// wafts_keep.js — THE PROGRAM MAP'S KEEPER (2026-11-09: src/lib/L/everything.js sublated — owner 2026-10-29 "everything.js is silly").
//
//  The map is no longer code.  Waft:Everything (wormhole/Ghost/Everything/toc.snap) and the area Wafts it points at
//   (FromWhat:Waft:<key> — Ghost/Net/Easy, Ghost/Swarm/Easy, …) are HAND-KEPT tocs, like wormhole/Credence: what each area is, its
//    Whats, its main Points with keywords, its Books (Funkcion:Storying,of_Book:…), and the Ground tags (,ground:X,stands:Y on an
//     Everything What, or on an inner What).  Edit them in the editor or by hand.
//  This module READS them back (wafts_read), VALIDATES every row before a byte is written (every Doc must exist, every Point must be
//   a def in its doc, no commas in a desc, every Book must exist), and REGENERATES only what is derived:
//    · Waft:Ghost/Rest/Unsorted — every source file no area cites, by directory (the map's debt)
//    · on Waft:Everything, the two counted Whats (the unsorted · the groundless) and the policy's two counted rules
//    · wormhole/Ground/<Name>/toc.snap for every TAGGED Ground, and src/lib/A/grounds.gen.js (the baked manifest)
//    · wormhole/Ground/Hacky/<Name>/toc.snap — every tagged Ground's MEASURING twin (below, HACKY_PLAIN)
//   A hand-kept Ground nobody tags (Ground/Radio · Runner · Pile) is never touched.
//  Two hosts, as before: scripts/wafts_everything.mjs (the floor — node + fs, no tab) and the `everything` verb (Ghost/L/Lagoon.g, the
//   editor terminal).  A host is { files(), exists(p), text(p), book(name), toc(key) → text|null } — all may be async.

export const COVER_ROOTS = ['Ghost', 'src']
export const COVER_EXT   = /\.(g|svelte|ts|md)$/
// the same archive rule Atlas's census keeps (ATLAS_SKIP: gen · history · shelved …) — the two hosts must count the same tree
export const COVER_SKIP  = /(^|\/)(node_modules|gen|history|shelved|ulative)(\/|$)/
export const UNSORTED    = 'Ghost/Rest/Unsorted'
// the front door's own key — it lives beside the area Wafts it maps, as ./Ghost/ holds the .g (owner, 2026-10-21)
export const EVERYTHING  = 'Ghost/Everything'
// what wafts_build adds to Everything on every run — stripped on read so a re-run never doubles them
// THE HACKY TWINS (owner 2026-11-09, spec/Electrode_todo.md §0).  Every tagged Ground gets a twin, Ground/Hacky/<Name>: the same Load:
//  rows (sources, repo-root paths — the loader derives which build), plus `Flavour:electrode`, so the floor loads each from
//   src/lib/gen-electrode/ (scripts/flavour_electrode.mjs builds it) and the call tap keeps its caller across an await.  A twin
//    stands on the twins of what its Ground stands on, and on the plain Ground where there is no twin.  These stay PLAIN — the
//     machinery under everything, which a Book is not about and which would only flood the measure — and Story, the runner's own
//      drive: a flavoured StoryFu would be eaten over the one running the Book.  ⚠ Loading ANY flavour over a live plain ghost is
//       --swap's road, with its hazard: module-level state (a `const` Map at the top of a .go) is a second copy in the flavoured
//        module, so old and new methods can disagree about it until the reload the sweep ends with.
export const HACKY_PLAIN  = new Set(['Core', 'Glass', 'Story'])
export const HACKY       = 'Hacky'
export const FLAVOUR_ELECTRODE = 'electrode'
export function hacky_twins(list) {
    const twin = (n) => HACKY_PLAIN.has(n) ? n : `${HACKY}/${n}`
    return list.filter(g => !HACKY_PLAIN.has(g.name)).map(g => ({
        name: twin(g.name), of: g.name, flavour: FLAVOUR_ELECTRODE,
        desc: `Ground/${g.name} built to be measured — the caller survives an await`,
        stands: new Set([...g.stands].map(twin)), load: g.load, beside: [], advice: [],
    }))
}
const DERIVED_WHATS = ['What:the unsorted', 'What:the groundless', 'What:every file has a home', 'What:every .g has a Ground']

