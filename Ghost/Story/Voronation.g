
//#region radio — VoroRadio: the tuner PROVEN (📻 drift as a deterministic Story Book)
// ══ VoroRadio — six dwells of the tuner on a fixed flora: motion, aging, and the hand ═══════════
//  The determinism gate the radio owed (spec/Voro_vtuffing.md §North stars): the SAME engine the
//   📻 button runs live (Voro_drift_tick — scoring, aging, popped_auto) driven here by STEP BEATS
//    instead of the ~7s dwell clock, on a FIXED flora, so every pick is a pure function of the
//     board + the tick count and the fixtures are byte-stable.  Four truths witnessed, each
//      hardened by the 2026-07-07 adversarial audit (evidence read AT its beat, gates that a
//       named one-line regression reddens — see VoroRadio_witness):
//      1. the tuner MOVES — six dwells, four+ distinct locales,
//      2. the trail AGES — at the first aging beat the first pick AND its whole gang stand
//         stamp-free (the wandering-landscape answer proven as data),
//      3. attention is a CYCLE — the aged locale re-gangs FULL-SIZE behind the same rep and
//         re-enters the pool (kills the audit's pool-depletion vacuity: motion is not just
//          consumption; this is the claim the gang-memory leak turns red),
//      4. the HAND outranks it — a manual pop (no popped_auto) survives every dwell untouched
//         (gates the auto|manual stamp split; the pane sits out of the pool BY DESIGN).
//  Crush re-scans each beat like VoroMitosis, so aged locales re-gang and the candidate pool
//   replenishes — the Book runs the governor and the tuner TOGETHER, exactly the live pairing.
//  All radio state c-side (drift_*, radio_*): the snap sees pure flora + the %see claims.
//   No transport, no audio, no wall clock — runs anywhere.
VoroRadio(A,w):
    w oai %req:wrangle,eternal
        await &VoroRadio_drive,w,req
        req%ok = 1

async VoroRadio_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.VoroRadio_seed(w)
        // AWAIT: the crush now grasps in its tail (writes the snapped %Se:scape row) — let it settle
        //  before this beat snaps.  The census|report rows still land synchronously above that await.
        if (n >= 2) await this.Voro_crush_scan(w)
        if (n === 5) await this.VoroRadio_hand(w)
        if (n >= 3 && n <= 8) {
            // REPOOL evidence, read BEFORE the n=8 tick: the locale aged at n=7 re-ganged at
            //  THIS beat's crush — the SAME rep back in the pool with its WHOLE family behind
            //   it (gang size = the genus's loose-taxa count).  The full-size gate matters: a
            //    partial sweep leaves orphan popped siblings and the clean remainder still
            //     re-gangs as a spill-relaxed MINI gang — same mainkey, same rep, smaller
            //      family — so anything looser passes with the leak alive.  Attention is a
            //       cycle, not a consumption; this claim goes RED if the popped-unstamp
            //        drops the gang memory or the unpop sweep loses the siblings.
            if (n === 8) {
                let aged = (w.c.radio_picks || [])[0]
                let amk = aged ? Object.keys(aged.sc)[0] : null
                let kin = amk ? w.o().filter(x => Object.keys(x.sc)[0] === amk) : []
                let cands = this.Voro_drift_candidates(w)
                if (aged && cands.includes(aged) && (aged.c.gang || []).length === kin.length) w.c.radio_repool = 1
            }
            let pick = await this.Voro_drift_tick(w)
            let picks = w.c.radio_picks || []
            if (pick) picks.push(pick)
            w.c.radio_picks = picks
            // AGED evidence, read AT the aging beat (n=7 is seq 5 — the first shift of the
            //  opens window): the first pick AND every loose taxon of its genus must be
            //   stamp-free NOW.  Read here, not at witness — once the genus re-pools the
            //    tuner may legitimately re-pick it, and a witness-time read would confuse
            //     that fresh pop with a failed aging.  Goes RED if Vtuff_unpop loses its
            //      gang sweep (siblings would still carry popped_auto).
            if (n === 7) {
                let first = picks[0]
                let fmk = first ? Object.keys(first.sc)[0] : null
                let kin = fmk ? w.o().filter(x => Object.keys(x.sc)[0] === fmk) : []
                if (first && kin.length && !kin.some(x => x.c.popped || x.c.popped_open || x.c.popped_auto)) w.c.radio_aged = 1
            }
        }
        if (n === 9) this.VoroRadio_witness(w)
    }

// a rich fixed flora — six genera so the pool outlasts six dwells even as picks consume panes
//  (a popped pane is unstamped and leaves the candidate set until a later pass re-gangs it).
VoroRadio_seed(w):
    this.VoroMitosis_found(w, 'Coprosma', 5)
    this.VoroMitosis_found(w, 'Veronica', 4)
    this.VoroMitosis_found(w, 'Metrosideros', 4)
    this.VoroMitosis_found(w, 'Olearia', 3)
    this.VoroMitosis_found(w, 'Pittosporum', 4)
    this.VoroMitosis_found(w, 'Nothofagus', 3)

// the human reaches in mid-run: pop ONE pane by hand (auto ABSENT — the human path), and stash
//  the nodes that carry the pop stamps so the witness can check every one still holds.
async VoroRadio_hand(w):
    let cands = this.Voro_drift_candidates(w)
    let manual = cands.find(c => c !== w.c.drift_focus)
    if (!manual) return
    w.c.radio_manual = manual
    await this.Vtuff_pop(manual, null)
    w.c.radio_hand = [manual].concat(manual.c.gang || manual.o()).filter(x => x.c.popped || x.c.popped_open)

// four truths, each gated on evidence a named regression would destroy (adversarially
//  audited 2026-07-07): MOVING gates the pick spread; AGED gates the unpop gang sweep (read
//   live at n=7 — see the drive); the CYCLE gates the popped-unstamp gang memory (read live
//    at n=8); the HAND gates the auto|manual stamp split (drop the `if (auto)` guard in
//     Vtuff_pop_stamp and it reddens).  The hand pane is out of the pool while popped BY
//      DESIGN, so its claim proves the stamp discipline, not a contention fight.
VoroRadio_witness(w):
    let picks = w.c.radio_picks || []
    let distinct = picks.filter((p, i) => picks.indexOf(p) === i).length
    if (picks.length >= 5 && distinct >= 4 && !(oa %see:'the tuner kept moving — six dwells chose four or more distinct locales')) i %see:'the tuner kept moving — six dwells chose four or more distinct locales'
    let last = picks[picks.length - 1]
    let fresh = last && (last.c.popped_auto || (last.c.gang || []).some(k => k.c.popped_auto) || last.o().some(k => k.c.popped_auto))
    if (w.c.radio_aged && fresh && !(oa %see:'the trail behind the listener folded back — the first locale and its whole gang aged clean while the newest stayed open')) i %see:'the trail behind the listener folded back — the first locale and its whole gang aged clean while the newest stayed open'
    if (w.c.radio_repool && !(oa %see:'an aged locale re-ganged and re-entered the pool — attention is a cycle not a consumption')) i %see:'an aged locale re-ganged and re-entered the pool — attention is a cycle not a consumption'
    let hand = w.c.radio_hand || []
    if (hand.length > 0 && hand.every(x => (x.c.popped || x.c.popped_open) && !x.c.popped_auto) && !(oa %see:'the hand outranks the tuner — a manual pop survived every dwell untouched')) i %see:'the hand outranks the tuner — a manual pop survived every dwell untouched'

//#endregion

//#region clinic — VoroClinic: auto-guard the CRUSH model (the render's faults are downstream)
// ══ VoroClinic — assert the crush INTENT is sound, so a render fault localises to the render ══════
//  The owner (2026-07-08) wants the Voro faults CHECKED automatedly.  Render pixels can't be Book-
//   gated (metaphysics #2 — nothing render-side snaps), but the CRUSH MODEL can: it stamps c-side
//    facts (c.stuff / c.fold_n / c.gang / c.represented) a Book CAN read.  This Book stands up a
//     known world, runs the crush, and asserts the invariants the render reads — so a GREEN here
//      means "the crush did its job; if the render shows fewer cells, the bug is the render."  It is
//       the automated proof behind `Voro_render_faults_todo.md` §0 (don't fork — fix the render).
VoroClinic(A, w):
    w oai %req:wrangle,eternal
        await &VoroClinic_drive,w,req
        req%ok = 1

async VoroClinic_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.VoroClinic_seed(w)
        // AWAIT: the crush now grasps in its tail (snapped %Se:scape row) — let it settle before snap.
        if (n >= 2) await this.Voro_crush_scan(w)
        if (n === 3) this.VoroClinic_witness(w)
    }

// two folded libraries (container folds via Voro_crushable) + one gang of noisy leaves (gang-fold);
//  deterministic, so the crush verdict is a pure function of this world — fixtures byte-stable.
//   Tracks carry VoroScape's musical sprinkle (hashed off the title — still pure): a %year, %live
//    on ~1/2, %remaster on ~1/3, so the Clinic exercises the CROSS-LEVEL grasp (G1: a track's
//     facts must never read as artist facts) and the absence blurs, not just a bare title list.
VoroClinic_seed(w):
    let a1 = w.i({ Artist: 1, name: 'Alpha' })
    this.VoroScape_track(a1, 'a1')
    this.VoroScape_track(a1, 'a2')
    this.VoroScape_track(a1, 'a3')
    this.VoroScape_track(a1, 'a4')
    let a2 = w.i({ Artist: 1, name: 'Beta' })
    this.VoroScape_track(a2, 'b1')
    this.VoroScape_track(a2, 'b2')
    this.VoroScape_track(a2, 'b3')
    this.VoroScape_track(a2, 'b4')
    for (let i = 0; i < 4; i++) w.i({ witnessed: 'w' + i })

// count the c.stuff CHUNKS under a node (each a cell candidate the render owes as glass); a chunk is
//  a fold — don't descend it (its members are represented inside).
VoroClinic_chunks(node, d):
    if (d > 6) return 0
    let n = 0
    for (const c of node.o()) {
        if (c.c.stuff) {
            n = n + 1
        } else {
            n = n + this.VoroClinic_chunks(c, d + 1)
        }
    }
    return n

VoroClinic_witness(w):
    // 1. container-fold fidelity: an Artist of four tracks folds to ONE chunk carrying fold_n === 4
    //  (the count the render reads to weight the cell — Voro_stamp_fold).  Reds if the fold miscounts.
    let a1 = w.o({ Artist: 1, name: 'Alpha' })[0]
    if (a1 && a1.c.stuff && a1.c.fold_n === 4 && !(oa %see:'a container of four folds to one chunk carrying its full count of four')) i %see:'a container of four folds to one chunk carrying its full count of four'
    // 2. gang fidelity: four scattered noisy leaves elect ONE rep carrying the whole gang — the other
    //  three ride represented (the render draws the rep once — Voro_gang_fold).  Reds if the sweep leaks.
    let reps = w.o().filter(x => Object.keys(x.sc)[0] === 'witnessed' && x.c.stuff && x.c.gang)
    let repd = w.o().filter(x => Object.keys(x.sc)[0] === 'witnessed' && x.c.represented)
    if (reps.length === 1 && reps[0].c.fold_n === 4 && repd.length === 3 && !(oa %see:'four scattered leaves gang behind one representative — the other three ride represented')) i %see:'four scattered leaves gang behind one representative — the other three ride represented'
    // 3. the render's DEBT made explicit: the crush intends THREE cell chunks (two libraries + one
    //  gang).  This is exactly the invariant VoroScape's render violates (crush intends N — F6 —
    //   render shows fewer); a GREEN here with a behind-glass render PROVES the bug is downstream.
    let chunks = this.VoroClinic_chunks(w, 0)
    if (chunks >= 3 && !(oa %see:'the crush intends three cell chunks — a render that shows fewer is trapping data behind glass')) i %see:'the crush intends three cell chunks — a render that shows fewer is trapping data behind glass'
//#endregion

//#region mitosis — VoroMitosis: watch the flora divide (the pure crush demo, no music no wire)
// ══ VoroMitosis — a colony that grows and splits: the voronoi render watched dividing ════════════
//  A demo-gauge Book for the crushed voronoi cells.  The flora is a BIGGER LOOSER w/*: every
//   species sits DIRECTLY under w keyed by its genus ({Coprosma:'robusta'}) — NO container is
//    modelled at all (the owner: "why does it even say cell? that's their technical term, not
//     data").  The hierarchy the old cell:<genus> containers hand-built is exactly what the
//      crusher DISCOVERS: a hundred loose taxa blow the governor's budget, it escalates, and
//       same-genus leaves gang behind one representative pane each — the machine earns the
//        clades.  Each beat every genus gains species; a genus past the split threshold DIVIDES
//         (half its species re-key to a fresh genus — a new cell births); one genus dies mid-run
//          (apoptosis — its territory reclaimed).  Deterministic throughout: growth count-driven,
//           names off fixed lists, no randomness.  No transport, no audio — runs anywhere.
//  Its subject IS the fold, so VoroMitosis DRIVES Voro_crush_scan inline (its do_fn) — not imposed.
//   The fold's working now surfaces in w:Voronoiology beside the flora; the model itself stays pure.
VoroMitosis(A,w):
    w oai %req:wrangle,eternal
        await &VoroMitosis_drive,w,req
        req%ok = 1

async VoroMitosis_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.VoroMitosis_seed(w)
        if (n >= 3 && n <= 10) this.VoroMitosis_grow(w, n)
        if (n === 8) this.VoroMitosis_die(w)
        // AWAIT the crush: the Se grasp now rides INSIDE Voro_crush_scan's tail (every crush user gets it
        //  for free — VoroScape and the VoroRadio family too, no longer VoroMitosis alone), and it writes
        //   the snapped %Se:scape row, so the drive must let it SETTLE before this beat snaps — exactly as
        //    the old hand-driven `await this.Voro_grasp(w)` did.  The grasp reads the folds through
        //     Selection.process; w:Voronoiology snaps its cross-beat News (division in, apoptosis out).
        if (n >= 2) await this.Voro_crush_scan(w)
        // the census-mirror rides where the hand grasp call used to (Seemables §1, Slice 0): a read-only
        //  %Seem:census over the PRE-SWEEP census subjects (w.c.census_home, an independent source), so a
        //   future %see can gate that its goners|neus reproduce Voro_report's hand c.seen_beat sweep —
        //    a DIVERGENCE would now MEAN a mis-reconciliation, not echo the sweep's own output.
        if (n >= 2) await this.Voro_census_mirror(w)
        if (n === 11) this.VoroMitosis_witness(w)
    }

// ── the NZ flora vocabulary ───────────────────────────────────────────────
//  fixed lists ARE the determinism (no randomness in this Book): genera name the
//   cells AND key their species, epithets name the species, forms name the nested
//    sub-taxa.  Real Aotearoa plants — Coprosma, Hebe-in-Veronica, tōtara, beech.
//  ORDER MATTERS for the ⬡ hull demo: radiation founds new genera in list order (one split
//   per beat reaches roughly index 9), so the multi-genus FAMILIES — Myrtaceae's trio and
//    Asteraceae's pair — sit early enough to all be alive at once and hull together.
Botany_genera():
    return ['Coprosma','Veronica','Metrosideros','Kunzea','Leptospermum','Pittosporum','Podocarpus','Olearia','Brachyglottis','Nothofagus','Phormium','Dracophyllum']

// the botanical FAMILY of a genus — real NZ taxonomy, the demo material for the ⬡ family
//  hulls: it rides each TAXON's c.vfamily (c-side, snap-blind — the model stays pure flora)
//   so whichever taxon a gang elects as rep carries it, and Cytui's family_of groups the
//    genus panes that share it into one rope hull.  The flora sits DIRECTLY under w, so
//     without this tag no hull can ever form there (no cyto-compound exists to group by).
Botany_family(genus):
    let fams = { Coprosma: 'Rubiaceae', Veronica: 'Plantaginaceae', Metrosideros: 'Myrtaceae', Kunzea: 'Myrtaceae', Leptospermum: 'Myrtaceae', Pittosporum: 'Pittosporaceae', Podocarpus: 'Podocarpaceae', Olearia: 'Asteraceae', Brachyglottis: 'Asteraceae', Nothofagus: 'Nothofagaceae', Phormium: 'Asphodelaceae', Dracophyllum: 'Ericaceae' }
    return fams[genus] || 'incertae sedis'
Botany_epithets():
    return ['robusta','propinqua','rhamnoides','grandifolia','lucida','tenuifolium','excelsa','totara','fusca','tenax','crassifolius','colensoi','australis','divaricata','microphylla','serrata','montana','linearis']
Botany_forms():
    return ['var. montana','var. prostrata','f. viridis','subsp. australis']

// a cheap deterministic hash (FNV-1a) — this Book carries NO randomness (fixtures must be
//  byte-stable), so "some but not all" comes from hashing a taxon's OWN name, never Math.random.
Voro_hash(s):
    let h = 2166136261
    for (let i = 0; i < s.length; i++) {
        h = Math.imul(h ^ s.charCodeAt(i), 16777619)
    }
    return h >>> 0

// plant one taxon, KEYED BY ITS GENUS ({Coprosma:'robusta'}) so siblings group; depth>0 gives it
//  two nested sub-taxa (a bifurcating frond — self-similar), so a chunk's interior is fractal
//   "here and there" rather than a flat row of names.  Count-driven depth, no blow-up.
//    A deterministic SPRINKLE of botanical traits rides some taxa (not all): %woodystem on ~1/3
//     (a presence-fact — 'woodystem ×N'), a %habit of three values on ~1/2 (a spread — chips), a
//      rare %endemic on ~1/6.  So a genus pane stops being one column of epithets and grows shared
//       facts + a spread the Vtuffing distiller can speak.  Genus stays the FIRST key (the mainkey).
Botany_plant(container, genus, epithet, depth):
    let sc = {}
    sc[genus] = epithet
    let hsh = this.Voro_hash(genus + '|' + epithet)
    if (hsh % 3 === 0) sc.woodystem = 1
    if (hsh % 2 === 1) {
        let habits = ['tree', 'shrub', 'vine']
        sc.habit = habits[this.Voro_hash(epithet) % 3]
    }
    if (hsh % 6 === 0) sc.endemic = 1
    let taxon = container.i(sc)
    taxon.c.vfamily = this.Botany_family(genus)
    if (depth > 0) {
        let forms = this.Botany_forms()
        this.Botany_plant(taxon, genus, epithet + ' ' + forms[0], depth - 1)
        this.Botany_plant(taxon, genus, epithet + ' ' + forms[1], depth - 1)
    }
    return taxon

// the LIVE GENERA census: the distinct genus mainkeys among w's loose flora, each with its
//  taxa.  There is NO container to ask any more — the census walks the data exactly the way
//   the crusher does (by mainkey).  Machinery under w (%req wrangle, %see claims) is not flora
//    and doesn't count.
VoroMitosis_taxa(w):
    let genera = this.Botany_genera()
    let by = {}
    for (const c of w.o()) {
        let mk = Object.keys(c.sc)[0]
        if (!genera.includes(mk)) continue
        if (!by[mk]) by[mk] = []
        by[mk].push(c)
    }
    return by

