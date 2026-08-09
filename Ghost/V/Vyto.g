// Vyto.g — the model side of the NEW glass (Ghost/V/, beside Voro.g; spec: Vyto_spec.md,
//  unpreened; workingouts: spec/vyto_workingouts/*).  Cyto grew a substrate problem — a
//   node-and-edge library under a glass that wants regions, walls and faces — and it never
//    had a continuous drive (the watch_c its comments promised was never built).  Vyto is
//     the moult: a second glass, commissioned per world exactly the way Cyto is, coexisting
//      while the fleet migrates; Cyto.svelte + Cytui.svelte freeze, Voro.g lives on (its fold
//       becomes the Fold organ here).
//  THIS MILESTONE IS THE HIGH-LEVEL SKELETON (spec §11): the organs, the furniture and the
//   dictionary words stand as NAMED STUBS — the board lists them from day one — so the
//    vocabulary exists in the workings and gets worn in while it is still cheap to rename.
//     No rendering is driven from here yet; Vytui renders only the board and the strip.
//  The six wants the stubs answer to (spec §2): space that states — expression first —
//   motion never blink — rest — interruptibility — the model is the UI.
//  v1 REFUSES (spec §12): takeTurns, ceremony flags on the commission, cytowave snapping,
//   headless anything, relayout-from-nothing.  Ceremony, when Story needs it, will ride the
//    REQUEST — never the commission.
//  All of w:Vyto is VIEW MATTER: the world sits beside the Run House (the w:Cyto precedent),
//   so nothing here reaches a run's got_snap and the Books stay Vyto-blind.

IMPORT()
    import Vytui from "$lib/O/Vytui.svelte"
    import { power_cells, poly_centroid, poly_area, pile_step, foam_cells } from "$lib/O/vyto_geometry"
    import { sig_of, group_edges, bucket_key_of, pull_step, budget_for, SIG_JOINS, FOCUS_BOOST, FOCUS_SHRINK, AREA_BASE } from "$lib/O/vyto_foam"

    // HEAT_BUY — what a full purse of attention actually BUYS, as a multiplier on env_area.
    //  The owner, 2026-08-09, of a crushed cell's ⤢: *"that we can click to make that cell become a
    //   normal cell right?  where's the attention sharing algorithm?  how do we balance things in the
    //    user's face?"*  The algorithm was there and honest — heat is earned by attending, self-taxed
    //     on everyone else, spent here as size — but at 0.8 its ENTIRE range was ×1.8 area, i.e. ×1.34
    //      radius.  A crushed cell (fit ≤ 0.34) cannot climb out of that on a full purse, so the ⤢ was
    //       promising something the currency could not pay, and attention read as decorative.
    //  A currency that can only nudge the order is not a currency.  At 3.5 a full purse is ×4.5 area
    //   (×2.1 radius), which can genuinely re-rank a pile — which is the point of spending anything.
    //  Heat is 0 in every Book (no fixture attends), so this is byte-invisible to all of them.
    const HEAT_BUY = 3.5

//#region the world — w:Vyto stands, plans, and waits for its commission
// Vyto — the w:Vyto worker.  Mirrors Cyto()'s shape so a client commissions either glass
//  the same way; but where Cyto idles under takeTurns, Vyto NEVER takes turns — its drive
//   is the grapple watch (below), and between stirs the glass is at REST on purpose.
Vyto(A, w):
    if (!w.c.plan_done) this.Vyto_plan(w)
    if (!w.c.commission) return w.i({ see: '⏳ awaiting commission' })
    w.i({ see: `🫧 stir:${w.c.stir_n ?? 0} yore:${w.c.yore_n ?? 0}` })

// Vyto_plan — stand the furniture: register the render side (Vytui mounts off the UIs
//  registry like every panel) and mint the board so the vocabulary is VISIBLE before any
//   cell is ever drawn.
Vyto_plan(w):
    let uis = this.oai_enroll(this, { watched: 'UIs' })
    uis.oai({ UI: 'Vyto' }, { component: Vytui })
    this.Vyto_board(w)
    w.c.plan_done = 1
//#endregion

//#region the board — the glass handled (spec §9): the bar of one-word toggles + the organ panel
// Vyto_board — mint the organ registry and the bar words as particles in w:Vyto, so the
//  panel is "the machine seen in its own matter" from day one.  Each organ row carries its
//   one-sentence guts (reads → decides → writes) as separate sc keys — the panel renders
//    the sentence from them, and no sc value ever needs a comma.  status:stub until the
//     organ's real body lands; the row is the organ's public face.
//  Four families: solvers place — governors permit — scribes translate — chroniclers capture.
Vyto_board(w):
    w.oai({ Organ: 'Scan',    family: 'chronicler', reads: 'the grappled worlds',      writes: 'the mirror',                       status: 'stub' })
    w.oai({ Organ: 'Fold',    family: 'solver',     reads: 'the mirror',               decides: 'which subtrees become one cell',  status: 'stub' })
    w.oai({ Organ: 'Gang',    family: 'solver',     reads: 'a crowded sibling row',    decides: 'who represents whom',             status: 'stub' })
    w.oai({ Organ: 'Slope',   family: 'solver',     reads: 'a weight',                 writes: 'a position — and back',            status: 'stub' })
    w.oai({ Organ: 'Mesh',    family: 'solver',     reads: 'a family',                 writes: 'a dot-body with a spine',          status: 'stub' })
    w.oai({ Organ: 'Calm',    family: 'governor',   reads: 'everything in flight',     decides: 'what may move',                   status: 'stub' })
    w.oai({ Organ: 'Focus',   family: 'governor',   reads: 'attention',                decides: 'what matters now',                status: 'stub' })
    w.oai({ Organ: 'Relate',  family: 'scribe',     reads: 'meaning',                  writes: 'flow edges',                       status: 'stub' })
    w.oai({ Organ: 'Express', family: 'scribe',     reads: 'quantities',               writes: 'channels',                         status: 'stub' })
    w.oai({ Organ: 'Spool',   family: 'chronicler', reads: 'settles',                  writes: 'moments',                          status: 'stub' })
    // the bar — about seven buttons; each is one coherent word toggling one visible doctrine.
    //  The rule that keeps the bar honest: a toggle that cannot earn a single dictionary word
    //   cannot be on the bar.  `on` rides as 1-or-absent (the snapped-boolean law — habit even
    //    off-snap).  `o` is an ACT not a toggle: it o-marks the newest moment (spec §8).
    w.oai({ Bar: 'live',   doctrine: 'follow the newest settle — or park' }, { on: 1 })
    w.oai({ Bar: 'depths', doctrine: 'this scope as notation rows instead of space' })
    w.oai({ Bar: 'flows',  doctrine: 'show or hush the loud edge caste' })
    w.oai({ Bar: 'frames', doctrine: 'show or hush the quiet one' })
    w.oai({ Bar: 'holds',  doctrine: 'paint every Hold and who placed it' })
    w.oai({ Bar: 'pelt',   doctrine: 'comb the hair-field visible' })
    w.oai({ Bar: 'o',      doctrine: 'we saw it — keep this moment', kind: 'act' })
//#endregion

//#region the commission and the grapple (spec §10) — owned by the RUN, watched at the GEAR
// e_Vyto_commission — the one door in.  sc shape v1: Scannable | recipe, Styles, client_w,
//  grapples (optional explicit list of source Cs to watch — refs ride the req like Cyto's
//   Scannable does).  The commission stands with the Run House and lives as long as the
//    world; Story is a SEEK CLIENT, never the owner.
e_Vyto_commission(A, w, e):
    let req = e?.sc.req
    if (!req) return w.i({ error: 'Vyto_commission: !req' })
    if (!w.c.plan_done) this.Vyto_plan(w)
    // v1 refusal — loud, so a mis-ported client learns at the seam, not from silence
    if (req.sc.supports_takeTurns || req.sc.wants_wave_done || req.sc.wants_animation_done) {
        w.i({ rebuff: 'Vyto refuses ceremony on the commission — ceremony rides the request' })
    }
    w.c.commission = req
    // the ONE timing constant (calm.md §8: one constant, one default — never the 0.4/0.3
    //  split the current glass fell into).  §5's spring ω derives from it (ω = 6/grawave).
    w.sc.grawave_duration ??= 0.4
    // Calm's home — a detached _C hanging off `.c`, unreachable from H** so the whole Hold
    //  tree never snaps (calm.md §1: Books stay glass-blind by construction, not discipline).
    //   The mirror's detached-mint precedent; %Hold rows live under here.
    if (!w.c.calm) w.c.calm = new TheC({ c: {}, sc: { Calm: 1 } })
    w.c.Scannable  = req.sc.Scannable
    w.c.Styles     = req.sc.Styles
    w.c.client_w   = req.sc.client_w
    // ④+⑤ opt-in (Vyto_sizing_todo §9): a PRICED glass sizes cells by the ONE global scale (see
    //  Vyto_express) instead of the absolute dose box.  Read afresh every commission, so a
    //   re-commission can flip a world priced or plain.  Default OFF ⇒ every existing commission
    //    keeps the byte-identical local cut (the studies' warp discipline — no fixture moves).
    w.c.priced     = req.sc.priced ? 1 : 0
    // NESTED opt-in (Vyto_sizing_todo J4 · Nestcut proven): a nested glass recurses the cut into every
    //  scope — a cluster of UI bits is a scope whose children solve INSIDE its cell.  Default off ⇒ the
    //   flat top-only cut every existing Book stands on, byte-identical.
    w.c.nested     = req.sc.nested ? 1 : 0
    // FOLDED opt-in: a folded glass crushes a crowded scope to its budget (Vyto_fold).  Default off ⇒
    //  every cell drawn as-is, byte-identical.  The three flags compose (priced sizes · nested recurses
    //   · folded crushes) but each is independently gated.
    w.c.folded     = req.sc.folded ? 1 : 0
    // NEED-FLOOR opt-in (Vyto_todo THE PIN P2 — the measure seam, Cytui:3256 ported): the render
    //  measures each leaf widget's natural box and stamps row.c.need_area; Vyto_express then FLOORS
    //   env_area at need·1.15, so no cell is ever smaller than the box its widget was measured to
    //    need.  Importance still ranks ABOVE the floor.  Default off ⇒ the algebra alone — and the
    //     render skips the measure entirely — byte-identical.
    w.c.need_floor = req.sc.need_floor ? 1 : 0
    // FOAM opt-in (Vyto_todo "THE ORCHESTRA OF SPHERES"): coverage earned by pressure — the render
    //  cuts foam_cells (each cell = its own disc trimmed only where discs press) instead of carving
    //   the whole frame.  Renderer-side law; the solve is unchanged for now (its seeds/radii feed
    //    both cuts).  Default off ⇒ every existing commission keeps the byte-identical frame cut.
    w.c.foam       = req.sc.foam ? 1 : 0
    // DEPTH-SCALE opt-in (Vyto_todo THE PIN P3): a nested scope's child radii scale by √(parent cell
    //  area / frame area) instead of staying frame-absolute — fixes crowd-out in a small parent cell
    //   (VytoDepth proves it).  Default off ⇒ Vyto_solve_scope's depth_k is 1 (no-op), so every
    //    EXISTING nested Book (VytoNestRest predates P3) keeps its byte-identical recorded geometry.
    w.c.depth_scale = req.sc.depth_scale ? 1 : 0
    // FOAMEREO — the composer's deck (`foamereo:'room,seal,copperless'`), carried from the commission
    //  onto the world's OWN sc so the model (Vyto_fo) and the render (Vytui's fo) read one key from one
    //   place.  It rides sc rather than .c on purpose: a composer's declaration is worth SEEING in a
    //    snap, and it is the one piece of the glass a Book may legitimately state about itself.
    //  GUARDED — an unset commission writes NOTHING.  Assigning `req.sc.foamereo` unconditionally would
    //   stamp `undefined` into sc and the encoder would faithfully brand the line `{"undef":["foamereo"]}`,
    //    which is a mint bug, not furniture.  So every existing world stays byte-identical.
    if (req.sc.foamereo) w.sc.foamereo = req.sc.foamereo
    // PLAIN — the commissioner is handing over particles with no faces behind them, so the glass
    //  should draw the C** itself (bare's typographic set) instead of leaving quiet frames waiting
    //   for components that will never mount.  Same carry as foamereo: a capture can read it.
    if (req.sc.plain) w.sc.plain = req.sc.plain
    // the commissioning client supplies the Run House on the req's `.c` (a ref — never sc); the
    //  Spool reads it to snap the RUN world into each moment's payload (spool.md §2).
    w.c.Run        = e?.c?.Run ?? req.c?.Run ?? null
    if (w.c.Styles) {
        let ave = this.oai_enroll(this, { watched: 'ave' })
        ave.i(w.c.Styles)
    }
    this.Vyto_grapples(w, req)
    this.Vyto_watch(w)
    w.i({ see: `📡 commissioned by ${w.c.client_w?.sc.w ?? '?'} — ${w.c.grapples.length} grapple(s)` })

// Vyto_grapples — derive the watch set.  watch_c(Scannable) was aimed one joint too high:
//  the state that FEEDS the Scannable lives in bits of gear (stokers, lineups, piers,
//   ledgers) and the Scannable is assembled from them.  So: an explicit list wins; the
//    RECIPE form (IOexprs assembling in the Sunpit, grapples derived transitively — "a
//     grapple on what it has a grapple on") is the next milestone (workingouts/commission.md);
//      the degenerate default — watch the Scannable itself — still beats today's nothing.
Vyto_grapples(w, req):
    let list = req.sc.grapples
    if (!list || !list.length) list = [req.sc.Scannable]
    w.c.grapples = list.filter(Boolean)

