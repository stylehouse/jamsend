// VytoFocus.spec — the focus regime's gates.  The claims that matter:
//  · NOBODY IS SWALLOWED: every key gets a real polygon, always — "no room" is unrepresentable.
//  · IT IS A PURE FUNCTION: same inputs, byte-same output — stillness by type signature, so
//    "I don't want it moving at all after it settles" is a theorem, not a damping constant.
//  · THE BELLY IS BIG and the buds are small and ATTACHED — the look is the spec.
// Run: node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/VytoFocus.spec.ts

import { describe, test, expect } from 'vitest'
import { focus_polys, fill_rect, fill_body, clip_frame, BELLY_SWELL,
         type Pt, type Frame, type FocusRole } from '../src/lib/O/vyto_focus'

const F: Frame = { x: 0, y: 0, w: 900, h: 520 }

function area(p: Pt[]): number {
    let a = 0
    for (let i = 0; i < p.length; i++) {
        const q = p[(i + 1) % p.length]
        a += p[i].x * q.y - q.x * p[i].y
    }
    return Math.abs(a / 2)
}
function inside(pt: Pt, poly: Pt[]): boolean {
    let odd = false
    for (let i = 0, j = poly.length - 1; i < poly.length; j = i++) {
        const a = poly[i], b = poly[j]
        if ((a.y > pt.y) !== (b.y > pt.y) && pt.x < ((b.x - a.x) * (pt.y - a.y)) / (b.y - a.y) + a.x) odd = !odd
    }
    return odd
}

describe('the focus layout', () => {
    const keys = ['Door!0', 'Sat,more!1', 'Sat,home!2']
    const roles: FocusRole[] = ['belly', 'bud', 'bud']

    test('NOBODY IS SWALLOWED — every key gets a real polygon', () => {
        for (let n = 1; n <= 6; n++) {
            const ks = Array.from({ length: n }, (_, i) => `k${i}`)
            const rs: FocusRole[] = ks.map((_, i) => (i === 0 ? 'belly' : 'bud'))
            const polys = focus_polys(F, ks, rs, 8)
            expect(polys.length).toBe(n)
            for (const p of polys) expect(area(p)).toBeGreaterThan(100)
        }
    })

    test('IT IS A PURE FUNCTION — same inputs, byte-same output, twice', () => {
        const a = focus_polys(F, keys, roles, 8)
        const b = focus_polys(F, keys, roles, 8)
        expect(JSON.stringify(a)).toBe(JSON.stringify(b))
    })

    test('THE BELLY IS BIG — most of the frame is the one thing', () => {
        const polys = focus_polys(F, keys, roles, 8)
        expect(area(polys[0])).toBeGreaterThan(F.w * F.h * 0.45)
    })

    test('THE BUDS ARE SMALL — none rivals the belly', () => {
        const polys = focus_polys(F, keys, roles, 8)
        for (let i = 1; i < polys.length; i++) expect(area(polys[i])).toBeLessThan(F.w * F.h * 0.08)
    })

    test('THE BUDS COME OFF THE BELLY — each overlaps it, none floats free', () => {
        const polys = focus_polys(F, keys, roles, 8)
        for (let i = 1; i < polys.length; i++) {
            let touching = 0
            for (const pt of polys[i]) if (inside(pt, polys[0])) touching++
            expect(touching).toBeGreaterThan(0)
            expect(touching).toBeLessThan(polys[i].length)   // off it, not inside it
        }
    })

    // THE OVERLAP LAW, both halves.  A bud must TOUCH the belly (it is coming off it) and must not
    //  SIT ON it — its centre outside the belly is what keeps the bud's component out of the belly's
    //   component, which is the "spilling the Door into the Shuffle Component" defect by name.
    test('A BUD SITS BESIDE THE BELLY, NEVER ON IT — no bud centre inside the belly', () => {
        for (let n = 2; n <= 6; n++) {
            const ks = Array.from({ length: n }, (_, i) => `k${i}`)
            const rs: FocusRole[] = ks.map((_, i) => (i === 0 ? 'belly' : 'bud'))
            const polys = focus_polys(F, ks, rs, 8)
            for (let i = 1; i < polys.length; i++) {
                let mx = 0, my = 0
                for (const p of polys[i]) { mx += p.x; my += p.y }
                mx /= polys[i].length; my /= polys[i].length
                expect(inside({ x: mx, y: my }, polys[0]), `bud ${i} of ${n} centre is inside the belly`).toBe(false)
            }
        }
    })

    test('EVERYTHING STAYS ON THE PLATE — no vertex leaves the frame', () => {
        const polys = focus_polys(F, keys, roles, 8)
        for (const p of polys) for (const pt of p) {
            expect(pt.x).toBeGreaterThanOrEqual(F.x - 0.5)
            expect(pt.x).toBeLessThanOrEqual(F.x + F.w + 0.5)
            expect(pt.y).toBeGreaterThanOrEqual(F.y - 0.5)
            expect(pt.y).toBeLessThanOrEqual(F.y + F.h + 0.5)
        }
    })

    test('a lone belly with no buds still stands, centred and bigger', () => {
        const solo = focus_polys(F, ['only'], ['belly'], 8)
        expect(solo.length).toBe(1)
        expect(area(solo[0])).toBeGreaterThan(F.w * F.h * 0.55)
    })

    test('extra bellies degrade to buds instead of fighting', () => {
        const polys = focus_polys(F, ['a', 'b'], ['belly', 'belly'], 8)
        expect(area(polys[0])).toBeGreaterThan(area(polys[1]) * 4)
    })

    test('different keys, different wobble — same key, same wobble', () => {
        const p1 = focus_polys(F, ['a', 's1'], ['belly', 'bud'], 8)
        const p2 = focus_polys(F, ['a', 's2'], ['belly', 'bud'], 8)
        expect(JSON.stringify(p1[0])).toBe(JSON.stringify(p2[0]))
        expect(JSON.stringify(p1[1])).not.toBe(JSON.stringify(p2[1]))
    })
})

