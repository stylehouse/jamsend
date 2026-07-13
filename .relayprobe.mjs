// .relayprobe.mjs — sit on a relay for N seconds and histogram the traffic it narrates.
//  The relay broadcasts control:log lines to every connected socket, so this sees every
//   forward WITHOUT being addressed — a passive wire-rate counter for the frame-storm hunt.
import { WebSocket } from 'ws'

const URL = process.argv[2] ?? 'ws://172.17.0.1:9092/relay'
const MS = Number(process.argv[3] ?? 10000)
const ws = new WebSocket(`${URL}?addr=probe-${Date.now()}`)
ws.on('error', e => { console.error(`✗ ${URL}: ${e?.code ?? e?.message ?? e}`); process.exit(1) })
await new Promise((res, rej) => { ws.on('open', res); setTimeout(() => rej(new Error('connect timeout')), 5000) }).catch(e => { console.error(`✗ ${e.message}`); process.exit(1) })

const hist = new Map()
let total = 0
const sample = new Map()   // kind → first raw line (trimmed)
ws.on('message', d => {
    total++
    let m; try { m = JSON.parse(String(d)) } catch { hist.set('unparsed', (hist.get('unparsed') ?? 0) + 1); return }
    // control:log frames narrate a forward; bucket by the narrated type when present
    const kind = m.control === 'log'
        ? `log:${String(m.line ?? m.msg ?? '').match(/\b(become_book|run_phase|run_result|advertise|ping|pong|ghost_ledger|runner_ask|runner_ack|wormhole_\w+|grant_\w+|rungo|ghost_compile\w*)\b/)?.[1] ?? 'other'}`
        : (m.control ? `control:${m.control}` : (m.header?.type ?? m.type ?? '?'))
    hist.set(kind, (hist.get(kind) ?? 0) + 1)
    if (!sample.has(kind)) sample.set(kind, String(m.line ?? JSON.stringify(m)).slice(0, 160))
})
await new Promise(r => setTimeout(r, MS))
try { ws.close() } catch {}
console.log(`${URL} — ${total} frames in ${MS}ms (${(total / (MS / 1000)).toFixed(1)}/s)`)
for (const [k, n] of [...hist.entries()].sort((a, b) => b[1] - a[1])) console.log(`  ${String(n).padStart(6)}  ${k}\n          ${sample.get(k)}`)
process.exit(0)