// found a genus: k species planted LOOSE under w keyed by the genus; the odd one carries a
//  nested form — the phylogeny "here and there" that gives each gang its self-similar texture.
VoroMitosis_found(w, genus, k):
    let eps = this.Botany_epithets()
    let gi = this.Botany_genera().indexOf(genus)
    if (gi < 0) gi = 0
    for (let s = 0; s < k; s++) this.Botany_plant(w, genus, eps[(gi * 3 + s) % eps.length], s % 2)

VoroMitosis_seed(w):
    this.VoroMitosis_found(w, 'Coprosma', 5)
    this.VoroMitosis_found(w, 'Veronica', 3)

// grow: every genus gains two loose species this beat; the first species of each sprouts a form
//  (and if it has one already, a sub-form) — the phylogeny deepening like a frond unfurling, and
//   the deepened taxon eventually outgrowing tiny-ness into its own little pane beside the gang.
//    Then AT MOST ONE genus past 8 species speciates: half its species RE-KEY to a daughter genus
//     (planted fresh under the new mainkey — a new cell gangs into being).  One division per beat
//      keeps it readable; the genera list caps the radiation.
VoroMitosis_grow(w, n):
    let genera = this.Botany_genera()
    let eps = this.Botany_epithets()
    let forms = this.Botany_forms()
    let by = this.VoroMitosis_taxa(w)
    for (const g of Object.keys(by)) {
        let base = by[g].length
        this.Botany_plant(w, g, eps[(n * 2 + base) % eps.length], 0)
        this.Botany_plant(w, g, eps[(n * 2 + base + 1) % eps.length], 0)
    }
    for (const g of Object.keys(by)) {
        let first = by[g][0]
        if (!first) continue
        let sub = first.o()
        if (!sub.length) {
            this.Botany_plant(first, g, first.sc[g] + ' ' + forms[n % forms.length], 0)
        } else {
            this.Botany_plant(sub[0], g, sub[0].sc[g] + ' ' + forms[(n + 1) % forms.length], 0)
        }
    }
    by = this.VoroMitosis_taxa(w)
    for (const g of Object.keys(by)) {
        let species = by[g]
        if (species.length < 8) continue
        let used = Object.keys(by)
        let name = genera.find(nm => !used.includes(nm))
        if (!name) break
        let half = species.slice(0, Math.floor(species.length / 2))
        for (const sp of half) {
            this.Botany_plant(w, name, sp.sc[g], 0)    // re-key to the daughter genus, keep the epithet
            sp.drop(sp)
        }
        w.c.mitosis_splits = (w.c.mitosis_splits || 0) + 1
        break
    }

// die: apoptosis — the smallest genus drops out entirely; its territory goes back to the neighbours.
VoroMitosis_die(w):
    let by = this.VoroMitosis_taxa(w)
    let names = Object.keys(by)
    if (names.length < 3) return
    names.sort((a, b) => by[a].length - by[b].length)
    w.c.mitosis_died = names[0]
    for (const sp of by[names[0]]) sp.drop(sp)

VoroMitosis_witness(w):
    let by = this.VoroMitosis_taxa(w)
    let names = Object.keys(by)
    if (names.length >= 4 && (w.c.mitosis_splits || 0) >= 2 && !(oa %see:'the flora radiated — more genera now than were founded and each new one split off an over-full parent')) i %see:'the flora radiated — more genera now than were founded and each new one split off an over-full parent'
    if (w.c.mitosis_died && !by[w.c.mitosis_died] && !(oa %see:'a genus went extinct mid-run and stayed gone — its range reclaimed by its neighbours')) i %see:'a genus went extinct mid-run and stayed gone — its range reclaimed by its neighbours'
    let ganged = names.filter(g => by[g].some(sp => sp.c.gang))
    if (names.length && ganged.length === names.length && !(oa %see:'the loose flora ganged itself by genus — one representative pane each and no container ever modelled')) i %see:'the loose flora ganged itself by genus — one representative pane each and no container ever modelled'
//#endregion

//#region scape — VoroScape: the MUSIC LIBRARY rendered as voronoi stained glass
// ══ VoroScape — a music library GROWS and the crush folds it to glass ══
//  The music twin of VoroMitosis (which watched abstract flora divide).  Here the cells are MUSIC:
//   %Artist panes hold their %Track songs, and the shelf grows LIVE — catalogs deepen (a pane thickens
//    in place) and new artists arrive (a new pane splits into the glass — mitosis's echo).  A pane's
//     weight is its track count: a deep catalog claims more room in the diagram, a two-track newcomer
//      is a sliver.  (The social layer — %Peer panes sharing tracks as edges — was cut 2026-07-10:
//       owner wants pure library glass here; edges belong to the Radio Books.)  Like VoroMitosis:
//        cells live DIRECTLY under w (the crusher folds any content container, so an umbrella would
//         swallow the whole scape as ONE chunk); crush armed c-side (no opt, nothing modelled), no
//          transport, no audio, count-driven determinism — runs anywhere a runner does.
//   beat 2  the library stands — three artists and their five tracks — a thin shelf of glass
//   beat 3  the catalogs deepen — five new tracks land across the SAME three panes — no new cells
//   beat 4  a new artist (Riverine) arrives with a catalog of three — a fourth pane splits in
//   beat 5  the shelf fills out — a fifth artist (Palegold) plus a straggler — sixteen tracks
//   beat 6  the crush folds every artist into a stuffed pane — the library arms as stained glass
VoroScape(A,w):
    w oai %req:wrangle,eternal
        await &VoroScape_drive,w,req
        req%ok = 1

async VoroScape_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.VoroScape_library(w)
        if (n === 3) this.VoroScape_deepen(w)
        if (n === 4) this.VoroScape_arrive(w, 'Riverine', ['Delta', 'Silt', 'Eddy'])
        if (n === 5) this.VoroScape_fill(w)
    }
    this.VoroScape_witness(w)
    await this.VoroScape_order(w)

// beat 2 — the library: three artists, each an %Artist pane holding its %Track songs (five in all).  The
//  crushable rule folds any container with children, so each artist becomes one voronoi pane; the tracks
//   ride inside it (a pane's interior).  A thin shelf — the growth beats thicken it.
VoroScape_library(w):
    let moon = w.i({ Artist: 1, name: 'Moonlit' })
    let tide = this.VoroScape_track(moon, 'Tide')
    let spot = this.VoroScape_section(tide, 'the-spot', 3, 6)
    this.VoroScape_section(spot, 'cymbal', 4, 5)
    this.VoroScape_track(moon, 'Halo')
    let fern = w.i({ Artist: 1, name: 'Fernway' })
    this.VoroScape_track(fern, 'Root')
    this.VoroScape_track(fern, 'Frond')
    let vox = w.i({ Artist: 1, name: 'Voxhall' })
    this.VoroScape_track(vox, 'Echo')

// a track with a deterministic SPRINKLE of musical facets (the music twin of Botany's traits —
//  no randomness, hashed off the title): a %year of three vintages (a spread — chips), %live on
//   ~1/2 and %remaster on ~1/3 (presence-facts).  So an Artist pane says more than a column of titles.
VoroScape_track(artist, title):
    let sc = { Track: 1, title: title }
    let hsh = this.Voro_hash('Track|' + title)
    let years = ['1998', '2007', '2019']
    sc.year = years[hsh % 3]
    if ((Math.floor(hsh / 4)) % 2 === 0) sc.live = 1
    if (hsh % 3 === 0) sc.remaster = 1
    return artist.i(sc)

// give a song real DEPTH — a nested %What time-region (a section, and a lick INSIDE it) — so the
//  scape carries a genuine Track/What/What C** for the crush to fold into nested craters (the
//   human, 2026-07-15: "add a Track/What:the-spot start_at:3 end_at:6 / What:cymbal start_at:4
//    end_at:5").  %What:<name> — the mainkey carries the section name; start_at|end_at are its span.
VoroScape_section(host, name, start_at, end_at):
    return host.i({ What: name, start_at: start_at, end_at: end_at })

// beat 3 — the catalogs deepen: five new tracks land across the SAME three panes.  No new cells —
//  a pane's weight is its track count, so the existing glass visibly thickens in place.
VoroScape_deepen(w):
    let moon = this.VoroScape_artist(w, 'Moonlit')
    this.VoroScape_track(moon, 'Drift')
    this.VoroScape_track(moon, 'Neon')
    let fern = this.VoroScape_artist(w, 'Fernway')
    this.VoroScape_track(fern, 'Moss')
    let vox = this.VoroScape_artist(w, 'Voxhall')
    this.VoroScape_track(vox, 'Static')
    this.VoroScape_track(vox, 'Choir')

// a new artist arrives with a whole catalog — a NEW pane splits into the glass (mitosis's echo).
VoroScape_arrive(w, name, titles):
    let a = w.i({ Artist: 1, name: name })
    for (const t of titles) this.VoroScape_track(a, t)
    return a

// beat 5 — the shelf fills out: a fifth artist lands and a straggler track joins Fernway (growth is
//  not always tidy — a pane can gain one song while a whole newcomer arrives beside it).
VoroScape_fill(w):
    this.VoroScape_arrive(w, 'Palegold', ['Ingot', 'Gleam'])
    let fern = this.VoroScape_artist(w, 'Fernway')
    this.VoroScape_track(fern, 'Bloom')

// an artist pane by name (the growth beats and the witness both address panes this way).
VoroScape_artist(w, name):
    return w.o({ Artist: 1 }).find(x => x.sc.name === name)

// the track count of a named artist — the pane's WEIGHT, what the voronoi reads off its size.
VoroScape_count(w, name):
    let a = this.VoroScape_artist(w, name)
    return a ? a.o({ Track: 1 }).length : 0

// ── the witness — each %see is a per-beat OBSERVATION gated to its step (n === K) reading the LIVE truth
//  of that beat, so it appears once and DROPS as the story moves on.  The drop IS the signal: beat 4's
//   "it lights up as a hub" (weight 2) gives way to beat 5's "the hub cools" (weight 1) — the same track,
//    re-weighted live.  Do NOT persist a claim past its beat (that is the old %witnessed noise reborn).
VoroScape_witness(w):
    let n = (this.c.run)?.c.step_n
    let artists = w.o({ Artist: 1 })
    let tracks = []
    for (const a of artists) for (const t of a.o({ Track: 1 })) tracks.push(t)
    // beat 2: the library stands — three artists, five tracks: a thin shelf of glass.
    if (n === 2 && artists.length === 3 && tracks.length === 5 && !(oa %see:'the library stands — three artists and five tracks — a shelf of glass with no light through it yet')) i %see:'the library stands — three artists and five tracks — a shelf of glass with no light through it yet'
    // beat 3: the catalogs deepen — 5 -> 10 tracks across the SAME three panes (Moonlit now four deep).
    if (n === 3 && artists.length === 3 && tracks.length === 10 && this.VoroScape_count(w, 'Moonlit') === 4 && !(oa %see:'the catalogs deepen — five new tracks land across the same three panes — the glass thickens in place')) i %see:'the catalogs deepen — five new tracks land across the same three panes — the glass thickens in place'
    // beat 4: a fourth pane splits into the glass — a whole newcomer catalog beside the elders.
    if (n === 4 && artists.length === 4 && tracks.length === 13 && this.VoroScape_count(w, 'Riverine') === 3 && !(oa %see:'a new artist arrives with a catalog of three — a fourth pane splits into the glass')) i %see:'a new artist arrives with a catalog of three — a fourth pane splits into the glass'
    // beat 5: the shelf fills out — a fifth artist plus Fernway's straggler: 16 tracks across 5 panes.
    if (n === 5 && artists.length === 5 && tracks.length === 16 && this.VoroScape_count(w, 'Palegold') === 2 && this.VoroScape_count(w, 'Fernway') === 4 && !(oa %see:'the shelf fills out — five artists and sixteen tracks — every pane heavy with song and ready to crush')) i %see:'the shelf fills out — five artists and sixteen tracks — every pane heavy with song and ready to crush'
    // the fold is IMPOSED by Story (%useVoroCyto) and self-reports in w:Voronoiology — VoroScape asserts
    //  only its own library truths (counts, arrivals, growth), never the fold.  See fig.1 in Story.

// float A:VoroScape to the front of H/* so the Run snap stays readable (MusuSkip_order's twin).
async VoroScape_order(w):
    let As = H.o({ A: 1 })
    if (!As.length) return
    let first = (a) => (a.sc.A === 'VoroScape') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)
//#endregion

//#region test — VoroTest: the fold|gang|family RULES themselves, shown on a gallery of shapes
// ══ VoroTest — a bench of deliberately different data shapes, all crushed in ONE world ════════════
//  The owner's ask: "show the rules of the way we fold|stuff etc in a VoroTest ... lots of instances
//   of data having a Voro compute in parallel ... utterly universal."  Where VoroMitosis watches ONE
//    flora move and VoroScape watches ONE library grow, VoroTest sets a GALLERY of canonical shapes
//     side by side and crushes them together — so a reader learns the crush POLICY by reading one
//      fixture: which shapes gang, which fold, which stay bare, and where each threshold bites.
//  The vocabulary is neutral GEOLOGY|BOTANY (no music — the point is the shape, not the domain): the
//   crush is a pure function of STRUCTURE (mainkey homogeneity, child count, container depth), so any
//    domain that keys the same way folds the same way.  Every shape sits LOOSE under w keyed by its
//     own mainkey (VoroMitosis's "bigger looser board") — a container would fold as ONE outer pane and
//      hide the inner rule, so the gallery is flat and the crusher DISCOVERS each shape's fold.
//  Deterministic throughout (traits hashed off names via Voro_hash — no randomness, fixtures byte-
//   stable).  Its subject IS the crush, so like VoroMitosis it DRIVES Voro_crush_scan inline (its
//    do_fn), same-beat, because its %see claims read the fold facts the crush just stamped.  The
//     world MUST be named VoroTest (Story dispatches the do_fn by the world name).
//   beat 2  the bench is laid — every shape built — crush once — the fold verdicts read
//   beat 3  MUTATIONS — arrivals grow the flock — goners leave the mix — the gradient bends — one
//            ingot pops — recrush — the readings MOVE
//   beat 4  a QUIET beat — recrush with no change — the readings hold steady (the fold is stable)
//  The shapes and the RULE each demonstrates (Voro.g line refs):
//   1 flock    12 %Boulder loose leaves        → gang-fold by mainkey        (Voro_gang_fold ~:1199)
//   2 mix      7 %Fern + 5 %Moss + 3 loners    → two gangs beside bare leaves (Voro_gang_min ~:1241)
//   3 motley   8 distinct mainkeys one each    → nothing gangs — all bare    (gang of 1 < min)
//   4 gradient 10 %Stratum sweeping a number   → one gang carrying a spread  (Voro_model_axis ~:848)
//   5 groves   3 %Grove each holding a subflock→ container-fold — no descent (Voro_crushable ~:1311)
//   6 edges    a 2-member %Pair + empty %Void  → tiny fallback-fold vs bare  (gang_fold else ~:1220)
//   7 swarm    5 varying %req + 2 %Cairn       → noisy gang looser than plain (Voro_gang_min noisy)
//   8 genus    5 genera × 4 loose taxa (=20)   → UNPINNED governor finds clades (Voro_crush_scan ~:52)
//   9 popped   3 %Ingot then pop one (beat 3)  → surf intent + spill re-gang  (crush_walk popped ~:1129)
//  10 families 4 genus gangs sharing a %clade   → region groups sibling folds  (Voro_model_family ~:805)
//  11 relics   2 bare %Relic × 6 facts + %Coin  → +N overflow marks crowded-out (Voro_model_loud_from)
VoroTest(A,w):
    w oai %req:wrangle,eternal
        await &VoroTest_drive,w,req
        req%ok = 1

async VoroTest_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.VoroTest_bench(w)
        if (n === 3) this.VoroTest_mutate(w)
        // crush EACH %Example's own data world in turn.  Voro_crush_scan writes the standard
        //  %Voronoiology (census + Se:scape|census + %Family rows + the off-snap %model) into the world's
        //   PARENT — here the Example — so every Example ends the beat holding its own Voronoiology
        //    beside its data.  No Cyto: the guts run headless, the snap of each Example IS the reading.
        //  AWAIT each: the Se grasp|model ride INSIDE the crush tail and write snapped rows, so the beat
        //   must let them settle before it snaps (VoroMitosis's discipline, once per Example).
        if (n >= 2) {
            // crush each Example at a FIXED level 2 — a unit harness pins the level so every dataset
            //  meets the SAME fold rule (non-noisy gang_min 3), not the viewport auto-leveller that
            //   would leave a small isolated world's leaves un-ganged.  The ONE exception is the genus
            //    example (#18): it is crushed UNPINNED so its twenty leaves overrun the density budget
            //     and the governor ESCALATES a level on its own — the governor discovering the clades is
            //      exactly what that shape proves, so pinning it would defeat the test.
            for (const ex of w.o({ Example: 1 })) {
                let dw = this.VoroTest_dataworld(ex)
                if (!dw) continue
                if (ex.sc.name === 'genus') { await this.Voro_crush_scan(dw, 0) } else { await this.Voro_crush_scan(dw, 0, 2) }
            }
        }
        if (n === 2) this.VoroTest_witness_bench(w)
        if (n === 3) this.VoroTest_witness_mutate(w)
        if (n === 4) this.VoroTest_witness_quiet(w)
    }

// VoroTest_example — mint one %Example (a labelled dataset case) holding its own DATA world; the crush
//  later hangs a %Voronoiology sibling beside that data world (both children of the Example), so the
//   Example is a self-contained (input world, output world) pair.  c.up is stamped by hand — a nested
//    world under a plain particle does not inherit it, and Voro_report reads w.c.up to place the output.
//  Returns the DATA world to plant into.
VoroTest_example(w, name):
    let ex = w.i({ Example: 1, name: name })
    let dw = ex.i({ w: name })
    dw.c.up = ex
    return dw

// VoroTest_dataworld — an Example's DATA world: its w child that is NOT the crush's Voronoiology output.
VoroTest_dataworld(ex):
    return ex.o({ w: 1 }).find(c => c.sc.w !== 'Voronoiology')

// VoroTest_dataworld_named — reach the data world of the Example called <name> (for the mutation beat).
VoroTest_dataworld_named(w, name):
    let ex = w.o({ Example: 1, name: name })[0]
    return ex ? this.VoroTest_dataworld(ex) : null

// VoroTest_seen — an Example's own Voronoiology output world (null before its first crush).
VoroTest_seen(w, name):
    let ex = w.o({ Example: 1, name: name })[0]
    return ex ? ex.o({ w: 'Voronoiology' })[0] : null

// ── the neutral vocabulary — geology|botany, keyed so shape (not domain) drives the fold ──────────
//  fixed lists ARE the determinism (no randomness): each list names one shape's members, and a
//   deterministic trait sprinkle (hashed off the member's own name) gives a gang shared FACTS and a
//    SPREAD to distil — so a pane speaks like real data, not a bare column of names.
VoroTest_grades():
    return ['coarse','medium','fine','pebble','cobble','angular','rounded','platy','blocky','tabular','massive','vesicular']

