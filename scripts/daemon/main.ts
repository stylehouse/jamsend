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
        inside: probe_line(),
        book: book_state(),
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
const server = http.createServer((req, res) => {
    const url = new URL(req.url || '/', 'http://x')
    res.setHeader('content-type', 'application/json')
    if (url.pathname === '/status') return res.end(JSON.stringify(stats(), null, 1))
    if (url.pathname === '/c') {
        if (!token_ok(req, url)) { res.statusCode = 401; return res.end('{"error":"token required — ?token=<STATUS_TOKEN> or X-Daemon-Token header (logged once at boot)"}') }
        // the C tree at a bounded depth — the daemon's `snap`, without needing Story
        const depth = Number(url.searchParams.get('depth') || 3)
        const dump = (n: any, d = 0): any => d > depth ? '…' : { sc: { ...n.sc }, kids: (n.o?.({}) ?? []).map((k: any) => dump(k, d + 1)) }
        return res.end(JSON.stringify(dump(H), null, 1))
    }
    if (url.pathname === '/stop') {
        if (!token_ok(req, url)) { res.statusCode = 401; return res.end('{"error":"token required — ?token=<STATUS_TOKEN> or X-Daemon-Token header (logged once at boot)"}') }
        stopping = true; return res.end('{"stopping":1}')
    }
    res.statusCode = 404; res.end('{"paths":["/status","/c?depth=3 (token)","/stop (token)"]}')
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
            mused_pick = picks[0]
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
        if (m.measured === null) { say(`🎬 ffmpeg ${v} — measure failed on ${mused_pick.split('/').pop()}: ${m.why}`); return }
        const gain = +(target - m.lufs).toFixed(2)
        say(`🎬 ffmpeg ${v} — measured ${mused_pick.split('/').pop()}: ${m.lufs} LUFS, tp ${m.measured.input_tp} dBTP`
            + ` → ${gain >= 0 ? '+' : ''}${gain} dB to reach ${target} (${secs}s)`)
    } catch (e: any) {
        say(`🎬 ffmpeg probe failed — ${String(e?.message).slice(0, 120)}`)
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
const MINT_INVITE = process.env.MINT_INVITE === '1'
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
            const b = new Uint8Array(6)
            ;(globalThis as any).crypto.getRandomValues(b)
            const nonce = Array.from(b, (x: number) => x.toString(16).padStart(2, '0')).join('')
            const iz = await (H as any).Swarm_mint_idzeug(null, self, { Music: 1 }, nonce)
            say(`🎟 invite minted by ${self.sc?.prepub} (serial ${nonce}) — redeem from a second daemon with:`)
            say(`   IZ='${iz}'`)
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
    station_up()
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
        // The wedge belongs in the HEARTBEAT, not just in /status.  A wedged machine keeps ticking,
        //  keeps answering HTTP, and keeps looking alive — the same lie the tab tells (Housing's
        //   mutex() comment).  If the heartbeat doesn't say it, nobody finds out until they ask.
        say(`♥ ${s.up_s}s ${s.identity.active ? "🪪" + s.identity.active : "no-id"} ticks=${s.ticks} ttlilts=${s.ttlilts} houses=${s.houses.map(h => `${h.name}${h.todo ? ':' + h.todo : ''}`).join(' ')}`
            // >2s only: the mutex is held for a fraction of every ordinary pass, so sampling it
            //  bare reports a "wedge" whenever the heartbeat lands mid-think.  A wedge is a pass
            //   that STOPPED, and 2s is far past any healthy one.
            + (s.wedge && s.wedge.ms > 2000 ? `  ⚠ WEDGE ${Math.round(s.wedge.ms / 1000)}s by ${s.wedge.who}` : '')
            + `  worlds=${s.houses.flatMap(h => h.worlds).join(' ')}`)
        if (s.wedge && s.wedge.ms > 2000) say(`   ↳ inside: ${probe_line()}`)
        if (s.book) say(`   ▸ Book ${s.book.Book} driving=${s.book.driving} phase=${s.book.phase} steps=${s.book.snapped}/${s.book.steps} ok=${s.book.ok} caveat=${s.book.caveat}`)
    }
    if (SECS && (Date.now() - t0) / 1000 > SECS) { say(`SECS=${SECS} reached`); break }

    const wait = tt.count > 0 ? Math.max(5, Math.min(120, Math.round((tt.soonest - now_s()) * 1000))) : 50
    await sleep(wait)
}

say('stopped — draining pending writes')
console.log = app_log
server.close()
await shutdown(0)