// wafts_parse — one Waft toc back into the map's node shape: [key, desc, [Book…], [What-node…]], a What-node being
//  [head, desc?, 'FromWhat:…'?, 'Ground:X'?, 'Stands:Y'…, then 'Doc:p' | 'Point:m|d' | What-node children in order].
//   Rows split on commas — safe because the map's own law is no comma in a desc (validated on every build).
export function wafts_parse(text) {
    const rows = String(text || '').split('\n').filter(l => l.trim()).map(l => {
        const depth = (l.length - l.trimStart().length) / 2
        const segs = l.trim().split(',')
        const kv = {}
        for (const s of segs.slice(1)) { const i = s.indexOf(':'); if (i > 0) kv[s.slice(0, i)] = s.slice(i + 1) }
        return { depth, head: segs[0], kv }
    })
    if (!rows.length || !rows[0].head.startsWith('Waft:')) return null
    const key = rows[0].head.slice(5)
    const books = []
    const tree = []
    const stack = [{ depth: 0, node: null }]
    for (const r of rows.slice(1)) {
        if (r.head === 'Funkcion:CreduFunk') continue
        if (r.head === 'Funkcion:Storying') { if (r.kv.of_Book) books.push(r.kv.of_Book); continue }
        while (stack.length > 1 && stack[stack.length - 1].depth >= r.depth) stack.pop()
        const parent = stack[stack.length - 1].node
        if (r.head.startsWith('What:')) {
            const node = [r.head]
            if (r.kv.desc) node.push(r.kv.desc)
            if (r.kv.FromWhat) node.push('FromWhat:' + r.kv.FromWhat)
            if (r.kv.ground) node.push('Ground:' + r.kv.ground)
            for (const s of (r.kv.stands ? r.kv.stands.split('|') : [])) node.push('Stands:' + s)
            if (DERIVED_WHATS.includes(r.head)) { stack.push({ depth: r.depth, node: [] }); continue }
            ;(parent ?? tree).push(node)
            stack.push({ depth: r.depth, node })
        } else if (parent) {
            if (r.head.startsWith('Doc:')) parent.push(r.head)
            else if (r.head === 'Point') parent.push(`Point:${r.kv.method}|${r.kv.desc ?? ''}`)
        }
    }
    return [key, rows[0].kv.desc ?? '', books, tree]
}

// wafts_read — the map as it stands on disk: every area Waft Everything points at (in its order — a .g's Ground is the FIRST that
//  cites it), then Everything itself.  Credence and the Unsorted are pointed at but not part of the map.  Returns { W, problems }.
export async function wafts_read(host) {
    const problems = []
    const every = wafts_parse(await host.toc(EVERYTHING))
    if (!every) return { W: [], problems: [`no ${EVERYTHING} toc`] }
    const W = []
    for (const what of every[3]) {
        const from = what.find(c => typeof c === 'string' && c.startsWith('FromWhat:Waft:'))
        const key = from ? from.slice(14) : null
        if (!key || key === UNSORTED || key === 'Credence') continue
        const area = wafts_parse(await host.toc(key))
        if (!area) { problems.push(`${EVERYTHING}: ${what[0]} points at Waft:${key} — no toc`); continue }
        W.push(area)
    }
    W.push(every)
    return { W, problems }
}