// plant one %Boulder loose under w — the HOMOGENEOUS FLOCK (shape 1).  A shared %stratum FACT the
//  whole flock agrees on, a %grade SPREAD that varies member to member, a %vein presence-fact on
//   ~1/3 — so the gang's pane says one fact once and a spread of the rest.  Boulder stays first key.
VoroTest_boulder(w, grade):
    let sc = { Boulder: 1, grade: grade, stratum: 'Miocene' }
    let hsh = this.Voro_hash('Boulder|' + grade)
    if (hsh % 3 === 0) sc.vein = 1
    return w.i(sc)

// plant a leaf of some mainkey loose under w with a naming value on its key — the MIX + MOTLEY
//  shapes (2 and 3).  The mainkey IS the type; the value names the instance ({Fern:'silver'}).
VoroTest_leaf(w, mainkey, name):
    let sc = {}
    sc[mainkey] = name
    return w.i(sc)

// shape 1 — the flock: twelve %Boulder leaves, one mainkey, some shared some varying.  Under the
//  escalated governor (this bench blows the 15-visible budget) non-noisy leaves gang at 3, so the
//   twelve fold behind ONE representative pane carrying fold_n 12 — the plainest gang rule.
VoroTest_flock(w):
    let grades = this.VoroTest_grades()
    for (let i = 0; i < 12; i++) this.VoroTest_boulder(w, grades[i])

// shape 2 — the mix: two families that clear the gang threshold (7 %Fern + 5 %Moss) beside three
//  LONERS of one each (%Lichen %Sedge %Rush).  Fern gangs, Moss gangs, each loner is a gang of one
//   below min so it stands as a bare leaf — two folds and three bare nodes in one neighbourhood.
VoroTest_mix(w):
    let fern = ['silver','hen-and-chicken','crown','shield','hard','ring','kidney']
    let moss = ['sphagnum','pincushion','feather','fork','sheet']
    for (const f of fern) this.VoroTest_leaf(w, 'Fern', f)
    for (const m of moss) this.VoroTest_leaf(w, 'Moss', m)
    this.VoroTest_leaf(w, 'Lichen', 'reindeer')
    this.VoroTest_leaf(w, 'Sedge', 'carnation')
    this.VoroTest_leaf(w, 'Rush', 'soft')

// shape 3 — the motley: eight leaves of eight DIFFERENT mainkeys, one each.  Every mainkey is a
//  gang of one, always below min, so NOTHING folds — eight bare nodes prove the fold needs a
//   population, not a lone instance.  Distinct rock types, each its own kind.
VoroTest_motley(w):
    let kinds = { Quartz: 'milky', Basalt: 'columnar', Slate: 'roofing', Gneiss: 'banded', Chert: 'nodular', Shale: 'fissile', Flint: 'grey', Marl: 'calcareous' }
    for (const k of Object.keys(kinds)) this.VoroTest_leaf(w, k, kinds[k])

// shape 4 — the gradient: ten %Stratum leaves whose %depth sweeps 1..10 smoothly (a shared %unit
//  fact besides).  They gang into ONE pane whose Vtuffing SPREAD lays the ten depths out in order —
//   the shape a semantic ordering|trail reads best (a continuous run, not a scatter of kinds).
VoroTest_gradient(w):
    for (let i = 1; i <= 10; i++) w.i({ Stratum: 1, depth: '' + i, unit: 'metres' })

// shape 5 — the groves: three %Grove containers, each holding a small homogeneous sub-flock (four
//  %Sapling leaves).  A Grove has children so it is NOT tiny → Voro_crushable folds EACH grove to
//   its own pane and the crusher STOPS there (no descent — folded here = folded on the canvas).  So
//    three groves = three panes, and the saplings ride INSIDE, never ganged across groves — the
//     honest answer to "what does the crusher do with depth": it folds the outermost container.
VoroTest_groves(w):
    let names = ['Kauri','Rimu','Totara']
    for (const gn of names) {
        let grove = w.i({ Grove: 1, name: gn })
        for (let s = 0; s < 4; s++) grove.i({ Sapling: 1, age: '' + (s + 1) })
    }

// shape 6 — the edges: a %Pair of two members (below the tiny-container threshold) and an EMPTY
//  %Void.  The Pair is tiny (≤3 all-leaf) so it rides loose[] and never forms a gang of one — but
//   the gang-fold FALLBACK folds a tiny CONTAINER-with-children to its own little pane (a lone
//    thing keeps its cell).  The Void has no children so Voro_crushable refuses it and it stands
//     BARE — the two ends of the fold: the smallest thing that still folds vs the thing that cannot.
VoroTest_edges(w):
    let pair = w.i({ Pair: 1, name: 'twins' })
    pair.i({ Pebble: 1, name: 'east' })
    pair.i({ Pebble: 1, name: 'west' })
    w.i({ Void: 1, name: 'hollow' })

// shape 7 — the swarm: the NOISY assertion|request confetti folded as a GROUP (Voro.g task 5 / roster
//  #6).  This is the ONE fold rule mix's gang path does NOT isolate.  mix already proves same-mainkey-
//   varying-value leaves gang behind a rep (Fern, Moss) — that IS the swarm's fold mechanism, shared
//    code (Voro_gang_fold).  What is DISTINCT is the THRESHOLD: %req|%witnessed|%see|%reached are the
//     noisy families and Voro_gang_min gangs them looser (min 2 under the escalated governor) than an
//      ordinary mainkey (min 3).  So at the bench's fixed L2 a swarm of five VARYING requests folds
//       behind one representative while an ORDINARY pair of two cairns stays two bare nodes — the fold
//        needs a smaller population when the family is noise.  The vocabulary breaks the geology rule on
//         purpose: the noisy policy is DEFINED for these exact internal mainkeys, so the shape must use
//          one of them (a childless %req rides the structural branch into loose[] and gangs there).
VoroTest_swarm(w):
    let reqs = ['awaitbuf', 'flush', 'drain', 'settle', 'retry']
    for (const r of reqs) this.VoroTest_leaf(w, 'req', r)
    this.VoroTest_leaf(w, 'Cairn', 'stack')
    this.VoroTest_leaf(w, 'Cairn', 'marker')

// shape 8 — the genus discovery: twenty loose taxa across FIVE genera keyed by genus (no container),
//  reusing the flora vocabulary.  Crushed UNPINNED (see the drive) so the density budget forces the
//   escalation: at level 0 no ordinary mainkey gangs (min 99) and all twenty stand visible, blowing the
//    15-cell budget; the governor escalates to level 1 (non-noisy min 3) where the five genera each gang
//     behind one representative — the machine EARNS the clades from flat leaves, exactly VoroMitosis's
//      governor move, proven here in one beat on a fixed dataset (#18, the only auto-levelled example).
VoroTest_genus(w):
    this.VoroMitosis_found(w, 'Coprosma', 4)
    this.VoroMitosis_found(w, 'Veronica', 4)
    this.VoroMitosis_found(w, 'Metrosideros', 4)
    this.VoroMitosis_found(w, 'Kunzea', 4)
    this.VoroMitosis_found(w, 'Leptospermum', 4)

// shape 10 — botanical families (#19): four genus gangs that a SECONDARY property ropes into two clades.
//  Each taxon carries a shared %clade fact (Metrosideros + Kunzea = Myrtales, Olearia + Brachyglottis =
//   Asterales).  The model's `region` is the grasp's the:family = each cell's VALUE on the dominant
//    SHARED key (here %clade, carried by all four reps), so sibling gangs of one clade get the SAME
//     region while the two clades differ — the render buckets its washes by exactly this grouping, one
//      level ABOVE the mainkey.  region lives OFF-SNAP (never projected to the Voronoiology row, so no
//       fixture churns); the gate reads it via VoroTest_model_of.  Genus stays the first key (mainkey).
VoroTest_families(w):
    this.VoroTest_clade_gang(w, 'Metrosideros', 'Myrtales', ['excelsa', 'robusta', 'umbellata'])
    this.VoroTest_clade_gang(w, 'Kunzea', 'Myrtales', ['ericoides', 'amathicola', 'linearis'])
    this.VoroTest_clade_gang(w, 'Olearia', 'Asterales', ['albida', 'solandri', 'furfuracea'])
    this.VoroTest_clade_gang(w, 'Brachyglottis', 'Asterales', ['repanda', 'greyi', 'rotundifolia'])

// plant one genus gang of three taxa, each carrying the shared %clade fact.  sc[genus] is set FIRST so
//  the genus is the mainkey; %clade rides as an ordinary second key (the shared property region groups by).
VoroTest_clade_gang(w, genus, clade, epithets):
    for (const e of epithets) {
        let sc = {}
        sc[genus] = e
        sc.clade = clade
        w.i(sc)
    }

// shape 11 — the loner showing ALL its ugly bits (#29): two %Relic leaves that stand BARE (a pair is
//  below the ordinary gang min 3, so no gang forms) merge into one bare family of two.  Each carries SIX
//   distinct properties, so the family's loud pool holds far more DISTINCT claims than the K=4 loud cap
//    keeps — the model marks the crowded-out tail with a +N `over` count instead of dropping it silently.
//   A tray of three %Coin gangs beside them: a purely-bare world (gangs:0, folded:0) never wakes the
//    grasp|model (the "don't stand an empty Seem on a non-Voro graph" guard, Voro_crush_scan ~:86), so
//     the coins are the fold that wakes the model — the rich bare Relics are what it must not silence.
//   This is the "no hiding stuff" honesty gate: nothing vanishes from a fold without being tallied.
VoroTest_relics(w):
    w.i({ Relic: 'astrolabe', metal: 'brass', era: 'renaissance', origin: 'Nuremberg', use: 'navigation', state: 'tarnished', rarity: 'museum' })
    w.i({ Relic: 'sextant', metal: 'silver', era: 'georgian', origin: 'London', use: 'surveying', state: 'pristine', rarity: 'auction' })
    for (const d of ['penny', 'florin', 'crown']) w.i({ Coin: d, metal: 'bronze' })

// shape 9 — the popped intent: three %Ingot leaves that gang at the bench (L2 min 3).  The mutate beat
//  pops ONE by hand (c.popped — the surf intent the crush must respect); that leaf then stands OUT of
//   the fold (the popped-tiny branch skips it from the gang pool) and the remaining TWO re-gang at the
//    RELAXED spill threshold (min 2, because a sibling popped) — the surf's contract "a few pop out, the
//     REST stays one pane".  Two remaining is below the ordinary min 3, so the re-gang PROVES the spill
//      relax fired; without it the pair would stand bare (#23).
VoroTest_popped(w):
    for (const nm of ['bar', 'coin', 'bead']) this.VoroTest_leaf(w, 'Ingot', nm)

// lay the whole bench — nine shapes, each in its OWN %Example, so the crush computes nine worlds in
//  parallel and the snap shows the datasets side by side, each beside its own Voronoiology reading.
VoroTest_bench(w):
    this.VoroTest_flock(this.VoroTest_example(w, 'flock'))
    this.VoroTest_mix(this.VoroTest_example(w, 'mix'))
    this.VoroTest_motley(this.VoroTest_example(w, 'motley'))
    this.VoroTest_gradient(this.VoroTest_example(w, 'gradient'))
    this.VoroTest_groves(this.VoroTest_example(w, 'groves'))
    this.VoroTest_edges(this.VoroTest_example(w, 'edges'))
    this.VoroTest_swarm(this.VoroTest_example(w, 'swarm'))
    this.VoroTest_genus(this.VoroTest_example(w, 'genus'))
    this.VoroTest_popped(this.VoroTest_example(w, 'popped'))
    this.VoroTest_families(this.VoroTest_example(w, 'families'))
    this.VoroTest_relics(this.VoroTest_example(w, 'relics'))

// beat 3 — the mutations, so a reader sees the readings MOVE: three arrivals swell the flock example
//  (12→15 Boulders), two goners leave the mix example (Fern loses two, 7→5), and one gradient member
//   bends its %depth off the smooth run (10→99, an outlier the spread must show).  Each edits its OWN
//    Example's data world, then the drive recrushes every Example and the deltas land per Voronoiology.
VoroTest_mutate(w):
    let flock = this.VoroTest_dataworld_named(w, 'flock')
    if (flock) { let extra = ['spheroidal','jointed','weathered']; for (const g of extra) this.VoroTest_boulder(flock, g) }
    let mix = this.VoroTest_dataworld_named(w, 'mix')
    if (mix) {
        let ferns = mix.o().filter(c => Object.keys(c.sc)[0] === 'Fern')
        if (ferns.length >= 2) { ferns[0].drop(ferns[0]); ferns[1].drop(ferns[1]) }
    }
    let grad = this.VoroTest_dataworld_named(w, 'gradient')
    if (grad) {
        let bent = grad.o().filter(c => Object.keys(c.sc)[0] === 'Stratum').find(s => s.sc.depth === '10')
        if (bent) bent.sc.depth = '99'
    }
    // the popped example (#23): pop ONE ingot by hand — c.popped is the surf intent the recrush reads.
    //  It stands out of the fold and the remaining two re-gang at the relaxed spill threshold.
    let pop = this.VoroTest_dataworld_named(w, 'popped')
    if (pop) {
        let ingots = pop.o().filter(c => Object.keys(c.sc)[0] === 'Ingot')
        if (ingots.length) ingots[0].c.popped = 1
    }

// ── the counters — a %see reads the LIVE fold facts, so each claim is what the crush actually did ─
//  the gang of a mainkey: the one representative that wears c.stuff + c.gang for that mainkey (or
//   null if the population never reached the threshold).  The whole roster the crusher elected.
VoroTest_gang_of(w, mainkey):
    return w.o().find(c => Object.keys(c.sc)[0] === mainkey && c.c.stuff && c.c.gang)

// the count of BARE leaves of a mainkey — loose leaves the crush left standing (no fold stamp, not
//  swallowed as a represented gang member).  A motley kind reads 1 here; a ganged kind reads 0.
VoroTest_bare_of(w, mainkey):
    return w.o().filter(c => Object.keys(c.sc)[0] === mainkey && !c.c.stuff && !c.c.represented && !c.o().length).length

// the folded CONTAINERS of a mainkey — a Grove|Pair that Voro_crushable stamped a pane (c.stuff and
//  it has real children, so it is a container fold, not a loose-leaf gang).
VoroTest_panes_of(w, mainkey):
    return w.o().filter(c => Object.keys(c.sc)[0] === mainkey && c.c.stuff && !c.c.gang && c.o().length > 0).length

// beat 2 — the bench verdicts, each gated on n === 2 and the LIVE crush stamps (a %see drops after
//  its step, so it is this beat's OBSERVATION not a latch).  Every sentence uses an em-dash — no
//   commas (the peel parser splits on them).  Only stable outputs are asserted (fold|gang|bare
//    counts + census presence); the per-family model readings (order|drift) are the SE-UP agent's
//     and get wired at integration.
// VoroTest_model_of — an Example's off-snap %model tree (rides on its data world's c.voro_model).
VoroTest_model_of(w, name):
    let dw = this.VoroTest_dataworld_named(w, name)
    return dw ? dw.c.voro_model : null