// Vyto_watch — THE DRIVE.  watch_c every grapple; the House's watched-flush fires handlers
//  after beliefs settles — but ONCE PER CHANGED C, not once per burst, and under a fresh
//   mutex hold (workingouts/commission.md, checked against Housing) — so Vyto adds its OWN
//    trailing-edge latch (Vyto_stir_soon) to fold N grapple bumps into one stir.  watch_c
//     now dedups per (C, OWNER): a re-commission over the same gear is idempotent, and a grapple on
//      a C another ghost already watches coexists (the era-guarded multi-handler landed in Housing —
//       Vyto_todo §0), with teardown-on-decommission via Vyto_decommission (unwatch_owner).
Vyto_watch(w):
    // OWNER-KEYED by w (the glass world): watch_c now carries an owner, so this grapple watch coexists
    //  with any OTHER ghost already watching the same C (the old dedup-by-C silently dropped us — the
    //   Radio agent's resident integration would have hit that first), and Vyto_decommission tears
    //    exactly these handlers down by that owner.  Re-commission stays idempotent (same (C, w) dedups).
    for (const g of w.c.grapples ?? []) {
        this.watch_c(g, () => this.Vyto_stir_soon(w), w)
    }

// Vyto_decommission — the teardown seam (was owed on Vyto_todo).  Stand the glass down: drop every
//  grapple watch it placed (owner = w), era-guarded by Housing.unwatch_owner so a stir can never
//   fire again after this, and mark the world decommissioned.  `this` is the House the watches live
//    on (the commissioner's House — the same `this` Vyto_watch ran under), so a client tears down via
//     <that House>.Vyto_decommission(w).  A later re-commission re-watches fresh.
Vyto_decommission(w):
    this.unwatch_owner(w)
    w.c.grapples = []
    w.c.decommissioned = 1

// Vyto_stir_soon — the coalescing latch: first bump arms it, the rest of the burst rides
//  free, and the stir itself runs through clear() — off the flush's own mutex hold, in a
//   quiet moment of its own.
Vyto_stir_soon(w):
    if (w.c.stir_pending) return
    w.c.stir_pending = 1
    setTimeout(() => this.clear(() => { w.c.stir_pending = 0; this.Vyto_stir(w) }), 0)

// Vyto_stir — where every grapple bump lands, coalesced.  The future body is the organ
//  chain in station order: Scan → Fold → Gang → (Slope | Mesh where a scope asks) → Relate
//   → Express — with Calm and Focus consulted throughout and Spool capturing at settle.
//    Today it walks the stations as stubs, so the ORDER is in the workings too.
Vyto_stir(w):
    w.c.stir_n = (w.c.stir_n ?? 0) + 1
    this.Vyto_scan(w)
    this.Vyto_fold(w)
    this.Vyto_gang(w)
    this.Vyto_relate(w)
    this.Vyto_express(w)
    this.Vyto_solve(w)

// Vyto_sunpit — the staging pit where a recipe's IOexprs pour in and assemble the
//  Scannable.  Milestone 2; the recipe grammar and the transitive grapple derivation are
//   worked out in vyto_workingouts/commission.md.
Vyto_sunpit(w, recipe):
    return null
//#endregion

//#region the organs — named stubs; each carries its sentence (reads → decides → writes)
// Vyto_scan — chronicler: reads the grappled worlds and writes the mirror.  The mirror is
//  a graph MIRROR (the CytoStep lesson) — never world C**; display-only time travel falls
//   out free because the spool archives mirrors.
Vyto_scan(w):
    // TASK 2 — read grapples defensively: a world with no grapple set is a no-op, never a
    //  throw (a commission may stand before its gear does).
    let grapples = w.c.grapples
    if (!grapples || !grapples.length) return
    // The mirror lives DETACHED on `.c` (the CytoStep `_C({cyto_root})` precedent — a root C
    //  minted off the H tree): reachable from nothing in H**, so it never snaps and the Books
    //   stay Vyto-blind, and it holds a graph MIRROR of scalar reflections, never world C**
    //    refs woven into sc.  Detached-mint chosen over an attached holder-row precisely so no
    //     mainkey has to be reserved fleet-wide.
    if (!w.c.mirror) w.c.mirror = new TheC({ c: {}, sc: { mirror: 1 } })
    // one generation per scan — every row Scan touches is stamped `seen_at:gen`; the sweep
    //  reads that stamp to find the rows whose source has vanished.
    let gen = w.c.scan_gen = (w.c.scan_gen ?? 0) + 1
    for (const g of grapples) this.Vyto_scan_walk(w, g, w.c.mirror, 0, gen)
    this.Vyto_scan_sweep(w, w.c.mirror, gen)
    // the organ goes live the first time it actually writes the mirror — the board row is the
    //  organ's public face (spec §9), stub until its body lands.
    let organ = w.o({ Organ: 'Scan' })[0]
    if (organ && organ.sc.status !== 'live') {
        organ.sc.status = 'live'
        organ.bump_version()
    }

// Vyto_scan_walk — the subtree walk, PLAIN recursion (the .g compiler parse-storms on
//  closure-heavy helpers): mirror the source particle n under parentMirror, then descend into
//   its children.  Identity is DETERMINISTIC (spool.md §5.4 — the replay claim depends on it):
//    a row is a stable function of the source's line identity, so the SAME source maps to the
//     SAME row across stirs and a value change morphs a row in place rather than minting a new
//      cell (which cyto_assign_ids' per-walk counter could never promise).
Vyto_scan_walk(w, n, parentMirror, depth, gen):
    if (!n || !n.sc) return
    let mk = this.mainkey(n)
    if (!mk) return
    // The identity token = mainkey + its value + the recognised structural JOIN keys (id of pub
    //  page seq — the flock joins CLAUDE.md and Ra.g name, plus the Cloud page).  Express-style
    //   VALUE channels (dose weight fresh hue z area …) are deliberately EXCLUDED so a quantity
    //    change reuses the same row (a morph) instead of re-keying it (a false leave+enter).
    //     Ancestry is STRUCTURAL — the row sits under its parent's mirror row — so the token is
    //      only the LOCAL identity; two byte-identical siblings collapse to one cell, which the
    //       spec accepts as visually interchangeable.  This join set is Scan's v1 identity
    //        vocabulary — the future Scan workingout refines the identity|value split.
    let mkVal = n.sc[mk]
    let scalarish = mkVal != null && typeof mkVal !== 'object' && typeof mkVal !== 'function' && typeof mkVal !== 'boolean'
    let nmk = scalarish ? mkVal : 1
    let tok = mk + ':' + nmk
    let joins = ['id', 'of', 'pub', 'page', 'seq']
    for (const k of joins) {
        if (n.sc[k] != null) tok = tok + '|' + k + ':' + n.sc[k]
    }
    // find-or-create by the token on `.c` (a string compare) — NOT an sc query, whose numeric-1
    //  values wildcard ({seq:1} matches any seq) and would merge distinct siblings.
    let row = parentMirror.o().find(r => r.c.tok === tok)
    if (!row) {
        // DIAGNOSTIC (2026-07-30, chasing the KeepFace mount/destroy thrash — see
        //  Download_stall_handover.md "Evening 8"): a Keep should mint its mirror row ONCE and then be
        //   FOUND every later scan by the same tok. Repeated minting for the same title means the tok
        //    (or the row itself) isn't surviving between scans — the actual remount mechanism, not
        //     component-local state. Gated to Keep only — every other mainkey stays silent.
        if (mk === 'Heist') console.log('◈ Vyto mirror MINT (no existing row matched)', tok, 'gen', gen)
        let seed = {}
        seed[mk] = nmk
        row = parentMirror.i(seed)
    }
    row.c.tok = tok
    row.c.source_n = n     // the Cyto source_n backlink — rides .c so there is no encode cost
    row.c.seen_at = gen
    // copy the source's scalar sc faithfully, comparing BEFORE writing so nothing churns; guard
    //  every value — an object|function in sc is fatal at encode, an undefined brands an `undef`
    //   marker (a mint bug), a boolean rides as 1-or-absent.
    let changed = 0
    let desired = {}
    for (const k of Object.keys(n.sc)) {
        let v = n.sc[k]
        if (v === undefined) continue
        let t = typeof v
        if (t === 'object' || t === 'function') continue
        if (t === 'boolean') {
            if (v) desired[k] = 1
            continue
        }
        desired[k] = v
    }
    desired[mk] = nmk    // the mainkey line is identity — kept faithful and never swept below
    for (const k of Object.keys(desired)) {
        if (row.sc[k] !== desired[k]) { row.sc[k] = desired[k]; changed = 1 }
    }
    for (const k of Object.keys(row.sc)) {
        // `departing` is mirror-managed (the escort mark) — never a source key, so leave it here
        if (k === 'departing') continue
        if (desired[k] === undefined) { delete row.sc[k]; changed = 1 }
    }
    // a source that vanished and came back sheds its escort (prefer the tracked path — bare
    //  delete of an sc key is query+snap safe, and this row never reaches a real snap anyway).
    if (row.sc.departing) { delete row.sc.departing; changed = 1 }
    if (changed) row.bump_version()
    // A FLAT GRAPPLE KEEPS ITS GUTS (the owner 2026-08-09: *"there's this `Heist:9.the one they
    //  play...` thing which is odd, has some Supervisor facts, I don't want to show most users
    //   that"*).  Nesting turns every child of every grapple into a visible subcell, and some
    //    grapples carry WORKINGS rather than contents — the heist flow organ's constraint/Lead/
    //     filing rows, supervision facts, and the like.  Those were never meant to be looked at;
    //      they became cells only because the glass learned to descend.
    //  So the COMMISSIONER decides, not the renderer: a source wearing `.c.flat` is mirrored as
    //   itself and its children are not walked.  It rides `.c` (a runtime mark, never encoded, so
    //    it can sit on a real persisted particle like %Caper without touching its snap), and a
    //     source that does not wear it walks exactly as before — so no fixture can move.
    //  This is the right seam for it: what a thing shows is a property of the thing, not a rule the
    //   display invents per mainkey.
    if (depth < 40 && !n.c.flat) {
        for (const c of n.o()) this.Vyto_scan_walk(w, c, row, depth + 1, gen)
    }

// Vyto_scan_sweep — departures.  A mirror row NOT stamped this generation has lost its source.
//  The human blessed departure escorts (calm.md §9.1 2026-07-20), so a vanished row is NOT
//   dropped on first sight — it stays alive one grace scan wearing `departing:1` so an escort
//    can draw its exit arc.  A row STILL missing on the next scan (already `departing`) has had
//     its two-stir grace and drops mirror-side (parentMirror.drop bumps the parent so a watcher
//      sees the ring shrink).  Recurse first so a whole vanished subtree escorts leaf-up.
Vyto_scan_sweep(w, parentMirror, gen):
    for (const row of parentMirror.o()) {
        this.Vyto_scan_sweep(w, row, gen)
        if (row.c.seen_at === gen) continue
        // DIAGNOSTIC twin of the MINT log above — a Keep row missed this scan (its source wasn't
        //  re-walked): first miss marks departing, second miss (still departing) actually drops it.
        if (String(row.c.tok || '').indexOf('Heist:') === 0) {
            console.log(row.sc.departing ? '◈ Vyto mirror DROP (missed 2nd scan)' : '◈ Vyto mirror DEPART (missed this scan)', row.c.tok, 'gen', gen)
        }
        if (row.sc.departing) {
            parentMirror.drop(row)
        } else {
            row.sc.departing = 1
            // a departing cell is usually one the user just CLOSED — the pointer is still on it,
            //  and its own hover pin would hold the corpse in place through the whole grace scan.
            this.Vyto_calm_yield(w, row.c.tok)
            row.bump_version()
        }
    }

// Vyto_fold — solver: reads the mirror and decides which subtrees become one cell.  This
//  is Voro.g's crush knowledge re-homed (intensity governor, rosette nucleus); the fold
//   ITSELF stays in Voro.g until the moult's first tenant proves the seam.  The decision
//   core it will call already stands PURE in vyto_foam.ts — budget_for (the glass sets the
//    cell count) + fold_ladder (OPEN → BUCKETED → CRUSHED, tightest first, focus shielded) —
//     gate-proven in the foam studies; this stub stays until the display refactor (which owns
//      that half) lands the mirror-side wiring.
// TENANTED 2026-07-27 (the grant executed): a PRICED-style opt-in `w.c.folded` glass crushes a
//  crowded scope so a big tree stays legible (Voro's signature rosette, matched).  The decision uses
//   the pure `budget_for` (how many cells the frame affords) + `bucket_key_of` (which key partitions
//    the crowd) + the re-homed distiller (`Vyto_distil` mints the crest with its counted dip).  Default
//     off ⇒ a plain glass never crushes and every existing fixture stands byte-identical.
Vyto_fold(w):
    if (!w.c.mirror) return
    if (!w.c.folded) return
    this.Vyto_fold_scope(w, w.c.mirror)
    let organ = w.o({ Organ: 'Fold' })[0]
    if (organ && organ.sc.status !== 'live') {
        organ.sc.status = 'live'
        organ.bump_version()
    }

