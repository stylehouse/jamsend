// scripts/story_repl.mjs — a readline shell to EXPLORE a live browser Story runner over the relay.
//
//  The interactive companion to scripts/runner_ask.mjs (one-shot): this keeps ONE socket open and gives
//   you a prompt to drive + inspect a runner already running in a browser (booted ?B=<Book>) — run a
//    Book, watch it to a verdict, read a step's snap, and DIFF the live snap against the baked expected.
//  This is the §16 "agent as test driver — read pass/fail plus the diff as text, and iterate" loop
//   (Story_future.md), pointed at the LIVE runner instead of the headless pile.
//
//  Run:   node scripts/story_repl.mjs            (RUNNER_URL overrides the relay origin)
//  Then:  story› run MusuLive --watch
//         story› diff 2
//
//  After a run lands, the runner HANGS IN THERE holding it as a uid-addressable record (it pins the
//   produced step snaps off-snap), so you can keep pulling its diff/snap/trace by uid even after you've
//    kicked another run.  `run` prints the uid; `rungos` lists the held runs; append `@<uid>` (or bare `@`
//     = the last run) to any read to target a held run instead of the live one.
//
//  Commands (alias):
//    ping (p)            — runner liveness {role, channel, running}
//    run <Book> (r)      — kick a run on the live browser; sets current Book; prints the run's uid
//    rungos (rg)         — the held runs: ● active · uid · Book · phase · pinned step count
//    watch (w)           — poll state until the run settles done|failed
//    state (s)           — verdict {ok, ok_pct, done, caveat} + phase/n/total
//    steps [@uid]        — per-Step ok/caveat/dige
//    snap <n> [@uid]     — one Step's produced snap (the live world, or a held run's frozen pin)
//    diff <n> [@uid] (d) — colorised line-diff: got_snap vs expected (socket exp_snap, else the
//                           shared-disk fixture wormhole/Story/<Book>/<NNN>.snap)
//    books               — Books with a fixture dir under wormhole/Story
//    book <Book>         — set the current Book (for diff/snap fixture lookup) without running
//    help (h, ?) · quit (q, exit)
import { WebSocket } from 'ws'
import readline from 'node:readline'
import { readFileSync, readdirSync } from 'node:fs'

const HTTP       = process.env.RUNNER_URL || 'http://172.17.0.1:9091'
const WS_URL     = HTTP.replace(/^http/, 'ws').replace(/\/$/, '') + '/relay'
const TIMEOUT_MS = Number(process.env.RUNNER_ASK_TIMEOUT_MS || 8000)
const stamp      = Date.now()
const cliAddr    = `storyrepl-${stamp}`

const C = { red: s => `\x1b[31m${s}\x1b[0m`, grn: s => `\x1b[32m${s}\x1b[0m`, dim: s => `\x1b[2m${s}\x1b[0m`,
            cyan: s => `\x1b[36m${s}\x1b[0m`, yel: s => `\x1b[33m${s}\x1b[0m`, bold: s => `\x1b[1m${s}\x1b[0m` }

