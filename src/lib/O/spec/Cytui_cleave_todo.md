# Cytui_cleave_todo.md — the migration map for shrinking Cytui.svelte

Plan ONLY — no code moves in this doc. Cytui is ~3925 lines and half of it is one region (the
 voronoi glass). This doc measures the bloat, maps which parts are portable and which are welded to
  Svelte 5's reactivity, and — post the 2026-07-12 three-layer decision — reads as the MIGRATION MAP
   for the coming waves, not a standalone cleave. Cites read live 2026-07-12.

---

## 0. The decision, and what this doc is now for

**DECISION 2026-07-12 (the human, in a hui): NO `VoroGlass.ts`.** This doc used to recommend cutting
 the pure geometry helpers out into a sibling `VoroGlass.svelte.ts` module. That is SUPERSEDED. The
  geometry/formatting maths folds into **`Ghost/V/Voro.g` itself** — the engine's home — not a new .ts
   module beside Cytui. (Known caveat to carry into that wave: LangTiles parse-storms on closure-heavy
    raw JS — `.g-authoring-gotchas` — so the closed-form eigen / clipping / Catmull code will feel that
     out; prefer DSL, drop to raw JS only where the maths demands it.)

**Why the destination moved.** The larger decision is that Voro becomes a three-layer engine (see
 `Voro_render_todo.md §0 "The three-layer engine"`): the grasp/ghost decides WHAT (the Seems — model),
  pure derivations decide WHERE (geometry), and **Cytui shrinks to wiring + paint**. So the goal is no
   longer "carve a tidy geometry library out of the component" — it is "Cytui stops computing the model
    and the geometry at all; it consumes them." A `VoroGlass.ts` would have been geometry-in-a-new-house;
     the real move is geometry-into-Voro.g, driven by the model the grasp now computes.

**What this doc is for now.** The Layer A/B/C anatomy below (§2) is still the load-bearing content — it
 is the MAP of what migrates and what stays:

- **Layer A (pure geometry, ~400 lines)** is what eventually migrates INTO `Voro.g` — the ④ geometry
   wave in `Voro_render_todo.md §0`. Not a Cytui-sibling cut; it moves to the engine.
- **Layer B (stateful render orchestration)** SHRINKS as the grasp's model takes over the diffing and
   census it currently hand-rolls — but the parts that drive cytoscape and write the `{#each}` arrays
    STAY as paint.
- **Layer C (the reactive `$state` surface)** STAYS in Cytui — it is the paint layer by definition;
   `{#each}`-bound arrays live in the component that renders them.

The Svelte 5 reactivity honesty (§4) and the "is it worth it" read (§5) survive the decision unchanged:
 the reactive/DOM-coupled bulk was never a clean cut to a .ts sibling, and that is exactly why the
  geometry goes to the engine (fed by the model) rather than to a module wall beside the component.

---

## 1. The measurement

`Cytui.svelte` = ~3925 lines (was 3684 when this doc was first written; the glass keeps growing).
 Region structure (`//#region` markers, `grep -n "#region"`, read live 2026-07-12):

| Region | Starts | Character |
|---|---|---|
| (top: imports + shared refs + module `$state`) | 1 | `cy`, `container`, `matstyles`, `layout_name`, `status`, `grawave_dur` |
| `animations` | 124 | wave/morph/settle timing |
| `overlays` | 283 | Stuffing overlays, `node_src` map, `paint_overlays_now`, `reposition_overlays` |
| **`voronoi`** | **739** | **the glass — over HALF the file, ~2150 lines to the `apply` marker** |
| `apply` | 2892 | `apply(wave, dur)` — the marker executor (NOT a diff, per Seemables §2) |
| `layout` | 3138 | fcose/cola/dagre layout drivers |
| (template markup) | ~3450 | the `<div class="cytui">` render, `{#each vcells/vtips/vfams/vregions/vsubs}` |

**The voronoi region is the bloat — over half the file.** Everything below is about that region; the
 other regions are reasonably sized and cohesive. (Line numbers inside §2/§3 below are from the
  earlier read and have drifted a few hundred lines as the glass grew — treat them as approximate
   anchors, re-grep the function name before relying on one.)

