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
    import { power_cells, foam_cells, slab_seat, poly_area, type Pt } from "$lib/O/vyto_geometry"
    import { deal_rows, seat_on_deal, deal_fits, deal_badness, box_poly,
             type Deal, type SeatRow } from "$lib/O/vyto_seat"
    import { focus_polys, fill_body, BELLY_SWELL, type FocusRole } from "$lib/O/vyto_focus"
    import { gauge_box, gauge_pose, GAUGE_MS } from "$lib/O/vyto_gauge"
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
    // (the bar press went with the bar — 2026-08-11.  `Vyto_omark` and every %Bar doctrine still
    //  stand model-side; nothing in this component toggles them any more.)

    // THE SMUGGLED PRESS (the owner 2026-08-09: "with click handlers smuggled in, so anything can
    //  basically be interacted with").  A posed particle carries `.c.press` (a ref — never encoded,
    //   exactly what .c is for); a cell whose SOURCE wears one is a button, whatever its mainkey.
    //    The handler is handed the source particle so a one-line .g handler can read and write it.
    function cell_click(w: TheC, cell: PaintCell) {
        // A CLICK IS A PRESS OR IT IS NOTHING (the owner 2026-08-10, the focus pivot: *"currently we
        //  can drag cells around ... and click to enlarge them, and click another button to reset
        //   them all, all that I want GONE!"*).  The attention buy and the camera engage are out —
        //    a click no longer changes anyone's size or anyone's view.  What stays is the smuggled
        //     press: a cell whose source wears `.c.press` is a BUTTON (the OK/CANCEL substrate the
        //      satellites ride), and pressing a button is the one thing a click still means.
        void w
        const src: any = (cell.row.c as any)?.source_n
        // `.c.press` is the name; `.c.onclick` is the name people reach for (the owner did — "some of
        //  them have click handlers magically (C.c.onclick?)"), and a handler that silently does not
        //   fire because it was spelled the DOM way is a bad half hour for whoever wrote it.  Both work.
        const fn = src?.c?.press ?? src?.c?.onclick
        if (typeof fn === 'function') {
            try { fn(src) } catch (e) { console.warn('◈ Vyto press threw', cell.ident, e) }
        }
    }

    // A BUTTON HAS TO LOOK LIKE ONE.  Until this, a cell wearing `.c.press` was pixel-identical to a
    //  cell that merely STATES something — which is the single reason "C** all the way down" could
    //   not carry an interface: the tree was already interactive, nobody could tell which parts.
    //    One predicate, read live off `.c` (never stamped on PaintCell), so a handler that arrives
    //     mid-session lights its cell on the next paint without a rebuild.
    function pressy(cell: PaintCell): boolean {
        const src: any = (cell.row.c as any)?.source_n
        return typeof (src?.c?.press ?? src?.c?.onclick) === 'function'
    }

    // THE A IS GONE (2026-08-10, the focus pivot).  It was the honest cure for a foam that guessed
    //  sizes — a handle on the same knob the model reads.  Under focus, size is ASSIGNED by the
    //   commission, so the handle came off with the guessing: `dose` remains a model fact the
    //    commissioner writes (Sounditron prices its organs with it), but no gesture edits it.

    // ── THE FOAMEREO (the owner 2026-08-09: "are much of these differences available to the
    //  composer of future machines like this? we'd like to have a lot of options on the foamereo").
    //  One scalar sc key on the world — `foamereo:"wave,seal,copperless"` — a comma deck of decor
    //   stops a COMPOSER pulls when commissioning a glass.  A plain scalar string, so it snaps
    //    clean and a Book (or a machine recipe) sets it like any other line; `key:value` tokens
    //     carry a setting.  UNSET ⇒ every default ⇒ byte-identical renders, which is the fixture
    //      contract.  The deck so far:
    //        wave        label rides the scalloped waveband instead of the wall carve
    //        seal        the A is the round HTML thumb-seal instead of the wall gate
    //        copperless  no ground grain          nohall   no corridor of guts
    //        simmer      layout keeps negotiating from first mount (live pages only)
    function fo(w: TheC, key: string): string | null {
        const s = String((w.sc as any)?.foamereo ?? '')
        if (!s) return null
        for (const t of s.split(',')) {
            const tt = t.trim()
            if (tt === key) return '1'
            if (tt.startsWith(key + ':')) return tt.slice(key.length + 1)
        }
        return null
    }

    // ── THE WALL CARVE (the owner: "the A I'm thinking of is built in to the vector graphic in
    //  the wall" / "we need on top of the A labels, drawing them properly in the cell wall").
    //  A foam cell IS a ball, so its wall is an arc: band the upper arc (205°→335°, over the
    //   top), set the name along it as a textPath, and stand the A at the 205° end — the gate
    //    this world was walked into through, nose out along the wall normal.  Non-foam worlds
    //     (no ball law) keep the waveband, as does any composer who pulled `wave`. ──
    //  THE CARVE IS DECIDED BY THE ROOM, NOT THE BALL (2026-08-10, the owner: *"some of the cell labels
    //   are not in the wall style"*).  The gate was `cell.r > 24` — the radius the PILE asked for, before
    //    the power cut took it away wherever a neighbour pressed.  So it answered the wrong question in
    //     both directions: a fat little cell (r 20, a near-round 1200px² of wall) was refused the carve
    //      and fell back to the wave band, while a sliver (r 60, 400px² of shard) kept the full masonry
    //       treatment on a wall that could not hold it.  `never-measure-a-foam-cell-by-its-radius`, again,
    //        in the furniture this time rather than in the tally.
    //  CARVE_ROOM is the area at which the 130° band can hold a few characters (r_eq ≈ 17 ⇒ ~38px of
    //   arc).  It is deliberately LOOSER than the old radius gate for a round cell (π·24² = 1810) and
    //    tighter for a shard, which is the whole correction.  Fuzzed at 1500 first and the number was
    //     WRONG in the direction that matters: on a 5,398-cell calm fuzz it took the carve from 94% to
    //      82%, i.e. it answered "some labels are not in the wall style" by making more of them not be.
    //  WHAT THE DEMOTED CELLS FELL BACK TO IS THE REAL BUG.  `wave_d` is drawn off the cell's BBOX top
    //   edge — and a foam cell never reaches its own bbox corner (the same fact that made the corridor
    //    read as detached furniture, 2026-08-09).  So every uncarved foam cell's label is a band and a
    //     tab hanging in space ABOVE the body, worst of all on a shard, whose bbox is large and empty.
    //      That is the "not in the wall style" the owner can see, and demoting cells into it is exactly
    //       backwards.  So in a world that CAN carve, the wave band is not a fallback at all: a cell too
    //        small to hold the masonry states its name in the middle of its own body instead, and one
    //         too small even for that is not drawn (the vanish floor).  Everything stays ON the cell.
    const CARVE_ROOM = 900
    function room_of(cell: PaintCell): number { return cell.room ?? 0 }
    // the WORLD can carve (it has the ball law and the composer didn't pull `wave`); whether a given
    //  cell does is a question about that cell's room.  Split because the fallback differs: a carveable
    //   world falls back to the body, a non-carveable one has no wall law and keeps the wave.
    //  A SEATED cell is a rectangle, so the arc band is meaningless on it — and `wave_d`, the
    //   scalloped band struck along the bbox TOP EDGE, stops being the floating furniture it was over
    //    a ball (2026-08-10) and becomes exactly right: on a rect the bbox top edge IS the top wall.
    //     The label style that had to be worked around for the foam is native here.
    function carveable(w: TheC): boolean { return !!(w.c as any).foam && !seat_on(w) && !fo(w, 'wave') }
    function wall_carve(w: TheC, cell: PaintCell): boolean {
        return carveable(w) && cell.kind === 'poly' && room_of(cell) >= CARVE_ROOM
    }
    const RAD = Math.PI / 180
    // THE BAND RIDES THE REAL WALL (2026-08-09, the owner: *"the `A $Shuffle:5` label curves should
    //  actually fit onto the side of the cell — they are inset a little bit"*).  A ball's radius is
    //   NOT its wall: the pile solves radii, then the power cut takes them away wherever a neighbour
    //    presses and leaves them long wherever nothing does, so an arc struck at `r` sits inside the
    //     wall on every free side — which is exactly the "inset a little bit" that was visible.  So
    //      cast a ray from the seed at each sampled degree and land on the POLYGON boundary, pulled
    //       in by the band's own half-stroke so the masonry lies IN the wall rather than across it.
    //  `wall_pt` falls back to the circle when there is no poly (disc cells, departing cells) — the
    //   old behaviour, unchanged, so nothing that lacked a wall changes byte.
    const BAND_IN = 8               // half the band stroke: the band's spine, not its outer lip
    function ray_hit(poly: Pt[], cx: number, cy: number, ux: number, uy: number): number {
        // nearest positive t where centre + t·u crosses an edge; 0 if the ray escapes (seed outside)
        let best = 0
        for (let i = 0; i < poly.length; i++) {
            const p = poly[i], q = poly[(i + 1) % poly.length]
            const ex = q.x - p.x, ey = q.y - p.y
            const den = ux * ey - uy * ex
            if (Math.abs(den) < 1e-9) continue
            const wx = p.x - cx, wy = p.y - cy
            const t = (wx * ey - wy * ex) / den           // along the ray
            const s2 = (wx * uy - wy * ux) / den          // along the edge, must be in [0,1]
            if (t > 0 && s2 >= 0 && s2 <= 1 && (best === 0 || t < best)) best = t
        }
        return best
    }
    function wall_pt(cell: PaintCell, deg: number, inset = BAND_IN): { x: number, y: number } {
        const ux = Math.cos(deg * RAD), uy = Math.sin(deg * RAD)
        const poly = cell.poly
        let t = poly && poly.length > 2 ? ray_hit(poly, cell.x, cell.y, ux, uy) : 0
        if (!(t > 0)) t = cell.r                          // no wall to find: the ball is the wall
        t = Math.max(t * 0.35, t - inset)                 // never collapse a thin lobe onto the seed
        return { x: cell.x + t * ux, y: cell.y + t * uy }
    }
    function arc_pt(cell: PaintCell, deg: number): { x: number, y: number } {
        return wall_pt(cell, deg)
    }
    // ── FURNITURE FOLLOWS THE VISIBLE WALL (2026-08-09, the owner: *"we just regressed our ability to
    //  label and A-tip the cells properly"*).  Both pieces of furniture sit on a FIXED side of the
    //   cell — the label over the top (bearings 205°→335°), the tail out to the left (198°…250°) —
    //    which was correct for as long as every cell sat inside the frame.  The stage broke that
    //     assumption on purpose: the primary is pinned left and sized past the frame, so its top and
    //      its left flank are both OUTSIDE the viewport, and its name and tail were being drawn where
    //       nobody can see them.
    //  So a cell that overflows puts its furniture on the side facing back INTO the view.  A cell that
    //   fits keeps its default bearings exactly, which is every cell in every Book — this cannot move
    //    a fixture, and it costs a bbox test per furnished cell.
    //  The rule is about the VIEW, not about the stage: any future law that pushes a cell off an edge
    //   inherits the fix instead of re-discovering it.
    function furn_dir(w: TheC, cx: number, cy: number, cr: number, dflt: number): number {
        const c: any = cam_view(w)
        if (!c) return dflt
        const fits = cx - cr >= c.x && cx + cr <= c.x + c.w && cy - cr >= c.y && cy + cr <= c.y + c.h
        if (fits) return dflt
        const ex = (c.x + c.w / 2) - cx, ey = (c.y + c.h / 2) - cy
        if (!(Math.hypot(ex, ey) > 1)) return dflt          // dead centre and still overflowing: no better side
        return ((Math.atan2(ey, ex) / RAD) + 360) % 360
    }
    function arc_d(w: TheC, cell: PaintCell): string {
        // a 130° window, by default 205°→335° (over the top), sampled every 6.5° and drawn as a smooth
        //  spline through the wall hits, so the band bends with a lobed cell instead of ignoring it.
        //   An overflowing cell rotates the whole window to face back into the view.
        const mid = furn_dir(w, cell.x, cell.y, cell.r, 270)
        const pts: { x: number, y: number }[] = []
        for (let deg = mid - 65; deg <= mid + 65.01; deg += 6.5) pts.push(wall_pt(cell, deg))
        if (pts.length < 2) return ''
        const f = (v: number) => v.toFixed(1)
        let d = `M ${f(pts[0].x)} ${f(pts[0].y)}`
        for (let i = 1; i < pts.length - 1; i++) {
            const m = { x: (pts[i].x + pts[i + 1].x) / 2, y: (pts[i].y + pts[i + 1].y) / 2 }
            d += ` Q ${f(pts[i].x)} ${f(pts[i].y)} ${f(m.x)} ${f(m.y)}`
        }
        const last = pts[pts.length - 1]
        d += ` L ${f(last.x)} ${f(last.y)}`
        return d
    }
    // ── THE DROPLET TAIL (2026-08-09, the owner: *"the A thing is actually supposed to be a little
    //  outward-pointing spike in the cell wall, like a droplet tail… you have to composite it onto the
    //   cell somewhere sensible, like a sharp corner, and the only mark it is besides the shape of the
    //    cell near it is that triangle inside the space of the A, where its shape can be manipulated
    //     from"*).  The old gate was a GLYPH — three little strokes standing on the wall ring at a fixed
    //      205°, which is why it read as furniture stuck on the cell and why it "had a very hard time"
    //       every previous attempt: it was never part of the body it belonged to.
    //  So it is not drawn as an A at all.  A tail is grown OUT of the cell's own sharpest outward corner
    //   and filled with the cell's own ground, so the silhouette itself grows the spike — and the only
    //    added mark is the COUNTER, the triangular hole punched inside it.  Two legs splaying from an
    //     apex around a triangular counter IS an A; nobody has to draw one.  One path, `fill-rule
    //      evenodd`, outer subpath then inner: the hole is real, not a second fill faking it.
    //  The counter is the working part — the handle the dose is dragged from — which is exactly the
    //   owner's "where its shape can be manipulated from".
    function spike_of(poly: Pt[] | undefined, cx: number, cy: number, cr: number, want: number):
            { poly: Pt[], apex: Pt } | null {
        if (!poly || poly.length < 3 || !(cr > 24)) return null
        const cell = { x: cx, y: cy, r: cr }
        const n = poly.length
        // ── WHERE THE TAIL GOES (2026-08-09, the owner: *"the A-tips should avoid being on top of each
        //  other somehow… perhaps the A-tip is always to the left of the cell-wall label"*).
        //  Both halves of that are one rule.  "Sharpest corner" was a LOCAL choice — every cell picked
        //   independently, so two neighbours facing each other across a seam both grew a tail into the
        //    same gap and the tips collided.  A tail placed by ANGLE is placeable by agreement instead:
        //     the wall band runs 205°→335°, so "left of the label" is the approach to 205°, and that is
        //      the wanted angle.  When it is taken, the next candidate angle is tried — which is how the
        //       tips stop landing on each other without anyone needing to know about anyone else.
        //  So the corner is chosen as the one nearest the wanted bearing (still preferring a genuine
        //   promontory over a dent), and the CALLER sweeps the candidate bearings.
        const wrap = (d: number) => ((d % 360) + 360) % 360
        let bi = -1, best = -Infinity
        for (let i = 0; i < n; i++) {
            const v = poly[i], p = poly[(i - 1 + n) % n], q = poly[(i + 1) % n]
            const ux = v.x - p.x, uy = v.y - p.y, vx = q.x - v.x, vy = q.y - v.y
            const lu = Math.hypot(ux, uy), lv = Math.hypot(vx, vy)
            const out = Math.hypot(v.x - cell.x, v.y - cell.y) / Math.max(1, cell.r)
            const deg = wrap(Math.atan2(v.y - cell.y, v.x - cell.x) / RAD)
            let off = Math.abs(wrap(deg - want) > 180 ? 360 - wrap(deg - want) : wrap(deg - want))
            const near = 1 - Math.min(1, off / 90)             // 1 on the bearing, 0 a quarter-turn away
            const turn = lu > 4 && lv > 4
                       ? -((ux / lu) * (vx / lv) + (uy / lu) * (vy / lv)) : 0
            // bearing dominates (it is the rule the owner asked for); sharpness and reach only break ties
            const score = near * 1.0 + turn * 0.25 + out * 0.25
            if (score > best) { best = score; bi = i }
        }
        if (bi < 0) return null
        const v = poly[bi], p = poly[(bi - 1 + n) % n], q = poly[(bi + 1) % n]
        // outward along the seed→corner ray: the seed is inside its own cell, so this always points out
        const ox = v.x - cell.x, oy = v.y - cell.y, lo = Math.hypot(ox, oy) || 1
        const ux = ox / lo, uy = oy / lo
        const len = Math.max(11, Math.min(30, 0.3 * lo))
        // THE BASE IS SET BY THE LENGTH, NOT BY THE EDGES.  Backing off along the two polygon edges
        //  looked principled and produced a NEEDLE — the first live capture came back 7.5px wide over
        //   33px long, because a corner's edges can be any length at all, and a counter scaled inside
        //    that was ~3px: invisible, and far too small to be the handle it is supposed to be.  So the
        //     triangle is built from the spike itself — isoceles about the outward ray, half-width a
        //      fixed fraction of the length — which fixes its aspect no matter what corner it grew from.
        //  The base sits slightly INSIDE the wall so the tail merges into the body instead of balancing
        //   on the vertex.
        const halfw = Math.max(6, Math.min(17, 0.42 * len))
        const sink = halfw * 0.4
        const a = { x: v.x - (-uy) * halfw - ux * sink, y: v.y - ux * halfw - uy * sink }
        const b = { x: v.x + (-uy) * halfw - ux * sink, y: v.y + ux * halfw - uy * sink }
        const apex = { x: v.x + ux * len, y: v.y + uy * len }
        void p; void q
        // the counter — the same triangle shrunk about its own centroid and nudged toward the apex, so
        //  the hole sits high in the tail where an A's counter sits.  Its centre is the drag handle.
        // SPLICED INTO THE WALL, not laid over it (2026-08-09, the owner: *"can you seamlessly do the
        //  A-tip as part of the cell? it's just like a teardrop except with a bar across it there"*).
        //  The previous cut drew the tail as its own <path> in the cell's colours — which looks seamless
        //   only while the two agree about fill, stroke, opacity, hover, sink and paint order, and they
        //    never agree for long.  So the tail is not drawn at all now: its three points are SPLICED
        //     INTO THE POLYGON in place of the corner they grew from, and the cell path is built from
        //      that.  One outline, one stroke, one fill — the wall simply has a teardrop on it, and
        //       every state the cell can be in carries the tail for free because it IS the cell.
        //  What is left to draw is the owner's other half: the BAR across it.  Teardrop + bar = the A,
        //   and the bar is the handle.
        // THE CUTE BLOB (2026-08-09, the owner: *"these actual triangle A-tips look terrible, I like the
        //  cute blob-tail looking ones I got excited about before"* / *"lets just make them do nothing,
        //   just for cuteness"* / *"software isn't cute enough"*).
        //  The blobs were the SPLICED construction and nobody realised that at the time, including me:
        //   spliced points go through `path_round` with everything else, so the tip comes out as a soft
        //    rounded bump growing off the wall.  Drawn as its own path it is a hard-edged triangle
        //     sitting next to the cell, which is the thing that looks terrible.  Same three points —
        //      the difference is entirely whether the outline owns them.
        //  So: splice, no separate path, no counter, no bar, nothing to click.  A cell simply has a
        //   soft tail on one side, and the shape cannot occlude anything because it IS the shape.
        //  Extra rounding room: the base is widened and the tip pulled in a little, because
        //   `path_round` caps its radius at 0.4 of the shortest adjoining edge — a long thin spike
        //    rounds barely at all, and a stubby one rounds into an actual blob.
        const wide = { x: a.x + (a.x - b.x) * 0.16, y: a.y + (a.y - b.y) * 0.16 }
        const wideb = { x: b.x + (b.x - a.x) * 0.16, y: b.y + (b.y - a.y) * 0.16 }
        const tip = { x: v.x + ux * len * 0.8, y: v.y + uy * len * 0.8 }
        return { poly: poly.slice(0, bi).concat([wide, tip, wideb], poly.slice(bi + 1)), apex: tip }
    }
    // the spill arc — a second band inside the name's, carrying the row's own scalars as one line.
    //  Its length is the wall's, so how much detail a cell states is decided by how much wall it has;
    //   under ~9 characters' worth there is nothing worth saying and it returns null.
    function spill_of(cell: PaintCell): { d: string, text: string } | null {
        const inset = 21
        const pts: { x: number, y: number }[] = []
        for (let deg = 208; deg <= 332.01; deg += 6.5) pts.push(wall_pt(cell, deg, BAND_IN + inset))
        if (pts.length < 3) return null
        let len = 0
        for (let i = 1; i < pts.length; i++) len += Math.hypot(pts[i].x - pts[i - 1].x, pts[i].y - pts[i - 1].y)
        const room = Math.floor(len / 4.6)               // ~4.6px per glyph at 9px monospace-ish
        if (room < 9) return null
        const guts = under_guts(cell.row, 7)
        if (!guts.length) return null
        let text = guts.join(' · ')
        if (text.length > room) text = text.slice(0, Math.max(1, room - 1)) + '…'
        const f = (v: number) => v.toFixed(1)
        let d = `M ${f(pts[0].x)} ${f(pts[0].y)}`
        for (let i = 1; i < pts.length - 1; i++) {
            const m = { x: (pts[i].x + pts[i + 1].x) / 2, y: (pts[i].y + pts[i + 1].y) / 2 }
            d += ` Q ${f(pts[i].x)} ${f(pts[i].y)} ${f(m.x)} ${f(m.y)}`
        }
        d += ` L ${f(pts[pts.length - 1].x)} ${f(pts[pts.length - 1].y)}`
        return { d, text }
    }
    // ── THE BARE SETTING (2026-08-09, the owner: *"Bare mode should just mean no Component, should
    //  still look all fancy… Bare only as in no illusions about data representation, just stating the
    //   C** like a snap, but with good composition, like a good piece of typographic art"*).
    //  The first cut of bare was an ABSENCE — drop the face and let whatever was left show through.
    //   That is not what was asked for.  Bare is a SURFACE: the particle stated plainly, and set
    //    properly.  A snap's own hierarchy is the typographic hierarchy — the mainkey IS the title
    //     (it is what the thing IS), its value is the subject, and the remaining scalars are the
    //      supporting matter — so the setting does not have to invent a structure, only honour the
    //       one the data already has.
    //  Three registers, one measure: title at the top of the block, an oversized value beneath it,
    //   then key/value pairs where the KEY is small, spaced and quiet and the VALUE carries the ink.
    //    Everything is centred on the seat and scaled by one factor, so composition survives any cell
    //     size — and below the point where the supporting matter would be illegible it is simply
    //      dropped, title first out, rather than shrunk into grey mush.
    function bare_set(cell: PaintCell): { title: string, value: string, rows: [string, string][], k: number } | null {
        const sc: any = cell.row?.sc; if (!sc) return null
        const keys = Object.keys(sc); if (!keys.length) return null
        const mk = keys[0]
        const val = sc[mk] == null || sc[mk] === 1 ? '' : String(sc[mk])
        const rows: [string, string][] = []
        for (let i = 1; i < keys.length; i++) {
            const k = keys[i]
            if (GUT_SKIP.has(k)) continue
            const v = sc[k]
            if (v == null || typeof v === 'object') continue
            let s = String(v); if (s.length > 20) s = s.slice(0, 19) + '…'
            rows.push([k, s])
        }
        // one scale for the whole block, from the room the wall actually gives (ray-measured, like the
        //  component seat) — so bare and faced cells are composed against the same geometry.
        const want_w = 150, want_h = 46 + rows.length * 15
        let byray = Infinity
        for (const [qx, qy] of [[1, 1], [1, -1], [-1, 1], [-1, -1], [1, 0], [-1, 0], [0, 1], [0, -1]]) {
            const ex = (want_w / 2) * qx, ey = (want_h / 2) * qy
            const L = Math.hypot(ex, ey); if (!(L > 0)) continue
            const t = ray_hit(cell.poly ?? [], cell.x, cell.y, ex / L, ey / L)
            if (t > 0) byray = Math.min(byray, Math.max(0, t - 4) / L)
        }
        let k = Number.isFinite(byray) ? byray : 1
        k = Math.max(0.34, Math.min(1.6, k))
        // drop supporting matter rather than shrink it past reading
        const room = Math.max(0, Math.floor((k * want_h - 46 * k) / (15 * k)))
        return { title: mk, value: val, rows: rows.slice(0, Math.max(0, Math.min(rows.length, room))), k }
    }
    function arc_id(w: TheC, cell: PaintCell): string {
        return 'vyarc-' + String((w.sc as any)?.w ?? 'w').replace(/[^A-Za-z0-9_-]/g, '')
             + '-' + cell.key.replace(/[^A-Za-z0-9_-]/g, '-')
    }

    // ── KEEP-RUNNING LAYOUT (the owner: "needs more redraw or keep running layout buttons like
    //  cyto had").  Simmer: the model jitters every unpinned seat a few px per tick
    //   (Vyto_simmer_tick — deterministic, counter-hashed) and the pile re-settles around the
    //    disturbance, so the foam visibly keeps negotiating.  Renderer interval, live pages
    //     only, torn down with the stage — a Book never simmers and no fixture can. ──
    // ── BARE MODE — THE GLASS WITHOUT COMPONENTS (2026-08-09, the owner: *"I think I want to have a
    //  tab I can click to try a no-Components version of this interface.  I just want cellular trees of
    //   the information in the thing right now, and some of them have click handlers magically… it's
    //    like building yet another web-framework thing within a thing within a thing"*).
    //  The last sentence is the reason this is worth having as a SWITCH rather than an argument.  Every
    //   face is a Svelte component with its own layout, its own measure, its own idea of how big it
    //    wants to be — a second framework living inside the cut, and most of the hard bugs of the last
    //     two days (the puddle, the crush, the need floor, the seat) came from the seam between the two
    //      rather than from either side.  Bare mode simply removes that seam: no molds mount, no faces
    //       measure, no `need_area` is stamped, and what is left is the thing itself — the cut, the
    //        names, the details spilled along the wall, and whatever a particle chose to make clickable.
    //  Per TAB, never snapped: a view preference is not world state, and a Book must never see it.
    //   Books are additionally locked out below, so no fixture can move whatever a human left toggled.
    const bare = new Set<TheC>()
    let bare_flip = $state(0)
    // BARE STAYS A CHOICE, NEVER A CONSEQUENCE (the owner 2026-08-09: *"twas looking pretty good
    //  until you switched on bare. back that out"*).  A plain commission briefly forced this true so
    //   faceless particles would draw their own set; the cost was that it took the faces off cells
    //    that HAVE them and want them.  A faceless cell already states itself (ident + wall spill) —
    //     that is enough, and it costs the faced cells nothing.  ▢ is the only thing that sets it.
    function bare_on(w: TheC): boolean { void bare_flip; return bare.has(w) }
    // (bare_toggle, seat_toggle and their shared view_repaint went out with the toybox, 2026-08-10 —
    //  a view switch must force its own repaint if a toggle ever returns: paint_tick bumps only when
    //   geometry MOVES, so a regime/face flip needs paint_world + paint_tick++ + kick by hand.)
    // ── THE TWO POSES (2026-08-09, the owner: *"we need some simulation of them competing for
    //  attention… or engaging some pose where they are all fairly equal"*).
    //  ≡ EVEN flattens every price to one base, so the cut states its STRUCTURE alone — pricing is what
    //   makes a glass legible and also what hides its shape, and this is the switch between the two.
    //  ⚔ COMPETE hands the attention coin round the ring on a tick.  It needed no new machinery: heat
    //   is already earned by being attended, already self-taxing (everyone else cools 4% per grant),
    //    and already spent by express as size — a competition is simply nobody being the reader.
    //  Both live-page only, both torn down with the stage, so no Book can see either.
    const competing = new Map<TheC, ReturnType<typeof setInterval>>()
    let pose_flip = $state(0)
    function compete_on(w: TheC): boolean { void pose_flip; return competing.has(w) }
    function even_on(w: TheC): boolean { void pose_flip; return !!(w.c as any).even }
    function compete_toggle(w: TheC) {
        const t = competing.get(w)
        if (t) { clearInterval(t); competing.delete(w) }
        else if (live_page() && !fo(w, 'still')) competing.set(w, setInterval(() => (H as any).Vyto_compete_tick?.(w), 700))
        pose_flip++
    }
    function even_toggle(w: TheC) { (H as any).Vyto_even_toggle?.(w); pose_flip++ }
    const simmering = new Map<TheC, ReturnType<typeof setInterval>>()
    let simmer_flip = $state(0)     // the ∿ button reads this to light up
    function simmer_on(w: TheC): boolean { void simmer_flip; return simmering.has(w) }
    function simmer_toggle(w: TheC) {
        const t = simmering.get(w)
        if (t) { clearInterval(t); simmering.delete(w) }
        else if (live_page() && !fo(w, 'still')) simmering.set(w, setInterval(() => (H as any).Vyto_simmer_tick?.(w), 900))
        simmer_flip++
    }
    onDestroy(() => {
        for (const t of simmering.values()) clearInterval(t)
        for (const t of competing.values()) clearInterval(t)
    })

    // ── THE HAND IS OFF THE GLASS (2026-08-10, the focus pivot: *"currently we can drag cells
    //  around (although it's far too slow to be visually nice) and click to enlarge them, and click
    //   another button to reset them all, all that I want GONE!"* / *"I guess we still want the
    //    STAGING a blob to be a programmatic process back there"*.)
    //  The ball-grab, the drag pin, the stage band drop target, the ⤫ unstage and ⇱ release chips
    //   all came out together — they were one gesture family, and the family's job (deciding what
    //    is big) belongs to the COMMISSION now.  `Vyto_stage`/`stage_want` stay model verbs: a
    //     heist stages itself programmatically ("STAGING for Heist is important"), which is why
    //      staged_tok below survives — the paint still marks the staged body, no hand required.
    function staged_tok(w: TheC): string | null { void paint_tick; return ((w.c as any).stage_tok ?? null) }
    // rows the cut could not seat: a disc cell that is not LOOSE (loose is a choice, unseated is not).
    // ⚠ AND NOT DEPARTING.  A cell on its way out is emitted `kind: 'disc'` too (it has no wall left to
    //  cut), so the old count reported every leaving cell as a row the cut REFUSED — an accusation about
    //   crowding raised by an animation finishing normally.  The number the owner read as "3 not seated"
    //    could be three cells politely leaving.  A report has to be able to name its rows or it cannot be
    //     checked, which is the other half of this: it now returns the cells, not a tally.
    function unseated_cells(w: TheC): PaintCell[] {
        const out: PaintCell[] = []
        for (const c of viewport_cells(w)) { if (c.kind === 'disc' && !c.loose && !c.departing) out.push(c) }
        return out
    }

    // THE CLUTTER KNOB AND THE TOYBOX ARE GONE WITH THE HAND (2026-08-10: *"forget the other
    //  buttons. time to slick it all back"*).  The junk fabricator (`Sounditron_junk`) still exists
    //   model-side for a Book that wants a crowded world; only the button that cycled it left.

    // (`sentence` — the organ row's reads/decides/writes line — went with the organ panel, 2026-08-11.)

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
    // THE ASPECT PICK IS GONE, AND MEASURING IS THE ONLY WAY THE FRAME IS SET (2026-08-11, the owner:
    //  *"no aspect ratio"*).  It arrived 2026-08-08 to enforce a min-height, back when the measured
    //   path kept landing on the 0.35 clamp FLOOR and the first pixels of a live glass came back
    //    800×280 — a letterbox strip.  That fault was in the MEASURE (it read the stage's own height,
    //     which is the aspect it had just set — a fixed point at whatever it started as), and fixing
    //      it to take the width from the stage and the height from the screen below it is what made
    //       `auto` right; the dropdown had already been defaulted back to `auto` on 2026-08-10 and
    //        every other option could then only make the glass WORSE than the hole it lives in.
    //  The min-height it was hired for now rides where it belongs — the ratio floor in fit_frame and
    //   `.depth`'s vh cap in the CSS — neither of which is a thing anyone has to press.
    //  The chokepoint is UNCHANGED and is the whole Book guarantee: fit_frame is the only writer of
    //   vw_w/vw_h, publish_frame the only place the model hears about it, and the humdinger gate at
    //    the top of fit_frame still returns first on every runner — so a driven world is never
    //     stamped and Vyto_solve cuts the same literal 800×450 it always did.  Long edge stays 800 so
    //      the model's absolute AREA_BASE algebra keeps its range.
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
        {
            const availW = r.width
            const availH = full ? r.height : Math.max(120, (window.innerHeight || 0) - r.top - 8)
            if (!(availH > 0)) return
            const portrait = availH > availW
            // THE FLOOR *IS* THE MIN-HEIGHT (2026-08-11, the owner: *"when not FaceSucking the Vytui
            //  wants a min-height a bit bigger than it is now"*).  The svg is `width:100%; height:auto`,
            //   so the viewBox ratio renders as height by construction and a pixel min-height would be
            //    the wrong tool — it letterboxes gutters AROUND an unchanged cut (§0.2(d): the cut must
            //     follow the hole).  0.35 dates from when this clamp was all that stood between the
            //      glass and a letterbox strip; 0.5 says a glass is never flatter than 2:1, which on a
            //       short wide window costs a sliver of overflow and buys back a shape you can put a
            //        belly in.  It binds ONLY on wide-and-short; on the resident full-page glass the
            //         measurement is well above it and this line is inert.
            const ratio = Math.min(1, Math.max(0.5, portrait ? availW / availH : availH / availW))
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
    // (`repick_aspect` went with the dropdown — 2026-08-11.  Nothing re-runs fit_frame by hand any
    //  more: the ResizeObserver in reg_stage is the only trigger, which is the honest one.)
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
    const SEAT_AIR = 3        // viewBox units of air between a slab-seated face and its two long walls
    // EVERY LIVE ROW GETS A SEAT (the owner 2026-08-09, on the corner note reading "3 not seated":
    //  *"I think that's what I want to never happen, certainly not to Radio"*).  The smallest cell the
    //   cut is allowed to leave a neighbour, in viewBox units of depth along the pressing axis — the
    //    guarantee the foam has to honour before it may honour anything else.  See the seat floor in
    //     `layout` for why it is expressible as a cap on the AGGRESSOR rather than a floor on the victim.
    const SEAT_MIN = 10
    const VANISH_ROOM = 380   // the floor a cell must clear to be drawn at all — law at its use site

    // ── THE SEAT REGIME (`foamereo:'seat'`) ───────────────────────────────────────────────────────
    //  (the owner 2026-08-10: *"shall we now do a completely other UI for all these cells... one with
    //   way less skittishness, but eating the same model... less failure modes..."* — and, on the
    //    landing: *"don't throw away everything we have? is it going to be switchable?"*)
    //  A THIRD REGIME BESIDE foam AND plain, not a replacement.  It eats the identical model input —
    //   the solve's radii, which ARE Vyto_express's env_area in another dress — and answers with a
    //    deterministic partition instead of a relaxation-then-discovery.  The law, the measured case
    //     against the foam, and the deal are all stated in `vyto_seat.ts`; this is only the wiring.
    //  ADDITIVE: an unset foamereo returns null from `fo`, so every gate below is byte-invisible and
    //   the foam's arithmetic is untouched.  No Book commissions `seat`, so no fixture moves.
    //  WHERE IT PLUGS IN: `polyByKey` — the emit loop downstream reads polygons by key and cares not
    //   at all where they came from, so faces, molds, the dose handle, holds, the decor deck and the
    //    whole label ladder draw a rect exactly as they draw a wall.  Nothing is deleted for this.
    //  TWO WAYS IN, and the local one is the one a human uses.  A composer DECLARES the regime on the
    //   commission (`foamereo:'seat'`) and that is what a Book or a saved glass would carry; a person
    //    presses ▦ and it changes NOW.  The local flip exists because the declared route goes through
    //     `Sounditron_commission` → `i_elvisto` → `Vyto_commission`, which is DEFERRED: on the first
    //      landing two full toggles read as no-ops before the regime appeared, and it looked exactly
    //       like a broken switch.  A view preference should never wait on the model's queue.
    //  Per TAB and never snapped, like `bare` and the two poses — a Book must not see which UI a human
    //   left on, or a fixture would record a view preference as world state.
    function seat_on(w: TheC): boolean { return fo(w, 'seat') != null }
    // The standing deal per scope, per world.  `.c`-side only (never encoded) — the deal is derived,
    //  and stage 4 is where it earns a place in the tree so a Book can witness the layout.
    const dealMemo = new WeakMap<TheC, Map<string, Deal>>()
    // WEIGHT = the SPRUNG radius, not the target.  Deliberate, and it is what buys the motion for
    //  free: the existing integrator already eases every spring's r toward its target and already
    //   keeps the paint loop alive while it does, so the boxes follow that easing without a second
    //    animation system.  The cost is that the box steps by a grid unit rather than gliding — the
    //     rect spring that would smooth it is stage 3, deliberately not smuggled in here.
    function seat_polys(w: TheC, scopeKey: string, keys: string[], radii: number[],
                        framePoly: Pt[], gap: number): (Pt[] | null)[] {
        if (!keys.length) return []
        let bx = Infinity, by = Infinity, bx1 = -Infinity, by1 = -Infinity
        for (const p of framePoly) {
            if (p.x < bx) bx = p.x
            if (p.x > bx1) bx1 = p.x
            if (p.y < by) by = p.y
            if (p.y > by1) by1 = p.y
        }
        const frame = { x: bx, y: by, w: Math.max(1, bx1 - bx), h: Math.max(1, by1 - by) }
        const rows: SeatRow[] = keys.map((k, i) => ({ key: k, weight: Math.PI * radii[i] * radii[i] }))
        if (!dealMemo.has(w)) dealMemo.set(w, new Map())
        const dm = dealMemo.get(w) as Map<string, Deal>
        let deal = dm.get(scopeKey)
        // RE-DEAL IS AN EVENT, and it has exactly two causes.  Membership: these are not the rows the
        //  deal was cut for.  Staleness: the standing deal could not seat everyone at these weights,
        //   which shows up as a short box list (see vyto_seat's strict-axis note — a cut is never
        //    quietly turned to make the numbers work, because turning one IS the teleport).
        let boxes = deal && deal_fits(rows, deal) ? seat_on_deal(rows, deal, frame) : null
        if (!boxes || boxes.length + (deal?.out.length ?? 0) < rows.length) {
            deal = deal_rows(rows, frame)
            dm.set(scopeKey, deal)
            boxes = seat_on_deal(rows, deal, frame)
            ;(w.c as any).re_deals = (((w.c as any).re_deals as number) || 0) + 1
        }
        ;(w.c as any).seat_bad = Math.round(deal_badness(rows, deal as Deal, frame) * 10) / 10
        ;(w.c as any).seat_wait = (deal as Deal).out.length
        const byKey = new Map(boxes.map(b => [b.key, b]))
        return keys.map(k => {
            const b = byKey.get(k)
            if (!b) return null
            const p = box_poly(b, gap)
            return p.length ? p : null
        })
    }

    // ── THE FOCUS REGIME (`foamereo:'focus'`) — one belly, a couple of buds ───────────────────────
    //  (the owner 2026-08-10, the pivot: *"lets only feed Vyto one thing at a time ... the
    //   one-main-thing should look like a big belly, with a couple of purple somethings coming off
    //    it ... I don't want it moving at all after it settles"* / *"strip it right back to just
    //     being an artifact with a big blob to present stuff in"*.)
    //  The geometry, the law and the gates live in `vyto_focus.ts`; this is only the wiring, and it
    //   plugs in at the SAME SEAM the seat did — polyByKey — so faces, molds, labels and the carve
    //    draw a belly exactly as they draw a wall.  ROOT SCOPE ONLY: a nested scope (a heist's
    //     chips inside the belly) keeps the existing tiling, which is how "STAGING for Heist is
    //      important, sometimes is a bunch of info in there" is honoured — the heist IS the belly
    //       and its stuffing tiles inside it.
    //  WHO IS THE BELLY: the row whose source wears `stage_want` (how a heist asks — the model's
    //   programmatic staging, no gesture involved), else the biggest non-%Sat ask.  %Sat rows are
    //    always buds — they are the commission's satellites, never the subject.
    function focus_on(w: TheC): boolean { return fo(w, 'focus') != null }
    function sat_row(row: TheC): boolean {
        const src: any = (row.c as any)?.source_n
        const sc = src?.sc ?? row.sc
        return sc ? Object.keys(sc)[0] === 'Sat' : false
    }
    function focus_cells(live: Node[], keys: string[], radii: number[],
                         framePoly: Pt[], gap: number): (Pt[] | null)[] {
        let bx = Infinity, by = Infinity, bx1 = -Infinity, by1 = -Infinity
        for (const p of framePoly) {
            if (p.x < bx) bx = p.x
            if (p.x > bx1) bx1 = p.x
            if (p.y < by) by = p.y
            if (p.y > by1) by1 = p.y
        }
        const frame = { x: bx, y: by, w: Math.max(1, bx1 - bx), h: Math.max(1, by1 - by) }
        // ── THE COMMISSIONER PICKS THE BELLY, NOT THIS FUNCTION ────────────────────────────────────
        //  (2026-08-10, caught within minutes of the belly ladder landing: the model reported
        //   `belly=Radio` while the glass drew the Door big, and both were working correctly.)
        //  The first cut re-decided here — stage_want, else the biggest radius — which is a SECOND
        //   opinion about the very thing this regime exists to take away from the renderer.  Size is
        //    assigned by the commissioner; so is subjecthood.  `.c.pose:'big'` is that decision
        //     arriving, and it is the only rung that should normally fire.
        //  The two below it are fallbacks for a glass whose commissioner poses nothing (a Book, a
        //   hand-built world): honour a `stage_want`, else take the biggest ask, else row 0 — so an
        //    unposed world still gets a sensible belly instead of nothing.
        let bellyI = -1
        for (let i = 0; i < live.length; i++)
            if (String((live[i].row.c as any)?.source_n?.c?.pose ?? '') === 'big') { bellyI = i; break }
        if (bellyI < 0) for (let i = 0; i < live.length; i++)
            if (!sat_row(live[i].row) && (live[i].row.c as any)?.source_n?.c?.stage_want) { bellyI = i; break }
        if (bellyI < 0) {
            let best = -1
            for (let i = 0; i < live.length; i++)
                if (!sat_row(live[i].row) && (best < 0 || radii[i] > radii[best])) best = i
            bellyI = best < 0 ? 0 : best
        }
        const roles: FocusRole[] = keys.map((_, i) => (i === bellyI ? 'belly' : 'bud'))
        // A STRETCHED BELLY IS SWELLED PAST THE PLATE (the owner 2026-08-11: *"the cell going off the
        //  screen top left and bottom … so we can use half the screen efficiently"*).  Gated on the
        //   same pose that chose the stretch seat, so the player's belly — which is sized from a face
        //    that HAS a natural shape — is untouched: only the thing with no shape of its own takes
        //     the whole room.
        const bellyPose = String((live[bellyI]?.row.c as any)?.source_n?.c?.pose ?? '')
        return focus_polys(frame, keys, roles, gap, bellyPose === 'stretched' ? BELLY_SWELL : 1)
    }

    const OVERHANG = 1.25     // a slab seat may overrun the cell's ends by this factor of its length
    // ⛔ SIDEWAYS IS OUT (the owner 2026-08-09: "ew... very incoherent! forget sidewaysing, I just meant
    //  the box-within-box reality of Component in cell aligned for space efficiency, without tilting
    //   anything more than say 30degrees, or zooming more than so much").  A slab steeper than MAX_TILT
    //    is NOT clamped to 30° (a 30° box in a 70° slab helps nobody) — it falls back to the axis-
    //     aligned seat.  And the scale is bounded both ways: envelope-down survives (the icon floor
    //      needs it) but blow-UP stops at FIT_MAX, because a trivial widget magnified 6× was half the
    //       incoherence.
    const MAX_TILT = Math.PI / 6   // 30°
    const FIT_MAX = 1.6
    // …and the focus belly's ceiling, which is a different question with a different answer (see the
    //  note at the fit clamp).  Not Infinity: a face IS still laid out at `100%/fit` and scaled back,
    //   so an unbounded blow-up would hand a component a sub-pixel layout box to reflow inside.
    const BELLY_FIT_MAX = 4.5
    // THE STRETCH IS A COLUMN, NOT A CANVAS (2026-08-10, the owner on the fullscreen capture: *"the
    //  Heist is all tiny when fullscreened... the X button and row is the only spacing out thing...
    //   it should be told it is skinnier and zoomed in.  everything wants to be round, then we see
    //    how big it really is"*).
    //  The first cut handed the face the whole rectangle and zoomed it 1.3×.  Fullscreen showed why
    //   that is not "maxed out": a face's type is hardcoded px, so a wider BOX does not make a bigger
    //    FACE — it only lets the flex rows drift apart, which is exactly the one thing that visibly
    //     changed (the `start … LOFI … ✕` row spanning 1900px of empty purple).  Room went to the gaps.
    //  So the face is told it is SKINNY — laid out in a fixed reading column — and the room is spent
    //   on ZOOM instead, which is the only unit that reaches hardcoded px.  `fit = rect / column`, so
    //    the bigger the belly the bigger the type, and *"then we see how big it really is"*.
    //  360 is chosen so the current window lands on the owner's 1.3 and fullscreen grows from there —
    //   the 130% is not lost, it is the bottom of the range.
    //  …AND THE COLUMN CANNOT BE GUESSED — IT HAS TO BE SEARCHED (2026-08-10, the owner: *"Heist is
    //   tiny... needs more rounds of measuring."*).  A fixed column was still too wide: measured live,
    //    the belly's inscribed rectangle was 410 units and the column 360, so `rect / col` left a zoom
    //     of 1.14 — the floor — and the face stayed *"tiny"*.  Narrowing the column blindly does not
    //      fix it either: a narrower column makes the content TALLER, and past some point the height
    //       binds instead and the zoom falls again.  **The zoom is `min(rect_w/col, rect_h/height)`,
    //        and `height` is a function of `col`** — so there is a best column, and the only way to
    //         find it is to try one, measure what came back, and step.  That is the owner's "more
    //          rounds": the search lives in the measure pass, and it sits still inside a dead band.
    //  …AND IT STEPPED WHERE IT COULD HAVE SOLVED (2026-08-11, the owner: *"can we size the Heist
    //   Component slightly smoother than it does now"*).  A fixed ±18% step is a STAIRCASE: every round
    //    is a real relayout at a visibly different column and zoom, so a heist settles through three to
    //     six sizes on its way in, and every content change walks the staircase again.  That is the
    //      unsmoothness — not the final size, the parade of sizes before it.
    //  But the column is not an unknown to be hunted, it is an unknown to be SOLVED.  Wrapped content
    //   holds its area roughly constant (`h ≈ A/col`), so one measurement gives A, and balancing
    //    `rect_w/col` against `rect_h/h` is then a quadratic with one positive root:
    //     **`col* = √(rect_w · col · h / rect_h)`**.  One measured round lands on it or very near it,
    //      and what follows is a small correction rather than another step of the same size.
    //  The model is only approximately true (a heist has fixed-height rows that do not reflow), so the
    //   safeties stay: the leap is bounded, the result is clamped, a correction under NUDGE is not
    //    worth a relayout at all, and the 2-cycle guard is untouched.
    const STRETCH_COL0 = 300        // where the search starts, in viewBox units of layout width
    const STRETCH_COL_MIN = 150     // skinnier than this and a heist is a column of wrapped fragments
    const STRETCH_COL_MAX = 520
    const STRETCH_LEAP = 2          // no round may change the column by more than this factor
    const STRETCH_NUDGE = 0.04      // a correction smaller than 4% is not worth the relayout it costs
    const STRETCH_BAND = 1.08       // within 8% of balanced, stop: this is what makes it settle
    const STRETCH_ZOOM_MIN = 1.3    // the owner's 130%, as the floor
    // foam fill targets: what fraction of a scope's area the discs may claim before pressing.
    //  Top cut leaves real margin (the rim curvature + the empty ground ARE information); a nested
    //   bag packs near-full (a membrane holds what it holds).
    const FOAM_FILL = 0.8
    const FOAM_FILL_NESTED = 0.95

    // kp/ks are the LAST INTEGRATED calm strengths for this spring's two channels (position, size),
    //  cached by integrate_world so the settle test can skip a PINNED channel without re-running
    //   Vyto_calm_held (a real query) a second time per cell per frame.  Optional because a spring
    //    minted by `adopt` has not been integrated yet; `?? 1` at the read sites treats an
    //     un-integrated spring as free, which is what it was before it had these fields at all.
    type Spring = { x: number, y: number, r: number, vx: number, vy: number, vr: number, kp?: number, ks?: number,
                    ltx?: number, lty?: number }   // last SEEN target — the galaxy-morph jump detector (foam only)
    // key: a TREE-unique identity (tok at the root, parentKey>tok below) — springs, lift, and the
    //  keyed {#each} are all keyed by it, because a mirror tok is only LOCALLY unique (two byte-
    //   identical cousins share a tok).  depth/hasKids drive the nested look: a cell that is a scope
    //    (its children tile it) suppresses its OWN label + face and renders as a bare frame.
    //  mx/my/mw/mh is the MOLD box (where the face sits — the slab seat when one is found, the AABB
    //   otherwise) and ang its rotation; bx/by/bw/bh stays the cell's AABB, which is what the edge
    //    label + guts rail hang off.  Two boxes because they answer different questions: "where is the
    //     cell" vs "where does the component lie".
    type PaintCell = { tok: string, key: string, depth: number, hasKids: boolean,
                       ident: string, x: number, y: number, r: number,
                       kind: 'poly' | 'disc', d: string, departing: boolean, lift: boolean,
                       bx: number, by: number, bw: number, bh: number,
                       mx: number, my: number, mw: number, mh: number, ang: number, clip: string,
                       face: any | null, source: TheC | null, row: TheC,
                       fx: '' | 'arrive' | 'erupt', fxi: number, fit: number, loose?: boolean,
                       zi?: number, sunk?: boolean, poly?: Pt[],
                       // ROOM — the polygon's own area.  Every furniture gate used to ask `r` or the
                       //  bbox, and neither is the cell: `r` is the ball the pile ASKED for before the
                       //   power cut took it away, and a diagonal sliver has a big bbox holding almost
                       //    nothing.  This is what the cell actually got, and it is what decides what
                       //     the cell can afford to say.  Absent on disc cells (they have no wall).
                       room?: number,
                       // the SELF SEAT: this cell is a scope's own face taking a seat among its
                       //  children.  It is drawn to belong to its parent, not to sit beside it.
                       selfseat?: boolean,
                       spike?: { poly: Pt[], apex: Pt } | null }

    // (inscribed_of is GONE, 2026-08-09 — it was already unseated by the AABB+clip regime and it
    //  carried the adversarial review's A1: the gap inset in power_cells pulls vertices toward the
    //   vertex MEAN by a fixed distance, which is not convexity-preserving, so "convex by construction"
    //    was not a property its containment test could actually lean on.  The seat questions it used to
    //     answer now live in slab_seat (vyto_geometry.ts, pure, node-testable) and clip_of below.)

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

    // ── THE SEAT FLOOR — NO ROW MAY BE SWALLOWED WHOLE ────────────────────────────────────────────
    //  (the owner 2026-08-09, reading "3 not seated" in the corner: *"I think that's what I want to
    //   never happen, certainly not to Radio ... it's too much of a crush, we should be able to click
    //    back into it to share the focus across more things"*.)
    //  A foam cell is its own ball, trimmed by a wall wherever a neighbour's ball presses.  When a
    //   neighbour grows big enough to CONTAIN this one, that wall lands behind this seed and the clip
    //    empties the polygon: `foam_cells` returns null and the row leaves the paint entirely.  That is
    //     not a crush, it is ABSENCE — no wall, no face, no label, and (the part that makes it
    //      unrecoverable rather than merely small) NO CLICK TARGET, because the press handler lives on
    //       the <path> a null-poly cell never gets.  You cannot attend your way back into a cell that
    //        isn't there, so the crush ladder used to bottom out in a trapdoor.
    //  The swallow is pure geometry — j eats i exactly when `r_j ≥ d + r_i` — so it can be FORBIDDEN in
    //   closed form rather than detected afterwards.  Solving "leave i at least SEAT_MIN of cap depth
    //    along the pressing axis" for r_j gives the cap below.  THE AGGRESSOR IS WHAT GIVES WAY, which is
    //     the owner's own reading of the fault: emphasis is bounded by the survival of the least, so no
    //      focus boost, stage deal or dose can buy one cell more room than the glass actually has.
    //  It never shrinks a body below its victim (`min(cr[i], cr[j])`), so a pair where j is the SMALLER
    //   one is untouched — the guard only ever takes room off whoever was taking too much.
    //  `victims`/`mult` are THE REPAIR PASS's handle (see the call site).  Pairwise closes 98.5% of the
    //   swallows on a 19k-cell fuzz but not all: a cell can also be killed by the ACCUMULATION of several
    //    neighbours, each of which individually left it a legal seat, and no pairwise form can see that.
    //     Raising the demand for the rows that actually died — and re-cutting — takes it to zero.
    //  BYTE-NEUTRAL WHERE NOTHING IS SWALLOWED: the cap only lowers a radius that was about to empty a
    //   neighbour, and the floor only raises one too thin to cut at all, so a healthy scope's arithmetic
    //    is untouched.  RENDERER-SIDE ONLY: Vyto.g runs its own foam_cells for the model and is
    //     deliberately not touched here, so this cannot move a single recorded fixture.
    function seat_floor(seeds: Pt[], radii: number[], gap: number,
                        victims: Set<number> | null, mult: number): number[] {
        const cr = radii.slice()
        // a ball thinner than the breath between cells has no cell to cut — the OTHER null branch in
        //  foam_cells (`R = r - gap/2 <= 0`), and the one a zero-dose row falls down.
        const MIN_BALL = gap / 2 + 3
        for (let i = 0; i < cr.length; i++) if (cr[i] < MIN_BALL) cr[i] = MIN_BALL
        // three sweeps: capping an aggressor can in principle expose it to a third ball.  A FIXED sweep
        //  count, not a while-loop — the cut must stay deterministic (solver law 4).
        for (let pass = 0; pass < 3; pass++) {
            let moved = false
            for (let i = 0; i < cr.length; i++) {
                const want = SEAT_MIN * (victims?.has(i) ? mult : 1)
                for (let j = 0; j < cr.length; j++) {
                    if (i === j) continue
                    const d = Math.hypot(seeds[j].x - seeds[i].x, seeds[j].y - seeds[i].y)
                    if (d < 0.5) continue
                    const reach = d + cr[i]
                    const roomy = Math.sqrt(Math.max(0, reach * reach - 2 * d * (gap + want)))
                    const cap = Math.max(roomy, Math.min(cr[i], cr[j]))
                    if (cr[j] > cap) { cr[j] = cap; moved = true }
                }
            }
            if (!moved) break
        }
        return cr
    }

    // ── THE FRAME SEAT — NO ROW MAY BE DRAWN OFF-FRAME ────────────────────────────────────────────
    //  The seat floor's sibling, and the OTHER half of the owner's ruling ("I think that's what I want
    //   to never happen, certainly not to Radio"): a row can be missing from the glass without ever
    //    being swallowed by a neighbour.  If its seed sits outside the frame, the frame clip in
    //     `foam_cells` does NOT empty it — the cut is written to keep the SEED's side of every wall
    //      (so a frame handed either winding still works), so an outside seed keeps the OUTSIDE
    //       halfplane and the cell comes back whole, full size, drawn entirely beyond the viewBox.
    //  That is worse than a null and it reads identically: no wall on screen, no face, no label, and
    //   no reachable click target — the same trapdoor, minus the corner note that would have counted
    //    it.  Measured on a 26k-cell fuzz: 6.8% of cells when 15% of seeds are out of the rect, and
    //     12.6% in a NESTED scope, where the frame is the parent's own polygon and a child only has to
    //      drift past its parent's wall.  It is never partial — the clip keeps one side of a wall, so a
    //       cell is wholly in or wholly out (0 cells landed between 2% and 50% in-frame).
    //  ⚠ THIS IS THE PHENOMENON THE MODEL ALREADY NAMES: Vyto_normal §2 VISIBILITY, *"off-frame is a
    //   LAYOUT fault, never a fact about the data — 'things go missing somehow', nobody sent the Radio
    //    off the side, the solve did"*.  Its cure is to poke the solve and re-seed at the rim, which is
    //     right and stays — but it is a MODEL cure on a MODEL target, and it leaves the cell invisible
    //      in the meantime (and forever, if two pokes don't take).  This is the render-side belt to that
    //       braces: the seat is honest about where the row is *drawn* while the solve fixes where it
    //        *belongs*.  A seed is pulled to `want` inside each wall it broke — three passes so a corner
    //         (two walls at once) converges, then the frame's centroid as the last resort for a frame
    //          too small to inset into.
    //  Re-seats the DRAWN seed only — `seeds` holds copies made at the top of layout, never the springs,
    //   so the body keeps flying and simply slides along the rim instead of vanishing off it.
    //  BYTE-NEUTRAL WHERE NOTHING IS OFF-FRAME (the seat_floor discipline): a seed inside every wall is
    //   not touched at all, so a healthy scope's arithmetic is identical — 0 seeds moved across 25,830
    //    in-frame cells, same p05/median/p95 cell area to the unit.  RENDERER-SIDE ONLY, so it cannot
    //     move a recorded fixture.  The cells that WERE off-frame cost the rest about 2% of median area
    //      when they come back — the correct price, and the reason it is stated here rather than hidden.
    //  ASSUMES A CONVEX FRAME, which is exactly what the cut already assumes: the root frame is the
    //   viewport rect, and every nested frame is a parent's own cell — a polygonised disc trimmed by
    //    halfplanes, convex by construction.  A concave frame would make "inside every wall" stricter
    //     than "inside the polygon" and pull seeds further in than they need; it would not let one out.
    function frame_seat(seeds: Pt[], frame: Pt[], want: number): number {
        if (!frame || frame.length < 3 || !seeds.length) return 0
        type Wall = { ax: number, ay: number, nx: number, ny: number }
        // the frame's own winding decides which normal points OUT — the one thing the cut deliberately
        //  refuses to assume, and the reason it leans on the seed instead.  Here we must know.
        let sa = 0, cx = 0, cy = 0
        for (let i = 0; i < frame.length; i++) {
            const p = frame[i], q = frame[(i + 1) % frame.length]
            sa += p.x * q.y - q.x * p.y
            cx += p.x; cy += p.y
        }
        const ccw = sa > 0
        cx /= frame.length; cy /= frame.length
        const walls: Wall[] = frame.map((a, k) => {
            const b = frame[(k + 1) % frame.length]
            const ex = b.x - a.x, ey = b.y - a.y, el = Math.hypot(ex, ey) || 1
            return { ax: a.x, ay: a.y, nx: ccw ? ey / el : -ey / el, ny: ccw ? -ex / el : ex / el }
        })
        const depth = (x: number, y: number, e: Wall) => (x - e.ax) * e.nx + (y - e.ay) * e.ny
        let seated = 0
        for (const s of seeds) {
            let out = false
            for (const e of walls) if (depth(s.x, s.y, e) > 0) { out = true; break }
            if (!out) continue
            let x = s.x, y = s.y
            for (let pass = 0; pass < 3; pass++) {
                let shifted = false
                for (const e of walls) {
                    const dd = depth(x, y, e)
                    if (dd > -want) { const k = dd + want; x -= e.nx * k; y -= e.ny * k; shifted = true }
                }
                if (!shifted) break
            }
            for (const e of walls) if (depth(x, y, e) > 0) { x = cx; y = cy; break }
            s.x = x; s.y = y
            seated++
        }
        return seated
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
    //  The rotation lives here too now: a slab seat lies along its cell's parallelest walls, so the mold
    //   rotates about its own centre (CSS default origin) by cell.ang.  rotate is a Z-axis turn and
    //    translateZ a Z-axis move, so the two compose without interacting; the percentage box maps to
    //     viewBox space by ONE uniform scale (the element box always carries the viewBox's aspect —
    //      the .depth width-cap contract), so a CSS rotation lands exactly where the viewBox rotation
    //       would.  Degrees to 1dp: a calm glass re-emits a byte-identical string.
    // A POSED CELL IS NEVER "CRUSHED" (2026-08-10, the owner: *"Door once demoted to small cell again
    //  becomes just that damn ⤢ icon, which is now glitch zone I want banished"*).  The crush register
    //   means ONE thing — "this face is folded, there is more inside than I can show" — and it is the
    //    honest report of a cell that got less room than its content needed.  A `small` pose is the
    //     opposite statement: the commissioner ASSIGNED this size and the face has already been told
    //      to render as an icon, so there is nothing folded away and nothing to promise.  Wearing the
    //       fold mark there is a lie about the model AND, because the mark comes with an unmounted
    //        face, it replaced the icon the pose exists to show.
    function posed_cell(cell: PaintCell): boolean {
        return String(((cell.source as any)?.c?.pose ?? '')) === 'small'
    }
    function stretch_cell(cell: PaintCell): boolean {
        return String(((cell.source as any)?.c?.pose ?? '')) === 'stretched'
    }
    // `fill_rect` sweeps 15 aspects × 8 rays against every edge of a 56-vertex belly — fine once, not
    //  fine every frame of a resize, and `layout` runs on every adopt.  The belly is a PURE function
    //   of the frame, so its bbox (rounded to the whole unit) identifies the body exactly: same box,
    //    same answer, and the sweep runs only when the frame actually changed shape.  Cached on the
    //     mirror row's `.c` — one slot per cell, nothing to grow or evict.
    //  This is the "don't make the relayouts an annoyance" half: the OTHER half is that the face's
    //   layout width is a CONSTANT (`STRETCH_COL`), so no amount of resizing reflows its content —
    //    only the scale it is drawn at changes, which is a composite, not a layout.
    //  The body is keyed by its own bbox AND the plate's, because a swelled belly is cut by the plate
    //   — the same body in a different frame is a different room.
    //  THREE GUARDS AGAINST A FLITTING SEAT (2026-08-11 — *"Heist is flitting rapidly up and down"*).
    //   The belly breathes: the radio stirs the model continuously and express nudges the cell's
    //    radius, so this memo was being MISSED several times a second and re-solving an argmax that
    //     can teleport between near-equal peaks (see `fill_body`'s incumbency note).  In order of
    //      how much each one buys:
    //   1. INCUMBENCY (in `fill_body`): the standing centre re-competes with a handicap, so a
    //       challenger must be meaningfully better to take the seat.  This is the real fix; the other
    //        two are hygiene that stop us asking the question so often in the first place.
    //   2. A COARSE KEY.  Rounding the bbox to the whole unit means a one-pixel breath is a new room.
    //       `QUANT` units is the grid instead — a body that has genuinely changed shape still misses,
    //        a body that is merely alive does not.
    //   3. A QUANTISED ANSWER.  mx/my/mw/mh go straight into a style string, so an answer that moves
    //       by a third of a unit relayouts the face for nothing.  Whole units out, and if the fresh
    //        answer is within `STILL` of the standing one on every side, hand back the STANDING
    //         OBJECT — identical numbers, so Svelte never touches the attribute.
    // ── …AND THE SIZE WAS STILL BREATHING (2026-08-12, the owner: *"it's still doing it. the rapid
    //  jitterbugging of size or something, maybe a throttle() would help?"*) ──────────────────────
    //  Incumbency fixed WHERE the seat is; it never touched HOW BIG it is.  The incumbent re-competes
    //   from its own centre, but the rectangle it defends with is `fill_rect` solved afresh against a
    //    body that is moving — so `x,y` held and `w,h` tracked the breath, unit by unit, several times
    //     a second.  A mold that changes size is a face that re-scales and re-wraps: the same flitting,
    //      one axis over.
    //  The old still-band could not absorb it because it was ABSOLUTE — 2 units on a ~460-unit seat is
    //   half a percent, which a stirring belly clears without trying.  A dead band has to be in the
    //    units of the thing it is judging, so it is proportional now.
    //  ⚠ AND A DEAD BAND IS LEGITIMATE HERE, where damping was not legitimate for the centre.  The two
    //   look like the same medicine and are not: `fill_body`'s centre choice is an ARGMAX, discontinuous,
    //    so no amount of smoothing helps — the input barely moves and the output jumps across the belly.
    //     `fill_rect` about a FIXED centre is continuous in the body: a body that breathes by half a
    //      percent returns a rectangle that differs by half a percent.  Continuous inputs are exactly
    //       what a dead band is for.  Read the two notes together before touching either.
    //  THE COOLDOWN is the owner's `throttle()`, and it is the second half rather than the first: it
    //   bounds how OFTEN the seat may move, which is what turns a residue of jitter into something that
    //    reads as settling.  A big change (`SEAT_LEAP`) ignores it — a genuinely different room should
    //     be taken at once, and waiting out a cooldown to show it would be its own annoyance.
    const SEAT_QUANT = 6      // bbox grid for the memo key, in viewBox units
    const SEAT_STILL = 0.025  // a new seat within 2.5% of the standing one IS the standing one
    const SEAT_FLOOR = 2      // …but never a tighter band than this, so a tiny seat can still settle
    const SEAT_HOLD_MS = 900  // having just moved, hold — the owner's throttle
    const SEAT_LEAP = 0.25    // …unless the room changed by a quarter, which is a different room
    const MOLD_CYCLE_MS = 1200 // "the seat we just left" only counts as a 2-cycle if we left it JUST now
    // every side within the band, and the band is a fraction of the seat's own short side.
    function seat_still(a: { x: number, y: number, w: number, h: number },
                        b: { x: number, y: number, w: number, h: number }): boolean {
        const tol = Math.max(SEAT_FLOOR, Math.min(a.w, a.h) * SEAT_STILL)
        return Math.abs(a.x - b.x) <= tol && Math.abs(a.y - b.y) <= tol
            && Math.abs(a.w - b.w) <= tol && Math.abs(a.h - b.h) <= tol
    }
    function fill_body_memo(row: TheC, poly: Pt[], frame: { x: number, y: number, w: number, h: number },
                            bb: { bx: number, by: number, bw: number, bh: number },
                           ): { x: number, y: number, w: number, h: number } {
        const c = row.c as any
        const q = (v: number) => Math.round(v / SEAT_QUANT)
        const k = `${q(bb.bx)},${q(bb.by)},${q(bb.bw)},${q(bb.bh)},${poly.length}`
              + `|${q(frame.x)},${q(frame.y)},${q(frame.w)},${q(frame.h)}`
        if (c.fillrect_k === k && c.fillrect) return c.fillrect
        // …UNLESS THE FACE IS STILL ARRIVING.  Inside the settling window both guards stand down —
        //  no incumbency, no still-band — so the seat follows a Heist that is still filling up
        //   instead of defending the shape of an empty one.  See `regauge_pose`.
        const loose = settling(row)
        const held = c.fillrect as { x: number, y: number, w: number, h: number } | undefined
        const keep = !loose && held && held.w > 0 ? { x: held.x, y: held.y } : null
        const raw = fill_body(poly, frame, 3, keep)
        const r = { x: Math.round(raw.x), y: Math.round(raw.y), w: Math.round(raw.w), h: Math.round(raw.h) }
        c.fillrect_k = k
        if (!loose && held && held.w > 0) {
            if (seat_still(held, r)) return held
            // the throttle, and the exemption from it.  Area either way: a room that HALVED is as much
            //  a different room as one that doubled, and both should be taken while the reader is still
            //   looking at the change that caused them.
            const a0 = held.w * held.h, a1 = r.w * r.h
            const leapt = a1 > a0 * (1 + SEAT_LEAP) || a1 < a0 * (1 - SEAT_LEAP)
            if (!leapt && Date.now() - +(c.fillrect_at ?? 0) < SEAT_HOLD_MS) return held
        }
        c.fillrect = r
        c.fillrect_at = Date.now()
        return r
    }
    function mold_seat(cell: PaintCell): string {
        const rot = cell.ang ? ` rotate(${(cell.ang * 180 / Math.PI).toFixed(1)}deg)` : ''
        // THE OCCLUSION RANK — build_cells' one sort, expressed in Z.  No `perspective` is set
        //  anywhere on the stage, so a translateZ inside `.depth`'s preserve-3d changes STACKING
        //   ONLY (never size): 0.02px per rank keeps molds in the same big-under-small order as
        //    their SVG cells, and the 12px hover lift outranks every rank step by construction.
        const z = cell.lift ? ' translateZ(12px)' : ` translateZ(${((cell.zi ?? 0) * 0.02).toFixed(2)}px)`
        // ── THE LAYOUT WIDTH AND THE ZOOM MUST NOT BE THE SAME VARIABLE ────────────────────────────
        //  `.face-scroll` lays out at `100% / --fit` and scales back by `--fit`, which is exactly right
        //   for the magnifier: the box it lays out in and the box it lands in are the same box.  For a
        //    STRETCHED face it is a feedback loop, and the second half of the flitting the owner saw.
        //  Follow it round once.  `fit = min(W/col, H/h)`.  When the HEIGHT term binds, the laid-out
        //   column is no longer `col` — it is `W/fit = W·h/H`, wider.  Wrapped content holds its area,
        //    so at that wider column the content comes back SHORTER: h' ≈ A/(W·h/H) = A·H/(W·h).  That
        //     map is `h → k/h`, an involution: it does not converge on the balance point, it BOUNCES
        //      between two heights forever, one relayout each way, which on screen is a face pulsing
        //       up and down about its own centre several times a second.  Nothing downstream can damp
        //        it, because both states are self-consistent.
        //  `--lay` breaks the loop by assigning the layout width outright: the column is `col` whatever
        //   the zoom does, so the face is measured at the column the search actually chose and the
        //    search becomes a plain 1-D fixed point (which the solve + dead band already handle).
        //     `--fit` goes back to being a pure OUTPUT — a scale, never a layout.
        //  The price, and it is the honest one: when the two terms disagree the face is narrower than
        //   its rectangle instead of overflowing it.  That air is exactly what the capture's `slx`
        //    reports, and it is what the next search round closes.  At the balance point lay×fit = 1
        //     and the face fills the rectangle on both axes, which is where it comes to rest.
        const rc: any = cell.row.c
        const fr = rc?.stretch_rect
        const lay = stretch_cell(cell) && fr && fr.w > 0
            ? ` --lay:${Math.max(0.05, Math.min(4, (+(rc.stretch_col ?? STRETCH_COL0)) / fr.w)).toFixed(3)};`
            : ''
        return ` transform:${rot}${z};${lay}`
    }

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
    // (`show_organs` went with the organ panel — 2026-08-11, the chrome cull.)

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

    // THE IDENT — `Heist:10.Yara`, not `Heist:1` (the owner 2026-08-09: *"we had some way of saying the
    //  'Heist:10.Yara' or whatever it is (it should be more serial id?)"*).
    //  A mainkey's VALUE is often just the presence marker `1` (`{Transfer:1}`, `{Diag:1}`, `{Heist:1}` on
    //   a fresh keep), so `mk:value` said nothing about WHICH one you were looking at — and several of
    //    these are many-per-glass.  Three parts now, each dropped when it has nothing to say:
    //     · the MAINKEY — what the thing IS (CLAUDE.md: the mainkey is the type tag);
    //     · a SERIAL — a small stable number per identity, so two of the same kind are tellable apart at
    //        a glance and stay tellable across repaints (assigned first-seen, held on the tok);
    //     · a NAME — the mainkey's own value when it carries one (a %Heist wears its TITLE: `Heist.g`
    //        mints `{ Heist: entry.sc.title, seed, pub, state }`), else the shortest identifying scalar
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
        const tails: Pt[] = []      // tips placed this build — the bearing sweep steers around them
        const curWalls = new Map<string, Pt[]>()
        const sp = springs.get(w)
        if (!sp) return { cells, curWalls }
        const tn = walk ?? tree_nodes(w)
        const roots = tn.roots
        const liftKey = lifted.get(w)
        // THE POOL DEPTH (the owner: "pools of information...").  Nested stuffing rests SUNKEN —
        //  low ink at the bottom of its bag's pool — and SURFACES the moment anyone approaches:
        //   a hover anywhere along its chain (the bag, the cell itself, or deeper stuffing) or a
        //    camera engaged into the chain lifts the WHOLE chain back to full ink.  A paint
        //     register only: geometry, springs, targets and fixtures never move — a capture shows
        //      the same cells at quieter ink.  Keys are '>'-joined paths, so chain membership is
        //       a prefix test in both directions.
        const engKey = engaged.get(w)
        const near_key = (k: string | undefined, self: string) =>
            !!k && (k === self || k.startsWith(self + '>') || self.startsWith(k + '>'))
        // ── THE PROBES ARE OFF BY DEFAULT (2026-08-08) ──
        //  The GATE-FLIP probe and the OMISSION DETECTOR below both ran UNCONDITIONALLY, every build,
        //   i.e. up to 60×/s: the detector alone did a THIRD full `tree_nodes(w)` walk plus a filter,
        //    two Set constructions and two diff loops, and the gate probe allocates a 6-field object
        //     and does six comparisons per Heist cell per frame. They are diagnostics; they found the
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
        // THE SELF SEAT (the owner 2026-08-09: *"the Component needs a subcell to exist in next to the
        //  other subcells, though it should be graphically implying it's not separate to the cell
        //   itself"*).  Until now a scope SUPPRESSED its own face entirely — its children tiled its
        //    interior and the parent's component simply had nowhere to be, so nesting cost you the
        //     thing the cell was for.  Now the parent enters its OWN child tessellation as one more
        //      body: it competes for room on the same terms as its children (which is the only way
        //       the room is honestly divided) and takes a real polygon among them.
        //  What makes it read as "not separate" is the DRAWING, not the geometry — the self cell
        //   wears the parent's fill and no wall of its own, so it reads as the parent showing
        //    through its own stuffing rather than as a sibling of its children.
        const SELF_KEY = '»self'
        const layout = (nodes: Node[], framePoly: Pt[], gap: number, scopeKey: string, selfOf?: Node): void => {
            // the seat is its own regime: it never runs the fill economy, the seat floor, the repair
            //  loop or the vanish floor, because it cannot produce the faults those exist to repair.
            //  The FOCUS regime is stricter still — assigned outright, root scope only (a scope
            //   INSIDE the belly tiles with the standing machinery) — and it outranks the seat.
            const focusR = scopeKey === '' && focus_on(w)
            const seatR = !focusR && seat_on(w)
            const foam = !!(w.c as any).foam && !seatR && !focusR
            const live: Node[] = []
            const seeds: Pt[] = []
            const radii: number[] = []
            const keys: string[] = []
            for (const n of nodes) {
                const s = sp.get(n.key)
                if (!s || (n.row.sc as any).departing) continue
                // a LOOSE row (foam law) takes no seat in the cut — it exerts no wall pressure and
                //  receives none.  It still gets a PaintCell below (the disc branch), on its own layer.
                if (foam && (n.row.sc as any).loose) continue
                live.push(n); keys.push(n.key); seeds.push({ x: s.x, y: s.y }); radii.push(s.r)
            }
            // the parent joins its children's cut as one more body.  Its seed is its OWN solved
            //  position — it is already inside its own polygon by construction, so no placement is
            //   invented — and its weight is the mean child radius, i.e. "an equal share among your
            //    stuffing".  A bigger claim would starve the children the nesting exists to show; a
            //     smaller one would crush the component the seat exists to hold.
            let selfSeed: Pt | null = null
            const selfFace = selfOf ? (bare_on(w) ? null : face_of(selfOf.row)) : null
            if (selfOf && selfFace && live.length) {
                const ps = sp.get(selfOf.key)
                if (ps) {
                    const mean = radii.reduce((a, r) => a + r, 0) / radii.length
                    selfSeed = { x: ps.x, y: ps.y }
                    live.push(selfOf); keys.push(selfOf.key + SELF_KEY)
                    seeds.push(selfSeed); radii.push(mean)
                }
            }
            // THE FRAME SEAT — applied before anything reads a seed, because the stage's room
            //  measurement below cuts a real cell at `seeds[sI]` and would otherwise be measuring the
            //   room left by a body that isn't on screen.  Law and evidence above `frame_seat`.
            //  Counted on `.c` (never encoded) so `--why` can show the glass catching its own rows.
            //  A seated glass has no seed to strand — boxes are constructed inside the frame — so it
            //   skips this too rather than counting phantom rescues.
            const seated = (seatR || focusR) ? 0 : frame_seat(seeds, framePoly, SEAT_MIN)
            if (seated) (w.c as any).frame_seats = (((w.c as any).frame_seats as number) || 0) + seated
            // THE FOAM REGIME (gated on w.c.foam — the ORCHESTRA OF SPHERES law, Vyto_todo):
            //  coverage is earned by pressure.  The solve's radii are RELATIVE weights tuned for
            //   frame-carving, so as literal discs they'd cover ~5% of the frame and never touch;
            //    rescale them so their disc areas sum to FOAM_FILL of this scope's frame — enough
            //     press for the pile's interior to wall into mosaic while the rim stays round and
            //      the uncrowded margins stay EMPTY (emptiness finally means uncrowded).  A nested
            //       scope packs tighter (its stuffing fills its membrane).  Gate off ⇒ the exact
            //        standing cut, byte for byte.
            // THE STAGED BODY IS OUTSIDE THE FILL ECONOMY (the owner 2026-08-09: *"when the Heist is
            //  focused|happening|staged, the other cells are a bit squished up in a wad, I can only see
            //   Door and it's 4x too small to play with"*).  The model already learned this — Vyto.g's
            //    bag-pressure gate leaves the staged body "out of the pressure TOTAL as well, so its
            //     size does not squeeze the small cells it is supposed to be sitting beside" — but THIS
            //      normalisation never got the same exemption, and it is the one that actually grants
            //       room: it grows every scope's discs until they sum to FOAM_FILL of the frame, which
            //        is what normally lets four cells share the whole room generously.  A staged monster
            //         (0.62·min(fw,fh) ⇒ its disc alone ≈ 85% of an 800×450 budget) included in that sum
            //          IS the budget, so the others stayed at their raw solved radii — down ~4× in area
            //           from their unstaged selves.  The wad.
            //  So: the monster keeps its screen-stated radius untouched (it is a claim about the SCREEN,
            //   stage_lay's law), and everyone else is normalised to fill FOAM_FILL of the room the
            //    monster actually leaves IN-FRAME — measured with the same foam_cells primitive that
            //     will cut it, so "the room it leaves" and "the room it takes" cannot disagree.
            //  Floored at 0.15·A so a monster that swallows the whole frame still leaves the others a
            //   sliver-economy rather than zero.  No stage ⇒ sI −1 ⇒ the exact standing arithmetic,
            //    byte for byte — and no Book ever stages, so every fixture stands.
            //  The effective stage is EITHER the human's drag (w.c.stage_tok) OR the model's standing
            //   want (`source_n.c.stage_want`, how a heist asks — Vyto_stage_tok resolves it at solve
            //    time and never writes it back, so reading stage_tok alone misses the heist case).
            let cutRadii = radii
            if (foam && radii.length) {
                const A = Math.abs(poly_area(framePoly))
                const fill = scopeKey === '' ? FOAM_FILL : FOAM_FILL_NESTED
                const stok = (w.c as any).stage_tok ?? null
                let sI = -1
                // two passes, drag first — the SAME precedence Vyto_stage_tok resolves with, so the
                //  body this exempts is always the body stage_lay actually placed.  One flat loop
                //   would exempt whichever row it met first when a drag overrides a standing want.
                if (stok != null) for (let i = 0; i < live.length; i++) if (live[i].tok === stok) { sI = i; break }
                if (sI < 0) for (let i = 0; i < live.length; i++) if ((live[i].row.c as any)?.source_n?.c?.stage_want) { sI = i; break }
                const discs = radii.reduce((a, r, i) => i === sI ? a : a + Math.PI * r * r, 0)
                if (discs > 0 && A > 0) {
                    let room = A
                    if (sI >= 0) {
                        const mp = foam_cells([seeds[sI]], [radii[sI]], 0, framePoly)[0]
                        room = Math.max(A * 0.15, A - (mp ? Math.abs(poly_area(mp)) : Math.PI * radii[sI] * radii[sI]))
                    }
                    const k = Math.sqrt((room * fill) / discs)
                    cutRadii = radii.map((r, i) => i === sI ? r : r * k)
                }
            }
            // THE SEAT FLOOR — every live row is owed a cell, so the radii the cut actually receives are
            //  the asked-for ones with every swallow forbidden.  The law, the geometry and the owner's
            //   ruling behind it are stated once above `seat_floor`; this is only where it is applied.
            //  `askRadii` is kept because the REPAIR PASS below re-derives from the ASK, never from an
            //   already-floored array — escalating on top of a previous escalation compounds.
            const askRadii = cutRadii
            if (foam && askRadii.length) cutRadii = seat_floor(seeds, askRadii, gap, null, 1)
            // the memo consult: unchanged inputs reuse the standing polys (same references — the drift
            //  judge shortcuts them to zero); changed inputs cut fresh and count one REAL cut.
            //  Keyed on the PRE-repair sig, which is correct rather than a shortcut: the repair is a
            //   deterministic function of the same inputs, so a sig hit implies the same repair.
            seenScopes.add(scopeKey)
            const sig = (foam ? 'F' : '') + cut_sig(framePoly, keys, seeds, cutRadii, gap)
            const had = wm.get(scopeKey)
            let polys: (Pt[] | null)[]
            if (focusR) {
                // assigned outright — a pure function of (frame, keys, roles), so nothing here can
                //  move once arrived, and no key can come back null.  No memo needed: it is cheaper
                //   than the sig it would be memoed under.
                polys = focus_cells(live, keys, radii, framePoly, gap)
            } else if (seatR) {
                // no wall memo here: the deal IS the memo, and it is keyed on membership rather than
                //  on a signature of every coordinate, so ordinary dose work never re-cuts it.
                polys = seat_polys(w, scopeKey, keys, radii, framePoly, gap)
            } else if (had && had.sig === sig) {
                polys = had.polys
            } else {
                polys = foam ? foam_cells(seeds, cutRadii, gap, framePoly)
                             : power_cells(framePoly, seeds, cutRadii, gap)
                ;(w.c as any).wall_cuts = (((w.c as any).wall_cuts as number) || 0) + 1
                // THE REPAIR PASS — the accumulation case the pairwise floor cannot see: a row killed by
                //  several neighbours that each, on their own, left it a legal seat.  Ask again, harder,
                //   for exactly the rows that actually died, and re-cut.  Measured on a 19,458-cell fuzz
                //    against this same `foam_cells`: the floor alone takes 3159 swallowed rows to 48, and
                //     this takes those 48 to ZERO, for about one extra cut in 1.6% of scopes.  It lives
                //      inside the memo MISS, so a settled glass never pays for it at all.
                //  Bounded at SIX tries so a pathological scope cannot spin.  Three was enough for the
                //   full-frame fuzz above but not for a NESTED scope, where the frame is a small parent
                //    polygon and the escalation has less room to work with: 6 rows in 17,523 still died
                //     at three tries and none at six.  The bound costs nothing where it isn't needed —
                //      the loop breaks the moment there are no victims, which is every healthy scope.
                if (foam) {
                    for (let tryn = 1; tryn <= 6; tryn++) {
                        const victims = new Set<number>()
                        for (let i = 0; i < polys.length; i++) if (!polys[i]) victims.add(i)
                        if (!victims.size) break
                        cutRadii = seat_floor(seeds, askRadii, gap, victims, 1 + tryn * 1.6)
                        polys = foam_cells(seeds, cutRadii, gap, framePoly)
                        ;(w.c as any).wall_cuts = (((w.c as any).wall_cuts as number) || 0) + 1
                    }
                }
                // ── THE VANISH FLOOR — a cell too small to say anything is worse than no cell ──────────
                //  (2026-08-10, the owner: *"it's often glitch-zone-tiny-bitsing cells with no clear way
                //   to bring them back out of nowhere. perhaps if they're too small we simply vanish
                //    them?"*)  The seat floor above answers "every live row is OWED a cell" and it now
                //     delivers one in very nearly every case — but a cell is not a seat.  Under about a
                //      word's worth of wall, what arrives is a shard that carries no face (fit is long
                //       gone), no carve, no hall and no A dial: it has already lost every part except the
                //        wall itself, one threshold at a time, and the LAST thing it lost was its handle —
                //         so the control that would grow it back is gated on it being big enough not to
                //          need growing.  That is the trap the owner is naming, and it is the same shape
                //           as the null-poly trapdoor: the one you want to recover is the one you cannot
                //            press.
                //  So below VANISH_ROOM the cell is not drawn at all.  This is NOT hiding, and the
                //   distinction is the whole design:
                //    · the row still exists, and takes the EXACT exit an unseated row takes — a null poly,
                //       fit 0, and its own chip in the corner note, whose press already pays attention
                //        currency to seat it.  A way back in, not a tally, and no new UI to build.
                //    · its room is GIVEN BACK.  One re-cut without the doomed seeds, so the neighbours
                //       close over the shard instead of leaving a hole where it was.  Removing a body can
                //        only remove clips, so every survivor grows or stays — the pass is monotone and
                //         cannot cascade, which is why one iteration is the whole of it.
                //  380px² ≈ a 20×19 box: under one legible character at the 14px ident floor.  It is the
                //   conservative landing on purpose — it removes only what was already unreadable — and it
                //    is one constant to raise once we have looked at a glass with the count in it.
                //  Inside the memo MISS, like the repair: a settled glass never re-runs it.
                //  ⚠ AND IT MUST NOT EAT THE ENTRANCE.  `adopt` springs a newcomer in with **`r: 0` —
                //   "the radius ramp IS the entrance"** — so EVERY cell is born under this floor and
                //    passes up through it.  Vanishing during that ramp deletes a cell for its own
                //     arrival: measured on the live glass as a transient `1 with no room` that settled
                //      back to 0, i.e. a flicker at every world change.  The floor is a judgement about
                //       what the CUT left a cell, not about a cell that has not finished growing, so a
                //        row inside its ARRIVE window is exempt.  A key absent from `seen` is brand new
                //         (the emit loop stamps it below, after this), which is the most arriving a row
                //          can be — hence `born == null` counts as arriving rather than as ancient.
                if (foam) {
                    const doomed = new Set<number>()
                    for (let i = 0; i < polys.length; i++) {
                        const p = polys[i]
                        if (!p || Math.abs(poly_area(p)) >= VANISH_ROOM) continue
                        const born = seen?.get(keys[i])
                        if (seen && (born == null || now_fx - born < ARRIVE_MS)) continue
                        doomed.add(i)
                    }
                    if (doomed.size && doomed.size < polys.length) {
                        const keep: number[] = []
                        for (let i = 0; i < polys.length; i++) if (!doomed.has(i)) keep.push(i)
                        const again = foam_cells(keep.map(i => seeds[i]), keep.map(i => cutRadii[i]), gap, framePoly)
                        ;(w.c as any).wall_cuts = (((w.c as any).wall_cuts as number) || 0) + 1
                        // a survivor that comes back null keeps the wall it already had — the re-cut is
                        //  an improvement pass, never a way to lose a cell that had one.
                        const out: (Pt[] | null)[] = polys.map((p, i) => doomed.has(i) ? null : p)
                        for (let k = 0; k < keep.length; k++) if (again[k]) out[keep[k]] = again[k]
                        polys = out
                        ;(w.c as any).vanished = (((w.c as any).vanished as number) || 0) + doomed.size
                    }
                }
                wm.set(scopeKey, { sig, polys })
            }
            const polyByKey = new Map<string, Pt[] | null>()
            // keyed off `keys`, NOT `live[i].key` — the self seat's Node IS the parent, so its own
            //  key would overwrite the parent's entry and the scope would inherit its child's wall.
            //   `keys` carries the synthetic »self suffix and is the only correct index here.
            for (let i = 0; i < live.length; i++) {
                polyByKey.set(keys[i], polys[i])
                if (polys[i]) curWalls.set(keys[i], polys[i] as Pt[])
            }
            // emit order: lifted sibling last (its subtree follows, so it all paints on top).
            const order = [...nodes].sort((a, b) => (a.key === liftKey ? 1 : 0) - (b.key === liftKey ? 1 : 0))
            for (const n of order) {
                const s = sp.get(n.key)
                if (!s) continue
                const row = n.row
                // JUST THE MAINKEY, UNDER FOCUS ONLY (the owner 2026-08-10: *"just say the mainkey in
                //  the label"*).  `ident_of`'s three-part identity — mainkey : serial . name — answers
                //   "WHICH of these several am I looking at", and that is a FOAM question: a glass of
                //    twelve cells can hold four %Heists and they have to be tellable apart at a glance.
                //     Under focus there is one subject and a bud or two, all of different kinds, so the
                //      serial and the name answer a question nobody is asking — and the name is where
                //       `playing` and `of:48` were coming from.
                //  Scoped to THE REGIME, not to `ident_of`: every other glass keeps the identity it was
                //   designed with (§0.0), and this stays a parameterisation rather than a deletion.
                const ident = focusR ? (Object.keys((row.sc as any) ?? {})[0] ?? '?') : ident_of(row, w, n.tok)
                const lift = liftKey === n.key
                // heat holds a body SURFACED after the pointer moves on — the attention trail
                //  stays lit and sinks only as the currency taxes away (heat 0 in every Book,
                //   so driven worlds read exactly as before).
                const sunk = n.depth > 0 && !near_key(liftKey, n.key) && !near_key(engKey, n.key)
                          && !(((row.c as any).heat ?? 0) > 0.25)
                // BARE: the face is dropped at the source, so nothing downstream — mold, measure, seat,
                //  need floor, icon register — has anything to do.  One gate, not six opt-outs.
                const f = bare_on(w) ? null : face_of(row)
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
                regauge_pose(row, w)
                const nw = (row.c as any).need_w as number | undefined
                const nh = (row.c as any).need_h as number | undefined
                // THE BUD AND THE BELLY WANT OPPOSITE CEILINGS.  `FIT_MAX` exists to stop a trivial
                //  widget being magnified until it dominates a foam cell — but under focus DOMINATING
                //   THE CELL IS THE ENTIRE POINT: the belly is *"a big blob to present stuff in"*, and
                //    pinned at 1.6 the Radio's 170×169 face drew a 272×271 mold inside an 800px body,
                //     i.e. *"sitting in the middle, nowhere near big enough"*.  So the belly's ceiling
                //      is the room the ray seat actually measured, not a foam-era constant; the bud
                //       keeps the opposite rule (never magnified — see the small-pose clamp below).
                const poseNow = String((((row.c as any).source_n) as any)?.c?.pose ?? '')
                const smallPose = poseNow === 'small'
                const stretchPose = poseNow === 'stretched'
                const fitMax = (focusR && !smallPose) ? BELLY_FIT_MAX : FIT_MAX
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
                if (PROBE && String(ident).indexOf('Heist:') === 0) {
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
                                 bx: s.x - r, by: s.y - r, bw: 2 * r, bh: 2 * r,
                                 mx: s.x - r, my: s.y - r, mw: 2 * r, mh: 2 * r, ang: 0,
                                 clip: clipPoly, face, source, row, fx, fxi, fit })
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
                    // THE GENTLE SEAT (the owner 2026-08-09, second ruling: *"forget sidewaysing, I just
                    //  meant the box-within-box reality of Component in cell aligned for space efficiency,
                    //   without tilting anything more than say 30degrees, or zooming more than so much"*).
                    //  slab_seat still finds the parallelest walls, but the seat is only TAKEN when its
                    //   angle is ≤ MAX_TILT — a gently-slanted cell gets a gently-slanted component; a
                    //    steep slab falls back to the axis-aligned AABB + wall clip.  Within a taken seat
                    //     the component lies along the slab, fills it across (SEAT_AIR), may overrun the
                    //      ends a little (OVERHANG — hover top-mostity resolves the overlap), and its
                    //       scale is bounded BOTH ways (0.2 .. FIT_MAX): envelope-down survives for the
                    //        icon floor, blow-up stops before a trivial widget dominates its cell.
                    //  Angle discipline: normalised so text never reads upside down; snapped level
                    //   within 8° — a 3° tilt reads as a bug where a 20° tilt reads as a seat.
                    let mx = bb.bx, my = bb.by, mw = bb.bw, mh = bb.bh, ang = 0
                    // A BLOB NEEDS THE INSCRIBED SEAT TOO (2026-08-10, `focusR` added).  This branch
                    //  ray-casts the mold INSIDE the polygon; the `else` below falls back to a slab
                    //   or the AABB, which for a round body means a rect inscribed in its BOUNDING
                    //    BOX — reaching into corners the body does not occupy.  Measured on the live
                    //     glass: the belly's component box ran into the top-right corner where a bud
                    //      sits, reporting an overlap between two cells whose walls never touch.
                    //  The focus belly is exactly as round as a foam ball, so it wants exactly this
                    //   seat; the `s.r > 8` gate is dropped for it because a focus cell's radius is
                    //    the spring's, which the assigned layout does not use.
                    if (!hasKids0 && face && (foam || focusR) && (focusR || s.r > 8) && nw && nh) {
                        // THE FOAM SEAT (2026-08-09, the owner: "things aren't positioned in the
                        //  cells properly").  A foam cell is a BALL, and the ball answers the seat
                        //   question exactly: the largest rectangle of the face's aspect inscribed
                        //    in the circle (diagonal = 2(r-3), a hair inside the wall), centred on
                        //     the ball BY CONSTRUCTION.  No slab hunt, no clip — inscribed means
                        //      the wall is never crossed, and what still overhangs on hover is the
                        //       spill the owner asked to keep.
                        const diag = 2 * Math.max(4, s.r - 3)
                        const hyp = Math.hypot(nw, nh)
                        // ── THE SEAT BY RAYS (2026-08-09, the owner: *"I'd like you to try to get
                        //  Component to fit into the cell better"*).  Three answers have been tried and
                        //   each measured the WRONG SHAPE: the ball ignores the cut, the bbox is a box
                        //    around a polygon (so it promises room the wall does not have), and the two
                        //     together are just the smaller of two wrong numbers.  The right question is
                        //      "how big can a rectangle OF THIS FACE'S ASPECT be, centred on the seed,
                        //       before it touches the wall" — and `ray_hit` already answers it exactly.
                        //  Cast to the eight points of the face's own outline (four corners, four edge
                        //   midpoints); each says how far the wall is in that direction; the binding one
                        //    is the seat.  Strictly ≥ the ball answer on a free cell and strictly better
                        //     on a pressed one, because it measures the room in the direction the
                        //      component actually needs it. -->
                        let byray = Infinity
                        for (const [qx, qy] of [[1, 1], [1, -1], [-1, 1], [-1, -1], [1, 0], [-1, 0], [0, 1], [0, -1]]) {
                            const ex = (nw / 2) * qx, ey = (nh / 2) * qy
                            const L = Math.hypot(ex, ey); if (!(L > 0)) continue
                            const t = ray_hit(poly, s.x, s.y, ex / L, ey / L)
                            if (t > 0) byray = Math.min(byray, Math.max(0, t - 2) / L)
                        }
                        // THE CUT IS THE WALL, NOT THE BALL (2026-08-09, the owner: *"there's a cell
                        //  (friends|local-music) that's been squished way too far down but its component
                        //   overlay thing is there still"*).  A seat inscribed in the BALL is only the
                        //    seat when nothing presses: the power cut takes the ball away wherever a
                        //     neighbour leans in, so a cell squeezed from both sides keeps radius `r`
                        //      while its polygon collapses to a sliver — and a ball-sized mold then sits
                        //       there at full size over a wall that is no longer under it.  That is the
                        //        reported bug exactly.  So the ball proposes and THE CUT DISPOSES: bound
                        //         the same inscribed seat by the polygon's own extent as well, which is a
                        //          no-op on a free ball (bbox ≈ 2r) and the whole answer on a pressed one.
                        //  It also re-arms the icon register — a genuinely crushed cell now reports a
                        //   crushed `fit`, drops below the 0.34 floor, and becomes an icon instead of
                        //    wearing a widget it has no room for.
                        // ── AND THE CENTRE DISPOSES TOO (the owner 2026-08-09: *"the Component fitting
                        //  wants to be a bit larger... its 0.7 but wants 0.92"*).  The rays above are
                        //   cast from the SEED, and a power cell's seed is not its middle — a body
                        //    leaned on from one side keeps its seed where it was while its polygon
                        //     grows away from it.  Every ray then answers about the SHORT side, and the
                        //      component is sized by the cell's worst direction from an arbitrary
                        //       point.  That is the missing third, not a bound that is set too low:
                        //        the cut already disposed of the ball's SIZE, it has to dispose of its
                        //         CENTRE as well.
                        //  So measure again from the polygon's centroid and keep whichever centre wins.
                        //   Two candidates, not a search — a real max-inscribed solve is not worth a
                        //    per-frame cost here, and the centroid is where the room actually is.
                        let cx2 = 0, cy2 = 0
                        for (const p of poly) { cx2 += p.x; cy2 += p.y }
                        cx2 /= poly.length; cy2 /= poly.length
                        let byray2 = Infinity
                        for (const [qx, qy] of [[1,1],[1,-1],[-1,1],[-1,-1],[1,0],[-1,0],[0,1],[0,-1]]) {
                            const ex = (nw / 2) * qx, ey = (nh / 2) * qy
                            const L = Math.hypot(ex, ey); if (!(L > 0)) continue
                            const t = ray_hit(poly, cx2, cy2, ex / L, ey / L)
                            if (t > 0) byray2 = Math.min(byray2, Math.max(0, t - 2) / L)
                        }
                        let seatx = s.x, seaty = s.y
                        if (Number.isFinite(byray2) && !(byray2 <= byray)) { byray = byray2; seatx = cx2; seaty = cy2 }
                        // …and under focus the CENTROID IS THE ONLY HONEST CENTRE.  The rays above are
                        //  cast from the spring as well, and a focus body is not where its spring is
                        //   (the springs keep relaxing toward foam targets nothing draws), so that
                        //    candidate measures a different shape in a different place.  Take the
                        //     centroid's answer outright rather than letting a meaningless one win it.
                        if (focusR && Number.isFinite(byray2)) { byray = byray2; seatx = cx2; seaty = cy2 }
                        fit = Number.isFinite(byray) ? byray : Math.min(diag / hyp, bb.bw / nw, bb.bh / nh)
                        fit = Math.max(0.2, Math.min(fitMax, +fit.toFixed(3)))
                        mw = nw * fit; mh = nh * fit
                        mx = seatx - mw / 2; my = seaty - mh / 2
                        // the seed of a lobed cell can sit well off its own bbox centre; keep the seat
                        //  inside the cut it was just measured against.
                        if (mw <= bb.bw) mx = Math.max(bb.bx, Math.min(bb.bx + bb.bw - mw, mx))
                        if (mh <= bb.bh) my = Math.max(bb.by, Math.min(bb.by + bb.bh - mh, my))
                    } else if (!hasKids0 && face) {
                        let seat = nw && nh ? slab_seat(poly) : null
                        let th = 0
                        if (seat) {
                            let sux = seat.ux, suy = seat.uy
                            if (sux < 0) { sux = -sux; suy = -suy }          // (-90°, 90°]
                            th = Math.atan2(suy, sux)
                            if (Math.abs(th) < 0.14) th = 0                  // snap level
                            if (Math.abs(th) > MAX_TILT) seat = null         // too steep — not our seat
                        }
                        if (seat && nw && nh) {
                            fit = Math.min((seat.t - SEAT_AIR) / nh, (seat.len * OVERHANG) / nw)
                            fit = Math.max(0.2, Math.min(fitMax, +fit.toFixed(3)))
                            mw = nw * fit; mh = nh * fit
                            mx = seat.cx - mw / 2; my = seat.cy - mh / 2
                            ang = +th.toFixed(3)
                        } else {
                            clipPoly = clip_of(poly, bb)
                            // one uniform scale to fill the AABB seat — stretches UP into a roomy cell
                            //  and envelopes DOWN into a crushed one, same rule.
                            if (nw && nh && bb.bw > 0 && bb.bh > 0) {
                                fit = Math.min(bb.bw / nw, bb.bh / nh)
                                fit = Math.max(0.2, Math.min(fitMax, +fit.toFixed(3)))
                            }
                        }
                    }
                    // the tail is SPLICED into the outline (that is what makes it a soft blob rather
                    //  than a hard triangle — path_round owns the points).  The seat and bbox stay
                    //   measured on the ORIGINAL wall: the tail is a mark on the body, not room in it.
                    // THE BEARING SWEEP.  205° is the left end of the wall band, so the wanted tail
                    //  bearing is the approach to it; each further candidate steps away in alternating
                    //   directions.  Greedy in emit order against the tips already placed this build —
                    //    no neighbour lookup, no second pass, and deterministic, so a settled glass
                    //     re-emits the identical placement and a Book cannot flake on it.
                    let sp: ReturnType<typeof spike_of> = null
                    if (!hasKids0 && foam && !fo(w, 'wave') && !fo(w, 'seal')) {
                        // the sweep is RELATIVE to the visible flank, for the same reason the label
                        //  band is (see furn_dir): a cell pushed off an edge was growing its tail into
                        //   the part of itself nobody can see.  Fits ⇒ 198° ⇒ the original list exactly.
                        const tdir = furn_dir(w, s.x, s.y, s.r, 198)
                        for (const off of [0, 16, -16, 34, -34, 52, -52]) {
                            const want = ((tdir + off) % 360 + 360) % 360
                            const cand = spike_of(poly, s.x, s.y, s.r, want)
                            if (!cand) continue
                            sp = cand
                            const clash = tails.some(t => Math.hypot(t.x - cand.apex.x, t.y - cand.apex.y) < 26)
                            if (!clash) break
                        }
                        if (sp) tails.push(sp.apex)
                    }
                    // FOCUS CELLS ANCHOR ON THEIR OWN BODY, not the spring.  The polys are assigned
                    //  and still; the springs keep relaxing underneath — an anchor read off s.x/s.y
                    //   would slide a label across a cell that is not moving.
                    let ax = s.x, ay = s.y
                    if (focusR) {
                        ax = 0; ay = 0
                        for (const p of poly) { ax += p.x; ay += p.y }
                        ax /= poly.length; ay /= poly.length
                    }
                    // A SMALL POSE IS NEVER MAGNIFIED.  `FIT_MAX` lets a face be blown UP to fill a
                    //  roomy cell, which is right for a subject and wrong for a bud: a cell whose
                    //   whole content is a name and an icon, scaled 1.34×, grows a mold BIGGER than
                    //    the thing it holds — and on the live glass that box reached back under the
                    //     belly and put the two components over each other again (`overlapping
                    //      pairs: 1`), which is the defect the bud placement had just removed.
                    //  So a `small` cell renders at its natural size or smaller, never larger, and
                    //   the mold is re-seated on the same anchor so it stays centred in its bud.
                    //  …AND NEVER SHRUNK TO NOTHING EITHER (the owner 2026-08-10: *"never make the
                    //   Component too small!"*).  A bud's face is already an icon — it has no fat to
                    //    give — so the envelope-down that saves a crowded foam cell is exactly wrong
                    //     here: shrinking it only makes an unreadable glyph.  A small pose therefore
                    //      draws between 0.8× and 1× and nothing else, and if that still overhangs
                    //       its bud a little, an icon overhanging by a few px is the right trade for
                    //        an icon you can see.
                    if (smallPose && fit !== 1) {
                        const cxm = mx + mw / 2, cym = my + mh / 2
                        const f2 = Math.max(0.8, Math.min(1, fit))
                        mw = (mw / fit) * f2; mh = (mh / fit) * f2
                        mx = cxm - mw / 2; my = cym - mh / 2
                        fit = f2
                    }
                    // ── A MOLD MUST SIT IN ITS OWN CELL (2026-08-10) ───────────────────────────────
                    //  Every mold seat above is measured from the SPRING position (or a centroid the
                    //   spring is compared against).  Under focus the springs are still relaxing
                    //    toward foam targets that nothing draws, so the seat has no relationship to
                    //     the assigned polygon — measured live, a bud's component box landed ~60px
                    //      LEFT of its own cell, back under the belly, reporting `overlapping pairs:
                    //       1` from two cells whose walls do not touch.
                    //  So: re-seat on the polygon's own centroid and clamp into its bbox.  This is
                    //   the same law the label anchor above follows, and it cannot regress the other
                    //    regimes because it is gated on `focusR`.
                    if (focusR) {
                        mx = ax - mw / 2; my = ay - mh / 2
                        if (mw <= bb.bw) mx = Math.max(bb.bx, Math.min(bb.bx + bb.bw - mw, mx))
                        if (mh <= bb.bh) my = Math.max(bb.by, Math.min(bb.by + bb.bh - mh, my))
                    }
                    // ── THE STRETCH (the owner 2026-08-10: *"for the Heist we want it totally maxed
                    //  out up in there like the STAGED AREA did it before."*) ───────────────────────
                    //  Every seat above starts from the face's NATURAL BOX and asks how big that
                    //   aspect can be.  A heist has no natural size worth honouring — it is a list —
                    //    so asking its content how much room to take leaves the belly full of nothing.
                    //  A `stretched` cell asks the other question instead: how big a rectangle is in
                    //   this body AT ALL (`fill_rect` sweeps the aspects; pure, gated in VytoFocus).
                    //    The answer IS the box, `fit` is exactly 1 — the face is LAID OUT at that size
                    //     rather than drawn small and magnified — and the CSS below makes its root fill
                    //      it.  The regime's law one step on: not just the size assigned, the aspect too.
                    //  This runs after everything above ON PURPOSE: whatever the natural-box seat
                    //   concluded is simply not the question being answered here.
                    //  …AND THE BODY IS NOW BIGGER THAN THE ROOM (2026-08-11).  A swelled belly runs off
                    //   three edges of the plate, so the question changes shape: the rectangle must be
                    //    inscribed in the VISIBLE body — the wall where there is one, the viewport edge
                    //     where the wall has left — and centred where that cut region actually has room,
                    //      not on the polygon's centroid, which a cut can throw anywhere.  `fill_body`
                    //       answers both (clip + centre sweep) and hands back the centre it chose.
                    if (focusR && stretchPose) {
                        const fbb = bbox_of(framePoly)
                        const fr = fill_body_memo(row, poly, { x: fbb.bx, y: fbb.by, w: fbb.bw, h: fbb.bh }, bb)
                        if (fr.w > 8 && fr.h > 8) {
                            // …AND 130% OF IT (the owner, looking at the working stretch: *"Heist wants
                            //  font-size:130% — the rest of it"*).  NOT a font rule: the faces hardcode
                            //   9/10/11px in their own stylesheets, so nothing set here would reach
                            //    them (that is why `--fit` is a transform in the first place).  The
                            //     magnifier already does exactly this — lay out in a box divided by
                            //      `fit`, scale back by `fit` — so the whole face comes up, "the rest
                            //       of it" included, and still fills the rectangle to the pixel.
                            //  QUANTISED to 2dp so a frame that jitters by a pixel does not re-emit
                            //   `--fit` and relayout the face underneath the reader — the owner:
                            //    *"there's relayouts I'm implying you could not make an annoyance of"*.
                            mw = fr.w; mh = fr.h; ang = 0
                            // the column the search has arrived at, and the zoom it buys.  Height binds
                            //  too once the face has been measured at this column — until then only
                            //   width is known, which is the first round of the search.
                            const col = +((row.c as any).stretch_col ?? STRETCH_COL0)
                            const sh = +((row.c as any).stretch_h ?? 0)
                            let z = fr.w / col
                            if (sh > 0) z = Math.min(z, fr.h / sh)
                            fit = +Math.max(STRETCH_ZOOM_MIN, Math.min(BELLY_FIT_MAX, z)).toFixed(2)
                            mx = fr.x - mw / 2; my = fr.y - mh / 2
                            // `stretch_rect` is NOT written here — see below.  It must be the mold this
                            //  face is actually laid out in, and the dead band may still overrule `fr`.
                        }
                    }
                    // ── FURNITURE READS THE VISIBLE BODY ───────────────────────────────────────────
                    //  `bb` is the cell's TRUE extent and every seat above wants it that way, but the
                    //   wave band, the ident and the camera fit are all struck off bx/by — and a
                    //    swelled belly's true bbox starts a couple of hundred units off the plate, so
                    //     those would hang the name where the viewport has already cut it away.  The
                    //      record therefore carries the INTERSECTION with the plate: the part of this
                    //       cell a reader can actually see, which is the only part furniture belongs on.
                    let vx = bb.bx, vy = bb.by, vw = bb.bw, vh = bb.bh
                    if (focusR) {
                        const f = bbox_of(framePoly)
                        const x0 = Math.max(vx, f.bx), y0 = Math.max(vy, f.by)
                        const x1 = Math.min(vx + vw, f.bx + f.bw), y1 = Math.min(vy + vh, f.by + f.bh)
                        if (x1 > x0 && y1 > y0) { vx = x0; vy = y0; vw = x1 - x0; vh = y1 - y0 }
                    }
                    // ── THE SAME DEAD BAND, ON THE SEAT THAT IS NOT THE STRETCH ONE ────────────────
                    //  `fill_body_memo` holds the STRETCHED seat still, and only that one.  The belly's
                    //   ordinary seat is struck fresh every adopt from the polygon's centroid and eight
                    //    rays — both continuous in a body that the radio is stirring — and `fit` is
                    //     carried to three decimals, so a cell breathing by a unit re-emits a different
                    //      width, height AND scale.  That is a face resizing several times a second
                    //       under a reader who never asked it to: the owner's *"jitterbugging of size"*
                    //        on the path that was never covered.
                    //  Focus only.  Under foam the molds RIDE the springs, and holding one still there
                    //   would peel it off the cell it belongs to — the motion is the point in that
                    //    regime, and it is not the point in this one (*"assigned, still"*).
                    //  ⚠ AND A DEAD BAND CANNOT STOP A 2-CYCLE (2026-08-12).  If the value alternates
                    //   between two seats FURTHER apart than the band, every round is "not still", the
                    //    band never fires and the mold flips at paint rate — the owner: *"jitterbugging
                    //     between two positions, a measurement+position feedback loop"*.  Nor can a
                    //      throttle fix it: it bounds how OFTEN the flip happens, so a fast buzz becomes
                    //       a slow one, forever, because both states are self-consistent (the `--lay`
                    //        note above says exactly this about the height involution).  What ends a
                    //         2-cycle is REFUSING TO RETURN: remember one seat back, and if the "new"
                    //          seat is the one we just left, stay put.  `stretch_search` has carried the
                    //           same guard for its column since the day it was written; this is that
                    //            idiom, one quantity over.
                    if (focusR && face) {
                        const st = row.c as any
                        type Held = { x: number, y: number, w: number, h: number, fit: number }
                        const prev = st.mold_hold as Held | undefined
                        const back = st.mold_back as Held | undefined
                        const now = { x: mx, y: my, w: mw, h: mh, fit }
                        const same = (a: Held | undefined, b: Held) => !!a && seat_still(a, b)
                            && Math.abs(a.fit - b.fit) <= Math.max(0.01, a.fit * SEAT_STILL)
                        //  …AND THE CYCLE MEMORY IS ON A CLOCK (the owner, on the first cut of it:
                        //   *"it wasn't properly positioned for a while, and was harder to get to
                        //    reposition than usual"*).  A 2-cycle is a FAST alternation — it flips every
                        //     paint, so both legs land inside `MOLD_CYCLE_MS`.  Without the clock the
                        //      remembered seat never expires, so a seat left minutes ago goes on vetoing
                        //       a perfectly legitimate move back to it, and the face is pinned somewhere
                        //        wrong with no way to talk it out.  A guard against oscillation must not
                        //         become a guard against MOVING; that is the settling-window lesson
                        //          arriving a third time.
                        const cycling = same(back, now) && Date.now() - +(st.mold_at ?? 0) < MOLD_CYCLE_MS
                        if (prev && !settling(row) && (same(prev, now) || cycling)) {
                            mx = prev.x; my = prev.y; mw = prev.w; mh = prev.h; fit = prev.fit
                        } else { st.mold_back = prev; st.mold_hold = now; st.mold_at = Date.now() }
                    }
                    // ── AND `stretch_rect` IS THE MOLD ASSIGNED, NEVER THE ONE SOLVED FOR ──────────
                    //  This used to be written up in the stretch block off `fr`, before the band above
                    //   had had its say — so whenever the band held the mold at its standing size,
                    //    `--lay` (= col / stretch_rect.w) was struck against a DIFFERENT rectangle than
                    //     the face was laid out in, and the column actually rendered came to
                    //      `col × mw_held / fr.w`: breathing with the body again, which is precisely the
                    //       coupling `--lay` exists to remove.  Measure at one column, solve at another,
                    //        and the involution is back — a dead band on the mold reintroduced it
                    //         (2026-08-11 → 2026-08-12).  Write what was ASSIGNED and the two agree
                    //          again whether the band fired or not.
                    if (focusR && stretchPose && mw > 8 && mh > 8) {
                        (row.c as any).stretch_rect = { x: mx + mw / 2, y: my + mh / 2, w: mw, h: mh }
                    }
                    cells.push({ tok: n.tok, key: n.key, depth: n.depth, hasKids, ident, spike: sp,
                                 x: ax, y: ay, r: s.r, kind: 'poly', d: path_round(sp ? sp.poly : poly), departing: false, lift,
                                 bx: vx, by: vy, bw: vw, bh: vh,
                                 mx, my, mw, mh, ang, clip: clipPoly, face, source, row, fx, fxi, fit, sunk, poly,
                                 room: Math.abs(poly_area(poly)) })
                    if (hasKids) layout(n.kids, poly, 0, n.key, n)
                } else {
                    // no poly: a crowded-out seed draws its 6px marker; a LOOSE row draws at its
                    //  solved rim radius on the loose layer — dim, off the pile, drifting with stirs.
                    const isLoose = foam && !!(row.sc as any).loose
                    const lr = isLoose ? Math.max(6, s.r) : 6
                    // NO CELL MEANS NO ROOM (2026-08-09, the owner: *"I can see a puddle of our html
                    //  overlays (a Component per cell?) sitting over the top of each other, even though
                    //   the cells are kinda spread out"*).  A crowded-out seed gets no polygon and falls
                    //    back to a 6px marker — but it kept the incoming `fit` of 1, so it MOUNTED ITS
                    //     FACE into a 12×12 mold, and every crowded-out row's mold landed in the same
                    //      few pixels near the bag's heart.  That is the puddle, and the mold map found
                    //       it in one shot: three molds, all exactly 12×12, all within 60px.  A row the
                    //        cut could not seat has earned no surface, so hand it fit 0 — the icon
                    //         register then draws its marker and its edge label and nothing else.
                    //  LOOSE rows are exempt: they are off the pile BY CHOICE and draw at a real solved
                    //   radius, so they keep whatever fit they were priced at.
                    cells.push({ tok: n.tok, key: n.key, depth: n.depth, hasKids: false, ident,
                                 x: s.x, y: s.y, r: lr, kind: 'disc', d: '', departing: false, lift,
                                 bx: s.x - lr, by: s.y - lr, bw: 2 * lr, bh: 2 * lr,
                                 mx: s.x - lr, my: s.y - lr, mw: 2 * lr, mh: 2 * lr, ang: 0,
                                 clip: clipPoly, face, source, row, fx, fxi,
                                 fit: isLoose ? fit : 0, loose: isLoose, sunk })
                }
            }
            // ── the SELF SEAT's own cell, emitted last so it paints over its children's walls (the
            //  seam it shares with them is the thing that should not read as a border).  It carries
            //   the PARENT's face, source and row — pressing it is pressing the parent, which is what
            //    "not separate to the cell itself" has to mean for the pointer as well as the eye.
            if (selfOf && selfFace && selfSeed) {
                const spoly = polyByKey.get(selfOf.key + SELF_KEY)
                const ps = sp.get(selfOf.key)
                if (spoly && ps) {
                    const sbb = bbox_of(spoly)
                    // SEATED BY RAYS, exactly like a leaf: cast at the measured box's own corners and
                    //  take the tightest hit, so the component sizes to the room it actually WON
                    //   rather than to the box it wished for.  Unmeasured (need_w/h absent until the
                    //    first flush) falls back to the bbox, which is the same fallback leaves use.
                    const snw = (selfOf.row.c as any).need_w as number | undefined
                    const snh = (selfOf.row.c as any).need_h as number | undefined
                    let sfit = 1
                    if (snw && snh) {
                        let byray = Infinity
                        for (const [qx, qy] of [[1,1],[1,-1],[-1,1],[-1,-1],[1,0],[-1,0],[0,1],[0,-1]]) {
                            const ex = (snw / 2) * qx, ey = (snh / 2) * qy
                            const L = Math.hypot(ex, ey); if (!(L > 0)) continue
                            const t = ray_hit(spoly, selfSeed.x, selfSeed.y, ex / L, ey / L)
                            if (t > 0) byray = Math.min(byray, Math.max(0, t - 2) / L)
                        }
                        sfit = Number.isFinite(byray) ? byray : Math.min(sbb.bw / snw, sbb.bh / snh)
                    }
                    sfit = +Math.max(0.2, Math.min(FIT_MAX, sfit)).toFixed(3)
                    cells.push({ tok: selfOf.tok, key: selfOf.key + SELF_KEY, depth: selfOf.depth + 1,
                                 // A SCOPE IS THE ONE THING ON THE GLASS WITH NO NAME.  `hasKids`
                                 //  suppresses a scope's own label (its children tile it, so there is
                                 //   nowhere to put one), and the self seat — the scope's own body among
                                 //    its children — carried `ident: ''`, so the name fell off the world
                                 //     entirely.  It already wears the parent's face, source and row;
                                 //      wearing the parent's NAME is the same sentence finished.
                                 hasKids: false, ident: ident_of(selfOf.row, w, selfOf.tok),
                                 x: selfSeed.x, y: selfSeed.y,
                                 r: Math.max(6, Math.min(sbb.bw, sbb.bh) / 2), kind: 'poly',
                                 d: path_round(spoly), departing: false, lift: false,
                                 bx: sbb.bx, by: sbb.by, bw: sbb.bw, bh: sbb.bh,
                                 mx: sbb.bx, my: sbb.by, mw: sbb.bw, mh: sbb.bh, ang: 0,
                                 clip: clip_of(spoly, sbb), face: selfFace.comp, source: selfFace.source,
                                 row: selfOf.row, fx: '', fxi: 0, fit: sfit, sunk: false,
                                 poly: spoly, room: Math.abs(poly_area(spoly)), selfseat: true })
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
            const tnKeep = tn.all.filter(nn => nn.key.indexOf('Heist:') === 0)
            const emitted = new Set(cells.filter(c => c.key.indexOf('Heist:') === 0).map(c => c.key))
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
        // OCCLUSION ORDER (the owner 2026-08-09: "cells need occlusion ordering, html should always
        //  spill out").  SVG paints in document order and the molds mirror the same rank through a
        //   translateZ step (mold_seat), so this ONE sort is the whole z-law of the glass: parents
        //    under children (depth), then BIG UNDER SMALL — a small cell, its label and its spilled
        //     face always ride on top of a large neighbour's spill, which is what makes unclipped
        //      HTML livable.  Area is quantized so settle-time drift never flips two near-equal
        //       cells back and forth and churns the keyed-each DOM order.
        cells.sort((a, b) => (a.depth - b.depth)
            || (Math.round((b.bw * b.bh) / 1500) - Math.round((a.bw * a.bh) / 1500))
            || (a.key < b.key ? -1 : a.key > b.key ? 1 : 0))
        for (let zi = 0; zi < cells.length; zi++) cells[zi].zi = zi
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
        // THE GALAXY MORPH (the owner: "everything spins (when morphing) like a galaxy") — foam only.
        //  When a spring's TARGET leaps (a focus flip, a pose change, a re-commission), the straight
        //   critically-damped approach reads as a slide.  Kick the spring's POSITION once, perpendicular
        //    to its displacement, and the same spring math then carves a curved, turning approach —
        //     change rotates into place.  One-shot per leap (keyed on the last seen target), never a
        //      standing force, so settle math and the calm floor are untouched; parked worlds returned
        //       above and never feel it.
        const foamW = !!(w.c as any).foam
        for (const [key, s] of sp) {
            const row = rowByKey.get(key)
            const T = row ? target_of(row) : null
            if (!T) continue
            if (foamW) {
                if (s.ltx !== undefined && (Math.abs(T.x - s.ltx) > 40 || Math.abs(T.y - (s.lty ?? 0)) > 40)) {
                    const dx = T.x - s.x, dy = T.y - s.y
                    const d = Math.hypot(dx, dy)
                    if (d > 1) {
                        const sw = Math.min(60, d * 0.35)
                        s.x += (-dy / d) * sw
                        s.y += (dx / d) * sw
                    }
                }
                s.ltx = T.x; s.lty = T.y
            }
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
            const sawHeist = new Set<string>()
            for (const n of tree_nodes(w).all) {
                if (n.key.indexOf('Heist:') === 0) sawHeist.add(n.key)
                const T = target_of(n.row)
                if (!T) {
                    if (n.key.indexOf('Heist:') === 0) console.log('◈ Vyto adopt: row.c.T MISSING for', n.key)
                    continue
                }
                present.add(n.key)
                let s = sp.get(n.key)
                if (!s) {
                    if (n.key.indexOf('Heist:') === 0) console.log('◈ Vyto adopt: NEW spring (entrance ramp) for', n.key, 'T=', JSON.stringify(T))
                    // a newcomer springs from x,y AT target with r 0 — the radius ramp IS the entrance.
                    sp.set(n.key, { x: T.x, y: T.y, r: 0, vx: 0, vy: 0, vr: 0 })
                    moved = true
                } else if (Math.hypot(s.x - T.x, s.y - T.y) > CALM_EPS || Math.abs(s.r - T.r) > CALM_EPS) {
                    moved = true
                }
            }
            for (const key of [...sp.keys()]) {
                if (key.indexOf('Heist:') === 0 && !sawHeist.has(key)) console.log('◈ Vyto adopt: row ABSENT from tree_nodes().all for', key, '(not just T-less — gone from the walk entirely)')
            }
            let removed = false
            for (const key of [...sp.keys()]) if (!present.has(key)) {
                if (key.indexOf('Heist:') === 0) console.log('◈ Vyto adopt: spring REMOVED for', key)
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
        // a composer who pulled `simmer` on the foamereo wants the layout negotiating from first
        //  sight — same toggle the ∿ button flips, so pressing it still turns it off.
        if (fo(w, 'simmer') && live_page() && !simmering.has(w)) simmer_toggle(w)
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
    // (`go_fullscreen` went with the ⛶ — 2026-08-11.  The ResizeObserver above still re-cuts the frame
    //  for a browser-driven fullscreen, and fit_frame still lets `document.fullscreenElement` beat the
    //   pick, so the PATH is intact; there is simply no longer a button in the glass that asks for it.)
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
    // ── AND IT HAS TO BE ABLE TO FALL (2026-08-10) ────────────────────────────────────────────
    //  Grow-only was a RATCHET WITH NO RELEASE, and a ratchet remembers a size long after it has
    //   stopped being true.  That is the whole of the demoted-Door defect: as the belly the Door
    //    measured its entire self, as a bud it renders one icon — but the remembered box still said
    //     "this face is 300 wide", so the fit fell under the 0.34 icon floor, the face UNMOUNTED,
    //      and AN UNMOUNTED FACE IS NEVER MEASURED AGAIN.  One-way latch: crushed because it used
    //       to be big, with no path back to learning that it isn't.  ⤢ forever.
    //  So the gauge falls as well as rises, on the owner's own prescription (*"gotta gauge that
    //   size... sensibly... over time... check again 200ms after any layout"*):
    //    · GROWING is believed at once — a component overflowing its seat is a fault you can see now;
    //    · a reading within the dead band is no news;
    //    · SHRINKING opens a window and is only taken if it is STILL TRUE `GAUGE_MS` later.  A face
    //       mid-mount, mid-font-load or mid-fold measures small for a frame or two, and taking that
    //        reading would pull the seat out from under a component about to need it.
    //  The re-check needs its own timer because `paint_tick` only bumps when geometry MOVES — a
    //   settled glass would otherwise never look a second time, which is the same "no second look"
    //    that made the ratchet permanent.  Render-side only: `need_w/need_h` never poke the model
    //     (that is `stamp_need`'s job, still grow-only), so no fixture can move under this.
    //  The decision itself lives in `vyto_gauge.ts` — pure, and therefore gated (VytoGauge.spec).
    //   Here is only what a decision cannot be: the clock, the re-check timer, and the relayout.
    //  THE TIMER IS NOT OPTIONAL.  `paint_tick` only bumps when geometry MOVES, so a settled glass
    //   would never look a second time — the same "no second look" that made the ratchet permanent.
    //    That is the owner's *"check again 200ms after any layout"*, and it is why the window can
    //     close at all.
    const gauge_timers = new Map<TheC, any>()
    function gauge_again(w: TheC) {
        if (typeof setTimeout === 'undefined' || gauge_timers.has(w)) return
        gauge_timers.set(w, setTimeout(() => { gauge_timers.delete(w); measure_world(w) }, GAUGE_MS + 20))
    }
    function stamp_box(w: TheC, row: TheC, nw: number, nh: number) {
        const v = gauge_box(row.c as any, nw, nh, Date.now())
        if (v === 'watching') gauge_again(w)
        // ANY CHANGE TO THE BOX MAKES THE SEAT STALE, and nothing else will notice: `paint_tick` only
        //  bumps when geometry MOVES, so a face that has just been measured sits at whatever seat it
        //   was given before anyone knew its size — until some unrelated thing moves.  The owner
        //    watched exactly that: *"arrives small and to the side, then it requires mousing over the
        //     simulation to resize and reposition it properly into that space"* — the mouse was doing
        //      the relayout, because a hover is the only thing that reliably bumps the paint.
        //  `react_soon` is the trailing-edge latch, so a burst of first-measures folds into one adopt.
        else if (v === 'first' || v === 'grew' || v === 'fell') {
            react_soon()
            // ── A GROW IS THE READING MOST LIKELY TO BE WRONG (2026-08-12) ────────────────────────
            //  Growing is believed AT ONCE, on purpose — a component overflowing its seat is a fault
            //   you can see now.  But "believed at once" and "never checked again" are different
            //    promises, and only the first one was ever meant: a face measured mid-mount, mid-font-
            //     load or mid-HMR lays out unconstrained for a frame or two and reads far too wide, and
            //      once that reading is taken the geometry STOPS MOVING — so `paint_tick` never bumps,
            //       nothing measures again, and the mold sits permanently too big with the face
            //        rattling inside it.  Caught live: one player tab held a natural width 20% over the
            //         truth with 17% air beside the face, while the other tab, from the identical
            //          reload, sat at the right number.  The shrink window cannot rescue that on its
            //           own — a window that nobody opens is just a closed door.
            //  So a grow keeps its instant belief AND arms the ladder.  The window walks it back a beat
            //   later if the grow was a frame's accident, and costs nothing if it was real.
            if (v === 'grew' || v === 'first') settle_ladder(w)
        }
    }
    // ── THE COLUMN SEARCH ──────────────────────────────────────────────────────────────────────
    //  One step per measured round.  The zoom a stretched face gets is `min(rect_w/col, rect_h/h)`
    //   where `h` is what the content came to AT THAT COLUMN — so the two terms pull opposite ways
    //    and the best column is where they meet:
    //     · height to spare (`zh > zw`) ⇒ the column is too WIDE — narrow it and buy zoom;
    //     · height binding (`zh < zw`) ⇒ too skinny, the content has grown taller than the room —
    //        widen it and give some zoom back.
    //  It settles because of the DEAD BAND, not because of a step count: once the two zooms are
    //   within `STRETCH_BAND` of each other nothing is written and nothing re-lays out.  The column
    //    is rounded to a whole unit so a settled search re-emits byte-identical numbers — the same
    //     "don't make the relayouts an annoyance" discipline as the 2dp `fit`.
    function stretch_search(w: TheC, cell: PaintCell, mold: Element, sy: number) {
        const c = cell.row.c as any
        const child = (mold.querySelector('.face-scroll')?.firstElementChild) as HTMLElement | null
        if (!child || !(child.offsetHeight > 0)) return
        const h = child.offsetHeight * sy
        const prev = +(c.stretch_h ?? 0)
        if (!(prev > 0) || Math.abs(h - prev) / h > 0.02) { c.stretch_h = h; react_soon() }
        const fr = c.stretch_rect
        if (!fr || !(fr.w > 0) || !(fr.h > 0)) return
        // MEASURE THE COLUMN, DO NOT ASSUME IT.  `h` is whatever the content came to in the box it was
        //  ACTUALLY given, so the `col` it is paired with has to be that same box or the solve is
        //   comparing a height from one layout against a width from another — which is how a search
        //    that looks correct on paper ends up chasing its own tail.  Since `--lay` these agree, and
        //     that is the point: reading the DOM keeps them agreeing even if some future rule changes
        //      the box again, instead of failing silently the way the coupled version did.
        const col = child.offsetWidth > 0 ? child.offsetWidth * sy : +(c.stretch_col ?? STRETCH_COL0)
        const zw = fr.w / col, zh = fr.h / h
        if (zh > zw * STRETCH_BAND || zw > zh * STRETCH_BAND) {
            // the solve (see STRETCH_LEAP above), then the safeties: bound the leap, clamp to the legal
            //  range, round to a whole unit so a settled search re-emits identical numbers — and drop a
            //   correction too small to be worth the relayout, which is where the smoothness comes from.
            const solved = Math.sqrt((fr.w * col * h) / fr.h)
            const leapt = Math.max(col / STRETCH_LEAP, Math.min(col * STRETCH_LEAP, solved))
            const want = Math.round(Math.max(STRETCH_COL_MIN, Math.min(STRETCH_COL_MAX, leapt)))
            // the nudge floor exists so a 3% correction does not relayout the type under the reader —
            //  but while the face is still arriving a 3% correction is not noise, it is the content
            //   landing.  A quarter of the floor inside the settling window.
            const nudge = settling(cell.row) ? STRETCH_NUDGE / 4 : STRETCH_NUDGE
            if (Math.abs(want - col) < col * nudge) return
            // IT MUST TERMINATE, and the dead band alone does not guarantee that.  If the balance
            //  point falls BETWEEN two reachable columns, neither satisfies the band and a fixed
            //   multiplicative step ping-pongs between them forever — each bounce a relayout, which
            //    is precisely the annoyance the owner warned about.  A 2-cycle is the only cycle this
            //     step can produce, so remembering one column back is enough to see it and stop: we
            //      are already at the better of the two (this step would return to the worse one).
            //  `col` is now MEASURED, so it is a float; the cycle memory has to be rounded the same way
            //   `want` is or it can never match and the guard silently stops guarding.
            const here = Math.round(col)
            if (want === here || want === +(c.stretch_prev ?? 0)) return
            c.stretch_prev = here; c.stretch_col = want; react_soon()
        }
    }
    // ── THE SETTLING WINDOW (2026-08-11, the owner: *"it needs to layout a bit more, at occasions
    //  near but perhaps not exactly Heist starting..."*) ────────────────────────────────────────────
    //  Read the "perhaps not exactly" literally, because it is the whole diagnosis: the trouble is
    //   not AT the pose change, it is in the second or two AFTER it.  A Heist that has just started
    //    is a nearly-empty list; its rows arrive over the following beats.  Every guard added to stop
    //     the flitting — incumbency, the still-band, the 4% nudge floor — is a reason NOT to move,
    //      and they were all in force while the face was still becoming what it is.  So the layout
    //       settled on the shape of an empty Heist and then defended it.
    //  Stickiness therefore has to be EARNED, not granted at birth.  For `SETTLE_MS` after a pose
    //   change the seat carries no handicap, the still-band is off and the nudge floor is a quarter
    //    of its size — the layout is as free as it was before the flitting fix.  After that the
    //     guards come back and the glass goes still, which is the state it spends its life in.
    //  The LADDER is the other half, and `gauge_again` already proved why it is not optional: a
    //   settled glass never bumps `paint_tick`, so nothing would look a second time on its own.  Four
    //    re-measures across the window catch the content wherever it happens to land.
    const SETTLE_MS = 2200
    const SETTLE_LADDER = [180, 520, 1200, 2000, 3200]
    const settle_timers = new Map<TheC, any[]>()
    function settling(row: TheC): boolean {
        const at = +((row.c as any).settle_at ?? 0)
        return at > 0 && Date.now() - at < SETTLE_MS
    }
    // the re-measure ladder itself, shared by the two things that need one.  World-level because every
    //  rung is a whole `measure_world`; re-arming clears the outstanding rungs so a burst of reasons to
    //   look again is still one ladder, not N overlapping ones.
    function settle_ladder(w: TheC) {
        if (typeof setTimeout === 'undefined') return
        for (const t of settle_timers.get(w) ?? []) clearTimeout(t)
        settle_timers.set(w, SETTLE_LADDER.map(ms => setTimeout(() => { measure_world(w); react_soon() }, ms)))
    }
    function regauge_pose(row: TheC, w: TheC) {
        if (!gauge_pose(row.c as any, String((((row.c as any).source_n) as any)?.c?.pose ?? ''))) return
        ;(row.c as any).settle_at = Date.now()
        settle_ladder(w)
    }
    // ── AND A GLASS ARRIVES, TOO (2026-08-12, the owner: *"initially Radio has its component face way
    //  off to the side and tidy. a bit more trying to get that jiggled out?"*) ──────────────────────
    //  The ladder above is armed by a POSE CHANGE, and the arrival of the glass itself is not one: the
    //   first pose a row is ever seen wearing arms it, but only from the paint that carried a mounted
    //    face — and everything that makes the first seat wrong lands in the second after that.  On the
    //     first paint nothing has been measured, so the mold is sized and seated from a natural box
    //      nobody knows yet; the springs are still relaxing toward targets the focus regime does not
    //       draw; the face's own content (a track name, a chunk count) is still arriving.  Every one of
    //        those resolves within a beat or two — but ONLY IF SOMEBODY LOOKS AGAIN, and `paint_tick`
    //         bumps when geometry MOVES, so a glass that has gone still will not look on its own.  That
    //          is the whole of *"it requires mousing over the simulation"*: the mouse was the ladder.
    //  So the first time a world is successfully measured, arm one.  Once per world (`settled_in`), so
    //   this costs five measures at boot and nothing ever again.
    function settle_arrival(w: TheC) {
        const c = w.c as any
        if (c.settled_in) return
        c.settled_in = 1
        settle_ladder(w)
    }
    function measure_world(w: TheC) {
        if (!(w.c as any).need_floor) return
        // NOT WHILE ENGAGED.  (`need_area`, the model's floor, is still grow-only — the natural BOX is
        //  gauged both ways now, see `stamp_box`.)  The honest contract is that a widget's
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
        for (const t of stage.querySelectorAll('text.ident:not(.under):not(.crush)')) {
            const cell = byKey.get((t as Element).getAttribute('data-key') ?? '')
            if (!cell || cell.departing) continue
            try {
                const bb = (t as SVGGraphicsElement).getBBox()
                stamp_need(w, cell.row, bb.width * bb.height)
            } catch { /* an unrendered node has no box — skip */ }
        }
        let seen = 0
        for (const m of stage.querySelectorAll('.face-mold')) {
            const cell = byKey.get((m as Element).getAttribute('data-key') ?? '')
            if (!cell || cell.departing) continue
            seen++
            // A STRETCHED FACE IS MEASURED ON ONE AXIS ONLY, and searched on the other.
            //  Its WIDTH is assigned (the column), so reading it back would just be the mold talking
            //   to itself — the `.df-small { height: 100% }` feedback loop.  Its HEIGHT is genuinely
            //    intrinsic: it is what this content comes to WHEN GIVEN THAT COLUMN, which is the one
            //     fact the layout cannot compute and the whole reason a fixed column could not be
            //      guessed right.  So: measure the height, then step the column toward the balance
            //       point and ask again — the owner's *"needs more rounds of measuring"*.
            if (stretch_cell(cell)) { stretch_search(w, cell, m as Element, sy); continue }
            const scroll = (m as Element).querySelector('.face-scroll') as HTMLElement | null
            const child = scroll?.firstElementChild as HTMLElement | null
            if (!scroll || !child || typeof child.offsetWidth !== 'number') continue
            if (Math.abs(child.offsetWidth - scroll.clientWidth) <= 1) continue   // box-stretched — skip
            const nw = child.offsetWidth * sx, nh = child.offsetHeight * sy
            stamp_box(w, cell.row, nw, nh)
            stamp_need(w, cell.row, nw * nh)
        }
        // a paint that carried no face has measured nothing, so it is not the arrival — wait for one
        //  that did, or the ladder is spent on an empty stage.
        if (seen) settle_arrival(w)
    }
    $effect(() => {
        void paint_tick
        // measure AFTER the flush carrying this paint (microtask chain — runs in hidden tabs too,
        //  where the whole runner lives); reads no tracked state, so no feedback into the effect.
        Promise.resolve().then(() => { for (const w of springs.keys()) measure_world(w) })
    })
    // ── A FACE CAN CHANGE SIZE WITHOUT ANYTHING MOVING (2026-08-10, the owner: *"the 'Invite...'
    //  popup opening needs to trigger a size check as well"*) ──────────────────────────────────────
    //  The pass above rides `paint_tick`, and `paint_tick` only bumps when GEOMETRY MOVES.  Opening
    //   the invite panel changes what the Door draws and moves nothing, so no size check ever ran and
    //    the face sat in a seat measured for the folded version of itself.  The 200ms gauge timer does
    //     not cover it either — that only arms while a SHRINK window is open.
    //  So: a model bump is also a reason to look.  A face reads the particle, so if the particle
    //   changed, what the face draws may have changed size — which is exactly why DoorFace's invite
    //    state was moved onto `.c` and bumped rather than kept in component-local `$state`.
    //  NOT OFF `H.version` — that was the first cut and it is the trap this file already documents
    //   two screens up: `adopt` autovivifies Matstyle swatches on `H.ave`, so an effect that READS
    //    `H.version` and ends (however indirectly) in an adopt is subscribed to its own consequences.
    //     Measuring feeds `react_soon` feeds `adopt` feeds a bump feeds the effect — a loop paced by
    //      timers rather than a synchronous one, so it does not blow the effect depth, it just spins
    //       full adopts forever.  Measured live: the model stayed perfectly healthy (pokes answered,
    //        `belly=Radio`) while the glass went missing from the DOM — render dead, model fine.
    //  THE HONEST INSTRUMENT IS A ResizeObserver ON THE FACE ITSELF.  A size check should be
    //   triggered by a size CHANGING, not by the model ticking: it fires exactly when a face's own
    //    box moves (the invite panel unfolding is precisely that), it costs nothing when nothing
    //     changes, and it cannot route back through the reactive graph at all.
    //  Still trailing-edge — a burst of resizes folds into ONE measure, after the flush, with the
    //   forced-layout reads well outside any reactive context.
    let measure_pending: any = 0
    function measure_soon() {
        if (measure_pending || typeof setTimeout === 'undefined') return
        measure_pending = setTimeout(() => {
            measure_pending = 0
            for (const w of springs.keys()) measure_world(w)
        }, 140)
    }
    let faceRO: ResizeObserver | null = null
    // the action rides `.face-scroll`, but what it OBSERVES is the face's own root inside it: the
    //  scroll's box is handed down from the mold (it changes when WE change it), while the child's
    //   box is the face's own answer — the thing worth hearing about.  Re-resolved on update and on
    //    a microtask, because the Face mounts after the action runs.
    function sizewatch(el: HTMLElement) {
        if (typeof ResizeObserver === 'undefined') return
        if (!faceRO) faceRO = new ResizeObserver(() => measure_soon())
        let kid: Element | null = null
        const attach = () => {
            const k = el.firstElementChild
            if (k === kid) return
            if (kid) faceRO!.unobserve(kid)
            kid = k
            if (kid) faceRO!.observe(kid)
        }
        attach(); queueMicrotask(attach)
        return {
            update() { attach() },
            destroy() { if (kid) faceRO?.unobserve(kid); kid = null },
        }
    }

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
        if (measure_pending) clearTimeout(measure_pending); measure_pending = 0
        for (const t of gauge_timers.values()) clearTimeout(t)
        gauge_timers.clear()
        faceRO?.disconnect(); faceRO = null
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
    function engaged_key(w: TheC): string { void paint_tick; return engaged.get(w) ?? '' }
    // THE WAVE (the owner: "some chunky covering like a wave from the side of the cell, labels,
    //  which fold away (like a wave toppling in reverse) when the cell is focused").  A scalloped
    //   band along the cell's top edge wearing the ident large; engaging the cell folds it away.
    //    Starts right of the hallway head so the corridor reads as running IN under the wave.
    function wave_d(cell: PaintCell): string {
        const x0 = cell.bx + 16, x1 = cell.bx + cell.bw
        const w = x1 - x0
        if (w < 24) return ''
        const y0 = cell.by, h = 13
        const humps = Math.max(2, Math.round(w / 26))
        const hw = w / humps
        let d = `M ${x0},${y0} L ${x1},${y0} L ${x1},${(y0 + h - 3).toFixed(1)}`
        for (let i = humps - 1; i >= 0; i--)
            d += ` Q ${(x0 + hw * (i + 0.5)).toFixed(1)},${(y0 + h + 4).toFixed(1)} ${(x0 + hw * i).toFixed(1)},${(y0 + h - 3).toFixed(1)}`
        return d + ' Z'
    }
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
    // the BREATH gate: foam glasses on the live page only — runners and Books never breathe, so
    //  captures stay deterministic and the drive sees a still world.  CSS-animated (no rAF, no
    //   settle interference — the spring loop still parks; only the compositor moves).
    function foam_breathes(w: TheC): boolean { void paint_tick; return !!(w.c as any).foam && live_page() }
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
        //    Shuffle, Heist…), not to the shelves a %Record hangs under, so a purely structural walk can
        //     run its whole guard and draw nothing.  But the glass is usually already showing the track
        //      — as a REFERRING particle wearing its own mainkey and carrying the holding's id
        //       (`Card,id:X` / `Heist,…` / `Spin,of:X`; CLAUDE.md's identity model).  That id IS the join,
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
    // the ATTENTION CURRENCY's earn side (model: Vyto_attend — self-taxing heat, spent by
    //  express as size).  A hover pays a little, a press pays more; throttled per tok so a
    //   jittering pointer at a wall doesn't storm the stir.  Live pages only — a Book never
    //    navigates, so no fixture can feel heat.
    const lastAttend = new Map<string, number>()
    function attend(w: TheC, tok: string, amt: number) {
        if (!live_page() || fo(w, 'still')) return
        const now = performance.now()
        if (now - (lastAttend.get(tok) ?? 0) < 400) return
        lastAttend.set(tok, now)
        ;(H as any).Vyto_attend?.(w, tok, amt)
    }
    // ── NOTHING MOVES UNDER THE POINTER (2026-08-09, the owner: *"when we mouse over a cell, it cannot
    //  move under us!"*).  Two separate faults, both mine, both making the cell move on hover:
    //   1. The hold was placed only `if (key === tok)`.  A key carries depth, a tok does not, so that
    //      test is true for top-level cells and FALSE for every nested one — most of the glass was
    //      never pinned on hover at all.  The verb takes any tok; the guard was the whole bug.
    //   2. Hover granted HEAT (0.08), and express spends heat as SIZE.  So pointing at a cell made it
    //      grow, which moved it, which moved its neighbours — the exact opposite of the rule, added by
    //      me while building the attention currency.  Heat is now earned by PRESSING only: a click is
    //      a choice, and a choice may rearrange the world; passing the mouse over something is not.
    function on_enter(w: TheC, key: string, tok: string) {
        lifted.set(w, key)
        ;(H as any).Vyto_pointer_enter?.(w, tok)
        kick(w); paint_tick++
    }
    function on_leave(w: TheC, key: string, tok: string) {
        if (lifted.get(w) === key) lifted.delete(w)
        ;(H as any).Vyto_pointer_leave?.(w, tok)
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
        <!-- THE BAR, THE ORGAN PANEL AND THE MOMENT STRIP ARE GONE (2026-08-11, the owner: *"all the
             Vyto options, live|depths|flows I never found out what any of that did anyway. no aspect
              ratio or list of dots representing some other timeline than Story steps... so the whole
               page is just full-view Vyto glass"*).  Four bits of chrome, one verdict — the page IS
                the glass, and everything that sat above it was developer furniture charged to the
                 listener in screen height.
             WHAT WENT, and what is still there without it:
               • the seven bar words (live · depths · flows · frames · holds · pelt · o).  The %Bar
                 particles STAY minted in Vyto.g — they are the doctrine, and Books snap them — so
                  `bar_on` still reads them and `live` is still on by default; only the buttons left.
                   `holds` therefore never paints now, which is correct: it is an inspection overlay
                    and there is no longer an inspector on this page.
               • `organs` + its panel — a dev listing of the eleven stations, all still `status:stub`.
               • the aspect <select>.  `auto` was already the default and the only pick anyone kept,
                  and "measure the hole" is the law the whole §0.2(d) frame work landed on; a dropdown
                   that can only make the glass WORSE than the measurement is not a control.
               • the %Moment tick strip — a second timeline running beside Story's steps, which is
                  exactly the confusion the owner names.  Moments are still spooled model-side.
             The height this frees is not left as air: `.stage` loses its top margin and `.depth`'s
              cap goes up (see the CSS), so the glass takes the room the chrome was holding. -->
        {#if show_viewport(w)}
            {@const plug = plug_of(w, viewport_cells(w))}
            {@const ants = plug ? ants_of() : null}
            {@const plug_id = 'vyplug-' + String((w.sc as any)?.w ?? 'w').replace(/[^A-Za-z0-9_-]/g, '')}
            {@const cam = cam_view(w)}
            <div class="stage" use:reg_stage={w} use:lifetell={{ H, what: 'stage', id: String((w.sc as any)?.w ?? '?') }}>
                <!-- THE STAGE BAND IS GONE with the drag it advertised (2026-08-10, the focus
                     pivot) — staging is the commission's call now, not a drop target's. -->
                <!-- the one report the deleted markers owed: the rows the cut could not seat.  Said once,
                     in a corner, where it costs nobody their pixels — rather than N times, on top of
                     whatever won the room.  Absent when everything got a seat, which since the SEAT FLOOR
                     landed is very nearly always, and is exactly the state that deserves no chrome at all.
                     WHAT IS LEFT HERE IS A WAY BACK IN, not a tally (the owner 2026-08-09: *"we should be
                     able to click back into it ... and have some other cells we can switch on"*).  A bare
                     count names no defendant: you cannot check it, and you certainly cannot act on it.
                     Each missing row is now its own chip that says WHO, and pressing it pays the crushed
                     price out of the attention currency — the same coin a press on a crushed cell spends —
                     so the thing you named takes room off everyone else and seats itself.  That is the
                     recovery the null-poly trapdoor removed: a row with no cell had no click target at
                     all, so the only cells you could rescue were the ones that did not need rescuing. -->
                {#if unseated_cells(w).length > 0}
                    {@const missing = unseated_cells(w)}
                    <!-- TWO WAYS TO HAVE NO CELL, ONE WAY BACK.  A row lands here either because the cut
                         could not seat it at all, or because the VANISH FLOOR took a shard away and gave
                         the room to its neighbours.  They are the same fact to a reader — "this is here
                         and you cannot see it" — and the same press fixes both, so they share the note
                         rather than each growing chrome of their own. -->
                    <div class="unseated" title="rows with no cell — too crowded to seat, or too small to draw. press one to give it the room">
                        <span class="unseated-lede">no room</span>
                        {#each missing as u (u.key)}
                            <button class="unseat-chip" onclick={() => attend(w, u.tok, 0.85)}
                                    title={`seat ${u.ident} — takes the room off everyone else`}>{u.ident}</button>
                        {/each}
                    </div>
                {/if}
                <!-- THE AWAIT RING (the owner 2026-08-09: "look a bit more spinnery before the data
                     comes in").  An empty glass used to be a blank plate — indistinguishable from a
                     broken one, for up to ~30s while the share arms.  While there is NOTHING to cut,
                     a slow ring says "alive, waiting".  Gone the instant the first cell lands; live
                     tabs only, so no Book or capture ever contains it. -->
                {#if live_page() && !parked(w) && viewport_cells(w).length === 0}
                    <div class="await-spin" title="waiting for the world to arrive"></div>
                {/if}
                <!-- ⛶ IS GONE TOO (same breath: *"no fullscreen button in the Vyto glass either,
                     it'll just how it is"*).  It made sense when the glass was a panel among panels;
                      the page is the glass now, so the button's whole offer — "make this bigger" —
                       is already the resting state.  The fullscreen PATH stays live in fit_frame
                        (`document.fullscreenElement` still beats the measure) so an F11 or a browser
                         menu is still measured honestly; only the chrome that asked for it left. -->
                <!-- THE TOYBOX IS GONE (2026-08-10, the focus pivot: *"forget the other buttons.
                     time to slick it all back"*).  ⋯ and everything behind it — ∿ simmer, ≡ even,
                     ⚔ compete, ▢ bare, ▦ seat, ⧉ junk, ⟳ redraw — plus the ⤫ unstage and ⇱ release
                     chips.  The glass is an artifact with a big blob to present stuff in; the one
                     control left on the stage is ⛶.  The machinery behind several of those words
                     still stands model-side (regimes via foamereo, junk via Sounditron_junk,
                     staging via stage_want) — they are composed now, not pressed. -->

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
                <!-- the composer's deck, ON THE ELEMENT (2026-08-09): the only instrument this glass has
                     is the `--svg` capture, and it could not tell a world that declined the room law from
                     one whose commission never reached it — which is exactly the question a capture gets
                     asked first.  Empty string when unset, so it costs a world nothing to have none. -->
                <!-- NO SILENT CAPS.  The corner note is HTML and never reaches a capture, so the rows
                     that have no cell — crowded out, or under the vanish floor — would be invisible to
                     exactly the instrument we use to judge the glass.  Ride the count out on the svg. -->
                <!-- and the seat's own three numbers, for the same reason: whether the regime is on at
                     all, how many rows are on its waiting list, and how sour the standing deal has
                     gone (the re-deal trigger).  A capture that cannot see these cannot judge it. -->
                <svg class="viewport" data-foamereo={String((w.sc as any)?.foamereo ?? '')}
                     data-noroom={unseated_cells(w).length}
                     data-seat={seat_on(w) ? '1' : '0'}
                     data-seatwait={(w.c as any).seat_wait ?? 0}
                     data-seatbad={(w.c as any).seat_bad ?? 0}
                     data-redeals={(w.c as any).re_deals ?? 0}
                     viewBox="{cam.x} {cam.y} {cam.w} {cam.h}" preserveAspectRatio="xMidYMid meet">
                    <!-- COPPER (the owner 2026-08-09: "you could use copperannodes.jpg at different
                         scales for texture perhaps").  userSpaceOnUse, so the grain lives in WORLD
                         units — flying the camera into a cell zooms the metal with it, which is what
                         makes it read as material rather than wallpaper.  Two scales: coarse for the
                         ground the cells sit on, fine for the hallway ribbon + the A pad (a third,
                         smaller still, rides the HTML A dial as a CSS background).
                         The ids repeat across worlds ON PURPOSE: every svg must carry its own defs so
                         a runner_shot --svg capture stays standalone; identical content makes the
                         document-wide first-match resolution a no-op. -->
                    <defs>
                        <pattern id="vy-cop-coarse" patternUnits="userSpaceOnUse" width="520" height="520">
                            <image href="/i/copper_anodes.jpg" width="520" height="520" preserveAspectRatio="xMidYMid slice"></image>
                        </pattern>
                        <pattern id="vy-cop-fine" patternUnits="userSpaceOnUse" width="130" height="130">
                            <image href="/i/copper_anodes.jpg" width="130" height="130" preserveAspectRatio="xMidYMid slice"></image>
                        </pattern>
                    </defs>
                    {#if !fo(w, 'copperless')}
                        <rect class="ground-tex" x={cam.x} y={cam.y} width={cam.w} height={cam.h} fill="url(#vy-cop-coarse)"></rect>
                    {/if}
                    <!-- THE VINES, FIRST: the %Flow relations the solver already bunches by, drawn as
                         roots UNDER the cells they tie together.  Nothing when nothing relates. -->
                    {#each vines_of(w, viewport_cells(w)) as v (v.d)}
                        <path class="vine" d={v.d} style="stroke-width:{v.sw};"></path>
                    {/each}
                    {#each viewport_cells(w) as cell, ci (cell.key)}
                        {@const g = cell_ground(cell)}
                        {@const cdv = Number((cell.row.sc as any)?.dose) || 0}
                        {#if cell.kind === 'poly'}
                            <!-- the hand is off the wall (2026-08-10): no grab, no drag, no focus
                                 attention buy.  A cell is pressed (the smuggled .c.press) or it is
                                 looked at.
                                 THE CELLS ARE DRAWN EXACTLY AS BEFORE (the owner 2026-08-10: *"if
                                 the cells could be drawn like before that'd be great"*).  A first
                                 cut hardcoded a purple fill on %Sat rows, which BYPASSED
                                 `cell_ground` → `matstyle_ground` — i.e. it opted the satellites
                                 out of the auto-swatch machinery that gives every mainkey its jewel
                                 tone, so they read as flat paint beside worked metal.  The ground
                                 comes from Matstyle again for every cell without exception; `sat`
                                 stays as a CLASS so the purple can be said in CSS as a rim, over
                                 the swatch rather than instead of it. -->
                            <!-- `data-key` ON THE WALL (2026-08-11, the owner: *"I need the Heist given more
                                 measurements to check it's fitting into the cell good"*).  The mold map already
                                  carried every face's box keyed by cell.key, but the CELL — the thing it has to
                                   fit inside — was an anonymous <path>, so a capture could say how big the face
                                    was and never whether it was inside its own wall.  One attribute joins the two
                                     layers, and runner_shot does the arithmetic (area, coverage, corners-inside).
                                 Inert for the measure pass: that selects `text.ident` and `.face-mold`, never a
                                  path, so nothing can now floor a cell to its own wall. -->
                            <path class="cell" class:departing={cell.departing} class:lift={cell.lift} class:sunk={cell.sunk}
                                  class:faced={!!cell.face && !cell.hasKids} class:nested={cell.depth > 0} class:scope={cell.hasKids}
                                  class:crushed={!!cell.face && !cell.hasKids && cell.fit <= 0.34 && !posed_cell(cell)}
                                  class:breathe={cell.fx === '' && foam_breathes(w) && !focus_on(w)}
                                  class:hot={((cell.row.c as any).heat ?? 0) > 0.25}
                                  class:pressy={pressy(cell)} class:staged={cell.tok === staged_tok(w)}
                                  class:selfseat={cell.selfseat} class:sat={sat_row(cell.row)}
                                  class:arrive={cell.fx === 'arrive'} class:erupt={cell.fx === 'erupt'} d={cell.d}
                                  data-key={cell.key}
                                  style={(g ? `fill:${g.bg}; stroke:${g.border};` : '') + (cdv > 0 ? ` stroke-width:${(1.2 + Math.min(3, cdv) * 0.55).toFixed(2)};` : '') + (cell.fx === 'arrive' ? ` animation-delay:${cell.fxi * 55}ms;` : ` --bd:-${ci * 430}ms;`)}
                                  onpointerenter={() => on_enter(w, cell.key, cell.tok)}
                                  onpointerleave={() => on_leave(w, cell.key, cell.tok)}
                                  onclick={() => cell_click(w, cell)}
                                  role="button" tabindex={0} aria-label={cell.ident}
                                  onkeydown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); cell_click(w, cell) } }}></path>
                        {:else}
                            <!-- A LOOSE row rides an ORBIT group (the <g> wrapper the drift waited
                                 on): the constellation revolves glacially about the frame heart
                                 while each member counter-rotates, so discs drift and their
                                 labels stay upright.  foam_breathes-gated like the breath: live
                                 page only — a Book's captures never see a body mid-drift. -->
                            {#if cell.loose}
                                <g class="orbit" class:adrift={foam_breathes(w)}>
                                    <g class="orbiter">
                                    <circle class="cell disc loose" class:departing={cell.departing} class:lift={cell.lift}
                                            class:arrive={cell.fx === 'arrive'} class:erupt={cell.fx === 'erupt'}
                                            cx={cell.x} cy={cell.y} r={cell.r}
                                            onpointerenter={() => on_enter(w, cell.key, cell.tok)}
                                            onpointerleave={() => on_leave(w, cell.key, cell.tok)}></circle>
                                    {#if !cell.face && !cell.hasKids}
                                        <text class="ident" class:sunk={cell.sunk} data-key={cell.key} x={cell.x} y={cell.y} text-anchor="middle" dominant-baseline="middle">{cell.ident}</text>
                                    {/if}
                                    </g>
                                </g>
                            {:else}
                                <!-- THE CROWDED-OUT MARKER IS GONE (the owner 2026-08-09: *"I don't like
                                     how we have these things: <circle class='cell disc' r='6'> and how
                                     they hang around over the top of other things"*).  A seed the cut
                                     could not seat has no polygon; it used to fall back to a 6px dot
                                     dropped at its seed — which is wherever the solve last had it,
                                     i.e. ON TOP of whatever DID win that room.  It carries no face
                                     (fit 0 since the puddle fix) and no wall, so the dot's entire
                                     content was "something is here that has nowhere to be", stated by
                                     occluding the things that do have somewhere to be.
                                     That fact is worth ONE report, not N floating dots, so it is
                                     counted into the corner note below instead.  Nothing is hidden —
                                     it is said once, in a place that costs nobody their pixels. -->
                            {/if}
                        {/if}
                        <!-- a CARVED cell wears its name in the wall (late pass below) whether or not it
                             has a face, so it does not also get one in the middle.  Below the carve it
                             keeps the centred ident — which is also what restores its need floor: the
                             measure pass stamps a cell's need off THIS text, grow-only, so a faceless
                             cell that shrinks out of the carve is measured against its own name again
                             and pushed back up.  The fallback is the floor; nothing had to be added. -->
                        {#if !cell.face && !cell.hasKids && !cell.loose && cell.kind !== 'disc' && !wall_carve(w, cell)}
                            <text class="ident" class:sunk={cell.sunk} data-key={cell.key} x={cell.x} y={cell.y} text-anchor="middle" dominant-baseline="middle">{cell.ident}</text>
                        {:else if cell.face && !cell.hasKids && !cell.departing}
                            <!-- THE LABEL, ALONG ONE SIDE (the owner: "along one side of the cell, looking
                                 like a label") + THE GUTS SPILLED BELOW IT.  Inscribing the mold opened
                                 the gap this sits in: the face now stops short of its own wall, so the
                                 label rides the top edge of the cell OUTSIDE the component rather than
                                 underneath it, and the guts run down the same margin.  Left-aligned and
                                 hanging, so it reads as a filed tab rather than a caption. -->
                            <!-- THE WAVE — the chunky label covering, folding away (toppling in
                                 reverse: scaleY about its own top edge) when the cell is engaged.
                                 The scalloped band starts right of the hallway head, so the
                                 corridor reads as running in UNDER the wave. -->
                            {#if wall_carve(w, cell)}
                                <!-- carved cells wear their name + A in the LATE FURNITURE PASS below
                                     (after every cell has painted), so no neighbour can bury them —
                                     "on top of the A labels".  Nothing to draw here. -->
                            {:else if carveable(w) && cell.kind === 'poly'}
                                <!-- TOO SMALL TO CARVE, STILL ITS OWN BODY.  Not the wave band: that is
                                     struck along the BBOX top edge, which on a ball is off the cell
                                     entirely, so it would hang the name in the air above a cell too
                                     small to have put it there.  The name goes in the middle of the
                                     body — and carries `data-key`, so the measure pass floors this
                                     cell to its own name, grows it, and it carves on the next pass.
                                     The demotion is self-repairing, not a resting state. -->
                                <text class="ident" class:sunk={cell.sunk} data-key={cell.key} x={cell.x} y={cell.y}
                                      text-anchor="middle" dominant-baseline="middle">{cell.ident}</text>
                            {:else}
                                {@const wd = wave_d(cell)}
                                <g class="wave" class:folded={engaged_key(w) === cell.key} class:sunk={cell.sunk}>
                                    {#if wd}<path class="waveband" d={wd}></path>{/if}
                                    <text class="ident under lab" data-ukey={cell.key} x={cell.bx + 20} y={cell.by + 3}
                                          text-anchor="start" dominant-baseline="hanging">{cell.ident}</text>
                                </g>
                            {/if}
                            <!-- THE CRUSH MUST BE OBVIOUS (the owner: "crush down to a simpler
                                 representation until navigated into... and that needs to be obvious!").
                                 Below the icon floor the face is not mounted at all, so without a mark
                                 a crushed cell is indistinguishable from an empty one.  A dashed wall
                                 (.cell.crushed) plus this centred glyph says "folded, more inside".
                                 No data-key: the measure pass must never floor a cell to its own
                                 crush mark. -->
                            {#if cell.fit <= 0.34 && !posed_cell(cell)}
                                <!-- THE PEARL (the owner 2026-08-09: "everything should be a cell or a
                                     sub-cell or a label ... we need consistency" — a crushed Door had
                                     shrunk to a sliver, leaving ⤢ + ident floating with no visible
                                     body, i.e. exactly the floating junk the disc markers were).  A
                                     crushed cell keeps a small round BODY: same wall/ground family as
                                     every other cell, glyph inside it.  pointer-events none — the
                                     cell's own path underneath takes the press. -->
                                <circle class="cell pearl" cx={cell.x} cy={cell.y}
                                        r={Math.min(16, Math.max(9, cell.r * 0.4))}></circle>
                                <text class="ident crush" x={cell.x} y={cell.y}
                                      text-anchor="middle" dominant-baseline="middle">⤢</text>
                            {/if}
                        {/if}
                        <!-- THE HALLWAY (the owner 2026-08-09: "the rest of the cell guts is under
                             the A. it's a hallway merged into the cell wall that we walked into this
                             world through").  A tapered corridor let into the cell's top-left wall —
                             the doorway register: this is where you came in, and the cell's own
                             scalars (the guts, formerly loose down the margin) now file down it,
                             under the A dial that heads it.  Fine copper, so it reads as the same
                             metal as the ground, worked smaller.  pointer-events none throughout:
                             the corridor is something to SEE — the A that heads it lives in the
                             HTML top layer (.adials), where a spilling face cannot bury it. -->
                        <!-- ONE PLACE FOR THE DETAIL, NOT TWO.  A carved cell now spills its scalars along
                             the wall beside its name, so the boxed hall would be the same facts a second
                             time, stacked behind the component — the "odd and messy" background the owner
                             named.  Uncarved worlds (no foam, or `wave`) have no band to spill onto and
                             keep the hall, which is the only surface they have. -->
                        <!-- ...and NOT in a carveable world at all (2026-08-10).  The hall is anchored on
                             the bbox corner, which a ball never reaches, so on any foam cell it is the
                             same floating furniture the wave band is.  Carved cells already spill along
                             the wall; small ones now say their name on the body and nothing else.  This
                             corridor belongs to the worlds with no wall law, where a cell's polygon does
                             reach its own corner. -->
                        {#if cell.kind === 'poly' && !cell.hasKids && !cell.departing && cell.bw > 30 && cell.bh > 40 && !fo(w, 'nohall') && !carveable(w)}
                            <!-- ANCHOR THE CORRIDOR TO THE WALL, NOT THE BBOX.  A foam cell's bbox
                                 corner is off the disc entirely (a circle never reaches its own
                                 corner), which is why the corridor read as detached furniture.  On a
                                 carved cell it now starts at the gate point (the 205° wall mark, just
                                 under the A) and runs inward; bbox worlds keep the old corner. -->
                            <!-- the gate-point branch that used to live here is gone with the carve: this
                                 block is now unreachable from a carveable world, so the corner IS the
                                 anchor and the ternary was a lie about which worlds get here. -->
                            {@const hx = cell.bx}
                            {@const hy = cell.by}
                            {@const hguts = under_guts(cell.row, Math.max(0, Math.min(7, Math.floor((cell.bh - 34) / 10))))}
                            {@const hh = Math.min(cell.bh - 6, 27 + hguts.length * 10)}
                            <g class="hall" class:sunk={cell.sunk}>
                                <path class="hallway" d="M {hx - 0.6},{hy + 2} L {hx + 16},{hy + 6.5} L {hx + 16},{hy + hh - 4.5} L {hx - 0.6},{hy + hh} Z"></path>
                                <path class="hall-rail" d="M {hx},{hy + 2 + hh * 0.33} L {hx + 16},{hy + 5 + hh * 0.33} M {hx},{hy + hh * 0.67} L {hx + 16},{hy + hh * 0.67 - 3}"></path>
                                {#each hguts as g, gi (g)}
                                    <text class="ident under sub" data-ukey={cell.key}
                                          x={hx + 2} y={hy + 25 + gi * 10}
                                          text-anchor="start" dominant-baseline="hanging">{g}</text>
                                {/each}
                            </g>
                        {/if}
                    {/each}
                    <!-- THE LATE FURNITURE PASS — carved names + A gates paint AFTER every cell
                         ("on top of the A labels"), so a big neighbour drawn later in the occlusion
                         order can never bury another cell's name or its handle.  Gates last of all:
                         the working part rides highest. -->
                    {#each viewport_cells(w) as cell (cell.key)}
                        <!-- NOT GATED ON THE FACE (2026-08-10).  The SPILL beside this name was un-nested
                             from this block on 2026-08-09 precisely because the face gate was silently
                             deleting every faceless carved cell's detail — but the NAME was left behind
                             the same gate, so a faceless cell ended up with its guts curved along the
                             wall and its name floating in the middle in a different typeface.  Two
                             styles, one cell.  The wall is the label surface; whatever has a wall
                             wears its name in it. -->
                        {#if !cell.hasKids && !cell.departing && wall_carve(w, cell)}
                            <!-- THE NAME IN THE WALL — the ball's upper arc doubles as a masonry
                                 band and the ident rides it as a textPath, so the label is drawn
                                 IN the cell wall (the owner: "drawing them properly in the cell
                                 wall") and can never detach from its body the way the old edge
                                 tab did when a cell pressed the frame. -->
                            <g class="wallwork" class:sunk={cell.sunk}>
                                <path id={arc_id(w, cell)} class="wallband" d={arc_d(w, cell)}></path>
                                <text class="wallname" data-ukey={cell.key}>
                                    <textPath href="#{arc_id(w, cell)}" startOffset="50%">{cell.ident}</textPath>
                                </text>
                                <!-- THE DETAILS SPILL FROM THE LABEL (2026-08-09, the owner: *"the way
                                     Radio cell has title,artist,of,at,skip etc in the background looks odd
                                     and messy — perhaps that label on the side of it should be the
                                     canonical thing, and spill the further details out of there"*).  They
                                     used to stack as a boxed hall in the middle of the cell, UNDER the
                                     component — a second, competing surface behind the living one, which
                                     is why it read as mess rather than as information.  Now they run as
                                     one line along a concentric arc just inside the name, so the wall band
                                     is the canonical label and everything else is visibly a continuation
                                     of it.  Joined with a middot and cut to the arc's own length: the
                                     wall decides how much detail there is room for, and a small cell
                                     simply says less. -->
                            </g>
                        {/if}
                    {/each}
                    <!-- the spill rides its OWN pass, gated on the CARVE and not on the face: it replaces
                         the boxed hall, and the hall never needed a face either.  Nested inside the
                         wallwork block it silently deleted every faceless carved cell's detail — the
                         capture caught it as labels dropping 14 → 7 with nothing put back. -->
                    <!-- BARE: the particle, set. -->
                    {#if bare_on(w)}
                        {#each viewport_cells(w) as cell (cell.key)}
                            {#if cell.kind === 'poly' && !cell.hasKids && !cell.departing && cell.r > 20}
                                {@const bs = bare_set(cell)}
                                {#if bs}
                                    <g class="bareset" class:sunk={cell.sunk} data-ukey={cell.key}
                                       transform="translate({cell.x.toFixed(1)},{cell.y.toFixed(1)}) scale({bs.k.toFixed(3)})">
                                        <text class="bare-title" x="0" y={-14 - bs.rows.length * 7.5}>{bs.title}</text>
                                        {#if bs.value}
                                            <text class="bare-value" x="0" y={2 - bs.rows.length * 7.5}>{bs.value}</text>
                                        {/if}
                                        {#each bs.rows as [rk, rv], ri (rk)}
                                            <text class="bare-key" x="-4" y={20 - bs.rows.length * 7.5 + ri * 15}>{rk}</text>
                                            <text class="bare-val" x="4" y={20 - bs.rows.length * 7.5 + ri * 15}>{rv}</text>
                                        {/each}
                                    </g>
                                {/if}
                            {/if}
                        {/each}
                    {/if}
                    {#each viewport_cells(w) as cell (cell.key)}
                        <!-- NOT UNDER FOCUS (the owner 2026-08-10: *"the Heist cell, and any of them,
                             don't want the seed,pub,state C** labels printed there"*).  The spill is
                             the cell's raw `sc` run along its wall — it earns its place in the foam,
                             where a small faceless cell has nothing else to say what it holds.  Under
                             focus every cell HAS a face, and that face is the considered account of
                             the same particle: the spill beside it is the unconsidered one, competing
                             with it in a different typeface.  Same family as the ⤢ and the toybox —
                             plumbing wearing the costume of information.
                             `carveable` is not the gate to use here: it reads `w.c.foam` directly
                             (not `layout`'s local `foam`, which focus already turns off), which is
                             exactly how this leaked into a regime it was never meant for.  The NAME
                             band keeps its carve — a cell still has to say which thing it is. -->
                        {#if cell.kind === 'poly' && !cell.hasKids && !cell.departing && wall_carve(w, cell) && !fo(w, 'nohall') && !focus_on(w)}
                            {@const sp = spill_of(cell)}
                            {#if sp}
                                <g class="wallwork" class:sunk={cell.sunk}>
                                    <path id="{arc_id(w, cell)}-s" class="wallspill-arc" d={sp.d}></path>
                                    <text class="wallspill" data-ukey={cell.key}>
                                        <textPath href="#{arc_id(w, cell)}-s" startOffset="50%">{sp.text}</textPath>
                                    </text>
                                </g>
                            {/if}
                        {/if}
                    {/each}
                    <!-- (THE TAIL used to be drawn here as its own path.  It is not drawn at all now —
                         it lives in the cell's own outline, spliced in by build_cells, which is what
                         makes it a soft blob instead of a hard triangle and what makes it incapable of
                         occluding anything.  A whole pass, a slider role, four pointer handlers, a
                         wheel handler and a hit pad all went away with it.) -->
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
                        <!-- `!bare_on(w)` is belt AND braces beside the null face `build_cells` gives a
                             bare cell: this gate reads the flag DIRECTLY, so it cannot be outvoted by a
                             stale cell list however the paint got behind.  A view switch must be
                             obeyable from the template alone. -->
                        <!-- …EXCEPT A POSED ONE, which is never below the floor by accident: a `small`
                             cell was ASSIGNED its size and its face already renders as an icon, so the
                             icon register has nothing left to do but hide the icon.  This is also the
                             half that closes the ratchet's trap door — an unmounted face can never be
                             re-measured, so "crushed" used to be a state a cell could not leave. -->
                        {#if cell.face && !bare_on(w) && !cell.departing && !cell.hasKids && (cell.fit > 0.34 || posed_cell(cell))}
                            {@const Face = cell.face}
                            <div class="face-mold" class:lift={cell.lift} class:sunk={cell.sunk}
                                 class:arrive={cell.fx === 'arrive'} class:erupt={cell.fx === 'erupt'} data-key={cell.key}
                                 use:lifetell={{ H, what: 'mold', id: cell.key }}
                                 style="left:{((cell.mx - cam.x) / cam.w) * 100}%; top:{((cell.my - cam.y) / cam.h) * 100}%; width:{(cell.mw / cam.w) * 100}%; height:{(cell.mh / cam.h) * 100}%; --fit:{cell.fit};{mold_seat(cell)}"
                                 onpointerenter={() => on_enter(w, cell.key, cell.tok)}
                                 onpointerleave={() => on_leave(w, cell.key, cell.tok)}>
                                <div class="face-scroll" class:stretch={stretch_cell(cell)} use:sizewatch>
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
                <!-- THE A DIALS ARE GONE (2026-08-10, the focus pivot: size is ASSIGNED by the
                     commission now, so a per-cell intensity thumb is a handle to nothing — and the
                     owner's ruling was total: *"all that I want GONE!"*.  `dose` stays a model fact
                     the commissioner writes; only the hand on it left). -->
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
    /* FULL BLEED, AND THE COPPER RUNS TO THE EDGE (2026-08-11, the owner: *"there's gaps around the
       Vyto glass we don't need"* / *"should be copperannodes background to the edge of the page"*).
       Four separate gaps were stacked here, each individually defensible and collectively a frame
       around a page that is supposed to BE the glass: a 4px margin, 6/8px of padding, a 1px border
       with a 6px radius, and a 68em max-width that gutter-boxed the whole thing on a wide screen.
       All four go.
       The copper is the same `/i/copper_anodes.jpg` the svg lays down as its `vy-cop-coarse` ground,
       at the same 520 scale, so the sheet the glass sits on and the ground inside it are one
       material.  That matters because the svg CANNOT reach all four edges by construction — it holds
       its viewBox aspect exactly (the `.depth` contract every mold percentage depends on), so any
       mismatch between the cut's aspect and the window's shows as a gutter.  Painting the same metal
       underneath turns that gutter from a hole in the page into more of the sheet. */
    .vyto {
        font: 12px/1.5 system-ui, sans-serif;
        color: #cfcfd8;
        /* …COOLED DOWN (the owner, on the first full-strength version: *"doesn't look sophisticated
           enough, needs cooling down"*).  A whole page of bright copper is a WALL — it competes with
           the glass instead of holding it, and at 520px the grain reads as blotchy pattern rather
           than as metal.  Three moves, none of which throws the material away:
             · the grain goes FINER (300px) — texture you read as surface, not as a repeat;
             · a cool near-black veil over it, so what survives is a warm GLINT rather than a hue;
             · a vignette, lighter under the belly and darkest at the corners, so the sheet recedes
                at the edges of the page and the lit thing in the middle is the glass.
           The dial is the two rgba alphas: lower them for more copper, raise them for less. */
        background-color: #6e4e2e;
        background-image:
            radial-gradient(135% 120% at 50% 42%, rgba(12, 15, 26, 0.82), rgba(4, 5, 10, 0.96) 72%),
            url(/i/copper_anodes.jpg);
        background-size: auto, 300px 300px;
        background-position: center, center;
        /* fill the hole the page gives us, and hold the glass in the middle of it.  `min-height`
           rather than `height` on purpose: against `.scape-glass` (a flex item with a definite
           height) it resolves and the sheet reaches the bottom of the page; in the sprawl the parent
           height is indefinite, so it computes to auto and that room is untouched. */
        min-height: 100%;
        display: flex; flex-direction: column; justify-content: center;
    }
    /* (.bar/.crest/.word/.organs-btn/.panel/.organ/.strip/.tick/.aspect-sel all went with the chrome
       they styled — 2026-08-11.  `.fs-btn` STAYS: ⛶ left but `.out-btn` wears the same class, and the
       walk-out ⤴ is navigation, not chrome.) */

    /* the viewport — the root scope, one cell per mirror row.  The frame follows the stage's aspect
       (fit_frame), so this is free to be any shape; fullscreen is just the biggest such shape.
       margin-top: 0 — there is nothing above the stage any more, and a 6px gap to nothing is 6px of
       the listener's screen. */
    .stage { position: relative; }
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
           percentage mold contract holds by construction.  --fw/--fh are stamped from vw_w/vw_h.
           THE CAP IS ALSO THE HEIGHT (2026-08-11): because the box holds the viewBox aspect exactly, this
           width limit is what decides how tall the glass renders — so it, not any `min-height`, is the
           dial the owner reached for.  82vh was sized to leave room for the bar, the moment strip and
           the organ panel; all three are gone, so the glass takes what they were holding.  Not 100vh:
           `.vyto` still had padding and a border, and a glass that touched the exact bottom of the
           viewport read as cut off rather than as full.  BOTH OF THOSE ARE NOW GONE (the full-bleed
           rule above), so the reason for holding 6vh back went with them: 100vh.  The cap has not
           become decorative — with the aspect floor at 0.5, a very wide window still asks for a frame
           taller than its hole, and this is what keeps that from overflowing. */
        max-width: calc(100vh * var(--fw, 800) / var(--fh, 450));
        margin-inline: auto;
    }
    /* no border, no radius, no ground colour of its own: the copper sheet behind it is the ground now,
       and a rounded 1px rule around the glass was the fourth of the gaps (it drew a card edge where
       the page is meant to run straight off the screen). */
    .viewport {
        display: block; width: 100%; height: auto;
    }
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
    /* THE RAIL IS DOWN TO ⛶ AND THE WALK-OUT (2026-08-10, the focus pivot — the toybox and its
       toys went with the gestures).  ⤴ shows only while somewhere to come out of exists. */
    .out-btn { right: 38px; }
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
        transition: fill 120ms ease, fill-opacity 260ms ease, stroke-opacity 260ms ease;
    }
    /* THE POOL DEPTH — sunken stuffing (nested, unapproached) rests at low ink; approaching its
       chain surfaces it (build_cells' near_key).  The 260ms rise IS the surfacing gesture. */
    .cell.sunk { fill-opacity: 0.5; stroke-opacity: 0.4; }
    /* the attention currency's visible trail: a HOT body (heat > 0.25 — recently navigated)
       carries a faint warm halo that fades as the currency taxes away. */
    .cell.hot { filter: drop-shadow(0 0 7px rgba(255, 216, 121, 0.33)); }
    .cell.disc { fill: #33334a; }
    .cell.departing { opacity: 0.35; }
    .cell.lift { fill: #3a3a58; stroke: #a8a8f0; }
    /* a faced cell is a quiet frame — the mounted face draws the content over it */
    .cell.faced { fill: #17171f; stroke: #3d3d55; }
    /* a crushed cell (face folded below the icon floor) must SAY so: dashed wall = "not empty, folded" */
    .cell.crushed { stroke-dasharray: 5 3; }
    /* the PEARL — a crushed cell's guaranteed small body: solid wall (the dash belongs to the outer
       poly), the ordinary cell ground, so the ⤢ always sits IN something instead of floating */
    .cell.pearl { fill: #23233a; stroke-dasharray: none; pointer-events: none; }
    /* the AWAIT RING — an empty live glass spins slowly instead of sitting blank */
    .await-spin {
        position: absolute; left: 50%; top: 50%; width: 46px; height: 46px; margin: -23px 0 0 -23px;
        border-radius: 50%; border: 2px solid rgba(159, 208, 255, 0.14);
        border-top-color: rgba(159, 208, 255, 0.65);
        animation: vyto-await 1.6s linear infinite; pointer-events: none; z-index: 4;
    }
    @keyframes vyto-await { to { transform: rotate(360deg); } }
    /* A PRESSABLE CELL IS A BUTTON — the one thing the tree could not say about itself.  A warm wall
       and a lift on hover; the affordance is the WALL because in a C** interface the wall is all a
       cell has that is reliably its own (the inside belongs to whatever is stated there). */
    .cell.pressy { stroke: #e0a04c; stroke-width: 1.9; }
    .cell.pressy:hover { stroke: #ffc978; filter: drop-shadow(0 0 6px rgba(224, 160, 76, 0.4)); }
    .cell.pressy:active { fill: #3a3040; }
    /* THE STAGED CELL — the one the human put on the left.  It needs no decoration to be found (it
       is half the screen); the mark is for the OTHERS' benefit — it says the deal is deliberate. */
    .cell.staged { stroke: #9fd0ff; stroke-width: 2.2; }
    /* THE SELF SEAT reads as the PARENT SHOWING THROUGH its own stuffing, never as a sibling of it.
       Geometrically it is one more body in the children's cut — it had to be, or the room would not
       be honestly divided — so everything that says "separate thing" has to come off: no wall of its
       own, and the scope's own quiet ground rather than a child's.  What is left is a shaped opening
       in the tiling, which is exactly what a parent still visible among its children looks like. */
    .cell.selfseat { stroke: none; fill: #14141c; }
    .cell.selfseat.pressy { stroke: none; }
    .cell.selfseat:hover { fill: #1a1a26; }
    /* the corner note.  pointer-events NONE on the strip and AUTO on the chips: the note must not eat
       presses meant for the cells it overlaps, but the one thing in it you can act on has to be live. */
    .unseated {
        position: absolute; left: 8px; bottom: 6px; z-index: 5; pointer-events: none;
        display: flex; flex-wrap: wrap; align-items: center; gap: 4px; max-width: 70%;
        font: 9px/1 ui-monospace, monospace; letter-spacing: 0.09em; text-transform: uppercase;
        color: rgba(190, 190, 220, 0.5);
    }
    .unseated-lede { opacity: 0.75; }
    .unseat-chip {
        pointer-events: auto; cursor: pointer;
        font: inherit; letter-spacing: inherit; text-transform: none;
        color: rgba(214, 214, 240, 0.85);
        background: rgba(20, 20, 30, 0.72);
        border: 1px solid rgba(140, 140, 180, 0.45);
        border-radius: 8px; padding: 2px 7px;
        max-width: 15ch; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
    }
    .unseat-chip:hover { color: #fff; background: rgba(52, 52, 74, 0.9); border-color: rgba(190, 190, 235, 0.8); }
    /* (.stageband went with the drag, 2026-08-10.) */
    /* THE LOOSE LAYER — drifters off the pile: dim, small, owing no wall.  Rim seats are static
       (tok-hashed) — a stir-clock drift was cut because rest_poll stirs in a loop; renderer-side
       drift waits on a <g> wrapper so a disc and its label revolve together. */
    .cell.disc.loose { opacity: 0.5; fill: #1c1c26; stroke: #33334a; }
    /* THE SATELLITES' PURPLE, as a RIM not a repaint (2026-08-10) — the "couple of purple somethings
       coming off it".  Stroke only, so the Matstyle swatch underneath is untouched and a sat is drawn
       the same way as every other cell, wearing one extra mark that says what it is. */
    .cell.sat { stroke: #9b6fc9 !important; stroke-width: 2; }
    /* transform-box makes scale animations (breath, dent) pivot each cell about its OWN centre */
    .cell { transform-box: fill-box; transform-origin: center; }
    /* THE BREATH — the orchestra's shared slow pulse, foam glasses on the live page only (the class
       is gated in the template).  CSS-driven: no rAF, no settle interference, the compositor plays it.
       --bd staggers phase per cell so the glass breathes as a body, not a metronome. */
    .cell.breathe { animation: vy-breathe 3.4s ease-in-out infinite; animation-delay: var(--bd, 0ms); }
    @keyframes vy-breathe { 50% { transform: scale(1.012); } }
    /* THE DENT — instant compositor acknowledgment of a press, long before the model answers.
       post_do latency is queue latency (the drain-lag electrode); the dent masks it honestly. */
    .cell:active { animation: vy-dent 140ms ease-out both; }
    @keyframes vy-dent { 30% { transform: scale(0.965); } 100% { transform: scale(1); } }
    @media (prefers-reduced-motion: reduce) { .cell.breathe { animation: none; } }
    /* NESTED (depth>0): a child wall reads finer than its container so the tree is legible; a
       SCOPE cell (its children tile it) is a bare frame — transparent fill, faint outline — so the
       children carry the ink.  Both ADD onto the flat look; a flat glass never emits either class. */
    .cell.nested { stroke-width: 0.7; }
    /* a SCOPE keeps its bare frame but gains a coarse copper FLOOR — the bag visibly holds its
       children on something, and (visiblePainted hit-testing) the floor makes the gaps between
       children clickable, so pressing a bag's background engages the bag. */
    .cell.scope { fill: url(#vy-cop-coarse); fill-opacity: 0.07; stroke: #4a4a66; }
    .cell.scope.lift { fill-opacity: 0.12; stroke: #a8a8f0; }

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
        /* SPILLING — the wall policy re-decided a THIRD time (the owner 2026-08-09 evening: "cells need
           occlusion ordering, html should always spill out").  History, so nobody relitigates blind:
           #4 chose overflow (clipping amputated content in cells cut too small) → THE PIN re-chose
           clipping once the NEED FLOOR removed that cause (faces were lying on top of each other) →
           and NOW spill returns, because the piling-up cause is gone a better way: build_cells' one
           occlusion sort ranks every cell and mold (small over big, child over parent, hover over all),
           so what spills lands UNDER anything smaller and more focused than itself instead of on top
           of everything.  Clip solved overlap by amputation; occlusion solves it by order. */
        overflow: visible;
        /* CHROME OFF (the owner: "centering the Player things is going to make it look better, and lose
           the border").  The seat ring + cast shadow made every face read as a bordered card in a cell;
           a centered, chromeless face reads as the cell's OWN body instead.  The lift used to keep a
           glow as the one exception — 2026-08-11 took that away too, so there is now no state in which
           a mold draws its own rectangle, and nothing left to transition. */
        transform-style: preserve-3d;
    }
    /* the lift's Z lives in mold_seat (z-index does not order inside a preserve-3d context); z-index is
       kept for browsers that flatten the 3D context, where it is still the only thing that can order. */
    /* NO CHROME ON THE MOLD AT ALL (the owner 2026-08-11: *"lets get rid of the sometimes-visible
       lavendar border that the components have when pointer is in them"*, then — of the cast shadow that
       was left — *"lose the shadow too - I want it to just be there"*).  It was an `inset 0 0 0 1px
       #a8a8f0` plus a drop shadow, and BOTH drew the MOLD's rectangle, which is not a shape the reader
       has any other evidence of: the cell is a blob and the face is chromeless inside it, so a hover
       produced a hard box agreeing with neither.  "Sometimes-visible" is exactly that mismatch, and the
       shadow had it too — softer, same rectangle.  The lift now changes NOTHING about the face; it is
       purely an ordering fact.  The hover is still said on the WALL (`.cell.lift`), which is the
       affordance in a C** glass (see `.cell.pressy`) and is a shape that actually exists. */
    .face-mold.lift { z-index: 5; }
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
        /* CENTERED + SPILLING (the owner: "centering the Player things is going to make it look
           better").  Flex centering means a face sits in the middle of its seat instead of hugging
           the top-left wall, and a face narrower than the seat SHRINKS TO ITS CONTENT (a flex item
           never box-stretches) — which also hands the measure pass an honest intrinsic box where the
           stretched one used to hide it.  overflow follows the mold's spill law: what does not fit
           lands under smaller cells, by the occlusion sort, not inside a scrollbar. */
        display: flex; align-items: center; justify-content: center;
        overflow: visible;
        font-size: 11px; line-height: 1.35;
        /* the pool: a sunken face dims + desaturates on this child (the mold's transform stays
           free for the seat); opacity/filter only, so surfacing costs no layout */
        transition: opacity 240ms ease, filter 240ms ease;
    }
    /* STRETCHED — the face fills the COLUMN it was assigned, not the room (see the stretch note in
       `layout`: the room is spent on ZOOM, because a face's type is hardcoded px and a wider box
       cannot make it bigger — it can only push its rows apart, which was the fullscreen defect).
       WIDTH is overridden because the face's own `width: max-content` + `max-width` cap is written
       for the fill economy and is wrong when the box was chosen FOR it.  HEIGHT deliberately is NOT:
       forcing it stretched the vertical rhythm the same way and stranded the content at the top of a
       tall box.  Natural height, centred by `.face-scroll`'s own alignment.
       `:global` because the child is another component's root, which Svelte's scoping cannot reach.
       Only ever on a cell the commissioner posed `stretched`; every other face is untouched. */
    .face-scroll.stretch > :global(*) {
        /* THE COLUMN IS ASSIGNED HERE, AND `--fit` CANCELS OUT OF IT (2026-08-11 — the flitting fix;
           the reasoning is at `mold_seat`'s --lay note).  This box lays out inside `.face-scroll`,
           which is `100% / --fit` wide, so a child at `--lay × --fit` of it is `--lay` of the MOLD in
           real units whatever the zoom does: fit cancels, and the face is finally measured at the
           column the search chose instead of at one the zoom moved underneath it.
           It stays a child width rather than a width on `.face-scroll` itself so the flex centring
           above still holds — a face narrower than its room sits in the middle of it, not against the
           left wall.  `--lay` is absent for every non-stretched face, so this is `100%` exactly as it
           was for them. */
        width: calc(100% * var(--lay, 1) * var(--fit, 1));
        max-width: none;
        /* NO SHADOW, SECOND AND LAST TIME (asked for 2026-08-11 — *"maybe the border could have a
           slight dropshadow, but very subtle"* — and withdrawn the same day: *"remove the Heist
           component dropshadow again"*).  The verdict either side of the experiment is the earlier
           one: *"I want it to just be there."*  A shadow is a claim that the face is floating above
           the cell, and it is not — it is seated IN it.  Left as a note rather than a line, so the
           next person reads that this was tried and rejected, not that it was never thought of. */
    }
    .face-mold.sunk .face-scroll { opacity: 0.35; filter: saturate(0.55) brightness(0.82); }
    .face-err {
        padding: 4px 6px; color: #d08a8a; font-weight: 600;
        font: 600 11px/1.3 system-ui, sans-serif;
    }
    .ident {
        fill: #e6e6f2; font: 600 14px/1 system-ui, sans-serif;   /* 14px legibility floor */
        pointer-events: none; user-select: none;
        transition: opacity 260ms ease;
    }
    /* sunken ink for names + labels — legible on approach, a murmur at rest */
    .ident.sunk { opacity: 0.22; }
    /* THE WAVE — chunky scalloped label covering; engaging the cell FOLDS it away, toppling in
       reverse about its own top edge.  The overshoot ease reads as the wave gathering before it
       goes.  pointer-events none: it covers, it never blocks. */
    .wave { transform-box: fill-box; transform-origin: center top; pointer-events: none;
            transition: transform 460ms cubic-bezier(0.6, -0.25, 0.3, 1), opacity 380ms ease; }
    .wave.folded { transform: scaleY(0.04); opacity: 0; }
    .wave.sunk { opacity: 0.25; }
    /* plain band — the copper grain read as grunge at label scale (the owner: "the copper annodes
       in the plain label part is invalid"); the metal stays on the ground, the hall and the seal,
       where it is worked at its own scale. */
    .waveband { fill: #16162a; fill-opacity: 0.55; stroke: #6a6ad0; stroke-width: 0.5; stroke-opacity: 0.28; }

    /* THE WALL CARVE — masonry band on the ball's upper arc, the name set along it, the A gate at
       its head.  Band and name are scenery (pointer-events none); the gate is the working part. */
    .wallwork { pointer-events: none; transition: opacity 260ms ease; }
    .wallwork.sunk { opacity: 0.3; }
    .wallband { fill: none; stroke: rgba(13, 13, 24, 0.55); stroke-width: 15; stroke-linecap: round; }
    /* the spill: a murmur beside the name, never competing with it — the name is the canonical label
       and these are its continuation, so they sit smaller, dimmer and unbanded (no masonry of their
       own; they ride the cell's own body). */
    /* THE BARE SETTING — three registers on one measure.  The mainkey is the title because it is what
       the thing IS; its value is the subject and carries the size; the supporting scalars are set as a
       key/value pair with the key quiet, spaced and right-ranged and the value holding the ink.  This
       is the whole of "no illusions about data representation": nothing here is a widget pretending to
       be a thing — it is the particle, stated, and set well. */
    .bareset { pointer-events: none; user-select: none; transition: opacity 260ms ease; }
    .bareset.sunk { opacity: 0.3; }
    .bare-title {
        fill: #8f8fb4; font: 600 9px/1 ui-monospace, monospace;
        letter-spacing: 0.22em; text-transform: uppercase; text-anchor: middle;
    }
    .bare-value {
        fill: #f2f2fa; font: 300 19px/1 ui-sans-serif, system-ui, sans-serif;
        letter-spacing: -0.01em; text-anchor: middle;
        paint-order: stroke; stroke: rgba(10, 10, 18, 0.6); stroke-width: 3px;
    }
    .bare-key {
        fill: #6f6f8c; font: 500 8.5px/1 ui-monospace, monospace;
        letter-spacing: 0.14em; text-anchor: end;
    }
    .bare-val {
        fill: #c9c9e2; font: 400 10.5px/1 ui-monospace, monospace; text-anchor: start;
    }
    .wallspill-arc { fill: none; stroke: none; }
    .wallspill {
        fill: #9a9ab8; font: 9px/1 ui-monospace, monospace; letter-spacing: 0.06em;
        paint-order: stroke; stroke: rgba(10, 10, 18, 0.7); stroke-width: 2.5px;
        pointer-events: none; user-select: none;
    }
    .wallname {
        font-size: 11.5px; font-weight: 600; letter-spacing: 0.14em;
        fill: #dcdcf2; dominant-baseline: middle;
        paint-order: stroke; stroke: rgba(10, 10, 18, 0.5); stroke-width: 2.5px;
        user-select: none;
    }
    /* (the .agate rules are GONE.  The tail has no styling of its own any more — it is part of the
       cell path, so it wears the cell's fill, stroke, hover, sink and occlusion rank by construction.
       That is the whole reason the blob looks right where the standalone triangle did not: a mark that
       shares an outline cannot drift out of agreement with the thing it belongs to.) */
    /* (.dosetip went with the tail's drag — there is no dose gesture on the glass any more.) */
    .wave .lab { fill: #dcdcf0; opacity: 0.8; }
    /* THE ORBIT — the loose constellation revolves about the frame heart (view-box origin), each
       member counter-rotating so its label stays upright while its body drifts.  Glacial on
       purpose: drift you notice only when you look away and back.  Live-page gated in the
       template; reduced-motion stills it. */
    .orbit.adrift { transform-box: view-box; transform-origin: 50% 50%; animation: vy-orbit 480s linear infinite; }
    .orbit.adrift .orbiter { transform-box: fill-box; transform-origin: center; animation: vy-orbit 480s linear infinite reverse; }
    @keyframes vy-orbit { to { transform: rotate(360deg); } }
    @media (prefers-reduced-motion: reduce) { .orbit.adrift, .orbit.adrift .orbiter { animation: none; } }
    /* THE UNDER-LAYER — the bare standard representation, SHADOWED OVER by the face shoved in on top
       (the human's words).  Low ink on purpose: on screen it should read as the machine showing through
       its own UI, not as a label competing with it.  In a `runner_shot --svg` capture the faces are
       simply absent, so this IS the picture — which is the whole point of drawing it. */
    .ident.under { fill: #8f8fb4; opacity: 0.5; font-weight: 600; }
    /* THE EDGE LABEL — the cell's name filed along its top side, in the margin the inscribed mold opened
       between the wall and the face.  Slightly brighter and tighter than the guts: it is the one thing
       that says WHICH of several same-kind cells this is (`Heist:10.Yara`), so it should read first. */
    .ident.under.lab { font: 600 11px/1 ui-monospace, SFMono-Regular, Menlo, monospace; fill: #a8a8cc; opacity: 0.62; letter-spacing: 0.2px; }
    /* THE GUTS — the particle's own scalars, spilled down the same margin as quiet standing matter.
       Monospace so the k/v columns line up down the stack and the eye can scan them. */
    .ident.under.sub { font: 500 9px/1 ui-monospace, SFMono-Regular, Menlo, monospace; fill: #7a7a9c; opacity: 0.42; }
    /* the crushed-cell mark: "folded, more inside" — pairs with .cell.crushed's dashed wall */
    .ident.crush { font-size: 15px; fill: #9a9ac8; opacity: 0.85; pointer-events: none; }
    /* THE GROUND — coarse copper under everything, barely there: the cells sit ON something. */
    .ground-tex { opacity: 0.055; pointer-events: none; }
    /* THE HALLWAY — the corridor let into the cell wall (fine copper, worked smaller than the
       ground), with the two receding rails that make it read as depth rather than a badge.
       All of it is scenery: pointer-events none, the A dial above is the part you touch. */
    .hall { pointer-events: none; transition: opacity 260ms ease; }
    .hall.sunk { opacity: 0.3; }
    .hallway { fill: url(#vy-cop-fine); fill-opacity: 0.13; stroke: #6a6ad0; stroke-width: 0.5; stroke-opacity: 0.3; }
    .hall-rail { fill: none; stroke: #8f8fb4; stroke-width: 0.4; opacity: 0.22; }
    /* (.adials / .dosea went with the dose gesture, 2026-08-10 — size is assigned now.) */
    .holds { margin-top: 6px; display: flex; flex-direction: column; gap: 1px; }
    .hold { display: flex; gap: 8px; align-items: baseline; color: #a8a8bc; }
    .hold.releasing { color: #77778c; font-style: italic; }
    .hold .hscope { min-width: 8em; color: #d8d8e8; }
    .hold .hchan  { min-width: 6em; color: #8a8aa0; }
    .hold .hstr   { min-width: 5em; color: #9a9ab0; }
    .hold .hby    { color: #66667a; }
</style>
