// Node proof for the /relay websocket relay (src/lib/server/relay.ts), no browser.
//  Stands up an editor relay and a runner relay on two localhost ports, wires three
//   "browser" ws-clients, and asserts: same-origin delivery, cross-relay routing both
//    directions (editor↔runner over the server-to-server bridge), set-once role (errorific),
//     to:<pub> individuation vs to:runner broadcast (the anti-double-run contract), and that an
//      unknown addressee is silently dropped (no crash).  Run:
//        npx vite-node scripts/relay-test.ts
//  Exits 0 on PASS, 1 on FAIL.
//
// ⓘ THE LOST IDENTITY BIND (2026-09-10) — the last block in this file.  A tab re-binds its ROLE
//  synchronously on every reconnect (`become`) but its IDENTITY only via the signed `hello`, which was
//   fire-and-forget.  Miss one and the tab talks OUT perfectly (`to:'editor'` is role-addressed) while
//    every `to:<its prepub>` frame dies at the relay for the life of that socket: out is a role, back
//     is an identity, so only the return leg can drop and nothing local notices.
//  FIXED CLIENT-SIDE (LiesLies.svelte): a latch cleared on open, stamped by `hello_ok`, and the hello
//   re-sent on the keepalive tick while it is unset.  The check here pins the RELAY CONTRACT that cure
//    depends on — a fresh hello on a NEW socket re-binds the identity.  It cannot test the app's own
//     code, because here the harness IS the client; see the note at the block itself.

