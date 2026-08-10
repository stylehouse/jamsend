// vyto_seat — THE SEAT: a deterministic partition of a frame among weighted rows.
//  The alternative to the foam cut, eating exactly the same model input (one weight per row —
//   Vyto_express's env_area, which the solver already turns into a radius) and answering with a
//    rect per row instead of a polygon discovered after the fact.
//
// ── WHY THIS EXISTS ───────────────────────────────────────────────────────────────────────────
//  The foam DISCOVERS size: express writes an area, solve turns it into a radius, a mutual
//   relaxation moves the seeds, the power cut tessellates whatever came out, and only THEN do we
//    learn what each cell got.  Every failure we have chased lives in that gap — `seat_floor` and
//     its six-try repair loop, `frame_seat`, the null-poly trapdoor, the vanish floor, the "no
//      room" corner note, the grow-only need floor, `slab_seat`.  All of them are machinery for
//       "the cell got less than it needed and we found out too late".
//  The seat ASSIGNS size.  Every row is handed a whole number of grid units, floor one, by
//   largest-remainder apportionment.  "No row may be swallowed" stops being a law enforced by
//    repair and becomes arithmetic that cannot fail: a box below one unit is not representable.
//
// ── THE MEASURED CASE (scratchpad/seat.mjs + mono.mjs, 92,400 cells, 2026-08-10) ───────────────
//                        cells lost     min cell      knob monotone
//     foam               0.1–0.2%       0px²          77–87%   ← turning a dose UP shrinks the
//     seat               0 / 92,400     1071px²       100%        cell about one drag in five
//  The monotony number is the one that decides it.  `seat_floor` caps whoever is taking too much,
//   so pushing your own dose past the cap gets it clamped straight back while the live dosetip
//    reads the number going up.  The knob lies.  (Measured with the pile held still, so that is
//     the LOWER bound — on a live glass the pile then moves too.)
//
// ── THE DEAL — the part that is not obvious ───────────────────────────────────────────────────
//  A plain treemap is WORSE than the foam, and the fuzz caught it before the review did.  Deriving
//   the strip structure afresh from current weights every frame lets rows jump between strips:
//    39% of cells disturbed by a mean of 33px.  The foam jitters everywhere but tinily; a naive
//     treemap moves few cells but HURLS them, which is far worse when you are reaching for one.
//  So the structure is lifted out and KEPT.  A `Deal` is which rows sit in which strip and how tall
//   each strip is.  A weight change re-apportions widths INSIDE one strip and touches nothing else
//    (0.1–24% of others disturbed, 0.04–5.4px).  The deal is re-cut only when membership changes or
//     badness crosses a hysteresis line — an EVENT you can name, throttle and animate, never a twitch.
//  A Deal is also plain scalars, so unlike a wall it can ride in the C tree and a Book can witness
//   the layout (see the memory "Books cannot witness wall shape").
//
// Pure: no C, no DOM, no clock, no randomness.  Node-testable, and fuzzed as such.

export type Pt = { x: number, y: number }
export type SeatRow = { key: string, weight: number }
export type SeatBox = { key: string, x: number, y: number, w: number, h: number }
// A deal is a SPLIT TREE: each branch says "this rectangle is divided along x (or y), these rows on
//  the near side, those on the far side".  It holds no sizes — the ratios are recomputed from live
//   weights every seat — so a dose change re-proportions the cuts it sits under and moves nothing
//    else.  Splitting an ORDERED list keeps each row among the same neighbours forever, and cutting
//     the longer axis each time is what gives the squarish boxes a strip layout could not (14% of
//      cells were slivers as strips; the split tree is measured beside it in VytoSeat.spec).
export type DealNode = { key: string } | { axis: 'x' | 'y', a: DealNode, b: DealNode, n: number }
// gw/gh are the grid the deal was cut against and ride WITH it: re-deriving the grid per frame
//  would move every wall the moment a row arrives, which is the teleport the deal exists to stop.
export type Deal = { gw: number, gh: number, root: DealNode | null, out: string[] }
export type Frame = { x: number, y: number, w: number, h: number }

