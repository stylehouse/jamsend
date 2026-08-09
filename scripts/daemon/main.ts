// jamsend daemon — the machine, booted like a tab, with no tab.
//
//   node scripts/daemon/run.mjs
//
//   (NOT the vite-node CLI — it defaults every module to the ssr transform and the machine never
//    thinks; run.mjs uses vite-node's programmatic API with transformMode web.  Daemon_todo §3.1.)
//
// WHY THIS EXISTS.  Every long-running peer on this network is currently a browser tab a human
//  has to keep open (the Sounditrons, the runners).  A tab can be closed, backgrounded, throttled,
//   OOMed, or reloaded out from under a transfer.  A daemon is the same machine with none of those
//    properties.  The design question it answers — "is any of this browser-only?" — is mostly NO:
//     the wire is a WebSocket (Tribunal Socket_real, not WebRTC), the disk is a nav seam (A.c.nav),
//      the crypto is node-native.  What IS browser-only is AUDIO: OfflineAudioContext/decodeAudioData
//       and WebCodecs Opus (AudioEncoder/AudioDecoder).  Both are guarded at every call site with
//        `typeof X === 'undefined'` → return null, so this daemon boots and serves WITHOUT them; it
//         simply cannot stock new records or listen.  See spec/Daemon_todo.md §2.
//
// KNOBS (env — boot_param() reads env under node exactly as it reads ?query in the browser):
//   A=Auto             top-level world (default Auto — the Library/identity owner)
//   B=<Book>           boot as a RUNNER with a Book (the ?B= path)
//   E=<Waft>           boot as an EDITOR on a Waft (the ?E= path)
//   I=<prepub>         RESUME a specific identity from the share's .jamsend/account/<prepub>/ —
//                       the PRODUCTION shape (Identity_persist_todo §7: browser provisions, share
//                        carries, daemon resumes).  Also rides on_grid, so an I= daemon is an idle
//                         on-grid runner.  An arrest is an ERROR EXIT here, never a hang — see
//                          arrest_watch below (exit 2 = no account in the share, exit 3 = seed bug).
//   E=/B=/I=           exactly one of these three is REQUIRED — a bare boot with none of them
//                       refuses to start rather than falling into Auto's dev-only library page
//                        (Daemon_todo §8.3).  exit 4 = no boot shape given.
//   ROLE=<name>        identity name for a bare boot — OFF BY DEFAULT (ROLE=<name> opts in; ROLE=0
//                       is accepted but redundant with the default).  Resumes or MINTS under that
//                        role via Clustation_ensure_default.  A dev/smoke convenience only:
//                         production uses I=, because a daemon never provisions (ruled 2026-08-07) —
//                          defaulting this to a name used to MINT an identity on every unconfigured
//                           boot, which is exactly the provisioning that ruling forbids.
//   KEYFILE=<path>     keypair file (default /tmp/jamsend_daemon/idento.json) — the pre-Thangs
//                       fallback.  NOTE: with KEYED on (the default) the keyfile adopt WINS over
//                        ROLE= (Auto's adopt leg runs before ensure_default), so ROLE is inert
//                         unless KEYED=0.  §4.1's proof runs were KEYED=0 for exactly this reason.
//   ACCOUNT=0          don't mirror the active identity to .jamsend/account/ (default: mirror)
//   DAEMON_STATE=      dexie-node's backing dir (default /tmp/jamsend_daemon/state).  LOCKED
//                       (Daemon_todo §8.5) — a second daemon over the SAME dir refuses to boot
//                        (exit 6) rather than silently clobbering the first's writes.  A stale lock
//                         from a crashed process (dead pid inside) recovers on its own.  Running two
//                          daemons on purpose (§9.4) just needs two DIFFERENT DAEMON_STATE dirs
//                           (and two different PORTs) — that was always fine and still is.
//   ORIGIN=            what location.host becomes — the dev server Socket_real dials for /relay
//                       (default http://172.17.0.1:9091, the host as seen from this container)
//   SHARE=             repo/share root the wormhole nav reads (default cwd)
//   OVERLAY=           where writes land (default /tmp/jamsend_daemon/fs).  SAFE BY DEFAULT:
//                       the daemon does NOT write into the working tree.  OVERLAY=repo to opt in.
//   MUSIC=             a real collection to graft in READ-ONLY as `music/` in the nav, so
//                       Crate_nav_meander has something to dig through (Daemon_todo §5.3 / §0 item 6).
//                        MUSIC=1 means this container's /music mount; any other value is a path.
//                         Off by default — the daemon then sees only whatever music is in the share.
//   RELAY=1            join the /relay websocket (OFF by default — read Daemon_todo §4 first)
//   PORT=              status endpoint (default 9099).  curl localhost:9099/status
//   HOST=              status endpoint bind address (default 127.0.0.1 — LOCALHOST ONLY).
//                       Daemon_todo §8.4: `server.listen(PORT, …)` used to omit a host, which binds
//                        0.0.0.0 under node — `/stop` was an unauthenticated GET on every interface
//                         and `/c?depth=N` dumped the whole .sc tree the same way.  HOST=0.0.0.0 is
//                          an escape hatch for a deliberately-exposed deployment; know what you're
//                           doing before setting it.
//   STATUS_TOKEN=      the token /stop and /c require (as `?token=` or an `X-Daemon-Token` header).
//                       Default: a random token minted at boot and logged ONCE (grep the log for
//                        "🔑 status token", or read it back off stdout) — set STATUS_TOKEN=<val> to
//                         pin a known one for scripting.  /status stays open (uptime/worlds/book
//                          state, nothing secret — no key ever rides .sc, only .c).
//   SECS=              exit after N seconds (0 = forever).  For scripted smoke runs.
//   LOG=               log file (default /tmp/jamsend_daemon/daemon.log), ROTATED at ~10MB
//                       (daemon.log.1 keeps one prior generation — appendFileSync forever was
//                        unbounded, Daemon_todo §8.5)
//   QUIET=1            drop the app's own console noise, keep the daemon's own lines
//
// EXIT CODES — every one drains pending writes first (`shutdown()`, below):
//   0 normal stop (SECS reached, SIGINT/SIGTERM, or /stop)      1 no House ever appeared
//   2 I= arrest, CONFIG: no account for that prepub in the share (provision from a browser first)
//   3 I= arrest, BUG: account is on disk but the seed still couldn't adopt it (Identity_persist_todo §6)
//   4 no boot shape given (need B=/E=/I=)                       5 uncaughtException (node's own advice)
//   6 DAEMON_STATE already held by another live daemon process
import http from 'node:http'
import path from 'node:path'
import crypto from 'node:crypto'
import { appendFileSync, existsSync, mkdirSync, readFileSync, renameSync, statSync, writeFileSync } from 'node:fs'
import { JSDOM } from 'jsdom'

const ROOT     = process.env.SHARE   || process.cwd()
const OVERLAY  = process.env.OVERLAY === 'repo' ? ROOT : (process.env.OVERLAY || '/tmp/jamsend_daemon/fs')
const ORIGIN   = process.env.ORIGIN  || 'http://172.17.0.1:9091'
const PORT     = Number(process.env.PORT || 9099)
const HOST     = process.env.HOST || '127.0.0.1'
// STATUS_TOKEN — see the KNOBS comment above.  Minted here (not lazily) so the boot log always has
//  it, whether or not /stop or /c ever get hit.
const STATUS_TOKEN = process.env.STATUS_TOKEN || crypto.randomBytes(16).toString('hex')
const SECS     = Number(process.env.SECS || 0)
const QUIET    = process.env.QUIET === '1'
const t0       = Date.now()

// Log to a FILE as well as stdout, always.  A daemon's stdout is a pipe, and node block-buffers a
//  piped stdout — kill the process and the last 64KB of the story dies with it, which is exactly
//   the story you wanted (the first boot attempt here reported nothing but "Terminated").
// ROTATED (Daemon_todo §8.5): `appendFileSync` forever, with a heartbeat every 10s plus the app's
//  own console noise, is an unbounded file on a box nobody restarts.  One prior generation
//   (daemon.log.1) is enough for "what happened right before this" without a log manager.
const LOG = process.env.LOG || '/tmp/jamsend_daemon/daemon.log'
const LOG_MAX_BYTES = 10 * 1024 * 1024
mkdirSync(path.dirname(LOG), { recursive: true })
let log_size = 0
try { log_size = statSync(LOG).size } catch { /* no file yet */ }
const say = (m: string) => {
    const line = `[daemon ${((Date.now() - t0) / 1000).toFixed(1)}s] ${m}\n`
    process.stdout.write(line)
    try {
        if (log_size > LOG_MAX_BYTES) {
            try { renameSync(LOG, `${LOG}.1`) } catch { /* best-effort — a failed rotate must not stop logging */ }
            log_size = 0
        }
        appendFileSync(LOG, line)
        log_size += Buffer.byteLength(line)
    } catch { /* logging must never be why the daemon dies */ }
}
const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))

// ── 1. the browser, such as it is ────────────────────────────────────────────────────────────
// jsdom BEFORE any app module loads (hence the dynamic imports further down — a static import
//  would be hoisted above this and the svelte client runtime would find no document).
//  `url` is load-bearing and easy to miss: Tribunal's Socket_real builds its relay URL out of
//   location.protocol + location.host, so a wrong ORIGIN here is a daemon that boots perfectly
//    and silently never joins the relay.
const dom = new JSDOM('<!doctype html><html><body></body></html>', { url: ORIGIN, pretendToBeVisual: true })
const win: any = dom.window
;(globalThis as any).window = win
;(globalThis as any).document = win.document
// Copy jsdom's globals in, but never CLOBBER a node global that already works better than jsdom's
//  (WebSocket is the one that matters — node's is a real network socket, jsdom's is jsdom's).
//  `location` is the exception we force: node has none, and Socket_real needs it.
for (const k of Object.getOwnPropertyNames(win)) {
    if (k.startsWith('_') || k === 'window' || k === 'document') continue
    if (k in globalThis) continue
    try { (globalThis as any)[k] = win[k] } catch { /* getters that throw off-thread */ }
}
;(globalThis as any).location = win.location
;(globalThis as any).navigator ??= win.navigator

// PERSISTENCE MUST ACTUALLY SETTLE — it is not optional, and this cost an afternoon to learn.
//  Story_cli.setup.ts gets away with a no-op indexedDB stub (a request whose onsuccess never fires)
//   because a fixture Book never awaits Dexie.  A real boot awaits it immediately:
//    Housing.DirectoryOpener's very first act is `await fsh.start()` → restoreDirectoryHandle →
//     `await db.Handle.get(key)`.  Against the stub that promise NEVER SETTLES — and it is awaited
//      inside the beliefs mutex, the one lock every House drains under.  Symptom: `beliefs mutex
//       held 26s by H:Mundo think`, worlds half-built, todo stuck at 2, and a process that looks
//        perfectly healthy.  A stub is worse than nothing: nothing fails loudly.
//  The daemon's answer is NOT an indexedDB at all — daemon.vite.config.mjs aliases `dexie` to
//   scripts/daemon/dexie-node.ts, a file-backed key-value store covering the ~20 calls the app
//    really makes.  So: no npm install (no libc drift across the two containers that share
//     /app/node_modules), and persistence that SURVIVES A RESTART, which memory-only
//      fake-indexeddb would not have given.
//  NOTE we deliberately leave `indexedDB` UNDEFINED.  Nothing needs it now, and one thing checks
//   for it: Lies_stemdex (LiesFunk.svelte:1378) early-returns on `typeof indexedDB === 'undefined'`.
//    Stemdex is the code EDITOR's search index (Lies+Lang), not the Jamsend app — so it opts itself
//     out here, which is exactly what a daemon wants.  Defining indexedDB would switch it back on.
;(globalThis as any).requestAnimationFrame ||= (cb: any) => setTimeout(() => cb(Date.now()), 16)
;(globalThis as any).cancelAnimationFrame  ||= (id: any) => clearTimeout(id)

