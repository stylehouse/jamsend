// vyto_code_sketch.mjs — the CODE as a sketch for the glass: `static/vyto/code_sketch.json`, read by Book VytoCodeCave.
//   node scripts/vyto_code_sketch.mjs
//  The owner, 2026-10-04: *"we have a bit of a problem how the data is so fake... probably use it to explore code so we
//   have our words in it"*.  Levels, each a HOLE to descend into (Vytui's `descend` stop): folder (M, S, N, V, Story…)
//    → ghost (one .g) → its `//#region`s → their methods.  Facts are true things about the code, so the vines between
//     them say something: `leans_on` = the OTHER ghost a thing calls most (two things that lean on the same ghost get a
//      string of cheese between them).  Sizes (`dose`) grow with how much a thing holds.  Words are the code's own:
//       region titles, method names.  Regenerate whenever the code moves — it is a snapshot, not a mirror.
import fs from 'node:fs'
import path from 'node:path'
const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..')
const files = []
const walk = d => { for (const e of fs.readdirSync(d, { withFileTypes: true })) { const p = path.join(d, e.name); if (e.isDirectory()) { if (!/^(test|wormhole-Ghost)$/.test(e.name)) walk(p) } else if (p.endsWith('.g')) files.push(p) } }
walk(path.join(ROOT, 'Ghost'))
const DEF = /^(async\s+)?([A-Za-z_]\w*)\s*\([^)]*\)\s*:\s*$/
// pass 1: every def → its file, region, calls
const defs = {}
const ghosts = {}
for (const f of files) {
    const rel = path.relative(path.join(ROOT, 'Ghost'), f).replace(/\.g$/, '')
    const lines = fs.readFileSync(f, 'utf8').split('\n')
    let region = '(top)', cur = null
    const g = ghosts[rel] = { rel, lines: lines.length, regions: {} }
    for (let i = 0; i < lines.length; i++) {
        const L = lines[i]
        const rm = L.match(/^\/\/#region\s+(.*)$/)
        if (rm) { region = rm[1].split(/\s+[—–-]\s+/)[0].trim().slice(0, 40) || 'region'; continue }
        if (/^\/\/#endregion/.test(L)) { region = '(top)'; continue }
        const m = L.match(DEF)
        if (m) { cur = m[2]; defs[cur] ||= { ghost: rel, region, calls: {}, line: i + 1 }; (g.regions[region] ||= []).push(cur); continue }
        if (!cur || /^\s*\/\//.test(L)) continue
        for (const c of L.matchAll(/this\.([A-Za-z_]\w*)\s*\(/g)) defs[cur].calls[c[1]] = (defs[cur].calls[c[1]] || 0) + 1
        for (const c of L.matchAll(/&([A-Za-z_]\w*)\s*,/g)) defs[cur].calls[c[1]] = (defs[cur].calls[c[1]] || 0) + 1
    }
}
// the OTHER ghost a set of methods calls most
const leans = (methods, self) => {
    const n = {}
    for (const m of methods) for (const [k, c] of Object.entries(defs[m]?.calls ?? {})) { const og = defs[k]?.ghost; if (og && og !== self) n[og] = (n[og] || 0) + c }
    const best = Object.entries(n).sort((a, b) => b[1] - a[1])[0]
    return best ? best[0].split('/').pop() : null
}
const dose = n => Math.max(1, Math.round(Math.sqrt(n)))
const fact = (o, k, v) => { if (v != null && v !== '') o[k] = v; return o }
// pass 2: the tree
const folders = {}
for (const g of Object.values(ghosts)) (folders[g.rel.includes('/') ? g.rel.split('/')[0] : '.'] ||= []).push(g)
const items = []
for (const [fname, gs] of Object.entries(folders).sort()) {
    const gitems = []
    for (const g of gs.sort((a, b) => a.rel < b.rel ? -1 : 1)) {
        const all = Object.values(g.regions).flat()
        if (!all.length) continue
        // NO REGIONS ⇒ GROUP BY NAME: a ghost with only "(top)" would make a pointless middle level (one hole holding
        //  everything — VytoTesting is ~600 methods).  Its methods group by their name's prefix instead — in these files
        //   that is the Book or the organ (`VytoSketch_*`, `Radio_*`) — and a group of one stays a bare method.
        if (Object.keys(g.regions).length === 1) {
            const by = {}
            for (const m of all) { const pre = m.includes('_') ? m.split('_')[0] : m; (by[pre] ||= []).push(m) }
            if (Object.keys(by).length >= 2) {
                g.regions = {}
                for (const [pre, ms] of Object.entries(by)) (g.regions[ms.length > 1 ? pre : '(loose)'] ||= []).push(...ms)
            }
        }
        const ritems = []
        for (const [rname, ms] of Object.entries(g.regions)) {
            // `part` — the organ a method belongs to, read off its own name (`Vyto_fold_scope` → fold): a fact EVERY method
            //  carries, so a crowded region folds into crests by part instead of piling into labels
            const part = m => { const s = m.replace(/^e_/, '').split('_'); return s.length > 2 ? s[1] : s.length === 2 ? s[1].replace(/[A-Z].*$/, '') || 'self' : 'self' }
            const mitems = ms.map(m => fact(fact({ Method: m }, 'part', part(m)), 'leans_on', leans([m], g.rel)))
                .map((o, i) => (o.guise = { tok: `code:${g.rel}#${rname}.${ms[i]}`, dose: dose(Object.keys(defs[ms[i]].calls).length + 1) }, o))
            ritems.push(fact({ Region: rname }, 'leans_on', leans(ms, g.rel)))
            ritems[ritems.length - 1].guise = { tok: `code:${g.rel}#${rname}`, dose: dose(ms.length), kids: mitems }
        }
        const gi = fact({ Ghost: g.rel.split('/').pop() }, 'leans_on', leans(all, g.rel))
        gi.guise = { tok: `code:${g.rel}`, dose: dose(all.length / 4 + 1), kids: ritems }
        gitems.push(gi)
    }
    if (!gitems.length) continue
    items.push({ Folder: fname, guise: { tok: `code:${fname}`, dose: dose(gitems.length * 3), kids: gitems } })
}
const out = {
    about: 'THE CODE AS A CAVE — generated by scripts/vyto_code_sketch.mjs from Ghost/**/*.g: folder → ghost → region → method, each a hole to descend into; `leans_on` is the other ghost a thing calls most, so things leaning on the same ghost are tied by a vine.  Regenerate when the code moves.',
    name: 'the code',
    // budget:16 — a crowded level ("the organs" holds 68 methods) FOLDS into crests by what its methods lean on,
    //  instead of piling 68 cells into labels
    deck: 'grid,descend,budget:16',
    folded: 1,
    landscape_at: { x: 880, y: 160 },
    generated: new Date().toISOString().slice(0, 10),
    items,
}
const dest = path.join(ROOT, 'static/vyto/code_sketch.json')
fs.writeFileSync(dest, JSON.stringify(out))
const n = Object.keys(defs).length
console.log(`${path.relative(ROOT, dest)} — ${items.length} folders · ${Object.values(folders).flat().length} ghosts · ${Object.values(ghosts).reduce((s, g) => s + Object.keys(g.regions).length, 0)} regions · ${n} methods · ${(fs.statSync(dest).size / 1024).toFixed(0)}KB`)