// THE STRETCH — *"for the Heist we want it totally maxed out up in there"*.  The claim is a SIZE
//  claim, so the gates are about area and containment: it must take most of the body, all of it must
//   be inside the wall, and it must not care what shape the face wanted.
describe('the stretch — fill_rect', () => {
    const belly = () => focus_polys(F, ['Heist!0', 'Door!1'], ['belly', 'bud'], 8)[0]
    function centroid(p: Pt[]): Pt {
        let x = 0, y = 0
        for (const q of p) { x += q.x; y += q.y }
        return { x: x / p.length, y: y / p.length }
    }

    test('IT IS MAXED OUT — the box takes most of the body it is in', () => {
        const b = belly(), c = centroid(b)
        const r = fill_rect(b, c.x, c.y)
        // an inscribed rectangle in an ellipse tops out at 2/π ≈ 63.7% of it; anything near that is
        //  "maxed out", and anything much under it is the old content-sized seat leaving room empty.
        expect(r.w * r.h).toBeGreaterThan(area(b) * 0.55)
    })

    test('IT STAYS INSIDE THE WALL — every corner of the box is in the body', () => {
        const b = belly(), c = centroid(b)
        const r = fill_rect(b, c.x, c.y)
        for (const [sx, sy] of [[1, 1], [1, -1], [-1, 1], [-1, -1]])
            expect(inside({ x: c.x + (sx * r.w) / 2, y: c.y + (sy * r.h) / 2 }, b), `corner ${sx},${sy}`).toBe(true)
    })

    test('THE ASPECT IS ASSIGNED, NOT ASKED FOR — a tall body yields a tall box', () => {
        const tall = focus_polys({ x: 0, y: 0, w: 300, h: 900 }, ['only'], ['belly'], 8)[0]
        const wide = focus_polys({ x: 0, y: 0, w: 900, h: 300 }, ['only'], ['belly'], 8)[0]
        const ct = centroid(tall), cw = centroid(wide)
        const rt = fill_rect(tall, ct.x, ct.y)
        const rw = fill_rect(wide, cw.x, cw.y)
        expect(rt.h).toBeGreaterThan(rt.w)
        expect(rw.w).toBeGreaterThan(rw.h)
    })

    test('IT IS A PURE FUNCTION — same body, byte-same box', () => {
        const b = belly(), c = centroid(b)
        expect(JSON.stringify(fill_rect(b, c.x, c.y))).toBe(JSON.stringify(fill_rect(b, c.x, c.y)))
    })

    test('a degenerate body yields nothing rather than a lie', () => {
        expect(fill_rect([], 0, 0)).toEqual({ w: 0, h: 0 })
        expect(fill_rect([{ x: 0, y: 0 }, { x: 1, y: 1 }], 0, 0)).toEqual({ w: 0, h: 0 })
    })
})

