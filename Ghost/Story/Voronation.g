
//#region pier — VoroRadioPier: the tuner drifts over MUSIC dribbled in from a (fake) Pier
// < strewn with test data to move out to Voronation.g
// ══ the fake music Pier — a deterministic catalog, the DRIBBLE-SOURCE the tuner walks ═══════════
//  "VoroRadio feeding music in from a Pier" (owner), the Pier "very fake" by licence.  Structurally
//   the flora-mirror: a %Pier holds tracks keyed STATION-as-mainkey ({Fernway:'Tide'}) exactly as
//    the flora keys taxa genus-as-mainkey, so the SAME crush gangs same-station tracks into a locale
//     and the SAME Voro_drift_tick walks across stations — zero new render, zero new fold policy.
//      No transport, no audio, no wall clock: tracks are the deterministic sprinkle twin of
//       Botany_plant (fixtures byte-stable).  The Pier is the source content flows in from (spec
//        Voro_vtuffing.md §Owner vision seeds — dribble → swish → Travel → trail).
Radio_stations():
    return ['Fernway', 'Moonlit', 'Kolter', 'Sable', 'Vireo', 'Halcyon', 'Brasswick', 'Lowfield']
Radio_titles():
    return ['Tide', 'Halo', 'Drift', 'Ember', 'Vellum', 'Marrow', 'Cinder', 'Fathom', 'Glass', 'Lantern', 'Pulse', 'Ridge', 'Solace', 'Wend', 'Yolk', 'Zephyr']
Radio_genres():
    return ['dreampop', 'krautrock', 'ambient']

// plant one track under the pier, keyed by its STATION (the mainkey, so a station's tracks gang);
//  a deterministic sprinkle rides each (stable fixtures): a %year of three values (a Vtuffing
//   SPREAD — chips), %live on ~1/3 (a presence-FACT — 'live ×N'), and a %genre the whole station
//    agrees on (a shared FACT), so a station pane speaks like a real locale.  vfamily by genre
//     ropes same-genre stations into one ⬡ hull.  Station stays the first key.
Radio_track(pier, station, title):
    let sc = {}
    sc[station] = title
    let hsh = this.Voro_hash(station + '|' + title)
    let years = ['1998', '2007', '2019']
    sc.year = years[hsh % 3]
    if (hsh % 3 === 0) sc.live = 1
    let genres = this.Radio_genres()
    sc.genre = genres[this.Voro_hash(station) % 3]
    let tr = pier.i(sc)
    tr.c.vfamily = 'pier:' + sc.genre
    return tr

// tune k tracks of a station into the pier (the flora-mirror of VoroMitosis_found).  Offset the
//  title index by how many the station ALREADY has, so a later dribble adds FRESH titles instead of
//   re-planting the seed's ({station:title} would collide → a station showing the same track twice).
Radio_station_in(pier, station, k):
    let titles = this.Radio_titles()
    let si = this.Radio_stations().indexOf(station)
    if (si < 0) si = 0
    let have = pier.o().filter(c => Object.keys(c.sc)[0] === station).length
    for (let t = 0; t < k; t++) this.Radio_track(pier, station, titles[(si * 3 + have + t) % titles.length])

// the pier itself — one dribble-source node under w
Radio_pier(w):
    let p = w.o({ Pier: 1, name: 'Crowd' })[0]
    if (!p) p = w.i({ Pier: 1, name: 'Crowd' })
    return p

// the initial library: six stations open at once so ≥4 locales exist for the drift-count witness
Radio_seed(w):
    let p = this.Radio_pier(w)
    this.Radio_station_in(p, 'Fernway', 4)
    this.Radio_station_in(p, 'Moonlit', 3)
    this.Radio_station_in(p, 'Kolter', 4)
    this.Radio_station_in(p, 'Sable', 3)
    this.Radio_station_in(p, 'Vireo', 4)
    this.Radio_station_in(p, 'Halcyon', 3)

