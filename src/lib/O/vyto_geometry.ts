// vyto_geometry.ts — the proven geometry toolbox lifted out of Cytui (workingout:
//  spec/vyto_workingouts/shapes.md §0), as PURE functions: no Svelte, no $state, no
//   side effects.  Two callers import it — the model's cell solver (Ghost/V/Vyto.g,
//    Vyto_solve) and the render side's per-frame wall re-derivation (Vytui.svelte) —
//     so both cut cells against byte-identical math and a moment can never disagree
//      with the pixels it was captured beside.
//  The behaviour is Cytui's verbatim: the weighted half-plane cut with a wall at
//   t = (d² + rᵢ² − rⱼ²)/(2d) along each seed-to-seed line, a null slot for a
//    crowded-out seed, a gap inset toward the polygon's vertex mean, and shoelace
//     moments for area and the true area centroid — primitives moved, not reinvented.

export type Pt = { x: number, y: number }
type Rect = { x: number, y: number, w: number, h: number }

// Sutherland–Hodgman against one wall: keep the side the seed is on — every vertex p
//  with dot(p − m, dir) ≤ 0, splicing the crossing point on each edge that straddles
//   the wall.  The single clip every cut is built from.
export function clip_halfplane(poly: Pt[], m: Pt, dir: Pt): Pt[] {
    const out: Pt[] = []
    for (let k = 0; k < poly.length; k++) {
        const a = poly[k], b = poly[(k + 1) % poly.length]
        const da = (a.x - m.x) * dir.x + (a.y - m.y) * dir.y
        const db = (b.x - m.x) * dir.x + (b.y - m.y) * dir.y
        if (da <= 0) out.push(a)
        if ((da <= 0) !== (db <= 0)) {
            const t = da / (da - db)
            out.push({ x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t })
        }
    }
    return out
}

// weighted power cut: tessellate a convex polygon by weighted seeds.  The wall between
//  seeds i and j sits at t = (d² + rᵢ² − rⱼ²)/(2d) along the i→j line — the radical
//   plane of the two power circles, the power diagram's defining cut (a bigger radius
//    pushes the wall away, claiming more room).  A seed clipped below a triangle by its
//     neighbours is crowded out and returns null (the caller draws it as a bare disc).
//      Each surviving polygon is inset toward its own vertex mean by `gap` so cells breathe.
export function power_cells(poly0: Pt[], pts: Pt[], radii: number[], gap: number): (Pt[] | null)[] {
    return pts.map((p, i) => {
        let poly: Pt[] = poly0
        for (let j = 0; j < pts.length; j++) {
            if (j === i) continue
            const dx = pts[j].x - p.x, dy = pts[j].y - p.y
            const d = Math.hypot(dx, dy)
            if (d < 0.5) continue
            const ux = dx / d, uy = dy / d
            const t = (d * d + radii[i] * radii[i] - radii[j] * radii[j]) / (2 * d)
            poly = clip_halfplane(poly, { x: p.x + ux * t, y: p.y + uy * t }, { x: ux, y: uy })
            if (poly.length < 3) return null
        }
        if (poly.length < 3) return null
        const vmx = poly.reduce((a, q) => a + q.x, 0) / poly.length
        const vmy = poly.reduce((a, q) => a + q.y, 0) / poly.length
        return poly.map(q => {
            const dx = q.x - vmx, dy = q.y - vmy, dd = Math.hypot(dx, dy)
            const k = dd > gap ? 1 - gap / dd : 0
            return { x: vmx + dx * k, y: vmy + dy * k }
        })
    })
}

