// sockcap — a browser-side tap on the /relay WebSocket, so the socket traffic a human reads in
//  DevTools → Network is captured into a ring and can be DUMPED to disk via the Wormhole before an
//   auto-reload wipes it (investigation scaffold; see Otro ?watch + Lies_dump_socklog).  ALMOST-GONER —
//    the roster/dispatch bug it chased is fixed, but KEPT DELIBERATELY (owner's call) as close-up
//     socket-traffic knowledge for future runner/relay debugging.  GENUINELY dormant unless armed: the tap
//      installs (and only then does the dump write) ONLY on ?socklog, or implied by ?watch=N — a plain
//       editor|runner tab captures NOTHING.  (Was always-on; that parked a full JSONL blob in an rw req
//        every ~10s.)  Arm with ?socklog for on-demand capture.  Rip out if it intrudes.
//
//  Why a global WebSocket tap and not a Socket_real hook: Socket_real lives in the FROZEN editor spine
//   (Tribunal.go, pinned) — untouchable from app code.  Wrapping the constructor + send catches EVERY
//    frame on the real socket exactly as the wire carries it, both roles, no spine edit.  Scoped to URLs
//     containing '/relay' so PeerJS signalling / other sockets don't pollute the log.
//
//  Records a SUMMARY per frame (to/type/seq/from/len), not full bodies — enough to see become_book's
//   address (a <pub> = individuated, 'runner' = the broadcast bug), advertise's from:<pub>, ping's
//    from:<pub>, and the ordering — without dumping payloads.

type Cap = { t: number; dir: '↑' | '↓'; to?: string; type?: string; seq?: number; from?: string; len: number; line?: string }

const CAP_MAX = 5000
const ring: Cap[] = []
export const SOCKCAP_BOOT = (typeof Date !== 'undefined' ? Date.now() : 0)   // one id per page life → its own dump file
let installed = false

function push(c: Cap) {
    ring.push(c)
    if (ring.length > CAP_MAX) ring.splice(0, ring.length - CAP_MAX)
}

// Pull a routing summary off a frame.  Text frames are {header:{to,type,seq}, …} with `from` riding
//  the consumer body (advertise/ping) or, for control frames, a bare {control,…}.  A binary frame is
//   [header JSON]\n[raw buffer]; we read only the header line.
function summarise(data: any, dir: '↑' | '↓'): Cap | null {
    try {
        if (typeof data === 'string') {
            const len = data.length
            let m: any
            try { m = JSON.parse(data) } catch { return { t: Date.now(), dir, type: '(non-json)', len } }
            const h = m?.header
            const from = m?.from ?? m?.header?.from ?? m?.body?.from ?? m?.payload?.from
            if (h) return { t: Date.now(), dir, to: h.to, type: h.type, seq: h.seq, from, len }
            // control:log carries the relay's own routing narration (→ <pub>/<runner> <type>) and our
            //  Lies_relay_note warnings — keep the line (truncated) so the dump shows WHERE frames went.
            if (m?.control === 'log') return { t: Date.now(), dir, type: 'control:log', len, line: String(m.line ?? '').slice(0, 240) }
            if (m?.control) return { t: Date.now(), dir, type: 'control:' + m.control, len }
            return { t: Date.now(), dir, type: '(headerless)', from, len }
        }
        // binary: header line up to the first '\n'
        let bytes: Uint8Array | null = null
        if (data instanceof ArrayBuffer) bytes = new Uint8Array(data)
        else if (data?.buffer instanceof ArrayBuffer) bytes = new Uint8Array(data.buffer)
        if (!bytes) return { t: Date.now(), dir, type: '(binary)', len: data?.size ?? data?.byteLength ?? 0 }
        const nl = bytes.indexOf(10)
        const headTxt = new TextDecoder().decode(nl < 0 ? bytes : bytes.subarray(0, nl))
        let h: any; try { h = JSON.parse(headTxt) } catch { h = null }
        return { t: Date.now(), dir, to: h?.to, type: (h?.type ?? 'binary') + '+buf', seq: h?.seq, len: bytes.length }
    } catch { return null }
}

// Install the tap once, browser-only.  Subclass WebSocket so a 'message' listener rides every relay
//  socket the page opens (incoming), and override send (outgoing).  Idempotent across HMR.
export function sockcap_install() {
    if (installed || typeof window === 'undefined' || typeof WebSocket === 'undefined') return
    installed = true
    const Orig = WebSocket
    const isRelay = (url: string) => typeof url === 'string' && url.includes('/relay')
    class Tapped extends Orig {
        constructor(url: string | URL, protocols?: string | string[]) {
            super(url as any, protocols as any)
            if (isRelay(String(url))) this.addEventListener('message', (ev: MessageEvent) => {
                const c = summarise(ev.data, '↓'); if (c) push(c)
            })
        }
        send(data: any): void {
            if (isRelay(this.url)) { const c = summarise(data, '↑'); if (c) push(c) }
            super.send(data)
        }
    }
    ;(window as any).WebSocket = Tapped
}

