<script lang="ts">
    // Vytui.svelte — the render side of the NEW glass (spec: Vyto_spec.md, unpreened;
    //  model side: Ghost/V/Vyto.g).  Tessellation-first cells as real DOM/SVG, faces as
    //   child elements, text measured by the browser — the overlay-sync bug class ends by
    //    construction, not by fix.
    //  THE BOARD (spec §9) and the moment STRIP (spec §8) stand exactly as they did — the bar
    //   of one-word toggles, the organ panel, the spool's ticks — and BELOW them now stands
    //    THE FIRST CELL: one root scope, a fixed 800×450 frame, cut by the proven power diagram
    //     and sprung critically-damped from the model's targets (calm.md §5).  Walls re-derive
    //      every frame from the sprung seeds; text rides the seed; the model is the UI.
    //  Mounts off the UIs registry (Vyto_plan registers it; Otro mounts every UI with
    //   H={house}), so a House with no w:Vyto renders nothing at all.
    import { TheC }   from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { power_cells, type Pt } from "$lib/O/vyto_geometry"
    import { GLASS_KINDS } from "$lib/O/glass_kinds"
    import { FACE_MAINKEYS } from "$lib/O/glass_faces"
    import { lifetell } from "$lib/O/ui/micro/lifetell"   // DIAGNOSTIC — strip with the rest of the remount probes
    import { hold_list, hold_true } from "$lib/O/ui/micro/hold"
    import { onMount, onDestroy } from 'svelte'

    let { H } = $props()

    // LIFECYCLE BRACKET (2026-08-02): is the whole glass remounting, or just KeepFace inside it?
    //  The serial USED TO LIVE IN A `<script module>` BLOCK, and that one block cost the whole glass its
    //   HMR (2026-08-07, the human's "why does HMR cause a whole page reload sometimes").  vite-plugin-
    //    svelte refuses to make a component self-accepting once it has module-context state: a module
    //     binding cannot be hot-swapped without re-evaluating every importer.  So Vytui was an HMR
    //      DEAD END — and `glass_kinds.ts`, whose only importer is Vytui, inherited it, which is why
    //       registering one face reloaded both player tabs and cost the human an AudioContext tap.
    //  It counts two console lines.  Keeping it on the House (`.c`, runtime-only, never encoded) buys
    //   back hot updates for every face in the glass and loses nothing the bracket was for.
    //  Defensive: this is a DEBUG COUNTER, and a debug counter that throws would white-screen the whole
    //   glass on mount — worse than any question it answers.  Optional-chained, defaulting to 0.
    const __vy_id = (() => {
        const hc = (H as any)?.c
        if (!hc) return 0
        hc.vytui_serial = (hc.vytui_serial ?? 0) + 1
        return hc.vytui_serial
    })()
    onMount(()   => console.log('▣▣ Vytui REAL mount',   __vy_id))
    onDestroy(() => console.log('▣▣ Vytui REAL destroy', __vy_id))

    // ── the FACE rail (Cyto parity — glass_kinds.ts) ──────────────────────────────────────
    //  A cell whose mirror row wears `sc.face:'X'` (WORN) or whose mainkey the viewer imposes a
    //   face on (FACE_MAINKEYS — Heist · Musu*→Crate) mounts the SAME Svelte face component Cyto
    //    does — props { n, H } — molded into its cell.  This is what makes the glass a real UI
    //     (play/pause, track decks, friend liveness) and not a labelled bubble diagram.  The face
    //      is handed the SOURCE particle `row.c.source_n` (the live gear the face reads), NEVER the
    //       scalar mirror row.  A row with no resolvable face keeps its ident label (the old paint),
    //        so every faceless Book (Cogs) renders byte-identical.
    function face_of(row: TheC): { comp: any, source: TheC } | null {
        if (!row || !row.sc) return null
        const mk = Object.keys(row.sc)[0]
        const kind = (row.sc as any).face || (mk ? FACE_MAINKEYS[mk] : null)
        if (!kind) return null
        const comp = GLASS_KINDS[kind]
        const source: any = (row.c as any).source_n
        if (!comp || !source) return null
        return { comp, source }
    }

    // the glass worlds on this House — A:Vyto > w:Vyto (the A:Cyto precedent).  ob() reads
    //  vers so the walk re-runs when worlds arrive; called from the template, never from a
    //   construction $effect (the Otro H-effect lesson).
    function vyto_worlds(): TheC[] {
        if (!H) return []
        const out: TheC[] = []
        for (const A of H.ob({ A: 'Vyto' }) as TheC[])
            for (const w of A.ob({ w: 'Vyto' }) as TheC[]) out.push(w)
        // WORLDS PROBE (2026-08-04): the life ladder proved the `{#each vyto_worlds() as w (w)}`
        //  block is recreated every tick while the `w` OBJECT stays stable (springs/paintMap, both
        //   Map<TheC,…> keyed by w, keep hitting — one entrance ramp in a whole run, not one per
        //    tick).  Stable key + recreated block ⟹ the each is being handed a transiently EMPTY
        //     list: one render with 0 worlds destroys the subtree, the next brings the same object
        //      back and rebuilds it.  Every other probe is blind to that render because they all
        //       live INSIDE the world (build_cells / show_viewport simply never run).  This logs the
        //        count transition and whether identity survived it — one line per gap, naming which
        //         half went missing (the A:Vyto actor, or the w:Vyto under it).
        const prevN = lastWorldsN
        if (prevN !== undefined && prevN !== out.length) {
            const nA = (H.ob({ A: 'Vyto' }) as TheC[]).length
            const same = out.length === 1 && lastWorldObj === out[0]
            console.log('◈ Vyto WORLDS', prevN, '→', out.length, '| A:Vyto rows=', nA,
                        'sameObject=', same, '(false on a 0-render is expected — nothing to compare)')
            const M: any = (H as any).top_House?.()
            if (M) { const log = M.c.supply_trace || (M.c.supply_trace = []); log.push({ t: Date.now(), ev: 'vyto-worlds', id: 'Vyto', from: prevN, to: out.length, actors: nA, same: same ? 1 : 0 }); if (log.length > 300) log.splice(0, log.length - 300) }
        }
        lastWorldsN = out.length
        if (out.length) lastWorldObj = out[0]
        // THE HOLD (2026-08-05, the fix the probe above earned).  The gap is REAL and it is standard:
        //  `agency_officing` (Hovercraft.svelte:133) replaces every actor's `w:` children every tick,
        //   and replace() publishes the empty half of its transaction (ui/micro/hold.ts has the chain).
        //    So we buffer what we took and iterate the BUFFER — a transacting A:Vyto reads as unchanged,
        //     and only an emptiness that OUTLASTS the hold is believed and torn down.  The probe above
        //      still logs every raw gap, so this stays honest: the log says how often it saves us.
        return worlds_hold(out)
    }
    const worlds_hold = hold_list<TheC>()
    let lastWorldsN: number | undefined = undefined   // DIAGNOSTIC — strip with the life ladder
    let lastWorldObj: TheC | null = null

    // a bar press: `o` is an ACT (o-mark the newest moment); every other word is a toggle —
    //  on rides as 1-or-absent, deleted not zeroed (the snapped-boolean law, kept as habit
    //   even in an off-snap world).
    function press(w: TheC, b: TheC) {
        if (b.sc.kind === 'act') { (H as House).Vyto_omark?.(w); return }
        if (b.sc.on) delete b.sc.on
        else b.sc.on = 1
        b.bump_version()
    }

    function sentence(o: TheC): string {
        const bits = [`reads ${o.sc.reads}`]
        if (o.sc.decides) bits.push(`decides ${o.sc.decides}`)
        if (o.sc.writes)  bits.push(`writes ${o.sc.writes}`)
        return bits.join(' — ')
    }

    // ── the viewport: one root scope, the fixed frame Vyto_solve cuts against ──────────────
    //  Everything below is UItime render matter: springs are plain JS (not $state — they churn
    //   60×/s and Svelte should not track every velocity nudge), and the template reads a paint
    //    snapshot published through the paint_tick counter (the idiomatic Svelte-5 "compute in a
    //     function that reads a tracked tick" pattern).  Nothing here writes the model.
    // PHONE-FIRST FRAME (the human 2026-08-07: "so that Vyto can be fullscreened and everything within
    //  it gets pronounced with just the right focus", phone-first).  The frame was a fixed 800×450 — 16:9
    //   LANDSCAPE — and the SVG holds that aspect at width:100%, so on a portrait phone the whole glass
    //    collapsed into a letterbox strip across the middle of the screen with the cells squeezed inside
    //     it.  A voronoi cut has no intrinsic orientation, so the fix is not to rescale it but to cut
    //      against the shape you are actually looking through: the frame now FOLLOWS THE STAGE'S ASPECT.
    //  DRIVEN WORLDS ARE PINNED to the old 800×450.  A Book's layout must not depend on the size of the
    //   window it happens to run in — that would make every Vyto fixture a function of the runner tab's
    //    geometry, which is the definition of a flaky gate.  So the aspect is read only on the live page
    //     (humdinger), and every Book cuts the same rectangle it always did: no fixture can move.
    const FRAME_LONG = 800, FRAME_SHORT = 450
    let vw_w = $state(FRAME_LONG), vw_h = $state(FRAME_SHORT)
    // THE ASPECT PICK (the human 2026-08-08: "lets have some aspect ratios to flip through (dropdown)
    //  in Vytui to enforce some kind of min-height").  The measured `auto` path below kept landing on
    //   ratio 0.35 — the hard clamp FLOOR — on the live page: the first pixels ever taken of a live
    //    glass came back 800×280, the letterbox strip the phone-first work was supposed to end.  So
    //     give the shape a CHOICE beside the measurement, and let the picked ratio BE the min-height:
    //      the svg is `width:100%; height:auto`, so a 4:3 viewBox renders 0.75×width tall by
    //       construction.  (A pixel `min-height` would be the wrong fix — it letterboxes gutters
    //        AROUND an unchanged cut, and "the cut must follow the hole" is the whole §0.2(d) lesson.)
    //  A THIRD WRITER OF THE FRAME, ROUTED THROUGH THE SAME CHOKEPOINT.  fit_frame is the only place
    //   vw_w/vw_h are written, publish_frame the only place the model hears about it — the pick adds a
    //    branch inside fit_frame and NO new path, which is what keeps the Book guarantee intact: the
    //     humdinger gate at the top of fit_frame still returns first on every runner, so a driven world
    //      is never stamped and Vyto_solve cuts the same literal 800×450 it always did.
    //  Long edge stays 800 so the model's absolute AREA_BASE algebra keeps its range (a 9:16 pick is
    //   450×800, portrait, same long edge).  Tall picks are capped in CSS (.viewport max-height) and
    //    the measure pass converts through the 'meet' scale, so a letterboxed svg stays honest.
    const ASPECTS: [string, number, number][] = [
        ['auto',  0,   0  ],   // measure the hole — today's behaviour, byte-identical
        ['21:9',  800, 343],
        ['16:9',  800, 450],
        ['3:2',   800, 533],
        ['4:3',   800, 600],
        ['1:1',   800, 800],
        ['9:16',  450, 800],
    ]
    let aspect_pick = $state('auto')
    const frame_of = (): Pt[] => [{ x: 0, y: 0 }, { x: vw_w, y: 0 }, { x: vw_w, y: vw_h }, { x: 0, y: vw_h }]
    // THE SOLVE FRAME AND THE CUT FRAME MUST BE THE SAME RECTANGLE (Vyto_todo §0.2(d), 2026-08-08).
    //  `Vyto_solve` cut against a hardcoded [0,0,800,450] while this renderer cuts against
    //   vw_w × vw_h, which follows the stage aspect.  On a portrait phone fit_frame yields ~446×800,
    //    so the model placed seeds with x up to 800 into a 446-wide cut; a seed outside the cut clips
    //     to poly.length < 3 → null → the cell draws as a 6px disc at an off-viewBox coordinate, i.e.
    //      invisible.  So hand the model the rectangle actually being looked through.  `.c`, never
    //       encoded — the field itself cannot reach a snap.
    //  BOOK SAFETY, which is the whole constraint on this fix: the ONLY caller is fit_frame, which
    //   returns before touching anything unless `top_House().c.humdinger`.  A driven world is
    //    therefore never stamped at all, `w.c.vw_frame` stays undefined there, and Vyto_solve falls
    //     back to the same literal 800×450 rectangle it always cut.  (The .g side is written so the
    //      whole override — frame AND the seed clamp that comes with it — sits inside `if (w.c.vw_frame)`,
    //       so the driven path is not merely equal, it is unreachable.)
    //  Stamps the world whose stage was measured, not every world: vw_w/vw_h are component-wide (one
    //   Vytui renders the whole column of worlds), which is a pre-existing simplification this change
    //    neither relies on nor worsens.
    function publish_frame(w?: TheC | null) {
        if (!w) return
        const f: any = (w.c as any).vw_frame
        if (f && f.w === vw_w && f.h === vw_h) return
        ;(w.c as any).vw_frame = { w: vw_w, h: vw_h }
        // a reshaped frame is a re-solve, and nothing else would ask for one: `.c` bumps no version,
        //  so without this poke the model would keep the targets it cut for the old rectangle until
        //   the next unrelated stir.
        ;(H as any).Vyto_stir_soon?.(w)
    }
    // measure the stage and re-cut the frame when the shape of the hole changes.  Quantised to whole
    //  viewBox units and ignored under a 2% wobble, so a scrollbar appearing or an address bar sliding
    //   away cannot retrigger a full relayout on every frame.
    function fit_frame(el: Element | null, w?: TheC | null) {
        if (!el || !(H as any)?.top_House?.()?.c?.humdinger) return
        // stamp first: a world whose stage has only just mounted needs the STANDING frame even when
        //  the measure below changes nothing (and publish_frame no-ops when it is already stamped).
        publish_frame(w)
        const r = el.getBoundingClientRect()
        if (!(r.width > 0)) return
        // MEASURE THE HOLE, NOT THE THING IN IT.  `.stage` has no height of its own — the SVG inside it
        //  is width:100% height:auto, so the stage's height IS the aspect we just set. Measuring it
        //   would feed the frame back into itself: a fixed point at whatever it started as, which on a
        //    portrait phone means it never leaves landscape. So the WIDTH comes from the stage (that is
        //     real, the page lays it out) and the HEIGHT from the space actually left on screen below
        //      the stage's top edge. Fullscreen is the easy case — there the stage is sized 100vw/100vh
        //       by CSS, so its own box is already independent and honest.
        const full = typeof document !== 'undefined' && !!document.fullscreenElement
        let nw: number, nh: number
        // FULLSCREEN BEATS THE PICK.  Fullscreen means "fill THIS screen" and the stage's own box is
        //  honest there (CSS sizes it 100vw/100vh), so measuring is strictly better than any ratio a
        //   dropdown could name — and the ResizeObserver restores the pick on the way back out.  The
        //    pick governs the in-page stage, which is the shape that was starving.
        const picked = aspect_pick !== 'auto' && !full
            ? ASPECTS.find(a => a[0] === aspect_pick)
            : undefined
        if (picked) {
            nw = picked[1]; nh = picked[2]
        } else {
            const availW = r.width
            const availH = full ? r.height : Math.max(120, (window.innerHeight || 0) - r.top - 8)
            if (!(availH > 0)) return
            const portrait = availH > availW
            const ratio = Math.min(1, Math.max(0.35, portrait ? availW / availH : availH / availW))
            const long = FRAME_LONG, short = Math.max(200, Math.round(long * ratio))
            nw = portrait ? short : long; nh = portrait ? long : short
        }
        if (Math.abs(nw - vw_w) / vw_w < 0.02 && Math.abs(nh - vw_h) / vw_h < 0.02) return
        vw_w = nw; vw_h = nh
        // A RESHAPED FRAME INVALIDATES AN ENGAGED CAMERA: the rect was cut against the old rectangle and
        //  its aspect lock no longer matches, so walk everyone home rather than leave a view stranded on
        //   coordinates the frame may no longer contain.  (cam_step then glides the disengaged camera to
        //    the new reference pose, so this reads as the glass zooming out to show its new shape.)
        if (engaged.size) { for (const ww of [...engaged.keys()]) { engaged.delete(ww); kick(ww) } ; paint_tick++ }
        publish_frame(w)
    }
    // the pick changed: re-run the ONE writer against every mounted stage.  `stageEls` is the registry
    //  reg_stage already keeps for the measure pass (declared further down; this only ever runs from an
    //   event handler, long after init).  fit_frame does the rest — the 2% guard, the vw_w/vw_h write,
    //    publish_frame's stamp and its Vyto_stir_soon poke, so the model re-cuts against the new
    //     rectangle and clamps any seed the reshape stranded outside it.  Flipping the dropdown IS the
    //      first effect: the whole glass visibly re-flows into the new shape.
    function repick_aspect(v: string) {
        aspect_pick = v
        for (const [w, el] of stageEls) fit_frame(el, w)
    }
    // THE KNIFE-EDGE, resolved (Vyto_todo §0.2(a), decided 2026-08-08).  This floor and the model's
    //  rewrite tolerance (`EPS = 0.5`, Vyto.g Solve law 1) were THE SAME NUMBER, so every target
    //   rewrite was by construction ≥ the not-calm threshold: one sub-pixel solve wriggle bought a
    //    full spring convergence (~20-40 frames) before calm could re-accumulate, and any source
    //     stirring faster than ~0.5s pinned the rAF loop at 60fps until the 240-frame watchdog.
    //  They are different questions — "did it move enough to matter" (model) vs "is it still"
    //   (renderer) — so they get different numbers with a real gap: the calm floor sits 2.5× the
    //    rewrite tolerance, so a lone rewrite at the model's threshold lands INSIDE calm and the
    //     streak survives it.  Sustained real motion (> this floor) animates exactly as before.
    //  Pixel truth is NOT loosened: an ordinary settle now LANDS the springs (jump_to_target at the
    //   strike, the same landing parked/hidden/watchdog already trust), so the glass rests byte-exact
    //    on the model within one frame of striking — the floor only decides when to stop easing, never
    //     where the cells end up.  Renderer-only; driven Books are parked and never enter this path.
    const CALM_EPS = 1.25     // settle displacement floor, px — MUST stay > the model's rewrite EPS
    const DRIFT_EPS = 0.25    // settle wall-vertex drift floor, px/frame
    const SETTLE_FRAMES = 8   // consecutive calm frames before a settle strikes (~130ms @60fps)
    // ANTI-FREEZE WATCHDOG (2026-07-29): a hard ceiling on CONTINUOUS rAF motion.  No matter what
    //  pathology keeps a world "moving" (the vertex-count flicker that used to pin drift→never-settle,
    //   a target that chases itself, a NaN), the loop MUST land within this many frames — force the
    //    jump-to-target, strike settle, and SHOUT once (the human: "get clearly fatal about insanity").
    //     ~4s @60fps: far beyond any real settle (<1s), so a healthy layout never trips it; a sick one
    //      can no longer peg the main thread → freeze the tab → kill the peer heartbeat.
    const MAX_MOTION_FRAMES = 240
    const GAP = 2.2           // the breath between cells (shapes.md §0)

    // kp/ks are the LAST INTEGRATED calm strengths for this spring's two channels (position, size),
    //  cached by integrate_world so the settle test can skip a PINNED channel without re-running
    //   Vyto_calm_held (a real query) a second time per cell per frame.  Optional because a spring
    //    minted by `adopt` has not been integrated yet; `?? 1` at the read sites treats an
    //     un-integrated spring as free, which is what it was before it had these fields at all.
    type Spring = { x: number, y: number, r: number, vx: number, vy: number, vr: number, kp?: number, ks?: number }
    // key: a TREE-unique identity (tok at the root, parentKey>tok below) — springs, lift, and the
    //  keyed {#each} are all keyed by it, because a mirror tok is only LOCALLY unique (two byte-
    //   identical cousins share a tok).  depth/hasKids drive the nested look: a cell that is a scope
    //    (its children tile it) suppresses its OWN label + face and renders as a bare frame.
    type PaintCell = { tok: string, key: string, depth: number, hasKids: boolean,
                       ident: string, x: number, y: number, r: number,
                       kind: 'poly' | 'disc', d: string, departing: boolean, lift: boolean,
                       bx: number, by: number, bw: number, bh: number, clip: string,
                       face: any | null, source: TheC | null, row: TheC,
                       fx: '' | 'arrive' | 'erupt', fxi: number, fit: number }

    // ── THE MOLD BOX: INSCRIBED, NOT BOUNDING (2026-08-09) ─────────────────────────────────────────
    //  The owner, looking at the live glass: *"they're still utterly on top of each other, not much info
    //   for how their Component is shaped?"* — and the capture says exactly why.  A mold was placed at the
    //    cell's AABB (`bbox_of`), and **voronoi bounding boxes overlap heavily** even though the cells
    //     themselves tile perfectly: a slanted wall means each neighbour's box reaches well into the
    //      other's territory.  Add the standing "let them overflow" choice (ledger #4) and the faces land
    //       on top of one another — the radio player lying across the Diag cell, the Haul panel over
    //        Transfer.  It also made the cell shape say NOTHING about its component, because the box a
    //         component filled was never the cell.
    //  So mold to the largest axis-aligned rectangle that FITS INSIDE the polygon.  Two convex cells are
    //   disjoint, so their inscribed rectangles are disjoint too — **the overlap becomes impossible rather
    //    than discouraged**, which is worth more than any z-ordering or pointer-events rule (both of which
    //     this glass already tried).  Anchored at the centroid, holding the AABB's aspect, binary-searched
    //      on scale: for a CONVEX polygon containing all four corners is containment, so the test is exact.
    //  Power cells are convex by construction (an intersection of half-planes), which is what makes this
    //   sound; a degenerate or non-convex input simply converges to something small and still inside.
    //  MEMOISED ON THE POLY REFERENCE.  The wall memo hands back the SAME array when a scope's inputs have
    //   not changed, so a settled glass re-derives nothing at all and a moving one pays ~14 cheap
    //    iterations per cell — the same discipline that keeps the wall cut itself off a calm frame.
    //  BOX AWARENESS (the owner 2026-08-09: *"it's not stretching the Components into the ENTIRE cell too
    //   well. it needs some kind of box awareness that's evading us since ages"*).  The first cut of this
    //    inscribed a rectangle with the CELL's aspect and then shrank the component into it — so nothing
    //     in the chain ever asked what shape the COMPONENT wanted, and a wide player dropped into a tall
    //      cell sat small in a box of the wrong proportions with air all round it.
    //  So inscribe at the COMPONENT's aspect: the largest rectangle of ratio `want` that fits this cell.
    //   Then the component fills its box exactly — one uniform scale, no letterboxing inside the seat, no
    //    wasted cell.  `want` comes from the same measured natural box the floor runs on (`need_w/need_h`),
    //     so the measurement finally drives the SHAPE of the seat and not merely its area.  Falls back to
    //      the cell's own aspect before anything has been measured, which is the old behaviour exactly.
    const inscribeMemo = new WeakMap<Pt[], { want: number, box: { bx: number, by: number, bw: number, bh: number } }>()
    const INSCRIBE_INSET = 1.5      // viewBox units of air between a face and its own wall
    function inscribed_of(poly: Pt[], want?: number): { bx: number, by: number, bw: number, bh: number } {
        const bb0 = bbox_of(poly)
        const aspect = want && want > 0 && isFinite(want) ? want : (bb0.bh > 0 ? bb0.bw / bb0.bh : 1)
        const had = inscribeMemo.get(poly)
        if (had && Math.abs(had.want - aspect) < 0.01) return had.box
        // the search rectangle carries the WANTED ratio; only its scale is solved for
        const bb = { bx: bb0.bx, by: bb0.by, bw: aspect >= 1 ? bb0.bw : bb0.bh * aspect,
                                             bh: aspect >= 1 ? bb0.bw / aspect : bb0.bh }
        let cx = 0, cy = 0
        for (const p of poly) { cx += p.x; cy += p.y }
        cx /= poly.length; cy /= poly.length
        const inside = (x: number, y: number) => {
            let hit = false
            for (let i = 0, j = poly.length - 1; i < poly.length; j = i++) {
                const a = poly[i], b = poly[j]
                if ((a.y > y) !== (b.y > y) && x < ((b.x - a.x) * (y - a.y)) / (b.y - a.y) + a.x) hit = !hit
            }
            return hit
        }
        const fits = (t: number) => {
            const hw = (bb.bw * t) / 2 + INSCRIBE_INSET, hh = (bb.bh * t) / 2 + INSCRIBE_INSET
            return inside(cx - hw, cy - hh) && inside(cx + hw, cy - hh)
                && inside(cx + hw, cy + hh) && inside(cx - hw, cy + hh)
        }
        // `hi` starts above 1 so a rectangle of the wanted ratio can grow to fill a cell that is BIGGER
        //  than the natural box — otherwise the component could never stretch into the whole cell, which
        //   is the complaint this is here to answer.  The bisection still only ever reports what fits.
        let lo = 0, hi = 4
        if (!fits(0)) { const z = { bx: cx, by: cy, bw: 0, bh: 0 }; inscribeMemo.set(poly, { want: aspect, box: z }); return z }
        if (fits(hi)) lo = hi
        else for (let i = 0; i < 16; i++) { const m = (lo + hi) / 2; if (fits(m)) lo = m; else hi = m }
        const w = bb.bw * lo, h = bb.bh * lo
        const box = { bx: cx - w / 2, by: cy - h / 2, bw: w, bh: h }
        inscribeMemo.set(poly, { want: aspect, box })
        return box
    }

    // THE WALL AS A CLIP — the cell polygon expressed in PERCENTAGES of its own bounding box, which is
    //  exactly the space a CSS `clip-path: polygon()` resolves against.  So the mold can be handed the
    //   cell's whole extent (the component finally has the room) while the wall still decides where it
    //    stops — no pixel measurement, no overlay-sync drift, the same percentage contract the molds have
    //     always used.  Corners are sampled off the ROUNDED path so the clip is as curvey as the wall it
    //      follows, rather than a hard polygon inside a soft cell.
    //  Rounded to 1dp so a calm glass re-emits a byte-identical string and Svelte never touches it.
    function clip_of(poly: Pt[], bb: { bx: number, by: number, bw: number, bh: number }): string {
        if (!(bb.bw > 0) || !(bb.bh > 0) || poly.length < 3) return ''
        const n = poly.length
        const pts: string[] = []
        const put = (x: number, y: number) =>
            pts.push((((x - bb.bx) / bb.bw) * 100).toFixed(1) + '% ' + (((y - bb.by) / bb.bh) * 100).toFixed(1) + '%')
        for (let i = 0; i < n; i++) {
            const v = poly[i], p = poly[(i - 1 + n) % n], q = poly[(i + 1) % n]
            const d1x = v.x - p.x, d1y = v.y - p.y, l1 = Math.hypot(d1x, d1y) || 1
            const d2x = q.x - v.x, d2y = q.y - v.y, l2 = Math.hypot(d2x, d2y) || 1
            const r = Math.min(CORNER_R, l1 * 0.4, l2 * 0.4)
            const ax = v.x - (d1x / l1) * r, ay = v.y - (d1y / l1) * r
            const bx2 = v.x + (d2x / l2) * r, by2 = v.y + (d2y / l2) * r
            // sample the same quadratic the wall is drawn with, so clip and stroke agree
            put(ax, ay)
            for (let s = 1; s <= 3; s++) {
                const t = s / 4, u = 1 - t
                put(u * u * ax + 2 * u * t * v.x + t * t * bx2, u * u * ay + 2 * u * t * v.y + t * t * by2)
            }
            put(bx2, by2)
        }
        return 'polygon(' + pts.join(',') + ')'
    }

    // the axis-aligned bounding box of a cell polygon (viewBox units) — the OUTER extent of a cell.
    //  Still the starting point for the inscribed box above (it fixes the aspect), and still what a
    //   departing disc reports; it is no longer what a face is molded to.
    function bbox_of(poly: Pt[]): { bx: number, by: number, bw: number, bh: number } {
        let minx = Infinity, miny = Infinity, maxx = -Infinity, maxy = -Infinity
        for (const p of poly) {
            if (p.x < minx) minx = p.x
            if (p.x > maxx) maxx = p.x
            if (p.y < miny) miny = p.y
            if (p.y > maxy) maxy = p.y
        }
        return { bx: minx, by: miny, bw: Math.max(0, maxx - minx), bh: Math.max(0, maxy - miny) }
    }

    // the memo key for one scope's cut — order-preserving (keys ride beside their coordinates), so a
    //  hit guarantees polys[i] belongs to live[i].  Quantum 0.01px: a sub-centipixel wriggle reuses
    //   the standing walls (visually identical; the spring disp still judges settle off the raw floats).
    function cut_sig(framePoly: Pt[], keys: string[], seeds: Pt[], radii: number[], gap: number): string {
        let s = String(gap)
        for (const p of framePoly) s += '|' + Math.round(p.x * 100) + ',' + Math.round(p.y * 100)
        for (let i = 0; i < keys.length; i++)
            s += '§' + keys[i] + '@' + Math.round(seeds[i].x * 100) + ',' + Math.round(seeds[i].y * 100) + '~' + Math.round(radii[i] * 100)
        return s
    }

    // MOLD SEATING (the human 2026-08-08: the UI bits "should be really properly shoved in there... it
    //  should be able to simulate a bit of spatial things").  A face is seated by its cell's position in
    //   the frame: off-centre cells angle INWARD, like the curved wall of a videogame menu, and a hovered
    //    cell pops toward the camera.  A tilt of 6° is deliberately small — the point is for the glass to
    //     read as a physical arrangement of panels, not to make text hard to read at the edges.
    //  APPENDED TO THE EXISTING PER-CELL STYLE STRING, and that is the whole cost argument: the mold's
    //   left/top/width/height percentages are already rebuilt every frame, so this adds one concat to a
    //    string that was being written anyway, and the transform itself composites on the GPU (no layout,
    //     no paint).  Rounded to 1dp so a CALM glass re-emits a byte-identical string and Svelte never
    //      touches the attribute — the same discipline plug_curve's 2dp rounding buys for the ants.
    //  translateZ is ALSO where the hover lift now lives: `.face-mold.lift`'s z-index stops working under
    //   `.depth`'s preserve-3d (Z position decides order in a 3D context), and a card physically rising
    //    toward the viewer is the better reading of "lifted" anyway.
    //  ⛔ THE TILT IS GONE (the owner 2026-08-09: *"the tilting around 'like a 3d menu' is silly, I don't
    //   care. I want... everything mozaic'd nicely"*).  It was a mis-reading of "looks like a fancy
    //    videogame menu" as perspective when what was wanted was a good MOSAIC — and a tilt actively
    //     fights a mosaic, because a tessellation reads as one surface and rotating each tile breaks the
    //      shared edges that make it one.  Removed rather than gated: there is no configuration in which
    //       a tilted tile helps, and the adversarial review was right that leaving retired features
    //        threaded through the hot path is how this file got to 2000 lines.
    //  The function stays as the one seam where a mold's own transform belongs, so the hover lift has
    //   somewhere to live — and `preserve-3d`'s z-index consequence stays documented at the CSS.
    function mold_seat(cell: PaintCell): string {
        return cell.lift ? ' transform: translateZ(12px);' : ''
    }

    // (clip_of removed: the "let them overflow" occlusion revert stopped reading cell.clip, so the
    //  per-cell clip-path string is no longer computed — the coloured <path class="cell"> polygon is the
    //   visible cell wall now.  The `clip` field stays on PaintCell as always-'' until the renderer refactor
    //    sweeps it.)

    // per-cell colour from Matstyle (the human: "colour each of them somehow"): mainkey → a jewel
    //  ground via matstyle_ground (the Style subagent seeded the organs + a deterministic string-hash
    //   for any future mainkey).  Guarded — if Matstyle isn't mixed on yet it returns null and the cell
    //    keeps its default .cell.faced fill, so this can only ADD colour, never regress.
    const cell_ground = (cell: any): { bg: string, color: string, border: string } | null => {
        try {
            const sc = cell?.source?.sc
            if (!sc) return null
            const mk = Object.keys(sc)[0]
            return (H as any)?.matstyle_ground?.(mk) ?? null
        } catch { return null }
    }

    // per-world render state, keyed by the world C — plain, not reactive.
    const springs      = new Map<TheC, Map<string, Spring>>()   // tok → sprung scalars
    const prevWalls    = new Map<TheC, Map<string, Pt[]>>()      // last frame's polys, for drift
    // THE WALL MEMO (Vyto_todo THE PIN P1 · Vyto_perf_todo §1): each scope's power cut, keyed by the
    //  exact inputs that shape it — membership ⊕ sprung seeds ⊕ radii ⊕ frame ⊕ gap, quantised to
    //   0.01px (two orders under DRIFT_EPS, so a reused cut is the same cut to the eye AND to the
    //    drift judge).  A paint whose scope inputs stand still reuses the standing polys, so the
    //     resident/hidden-tab churn (adopt paints on every model bump) costs O(M) string checks, not
    //      O(M²) half-plane clips — and a SETTLED glass cuts no walls at all.  w.c.wall_cuts counts
    //       only REAL cuts (off-snap `.c` — the VytoMemo Book's probe); stale scope keys prune each
    //        build so a reshaped tree cannot pool dead polys.
    const wallMemo     = new Map<TheC, Map<string, { sig: string, polys: (Pt[] | null)[] }>>()
    const settleCount  = new Map<TheC, number>()                 // consecutive calm frames
    const motionFrames = new Map<TheC, number>()                 // frames of continuous motion (watchdog)
    const settledState = new Map<TheC, boolean>()                // struck-this-rest latch
    const lifted       = new Map<TheC, string>()                 // the hovered (z-lifted) tok
    const paintMap     = new Map<TheC, PaintCell[]>()            // the published snapshot
    // DIAGNOSTIC (2026-07-30, KeepFace mount/destroy thrash — Download_stall_handover.md "Evening 8"):
    //  mirror row + spring both proven stable by sibling logs, yet the Face keeps remounting on ANY
    //   bump of the source Keep. Last remaining candidate: face_of(row)'s returned {comp,source} pair
    //    going null, or `source` (the prop identity `<Face n={cell.source}>` binds) changing reference
    //     between renders — either would remount even with a stable key. Gated to Keep rows.
    const lastFaceOkByKey = new Map<string, any>()
    // GATE-FLIP probe (2026-08-02): the ◈◈ REAL serial climbs → genuine keyed-each teardown, but every
    //  face/source/key check keyed by n.key is BLIND to a key flip (a changed key makes prev undefined →
    //   silent).  Key THIS one by the STABLE ident (mk:val, immune to tok/join churn) and capture EVERY
    //    input to the two structural gates ({#if show_viewport} and {#if cell.face && !departing &&
    //     !hasKids}); log the first that flips.  One repro then NAMES the culprit instead of dumping.
    const lastGateByIdent = new Map<string, any>()
    // ── THE FX LEDGERS (the "things flying at you and erupting when people play it" ask) ──────
    //  ARRIVE and ERUPT are ONE-SHOT CSS ANIMATIONS.  Nothing here drives them frame by frame: the
    //   renderer only decides CLASS MEMBERSHIP, and the browser's own clock plays the keyframes — the
    //    same load-bearing choice the SMIL ants made, and for the same reason.  A settled glass PARKS
    //     and never repaints, so anything animated from our rAF loop would freeze exactly when the
    //      layout calmed, which is most of the time.
    //  `seenAt` decides an arrival by FIRST-EVER SIGHTING OF A KEY, not by DOM presence — and that is
    //   the load-bearing detail.  This glass has a documented keyed-remount churn (the KeepFace hunt:
    //    a cell can leave and re-enter the {#each} without the thing it stands for having gone
    //     anywhere), and a presence test would replay the fly-in every time that happened.  Pruned
    //      beside `sp.delete` in adopt, so departed keys cannot pool and a returning cell CAN re-arrive.
    //  Classes flip on, then off ~1s later, on a frame that is animating regardless: an arrival or an
    //   eruption always coincides with spring motion, so a build is guaranteed inside the window and no
    //    timer is needed to take the class away again.
    const seenAt   = new Map<TheC, Map<string, number>>()   // key → first build ts (arrival ledger)
    const eruptAt  = new Map<TheC, Map<string, number>>()   // tok → focus-flip ts (eruption ledger)
    const lastFocus = new Map<TheC, any>()                  // last w.c.focus_tok, to detect the flip
    const ARRIVE_MS = 900
    const ERUPT_MS  = 700
    // THE FX SWEEP — one shot, self-clearing (2026-08-09, found by looking at a live capture).  An fx class
    //  is removed by the NEXT build, and a build only happens when something moves; a glass that arrives
    //   and immediately settles therefore keeps `arrive` on every cell forever.  Visually that is harmless
    //    (the animation has finished and its `both` fill is holding the rest state) — the live capture of
    //     the owner's tab showed all five cells still wearing it — but a stale class would mis-stagger the
    //      NEXT batch's `animation-delay` and it lies to anyone reading the DOM.  So when a build hands out
    //       fx, arm exactly ONE timer to repaint after the longest window closes.  Not a heartbeat: it is
    //        armed only by an actual fx and it disarms itself, so a quiet glass still owns no timer.
    let fx_sweep: any = 0
    function fx_sweep_soon(ms: number) {
        if (fx_sweep) return
        fx_sweep = setTimeout(() => { fx_sweep = 0; paint_tick++ }, Math.max(60, ms))
    }

    // ── THE CAMERA (the human 2026-08-08: "things need to be navigable") ────────────────────────
    //  A rect over the model's frame, sprung on the loop that already exists, published as the svg's
    //   viewBox.  Click a cell to fly to it; click it again (or Esc, or ⤴) to walk back out.
    //  WHY A CAMERA AND NOT A RELAYOUT — this is the standing ruling, not a preference.  The owner
    //   ruled "zoom = reframe YES" with the rider *"we must not run out of memory when someone zooms in
    //    infinitely"*, and `processes.md §6` fixes the division of labour: the layout owns POSITIONS AND
    //     ROOM, focus is *"a VIEW transform over the graph's positions, so still not a relayout"*.  A
    //      camera obeys both by construction: the model is not consulted, nothing re-solves, and the
    //       resident state is ONE RECT per world — O(visible), never O(zoom-history).  There is no zoom
    //        stack: walking out recomputes the parent rect from the standing tree, so infinite drilling
    //         cannot accumulate anything to run out of.
    //  ASPECT-LOCKED, and this is load-bearing rather than cosmetic: `preserveAspectRatio="xMidYMid
    //   meet"` letterboxes a viewBox whose aspect differs from the element box, and the face molds are
    //    positioned in PERCENTAGES of that element box — so an off-aspect camera would slide every face
    //     off its cell.  Engage targets are therefore padded OUT to the frame's aspect before use.
    //  It contributes to the loop's `moving` verdict and to NOTHING else: never to disp, never to drift,
    //   never to settleCount.  A glide must not delay `Vyto_settle` or nudge the spool's yore — the
    //    camera is view, and view is not model.  Live-page only, so a driven Book never leaves the
    //     reference pose and renders the same full-frame viewBox its fixtures recorded.
    type Cam = { x: number, y: number, w: number, h: number,
                 tx: number, ty: number, tw: number, th: number,
                 vx: number, vy: number, vw: number, vh: number }
    const cams    = new Map<TheC, Cam>()
    const engaged = new Map<TheC, string>()      // world → the engaged cell's tree-unique key
    const CAM_PAD = 1.08                         // a little air around an engaged cell
    const ref_cam = (): { x: number, y: number, w: number, h: number } => ({ x: 0, y: 0, w: vw_w, h: vw_h })
    function cam_of(w: TheC): Cam {
        let c = cams.get(w)
        if (!c) {
            const r = ref_cam()
            c = { x: r.x, y: r.y, w: r.w, h: r.h, tx: r.x, ty: r.y, tw: r.w, th: r.h, vx: 0, vy: 0, vw: 0, vh: 0 }
            cams.set(w, c)
        }
        return c
    }
    // the camera the TEMPLATE reads — off paint_tick, like every other paint fact.  Falls back to the
    //  reference pose so a world that has never been engaged allocates nothing and reads byte-identically
    //   to the pre-camera renderer (`x:0 y:0 w:vw_w h:vw_h` is exactly the old `0 0 {vw_w} {vw_h}`).
    function cam_view(w: TheC): { x: number, y: number, w: number, h: number } {
        void paint_tick
        return cams.get(w) ?? ref_cam()
    }
    // pad a rect out to the frame's aspect (grow the short axis; never crop, so the whole cell always
    //  stays inside the shot), then clamp inside the frame without changing the size that was chosen.
    function aspect_fit(bx: number, by: number, bw: number, bh: number): { x: number, y: number, w: number, h: number } {
        const fa = vw_w / vw_h
        let w = Math.max(24, bw * CAM_PAD), h = Math.max(24, bh * CAM_PAD)
        if (w / h > fa) h = w / fa; else w = h * fa
        // never zoom out past the whole frame
        if (w > vw_w || h > vw_h) { w = vw_w; h = vw_h }
        let x = bx + bw / 2 - w / 2, y = by + bh / 2 - h / 2
        x = Math.max(0, Math.min(vw_w - w, x))
        y = Math.max(0, Math.min(vw_h - h, y))
        return { x, y, w, h }
    }
    function cam_to(w: TheC, r: { x: number, y: number, w: number, h: number }) {
        const c = cam_of(w)
        c.tx = r.x; c.ty = r.y; c.tw = r.w; c.th = r.h
        kick(w); paint_tick++
    }
    // ENGAGE — fly to a cell.  Clicking the ALREADY-engaged cell walks out, so the same gesture is both
    //  "in" and "out" and needs no second control to discover.
    // ⛔ THE CAMERA IS RETIRED AS THE NAVIGATION VERB (the owner 2026-08-09: *"I think no zooming but
    //  only shifting emphasis, is the way to do it all"*).  Engagement is gated off here rather than
    //   deleted in the same breath as the fit work, because the camera threads through nine call sites
    //    (viewBox, every mold's transform, the settle verdict, the watchdog reset, the measure gate,
    //     fit_frame's reshape, a window keydown, and the cell's role/tabindex) and unpicking it belongs
    //      in its own pass with its own regression — not tangled into a live rendering fix.
    //  Gating it here kills the misbehaviour NOW: with molds clipped, a click on a face's dead space fell
    //   through to the cell and flew the camera, in a mode that has been ruled out.
    //  WHAT REPLACES IT is already built and already live: `Vyto_focus` swells the attended cell by
    //   FOCUS_BOOST and compresses its siblings — the glass re-flows and nothing leaves the screen.
    //    Clicking should SHIFT EMPHASIS, and that is the next station, not a camera with a smaller flight.
    const CAMERA_RETIRED = true
    function cam_engage(w: TheC, cell: PaintCell) {
        if (CAMERA_RETIRED) return
        if (!live_page() || parked(w)) return
        if (engaged.get(w) === cell.key) { cam_out(w); return }
        engaged.set(w, cell.key)
        cam_to(w, aspect_fit(cell.bx, cell.by, cell.bw, cell.bh))
    }
    // WALK OUT — one level per press: an engaged nested cell rises to its PARENT scope's rect, a top
    //  cell (or anything whose parent has left the paint) returns to the reference pose.  Recomputed
    //   from the standing paint, never popped off a stack — that is the memory law in one line.
    function cam_out(w: TheC) {
        const key = engaged.get(w)
        if (!key) { cam_to(w, ref_cam()); return }
        const cut = key.lastIndexOf('>')
        const parentKey = cut > 0 ? key.slice(0, cut) : ''
        const parent = parentKey ? (paintMap.get(w) ?? []).find(c => c.key === parentKey) : null
        if (parent) {
            engaged.set(w, parent.key)
            cam_to(w, aspect_fit(parent.bx, parent.by, parent.bw, parent.bh))
        } else {
            engaged.delete(w)
            cam_to(w, ref_cam())
        }
    }
    // one integration step for the camera; returns whether it is still gliding.  Same closed-form
    //  critically-damped step and same ω as the cells, so the glass and the camera move as one system.
    //  THE CALM FLOOR SCALES WITH ZOOM: CALM_EPS is a MODEL-unit floor, and at 4× magnification 1.25
    //   model units is 5 screen pixels — landing there would be a visibly sloppy stop.  Judge in screen
    //    terms (floor × the zoom ratio) and then land exactly.
    function cam_step(w: TheC, dt: number): boolean {
        const c = cams.get(w); if (!c) return false
        // a DISENGAGED camera tracks the reference pose, so an aspect flip or a window resize glides
        //  home instead of stranding the view on a rect the frame no longer contains.
        if (!engaged.has(w)) { const r = ref_cam(); c.tx = r.x; c.ty = r.y; c.tw = r.w; c.th = r.h }
        const omega = 6 / grawave(w)
        step_channel(c, 'x', 'vx', c.tx, 1, omega, dt)
        step_channel(c, 'y', 'vy', c.ty, 1, omega, dt)
        step_channel(c, 'w', 'vw', c.tw, 1, omega, dt)
        step_channel(c, 'h', 'vh', c.th, 1, omega, dt)
        const zoom = c.tw > 0 ? c.tw / vw_w : 1
        const floor = CALM_EPS * Math.max(0.08, zoom)
        const off = Math.max(Math.abs(c.x - c.tx), Math.abs(c.y - c.ty), Math.abs(c.w - c.tw), Math.abs(c.h - c.th))
        if (!(off >= floor)) {
            // land exactly, then stop — same "every settle lands" discipline the cells got in §0.2(a),
            //  and it is what lets a disengaged camera be byte-identical to the pre-camera renderer.
            c.x = c.tx; c.y = c.ty; c.w = c.tw; c.h = c.th
            c.vx = 0; c.vy = 0; c.vw = 0; c.vh = 0
            // a landed camera at the reference pose is indistinguishable from no camera: drop it so the
            //  common case allocates and reads nothing (cam_view falls back to ref_cam()).
            const r = ref_cam()
            if (!engaged.has(w) && c.x === r.x && c.y === r.y && c.w === r.w && c.h === r.h) cams.delete(w)
            return false
        }
        return true
    }
    const lastKeepEmit = new Map<TheC, Set<string>>()   // last build's emitted Keep-cell keys, per world
    const lastShow = new Map<TheC, boolean>()            // show_viewport's last value per world (stage {#if} toggle detector)
    let paint_tick = $state(0)     // the template reads this to re-pull paintMap
    let raf_id = 0                 // 0 = loop stopped
    let last_ts = 0
    // local UItime chrome state (never snapped): the organ panel is DEV/inspection readout —
    //  collapsed by default, revealed by the bar toggle.  Room to grow into real layout controls.
    let show_organs = $state(false)

    const grawave = (w: TheC) => Number((w.sc as any).grawave_duration) || 0.4
    const commissioned = (w: TheC) => !!(w.c as any).commission

    // ── the mirror TREE (nested render) ────────────────────────────────────────────────────
    //  A Node wraps one mirror row with its tree-unique `key` and its drawable `kids`.  The walk is
    //   GATED twice, so a flat glass is byte-and-cost identical to before:
    //    · descent only when `w.c.nested` — a flat commission never enters the recursion, so `roots`
    //       carry empty `kids` and the layout cuts one power diagram over the top rows exactly as it did;
    //    · a kid is drawn only if the MODEL solved it (`.c.T`) — Vyto_solve_scope writes `.c.T` on the
    //       kids it tessellates, so depth is exactly the solve's reach and a deep-but-unsolved mirror
    //        subtree (a scan that walked into an organ's guts) is never descended into.
    type Node = { row: TheC, tok: string, key: string, depth: number, kids: Node[] }
    function tree_nodes(w: TheC): { roots: Node[], all: Node[] } {
        const roots: Node[] = []
        const all: Node[] = []
        const mirror: any = (w.c as any).mirror
        if (!mirror) return { roots, all }
        const nested = !!(w.c as any).nested
        const build = (row: TheC, parentKey: string, depth: number): Node | null => {
            const tok: string = (row.c as any).tok
            if (!tok) return null
            const key = parentKey ? parentKey + '>' + tok : tok
            const node: Node = { row, tok, key, depth, kids: [] }
            all.push(node)
            if (nested && depth < 40) {
                for (const k of row.o() as TheC[]) {
                    if (!(k.c as any).T && !(k.sc as any).departing) continue
                    const kn = build(k, key, depth + 1)
                    if (kn) node.kids.push(kn)
                }
            }
            return node
        }
        for (const row of mirror.o() as TheC[]) { const n = build(row, '', 0); if (n) roots.push(n) }
        return { roots, all }
    }

    // THE IDENT — `Haul:10.Yara`, not `Haul:1` (the owner 2026-08-09: *"we had some way of saying the
    //  'Haul:10.Yara' or whatever it is (it should be more serial id?)"*).
    //  A mainkey's VALUE is often just the presence marker `1` (`{Transfer:1}`, `{Diag:1}`, `{Haul:1}` on
    //   a fresh keep), so `mk:value` said nothing about WHICH one you were looking at — and several of
    //    these are many-per-glass.  Three parts now, each dropped when it has nothing to say:
    //     · the MAINKEY — what the thing IS (CLAUDE.md: the mainkey is the type tag);
    //     · a SERIAL — a small stable number per identity, so two of the same kind are tellable apart at
    //        a glance and stay tellable across repaints (assigned first-seen, held on the tok);
    //     · a NAME — the mainkey's own value when it carries one (a %Haul wears its TITLE: `Heist.g`
    //        mints `{ Haul: entry.sc.title, seed, pub, state }`), else the shortest identifying scalar
    //         to hand (`id`/`seed`/`of`, trimmed — an id8 is plenty to disambiguate on a glass).
    //  The serial is per-WORLD and lives on `.c` — it is a way of SAYING the thing, not a fact about it,
    //   so it must never reach a snap.
    const serials = new Map<TheC, Map<string, number>>()
    function serial_of(w: TheC | null, tok: string): number {
        if (!w) return 0
        let m = serials.get(w); if (!m) { m = new Map(); serials.set(w, m) }
        let n = m.get(tok); if (n == null) { n = m.size + 1; m.set(tok, n) }
        return n
    }
    function ident_of(row: TheC, w?: TheC | null, tok?: string): string {
        const sc: any = row?.sc; if (!sc) return '?'
        const mk = Object.keys(sc)[0]; if (!mk) return '?'
        const v = sc[mk]
        // a bare presence marker is not a name; anything else the mainkey carries IS one
        let name = (v == null || v === 1 || v === '1') ? '' : String(v)
        if (!name) {
            const alt = sc.id ?? sc.seed ?? sc.of ?? sc.title ?? sc.name
            if (alt != null) name = String(alt)
        }
        if (name.length > 18) name = name.slice(0, 17) + '…'
        const n = tok != null ? serial_of(w ?? null, tok) : 0
        return n ? `${mk}:${n}${name ? '.' + name : ''}` : `${mk}${name ? ':' + name : ''}`
    }

    // THE UNDER-LAYER (the human 2026-08-08: "Components won't be snapped by your picture-taker, but
    //  perhaps a lot of it shall fit in the background, or there could always be some bare standard
    //   representation in the background which is shadowed over by the UI bits shoved in there").
    //  THE PROBLEM IT SOLVES IS A WITNESS PROBLEM, and it is the F1 failure mode of THE PIN by name.
    //   The only camera this glass has is `runner_shot --svg`, which serialises `.vyto svg.viewport` —
    //    and the faces are HTML in a SIBLING div, so no capture has ever contained a single one of
    //     them.  Worse, a FACED cell suppressed its ident, so the first pixels ever taken of a live
    //      glass (2026-08-08) were five mute polygons with ZERO labels: the picture could not say what
    //       any organ was.  So every faced cell now ALSO draws its bare self in SVG, under the face:
    //        on screen a low-ink watermark the real UI is shoved in over the top of; in a capture, the
    //         whole glass still states what it is.  This pays LAW A forward for every face ever added.
    //  `sc` ONLY — the TreeFace discipline.  The mirror row IS the bare standard representation (it is
    //   what Scan already distilled the source to), so this reads what is already in hand: no `.c`
    //    walking (the House, the parent chain and every cycle live there), no new queries, no timers.
    //  THE GUTS (the owner 2026-08-09: *"and then we spill the specific guts"*).  The edge label says
    //   WHICH thing this is; the guts are what it actually holds — its scalars, spilled down the cell as
    //    the standing matter the Component is laid over.  One `k:v` per line so the eye can scan a column
    //     rather than parse a run-on, and the caller decides how many lines the cell has room for, so a
    //      small cell shows a couple and a big one shows its whole state.
    //  `sc` ONLY, and the mainkey is skipped because the label above already carries it.  Session
    //   furniture is dropped — `dontSnap` and friends describe the PLUMBING, not the thing (the live
    //    capture was showing `dontSnap:1` under three separate organs, which is noise wearing the costume
    //     of information).
    const GUT_SKIP = new Set(['face', 'departing', 'active', 'created_at', 'new', 'not_found', 'dontSnap'])
    function under_guts(row: TheC, max: number): string[] {
        const sc: any = row?.sc; if (!sc || max <= 0) return []
        const keys = Object.keys(sc)
        const out: string[] = []
        for (let i = 1; i < keys.length && out.length < max; i++) {
            const k = keys[i]
            if (GUT_SKIP.has(k)) continue
            const v = sc[k]
            if (v == null || typeof v === 'object') continue
            let s = String(v)
            if (s.length > 22) s = s.slice(0, 21) + '…'
            out.push(k + ' ' + s)
        }
        return out
    }

    // THE PARKED-RUN GATE (Book determinism depends on it).  While a Story run DRIVES this
    //  world the renderer is inert — target changes jump straight to target and NEVER strike a
    //   settle: a renderer-struck settle mid-run would bump the spool's yore_n at a wall-clock-
    //    random instant and flake the recorded VytoStaple fixtures.  The flag is `run.c.driving`
    //     (Story.svelte's story_drive), and the run particle hangs off the Run House as
    //      `Run.c.run`; w.c.Run IS that Run House — so the truth is one hop deeper than the
    //       dictated w.c.Run.c.driving.  When the run finishes (driving false) the gate lifts and
    //        normal animation resumes.
    function parked(w: TheC): boolean {
        const run: any = (w.c as any).Run?.c?.run
        return !!(run && run.c && run.c.driving)
    }

    // the spring target for a row: the model's T on `.c`.  A departing row's T is left standing
    //  by the solver (it was filtered out of the cut) — the renderer ramps its radius to 0, so a
    //   departure is a disc shrinking at its last place.
    function target_of(row: TheC): { x: number, y: number, r: number } | null {
        const T: any = (row.c as any).T
        if (!T) return null
        if ((row.sc as any).departing) return { x: T.x, y: T.y, r: 0 }
        return { x: T.x, y: T.y, r: T.r }
    }

    // the closed-form critically-damped step, calm.md §5 VERBATIM (any dt, unconditionally
    //  stable — no Euler, no clamp).  ω_eff = k·ω folds Calm's grant in; k===0 pins the channel
    //   (no integration, velocity decays to 0) so a held seed does not chase.
    function step_channel(s: any, key: string, vkey: string, T: number, k: number, omega: number, dt: number) {
        if (k <= 0) { s[vkey] = s[vkey] * Math.exp(-omega * dt); return }
        const oe = k * omega
        const y  = s[key] - T
        const B  = s[vkey] + oe * y
        const e  = Math.exp(-oe * dt)
        s[key]  = T + (y + B * dt) * e
        s[vkey] = (s[vkey] - oe * B * dt) * e
    }

    function path_of(poly: Pt[]): string {
        return 'M' + poly.map(p => p.x.toFixed(2) + ',' + p.y.toFixed(2)).join('L') + 'Z'
    }

    // MEMBRANES (the human 2026-08-08: "biological feels", and §0.0's standing ruling that the whole
    //  program should look like "a child's pasta and paint artwork" — a MADE thing, not a dashboard).
    //  BOUNDED-RADIUS CORNERS, not midpoint smoothing — and the first version got this wrong, which the
    //   rasterised capture caught before it shipped (2026-08-09).  Smoothing through edge MIDPOINTS turns a
    //    4-vertex cell into an ellipse: measured coverage of a 3-cell frame fell to 82%, every corner eaten
    //     and a visible gap opened between neighbours.  That breaks the one thing a power diagram
    //      guarantees — that the cells TILE ("everything not some-not-everything") — so the softness has to
    //       live only NEAR each vertex.  Each corner is cut back by `r` along both its edges and bridged
    //        with a quadratic through the vertex; the straight middles of the edges survive, so two
    //         neighbours still share a wall exactly.  `r` is capped at 40% of the shorter adjacent edge, so
    //          a thin sliver cell degrades to nearly-straight instead of self-intersecting.
    //  WHAT THIS DELIBERATELY DOES NOT TOUCH: only the `d` STRING changes.  bbox_of, the drift judge,
    //   the wall memo's cut_sig, power_cells and every nested frame keep operating on the RAW polys, so
    //    geometry, settle, the need floor and the fold all see the same numbers they always did.  Cells
    //     are still the model's cells; they merely stop being drawn as knives.
    //  UNGATED, Books included.  A fixture is a dige of the C tree, and no `d` string reaches one — the
    //   pixel witness greps classes and counts (`.cell`, `.ident`, path count), never path bytes.  The
    //    doc row says so, because "ungated" is a claim that has to be defensible, not convenient.
    const CORNER_R = 26          // model units — the softness of a cell corner
    function path_round(poly: Pt[]): string {
        const n = poly.length
        if (n < 3) return path_of(poly)
        const f = (v: number) => v.toFixed(2)
        // per vertex: where the rounding STARTS on the inbound edge (a) and RESUMES on the outbound (b)
        const a: Pt[] = [], b: Pt[] = []
        for (let i = 0; i < n; i++) {
            const v = poly[i], p = poly[(i - 1 + n) % n], q = poly[(i + 1) % n]
            const d1x = v.x - p.x, d1y = v.y - p.y, l1 = Math.hypot(d1x, d1y) || 1
            const d2x = q.x - v.x, d2y = q.y - v.y, l2 = Math.hypot(d2x, d2y) || 1
            const r = Math.min(CORNER_R, l1 * 0.4, l2 * 0.4)
            a.push({ x: v.x - (d1x / l1) * r, y: v.y - (d1y / l1) * r })
            b.push({ x: v.x + (d2x / l2) * r, y: v.y + (d2y / l2) * r })
        }
        let d = 'M' + f(b[0].x) + ',' + f(b[0].y)
        for (let i = 1; i < n; i++) d += 'L' + f(a[i].x) + ',' + f(a[i].y) + 'Q' + f(poly[i].x) + ',' + f(poly[i].y) + ' ' + f(b[i].x) + ',' + f(b[i].y)
        d += 'L' + f(a[0].x) + ',' + f(a[0].y) + 'Q' + f(poly[0].x) + ',' + f(poly[0].y) + ' ' + f(b[0].x) + ',' + f(b[0].y)
        return d + 'Z'
    }

    // build the paint snapshot from the CURRENT sprung positions: re-derive the walls per frame
    //  (a cell is where its neighbours leave room, so the walls must move with them), then a
    //   PaintCell per spring.  A null poly (crowded out) renders a small disc; a departing row is
    //    excluded from the cut and renders a shrinking disc.  The lifted (hovered) cell sorts last
    //     so it paints on top — re-asserted every build, so a keyed re-mint never loses the lift.
    //  `walk` is the caller's tree_nodes() result, handed in so ONE walk serves a whole frame:
    //   integrate_world needs `.all` (to key rows) and this needs `.roots`, and they were two
    //    separate depth-first walks of the same tree back to back (Vyto_todo §0.2(c)2 — three per
    //     frame with the probe on).  Nothing between the two mutates the tree: the integration loop
    //      writes only spring scalars, and tree_nodes reads mirror rows, `.c.tok` and `.c.T`.
    //       Optional, because paint_world/adopt call build_cells without one.
    function build_cells(w: TheC, walk?: { roots: Node[], all: Node[] }): { cells: PaintCell[], curWalls: Map<string, Pt[]> } {
        const cells: PaintCell[] = []
        const curWalls = new Map<string, Pt[]>()
        const sp = springs.get(w)
        if (!sp) return { cells, curWalls }
        const tn = walk ?? tree_nodes(w)
        const roots = tn.roots
        const liftKey = lifted.get(w)
        // ── THE PROBES ARE OFF BY DEFAULT (2026-08-08) ──
        //  The GATE-FLIP probe and the OMISSION DETECTOR below both ran UNCONDITIONALLY, every build,
        //   i.e. up to 60×/s: the detector alone did a THIRD full `tree_nodes(w)` walk plus a filter,
        //    two Set constructions and two diff loops, and the gate probe allocates a 6-field object
        //     and does six comparisons per Haul cell per frame. They are diagnostics; they found the
        //      remount mechanism they were written for, and that knowledge is worth keeping — so they
        //       are GATED, not deleted. `H.top_House().c.vyto_probe = 1` in a console turns them back
        //        on for one session. Kept because the human's complaint is battery, not features:
        //         "I don't want to melt people's phones if possible."
        const PROBE = !!((H as any)?.top_House?.()?.c?.vyto_probe)
        // the fx window for this build.  LIVE PAGE AND UNPARKED ONLY, and not optional: a driven Book
        //  must render the picture its fixtures recorded, and a decoration keyed on wall-clock age is
        //   exactly the kind of thing that makes a step's dige depend on when it ran.  A runner gets
        //    fx:'' on every cell, so the classes are absent from its DOM entirely.
        const fx_on = live_page() && !parked(w)
        const now_fx = fx_on ? Date.now() : 0
        if (fx_on && !seenAt.has(w)) seenAt.set(w, new Map())
        const seen = fx_on ? (seenAt.get(w) as Map<string, number>) : null
        const erupts = eruptAt.get(w)
        let fx_i = 0
        let fx_left = 0     // ms until the longest-running fx window closes — arms the one-shot sweep below
        if (!wallMemo.has(w)) wallMemo.set(w, new Map())
        const wm = wallMemo.get(w) as Map<string, { sig: string, polys: (Pt[] | null)[] }>
        const seenScopes = new Set<string>()

        // lay out ONE sibling group inside `framePoly`: cut the power diagram from the siblings' sprung
        //  seeds, emit a PaintCell each (in lifted-last order so the hovered cell + its whole subtree
        //   paint on top), then recurse into each cell — a child scope's frame IS its parent's cell poly,
        //    tiled with gap 0 (a scope FILLS its parent; the visual GAP is a top-cut property only).  Parent-
        //     before-child emit order = SVG paint order, so children sit above their container.
        const layout = (nodes: Node[], framePoly: Pt[], gap: number, scopeKey: string): void => {
            const live: Node[] = []
            const seeds: Pt[] = []
            const radii: number[] = []
            const keys: string[] = []
            for (const n of nodes) {
                const s = sp.get(n.key)
                if (!s || (n.row.sc as any).departing) continue
                live.push(n); keys.push(n.key); seeds.push({ x: s.x, y: s.y }); radii.push(s.r)
            }
            // the memo consult: unchanged inputs reuse the standing polys (same references — the drift
            //  judge shortcuts them to zero); changed inputs cut fresh and count one REAL cut.
            seenScopes.add(scopeKey)
            const sig = cut_sig(framePoly, keys, seeds, radii, gap)
            const had = wm.get(scopeKey)
            let polys: (Pt[] | null)[]
            if (had && had.sig === sig) {
                polys = had.polys
            } else {
                polys = power_cells(framePoly, seeds, radii, gap)
                wm.set(scopeKey, { sig, polys })
                ;(w.c as any).wall_cuts = (((w.c as any).wall_cuts as number) || 0) + 1
            }
            const polyByKey = new Map<string, Pt[] | null>()
            for (let i = 0; i < live.length; i++) {
                polyByKey.set(live[i].key, polys[i])
                if (polys[i]) curWalls.set(live[i].key, polys[i] as Pt[])
            }
            // emit order: lifted sibling last (its subtree follows, so it all paints on top).
            const order = [...nodes].sort((a, b) => (a.key === liftKey ? 1 : 0) - (b.key === liftKey ? 1 : 0))
            for (const n of order) {
                const s = sp.get(n.key)
                if (!s) continue
                const row = n.row
                const ident = ident_of(row, w, n.tok)
                const lift = liftKey === n.key
                const f = face_of(row)
                const face = f ? f.comp : null
                const source = f ? f.source : null
                // the cell's fx for this build: a first sighting SPROUTS (and the index staggers the
                //  batch, so a commission blooms outward instead of flashing at once); a focus flip
                //   ERUPTS.  Arrival wins — a cell cannot both be born and erupt in the same instant.
                let fx: '' | 'arrive' | 'erupt' = ''
                let fxi = 0
                // ENVELOPE DOWN — the third answer, after spill and clip both failed (2026-08-09).
                //  Spill put the components back on top of each other and over the edge of the page; clip
                //   cut the HTML in half.  Both are wrong because both keep the component at its natural
                //    size and argue about what to do with the excess.  The owner named the right verb —
                //     *"we need much better enveloping things down when there's no room on the screen"* —
                //      so when a component does not fit its seat, SHRINK IT until it does.  Nothing is
                //       hidden, nothing escapes its cell, and the glass stays a tiling.
                //  This is what "actually measuring" means, and the previous test was not it: `tight`
                //   compared an AREA against an AREA, which cannot answer a FIT question (a 200×40 face
                //    "fits" a 90×90 seat by area and is amputated in reality).  Ask the real question, per
                //     axis, against the measured natural box.
                //  It also gives "things become icons when crushed down" as a CONTINUUM rather than a
                //   special case: the scale falls smoothly with the seat, and below a legibility floor the
                //    face is not drawn at all and the cell keeps only its edge label — the icon register.
                const nw = (row.c as any).need_w as number | undefined
                const nh = (row.c as any).need_h as number | undefined
                let fit = 1
                let clipPoly = ''
                if (seen) {
                    let born = seen.get(n.key)
                    if (born == null) { born = now_fx; seen.set(n.key, born) }
                    if (now_fx - born < ARRIVE_MS) { fx = 'arrive'; fxi = fx_i++; fx_left = Math.max(fx_left, ARRIVE_MS - (now_fx - born)) }
                    else {
                        const er = erupts?.get(n.tok)
                        if (er != null && now_fx - er < ERUPT_MS) { fx = 'erupt'; fx_left = Math.max(fx_left, ERUPT_MS - (now_fx - er)) }
                    }
                }
                if (PROBE && String(ident).indexOf('Haul:') === 0) {
                    // capture EVERY structural-gate input, keyed by the stable ident so a KEY flip is
                    //  itself caught (prev survives a tok change).  faceNull|face|source feed the inner
                    //   {#if cell.face}; departing|hasKids feed its other two clauses; key feeds the each.
                    const gate = { key: n.key, faceNull: !f, face, source,
                                   departing: !!(row.sc as any).departing, hasKids: n.kids.length > 0 }
                    const prev = lastGateByIdent.get(ident)
                    if (prev) {
                        const d: string[] = []
                        if (prev.key !== gate.key)             d.push(`KEY ${prev.key}→${gate.key}`)
                        if (prev.faceNull !== gate.faceNull)   d.push(`FACE_NULL ${prev.faceNull}→${gate.faceNull}`)
                        if (prev.face !== gate.face)           d.push('FACE_REF changed')
                        if (prev.source !== gate.source)       d.push('SOURCE_REF changed')
                        if (prev.departing !== gate.departing) d.push(`DEPARTING ${prev.departing}→${gate.departing}`)
                        if (prev.hasKids !== gate.hasKids)     d.push(`HASKIDS ${prev.hasKids}→${gate.hasKids}`)
                        if (d.length) console.log('◈ Vyto GATE FLIP', ident, '::', d.join(' | '))
                    }
                    lastGateByIdent.set(ident, gate)
                }
                if ((row.sc as any).departing) {
                    const r = Math.max(0, s.r)
                    cells.push({ tok: n.tok, key: n.key, depth: n.depth, hasKids: false, ident,
                                 x: s.x, y: s.y, r, kind: 'disc', d: '', departing: true, lift,
                                 bx: s.x - r, by: s.y - r, bw: 2 * r, bh: 2 * r, clip: clipPoly, face, source, row, fx, fxi, fit })
                    continue
                }
                const poly = polyByKey.get(n.key)
                if (poly) {
                    // a SCOPE's children tile its interior, so a scope keeps the outer box (its kids do the
                    //  inscribing); a leaf that actually mounts a face gets the inscribed box so the face
                    //   sits inside its own wall and cannot reach a neighbour's.
                    const hasKids0 = n.kids.length > 0
                    // THE WHOLE CELL, CLIPPED TO ITS WALL (2026-08-09) — the owner: *"it's not stretching
                    //  the Components into the ENTIRE cell too well. it needs some kind of box awareness
                    //   that's evading us since ages."*  An INSCRIBED rectangle can never answer that: a
                    //    rectangle inside a voronoi cell measured 33-35% of the cell's area, so a component
                    //     confined to one is small in a big cell BY CONSTRUCTION, no matter how the
                    //      rectangle is chosen.  So hand the face the cell's FULL extent and stop it
                    //       reaching a neighbour with a CLIP to the actual wall — which is exactly what
                    //        THE PIN's P5 reserved ("restore the polygon clip once the floor lands"), and
                    //         it is only safe now because the floor and the envelope scale both exist.
                    const bb = bbox_of(poly)
                    const hasKids = hasKids0
                    if (!hasKids0 && face) clipPoly = clip_of(poly, bb)
                    // one uniform scale to fill that seat.  Because the seat now carries the component's
                    //  OWN ratio, both axes agree and the component fills its box edge to edge — it
                    //   stretches UP into a roomy cell and envelopes DOWN into a crushed one, same rule.
                    if (face && nw && nh && bb.bw > 0 && bb.bh > 0) {
                        fit = Math.min(bb.bw / nw, bb.bh / nh)
                        fit = Math.max(0.2, Math.min(6, +fit.toFixed(3)))
                    }
                    cells.push({ tok: n.tok, key: n.key, depth: n.depth, hasKids, ident,
                                 x: s.x, y: s.y, r: s.r, kind: 'poly', d: path_round(poly), departing: false, lift,
                                 bx: bb.bx, by: bb.by, bw: bb.bw, bh: bb.bh, clip: clipPoly, face, source, row, fx, fxi, fit })
                    if (hasKids) layout(n.kids, poly, 0, n.key)
                } else {
                    cells.push({ tok: n.tok, key: n.key, depth: n.depth, hasKids: false, ident,
                                 x: s.x, y: s.y, r: 6, kind: 'disc', d: '', departing: false, lift,
                                 bx: s.x - 6, by: s.y - 6, bw: 12, bh: 12, clip: clipPoly, face, source, row, fx, fxi, fit })
                }
            }
        }
        layout(roots, frame_of(), GAP, '')
        // OMISSION DETECTOR (2026-08-02): the real remount mechanism is a Keep cell being OMITTED from
        //  `cells` (no spring → `layout` continues past it), so its key LEAVES the keyed {#each} and
        //   KeepFace is torn down; back next build → remount.  The GATE-FLIP probe sits AFTER the
        //    `if(!s)continue` so it is blind to this.  Diff the emitted Keep-key SET vs last build and
        //     log ONLY the transitions — exactly one line per remount — with WHY (walk / spring / T).
        //  GATED (2026-08-08) — see the PROBE note at the top of build_cells.  It used to open with a
        //   THIRD full `tree_nodes(w)` walk, every frame; it now reads the frame's one shared walk
        //    (`tn`), so even switched on it costs a filter rather than a re-walk.
        if (PROBE) {
            const sp2 = springs.get(w)
            const tnKeep = tn.all.filter(nn => nn.key.indexOf('Haul:') === 0)
            const emitted = new Set(cells.filter(c => c.key.indexOf('Haul:') === 0).map(c => c.key))
            const lastEmit = lastKeepEmit.get(w) ?? new Set<string>()
            for (const k of lastEmit) if (!emitted.has(k)) {
                const node = tnKeep.find(nn => nn.key === k)
                console.log('◈ Vyto CELL LEFT each →', k, '| inWalk=', !!node, 'spring=', !!sp2?.get(k), 'T=', !!(node && target_of(node.row)))
            }
            for (const k of emitted) if (!lastEmit.has(k)) console.log('◈ Vyto CELL ENTERED each →', k)
            lastKeepEmit.set(w, emitted)
        }
        for (const k of [...wm.keys()]) if (!seenScopes.has(k)) wm.delete(k)
        // an fx is in flight ⇒ guarantee one build after it expires, so the class comes back off even if
        //  the glass settles in the meantime.  See fx_sweep_soon: one timer per burst, never a heartbeat.
        if (fx_left > 0) fx_sweep_soon(fx_left + 40)
        return { cells, curWalls }
    }

    function paint_world(w: TheC) {
        const { cells, curWalls } = build_cells(w)
        paintMap.set(w, cells)
        prevWalls.set(w, curWalls)
        // WHICH STIR THIS PICTURE SHOWS — the one outward signal Story's waitVyto can wait on.
        //  Note what it is NOT: settle.  During a run the glass is PARKED (parked(w) === "a Story run
        //   drives"), and a parked world jump-lands its springs and never animates, so it never strikes
        //    a settle at all — a settle-based gate would take the ceiling on every step.  What a driving
        //     Book actually wants is "has the glass re-solved and repainted since the step changed the
        //      model", and that is exactly stir→paint.  Stamped here because this is the single site
        //       every path funnels through (parked jump, hidden-tab jump, the visible resident path).
        //  `.c`, never encoded: view timing is not model state and must not reach a fixture.
        ;(w as any).c.vyto_painted_stir = ((w.c as any).stir_n ?? 0)
    }

    // land every spring on its target at rest — the t→∞ limit of the closed form (calm.md §8's
    //  hidden-tab jump, and the parked-run jump).
    function jump_to_target(w: TheC) {
        const sp = springs.get(w); if (!sp) return
        for (const n of tree_nodes(w).all) {
            const s = sp.get(n.key); if (!s) continue
            const T = target_of(n.row); if (!T) continue
            s.x = T.x; s.y = T.y; s.r = T.r; s.vx = 0; s.vy = 0; s.vr = 0
        }
    }

    // one integration frame for one world; returns whether it is still in motion.  Parked worlds
    //  never integrate — they hold jumped-to-target and strike no settle.
    function integrate_world(w: TheC, dt: number): boolean {
        const sp = springs.get(w)
        if (!sp || sp.size === 0) return false
        if (parked(w)) { jump_to_target(w); paint_world(w); return false }   // no camera on a driven world
        // ONE TREE WALK PER FRAME (2026-08-08).  This walk and build_cells' were the same depth-first
        //  walk of the same tree, run back to back with nothing between them that touches the tree —
        //   the integration loop below writes spring scalars only.  Hand it down instead.
        const tn = tree_nodes(w)
        const rowByKey = new Map<string, TheC>()
        for (const n of tn.all) rowByKey.set(n.key, n.row)
        const omega = 6 / grawave(w)
        for (const [key, s] of sp) {
            const row = rowByKey.get(key)
            const T = row ? target_of(row) : null
            if (!T) continue
            // position governs x and y; size governs r (calm.md §5).  k defaults free if the
            //  method is absent (a bare House with no gen'd Vyto).
            const kp = (H as any).Vyto_calm_held?.(w, row, 'position') ?? 1
            const ks = (H as any).Vyto_calm_held?.(w, row, 'size') ?? 1
            // remember the pin state for the settle test below — a PINNED channel is not integrated
            //  (step_channel returns early on k <= 0), so its |s − T| can never shrink, and measuring
            //   it as displacement is measuring a distance nothing is trying to close.  Cached here
            //    rather than re-queried: Vyto_calm_held runs a real o({Hold:1}) query and this used to
            //     cost TWO per cell per frame in each loop.
            s.kp = kp
            s.ks = ks
            step_channel(s, 'x', 'vx', T.x, kp, omega, dt)
            step_channel(s, 'y', 'vy', T.y, kp, omega, dt)
            step_channel(s, 'r', 'vr', T.r, ks, omega, dt)
        }
        const { cells, curWalls } = build_cells(w, tn)
        paintMap.set(w, cells)
        // settle: max cell displacement (position and radius) and max derived-wall vertex drift.
        let disp = 0
        for (const [key, s] of sp) {
            const row = rowByKey.get(key); const T = row ? target_of(row) : null
            if (!T) continue
            // A PINNED CHANNEL MUST NOT COUNT AS DISPLACEMENT (2026-08-08).  `step_channel` returns
            //  early when k <= 0 — it bleeds velocity and does NOT integrate position — so a pinned
            //   spring's |s − T| is frozen at whatever it was.  Measuring it here meant the settle
            //    test was waiting for a gap that nothing on earth was closing.
            //  WHY IT FIRES CONSTANTLY IN PRACTICE: `Vyto_pointer_enter` pins on EVERY pointerenter,
            //   and the solver writes a pinned cell's T as its polygon CENTROID, which moves whenever
            //    any neighbour does.  So a pointer resting on a cell plus any model churn pinned the
            //     rAF loop at 60fps *forever* — the `▣⚠ forced settle after 240 frames` line in every
            //      console the human has sent, and a standing battery drain with nothing happening.
            //  Note this does not weaken the test: an UNPINNED channel is measured exactly as before,
            //   and a pin is by definition the user saying "hold this still", not "keep chasing it".
            if ((s.kp ?? 1) > 0) disp = Math.max(disp, Math.hypot(s.x - T.x, s.y - T.y))
            if ((s.ks ?? 1) > 0) disp = Math.max(disp, Math.abs(s.r - T.r))
        }
        let drift = 0
        const pw = prevWalls.get(w)
        for (const [tok, poly] of curWalls) {
            const prev = pw?.get(tok)
            // a cell ENTERING/LEAVING (no prev, or a vertex-count change as an oversized/undersized seed
            //  crosses a power-cell degeneracy) must NOT hard-fail settle.  Its SEED motion is already in
            //   `disp`; forcing drift→1e9 here was THE freeze bug — a dose-shrunk organ flickering
            //    null↔poly at the crowd-out threshold pinned drift high EVERY frame → settle never struck →
            //     rAF ran at 60fps forever → the tab froze → its beat stopped → the peer went dark ("the
            //      Sounditrons stop talking after a Heist is started").  Skip its wall drift; when its seed
            //       stops moving, `disp` settles it.  (Vyto_perf_todo §3.)
            if (prev === poly) continue   // a memo-reused wall is the SAME array — zero drift, free
            if (!prev || prev.length !== poly.length) continue
            for (let v = 0; v < poly.length; v++) drift = Math.max(drift, Math.hypot(poly[v].x - prev[v].x, poly[v].y - prev[v].y))
        }
        prevWalls.set(w, curWalls)
        // negated so a NON-finite disp/drift (a NaN that slipped past the radius clamp) counts as CALM and
        //  STOPS the loop, instead of `NaN < CALM_EPS === false` pinning requestAnimationFrame at 60fps forever
        //   (a dead-silent CPU burn that eventually OOM-kills the tab).  Finite frames behave identically.
        const calm_frame = !(disp >= CALM_EPS) && !(drift >= DRIFT_EPS)
        let cnt = (settleCount.get(w) ?? 0)
        cnt = calm_frame ? cnt + 1 : 0
        settleCount.set(w, cnt)
        // WATCHDOG: count continuous-motion frames; a settle resets it.  If the loop ever runs past the
        //  ceiling without landing, something is insane — LAND IT ANYWAY and shout, so a render pathology
        //   can never again peg the main thread.  (Reset only on a real settle, never from adopt, so this
        //    is a true ceiling on unbroken rAF spinning regardless of model churn re-arming targets.)
        // THE CAMERA STEPS HERE AND AFFECTS ONLY THE VERDICT BELOW.  It is deliberately downstream of
        //  every settle input (disp, drift, calm_frame are all already computed): a glide must keep the
        //   rAF loop alive so the view actually moves, and must NOT delay the settle strike, because a
        //    settle is a MODEL fact the spool and Story's waitVyto read.  View is not model.
        const cam_moving = cam_step(w, dt)
        const mf = (motionFrames.get(w) ?? 0) + 1
        if (cnt >= SETTLE_FRAMES || mf >= MAX_MOTION_FRAMES) {
            if (mf >= MAX_MOTION_FRAMES && cnt < SETTLE_FRAMES) {
                if (typeof console !== 'undefined') console.log('▣⚠ Vyto watchdog: forced settle after', mf,
                    'frames of unbroken motion — a cell never stopped moving (disp/drift pinned). Landing anyway.', { w })
            }
            // EVERY settle lands (2026-08-08, half of the CALM_EPS decision above): the ordinary strike
            //  used to leave springs wherever the calm streak caught them (≤EPS off), which was fine at
            //   0.5px and would not be at 1.25 — so land exactly, always, and the widened floor costs
            //    zero pixel truth.  One ≤CALM_EPS snap in one frame, imperceptible.
            jump_to_target(w); paint_world(w)
            motionFrames.set(w, 0)
            if (!(settledState.get(w) ?? false)) {
                settledState.set(w, true)
                if (!parked(w)) queueMicrotask(() => (H as any).Vyto_settle?.(w))   // §7: off the frame, once per transition
            }
            // the MODEL has landed and the settle has struck — but a camera still in flight needs the
            //  loop, so hand back its verdict rather than a flat false.  `settledState` keeps Vyto_settle
            //   to one firing per transition, so the extra frames re-strike nothing.
            return cam_moving
        }
        motionFrames.set(w, mf)
        return true
    }

    function frame(ts: number) {
        const dt = last_ts ? Math.max(0, (ts - last_ts) / 1000) : 1 / 60
        last_ts = ts
        let moving = false
        for (const w of springs.keys()) if (integrate_world(w, dt)) moving = true
        raf_id = moving ? requestAnimationFrame(frame) : 0
        if (!moving) last_ts = 0
        paint_tick++
    }

    function kick(w: TheC) {
        if (parked(w) || document.hidden) return
        if (raf_id === 0) { last_ts = 0; raf_id = requestAnimationFrame(frame) }
    }

    // adopt current targets: sync springs to the live member set, reset settle on a real move,
    //  and either jump (parked / hidden tab) or ensure the rAF loop is spinning.
    //  THE IDLE GATE (the resident-glass CPU fix): a resident world grapples LIVE organs whose
    //   VALUES churn every heartbeat (Stoker levels, Session counters, Heist), so this effect
    //    re-fires every stir — but the CELLS sit still (no dose ⇒ constant radii ⇒ the cut is a
    //     fixed point).  paint_tick MUST bump only when the geometry actually MOVES; an
    //      unconditional bump re-pulls viewport_cells and re-diffs all nine real-DOM faces every
    //       heartbeat (and each face, reading its live source, re-renders — the churn feeds
    //        itself: a core pinned on a standing picture).  So track `changed` and gate the bump.
    //         Faces stay live regardless: each reads its own source reactively, off paint_tick.
    function adopt(ws: TheC[]) {
        let changed = false
        for (const w of ws) {
            if (!commissioned(w)) continue
            if (!springs.has(w)) springs.set(w, new Map())
            const sp = springs.get(w) as Map<string, Spring>
            const present = new Set<string>()
            let moved = false
            // DIAGNOSTIC (2026-07-30, chasing the KeepFace mount/destroy thrash — see
            //  Download_stall_handover.md "Evening 8"): the mirror row is confirmed STABLE (a sibling
            //   Vyto.g log never re-mints/drops it), yet the Face keeps remounting once per trickle —
            //    so the churn must be HERE, in whether this row gets a spring each adopt() pass. Gated
            //     to Keep rows only.
            const sawHaul = new Set<string>()
            for (const n of tree_nodes(w).all) {
                if (n.key.indexOf('Haul:') === 0) sawHaul.add(n.key)
                const T = target_of(n.row)
                if (!T) {
                    if (n.key.indexOf('Haul:') === 0) console.log('◈ Vyto adopt: row.c.T MISSING for', n.key)
                    continue
                }
                present.add(n.key)
                let s = sp.get(n.key)
                if (!s) {
                    if (n.key.indexOf('Haul:') === 0) console.log('◈ Vyto adopt: NEW spring (entrance ramp) for', n.key, 'T=', JSON.stringify(T))
                    // a newcomer springs from x,y AT target with r 0 — the radius ramp IS the entrance.
                    sp.set(n.key, { x: T.x, y: T.y, r: 0, vx: 0, vy: 0, vr: 0 })
                    moved = true
                } else if (Math.hypot(s.x - T.x, s.y - T.y) > CALM_EPS || Math.abs(s.r - T.r) > CALM_EPS) {
                    moved = true
                }
            }
            for (const key of [...sp.keys()]) {
                if (key.indexOf('Haul:') === 0 && !sawHaul.has(key)) console.log('◈ Vyto adopt: row ABSENT from tree_nodes().all for', key, '(not just T-less — gone from the walk entirely)')
            }
            let removed = false
            for (const key of [...sp.keys()]) if (!present.has(key)) {
                if (key.indexOf('Haul:') === 0) console.log('◈ Vyto adopt: spring REMOVED for', key)
                sp.delete(key); removed = true
                // prune the arrival ledger with the spring: a key that genuinely leaves must be able to
                //  SPROUT again when it comes back, and the ledger must not grow without bound.
                seenAt.get(w)?.delete(key)
            }

            // THE ERUPTION TRIGGER — the model's own focus decision, noticed.  `Vyto_focus` swells the
            //  focused cell by FOCUS_BOOST and compresses its siblings (~88× in area), and `Radio_state`
            //   is the chokepoint that proposes it: DIGGING/OFF are the underworld, PLAYING is the panel.
            //    So the swell IS the eruption's body, already springing — this only stamps WHEN the flip
            //     happened so the paint can add the flash on top.  Which means "erupting when people play
            //      it" is not a new mechanism at all: it is the focus wire that has been live since
            //       2026-08-07, finally dressed.
            const ftok: any = (w.c as any).focus_tok
            if (lastFocus.get(w) !== ftok) {
                lastFocus.set(w, ftok)
                if (ftok != null && live_page() && !parked(w)) {
                    if (!eruptAt.has(w)) eruptAt.set(w, new Map())
                    ;(eruptAt.get(w) as Map<string, number>).set(String(ftok), Date.now())
                    changed = true      // the flash needs a paint even if no spring moved far enough
                }
            }

            // parked (a Story run drives) and hidden (a ?B= runner) keep painting unconditionally —
            //  their determinism and jump-landing depend on it, and neither is a visible CPU burn.
            if (parked(w)) { jump_to_target(w); paint_world(w); changed = true; continue }
            if (moved) { settleCount.set(w, 0); settledState.set(w, false) }
            if (document.hidden) {
                // rAF is frozen in a hidden tab (every ?B= runner): land at t→∞, paint, and strike
                //  settle synchronously (a jump-landing has no wriggle for SETTLE_FRAMES to debounce).
                jump_to_target(w); paint_world(w); changed = true
                if (moved) {
                    settleCount.set(w, SETTLE_FRAMES); settledState.set(w, true)
                    queueMicrotask(() => (H as any).Vyto_settle?.(w))
                }
            } else {
                // the VISIBLE resident path: only a real move or a membership change is worth a
                //  re-pull.  A move (re)starts the rAF loop, which paints every frame until settle;
                //   a bare removal needs one paint to drop the departed cell.
                if (moved && raf_id === 0) { last_ts = 0; raf_id = requestAnimationFrame(frame) }
                if (moved || removed) changed = true
            }
        }
        if (changed) paint_tick++
    }

    // ── THE MEASURE (Vyto_todo THE PIN P2 — the need floor's render half) ──────────────────
    //  After each template flush, read every leaf cell's NATURAL widget box and stamp it on the
    //   mirror row as `row.c.need_area` (viewBox units², off-snap `.c`) for Vyto_express to floor.
    //    Two widget kinds, both FEEDBACK-FREE (the Cytui:3256 discipline):
    //     · an ident label — SVG getBBox, already in viewBox units, intrinsic by nature (text never
    //        stretches to its cell);
    //     · a face — the face-scroll's firstElementChild offset box (a max-content face reads its
    //        intrinsic size whether it fits or overflows); a child whose width EQUALS the mold's is
    //         box-stretched (width:100%) and is SKIPPED — measuring it would feed the cell back to
    //          itself and spiral.  Stamps are GROW-ONLY with a 2% dead-band so the wall never
    //           flutters; each real stamp pokes Vyto_stir_soon so express re-floors on the model's
    //            own latch.  The whole pass runs ONLY on a need_floor world — a floor-free glass
    //             pays nothing (the additive-gate law, cost included).
    const stageEls = new Map<TheC, HTMLElement>()
    function reg_stage(el: HTMLElement, w: TheC) {
        stageEls.set(w, el)
        // watch the SHAPE of the hole, not just its size — fit_frame re-cuts the frame when the stage
        //  flips portrait/landscape (a phone rotating, or Vyto going fullscreen) and no-ops otherwise.
        //   Measured once up front so the first paint is already the right shape.
        fit_frame(el, w)
        let ro: ResizeObserver | null = null
        if (typeof ResizeObserver !== 'undefined') {
            ro = new ResizeObserver(() => fit_frame(el, w))
            ro.observe(el)
        }
        return { destroy() { ro?.disconnect(); if (stageEls.get(w) === el) stageEls.delete(w) } }
    }
    // fullscreen the stage (the human 2026-08-07: "so that Vyto can be fullscreened").  Toggles, and
    //  leans on the ResizeObserver above to re-cut the frame to whatever shape the screen turns out to
    //   be — so entering fullscreen on a portrait phone reshapes the cut, it does not just zoom it.
    //  Best-effort by design: the API rejects when the gesture isn't trusted or the browser forbids it
    //   (iOS Safari has no element fullscreen), and a refused fullscreen must not throw into the render.
    async function go_fullscreen(el: Element | null) {
        try {
            if (document.fullscreenElement) { await document.exitFullscreen(); return }
            await (el as any)?.requestFullscreen?.()
        } catch (e) { console.log('◈ Vyto fullscreen refused —', String((e as any)?.message ?? e)) }
    }
    function stamp_need(w: TheC, row: TheC, area: number) {
        if (!(area > 0)) return
        const cur = (row.c as any).need_area as number | undefined
        if (cur != null && area <= cur * 1.02) return
        ;(row.c as any).need_area = area
        ;(H as any).Vyto_stir_soon?.(w)
    }
    // THE NATURAL BOX, not just its area (2026-08-09).  `need_area` is a single scalar, so a cell could be
    //  floored to the right AREA and still hand a wide player a tall narrow seat — the doc names that as
    //   the reason the HTML gets cut off, and an area-vs-area "does it fit" test is meaningless for the
    //    same reason.  Keep the measured WIDTH and HEIGHT so the renderer can ask the only question that
    //     matters — does this component fit in this box, and if not by how much.  `.c`, never snapped.
    function stamp_box(row: TheC, nw: number, nh: number) {
        if (!(nw > 0) || !(nh > 0)) return
        const cw = (row.c as any).need_w as number | undefined
        const ch = (row.c as any).need_h as number | undefined
        if (cw != null && ch != null && nw <= cw * 1.02 && nh <= ch * 1.02) return
        ;(row.c as any).need_w = Math.max(cw ?? 0, nw)
        ;(row.c as any).need_h = Math.max(ch ?? 0, nh)
    }
    function measure_world(w: TheC) {
        if (!(w.c as any).need_floor) return
        // NOT WHILE ENGAGED.  The need floor is grow-only, and the honest contract is that a widget's
        //  natural box is measured in ONE viewing condition — the reference pose.  (A zoomed camera makes
        //   faces read smaller in model units, which the grow-only guard would simply discard, so this is
        //    belt and braces rather than a live bug; the point is that the floor must never become a
        //     function of where the user happened to be looking.)
        if (engaged.has(w) || cams.has(w)) return
        const stage = stageEls.get(w); if (!stage) return
        const svg = stage.querySelector('svg.viewport') as SVGSVGElement | null
        if (!svg) return
        const srect = svg.getBoundingClientRect()
        if (!(srect.width > 0) || !(srect.height > 0)) return
        // px → viewBox, VIA THE 'meet' SCALE, not the width ratio (2026-08-08).  `vw_w / srect.width`
        //  is only correct while the svg's ELEMENT BOX has the same aspect as its viewBox — true while
        //   the svg is `width:100%; height:auto`, and FALSE the moment a max-height caps a tall aspect
        //    (the pick's 1:1 / 9:16 letterbox horizontally, so srect.width includes gutters the drawing
        //     does not use).  Measured through the width ratio there, every face reads SMALLER than it
        //      is and `stamp_need` — grow-only — silently under-floors the cell.  `preserveAspectRatio
        //       ="xMidYMid meet"` scales by the MIN of the two ratios, so that is the honest conversion;
        //        when the aspects do match it degenerates to exactly the old number, so this is a
        //         no-op on the uncapped layout and a correctness fix on the capped one.
        const k = Math.min(srect.width / vw_w, srect.height / vw_h)
        if (!(k > 0)) return
        const sx = 1 / k, sy = 1 / k
        const byKey = new Map<string, PaintCell>()
        for (const c of paintMap.get(w) ?? []) byKey.set(c.key, c)
        // `:not(.under)` — the under-layer's watermark texts are NOT the cell's widget (the face is), so
        //  measuring them would floor a cell to the size of a label it draws BEHIND its real content.
        //   They also carry no `data-key`, so the byKey lookup below would already skip them; this is
        //    the explicit half of that, so the intent survives a future refactor of either side.
        for (const t of stage.querySelectorAll('text.ident:not(.under)')) {
            const cell = byKey.get((t as Element).getAttribute('data-key') ?? '')
            if (!cell || cell.departing) continue
            try {
                const bb = (t as SVGGraphicsElement).getBBox()
                stamp_need(w, cell.row, bb.width * bb.height)
            } catch { /* an unrendered node has no box — skip */ }
        }
        for (const m of stage.querySelectorAll('.face-mold')) {
            const cell = byKey.get((m as Element).getAttribute('data-key') ?? '')
            if (!cell || cell.departing) continue
            const scroll = (m as Element).querySelector('.face-scroll') as HTMLElement | null
            const child = scroll?.firstElementChild as HTMLElement | null
            if (!scroll || !child || typeof child.offsetWidth !== 'number') continue
            if (Math.abs(child.offsetWidth - scroll.clientWidth) <= 1) continue   // box-stretched — skip
            const nw = child.offsetWidth * sx, nh = child.offsetHeight * sy
            stamp_box(cell.row, nw, nh)
            stamp_need(w, cell.row, nw * nh)
        }
    }
    $effect(() => {
        void paint_tick
        // measure AFTER the flush carrying this paint (microtask chain — runs in hidden tabs too,
        //  where the whole runner lives); reads no tracked state, so no feedback into the effect.
        Promise.resolve().then(() => { for (const w of springs.keys()) measure_world(w) })
    })

    // the drive: THE REACTION IS THROWN OUT OF THE EFFECT (a trailing-edge setTimeout latch).
    //  Atime and UItime are NOT as cleanly gated as reactivity_docs implies — H.ave.vers and
    //   vyto_worlds()'s own H.ob/A.ob reads still leak Atime-frequency bumps — so chasing a
    //    perfectly gated signal is a losing game.  Instead keep the effect BODY trivial: subscribe
    //     broadly (so we never miss a change) and just re-arm a timer.  The heavy adopt runs in the
    //      setTimeout callback, OUTSIDE the reactive context, so (a) its reads take NO subscription
    //       and can't re-arm the effect (no feedback), and (b) a burst of N bumps folds into ONE
    //        adopt per REACT_MS window (the Vyto_stir_soon idiom, render side).  The rAF spring loop
    //         runs at 60fps BETWEEN windows, so motion stays smooth though targets refresh at ~8Hz.
    //          Hidden ?B= runners can't use the setTimeout latch (throttled to ~1s in a background
    //           tab) and a Book's determinism wants adopt prompt — but the OLD shortcut (adopt()
    //            straight from the effect body) ran it INSIDE the reactive context, so adopt's own
    //             reads (tree_nodes/target_of + Matstyle swatch autoviv on H.ave, which this effect
    //              reads) subscribed the effect to itself; a heist's husk churn then re-armed the
    //               effect from within its own run → effect_update_depth_exceeded (the human,
    //                2026-07-28: "spinning only while heisting").  Fix: run the hidden adopt in a
    //                 MICROTASK — outside the reactive context (no feedback, same as the visible
    //                  path) yet still prompt: queueMicrotask is NOT throttled in a bg tab and it
    //                   flushes before the next paint/snap, so Book determinism holds.
    let react_pending: any = 0
    let react_micro = false
    let react_alive = true
    const REACT_MS = 120
    function react_soon() {
        if (typeof document !== 'undefined' && document.hidden) {
            if (react_micro) return
            react_micro = true
            queueMicrotask(() => { react_micro = false; if (react_alive) adopt(vyto_worlds()) })
            return
        }
        if (react_pending) return
        react_pending = setTimeout(() => { react_pending = 0; adopt(vyto_worlds()) }, REACT_MS)
    }
    $effect(() => {
        // subscribe broadly — the body is O(1)-cheap, so a marching-readout here is harmless: the
        //  first fire arms the timer, every other fire in the window early-returns.
        void H?.ave?.vers
        for (const w of vyto_worlds()) {
            const mirror: any = (w.c as any).mirror
            if (mirror) void mirror.vers; else void w.vers
        }
        react_soon()
    })
    // ESC WALKS OUT — the key everyone already tries.  Window-level because the SVG cells are not
    //  focusable and giving them tabindex would put every cell in the page's tab order; live-page only,
    //   and it no-ops unless something is actually engaged, so it never swallows a key from anything else.
    $effect(() => {
        if (typeof window === 'undefined' || !live_page()) return
        const onkey = (e: KeyboardEvent) => {
            if (e.key !== 'Escape' || !engaged.size) return
            for (const w of [...engaged.keys()]) cam_out(w)
        }
        window.addEventListener('keydown', onkey)
        return () => window.removeEventListener('keydown', onkey)
    })
    // teardown: release the frame loop AND the pending reaction (calm.md §5's cancel-on-teardown).
    $effect(() => () => {
        react_alive = false
        if (raf_id) cancelAnimationFrame(raf_id); raf_id = 0
        if (react_pending) clearTimeout(react_pending); react_pending = 0
        if (fx_sweep) clearTimeout(fx_sweep); fx_sweep = 0
    })

    // ── template readers (each reads paint_tick so the snapshot re-pulls) ──────────────────
    function show_viewport(w: TheC): boolean {
        void paint_tick
        const r = show_viewport_calc(w)
        // TOGGLE DETECTOR (2026-08-02): this {#if} gates the ENTIRE stage (svg + faces + every KeepFace).
        //  If it flips false↔true it tears the whole stage down and rebuilds it — invisible to the cell-
        //   array probes (build_cells keeps emitting the cell regardless).  Log ONLY on a flip, with why.
        const prev = lastShow.get(w)
        if (prev !== undefined && prev !== r) {
            const mirror: any = (w.c as any).mirror
            const rows = mirror ? (mirror.ob() as TheC[]) : []
            const live = rows.filter(x => !(x.sc as any).departing).length
            console.log('▣ Vyto show_viewport TOGGLE', prev, '→', r, '| commissioned=', commissioned(w),
                        'mirror=', !!mirror, 'rows=', rows.length, 'nonDeparting=', live)
            // ALSO land it in the supply_trace ring → wormhole/_trace/ (relay-free disk read via
            //  scripts/tracelog.mjs), so this is self-serve without console copying.  Direct push (not
            //   Radio_trace) so it works even if the Radio ghost isn't mounted on this House.
            const M: any = (H as any).top_House?.()
            if (M) { const log = M.c.supply_trace || (M.c.supply_trace = []); log.push({ t: Date.now(), ev: 'vyto-show-toggle', to: r ? 1 : 0, comm: commissioned(w) ? 1 : 0, rows: rows.length, live }); if (log.length > 300) log.splice(0, log.length - 300) }
        }
        lastShow.set(w, r)
        // THE HOLD — this {#if} gates the ENTIRE stage, so a false that lasts one render costs every
        //  face its DOM (and the human their half-typed directory).  Arriving is instant; LEAVING must
        //   persist past the hold.  Keyed per world, and the detector above still reports raw flips.
        return stage_hold(r, w)
    }
    const stage_hold = hold_true()
    function show_viewport_calc(w: TheC): boolean {
        if (!commissioned(w)) return false
        const mirror: any = (w.c as any).mirror
        if (!mirror) return false
        return (mirror.ob() as TheC[]).some(r => !(r.sc as any).departing)
    }
    function viewport_cells(w: TheC): PaintCell[] { void paint_tick; return paintMap.get(w) ?? [] }
    // `engaged` is a plain Map (render state, never reactive), so the template reads it through the
    //  paint_tick tick like every other paint fact — cam_to bumps it, so the ⤴ chip appears and
    //   disappears with the engagement.
    function engaged_on(w: TheC): boolean { void paint_tick; return engaged.has(w) }
    // THE MAGNIFICATION FACTOR — how much bigger the camera is currently making everything.
    //  The owner, after clicking into a cell: *"the zooming up to each thing as you click them doesn't
    //   help as the thing inside is just as small and uncomplicated."*  Exactly right, and it is ledger
    //    #5 ("face content is flat 11px — no floor, no scale"): the camera grows a face's BOX, but every
    //     face renders at hardcoded 9/10/11px, so zooming in bought whitespace instead of detail.
    //  Cyto has always done this the other way (`fontSize = base * cy.zoom()`, Cytui:673) — the glass
    //   just never inherited it.  Handing the factor to CSS as a variable rather than scaling fonts in JS
    //    is what makes it work for faces this file knows nothing about: `.face-scroll` lays out in a box
    //     divided by the factor and is then scaled back up by it, so EVERYTHING inside magnifies (text,
    //      buttons, the transfer sparkline) whatever units that face happens to use.  Identity at rest.
    function cam_zoom(w: TheC): number {
        void paint_tick
        const c = cams.get(w)
        if (!c || !(c.w > 0)) return 1
        return +(vw_w / c.w).toFixed(3)
    }

    // ── THE PLUG AND THE ANTS ─────────────────────────────────────────────────
    //  The owner's ruling (Vyto_todo §0.0, 2026-08-06): *"we can see what the player is plugged into
    //   in the Mag, tiny ants moving buffer into the Record there"* — and, load-bearing, that new
    //    understanding must arrive as a RELATION DRAWN between things already on the glass and as
    //     MOTION, never as another cell of text.  Both facts are already held and thrown away at the
    //      face boundary: `radio.c.rec` is the plug, `H.top_House().c.xfer.pulls[]` is the flow.
    //  SELF-TICKED, because both ride `.c` and `.c` never bumps a version — the §0.0 caution, and the
    //   same 250ms–1s idiom RadioFace/TransferFace already use.  paint_tick alone is not enough: it
    //    stops when the layout settles, and the plug must still notice the record CHANGING under a
    //     calm glass (which is most of the time — a track lasts minutes, the cells settle in <1s).
    //  LIVE PAGE ONLY, and this is not optional — it is the same law the focus taper obeys ("a driven
    //   world must keep the even cut its fixtures recorded", Vyto_todo §0).  A driven Book must not have
    //    a 500ms timer re-rendering its glass underneath it: quiescence and settle are what a Story step
    //     waits on, and decoration that re-renders on its own clock is exactly the kind of thing that
    //      makes a Book's timing — and therefore its diges — depend on the decoration.  `humdinger` is
    //       the standing predicate for END-USER PAGE vs machine tab, so the tick simply never fires on a
    //        runner, and plug_of/ants_of below return null there regardless of the tick.
    function live_page(): boolean { return !!(H as any)?.top_House?.()?.c?.humdinger }
    let plug_tick = $state(0)
    // THE TICK ONLY FIRES ON A CHANGE (2026-08-08, Vyto_todo §0.2(c) "standing cost even on a settled
    //  glass").  This interval used to bump `plug_tick` — a `$state` — every 500ms on any live page,
    //   whether or not a plug or an ant existed, so every reader of it re-ran at 2Hz on a settled,
    //    silent glass, which is exactly the "burning CPU with nothing happening" complaint.
    //  It must NOT be gated on "a plug exists": the interesting transition is precisely no-plug → plug,
    //   and a gate like that could never see its own precondition arrive.  What the tick is actually
    //    FOR is noticing `.c` facts change (`.c` bumps no version), so bump when those facts differ —
    //     which is the same thing, minus the false alarms.
    //  What this does NOT gate: cell GEOMETRY still reaches the plug through paint_tick — the template
    //   calls `plug_of(w, viewport_cells(w))` and viewport_cells reads paint_tick — so a moving glass
    //    redraws the cable every paint regardless of this timer.
    //  `springs.keys()` rather than `vyto_worlds()` on purpose: vyto_worlds() carries the WORLDS PROBE
    //   and the hold_list buffer, both of which have per-call state, and a timer must not perturb them.
    let plug_sig_last = ''
    function plug_sig(): string {
        let s = ''
        for (const w of springs.keys()) {
            const radio: any = (w as any).o?.({ Radio: 1 })?.[0]
            const rec: any = radio?.c?.rec
            s += '|' + (radio ? String(radio.sc?.Radio ?? '') : '-')
               + ':' + (rec ? String(rec.sc?.id ?? rec.sc?.path ?? '?') : '-')
        }
        const a = ants_now()
        return s + (a ? '#' + a.begins.length + '@' + a.dur : '#-')
    }
    const plug_timer = setInterval(() => {
        if (!live_page()) return
        const sig = plug_sig()
        if (sig === plug_sig_last) return
        plug_sig_last = sig
        plug_tick = plug_tick + 1
    }, 500)
    onDestroy(() => clearInterval(plug_timer))

    // a slack curve, not a straight edge.  A straight line between two cells reads as a GRAPH
    //  DIAGRAM, which is the dashboard instinct the ruling rejects; a sagging cable reads as a made
    //   thing.  The control point is pushed perpendicular to the chord by a fraction of its length,
    //    so a long plug sags more, like a real cable, and a short one stays taut.
    function plug_curve(a: { x: number, y: number }, b: { x: number, y: number }): string {
        const mx = (a.x + b.x) / 2, my = (a.y + b.y) / 2
        const dx = b.x - a.x, dy = b.y - a.y
        const len = Math.hypot(dx, dy) || 1
        const sag = Math.min(46, len * 0.18)
        return `M ${a.x.toFixed(2)} ${a.y.toFixed(2)} Q ${(mx - (dy / len) * sag).toFixed(2)} ${(my + (dx / len) * sag).toFixed(2)} ${b.x.toFixed(2)} ${b.y.toFixed(2)}`
    }

    //  The Record itself usually has NO cell of its own — it lives inside a Mag — so we walk up the
    //   `.c.up` chain until we reach a particle the cut actually gave a cell to.  That walk is what
    //    makes the plug land "in the Mag" rather than nowhere: the plug points at the container
    //     holding what is playing, which is exactly what the ruling asks to be able to see.
    function plug_of(w: TheC, cells: PaintCell[]): { d: string, hx: number, hy: number } | null {
        void plug_tick
        if (!live_page()) return null            // a driven Book draws no plug — see live_page()
        const radio: any = (w as any).o?.({ Radio: 1 })?.[0]
        if (!radio || radio.sc?.Radio === 'off') return null
        const rec: any = radio.c?.rec
        if (!rec) return null
        const by_source = new Map<any, PaintCell>()
        for (const c of cells) if (c.source) by_source.set(c.source, c)
        const from = by_source.get(radio)
        if (!from) return null
        let hop: any = rec
        for (let guard = 0; hop && guard < 12; guard++) {
            const to = by_source.get(hop)
            if (to && to !== from) return { d: plug_curve(from, to), hx: to.x, hy: to.y }
            hop = hop.c?.up
        }
        //  FALLBACK — BY ID, NOT BY CONTAINMENT.  The walk above only lands if some ANCESTOR of the
        //   record was given a cell, and often none was: the cut hands cells to FACES (Radio, Transfer,
        //    Shuffle, Haul…), not to the shelves a %Record hangs under, so a purely structural walk can
        //     run its whole guard and draw nothing.  But the glass is usually already showing the track
        //      — as a REFERRING particle wearing its own mainkey and carrying the holding's id
        //       (`Card,id:X` / `Haul,…` / `Spin,of:X`; CLAUDE.md's identity model).  That id IS the join,
        //        so match on it.  This is the case that most often makes the plug visible at all.
        const rid = rec?.sc?.id != null ? String(rec.sc.id) : null
        if (rid) {
            for (const c of cells) {
                if (c === from || !c.source) continue
                const s: any = c.source
                if (String(s.sc?.id ?? '') === rid || String(s.sc?.of ?? '') === rid) {
                    return { d: plug_curve(from, c), hx: c.x, hy: c.y }
                }
            }
        }
        return null
    }

    // ── THE VINES (the human 2026-08-08: "lots of erupting sprouting branchy things") ────────────
    //  The Relate scribe's %Flow edges have been shaping this glass invisibly since VytoBunch: `pull_step`
    //   nudges meaning-related seats toward one another inside `Vyto_solve`'s relax, so two cells that
    //    share meaning already sit closer together — a fact PROVEN by an A/B differential (joined kin rest
    //     234 < severed kin 247) and never once drawn.  This is the missing display half: the branchy
    //      thing IS the relation, so draw it.
    //  §0.0 BY THE LETTER — "new understanding should arrive as relations drawn between things already on
    //   the glass, and as motion, not as new boxes of text."  A vine adds no cell and no readout.
    //  Beneath the cells (emitted first) and cool against the plug's warm amber: this is mycelium under
    //   the foam, not the one human cable running across it.  Weight rides log2 so a heavy vein reads
    //    thicker without a strong edge swamping the picture.
    //  NO TIMER: edges are written by Relate during a stir, and a stir always ends in a paint, so
    //   paint_tick alone carries them.  (Contrast the plug, which needed its own tick because `radio.c.rec`
    //    changes with no stir at all.)  TOP CELLS ONLY — a %Flow edge names a mirror tok, and a tok is
    //     unique only among siblings, so matching it against nested cells could pair the wrong cousins.
    //  HONEST STATE: whether the LIVE Sounditron world declares any relations is exactly the open
    //   question of the gap list (§0.1 item 3) — Relate's teeth were proven in Books, not on the live
    //    page.  So this renders whatever is true and nothing when nothing is: no relations, no vines.
    function vines_of(w: TheC, cells: PaintCell[]): { d: string, sw: number }[] {
        const rel: any = (w.c as any).relations
        if (!rel) return []
        const at = new Map<string, PaintCell>()
        for (const c of cells) if (c.key === c.tok && !c.departing) at.set(c.tok, c)
        if (!at.size) return []
        const out: { d: string, sw: number }[] = []
        for (const e of rel.o() as TheC[]) {
            const a = at.get(String((e.sc as any).a)), b = at.get(String((e.sc as any).b))
            if (!a || !b || a === b) continue
            out.push({ d: vine_curve(a, b), sw: +(1 + Math.log2(1 + (Number((e.sc as any).n) || 1))).toFixed(2) })
        }
        return out
    }
    // a ROOT, not an edge: two quadratics with control points thrown to opposite sides of the chord, so
    //  the line leaves one cell and arrives at the other along a shallow S — the way a runner grows
    //   between two plants rather than the way a graph library connects two nodes.  2dp, so a settled
    //    glass re-emits a byte-identical `d` and Svelte never touches the attribute.
    function vine_curve(a: { x: number, y: number }, b: { x: number, y: number }): string {
        const dx = b.x - a.x, dy = b.y - a.y
        const len = Math.hypot(dx, dy) || 1
        const nx = -dy / len, ny = dx / len            // unit normal to the chord
        const bow = Math.min(30, len * 0.16)
        const f = (v: number) => v.toFixed(2)
        const p1 = { x: a.x + dx / 3, y: a.y + dy / 3 }
        const p2 = { x: a.x + (2 * dx) / 3, y: a.y + (2 * dy) / 3 }
        const m  = { x: (a.x + b.x) / 2, y: (a.y + b.y) / 2 }
        return `M ${f(a.x)} ${f(a.y)}`
             + ` Q ${f(p1.x + nx * bow)} ${f(p1.y + ny * bow)} ${f(m.x)} ${f(m.y)}`
             + ` Q ${f(p2.x - nx * bow)} ${f(p2.y - ny * bow)} ${f(b.x)} ${f(b.y)}`
    }

    //  The ants are the transfer SEEN. `count` reads as volume and `dur` as rate — the pair of things
    //   a single KB/s number says in one unreadable breath.  Null when nothing is actually moving, so
    //    a quiet glass stays quiet: motion that never stops stops meaning anything.
    //  Returns the ants' START OFFSETS, not a count: {#each} wants a real array (an array-LIKE
    //   `{length:n}` is not iterable and does not reliably iterate), and the offsets are what the
    //    markup actually needs anyway — one negative `begin` each, so the file is already mid-flight
    //     at mount and the ants arrive as a stream instead of leaving the gate together.
    //  `pulls` is an OBJECT KEYED BY id8, not an array — `Repli.g:718` initialises `pulls: {}` and
    //   `Ra.g:2591` writes `x.pulls[id8] = {title, held, total, ts, done, goodput_kbps…}`.  Vyto_todo
    //    §0.0 writes it `xfer.pulls[]`, which reads as an array and is what this got wrong first time:
    //     an `Array.isArray` guard is false for `{}`, so the ants were silently dead in every case.
    //  Entries are pruned by `Heist_keep_beat` on a `ts` cut, but a pull that simply STOPPED reporting
    //   can sit there between prunes, so age it out here too — 12s, the same threshold Ra.g calls a
    //    heist-stall.  Ants for a dead pull would be a lie told in motion, which is worse than no ants.
    //  SPLIT IN TWO (2026-08-08): `ants_now` is the reading, `ants_of` is the reading plus the tick
    //   subscription.  The plug_timer needs the facts WITHOUT subscribing to (or being ordered after)
    //    the tick it is deciding whether to bump — `plug_sig` calls `ants_now`.  Same computation.
    function ants_of(): { begins: number[], dur: number } | null {
        void plug_tick
        return ants_now()
    }
    function ants_now(): { begins: number[], dur: number } | null {
        const pulls: any = (H as any)?.top_House?.()?.c?.xfer?.pulls
        if (!pulls || typeof pulls !== 'object') return null
        const now = Date.now()
        let kbps = 0, live = 0
        for (const k of Object.keys(pulls)) {
            const p: any = pulls[k]
            if (!p || p.done) continue
            const held = +(p.held || 0), total = +(p.total || 0)
            if (!(total > 0) || held >= total) continue
            if (now - +(p.ts || 0) > 12000) continue
            live++
            kbps += (+(p.goodput_kbps) || 0)
        }
        if (!live) return null
        const n = Math.max(3, Math.min(7, 2 + live))
        const dur = kbps > 0 ? Math.max(0.9, Math.min(4.5, 900 / kbps)) : 3
        const begins: number[] = []
        for (let i = 0; i < n; i++) begins.push(+((i * dur) / n).toFixed(2))
        return { begins, dur }
    }

    function bar_on(w: TheC, name: string): boolean {
        for (const b of (w.ob({ Bar: 1 }) as TheC[])) if (b.sc.Bar === name) { void b.vers; return !!b.sc.on }
        return false
    }
    function holds_list(w: TheC): { scope: any, channels: string, strength: string, by: any, releasing: boolean }[] {
        void paint_tick
        const calm: any = (w.c as any).calm
        if (!calm) return []
        return (calm.ob({ Hold: 1 }) as TheC[]).map(h => ({
            scope: h.sc.scope,
            channels: ['position', 'size', 'membership', 'face', 'all'].filter(c => (h.sc as any)[c]).join('+'),
            strength: h.sc.pin ? 'pin' : ('damp:' + h.sc.damp),
            by: h.sc.by,
            releasing: (h.sc as any).released_at != null,
        }))
    }

    // pointer facts (cells are real DOM now — the polygon hit-test retires): lift the cell above the
    //  pile by its tree-unique key, poke Calm to place|release the pointer-hold, and kick the loop so
    //   the release ease plays out.  The MODEL hold is keyed by a mirror tok (Calm's %Hold scope),
    //    which is only LOCALLY unique — so fire it for TOP cells only (key===tok); a nested cell lifts
    //     VISUALLY (local `lifted`) but places no tok-scoped hold that would over-pin a same-tok cousin.
    function on_enter(w: TheC, key: string, tok: string) {
        lifted.set(w, key)
        if (key === tok) (H as any).Vyto_pointer_enter?.(w, tok)
        kick(w); paint_tick++
    }
    function on_leave(w: TheC, key: string, tok: string) {
        if (lifted.get(w) === key) lifted.delete(w)
        if (key === tok) (H as any).Vyto_pointer_leave?.(w, tok)
        kick(w); paint_tick++
    }