// Vyto_fold_scope — crush a crowded scope into legible cells.  If its source members exceed the
//  frame's budget, elect the partitioning key and distil each ≥2 group into ONE crest cell carrying
//   its counted dip; singletons stay open.  The scope then renders at most (groups + singletons)
//    cells instead of N specks.  RE-DERIVED every stir but STABLE: a crest is found-or-created by its
//     `of` group tok (so its seed persists and Solve rests it), refilled only when its group count
//      changes, and stamped `seen_at = scan_gen` so Scan's sweep keeps it (a group that stops
//       qualifying has its crest dropped — un-crush).  Members of a crushed group wear `.c.folded`
//        and lose their `.c.T`, so Solve skips them and the renderer never springs them.
Vyto_fold_scope(w, scope):
    let all = scope.o()
    let members = all.filter(r => !r.sc.departing && r.sc.Vtuffing == null)
    for (const m of members) { if (m.c.folded) { m.c.folded = 0; m.c.T = null; m.bump_version() } }
    // DELIBERATELY STILL 800×450, unlike Vyto_solve's frame (which now follows w.c.vw_frame — see
    //  the note there).  This is a legibility BUDGET — how many cells fit before they read as specks —
    //   and it is a function of the frame's AREA, which barely moves when the aspect does (800×450 =
    //    360000 vs a portrait 446×800 = 356800, under 1%).  Making it follow the live frame would put
    //     the fold/un-fold threshold on the tab's geometry for well under a percent of signal, and a
    //      cell crossing that threshold CRUSHES or UNCRUSHES a whole group — a far bigger visual event
    //       than the thing it would be tracking.  Not measured; reasoned from the arithmetic above.
    let budget = budget_for(800, 450)
    let groups = {}
    if (members.length > budget) {
        let key = bucket_key_of(members.map(m => m.sc))
        if (key) {
            for (const m of members) {
                if (m.sc[key] == null) continue
                let ofk = key + '=' + m.sc[key]
                if (!groups[ofk]) groups[ofk] = []
                groups[ofk].push(m)
            }
        }
    }
    for (const c of all) {
        if (c.sc.Vtuffing == null) continue
        let g = groups[c.sc.of]
        if (!g || g.length < 2) scope.drop(c)
    }
    for (const ofk of Object.keys(groups)) {
        let grp = groups[ofk]
        if (grp.length < 2) continue
        let crest = scope.o({ Vtuffing: 1, of: ofk })[0]
        if (!crest) {
            crest = this.Vyto_distil(scope, grp, ofk, [], 0)
        } else if (crest.sc.n !== grp.length) {
            for (const vr of crest.o()) crest.drop(vr)
            crest.sc.n = grp.length
            this.Vyto_distil_fill(crest, grp, [], 0)
        }
        crest.c.seen_at = w.c.scan_gen
        if (crest.sc.dose !== '' + grp.length) { crest.sc.dose = '' + grp.length; crest.bump_version() }
        for (const m of grp) { if (!m.c.folded) { m.c.folded = 1; m.c.T = null; m.bump_version() } }
    }

// ══ the fold's toolbox — the FIRST TENANT (granted 2026-07-22): the distiller re-homed ════════════
//  The algebra the crush speaks (Voronation Stuff region = the Book-proven oracle) now LIVES at the
//   fold station — verbatim: veins first · keyrows supersede the facts a vein crosses unless the
//    coexist knob keeps them · counted chips · honest +N tail · counted presence.  PLUS the law the
//     oracle predates — Dip_assign (Cstructures_todo §4): every act of supersession assigns a
//      countable door.  The crest's FIRST row is `%Vrow,row:dip` carrying `n` (the true subsumed
//       count — Readback proved a crest without its count renders a family like a lie; same shape
//        as Voro.g's surf handle) and `.c.members` (the way back in — runtime refs · never
//         encoded).  Two mints: `Vyto_distil` ATTACHES (a Book snaps it as proof) and
//          `Vyto_distil_free` mints DETACHED (new TheC · unreachable from H** · Books-invisible —
//           the display side's working matter).  `Vyto_fold` above stays a stub until the
//            mirror-side solver lands (the display refactor owns that half); these are its tools.
Vyto_distil(into, members, kind, skips, coexist):
    let root = into.i({ Vtuffing: 1, of: kind || 'stuff', n: members ? members.length : 0 })
    return this.Vyto_distil_fill(root, members, skips, coexist)

Vyto_distil_free(members, kind, skips, coexist):
    let root = new TheC({ c: {}, sc: { Vtuffing: 1, of: kind || 'stuff', n: members ? members.length : 0 } })
    return this.Vyto_distil_fill(root, members, skips, coexist)

Vyto_distil_fill(root, members, skips, coexist):
    this.Vyto_dip_assign(root, members)
    if (!members || !members.length) return root
    let veined = this.Vyto_veinrows(root, members, skips)
    let hide = coexist ? null : veined
    this.Vyto_keyrows(root, members, skips, hide)
    return root

// Vyto_dip_assign — the Dip_assign law as a method: the door rides FIRST with the true count and
//  the members on `.c` (the dip a surf opens; the count present at EVERY register — injectivity).
Vyto_dip_assign(root, members):
    let dip = root.i({ Vrow: 1, row: 'dip', n: members ? members.length : 0 })
    dip.c.members = members ? members.slice() : []
    return dip

// Vyto_veinrows — one value crossing many keys is a VEIN said once (the oracle's ruling: a vein
//  SUPERSEDES the per-key facts it subsumes unless coexist keeps them; wgt:1; '1' never a vein).
Vyto_veinrows(root, members, skips):
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

// Vyto_keyrows — the key-by-key pass: ONE value → a fact said once (a bare '1' → a COUNTED
//  presence fact when some-not-all carry it) · MANY → a counted ranked spread capped at 3 + '+N'.
Vyto_keyrows(root, members, skips, hide):
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

// Vyto_gang — solver: reads a crowded sibling row and decides who represents whom.  The election
//  (vyto_foam.bucket_key_of, the foam studies' gate-proven chooser) picks the sc key that PARTITIONS
//   the row — present in the most members, 2..n−1 distinct values, coarsest wins ties — so K
//    aggregate representatives could stand for N members.  v1 scope matches Vyto_solve: the ONE
//     root sibling row.  The DECISION is the write — `w.c.gang_key` + each row's `.c.gang_v` (its
//      group under that key) — all `.c` matter (an sc write would be swept by the next scan).  An
//       uncrowded row (≤ 6 — the foam crowding law) needs no representative and clears the key.
Vyto_gang(w):
    if (!w.c.mirror) return
    let members = w.c.mirror.o().filter(r => !r.sc.departing)
    if (members.length <= 6) { w.c.gang_key = null; return }
    let key = bucket_key_of(members.map(m => m.sc))
    w.c.gang_key = key
    if (!key) return
    for (const m of members) {
        m.c.gang_v = (m.sc[key] != null) ? '' + m.sc[key] : null
    }
    let organ = w.o({ Organ: 'Gang' })[0]
    if (organ && organ.sc.status !== 'live') {
        organ.sc.status = 'live'
        organ.bump_version()
    }

// Vyto_slope — solver: reads a weight and writes a position — and reads the position back
//  as the weight.  Meaning-owned geometry (spec §6): dragging a Mag up the slope WRITES
//   the selection weight; arranging the queue is playing it.
Vyto_slope(w, scope):
    return

// Vyto_mesh — solver: reads a family and writes a dot-body with a spine (the organ-body
//  look).  The spine is the pelt's strongest streamline (workingouts/pelt.md).
Vyto_mesh(w, scope):
    return

// Vyto_calm_held — governor Calm's one public question, per (cell, channel): how much may
//  this move THIS frame?  The %Hold algebra (calm.md §2) — walk the Hold rows whose scope
//   is this cell's tok and which claim the channel (or `all`); each contributes a strength
//    in [0,1]; a live PIN short-circuits to 0 (nothing moves), otherwise damps STACK
//     multiplicatively (order-free, k → 0 is pin's limit).  A released hold eases its
//      strength toward 1 along the cubic tail (§4) so releases are continuous by arithmetic.
//   Returns the NUMBER k — 0 pinned, 1 free, damped between (the renderer scales the spring's
//    ω by it).  cell may be a mirror ROW or a tok STRING.  (Contract change from the skeleton,
//     which returned 0 meaning "not held": k is now the strength, 1 = free.  This ghost is the
//      only caller of the method as a solve-time pin probe; the renderer is the other caller.)
Vyto_calm_held(w, cell, channel):
    if (!w.c.calm) return 1
    let tok = (typeof cell === 'string') ? cell : cell?.c?.tok
    if (!tok) return 1
    let now = Date.now()
    let k = 1
    for (const h of w.c.calm.o({ Hold: 1 })) {
        if (h.sc.scope !== tok) continue
        if (!(h.sc[channel] || h.sc.all)) continue
        let s = this.Vyto_strength_now(w, h, now)
        if (s === 0) return 0
        k = k * s
    }
    return k

// Vyto_strength_now — one hold's live strength (calm.md §2 strength_now).  base = 0 for a
//  pin, its damp value otherwise; while live that base stands; once released_at is stamped it
//   eases base → 1 along a cubic ease-out over ease_ms, and when the tail completes (u ≥ 1) the
//    row RETIRES (dropped from w.c.calm — the .o() snapshot makes the mid-walk drop safe).
Vyto_strength_now(w, h, now):
    // A MALFORMED ROW MUST NOT BE A PERMANENT PIN (Vyto_todo §0.2(b), 2026-08-08).  This read was
    //  `Number(h.sc.damp) || 0`, so a %Hold with neither `pin` nor `damp` — or a garbage damp —
    //   silently returned 0, the strongest hold there is, forever.  Absent|NaN now reads FREE (1):
    //    the honest default for a row that never said what it wants.  A CONFIGURED damp:0 still
    //     holds fully — `== null` distinguishes absent from zero, which `||` cannot.
    let d = Number(h.sc.damp)
    let base = h.sc.pin ? 0 : (h.sc.damp == null || !isFinite(d) ? 1 : d)
    if (h.sc.released_at == null) return base
    let ease = Number(h.sc.ease_ms) || 1
    let u = (now - Number(h.sc.released_at)) / ease
    if (u < 0) u = 0
    if (u > 1) u = 1
    if (u >= 1) {
        w.c.calm.drop(h)
        return 1
    }
    let inv = 1 - u
    return base + (1 - base) * (1 - inv * inv * inv)

// Vyto_mirror_find — the mirror row bearing this tok, PLAIN recursion (the .g compiler
//  parse-storms on closure-heavy helpers) — Vytui hands Calm a tok, never a row.
Vyto_mirror_find(w, tok):
    if (!w.c.mirror) return null
    return this.Vyto_mirror_find_in(w.c.mirror, tok)

Vyto_mirror_find_in(parent, tok):
    for (const r of parent.o()) {
        if (r.c.tok === tok) return r
        let found = this.Vyto_mirror_find_in(r, tok)
        if (found) return found
    }
    return null

// Vyto_pointer_enter — Vytui owns the pointer facts (cells are real DOM now); on enter it
//  pokes Calm, which mints TWO rows on the entered cell (calm.md §1/§3): the seed POSITION
//   PINNED so the tessellation solves with it fixed and the world rearranges around it, plus
//    the SIZE DAMPED at 0.3 so the boundary follows sluggishly.  Booleans ride 1-or-absent.
Vyto_pointer_enter(w, tok):
    if (!tok) return
    if (!w.c.calm) w.c.calm = new TheC({ c: {}, sc: { Calm: 1 } })
    // `oai`, NOT `i` (2026-08-08).  `i()` MINTS UNCONDITIONALLY, so every pointerenter on the same
    //  cell added two more identical %Hold rows.  They are retired only by `Vyto_pointer_leave`, which
    //   depends on the browser delivering `pointerleave` — and a keyed re-mint of the <path> under the
    //    pointer (exactly the churn this glass does constantly) can swallow that event. So the pile
    //     grew without bound for the life of the tab, and every one of them was then re-read by
    //      `Vyto_calm_held`, which runs a real o({Hold:1}) query per cell per channel per frame.
    //  Find-or-create is the correct shape regardless: entering a cell you are already on is not a
    //   second hold, it is the same hold. Duplicates never changed the VERDICT (any pin wins), so this
    //    is a cost and a leak, not a behaviour change — the pin still lands on the first enter.
    w.c.calm.oai({ Hold: 1, scope: tok, position: 1, pin: 1, while: 'pointer', by: 'Calm' })
    // SIZE IS PINNED UNDER THE POINTER, NOT DAMPED (2026-08-09, the owner: "when we mouse over a cell,
    //  it cannot move under us!").  `damp: 0.3` still let the cell resize while pointed at, just more
    //   slowly — and a cell that resizes moves its own wall under the cursor and shoves its neighbours.
    //    "Slower" is not the rule; the rule is STILL.  Position was already pinned; size now matches.
    w.c.calm.oai({ Hold: 1, scope: tok, size: 1, pin: 1, while: 'pointer', by: 'Calm' })
    w.c.pointer = tok
    // flip the Calm organ row live on first mint (the Scan/Express flip idiom — the board row
    //  is the organ's public face, stub until its body first fires).
    let organ = w.o({ Organ: 'Calm' })[0]
    if (organ && organ.sc.status !== 'live') {
        organ.sc.status = 'live'
        organ.bump_version()
    }

// Vyto_pointer_leave — stamp every live pointer hold on this scope with released_at + ease_ms
//  (= grawave, so the release FEELS like one wave): strength then eases 0 → 1 along the tail and
//   the ex-hovered cell accelerates gently toward the standing target — un-hovering never snaps
//    because motion resumes at zero speed.  The row retires itself when the tail completes (§2).
Vyto_pointer_leave(w, tok):
    if (!w.c.calm) return
    let now = Date.now()
    let ease = (w.sc.grawave_duration ?? 0.4) * 1000
    for (const h of w.c.calm.o({ Hold: 1 })) {
        if (h.sc.while !== 'pointer') continue
        if (h.sc.scope !== tok) continue
        if (h.sc.released_at != null) continue
        h.sc.released_at = now
        h.sc.ease_ms = ease
        h.bump_version()
    }
    if (w.c.pointer === tok) w.c.pointer = null

