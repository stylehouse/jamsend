// tab_watch.mjs — RELOAD A LIVE TAB AND WATCH A SUBTREE SETTLE, as a stream of diffs (owner 2026-09-05:
//  "can you automate reloading the page and watch it get correct? … a snap diff of the entire computation
//   every 5s").  Rides runner_ask's own rails — nothing new on the tab side:
//    1. `socklog on --reload` ARMS the tab (an unarmed player tab hangs every introspection ask) and reloads it;
//    2. every INTERVAL seconds, `minisnap <path> --diff` — the targeted, bounded C-tree dump, diffed against the
//       previous pull tab-side — and only the changed lines are printed, stamped with wall time.
//   node scripts/tab_watch.mjs <prepub> '<path>' [--every=5] [--for=300] [--depth=4] [--nodes=400] [--no-reload]
//   e.g. node scripts/tab_watch.mjs eed831f1977c4e81 'Swarm>Peering' --every=5 --for=240
//  Exit 0 when --for elapses; the last full minisnap is written beside the diffs (--out=<file>) so the END state
//   can be read whole.  ⚠ `runner_ask reload` on a player tab is self-serve but the tab takes ~10-25s to come back;
//    the first pulls are retried until one answers.
import { spawnSync } from 'node:child_process'
import fs from 'node:fs'
const args = process.argv.slice(2)
const pos = args.filter(a => !a.startsWith('--'))
const flag = (k, d) => { const f = args.find(a => a.startsWith(k + '=')); return f ? f.slice(k.length + 1) : d }
const [pub, path] = pos
if (!pub || !path) { console.error("usage: node scripts/tab_watch.mjs <prepub> '<path>' [--every=5] [--for=300] [--depth=4] [--nodes=400] [--no-reload] [--out=file]"); process.exit(2) }
const EVERY = Number(flag('--every', 5)), FOR = Number(flag('--for', 300)), DEPTH = flag('--depth', 4), NODES = flag('--nodes', 400)
const OUT = flag('--out', ''), RELOAD = !args.includes('--no-reload')
const ask = (op, extra = [], ms = 40000) => {
    const r = spawnSync('node', ['scripts/runner_ask.mjs', op, ...extra, `--player=${pub}`], { encoding: 'utf8', timeout: ms, maxBuffer: 64 * 1024 * 1024 })
    return { out: (r.stdout || '') + (r.stderr || ''), code: r.status, timedOut: r.error && r.error.code === 'ETIMEDOUT' }
}
const stamp = () => new Date().toTimeString().slice(0, 8)
if (RELOAD) {
    const a = ask('socklog', ['on', '--reload'], 30000)
    console.log(`${stamp()} armed+reload → ${a.timedOut ? 'no answer (was it already unarmed? the reload still lands)' : a.out.trim().split('\n').pop()}`)
} else console.log(`${stamp()} watching without reload`)
const t0 = Date.now(); let n = 0, last = ''
while (Date.now() - t0 < FOR * 1000) {
    const r = ask('minisnap', [path, `--depth=${DEPTH}`, `--nodes=${NODES}`, '--diff'], 30000)
    if (r.timedOut) { console.log(`${stamp()} … tab not answering yet`) }
    else {
        const body = r.out.trim()
        // minisnap --diff prints only what moved since the tab's previous pull; an unchanged pull is short
        const lines = body.split('\n').filter(l => l.trim())
        if (body && body !== last) { console.log(`${stamp()} ── pull ${++n} (${lines.length} lines)`); console.log(body); last = body }
        else console.log(`${stamp()} · no change`)
        if (OUT) fs.writeFileSync(OUT, body + '\n')
    }
    spawnSync('node', ['-e', `setTimeout(()=>{}, ${EVERY * 1000})`])
}
console.log(`${stamp()} done — ${n} changed pull(s) in ${FOR}s`)
