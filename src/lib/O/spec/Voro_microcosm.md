# Voro_microcosm — layout WITHIN a cell + zoom-recursion (Voro_todo task 6, design note)

The question that prompted this: *"it seems I would need extra w:Cyto+Cytui hanging around
 to be two sets of graphs? surely not. channels of graph in Cyto? just crunching on subsets?"*

**Answer: just crunching on subsets.** No second w:Cyto, no second Cytui, no channels.

## Why no second graph machine

The crushed children never left. The crush only suppressed Cyto's DESCENT
 (`T.sc.no_further = 'stuffed'` in cyto_scan) — every member of a fold is still in C,
  one `fold.o()` walk from the fold particle Cytui already holds live (`node_src` /
   the wave's `c.source_n`). A microcosm is therefore not a graph that needs scanning,
    waving, or a world to live in: it is a RENDER of a subtree we already have a ref to,
     computed in the cell's own pixel frame. Exactly like the cells themselves are an
      interpretation of node positions, a microcosm is an interpretation of a fold's
       members.

What a second w:Cyto per fold would cost, and why it is wrong:
- a `w` is a WORLD — snap-visible, req-pumped, mutex-serialised, scanned per tick.
   Standing one up per cell puts render state in model territory (metaphysics §2:
    a Book underneath must never see the render).
- one scan/wave pipeline per cell multiplies the machinery the anti-energise
   discipline exists to keep singular.
- Cyto's job ENDS at the fold, by design. Everything below the fold is Cytui-local
   pixels. "Channels of graph" would drag the ghost back below the fold line.

## The design

Three carves, built in order; each is useful alone.

### (a) The static grid microcosm

At settle cadence (`paint_final`), a cell whose fold has members lays them out as a
 mini grid IN the cell's eigenframe: columns ≈ `ceil(sqrt(k · λ1/λ2))` aligned to the
  long axis φ, members sorted by their mainkey then value (stable, deterministic — no
   force pass, no iteration). Each member renders as one compact row-card (v1: a small
    HTML div in the overlay, reusing the Stuffing row look; the SVG rebuild —
     `Voro_svg_stuffing.md` — later replaces the material).
- The mini-layout is a pure function of (members, cell polygon, φ, λ) — no DOM
   measurement feedback: card sizes come from a char-count estimate, not offsetWidth
    (metaphysics §6; the cell's seed weight must not see the microcosm).
- Computed ONLY at settle; during motion the layer hides with the overlays
   (`motion_hidden`), so drag_frame's budget never pays for it.

### (b) The zoom-threshold swap

`paint_final` knows `cy.zoom()` and each cell's area. Define
 `depth = zoom · sqrt(cellArea)` — "how many pixels of my cell are on your screen".
- `depth < Z1`: the fold's single molded Stuffing (today's render).
- `depth ≥ Z1`: crossfade (~200ms opacity) Stuffing → microcosm.
- HYSTERESIS: swap up at Z1·1.15, back down at Z1·0.85 — a breathing zoom must not flap.
- The C tree never changes; zooming is pure reinterpretation.

### (c) Recursion

A member that is itself a fold (`c.stuff` rides on it) gets its own INNER cells:
 `voronoi_layout()` is already nearly a pure function of (seeds, frame) — parameterise
  the frame (today it assumes `[0,CW]×[0,HH]`) and run the same power-diagram +
   molding code with the member-cards as seeds inside the parent cell's polygon.
- Depth is capped by PIXELS, not levels: recurse only while the sub-cell's rendered
   area exceeds ~15,000 px². Zooming in buys depth; zooming out folds it back.
- Same swap rule (b) at every level → "effortless zoom-recursion through any".

## Interaction rules

- A microcosm member is NOT a cy node. Clicks hit-test Cytui-side (we placed every
   card, we know where they are). v1: click logs/identifies (the 🔎 idiom).
- Dragging a member is OUT OF SCOPE: fcose doesn't know members exist, so a member
   drag has no layout meaning. The fold's chunk stays the drag handle.
- The budget self-heal ordering: when drag_frame sheds, microcosms hide FIRST
   (deepest luxury goes first), cells next, node overlays last.

## What Cyto contributes

Nothing new. `source_n` already rides every wave upsert (widened 2026-07-06 for
 properCellable); members are `fold.o()`; member colours read Matstyle READ-ONLY
  (the `cell_color` pattern — never autovivify, metaphysics §5).