// coverage + validate + emit.  Returns { out: [[waftKey, tocText]], problems: [msg], coverage }.  Writes nothing.
export async function wafts_build(W, host) {
    const problems = []
    // ── COVERAGE — every source file has a home (2026-10-08, the owner: "do we ensure everything in src/ and Ghost/ is in
    //  Everything? that'd be good").  It did not: 186 of 415 source files were cited anywhere.  Placing a file in an AREA is
    //   curation (the policy: one area per ghost, split past ~150 lines), so this does not guess — every file no Waft cites
    //    goes into one generated Waft, grouped by directory, and Everything cites it WITH THE COUNT.
    const cited = new Set()
    const scan = (node) => { for (const c of node) { if (Array.isArray(c)) scan(c); else if (typeof c === 'string' && c.startsWith('Doc:')) cited.add(c.slice(4)) } }
    for (const [, , , tree] of W) for (const w of tree) scan(w)
    const files = (await host.files()).filter(f => COVER_EXT.test(f) && !COVER_SKIP.test(f)).sort()
    const rest = files.filter(f => !cited.has(f))
    const byDir = new Map()
    for (const f of rest) { const d = f.slice(0, f.lastIndexOf('/')); if (!byDir.has(d)) byDir.set(d, []); byDir.get(d).push(f) }
    W.push([UNSORTED, `every source file no area Waft cites yet — ${rest.length} of ${files.length} — one What per directory — give each a home in its area and re-run`, [],
        [...byDir].map(([d, fs_]) => [`What:${d}`, `${fs_.length} file${fs_.length === 1 ? '' : 's'} with no area`, ...fs_.map(f => 'Doc:' + f)])])
    const every = W.find(w => w[0] === EVERYTHING)
    const at = every[3].findIndex(w => w[0] === 'What:the policy')
    every[3].splice(at, 0, ['What:the unsorted', `${UNSORTED} — ${rest.length} of ${files.length} source files no area claims yet — by directory — the debt of this map`, `FromWhat:Waft:${UNSORTED}`])
    const pol = every[3].find(w => w[0] === 'What:the policy')
    pol.push(['What:every file has a home', `every source file under ${COVER_ROOTS.join(' and ')} is cited by an area Waft or sits in the unsorted Waft — re-running this map recounts it`])
    const coverage = { cited: files.length - rest.length, total: files.length, unsorted: rest.length, dirs: byDir.size }

    // ── GROUNDS — the tags on Waft:Everything become bundles (spec/Aprac_todo.md §0.5) ──
    const grounds = grounds_derive(W, files, problems)
    const groundless = files.filter(f => /\.g$/.test(f) && !grounds.home.has(f))
    every[3].splice(every[3].findIndex(w => w[0] === 'What:the policy'), 0,
        ['What:the groundless', `${groundless.length} .g in no Ground — nothing loads them by recipe — tag their area on this Waft`, ...groundless.map(f => 'Doc:' + f)])
    pol.push(['What:every .g has a Ground', 'an area What here wears ground:<Name> — its Waft becomes Ground/<Name> — an inner What may wear its own — a .g lives in the first Ground that cites it and a Ground citing another Ground .g stands on it — *Testing.g and every .g under a What:the tests go to <Name>Testing — Core is under everything and never said'])
    coverage.grounds = grounds.list.length
    coverage.groundless = groundless.length

    // ── validate + emit ──
    const defs = new Map()
    const defsOf = async (p) => {
        if (!defs.has(p)) {
            const s = String((await host.text(p)) ?? '')
            const set = new Set()
            for (const m of s.matchAll(/^\s*(?:export\s+)?(?:async\s+)?(?:function\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*\(/gm)) set.add(m[1])
            for (const m of s.matchAll(/^\s*(?:export\s+)?(?:const|let)\s+([A-Za-z_][A-Za-z0-9_]*)\s*=/gm)) set.add(m[1])
            defs.set(p, set)
        }
        return defs.get(p)
    }
    const out = []
    for (const [name, wdesc, books, tree] of W) {
        const lines = [`Waft:${name}${wdesc ? ',desc:' + wdesc : ''}`]
        if (books.length) lines.push(`  Funkcion:CreduFunk`)
        for (const b of books) {
            if (!(await host.book(b))) problems.push(`${name}: no Book ${b}`)
            lines.push(`    Funkcion:Storying,of_Book:${b}`)
        }
        const emit = async (node, depth) => {
            const pad = '  '.repeat(depth)
            let lastDoc = null
            const [head, ...rest_] = node
            const desc = (typeof rest_[0] === 'string' && !MARK_RE.test(rest_[0])) ? rest_.shift() : null
            const from = (typeof rest_[0] === 'string' && rest_[0].startsWith('FromWhat:')) ? rest_.shift().slice(9) : null
            const m = ground_marks(node)
            if (/,/.test(desc || '') || /,/.test(head)) problems.push(`${name}: comma in ${head}`)
            lines.push(`${pad}${head}${desc ? ',desc:' + desc : ''}${from ? ',FromWhat:' + from : ''}${m.ground ? ',ground:' + m.ground : ''}${m.stands.length ? ',stands:' + m.stands.join('|') : ''}`)
            for (const c of rest_) {
                if (Array.isArray(c)) { await emit(c, depth + 1); continue }
                if (/^(Ground|Stands):/.test(c)) continue
                if (c.startsWith('Doc:')) {
                    lastDoc = c.slice(4)
                    if (!(await host.exists(lastDoc))) problems.push(`${name}: missing ${lastDoc}`)
                    lines.push(`${pad}  ${c}`)
                } else if (c.startsWith('Point:')) {
                    const [m, d] = c.slice(6).split('|')
                    if (!lastDoc || !(await defsOf(lastDoc)).has(m)) problems.push(`${name}: ${lastDoc} has no def ${m}`)
                    if (/,/.test(d || '')) problems.push(`${name}: comma in desc of ${m}`)
                    lines.push(`${pad}  Point,method:${m}${d ? ',desc:' + d : ''}`)
                }
            }
        }
        for (const w of tree) await emit(w, 1)
        out.push([name, lines.join('\n') + '\n'])
    }
    const twins = hacky_twins(grounds.list)
    for (const g of [...grounds.list, ...twins]) out.push(['Ground/' + g.name, ground_toc(g)])
    return { out, problems, coverage, files: [[GROUND_MANIFEST, ground_manifest([...grounds.list, ...twins])]] }
}

// ── GROUNDS ─────────────────────────────────────────────────────────────────────────────────────────────────────────────
//  A Ground is a list of .g a tab loads to stand some work (spec/Aprac_todo.md §0.5).  It is not authored: Waft:Everything's
//   area Whats wear 'Ground:<Name>' (and 'Stands:<Name>' when it needs a Ground it doesn't cite), an inner What in an area
//    Waft may wear its own, and this derives the bundles.  No diges in a Ground — Credulate keeps each .g's dige.
//  Rules: a .g's HOME is the first Ground that cites it (map order); a Ground that cites another's .g stands on that one;
//   a *Testing.g (or any .g under a What:the tests) goes to <Name>Testing, which stands on <Name>; Core is under every Ground and is never written as a stand.
//  Out: wormhole/Ground/<Name>/toc.snap (the readable recipe) and GROUND_MANIFEST (the same, baked — the floor loads Core
//   from it with no wormhole, and a prod tab with no wormhole tree reads it too).
export const GROUND_CORE     = 'Core'
export const GROUND_MANIFEST = 'src/lib/A/grounds.gen.js'
const MARK_RE = /^(Doc:|Point:|FromWhat:|Ground:|Stands:)/

export function ground_marks(node) {
    const m = { ground: null, stands: [] }
    for (const c of node.slice(1)) {
        if (typeof c !== 'string') continue
        if (c.startsWith('Ground:')) m.ground = c.slice(7)
        else if (c.startsWith('Stands:')) m.stands.push(c.slice(7))
    }
    return m
}

export function grounds_derive(W, files, problems) {
    const by = new Map()
    const home = new Map()
    const G = (name) => {
        if (!by.has(name)) by.set(name, { name, desc: '', from: '', stands: new Set(), load: [], beside: [], advice: [] })
        return by.get(name)
    }
    const every = W.find(w => w[0] === EVERYTHING)
    const areas = new Map()
    for (const what of every[3]) {
        const m = ground_marks(what)
        if (!m.ground) continue
        const from = what.find(c => typeof c === 'string' && c.startsWith('FromWhat:Waft:'))
        if (!from) { problems.push(`${EVERYTHING}: ${what[0]} wears Ground:${m.ground} but points at no Waft`); continue }
        if (!/^[A-Z][A-Za-z]*$/.test(m.ground)) problems.push(`${EVERYTHING}: Ground name ${m.ground} — one capitalised word`)
        areas.set(from.slice(14), m)
    }
    const place = (path, ground, tests) => {
        if (/\.g$/.test(path)) {
            const g = (tests || /Testing\.g$/.test(path)) ? ground + 'Testing' : ground
            if (g !== ground) G(g).stands.add(ground)
            if (!home.has(path)) { home.set(path, g); G(g).load.push(path) }
            else if (home.get(path) !== g) G(g).stands.add(home.get(path))
        }
        else if (/\.md$/.test(path)) { if (!G(ground).advice.includes(path)) G(ground).advice.push(path) }
        else if (!G(ground).beside.includes(path)) G(ground).beside.push(path)
    }
    for (const [name, wdesc, , tree] of W) {
        const area = areas.get(name)
        if (!area) continue
        const top = G(area.ground)
        if (top.from) problems.push(`Ground/${area.ground}: tagged on two areas — ${top.from} and ${name}`)
        top.from = name
        top.desc = wdesc
        for (const s of area.stands) top.stands.add(s)
        const walk = (node, ground, tests) => {
            const m = ground_marks(node)
            tests = tests || node[0] === 'What:the tests'
            if (m.ground) { ground = m.ground; G(ground).from ||= name; G(ground).desc ||= node[1] }
            for (const s of m.stands) G(ground).stands.add(s)
            for (const c of node.slice(1)) {
                if (Array.isArray(c)) walk(c, ground, tests)
                else if (typeof c === 'string' && c.startsWith('Doc:')) place(c.slice(4), ground, tests)
            }
        }
        for (const w of tree) walk(w, area.ground)
    }
    for (const g of by.values()) {
        g.stands.delete(g.name)
        g.stands.delete(GROUND_CORE)
        if (/Testing$/.test(g.name) && !g.desc) { g.desc = `the tests of Ground/${g.name.replace(/Testing$/, '')} — what a Book proving it loads`; g.from = by.get(g.name.replace(/Testing$/, ''))?.from || '' }
        for (const s of g.stands) if (!by.has(s)) problems.push(`Ground/${g.name}: stands on Ground/${s} — no area wears it`)
        for (const p of g.load) if (!files.includes(p)) problems.push(`Ground/${g.name}: ${p} is not a source file`)
    }
    // no Ground stands on itself through another — the load order must exist
    const state = new Map()
    const visit = (n, trail) => {
        if (state.get(n) === 2) return
        if (state.get(n) === 1) { problems.push(`Ground cycle: ${[...trail, n].join(' → ')}`); return }
        state.set(n, 1)
        for (const s of by.get(n)?.stands || []) visit(s, [...trail, n])
        state.set(n, 2)
    }
    for (const n of by.keys()) visit(n, [])
    if (!by.has(GROUND_CORE)) problems.push(`no Ground/${GROUND_CORE} — some area must wear Ground:${GROUND_CORE}`)
    const list = [...by.values()].filter(g => g.load.length || g.stands.size).sort((a, b) => a.name < b.name ? -1 : 1)
    return { list, home }
}

export function ground_toc(g) {
    const lines = [`Ground:${g.name}${g.desc ? ',desc:' + g.desc : ''}${g.of ? ',FromWhat:Ground:' + g.of : g.from ? ',FromWhat:Waft:' + g.from : ''}`]
    if (g.flavour) lines.push(`  Flavour:${g.flavour}`)
    for (const s of g.stands) lines.push(`  Stands:${s}`)
    for (const p of g.load) lines.push(`  Load:${p}`)
    for (const p of g.beside) lines.push(`  Beside:${p}`)
    for (const p of g.advice) lines.push(`  Advice:${p}`)
    return lines.join('\n') + '\n'
}

export function ground_manifest(list) {
    const o = {}
    for (const g of list) o[g.name] = g.flavour ? { stands: [...g.stands], load: g.load, flavour: g.flavour } : { stands: [...g.stands], load: g.load }
    return `// grounds.gen.js — GENERATED by src/lib/L/wafts_keep.js (node scripts/wafts_everything.mjs) — never hand-edit.
//  The Ground tags on Waft:Everything, baked: what each Ground loads, in order, and what it stands on (Core is under all).
//   The floor (src/lib/A/ground.ts) loads Core from this with no wormhole; wormhole/Ground/<Name>/toc.snap says the same.
export const GROUNDS = ${JSON.stringify(o, null, 1)}
`
}
