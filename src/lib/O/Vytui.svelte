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

    let { H } = $props()

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
    // ANTI-FREEZE WATCHDOG (2026-07-29): a hard ceiling on CONTINUOUS rAF motion.  No matter what
    //  pathology keeps a world "moving" (the vertex-count flicker that used to pin drift→never-settle,
    //   a target that chases itself, a NaN), the loop MUST land within this many frames — force the
    //    jump-to-target, strike settle, and SHOUT once (the human: "get clearly fatal about insanity").
    //     ~4s @60fps: far beyond any real settle (<1s), so a healthy layout never trips it; a sick one
    //      can no longer peg the main thread → freeze the tab → kill the peer heartbeat.
    const MAX_MOTION_FRAMES = 240
    const GAP = 2.2           // the breath between cells (shapes.md §0)

    type Spring = { x: number, y: number, r: number, vx: number, vy: number, vr: number }
    // key: a TREE-unique identity (tok at the root, parentKey>tok below) — springs, lift, and the
    //  keyed {#each} are all keyed by it, because a mirror tok is only LOCALLY unique (two byte-
    //   identical cousins share a tok).  depth/hasKids drive the nested look: a cell that is a scope
    //    (its children tile it) suppresses its OWN label + face and renders as a bare frame.
    type PaintCell = { tok: string, key: string, depth: number, hasKids: boolean,
                       ident: string, x: number, y: number, r: number,
                       kind: 'poly' | 'disc', d: string, departing: boolean, lift: boolean,
                       bx: number, by: number, bw: number, bh: number, clip: string,
                       face: any | null, source: TheC | null, row: TheC }

    // the axis-aligned bounding box of a cell polygon (viewBox units) — the box a molded face fills.
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
        const { roots } = tree_nodes(w)
        const liftKey = lifted.get(w)
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
                const ident = ident_of(row)
                const lift = liftKey === n.key
                const f = face_of(row)
                const face = f ? f.comp : null
                const source = f ? f.source : null
                if ((row.sc as any).departing) {
                    const r = Math.max(0, s.r)
                    cells.push({ tok: n.tok, key: n.key, depth: n.depth, hasKids: false, ident,
                                 x: s.x, y: s.y, r, kind: 'disc', d: '', departing: true, lift,
                                 bx: s.x - r, by: s.y - r, bw: 2 * r, bh: 2 * r, clip: '', face, source, row })
                    continue
                }
                const poly = polyByKey.get(n.key)
                if (poly) {
                    const bb = bbox_of(poly)
                    const hasKids = n.kids.length > 0
                    cells.push({ tok: n.tok, key: n.key, depth: n.depth, hasKids, ident,
                                 x: s.x, y: s.y, r: s.r, kind: 'poly', d: path_of(poly), departing: false, lift,
                                 bx: bb.bx, by: bb.by, bw: bb.bw, bh: bb.bh, clip: '', face, source, row })
                    if (hasKids) layout(n.kids, poly, 0, n.key)
                } else {
                    cells.push({ tok: n.tok, key: n.key, depth: n.depth, hasKids: false, ident,
                                 x: s.x, y: s.y, r: 6, kind: 'disc', d: '', departing: false, lift,
                                 bx: s.x - 6, by: s.y - 6, bw: 12, bh: 12, clip: '', face, source, row })
                }
            }
        }
        layout(roots, FRAME, GAP, '')
        for (const k of [...wm.keys()]) if (!seenScopes.has(k)) wm.delete(k)
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
        if (parked(w)) { jump_to_target(w); paint_world(w); return false }
        const rowByKey = new Map<string, TheC>()
        for (const n of tree_nodes(w).all) rowByKey.set(n.key, n.row)
        const omega = 6 / grawave(w)
        for (const [key, s] of sp) {
            const row = rowByKey.get(key)
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
        for (const [key, s] of sp) {
            const row = rowByKey.get(key); const T = row ? target_of(row) : null
            if (!T) continue
            disp = Math.max(disp, Math.hypot(s.x - T.x, s.y - T.y), Math.abs(s.r - T.r))
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
        //  STOPS the loop, instead of `NaN < EPS === false` pinning requestAnimationFrame at 60fps forever
        //   (a dead-silent CPU burn that eventually OOM-kills the tab).  Finite frames behave identically.
        const calm_frame = !(disp >= EPS) && !(drift >= DRIFT_EPS)
        let cnt = (settleCount.get(w) ?? 0)
        cnt = calm_frame ? cnt + 1 : 0
        settleCount.set(w, cnt)
        // WATCHDOG: count continuous-motion frames; a settle resets it.  If the loop ever runs past the
        //  ceiling without landing, something is insane — LAND IT ANYWAY and shout, so a render pathology
        //   can never again peg the main thread.  (Reset only on a real settle, never from adopt, so this
        //    is a true ceiling on unbroken rAF spinning regardless of model churn re-arming targets.)
        const mf = (motionFrames.get(w) ?? 0) + 1
        if (cnt >= SETTLE_FRAMES || mf >= MAX_MOTION_FRAMES) {
            if (mf >= MAX_MOTION_FRAMES && cnt < SETTLE_FRAMES) {
                if (typeof console !== 'undefined') console.warn('[Vyto] watchdog: forced settle after', mf,
                    'frames of unbroken motion — a cell never stopped moving (disp/drift pinned). Landing anyway.', { w })
                jump_to_target(w); paint_world(w)
            }
            motionFrames.set(w, 0)
            if (!(settledState.get(w) ?? false)) {
                settledState.set(w, true)
                if (!parked(w)) queueMicrotask(() => (H as any).Vyto_settle?.(w))   // §7: off the frame, once per transition
            }
            return false
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
            for (const n of tree_nodes(w).all) {
                const T = target_of(n.row)
                if (!T) continue
                present.add(n.key)
                let s = sp.get(n.key)
                if (!s) {
                    // a newcomer springs from x,y AT target with r 0 — the radius ramp IS the entrance.
                    sp.set(n.key, { x: T.x, y: T.y, r: 0, vx: 0, vy: 0, vr: 0 })
                    moved = true
                } else if (Math.hypot(s.x - T.x, s.y - T.y) > EPS || Math.abs(s.r - T.r) > EPS) {
                    moved = true
                }
            }
            let removed = false
            for (const key of [...sp.keys()]) if (!present.has(key)) { sp.delete(key); removed = true }

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
        return { destroy() { if (stageEls.get(w) === el) stageEls.delete(w) } }
    }
    function stamp_need(w: TheC, row: TheC, area: number) {
        if (!(area > 0)) return
        const cur = (row.c as any).need_area as number | undefined
        if (cur != null && area <= cur * 1.02) return
        ;(row.c as any).need_area = area
        ;(H as any).Vyto_stir_soon?.(w)
    }
    function measure_world(w: TheC) {
        if (!(w.c as any).need_floor) return
        const stage = stageEls.get(w); if (!stage) return
        const svg = stage.querySelector('svg.viewport') as SVGSVGElement | null
        if (!svg) return
        const srect = svg.getBoundingClientRect()
        if (!(srect.width > 0) || !(srect.height > 0)) return
        const sx = 800 / srect.width, sy = 450 / srect.height
        const byKey = new Map<string, PaintCell>()
        for (const c of paintMap.get(w) ?? []) byKey.set(c.key, c)
        for (const t of stage.querySelectorAll('text.ident')) {
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
            stamp_need(w, cell.row, (child.offsetWidth * sx) * (child.offsetHeight * sy))
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
    // teardown: release the frame loop AND the pending reaction (calm.md §5's cancel-on-teardown).
    $effect(() => () => {
        react_alive = false
        if (raf_id) cancelAnimationFrame(raf_id); raf_id = 0
        if (react_pending) clearTimeout(react_pending); react_pending = 0
    })

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
    <div class="vyto">
        <div class="bar">
            <span class="crest">Vyto</span>
            {#each w.ob({ Bar: 1 }) as b (b.sc.Bar)}
                <button class="word" class:on={!!b.sc.on} class:act={b.sc.kind === 'act'}
                        title={b.sc.doctrine} onclick={() => press(w, b)}>{b.sc.Bar}</button>
            {/each}
            <button class="word organs-btn" class:on={show_organs}
                    title="the organ panel — reads/decides/writes per station (dev; layout controls to come)"
                    onclick={() => (show_organs = !show_organs)}>organs</button>
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
            <div class="stage" use:reg_stage={w}>
                <svg class="viewport" viewBox="0 0 800 450" preserveAspectRatio="xMidYMid meet">
                    {#each viewport_cells(w) as cell (cell.key)}
                        {@const g = cell_ground(cell)}
                        {#if cell.kind === 'poly'}
                            <path class="cell" class:departing={cell.departing} class:lift={cell.lift}
                                  class:faced={!!cell.face && !cell.hasKids} class:nested={cell.depth > 0} class:scope={cell.hasKids} d={cell.d}
                                  style={g ? `fill:${g.bg}; stroke:${g.border};` : undefined}
                                  onpointerenter={() => on_enter(w, cell.key, cell.tok)}
                                  onpointerleave={() => on_leave(w, cell.key, cell.tok)}></path>
                        {:else}
                            <circle class="cell disc" class:departing={cell.departing} class:lift={cell.lift} class:nested={cell.depth > 0}
                                    cx={cell.x} cy={cell.y} r={cell.r}
                                    onpointerenter={() => on_enter(w, cell.key, cell.tok)}
                                    onpointerleave={() => on_leave(w, cell.key, cell.tok)}></circle>
                        {/if}
                        {#if !cell.face && !cell.hasKids}
                            <text class="ident" data-key={cell.key} x={cell.x} y={cell.y} text-anchor="middle" dominant-baseline="middle">{cell.ident}</text>
                        {/if}
                    {/each}
                </svg>
                <!-- the FACE overlay: an HTML layer molded to the SVG in viewBox percentages (the SVG
                     keeps its 800×450 aspect at width:100%, so a % box tracks its cell exactly — no
                     pixel measurement, no overlay-sync drift).  Each faced cell mounts its glass
                     component handed the live source particle + the House. -->
                <div class="faces">
                    {#each viewport_cells(w) as cell (cell.key)}
                        {#if cell.face && !cell.departing && !cell.hasKids}
                            {@const Face = cell.face}
                            <div class="face-mold" class:lift={cell.lift} data-key={cell.key}
                                 style="left:{(cell.bx / 800) * 100}%; top:{(cell.by / 450) * 100}%; width:{(cell.bw / 800) * 100}%; height:{(cell.bh / 450) * 100}%;"
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

    /* the viewport — the fixed root scope, one cell per mirror row */
    .stage { position: relative; margin-top: 6px; }
    .viewport {
        display: block; width: 100%; height: auto;
        background: #16161c; border: 1px solid #2a2a35; border-radius: 4px;
    }
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
        position: absolute; pointer-events: none; overflow: visible;
        box-sizing: border-box;
    }
    .face-mold.lift { box-shadow: inset 0 0 0 1px #a8a8f0, 0 2px 10px rgba(0,0,0,0.5); z-index: 5; }
    .face-scroll {
        width: 100%; height: 100%; overflow: visible;
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
    .holds { margin-top: 6px; display: flex; flex-direction: column; gap: 1px; }
    .hold { display: flex; gap: 8px; align-items: baseline; color: #a8a8bc; }
    .hold.releasing { color: #77778c; font-style: italic; }
    .hold .hscope { min-width: 8em; color: #d8d8e8; }
    .hold .hchan  { min-width: 6em; color: #8a8aa0; }
    .hold .hstr   { min-width: 5em; color: #9a9ab0; }
    .hold .hby    { color: #66667a; }
</style>