let corrSeq = 0
let ws = null
// TARGET — the ONE runner this session talks to.  'runner' is only the pre-court placeholder: the relay
//  fans a role-addressed frame to EVERY runner tab (two tabs ⇒ a `run` dispatches twice — the
//   double-dispatch bug), so main() courts a single prepub at connect and everything rides to:<prepub>.
let TARGET = 'runner'
function sendAsk(theAsk) {
	const corr = `sr-${stamp}-${corrSeq++}`
	return new Promise((resolve) => {
		let done = false
		const settle = (v) => { if (!done) { done = true; ws.off('message', onMsg); clearTimeout(timer); resolve(v) } }
		const onMsg = (data) => {
			let m; try { m = JSON.parse(String(data)) } catch { return }
			if (m.corr !== corr) return
			if (m.control === 'undeliverable') settle({ ok: false, error: 'no runner connected to the relay (frame dropped)' })
			else if (m.control === 'runner_ack') settle(m)
		}
		const timer = setTimeout(() => settle({ ok: false, error: `no reply in ${Math.round(TIMEOUT_MS / 1000)}s (runner not connected or half-open?)` }), TIMEOUT_MS)
		ws.on('message', onMsg)
		ws.send(JSON.stringify({ header: { type: 'runner_ask', from: cliAddr, to: TARGET, seq: Date.now(), corr }, ask: theAsk, corr }))
	})
}
// court — one role-broadcast ping, gather EVERY tab's ack (self + engagement) for a short grace after the
//  first, pick one (a free runner over a leased one), pin TARGET.  Same shape as runner_ask.mjs collectAcks.
function court() {
	const corr = `sr-${stamp}-${corrSeq++}`
	return new Promise((resolve) => {
		const acks = []
		let grace = null
		const finish = () => { ws.off('message', onMsg); clearTimeout(first); clearTimeout(grace); resolve(acks) }
		const onMsg = (data) => {
			let m; try { m = JSON.parse(String(data)) } catch { return }
			if (m.corr !== corr) return
			if (m.control === 'undeliverable') return finish()
			if (m.control !== 'runner_ack') return
			acks.push(m)
			if (!grace) { clearTimeout(first); grace = setTimeout(finish, 900) }
		}
		const first = setTimeout(finish, TIMEOUT_MS)
		ws.on('message', onMsg)
		ws.send(JSON.stringify({ header: { type: 'runner_ask', from: cliAddr, to: 'runner', seq: Date.now(), corr }, ask: { op: 'ping' }, corr }))
	})
}

let currentBook = null
let lastUid = null          // the uid of the most recent run — `@` with no chars resolves to it
const pad = n => String(n).padStart(3, '0')
function diskFixture(book, n) {
	if (!book) return null
	try { return readFileSync(`wormhole/Story/${book}/${pad(n)}.snap`, 'utf8') } catch { return null }
}

// LCS line-diff (a=expected/old, b=got/new) → [{tag:' '|'-'|'+', line}]. Step snaps are a few hundred
//  lines, so the O(n·m) table is fine; collapses long unchanged runs to keep the surprise visible.
function lineDiff(aText, bText) {
	const a = (aText || '').replace(/\n+$/, '').split('\n')
	const b = (bText || '').replace(/\n+$/, '').split('\n')
	const n = a.length, m = b.length
	const dp = Array.from({ length: n + 1 }, () => new Int32Array(m + 1))
	for (let i = n - 1; i >= 0; i--) for (let j = m - 1; j >= 0; j--)
		dp[i][j] = a[i] === b[j] ? dp[i + 1][j + 1] + 1 : Math.max(dp[i + 1][j], dp[i][j + 1])
	const out = []; let i = 0, j = 0
	while (i < n && j < m) {
		if (a[i] === b[j]) { out.push({ tag: ' ', line: a[i] }); i++; j++ }
		else if (dp[i + 1][j] >= dp[i][j + 1]) { out.push({ tag: '-', line: a[i] }); i++ }
		else { out.push({ tag: '+', line: b[j] }); j++ }
	}
	while (i < n) out.push({ tag: '-', line: a[i++] })
	while (j < m) out.push({ tag: '+', line: b[j++] })
	return out
}
function renderDiff(rows) {
	const CTX = 2
	const keep = new Array(rows.length).fill(false)
	rows.forEach((r, i) => { if (r.tag !== ' ') for (let k = Math.max(0, i - CTX); k <= Math.min(rows.length - 1, i + CTX); k++) keep[k] = true })
	const lines = []; let skipped = 0
	rows.forEach((r, i) => {
		if (!keep[i]) { skipped++; return }
		if (skipped) { lines.push(C.dim(`  … ${skipped} unchanged`)); skipped = 0 }
		lines.push(r.tag === '-' ? C.red(`- ${r.line}`) : r.tag === '+' ? C.grn(`+ ${r.line}`) : C.dim(`  ${r.line}`))
	})
	if (skipped) lines.push(C.dim(`  … ${skipped} unchanged`))
	const add = rows.filter(r => r.tag === '+').length, del = rows.filter(r => r.tag === '-').length
	return { body: lines.join('\n'), add, del }
}

