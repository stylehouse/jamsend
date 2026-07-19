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

    let { H } = $props()

    // the glass worlds on this House — A:Vyto > w:Vyto (the A:Cyto precedent).  ob() reads
    //  vers so the walk re-runs when worlds arrive; called from the template, never from a
    //   construction $effect (the Otro H-effect lesson).
    function vyto_worlds(): TheC[] {
        if (!H) return []
        const out: TheC[] = []
        for (const A of H.ob({ A: 'Vyto' }) as TheC[])
            for (const w of A.ob({ w: 'Vyto' }) as TheC[]) out.push(w)
        return out
    }

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
    const FRAME: Pt[] = [{ x: 0, y: 0 }, { x: 800, y: 0 }, { x: 800, y: 450 }, { x: 0, y: 450 }]
    const EPS = 0.5           // settle displacement floor, px (calm.md §6)
    const DRIFT_EPS = 0.25    // settle wall-vertex drift floor, px/frame
    const SETTLE_FRAMES = 8   // consecutive calm frames before a settle strikes (~130ms @60fps)
    const GAP = 2.2           // the breath between cells (shapes.md §0)

    type Spring = { x: number, y: number, r: number, vx: number, vy: number, vr: number }
    type PaintCell = { tok: string, ident: string, x: number, y: number, r: number,
                       kind: 'poly' | 'disc', d: string, departing: boolean, lift: boolean }

    // per-world render state, keyed by the world C — plain, not reactive.
    const springs      = new Map<TheC, Map<string, Spring>>()   // tok → sprung scalars
    const prevWalls    = new Map<TheC, Map<string, Pt[]>>()      // last frame's polys, for drift
    const settleCount  = new Map<TheC, number>()                 // consecutive calm frames
    const settledState = new Map<TheC, boolean>()                // struck-this-rest latch
    const lifted       = new Map<TheC, string>()                 // the hovered (z-lifted) tok
    const paintMap     = new Map<TheC, PaintCell[]>()            // the published snapshot
    let paint_tick = $state(0)     // the template reads this to re-pull paintMap
    let raf_id = 0                 // 0 = loop stopped
    let last_ts = 0

    const grawave = (w: TheC) => Number((w.sc as any).grawave_duration) || 0.4
    const commissioned = (w: TheC) => !!(w.c as any).commission

    function all_rows(w: TheC): TheC[] {
        const mirror: any = (w.c as any).mirror
        return mirror ? (mirror.o() as TheC[]) : []
    }

    function ident_of(row: TheC): string {
        const mk = Object.keys(row.sc)[0]
        return mk ? `${mk}:${(row.sc as any)[mk]}` : '?'
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

    // build the paint snapshot from the CURRENT sprung positions: re-derive the walls per frame
    //  (a cell is where its neighbours leave room, so the walls must move with them), then a
    //   PaintCell per spring.  A null poly (crowded out) renders a small disc; a departing row is
    //    excluded from the cut and renders a shrinking disc.  The lifted (hovered) cell sorts last
    //     so it paints on top — re-asserted every build, so a keyed re-mint never loses the lift.
    function build_cells(w: TheC): { cells: PaintCell[], curWalls: Map<string, Pt[]> } {
        const cells: PaintCell[] = []
        const curWalls = new Map<string, Pt[]>()
        const sp = springs.get(w)
        if (!sp) return { cells, curWalls }
        const rowByTok = new Map<string, TheC>()
        for (const row of all_rows(w)) { const tok = (row.c as any).tok; if (tok) rowByTok.set(tok, row) }
        const liveToks: string[] = []
        const seeds: Pt[] = []
        const radii: number[] = []
        for (const [tok, s] of sp) {
            const row = rowByTok.get(tok)
            if (!row || (row.sc as any).departing) continue
            liveToks.push(tok); seeds.push({ x: s.x, y: s.y }); radii.push(s.r)
        }
        const polys = power_cells(FRAME, seeds, radii, GAP)
        const polyByTok = new Map<string, Pt[] | null>()
        for (let i = 0; i < liveToks.length; i++) {
            polyByTok.set(liveToks[i], polys[i])
            if (polys[i]) curWalls.set(liveToks[i], polys[i] as Pt[])
        }
        const liftTok = lifted.get(w)
        for (const [tok, s] of sp) {
            const row = rowByTok.get(tok)
            if (!row) continue
            const ident = ident_of(row)
            const lift = liftTok === tok
            if ((row.sc as any).departing) {
                cells.push({ tok, ident, x: s.x, y: s.y, r: Math.max(0, s.r), kind: 'disc', d: '', departing: true, lift })
            } else {
                const poly = polyByTok.get(tok)
                if (poly) cells.push({ tok, ident, x: s.x, y: s.y, r: s.r, kind: 'poly', d: path_of(poly), departing: false, lift })
                else      cells.push({ tok, ident, x: s.x, y: s.y, r: 6, kind: 'disc', d: '', departing: false, lift })
            }
        }
        cells.sort((a, b) => (a.lift === b.lift ? 0 : a.lift ? 1 : -1))
        return { cells, curWalls }
    }

    function paint_world(w: TheC) {
        const { cells, curWalls } = build_cells(w)
        paintMap.set(w, cells)
        prevWalls.set(w, curWalls)
    }

    // land every spring on its target at rest — the t→∞ limit of the closed form (calm.md §8's
    //  hidden-tab jump, and the parked-run jump).
    function jump_to_target(w: TheC) {
        const sp = springs.get(w); if (!sp) return
        const rowByTok = new Map<string, TheC>()
        for (const row of all_rows(w)) { const tok = (row.c as any).tok; if (tok) rowByTok.set(tok, row) }
        for (const [tok, s] of sp) {
            const row = rowByTok.get(tok); const T = row ? target_of(row) : null
            if (!T) continue
            s.x = T.x; s.y = T.y; s.r = T.r; s.vx = 0; s.vy = 0; s.vr = 0
        }
    }

    // one integration frame for one world; returns whether it is still in motion.  Parked worlds
    //  never integrate — they hold jumped-to-target and strike no settle.
    function integrate_world(w: TheC, dt: number): boolean {
        const sp = springs.get(w)
        if (!sp || sp.size === 0) return false
        if (parked(w)) { jump_to_target(w); paint_world(w); return false }
        const rowByTok = new Map<string, TheC>()
        for (const row of all_rows(w)) { const tok = (row.c as any).tok; if (tok) rowByTok.set(tok, row) }
        const omega = 6 / grawave(w)
        for (const [tok, s] of sp) {
            const row = rowByTok.get(tok)
            const T = row ? target_of(row) : null
            if (!T) continue
            // position governs x and y; size governs r (calm.md §5).  k defaults free if the
            //  method is absent (a bare House with no gen'd Vyto).
            const kp = (H as any).Vyto_calm_held?.(w, row, 'position') ?? 1
            const ks = (H as any).Vyto_calm_held?.(w, row, 'size') ?? 1
            step_channel(s, 'x', 'vx', T.x, kp, omega, dt)
            step_channel(s, 'y', 'vy', T.y, kp, omega, dt)
            step_channel(s, 'r', 'vr', T.r, ks, omega, dt)
        }
        const { cells, curWalls } = build_cells(w)
        paintMap.set(w, cells)
        // settle: max cell displacement (position and radius) and max derived-wall vertex drift.
        let disp = 0
        for (const [tok, s] of sp) {
            const row = rowByTok.get(tok); const T = row ? target_of(row) : null
            if (!T) continue
            disp = Math.max(disp, Math.hypot(s.x - T.x, s.y - T.y), Math.abs(s.r - T.r))
        }
        let drift = 0
        const pw = prevWalls.get(w)
        for (const [tok, poly] of curWalls) {
            const prev = pw?.get(tok)
            if (!prev || prev.length !== poly.length) { drift = Math.max(drift, 1e9); continue }
            for (let v = 0; v < poly.length; v++) drift = Math.max(drift, Math.hypot(poly[v].x - prev[v].x, poly[v].y - prev[v].y))
        }
        prevWalls.set(w, curWalls)
        const calm_frame = disp < EPS && drift < DRIFT_EPS
        let cnt = (settleCount.get(w) ?? 0)
        cnt = calm_frame ? cnt + 1 : 0
        settleCount.set(w, cnt)
        if (cnt >= SETTLE_FRAMES) {
            if (!(settledState.get(w) ?? false)) {
                settledState.set(w, true)
                if (!parked(w)) queueMicrotask(() => (H as any).Vyto_settle?.(w))   // §7: off the frame, once per transition
            }
            return false
        }
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
    function adopt(ws: TheC[]) {
        for (const w of ws) {
            if (!commissioned(w)) continue
            if (!springs.has(w)) springs.set(w, new Map())
            const sp = springs.get(w) as Map<string, Spring>
            const present = new Set<string>()
            let moved = false
            for (const row of all_rows(w)) {
                const tok: string = (row.c as any).tok
                if (!tok) continue
                const T = target_of(row)
                if (!T) continue
                present.add(tok)
                let s = sp.get(tok)
                if (!s) {
                    // a newcomer springs from x,y AT target with r 0 — the radius ramp IS the entrance.
                    sp.set(tok, { x: T.x, y: T.y, r: 0, vx: 0, vy: 0, vr: 0 })
                    moved = true
                } else if (Math.hypot(s.x - T.x, s.y - T.y) > EPS || Math.abs(s.r - T.r) > EPS) {
                    moved = true
                }
            }
            for (const tok of [...sp.keys()]) if (!present.has(tok)) sp.delete(tok)

            if (parked(w)) { jump_to_target(w); paint_world(w); continue }
            if (moved) { settleCount.set(w, 0); settledState.set(w, false) }
            if (document.hidden) {
                // rAF is frozen in a hidden tab (every ?B= runner): land at t→∞, paint, and strike
                //  settle synchronously (a jump-landing has no wriggle for SETTLE_FRAMES to debounce).
                jump_to_target(w); paint_world(w)
                if (moved) {
                    settleCount.set(w, SETTLE_FRAMES); settledState.set(w, true)
                    queueMicrotask(() => (H as any).Vyto_settle?.(w))
                }
            } else if (moved && raf_id === 0) {
                last_ts = 0; raf_id = requestAnimationFrame(frame)
            }
        }
        paint_tick++
    }

    // the drive: re-run when the model version moves (worlds arrive, the mirror re-scans, a row's
    //  T retargets).  Subscribes to each world's own version and every mirror row's — a row's
    //   bump_version on a T change bumps only the ROW, so the walk must touch each row's vers.
    $effect(() => {
        const ws = vyto_worlds()
        for (const w of ws) {
            void w.vers
            const mirror: any = (w.c as any).mirror
            if (mirror) { void mirror.vers; for (const r of (mirror.o() as TheC[])) void r.vers }
        }
        adopt(ws)
    })
    // teardown: always release the frame loop (calm.md §5's cancelAnimationFrame-on-teardown).
    $effect(() => () => { if (raf_id) cancelAnimationFrame(raf_id); raf_id = 0 })

    // ── template readers (each reads paint_tick so the snapshot re-pulls) ──────────────────
    function show_viewport(w: TheC): boolean {
        void paint_tick
        if (!commissioned(w)) return false
        const mirror: any = (w.c as any).mirror
        if (!mirror) return false
        return (mirror.ob() as TheC[]).some(r => !(r.sc as any).departing)
    }
    function viewport_cells(w: TheC): PaintCell[] { void paint_tick; return paintMap.get(w) ?? [] }

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

    // pointer facts (cells are real DOM now — the polygon hit-test retires): poke Calm to place
    //  or release the pointer-hold, lift the cell above the pile, and kick the loop so the
    //   release ease plays out.
    function on_enter(w: TheC, tok: string) {
        lifted.set(w, tok)
        ;(H as any).Vyto_pointer_enter?.(w, tok)
        kick(w); paint_tick++
    }
    function on_leave(w: TheC, tok: string) {
        if (lifted.get(w) === tok) lifted.delete(w)
        ;(H as any).Vyto_pointer_leave?.(w, tok)
        kick(w); paint_tick++
    }
</script>

{#each vyto_worlds() as w (w)}
    <div class="vyto">
        <div class="bar">
            <span class="crest">Vyto</span>
            {#each w.ob({ Bar: 1 }) as b (b.sc.Bar)}
                <button class="word" class:on={!!b.sc.on} class:act={b.sc.kind === 'act'}
                        title={b.sc.doctrine} onclick={() => press(w, b)}>{b.sc.Bar}</button>
            {/each}
        </div>
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
        <div class="strip">
            {#each w.ob({ Moment: 1 }) as m (m.sc.Moment)}
                <span class="tick" class:o={!!m.sc.o} class:blessed={!!m.sc.bless}
                      class:step={m.sc.step_n != null}
                      title={`yore ${m.sc.Moment}` + (m.sc.step_n != null ? ` — step ${m.sc.step_n}` : '')}></span>
            {/each}
        </div>
        {#if show_viewport(w)}
            <svg class="viewport" viewBox="0 0 800 450" preserveAspectRatio="xMidYMid meet">
                {#each viewport_cells(w) as cell (cell.tok)}
                    {#if cell.kind === 'poly'}
                        <path class="cell" class:departing={cell.departing} class:lift={cell.lift} d={cell.d}
                              onpointerenter={() => on_enter(w, cell.tok)}
                              onpointerleave={() => on_leave(w, cell.tok)}></path>
                    {:else}
                        <circle class="cell disc" class:departing={cell.departing} class:lift={cell.lift}
                                cx={cell.x} cy={cell.y} r={cell.r}
                                onpointerenter={() => on_enter(w, cell.tok)}
                                onpointerleave={() => on_leave(w, cell.tok)}></circle>
                    {/if}
                    <text class="ident" x={cell.x} y={cell.y} text-anchor="middle" dominant-baseline="middle">{cell.ident}</text>
                {/each}
            </svg>
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
        padding: 6px 8px; margin: 4px; max-width: 46em;
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

    /* the viewport — the fixed root scope, one cell per mirror row */
    .viewport {
        display: block; width: 100%; height: auto; margin-top: 6px;
        background: #16161c; border: 1px solid #2a2a35; border-radius: 4px;
    }
    .cell {
        fill: #2a2a3e; stroke: #6a6ad0; stroke-width: 1.2;
        transition: fill 120ms ease;
    }
    .cell.disc { fill: #33334a; }
    .cell.departing { opacity: 0.35; }
    .cell.lift { fill: #3a3a58; stroke: #a8a8f0; }
    .ident {
        fill: #e6e6f2; font: 600 14px/1 system-ui, sans-serif;   /* 14px legibility floor */
        pointer-events: none; user-select: none;
    }
    .holds { margin-top: 6px; display: flex; flex-direction: column; gap: 1px; }
    .hold { display: flex; gap: 8px; align-items: baseline; color: #a8a8bc; }
    .hold.releasing { color: #77778c; font-style: italic; }
    .hold .hscope { min-width: 8em; color: #d8d8e8; }
    .hold .hchan  { min-width: 6em; color: #8a8aa0; }
    .hold .hstr   { min-width: 5em; color: #9a9ab0; }
    .hold .hby    { color: #66667a; }
</style>
