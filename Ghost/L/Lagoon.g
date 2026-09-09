// Lagoon.g — the READER LAYER over the censuses.  The third ghost in Ghost/L/ (the land); spec home:
//  src/lib/O/spec/Lagoon_todo.md.  `Lagoon` is the owner's working title (2026-09-08) and the image is
//   the behaviour: shallow enclosed water where structures ERUPT — reefs, atolls — and get arranged
//    around the place.  *"little structures erupt when we go climbing call trees."*
//
//  WHY IT EXISTS — the concept line (Wordland_todo §1.1, ruled 2026-09-08):
//
//        ATLAS KEEPS.  LAGOON ASKS.
//
//   Atlas is a census: the compiler's index of every doc, kept fresh.  One idea.  But it had drifted to
//    12 keeping / 4 asking, one convenience at a time — no single addition wrong, which is what
//     globulation looks like from the inside.  The test for anything new is a single question: *does it
//      change what is HELD, or ask a question OF what is held?*  Keeping is Atlas.  Asking is here.
//
//  MOVED IN, 2026-09-08, unchanged but for their names and where they look the world up:
//    Lagoon_callers   ← Atlas_callers    who calls X, with the doc and the enclosing method
//    Lagoon_lint      ← Atlas_lint       rotted file:line links, drifted lines, orphan defs
//    Lagoon_resolve   ← Atlas_resolve    (lint's helper)
//    Lagoon_unproven  ← Atlas_unproven   which %see sentences no Book fixture recorded
//    Lagoon_join      ← Electrode_join   declared (Atlas) vs measured (Electrode) — belongs to neither
//
//   `Atlas_unproven` was the clearest misfit and the reason the line got drawn: it does not ask of the
//    census at all, it opens `wormhole/Story/**/*.snap` off disk.  A second source and a second concern
//     inside a code index, mitigated with an opt-in flag instead of being given a home.  This is the home.
//
//  THE TRAP THIS GHOST MUST NOT FALL INTO — *Lagoon must not start keeping.*  A reader may cache what it
//   can throw away and rebuild; it may never hold something Atlas cannot recompute, or there are two
//    truths.  Every verb here is a pure read over particles it does not own.
//
//  WHERE IT LOOKS: `A:Atlas/w:Atlas` and `A:Electrode/w:Electrode` on the top House, found by name and
//   never held — so a re-stand of either census is picked up on the next ask with no invalidation.
//    Nothing is minted; nothing here writes.

IMPORT()
    import Lagui from "$lib/L/Lagui.svelte"
    import Clerkdesk from "$lib/L/Clerkdesk.svelte"
    // Copies of the constants the moved verbs need.  Module consts do not cross ghosts, and a shared
    //  module for four regexes would be a third thing to keep in step — the duplication is deliberate
    //   and each is annotated with its twin in Atlas.g so a drift is greppable.
    const LAGOON_EXT        = { g: 1, svelte: 1, ts: 1, md: 1 }      // twin: ATLAS_EXT
    // StemHive's camel|snake splitter, verbatim (LiesFunk.svelte:1484) — see Lagoon_families
    const LAGOON_TOKEN      = /[A-Z]+(?![a-z])|[A-Z][a-z]+|[a-z]+|[0-9]+/g
    const LAGOON_DISPATCHED = /^(req_|e_|Run_A_|_)/                  // twin: ATLAS_DISPATCHED
    const SNAP_NAME_RE      = /^\d+\.snap$/                          // twin: Atlas.g's own
    const SEE_LINE_RE       = /^\s*see:([^,\n]+)/gm                  // twin: Atlas.g's own
    // a Book toc's declared oath — `Assertion:<slug>,sentence:…` under its latch step (CLAUDE.md's
    //  Story section).  The SLUG is what a `«sworn»` link cites, so that is what this captures.
    const OATH_LINE_RE      = /^\s*Assertion:([a-z0-9-]+),/gm

// Lagoon(A, w) — the do_fn.  A reader has no work of its own: every verb is called by a query (the CLI
//  op, a Book, later the room).  So the drive only reports what it can see, which is also the liveness
//   tell a caller wants — `see:lagoon,atlas,electrode` says which censuses are standing.
// WRITE ONLY ON CHANGE (2026-09-08).  This stamped `atlas:<count>` every single tick, and a write is a
//  version bump whether or not the value moved — so the world bumped forever, and anything watching it
//   (the face) re-derived forever with it.  The owner watching the panel: *"now it's tailspinning".*
//  A report row is a REPORT: it may only move when what it reports moves.  Cheap to get right, and the
//   same discipline `Atlas_report` already keeps ("replaced not piled, the Seem/%News idiom").
Lagoon(A, w):
    if (!w.c.faced) this.Lagoon_plan(w)
    let row = w.oai({ see: 'lagoon' })
    let atlas = this.Lagoon_atlas()
    let elec = this.Lagoon_electrode()
    let docs = atlas ? '' + atlas.o({ Doc: 1 }).length : null
    if (docs !== null) {
        if (row.sc.atlas !== docs) row.sc.atlas = docs
    } else if (row.sc.atlas) {
        delete row.sc.atlas
    }
    if (elec) {
        if (!row.sc.electrode) row.sc.electrode = 1
    } else if (row.sc.electrode) {
        delete row.sc.electrode
    }

// Lagoon_plan — mount the face, the Cyto_plan idiom (`uis.oai({UI:…},{component})`).  Everything the
//  reader knows was CLI-only until 2026-09-08 — the owner, looking for it in a room: "where's all the
//   work?".  A reader layer nobody can look at is a library with no door.
//  It lands wherever Lagoon stands, which is a RUNNER tab: L ghosts are outside the spine manifest and
//   `ghost_load` is refused on a humdinger, so /BigWordland (role 'word') cannot host one.  Making it
//    visible THERE is a manifest question, which is Atheory's (Lagoon_todo §4).
// WHERE THE CENSUS STANDS AND WHERE ITS FACE MOUNTS ARE TWO QUESTIONS, and conflating them is what
//  split the Hackarium room in half (the owner, 2026-09-09: *"UI:Lagoon appears to come out in H:Mundo
//   but shouldn't… I can see H:Hackarium's UI:Langui there but not UI:Lagoon"*).
//  The census MUST stand on the top House — `Lagoon_atlas()` looks it up there by name, `runner_ask`'s
//   ops look there, and `LagoonStaple` paid a recording to learn "stand where the reader looks".  So
//    `A:Lagoon` is minted on Mundo, its do_fn's `this` is Mundo, and enrolling the UI on `this` put the
//     face on Mundo while the room's own Langui sat on `H:Hackarium`.  In a room that shows ONE House's
//      UIs at a time, that is not a cosmetic split — it is the face being on another page.
//  So a room may NAME ITSELF as the face's home: `w.c.face_on` is a runtime House ref (`.c` is exactly
//   for runtime objects), set by whoever stands the world.  Absent — a CLI-stood Lagoon with no room —
//    it falls back to `this`, which is the old behaviour and still right when there is no room to join.
Lagoon_plan(w):
    let home = w.c.face_on ?? this
    let uis = this.oai_enroll(home, { watched: 'UIs' })
    uis.oai({ UI: 'Lagoon' }, { component: Lagui })
    // TWO FACES, ONE READER, and they are two because they answer two questions — Lagui asks the
    //  corpus "where is X", the desk asks the day "what was I doing".  Both are renderings of Lagoon
    //   verbs over shelves it does not own, so this is not a second machine (Lagoon_todo §1.8's line);
    //    it is the same reader wearing the face each question deserves.
    uis.oai({ UI: 'Clerkdesk' }, { component: Clerkdesk })
    w.c.faced = 1

//#region the censuses it reads — found by name, never held
Lagoon_atlas():
    return this.top_House().o({ A: 'Atlas' })[0]?.o({ w: 'Atlas' })[0] ?? null

Lagoon_electrode():
    return this.top_House().o({ A: 'Electrode' })[0]?.o({ w: 'Electrode' })[0] ?? null

// THE STEMDEX IS A CENSUS TOO, and noticing that is the whole of the 2026-09-09 unification.
//  `w:Lies` holds the Stemdex — every name and every line of freetext the machine has read off disk,
//   kept fresh by a polite dige-gated scan.  That is a census by any definition this land uses: it
//    KEEPS.  It was never treated as one only because it happened to arrive with a face attached.
//  So it is looked up by name on the top House and never held, exactly like Atlas and Electrode, and
//   `Lagoon_seek` asks over all three.  Three censuses, one reader, one answer.
Lagoon_lies():
    return this.top_House().o({ A: 'Lies' })[0]?.o({ w: 'Lies' })[0] ?? null
//#endregion

