<script lang="ts">
    // Cellui.svelte — the Cello renderer view.
    //  "Nearly powerpoint looking UI, one after another, presented as cells that switcheroo
    //   and line up against one edge of the main one."  — owner, 2026-08-29.
    //  No voronoi, no fcose, no layout math — CSS template placement only.
    //  Charm reused from Vyto: clip-path blob walls + a DRAWN gold wall stroke + Matstyle
    //   colour + mounted Faces.  The wall is an SVG <path> tracing the SAME blob polygon
    //    (Vytui draws its wall, it does not box-shadow it — a box-shadow reads as a rectangle
    //     inset, not an organic outline), so the wobble is visible ink, not a faint frame.
    //  Mounts off house.UIs (Otro renders every UI; music-page switch is a later step).
    //  See spec/Cello_todo.md for full design.
    import { TheC } from '$lib/data/Stuff.svelte'
    import type { House } from '$lib/O/Housing.svelte'
    import { GLASS_KINDS } from '$lib/O/glass_kinds'
    import { FACE_MAINKEYS } from '$lib/O/glass_faces'
    import { cello_blob, cello_blob_path, cello_seed } from '$lib/O/cello_blob'
    import { flip } from 'svelte/animate'
    import { backOut } from 'svelte/easing'
    import { Spring } from 'svelte/motion'

    let { H } = $props()

    // ════════════════════════════════════════════════════════════════════════════
    //  THE PHYSICAL SWAP — "like Pixar animated them" (owner, all-night craft pass).
    // ════════════════════════════════════════════════════════════════════════════
    //  A minicell promoted → main while the old main demotes → minicell is a cross-BLOCK move:
    //   the same particle (keyed by cell.key) leaves the {#each} satellites and appears in the
    //    {#if} main (or vice versa).  Un-helped that's a teleport.  We PAIR the outgoing element
    //     in one block with the incoming one in the other by key and TWEEN box→box, so the blob
    //      FLIES across the stage — a heavy stone a hand turns over.  Two layers do the work:
    //
    //   · THE FLIGHT (this bespoke crossfade) drives the OUTER element's transform for the whole
    //      journey.  It is bespoke (not svelte/transition's crossfade) because the twelve
    //       animation principles need the box GEOMETRY (dx/dy/dw/dh) inside the css fn — the stock
    //        crossfade only exposes that in its OWN css and won't let a caller add an arc.  So we
    //         mirror its Map-pairing internals and write a physics-rich css: ARC lift, velocity
    //          squash&stretch, and a deepening z-lift shadow (principles 2,3,7).
    //   · THE SETTLE (the `land` Spring, below) drives an INNER wrapper for the anticipation dip,
    //      the underdamped overshoot, and the wall/guts FOLLOW-THROUGH lag (principles 1,4,5).
    //
    //  COMPOSITION (why nothing fights): the ambient rocks-in-palm drift rides .cello-drift; the
    //   satellite drag/wheel NUDGE moved onto .cello-sat-nudge; the settle bounce rides
    //    .cello-settle; the flight owns the OUTERMOST element.  Four separate transform layers,
    //     each its own wrapper — they MULTIPLY, they never overwrite one another.
    //
    //  REDUCED MOTION: a transition css can't be CSS-media-disabled, so we gate DURATION→0 and
    //   drop the arc/squash/shadow (detected once via matchMedia; SSR-safe default false).
    let reduce_motion = $state(false)
    $effect(() => {
        if (typeof window === 'undefined' || !window.matchMedia) return
        const mq = window.matchMedia('(prefers-reduced-motion: reduce)')
        reduce_motion = mq.matches
        const on = () => { reduce_motion = mq.matches }
        try { mq.addEventListener('change', on) } catch { /* older Safari */ }
        return () => { try { mq.removeEventListener('change', on) } catch { /* no-op */ } }
    })

    // ── the bespoke crossfade pair (send/receive), Map-paired by key like svelte's, but with a
    //  physics css.  A `key` present in BOTH the send-map and receive-map at flush is a SWAP pair;
    //   a lone key is a genuine join/leave → the `fallback` grow/shrink (no partner to fly to). ──
    const to_send = new Map<any, Element>()
    const to_receive = new Map<any, Element>()

    // WEIGHT curve: √d·58, floored 320ms (even a short hop has mass) capped 760ms (an off-edge
    //  belly's huge box can't drag the tween into seconds).  0 when reduced.
    const flight_dur = (d: number) => reduce_motion ? 0 : Math.min(760, Math.max(320, Math.sqrt(d) * 58))

    function flight(from_node: Element, node: Element) {
        const from = from_node.getBoundingClientRect()
        const to = node.getBoundingClientRect()
        const dx = from.left - to.left, dy = from.top - to.top
        const dw = from.width / to.width, dh = from.height / to.height
        const d = Math.hypot(dx, dy)
        const style = getComputedStyle(node)
        const base = style.transform === 'none' ? '' : style.transform
        const opacity = +style.opacity || 1
        // horizontal-dominant journeys (strip↔belly is one) stretch along X; vertical along Y.
        const horiz = Math.abs(dx) >= Math.abs(dy)
        // ARC height ~11% of travel (principle 2) — a real thrown stone lifts on the way over.
        const arc = reduce_motion ? 0 : Math.min(140, d * 0.11)
        return {
            duration: flight_dur(d),
            easing: backOut,   // the body itself overshoots its seat a hair before the spring takes over
            css: (t: number, u: number) => {
                // base box interpolation (identical maths to svelte crossfade: at t=0 sit on `from`)
                const tx = u * dx, ty = u * dy
                const sx = t + u * dw, sy = t + u * dh
                if (reduce_motion)
                    return `opacity:${t * opacity}; transform-origin:top left; transform:${base} translate(${tx}px,${ty}px) scale(${sx},${sy});`
                // SPEED proxy: a bell peaking mid-flight (0 at both ends), so squash/stretch and
                //  z-lift are strongest when the stone is moving fastest and vanish as it lands.
                const v = Math.sin(Math.PI * t)
                // SQUASH & STRETCH (principle 3), volume-preserving: stretch along motion, thin across.
                const k = 0.16 * v
                const stretch_a = 1 + k, stretch_b = 1 / (1 + k)
                const qx = horiz ? stretch_a : stretch_b
                const qy = horiz ? stretch_b : stretch_a
                // ARC (principle 2): a parabolic lift on top of the straight interpolation.
                const lift = -arc * Math.sin(Math.PI * t)
                // Z-LIFT (principle 7): the stone rises off the copper — shadow deepens+spreads mid-flight.
                const blur = 18 + 34 * v, spread = 8 + 18 * v, drop = 12 + 26 * v
                return `
                    opacity:${0.35 + 0.65 * t};
                    transform-origin:top left;
                    transform:${base} translate(${tx}px, ${ty + lift}px) scale(${sx * qx}, ${sy * qy});
                    filter: drop-shadow(0 ${drop}px ${blur}px rgba(0,0,0,${0.45 + 0.25 * v})) drop-shadow(0 0 ${spread}px rgba(0,0,0,0.3));
                    will-change: transform, filter, opacity;
                `
            },
        }
    }

    function fallback(node: Element) {
        const style = getComputedStyle(node)
        const base = style.transform === 'none' ? '' : style.transform
        const d = Math.max((node as HTMLElement).clientWidth, (node as HTMLElement).clientHeight) || 320
        return {
            duration: reduce_motion ? 0 : Math.min(560, Math.max(240, Math.sqrt(d) * 48)),
            easing: backOut,   // a newcomer pops in with a touch of overshoot, a leaver shrinks away
            css: (t: number) =>
                `opacity:${t}; transform-origin:center; transform:${base} scale(${0.55 + 0.45 * t});`,
        }
    }

    // send/receive — set the node in its map; at flush, if the counterpart map holds the same key
    //  it's a SWAP pair (fly box→box), else the fallback.  (Mirror of svelte/transition crossfade.)
    function make_side(mine: Map<any, Element>, theirs: Map<any, Element>) {
        return (node: Element, params: { key: any }) => {
            mine.set(params.key, node)
            return () => {
                if (theirs.has(params.key)) {
                    const other = theirs.get(params.key)!
                    theirs.delete(params.key)
                    return flight(other, node)
                }
                mine.delete(params.key)
                return fallback(node)
            }
        }
    }
    const send = make_side(to_send, to_receive)
    const receive = make_side(to_receive, to_send)

    // ── THE SETTLE SPRING (`land`) — anticipation + underdamped overshoot + follow-through ──────
    //  One spring per swap, driving an INNER wrapper (.cello-settle) that MULTIPLIES with the
    //   flight.  Underdamped (stiffness 0.12, damping 0.62) so it OVERSHOOTS and rings down — the
    //    overshoot is the life (principle 1).  On a swap we snap it to 0 (a wound-up ANTICIPATION
    //     dip, scale ≈ 0.94) then release to 1: it springs past 1 and settles, giving the launch
    //      wind-up + the arrival bounce in one motion (principle 4).  Its distance-to-go is the
    //       ENERGY that couples wall wobble + stroke to speed (principle 6), and the guts wrapper
    //        reads it a beat LATE for the wall/face follow-through (principle 5).
    const land = new Spring(1, { stiffness: 0.12, damping: 0.62, precision: 0.002 })
    //  the WALL+GUTS trail on a SOFTER spring so the outline jiggles and the face settles a beat
    //   after the body lands — overlapping action, the single biggest "alive" tell (principle 5).
    const land_guts = new Spring(1, { stiffness: 0.08, damping: 0.58, precision: 0.002 })
    // scale the settle wrapper: at land=0 it's dipped to 0.94; rest at land=1; overshoot rings >1.
    const settle_scale = $derived(reduce_motion ? 1 : 0.94 + 0.06 * land.current)
    //  the guts lag: a slightly bigger swing off the softer spring (0.90..overshoot), plus a whisper
    //   of counter-rotation so the silhouette flexes rather than just breathing.
    const guts_scale = $derived(reduce_motion ? 1 : 0.90 + 0.10 * land_guts.current)
    const guts_tilt  = $derived(reduce_motion ? 0 : (land_guts.current - 1) * 4)   // deg, rings to 0
    // ENERGY 0..1 — how far the spring still is from rest; peaks at launch, decays as it settles.
    //  Couples the wall wobble amplitude + stroke to SPEED (principle 6): the silhouette shivers as
    //   the stone moves and calms when it lands.
    //  Take the MAX of BOTH springs' distance-to-rest so the shiver stays hot through the whole
    //   two-clock settle — the guts are still ringing after the body has calmed, and the wall must
    //    keep shivering until the LAST thing stops moving, not just the body.
    const swap_energy = $derived(
        reduce_motion ? 0
        : Math.min(1, Math.max(Math.abs(1 - land.current), Math.abs(1 - land_guts.current)) * 7)
    )

    // ── size floor — below this satellite width (px) drop the rim label ─────────
    const LABEL_FLOOR_W = 80

    // ── colour fallback palette (when Matstyle isn't mixed in yet) ───────────────
    //  keyed by mainkey; anything missing falls back to a neutral jewel.  These sit
    //   in Vyto's register — a dim jewel ground (#17171f-ish) with a saturated rim.
    const FALLBACK_COLOUR: Record<string, { bg: string, color: string, border: string }> = {
        Door:       { bg: '#1a0e2e', color: '#c6a6f0', border: '#9b6fc9' },
        Radio:      { bg: '#1a1408', color: '#f0d488', border: '#e0a04c' },
        Link:       { bg: '#0e1a1a', color: '#88e8e8', border: '#4cc9c9' },
        Supervisor: { bg: '#0e1a0e', color: '#88e888', border: '#4cc94c' },
        Transfer:   { bg: '#1a0e0e', color: '#e88888', border: '#c94c4c' },
        Heist:      { bg: '#0e0e1a', color: '#8888e8', border: '#4c4cc9' },
        Caper:      { bg: '#1a120e', color: '#e8b088', border: '#c9784c' },
    }
    const NEUTRAL = { bg: '#141420', color: '#a8a8cc', border: '#6a6ad0' }

    // ── WALLPAPER — which cells wear a photo texture instead of their flat jewel ground.
    //  Keyed by MAINKEY (never the tok — the radio's tok half is its STATE, so a tok key would
    //   peel the paper off every track change; the Vytui contract, Vytui.svelte:1297).  The photo
    //    is multiplied by the cell's own Matstyle ground so it reads as a TEXTURE tinted to the
    //     cell's colour, not a pasted picture (see the <pattern> in the template).  Radio is the
    //      required one (the sea/album texture in the screenshot); others keep their jewel ground.
    const WALLPAPER: Record<string, string> = { Radio: 'cello-sea' }
    // wall_tint — the ground the paper is multiplied by; the SAME colour the cell would have worn
    //  plain, so wallpapering never costs the organ its colour.  Guarded like Vytui's.
    function wall_tint(mk: string): string {
        try { return (H as any)?.matstyle_ground?.(mk)?.bg ?? cell_colour(mk).bg } catch { return '#17171f' }
    }

    // ── the PERMANENT CAST — always allowed as satellites at rest (owner: "Always
    //  Door|Player, sometimes others").  Everything else is contextual and only shows
    //   when it earns a seat (see keep_cell): a Heist while a nab is in flight, a
    //    Supervisor only when something is amiss, etc.  Restraint is a requirement —
    //     the resting glass is main + Door + Player, nothing more.
    const PERMANENT_CAST = new Set(['Door', 'Radio'])

    // ── is a %Supervisor healthy (and so NOT worth a seat)?  SupervisorFace is
    //  quiet-when-healthy, and taken all the way that means ABSENCE (its own header:
    //   "IT IS USUALLY NOT HERE AT ALL … the glass only grapples the %Supervisor row
    //    when the model says something is `amiss`").  The signal is sc.amiss > 0.
    function supervisor_amiss(n: TheC): boolean {
        try { return Number((n?.sc as any)?.amiss ?? 0) > 0 } catch { return false }
    }

    // ── keep_cell — the restraint gate.  Decides whether a scanned particle earns a
    //  seat on the resting glass.  Permanent cast always; a Supervisor only when amiss;
    //   everything else (Heist, Transfer, Link, Caper…) is contextual and shows because
    //    it is PRESENT in the tree (a finished Heist is flattened away, so a Heist still
    //     here is a nab in flight).  Guarded — a throw keeps the cell rather than dropping
    //      it silently.
    function keep_cell(mk: string, n: TheC): boolean {
        try {
            if (PERMANENT_CAST.has(mk)) return true
            if (mk === 'Supervisor') return supervisor_amiss(n)
            return true
        } catch { return true }
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // CELL RECORD — one entry per face-bearing particle
    // ─────────────────────────────────────────────────────────────────────────────
    type Cell = {
        key: string
        n: TheC        // the live particle (handed to Face)
        mk: string     // mainkey
        seed: number   // stable shape seed (so the off-edge variant can re-derive the ring)
        face: any      // Svelte component | null
        colour: { bg: string, color: string, border: string }
        blob: string   // clip-path polygon string
        wall: string   // SMOOTH SVG path `d` tracing the same ring (viewBox 0 0 100 100)
        paper: string | null   // wallpaper <pattern> id, or null for a plain jewel fill
        label: string
    }

    // ── colour for a mainkey — Matstyle if available, else fallback ───────────────
    function cell_colour(mk: string): { bg: string, color: string, border: string } {
        try {
            const g = (H as any)?.matstyle_ground?.(mk)
            if (g && g.bg && g.border) return g
        } catch { /* Matstyle not mixed in yet */ }
        return FALLBACK_COLOUR[mk] ?? NEUTRAL
    }

    // ── build one Cell from a live particle + the mainkey it wears ───────────────
    //  Factored out so BOTH sources (the commissioned mirror and the raw fallback)
    //   mint identical records.  `n` is the LIVE particle handed to the Face.
    function make_cell(n: TheC, mk: string, kind: string): Cell {
        const face = GLASS_KINDS[kind] ?? null
        const id = (n.sc as any).pub || (n.sc as any).id || mk
        const seed = cello_seed(String(id))
        const colour = cell_colour(mk)
        const label = (n.sc as any).name || (n.sc as any).label || mk
        const blob = cello_blob(seed)
        const wall = cello_blob_path(seed)   // SMOOTH Q-curve wall, not the jagged polygon
        const paper = WALLPAPER[mk] ?? null   // Radio wears the sea texture; others stay jewel
        return { key: mk + ':' + String(id), n, mk, seed, face, colour, blob, wall, paper, label }
    }

    // ── resolve a particle to a face-bearing Cell, or null ───────────────────────
    //  Face-bearing = mainkey ∈ FACE_MAINKEYS or an sc.face worn.  Applies the
    //   restraint gate (keep_cell).  Returns null for anything that earns no seat.
    function cell_of(n: TheC | undefined, seen: Set<TheC>): Cell | null {
        if (!n || !n.sc || seen.has(n)) return null
        seen.add(n)
        const mk = Object.keys(n.sc)[0]
        if (!mk) return null
        const kind: string | undefined = (n.sc as any).face || FACE_MAINKEYS[mk]
        if (!kind) return null
        if (!keep_cell(mk, n)) return null
        return make_cell(n, mk, kind)
    }

    // ── the commissioned worlds on this House (Vyto preferred, Cyto fallback) ─────
    //  Vytui's own selector (Vytui.svelte:73): A:Vyto > w:Vyto.  A world the
    //   Sounditron commissioned carries a distilled `w.c.mirror` — the SAME rows the
    //    live glass draws — and each mirror row backlinks its LIVE particle on
    //     `row.c.source_n` (glass contract, Vytui.svelte:53-62).  We scan THAT, so
    //      Cello's cast is exactly Vyto's, not an arbitrary Mundo walk.
    function commissioned_worlds(): TheC[] {
        const H_any = H as any
        const out: TheC[] = []
        for (const tag of ['Vyto', 'Cyto']) {
            for (const A of (H_any.ob?.({ A: tag }) ?? []) as TheC[])
                for (const w of (A.ob?.({ w: tag }) ?? []) as TheC[]) out.push(w)
            if (out.length) break   // Vyto preferred — don't mix Cyto in when Vyto stood
        }
        return out
    }

    // ── scan for face-bearing cells ──────────────────────────────────────────────
    //  PRIMARY source: the commissioned world's mirror (each row → its live
    //   source_n).  FALLBACK (no mirror yet — pre-commission, headless, a bare
    //    House): the old raw H > A > w walk, so the glass is never blank while a
    //     commission is still landing.  H.version gates reactivity; try/catch so a
    //      bad subtree never white-screens.
    function scan_cells(): Cell[] {
        try {
            void (H as any)?.version
            if (!H) return []

            const seen = new Set<TheC>()
            const out: Cell[] = []

            // PRIMARY — the commissioned mirror(s)
            for (const w of commissioned_worlds()) {
                const mirror: any = (w.c as any)?.mirror
                if (!mirror?.o) continue
                for (const row of (mirror.o() ?? []) as TheC[]) {
                    // hand the Face the LIVE particle; the sc-only mirror twin is the
                    //  fallback basis only when a row carries no backlink.
                    const src = (row.c as any)?.source_n as TheC | undefined
                    const cell = cell_of(src ?? row, seen)
                    if (cell) out.push(cell)
                }
            }
            if (out.length) return out

            // FALLBACK — raw walk (pre-commission / headless), same face gate
            const H_any = H as any
            for (const A of (H_any.ob?.({ A: 1 }) ?? []) as TheC[])
                for (const w of (A.ob?.({ w: 1 }) ?? []) as TheC[])
                    for (const n of (w.ob?.({}) ?? []) as TheC[]) {
                        const cell = cell_of(n, seen); if (cell) out.push(cell)
                    }
            for (const n of (H_any.ob?.({}) ?? []) as TheC[]) {
                const cell = cell_of(n, seen); if (cell) out.push(cell)
            }
            return out
        } catch (err) {
            console.warn('[Cellui] scan error:', err)
            return []
        }
    }

    // ── which particle is main — stored as its cell key ───────────────────────────
    //  Prefer something that's NOT Door/Radio first (the contextual "big thing"),
    //  falling back to Radio, then Door, then the first available.
    let main_key = $state<string | null>(null)

    // (the big/compact toggle is GONE — the owner 2026-08-30: "the compact toggle button is not
    //  wanted, doesn't achieve much?".  The main has ONE size: big.  The off-edge belly is the
    //   only other stance, and the CAST decides that, not a hand.)

    // ── wall-clock heartbeat — surfaces .c-only state (layer 3) ──────────────────
    //  Most of what Cello draws is structural/sc and bumps H.version.  But the
    //   commissioned `w.c.mirror` is a `.c` structure the Cyto/Vyto GHOST keeps
    //    fresh (req-driven, independent of which VIEW is mounted) — and a `.c` write
    //     bumps no version (CLAUDE.md).  So when Cello is showing INSTEAD of Vyto and
    //      a source goes quiet→amiss (or a mirror row lands), version may not fire.
    //  This tick re-runs the scan on a gentle wall clock.  It is a PURE READ — it
    //   mutates no sc, snaps nothing, bumps no version — so it can never flake a
    //    fixture (Books drive Vyto, never this).  Browser-only, torn down on unmount.
    let now_tick = $state(0)
    $effect(() => {
        if (typeof window === 'undefined') return
        const id = setInterval(() => { now_tick++ }, 1000)
        return () => clearInterval(id)
    })

    // ── derived cell list (re-runs on H.version bump OR the heartbeat) ───────────
    const cells = $derived.by(() => {
        void (H as any)?.version
        void now_tick
        return scan_cells()
    })

    // ── RESTING MAIN is ALWAYS the Player (Radio) ─────────────────────────────────
    //  "a proper look at one big thing" is the Radio — it is the resting main and
    //   nothing usurps it.  Supervisor must NEVER become the big cell (it is a small
    //    satellite, and only when unwell); Door is the fallback main only if no Radio
    //     exists yet, then the first face-bearing cell as a last resort.  A user tap
    //      (switcheroo) can TEMPORARILY promote a satellite — that choice is honoured
    //       while its cell is still present, but the default is always Radio.
    function resting_main(list: Cell[]): Cell | null {
        return list.find(c => c.mk === 'Radio')
            ?? list.find(c => c.mk === 'Door')
            ?? list.find(c => c.mk !== 'Supervisor')
            ?? list[0]
            ?? null
    }

    // ── TAKEOVER cells (glass_kinds: "its own takeover cell") — the dramatic OFF-EDGE belly look (see
    //  main_offedge).  Owner 2026-08-30: "it's actually only the Heist setup that's super big; the Link
    //   Device is likely okay as the regular large cell" — so ONLY the Heist ceremony earns the giant
    //    spill-off-screen geometry.  Link/Transfer/Caper still CLAIM the main (commissioner focus +
    //     the main-or-gone satellites filter for Link), but render as a normal large main cell.
    const TAKEOVER = new Set(['Heist', 'HeistBar'])
    // THE COMMISSIONER'S FOCUS is the shared belly signal (task #45 "defer to commissioner belly").
    //  Sounditron stores the focused cell's MAINKEY on the commissioned world as `w.c.focused`
    //   (Sounditron.g: the Door's "Link Device" button → 'Link', a Vyto cell-switch → that cell, else
    //    'Radio').  Cello FOLLOWS it and its own switcheroo DRIVES it (set_focus), so the two glasses
    //     share ONE focus — the Door buttons work here every press, and a Link un-grapples the instant
    //      you leave it (Sounditron drops the %Link organ when focused≠'Link' and no ferry is live),
    //       which IS "navigate away → it vanishes, re-enter via Door".  Read through now_tick too so a
    //        .c-only focus write by the Sounditron surfaces (focused is .c, bumps no version).
    //  ⚠ focus lives on the CLIENT world, not the glass world.  Sounditron_focus writes `w.c.focused`
    //   on `vw.c.client_w` (the run world the organs live on — Sounditron.g:1150-1163 "THE WORLD IT
    //    HANDS ON IS THE CLIENT'S, NOT THE GLASS'S"), while `commissioned_worlds()` returns the w:Vyto
    //     glass.  So read `client_w.c.focused` (fall back to the glass world for a headless/odd case).
    function commissioner_focus(): string | null {
        try {
            void now_tick
            for (const w of commissioned_worlds()) {
                const cw = (w.c as any)?.client_w
                const f = (cw?.c as any)?.focused ?? (w.c as any)?.focused
                if (f) return String(f)
            }
        } catch {}
        return null
    }
    // DRIVE the focus through the SAME seam the Door buttons use (Sounditron_focus resolves the client
    //  world + focus_to + bump), so Cello's switcheroo and a Door press are one path.  Key = the cell's
    //   mainkey ('Radio'/'Door'/'Link'…).  Guarded; the local main_key echo still moves the glass if the
    //    seam isn't present (a bare House, headless).
    function set_focus(mk: string) {
        try { (H as any).Sounditron_focus?.(mk) } catch { /* no seam — rely on the local echo */ }
    }

    // ── THE FOCUS AUTHORITY (Layer B) — who claims the belly, and how you say no ──
    //  Three grades of claim (the owner, 2026-08-29):
    //   · a cell that merely EXISTS (a Link standing) is a soft belly at most — the user's
    //      switcheroo leaves it freely ("we quit it by going back to anything else");
    //   · a cell wearing `stage_want` is INSISTENT ("a Cave wanting colonising will focus us
    //      back into it") — it claims the main and RE-claims it even after the user wanders,
    //       for as long as the want stands;
    //   · the only out is REFUSING that specific ask ("the only way to avoid that is to hit
    //      'no'").  A refusal is scoped to THE ASK (cell + want value), not the cell: the same
    //       device re-asking later is a NEW ask and gets a fresh hearing.
    //  WHY stage_want AND NOT pose: in Vyto the commissioner stamps pose and the renderer reads
    //   it (Vytui:791-812, "ask 'did the commissioner name a belly'").  But Cello WRITES pose —
    //    it is our output channel to the Faces (main='big', sats='small', below) — so reading it
    //     back would be reading our own writes.  `stage_want` is the commissioner's ask ("how a
    //      heist asks — the model's programmatic staging", Vytui:772) and Cello never writes it:
    //       clean input.  Supervisor can never claim, want or no want.
    //  THE DURABLE REFUSAL IS A SERIAL, NOT THIS SET: the real "no" checks the grant's serial
    //   off against the %Idzeug issuer (Ghost/S/Swarm.g §6.2 — the class behind an invite, with
    //    its `claimed:"3-5,9,14"` ranges), so a refused colonisation is as recorded as a spent
    //     one and a fresh serial re-offers cleanly.  This Set is the VIEW-side seam that wiring
    //      lands in (task #45); it already keys per-ask so the shape is right.
    let refuse_tick = $state(0)
    const refused = new Set<string>()          // ask ids: `${cell.key}·${want}` — view state, never snapped
    const ask_id = (c: Cell): string | null => {
        try {
            const want = (c.n?.c as any)?.stage_want
            return want ? c.key + '·' + String(want) : null
        } catch { return null }
    }
    function refuse_ask(c: Cell) {
        const id = ask_id(c)
        if (id) { refused.add(id); refuse_tick++ }
    }
    const insistent = $derived.by(() => {
        void refuse_tick
        return cells.find(c => {
            if (c.mk === 'Supervisor') return false
            const id = ask_id(c)
            return !!id && !refused.has(id)
        }) ?? null
    })

    $effect(() => {
        const list = cells
        if (!list.length) return
        const keys = new Set(list.map(c => c.key))
        // TIER 1 — an unrefused insistent ask (a Cave wearing stage_want) OWNS the belly, re-claiming
        //  even after you wander ("a Cave wanting colonising focuses us back"), until refused ("no").
        const want = insistent
        if (want) { if (main_key !== want.key) main_key = want.key; return }
        // TIER 2 — the COMMISSIONER'S FOCUS (w.c.focused, a mainkey): the Door buttons + a Vyto switch
        //  drive it, Cello follows.  Match by mainkey (Radio/Door/Link are singletons).
        const foc = commissioner_focus()
        if (foc) { const c = list.find(x => x.mk === foc); if (c) { if (main_key !== c.key) main_key = c.key; return } }
        // TIER 3 — the resting main: keep a still-valid main, else fall to Radio.
        if (main_key && keys.has(main_key)) return
        main_key = resting_main(list)?.key ?? null
    })

    // ── partition into main + satellites ─────────────────────────────────────────
    //  POSE is stamped HERE, synchronously, inside the derived — before the template mounts
    //   the Faces (RadioFace/DoorFace read n.c.pose).  Cello's main is ALWAYS 'big' (the full
    //    form), every satellite is 'small' (a bud glyph).  This replaces the old fragile @const
    //     side-effects in the template: those raced the 1s heartbeat re-scan (which mints a fresh
    //      cell object over the same shared particle) and the Face's mount, so a promoted main
    //       could read the stale 'small' pose and blow the bud glyph up into "a giant play button".
    //        Because main↔satellite is a cross-block move (main {#if} vs satellite {#each}), the
    //         Face remounts on role change and reads the freshly-stamped pose.  pose is .c-only
    //          (never snapped) and Vyto re-solves it on switch-back, so this is safe.
    const main_cell = $derived.by(() => {
        const c = cells.find(x => x.key === main_key) ?? null
        if (c?.n?.c) c.n.c.pose = 'big'
        return c
    })
    // LATCH THE LEAVING CELL'S KEY (owner 2026-08-31, the Door-nav crash "Cannot read properties of undefined
    //  (reading 'reset')").  On a rapid swap (Link→Door) main_cell blips null for a tick, so `out:send` fired
    //   with key:undefined — and Svelte's DEFERRED crossfade facade does `reset: () => a.reset()` where `a` is
    //    only set in a later microtask (transitions.js), so an undefined-key leave that resets before that tick
    //     throws.  A real, stable key keeps the leave a normal deferred outro.  Holds the last non-null main key.
    let last_main_key = $state<string | null>(null)
    $effect(() => { if (main_cell?.key) last_main_key = main_cell.key })

    // ── KICK THE SETTLE SPRING on every main_key change — the arrival wind-up+overshoot.  Snap to
    //  the dipped anticipation pose (0) WITHOUT animating (instant), then release to 1 so the
    //   underdamped spring springs out past rest and rings down.  Skipped on the very first mount
    //    (no swap happened) and when reduced-motion is on.  Reads main_key only. ──
    let land_primed = false
    $effect(() => {
        const k = main_key
        void k
        if (!land_primed) { land_primed = true; return }   // don't bounce on first paint
        if (reduce_motion) { land.set(1, { instant: true }); land_guts.set(1, { instant: true }); return }
        land.set(0, { instant: true }); land_guts.set(0, { instant: true })   // ANTICIPATION — wound-up dip
        land.set(1); land_guts.set(1)     // …released: overshoot + settle, guts trailing (1,4,5)
    })

    // ── OFF-EDGE BIG-CELL — the dramatic "really-big" main (screenshot RIGHT, the Link Device
    //  cell whose wall arcs off the left/top/bottom edges, satellites nestled on its right wall).
    //   The rule: a BELLY main that is a big contextual actor (Heist/Link/Transfer/Caper) gets the
    //    off-edge look; the resting Radio/Door keep the centred-big look (screenshot LEFT).  Both
    //     stay available — flip by which cell is main.  When off-edge the main's wall is re-derived
    //      oversized (scale) and shifted LEFT (dx<0) so only its right portion shows in the box.
    const main_offedge = $derived(!!main_cell && TAKEOVER.has(main_cell.mk))
    // OFF-EDGE blob is OVERSIZED so it OVERFILLS the visible box (owner 2026-08-30: "not fat enough on
    //  the left side — showing two triangles of outside it").  A normal-radius ring in the wide spilling
    //   box left the top-left/bottom-left viewport corners OUTSIDE the curve (the two triangles).  scale
    //    1.32 pushes the radii well past the box on the left/top/bottom (no corner gaps); dx −12 nudges
    //     the bulk left so only the RIGHT arc curves in (where the minicells nestle).  The centred-big
    //      stance (Radio/Door) keeps the normal blob.
    const main_edge_blob = $derived(main_cell ? cello_blob(main_cell.seed, { scale: 1.32, dx: -12 }) : '')
    const main_edge_wall = $derived(main_cell ? cello_blob_path(main_cell.seed, { scale: 1.32, dx: -12 }) : '')
    const main_blob = $derived(main_offedge ? main_edge_blob : (main_cell?.blob ?? ''))
    const main_wall = $derived(main_offedge ? main_edge_wall : (main_cell?.wall ?? ''))

    // ── satellites — RESTRAINED.  At rest the glass shows the main + only the
    //  permanent cast (Door + Player), and it never crowds.  When a nab is in flight
    //   (a %Heist cell present) the glass is ALLOWED to grow to show the heist cell(s);
    //    otherwise contextual actors that slipped past keep_cell are held to a couple
    //     of extras so the resting state stays calm (owner: "one or two minicells").
    //  Ordering: permanent cast first (Door, then Player), then the rest, so the
    //   fixed cast always reads in the same place.  POSE stamped 'small' here (see main_cell).
    const heisting = $derived(cells.some(c => c.mk === 'Heist' || c.mk === 'HeistBar'))
    const satellites = $derived.by(() => {
        // LINK is MAIN-OR-GONE — never a minicell (owner: a walked-away Link vanishes, re-enter via
        //  Door).  Other contextual cells (Heist/Transfer) may still ride as minicells when present.
        const rest = cells.filter(c => c.key !== main_key && c.mk !== 'Link')
        const rank = (c: Cell) => c.mk === 'Door' ? 0 : c.mk === 'Radio' ? 1 : 2
        const ordered = [...rest].sort((a, b) => rank(a) - rank(b))
        // permanent cast is always kept; the extras are capped unless we're heisting.
        const permanent = ordered.filter(c => PERMANENT_CAST.has(c.mk))
        const extras = ordered.filter(c => !PERMANENT_CAST.has(c.mk))
        const extra_cap = heisting ? extras.length : Math.min(extras.length, 2)
        const list = [...permanent, ...extras.slice(0, extra_cap)]
        for (const c of list) if (c?.n?.c) c.n.c.pose = 'small'   // satellites are bud glyphs
        return list
    })

    // ── switcheroo — tap a satellite to make it main ───────────────────────────
    //  A true SWAP: the tapped cell erupts to the main slot; the old main falls to a
    //   satellite on the next derive (main_cell picks up the new main_key; the old main is
    //    no longer main_key so it lands in `satellites`).  Works for EVERY cell — permanent
    //     cast AND contextual (Link/Heist/Transfer) — the $effect below honours the pick.
    function switcheroo(cell: Cell) {
        set_focus(cell.mk)    // DRIVE the commissioner's focus — Vyto follows, and a left Link un-grapples
        main_key = cell.key   // optimistic local echo; the effect re-affirms from w.c.focused next derive
    }

    // ── ROCKS-IN-PALM drift timing — a stable per-cell duration + phase from the seed, so
    //  neighbours drift out of sync and appear to turn about one another (owner: "like rocks
    //   in your palm").  Duration in a slow 14–26s band; delay negative so every cell starts
    //    mid-cycle (no synchronised kick-off).  Pure, deterministic, SSR-safe.
    function drift_dur(seed: number, base = 20): number {
        return base + (seed % 1200) / 100   // base .. base+12s, stable per seed
    }
    function drift_delay(seed: number): string {
        return `-${seed % 9000}ms`
    }


    // ─────────────────────────────────────────────────────────────────────────────
    // ROLLABLE + RESIZABLE MINICELLS — a minicell is a physical stone: drag to ROLL it
    //  around/along the main cell, wheel (or corner-drag) to RESIZE.  Its nudged position
    //   (a px offset off its resting flex slot) + scale persist keyed by the STABLE cell.key
    //    in a plain Map — VIEW STATE, never snapped, so it survives the 1s heartbeat re-scan
    //     and re-derives.  A stone being dragged pauses its ambient rocks-in-palm drift and
    //      settles where it lands (the drift resumes from there).  Pointer-based, guarded.
    // ─────────────────────────────────────────────────────────────────────────────
    type Nudge = { dx: number, dy: number, scale: number }
    // reactive so a nudge repaints; a Map wrapped in $state gives us fine-grained keys.
    let nudges = $state<Map<string, Nudge>>(new Map())
    let dragging_key = $state<string | null>(null)

    function nudge_of(key: string): Nudge {
        return nudges.get(key) ?? { dx: 0, dy: 0, scale: 1 }
    }
    function set_nudge(key: string, n: Nudge) {
        const m = new Map(nudges); m.set(key, n); nudges = m
    }

    // pointer roll — drag the stone; dx/dy accumulate off its resting slot (guarded).
    function sat_pointerdown(e: PointerEvent, cell: Cell) {
        try {
            if (e.button !== 0) return
            const start = nudge_of(cell.key)
            const sx = e.clientX, sy = e.clientY
            const target = e.currentTarget as HTMLElement
            let moved = false
            dragging_key = cell.key
            try { target.setPointerCapture(e.pointerId) } catch { /* no-op */ }
            const move = (ev: PointerEvent) => {
                const ddx = ev.clientX - sx, ddy = ev.clientY - sy
                if (!moved && Math.hypot(ddx, ddy) > 4) moved = true
                // clamp the roll so a stone can wander around/along the main but never off to nowhere
                const clamp = (v: number, lim: number) => Math.max(-lim, Math.min(lim, v))
                set_nudge(cell.key, { dx: clamp(start.dx + ddx, 480), dy: clamp(start.dy + ddy, 480), scale: start.scale })
            }
            const up = (ev: PointerEvent) => {
                window.removeEventListener('pointermove', move)
                window.removeEventListener('pointerup', up)
                try { target.releasePointerCapture(ev.pointerId) } catch { /* no-op */ }
                dragging_key = null
                // a real drag consumes the click so it doesn't ALSO promote; a tap (no move) promotes.
                if (moved) { const swallow = (ce: Event) => { ce.stopPropagation(); ce.preventDefault() }
                    target.addEventListener('click', swallow, { capture: true, once: true }) }
            }
            window.addEventListener('pointermove', move)
            window.addEventListener('pointerup', up)
        } catch { dragging_key = null }
    }

    // wheel resize — grow/shrink the stone under the pointer, persisted + clamped (guarded).
    function sat_wheel(e: WheelEvent, cell: Cell) {
        try {
            e.preventDefault()
            const cur = nudge_of(cell.key)
            const next = Math.max(0.55, Math.min(2.4, cur.scale * (e.deltaY < 0 ? 1.08 : 0.926)))
            set_nudge(cell.key, { dx: cur.dx, dy: cur.dy, scale: next })
        } catch { /* no-op */ }
    }

    // ── FOOLPROOF LAYOUT — a ResizeObserver on the stage root ─────────────────────
    //  The layout is CSS-driven (flex + clamp + vw/vh), so it already flows, but the
    //   observer gives an explicit recompute seam and lets us STACK the satellites
    //    below the main cell on a narrow embed instead of letting them overflow the
    //     side.  `stage_w` drives a `narrow` class; nothing here measures a Face (that
    //      stays the browser's job).  Guarded + torn down so it can't leak or throw on
    //       an SSR/no-RO environment.
    let stage_el = $state<HTMLDivElement | null>(null)
    let stage_w = $state(0)
    const NARROW_FLOOR = 640   // below this the satellites go UNDER the main, not beside

    $effect(() => {
        const el = stage_el
        if (!el || typeof ResizeObserver === 'undefined') return
        stage_w = el.clientWidth
        let raf = 0
        const ro = new ResizeObserver((entries) => {
            // coalesce to a frame so a resize storm doesn't thrash reactivity
            if (raf) return
            raf = requestAnimationFrame(() => {
                raf = 0
                try {
                    const w = entries[0]?.contentRect?.width ?? el.clientWidth
                    if (Number.isFinite(w)) stage_w = w
                } catch { /* never let a measure throw white-screen the glass */ }
            })
        })
        try { ro.observe(el) } catch { /* no-op */ }
        return () => { if (raf) cancelAnimationFrame(raf); try { ro.disconnect() } catch { /* no-op */ } }
    })

    const narrow = $derived(stage_w > 0 && stage_w < NARROW_FLOOR)

    // ─────────────────────────────────────────────────────────────────────────────
    // THE GUTS-FITTING MACHINERY — ported from Vytui (adapted, simpler: no springs, no
    //  solver).  The face content ("the guts") must INSCRIBE into the blob, not sit in a
    //   centered-flex-and-hope box.  Four pieces, each the Vytui pattern:
    //   · sizewatch (Vytui:3193) — one shared ResizeObserver on the FACE'S OWN ROOT (the
    //      scroll's firstElementChild): "the scroll's box is handed down from the mold — it
    //       changes when WE change it; the child's box is the face's own answer — the thing
    //        worth hearing about."  Re-resolved on update + a microtask, because the Face
    //         mounts AFTER the action runs.
    //   · measure_soon / measure_lately (Vytui:3164-3187) — a trailing 140ms pass folds a
    //      burst into ONE measure; two LATE LOOKS at 450/900ms catch the settle ("a face that
    //       resized once tends to resize AGAIN when its async content lands a beat later —
    //        a cost line goes spinner → numbers, a listing fills in").
    //   · the natural box (Vytui:3124-3127) — child.offsetWidth/Height, SKIPPING a
    //      box-stretched child (|child.w − scroll.w| ≤ 1: it echoes the column, says nothing).
    //   · the --fit trick (Vytui:1258) — the layout width and the zoom are SEPARATE variables:
    //      the scroll lays out at 100%/--fit and scales back by --fit, so the face keeps its
    //       OWN layout at a wider virtual column and is scaled to inscribe — never cramped,
    //        never spilling over the wobbly wall.
    //  NOT wired off H.version (Vytui:3151-3157 documents the adopt feedback-loop trap:
    //   measure→react→adopt→bump→measure, spinning forever).  The RO on the face root is the
    //    honest instrument (Vytui:3158-3163): it fires when a panel unfolds (DoorFace's invite
    //     opening), costs nothing at rest, cannot route back through the reactive graph.  The
    //      existing 1s now_tick covers the rest.  All view state; nothing snapped.
    // ─────────────────────────────────────────────────────────────────────────────
    const molds = new Map<string, HTMLElement>()      // cell.key → its face-scroll el (plain, not reactive)
    let fits = $state<Map<string, number>>(new Map()) // cell.key → --fit (view state, never snapped)

    // the honest inscribed rect of a round-ish blob: a centered box of ~2/3 of the cell.
    //  Width a touch wider than height (these blobs squish wide); the tighter height factor
    //   also keeps the guts BELOW the rim label's band.
    const INSCRIBE_W = 0.68, INSCRIBE_H = 0.62
    // UNIFORM INLAY SCALE (owner 2026-08-30: "all inlays need to be 1.6x the size, all uniformly").  The
    //  INSCRIBE rect above is the blob's honest interior; this multiplies the fit TARGET so every face —
    //   main and satellite, compact and stretched — fills ~1.6x that.  Content grows toward the blob's
    //    edge (the clip-path trims only the rounded CORNERS, which carry no centred text), and the
    //     stretched-cap below (min 1) still stops a full-width face scaling out past its own sides into
    //      the wall — so this enlarges without reviving the clipped-letter.  One knob: retune here.
    const INLAY_SCALE = 1.2
    //  THE CAP IS PER-ROLE (the owner, 2026-08-29: "it needs to resize the overlay glass, the
    //   Radio controls are taking up 1/5th of the area of the cell").  A compact-natural face
    //    (RadioFace's pill cluster) in an 860px belly needs to SCALE UP to fill its inscribed
    //     box — the screenshot's player is BIG in the big cell — so the main's cap must be well
    //      above 1.  Satellites keep the low cap: a bud glyph ballooned 3× is a cartoon.
    const FIT_MIN = 0.3, FIT_MAX_MAIN = 4.5, FIT_MAX_SAT = 1.85   // caps ×1.6 so INLAY_SCALE isn't clamped
    // STRETCHED CAP (owner 2026-08-30: "the Link innard is much smaller than it was, was looking really
    //  good").  A full-width (block-layout) face can't scale UP without its sides crossing the wall, but
    //   capping it at 1 shrank the Link badly.  1.3 lets it fill to the blob's widest point (~the cell
    //    edge at mid-height, where the column at 0.76·cell × 1.3 ≈ 1.0·cell) — big again — while still
    //     stopping the gross overflow that clipped whole letters.  Below the wall, not past it.
    const STRETCH_CAP = 1.3
    // DEAD-BAND WIDER (owner 2026-08-30: "Link's overlay glass … constantly re-measuring").  A live
    //  Face animates (LinkDevice's spinner/pills/SAS), and each pulse fired the fit at 2% — visible
    //   thrash.  6% + rounding the natural box to 6px absorbs the animation while still catching a
    //    real change (a panel unfolding is far past 6%).  The bigger structural fix is below: the
    //     scroll column no longer depends on --fit, so a fit change can't reflow the face and feed back.
    const FIT_DEADBAND = 0.06

    function measure_molds() {
        try {
            let next: Map<string, number> | null = null
            for (const [key, scroll] of molds) {
                if (!scroll?.isConnected) continue
                const child = scroll.firstElementChild as HTMLElement | null
                if (!child || typeof child.offsetWidth !== 'number') continue
                const mold = scroll.parentElement as HTMLElement | null
                if (!mold) continue
                const iw = mold.clientWidth * INSCRIBE_W * INLAY_SCALE, ih = mold.clientHeight * INSCRIBE_H * INLAY_SCALE
                // round the natural box to 6px so a 1-2px animation wobble in the Face can't nudge the fit
                const nw = Math.round(child.offsetWidth / 6) * 6, nh = Math.round(child.offsetHeight / 6) * 6
                if (!(nw > 0 && nh > 0 && iw > 0 && ih > 0)) continue
                // THE WEDGE (the owner: "its guts still get stuck not big enough sometimes… we need
                //  to do better there, that was one of the main incompetencies of Vyto").  The old
                //   box-stretched SKIP (|child.w − scroll.w| ≤ 1 ⇒ don't measure) wedged the fit at
                //    its first value: once --fit was applied, a block-layout face fills the widened
                //     scroll column exactly, so every later measure read "stretched" and bailed —
                //      stuck forever at a fit computed from a half-mounted face.  A stretched WIDTH
                //       says nothing (it echoes the column we set), but the HEIGHT is still the
                //        face's own answer at that column — so fit on height alone in that case
                //         rather than not at all.  Measures are CHEAP (a handful of offset reads on
                //          <10 cells), so we look often and let the dead-band keep it calm.
                const stretched = Math.abs(child.offsetWidth - scroll.clientWidth) <= 1
                const cap = key === main_key ? FIT_MAX_MAIN : FIT_MAX_SAT
                // NEVER SCALE A STRETCHED FACE *UP* (owner 2026-08-30: "the cell inlay left|right padding is
                //  not there at all, we're missing a letter off the text").  A stretched (block-layout) face
                //   already fills the scroll column width, so scaling it up by a HEIGHT-derived fit widens it
                //    PAST the inscribed rect into the wobbly wall — the clip-path trims the overflow and the
                //     first/last glyph vanishes, defeating the mold's 12% horizontal padding.  Cap the
                //      stretched case at 1 (fill the column at natural scale; shrink only if genuinely too
                //       tall).  A compact face still scales up on the min(width,height) term as before.
                const raw = stretched ? Math.min(STRETCH_CAP, ih / nh) : Math.min(iw / nw, ih / nh)
                const fit = Math.max(FIT_MIN, Math.min(cap, raw))
                const cur = fits.get(key) ?? 1
                if (Math.abs(fit - cur) / cur <= FIT_DEADBAND) continue   // dead-band damp
                if (!next) next = new Map(fits)
                next.set(key, fit)
            }
            if (next) fits = next
        } catch { /* a measure must never white-screen the glass */ }
    }

    // trailing-edge: a burst of resizes folds into ONE measure, off the flush (Vytui:3164-3171)
    let measure_pending: any = 0
    function measure_soon() {
        if (measure_pending || typeof setTimeout === 'undefined') return
        measure_pending = setTimeout(() => { measure_pending = 0; measure_molds() }, 140)
    }
    // the LATE LOOKS: 450ms + 900ms, for async content landing a beat later (Vytui:3177-3187)
    let measure_late: any = 0
    function measure_lately() {
        if (measure_late || typeof setTimeout === 'undefined') return
        measure_late = setTimeout(() => {
            measure_molds()
            measure_late = setTimeout(() => { measure_late = 0; measure_molds() }, 900)
        }, 450)
    }

    // ── EVENT LOOKS (the owner: "it needs to happen automatically sometimes too, like 0.1s,
    //  0.5s and periodically after any event like changing cell / maincell") ─────────────────
    //  The RO fires when a face's box MOVES, but a promote/demote/compact/off-edge flip changes
    //   the MOLD and the applicable cap without the face necessarily resizing first — and the
    //    remounted face's content often lands a beat after the flip.  So any such event gets an
    //     explicit quick-then-settled ladder: 100ms (the flip has painted) + 500ms (async guts
    //      landed).  All dead-band damped, so a look that finds nothing costs nothing.
    let event_looks: any[] = []
    function measure_on_event() {
        if (typeof setTimeout === 'undefined') return
        for (const t of event_looks) clearTimeout(t)
        event_looks = [
            setTimeout(measure_molds, 100),
            setTimeout(measure_molds, 500),
        ]
        measure_lately()   // + the 450/900 settle pair
    }
    $effect(() => {
        // any change of WHO is main, its size, or its stance is an event
        void main_key; void main_offedge
        measure_on_event()
    })
    // …and the PERIODIC look rides the existing 1s heartbeat: a cheap dead-banded sweep that
    //  catches anything the RO and the ladders missed (a face that grew without an event).
    $effect(() => {
        void now_tick
        measure_soon()
    })
    $effect(() => () => { for (const t of event_looks) clearTimeout(t) })

    // the shared observer + the action.  Rides each cell's .cello-face-scroll; OBSERVES the
    //  face's own root inside it (Vytui:3188-3209).
    let faceRO: ResizeObserver | null = null
    function sizewatch(el: HTMLElement, key: string) {
        if (typeof ResizeObserver === 'undefined') return
        if (!faceRO) faceRO = new ResizeObserver(() => { try { measure_soon(); measure_lately() } catch { /* an RO callback must never escape as an uncaught error */ } })
        let kid: Element | null = null
        let mykey = key
        molds.set(mykey, el)
        const attach = () => {
            // TORN-DOWN GUARD (owner 2026-08-30, Incogni: "threw on faceRO!.observe(kid) … after Link took us
            //  giantcell").  A giant-cell mount/unmount churns actions fast; the teardown $effect nulls faceRO, but a
            //   queued attach (queueMicrotask below, or a use:action update) can still fire after — then
            //    faceRO!.observe(kid) dereferences null.  Bail before touching the observer; the catch was the net,
            //     this is the fix.
            if (!faceRO) { kid = null; return }
            try {
                const k = el.firstElementChild
                if (k === kid) return
                if (kid) faceRO!.unobserve(kid)
                kid = k
                if (kid) faceRO!.observe(kid)
            } catch { /* no-op */ }
        }
        attach(); queueMicrotask(attach)
        measure_soon(); measure_lately()   // first look — the Face lands right after mount
        return {
            update(nk: string) {
                if (nk !== mykey) { molds.delete(mykey); mykey = nk; molds.set(mykey, el) }
                attach()
            },
            destroy() {
                try { if (kid) faceRO?.unobserve(kid) } catch { /* no-op */ }
                kid = null
                molds.delete(mykey)
            },
        }
    }

    // a MOLD size change (window resize, compact toggle, off-edge flip) is also a reason to
    //  re-fit — piggyback on the stage observer's seam rather than adding another RO.
    $effect(() => {
        void stage_w; void main_offedge
        measure_soon(); measure_lately()
    })

    // teardown — the shared observer + pending timers die with the component
    $effect(() => () => {
        try { faceRO?.disconnect() } catch { /* no-op */ }
        faceRO = null
        if (measure_pending) { clearTimeout(measure_pending); measure_pending = 0 }
        if (measure_late) { clearTimeout(measure_late); measure_late = 0 }
    })
</script>

<!-- ─────────────────────────────────────────────────────────────────────────── -->
<!-- CELLO STAGE                                                                  -->
<!-- One main cell (big or compact) + satellite blobs nestling along its right   -->
<!-- edge.  No layout math — CSS placement only.  Fills the tab (min-height 100vh)-->
<!-- ─────────────────────────────────────────────────────────────────────────── -->
<div class="cello-stage" class:narrow={narrow} class:offedge={main_offedge} bind:this={stage_el}>

    <!-- ── SHARED DEFS — the wallpaper pattern (Vytui.svelte:3777).  The photo is multiplied by
         the cell's own Matstyle ground (wall_tint) so it reads as a TEXTURE tinted to the cell's
          colour, not a pasted picture.  Keyed 'cello-sea' so Radio's blob fills with url(#cello-sea).
           One <defs> for the whole stage; every blob that wears paper references it. -->
    <svg class="cello-defs" width="0" height="0" aria-hidden="true">
        <defs>
            <pattern id="cello-sea" patternUnits="objectBoundingBox" patternContentUnits="objectBoundingBox"
                     width="1" height="1">
                <image href="/seapiano.webp" width="1" height="1" preserveAspectRatio="xMidYMid slice"></image>
                <rect width="1" height="1" fill={wall_tint('Radio')} opacity="0.62" style="mix-blend-mode: multiply;"></rect>
            </pattern>
        </defs>
    </svg>

    {#if main_cell}
        <!-- ── MAIN CELL ──────────────────────────────────────────────────── -->
        <!-- `offedge` = the really-big belly (screenshot RIGHT): its wall is oversized + left-anchored
             so it spills off the left/top/bottom, only the right portion showing.  Otherwise the
              centred-big look (screenshot LEFT).  POSE 'big' already stamped in the main_cell derived. -->
        <div
            class="cello-main"
            class:offedge={main_offedge}
            in:receive={{ key: main_cell?.key ?? last_main_key }}
            out:send={{ key: main_cell?.key ?? last_main_key }}
            style="
                --cell-bg:     {main_cell.colour.bg};
                --cell-fg:     {main_cell.colour.color};
                --cell-border: {main_cell.colour.border};
            "
        >
          <!-- SETTLE WRAPPER — the arrival spring (land) drives THIS wrapper's scale: a wound-up
               anticipation dip (~0.94) that releases past 1 and rings down.  It also publishes the
                swap ENERGY (0..1) as --swap-energy, which the wall reads to shiver with speed.  The
                 flight (crossfade) owns the OUTER .cello-main transform; this inner one MULTIPLIES,
                  so anticipation+overshoot compose with the cross-screen fly, never overwrite it. -->
          <div class="cello-settle" style="transform: scale({settle_scale}); --swap-energy: {swap_energy}; will-change: {swap_energy > 0.001 ? 'transform' : 'auto'};">
          <!-- DRIFT WRAPPER — the "rocks in your palm" motion rides an INNER transform so it composes
               with (never fights) the outer flex/position/switcheroo transitions.  Duration + phase are
                seeded per cell so neighbours drift out of sync and appear to turn about one another.
                 The main drifts most gently (it's the big stone at the bottom of the palm). -->
          <div class="cello-drift main-drift"
               style="--drift-dur:{drift_dur(main_cell.seed, 22)}s; animation-delay:{drift_delay(main_cell.seed)};">
            <!-- GUTS WRAPPER — the wall + face lag the body on a SOFTER spring (land_guts) so the
                 outline jiggles and the guts settle a beat AFTER the body lands: overlapping action,
                  the biggest alive tell.  A whisper of counter-tilt flexes the silhouette. -->
            <!-- offedge: the box is huge + shifted -40% left, so its transform-origin sits off-screen
                 and a rotate would swing the visible right arc wildly — drop the tilt there, keep the
                  scale follow-through only (the scale still reads as a settle beat behind the body). -->
            <div class="cello-guts" style="transform: scale({guts_scale}) rotate({main_offedge ? 0 : guts_tilt}deg); will-change: {swap_energy > 0.001 ? 'transform' : 'auto'};">
            <!-- THE BLOB — a single SVG path is BOTH the fill and the wall (the Vytui contract,
                 Vytui.svelte:3825): fill is the sea pattern for Radio, the Matstyle jewel otherwise;
                  a soft dark undercoat + a thin smooth jewel stroke on the same smooth Q-curve path.
                   preserveAspectRatio=none lets the 0..100 ring map onto the box.  A jewel-gradient
                    div sits UNDER for the roundness highlight (paper covers it on Radio). -->
            <div class="cello-body" style="clip-path: {main_blob};"></div>
            {#if main_wall}
                <svg class="cello-wall" viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden="true">
                    <path class="wall-fill" d={main_wall}
                          style={main_cell.paper ? `fill:url(#${main_cell.paper});` : 'fill:transparent;'} />
                    <path class="wall-underline" d={main_wall} />
                    <path class="wall-stroke" d={main_wall} />
                </svg>
            {/if}

            <!-- the Face, declarative mount inside the clipped mold -->
            {#if main_cell.face}
                {@const Face = main_cell.face}
                <div class="cello-face-mold" style="clip-path: {main_blob};">
                    <!-- sizewatch observes the Face's OWN root; --fit inscribes the guts into the
                         blob (lay out at 100%/--fit, scale back by --fit — Vytui:1258). -->
                    <div class="cello-face-scroll" class:scrollbig={main_offedge} use:sizewatch={main_cell.key}
                         style="--fit: {main_offedge ? 1 : (fits.get(main_cell.key) ?? 1)};">
                        <svelte:boundary>
                            <Face n={main_cell.n} H={H} />
                            {#snippet failed(error)}
                                <div class="cello-face-err" title={String(error)}>{main_cell.label}</div>
                            {/snippet}
                        </svelte:boundary>
                    </div>
                </div>
            {:else}
                <div class="cello-no-face">{main_cell.mk}</div>
            {/if}
            </div><!-- /.cello-guts -->

            <!-- rim label — rides the TOP RIM of the blob, over the wall (OUTSIDE guts so text
                 stays crisp — it shouldn't smear with the follow-through flex) -->
            <div class="cello-label">{main_cell.label}</div>

            <!-- (the ⊟/⊞ size toggle is gone — one size, big; the cast picks the stance) -->

            <!-- THE NO (Layer B) — shown only while THIS main holds the belly by an insistent
                 stage_want claim.  Pressing it refuses THAT ask (cell + want value): the pull
                  stops, focus falls back to the resting Radio, and the cell keeps its normal
                   seat.  A fresh ask (new want) gets a fresh hearing.  The durable serial
                    refusal against the %Idzeug issuer wires in behind refuse_ask (task #45). -->
            {#if insistent && insistent.key === main_cell.key}
                <button
                    class="cello-refuse"
                    title="no — refuse this ask (it stops pulling focus; a new ask may return)"
                    aria-label="refuse this ask"
                    onclick={() => refuse_ask(main_cell)}
                >no</button>
            {/if}
          </div><!-- /.cello-drift -->
          </div><!-- /.cello-settle -->
        </div>
    {:else}
        <div class="cello-empty">no cells</div>
    {/if}

    <!-- ── SATELLITE STRIP — smaller blobs nestling along the right edge ──── -->
    {#if satellites.length}
        <div class="cello-satellites">
            {#each satellites as cell (cell.key)}
                {@const tiny = false /* TODO: measure width < LABEL_FLOOR_W */}
                {@const nz = nudge_of(cell.key)}
                {@const held = dragging_key === cell.key}
                <button
                    class="cello-sat"
                    class:tiny={tiny}
                    class:held={held}
                    in:receive={{ key: cell.key }}
                    out:send={{ key: cell.key }}
                    animate:flip={{ duration: reduce_motion ? 0 : 420, easing: backOut }}
                    style="
                        --cell-bg:     {cell.colour.bg};
                        --cell-fg:     {cell.colour.color};
                        --cell-border: {cell.colour.border};
                        --nudge-x: {nz.dx}px; --nudge-y: {nz.dy}px; --nudge-s: {nz.scale};
                    "
                    onclick={() => switcheroo(cell)}
                    onpointerdown={(e) => sat_pointerdown(e, cell)}
                    onwheel={(e) => sat_wheel(e, cell)}
                    title={cell.label}
                    aria-label="switch to {cell.label}"
                >
                  <!-- NUDGE WRAPPER — the user's persisted drag-roll (--nudge-x/y) + wheel resize (--nudge-s),
                       off the resting flex slot.  It MOVED off the outer button onto this inner wrapper because
                        crossfade (in:receive/out:send) now owns the button's transform for the physical swap; a
                         nudge on the same outer element would fight the send/receive tween.  The drift wrapper
                          (rocks-in-palm) nests INSIDE this, so button-transform (swap) ⊃ nudge ⊃ drift compose. -->
                  <div class="cello-sat-nudge">
                  <!-- DRIFT WRAPPER — the rocks-in-palm wander, PAUSED while this stone is held so it
                       settles where it lands and resumes from there. -->
                  <div class="cello-drift" class:paused={held}
                       style="--drift-dur:{drift_dur(cell.seed, 16)}s; animation-delay:{drift_delay(cell.seed)};">
                    <div class="cello-body" style="clip-path: {cell.blob};"></div>
                    {#if cell.wall}
                        <svg class="cello-wall" viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden="true">
                            <path class="wall-fill" d={cell.wall}
                                  style={cell.paper ? `fill:url(#${cell.paper});` : 'fill:transparent;'} />
                            <path class="wall-underline" d={cell.wall} />
                            <path class="wall-stroke" d={cell.wall} />
                        </svg>
                    {/if}
                    {#if cell.face}
                        {@const Face = cell.face}
                        <!-- a satellite is small — pose 'small' already stamped in the satellites derived,
                             so the Face renders its bud glyph, not a folded player. -->
                        <div class="cello-sat-face" style="clip-path: {cell.blob};">
                            <!-- same fitting seam as the main: the bud glyph centres in ITS inscribed box -->
                            <div class="cello-face-scroll" use:sizewatch={cell.key}
                                 style="--fit: {fits.get(cell.key) ?? 1};">
                                <svelte:boundary>
                                    <Face n={cell.n} H={H} />
                                    {#snippet failed()}
                                        <div class="cello-face-err">{cell.mk}</div>
                                    {/snippet}
                                </svelte:boundary>
                            </div>
                        </div>
                    {:else}
                        <div class="cello-sat-mk">{cell.mk}</div>
                    {/if}
                    {#if !tiny}
                        <div class="cello-label sat">{cell.label}</div>
                    {/if}
                    <!-- HIT OVERLAY — a satellite is a PREVIEW, not a live control: its Face re-arms
                         pointer-events (DoorFace's peer rows are clickable), which would swallow the
                          promote-tap so the cell "stays a tiny icon" instead of switcheroo-ing to main.
                           This transparent layer sits ABOVE the face so a click ANYWHERE on the blob
                            promotes it (and starts a roll-drag); the face only becomes interactive once
                             it IS the main cell.  pointer-events on the overlay routes the tap/drag to
                              the button, not the inert preview underneath. -->
                    <span class="cello-sat-hit" aria-hidden="true"></span>
                  </div>
                  </div>
                </button>
            {/each}
        </div>
    {/if}

</div>

<style>
/* ── STAGE ─────────────────────────────────────────────────────────────────── */
/* Fills the tab — the owner's requirement: a proper look at one big thing, never a
   collapsed/tiny layout.  A dark WOVEN COPPER ground — the REAL copper_anodes.jpg texture
    (Vytui.svelte:4173-4177), a warm base (#6e4e2e) under a cool near-black radial veil so
     what survives is a warm GLINT rather than a hue, receding at the edges so the lit glass
      in the middle reads.  The two rgba alphas are the more/less-copper dial. */
.cello-stage {
    position: relative;
    display: flex;
    flex-direction: row;
    align-items: center;
    justify-content: center;
    width: 100%;
    min-height: 100vh;
    box-sizing: border-box;
    padding: 4vh 3vw;
    background-color: #6e4e2e;
    background-image:
        radial-gradient(135% 120% at 50% 42%, rgba(12, 15, 26, 0.82), rgba(4, 5, 10, 0.96) 72%),
        url(/i/copper_anodes.jpg);
    background-size: auto, 300px 300px;
    background-position: center, center;
    overflow: hidden;
    gap: 0;
}
/* the wallpaper pattern lives in a zero-size defs SVG — it must not take layout space */
.cello-defs { position: absolute; width: 0; height: 0; overflow: hidden; pointer-events: none; }

/* ── MAIN CELL ──────────────────────────────────────────────────────────────── */
/* A big organic blob.  The body, wall, mold and label are stacked absolutely; the
   .cello-main box is a plain rectangle that the pieces clip/trace themselves. */
.cello-main {
    position: relative;
    flex: 0 1 min(96vw, 1452px);   /* 10% wider (owner 2026-08-30); DOMINATES + WIDE like Vyto */
    aspect-ratio: 1.25 / 1;        /* 20% taller (owner 2026-08-30): lowered from 1.5 so the cell rises;
                                       still wide enough that a rectangular Face inscribes without its
                                        corners poking past the blob curve */
    max-height: 94vh;
    color: var(--cell-fg, #a8a8cc);
    transition: flex-basis 0.4s cubic-bezier(0.4, 0, 0.2, 1), max-height 0.4s ease;
    filter: drop-shadow(0 10px 30px rgba(0, 0, 0, 0.55));
}
/* ── OFF-EDGE BELLY (screenshot RIGHT) — the really-big cell anchored to the left, its
   oversized wall spilling off the left/top/bottom.  The .cello-main box grows past the
    viewport and shifts left; the oversized ring (main_edge_wall, scale 1.9, dx -60) is
     what actually paints, so only the right arc of the wall shows.  Satellites still float
      on the right via .cello-satellites.  clip:visible so the spilled wall isn't boxed. */
.cello-stage.offedge { justify-content: flex-start; }
/* ABSOLUTE + SPILLING (owner: it was "only taking the left 1/3, not underlapping the minicells").
   left -32vw so the wall arcs off the left.  RIGHT EDGE pulled IN off the viewport edge (owner
    2026-08-30: "the superbig's right edge is about at the right edge of the screen, so the minicells
     are inside it — bring it in a bit so the minicells look like they're sitting on it like a
      planetary body").  left -32 + width 120 = 88vw right edge, so the curved right limb passes UNDER
       the minicells' left side (satellites at right:2.5vw) and they perch on the bulge, sticking out
        into space on the right rather than being swallowed.  top/bottom spill ±9vh.  Absolute so it
         doesn't fight the flex row — the satellites are absolute in off-edge too. */
.cello-main.offedge {
    position: absolute;
    /* owner 2026-08-30 nudge: 10vw further LEFT, 8vw wider on the RIGHT (so the minicells now tuck a
       tiny bit UNDER the right edge at the screen edge, not perched clear of it), and ~11% taller at
        both the top and bottom spills.  left -42 + width 138 = 96vw right edge (was 88); top/bottom
         overhang ±15vh (was ±9).  The mold (left:40%/right:16%) and blob are box-relative, so they
          track these automatically. */
    left: -42vw;
    width: 138vw;
    top: -15vh;
    height: 130vh;
    max-height: none;
    margin: 0;
    flex: none;
    aspect-ratio: auto;
    z-index: 1;
}

/* ── SATELLITE STRIP ────────────────────────────────────────────────────────── */
/* The satellites nestle against the main cell's right edge — a small negative
   margin makes the wobbly walls overlap so it reads as "a blob among a blob",
    not a docked rail. */
.cello-satellites {
    position: relative;
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    justify-content: center;
    gap: 4px;
    margin-left: -6%;
    z-index: 2;
    flex: 0 0 auto;
}
/* OFF-EDGE — the main fills almost the whole stage, so the satellites can't be a flex
   sibling on the right (there's no room); pin them absolutely against the right edge,
    spread vertically along the big cell's visible right wall (screenshot RIGHT). */
.cello-stage.offedge .cello-satellites {
    position: absolute;
    right: 2.5vw;
    top: 50%;
    transform: translateY(-50%);
    margin-left: 0;
    gap: 4vh;
    z-index: 4;
}

/* ── NARROW EMBED — the ResizeObserver's `narrow` class.  Below the floor the row
   would overflow the side, so stack the satellites UNDER the main cell and let them
    nestle up against its bottom rim instead of its right edge.  No overflow, no break
     at any viewport. */
.cello-stage.narrow {
    flex-direction: column;
    padding: 3vh 4vw;
}
.cello-stage.narrow .cello-main {
    flex: 0 1 auto;
    width: min(78vw, 460px);
    aspect-ratio: 1 / 1;
}
.cello-stage.narrow .cello-satellites {
    flex-direction: row;
    align-items: flex-start;
    justify-content: center;
    margin-left: 0;
    margin-top: -6%;
    flex-wrap: wrap;
}
.cello-stage.narrow .cello-sat {
    width: clamp(96px, 26vw, 150px);
}

/* ── SATELLITE BLOB ─────────────────────────────────────────────────────────── */
.cello-sat {
    position: relative;
    width: clamp(96px, 10vw, 150px);   /* satellites clearly SMALL — widen the gap to the main */
    aspect-ratio: 1 / 1;
    background: transparent;
    color: var(--cell-fg, #a8a8cc);
    border: none;
    padding: 0;
    cursor: grab;
    filter: drop-shadow(0 6px 16px rgba(0, 0, 0, 0.5));
    /* NO transform here any more — crossfade (in:receive/out:send) OWNS the button transform to
       fly the blob into/out of the main slot (the physical swap).  The nudge (drag-roll + wheel
        resize) moved to the inner .cello-sat-nudge wrapper so it can't fight that tween. */
    touch-action: none;
    transition: width 0.4s ease;
    flex-shrink: 0;
}
/* the nudge wrapper — the user's persisted roll (--nudge-x/y) + wheel resize (--nudge-s), off the
   resting flex slot.  Inner to the button so the outer transform is free for the swap crossfade. */
.cello-sat-nudge {
    position: absolute;
    inset: 0;
    transform: translate(var(--nudge-x, 0px), var(--nudge-y, 0px)) scale(var(--nudge-s, 1));
    transition: transform 0.25s cubic-bezier(0.4, 0, 0.2, 1);
}
/* while HELD the transform must track the pointer with no lag — kill the settle transition */
.cello-sat.held { cursor: grabbing; z-index: 5; }
.cello-sat.held .cello-sat-nudge { transition: none; }
.cello-sat:hover { z-index: 3; }
.cello-sat:hover .wall-stroke { stroke-width: 2.2; }
.cello-sat:focus-visible { outline: none; }
.cello-sat:focus-visible .wall-stroke { stroke: #ffd479; stroke-width: 3.2; }
.cello-sat.tiny { width: clamp(72px, 9vw, 110px); }

/* the promote hit-target — above the (inert-preview) face so a tap anywhere switcheroos.  It fills
   the whole blob so a click|drag ANYWHERE on the stone routes to the button (never the inert Face). */
.cello-sat-hit { position: absolute; inset: 0; z-index: 6; pointer-events: auto; background: transparent; }

/* ── THE SWAP SETTLE + FOLLOW-THROUGH WRAPPERS ─────────────────────────────────
   Two nested inner wrappers driven by the `land`/`land_guts` springs.  They live BETWEEN the
    outer .cello-main (which the flight crossfade owns) and the .cello-drift (ambient), so the
     arrival anticipation-dip+overshoot and the wall/guts follow-through MULTIPLY with — never
      overwrite — the fly and the drift.  transform + opacity only (GPU).  will-change is set
       INLINE and only while the spring has energy, so it's `auto` at rest (no idle GPU layer). */
.cello-settle {
    position: absolute;
    inset: 0;
    transform-origin: 50% 62%;   /* pivot low — the stone settles onto its base, like the drift */
}
/* ── GUTS — the FOLLOW-THROUGH clock (principle 5).  Wraps the body + wall + face, driven by the
   softer/laggier land_guts spring (lower stiffness than the outer .cello-settle body spring): while
    .cello-settle has sprung out and calmed, this layer is still catching up ~a beat behind, so the
     silhouette jiggles and the face settles late relative to the arrival.  The label + refuse pill
      sit OUTSIDE this (crisp text mustn't smear).  A whisper of counter-tilt flexes the stone. */
.cello-guts {
    position: absolute;
    inset: 0;
    transform-origin: 50% 55%;
}
/* SECONDARY ACTION (principle 6) — the wall stroke thickens + brightens with swap ENERGY, so the
   silhouette visibly shivers while the stone is in motion and calms as it lands.  Pure paint; the
    energy is the live spring's distance-to-rest, so the edge pulse-thickens in time with the ring,
     honest coupling to speed rather than a fixed keyframe. */
/* 3-class selectors so these BEAT the later, equal-source-order `.cello-wall .wall-stroke` base
   (2 classes) — otherwise the base's flat stroke-width clobbers the energy coupling.  The base's
    160ms stroke-width transition still applies (inherited), gently low-passing the ring so the
     edge pulses smoothly rather than jittering frame-to-frame. */
.cello-settle .cello-wall .wall-stroke {
    stroke-width: calc(1.6px + var(--swap-energy, 0) * 2.2px);
    stroke: color-mix(in srgb, var(--cell-border, #6a6ad0) calc(100% - var(--swap-energy,0)*35%), #fff calc(var(--swap-energy,0)*35%));
}
.cello-settle .cello-wall .wall-underline {
    stroke-width: calc(3.4px + var(--swap-energy, 0) * 2px);
}
@media (prefers-reduced-motion: reduce) {
    /* springs are already pinned to rest in JS; belt-and-braces the wrappers to identity so no
       residual scale/tilt survives, and the wobble collapses to the resting stroke width. */
    .cello-settle, .cello-guts { transform: none !important; }
    .cello-settle .cello-wall .wall-stroke  { stroke-width: 1.6px; }
    .cello-settle .cello-wall .wall-underline { stroke-width: 3.4px; }
}

/* ── DRIFT — "rocks in your palm": a slow, weighty, seeded loop that turns each stone about its
   own space so neighbours appear to jostle/orbit one another.  Small amplitude (a few px + a few
    degrees), ease-in-out, infinite; rides an INNER wrapper so it never fights the outer flex,
     switcheroo, off-edge or nudge transforms.  Paused while a stone is held (settles where it lands). */
.cello-drift {
    position: absolute;
    inset: 0;
    transform-origin: 50% 60%;   /* pivot low, like a stone resting in a cupped palm */
    animation: cello-roll var(--drift-dur, 20s) ease-in-out infinite;
    will-change: transform;
}
.cello-drift.main-drift { animation-name: cello-roll-main; }
.cello-drift.paused { animation-play-state: paused; }
@keyframes cello-roll {
    0%   { transform: translate(0, 0) rotate(0deg); }
    25%  { transform: translate(2.2%, -1.4%) rotate(1.6deg); }
    50%  { transform: translate(0.4%, 1.8%) rotate(-0.8deg); }
    75%  { transform: translate(-2%, 0.6%) rotate(-1.8deg); }
    100% { transform: translate(0, 0) rotate(0deg); }
}
/* the big stone at the bottom of the palm barely stirs — a whisper of the same motion */
@keyframes cello-roll-main {
    0%   { transform: translate(0, 0) rotate(0deg); }
    33%  { transform: translate(0.5%, -0.4%) rotate(0.35deg); }
    66%  { transform: translate(-0.4%, 0.5%) rotate(-0.3deg); }
    100% { transform: translate(0, 0) rotate(0deg); }
}
@media (prefers-reduced-motion: reduce) {
    .cello-drift { animation: none; }
}

/* ── BLOB BODY (jewel fill) ──────────────────────────────────────────────────── */
/* The dim jewel ground.  A soft radial highlight gives the blob a little roundness
   so it reads as a body, not a flat sticker (charm, restrained). */
.cello-body {
    position: absolute;
    inset: 0;
    background:
        radial-gradient(ellipse 90% 80% at 42% 34%,
            color-mix(in srgb, var(--cell-bg, #141420) 78%, #ffffff 12%) 0%,
            var(--cell-bg, #141420) 55%,
            color-mix(in srgb, var(--cell-bg, #141420) 88%, #000000 20%) 100%);
    pointer-events: none;
}

/* ── THE WALL — drawn gold/jewel outline (an SVG path, not a box-shadow) ─────── */
.cello-wall {
    position: absolute;
    inset: 0;
    width: 100%;
    height: 100%;
    pointer-events: none;
    overflow: visible;
    z-index: 1;
}
/* the FILL path — the wallpaper texture (Radio) painted inside the smooth wall; transparent
   for a jewel cell (the .cello-body gradient shows through).  Draws first, under the strokes. */
.cello-wall .wall-fill {
    stroke: none;
}
/* a dark undercoat behind the jewel line lifts it off the ground (Vytui's wallband
   idea: a fat dark stroke under the coloured one so the outline never fights the fill) */
.cello-wall .wall-underline {
    fill: none;
    stroke: rgba(6, 6, 12, 0.5);
    stroke-width: 3.4;
    stroke-linejoin: round;
    stroke-linecap: round;
    vector-effect: non-scaling-stroke;
}
/* a THIN, smooth, jewel-coloured outline (gold Radio / purple Door / green Link) — the screenshot's
   hairline gold rim, not a fat frame. */
.cello-wall .wall-stroke {
    fill: none;
    stroke: var(--cell-border, #6a6ad0);
    stroke-width: 1.6;
    stroke-linejoin: round;
    stroke-linecap: round;
    vector-effect: non-scaling-stroke;
    transition: stroke 160ms ease, stroke-width 160ms ease;
}
.cello-main:hover .wall-stroke,
.cello-sat:hover .wall-stroke {
    stroke: color-mix(in srgb, var(--cell-border, #6a6ad0) 70%, #ffffff 30%);
}

/* ── RIM LABEL ──────────────────────────────────────────────────────────────── */
/* Rides the TOP RIM of the blob, in the cell's own jewel ink — Vytui's .ident
   register (legible, 600 weight), with a dark halo so it reads over the fill. */
.cello-label {
    position: absolute;
    top: 3%;
    left: 50%;
    transform: translateX(-50%);
    font: 600 clamp(0.72rem, 1.1vw, 0.95rem)/1 system-ui, sans-serif;
    letter-spacing: 0.06em;
    color: color-mix(in srgb, var(--cell-fg, #a8a8cc) 82%, #ffffff 18%);
    text-shadow: 0 1px 3px rgba(0, 0, 0, 0.85), 0 0 6px rgba(0, 0, 0, 0.6);
    white-space: nowrap;
    pointer-events: none;
    z-index: 4;
}
.cello-label.sat {
    top: 5%;
    font-size: clamp(0.62rem, 0.9vw, 0.8rem);
}
/* OFF-EDGE — the blob's true top-centre is off the top edge, so the centred rim label would
   float in the void above the page.  The off-edge Face carries its own title (screenshot RIGHT
    "Link Device"), so drop the rim label + size toggle for the belly and let the Face speak. */
.cello-main.offedge .cello-label { display: none; }

/* (the ⊟/⊞ size-toggle styles went with the button — one size, big) */

/* ── THE NO — the refuse affordance on an insistently-claimed belly.  Deliberately quiet
   (it must be findable, not a competing call-to-action): a small pill at the rim's corner,
    warm-red ink, full opacity only on hover. */
.cello-refuse {
    position: absolute;
    top: 6%;
    right: 16%;
    background: rgba(26, 8, 8, 0.55);
    border: 1px solid #a05050;
    color: #e0a0a0;
    font: 600 0.72rem/1 system-ui, sans-serif;
    letter-spacing: 0.05em;
    border-radius: 999px;
    padding: 3px 9px;
    cursor: pointer;
    opacity: 0.65;
    z-index: 5;
    transition: opacity 0.15s, background 0.15s;
}
.cello-refuse:hover { opacity: 1; background: rgba(60, 14, 14, 0.75); }
.cello-main.offedge .cello-refuse { top: 12%; right: 8%; }

/* ── FACE MOLD (inside the blob) ─────────────────────────────────────────────── */
/* The mold is clipped to the SAME blob so the Face content stays inside the wobbly
   wall.  pointer-events:none on the mold (Vytui contract — the mold rectangle must
    never eat a press meant for a neighbour); the face's own buttons re-arm auto. */
.cello-face-mold {
    position: absolute;
    inset: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    pointer-events: none;
    z-index: 2;
    /* clip-path set inline to the blob polygon */
    box-sizing: border-box;
    padding: 12% 12% 8%;   /* keep the face off the wobbly wall + clear the rim label */
}
/* OFF-EDGE — the mold is centred in the box, but the box is huge + shifted left, so a centred
   Face lands off-screen.  Pin the off-edge Face to the VISIBLE right portion of the box (the
    right arc of the spilled wall), roughly matching the shifted ring so the player reads inside
     the visible cell.  Padding keeps it off the wall + top/bottom spill. */
/* OFF-EDGE FACE — pinned to the VISIBLE right area of the spilling box (left of the minicells),
   TOP-anchored, and it SCROLLS rather than --fit-shrinks (owner 2026-08-30: the Link overlay glass
    "aligns with the left center or top and scroll, with the copper anode fat handled global style
     scrollbar").  The box right edge is at 100vw; right:16vw of the box ⇒ the face's right edge at
      ~84vw, clear of the minicells at ~97vw. */
.cello-main.offedge .cello-face-mold {
    /* box spans viewport ~-32vw..100vw; left 40% / right 16% centres the mold on the viewport (owner:
       the overlay component should be "in the middle... ish"), clear of the minicells on the far right */
    left: 40%;
    right: 16%;
    top: 7vh;
    bottom: 7vh;
    transform: none;
    width: auto;
    height: auto;
    padding: 1% 1.5%;
    align-items: flex-start;      /* TOP-anchored (owner: "aligns with the … top and scroll") */
    justify-content: center;      /* horizontally centred-ish */
}
/* the off-edge face SCROLLS at natural size (no --fit scale — the template forces --fit:1 here) and
   wears the copper fat scrollbar (.scrollbig, app.css) via a class bound on the element.  It re-arms
    pointer-events (the mold is inert by contract) so the wheel/drag scrolls it. */
.cello-main.offedge .cello-face-scroll {
    width: 100%;
    height: 100%;
    align-items: stretch;
    justify-content: flex-start;
    transform: none;              /* takeover cells scroll; they do NOT scale-to-fit */
    overflow-y: auto;
    overflow-x: hidden;
    pointer-events: auto;
}

.cello-sat-face {
    position: absolute;
    inset: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    pointer-events: none;
    z-index: 2;
    box-sizing: border-box;
    padding: 20% 14% 12%;
    font-size: 0.68em;
}
/* the face itself, chromeless (Vytui .face-scroll) — THE --fit TRICK (Vytui:1258): the layout
   width and the zoom are SEPARATE variables.  The scroll lays out at a WIDER virtual column
    (100% / --fit) and scales back by --fit, so the face keeps its own layout and its natural
     box lands inside the blob's inscribed rect — never cramped, never spilling over the wobbly
      wall.  --fit is stamped inline per cell by measure_molds (dead-band damped); default 1.
   Height stays natural (the mold's flex centres it), so the measured offsetHeight is the face's
    own answer, not an echo of the mold.  No overflow:hidden — the mold's clip-path is the wall. */
.cello-face-scroll {
    display: flex;
    align-items: center;
    justify-content: center;
    /* THE COLUMN NO LONGER DEPENDS ON --fit (owner: "constantly re-measuring").  It was
       `calc(100%/--fit)`, so a fit change WIDENED the column, reflowed the face, changed its
        measured height and fed straight back into --fit — a limit cycle a live/animated Face
         (LinkDevice) never escaped.  Fixed column (100% of the inscribed mold) + scale-only:
          --fit can't reflow the face, so the measure converges and stays put.  A scaled-up face
           overflows into the wall, which the mold's clip-path already trims. */
    width: 100%;
    transform: scale(var(--fit, 1));
    transform-origin: center;
    flex: 0 0 auto;
    line-height: 1.35;
    transition: transform 0.25s cubic-bezier(0.4, 0, 0.2, 1);
}

/* ── ERROR / FALLBACK TEXT ──────────────────────────────────────────────────── */
.cello-face-err {
    font-size: 0.75rem;
    color: #d08a8a;
    font-weight: 600;
    padding: 8px;
    pointer-events: none;
}
.cello-no-face,
.cello-sat-mk {
    position: absolute;
    inset: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    font: 600 0.8rem system-ui, sans-serif;
    color: var(--cell-fg, #a8a8cc);
    opacity: 0.7;
    text-align: center;
    pointer-events: none;
    z-index: 2;
}
.cello-empty {
    color: #555;
    font-size: 0.85rem;
    padding: 24px;
    align-self: center;
}
</style>