// RELATIVE FETCH.  jsdom gives us `location`, but node's global fetch is node's, and it rejects a
//  relative URL outright: `TypeError: Failed to parse URL from /log?stream=Startup-anon` (seen for
//   real, from the startup telemetry post).  In a browser every `fetch('/thing')` resolves against
//    the origin; here nothing does.  Resolve against ORIGIN so app code that assumes a page origin
//     behaves, rather than throwing somewhere nobody is reading.
{
    const raw = globalThis.fetch.bind(globalThis)
    ;(globalThis as any).fetch = (input: any, init?: any) => {
        if (typeof input === 'string' && input.startsWith('/')) input = new URL(input, ORIGIN).toString()
        return raw(input, init)
    }
    ;(win as any).fetch = (globalThis as any).fetch
}

// ── the relay is OPT-IN, and this is not caution for its own sake ────────────────────────────
// A runner's relay address is its ROLE, not its identity: LiesLies.svelte:312 does
//  `w.oai({ Peering: 1, name: role })` and Socket_real dials `/relay?addr=<that>` — so this daemon
//   registers as `addr=runner`, the SAME address every runner tab claims.  Observed on the first
//    connected run: `ws SEND control:become role=runner`, accepted, then `channel DEAD — 20s silent`
//     twice — i.e. two claimants on one binding.  It also cheerfully sent `run_phase` frames to the
//      editor, which is a phantom run appearing in someone else's cluster view.
//  So: off unless RELAY=1.  The switch is the app's OWN seam — LiesLies skips the whole channel on
//   `typeof WebSocket === 'undefined'` ("not a browser (tests/node)") — so nothing is monkeyed with;
//    the daemon simply looks like node to the code that asks.
//  Before turning this on for real, give the daemon its own addr (Daemon_todo.md §4).
const RELAY = process.env.RELAY === '1'
if (!RELAY) {
    delete (globalThis as any).WebSocket
    try { delete (win as any).WebSocket } catch {}
}

// ── shutdown — the ONE choke point every exit path funnels through ──────────────────────────
// Daemon_todo §8.5: `process.exit()` used to be called directly at every exit site.  Two problems
//  with that, both silent: (1) dexie-node's save() only ever SCHEDULES a write via queueMicrotask,
//   and process.exit does not wait for a queued microtask — a write issued in the last tick (an
//    identity mint, an account mirror) was dropped; (2) a second daemon sharing DAEMON_STATE was
//     never released back to a crashed-and-restarted sibling.  `flush_all`/`unlock_state` are wired
//      in once dexie-node has loaded (below); before that there is nothing buffered to lose or lock
//       to release, so the no-op defaults are honest, not a gap.
let flush_all: () => Promise<void> = async () => {}
let unlock_state: () => void = () => {}
const shutdown = async (code: number): Promise<never> => {
    try { await flush_all() } catch (e: any) { say(`⚠ flush on shutdown failed — ${e?.message ?? e}`) }
    try { unlock_state() } catch { /* best-effort */ }
    process.exit(code)
}

// The machine is a perpetual reactive system with fire-and-forget elvises; a late rejection is
//  normal weather, not a fault.  A daemon must never die of one.
process.on('unhandledRejection', (e: any) => { if (!QUIET) say(`⚠ unhandledRejection: ${e?.message ?? e}\n${(e?.stack ?? '').split('\n').slice(1, 7).join('\n')}`) })
// uncaughtException USED to log and continue (Daemon_todo §8.5) — node explicitly warns against
//  that: past this point the process is in an unknown state, and "log and continue" also means a
//   crash-loop supervisor never fires, because the process never exits for it to notice.  Drain what
//    we can (flush_all is synchronous fs underneath, so this is fast) and exit — exit 5, a new code,
//     distinct from the arrest/boot-shape exits above.
process.on('uncaughtException', (e: any) => {
    say(`☠ uncaughtException: ${e?.stack ?? e}`)
    say('   exiting rather than continuing in an unknown state (node\'s own guidance) — exit 5')
    shutdown(5)
})

const app_log = console.log
if (QUIET) console.log = () => {}

// ── 2. the machine ───────────────────────────────────────────────────────────────────────────
// WHICH dexie am I?  The alias is invisible at the call sites (they all just `import from 'dexie'`),
//  so say it out loud at boot.  If this ever prints `real dexie`, the alias didn't take and the
//   daemon is about to wedge in DirectoryOpener with no indexedDB — the exact failure that ate an
//    afternoon, and one that otherwise announces itself only as "the machine stopped thinking".
{
    const dexie_mod: any = await import('dexie')
    const Dx: any = dexie_mod.Dexie
    const shimmed = typeof (Dx?.prototype as any)?.save === 'function'
    say(`dexie: ${shimmed ? `dexie-node shim → ${process.env.DAEMON_STATE || '/tmp/jamsend_daemon/state'}` : '⚠ REAL dexie — the alias did not take, expect a wedge'}`)
    if (shimmed) {
        flush_all = dexie_mod.flush_all
        // DAEMON_STATE lock (Daemon_todo §8.5) — two daemons pointed at the same DAEMON_STATE used
        //  to silently clobber each other, last-writer-wins over the WHOLE table (each process holds
        //   its own in-memory Map and periodically overwrites the shared JSON file, so whichever
        //    saves last wins, wiping the other's rows).  §9.4 wants two daemons deliberately, each
        //     with its own DAEMON_STATE dir — that stays fine, this only locks a SHARED dir.  A stale
        //      lock (the pid inside is dead — a crash, not a clean stop) is recovered automatically
        //       rather than wedging the next boot forever.
        try {
            unlock_state = dexie_mod.lock_state()
        } catch (e: any) {
            say(`☠ ${e?.message ?? e}  exit 6`)
            process.exit(6)
        }
    }
}

const { mount, flushSync } = await import('svelte')
const { NodeWormholeNav }  = await import('../NodeWormholeNav')
const Daemonic             = (await import('./Daemonic.svelte')).default

// Reads fall through overlay → repo; writes land in the overlay.  Deliberately the TEST nav: a
//  daemon that scribbles toc.snaps into a working tree someone else is editing is a bad neighbour.
//   A real deployment points SHARE at its own share and OVERLAY=repo.
//  MUSIC= grafts a real collection in as a READ-ONLY third root named `music` (NodeWormholeNav's
//   `mounts`).  Without it the daemon's crate is whatever audio happens to sit in the share — which
//    for a dev checkout is the 8-track `testsounds`, i.e. enough to prove plumbing and not enough to
//     mean anything.  Not folded into SHARE because SHARE is the repo the daemon BOOTS from (the
//      wormhole fixtures, the GhostList, the gen trees); repointing it at music would find the
//       collection and lose the machine.  Read-only is enforced in the nav, not just intended.
// LIBRARY= is the ONE knob for the real deployment: the folder the user granted in a browser over
//  FSA, which is where their music lives AND where the browser already wrote
//   `.jamsend/account/<prepub>/toc.snap` (the owner: *"the user must have already set up via
//    browser+FSA the /music/.jamsend etc"*).  It expands into the two mounts that shape needs:
//     `music`    → the library, READ-ONLY.  Nothing should ever write into someone's collection.
//     `.jamsend` → the library's own `.jamsend`, READ-WRITE.  The account the daemon RESUMES from
//                   lives there, and the mirror, radiostock and berth must land back in the same
//                    place a browser session would find them — not in a scratch volume nobody reads.
//  Everything else (Story snaps, gen writes, compile output) keeps landing in OVERLAY, so a jamserve
//   run never litters the user's music folder with machine scratch.  That separation is the whole
//    reason this is a mount rather than just pointing OVERLAY at the library.
//  MUSIC= remains the simpler alias for a dev box: collection visible, no `.jamsend` writes.
const LIBRARY = process.env.LIBRARY === '1' ? '/music' : (process.env.LIBRARY || '')
const MUSIC = process.env.MUSIC === '1' ? '/music' : (process.env.MUSIC || '')
const mounts: Record<string, string | { path: string; rw?: boolean }> = {}
if (LIBRARY) {
    if (!existsSync(LIBRARY)) say(`⚠ LIBRARY=${LIBRARY} does not exist — no collection and no account`)
    else {
        mounts.music = LIBRARY
        mounts['.jamsend'] = { path: `${LIBRARY}/.jamsend`, rw: true }
        if (!existsSync(`${LIBRARY}/.jamsend`)) {
            say(`⚠ ${LIBRARY}/.jamsend is absent — provision this identity from a BROWSER first (§4.1: the daemon never provisions)`)
        }
    }
} else if (MUSIC) {
    if (!existsSync(MUSIC)) say(`⚠ MUSIC=${MUSIC} does not exist — the collection stays empty`)
    else mounts.music = MUSIC
}
const nav = new NodeWormholeNav(ROOT, OVERLAY, false, mounts)

// BOOT SHAPE — mirror boot_qualand (BigQualand.svelte.ts:47-71), not Auto's dev library page.
//  Daemon_todo §8.3: a bare `node run.mjs` sets neither `book` nor `boot_role`, so Auto.svelte:565
//   (`H.c.boot_role ? 'run' : 'library'`) falls into the disk-backed book-browser and activates
//    whatever Book a human last left `active` in the shared wormhole/Present/toc.snap — a dev
//     affordance no real client ever reaches.  Real clients stamp `book`+`boot_role` in CODE
//      (`/BigSoundland` → `boot_qualand({book:'Sounditron', role:'sound'})`), never via a query
//       param.  So: stamp the same shape here, and REFUSE to boot bootless rather than silently
//        taking the library branch — exit 4, the next unused code after arrest_watch's 2/3.
//  THE DAEMON IS NOT THE EDITOR'S RUNNER (2026-08-08, Daemon_todo §4a).  `boot_role='runner'` buys
//   two unrelated things: `creduler:1` (what runs Books) and `runner:1` (what claims /relay?addr=
//    runner and stands the editor↔runner control channel).  An always-up peer wants the first only —
//     the relay's `bind()` is additive and `deliverLocal` fans out to the whole set, so a second
//      claimant of `runner` quietly receives every frame meant for a human's tab.  `boot_role='daemon'`
//       is a runner in every respect but that claim (Auto.svelte's `runnerish`).
//  CHANNEL=1 opts back IN to the runner role, for the one case that wants it: driving this process
//   from the editor like any other runner tab.  Know what it collides with before you set it — with a
//    human's runner tab up, that is the `channel DEAD — 20s silent` of §4, on both of you.
const CHANNEL = process.env.CHANNEL === '1'
const RUNNER_ROLE = CHANNEL ? 'runner' : 'daemon'
const boot: Record<string, any> = { toplevel: process.env.A || 'Auto' }
if (process.env.E) { boot.book = process.env.E; boot.boot_role = 'editor' }
else if (process.env.B) { boot.book = process.env.B; boot.boot_role = RUNNER_ROLE }
else if (process.env.I) { boot.boot_role = RUNNER_ROLE; boot.on_grid = process.env.I }

// FACELESS — the UIs this process registers but never mounts (Daemonic's FACELESS SET explains
//  why Vyto is the default: the glass runs a 60fps render loop into a document with no reader, and
//   trips its own watchdog every four seconds saying so).  `FACELESS=` mounts everything again —
//    an empty string is a deliberate override, so read `!== undefined`, not `||`.
if (process.env.FACELESS !== undefined) boot.faceless = process.env.FACELESS

if (!boot.boot_role) {
    say('☠ no boot shape given — set B=<Book> (runner), E=<Waft> (editor), or I=<prepub> (resume).')
    say('   A bare `node run.mjs` would fall into Auto\'s dev-only library page (Daemon_todo §8.3), which no real client ever reaches.  exit 4')
    await shutdown(4)
}