// the stream keeps flowing: one more track dribbles onto a station each drift beat (deterministic
//  by beat, so the fold GROWS under the tuner — the Pier is not a one-shot seed but a source).
Radio_dribble(w, n):
    let p = this.Radio_pier(w)
    let sts = this.Radio_stations()
    this.Radio_station_in(p, sts[n % 6], 1)

//#endregion


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
        if (n >= 2) this.Voro_crush_scan(w)
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






// ══ VoroRadioPier — VoroRadio's music twin: the tuner PROVEN over a streamed Pier of stations ════
//  brand_new — record LIVE with eyes on (this session compile-verified + smoke-checked it, did NOT
//   record fixtures).  Same witness shape as VoroRadio (moving) plus two Pier-specific truths: the
//    TRAIL was kept (the durable breadcrumb — "saving the trail") and music DRIBBLED in (the stream
//     folded into locales).  The world MUST be named VoroRadioPier (Story_subHouse dispatches by it).
VoroRadioPier(A, w):
    w oai %req:wrangle,eternal
        await &VoroRadioPier_drive,w,req
        req%ok = 1

async VoroRadioPier_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.Radio_seed(w)
        if (n >= 3 && n <= 8) this.Radio_dribble(w, n)
        if (n >= 2) this.Voro_crush_scan(w)
        if (n >= 3 && n <= 8) {
            let pick = await this.Voro_drift_tick(w)
            let picks = w.c.radio_picks || []
            if (pick) picks.push(pick)
            w.c.radio_picks = picks
            // saving the trail: a DURABLE breadcrumb of the WHOLE path (not just the drift_opens
            //  window of 4) — station + track at each dwell, a down-payment on the §Owner vision.
            let trail = w.c.radio_trail || []
            if (pick) {
                let mk = Object.keys(pick.sc)[0]
                trail.push({ seq: n, station: mk, track: pick.sc[mk] })
            }
            w.c.radio_trail = trail
        }
        if (n === 9) this.VoroRadioPier_witness(w)
    }

VoroRadioPier_witness(w):
    let picks = w.c.radio_picks || []
    let distinct = picks.filter((p, i) => picks.indexOf(p) === i).length
    if (picks.length >= 5 && distinct >= 4 && !(oa %see:'the tuner walked the pier — six dwells lit four or more distinct stations of streamed music')) i %see:'the tuner walked the pier — six dwells lit four or more distinct stations of streamed music'
    let trail = w.c.radio_trail || []
    if (trail.length >= 5 && !(oa %see:'the trail was kept — every dwell left a breadcrumb of its station and track behind the listener')) i %see:'the trail was kept — every dwell left a breadcrumb of its station and track behind the listener'
    let p = w.o({ Pier: 1 })[0]
    let ntracks = p ? p.o().length : 0
    if (ntracks >= 12 && !(oa %see:'music dribbled in from the pier — a dozen or more tracks streamed in and folded into station locales')) i %see:'music dribbled in from the pier — a dozen or more tracks streamed in and folded into station locales'



//#endregion

//#region radio — VoroRadio: the tuner PROVEN (📻 drift as a deterministic Story Book)


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
        if (n >= 2) this.Voro_crush_scan(w)
        if (n === 3) this.VoroClinic_witness(w)
    }

// two folded libraries (container folds via Voro_crushable) + one gang of noisy leaves (gang-fold);
//  deterministic, so the crush verdict is a pure function of this world — fixtures byte-stable.
VoroClinic_seed(w):
    let a1 = w.i({ Artist: 1, name: 'Alpha' })
    a1.i({ Track: 1, title: 'a1' })
    a1.i({ Track: 1, title: 'a2' })
    a1.i({ Track: 1, title: 'a3' })
    a1.i({ Track: 1, title: 'a4' })
    let a2 = w.i({ Artist: 1, name: 'Beta' })
    a2.i({ Track: 1, title: 'b1' })
    a2.i({ Track: 1, title: 'b2' })
    a2.i({ Track: 1, title: 'b3' })
    a2.i({ Track: 1, title: 'b4' })
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
        if (n >= 2) this.Voro_crush_scan(w)
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

