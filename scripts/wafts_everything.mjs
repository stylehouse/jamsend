// wafts_everything.mjs — THE FLOOR's host for the program map (src/lib/L/everything.js holds the map and the emitter).
//  The same map also runs as the `everything` verb on an editor terminal (spec/Verbs_todo.md §3.3); this script is the
//   floor — node + fs, no tab needed — so the map can always be rebuilt even with the app down.
//  Usage: node scripts/wafts_everything.mjs        (writes wormhole/Ghost/*/toc.snap, Everything included)
//  The editor keeps these Wafts open and saves them back on a version bump — reload it after a run.
//  Policy for what goes in lives in Waft:Everything itself (What:the policy).
import fs from 'node:fs'
import path from 'node:path'
import { everything_map, everything_build, COVER_ROOTS } from '../src/lib/L/everything.js'
const ROOT = path.resolve(new URL('..', import.meta.url).pathname)

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
}

const { out, problems, coverage, files } = await everything_build(everything_map(), host)
console.log(`coverage: ${coverage.cited} of ${coverage.total} source files cited by an area — ${coverage.unsorted} unsorted across ${coverage.dirs} directories — ${coverage.grounds} Grounds — ${coverage.groundless} .g in none`)
for (const p of problems) console.log('✗ ' + p)
if (problems.length) { console.log(`${problems.length} problem(s) — nothing written`); process.exit(1) }
for (const [name, text] of out) {
    const dir = `${ROOT}/wormhole/${name}`
    fs.mkdirSync(dir, { recursive: true })
    fs.writeFileSync(`${dir}/toc.snap`, text)
    console.log(`✓ wormhole/${name}/toc.snap  ${text.split('\n').length - 1} lines`)
}
// the baked Ground manifest (src/lib/A/grounds.gen.js) — written only when it changed, so Vite reloads nothing for nothing
for (const [p, text] of files) {
    const at = ROOT + '/' + p
    if (fs.existsSync(at) && fs.readFileSync(at, 'utf8') === text) { console.log(`= ${p}  unchanged`); continue }
    fs.writeFileSync(at, text)
    console.log(`✓ ${p}`)
}