// THE SWELL — *"the cell going off the screen top left and bottom … so we can use half the screen
//  efficiently"*.  Two claims, and they are in tension, which is why both are gated: the BODY must
//   leave the plate on three named sides, and the COMPONENT must not leave it at all.
describe('the swell — a belly bigger than its plate', () => {
    const ks = ['Heist!0', 'Door!1']
    const rs: FocusRole[] = ['belly', 'bud']
    const plain = () => focus_polys(F, ks, rs, 8)
    const swelled = () => focus_polys(F, ks, rs, 8, BELLY_SWELL)

    test('SWELL 1 IS THE IDENTITY — an unswelled belly is what it always was', () => {
        expect(JSON.stringify(focus_polys(F, ks, rs, 8, 1))).toBe(JSON.stringify(plain()))
    })

    test('IT LEAVES THE PLATE ON THREE SIDES — top, left and bottom, and only those', () => {
        const b = swelled()[0]
        expect(Math.min(...b.map(p => p.x))).toBeLessThan(F.x)                 // off the left
        expect(Math.min(...b.map(p => p.y))).toBeLessThan(F.y)                 // off the top
        expect(Math.max(...b.map(p => p.y))).toBeGreaterThan(F.y + F.h)        // off the bottom
        // …and NOT off the right: that rim is the buds' margin, and the swell pivots on it.
        const plainRight = Math.max(...plain()[0].map(p => p.x))
        expect(Math.max(...b.map(p => p.x))).toBeCloseTo(plainRight, 6)
    })

    test('THE BUDS ARE UNDISTURBED — still on the plate, still off the belly, never on it', () => {
        for (let n = 2; n <= 5; n++) {
            const keys = Array.from({ length: n }, (_, i) => `k${i}`)
            const roles: FocusRole[] = keys.map((_, i) => (i === 0 ? 'belly' : 'bud'))
            const polys = focus_polys(F, keys, roles, 8, BELLY_SWELL)
            for (let i = 1; i < polys.length; i++) {
                let mx = 0, my = 0, touching = 0
                for (const p of polys[i]) { mx += p.x; my += p.y }
                mx /= polys[i].length; my /= polys[i].length
                for (const pt of polys[i]) if (inside(pt, polys[0])) touching++
                expect(inside({ x: mx, y: my }, polys[0]), `bud ${i} of ${n} sits ON the belly`).toBe(false)
                expect(touching, `bud ${i} of ${n} floats free of the belly`).toBeGreaterThan(0)
                for (const pt of polys[i]) {
                    expect(pt.x).toBeGreaterThanOrEqual(F.x - 0.5)
                    expect(pt.x).toBeLessThanOrEqual(F.x + F.w + 0.5)
                    expect(pt.y).toBeGreaterThanOrEqual(F.y - 0.5)
                    expect(pt.y).toBeLessThanOrEqual(F.y + F.h + 0.5)
                }
            }
        }
    })

    test('THE PLATE CUTS IT — clip_frame keeps the visible part and nothing outside', () => {
        const cut = clip_frame(swelled()[0], F)
        expect(cut.length).toBeGreaterThan(3)
        for (const p of cut) {
            expect(p.x).toBeGreaterThanOrEqual(F.x - 1e-6)
            expect(p.x).toBeLessThanOrEqual(F.x + F.w + 1e-6)
            expect(p.y).toBeGreaterThanOrEqual(F.y - 1e-6)
            expect(p.y).toBeLessThanOrEqual(F.y + F.h + 1e-6)
        }
        // a body already inside its plate comes back unchanged in extent
        const inb = clip_frame(plain()[0], F)
        expect(area(inb)).toBeCloseTo(area(plain()[0]), 3)
    })

    test('THE COMPONENT NEVER LEAVES THE SCREEN — the seat is inside the plate, corners and all', () => {
        const r = fill_body(swelled()[0], F)
        for (const [sx, sy] of [[1, 1], [1, -1], [-1, 1], [-1, -1]]) {
            const cx = r.x + (sx * r.w) / 2, cy = r.y + (sy * r.h) / 2
            expect(cx).toBeGreaterThanOrEqual(F.x - 0.5)
            expect(cx).toBeLessThanOrEqual(F.x + F.w + 0.5)
            expect(cy).toBeGreaterThanOrEqual(F.y - 0.5)
            expect(cy).toBeLessThanOrEqual(F.y + F.h + 0.5)
        }
    })

    // THE POINT OF THE WHOLE CHANGE.  *"use half the screen efficiently"* — an inscribed belly's seat
    //  measured well under half the plate (round body, square plate, and the corners are the loss); a
    //   bled one must beat it decisively or the swell bought nothing but a bigger drawing.
    test('IT USES THE SCREEN — the bled seat takes over half the plate, and far more than the inscribed one', () => {
        const before = fill_body(plain()[0], F)
        const after = fill_body(swelled()[0], F)
        expect(after.w * after.h).toBeGreaterThan(F.w * F.h * 0.5)
        expect(after.w * after.h).toBeGreaterThan(before.w * before.h * 1.4)
    })

    test('IT IS A PURE FUNCTION — same plate, byte-same seat', () => {
        const b = swelled()
        expect(JSON.stringify(fill_body(b[0], F))).toBe(JSON.stringify(fill_body(b[0], F)))
    })

    test('a body that misses its plate yields nothing rather than a lie', () => {
        const away: Frame = { x: 5000, y: 5000, w: 100, h: 100 }
        expect(fill_body(swelled()[0], away)).toEqual({ x: 0, y: 0, w: 0, h: 0 })
        expect(clip_frame(swelled()[0], away)).toEqual([])
    })
})