import { createServer, type Server } from 'node:http'
import { WebSocket } from 'ws'
import * as ed from '@noble/ed25519'
import { attachRelay, type RelayHandle } from '../src/lib/server/relay'
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
// Re-listen on a SPECIFIC port — for the reconnect test, where the editor/staging relay restarts
//  on the same port the runner's hardcoded editorRelayUrl points at (SO_REUSEADDR is Node default).
function listenOn(server: Server, port: number): Promise<void> {
	return new Promise((res, rej) => {
		server.once('error', rej)
		server.listen(port, '127.0.0.1', () => res())
	})
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
// `addr` names this socket for the frames it SENDS (header.from) and, by default, for the `?addr=`
//  it dials with.  `{ addrless: true }` dials `/relay` with no query at all — the 2026-09-10 "a role
//   is not an address" model, where a role channel is bound by its `become` instead.  The name is
//    still used as `from`, so a caller reads the same either way.
function browser(port: number, addr: string, o: { addrless?: boolean } = {}) {
	const ws = new WebSocket(o.addrless ? `ws://127.0.0.1:${port}/relay` : `ws://127.0.0.1:${port}/relay?addr=${addr}`)
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

	// ── to:<pub> AUTHENTICATED binding (Cluster_spec §3.2).  A signed hello binds prepub(pub) → socket,
	//  PROVING key-ownership — where ?addr= is an unauthenticated claim by contrast.  A frame to: that
	//   prepub is then delivered to the verified holder; a hello with a bad self-sig binds NOTHING (so
	//    an impostor can't re-bind someone else's address and steal their frames).
	log('\n— to:<pub> signed-hello binding —')
	const carolKey = await mint()
	const carolAddr = prepubOf(carolKey.pubHex)
	const carol = browser(editorPort, '')          // addr-less socket — binds ONLY via a signed hello
	await carol.open
	const cts = Date.now()
	const csign = await signHeader({ control: 'hello', from: carolAddr, pub: carolKey.pubHex, ts: cts }, carolKey.privHex)
	carol.send({ control: 'hello', from: carolAddr, pub: carolKey.pubHex, ts: cts, sign: csign })
	const helloOk = await until(() => carol.ctrl.some((m) => m.control === 'hello_ok' && m.addr === carolAddr))
	check('signed hello accepted (hello_ok, bound by verified prepub)', helloOk)

	// ALICE addresses CAROL by her pub-derived addr → delivered to the verified holder.
	alice.frame(carolAddr, 'dock_push', 20)
	const toPub = await until(() => carol.got.some((m) => m.header?.to === carolAddr && m.header?.from === 'ALICE'))
	check('to:<pub> delivers to the hello-bound socket', toPub)

	// An impostor socket sends a hello for CAROL's pub but signs it with the WRONG key → rejected.
	const evil = browser(editorPort, '')
	await evil.open
	const evilKey = await mint()
	const ets = Date.now()
	const esign = await signHeader({ control: 'hello', from: carolAddr, pub: carolKey.pubHex, ts: ets }, evilKey.privHex)
	evil.send({ control: 'hello', from: carolAddr, pub: carolKey.pubHex, ts: ets, sign: esign })
	const helloErr = await until(() => evil.ctrl.some((m) => m.control === 'hello_error'))
	check('hello with a bad self-signature rejected (hello_error)', helloErr)

	// CAROL's addr stays bound to CAROL alone — a frame to it must NOT reach the impostor socket.
	const evilBefore = evil.got.length
	alice.frame(carolAddr, 'dock_push', 21)
	const carolGot21 = await until(() => carol.got.some((m) => m.header?.seq === 21 && m.header?.to === carolAddr))
	check('to:<pub> still reaches the real holder after a forged hello', carolGot21)
	check('impostor never bound — to:<pub> does not reach it', evil.got.length === evilBefore)

	// The OTHER door (ClusterAddressing_todo §6): `become <prepub>` would shadow-subscribe an
	//  unauthenticated socket onto a verified identity (bind is additive; deliverLocal fans out).
	//   Identity-shaped role names are refused outright — identities bind via signed hello alone.
	const becomeCtrlBefore = evil.ctrl.length
	evil.send({ control: 'become', role: carolAddr })
	const becomeRefused = await until(() => evil.ctrl.slice(becomeCtrlBefore).some((m) => m.control === 'error' && /identity-shaped/.test(String(m.error))))
	check('become <prepub> refused (identity-shaped role name)', becomeRefused)
	const evilBefore22 = evil.got.length
	alice.frame(carolAddr, 'dock_push', 22)
	const carolGot22 = await until(() => carol.got.some((m) => m.header?.seq === 22 && m.header?.to === carolAddr))
	check('to:<pub> still individuated after the refused become', carolGot22)
	check('shadow-subscriber got no copy', evil.got.length === evilBefore22)

	// ── individuation: to:<pub> is ONE runner, to:'runner' is ALL ─────────────────────────────────
	//  The contract the "runs going to both runners" fix rests on.  Two runner sockets share the addr
	//   'runner' (the broadcast bucket) AND each signed-hello-binds its OWN prepub (its individuated
	//    address).  A directed rungo to:<prepubA> must reach A ALONE; a fallback broadcast to:'runner'
	//     must reach BOTH.  If the relay ever collapses these two, silent double-runs return.
	log('\n— individuation: to:<pub> is one runner, to:runner is all —')
	const rk1 = await mint(), rk2 = await mint()
	const rp1 = prepubOf(rk1.pubHex), rp2 = prepubOf(rk2.pubHex)
	const run1 = browser(editorPort, 'runner') // both share the 'runner' broadcast bucket…
	const run2 = browser(editorPort, 'runner')
	await Promise.all([run1.open, run2.open])
	// …and each proves its OWN prepub with a signed hello (its individuated addr)
	const rt1 = Date.now()
	run1.send({ control: 'hello', from: rp1, pub: rk1.pubHex, ts: rt1, sign: await signHeader({ control: 'hello', from: rp1, pub: rk1.pubHex, ts: rt1 }, rk1.privHex) })
	const rt2 = Date.now()
	run2.send({ control: 'hello', from: rp2, pub: rk2.pubHex, ts: rt2, sign: await signHeader({ control: 'hello', from: rp2, pub: rk2.pubHex, ts: rt2 }, rk2.privHex) })
	await until(() => run1.ctrl.some((m) => m.control === 'hello_ok') && run2.ctrl.some((m) => m.control === 'hello_ok'))

	// directed to:<prepub1> → run1 ALONE (run2 must NOT see it — the individuation)
	const run2Before = run2.got.length
	alice.frame(rp1, 'rungo', 30)
	const indiv = await until(() => run1.got.some((m) => m.header?.seq === 30 && m.header?.to === rp1))
	check('to:<pubA> reaches runner A', indiv)
	await wait(120)
	check('to:<pubA> does NOT reach runner B (individuated — no double-run)', run2.got.length === run2Before)

	// broadcast to:'runner' → BOTH run1 and run2 (the deliberate fan-out)
	alice.frame('runner', 'become_book', 31)
	const bcastA = await until(() => run1.got.some((m) => m.header?.seq === 31 && m.header?.to === 'runner'))
	const bcastB = await until(() => run2.got.some((m) => m.header?.seq === 31 && m.header?.to === 'runner'))
	check('to:runner broadcasts to runner A', bcastA)
	check('to:runner broadcasts to runner B', bcastB)

	// ── A ROLE IS NOT AN ADDRESS: the same contracts, on an ADDR-LESS role channel ────────────────
	//  2026-09-10.  Clients stopped spelling a role as an address: `Socket_real`'s home() emits
	//   `?addr=` only for an identity-shaped name, so `runner|editor|player` channels dial `/relay`
	//    bare and are bound a message later by `become`.  Everything above still dials the old way
	//     (the relay still ACCEPTS it), so without these cases the new road has no test at all.
	//  THE ONE THAT ACTUALLY WORRIED ME IS THE RECONNECT.  The old dial re-bound the role in the URL
	//   on every reopen, for free, before a single message was exchanged.  The new road owes that
	//    entirely to `Socket_real` re-firing its open_hooks — and a role that silently fails to
	//     re-bind after a drop is invisible until someone asks "why is nothing dispatching?", which
	//      is the exact failure shape this whole thread has been paying for.
	log('\n— addr-less role channel: become binds it, and keeps binding it across a reconnect —')
	const alk = await mint(), alp = prepubOf(alk.pubHex)
	let bare = browser(editorPort, 'runner', { addrless: true })
	await bare.open
	bare.send({ control: 'become', role: 'runner' })
	await until(() => bare.ctrl.some((m) => m.control === 'become_ok' || m.control === 'role'), 1000)
	alice.frame('runner', 'become_book', 60)
	check('to:runner reaches an addr-less socket bound by `become`', await until(() => bare.got.some((m) => m.header?.seq === 60)))

	// …and it is still individuated: hello binds the prepub, and a `?B=`/`?I=` runner with NO station
	//  socket must stay directly addressable through this very channel (own-door: nobody claims the
	//   door, so the frame fans to every bound socket — here, just this one).
	const at = Date.now()
	bare.send({ control: 'hello', from: alp, pub: alk.pubHex, ts: at, sign: await signHeader({ control: 'hello', from: alp, pub: alk.pubHex, ts: at }, alk.privHex) })
	await until(() => bare.ctrl.some((m) => m.control === 'hello_ok'))
	alice.frame(alp, 'rungo', 61)
	check('to:<pub> reaches a station-less runner through its addr-less role channel', await until(() => bare.got.some((m) => m.header?.seq === 61)))

	// THE RECONNECT.  Drop it and stand a fresh addr-less socket up exactly as Socket_real's backoff
	//  does — new ws, then the open_hooks re-send `become`.  Nothing in the URL carries the role now.
	bare.ws.close()
	await until(() => !editor.localCount || true, 50); await wait(150)
	bare = browser(editorPort, 'runner', { addrless: true })
	await bare.open
	bare.send({ control: 'become', role: 'runner' })
	await wait(80)
	alice.frame('runner', 'become_book', 62)
	check('to:runner reaches it AGAIN after a reconnect (re-become re-binds)', await until(() => bare.got.some((m) => m.header?.seq === 62)))
	bare.ws.close(); await wait(80)

	// ── and the anti-doubling rule still holds when the role channel is addr-less ─────────────────
	//  The own-door rule reads `qaddr`, which is now EMPTY on a role channel.  A tab with a station
	//   (`?addr=<prepub>`) plus an addr-less role channel must still take each music frame exactly
	//    once, on the station — the doubling that filled the inbox to its 2000 cap.
	const ddk = await mint(), ddp = prepubOf(ddk.pubHex)
	const dstation = browser(editorPort, ddp)
	const dchannel = browser(editorPort, 'runner', { addrless: true })
	await Promise.all([dstation.open, dchannel.open])
	dchannel.send({ control: 'become', role: 'runner' })
	for (const s of [dstation, dchannel]) {
		const t = Date.now()
		s.send({ control: 'hello', from: ddp, pub: ddk.pubHex, ts: t, sign: await signHeader({ control: 'hello', from: ddp, pub: ddk.pubHex, ts: t }, ddk.privHex) })
	}
	await until(() => dstation.ctrl.some((m) => m.control === 'hello_ok') && dchannel.ctrl.some((m) => m.control === 'hello_ok'))
	const dchanBefore = dchannel.got.length
	alice.frame(ddp, 'repli_page', 63)
	check('music frame lands on the station even with an addr-less role channel', await until(() => dstation.got.some((m) => m.header?.seq === 63)))
	await wait(120)
	check('…and NOT on the addr-less role channel (no phantom copy)', dchannel.got.length === dchanBefore)
	check('…exactly once', dstation.got.filter((m) => m.header?.seq === 63).length === 1)
	dstation.ws.close(); dchannel.ws.close(); await wait(80)

	// ── ONE DELIVERY DOOR: a tab with TWO sockets gets each frame ONCE ───────────────────────────
	//  The other half of the individuation contract, and the one that had no test until it broke
	//   something (2026-08-13).  A live tab opens TWO sockets that both hello-bind the SAME identity:
	//    its station (`?addr=<prepub>`, Swarm_station_up) and its Lies channel (`?addr=runner`).  `bind`
	//     is additive, so `to:<prepub>` fanned to BOTH and every swarm frame and MUSIC CHUNK arrived
	//      twice — the phantom copy landing in w:Lies, where no repli handler is armed to finish it, so
	//       the inbox climbs to its 2000 cap and every per-frame query is O(depth).  The tab gets slower
	//        as it fills: a runaway that reads as "the app is broken".
	//  The first fix stopped the role socket binding at all, which silently cost the `to:<pubA>` case
	//   directly above (a `?B=`/`?I=` runner has NO station socket — the role channel is its only door)
	//    and `who` presence with it.  Both halves now hold at once because the de-duplication is at
	//     DELIVERY: prefer an address's own station socket when one is bound, else deliver to all.
	//  Assert BOTH directions here, forever: the frame lands exactly once, and it lands on the RIGHT one.
	log('\n— one delivery door: a two-socket tab receives each frame once —')
	const dk = await mint()
	const dp = prepubOf(dk.pubHex)
	const station = browser(editorPort, dp)          // the station socket: ?addr=<prepub>
	const channel = browser(editorPort, 'runner')    // the Lies channel: same identity, role addr
	await Promise.all([station.open, channel.open])
	for (const sock of [station, channel]) {
		const ts = Date.now()
		sock.send({ control: 'hello', from: dp, pub: dk.pubHex, ts, sign: await signHeader({ control: 'hello', from: dp, pub: dk.pubHex, ts }, dk.privHex) })
	}
	await until(() => station.ctrl.some((m) => m.control === 'hello_ok') && channel.ctrl.some((m) => m.control === 'hello_ok'))
	const chanBefore = channel.got.length
	alice.frame(dp, 'repli_page', 40)
	const onStation = await until(() => station.got.some((m) => m.header?.seq === 40))
	check('a music frame reaches the tab\'s STATION socket', onStation)
	await wait(120)
	check('…and NOT its role channel (no phantom copy into w:Lies)', channel.got.length === chanBefore)
	check('…exactly once on the station socket', station.got.filter((m) => m.header?.seq === 40).length === 1)
	station.ws.close(); channel.ws.close()

	// ── who: batch presence, verified-binds-only, leak-gated ─────────────────────────────────────
	//  One frame asks about N addrs; the answer counts only hello-VERIFIED binds (an ?addr= claim
	//   routes but must not read as presence), and is refused entirely to a non-hello-bound asker.
	log('\n— who: batch presence probe —')
	// ALICE is ?addr=-bound only (never sent a hello) → refused.
	alice.send({ control: 'who', addrs: [carolAddr], corr: 'w0' })
	const whoRefused = await until(() => alice.ctrl.some((m) => m.control === 'who_error' && m.corr === 'w0'))
	check('who refused to a non-hello-bound asker (who_error)', whoRefused)

	// CAROL (hello-bound) asks about: two live hello-bound runners, herself, a nobody, and ALICE
	//  (?addr=-bound only). Expect exactly the verified three; ALICE must NOT read as online.
	carol.send({ control: 'who', addrs: [rp1, rp2, carolAddr, 'deadbeefdeadbeef', 'ALICE'], corr: 'w1' })
	const who1 = await until(() => carol.ctrl.some((m) => m.control === 'who_ok' && m.corr === 'w1'))
	check('who answers a hello-bound asker (who_ok)', who1)
	const w1 = carol.ctrl.find((m) => m.control === 'who_ok' && m.corr === 'w1')
	check('who: hello-bound runners read online', !!w1 && w1.online.includes(rp1) && w1.online.includes(rp2))
	check('who: the asker reads online to itself', !!w1 && w1.online.includes(carolAddr))
	check('who: an unknown addr reads offline', !!w1 && !w1.online.includes('deadbeefdeadbeef'))
	check('who: an ?addr=-only claim does NOT read online (verified binds only)', !!w1 && !w1.online.includes('ALICE'))
	check('who: asked count echoes the list', !!w1 && w1.asked === 5)

	// Logging is transition-only (who rides every tab's ~10s pulse round), and the risk that creates
	//  is quieting the ANSWER along with the log.  Ask the same thing three times: every one must
	//   still reply, even though only the first prints.
	const beforeRepeat = carol.ctrl.filter((m) => m.control === 'who_ok').length
	carol.send({ control: 'who', addrs: [rp1], corr: 'r1' })
	carol.send({ control: 'who', addrs: [rp1], corr: 'r2' })
	carol.send({ control: 'who', addrs: [rp1], corr: 'r3' })
	const allThree = await until(() => carol.ctrl.filter((m) => m.control === 'who_ok').length >= beforeRepeat + 3)
	check('an unchanged who still ANSWERS every time (only the log is quiet)', allThree)
	check('and each reply carries its own corr', ['r1', 'r2', 'r3'].every((c) => carol.ctrl.some((m) => m.control === 'who_ok' && m.corr === c)))

	// A closed socket goes offline once the relay unbinds it (presence tracks live sockets).
	run2.ws.close()
	await wait(200)
	carol.send({ control: 'who', addrs: [rp1, rp2], corr: 'w2' })
	const who2 = await until(() => carol.ctrl.some((m) => m.control === 'who_ok' && m.corr === 'w2'))
	const w2 = carol.ctrl.find((m) => m.control === 'who_ok' && m.corr === 'w2')
	check('who: a closed socket reads offline', who2 && !!w2 && !w2.online.includes(rp2))
	check('who: the still-open runner stays online', !!w2 && w2.online.includes(rp1))

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

	// ── the routing TALLY: rate in the log, not one line per frame ───────────────────────────────
	//  A successful route no longer prints; it is counted, and a 10s timer dumps one line per
	//   (addr, type, lane).  The risk this creates is the same one the who-log quieting creates —
	//    silencing the LOG must never silence the DELIVERY — so assert both halves: every frame
	//     arrives, no per-frame line was printed, and the dump reports the true count.
	log('\n— routing tally (one line per addr+type per 10s) —')
	const printed: string[] = []
	const realLog = console.log
	console.log = (...a: any[]) => { printed.push(a.join(' ')); realLog(...a) }
	const tallyBefore = alice2.got.length
	for (let i = 0; i < 12; i++) alice.frame('ALICE2', 'repli_page', 900 + i)
	const allArrived = await until(() => alice2.got.length >= tallyBefore + 12)
	check('every tallied frame still DELIVERS (12/12)', allArrived)
	check('and none of them printed a per-frame routing line', !printed.some((l) => /→ ALICE2 repli_page/.test(l)))
	// the dump lands on the 10s boundary; wait one window plus slack
	const dumped = await until(() => printed.some((l) => /📊 ALICE2 repli_page/.test(l)), 13000)
	check('the 10s tally dump prints one line for ALICE2/repli_page', dumped)
	const row = printed.find((l) => /📊 ALICE2 repli_page/.test(l)) ?? ''
	check(`the tally counts all 12 (got: ${row.trim().slice(0, 80)})`, /×12\b/.test(row))
	check('and reports a byte total + lane', /local/.test(row) && /\d+(\.\d+)?(B|KB|MB)/.test(row))
	console.log = realLog

	// ── r2r AUTO-RECONNECT — the editor/staging end restarts while the runner's browser (BOB) stays
	//  connected.  The runner must re-dial the bridge ON ITS OWN (no browser reload, no manual restart)
	//   and cross-routing must resume.  This is the staging-restart bug: before the auto-redial loop,
	//    the dropped bridge stayed down until something re-triggered dialEditor.
	// ── a broadcast control frame reaches each SOCKET once, not each BINDING once ─────────────────
	//  2026-09-10.  `locals` is addr → Set<socket> and one socket is deliberately bound under several
	//   addrs (role, prepub, granted seat).  `broadcastControl` walked `locals.values()`, so a
	//    multiply-bound socket got one copy PER BINDING — the owner's console showed `🌉 relay bridge
	//     DOWN` three times for one drop.  It also made the log lie about how many events occurred,
	//      which is how it hid for so long.  MULTI below is bound three ways; BOB is bound once; the
	//       bridge drop just below broadcasts `peer-relay`, and both must count it exactly the same.
	log('\n— broadcastControl: once per socket, not once per binding —')
	const mk = await mint(), mp = prepubOf(mk.pubHex)
	const multi = browser(runnerPort, 'MULTI')          // bind 1: ?addr=MULTI
	await multi.open
	multi.send({ control: 'become', role: 'runner' })    // bind 2: the role (same role = safe no-op)
	const mt = Date.now()
	multi.send({ control: 'hello', from: mp, pub: mk.pubHex, ts: mt, sign: await signHeader({ control: 'hello', from: mp, pub: mk.pubHex, ts: mt }, mk.privHex) })
	await until(() => multi.ctrl.some((m) => m.control === 'hello_ok'))   // bind 3: the prepub
	const peerRelayCount = (b: { ctrl: any[] }) => b.ctrl.filter((m) => m.control === 'peer-relay').length
	const multiPrBefore = peerRelayCount(multi), bobPrBefore = peerRelayCount(bob)

	log('\n— r2r reconnect: simulating editor/staging restart (BOB stays put) —')
	editor.close()
	editorSrv.close()
	const wentDown = await until(() => !runner.peerReady, 3000)
	check('bridge drops when editor/staging restarts', wentDown)
	await wait(150)
	const multiGot = peerRelayCount(multi) - multiPrBefore
	const bobGot = peerRelayCount(bob) - bobPrBefore
	// ⚠ ABSOLUTE, NOT COMPARATIVE.  The first cut of this asserted `multiGot === bobGot` and PASSED with
	//  the bug in place (both read 3) — because BOB is multiply bound as well (`?addr=BOB` plus its
	//   `become runner`), so per-binding fan-out inflates BOTH sides equally. A comparison between two
	//    affected things measures nothing. One drop is ONE event: the count must be exactly 1.
	check(`a multiply-bound socket gets exactly ONE copy of a broadcast control frame (multi=${multiGot} bob=${bobGot})`, multiGot === 1)
	check('…and one really did arrive, so the check is not vacuous', multiGot > 0)

	// Bring the editor relay back up on the SAME port (staging is back); its hardcoded url is unchanged.
	const editorSrv2 = createServer()
	await listenOn(editorSrv2, editorPort)
	const editor2: RelayHandle = attachRelay(editorSrv2)
	// A reloaded editor tab re-binds ALICE on the fresh server (the old alice socket died with editorSrv).
	const alice3 = browser(editorPort, 'ALICE')
	await alice3.open
	alice3.send({ control: 'become', role: 'editor' })

	// The RUNNER must re-dial the bridge autonomously — BOB never reloaded, no new runner `become`.
	const reBridged = await until(() => runner.peerReady && editor2.peerReady, 20000)
	check('runner auto-re-dials the r2r bridge (no browser reload, no manual restart)', reBridged)

	// And cross-relay routing resumes both directions after the heal.
	bob.frame('ALICE', 'run_result', 7)
	const backAgain = await until(() => alice3.got.some((m) => m.header?.to === 'ALICE' && m.header?.from === 'BOB'), 3000)
	check('cross-relay deliver resumes after reconnect (BOB→ALICE)', backAgain)
	alice3.frame('BOB', 'dock_push', 8)
	const fwdAgain = await until(() => bob.got.some((m) => m.header?.to === 'BOB' && m.header?.from === 'ALICE' && m.header?.seq === 8), 3000)
	check('cross-relay deliver resumes after reconnect (ALICE→BOB)', fwdAgain)

	// ── THE LOST IDENTITY BIND: a reconnect that re-`become`s but never re-`hello`s ───────────────
	//  2026-09-10, from the owner's live log: `⚠ DROPPED bridge→ pong seq=50 → 'da060c944e310adb' ×60`
	//   beside a runner tab whose Brink badge read `→EDITOR (silent 94s)` — while that runner was
	//    demonstrably ALIVE, because the pongs being dropped were answers to pings it had just sent.
	//  THE ASYMMETRY THAT CAUSES IT.  A tab re-binds its ROLE synchronously on every (re)open
	//   (`become`, LiesLies.svelte on_open — it cannot fail) and its IDENTITY only through the signed
	//    `hello`, which is fire-and-forget: `if (!idento?.pub || !idento?.key) return` plus a bare
	//     `catch {}` (LiesLies.svelte:419-460), with nothing checking that `hello_ok` ever came back.
	//      Miss one and the socket is bound at `runner` but at NO prepub: outbound is perfect
	//       (to:'editor' is role-addressed) and every to:<its prepub> frame dies at deliverLocal for
	//        the life of the tab.  Half a channel, with no client-visible symptom but a stale badge.
	//  THE ASSERTION IS ABSOLUTE, and it is about DELIVERY, not about logs: after the lost-bind
	//   reconnect, a frame addressed to the tab's prepub must reach that tab.  Not "fewer drops than
	//    before", not "the same as the role path" — a comparison between two affected things measures
	//     nothing (the lesson the broadcastControl check above is written in).
	//  ⓘ This block was RED when first written — it reproduced the live fault exactly, and that red is
	//   what proved the diagnosis.  It is green now because the CLIENT-side cure shipped (the retried
	//    hello, modelled below).  A relay-side `rehello` nudge — warnDrop asking the local flock to
	//     re-assert identity instead of only complaining to the terminal — remains an unbuilt
	//      belt-and-braces option; it is written up in `spec/Social_demarcation_todo.md §0` and is NOT
	//       needed for this check to pass.
	log('\n— the lost identity bind: role re-binds on reconnect, identity does not —')
	{
		const { attachRelay: attach2 } = await import(process.env.RELAY_MOD ?? '../src/lib/server/relay')
		const eSrv = createServer(), rSrv = createServer()
		const ePort = await listen(eSrv), rPort = await listen(rSrv)
		const eRelay = attach2(eSrv)
		const rRelay = attach2(rSrv, { editorRelayUrl: `ws://127.0.0.1:${ePort}/relay?r2r=1` })
		const ek = await mint(), rkey = await mint()
		const PR = prepubOf(rkey.pubHex)
		// the seat-dodge hello the Lies channel really sends (LiesLies.svelte:455) — want=<prepub>_9NNN
		const helloOn = async (b: any, k: any, rid: string) => {
			const from = prepubOf(k.pubHex)
			const h = { control: 'hello', from, pub: k.pubHex, ts: Date.now() }
			b.send({ ...h, sign: await signHeader(h, k.privHex), want: `${from}_${rid}` })
		}
		// The CLIENT-SIDE CURE, which is the one that shipped (LiesLies.svelte, 2026-09-10): a latch
		//  cleared on open, stamped by `hello_ok`, and a hello re-sent on the keepalive tick while it is
		//   unset — with a FRESH seat dodge each attempt, so a retry cannot collide with a seat an
		//    earlier attempt already won.  Modelled here on a fast tick because the harness has no 6s
		//     keepalive.
		//  ⚠ WHAT THIS CHECK IS AND IS NOT.  It cannot test the app's code — the harness IS the client.
		//   What it pins is the RELAY CONTRACT the cure depends on: **a fresh signed hello on a NEW
		//    socket re-binds the identity**, so a tab that lost its bind can recover it unaided. If the
		//     relay ever stopped honouring a re-hello, the shipped fix would silently stop working and
		//      this is what would catch it.
		const armHelloRetry = (b: any, k: any) => {
			let acked = false
			b.ws.on('message', (d: any, isBin: boolean) => {
				if (isBin) return
				try { if (JSON.parse(String(d))?.control === 'hello_ok') acked = true } catch {}
			})
			const t = setInterval(() => {
				if (acked || b.ws.readyState !== 1) return          // 1 = OPEN, the readyState gate the fix needs
				void helloOn(b, k, String(9000 + Math.floor(Math.random() * 900)))
			}, 150)
			return () => clearInterval(t)
		}
		const eTab = browser(ePort, 'editor'); await eTab.open
		eTab.send({ control: 'become', role: 'editor' })
		await helloOn(eTab, ek, '9523')
		let rTab = browser(rPort, 'runner'); await rTab.open
		rTab.send({ control: 'become', role: 'runner' })
		await helloOn(rTab, rkey, '9514')
		await until(() => eRelay.peerReady && rRelay.peerReady, 8000)
		await until(() => rTab.ctrl.some((m: any) => m.control === 'hello_ok'), 2000)
		eTab.frame(PR, 'pong', 50)
		check("baseline: a bridged pong to the runner's prepub lands while it is hello-bound",
			await until(() => rTab.got.some((m: any) => m.header?.seq === 50), 2000))

		// the reconnect that loses the identity bind: `become` re-fires, `hello` does not
		rTab.ws.close(); await wait(200)
		rTab = browser(rPort, 'runner'); await rTab.open
		const stopRetry = armHelloRetry(rTab, rkey)
		rTab.send({ control: 'become', role: 'runner' })
		await wait(150)
		// the tab is manifestly alive: its role-addressed ping still crosses the bridge
		rTab.frame('editor', 'ping', 51)
		check('the reconnected tab is ALIVE — its role-addressed ping still reaches the editor',
			await until(() => eTab.got.some((m: any) => m.header?.seq === 51), 2000))
		// …and now the answer, addressed to its prepub, exactly as Lies_pong addresses it
		eTab.frame(PR, 'pong', 52)
		await wait(600)
		eTab.frame(PR, 'pong', 53)   // the transport re-asks; the SECOND round must land
		check("the retried hello re-binds the identity — a pong to the tab's prepub lands again",
			await until(() => rTab.got.some((m: any) => m.header?.seq === 53), 3000))
		stopRetry()
		eRelay.close(); rRelay.close(); await wait(50)
		eSrv.close(); rSrv.close()
	}

	editor2.close()
	runner.close()
	await wait(50)
	editorSrv2.close()
	runnerSrv.close()

	log(failures ? `\nFAIL — ${failures} check(s) failed` : '\nPASS — relay routes')
	process.exit(failures ? 1 : 0)
}

main().catch((e) => {
	console.error('relay-test threw:', e)
	process.exit(1)
})
