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
Voro_crush_scan(w):
    let level = w.c.crush_level || 0
    let stats = this.Voro_crush_pass(w, level)
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
    w.c.crush_level = level
    this.Voro_report(w, stats)
    return stats

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
//      visible count, per-genus whether it folded to a gang or scattered loose (the owner's
//       "why are some Pittosporum non-cells" — level-dependent ganging, now readable), which
//        panes the radio popped, and the drift focus.  A sibling world is NOT in the flora
//         world's subtree, so cyto_scan never renders it — it is SNAP-ONLY, the seed of Story's
//          future separable snap channels (capture certain A/w on their own layer, trace always
//           on).  NO gate: whenever the fold runs (imposed or inline) it self-reports here.  Story
//            decides RECORDING not building — it prunes w:Voronoiology from the snap for a Book with
//             %dontSnapVoronoiology (MusuReplica keeps its replication fixture clean); the ◈ button
//              folds the Cyto MIRROR, which never reaches Story, so it reports live only.
Voro_report(w, stats):
    let A = w.c.up
    if (!A || !w.sc.w) return null
    let rname = 'Voronoiology'
    let rw = A.o({ w: rname })[0]
    if (!rw) rw = A.i({ w: rname, dontGraph: 1 })
    // %dontGraph — the self-report is process-trace NOISE, not data: keep it OUT of the live graph
    //  (Cyto's cytyle_classify skips a dontGraph node AND its subtree).  Snapped (sc, set at mint) so
    //   it SURVIVES encode|decode and is legible in the snap; also re-stamped c-side each beat so a
    //    world minted before this landed is covered too.  (Books that snap w:Voronoiology gain a
    //     dontGraph:1 on the world line — re-record picks it up.)
    rw.c.dontGraph = 1
    for (const c of rw.o().slice()) c.drop(c)
    w.c.report_beat = (w.c.report_beat || 0) + 1
    // level as 'L0'|'L1'|'L2' — a bare numeric 1 would snap as the boolean sentinel (collapse
    //  to a flag) and 0 would VANISH, so the governor level must ride as a string to stay legible.
    rw.i({ Voro: 1, beat: w.c.report_beat, level: 'L' + stats.level, visible: stats.visible, gangs: stats.gangs, folded: '' + stats.folded, count: '' + stats.count })
    if (w.c.drift_focus) {
        let f = w.c.drift_focus
        let fk = Object.keys(f.sc)[0]
        rw.i({ drift: 1, focus: fk + ' ' + f.sc[fk], opens: (w.c.drift_opens || []).length })
    }
    // one row per genus present, in the fixed Botany order (deterministic): the fold verdict
    //  the crush reached this beat — a gang (n folded behind a rep) or loose (each its own
    //   node|cell), plus how many the radio has popped out right now.
    for (const g of this.Botany_genera()) {
        let members = w.o().filter(c => Object.keys(c.sc)[0] === g)
        if (!members.length) continue
        let rep = members.find(m => m.c.stuff && m.c.gang)
        let pop = members.filter(m => m.c.popped).length
        let row = { row: g, n: members.length }
        if (rep) {
            row.fold = 'gang'
            row.rep = rep.sc[g]
            row.of = rep.c.fold_n
        } else {
            row.fold = 'loose'
            let cells = members.filter(m => m.c.stuff).length
            if (cells) row.cells = cells
        }
        if (pop) row.pop = pop
        rw.i(row)
    }

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
        if (mk === 'Opt') continue
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
    if (src.c.vtuffing && src.c.vtuffing_sig === sig) return src.c.vtuffing
    let kind = src.c.fold_kind || 'stuff'
    let root = new TheC({ c: {}, sc: { Vtuffing: 1, of: kind, n: members.length } })
    root.c.src = src
    let hook = this['Vtuff_of_' + kind]
    if (hook) {
        hook.call(this, root, members, src)
    } else {
        this.Vtuff_default(root, members, src)
    }
    src.c.vtuffing = root
    src.c.vtuffing_sig = sig
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

// Voro_books — the Books that exercise this render.  VoroMitosis + VoroRadio DRIVE the fold inline
//  (their subject is Voro); VoroScape + MusuReplica (Ghost/Story/Musuation.g) carry %useVoroCyto and
//   have the fold IMPOSED by Story at snap time — the data Book never touches it.
Voro_books():
    return ['VoroMitosis', 'VoroScape', 'MusuReplica']

// Voro_render_map — the stages in order (this ghost's crush, then Cytui's pixels), to walk the pipeline.
Voro_render_map():
    return ['Voro_crush_scan', 'Vtuff_build', 'voronoi_layout', 'install_nuclei', 'morph_voronoi', 'voronoi_paint_now', 'paint_final']

//#endregion
