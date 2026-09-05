// story_late.mjs — NAME the nondeterminism in a Story step, instead of guessing at it.
//   node scripts/story_late.mjs <Book> [--runs=N] [--steps=A-B] [--settle=6]
//
// WHY (Story_hygiene_todo.md §0a–§0a.2, measured 2026-09-04).  A Story step does NOT end when its work
//  finishes — it ends when the belief mutex has been idle for `quiesce_snap_time` (default 1.5×TICK ≈
//   75-100ms; Story.svelte:2443 "the crux").  So every async completion is a race against that window:
//    land inside it and the work joins THIS step, land outside and it joins the NEXT one and the belief
//     round counter is offset from there on.  That is the whole of the observed flap — five Books × six
//      runs, `ok_pct:1` every time, and the ONLY line differing between two runs of a 304-line snap was
//       `self,round=39` vs `38`.  The belief machine is deterministic; the last 100ms is not.
//
// WHAT THIS COUNTS.  Per step, off the runner's own `Run_trace` (no core code changed, read-only):
//   - late      an entry AFTER the final `gallop: off` and before `quiescent`.  By definition this work
//                was triggered by something the todo registry did not hold — an unregistered async.
//                THIS IS THE NUMBER THAT MATTERS: it should be 0, and each one names the think that ran.
//   - rekick    the watchdog "actively re-drive a dropped wakeup" (Story.svelte ~2470), which fires off a
//                wall-clock idle threshold *inside* the step (`rekick: todo:17 idle:0.04s`).  A re-drive
//                whose firing depends on the clock is a coin-flip in the middle of the ordering.
//   - clip      `gallop: clip todo:N` — the gallop hit its cap with N todos still queued, so the drain
//                was cut by a bound rather than by running out of work.
//   - cycles    trace length (NOT belief passes — LiesFunk.svelte:2843 sets cycles = trace.length).
//                MusuHeist step 10 is 351 entries = 113 todo + 226 beliefs + 4 think, in ~1.1s: a gallop
//                 draining back-to-back, perfectly ordered.  The intensity is not the problem.
//
// READING IT.  A step with late=0, rekick=0, clip=0 is causally settled and should be dige-stable across
//  runs — the report checks that and says so.  A step that flaps WITH those all zero means the
//   nondeterminism is upstream of the trace and this tool cannot see it; say so rather than inventing.
//
// ⚠ Traces are only readable while the run's `This` is still up (~30-40s), and one `trace` call per step
//  is slow, so a long Book will lose its tail — that is reported as `(no trace)`, never silently skipped.
//  ⚠ Always settle between `release` and `run` (§0a.2): no gap wedged the standup 2 of 6.
import { spawnSync } from 'node:child_process'

const args  = process.argv.slice(2)
const book  = args.find(a => !a.startsWith('--'))
const RUNS  = Number((args.find(a => a.startsWith('--runs=')) || '').slice(7) || 3)
const SET   = Number((args.find(a => a.startsWith('--settle=')) || '').slice(9) || 6)
const range = (args.find(a => a.startsWith('--steps=')) || '').slice(8)
if (!book) { console.error('usage: node scripts/story_late.mjs <Book> [--runs=N] [--steps=A-B] [--settle=6]'); process.exit(2) }

const sh = (cmd, ms = 500000) => {
    const r = spawnSync('bash', ['-c', cmd], { encoding: 'utf8', timeout: ms, maxBuffer: 64 * 1024 * 1024 })
    return (r.stdout || '') + (r.stderr || '')
}
const lastJson = (txt) => {
    for (const l of txt.trim().split('\n').reverse()) {
        const i = l.indexOf('{'); if (i < 0) continue
        try { return JSON.parse(l.slice(i)) } catch (e) {}
    }
    return null
}

// one step's trace → the named counts.  `late` is the load-bearing one.
const dissect = (j) => {
    const tr = j.trace || []
    let lastOff = -1
    tr.forEach((e, i) => { if (e.kind === 'gallop' && String(e.tag).startsWith('off')) lastOff = i })
    const qi = tr.findIndex(e => e.kind === 'quiescent')
    const end = qi < 0 ? tr.length : qi
    // work after the gallop said "todo:0" but before the snap — the unregistered arrivals
    const late = lastOff < 0 ? [] : tr.slice(lastOff + 1, end).filter(e => ['todo', 'beliefs', 'think'].includes(e.kind))
    const kinds = {}
    for (const e of tr) kinds[e.kind] = (kinds[e.kind] || 0) + 1
    return {
        n: j.n, dige: String(j.dige || '').slice(0, 8), cycles: j.cycles, caveat: j.caveat ? 1 : 0,
        late: late.length,
        late_tags: [...new Set(late.filter(e => e.kind === 'think' || e.kind === 'todo').map(e => String(e.tag)))].slice(0, 4),
        rekick: kinds.rekick || 0,
        clip: tr.filter(e => e.kind === 'gallop' && String(e.tag).startsWith('clip')).length,
        thinks: kinds.think || 0,
        quiescent: tr.filter(e => e.kind === 'quiescent').map(e => String(e.tag)).join(','),
        timeout: tr.some(e => e.kind === 'quiescent' && String(e.tag).includes('timeout')) ? 1 : 0,
    }
}

