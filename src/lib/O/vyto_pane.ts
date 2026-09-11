// vyto_pane.ts — THE FOLIO: a cell's words laid into its own shape, the way a magazine lays a page.
//
//  Pure geometry, no Svelte, no C — node-testable (scripts/VytoPane.spec.ts), the vyto_geometry.ts
//   discipline.  Ported from Cytui.svelte's `tuple_frame` / `pane_rows` (the 'tuples' face of the
//    old Voro glass — the one piece of that renderer the owner called *"a breakthrough in
//     legibility: putting the words along the wall of the cell"*) which never crossed the moult.
//      Vytui had a name-in-the-wall textPath and a corridor of guts; it had no way to FLOW rows
//       of text into a polygon so that every line sits inside the wall and the block fills the room.
//
//  THE THREE MOVES, each the owner's own sentence:
//   1. ALIGN TO THE WALL — the baseline turns to the cell's *"biggest top-left-est cell wall"*
//      (`tuple_frame`): longest wall wins, weighted toward the top-left, upright, ≤45°, quantised
//       to 15° so neighbours agree exactly without a cross-cell solve.
//   2. SEAT BETWEEN CHORDS — each line's BOX is fitted between the polygon's chords at its top AND
//      bottom edge, so a sloping wall can never clip the ascenders (*"a line obscured by the
//       cellwall above it"*).  Over-wide atoms shrink to a 7px floor; what will not seat folds
//        into `hid`, counted, never drawn half.
//   3. INFLATE, THEN UNFOLD — measure at 1×, grow the whole stack to fill the spare height
//      (*"inflating into its potential space"*), then drop it by half the remaining spare
//       (*"typography-spatialising for maximum central unfoldment"*) — a convex cell is widest
//        in the middle, so the drop usually helps the seat.
//
//  What this module does NOT do: decide what the rows SAY.  `rows_of` below assembles rows from
//   plain descriptors (ident + facts + a crest's distilled Vrows) so the composition is testable
//    too, but reading a C row is the renderer's job.

export type Pt = { x: number, y: number }

// one atom of text — `len` is its width estimate in glyphs (filled by `atom`), `afs` its asked size
export type Atom = { text: string, afs: number, cls: string, hue?: string, len: number, k?: string, pair?: boolean }
// one atom landed — (x,y) is the START of the baseline, in the caller's coordinates, rotated `rot`°
export type Seat = { text: string, x: number, y: number, fs: number, rot?: number, cls: string, hue?: string, k?: string, line: number }

export type Pane = { seats: Seat[], hid: number, used: number, avail: number, rot: number, zoom: number }

export const GLY = 0.62                        // em-width of one glyph in the mono face (Cytui's constant)
export const FS_FLOOR = 7                      // below this a glyph is a smudge — fold rather than shrink further

export function atom(text: string, afs: number, cls = 'fo-fact', hue?: string, k?: string): Atom {
    return { text, afs, cls, hue, k, len: text.length + 0.4 }
}

// the horizontal chord of a polygon at height y — [x0, x1] or null when y misses it
export function poly_chord(poly: Pt[], y: number): [number, number] | null {
    let x0 = Infinity, x1 = -Infinity, hit = false
    for (let i = 0; i < poly.length; i++) {
        const a = poly[i], b = poly[(i + 1) % poly.length]
        if ((a.y - y) * (b.y - y) > 0) continue
        const dy = b.y - a.y
        if (Math.abs(dy) < 1e-6) { x0 = Math.min(x0, a.x, b.x); x1 = Math.max(x1, a.x, b.x) }
        else {
            const x = a.x + (b.x - a.x) * (y - a.y) / dy
            x0 = Math.min(x0, x); x1 = Math.max(x1, x)
        }
        hit = true
    }
    if (!hit || x1 <= x0) return null
    return [x0, x1]
}

