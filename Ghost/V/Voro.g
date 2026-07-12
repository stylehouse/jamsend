// Voro.g — the Vis family home: the Voronoi-Cyto render (Ghost/V/, Waft:Ghost/Vis/Visua).
//  A late sibling to networking (N), music (M) and society (S).  But where THOSE are spines the
//   runner RUNS, Vis is a lens the runner LOOKS THROUGH — so the runtime here is small and
//    view-shaped: the CRUSH policy (below) that decides what folds, plus the family's own two demo
//     Books (VoroMitosis, VoroScape).  The pixels stay in the widget (src/lib/O/Cytui.svelte)
//      because they are SVG over the live Cytoscape canvas, not particles.
//
// The idea (see also the memory voronoi-cells-render):
//  Cyto stays the LAYOUT engine — fcose decides where the crushed chunks want to sit — and the
//   render REINTERPRETS that result.  Each crushed chunk seeds a cell at its node's rendered
//    position, weighted by its content box (a power diagram, so a big chunk claims more room),
//     and its Stuffing is molded into the cell.  Adjacency reads as shared WALLS not wires.
//  Orderless siblings would grid-jitter under a pure force sim, so a hidden NUCLEUS per parent
//   gathers them into a radial flower (a rosette that voronois cleanly) — scaffold only, never a
//    cell, never snapped.  It auto-arms when a wave ferries a crusher-stamped particle (c.stuffy);
//     the ◈ bar button overrides either way — and on a world whose Book never crushed, ◈ IMPOSES
//      the crush (e_Cyto_crush arms c.crush_wanted on the scan root; Cyto then runs the crusher
//       below before every scan).  The whole layer is a LUXURY: switch it on over any graph,
//        switch it off, and the Story underneath never knows.

//#region crush — fold big homogeneous collections behind ONE stuffed chunk each (all c-side)
// ══ the data-crusher (grew up as Repli_crush_* in Musuation.g; the Vis family owns it now) ═════
//  A busy world is mostly CONFETTI — 16 emits + 16 unemits per pier side, a Record per tone —
//   drawn raw the graph is too big to read a label of.  The crush folds it: ANY non-structural
//    container with children is stamped c.stuff — Cyto then draws it as one chunk hosting a live
//     Stuffing overlay (the ×N fold) and stops its walk there (descent suppressed at a stuffed
//      node).
//  ALL stamps are c-side (c.stuff the fold, c.stuffy the skin) — NEVER snapped, so NOTHING the
//   crush does reaches a got_snap.  The crush is a VIEW someone switches on, and a view must not
//    change what a Story records.  There is NO report particle any more (the old flat %Crush_Tree
//     is gone — it was the one thing the crush still snapped): the fold TOTALS a proof Book wants
//      come back as live stats from the scan, read off the c-side stamps, never modelled.
//  NO gate: Voro_crush_scan folds whatever w it is handed.  Two callers.  (1) IMPOSED from above —
//   a Book whose subject is NOT Voro (VoroScape=music, MusuReplica=replication) carries %useVoroCyto
//    in its toc Opt and Story imposes the fold at SNAP time (story_snap); the Book never touches it.
//     (2) DRIVEN inline — a Book whose subject IS Voro (VoroMitosis=the fold, VoroRadio=the radio
//      that eats the fold) calls it in its own do_fn, same-beat, because its behaviour|%see consume
//       the fold.  The ◈ button (Cyto's e_Cyto_crush) is a third, LIVE-only path on the Cyto mirror.

// Voro_crush_scan — the INTENSITY GOVERNOR (the owner's "hover around a sensible intensity,
//  aim for 9 families or so").  Each pass is authoritative (it stamps AND unstamps, so a level
//   change or a shrunken graph self-corrects) and counts stats.visible — the nodes the Cyto walk
//    will actually draw (folds, gang reps, loose leaves, walked-through structure; w/H/A and
//     represented members don't count).  Too dense → escalate the crush level and re-pass; too sparse
//      → relax, but never back past the ceiling.  The level rides w.c.crush_level (c-side) as
//       hysteresis across beats, so the graph doesn't flap between levels while it grows.
//  RETURN shape: {folded,count} = container folds only (now surfaced in w:Voronoiology's row, no
//   longer a Book %see); gang folds ride separately as {gangs,ganged}, plus {visible,level}.
//  quiet: stamp only, no self-report — the pre-scan pass (Voro_crush_worlds) re-stamps so the
//   WAVE ferries fresh folds, but the census (and its beat counter, pinned in fixtures) must
//    keep landing exactly once per beat, at snap time.
Voro_crush_scan(w, quiet, fixed):
    // fixed != null → crush at exactly that level, no auto-levelling.  The escalate|de-escalate dance
    //  below is a VIEWPORT heuristic (keep 6..15 cells on screen); an isolated small world (a VoroTest
    //   %Example) never trips the 15 budget so it would never gang.  A unit harness wants a DETERMINISTIC
    //    level that demonstrates the rule, so it pins one (L2, where non-noisy gang_min is 3).
    let level = fixed != null ? fixed : (w.c.crush_level || 0)
    let stats = this.Voro_crush_pass(w, level)
    if (fixed == null) {
        while (stats.visible > 15 && level < 2) {
            level = level + 1
            stats = this.Voro_crush_pass(w, level)
        }
        while (level > 0 && stats.visible < 6) {
            let trial = this.Voro_crush_pass(w, level - 1)
            if (trial.visible > 15) {
                stats = this.Voro_crush_pass(w, level)
                break
            }
            level = level - 1
            stats = trial
        }
    }
    w.c.crush_level = level
    if (!quiet) {
        this.Voro_report(w, stats)
        // the Se GRASP rides here, in the crush governor's tail, so EVERY crush user gets it for free
        //  — not just VoroMitosis (which drove it by hand) but VoroScape (imposed from above via the
        //   toc's useVoroCyto) and the VoroRadio family too.  Only on the census-authoring pass, never
        //    quiet: the pre-scan Voro_crush_worlds runs quiet and must NOT double-mint the Seem.
        //  GUARDED on folds: a world the crush found nothing to fold in (a non-Voro graph, level 0 with
        //   no gangs) gets no grasp — we don't stand an empty %Seem:scape on it.  Voro_grasp awaits, so
        //    this body is async from here down; each CALLER keeps its own await|fire-and-forget stance,
        //     but a caller whose snap must carry the %Se:scape row has to AWAIT (the census|report rows
        //      land synchronously ABOVE this await; only the grasp's row rides after it).
        if (stats.folded > 0 || stats.gangs > 0) {
            await this.Voro_grasp(w)
            // THE MODEL rides right behind the grasp, in the same fold guard — it reads the grasp's
            //  the:family stamps and the wgt the grasp wrote onto each Vtuffing row, then emits the
            //   per-family readings a consumer would otherwise re-derive from pixels.  Same census-
            //    authoring-pass discipline: never the quiet pre-scan (that would double-mint the Seem).
            await this.Voro_model(w)
        }
    }
    return stats

// Voro_crush_worlds — the PRE-SCAN imposition: crush every Run world (skipping the Voronoiology
//  projection — never fold the report) right before Cyto scans, so the wave that ferries a
//   newborn already carries its fold.  Without this the stamps land at SNAP time (story_snap),
//    one tick AFTER the scan — a flooding step waved raw nodes and only the NEXT step's scan
//     dressed them (the owner's "step 2 has all these nodes flood in but not cells").  Armed by
//      Cyto: e_Cyto_commission sets Scannable.c.crush_wanted when the commission carries
//       useVoroCyto, the ◈ button sets the same flag by hand; cyto_update_wave calls here.
//  Always QUIET — story_snap's per-world crush stays the census author (once per beat).
//   A scannable with no A children (a bare w, Lang's Cyto) folds as one world, same as ever.
Voro_crush_worlds(scan):
    let As = scan.o({ A: 1 })
    if (!As.length) {
        this.Voro_crush_scan(scan, 1)
        return
    }
    for (const a of As) {
        for (const rw of a.o({ w: 1 })) {
            if (rw.sc.w !== 'Voronoiology') this.Voro_crush_scan(rw, 1)
        }
    }

Voro_crush_pass(w, level):
    let stats = { folded: 0, count: 0, gangs: 0, ganged: 0, visible: 0, level: level }
    this.Voro_crush_walk(w, 0, stats, level)
    return stats

// Voro_report — the crush's WORKING, projected onto a SIBLING world (the owner's "a different
//  w, a projection on the wall next to it").  The flora world stays PURE flora — the c-side
//   discipline holds THERE, nothing the fold does reaches its snap — while the thinking lands
//    NEXT to it in w:Voronoiology (one fixed name across all Book:Voro*), rewritten each crush
//     beat.  So every Story step now DIFFS
//     and the model Cyto renders is finally legible in the snap: the governor level, the
//      visible count, every pane the crush INTENDS (%cell rows — gang or folded container, the
//       owner's "why are some Pittosporum non-cells" now readable for ANY world, not just flora),
//        the unfolded leaves (%bare rows), which panes the radio popped, and the drift focus.
//         Since 2026-07-09 the report world also GRAPHS (the owner un-hid it) — a live pane of
//          the crush's working beside the data; it remains the seed of Story's future separable
//           snap channels (capture certain A/w on their own layer, trace always
//           on).  NO gate: whenever the fold runs (imposed or inline) it self-reports here.  Story
//            decides RECORDING not building — it prunes w:Voronoiology from the snap for a Book with
//             %dontSnapVoronoiology (MusuReplica keeps its replication fixture clean); the ◈ button
//              folds the Cyto MIRROR, which never reaches Story, so it reports live only.
Voro_report(w, stats):
    let A = w.c.up
    if (!A || !w.sc.w) return null
    let rname = 'Voronoiology'
    let rw = A.o({ w: rname })[0]
    if (!rw) rw = A.i({ w: rname })
    // w:Voronoiology is our processing/debugging C** — it SNAPS (the census rides every Book's
    //  fixture, so the crush INTENT is auto-checkable) but must NEVER enter the Cyto graph layout;
    //   it is process-noise, not data.  %dontGraph is that marker, and cytyle_classify skips a
    //    dontGraph world (and its whole subtree) so this debug pane can't clutter the data graph.
    //     Enriching the world is what made the old leak visible — so keep the flag ON, don't drop it.
    rw.sc.dontGraph = 1
    // NO drop-and-rebuild — THAT is the census-storm root.  The census is PERSISTENT now: stale-mark
    //  every child (c-side), find-or-create each cell|bare|head by its DURABLE identity, merge the
    //   counts in place, then sweep only the children this beat never re-touched (the real goners).
    //    So a pane that survives keeps its SLOT — a count sliding ×9→×11 is one field-diff, not the
    //     whole cell torn down + re-added because the walk happened to reorder it.  The snap churns
    //      on emission ORDER, and find-or-create reuses each child in place, so the order holds.
    for (const c of rw.o()) c.c.seen_beat = 0
    w.c.report_beat = (w.c.report_beat || 0) + 1
    let census = { cells: [], bare: {} }
    this.Voro_report_walk(w, census, 0)
    let pops = 0
    for (const f of census.cells) pops = pops + f.pop
    // the head — one persistent %Voro particle, beat + counts merged in place.  level|counts ride
    //  stringified: a bare 1 would snap as the boolean sentinel and a 0 would vanish.
    let headC = rw.oai({ Voro: 1 }, { beat: w.c.report_beat, level: 'L' + stats.level, visible: stats.visible, cells: '' + census.cells.length, gangs: stats.gangs, folded: '' + stats.folded, count: '' + stats.count })
    headC.c.seen_beat = 1
    if (pops) headC.sc.pop = '' + pops
    if (!pops) delete headC.sc.pop
    if (w.c.drift_focus) {
        let f = w.c.drift_focus
        let fk = Object.keys(f.sc)[0]
        let driftC = rw.oai({ drift: 1 }, { focus: fk + ' ' + f.sc[fk], opens: (w.c.drift_opens || []).length })
        driftC.c.seen_beat = 1
    }
    // the panes — identity is the DURABLE {cell,kind}; n|pop MERGE, they never identify, so a count
    //  change rides the same particle instead of re-keying.  Two gangs of one family in a beat would
    //   share a key, so a collision takes a disambiguating tail — neither swallowed by the other's
    //    find-or-create.  kind = pane (a folded container) | gang (loose leaves behind a rep).
    let used = {}
    for (const f of census.cells) {
        let n_seen = used[f.label] || 0
        let key = n_seen ? f.label + ' ' + n_seen : f.label
        used[f.label] = n_seen + 1
        let cellC = rw.oai({ cell: key, kind: f.kind }, { n: '' + f.n })
        cellC.c.seen_beat = 1
        if (f.pop) cellC.sc.pop = '' + f.pop
        if (!f.pop) delete cellC.sc.pop
        // the pane's WORDS stay c-side (f.src.c.vtuffing — the grasp builds + scores that tree, the
        //  render draws it).  They are NOT transcribed into the snap: a Vtuffing is render LAYOUT
        //   (×N titles, /*N dip handles, wgt sizes — annotations of the paint, not facts of the data)
        //    and a fixture that bakes chrome reads as data what is only presentation.  The words
        //     surface honestly through the model's %Family/%Loud rows instead.  The sweep clears
        //      rows an older gen left snapped under a persistent cell.
        for (const old of cellC.o({ Vtuffing: 1 }).slice()) old.drop(old)
    }
    // one %bare row per mainkey of UNFOLDED visible leaves — legitimate data standing as plain
    //  nodes (a fat bare row at level 0 is usually pre-escalation; one that persists is a fold gap).
    for (const mk of Object.keys(census.bare)) {
        let b = census.bare[mk]
        let bareC = rw.oai({ bare: mk }, { n: '' + b.n })
        bareC.c.seen_beat = 1
        if (b.pop) bareC.sc.pop = '' + b.pop
        if (!b.pop) delete bareC.sc.pop
    }
    // stash the PRE-SWEEP census as an off-snap INTENT tree, straight off the flora walk (census) — an
    //  INDEPENDENT source for Voro_census_mirror's Seem.  The mirror must be a second OPINION on the
    //   sweep below, not a mirror of its output: point a Seem at the POST-sweep rw and its goners equal
    //    "what the sweep dropped" BY CONSTRUCTION (break the sweep → the mirror breaks in lockstep, never
    //     diverges, proves nothing).  Built from the census OBJECT (this beat's flora truth), not from rw
    //      or c.seen_beat, so the two diffs share only their SUBJECT — never their machinery.  A
    //       mis-reconciliation in the sweep and the mirror now DISAGREE.  Never carries the %Se readout
    //        rows: they are OUTPUTS, not census subjects, so they never enter here (the self-count the
    //         old prototype suffered is gone by construction — no negative query needed).
    this.Voro_census_stash(w, census, stats)
    // sweep the goners — a census child this beat never re-touched has left the crush.  The grasp's
    //  own %Se row is authored by Voro_grasp on its own beat (it runs AFTER this census sweep), so
    //   this sweep must spare it — otherwise the Se row is dropped here and re-added there every beat,
    //    the very census storm we killed, reborn on the grasp's row.  The model's %Family rows are
    //     the same shape (authored after, persistent slots, self-swept in Voro_model) — spared too.
    for (const c of rw.o().slice()) {
        let mk = Object.keys(c.sc)[0]
        if (!c.c.seen_beat && mk !== 'Se' && mk !== 'Family') c.drop(c)
    }