// Vyto_calm_yield — a COMMANDED cell yields its pointer holds (2026-08-09, the owner: the staged
//  cell "pops into its final location" seconds late, and the close was little better).  The pin
//   exists so the world cannot squirm under a RESTING pointer — but a stage, an un-stage and a
//    departure are the user moving the cell themselves, and after a drag-release or a button
//     press the pointer is parked exactly on the commanded cell, so its own pin froze the very
//      motion just ordered until the mouse happened to wander off.  Release the holds NOW on a
//       short tail (continuous by the same §4 arithmetic as pointer_leave), and DO NOT touch
//        w.c.pointer — the pointer fact stays true, only its claim of stillness yields.  No new
//         pointerenter re-pins meanwhile: the pointer never crosses a boundary while the same
//          cell grows or shrinks beneath it.
Vyto_calm_yield(w, tok):
    if (!w.c.calm || tok == null) return
    let now = Date.now()
    for (const h of w.c.calm.o({ Hold: 1 })) {
        if (h.sc.while !== 'pointer') continue
        if (h.sc.scope !== tok) continue
        if (h.sc.released_at != null) continue
        h.sc.released_at = now
        h.sc.ease_ms = 150
        h.bump_version()
    }

// Vyto_hold — place a %Hold directly: a declared, composable claim of stillness under Calm's
//  home (the same detached tree the pointer holds ride, so the board's `holds` toggle paints
//   every claim uniformly).  Kept as the generic placer the shift/seek holds will grow into.
Vyto_hold(w, hold):
    if (!w.c.calm) w.c.calm = new TheC({ c: {}, sc: { Calm: 1 } })
    return w.c.calm.i(hold)

// Vyto_focus — governor: reads attention and decides what matters now.  A proposal names a tok
//  (or nothing — release); the governor STANDS the decision on w.c.focus_tok and stirs, and the
//   solver honors it as the foam taper: the focused member's power radius swells by FOCUS_BOOST,
//    every off-focus sibling compresses by FOCUS_SHRINK, so attention dominates through real
//     geometry.  No standing focus ⇒ every mag is 1 ⇒ the untouched base cut, byte-identical
//      (the studies' warp gate — existing fixtures never move).  The full SHIFT transaction
//       (collect → hold → choreograph → settle → moment, spec §4) rides this seam later;
//        Voro_drift becomes a client of this organ — it proposes, it never touches layout.
Vyto_focus(w, proposal):
    // NAME THE THING, NOT ITS TOKEN (2026-08-07).  A tok is an internal mirror coordinate — a client
    //  outside Vyto (the radio deciding it should dominate once music is playing) has no way to know
    //   one, and Vytonation only ever got its tok by reading Vyto_cells first.  So a proposal may name
    //    an `on:<mainkey>` instead and the governor resolves it here, against the same live cells.
    //  `tok` still wins when given, so every existing caller — and every recorded fixture — is untouched.
    let tok = proposal?.tok ?? null
    if (tok == null && proposal?.on && w.c.mirror) {
        for (const r of w.c.mirror.o()) {
            if (tok == null && !r.sc.departing && this.mainkey(r) === proposal.on) tok = r.c.tok
        }
    }
    w.c.focus_tok = tok ?? null
    let organ = w.o({ Organ: 'Focus' })[0]
    if (organ && organ.sc.status !== 'live') {
        organ.sc.status = 'live'
        organ.bump_version()
    }
    this.Vyto_stir_soon(w)

// e_Vyto_focus — the proposal door (the e_Vyto_commission idiom): a client anywhere dispatches
//  i_elvisto('Vyto/Vyto' 'Vyto_focus' {tok}) and the governor decides.  Story drives it the same
//   way a pointer or Voro_drift will.
e_Vyto_focus(A, w, e):
    this.Vyto_focus(w, e?.sc)

// Vyto_redraw — the RESHUFFLE verb (the owner 2026-08-09: "needs more redraw or keep running
//  layout buttons like cyto had").  Forget every unpinned seat; the next stir re-enters the
//   whole cast around the rim (the batch spread) and re-piles it — a fresh deal of the same
//    hand.  redraw_n salts the entry phase so each press actually deals DIFFERENTLY (same
//     press count ⇒ same deal: deterministic, solver law 4 — and redraw_n 0 leaves the entry
//      arithmetic byte-identical, so every recorded fixture stands).
Vyto_redraw(w):
    if (!w.c.mirror) return
    w.c.redraw_n = (w.c.redraw_n ?? 0) + 1
    this.Vyto_redraw_walk(w, w.c.mirror)
    this.Vyto_stir_soon(w)

Vyto_redraw_walk(w, n):
    for (const m of n.o()) {
        if (m.c.seed && this.Vyto_calm_held(w, m, 'position') !== 0) m.c.seed = null
        this.Vyto_redraw_walk(w, m)
    }

// Vyto_simmer_tick — one beat of KEEP-RUNNING LAYOUT (the second Cyto button).  A deterministic
//  per-tick jitter (counter-hashed, never Math.random — solver law 4 per tick count) nudges every
//   unpinned seat a few px, and the pile re-settles around the disturbance: the foam visibly keeps
//    negotiating.  The renderer's simmer toggle calls this on an interval — live pages only, so a
//     Book never sees it and no fixture can.
Vyto_simmer_tick(w):
    if (!w.c.mirror) return
    w.c.simmer_n = (w.c.simmer_n ?? 0) + 1
    this.Vyto_simmer_walk(w, w.c.mirror, w.c.simmer_n, 0)
    this.Vyto_stir_soon(w)

// Vyto_attend — the NAVIGATION|ATTENTION CURRENCY (the owner 2026-08-09: "cells need a
//  navigation|attention currency!").  Attention is EARNED by navigation — a hover pays a
//   little, a press pays more — and SELF-TAXING: attending one body decays every other,
//    so the total stays roughly conserved (a currency, not a counter) and the glass
//     re-centres on where the hands have actually been.  heat rides `.c` (runtime, never
//      snapped); express spends it as an env_area multiplier (1 + HEAT·0.8), so hot cells
//       swell and the pile renegotiates around the reader's own trail.  A Book never
//        navigates ⇒ heat stays 0 ⇒ every fixture byte-identical (the additive-gate law).
Vyto_attend(w, tok, amount):
    if (!w.c.mirror) return
    let amt = Number(amount) || 0.25
    this.Vyto_attend_walk(w, w.c.mirror, tok, amt)
    this.Vyto_stir_soon(w)

Vyto_attend_walk(w, n, tok, amt):
    for (const m of n.o()) {
        if (m.c.tok === tok) m.c.heat = Math.min(1, (m.c.heat ?? 0) + amt * (1 - (m.c.heat ?? 0)))
        // THE TAX IS PROPORTIONAL TO THE GRANT (2026-08-09) — *"how do we balance things in the
        //  user's face?"*  A flat ×0.96 meant a big grant and a glance cost the rest of the glass the
        //   same, so attention was not really SHARED: it was minted.  Taxing by the size of the grant
        //    makes it close to zero-sum — a deliberate press visibly cools everything else, a small
        //     brush barely does — which is what makes the pile rebalance rather than just inflate.
        //  Capped at 0.6 so one press can never wipe the board; recovery should still take a press.
        if (m.c.tok !== tok && m.c.heat) {
            m.c.heat = m.c.heat * (1 - Math.min(0.6, amt * 0.7))
            if (m.c.heat < 0.02) m.c.heat = 0
        }
        this.Vyto_attend_walk(w, m, tok, amt)
    }

// Vyto_even_toggle — flip the EQUAL POSE (see Vyto_express).  Runtime .c, one flip, one stir.
Vyto_even_toggle(w):
    let on = w.c.even ? 1 : 0
    delete w.c.even
    if (!on) w.c.even = 1
    this.Vyto_stir_soon(w)

// Vyto_compete_tick — THE COMPETITION (the owner: *"we need some simulation of them competing for
//  attention"*).  The attention currency already has everything this needs: heat is earned by being
//   attended, it is SELF-TAXING (every other body cools 4% per grant), and express spends it as size.
//    So a competition is not new machinery — it is just nobody being the reader.  Each tick hands the
//     coin to the next body in turn, everyone else pays the tax, and the foam visibly fights it out.
//  Deterministic (a counter, not a clock, and never Math.random) so a held pose repeats exactly; the
//   renderer runs it on an interval and only on a live page, so no Book can ever see a tick.
Vyto_compete_tick(w):
    if (!w.c.mirror) return
    let toks = []
    this.Vyto_compete_walk(w.c.mirror, toks)
    if (!toks.length) return
    let n = Number(w.c.compete_n ?? 0)
    this.Vyto_attend(w, toks[n % toks.length], 0.5)
    w.c.compete_n = n + 1

Vyto_compete_walk(n, toks):
    for (const m of n.o()) {
        if (m.c.tok) toks.push(m.c.tok)
        this.Vyto_compete_walk(m, toks)
    }

// ── THE STAGE ────────────────────────────────────────────────────────────────────────────────
//  Vyto_stage — name the one cell that gets the room, or clear the stage.  Dropping the cell that
//   is ALREADY staged un-stages it, so the same gesture is on and off and there is no second
//    control to find.  A tok that no longer exists simply lays out as no stage (stage_lay returns
//     0 and every other law runs as before), so a departing staged cell cannot strand the glass.
Vyto_stage(w, tok):
    let cur = w.c.stage_tok
    delete w.c.stage_tok
    if (tok != null && tok !== cur) w.c.stage_tok = tok
    // both the newly staged cell and the one leaving the stage were just COMMANDED — their hover
    //  pins must not freeze the growth/shrink they were ordered into (Vyto_calm_yield's note).
    this.Vyto_calm_yield(w, cur)
    this.Vyto_calm_yield(w, tok)
    this.Vyto_stir_soon(w)

// Vyto_stage_lay — DEAL the frame instead of solving it.  The staged body takes the left band's
//  heart; everyone else files down a right-hand column, alternating two x's so a long name has
//   somewhere to go and neighbours do not share a wall dead-on.  Every seed is pinned, so the
//    relax moves nothing and the same stage lays out identically every frame — which is the whole
//     point: a dealt layout cannot flap, and flapping is what "it's fond of re-laying-out" was.
//  Writes back to m.c.seed as well as the local array so the placement PERSISTS: un-stage later
//   and the pile resumes from where the deal left it rather than teleporting from stale seeds.
// Vyto_stage_tok — THE EFFECTIVE STAGE.  The human's drag always wins; failing that, the MODEL may
//  ask, by marking a source `.c.stage_want` (the owner 2026-08-09: *"We need to make sure Heist gets
//   into the focus zone, so our UI can have enough room"*).  A heist opening is the app saying "this
//    is what you are doing now", and it should not need a drag to get the room it needs.
//  Read through `source_n`, so the WANT lives on the real particle the commissioner owns rather than
//   on a mirror row the glass rebuilds — the mirror is a copy and must never be the place a decision
//    is stored.  Nothing wants the stage ⇒ null ⇒ every stage law is skipped, byte-invisibly.
Vyto_stage_tok(w, members):
    if (w.c.stage_tok != null) return w.c.stage_tok
    for (const m of members) {
        let src = m.c.source_n
        if (src && src.c && src.c.stage_want) return m.c.tok
    }
    return null

// Vyto_stage_lay — PLACE THE PRIMARY, TOUCH NOTHING ELSE (the owner 2026-08-09: *"we should keep the
//  cells clustered as they always were but just insist on the primary one being huge, off the edges
//   of the screen, on the left, the others small"*).
//  The first version DEALT the whole frame — primary left, everyone else pinned down a right-hand
//   column.  That threw away the one thing this glass actually has: bodies that cluster by
//    negotiation.  A dealt grid is just a list with extra steps, and it looked like one.
//  So the stage is now only a PRICE (Vyto_express: huge vs small) and a PLACE (this: the primary
//   pinned left of centre).  Every other seed is left completely alone — unpinned, piling as it
//    always did, now around a big neighbour instead of among equals.
//  Returns the primary's index so the caller can exempt it from the fit law: a staged cell is the
//   thing being LOOKED AT, not a thing being fitted, and it is allowed to run off the frame.
Vyto_stage_lay(w, members, seeds, radii, pinned, fw, fh, stok):
    let si = -1
    let i = 0
    while (i < members.length) {
        if (members[i].c.tok === stok) si = i
        i = i + 1
    }
    if (si < 0) return -1
    let sx = fw * 0.26
    let sy = fh * 0.5
    seeds[si] = { x: sx, y: sy }
    pinned[si] = true
    members[si].c.seed = { x: sx, y: sy }
    // sized FROM THE FRAME, not from the pricing algebra.  "Huge, off the edges" is a statement about
    //  the screen, so it is answered in screen terms — 0.62·min(fw,fh) is comfortably past the 0.44
    //   cap it is exempt from, which is what makes it run off rather than sit inside.  Expressing it
    //    as a multiple of AREA_BASE instead would make "does it overflow" depend on a constant tuned
    //     for something else entirely, and it would stop being true the moment that constant moved.
    radii[si] = 0.62 * Math.min(fw, fh)
    return si

Vyto_simmer_walk(w, n, tick, base):
    let i = base
    for (const m of n.o()) {
        if (m.c.seed && this.Vyto_calm_held(w, m, 'position') !== 0) {
            let a = Math.sin(tick * 12.9898 + i * 78.233) * 43758.5453
            a = a - Math.floor(a)
            let b = Math.sin(tick * 39.425 + i * 11.135) * 24634.6345
            b = b - Math.floor(b)
            m.c.seed = { x: m.c.seed.x + (a - 0.5) * 14, y: m.c.seed.y + (b - 0.5) * 14 }
        }
        i = i + 1
        this.Vyto_simmer_walk(w, m, tick, i * 31)
    }