---

## 2. Anatomy of the voronoi region — three layers

Reading the region's function inventory (`awk` over 739-2694), it stratifies into three layers with
 very different portability:

### Layer A — pure geometry + formatting helpers (~400 lines, ZERO coupling)

Stateless functions: plain args in, plain values out. Verified (grep over each body) to touch NONE
 of `cy`, `container`, `node_src`, or any `$state`/`$derived` var — the `cy` tokens that appear are
  local centroid variables (`const cy = averageY`), not the cytoscape instance:

- `poly_chord` (:1063), `wide_chord` (:1217), `stretch` (:1233) — chord/fit math
- `seg_hit` (:1870), `clip_halfplane` (:1884), `box_support` (:1922) — half-plane clipping
- `convex_hull` (:2258), `resample` (:2279), `align_ring` (:2302) — ring geometry (the `align_ring`
   that Seemables §2 calls a hand-rolled `bD` — pure math here)
- `pca_axis` (:2327), `river_order` (:2354), `letter_of` (:2381), `catmull_d` (:2407) — the "read the
   cell centroids as a written word" river machinery
- `kind_color`/`kind_hue`/`kind_glass`/`kind_tint` (:2171-2213) — kind→colour lookups (constant-driven)

**These are the clean cut.** They are already de-facto a geometry library trapped inside a Svelte
 component. Nothing reactive, nothing DOM, nothing HMR-sensitive.

### Layer B — stateful render orchestration (the bulk, STAYS)

Functions that read `cy`/`container`/`node_src` and WRITE the `$state` arrays that the template
 renders:

- `voronoi_layout` (:1931) — reads `cy`, `container`, `voronoi_on`, `node_src`; computes the cell
   tessellation. Coupled.
- `paint_final` (:2475), `voronoi_paint_now` (:500), `voronoi_soon` (:1790) — write `vcells`,
   `vtips`, `vfams`, `vregions`, `vsubs`.
- `morph_voronoi` (:2581) — the tween; reads `shown_pts`/`shown_color` hand-rolled `bD` (Seemables §2).
- `subgraph_build` (:1409), `nucleus_pane` (:1388), `power_cells` (:1358), `fit_stat`/`fit_ident`
   (:1275/:1325) — build the sub-pane render descriptors into `vsubs`.
- the `toggle_*` handlers (`toggle_voronoi`/`proper`/`families`/`regions`/`brush`/`subgraph`/`radio`/
   `tunnel`) — flip `$state` prefs + persist to `H.stashed`.
- `install_nuclei` (:1809), `radio_tick` (:1645), `tube_project` (:1700), the pointer/wheel handlers
   (`brush_wheel`, `visor_guard`, `middle_pan_down`, `wrap_pointerdown`).

### Layer C — the reactive `$state` surface (STAYS, it is the seam problem)

~16 `$state`/`$derived` declarations in the region back the template's `{#each}` blocks:
 `voronoi_pref`/`saw_stuffy`/`voronoi_on` (:759-775), `proper_pref`/`proper_on` (:790),
  `families_pref`/`vfams` (:827-829), `region_pref`/`vregions` (:847-849), `visor_lit` (:876),
   `brush_pref` (:922), **`vcells`/`vtips`** (:959-960), `vsubs`/`subgraph_on` (:1119-1122),
    `radio_pref`/`radio_on` (:1628), `tunnel_pref`/`tunnel_on` (:1674), `vregion_w` (:1711),
     `wrap_el`/`motion_hidden` (:1752-1764).

The template (3300-3360) renders `{#each vregions}`, `{#each vfams}`, `{#each vcells}`,
 `{#each vtips}`, `{#each vsubs}`, gated by `{#if voronoi_on && vcells.length}`. **This is why the
  big cleave is hard: these arrays are template-bound reactive state.**

---

## 3. What migrates, and what stays behind

### The geometry migrates into `Voro.g` (NOT a `VoroGlass.ts` sibling)