// THE SLAB SEAT (the owner 2026-08-09: *"notice when the sides of the cell aren't square... pick the
//  two parallelest sides that the box aligns between to consume the most space of the cell"* — and
//   *"we used to jam things in sideways"*).  A voronoi cell is rarely axis-aligned, so an axis-aligned
//    seat wastes it; but nearly every power cell has a pair of near-antiparallel walls (shared walls
//     come in opposing pairs by construction).  Find the MOST antiparallel pair, weighted by how much
//      wall they actually offer (long parallel walls beat a short accidental pair), and return the slab
//       they bound: unit direction `u` ALONG the slab, centre of the cell's extent, thickness `t`
//        across it and length `len` along it.  The caller lays the component's box along `u`, filling
//         `t`, free to overrun `len` a little (overflow is allowed; hover top-mostity resolves it).
//  Pure and renderer-agnostic: extents are computed over the WHOLE polygon projected on the slab axes,
//   so even when the two chosen edges are not the exact support lines the slab still contains the cell.
//  Returns null when no pair is parallel within `minPar` (a triangle-ish cell) — the caller falls back
//   to the axis-aligned seat.
export function slab_seat(poly: Pt[], minPar = 0.8): { ux: number, uy: number, cx: number, cy: number, t: number, len: number } | null {
    const n = poly.length
    if (n < 4) return null
    // edge directions + lengths
    const dirs: Pt[] = [], lens: number[] = []
    for (let i = 0; i < n; i++) {
        const a = poly[i], b = poly[(i + 1) % n]
        const dx = b.x - a.x, dy = b.y - a.y, l = Math.hypot(dx, dy)
        dirs.push(l > 0 ? { x: dx / l, y: dy / l } : { x: 1, y: 0 })
        lens.push(l)
    }
    let best = -Infinity, bi = -1, bj = -1
    for (let i = 0; i < n; i++) for (let j = i + 1; j < n; j++) {
        const par = -(dirs[i].x * dirs[j].x + dirs[i].y * dirs[j].y)   // 1 = perfectly antiparallel
        if (par < minPar) continue
        const score = (par - minPar) * (lens[i] + lens[j])
        if (score > best) { best = score; bi = i; bj = j }
    }
    if (bi < 0) return null
    // slab direction: edge i's direction averaged with edge j's REVERSED direction
    let ux = dirs[bi].x - dirs[bj].x, uy = dirs[bi].y - dirs[bj].y
    const ul = Math.hypot(ux, uy)
    if (!(ul > 0)) return null
    ux /= ul; uy /= ul
    const nx = -uy, ny = ux
    let minU = Infinity, maxU = -Infinity, minN = Infinity, maxN = -Infinity
    for (const p of poly) {
        const pu = p.x * ux + p.y * uy, pn = p.x * nx + p.y * ny
        if (pu < minU) minU = pu
        if (pu > maxU) maxU = pu
        if (pn < minN) minN = pn
        if (pn > maxN) maxN = pn
    }
    const mu = (minU + maxU) / 2, mn = (minN + maxN) / 2
    return { ux, uy, cx: mu * ux + mn * nx, cy: mu * uy + mn * ny, t: maxN - minN, len: maxU - minU }
}

// ── THE FOAM CUT — coverage is EARNED BY PRESSURE, not granted by the frame ──────────────────────
// The owner's picture (2026-08-09): *"balls. shoving into your face. more balls inside each of them,
//  wires amongst them"* — and, earlier the same evening, *"everything mozaic'd nicely"*.  Those are
//   not two renderers; they are two PRESSURES of one thing, and the thing is soap foam: a lone
//    bubble is round, two touching bubbles share one flat wall, a packed froth is a polygon mosaic
//     whose outer silhouette stays curved.  power_cells above carves the whole frame top-down, so
//      three unrelated cells become three giant slabs and the tessellation says nothing.  foam_cells
//       grows the picture bottom-up: every cell starts as its OWN DISC (polygonised), and each
//        neighbour's radical-axis wall (the identical power-diagram cut) only trims it where the two
//         discs actually press — d < rᵢ + rⱼ.  Isolated ⇒ a circle.  Kissing ⇒ a lens wall.  Packed
//          ⇒ the interior tiles like power_cells while the pile's rim stays round.  Emptiness
//           finally MEANS something: uncovered frame is uncrowded world.
//  Same primitives as the frame cut (clip_halfplane, the same t), so a foam glass and a frame glass
//   can never disagree about where a shared wall sits — only about what happens where nothing does.
//  `frame` is optional: pass it to keep the foam inside the viewport; omit it for a free pile.
//  Deterministic, pure, no clock — a Book can drive it and vyto_see can rasterise the result.
export function foam_cells(pts: Pt[], radii: number[], gap: number, frame?: Pt[] | null, segs = 28): (Pt[] | null)[] {
    return pts.map((p, i) => {
        const R = Math.max(0, radii[i] - gap / 2)
        if (!(R > 0)) return null
        // the ball itself — the cell's birthright, before any neighbour presses on it
        let poly: Pt[] = []
        for (let s = 0; s < segs; s++) {
            const a = (s / segs) * 2 * Math.PI
            poly.push({ x: p.x + R * Math.cos(a), y: p.y + R * Math.sin(a) })
        }
        for (let j = 0; j < pts.length; j++) {
            if (j === i) continue
            const dx = pts[j].x - p.x, dy = pts[j].y - p.y
            const d = Math.hypot(dx, dy)
            if (d < 0.5) continue
            if (d >= radii[i] + radii[j]) continue          // not pressing — no wall, the arc survives
            const ux = dx / d, uy = dy / d
            const t = (d * d + radii[i] * radii[i] - radii[j] * radii[j]) / (2 * d) - gap / 2
            poly = clip_halfplane(poly, { x: p.x + ux * t, y: p.y + uy * t }, { x: ux, y: uy })
            if (poly.length < 3) return null
        }
        if (frame && frame.length >= 3) {
            for (let k = 0; k < frame.length; k++) {
                const a = frame[k], b = frame[(k + 1) % frame.length]
                const ex = b.x - a.x, ey = b.y - a.y, el = Math.hypot(ex, ey) || 1
                // inward normal for a CCW frame; the cut keeps the seed's side either way
                const nx = ey / el, ny = -ex / el
                const side = (p.x - a.x) * nx + (p.y - a.y) * ny
                const dir = side > 0 ? { x: -nx, y: -ny } : { x: nx, y: ny }
                poly = clip_halfplane(poly, a, dir)
                if (poly.length < 3) return null
            }
        }
        return poly
    })
}