// Voro_census_stash — mirror THIS beat's census subjects into an off-snap free C** (w.c.census_home),
//  keyed by the SAME durable identity Voro_report gives each rw row (so a survivor keeps its slot and
//   the mirror's resolve() reads it as a survivor, a departure as a goner).  Persistent across beats
//    (the Seem's Selection resolves it beat-to-beat) yet drop-and-rebuilt each beat — this tree never
//     snaps and no render reads it, so churn is FREE here, unlike rw.  The %Se readout rows are OUTPUTS,
//      so they are never mirrored: the subjects are the folds (cells), the bare leaves, the head and the
//       drift focus — exactly the rows the c.seen_beat sweep governs, minus the %Se it spares.
Voro_census_stash(w, census, stats):
    if (!w.c.census_home) w.c.census_home = new TheC({ c: {}, sc: { census_home: 1 } })
    let home = w.c.census_home
    for (const c of home.o().slice()) c.drop(c)
    home.i({ Voro: 1, cells: '' + census.cells.length, visible: '' + stats.visible })
    if (w.c.drift_focus) {
        let f = w.c.drift_focus
        let fk = Object.keys(f.sc)[0]
        home.i({ drift: 1, focus: fk + ' ' + f.sc[fk] })
    }
    let used = {}
    for (const f of census.cells) {
        let n_seen = used[f.label] || 0
        let key = n_seen ? f.label + ' ' + n_seen : f.label
        used[f.label] = n_seen + 1
        home.i({ cell: key, kind: f.kind, n: '' + f.n })
    }
    for (const mk of Object.keys(census.bare)) {
        home.i({ bare: mk, n: '' + census.bare[mk].n })
    }

// Voro_report_walk — gather Voro_report's census on the same cut the Cyto walk makes.  A fold
//  stamp (c.stuff) is a pane — count it, do NOT descend (folded here = folded on the canvas); a
//   represented member is already inside its rep's pane; anything else with children is walked-
//    through structure; a leaf left standing is bare.  Popped members tally per-pane (a gang's
//     popped ride its c.gang list, a folded container's its children) and a popped LONER —
//      crush_walk lets it stand alone — tallies on its mainkey's bare row.
Voro_report_walk(node, census, d):
    if (d > 8) return
    for (const c of node.o()) {
        if (c.c.represented) continue
        let mk = Object.keys(c.sc)[0]
        // same cut as the crush walk: Opt is config, self is machinery — neither is a pane
        //  nor a bare leaf the canvas could show, so neither belongs in the census.
        if (mk === 'Opt' || mk === 'self') continue
        if (c.c.stuff) {
            let label = mk
            if (c.c.gang) {
                label = c.c.fold_kind || mk
            } else if (c.sc[mk] && c.sc[mk] !== 1) {
                // the mainkey CARRIES the datum ({Metrosideros:'robusta'}) — that value IS the name.
                label = mk + ' ' + ('' + c.sc[mk]).split(',').join(' ')
            } else {
                // the mainkey is a bare presence marker ({Artist:1,name:'Moonlit'}); the identity
                //  lives in a sibling field.  Name the cell by its DATA (Artist Moonlit), not by a
                //   fragile walk-order tail (Artist 1) that re-shuffles the instant a pane ahead of
                //    it is born or dies — the very volatile-identity churn the persistent census kills.
                let ks = Object.keys(c.sc)
                for (let i = 1; i < ks.length; i++) {
                    let v = c.sc[ks[i]]
                    if (v && v !== 1) {
                        label = mk + ' ' + ('' + v).split(',').join(' ')
                        break
                    }
                }
            }
            let pop = 0
            let members = c.c.gang || c.o()
            for (const m of members) if (m.c.popped) pop = pop + 1
            census.cells.push({ label: label, kind: c.c.gang ? 'gang' : 'pane', n: c.c.fold_n || c.o().length, pop: pop, src: c })
            continue
        }
        if (c.o().length > 0) {
            this.Voro_report_walk(c, census, d + 1)
            continue
        }
        if (!census.bare[mk]) census.bare[mk] = { n: 0, pop: 0 }
        census.bare[mk].n = census.bare[mk].n + 1
        if (c.c.popped) census.bare[mk].pop = census.bare[mk].pop + 1
    }

// ── Voro_grasp — the Se GRASP, stood on the mature primitive (LiesEnd's %Seem) ─────────────────────
//  Where Voro_report walks the crush BY HAND, the grasp stands the same reading on Selection.process
//   — the very machine Cyto's own id-resolve rides (cyto_assign_ids: a Selection whose trace mints
//    D%the_* nodes, whose Dip gives cross-beat-stable ids).  So the grasp is not a new idea, it is the
//     crush read through the primitive that already knows how to have IDENTITY across beats.
//  It is a %Seem whose D-sphere mirrors the flora one layer deep; use_Understandable wires each D node
//   back to its source C, so the projection below can read the crush's c-side fold facts off the
//    sphere.  resolve() then gives every fold cross-beat identity FOR FREE: a genus that survives keeps
//     its D node, one that divides IN is a neu, one that dies (apoptosis) a goner — the mitosis
//      counted at the primitive, not reconstructed from a diff.
//  The %Seem machinery is snap-hostile — functions ride its sc.opt, a live Selection rides sc.Se — so
//   it lives OFF-SNAP on a free C** parked at w.c.grasp_home (persisting across beats, so its Selection
//    resolves the folds beat-to-beat).  Only the distilled READING is projected into w:Voronoiology as
//     a clean %Se:scape row.  STAMPS NO verdict — pure read.  Slice 0: prove the sphere reproduces the
//      folds and counts the mitosis; the_*/the_very_* weighting and the render gift come next.
Voro_grasp(w):
    let A = w.c.up
    if (!A || !w.sc.w) return
    let rw = A.o({ w: 'Voronoiology' })[0]
    if (!rw) return
    if (!w.c.grasp_home) w.c.grasp_home = new TheC({ c: {}, sc: { grasp_home: 1 } })
    let home = w.c.grasp_home
    let seem = home.o({ Seem: 'scape' })[0]
    if (!seem) seem = this.i_Seem(home, { Seem: 'scape', C: w, use_Understandable: 1 })
    seem.sc.C = w
    let news = await this.o_Seem(seem)
    // collect the fold D nodes and the loudest count FIRST, so each cell's weight is NEIGHBOUR-relative
    //  (the Se reads its surroundings — a count of 9 is loud in a field of 3s, ordinary in a field of 20s).
    //   A D node whose source C is a stamped fold (not a represented member already in another's pane) is
    //    one cell the grasp knows.
    let folds = []
    let max_n = 1
    let topD = news.topD
    if (topD) {
        for (const d of topD.o()) {
            let src = d.c.C
            if (src && src.c.stuff && !src.c.represented) {
                let fn = src.c.fold_n || src.o().length
                folds.push({ d: d, src: src, n: fn })
                if (fn > max_n) max_n = fn
            }
        }
    }
    let grasped = folds.length
    // ── NEIGHBOURHOOD CENSUS — the Se proper.  Count every (key,val) claim across ALL the cells, so a
    //  claim's loudness can be read as how much it SETS ITS CELL APART: a fact every cell shares
    //   ('format: digital') is quiet, one only this cell makes ('genre: shoegaze' among folk) is loud.
    //    This is the surroundings-read the isolation judges (Voro_crushable) can't do — a cell weighed
    //     against its neighbours, not alone.  Drawn from the SAME Vtuffing tree the render draws
    //      (Vtuff_build's cached %Vtuffing), so a weight lands on the very row the glass shows — the two
    //       halves aligned by construction, no cross-beat key-matching to drift.
    let kv = {}
    let keyc = {}
    for (const f of folds) {
        let t = this.Vtuff_build(f.src)
        if (!t) continue
        let saw = {}
        for (const r of t.o()) {
            let rk = r.sc.row
            if (rk === 'fact') {
                let p = this.Voro_grasp_kv('' + r.sc.text)
                this.Voro_grasp_tally(kv, keyc, saw, p.key, p.val)
            } else if (rk === 'spread') {
                let sk = '' + r.sc.text
                for (const b of r.o()) {
                    this.Voro_grasp_tally(kv, keyc, saw, sk, '' + b.sc.text)
                }
            }
        }
    }
    // VOICE each fold — its identity is always the_very (the name the render stretches biggest); its
    //  count rides 0..100 against the loudest sibling; and each of its OWN rows is weighed by the census
    //   above and the weight stamped straight onto the Vtuffing tree (off-snap, so the drop+rebuild costs
    //    the snap NOTHING — only the render reads it, via the wgt field that already rode every Vrow).
    //     Track the cell's loudest distinguishing trait for the readout.  The D%the children stay too,
    //      so the sphere is self-describing: a cell's D says its name, its n, and its defining trait.
    // the REGION axis (Slice C seed): the key the most cells share is the axis they can be grouped
    //  along — cluster cells by their VALUE on it and same-value cells form a continuous region (the
    //   human's "a river of some type of debris through another").  Provisional (dominant-shared-key);
    //    the real bucketing wants eyes-on — tune when a Voro runner is up.
    let fam_key = ''
    let fam_best = 0
    for (const k in keyc) {
        if (keyc[k] > fam_best) {
            fam_best = keyc[k]
            fam_key = k
        }
    }
    let fams = {}
    let loudest = ''
    let loud_n = 0
    let loud_trait = ''
    for (const f of folds) {
        for (const old of f.d.o({ the: 1 }).slice()) old.drop(old)
        let name = f.src.c.fold_kind
        if (!f.src.c.gang) name = this.Vtuff_ident(f.src)
        if (!name) name = Object.keys(f.src.sc)[0]
        name = ('' + name).split(',').join(' ')
        f.d.i({ the: 'name', val: name, weight: 100, very: 1 })
        f.d.i({ the: 'n', val: '' + f.n, weight: '' + Math.round(100 * f.n / max_n) })
        let t = f.src.c.vtuffing
        let top_fact = ''
        let top_w = 0
        if (t) {
            for (const r of t.o()) {
                let rk = r.sc.row
                if (rk === 'title') {
                    r.sc.wgt = 100
                } else if (rk === 'dip') {
                    r.sc.wgt = 10
                } else if (rk === 'fact') {
                    let p = this.Voro_grasp_kv('' + r.sc.text)
                    let w = this.Voro_grasp_weight(kv, keyc, grasped, p.key, p.val)
                    r.sc.wgt = w
                    if (w > top_w) {
                        top_w = w
                        top_fact = '' + r.sc.text
                    }
                } else if (rk === 'spread') {
                    let sk = '' + r.sc.text
                    let mx = 0
                    let mxv = ''
                    for (const b of r.o()) {
                        let cw = this.Voro_grasp_weight(kv, keyc, grasped, sk, '' + b.sc.text)
                        b.sc.wgt = cw
                        if (cw > mx) {
                            mx = cw
                            mxv = '' + b.sc.text
                        }
                    }
                    r.sc.wgt = mx
                    if (mx > top_w) {
                        top_w = mx
                        top_fact = sk + ' ' + mxv
                    }
                } else {
                    r.sc.wgt = 50
                }
            }
        }
        f.d.i({ the: 'trait', val: top_fact, weight: '' + top_w })
        // the REGION this cell belongs to (its value on the shared axis) + a durable ANCHOR (its
        //  identity) — the two fields Slice C (regroup) and Slice D (arc bead order) read off the sphere.
        let family = 'misc'
        if (t && fam_key) {
            for (const r of t.o()) {
                let rk = r.sc.row
                if (rk === 'fact') {
                    let p = this.Voro_grasp_kv('' + r.sc.text)
                    if (p.key === fam_key) {
                        family = p.val || fam_key
                        break
                    }
                } else if (rk === 'spread' && ('' + r.sc.text) === fam_key) {
                    let b0 = r.o()[0]
                    if (b0) {
                        family = '' + b0.sc.text
                    }
                    break
                }
            }
        }
        fams[family] = 1
        f.d.i({ the: 'family', val: family, weight: '' + fam_best })
        f.d.i({ the: 'anchor', val: name })
        if (f.n > loud_n) {
            loud_n = f.n
            loudest = name
            loud_trait = top_fact
        }
    }
    // born = the folds that ARRIVED this beat — resolve() flagged their D node a neu AND its source
    //  is a fold (a genus dividing IN).  The raw news.neus/goners count every LEAF that came or went
    //   (a fast-growing flora arrives ~19 species a beat), which drowns the cell story — so we keep
    //    only the fold-level arrivals.  died is derived from the fold-count delta (grasped = prev +
    //     born - died): a goner D's source is already stale, so it can't be re-read, but the arithmetic
    //      is exact.  So born|died read as CELL mitosis — divisions in, apoptosis out — a beat or two
    //       at a time, not the leaf churn underneath.
    let born = 0
    for (const d of news.neus) {
        let src = d.c.C
        if (src && src.c.stuff && !src.c.represented) born = born + 1
    }
    let prev = w.c.grasp_prev_folds
    let died = 0
    if (prev != null) {
        died = prev + born - grasped
        if (died < 0) died = 0
    }
    w.c.grasp_prev_folds = grasped
    // PROJECT — the grasp's readout beside the census: cells held, the cell mitosis, and the LOUDEST
    //  cell (its the_very name) — a first legible taste of the reductionist weighting the render reads.
    //   oai keeps its slot so only the fields slide — no storm on the grasp's own row.
    rw.oai({ Se: 'scape' }, { grasped: '' + grasped, born: '' + born, died: '' + died, loudest: loudest, trait: loud_trait, regions: '' + Object.keys(fams).length })

