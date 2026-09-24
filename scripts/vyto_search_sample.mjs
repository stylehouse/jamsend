// vyto_search_sample.mjs — real code-search result sets (→ static/vyto/*.json, fetched by the page) for the Vyto glass to be designed against.
//  Greps Ghost/**/*.g for a few queries and writes them in the Searchbar's own hit shape
//   ({path, line, name, glyph}; glyph ƒ def · % particle · ¶ mention — Searchbar.svelte:103-110), so a
//    Book can stand a result set that looks exactly like what the live search hands over, without the
//     Book needing disk or a warm Stemdex.  Each hit also carries `m` — its ENCLOSING METHOD (the last
//      column-0 `Name(args):` above it) — which is the code's own anatomy the cave expedition walks.
//  A second file, search_anatomy.json, carries each touched file's method list and the source lines
//   of every method that holds a hit (capped), so the deepest chamber can show the code itself.  The dev
//    server refuses raw .g reads (403), so the page cannot fetch them; this is the stand-in until the
//     live Searchbar + a source route are wired.
//  Re-run to refresh:  node scripts/vyto_search_sample.mjs
import { execSync } from 'node:child_process'
import fs from 'node:fs'

const QUERIES = ['Crew', 'Door', 'Heist']
const MAX_LINES = 40, MAX_COL = 84
const DEF = /^(?:async\s+)?([A-Za-z_]\w*)\([^)]*\):\s*$/
const anatomyOf = new Map()     // path -> { methods: [{name,a,b}], src: string[] }
function anatomy(path) {
    if (anatomyOf.has(path)) return anatomyOf.get(path)
    const src = fs.readFileSync(path, 'utf8').split('\n')
    const methods = []
    const regions = []
    src.forEach((ln, i) => {
        const d = ln.match(DEF); if (d) methods.push({ name: d[1], a: i + 1, b: src.length })
        const r = ln.match(/^\s*\/\/#region\s*(.*)$/)
        if (r) regions.push({ name: r[1].split(/ — | - |: |\(/)[0].trim().slice(0, 40) || 'region', a: i + 1 })
    })
    for (let k = 0; k < methods.length - 1; k++) methods[k].b = methods[k + 1].a - 1
    const an = { methods, regions, src }
    anatomyOf.set(path, an)
    return an
}
// the REGION a line sits in — the file's own `//#region` markers; a file with none groups by the method
//  name's prefix before its first underscore (in a *Testing.g file that prefix IS the Book)
function region_at(an, line, mname) {
    let r = null
    for (const x of an.regions) { if (x.a <= line) r = x; else break }
    if (r) return r.name
    if (!an.regions.length && mname) return mname.split('_')[0]
    return '(top)'
}
function method_at(an, line) {
    let m = null
    for (const x of an.methods) { if (x.a <= line) m = x; else break }
    return m
}

const out = {}
const touched = new Map()       // path -> Set(method name)
for (const q of QUERIES) {
    const raw = execSync(`grep -rn --include=*.g ${JSON.stringify(q)} Ghost`, { encoding: 'utf8', maxBuffer: 1 << 26 })
    const hits = []
    for (const ln of raw.split('\n')) {
        const mm = ln.match(/^([^:]+):(\d+):(.*)$/)
        if (!mm) continue
        const [, path, line, text] = mm
        const t = text.trim()
        const def = t.match(DEF)
        let glyph = '¶', name = t.length > 60 ? t.slice(0, 59) + '…' : t
        if (def && def[1].includes(q)) { glyph = 'ƒ'; name = def[1] }
        else if (new RegExp(`%${q}\\b|\\{\\s*${q}\\s*:`).test(t)) glyph = '%'
        const an = anatomy(path)
        const m = method_at(an, +line)
        const h = { path, line: +line, name, glyph, m: m ? m.name : '(top)', r: region_at(an, +line, m ? m.name : null) }
        hits.push(h)
        if (!touched.has(path)) touched.set(path, new Set())
        touched.get(path).add(h.m)
    }
    hits.sort((a, b) => a.path < b.path ? -1 : a.path > b.path ? 1 : a.line - b.line)
    out[q] = hits
}
const ANAT = {}
for (const [path, names] of touched) {
    const an = anatomy(path)
    const lines = {}
    for (const x of an.methods) {
        if (!names.has(x.name)) continue
        lines[x.name] = { a: x.a, src: an.src.slice(x.a - 1, Math.min(x.b, x.a - 1 + MAX_LINES)).map(l => l.length > MAX_COL ? l.slice(0, MAX_COL - 1) + '…' : l) }
    }
    ANAT[path] = { methods: an.methods.map(x => [x.name, x.a, x.b]), lines }
}
// served from static/ and FETCHED lazily (a module import would ride every runner boot through
//  VytoTesting's import graph — a quarter-megabyte of sample on every page that never shows a spine)
fs.mkdirSync('static/vyto', { recursive: true })
fs.writeFileSync('static/vyto/search_sample.json', JSON.stringify(out))
fs.writeFileSync('static/vyto/search_anatomy.json', JSON.stringify(ANAT))
for (const q of QUERIES) console.log(q, out[q].length, 'hits', new Set(out[q].map(h => h.path)).size, 'files', new Set(out[q].map(h => h.path + h.m)).size, 'methods')
console.log('anatomy bytes', fs.statSync('static/vyto/search_anatomy.json').size, 'sample bytes', fs.statSync('static/vyto/search_sample.json').size)