// pile_step — one deterministic beat of the PILE: gravity toward the bag's centre, wire-springs
//  along the %Flow edges (rest length = kissing distance, so meaning pulls balls INTO contact and
//   contact makes walls), and positional separation where discs overlap deeper than the foam wants.
//  All displacements are read from ONE input snapshot and applied together, so the result is
//   independent of seat order (the pull_step discipline) — no clock, no randomness, Book-drivable.
//  The equilibrium this seeks IS the owner's picture: related balls press into a mosaic pile,
//   unrelated balls settle at the rim or float free — "cyto's mesh bagging and piling up of bodies",
//    re-had as physics instead of a compound node.
export function pile_step(
    seeds: Pt[], radii: number[], centre: Pt,
    nbrs: Array<{ j: number, w: number }[] | null | undefined>,
    k = { g: 0.02, s: 0.06, sep: 0.5, squeeze: 0.85 },
): Pt[] {
    const n = seeds.length
    const dx = new Array(n).fill(0), dy = new Array(n).fill(0)
    for (let i = 0; i < n; i++) {
        // gravity — every ball wants the bag's heart
        dx[i] += k.g * (centre.x - seeds[i].x)
        dy[i] += k.g * (centre.y - seeds[i].y)
        // wires — spring toward kissing distance with each related ball
        const ns = nbrs[i]
        if (ns) for (const nb of ns) {
            const q = seeds[nb.j]; if (!q) continue
            const vx = q.x - seeds[i].x, vy = q.y - seeds[i].y
            const d = Math.hypot(vx, vy) || 1
            const rest = (radii[i] + radii[nb.j]) * 1.02
            const f = k.s * Math.min(2, nb.w) * (d - rest) / d
            dx[i] += f * vx; dy[i] += f * vy
        }
    }
    // separation — a press is welcome (squeeze < 1 leaves the overlap the walls are cut from),
    //  but past the squeeze the pile pushes back, half the excess each
    for (let i = 0; i < n; i++) for (let j = i + 1; j < n; j++) {
        const vx = seeds[j].x - seeds[i].x, vy = seeds[j].y - seeds[i].y
        const d = Math.hypot(vx, vy)
        const want = (radii[i] + radii[j]) * k.squeeze
        if (!(d > 0) || d >= want) continue
        const push = k.sep * (want - d) / d / 2
        dx[i] -= push * vx; dy[i] -= push * vy
        dx[j] += push * vx; dy[j] += push * vy
    }
    return seeds.map((p, i) => ({ x: p.x + dx[i], y: p.y + dy[i] }))
}

// shoelace signed area — Σ(pₖ × pₖ₊₁) / 2.  The sign follows winding; readers wanting
//  magnitude take Math.abs.

// pile_rest — THE PILE, AT REST (extracted from Vyto_solve 2026-10-03, so the hand's law is node-testable;
//  the owner: *"weird how singular this code is"*).  Iterates pile_step to its fixed point — bounded at 400,
//   quit when the largest move falls under 0.05 (both MEASURED, see Vyto_solve's note) — restoring PINS after
//    every step (pile_step stays pin-blind and pure) and pulling every PUT seed toward where the hand put it
//     (hand_pull, an attractor; a pinned put is already in `pinned`).  Same arithmetic, same order as the
//      loop it replaced, so every recorded world solves byte-identically.
export type HandAt = { x: number, y: number, k: number }
export function hand_pull(s: Pt, at: HandAt): Pt {
    return { x: s.x + at.k * (at.x - s.x), y: s.y + at.k * (at.y - s.y) }
}
export function pile_rest(
    seeds: Pt[], radii: number[], centre: Pt,
    nbrs: Array<{ j: number, w: number }[] | null | undefined>,
    pinned: boolean[], puts?: (HandAt | null)[] | null,
): Pt[] {
    let pk = 0
    while (pk < 400) {
        const next = pile_step(seeds, radii, centre, nbrs || [])
        let moved = 0
        for (let pi = 0; pi < seeds.length; pi++) {
            if (pinned[pi]) next[pi] = seeds[pi]
            else if (puts && puts[pi]) next[pi] = hand_pull(next[pi], puts[pi]!)
            const dd = Math.abs(next[pi].x - seeds[pi].x) + Math.abs(next[pi].y - seeds[pi].y)
            if (dd > moved) moved = dd
        }
        seeds = next
        pk = pk + 1
        if (moved < 0.05) pk = 999
    }
    return seeds
}

export function poly_area(poly: Pt[]): number {
    let A2 = 0
    for (let i = 0; i < poly.length; i++) {
        const p = poly[i], q = poly[(i + 1) % poly.length]
        A2 += p.x * q.y - q.x * p.y
    }
    return A2 / 2
}

