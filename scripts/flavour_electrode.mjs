// flavour_electrode.mjs — build the ELECTRODE FLAVOUR of some Grounds: each Load: .g's plain src/lib/gen/<X>.go, rewritten by
//  src/lib/L/flavour_electrode.ts (the caller survives an await) into src/lib/gen-electrode/<X>.go.  A pass over the PLAIN build,
//   so it needs no .g compiler and no tab: compile the .g as usual first, then flavour.  gen-electrode/ is gitignored — a measuring
//    build, rebuilt on demand (spec/Electrode_todo.md §0, Ground/Hacky/*).  Writes only what changed.
//
//  Usage: node scripts/flavour_electrode.mjs Land Cave        (the Grounds' own Load: rows — not what they stand on)
//         node scripts/flavour_electrode.mjs Ghost/M/Heist.g  (one file)
//         node scripts/flavour_electrode.mjs --hacky          (every Ground/Hacky/* twin's rows — what a measuring sweep stands)
//         … --check                                           (say what would change, write nothing)
import fs from 'node:fs'
import path from 'node:path'
import { GROUNDS } from '../src/lib/A/grounds.gen.js'
import { flavour_electrode_go, flavour_electrode_path } from '../src/lib/L/flavour_electrode.ts'

const ROOT = path.resolve(new URL('..', import.meta.url).pathname)
const args = process.argv.slice(2)
const check = args.includes('--check')
const names = args.filter(a => !a.startsWith('--'))
if (args.includes('--hacky')) for (const [n, G] of Object.entries(GROUNDS)) if (G.flavour === 'electrode') names.push(n)
if (!names.length) { console.error('usage: node scripts/flavour_electrode.mjs <Ground|Ghost/X/Y.g> … [--check]'); process.exit(2) }

// the plain build's path, as Lies_gen_path makes it (LiesCortex): Ghost/X/Y.g → gen/X/Y.go
const gen_of = (g) => g.replace(/^.*Ghost\//, 'gen/').replace(/\.g$/, '.go')
const files = []
for (const n of names) {
    if (n.endsWith('.g')) { files.push(n); continue }
    const G = GROUNDS[n]
    if (!G) { console.error(`✗ no Ground/${n} in src/lib/A/grounds.gen.js`); process.exit(1) }
    for (const p of G.load) if (p.endsWith('.g') && !files.includes(p)) files.push(p)
}
let wrote = 0, same = 0, bad = 0
for (const g of files) {
    const gen = gen_of(g)
    const from = path.join(ROOT, 'src/lib', gen)
    if (!fs.existsSync(from)) { console.log(`✗ ${g} — no ${gen} (compile it first)`); bad++; continue }
    let out
    try { out = flavour_electrode_go(fs.readFileSync(from, 'utf8')) } catch (e) { console.log(`✗ ${g} — ${e.message}`); bad++; continue }
    const to = path.join(ROOT, 'src/lib', flavour_electrode_path(gen))
    if (fs.existsSync(to) && fs.readFileSync(to, 'utf8') === out.source) { same++; continue }
    if (check) { console.log(`~ ${flavour_electrode_path(gen)} would change (${out.fns} async fns, ${out.awaits} awaits)`); continue }
    fs.mkdirSync(path.dirname(to), { recursive: true })
    fs.writeFileSync(to, out.source)
    wrote++
    console.log(`✓ ${flavour_electrode_path(gen)}  ${out.fns} async fns, ${out.awaits} awaits`)
}
console.log(`${files.length} .g: ${wrote} written · ${same} unchanged · ${bad} refused`)
process.exit(bad ? 1 : 0)