// The ring as JSONL, oldest→newest.  Read by Lies_dump_socklog and written to wormhole/_socklog/.
export function sockcap_lines(): string {
    return ring.map(c => JSON.stringify(c)).join('\n')
}
export function sockcap_count(): number { return ring.length }

// ── concap — a browser-side tap on console.{log,warn,error,info,debug} ────────────────────────────
//  The socket tap above catches WIRE frames; this catches the RAW console lines a human reads in
//   DevTools → Console (the `🛰 ws SEND/RECV` from Tribunal, `🛰☠ no Pier` drops from Peeroleum, the
//    `🦑` from Swarm, Story's beliefs narration).  Pulled READ-ONLY over the relay by `runner_ask
//     console` — no disk file, no reload once installed, no manual DevTools copy-paste.
//  UNCONDITIONAL at boot (concap_install from Otro), NOT arm-gated like sockcap: it is a pure
//   in-memory ring (bounded CON_MAX), never persisted, never snapped — so it costs a page nothing
//    but the ring, and is always there when a bug happens.  Off-snap runtime state: the ring is a
//     module-level array, never a C particle, so no Story fixture can ever see it.
type Con = { t: number; lv: 'log' | 'warn' | 'error' | 'info' | 'debug'; line: string }
const CON_MAX = 2000
const conRing: Con[] = []
let conInstalled = false
// serialise one console arg the way DevTools would show it, without exploding a deep object into the
//  ring.  Strings pass through; everything else is a compact JSON (or String() when it won't stringify,
//   e.g. an Error or a circular ref).  Bounded per-arg so one fat object can't blow the line length.
function conArg(a: any): string {
    if (typeof a === 'string') return a
    if (a instanceof Error) return a.stack ? String(a.stack) : `${a.name}: ${a.message}`
    try { const s = JSON.stringify(a); return s === undefined ? String(a) : s } catch { return String(a) }
}
function conPush(lv: Con['lv'], args: any[]) {
    let line: string
    try { line = args.map(conArg).join(' ') } catch { line = '(unserialisable console args)' }
    if (line.length > 2000) line = line.slice(0, 2000) + '…'
    conRing.push({ t: Date.now(), lv, line })
    if (conRing.length > CON_MAX) conRing.splice(0, conRing.length - CON_MAX)
}
// Install the console tap once, browser-only.  Wrap each level so the ORIGINAL still prints to DevTools
//  (a human at the tab loses nothing) AND the line lands in the ring.  Idempotent across HMR.
export function concap_install() {
    if (conInstalled || typeof window === 'undefined' || typeof console === 'undefined') return
    conInstalled = true
    for (const lv of ['log', 'warn', 'error', 'info', 'debug'] as const) {
        const orig = (console as any)[lv]?.bind(console)
        if (typeof orig !== 'function') continue
        ;(console as any)[lv] = (...args: any[]) => { try { conPush(lv, args) } catch {} ; orig(...args) }
    }
}
// The ring as an array of {t,lv,line}, oldest→newest, AFTER optional grep + tail.  Applied ring-side so
//  the relay reply carries only the N lines the caller wants, not the whole 2000-entry ring every read.
//   grep is a plain substring OR a /re/flags literal; matched against the line only (not the level).
export function concap_read(opts: { tail?: number; grep?: string } = {}): Con[] {
    let out = conRing
    if (opts.grep) {
        let test: (s: string) => boolean
        const m = /^\/(.*)\/([a-z]*)$/.exec(opts.grep)
        try { const re = m ? new RegExp(m[1], m[2]) : new RegExp(opts.grep.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')); test = (s) => re.test(s) }
        catch { const g = opts.grep; test = (s) => s.includes(g) }
        out = out.filter(c => test(c.line))
    }
    const tail = opts.tail && opts.tail > 0 ? opts.tail : out.length
    return out.slice(Math.max(0, out.length - tail))
}
export function concap_count(): number { return conRing.length }

// Persistent ARM flag (per-browser, localStorage — readable SYNCHRONOUSLY at boot, before the House or the
//  relay socket exist, which a particle|Dexie flag can't be).  Otro reads socklog_armed() to decide whether
//   to sockcap_install() this boot; the 🪪 Id toggle flips it.  A flip takes effect on the NEXT reload — the
//    tap has to be in place before the socket opens.
const ARM_KEY = 'socklog'
export function socklog_armed(): boolean {
    try { return typeof localStorage !== 'undefined' && localStorage.getItem(ARM_KEY) === '1' } catch { return false }
}
export function socklog_arm(on: boolean): void {
    try { if (on) localStorage.setItem(ARM_KEY, '1'); else localStorage.removeItem(ARM_KEY) } catch {}
}