// beat 2 — the bench verdicts, read PER EXAMPLE (each dataset scanned in its own data world, each
//  reading in its own Voronoiology).  A %see drops after its step, so it is this beat's OBSERVATION.
//   Em-dash, never a comma (the peel parser splits on commas).  The fixtures carry the full detail;
//    these sentences name the cross-example rules a reader should take away.
VoroTest_witness_bench(w):
    // every Example crushed to its OWN reading world — each data world beside its own Voronoiology.
    let exs = w.o({ Example: 1 })
    // a crushed Example carries a %Voro census head in its own Voronoiology — true even for the motley
    //  (which folds NOTHING, so it has a head but zero cells); count that, not cells.  Gate seen ===
    //   exs so the claim survives every new shape added to the bench — never a hard-coded roster size.
    let seen = exs.filter(ex => { let rw = ex.o({ w: 'Voronoiology' })[0]; return rw && rw.o({ Voro: 1 }).length > 0 }).length
    if (exs.length >= 6 && seen === exs.length && !(oa %see:'every example computed its own Voronoiology — each dataset crushed in parallel to its own reading world beside its data')) i %see:'every example computed its own Voronoiology — each dataset crushed in parallel to its own reading world beside its data'
    // a population folds — a dozen boulders behind one pane — where eight lone kinds cannot.
    let flock = this.VoroTest_dataworld_named(w, 'flock')
    let motleyW = this.VoroTest_dataworld_named(w, 'motley')
    let boulders = flock ? this.VoroTest_gang_of(flock, 'Boulder') : null
    let motley = ['Quartz','Basalt','Slate','Gneiss','Chert','Shale','Flint','Marl']
    let bare = 0
    for (const k of motley) bare = bare + (motleyW ? this.VoroTest_bare_of(motleyW, k) : 0)
    if (boulders && (boulders.c.gang || []).length === 12 && bare === 8 && !(oa %see:'a population folds where lone kinds cannot — twelve boulders gang behind one pane while eight single kinds stay bare below the minimum')) i %see:'a population folds where lone kinds cannot — twelve boulders gang behind one pane while eight single kinds stay bare below the minimum'
    // the groves keep their own panes — the crush folds the outermost container and never descends.
    let grovesW = this.VoroTest_dataworld_named(w, 'groves')
    let groves = grovesW ? this.VoroTest_panes_of(grovesW, 'Grove') : 0
    if (groves === 3 && !(oa %see:'the groves keep their own panes — three nested containers fold outermost into three cells and the crush never descends inside')) i %see:'the groves keep their own panes — three nested containers fold outermost into three cells and the crush never descends inside'
    // the MODEL discovers order from the DATA: the gradient example's model finds depth as a numeric
    //  axis and pins the ten strata end to end — the trail a render would otherwise derive from pixels.
    let gmodel = this.VoroTest_model_of(w, 'gradient')
    let gfams = gmodel ? gmodel.o({ Family: 1 }) : []
    let gradfam = gfams.find(f => f.sc.order_by === 'depth')
    if (gradfam && gradfam.sc.axis === 'num' && gradfam.sc.n === '10' && gradfam.sc.from && gradfam.sc.to && gradfam.sc.from !== gradfam.sc.to && !(oa %see:'the model discovers order from the data — the gradient example reads depth as a numeric axis and pins its ten strata from one end anchor to the other')) i %see:'the model discovers order from the data — the gradient example reads depth as a numeric axis and pins its ten strata from one end anchor to the other'
    // #6 the swarm: the noisy families fold looser than the ordinary ones.  Five requests of VARYING
    //  value gang behind one representative (noisy min 2 at L2) while two cairns stay bare (ordinary
    //   min 3) — the un-same folded as a group where an ordinary pair of the same size will not.
    let sw = this.VoroTest_dataworld_named(w, 'swarm')
    let reqgang = sw ? this.VoroTest_gang_of(sw, 'req') : null
    let reqvals = {}
    for (const p of (reqgang ? (reqgang.c.gang || []) : [])) reqvals['' + p.sc.req] = 1
    let cairns = sw ? this.VoroTest_bare_of(sw, 'Cairn') : 0
    if (reqgang && (reqgang.c.gang || []).length === 5 && Object.keys(reqvals).length === 5 && cairns === 2 && !(oa %see:'the un-same folds as a group — five requests of varying value gang behind one representative where two ordinary cairns stay bare below the ordinary minimum')) i %see:'the un-same folds as a group — five requests of varying value gang behind one representative where two ordinary cairns stay bare below the ordinary minimum'
    // #18 the governor discovers the clades: the genus example is crushed UNPINNED, so its twenty loose
    //  taxa overran the 15-cell budget and the governor ESCALATED to level 1 (the pinned examples sit at
    //   L2) — where the five genera each ganged behind one representative.  crush_level === 1 proves the
    //    escalation was the density budget's own doing, not a pinned level.
    let g = this.VoroTest_dataworld_named(w, 'genus')
    let genera = ['Coprosma', 'Veronica', 'Metrosideros', 'Kunzea', 'Leptospermum']
    let clades = g ? genera.filter(gn => this.VoroTest_gang_of(g, gn)).length : 0
    if (g && g.c.crush_level === 1 && clades === 5 && !(oa %see:'the governor discovered the clades — twenty loose leaves overran the density budget so the crush escalated one level on its own and five genera each ganged behind a representative')) i %see:'the governor discovered the clades — twenty loose leaves overran the density budget so the crush escalated one level on its own and five genera each ganged behind a representative'
    // #14 a fact is not a spread: the flock reads grade as the SPREAD it orders by (twelve distinct
    //  values) while stratum Miocene — the one value all twelve share — rides as a shared Loud FACT.
    //   The model buckets the two kinds of claim apart, so the pane can speak a fact once and lay a
    //    spread in order.  Read off the snapped row (order_by is the spread key; the Loud carries the v).
    let fseen = this.VoroTest_seen(w, 'flock')
    let brow = fseen ? fseen.o({ Family: 'Boulder' })[0] : null
    let stratLoud = brow ? brow.o({ Loud: 'stratum' })[0] : null
    if (brow && brow.sc.order_by === 'grade' && stratLoud && stratLoud.sc.v === 'Miocene' && !(oa %see:'the model tells a fact from a spread — the flock orders by grade the spread that varies while stratum Miocene the value all twelve share rides as a shared fact')) i %see:'the model tells a fact from a spread — the flock orders by grade the spread that varies while stratum Miocene the value all twelve share rides as a shared fact'
    // #30 a minority-but-loud trait keeps its COUNT: the flock's %vein rides ~a third of the strata (the
    //  `hsh % 3` seed), a claim the gang's ONE rep cell structurally cannot count.  The share cut pools
    //   the MEMBERS, so the snapped Loud:vein row carries `share:N` — present IFF partial (0 < N < n),
    //    so its very presence proves vein is a minority reading not the family-wide one.  Read off the
    //     SNAP (share is projected).  Reddens if rep-pooled loudness swallowed the count (no share) or
    //      vein went universal (share === n, suppressed).
    let veinLoud = brow ? brow.o({ Loud: 'vein' })[0] : null
    let veinShare = veinLoud ? ((+veinLoud.sc.share) || 0) : 0
    let bn = brow ? ((+brow.sc.n) || 0) : 0
    if (veinLoud && veinShare > 0 && veinShare < bn && !(oa %see:'a minority-but-loud trait keeps its count — the flock names vein and marks how many of the strata carry it not all so the claim the rep cannot count survives as a share')) i %see:'a minority-but-loud trait keeps its count — the flock names vein and marks how many of the strata carry it not all so the claim the rep cannot count survives as a share'
    // #28 census-storm slot capture: pin the flock's Family:Boulder row NODE now, so the mutate beat can
    //  prove it is the VERY SAME row (not a torn-down-and-rebuilt one) after its count slides.  c-side
    //   ref, survives across beats like VoroRadio's radio_picks — the model's find-or-create keeps it.
    w.c.census_id = brow
    // #19 sibling folds grouped by a SECONDARY property: the families example's four genus gangs share a
    //  %clade fact, so the model's region (the grasp's the:family = each cell's value on the dominant
    //   SHARED key) equals WITHIN a clade and differs ACROSS.  Read off the OFF-SNAP model (region is
    //    never projected to the snap).  Reddens if the grasp picked a per-gang key (regions would split)
    //     or never set region (reg === fold name).
    let fmodel = this.VoroTest_model_of(w, 'families')
    let ffams = fmodel ? fmodel.o({ Family: 1 }) : []
    let rMet = (ffams.find(x => x.sc.Family === 'Metrosideros') || { sc: {} }).sc.region
    let rKun = (ffams.find(x => x.sc.Family === 'Kunzea') || { sc: {} }).sc.region
    let rOle = (ffams.find(x => x.sc.Family === 'Olearia') || { sc: {} }).sc.region
    let rBra = (ffams.find(x => x.sc.Family === 'Brachyglottis') || { sc: {} }).sc.region
    if (rMet && rMet === rKun && rOle && rOle === rBra && rMet !== rOle && !(oa %see:'sibling folds group by a shared property — Metrosideros and Kunzea land in one region while Olearia and Brachyglottis land in another so a secondary clade ropes the gangs the mainkey keeps apart')) i %see:'sibling folds group by a shared property — Metrosideros and Kunzea land in one region while Olearia and Brachyglottis land in another so a secondary clade ropes the gangs the mainkey keeps apart'
    // #29 nothing dropped silently: the relics example is two bare %Relic leaves (a pair below the gang
    //  min 3) with six distinct properties each, so the family's loud pool holds far more DISTINCT claims
    //   than the K=4 cap keeps.  The snapped row must carry the four loudest AND an `over` count of the
    //    crowded-out tail — read off the SNAP (over is projected, so this proves it reached the fixture).
    //     Reddens if the cap silently dropped the tail (over absent) or the pair ganged (no bare family).
    let rseen = this.VoroTest_seen(w, 'relics')
    let relF = rseen ? rseen.o({ Family: 'Relic' })[0] : null
    let kept = relF ? relF.o({ Loud: 1 }).length : 0
    let over = relF ? ((+relF.sc.over) || 0) : 0
    if (relF && kept === 4 && over > 0 && !(oa %see:'a crowded fold drops nothing silently — the bare Relic pair carries more distinct facts than the four loudest the cap keeps so the model marks the crowded-out tail with an over count instead of letting it vanish')) i %see:'a crowded fold drops nothing silently — the bare Relic pair carries more distinct facts than the four loudest the cap keeps so the model marks the crowded-out tail with an over count instead of letting it vanish'

// beat 3 — the mutations read back PER EXAMPLE: the flock example grew, the mix example shrank.  The
//  drift readings on each Voronoiology attribute the arrivals|departures to their family.
VoroTest_witness_mutate(w):
    let flock = this.VoroTest_dataworld_named(w, 'flock')
    let boulders = flock ? this.VoroTest_gang_of(flock, 'Boulder') : null
    if (boulders && (boulders.c.gang || []).length === 15 && !(oa %see:'the flock example swelled — its boulder gang recomputed to fifteen members behind the same representative')) i %see:'the flock example swelled — its boulder gang recomputed to fifteen members behind the same representative'
    let mix = this.VoroTest_dataworld_named(w, 'mix')
    let fern = mix ? this.VoroTest_gang_of(mix, 'Fern') : null
    if (fern && (fern.c.gang || []).length === 5 && !(oa %see:'the mix example shed two ferns — its fern gang shrank from seven to five yet still cleared the threshold and held its pane')) i %see:'the mix example shed two ferns — its fern gang shrank from seven to five yet still cleared the threshold and held its pane'
    // the model's DRIFT attributes the deltas: the flock's Voronoiology must read three arrivals on its
    //  boulder family reading and the mix's two departures — each as the %Se:drift CHILD of a snapped
    //   %Family row (the mainkey-as-provenance rule: %Se only where a Selection resolve spoke).
    let fseen = this.VoroTest_seen(w, 'flock')
    let mseen = this.VoroTest_seen(w, 'mix')
    let fneu = fseen ? fseen.o({ Family: 1 }).some(r => (r.o({ Se: 'drift' })[0] || { sc: {} }).sc.neu === '3') : false
    let mgone = mseen ? mseen.o({ Family: 1 }).some(r => (r.o({ Se: 'drift' })[0] || { sc: {} }).sc.gone === '2') : false
    if (fneu && !(oa %see:'the model felt the arrivals — the flock reading carries three new members in its drift this beat')) i %see:'the model felt the arrivals — the flock reading carries three new members in its drift this beat'
    if (mgone && !(oa %see:'the model felt the goners — the mix reading carries two departures in its drift this beat')) i %see:'the model felt the goners — the mix reading carries two departures in its drift this beat'
    // #23 the popped intent respected: one ingot was popped by hand this beat.  It stands OUT of the fold
    //  (no stuff stamp, not represented) and the remaining TWO re-gang at the relaxed spill threshold —
    //   two is below the ordinary min 3, so a re-gang can only mean the spill relax fired (min 2).  This
    //    reddens if the popped-tiny branch swept the popped leaf back in (represented) or if spill relax
    //     were removed (the pair would stand bare and VoroTest_gang_of would find no rep).
    let popw = this.VoroTest_dataworld_named(w, 'popped')
    let popped_leaf = popw ? popw.o().find(c => c.c.popped) : null
    let ingang = popw ? this.VoroTest_gang_of(popw, 'Ingot') : null
    if (popped_leaf && !popped_leaf.c.stuff && !popped_leaf.c.represented && ingang && (ingang.c.gang || []).length === 2 && !(oa %see:'a popped member stands out and the rest hold together — one ingot surfed out of the fold while the remaining two re-ganged at the relaxed spill threshold')) i %see:'a popped member stands out and the rest hold together — one ingot surfed out of the fold while the remaining two re-ganged at the relaxed spill threshold'
    // #31 the dial is not mitosis (the openness split): this beat's pop is the VIEWER's hand — the
    //  ingot gang undressed (unfolded) and its spill re-dressed at the relaxed min (folded) while NOT
    //   ONE node arrived or left the data.  The old silhouette arithmetic (prev+born−grasped) booked
    //    exactly this undressing as a death; the split reads the same beat honestly — born and died
    //     both zero with the dial's own weather beside them on the one row.  Reddens if the was_fold
    //      annotation is lost (folded|unfolded vanish) or an undressing books as died again.
    let pseen = this.VoroTest_seen(w, 'popped')
    let prow = pseen ? pseen.o({ Se: 'scape' })[0] : null
    if (prow && !(+prow.sc.born) && !(+prow.sc.died) && (+prow.sc.folded) > 0 && (+prow.sc.unfolded) > 0 && !(oa %see:'the dial is not mitosis — the popped gang undressed and its spill re-dressed while nothing was born and nothing died')) i %see:'the dial is not mitosis — the popped gang undressed and its spill re-dressed while nothing was born and nothing died'
    // #28 the family kept its slot: the flock's Family:Boulder is the VERY SAME row node captured at the
    //  bench, its count slid twelve to fifteen IN PLACE.  A census storm would have dropped and rebuilt
    //   the row (a fresh node), so a surviving === ref is the live-reachable proof of the persistent
    //    find-or-create emission (the full diff-size gate stays the human's fixture territory).
    let fseen2 = this.VoroTest_seen(w, 'flock')
    let frow = fseen2 ? fseen2.o({ Family: 'Boulder' })[0] : null
    if (w.c.census_id && frow && frow === w.c.census_id && frow.sc.n === '15' && !(oa %see:'the family kept its slot — the flock reading is the very same row across the recrush its count sliding to fifteen in place rather than a storm tearing it down and rebuilding')) i %see:'the family kept its slot — the flock reading is the very same row across the recrush its count sliding to fifteen in place rather than a storm tearing it down and rebuilding'

// beat 4 — the quiet beat: recrush with NO mutation, so every Example's fold verdicts hold exactly and
//  the drift falls silent (a stale neu|gone would mean a model tail failed to re-run — the staleness
//   this harness exists to catch).
VoroTest_witness_quiet(w):
    let flock = this.VoroTest_dataworld_named(w, 'flock')
    let mix = this.VoroTest_dataworld_named(w, 'mix')
    let grovesW = this.VoroTest_dataworld_named(w, 'groves')
    let boulders = flock ? this.VoroTest_gang_of(flock, 'Boulder') : null
    let fern = mix ? this.VoroTest_gang_of(mix, 'Fern') : null
    let groves = grovesW ? this.VoroTest_panes_of(grovesW, 'Grove') : 0
    let steady = boulders && (boulders.c.gang || []).length === 15 && fern && (fern.c.gang || []).length === 5 && groves === 3
    if (steady && !(oa %see:'the readings held steady across the examples — a recrush with nothing changed reproduced every gang and pane because the fold is a pure function of the data')) i %see:'the readings held steady across the examples — a recrush with nothing changed reproduced every gang and pane because the fold is a pure function of the data'
    // drift silent on EVERY example this beat — silence is STRUCTURAL now: a quiet %Family row simply
    //  has no %Se:drift child (absence is the reading), so the check is child-count zero, not fields.
    let all_quiet = w.o({ Example: 1 }).every(ex => { let rw = ex.o({ w: 'Voronoiology' })[0]; if (!rw) return true; return rw.o({ Family: 1 }).every(r => r.o({ Se: 'drift' }).length === 0) })
    if (all_quiet && !(oa %see:'the drift fell silent everywhere — no family reading on any example carries an arrival or a departure after a recrush with nothing changed')) i %see:'the drift fell silent everywhere — no family reading on any example carries an arrival or a departure after a recrush with nothing changed'
//#endregion

//#region reference — the canonical Voro sets, as data (a nav aid + a future sweep target)

// Voro_render_map — the stages in order (this ghost's crush, then Cytui's pixels), to walk the pipeline.
Voro_render_map():
    return ['Voro_crush_scan', 'Vtuff_build', 'voronoi_layout', 'install_nuclei', 'morph_voronoi', 'voronoi_paint_now', 'paint_final']
//#endregion

//#region Stuff — the regrouping algebra, stho-native (re-home target: Vyto_fold, Vyto.g:294)
// ══ Stuff_distil — the Stuffing regrouping algebra re-said CLEAN in stho ══════════════════════════
//  A faithful re-expression of Voro.g Vtuff_keyrows (:1911, the oracle) — the pane-content engine's
//   distiller lifted out of the crush and stated on its own, so a Book can prove it with no glass.
//    A bag of member Cs (each an sc of k:v facts) distils into the SAME %Vtuffing/%Vrow/%Vbit tree
//     Voro emits (keep-the-format, 2026-07-21 — it is already typed k/v and carries wgt|n prosody),
//      PLUS the one leg Vtuff_keyrows structurally cannot reach: row:vein (a value that crosses keys).
//   The three legs re-said: ONE distinct value → a fact said once (a bare '1' → a COUNTED presence
//    fact, only when some-not-all carry it — a universal presence says nothing).  MANY values → a
//     spread of chips, counted (the ×N multiplicity), ranked most-common-first, capped at 3 + an
//      honest '+N' tail (never a silent drop).  Render decorations (tag badge · c.members hover) are
//       DROPPED here — those are paint|hover, not the algebra.  `into` mints the tree attached (a
//        Book wants it snapped as the proof — Snap data not judgement); Vyto_fold will add the
//         detached-mint variant (new TheC · Books-invisible) at re-home.
Stuff_distil(into, members, kind, skips, coexist):
    let k = kind || 'stuff'
    let n = members ? members.length : 0
    let root = into.i({ Vtuffing: 1, of: k, n: n })
    if (!members || !members.length) return root
    // veins FIRST — they compute which (key|value) facts they subsume; then keyrows SUPERSEDES those
    //  facts (say more with less — the human's ruling 2026-07-21) unless `coexist` keeps the raw facts.
    let veined = this.Stuff_veinrows(root, members, skips)
    let hide = coexist ? null : veined
    this.Stuff_keyrows(root, members, skips, hide)
    return root

// Stuff_keyrows — the key-by-key pass, Vtuff_keyrows re-said (Voro.g:1911).  Union the members'
//  keys first-seen; per key tally values and carriers; ONE value → fact (or counted presence),
//   MANY → spread + ranked capped chips.
Stuff_keyrows(root, members, skips, hide):
    let keys = []
    let seen = {}
    for (const m of members) {
        for (const kk of Object.keys(m.sc)) {
            if (!seen[kk]) {
                seen[kk] = 1
                keys.push(kk)
            }
        }
    }
    for (const kk of keys) {
        if (skips && skips.includes(kk)) continue
        let vals = {}
        let order = []
        let have = 0
        for (const m of members) {
            if (!Object.prototype.hasOwnProperty.call(m.sc, kk)) continue
            have = have + 1
            let v = '' + m.sc[kk]
            if (vals[v] == null) {
                vals[v] = 0
                order.push(v)
            }
            vals[v] = vals[v] + 1
        }
        if (!have) continue
        if (order.length === 1) {
            if (order[0] === '1') {
                if (have < members.length) {
                    let fp = { Vrow: 1, row: 'fact', k: kk, n: have, wgt: 1 }
                    root.i(fp)
                }
            } else {
                if (hide && hide[kk + '|' + order[0]]) continue
                let fq = { Vrow: 1, row: 'fact', k: kk, v: order[0], wgt: 1 }
                root.i(fq)
            }
            continue
        }
        order.sort((a, b) => vals[b] - vals[a])
        let ssc = { Vrow: 1, row: 'spread', k: kk, wgt: 1 }
        let r = root.i(ssc)
        let chips = order
        if (order.length > 4) chips = order.slice(0, 3)
        for (const v of chips) {
            let bsc = { Vbit: 1, v: v, n: vals[v] }
            r.i(bsc)
        }
        if (order.length > chips.length) {
            let tsc = { Vbit: 1, text: '+' + (order.length - chips.length), n: 0 }
            r.i(tsc)
        }
    }

// Stuff_veinrows — THE NEW LEG (RULED 2026-07-21).  Vtuff_keyrows reads
//  key-by-key and can NEVER see a value that crosses keys.  The sizing algebra wants it: a value
//   carried across many keys is a global VEIN — one hue|bearing racing the whole scape — that
//    deserves saying ONCE.  The dual of spread: spread = one key · many values; vein =
//     one value · many keys.  Poses large as `v` over `k1|k2`.  Ranked by total carriers; the '1'
//      presence marker is never a vein value.  The ruling: a vein SUPERSEDES the per-key facts it
//       subsumes (say more with less) unless the `coexist` knob keeps them; and it rides wgt:1 like
//        fact|spread — real loudness comes from shared-ness in the live stack, not a bump.
Stuff_veinrows(root, members, skips):
    let vkeys = {}
    let vn = {}
    for (const m of members) {
        for (const kk of Object.keys(m.sc)) {
            if (skips && skips.includes(kk)) continue
            let v = '' + m.sc[kk]
            if (v === '1') continue
            if (!vkeys[v]) vkeys[v] = {}
            if (vn[v] == null) vn[v] = 0
            vkeys[v][kk] = (vkeys[v][kk] || 0) + 1
            vn[v] = vn[v] + 1
        }
    }
    let veins = []
    for (const v of Object.keys(vkeys)) {
        if (Object.keys(vkeys[v]).length >= 2) veins.push(v)
    }
    veins.sort((a, b) => vn[b] - vn[a])
    let veined = {}
    for (const v of veins) {
        let r = root.i({ Vrow: 1, row: 'vein', v: v, wgt: 1 })
        let ks = Object.keys(vkeys[v])
        ks.sort((a, b) => vkeys[v][b] - vkeys[v][a])
        for (const kk of ks) {
            r.i({ Vbit: 1, k: kk, n: vkeys[v][kk] })
            veined[kk + '|' + v] = 1
        }
    }
    return veined
