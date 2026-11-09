// wafts_everything.mjs — THE FLOOR's host for the program map's keeper (src/lib/L/wafts_keep.js).
//  The map is the hand-kept tocs (Waft:Everything + the area Wafts it points at); this reads them, validates every row, and
//   regenerates only what is derived: Waft:Ghost/Rest/Unsorted, Everything's counted Whats, the tagged Ground tocs, grounds.gen.js.
//  The same keeper runs as the `everything` verb on an editor terminal (spec/Verbs_todo.md §3.3); this script is the floor —
//   node + fs, no tab needed — so the map can always be checked even with the app down.
//  Usage: node scripts/wafts_everything.mjs           (check, then write the derived tocs)
//         node scripts/wafts_everything.mjs --check   (check only — writes nothing)
//  The editor keeps Wafts open and saves them back on a version bump — run this with no editor tab up, or reload it after.
import fs from 'node:fs'
import path from 'node:path'
import { wafts_read, wafts_build, COVER_ROOTS, EVERYTHING } from '../src/lib/L/wafts_keep.js'
const ROOT = path.resolve(new URL('..', import.meta.url).pathname)
const check = process.argv.includes('--check')

const host = {
    files: () => {
        const out = []
        const walk = (d) => {
            for (const e of fs.readdirSync(ROOT + '/' + d, { withFileTypes: true })) {
                const rel = d + '/' + e.name
                if (e.isDirectory()) { if (!/(^|\/)(node_modules|gen|history|shelved|ulative)$/.test(rel)) walk(rel) }
                else out.push(rel)
            }
        }
        for (const r of COVER_ROOTS) walk(r)
        return out
    },
    exists: (p) => fs.existsSync(ROOT + '/' + p),
    text:   (p) => fs.readFileSync(ROOT + '/' + p, 'utf8'),
    // a Book is its toc — a directory holding only Credulate leftovers is a retired Book's husk
    book:   (b) => fs.existsSync(`${ROOT}/wormhole/Story/${b}/toc.snap`),
    toc:    (k) => { const p = `${ROOT}/wormhole/${k}/toc.snap`; return fs.existsSync(p) ? fs.readFileSync(p, 'utf8') : null },
}

const read = await wafts_read(host)
const { out, problems, coverage, files } = await wafts_build(read.W, host)
problems.unshift(...read.problems)
console.log(`coverage: ${coverage.cited} of ${coverage.total} source files cited by an area — ${coverage.unsorted} unsorted across ${coverage.dirs} directories — ${coverage.grounds} Grounds — ${coverage.groundless} .g in none`)
for (const p of problems) console.log('✗ ' + p)
if (problems.length) { console.log(`${problems.length} problem(s) — nothing written`); process.exit(1) }
// write only what changed — an authored Waft comes back byte-identical unless the map's own rows moved, and an untouched toc
//  never wakes a watcher.  Everything is written too: its counted Whats are derived.
for (const [name, text] of out) {
    const at = `${ROOT}/wormhole/${name}/toc.snap`
    if (fs.existsSync(at) && fs.readFileSync(at, 'utf8') === text) continue
    if (check) { console.log(`~ wormhole/${name}/toc.snap  would change`); continue }
    fs.mkdirSync(path.dirname(at), { recursive: true })
    fs.writeFileSync(at, text)
    console.log(`✓ wormhole/${name}/toc.snap  ${text.split('\n').length - 1} lines`)
}
// the baked Ground manifest (src/lib/A/grounds.gen.js) — written only when it changed, so Vite reloads nothing for nothing
for (const [p, text] of files) {
    const at = ROOT + '/' + p
    if (fs.existsSync(at) && fs.readFileSync(at, 'utf8') === text) continue
    if (check) { console.log(`~ ${p}  would change`); continue }
    fs.writeFileSync(at, text)
    console.log(`✓ ${p}`)
}
console.log(check ? `checked — ${EVERYTHING} and its areas are sound` : 'done')