//#region THE BEADCHAIN — a document as its own shape, not a screed (Lagoon_todo leg 4)
// The owner, 2026-09-08: *"we then also want the code to not be so much of a screed but a beadchain,
//  which could have clusters of stuff, compound nodes, etc… perhaps.  it's that world very soon now."*
//
// ATLAS ALREADY HELD THE BEADS AND NOBODY HAD DRAWN THEM — and it turned out to hold them more
//  completely than the plan guessed.  A `//#region` is an author-declared bead with a name and a span,
//   and the census keeps `region,label,depth,line` for every doc.  But it also keeps, on EVERY def,
//    the enclosing region chain the collector recorded as it walked (`.c.region_path`) — and
//     `Atlas_cache_put` carries it through the Dexie row, so it survives a warm adopt.  So there is no
//      containment arithmetic to do and no span to intersect: each def already knows its beads.
//
// A CHAIN, NOT A GRAPH, and deliberately.  `Lens_posable` says not to invent a pose model yet, and the
//  spec's own first cut is the honest one: beads in FILE ORDER, indented by region depth.  An order and
//   an indent are things the corpus actually states; an arrangement is not, so it is not invented here.
//
// It returns ONE FLAT `chain`, because that is what a chain is — a face renders it by indenting on
//  `depth` and needs no tree walk.  Defs outside every region sit at depth 0, which is the truth about
//   a file whose author never drew a bead: it is one long bead, and saying so is better than pretending.
Lagoon_beads(w, path):
    let atlas = this.Lagoon_atlas()
    if (!atlas) return { error: 'no A:Atlas standing — ghost_load Ghost/L/Atlas.g --stand=Atlas first' }
    let want = String(path ?? '').trim()
    if (!want) return { error: 'Lagoon_beads: a doc path is required' }
    let doc = atlas.o({ Doc: want })[0]
    if (!doc) {
        // a bare filename is the common way to ask, so resolve it the way every other reader does
        let by_tail = {}
        for (const d of atlas.o({ Doc: 1 })) {
            let p = d.sc.Doc
            let t = p.slice(p.lastIndexOf('/') + 1)
            if (!by_tail[t]) by_tail[t] = []
            by_tail[t].push(p)
        }
        let hit = this.Lagoon_resolve(by_tail, want)
        if (hit) doc = atlas.o({ Doc: hit })[0]
    }
    if (!doc) return { error: 'no such Doc in the census — try the full path, or lagoon defs doc:<part>' }
    let map = doc.o({ Map: 1 })[0]
    if (!map) return { error: 'that Doc is rostered but not mapped yet — the census is still walking' }
    let rows = []
    for (const r of map.o({ region: 1 })) {
        rows.push({ kind: 'region', label: r.sc.label, depth: +(r.sc.depth ?? 1), line: +(r.sc.line ?? 0), defs: 0 })
    }
    let beads = 0
    for (const r of rows) beads = beads + 1
    for (const d of map.o({ def: 1 })) {
        let name = d.sc.method
        if (!name || name === 'IMPORT') continue
        let rp = d.c.region_path
        let depth = (rp && rp.length) ? rp.length : 0
        let row = { kind: 'def', label: name, depth: depth, line: +(d.sc.line ?? 0) }
        if (rp && rp.length) row.bead = rp[rp.length - 1]
        rows.push(row)
    }
    // FILE ORDER IS THE ORDER.  The chain is the document read top to bottom; a region sorts before the
    //  defs it opens because its own line is the `//#region` line.  Nothing is re-arranged.
    rows.sort((a, b) => (a.line - b.line) || (a.kind === 'region' ? -1 : 1))
    // the count each bead carries — a bead's weight is how much of the file it holds
    let by_label = {}
    for (const r of rows) { if (r.kind === 'region') by_label[r.label] = r }
    let loose = 0
    for (const r of rows) {
        if (r.kind !== 'def') continue
        if (r.bead && by_label[r.bead]) {
            by_label[r.bead].defs = by_label[r.bead].defs + 1
        } else {
            loose = loose + 1
        }
    }
    return { doc: doc.sc.Doc, lines: +(doc.sc.lines ?? 0), beads: beads, defs: rows.length - beads,
             loose: loose, chain: rows }
//#endregion

//#region ONE ANSWER, MANY FACES — the seek (2026-09-09)
// The owner, looking at their room: *"there's the `search — ƒ methods · % props` searchbar, which is
//  kinda annoying… every search result should probably be 80% of the screen real estate, as usual"*
//   and then *"unify it beautifully with the current effort as well."*
//
// WHAT WAS ACTUALLY WRONG, and it was not the placeholder.  The room had TWO seek machines: the
//  Searchbar over the Stemdex (ƒ methods · % props · ≈ text) and Lagui over Atlas (families, defs,
//   callers, mentions).  Two inputs, two hit lists, two glyph vocabularies, mounted on two different
//    Houses — and both ending in the SAME act, `Lies_ghost_pick{path, point}`.  A person typing
//     `Heist_keep` does not care which index answers.  The taxonomy in that placeholder was one
//      index announcing itself at the seeker, which is why it read as annoying.
//
// THE UNIFICATION IS NOT ONE FACE.  IT IS ONE ANSWER.
//  Atlas keeps.  The Stemdex keeps.  Lagoon asks — over both, and returns the readings a SEEKER wants
//   in the order they want them, not the order the indexes are built in.  Then the Searchbar and Lagui
//    are two renderings of one reply, which is the model this codebase already uses everywhere else.
//     Two faces on one answer is fine.  Two answers behind two faces is the globulation.
//
// THE READINGS, in seeker order:
//   families — the browse door, when the query is too short to rank.  *"I can't remember a method name
//              to look up"* is the commonest way a seek starts, and a blind input asks you to already
//              know the answer.  The unranked INDEX rides beside it, because a short query has two
//              honest answers (the map, and everything) and picking between them is a face's job.
//   defs     — the symbol itself.  Atlas is authoritative (it has the real doc:line); the Stemdex's
//              own defs are merged in so a missing census degrades the answer instead of emptying it.
//   mentions — the prose that NAMES it, once the query resolves to a real def.  Callers stay a
//              SEPARATE ask (`Lagoon_callers`) because they are per-row and on demand — that is the
//              erupting, and it should cost nothing until you climb.
//   props / texts — the Stemdex's particle vocabulary and freetext.
//
// AND IT NAMES WHICH CENSUSES ANSWERED.  A partial answer that looks whole is the silent-empty law
//  broken one layer up (Fallen_out_of_mind §2.9 Law 3): with Atlas down you get the Stemdex readings
//   and `atlas:0`, so the face can SAY so rather than quietly showing you less.
Lagoon_seek(w, q, cap):
    let atlas = this.Lagoon_atlas()
    let lies = this.Lagoon_lies()
    let needle = String(q ?? '').trim()
    let kk = cap || 200
    if (!atlas && !lies) {
        return { error: 'no census standing — ghost_load Ghost/L/Atlas.g --stand=Atlas (and a w:Lies for the Stemdex)' }
    }
    let out = { q: needle, atlas: atlas ? 1 : 0, stemdex: lies ? 1 : 0,
                families: [], defs: [], props: [], texts: [], mentions: [], mentions_total: 0 }
    // THE BROWSE DOOR.  Under two characters there is nothing to RANK, so the honest answer is not an
    //  empty list — it is the map, plus the index itself.
    // THE ANSWER DOES NOT DECIDE WHAT A FACE SHOWS, and getting that wrong cost a regression before it
    //  shipped.  A first cut returned families ALONE here, which suited the Searchbar (whose resting
    //   state is the map) and quietly emptied Lagui (whose resting state is the INDEX — *"that thing
    //    where all the methods are"*, the owner's own words for why it exists).  Two faces, two resting
    //     states, one answer: so the reply carries BOTH readings and each face renders what it is for.
    //      A reader that decides a face's layout has taken a decision that is not its to take.
    if (needle.length < 2) {
        if (atlas) {
            let fam = this.Lagoon_families(w, 40)
            if (fam && fam.families) out.families = fam.families
            let a = this.Lagoon_defs(w, '', kk)
            if (a && a.defs) {
                for (const d of a.defs) {
                    let row = { name: d.name, doc: d.doc, line: d.line, from: 'atlas' }
                    if (d.bead) row.bead = d.bead
                    out.defs.push(row)
                }
                out.defs_total = a.total
            }
        }
        return out
    }
    // the Stemdex's three readings, verbatim — it is a census and this is a read of it
    //  ONE FIELD NAME FOR ONE THING.  The Stemdex says `path`, Atlas says `doc`, and a face that had
    //   to know which reading it was holding would be the split all over again in miniature.  Every
    //    row that leaves here says `doc`, and a snippet rides along wherever the census had one.
    if (lies) {
        let s = this.Lies_search(lies, needle, kk)
        if (s) {
            for (const p of s.props ?? []) out.props.push({ name: p.name, doc: p.path, line: p.line ?? (p.lines ?? [])[0], from: 'stemdex' })
            for (const t of s.texts ?? []) {
                let row = { name: t.title ?? t.path, doc: t.path, line: t.line ?? 1, from: 'stemdex' }
                if (t.snippet) row.snippet = t.snippet
                out.texts.push(row)
            }
            out.done = s.done
            out.total = s.total
            if (s.missing) out.missing = s.missing
            for (const d of s.defs ?? []) {
                let row = { name: d.name, doc: d.path, line: d.line, from: 'stemdex' }
                if (d.snippet) row.snippet = d.snippet
                out.defs.push(row)
            }
        }
    }
    // Atlas's defs, merged over the top: it holds the real doc:line, so where both censuses know a
    //  def Atlas wins the row and the Stemdex's copy is dropped rather than shown twice.
    let seen = {}
    for (const d of out.defs) seen[d.name + '@' + d.doc + ':' + d.line] = 1
    if (atlas) {
        let a = this.Lagoon_defs(w, needle, kk)
        if (a && a.defs) {
            for (const d of a.defs) {
                let key = d.name + '@' + d.doc + ':' + d.line
                if (seen[key]) continue
                seen[key] = 1
                out.defs.push({ name: d.name, doc: d.doc, line: d.line, from: 'atlas' })
            }
            out.defs_total = a.total
        }
    }
    // RANK FOR A SEEKER, not for an index.  Both surfaces sorted by name or by path, which buries an
    //  exact hit under thirty substring ones.  Exact first, then prefix, then the rest; path breaks
    //   the tie so same-doc hits still sit together, which was the Stemhive's own good idea.
    let low = needle.toLowerCase()
    for (const d of out.defs) {
        let n = String(d.name ?? '').toLowerCase()
        d.rank = n === low ? 0 : (n.indexOf(low) === 0 ? 1 : 2)
    }
    out.defs.sort((a, b) => (a.rank - b.rank)
        || String(a.doc).localeCompare(String(b.doc)) || ((a.line ?? 0) - (b.line ?? 0)))
    // THE PROSE NEIGHBOURHOOD, and only when the query resolves to a real def.  A backticked phrase
    //  that names nothing is a phrase, not a link (the m14 lesson), so mentions are offered for a
    //   symbol the census can vouch for and stay quiet otherwise.
    // THE BEADCHAIN AS A READING.  `doc:<part>` already scoped the defs index to a file, so when that
    //  scope lands on exactly ONE document the honest answer to "show me this file" is its SHAPE, not a
    //   list of its methods in alphabetical order.  One prefix in the same box, no second surface —
    //    which is the whole point of §1.8.
    if (atlas && needle.indexOf('doc:') === 0) {
        let docs = {}
        for (const d of out.defs) docs[d.doc] = 1
        let names = Object.keys(docs)
        if (names.length === 1) {
            let b = this.Lagoon_beads(w, names[0])
            if (b && !b.error) out.beads = b
        } else if (names.length > 1) {
            out.beads_ambiguous = names.length
        }
    }
    if (atlas && out.defs.length && out.defs[0].rank === 0) {
        let m = this.Lagoon_mentions(w, out.defs[0].name, 40)
        if (m && m.mentions) {
            out.mentions = m.mentions
            out.mentions_total = m.total
            out.mentions_of = out.defs[0].name
        }
    }
    return out