const HELP = `commands:
  ping (p)            runner liveness
  run <Book> (r)      kick a run on the live browser (sets current Book; prints uid; add --watch to follow)
  rungos (rg)         the held runs (● active · uid · Book · phase · pinned step count)
  watch (w)           poll state until done|failed
  state (s)           verdict + phase/n/total
  steps [@uid]        per-Step ok/caveat/dige
  retain [on|off]     keep middle steps' got_snap (suppress the trim) — set it BEFORE a run
  snap <n> [@uid]     one Step's produced snap (live world, or a held run's frozen pin)
  trace <n> [@uid] (t) the step's WHY: beliefs-cycle trace + quiescent (causal vs timeout) label
  diff <n> [@uid] (d) got_snap vs expected (socket exp_snap, else disk fixture)
  diff <n> prev|<m> [@uid]  TEMPORAL: how the world changed step n-1 (or m) → n, both produced (one read)
  books               Books with a wormhole/Story fixture dir
  book <Book>         set current Book (for diff/snap) without running
  @uid                append to any read to target a HELD run (bare @ = the last run); else the live one
  help (h, ?)  ·  quit (q, exit)`

async function pollWatch(printer) {
	const t0 = Date.now(); let last = ''
	while (Date.now() - t0 < Number(process.env.RUNNER_WATCH_MS || 120000)) {
		await new Promise(r => setTimeout(r, 700))
		const s = await sendAsk({ op: 'state' })
		if (s.control !== 'runner_ack') { printer(C.red(`✗ state: ${s.error}`)); return }
		const run = s.result?.run, out = s.result?.outcome
		const tag = run ? `${run.phase} ${run.n ?? '?'}/${run.total ?? '?'}` : 'no run'
		if (tag !== last) { printer(`${C.dim('…')} ${C.cyan(tag)}  ${JSON.stringify(out)}`); last = tag }
		if (run && (run.phase === 'done' || run.phase === 'failed')) {
			printer(run.phase === 'done' ? C.grn(`✓ done`) : C.red(`✗ ${run.phase}`)); return
		}
	}
	printer(C.yel('watch timed out'))
}

