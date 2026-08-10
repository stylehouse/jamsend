// VytoFocus.spec — the focus regime's gates.  The claims that matter:
//  · NOBODY IS SWALLOWED: every key gets a real polygon, always — "no room" is unrepresentable.
//  · IT IS A PURE FUNCTION: same inputs, byte-same output — stillness by type signature, so
//    "I don't want it moving at all after it settles" is a theorem, not a damping constant.
//  · THE BELLY IS BIG and the buds are small and ATTACHED — the look is the spec.
// Run: node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/VytoFocus.spec.ts

import { describe, test, expect } from 'vitest'
import { focus_polys, type Pt, type Frame, type FocusRole } from '../src/lib/O/vyto_focus'

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
