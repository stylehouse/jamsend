// Gardener.g — the keeper of the derived map: a DUTY a tab takes up, not a role it boots as (AtheoryNexus_todo §3.14, built 2026-11-20).
//  Owner: "keep the entire process in A rather than random scripts that don't decode the Lines properly … it'd be a role you took on
//   when ready, a lot of hackers shall just be looking at code for something else … it may need a level of awakeness".  And its main
//    act: "look at each computation, and commission a runner to interrupt there … target C** surrounding it to isolate certain occasions".
//
//  THE DUTY — `gardener take [--awake=dozing|awake]` / `gardener drop`.  Until taken the Gardener is ASLEEP and holds nothing.
//    asleep   holds nothing; every act but `take` says so
//    dozing   reads — the map (`gardener map`) and who reads whom (`gardener sees`); commissions nothing
//    awake    also commissions — `gardener catch <fn> --when=<query>` on this tab's Electrode or another tab's (--to=<pub>)
//   Awakeness is a row, so a face draws it and a Book swears it; it gates the acts, it does not yet schedule them (dozing re-reading
//    the map on a docindex push is the next rung).  One holder at a time across tabs is OWED (a relay lease, Nexus §6 DECISION B) —
//     today two tabs may each take it, and nothing they hold is canonical but what a human commits.
//
//  WHAT IT KEEPS, on w:Gardener (dontSnap: live derived truth, read by minisnap and the verb, never a fixture):
//    Duty:Gardener,awake:<level>
//    Map,dontSnap[,problems]                                the program map READ WITH TEXT'S OWN DECODER (deWaft) — counted by its rows
//      Waft:<key>,whats,docs,points[,json]                   one per toc read — json = lines in enLine's JSON form (a value with a comma)
//      Organ:<name>,layer,docs                               the Nexus organs, each with the Docs it lives in
//      Edge:<from>,to,as                                     the hand Nexus edges
//      Problem:<i>,says                                      the Nexus's own law (wafts_keep nexus_check) and every place deWaft and
//                                                             the script's split-on-comma parser (wafts_parse) read a toc differently
//    Derived,from,dontSnap                                   who reads whom, off a tab's %TheASees rows (Theory `sees`)
//      Seen:<organ>,to:<organ>,via,nexus:<as>|lacks          a frame in one Organ naming an A in another — the Edge the code says
//      Unhomed:<name>,via                                    a named A no file defines (stood by another's code) — its Organ unknown
//      Unmapped:<doc>,via                                    a file no Organ lives in
//    Commission:<fn>,to,when,k,kept,seen                     a catch this Gardener asked for, and what came back
//      Caught:<n>,step,from,heard                            one occasion; its said lines and args on .c.occ (Electrode's shape)
//  The script (scripts/wafts_everything.mjs) still WRITES the derived tocs; the Gardener reads beside it and says where the two
//   readings part.  Writing by enWaft and retiring the script behind a verb is the next rung (Nexus §3.14).

IMPORT()
    import { wafts_parse, nexus_check, NEXUS, EVERYTHING, UNSORTED, DERIVED_WHATS } from "$lib/L/wafts_keep.js"
    const GARDENER_AWAKE = ['asleep', 'dozing', 'awake']

Gardener(A, w):
    if (!w.o({ Duty: 'Gardener' }).length) w.i({ Duty: 'Gardener', awake: 'asleep' })

//#region the duty
Gardener_w():
    return this.top_House().o({ A: 'Gardener' })[0]?.o({ w: 'Gardener' })[0]

Gardener_awake(w):
    return String(w?.o({ Duty: 'Gardener' })[0]?.sc.awake || 'asleep')

// …the level an act needs, or the refusal that says which
Gardener_needs(w, level):
    let now = this.Gardener_awake(w)
    if (GARDENER_AWAKE.indexOf(now) >= GARDENER_AWAKE.indexOf(level)) return null
    return { error: 'the Gardener is ' + now + ' — this wants it ' + level + ' (`gardener take --awake=' + level + '`)', awake: now }

Gardener_take(w, level):
    let lv = GARDENER_AWAKE.indexOf(level) > 0 ? level : 'dozing'
    w.oai({ Duty: 'Gardener' }).sc.awake = lv
    return lv

Gardener_drop(w):
    w.oai({ Duty: 'Gardener' }).sc.awake = 'asleep'
    return 'asleep'
//#endregion