// shoelace area centroid — the true centroid of the FILLED polygon (∫x dA / A), not the
//  cheaper vertex mean.  A degenerate polygon (near-zero area — a sliver or a collapsed
//   cut) falls back to the vertex mean, the same guard Cytui takes at |A| ≤ 1.
export function poly_centroid(poly: Pt[]): Pt {
    let A2 = 0, sx = 0, sy = 0
    for (let i = 0; i < poly.length; i++) {
        const p = poly[i], q = poly[(i + 1) % poly.length]
        const cr = p.x * q.y - q.x * p.y
        A2 += cr
        sx += (p.x + q.x) * cr
        sy += (p.y + q.y) * cr
    }
    const A = A2 / 2
    if (Math.abs(A) > 1) return { x: sx / (6 * A), y: sy / (6 * A) }
    const n = poly.length || 1
    return { x: poly.reduce((a, q) => a + q.x, 0) / n, y: poly.reduce((a, q) => a + q.y, 0) / n }
}

// distance from p to the segment ab
function seg_dist(a: Pt, b: Pt, p: Pt): number {
    const dx = b.x - a.x, dy = b.y - a.y, l2 = dx * dx + dy * dy
    let t = l2 > 0 ? ((p.x - a.x) * dx + (p.y - a.y) * dy) / l2 : 0
    t = Math.max(0, Math.min(1, t))
    return Math.hypot(p.x - (a.x + t * dx), p.y - (a.y + t * dy))
}

// THE MEMBRANE CARVE (2026-09-12, the owner: *"cells have to be made with pinches tucked into these
//  merges… like it's stretched over a protrusion, and that protrusion has some shoulders"*).  A post-cut
//   carve on one family: `mi` is the membrane's seat (Vyto_membrane — the small body at the family's
//    heart), `petals` its members.  The cut cannot be trusted to seat the bump — the fill economy scales
//     every radius but no distance, so three big petals pressing at kissing distance swallow a small
//      body between them outright (seen live: "NO ROOM Membrane:Song" at the heart of a perfect
//       rosette).  So the bump is DEALT, not solved: its cell is the disc (centre, rb), and each petal
//        is clipped to the tangent line at rb along its own ray from the centre — the tip it loses is
//         the room the bump takes.  With `pinch` > 0 the straight tangent wall becomes a NECK: its two
//          ends A, B (the shoulders) are kept and the wall is re-drawn from A in to A′ on the disc,
//           along the arc to B′, and out to B — A′/B′ being A/B's angles pulled toward the ray by
//            `pinch` (0.55 ⇒ the neck wraps 55% of the wall's sweep onto the bump).  Between two
//             necks a wedge of the disc shows through: the pinch, and the eye reads each petal as
//              narrowing INTO the bump — what is joined to what, said by shape.
//  In place on `polys`.  A petal the tangent line does not cross (it stands off the bump) is left
//   whole — it is not stitched, and the shape should say so honestly.
export function membrane_carve(polys: (Pt[] | null)[], mi: number, petals: number[], centre: Pt, rb: number, pinch = 0.55, segs = 6): boolean {
    if (!(rb > 3)) return false
    const c = centre
    const wrap = (a: number): number => { while (a > Math.PI) a -= 2 * Math.PI; while (a <= -Math.PI) a += 2 * Math.PI; return a }
    let carved = 0
    for (const k of petals) {
        if (k === mi) continue
        const P = polys[k]
        if (!P || P.length < 3) continue
        const pc = poly_centroid(P)
        const th = Math.atan2(pc.y - c.y, pc.x - c.x)
        const u = { x: Math.cos(th), y: Math.sin(th) }
        // keep dot(p − c, u) ≥ rb: the wall is the tangent line at rb, the seed side is the far side
        const m = { x: c.x + u.x * rb, y: c.y + u.y * rb }
        const Q = clip_halfplane(P, m, { x: -u.x, y: -u.y })
        if (Q.length < 3 || Q.length === P.length && Q.every((q, i) => q === P[i])) continue
        carved++
        if (!(pinch > 0)) { polys[k] = Q; continue }
        // the two vertices on the tangent line, consecutive in the ring: A then B
        const onl = Q.map(q => Math.abs((q.x - m.x) * u.x + (q.y - m.y) * u.y) <= 0.5)
        const n = Q.length
        let ia = -1
        for (let i = 0; i < n; i++) if (onl[i] && onl[(i + 1) % n]) { ia = i; break }
        if (ia < 0) { polys[k] = Q; continue }
        const A = Q[ia], B = Q[(ia + 1) % n]
        const dA = wrap(Math.atan2(A.y - c.y, A.x - c.x) - th), dB = wrap(Math.atan2(B.y - c.y, B.x - c.x) - th)
        const ta = dA * pinch, tb = dB * pinch
        const out: Pt[] = [A]
        for (let s = 0; s <= segs; s++) {
            const t = ta + (tb - ta) * s / segs
            out.push({ x: c.x + rb * Math.cos(th + t), y: c.y + rb * Math.sin(th + t) })
        }
        for (let i = 1; i < n; i++) out.push(Q[(ia + i) % n])
        polys[k] = out
    }
    const disc: Pt[] = []
    for (let s = 0; s < 24; s++) disc.push({ x: c.x + rb * Math.cos(s * Math.PI / 12), y: c.y + rb * Math.sin(s * Math.PI / 12) })
    polys[mi] = disc
    return carved > 0
}

