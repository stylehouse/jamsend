// The /relay endpoint — Peeroleum's real websocket transport (spec §4.1, §11.2, §17; heading 10).
//  A dumb address-routed frame forwarder. Each browser opens a SAME-ORIGIN socket
//   ws://<own-origin>/relay?addr=<its id> and every frame it sends is routed to the socket(s)
//    registered under frame.header.to. The relay reads only the header to route and never
//     inspects the body, so a signed/opaque body passes through untouched.
//
//  Two relays bridge each other server-to-server (no CORS at that layer): the runner-server
//   dials the editor-server ONCE over plain ws (?r2r=1). Routing is two-AP — local socket →
//    deliver, else hand once to the peer relay; with exactly two relays "not local → the other
//     one" is the whole table (no ARP, no discovery, no clue-queue). 802.11g picture: a relay
//      is the AP, header.to is the destination address.
//
//  Loop-safety is structural, not a flag: a frame from a BROWSER socket may be forwarded once
//   to the peer relay; a frame arriving over the peer link is deliver-local-or-drop, NEVER
//    re-forwarded. One hop, asymmetric rule ⇒ a frame cannot go around.
//
//  Role (editor|runner) is decided at runtime, commanded by the browser (Lies%runner sends
//   {control:'become',role:'runner'}), and is SET-ONCE: a conflicting reassignment throws
//    (errorific). No docker/env role config. The runner-server, once told, opens the single
//     r2r link to the editor's hardcoded endpoint and dials it once (v1: no auto-reconnect).
//
//  NB the half-removed server.ts/socket.io scaffold (vite.config.server.js) is a phantom — this
//   does not touch it. `ws` is already vite's transitive dep; no new package.

import { WebSocketServer, WebSocket } from 'ws'
import type { Server } from 'node:http'
import { writeFile, mkdir } from 'node:fs/promises'
import { resolve, dirname, sep } from 'node:path'
import { createHash } from 'node:crypto'
import { loadTrustedPubs, verifyHeader, prepubOf } from '../cluster_trust'
import { makeWatchDesk } from './watch'

// gen_write lands here: the editor compiles a ghost and, rather than pay the browser's
//  ~0.5s File-System-Access write, ships the .go down its relay socket for Node to write
//   straight to src/lib/gen/<…>.go — Vite then HMRs it to both origins (shared /app).  The
//    path is browser-supplied, so it is validated HARD: it must be a gen/**.go under this
//     resolved root, no traversal, bounded size.  Dev-only, localhost, but a write-to-disk
//      from a socket message gets a tight gate regardless.
const GEN_ROOT      = resolve('src/lib/gen')
const GEN_PATH_RE   = /^gen\/[A-Za-z0-9_][A-Za-z0-9_\-/]*\.go$/
const GEN_MAX_BYTES = 5_000_000

// The one hardcoded knob: where the runner-server dials the editor-server for the relay↔relay
//  bridge. Both servers run on localhost (runner :9091, editor|staging :9092), reachable over
//   plain ws without https. Override per-call (tests) or via the EDITOR_RELAY env var.
const DEFAULT_EDITOR_RELAY = 'ws://172.17.0.1:9092/relay?r2r=1'

const ATTACHED = Symbol.for('peeroleum.relay.attached')

// (There was a NOISY set here — ping/pong/ack, suppressed on the success path so the healthy
//  channel didn't flood the log. The tally below subsumes it and does better: those frames are now
//   COUNTED rather than hidden, so the heartbeat reads as a rate instead of as nothing.)

