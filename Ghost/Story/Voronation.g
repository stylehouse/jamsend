
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
        // AWAIT: the crush now grasps in its tail (snapped %Se:scape row) — let it settle before snap.
        if (n >= 2) await this.Voro_crush_scan(w)
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
        // AWAIT: the crush now grasps in its tail (snapped %Se:scape row) — let it settle before snap.
        if (n >= 2) await this.Voro_crush_scan(w)
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