// grid_cells -- A GRID REGIME, ROW-BANDED BY THE SHARED SCALAR (2026-09-24, the owner on the crosslink
//  vines: *"I wish they were more containey alignments of things informing the layout rather than a
//   bunch of noodles dropped onto the cells"*).  Assigned OUTRIGHT -- same contract as `seat_polys` /
//    `focus_cells`: a pure function of (rows, radii, frame), no relax, no memo needed.
//  THE GROUPING BECOMES ALIGNMENT, not a line: `bucket_key_of` (vyto_foam -- the same heuristic the fold
//   ladder elects a partition key with: excludes a key everyone shares one value of, excludes a key
//    where every row differs, prefers fewer distinct values over more) picks the strongest shared
//     scalar across the rows handed in, and every row carrying the same value of it lands in the SAME
//      ROW of the grid -- reading left to right like the ROWS an HTML table would put them in, no cell
//       drawn to hold the group, the position itself says it.  A row with no shared-enough scalar
//        (an ungrouped or entirely-unique set) falls back to one flowing grid, still no cut, still no
//         crowding -- HTML block flow either way, laid out once, not negotiated.
//  Sizing: each cell keeps the AREA its radius asked for (area = pi*r^2) as a square (side = r * 1.77,
//   i.e. r*sqrt(pi)), so a bigger ask still reads bigger inside the grid -- the one thing power_cells
//    and this regime agree on.  Rows and the grid overall shrink to fit the frame only if they would
//     overflow it (never grow past what was asked, matching seat_polys' floor-not-ceiling discipline).
//  Returns polygons in the SAME ORDER as `radii`, aligned with the caller's `keys` -- a null is never
//   produced (an assigned regime, like focus_cells, promises every row a cell).
export function grid_cells(scs: Record<string, any>[], radii: number[], frame: Rect, gap: number,
                            bandKeyFn: (rows: Record<string, any>[]) => string | null): (Pt[] | null)[] {
    const n = scs.length
    if (!n) return []
    const sides = radii.map(r => Math.max(6, r * 1.772))
    const bandKey = bandKeyFn(scs)
    // group indices by the band key's value, first-seen order -- a row with no value for it (or no
    //  band key found at all) rides alone in its own singleton row, never dropped
    const bands: number[][] = []
    const at = new Map<string, number>()
    for (let i = 0; i < n; i++) {
        const v = bandKey != null ? ('' + (scs[i][bandKey] ?? (' ' + i))) : (' ' + i)
        let bi = at.get(v)
        if (bi == null) { bi = bands.length; bands.push([]); at.set(v, bi) }
        bands[bi].push(i)
    }
    const pad = Math.max(4, gap)
    const innerW = Math.max(1, frame.w - 2 * pad)
    let y = frame.y + pad
    let usedW = 0
    const rects: (Rect | null)[] = new Array(n).fill(null)
    for (const band of bands) {
        // WRAP a band that would overrun the frame's width -- an HTML row that has run out of room
        //  starts a new line, same law, never a squeeze that shrinks a cell below its own ask
        let x = frame.x + pad, rowH = 0
        for (const i of band) {
            const s = sides[i]
            if (x > frame.x + pad && x + s > frame.x + pad + innerW) { x = frame.x + pad; y += rowH + pad; rowH = 0 }
            rects[i] = { x, y, w: s, h: s }
            x += s + pad
            if (s > rowH) rowH = s
            if (x - pad > usedW) usedW = x - pad
        }
        y += rowH + pad
    }
    const usedH = Math.max(1, y - frame.y)
    usedW = Math.max(1, usedW - frame.x)
    // FIT TO THE FRAME BOTH WAYS (2026-09-24, the owner: watching a raw block-flow hug the top-left
    //  corner of an 800x450 frame at its natural size -- *"we're not using the entire space very
    //   efficiently"*, the SAME complaint that started this whole regime, now showing up a second time
    //    in a new shape).  A shrink-only floor stops overflow but never fills a sparse pile; grow the
    //     WHOLE GRID -- one uniform scale about the frame's own top-left, so every row keeps its
    //      relative size and alignment -- to the tighter of the two axes, capped so a lone tiny result
    //       set never balloons into a single monstrous cell (the same cap 'room' and 'plump' already use).
    const k = Math.max(0.35, Math.min(2.4, Math.min(frame.w / usedW, frame.h / usedH)))
    return rects.map(r => {
        if (!r) return null
        const rx = frame.x + (r.x - frame.x) * k, ry = frame.y + (r.y - frame.y) * k, rw = r.w * k, rh = r.h * k
        return [{ x: rx, y: ry }, { x: rx + rw, y: ry }, { x: rx + rw, y: ry + rh }, { x: rx, y: ry + rh }]
    })
}

// ── THE SPINE — a result set laid out as a creature, not a table (2026-09-24) ──────────────────────
//  The owner, of the grid regime: *"pretty sucky really. I want more of an actual creature-looking
//   spine... it's got a goofy office vibe whereas where we're going looks more like zoology."*  And the
//    use: *"a nice fullscreen graphic while searching for code in the code editor."*
//  A code search is already a spine: hits come SORTED BY PATH (Searchbar — "the path IS the
//   structure"), so the files are an ORDERED run, and each file holds its own hits.  So: the files are
//    VERTEBRAE stacked down a gently S-curving backbone, each sized by what it holds, and each file's
//     hits are RIBS off its vertebra, alternating left and right, drooping slightly the way ribs do.  A
//      rib runs roughly horizontally, so its text reads — which is why the spine runs down, not across.
//  Assigned outright (the seat/focus/grid contract): pure, no relax, every row gets a cell.

