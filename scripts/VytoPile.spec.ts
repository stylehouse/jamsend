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

// THE GRID OF SAMENESS — the alignment is the tie (grid2_cells, vyto_geometry.ts)
import { grid2_cells, grid_keys } from '../src/lib/O/vyto_geometry'
import { bucket_key_of } from '../src/lib/O/vyto_foam'
describe('grid2_cells — things that share a fact line up', () => {
    const scs = [
        { Vessel: 'crown', tide: 'high', dose: '3' }, { Vessel: 'port', tide: 'high', reef: 'north', dose: '2' },
        { Vessel: 'starboard', tide: 'low', reef: 'north', dose: '2' }, { Vessel: 'keel-a', tide: 'low', reef: 'south', dose: '1' },
        { Vessel: 'keel-b', tide: 'high', reef: 'south', dose: '1' }, { Vessel: 'keel-c', tide: 'low', reef: 'south', dose: '1' },
    ]
    const radii = scs.map(s => 20 + 10 * Number(s.dose))
    const frame = { x: 0, y: 0, w: 800, h: 450 }
    const keys = grid_keys(scs, bucket_key_of)
    const g = grid2_cells(scs, radii, frame, 4, keys)
    const box = (p: { x: number, y: number }[]) => ({ x: p[0].x, y: p[0].y, cx: (p[0].x + p[1].x) / 2, cy: (p[0].y + p[2].y) / 2 })
    it('elects real facts for the axes, never a glass channel (dose)', () => {
        expect(keys[0]).not.toBe('dose'); expect(keys[1]).not.toBe('dose')
        expect(new Set(keys)).toEqual(new Set(['tide', 'reef']))
    })
    it('same ROW value ⇒ same row band; same COLUMN value ⇒ same column, across rows', () => {
        const rowKey = keys[0]!, colKey = keys[1]!
        const B = g.polys.map(p => box(p!))
        for (let i = 0; i < 6; i++) for (let j = 0; j < 6; j++) {
            if (i === j) continue
            if (scs[i][rowKey as 'tide'] === scs[j][rowKey as 'tide']) expect(Math.abs(B[i].cy - B[j].cy)).toBeLessThan(40)
        }
        // columns align: two things sharing the column value start at the same x
        const byCol: Record<string, number[]> = {}
        scs.forEach((s, i) => { const v = (s as any)[colKey]; if (v) (byCol[v] ||= []).push(i) })
        // the CELL starts align (two things sharing both values sit side by side inside one cell — compare each row's first)
        for (const ids of Object.values(byCol)) {
            const firstPerRow: Record<string, number> = {}
            for (const i of ids) { const rv = (scs[i] as any)[rowKey]; firstPerRow[rv] = Math.min(firstPerRow[rv] ?? Infinity, B[i].x) }
            const xs = Object.values(firstPerRow); expect(Math.max(...xs) - Math.min(...xs)).toBeLessThan(0.01)
        }
    })
    it('says each shared value ONCE — one label per row value and per column value', () => {
        expect(g.rows.map(r => r.value).sort()).toEqual([...new Set(scs.map(s => (s as any)[keys[0]!]).filter(Boolean))].sort())
        expect(g.cols.map(c => c.value).sort()).toEqual([...new Set(scs.map(s => (s as any)[keys[1]!]).filter(Boolean))].sort())
    })
    it('nothing overlaps and everything is inside the frame', () => {
        const R = g.polys.map(p => ({ x0: p![0].x, y0: p![0].y, x1: p![2].x, y1: p![2].y }))
        for (const r of R) { expect(r.x0).toBeGreaterThanOrEqual(-0.01); expect(r.y0).toBeGreaterThanOrEqual(-0.01); expect(r.x1).toBeLessThanOrEqual(800.01); expect(r.y1).toBeLessThanOrEqual(450.01) }
        for (let i = 0; i < R.length; i++) for (let j = i + 1; j < R.length; j++) {
            const a = R[i], b = R[j]
            expect(a.x1 <= b.x0 + 0.01 || b.x1 <= a.x0 + 0.01 || a.y1 <= b.y0 + 0.01 || b.y1 <= a.y0 + 0.01).toBe(true)
        }
    })
})
