// Node proof for the ${prepub}_${rid} addressing model (the owner's design, 2026-09-02).
//  Stands up ONE relay in-process and drives the multi-body scenario the live device-link
//   keeps dying on, asserting three things:
//    (A) the CURRENT self-inflicted bug: a soul-key hello that `want`s a FOREIGN name
//        (its body-key-derived name, a different prepub family) is refused 'foreign want'.
//    (B) the CURRENT phantom-routing: when two bodies both seat the bare <prepub>, a directed
//        to:<prepub> reaches only the first-seated socket (the reload's ghost), never the live tab.
//    (C) THE TARGET CONTRACT (owner's model): each body opens ?addr=<prepub>_<rid> (unique per
//        page) and courtesy-binds <prepub> via the soul hello. Then to:<prepub>_<rid> reaches that
//        body ALONE (directed, never doubled) AND to:<prepub> FANS OUT to every body (the room).
//   If (C) passes on the UNMODIFIED relay, the entire fix is client-side.
//  Run:  esbuild-bundle into /app then node (vite-node can't write its config temp to the shared
//         root-owned node_modules):
//    /app/node_modules/.bin/esbuild scripts/ceremony-addr-test.ts --bundle --platform=node \
//       --format=esm --packages=external --outfile=/app/scratchpad/ceremony-addr-test.mjs \
//       && node /app/scratchpad/ceremony-addr-test.mjs
//  Exits 0 on PASS, 1 on FAIL.

import { createServer, type Server } from 'node:http'
import { WebSocket } from 'ws'
import * as ed from '@noble/ed25519'
import { attachRelay } from '../src/lib/server/relay'
import { signHeader, prepubOf } from '../src/lib/p2p/cluster_trust'

const enhex = ed.etc.bytesToHex
async function mint() {
	const priv = ed.utils.randomPrivateKey()
	const pub = await ed.getPublicKeyAsync(priv)
	return { privHex: enhex(priv), pubHex: enhex(pub) }
}
const log = (...a: any[]) => console.log(...a)
let failures = 0
function check(name: string, ok: boolean) {
	log(`${ok ? '  ✓' : '  ✗ FAIL'}  ${name}`)
	if (!ok) failures++
}
function listen(server: Server): Promise<number> {
	return new Promise((res) => server.listen(0, '127.0.0.1', () => res((server.address() as any).port)))
}
const wait = (ms: number) => new Promise((r) => setTimeout(r, ms))
async function until(pred: () => boolean, ms = 2000): Promise<boolean> {
	const t0 = Date.now()
	while (Date.now() - t0 < ms) { if (pred()) return true; await wait(20) }
	return pred()
}
// a "browser" ws-client that records the data frames + control frames it receives
function browser(port: number, addr: string) {
	const ws = new WebSocket(`ws://127.0.0.1:${port}/relay?addr=${addr}`)
	const got: any[] = []
	const ctrl: any[] = []
	ws.on('message', (d: any, isBinary: boolean) => {
		if (isBinary) return
		try { const m = JSON.parse(String(d)); (m.control ? ctrl : got).push(m) } catch {}
	})
	const send = (o: any) => ws.send(JSON.stringify(o))
	const open = new Promise<void>((res) => ws.on('open', () => res()))
	return { ws, got, ctrl, send, open, addr }
}
// a signed soul hello, optionally with a `want` (the seat this body asks for) — mirrors Swarm's
//  station hello (Swarm.g:1637). `from`/`want` vary; the SIGNATURE is always over the soul key.
async function hello(cli: any, soul: { pubHex: string; privHex: string }, from: string, want?: string) {
	const ts = Date.now()
	const header = { control: 'hello', from, pub: soul.pubHex, ts }
	const sign = await signHeader(header, soul.privHex)
	cli.send(want ? { ...header, sign, want } : { ...header, sign })
}

