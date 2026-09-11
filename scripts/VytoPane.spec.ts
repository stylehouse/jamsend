// VytoPane.spec.ts — the folio's geometry, proven headless (the VytoFoldLadder.spec.ts sibling).
//  Run: node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/VytoPane.spec.ts
import { describe, it, expect } from 'vitest'
import { pane_rows, rows_of, tuple_frame, poly_chord, disc_poly, inside, seat_box, atom, GLY, FS_FLOOR,
         type Pt, type Atom } from '../src/lib/O/vyto_pane'

// a seeded PRNG so a failure is reproducible
function rng(seed: number) { let s = seed >>> 0; return () => { s = (s * 1664525 + 1013904223) >>> 0; return s / 4294967296 } }

// a random convex polygon: a wobbled n-gon, scaled anisotropically, rotated — the shapes a power cut makes
function convex(r: () => number, cx = 300, cy = 200): Pt[] {
    const n = 4 + Math.floor(r() * 7)
    const rx = 30 + r() * 170, ry = 30 + r() * 170, rot = r() * Math.PI
    const pts: Pt[] = []
    for (let i = 0; i < n; i++) {
        const t = (i / n) * Math.PI * 2 + (r() - 0.5) * (Math.PI / n) * 0.8
        const x = rx * Math.cos(t), y = ry * Math.sin(t)
        pts.push({ x: cx + x * Math.cos(rot) - y * Math.sin(rot), y: cy + x * Math.sin(rot) + y * Math.cos(rot) })
    }
    return pts
}
const words = ['Cog', 'metal', 'brass', 'iron', 'LowTide', 'artist', 'Yara', 'mood', 'brine', 'of', 'main', 'finished', 'a', 'seventeenletters!', 'x']
function rows_rand(r: () => number): Atom[][] {
    const nrows = 1 + Math.floor(r() * 6)
    const rows: Atom[][] = [[atom(words[Math.floor(r() * words.length)] + ':' + Math.floor(r() * 9), 14, 'fo-title')]]
    for (let i = 1; i < nrows; i++) {
        const natoms = 1 + Math.floor(r() * 4)
        const row: Atom[] = []
        for (let j = 0; j < natoms; j++) row.push(atom(words[Math.floor(r() * words.length)], j ? 9 : 10))
        rows.push(row)
    }
    return rows
}

describe('tuple_frame — the baseline follows the biggest top-left wall', () => {
    it('is quantised to 15° and never steeper than 45°', () => {
        const r = rng(7)
        for (let i = 0; i < 300; i++) {
            const th = tuple_frame(convex(r))
            expect(Math.abs(th)).toBeLessThanOrEqual(Math.PI / 4 + 1e-9)
            const q = th / (Math.PI / 12)
            expect(Math.abs(q - Math.round(q))).toBeLessThan(1e-9)
        }
    })
    it('a square stays level; a parallelogram leaning 30° tilts to it', () => {
        expect(tuple_frame([{ x: 0, y: 0 }, { x: 100, y: 0 }, { x: 100, y: 100 }, { x: 0, y: 100 }])).toBe(0)
        const s = Math.tan(Math.PI / 6) * 100
        const th = tuple_frame([{ x: 0, y: 0 }, { x: 100, y: s }, { x: 100, y: 100 + s }, { x: 0, y: 100 }])
        expect(th).toBeCloseTo(Math.PI / 6, 6)
    })
})

describe('poly_chord', () => {
    it('reads the width of a square at every height inside it and misses outside', () => {
        const sq = [{ x: 10, y: 10 }, { x: 110, y: 10 }, { x: 110, y: 60 }, { x: 10, y: 60 }]
        expect(poly_chord(sq, 30)).toEqual([10, 110])
        expect(poly_chord(sq, 5)).toBeNull()
        expect(poly_chord(sq, 65)).toBeNull()
    })
})

