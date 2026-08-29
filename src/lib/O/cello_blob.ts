// cello_blob.ts — the organically-wobbly cell wall, as a pure CSS clip-path (Cello renderer, 2026-08-29).
//  Cello does "basically no layout thinking, just this or that template" — but it MUST keep the cartoonish
//   charm of Vyto's hand-drawn cell walls (owner: "the organically wobbly cell wall, lovely").  Vyto earns its
//    wobble from voronoi cuts; Cello has no voronoi, so it synthesises the same LOOK cheaply: sample a ring of
//     points around an ellipse, nudge each radius by a smooth, SEEDED wobble, and emit a `clip-path: polygon()`
//      string in percentages of the cell's own bounding box (the same contract Vytui's wall-as-clip uses,
//       Vytui.svelte:937 — percentages resolve against the element box, so no pixel measuring, no overlay drift).
//  Deterministic per `seed` so a given cell keeps ONE shape across renders (it must not shimmer every frame),
//   yet neighbours look hand-drawn-different.  No dependencies, no Math.random — pure, testable, SSR-safe.

// a tiny deterministic hash → [0,1), so a cell's wobble is stable for its seed but varied between seeds.
function seeded(seed: number, i: number): number {
    // integer hash (xorshift-ish); the `i` mixes the vertex index so each point gets its own offset
    let x = (seed * 374761393 + i * 668265263) | 0
    x = (x ^ (x >>> 13)) * 1274126177 | 0
    x = x ^ (x >>> 16)
    return ((x >>> 0) % 100000) / 100000
}

export interface BlobOpts {
    points?: number   // vertices around the ring — more = smoother, fewer = lumpier (default 14)
    wobble?: number   // radial jitter as a fraction of the radius (default 0.06 — a gentle hand-drawn waver)
    squish?: number   // vertical squash: 1 = round, <1 = wider than tall (default 0.98, near-round like the screenshot)
}

// cello_ring — the shared ring of wall points (in box percentages, 0..100), the single source of
//  truth both the clip-path polygon and the smooth SVG wall path are built from.  Deterministic per
//   seed.  `bias` (dx,dy in box %) shifts the whole ring so the SAME shape can be anchored off-edge
//    (the belly cell that spills off the left/top/bottom — the ring is generated over a bigger notional
//     box and translated, the caller's viewBox does the cropping).  `scale` grows the radii past the box
//      (values >1 push the wall off the edges on purpose — the "really-big" off-edge cell).
export function cello_ring(seed: number, opts: BlobOpts & { scale?: number, dx?: number, dy?: number } = {}): Array<[number, number]> {
    const n = Math.max(6, opts.points ?? 14)
    const wob = opts.wobble ?? 0.06
    const squish = opts.squish ?? 0.98
    const scale = opts.scale ?? 1
    const dx = opts.dx ?? 0
    const dy = opts.dy ?? 0
    const cx = 50 + dx, cy = 50 + dy
    // base radii: leave a hair of margin so the wobble's outward bumps never clip past the box edge
    const rx = 47 * scale, ry = 47 * squish * scale
    const lobePhase = seeded(seed, 0) * Math.PI * 2
    const pts: Array<[number, number]> = []
    for (let i = 0; i < n; i++) {
        const a = (i / n) * Math.PI * 2
        // two-octave smooth wobble so it reads as an organic waver, not a spiky star: a low-frequency
        //  lobe (seeded phase) plus a smaller per-vertex jitter.  Kept small (wob) — charm, not chaos.
        const lobe = Math.sin(a * 3 + lobePhase) * 0.5
        const jitter = (seeded(seed, i + 1) - 0.5)
        const r = 1 + wob * (lobe + jitter)
        pts.push([cx + Math.cos(a) * rx * r, cy + Math.sin(a) * ry * r])
    }
    return pts
}

// cello_blob — a clip-path polygon string (percentages) describing one organically-wobbly cell wall.
//  seed: any stable number for this cell (e.g. a hash of its id) so the shape persists and varies per cell.
export function cello_blob(seed: number, opts: BlobOpts & { scale?: number, dx?: number, dy?: number } = {}): string {
    const pts = cello_ring(seed, opts)
    return `polygon(${pts.map(([x, y]) => `${x.toFixed(2)}% ${y.toFixed(2)}%`).join(', ')})`
}

// cello_blob_path — the SAME ring as a SMOOTH closed SVG path `d` (viewBox 0 0 100 100), joining the
//  points with quadratic Béziers through their midpoints (the Vytui arc_d technique: `Q vertex midpoint`
//   so the curve passes smoothly through each edge without a sharp corner).  This is what makes Cello's
//    wall read as a smooth blob outline, not a jagged polygon.  Closed with a final Q back to the start.
export function cello_blob_path(seed: number, opts: BlobOpts & { scale?: number, dx?: number, dy?: number } = {}): string {
    const pts = cello_ring(seed, opts)
    if (pts.length < 3) return ''
    const f = (v: number) => v.toFixed(2)
    // start at the midpoint of the last→first edge, so every vertex is hit by a Q through a midpoint
    const mid = (a: [number, number], b: [number, number]): [number, number] => [(a[0] + b[0]) / 2, (a[1] + b[1]) / 2]
    const start = mid(pts[pts.length - 1], pts[0])
    let d = `M ${f(start[0])} ${f(start[1])}`
    for (let i = 0; i < pts.length; i++) {
        const v = pts[i]
        const m = mid(v, pts[(i + 1) % pts.length])
        d += ` Q ${f(v[0])} ${f(v[1])} ${f(m[0])} ${f(m[1])}`
    }
    return d + ' Z'
}

// cello_seed — a stable small integer from a cell's id/pub string, for feeding cello_blob.
export function cello_seed(id: string): number {
    let h = 2166136261
    for (let i = 0; i < id.length; i++) { h ^= id.charCodeAt(i); h = Math.imul(h, 16777619) }
    return (h >>> 0) % 100000
}
