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
    const frame_of = (): Pt[] => [{ x: 0, y: 0 }, { x: vw_w, y: 0 }, { x: vw_w, y: vw_h }, { x: 0, y: vw_h }]
    // measure the stage and re-cut the frame when the shape of the hole changes.  Quantised to whole
    //  viewBox units and ignored under a 2% wobble, so a scrollbar appearing or an address bar sliding
    //   away cannot retrigger a full relayout on every frame.
    function fit_frame(el: Element | null) {
        if (!el || !(H as any)?.top_House?.()?.c?.humdinger) return
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
        const availW = r.width
        const availH = full ? r.height : Math.max(120, (window.innerHeight || 0) - r.top - 8)
        if (!(availH > 0)) return
        const portrait = availH > availW
        const ratio = Math.min(1, Math.max(0.35, portrait ? availW / availH : availH / availW))
        const long = FRAME_LONG, short = Math.max(200, Math.round(long * ratio))
        const nw = portrait ? short : long, nh = portrait ? long : short
        if (Math.abs(nw - vw_w) / vw_w < 0.02 && Math.abs(nh - vw_h) / vw_h < 0.02) return
        vw_w = nw; vw_h = nh
    }
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
                if (String(ident).indexOf('Haul:') === 0) {
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
        layout(roots, frame_of(), GAP, '')
        // OMISSION DETECTOR (2026-08-02): the real remount mechanism is a Keep cell being OMITTED from
        //  `cells` (no spring → `layout` continues past it), so its key LEAVES the keyed {#each} and
        //   KeepFace is torn down; back next build → remount.  The GATE-FLIP probe sits AFTER the
        //    `if(!s)continue` so it is blind to this.  Diff the emitted Keep-key SET vs last build and
        //     log ONLY the transitions — exactly one line per remount — with WHY (walk / spring / T).
        const sp2 = springs.get(w)
        const tnKeep = tree_nodes(w).all.filter(nn => nn.key.indexOf('Haul:') === 0)
        const emitted = new Set(cells.filter(c => c.key.indexOf('Haul:') === 0).map(c => c.key))
        const lastEmit = lastKeepEmit.get(w) ?? new Set<string>()
        for (const k of lastEmit) if (!emitted.has(k)) {
            const node = tnKeep.find(nn => nn.key === k)
            console.log('◈ Vyto CELL LEFT each →', k, '| inWalk=', !!node, 'spring=', !!sp2?.get(k), 'T=', !!(node && target_of(node.row)))
        }
        for (const k of emitted) if (!lastEmit.has(k)) console.log('◈ Vyto CELL ENTERED each →', k)
        lastKeepEmit.set(w, emitted)
        for (const k of [...wm.keys()]) if (!seenScopes.has(k)) wm.delete(k)
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
                if (typeof console !== 'undefined') console.log('▣⚠ Vyto watchdog: forced settle after', mf,
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
                } else if (Math.hypot(s.x - T.x, s.y - T.y) > EPS || Math.abs(s.r - T.r) > EPS) {
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
        fit_frame(el)
        let ro: ResizeObserver | null = null
        if (typeof ResizeObserver !== 'undefined') {
            ro = new ResizeObserver(() => fit_frame(el))
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
    function measure_world(w: TheC) {
        if (!(w.c as any).need_floor) return
        const stage = stageEls.get(w); if (!stage) return
        const svg = stage.querySelector('svg.viewport') as SVGSVGElement | null
        if (!svg) return
        const srect = svg.getBoundingClientRect()
        if (!(srect.width > 0) || !(srect.height > 0)) return
        const sx = vw_w / srect.width, sy = vw_h / srect.height
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
    const plug_timer = setInterval(() => { if (live_page()) plug_tick = plug_tick + 1 }, 500)
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
    function ants_of(): { begins: number[], dur: number } | null {
        void plug_tick
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
            <div class="stage" use:reg_stage={w} use:lifetell={{ H, what: 'stage', id: String((w.sc as any)?.w ?? '?') }}>
                <button class="fs-btn" onclick={(e) => go_fullscreen(e.currentTarget.parentElement)}
                        title="fullscreen the glass">⛶</button>
                <svg class="viewport" viewBox="0 0 {vw_w} {vw_h}" preserveAspectRatio="xMidYMid meet">
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
                        {#if cell.face && !cell.departing && !cell.hasKids}
                            {@const Face = cell.face}
                            <div class="face-mold" class:lift={cell.lift} data-key={cell.key}
                                 use:lifetell={{ H, what: 'mold', id: cell.key }}
                                 style="left:{(cell.bx / vw_w) * 100}%; top:{(cell.by / vw_h) * 100}%; width:{(cell.bw / vw_w) * 100}%; height:{(cell.bh / vw_h) * 100}%;"
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

    /* the viewport — the root scope, one cell per mirror row.  The frame follows the stage's aspect
       (fit_frame), so this is free to be any shape; fullscreen is just the biggest such shape. */
    .stage { position: relative; margin-top: 6px; }
    .viewport {
        display: block; width: 100%; height: auto;
        background: #16161c; border: 1px solid #2a2a35; border-radius: 4px;
    }
    /* FULLSCREEN — the stage becomes the whole screen and the glass fills it edge to edge.  height:100%
       on the svg (not auto) is what lets a portrait phone use its whole height instead of letterboxing;
       the frame has already been re-cut to that aspect, so nothing is stretched. */
    .stage:fullscreen { margin: 0; width: 100vw; height: 100vh; background: #0d0d12; }
    .stage:fullscreen .viewport { width: 100%; height: 100%; border: 0; border-radius: 0; }
    .fs-btn {
        position: absolute; right: 6px; top: 6px; z-index: 5;
        width: 26px; height: 26px; line-height: 1; padding: 0;
        border: 1px solid #4a4a6a; border-radius: 4px;
        background: rgba(22, 22, 28, 0.72); color: #b8b8d8;
        font-size: 13px; cursor: pointer;
    }
    .fs-btn:hover { background: #2a2a3e; color: #fff; }
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