</script>

{#each vyto_worlds() as w (w)}
    <!-- LIFE LADDER (2026-08-04, the KeepFace remount hunt): four nested lifecycle-true tells —
         world > stage > faces > mold — read against KeepFace's own ◈◈ REAL serial.  The OUTERMOST
         serial that climbs in lockstep with KeepFace is the culprit; a level that stays SILENT is
         proven stable, which is the half the value-comparison probes can't report.  See
         ui/micro/lifetell.ts for the ladder, and read it with `tracelog.mjs --watch --life`. -->
    <div class="vyto" use:lifetell={{ H, what: 'world', id: String((w.sc as any)?.w ?? '?') }}>
        <div class="bar">
            <span class="crest">Vyto</span>
            {#each w.ob({ Bar: 1 }) as b (b.sc.Bar)}
                <button class="word" class:on={!!b.sc.on} class:act={b.sc.kind === 'act'}
                        title={b.sc.doctrine} onclick={() => press(w, b)}>{b.sc.Bar}</button>
            {/each}
            <button class="word organs-btn" class:on={show_organs}
                    title="the organ panel — reads/decides/writes per station (dev; layout controls to come)"
                    onclick={() => (show_organs = !show_organs)}>organs</button>
            <!-- THE ASPECT PICK — the layout control the organs title has been promising.  LIVE PAGE
                 ONLY: a runner tab must never grow chrome that moves geometry (fit_frame's own
                 humdinger gate makes it harmless even if pressed, but absent is better than
                 harmless).  `auto` is the measured path, i.e. exactly today. -->
            {#if live_page()}
                <select class="word aspect-sel" title="the shape of the glass — auto measures the hole; a pick sets the min-height"
                        value={aspect_pick} onchange={(e) => repick_aspect(e.currentTarget.value)}>
                    {#each ASPECTS as a (a[0])}
                        <option value={a[0]}>{a[0]}</option>
                    {/each}
                </select>
            {/if}
        </div>
        {#if show_organs}
            <div class="panel">
                {#each w.ob({ Organ: 1 }) as o (o.sc.Organ)}
                    <div class="organ">
                        <span class="name">{o.sc.Organ}</span>
                        <span class="family">{o.sc.family}</span>
                        <span class="guts">{sentence(o)}</span>
                        <span class="status">{o.sc.status}</span>
                    </div>
                {/each}
            </div>
        {/if}
        <div class="strip">
            {#each w.ob({ Moment: 1 }) as m (m.sc.Moment)}
                <span class="tick" class:o={!!m.sc.o} class:blessed={!!m.sc.bless}
                      class:step={m.sc.step_n != null}
                      title={`yore ${m.sc.Moment}` + (m.sc.step_n != null ? ` — step ${m.sc.step_n}` : '')}></span>
            {/each}
        </div>
        {#if show_viewport(w)}
            {@const plug = plug_of(w, viewport_cells(w))}
            {@const ants = plug ? ants_of() : null}
            {@const plug_id = 'vyplug-' + String((w.sc as any)?.w ?? 'w').replace(/[^A-Za-z0-9_-]/g, '')}
            {@const cam = cam_view(w)}
            <div class="stage" use:reg_stage={w} use:lifetell={{ H, what: 'stage', id: String((w.sc as any)?.w ?? '?') }}>
                <button class="fs-btn" onclick={(e) => go_fullscreen(e.currentTarget.parentElement)}
                        title="fullscreen the glass">⛶</button>
                <!-- the way OUT, shown only while there is somewhere to come out of.  Clicking the
                     engaged cell again does the same thing, but a visible affordance is what makes the
                     navigation discoverable to someone who has not been told it exists. -->
                {#if engaged_on(w)}
                    <button class="fs-btn out-btn" onclick={() => cam_out(w)}
                            title="back out one level (Esc)">⤴</button>
                {/if}
                <!-- THE DEPTH STAGE (the human 2026-08-08: "it should be able to simulate a bit of spatial
                     things... look like a fancy videogame menu with things flying at you and erupting when
                     people play it on their big TVs").  `.stage` holds the CAMERA (perspective) and
                     `.depth` is the thing the camera looks at, so a tilt applies to the SVG cells and the
                     HTML faces AS ONE BODY.  That is not a style choice: the molds are positioned in
                     viewBox PERCENTAGES of the svg, so anything that moved one layer and not the other
                     would tear the registration the whole face rail depends on.  `.fs-btn` stays OUTSIDE
                     `.depth` — chrome must not tilt, and go_fullscreen reads `parentElement` expecting
                     `.stage`, which this keeps true. -->
                <div class="depth" style="--fw:{vw_w}; --fh:{vw_h}; ">
                <svg class="viewport" viewBox="{cam.x} {cam.y} {cam.w} {cam.h}" preserveAspectRatio="xMidYMid meet">
                    <!-- THE VINES, FIRST: the %Flow relations the solver already bunches by, drawn as
                         roots UNDER the cells they tie together.  Nothing when nothing relates. -->
                    {#each vines_of(w, viewport_cells(w)) as v (v.d)}
                        <path class="vine" d={v.d} style="stroke-width:{v.sw};"></path>
                    {/each}
                    {#each viewport_cells(w) as cell (cell.key)}
                        {@const g = cell_ground(cell)}
                        {#if cell.kind === 'poly'}
                            <path class="cell" class:departing={cell.departing} class:lift={cell.lift}
                                  class:faced={!!cell.face && !cell.hasKids} class:nested={cell.depth > 0} class:scope={cell.hasKids}
                                  class:arrive={cell.fx === 'arrive'} class:erupt={cell.fx === 'erupt'} d={cell.d}
                                  style={(g ? `fill:${g.bg}; stroke:${g.border};` : '') + (cell.fx === 'arrive' ? ` animation-delay:${cell.fxi * 55}ms;` : '')}
                                  onpointerenter={() => on_enter(w, cell.key, cell.tok)}
                                  onpointerleave={() => on_leave(w, cell.key, cell.tok)}
                                  onclick={() => cam_engage(w, cell)}
                                  role="button" tabindex={0} aria-label={cell.ident}
                                  onkeydown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); cam_engage(w, cell) } }}></path>
                        {:else}
                            <circle class="cell disc" class:departing={cell.departing} class:lift={cell.lift} class:nested={cell.depth > 0}
                                    class:arrive={cell.fx === 'arrive'} class:erupt={cell.fx === 'erupt'}
                                    cx={cell.x} cy={cell.y} r={cell.r}
                                    onpointerenter={() => on_enter(w, cell.key, cell.tok)}
                                    onpointerleave={() => on_leave(w, cell.key, cell.tok)}></circle>
                        {/if}
                        {#if !cell.face && !cell.hasKids}
                            <text class="ident" data-key={cell.key} x={cell.x} y={cell.y} text-anchor="middle" dominant-baseline="middle">{cell.ident}</text>
                        {:else if cell.face && !cell.hasKids && !cell.departing}
                            <!-- THE LABEL, ALONG ONE SIDE (the owner: "along one side of the cell, looking
                                 like a label") + THE GUTS SPILLED BELOW IT.  Inscribing the mold opened
                                 the gap this sits in: the face now stops short of its own wall, so the
                                 label rides the top edge of the cell OUTSIDE the component rather than
                                 underneath it, and the guts run down the same margin.  Left-aligned and
                                 hanging, so it reads as a filed tab rather than a caption. -->
                            {@const gy = Math.max(cell.by - 11, 3)}
                            <text class="ident under lab" data-ukey={cell.key} x={cell.bx} y={gy}
                                  text-anchor="start" dominant-baseline="hanging">{cell.ident}</text>
                            {#each under_guts(cell.row, Math.max(0, Math.min(7, Math.floor((cell.bh - 6) / 11)))) as g, gi (g)}
                                <text class="ident under sub" data-ukey={cell.key}
                                      x={cell.bx + 1} y={gy + 12 + gi * 10}
                                      text-anchor="start" dominant-baseline="hanging">{g}</text>
                            {/each}
                        {/if}
                    {/each}
                    <!-- the plug + the ants, drawn LAST so they ride over the cells they connect.
                         pointer-events:none throughout: this lane is something to see, never
                         something to hit — the cells keep every interaction they had. -->
                    {#if plug}
                        <path class="plug" id={plug_id} d={plug.d}></path>
                        <circle class="plug-end" cx={plug.hx} cy={plug.hy} r="3.4"></circle>
                        {#if ants}
                            {#each ants.begins as b (b)}
                                <circle class="ant" r="1.8">
                                    <!-- `path=` (SVG 1.1), NOT <mpath href>: mpath's SVG2 `href` form is the
                                         shakier half of this markup and would need an id to resolve against.
                                         Inlining the same d costs one duplicated string per ant and removes
                                         the whole question.  It also will NOT restart the ants on a calm
                                         glass — plug_curve rounds to 2dp, so a settled layout re-emits a
                                         byte-identical d and Svelte never touches the attribute.
                                         negative begin = already mid-flight, so they arrive as a STREAM
                                         rather than all leaving the gate together. -->
                                    <animateMotion dur="{ants.dur}s" repeatCount="indefinite" begin="-{b}s"
                                                   calcMode="linear" path={plug.d}></animateMotion>
                                </circle>
                            {/each}
                        {/if}
                    {/if}
                </svg>
                <!-- the FACE overlay: an HTML layer molded to the SVG in viewBox percentages (the SVG
                     keeps its 800×450 aspect at width:100%, so a % box tracks its cell exactly — no
                     pixel measurement, no overlay-sync drift).  Each faced cell mounts its glass
                     component handed the live source particle + the House. -->
                <div class="faces" use:lifetell={{ H, what: 'faces', id: String((w.sc as any)?.w ?? '?') }}>
                    {#each viewport_cells(w) as cell (cell.key)}
                        <!-- THE ICON REGISTER: below the legibility floor a face is not drawn at all —
                             the cell keeps its edge label and nothing else.  "things become icons when
                             crushed down", as the continuum's bottom step rather than a special case. -->
                        {#if cell.face && !cell.departing && !cell.hasKids && cell.fit > 0.34}
                            {@const Face = cell.face}
                            <div class="face-mold" class:lift={cell.lift}
                                 class:arrive={cell.fx === 'arrive'} class:erupt={cell.fx === 'erupt'} data-key={cell.key}
                                 use:lifetell={{ H, what: 'mold', id: cell.key }}
                                 style="left:{((cell.bx - cam.x) / cam.w) * 100}%; top:{((cell.by - cam.y) / cam.h) * 100}%; width:{(cell.bw / cam.w) * 100}%; height:{(cell.bh / cam.h) * 100}%; --fit:{cell.fit};{cell.clip ? ` clip-path:${cell.clip};` : ''}{mold_seat(cell)}"
                                 onpointerenter={() => on_enter(w, cell.key, cell.tok)}
                                 onpointerleave={() => on_leave(w, cell.key, cell.tok)}>
                                <div class="face-scroll">
                                    <svelte:boundary>
                                        <Face n={cell.source} H={H} />
                                        {#snippet failed(error)}
                                            <div class="face-err" title={String(error)}>{cell.ident}</div>
                                        {/snippet}
                                    </svelte:boundary>
                                </div>
                            </div>
                        {/if}
                    {/each}
                </div>
                </div><!-- /.depth -->
            </div>
        {/if}
        {#if bar_on(w, 'holds')}
            <div class="holds">
                {#each holds_list(w) as h}
                    <div class="hold" class:releasing={h.releasing}>
                        <span class="hscope">{h.scope}</span>
                        <span class="hchan">{h.channels}</span>
                        <span class="hstr">{h.strength}</span>
                        <span class="hby">{h.by}</span>
                    </div>
                {/each}
            </div>
        {/if}
    </div>
{/each}

<style>
    .vyto {
        font: 12px/1.5 system-ui, sans-serif;
        background: #1b1b22; color: #cfcfd8;
        border: 1px solid #33333f; border-radius: 6px;
        padding: 6px 8px; margin: 4px; max-width: 68em;
    }
    .bar { display: flex; gap: 4px; align-items: baseline; }
    .crest { color: #8a8aa0; font-weight: 600; margin-right: 4px; }
    .word {
        font: inherit; color: #9a9ab0; background: none;
        border: 1px solid #3a3a48; border-radius: 4px;
        padding: 1px 8px; cursor: pointer;
    }
    .word.on  { color: #e8e8f2; border-color: #7a7ad0; background: #26263a; }
    .word.act { border-style: dashed; }
    .organs-btn { margin-left: auto; }   /* chrome control — sits at the far end of the bar */
    .panel { margin-top: 6px; }
    .organ { display: flex; gap: 8px; align-items: baseline; padding: 1px 0; }
    .organ .name   { width: 4.5em; font-weight: 600; color: #d8d8e8; }
    .organ .family { width: 6em; color: #77778c; font-style: italic; }
    .organ .guts   { flex: 1; color: #a8a8bc; }
    .organ .status { color: #66667a; }
    .strip { margin-top: 6px; display: flex; gap: 3px; flex-wrap: wrap; }
    .tick {
        width: 7px; height: 7px; border-radius: 50%;
        background: #44445a; display: inline-block;
    }
    .tick.step    { background: #6a6ad0; }
    .tick.o       { background: #d0a94a; }
    .tick.blessed { background: #4ad07a; border-radius: 2px; }

    /* the viewport — the root scope, one cell per mirror row.  The frame follows the stage's aspect
       (fit_frame), so this is free to be any shape; fullscreen is just the biggest such shape. */
    .stage { position: relative; margin-top: 6px; }
    /* THE BODY THE CAMERA LOOKS AT — svg + faces move as one, so mold↔cell registration cannot tear.
       `preserve-3d` is what lets each mold hold its own Z (the seating tilt + the hover pop); its price
       is that Z-ORDER STOPS OBEYING z-index inside here, which is why the lift moved to translateZ.
       The transition doubles as the parallax damping: pointer motion reads as a heavy pane easing,
       and pointerleave glides home instead of snapping. */
    .depth {
        transform-style: preserve-3d;
        /* POSITIONED, so `.faces { inset: 0 }` resolves against THIS box and not `.stage`.  Without it
           the face layer would size to the stage while the drawing sized to the capped box below, and
           every mold percentage would land in the wrong place. */
        position: relative;
        /* THE TALL-PICK CAP — as a WIDTH limit, never a height one.  A 1:1 or 9:16 pick on a desktop
           would otherwise render width×1 / width×1.78 tall, past the bottom of the screen.  The naive
           fix (`max-height` on the svg) is WRONG and was caught before it shipped: the element box stays
           full width while the drawing letterboxes inside it, so the drawing is narrower and centred
           while the molds are still positioned in percentages of the FULL box — mold↔cell registration
           tears, silently, only on tall picks.  Capping the WIDTH instead keeps `width:100%; height:auto`
           exact: the element box always has the viewBox's aspect, so no letterbox can ever occur and the
           percentage mold contract holds by construction.  --fw/--fh are stamped from vw_w/vw_h. */
        max-width: calc(82vh * var(--fw, 800) / var(--fh, 450));
        margin-inline: auto;
    }
    .viewport {
        display: block; width: 100%; height: auto;
        background: #16161c; border: 1px solid #2a2a35; border-radius: 4px;
    }
    /* the aspect pick — a <select> wearing the .word chrome so it reads as one of the bar's controls */
    .aspect-sel { font: inherit; padding: 1px 4px; cursor: pointer; }
    /* FULLSCREEN — the stage becomes the whole screen and the glass fills it edge to edge.  height:100%
       on the svg (not auto) is what lets a portrait phone use its whole height instead of letterboxing;
       the frame has already been re-cut to that aspect, so nothing is stretched. */
    .stage:fullscreen { margin: 0; width: 100vw; height: 100vh; background: #0d0d12; }
    /* .depth must carry the full height through to the svg, or the viewport's height:100% resolves
       against an auto-height wrapper and collapses.  The max-height cap is an IN-PAGE limit only —
       fullscreen has already re-cut the frame to the screen's own shape, so nothing is being stretched. */
    .stage:fullscreen .depth { width: 100%; height: 100%; max-width: none; }
    .stage:fullscreen .viewport { width: 100%; height: 100%; border: 0; border-radius: 0; }
    .fs-btn {
        position: absolute; right: 6px; top: 6px; z-index: 5;
        width: 26px; height: 26px; line-height: 1; padding: 0;
        border: 1px solid #4a4a6a; border-radius: 4px;
        background: rgba(22, 22, 28, 0.72); color: #b8b8d8;
        font-size: 13px; cursor: pointer;
    }
    .fs-btn:hover { background: #2a2a3e; color: #fff; }
    /* the walk-out chip sits beside ⛶ (which is at right:6px), so the two read as one control cluster */
    .out-btn { right: 38px; }
    @media (pointer: coarse) { .out-btn { right: 52px; } }
    /* an engaged-able cell should say so under the cursor — the one hint that the glass is navigable.
       The cells are also real keyboard targets (role=button + tabindex): tab to a cell, Enter to fly to
       it, Esc to come back out.  ~5-9 cells on the live glass, so this is a usable tab order rather than
       a flood, and it is the honest answer to "navigable" — cheaper than suppressing the a11y warning and
       leaving the glass mouse-only.  A visible focus ring is the point, so style it rather than remove it. */
    .cell { cursor: pointer; }
    .cell:focus { outline: none; }
    .cell:focus-visible { stroke: #ffd479; stroke-width: 2.4; outline: none; }
    /* a phone is thumbs: give the control a real target without growing it on the desktop */
    @media (pointer: coarse) { .fs-btn { width: 38px; height: 38px; font-size: 17px; } }
    .cell {
        fill: #2a2a3e; stroke: #6a6ad0; stroke-width: 1.2;
        transition: fill 120ms ease;
    }
    .cell.disc { fill: #33334a; }
    .cell.departing { opacity: 0.35; }
    .cell.lift { fill: #3a3a58; stroke: #a8a8f0; }
    /* a faced cell is a quiet frame — the mounted face draws the content over it */
    .cell.faced { fill: #17171f; stroke: #3d3d55; }
    /* NESTED (depth>0): a child wall reads finer than its container so the tree is legible; a
       SCOPE cell (its children tile it) is a bare frame — transparent fill, faint outline — so the
       children carry the ink.  Both ADD onto the flat look; a flat glass never emits either class. */
    .cell.nested { stroke-width: 0.7; }
    .cell.scope { fill: none; stroke: #4a4a66; }
    .cell.scope.lift { fill: none; stroke: #a8a8f0; }

    /* ── THE FX: ARRIVE · ERUPT · DEPART ────────────────────────────────────────────────────────
       One-shot CSS animations, played by the browser's own clock.  Nothing in the render loop drives
       them — the loop only decides which class a cell wears — because a settled glass PARKS and never
       repaints, so a JS-driven effect would freeze exactly when the layout calmed.  Same reasoning as
       the SMIL ants; the browser is the one component here that keeps time for free.
       Under `prefers-reduced-motion: no-preference` throughout: this is decoration, and a reader who
       has asked for stillness gets the glass with none of it.
       NOTE the deliberate split of duties, learned the hard way while writing this: the CELL animates
       its own transform (an SVG path carries no inline transform, so nothing competes), but a MOLD
       must never — `mold_seat` writes an inline transform every frame and a running animation
       OUTRANKS inline style, so a keyframed mold transform would hold the fly-in and then POP to the
       seat the instant the animation ended.  The mold's motion therefore rides its CHILD
       (`.face-scroll`), whose transform composes with the parent's seat instead of fighting it. */
    @media (prefers-reduced-motion: no-preference) {
        /* SPROUT — a first-ever sighting grows into place from nothing, scaled about its own centre.
           `transform-box: fill-box` is required: an SVG element's transform-origin is the USER SPACE
           origin by default, so a bare `scale()` would fly the cell in from the frame's top-left
           corner instead of swelling where it stands. */
        .cell.arrive {
            transform-box: fill-box; transform-origin: center;
            animation: vy-sprout 620ms cubic-bezier(0.22, 1.4, 0.36, 1) both;
        }
        @keyframes vy-sprout {
            0%   { opacity: 0; transform: scale(0.28); }
            65%  { opacity: 1; transform: scale(1.06); }
            100% { opacity: 1; transform: scale(1); }
        }
        /* the face that rides a sprouting cell FLIES AT YOU — the videogame-menu arrival.  On the child,
           so the mold keeps its seat; `animation-delay` is inherited from the mold's inline stagger. */
        .face-mold.arrive .face-scroll {
            animation: vy-flyin 620ms cubic-bezier(0.22, 1.2, 0.36, 1) both;
        }
        @keyframes vy-flyin {
            0%   { opacity: 0; transform: translateZ(-560px) scale(0.7); }
            100% { opacity: 1; transform: translateZ(0) scale(1); }
        }
        /* ERUPT — the model has already swollen this cell (Vyto_focus's FOCUS_BOOST, springing); this is
           the flash that says it just happened.  Stroke only: no transform, so nothing contends. */
        .cell.erupt { animation: vy-erupt 700ms ease-out both; }
        @keyframes vy-erupt {
            0%   { stroke-width: 5.5; stroke: #fff3cf; }
            40%  { stroke-width: 2.4; }
            100% { stroke-width: 1.2; }
        }
        .face-mold.erupt .face-scroll { animation: vy-erupt-face 700ms ease-out both; }
        @keyframes vy-erupt-face {
            0%   { transform: translateZ(46px) scale(1.05); filter: brightness(1.5); }
            100% { transform: translateZ(0) scale(1); filter: brightness(1); }
        }
        /* DEPART — the spring is already shrinking this cell's radius to zero (the model leaves a
           departing row's T standing and the renderer ramps r down), so the fx adds only the ring
           going out with it.  Radius is the spring's to own; this touches stroke and opacity alone. */
        .cell.departing { animation: vy-depart 520ms ease-out both; }
        @keyframes vy-depart {
            0%   { stroke-width: 3.2; opacity: 0.6; }
            100% { stroke-width: 0.4; opacity: 0; }
        }
    }

    /* THE VINES — the %Flow relations as roots.  Cool and low-contrast on purpose: these are the standing
       kinships of the whole graph (many of them, potentially), so they must read as the substrate the
       cells grow out of, never as foreground.  The PLUG stays warm and on top: one live human thing over
       a bed of structure.  pointer-events:none — something to see, never something to hit. */
    .vine {
        fill: none; stroke: #6fae8f; stroke-linecap: round;
        opacity: 0.3; pointer-events: none;
    }
    /* THE PLUG — the radio↔Record relation, drawn (Vyto_todo §0.0).  Warm against the glass's cold
       violets on purpose: this is the one live, human thing on a plate of machinery, and it should
       read as a cable someone ran, not as another wall.  Unfilled, round-capped, and deliberately
       thinner than a cell stroke so it never competes with the foam it crosses. */
    .plug {
        fill: none; stroke: #ffb86b; stroke-width: 1.1; stroke-linecap: round;
        opacity: 0.55; pointer-events: none;
    }
    /* the socket end — a small bead where the cable meets the Mag, so the eye lands on WHICH cell
       is plugged rather than tracing the curve to find out */
    .plug-end { fill: #ffb86b; opacity: 0.8; pointer-events: none; }
    /* THE ANTS — the transfer as travel.  Small and slightly hot, so a stream of them reads as
       something being carried rather than as decoration; they exist only while bytes actually move
       (ants_of returns null otherwise), which is what keeps the motion meaningful. */
    .ant { fill: #ffe0a8; opacity: 0.9; pointer-events: none; }

    /* the FACE overlay — molded to cells in viewBox percentages, so it tracks the responsive SVG */
    .faces { position: absolute; inset: 0; pointer-events: none; }
    /* "let them overflow" (the human's choice): no polygon clip-path (was cutting the face content
       at the slanted cell walls) and overflow:visible, so a taller face spills past its cell rather
       than being occluded.  The grey inset box is dropped too — unclipped it would read as a bare
       rectangle; the coloured <path class="cell"> polygon is the cell wall now. */
    /* pointer-events:NONE, not auto — with overflow visible the mold is a RECTANGLE at the cell's
       bbox, and voronoi bboxes overlap heavily, so an auto mold's transparent corner floats over a
       neighbour's button and eats the click ("pause is impossible to click sometimes").  The mold
       must never catch: every face root is itself pointer-events:none and its buttons re-arm auto
       (glass_kinds contract), and an auto descendant still hit-tests its OWN small box even under a
       none ancestor — so the buttons stay live while the dead overflow steals nothing. */
    .face-mold {
        position: absolute; pointer-events: none;
        box-sizing: border-box;
        /* CLIPPED — ledger #4's "let them overflow" choice RE-DECIDED (THE PIN human call 2, blessed
           2026-08-09 after the owner saw the faces lying on top of each other).  Overflow was chosen when
           clipping amputated content inside cells cut too small; the NEED FLOOR removes that cause — a
           cell now grows to the box its component measured — so the cure is safe to restore, which is
           exactly the order THE PIN prescribed (floor first, then wall policy).
           Belt and braces with the inscribed mold: the box already sits inside the cell, and this stops
           any content taller than it from reaching over a neighbour's wall. */
        overflow: hidden;
        border-radius: 14px;
        /* SEATED, not taped on: a soft inner ring + a cast shadow so the face reads as set INTO the cell
           whose wall is drawn behind it.  Static — the per-cell 3D transform rides the style attribute
           (mold_seat), this is just the chrome that makes the seating legible. */
        transform-style: preserve-3d;
        transition: box-shadow 140ms ease-out;
        box-shadow: 0 1px 6px rgba(0, 0, 0, 0.35);
    }
    /* the lift's Z lives in mold_seat (z-index does not order inside a preserve-3d context); z-index is
       kept for browsers that flatten the 3D context, where it is still the only thing that can order. */
    .face-mold.lift { box-shadow: inset 0 0 0 1px #a8a8f0, 0 10px 26px rgba(0,0,0,0.6); z-index: 5; }
    /* THE MAGNIFIER.  Lay the face out in a box divided by the camera's zoom, then scale it back up by
       the same factor: the component fills the same visible area but every glyph, button and graph in it
       is `--vyz` times bigger.  This is what makes flying into a cell reveal the thing rather than just
       more whitespace around it — the complaint that "the thing inside is just as small".
       Done as a TRANSFORM, not a font-size, on purpose: the faces hardcode 9px/10px/11px in their own
       stylesheets, so nothing this file could set on a font would reach them; a transform scales whatever
       they drew.  `--vyz` is 1 whenever no camera is engaged, and `scale(1)` with a `calc(100%/1)` box is
       an exact identity — so a glass at rest is byte-for-byte what it was before the camera existed. */
    .face-scroll {
        /* ENVELOPE TO FIT: lay the component out in a box divided by `--fit`, then scale it back down by
           the same factor.  At --fit 1 this is an exact identity.  Below 1 the component keeps its full
           layout (nothing reflows, nothing is cut) and is drawn smaller so it SITS INSIDE ITS CELL —
           which is the only way to stop the overlapping without amputating anything. */
        width: calc(100% / var(--fit, 1)); height: calc(100% / var(--fit, 1));
        transform: scale(var(--fit, 1)); transform-origin: top left;
        overflow: hidden;
        font-size: 11px; line-height: 1.35;
    }
    .face-err {
        padding: 4px 6px; color: #d08a8a; font-weight: 600;
        font: 600 11px/1.3 system-ui, sans-serif;
    }
    .ident {
        fill: #e6e6f2; font: 600 14px/1 system-ui, sans-serif;   /* 14px legibility floor */
        pointer-events: none; user-select: none;
    }
    /* THE UNDER-LAYER — the bare standard representation, SHADOWED OVER by the face shoved in on top
       (the human's words).  Low ink on purpose: on screen it should read as the machine showing through
       its own UI, not as a label competing with it.  In a `runner_shot --svg` capture the faces are
       simply absent, so this IS the picture — which is the whole point of drawing it. */
    .ident.under { fill: #8f8fb4; opacity: 0.5; font-weight: 600; }
    /* THE EDGE LABEL — the cell's name filed along its top side, in the margin the inscribed mold opened
       between the wall and the face.  Slightly brighter and tighter than the guts: it is the one thing
       that says WHICH of several same-kind cells this is (`Haul:10.Yara`), so it should read first. */
    .ident.under.lab { font: 600 11px/1 ui-monospace, SFMono-Regular, Menlo, monospace; fill: #a8a8cc; opacity: 0.62; letter-spacing: 0.2px; }
    /* THE GUTS — the particle's own scalars, spilled down the same margin as quiet standing matter.
       Monospace so the k/v columns line up down the stack and the eye can scan them. */
    .ident.under.sub { font: 500 9px/1 ui-monospace, SFMono-Regular, Menlo, monospace; fill: #7a7a9c; opacity: 0.42; }
    .holds { margin-top: 6px; display: flex; flex-direction: column; gap: 1px; }
    .hold { display: flex; gap: 8px; align-items: baseline; color: #a8a8bc; }
    .hold.releasing { color: #77778c; font-style: italic; }
    .hold .hscope { min-width: 8em; color: #d8d8e8; }
    .hold .hchan  { min-width: 6em; color: #8a8aa0; }
    .hold .hstr   { min-width: 5em; color: #9a9ab0; }
    .hold .hby    { color: #66667a; }
</style>