// ── APPORTIONMENT ─────────────────────────────────────────────────────────────────────────────
// Largest remainder (Hamilton) with a floor: every claimant takes `floor` units off the top, the
//  surplus is shared by weight, and the sum is EXACT — no drift to mop up, no cell rounded to zero.
//  Ties break on index so the result is a pure function of its inputs (a Map iteration order or a
//   sort that is not total would make the layout depend on insertion history).
//  Returns null when the units genuinely do not stretch to one each — the honest overflow, which
//   the caller turns into a waiting list rather than into slivers.
export function apportion(weights: number[], total: number, floor = 1): number[] | null {
    const n = weights.length
    if (!n) return []
    if (total < n * floor) return null
    const spare = total - n * floor
    let sum = 0
    for (const w of weights) sum += Math.max(0, w)
    if (!(sum > 0)) sum = 1
    const exact = weights.map(w => (Math.max(0, w) / sum) * spare)
    const out = exact.map(e => Math.floor(e))
    let left = spare
    for (const v of out) left -= v
    const order = exact.map((e, i) => ({ frac: e - Math.floor(e), i }))
                       .sort((a, b) => (b.frac - a.frac) || (a.i - b.i))
    for (let k = 0; k < left; k++) out[order[k % n].i]++
    return out.map(v => v + floor)
}

// ── THE GRID ──────────────────────────────────────────────────────────────────────────────────
// How finely the frame is ruled.  Finer = truer to the weights and more twitch; coarser = chunkier
//  and calmer.  UNITS_PER_ROW is the dial; the cap keeps a 200-row scope from ruling a grid nobody
//   can see.  Units are kept near-square so an apportioned box's aspect is governed by its share,
//    not by the ruling.
const UNITS_PER_ROW = 12
const MAX_UNITS = 900
export function grid_for(frame: Frame, n: number): { gw: number, gh: number } {
    if (!(frame.w > 0) || !(frame.h > 0) || n < 1) return { gw: 1, gh: 1 }
    const want = Math.max(n, Math.min(MAX_UNITS, n * UNITS_PER_ROW))
    const cell = Math.sqrt((frame.w * frame.h) / want)
    let gw = Math.max(1, Math.round(frame.w / cell))
    let gh = Math.max(1, Math.round(frame.h / cell))
    // guarantee a unit each — grow the short side first so the ruling stays near-square
    while (gw * gh < n) { if (gw / frame.w < gh / frame.h) gw++; else gh++ }
    return { gw, gh }
}

