// scripts/runner_ask.mjs — "ask the LIVE browser runner to RUN a Story Book, or EXAMINE its state."
//
//  The real-time / real-audio twin of the headless CredRunner.  CredRunner boots the whole machine in
//   node (jsdom, no Web Audio, deterministic tick-snaps); THIS instead talks to a runner ALREADY running
//    in a real browser on :9091 (booted with ?B=<Book>), over the SAME /relay websocket the editor uses,
//     and the runner answers with live verdicts/snaps — real wall clock, real AudioContext, muted.
//  Addr-less request/reply correlated BY CORR, exactly like scripts/ghost_compile.ts (which targets the
//   editor); this one targets the runner.  The relay (src/lib/server/relay.ts) remembers this socket by
//    corr and routes the runner's {control:'runner_ack'} reply straight back here.  Handler is
//     Lies_runner_ask_recv (LiesFunk.svelte), registered on('runner_ask') in LiesLies.svelte.
//
//  Usage:
//    node scripts/runner_ask.mjs ping                    # liveness {role,channel,running}
//    node scripts/runner_ask.mjs run MusuLive            # kick a run (returns immediately)
//    node scripts/runner_ask.mjs run MusuLive --watch    # kick + poll state until done|failed
//    node scripts/runner_ask.mjs state [--watch]         # verdict + phase/n/total
//    node scripts/runner_ask.mjs steps                   # per-Step ok/caveat/dige
//    node scripts/runner_ask.mjs snap 3                  # one Step's got_snap (the live world serialisation)
//
//  RUNNER_URL overrides the relay origin (default http://172.17.0.1:9091 — the runner dev server as seen
//   from the claude container; use http://localhost:9091 if running on the host).  Exit 1 when a --watch
//    run finishes red (outcome not ok) or the request errors, else 0 — so it scripts.
import { WebSocket } from 'ws'

const OPS = ['ping', 'run', 'state', 'steps', 'snap']
const argv  = process.argv.slice(2)
const flags = new Set(argv.filter(a => a.startsWith('--')))
const pos   = argv.filter(a => !a.startsWith('-'))
const op    = pos[0]
const arg   = pos[1]
const watch = flags.has('--watch')
if (!op || !OPS.includes(op)) {
	console.error('usage: node scripts/runner_ask.mjs <ping|run <Book>|state|steps|snap <n>> [--watch]')
	process.exit(2)
}
if (op === 'run' && !arg)  { console.error('run needs a Book: node scripts/runner_ask.mjs run <Book>'); process.exit(2) }
if (op === 'snap' && !arg) { console.error('snap needs a step number: node scripts/runner_ask.mjs snap <n>'); process.exit(2) }

const ask = { op }
if (op === 'run')  ask.book = arg
if (op === 'snap') ask.n = Number(arg)

const HTTP       = process.env.RUNNER_URL || 'http://172.17.0.1:9091'
const WS_URL     = HTTP.replace(/^http/, 'ws').replace(/\/$/, '') + '/relay'
const TIMEOUT_MS = Number(process.env.RUNNER_ASK_TIMEOUT_MS || 8000)
const WATCH_MS   = Number(process.env.RUNNER_WATCH_MS || 120000)
const stamp      = Date.now()
const cliAddr    = `runcli-${stamp}`   // ephemeral addr — relay LOGS the connect/disconnect; reply is corr-routed

let corrSeq = 0
// sendAsk — one runner_ask, settled on the FIRST of: a corr-matched runner_ack, a relay `undeliverable`
//  (no runner on the relay), or a timeout (a half-open runner leaves the relay falsely "delivering" and
//   never acks — silence-past-N is the only thing that catches it).
function sendAsk(ws, theAsk) {
	const corr = `ra-${stamp}-${corrSeq++}`
	return new Promise((resolve) => {
		let done = false
		const settle = (v) => { if (!done) { done = true; ws.off('message', onMsg); clearTimeout(timer); resolve(v) } }
		const onMsg = (data) => {
			let m; try { m = JSON.parse(String(data)) } catch { return }
			if (m.corr !== corr) return                                  // relay control:log + other corrs — ignore
			if (m.control === 'undeliverable') settle({ ok: false, error: 'no runner connected to the relay (frame dropped)' })
			else if (m.control === 'runner_ack') settle(m)
		}
		const timer = setTimeout(() => settle({ ok: false, error: `no reply in ${Math.round(TIMEOUT_MS / 1000)}s (runner not connected or half-open?)` }), TIMEOUT_MS)
		ws.on('message', onMsg)
		ws.send(JSON.stringify({ header: { type: 'runner_ask', from: cliAddr, to: 'runner', seq: Date.now(), corr }, ask: theAsk, corr }))
	})
}

const ws = new WebSocket(`${WS_URL}?addr=${encodeURIComponent(cliAddr)}`)
ws.on('error', (e) => { console.error(`✗ relay ${WS_URL}: ${String(e?.code ?? e?.message ?? e)}`); process.exit(1) })
const opened = await new Promise((resolve) => { const wd = setTimeout(() => resolve(false), 5000); ws.on('open', () => { clearTimeout(wd); resolve(true) }) })
if (!opened) { console.error(`✗ relay ${WS_URL}: connect timeout (5s) — is the dev server up and ?B= a runner booted?`); process.exit(1) }

let exitCode = 0
const reply = await sendAsk(ws, ask)
if (reply.control !== 'runner_ack') { console.error(`✗ ${op}: ${reply.error ?? 'no reply'}`); exitCode = 1 }
else if (op === 'snap' && reply.result?.got_snap) {
	console.error(`snap: Step ${reply.result.n} ok=${reply.result.ok} dige=${reply.result.dige}`)
	process.stdout.write(reply.result.got_snap.endsWith('\n') ? reply.result.got_snap : reply.result.got_snap + '\n')
} else {
	console.log(`${op}: ${JSON.stringify({ ok: reply.ok, ...reply.result })}`)
	if (reply.ok === false) exitCode = 1
}

// --watch (run|state): poll state until the Storyrun phase settles done|failed, narrating each change.
if (watch && (op === 'run' || op === 'state') && reply.control === 'runner_ack') {
	const t0 = stamp
	let last = ''
	while (Date.now() - t0 < WATCH_MS) {
		await new Promise(r => setTimeout(r, 700))
		const s = await sendAsk(ws, { op: 'state' })
		if (s.control !== 'runner_ack') { console.error(`✗ state: ${s.error}`); exitCode = 1; break }
		const run = s.result?.run, out = s.result?.outcome
		const tag = run ? `${run.phase} ${run.n ?? '?'}/${run.total ?? '?'}` : 'no run'
		if (tag !== last) { console.log(`… ${JSON.stringify({ run, outcome: out })}`); last = tag }
		if (run && (run.phase === 'done' || run.phase === 'failed')) { exitCode = out && out.ok ? 0 : 1; break }
	}
}

try { ws.close() } catch {}
process.exit(exitCode)
