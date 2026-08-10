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
