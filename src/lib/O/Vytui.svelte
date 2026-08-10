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

    // THE SMUGGLED PRESS (the owner 2026-08-09: "with click handlers smuggled in, so anything can
    //  basically be interacted with").  A posed particle carries `.c.press` (a ref — never encoded,
    //   exactly what .c is for); a cell whose SOURCE wears one is a button, whatever its mainkey.
    //    The handler is handed the source particle so a one-line .g handler can read and write it.
    //  Falls through to cam_engage for every press-less cell, so nothing that worked changes.
    function cell_click(w: TheC, cell: PaintCell) {
        // a click that ends a live drag is the HAND OPENING, not a press
        if (drag_ate_click) { drag_ate_click = false; return }
        // A PRESS IS REAL ATTENTION — the currency's big coin.  A press on a CRUSHED cell is bigger
        //  still: the ⤢ it wears is an offer to open it (the owner: *"that we can click to make that
        //   cell become a normal cell right?"*), and 0.3 of a purse cannot pay that even now that a
        //    full purse buys ×4.5 area.  So the offer sets its own price — one press, actually open.
        //  It is also self-taxing on everyone else in proportion (Vyto_attend_walk), so opening this
        //   one visibly closes the room for the others rather than inflating the whole glass.
        const crushed = !!cell.face && !cell.hasKids && cell.fit <= 0.34
        attend(w, cell.tok, crushed ? 0.85 : 0.3)
        const src: any = (cell.row.c as any)?.source_n
        // `.c.press` is the name; `.c.onclick` is the name people reach for (the owner did — "some of
        //  them have click handlers magically (C.c.onclick?)"), and a handler that silently does not
        //   fire because it was spelled the DOM way is a bad half hour for whoever wrote it.  Both work.
        const fn = src?.c?.press ?? src?.c?.onclick
        if (typeof fn === 'function') {
            try { fn(src) } catch (e) { console.warn('◈ Vyto press threw', cell.ident, e) }
            return
        }
        cam_engage(w, cell)
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

    // THE A (the owner 2026-08-09: "cells could do with a handle... an A on one corner of it
    //  somewhere, which can drag up-down to control the intensity|size of that cell").  dose is
    //   ALREADY the pressure law's loudness input (Vyto_express: env_area = AREA_BASE·(1+dose)),
    //    so the dial invents nothing — it hands the human the same knob the model reads, and the
    //     foam re-negotiates around their thumb.  Which is the honest cure for "it gets the wrong
    //      thing fullfaced sometimes": not a smarter guess — a handle.
    //  Writes land on the SOURCE particle (the mirror is rebuilt from it every scan, so a mirror
    //   write would be overwritten next stir); dose is deleted at zero, never set '0' (the
    //    snapped-boolean law's cousin: absence is the clean off).  Throttled ~90ms — every write
    //     is a real stir→solve — and the springs glide between writes anyway.
    //  $state so the drag can show a live readout (the dosetip) — the one render fact here.
    let dosing: { src: any, w: TheC, y0: number, d0: number, lastT: number } | null = $state(null)
    function dose_src(cell: PaintCell): any { return (cell.row.c as any)?.source_n ?? cell.source ?? cell.row }
    function dose_down(e: PointerEvent, w: TheC, cell: PaintCell) {
        const src = dose_src(cell); if (!src) return
        dosing = { src, w, y0: e.clientY, d0: Number(src.sc?.dose) || 0, lastT: 0 }
        ;(e.currentTarget as Element).setPointerCapture?.(e.pointerId)
        e.stopPropagation(); e.preventDefault()
    }
    function dose_move(e: PointerEvent) {
        if (!dosing) return
        const now = performance.now()
        if (now - dosing.lastT < 90) return
        dosing.lastT = now
        dose_write(dosing.src, dosing.w, dosing.d0 + (dosing.y0 - e.clientY) / 56)
    }
    function dose_up(e: PointerEvent) {
        if (!dosing) return
        dose_write(dosing.src, dosing.w, dosing.d0 + (dosing.y0 - e.clientY) / 56)
        dosing = null
    }
    function dose_key(e: KeyboardEvent, w: TheC, cell: PaintCell) {
        if (e.key !== 'ArrowUp' && e.key !== 'ArrowDown') return
        e.preventDefault(); e.stopPropagation()
        const src = dose_src(cell); if (!src) return
        dose_write(src, w, (Number(src.sc?.dose) || 0) + (e.key === 'ArrowUp' ? 0.2 : -0.2))
    }
    function dose_write(src: any, w: TheC, nd: number) {
        nd = Math.max(0, Math.min(9, Math.round(nd * 10) / 10))
        const v = nd < 0.05 ? undefined : String(nd)
        const cur = src.sc?.dose
        if (v === undefined) { if (cur === undefined) return; delete src.sc.dose }
        else { if (cur === v) return; src.sc.dose = v }
        if (src.bump_version) src.bump_version(); else src.bump?.()
        ;(H as any).Vyto_stir_soon?.(w)
    }
    // the third hand on the same knob: a wheel tick over the A nudges dose ±0.1 — drag for a
    //  sweep, wheel for a trim, arrows for no-pointer.  All three land in dose_write.
    function dose_wheel(e: WheelEvent, w: TheC, cell: PaintCell) {
        const src = dose_src(cell); if (!src) return
        e.preventDefault(); e.stopPropagation()
        dose_write(src, w, (Number(src.sc?.dose) || 0) + (e.deltaY < 0 ? 0.1 : -0.1))
    }

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
    function bare_toggle(w: TheC) {
        if (bare.has(w)) bare.delete(w)
        else bare.add(w)
        bare_flip++
        ;(H as any).Vyto_stir_soon?.(w)
    }
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

    // ── GRAB A BALL (the fun law, 2026-08-09: "nothing is fun to interact with").  Drag a
    //  foam cell and the pile renegotiates around your thumb: the drag writes the mirror row's
    //   seed (solver state) and w.c.drag_tok (the solve pins a grabbed body while the hand
    //    holds it), poking a stir per ~70ms; release clears the pin and gravity rolls the ball
    //     back into the press — the toy IS the physics.  A real drag only begins past 6px, so
    //      clicks stay clicks (drag_ate_click eats the click that follows a live drag).
    //       Live pages only; a Book never sets drag_tok, so no fixture can feel this. ──
    let dragging: { w: TheC, cell: PaintCell, x0: number, y0: number, live: boolean, lastT: number } | null = null
    let drag_ate_click = false
    function cell_grab(e: PointerEvent, w: TheC, cell: PaintCell) {
        if (!live_page() || fo(w, 'still') || cell.hasKids || cell.departing) return   // grab balls, not bags
        dragging = { w, cell, x0: e.clientX, y0: e.clientY, live: false, lastT: 0 }
        ;(e.currentTarget as Element).setPointerCapture?.(e.pointerId)
    }
    function cell_drag(e: PointerEvent) {
        if (!dragging) return
        if (!dragging.live && Math.hypot(e.clientX - dragging.x0, e.clientY - dragging.y0) < 6) return
        dragging.live = true
        if (!drag_live) drag_live = 1
        const now = performance.now()
        if (now - dragging.lastT < 70) return
        dragging.lastT = now
        drag_write(e)
    }
    function drag_write(e: PointerEvent) {
        if (!dragging) return
        const { w, cell } = dragging
        const stage = stageEls.get(w); if (!stage) return
        const svg = stage.querySelector('svg.viewport') as SVGSVGElement | null; if (!svg) return
        const bb = svg.getBoundingClientRect()
        if (!(bb.width > 0) || !(bb.height > 0)) return
        const c = cam_view(w)
        const px = c.x + ((e.clientX - bb.left) / bb.width) * c.w
        const py = c.y + ((e.clientY - bb.top) / bb.height) * c.h
        ;(cell.row.c as any).seed = { x: px, y: py }
        ;(w.c as any).drag_tok = cell.tok
        ;(H as any).Vyto_stir_soon?.(w)
    }
    // ── THE STAGE BAND (the owner 2026-08-09: "perhaps whatever's on the left of the screen becomes
    //  larger, and you drag cells over there to become the big ones... whatever was there falls out
    //   of the way").  The left 40% of the viewport is a DROP TARGET, not a region the solve happens
    //    to fill: release a dragged cell in it and Vyto_stage deals the frame around that cell.
    //  Drop the staged cell there again to clear — one gesture, on and off, no second control.
    const STAGE_BAND = 0.4
    let drag_live = $state(0)          // 1 while a real drag is in flight — lights the band
    function in_stage_band(w: TheC, e: PointerEvent): boolean {
        const stage = stageEls.get(w); if (!stage) return false
        const svg = stage.querySelector('svg.viewport') as SVGSVGElement | null; if (!svg) return false
        const bb = svg.getBoundingClientRect()
        if (!(bb.width > 0)) return false
        return (e.clientX - bb.left) / bb.width < STAGE_BAND
    }
    function staged_tok(w: TheC): string | null { void paint_tick; return ((w.c as any).stage_tok ?? null) }
    // IS THERE ANYTHING TO COME BACK FROM?  Every emphasis verb the glass has is one-way — attend buys
    //  heat, focus stands a tok, stage deals the frame — and none of them has an undo that means "share
    //   it out again" (attending something else is a different bias, not a release).  `Vyto_release` is
    //    that verb; this is the predicate that decides whether to offer it, so the control exists exactly
    //     as long as there is something for it to do.  Read off the paint — heat already rides `row.c`
    //      and the cells are already in hand — so offering it costs no extra walk of the model.
    function emphasised(w: TheC): boolean {
        void paint_tick
        if ((w.c as any).stage_tok || (w.c as any).focus_tok) return true
        for (const c of viewport_cells(w)) if ((((c.row.c as any).heat) ?? 0) > 0.02) return true
        return false
    }
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

    // ── THE CLUTTER KNOB ──────────────────────────────────────────────────────────────────────
    //  The junk queue is minted by the COMMISSIONER (Sounditron_junk), not by the glass — the glass
    //   must never invent particles, that is the whole seam.  So the knob writes to the client
    //    world the commission came from and lets the next trickle re-commission; the count is one
    //     scalar the fabricator reads, which is why the button can be this small.
    // THE TOYBOX LATCH — per-tab, runtime, never snapped.  Everything on the rail except ⋯ and the
    //  walk-out chip hangs off it: those controls are how I look at the glass, not how anyone uses it.
    const toys = new Set<TheC>()
    let toys_flip = $state(0)
    function toys_on(w: TheC): boolean { void toys_flip; return toys.has(w) }
    function toys_toggle(w: TheC) {
        if (toys.has(w)) toys.delete(w)
        else toys.add(w)
        toys_flip++
    }
    let junk_flip = $state(0)
    function junk_world(w: TheC): any { return (w.c as any)?.commission?.sc?.client_w ?? null }
    function junk_n(w: TheC): number { void junk_flip; void paint_tick; return Number(junk_world(w)?.c?.junk) || 0 }
    function junk_cycle(w: TheC) {
        const cw = junk_world(w); if (!cw) return
        const now = Number(cw.c.junk) || 0
        // off → 6 → 12 → 24 → off.  A boolean would answer "does it cope"; a ladder answers "where
        //  does it stop coping", which is the only version of that question worth asking.
        const next = now === 0 ? 6 : (now === 6 ? 12 : (now === 12 ? 24 : 0))
        if (next === 0) delete cw.c.junk
        if (next !== 0) cw.c.junk = next
        junk_flip++
        // RE-COMMISSION THROUGH THE STASHED RUN, not through H.  Sounditron's verbs are bound to its
        //  own run-House; the top House stashes that binding as `c.sounditron_run` precisely so a
        //   gesture can re-commission with the correct `this` (the same trick the ⇊ keep gesture
        //    uses).  Calling it off H would find nothing and the knob would look dead until the next
        //     trickle happened to come round — which is indistinguishable from a broken button.
        const run: any = (H as any)?.top_House?.()?.c?.sounditron_run ?? (H as any)?.c?.sounditron_run
        run?.Sounditron_commission?.(cw)
        ;(H as any).Vyto_stir_soon?.(w)
    }
    function cell_release(e: PointerEvent) {
        if (!dragging) return
        if (dragging.live) {
            const { w, cell } = dragging
            drag_write(e)
            ;(w.c as any).drag_tok = null
            // ORDER MATTERS: clear drag_tok first (it pins the body for the hand), then stage, then
            //  one stir.  Staging before the clear would leave the cell pinned twice and the stage
            //   deal fighting the thumb pin for the same seed.
            if (in_stage_band(w, e)) (H as any).Vyto_stage?.(w, cell.tok)
            ;(H as any).Vyto_stir_soon?.(w)
            drag_ate_click = true
        }
        dragging = null
        drag_live = 0
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
    // 16:9 is the DEFAULT pick (the owner 2026-08-09) — the glass boots into the shape it was designed
    //  in (800×450 is the model's literal solve frame) instead of whatever letterbox the page happens to
    //   leave.  'auto' stays in the list as the opt-back-in for measuring the hole.
    let aspect_pick = $state('16:9')
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
    function mold_seat(cell: PaintCell): string {
        const rot = cell.ang ? ` rotate(${(cell.ang * 180 / Math.PI).toFixed(1)}deg)` : ''
        // THE OCCLUSION RANK — build_cells' one sort, expressed in Z.  No `perspective` is set
        //  anywhere on the stage, so a translateZ inside `.depth`'s preserve-3d changes STACKING
        //   ONLY (never size): 0.02px per rank keeps molds in the same big-under-small order as
        //    their SVG cells, and the 12px hover lift outranks every rank step by construction.
        const z = cell.lift ? ' translateZ(12px)' : ` translateZ(${((cell.zi ?? 0) * 0.02).toFixed(2)}px)`
        return ` transform:${rot}${z};`
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
            const seatR = seat_on(w)
            const foam = !!(w.c as any).foam && !seatR
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
            const seated = seatR ? 0 : frame_seat(seeds, framePoly, SEAT_MIN)
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
            if (seatR) {
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
                const ident = ident_of(row, w, n.tok)
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
                    if (!hasKids0 && face && foam && s.r > 8 && nw && nh) {
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
                        fit = Number.isFinite(byray) ? byray : Math.min(diag / hyp, bb.bw / nw, bb.bh / nh)
                        fit = Math.max(0.2, Math.min(FIT_MAX, +fit.toFixed(3)))
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
                            fit = Math.max(0.2, Math.min(FIT_MAX, +fit.toFixed(3)))
                            mw = nw * fit; mh = nh * fit
                            mx = seat.cx - mw / 2; my = seat.cy - mh / 2
                            ang = +th.toFixed(3)
                        } else {
                            clipPoly = clip_of(poly, bb)
                            // one uniform scale to fill the AABB seat — stretches UP into a roomy cell
                            //  and envelopes DOWN into a crushed one, same rule.
                            if (nw && nh && bb.bw > 0 && bb.bh > 0) {
                                fit = Math.min(bb.bw / nw, bb.bh / nh)
                                fit = Math.max(0.2, Math.min(FIT_MAX, +fit.toFixed(3)))
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
                    cells.push({ tok: n.tok, key: n.key, depth: n.depth, hasKids, ident, spike: sp,
                                 x: s.x, y: s.y, r: s.r, kind: 'poly', d: path_round(sp ? sp.poly : poly), departing: false, lift,
                                 bx: bb.bx, by: bb.by, bw: bb.bw, bh: bb.bh,
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
        for (const t of stage.querySelectorAll('text.ident:not(.under):not(.crush)')) {
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
                <!-- THE STAGE BAND, shown only while a drag is live.  A drop target you cannot see is
                     not a target, and one you can always see is furniture — so it exists exactly as
                     long as the gesture that can use it.  pointer-events:none, so it never eats the
                     drop it is advertising. -->
                {#if drag_live}
                    <div class="stageband" style="width:{(STAGE_BAND * 100).toFixed(0)}%">
                        <span>{staged_tok(w) ? 'drop to swap · drop the staged one to clear' : 'drop here to stage'}</span>
                    </div>
                {/if}
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
                <button class="fs-btn" onclick={(e) => go_fullscreen(e.currentTarget.parentElement)}
                        title="fullscreen the glass">⛶</button>
                <!-- THE TOYBOX (the owner 2026-08-09: *"we have to put most of this junk behind some
                     kind of hidden button ... that lets you play with more buttons"*).  Seven
                     always-on controls is a workbench, not an interface — and every one of them is a
                     thing I added to look at the glass with, not a thing a listener needs.  So one
                     nearly-invisible ⋯ opens the lot and nothing else shows by default.  Per-tab
                     runtime state: a Book never opens it, so no fixture can move on it. -->
                {#if live_page()}
                    <button class="fs-btn toy-btn" class:posing={toys_on(w)} onclick={() => toys_toggle(w)}
                            title={toys_on(w) ? 'hide the layout toys' : 'layout toys'}>⋯</button>
                    <!-- THE WAY OFF THE STAGE (the owner: *"that should be escapable via some
                         button"*).  A staged cell is huge and runs off the frame, so the gesture that
                         made it — drag it back — is the one gesture that is now awkward: there is
                         nowhere to grab and nowhere to drop it.  A stage you can enter and not leave
                         is a trap, so the escape is plain, outside the toybox, and shows only while
                         there is something to escape from. -->
                    {#if staged_tok(w)}
                        <button class="fs-btn unstage-btn" onclick={() => (H as any).Vyto_stage?.(w, staged_tok(w))}
                                title="off the stage — back to the ordinary pile">⤫</button>
                    {/if}
                    <!-- BACK TO TOP (the owner 2026-08-09: *"or at least have some back-to-top thing"*).
                         Deliberately NOT a second unstage: ⤫ above is the precise verb (this one cell,
                         off the stage, trail intact) and this is the general one — every emphasis
                         dropped at once, which is what someone who has pressed their way into a corner
                         actually wants.  They overlap only when the stage is the sole thing standing,
                         and there the two agree.  Shows only while something stands, so the rail is
                         unchanged for a reader who has not navigated at all. -->
                    {#if emphasised(w)}
                        <button class="fs-btn release-btn" onclick={() => (H as any).Vyto_release?.(w)}
                                title="share it out again — drop every emphasis and let the pile settle even">⇱</button>
                    {/if}
                {/if}
                {#if live_page() && toys_on(w)}
                    <button class="fs-btn sim-btn" class:simmering={simmer_on(w)} onclick={() => simmer_toggle(w)}
                            title="keep running layout — the foam keeps negotiating">∿</button>
                    <!-- BARE — the glass with no Components at all: just the cellular tree of what is
                         actually in there, its names, its details along the wall, and whatever a
                         particle made clickable.  Live pages only: a Book must never see a view
                         preference, so no fixture can move on whatever a human left toggled. -->
                    <button class="fs-btn even-btn" class:posing={even_on(w)} onclick={() => even_toggle(w)}
                            title="equal pose — every cell priced the same, so the structure shows">≡</button>
                    <button class="fs-btn vie-btn" class:posing={compete_on(w)} onclick={() => compete_toggle(w)}
                            title="compete for attention — the coin goes round and the foam fights it out">⚔</button>
                    <button class="fs-btn bare-btn" class:baring={bare_on(w)} onclick={() => bare_toggle(w)}
                            title={bare_on(w) ? 'components off — cells only (click to bring them back)'
                                              : 'try it bare — no Components, just the cellular tree'}>▢</button>
                    <!-- THE CLUTTER KNOB — fabricate a queue of faceless heist jobs, each holding its
                         cuts as SUBCELLS, so the crowded regime can actually be looked at.  Cycles
                         off → 6 → 12 → 24 → off; the real organs keep their faces throughout. -->
                    <button class="fs-btn junk-btn" class:posing={junk_n(w) > 0} onclick={() => junk_cycle(w)}
                            title="fabricate a cluttered heist queue (faceless, with subcells) — off · 6 · 12 · 24">⧉{junk_n(w) || ''}</button>
                    <!-- the LAYOUT HANDS (the owner: "needs more redraw or keep running layout buttons
                         like cyto had").  ⟳ deals the pile fresh (Vyto_redraw — every unpinned seat
                         forgets, re-enters round the rim, re-piles, salted per press). -->
                    <button class="fs-btn re-btn" onclick={() => (H as any).Vyto_redraw?.(w)}
                            title="redraw — deal the pile fresh">⟳</button>
                {/if}
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
                            <!-- a DOSED wall is a PRESSED wall: stroke weight rides the dose, so the
                                 A-drag answers under the thumb before the solve even lands. -->
                            <path class="cell" class:departing={cell.departing} class:lift={cell.lift} class:sunk={cell.sunk}
                                  class:faced={!!cell.face && !cell.hasKids} class:nested={cell.depth > 0} class:scope={cell.hasKids}
                                  class:crushed={!!cell.face && !cell.hasKids && cell.fit <= 0.34}
                                  class:breathe={cell.fx === '' && foam_breathes(w)}
                                  class:hot={((cell.row.c as any).heat ?? 0) > 0.25}
                                  class:pressy={pressy(cell)} class:staged={cell.tok === staged_tok(w)}
                                  class:selfseat={cell.selfseat}
                                  class:arrive={cell.fx === 'arrive'} class:erupt={cell.fx === 'erupt'} d={cell.d}
                                  style={(g ? `fill:${g.bg}; stroke:${g.border};` : '') + (cdv > 0 ? ` stroke-width:${(1.2 + Math.min(3, cdv) * 0.55).toFixed(2)};` : '') + (cell.fx === 'arrive' ? ` animation-delay:${cell.fxi * 55}ms;` : ` --bd:-${ci * 430}ms;`)}
                                  onpointerenter={() => on_enter(w, cell.key, cell.tok)}
                                  onpointerleave={() => on_leave(w, cell.key, cell.tok)}
                                  onpointerdown={(e) => cell_grab(e, w, cell)}
                                  onpointermove={cell_drag} onpointerup={cell_release} onpointercancel={cell_release}
                                  onclick={() => cell_click(w, cell)}
                                  onfocus={() => attend(w, cell.tok, 0.08)}
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
                            {#if cell.fit <= 0.34}
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
                        {#if cell.kind === 'poly' && !cell.hasKids && !cell.departing && wall_carve(w, cell) && !fo(w, 'nohall')}
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
                        {#if cell.face && !cell.departing && !cell.hasKids && cell.fit > 0.34}
                            {@const Face = cell.face}
                            <div class="face-mold" class:lift={cell.lift} class:sunk={cell.sunk}
                                 class:arrive={cell.fx === 'arrive'} class:erupt={cell.fx === 'erupt'} data-key={cell.key}
                                 use:lifetell={{ H, what: 'mold', id: cell.key }}
                                 style="left:{((cell.mx - cam.x) / cam.w) * 100}%; top:{((cell.my - cam.y) / cam.h) * 100}%; width:{(cell.mw / cam.w) * 100}%; height:{(cell.mh / cam.h) * 100}%; --fit:{cell.fit};{mold_seat(cell)}"
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
                <!-- THE A DIALS (the owner 2026-08-09: "cells could do with a handle... an A on one
                     corner of it somewhere, which can drag up-down to control the intensity|size of
                     that cell").  HTML, in a plane translateZ'd above every mold: a handle that a
                     spilling face could bury would not be a handle.  Fixed PIXEL size on purpose —
                     the camera zooms the world, but a thumb-target should stay a thumb-target.
                     Anchored at the head of the cell's hallway; drag maps clientY straight to dose,
                     so no viewBox math is ever needed mid-gesture. -->
                <div class="adials">
                    {#each viewport_cells(w) as cell (cell.key)}
                        <!-- the SEAL is now the fallback hand: worlds that can't carve (no ball law)
                             and composers who pulled `seal` on the foamereo get the round HTML thumb;
                             carved worlds wear the A gate in the wall instead. -->
                        {#if cell.kind === 'poly' && !cell.hasKids && !cell.departing && cell.bw > 18 && cell.bh > 24 && (!wall_carve(w, cell) || fo(w, 'seal'))}
                            {@const dv = Number((dose_src(cell)?.sc as any)?.dose) || 0}
                            <!-- on a foam ball the bbox corner is off the disc (a circle never reaches
                                 its corner — the detached-hall lesson): seat the seal at the 205° wall
                                 mark instead, where the gate would stand. -->
                            <!-- `arc_pt` ray-hits the POLYGON, so it lands on the wall of any foam cell,
                                 carved or not — the bbox corner is only the right seat where the cell
                                 actually reaches it, which is the non-ball worlds. -->
                            {@const sp = carveable(w) ? arc_pt(cell, 205) : { x: cell.bx + 8, y: cell.by + 14.5 }}
                            <div class="dosea" class:doped={dv > 0} class:sunk={cell.sunk} role="slider" tabindex="0"
                                 aria-label={`intensity of ${cell.ident}`}
                                 aria-valuenow={dv} aria-valuemin={0} aria-valuemax={9}
                                 style="left:{((sp.x - cam.x) / cam.w) * 100}%; top:{((sp.y - cam.y) / cam.h) * 100}%;"
                                 onpointerdown={(e) => dose_down(e, w, cell)}
                                 onpointermove={dose_move} onpointerup={dose_up} onpointercancel={dose_up}
                                 onkeydown={(e) => dose_key(e, w, cell)}>
                                <svg viewBox="-10 -10 20 20" aria-hidden="true">
                                    <path class="dosea-A" d="M -3.2,3.8 L 0,-4.4 L 3.2,3.8 M -1.9,1.1 L 1.9,1.1"></path>
                                    <path class="dosea-chev" d="M -2.6,-6.4 L 0,-8.7 L 2.6,-6.4"></path>
                                    <path class="dosea-chev" d="M -2.6,6.6 L 0,8.9 L 2.6,6.6"></path>
                                </svg>
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
    /* THE RAIL, left of ⛶ (right:6px).  ⋯ is the only always-on member and it is deliberately faint:
       a listener should be able to look straight past it, and anyone hunting for controls finds it
       on the first hover.  Everything after it exists only while the toybox is open. */
    .toy-btn { right: 38px; opacity: 0.28; }
    .toy-btn:hover, .toy-btn.posing { opacity: 1; }
    .toy-btn.posing { color: #c3b0ff; border-color: #6a5ad0; background: #201c34; }
    .sim-btn { right: 70px; }
    .sim-btn.simmering { color: #ffd479; border-color: #b89a4a; background: #2c2618; }
    .even-btn { right: 102px; }
    .vie-btn  { right: 134px; }
    .bare-btn { right: 166px; }
    .junk-btn { right: 198px; min-width: 28px; }
    .re-btn   { right: 236px; }
    .even-btn.posing, .vie-btn.posing, .junk-btn.posing { color: #c3b0ff; border-color: #6a5ad0; background: #201c34; }
    .bare-btn.baring { color: #9fe6c8; border-color: #4a8a72; background: #16241f; }
    /* the walk-out chip is NAVIGATION, not a toy — it shows whenever there is somewhere to come out
       of, toybox open or shut, so a human who flew into a cell is never stranded.  It therefore sits
       at the head of the rail (right of ⋯), where it does not move as toys come and go. */
    .out-btn { right: 268px; }
    /* the escape sits at the head of the rail beside ⋯ — it is not a toy, and it must be findable
       without opening anything, because the stage it undoes covers most of the screen. */
    .unstage-btn { right: 300px; color: #9fd0ff; border-color: #4a6a8a; }
    /* back-to-top rides at the head of the rail, past the escape: it is the most general way out and
       the one that should still be findable when everything else on the rail is hidden. */
    .release-btn { right: 332px; color: #9fe6c8; border-color: #4a8a72; }
    @media (pointer: coarse) {
        .toy-btn { right: 52px; } .sim-btn { right: 98px; }
        .even-btn { right: 144px; } .vie-btn { right: 190px; } .bare-btn { right: 236px; }
        .junk-btn { right: 282px; } .re-btn { right: 328px; } .out-btn { right: 374px; }
        .unstage-btn { right: 420px; } .release-btn { right: 466px; }
    }
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
    .stageband {
        position: absolute; left: 0; top: 0; bottom: 0; z-index: 6; pointer-events: none;
        border-right: 1px dashed rgba(159, 208, 255, 0.55);
        background: linear-gradient(90deg, rgba(159, 208, 255, 0.13), rgba(159, 208, 255, 0.03));
        display: flex; align-items: flex-end; justify-content: center; padding-bottom: 10px;
    }
    .stageband span {
        font: 10px/1 ui-monospace, monospace; letter-spacing: 0.1em; text-transform: uppercase;
        color: rgba(200, 226, 255, 0.8); background: rgba(10, 12, 20, 0.6); padding: 4px 8px; border-radius: 3px;
    }
    /* THE LOOSE LAYER — drifters off the pile: dim, small, owing no wall.  Rim seats are static
       (tok-hashed) — a stir-clock drift was cut because rest_poll stirs in a loop; renderer-side
       drift waits on a <g> wrapper so a disc and its label revolve together. */
    .cell.disc.loose { opacity: 0.5; fill: #1c1c26; stroke: #33334a; }
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
           a centered, chromeless face reads as the cell's OWN body instead.  The lift keeps its glow —
           that one is information (hover top-mostity), not upholstery. */
        transform-style: preserve-3d;
        transition: box-shadow 140ms ease-out;
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
    /* THE A DIALS — the handle layer.  translateZ above every mold's occlusion rank AND the 12px
       hover lift: a handle that can be buried is not a handle.  The container never catches a
       pointer; each dial re-arms (same law as the face buttons). */
    .adials { position: absolute; inset: 0; pointer-events: none; transform: translateZ(30px); }
    .dosea {
        position: absolute; width: 19px; height: 19px; transform: translate(-50%, -50%);
        pointer-events: auto; touch-action: none; cursor: ns-resize;
        border-radius: 50%;
        /* the third copper scale — the dial is the smallest worked piece of the same metal */
        background: #262640 url('/i/copper_anodes.jpg') center / 90px;
        background-blend-mode: soft-light;
        box-shadow: inset 0 0 0 1px #8a8ac0, 0 1px 4px rgba(0, 0, 0, 0.45);
        opacity: 0.55; transition: opacity 120ms ease, box-shadow 120ms ease;
    }
    .dosea.sunk { opacity: 0.18; }
    .dosea:hover, .dosea:focus-visible { opacity: 1; box-shadow: inset 0 0 0 1px #c8c8f4, 0 2px 8px rgba(0, 0, 0, 0.55); }
    .dosea.doped { opacity: 0.9; box-shadow: inset 0 0 0 1.4px #b8a878, 0 1px 5px rgba(0, 0, 0, 0.5); }
    .dosea svg { display: block; width: 100%; height: 100%; }
    .dosea-A { fill: none; stroke: #e6e6f2; stroke-width: 1.2; stroke-linecap: round; stroke-linejoin: round; }
    .dosea-chev { fill: none; stroke: #a8a8f0; stroke-width: 1; stroke-linecap: round; opacity: 0; transition: opacity 120ms ease; }
    .dosea:hover .dosea-chev, .dosea:focus-visible .dosea-chev { opacity: 0.85; }
    @media (pointer: coarse) { .dosea { width: 26px; height: 26px; } }
    .holds { margin-top: 6px; display: flex; flex-direction: column; gap: 1px; }
    .hold { display: flex; gap: 8px; align-items: baseline; color: #a8a8bc; }
    .hold.releasing { color: #77778c; font-style: italic; }
    .hold .hscope { min-width: 8em; color: #d8d8e8; }
    .hold .hchan  { min-width: 6em; color: #8a8aa0; }
    .hold .hstr   { min-width: 5em; color: #9a9ab0; }
    .hold .hby    { color: #66667a; }
</style>