// Vyto_relate — scribe: reads meaning and writes %Flow edges (same Artist, played-together,
//  co-heisted).  A Relate edge is also an ATTRACTION the solver honors — the first link of
//   the bunching chain (spec §6; the solver's spring read is the next milestone — the edges
//    STAND first so Vytui and the Books can see them).  Meaning = the foam signature: every
//     shared `k=v` atom between two sibling rows EXCEPT the structural join keys (of:main across
//      a family is plumbing, not kinship) and each row's own mainkey line (identity, not meaning).
//       The edges live DETACHED on w.c.relations — c-side, spool-visible, entirely view matter,
//        never a snap — as %Flow rows `a`/`b` (the two toks) + `n` (shared-atom count, a string —
//         a bare numeric 1 would wildcard).  Rebuilt whole each stir: root-scope edge sets are
//          tiny, and a rebuild can never leak a stale affinity.
Vyto_relate(w):
    if (!w.c.mirror) return
    let members = w.c.mirror.o().filter(r => !r.sc.departing)
    if (!w.c.relations) w.c.relations = new TheC({ c: {}, sc: { Relations: 1 } })
    for (const e of w.c.relations.o()) w.c.relations.drop(e)
    let sigs = []
    for (const m of members) {
        let skips = SIG_JOINS.concat(['departing', this.mainkey(m)])
        sigs.push(sig_of(m.sc, skips))
    }
    let edges = group_edges(sigs)
    for (const e of edges) {
        w.c.relations.i({ Flow: 1, a: members[e.i].c.tok, b: members[e.j].c.tok, n: '' + e.w })
    }
    if (!edges.length) return
    let organ = w.o({ Organ: 'Relate' })[0]
    if (organ && organ.sc.status !== 'live') {
        organ.sc.status = 'live'
        organ.bump_version()
    }

// Vyto_importance — the ONE composable importance number the global scale prices (Vyto_sizing_todo
//  §3).  A blend, never a single binding:
//  · 1 + dose — the base loudness (the +1 keeps a doseless row present; dose-drives-area lifted in).
//  · + a KINSHIP lift (§3 shared-ness · §9③ "a relation lifts BOTH endpoints' importance") — sum the
//     %Flow edge weights the Relate scribe already wove onto w.c.relations incident on this row's tok.
//      Relate runs BEFORE Express in Vyto_stir, so the edges stand when this reads them.  This is the
//       one thing raw dose can NEVER say: a value shared across the graph (a vein) makes every carrier
//        bigger EVERYWHERE — importance becomes graph-global, not merely local.  Coefficient 0.5: each
//         unit of shared meaning adds half a dose of loudness (eye-tuned — the COMPOSITION is the point
//          not the constant).  A relation-free row adds nothing, so a priced glass with no edges is
//           byte-identical to the plain dose box.  Intra-cell rank (§3) composes in here likewise later.
Vyto_importance(w, row):
    let imp = 1 + (Number(row.sc.dose) || 0)
    if (w.c.relations) {
        let tie = 0
        for (const e of w.c.relations.o()) {
            if (e.sc.a === row.c.tok) tie = tie + (Number(e.sc.n) || 1)
            if (e.sc.b === row.c.tok) tie = tie + (Number(e.sc.n) || 1)
        }
        imp = imp + 0.5 * tie
    }
    return imp

// Vyto_express — scribe: reads quantities and writes channels (area, weight, hue, z, blur,
//  fg/bg, motion amplitude, edge loudness).  The generalisation of dose-drives-area and of
//   Matstyle's auto-swatch instinct.  It writes the ONE channel the solver reads — area — onto
//   `.c` (row.c.env_area, never row.sc: Vyto_scan_walk sweeps unknown sc keys off mirror rows
//    every scan, so an sc-side channel would be deleted next stir).  TWO regimes:
//  · PLAIN (default) — env_area = AREA_BASE·(1 + dose), a doseless row the base.  ABSOLUTE and
//     LOCAL: a cell is blind to the rest of the graph, so adding a cell never re-breathes the
//      standing ones.  Every pre-pricing Book stands to the byte on this path.
//  · PRICED (opt-in, Vyto_sizing_todo §9 stations ④+⑤) — area demanded by the row's global
//     IMPORTANCE (Vyto_importance: dose blended with the graph-global shared-meaning lift), not raw
//      dose.  ABSOLUTE scale (the same AREA_BASE) on purpose: the power diagram reads only RELATIVE
//       radii, so the priced signal must ride the IMPORTANCE — a bigger number for a better-connected
//        cell — never a frame re-normalisation (env_area·k re-scales every radius identically and the
//         cut only shifts because r² are additive weights, which DEGRADES the importance ordering —
//          the wrong lever).  So env_area = AREA_BASE·importance: a well-connected cell is a bigger
//           cell, comparably across the whole graph.  A row with no kin ⇒ importance = 1+dose ⇒
//            byte-identical to the plain path (the priced signal is purely additive on connection).
Vyto_express(w):
    if (!w.c.mirror) return
    let rows = w.c.mirror.o().filter(r => !r.sc.departing)
    if (!rows.length) return
    if (w.c.nested) {
        // a nested glass sizes EVERY row in the tree (the scope solve reads a child's env_area for its
        //  radius inside the parent), so walk the whole mirror — not just the top row.  Plain dose box
        //   per row (pricing×nesting is a later compose; keep the first nest tenancy one-variable).
        this.Vyto_express_rows(w, rows)
    } else if (w.c.priced) {
        // DOSE MULTIPLIES THE FLOORED BASE (2026-08-09, the dead-A-drag find): the old form
        //  max(AREA_BASE·imp, need) let the need floor DOMINATE the dial on every faced cell —
        //   a measured player box is ~17× AREA_BASE, so a dose sweep moved nothing the eye
        //    could see and "the A drag gesture does nothing".  Pricing the floored base keeps
        //     the floor (a widget still never crushes below its box unpriced) AND keeps the
        //      knob live at every size.  Byte-identical wherever need is unmeasured or the
        //       row is doseless/unlifted — which is every recorded fixture combination.
        for (const row of rows) { row.c.imp = this.Vyto_importance(w, row); row.c.env_area = Math.max(1, Math.max(AREA_BASE, this.Vyto_need_of(w, row)) * row.c.imp * (1 + HEAT_BUY * (row.c.heat ?? 0))) }
    } else {
        // max(AREA_BASE, need)·(1 + dose)·(1 + 0.8·heat) — the PLAIN regime base (vyto_foam
        //  AREA_BASE), need-floored FIRST so the dial stays live on faced cells (the dead-A-drag
        //   find above), then the attention currency spends on top (heat 0 ⇒ byte-identical).
        for (const row of rows) { row.c.env_area = Math.max(1, Math.max(AREA_BASE, this.Vyto_need_of(w, row)) * (1 + (Number(row.sc.dose) || 0)) * (1 + HEAT_BUY * (row.c.heat ?? 0))) }
    }
    // THE EQUAL POSE (2026-08-09, the owner: *"we need some simulation of them competing for
    //  attention… or engaging some pose where they are all fairly equal"*).  Flatten every price to the
    //   same base, so the cut states the STRUCTURE alone — how many things there are, how they
    //    neighbour, what the tessellation actually looks like — with dose, importance, need and heat
    //     all silent.  Pricing is what makes a glass legible and it is also what hides its shape; this
    //      is the switch between the two.
    //  Runtime `.c` and last in the chain, so it overrides every regime uniformly and no fixture can
    //   see it (a Book never sets it).
    if (w.c.even) {
        for (const row of rows) row.c.env_area = AREA_BASE
    }
    // THE STAGE PRICES NOTHING (2026-08-09).  It used to overwrite every NON-staged row's env_area,
    //  and that one line quietly destroyed three separate mechanisms, each found on its own:
    //   1. the NEED FLOOR — faced cells priced below their measured box and crushed to icons
    //      (*"the Heist,posed,from cell seems to have only a 3em wide box"*);
    //   2. the FURNITURE FLOOR — AREA_BASE*0.7 is r = 23.1, and the renderer drops a cell's wall
    //      label and its A-tip below r = 24, so every other cell lost its name and its tail
    //      (*"we just regressed our ability to label and A-tip the cells properly"*);
    //   3. the ATTENTION CURRENCY — the (1 + 0.8·heat) term lives in the regime lines above, so a
    //      flat overwrite meant attending a cell under a stage did nothing (*"where's the attention
    //      sharing algorithm?"*).  Heat was still earned and still taxed; it just stopped being SPENT.
    //  Three findings, one cause, and that is the lesson worth keeping: a price is not a number, it is
    //   the PRODUCT of every rule with a claim on this cell, and replacing it discards all of them.
    //  The primary is sized from the FRAME in Vyto_stage_lay — a claim about the screen, answered in
    //   screen terms — so the contrast needs nobody else shrunk.  Every other cell keeps its ordinary
    //    price, and need, dose and attention all still work while a stage stands.
    let organ = w.o({ Organ: 'Express' })[0]
    if (organ && organ.sc.status !== 'live') {
        organ.sc.status = 'live'
        organ.bump_version()
    }

// Vyto_express_rows — the nested express: size a bag of sibling rows (dose box) then recurse into each
//  row's own children, so EVERY scope in the tree has an env_area for its scope solve to read.  Only a
//   nested glass calls this; a flat glass never leaves the top row.
Vyto_express_rows(w, rows):
    for (const row of rows) {
        if (row.sc.departing) continue
        row.c.env_area = Math.max(1, Math.max(AREA_BASE, this.Vyto_need_of(w, row)) * (1 + (Number(row.sc.dose) || 0)) * (1 + HEAT_BUY * (row.c.heat ?? 0)))
        let kids = row.o()
        if (kids.length) this.Vyto_express_rows(w, kids)
    }

// Vyto_need_of — THE NEED FLOOR (THE PIN P2): the measured widget box as a lower bound on env_area.
//  Reads row.c.need_area — stamped by the RENDER (Vytui measure pass: an ident label by getBBox or a
//   face child by the Cytui offset trick) — and returns need·1.15 (breathing room past the tight
//    box).  Zero when the floor is unarmed or nothing measured, so the Math.max above is
//     byte-invisible to every floor-free world (the additive-gate law).
Vyto_need_of(w, row):
    if (!w.c.need_floor) return 0
    let need = Number(row.c.need_area)
    if (!need || !(need > 0)) return 0
    return need * 1.15

// Vyto_fo — THE FOAMEREO READER, model side (the twin of Vytui's `fo`).  One scalar sc key holds a
//  comma deck of composer tokens: `foamereo:'wave,seal,room:0.55'`.  Returns null when the token is
//   absent (so every gate reading it is byte-invisible on an unset world — the additive-gate law),
//    '1' for a bare token, and the value string for a `key:value` one.  Kept as a verb rather than
//     an inline `includes()` because the inline form cannot carry a value and cannot tell `room`
//      from `roomy`, and the deck is going to keep growing — the owner asked for "a lot of options
//       on the foamereo", which only stays workable if reading one is a single honest call.
Vyto_fo(w, key):
    let s = String(w.sc.foamereo ?? '')
    if (!s) return null
    for (const raw of s.split(',')) {
        let t = raw.trim()
        if (t === key) return '1'
        if (t.startsWith(key + ':')) return t.slice(key.length + 1)
    }
    return null