// Voro_grasp_kv — split a Vtuffing fact's text into { key, val }: 'year: 2007' → { year, 2007 };
//  a presence fact ('remaster ×2') or a bare key → { key, '' } (its value IS its mere presence).
Voro_grasp_kv(text):
    let i = text.indexOf(': ')
    if (i > 0) {
        let o = { key: text.slice(0, i), val: text.slice(i + 2) }
        return o
    }
    let x = text.lastIndexOf(' ×')
    if (x > 0) {
        let o = { key: text.slice(0, x), val: '' }
        return o
    }
    let o = { key: text, val: '' }
    return o

// Voro_grasp_tally — record one (key,val) claim for ONE cell into the neighbourhood census, deduped
//  per cell (a cell that says a value twice counts once — saw is this cell's).  kv counts the cells
//   per (key,val); keyc counts the cells per key — a key few cells even carry is itself distinguishing.
Voro_grasp_tally(kv, keyc, saw, key, val):
    if (!key) return
    let vk = key + '~#~' + val
    if (!saw[vk]) {
        saw[vk] = 1
        kv[vk] = (kv[vk] || 0) + 1
    }
    let kk = 'K' + key
    if (!saw[kk]) {
        saw[kk] = 1
        keyc[key] = (keyc[key] || 0) + 1
    }

// Voro_grasp_weight — a claim's loudness 0..100 from the census: universal (every cell shares it) →
//  ~20 (recedes below the render's 14pt floor — it needn't shout), unique to this cell → ~95 (towers).
//   A rare KEY nudges up (a property few cells even carry is distinguishing).  96..100 stays reserved
//    for identity/title, so a fact never out-shouts the name of the thing it describes.
Voro_grasp_weight(kv, keyc, total, key, val):
    if (!key) return 50
    if (!total) return 50
    let vk = key + '~#~' + val
    let share = (kv[vk] || 1) / total
    let w = Math.round(100 * (1 - 0.85 * share))
    let kshare = (keyc[key] || 1) / total
    w = w + Math.round(15 * (1 - kshare))
    if (w > 95) w = 95
    if (w < 20) w = 20
    return w

// ── Voro_census_mirror — SEEM-ABLE §1, Slice 0 (isolation-first, read-only) ──────────────────────────
//  Voro_report STILL hand-rolls its survivors/goners the old way: stamp c.seen_beat=0 on every census row,
//   re-stamp =1 on each one the walk re-touches, then sweep the un-touched as goners.  That is precisely
//    the last-beat-vs-this-beat diff the mature %Seem gives for FREE, with identity — the Seemables harvest
//     (spec/Seemables_todo.md §1), one function over from where Voro_grasp already proved the pattern.
//  This stands a SECOND Seem — %Seem:census — as an INDEPENDENT second opinion on that sweep.  Where the
//   grasp's Seem walks w's FLORA fold layer (leaf-grained), THIS one walks the CENSUS ROW layer, the same
//    granularity the c.seen_beat sweep diffs — so its goners can be checked row-for-row against the rows
//     the sweep drops.
//  The honesty hinge is the SOURCE.  A first prototype pointed this Seem at the POST-sweep rw, so its
//   goners equalled the sweep's OWN output by construction (break the sweep and the mirror broke in
//    lockstep — it could never DISAGREE, so it proved nothing), and it self-counted its own %Se readout
//     rows.  Here the Seem resolves over w.c.census_home — the PRE-SWEEP intent tree Voro_report stashes
//      straight off the flora walk (Voro_census_stash), before the sweep drops anything and carrying no
//       %Se rows at all.  The two diffs now share only their SUBJECT (the census rows), never their
//        machinery: the sweep reads c.seen_beat on rw, the mirror reads its OWN cross-beat D-sphere on
//         census_home.  So a mis-reconciliation — a survivor wrongly swept, a stale row wrongly kept —
//          makes the mirror's goners and the seen_beat drops DIVERGE, which is what a proof %see can gate.
//  Off-snap like the grasp: the Selection rides sc.Se, the fns ride sc.opt (both snap-hostile), parked on
//   the free census_home; only the distilled {goners,neus,rows} reading projects into w:Voronoiology as a
//    read-only %Se:census row.  rows counts HONEST census subjects (census_home holds no %Se), so it is
//     the sweep's true survivor+neu count, never inflated by the readout rows themselves.
Voro_census_mirror(w):
    let A = w.c.up
    if (!A || !w.sc.w) return
    let rw = A.o({ w: 'Voronoiology' })[0]
    if (!rw) return
    let home = w.c.census_home
    if (!home) return
    let cseem = home.o({ Seem: 'census' })[0]
    if (!cseem) cseem = this.i_Seem(home, { Seem: 'census', C: home })
    cseem.sc.C = home
    let cnews = await this.o_Seem(cseem)
    // resolve()'s add/drop of the PRE-SWEEP census rows — an independent verdict beside Voro_report's
    //  c.seen_beat sweep.  rows counts census_home's honest subjects (no %Se readout rows live here).
    let gone = cnews.goners.length
    let neu = cnews.neus.length
    rw.oai({ Se: 'census' }, { goners: '' + gone, neus: '' + neu, rows: '' + home.o().length })