// ── the routing TALLY (the owner 2026-08-10: "tally these and dump them every 10s, one log line
//  per pub+type, to save log space") ────────────────────────────────────────────────────────────
//  A successful route used to print its own line.  During a heist that is a 32KB repli_page every
//   few ms per listener, and each line costs a JSON.stringify + a send to the editor socket
//    (relayLog broadcasts as control:log) — so the log was both unreadable AND a per-frame tax on
//     the exact path that is already the busiest thing the app does.
//  Now the success path only COUNTS, and a 10s timer prints one line per (addr, type, lane).  Two
//   tabs pulling music go from hundreds of lines per 10s to about eight.
//  What is NOT tallied, deliberately: DROPS (warnDrop escalates immediately — a drop is the thing
//   you are usually hunting), and every control/lifecycle event (hello, become, claim, bridge
//    up/down, gen_write).  Rate belongs in a tally; events belong in the log.
const TALLY_MS = 10000
type Tally = { n: number; bytes: number }
const tally = new Map<string, Tally>()
const TSEP = '\u0000'
//  A NUL, written as an ESCAPE on purpose (2026-09-10).  As a RAW byte it made git treat this whole
//   file as BINARY — `git diff` showed `Bin 70329 -> 73789 bytes` and nothing else, on the one file
//    whose review matters most here, and plain `grep` skipped it silently (you needed `-a` and had to
//     know to). Identical separator, identical runtime value, source stays pure ASCII and diffable.
function noteRoute(to: string, type: string, lane: string, bytes: number) {
	const k = to + TSEP + type + TSEP + lane
	let t = tally.get(k)
	if (!t) tally.set(k, (t = { n: 0, bytes: 0 }))
	t.n += 1
	t.bytes += bytes
}
function humanBytes(n: number): string {
	if (n < 1024) return `${n}B`
	if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)}KB`
	return `${(n / (1024 * 1024)).toFixed(1)}MB`
}

export type Role = 'editor' | 'runner'
type Meta = { addr: string | null; r2r: boolean }

export interface RelayHandle {
	wss: WebSocketServer
	readonly role: Role | null
	readonly localCount: number
	readonly peerReady: boolean
	close(): void
	// broadcast — a SERVER-ORIGINATED control frame to every local socket bound under one of `addrs`
	//  (default: `editor` + `hacker` + `player` — a hacker room binds the read-only player door, so
	//   `player` is where a code room actually listens; music pages ignore an unknown control).  The relay is the one party a tab has
	//   already trusted by dialling it (hello_ok/who_ok/census all ride this same lane), so a control
	//    frame from it needs no cluster signature — it is not a peer speaking, it is the wire.  Never an
	//     envelope (no header/seq/ack), never to a bridge or an identity addr.  Returns sockets reached.
	//      First use: the dev server's `digePlugin` announcing `control:'docindex'` on a source change.
	broadcast(frame: Record<string, unknown>, addrs?: string[]): number
}

export function attachRelay(
	httpServer: Server,
	opts: { path?: string; editorRelayUrl?: string } = {},
): RelayHandle {
	// Guard against vite re-running configureServer (config HMR) → double-attach.
	const existing = (httpServer as any)[ATTACHED] as RelayHandle | undefined
	if (existing) return existing

	const PATH = opts.path ?? '/relay'
	const editorRelayUrl = opts.editorRelayUrl ?? process.env.EDITOR_RELAY ?? DEFAULT_EDITOR_RELAY
	// BRIDGE OFF — "this relay has no peer" is a real configuration, and PRODUCTION is it.  Prod runs
	//  alone: no editor, no staging, nothing on its box's :9092.  With EDITOR_RELAY unset it fell through
	//   to DEFAULT_EDITOR_RELAY ('the other dev server on my box'), which there is an address that will
	//    never answer — so prod dialled ECONNREFUSED forever (observed: attempt 461, ~2h at the 15s cap,
	//     and the paired close:1006 with it).  The only way to express "don't bridge" used to be pointing
	//      EDITOR_RELAY at yourself to trip the self-dial guard, and that guard compares against
	//       `selfHost`, which is LEARNED FROM THE FIRST UPGRADE'S Host header — so whether the hack works
	//        depends on which request happens to arrive first.  Not something to deploy behind.
	//  Say it directly instead: EDITOR_RELAY=off|none|0|false|'' means no bridge, ever.  Nothing dials,
	//   nothing schedules, and it is said ONCE at attach rather than every 15s.
	const bridgeOff = !editorRelayUrl || /^(off|none|0|false)$/i.test(editorRelayUrl.trim())
	// Said once per attach — which also makes a DOUBLE attach visible.  Prod's log carried three
	//  independent re-dial counters at once (attempt 461 beside 25 and 30), i.e. three attachRelay
	//   closures alive in one process with no `handle.close()` between them.  One line per attach is
	//    how you see that happen instead of inferring it from interleaved counters.
	if (bridgeOff) console.log('🛰 relay attach — r2r bridge OFF (EDITOR_RELAY=' + JSON.stringify(process.env.EDITOR_RELAY ?? null) + '); this relay has no peer')

	const wss = new WebSocketServer({ noServer: true })
	const locals = new Map<string, Set<WebSocket>>() // addr → live browser sockets
	// corr → the socket that sent a ghost_compile.  The CLI (ghost_compile.ts) is NOT a bound peer
	//  (no ?addr=), so the editor's ghost_compile_ack can't be routed by header.to — instead we
	//   remember which socket asked, keyed by the frame's corr, and route the ack back to it.
	//    Entries are short-lived (cleared on the terminal done/error ack, the sender's close, or
	//     just superseded), so the map stays tiny.
	const ackBack = new Map<string, WebSocket>()
	// Multicast channels (spec §18).  A `to` starting with `@` is a TOPIC, not a peer addr: a
	//  publisher uploads ONE frame and the relay fans it out to every subscriber — the whole point being
	//   that a phone relaying to 100 listeners uploads once, not 100 addressed copies.  SUBSCRIBE reuses the
	//    existing `locals` machinery: bind(@channel, ws) adds the socket to the channel's Set, and deliverLocal
	//     (already a fan-out over that Set) does the multiplication with NO routing change.  CLAIM reserves the
	//      @name — first-come now (a community/crypto-signed gate is the future); ownership is recorded but
	//       publishing is NOT yet enforced against it (trust-everything v1, spec §5).  One relay instance for
	//        now, so a topic delivers LOCAL-only; cross-relay topic fan-out (forward to the bridge too) is the
	//         two-instance follow-up — penciled, not built.
	const claims = new Map<string, WebSocket>() // @channel → the socket that claimed the name
	let role: Role | null = null
	let peerLink: WebSocket | null = null // the single relay↔relay socket (either end)
	let selfHost = '' // our own host:port, learned from the first upgrade's Host header
	// r2r bridge auto-reconnect (runner end only).  A dropped/half-open bridge USED to wait for a
	//  browser (re)connect to re-dial — so an editor/staging restart with the runner's tabs left open
	//   stranded the bridge until a manual restart (you bouncing staging WAS the missing trigger). This
	//    is the server twin of Socket_real's onclose loop: schedule a backoff re-dial whenever the
	//     bridge goes down, until it is OPEN again — no browser reload, no manual restart needed.
	let closed = false // handle.close() called — stop re-dialing
	let redialTimer: ReturnType<typeof setTimeout> | null = null
	let redialTries = 0

	// The relay runs in the node dev server: its console.log lands in the terminal, drowned
	//  among svelte-check warnings. relayLog ALSO pushes the line down every local browser
	//   socket as a {control:'log'} frame, so it surfaces in that origin's browser console
	//    (Socket_real.onmessage routes control frames aside). One-way, server→browser; a log
	//     frame carries no header, so it never re-enters the routing/handler path.
	function relayLog(line: string) {
		const tag = `🛰 relay${selfHost ? '[' + selfHost + ']' : ''}${role ? '/' + role : ''}`
		console.log(`${tag} ${line}`)
		// control:log is the relay's routing narration surfaced in the browser console — but ONLY the
		//  EDITOR is the debugging surface for it.  Broadcasting to EVERY local socket flooded each runner
		//   tab's belief queue with frames it merely console-notes (a real death-spiral feeder).  Send it to
		//    the editor-bound socket(s) alone; on a runner relay that set is empty, so runners stop drowning.
		sendControlTo('editor', { control: 'log', line: `${tag} ${line}` })
	}
	// THE WATCH DESK (2026-09-17, src/lib/server/watch.ts): a socket asks `{control:'watch', paths:[…]}`
	//  for the files it holds open and hears `{control:'changed', path, dige, …}` when one moves on
	//   disk.  Per-socket interest, per-directory inotify, gentle GC — the shape the owner asked for
	//    once vite stopped watching wormhole/.  Its pushes go straight down the asking socket (never
	//     routed, never bridged), so the peer link is never involved.
	const watchDesk = makeWatchDesk(process.cwd(), (ws, frame) => {
		const s = ws as WebSocket
		if (s.readyState === WebSocket.OPEN) s.send(JSON.stringify(frame))
	}, (line) => relayLog(line))
	// Send a control frame to the live local browser socket(s) bound under one addr (e.g. 'editor').
	function sendControlTo(addr: string, obj: any) {
		const set = locals.get(addr)
		if (!set) return
		const text = JSON.stringify(obj)
		for (const ws of set) if (ws.readyState === WebSocket.OPEN) ws.send(text)
	}
	// Send a control frame to every live local browser socket (NOT the r2r peer link).
	// ONCE PER SOCKET, NOT ONCE PER BINDING (2026-09-10).  `locals` is addr → Set<socket> and one socket
	//  is deliberately bound under SEVERAL addrs — a Lies channel sits at its role AND, after hello, at
	//   its prepub, and a body may hold a granted seat besides.  Walking `locals.values()` therefore
	//    visits the same socket once per binding, and every control frame arrived DOUBLED or TRIPLED.
	//  Seen in the owner's own console 2026-09-10: `🌉 relay bridge DOWN` and `🌉 relay bridge UP`
	//   logged three times each, per event.  Harmless-looking, and not: `peer-relay` is broadcast on
	//    every failed r2r dial, so during a reconnect storm this multiplies the storm by the number of
	//     bindings each tab holds — noise the tab must parse, on the belief path, exactly when it is
	//      already struggling.  It also makes the log lie about how many events happened, which is how
	//       it stayed invisible: three DOWN lines read as three drops, not one drop counted thrice.
	function broadcastControl(obj: any) {
		const text = JSON.stringify(obj)
		const sent = new Set<WebSocket>()
		for (const set of locals.values())
			for (const ws of set) {
				if (ws.readyState !== WebSocket.OPEN || sent.has(ws)) continue
				sent.add(ws)
				ws.send(text)
			}
	}

	// CONTROL-PLANE DELIVERY, SEPARATE FROM DATA DELIVERY (2026-08-13, the regression this pairs with —
	//  read the AUTH-vs-DELIVERY note at handleHello first, this is its other half).  That note stopped a
	//   role-channel socket (?addr=runner|editor) joining its identity's `locals` fan-out, because `bind`
	//    is additive and every to:<prepub> frame — swarm frames, MUSIC CHUNKS — was being delivered twice,
	//     the phantom copy landing in w:Lies where nothing is armed to finish it.  That was right, and it
	//      broke something load-bearing that nothing tested: **`runner_ask` addresses a tab by its PREPUB,
	//       but the op handler that answers lives on the ROLE channel.**  So `to:'runner'` (the broadcast)
	//        kept working while every addressed ask — ping, state, steps, snap, supervisor, run — went
	//         silent, and `runner_ask` reads silence as "runner not connected".  The whole flock read as
	//          down for hours while every tab was alive and healthy; the census even said so, listing three
	//           live tabs it then refused to address ("role UNKNOWN — this tab won't say").
	//  The distinction the first cut was missing is not WHICH SOCKET but WHICH FRAME.  A role socket has no
	//   business receiving a music chunk and every business receiving a question about the tab.  So it joins
	//    a SECOND map keyed the same way, and delivery consults it only for the control-plane types below.
	//     Data frames are unchanged and still land exactly once, on the station socket.
	function bind(addr: string, ws: WebSocket) {
		let set = locals.get(addr)
		if (!set) locals.set(addr, (set = new Set()))
		set.add(ws)
	}
	function unbind(addr: string, ws: WebSocket) {
		const set = locals.get(addr)
		if (!set) return
		set.delete(ws)
		if (!set.size) locals.delete(addr)
	}
	// payload is the raw wire item — a string (text JSON frame) or a Buffer (a buffer-carrying
	//  binary frame, [header JSON]\n[raw buffer]).  ws.send carries either as-is (string → text
	//   message, Buffer → binary message); the relay never parses past the header line.
	// ONE DELIVERY DOOR PER ADDRESS (2026-08-13 — this replaces the AUTH-vs-DELIVERY cut made earlier the
	//  same day at handleHello, which was right about the problem and wrong about the remedy).
	//  THE PROBLEM, unchanged: a live tab opens TWO sockets that both hello-bind the SAME identity — the
	//   station (`?addr=<prepub>`, Swarm_station_up) and the Lies channel (`?addr=runner|editor`). `bind`
	//    is additive, so every `to:<prepub>` frame — swarm frames, MUSIC CHUNKS — was delivered TWICE, the
	//     phantom copy landing in w:Lies where no repli handler is armed. It is never finished, the inbox
	//      climbs to its 2000 cap, and every per-frame query is O(depth): the tab gets slower as it fills.
	//  THE WRONG REMEDY was to stop the role socket binding at all. It cost the **individuation contract**
	//   that `relay-test.ts` has asserted all along — *"a directed rungo to:<prepubA> must reach A ALONE"* —
	//    because a `?B=`/`?I=` runner has NO station socket: the role channel IS its only door. So every
	//     directed frame to such a tab vanished (`runner_ask` ping/state/steps/snap/supervisor/run all went
	//      silent while the broadcast `to:'runner'` still worked, and the whole flock read as disconnected
	//       for hours with every tab alive), and `who` reported live runners offline because presence counts
	//        `locals` membership. The harness said so; it went unread. **Run relay-test.ts after touching
	//         this file** — it encodes contracts no Book covers.
	//  THE RULE THAT SATISFIES BOTH: an address may have several bound sockets, but a frame addressed to it
	//   is delivered to its OWN door when it has one. A socket that opened `?addr=<the address being
	//    addressed>` is that address's station socket; when any such socket is bound, it alone receives, and
	//     a role socket that merely proved the same key is skipped. When none is (the `?B=`/`?I=` runner),
	//      every bound socket receives, exactly as before this whole episode.
	//  It falls out correctly for the non-prepub addresses too, with no special-casing: for `to:'runner'`
	//   NO socket claims the door (a role channel dials addr-less since 2026-09-10 — see below), so `own`
	//    is false and the broadcast fans out to every bound socket; for a subscribed channel no socket's
	//     qaddr is the channel name either, so all subscribers receive.
	//  ── A ROLE IS NOT AN ADDRESS (2026-09-10, the owner's call; client half in Tribunal.g `Socket_real`) ──
	//   `?addr=` used to carry an identity's front door AND a channel role into this one `locals`
	//    namespace, so "address" meant "or a role, sometimes".  The role half was pure redundancy:
	//     `become <role>` binds the same name one message later and also records `declaredRole`, which is
	//      strictly better evidence.  Clients now dial `?addr=` only for a real identity, which leaves
	//       `qaddr` meaning exactly ONE thing — "this socket is that address's own front door" — the very
	//        fact this rule wants.  Delivery did not move: `to:'runner'` fanned out before because ALL role
	//         sockets claimed the door and fans out now because NONE do.  (The relay still ACCEPTS
	//          `?addr=<role>`; nothing rejects it, and relay-test.ts's harness still dials that way.)
	//   ⚠ DO NOT re-key `own` on the socket's `bound` set instead — the obvious-looking "use the proven
	//    bind, not the claimed one" refactor.  A role channel hellos too, so its `bound` ALSO holds the
	//     prepub: both sockets would qualify, and every music chunk would be delivered twice again.
	function deliverLocal(to: string, payload: string | Buffer): boolean {
		const set = locals.get(to)
		if (!set || !set.size) return false
		// "Came in through THAT NAME's own front door" is the test, and a name has two kinds of door:
		//  `?addr=<name>` (an identity's station) and `become <name>` (a role channel — for a role,
		//   `become` IS the front door, and since 2026-09-10 it is the only one).  Both count.
		//  ⚠ COUNTING ONLY `qaddr` HERE SPLITS A MIXED FLEET, SILENTLY (caught by relay-test 2026-09-10,
		//   minutes after the addr-less change; it is why the first live runner to reload stopped
		//    answering a bare `ping` while `--runner=<prepub>` still worked).  One straggler still
		//     dialling `?addr=runner` — an un-reloaded tab, a daemon on old code, a test harness —
		//      CLAIMS the door at `runner`, `own` goes true, and every addr-less role channel is
		//       dropped from the `to:'runner'` broadcast.  Nothing errors; dispatch just stops finding
		//        half the flock.  Reading `declaredRole` too makes old and new sockets equal claimants,
		//         so the bucket fans out to both, which is what a role bucket has always meant.
		const ownsDoor = (ws: WebSocket) =>
			String((ws as any).qaddr || '') === to || String((ws as any).declaredRole || '') === to
		let own = false
		for (const ws of set) if (ws.readyState === WebSocket.OPEN && ownsDoor(ws)) { own = true; break }
		let delivered = false
		for (const ws of set)
			if (ws.readyState === WebSocket.OPEN && (!own || ownsDoor(ws))) {
				ws.send(payload)
				delivered = true
			}
		return delivered
	}

	// Set-once role. A conflicting reassignment is an error (errorific), surfaced to the caller.
	function setRole(next: Role) {
		if (role && role !== next) throw new Error(`relay role already '${role}', refusing '${next}'`)
		if (role === next) return
		role = next
		relayLog(`role set → ${role}`)
		if (role === 'runner') dialEditor()
	}

	// The runner-server reaches out to the editor ONCE — the "after the runner says hi, dial
	//  the other server" step. The single point everything downstream depends on: if this link
	//   never opens, every editor↔runner envelope is dropped at routeFromBrowser (no local
	//    addressee, no peer to forward to) and the browsers see only their own SENDs. So it is
	//     logged loudly: the target, a self-dial guard, open/error(code)/close, and a 5s
	//      not-connectable callback — all echoed to the browser via {control:'peer-relay'}.
	function dialEditor() {
		if (bridgeOff) return   // no peer relay configured — see `bridgeOff` above
		// A still-OPEN bridge is fine. But a STALE half-open peerLink (a bridge drop with no close
		//  event) is non-null yet dead — and would block every re-dial forever (browser refresh
		//   included) until a server restart: the "state stuckness". Treat a non-OPEN link as down —
		//    close it and dial fresh.
		// A CONNECTING link is ALIVE, not stale — leave it alone (2026-09-10).  `peerLink` is assigned
		//  the moment the socket is CREATED, several lines below, long before it opens.  So a second
		//   dialEditor() arriving during the connect window used to see "not OPEN", conclude the link
		//    was the stale half-open case, CLOSE it, and dial again — killing its own in-flight dial.
		//  That is a self-inflicted storm, and it fires on exactly the event that triggers many dials at
		//   once: `browser (re)connected, bridge down — re-dialing` runs per browser socket, so reloading
		//    a few tabs makes each one murder the previous tab's dial. The tell in the browser console is
		//     a burst of `🌉 relay bridge DOWN — error=WebSocket was closed before the connection was
		//      established` and `close:1006`, which is what the owner was looking at when they said
		//       "reloaded… everything's running slow as".
		//  The stale-link cure below still stands for a link that is CLOSING or CLOSED. A CONNECTING link
		//   that never opens is not orphaned either: the 5s watchdog already broadcasts and calls
		//    scheduleRedial, so the "state stuckness" this guard was written for cannot come back.
		if (peerLink && (peerLink.readyState === WebSocket.OPEN || peerLink.readyState === WebSocket.CONNECTING)) return
		if (peerLink) { try { peerLink.close() } catch {} ; peerLink = null }
		// Self-dial guard: the default editor-relay is hardcoded to :9091, but if THIS server is
		//  :9091 the runner dials itself — the r2r upgrade then hits the set-once role guard
		//   (already 'runner'), throws, and closes. Detect it and say so instead of failing mute;
		//    the fix is to point EDITOR_RELAY at the EDITOR origin's port (the other dev server).
		const target = (() => { try { return new URL(editorRelayUrl).host } catch { return '' } })()
		if (target && selfHost && target === selfHost) {
			const msg = `editor-relay points at SELF (${editorRelayUrl}) — bridge cannot form. Set EDITOR_RELAY to the EDITOR origin's port (the other dev server), not ${selfHost}.`
			relayLog(`✗ ${msg}`)
			broadcastControl({ control: 'peer-relay', up: false, error: 'self-dial', detail: msg, target: editorRelayUrl })
			return
		}
		relayLog(`dialing editor relay → ${editorRelayUrl} …`)
		const link = new WebSocket(editorRelayUrl)
		peerLink = link
		// 5s connectability watchdog: if the bridge has not reached OPEN, tell the browser it is
		//  not connectable, with whatever error code the socket captured. Cleared on open.
		let lastError = ''
		const watchdog = setTimeout(() => {
			if (link.readyState === WebSocket.OPEN) return
			const msg = `editor relay ${editorRelayUrl} not connectable after 5s (readyState=${link.readyState}${lastError ? ', ' + lastError : ''})`
			relayLog(`✗ ${msg}`)
			broadcastControl({ control: 'peer-relay', up: false, error: lastError || 'timeout', detail: msg, target: editorRelayUrl })
			scheduleRedial('not connectable after 5s') // a connect that never opens (black-hole) also retries
		}, 5000)
		link.on('open', () => {
			clearTimeout(watchdog)
			redialTries = 0                                            // a clean open resets the backoff for the NEXT outage
			;(link as any).isAlive = true                              // keepalive: the heartbeat round pings this outbound bridge too
			try { (link as any)._socket?.setNoDelay(true) } catch {}   // Nagle off on the r2r bridge too
			relayLog(`✓ peer relay LINKED (outbound r2r) → ${editorRelayUrl}`)
			broadcastControl({ control: 'peer-relay', up: true, target: editorRelayUrl })
		})
		link.on('pong', () => { (link as any).isAlive = true })        // re-proven each round — unmasks a half-open outbound bridge
		link.on('message', (data: any, isBinary: boolean) => routeFromPeer(isBinary ? asBuffer(data) : asText(data)))
		link.on('close', (code: number) => {
			clearTimeout(watchdog)
			if (peerLink === link) peerLink = null
			relayLog(`✗ peer relay CLOSED code=${code} → ${editorRelayUrl}`)
			broadcastControl({ control: 'peer-relay', up: false, error: `close:${code}`, target: editorRelayUrl })
			scheduleRedial(`bridge closed code=${code}`) // staging restart / network drop → heal on our own
		})
		link.on('error', (err: any) => {
			lastError = (err && (err.code || err.message)) || 'error'
			if (peerLink === link) peerLink = null
			relayLog(`✗ peer relay ERROR ${lastError} → ${editorRelayUrl}`)
			broadcastControl({ control: 'peer-relay', up: false, error: lastError, target: editorRelayUrl })
			scheduleRedial(`bridge error ${lastError}`) // editor not up yet → keep retrying with backoff
		})
	}

	// Schedule a backoff re-dial of the r2r bridge (RUNNER end only — the editor end is passive and
	//  cannot dial).  One timer at a time; a no-op once the bridge is OPEN again or the relay is
	//   closed.  Backoff 0.5s→1→2…capped 15s + jitter, mirroring Socket_real, so a relay/staging
	//    restart that drops every bridge at once doesn't thunder back in lockstep.  redialTries resets
	//     on a clean open.  This is what removes the "manual restart staging to recover" step.
	function scheduleRedial(why: string) {
		if (bridgeOff) return // no peer relay configured — never schedule, never storm
		if (closed || role !== 'runner') return // editor end never dials
		if (peerLink && peerLink.readyState === WebSocket.OPEN) return // already healthy
		if (redialTimer) return // one pending re-dial is enough
		const delay = Math.min(15000, 500 * Math.pow(2, redialTries++)) + Math.floor(Math.random() * 300)
		relayLog(`r2r re-dial in ${delay}ms (attempt ${redialTries}) — ${why}`)
		redialTimer = setTimeout(() => {
			redialTimer = null
			if (!closed) dialEditor()
		}, delay)
	}

	// A DROP is a real connectivity fault — a frame reached this relay addressed to someone with
	//  NO live local socket, so it is discarded. That is worth a WARNING, not a lost-in-the-noise
	//   info line: a single drop may be a connect race, but a REPEATING drop to the same addr is a
	//    wedged channel (the upload-only bug). Escalate: ⚠ on the first drop to an addr, then every
	//     Nth repeat, so it keeps complaining loudly without becoming a per-ping firehose. Reset the
	//      counter when that addr next delivers, so a healed channel goes quiet and a re-break re-warns.
	//  BOUNDED, because the key is a string off the wire (2026-09-10).  `to` comes straight out of an
	//   inbound frame header, and an entry is only ever removed when that EXACT addr later delivers —
	//    so a peer addressing many short-lived or bogus names grows this map for the life of the dev
	//     server, silently, with nothing failing.  That is the same shape as the doubled-delivery bug
	//      this file's own note describes (nothing errors; it just accumulates until it reads as "the
	//       app is slow"), so give it a ceiling.  The count is ONLY log-escalation state, so dropping
	//        it is free: the next drop to a forgotten addr warns as if it were the first, which is the
	//         honest thing to say anyway once we have stopped tracking it.
	const DROPCOUNT_MAX = 4096
	const dropCounts = new Map<string, number>()
	function noteDeliver(to: string) { if (dropCounts.has(to)) dropCounts.delete(to) }
	function warnDrop(where: string, to: string, kind: string, why: string) {
		const n = (dropCounts.get(to) ?? 0) + 1
		if (dropCounts.size >= DROPCOUNT_MAX && !dropCounts.has(to)) {
			relayLog(`⚠ drop-counter table hit ${DROPCOUNT_MAX} distinct addrs — clearing it; escalation restarts from the first warning`)
			dropCounts.clear()
		}
		dropCounts.set(to, n)
		if (n === 1 || n % 20 === 0)
			relayLog(`⚠ DROPPED ${where} ${kind} → '${to}' ×${n} — ${why}. Frames addressed to '${to}' are being discarded (no live socket bound here); that side's inbound is DEAD.`)
	}

	// A frame from a BROWSER socket: deliver local, else forward ONCE to the peer relay. payload
	//  is a string (text JSON frame) or a Buffer (binary [header JSON]\n[buffer]) — routed the same
	//   way, by header.to; the binary buffer tail is never inspected.
	function routeFromBrowser(payload: string | Buffer): 'local' | 'bridge' | 'dropped' {
		const bin = typeof payload !== 'string'
		const to = bin ? headerToBin(payload as Buffer) : headerTo(payload as string)
		if (!to) return 'dropped'
		// Heartbeat traffic (ping/pong/ack) is suppressed on the SUCCESS path — it would flood
		//  the log once the channel is healthy. A DROP is always logged, even for a ping: a
		//   dropped heartbeat is the symptom worth seeing (and only happens while unbridged).
		const type = bin ? frameTypeBin(payload as Buffer) : frameType(payload as string)
		const size = bin ? (payload as Buffer).length : (payload as string).length
		if (deliverLocal(to, payload)) { noteDeliver(to); noteRoute(to, type, 'local', size); return 'local' }
		if (peerLink && peerLink.readyState === WebSocket.OPEN) { peerLink.send(payload); noteRoute(to, type, 'bridge', size); return 'bridge' }
		// a DROP still speaks up the instant it happens — it is the thing you are usually hunting
		const kind = bin ? frameKindBin(payload as Buffer) : frameKind(payload as string)
		warnDrop('browser', to, kind, peerLink ? 'bridge not OPEN' : 'no bridge + no local socket')
		return 'dropped'
	}

	// A frame from the PEER relay: deliver local or drop. NEVER re-forwarded (the loop guard).
	function routeFromPeer(payload: string | Buffer) {
		const bin = typeof payload !== 'string'
		const to = bin ? headerToBin(payload as Buffer) : headerTo(payload as string)
		if (!to) return
		const type = bin ? frameTypeBin(payload as Buffer) : frameType(payload as string)
		const size = bin ? (payload as Buffer).length : (payload as string).length
		if (deliverLocal(to, payload)) { noteDeliver(to); noteRoute(to, type, 'from-bridge', size) }
		else {
			const kind = bin ? frameKindBin(payload as Buffer) : frameKind(payload as string)
			warnDrop('bridge→', to, kind, 'arrived over the r2r bridge but no local socket is bound')
		}
	}

	// ADDRESSABLE roles vs BRIDGE roles (2026-08-08, Daemon_todo §4a — the owner's ruling: the
	//  editor|runner restriction "should fall, dispatching only runners").  A `become` does TWO
	//   unrelated things, and conflating them is what kept the door shut on a third kind of peer:
	//    (1) bind(role, ws) — makes the socket REACHABLE at to:<role>.  Harmless for any name.
	//    (2) setRole(role) — decides which relay dials the r2r bridge.  SET-ONCE, and it THROWS on a
	//         conflicting reassignment.
	//  So widening (1) is safe and widening (2) is NOT: if a daemon's `become` reached setRole, then
	//   whichever peer connected first would win the relay's role, and the loser's become — quite
	//    possibly a real runner tab's — would throw `relay role already '…'`.  That is the "a bad
	//     relay edit takes every runner down" failure, reachable by simply relaxing the `if`.
	//  Hence: bind ANY sane role name; let only editor|runner steer the bridge.  Dispatch stays
	//   runner-only because dispatch addresses to:'runner', which no other role binds.
	//  ⇢ "Listing every bound role somewhere" WAS the owner's stated "maybe one day" and is now BUILT:
	//   `control:'census'` enumerates `locals` with each socket's declared role.  A daemon that binds a
	//    role name is therefore already visible without being dispatchable, which is the shape the
	//     comment above was reaching for.
	const BRIDGE_ROLES = new Set(['editor', 'runner'])
	// A bound name reaches into the `locals` routing map, so keep it a plain short token rather than
	//  whatever a peer felt like sending.  (Not a new exposure — `subscribe` already binds caller-
	//   chosen channel names — but there is no reason to widen the shape while widening the policy.)
	const SANE_ROLE = /^[A-Za-z0-9_:.-]{1,64}$/
	// …but an identity-SHAPED name is refused outright (2026-08-08, ClusterAddressing_todo §6).  A
	//  prepub is 16 hex chars, a full pub 64; `bind` is additive and `deliverLocal` fans out to the
	//   whole Set — so a `become <prepub>` would shadow-subscribe an UNAUTHENTICATED socket onto a
	//    hello-verified identity's frames (a copy of everything addressed to them: swarm frames, music
	//     chunks, wormhole replies).  Identity addresses are bound by signed `hello` ALONE; a role name
	//      has no business being pure hex.  NB the `?addr=` query is the same door still open — it is
	//       load-bearing for the pre-hello window (Swarm_station_up dials ?addr=<own prepub>), so
	//        closing it needs the §2 precondition (wait for hello_ok) first; refusing it here would
	//         drop legitimate first frames instead.
	const IDENTITY_SHAPED = /^[0-9a-fA-F]{16,}$/
	// Batch presence: one `who` frame asks about up to WHO_MAX addrs at once (the Radios friend
	//  roster is ~100; the cap is headroom, not a target).  Bounded so a hostile frame can't make
	//   the relay walk an unbounded list.
	const WHO_MAX = 512

	function handleControl(ws: WebSocket, msg: any) {
		if (msg.control === 'become' && typeof msg.role === 'string' && IDENTITY_SHAPED.test(msg.role)) {
			ws.send(JSON.stringify({ control: 'error', error: `become '${msg.role.slice(0, 12)}…' refused — identity-shaped; identities bind via signed hello only` }))
			relayLog(`✗ become REFUSED (identity-shaped) '${msg.role.slice(0, 16)}' — a role name is never pure hex; signed hello is the identity bind`)
			return
		}
		if (msg.control === 'become' && typeof msg.role === 'string' && SANE_ROLE.test(msg.role)) {
			// Bind this socket under its ROLE addr so role-addressed frames actually reach it —
			//  the editor↔runner ping/pong keepalive (and any to:'runner'/'editor' traffic) is
			//   addressed by role, and without a binding every such frame DROPS at deliverLocal
			//    ("no local socket for runner" — the upload-only channel).  This is what the
			//     ?addr=<role> query was meant to guarantee; binding here makes it robust even
			//      when the socket didn't (or couldn't) carry ?addr=.  Independent of the set-once
			//       relay ROLE below (which only decides who dials the r2r bridge): a socket whose
			//        become LOSES the role race must still be reachable at to:<role>, so bind first,
			//         unconditionally, and track it for unbind on close (drop()).
			// ── THE THIRD THING A `become` MEANS, now kept as a fact of its own (2026-09-09) ──
			//  The note above names two: bind (reachable at to:<role>) and setRole (who dials the
			//   bridge).  There is a third tangled into the first — **this socket's own role**, "the
			//    tab that dialled here is a runner".  Nothing recorded it; it was only ever inferable
			//     from who happened to be BOUND at the shared name, which is precisely why deleting
			//      that name would have thrown the knowledge away with it.
			//  So say it directly.  Costs one property, changes no routing, and makes the role
			//   survive the address: `census` can answer "which tabs are runners" without anyone
			//    being bound at `runner` at all, which is what step 3 of the ?addr=runner removal
			//     needs (Social_demarcation_todo §0).
			//  It is also BETTER EVIDENCE than the alternatives.  `qaddr` is only what the socket
			//   dialled with (a tab may carry none); an ack's self-reported role is the fact
			//    runner_ask's own `isRunner` comment calls useless, since a Sounditron answers
			//     `role:'runner'` while being someone's music page.  This is what the socket
			//      DECLARED, at the one moment it declares anything.
			;(ws as any).declaredRole = msg.role
			bind(msg.role, ws)
			;((ws as any).roleBound ??= new Set<string>()).add(msg.role)
			relayLog(`🎭 become ${msg.role} — bound addr=${msg.role} (locals: ${[...locals.keys()].join(',')})`)
			// A NON-BRIDGE role (a daemon, and whatever comes after it) is now reachable at to:<role>
			//  and stops there: it must never touch the set-once relay role, or the first such peer to
			//   connect would lock the bridge and every later editor|runner become would throw.  Ack
			//    with the role it asked for, and report the relay's own role as-is (possibly unset).
			if (!BRIDGE_ROLES.has(msg.role)) {
				ws.send(JSON.stringify({ control: 'role', role: msg.role, bridge: role ?? null }))
				return
			}
			try {
				setRole(msg.role as Role)
				ws.send(JSON.stringify({ control: 'role', role }))
			} catch (e) {
				ws.send(JSON.stringify({ control: 'error', error: String((e as Error).message) }))
			}
			return
		}
		if (msg.control === 'gen_write') { void handleGenWrite(ws, msg); return }
		if (msg.control === 'hello') { void handleHello(ws, msg); return }
		// census (asker → relay): WHO IS BOUND HERE, answered from the relay's own tables.
		//  Discovery has always been done by BROADCAST — an ask to the well-known role name `runner`,
		//   which `deliverLocal` fans to every socket bound under it.  That works for one tab and lies
		//    for two: the asker's `corr` is spent on the FIRST ack, so one broadcast finds exactly one
		//     tab however many answered, and enumerating a flock needs repeated stochastic rounds with a
		//      minimum-round floor because "an early-stopping census under-reports" (runner_ask.mjs).
		//  None of that is necessary. The relay HOLDS the answer: `locals` is addr → sockets, and every
		//   socket carries the `bound` Set that `hello` filled plus the `qaddr` it dialled with. So it
		//    can simply say, once, deterministically — no rounds, no rotation, no floor.
		//  This is step 1 of removing the `?addr=runner` socket entirely (Social_demarcation_todo §0).
		//   It is deliberately ADDITIVE: it introduces no new routing and changes no existing frame path,
		//    so it can land and be proven live before anything starts depending on it.
		//  It reports ADDRESSES, never sockets or their contents — the same names any peer could already
		//   discover by addressing them. `identity` marks a prepub-shaped name (a real bound tab) apart
		//    from a role name like `editor`, so a caller can prefer the individual over the shared seat.
		if (msg.control === 'census') {
			// GATED EXACTLY AS `who` IS, and for the same reason (2026-09-09).
			//  The first cut of this shipped ungated, on the argument that it was no worse than the debug
			//   surface §3.4.3 already records.  That argument was WRONG and the difference matters: every
			//    op in §3.4.3 has to reach a TAB, which can refuse, arm itself, or not exist.  This is
			//     answered by the RELAY, to any socket that connects, with no tab involved at all.
			//  And the relay is not only the dev server: `docker-compose.prod.yml:33` runs `npx vite`, so
			//   `relayPlugin()` attaches in PRODUCTION too — an ungated enumerator here is reachable by
			//    anyone who can open a WebSocket to the public box.
			//  What it would hand out is the bound identity list, which is PRESENCE — the very thing `who`
			//   twenty lines below refuses to unverified askers ("presence answers only to verified
			//    identities").  Enumerating who is online is strictly more than `who` gives, since `who`
			//     only confirms names the asker already held.  Same door, same lock.
			//  COST, accepted deliberately: `runner_ask` connects with a bare `?addr=` and signs no hello,
			//   so it cannot pass this gate and falls back to the broadcast court it used before tonight.
			//    That loses the CLI's deterministic discovery until asks are signed (§3.4.3) — a
			//     convenience — rather than leaving presence readable by strangers — a property.
			//      The fallback is already there and already worked; nothing breaks, it only gets vaguer.
			{
				const asker = (ws as any).bound as Set<string> | undefined
				if (!asker || !asker.size) {
					try { ws.send(JSON.stringify({ control: 'census_error', reason: 'not hello-bound — the bound list is presence, and presence answers only to verified identities', corr: msg.corr ?? null })) } catch {}
					if (!(ws as any).censusRefused) { (ws as any).censusRefused = 1; relayLog(`✗ census REFUSED — asking socket has no verified hello bind`) }
					return
				}
			}
			relayLog(`👥 census asked — ${locals.size} bound name(s)`)
			const rows: { addr: string, identity: boolean, sockets: number, roles: string[] }[] = []
			for (const [addr, set] of locals) {
				let live = 0
				const roles = new Set<string>()
				for (const s of set) {
					if (s.readyState !== WebSocket.OPEN) continue
					live++
					// the DECLARED role first — what the socket said it is, at `become`.  `qaddr` is the
					//  fallback for a socket that dialled a role door without declaring (and for anything
					//   predating the declaration), so this reads the same today and keeps reading right
					//    once nothing binds a shared role name any more.
					const d = String((s as any).declaredRole || '')
					const q = String((s as any).qaddr || '')
					const r = d || q
					if (r && r !== addr) roles.add(r)
				}
				if (!live) continue
				rows.push({ addr, identity: IDENTITY_SHAPED.test(addr), sockets: live, roles: [...roles] })
			}
			rows.sort((a, b) => (a.identity === b.identity ? (a.addr < b.addr ? -1 : 1) : a.identity ? -1 : 1))
			try { ws.send(JSON.stringify({ control: 'census', rows, corr: msg.corr ?? null })) } catch {}
			return
		}
		// claim (publisher → relay): reserve an @channel.  First-come: granted if unclaimed or already this
		//  socket's; a live foreign owner refuses (claim_error).  Recorded for the future crypto gate; publishing
		//   is not enforced against it yet.  Tracked on the socket so its close releases the name.
		if (msg.control === 'claim' && typeof msg.channel === 'string') {
			const ch = msg.channel
			const cur = claims.get(ch)
			if (cur && cur !== ws && cur.readyState === WebSocket.OPEN) {
				try { ws.send(JSON.stringify({ control: 'claim_error', channel: ch, reason: 'taken' })) } catch {}
				relayLog(`✗ claim ${ch} REFUSED — already owned`)
			} else {
				claims.set(ch, ws)
				;((ws as any).owns ??= new Set<string>()).add(ch)
				try { ws.send(JSON.stringify({ control: 'claimed', channel: ch })) } catch {}
				relayLog(`🎙 claim ${ch}`)
			}
			return
		}
		// subscribe (listener → relay): join the @channel's fan-out set.  bind() into `locals` IS the
		//  subscription — deliverLocal then reaches us on every publish, no routing change.  Tracked on the
		//   socket so close unbinds every channel, not just meta.addr.
		if (msg.control === 'subscribe' && typeof msg.channel === 'string') {
			const ch = msg.channel
			// A subscribe binds into the SAME `locals` Set an identity's hello-bind uses, and deliverLocal
			//  fans out regardless of how a socket got bound — so an unqualified subscribe is the OTHER
			//   shadow-subscribe door beside `become` (ClusterAddressing_todo §6, finding #3): `{subscribe,
			//    channel:<victim-prepub>}` would splice an unauthenticated socket onto that identity's frames.
			//     Legitimate channels are ALWAYS `@`-prefixed (the delivery path only treats to[0]==='@' as a
			//      channel — Peeroleum_deliver, Peeroleum.g), so REQUIRE it: a non-`@` subscribe is either a
			//       mistake or this attack, never a real listener. (The `?addr=<prepub>` door stays open — it
			//        is load-bearing for the pre-hello station bind and needs the §2 hello_ok precondition.)
			if (ch[0] !== '@' || !SANE_ROLE.test(ch.slice(1))) {
				try { ws.send(JSON.stringify({ control: 'subscribe_error', channel: ch, reason: 'channel must be @-prefixed (identity addresses bind via signed hello, not subscribe)' })) } catch {}
				relayLog(`✗ subscribe REFUSED '${ch.slice(0, 20)}' — not an @channel; identities never bind via subscribe`)
				return
			}
			bind(ch, ws)
			;((ws as any).subs ??= new Set<string>()).add(ch)
			try { ws.send(JSON.stringify({ control: 'subscribed', channel: ch })) } catch {}
			relayLog(`📻 subscribe ${ch} (subs: ${locals.get(ch)?.size ?? 0})`)
			return
		}
		if (msg.control === 'unsubscribe' && typeof msg.channel === 'string') {
			const ch = msg.channel
			unbind(ch, ws)
			;(ws as any).subs?.delete(ch)
			relayLog(`📻 unsubscribe ${ch} (subs: ${locals.get(ch)?.size ?? 0})`)
			return
		}
		// watch / unwatch (tab → relay): fixation on files (watch.ts).  Idempotent — a tab re-sends its
		//  whole list on every reconnect, since interest dies with the socket.  The ack names what was
		//   refused and why (outside the fence, no such directory, over budget) so a bad path is visible
		//    in the tab rather than silently unwatched; the count line here is the terminal's view.
		if (msg.control === 'watch' && Array.isArray(msg.paths)) {
			const r = watchDesk.watch(ws, msg.paths)
			try { ws.send(JSON.stringify({ control: 'watch_ok', ok: r.ok.length, refused: r.refused.slice(0, 32), corr: msg.corr ?? null })) } catch {}
			const st = watchDesk.stats
			relayLog(`👁 watch +${r.ok.length}${r.refused.length ? ` ✗${r.refused.length} (${r.refused[0].why})` : ''} — ${st.paths} paths in ${st.dirs} dirs for ${st.sockets} socket(s)`)
			return
		}
		if (msg.control === 'unwatch' && Array.isArray(msg.paths)) {
			const n = watchDesk.unwatch(ws, msg.paths)
			const st = watchDesk.stats
			if (n) relayLog(`👁 unwatch -${n} — ${st.paths} paths in ${st.dirs} dirs`)
			return
		}
		// who (peer → relay): BATCH presence probe — which of these addrs are online right now?
		//  Replaces the speculative fan-out (one pulse/swarm_hi per friend, most of them offline,
		//   with every miss dying silently in warnDrop — the sender can never learn).  One frame up,
		//    one frame down, O(1) Map lookup per addr against `locals`, which the 15s heartbeat keeps
		//     honest (a half-open socket is terminated + unbound within ~2 rounds).
		//  STRICTER than routing, deliberately: an addr counts as online only if some OPEN socket
		//   was bound to it by a VERIFIED hello ((ws).bound) — the `?addr=` pre-hello door still
		//    binds into `locals` for routing (load-bearing, ClusterAddressing_todo §6.4), but a
		//     pre-claiming eavesdropper must not make an identity read as present.
		//  Leak gate: presence is answered only to a socket that is ITSELF hello-bound, and only
		//   list-in (asked addrs), never enumerate-out — `locals`' roster stays unlistable (the
		//    owner's parked "maybe one day", §4a note above).
		if (msg.control === 'who' && Array.isArray(msg.addrs)) {
			const asker = (ws as any).bound as Set<string> | undefined
			if (!asker || !asker.size) {
				try { ws.send(JSON.stringify({ control: 'who_error', reason: 'not hello-bound — presence answers only to verified identities', corr: msg.corr })) } catch {}
				// once per socket: an unbound asker re-asks on ITS pulse round too, so the refusal is
				//  as repetitive as the answer.  The first one is the diagnostic; the rest are noise.
				if (!(ws as any).whoRefused) { (ws as any).whoRefused = 1; relayLog(`✗ who REFUSED — asking socket has no verified hello bind`) }
				return
			}
			const asked = msg.addrs.slice(0, WHO_MAX)
			if (msg.addrs.length > WHO_MAX) relayLog(`⚠ who list truncated ${msg.addrs.length}→${WHO_MAX}`)
			const online: string[] = []
			for (const a of asked) {
				if (typeof a !== 'string') continue
				const set = locals.get(a)
				if (!set) continue
				for (const s of set)
					if (s.readyState === WebSocket.OPEN && ((s as any).bound as Set<string> | undefined)?.has(a)) { online.push(a); break }
			}
			try { ws.send(JSON.stringify({ control: 'who_ok', online, asked: asked.length, corr: msg.corr })) } catch {}
			// LOG TRANSITIONS ONLY.  who rides the ~10s pulse round of every tab, so logging each
			//  answer is a per-tab firehose that says the same thing forever — the same reason
			//   ping/pong/ack are in NOISY.  What is worth seeing is a CHANGE: a friend arriving or
			//    leaving, and the first answer after a (re)connect.  Steady state stays silent.
			const sig = online.join(',')
			if ((ws as any).whoSig !== sig) {
				const was = (ws as any).whoSig
				;(ws as any).whoSig = sig
				relayLog(`👥 who ${asked.length} asked → ${online.length} online${was === undefined ? '' : ' (changed)'} (verified binds only)`)
			}
			return
		}
		// ghost_compile_ack (editor → CLI): the verdict-reply for a ghost_compile.  Route it back to
		//  the socket that asked (by corr), since the CLI has no addr to deliverLocal to.  started
		//   narrates; done/error are terminal, so the corr mapping is spent and dropped.
		if (msg.control === 'ghost_compile_ack' && msg.corr) {
			const cli = ackBack.get(String(msg.corr))
			if (cli && cli.readyState === WebSocket.OPEN) { cli.send(JSON.stringify(msg)); relayLog(`→ cli ghost_compile_ack ${msg.phase ?? '?'} corr=${msg.corr}`) }
			else relayLog(`ghost_compile_ack ${msg.phase ?? '?'} corr=${msg.corr} — no asking socket (gone)`)
			if (msg.phase === 'done' || msg.phase === 'error') ackBack.delete(String(msg.corr))
			return
		}
		// runner_ack (runner → CLI): the single reply to a runner_ask, a raw control frame the runner
		//  sends down its own socket (mirrors ghost_compile_ack).  Route it back to the asking CLI by
		//   corr; one reply per ask, so the corr mapping is spent on receipt.
		if (msg.control === 'runner_ack' && msg.corr) {
			const cli = ackBack.get(String(msg.corr))
			if (cli && cli.readyState === WebSocket.OPEN) { cli.send(JSON.stringify(msg)); relayLog(`→ cli runner_ack ${msg.op ?? '?'} corr=${msg.corr}`) }
			else relayLog(`runner_ack ${msg.op ?? '?'} corr=${msg.corr} — no asking socket (gone)`)
			ackBack.delete(String(msg.corr))
			return
		}
	}

	// hello (peer → relay): AUTHENTICATED bind by Idento pub (Cluster_spec §3.2 — to:<pub> addressing).
	//  `?addr=` is an UNAUTHENTICATED claim: any socket can open ?addr=BOB and start receiving BOB's
	//   frames. A hello PROVES the sender holds the private key for `pub` by signing the hello header,
	//    so the relay binds prepubOf(pub) → this socket only for the real key-holder. to:<pub> then
	//     routes to a VERIFIED identity, not a self-asserted string. This is SELF-auth — the sign is
	//      checked against the CLAIMED pub (a single-key set), orthogonal to gen_write's "is this a
	//       TRUSTED flock signer". Add-only: ?addr= binding still works for the un-migrated path. ts
	//        freshness bounds replay of a captured hello; a relay-issued nonce challenge is the
	//         hardening follow-up (a captured hello can still re-bind within the 30s window).
	// ── hello-v2: the address ARBITER (Portability_todo §4 — the doubled-stream disease).  Two honest
	//  bodies of one soul used to land on the SAME address BY CONSTRUCTION: hello always bound
	//   prepubOf(pub), `bind` is additive, and deliverLocal fans out — so both bodies received
	//    everything, both answered, each stamping its own sequence counter from:<prepub>, and a friend
	//     got two interleaved streams no repli window can reconcile (repli_missed forever).  Bodies
	//      coexist by holding DISTINCT addresses: the bare <prepub> goes to whoever claimed it first,
	//       later bodies wear <prepub>_N.  So a v2 hello may carry `want:<addr>` — the address this
	//        body wishes to hold — and the relay arbitrates like `claim` does for @channels, EXCEPT
	//         that a bare refusal would strand a body with no address at all.  Err toward suffixing:
	//          a want held by another OPEN socket is answered with the next free <prepub>_N
	//           (hello_ok{addr:<suffix>, taken:[…]}) and the client ADOPTS the answered addr.  A want
	//            outside the body's own prepub family is refused (hello_error 'foreign want') —
	//             wanting someone ELSE's name is the shadow-subscribe attack wearing a valid
	//              signature, so family membership is checked against the prepub the sign just
	//               proved, never against the want's own claim.  "OPEN" is readyState OPEN; the 15s
	//                heartbeat terminates+unbinds the dead, so a crashed incumbent frees its seat
	//                 within ~30s and the next hello wanting that name simply gets it.  No `want` ⇒
	//                  exactly the v1 behaviour (bind prepubOf(pub) alone), so every existing client
	//                   keeps working unchanged.
	// An addr counts as HELD only by an OPEN socket, other than the asker, that was GRANTED it as its
	//  seat — not by every socket `locals` happens to route it to.  The distinction matters because a
	//   suffixed body ALSO carries the bare-prepub courtesy bind (the who-count bind below): counting
	//    raw `locals` membership would make the bare name read taken FOREVER while any sibling lives,
	//     so a crashed incumbent's seat would never actually free.  A socket's `seats` set is what
	//      hello granted it; an addr in its `locals` set but not in its `seats` is mere routing
	//       bookkeeping and does not block.  A socket with NO seats (an ?addr= squatter that never
	//        helloed) still blocks — err toward suffixing.  The asker's own binds never block itself
	//         (its ?addr= station bind, a re-hello down the same socket), so a re-hello is idempotent,
	//          answered with the seat it already has.
	function heldByAnother(addr: string, ws: WebSocket): boolean {
		const set = locals.get(addr)
		if (!set) return false
		for (const s of set) {
			if (s === ws || s.readyState !== WebSocket.OPEN) continue
			const seats = (s as any).seats as Set<string> | undefined
			if (seats && !seats.has(addr)) continue // only the courtesy bind — its granted seat is elsewhere
			return true
		}
		return false
	}
	// `<prepub>` or `<prepub>_N`, N ≥ 1 — the only addresses a body may want (its OWN family).
	function familyAddr(prepub: string, a: string): boolean {
		return a === prepub || (a.startsWith(prepub + '_') && /^[1-9]\d*$/.test(a.slice(prepub.length + 1)))
	}
	async function handleHello(ws: WebSocket, msg: any) {
		const pub = typeof msg.pub === 'string' ? msg.pub : ''
		const fresh = typeof msg.ts === 'number' && Math.abs(Date.now() - msg.ts) < 30_000
		const header = { control: 'hello', from: msg.from, pub, ts: msg.ts, sign: msg.sign }
		const signer = pub ? await verifyHeader(header, [pub]) : null
		if (signer === pub && pub && fresh) {
			const addr = prepubOf(pub)
			// The arbiter runs strictly INSIDE the verified branch: an unverified want is just an
			//  unverified hello, refused below with the v1 reasons.  A verified-but-foreign want
			//   refuses the whole hello — nothing binds, the body holds no seat here.
			const want = typeof msg.want === 'string' ? msg.want : ''
			if (want && !familyAddr(addr, want)) {
				try { ws.send(JSON.stringify({ control: 'hello_error', reason: 'foreign want' })) } catch {}
				relayLog(`✗ hello REJECTED (foreign want) — ${addr} wanted '${want.slice(0, 24)}', not of its own prepub family`)
				return
			}
			// AUTHENTICATION IS NOT DELIVERY (2026-08-13 — the owner's d101 Invite tab melting).
			//  A tab opens TWO sockets that both hello-bind the SAME identity: the station
			//   (?addr=<prepub>, Swarm_station_up) and the Lies channel (?addr=runner|editor,
			//    LiesLies.svelte).  `bind` is additive and `deliverLocal` fans to the whole Set, so
			//     every to:<prepub> frame — swarm frames, MUSIC CHUNKS, wormhole replies — was
			//      delivered TWICE, once to a socket with no business receiving it.  That phantom
			//       copy lands in w:Lies, where no repli handler is armed, so it is never finished:
			//        the inbox climbs to the 2000 cap and every per-frame query is O(depth), so the
			//         tab gets slower as it fills — a runaway that reads as "the app is broken".
			//          The tell is `inbox backstop: pier editor holds 2050 unemits … type=repli_page`
			//           beside a doubled `🛰 ws RECV` on every frame; there is no legitimate path for
			//            a music frame onto the Lies channel.
			//  So a role-channel socket AUTHENTICATES (it still proves the key, still counts as a
			//   verified bind for `who`, still gets hello_ok) but does NOT join the prepub's
			//    delivery fan-out.  The station socket — the one that opened ?addr=<prepub>, or any
			//     addr-less socket claiming only itself — is the single delivery door.
			//  …WHICH IS NOW DONE AT DELIVERY, NOT HERE (2026-08-13, same day, after the cut below cost
			//   the individuation contract and `who` presence — the full account is at `deliverLocal`).
			//    A hello ALWAYS binds: that is what makes the tab addressable and what `who` counts.  The
			//     de-duplication moved into deliverLocal, which prefers an address's OWN station socket
			//      when one is bound and otherwise delivers to every bound socket — so a tab with both
			//       sockets still gets each music frame exactly once, and a `?B=`/`?I=` runner with no
			//        station socket at all stays reachable through its role channel.
			const qaddr = String((ws as any).qaddr || '')
			// The prepub bind ALWAYS happens, want or no want — it is what `who` counts and what
			//  to:<prepub> routing rests on; the arbiter only decides which ADDITIONAL seat this
			//   body sits in.  (Two bodies both bound under the bare prepub is safe at delivery:
			//    the own-door rule prefers the station socket, and friends address the granted seat.)
			bind(addr, ws)
			const bound = ((ws as any).bound ??= new Set<string>())
			bound.add(addr)
			let grant = addr
			let taken: string[] | undefined
			if (want) {
				if (heldByAnother(want, ws)) {
					// The wanted seat is occupied by a live other body.  Do NOT contest it — the bare
					//  name goes to whoever claimed it first, and a deliberate take-back is
					//   Swarm_steal_back's job, not the relay's.  Answer with the next free suffix
					//    instead, plus the family's held seats so the client can SEE who it is
					//     coexisting with (the 👥 material).
					taken = [...locals.keys()].filter((a) => familyAddr(addr, a) && heldByAnother(a, ws))
					for (let n = 1; ; n++) {
						const s = addr + '_' + n
						if (!heldByAnother(s, ws)) { grant = s; break }
					}
				} else grant = want
				bind(grant, ws)
				bound.add(grant) // counted by `who`, released by drop() on close — same lifecycle as the prepub bind
			}
			// The seat is what the ARBITER granted (v1: the bare prepub; v2: want or its suffix) — the
			//  one addr this socket occupies against other bodies.  heldByAnother consults it so the
			//   courtesy prepub bind above never squats the bare name on a suffixed body's behalf.
			;((ws as any).seats ??= new Set<string>()).add(grant)
			try { ws.send(JSON.stringify(taken ? { control: 'hello_ok', addr: grant, taken } : { control: 'hello_ok', addr: grant })) } catch {}
			relayLog(`🪪 hello bound ${addr}${want ? ` want=${want} → seat ${grant}${taken ? ` (taken: ${taken.join(',')} — suffixed)` : ''}` : ''}${qaddr && qaddr !== addr ? ` (role channel ${qaddr} — delivery prefers the station socket)` : ''} (verified self-sig)`)
		} else {
			const reason = !pub ? 'no pub' : !fresh ? 'stale (ts skew)' : 'bad self-signature'
			try { ws.send(JSON.stringify({ control: 'hello_error', reason })) } catch {}
			relayLog(`✗ hello REJECTED (${reason})${pub ? ' for ' + prepubOf(pub) : ''}`)
		}
	}

	// Write a compiled .go to disk on the editor's behalf (see GEN_ROOT note above).  No ack
	//  frame: the editor settles optimistically (a localhost Node write is ~1ms and reliable);
	//   a rejection or fs error is surfaced via relayLog, which already echoes to the browser
	//    console.  Validates the browser-supplied path to gen/**.go under GEN_ROOT, no traversal.
	//  AUTHENTICATION (cluster trust, Cluster_spec.md §2): gen_write writes code Vite then
	//   runs, so it is the relay's one RCE surface.  When the cluster flock is configured
	//    (CLUSTER_TRUSTED_PUBS present) we ENFORCE: the frame must carry a `sign` over its header
	//     ({control,path,from,body_hash}) by a trusted key, and body_hash must be sha256(body) —
	//      so the signature commits to exactly these bytes (sha256, NOT the spine's collidable FNV).
	//       Unsigned/foreign/tampered ⇒ dropped.  When NOT configured we warn-and-allow, so the dev
	//        loop keeps working until the cluster env is deployed (then enforcement is automatic —
	//         migrate the editor's gen_write behind a node signer first; the browser can't sign).
	async function handleGenWrite(ws: WebSocket, msg: any) {
		const rel  = String(msg.path ?? '')
		const body = typeof msg.body === 'string' ? msg.body : ''
		// Every reject REPLIES to the sender (control:gen_write_error) as well as logging, so a
		//  rejected compile surfaces as a real error in the editor — not a silent drop the editor's
		//   optimistic settle never learns about (Cluster_spec §2: "I WANT ERRORS").
		const reject = (reason: string) => {
			relayLog(`✗ gen_write REJECTED ${rel || '(no path)'} — ${reason}`)
			try { ws.send(JSON.stringify({ control: 'gen_write_error', path: rel, reason })) } catch {}
		}
		if (!GEN_PATH_RE.test(rel) || rel.includes('..')) return reject(`bad path ${JSON.stringify(rel)}`)
		if (body.length > GEN_MAX_BYTES)                  return reject(`too large (${body.length}c > ${GEN_MAX_BYTES})`)
		const abs = resolve('src/lib', rel)
		if (abs !== GEN_ROOT && !abs.startsWith(GEN_ROOT + sep)) return reject('escapes gen root')
		const trusted = loadTrustedPubs()
		if (trusted.length) {
			// Distinguish UNSIGNED (no body_hash — the editor has no cluster key) from a TAMPERED/wrong
			//  digest, so the editor's error says which and how to fix it.
			if (msg.body_hash == null) return reject('unsigned — no body_hash (cluster trust enforced; the editor needs its cluster key)')
			const expect = createHash('sha256').update(body).digest('hex')
			if (msg.body_hash !== expect) return reject('body_hash ≠ sha256(body) (tampered or wrong digest)')
			const header = { control: 'gen_write', path: rel, from: msg.from, body_hash: msg.body_hash, sign: msg.sign }
			const signer = await verifyHeader(header, trusted)
			if (!signer) return reject('foreign or unsigned — not a trusted cluster key')
			relayLog(`🔑 gen_write authorised by ${prepubOf(signer)}`)
		} else {
			relayLog(`⚠ gen_write UNAUTHENTICATED ${rel} — cluster trust not configured (set CLUSTER_TRUSTED_PUBS / .env.cluster-identos to enforce)`)
		}
		const t0 = Date.now()
		try {
			await mkdir(dirname(abs), { recursive: true })
			await writeFile(abs, body)
			relayLog(`✍ gen_write ${rel} (${body.length}c, ${Date.now() - t0}ms)`)
		} catch (e) {
			return reject(`fs write failed: ${(e as Error).message}`)
		}
	}

	wss.on('connection', (ws: WebSocket, meta: Meta) => {
		// #1-real — transport keepalive (see the heartbeat below): every socket starts alive and is
		//  re-proven on each pong.  This is what unmasks a half-open socket that still reports OPEN.
		;(ws as any).isAlive = true
		ws.on('pong', () => { (ws as any).isAlive = true })
		if (meta.r2r) {
			// Inbound relay↔relay link: we are the editor end. Assert the editor role (set-once;
			//  throws → close, if a browser already locked us 'runner' — a real misconfig).
			try {
				setRole('editor')
			} catch (e) {
				ws.close(1011, String((e as Error).message))
				return
			}
			// ⚠ SAY IT WHEN A SECOND PEER TAKES THE BRIDGE (2026-09-10).  This end holds exactly ONE
			//  `peerLink`, and this line silently overwrites it — so when two relays dial the same
			//   passive end, the LAST one wins and the first one's traffic vanishes into a link that
			//    still reads OPEN at its own end.  Measured on a box running dev (:9091), staging
			//     (:9092) and prod (:19091): prod fell back to DEFAULT_EDITOR_RELAY, dialled staging,
			//      won the bridge, and every `become_book` the editor sent was forwarded to PROD —
			//       which has no runners — and dropped there.  The editor said "sent", the runner sat
			//        at "→EDITOR (dialing)", and nothing anywhere named the cause.  Hours.
			//  The real cure is prod not dialling at all (`EDITOR_RELAY=off`, now set in
			//   docker-compose.prod.yml).  This is the tell that would have found it in one minute,
			//    and it stays useful for every future box that grows a third relay.
			if (peerLink && peerLink !== ws && peerLink.readyState === WebSocket.OPEN) {
				relayLog(`⚠ peer relay REPLACED — a SECOND r2r peer dialled in and took the bridge. The previous peer's frames will now be forwarded to THIS one and dropped if it has no matching socket. Only one peer link is held; set EDITOR_RELAY=off on any relay that should not bridge.`)
				broadcastControl({ control: 'peer-relay', up: true, error: 'replaced', detail: 'a second r2r peer replaced the existing bridge' })
			}
			peerLink = ws
			relayLog(`✓ peer relay LINKED (inbound r2r) — editor end`)
			broadcastControl({ control: 'peer-relay', up: true })
			ws.on('message', (data: any, isBinary: boolean) => routeFromPeer(isBinary ? asBuffer(data) : asText(data)))
			ws.on('close', (code: number) => {
				if (peerLink === ws) peerLink = null
				relayLog(`✗ peer relay CLOSED code=${code} (inbound r2r)`)
				broadcastControl({ control: 'peer-relay', up: false, error: `close:${code}` })
			})
			ws.on('error', (err: any) => {
				if (peerLink === ws) peerLink = null
				relayLog(`✗ peer relay ERROR ${(err && (err.code || err.message)) || 'error'} (inbound r2r)`)
			})
			return
		}
		// Browser socket.
		// Remember the QUERY addr: handleHello needs it to tell an identity's own station socket
		//  (?addr=<prepub>) from a role-channel socket (?addr=runner|editor) that merely proves the
		//   same key.  See the AUTH-vs-DELIVERY note there.
		;(ws as any).qaddr = meta.addr || ''
		if (meta.addr) { bind(meta.addr, ws); relayLog(`browser bound addr=${meta.addr} (locals: ${[...locals.keys()].join(',')})`) }
		// Re-dial the bridge on (re)connect if we are the runner and the link is down. role is
		//  set-once and persists for the dev server's life, so dialEditor fires only on the FIRST
		//   become — a failed first dial (editor server not up yet) would otherwise stay dead until
		//    a SERVER restart, with every reload silently dropping frames. This recovers it on a
		//     browser reload: the v1 "dial once" becomes "dial whenever a browser arrives and we're
		//      unbridged" — still no background reconnect timer, but no longer a one-shot dead end.
		if (role === 'runner' && !(peerLink && peerLink.readyState === WebSocket.OPEN)) { relayLog(`browser (re)connected, bridge down — re-dialing`); dialEditor() }
		ws.on('message', (data: any, isBinary: boolean) => {
			// A binary message is a buffer-carrying frame ([header JSON]\n[buffer]) — route it
			//  whole by its header line; it is never a control frame.
			if (isBinary) { routeFromBrowser(asBuffer(data)); return }
			const text = asText(data)
			const msg = parse(text)
			if (msg && msg.control) {
				handleControl(ws, msg)
				return
			}
			// Remember the asking socket by corr so a browser's control-frame reply (a …_ack, handled
			//  below) can be routed back to this addr-less CLI.  ghost_compile (→ editor) and runner_ask
			//   (→ runner) are the two addr-less-CLI request frames; both reply by corr, not by addr.
			const askType = msg?.header?.type
			const askCorr = (askType === 'ghost_compile' || askType === 'runner_ask') && (msg.corr ?? msg.header?.corr)
			if (askCorr) ackBack.set(String(askCorr), ws)
			const outcome = routeFromBrowser(text)
			// #1 — undeliverable: a request that reached no browser (no local socket, no bridge) is
			//  dropped, and the asking CLI must HEAR that rather than wait its full timeout blind.
			//   Reply on its own socket (it's right here — no routing), with corr (+path for a compile)
			//    so it matches the ticket; the corr mapping is spent, so drop it.
			if (askCorr && outcome === 'dropped') {
				try { ws.send(JSON.stringify({ control: 'undeliverable', to: msg.header?.to ?? '?', path: msg.dock?.path, corr: String(askCorr) })) } catch {}
				ackBack.delete(String(askCorr))
			}
		})
		// Log the disconnect — it was silent before (only the bind logged), so a half-open drop +
		//  rebind read as two "browser bound" lines with no close between, hiding the reconnect.
		//   relayLog broadcasts as control:log, so this also lands in each browser console + the
		//    Relay Brink ring.  unbind first, then report the remaining locals.
		const drop = () => {
			if (meta.addr) unbind(meta.addr, ws)
			for (const [corr, s] of ackBack) if (s === ws) ackBack.delete(corr)   // asker hung up — forget its corr
			const subs = (ws as any).subs as Set<string> | undefined        // release every @channel this socket subscribed to
			if (subs) for (const ch of subs) unbind(ch, ws)
			const owns = (ws as any).owns as Set<string> | undefined         // and free any @name it claimed, so it can be re-claimed
			if (owns) for (const ch of owns) if (claims.get(ch) === ws) claims.delete(ch)
			const bound = (ws as any).bound as Set<string> | undefined       // release every pub-addr this socket bound via a signed hello
			if (bound) for (const a of bound) unbind(a, ws)
			const roleBound = (ws as any).roleBound as Set<string> | undefined  // release the role addr(s) bound via `become`
			if (roleBound) for (const a of roleBound) unbind(a, ws)
			watchDesk.drop(ws)                                                 // its file fixations; the dir watches linger for GC
		}
		ws.on('close', (code: number) => {
			drop()
			if (meta.addr) relayLog(`browser DISCONNECTED addr=${meta.addr} code=${code} (locals: ${[...locals.keys()].join(',') || 'none'})`)
		})
		ws.on('error', drop)
	})

	// #1-real — transport keepalive so `locals` can't lie.  deliverLocal trusts readyState===OPEN,
	//  but a TCP-half-open socket (a tab crash / NAT drop with no close frame) reports OPEN forever
	//   and the relay "delivers" into the void (bomb #1 — the runner-Lens flap, the silent ghost_compile
	//    drop).  A WS ping/pong round is the only thing that unmasks it: a socket that misses a pong is
	//     dead → terminate → its close handler unbinds it from `locals` → deliverLocal honestly fails →
	//      routeFromBrowser drops → the asking CLI hears `undeliverable` instead of waiting the timeout.
	// The tally dump: one line per (addr, type, lane) per window, busiest first so a heist reads at a
	//  glance.  Silent when nothing routed, so an idle relay stays quiet rather than printing zeroes.
	const tallyTimer = setInterval(() => {
		if (!tally.size) return
		const rows = [...tally.entries()].sort((a, b) => b[1].bytes - a[1].bytes || b[1].n - a[1].n)
		tally.clear()
		for (const [k, t] of rows) {
			const [to, type, lane] = k.split(TSEP)
			relayLog(`📊 ${to} ${type} ×${t.n} ${humanBytes(t.bytes)} (${lane}, ${TALLY_MS / 1000}s)`)
		}
	}, TALLY_MS)

	const HEARTBEAT_MS = 15000
	const heartbeat = setInterval(() => {
		for (const ws of wss.clients) {
			if ((ws as any).isAlive === false) { relayLog(`✂ half-open socket terminated (missed pong)`); ws.terminate(); continue }
			;(ws as any).isAlive = false
			try { ws.ping() } catch { /* terminating anyway next round */ }
		}
		// The OUTBOUND r2r bridge (dialEditor's `new WebSocket`) is NOT a wss client, so the loop
		//  above never pings it — a half-open outbound bridge reports OPEN forever and silently
		//   swallows every forwarded frame (routeFromBrowser's bridge.send into the void). Ping it on
		//    the same round; a missed pong terminates+nulls it, so the next browser (re)connect's
		//     re-dial guard dials a FRESH bridge instead of trusting the zombie (the relay.ts:335 case).
		const link = peerLink
		if (link && link.readyState === WebSocket.OPEN && !wss.clients.has(link as any)) {
			if ((link as any).isAlive === false) {
				relayLog(`✂ half-open r2r bridge terminated (missed pong) — will re-dial`)
				try { link.terminate() } catch {}
				if (peerLink === link) peerLink = null
				scheduleRedial('half-open bridge (missed pong)') // the zombie case: now actually re-dials
			} else {
				;(link as any).isAlive = false
				try { link.ping() } catch {}
			}
		}
	}, HEARTBEAT_MS)

	const onUpgrade = (req: any, socket: any, head: any) => {
		let u: URL
		try {
			u = new URL(req.url ?? '', 'http://localhost')
		} catch {
			return
		}
		if (u.pathname !== PATH) return // not ours (vite HMR etc.) — leave it for the next listener
		// Nagle off (TCP_NODELAY).  This is a latency-sensitive frame relay: Nagle pools a small WS
		//  frame (ws splits header/payload into separate writes) until a delayed-ACK returns — tens to
		//   a couple hundred ms per hop, and the r2r path stacks several hops.  setNoDelay so tiny
		//    frames shoot immediately instead of sitting in the pipe waiting for company.
		try { socket.setNoDelay(true) } catch {}
		selfHost = selfHost || req.headers?.host || '' // learn our own host:port for the self-dial guard
		const meta: Meta = { addr: u.searchParams.get('addr'), r2r: u.searchParams.get('r2r') === '1' }
		wss.handleUpgrade(req, socket, head, (ws) => wss.emit('connection', ws, meta))
	}
	httpServer.on('upgrade', onUpgrade)

	const handle: RelayHandle = {
		wss,
		get role() {
			return role
		},
		get localCount() {
			return locals.size
		},
		get peerReady() {
			return !!peerLink && peerLink.readyState === WebSocket.OPEN
		},
		broadcast(frame, addrs = ['editor', 'hacker', 'player']) {
			if (closed) return 0
			const text = JSON.stringify(frame)
			let n = 0
			for (const a of addrs) {
				for (const ws of locals.get(a) ?? []) {
					if (ws.readyState !== WebSocket.OPEN) continue
					try { ws.send(text); n++ } catch { /* a closing socket — the heartbeat reaps it */ }
				}
			}
			return n
		},
		close() {
			closed = true
			if (redialTimer) { clearTimeout(redialTimer); redialTimer = null }
			httpServer.off('upgrade', onUpgrade)
			clearInterval(heartbeat)
			clearInterval(tallyTimer)
			watchDesk.close()
			peerLink?.close()
			wss.close()
			delete (httpServer as any)[ATTACHED]
		},
	}
	;(httpServer as any)[ATTACHED] = handle
	return handle
}