//#endregion

//#region test — Stuffing: the k:v regrouping algebra proven in isolation (no glass, no pixels)
// ══ Stuffing — feed hand-built bags through Stuff_distil and assert the %Vtuffing tree ════════════
//  Where VoroTest crushes whole data worlds through the fold|gang RULES, Stuffing isolates the ONE
//   pane-content step: given a bag of members, what tree does the distiller say?  Five bags, one per
//    leg; each an %Example holding its members + its distilled %Vtuffing (attached → SNAPPED → the
//     fixture IS the proof, Snap data not judgement).  The %see are per-beat readable claims on top;
//      the distilled trees are the durable gate.  Deterministic throughout — hand-built values, no
//       hash, no wall-clock, no audio, no commission — byte-stable fixtures.  The world MUST be named
//        Stuffing (do_fn_for dispatches by w.sc.w) — no Run_A_ recipe; Story auto-stands A:Stuffing.
//   beat 2  the bench is laid — five bags distilled — every leg read
//   beat 3  the vein RE-BREATHES — a fourth carrier lands on dub — its genre count thickens 2→3
//   beat 4  a QUIET beat — nothing changes — the trees hold (the distiller is a pure function)
Stuffing(A,w):
    w oai %req:wrangle,eternal
        await &Stuffing_drive,w,req
        req%ok = 1

async Stuffing_drive(w, req):
    let run = this.c.run
    if (run && run.sc && run.sc.mode === 'new') run.sc.total = 4
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.Stuffing_bench(w)
        if (n === 3) this.Stuffing_rebreathe(w)
    }
    this.Stuffing_witness(w)

// ── bag builders ─────────────────────────────────────────────────────────────────────────────────
Stuffing_bag(w, name):
    return w.i({ Example: 1, name: name })

Stuffing_member(ex, sc):
    return ex.i(sc)

// distil an Example's EXPLICIT member list into an attached %Vtuffing under it (never re-read
//  ex.o() — the %Vtuffing child would pollute the member set).
Stuffing_seal(ex, members):
    return this.Stuff_distil(ex, members, 'stuff', null, null)

// the knob: the SAME distil with coexist ON (the raw per-key facts kept beside the vein)
Stuffing_seal_coexist(ex, members):
    return this.Stuff_distil(ex, members, 'stuff', null, 1)

// ── readers (the witness walks the distilled trees through these) ──────────────────────────────────
Stuffing_tree(w, name):
    let ex = w.o({ Example: 1, name: name })[0]
    return ex ? ex.o({ Vtuffing: 1 })[0] : null

Stuffing_row(tree, rowkind, k):
    if (!tree) return null
    return tree.o({ Vrow: 1, row: rowkind, k: k })[0]

Stuffing_vein(tree, v):
    if (!tree) return null
    return tree.o({ Vrow: 1, row: 'vein', v: v })[0]

Stuffing_chip(row, v):
    if (!row) return null
    return row.o({ Vbit: 1, v: v })[0]

Stuffing_keybit(row, k):
    if (!row) return null
    return row.o({ Vbit: 1, k: k })[0]

// ── the bench: five bags one per leg ───────────────────────────────────────────────────────────────
Stuffing_bench(w):
    // A — AGREE: five tracks all genre dub (→ fact said once) beside varying titles (→ a spread)
    let a = this.Stuffing_bag(w, 'agree')
    let am = []
    let titles = ['Tide', 'Halo', 'Drift', 'Glow', 'Vane']
    for (const t of titles) am.push(this.Stuffing_member(a, { Track: 1, title: t, genre: 'dub' }))
    this.Stuffing_seal(a, am)
    // B — SPREAD + MULTIPLICITY: year 2007 twice · 1998 once (→ counted ranked chips)
    let b = this.Stuffing_bag(w, 'spread')
    let bm = []
    bm.push(this.Stuffing_member(b, { Track: 1, title: 'Ember', year: '2007' }))
    bm.push(this.Stuffing_member(b, { Track: 1, title: 'Frost', year: '2007' }))
    bm.push(this.Stuffing_member(b, { Track: 1, title: 'Gale', year: '1998' }))
    this.Stuffing_seal(b, bm)
    // C — VEIN (the new leg): value 'dub' under BOTH genre AND mood (→ one vein two keys)
    let c = this.Stuffing_bag(w, 'vein')
    let cm = []
    cm.push(this.Stuffing_member(c, { Track: 1, title: 'Sway', genre: 'dub' }))
    cm.push(this.Stuffing_member(c, { Track: 1, title: 'Murk', mood: 'dub' }))
    cm.push(this.Stuffing_member(c, { Track: 1, title: 'Reed', genre: 'dub' }))
    this.Stuffing_seal(c, cm)
    // C2 — the KNOB: the same cross-key bag with coexist ON keeps genre dub and mood dub beside the vein
    let c2 = this.Stuffing_bag(w, 'coexist')
    let c2m = []
    c2m.push(this.Stuffing_member(c2, { Track: 1, title: 'Sway', genre: 'dub' }))
    c2m.push(this.Stuffing_member(c2, { Track: 1, title: 'Murk', mood: 'dub' }))
    c2m.push(this.Stuffing_member(c2, { Track: 1, title: 'Reed', genre: 'dub' }))
    this.Stuffing_seal_coexist(c2, c2m)
    // D — OVERFLOW: one shared title (→ fact) + five distinct labels (→ top three + '+2' tail)
    let d = this.Stuffing_bag(w, 'overflow')
    let dm = []
    let labels = ['blue', 'warp', 'deep', 'on-u', 'wackies']
    for (const l of labels) dm.push(this.Stuffing_member(d, { Track: 1, title: 'Comp', label: l }))
    this.Stuffing_seal(d, dm)
    // E — PRESENCE: remaster:1 on three of five (→ counted fact no value); universal Track → skipped
    let e = this.Stuffing_bag(w, 'presence')
    let em = []
    em.push(this.Stuffing_member(e, { Track: 1, title: 'Alve', remaster: 1 }))
    em.push(this.Stuffing_member(e, { Track: 1, title: 'Bore', remaster: 1 }))
    em.push(this.Stuffing_member(e, { Track: 1, title: 'Cusp', remaster: 1 }))
    em.push(this.Stuffing_member(e, { Track: 1, title: 'Dell' }))
    em.push(this.Stuffing_member(e, { Track: 1, title: 'Etch' }))
    this.Stuffing_seal(e, em)

// the vein re-breathes — a fourth carrier lands on dub-via-genre; drop the stale tree and re-seal.
Stuffing_rebreathe(w):
    let c = w.o({ Example: 1, name: 'vein' })[0]
    if (!c) return
    let old = c.o({ Vtuffing: 1 })[0]
    if (old) c.drop(old)
    let cm = c.o({ Track: 1 })
    cm.push(this.Stuffing_member(c, { Track: 1, title: 'Kelp', genre: 'dub' }))
    this.Stuffing_seal(c, cm)

// ── the witness — each %see is a per-beat observation gated to its step (flat like VoroScape — a
//  peel verb inside a nested { } block does not compile); comma-free · em-dash ────────────────────
Stuffing_witness(w):
    let n = (this.c.run)?.c.step_n
    // A — a value everyone agrees on says itself once as a fact (not once per member)
    let ta = this.Stuffing_tree(w, 'agree')
    let fa = this.Stuffing_row(ta, 'fact', 'genre')
    let sa = this.Stuffing_row(ta, 'spread', 'title')
    if (n === 2 && fa && fa.sc.v === 'dub' && sa && !(oa %see:'a value everyone agrees on is said once as a fact — five dub tracks fold to a single genre dub not five')) i %see:'a value everyone agrees on is said once as a fact — five dub tracks fold to a single genre dub not five'
    // B — a varying key spreads into counted chips ranked most-common-first (the ×N multiplicity)
    let tb = this.Stuffing_tree(w, 'spread')
    let sy = this.Stuffing_row(tb, 'spread', 'year')
    let c07 = this.Stuffing_chip(sy, '2007')
    let c98 = this.Stuffing_chip(sy, '1998')
    let lead = sy ? sy.o({ Vbit: 1 })[0] : null
    if (n === 2 && c07 && c07.sc.n === 2 && c98 && c98.sc.n === 1 && lead && lead.sc.v === '2007' && !(oa %see:'a key that varies spreads into counted chips ranked most-common-first — 2007 carries two and leads 1998 with one')) i %see:'a key that varies spreads into counted chips ranked most-common-first — 2007 carries two and leads 1998 with one'
    // C — THE NEW LEG (supersede default): a cross-key value folds to one vein and REPLACES the facts it subsumes
    let tc = this.Stuffing_tree(w, 'vein')
    let vein = this.Stuffing_vein(tc, 'dub')
    let vg = this.Stuffing_keybit(vein, 'genre')
    let vm = this.Stuffing_keybit(vein, 'mood')
    let cfact = this.Stuffing_row(tc, 'fact', 'genre')
    if (n === 2 && vein && vg && vm && !cfact && !(oa %see:'the new leg folds a value crossing several keys into one vein and supersedes the per-key facts it subsumes — dub spans genre and mood said once not as two separate facts')) i %see:'the new leg folds a value crossing several keys into one vein and supersedes the per-key facts it subsumes — dub spans genre and mood said once not as two separate facts'
    // C2 — THE KNOB: coexist on restores the raw per-key facts beside the vein for a domain that wants both
    let tk = this.Stuffing_tree(w, 'coexist')
    let kvein = this.Stuffing_vein(tk, 'dub')
    let kfact = this.Stuffing_row(tk, 'fact', 'genre')
    if (n === 2 && kvein && kfact && kfact.sc.v === 'dub' && !(oa %see:'the knob restores coexistence — the same bag with supersede off keeps genre dub beside the vein for a domain that wants the raw facts too')) i %see:'the knob restores coexistence — the same bag with supersede off keeps genre dub beside the vein for a domain that wants the raw facts too'
    // D — a spread past four keeps its top three and marks the rest as an honest overflow tail
    let td = this.Stuffing_tree(w, 'overflow')
    let so = this.Stuffing_row(td, 'spread', 'label')
    let chips = so ? so.o({ Vbit: 1 }) : []
    let tail = so ? so.o({ Vbit: 1 }).find(x => x.sc.text != null) : null
    if (n === 2 && chips.length === 4 && tail && tail.sc.text === '+2' && !(oa %see:'a spread past four values keeps its top three and marks the rest as an honest overflow tail — five labels show three then plus two')) i %see:'a spread past four values keeps its top three and marks the rest as an honest overflow tail — five labels show three then plus two'
    // E — a presence key on some-not-all rides as a counted fact with no value; universal mainkey says nothing
    let te = this.Stuffing_tree(w, 'presence')
    let pr = this.Stuffing_row(te, 'fact', 'remaster')
    let trk = this.Stuffing_row(te, 'fact', 'Track')
    if (n === 2 && pr && pr.sc.n === 3 && pr.sc.v == null && !trk && !(oa %see:'a presence key on some-not-all rides as a counted fact with no value while the universal mainkey says nothing — three of five remastered')) i %see:'a presence key on some-not-all rides as a counted fact with no value while the universal mainkey says nothing — three of five remastered'
    // beat 3 — the field is live: one more carrier and the vein re-breathes (vg now reads the post-rebreathe tree)
    if (n === 3 && vg && vg.sc.n === 3 && !(oa %see:'add another carrier and the vein re-breathes — dub across genre thickens from two to three without restating the bag')) i %see:'add another carrier and the vein re-breathes — dub across genre thickens from two to three without restating the bag'
//#endregion

//#region Typescale — the global type-scale (Vyto_sizing_todo §4 / §9 station ④) proven in isolation
// ══ Typescale — ONE global scale S sizes every text so size(t) = S·φ(importance(t)) ═══════════════
//  §9 of Vyto_sizing_todo.md names this the law's heart and says to prove it the way Stuffing proved
//   the distiller: a bag of texts each with an importance, sized under ONE graph-global S — so the
//    biggest word ANYWHERE is the most important thing anywhere (not an accident of local fit).  φ=√
//     (a knob — √ compresses a 100× importance range to a 10× size range AND makes area=S²·w so S
//      solves closed-form S=√(frame/Σw)); a text fills area ∝ size².  A FIRST CUT, no glass — it proves
//       the INVARIANTS (global ratio · order · frame-spent · floor-fold · re-breathe) that hold for ANY
//        reasonable φ; the exact φ|area|floor model is the human's to preen (§4).  World named Typescale.

// Typescale_phi — the importance→size compression.  √: importance 100 → 10× the size of importance 1.
Typescale_phi(wt):
    return Math.sqrt(wt)

// Typescale_size — size a bag of %Text (each sc.w an importance) under ONE global S, folding any text
//  that would fall below the legibility floor (folding frees its area → S RISES for the rest → the
//   re-breathe).  Mints an attached %Scale carrying S (×100 for a clean integer snap) + a %Size per
//    survivor (px = round(S·φ(w))) + a %Fold per folded text (the honest +N — never a silent shrink).
Typescale_size(into, texts, frame, floor):
    let survivors = []
    for (const t of texts) survivors.push(t)
    let folded = []
    let S = 0
    let guard = 0
    while (guard < 50) {
        guard = guard + 1
        let sumw = 0
        for (const t of survivors) sumw = sumw + t.sc.w
        if (sumw <= 0) break
        S = Math.sqrt(frame / sumw)
        let lo = null
        for (const t of survivors) {
            if (lo == null || t.sc.w < lo.sc.w) lo = t
        }
        if (lo == null) break
        let losize = S * this.Typescale_phi(lo.sc.w)
        if (losize >= floor || survivors.length <= 1) break
        folded.push(lo)
        let keep = []
        for (const t of survivors) {
            if (t !== lo) keep.push(t)
        }
        survivors = keep
    }
    let root = into.i({ Scale: 1, frame: frame, floor: floor, S: Math.round(S * 100) })
    for (const t of survivors) {
        let px = Math.round(S * this.Typescale_phi(t.sc.w))
        root.i({ Size: 1, label: t.sc.label, w: t.sc.w, px: px })
    }
    for (const t of folded) {
        root.i({ Fold: 1, label: t.sc.label, w: t.sc.w })
    }
    return root

// Typescale — the Book (world MUST be named Typescale — do_fn_for dispatches by w.sc.w).
Typescale(A,w):
    w oai %req:wrangle,eternal
        await &Typescale_drive,w,req
        req%ok = 1

async Typescale_drive(w, req):
    let run = this.c.run
    if (run && run.sc && run.sc.mode === 'new') run.sc.total = 3
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.Typescale_bench(w)
    }
    this.Typescale_witness(w)

Typescale_bag(w, name):
    return w.i({ Example: 1, name: name })

Typescale_text(bag, label, wt):
    return bag.i({ Text: 1, label: label, w: wt })

Typescale_scale(w, name):
    let ex = w.o({ Example: 1, name: name })[0]
    return ex ? ex.o({ Scale: 1 })[0] : null

Typescale_size_of(scale, label):
    if (!scale) return null
    return scale.o({ Size: 1, label: label })[0]

// ── the bench: four cases, all integer-clean by construction (frame = perfect-square · Σw) ─────────
Typescale_bench(w):
    // A — FILL no fold: importances 16 9 4 1 at frame 1920 floor 8 → S=8 sizes 32 24 16 8 (Σpx²=1920)
    let a = this.Typescale_bag(w, 'fill')
    let at = []
    at.push(this.Typescale_text(a, 'p', 16))
    at.push(this.Typescale_text(a, 'q', 9))
    at.push(this.Typescale_text(a, 'r', 4))
    at.push(this.Typescale_text(a, 's', 1))
    this.Typescale_size(a, at, 1920, 8)
    // B — FOLD: same texts at frame 464 → importance 1 folds → survivors S=4 sizes 16 12 8
    let b = this.Typescale_bag(w, 'fold')
    let bt = []
    bt.push(this.Typescale_text(b, 'p', 16))
    bt.push(this.Typescale_text(b, 'q', 9))
    bt.push(this.Typescale_text(b, 'r', 4))
    bt.push(this.Typescale_text(b, 's', 1))
    this.Typescale_size(b, bt, 464, 8)
    // C-small — re-breathe reference: importances 16 9 at frame 2500 → S=10 sizes 40 30
    let cs = this.Typescale_bag(w, 'small')
    let cst = []
    cst.push(this.Typescale_text(cs, 'p', 16))
    cst.push(this.Typescale_text(cs, 'q', 9))
    this.Typescale_size(cs, cst, 2500, 8)
    // C-big — the field re-breathes: add importance 75 at the SAME frame → S=5 the shared texts halve
    let cb = this.Typescale_bag(w, 'big')
    let cbt = []
    cbt.push(this.Typescale_text(cb, 'p', 16))
    cbt.push(this.Typescale_text(cb, 'q', 9))
    cbt.push(this.Typescale_text(cb, 'z', 75))
    this.Typescale_size(cb, cbt, 2500, 8)

// ── the witness — flat, gated to n===2; comma-free · em-dash ──────────────────────────────────────
Typescale_witness(w):
    let n = (this.c.run)?.c.step_n
    // A — one global scale: biggest importance = biggest px, ratio is √(importance)
    let fa = this.Typescale_scale(w, 'fill')
    let ap = this.Typescale_size_of(fa, 'p')
    let as = this.Typescale_size_of(fa, 's')
    if (n === 2 && ap && ap.sc.px === 32 && as && as.sc.px === 8 && !(oa %see:'one global scale sizes every text so the biggest word is the most important thing anywhere — importance 16 takes 32px exactly four times importance 1 at 8px the square-root ratio')) i %see:'one global scale sizes every text so the biggest word is the most important thing anywhere — importance 16 takes 32px exactly four times importance 1 at 8px the square-root ratio'
    // A — the scale is maximal: the frame is spent to the last pixel
    if (n === 2 && fa && fa.sc.S === 800 && !(oa %see:'the scale is pushed until the frame is spent — importance summed to thirty fills the frame at scale eight to the last pixel')) i %see:'the scale is pushed until the frame is spent — importance summed to thirty fills the frame at scale eight to the last pixel'
    // B — floor-fold: the sub-floor text folds and freeing its room clears the survivors
    let fb = this.Typescale_scale(w, 'fold')
    let bfold = fb ? fb.o({ Fold: 1, label: 's' })[0] : null
    let bp = this.Typescale_size_of(fb, 'p')
    let br = this.Typescale_size_of(fb, 'r')
    if (n === 2 && bfold && bp && bp.sc.px === 16 && br && br.sc.px === 8 && !(oa %see:'a text that would fall below the legibility floor is folded not shrunk — importance 1 drops to a plus-one door and freeing its room lifts the scale so the survivors all clear eight px')) i %see:'a text that would fall below the legibility floor is folded not shrunk — importance 1 drops to a plus-one door and freeing its room lifts the scale so the survivors all clear eight px'
    // C — re-breathe: the shared text shrinks when an important newcomer joins the same frame
    let fcs = this.Typescale_scale(w, 'small')
    let fcb = this.Typescale_scale(w, 'big')
    let sp = this.Typescale_size_of(fcs, 'p')
    let bp2 = this.Typescale_size_of(fcb, 'p')
    if (n === 2 && sp && sp.sc.px === 40 && bp2 && bp2.sc.px === 20 && !(oa %see:'add an important text and the whole field re-breathes — importance 16 shrinks from 40px to 20px as one global scale rescales to hold the newcomer')) i %see:'add an important text and the whole field re-breathes — importance 16 shrinks from 40px to 20px as one global scale rescales to hold the newcomer'