//#region the map — read with Text's decoder, checked against the script's
// Gardener_map — Everything, every area Waft it points at, and the Nexus, each toc decoded by deWaft (Text.svelte — the standard
//  decoder: JSON-form lines, tab-carried objecties and blockquote bodies all read right) into a C tree kept on .c, and summarised as
//   rows.  The same text is parsed by wafts_parse (the script's split-on-comma reader) and every row-count the two disagree on is a
//    Problem: that is the claim "the script doesn't decode the Lines properly" made checkable.  Read only; the nav may be the
//     server's (a folderless hacker page reads the repo through Atlas's origin nav).
async Gardener_map(w):
    let nav = this.Gardener_nav()
    if (!nav) return { error: 'no repo nav on this tab — stand Atlas (its origin nav) or grant a folder' }
    let read = async (key) => {
        try {
            return await nav.read_file('wormhole/' + key, 'toc.snap')
        } catch (e) {
            return null
        }
    }
    let texts = []
    let every = await read(EVERYTHING)
    if (every == null) return { error: 'no ' + EVERYTHING + ' toc' }
    texts.push([EVERYTHING, every])
    let ew = this.deWaft(every, EVERYTHING).Waft
    for (const what of (ew ? ew.o({ What: 1 }) : [])) {
        let from = String(what.sc.FromWhat || '')
        if (from.indexOf('Waft:') !== 0) continue
        let key = from.slice(5)
        if (key === UNSORTED || key === 'Credence') continue
        let text = await read(key)
        if (text != null) texts.push([key, text])
    }
    if (!texts.some((x) => x[0] === NEXUS)) {
        let nx = await read(NEXUS)
        if (nx != null) texts.push([NEXUS, nx])
    }
    return this.Gardener_map_land(w, texts)

Gardener_nav():
    if (this.Atlas_nav) {
        let nav = this.Atlas_nav()
        if (nav) return nav
    }
    return this.top_House().o({ A: 'Wormhole' })[0]?.c.nav || null

// …the decoded tocs as rows (synchronous: every read is done)
Gardener_map_land(w, texts):
    let had = w.o({ Map: 1 })[0]
    if (had) w.drop(had)
    let map = w.i({ Map: 1 })
    map.sc.dontSnap = 1
    map.c.wafts = {}
    let problems = []
    let organs = 0
    let edges = 0
    for (const [key, text] of texts) {
        let got = this.deWaft(text, key)
        for (const er of (got.errors || [])) problems.push(key + ': deWaft — ' + er)
        if (!got.Waft) continue
        map.c.wafts[key] = got.Waft
        let n = { whats: 0, docs: 0, points: 0 }
        let walk = (C, layer) => {
            for (const c of C.o()) {
                // the Whats the script writes itself (the unsorted, the groundless …) are derived — neither reading counts them
                if (c.sc.What != null && DERIVED_WHATS.indexOf('What:' + c.sc.What) >= 0) continue
                if (c.sc.What != null) n.whats = n.whats + 1
                if (c.sc.Doc != null) n.docs = n.docs + 1
                if (c.sc.Point != null) n.points = n.points + 1
                if (key === NEXUS && c.sc.Organ != null) {
                    let docs = c.o({ Doc: 1 }).map((d) => String(d.sc.Doc))
                    map.i({ Organ: String(c.sc.Organ), layer: String(layer || ''), docs: docs.join(' ') })
                    organs = organs + 1
                }
                if (key === NEXUS && c.sc.Edge != null) {
                    let e = map.i({ Edge: String(c.sc.Edge) })
                    if (c.sc.to) e.sc.to = String(c.sc.to)
                    if (c.sc.as) e.sc.as = String(c.sc.as)
                    edges = edges + 1
                }
                walk(c, c.sc.What != null ? c.sc.What : layer)
            }
        }
        walk(got.Waft, '')
        let row = map.i({ Waft: key, whats: '' + n.whats, docs: '' + n.docs, points: '' + n.points })
        let json = String(text).split('\n').filter((l) => l.trim().indexOf('{') === 0).length
        if (json) row.sc.json = '' + json
        this.Gardener_map_compare(key, text, n, problems)
        if (key === NEXUS) {
            let parsed = wafts_parse(text)
            if (parsed) nexus_check(parsed[3], problems)
        }
    }
    problems.forEach((p, ix) => map.i({ Problem: "" + (ix + 1), says: p }))
    if (problems.length) { map.sc.problems = '' + problems.length } else { delete map.sc.problems }
    return { wafts: map.o({ Waft: 1 }).map((r) => r.sc), organs: organs, edges: edges, problems: problems }

