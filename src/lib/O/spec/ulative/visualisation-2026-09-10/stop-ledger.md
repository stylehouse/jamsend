# VytoOrchestra render-stop ledger (BigShapeland, /BigShapeland?B=VytoOrchestra)

Baseline = `none_60s.png`: pie/voronoi of overlapping wedge cells on a dark
red-brown mottled-marble ground; teal wedges "Song:5.LowTide" (artist Yara ·
mood, curved along the rim), "Song:6." (artist…), olive wedge "Stray:8.moth",
teal sliver "Pull:9.Drift", and a translucent rose wedge in the centre
("Player:2.keys" mostly hidden under other cells). Top desk: a row of chips
(folio, wave, seal, copperless, nohall, simmer, still, seat, focus, plump,
kindfold, kinweave, saylaw, room, fold) — none lit in the baseline.

| stop | what it looks like | keep? |
|---|---|---|
| none | Baseline voronoi wedge pie described above. | reference |
| wave | Ground texture is a visibly flowing/swirly pattern (vs. none's static mottled marble). Labels render horizontal instead of curved along the wedge rim, so text crowds and overlaps in the centre (Player:3.bass, Player:2.keys, Pull:9.Drift, Song:7.SaltAir, 6.Undertow all stacked on top of each other). New/renamed labels appear — "Song:7.SaltAir" and "6.Undertow" — and a small standalone cell "Lane:wire" shows top-left. | keep |
| seal | No visible difference from none. | drop |
| copperless | No visible difference from none. | drop |
| nohall | Same wedge shapes/positions as none, but the secondary sub-labels are gone — "artist Yara · mood" under Song:5 and the "artist" line under Song:6 are missing; only the main titles remain. | keep |
| simmer | No visible difference from none. | drop |
| still | No visible difference from none. | drop |
| seat | Big layout change: cells become a rectangular tile grid (rounded-rect boxes in rows) instead of voronoi wedges. Same base palette (teal, olive, maroon) but duplicated labels appear ("of main" ×2, "artist Yara / mood brine" ×2, plus "artist Yara" alone, "loose 1", "lane wire", "Stray:8.moth"). | keep |
| focus | At 30s: a completely different zoomed hub-and-spoke/graph view — one huge magenta cell ("Player:2.bass" / "Player:1.") joined by a green line to a chain of small satellite circles labelled Song, Son, Son, Str, Pull. At 60s: blank canvas, 0 paths/texts — the log shows a mid-capture HMR reload ("[vite] hot updated Story.svelte", world destroy + auto_reset) wiped the render, so the blank 60s looks like a capture artifact rather than a real "focus" state. | keep (30s only) |
| plump | Cells render larger/zoomed-in, filling more of the frame; full label text is legible without truncation ("Pull:9.Driftline", "Song:7.Sa…", "Song:6.Under", "Player:3 / of main" in the centre cell). | keep |
| kindfold | No visible difference from none. | drop |
| kinweave | Same wedge shapes/layout as none, but cell borders are noticeably thicker and brighter/whiter rather than none's thin colour-tinted outlines. Status chip reads "sworn 0/0 o5" vs none's "o7" (UI badge, not the glass itself). | keep |
| saylaw | No visible difference from none. | drop |
| room | Cells render larger/zoomed similar to plump, but with flatter, more rectangular/blocky cell-top edges instead of none's smooth rounded wedge tops; full labels legible. | keep |
| folio | Layout changes substantially: labels are horizontal (not curved along the rim), larger/bolder, and broken onto separate stacked lines per field, with "artist"/"mood" field names in a purple accent colour and values in white on the next line. A new label "BAND:1.MAIN" appears that isn't present in none. "Pull:9.Driftline" and "lane / wire" show in full. | keep |
| fold (deck=folio,fold) | Visually near-identical to folio's rendering — same cells, same horizontal stacked-line label style, same "BAND:1.MAIN" label. Header text changes to "budget:3,folio" and both the folio and fold desk chips are lit. No crest/count cells appeared. | keep (same visual family as folio) |

## folio — close look

Text sits stacked vertically inside each cell: a bold title line at the top
(e.g. "Song:5.LowTide", "Pull:9.Driftline"), then smaller field:value pairs
below it ("artist" in purple / "Yara" in white, "mood" in purple / "brine" in
white), all horizontal rather than curved along the cell's rim. Every solid
cell is labelled — BAND:1.MAIN, Song:5.LowTide, Pull:9.Driftline,
Song:6.Undertow — except the translucent rose "Player" cell in the middle,
whose text ("Player:3.ba…", "of main") is cut off/overlapped by the BAND and
Pull cell borders crossing over it; that's the one illegible/clipped label.
No crest cells (no "×N" grouped-row cells) are visible in this pass.
Legibility is otherwise good: large, high-contrast, uncurved text. Top desk:
only the "folio" chip is lit (boxed); all the others are unlit.

## fold — close look

Nearly indistinguishable from folio: same four legible cells in the same
positions with the same stacked title/field/value text style, and the same
obscured "Player" cell hidden under the BAND/Pull borders. Despite requesting
`deck=folio,fold`, no crest cells (e.g. a Song crest collapsing multiple rows
with a "×3" count) appear — this Book's dataset (8 steps, a handful of
particles) is likely too small to trigger a fold/collapse, so fold renders
the same as plain folio here. Top desk: both "folio" and "fold" chips are lit
(boxed), and the header text reads "budget:3,folio" in place of a stop name.