//#endregion

//#region Floorlaw — the ONE supersession law (processes.md J2+J3+J5 kernel) proven in isolation
// ══ Floorlaw — below the floor · superseded by distillation ═══════════════════════════════════════
//  The floor law generalises Typescale's text-fold to STRUCTURE: a family (a %Brood of members)
//   whose LOUDEST voice would size below the legibility floor at the global S is superseded by its
//    distillation — the crest = Stuff_distil of its members (the crush SPEAKS Stuffing — J3: Gang
//     picks who · Stuffing says what).  Crushing frees demand so S RISES — and the law is
//      ONE-DIRECTIONAL within a pass: case A lands S exactly AT the members' re-admission point and
//       the crush must HOLD (the flutter defused by construction — J2).  Un-crush happens only
//        ACROSS passes: by frame (case C — reframe = re-solve at the scope's own frame · the surf
//         kernel — J5) or by importance (beat 3 — a member grows loud).  v1 granularity is the
//          FAMILY (its legibility = its loudest voice; meek siblings ride along) — per-text fold
//           inside an unfolded family is Typescale's law and composes later in the pipeline.
//            No glass · no pixels · byte-stable fixtures.  World MUST be named Floorlaw
//             (do_fn_for dispatches by w.sc.w).
//   beat 2  the bench — crush at the world frame · legible at a big one · affordable reframed
//   beat 3  a member grows LOUD — the family un-crushes across passes
//   beat 4  a QUIET beat — nothing changes — the trees hold (the solve is a pure function)

// Floorlaw_phi — the same compression as Typescale (φ=√ — area=S²·w so S solves closed-form).
Floorlaw_phi(wt):
    return Math.sqrt(wt)

// Floorlaw_solve — price the Example's texts under ONE global S with the floor law: loose %Text and
//  unfolded %Brood members demand w each; a brood whose loudest member would size below the floor
//   CRUSHES — a %Crush row minted under the %Scale root with the crest %Vtuffing distilled inside it
//    ('w' skipped — importance is not a fact) — and thereafter demands only its crest rows' count.
//     Loop one-directional (crush only · never un-crush within the pass · guard 50) exactly like
//      Typescale's fold loop; then stamp S ×100 and mint a %Size per surviving voice (the crest is
//       the crushed brood's one voice — it must itself clear the floor to say the family legibly).
Floorlaw_solve(ex, frame, floor):
    let old = ex.o({ Scale: 1 })[0]
    if (old) ex.drop(old)
    let loose = ex.o({ Text: 1 })
    let broods = ex.o({ Brood: 1 })
    let root = ex.i({ Scale: 1, frame: frame, floor: floor })
    let crushed = {}
    let crestw = {}
    let S = 0
    let guard = 0
    while (guard < 50) {
        guard = guard + 1
        let sumw = 0
        for (const t of loose) sumw = sumw + t.sc.w
        for (const b of broods) {
            if (crushed[b.sc.name]) {
                sumw = sumw + crestw[b.sc.name]
            } else {
                for (const m of b.o({ Track: 1 })) sumw = sumw + m.sc.w
            }
        }
        if (sumw <= 0) break
        S = Math.sqrt(frame / sumw)
        let hit = null
        for (const b of broods) {
            if (crushed[b.sc.name]) continue
            let loud = 0
            for (const m of b.o({ Track: 1 })) {
                if (m.sc.w > loud) loud = m.sc.w
            }
            if (S * this.Floorlaw_phi(loud) < floor) {
                hit = b
                break
            }
        }
        if (!hit) break
        crushed[hit.sc.name] = 1
        let members = hit.o({ Track: 1 })
        let memw = 0
        for (const m of members) memw = memw + m.sc.w
        let cr = root.i({ Crush: 1, fam: hit.sc.name })
        this.Stuff_distil(cr, members, 'crest', ['w'], null)
        let vt = cr.o({ Vtuffing: 1 })[0]
        let rows = vt ? vt.o({ Vrow: 1 }).length : 1
        crestw[hit.sc.name] = rows
        cr.sc.freed = memw - rows
    }
    root.sc.S = Math.round(S * 100)
    for (const t of loose) {
        root.i({ Size: 1, label: t.sc.label, w: t.sc.w, px: Math.round(S * this.Floorlaw_phi(t.sc.w)) })
    }
    for (const b of broods) {
        if (crushed[b.sc.name]) {
            let cw = crestw[b.sc.name]
            root.i({ Size: 1, label: b.sc.name, w: cw, px: Math.round(S * this.Floorlaw_phi(cw)) })
        } else {
            for (const m of b.o({ Track: 1 })) {
                root.i({ Size: 1, label: m.sc.title, w: m.sc.w, px: Math.round(S * this.Floorlaw_phi(m.sc.w)) })
            }
        }
    }
    return root

// Floorlaw — the Book (world MUST be named Floorlaw — do_fn_for dispatches by w.sc.w).
Floorlaw(A,w):
    w oai %req:wrangle,eternal
        await &Floorlaw_drive,w,req
        req%ok = 1

async Floorlaw_drive(w, req):
    let run = this.c.run
    if (run && run.sc && run.sc.mode === 'new') run.sc.total = 4
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.Floorlaw_bench(w)
        if (n === 3) this.Floorlaw_louden(w)
    }
    this.Floorlaw_witness(w)

Floorlaw_bag(w, name):
    return w.i({ Example: 1, name: name })

Floorlaw_brood(ex, name):
    return ex.i({ Brood: 1, name: name })

Floorlaw_loose(ex, label, wt):
    return ex.i({ Text: 1, label: label, w: wt })

Floorlaw_scale(w, name):
    let ex = w.o({ Example: 1, name: name })[0]
    return ex ? ex.o({ Scale: 1 })[0] : null

Floorlaw_crushrow(scale, fam):
    if (!scale) return null
    return scale.o({ Crush: 1, fam: fam })[0]

Floorlaw_size_of(scale, label):
    if (!scale) return null
    return scale.o({ Size: 1, label: label })[0]

// ── the bench: three cases — all integer-clean by construction ────────────────────────────────────
Floorlaw_bench(w):
    // A — CRUSH at the world frame: a loud loose voice (w 16) beside a meek five-member brood (w 1
    //  each).  frame 1152 floor 8: unfolded Σw=21 → S=7.41 → the loudest member sizes 7.41 < 8 →
    //   crush; the crest says TWO rows (fact genre · spread title) → Σw=18 → S=8 EXACTLY — the
    //    members would now size AT the floor yet stay crushed (the flutter case · defused).
    let a = this.Floorlaw_bag(w, 'crush')
    this.Floorlaw_loose(a, 'p', 16)
    let ab = this.Floorlaw_brood(a, 'shoal')
    let titles = ['Kelp', 'Mist', 'Foam', 'Silt', 'Wrack']
    for (const t of titles) ab.i({ Track: 1, title: t, genre: 'dub', w: 1 })
    this.Floorlaw_solve(a, 1152, 8)
    // B — LEGIBLE: the same shape at frame 5376 → S=16 → the loudest member sizes 16 ≥ 8 → no crush.
    let b2 = this.Floorlaw_bag(w, 'legible')
    this.Floorlaw_loose(b2, 'p', 16)
    let bb = this.Floorlaw_brood(b2, 'shoal')
    for (const t of titles) bb.i({ Track: 1, title: t, genre: 'dub', w: 1 })
    this.Floorlaw_solve(b2, 5376, 8)
    // C — REFRAME (the surf kernel): the brood ALONE as root at its own frame 320 → Σw=5 → S=8 →
    //  every member sizes 8 ≥ 8 → affordable → unfolded.  The same shoal that crushed at the world
    //   frame — un-crush across passes is legal and zoom is exactly a re-solve at a new frame.
    let c = this.Floorlaw_bag(w, 'reframe')
    let cb = this.Floorlaw_brood(c, 'shoal')
    for (const t of titles) cb.i({ Track: 1, title: t, genre: 'dub', w: 1 })
    this.Floorlaw_solve(c, 320, 8)

// beat 3 — a member grows LOUD: Kelp w 1→49 in the crush world and the same frame re-solves; the
//  brood's loudest now sizes 28.6 ≥ 8 so the family UN-CRUSHES across passes (importance re-opens
//   what the floor closed).  Meek siblings ride at 4px — family granularity v1 (see the header).
Floorlaw_louden(w):
    let a = w.o({ Example: 1, name: 'crush' })[0]
    if (!a) return
    let sh = a.o({ Brood: 1, name: 'shoal' })[0]
    let kelp = sh ? sh.o({ Track: 1, title: 'Kelp' })[0] : null
    if (!kelp) return
    kelp.sc.w = 49
    this.Floorlaw_solve(a, 1152, 8)

// ── the witness — flat · gated to its beat · comma-free · em-dash ─────────────────────────────────
Floorlaw_witness(w):
    let n = (this.c.run)?.c.step_n
    // A — the law itself: below the floor → superseded by the distillation and the crest SPEAKS
    let sa = this.Floorlaw_scale(w, 'crush')
    let cr = this.Floorlaw_crushrow(sa, 'shoal')
    let vt = cr ? cr.o({ Vtuffing: 1 })[0] : null
    let gf = vt ? vt.o({ Vrow: 1, row: 'fact', k: 'genre' })[0] : null
    if (n === 2 && cr && gf && gf.sc.v === 'dub' && !(oa %see:'a family below the legibility floor is superseded by its distillation — five meek tracks crush to a crest saying genre dub once beside an honest title spread')) i %see:'a family below the legibility floor is superseded by its distillation — five meek tracks crush to a crest saying genre dub once beside an honest title spread'
    // A — anti-flutter: S lands exactly at the members' re-admission point yet the crush HOLDS
    if (n === 2 && sa && sa.sc.S === 800 && cr && cr.sc.freed === 3 && !(oa %see:'the crush holds even though the room it freed would re-admit its members — supersession is one directional within a pass so the field cannot flutter')) i %see:'the crush holds even though the room it freed would re-admit its members — supersession is one directional within a pass so the field cannot flutter'
    // A — say more with less pays in pixels: the loose voice takes 32 and the crest clears the floor
    let ap = this.Floorlaw_size_of(sa, 'p')
    let ash = this.Floorlaw_size_of(sa, 'shoal')
    if (n === 2 && ap && ap.sc.px === 32 && ash && ash.sc.px === 11 && !(oa %see:'the freed demand lifts the global scale to spend the frame — the loud voice takes 32px and the crest itself stays legible at 11px above the floor')) i %see:'the freed demand lifts the global scale to spend the frame — the loud voice takes 32px and the crest itself stays legible at 11px above the floor'
    // B — the same shape above the floor never crushes: the law is a size comparison
    let sb = this.Floorlaw_scale(w, 'legible')
    let bcr = this.Floorlaw_crushrow(sb, 'shoal')
    let bk = this.Floorlaw_size_of(sb, 'Kelp')
    if (n === 2 && sb && !bcr && bk && bk.sc.px === 16 && !(oa %see:'the same family above the floor keeps every member unfolded — crush is a size comparison not a category')) i %see:'the same family above the floor keeps every member unfolded — crush is a size comparison not a category'
    // C — the surf kernel: reframed to its own frame the shoal is affordable
    let scl = this.Floorlaw_scale(w, 'reframe')
    let ccr = this.Floorlaw_crushrow(scl, 'shoal')
    let ck = this.Floorlaw_size_of(scl, 'Kelp')
    if (n === 2 && scl && scl.sc.S === 800 && !ccr && ck && ck.sc.px === 8 && !(oa %see:'reframe into the family and its members become affordable — the shoal that crushed at the world frame unfolds at its own frame with every member at the floor')) i %see:'reframe into the family and its members become affordable — the shoal that crushed at the world frame unfolds at its own frame with every member at the floor'
    // beat 3 — importance re-opens what the floor closed (cr re-read above is the RE-SOLVED tree)
    let k3 = this.Floorlaw_size_of(sa, 'Kelp')
    if (n === 3 && sa && !cr && k3 && k3.sc.px === 29 && !(oa %see:'a member grown loud un-crushes its family across passes — importance re-opens what the floor closed and the meek siblings ride along')) i %see:'a member grown loud un-crushes its family across passes — importance re-opens what the floor closed and the meek siblings ride along'
//#endregion

//#region Nestcut — nested power-cut (processes.md J4) proven in isolation
// ══ Nestcut — a /C solves INSIDE the cell of its C ════════════════════════════════════════════════
//  The nest-solve joint: the SAME one cut engine recurses — power_cells tessellates a scope's
//   polygon among its children and each child's polygon becomes the frame its OWN children solve in
//    (vyto_geometry.ts verbatim — the primitives Vytui and Vyto_solve already share; gap=0 so the
//     breathe-inset is a no-op and tiling is EXACT).  The snap mirrors the nesting: a %Cell tree —
//      label · rounded area · centroid — with `misfit` (×1000 of |parent − Σchildren|) carried as
//       DATA on each parent (snap data not judgement; the witness reads it).  Live polygons ride
//        `.c.poly` (runtime refs · never encoded) so a later beat can re-cut a scope INSIDE its
//         standing polygon — beat 3 re-divides family B under new weights while the root cut and
//          family A hold byte-still: the scope-isolation promise of Vyto_spec §5 shown as data.
//           No glass · no pixels · byte-stable.  World MUST be named Nestcut.
//   beat 2  the bench — depth 3 nest cut (root → A B C → A1 A2 A3 · B1 B2 → A1a A1b)
//   beat 3  family B RE-CUTS its innards inside its standing polygon — outside holds still
//   beat 4  a QUIET beat — nothing changes — the trees hold

IMPORT()
    import { power_cells, poly_area, poly_centroid } from "$lib/O/vyto_geometry"

// Nestcut_cut — tessellate `poly` among `kids` (plain {label·x·y·r·kids} rows — solver-side data
//  until the mint) and mint a %Cell per child under `row`; recurse into any kid carrying kids.
//   Stashes each cell polygon on the row's `.c.poly` for later re-cuts; stamps the parent's misfit.
Nestcut_cut(row, poly, kids):
    let pts = []
    let radii = []
    for (const k of kids) {
        pts.push({ x: k.x, y: k.y })
        radii.push(k.r)
    }
    let cells = power_cells(poly, pts, radii, 0)
    let parea = Math.abs(poly_area(poly))
    let sum = 0
    let i = 0
    for (const k of kids) {
        let cell = cells[i]
        i = i + 1
        if (!cell) continue
        let a = Math.abs(poly_area(cell))
        sum = sum + a
        let cen = poly_centroid(cell)
        let crow = row.i({ Cell: 1, label: k.label, area: Math.round(a), cx: Math.round(cen.x), cy: Math.round(cen.y) })
        crow.c.poly = cell
        if (k.kids) this.Nestcut_cut(crow, cell, k.kids)
    }
    row.sc.misfit = Math.round(Math.abs(parea - sum) * 1000)

// Nestcut — the Book (world MUST be named Nestcut — do_fn_for dispatches by w.sc.w).
Nestcut(A,w):
    w oai %req:wrangle,eternal
        await &Nestcut_drive,w,req
        req%ok = 1

async Nestcut_drive(w, req):
    let run = this.c.run
    if (run && run.sc && run.sc.mode === 'new') run.sc.total = 4
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.Nestcut_bench(w)
        if (n === 3) this.Nestcut_recut(w)
    }
    this.Nestcut_witness(w)

Nestcut_cell(row, label):
    if (!row) return null
    return row.o({ Cell: 1, label: label })[0]

// ── the bench: an 800×450 root cut into three families — A (heavy r60) holds three members and
//  its first member holds two grandchildren; seeds hand-placed inside their scopes (the wall
//   algebra puts A|B at x=402.5 and the A|C wall near x+y=555 — the plan keeps clear of both) ─────
Nestcut_bench(w):
    let ex = w.i({ Example: 1, name: 'nest' })
    let root = ex.i({ Cell: 1, label: 'root', area: 360000, cx: 400, cy: 225 })
    let frame = []
    frame.push({ x: 0, y: 0 })
    frame.push({ x: 800, y: 0 })
    frame.push({ x: 800, y: 450 })
    frame.push({ x: 0, y: 450 })
    root.c.poly = frame
    let a1 = { label: 'A1', x: 150, y: 100, r: 30, kids: [] }
    a1.kids.push({ label: 'A1a', x: 130, y: 80, r: 20 })
    a1.kids.push({ label: 'A1b', x: 180, y: 120, r: 20 })
    let fa = { label: 'A', x: 200, y: 150, r: 60, kids: [] }
    fa.kids.push(a1)
    fa.kids.push({ label: 'A2', x: 250, y: 100, r: 30 })
    fa.kids.push({ label: 'A3', x: 200, y: 220, r: 50 })
    let fb = { label: 'B', x: 600, y: 150, r: 40, kids: [] }
    fb.kids.push({ label: 'B1', x: 550, y: 100, r: 30 })
    fb.kids.push({ label: 'B2', x: 650, y: 200, r: 30 })
    let plan = []
    plan.push(fa)
    plan.push(fb)
    plan.push({ label: 'C', x: 400, y: 350, r: 40 })
    this.Nestcut_cut(root, frame, plan)

// beat 3 — family B re-divides the SAME standing polygon under shifted weights (r 30|30 → 45|15):
//  only B's child rows re-mint; the root cut and family A are untouched by construction AND the
//   re-cut must still tile B exactly — the scope seam carries no cost.
Nestcut_recut(w):
    let ex = w.o({ Example: 1, name: 'nest' })[0]
    if (!ex) return
    let root = ex.o({ Cell: 1, label: 'root' })[0]
    let brow = root ? root.o({ Cell: 1, label: 'B' })[0] : null
    if (!brow || !brow.c.poly) return
    for (const c of brow.o({ Cell: 1 }).slice()) brow.drop(c)
    let kids = []
    kids.push({ label: 'B1', x: 550, y: 100, r: 45 })
    kids.push({ label: 'B2', x: 650, y: 200, r: 15 })
    this.Nestcut_cut(brow, brow.c.poly, kids)