async function handle(line, out) {
	const [cmd, ...rest] = line.split(/\s+/).filter(Boolean)
	if (!cmd) return
	const words = rest.filter(r => !r.startsWith('-') && !r.startsWith('@'))
	const arg = words[0]
	const arg2 = words[1]
	const watch = rest.includes('--watch') || rest.includes('-w')
	// @uid targets a HELD run (its frozen pins); bare `@` = the last run; none = the live/active run.
	const uidTok = rest.find(r => r.startsWith('@'))
	const uid = uidTok ? (uidTok.slice(1) || lastUid || undefined) : undefined
	const U = uid ? { uid } : {}
	switch (cmd) {
		case 'help': case 'h': case '?': out(HELP); return
		case 'quit': case 'q': case 'exit': ws.close(); process.exit(0)
		case 'books': {
			try { out(readdirSync('wormhole/Story').sort().join('  ')) } catch (e) { out(C.red(String(e?.message ?? e))) }
			return
		}
		case 'book': { if (arg) { currentBook = arg; out(`current Book → ${C.cyan(arg)}`) } else out(`current Book: ${currentBook ?? '(none)'}`); return }
		case 'retain': {
			const on = !(arg === 'off' || arg === '0' || arg === 'false')
			const r = await sendAsk({ op: 'retain', on })
			out(r.control === 'runner_ack' && r.ok !== false
				? `retain ${r.result.retain ? C.grn('ON') : C.dim('off')}${r.result.retain ? C.dim(' — got_snap trim suppressed; middle steps stay inspectable') : ''}`
				: C.red(`✗ retain: ${r.error ?? r.result?.error}`))
			return
		}
		case 'ping': case 'p': { const r = await sendAsk({ op: 'ping' }); out(r.control === 'runner_ack' ? JSON.stringify(r.result) : C.red(r.error)); if (r.result?.running?.book) currentBook = r.result.running.book; if (r.result?.running?.uid) lastUid = r.result.running.uid; return }
		case 'state': case 's': { const r = await sendAsk({ op: 'state' }); out(r.control === 'runner_ack' ? JSON.stringify(r.result) : C.red(r.error)); if (r.result?.run?.book) currentBook = r.result.run.book; if (r.result?.run?.uid) lastUid = r.result.run.uid; return }
		case 'steps': { const r = await sendAsk({ op: 'steps', ...U }); out(r.control === 'runner_ack' && r.ok !== false ? JSON.stringify(r.result) : C.red(r.error ?? r.result?.error)); return }
		case 'rungos': case 'rg': {
			const r = await sendAsk({ op: 'rungos' })
			if (r.control !== 'runner_ack' || r.ok === false) { out(C.red(`✗ rungos: ${r.error ?? r.result?.error}`)); return }
			const rs = r.result?.rungos ?? []
			if (!rs.length) { out(C.dim('(no runs held)')); return }
			for (const x of rs) out(`${x.active ? C.grn('●') : ' '} ${C.cyan(x.uid ?? '????????')}  ${x.book}  ${C.dim(x.phase)}${x.done != null ? ` ${x.done}/${x.total ?? '?'}` : ''}  ${x.pinned ? C.dim(`pinned ${x.pinned} step(s)`) : C.yel('live (not pinned)')}`)
			return
		}
		case 'run': case 'r': {
			if (!arg) { out(C.red('run needs a Book')); return }
			const r = await sendAsk({ op: 'run', book: arg })
			if (r.control !== 'runner_ack' || r.ok === false) { out(C.red(`✗ run: ${r.error ?? r.result?.error ?? 'rejected'}`)); return }
			currentBook = arg; if (r.result?.uid) lastUid = r.result.uid
			out(`${C.grn('▶')} run ${C.cyan(arg)} accepted${r.result?.uid ? `  ${C.dim('uid')} ${C.cyan(r.result.uid)}` : ''}`)
			if (watch) await pollWatch(out)
			return
		}
		case 'watch': case 'w': await pollWatch(out); return
		case 'snap': {
			if (!arg) { out(C.red('snap needs a step number')); return }
			const r = await sendAsk({ op: 'snap', n: Number(arg), ...U })
			if (r.control !== 'runner_ack' || r.ok === false) { out(C.red(`✗ snap: ${r.error ?? r.result?.error}`)); return }
			out(C.dim(`Step ${r.result.n} ok=${r.result.ok} dige=${r.result.dige}${uid ? ` @${uid}` : ''}`)); out(r.result.got_snap ?? '(no got_snap)')
			return
		}
		case 'trace': case 't': {
			if (!arg) { out(C.red('trace needs a step number')); return }
			const r = await sendAsk({ op: 'trace', n: Number(arg), ...U })
			if (r.control !== 'runner_ack' || r.ok === false) { out(C.red(`✗ trace: ${r.error ?? r.result?.error}`)); return }
			out(C.dim(`trace Step ${r.result.n}  ok=${r.result.ok}${r.result.caveat ? ' caveat' : ''} dige=${r.result.dige}  ${r.result.cycles} beliefs-cycle(s)`))
			const tr = r.result.trace
			if (!tr || !tr.length) { out(C.yel('  (no Run_trace — step may not have run, or trace was off)')); return }
			for (const e of tr) {
				const s = typeof e === 'string' ? e : JSON.stringify(e)
				out('  ' + (/timeout/i.test(s) ? C.red(s) : /quiescent/i.test(s) ? C.grn(s) : C.dim(s)))
			}
			return
		}
		case 'diff': case 'd': {
			if (!arg) { out(C.red('diff needs a step number')); return }
			const n = Number(arg)
			// temporal diff — `diff <n> prev` (n vs n-1) or `diff <n> <m>` (m → n): how the world
			//  changed BETWEEN steps, both produced (got_snap), neither the expected. Uses two snap ops.
			if (arg2 === 'prev' || arg2 === 'p' || (arg2 != null && !Number.isNaN(Number(arg2)))) {
				const baseN = (arg2 === 'prev' || arg2 === 'p') ? n - 1 : Number(arg2)
				const r = await sendAsk({ op: 'snaps', ns: [baseN, n], ...U })   // ONE atomic read — a coherent pair even while the runner churns (doubly stable on a held @uid)
				if (r.control !== 'runner_ack' || r.ok === false) { out(C.red(`✗ diff: ${r.error ?? r.result?.error}`)); return }
				const ra = r.result?.snaps?.[baseN], rb = r.result?.snaps?.[n]
				if (!ra?.got_snap || !rb?.got_snap) { out(C.yel(`need both Step ${baseN} and Step ${n} got_snap (have ${ra?.got_snap ? '✓' : '✗'}${baseN} / ${rb?.got_snap ? '✓' : '✗'}${n}; old steps get trimmed — use retain mode)`)); return }
				const { body, add, del } = renderDiff(lineDiff(ra.got_snap, rb.got_snap))
				out(C.dim(`diff Step ${baseN} → Step ${n}  ${C.red('-' + del)} ${C.grn('+' + add)}  (dige ${ra.dige} → ${rb.dige})`))
				out(add || del ? body : C.grn('  (identical — no change between these steps)'))
				return
			}
			const r = await sendAsk({ op: 'diff', n, ...U })
			if (r.control !== 'runner_ack' || r.ok === false) { out(C.red(`✗ diff: ${r.error ?? r.result?.error}`)); return }
			const book = r.result.book ?? currentBook; if (r.result.book) currentBook = r.result.book
			const got = r.result.got_snap
			if (got == null) { out(C.yel(`Step ${n} has no got_snap yet`)); return }
			let exp = r.result.exp_snap, src = 'socket exp_snap'
			if (exp == null) { exp = diskFixture(book, n); src = `disk fixture wormhole/Story/${book}/${pad(n)}.snap` }
			if (exp == null) { out(C.yel(`Step ${n}: no expected snap (not loaded over the socket, no disk fixture for Book "${book}") — likely an un-ACCEPTed Book (lie dige)`)); return }
			const { body, add, del } = renderDiff(lineDiff(exp, got))
			out(C.dim(`diff Step ${n}  (expected: ${src})  ${C.red('-' + del)} ${C.grn('+' + add)}  ok=${r.result.ok} dige=${r.result.dige}`))
			out(add || del ? body : C.grn('  (identical — no surprise)'))
			return
		}
		default: out(C.red(`unknown command "${cmd}" — try help`))
	}
}

