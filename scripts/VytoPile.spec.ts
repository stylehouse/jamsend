// VytoPile.spec — the HAND's law, proven headless (the VytoSeat / VytoFocus / VytoPane siblings).
//  Glassbeast §0 "THE WALL, AND THE SHAPE OF ITS CRACK": the CAUSES (where a hand put a seed — `%Put`) snap in a
//   Book (VytoHand); the solve that turns them into seeds is a PURE function, extracted from Vyto_solve
//    2026-10-03 as `pile_rest` + `hand_pull` — so its laws are theorems here, by arithmetic, no browser.
//  Each claim has been seen to go red with its mechanism removed (hand_pull → identity reds 3 of 7).
// Run: node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/VytoPile.spec.ts
import { describe, it, expect } from 'vitest'
import { pile_rest, pile_step, hand_pull, type Pt } from '../src/lib/O/vyto_geometry'

const fw = 800, fh = 450, centre = { x: fw / 2, y: fh / 2 }
// six stones, VytoHand's shape: radii from doses, seeded on a ring
const radii = [3, 1, 2, 1, 2, 1].map(dose => Math.sqrt(4200 * (1 + dose) / Math.PI))
const ring = (): Pt[] => radii.map((_, i) => ({ x: centre.x + 160 * Math.cos(i), y: centre.y + 120 * Math.sin(i) }))
const none = radii.map(() => false)
const d = (a: Pt, b: Pt) => Math.hypot(a.x - b.x, a.y - b.y)
const free = () => pile_rest(ring(), radii, centre, [], none, null)

describe('pile_rest — the extraction moved nothing', () => {
    it('no puts ⇒ byte-identical to iterating pile_step by hand (the loop Vyto_solve used to hold)', () => {
        let s = ring(), pk = 0
        while (pk < 400) {
            const next = pile_step(s, radii, centre, [])
            let moved = 0
            for (let i = 0; i < s.length; i++) { const dd = Math.abs(next[i].x - s[i].x) + Math.abs(next[i].y - s[i].y); if (dd > moved) moved = dd }
            s = next; pk++
            if (moved < 0.05) pk = 999
        }
        expect(JSON.stringify(free())).toBe(JSON.stringify(s))
    })
    it('is deterministic — the same causes rest at the same seeds, to the bit', () => {
        expect(JSON.stringify(free())).toBe(JSON.stringify(free()))
    })
})

describe('the hand — a pin, an attractor, and neighbours that still press', () => {
    it('a PIN sits exactly where it was put', () => {
        const at = { x: 0.150 * fw, y: 0.750 * fh }
        const s = ring(); s[1] = { ...at }
        const pinned = none.slice(); pinned[1] = true
        const puts = radii.map(() => null) as ({ x: number, y: number, k: number } | null)[]; puts[1] = { ...at, k: 0.15 }
        expect(d(pile_rest(s, radii, centre, [], pinned, puts)[1], at)).toBe(0)
    })
    it('an ATTRACTOR rests nearer its place than free — and arrives within its own radius', () => {
        const at = { x: 0.850 * fw, y: 0.250 * fh }
        const puts = radii.map(() => null) as ({ x: number, y: number, k: number } | null)[]; puts[3] = { ...at, k: 0.15 }
        const r = pile_rest(ring(), radii, centre, [], none, puts)
        expect(d(r[3], at)).toBeLessThan(d(free()[3], at))
        expect(d(r[3], at)).toBeLessThan(radii[3])
    })
    it('an attractor put onto a neighbour is PRESSED OFF the spot (the owner: "or be like an attractor")', () => {
        const at = { ...free()[0] }
        const puts = radii.map(() => null) as ({ x: number, y: number, k: number } | null)[]; puts[3] = { ...at, k: 0.15 }
        expect(d(pile_rest(ring(), radii, centre, [], none, puts)[3], at)).toBeGreaterThan(1)
    })
    it('hand_pull moves k of the way toward the place', () => {
        expect(hand_pull({ x: 0, y: 0 }, { x: 100, y: 50, k: 0.15 })).toEqual({ x: 15, y: 7.5 })
    })
})