// ── the witness — flat · gated to its beat · comma-free · em-dash ─────────────────────────────────
Nestcut_witness(w):
    let n = (this.c.run)?.c.step_n
    let ex = w.o({ Example: 1, name: 'nest' })[0]
    let root = ex ? ex.o({ Cell: 1, label: 'root' })[0] : null
    let fa = this.Nestcut_cell(root, 'A')
    let fb = this.Nestcut_cell(root, 'B')
    let a1 = this.Nestcut_cell(fa, 'A1')
    let a1a = this.Nestcut_cell(a1, 'A1a')
    // the recursion IS the ask — a shape means C and another /C is visibly inside it
    if (n === 2 && a1a && !(oa %see:'the cut recurses — a grandchild cell solves inside a child that solved inside the root and every level is the same one engine')) i %see:'the cut recurses — a grandchild cell solves inside a child that solved inside the root and every level is the same one engine'
    // exact tiling at every level — misfit is thousandths and reads zero all the way down
    if (n === 2 && root && root.sc.misfit === 0 && fa && fa.sc.misfit === 0 && a1 && a1.sc.misfit === 0 && fb && fb.sc.misfit === 0 && !(oa %see:'the children tile their parent exactly at every level of the nest — the areas sum with no gap and no overlap down to the grandchildren')) i %see:'the children tile their parent exactly at every level of the nest — the areas sum with no gap and no overlap down to the grandchildren'
    // the power wall respects weight — the heavier family claims more room
    if (n === 2 && fa && fb && fa.sc.area > fb.sc.area && !(oa %see:'a heavier seed claims more room — the power wall stands off proportional to weight so importance can drive area')) i %see:'a heavier seed claims more room — the power wall stands off proportional to weight so importance can drive area'
    // containment reads as monotone areas down the spine
    if (n === 2 && root && fa && a1 && a1a && a1a.sc.area < a1.sc.area && a1.sc.area < fa.sc.area && fa.sc.area < root.sc.area && !(oa %see:'areas nest monotonically — each cell holds strictly less room than the scope it lives in')) i %see:'areas nest monotonically — each cell holds strictly less room than the scope it lives in'
    // beat 3 — the scope seam: B re-divided its standing polygon (134622 stands) and the heavier
    //  re-weight GREW B1 from its beat-2 50872 to exactly 53142 — the wall moved with the weight.
    //   (NOT b1 > b2: a power weight shifts the wall locally — it never promises global order
    //    against positional advantage; B2 keeps the big corner.  The first draft asserted the
    //     stronger false claim and the %see silently never minted — the pinned constant is the
    //      honest deterministic gate.)
    let b1 = this.Nestcut_cell(fb, 'B1')
    if (n === 3 && fb && fb.sc.misfit === 0 && fb.sc.area === 134622 && b1 && b1.sc.area === 53142 && a1a && root && root.sc.misfit === 0 && !(oa %see:'a scope re-cut its innards inside its standing polygon — the outside held still while the heavier weight grew its share of the same room')) i %see:'a scope re-cut its innards inside its standing polygon — the outside held still while the heavier weight grew its share of the same room'
//#endregion

//#region Deepcrest — distillation composes (processes.md §4 emergent engine №1) proven in isolation
// ══ Deepcrest — the crest of crests says the deepest shared truth ═════════════════════════════════
//  When a family of families crushes the members of the outer crush are themselves crests — so the
//   distiller must accept its OWN OUTPUT as members.  The claim proven here: distillation composes.
//    A crest re-said as a plain member (Deep_memberise — veins hand their value back to each key
//     they cross · facts carry over · spreads REFUSE to collapse — a blur never fakes a voice) can
//      be distilled again and the top crest AGREES with the crest of the raw pool on every family-
//       uniform key: the same vein · the same shared fact · the same spreads.  What level one
//        already blurred stays blurred (year) — the recursion loses nothing it had and invents
//         nothing it lost.  The top door carries the SUM of family counts (Dip_assign — a dip
//          without its count would render a library of seventeen like a lone particle).  Beat 3:
//           a dissenting family arrives and the shared truth DEMOTES — fact falls to spread at the
//            top and in the pool alike and the door recounts.  No glass · no pixels · byte-stable
//             fixtures.  World MUST be named Deepcrest (do_fn_for dispatches by w.sc.w).
//   beat 2  the bench — three families distil · memberise · distil again · the pool alongside
//   beat 3  the annex dissents — format falls from fact to spread · the door recounts to twenty

// Deep_fam — level one: a brood's members distil into a %Deep,lvl:fam holder ('title' skipped —
//  a name names · it is not a truth).  lvl is a STRING on purpose: a numeric 1 in an o() query is
//   the presence wildcard and would match every level.
Deep_fam(ex, brood):
    let holder = ex.i({ Deep: 1, lvl: 'fam', name: brood.sc.name })
    this.Stuff_distil(holder, brood.o({ Track: 1 }), 'crest', ['title'], null)
    return holder

// Deep_memberise — the composing move: read a crest back into ONE plain member (%Gist — a referring
//  particle wearing its OWN mainkey · it NAMES a distillate and never impersonates a %Track).
//   A vein hands its value to every key it crosses (the vein IS those facts said once — undoing the
//    supersession recovers them).  A fact carries straight over.  A spread is DROPPED: level one
//     already blurred that key and a single stand-in value would be a fake voice at the top.
Deep_memberise(ex, holder):
    let sc = { Gist: 1, name: holder.sc.name }
    let vt = holder.o({ Vtuffing: 1 })[0]
    if (!vt) return ex.i(sc)
    for (const r of vt.o({ Vrow: 1 })) {
        if (r.sc.row === 'vein') {
            for (const b of r.o({ Vbit: 1 })) sc[b.sc.k] = r.sc.v
        }
        if (r.sc.row === 'fact' && r.sc.v != null) sc[r.sc.k] = r.sc.v
    }
    return ex.i(sc)

// Deep_top — level two: memberise every family crest and distil the gists.  Rebuilt whole each
//  call (drop old top and gists first — the solve is a pure function of the families).  The door
//   count `deep` = Σ family Vtuffing n — the Dip_assign law at height: every act of supersession
//    assigns a countable door.
Deep_top(ex):
    let old = ex.o({ Deep: 1, lvl: 'top' })[0]
    if (old) ex.drop(old)
    for (const g of ex.o({ Gist: 1 })) ex.drop(g)
    let deep = 0
    for (const f of ex.o({ Deep: 1, lvl: 'fam' })) {
        let vt = f.o({ Vtuffing: 1 })[0]
        if (vt) deep = deep + vt.sc.n
        this.Deep_memberise(ex, f)
    }
    let top = ex.i({ Deep: 1, lvl: 'top', deep: deep })
    this.Stuff_distil(top, ex.o({ Gist: 1 }), 'deep', ['name'], null)
    return top

// Deep_pool — the referee: every track everywhere distilled FLAT.  The composition claim is judged
//  against this tree — agreement on every family-uniform key · honest divergence where level one
//   already blurred (the pool hears nine voices for 2007 · the top hears the one meadow kept).
Deep_pool(ex):
    let old = ex.o({ Deep: 1, lvl: 'pool' })[0]
    if (old) ex.drop(old)
    let holder = ex.i({ Deep: 1, lvl: 'pool' })
    let all = []
    for (const b of ex.o({ Brood: 1 })) {
        for (const t of b.o({ Track: 1 })) all.push(t)
    }
    this.Stuff_distil(holder, all, 'pool', ['title'], null)
    return holder

// Deepcrest — the Book (world MUST be named Deepcrest — do_fn_for dispatches by w.sc.w).
Deepcrest(A,w):
    w oai %req:wrangle,eternal
        await &Deepcrest_drive,w,req
        req%ok = 1

async Deepcrest_drive(w, req):
    let run = this.c.run
    if (run && run.sc && run.sc.mode === 'new') run.sc.total = 4
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.Deepcrest_bench(w)
        if (n === 3) this.Deepcrest_annex(w)
    }
    this.Deepcrest_witness(w)

// ── the bench: three families with engineered truths ──────────────────────────────────────────────
//  reef (5)   — vein dub crosses genre|mood · format flac · year SPREAD (2019×3 2007×2)
//  meadow (7) — all facts: flac · folk · hushed · 2007
//  vault (5)  — all facts: flac · jazz · hushed · 1959
//  Shared everywhere: format flac (the deepest truth).  Differing: genre (spreads at the top).
//   Blurred at level one: year in reef (must NEVER fake a fact above).
Deepcrest_bench(w):
    let ex = w.i({ Example: 1, name: 'library' })
    let reef = ex.i({ Brood: 1, name: 'reef' })
    reef.i({ Track: 1, title: 'Tide', genre: 'dub', mood: 'dub', format: 'flac', year: '2019' })
    reef.i({ Track: 1, title: 'Halo', genre: 'dub', mood: 'dub', format: 'flac', year: '2019' })
    reef.i({ Track: 1, title: 'Drift', genre: 'dub', mood: 'dub', format: 'flac', year: '2019' })
    reef.i({ Track: 1, title: 'Vane', genre: 'dub', mood: 'dub', format: 'flac', year: '2007' })
    reef.i({ Track: 1, title: 'Ebb', genre: 'dub', mood: 'dub', format: 'flac', year: '2007' })
    let meadow = ex.i({ Brood: 1, name: 'meadow' })
    let mnames = ['Root', 'Frond', 'Moss', 'Bloom', 'Seed', 'Bark', 'Fern']
    for (const t of mnames) meadow.i({ Track: 1, title: t, genre: 'folk', mood: 'hushed', format: 'flac', year: '2007' })
    let vault = ex.i({ Brood: 1, name: 'vault' })
    let vnames = ['Blue', 'Modal', 'Vamp', 'Sides', 'Nonet']
    for (const t of vnames) vault.i({ Track: 1, title: t, genre: 'jazz', mood: 'hushed', format: 'flac', year: '1959' })
    for (const b of ex.o({ Brood: 1 })) this.Deep_fam(ex, b)
    this.Deep_pool(ex)
    this.Deep_top(ex)

// beat 3 — the annex dissents: three mp3 rips join.  The shared truth format flac DEMOTES to a
//  spread (at the top AND in the pool — composition holds through change) and the door recounts.
Deepcrest_annex(w):
    let ex = w.o({ Example: 1, name: 'library' })[0]
    if (!ex) return
    let annex = ex.i({ Brood: 1, name: 'annex' })
    annex.i({ Track: 1, title: 'Byte', genre: 'dub', mood: 'dub', format: 'mp3', year: '1999' })
    annex.i({ Track: 1, title: 'Rip', genre: 'dub', mood: 'dub', format: 'mp3', year: '1999' })
    annex.i({ Track: 1, title: 'Cache', genre: 'dub', mood: 'dub', format: 'mp3', year: '1999' })
    this.Deep_fam(ex, annex)
    this.Deep_pool(ex)
    this.Deep_top(ex)

// ── the witness — flat · gated to its beat · comma-free · em-dash ─────────────────────────────────
Deepcrest_witness(w):
    let n = (this.c.run)?.c.step_n
    let ex = w.o({ Example: 1, name: 'library' })[0]
    let toph = ex ? ex.o({ Deep: 1, lvl: 'top' })[0] : null
    let top = toph ? toph.o({ Vtuffing: 1 })[0] : null
    let poolh = ex ? ex.o({ Deep: 1, lvl: 'pool' })[0] : null
    let pool = poolh ? poolh.o({ Vtuffing: 1 })[0] : null
    // the deepest shared truth rises: a fact in every family is a fact at the top
    let tf = top ? top.o({ Vrow: 1, row: 'fact', k: 'format' })[0] : null
    if (n === 2 && tf && tf.sc.v === 'flac' && !(oa %see:'the shared truth format flac rises intact through two distillations to the top crest')) i %see:'the shared truth format flac rises intact through two distillations to the top crest'
    // the vein survives the climb — memberise undoes the supersession so the crossing re-enters
    let tv = top ? top.o({ Vrow: 1, row: 'vein', v: 'dub' })[0] : null
    let tvg = tv ? tv.o({ Vbit: 1, k: 'genre' })[0] : null
    let tvm = tv ? tv.o({ Vbit: 1, k: 'mood' })[0] : null
    if (n === 2 && tv && tvg && tvm && !(oa %see:'the vein dub survives the climb — genre and mood still cross at the top because the crests carried the crossing')) i %see:'the vein dub survives the climb — genre and mood still cross at the top because the crests carried the crossing'
    // families that differ spread — the top never picks a winner
    let tg = top ? top.o({ Vrow: 1, row: 'spread', k: 'genre' })[0] : null
    let tgd = tg ? tg.o({ Vbit: 1, v: 'dub' })[0] : null
    let tgf = tg ? tg.o({ Vbit: 1, v: 'folk' })[0] : null
    let tgj = tg ? tg.o({ Vbit: 1, v: 'jazz' })[0] : null
    if (n === 2 && tg && tgd && tgf && tgj && !(oa %see:'families that differ spread at the top — genre says dub folk jazz side by side')) i %see:'families that differ spread at the top — genre says dub folk jazz side by side'
    // the blur boundary: what level one spread NEVER fakes a fact above — and the counts tell it
    let ty = top ? top.o({ Vrow: 1, row: 'spread', k: 'year' })[0] : null
    let tyf = top ? top.o({ Vrow: 1, row: 'fact', k: 'year' })[0] : null
    let ty7 = ty ? ty.o({ Vbit: 1, v: '2007' })[0] : null
    let py = pool ? pool.o({ Vrow: 1, row: 'spread', k: 'year' })[0] : null
    let py7 = py ? py.o({ Vbit: 1, v: '2007' })[0] : null
    if (n === 2 && ty && !tyf && ty7 && ty7.sc.n === 1 && py7 && py7.sc.n === 9 && !(oa %see:'a key already blurred at level one never fakes a fact at the top — year stays a spread and the top hears one voice for 2007 where the pool hears nine')) i %see:'a key already blurred at level one never fakes a fact at the top — year stays a spread and the top hears one voice for 2007 where the pool hears nine'
    // the composition claim judged against the referee
    let pf = pool ? pool.o({ Vrow: 1, row: 'fact', k: 'format' })[0] : null
    let pv = pool ? pool.o({ Vrow: 1, row: 'vein', v: 'dub' })[0] : null
    let pg = pool ? pool.o({ Vrow: 1, row: 'spread', k: 'genre' })[0] : null
    if (n === 2 && tf && tv && tg && pf && pf.sc.v === 'flac' && pv && pg && !(oa %see:'the crest of crests agrees with the crest of the pool — same dub vein same flac fact same genre spread')) i %see:'the crest of crests agrees with the crest of the pool — same dub vein same flac fact same genre spread'
    // Dip_assign at height: the door counts what it hides
    if (n === 2 && toph && toph.sc.deep === 17 && !(oa %see:'the deep count seventeen rides the top door — five and seven and five members held behind one dip')) i %see:'the deep count seventeen rides the top door — five and seven and five members held behind one dip'
    // beat 3 — dissent demotes: the shared truth falls to a spread everywhere at once
    let tf3 = top ? top.o({ Vrow: 1, row: 'fact', k: 'format' })[0] : null
    let ts3 = top ? top.o({ Vrow: 1, row: 'spread', k: 'format' })[0] : null
    let ps3 = pool ? pool.o({ Vrow: 1, row: 'spread', k: 'format' })[0] : null
    if (n === 3 && ts3 && !tf3 && ps3 && !(oa %see:'a dissenting family demotes the shared truth — format falls from fact to spread at the top and in the pool alike when the annex arrives carrying mp3')) i %see:'a dissenting family demotes the shared truth — format falls from fact to spread at the top and in the pool alike when the annex arrives carrying mp3'
    if (n === 3 && toph && toph.sc.deep === 20 && !(oa %see:'the door recounts to twenty when the annex joins — the dip count follows the truth it hides')) i %see:'the door recounts to twenty when the annex joins — the dip count follows the truth it hides'
//#endregion

//#region Readback — the read contract (Cstructures_todo §6) proven in isolation — THE KEYSTONE
// ══ Readback — read(render(tree)) ≡ tree modulo declared dips ═════════════════════════════════════
//  The steer said ACCURATELY READABLE — this Book makes that a contract and measures it.  A NEW
//   engine `Read_crest` INVERTS a crest: every claim in the %Vtuffing becomes a recovered MARGINAL
//    (%Marg — k·v·count) and every declared door becomes a counted %Tail stub.  `Read_audit` then
//     judges each recovered claim against the true family — claimed vs truth as DATA (%Audit rows ·
//      snap data not judgement).  What the notation states it states EXACTLY (the exact bench —
//       every audit lands claimed ≡ truth).  Where the notation UNDER-DECLARES the audit says so:
//        a valued fact carries no carrier count (the leaky bench — the read believes five where
//         three carry it) and a spread tail counts dropped VALUES not carriers (the tail bench —
//          plus three values hiding four members).  Both leaks go to the human as candidate
//           notation fixes (stamp n on valued facts · stamp have on spreads) — fixing them re-snaps
//            three green Books so it is a MORNING RULING not a night move.  Beat 3 the twins: two
//             families sharing every marginal but differing in the JOINT wear byte-identical
//              crests — the crest is marginal BY DESIGN and only the counted door (Read_surf — the
//               dip opened) tells them apart.  That is §6 injectivity made flesh: the count is the
//                whole difference between a crest and a lie.  No glass · no pixels · byte-stable.
//                 World MUST be named Readback (do_fn_for dispatches by w.sc.w).
//   beat 2  exact|leaky|tail benches — distil · read back · audit · surf the exact door
//   beat 3  the twins — identical crests over different joints · the door tells them apart

// Read_crest — the inverse engine: walk a crest holder's %Vtuffing and mint what a READER can
//  recover.  A vein bit hands back k·v·its own count (undoing the supersession).  A valued fact
//   claims ALL n members (the crest gives a reader no smaller number — that IS the leak the leaky
//    bench measures).  A counted presence fact keeps its n.  A spread chip keeps its n; a spread
//     tail becomes a %Tail stub — the declared door with what little it counts.
Read_crest(ex, holder):
    let vt = holder.o({ Vtuffing: 1 })[0]
    let rec = ex.i({ Recovered: 1, name: holder.sc.name, n: vt ? vt.sc.n : 0 })
    if (!vt) return rec
    for (const r of vt.o({ Vrow: 1 })) {
        if (r.sc.row === 'vein') {
            for (const b of r.o({ Vbit: 1 })) rec.i({ Marg: 1, k: b.sc.k, v: r.sc.v, n: b.sc.n })
        }
        if (r.sc.row === 'fact' && r.sc.v != null) rec.i({ Marg: 1, k: r.sc.k, v: r.sc.v, n: vt.sc.n })
        if (r.sc.row === 'fact' && r.sc.v == null) rec.i({ Marg: 1, k: r.sc.k, v: '1', n: r.sc.n })
        if (r.sc.row === 'spread') {
            for (const b of r.o({ Vbit: 1 })) {
                if (b.sc.v != null) rec.i({ Marg: 1, k: r.sc.k, v: b.sc.v, n: b.sc.n })
                if (b.sc.text != null) rec.i({ Tail: 1, k: r.sc.k, dropped: b.sc.text })
            }
        }
    }
    return rec

