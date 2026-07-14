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
//  Every shot ALSO prints the render telemetry (the "film strip" beside the frame): the over-time
//   story of what the pipeline did to turn the model into cells — wave / armed / remorph / morph /
//    settle / diag events since the last layout settle, plus the live gate (voronoi_on, seeds, cells).
//     `--why` skips the png and prints ONLY that (cheap, pollable).  It's the Cyto twin of reactap —
//      render-side, so it can never be a snapped world (metaphysics #2); this is its home.
//
//  Usage:
//    node scripts/runner_shot.mjs                     # /tmp/runner_shot.png + telemetry, full extent, last runner
//    node scripts/runner_shot.mjs shots/voro.png      # a named outfile
//    node scripts/runner_shot.mjs --why               # telemetry ONLY (no png) — what's processing into cells
//    node scripts/runner_shot.mjs --svg               # the GLASS: the voronoi SVG layer itself (cells, tuple
//                                                       #  regions, labels — everything cy.png() can't see), scoped
//                                                        #  CSS baked in, saved standalone (/tmp/runner_shot.svg);
//                                                         #  text stays text, so it also greps
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
// Unlike runner_ask, this script does NOT court — the relay routes `to:` by FULL prepub (or the
//  'runner' role), so a bare PREFIX ('77d26228') is unroutable and the ask silently drops (12s
//   timeout that reads as a dead/stale tab — a footgun that cost a whole debugging saga once).
//    So: resolve a short --runner against the sticky runner_ask wrote (its full courted prepub);
//     if they match, use the full addr; else warn loudly to court first rather than time out blind.
let TARGET = 'runner'
if (kv.runner) {
    TARGET = kv.runner
    if (TARGET !== 'runner' && TARGET.length < 16) {   // a full prepub is 16 hex; less = a prefix
        let sticky = ''
        try { sticky = readFileSync('/tmp/runner_ask.target', 'utf8').trim() } catch { /* none */ }
        if (sticky.startsWith(TARGET) && sticky.length >= 16) { TARGET = sticky; console.error(`⇢ --runner=${kv.runner} resolved to full prepub ${TARGET} via the sticky`) }
        else console.error(`⚠ --runner=${kv.runner} is a PREFIX — the relay needs a FULL prepub, so this will time out.  Court it first:  node scripts/runner_ask.mjs state --runner=${kv.runner}  then re-run WITHOUT --runner (uses the sticky).`)
    }
}
else { try { TARGET = readFileSync('/tmp/runner_ask.target', 'utf8').trim() || 'runner' } catch { /* no sticky — broadcast */ } }

const HTTP   = process.env.RUNNER_URL || 'http://172.17.0.1:9091'
const WS_URL = HTTP.replace(/^http/, 'ws').replace(/\/$/, '') + '/relay'
const stamp  = Date.now()
const corr   = `shot-${stamp}`
const addr   = `runshot-${stamp}`   // ephemeral — the reply comes back corr-routed, not by addr

const why = flags.has('--why')                          // telemetry only — no png
const svg = flags.has('--svg')                          // the voronoi SVG layer, standalone
const arm = flags.has('--arm')                          // remote face-arm: set the tab's ◈/▦ prefs
// --arm default arms ◈+▦ ONLY — never regions (arming ▧ once STASHED Cyto_regions=1 onto the
//  human's tab and the washes stuck across reloads; a remote arm must not leave surprise state).
//   --face=k:v,k:v overrides/extends, e.g. --face=regions:0 to clean that stash off a tab, or
//    --face=vsub:star to A/B the ▦ face parameter ('tuples' is the default face).
const faces = Object.fromEntries((kv.face ?? 'voronoi:1,subgraph:1').split(',').map(s => {
    const [k, v] = s.split(':')
    return [k, v === 'tuples' || v === 'star' ? v : Number(v)]
}))
const ask = arm ? { op: 'face', faces }
          : why ? { op: 'why' } : svg ? { op: 'svg' } : { op: 'shot', full: !flags.has('--viewport') }
if (kv.scale) ask.scale = Number(kv.scale)
if (kv.w)     ask.maxWidth = Number(kv.w)
if (kv.h)     ask.maxHeight = Number(kv.h)
if (kv.bg)    ask.bg = kv.bg

// print the render telemetry (the over-time model→cells story) — shared by `shot` (rides r.render)
//  and `--why` (the whole reply IS it).  dt = ms from the last layout settle (the epoch the owner named).
function printRender(cr) {
    if (!cr) { console.log('  (no render telemetry — reload the runner tab so Cytui remounts)'); return }
    const sy = (b) => b == null ? '?' : b ? 'yes' : 'no'
    console.log(`render gate: voronoi_on=${sy(cr.voronoi_on)} saw_stuffy=${sy(cr.saw_stuffy)} pref=${cr.voronoi_pref == null ? 'auto' : sy(cr.voronoi_pref)}`)
    console.log(`   now: seeds=${cr.seeds} cells=${cr.cells} nodes=${cr.nodes}${cr.since_settle_ms != null ? ` · ${cr.since_settle_ms}ms since last settle` : ''}${cr.diag_cures ? ` · ♒ diag cured ×${cr.diag_cures}` : ''}`)
    if (cr.cells === 0 && cr.seeds >= 2) console.log('   ⚠ ≥2 seeds but 0 cells — the render gate is trapping data (F1/F6)')
    if (cr.saw_stuffy === false) console.log('   ⓘ never armed (saw_stuffy=no) — no crushed chunks reached the render (empty world, or the seed never fired)')
    console.log('   log (dt ms from last settle):')
    for (const e of cr.log ?? []) {
        const { t, ev, dt, ...rest } = e
        const kv = Object.entries(rest).map(([k, v]) => `${k}:${v}`).join(' ')
        console.log(`     ${String(dt == null ? '·' : (dt >= 0 ? '+' + dt : dt)).padStart(6)}  ${ev.padEnd(9)} ${kv}`)
    }
}

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
    console.error(`✗ ${ask.op}: ${reply.error ?? reply.result?.error ?? 'failed'}`)
    process.exit(1)
}
const r = reply.result || {}
if (arm) { console.log(`◈ faces armed: ${JSON.stringify(r)}`); process.exit(0) }
if (why) { printRender(r); process.exit(0) }   // the whole reply IS the telemetry
if (svg) {
    if (!r.svg) { console.error(`✗ svg: runner returned no svg (${JSON.stringify(r)})`); process.exit(1) }
    const svgout = out.endsWith('.png') ? '/tmp/runner_shot.svg' : out
    writeFileSync(svgout, r.svg)
    console.log(`🩻 ${svgout} — ${(r.svg.length / 1024).toFixed(0)}KB · ${r.w}×${r.h} · ${r.paths} paths ${r.labels} labels${r.groups != null ? ` · ${r.groups} vsub-groups (state ${r.state_vsubs})` : ''}${r.svgs > 1 ? ` · ${r.svgs} svgs` : ''}${r.cands ? ` · cands [${r.cands.join(' ')}]` : ''}`)
    process.exit(0)
}
if (!r.png) { console.error(`✗ shot: runner returned no png (${JSON.stringify(r)})`); process.exit(1) }
const buf = Buffer.from(r.png, 'base64')
writeFileSync(out, buf)
console.log(`📸 ${out} — ${(buf.length / 1024).toFixed(0)}KB · canvas ${r.w}×${r.h}${r.full ? ' (full extent)' : ' (viewport)'} · ${r.nodes} nodes ${r.edges} edges${r.diag_cures ? ` · ♒ diagonal satan cured ×${r.diag_cures}` : ''}`)
printRender(r.render)
process.exit(0)