//#region scape — VoroScape: the GRAPH OF MUSIC rendered as voronoi stained glass
// ══ VoroScape — a music library becomes a graph when friends share it, and the crush folds it to glass ══
//  The music twin of VoroMitosis (which watched abstract flora divide).  Here the cells are MUSIC and the
//   edges are SOCIAL: %Artist panes hold their %Track songs; %Peer panes each %Share tracks from the
//    library — and a share is an EDGE from a friend onto a real track.  A track many friends share is a
//     HUB: its pane claims more room (the power-diagram weight the voronoi reads off a big node).  A track
//      nobody shares is a sliver; a deep cut nobody touches goes dark.  So the stained glass is not a flat
//       shelf — some panes blaze (the hits), some are slivers (the deep cuts), and the light moves live as
//        friends come and go.  Like VoroMitosis: cells live DIRECTLY under w (the crusher folds any content
//         container, so an umbrella would swallow the whole scape as ONE chunk); crush armed c-side (no opt,
//          nothing modelled), no transport, no audio, count-driven determinism — runs anywhere a runner does.
//   beat 2  the library stands — three artists and their five tracks — a shelf, no friends, no light yet
//   beat 3  a friend (Bo) arrives and shares — every share is an edge onto a REAL track — a graph is born
//   beat 4  a second friend (Ada) shares the same track — it lights up as a HUB (weight 2) above the singles
//   beat 5  Ada leaves — the hub cools LIVE (2 -> 1) and a track she alone lit goes dark (1 -> 0)
//   beat 6  the crush folds every artist and friend into one stuffed pane — the graph arms as stained glass
VoroScape(A,w):
    w oai %req:wrangle,eternal
        await &VoroScape_drive,w,req
        req%ok = 1

async VoroScape_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.VoroScape_library(w)
        if (n === 3) this.VoroScape_peer(w, 'Bo', ['Tide', 'Root', 'Echo'])
        if (n === 4) this.VoroScape_peer(w, 'Ada', ['Tide', 'Halo'])
        if (n === 5) this.VoroScape_leave(w, 'Ada')
    }
    this.VoroScape_witness(w)
    await this.VoroScape_order(w)

// beat 2 — the library: three artists, each an %Artist pane holding its %Track songs (five in all).  The
//  crushable rule folds any container with children, so each artist becomes one voronoi pane; the tracks
//   ride inside it (a pane's interior).  No peers yet — a shelf, not a graph.
VoroScape_library(w):
    let moon = w.i({ Artist: 1, name: 'Moonlit' })
    this.VoroScape_track(moon, 'Tide')
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
    artist.i(sc)

// a friend joins and shares tracks off the library — each %Share is an EDGE from the %Peer pane onto a
//  track by its title.  (A share names a track; VoroScape_dangling proves it names a REAL one.)
VoroScape_peer(w, name, tracks):
    let p = w.i({ Peer: 1, name: name })
    for (const t of tracks) p.i({ Share: 1, track: t })
    return p

// a friend leaves — their pane drops out and their shares go with it (apoptosis, VoroMitosis's death twin):
//  a track they alone shared goes dark, a hub they helped light cools by one.
VoroScape_leave(w, name):
    let p = w.o({ Peer: 1 }).find(x => x.sc.name === name)
    if (p) p.drop(p)

// every track title in the library (walk the artists' panes).
VoroScape_titles(w):
    let titles = []
    for (const a of w.o({ Artist: 1 })) for (const t of a.o({ Track: 1 })) titles.push(t.sc.title)
    return titles

// a share that names no real track is a DANGLING pane — a bug in the graph.  Zero is the health check.
VoroScape_dangling(w):
    let titles = this.VoroScape_titles(w)
    let bad = 0
    for (const p of w.o({ Peer: 1 })) for (const s of p.o({ Share: 1 })) if (!titles.includes(s.sc.track)) bad = bad + 1
    return bad

