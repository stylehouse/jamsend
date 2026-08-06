// scripts/tracelog.mjs — the RELAY-FREE supply|heist tail.  Reads the timestamped stage marks a
//  live tab dumped to wormhole/_trace/ (Lies_dump_supply — the Radio_trace ring on the SAME FSA
//   path as the socklog dump), so you SEE what a heisting/streaming process is doing even while the
//    relay is down or the CPU is pinned — the one channel that keeps working when `runner_ask world`
//     (which reads the SAME ring, but over the /relay websocket) can't reach the tab.
//
//  Arm it on the tab first: the 🪪 Id hatch → socklog toggle (or boot ?socklog / ?watch=N).  Then
//   play/heist; the tab overwrites wormhole/_trace/<role>-<pub>-<boot>.jsonl every ~5s.  No reload
//    needed for the trace (it reads M.c.supply_trace directly, not the socket tap).
//
//  Usage:
//    node scripts/tracelog.mjs                 # newest _trace file, whole ring, one shot
//    node scripts/tracelog.mjs --watch         # live tail: re-read ~1s, print only new marks
//    node scripts/tracelog.mjs --heist         # only heist-* marks (+ the stream/transcode kin)
//    node scripts/tracelog.mjs --watch --life  # only the mount/destroy ladder (ui/micro/lifetell.ts)
//                                              #  — world > stage > faces > mold > face:<Kind>.
//                                              #  Outermost climbing serial = the real teardown.
//    node scripts/tracelog.mjs --runner=<pub>  # newest dump for THAT tab (pub prefix ok) — never
//                                              #  someone else's ring
//    node scripts/tracelog.mjs --file <path>   # a specific dump (a fleet has one file per pub/boot)
//    node scripts/tracelog.mjs --list          # list the dump files (role · pub · boot · marks · age)
//
//  Format matches `runner_ask world`'s supply block on purpose (+Δms  ev  [id]  extra  ⟵ SLOW), so
//   the disk view and the relay view read identically — only the CARRIER differs.
import { readdirSync, readFileSync, statSync } from 'node:fs'
import { join } from 'node:path'

const DIR  = 'wormhole/_trace'
const args = process.argv.slice(2)

// STRICT parse — an unknown arg REFUSES instead of falling on the floor.  The old permissive
//  `args.includes` cost an evening on 2026-08-06: `--runner=X` (then unsupported) was silently
//   ignored, pick() served the newest file BY MTIME, and an idle grid runner's honest `starved
//    why=nobody` got attributed to a different tab for hours.  Valued flags take `=` OR a space.
const FLAGS = { '--watch': 0, '--heist': 0, '--life': 0, '--list': 0, '--file': 1, '--runner': 1 }
const opt = {}
for (let i = 0; i < args.length; i++) {
	const a = args[i]
	const eq = a.indexOf('=')
	const name = eq >= 0 ? a.slice(0, eq) : a
	if (!(name in FLAGS)) {
		console.error(`tracelog: unknown arg ${a}\n  known: ${Object.keys(FLAGS).join(' ')}  (valued flags take = or a space)`)
		process.exit(2)
	}
	if (FLAGS[name] === 0) {
		if (eq >= 0) { console.error(`tracelog: ${name} takes no value`); process.exit(2) }
		opt[name] = true
	} else {
		const v = eq >= 0 ? a.slice(eq + 1) : args[++i]
		if (v == null || v === '' || (eq < 0 && v.startsWith('--'))) { console.error(`tracelog: ${name} needs a value`); process.exit(2) }
		opt[name] = v
	}
}

const WATCH  = !!opt['--watch']
const HEIST  = !!opt['--heist']
const LIFE   = !!opt['--life']
const FILE   = opt['--file'] ?? null
const LIST   = !!opt['--list']
const RUNNER = opt['--runner'] ?? null

// heist filter: the acquisition marks + the stream/transcode kin that feed a pull.
const heisty = (ev) => /^heist-/.test(ev) || /^(transcode-|stream-|pcm-)/.test(ev)
// life filter: the lifecycle ladder (ui/micro/lifetell.ts) + the stage-gate toggle it pairs with —
//  a remount hunt wants ONLY these, because the ring is capped 300 and a busy download drowns them.
const lifey = (ev) => /^life-/.test(ev) || ev === 'vyto-show-toggle'
// one predicate, so --watch and the one-shot path can never drift apart.
const keep = (e) => (!HEIST || heisty(e.ev)) && (!LIFE || lifey(e.ev))

function dumps() {
	let names
	try { names = readdirSync(DIR).filter((n) => n.endsWith('.jsonl')) } catch { return [] }
	return names
		.map((n) => {
			const [role, pub, boot] = n.replace(/\.jsonl$/, '').split('-')
			return { n, role, pub: pub || '', boot: boot || '', path: join(DIR, n), mtime: statSync(join(DIR, n)).mtimeMs }
		})
		.sort((a, b) => b.mtime - a.mtime)
}

