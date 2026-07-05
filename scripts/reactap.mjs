// scripts/reactap.mjs — "which particles keep bumping?"  The socklog sibling for REACTIVITY:
//  socklog captures the wire, this censuses the TREE.  Asks a LIVE tab (the editor by default) to
//   arm the Stuff.svelte.ts bump tap (REACTAP) for a window, then prints the census — per-habitat
//    (nearest Waft) totals + the top bumping particles, each with a first-sighting stack naming
//     WHO bumps it.  For chasing idle churn (the editor idling at 30% CPU): run it while touching
//      NOTHING — any fat count over an idle window IS a re-render driver.
//
//  Usage:
//    node scripts/reactap.mjs                 # 5s window on the editor
//    node scripts/reactap.mjs 10000           # 10s window
//    node scripts/reactap.mjs --runner        # census the runner tab instead
//    node scripts/reactap.mjs --json          # the raw result JSON (diffable)
//
//  Rides the runner_ask/runner_ack corr rails (ask.op:'reactap') so the relay needs NO change (it
//   only corr-remembers ghost_compile + runner_ask asks); the editor serves just this op (LiesLies),
//    the runner forwards it out of Lies_runner_ask_recv.  Handler: Lies_reactap_recv (LiesFunk).
//  RUNNER_URL overrides the relay origin (default http://172.17.0.1:9091 — the dev server as seen
//   from this container; http://localhost:9091 on the host).  Exit 1 on error/no-reply, so it scripts.
import { WebSocket } from 'ws'

const argv   = process.argv.slice(2)
const flags  = new Set(argv.filter(a => a.startsWith('--')))
const ms     = Number(argv.find(a => /^\d+$/.test(a)) ?? 5000)
const TARGET = flags.has('--runner') ? 'runner' : 'editor'

const HTTP   = process.env.RUNNER_URL || 'http://172.17.0.1:9091'
const WS_URL = HTTP.replace(/^http/, 'ws').replace(/\/$/, '') + '/relay'
const stamp  = Date.now()
const corr   = `rt-${stamp}`
const addr   = `reactap-${stamp}`   // ephemeral — the reply comes back corr-routed, not by addr

const ws = new WebSocket(`${WS_URL}?addr=${encodeURIComponent(addr)}`)
ws.on('error', (e) => { console.error(`✗ relay ${WS_URL}: ${String(e?.code ?? e?.message ?? e)}`); process.exit(1) })
const opened = await new Promise((resolve) => { const wd = setTimeout(() => resolve(false), 5000); ws.on('open', () => { clearTimeout(wd); resolve(true) }) })
if (!opened) { console.error(`✗ relay ${WS_URL}: connect timeout (5s) — is the dev server up?`); process.exit(1) }

const reply = await new Promise((resolve) => {
	// the window runs REMOTELY before the ack, so the wait is ms + slack (a tab mid-think can lag the arm)
	const timer = setTimeout(() => resolve({ ok: false, error: `no reply in ${Math.round((ms + 15000) / 1000)}s — is an ${TARGET} tab open on :9091?` }), ms + 15000)
	ws.on('message', (data) => {
		let m; try { m = JSON.parse(String(data)) } catch { return }
		if (m.corr !== corr) return                                  // relay control:log + other corrs — ignore
		clearTimeout(timer)
		if (m.control === 'undeliverable') resolve({ ok: false, error: `no ${TARGET} connected to the relay (frame dropped)` })
		else if (m.control === 'runner_ack') resolve(m)
	})
	ws.send(JSON.stringify({ header: { type: 'runner_ask', from: addr, to: TARGET, seq: stamp, corr }, ask: { op: 'reactap', ms }, corr }))
})
try { ws.close() } catch { /* already closing */ }

if (reply.control !== 'runner_ack' || reply.ok === false) {
	console.error(`✗ reactap: ${reply.error ?? reply.result?.error ?? 'failed'}`)
	process.exit(1)
}
const r = reply.result
if (flags.has('--json')) { console.log(JSON.stringify(r, null, 1)); process.exit(0) }

console.log(`window ${r.ms}ms · ${r.thinks} thinks · ${r.bumps} bumps · ${r.particles} particles bumping`)
console.log('')
console.log('per habitat (nearest Waft):')
for (const h of r.wafts) console.log(`  ${String(h.count).padStart(6)}  ${h.habitat}`)
console.log('')
console.log(`top bumpers${r.dropped ? ` (60 of ${r.particles} — ${r.dropped} smaller ones dropped; --json has counts only for these 60 too)` : ''}:`)
for (const row of r.rows) {
	console.log(`  ${String(row.count).padStart(6)}  ${row.path}`)
	for (const f of row.who ?? []) console.log(`            ${f}`)
}
process.exit(0)