// the WRITING DIRECTION of a pane: text hangs off the cell's OWN shape — the biggest top-left-est
//  wall.  Returns radians, upright (−90°, 90°], rejected past 45°, quantised to 15°.
export function tuple_frame(poly: Pt[]): number {
    const xs = poly.map(p => p.x), ys = poly.map(p => p.y)
    const bx0 = Math.min(...xs), bw = Math.max(...xs) - bx0 || 1
    const by0 = Math.min(...ys), bh = Math.max(...ys) - by0 || 1
    let best = 0, score = -1
    for (let i = 0; i < poly.length; i++) {
        const a = poly[i], b = poly[(i + 1) % poly.length]
        const len = Math.hypot(b.x - a.x, b.y - a.y)
        if (len < 8) continue
        let th = Math.atan2(b.y - a.y, b.x - a.x)
        if (th > Math.PI / 2) th -= Math.PI
        else if (th <= -Math.PI / 2) th += Math.PI
        if (Math.abs(th) > Math.PI / 4 + 1e-3) continue
        const mx = (a.x + b.x) / 2, my = (a.y + b.y) / 2
        const tl = 1 - ((mx - bx0) / bw + (my - by0) / bh) / 2      // 1 at the top-left corner
        const read = 0.35 + 0.65 * Math.cos(th) * Math.cos(th)     // a steep baseline reads badly
        const s = len * (0.5 + tl) * read
        if (s > score) { score = s; best = th }
    }
    return Math.round(best / (Math.PI / 12)) * (Math.PI / 12)
}

// a circle as a polygon — a disc cell has no wall, so it gets one to write in
export function disc_poly(cx: number, cy: number, r: number, n = 24): Pt[] {
    const out: Pt[] = []
    for (let i = 0; i < n; i++) { const t = (i / n) * Math.PI * 2; out.push({ x: cx + r * Math.cos(t), y: cy + r * Math.sin(t) }) }
    return out
}

export type PaneOpts = { toppad?: number, inflate?: boolean, capfs?: number, norot?: boolean, maxzoom?: number, pad?: number, top?: boolean }