// ROLE — the daemon's identity NAME (a dev/smoke convenience — production uses I=, §4.1's ruling
//  that "the daemon never provisions").  DEFAULT OFF: a bare `ROLE=` used to default to 'daemon',
//   which MINTS an identity on every unconfigured boot — exactly the provisioning the owner ruled
//    against.  ROLE=<name> opts in explicitly; ROLE=0 is now redundant with the default but still
//     accepted so old invocations keep working.
//  /BigSoundland is `boot_qualand({book:'Sounditron', role:'sound'})`, which stamps id_role +
//   assume_identity + humdinger (BigQualand.svelte:54-68).  Two consequences, both wanted, when
//    ROLE is given:
//     · Auto's `Clustation_ensure_default` resumes-or-mints the identity stored in the identities
//        Thang under this role — persisted by the dexie-node shim — so the daemon is the SAME peer
//         across restarts through the app's own path.  `?I=` and the legacy keyfile adopt both still
//          WIN if present (they run first); this only fills a bare boot's gap.
//  NOTE the role is a STORAGE NAME, not a derivation: the key is a fresh random mint either way, so
//   two daemons sharing a role name on different boxes are different peers, not impostors of one.
const ROLE = process.env.ROLE === '0' ? '' : (process.env.ROLE || '')
if (ROLE) { boot.id_role = ROLE; boot.assume_identity = true }

// humdinger — derived from BOOT_ROLE, the way boot_qualand derives it from opts.role, NOT from the
//  ROLE identity knob.  Bug this replaces (Daemon_todo §8.3): `ROLE=0 B=Sounditron` used to stamp
//   boot_role='runner' but skip humdinger (it only rode inside the `if (ROLE)` block above) — so the
//    editor enrolled the daemon off its 5s heartbeat and dispatched Story runs at it, a phantom-run
//     footgun.  Any real boot_role (editor or runner) is an end-user-shaped process and must stay
//      off that grid regardless of whether an identity role was also given.
if (boot.boot_role) boot.humdinger = true

let H: any = null
say(`booting — relay=${RELAY ? "ON (RELAY=1)" : "off — set RELAY=1 to join, but read Daemon_todo §4 first"} origin=${ORIGIN} share=${ROOT} overlay=${OVERLAY}${LIBRARY ? ` library=${LIBRARY} (music ro, .jamsend rw)` : mounts.music ? ` music=${mounts.music} (ro)` : ''} boot=${JSON.stringify(boot)}`)
mount(Daemonic, { target: win.document.body, props: { boot, onhouse: (h: any) => { H = h } } })
for (let i = 0; i < 100 && !H; i++) { flushSync(); await sleep(20) }
if (!H) { say('☠ no House — the shell never constructed one'); await shutdown(1) }
say(`H:Mundo up (started=${H.started})`)

// ── 3. the crank ─────────────────────────────────────────────────────────────────────────────
// THE ONE STRUCTURAL DIFFERENCE FROM A TAB.  In the browser the House's own $effect.root drives
//  todo → beliefs off svelte's scheduler.  Under node that pump does not carry itself (the comment
//   at the top of Story_cli.svelte says so, and every headless spec here hand-cranks
//    _really_answer_calls in a loop).  So the daemon's main loop IS the pump.  Everything else
//     about the machine is identical; this is the seam where "a tab" becomes "a process".
//
// Pacing: drain hard while there is work, idle at ~50ms when there isn't, and wake early for the
//  soonest live ttlilt.  A ttlilt is the machine's own alarm clock — sleeping past one turns a
//   timing-sensitive req into a spurious timeout, which is exactly the class of bug that reads as
//    "the daemon is flaky" and is really "the driver overslept".
const allHouses = (h: any): any[] => { const out = [h]; const w = (x: any) => { for (const s of (x.o?.({ H: 1 }) ?? [])) if (!out.includes(s)) { out.push(s); w(s) } }; w(h); return out }
const now_s = () => Date.now() / 1000
const liveTtlilts = (h: any): { count: number, soonest: number } => {
    let count = 0, soonest = Infinity
    const visit = (n: any) => {
        if (n?.sc?.ttlilt !== undefined && !n.sc.timed_out) { count++; const u = n.sc.until_ts; if (typeof u === 'number' && u < soonest) soonest = u }
        for (const k of (n.o?.({}) ?? [])) visit(k)
    }
    visit(h); return { count, soonest }
}
const drain = async () => {
    for (const h of allHouses(H)) {
        let guard = 0
        while (h.todo?.length && h.started && guard++ < 300) { try { await h._really_answer_calls() } catch { /* Story_error already booked it */ } }
    }
}

// ── the keyfile: a daemon that is the SAME peer after a restart ──────────────────────────────
// The identity layer's on-ramp is `?I=<tag>` — and for a named tag it can only RESUME, from a
//  store this process doesn't durably have.  Observed: `I=daemon-alpha` on a fresh daemon prints
//   `🪪⚠ identity ARRESTED — no key for daemon-alpha is stored in this browser`, and the boot
//    STOPS there by design (Auto.svelte: "Nothing past this point runs … until a human resolves it
//     via the IdHatch").  An IdHatch is a popover.  A daemon renders no popovers.  So `I=<tag>` is
//      a dead end here, and `I=new` is worse in a different way: a brand-new stranger every boot.
//  The way through needs no change to shared code.  Auto's legacy-migration leg adopts a bare
//   `stashed.cluster_idento` into a first-class %Identity, ONCE, on any boot without ?I=.  So the
//    daemon keeps its keypair in a FILE, stamps it on the top House's stashed before the world
//     stands up, and Auto does the rest — same peer, same prepub, every restart.
//  KEYFILE=<path> (default outside the repo, because it is a private key).  Minted on first run.
const KEYFILE = process.env.KEYFILE || '/tmp/jamsend_daemon/idento.json'
const KEYED   = process.env.KEYED !== '0'
let keyed_done = false
const seed_identity = async (): Promise<boolean> => {
    if (!KEYED || keyed_done) return true
    if (!H.stashed || typeof H.stashed !== 'object') return false    // Dexie hasn't hydrated it yet
    if ((H.stashed as any).cluster_idento) { keyed_done = true; return true }
    let stored: any = null
    if (existsSync(KEYFILE)) {
        try { stored = JSON.parse(readFileSync(KEYFILE, 'utf8')) } catch (e: any) { say(`⚠ keyfile unreadable: ${e?.message}`) }
    }
    if (!stored) {
        if (typeof (H as any).Clustation_mint !== 'function') return false   // ghosts still mounting
        stored = await (H as any).Clustation_mint()
        mkdirSync(path.dirname(KEYFILE), { recursive: true })
        writeFileSync(KEYFILE, JSON.stringify(stored, null, 1), { mode: 0o600 })
        say(`🪪 minted a daemon identity → ${KEYFILE} (prepub ${String(stored.prepub).slice(0, 12)})`)
    }
    if (!stored?.pub || !stored?.key) { say('⚠ keyfile has no {pub,key} — running identity-less'); keyed_done = true; return true }
    ;(H.stashed as any).cluster_idento = { pub: stored.pub, key: stored.key }
    keyed_done = true
    say(`🪪 identity seeded from keyfile (prepub ${String(stored.prepub ?? '').slice(0, 12)})`)
    return true
}

let began = false
let ticks = 0, drains = 0
let stopping = false

// identity_state — is there a self to BE on this network?  Everything social hangs off it: an
//  Invite is redeemed BY someone, a grant is issued TO someone, a Pier is sealed between two
//   prepubs.  A daemon with no identity can still run Books; it cannot be a peer.
//  Identities live as %Identity children of A:Clustation (Auto.svelte:272), mirrored into the
//   Thangs `identities` Dexie table.  With a memory-only IDB the particle appears but the mirror
//    dies at exit — a NEW identity every boot, which on a real network reads as a new stranger
//     each restart.  That is Daemon_todo §3, and it is the difference between a daemon and a tab
//      that forgets itself.
const identity_state = () => {
    const A = (H.o?.({ A: 'Clustation' }) ?? [])[0]
    const ids = (A?.o?.({ Identity: 1 }) ?? []) as any[]
    const active = ids.find(i => i.sc.active)
    return { count: ids.length, active: active ? String(active.sc.prepub ?? '').slice(0, 12) : null }
}

// nag_identity — SAY WHAT IS WRONG, FOR AS LONG AS IT IS WRONG (the owner, 2026-08-08: "it should
//  probably complain about no identity if there isn't one").  Two states deserve a standing complaint,
//   and neither announces itself otherwise — the box boots green, heartbeats happily, and is simply
//    not the peer anyone can reach:
//     · NO IDENTITY — nothing to be on the network.  Books still run; an invite cannot be answered.
//     · A THROWAWAY — an identity minted here rather than provisioned in a browser (I= unset).  It
//        works, and it is nobody's friend: no one holds a Pier to it, and it dies with the container.
//  ONCE loudly at boot, then folded into the heartbeat, because the loud one scrolls away in minutes
//   and the whole point is that this stays visible to someone reading `docker logs` an hour later.
//   Silent in the configured case, so a correctly-provisioned box says nothing at all.
let nagged = false
const nag_identity = (): string => {
    const id = identity_state()
    const provisioned = !!process.env.I                // I=<prepub>, the production shape
    if (id.active && provisioned) return ''
    // NOT "it dies with the container" — that was written before it was watched, and it is false.
    //  A throwaway MIRRORS itself to <music>/.jamsend/account/<prepub>/, and `Swarm_boot_seed` then
    //   picks that sole account back up on the next boot with no I= at all.  Measured 2026-08-08:
    //    the same prepub came back with KEYED=0, ROLE unset and I= unset.  So the complaint is not
    //     that it is ephemeral — it is that it is SELF-MINTED (nobody knows it, so nobody can be
    //      served by it) and that it has left an unencrypted private key in a music folder whose
    //       owner never asked for one.
    // COUNT the friends rather than asserting there are none.  "Nobody holds a Pier to it" was in
    //  this string until an incognito tab redeemed the throwaway's own invite and sealed one —
    //   measured 2026-08-08, and it survived a restart.  A throwaway is unprovisioned, not friendless;
    //    saying the stronger thing made the log lie the moment the feature above started working.
    const self = (H as any).Swarm_live_self?.()
    const friends = (H as any).Swarm_peering?.(self)?.o({ Pier: 1 })?.length ?? 0
    const one = !id.active
        ? `⚠ NO IDENTITY — this box can run Books but cannot be a peer: no invite can be answered.`
        : `⚠ THROWAWAY IDENTITY (${id.active}) — self-minted, not provisioned from a browser`
          + (friends ? `, though ${friends} peer(s) have sealed with it.` : `, and nobody has sealed with it yet.`)
    // HOLD the loud block until the station is up, because the Swarm ledger (piers, invites) is
    //  restashed as part of arming — nagging before that read "nobody has sealed with it yet" at
    //   30.4s and `remembers 1 friend(s)` at 42.3s, twelve seconds and one contradiction apart.
    //  The `|| uptime > 90` escape is for the state that never arms: with no identity at all the
    //   station cannot come up, and that is exactly the case most deserving of the complaint.
    if (!nagged && (stood || process.uptime() > 90)) {
        nagged = true
        say(one)
        if (id.active) say(`   It PERSISTS: mirrored to <music>/.jamsend/account/${id.active}…/ and resumed from there, so it is the same peer each boot — and that is an unencrypted private key in your music folder you did not ask for. Delete that directory to be rid of it.`)
        say(`   To be a real peer: grant your music folder in a BROWSER, let it write the account, then`)
        say(`   ls <music>/.jamsend/account/   — the directory names ARE the prepubs — and set`)
        say(`   JAMSERVE_ID=<prepub> (which becomes I=). The daemon never provisions (§4.1).`)
    }
    return id.active ? ` ⚠throwaway` : ` ⚠no-identity`
}