async function main() {
	const srv = createServer()
	const port = await listen(srv)
	attachRelay(srv)

	const soul = await mint()                 // ONE soul, many bodies
	const P = prepubOf(soul.pubHex)            // the soul prepub (eed831f1…)
	const bodyKey = await mint()               // a body-key-derived name (a DIFFERENT prepub family)
	const foreign = prepubOf(bodyKey.pubHex)

	// ── (A) the self-inflicted foreign-want — the spam in eed's boot log ─────────────────────────
	//  addr-less socket: it binds ONLY via the signed hello, so it never ?addr-squats the soul name.
	log('\n— (A) a soul-key hello that wants its BODY-KEY name is refused (the switcheroo eating itself) —')
	const bodyA = browser(port, ''); await bodyA.open
	await hello(bodyA, soul, P, foreign)       // sign as soul, but want a foreign-family name
	const gotForeign = await until(() => bodyA.ctrl.some((m) => m.control === 'hello_error' && m.reason === 'foreign want'))
	check('soul-key hello with want=<body-key name> → hello_error "foreign want"', gotForeign)
	bodyA.ws.close(); await wait(50)

	// ── (B) the phantom: the ghost SEATS the bare <prepub>; the live tab (rehomed to its own door,
	//  courtesy-binding the soul name) does NOT own the seat, so a directed to:<prepub> misses it.
	log('\n— (B) CURRENT model: the ghost owns the bare <prepub> seat; to:<prepub> reaches the ghost, not the live tab —')
	const ghost = browser(port, P); await ghost.open   // the reload's leftover socket owns ?addr=P
	await hello(ghost, soul, P, P)                       // seats the bare P first
	await until(() => ghost.ctrl.some((m) => m.control === 'hello_ok'))
	const live = browser(port, ''); await live.open     // the reloaded live tab — addr-less, NOT squatting P
	await hello(live, soul, P, P)                         // wants P too → offered a suffix; courtesy-binds P
	await until(() => live.ctrl.some((m) => m.control === 'hello_ok'))
	const liveSeat = live.ctrl.find((m) => m.control === 'hello_ok')?.addr
	check('the live tab is suffixed off the bare name (seat = ' + liveSeat + ')', liveSeat !== P && String(liveSeat || '').startsWith(P + '_'))
	// a directed frame to the soul name
	const gB = ghost.got.length, lB = live.got.length
	const sender = browser(port, 'somefriend'); await sender.open
	sender.send({ header: { from: 'somefriend', to: P, type: 'ferry', seq: 1 } })
	await wait(150)
	check('to:<prepub> reached the GHOST (owns the seat) — the disease', ghost.got.length > gB)
	check('to:<prepub> did NOT reach the live tab — why the soul never arrives', live.got.length === lB)
	ghost.ws.close(); live.ws.close(); await wait(50)

	// ── (C) THE TARGET: unique per-page door + soul-name-as-room, on the SAME relay ──────────────
	//  FRESH soul so no leftover ?addr=<prepub> squatter from (A)/(B) can flip the own-door rule.
	log('\n— (C) TARGET model: bodies open ?addr=<prepub>_<rid>, courtesy-bind <prepub>; directed=one, room=all —')
	const soul2 = await mint()
	const P2 = prepubOf(soul2.pubHex)
	const ridA = '7011', ridB = '7022'          // random per page (numeric rid = already family-valid)
	const bA = browser(port, P2 + '_' + ridA); await bA.open
	await hello(bA, soul2, P2 + '_' + ridA, P2 + '_' + ridA)  // seat my own unique door; from=my door
	const bB = browser(port, P2 + '_' + ridB); await bB.open
	await hello(bB, soul2, P2 + '_' + ridB, P2 + '_' + ridB)
	await until(() => bA.ctrl.some((m) => m.control === 'hello_ok') && bB.ctrl.some((m) => m.control === 'hello_ok'))
	const seatA = bA.ctrl.find((m) => m.control === 'hello_ok')?.addr
	const seatB = bB.ctrl.find((m) => m.control === 'hello_ok')?.addr
	check('each body seats its OWN unique door (A=' + seatA + ', B=' + seatB + ')', seatA === P2 + '_' + ridA && seatB === P2 + '_' + ridB)

	// directed to one body's door → that body ALONE
	const a1 = bA.got.length, b1 = bB.got.length
	sender.send({ header: { from: 'somefriend', to: P2 + '_' + ridB, type: 'ferry', seq: 2 } })
	await wait(150)
	check('to:<prepub>_<ridB> reached body B alone', bB.got.length > b1)
	check('to:<prepub>_<ridB> did NOT reach body A (never doubled)', bA.got.length === a1)

	// the room: to:<prepub> fans out to EVERY body (no socket owns ?addr=<prepub> now)
	const a2 = bA.got.length, b2 = bB.got.length
	sender.send({ header: { from: 'somefriend', to: P2, type: 'knock', seq: 3 } })
	await wait(150)
	check('to:<prepub> (the room) FANNED OUT to body A', bA.got.length > a2)
	check('to:<prepub> (the room) FANNED OUT to body B', bB.got.length > b2)

	log('')
	log(failures ? `FAIL — ${failures} check(s) failed` : 'PASS — the ${prepub}_${rid} model routes on the current relay')
	srv.close()
	setTimeout(() => process.exit(failures ? 1 : 0), 100)
}
main().catch((e) => { console.error(e); process.exit(1) })
