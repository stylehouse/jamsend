// scripts/runner_shot.mjs — "take a PNG of the live Cyto canvas."  The PIXEL twin of runner_ask:
//  runner_ask reads the SNAP (what a fixture can carry); this reads the CANVAS (what it can't).  Asks
//   the LIVE runner tab (booted ?B=<Book> on :9091) to render its Cytoscape power-diagram to a base64
//    PNG via cy.png() and ships it back over the SAME /relay corr rails — so a headless caller can finally
//     SEE the render faults (cells-not-drawn, everything-Stuffing, the diagonal collapse) instead of
//      relying on a human's eyes.  Handler: op:'shot' in Lies_runner_ask_recv (LiesFunk.svelte); cy is
//       stashed on top_House by Cytui onMount (RELOAD the runner tab once after the handler first lands).
//
//  Rides the runner_ask/runner_ack corr rails (ask.op:'shot') so the relay needs NO change — it already
//   corr-remembers runner_ask asks and routes the {control:'runner_ack'} reply straight back here.
//
//  Usage:
//    node scripts/runner_shot.mjs                     # /tmp/runner_shot.png, full graph extent, last-courted runner
//    node scripts/runner_shot.mjs shots/voro.png      # a named outfile
//    node scripts/runner_shot.mjs --viewport          # only what's on screen (default is the full extent)
//    node scripts/runner_shot.mjs --scale=2           # 2x pixels (sharper + bigger)
//    node scripts/runner_shot.mjs --w=1200            # cap maxWidth (px)
//    node scripts/runner_shot.mjs --runner=49dee9     # court ONE runner by prepub|prefix (else the sticky, else broadcast)
//
//  TARGET defaults to the runner runner_ask last courted (its /tmp/runner_ask.target sticky) so a shot lands
//   on the same tab you just ran a Book on.  RUNNER_URL overrides the relay origin (default the dev server
//    as seen from this container).  Exit 1 on error/no-reply, so it scripts.
import { WebSocket } from 'ws'
import { readFileSync, writeFileSync } from 'node:fs'

const argv  = process.argv.slice(2)
const flags = new Set(argv.filter(a => a.startsWith('--') && !a.includes('=')))
const kv    = Object.fromEntries(argv.filter(a => a.startsWith('--') && a.includes('=')).map(a => a.slice(2).split('=')))
const out   = argv.find(a => !a.startsWith('-')) || '/tmp/runner_shot.png'

// TARGET — the runner runner_ask last courted (sticky), so a shot lands on the tab you just ran on;
//  --runner=<id> overrides; else the role broadcast 'runner' (first ack wins — fine with one tab up).
let TARGET = 'runner'
if (kv.runner) TARGET = kv.runner
else { try { TARGET = readFileSync('/tmp/runner_ask.target', 'utf8').trim() || 'runner' } catch { /* no sticky — broadcast */ } }

const HTTP   = process.env.RUNNER_URL || 'http://172.17.0.1:9091'
const WS_URL = HTTP.replace(/^http/, 'ws').replace(/\/$/, '') + '/relay'
const stamp  = Date.now()
const corr   = `shot-${stamp}`
const addr   = `runshot-${stamp}`   // ephemeral — the reply comes back corr-routed, not by addr

const ask = { op: 'shot', full: !flags.has('--viewport') }
if (kv.scale) ask.scale = Number(kv.scale)
if (kv.w)     ask.maxWidth = Number(kv.w)
if (kv.h)     ask.maxHeight = Number(kv.h)
if (kv.bg)    ask.bg = kv.bg

const ws = new WebSocket(`${WS_URL}?addr=${encodeURIComponent(addr)}`)
ws.on('error', (e) => { console.error(`✗ relay ${WS_URL}: ${String(e?.code ?? e?.message ?? e)}`); process.exit(1) })
const opened = await new Promise((r) => { const wd = setTimeout(() => r(false), 5000); ws.on('open', () => { clearTimeout(wd); r(true) }) })
if (!opened) { console.error(`✗ relay ${WS_URL}: connect timeout (5s) — is the dev server up and ?B= a runner booted?`); process.exit(1) }

const reply = await new Promise((resolve) => {
    const timer = setTimeout(() => resolve({ ok: false, error: 'no reply in 12s — is a runner tab open (and reloaded since the shot handler landed)?' }), 12000)
    ws.on('message', (data) => {
        let m; try { m = JSON.parse(String(data)) } catch { return }
        if (m.corr !== corr) return                                  // relay control:log + other corrs — ignore
        clearTimeout(timer)
        if (m.control === 'undeliverable') resolve({ ok: false, error: 'no runner connected to the relay (frame dropped)' })
        else if (m.control === 'runner_ack') resolve(m)
    })
    ws.send(JSON.stringify({ header: { type: 'runner_ask', from: addr, to: TARGET, seq: stamp, corr }, ask, corr }))
})
try { ws.close() } catch { /* already closing */ }

if (reply.control !== 'runner_ack' || reply.ok === false) {
    console.error(`✗ shot: ${reply.error ?? reply.result?.error ?? 'failed'}`)
    process.exit(1)
}
const r = reply.result || {}
if (!r.png) { console.error(`✗ shot: runner returned no png (${JSON.stringify(r)})`); process.exit(1) }
const buf = Buffer.from(r.png, 'base64')
writeFileSync(out, buf)
console.log(`📸 ${out} — ${(buf.length / 1024).toFixed(0)}KB · canvas ${r.w}×${r.h}${r.full ? ' (full extent)' : ' (viewport)'} · ${r.nodes} nodes ${r.edges} edges`)
process.exit(0)