//#region model — THE MODEL: the semantics a consumer reads instead of re-deriving from pixels
// ══ Voro_model — the first side: compute the model, hand it to Cyto ═══════════════════════════════
//  The crush FOLDS, the grasp WEIGHS — but every SEMANTIC a render wants (which cells are one family,
//   what order to walk them in, which of a cell's facts is loudest, what changed this beat) is still
//    re-derived downstream from RENDERED POSITIONS (Cytui's river_order runs a PCA over where fcose
//     happened to drop the seeds).  That is backwards: the order a family reads in is a fact of the
//      DATA, not of the layout.  Voro_model closes it — it reads the crushed+grasped world and emits
//       the readings ONCE, so a consumer never re-derives.  It is the twin of Voro_report: where the
//        report snaps the crush's SHAPE (what folded), the model snaps its MEANING (how it groups,
//         orders, and what shifted).
//  Two homes, the census pattern exactly:
//   (a) w.c.voro_model — the FULL off-snap model C** (drop-and-rebuilt each compute, reachable from
//        nothing, so no snap and no encode ever sees it).  A consumer walks it for the whole answer:
//         %Model head · %Family{name,n,order_by,ends} / %Member{anchor,ord,val,weight} · %Loud rows.
//   (b) w:Voronoiology — a SMALL stable %Family row PER FAMILY (the fixture-diffable distillation):
//        the family name, its size + kind, the axis it orders along, the two END anchors, its %Loud
//         claims as key:val children — and an %Se:drift child ONLY on a beat the model Seem's resolve
//          reported movement.  The MAINKEY is provenance: %Family|%Loud are COMPUTED census (plain
//           code), %Se is worn iff a Selection.process() produced the reading — never a costume.
//            A full member-order string would be snap noise (it re-shuffles as the flora grows);
//             the ends + n pin it without the churn.
//  UNIVERSAL — zero mainkey knowledge.  A "family" is whatever value the grasp stamped on the:family
//   (the widest-shared key's value, itself found generically); the ordering axis is the numeric-else-
//    lexical key with the widest spread across a family's cells, discovered by scanning, never named.
//     The comments say Artist/year for the reader's sake; the code names nothing.
//  Runs in the crush tail AFTER Voro_grasp (it reads the grasp's the:family stamps and the wgt the
//   grasp wrote onto each Vtuffing row), on census-authoring passes only — never the quiet pre-scan.
Voro_model(w):
    let A = w.c.up
    if (!A || !w.sc.w) return
    let rw = A.o({ w: 'Voronoiology' })[0]
    if (!rw) return
    if (!w.c.voro_model) w.c.voro_model = new TheC({ c: {}, sc: { voro_model: 1 } })
    let model = w.c.voro_model
    // rebuild the subject tree fresh each beat, but SPARE the %Seem:model node — its D-sphere IS the
    //  cross-beat baseline the drift diff resumes against.  Drop it and every member reads as a neu
    //   every beat (drift frozen — the bug the first live run surfaced).  Selection.process pairs by
    //    sc CONTENT, so the %Family/%Member C nodes are free to be rebuilt; only the Seem must outlive them.
    for (const c of model.o().slice()) if (Object.keys(c.sc)[0] !== 'Seem') c.drop(c)
    // gather the FOLD RECORDS — the family is the FOLD UNIT, not the grasp's coarse region.  A loose-leaf
    //  GANG is one family named by its kind, its members the ganged particles (so the ten strata are ten
    //   MEMBERS an axis can order by depth — not one opaque cell); a container PANE is one member of a
    //    mainkey family (three Groves → one Grove family of three); a BARE leaf is a family of one.
    let folds = []
    this.Voro_model_gather(w, 0, folds)
    // group fold records into families by name (first-seen order, so neither tree nor fixture churns on
    //  walk order).  Each family builds its MEMBERS (a gang member's facts off its sc, a pane's off its
    //   weight-stamped Vtuffing) and its LOUD source (a gang's rep Vtuffing — the grasp scored it — a
    //    pane|bare's own facts) so epithets rank by distinctiveness, not per-member noise.
    let fams = {}
    let fam_order = []
    for (const fr of folds) {
        let fk = fr.family
        if (!fams[fk]) { fams[fk] = { name: fk, kind: fr.kind, rep: fr.cell, members: [], loud_facts: [] }; fam_order.push(fk) }
        let fam = fams[fk]
        if (fr.kind === 'gang') {
            for (const p of (fr.particles || [])) {
                let facts = this.Voro_model_member_facts(p)
                fam.members.push({ anchor: this.Voro_model_member_anchor(p), facts: facts, weight: this.Voro_facts_top_weight(facts) })
            }
            for (const f of this.Voro_model_facts({ src: fr.cell })) fam.loud_facts.push(f)
        } else {
            for (const c of fr.particles) {
                let facts = fr.kind === 'pane' ? this.Voro_model_facts({ src: c }) : this.Voro_model_member_facts(c)
                let anchor = fr.kind === 'pane' ? this.Vtuff_ident(c) : this.Voro_model_member_anchor(c)
                if (!anchor) anchor = Object.keys(c.sc)[0]
                anchor = ('' + anchor).split(',').join(' ')
                fam.members.push({ anchor: anchor, facts: facts, weight: this.Voro_facts_top_weight(facts) })
                for (const f of facts) fam.loud_facts.push(f)
            }
        }
    }
    let members_total = 0
    for (const fk of fam_order) members_total = members_total + fams[fk].members.length
    let head = model.i({ Model: 1, beat: '' + (w.c.report_beat || 0), families: '' + fam_order.length, cells: '' + members_total })
    // one %Family in the model per group; the snapped %Family below MIRRORS it (reads the built node,
    //  never re-computes — the model tree is the single source).  fam_node maps name → %Family.
    let fam_node = {}
    for (const fk of fam_order) {
        let fam = fams[fk]
        let mem = fam.members
        // the ORDER axis: the fact-key whose values spread WIDEST across this family's members.  Voro_model_axis
        //  scores every key some member carries — numeric keys by their value RANGE (normalised), non-numeric by
        //   how many distinct values they take — and picks the widest.  This is the data-native replacement for
        //    Cytui's positional PCA: the trail order is a property of the DATA, computed once, here.
        let axis = this.Voro_model_axis(mem)
        // order the members along the axis (numeric ascending, else lexical); a family with no usable axis
        //  keeps gather order (stable, better than random).  ord rides each member 0..n-1 for the consumer.
        let ordered = this.Voro_model_sort(mem, axis)
        let famC = model.i({ Family: fk, n: '' + ordered.length })
        fam_node[fk] = famC
        if (fam.kind) famC.sc.kind = fam.kind
        if (axis.key) famC.sc.order_by = axis.key
        if (axis.kind) famC.sc.axis = axis.kind
        // the grasp's coarse region rides as a SECONDARY property (the render's wash layer buckets by it) —
        //  never the family name.  Skip when it just echoes the fold name.
        let reg = this.Voro_model_family(fam.rep)
        if (reg && reg !== fk) famC.sc.region = reg
        // the two ENDS ride the %Family node too (the snap distillation reads them here) — first|last anchor.
        if (ordered.length) famC.sc.from = ('' + ordered[0].anchor).split(',').join(' ')
        if (ordered.length > 1) famC.sc.to = ('' + ordered[ordered.length - 1].anchor).split(',').join(' ')
        let oi = 0
        for (const m of ordered) {
            // fam rides the member row so DRIFT can attribute it: a departed member's D-clone keeps its
            //  own sc but LOSES its parent link in the D-sphere (the resolve hands back a detached node),
            //   so the family must live ON the member, not be reached by walking up to the %Family clone.
            let mrow = { Member: m.anchor, ord: '' + oi, weight: '' + m.weight, fam: fk }
            let av = this.Voro_model_axis_val(m, axis.key)
            if (av !== '') mrow.val = ('' + av).split(',').join(' ')
            famC.i(mrow)
            oi = oi + 1
        }
        // LOUDNESS — the family's top-K loud claims, pooled from its weighted source and kept loudest-
        //  first.  Each rides as an honest (key, v) pair — a presence claim carries no v at all.  The
        //   ORDER-AXIS key is excluded: its story is already told once, by order_by|from|to (a Loud row
        //    repeating an axis value would say the same fact twice — the one-fact-one-place rule).
        //     These are the words B2 sizes up; a consumer reads them straight instead of re-scoring.
        let loud = this.Voro_model_loud_from(fam.loud_facts, 4, axis.key)
        for (const l of loud) {
            let lrow = { Loud: ('' + l.key).split(',').join(' '), weight: '' + l.weight }
            if (l.val !== '') lrow.v = ('' + l.val).split(',').join(' ')
            famC.i(lrow)
        }
    }
    // DRIFT — stand a %Seem over the model's MEMBER layer so goners|neus come with cross-beat identity for
    //  FREE (the same primitive the grasp and census_mirror ride).  A member that left is a goner, one that
    //   arrived a neu; each carries its family, so drift attributes PER FAMILY.  The Seem is snap-hostile
    //    (a live Selection on sc.Se), so it parks on the free voro_model itself, off-snap.  The distilled
    //     per-family {gone,neu} then rides an %Se:drift child of the %Family row — this is what lets
    //      VoroTest "deduce what changed": a mutation beat surfaces exactly which family gained|lost.
    let drift = await this.Voro_model_drift(w, model)
    // PROJECT the small stable readings — one %Family row per family, MAINKEY = PROVENANCE.  %Family and
    //  its %Loud children are COMPUTED census (grouping, order, loudness — plain code), so they wear plain
    //   names; %Se is worn ONLY by the Selection-derived part (the drift child below).  Identity is the
    //    durable {Family:<name>} — family names are unique per beat (they ARE the grouping keys), so a
    //     survivor keeps its slot and only its fields slide (the persistent-census discipline, no storm).
    for (const fk of fam_order) {
        let famC = fam_node[fk]
        // a family of one (a bare leaf, a lone pane) has no order|drift worth a snapped row and would
        //  flood the fixture (the motley alone is eight singletons) — it stays in the off-snap model tree
        //   for a consumer, but only families of TWO or more project a snapped row.
        if (((+famC.sc.n) || 0) < 2) continue
        let d = drift[fk] || { gone: 0, neu: 0 }
        let row = rw.o({ Family: fk })[0]
        if (!row) row = rw.i({ Family: fk })
        // overwrite the sliding fields in place (clear the old ones first so a shrunk family sheds a
        //  stale `to`); the mainkey stays put.  n, kind, the axis, the two ENDS — a full member-order
        //   string would re-shuffle as the flora grows (snap noise), so n + the ends pin the trail.
        for (const k of Object.keys(row.sc)) if (k !== 'Family') delete row.sc[k]
        row.sc.n = famC.sc.n
        if (famC.sc.kind) row.sc.kind = famC.sc.kind
        if (famC.sc.order_by) row.sc.order_by = famC.sc.order_by
        if (famC.sc.axis) row.sc.axis = famC.sc.axis
        if (famC.sc.from) row.sc.from = famC.sc.from
        if (famC.sc.to) row.sc.to = famC.sc.to
        // the LOUD claims ride as typed (key, v) children, loudest-first — RANK is the child order, the
        //  numeric weight stays off-snap (it re-scores continuously; snapping it would churn fixtures on
        //   meaningless slides).  Drop-and-relay is safe at this scale: at most K tiny rows, re-emitted
        //    in a deterministic order, so unchanged claims serialise identically beat over beat.
        for (const old of row.o({ Loud: 1 }).slice()) old.drop(old)
        for (const l of famC.o({ Loud: 1 })) {
            let lr = { Loud: l.sc.Loud }
            if (l.sc.v) lr.v = l.sc.v
            row.i(lr)
        }
        // the DRIFT — the one Selection-derived reading — rides an %Se:drift child, present ONLY on a
        //  beat the model Seem's resolve reported movement.  Absence IS the quiet reading: a row with no
        //   %Se child moved nothing this beat, and no field ever says so twice.
        let sed = row.o({ Se: 'drift' })[0]
        if (d.neu || d.gone) {
            if (!sed) sed = row.i({ Se: 'drift' })
            if (d.neu) { sed.sc.neu = '' + d.neu } else { delete sed.sc.neu }
            if (d.gone) { sed.sc.gone = '' + d.gone } else { delete sed.sc.gone }
        } else if (sed) {
            sed.drop(sed)
        }
        row.c.seen_beat = 1
    }
    // sweep the %Family rows whose family left this beat — a row this beat never re-touched.  Matched on
    //  the Family mainkey only, so it never touches Se:scape|Se:census nor any census cell|bare row.
    //   Then re-arm seen_beat=0 for next beat's diff.
    for (const c of rw.o({ Family: 1 }).slice()) if (!c.c.seen_beat) c.drop(c)
    for (const c of rw.o({ Family: 1 })) c.c.seen_beat = 0

// Voro_model_gather — collect FOLD RECORDS on the same cut Voro_report_walk makes: a c.stuff fold is a
//  fold (don't descend), a represented member is inside its rep, %Opt|%self are machinery, anything else
//   with children is walked through, a childless leaf left standing is bare.  Each record says its KIND
//    (gang | pane | bare), its family NAME (a gang's fold_kind, else the mainkey), the source cell, and
//     the PARTICLES that become members (a gang's ganged list; the cell itself for a pane|bare).
Voro_model_gather(node, d, out):
    if (d > 8) return
    for (const c of node.o()) {
        if (c.c.represented) continue
        let mk = Object.keys(c.sc)[0]
        if (mk === 'Opt' || mk === 'self') continue
        if (c.c.stuff) {
            if (c.c.gang) {
                // a loose-leaf GANG: the fold IS a family, its members the ganged particles.  Named by its
                //  kind (fold_kind, the shared mainkey) — NEVER a bare trait value (the old grain's `1` bug).
                let fam = c.c.fold_kind || mk
                out.push({ kind: 'gang', cell: c, family: ('' + fam), particles: (c.c.gang || []) })
            } else {
                // a CONTAINER pane (a folded container-with-children): ONE member of a mainkey family —
                //  sibling panes of one kind (three Groves) merge into one family below.
                out.push({ kind: 'pane', cell: c, family: mk, particles: [c] })
            }
            continue
        }
        if (c.o().length > 0) {
            this.Voro_model_gather(c, d + 1, out)
        } else {
            // a BARE leaf the crush left standing: a family of one, named by its mainkey.  Kept so a
            //  consumer sees every cell attributed; the n<2 rule keeps these singletons out of the snap.
            out.push({ kind: 'bare', cell: c, family: mk, particles: [c] })
        }
    }

// Voro_model_family — the family a cell belongs to: the grasp's the:family awareness value, reached off
//  the cell's off-snap D node (c.D), null-safe to fold_kind else 'misc'.  This is the SAME source
//   Cytui's region_of reads — so the model's grouping IS what the render buckets by, no divergence.
Voro_model_family(c):
    let D = c.c.D
    if (D) {
        let f = D.o({ the: 'family' })[0]
        if (f && typeof f.sc.val === 'string' && f.sc.val) return f.sc.val
    }
    if (c.c.fold_kind) return c.c.fold_kind
    return 'misc'

// Voro_model_facts — a cell's own (key,val,weight) claims, read from its weight-stamped Vtuffing tree
//  (the grasp wrote wgt onto every row).  A single-value fact contributes its (key,val); a spread
//   contributes each chip's value under the spread's key (so a per-family axis can see the members'
//    values apart).  Presence facts ('remaster ×2') carry an empty val — still a claim, still loud.
//     Reads the SAME tree the render draws, so a weight lands on the very fact the glass shows.
Voro_model_facts(cell):
    let out = []
    let t = cell.src.c.vtuffing
    if (!t) return out
    for (const r of t.o()) {
        let rk = r.sc.row
        if (rk === 'fact') {
            let p = this.Voro_grasp_kv('' + r.sc.text)
            out.push({ key: p.key, val: p.val, weight: (+r.sc.wgt) || 0 })
        } else if (rk === 'spread') {
            let sk = '' + r.sc.text
            for (const b of r.o()) {
                // a spread's visible tail ('+9') is render CHROME, structurally marked n:0 (a real
                //  value chip always counts ≥1) — it must never cross into the model as a datum.
                if (!(+b.sc.n)) continue
                out.push({ key: sk, val: '' + b.sc.text, weight: (+b.sc.wgt) || (+r.sc.wgt) || 0 })
            }
        }
    }
    return out

