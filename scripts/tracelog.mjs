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
//    node scripts/tracelog.mjs --file <path>   # a specific dump (a fleet has one file per pub/boot)
//    node scripts/tracelog.mjs --list          # list the dump files (role · pub · boot · marks · age)
//
//  Format matches `runner_ask world`'s supply block on purpose (+Δms  ev  [id]  extra  ⟵ SLOW), so
//   the disk view and the relay view read identically — only the CARRIER differs.
import { readdirSync, readFileSync, statSync } from 'node:fs'
import { join } from 'node:path'

const DIR  = 'wormhole/_trace'
const args = process.argv.slice(2)
const has  = (f) => args.includes(f)
const val  = (f) => { const i = args.indexOf(f); return i >= 0 ? args[i + 1] : null }

const WATCH = has('--watch')
const HEIST = has('--heist')
const LIFE  = has('--life')
const FILE  = val('--file')
const LIST  = has('--list')

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
		.map((n) => ({ n, path: join(DIR, n), mtime: statSync(join(DIR, n)).mtimeMs }))
		.sort((a, b) => b.mtime - a.mtime)
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

function fmt(e, prev) {
	const d = prev == null ? 0 : e.t - prev
	const extra = Object.keys(e).filter((k) => k !== 't' && k !== 'ev' && k !== 'id').map((k) => `${k}=${e[k]}`).join(' ')
	const flag = d >= 2000 ? '  ⟵ SLOW' : d >= 500 ? '  ⟵ slow' : ''
	return `  +${String(d).padStart(6)}ms  ${String(e.ev).padEnd(18)} ${e.id ? '[' + e.id + '] ' : ''}${extra}${flag}`
}

if (LIST) {
	const d = dumps()
	if (!d.length) { console.error(`(no ${DIR}/*.jsonl — arm socklog on the tab, then play/heist)`); process.exit(1) }
	const now = Date.now()
	for (const f of d) {
		const m = marks(f.path)
		const age = Math.round((now - f.mtime) / 1000)
		const [role, pub] = f.n.replace(/\.jsonl$/, '').split('-')
		console.log(`  ${role.padEnd(6)} ${(pub || '').slice(0, 12).padEnd(12)}  ${String(m.length).padStart(4)} marks  ${age}s ago  ${f.n}`)
	}
	process.exit(0)
}

function pick() {
	if (FILE) return FILE
	const d = dumps()
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
	console.log(`${path} — ${m.length} mark${m.length === 1 ? '' : 's'}${tag ? ` (${tag.trim()})` : ''}  (Δ = ms since previous mark):`)
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
	const p = FILE || (dumps()[0]?.path ?? cur)
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