Layer A (the ~400 lines of pure geometry/formatting) is what moves — the ④ geometry wave in
 `Voro_render_todo.md §0`. Per the 2026-07-12 decision it does NOT become a sibling `.svelte.ts`
  module; it folds into `Ghost/V/Voro.g`, the engine's home, so the maths sits WITH the model that
   feeds it and the "where" derivations stop being trapped inside the paint component.

**What travels:** the pure functions listed in Layer A. They import nothing from the component and
 touch no reactivity — that is exactly why they can move. The list, as a portability checklist:

- `convex_hull`, `resample`, `align_ring` — ring geometry
- `clip_halfplane`, `seg_hit`, `box_support` — half-plane clipping
- `poly_chord`, `wide_chord`, `stretch` — chord/fit math
- `pca_axis`, `river_order`, `letter_of`, `catmull_d` — the "read the centroids as a written word" river machinery
- `kind_color`/`kind_hue`/`kind_glass`/`kind_tint` — kind→colour lookups (constant-driven)

**The caveat that shapes HOW it migrates:** LangTiles parse-storms on closure-heavy raw JS
 (`.g-authoring-gotchas`). This code is closed-form eigen, polygon clipping, Catmull-Rom — dense raw
  maths, not the DSL's comfort zone. Prefer the LangTiles DSL where it reaches; drop to raw JS (a
   `RENDER()`/`IMPORT()` tail block, `.g-import-ts-module`) only where the maths genuinely demands it.
    This wave will feel out that boundary; it is not a mechanical copy-paste.

**What stays behind:** everything in Layers B and C — all `$state`, all `cy`/`container` access, all
 `{#each}`-bound arrays, all `toggle_*`, `voronoi_layout`, `paint_final`, `morph_voronoi`, the
  pointer handlers. That is the paint layer, and it stays in `Cytui.svelte`. As the grasp's model takes
   over the diffing/census that Layer B hand-rolls (Seemables §2, and the ③ wave), Layer B SHRINKS —
    but what remains is irreducibly cytoscape-coupled and belongs in the component.

### Why NOT lift the whole voronoi region into a `<VoroGlass />` child component

Tempting (it is half the file), but it is a rewrite, not a move, for three reasons:

1. **`$state` doesn't cross freely.** `vcells`/`vtips`/`vfams`/`vsubs` are written by Layer B and
    read by the template's `{#each}`. A child component would need them as `$props` or `$bindable` —
     but they are DERIVED FROM `cy` geometry recomputed on every wave/morph, so the child would need
      `cy` too, and `cy` is the parent's single cytoscape instance. You'd be threading the live graph
       handle + a dozen reactive arrays across a component boundary that today are all local. Net: more
        surface, not less.
2. **The template is interleaved.** The voronoi `{#each}` blocks (3300-3360) sit INSIDE the same
    `<div class="cytui">` that hosts the cytoscape container and the overlay layer — they share a
     coordinate space and z-stacking. Splitting the SVG glass into a child means passing the pan/zoom
      transform and container rect down, and the overlays (Layer `overlays`, a different region) also
       reposition against that same rect (`reposition_overlays`). The layers are spatially coupled.
3. **It buys little.** The orchestration (Layer B) is where the complexity lives, and it is
    irreducibly coupled to `cy`. Moving it to a child just relocates the coupling behind a prop wall.

So the honest cleave is: extract the STATELESS math (real decoupling), leave the STATEFUL
 orchestration (fake decoupling if moved).

---

## 4. Svelte 5 reactivity + HMR risks (why only the pure math can move)

The repo's own constraints are why the migration boundary is "pure functions only," whether the
 destination is a .ts sibling (rejected) or `Voro.g` (chosen):

- **`$state`/`$derived` semantics don't cross a module boundary freely.** Reactive state works in
   `.svelte.ts`, but `$effect` timing and the reactive graph behave differently outside a component's
    instance scope, and `{#each}`-driving arrays are simplest kept in the component that renders them.
     Layer A has NO runes, so it moves cleanly. The moment a candidate function needs a `$state`, it is
      Layer B, and it stays.