// pane_rows — flow ROWS of atoms into a convex polygon.  rows[0] is load-bearing: if it cannot
//  seat, the pane degrades (null).  Seats return in ORIGINAL coordinates, pivoted about (cx, cy).
export function pane_rows(poly: Pt[], cx: number, cy: number, rows: Atom[][], opts?: PaneOpts): Pane | null {
    if (!rows.length || poly.length < 3) return null
    const th = opts?.norot ? 0 : tuple_frame(poly)
    const cosR = Math.cos(-th), sinR = Math.sin(-th)
    const rpoly = poly.map(p => ({ x: cx + (p.x - cx) * cosR - (p.y - cy) * sinR,
                                   y: cy + (p.x - cx) * sinR + (p.y - cy) * cosR }))
    const cosB = Math.cos(th), sinB = Math.sin(th)
    const deg = Math.abs(th) > 1e-3 ? +(th * 180 / Math.PI).toFixed(1) : undefined
    const rys = rpoly.map(p => p.y)
    const ry0 = Math.min(...rys), ry1 = Math.max(...rys)
    const pad = opts?.pad ?? 5                 // breathing room off the wall, both sides of a chord
    const availH = ry1 - ry0 - 6
    // the widest chord the cell has at all (9 samples) — a SMALL cell seats its title there, shrunk, rather
    //  than asking for room it can never have and saying nothing (the strays came up mute)
    let widest = 0
    for (let i = 1; i < 10; i++) { const c = poly_chord(rpoly, ry0 + (ry1 - ry0) * i / 10); if (c && c[1] - c[0] > widest) widest = c[1] - c[0] }
    widest = Math.max(6, widest - 2 * pad)
    const toppad = opts?.toppad ?? 4
    const line_span = (ytop: number, lh: number, padx = pad): [number, number] | null => {
        // the chords are read at the line box's TRUE top and bottom (1px in), so a glyph's ascender
        //  and descender are inside the wall by construction — the test's seat_box is this same box
        const a = poly_chord(rpoly, ytop + 1), b = poly_chord(rpoly, ytop + lh - 1)
        if (!a || !b) return null
        const lo = Math.max(a[0], b[0]) + padx, hi = Math.min(a[1], b[1]) - padx
        return hi - lo > 6 ? [lo, hi] : null
    }
    const layout = (zoom: number, tp = toppad): Pane | null => {
        const seats: Seat[] = []
        let cap = opts?.capfs ?? Infinity
        let ycur = ry0 + tp, hid = 0, dry = false, line = 0
        // tight: the TITLE row — its value wrapping under its mainkey is not a treeing continuation, so no
        //  indent and a 2-unit wall pad; in a slim wedge that is the difference between 'SaltA…' and 'SaltAir'
        const flow = (atoms: Atom[], tight = false) => {
            if (!atoms.length) return
            if (dry) { hid += atoms.length; return }
            // the line box is as tall as the atoms will actually BE, not as tall as they asked: an atom the
            //  widest chord will only hold at 8px must not hunt for a 17-unit-tall band (SaltAir never found one)
            const lh = Math.max(...atoms.map(a => Math.min(a.afs * zoom, cap, Math.max(FS_FLOOR, widest / (a.len * GLY))))) * 1.24
            // the room a line NEEDS before it will sit: its first atom at its asked size, capped at 60px —
            //  so the lead row steps past a wedge's tip to where it can be read, rather than seating a
            //   7px smudge at the apex and capping everything under it.
            // ...but never LESS than the atom needs at the 7px floor when the cell can give it (up to 95%
            //  of its widest chord) — stopping at the first 85% chord left 'SaltAi…' one glyph short of a word
            const floorW = atoms[0].len * GLY * FS_FLOOR
            const need = Math.min(60, Math.max(widest * 0.85, Math.min(widest * 0.95, floorW)), atoms[0].len * GLY * Math.min(atoms[0].afs * zoom, cap))
            let ch = line_span(ycur, lh)
            while ((!ch || ch[1] - ch[0] < need) && ycur + lh < ry1 - 3) { ycur += lh * 0.5; ch = line_span(ycur, lh) }
            if (!ch || ycur + lh > ry1 - 3) { dry = true; hid += atoms.length; return }
            let x = ch[0], right = ch[1], fresh = true
            const indent = Math.min(atoms[0].afs * zoom, cap) * 1.4
            for (let ai = 0; ai < atoms.length; ai++) {
                const a = atoms[ai]
                if (dry) { hid++; continue }
                let afs = Math.min(a.afs * zoom, cap), w = a.len * GLY * afs
                // a key that owns the next atom wraps as a UNIT: measure key + gap + value before placing the key
                const nx = a.pair && atoms[ai + 1] ? atoms[ai + 1] : null
                const wpair = nx ? w + afs * 0.55 + nx.len * GLY * Math.min(nx.afs * zoom, cap) : w
                if (!fresh && x + wpair > right) {                 // wrap — the treeing indent
                    ycur += lh; line++
                    const nch = line_span(ycur, lh, tight ? 2 : pad)
                    if (!nch || ycur + lh > ry1 - 3) { dry = true; hid++; continue }
                    // the treeing indent is for a WIDE cell; in a narrow one it eats the line — cap it to a
                    //  slice of the chord so a wrapped value still has room to be a word
                    x = nch[0] + (tight ? 0 : Math.min(indent, (nch[1] - nch[0]) * 0.15)); right = nch[1]
                }
                const room = right - x
                let text = a.text
                if (w > room) {                                    // over-wide atom — shrink, floor 7
                    afs = Math.max(FS_FLOOR, room / (GLY * a.len))
                    w = a.len * GLY * afs
                    if (w > room + 0.5) {
                        // still too wide at the floor: an ELLIPSIS, never a glyph past the wall.  Fewer than
                        //  four characters is not a word — that atom folds into hid and the line goes on.
                        const keep = Math.floor(room / (GLY * afs)) - 1
                        if (keep < 3) { hid++; continue }
                        text = a.text.slice(0, keep) + '…'
                        w = (text.length + 0.4) * GLY * afs
                    }
                }
                const rx = x, ry = ycur + lh * 0.8
                seats.push({ text, cls: a.cls, hue: a.hue, k: a.k, fs: afs, rot: deg, line,
                             x: cx + (rx - cx) * cosB - (ry - cy) * sinB,
                             y: cy + (rx - cx) * sinB + (ry - cy) * cosB })
                x += w + afs * 0.55
                fresh = false
            }
            ycur += lh + 1.5; line++
        }
        for (let ri = 0; ri < rows.length; ri++) {
            flow(rows[ri], ri === 0)
            if (ri === 0) {
                if (!seats.length) return null                      // the lead line didn't seat — degrade
                cap = Math.min(cap, Math.max(FS_FLOOR + 1, Math.max(...seats.map(s => s.fs)) * 0.92))
            }
        }
        return { seats, hid, used: ycur - ry0 - tp + toppad, avail: availH, rot: deg ?? 0, zoom }
    }
    let res = layout(1), zused = 1
    // the wall-aligned frame is a PREFERENCE, not a law: a slim wedge whose chords shrink further once
    //  rotated (SaltAir on Orchestra, 50×51 units, said nothing) still seats its title upright — try
    //   that before degrading to no words at all (the blank-bit floor is a worse look than a level title)
    if (!res) return (opts?.norot || Math.abs(th) < 1e-3) ? null : pane_rows(poly, cx, cy, rows, { ...opts, norot: true })
    // INFLATE BY LADDER (2026-09-11, the owner: "maxing out left-right top-bottom-ness and available
    //  space"): one guess at a zoom, rejected whole if a single atom then hid, left big cells half empty.
    //   Walk down from the ceiling and keep the LARGEST zoom that seats everything the 1× layout seated.
    if (opts?.inflate !== false && res.hid === 0 && res.used > 8 && availH / res.used > 1.15) {
        const top = Math.min(opts?.maxzoom ?? 2.0, 1 + (availH / res.used - 1) * 0.85)
        for (let zoom = top; zoom > 1.05; zoom -= 0.1) {
            const up = layout(zoom)
            if (up && up.seats.length === res.seats.length && up.hid === 0) { res = up; zused = zoom; break }
        }
    }
    const spare = availH - res.used
    if (spare > 10 && !opts?.top) {
        const down = layout(zused, toppad + spare / 2)
        if (down && down.hid === res.hid && down.seats.length === res.seats.length) res = down
    }
    return res
}