// Voro_model_axis — find the family's ORDER AXIS: the fact-key whose values spread WIDEST across the
//  family's cells.  For each key some cell carries, take ONE representative value per cell (its highest-
//   weight value on that key — the value that best characterises the cell), then score the SPREAD:
//    · numeric (every representative parses as a number) → the value RANGE, normalised by the mean so a
//       'year' 2001..2019 and a 'bpm' 90..180 compete fairly; the wider relative range wins.
//    · non-numeric → the count of DISTINCT values (a key everyone agrees on can't order anything; a key
//       with many distinct values orders finely).  A tie breaks toward the key MORE cells carry.
//   Returns { key, kind:'num'|'lex', spread }; { key:'' } when no key spreads at all (a uniform family).
Voro_model_axis(mem):
    if (mem.length < 2) return { key: '', kind: '', spread: 0 }
    let per = {}
    for (const cell of mem) {
        let best = {}
        let bw = {}
        for (const f of (cell.facts || [])) {
            if (!f.key) continue
            if (bw[f.key] == null || f.weight > bw[f.key]) {
                bw[f.key] = f.weight
                best[f.key] = f.val
            }
        }
        for (const k of Object.keys(best)) {
            if (!per[k]) per[k] = []
            per[k].push(best[k])
        }
    }
    let win_key = ''
    let win_kind = ''
    let win_spread = 0
    let win_have = 0
    for (const k of Object.keys(per)) {
        let vals = per[k]
        if (vals.length < 2) continue
        let nums = []
        let all_num = true
        for (const v of vals) {
            let x = this.Voro_model_num(v)
            if (x == null) { all_num = false } else { nums.push(x) }
        }
        let spread = 0
        let kind = 'lex'
        if (all_num && nums.length >= 2) {
            let lo = nums[0]
            let hi = nums[0]
            let sum = 0
            for (const x of nums) { if (x < lo) lo = x; if (x > hi) hi = x; sum = sum + x }
            let mean = sum / nums.length
            let denom = mean === 0 ? 1 : Math.abs(mean)
            spread = (hi - lo) / denom
            kind = 'num'
        } else {
            let distinct = {}
            for (const v of vals) distinct['' + v] = 1
            spread = (Object.keys(distinct).length - 1) / vals.length
            kind = 'lex'
        }
        // widest spread wins; ties toward the key more cells carry (a fuller axis is more legible)
        if (spread > win_spread || (spread === win_spread && vals.length > win_have)) {
            win_spread = spread
            win_key = k
            win_kind = kind
            win_have = vals.length
        }
    }
    return { key: win_key, kind: win_kind, spread: win_spread }

// Voro_model_num — parse a value as a number, or null.  Tolerates a leading|trailing scrap ('2007',
//  ' 180 ') but refuses a word ('digital') so a lexical key never masquerades as numeric.  Uses a hand
//   scan (no regex literals in .g) — a run of digits with at most one dot.
Voro_model_num(v):
    let s = ('' + v).trim()
    if (!s.length) return null
    let seen_dot = false
    let seen_dig = false
    for (let i = 0; i < s.length; i++) {
        let ch = s[i]
        if (ch >= '0' && ch <= '9') { seen_dig = true; continue }
        if (ch === '.' && !seen_dot) { seen_dot = true; continue }
        if (ch === '-' && i === 0) continue
        return null
    }
    if (!seen_dig) return null
    return +s

// Voro_model_axis_val — the value a cell takes ON the axis key (its highest-weight value on that key),
//  '' when the cell doesn't carry the axis at all.  This is the datum a member sits at along the trail —
//   the consumer reads it to POSITION the member, no re-derivation.
Voro_model_axis_val(cell, key):
    if (!key) return ''
    let best = ''
    let bw = -1
    for (const f of (cell.facts || [])) {
        if (f.key === key && f.weight > bw) { bw = f.weight; best = f.val }
    }
    return best

// Voro_model_sort — order a family's cells along the axis: numeric ascending, else lexical; a cell
//  missing the axis value sinks to the end (a stable tail).  No axis → gather order (stable).  Pure —
//   returns a new ordered array, never mutates the input.
Voro_model_sort(mem, axis):
    let arr = mem.slice()
    if (!axis.key) return arr
    let key = axis.key
    let num = axis.kind === 'num'
    let self = this
    arr.sort((a, b) => {
        let va = self.Voro_model_axis_val(a, key)
        let vb = self.Voro_model_axis_val(b, key)
        let ha = va !== ''
        let hb = vb !== ''
        if (ha && !hb) return -1
        if (!ha && hb) return 1
        if (!ha && !hb) return 0
        if (num) {
            let na = self.Voro_model_num(va)
            let nb = self.Voro_model_num(vb)
            if (na == null) na = 0
            if (nb == null) nb = 0
            return na - nb
        }
        if (va < vb) return -1
        if (va > vb) return 1
        return 0
    })
    return arr

// Voro_model_member_anchor — a member's STABLE UNIQUE identity string: the mainkey's VALUE when it
//  carries one (Fern:'silver' → silver), else a naming-key value, else the join of its distinguishing
//   field values (a Boulder's grade+stratum).  Content-derived so the SAME particle reads the SAME
//    anchor every beat — the drift diff pairs a survivor to itself, only true arrivals|departures move.
Voro_model_member_anchor(p):
    let mk = Object.keys(p.sc)[0]
    let mv = p.sc[mk]
    if (typeof mv === 'string' && mv.length) return mv
    for (const nk of ['name', 'title', 'label', 'nick', 'id']) {
        let v = p.sc[nk]
        if (typeof v === 'string' && v.length) return v
    }
    let parts = []
    for (const k of Object.keys(p.sc)) {
        if (k === mk) continue
        let v = p.sc[k]
        if (typeof v === 'string' && v.length) { parts.push(v) } else if (typeof v === 'number') { parts.push('' + v) }
    }
    if (parts.length) return parts.join(' ')
    return mk

// Voro_model_member_facts — a raw particle's (key,val) claims read straight off its sc.  The presence
//  mainkey marker (Boulder:1) carries no value so it contributes nothing; a mainkey that CARRIES a value
//   (Fern:'silver') is the member's NAME not an ordering fact, so it is skipped as an axis key too.
//    Weight 0 — a member particle was never grasp-scored (only the fold's rep Vtuffing was); loudness
//     reads the rep instead.  A member sinks or rises on the axis by its own recorded fields.
Voro_model_member_facts(p):
    let out = []
    let mk = Object.keys(p.sc)[0]
    for (const k of Object.keys(p.sc)) {
        if (k === mk) continue
        let v = p.sc[k]
        if (typeof v === 'number') { v = '' + v }
        if (typeof v !== 'string') continue
        if (!v.length) continue
        out.push({ key: k, val: v, weight: 0 })
    }
    return out

// Voro_facts_top_weight — the loudest weight in a facts list (a member's own emphasis, 0 when none).
Voro_facts_top_weight(facts):
    let top = 0
    for (const f of (facts || [])) if (f.weight > top) top = f.weight
    return top

// Voro_model_loud_from — a family's top-K loudest DISTINCT (key,val) claims from a pooled facts list.
//  The grasp weighed each fact 0..100 (how much it sets its cell apart); keep the loudest weight per
//   distinct claim and return the K loudest as { key, val, weight } — key and val stay SPLIT so the
//    consumer (and the snap) get a typed claim, never a pre-joined display string.  Pooled from the
//     fold's WEIGHTED source (a gang's rep Vtuffing, a pane's own), never per-member noise.  Claims on
//      `axis_key` don't compete — the axis organ already owns that key's whole story.
Voro_model_loud_from(facts, K, axis_key):
    let best = {}
    let src = {}
    let order = []
    for (const f of (facts || [])) {
        if (!f.key) continue
        if (axis_key && f.key === axis_key) continue
        let id = f.val === '' ? f.key : f.key + ': ' + f.val
        if (best[id] == null) {
            best[id] = 0
            src[id] = f
            order.push(id)
        }
        if (f.weight > best[id]) best[id] = f.weight
    }
    order.sort((a, b) => best[b] - best[a])
    let out = []
    let lim = K < order.length ? K : order.length
    for (let i = 0; i < lim; i++) out.push({ key: src[order[i]].key, val: src[order[i]].val, weight: best[order[i]] })
    return out

// Voro_model_drift — per-family goners|neus via a %Seem over the model's MEMBER layer.  The Seem walks
//  voro_model's %Family/%Member subtree; resolve() flags each member that arrived (neu) or left (goner)
//   with cross-beat identity, for FREE, the same primitive the grasp and census_mirror ride.  We then
//    attribute each neu|goner to its FAMILY.  Returns { <family>: { gone, neu } }.  Snap-hostile (a live
//     Selection rides sc.Se), so it parks on the free voro_model itself, off-snap.
//  Two Seem knobs matter here:
//   · each_fn — the DEFAULT stops descent one layer deep (T.c.d > 1), which would clone Families but
//      never their Members.  We hand our own so the walk reaches depth 2 (root → Family → Member) and
//       stops below (a Member's own %Loud|val leaves aren't drift subjects) — so member arrivals|
//        departures are what resolve() diffs.
//   · trace_sc — the D clone is { ...trace_sc, ...C.sc }; the DEFAULT trace_sc ({Demonstrations:…})
//      would make Demonstrations the clone's FIRST key, so mainkey position is unreliable.  We read the
//       Family|Member keys by PRESENCE below instead of by position, so the default trace_sc is fine and
//        the source sc (Member:<anchor>, Family:<name>) rides the clone untouched.
Voro_model_drift(w, model):
    let out = {}
    let seem = model.o({ Seem: 'model' })[0]
    let fresh = 0
    if (!seem) {
        seem = this.i_Seem(model, { Seem: 'model', C: model, each_fn: this.Voro_model_seem_each })
        fresh = 1
    }
    seem.sc.C = model
    let news = await this.o_Seem(seem)
    // the FIRST resolve only ESTABLISHES the baseline D-sphere (everything is trivially "new" against an
    //  empty sphere) — report no drift on it, so a bench beat reads clean and real arrivals|departures
    //   start from the NEXT compute.  (The Seem now persists across the rebuild, so fresh is true once.)
    if (fresh) return out
    for (const d of news.neus) {
        let fam = this.Voro_model_drift_fam(d)
        if (!fam) continue
        if (!out[fam]) out[fam] = { gone: 0, neu: 0 }
        out[fam].neu = out[fam].neu + 1
    }
    for (const d of news.goners) {
        let fam = this.Voro_model_drift_fam(d)
        if (!fam) continue
        if (!out[fam]) out[fam] = { gone: 0, neu: 0 }
        out[fam].gone = out[fam].gone + 1
    }
    return out

// Voro_model_seem_each — the model Seem's walk gate: descend to the Member layer (depth 2), stop below.
//  A flat arrow (T.c.d is the Travel's depth) so the drift diff is member-grained, not family-grained.
Voro_model_seem_each(D, C, T):
    if (T.c.d > 2) T.sc.no_further = 'model-depth'

// Voro_model_drift_fam — the family a drifted D node belongs to, read by KEY PRESENCE (the D clone leads
//  with the default trace_sc's key, so position is unreliable).  A drifted %Member clone carries its own
//   `fam` (stamped on the row for exactly this — the resolve hands back a DETACHED node with no parent
//    link, so walking up to the %Family clone fails).  A whole %Family arriving|leaving carries Family.
//     Null for anything else (the %Model head, a bare Demonstrations wrapper, a %Loud leaf).
Voro_model_drift_fam(d):
    if (typeof d.sc.fam === 'string' && d.sc.fam) return d.sc.fam
    if (d.sc.Family != null && typeof d.sc.Family === 'string') return d.sc.Family
    if (d.sc.Member != null) {
        let p = d.c.up
        if (p && p.sc && typeof p.sc.Family === 'string') return p.sc.Family
    }
    return null
//#endregion

