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
//    node scripts/runner_ask.mjs runners                 # list the Waft:Cluster registry (prepub  friendly  ★fav)
//    node scripts/runner_ask.mjs run MusuLive --runner=49dee9   # court ONE runner by prepub|prefix|friendly and
//                                                          #  INSIST: retry IT on busy/silence (never failover);
//                                                           #   no --runner ⇒ legacy role broadcast (first to ack)
//    node scripts/runner_ask.mjs state [--watch]         # verdict + phase/n/total
//    node scripts/runner_ask.mjs steps                   # per-Step ok/caveat/dige
//    node scripts/runner_ask.mjs snap 3                  # one Step's got_snap (the live world serialisation)
//    node scripts/runner_ask.mjs rungos                  # the held runs, each addressable by uid
//    node scripts/runner_ask.mjs snap 3 @ab12cd34        # a HELD run's frozen pin (the runner hangs in there)
//    node scripts/runner_ask.mjs accept                  # RE-RECORD: accept the live run's steps as the new
//                                                          #  fixture (the Accept-All button, over the wire) —
//                                                           #   the only sanctioned re-record path (never headless)
//    node scripts/runner_ask.mjs release                 # hang up: drop our engagement lease + GC the runs,
//                                                          #  tearing the runner's Story world down to H:Mundo (idle)
//
//  ENGAGEMENT: `run` takes a soft 10-min lease on the runner, keyed by this CLI's stable client id (the
//   claude cluster prepub from .env.cluster-claude, or RUNNER_CLIENT).  A second client is refused while the
//    lease is live ("don't run into each other's runners"); the same client re-attaches.  ping/state report
//     the lease + favourite_client.  After a `release` (or 10-min idle timeout), `@uid` on a reaped run says
//      it was garbage-collected, not a bare miss.
//
//  RUNNER_URL overrides the relay origin (default http://172.17.0.1:9091 — the runner dev server as seen
//   from the claude container; use http://localhost:9091 if running on the host).  Exit 1 when a --watch
//    run finishes red (outcome not ok) or the request errors, else 0 — so it scripts.
import { WebSocket } from 'ws'
import { readFileSync } from 'node:fs'

const OPS = ['ping', 'run', 'state', 'steps', 'snap', 'rungos', 'accept', 'release', 'runners']

// ── court a runner via Waft:Cluster ──────────────────────────────────────────────────────────
//  deLines the registry snap (wormhole/Cluster/toc.snap — the durable HostedIdentity directory the editor
//   builds from advertise beacons) so we can address ONE runner BY PREPUB (to:<prepub>) instead of the role
//    broadcast to:'runner' that fans to EVERY runner.  No eatfunc to import here (Lies_dispatch_target is
//     ghost-swallowed) and we don't need full deWaft — just the flat indent+comma lines:
//      `HostedIdentity:<prepub>,role:runner,friendly:…`.  (Editor-side the auto-allocator tries-another-if-busy;
//       the CLI does the OPPOSITE — it INSISTS on the one runner you name, for repeatable targeted testing.)
function clusterRunners() {
	let txt
	try { txt = readFileSync(new URL('../wormhole/Cluster/toc.snap', import.meta.url), 'utf8') } catch { return [] }
	const out = []
	for (const raw of txt.split('\n')) {
		const line = raw.trim()
		if (!line.startsWith('HostedIdentity:')) continue
		const parts = line.split(',')
		const pub = parts[0].slice('HostedIdentity:'.length)
		const props = {}
		for (const p of parts.slice(1)) { const i = p.indexOf(':'); if (i > 0) props[p.slice(0, i)] = p.slice(i + 1) }
		if (props.role === 'runner') out.push({ pub, friendly: props.friendly, favourite_client: props.favourite_client })
	}
	return out
}
// resolve --runner <id> (exact prepub ▸ prefix ▸ friendly) to a prepub; no id ⇒ the LATEST runner in the directory.
function resolveRunner(id) {
	const rs = clusterRunners()
	if (!id) return rs[rs.length - 1]?.pub
	return (rs.find(r => r.pub === id) ?? rs.find(r => r.pub.startsWith(id)) ?? rs.find(r => r.friendly === id))?.pub
}
const argv  = process.argv.slice(2)
const flags = new Set(argv.filter(a => a.startsWith('--') && !a.startsWith('--runner=')))
const uidTok = argv.find(a => a.startsWith('@'))             // @uid → target a HELD run's frozen pins
const uid    = uidTok ? uidTok.slice(1) : undefined
const runnerSel = (argv.find(a => a.startsWith('--runner=')) ?? '').split('=')[1]   // --runner=<prepub|prefix|friendly>
const pos   = argv.filter(a => !a.startsWith('-') && !a.startsWith('@'))
const op    = pos[0]
const arg   = pos[1]
const watch = flags.has('--watch')
if (!op || !OPS.includes(op)) {
	console.error('usage: node scripts/runner_ask.mjs <ping|run <Book>|state|steps|snap <n>|rungos|accept|release|runners> [@uid] [--runner=<id>] [--watch]')
	process.exit(2)
}
// `runners` — list the Waft:Cluster registry (no relay needed); a discovery aid for --runner=<id>.
if (op === 'runners') {
	const rs = clusterRunners()
	if (!rs.length) { console.error('no runners in wormhole/Cluster/toc.snap (none advertised yet, or the editor never wrote it)'); process.exit(1) }
	for (const r of rs) console.log(`${r.pub}${r.friendly ? `  ${r.friendly}` : ''}${r.favourite_client ? `  ★${r.favourite_client.slice(0, 8)}` : ''}`)
	process.exit(0)
}
// TARGET — who to address.  --runner=<id> courts ONE runner by prepub (insist, no failover); else the legacy
//  role broadcast 'runner' (the relay fans it; whichever acks first answers).
let TARGET = 'runner'
if (runnerSel !== undefined) {
	const pub = resolveRunner(runnerSel)
	if (!pub) { console.error(`✗ --runner=${runnerSel || '(latest)'}: no matching runner in wormhole/Cluster/toc.snap — try \`runners\``); process.exit(2) }
	TARGET = pub
}
if (op === 'run' && !arg)  { console.error('run needs a Book: node scripts/runner_ask.mjs run <Book>'); process.exit(2) }
if (op === 'snap' && !arg) { console.error('snap needs a step number: node scripts/runner_ask.mjs snap <n>'); process.exit(2) }