//#endregion

//#region who calls X — moved from Atlas 2026-09-08
// Walks every mapped Doc's `call` AND `elvisto` rows for the name — a plain o() per doc, no index: at
//  711 docs this is milliseconds, and an actual reverse index would mean maintaining a SECOND structure
//   in step with the first (and a reader that keeps an index has started keeping — see the header).
//  Returns [{doc, line, via, kind}], kind:'call'|'elvisto' so a caller can tell direct calls from
//   deferred cross-ghost ones without a second query.
Lagoon_callers(w, name):
    let atlas = this.Lagoon_atlas()
    if (!atlas) return { error: 'no A:Atlas standing — ghost_load Ghost/L/Atlas.g --stand=Atlas first' }
    let out = []
    for (const doc of atlas.o({ Doc: 1 })) {
        let map = doc.o({ Map: 1 })[0]
        if (!map) continue
        for (const c of map.o({ call: 1, method: name })) {
            out.push({ doc: doc.sc.Doc, line: c.sc.line, via: c.sc.via, kind: 'call' })
        }
        for (const e of map.o({ elvisto: 1, method: name })) {
            out.push({ doc: doc.sc.Doc, line: e.sc.line, via: e.sc.via, target: e.sc.target, kind: 'elvisto' })
        }
    }
    return out
//#endregion

//#region the index — every def the census holds, browsable
// Lagoon_defs — "that thing where all the methods are" (the owner, 2026-09-08, on the first face: *"I
//  can't remember a method name to look up… Lagoon seems like it has nothing in it"*).  A blind input
//   asks you to already know the answer, which is the opposite of an index.
//  Substring match on the name, or on `doc:` to scope to a file; capped, with the true total beside it
//   so a cut is never silent.  Sorted by name so the same query gives the same list twice — a browsable
//    thing has to hold still.  Pure read; nothing minted, nothing cached (the layer rule).
Lagoon_defs(w, q, cap):
    let atlas = this.Lagoon_atlas()
    if (!atlas) return { error: 'no A:Atlas standing — ghost_load Ghost/L/Atlas.g --stand=Atlas first' }
    let needle = String(q ?? '').trim().toLowerCase()
    let doc_only = null
    if (needle.indexOf('doc:') === 0) {
        doc_only = needle.slice(4)
        needle = ''
    }
    let out = []
    let total = 0
    let kk = cap || 300
    for (const doc of atlas.o({ Doc: 1 })) {
        let path = doc.sc.Doc
        if (doc_only && path.toLowerCase().indexOf(doc_only) < 0) continue
        let map = doc.o({ Map: 1 })[0]
        if (!map) continue
        for (const d of map.o({ def: 1 })) {
            let name = d.sc.method
            if (!name || name === 'IMPORT') continue
            if (needle && name.toLowerCase().indexOf(needle) < 0) continue
            total = total + 1
            // COLLECT ALL, SORT, THEN CUT — not cut-then-sort, which is what this did.  With a cap the
            //  old order kept whichever rows the WALK reached first and sorted only those, so the index
            //   looked alphabetical while actually being an arbitrary sample of the corpus — and which
            //    sample you got moved as the census re-rostered.  This verb's own comment says "sorted
            //     by name so the same query gives the same list twice — a browsable thing has to hold
            //      still", and cut-then-sort cannot hold still.  Found 2026-09-09 by reading a capped
            //       resting index and seeing four lowercase names from scripts/ where the As should be.
            {
                // THE BEAD, and it costs nothing (2026-09-09).  The collector already recorded each
                //  def's enclosing `//#region` chain on `.c.region_path` — and `Atlas_cache_put`
                //   carries it through the Dexie row — so the innermost named region a method lives in
                //    is simply THERE, on the row.  `path:line` says where a thing is on disk; the bead
                //     says where it is in the FILE'S OWN STRUCTURE, which is what the author meant.
                let rp = d.c.region_path
                let row = { name: name, doc: path, line: d.sc.line }
                if (rp && rp.length) row.bead = rp[rp.length - 1]
                out.push(row)
            }
        }
    }
    out.sort((a, b) => a.name < b.name ? -1 : (a.name > b.name ? 1 : 0))
    if (out.length > kk) out = out.slice(0, kk)
    return { defs: out, total: total, shown: out.length, docs: atlas.o({ Doc: 1 }).length }
//#endregion

// Lagoon_families — THE LARGER OBJECTS (the owner, 2026-09-08: *"I want the larger objects in the code
//  picked up on somehow… we did this with stemming"*).  Three thousand method names is a phone book, not
//   a map.  But the names already carry the structure: `Heist_keep`, `Heist_blag`, `Heist_census` are one
//    thing seen three times.  So bucket every def by the STEM OF ITS FIRST TOKEN and the subsystems fall
//     out of the corpus without anyone declaring them.
//  Reuses the machine's own two pieces rather than inventing a third — `LAGOON_TOKEN` is StemHive's
//   camel|snake splitter verbatim (`LiesFunk.svelte:1484`) and the stemming matches `Lies_stem`'s light
//    suffix strip, so a family here and a search hit there agree about what a word is.
//  A `region` count rides along: `//#region` blocks are the OTHER larger object, the one an author named
//   by hand inside a file, and Atlas already holds them.
Lagoon_families(w, cap):
    let atlas = this.Lagoon_atlas()
    if (!atlas) return { error: 'no A:Atlas standing — ghost_load Ghost/L/Atlas.g --stand=Atlas first' }
    let fam = new Map()
    let defs_total = 0
    let regions = 0
    for (const doc of atlas.o({ Doc: 1 })) {
        let map = doc.o({ Map: 1 })[0]
        if (!map) continue
        regions = regions + map.o({ region: 1 }).length
        for (const d of map.o({ def: 1 })) {
            let name = d.sc.method
            if (!name || name === 'IMPORT') continue
            let toks = String(name).match(LAGOON_TOKEN)
            if (!toks || !toks.length) continue
            let stem = this.Lagoon_stem(toks[0])
            if (!stem) continue
            defs_total = defs_total + 1
            let row = fam.get(stem)
            if (!row) {
                row = { stem: stem, defs: 0, docs: new Set(), head: toks[0] }
                fam.set(stem, row)
            }
            row.defs = row.defs + 1
            row.docs.add(doc.sc.Doc)
        }
    }
    let out = []
    for (const row of fam.values()) {
        out.push({ stem: row.stem, head: row.head, defs: row.defs, docs: row.docs.size })
    }
    out.sort((a, b) => b.defs - a.defs)
    let kk = cap || 60
    return { families: out.slice(0, kk), total: out.length, defs_total: defs_total, regions: regions }