// Vyto_solve — the cut.  For now ONE root scope (the scope milestone comes later): a fixed
//  frame, the `cell` solver of shapes.md §3 — seed-and-relax over the proven power diagram.
//   NO board Organ row is struck here: the cut is the root scope's own cell solve, and organ
//    attribution (a Cell/Fold face owning a solve) waits for the scope milestone, when a real
//     scope, not this fixed frame, owns it.  Writes each member's spring target on `.c.T`
//      (never sc — swept) and updates its `.c.seed` (solver state, persists across solves).
Vyto_solve(w):
    if (!w.c.mirror) return
    // a crushed member (Fold marked `.c.folded`) is off the cut — its group's crest cell stands for it.
    let members = w.c.mirror.o().filter(r => !r.sc.departing && !r.c.folded)
    if (!members.length) return
    // THE LOOSE LAYER (foam law — Vyto_todo "THE ORCHESTRA OF SPHERES"): a member wearing sc.loose
    //  is EXPLICITLY loose (the poser owns the vocabulary — inference from zero-flow waits until the
    //   live weave is rich enough not to misclassify an organ).  A loose member takes no seat in the
    //    pile: it is partitioned out BEFORE the relax so it exerts no wall pressure and receives
    //     none, and it is seated on the RIM below — a deterministic orbit (tok-hashed angle) that
    //      ADVANCES ONLY WHEN THE WORLD STIRS, so the loose layer drifts with activity and holds
    //       still with the fixture.  Foam-gated: a frame-cut world treats sc.loose as any other
    //        scalar and every recorded Book stands to the byte.
    let loosed = []
    if (w.c.foam) {
        loosed = members.filter(m => m.sc.loose)
        members = members.filter(m => !m.sc.loose)
    }
    // THE ROOT RECTANGLE — and it must be the one the RENDERER cuts against (Vyto_todo §0.2(d),
    //  2026-08-08).  It was the hardcoded [0,0,800,450] while Vytui cut against vw_w × vw_h, which
    //   follows the stage aspect: on a portrait phone fit_frame yields ~446×800, so this placed seeds
    //    with x up to 800 into a 446-wide cut, and every seed outside it clipped to poly.length < 3 →
    //     null → the renderer drew a 6px disc at an off-viewBox coordinate, i.e. nothing you can see.
    //  `w.c.vw_frame` is stamped by Vytui's publish_frame, whose only caller (fit_frame) returns before
    //   touching anything unless `top_House().c.humdinger`.  So a DRIVEN world is never stamped, `vf`
    //    is null, and this whole block — the frame override AND the seed clamp below — is unreachable:
    //     a Book cuts the same literal 800×450 it always did, and every recorded fixture stands to the
    //      byte.  Not "equal by arithmetic", unreachable, which is the only guarantee worth having here.
    let fw = 800
    let fh = 450
    let vf = w.c.vw_frame
    if (vf) {
        if (Number(vf.w) > 0) fw = Number(vf.w)
        if (Number(vf.h) > 0) fh = Number(vf.h)
        // CLAMP STANDING SEEDS INTO THE NEW FRAME.  Seeds persist on `.c.seed` across solves, and a
        //  seed OUTSIDE the frame is a trap, not a transient: power_cells gives it a null poly, the
        //   relax below skips a null poly (`if (!pinned[i] && polys[i])`), so nothing ever pulls it
        //    back in — a phone rotating to portrait would strand every cell whose x exceeded the new
        //     width, permanently.  With the default frame this loop is a no-op by construction (entries
        //      come from Vyto_frame_at/Vyto_frame_nearest on the boundary, and every later position is
        //       a convex combination of in-frame points), which is why it is safe to sit inside the gate.
        for (const m of members) { if (m.c.seed) m.c.seed = { x: Math.min(fw, Math.max(0, m.c.seed.x)), y: Math.min(fh, Math.max(0, m.c.seed.y)) } }
    }
    let frame = [{ x: 0, y: 0 }, { x: fw, y: 0 }, { x: fw, y: fh }, { x: 0, y: fh }]
    // a newcomer (no prior seed) enters at the frame-boundary point nearest the mean of the
    //  existing seeds — the frame centre when it is the first member.  Deterministic by
    //   construction (never Math.random — solver law 4); prior seeds ride row.c.seed.
    let existing = []
    for (const m of members) { if (m.c.seed) existing.push(m.c.seed) }
    // a BATCH of newcomers — several arriving in the SAME solve (a multi-grapple commission's first
    //  cut, or several grapples added at once) — must SPREAD.  Entering each at the boundary point
    //   nearest the running mean piles the whole batch on ONE point (the mean of a single boundary
    //    point is that point, whose nearest boundary is itself), and coincident seeds never separate
    //     (power_cells skips the wall between seeds < 0.5 apart, so each takes the whole frame and
    //      the relax pulls them all to the same centroid).  So spread a batch around the frame
    //       perimeter at distinct deterministic points — whether the frame was empty (a cold start)
    //        or already holds settled cells (a mid-run arrival: the newcomers enter at the rim and
    //         relax inward among the standing cut).  A LONE newcomer keeps the original nearest-to-
    //          mean entry — it joins the crowd — so VytoStaple's single grapple is unaffected (batch 1).
    let batch = members.filter(m => !m.c.seed).length
    let placed = 0
    for (const m of members) {
        if (m.c.seed) continue
        let entry
        if (batch > 1) {
            // + redraw salt: each Vyto_redraw press shifts the whole ring of entry points by an
            //  irrational-ish phase, so a re-deal lands a genuinely different pile.  redraw_n
            //   unset ⇒ phase 0 ⇒ the original arithmetic to the byte.
            entry = this.Vyto_frame_at(frame, ((placed + 0.5) / batch + (w.c.redraw_n ?? 0) * 0.377) % 1)
        } else {
            entry = this.Vyto_frame_nearest(frame, this.Vyto_seed_mean(existing))
        }
        m.c.seed = { x: entry.x, y: entry.y }
        existing.push(m.c.seed)
        placed = placed + 1
    }
    // seeds, radii (rᵢ = sqrt(env_area/π)), and the position-pin per member (a held seed
    //  keeps fixed through the relax: Calm_held(·,'position') === 0 means pinned).
    let seeds = []
    let radii = []
    let pinned = []
    for (const m of members) {
        seeds.push({ x: m.c.seed.x, y: m.c.seed.y })
        // env_area is clamped ≥1 at every write above, but floor it here too: a NON-finite or ≤0 area
        //  makes rᵢ = sqrt(a/π) NaN, which corrupts EVERY power_cells wall (t goes NaN, the cut empties
        //   to a 6px disc) AND pins the render's settle loop forever (NaN disp never falls below EPS).
        //    One byte-invisible floor here keeps radii finite no matter how a future env_area is priced.
        let a = Math.max(1, (m.c.env_area != null) ? m.c.env_area : AREA_BASE)
        // the focus taper (governor Focus's standing decision): the focused member's radius swells
        //  by FOCUS_BOOST and every other compresses by FOCUS_SHRINK — attention as geometry.  No
        //   standing focus ⇒ mag 1 ⇒ this line is byte-invisible to every focus-free world.
        let mag = 1
        if (w.c.focus_tok != null) mag = (m.c.tok === w.c.focus_tok) ? FOCUS_BOOST : FOCUS_SHRINK
        radii.push(Math.sqrt(a / Math.PI) * mag)
        // a GRABBED body is pinned for exactly as long as the hand holds it (w.c.drag_tok —
        //  Vytui's cell drag): the pile renegotiates around the thumb, and release lets
        //   gravity roll it back into the press.  Runtime-only, never set by a Book.
        pinned.push(this.Vyto_calm_held(w, m, 'position') === 0 || (w.c.drag_tok != null && m.c.tok === w.c.drag_tok))
    }
    // THE STAGE (the owner 2026-08-09: *"perhaps whatever's on the left of the screen becomes larger,
    //  and you drag cells over there to become the big ones... whatever was there falls out of the
    //   way"*).  Every layout law before this one is a NEGOTIATION — pressure, dose, need, heat, the
    //    room spread — and negotiations are exactly what "lots of glitch zone" is made of: nobody
    //     placed the two huge cells, nobody sent the Radio off the side, the solve did.  The stage is
    //      the opposite kind of law: the human names ONE cell and the frame is DEALT, not solved.
    //  Every seed is pinned while a stage stands, so `anyPin` is true and the fit + room laws step
    //   aside — deliberately.  They exist to rescue a solve that placed itself badly; a dealt frame
    //    has nothing to rescue, and letting them re-fit a dealt layout is how a stage would drift.
    //  Runtime `.c.stage_tok`, never sc, never set by a Book: byte-invisible to every fixture.
    let stok = this.Vyto_stage_tok(w, members)
    let sidx = -1
    if (stok != null) sidx = this.Vyto_stage_lay(w, members, seeds, radii, pinned, fw, fh, stok)
    // THE BAG IS FINITE (fit law, 2026-08-09 — the owner: "mostly in a broken layout state").
    //  Bodies keep their intrinsic sizes until the bag cannot hold them; then BAG PRESSURE
    //   squeezes everyone ALIKE (one k on every radius — a similarity, so relative pricing is
    //    untouched), and no single body may span the bag (a ball bigger than the frame IS the
    //     frame, which expresses nothing).  Squeeze-only — k never exceeds 1 — so a sparse
    //      world keeps its honest smallness: coverage stays EARNED by pressure, never granted
    //       by the frame.  Both gates are overflow-gated: a world that already fits passes
    //        through byte-identical, which is what keeps every green fixture green.
    if (w.c.foam) {
        // THE STAGED BODY IS EXEMPT FROM BOTH GATES.  "No single body may span the bag" is the right
        //  law for a negotiated pile and the wrong one for a chosen primary — the whole request is
        //   *"huge, off the edges of the screen"*, and a cap whose entire job is to prevent that
        //    cannot also be applied to it.  It is left out of the pressure TOTAL as well, so its size
        //     does not squeeze the small cells it is supposed to be sitting beside.
        //  Exactly one body can ever be exempt, and only while a human or the model has named it.
        let rcap = 0.44 * Math.min(fw, fh)
        let ri = 0
        while (ri < radii.length) {
            if (radii[ri] > rcap && ri !== sidx) radii[ri] = rcap
            ri = ri + 1
        }
        let total = 0
        ri = 0
        while (ri < radii.length) {
            if (ri !== sidx) total = total + Math.PI * radii[ri] * radii[ri]
            ri = ri + 1
        }
        let hold = 0.62 * fw * fh
        if (total > hold) {
            let k = Math.sqrt(hold / total)
            ri = 0
            while (ri < radii.length) {
                if (ri !== sidx) radii[ri] = radii[ri] * k
                ri = ri + 1
            }
        }
        // PLUMP — the one place the frame may GRANT coverage, and only because the composer
        //  asked (foamereo token `plump`): a sparse world inflates toward 0.45 fill, capped at
        //   ×3 so a lone dot never becomes the bag.  Off by default — the foam law stands.
        if (String(w.sc.foamereo ?? '').includes('plump') && total > 0 && total < 0.45 * fw * fh) {
            let pk2 = Math.min(3, Math.sqrt((0.45 * fw * fh) / total))
            ri = 0
            while (ri < radii.length) { radii[ri] = radii[ri] * pk2; ri = ri + 1 }
        }
    }
    // the Relate attraction (Vyto_spec §6 — meaning becomes proximity becomes tessellation adjacency):
    //  read the %Flow edges the scribe wrote onto w.c.relations and build the per-seat neighbour list the
    //   relax nudges toward.  Left NULL when no edge references a live seat — the relation-free solve then
    //    hands pull_step nothing and its seeds come back verbatim (the focus-taper byte-neutral discipline:
    //     no edges ⇒ this whole apparatus is invisible and every relate-free fixture stands to the byte).
    let nbrs = null
    if (w.c.relations) {
        let tokAt = {}
        let ti = 0
        while (ti < members.length) { tokAt[members[ti].c.tok] = ti; ti = ti + 1 }
        for (const e of w.c.relations.o()) {
            let ai = tokAt[e.sc.a]
            let bi = tokAt[e.sc.b]
            if (ai == null) continue
            if (bi == null) continue
            if (!nbrs) {
                nbrs = []
                let z = 0
                while (z < members.length) { nbrs.push([]); z = z + 1 }
            }
            let wgt = Number(e.sc.n) || 1
            nbrs[ai].push({ j: bi, w: wgt })
            nbrs[bi].push({ j: ai, w: wgt })
        }
    }
    // K=2 relax toward the centroidal power diagram (shapes.md §3: η=0.25, K=2, gap 2.2) — each unpinned
    //  seed steps a quarter of the way to its cell's area centroid; a null poly (crowded out) skips the
    //   pull.  When Relate wrote edges, each iteration ALSO nudges related seats toward one another
    //    (pull_step) so meaning bunches into adjacency; the centroidal pull counter-balances so the
    //     equilibrium is proximity not collapse.  K is small on purpose: convergence rides successive
    //      solves, so the relax is interruptible by construction.
    // THE PILE (foam law — "coverage is earned by pressure, not granted by the frame").  Under the
    //  foam gate the centroidal relax is OFF: a centroid pull is the frame dictating where bodies
    //   sit, and the foam law says the bodies negotiate.  pile_step (vyto_geometry — pure, node-
    //    proven in the foam studies) is gravity toward the bag's heart + wires toward kissing
    //     distance + separation past the squeeze, iterated INSIDE this one solve to its fixed
    //      point (bounded at 400, quit when the largest move falls under 0.05).  In-solve
    //       convergence is the rest discipline: rest_poll stirs in a loop while waiting, so a
    //        relax that leaves standing motion for the NEXT stir is a world that can never rest.
    //  400 is MEASURED, not guessed (scratch probe, 2026-08-09): gravity 0.02/step is an
    //   exponential approach, and the worst case probed — a lone ball crossing the whole frame —
    //    lands under 0.05 in 256 steps; a 6-ball wired orchestra in 121.  A 40 cap looked fine
    //     and NEVER rested in 3 of 4 configs — the next solve inherited standing motion forever.
    //  Pins are restored after every step — pile_step is pin-blind on purpose, it stays pure.
    //   Deterministic throughout (solver law 4): same members, same seeds, same pile.
    if (w.c.foam) {
        let centre = { x: fw / 2, y: fh / 2 }
        let pk = 0
        while (pk < 400) {
            let next = pile_step(seeds, radii, centre, nbrs || [])
            let moved = 0
            let pi = 0
            while (pi < seeds.length) {
                if (pinned[pi]) next[pi] = seeds[pi]
                let dd = Math.abs(next[pi].x - seeds[pi].x) + Math.abs(next[pi].y - seeds[pi].y)
                if (dd > moved) moved = dd
                pi = pi + 1
            }
            seeds = next
            pk = pk + 1
            if (moved < 0.05) pk = 999
        }
        // THE CLOUD SITS IN THE SHOT (fit law, part two).  A settled pile can still poke past an
        //  edge — a wired chain is long, gravity is gentle — so after rest, translate the pile's
        //   bounding box the MINIMUM distance that brings it inside, then (only if it still cannot
        //    fit) scale seeds AND radii about the bag's heart — one similarity transform, every
        //     kiss preserved.  Overflow-gated: an in-frame pile passes byte-identical.  Skipped
        //      whole when any seed is PINNED — a held position is an author's word, and a fit that
        //       moves it is the frame overruling the author.
        let anyPin = false
        for (const p of pinned) { if (p) anyPin = true }
        if (!anyPin && seeds.length) {
            let minx = 1e9
            let miny = 1e9
            let maxx = -1e9
            let maxy = -1e9
            let si = 0
            while (si < seeds.length) {
                if (seeds[si].x - radii[si] < minx) minx = seeds[si].x - radii[si]
                if (seeds[si].y - radii[si] < miny) miny = seeds[si].y - radii[si]
                if (seeds[si].x + radii[si] > maxx) maxx = seeds[si].x + radii[si]
                if (seeds[si].y + radii[si] > maxy) maxy = seeds[si].y + radii[si]
                si = si + 1
            }
            let pad = 5
            let dx = 0
            let dy = 0
            if (minx < pad) dx = pad - minx
            if (maxx > fw - pad && dx === 0) dx = (fw - pad) - maxx
            if (miny < pad) dy = pad - miny
            if (maxy > fh - pad && dy === 0) dy = (fh - pad) - maxy
            let sk = 1
            let bw = maxx - minx
            let bh = maxy - miny
            if (bw > fw - 2 * pad) sk = (fw - 2 * pad) / bw
            if (bh > fh - 2 * pad && (fh - 2 * pad) / bh < sk) sk = (fh - 2 * pad) / bh
            if (sk < 1) {
                // too big even shifted: shrink about the CLOUD's centre and land that centre on
                //  the bag's heart — the scaled bbox then fits exactly, no residual overflow.
                let ccx = (minx + maxx) / 2
                let ccy = (miny + maxy) / 2
                si = 0
                while (si < seeds.length) {
                    seeds[si] = { x: fw / 2 + (seeds[si].x - ccx) * sk, y: fh / 2 + (seeds[si].y - ccy) * sk }
                    radii[si] = radii[si] * sk
                    si = si + 1
                }
            }
            if (sk >= 1 && (dx !== 0 || dy !== 0)) {
                si = 0
                while (si < seeds.length) {
                    seeds[si] = { x: seeds[si].x + dx, y: seeds[si].y + dy }
                    si = si + 1
                }
            }
            // ── THE ROOM LAW (2026-08-09, the owner: *"there's a 16:9 space with one big orb in the
            //  middle with gaps on either side of it — it should be slightly more aware of the space it
            //   can use — cytoscape was good at this"*).  The fit law above is only its shrinking half:
            //    nothing here ever GREW, and nothing anywhere read the frame's ASPECT.  So the pile
            //     packs an isotropic blob, and a 16:9 bag gets a round cloud with two dead thirds — the
            //      live capture measured exactly that (cloud x 229→571 of 800, every faced cell crushed).
            //  Two moves, both about the room and neither about the pricing:
            //   1. SPREAD — positions scale about the cloud's centre onto the bag's heart, ANISOTROPICALLY
            //      (gx and gy separately), so a wide bag pulls the cloud wide.  Positions only; balls stay
            //      round, relative pricing untouched, and a spread ≥1 can never create an overlap the pile
            //      had already resolved — it only opens the presses that were crushing every cell.
            //   2. GROW — radii then rise isotropically toward the asked fill, bounded by the SAME rcap
            //      and pressure hold the shrinking half enforces, so the two halves can never fight.
            //  This is the one place the frame GRANTS coverage instead of pressure earning it, so it is
            //   OPT-IN and says so: `foamereo:'room'` (or `room:<fill>`, default 0.55).  Unset ⇒ this
            //    whole block is skipped and every recorded fixture stands to the byte.  `lean` is not
            //     needed as an opt-out — absence IS the opt-out.
            let room = this.Vyto_fo(w, 'room')
            if (room != null) {
                let want = Number(room) > 0 ? Number(room) : 0.55
                let rminx = 1e9
                let rminy = 1e9
                let rmaxx = -1e9
                let rmaxy = -1e9
                si = 0
                while (si < seeds.length) {
                    if (seeds[si].x - radii[si] < rminx) rminx = seeds[si].x - radii[si]
                    if (seeds[si].y - radii[si] < rminy) rminy = seeds[si].y - radii[si]
                    if (seeds[si].x + radii[si] > rmaxx) rmaxx = seeds[si].x + radii[si]
                    if (seeds[si].y + radii[si] > rmaxy) rmaxy = seeds[si].y + radii[si]
                    si = si + 1
                }
                let rbw = rmaxx - rminx
                let rbh = rmaxy - rminy
                let gx = 1
                let gy = 1
                if (rbw > 1) gx = Math.max(1, Math.min(2.5, (fw - 2 * pad) / rbw))
                if (rbh > 1) gy = Math.max(1, Math.min(2.5, (fh - 2 * pad) / rbh))
                if (gx > 1.001 || gy > 1.001) {
                    let rcx = (rminx + rmaxx) / 2
                    let rcy = (rminy + rmaxy) / 2
                    si = 0
                    while (si < seeds.length) {
                        seeds[si] = { x: fw / 2 + (seeds[si].x - rcx) * gx, y: fh / 2 + (seeds[si].y - rcy) * gy }
                        si = si + 1
                    }
                }
                // THE GROW HALF IS GONE (2026-08-09, off the owner's screenshot).  Spreading positions
                //  uses the room; growing RADII to hit a fill target does not — it inflates every cell
                //   past the content it holds, so the component ends up small in a vast blob (the seat
                //    is capped by FIT_MAX, so a bigger cell just buys more margin, which is the exact
                //     complaint "about half of it is margin" arriving from the other side).  It also
                //      broke containment outright: the cloud-into-shot fit runs BEFORE this, so radii
                //       grown afterwards pushed cells straight off the frame — visible in the capture as
                //        blobs cropped by the viewport top and bottom.
                //  So the room law is now SPREAD ONLY.  Cells stay the size their content asked for and
                //   are distributed across the bag instead of huddling in the middle, which is the whole
                //    of what was wanted: use the screen, do not inflate the furniture.
                void want
            }
        }
    }
    if (!w.c.foam) {
        let k = 0
        while (k < 2) {
            let polys = power_cells(frame, seeds, radii, 2.2)
            let i = 0
            while (i < seeds.length) {
                if (!pinned[i] && polys[i]) {
                    let c = poly_centroid(polys[i])
                    seeds[i] = { x: seeds[i].x + 0.25 * (c.x - seeds[i].x), y: seeds[i].y + 0.25 * (c.y - seeds[i].y) }
                }
                i = i + 1
            }
            if (nbrs) seeds = pull_step(seeds, nbrs, pinned, 0.15)
            k = k + 1
        }
    }
    // final cut + area-centroid anchors → write targets.  Solver law 1: if the computed T
    //  equals the standing T (x, y AND r), leave the reference untouched so "no change grants
    //   no motion" is byte-visible.  A departing row's T is left alone (the renderer ramps it
    //    out) — those rows were filtered out of `members` above.
    // Under foam the final cut is the FOAM cut — each cell its own disc trimmed where discs press
    //  (same law the renderer draws by), because the scope recursion below hands finals[p] to every
    //   bag as its tessellation bound: a null finals under foam THREW on `finals[p]` and took every
    //    stir down with it (the 2026-08-09 controlled-revert find: 1/7 %see with the pile, 7/7
    //     without — the pile was innocent, the null was the killer).  The anchor stays the BALL
    //      under foam: a centroid would tug every T off the body it stands for.
    let finals = null
    if (w.c.foam) finals = foam_cells(seeds, radii, 2.2, frame)
    if (!w.c.foam) finals = power_cells(frame, seeds, radii, 2.2)
    let j = 0
    while (j < members.length) {
        let m = members[j]
        m.c.seed = { x: seeds[j].x, y: seeds[j].y }
        let anchor = seeds[j]
        if (!w.c.foam && finals && finals[j]) anchor = poly_centroid(finals[j])
        let r = radii[j]
        let T = m.c.T
        // law 1 with a SETTLE TOLERANCE (shapes.md — "no change grants no motion"): a sub-EPS drift
        //  is NO change.  The relax approaches its fixed point by ever-smaller steps, so an exact
        //   `!==` rewrites T (and re-animates) on floating-point noise FOREVER — a distinct multi-cell
        //    cut never stands byte-still.  Once every cell sits within EPS (a hundredth of a pixel —
        //     imperceptible) of its target, leave the standing reference untouched: the world is at
        //      rest and a further stir grants no motion, byte-true.  A single-cell solve (VytoStaple's
        //       lone grapple → the whole frame) matches EXACTLY every solve, so EPS never bites there.
        let EPS = 0.5
        if (!T || Math.abs(T.x - anchor.x) > EPS || Math.abs(T.y - anchor.y) > EPS || Math.abs(T.r - r) > EPS) {
            m.c.T = { x: anchor.x, y: anchor.y, r: r }
            m.bump_version()
        }
        j = j + 1
    }
    // THE RIM SEATS — the loose layer's own ring, after the pile has its targets.  Angle is a hash
    //  of the tok alone: STATIC by design — a stir-advanced spin was tried and cut, because
    //   Vyto_rest_poll stirs in a loop while waiting for rest, so any per-stir motion means a
    //    driven world can never rest (drift belongs to the RENDERER, later, where a Book never
    //     looks).  The ellipse factor keeps a wide frame's ring inside the short axis.
    //      EPS-tolerant like law 1, so a quiet loose row stands byte-still.
    if (loosed.length) {
        let ocx = fw / 2
        let ocy = fh / 2
        let orbR = Math.min(fw, fh) * 0.46
        for (const m of loosed) {
            let ts = String(m.c.tok || '')
            let hsh = 0
            let hi = 0
            while (hi < ts.length) { hsh = (hsh * 31 + ts.charCodeAt(hi)) % 6283; hi = hi + 1 }
            let ang = hsh / 1000
            let la = Math.max(1, (m.c.env_area != null) ? m.c.env_area : AREA_BASE)
            let lr = Math.sqrt(la / Math.PI) * 0.4
            let lx = ocx + Math.cos(ang) * orbR * 1.35
            let ly = ocy + Math.sin(ang) * orbR * 0.82
            lx = Math.min(fw - lr, Math.max(lr, lx))
            ly = Math.min(fh - lr, Math.max(lr, ly))
            let LT = m.c.T
            if (!LT || Math.abs(LT.x - lx) > 0.5 || Math.abs(LT.y - ly) > 0.5 || Math.abs(LT.r - lr) > 0.5) {
                m.c.T = { x: lx, y: ly, r: lr }
                m.bump_version()
            }
        }
    }
    // NESTED scopes (opt-in, Vyto_sizing_todo J4 · Nestcut proven in isolation): the root cut stands
    //  above — now each top cell BECOMES the frame for its own mirror children, recursing to any depth.
    //   ADDITIVE + gated: a flat glass never enters here, so every flat fixture stands to the byte.  The
    //    top polys come from `finals` (the cut just computed) — no re-cut of the root.
    if (w.c.nested) {
        let p = 0
        while (p < members.length) {
            let m = members[p]
            m.c.poly = finals[p] ?? null
            if (m.c.poly) this.Vyto_solve_scope(w, m, m.c.poly)
            p = p + 1
        }
    }