// Voro_crush_walk — recurse; structural mainkeys stay graph (the skeleton must remain readable) but
//  are walked THROUGH; a crushed container's subtree is NOT descended (folded here = folded in the
//   Cyto walk, the same cut).  EVERYTHING the walk touches gets c.stuffy (the presentation skin) —
//    c.stuffy IS the crushed look in Cyto (self-row stuffings for spine + leaves, children-Stuffing
//     where c.stuff rides beside it); a plain snapped %stuff elsewhere (Machinery peeks, stuff_of)
//      keeps the classic labelled look untouched.
Voro_crush_walk(node, d, stats, level):
    if (d > 8) return
    let loose = {}
    let spilled = 0
    for (const c of node.o()) {
        let mk = Object.keys(c.sc)[0]
        // %Opt is config, %self is machinery (beat rounds + a wall-clock %est) — the VIEW
        //  already hides both (cytyle_classify), so the crush must not gang them either: a
        //   cell:self in the census is a pane the canvas can never draw (the render-debt
        //    gauge lies) and its transcript bakes the est TIMESTAMP into fixtures (VoroRadio
        //     steps 4-5 red on every re-run).
        if (mk === 'Opt' || mk === 'self') continue
        // ANY pop intent among the children marks this locale as being surfed — the
        //  remaining leaves then gang at min 2 (the spill relax), because "a few pop
        //   out, the REST stays one pane" is the surf's contract.
        if (c.c.popped || c.c.popped_open) spilled = spilled + 1
        // TINY = a leaf or a small all-leaf frond (≤3 children): it rides its mainkey's
        //  gang instead of claiming a pane of its own — the owner's "bigger looser" board;
        //   a two-form species is a chip with a /*N glyph, not a cell.  A gang that fails
        //    to form falls back per-member in Voro_gang_fold (a tiny container folds as its
        //     own little pane THERE, so a lone artist keeps its cell).
        let kids = c.o()
        let tiny = kids.length < 1 || (kids.length <= 3 && !kids.some(k => k.o().length > 0))
        if (c.c.popped && tiny) {
            // a tiny someone SURFED OUT of its gang|fold (Vtuff_pop) — never re-gangs; it
            //  stands as its own node until un-popped or ◈ un-imposes.  One that later grows
            //   a deep frond re-enters the ordinary rules (a popped DEEP container folds as
            //    its own pane below, which is a node all the same).
            //  KEEP the gang memory across the unstamp: a popped ex-rep must remember its
            //   siblings (their pop stamps ride too) or Vtuff_unpop's gang sweep is dead by
            //    the time aging fires and the locale leaks permanently-popped orphans that
            //     never re-gang — the pool shrinks silently (the VoroRadio audit's find).
            let gang = c.c.gang
            this.Voro_unstamp(c)
            if (gang) c.c.gang = gang
            c.c.stuffy = 1
            stats.visible = stats.visible + 1
            continue
        }
        if (mk === 'w' || mk === 'H' || mk === 'A' || mk === 'Peering' || mk === 'Pier' || mk === 'req') {
            if (level >= 2 && (mk === 'Peering' || mk === 'Pier') && c.o().length >= 2) {
                let verdict = this.Voro_crushable(c)
                if (verdict) {
                    this.Voro_stamp_fold(c, verdict, stats)
                    continue
                }
            }
            let swarm = this.Voro_swarmable(c, mk)
            if (swarm) {
                this.Voro_stamp_fold(c, swarm, stats)
                continue
            }
            if (mk === 'req' && c.o().length < 1) {
                if (!loose[mk]) loose[mk] = []
                loose[mk].push(c)
                continue
            }
            this.Voro_unstamp(c)
            c.c.stuffy = 1
            if (mk !== 'w' && mk !== 'H' && mk !== 'A') stats.visible = stats.visible + 1
            this.Voro_crush_walk(c, d + 1, stats, level)
            continue
        }
        if (tiny) {
            if (!loose[mk]) loose[mk] = []
            loose[mk].push(c)
            continue
        }
        let verdict = this.Voro_crushable(c)
        if (verdict) {
            this.Voro_stamp_fold(c, verdict, stats)
            continue
        }
        // not a fold this pass (today that means popped_open) — shed any stale fold stamps
        this.Voro_unstamp(c)
        c.c.stuffy = 1
        stats.visible = stats.visible + 1
        this.Voro_crush_walk(c, d + 1, stats, level)
    }
    this.Voro_gang_fold(loose, stats, level, spilled > 0)

// Voro_gang_fold — the CO-CRUSH of scattered same-mainkey leaves (the owner's "%witnessed and
//  %reached crushed further — together into one cell+Stuffing each").  Leaves with no foldable
//   parent gather by mainkey; a big enough gang ELECTS its first member as representative — the
//    rep wears the fold stamps plus c.gang (the live member list, runtime refs on .c only) and
//     the rest are c.represented (their row already shows in the rep's pane, so the Cyto walk
//      skips them to avoid drawing it twice; cytyle_classify reads the stamp).  The rep's pane
//       shows every member's row via Cytui's mirror (the rep itself has no children).  NOTHING
//        is minted or reparented in the model — election is pure c-side stamps, so no snap and
//         no fixture can ever see a gang.
// spill: siblings of a popped node gang at min 2 REGARDLESS of mainkey noisiness — they
//  were one pane a moment ago, and the surf's contract is "a few pop out, the REST stays
//   one pane", not "the rest confettis because Leptospermum isn't a noisy family".
Voro_gang_fold(loose, stats, level, spill):
    for (const mk of Object.keys(loose)) {
        let gang = loose[mk]
        let min = this.Voro_gang_min(mk, level)
        if (spill && min > 2) min = 2
        if (gang.length >= min) {
            let rep = gang[0]
            delete rep.c.represented
            rep.c.stuff = 1
            rep.c.stuffy = 1
            rep.c.fold_kind = mk
            rep.c.fold_n = gang.length
            rep.c.gang = gang
            for (let gi = 1; gi < gang.length; gi++) {
                this.Voro_unstamp(gang[gi])
                gang[gi].c.represented = 1
                gang[gi].c.stuffy = 1
            }
            stats.gangs = stats.gangs + 1
            stats.ganged = stats.ganged + gang.length
            stats.visible = stats.visible + 1
        } else {
            for (const c of gang) {
                // no gang formed: a tiny CONTAINER falls back to its own fold pane (a lone
                //  artist keeps its cell); a plain leaf stands as itself.
                let verdict = null
                if (c.o().length > 0) verdict = this.Voro_crushable(c)
                if (verdict) {
                    this.Voro_stamp_fold(c, verdict, stats)
                    continue
                }
                this.Voro_unstamp(c)
                c.c.stuffy = 1
                stats.visible = stats.visible + 1
            }
        }
    }

// Voro_gang_min — how many scattered leaves of one mainkey make a gang.  The NOISY families
//  (assertion/req confetti) gang at 3, loosening to 2 when the governor escalates; any other
//   mainkey only gangs under escalation (level >= 1, at 3) — at rest an unusual leaf pair
//    stays two honest nodes.
Voro_gang_min(mk, level):
    let noisy = { req: 1, witnessed: 1, see: 1, reached: 1 }
    if (noisy[mk]) {
        if (level >= 1) return 2
        return 3
    }
    if (level >= 1) return 3
    return 99

// Voro_unstamp — the authoritative-pass eraser: anything the walk decides is NOT a fold this
//  pass sheds every fold/gang stamp it may carry from an earlier pass or level.  c-side deletes
//   only; stuffy is re-set by the caller where it applies.
Voro_unstamp(c):
    delete c.c.stuff
    delete c.c.fold_kind
    delete c.c.fold_n
    delete c.c.gang
    delete c.c.represented
    delete c.c.vtuffing
    delete c.c.vtuffing_sig

// Voro_stamp_fold — the one place a fold is stamped: the two view flags plus the fold's LIVE
//  descriptors (c.fold_kind the dominant child mainkey, c.fold_n the child count) — all c-side,
//   never snapped.  Cytui reads them via the node's source_n: the kind colours the cell (a fold
//    wears what is INSIDE it) and the count lifts its seed-weight floor (a bigger family claims
//     a bigger cell).
Voro_stamp_fold(c, verdict, stats):
    delete c.c.gang
    delete c.c.represented
    c.c.stuff = 1
    c.c.stuffy = 1
    c.c.fold_kind = verdict.kind
    c.c.fold_n = verdict.n
    stats.count = stats.count + 1
    stats.folded = stats.folded + verdict.n
    stats.visible = stats.visible + 1

// Voro_swarmable — the crush-harder loosening: a STRUCTURAL container normally stays graph (the
//  skeleton must remain readable), but when its children are a homogeneous SWARM of one noisy
//   mainkey (>= 3 kids, all %req / %witnessed / %see — same key, varying value, never resolving
//    as same) the container folds as the group's chunk: the swarm reads as one pane whose
//     Stuffing rows show the spread, instead of confetti littering the graph.  w/H/A never fold
//      (they ARE the skeleton).  Strict homogeneity for now — a mixed structural container keeps
//       its children in the graph.
Voro_swarmable(c, mk):
    if (c.c.popped_open) return null
    if (mk === 'w' || mk === 'H' || mk === 'A') return null
    let N = c.o()
    if (N.length < 3) return null
    let noisy = { req: 1, witnessed: 1, see: 1, reached: 1 }
    let kinds = {}
    for (const k of N) {
        if (k.c.popped || k.c.popped_open) return null
        let kmk = Object.keys(k.sc)[0]
        kinds[kmk] = (kinds[kmk] || 0) + 1
    }
    let names = Object.keys(kinds)
    if (names.length !== 1) return null
    if (!noisy[names[0]]) return null
    return { kind: names[0], n: N.length }

// Voro_crushable — the rule: fold ANY non-structural container with children.  Even a weakly
//  motivated Stuffing (mixed keys, one row per group) reads better as one chunk than as confetti.
//   kind = the dominant child mainkey (a nav aid — the chunk's "what's inside"), n = child count.
//    A POPPED CHILD refuses the fold: someone surfed that child out, and a shut pane would
//     swallow it silently (Cyto's no_further stops at a stuffed node, so the popped stamp
//      alone changes nothing — the pane MUST open for the child to reach the graph).  The
//       container then descends as a plain hub node; its remaining leaves re-gang at min 2
//        (the spill relax in Voro_gang_fold) and the scan's own parent→child `/` edges draw
//         the family explosion for free.
Voro_crushable(c):
    if (c.c.popped_open) return null
    let N = c.o()
    if (N.length < 1) return null
    let counts = {}
    for (const k of N) {
        if (k.c.popped || k.c.popped_open) return null
        let mk = Object.keys(k.sc)[0]
        counts[mk] = (counts[mk] || 0) + 1
    }
    let kind = null
    let kn = 0
    for (const mk of Object.keys(counts)) {
        if (counts[mk] > kn) { kind = mk; kn = counts[mk] }
    }
    return { kind: kind, n: N.length }

// Voro_crush_clear — the ◈ un-imposition: walk everything and strip the two view stamps.
//  c-side deletes only, so it is snap- and query-safe anywhere; a Book-opted world just
//   re-stamps next beat (its drive calls the scan), which is the right outcome.
Voro_crush_clear(node, d):
    if ((d || 0) > 12) return
    delete node.c.stuff
    delete node.c.stuffy
    delete node.c.drift_seq
    delete node.c.drift_opens
    delete node.c.drift_focus
    delete node.c.fold_kind
    delete node.c.fold_n
    delete node.c.gang
    delete node.c.represented
    delete node.c.crush_level
    delete node.c.popped
    delete node.c.popped_open
    delete node.c.popped_auto
    delete node.c.drift_seen
    delete node.c.vtuffing
    delete node.c.vtuffing_sig
    for (const c of node.o()) this.Voro_crush_clear(c, (d || 0) + 1)
//#endregion

//#region vtuffing — the pane-content engine: a fold|gang's members distilled into a layout C**
// ══ Vtuffing — what a pane SAYS (the microcosm cards grew up; they used to say one word) ═══════
//  The molded Stuffing was rich; the card grid that replaced it at depth said "Track".  Vtuffing
//   is the data pipeline between them: Vtuff_build reads a fold|gang's members and distils them
//    into a small LAYOUT TREE — a FREE C** (new TheC, reachable from nothing, so no snap and no
//     encode ever sees it) whose rows say what the members share, how they spread, and where to
//      dig.  The renderer (Cytui's micro layer) stays dumb: it walks rows and fits text into the
//       cell polygon.  The smarts live HERE, .g-side, and extend the Waft way: define
//        Vtuff_of_<fold kind> on any ghost and that kind's panes author their own rows.
//
//  The tree:  %Vtuffing,of:<kind>,n:<members>            (c.src backlinks the fold|gang rep)
//               /%Vrow,row:title,text:'Artist: Moonlit  ×5',wgt:2
//               /%Vrow,row:fact,text:'artist: Neil Young'   — a key EVERYONE agrees on, said once
//               /%Vrow,row:spread,text:'title'              — a key that varies, chips below
//                  /%Vbit,text:'Tide',n:2                   — value chips with counts
//               /%Vrow,row:member,text:'Track · Halo'       — per-member when the family is small
//                                                             (c.member — the pop-out handle)
//               /%Vrow,row:dip,text:'/*12'                  — the surf handle (c.members)