- **`<script module lang="ts">` gotcha** (`module-script-lang-ts` memory): this is one more reason the
   geometry belongs in `Voro.g` rather than a new module script beside Cytui — a `.svelte.ts` carrying
    TS annotations must declare `lang="ts"` or it silently breaks esbuild's `optimizeDeps` scan. Voro.g
     compiles through the ghost pipeline (its own gen `.go`), sidestepping the module-script trap
      entirely. This was the original argument for "plain .ts over .svelte.ts"; the decision took it
       further to "into the engine, not a sibling at all."
- **HMR re-mixes methods, not captured refs** (`hmr-remixes-ghost-methods`): a subtlety the migration
   INTO Voro.g must respect that the old .ts-sibling plan dodged. Voro.g functions ARE ghost methods —
    they re-mix on hot update — so a caller that captured a geometry-fn ref at construction goes stale.
     Cytui calling `H.<geometry_fn>(...)` per beat is fine (re-dispatched through the House); a stashed
      ref is not. Not a blocker, a discipline.
- **No fixture / no snap risk (render side).** Cytui is a VIEW — nothing here is snapped, so no
   `toc.snap` moves from a render change. The blast of a paint-side mistake is VISUAL only, provable
    with `runner_shot.mjs --svg` (the glass as standalone SVG) and `--why` (the telemetry film strip).
     (The GRASP side of the same wave — the model — DOES snap `%Se:*` and is Book-gateable; that is the
      point of doing the model first.)

---

## 5. Is it worth it — the honest paragraph

The file is ~3925 lines and half of that is one region, which is a real "this is a lot" — but it is
 not BROKEN. It compiles, it renders, the voronoi work is recent and actively evolving (the Voro modes
  gallery, the radial hierarchy, the sub-graph slice — see the recent commits and `Voro_todo.md`), so
   churn here is expected. The point of the three-layer decision is that the shrink is NOT a
    cut-for-tidiness — it falls OUT of the model-first arc: once the grasp computes membership / order /
     loudness / drift (`Voro_render_todo.md §0`), Cytui stops hand-rolling the diff and census that bulk
      Layer B, and once the geometry migrates into `Voro.g`, Layer A leaves too. What remains in Cytui is
       the irreducibly cytoscape-coupled paint (Layer B remnant + Layer C reactive surface), which is
        where it belongs. So the honest read is: don't cleave Cytui as a standalone task; let it shrink
         as the model and geometry waves land. The one thing NOT to do is the big-child-component rewrite
          (§3) — it fights Svelte 5 and relocates coupling rather than removing it. And there is no rush:
           the geometry is pure, so it migrates exactly as easily in a month, after the model side and
            VoroTest Book settle.

---

## Cross-references

- **The three-layer decision + the wave order:** `Voro_render_todo.md §0` ("The three-layer engine" +
   the ①–⑤ arc). This doc is the ③/④ migration map for that arc.
- **File:** `src/lib/O/Cytui.svelte` (~3925 lines); region starts 124/283/739/2892/3138; template ~3450+.
- **The stateful voronoi work (why it's churning):** `Voro_todo.md`, `Voro_vtuffing.md`,
   `voro-subgraph-slice`, `voro-imposed-from-above`, `voronoi-cells-render` memories.
- **Seemables overlap:** `Seemables_todo.md` Appendix §2 (Cytui `morph_voronoi`/`apply` as a
   hand-rolled diff) — note its ground-truth correction: `apply` is a marker executor, 6 of 7 maps must
    stay, and `align_ring` is a DIFFERENT axis from a node move. The migration and a Seem-ification are
     orthogonal; the geometry move does not touch `morph_voronoi`'s diff.
- **Constraints:** `.g-authoring-gotchas` (LangTiles parse-storms on closure-heavy raw JS — shapes the
   geometry migration), `hmr-remixes-ghost-methods` (Voro.g fns re-mix; don't stash refs),
    `module-script-lang-ts`, `svelte-comment-tag-gotcha`.
- **Verify visually:** `runner_shot.mjs --svg` / `--why` against a live Voro runner (`?B=VoroMitosis`
   or `VoroScape`); the glass is a view, so pixels are the gate (`runner-shot-pixel-loop`).
