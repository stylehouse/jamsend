// Node proof for the /relay websocket relay (src/lib/server/relay.ts), no browser.
//  Stands up an editor relay and a runner relay on two localhost ports, wires three
//   "browser" ws-clients, and asserts: same-origin delivery, cross-relay routing both
//    directions (editor↔runner over the server-to-server bridge), set-once role (errorific),
//     and that an unknown addressee is silently dropped (no crash).  Run:
//        npx vite-node scripts/relay-test.ts
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

// A browser ws-client that records every frame it receives. A binary message is a
//  buffer-carrying frame ([header JSON]\n[raw buffer]) — decoded to {header, buffer}; a text
//   message is the JSON frame (or a control frame). Mirrors Tribunal.g Socket_real / the relay.
function browser(port: number, addr: string) {
	const ws = new WebSocket(`ws://127.0.0.1:${port}/relay?addr=${addr}`)
	const got: any[] = []
	const ctrl: any[] = []
	ws.on('message', (d, isBinary) => {
		if (isBinary) {
			const buf = Buffer.isBuffer(d) ? d : Buffer.from(d as any)
			const nl = buf.indexOf(10)
			const header = JSON.parse(buf.subarray(0, nl).toString())
			got.push({ header, buffer: buf.subarray(nl + 1) })
			return
		}
		const m = JSON.parse(d.toString())
		;(m.control ? ctrl : got).push(m)
	})
	const open = new Promise<void>((r) => ws.on('open', () => r()))
	const send = (o: any) => ws.send(JSON.stringify(o))
	const frame = (to: string, type: string, seq = 1) => send({ header: { from: addr, to, type, seq } })
	// A buffer-carrying frame: bare header line + '\n' + raw buffer (the binary wire form).
	const binframe = (to: string, type: string, seq: number, buffer: Buffer) => {
		const hj = Buffer.from(JSON.stringify({ from: addr, to, type, seq, body_len: buffer.length }))
		ws.send(Buffer.concat([hj, Buffer.from([10]), buffer]))
	}
	return { ws, got, ctrl, open, send, frame, binframe }
}

async function main() {
	const editorSrv = createServer()
	const runnerSrv = createServer()
	const editorPort = await listen(editorSrv)
	const runnerPort = await listen(runnerSrv)

	const editor: RelayHandle = attachRelay(editorSrv)
	// The runner dials the editor's r2r endpoint (this is the one hardcoded knob, injected here).
	const runner: RelayHandle = attachRelay(runnerSrv, {
		editorRelayUrl: `ws://127.0.0.1:${editorPort}/relay?r2r=1`,
	})

	const alice = browser(editorPort, 'ALICE') // editor browser
	const alice2 = browser(editorPort, 'ALICE2') // a second editor browser (same-origin target)
	const bob = browser(runnerPort, 'BOB') // runner browser
	await Promise.all([alice.open, alice2.open, bob.open])

	// Lies%editor / Lies%runner command their own servers' roles (browser-initiated, set-once).
	alice.send({ control: 'become', role: 'editor' })
	bob.send({ control: 'become', role: 'runner' }) // → runner dials the editor once

	const bridged = await until(() => editor.peerReady && runner.peerReady && editor.role === 'editor' && runner.role === 'runner')
	check('relay↔relay bridge comes up (runner dialed editor)', bridged)
	check('editor role locked editor', editor.role === 'editor')
	check('runner role locked runner', runner.role === 'runner')

	// Same-origin delivery: ALICE → ALICE2, both on the editor relay (local, no bridge hop).
	alice.frame('ALICE2', 'dock_push', 1)
	const same = await until(() => alice2.got.some((m) => m.header?.to === 'ALICE2' && m.header?.from === 'ALICE'))
	check('same-origin deliver ALICE→ALICE2', same)

	// Cross-relay editor→runner: ALICE → BOB (editor relay forwards once over the bridge).
	alice.frame('BOB', 'dock_push', 2)
	const fwd = await until(() => bob.got.some((m) => m.header?.to === 'BOB' && m.header?.from === 'ALICE'))
	check('cross-relay deliver ALICE→BOB (editor→runner)', fwd)

	// Cross-relay runner→editor: BOB → ALICE (runner relay forwards once back).
	bob.frame('ALICE', 'run_result', 3)
	const back = await until(() => alice.got.some((m) => m.header?.to === 'ALICE' && m.header?.from === 'BOB'))
	check('cross-relay deliver BOB→ALICE (runner→editor)', back)

	// Binary frames ([header]\n[buffer]) route exactly like text, by header.to — buffer opaque.
	const payload = Buffer.from([1, 2, 3, 4, 250, 128, 0, 99, 17])
	alice.binframe('ALICE2', 'test_binary', 5, payload)
	const binSame = await until(() => alice2.got.some((m) => m.buffer && m.header?.from === 'ALICE' && m.header?.type === 'test_binary'))
	check('binary same-origin deliver ALICE→ALICE2', binSame)
	const binSameRow = alice2.got.find((m) => m.buffer && m.header?.type === 'test_binary')
	check('binary buffer intact (same-origin)', !!binSameRow && Buffer.compare(binSameRow.buffer, payload) === 0)

	alice.binframe('BOB', 'test_binary', 6, payload)
	const binFwd = await until(() => bob.got.some((m) => m.buffer && m.header?.from === 'ALICE' && m.header?.type === 'test_binary'))
	check('binary cross-relay deliver ALICE→BOB (over bridge)', binFwd)
	const binFwdRow = bob.got.find((m) => m.buffer && m.header?.type === 'test_binary')
	check('binary buffer intact (cross-relay)', !!binFwdRow && Buffer.compare(binFwdRow.buffer, payload) === 0)

	// Set-once errorific: BOB's server is already 'runner'; asking it to become 'editor' must error.
	const ctrlBefore = bob.ctrl.length
	bob.send({ control: 'become', role: 'editor' })
	const errored = await until(() => bob.ctrl.slice(ctrlBefore).some((m) => m.control === 'error'))
	check('set-once role conflict is errorific', errored)

	// Unknown addressee is dropped silently (no delivery, no crash).
	const bobBefore = bob.got.length
	alice.frame('NOBODY', 'dock_push', 4)
	await wait(150)
	check('unknown addressee dropped (no spurious delivery)', bob.got.length === bobBefore)

	// No frame should ever loop back to its own sender.
	check('no loopback to sender ALICE', !alice.got.some((m) => m.header?.from === 'ALICE'))
	check('no loopback to sender BOB', !bob.got.some((m) => m.header?.from === 'BOB'))

	editor.close()
	runner.close()
	await wait(50)
	editorSrv.close()
	runnerSrv.close()

	log(failures ? `\nFAIL — ${failures} check(s) failed` : '\nPASS — relay routes')
	process.exit(failures ? 1 : 0)
}

main().catch((e) => {
	console.error('relay-test threw:', e)
	process.exit(1)
})
