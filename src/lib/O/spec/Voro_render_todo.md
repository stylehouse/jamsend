# Voro render — the grasp-fed stained glass (text stretch-ups → I/C/S/O rivers)

## 0. What to get on with next

**Slice A — text stretch-ups, render-only, no grasp needed.** The smallest real visible win and it
 de-risks the fitter every later slice builds on. All in `Cytui.svelte`, touches no crush verdict,
  snaps nothing. Verify with `runner_shot --svg` (text stays greppable — assert the loud statements
   carry `font-size ≥ 14`). Then Slice B feeds it real weights.

Vague-but-fine candidates after that: the grasp learns to speak `the_*`/`the_very_*` (Slice B); cells
 clump into continuous regions (Slice C); the first C-arc river through one region (Slice D).

## The arc (the destination)

The human's north star, verbatim: "big text stretch-ups" (a **14pt hard font floor**, the loud
 properties bigger); "zen-garden trails of lined up tuples … we have to regroup the cells into
  continuous spaces that can have big tidy arcs drawn through them — preferably an I, C, S or O —
   making a river of some type of debris through another. landscapey." (Wes-Wilson poster lettering.)

Instead of each voronoi cell being an isolated polygon of cramped text, the render **regroups cells
 into a few large continuous regions** and draws big clean **letterform arcs (I/C/S/O)** through them,
  the grasp's aligned `the_*` tuples flowing as a **river** of one kind of data threading through
   another. The [[voro-se-as-seem]] grasp is what makes it possible: cross-beat cell identity (so a
    river doesn't reshuffle) + `the_very_*` weights (so text sizes by meaning).

## The data-path crux (how the render reaches the grasp)

The render's ONLY handle to the model is `node_src: Map<cytoid, TheC>` (`Cytui.svelte:795`), the live
 flora particle riding each wave upsert's `.c.source_n` (`Cyto.svelte:1254`/`1266`). From `src` the
  render already reads crush facts c-side (`src.c.fold_kind/fold_n/gang`, e.g. `voronoi_layout`
   `Cytui.svelte:1823`). **`w:Voronoiology` is `dontGraph`** (`Cyto.svelte:658`) — never in `node_src`,
    so "read the grasp" can NOT mean "draw Voronoiology."

The grasp already wires `C.c.D = D` (`_Seem_CDUsive`, `LangHold.svelte:963`). So the render reaches the
 grasp from the SAME `src` handle: `src.c.D` → `D.o({the:1})` / `D.o({the_very:1})`. Add one reader
  `grasp_of(src)` beside `vtuff_rows` (`Cytui.svelte:971`); it returns null pre-boot and `vtuff_rows`
   stays the fallback — the render ENRICHES when the grasp is present, never requires it.

## Slices

**A — Text stretch-ups (render-only, ships first).** Core fitter = `fit_stat` (`Cytui.svelte:1193`,
 band `lo:7,hi:16`) + `fit_ident` grammar-shed (`:1243`).
 - **14pt floor DRIVES shed** (not post-clamp): if the biggest-that-fits < 14pt the statement must
    shed words / defer, never clip. Raise `lo`→14 for load-bearing statements (nucleus, identity),
     keep a low floor only for decoration (`vsub-ringkey`/`vsub-sup`).
 - **Loud → bigger:** thread a weight into the fitter — `the_very_*` → `hi:26+,lo:16`; `the_*` →
    `hi:18,lo:14`; decoration → `[7,16]`. Tie the loudest statement to the biggest CELL too (nucleus
     radius floor already at `R*0.34`, `:1375`). Use **faked weights** first (title/mainkey/dominant
      `spread` chip) until Slice B lands real ones.
 - **Un-compress ×N** when the compressed chip won't sit at 14pt and the region has spare sub-cells:
    split `×4` back into its four value chips (feed N seeds to the phi-spiral tessellation `:1421`);
     keep `+N` fold-mark (`hid_mark`, `:1263`) only when even split won't fit — never a silent drop.
 - Molded-Stuffing face (▦ off): add a min-legible-scale gate in `paint_final` (`:2229`) — shed rows
    rather than shrink below ~14pt (reuse `wrap_applied` hysteresis).

**B — Grasp speaks `the_*`/`the_very_*` (the `.g` half, snap-verifiable).** Extend `Voro_grasp`
 (`Ghost/V/Voro.g`) so each fold D carries `the:<prop>,val,weight`, promotes loud ones to
  `the_very:<prop>`, plus `the_anchor` (durable cross-beat id) and `the_family` (region key —
   `traced_fn` fires after the sibling layer resolves, so it can neighbour-read). Swap Slice A's faked
    weights for `grasp_of(src)`. `.g` → LocalGen/ghost-compile → live-verify; re-record the `%Se:scape`
     fixture (identity-stable → small diff). **Weight formula is undefined** — start heuristic
      (identity=always very; dominant spread chip; large ×N), eye it on a live tab.

**C — Regroup into continuous spaces.** C1: fcose intra-family gravity so a `the_family` seats
 contiguously (render-side nudge; nuclei `install_nuclei:1685` is the precedent). C2: promote the
  family hull from a stroked lasso to a **filled merged region** — reuse the outer-boundary computation
   already in the hull path (`edge_src` outer walls, `:2270`); internal walls become faint sub-divisions.
    Region-count governor above the crush's ~9: aim ~3–5 regions. Grouping key from grasp `the_family`.

**D — The arcs (I/C/S/O rivers).** A letterform is a parametric spine `spine(t)`, not a font glyph.
 Reuse: **C** arc = tunnel `tube_project` SPAN (~250°, `:1577`); **I/O** orientation = molding
  covariance eigenframe (`:1916`); stable per-key lanes = `vein_of(key)` global angle registry (`:1153`).
   Lay a region's folds as beads along the spine in `the_anchor` order; place each fold's `the_*` values
    on FIXED perpendicular lanes (answers "which value is the year"). New `<g>` in the voronoi svg
     (`:3069`), painted in `paint_final` beside `vsubs`; reuses the whole `vstat` snippet (`:3108`) +
      clip + `textLength` stretch; morph-compatible (`resample`/`morph_voronoi` `:2076`/`:2360`), so
       toggling arc mode morphs the glass like the tunnel. Start with ONE C-arc on one region behind a
        bar toggle, then I/O/S.

## The ledger — render-only vs grasp-carrying (metaphysics)

- **Render-only (NOTHING snaps; signals ride `.c`/$state):** all of Slice A, C1, C2, D; the fit-tight
   feedback `src.c.grasp_tight` (render measures fit, grasp reads it NEXT beat to un-compress/defer);
    every bar toggle/pref.
- **Grasp carries more (model-side, MAY snap):** `the_*`/`the_very_*` weights, `the_anchor`,
   `the_family` (Slice B). Model, not render — the grasp is allowed to snap (Voronoiology is its home).

## Risks / prototype-first

1. Grasp emits no `the_*` yet (Slice 0 is counts-only) — build + isolation-prove the emission before any
    render consumes it.
2. Weight = a judgement, no formula in code — three cheap heuristics, eyes-on via `runner_shot --svg`.
3. Region-merge governor (~3–5) may fight the crush governor (~9) — prototype C2 on **VoroScape** (real
    Artist/Track hierarchy) first.
4. Arc legibility: a river reads with ~5 folds/region, smears with 40 — extend the `+N` fold-mark to
    arcs; prototype ONE small C-arc first.
5. Don't rely on fcose to clump families (the standing "hulls aren't touching" complaint) — merge the
    region GEOMETRICALLY (C2) so it's continuous even if fcose scatters the seeds.
6. `grasp_tight` feedback one-beat lag is fine; a flip-flop is the risk — hysteresis (reuse the
    `wrap_applied` 15% damping `:2218`).
7. All render slices are EYES-ON, none Book-gateable (pixels never round-trip a fixture) — verify via
    `runner_shot` (`--svg` greppable text, `--why` telemetry, `shot` raster) on a LIVE runner. The only
     gate-able artifact is the grasp's snapped `%Se:scape` fields (Slice B).