// ── INCUMBENCY: the seat must not teleport ─────────────────────────────────────────────────────
//  The bug these gate (2026-08-11, the owner: *"Heist is flitting rapidly up and down"*): the seat
//   is an argmax over 81 lattice centres, the area landscape over a blob has broad near-equal peaks,
//    and the belly breathes continuously because the radio stirs the model.  So the winner flipped
//     between two rows on a sub-pixel difference and the Component jumped, several times a second.
//  The fix is incumbency, and what has to be true of it is a pair, not a single property: it must
//   HOLD a seat that is merely tied, and it must YIELD one that is genuinely beaten.  A gate for
//    only the first would pass just as happily on a seat that is welded in place.
describe('incumbency — a seat holds its ground but does not squat', () => {
    const ks = ['Heist!0', 'Door!1']
    const rs: FocusRole[] = ['belly', 'bud']
    const belly = () => focus_polys(F, ks, rs, 8, BELLY_SWELL)[0]

    test('NO KEEP IS THE OLD SWEEP — incumbency is opt-in, so every prior gate still means what it did', () => {
        const b = belly()
        expect(fill_body(b, F)).toEqual(fill_body(b, F, 3, null))
    })

    test('A TIED SEAT HOLDS — a centre a whisker off the winner keeps the seat instead of jumping to it', () => {
        const b = belly()
        const won = fill_body(b, F)
        // one unit off the winning centre: a different lattice answer, an all-but-identical area
        const near = { x: won.x + 1, y: won.y + 1 }
        const held = fill_body(b, F, 3, near)
        expect(held.x).toBe(near.x)
        expect(held.y).toBe(near.y)
        // and it is not a bad seat — holding still cost us almost nothing
        expect(held.w * held.h).toBeGreaterThan(won.w * won.h * 0.9)
    })

    // ⚠ THIS TEST FINDS ITS OWN INCUMBENT, and that is the whole point of it.  The obvious version —
    //  plant the seat hard against a wall and watch it move — passes with the handicap set to TWENTY:
    //   a corner seat is so bad that any margin short of absurd still lets a challenger take it, so
    //    the gate discriminates nothing and is theatre.  What has to be pinned is the MIDDLE of the
    //     range: a seat that is genuinely worse but not laughably so must still yield.  So sweep for a
    //      centre scoring 30–70% of the best and use that; it goes red the moment the handicap grows
    //       enough to let a half-price seat squat, which is the failure incumbency could actually
    //        introduce.
    test('A BEATEN SEAT YIELDS — a half-price seat is not allowed to squat', () => {
        const b = belly()
        const won = fill_body(b, F)
        const bA = won.w * won.h
        // sweep the CLIPPED body — the same polygon `fill_body` scores against.  Sweeping the raw
        //  belly instead was the first version of this test and it was worthless: off the plate the
        //   areas are wildly bigger, so "half price" there is a near-tie here and the gate passed
        //    under every margin.  Measure in the units the function decides in.
        const body = clip_frame(b, F)
        let mid: Pt | null = null
        for (let i = 1; i <= 15 && !mid; i++) for (let j = 1; j <= 15 && !mid; j++) {
            const cx = F.x + (F.w * i) / 16, cy = F.y + (F.h * j) / 16
            const r = fill_rect(body, cx, cy, 3)
            const a = r.w * r.h
            if (a > bA * 0.3 && a < bA * 0.7) mid = { x: cx, y: cy }
        }
        expect(mid).not.toBeNull()
        const moved = fill_body(b, F, 3, mid)
        expect(moved.x === mid!.x && moved.y === mid!.y).toBe(false)
        expect(moved.w * moved.h).toBeGreaterThan(bA * 0.9)
    })

    test('A KEEP THE BODY NO LONGER HOLDS IS IGNORED, not honoured into a zero seat', () => {
        const b = belly()
        const gone = fill_body(b, F, 3, { x: -9999, y: -9999 })
        expect(gone).toEqual(fill_body(b, F))
    })

    test('IT IS STILL PURE — same body, same keep, byte-same seat', () => {
        const b = belly(), k = { x: F.x + F.w / 2, y: F.y + F.h / 2 }
        expect(JSON.stringify(fill_body(b, F, 3, k))).toBe(JSON.stringify(fill_body(b, F, 3, k)))
    })
})
