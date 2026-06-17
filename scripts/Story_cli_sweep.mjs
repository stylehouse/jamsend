// Story_cli_sweep — run the headless Story runner over many Books and aggregate a
//  fleet verdict (green/amber/red per Book) into one table + /tmp/Story_cli/_fleet.json.
//
//   node scripts/Story_cli_sweep.mjs                 # every Book under wormhole/Story/
//   node scripts/Story_cli_sweep.mjs PortPlanet Mundane*   # an explicit list (globs ok)
//   ACCEPT=1 node scripts/Story_cli_sweep.mjs        # re-record sweep (rewrites fixtures)
//
// Each Book runs in its OWN fresh vitest process (the forks design — clean House
//  singletons per Book); the runner writes /tmp/Story_cli/<Book>/run.json, which we
//   read back. Cold ≈ 20-40s/Book, so a full sweep is minutes; narrow the list while
//    iterating. Verdict: green = every step matches, amber = ran but surprises, red =
//     never produced a run.json (boot/drive failure).
import { spawnSync } from 'node:child_process'
import { readFileSync, readdirSync, existsSync } from 'node:fs'
import path from 'node:path'

const ROOT = process.cwd()
const CFG  = 'scripts/Story_cli.vitest.config.mjs'
const SPEC = 'scripts/Story_cli.spec.ts'

const all_books = () => readdirSync(path.join(ROOT, 'wormhole/Story'), { withFileTypes: true })
    .filter(d => d.isDirectory() && existsSync(path.join(ROOT, 'wormhole/Story', d.name, 'toc.snap')))
    .map(d => d.name).sort()

// args may be exact names or simple `*` globs
const argv  = process.argv.slice(2)
const pool  = all_books()
const books = !argv.length ? pool : argv.flatMap(a => {
    if (!a.includes('*')) return [a]
    const re = new RegExp('^' + a.replace(/[.+?^${}()|[\]\\]/g, '\\$&').replace(/\*/g, '.*') + '$')
    return pool.filter(b => re.test(b))
})

const rows = []
for (const book of books) {
    process.stdout.write(`▶ ${book} … `)
    const r = spawnSync(path.join(ROOT, 'node_modules/.bin/vitest'),
        ['run', '-c', CFG, SPEC],
        { env: { ...process.env, BOOK: book }, cwd: ROOT, encoding: 'utf8', timeout: 240_000 })
    let summary = null
    try { summary = JSON.parse(readFileSync(path.join('/tmp/Story_cli', book, 'run.json'), 'utf8')) } catch {}
    if (!summary || !summary.steps?.length) {
        rows.push({ book, verdict: 'red', captured: 0, matched: 0, surprises: [] })
        console.log(`🔴 no run.json (exit ${r.status})`)
        continue
    }
    const matched   = summary.steps.filter(s => s.match).length
    const surprises = summary.surprises ?? []
    const verdict   = surprises.length === 0 && matched === summary.steps.length ? 'green' : 'amber'
    rows.push({ book, verdict, captured: summary.steps.length, matched, surprises, mode: summary.mode })
    console.log(`${verdict === 'green' ? '🟢' : '🟡'} ${matched}/${summary.steps.length}${surprises.length ? `  surprises [${surprises.join(',')}]` : ''}`)
}

const tally = v => rows.filter(r => r.verdict === v).length
console.log(`\n── fleet: 🟢 ${tally('green')}  🟡 ${tally('amber')}  🔴 ${tally('red')}  (${rows.length} books) ──`)
for (const r of rows.filter(r => r.verdict !== 'green'))
    console.log(`  ${r.verdict === 'red' ? '🔴' : '🟡'} ${r.book}: ${r.matched}/${r.captured}${r.surprises.length ? ` surprises [${r.surprises.join(',')}]` : ''}`)

import { writeFileSync } from 'node:fs'
writeFileSync('/tmp/Story_cli/_fleet.json', JSON.stringify({ books: rows.length, ...{ green: tally('green'), amber: tally('amber'), red: tally('red') }, rows }, null, 2))
console.log(`\nfleet report → /tmp/Story_cli/_fleet.json`)
process.exit(0)
