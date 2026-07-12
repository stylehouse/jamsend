# Voro render — the grasp-fed stained glass (text stretch-ups → I/C/S/O rivers)

## 0. What to get on with next

**Every slice is now BUILT (2026-07-12): A + B + B2 (meaning→size), C v1 (▧ washes), C1 (family
 clumping — layout), D v1 (I/C/S/O arc-rivers + debris chips), and the grasp ROLLED OUT to every crush
  user** (it rides `Voro_crush_scan`'s tail now — VoroScape/VoroRadio/VoroRadioPier/VoroClinic all
   grasp, not just VoroMitosis; `Story.svelte:1243` awaits the imposed-from-above crush so `%Se:scape`
    snaps deterministically).

**B2 is SEMANTICALLY VERIFIED on the live SVG (2026-07-12):** species epithets (unique) tower at 26pt,
 `habit: vine` (rare) 22pt vs `habit: shrub` (common) 11pt, `woodystem ×4` (universal) recedes to 8.6pt.
  The engine works. Remaining eyes-on = TASTE tuning (`Voro_grasp_weight` consts 0.85/15, `band_for`
   thresholds 80/45), not correctness.

**NEXT (needs a human at the tab — TWO gotchas):**
 1. **RELOAD the runner tab first** — its Vite HMR socket is dead ([[hmr-socket-dead-tell]] memory):
     relay ops answer but `.svelte` edits (C1 + rivers) never landed in it. Everything render-side built
      today is unexecuted in that tab until a reload.
 2. Then `run VoroMitosis --watch` (RED expected — `%Se:scape` + step-11 `wgt` restamps + now a rebuilt
     `%Se:census` make fixtures stale; the re-record is the human's call) and:
    - `runner_shot --why` — expect a `clump fams:N moved:M` line (C1 alive; `fams:1` = the family
       bucketing collapsed, tune `the:family`); after toggling `▧` expect a `river` line too.
    - Click `▧` on the tab — washes + rivers + chips all live behind it. Tune widths/opacities/spacing
       (knob line-refs in `## Slice D — arc-rivers build notes` at the end of this doc).
    - `runner_shot --svg out.svg` — eyeball rivers: do arcs read as I/C/S/O? Do same-family cells sit
       contiguous (C1's job — `CLUMP=0.30`, `MINSEP=84` in `voronoi_layout`)?

Then: C2 (merge each family's washes into ONE filled region now that C1 makes them contiguous), chip
 thinning on long streaks, and the Wes-Wilson lettering pass (warp the big words along the river
  tangents). Fixture staleness after the rollout: VoroMitosis, VoroScape, VoroRadio, VoroRadioPier,
   VoroClinic (each gains `%Se:scape`; Mitosis' `%Se:census` values change) — all live re-records.

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

**B + B2 — Grasp weighs every claim by neighbourhood salience; the render sizes text by it. BUILT
 2026-07-12 (compile+type-clean; pixel-verify owed).** The path landed CLEANER than the D-sphere
  key-matching this doc first sketched — the grasp weighs the *same Vtuffing tree the render draws*, so
   the two halves align by construction, no cross-beat keying to drift:
 - `.g` (`Voro_grasp`, `Ghost/V/Voro.g`): a NEIGHBOURHOOD CENSUS counts every `(key,val)` claim across
    all cells (`Voro_grasp_tally`), then `Voro_grasp_weight` scores each claim 0..100 — universal (every
     cell shares it) → ~20 (recedes below 14pt), unique → ~95 (towers), a rare *key* nudges up. The
      weight is stamped straight onto each `%Vrow`/`%Vbit`'s `wgt` (off-snap tree → snaps nothing;
       96..100 reserved for identity/title). The `%Se:scape` readout gains `trait` (the loudest cell's
        defining claim). This is the real Se — a cell weighed against its neighbours, which the isolation
         judges (`Voro_crushable`) never could.
 - render (`Cytui.svelte`): `wgt_norm` carries the row `wgt` through `vtuff_rows`; `band_for(wgt, hiCap)`
    maps it to a fit band (≥80 towers lo16, ≥45 the 14pt floor, below recedes lo7). Faked `loud` deleted.
     A grasp-blind pane still renders sane (title 100, else 50 → 14pt floor) — enrich, never require.
 - **The weight formula is the knob to tune live** (`Voro_grasp_weight`, the `0.85`/`15` constants +
    the 80/45 band thresholds). Start heuristic; eye it on a `runner_shot --svg` and adjust.
 - Owed with a runner: emit `the_family` (region key, for Slice C) + `the_anchor` (durable id, for Slice
    D) — held until the bucketing can be eyeballed. Fold `Voro_grasp` into `Voro_crush_scan` so VoroScape
     (imposed-from-above) gets it too.

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

## Slice D — arc-rivers build notes (2026-07-12)

Built in `src/lib/O/Cytui.svelte` only (render-only, nothing snaps). Gated entirely behind the existing
 `▧` toggle (`region_on`) — it is now "the regroup face": washes + rivers together. `region_on` false ⇒
  `vrivers` stays `[]` and the render is byte-identical to before.

**What draws.** For each `region_of`-bucketed family (same bucketing as the Slice C washes) with ≥ 2
 cells: one wide translucent riverbed stroked in the family's `REGION_COLORS` colour, layered in the svg
  BETWEEN the washes and the family hulls / cell strokes (`:3515`–`:3535`), with the family's shared trait
   lined along it as tiny tangent-rotated text chips (the "zen-garden trail of lined up tuples"). Washes
    and rivers now share ONE grouping pass (`:2637` `## ▧ the regroup face`) so a river always wears the
     SAME colour as its wash (same `ri` index). New reactive `vrivers` state at `:858` carries
      `{ id, d, color, shape, chips[] }`; `shape` is the classified letterform, in the data so `op:'why'`
       can read what the scape drew.

**The letterform classifier (`letter_of`, `:2381`).** The choice falls out of the ordered walk's
 geometry, not a flag:
- Order the family's cell centroids first (`river_order`, `:2354`): a family that WRAPS around something
   (round cloud — PCA flatness `l2/l1 > 0.55` AND the largest angular gap `< 0.9π`, ≥4 cells) is walked by
    angle around the family centroid; everything else (a streak) is walked by projection onto the PCA
     main axis (`pca_axis`, `:2327`, closed-form 2×2 eigen).
- A wrap whose last centroid closes back near the first (`span < 0.35 × bbox`, ≥4 cells) ⇒ **O** (the
   Catmull path is drawn closed).
- Otherwise sum the signed per-vertex turn and count sign-flips of that turn (dead-band 0.18 rad so
   sampling jitter can't invent an inflection): tiny total bend (`|Σ| < 0.35`) ⇒ **I**; ≥ 2 flips ⇒ **S**;
    else one steady bend ⇒ **C**.
- Path itself is Catmull-Rom → cubic Béziers (`catmull_d`, `:2407`), self-contained formatter (doesn't
   lean on `paint_final`'s local `P`).

**Recompute cadence + telemetry.** Rivers recompute exactly where the washes do — inside `paint_final`,
 which runs per settle AND per morph frame, so a drag/morph keeps them live. `paint_final` runs per frame,
  so the `vlog('river', { fams, arcs, shapes })` line (`:2706`) is change-gated on `river_sig`
   (`:2465`, `count + shape-string`) exactly like the C1 `clump_sig` pattern — one line only when the
    river census or its shape mix changes, never a per-frame flood.

**Knobs (defaults, line refs):**
- riverbed body stroke: width **22** / opacity **0.14** (`:3523`); bright core: width **6** / opacity
   **0.30** (`:3526`).
- chip spacing `RIVER_CHIP_STEP` = **110px** along the polyline (`:2430`); chips start half a step in.
- chip face `.cytui-river-chip`: font **9px**, weight 600, fill-opacity **0.85** (`:3704`), fill = family
   colour inline; each rotated to the local leg tangent, clamped upright-ish (never upside-down).
- wrap-detection thresholds live in `river_order` (`:2354`): flatness `0.55`, max-gap `0.9π`, min 4 cells;
   O-closure `span < 0.35 × bbox`. `letter_of` (`:2381`): dead-band `0.18` rad, I-threshold `|Σturn| < 0.35`.
- chip text = the grasp's `the:family` value off any member's node_src particle
   (`family_trait`, `:2454`), falling back to the family bucket key.

**Owed (eyes-on tuning, none Book-gateable — pixels don't round-trip a fixture).** Verify on a LIVE
 runner via `runner_shot --svg`/`--why` (the grep-`river` telemetry line + the drawn `d`s). Untuned by
  eye so far — the widths/opacities/spacing above are first-guess; likely tuning: riverbed width vs cell
   size at real fold counts, chip density on a long streak (may need thinning like the `+N` fold-mark idea
    in Risk 4), and confirming the wrap-vs-streak thresholds pick sane orderings on VoroScape's real
     Artist/Track families (Risk 3). Letterform correctness is only readable off `--svg` today — a small
      hand-check of I/C/S/O against eyeballed arcs is owed.