// Lagoon_stem — `Lies_stem`'s light strip, kept here rather than called across the ghost border so a
//  reader has no dependency on the editor's Stemdex being loaded.  If the two ever disagree, THIS is the
//   copy to change: the Stemdex's is the original and the contract is internal consistency, not English.
Lagoon_stem(word):
    let s = String(word ?? '').toLowerCase()
    if (s.length > 4) {
        if (/ies$/.test(s)) { s = s.slice(0, -3) + 'y' } else { s = s.replace(/(?:ings?|ers?|eds?|es|s)$/, '') }
    }
    return s
//#endregion

//#region the prose side — which docs TALK about a symbol
// Lagoon_mentions — the twin of Lagoon_callers, and the reason the `code` link kind exists.  `callers`
//  answers "what CALLS this"; this answers "what SAYS this" — every doc that names the symbol in
//   backticks, with the line.  Between them a method has both of its neighbourhoods: the code that
//    depends on it and the prose that explains it.
//  RESOLUTION LIVES HERE, not in the collector (compile.ts's CODE_RE emits every candidate because it
//   cannot know the corpus).  `resolved` says whether Atlas holds a def by that name: if it does, the
//    mention is a LINK and a rot check applies; if not, it is just a phrase in backticks and no doc is
//     wrong for containing it.  That split is the whole reason Atlas keeps and Lagoon asks.
Lagoon_mentions(w, name, cap):
    let atlas = this.Lagoon_atlas()
    if (!atlas) return { error: 'no A:Atlas standing — ghost_load Ghost/L/Atlas.g --stand=Atlas first' }
    let needle = String(name ?? '').trim()
    if (!needle) return { error: 'Lagoon_mentions: a name is required' }
    let out = []
    let total = 0
    let resolved = false
    let kk = cap || 60
    for (const doc of atlas.o({ Doc: 1 })) {
        let map = doc.o({ Map: 1 })[0]
        if (!map) continue
        if (!resolved && map.o({ def: 1, method: needle }).length) resolved = true
        for (const l of map.o({ link: 1, kind: 'code', target: needle })) {
            total = total + 1
            if (out.length < kk) out.push({ doc: doc.sc.Doc, line: l.sc.line })
        }
    }
    return { name: needle, resolved: resolved, mentions: out, total: total, shown: out.length }

// Lagoon_prose_rot — the doc-rot work queue for SYMBOLS (front 3, the owner: "higher level pointers or
//  sending you around fixing|obsoleting things is the way").  A `code` link whose target Atlas holds no
//   def for, and which no OTHER doc resolves either, is a doc naming something that is not there any
//    more — the prose twin of a dead `file:line`.  Capped and counted; a scan aid like the orphan lint,
//     not a verdict, because a backticked word can legitimately be a key or a constant rather than a def.
Lagoon_prose_rot(w, cap):
    let atlas = this.Lagoon_atlas()
    if (!atlas) return { error: 'no A:Atlas standing — ghost_load Ghost/L/Atlas.g --stand=Atlas first' }
    let defs = new Set()
    let mentions = new Map()
    let links = 0
    // A doc's own NAME wears the same shape as a ghost method (`Daemon_todo`, `Identity_persist_todo`,
    //  `Wire_spec`), and the corpus backticks doc names constantly.  Those are references to documents,
    //   not to code, so they are not rot — and Atlas already holds every doc path, so excluding them
    //    costs one set.  (This is the second time this verb over-claimed; the lesson is that "looks like
    //     a symbol" and "is a symbol" are different questions, and only the census can tell them apart.)
    let docnames = new Set()
    for (const doc of atlas.o({ Doc: 1 })) {
        let p = doc.sc.Doc
        let base = p.slice(p.lastIndexOf('/') + 1)
        docnames.add(base.replace(/\.(svelte\.ts|svelte|ts|g|mjs|md)$/, ''))
    }
    for (const doc of atlas.o({ Doc: 1 })) {
        let map = doc.o({ Map: 1 })[0]
        if (!map) continue
        for (const d of map.o({ def: 1 })) defs.add(d.sc.method)
        for (const l of map.o({ link: 1, kind: 'code' })) {
            links = links + 1
            let t = l.sc.target
            if (!mentions.has(t)) mentions.set(t, { target: t, n: 0, doc: doc.sc.Doc, line: l.sc.line })
            mentions.get(t).n = mentions.get(t).n + 1
        }
    }
    // SPLIT THE UNRESOLVED BY SHAPE, because the first cut of this verb over-claimed and the numbers say
    //  so: 3,025 distinct targets, 1,343 unresolved — but the top of that list was `body_hash`,
    //   `runner_ask`, `CREDULER_GHOSTS`, `repli_want`, `heard_at`, none of which is rot.  They are
    //    particle keys, a CLI name, a constant, a wire verb.  A backticked word is not a promise that a
    //     def exists.
    //  The GHOST-METHOD shape — `Capitalised_lowercase…`, which is what every ghost method in this
    //   codebase is named — is the subset where an unresolved target really does suggest the doc is
    //    naming something gone.  Everything else is reported as `other`, counted but not accused.
    let rot = []
    let other = 0
    for (const row of mentions.values()) {
        if (defs.has(row.target)) continue
        if (docnames.has(row.target)) { other = other + 1; continue }
        if (/^[A-Z][A-Za-z0-9]*_[a-z]/.test(row.target)) { rot.push(row) } else { other = other + 1 }
    }
    rot.sort((a, b) => b.n - a.n)
    let kk = cap || 60
    return { code_links: links, distinct: mentions.size, resolved: mentions.size - rot.length - other, likely_rot: rot.length, other_unresolved: other, top: rot.slice(0, kk) }
//#endregion