const runs = []
for (let r = 1; r <= RUNS; r++) {
    sh('node scripts/runner_ask.mjs release')
    sh(`sleep ${SET}`)
    const out = sh(`timeout 500 node scripts/runner_ask.mjs run ${book} --watch`)
    const st  = lastJson(sh('timeout 60 node scripts/runner_ask.mjs state'))
    const total = st?.run?.total
    if (!total) { console.log(`run ${r}: WEDGED (phase=${st?.run?.phase ?? '?'}, n=${st?.run?.n ?? 'null'}) — the §0a.2 standup race; not counted`); runs.push(null); continue }
    let lo = 1, hi = total
    if (range) { const m = range.split('-'); lo = Number(m[0]) || 1; hi = Number(m[1] || m[0]) || total }
    const steps = {}
    for (let n = lo; n <= hi; n++) {
        const j = lastJson(sh(`timeout 40 node scripts/runner_ask.mjs trace ${n}`))
        if (!j || !j.trace) { steps[n] = null; continue }
        steps[n] = dissect(j)
    }
    const ok = st?.outcome?.ok_pct
    console.log(`run ${r}: ok_pct=${ok} caveat=${st?.outcome?.caveat} steps ${lo}-${hi}`)
    runs.push(steps)
}
sh('node scripts/runner_ask.mjs release')

const good = runs.filter(Boolean)
if (!good.length) { console.log('\nno usable runs — every one wedged; raise --settle'); process.exit(1) }

const ns = [...new Set(good.flatMap(s => Object.keys(s)))].map(Number).sort((a, b) => a - b)
console.log(`\n${book} — per step over ${good.length} usable run(s)`)
console.log('step | dige flap | late | rekick | clip | timeout | cycles')
const suspects = []
for (const n of ns) {
    const rows = good.map(s => s[n]).filter(Boolean)
    if (!rows.length) { console.log(`${String(n).padStart(4)} | (no trace — This cleared before this step)`); continue }
    const diges = new Set(rows.map(r => r.dige))
    const flap = diges.size > 1
    const late = Math.max(...rows.map(r => r.late))
    const rek  = Math.max(...rows.map(r => r.rekick))
    const clip = Math.max(...rows.map(r => r.clip))
    const to   = Math.max(...rows.map(r => r.timeout))
    const cyc  = [...new Set(rows.map(r => r.cycles))].join('/')
    console.log(`${String(n).padStart(4)} | ${flap ? `FLAP ${diges.size}` : '  stable'} | ${String(late).padStart(4)} | ${String(rek).padStart(6)} | ${String(clip).padStart(4)} | ${String(to).padStart(7)} | ${cyc}`)
    if (flap || late || rek) suspects.push({ n, flap, late, rek, clip, tags: rows.flatMap(r => r.late_tags) })
}

console.log('\n── what this names ─────────────────────────────────────────')
const unexplained = suspects.filter(s => s.flap && !s.late && !s.rek && !s.clip)
for (const s of suspects) {
    const why = [s.late && `${s.late} late arrival(s)`, s.rek && `${s.rek} rekick(s)`, s.clip && `${s.clip} gallop clip(s)`].filter(Boolean).join(' + ')
    if (why) console.log(`  step ${s.n}: ${s.flap ? 'FLAPS, ' : ''}${why}${s.tags.length ? ` — ${[...new Set(s.tags)].slice(0, 3).join(' | ')}` : ''}`)
}
if (unexplained.length) {
    console.log(`  ⚠ ${unexplained.length} step(s) FLAP with late=0 rekick=0 clip=0: ${unexplained.map(s => s.n).join(', ')}`)
    console.log('    the trace cannot see this one — the divergence is upstream of the step. Do not guess.')
}
if (!suspects.length) console.log('  nothing: every step causally settled and dige-stable across these runs.')
console.log('\n(late>0 is the target — it is work the todo registry did not hold. Wrap those in a req/expecting()')
console.log(' and the 75ms idle window stops deciding whether they land in this step or the next.)')
