// Node proof for the runner_ask / runner_ack corr-routing added to src/lib/server/relay.ts — no
//  browser.  Stands up ONE relay, binds a fake "runner" browser (addr=runner) that answers a routed
//   runner_ask with a {control:'runner_ack',corr} reply, and an ADDR-LESS "cli" (like ghost_compile.ts
//    / scripts/runner_ask.mjs) that sends a runner_ask and must get the ack routed back BY CORR — it has
//     no addr to deliverLocal to.  Also: a runner_ask with no runner bound must come back `undeliverable`.
//  This is the relay half of the Story-runner interface (the load-bearing, browserless-verifiable bit);
//   the live Lies_runner_ask_recv handler is proven on :9091.  Mirrors scripts/relay-test.ts.  Run:
//      npx vite-node scripts/runner-ask-test.ts
//  Exits 0 on PASS, 1 on FAIL.

import { createServer, type Server } from 'node:http'
import { WebSocket } from 'ws'
import { attachRelay, type RelayHandle } from '../src/lib/server/relay'

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
	while (Date.now() - t0 < ms) {
		if (pred()) return true
		await wait(20)
	}
	return pred()
}

// A bound "browser" ws-client (the runner end) — records routed frames and control frames apart.
function browser(port: number, addr: string) {
	const ws = new WebSocket(`ws://127.0.0.1:${port}/relay?addr=${addr}`)
	const got: any[] = []
	const ctrl: any[] = []
	ws.on('message', (d: any) => {
		const m = JSON.parse(d.toString())
		;(m.control ? ctrl : got).push(m)
	})
	const open = new Promise<void>((r) => ws.on('open', () => r()))
	const send = (o: any) => ws.send(JSON.stringify(o))
	return { ws, got, ctrl, open, send }
}

// An ADDR-LESS "cli" ws-client — no ?addr=, so the relay can route a reply to it ONLY by corr (the
//  ackBack map), exactly as ghost_compile.ts / runner_ask.mjs rely on.
function cli(port: number) {
	const ws = new WebSocket(`ws://127.0.0.1:${port}/relay`)
	const replies: any[] = []
	ws.on('message', (d: any) => { try { replies.push(JSON.parse(d.toString())) } catch {} })
	const open = new Promise<void>((r) => ws.on('open', () => r()))
	const ask = (corr: string, op: string, extra: any = {}) =>
		ws.send(JSON.stringify({ header: { type: 'runner_ask', from: 'cli', to: 'runner', seq: Date.now(), corr }, ask: { op, ...extra }, corr }))
	return { ws, replies, open, ask }
}

async function main() {
	const srv = createServer()
	const port = await listen(srv)
	const relay: RelayHandle = attachRelay(srv)

	// (a) runner_ask with NO runner bound → the CLI must hear `undeliverable` (no blind wait).
	const lonely = cli(port)
	await lonely.open
	lonely.ask('corr-none', 'ping')
	const undeliv = await until(() => lonely.replies.some((m) => m.control === 'undeliverable' && m.corr === 'corr-none'))
	check('runner_ask with no runner → undeliverable (by corr)', undeliv)
	lonely.ws.close()

	// Bind the fake runner. It answers a routed runner_ask with a {control:'runner_ack',corr} reply,
	//  echoing the op + a canned result — the shape Lies_runner_ask_recv produces in the browser.
	const runner = browser(port, 'runner')
	await runner.open
	runner.send({ control: 'become', role: 'runner' })
	runner.ws.on('message', (d: any) => {
		let m: any; try { m = JSON.parse(d.toString()) } catch { return }
		if (m.control || m.header?.type !== 'runner_ask') return
		const corr = m.corr ?? m.header?.corr
		const op = m.ask?.op
		const result = op === 'ping'  ? { role: 'runner', channel: 'up', book: m.ask?.book ?? null }
		             : op === 'run'   ? { accepted: true, book: m.ask?.book }
		             : op === 'state' ? { outcome: { ok: true, ok_pct: 1, done: 5, caveat: 0 }, run: { phase: 'done', n: 5, total: 5 } }
		             :                  { echo: m.ask }
		runner.send({ control: 'runner_ack', corr, ok: true, op, result })
	})

	// (b) ping round-trip — CLI sends, fake runner answers, relay routes the ack back by corr.
	const c = cli(port)
	await c.open
	c.ask('corr-ping', 'ping')
	const pinged = await until(() => c.replies.some((m) => m.control === 'runner_ack' && m.corr === 'corr-ping' && m.op === 'ping'))
	check('runner_ask ping → runner_ack routed back by corr', pinged)

	// (c) the routed frame actually reached the runner (its op-dispatch saw it).
	check('runner received the routed runner_ask frame', runner.got.some((m) => m.header?.type === 'runner_ask' && m.corr === 'corr-ping'))

	// (d) run op carries the Book through and comes back accepted.
	c.ask('corr-run', 'run', { book: 'MusuLive' })
	const ran = await until(() => c.replies.some((m) => m.control === 'runner_ack' && m.corr === 'corr-run' && m.result?.book === 'MusuLive' && m.result?.accepted))
	check('runner_ask run <Book> → ack {accepted, book}', ran)

	// (e) state op returns the verdict/phase shape the CLI prints back.
	c.ask('corr-state', 'state')
	const stated = await until(() => c.replies.some((m) => m.control === 'runner_ack' && m.corr === 'corr-state' && m.result?.outcome?.done === 5 && m.result?.run?.phase === 'done'))
	check('runner_ask state → ack {outcome, run}', stated)

	// (f) distinct corrs don't cross — the run ack never arrived under the ping corr.
	check('no corr crosstalk (run ack not delivered as ping)', !c.replies.some((m) => m.corr === 'corr-ping' && m.op === 'run'))

	c.ws.close()
	runner.ws.close()
	relay.close()
	await wait(50)
	srv.close()

	log(failures ? `\nFAIL — ${failures} check(s) failed` : '\nPASS — relay corr-routes runner_ask/runner_ack')
	process.exit(failures ? 1 : 0)
}

main().catch((e) => {
	console.error('runner-ask-test threw:', e)
	process.exit(1)
})