// book_state — the same three numbers `runner_ask state` reports off a live tab (verdict + where
//  the run is), read straight off the C tree.  A Story Run lives at H:Story/A:Story/w:Story, with
//   the live session on w.c.This; each %Step carries ok|caveat|dige once it has been snapped.
const book_state = () => {
    const SH = (H.o?.({ H: 'Story' }) ?? [])[0]
    const w = SH?.o?.({ A: 'Story' })?.[0]?.o?.({ w: 'Story' })?.[0]
    if (!w) return null
    const run = w.o?.({ run: 1 })?.[0]
    const steps = (w.c?.This?.o?.({ Step: 1 }) ?? []) as any[]
    return {
        Book: w.sc?.Book ?? null,
        driving: run?.c?.driving ?? null,
        phase: run?.sc?.phase ?? null,
        frontier: run?.sc?.frontier ?? null,
        steps: steps.length,
        ok: steps.filter(s => s.sc.ok).length,
        caveat: steps.filter(s => s.sc.caveat).length,
        snapped: steps.filter(s => s.sc.got_snap).length,
    }
}

// ── 3b. the probe: what is the beliefs pass actually inside? ─────────────────────────────────
// A wedge reports as `beliefs mutex held 26s by H:Mundo think` — true, and useless: `think` is
//  the whole machine.  The pass is a nest of awaits (beliefs → organise → attend → reqdo_sweep →
//   reqdo(w) → w.do()), and the one that never returns is the answer.  So keep a breadcrumb STACK
//    by wrapping those methods on House.prototype from out here — no edit to Housing.svelte.ts,
//     which is shared ground and heavily trafficked.
//  This is not scaffolding to delete: an always-on daemon needs to name its own wedge, because by
//   the time a human looks, the interesting stack is 20 minutes gone.
const probe: { stack: { tag: string, at: number }[], last: string, deepest: string, deepest_ms: number } =
    { stack: [], last: '', deepest: '', deepest_ms: 0 }
const wrapped = new Set<string>()
const wrap_probe = () => {
    // TWO homes, and the difference is the whole trick: the pump's own methods live on
    //  House.prototype, while every GHOST method is eatfunc-deposited as an OWN property of H
    //   (and arrives late, as ghosts mount).  So wrap both, and re-check each tick for the ones
    //    that hadn't landed yet.
    const P: any = Object.getPrototypeOf(H)
    const at = (name: string) => (typeof P[name] === 'function' ? P : (typeof (H as any)[name] === 'function' ? H : null))
    const wrap = (name: string, label?: (a: any[]) => string) => {
        if (wrapped.has(name)) return
        const home = at(name); if (!home) return
        const f = home[name]
        wrapped.add(name)
        home[name] = async function (...a: any[]) {
            const m = { tag: label ? label(a) : name, at: Date.now() }
            probe.stack.push(m)
            try { return await f.apply(this, a) }
            finally { probe.stack.pop(); probe.last = m.tag }
        }
    }
    wrap('beliefs')
    wrap('organise')
    wrap('attend')
    wrap('reqdo_sweep')
    wrap('reqdo', (a) => `reqdo ${a[0]?.c?.up?.sc?.A ?? '?'}/${a[0]?.sc?.w ?? '?'}`)
    wrap('_deliver_targeted', (a) => `deliver ${a[0]?.sc?.elvis ?? '?'}`)
    // the money one: _Aw_think is the per-world dispatch — its label names the exact A/w whose
    //  handler is sitting there not returning.
    wrap('_Aw_think', (a) => `Aw ${(a[0]?.sc?.n)?.sc?.A ?? '?'}/${(a[1]?.sc?.n)?.sc?.w ?? '?'}`)
    wrap('agency_officing')
    wrap('self_timekeeping', (a) => `timekeep ${a[0]?.sc?.A ?? a[0]?.sc?.w ?? '?'}`)
}
wrap_probe()
const probe_line = () => probe.stack.map(m => `${m.tag}(${((Date.now() - m.at) / 1000).toFixed(1)}s)`).join(' → ') || '(idle)'
// stock_state — how much music this box can actually SERVE, which until tonight was a number nobody
//  could see from outside.  `records` is the live shelf (%Record under this identity's own %Peering);
//   `ff` is the native provider's running tally, and its `last_why` is the single most useful line
//    when the shelf will not grow — it names the track and the reason instead of leaving a silence
//     that reads identically to "the collection is empty".
const stock_state = () => {
    const out: any = { native: false, records: 0 }
    try {
        const top = (H as any).top_House?.() || H
        const nat = top?.c?.ra_native
        out.native = !!nat
        if (nat) out.ff = nat.stats
        const rw = top?.c?.radio_w
        if (!rw) return out
        const pub = (H as any).Radio_pub?.(rw)
        if (!pub) return out
        const shelf = (H as any).Ra_home_self?.(rw, pub)
        out.records = shelf ? ((H as any).Ra_recs?.(shelf)?.length ?? 0) : 0
        // THE NUMBER THAT PROVES A FRIENDSHIP IS DOING ANYTHING.  A friend's cast mints a per-friend
        //  `%MusuThem` crate in the radio world (`Swarm_share_up`'s `repli_mirror_by_from` +
        //   `repli_mirror_w`).  ZERO of them while sealed peers trade `ive_got` every few seconds is
        //    the exact signature of an unarmed rx — the fault that hid all morning behind a box that
        //     looked healthy from every other angle: sealed, granted, shelf stocked, no errors.
        out.share = share_armed
        out.them = rw.o?.({ MusuThem: 1 })?.length ?? 0
        // THE CONVEYOR'S OWN ELECTRODES, which `Stoker_dig` already sets and nobody outside a browser
        //  could read: they live on `.c`, and /c dumps `sc`.  Without them "the shelf stopped growing"
        //   has at least three explanations wanting opposite fixes — the tour never ran; it ran and the
        //    meander returned nothing; it ran, returned picks, and every pick was already standing
        //     (`dig_got` up, `dig_dup` up, shelf flat) — and Radio.g's own comments record this file
        //      relearning that lesson twice already.  Reading them costs nothing and guessing costs a
        //       night.  `tour_ago_s` separates "not running" from "running and finding nothing", which
        //        is the split none of the counters can make on their own.
        const st = rw.o?.({ Stoker: 1 })?.[0]
        if (st) out.dig = {
            state: st.sc?.Stoker ?? '?',
            tour_ago_s: st.c?.tour_at ? +((Date.now() - st.c.tour_at) / 1000).toFixed(1) : null,
            base: st.c?.dig_base ?? null,
            picks: st.c?.dig_picks ?? 0,
            got: st.c?.dig_got ?? 0,
            dup: st.c?.dig_dup ?? 0,
            bad: st.c?.dig_bad ?? 0,
            hit: st.c?.dig_hit ?? 0,
            err: st.c?.dig_err || '',
        }
    } catch (e: any) { out.why = String(e?.message).slice(0, 80) }
    return out
}

// friendly_of — a prepub-8 back to the name a human gave that friendship.  A log line that says
//  `65ae23ea` makes the reader do a lookup; one that says `Vaga(65ae23ea)` does not.
const friendly_of = (pub8: string): string => {
    try {
        const self = (H as any).Swarm_live_self?.()
        const peering = self && (H as any).Swarm_peering?.(self)
        for (const p of (peering?.o?.({ Pier: 1 }) ?? []))
            if (String(p.sc?.pub || '').startsWith(pub8)) return `${p.sc.friendly || '?'}(${pub8})`
    } catch {}
    return pub8 || '?'
}

// mem_state — WHAT THIS BOX IS HOLDING, and the peak it has ever held.  Added 2026-08-08 because
//  `docker-compose.yml` caps jamserve at 3G and NOTHING measured whether that number bore any
//   relation to reality — it was set against the old `rec.c.pcm` pinning (~92MB per record) and has
//    never been checked since that got an owner.  A limit nobody measures against is a coin flip:
//     too low and the box dies mid-heist, too high and a leak runs for hours before anyone notices.
//  `hi` is the high-water mark, and it is the one that matters.  RSS sampled every 10s tells you
//   almost nothing about a process that allocates in bursts (a whole-remainder ffmpeg queue, a
//    census, a landing) — the peak is what the cgroup killer actually reacts to, and it is invisible
//     to any amount of staring at instantaneous readings.
//  V8 heap is reported BESIDE rss on purpose.  They answer different questions: heap climbing with
//   rss flat is a JS leak, rss climbing with heap flat is buffers|subprocess|external (which on this
//    box means audio bytes, the likelier one).  A single number cannot tell those apart.
let mem_hi = 0
const mem_state = () => {
    const m = process.memoryUsage()
    const mb = (n: number) => Math.round(n / 1048576)
    if (m.rss > mem_hi) mem_hi = m.rss
    return { rss: mb(m.rss), hi: mb(mem_hi), heap: mb(m.heapUsed), heap_cap: mb(m.heapTotal), ext: mb(m.external) }
}

// serve_state — WHO THIS BOX IS ACTUALLY FEEDING, the one thing the log never said.  "A peer is
//  connected" and "bytes are leaving for that peer" are different claims, and only the second one
//   means the box is doing its job; all morning the first was true and the second was false, and
//    nothing in the log could tell them apart.  Repli already keeps the answer: `Repli_serve_want`
//     stamps a live serve cursor per record on the top House's `.c.xfer` (Repli.g:817) —
//      `{title, n, total, to, ts, re}` — as pages go out.  That is the UPLOADER's own view.  `re` is
//       the retransmit count, which is the tell that a sink is re-asking for pages it already got.
const serve_state = () => {
    try {
        const x: any = (H as any).top_House?.()?.c?.xfer
        if (!x) return null
        const now = Date.now()
        const live = Object.entries(x.serves || {})
            .map(([id, s]: any) => ({ id, ...(s as object) }))
            .filter((s: any) => now - (s.ts || 0) < 30_000)     // "in flight", not "ever served"
            .sort((a: any, b: any) => (b.ts || 0) - (a.ts || 0))
        return { live, rx_kbps: x.rx_kbps || 0, tx_kbps: x.tx_kbps || 0, drops: x.drops || 0, last_drop: x.last_drop || '' }
    } catch { return null }
}

// vyto_state — the glass's own electrodes, and the one reading that settles whether the RENDERER is
//  running on a box with no screen.  The split matters and no single number makes it:
//   · stir_n     — the GHOST half (Vyto_stir → scan/fold/gang/relate/express/solve).  Still turns
//                   with the glass faceless; it is the commission that drives it, not the render.
//   · wall_cuts  — the RENDER half, bumped only inside Vytui's build_cells.  Flat ⇒ nothing is
//                   cutting power cells, which is what "faceless" is supposed to mean.  A rising
//                    wall_cuts on a daemon is the whole bug, visible in one number.
//   · painted_stir/settled/yore_n — where the renderer got to, for when it IS wanted.
//  Blank when no glass stands, which is itself the answer to "did the commission land".
const vyto_state = () => {
    try {
        for (const h of allHouses(H))
            for (const A of (h.o?.({ A: 'Vyto' }) ?? []))
                for (const w of (A.o?.({ w: 'Vyto' }) ?? [])) {
                    const c: any = w.c ?? {}
                    return {
                        commissioned: !!c.commission,
                        stir_n: c.stir_n ?? 0,
                        wall_cuts: c.wall_cuts ?? 0,
                        painted_stir: c.vyto_painted_stir ?? 0,
                        settled: c.settled ?? 0,
                        yore_n: c.yore_n ?? 0,
                    }
                }
    } catch (e: any) { return { why: String(e?.message).slice(0, 80) } }
    return null
}