// ── WHAT A CELL SAYS — rows from plain descriptors ────────────────────────────────────────────────
//  A plain row: its ident, then its scalars one per line.  A CREST (a fold's distilled voice, the
//   `%Vrow` tree Vyto_distil writes): the door first (×N and the query that reopens it), then the
//    veins (one value crossing keys, said once), the facts, the spreads with their chips.  This is the
//     snap's own grammar — `k: v` rows, a `×n` count, `+N` for what did not fit — laid as type.
export type VrowDesc = { row: string, k?: string, v?: string, n?: number, q?: string, text?: string,
                         bits?: { k?: string, v?: string, n?: number, text?: string }[] }
export type RowsOpts = { title_fs?: number, fact_fs?: number, chip_fs?: number, max_facts?: number, hue?: string, key_hue?: string }

// ident: a plain string (a crest key, or anything with no clean mainkey:value split — drawn as one
//  bold run), or a { mk, v } pair (the ordinary case) drawn as TWO atoms so the title wears the SAME
//   key-lilac/value-white convention every fact line already does (the owner: "a more universal k:v
//    style, like artist:Yara is... to Song too") — and so the title's own atoms carry `k` (the
//     mainkey name), the same field every fact atom already carries, letting a caller glow the title
//      and its matching fact/source line together on hover without caring which one it started from.
export function rows_of(ident: string | { mk: string, v: string, hide_mk?: boolean }, guts: { k: string, v: string }[], vrows: VrowDesc[] | null, o?: RowsOpts): Atom[][] {
    const T = o?.title_fs ?? 14, F = o?.fact_fs ?? 10, C = o?.chip_fs ?? 9
    // hide_mk: the mainkey is said elsewhere (a shared junction label) — the title is the value alone,
    //  still tagged k=mk so it glows with the junction and every sibling's value together
    const titleRow: Atom[] = (typeof ident === 'object' && ident.v)
        ? (ident.hide_mk ? [atom(ident.v, T, 'fo-title fo-title-val', o?.hue, ident.mk)]
                         // the mainkey wears the FACT-KEY look (artist, mood — size F, lilac, 600), not the title's: the owner,
                         //  2026-09-11: "Song (mainkey) could look more like the other keys"; only the value is the title
                         : [atom(ident.mk, F, 'fo-key fo-title-key', o?.key_hue, ident.mk), atom(ident.v, T, 'fo-title fo-title-val', o?.hue, ident.mk)])
        : [atom(typeof ident === 'object' ? ident.mk : ident, T, 'fo-title', o?.hue, typeof ident === 'object' ? ident.mk : undefined)]
    const rows: Atom[][] = [titleRow]
    if (vrows && vrows.length) {
        const dip = vrows.find(r => r.row === 'dip')
        if (dip) {
            const line = [atom('×' + (dip.n ?? 0), F, 'fo-dip', o?.hue)]
            if (dip.q) line.push(atom(dip.q, F, 'fo-q', o?.key_hue))
            rows.push(line)
        }
        for (const r of vrows) {
            if (r.row === 'vein') {
                const line = [atom(String(r.v ?? ''), F, 'fo-vein', o?.hue)]
                for (const b of r.bits ?? []) line.push(atom((b.k ?? '') + (b.n && b.n > 1 ? '×' + b.n : ''), C, 'fo-chip', o?.key_hue))
                rows.push(line)
            }
        }
        for (const r of vrows) {
            if (r.row === 'fact') {
                const line = [atom(String(r.k ?? ''), F, 'fo-key', o?.key_hue, r.k)]
                if (r.v != null) line.push(atom(String(r.v), F, 'fo-val', o?.hue))
                else if (r.n) line.push(atom('×' + r.n, C, 'fo-chip', o?.hue))
                rows.push(line)
            }
        }
        for (const r of vrows) {
            if (r.row === 'spread') {
                const line = [atom(String(r.k ?? ''), F, 'fo-key', o?.key_hue, r.k)]
                for (const b of r.bits ?? []) {
                    if (b.text) line.push(atom(b.text, C, 'fo-more', o?.key_hue))
                    else line.push(atom(String(b.v ?? '') + (b.n && b.n > 1 ? '×' + b.n : ''), C, 'fo-chip', o?.hue))
                }
                rows.push(line)
            }
        }
    } else {
        const max = o?.max_facts ?? 8
        // FACTS FLOW (2026-09-11, the owner: "a bit more thinking about where the words go, maxing out
        //  left-right top-bottom-ness and available space") — one line per fact wasted a wide cell's width
        //   and a small cell's height (a Player's third line, `of main`, never fit).  All facts are ONE row
        //    of key/value PAIRS: pane_rows wraps when the chord runs out, and a key never strands from its
        //     value (`pair` — the key is placed only where its value fits beside it).
        const line: Atom[] = []
        for (const g of guts.slice(0, max)) { const ka = atom(g.k, F, 'fo-key', o?.key_hue, g.k); ka.pair = true; line.push(ka, atom(g.v, F, 'fo-val', o?.hue, g.k)) }
        if (line.length) rows.push(line)
        if (guts.length > max) rows.push([atom('+' + (guts.length - max), C, 'fo-more', o?.key_hue)])
    }
    return rows
}

// point-in-convex-polygon (either winding) — the test's witness that no seat left its cell
export function inside(poly: Pt[], p: Pt, slack = 0.01): boolean {
    let sign = 0
    for (let i = 0; i < poly.length; i++) {
        const a = poly[i], b = poly[(i + 1) % poly.length]
        const el = Math.hypot(b.x - a.x, b.y - a.y) || 1
        const cr = ((b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x)) / el   // signed distance from the edge line
        if (Math.abs(cr) <= slack) continue
        const s = cr > 0 ? 1 : -1
        if (sign === 0) sign = s
        else if (s !== sign) return false
    }
    return true
}

// the four corners of a seat's glyph box, in the caller's coordinates — what `inside` is asked about
export function seat_box(s: Seat): Pt[] {
    const w = s.text.length * GLY * s.fs, asc = s.fs * 0.8, desc = s.fs * 0.25
    const th = (s.rot ?? 0) * Math.PI / 180, c = Math.cos(th), sn = Math.sin(th)
    const at = (dx: number, dy: number): Pt => ({ x: s.x + dx * c - dy * sn, y: s.y + dx * sn + dy * c })
    return [at(0, -asc), at(w, -asc), at(w, desc), at(0, desc)]
}