function asText(data: any): string {
	return typeof data === 'string' ? data : data.toString()
}
function parse(text: string): any {
	try {
		return JSON.parse(text)
	} catch {
		return null
	}
}
function headerTo(text: string): string | undefined {
	const m = parse(text)
	return m && m.header && m.header.to
}
// A short label for a frame, for the routing logs: "<type> seq=<n>" or "(headerless)".
function frameKind(text: string): string {
	const m = parse(text)
	const h = m && m.header
	return h ? `${h.type}${h.seq != null ? ' seq=' + h.seq : ''}` : '(headerless)'
}
// Just the header type (for the NOISY heartbeat filter); '' if headerless.
function frameType(text: string): string {
	const m = parse(text)
	return (m && m.header && m.header.type) || ''
}

// ── binary frames ([header JSON]\n[raw buffer]) — encode/decode MUST match Tribunal.g Socket_real.
//  The header LINE is the bare header object (not the {header:…} wrapper a text frame is), so we
//   read `.to` directly. The buffer tail is never parsed — the relay only needs the routing header.
function asBuffer(data: any): Buffer {
	if (Buffer.isBuffer(data)) return data
	if (Array.isArray(data)) return Buffer.concat(data)
	return Buffer.from(data) // ArrayBuffer / TypedArray
}
function binHeader(buf: Buffer): any {
	const nl = buf.indexOf(10) // '\n'
	if (nl < 0) return null
	try { return JSON.parse(buf.subarray(0, nl).toString()) } catch { return null }
}
function headerToBin(buf: Buffer): string | undefined {
	const h = binHeader(buf)
	return h && h.to
}
// Just the header type of a binary frame (for the routing tally); '' if the header line is unreadable.
function frameTypeBin(buf: Buffer): string {
	const h = binHeader(buf)
	return (h && h.type) || ''
}
function frameKindBin(buf: Buffer): string {
	const h = binHeader(buf)
	if (!h) return '(binary, no header line)'
	const nl = buf.indexOf(10)
	return `${h.type}${h.seq != null ? ' seq=' + h.seq : ''} +buf=${buf.length - nl - 1}`
}