const stats = () => {
    const hs = allHouses(H)
    return {
        up_s: +((Date.now() - t0) / 1000).toFixed(1),
        ticks, drains,
        houses: hs.map(h => ({
            name: h.name, started: !!h.started, todo: h.todo?.length ?? 0,
            // WHAT is queued, not just how many — a standing count of 2 says nothing; two named
            //  elvises say which pump is stalled.  Same shape Otro's todo popover shows a human.
            queued: (h.todo ?? []).slice(0, 8).map((e: any) => e?.sc?.fn ? `fn:${e.sc.see ?? '?'}` : (e?.sc?.elvis ?? '?')),
            drain_why: h.c?.drain_why ?? null,
            worlds: (h.o?.({ A: 1 }) ?? []).map((A: any) => `${A.sc.A}/${(A.o?.({ w: 1 }) ?? []).map((w: any) => w.sc.w).join(',')}`),
        })),
        wedge: (H.top_House?.() as any)?.mutex_held?.('beliefs') ?? null,
        mem: mem_state(),
        inside: probe_line(),
        book: book_state(),
        stock: stock_state(),
        serve: serve_state(),
        vyto: vyto_state(),
        identity: identity_state(),
        ttlilts: liveTtlilts(H).count,
        ghosts: Object.keys(H).filter(k => typeof (H as any)[k] === 'function').length,
        boot,
    }
}

// ── 4. the interrogation surface ─────────────────────────────────────────────────────────────
// Two of them, on purpose.  The RIGHT one is the relay: a daemon booted as a runner registers on
//  /relay and `node scripts/runner_ask.mjs --runner=<addr> ping|run|state|steps|snap` reaches it
//   like any tab — the usual ways, unchanged.  But that channel is exactly what breaks first, and
//    a diagnostic that shares a failure mode with its subject is worthless.  So this local HTTP
//     port answers even when the relay is down, which is when you most want to ask.
//  SECURED (Daemon_todo §8.4): bound to HOST (default 127.0.0.1, not the node default 0.0.0.0), and
//   /stop + /c require STATUS_TOKEN — a curl one-liner still works:
//     curl "http://localhost:9099/stop?token=$TOKEN"
//     curl -H "X-Daemon-Token: $TOKEN" "http://localhost:9099/c?depth=3"
//   /status stays open: uptime/worlds/book-state, nothing a key ever rides on (.c only).
const token_ok = (req: any, url: URL) =>
    url.searchParams.get('token') === STATUS_TOKEN
    || req.headers['x-daemon-token'] === STATUS_TOKEN
    || req.headers['authorization'] === `Bearer ${STATUS_TOKEN}`
// safe_json — JSON.stringify that CANNOT throw on a live object graph.  Both of this server's
//  interesting routes serialise state that is supposed to be scalar and occasionally is not, and a
//   throw out of a node request handler is an uncaughtException, which arrest_watch turns into
//    exit 5.  So a read-only diagnostic could kill the daemon, from a GET.
//  Measured twice on 2026-08-08, and note WHERE it moved: first `/c` (a `Timeout` reached from the
//   C tree), then — after an incognito tab sealed a Pier — `/status`, because `stats()` reports each
//    House's `queued` and the Swarm's retransmit timers now live there.  `/status` had been safe all
//     night and became unsafe when the world gained a peer.  Guarding one route was not enough;
//      guarding the SHAPE is, so this is used for every response and the handler is wrapped too.
const safe_json = (v: any) => {
    const seen = new WeakSet()
    return JSON.stringify(v, (_k, val) => {
        if (val === null) return val
        const t = typeof val
        if (t === 'function') return '[function]'
        if (t === 'bigint' || t === 'symbol') return `[${t}]`
        if (t === 'object') {
            if (seen.has(val)) return '[circular]'
            seen.add(val)
            // A node Timeout (and anything else with a class that is not Object/Array) is state we
            //  never want to walk INTO — the point is to report that it is there, not to dump it.
            const ctor = val.constructor?.name
            if (ctor && ctor !== 'Object' && ctor !== 'Array') return `[${ctor}]`
        }
        return val
    }, 1)
}
const server = http.createServer((req, res) => {
  try {
    const url = new URL(req.url || '/', 'http://x')
    res.setHeader('content-type', 'application/json')
    if (url.pathname === '/status') return res.end(safe_json(stats()))
    if (url.pathname === '/c') {
        if (!token_ok(req, url)) { res.statusCode = 401; return res.end('{"error":"token required — ?token=<STATUS_TOKEN> or X-Daemon-Token header (logged once at boot)"}') }
        // the C tree at a bounded depth — the daemon's `snap`, without needing Story.
        // ⚠ THIS ENDPOINT MUST NOT BE ABLE TO KILL THE DAEMON, and it could: on 2026-08-08 a
        //  `/c?depth=8` threw `Converting circular structure to JSON` straight out of the request
        //   handler, which node turns into an uncaughtException — arrest_watch then did the right
        //    thing and exited 5.  A read-only diagnostic taking the process down is worse than the
        //     bug it was looking for, and the trigger is a query parameter.
        //  Cause: `.sc` is supposed to hold scalars only (CLAUDE.md: an object in sc is fatal at
        //   encode time), so SOMETHING is stashing a live object in an sc — a real bug elsewhere.
        //    This copies sc value-by-value and marks any non-scalar rather than trusting the law,
        //     because a diagnostic that only works on healthy trees is no diagnostic at all.
        const depth = Number(url.searchParams.get('depth') || 3)
        let nodes = 0
        const NODE_CAP = 20_000
        const scalars = (sc: any) => {
            const out: any = {}
            for (const k of Object.keys(sc ?? {})) {
                const v = (sc as any)[k]
                const t = typeof v
                out[k] = (v === null || t === 'string' || t === 'number' || t === 'boolean') ? v : `[${t}]`
            }
            return out
        }
        const dump = (n: any, d = 0): any => {
            if (d > depth) return '…'
            if (++nodes > NODE_CAP) return '…capped'
            return { sc: scalars(n.sc), kids: (n.o?.({}) ?? []).map((k: any) => dump(k, d + 1)) }
        }
        return res.end(safe_json(dump(H)))
    }
    if (url.pathname === '/stop') {
        if (!token_ok(req, url)) { res.statusCode = 401; return res.end('{"error":"token required — ?token=<STATUS_TOKEN> or X-Daemon-Token header (logged once at boot)"}') }
        stopping = true; return res.end('{"stopping":1}')
    }
    // /restock — drop THIS identity's radiostock shelf so the next tour re-digs it.
    //  WHY IT EXISTS: a stock card bakes decisions (the gain, the cut point, the preview window) that
    //   come from constants and from HOW it was measured.  Change any of those and every standing
    //    card keeps resurrecting the old answer forever, because `Ra_stock_standing` matches on the
    //     enid — a content hash of the SOURCE, which did not move.  There was no way to say
    //      "re-baseline" short of deleting files, and the shelf is not mine to delete from outside:
    //       /music is read-only to every container but this one.
    //  SAFE BY CONSTRUCTION, and worth saying why: `Ra_stock_ls` filters to this pub, so a daemon can
    //   only ever wear off its OWN shelf — never a browser identity's sharing the same .jamsend.  And
    //    a dropped card is one re-dig from the source, never a loss.
    if (url.pathname === '/restock') {
        if (!token_ok(req, url)) { res.statusCode = 401; return res.end('{"error":"token required — ?token=<STATUS_TOKEN> or X-Daemon-Token header (logged once at boot)"}') }
        const top = (H as any).top_House?.() || H
        const rw = top?.c?.radio_w
        const pub = rw ? (H as any).Radio_pub?.(rw) : null
        if (!pub) { res.statusCode = 409; return res.end('{"error":"no radio world / pub yet — the daemon is still coming up"}') }
        ;(async () => {
            // COUNT WHAT SURVIVED, not what was attempted.  The first cut of this counted calls to
            //  Ra_stock_drop and reported "dropped 20" while twenty files sat on disk untouched —
            //   that verb no-ops when the nav has no deleteEntry, which the node nav did not.  A
            //    before/after listing cannot tell that lie, so that is what it reports.
            const before = (await (H as any).Ra_stock_ls(nav, pub)).length
            try {
                for (const p of await (H as any).Ra_stock_ls(nav, pub)) await (H as any).Ra_stock_drop(nav, p.name)
            } catch (e: any) { say(`🎚 restock sweep threw — ${String(e?.message).slice(0, 80)}`) }
            const after = (await (H as any).Ra_stock_ls(nav, pub)).length
            say(`🎚 restock — ${before - after} of ${before} card(s) gone for ${String(pub).slice(0, 12)}`
                + (after ? `; ${after} REFUSED to drop (nav cannot delete?)` : '; the next tour re-digs them'))
        })()
        return res.end(`{"restocking":1,"pub":${JSON.stringify(pub)}}`)
    }
    res.statusCode = 404; res.end('{"paths":["/status","/c?depth=3 (token)","/stop (token)","/restock (token)"]}')
  } catch (e: any) {
    // The backstop.  Nothing this server does is worth the process, and everything above is a READ.
    try { res.statusCode = 500; res.end(`{"error":${JSON.stringify(String(e?.message || e))}}`) } catch {}
  }
})
server.listen(PORT, HOST, () => {
    say(`status on http://${HOST}:${PORT}/status`)
    say(`🔑 status token (for /stop and /c): ${STATUS_TOKEN}`)
})

process.on('SIGINT',  () => { say('SIGINT — stopping'); stopping = true })
process.on('SIGTERM', () => { say('SIGTERM — stopping'); stopping = true })

// ── the account mirror: the ONE call the app never makes ─────────────────────────────────────
// `Swarm_persist(nav, root, ident)` writes the identity to its two durable homes — the keyed account
//  at `.jamsend/account/<prepub>/toc.snap` (Swarm_account_save) and the pub-only recognition roster.
//   Auto's boot-seed READS that file (Auto.svelte:176, "Swarm_account_save has been writing the whole
//    account all along") — but **nothing in the app writes it.** grep the tree: every caller of
//     Swarm_persist / Swarm_account_save / Swarm_roster_save is inside the SwarmDisk Book. The read
//      side was wired 2026-08-04; the write side has no caller, so a browser with a cleared Dexie
//       arrests next to an account dir that was never created. That is Identity_persist_todo's
//        "editor lost its crypto again!?" with the cause in plain sight.
//  The daemon calls it itself. Not as a fix for the app — that is shared ground — but because it is
//   the only way to prove the seam end-to-end here, and because a daemon of all things must not keep
//    its sole copy of its key in a cache. Once per identity per boot (a version-bump throttle is what
//     the app wants; a daemon's identity does not churn). ACCOUNT=0 opts out.
//  Cheap and worth saying: this makes `I=<prepub>` work headlessly. The account dir IS the resume —
//   Swarm_boot_seed enumerates `.jamsend/account/*` and loads the wanted prepub, keys thawed. So the
//    daemon's identity becomes portable: copy the dir to another box, boot with I=<prepub>, same peer.
const ACCOUNT = process.env.ACCOUNT !== '0'
const persisted = new Set<string>()
// Say WHY it isn't mirroring, once per distinct reason.  A silent early-return here would read as
//  "the mirror is fine" while the daemon's only key sat in a cache — the exact failure this exists to
//   prevent, so the not-yet path has to be as legible as the done path.
let last_block = ''
const blocked = (why: string) => { if (why !== last_block) { last_block = why; say(`🪪… account mirror waiting — ${why}`) } }
const persist_account = async (): Promise<void> => {
    if (!ACCOUNT) return
    if (typeof (H as any).Swarm_persist !== 'function') { blocked('Swarm_persist not deposited'); return }
    const A = (H.o?.({ A: 'Clustation' }) ?? [])[0]
    const ident = ((A?.o?.({ Identity: 1 }) ?? []) as any[]).find(i => i.sc.active)
    if (!ident) { blocked('no active %Identity'); return }
    if (!ident.c?.keys) { blocked(`%Identity ${ident.sc.prepub} has no .c.keys`); return }
    if (!ident.sc.prepub) { blocked('active %Identity has no prepub'); return }
    if (persisted.has(ident.sc.prepub)) return
    persisted.add(ident.sc.prepub)
    try {
        await (H as any).Swarm_persist(nav, '', ident)
        say(`🪪 account mirrored → .jamsend/account/${ident.sc.prepub}/toc.snap (resume with I=${ident.sc.prepub})`)
    } catch (e: any) {
        persisted.delete(ident.sc.prepub)
        say(`⚠ account mirror failed: ${e?.message}`)
    }
}