// the HUB weight of a track: how many distinct friends share it.  This is the power-diagram weight the
//  voronoi reads off the pane's rendered size — a hit blazes, a deep cut is a sliver, zero is dark.
VoroScape_hub(w, title):
    let count = 0
    for (const p of w.o({ Peer: 1 })) if (p.o({ Share: 1 }).some(s => s.sc.track === title)) count = count + 1
    return count

// ── the witness — each %see is a per-beat OBSERVATION gated to its step (n === K) reading the LIVE truth
//  of that beat, so it appears once and DROPS as the story moves on.  The drop IS the signal: beat 4's
//   "it lights up as a hub" (weight 2) gives way to beat 5's "the hub cools" (weight 1) — the same track,
//    re-weighted live.  Do NOT persist a claim past its beat (that is the old %witnessed noise reborn).
VoroScape_witness(w):
    let n = (this.c.run)?.c.step_n
    let artists = w.o({ Artist: 1 })
    let tracks = []
    for (const a of artists) for (const t of a.o({ Track: 1 })) tracks.push(t)
    let peers = w.o({ Peer: 1 })
    // beat 2: the library stands — three artists, five tracks, no friends: a shelf with no light through it.
    if (n === 2 && artists.length === 3 && tracks.length === 5 && !peers.length && !(oa %see:'the library stands — three artists and five tracks — a shelf of glass with no light through it yet')) i %see:'the library stands — three artists and five tracks — a shelf of glass with no light through it yet'
    // beat 3: a friend shares — every share edges onto a REAL track (no dangling) — the shelf is now a graph.
    if (n === 3 && peers.length === 1 && this.VoroScape_dangling(w) === 0 && this.VoroScape_hub(w, 'Tide') === 1 && !(oa %see:'a friend arrives and shares — every share is an edge onto a real track — the shelf becomes a graph')) i %see:'a friend arrives and shares — every share is an edge onto a real track — the shelf becomes a graph'
    // beat 4: two friends on one track — it lights up as a HUB (weight 2) above the singles and the deep cut.
    if (n === 4 && peers.length === 2 && this.VoroScape_hub(w, 'Tide') === 2 && this.VoroScape_hub(w, 'Root') === 1 && this.VoroScape_hub(w, 'Frond') === 0 && !(oa %see:'two friends share one track — it lights up as a hub — its pane claims more room while a deep cut stays a sliver')) i %see:'two friends share one track — it lights up as a hub — its pane claims more room while a deep cut stays a sliver'
    // beat 5: a friend leaves — the hub cools LIVE (2 -> 1) and a track she alone lit goes dark (1 -> 0).
    if (n === 5 && peers.length === 1 && this.VoroScape_hub(w, 'Tide') === 1 && this.VoroScape_hub(w, 'Halo') === 0 && !(oa %see:'a friend leaves and the hub cools — the shared track drops to one and a track only she lit goes dark')) i %see:'a friend leaves and the hub cools — the shared track drops to one and a track only she lit goes dark'
    // the fold is IMPOSED by Story (%useVoroCyto) and self-reports in w:Voronoiology — VoroScape asserts
    //  only its own music-graph truths (hubs, dangling, apoptosis), never the fold.  See fig.1 in Story.

// float A:VoroScape to the front of H/* so the Run snap stays readable (MusuSkip_order's twin).
async VoroScape_order(w):
    let As = H.o({ A: 1 })
    if (!As.length) return
    let first = (a) => (a.sc.A === 'VoroScape') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)
//#endregion

//#region reference — the canonical Voro sets, as data (a nav aid + a future sweep target)

// Voro_render_map — the stages in order (this ghost's crush, then Cytui's pixels), to walk the pipeline.
Voro_render_map():
    return ['Voro_crush_scan', 'Vtuff_build', 'voronoi_layout', 'install_nuclei', 'morph_voronoi', 'voronoi_paint_now', 'paint_final']

//#endregion