// Vyto_solve_scope — the scope recursion: tessellate `poly` among `parent`'s live mirror children,
//  write each child's spring target T (EPS-tolerant law 1, so a settled scope stands byte-still) and
//   its cell polygon on `.c.poly`, then recurse.  gap=0 — a scope FILLS its parent (tiling is the scope
//    property, unlike the top cut's visual 2.2 gap); stamps parent.c.misfit = |parent area − Σ child
//     areas| so a Book can assert the seam carries no cost.  Seeds spread deterministically around the
//      parent polygon perimeter (Vyto_frame_at) and persist on `.c.seed`, so re-cuts stay stable.
Vyto_solve_scope(w, parent, poly):
    let kids = parent.o().filter(r => !r.sc.departing && !r.c.folded)
    if (!kids.length) return
    let seeds = []
    let radii = []
    // DEPTH SCALING (Vyto_todo THE PIN P3 · Vyto_perf_todo §2): a child radius was ABSOLUTE —
    //  √(env_area/π) is sized for the whole 800×450 frame — then dropped into a parent cell maybe
    //   an eighth that wide, so a gentle dose difference became violent (the big sibling claimed
    //    the cell and small siblings crowded out to null).  Scale the WHOLE scope's radii by
    //     √(parent share of the frame): the r² wall differentials then shrink WITH the parent, so
    //      children contest a small cell as gently as tops contest the frame.  Relative order is
    //       untouched — express still speaks through env_area; this only fits the voice to the room.
    //  The 800*450 denominator is the frame AREA, and it stays literal for the same reason the fold
    //   budget above does: the area moves under 1% when the aspect does (a portrait 446×800 is 356800),
    //    so tying it to w.c.vw_frame would buy a sub-percent correction at the price of one more thing
    //     a nested layout depends on the tab's geometry for.  Reasoned from the arithmetic, not measured.
    let depth_k = w.c.depth_scale ? Math.sqrt(Math.abs(poly_area(poly)) / (800 * 450)) : 1
    let i = 0
    while (i < kids.length) {
        let k = kids[i]
        if (!k.c.seed) k.c.seed = this.Vyto_frame_at(poly, (i + 0.5) / kids.length)
        seeds.push({ x: k.c.seed.x, y: k.c.seed.y })
        let a = (k.c.env_area != null) ? k.c.env_area : AREA_BASE
        radii.push(Math.sqrt(a / Math.PI) * depth_k)
        i = i + 1
    }
    let kk = 0
    while (kk < 2) {
        let polys = power_cells(poly, seeds, radii, 0)
        let z = 0
        while (z < seeds.length) {
            if (polys[z]) {
                let c = poly_centroid(polys[z])
                seeds[z] = { x: seeds[z].x + 0.25 * (c.x - seeds[z].x), y: seeds[z].y + 0.25 * (c.y - seeds[z].y) }
            }
            z = z + 1
        }
        kk = kk + 1
    }
    let finals = power_cells(poly, seeds, radii, 0)
    let parea = Math.abs(poly_area(poly))
    let sum = 0
    let j = 0
    while (j < kids.length) {
        let k = kids[j]
        k.c.seed = { x: seeds[j].x, y: seeds[j].y }
        let cell = finals[j]
        let anchor = cell ? poly_centroid(cell) : seeds[j]
        let r = radii[j]
        if (cell) sum = sum + Math.abs(poly_area(cell))
        let T = k.c.T
        let EPS = 0.5
        if (!T || Math.abs(T.x - anchor.x) > EPS || Math.abs(T.y - anchor.y) > EPS || Math.abs(T.r - r) > EPS) {
            k.c.T = { x: anchor.x, y: anchor.y, r: r }
            k.bump_version()
        }
        k.c.poly = cell ?? null
        if (cell) this.Vyto_solve_scope(w, k, cell)
        j = j + 1
    }
    parent.c.misfit = Math.abs(parea - sum)

