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
import { loadTrustedPubs, verifyHeader, prepubOf } from '../p2p/cluster_trust'

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

// Heartbeat + acknowledgement frames: high-volume, low-information once the channel is up, so
//  the routing logs skip them on the success path (drops are still logged — see routeFromBrowser).
const NOISY = new Set(['ping', 'pong', 'ack'])

export type Role = 'editor' | 'runner'
type Meta = { addr: string | null; r2r: boolean }

export interface RelayHandle {
	wss: WebSocketServer
	readonly role: Role | null
	readonly localCount: number
	readonly peerReady: boolean
	close(): void
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

	const wss = new WebSocketServer({ noServer: true })
	const locals = new Map<string, Set<WebSocket>>() // addr → live browser sockets
	// corr → the socket that sent a ghost_compile.  The CLI (ghost_compile.ts) is NOT a bound peer
	//  (no ?addr=), so the editor's ghost_compile_ack can't be routed by header.to — instead we
	//   remember which socket asked, keyed by the frame's corr, and route the ack back to it.
	//    Entries are short-lived (cleared on the terminal done/error ack, the sender's close, or
	//     just superseded), so the map stays tiny.
	const ackBack = new Map<string, WebSocket>()
	let role: Role | null = null
	let peerLink: WebSocket | null = null // the single relay↔relay socket (either end)
	let selfHost = '' // our own host:port, learned from the first upgrade's Host header

