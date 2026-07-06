// scripts/trace_gaps.mjs — where does a Story step's settle wall-clock actually go?
//
//  Pipe a `runner_ask trace <n>` dump in and it buckets the inter-event gaps of that step's
//   beliefs-cycle trace, so you can SEE the cost breakdown instead of guessing which lever to build:
//     tight  (<20ms)   — real belief work between events
//     mid    (20-100)  — the answer_calls 50ms DRAIN GATE (Technique A's target)
//     trickle(100-200) — the 150ms think trickle between maz levels (Technique B / lever #3)
//     work   (>200)    — real async (compile/run/disk) OR the trailing quiescence guard
//   plus the biggest gaps with the event kinds that bracket them (names the cost).
//
//  Usage:  node scripts/runner_ask.mjs trace 1 | node scripts/trace_gaps.mjs
//   First measured on LakeFlush 2026-07-07 — see Perf_todo.md status log for the finding that
//    reprioritised the levers (the 50ms drain gate dominates; trickle is minor; a ~428ms/step
//     quiescence guard was a surprise).  A step-1 result: 49% drain-gate, 22% quiescence, 11% trickle.
// analyse a runner_ask trace dump on stdin: where does a step's wall-clock go?
let s = ''
process.stdin.on('data', d => s += d)
process.stdin.on('end', () => {
  const r  = JSON.parse(s.match(/trace: (.*)/s)[1])
  const tr = r.trace || []
  const ts = tr.map(c => c.t)
  const span = ts[ts.length - 1] - ts[0]
  const kinds = {}
  tr.forEach(c => kinds[c.kind] = (kinds[c.kind] || 0) + 1)
  console.log(`step ${r.n}: span ${Math.round(span)}ms  events ${tr.length}`)
  console.log('kinds:', JSON.stringify(kinds))
  const gaps = ts.slice(1).map((t, i) => t - ts[i])
  const bucket = { tight_lt20: 0, mid_20_100: 0, trickle_100_200: 0, work_gt200: 0 }
  const sum = { tight: 0, mid: 0, trickle: 0, work: 0 }
  gaps.forEach(g => {
    if (g < 20) { bucket.tight_lt20++; sum.tight += g }
    else if (g < 100) { bucket.mid_20_100++; sum.mid += g }
    else if (g < 200) { bucket.trickle_100_200++; sum.trickle += g }
    else { bucket.work_gt200++; sum.work += g }
  })
  console.log('gap COUNTS:', JSON.stringify(bucket))
  console.log('gap TIME ms:', JSON.stringify({
    tight: Math.round(sum.tight), mid: Math.round(sum.mid),
    trickle: Math.round(sum.trickle), work: Math.round(sum.work),
  }))
  const big = gaps.map((g, i) => ({
    g: Math.round(g),
    from: tr[i].kind + '/' + (tr[i].tag || ''),
    to: tr[i + 1].kind + '/' + (tr[i + 1].tag || ''),
  })).filter(x => x.g > 120).sort((a, b) => b.g - a.g).slice(0, 14)
  console.log('biggest gaps (>120ms):')
  big.forEach(x => console.log(`  ${x.g}ms  ${x.from} -> ${x.to}`))
})