// --runner filter: match the PUB segment of <role>-<pub>-<boot>.jsonl by prefix.  A miss is an
//  ERROR that names what IS on disk — never a silent fall-through to somebody else's ring.
function dumps_for(runner) {
	const d = dumps()
	if (!runner) return d
	const hit = d.filter((f) => f.pub.startsWith(runner))
	if (!hit.length) {
		console.error(`tracelog: no dump for --runner=${runner} in ${DIR}/`)
		const pubs = [...new Set(d.map((f) => `${f.role} ${f.pub}`))]
		for (const p of pubs) console.error(`  have: ${p}`)
		if (!d.length) console.error('  (none at all — arm socklog on the tab first)')
		process.exit(1)
	}
	return hit
}

function marks(path) {
	let txt
	try { txt = readFileSync(path, 'utf8') } catch { return [] }
	const out = []
	for (const line of txt.split('\n')) {
		if (!line.trim()) continue
		try { const m = JSON.parse(line); if (m && typeof m.t === 'number') out.push(m) } catch {}
	}
	return out.sort((a, b) => a.t - b.t)
}

// T0 — the first RENDERED mark, so every line carries an absolute `@Nms` offset beside its delta.
//  Why both: the `+Δms` is time since the previous SURVIVING mark, which is exactly right inside
//   tracelog's own --heist/--life filters (deltas are computed after `keep`) and exactly WRONG the
//    moment the output is piped through grep — the dropped lines silently widen every gap. That
//     misread cost two false calls on 2026-08-06 ("advertise fires every 601ms", then a boast-floor
//      suppression that could not be read either way). `@` is grep-proof: it is anchored to T0, not
//       to the neighbour, so a filtered line still says when it happened.
let T0 = null
function fmt(e, prev) {
	if (T0 == null) T0 = e.t
	const d = prev == null ? 0 : e.t - prev
	const extra = Object.keys(e).filter((k) => k !== 't' && k !== 'ev' && k !== 'id').map((k) => `${k}=${e[k]}`).join(' ')
	const flag = d >= 2000 ? '  ⟵ SLOW' : d >= 500 ? '  ⟵ slow' : ''
	return `  @${String(e.t - T0).padStart(7)} +${String(d).padStart(6)}ms  ${String(e.ev).padEnd(18)} ${e.id ? '[' + e.id + '] ' : ''}${extra}${flag}`
}

if (LIST) {
	const d = dumps_for(RUNNER)
	if (!d.length) { console.error(`(no ${DIR}/*.jsonl — arm socklog on the tab, then play/heist)`); process.exit(1) }
	const now = Date.now()
	for (const f of d) {
		const m = marks(f.path)
		const age = Math.round((now - f.mtime) / 1000)
		console.log(`  ${f.role.padEnd(6)} ${f.pub.slice(0, 12).padEnd(12)}  ${String(m.length).padStart(4)} marks  ${age}s ago  ${f.n}`)
	}
	process.exit(0)
}

function pick() {
	if (FILE) return FILE
	const d = dumps_for(RUNNER)
	return d.length ? d[0].path : null
}

const path = pick()
if (!path) {
	console.error(`(no ${DIR}/*.jsonl yet)\n  Arm the tab first: 🪪 Id hatch → socklog (or boot ?socklog / ?watch), then play/heist.\n  The heisting tab writes to disk via its LOCAL FSA share — no relay needed.`)
	process.exit(1)
}

if (!WATCH) {
	const m = marks(path).filter(keep)
	const tag = HEIST ? ' heist' : LIFE ? ' life' : ''
	if (!m.length) { console.error(`(${path}: no${tag} marks yet)`); process.exit(1) }
	console.log(`${path} — ${m.length} mark${m.length === 1 ? '' : 's'}${tag ? ` (${tag.trim()})` : ''}  (@ = ms since first shown mark — grep-safe; Δ = ms since previous SHOWN mark — NOT grep-safe):`)
	let prev = null
	for (const e of m) { console.log(fmt(e, prev)); prev = e.t }
	process.exit(0)
}

// --watch: print the current ring, then poll the newest file ~1s and print only marks newer than
//  the last t seen.  A page reload rotates to a fresh file (new SOCKCAP_BOOT); re-pick each poll so
//   the tail follows it.  Ctrl-C to stop.  (No fs.watch — a ~5s overwrite + 1s poll is plenty, and
//    polling survives the atomic-rename some FSA writes do that fs.watch misses.)
console.log(`tail ${path}  (watching ${DIR}; Ctrl-C to stop)`)
let seen = -Infinity
let cur = path
function tick() {
	const p = FILE || (dumps_for(RUNNER)[0]?.path ?? cur)
	cur = p
	const m = marks(p).filter((e) => e.t > seen && keep(e))
	if (m.length) {
		let prev = seen === -Infinity ? null : seen
		for (const e of m) { console.log(fmt(e, prev)); prev = e.t }
		seen = m[m.length - 1].t
	}
}
tick()
setInterval(tick, 1000)