	// The relay runs in the node dev server: its console.log lands in the terminal, drowned
	//  among svelte-check warnings. relayLog ALSO pushes the line down every local browser
	//   socket as a {control:'log'} frame, so it surfaces in that origin's browser console
	//    (Socket_real.onmessage routes control frames aside). One-way, server→browser; a log
	//     frame carries no header, so it never re-enters the routing/handler path.
	function relayLog(line: string) {
		const tag = `🛰 relay${selfHost ? '[' + selfHost + ']' : ''}${role ? '/' + role : ''}`
		console.log(`${tag} ${line}`)
		broadcastControl({ control: 'log', line: `${tag} ${line}` })
	}
	// Send a control frame to every live local browser socket (NOT the r2r peer link).
	function broadcastControl(obj: any) {
		const text = JSON.stringify(obj)
		for (const set of locals.values())
			for (const ws of set) if (ws.readyState === WebSocket.OPEN) ws.send(text)
	}

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
	function deliverLocal(to: string, payload: string | Buffer): boolean {
		const set = locals.get(to)
		if (!set || !set.size) return false
		let delivered = false
		for (const ws of set)
			if (ws.readyState === WebSocket.OPEN) {
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
		// A still-OPEN bridge is fine. But a STALE half-open peerLink (a bridge drop with no close
		//  event) is non-null yet dead — and would block every re-dial forever (browser refresh
		//   included) until a server restart: the "state stuckness". Treat a non-OPEN link as down —
		//    close it and dial fresh.
		if (peerLink && peerLink.readyState === WebSocket.OPEN) return
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
		}, 5000)
		link.on('open', () => {
			clearTimeout(watchdog)
			try { (link as any)._socket?.setNoDelay(true) } catch {}   // Nagle off on the r2r bridge too
			relayLog(`✓ peer relay LINKED (outbound r2r) → ${editorRelayUrl}`)
			broadcastControl({ control: 'peer-relay', up: true, target: editorRelayUrl })
		})
		link.on('message', (data: any, isBinary: boolean) => routeFromPeer(isBinary ? asBuffer(data) : asText(data)))
		link.on('close', (code: number) => {
			clearTimeout(watchdog)
			if (peerLink === link) peerLink = null
			relayLog(`✗ peer relay CLOSED code=${code} → ${editorRelayUrl}`)
			broadcastControl({ control: 'peer-relay', up: false, error: `close:${code}`, target: editorRelayUrl })
		})
		link.on('error', (err: any) => {
			lastError = (err && (err.code || err.message)) || 'error'
			if (peerLink === link) peerLink = null
			relayLog(`✗ peer relay ERROR ${lastError} → ${editorRelayUrl}`)
			broadcastControl({ control: 'peer-relay', up: false, error: lastError, target: editorRelayUrl })
		})
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
		const loud = bin ? true : !NOISY.has(frameType(payload as string))
		const kind = bin ? frameKindBin(payload as Buffer) : frameKind(payload as string)
		if (deliverLocal(to, payload)) { if (loud) relayLog(`→ ${to} ${kind} (local)`); return 'local' }
		if (peerLink && peerLink.readyState === WebSocket.OPEN) { peerLink.send(payload); if (loud) relayLog(`→ ${to} ${kind} (forwarded over bridge)`); return 'bridge' }
		relayLog(`→ ${to} ${kind} DROPPED (no local socket, ${peerLink ? 'bridge not OPEN' : 'no bridge'})`)
		return 'dropped'
	}

	// A frame from the PEER relay: deliver local or drop. NEVER re-forwarded (the loop guard).
	function routeFromPeer(payload: string | Buffer) {
		const bin = typeof payload !== 'string'
		const to = bin ? headerToBin(payload as Buffer) : headerTo(payload as string)
		if (!to) return
		const loud = bin ? true : !NOISY.has(frameType(payload as string))
		const kind = bin ? frameKindBin(payload as Buffer) : frameKind(payload as string)
		if (deliverLocal(to, payload)) { if (loud) relayLog(`← bridge → ${to} ${kind} (local)`) }
		else relayLog(`← bridge → ${to} ${kind} DROPPED (no local socket for ${to})`)
	}

	function handleControl(ws: WebSocket, msg: any) {
		if (msg.control === 'become' && (msg.role === 'editor' || msg.role === 'runner')) {
			try {
				setRole(msg.role)
				ws.send(JSON.stringify({ control: 'role', role }))
			} catch (e) {
				ws.send(JSON.stringify({ control: 'error', error: String((e as Error).message) }))
			}
			return
		}
		if (msg.control === 'gen_write') { void handleGenWrite(ws, msg); return }
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
	}

	// Write a compiled .go to disk on the editor's behalf (see GEN_ROOT note above).  No ack
	//  frame: the editor settles optimistically (a localhost Node write is ~1ms and reliable);
	//   a rejection or fs error is surfaced via relayLog, which already echoes to the browser
	//    console.  Validates the browser-supplied path to gen/**.go under GEN_ROOT, no traversal.
	//  AUTHENTICATION (cluster trust, ClusterTrust_handover.md): gen_write writes code Vite then
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
		//   optimistic settle never learns about (ClusterTrust_handover: "I WANT ERRORS").
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
			// Remember the asking socket by corr so the editor's ghost_compile_ack (a control frame,
			//  handled below) can be routed back to this addr-less CLI.
			const gcCorr = msg?.header?.type === 'ghost_compile' && (msg.corr ?? msg.header?.corr)
			if (gcCorr) ackBack.set(String(gcCorr), ws)
			const outcome = routeFromBrowser(text)
			// #1 — undeliverable: a ghost_compile that reached no editor (no local socket, no bridge)
			//  is dropped, and the asking CLI must HEAR that rather than wait its full 12s timeout
			//   blind.  Reply on its own socket (it's right here — no routing), with corr+path so it
			//    matches the ticket; the corr mapping is spent, so drop it.
			if (gcCorr && outcome === 'dropped') {
				try { ws.send(JSON.stringify({ control: 'undeliverable', to: msg.header?.to ?? 'editor', path: msg.dock?.path, corr: String(gcCorr) })) } catch {}
				ackBack.delete(String(gcCorr))
			}
		})
		// Log the disconnect — it was silent before (only the bind logged), so a half-open drop +
		//  rebind read as two "browser bound" lines with no close between, hiding the reconnect.
		//   relayLog broadcasts as control:log, so this also lands in each browser console + the
		//    Relay Brink ring.  unbind first, then report the remaining locals.
		const drop = () => {
			if (meta.addr) unbind(meta.addr, ws)
			for (const [corr, s] of ackBack) if (s === ws) ackBack.delete(corr)   // asker hung up — forget its corr
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
	const HEARTBEAT_MS = 15000
	const heartbeat = setInterval(() => {
		for (const ws of wss.clients) {
			if ((ws as any).isAlive === false) { relayLog(`✂ half-open socket terminated (missed pong)`); ws.terminate(); continue }
			;(ws as any).isAlive = false
			try { ws.ping() } catch { /* terminating anyway next round */ }
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
		close() {
			httpServer.off('upgrade', onUpgrade)
			clearInterval(heartbeat)
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
function frameKindBin(buf: Buffer): string {
	const h = binHeader(buf)
	if (!h) return '(binary, no header line)'
	const nl = buf.indexOf(10)
	return `${h.type}${h.seq != null ? ' seq=' + h.seq : ''} +buf=${buf.length - nl - 1}`
}