describe('pane_rows — every seated glyph box lies inside its cell', () => {
    it('600 random cells × random rows: no seat leaves the wall, hid counts the rest', () => {
        const r = rng(42)
        let seated = 0, hidden = 0, degraded = 0
        for (let i = 0; i < 600; i++) {
            const poly = convex(r)
            const cx = poly.reduce((a, p) => a + p.x, 0) / poly.length, cy = poly.reduce((a, p) => a + p.y, 0) / poly.length
            const rows = rows_rand(r)
            const total = rows.reduce((a, row) => a + row.length, 0)
            const pane = pane_rows(poly, cx, cy, rows)
            if (!pane) { degraded++; continue }
            expect(pane.seats.length + pane.hid).toBe(total)
            for (const s of pane.seats) {
                expect(s.fs).toBeGreaterThanOrEqual(FS_FLOOR - 1e-9)
                for (const c of seat_box(s)) {
                    // 2.5px of slack: the ascender box is a little taller than the chord the line was seated against
                    expect(inside(poly, c, 2.5)).toBe(true)
                }
            }
            seated += pane.seats.length; hidden += pane.hid
        }
        // the sample is not degenerate: most atoms seat, some cells are too small to say everything
        expect(seated).toBeGreaterThan(hidden)
        expect(hidden).toBeGreaterThan(0)
        expect(degraded).toBeLessThan(600)
    })
    it('the title is the first seat and nothing out-sizes it', () => {
        const r = rng(3)
        for (let i = 0; i < 200; i++) {
            const poly = convex(r)
            const cx = poly.reduce((a, p) => a + p.x, 0) / poly.length, cy = poly.reduce((a, p) => a + p.y, 0) / poly.length
            const pane = pane_rows(poly, cx, cy, rows_rand(r))
            if (!pane) continue
            expect(pane.seats[0].cls).toBe('fo-title')
            const title = pane.seats[0].fs
            // a title squeezed under the floor does not cap its rows below legibility: the floor wins
            for (const s of pane.seats.slice(1)) expect(s.fs).toBeLessThanOrEqual(Math.max(title, FS_FLOOR + 1) + 1e-9)
        }
    })
    it('a cell too small for its own title degrades to null rather than drawing a smudge', () => {
        const tiny = disc_poly(0, 0, 6)
        expect(pane_rows(tiny, 0, 0, [[atom('Vtuffing:Cog', 14, 'fo-title')]])).toBeNull()
    })
    it('a bigger room inflates the same rows (zoom > 1) and never past the ceiling', () => {
        const rows = rows_of('Cog:4', [{ k: 'metal', v: 'brass' }, { k: 'dose', v: '2' }], null)
        const small = pane_rows(disc_poly(0, 0, 40), 0, 0, rows)
        const big = pane_rows(disc_poly(0, 0, 160), 0, 0, rows)
        expect(small && big).toBeTruthy()
        expect(big!.zoom).toBeGreaterThan(small!.zoom)
        expect(big!.zoom).toBeLessThanOrEqual(2.0)
        expect(big!.seats[0].fs).toBeGreaterThan(small!.seats[0].fs)
    })
    it('lines are seated between chords: on a diamond the rows are narrower near the tips', () => {
        const dia = [{ x: 0, y: -100 }, { x: 120, y: 0 }, { x: 0, y: 100 }, { x: -120, y: 0 }]
        const rows: Atom[][] = [[atom('T', 12, 'fo-title')]]
        for (let i = 0; i < 12; i++) rows.push([atom('wwwwwwwwwwwwwwwwwwwwwwwwwwwwww', 10)])
        const pane = pane_rows(dia, 0, 0, rows, { norot: true, inflate: false })
        expect(pane).toBeTruthy()
        const widths = pane!.seats.map(s => ({ y: s.y, w: s.text.length * GLY * s.fs }))
        // the seat nearest a tip is narrower than the widest seat, and the widest sits nearer the middle
        const widest = widths.reduce((a, b) => (b.w > a.w ? b : a))
        const tip = widths.reduce((a, b) => (Math.abs(b.y) > Math.abs(a.y) ? b : a))
        expect(tip.w).toBeLessThan(widest.w)
        expect(Math.abs(widest.y)).toBeLessThan(Math.abs(tip.y))
    })
    it('a level cell reads level; a rotated pane reports its angle on every seat', () => {
        const sq = [{ x: 0, y: 0 }, { x: 200, y: 0 }, { x: 200, y: 100 }, { x: 0, y: 100 }]
        const p = pane_rows(sq, 100, 50, rows_of('A', [], null))!
        expect(p.rot).toBe(0)
        const s = Math.tan(Math.PI / 6) * 200
        const para = [{ x: 0, y: 0 }, { x: 200, y: s }, { x: 200, y: 100 + s }, { x: 0, y: 100 }]
        const q = pane_rows(para, 100, 50 + s / 2, rows_of('A', [], null))!
        expect(q.rot).toBeCloseTo(30, 0)
        for (const st of q.seats) expect(st.rot).toBeCloseTo(30, 0)
    })
})

describe('rows_of — what a cell says, in the snap\'s own grammar', () => {
    it('a plain row: title, then the scalars as ONE flowing row of key/value pairs, capped with +N', () => {
        const guts = Array.from({ length: 11 }, (_, i) => ({ k: 'k' + i, v: 'v' + i }))
        const rows = rows_of('Cog:3.B', guts, null, { max_facts: 8 })
        expect(rows[0][0].text).toBe('Cog:3.B')
        expect(rows.length).toBe(1 + 1 + 1)                       // title · the facts line · the +N tail
        expect(rows[2][0].text).toBe('+3')
        expect(rows[1].length).toBe(16)                          // 8 pairs
        expect(rows[1].slice(0, 4).map(a => a.text)).toEqual(['k0', 'v0', 'k1', 'v1'])
        expect(rows[1][0].pair).toBe(true)                        // a key owns its value — they wrap as a unit
        expect(rows[1][1].pair).toBeFalsy()
        // and a split title wears the fact-key look on its mainkey, title size on its value
        const t = rows_of({ mk: 'Song', v: 'LowTide' }, [], null, {})[0]
        expect(t.map(a => a.text)).toEqual(['Song', 'LowTide'])
        expect(t[0].afs).toBeLessThan(t[1].afs)
        expect(t[0].k).toBe('Song'); expect(t[1].k).toBe('Song')
    })
    it('a crest: the door first (×N + the query), then veins, facts, spreads with chips', () => {
        const rows = rows_of('Vtuffing:Cog', [], [
            { row: 'spread', k: 'metal', bits: [{ v: 'brass', n: 3 }, { v: 'iron', n: 1 }, { text: '+2' }] },
            { row: 'fact', k: 'of', v: 'main' },
            { row: 'fact', k: 'finished', n: 2 },
            { row: 'vein', v: 'brine', bits: [{ k: 'mood', n: 2 }, { k: 'tag', n: 1 }] },
            { row: 'dip', n: 5, q: '@mainkey=Cog' },
        ])
        const texts = rows.map(r => r.map(a => a.text))
        expect(texts[0]).toEqual(['Vtuffing:Cog'])
        expect(texts[1]).toEqual(['×5', '@mainkey=Cog'])
        expect(texts[2]).toEqual(['brine', 'mood×2', 'tag'])
        expect(texts[3]).toEqual(['of', 'main'])
        expect(texts[4]).toEqual(['finished', '×2'])
        expect(texts[5]).toEqual(['metal', 'brass×3', 'iron', '+2'])
        expect(rows[5][3].cls).toBe('fo-more')
    })
})