// clientId — the stable identity the runner records as the engagement holder (its don't-steal lease).
//  Prefer the claude cluster prepub (.env.cluster-claude → CLUSTER_IDENTO_CLAUDE_PUB, first 16 hex) so the
//   lease is STABLE across invocations — the runner can tell "was it you?" and let us re-attach to our own
//    held runner instead of refusing.  Override with RUNNER_CLIENT; fall back to a fixed tag if no key.
function clientId() {
	if (process.env.RUNNER_CLIENT) return process.env.RUNNER_CLIENT
	try {
		const env = readFileSync(new URL('../.env.cluster-claude', import.meta.url), 'utf8')
		const m = env.match(/CLUSTER_IDENTO_CLAUDE_PUB=([0-9a-fA-F]{16,})/)
		if (m) return m[1].slice(0, 16)
	} catch { /* no key file — fall through */ }
	return 'claude-cli'
}
const CLIENT = clientId()

const ask = { op, client: CLIENT }
if (op === 'run')  ask.book = arg
if (op === 'snap') ask.n = Number(arg)
if (uid) ask.uid = uid

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
		ws.send(JSON.stringify({ header: { type: 'runner_ask', from: cliAddr, to: TARGET, seq: Date.now(), corr }, ask: theAsk, corr }))
	})
}

const ws = new WebSocket(`${WS_URL}?addr=${encodeURIComponent(cliAddr)}`)
ws.on('error', (e) => { console.error(`✗ relay ${WS_URL}: ${String(e?.code ?? e?.message ?? e)}`); process.exit(1) })
const opened = await new Promise((resolve) => { const wd = setTimeout(() => resolve(false), 5000); ws.on('open', () => { clearTimeout(wd); resolve(true) }) })
if (!opened) { console.error(`✗ relay ${WS_URL}: connect timeout (5s) — is the dev server up and ?B= a runner booted?`); process.exit(1) }

let exitCode = 0
// INSIST: when courting a named runner (--runner=), DON'T failover — retry the SAME target on a busy refusal
//  or silence (an occupied or half-open runner), up to RUNNER_INSIST_TRIES.  The role broadcast stays single-shot.
const INSIST = runnerSel !== undefined ? Number(process.env.RUNNER_INSIST_TRIES || 5) : 1
let reply
for (let attempt = 1; ; attempt++) {
	reply = await sendAsk(ws, ask)
	const stuck = reply.control !== 'runner_ack' || reply.ok === false
	if (!stuck || attempt >= INSIST) break
	console.error(`… runner ${TARGET.slice(0, 8)} ${reply.ok === false ? `refused (${reply.result?.error ?? 'busy'})` : 'silent'} — insisting ${attempt}/${INSIST}`)
	await new Promise(r => setTimeout(r, Number(process.env.RUNNER_INSIST_MS || 3000)))
}
if (reply.control !== 'runner_ack') { console.error(`✗ ${op}: ${reply.error ?? 'no reply'}`); exitCode = 1 }
else if (op === 'snap' && reply.result?.got_snap) {
	console.error(`snap: Step ${reply.result.n} ok=${reply.result.ok} dige=${reply.result.dige}`)
	process.stdout.write(reply.result.got_snap.endsWith('\n') ? reply.result.got_snap : reply.result.got_snap + '\n')
} else if (reply.ok === false) {
	// a refused/failed op — surface the runner's reason on stderr (busy lease, GC'd run, unknown Book…)
	console.error(`✗ ${op}: ${reply.result?.error ?? 'failed'}`)
	if (reply.result?.engagement) console.error(`  lease: ${JSON.stringify(reply.result.engagement)}`)
	exitCode = 1
} else {
	console.log(`${op}: ${JSON.stringify({ ok: reply.ok, ...reply.result })}`)
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

// A watched RUN settled — do NOT auto-release: `release` GCs the run, so it would throw away exactly what
//  you need to look at (a red run especially — the failing steps, the snap diffs).  Handing the runner
//   back must be a deliberate act AFTER inspecting.  So just REMIND, with the exact commands — inspect
//    first, release when genuinely done (which also frees it for the editor + other clients).
if (watch && op === 'run') {
	console.error('')
	console.error(exitCode !== 0
		? '  ⚠ run went RED — inspect BEFORE releasing (release throws the run away):'
		: '  run settled — inspect if you want, then hand the runner back:')
	console.error('      failing steps: node scripts/runner_ask.mjs steps')
	console.error('      one step snap: node scripts/runner_ask.mjs snap <n>')
	console.error('      release:       node scripts/runner_ask.mjs release   ← frees it for the editor')
}

try { ws.close() } catch {}
process.exit(exitCode)