// …where the script's parser and deWaft disagree on one toc: the Docs and Points each finds (wafts_parse keeps Whats only as nodes,
//  so a What nested in a derived What is skipped by design — Docs and Points are the honest count)
Gardener_map_compare(key, text, n, problems):
    let parsed = wafts_parse(text)
    if (!parsed) {
        problems.push(key + ': the script\'s parser reads no Waft here')
        return
    }
    let docs = 0
    let points = 0
    let count = (node) => {
        for (const c of node) {
            if (Array.isArray(c)) count(c)
            else if (typeof c === 'string' && c.indexOf('Doc:') === 0) docs = docs + 1
            else if (typeof c === 'string' && c.indexOf('Point:') === 0) points = points + 1
        }
    }
    for (const what of parsed[3]) count(what)
    if (docs !== n.docs) problems.push(key + ': Docs — deWaft reads ' + n.docs + ' and the script ' + docs)
    if (points !== n.points) problems.push(key + ': Points — deWaft reads ' + n.points + ' and the script ' + points)
//#endregion

//#region who reads whom — Edges derived from %TheASees (AtheoryNexus_todo §3.15 step 4)
// Gardener_sees — a tab's `sees` answer (Theory TheA_sees: each frame, the As it read by name, the file each end came from), turned
//  into Organ pairs against the map: a frame living in one Organ that names an A living in another is an Edge the code says.  Each is
//   marked with the hand Nexus's word for it (`nexus:<as>`) or `lacks`.  --to=<pub> asks another tab (a music page is where the
//    arrival's frames stand); without it this tab answers.
async Gardener_sees(w, a):
    let to = a.to ? String(a.to) : ''
    let said = null
    if (!to) {
        said = this.TheA_sees ? this.TheA_sees({}) : null
        if (!said) return { error: 'no Theory on this tab — `sees` is Theory.g\'s' }
    } else {
        if (!this.Land_ask) return { error: 'asking another tab is the Land page\'s wire (Land_ask) — open /Desk?G=Land' }
        let got = await this.Land_ask({ verb: 'sees', to: to })
        if (got.error) return got
        said = got.result
        if (!said || !said.frames) return { error: 'no sees answer from ' + to, got: got }
    }
    return this.Gardener_sees_land(w, said, to || 'here')

Gardener_sees_land(w, said, from):
    let map = w.o({ Map: 1 })[0]
    if (!map) return { error: 'no map yet — `gardener map` first' }
    let organ_of = new Map()
    for (const org of map.o({ Organ: 1 })) {
        for (const d of String(org.sc.docs || '').split(' ')) if (d) organ_of.set(d, String(org.sc.Organ))
    }
    let nexus = new Map()
    for (const e of map.o({ Edge: 1 })) nexus.set(e.sc.Edge + '>' + e.sc.to, String(e.sc.as || ''))
    let had = w.o({ Derived: 1 })[0]
    if (had) w.drop(had)
    let der = w.i({ Derived: 1, from: from })
    der.sc.dontSnap = 1
    let out = { from: from, seen: [], unhomed: [], unmapped: [], inside: 0 }
    for (const f of (said.frames || [])) {
        let a_org = f.doc ? organ_of.get(f.doc) : null
        if (f.doc && !a_org) {
            if (!der.o({ Unmapped: f.doc }).length) der.i({ Unmapped: f.doc, via: f.at })
            out.unmapped.push(f.doc)
        }
        for (const s of (f.sees || [])) {
            let via = f.A + '>A:' + s.name
            if (!s.doc) {
                if (!der.o({ Unhomed: s.name }).length) der.i({ Unhomed: s.name, via: via })
                out.unhomed.push(s.name)
                continue
            }
            let b_org = organ_of.get(s.doc)
            if (!b_org) {
                if (!der.o({ Unmapped: s.doc }).length) der.i({ Unmapped: s.doc, via: via })
                out.unmapped.push(s.doc)
                continue
            }
            if (!a_org) continue
            if (a_org === b_org) {
                out.inside = out.inside + 1
                continue
            }
            let as = nexus.get(a_org + '>' + b_org)
            der.oai({ Seen: a_org, to: b_org }, { via: via, nexus: as || 'lacks' })
            out.seen.push({ from: a_org, to: b_org, via: via, nexus: as || 'lacks' })
        }
    }
    return out
//#endregion