// Vtuff_build — the cached entry: members = the gang, else the fold's children.  The cache
//  (c.vtuffing) is keyed by a cheap signature — member count + summed versions — so a beat that
//   changes nothing returns the same tree, per-frame render calls cost one sum, and any content
//    drift rebuilds.  Returns null on a non-fold (the renderer then leaves the pane alone).
Vtuff_build(src):
    let members = src.c.gang || (src.c.stuff && src.o()) || null
    if (!members || !members.length) return null
    let sig = members.length
    for (const m of members) sig = sig + (m.version || 0)
    let bamboo = this.Vtuff_bamboo_on()
    // cache the STRUCTURE by sig+mode; the live Se emphasis re-applies each call (drift moves
    //  without changing members, so it can't ride the sig — see Vtuff_se_apply).
    if (src.c.vtuffing && src.c.vtuffing_sig === sig && !!src.c.vtuffing_bamboo === !!bamboo) {
        if (bamboo) this.Vtuff_se_apply(src.c.vtuffing, src)
        return src.c.vtuffing
    }
    let kind = src.c.fold_kind || 'stuff'
    let root = new TheC({ c: {}, sc: { Vtuffing: 1, of: kind, n: members.length } })
    root.c.src = src
    let hook = this['Vtuff_of_' + kind]
    if (hook) {
        hook.call(this, root, members, src)
    } else if (bamboo) {
        this.Vtuff_bamboo(root, members, src)
        this.Vtuff_se_apply(root, src)
    } else {
        this.Vtuff_default(root, members, src)
    }
    src.c.vtuffing = root
    src.c.vtuffing_sig = sig
    src.c.vtuffing_bamboo = bamboo
    return root

// Vtuff_ident — one short line of identity for a particle: the mainkey (with its value when the
//  value carries meaning), sweetened by a naming key when one rides along.  {cell:'Coprosma'}
//   reads 'cell: Coprosma'; {Track:1,title:'Tide'} reads 'Track · Tide'.
Vtuff_ident(m):
    let mk = Object.keys(m.sc)[0]
    let v = m.sc[mk]
    let t = mk
    if (v !== 1 && v != null) t = mk + ': ' + v
    let names = ['name', 'title', 'text', 'nick', 'label']
    for (const k of names) {
        if (k !== mk && typeof m.sc[k] === 'string') {
            t = t + ' · ' + m.sc[k]
            break
        }
    }
    return t

// Vtuff_name — the NAME of a particle, type stripped: the mainkey's value when it carries one
//  ({cell:'Kunzea'} → 'Kunzea'), else a naming key ({Artist:1,name:'Fernway'} → 'Fernway'),
//   else ''.  The TYPE rides separately as the row's `tag` (a small kind-coloured chip the
//    renderer draws) — the metaphysics made visible: the mainkey IS different from other keys,
//     so it stops being inline prose ('cell: Kunzea' here, 'Artist · Fernway' there) and
//      becomes one consistent type-badge beside one consistent name.
Vtuff_name(m):
    let mk = Object.keys(m.sc)[0]
    let v = m.sc[mk]
    if (v !== 1 && v != null) return '' + v
    let names = ['name', 'title', 'text', 'nick', 'label']
    for (const k of names) {
        if (k !== mk && typeof m.sc[k] === 'string') return m.sc[k]
    }
    return ''

// Vtuff_namekey — the KEY whose value Vtuff_name displayed (the mainkey itself when it carries the
//  name, else the naming key like 'title').  The homogeneous list shows members BY this key, so
//   Vtuff_keyrows must skip it too — else a Track list of titles is followed by a 'title' spread of
//    the SAME titles (the Frond/Root repeat the owner flagged).
Vtuff_namekey(m):
    let mk = Object.keys(m.sc)[0]
    let v = m.sc[mk]
    if (v !== 1 && v != null) return mk
    let names = ['name', 'title', 'text', 'nick', 'label']
    for (const k of names) {
        if (k !== mk && typeof m.sc[k] === 'string') return k
    }
    return mk

// Vtuff_member_bit — the SHORT distinguishing bit of a member inside a pane whose title already
//  names the family: its name, else its bare mainkey.  (Children-to-dig ride the row|chip's
//   `sub` count now, drawn as the lilac /*N glyph — not baked into the text.)
Vtuff_member_bit(m):
    let t = this.Vtuff_name(m)
    if (!t) t = Object.keys(m.sc)[0]
    return t

// Vtuff_default — the generic distiller.  A HOMOGENEOUS family (one mainkey) never repeats
//  itself: the title names the family ONCE ('Olearia  ×4') and one list row carries the members
//   as clickable chips of just their distinguishing bit ('figaro | tenuifolium | +2' — the
//    owner's "Olearia: this|that|etc" form); shared facts and spreads of the OTHER keys ride
//     below.  A MIXED small family speaks per-member (each row a pop-out handle), and a tiny one
//      Travels the openness ONE level — a member's own few children indent under it (row:sub,
//       poppable too): the same-graph seed of recursion, depth capped where the pixels are.
//        A MIXED big family gets facts|spreads.  A presence-only key everyone carries (the
//         mainkey's 1) says nothing — skipped.
Vtuff_default(root, members, src):
    let kinds = {}
    for (const m of members) {
        kinds[Object.keys(m.sc)[0]] = 1
    }
    let homo = Object.keys(kinds).length === 1
    // the TITLE: one name + one type-tag, every pane the same shape.  A gang has no name of
    //  its own (the rep's ident would read as ONE member — '4 figaros'), so its title is just
    //   the tag + count; a fold container contributes its name ('Kunzea  ×14' tagged `cell`,
    //    'Fernway  ×2' tagged `Artist` — no more two formats).
    let tag = src.c.fold_kind || Object.keys(kinds)[0]
    let name = ''
    if (!src.c.gang) {
        tag = Object.keys(src.sc)[0]
        name = this.Vtuff_name(src)
    }
    let tsc = { Vrow: 1, row: 'title', text: (name ? name + '  ' : '') + '×' + members.length, wgt: 2, tag: tag }
    // nk — the KEY the name is the value OF (Stuffing is explicit about what's a key or
    //  what's a value; a bare 'Riverine' hid that it rides %Artist's `name`).  The renderer
    //   says `Artist name: Riverine`; when the mainkey itself carries the name, nk === tag
    //    and the tag takes the colon (`cell: Kunzea`).
    if (name) tsc.nk = this.Vtuff_namekey(src)
    root.i(tsc)
    if (homo) {
        let r = root.i({ Vrow: 1, row: 'list', text: '', wgt: 1 })
        let shown = members
        // generous — the phi spiral packs ~25 comfortably; the renderer's fit is the real
        //  gate (the owner: "give it until we have problems fitting everything in").
        if (members.length > 25) shown = members.slice(0, 25)
        for (const m of shown) {
            let bsc = { Vbit: 1, text: this.Vtuff_member_bit(m), n: 1 }
            let bsub = m.o().length
            if (bsub) bsc.sub = bsub
            let b = r.i(bsc)
            b.c.member = m
        }
        if (members.length > shown.length) r.i({ Vbit: 1, text: '+' + (members.length - shown.length), n: 0 })
        this.Vtuff_keyrows(root, members, [Object.keys(kinds)[0], this.Vtuff_namekey(members[0])])
    } else if (members.length <= 5) {
        for (const m of members) {
            let nm = this.Vtuff_name(m)
            let mmk = Object.keys(m.sc)[0]
            let sub = m.o().length
            let rsc = { Vrow: 1, row: 'member', text: nm || mmk, wgt: 1 }
            if (nm) rsc.tag = mmk
            if (sub) rsc.sub = sub
            let r = root.i(rsc)
            r.c.member = m
            if (members.length <= 3 && sub && sub <= 3) {
                for (const k of m.o()) {
                    let knm = this.Vtuff_name(k)
                    let kmk = Object.keys(k.sc)[0]
                    let ksc = { Vrow: 1, row: 'sub', text: knm || kmk, wgt: 1 }
                    if (knm && kmk !== mmk) ksc.tag = kmk
                    let ksub = k.o().length
                    if (ksub) ksc.sub = ksub
                    let sr = root.i(ksc)
                    sr.c.member = k
                }
            }
        }
    } else {
        this.Vtuff_keyrows(root, members, [])
    }
    let dip = root.i({ Vrow: 1, row: 'dip', text: '/*' + members.length, wgt: 1 })
    dip.c.members = members

//#region bamboo — 🎋 the schematic gets jointed, and the fold reads its surroundings (Se)
// ══ Vtuff_bamboo — the same distilled rows, grown into a jointed STALK ═══════════════════════════
//  §🎋's first build.  The flat Vrow list of Vtuff_default becomes a stalk of SEGMENTS (the bamboo
//   internodes) divided by JOINTS: crown (who it is) · cane (its members) · leaf (the shared
//    facts|spreads) · shoot (the /*N surf handle).  A pane then reads its SHAPE at a glance — how
//     many joints, which band is thick — before a word is read.  Each %Vseg carries a live c.se
//      EMPHASIS (Se, below): the renderer flattens the segments (backward-compatible — the rows
//       come out in tree order, so a Se-blind renderer loses nothing) and MAY thicken|quiet a band
//        by its se.  Reuses the flat distiller's leaf helpers (Vtuff_keyrows into the leaf segment)
//         so the wording logic lives in ONE place; empty bands just carry no rows.
//  SHELVED (owner 2026-07-11): the crown|cane|leaf|shoot vocabulary landed overnight and never
//   earned the owner's eyes — "I don't know anything about" it — and its stash read had become a
//    ZOMBIE (the 🎋 button died in the Cytui rollback, so a stale Cyto_bamboo=1 kept dressing
//     every tree in %Vseg with no way to turn it off — and the census transcript, hence FIXTURES,
//      followed the tab).  Hard false until bamboo v2: hierarchy expressed as sub-cells|sub-graph
//       (the owner's redirect), not text stalks.  The machinery below keeps; this gate is the lab door.
Vtuff_bamboo_on():
    return false

Vtuff_bamboo(root, members, src):
    let kinds = {}
    for (const m of members) kinds[Object.keys(m.sc)[0]] = 1
    let homo = Object.keys(kinds).length === 1
    let tag = src.c.fold_kind || Object.keys(kinds)[0]
    let name = ''
    if (!src.c.gang) {
        tag = Object.keys(src.sc)[0]
        name = this.Vtuff_name(src)
    }
    // crown — identity, the first joint, always present
    let crown = root.i({ Vseg: 1, seg: 'crown', joint: 0 })
    let csc = { Vrow: 1, row: 'title', text: (name ? name + '  ' : '') + '×' + members.length, wgt: 2, tag: tag }
    if (name) csc.nk = this.Vtuff_namekey(src)
    crown.i(csc)
    // cane — the members (only when there ARE member rows: a mixed big family speaks only in leaf)
    if (homo || members.length <= 5) {
        let cane = root.i({ Vseg: 1, seg: 'cane', joint: 1 })
        if (homo) {
            let r = cane.i({ Vrow: 1, row: 'list', text: '', wgt: 1 })
            let shown = members
            if (members.length > 25) shown = members.slice(0, 25)
            for (const m of shown) {
                let bsc = { Vbit: 1, text: this.Vtuff_member_bit(m), n: 1 }
                let bsub = m.o().length
                if (bsub) bsc.sub = bsub
                let b = r.i(bsc)
                b.c.member = m
            }
            if (members.length > shown.length) r.i({ Vbit: 1, text: '+' + (members.length - shown.length), n: 0 })
        } else {
            for (const m of members) {
                let nm = this.Vtuff_name(m)
                let mmk = Object.keys(m.sc)[0]
                let sub = m.o().length
                let rsc = { Vrow: 1, row: 'member', text: nm || mmk, wgt: 1 }
                if (nm) rsc.tag = mmk
                if (sub) rsc.sub = sub
                let r = cane.i(rsc)
                r.c.member = m
                if (members.length <= 3 && sub && sub <= 3) {
                    for (const k of m.o()) {
                        let knm = this.Vtuff_name(k)
                        let kmk = Object.keys(k.sc)[0]
                        let ksc = { Vrow: 1, row: 'sub', text: knm || kmk, wgt: 1 }
                        if (knm && kmk !== mmk) ksc.tag = kmk
                        let ksub = k.o().length
                        if (ksub) ksc.sub = ksub
                        let sr = cane.i(ksc)
                        sr.c.member = k
                    }
                }
            }
        }
    }
    // leaf — shared facts + spreads (reuse the flat distiller's keyrows into this segment)
    let leaf = root.i({ Vseg: 1, seg: 'leaf', joint: 2 })
    if (homo) {
        this.Vtuff_keyrows(leaf, members, [Object.keys(kinds)[0], this.Vtuff_namekey(members[0])])
    } else {
        this.Vtuff_keyrows(leaf, members, [])
    }
    // shoot — the /*N surf handle, the last joint, always present
    let shoot = root.i({ Vseg: 1, seg: 'shoot', joint: 3 })
    let bdip = shoot.i({ Vrow: 1, row: 'dip', text: '/*' + members.length, wgt: 1 })
    bdip.c.members = members

