// scripts/perf_ab.mjs — WARM, then measure a Book's settle wall-clock N times on the live runner.
//
//  Built to answer "did this perf lever actually move the needle?" WITHOUT the confounds that made the
//   lever-#4 full-sweep diff useless (see spec/Perf_todo.md status log 2026-07-06 + the memory
//    fleet-sweep-measurement-confounds):
//      • cold-start ≈ 2.5×  — the FIRST run after an HMR reload / idle gap is slow.  → we WARM first.
//      • long-runner drift  — a runner degrades over a long sweep.  → keep the batch SHORT + interleaved.
//      • single-run noise   — n=1 is a coin flip.  → N runs, report MEDIAN (robust) + spread.
//
//  A full 65-Book sweep is a CORRECTNESS net (verdict flips).  THIS is the PERF instrument.
//
//  Usage:
//    node scripts/perf_ab.mjs LakeTiles                       # warm 1, time 5, report median/spread
//    node scripts/perf_ab.mjs LakeTiles MusuGlide --n=7       # several Books, 7 timed runs each
//    node scripts/perf_ab.mjs LakeTiles --warm=2 --n=6        # 2 warmups discarded, 6 measured
//    node scripts/perf_ab.mjs LakeTiles --label=gate-on       # tag the run (for A/B notes)
//    node scripts/perf_ab.mjs LakeTiles --json                # machine-readable summary to stdout
//
//  A/B PROTOCOL (the whole point): run once per arm on the SAME warm runner, flipping only the lever's
//   flag (HMR) between arms.  Compare MEDIANS, not means, not single runs.  If the medians overlap within
//    spread, the lever is perf-neutral — do not ship risk for a signal you can't see.
//
//  Wraps runner_ask.mjs as a subprocess (run --watch; release) and times each with performance.now().
//   Node startup (~60ms) is a constant offset that cancels in an A/B delta.  RUNNER_URL / --runner pass
//    through to runner_ask.  Exit 1 if any measured run is red (so a perf batch also gates correctness).
import { spawnSync } from 'node:child_process'
import { performance } from 'node:perf_hooks'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

const HERE = dirname(fileURLToPath(import.meta.url))
const ASK  = join(HERE, 'runner_ask.mjs')

const argv    = process.argv.slice(2)
const books   = argv.filter(a => !a.startsWith('--'))
const opt     = Object.fromEntries(argv.filter(a => a.startsWith('--')).map(a => {
	const [k, v] = a.replace(/^--/, '').split('=')
	return [k, v ?? true]
}))
const N       = Number(opt.n    ?? 5)
const WARM    = Number(opt.warm ?? 1)
const GAP     = Number(opt.gap  ?? 1500)   // ms idle after release — let the runner tear down to H:Mundo
                                           //  and re-advertise before the next engage.  Back-to-back with
                                           //   no gap races the teardown→rebuild and degrades the runner
                                           //    (reds cluster on the LAST, most-hammered runs).
const label   = opt.label ? String(opt.label) : ''
const passRunner = opt.runner ? [`--runner=${opt.runner}`] : []
// blocking sleep (the harness is deliberately sequential — one settle at a time, no overlap).
const sleep = ms => { if (ms > 0) Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms) }

if (!books.length) {
	console.error('usage: node scripts/perf_ask.mjs <Book> [<Book>...] [--n=5] [--warm=1] [--label=tag] [--json]')
	process.exit(2)
}

function ask(args, { capture = false } = {}) {
	return spawnSync('node', [ASK, ...args, ...passRunner], {
		encoding: 'utf8',
		stdio: capture ? ['ignore', 'pipe', 'pipe'] : ['ignore', 'ignore', 'ignore'],
	})
}
// one settle: run --watch (blocks to done|failed), then release.  Returns {ms, ok}.
function timedRun(book) {
	const t0 = performance.now()
	const r  = ask(['run', book, '--watch'])
	const ms = performance.now() - t0
	ask(['release'])
	sleep(GAP)   // let the runner quiesce to idle before the next engage
	return { ms, ok: r.status === 0 }
}
const median = xs => {
	const s = [...xs].sort((a, b) => a - b)
	const m = Math.floor(s.length / 2)
	return s.length % 2 ? s[m] : (s[m - 1] + s[m]) / 2
}
const fmt = ms => (ms / 1000).toFixed(2) + 's'

function pingOrDie() {
	const r = ask(['ping'], { capture: true })
	if (r.status !== 0 || !/"channel":"up"/.test(r.stdout || '')) {
		console.error('runner not up — ping failed:\n' + (r.stdout || '') + (r.stderr || ''))
		process.exit(3)
	}
}

const results = []
pingOrDie()
console.error(`perf_ab${label ? ` [${label}]` : ''}: warm=${WARM} n=${N}  books=${books.join(',')}`)
for (const book of books) {
	process.stderr.write(`  ${book}: warming(${WARM})`)
	for (let i = 0; i < WARM; i++) { timedRun(book); process.stderr.write('.') }
	const runs = []
	process.stderr.write(` measuring(${N})`)
	for (let i = 0; i < N; i++) {
		const r = timedRun(book)
		runs.push(r)
		process.stderr.write(r.ok ? '.' : '✗')
	}
	const times  = runs.map(r => r.ms)
	const greens = runs.filter(r => r.ok).length
	const med    = median(times)
	const mn     = Math.min(...times)
	const mx     = Math.max(...times)
	const spread = mx - mn
	const summary = {
		book, label,
		n: N, green: greens,
		median_ms: Math.round(med), min_ms: Math.round(mn), max_ms: Math.round(mx),
		spread_ms: Math.round(spread), spread_pct: Math.round((spread / med) * 100),
		times_ms: times.map(t => Math.round(t)),
	}
	results.push(summary)
	process.stderr.write('\n')
	console.error(
		`  ${book}: median ${fmt(med)}  (min ${fmt(mn)} · max ${fmt(mx)} · spread ${Math.round(spread)}ms/${summary.spread_pct}%)`
		+ `  green ${greens}/${N}` + (greens < N ? '  ← RED runs, perf number is suspect' : ''),
	)
}

if (opt.json) console.log(JSON.stringify(results, null, 2))
const allGreen = results.every(r => r.green === r.n)
process.exit(allGreen ? 0 : 1)