// ── what collection can I actually see? (Daemon_todo §5.3 / §0 item 6) ───────────────────────
// A daemon whose job is "hold the collection" should say what it can reach, once, at boot — and it
//  should say it by walking the SAME verb the app walks (`Crate_nav_meander`), not by counting files
//   itself.  A private count would answer "is there music on disk?", which was never the question:
//    the question is "can the machine's own discovery path FIND it?", and those differ for exactly
//     the reasons the meander exists (the no-enumeration law, dot-dir skips, dead-end climbs).  An
//      instrument that agrees with the thing it measures by construction measures nothing.
//  Once per boot, non-fatal, and silent when there is nothing to say beyond the honest empty answer.
let mused = false
// the first thing the meander found, kept so the ffmpeg probe below can ask a REAL question of a REAL
//  file from the owner's collection rather than of a synthesised tone. A probe that only ever sees
//   audio we generated proves the spawn works and nothing about the library.
let mused_pick: string | null = null
const muse_collection = async (): Promise<void> => {
    if (mused) return
    if (typeof (H as any).Crate_nav_meander !== 'function') return   // ghosts still mounting — retry
    mused = true
    try {
        // The same base order Sounditron_muse uses, plus the mount name first when one is configured:
        //  a dev checkout's `testsounds` is 8 tracks, and finding those instead of a real collection
        //   is precisely the "proves plumbing, means nothing" outcome MUSIC= exists to end.
        const bases = mounts.music ? ['music'] : ['testsounds', 'music', '']
        for (const base of bases) {
            const picks: string[] = (await (H as any).Crate_nav_meander(nav, base, 5)) || []
            if (!picks.length) continue
            const where = base || '(share root)'
            // BASE-RELATIVE, so re-attach the base (Crate_nav_meander walks `base + '/' + rel` and
            //  hands back the rel half — Crate.g calls it "a BASE-RELATIVE path … offered as a bare
            //   key").  Stored raw, this named a file at the share root that does not exist, and the
            //    ffmpeg probe correctly reported `no native path` for it.
            mused_pick = base ? base + '/' + picks[0] : picks[0]
            say(`🎵 collection reachable via ${where} — meander picked ${picks.length}: ${picks.slice(0, 3).map(p => p.split('/').pop()).join(' · ')}`)
            return
        }
        say(`🎵 no music the meander can reach${mounts.music ? ` under ${mounts.music}` : ' — set MUSIC=1 to mount /music'}`)
    } catch (e: any) {
        say(`🎵 collection probe failed — ${String(e?.message).slice(0, 90)}`)
    }
}

// ── can this box do audio at all? (Daemon_todo §2.1/§2.2) ────────────────────────────────────
// The daemon's headless gap is audio, not networking: `Ra_lufs` measures through a Web Worker and
//  `Ra_encode_open` encodes through WebCodecs, so a daemon serves the pre-encoded preview window and
//   cannot carry a track past it.  ffmpeg is the answer, and it lives in the image (jamserve/Dockerfile).
// This probe reports the two facts that decide whether that answer is actually available HERE, once,
//  at boot — because the alternative is discovering it mid-heist on someone else's request:
//   (a) is there an ffmpeg to spawn, and (b) can it answer the real question, on a real file from
//    THIS collection.  (b) is the one that matters: (a) passing while (b) fails is an ffmpeg built
//     without the codec the library is actually in, which is invisible to a version string.
//  Non-fatal throughout — a box with no ffmpeg is a degraded box, not a broken one, and it should
//   say so plainly rather than boot green and disappoint a peer twenty minutes later.
let ffmpeg_probed = false
const ffmpeg_probe = async (): Promise<void> => {
    if (ffmpeg_probed) return
    // wait for the meander to have RUN (not to have found anything — an empty collection still
    //  deserves the version line).  Latching before it does would report "no track to measure" on a
    //   box whose library is fine, which is the wrong answer arriving early.
    if (!mused) return
    ffmpeg_probed = true
    try {
        const ff = await import('./ffmpeg.ts')
        const v = await ff.have()
        if (!v) { say(`🎬 no ffmpeg — this box serves preview windows only (§2.1)`); return }
        if (!mused_pick || typeof (nav as any).native_path !== 'function') { say(`🎬 ffmpeg ${v}`); return }
        const abs = (nav as any).native_path(mused_pick)
        if (!abs) { say(`🎬 ffmpeg ${v} — no native path for ${mused_pick}`); return }
        // the target is the WORLD's, never a constant in this file (trap 3 in ffmpeg.ts).  Fall back to
        //  the same -14 Ra_target_lufs defaults to, only when the ghost is not mounted yet.
        const target = typeof (H as any).Ra_target_lufs === 'function' ? (H as any).Ra_target_lufs(null) : -14
        const t0 = Date.now()
        const m = await ff.measure(abs, target)
        const secs = ((Date.now() - t0) / 1000).toFixed(1)
        if (ff.failed(m)) { say(`🎬 ffmpeg ${v} — measure failed on ${mused_pick.split('/').pop()}: ${m.why}`); return }
        const gain = +(target - m.lufs).toFixed(2)
        // BOTH peaks, on purpose.  `tp` is loudnorm's oversampled true peak; `pk` is astats' sample
        //  maximum, and `pk` is the one Ra_gain_for uses because it is what Ra_peak means.  Printing
        //   both is also the standing check that astats did not perturb the chain it rides in — the
        //    volumedetect trap (see ffmpeg.ts) showed up as tp MOVING when a meter was added.
        const pkdb = (20 * Math.log10(Math.max(1e-9, m.peak))).toFixed(2)
        say(`🎬 ffmpeg ${v} — measured ${mused_pick.split('/').pop()}: ${m.lufs} LUFS, tp ${m.measured.input_tp} dBTP, pk ${pkdb} dBFS (${m.peak_from})`
            + ` → ${gain >= 0 ? '+' : ''}${gain} dB to reach ${target} (${secs}s)`)
        // The ENCODE half is opt-in (FFTEST=1), because measuring a track costs seconds and
        //  transcoding one costs minutes — on every restart, and this box restarts on a timer.
        //   Measuring proves the binary can DECODE this collection, which is the fact that decides
        //    whether the rest is even possible; the encode is the thing worth proving once, by hand.
        if (process.env.FFTEST !== '1') return
        const e0 = Date.now()
        const lev = await ff.level_to_ogg(abs, target, m.measured)
        const esecs = ((Date.now() - e0) / 1000).toFixed(1)
        if ((lev as any).bytes === null) { say(`🎬 levelled encode FAILED — ${(lev as any).why}`); return }
        const L = lev as any
        say(`🎬 levelled encode OK — ${(L.bytes.length / 1048576).toFixed(2)}MB of Ogg/Opus @${L.bitrate},`
            + ` ${L.gain_db >= 0 ? '+' : ''}${L.gain_db} dB applied to reach ${L.target_lufs} LUFS (${esecs}s).`
            + ` Verified OggS + OpusHead.`)
        // The demux is the bridge to what Ra actually STORES (raw length-prefixed packets, not a
        //  container), so prove it on these bytes rather than on a fixture.  Cross-check the packet
        //   durations against the encode with the app's OWN parser (Ra_opus_samples reads each
        //    packet's TOC byte) — agreement between two independent readings of the same bytes is
        //     the only claim here worth making; a packet count alone would prove nothing about
        //      whether the lacing was reassembled correctly.
        const d = ff.demux_ogg_opus(L.bytes)
        if ((d as any).packets === null) { say(`🎬 demux FAILED — ${(d as any).why}`); return }
        const D = d as any
        let samples = 0
        if (typeof (H as any).Ra_opus_samples === 'function')
            for (const p of D.packets) samples += (H as any).Ra_opus_samples(p) || 0
        say(`🎬 demux OK — ${D.packets.length} opus packets, preskip ${D.preskip}, ${D.channels}ch @${D.sample_rate}`
            + (samples ? `, ${(samples / 48000).toFixed(1)}s of audio by Ra_opus_samples` : ''))
    } catch (e: any) {
        say(`🎬 ffmpeg probe failed — ${String(e?.message).slice(0, 120)}`)
    }
}

// ── arm native stocking: the thing that makes this daemon have anything to serve ──────────────
// THE GAP THIS CLOSES.  `Ra_stock_one` is the whole of stocking, and three of its steps are browser
//  primitives (OfflineAudioContext, the needles worker, WebCodecs).  Headless it threw on the first
//   of them, the stoker caught the throw, learned the path BARREN and moved on — so the daemon dug
//    the entire collection, reported a clean shelf of zero, and a sealed friend opened an empty
//     glass.  Nothing in any log said "I cannot do audio"; it said nothing at all.
// `Ra_native()` reads this object off the top House and forks those three steps to ffmpeg.  Set it
//  BEFORE the station comes up, so the first share beat's Stoker_tour already has it — arriving one
//   beat late is not fatal (the tour repeats) but it is a wasted pass that learns paths barren.
// Deliberately NOT gated on the meander finding anything: an empty collection still wants the
//  provider armed, because the mounts can change under a running daemon and the alternative is a
//   restart to pick up music that is already there.
let ra_native_armed = false
const ra_native_arm = async (): Promise<void> => {
    if (ra_native_armed) return
    if (!H || typeof (H as any).top_House !== 'function') return    // ghosts still mounting — retry
    ra_native_armed = true
    try {
        const { make_ra_native } = await import('./ra_native.ts')
        const provider = await make_ra_native(nav as any, say)
        if (!provider) return
        const top = (H as any).top_House() || H
        top.c.ra_native = provider
    } catch (e: any) {
        say(`🎚 native stocking failed to arm — ${String(e?.message).slice(0, 120)}`)
    }
}

// ── arm the Swarm station: the ONE call that lets this daemon ANSWER an invite ────────────────
// Daemon_todo §8.1/§9.2 step 4.  "An identity exists" and "the station is armed" are two entirely
//  disconnected facts, and the file conflated them for a while: `Swarm_station_world()` only does
//   `A.oai({w:'Swarm'})` — an inert container.  `Swarm_station_up` is what calls `Swarm_arm(w)` to
//    REGISTER the pier_hello/pier_accept handlers, dials Socket_real and hello-binds the key.  Until
//     it runs, an inbound pier_hello addressed to this daemon has nowhere to land, and the redeemer
//      sees a silence indistinguishable from a stranger.
// Mirrors InvitePanel.svelte's $effect without Svelte reactivity: RETRY, never latch on the first
//  attempt — the verb returns null while the transport ghosts are still depositing, so a latch would
//   permanently disarm a daemon that merely booted a beat early.
// It also rehydrates the stash BEFORE arming (Swarm.g:663-665 — piers, invites, chain roots), which
//  is exactly why tonight's ledger graft had to land first: without `%Idzeug` records under the live
//   %Peering, Swarm_hello's `o({ Idzeug: t.serial })[0]` misses and refuses('unknown') SILENTLY.
// Needs RELAY=1: with RELAY=0 the daemon deletes the WebSocket global and Swarm_station_up guards on
//  it (Swarm.g:669), so this would spin forever — say so once rather than look busy.
let stood = false
let station_note = ''
const station_up = (): void => {
    if (stood) return
    if (!RELAY) {
        if (station_note !== 'relay') { station_note = 'relay'; say('🤝 station not armed — RELAY=0, so invites cannot be answered (set RELAY=1)') }
        return
    }
    if (typeof (H as any).Swarm_station_up !== 'function') return          // ghosts still depositing
    const self = (H as any).Swarm_live_self?.()
    if (!self) return                                                      // identity not concrete yet
    const w = (H as any).Swarm_station_world?.()
    if (!w) return
    if ((H as any).Swarm_station_up(w, self)) {
        stood = true
        // Report what standup REHYDRATED, not just that it ran.  Swarm_station_up rebuilds piers,
        //  invites and chain roots from the Dexie stash before arming, so these counts are the
        //   daemon's memory of who it knows surviving a restart — the whole point of the ledger
        //    graft (§9.6 step 2), and previously invisible: a daemon that forgot every friendship
        //     looked exactly like one that had never had any.
        const peering = (H as any).Swarm_peering?.(self)
        const friends = peering?.o({ Pier: 1 })?.length ?? 0
        const izzes = peering?.o({ Idzeug: 1 })?.length ?? 0
        say(`🤝 Swarm station ARMED at ${self.sc?.prepub} — handlers registered; invites can be answered`
            + ` · remembers ${friends} friend(s), ${izzes} invite(s)`)
    }
}