// Vyto_seed_mean — the mean of the seeds placed so far, or the frame centre (400,225) when
//  none stand yet.  Feeds the newcomer's deterministic boundary entry point.
Vyto_seed_mean(seeds):
    if (!seeds.length) return { x: 400, y: 225 }
    let sx = 0
    let sy = 0
    for (const s of seeds) { sx = sx + s.x; sy = sy + s.y }
    return { x: sx / seeds.length, y: sy / seeds.length }

// Vyto_frame_at — the point at perimeter fraction f (wrapped to [0,1)) around the frame boundary,
//  walking edges in order.  Feeds the cold-batch spread so simultaneous newcomers enter DISTINCT
//   points (a lone newcomer never reaches this — the nearest-to-mean entry still governs joins).
Vyto_frame_at(frame, f):
    let lens = []
    let per = 0
    let i = 0
    while (i < frame.length) {
        let a = frame[i]
        let b = frame[(i + 1) % frame.length]
        lens.push(Math.hypot(b.x - a.x, b.y - a.y))
        per = per + lens[i]
        i = i + 1
    }
    let ff = f - Math.floor(f)
    let target = ff * per
    let acc = 0
    let j = 0
    while (j < frame.length) {
        if (acc + lens[j] >= target) {
            let a = frame[j]
            let b = frame[(j + 1) % frame.length]
            let t = (lens[j] > 0) ? (target - acc) / lens[j] : 0
            return { x: a.x + t * (b.x - a.x), y: a.y + t * (b.y - a.y) }
        }
        acc = acc + lens[j]
        j = j + 1
    }
    return { x: frame[0].x, y: frame[0].y }

// Vyto_frame_nearest — the point on the frame boundary nearest p: the closest point over
//  every edge, first minimum wins (deterministic).
Vyto_frame_nearest(frame, p):
    let best = null
    let bestD = null
    let i = 0
    while (i < frame.length) {
        let cp = this.Vyto_seg_nearest(frame[i], frame[(i + 1) % frame.length], p)
        let dx = cp.x - p.x
        let dy = cp.y - p.y
        let d = dx * dx + dy * dy
        if (bestD === null || d < bestD) { bestD = d; best = cp }
        i = i + 1
    }
    return best ?? { x: p.x, y: p.y }

// Vyto_seg_nearest — the closest point on segment a→b to p (clamped projection).
Vyto_seg_nearest(a, b, p):
    let dx = b.x - a.x
    let dy = b.y - a.y
    let len2 = dx * dx + dy * dy
    if (len2 === 0) return { x: a.x, y: a.y }
    let t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / len2
    if (t < 0) t = 0
    if (t > 1) t = 1
    return { x: a.x + t * dx, y: a.y + t * dy }
//#endregion

//#region the spool — two clocks, one ring (spec §8); moments captured AT SETTLE
// Vyto_settle — the %Settle tick.  The renderer calls this OFF the frame loop when
//  max(cell displacement, boundary vertex drift) < ε sustained SETTLE_FRAMES; the skeleton
//   makes it hand-strikeable (the drum-pad idiom) so the spool end of the wire can be
//    proven before any cell moves.  Settled state is dropped by the renderer on any new
//     target; here we just count ticks and capture.
// THE SECOND CLOCK, WIRED (2026-08-05).  Vyto_spool_capture has always accepted opts.step_n — "step
//  captures ALSO carry step_n, the quantize-lock Story pips seek by" — but NOTHING ever passed it, so
//   every Moment was scrubber-only and Storui's step pip (Storui.svelte, e_Vyto_seek with {step_n})
//    could never resolve: Vyto_seek_to looks for a Moment whose step_n matches and there were none.
//  The settle is exactly where the step is known, so read it here, off the commissioned Run (the same
//   `w.c.Run?.c?.run` ref Vyto_spool_frozen reads the verdict from).  IN FLIGHT ONLY: `driving` with a
//    live step_n.  A settle struck between steps, or in a resident glass with no Run, stamps NOTHING —
//     an absent key, never `undefined` (an undef marker in a snap is a mint bug, not furniture).
async Vyto_settle(w):
    w.c.settled = (w.c.settled ?? 0) + 1
    // the NORMALCY reading rides the settle: the world just stopped moving, so NOW is when
    //  "is anything missing or off screen" is a fair question (mid-flight it is noise).
    this.Vyto_normal(w)
    let run = w.c.Run?.c?.run
    let step_n = (run && run.c.driving && run.c.step_n != null) ? run.c.step_n : null
    if (step_n == null) {
        await this.Vyto_spool_capture(w)
    } else {
        await this.Vyto_spool_capture(w, { step_n: step_n })
    }

// Vyto_normal — SUPERVISORY reading (Supervisor_todo §9, the owner 2026-08-09: "pop into
//  Supervisor whatever we need to do to keep Vyto normal, which is a visible player").  The glass
//   is a UI a person is looking at, so at every settle it asks the two objective questions a
//    person would — and pokes the layout rather than waiting for a human to notice:
//  1. PRESENCE — every grapple the commission was given still has a live cell.  A %Radio the
//      commissioner handed over that has no mirror row is a scan fault or a race (the glass can
//       commission before the organ exists) — say so once and stir, so the next scan re-mints it.
//  2. VISIBILITY — every body is at least half on screen.  Off-frame is a LAYOUT fault, never a
//      fact about the data ("things go missing somehow" — nobody sent the Radio off the side, the
//       solve did).  Cure: drop the seed and stir — the newcomer law re-enters it at the rim and
//        the relax pulls it into the pile.  At most 2 pokes per cell per offence, then ONE see row
//         naming it instead of poking forever — a supervisor that livelocks the layout is worse
//          than none (the §6 anti-goal, applied to ourselves).
//  GATED ON w.c.vw_frame: only Vytui's publish_frame stamps it, and only on a humdinger tab — a
//   DRIVEN world is never stamped, so this whole verb is unreachable for Books and every recorded
//    fixture stands to the byte.  The staged cell is exempt from visibility — off the edges is
//     its whole job.
Vyto_normal(w):
    let vf = w.c.vw_frame
    if (!vf || !w.c.mirror) return
    let fw = Number(vf.w) > 0 ? Number(vf.w) : 800
    let fh = Number(vf.h) > 0 ? Number(vf.h) : 450
    let poked = 0
    // 1. presence — each grapple wants a live (non-departing) top-level row
    for (const g of w.c.grapples ?? []) {
        let found = 0
        for (const r of w.c.mirror.o()) { if (r.c.source_n === g && !r.sc.departing) found = 1 }
        let mk = this.mainkey(g) ?? '?'
        if (found) { if (w.c.normal_said) delete w.c.normal_said[mk]; continue }
        if (!w.c.normal_said) w.c.normal_said = {}
        if (!w.c.normal_said[mk]) {
            w.c.normal_said[mk] = 1
            w.i({ see: `⚕ Vyto normal: grappled %${mk} has no cell — poking a rescan` })
            // poke ONCE per offence, on first sight — the grapple watch re-stirs by itself the
            //  moment the organ actually changes, and a poke per settle would stir→settle→stir
            //   forever on an organ that stays missing (the livelock this verb must never be).
            poked = 1
        }
    }
    // 2. visibility — every unstaged body's centre in frame; off-frame ⇒ re-seed at the rim
    let stok = w.c.stage_tok
    for (const m of w.c.mirror.o()) {
        if (m.sc.departing || m.c.folded || m.sc.loose) continue
        if (m.c.tok === stok) continue
        let t = m.c.T
        if (!t) continue
        let out = t.x < 0 || t.x > fw || t.y < 0 || t.y > fh
        if (!out) { if (m.c.normal_pokes) m.c.normal_pokes = 0; continue }
        let n = (m.c.normal_pokes ?? 0) + 1
        m.c.normal_pokes = n
        if (n > 2) {
            if (n === 3) w.i({ see: `⚕ Vyto normal: ${m.c.tok} sits off screen and two pokes did not cure it` })
            continue
        }
        delete m.c.seed
        poked = 1
    }
    if (poked) this.Vyto_stir_soon(w)

// Vyto_spool_capture — chronicler Spool: reads settles and writes moments.  TWO CLOCKS:
//  every capture gets monotonic yore_n; step captures ALSO carry step_n (the quantize-lock
//   Story pips seek by) — and step_n is stamped ONLY when a step is in flight, NEVER
//    undefined (an undef marker is a mint bug).  The snap payload rides .c — and it is
//     snap_H (the SAME ref-pass encoder the fixtures use), NOT enWaft: the spec said
//      enWaft but the fixtures never came from it, and a moment must diff cleanly against
//       a fixture (workingouts/spool.md names the exact calls; lands milestone 2).
async Vyto_spool_capture(w, opts):
    let n = w.c.yore_n = (w.c.yore_n ?? 0) + 1
    let row
    if (opts && opts.step_n != null) {
        row = w.i({ Moment: n, step_n: opts.step_n })
    } else {
        row = w.i({ Moment: n })
    }
    // the payload — the RUN world snapped by snap_H (the SAME ref-pass encoder the fixtures use,
    //  so a moment diffs byte-clean against a fixture — spool.md §2).  It rides `.c`: a multi-KB
    //   string never belongs in sc (it would serialise into every exactly() and fold into every
    //    trace identity).  A BOUNDED await (a Selection tree walk) is allowed off the beat; an
    //     unbounded await under the beliefs mutex is the Sounditron deadlock.  w is undefined (a
    //      resident glass gets the unshaped walk) and Se_home is Vyto's OWN world, so Story's
    //       changed|is_new trace baseline never advances beneath the real snap_step.
    if (w.c.Run) {
        row.c.snap = await this.snap_H(w.c.Run, undefined, w)
    } else if (!w.c.bare_noted) {
        // no Run on the commission — moments still chronicle but carry no diffable payload; say
        //  it ONCE per world so the strip stays honest without flooding the see rows.
        w.c.bare_noted = 1
        w.i({ see: 'spool moments ride bare until a commission carries the Run' })
    }
    this.Vyto_spool_cull(w)
    return row

// Vyto_spool_frozen — has the commissioned run LANDED FAILED?  Read straight off the Run ref's
//  verdict (Run.c.run.sc.failed_at — the step number Story stamps the instant a run pauses at a
//   failing step, cleared on accept/forgive).  A frozen spool is EVIDENCE: it must not cull.
Vyto_spool_frozen(w):
    let run = w.c.Run?.c?.run
    return (run && run.sc.failed_at != null) ? 1 : 0

// Vyto_spool_cull — ring management: ~60, drop-oldest; o-marked moments are EXEMPT (kept
//  without typing — the seen-it rung of the keeping ladder) under their own generous cap;
//   blessed moments never drop.  FREEZE ON RUN-FAIL (spec §8, milestone 2): once the run lands
//    failed the ring is the forensic record — NO cull, NO drop-oldest, so every captured moment
//     survives for inspection (o/bless were already exempt; the freeze extends that to the whole
//      ring the moment the run reds).
Vyto_spool_cull(w):
    if (this.Vyto_spool_frozen(w)) return
    let rows = w.o({ Moment: 1 })
    let loose = rows.filter(m => !m.sc.o && !m.sc.bless)
    while (loose.length > 60) {
        w.drop(loose[0])
        loose = loose.slice(1)
    }

// e_Vyto_seek — display-only time travel: park the glass at a moment (yore_n), live
//  capture continues underneath, display follows nothing (the landmark-hold governs the
//   parked view).  seek with no yore_n = back to live.  NEVER resumes past C** state —
//    the spool archives mirrors, so there is nothing to resume INTO.
e_Vyto_seek(A, w, e):
    this.Vyto_seek_to(w, e?.sc)

// Vyto_seek_to — the seek RESOLVER (spec §12 moult seam).  A yore_n seek parks the glass directly
//  (the scrubber path — byte-unchanged).  A STEP seek (Storui's pip strip routes the step here, the
//   same way it hands Cyto a step) translates to the yore_n of the MOMENT carrying that step_n — the
//    quantize-lock Story pips seek by.  Moments with NO step_n are SCRUBBER-ONLY: a step seek never
//     lands on them (Number(undefined) is NaN, matches nothing).  No match (or a bare clear) parks
//      back at live (open_at null).  Factored out so both the elvis and a client|test share it.
Vyto_seek_to(w, opts):
    let yore = opts?.yore_n
    if (yore == null && opts?.step_n != null) {
        let mom = w.o({ Moment: 1 }).find(m => Number(m.sc.step_n) === Number(opts.step_n))
        yore = mom ? mom.sc.Moment : null
    }
    if (yore != null) {
        w.c.open_at = yore
    } else {
        w.c.open_at = null
    }

// Vyto_omark — the o-mark: point at a moment (default: the newest) and mark it `o` —
//  we saw it — kept, exempt from drop-oldest, nothing typed.  Another tap lets it go.
Vyto_omark(w, yore_n):
    let rows = w.o({ Moment: 1 })
    let row
    if (yore_n != null) {
        row = rows.find(m => m.sc.Moment == yore_n)
    } else {
        row = rows[rows.length - 1]
    }
    if (!row) return
    if (row.sc.o) {
        delete row.sc.o
    } else {
        row.sc.o = 1
    }
    row.bump_version()
    return row
//#endregion