//#region the catch — commissioned (Electrode's `catch`, here or on another tab)
// Gardener_catch — awake only.  Without --to the catch stands on this tab's Electrode; with it, Land_ask carries `catch` to that tab
//  (a runner running a Book, a music page) and the answer comes back as the commission's rows.  `gardener caught [--to]` reads again.
async Gardener_catch(w, a, commission):
    let fn = a.fn ? String(a.fn) : ''
    if (commission && !fn) return { error: 'gardener catch <fn> --when=<query> [--k=N] [--to=<pub>]' }
    let to = a.to ? String(a.to) : ''
    let ask = { name: commission ? fn : undefined, when: a.when, k: a.k, off: a.off }
    let got = null
    if (!to) {
        if (!this.Electrode_verb_catch) return { error: 'no Electrode on this tab — ghost_load Ghost/L/Electrode.g --stand=Electrode' }
        got = this.Electrode_verb_catch(w, ask)
    } else {
        if (!this.Land_ask) return { error: 'asking another tab is the Land page\'s wire (Land_ask) — open /Desk?G=Land' }
        let r = await this.Land_ask(Object.assign({ verb: 'catch', args: commission ? ['catch', fn] : ['catch'], to: to }, ask))
        if (r.error) return r
        got = r.result
    }
    if (!got || got.error) return got || { error: 'no answer' }
    for (const k of (got.catches || [])) this.Gardener_catch_keep(w, k, to || 'here')
    return got

Gardener_catch_keep(w, k, to):
    let row = w.oai({ Commission: String(k.fn), to: to })
    row.sc.dontSnap = 1
    if (k.when) { row.sc.when = k.when } else { delete row.sc.when }
    row.sc.k = '' + k.k
    row.sc.kept = '' + k.kept
    row.sc.seen = '' + k.seen
    if (k.ended) { row.sc.ended = 1 } else { delete row.sc.ended }
    for (const c of (k.caught || [])) {
        let got = row.oai({ Caught: '' + c.n })
        if (c.step) got.sc.step = c.step
        if (c.from) got.sc.from = c.from
        if (c.heard) got.sc.heard = c.heard
        got.c.occ = c
    }
//#endregion

//#region THE VERB
// gardener <act> — (none) status · take [--awake=dozing|awake] · drop · map · sees [--to=<pub>] · catch <fn> [--when] [--k] [--to] [--off]
//  · caught [--to].  Writes nothing to disk (its rows are its own w's), so a hacker room may hold it — that is where it belongs.
verbs_Gardener():
    let H = this
    return [
        { name: 'gardener', where: 'terminal', writes: 0, args: 'take [--awake=dozing|awake] · drop · map · sees [--to=<pub>] · catch <fn> [--when=<query>] [--k=N] [--to=<pub>] · caught',
          desc: 'the keeper of the derived map — a duty taken up with an awakeness — reads the map with the standard decoder and derives who reads whom and commissions catches',
          run: (w, a) => H.Gardener_verb(w, a) },
    ]

async Gardener_verb(w, a):
    let gw = this.Gardener_w()
    if (!gw) return { error: 'no A:Gardener standing — ghost_load Ghost/L/Gardener.g --stand=Gardener (the Land page stands it)' }
    let args = a.args || []
    let act = String(a.name || args[1] || '')
    if (act === 'take') return { awake: this.Gardener_take(gw, String(a.awake || 'dozing')) }
    if (act === 'drop') return { awake: this.Gardener_drop(gw) }
    if (act === 'map') return this.Gardener_needs(gw, 'dozing') || await this.Gardener_map(gw)
    if (act === 'sees') return this.Gardener_needs(gw, 'dozing') || await this.Gardener_sees(gw, a)
    if (act === 'catch') {
        let fn = a.fn || args[2]
        return this.Gardener_needs(gw, 'awake') || await this.Gardener_catch(gw, Object.assign({}, a, { fn: fn }), !a.off || !!fn)
    }
    if (act === 'caught') return this.Gardener_needs(gw, 'dozing') || await this.Gardener_catch(gw, a, false)
    return this.Gardener_said(gw)

Gardener_said(w):
    let map = w.o({ Map: 1 })[0]
    let der = w.o({ Derived: 1 })[0]
    return {
        awake: this.Gardener_awake(w),
        map: map ? { wafts: map.o({ Waft: 1 }).length, organs: map.o({ Organ: 1 }).length, edges: map.o({ Edge: 1 }).length, problems: +(map.sc.problems || 0) } : null,
        derived: der ? { from: der.sc.from, seen: der.o({ Seen: 1 }).map((r) => r.sc), unhomed: der.o({ Unhomed: 1 }).map((r) => r.sc.Unhomed), unmapped: der.o({ Unmapped: 1 }).map((r) => r.sc.Unmapped) } : null,
        commissions: w.o({ Commission: 1 }).map((r) => Object.assign({}, r.sc, { caught: r.o({ Caught: 1 }).length })),
    }
//#endregion
