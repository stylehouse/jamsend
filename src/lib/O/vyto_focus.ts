// vyto_focus.ts — THE FOCUS REGIME's geometry: one belly, a couple of buds.
//
//  (the owner 2026-08-10, the pivot: *"lets only feed Vyto one thing at a time, so one thing is
//   focused on, and two other things are mostly blank or possibly OK or CANCEL buttons, as separate
//    cells ... I don't want it moving at all after it settles I think, the one-main-thing should
//     look like a big belly, with a couple of purple somethings coming off it"* — and, on the old
//      regimes: *"it keeps making eg Shuffle larger than Player, it's silly ... strip it right back
//       to just being an artifact with a big blob to present stuff in"*.)
//
//  THE LAW: size is ASSIGNED, not discovered.  The foam relaxes seeds and then finds out what each
//   cell got; every skittish failure mode lived in that gap.  Here the layout is a PURE FUNCTION of
//    (frame, keys, roles): no springs, no clock, no randomness, no iteration — so after the arrival
//     animation there is nothing left that COULD move.  Stillness is not a damping constant, it is
//      the type signature.
//
//  One row is the BELLY — a big organic blob holding most of the frame, where the focused thing's
//   Component lives.  Every other row is a BUD — a small blob nestled onto the belly's right rim,
//    overlapping it (so it reads as "coming off" the belly, not as a sibling floating beside it).
//     Buds are the OK/CANCEL seats and the tuck (the way to the cells not currently focused).
//
//  The wobble is deterministic per key (a string hash seeds the phases), so the same world always
//   draws the same belly — a fixture-safe organic, not a random one.

export type Pt = { x: number, y: number }
export type Frame = { x: number, y: number, w: number, h: number }
export type FocusRole = 'belly' | 'bud'

// a tiny string hash → [0,1).  FNV-ish; only quality needed is "different keys, different phases".
function hash01(s: string, salt: number): number {
    let h = 2166136261 ^ salt
    for (let i = 0; i < s.length; i++) {
        h ^= s.charCodeAt(i)
        h = Math.imul(h, 16777619)
    }
    return ((h >>> 0) % 100000) / 100000
}

// a wobbled ellipse — three gentle harmonics, phases off the key.  amp is the total wobble as a
//  fraction of radius; kept small so the blob reads as a body, not a splat.
function blob(cx: number, cy: number, rx: number, ry: number, key: string, amp: number, pts: number): Pt[] {
    const p1 = hash01(key, 1) * Math.PI * 2
    const p2 = hash01(key, 2) * Math.PI * 2
    const p3 = hash01(key, 3) * Math.PI * 2
    const out: Pt[] = []
    for (let i = 0; i < pts; i++) {
        const t = (i / pts) * Math.PI * 2
        const w = 1 + amp * (0.6 * Math.sin(3 * t + p1) + 0.28 * Math.sin(5 * t + p2) + 0.12 * Math.sin(8 * t + p3))
        out.push({ x: cx + rx * w * Math.cos(t), y: cy + ry * w * Math.sin(t) })
    }
    return out
}

// where the buds sit, as a fraction of the belly's vertical half-extent (−1 top … +1 bottom).
//  They ride the RIGHT MARGIN — the strip `focus_polys` already reserves by shrinking `rx` — so a
//   bud is always beside the belly and never on top of it.  That distinction is not cosmetic: a bud
//    placed at an angle around the rim sits over the belly's BODY wherever the ellipse is wide, and
//     the belly's face mold is inscribed in that body, so the two components overlap — which is
//      exactly the *"spilling the Door into the Shuffle Component"* the owner rejected.
function bud_slots(n: number): number[] {
    if (n <= 0) return []
    if (n === 1) return [0.12]
    if (n === 2) return [-0.34, 0.42]
    const out: number[] = []
    for (let i = 0; i < n; i++) out.push(-0.62 + (1.24 * i) / (n - 1))
    return out
}

