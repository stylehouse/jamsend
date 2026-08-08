// scripts/vyto_see.mjs — LOOK at a `runner_shot --svg` capture, from a container with no browser.
//
//  WHY THIS EXISTS.  THE PIN's law A is "pixels or it didn't land", and Vyto's only camera is
//   `runner_shot --svg`, which returns SVG TEXT.  Reading coordinates out of that is not looking at it.
//    The first cut of the membrane rounding (2026-08-09) passed every compile check AND left the whole
//     Vyto* fleet green while quietly destroying the tessellation: cells bulged into balloons, every
//      corner ate itself, and neighbours stopped sharing walls.  Rendered to a character grid it was
//       obvious in one glance — coverage 82% where it should be ~99% — and the fix followed immediately.
//  A green Book could never have caught it.  A fixture is a dige of the C tree and the cell's `d` string
//   never reaches one, so wall SHAPE is structurally invisible to the Books.  This is the instrument for
//    exactly that blind spot, and it is why the shape work is not gated on the fleet alone.
//  Chromium/playwright CANNOT launch in the claude container (missing libglib-2.0), so this rasterises
//   itself rather than driving a browser.
//
//  usage:  node scripts/vyto_see.mjs <capture.svg> [columns]
//   · ~99% coverage with straight shared edges ⟹ the cells TILE, which is what a power diagram must do
//   · well under that, corners rounded off     ⟹ the wall shape is eating area; suspect path_round
//   · one glyph over everything                ⟹ a ONE-ROW world, not a bug (VytoTandem has 1 grapple)
//
//  rasterise a Vyto --svg capture to a character grid so the shapes can actually be LOOKED at
//  from here ("pixels or it didn't land", not "coordinates or it didn't land").
//  Handles exactly the grammar Vytui emits: `M x,y` / `M x y`, `L x,y`, `Q cx,cy x,y`, `Z`.  Quadratics
//   are flattened analytically (16 steps is far below a character cell), then each polygon is
//    scanline-filled with an even-odd test — which is exact for the convex-ish cells a power diagram cuts.
import { readFileSync } from 'fs'

const num = /-?\d+(?:\.\d+)?/g
export function flatten(d) {
    // tokenise into commands with their numbers, in order
    const parts = d.match(/[MLQZ][^MLQZ]*/gi) || []
    const pts = []
    let cur = null, start = null
    for (const p of parts) {
        const c = p[0].toUpperCase()
        const n = (p.slice(1).match(num) || []).map(Number)
        if (c === 'M') { cur = { x: n[0], y: n[1] }; start = cur; pts.push(cur) }
        else if (c === 'L') { cur = { x: n[0], y: n[1] }; pts.push(cur) }
        else if (c === 'Q') {
            const c1 = { x: n[0], y: n[1] }, e = { x: n[2], y: n[3] }
            for (let i = 1; i <= 16; i++) {
                const t = i / 16, u = 1 - t
                pts.push({ x: u * u * cur.x + 2 * u * t * c1.x + t * t * e.x,
                           y: u * u * cur.y + 2 * u * t * c1.y + t * t * e.y })
            }
            cur = e
        } else if (c === 'Z') { if (start) pts.push(start) }
    }
    return pts
}

function inside(poly, x, y) {
    let hit = false
    for (let i = 0, j = poly.length - 1; i < poly.length; j = i++) {
        const a = poly[i], b = poly[j]
        if ((a.y > y) !== (b.y > y) && x < ((b.x - a.x) * (y - a.y)) / (b.y - a.y) + a.x) hit = !hit
    }
    return hit
}

const file = process.argv[2]
const COLS = Number(process.argv[3] || 96)
const s = readFileSync(file, 'utf8')
const vb = (s.match(/viewBox="([^"]*)"/) || [, '0 0 800 450'])[1].split(/\s+/).map(Number)
const [vx, vy, vw, vh] = vb
const ROWS = Math.max(8, Math.round((COLS * vh) / vw / 2.1))   // /2.1 ≈ character aspect

// every drawn path, with its class, in paint order
const paths = [...s.matchAll(/<(path|circle)\b([^>]*)>/g)].map(m => {
    const attrs = m[2]
    const cls = (attrs.match(/class="([^"]*)"/) || [, ''])[1].replace(/\s*s-[A-Za-z0-9]+/g, '').trim()
    const d = (attrs.match(/\bd="([^"]*)"/) || [, ''])[1]
    if (m[1] === 'circle') {
        const cx = +(attrs.match(/cx="([^"]*)"/) || [, 0])[1], cy = +(attrs.match(/cy="([^"]*)"/) || [, 0])[1]
        const r = +(attrs.match(/\br="([^"]*)"/) || [, 0])[1]
        const poly = []
        for (let i = 0; i < 24; i++) poly.push({ x: cx + r * Math.cos((i / 24) * 2 * Math.PI), y: cy + r * Math.sin((i / 24) * 2 * Math.PI) })
        return { cls, poly }
    }
    return { cls, poly: d ? flatten(d) : [] }
}).filter(p => p.poly.length > 2)

// one glyph per cell index so neighbours are distinguishable at a glance
const GLYPH = '#@%&8OWMB$XZ*+='
const grid = Array.from({ length: ROWS }, () => Array(COLS).fill(' '))
const cells = paths.filter(p => /\bcell\b/.test(p.cls))
const other = paths.filter(p => !/\bcell\b/.test(p.cls))
cells.forEach((p, i) => {
    const g = GLYPH[i % GLYPH.length]
    for (let r = 0; r < ROWS; r++) for (let c = 0; c < COLS; c++) {
        const x = vx + ((c + 0.5) / COLS) * vw, y = vy + ((r + 0.5) / ROWS) * vh
        if (inside(p.poly, x, y)) grid[r][c] = g
    }
})
// vines/plug drawn as thin marks ON TOP so they are visible against the fill
for (const p of other) for (const pt of p.poly) {
    const c = Math.floor(((pt.x - vx) / vw) * COLS), r = Math.floor(((pt.y - vy) / vh) * ROWS)
    if (r >= 0 && r < ROWS && c >= 0 && c < COLS) grid[r][c] = /vine/.test(p.cls) ? '~' : (/plug/.test(p.cls) ? '-' : '.')
}

console.log(`${file}  viewBox ${vb.join(' ')}  ·  ${cells.length} cells, ${other.length} other paths  ·  ${COLS}x${ROWS} chars`)
console.log('+' + '-'.repeat(COLS) + '+')
for (const row of grid) console.log('|' + row.join('') + '|')
console.log('+' + '-'.repeat(COLS) + '+')
const labels = [...s.matchAll(/<text[^>]*class="([^"]*)"[^>]*>([^<]*)</g)].map(m => `${m[2]}${/under/.test(m[1]) ? '(under)' : ''}`)
console.log('labels:', labels.join(' · ') || '(none)')
const filled = grid.flat().filter(ch => ch !== ' ').length
console.log('coverage:', ((100 * filled) / (ROWS * COLS)).toFixed(1) + '%  ·  cell classes:', [...new Set(cells.map(c => c.cls))].join(' | '))