// ── the SHARE — armed the way a TAB arms it ───────────────────────────────────────────────────
// THE BLOCKER, found 2026-08-08 with a friend sealed and nothing flowing.  A sealed peer exchanged
//  `ive_got` with this box every few seconds and the box held ZERO `%MusuThem`.  The reason is that
//   `Swarm_share_up` is not only "offer my stock": it calls `Repli_arm` and sets
//    `repli_mirror_by_from`, so it is equally the **rx registration for a friend's cast**.  Unarmed,
//     the census arrives and nothing consumes it.  Radio.g:1281 describes this box exactly — "it
//      never registers an rx for the friend's cast — it can neither send music nor receive it, while
//       looking perfectly healthy (sealed, Music-granted, happily playing its own local shelf)".
//  TWO arming paths exist and the daemon had NEITHER:
//   · `InvitePanel.svelte`'s $effect — a UI component, and the daemon mounts no room chrome.
//   · `Stoker_ensure`, gated on `!w.sc.w` so a Book never starts a wall-clock pump (correct) — and
//      jamserve boots `B=Sounditron`, so it wears that gate.
//  Teaching the ghosts a third state (Book / browser / prod-headless) is still the right fix and is
//   still owed (Daemon_todo §10.5 item 4).  This does not pre-empt it: it makes the daemon do what a
//    tab does — call the same verb, from outside, where "this process is a daemon" is a plain fact
//     rather than a flag the ghosts must learn.
//
// ⚠ THE CULL, HELD OFF DELIBERATELY.  Arming the share starts `Swarm_share_beat`, which calls
//  `Ra_shuffle_cull` (Swarm.g:1967) — "check every Record in the shuffle Mag still has its source and
//   DELETE the ones that don't" — on a box whose `deleteEntry` only became real this morning.  Two
//    newly-live deletion paths at once, pointed at the owner's music folder, is not something to
//     switch on while proving something else.  The hold uses the cull's OWN throttle rather than a
//      new flag: a fresh `ra_cull_at` plus an absurd `ra_cull_floor_ms` means every call takes the
//       early return it already has.  Nothing is patched out — the mechanism declines itself, and
//        `CULL=1` releases it in one env var when someone wants to watch it work.
const CULL = process.env.CULL === '1'
let share_armed = false
let share_note = ''
const share_arm = (): void => {
    if (share_armed || !stood) return                                      // station first — share needs its world
    if (typeof (H as any).Swarm_share_up !== 'function') return            // ghosts still depositing
    const self = (H as any).Swarm_live_self?.()
    const w = (H as any).Swarm_station_world?.()
    const rw = (H as any).top_House?.()?.c?.radio_w                        // stamped by Stoker_ensure
    if (!self || !w || !rw) return
    if (!CULL) { rw.c.ra_cull_at = Date.now(); rw.c.ra_cull_floor_ms = 1e15 }
    if ((H as any).Swarm_share_up(w, self)) {
        share_armed = true
        say(`📻 share ARMED — Repli rx registered; a friend's cast now mints %MusuThem, and the share beat turns`
            + (CULL ? '  ·  ⚠ CULL=1 — Ra_shuffle_cull is LIVE and deletes records whose source is gone'
                    : '  ·  Ra_shuffle_cull held off (CULL=1 releases it)'))
    } else if (share_note !== 'no') {
        // Swarm_share_no says WHY, once per distinct reason, on the station world — a reason that
        //  never changes is precisely the bug it was written to expose.  Don't re-say it every tick.
        share_note = 'no'
        say('📻 share did not arm yet — Swarm_share_no left the reason on the station world (retrying)')
    }
}

// ── §9.4's two-daemon invite harness — TEST-ONLY, NOT the production shape ────────────────────
// The responder half (station_up, above) is the real feature; this is the only way to EXERCISE it
//  without a human, and it should read that way forever.  Why it has to exist: **redemption is a UI
//   gesture** — `Swarm_redeem` is called from exactly one place in the tree, `InvitePanel.join()`,
//    behind a click or a Svelte $effect.  So there is no headless redeemer, and the owner ruled the
//     daemon is the RESPONDER and never the joiner (*"the ?Iz parsing would never happen on the
//      Daemon, it would be minting Grants for the clients that come along with them"*).  A daemon
//       that could redeem in production would be building the wrong thing; a daemon that can redeem
//        under an explicit env knob is a test rig.  Hence two knobs, both off by default, and the
//         redeem path never runs unless someone hands it a token.
//   MINT_INVITE=1   daemon A: mint one %Idzeug once the station is armed and print its token.
//   IZ=<token>      daemon B: redeem that token against A, over the real relay.
// Run them with DIFFERENT DAEMON_STATE dirs and DIFFERENT PORTs (the state lock is per-dir).
// This is a SMOKE TEST, NOT A GATE (§6) — it does not replace the two-tab fingers-test.
// A THROWAWAY MINTS AN INVITE, UNASKED (the owner, 2026-08-08: "perhaps the THROWAWAY IDENTITY could
//  log an invite to it, to make everything easy to test? then I can incognito-tab another Pier to
//   listen to a bit of daemon-served music!").  It costs nothing and it turns the least useful state
//    this box has into the most testable one: an identity nobody knows is exactly an identity that
//     needs to hand out a way to know it.
//  ONLY on a throwaway.  A provisioned box (I=<prepub>) is YOU, and a daemon that quietly minted
//   single-use invites to your real identity on every boot — into a logfile — would be handing out
//    your friendship without asking.  The gate is `!process.env.I`, deliberately the same condition
//     the nag uses, so "complains that it is a throwaway" and "is useful because it is one" can
//      never disagree.
const MINT_INVITE = process.env.MINT_INVITE === '1' || !process.env.I
const IZ = process.env.IZ || ''
let minted = false
let redeem_done = false
const invite_harness = async (): Promise<void> => {
    if (!stood) return                                   // handlers not armed yet — nothing to do
    const self = (H as any).Swarm_live_self?.()
    const w = (H as any).Swarm_station_world?.()
    if (!self || !w) return

    if (MINT_INVITE && !minted) {
        minted = true
        try {
            // REPRINT a standing unspent invite rather than minting another.  Two reasons, both
            //  found by watching it: the ledger reached "3 invite(s)" after three restarts, and —
            //   worse for a human — the printed link CHANGED every time, so a copied one went stale
            //    on a timer.  A daemon that restarts every 900s must not hand out a new capability
            //     each time it does.
            //  The token itself cannot survive: `Swarm_mint_idzeug` parks it on `record.c.token`,
            //   and `.c` is never encoded.  But every input to it IS durable — the nonce is the
            //    Idzeug's own mainkey value, `n` is a plain join of `to` + params, and ed25519
            //     signing is deterministic — so the same token recomputes exactly.
            let iz: string | null = null
            const peering0 = (H as any).Swarm_peering?.(self)
            const standing = (peering0?.o({ Idzeug: 1 }) ?? []).filter((z: any) => !z.sc.spent)[0]
            if (standing) {
                const params: any = {}
                for (const k of Object.keys(standing.sc)) {
                    if (k === 'Idzeug' || k === 'to' || k === 'chain' || k === 'spent') continue
                    params[k] = standing.sc[k]
                }
                const nonce0 = standing.sc.Idzeug
                const n0 = (H as any).Swarm_token_n(standing.sc.to, params)
                const presig0 = await (H as any).Swarm_presig(self.c.keys, self.sc.prepub, nonce0, n0)
                iz = (H as any).Swarm_token(self.sc.prepub, nonce0, n0, presig0)
                say(`🎟 reusing the standing unspent invite (serial ${nonce0}) — same link as last boot.`)
            }
            const b = new Uint8Array(6)
            ;(globalThis as any).crypto.getRandomValues(b)
            const nonce = Array.from(b, (x: number) => x.toString(16).padStart(2, '0')).join('')
            if (!iz) iz = await (H as any).Swarm_mint_idzeug(null, self, { Music: 1 }, nonce)
            // A URL, not just a token.  `?Iz=` on the page IS the redeem path a scanned invite takes
            //  (InvitePanel: a scan-landing auto-joins; a pasted link waits for a deliberate click),
            //   so an incognito tab opened on this link becomes a Pier and can listen.
            //  Printed against localhost rather than ORIGIN on purpose: ORIGIN is the docker-bridge
            //   address this container reaches the dev server by, and pasting that into a browser on
            //    the host gives a page with no secure context — WebRTC then refuses, which looks like
            //     a peering failure and is not one.
            const host = (process.env.INVITE_ORIGIN || 'http://localhost:9091').replace(/\/+$/, '')
            say(`🎟 INVITE — this box is a throwaway, so here is a single-use way in.`)
            say(`   Open in an incognito tab (single use — one Pier, then it is spent):`)
            say(`   ${host}/BigSoundland?Iz=${iz}`)
            say(`   (from another daemon instead:  IZ='${iz}' )`)
        } catch (e: any) { minted = false; say(`🎟 mint failed — ${e?.message}`) }
    }

    if (IZ && !redeem_done) {
        const t = (H as any).Swarm_token_parse?.(IZ)
        if (!t?.prepub) { redeem_done = true; say('🎟 IZ did not parse — ask for a fresh token'); return }
        // The signed hello must be BOUND at the relay before the redeem, or the inviter's reply has
        //  nowhere to land — same ordering InvitePanel.join() keeps (dial, wait for OPEN, one beat,
        //   then redeem).  Returning early here just retries on the next crank tick.
        const port = (w.o({ transport: 1, type: 'websocket' })[0] as any)?.c?.port
        if (port?.ws?.readyState !== 1) return
        redeem_done = true
        try {
            ;(H as any).Swarm_station_pier(w, self, t.prepub)
            await sleep(600)
            const claim = await (H as any).Swarm_redeem(w, self, IZ)
            if (!claim) { say(`🎟 REFUSED by ${t.prepub} — refused or unreachable (the rebuff rides the identity)`); return }
            say(`🎟 redeem ACCEPTED by ${t.prepub} — waiting for the seal…`)
            // "joined" means SEALED, not "hello sent": watch for the %Pier their pier_accept lands.
            for (let i = 0; i < 24; i++) {
                await sleep(500)
                if ((H as any).Swarm_peering?.(self)?.o({ Pier: 1, pub: t.prepub })[0]) {
                    say(`🤝 SEALED with ${t.prepub} — the friendship stands, both ends`)
                    return
                }
            }
            say('🎟 hello delivered but NO SEAL within 12s — the inviter heard us and did not finish')
        } catch (e: any) { say(`🎟 redeem failed — ${e?.message}`) }
    }
}

