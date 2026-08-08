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
