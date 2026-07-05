# Voro_svg_stuffing — the SVG-native Stuffing rebuild (Voro_todo task 8, design)

## The problem

Today a Stuffing is an HTML box molded into its cell as a WHOLE: `paint_final` sets
 bbox + clipPath on the overlay and one affine (fit·T) on the child. The content
  inside is opaque to the tessellation — rows can't know where the walls are, and two
   neighbouring cells can't coordinate what faces what. The goal: rows the
    tessellation itself places, so shared-wall neighbours EDGE TOGETHER — matched
     rows gravitating to the shared wall and lining up across it, corresponding tuple
      fields aligned. The glass stops being panes-with-labels and becomes a single
       worked window.

## The tuple model

A Stuffing's content becomes structured rows, derived from the SAME live particle
 (nothing new modelled, metaphysics §2):

    Row   = { key, value, kind, weight, rid }
    Group = { head, rows: Row[] }         // the ×N groups the HTML Stuffing shows

- `key`/`value` from the member's mainkey and its scalar (`{Coprosma:'robusta'}` →
   key Coprosma, value robusta); `kind` = the mainkey class for colour (Matstyle
    read-only); `weight` = subtree size (a row with a frond under it is heavier).
- `rid` is the stable identity — `hash(key + ':' + value)` — needed to (1) tween a
   row's position between settles and (2) name it in cross-wall matching. Same-key
    duplicates get an ordinal suffix.
- Text metrics WITHOUT DOM measurement: the font is monospace (Berkeley Mono), so
   width = chars × em × 0.6 from a per-font constant. This is what frees the SVG
    path from the measure→re-tessellate feedback the HTML path must damp (§6).

## The per-shared-wall matching solve

`edge_src` (built 2026-07-06 for the family hulls) already names the neighbour that
 cut each wall — the adjacency structure is free. For each wall shared by cells A|B:

1. Candidate pairs: rows rᴬ, rᴮ with score = 3·(same key) + 2·(same value) +
    1·(same kind); score 0 pairs are non-candidates.
2. Greedy descending-score assignment, each row used once. (Hungarian is overkill at
    ≤ ~20 rows a side; greedy is deterministic and within pennies of optimal here.)
3. A row can match on at most ONE wall (its best-scoring wall wins) — a row torn
    between two neighbours goes to the stronger bond.

## The placement solve

Per cell, deterministic, no convergence loop:

1. Each wall with matches gets a BAND — the inner strip along that wall (inset by
    the gutter + stroke). Matched rows go to their band, ordered along the wall to
     FACE their partners (partner order on the far side fixes the order on this
      side; the lower cell id's ordering wins ties).
2. Unmatched rows fill the CENTRE block, sorted by weight then rid (stable).
3. Bands + centre block stack along the cell's long axis by simple interval
    packing; overflow spills to the centre block; centre overflow ellipsises with a
     `+N` tail row (log the drop — no silent caps).
4. Rows tween translate-only (~200ms) between settles, keyed by rid.

Walls NEVER move for rows: rows adapt to the tessellation, not vice versa
 (metaphysics §1 — pixel geometry does not push back).

## The paint

One `<g clip-path=cellpath>` per cell inside the existing `.cytui-voronoi` SVG;
 rows are `<text>` (crisp at any zoom — retires the HTML overlay's zoom-font
  stepping). A matched pair gets a light dash across the gutter at the two rows'
   midpoint (the braces already mark edge-crossings; row-bonds read one register
    quieter). Colours: kind's Matstyle, read-only, palette fallback.

## Budget story

- Matching + placement run at SETTLE only (the paint_final cadence). Cost per wall
   O(rows²) with rows ≤ ~20 → microseconds; whole-graph rebuild is one SVG subtree
    swap.
- Motion hides the layer with the overlays exactly as today (`motion_hidden`); the
   drag_frame budget never sees row work.
- Zoom: SVG text scales with the viewport transform for free; re-placement only at
   settle.

## Migration

- Tasks 1–2 (wrap-width, angle — BUILT on the HTML path 2026-07-06) survive as the
   fallback renderer and taught the geometry this spec assumes.
- The SVG path arms per-graph behind a stash flag (`Cyto_svgstuff`) so both
   renderers can be compared live on the same Book.
- The HTML path retires only when SVG covers: self-row mode, the ×N groups, the
   imem openness memory, and the microcosm cards (`Voro_microcosm.md` — the
    microcosm should be born SVG-native if this lands first).

## Open questions (decide before build)

1. Value-class near-matching (robusta vs robusta var. montana) — start with exact
    value + same-key-any-value tiers; fuzzier classes only if the glass demands it.
2. Do group HEADS participate in matching, or only leaf rows? (Lean: heads too —
    genus panes edging their shared genus reads right.)
3. RTL/very-long values: middle-ellipsis at the tuple model layer, not the paint.