// Vtuff_world — walk c.up to the enclosing w, for Se's neighbourhood read.  Capped so a detached
//  or mid-mint tree can't spin.
Vtuff_world(src):
    let n = src
    let i = 0
    while (n && i < 24) {
        if (n.sc && n.sc.w) return n
        n = n.c.up
        i = i + 1
    }
    return null

// Vtuff_se — SURROUNDINGS-REACTIVE emphasis: the owner's Se, "what to do given the surroundings."
//  The FIRST Se in the geometry|pane domain (the twin of Voro_crushable, which judges a node in
//   ISOLATION — Se widens the read to the neighbourhood).  Today it reads the RADIO: the pane the
//    tuner is lighting (w.c.drift_focus) RAMPAGES — swell the cane (show the members) and the leaf;
//     a pane the tuner has dwelt PAST (not in the open window while a focus lives elsewhere) QUIETS
//      its leaf detail (0 = the renderer may collapse it).  Everything else stays neutral (1).
//   Pure c-side reads of the drift stamps — no DOM (rule 6), no snap (rule 2) — so it re-runs off
//    the cache every build call without churning the cached structure.  This is the seam the §🎋
//     chain grows on: Se1 (am I lit?) → Se2 (…so which bands, and how loud) → per-segment emphasis;
//      when chains are wanted the read widens to siblings + what's popped + what the radio lights.
Vtuff_se(src):
    let e = { crown: 1, cane: 1, leaf: 1, shoot: 1 }
    let w = this.Vtuff_world(src)
    if (!w) return e
    if (w.c.drift_focus === src) {
        e.cane = 2
        e.leaf = 2
        return e
    }
    let opens = w.c.drift_opens || []
    if (w.c.drift_focus && opens.indexOf(src) < 0) e.leaf = 0
    return e

// Vtuff_se_apply — stamp the live emphasis onto the (cached) segment tree: c-side only (seg.c.se),
//  so the structure caches while the emphasis stays live.  A no-op on a flat (non-bamboo) tree.
Vtuff_se_apply(root, src):
    let e = this.Vtuff_se(src)
    for (const seg of root.o()) {
        if (Object.keys(seg.sc)[0] !== 'Vseg') continue
        let k = seg.sc.seg
        seg.c.se = e[k] == null ? 1 : e[k]
    }
//#endregion

// Vtuff_keyrows — shared facts + spreads over the members' keys, skipping every key in `skips`
//  (when homogeneous: the family mainkey AND the naming key the list showed members by — the
//   title|list already said them; a spread repeating either is the 'cell: Olearia ×4' then
//    'Olearia: figaro' / Frond,Root stutter the owner flagged).  A key with ONE
//    distinct value across everyone says it once (fact); a varying key shows value chips with
//     counts, most-common first, capped with a visible tail.
Vtuff_keyrows(root, members, skips):
    let keys = []
    let seen = {}
    for (const m of members) {
        for (const k of Object.keys(m.sc)) {
            if (!seen[k]) { seen[k] = 1; keys.push(k) }
        }
    }
    for (const k of keys) {
        if (skips && skips.includes(k)) continue
        let vals = {}
        let order = []
        let have = 0
        for (const m of members) {
            if (!Object.prototype.hasOwnProperty.call(m.sc, k)) continue
            have = have + 1
            let v = '' + m.sc[k]
            if (vals[v] == null) { vals[v] = 0; order.push(v) }
            vals[v] = vals[v] + 1
        }
        if (!have) continue
        if (order.length === 1) {
            if (order[0] === '1') {
                if (have < members.length) root.i({ Vrow: 1, row: 'fact', text: k + ' ×' + have, wgt: 1 })
            } else {
                root.i({ Vrow: 1, row: 'fact', text: k + ': ' + order[0], wgt: 1 })
            }
            continue
        }
        order.sort((a, b) => vals[b] - vals[a])
        let r = root.i({ Vrow: 1, row: 'spread', text: k, wgt: 1 })
        let chips = order
        if (order.length > 4) chips = order.slice(0, 3)
        for (const v of chips) r.i({ Vbit: 1, text: v, n: vals[v] })
        if (order.length > chips.length) r.i({ Vbit: 1, text: '+' + (order.length - chips.length), n: 0 })
    }

// Vtuff_pop — the /*N surf, the owner's "locate|create nodes popping up in the graph around it,
//  not in the Stuffing** itself" — now UNDER CONTROL (the owner's poke): a MEMBER row|chip pops
//   that ONE out (any depth — Vtuff_pop_stamp unfurls the container chain between it and the
//    graph); the DIP spills a REASONABLE FEW — the top-K by subtree weight — and the REST stays
//     one pane (the spill relax in Voro_gang_fold re-gangs the remainder at min 2); a pane of
//      K+1 or fewer just opens whole.  All c-side INTENT stamps: crush passes respect them,
//       Vtuff_unpop (right-click the node) or the ◈ un-imposition forgets them.  Then one wave
//        re-scans — the graph grows the new nodes right where the pane sits, and the scan's own
//         parent→child `/` edges wire an unfurled fold's family explosion for free.
async Vtuff_pop(src, member, auto):
    if (member) {
        this.Vtuff_pop_stamp(src, member, auto)
    } else {
        let members = src.c.gang || src.o()
        let K = 3
        if (members.length <= K + 1) {
            if (src.c.gang) {
                for (const m of src.c.gang) this.Vtuff_pop_stamp(src, m, auto)
            } else {
                src.c.popped_open = 1
                if (auto) src.c.popped_auto = 1
                this.Voro_unstamp(src)
            }
        } else {
            let ranked = members.slice()
            ranked.sort((a, b) => b.o().length - a.o().length)
            for (let i = 0; i < K; i++) this.Vtuff_pop_stamp(src, ranked[i], auto)
        }
    }
    delete src.c.vtuffing
    delete src.c.vtuffing_sig
    let w = src
    while (w && !(w.sc && w.sc.w)) w = w.c.up
    if (w && this.cyto_update_wave) await this.cyto_update_wave(w)

// Vtuff_pop_stamp — one node surfed out: c.popped on the node itself, c.popped_open on every
//  container between it and the pane (a grandchild's whole chain must unfurl for the scan to
//   reach it — Voro_crushable|swarmable refuse a fold whose child is popped|popped_open), and
//    c.represented dropped so a ganged member draws again.  `auto` rides c.popped_auto beside
//     the intent: the RADIO's own openings (Voro_drift) age back shut; a HUMAN's never do —
//      manual intent outranks the tuner.
Vtuff_pop_stamp(src, member, auto):
    member.c.popped = 1
    if (auto) member.c.popped_auto = 1
    delete member.c.represented
    let p = member.c.up
    let guard = 0
    while (p && p !== src && guard < 8) {
        p.c.popped_open = 1
        if (auto) p.c.popped_auto = 1
        this.Voro_unstamp(p)
        p = p.c.up
        guard = guard + 1
    }

// Vtuff_unpop — fold-me-back, the pop's inverse: forget the intents on a node, its GANG (a loose
//  gang's members sit BESIDE the rep under w — not below it — so without this a gang pop's sibling
//   stamps leaked and aged locales never re-ganged), and one level of its children (right-clicking
//    an unfurled HUB folds its whole family back), then wave — the next authoritative pass
//     re-folds|re-gangs by the ordinary rules.  Gesture: right-click the popped node (Cytui cxttap).
async Vtuff_unpop(n):
    delete n.c.popped
    delete n.c.popped_open
    delete n.c.popped_auto
    for (const m of n.c.gang || []) {
        delete m.c.popped
        delete m.c.popped_open
        delete m.c.popped_auto
    }
    delete n.c.gang   // the roster served its sweep; the next authoritative pass re-elects fresh
    for (const c of n.o()) {
        delete c.c.popped
        delete c.c.popped_open
        delete c.c.popped_auto
    }
    delete n.c.vtuffing
    delete n.c.vtuffing_sig
    let w = n
    while (w && !(w.sc && w.sc.w)) w = w.c.up
    if (w && this.cyto_update_wave) await this.cyto_update_wave(w)
//#endregion

//#region drift — 📻 the radio: attention as a supplied service (v1)
// ══ Voro_drift — the graph plays YOU: a tuner that walks attention around the board ═══════════
//  The owner's ask (2026-07-07): "automagically drifting towards some subset of stuff...
//   an algorithm that shifts your actual attention around that area as it wants to, as in
//    supplying a radio listener."  This is a NORTH STAR of the whole system — the full design
//     lives in spec/Voro_vtuffing.md §North stars.  v1 here is the smallest true tuner; each
//      TICK (the view's dwell cadence, ~7s, 📻 on the ◈ bar) it:
//       1) AGES — the oldest auto-opened locale folds back shut (the wandering-landscape
//          answer: the trail behind the listener disincludes itself),
//       2) CHOOSES — the next focus among the fold|gang panes, scored by family size +
//          freshness (starves revisits) + NEARNESS to the current focus (same vfamily or
//           same parent: the "around that area" pull), plus a deterministic hash jitter
//            standing in for taste; every 4th hop drops the nearness bonus (station drift,
//             not a random walk),
//       3) OPENS it a little — the bounded dip, stamped popped_auto so the tuner only ever
//          ages away its OWN openings; a human's pop is never touched,
//      and returns the focus C for the view to glide its camera onto.  Everything c-side;
//       no Book arms the radio, so no snap ever sees it.  The radio SUBSUMES the old "auto-
//        spill w/*/**" agenda item: open-a-little + age-behind IS the bounded spill governor.

// the tunable panes: fold|gang reps down to a shallow depth (below that the tuner would
//  be picking at what a pane already says better).
Voro_drift_candidates(w):
    let out = []
    this.Voro_drift_scan(w, 0, out)
    return out
Voro_drift_scan(node, d, out):
    if (d > 3) return
    for (const c of node.o()) {
        if (c.c.stuff) {
            out.push(c)
            continue
        }
        if (!c.c.represented) this.Voro_drift_scan(c, d + 1, out)
    }

async Voro_drift_tick(w):
    w.c.drift_seq = (w.c.drift_seq || 0) + 1
    let seq = w.c.drift_seq
    let opens = w.c.drift_opens || []
    if (opens.length > 3) {
        let old = opens.shift()
        if (old && (old.c.popped_auto || old.o().some(k => k.c.popped_auto))) await this.Vtuff_unpop(old)
    }
    w.c.drift_opens = opens
    let cands = this.Voro_drift_candidates(w)
    if (!cands.length) return null
    let cur = w.c.drift_focus
    let free = seq % 4 === 0
    let best = null
    let bs = -1
    for (const c of cands) {
        let s = Math.min(9, c.c.fold_n || 1)
        let last = c.c.drift_seen || 0
        s = s + Math.min(12, (seq - last) * 2)
        if (!free && cur && c !== cur) {
            if (c.c.vfamily && cur.c && c.c.vfamily === cur.c.vfamily) s = s + 6
            if (cur.c && c.c.up === cur.c.up) s = s + 4
        }
        if (c === cur) s = s - 8
        s = s + (this.Voro_hash(Object.keys(c.sc)[0] + ':' + seq) % 5)
        if (s > bs) { bs = s; best = c }
    }
    if (!best) return null
    best.c.drift_seen = seq
    w.c.drift_focus = best
    await this.Vtuff_pop(best, null, 1)
    opens.push(best)
    return best
//#endregion