export type SpineBand = { y0: number, y1: number, cx: number, hw: number, frame: Rect, side: number, t: number }
export type BoneMeta = { kind: 'vert', cx: number, cy: number, rx: number, ry: number, side: number, margin: number }
                     | { kind: 'rib', x0: number, cy: number, len: number, droop: number, th: number, dir: number }

// the backbone's x at height y — a slow S near one EDGE of the frame.  `side` +1: the spine hugs the
//  left and every rib runs right into the open room; -1: the mirror.  One side, on purpose (the owner:
//   *"I'd like to get all the lines coming off on the same side of the spine"*) — and it is also the first
//    answer to *"getting the spine to fit in around other things"*: the creature claims an edge and grows
//     into whatever the frame leaves open, rather than planting itself in the middle.
export function spine_x(frame: Rect, y: number, side = 1): number {
    const t = (y - frame.y) / Math.max(1, frame.h)
    // not hard against the edge: the margin behind the spine is where each vertebra's NAME hangs
    // the margin keeps room for a name even in a narrow frame (a kept editor column shrinks the frame)
    const m = Math.min(frame.w * 0.4, Math.max(frame.w * 0.22, 150))
    const base = side > 0 ? frame.x + m : frame.x + frame.w - m
    return base + frame.w * 0.03 * Math.sin(t * Math.PI * 1.6 - 0.4)
}

// spine_cells — one vertebra per root row, in the order given.  Each takes a vertical share of the
//  backbone proportional to its radius (radius ~ sqrt of what it holds, so a 300-hit file is a big
//   vertebra but not a 300x one).  The vertebra is a small flattened disc lying ACROSS the backbone,
//    sheared to its local slope — a bone, not a box: narrow enough that the ribs carry the width.
// THE PASSAGE (2026-09-24): a level with more vertebrae than a screen can read does not crush them — each
//  keeps at least `minBand` of body, the creature grows LONGER than the frame, and `scroll` travels along
//   it (the owner's cave: *"a way to wander around the code as a bit of a place"*).  Measured why: a region
//    of 42 methods squeezed into one frame stood 14px vertebrae whose ribs fell into each other.
//     `length` is the whole body, so the caller can bound the scroll.
export function spine_cells(radii: number[], frame: Rect, gap: number, side = 1, scroll = 0, minBand = 26, mins?: number[]): { polys: (Pt[] | null)[], bands: SpineBand[], metas: BoneMeta[], spine: Pt[], length: number } {
    const n = radii.length
    const pad = Math.max(10, gap * 3)
    const H = Math.max(1, frame.h - 2 * pad)
    const wsum = radii.reduce((a, r) => a + Math.max(1, r), 0) || 1
    const wmax = Math.max(1, ...radii)
    const polys: (Pt[] | null)[] = []
    const bands: SpineBand[] = []
    const metas: BoneMeta[] = []
    // each vertebra's floor is the room ITS OWN ribs need (`mins`, from the caller who knows how many it shows)
    //  — seen: seven one-line ribs piled into a 26px band, unreadable while a neighbour had room to spare
    const bhs = radii.map((r, i) => Math.max(minBand, mins?.[i] ?? 0, H * Math.max(1, r) / wsum))
    const total = bhs.reduce((a, b) => a + b, 0)
    // a body that fits is spread to the frame as before; a longer one keeps its min bands and scrolls
    const k = total < H ? H / total : 1
    const top = frame.y + pad - (total * k > H ? Math.max(0, Math.min(scroll, total * k - H)) : 0)
    let y = top
    for (let i = 0; i < n; i++) {
        const bh = bhs[i] * k
        const cy = y + bh / 2
        const cx = spine_x(frame, cy, side)
        const slope = (spine_x(frame, cy + 1, side) - spine_x(frame, cy - 1, side)) / 2
        const rx = frame.w * (0.022 + 0.026 * Math.sqrt(Math.max(1, radii[i]) / wmax))
        const ry = Math.max(3, bh * 0.4)
        const pts: Pt[] = []
        for (let k = 0; k < 18; k++) {
            const a = k / 18 * Math.PI * 2
            const px = rx * Math.cos(a), py = ry * Math.sin(a)
            pts.push({ x: cx + px + py * slope, y: cy + py })
        }
        polys.push(pts)
        bands.push({ y0: y, y1: y + bh, cx, hw: rx, frame, side, t: (y + bh / 2 - top) / Math.max(1, total * k) })
        metas.push({ kind: 'vert', cx, cy, rx, ry, side, margin: side > 0 ? cx - rx - frame.x : frame.x + frame.w - (cx + rx) })
        y += bh
    }
    const spine: Pt[] = []
    const y0 = top - pad * 0.6, y1 = top + total * k + pad * 0.6
    for (let s = 0; s <= 64; s++) {
        const yy = y0 + (y1 - y0) * s / 64
        spine.push({ x: spine_x(frame, yy, side), y: yy })
    }
    return { polys, bands, metas, spine, length: total * k + 2 * pad }
}

