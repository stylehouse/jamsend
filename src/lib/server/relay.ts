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

// The one hardcoded knob: where the runner-server dials the editor-server for the relay↔relay
//  bridge. Both servers run on localhost (editor :9091, runner/staging :9092), reachable over
//   plain ws without https. Override per-call (tests) or via the EDITOR_RELAY env var.
const DEFAULT_EDITOR_RELAY = 'ws://localhost:9091/relay?r2r=1'

const ATTACHED = Symbol.for('peeroleum.relay.attached')

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
	let role: Role | null = null
	let peerLink: WebSocket | null = null // the single relay↔relay socket (either end)

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
	function deliverLocal(to: string, text: string): boolean {
		const set = locals.get(to)
		if (!set || !set.size) return false
		let delivered = false
		for (const ws of set)
			if (ws.readyState === WebSocket.OPEN) {
				ws.send(text)
				delivered = true
			}
		return delivered
	}

	// Set-once role. A conflicting reassignment is an error (errorific), surfaced to the caller.
	function setRole(next: Role) {
		if (role && role !== next) throw new Error(`relay role already '${role}', refusing '${next}'`)
		if (role === next) return
		role = next
		if (role === 'runner') dialEditor()
	}

	// The runner-server reaches out to the editor ONCE.
	function dialEditor() {
		if (peerLink) return
		const link = new WebSocket(editorRelayUrl)
		peerLink = link
		link.on('message', (data) => routeFromPeer(asText(data)))
		link.on('close', () => {
			if (peerLink === link) peerLink = null
		})
		link.on('error', () => {
			if (peerLink === link) peerLink = null
		})
	}

	// A frame from a BROWSER socket: deliver local, else forward ONCE to the peer relay.
	function routeFromBrowser(text: string) {
		const to = headerTo(text)
		if (!to) return
		if (deliverLocal(to, text)) return
		if (peerLink && peerLink.readyState === WebSocket.OPEN) peerLink.send(text)
		// else: addressee absent — drop; the sender's no-ack ttlilt retries.
	}

	// A frame from the PEER relay: deliver local or drop. NEVER re-forwarded (the loop guard).
	function routeFromPeer(text: string) {
		const to = headerTo(text)
		if (to) deliverLocal(to, text)
	}

	function handleControl(ws: WebSocket, msg: any) {
		if (msg.control === 'become' && (msg.role === 'editor' || msg.role === 'runner')) {
			try {
				setRole(msg.role)
				ws.send(JSON.stringify({ control: 'role', role }))
			} catch (e) {
				ws.send(JSON.stringify({ control: 'error', error: String((e as Error).message) }))
			}
		}
	}

	wss.on('connection', (ws: WebSocket, meta: Meta) => {
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
			ws.on('message', (data) => routeFromPeer(asText(data)))
			ws.on('close', () => {
				if (peerLink === ws) peerLink = null
			})
			ws.on('error', () => {
				if (peerLink === ws) peerLink = null
			})
			return
		}
		// Browser socket.
		if (meta.addr) bind(meta.addr, ws)
		ws.on('message', (data) => {
			const text = asText(data)
			const msg = parse(text)
			if (msg && msg.control) {
				handleControl(ws, msg)
				return
			}
			routeFromBrowser(text)
		})
		const drop = () => {
			if (meta.addr) unbind(meta.addr, ws)
		}
		ws.on('close', drop)
		ws.on('error', drop)
	})

	const onUpgrade = (req: any, socket: any, head: any) => {
		let u: URL
		try {
			u = new URL(req.url ?? '', 'http://localhost')
		} catch {
			return
		}
		if (u.pathname !== PATH) return // not ours (vite HMR etc.) — leave it for the next listener
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
