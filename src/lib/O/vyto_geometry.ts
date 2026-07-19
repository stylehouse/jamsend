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