// ── CUTTING A DEAL ────────────────────────────────────────────────────────────────────────────
// Order-preserving squarify: walk the rows IN THEIR GIVEN ORDER (identity order — tree order —
//  never weight order, because sorting by weight is precisely what makes a cell change places when
//   its dose moves) and split it in two at the point that best balances weight, cutting whichever
//    axis of the rectangle is currently longer.  Recurse.  Each row therefore keeps the same
//     neighbours for the life of the deal, and every rectangle is cut across its long way, which is
//      what keeps the leaves squarish.
//  Only the SHAPE of the split is recorded.  Where each cut actually falls is recomputed from live
//   weights on every seat, so the tree survives any amount of dose work.
export function deal_rows(rows: SeatRow[], frame: Frame, gw?: number, gh?: number): Deal {
    const n = rows.length
    if (!n) return { gw: 1, gh: 1, root: null, out: [] }
    const g = (gw && gh) ? { gw, gh } : grid_for(frame, n)
    const GW = g.gw, GH = g.gh
    // rows beyond what the grid can seat one-each are the WAITING LIST — named, countable, and
    //  recoverable, instead of silently becoming a sliver or a null poly.
    const fit = Math.min(n, GW * GH)
    const seatable = rows.slice(0, fit)
    const out = rows.slice(fit).map(r => r.key)
    // build against the weights as they stand, in PIXELS, so the axis choice is about the shape the
    //  viewer will see rather than about the ruling.
    const build = (lo: number, hi: number, w: number, h: number): DealNode => {
        if (hi - lo === 1) return { key: seatable[lo].key }
        let total = 0
        for (let k = lo; k < hi; k++) total += Math.max(0, seatable[k].weight)
        // the ordered split: the index whose prefix is closest to half the weight.  Clamped to leave
        //  at least one row each side, so a single dominant row cannot make an empty branch.
        let acc = 0, bestI = lo + 1, bestD = Infinity
        for (let k = lo; k < hi - 1; k++) {
            acc += Math.max(0, seatable[k].weight)
            const d = Math.abs(acc - (total - acc))
            if (d < bestD) { bestD = d; bestI = k + 1 }
        }
        let a = 0
        for (let k = lo; k < bestI; k++) a += Math.max(0, seatable[k].weight)
        const fa = total > 0 ? a / total : (bestI - lo) / (hi - lo)
        const axis: 'x' | 'y' = w >= h ? 'x' : 'y'
        const A = axis === 'x' ? build(lo, bestI, w * fa, h) : build(lo, bestI, w, h * fa)
        const B = axis === 'x' ? build(bestI, hi, w * (1 - fa), h) : build(bestI, hi, w, h * (1 - fa))
        return { axis, a: A, b: B, n: bestI - lo }
    }
    return { gw: GW, gh: GH, root: build(0, fit, frame.w, frame.h), out }
}

// ── SEATING ON A STANDING DEAL ────────────────────────────────────────────────────────────────
// The hot path, run every paint.  Walks the standing tree in INTEGER grid units, so every cut lands
//  on a ruling line and a box only moves when a change is big enough to cross one — quantisation IS
//   the hysteresis, and it is why a live dose drag does not shimmer the whole glass.
//  Each side of a cut is floored at the units its leaves are owed (`ceil(leaves / across)`), which is
//   where "no row may be swallowed" actually lives: a branch cannot be given less room than its
//    subtree needs, so no leaf can arrive at zero.  A row the deal does not know about is skipped —
//     this NEVER invents a branch, because inventing one here is the teleport it exists to stop.
export function seat_on_deal(rows: SeatRow[], deal: Deal, frame: Frame): SeatBox[] {
    const out: SeatBox[] = []
    if (!deal.root) return out
    const cw = frame.w / deal.gw, ch = frame.h / deal.gh
    const wof = new Map<string, number>()
    for (const r of rows) wof.set(r.key, r.weight)
    // weight and live-leaf count of a subtree, memoised down the walk
    const wsum = (nd: DealNode): number => 'key' in nd ? Math.max(0, wof.get(nd.key) ?? 0)
                                                      : wsum(nd.a) + wsum(nd.b)
    const leaves = (nd: DealNode): number => 'key' in nd ? (wof.has(nd.key) ? 1 : 0)
                                                        : leaves(nd.a) + leaves(nd.b)
    const place = (nd: DealNode, ux: number, uy: number, uw: number, uh: number): void => {
        if (uw < 1 || uh < 1) return
        if ('key' in nd) {
            if (wof.has(nd.key))
                out.push({ key: nd.key, x: frame.x + ux * cw, y: frame.y + uy * ch, w: uw * cw, h: uh * ch })
            return
        }
        const la = leaves(nd.a), lb = leaves(nd.b)
        if (!la) { place(nd.b, ux, uy, uw, uh); return }
        if (!lb) { place(nd.a, ux, uy, uw, uh); return }
        const wa = wsum(nd.a), wb = wsum(nd.b), tot = wa + wb
        // THE RECORDED AXIS, ALWAYS.  An earlier draft turned a cut to the other axis when this one
        //  could not hold both floors, which read as a harmless local repair and is in fact the
        //   teleport wearing a disguise: flipping a branch from a horizontal cut to a vertical one
        //    rearranges everything under it, and the no-jump test caught rows swapping places
        //     (`k1 jumped past k2`).  A branch that genuinely cannot seat its subtree leaves those
        //      leaves unplaced, the caller sees a short box list, and THAT is the re-deal trigger —
        //       a named event, which is the only honest way for the structure to change.
        const axis = nd.axis
        const across = axis === 'x' ? uh : uw, along = axis === 'x' ? uw : uh
        const minA = Math.min(along - 1, Math.max(1, Math.ceil(la / across)))
        const minB = Math.min(along - minA, Math.max(1, Math.ceil(lb / across)))
        const want = tot > 0 ? Math.round((wa / tot) * along) : Math.round((la / (la + lb)) * along)
        const cut = Math.max(minA, Math.min(along - minB, want))
        if (axis === 'x') { place(nd.a, ux, uy, cut, uh); place(nd.b, ux + cut, uy, uw - cut, uh) }
        else { place(nd.a, ux, uy, uw, cut); place(nd.b, ux, uy + cut, uw, uh - cut) }
    }
    place(deal.root, 0, 0, deal.gw, deal.gh)
    return out
}