//#region the lint — moved from Atlas 2026-09-08
// Three answers the census already contains.
//  missing:    a `file:line` link in a doc whose target file is in NO living root — the tell that a
//              spec moved to history/, was renamed, or never existed (CLAUDE.md's own corollary:
//              "a referenced spec/X.md that isn't there is almost certainly spec/history/X.md").
//  beyond_eof: the target exists but the cited line is past its end — the line drifted.
//  orphans:    a def no call or elvisto anywhere names.  A scan aid, not a verdict: do_fns named
//              after their world, UI handlers wired in markup and `this[name]` dispatch all read as
//              orphans here.  Capped, with the total beside it.
// OWED (Lagoon_todo §0 front 3, the owner 2026-09-08): this returns a LIST, and the ruling is that doc
//  rot should be a WORK QUEUE — "higher level pointers or sending you around fixing|obsoleting things".
//   The rows below are the raw material for that; the routing is not built.
Lagoon_lint(w):
    let atlas = this.Lagoon_atlas()
    if (!atlas) return { error: 'no A:Atlas standing — ghost_load Ghost/L/Atlas.g --stand=Atlas first' }
    let docs = atlas.o({ Doc: 1 })
    let by_tail = {}
    let lines_of = {}
    for (const d of docs) {
        let p = d.sc.Doc
        lines_of[p] = +(d.sc.lines ?? 0)
        let tail = p.slice(p.lastIndexOf('/') + 1)
        if (!by_tail[tail]) by_tail[tail] = []
        by_tail[tail].push(p)
    }
    let missing = []
    let beyond = []
    let file_links = 0
    let called = {}
    for (const d of docs) {
        let map = d.o({ Map: 1 })[0]
        if (!map) continue
        for (const c of map.o({ call: 1 })) called[c.sc.method] = 1
        for (const e of map.o({ elvisto: 1 })) called[e.sc.method] = 1
        for (const l of map.o({ link: 1, kind: 'file' })) {
            let target = l.sc.target
            let ext = target.split('.').pop()
            if (!LAGOON_EXT[ext]) continue                // scripts/*.mjs &c. are not rostered — no verdict
            // a target NAMING history/ or shelved/ points at a shelf Atlas deliberately never rosters
            if (/(^|\/)(history|shelved)\//.test(target)) continue
            file_links = file_links + 1
            let hit = this.Lagoon_resolve(by_tail, target)
            if (!hit) {
                missing.push({ doc: d.sc.Doc, line: l.sc.line, target, at_line: l.sc.at_line })
                continue
            }
            let at = +(l.sc.at_line ?? 0)
            // A DOC WHOSE LENGTH IS UNKNOWN CANNOT BE OVERSHOT.  `lines` is stamped by a real map, so
            //  an as-yet-unmapped Doc reads 0 and EVERY link into it looked "past EOF" — 275 of them
            //   mid-walk, falling to ~100 as the census converged.  A convergence artifact wearing a
            //    verdict's clothes, and it predates tonight; the work queue is what made it visible
            //     ("the line drifted — that file is 0 lines" for `RadioFace.svelte`, which is fine).
            //  You cannot say a line is past the end of a file whose end you do not know.  Say nothing.
            if (!lines_of[hit]) continue
            if (at > lines_of[hit]) beyond.push({ doc: d.sc.Doc, line: l.sc.line, target: hit, at_line: at, lines: lines_of[hit] })
        }
    }
    // ── the § lint (2026-09-08, ATLAS_MAPPER m15).  The corpus's real cross-reference form, and the
    //  first one that can rot INSIDE a doc that still exists: `Radio_todo §0` is fine until Radio_todo
    //   renumbers, and nothing has ever noticed.  Two verdicts, deliberately kept apart, because they
    //    route to different work: `sect_nodoc` is the file-missing story the `file:line` lint already
    //     tells (the doc moved to history/ or was renamed), while `sect_gone` is a LIVE doc whose §N
    //      is not there any more — the section was renumbered, merged or dropped, and the pointer is
    //       now aimed at nothing in a page that reads perfectly well.  Only the second is new signal.
    //  A TARGET-LESS § IS COUNTED AND NEVER ACCUSED, and that ruling cost a measurement.  The obvious
    //   reading is that a bare `see §9` means THIS doc's §9, and linting them that way produced 454
    //    "dead" self-references.  Sampling them killed the reading: `Seemables_todo` has 38 bare §s and
    //     numbers nothing but its own §0, because its §s point into whatever doc the sentence just
    //      named — *"That work lives in `Voro_render_todo.md` §0"*.  A bare § has an AMBIGUOUS REFERENT
    //       that only prose resolves, so the honest lint says nothing about it.  (The m14 `prose_rot`
    //        lesson for the third time: "looks like rot" and "is rot" are different questions.  This one
    //         was caught before publishing rather than after, which is the improvement.)
    let sect_links = 0
    let sect_self = 0
    let sect_nodoc = []
    let sect_gone = []
    let sects_of = {}
    for (const d of docs) {
        let map = d.o({ Map: 1 })[0]
        if (!map) continue
        for (const l of map.o({ link: 1, kind: 'sect' })) {
            sect_links = sect_links + 1
            if (!l.sc.target) { sect_self = sect_self + 1; continue }
            let home = d.sc.Doc
            let t = l.sc.target
            // A TARGET THAT NAMES THE SHELF IS NOT ROT, and this rule already existed one loop above —
            //  the `file:line` lint has skipped `history/`|`shelved/` since it was written, because
            //   Atlas deliberately never rosters those roots, so it can neither confirm nor deny them.
            //    I did not carry it over when the § pass went in, and the corpus said so: a doc writing
            //     `history/Reqdrop_todo §N` — a reference that is already CORRECT and explicitly points
            //      at the shelf — was being reported as pointing at a doc nothing has.  Found by trying
            //       to ACT on the work queue, which is the only way that kind of wrongness shows up.
            if (/(^|\/)(history|shelved)\//.test(t)) continue
            if (!/\.md$/.test(t)) t = t + '.md'
            let hit = this.Lagoon_resolve(by_tail, t)
            // THE SUFFIX THE CORPUS DROPS.  Docs are named `X_todo.md` / `X_spec.md` (CLAUDE.md's Docs
            //  section) and prose cites them as plain `X` about a tenth of the time — `Social_demarcation
            //   §7`, `Radio_circuit §0.5`, `Vyto_sizing §8`.  Without this fallback 38 of 470 links read
            //    "no such doc" when the doc is right there under its full name; with it, 5.
            if (!hit) hit = this.Lagoon_resolve(by_tail, t.replace(/\.md$/, '_todo.md'))
            if (!hit) hit = this.Lagoon_resolve(by_tail, t.replace(/\.md$/, '_spec.md'))
            if (!hit) {
                sect_nodoc.push({ doc: home, line: l.sc.line, target: l.sc.target, sect: l.sc.sect })
                continue
            }
            if (!sects_of[hit]) sects_of[hit] = this.Lagoon_sections(atlas, hit)
            if (!sects_of[hit][l.sc.sect]) {
                sect_gone.push({ doc: home, line: l.sc.line, target: hit, sect: l.sc.sect })
            }
        }
    }

    let orphans = []
    let orphans_total = 0
    for (const d of docs) {
        let map = d.o({ Map: 1 })[0]
        if (!map) continue
        for (const f of map.o({ def: 1 })) {
            let name = f.sc.method
            if (!name || called[name]) continue
            if (name === 'IMPORT') continue                // the .g IMPORT() block parses as a def; it is not one
            if (LAGOON_DISPATCHED.test(name)) continue
            orphans_total = orphans_total + 1
            if (orphans.length < 400) orphans.push({ doc: d.sc.Doc, name, line: f.sc.line })
        }
    }
    return { docs: docs.length, file_links, missing, beyond_eof: beyond, orphans_total, orphans,
             sect_links, sect_self, sect_nodoc, sect_gone }

// Lagoon_sections — every section NUMBER a markdown doc declares, as a set.  Atlas already keeps every
//  heading (`%region,label,depth,line`), and a numbered heading wears its number at the front of the
//   label — `## 2.5 THE AFTERNOON'S THREE BUGS`, `## 0. What to get on with next`.  So this is a read
//    of held rows, not a parse: pull the leading `N(.N)*` off each label.
//  A doc with no numbered headings returns an empty set, which means every § pointing INTO it reads
//   gone.  That is the right answer rather than a special case — a doc that stopped numbering its
//    sections really did break every pointer aimed at one.
Lagoon_sections(atlas, path):
    let out = {}
    let d = atlas.o({ Doc: path })[0]
    if (!d) return out
    let map = d.o({ Map: 1 })[0]
    if (!map) return out
    for (const r of map.o({ region: 1 })) {
        // the corpus numbers its headings four ways and ALL of them must index, or the lint invents rot:
        //  `## 3.`, `## 3.1`, `## 3b.`, `## 5a.2`.  A first cut read only the first two and reported 852
        //   dead self-references, most of which were `§3.1b` pointing at a perfectly present `### 3.1b`.
        //    That is the m14 `prose_rot` lesson again — "looks like rot" and "is rot" are different
        //     questions — caught this time before it was published rather than after.
        let m = /^(\d+[a-z]?(?:\.\d+[a-z]?)*)\.?(?:\s|$)/.exec(String(r.sc.label ?? ''))
        if (!m) continue
        // index the whole number AND every shorter prefix, letterless forms included: a doc whose only
        //  section-3 headings are `3.1`/`3.2` still HAS a §3, and `§3.1` still names `### 3.1b`.
        let parts = m[1].split('.')
        for (let k = 1; k <= parts.length; k++) {
            let pre = parts.slice(0, k).join('.')
            out[pre] = 1
            out[pre.replace(/[a-z]/g, '')] = 1
        }
    }
    // %anchor rows — a numbered section that is NOT a heading (`**7.4 …**`), collected since m15 for
    //  exactly this: the corpus points § at them and a heading-only index calls them rot.
    for (const a of map.o({ anchor: 1 })) {
        let s = String(a.sc.sect ?? '')
        if (!s) continue
        let parts = s.split('.')
        for (let k = 1; k <= parts.length; k++) {
            let pre = parts.slice(0, k).join('.')
            out[pre] = 1
            out[pre.replace(/[a-z]/g, '')] = 1
        }
    }
    return out

//#region THE WORK QUEUE — rot routed, not rot listed (Lagoon_todo leg 6 / front 3)
// The owner's ruling, 2026-09-08: *"having higher level pointers or sending you around fixing|
//  obsoleting things is the way."*  So a lint's output is not a struck-through link in a margin.  It is
//   a routed list — *this doc points at something that no longer exists: fix the pointer, or mark the
//    doc obsolete* — and the environment's job is to send someone to it.
//
// THREE THINGS MAKE IT A QUEUE RATHER THAN A LIST, and they are the whole of this verb:
//  1. IT GROUPS BY DOC.  You do not fix a link, you fix a document — one visit, N repairs.  A flat list
//      of 200 rows sends you to 200 places; the same rows grouped send you to eleven.
//  2. IT PROPOSES THE FIX where the census can compute one.  A § pointing at a section that is gone
//      gets the nearest anchor the target doc actually has (`§3.7` → the doc has 3.1…3.4, so `§3`); a
//       file link with no holder gets the `_todo`/`_spec` name the corpus keeps dropping.  A suggestion
//        the census can stand behind is the difference between work and a complaint.
//  3. IT PICKS THE LIKELY EXIT.  Two exits, per the ruling.  A doc with one dead pointer into a live
//      doc wants `fix`.  A doc whose pointers rot in bulk INTO DOCS THAT ARE THEMSELVES GONE is not
//       broken, it is stale — and the ruled move for a stale doc is `spec/history/` with a historicity
//        notice (CLAUDE.md's Docs section), not a hundred pointer repairs.  So the queue says which.
//
// IT KEEPS NOTHING, and that is not an accident of implementation — it is the layer rule (`LagoonStaple`
//  beat 6 reds if this ghost starts holding).  There is no "done" flag anywhere, because a queue item's
//   disposition IS the edit: fix the pointer and the item stops being derived; retire the doc and every
//    item under it goes with it.  A work queue over a census needs no state of its own.
Lagoon_rotwork(w, cap):
    let atlas = this.Lagoon_atlas()
    if (!atlas) return { error: 'no A:Atlas standing — ghost_load Ghost/L/Atlas.g --stand=Atlas first' }
    let lint = this.Lagoon_lint(w)
    if (lint.error) return lint
    let by_tail = {}
    for (const d of atlas.o({ Doc: 1 })) {
        let p = d.sc.Doc
        let tail = p.slice(p.lastIndexOf('/') + 1)
        if (!by_tail[tail]) by_tail[tail] = []
        by_tail[tail].push(p)
    }
    let items = []
    // a file:line whose target no living root holds.  The census can often name the fix: the corpus
    //  drops the `_todo`/`_spec` suffix in prose, so try the full names before giving up.
    for (const m of lint.missing) {
        let fix = this.Lagoon_resolve(by_tail, m.target.replace(/\.md$/, '_todo.md'))
        if (!fix) fix = this.Lagoon_resolve(by_tail, m.target.replace(/\.md$/, '_spec.md'))
        // "nothing rosters" is the phrase the exit rule counts (below), and a missing FILE target is
        //  the same fact as a missing § target — the thing pointed at is gone.  The first cut phrased
        //   this one differently and so the exit rule saw only half the dead targets it claimed to
        //    weigh.  Same words for the same fact, or the rule quietly means something else.
        let it = { doc: m.doc, line: m.line, kind: 'file', target: m.target,
                   why: 'nothing rosters that file — no living root holds it' }
        if (fix) it.fix = fix
        items.push(it)
    }
    for (const b of lint.beyond_eof) {
        items.push({ doc: b.doc, line: b.line, kind: 'file', target: b.target + ':' + b.at_line,
                     why: 'the line drifted — that file is ' + b.lines + ' lines' })
    }
    // a § into a LIVE doc that has no such anchor — the kind of rot that hides in a page which still
    //  reads perfectly.  The proposal is the longest prefix of the cited number the doc DOES have.
    for (const s of lint.sect_gone) {
        let have = this.Lagoon_sections(atlas, s.target)
        let near = this.Lagoon_near_sect(have, s.sect)
        let it = { doc: s.doc, line: s.line, kind: 'sect', target: s.target + ' §' + s.sect,
                   why: 'that doc has no §' + s.sect }
        if (near) it.fix = s.target + ' §' + near
        items.push(it)
    }
    for (const s of lint.sect_nodoc) {
        items.push({ doc: s.doc, line: s.line, kind: 'sect', target: s.target + ' §' + s.sect,
                     why: 'nothing rosters that doc — try spec/history/' })
    }
    // group.  A visit is to a DOC, so the doc is the unit and the busiest goes first.
    let groups = {}
    for (const it of items) {
        if (!groups[it.doc]) groups[it.doc] = { doc: it.doc, n: 0, dead: [], items: [] }
        let g = groups[it.doc]
        g.n = g.n + 1
        if (it.why.indexOf('nothing rosters') === 0) g.dead.push(it.target.split(' ')[0])
        g.items.push(it)
    }
    let out = []
    for (const k of Object.keys(groups)) out.push(groups[k])
    for (const g of out) {
        g.items.sort((a, b) => a.line - b.line)
        // THE EXIT, and the first cut of this rule was wrong in an instructive way.  It counted dead
        //  pointers, so `Wire_spec.md` — 13 of them — read "stale, retire it".  But all thirteen name
        //   ONE vanished doc: `Wire_spec` is not stale, its target moved, and the work is a single
        //    retarget rather than thirteen repairs or a retirement.
        //  So the signal is DISTINCT dead targets, not the count.  Many pointers at ONE gone doc = the
        //   target moved (`same_target` names it, and that is the whole job, done once).  Pointers at
        //    THREE OR MORE gone docs = the pointing doc has outlived its neighbourhood, which is what
        //     stale looks like, and the ruled move is `spec/history/` with a historicity notice.
        //  Blunt on purpose: this routes attention, it does not rule.  A human takes the other exit
        //   whenever they like — which is why both exits are always named.
        let distinct = {}
        for (const d of g.dead) distinct[d] = 1
        let names = Object.keys(distinct)
        g.dead_targets = g.dead.length
        if (names.length === 1 && g.dead.length > 1) g.same_target = names[0]
        g.exit = names.length >= 3 ? 'obsolete' : 'fix'
        delete g.dead
    }
    out.sort((a, b) => b.n - a.n)
    let kk = cap || 12
    return { docs_with_rot: out.length, rot_items: items.length,
             to_fix: out.filter(g => g.exit === 'fix').length,
             to_obsolete: out.filter(g => g.exit === 'obsolete').length,
             queue: out.slice(0, kk) }

// Lagoon_near_sect — the closest anchor a doc actually has to a cited one: the longest dotted prefix of
//  `3.7.2` the doc holds (`3.7`, then `3`).  Not fuzzy matching — a prefix of a section number names the
//   section that CONTAINS it, so the proposal is always a real place, one level out from where the
//    author meant.  Returns null when even the top number is gone, which is itself the answer.
Lagoon_near_sect(have, sect):
    let parts = String(sect).split('.')
    for (let k = parts.length - 1; k >= 1; k--) {
        let pre = parts.slice(0, k).join('.')
        if (have[pre]) return pre
    }
    return null
//#endregion

// Lagoon_resolve — a link target (`Heist.g`, `M/Heist.g`, `src/lib/O/Lang.svelte`) to a rostered
//  path: same tail, then the longest path-suffix match; a bare filename takes the first holder.
Lagoon_resolve(by_tail, target):
    let tail = target.slice(target.lastIndexOf('/') + 1)
    let cands = by_tail[tail]
    if (!cands) return null
    if (target.indexOf('/') < 0) return cands[0]
    for (const c of cands) {
        if (c === target || c.endsWith('/' + target)) return c
    }
    return cands[0]
//#endregion

//#region unproven sentences — moved from Atlas 2026-09-08, and the move is the point
// Every %see sentence in code that NO Book fixture has ever recorded.  A %see is the assertion idiom,
//  so an unfixtured one is a claim nothing swears; a single-word `see:atlas` is a summary row, not a
//   claim, so only sentences with a space count.
// THIS is the verb that drew the concept line: it reads Book fixture FILES, not the census, so inside
//  Atlas it was a second source and a second concern.  Here it is simply one reader among several that
//   happens to need a nav.  (Downgraded as a FEATURE by the owner 2026-09-08 — "don't really care about
//    this… pointers from the spec to the test assertion, sure" — but it is homeless either way, so it
//     moves with the rest and stops being a headline.)
async Lagoon_unproven(w, nav):
    let atlas = this.Lagoon_atlas()
    if (!atlas) return { error: 'no A:Atlas standing — ghost_load Ghost/L/Atlas.g --stand=Atlas first' }
    let fixtured = {}
    let books = await nav.dir_at('wormhole/Story')
    if (!books) return { error: 'no wormhole/Story under this nav' }
    await books.expand()
    let read = 0
    // EVERY numbered snap, not just the last: sentences do not strictly accumulate (a beat's world can
    //  be re-stood), so the union over the Book's snaps is the fixture truth.  ~1000 reads: opt-in.
    for (const b of books.directories) {
        if (!b.expanded) await b.expand()
        for (const f of b.files) {
            if (!SNAP_NAME_RE.test(f.name)) continue
            let text = await nav.read_file('wormhole/Story/' + b.name, f.name)
            if (!text) continue
            read = read + 1
            for (const m of text.matchAll(SEE_LINE_RE)) fixtured[m[1].trim()] = 1
        }
    }
    let unproven = []
    let total = 0
    for (const d of atlas.o({ Doc: 1 })) {
        let map = d.o({ Map: 1 })[0]
        if (!map) continue
        for (const p of map.o({ proves: 1 })) {
            if (p.sc.desc) continue
            let s = p.sc.sentence
            if (!s || s.indexOf(' ') < 0) continue
            total = total + 1
            if (fixtured[s]) continue
            unproven.push({ doc: d.sc.Doc, line: p.sc.line, via: p.sc.via, sentence: s })
        }
    }
    return { books_read: read, fixtured: Object.keys(fixtured).length, sees_total: total, unproven }

// Lagoon_oaths — the OTHER two m15 link kinds, `book` and `sworn`, resolved against the Books themselves.
//  It is async and lives here rather than in Lagoon_lint for one honest reason: a Book is not in the
//   census.  Atlas rosters code and prose; `wormhole/Story/**` is a third shelf, and reaching for it is
//    a disk read — the same shape as Lagoon_unproven above, which is why they are neighbours.
//  ONE READ PER BOOK (the toc), not one per snap: a Book's declared oath lives in its toc as
//   `Assertion:<slug>,sentence:…`, so ~80 reads rather than unproven's ~1000.
//  Two verdicts, and the second is the one the owner asked for — *"pointers from the spec to the test
//   assertion"*.  A `Book:Name` that names no Book, and a `«slug»` no Book declares any more.  The
//    second is the sharper signal by far: a doc citing an assertion that has been renamed or dropped is
//     a doc claiming the machine still swears something it does not.
async Lagoon_oaths(w, nav):
    let atlas = this.Lagoon_atlas()
    if (!atlas) return { error: 'no A:Atlas standing — ghost_load Ghost/L/Atlas.g --stand=Atlas first' }
    let books = await nav.dir_at('wormhole/Story')
    if (!books) return { error: 'no wormhole/Story under this nav' }
    await books.expand()
    let known_book = {}
    let sworn_in = {}
    let read = 0
    for (const b of books.directories) {
        known_book[b.name] = 1
        let text = await nav.read_file('wormhole/Story/' + b.name, 'toc.snap')
        if (!text) continue
        read = read + 1
        for (const m of text.matchAll(OATH_LINE_RE)) {
            if (!sworn_in[m[1]]) sworn_in[m[1]] = b.name
        }
    }
    let book_links = 0
    let book_gone = []
    let sworn_links = 0
    let sworn_gone = []
    let sworn_ok = []
    for (const d of atlas.o({ Doc: 1 })) {
        let map = d.o({ Map: 1 })[0]
        if (!map) continue
        for (const l of map.o({ link: 1, kind: 'book' })) {
            book_links = book_links + 1
            if (!known_book[l.sc.target]) book_gone.push({ doc: d.sc.Doc, line: l.sc.line, target: l.sc.target })
        }
        for (const l of map.o({ link: 1, kind: 'sworn' })) {
            sworn_links = sworn_links + 1
            let where = sworn_in[l.sc.target]
            if (where) {
                sworn_ok.push({ doc: d.sc.Doc, line: l.sc.line, slug: l.sc.target, book: where })
            } else {
                sworn_gone.push({ doc: d.sc.Doc, line: l.sc.line, slug: l.sc.target })
            }
        }
    }
    return { tocs_read: read, books: Object.keys(known_book).length,
             oaths: Object.keys(sworn_in).length,
             book_links, book_gone, sworn_links, sworn_ok, sworn_gone }
//#endregion

//#region the join — declared (Atlas) vs measured (Electrode); moved from Electrode 2026-09-08
// For every method that RAN as a caller, Atlas's `call,via:<that method>` rows say what its body
//  DECLARES it calls; Electrode's tally says what it actually called.
//    declared − measured = paths this run never took (dead, or untested — coverage, per Book).
//    measured − declared = dispatch the static walk cannot follow (closures, by-name dispatch).
//  The universe is what the TAP can see (the ghost bag): Housing's class methods have Atlas defs but
//   are never coated, so a declared call to one is not a path this instrument can judge — left out of
//    both columns.  Declared callees are limited to names Atlas holds a def for, so `push`/`slice`
//     never count as "never ran".
//  It lived in Electrode because it needed the tally; it belongs to NEITHER census, which is exactly
//   why the reader layer had to exist.  This is the worked example in Lagoon_todo §0.
Lagoon_join(w, k):
    let atlas = this.Lagoon_atlas()
    if (!atlas) return { error: 'no A:Atlas standing — ghost_load Ghost/L/Atlas.g --stand=Atlas first' }
    let top = this.top_House()
    let T = top.c.electrode
    if (!T) return { error: 'no electrode tally — ghost_load Ghost/L/Electrode.g --stand=Electrode and arm it' }
    let bag = top.ghosts || {}
    let seeable = new Set(Object.keys(bag).filter(n => typeof bag[n] === 'function'))
    let defs = new Set()
    let declared = new Map()
    let docs_of = new Map()
    for (const doc of atlas.o({ Doc: 1 })) {
        let map = doc.o({ Map: 1 })[0]
        if (!map) continue
        for (const d of map.o({ def: 1 })) {
            if (!seeable.has(d.sc.method)) continue
            defs.add(d.sc.method)
            if (!docs_of.has(d.sc.method)) docs_of.set(d.sc.method, doc.sc.Doc)
        }
        for (const c of map.o({ call: 1 })) {
            if (!c.sc.via || !c.sc.method) continue
            let set = declared.get(c.sc.via)
            if (!set) {
                set = new Set()
                declared.set(c.sc.via, set)
            }
            set.add(c.sc.method)
        }
    }
    let measured = new Map()
    for (const row of T.tally.values()) {
        if (!row.from) continue
        let m = measured.get(row.from)
        if (!m) {
            m = new Map()
            measured.set(row.from, m)
        }
        m.set(row.to, (m.get(row.to) || 0) + row.n)
    }
    let ran = 0
    let pairs_declared = 0
    let pairs_ran = 0
    let never = []
    let undeclared = []
    let unknown_callers = 0
    for (const [from, tos] of measured) {
        if (!defs.has(from)) {
            unknown_callers = unknown_callers + 1
            continue
        }
        ran = ran + 1
        let dec = declared.get(from) || new Set()
        for (const callee of dec) {
            if (!defs.has(callee)) continue
            pairs_declared = pairs_declared + 1
            if (tos.has(callee)) { pairs_ran = pairs_ran + 1 } else { never.push({ via: from, callee: callee, doc: docs_of.get(from) || null }) }
        }
        for (const [to, n] of tos) {
            if (!dec.has(to) && defs.has(to)) undeclared.push({ from: from, to: to, n: n })
        }
    }
    undeclared.sort((a, b) => b.n - a.n)
    let kk = k || 40
    return {
        ran_methods: ran, unknown_callers: unknown_callers,
        declared_pairs: pairs_declared, pairs_ran: pairs_ran,
        coverage: pairs_declared ? Math.round(1000 * pairs_ran / pairs_declared) / 10 : null,
        never_ran: never.length, never_ran_top: never.slice(0, kk),
        undeclared: undeclared.length, undeclared_top: undeclared.slice(0, kk),
        atlas_docs: atlas.o({ Doc: 1 }).length, atlas_defs: defs.size
    }
//#endregion

//#region THE ERRANDS — what you went in there to look at (2026-09-09)
// The owner: *"it forgets what it was going in there to look at if that takes too long. so where do we
//  keep what to look at and what we're doing etc?"*
//
// IT WAS NEVER NOT KEPT.  Every search delivery already writes a moment into today's Aside Waft
//  (`Lies.svelte` e_Lies_ghost_pick → `Lies_spawn_aside_waft`), and the moment already carries the
//   answer to both halves of the question:
//     %What:<serial>            one moment per ghost per day — repeat deliveries accumulate on it,
//                                which the code itself calls "the day's research trail"
//       ,about:<label>          WHAT THIS MOMENT WAS FOR — stamped at mint 2026-09-08 on the owner's
//                                own words, *"just having a context the Point is going for"*
//       ,FromWhat:<locator>     where you came from: `Waft:<key>/<mainkey>:<value>`, a loose STRING
//                                so it survives the Aside being thrown away
//       > %Doc:<path>           what you opened
//         > %Point,method       where you landed — one per visit, so the count is how often you went
//  And `Lies_resolve_locator` already resolves that locator form; its own comment calls itself "the
//   reader %FromWhat was waiting for".  Shelf built, label built, resolver built, SURFACE NEVER DRAWN —
//    the same shape as Atlas holding the beadchain for weeks with nobody rendering it.
//  So this verb invents no store.  It READS a shelf it does not own, which is the whole layer rule.
//
// A STALE PATH IS HISTORY, NOT ROT, and this is the one judgement in here.  A moment records a visit
//  that happened; a doc renamed since (today's Aside names `Ghost/Story/Voronation.g`, from before the
//   Testing.g rename) has not invalidated the visit.  So `gone:1` is stamped when the census cannot
//    place the path, and it is stamped as a FACT for the face to render quietly — never repaired here,
//     never hidden, never called rot.  Atlas is consulted only if it is standing; absent, no doc is
//      marked gone, because "I cannot see" must not render as "it is not there".
Lagoon_errands(w, k):
    let lies = this.Lagoon_lies()
    if (!lies) return { error: 'no A:Lies standing — the Aside lives on w:Lies, so there is nothing to read' }
    let atlas = this.Lagoon_atlas()
    let known = null
    if (atlas) {
        known = new Set()
        for (const d of atlas.o({ Doc: 1 })) known.add(d.sc.Doc)
    }
    let days = []
    let moments = []
    for (const wf of lies.o({ Waft: 1 })) {
        if (!wf.sc.aside) continue
        let key = wf.sc.Waft
        let day = { day: key, moments: 0, visits: 0 }
        for (const m of wf.o({ What: 1 })) {
            let docs = []
            let visits = 0
            for (const d of m.o({ Doc: 1 })) {
                let pts = []
                for (const p of d.o({ Point: 1 })) {
                    if (p.sc.method) pts.push(p.sc.method)
                }
                visits = visits + (pts.length || 1)
                let row = { doc: d.sc.Doc, points: pts }
                if (known && !known.has(d.sc.Doc)) row.gone = 1
                docs.push(row)
            }
            let row = { day: key, what: m.sc.What, about: m.sc.about ?? null, docs: docs, visits: visits }
            if (m.sc.FromWhat) {
                row.from = m.sc.FromWhat
                let cut = this.Lagoon_locator_split(m.sc.FromWhat)
                if (cut) {
                    row.from_waft = cut.waft
                    row.from_tail = cut.tail
                }
            }
            moments.push(row)
            day.moments = day.moments + 1
            day.visits = day.visits + visits
        }
        days.push(day)
    }
    // newest day first, and inside a day the most-returned-to moment first: the desk wants what you
    //  kept coming back to at the top, not what you happened to open first
    days.sort((a, b) => a.day < b.day ? 1 : (a.day > b.day ? -1 : 0))
    moments.sort((a, b) => (a.day < b.day ? 1 : (a.day > b.day ? -1 : (b.visits - a.visits))))
    let total = moments.length
    let kk = k || 40
    let gone = 0
    for (const m of moments) {
        for (const d of m.docs) {
            if (d.gone) gone = gone + 1
        }
    }
    if (moments.length > kk) moments = moments.slice(0, kk)
    return { errands: moments, days: days, total: total, shown: moments.length, gone: gone,
             atlas: atlas ? 1 : 0 }

// Lagoon_locator_split — `Waft:<key>/<mainkey>:<value>` into its two halves.  GREEDY on the key half
//  on purpose: a Waft key contains slashes (`Ghost/Net/Easy`) and so can a value, so the split has to
//   be the LAST `/` that is followed by a `Mainkey:` — anything less greedy cuts a key in half.
Lagoon_locator_split(loc):
    let m = /^Waft:(.*)\/([A-Za-z][A-Za-z0-9_]*:[\s\S]*)$/.exec(loc || '')
    if (!m) return null
    return { waft: m[1], tail: m[2] }
//#endregion

//#region THE FIGURINES — who is well connected, measured beside declared (2026-09-09)
// The owner, end of a long day: *"I want another view where figurines of things that are well
//  connected are… I think we need to record a bunch of runtime data about which methods are top-most,
//   popular, etc… that's about it actually."*
//
// THE DATA WAS ALREADY RECORDED.  Electrode's tally holds every (from → to) flow the coats saw, with
//  counts and time; Atlas holds every `call,via` a body declares.  "Popular" and "top-most" are not new
//   taps, they are two READINGS of what is kept — which is exactly the reader layer's job, and why this
//    sits in Lagoon and not in either census (the same reason `Lagoon_join` does, one region up).
//     · POPULAR  — how many DISTINCT callers actually reached it (measured), beside how many distinct
//                  bodies declare a call to it (static).  Distinct, not raw count: a method one loop
//                   hammers a thousand times is busy, not connected.
//     · TOP-MOST — every flow into it entered from OUTSIDE the coats (`from` null: a do_fn dispatch, a
//                  UI handler, a timer).  Nothing coated ever calls it; it is where the world enters.
//     · FAN      — how many distinct methods it reaches, so a hub reads differently from a leaf.
//  A `dose` rides on each row — popularity over the run's maximum, 0..1 — because the face the owner
//   asked for is SIZED ("figurines"), and `dose_drives` (Matstyle) is the machine's own idiom for
//    "interpolate a size from a dose".  Derived from the answer at answer time; nothing is held.
// REFUSES BY NAME, like every reader verb: no Atlas, or no tally, is a named exit and never a silent
//  empty.  An un-armed tally is NOT a refusal — it is an honest zero, with `armed` on the reply so a
//   face can say "arm the electrode" rather than "nothing is connected".
Lagoon_figurines(w, k):
    let atlas = this.Lagoon_atlas()
    if (!atlas) return { error: 'no A:Atlas standing — ghost_load Ghost/L/Atlas.g --stand=Atlas first' }
    let top = this.top_House()
    let T = top.c.electrode
    if (!T) return { error: 'no electrode tally — ghost_load Ghost/L/Electrode.g --stand=Electrode and arm it' }
    // the declared side: where each def lives, and who declares a call to it
    let where = new Map()
    let declared_in = new Map()
    for (const doc of atlas.o({ Doc: 1 })) {
        let map = doc.o({ Map: 1 })[0]
        if (!map) continue
        for (const d of map.o({ def: 1 })) {
            if (!d.sc.method || where.has(d.sc.method)) continue
            where.set(d.sc.method, { doc: doc.sc.Doc, line: d.sc.line })
        }
        for (const c of map.o({ call: 1 })) {
            if (!c.sc.via || !c.sc.method) continue
            let set = declared_in.get(c.sc.method)
            if (!set) {
                set = new Set()
                declared_in.set(c.sc.method, set)
            }
            set.add(c.sc.via)
        }
        for (const e of map.o({ elvisto: 1 })) {
            if (!e.sc.via || !e.sc.method) continue
            let set = declared_in.get(e.sc.method)
            if (!set) {
                set = new Set()
                declared_in.set(e.sc.method, set)
            }
            set.add(e.sc.via)
        }
    }
    // the measured side, folded per method
    let seen = new Map()
    let fan_of = new Map()
    for (const row of T.tally.values()) {
        let m = seen.get(row.to)
        if (!m) {
            m = { n: 0, ms: 0, froms: new Set(), bare: 0 }
            seen.set(row.to, m)
        }
        m.n = m.n + row.n
        m.ms = m.ms + row.ms
        if (row.from) {
            m.froms.add(row.from)
            let f = fan_of.get(row.from)
            if (!f) {
                f = new Set()
                fan_of.set(row.from, f)
            }
            f.add(row.to)
        } else {
            m.bare = m.bare + row.n
        }
    }
    let rows = []
    let max_pop = 0
    for (const [name, m] of seen) {
        let pop = m.froms.size
        if (pop > max_pop) max_pop = pop
        let at = where.get(name)
        let row = { name: name, n: m.n, ms: Math.round(m.ms), callers: pop,
                    declared: (declared_in.get(name) || new Set()).size,
                    fan: (fan_of.get(name) || new Set()).size }
        if (at) {
            row.doc = at.doc
            row.line = at.line
        }
        if (m.bare && pop === 0) row.top = 1
        rows.push(row)
    }
    // connected first: distinct callers, then reach, then sheer traffic — a stable, readable order
    rows.sort((a, b) => (b.callers - a.callers) || (b.fan - a.fan) || (b.n - a.n) || (a.name < b.name ? -1 : 1))
    for (const r of rows) r.dose = max_pop ? Math.round(100 * r.callers / max_pop) / 100 : 0
    let kk = k || 40
    let tops = rows.filter(r => r.top).length
    // how many measured methods the census could not place.  First live run: ALL of them — not
    //  because the join was wrong but because a Book had left Atlas aimed at the frozen fixture
    //   (Lagoon_todo §2.5b), so the census held one doc.  A per-row "no def" said that 235 times and
    //    explained it never; `unjoined` beside `atlas_docs` says it once, with the cause in reach.
    let unjoined = rows.filter(r => !r.doc).length
    if (rows.length > kk) rows = rows.slice(0, kk)
    return { figurines: rows, ran: seen.size, tops: tops, armed: T.armed ? 1 : 0, since: T.since || 0,
             max_callers: max_pop, unjoined: unjoined, atlas_docs: atlas.o({ Doc: 1 }).length }
//#endregion
// (a .g must end on a comment or a statement, never a method-final brace)