// THE LAYOUT.  keys/roles aligned; exactly one 'belly' is honoured (the first — any extra bellies
//  degrade gracefully to buds rather than fighting).  Every key gets a real polygon: with roles
//   assigned up front there is no cut to lose a seat in, so "no room" is unrepresentable here.
// ── THE STRETCH: how much room is actually in here? ───────────────────────────────────────────
//  (the owner 2026-08-10: *"for the Heist we want it totally maxed out up in there like the STAGED
//   AREA did it before."*)
//
//  Every other seat in this renderer asks "how big can THIS COMPONENT be" — it starts from the
//   face's own natural box and finds the scale at which that aspect fits.  Right for a player, wrong
//    for a heist: a heist is a LIST, it has no natural size worth honouring, and sizing it from its
//     content leaves the belly full of nothing.  So the stretch asks the opposite question — **how
//      big a rectangle is in this body at all** — and hands the answer to the face as its box.
//   That is the regime's own law taken one step further: size is ASSIGNED, and here even the ASPECT
//    is assigned.  The face has no opinion left to have.
//
//  Method: for each candidate aspect, cast rays from the centre to the box's four corners and four
//   edge midpoints (the same probe set the component seat uses), take the binding one, and keep
//    whichever aspect wins on area.  A sweep, not a solve — a true maximum-area inscribed rectangle
//     is a real optimisation and this is a wobbled ellipse, where the answer is smooth and the sweep
//      lands within a percent of it.  Deterministic (no clock, no randomness), so a stretched belly
//       is as still as every other cell here.
function ray_wall(poly: Pt[], ox: number, oy: number, dx: number, dy: number): number {
    let best = Infinity
    for (let i = 0, j = poly.length - 1; i < poly.length; j = i++) {
        const ax = poly[j].x, ay = poly[j].y, bx = poly[i].x, by = poly[i].y
        const ex = bx - ax, ey = by - ay
        const den = dx * ey - dy * ex
        if (Math.abs(den) < 1e-9) continue
        const t = ((ax - ox) * ey - (ay - oy) * ex) / den            // along the ray
        const u = ((ax - ox) * dy - (ay - oy) * dx) / den            // along the edge
        if (t > 0 && u >= 0 && u <= 1) best = Math.min(best, t)
    }
    return best
}

// the 8 probes of a box with half-extents (hw, hh): corners then edge midpoints.
const PROBES: [number, number][] = [[1, 1], [1, -1], [-1, 1], [-1, -1], [1, 0], [-1, 0], [0, 1], [0, -1]]

// the biggest box of a given aspect (w/h) that fits, centred on (cx, cy).  `air` is held back from
//  the wall so a component never sits exactly on its own edge.
function box_at(poly: Pt[], cx: number, cy: number, aspect: number, air: number): number {
    let s = Infinity
    for (const [qx, qy] of PROBES) {
        const ex = (aspect / 2) * qx, ey = 0.5 * qy
        const L = Math.hypot(ex, ey); if (!(L > 0)) continue
        const t = ray_wall(poly, cx, cy, ex / L, ey / L)
        if (!Number.isFinite(t)) continue
        s = Math.min(s, Math.max(0, t - air) / L)
    }
    return Number.isFinite(s) ? s : 0
}

export function fill_rect(poly: Pt[], cx: number, cy: number, air: number = 3): { w: number, h: number } {
    if (!poly || poly.length < 3) return { w: 0, h: 0 }
    let bw = 0, bh = 0, bestA = -1
    // a geometric sweep across the aspects a body can plausibly want, tall through wide.
    for (let i = 0; i <= 14; i++) {
        const aspect = 0.35 * Math.pow(4.0 / 0.35, i / 14)
        const s = box_at(poly, cx, cy, aspect, air)
        if (!(s > 0)) continue
        const w = aspect * s, h = s
        const a = w * h
        if (a > bestA) { bestA = a; bw = w; bh = h }
    }
    return { w: bw, h: bh }
}

export function focus_polys(frame: Frame, keys: string[], roles: FocusRole[], gap: number): Pt[][] {
    const n = keys.length
    if (!n) return []
    const { x, y, w, h } = frame
    const md = Math.max(1, Math.min(w, h))
    const m = Math.max(gap, md * 0.025)
    const budR = Math.min(84, Math.max(22, md * 0.09))
    let bellyI = roles.indexOf('belly')
    if (bellyI < 0) bellyI = 0
    const budIdx: number[] = []
    for (let i = 0; i < n; i++) if (i !== bellyI) budIdx.push(i)
    // the belly sits a shade left of centre, leaving the right margin the buds bulge into.
    const cx = x + w * 0.5 - (budIdx.length ? budR * 0.5 : 0)
    const cy = y + h * 0.5
    const rx = Math.max(10, w * 0.5 - m - (budIdx.length ? budR * 1.05 : 0))
    const ry = Math.max(10, h * 0.5 - m)
    const out: Pt[][] = new Array(n)
    out[bellyI] = blob(cx, cy, rx, ry, keys[bellyI], 0.05, 56)
    const slots = bud_slots(budIdx.length)
    for (let k = 0; k < budIdx.length; k++) {
        const i = budIdx[k]
        const r = budR * (0.9 + 0.2 * hash01(keys[i], 7))
        // the slot fixes the HEIGHT; the belly's own rim at that height fixes the LEFT edge.  Sitting
        //  the bud just right of the rim overlaps it by a sliver — enough to read as "coming off it",
        //   never enough to put the bud's component over the belly's.
        const fy = slots[k]
        const by0 = cy + ry * fy
        const rimx = cx + rx * Math.sqrt(Math.max(0, 1 - fy * fy))
        let bx = rimx + r * 0.55
        let by = by0
        // stay on the plate: a bud may hug the frame edge but never leave it.
        bx = Math.min(x + w - r * 0.85 - 1, Math.max(x + r * 0.85 + 1, bx))
        by = Math.min(y + h - r * 0.85 - 1, Math.max(y + r * 0.85 + 1, by))
        out[i] = blob(bx, by, r, r * 0.92, keys[i], 0.07, 22)
    }
    return out
}