// ── WHEN TO RE-DEAL ───────────────────────────────────────────────────────────────────────────
// Membership is the hard trigger: a row arrived or left, so the deal is not about these rows any
//  more.  Compared as a SET (a re-order of the same rows is not a membership change) plus the
//   waiting list, because a row moving off the waiting list is an arrival for seating purposes.
export function deal_keys(deal: Deal): string[] {
    const ks: string[] = []
    const walk = (nd: DealNode | null): void => {
        if (!nd) return
        if ('key' in nd) { ks.push(nd.key); return }
        walk(nd.a); walk(nd.b)
    }
    walk(deal.root)
    return ks
}
export function deal_fits(rows: SeatRow[], deal: Deal): boolean {
    const seated = new Set<string>(deal_keys(deal))
    for (const k of deal.out) seated.add(k)
    if (seated.size !== rows.length) return false
    for (const r of rows) if (!seated.has(r.key)) return false
    return true
}
// Badness is the soft trigger: the worst aspect ratio the standing deal is currently producing.
//  Weights drift under a fixed deal, so a strip that squarified well when it was cut can end up
//   holding a sliver.  The caller compares this against a hysteresis line — high enough that
//    ordinary dose work never trips it, so a re-deal stays an event.
export function deal_badness(rows: SeatRow[], deal: Deal, frame: Frame): number {
    let worst = 0
    for (const b of seat_on_deal(rows, deal, frame)) {
        if (!(b.w > 0) || !(b.h > 0)) return Infinity
        const a = Math.max(b.w / b.h, b.h / b.w)
        if (a > worst) worst = a
    }
    return worst
}

// ── DRAWING ───────────────────────────────────────────────────────────────────────────────────
// A box as the polygon the renderer already knows how to draw, inset by half a gap on each side so
//  neighbouring cells show a wall between them exactly as the foam's gap does.  Wound the same way
//   the cut winds, so `poly_area`, `clip_of` and `path_round` all read it without a special case.
export function box_poly(b: { x: number, y: number, w: number, h: number }, gap = 0): Pt[] {
    const g = Math.min(gap / 2, b.w / 2 - 0.5, b.h / 2 - 0.5)
    const x0 = b.x + g, y0 = b.y + g, x1 = b.x + b.w - g, y1 = b.y + b.h - g
    if (!(x1 > x0) || !(y1 > y0)) return []
    return [{ x: x0, y: y0 }, { x: x1, y: y0 }, { x: x1, y: y1 }, { x: x0, y: y1 }]
}