// rib_cells — one vertebra's children as ribs.  Alternate sides (first right, then left, …) so the
//  creature stays balanced; each side stacks its ribs down the vertebra's band, thickness by radius,
//   with a GAP between ribs (bone, not masonry).  A rib is a curved tapering bone: it leaves the
//    vertebra level, droops as it runs out, narrows to a rounded tip.  Its LENGTH makes the silhouette:
//     a ribcage envelope along the body (longest mid-body, short at the neck and the tail), times the
//      rib's own weight (a crest standing for many reaches further than a single mention).
export function rib_cells(radii: number[], band: SpineBand, gap: number): { polys: (Pt[] | null)[], metas: (BoneMeta | null)[] } {
    const n = radii.length
    const polys: (Pt[] | null)[] = new Array(n).fill(null)
    const metas: (BoneMeta | null)[] = new Array(n).fill(null)
    if (!n) return { polys, metas }
    const f = band.frame
    const rmax = Math.max(1, ...radii)
    // every rib on the band's own side — one stack, one direction
    const sides: number[][] = [[]]
    for (let i = 0; i < n; i++) sides[0].push(i)
    for (let sd = 0; sd < 1; sd++) {
        const ids = sides[sd]
        if (!ids.length) continue
        const dir = band.side > 0 ? 1 : -1
        const tot = ids.reduce((a, i) => a + Math.max(1, radii[i]), 0)
        const h = band.y1 - band.y0
        let y = band.y0
        for (const i of ids) {
            const sh = h * Math.max(1, radii[i]) / tot
            const cy = y + sh / 2
            const x0 = spine_x(f, cy, band.side) + dir * (band.hw * 0.8)
            const room = dir > 0 ? (f.x + f.w - 10) - x0 : x0 - (f.x + 10)
            const t = band.t
            const env = 0.55 + 0.45 * Math.sin(Math.PI * Math.min(1, Math.max(0, t)))
            const len = Math.max(18, room * env * (0.4 + 0.6 * Math.sqrt(Math.max(1, radii[i]) / rmax)))
            const th = Math.max(2, sh * 0.62 - Math.max(0, gap))
            // the droop stays inside the rib's own slot — a rib that sags into the next vertebra's band is noise
            const droop = Math.min(len * 0.08, sh * 0.3)
            // the centre line droops with u^1.6; the half-thickness tapers to 45% at the tip
            const top: Pt[] = [], bot: Pt[] = []
            const K = 9
            for (let k = 0; k <= K; k++) {
                const u = k / K
                const x = x0 + dir * len * u
                const yc = cy + droop * Math.pow(u, 1.6)
                const ht = (th / 2) * (1 - 0.55 * u)
                top.push({ x, y: yc - ht }); bot.push({ x, y: yc + ht })
            }
            const tipx = x0 + dir * (len + th * 0.3), tipy = cy + droop
            const ring = top.concat([{ x: tipx, y: tipy }], bot.reverse())
            polys[i] = dir > 0 ? ring : ring.reverse()
            metas[i] = { kind: 'rib', x0, cy, len, droop, th, dir }
            y += sh
        }
    }
    return { polys, metas }
}