async function main() {
	ws = new WebSocket(`${WS_URL}?addr=${encodeURIComponent(cliAddr)}`)
	ws.on('error', (e) => { console.error(C.red(`✗ relay ${WS_URL}: ${String(e?.code ?? e?.message ?? e)}`)); process.exit(1) })
	const opened = await new Promise((resolve) => { const wd = setTimeout(() => resolve(false), 5000); ws.on('open', () => { clearTimeout(wd); resolve(true) }) })
	if (!opened) { console.error(C.red(`✗ relay ${WS_URL}: connect timeout (5s) — is the dev server up and a ?B= runner booted?`)); process.exit(1) }

	console.log(C.bold(`Story REPL`) + C.dim(` → ${WS_URL}  (type help)`))
	const acks = await court()
	if (acks.length) {
		const eng  = (a) => a.result?.engagement
		const pick = acks.find(a => { const e = eng(a); return !e || e.status !== 'active' || e.stale }) ?? acks[0]
		if (pick.result?.self) TARGET = pick.result.self
		if (acks.length > 1) console.log(C.yel(`⇢ ${acks.length} runners acked — courting ${TARGET.slice(0, 8)}; the rest stay untouched`))
		console.log(C.dim(`runner: ${JSON.stringify(pick.result)}`))
		if (pick.result?.running?.book) currentBook = pick.result.running.book
	} else console.log(C.yel(`no runner answered yet — boot a ?B=<Book> tab; commands will retry`))

	const rl = readline.createInterface({ input: process.stdin, output: process.stdout, prompt: C.cyan('story› ') })
	// Serialise line handling — one command finishes before the next starts (so a piped/scripted
	//  session runs each in order and never exits mid-flight, and interactive stays one-at-a-time).
	const queue = []; let draining = false, closed = false
	const fin = () => { try { ws.close() } catch {}; process.exit(0) }
	async function drain() {
		if (draining) return
		draining = true
		while (queue.length) {
			const line = queue.shift()
			try { await handle(line.trim(), (s) => console.log(s)) } catch (e) { console.log(C.red(String(e?.stack ?? e))) }
		}
		draining = false
		if (closed) fin(); else rl.prompt()
	}
	rl.prompt()
	rl.on('line', (line) => { queue.push(line); drain() })
	rl.on('close', () => { closed = true; if (!draining) fin() })
}
main()
