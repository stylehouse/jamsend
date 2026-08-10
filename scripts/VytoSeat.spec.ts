// VytoSeat — UNIT TESTS FOR THE SEAT, the deterministic partition that is the foam's alternative.
//
//  WHY THIS FILE EXISTS: the seat's whole case is that the properties the foam has to CHASE (no row
//   swallowed, a dose knob that works, nothing teleporting) are structural here rather than repaired
//    afterwards.  A claim like that is worth nothing unmeasured, so each one is a test and each one
//     has been seen to go red when the mechanism it names is removed.
//
//  WHAT THIS IS NOT: proof that the glass looks right.  These gate the partition's arithmetic, not
//   its wiring into Vytui and not a single pixel.  A wall's SHAPE still cannot be witnessed by a
//    fixture — but a seat's rect can, and that is the point of stage 4.
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/VytoSeat.spec.ts
import { test, expect } from 'vitest'
import { apportion, grid_for, deal_rows, seat_on_deal, deal_fits, deal_badness, deal_keys, box_poly }
    from '../src/lib/O/vyto_seat'

const FRAME = { x: 0, y: 0, w: 800, h: 450 }
// one deterministic stream, so a red is reproducible from the seed alone
let s = 20260810
const rn = () => (s = (s * 1103515245 + 12345) % 2147483648) / 2147483648
const rows_of = (n: number, disp: number) =>
    Array.from({ length: n }, (_, i) => ({ key: 'k' + i, weight: Math.pow(rn(), disp) + 0.06 }))
const REGIMES: [string, number, number][] =
    [['calm', 6, 1], ['busy', 18, 2.2], ['heavy', 40, 2.2], ['brutal', 90, 3]]

test('apportion: sum is exact, floor is honoured, overflow is null', () => {
    for (let t = 0; t < 500; t++) {
        const n = 1 + Math.floor(rn() * 40), total = n + Math.floor(rn() * 400)
        const ws = Array.from({ length: n }, () => rn() * 10)
        const out = apportion(ws, total, 1) as number[]
        expect(out).not.toBeNull()
        expect(out.reduce((a, v) => a + v, 0)).toBe(total)
        for (const v of out) expect(v).toBeGreaterThanOrEqual(1)
    }
    // the honest overflow: fewer units than claimants cannot be apportioned with a floor of one
    expect(apportion([1, 1, 1], 2, 1)).toBeNull()
    // a zero weight still eats its floor rather than vanishing — this is the whole "no swallow" law
    expect(apportion([0, 0, 5], 9, 1)).toEqual([1, 1, 7])
})

test('every row gets a box with real area — no nulls, no zero cells', () => {
    for (const [label, n, disp] of REGIMES) {
        for (let t = 0; t < 200; t++) {
            const rows = rows_of(n, disp)
            const deal = deal_rows(rows, FRAME)
            expect(deal.out.length, label).toBe(0)             // 90 rows still fit the grid
            const boxes = seat_on_deal(rows, deal, FRAME)
            expect(boxes.length, label).toBe(n)
            for (const b of boxes) {
                expect(b.w, label).toBeGreaterThan(0)
                expect(b.h, label).toBeGreaterThan(0)
            }
        }
    }
})

test('the boxes tile the frame — exact area, no overlap', () => {
    for (const [label, n, disp] of REGIMES) {
        for (let t = 0; t < 120; t++) {
            const rows = rows_of(n, disp)
            const boxes = seat_on_deal(rows, deal_rows(rows, FRAME), FRAME)
            const total = boxes.reduce((a, b) => a + b.w * b.h, 0)
            expect(total, label).toBeCloseTo(FRAME.w * FRAME.h, 6)
            for (let i = 0; i < boxes.length; i++) for (let j = i + 1; j < boxes.length; j++) {
                const a = boxes[i], b = boxes[j]
                const ox = Math.min(a.x + a.w, b.x + b.w) - Math.max(a.x, b.x)
                const oy = Math.min(a.y + a.h, b.y + b.h) - Math.max(a.y, b.y)
                expect(Math.min(ox, oy), `${label} overlap ${a.key}/${b.key}`).toBeLessThanOrEqual(1e-9)
            }
        }
    }
})

test('THE KNOB IS MONOTONE — turning a dose up never shrinks that cell', () => {
    // the foam fails this ~1 drag in 5 (scratchpad/mono.mjs: 77–87% monotone), because seat_floor
    //  clamps whoever is taking too much and the clamp lands on the row being dragged.
    for (const [label, n, disp] of REGIMES) {
        for (let t = 0; t < 200; t++) {
            const rows = rows_of(n, disp)
            const deal = deal_rows(rows, FRAME)
            const hit = Math.floor(rn() * n)
            const before = seat_on_deal(rows, deal, FRAME).find(b => b.key === rows[hit].key)!
            const rows2 = rows.map((r, i) => i === hit ? { ...r, weight: r.weight * 1.25 } : r)
            const after = seat_on_deal(rows2, deal, FRAME).find(b => b.key === rows[hit].key)!
            expect(after.w * after.h, `${label} ${rows[hit].key}`).toBeGreaterThanOrEqual(before.w * before.h - 1e-9)
        }
    }
})