// Read_audit — the judge: every recovered marginal against the true family.  claimed ≡ truth is
//  the round trip closing; claimed ≠ truth is a leak the notation owes a count for.
Read_audit(ex, brood, rec):
    let tracks = brood.o({ Track: 1 })
    for (const m of rec.o({ Marg: 1 })) {
        let truth = 0
        for (const t of tracks) {
            if (('' + t.sc[m.sc.k]) === m.sc.v) truth = truth + 1
        }
        ex.i({ Audit: 1, fam: brood.sc.name, k: m.sc.k, v: m.sc.v, claimed: m.sc.n, truth: truth })
    }

// Read_surf — the dip opened: walk from the crest holder back through the family door and count
//  what is actually there against what the read was promised.
Read_surf(ex, name):
    let b = ex.o({ Brood: 1, name: name })[0]
    let rec = ex.o({ Recovered: 1, name: name })[0]
    let found = b ? b.o({ Track: 1 }).length : 0
    ex.i({ Surf: 1, name: name, found: found, promised: rec ? rec.sc.n : 0 })

// Read_saying — a crest normalised to one string (rows sorted · chips as ranked) so two crests can
//  be compared as SAYINGS.  Ranking ties are broken by insertion so the twin benches use distinct
//   counts (3|1) to keep chip order canonical.
Read_saying(ex, name):
    let h = ex.o({ Deep: 1, lvl: 'fam', name: name })[0]
    let vt = h ? h.o({ Vtuffing: 1 })[0] : null
    if (!vt) return ''
    let lines = []
    for (const r of vt.o({ Vrow: 1 })) {
        let line = r.sc.row + '|' + (r.sc.k || '') + '|' + (r.sc.v || '')
        for (const b of r.o({ Vbit: 1 })) line = line + '·' + (b.sc.k || '') + ':' + (b.sc.v || b.sc.text || '') + 'x' + b.sc.n
        lines.push(line)
    }
    lines.sort()
    return lines.join(';')

Read_same(ex, n1, n2):
    let s1 = this.Read_saying(ex, n1)
    let s2 = this.Read_saying(ex, n2)
    let tw = ex.i({ Twin: 1, a: n1, b: n2 })
    if (s1 !== '' && s1 === s2) {
        tw.sc.verdict = 'same'
    } else {
        tw.sc.verdict = 'differ'
    }
    return tw

// Readback — the Book (world MUST be named Readback — do_fn_for dispatches by w.sc.w).
Readback(A,w):
    w oai %req:wrangle,eternal
        await &Readback_drive,w,req
        req%ok = 1

async Readback_drive(w, req):
    let run = this.c.run
    if (run && run.sc && run.sc.mode === 'new') run.sc.total = 4
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.Readback_bench(w)
        if (n === 3) this.Readback_twins(w)
    }
    this.Readback_witness(w)

// ── the benches: what the notation states · where it under-declares ───────────────────────────────
//  exact (5) — vein dub crosses genre|mood · year spread 2019×3 2007×2 · NO tail — every claim total
//  leaky (5) — format flac total · room attic carried by THREE of five (the uncounted valued fact)
//  tail (11) — city over six values lon×3 par×2 ber×2 rom×2 mad nyc — chips keep 7 · +3 hides FOUR
Readback_bench(w):
    let ex = w.i({ Example: 1, name: 'contract' })
    let exact = ex.i({ Brood: 1, name: 'exact' })
    exact.i({ Track: 1, title: 'Tide', genre: 'dub', mood: 'dub', year: '2019' })
    exact.i({ Track: 1, title: 'Halo', genre: 'dub', mood: 'dub', year: '2019' })
    exact.i({ Track: 1, title: 'Drift', genre: 'dub', mood: 'dub', year: '2019' })
    exact.i({ Track: 1, title: 'Vane', genre: 'dub', mood: 'dub', year: '2007' })
    exact.i({ Track: 1, title: 'Ebb', genre: 'dub', mood: 'dub', year: '2007' })
    let leaky = ex.i({ Brood: 1, name: 'leaky' })
    leaky.i({ Track: 1, title: 'Attic1', format: 'flac', room: 'attic' })
    leaky.i({ Track: 1, title: 'Attic2', format: 'flac', room: 'attic' })
    leaky.i({ Track: 1, title: 'Attic3', format: 'flac', room: 'attic' })
    leaky.i({ Track: 1, title: 'Bare1', format: 'flac' })
    leaky.i({ Track: 1, title: 'Bare2', format: 'flac' })
    let tail = ex.i({ Brood: 1, name: 'tail' })
    let cities = ['lon', 'lon', 'lon', 'par', 'par', 'ber', 'ber', 'rom', 'rom', 'mad', 'nyc']
    let ci = 0
    for (const c of cities) {
        ci = ci + 1
        tail.i({ Track: 1, title: 'T' + ci, city: c })
    }
    for (const b of ex.o({ Brood: 1 })) {
        let h = this.Deep_fam(ex, b)
        let rec = this.Read_crest(ex, h)
        this.Read_audit(ex, b, rec)
    }
    this.Read_surf(ex, 'exact')

// beat 3 — the twins: marginals identical (hue sage×2 teal×2 · tone sage×3 teal×1 in BOTH) but the
//  joint differs — P holds a teal-teal member and Q holds none.  The asymmetric counts make every
//   vein-key and chip ranking COUNT-decided (teal is hue×2 tone×1 so the sort canonicalises what a
//    first-seen tie would leak — the joint must stay invisible in the saying); the one tie left
//     (hue chips sage2 teal2) first-sees sage in both.
Readback_twins(w):
    let ex = w.o({ Example: 1, name: 'contract' })[0]
    if (!ex) return
    let p = ex.i({ Brood: 1, name: 'p' })
    p.i({ Track: 1, title: 'P1', hue: 'sage', tone: 'sage' })
    p.i({ Track: 1, title: 'P2', hue: 'sage', tone: 'sage' })
    p.i({ Track: 1, title: 'P3', hue: 'teal', tone: 'teal' })
    p.i({ Track: 1, title: 'P4', hue: 'teal', tone: 'sage' })
    let q = ex.i({ Brood: 1, name: 'q' })
    q.i({ Track: 1, title: 'Q1', hue: 'sage', tone: 'sage' })
    q.i({ Track: 1, title: 'Q2', hue: 'sage', tone: 'teal' })
    q.i({ Track: 1, title: 'Q3', hue: 'teal', tone: 'sage' })
    q.i({ Track: 1, title: 'Q4', hue: 'teal', tone: 'sage' })
    for (const nm of ['p', 'q']) {
        let b = ex.o({ Brood: 1, name: nm })[0]
        let h = this.Deep_fam(ex, b)
        this.Read_crest(ex, h)
        this.Read_surf(ex, nm)
    }
    this.Read_same(ex, 'p', 'q')

// ── the witness — flat · gated to its beat · comma-free · em-dash ─────────────────────────────────
Readback_witness(w):
    let n = (this.c.run)?.c.step_n
    let ex = w.o({ Example: 1, name: 'contract' })[0]
    // the round trip closes: every exact-bench audit lands claimed ≡ truth
    let ag = ex ? ex.o({ Audit: 1, fam: 'exact', k: 'genre', v: 'dub' })[0] : null
    let am = ex ? ex.o({ Audit: 1, fam: 'exact', k: 'mood', v: 'dub' })[0] : null
    let a9 = ex ? ex.o({ Audit: 1, fam: 'exact', k: 'year', v: '2019' })[0] : null
    let a7 = ex ? ex.o({ Audit: 1, fam: 'exact', k: 'year', v: '2007' })[0] : null
    if (n === 2 && ag && ag.sc.claimed === 5 && ag.sc.truth === 5 && am && am.sc.claimed === 5 && am.sc.truth === 5 && a9 && a9.sc.claimed === 3 && a9.sc.truth === 3 && a7 && a7.sc.claimed === 2 && a7.sc.truth === 2 && !(oa %see:'the crest read back recovers every marginal exactly — counts and all — the round trip closes modulo the declared doors')) i %see:'the crest read back recovers every marginal exactly — counts and all — the round trip closes modulo the declared doors'
    // the door opens: the dip surf finds exactly what the read was promised
    let se = ex ? ex.o({ Surf: 1, name: 'exact' })[0] : null
    if (n === 2 && se && se.sc.found === 5 && se.sc.promised === 5 && !(oa %see:'the door opens — surfing the dip from the crest recovers the five members the count promised')) i %see:'the door opens — surfing the dip from the crest recovers the five members the count promised'
    // leak one: a valued fact carries no carrier count so the read believes the whole family
    let al = ex ? ex.o({ Audit: 1, fam: 'leaky', k: 'room', v: 'attic' })[0] : null
    if (n === 2 && al && al.sc.claimed === 5 && al.sc.truth === 3 && !(oa %see:'the crest under-declares a partial fact — the read believes five carriers of attic where three exist — the one leak the contract names')) i %see:'the crest under-declares a partial fact — the read believes five carriers of attic where three exist — the one leak the contract names'
    // leak two: the spread tail counts dropped values not carriers
    let rtl = ex ? ex.o({ Recovered: 1, name: 'tail' })[0] : null
    let tl = rtl ? rtl.o({ Tail: 1, k: 'city' })[0] : null
    let tb = ex ? ex.o({ Brood: 1, name: 'tail' })[0] : null
    let alon = ex ? ex.o({ Audit: 1, fam: 'tail', k: 'city', v: 'lon' })[0] : null
    if (n === 2 && tl && tl.sc.dropped === '+3' && tb && tb.o({ Track: 1 }).length === 11 && alon && alon.sc.claimed === 3 && alon.sc.truth === 3 && !(oa %see:'a spread tail counts its dropped values but not their carriers — the tail says three values while four members hide behind it')) i %see:'a spread tail counts its dropped values but not their carriers — the tail says three values while four members hide behind it'
    // the twins: identical sayings over different joints — only the door tells them apart
    let tw = ex ? ex.o({ Twin: 1, a: 'p' })[0] : null
    let pb = ex ? ex.o({ Brood: 1, name: 'p' })[0] : null
    let qb = ex ? ex.o({ Brood: 1, name: 'q' })[0] : null
    let pj = pb ? pb.o({ Track: 1, hue: 'teal', tone: 'teal' })[0] : null
    let qj = qb ? qb.o({ Track: 1, hue: 'teal', tone: 'teal' })[0] : null
    if (n === 3 && tw && tw.sc.verdict === 'same' && pj && !qj && !(oa %see:'two families with one joint difference wear identical crests — the crest is marginal by design and only the counted door tells them apart')) i %see:'two families with one joint difference wear identical crests — the crest is marginal by design and only the counted door tells them apart'
    let sp = ex ? ex.o({ Surf: 1, name: 'p' })[0] : null
    let sq = ex ? ex.o({ Surf: 1, name: 'q' })[0] : null
    if (n === 3 && sp && sp.sc.found === 4 && sp.sc.promised === 4 && sq && sq.sc.found === 4 && sq.sc.promised === 4 && !(oa %see:'the twin doors open to the same counts and different rooms — four members each with the joints differing exactly where the crest stayed silent')) i %see:'the twin doors open to the same counts and different rooms — four members each with the joints differing exactly where the crest stayed silent'
//#endregion

//#region Surfline — the composed kernel (Nestcut × Floorlaw × reframe) proven in one stack
// ══ Surfline — the cut prices the rooms · the floor law spends them · the surf re-roots ═══════════
//  The machine kernel in one Book with NO new engine: `Nestcut_cut` (J4) tessellates the root room
//   among three scopes and each cell AREA becomes the frame `Floorlaw_solve` (J2) prices — geometry
//    hands its output straight to the law because both speak C.  The surf (J5) is beat 3: entering
//     a scope makes its cell the viewport — the SAME solve at the room the reframe grants — and the
//      shoal that crushed in its corner un-crushes with the whole frame behind it while every room
//       not surfed keeps its price to the byte (the scope seam again — this time across ENGINES).
//        All pins hand-derived and integer-anchored: rooms 136872|134622|88506 of 360000 (the
//         proven Nestcut triple) · A crushed Σw 16+2 → S = √(136872/18) = √7604 → 8720 · B Σw 36 →
//          √3739.5 → 6115 · surf √(360000/21) → 13093.  No glass · no pixels · byte-stable.
//           World MUST be named Surfline (do_fn_for dispatches by w.sc.w).
//   beat 2  cut the chart · price three scopes at their cell frames — crush | legible | crush
//   beat 3  surf into scope A — un-crush at the granted room · every other price holds still
//   beat 4  a QUIET beat — nothing changes — the trees hold

// ── the bench: the proven 800×450 triple (A r60 · B r40 · C r40) prices three scopes ──────────────
//  scopeA — a loud loose head (w16) over five meek minnows (w1): its 136872 room crushes them
//  scopeB — four whales (w9): loud enough that 134622 keeps every voice legible
//  scopeC — twelve plankton (w1): the crowd seals to a crest that frees ten voices
Surfline_bench(w):
    let ex = w.i({ Example: 1, name: 'chart' })
    let root = ex.i({ Cell: 1, label: 'root', area: 360000, cx: 400, cy: 225 })
    let frame = []
    frame.push({ x: 0, y: 0 })
    frame.push({ x: 800, y: 0 })
    frame.push({ x: 800, y: 450 })
    frame.push({ x: 0, y: 450 })
    root.c.poly = frame
    let plan = []
    plan.push({ label: 'A', x: 200, y: 150, r: 60 })
    plan.push({ label: 'B', x: 600, y: 150, r: 40 })
    plan.push({ label: 'C', x: 400, y: 350, r: 40 })
    this.Nestcut_cut(root, frame, plan)
    let ca = this.Nestcut_cell(root, 'A')
    let cb = this.Nestcut_cell(root, 'B')
    let cc = this.Nestcut_cell(root, 'C')
    let sa = w.i({ Example: 1, name: 'scopeA' })
    this.Floorlaw_loose(sa, 'head', 16)
    let ab = this.Floorlaw_brood(sa, 'minnows')
    for (const t of ['Fry', 'Roe', 'Smolt', 'Parr', 'Grilse']) ab.i({ Track: 1, title: t, genre: 'dub', w: 1 })
    let sb = w.i({ Example: 1, name: 'scopeB' })
    let bb = this.Floorlaw_brood(sb, 'whales')
    for (const t of ['Blue', 'Fin', 'Sei', 'Gray']) bb.i({ Track: 1, title: t, genre: 'deep', w: 9 })
    let sc2 = w.i({ Example: 1, name: 'scopeC' })
    let pb = this.Floorlaw_brood(sc2, 'plankton')
    for (const t of ['Krill', 'Copepod', 'Mysid', 'Salp', 'Diatom', 'Volvox', 'Ciliate', 'Rotifer', 'Amoeba', 'Spora', 'Algula', 'Nauplius']) pb.i({ Track: 1, title: t, genre: 'algae', w: 1 })
    if (ca) this.Floorlaw_solve(sa, ca.sc.area, 100)
    if (cb) this.Floorlaw_solve(sb, cb.sc.area, 100)
    if (cc) this.Floorlaw_solve(sc2, cc.sc.area, 100)

// beat 3 — the surf: entering scope A grants it the whole 360000 room (its cell becomes the
//  viewport) and the SAME law re-prices it — nothing else is touched.
Surfline_surf(w):
    let sa = w.o({ Example: 1, name: 'scopeA' })[0]
    if (!sa) return
    this.Floorlaw_solve(sa, 360000, 100)

// Surfline — the Book (world MUST be named Surfline — do_fn_for dispatches by w.sc.w).
Surfline(A,w):
    w oai %req:wrangle,eternal
        await &Surfline_drive,w,req
        req%ok = 1

async Surfline_drive(w, req):
    let run = this.c.run
    if (run && run.sc && run.sc.mode === 'new') run.sc.total = 4
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.Surfline_bench(w)
        if (n === 3) this.Surfline_surf(w)
    }
    this.Surfline_witness(w)

// ── the witness — flat · gated to its beat · comma-free · em-dash ─────────────────────────────────
Surfline_witness(w):
    let n = (this.c.run)?.c.step_n
    let chart = w.o({ Example: 1, name: 'chart' })[0]
    let root = chart ? chart.o({ Cell: 1, label: 'root' })[0] : null
    let ca = this.Nestcut_cell(root, 'A')
    let cb = this.Nestcut_cell(root, 'B')
    let cc = this.Nestcut_cell(root, 'C')
    let rooms = ca && ca.sc.area === 136872 && cb && cb.sc.area === 134622 && cc && cc.sc.area === 88506 && root && root.sc.misfit === 0
    if (n === 2 && rooms && !(oa %see:'the cut prices the rooms — three scopes claim 136872 and 134622 and 88506 of one 360000 frame with nothing lost')) i %see:'the cut prices the rooms — three scopes claim 136872 and 134622 and 88506 of one 360000 frame with nothing lost'
    let sca = this.Floorlaw_scale(w, 'scopeA')
    let cra = this.Floorlaw_crushrow(sca, 'minnows')
    let scb = this.Floorlaw_scale(w, 'scopeB')
    let crb = this.Floorlaw_crushrow(scb, 'whales')
    if (n === 2 && sca && sca.sc.S === 8720 && cra && cra.sc.freed === 3 && scb && scb.sc.S === 6115 && !crb && !(oa %see:'the floor law spends each room as the cut priced it — the meek shoal crushes at 8720 in its small room while the loud whales next door stay legible at 6115')) i %see:'the floor law spends each room as the cut priced it — the meek shoal crushes at 8720 in its small room while the loud whales next door stay legible at 6115'
    let scc = this.Floorlaw_scale(w, 'scopeC')
    let crc = this.Floorlaw_crushrow(scc, 'plankton')
    if (n === 2 && crc && crc.sc.freed === 10 && !(oa %see:'the crowded scope seals too — twelve plankton crush to a crest freeing ten voices')) i %see:'the crowded scope seals too — twelve plankton crush to a crest freeing ten voices'
    if (n === 3 && sca && sca.sc.S === 13093 && !cra && !(oa %see:'surf into the scope and its cell becomes the viewport — the shoal un-crushes at 13093 with the whole room behind it')) i %see:'surf into the scope and its cell becomes the viewport — the shoal un-crushes at 13093 with the whole room behind it'
    if (n === 3 && scb && scb.sc.S === 6115 && !crb && crc && crc.sc.freed === 10 && !(oa %see:'the seam holds — the rooms not surfed keep their prices — the whales still at 6115 and the plankton crest still freeing ten')) i %see:'the seam holds — the rooms not surfed keep their prices — the whales still at 6115 and the plankton crest still freeing ten'
    if (n === 3 && rooms && !(oa %see:'the chart never re-cut — the rooms stand while the surf re-prices only the scope it entered')) i %see:'the chart never re-cut — the rooms stand while the surf re-prices only the scope it entered'
//#endregion
