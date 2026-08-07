// jamsend daemon — the machine, booted like a tab, with no tab.
//
//   npx vite-node -c scripts/daemon/daemon.vite.config.mjs scripts/daemon/main.ts
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
//   I=<tag>            boot as an idle runner-on-the-grid, no Book (the ?I= path)
//   ORIGIN=            what location.host becomes — the dev server Socket_real dials for /relay
//                       (default http://172.17.0.1:9091, the host as seen from this container)
//   SHARE=             repo/share root the wormhole nav reads (default cwd)
//   OVERLAY=           where writes land (default /tmp/jamsend_daemon/fs).  SAFE BY DEFAULT:
//                       the daemon does NOT write into the working tree.  OVERLAY=repo to opt in.
//   PORT=              status endpoint (default 9099).  curl localhost:9099/status
//   SECS=              exit after N seconds (0 = forever).  For scripted smoke runs.
//   QUIET=1            drop the app's own console noise, keep the daemon's own lines
import http from 'node:http'
import path from 'node:path'
import { appendFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { JSDOM } from 'jsdom'

const ROOT     = process.env.SHARE   || process.cwd()
const OVERLAY  = process.env.OVERLAY === 'repo' ? ROOT : (process.env.OVERLAY || '/tmp/jamsend_daemon/fs')
const ORIGIN   = process.env.ORIGIN  || 'http://172.17.0.1:9091'
const PORT     = Number(process.env.PORT || 9099)
const SECS     = Number(process.env.SECS || 0)
const QUIET    = process.env.QUIET === '1'
const t0       = Date.now()

// Log to a FILE as well as stdout, always.  A daemon's stdout is a pipe, and node block-buffers a
//  piped stdout — kill the process and the last 64KB of the story dies with it, which is exactly
//   the story you wanted (the first boot attempt here reported nothing but "Terminated").
const LOG = process.env.LOG || '/tmp/jamsend_daemon/daemon.log'
mkdirSync(path.dirname(LOG), { recursive: true })
const say = (m: string) => {
    const line = `[daemon ${((Date.now() - t0) / 1000).toFixed(1)}s] ${m}\n`
    process.stdout.write(line)
    try { appendFileSync(LOG, line) } catch {}
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

// indexedDB MUST BE REAL.  This is the first thing the daemon taught us, and it cost an afternoon:
//  Story_cli.setup.ts gets away with a no-op stub (a request object whose onsuccess never fires)
//   because a fixture Book never awaits Dexie.  A real boot does, immediately —
//    Housing.DirectoryOpener's very first act is `await fsh.start()` → restoreDirectoryHandle →
//     `await db.Handle.get(key)`.  Against the stub that promise NEVER SETTLES, and it is being
//      awaited inside the beliefs mutex, so the machine wedges on tick one holding the one lock
//       every House drains under.  Symptom: `beliefs mutex held 26s by H:Mundo think`, worlds
//        half-built, todo stuck at 2, and a process that looks perfectly healthy.
//  fake-indexeddb is a real IDB implementation, so every Dexie await settles.  It is MEMORY-ONLY:
//   identity and stash do not survive a restart yet — see Daemon_todo.md §3 for what durable needs.
await import('fake-indexeddb/auto')
// TWO GLOBALS, AND THEY DISAGREE — the trap that made this look fixed when it wasn't.
//  fake-indexeddb/auto picks its target as `typeof window !== "undefined" ? window : … global`.
//   We installed a jsdom `window` moments ago, so it lands on the WINDOW.  Dexie resolves its own
//    global as `globalThis`.  So out of the box: window has IDB, globalThis doesn't, Dexie throws
//     MissingAPIError — and the machine keeps running, because a Dexie that REJECTS unwedges the
//      beliefs pass exactly like a Dexie that works.  The wedge clearing is therefore NOT proof
//       that persistence works; only `dexie: indexedDB=true` below is.
//  So copy window → globalThis (never the reverse, which silently clobbers the real ones with
//   undefined — the first version of this loop did precisely that).
for (const k of ['indexedDB', 'IDBKeyRange', 'IDBCursor', 'IDBCursorWithValue', 'IDBDatabase',
                 'IDBFactory', 'IDBIndex', 'IDBObjectStore', 'IDBOpenDBRequest', 'IDBRequest',
                 'IDBTransaction', 'IDBVersionChangeEvent']) {
    if ((win as any)[k] !== undefined) (globalThis as any)[k] = (win as any)[k]
}
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

// The machine is a perpetual reactive system with fire-and-forget elvises; a late rejection is
//  normal weather, not a fault.  A daemon must never die of one.
process.on('unhandledRejection', (e: any) => { if (!QUIET) say(`⚠ unhandledRejection: ${e?.message ?? e}\n${(e?.stack ?? '').split('\n').slice(1, 7).join('\n')}`) })
process.on('uncaughtException',  (e: any) => say(`☠ uncaughtException: ${e?.stack ?? e}`))

const app_log = console.log
if (QUIET) console.log = () => {}

// ── 2. the machine ───────────────────────────────────────────────────────────────────────────
// Dexie snapshots the IDB globals into Dexie.dependencies at MODULE-EVAL time, so "did the shim
//  land before dexie loaded" is a yes/no we should be able to see, not infer from a stray rejection.
{
    const Dx: any = (await import('dexie')).Dexie
    say(`dexie: indexedDB=${!!Dx?.dependencies?.indexedDB} IDBKeyRange=${!!Dx?.dependencies?.IDBKeyRange}`)
}

const { mount, flushSync } = await import('svelte')
const { NodeWormholeNav }  = await import('../NodeWormholeNav')
const Daemonic             = (await import('./Daemonic.svelte')).default

// Reads fall through overlay → repo; writes land in the overlay.  Deliberately the TEST nav: a
//  daemon that scribbles toc.snaps into a working tree someone else is editing is a bad neighbour.
//   A real deployment points SHARE at its own share and OVERLAY=repo.
const nav = new NodeWormholeNav(ROOT, OVERLAY, false)

const boot: Record<string, any> = { toplevel: process.env.A || 'Auto' }
if (process.env.E) { boot.book = process.env.E; boot.boot_role = 'editor' }
else if (process.env.B) { boot.book = process.env.B; boot.boot_role = 'runner' }
else if (process.env.I) { boot.boot_role = 'runner'; boot.on_grid = process.env.I }

let H: any = null
say(`booting — relay=${RELAY ? "ON (RELAY=1)" : "off — set RELAY=1 to join, but read Daemon_todo §4 first"} origin=${ORIGIN} share=${ROOT} overlay=${OVERLAY} boot=${JSON.stringify(boot)}`)
mount(Daemonic, { target: win.document.body, props: { boot, onhouse: (h: any) => { H = h } } })
for (let i = 0; i < 100 && !H; i++) { flushSync(); await sleep(20) }
if (!H) { say('☠ no House — the shell never constructed one'); process.exit(1) }
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
const server = http.createServer((req, res) => {
    const url = new URL(req.url || '/', 'http://x')
    res.setHeader('content-type', 'application/json')
    if (url.pathname === '/status') return res.end(JSON.stringify(stats(), null, 1))
    if (url.pathname === '/c') {
        // the C tree at a bounded depth — the daemon's `snap`, without needing Story
        const depth = Number(url.searchParams.get('depth') || 3)
        const dump = (n: any, d = 0): any => d > depth ? '…' : { sc: { ...n.sc }, kids: (n.o?.({}) ?? []).map((k: any) => dump(k, d + 1)) }
        return res.end(JSON.stringify(dump(H), null, 1))
    }
    if (url.pathname === '/stop') { stopping = true; return res.end('{"stopping":1}') }
    res.statusCode = 404; res.end('{"paths":["/status","/c?depth=3","/stop"]}')
})
server.listen(PORT, () => say(`status on http://localhost:${PORT}/status`))

process.on('SIGINT',  () => { say('SIGINT — stopping'); stopping = true })
process.on('SIGTERM', () => { say('SIGTERM — stopping'); stopping = true })

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

say('stopped')
console.log = app_log
server.close()
process.exit(0)