test('THE DEAL HOLDS — no row ever jumps past another, however the weights move', () => {
    // The teleport this forbids is what makes a plain treemap worse than the foam: re-deriving the
    //  structure per frame moved 39% of cells by a mean of 33px — few cells, hurled a long way,
    //   which is far worse than the foam's everything-jitters-a-little when you are reaching for one.
    //  The property is stated on the TREE, not on coordinates: at every branch, everything on the
    //   near side must stay wholly on the near side.  Boxes are free to resize as much as the
    //    weights say; what they may never do is swap places.
    for (const [label, n, disp] of REGIMES) {
        for (let t = 0; t < 120; t++) {
            const rows = rows_of(n, disp)
            const deal = deal_rows(rows, FRAME)
            // any weights at all, not just a nudge — including a total inversion of the glass
            const rows2 = rows.map(r => ({ ...r, weight: rn() < 0.5 ? r.weight * 40 : r.weight / 40 }))
            const boxes = seat_on_deal(rows2, deal, FRAME)
            // a short list means the standing deal cannot seat these weights at all — the caller's
            //  re-deal trigger, and a legitimate structural change rather than a jump.  The property
            //   under test is about deals that DO still hold.
            if (boxes.length < n) continue
            const box = new Map(boxes.map(b => [b.key, b]))
            const walk = (nd: any): string[] => {
                if ('key' in nd) return [nd.key]
                const A = walk(nd.a), B = walk(nd.b)
                for (const ka of A) for (const kb of B) {
                    const a = box.get(ka)!, b = box.get(kb)!
                    if (nd.axis === 'x') expect(a.x + a.w, `${label} ${ka} jumped past ${kb}`).toBeLessThanOrEqual(b.x + 1e-9)
                    else expect(a.y + a.h, `${label} ${ka} jumped past ${kb}`).toBeLessThanOrEqual(b.y + 1e-9)
                }
                return A.concat(B)
            }
            walk(deal.root)
        }
    }
})

test('membership is the hard trigger; a re-order alone is not', () => {
    const rows = rows_of(12, 1.5)
    const deal = deal_rows(rows, FRAME)
    expect(deal_fits(rows, deal)).toBe(true)
    expect(deal_fits([...rows].reverse(), deal)).toBe(true)                  // same set, re-ordered
    expect(deal_fits(rows.slice(0, 11), deal)).toBe(false)                   // one departed
    expect(deal_fits([...rows, { key: 'new', weight: 1 }], deal)).toBe(false) // one arrived
})

test('deal_badness sees a standing deal go sour', () => {
    const rows = rows_of(9, 1)
    const deal = deal_rows(rows, FRAME)
    expect(deal_badness(rows, deal, FRAME)).toBeLessThan(6)
    // drive one row's weight through the roof and the strip it sits in goes to slivers
    const skew = rows.map((r, i) => ({ ...r, weight: i === 0 ? 500 : r.weight }))
    expect(deal_badness(skew, deal, FRAME)).toBeGreaterThan(deal_badness(rows, deal, FRAME))
})

test('overflow is NAMED, not squeezed — surplus rows land on the waiting list', () => {
    const tiny = { x: 0, y: 0, w: 40, h: 40 }
    const rows = rows_of(30, 1)
    const deal = deal_rows(rows, tiny)
    expect(deal.gw * deal.gh).toBeGreaterThanOrEqual(1)
    const seated = deal_keys(deal).length
    expect(seated + deal.out.length).toBe(30)
    for (const b of seat_on_deal(rows, deal, tiny)) expect(b.w * b.h).toBeGreaterThan(0)
})

test('pure — same input, byte-identical output', () => {
    const rows = rows_of(24, 2)
    const a = JSON.stringify(seat_on_deal(rows, deal_rows(rows, FRAME), FRAME))
    const b = JSON.stringify(seat_on_deal(rows, deal_rows(rows, FRAME), FRAME))
    expect(a).toBe(b)
    // and independent of the order the weights are handed to seat_on_deal
    const shuffled = [...rows].reverse()
    const deal = deal_rows(rows, FRAME)
    const p = JSON.stringify(seat_on_deal(rows, deal, FRAME))
    const q = JSON.stringify(seat_on_deal(shuffled, deal, FRAME))
    expect(p).toBe(q)
})

test('grid_for always leaves a unit per row', () => {
    for (let n = 1; n < 300; n++) {
        const g = grid_for(FRAME, n)
        expect(g.gw * g.gh, `n=${n}`).toBeGreaterThanOrEqual(n)
    }
})

test('box_poly winds one way and survives a gap wider than the box', () => {
    const p = box_poly({ x: 10, y: 20, w: 100, h: 50 }, 4)
    expect(p.length).toBe(4)
    expect(p[0]).toEqual({ x: 12, y: 22 })
    expect(p[2]).toEqual({ x: 108, y: 68 })
    // a gap that would invert a thin box is clamped, never allowed to fold the polygon
    const thin = box_poly({ x: 0, y: 0, w: 3, h: 40 }, 20)
    expect(thin.length).toBe(4)
    expect(thin[1].x).toBeGreaterThan(thin[0].x)
})