// ── the arrest is an EXIT, not a hatch (ruled 2026-08-07) ────────────────────────────────────
// The owner: "it should exit with error if the given ?I hasn't been set up in the share by a
//  browser client first."  Provisioning is BROWSER work — mint, Invites, grants, the usual
//   surfaces — and the share's .jamsend/account/<prepub>/ is the hand-off; a daemon only ever
//    RESUMES (Identity_persist_todo §7).  On a tab the arrest is a popover a human answers; here
//     it is a hang nobody reads, so turn it into a legible exit.  Two distinct failures, two exit
//      codes, decided by a direct fs look at the account file (we are node; a diagnostic needs no
//       nav):
//        exit 2 — CONFIG: no account for this prepub in the share.  Provision from a browser first.
//        exit 3 — BUG: the account IS on disk and the seed still could not adopt it.  Until
//                 Identity_persist_todo §6 gaps 2/3 land in Auto.svelte this is the EXPECTED
//                  outcome of every I= boot — the message names the doc so nobody re-diagnoses it.
//  The grace period matters for the post-gap-3 world: a SUCCESSFUL seed will clear
//   identity_pending in Clustation_concrete, so a slow disk read must not race the exit.
const ARREST_GRACE_MS = 10_000
let arrested_at = 0
const arrest_watch = async () => {
    if (!process.env.I) return
    const top = (H.top_House?.() ?? H)
    if (!top?.c?.identity_pending) { arrested_at = 0; return }
    if (!arrested_at) { arrested_at = Date.now(); return }
    if (Date.now() - arrested_at < ARREST_GRACE_MS) return
    const acct = `.jamsend/account/${process.env.I}/toc.snap`
    const why  = top.c.identity_pending_why ? ` (${top.c.identity_pending_why})` : ''
    if (existsSync(path.join(OVERLAY, acct)) || existsSync(path.join(ROOT, acct))) {
        say(`☠ identity ARRESTED with the account ON DISK (${acct})${why}`)
        say(`   The boot-seed could not adopt it — a bug, not a config error: Identity_persist_todo.md §6 gaps 2/3 (Auto.svelte).  exit 3`)
        await shutdown(3)
    }
    say(`☠ identity ARRESTED — no account for ${process.env.I} in the share (${acct} absent)${why}`)
    say(`   Provision it from a browser session first (mint + Invites there), then boot the daemon.  exit 2`)
    await shutdown(2)
}

// ── 5. run ───────────────────────────────────────────────────────────────────────────────────
let last_beat = 0
let last_full = 0        // when the heartbeat last printed its state lines in full
let last_sig = ''        // their content last time, so an unchanged beat stays silent
while (!stopping) {
    for (const h of allHouses(H)) if (!h.started) h.started = true

    // may_begin stands up A:<toplevel>/w:<toplevel>; Otro fires it once H.started, so do the same.
    // The seed must land BEFORE may_begin: Auto's adopt leg latches `identity_adopted` on its very
    //  first pass ("nothing to adopt — don't re-scan"), so a key stamped after that is never seen.
    if (!began && H.started && await seed_identity()) {
        began = true
        try { H.may_begin() } catch (e: any) { say(`⚠ may_begin threw: ${e?.message}`) }
        H.i_elvisto(H, 'think')
        say('may_begin — the world is standing up')
    }

    // Cyto is a graph view of a machine nobody is watching; it costs real CPU per particle.
    //  Same opt-out CredRunner takes, applied to every House as they appear.
    for (const h of allHouses(H)) {
        const o = h.The_Opt_val?.bind(h)
        if (o && !h._daemon_nocyto) { h._daemon_nocyto = true; h.The_Opt_val = (ww: any, k: string) => k === 'useCyto' ? false : o(ww, k) }
    }

    // the wormhole nav — injected through the seam the Wormhole worker leaves open
    //  (`if (!A.c.nav) … new WormholeNav(DL)`), so the browser's DirectoryOpener path never runs.
    //   Re-asserted every tick because A:Wormhole may not exist yet at boot.
    const WA = H.o({ A: 'Wormhole' })[0] || H.i({ A: 'Wormhole' })
    if (!WA.oa?.({ w: 'Wormhole' })) WA.i({ w: 'Wormhole' })
    if (!WA.c.nav) { WA.c.nav = nav; say('w:Wormhole ← node nav') }

    await persist_account()
    await muse_collection()
    await ffmpeg_probe()          // after the meander, so it can ask about a real track from it
    await ra_native_arm()         // before station_up, so the first share beat's tour can stock
    station_up()
    share_arm()                   // after the station: the share needs its world and identity concrete
    await invite_harness()
    await arrest_watch()

    wrap_probe()
    flushSync()
    const tt = liveTtlilts(H)
    for (const h of allHouses(H)) h.i_elvisto?.(h, 'think')
    await drain(); drains++
    flushSync()
    ticks++

    if (Date.now() - last_beat > 10_000) {
        last_beat = Date.now()
        const s = stats()
        // THE HEARTBEAT IS A PULSE, NOT A REPORT (the human 2026-08-08: "repeatedly logging so much
        //  crap is annoying, I can't see the tiny bits between them").  Three lines every ten seconds,
        //   each of them usually IDENTICAL to the last, buries the one line anyone is actually waiting
        //    for — a `pier_hello`, a want, a throw.  A log that scrolls its own furniture past the
        //     event is worse than a quieter one, because it looks like it is telling you everything.
        //  So the STATE lines print only when their content CHANGES, plus a full re-print every five
        //   minutes so someone tailing in late still gets the picture without waiting for a change.
        //    The ♥ pulse itself stays on every beat: it is the liveness signal, and it is one line.
        //  THE GATE MUST BE BUILT FROM VALUES, NOT FROM THE RENDERED LINES (2026-08-08, second go).
        //   The first cut hashed the finished strings, and one of them carries `tour 39.9s ago` — a
        //    number that changes every single beat by construction.  So the signature changed every
        //     beat, the gate never held, and the log looked exactly as noisy as before while the code
        //      claimed to be quiet.  A change-detector fed its own clock detects nothing.  `sig` is
        //       therefore assembled from the state that MEANS something, and elapsed-time readouts are
        //        printed but never signed.
        const worlds = s.houses.flatMap(h => h.worlds).join(' ')
        const lines: string[] = []
        const sig_of: any[] = [worlds]
        // The wedge belongs in the HEARTBEAT, not just in /status.  A wedged machine keeps ticking,
        //  keeps answering HTTP, and keeps looking alive — the same lie the tab tells (Housing's
        //   mutex() comment).  If the heartbeat doesn't say it, nobody finds out until they ask.
        say(`♥ ${s.up_s}s ${s.identity.active ? "🪪" + s.identity.active : "no-id"} ticks=${s.ticks} ttlilts=${s.ttlilts} houses=${s.houses.map(h => `${h.name}${h.todo ? ':' + h.todo : ''}`).join(' ')}`
            // >2s only: the mutex is held for a fraction of every ordinary pass, so sampling it
            //  bare reports a "wedge" whenever the heartbeat lands mid-think.  A wedge is a pass
            //   that STOPPED, and 2s is far past any healthy one.
            + (s.wedge && s.wedge.ms > 2000 ? `  ⚠ WEDGE ${Math.round(s.wedge.ms / 1000)}s by ${s.wedge.who}` : '')
            // ON THE PULSE, NOT IN THE CHANGE-GATE.  rss moves every single beat by construction, so
            //  putting it in `sig_of` would wedge the gate permanently open — the exact bug the
            //   `tour Ns ago` readout caused when this gate was first written.  It rides the ♥ line,
            //    which prints unconditionally anyway, and contributes nothing to the signature.
            + `  ${s.mem.rss}MB${s.mem.hi > s.mem.rss ? '/hi ' + s.mem.hi : ''}`
            // same reasoning as the wedge above: unprovisioned looks exactly like provisioned from
            //  out here, so the heartbeat has to carry it or nobody finds out.  Empty when correct.
            + nag_identity())
        if (s.wedge && s.wedge.ms > 2000) say(`   ↳ inside: ${probe_line()}`)
        lines.push(`   ▸ worlds=${worlds}`)
        if (s.book) {
            lines.push(`   ▸ Book ${s.book.Book} driving=${s.book.driving} phase=${s.book.phase} steps=${s.book.snapped}/${s.book.steps} ok=${s.book.ok} caveat=${s.book.caveat}`)
            sig_of.push(s.book.Book, s.book.driving, s.book.phase, s.book.snapped, s.book.steps, s.book.ok, s.book.caveat)
        }
        // The shelf, because "how much can this box serve" was the one number a sealed friend could
        //  see and the owner could not.  Only once native stocking is armed — on a browser-shaped
        //   boot the line would be noise.
        if (s.stock.native) {
            const f = s.stock.ff || {}
            const d = s.stock.dig
            lines.push(`   🎚 shelf=${s.stock.records} rec  them=${s.stock.them ?? 0} crate(s)  ffmpeg probed=${f.probed ?? 0} measured=${f.measured ?? 0} encoded=${f.encoded ?? 0} failed=${f.failed ?? 0}`
                + (d ? `  ·  dig[${d.state}] tour ${d.tour_ago_s == null ? 'NEVER' : d.tour_ago_s + 's ago'}`
                     + ` base=${d.base ?? '-'} picks=${d.picks} got=${d.got} dup=${d.dup} bad=${d.bad}${d.err ? ' err=' + d.err : ''}` : '')
                + (f.last_why ? `  ↳ ${String(f.last_why).slice(0, 110)}` : ''))
            // NOTE what is absent: `tour_ago_s`.  It is the most useful field on the line and the most
            //  useless one to sign — it counts up on its own, so signing it means signing the clock.
            //   `tour_at` crossing into a NEW tour shows up as picks/got/base changing, which are here.
            sig_of.push(s.stock.records, s.stock.them, f.probed, f.measured, f.encoded, f.failed, f.last_why,
                d && d.state, d && d.base, d && d.picks, d && d.got, d && d.dup, d && d.bad, d && d.err,
                d ? (d.tour_ago_s == null) : null)     // NEVER→ever is a real transition; the seconds are not
        }
        // The glass, and ONLY when it is actually rendering.  A faceless box must never print this
        //  line, so its APPEARANCE is the alarm — power cells being cut on a machine with no screen.
        //   Silence here is the correct reading, which is why it isn't a permanent field.
        const vy: any = s.vyto
        if (vy && vy.wall_cuts > 0) {
            lines.push(`   ▣ Vyto is RENDERING on a screenless box — stirs=${vy.stir_n} wall_cuts=${vy.wall_cuts}`
                + ` painted@${vy.painted_stir}  (FACELESS=${boot.faceless ?? 'Vyto'})`)
            sig_of.push('vyto-rendering')   // the FACT, not the counters — they climb every beat
        }
        // THE SERVE LINE — deliberately NOT change-gated with the furniture below, and deliberately
        //  absent when idle.  A serve ADVANCING is the news, not repetition to be suppressed; and
        //   silence here is a real reading — nobody is being fed — rather than a gap in the log.
        //    Put another way: every other line answers "is this box alive", this one answers "is it
        //     doing the thing it exists for".
        const sv = s.serve
        if (sv && sv.live.length) {
            for (const g of sv.live.slice(0, 3))
                say(`   🎧 serving ${friendly_of(String(g.to || ''))} ← ${String(g.title ?? g.id).slice(0, 46)}`
                    + ` ${g.n}/${g.total}` + (g.re ? ` (re×${g.re})` : '') + `  tx ${sv.tx_kbps}KB/s`)
            if (sv.live.length > 3) say(`   🎧 … and ${sv.live.length - 3} more record(s) in flight`)
        }
        const sig = JSON.stringify(sig_of)
        if (sig !== last_sig || Date.now() - last_full > 300_000) {
            last_sig = sig; last_full = Date.now()
            for (const l of lines) say(l)
        }
    }
    if (SECS && (Date.now() - t0) / 1000 > SECS) { say(`SECS=${SECS} reached`); break }

    const wait = tt.count > 0 ? Math.max(5, Math.min(120, Math.round((tt.soonest - now_s()) * 1000))) : 50
    await sleep(wait)
}

say('stopped — draining pending writes')
console.log = app_log
server.close()
await shutdown(0)
