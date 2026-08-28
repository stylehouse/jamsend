#!/usr/bin/env node
// runner_watch — "start a remote Story run with pointers, be polled when a pointer lands" (the owner's ask).
//  A THIN wrapper over scripts/runner_ask.mjs (no runner-side protocol change): optionally kick a Book run,
//   then long-poll the live run's introspectable state and evaluate one or more named POINTERS — JS
//    predicates over a small context — exiting 0 the instant a pointer LANDS.  It scripts (exit codes) and
//     composes with a /loop Monitor: point it at a run, walk away, get woken when the thing you care about
//      becomes true instead of eyeballing `state` in a spin loop.
//
//  A POINTER is `name:expr` — expr is JS evaluated with these in scope:
//     state   — the `state` reply object  ({ verdict, phase, n, total, done, ... })
//     steps   — the array from `steps`     ([{ n, ok, caveat, error, dige }, ...])
//     step(n) — steps.find(s => s.n === n)  (or undefined)
//     snap    — the `--snap=<n>` step's got_snap text (only if --snap given), else ''
//     phase, verdict, done, total, n — hoisted from state for terseness
//   Truthy → the pointer LANDED.  All pointers landed (or --any + one landed) → exit 0.  Timeout → exit 1.
//
//  USAGE
//   node scripts/runner_watch.mjs [--run <Book>] --land 'name:expr' [--land ...] \
//        [--runner=<relay-addr>] [--every=2000] [--timeout=120000] [--snap=<n>] [--any] [--quiet]
//  EXAMPLES
//   # run a Book and land when it finishes green
//   node scripts/runner_watch.mjs --run SwarmFerry --land 'green:done>=1 && verdict!=="failed"'
//   # attach to whatever is running and land when step 3 passes
//   node scripts/runner_watch.mjs --land 'beat3:step(3)?.ok===1'
//   # watch a FOREIGN tab (a real device over the census) and land when its snap shows a sealed pier
//   node scripts/runner_watch.mjs --runner=<addr> --snap=3 --land 'pier:/Pier,pub/.test(snap)'
import { spawn } from 'node:child_process'

const A = process.argv.slice(2)
const opt = (k, d) => { const p = A.find(x => x.startsWith(`--${k}=`)); return p ? p.slice(k.length + 3) : d }
const has = (k) => A.includes(`--${k}`)
const RUN     = (() => { const i = A.indexOf('--run'); return i >= 0 ? A[i + 1] : null })()
const RUNNER  = opt('runner', '')
const EVERY   = Number(opt('every', 2000))
const TIMEOUT = Number(opt('timeout', 120000))
const SNAP_N  = opt('snap', '')
const ANY     = has('any')
const QUIET   = has('quiet')
// gather every --land 'name:expr'
const POINTERS = []
for (let i = 0; i < A.length; i++) {
	if (A[i] === '--land' && A[i + 1]) {
		const raw = A[i + 1]
		const c = raw.indexOf(':')
		const name = c > 0 ? raw.slice(0, c) : `p${POINTERS.length + 1}`
		const expr = c > 0 ? raw.slice(c + 1) : raw
		POINTERS.push({ name, expr, landed: false, at: 0 })
	}
}
if (!POINTERS.length) { console.error('runner_watch: need at least one --land \'name:expr\' pointer'); process.exit(2) }

const runnerArgs = RUNNER ? [`--runner=${RUNNER}`] : []
const log = (...m) => { if (!QUIET) console.error(...m) }

// spawn runner_ask <verb> [arg], capture stdout, strip the leading "verb: " prefix, JSON.parse.
function ask(verb, arg) {
	return new Promise((resolve) => {
		const args = ['scripts/runner_ask.mjs', verb, ...(arg != null ? [String(arg)] : []), ...runnerArgs]
		const ps = spawn('node', args, { stdio: ['ignore', 'pipe', 'pipe'] })
		let out = ''
		ps.stdout.on('data', (d) => (out += d))
		ps.stderr.on('data', () => {})
		ps.on('close', () => {
			// runner_ask prints "state: {json}" / "steps: {json}" / "snap: ..." — find the first JSON object
			const m = out.match(/\{[\s\S]*\}\s*$/m) || out.match(/\{[\s\S]*\}/)
			if (!m) { resolve({ raw: out.trim() }); return }
			try { resolve(JSON.parse(m[0])) } catch { resolve({ raw: out.trim() }) }
		})
		ps.on('error', () => resolve(null))
	})
}

async function poll() {
	const state = await ask('state').catch(() => null) || {}
	const stepsReply = await ask('steps').catch(() => null) || {}
	const steps = Array.isArray(stepsReply.steps) ? stepsReply.steps : []
	let snap = ''
	if (SNAP_N !== '') {
		const sr = await ask('snap', SNAP_N).catch(() => null)
		snap = (sr && (sr.got_snap || sr.snap || sr.raw)) || ''
	}
	const step = (k) => steps.find((s) => Number(s.n) === Number(k))
	const ctx = { state, steps, step, snap,
		phase: state.phase, verdict: state.verdict, done: Number(state.done || 0),
		total: Number(state.total || 0), n: Number(state.n || 0) }
	return ctx
}

function evalPointer(p, ctx) {
	try {
		// eslint-disable-next-line no-new-func
		const fn = new Function('state', 'steps', 'step', 'snap', 'phase', 'verdict', 'done', 'total', 'n', `return (${p.expr});`)
		return !!fn(ctx.state, ctx.steps, ctx.step, ctx.snap, ctx.phase, ctx.verdict, ctx.done, ctx.total, ctx.n)
	} catch (e) { return false }
}

;(async () => {
	if (RUN) {
		log(`▶ starting run: ${RUN}${RUNNER ? ` @${RUNNER}` : ''}`)
		await ask('run', RUN)
	}
	const t0 = Date.now()
	log(`👀 watching ${POINTERS.length} pointer(s): ${POINTERS.map(p => p.name).join(', ')} · every ${EVERY}ms · timeout ${TIMEOUT}ms`)
	while (Date.now() - t0 < TIMEOUT) {
		const ctx = await poll()
		let landedNow = false
		for (const p of POINTERS) {
			if (p.landed) continue
			if (evalPointer(p, ctx)) {
				p.landed = true; p.at = Date.now() - t0; landedNow = true
				console.log(`LANDED ${p.name} @${p.at}ms  (phase=${ctx.phase} done=${ctx.done}/${ctx.total} verdict=${ctx.verdict ?? ''})`)
			}
		}
		const allLanded = POINTERS.every(p => p.landed)
		if ((ANY && landedNow) || allLanded) {
			log(`✓ ${ANY ? 'a pointer' : 'all pointers'} landed`)
			process.exit(0)
		}
		await new Promise(r => setTimeout(r, EVERY))
	}
	const pending = POINTERS.filter(p => !p.landed).map(p => p.name)
	console.log(`TIMEOUT after ${TIMEOUT}ms  pending: ${pending.join(', ')}`)
	process.exit(1)
})()