// ── THE GRID OF SAMENESS (2026-10-06, the owner: *"if there's order we want to draw down entropy into some kind of
//  grid|alignment. the vines shouldn't be careening all over things, they should be tightening nodes together, showing
//   the path through which there is sameness"*).  Two shared facts, two axes: ROWS by one elected key, COLUMNS by a
//    second, aligned across rows — so things that share a value literally line up, and the value is said ONCE, on its
//     row or column, instead of drawn as lines between holders.  A thing missing a key rides alone (its own row, or the
//      unlabelled last column).  Natural sizes from the radii, then ONE scale so the whole grid fills its frame; gutters
//       left/top for the axis labels.  Pure: (rows' scalars, radii, frame) → rects + the axes to label.
export type GridAxis = { key: string, value: string, x: number, y: number }
const GRID_CHANNELS = new Set(['dose', 'loose', 'same_n', 'flat_n', 'departing'])
// elect the two axes from the rows' OWN facts (never the glass's channels, never a mainkey's distinct names)
export function grid_keys(scs: Record<string, any>[], bucket: (rows: Record<string, any>[]) => string | null): [string | null, string | null] {
    const strip = (drop: Set<string>) => scs.map(sc => { const o: Record<string, any> = {}; for (const k of Object.keys(sc || {})) if (!GRID_CHANNELS.has(k) && !drop.has(k)) o[k] = sc[k]; return o })
    const k1 = bucket(strip(new Set()))
    const k2 = k1 ? bucket(strip(new Set([k1]))) : null
    return [k1, k2]
}
export function grid2_cells(scs: Record<string, any>[], radii: number[], frame: Rect, gap: number,
                            keys: [string | null, string | null]): { polys: (Pt[] | null)[], rows: GridAxis[], cols: GridAxis[] } {
    const n = scs.length
    if (!n) return { polys: [], rows: [], cols: [] }
    const [rk, ck] = keys
    const side = radii.map(r => Math.max(6, r * 1.772))
    const val = (i: number, k: string | null) => (k && scs[i] && scs[i][k] != null && scs[i][k] !== '') ? String(scs[i][k]) : null
    // rows: by rk's value (first-seen), a row-less thing alone; no rk ⇒ a near-square wrap
    const rowOf: number[] = [], rowVal: (string | null)[] = []
    const rIdx = new Map<string, number>()
    const wrap = rk ? 0 : Math.max(1, Math.ceil(Math.sqrt(n)))
    for (let i = 0; i < n; i++) {
        if (!rk) { const r = Math.floor(i / wrap); rowOf.push(r); rowVal[r] = null; continue }
        const v = val(i, rk)
        if (v == null) { rowOf.push(rowVal.length); rowVal.push(null); continue }
        let r = rIdx.get(v); if (r == null) { r = rowVal.length; rIdx.set(v, r); rowVal.push(v) }
        rowOf.push(r)
    }
    // columns: by ck's value, aligned ACROSS rows (a column-less thing goes to the unlabelled last column);
    //  no ck ⇒ each row just flows left to right (its own order)
    const colOf: number[] = [], colVal: (string | null)[] = []
    const cIdx = new Map<string, number>()
    let lone = -1
    for (let i = 0; i < n; i++) {
        if (!ck) { colOf.push(-1); continue }
        const v = val(i, ck)
        if (v == null) { if (lone < 0) { lone = -2 } colOf.push(-2); continue }
        let c = cIdx.get(v); if (c == null) { c = colVal.length; cIdx.set(v, c); colVal.push(v) }
        colOf.push(c)
    }
    if (ck && lone === -2) { const L = colVal.length; colVal.push(null); for (let i = 0; i < n; i++) if (colOf[i] === -2) colOf[i] = L }
    const nr = rowVal.length
    // no ck: per-row slot index becomes the column
    if (!ck) { const seen: number[] = new Array(nr).fill(0); for (let i = 0; i < n; i++) colOf[i] = seen[rowOf[i]]++; const nc = Math.max(...seen); for (let c = 0; c < nc; c++) colVal.push(null) }
    const nc = colVal.length
    // natural extents: a (row, col) cell may hold several — they sit side by side
    const cellW = Array.from({ length: nr }, () => new Array(nc).fill(0))
    const rowH = new Array(nr).fill(0)
    const slot: number[] = []
    for (let i = 0; i < n; i++) { const r = rowOf[i], c = colOf[i]; slot.push(cellW[r][c]); cellW[r][c] += side[i] + (cellW[r][c] ? gap : 0); if (side[i] > rowH[r]) rowH[r] = side[i] }
    const colW = new Array(nc).fill(0)
    for (let c = 0; c < nc; c++) for (let r = 0; r < nr; r++) if (cellW[r][c] > colW[c]) colW[c] = cellW[r][c]
    const pad = Math.max(3, gap)
    const L = rk && rowVal.some(v => v != null) ? Math.min(frame.w * 0.16, 130) : 0
    const T = ck && colVal.some(v => v != null) ? Math.min(frame.h * 0.1, 26) : 0
    const W = colW.reduce((s, x) => s + x, 0) + pad * (nc + 1)
    const H = rowH.reduce((s, x) => s + x, 0) + pad * (nr + 1)
    const s = Math.max(0.05, Math.min((frame.w - L) / W, (frame.h - T) / H))
    const ox = frame.x + L + ((frame.w - L) - W * s) / 2, oy = frame.y + T + ((frame.h - T) - H * s) / 2
    const colX: number[] = []; let x = ox + pad * s; for (let c = 0; c < nc; c++) { colX.push(x); x += (colW[c] + pad) * s }
    const rowY: number[] = []; let y = oy + pad * s; for (let r = 0; r < nr; r++) { rowY.push(y); y += (rowH[r] + pad) * s }
    const polys: (Pt[] | null)[] = []
    for (let i = 0; i < n; i++) {
        const r = rowOf[i], c = colOf[i]
        const x0 = colX[c] + (slot[i] ? slot[i] + 0 : 0) * s, y0 = rowY[r] + (rowH[r] - side[i]) * s / 2
        const w = side[i] * s, h = side[i] * s
        polys.push([{ x: x0, y: y0 }, { x: x0 + w, y: y0 }, { x: x0 + w, y: y0 + h }, { x: x0, y: y0 + h }])
    }
    const rows: GridAxis[] = [], cols: GridAxis[] = []
    if (rk) for (let r = 0; r < nr; r++) if (rowVal[r] != null) rows.push({ key: rk, value: rowVal[r]!, x: frame.x + 4, y: rowY[r] + rowH[r] * s / 2 })
    if (ck) for (let c = 0; c < nc; c++) if (colVal[c] != null) cols.push({ key: ck, value: colVal[c]!, x: colX[c] + colW[c] * s / 2, y: frame.y + T * 0.6 })
    return { polys, rows, cols }
}
