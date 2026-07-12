# Cytui_cleave_todo.md — a cleave plan for the 3684-line Cytui.svelte

Plan ONLY — no code moves in this doc. The human flagged Cytui's bloat and said "maybe it's fine".
 This doc measures the bloat, proposes the ONE seam worth cutting, weighs the Svelte 5 reactivity
  constraints honestly, and ends with a recommendation + the single gating question. Cites read live
   2026-07-12.

---

## 0. Recommendation + the gating question

**Recommendation: cut ONE narrow seam — the pure geometry/formatting helpers into
 `VoroGlass.svelte.ts` — and leave everything else where it is.** The file is big, but most of the
  bigness is REACTIVE and DOM-coupled (`$state`, `cy`, `container`, `{#each}`-bound arrays) and does
   NOT cross a `.svelte.ts` boundary cleanly in Svelte 5. There is exactly one clean, low-risk win: a
    ~400-line cluster of stateless geometry math (convex hull, polygon clipping, ring resampling,
     Catmull-Rom, PCA, river ordering, colour lookups) that takes plain args and returns plain values.
      Moving THOSE out is pure win — testable in isolation, no reactivity, no HMR hazard — and it
       shrinks the file ~11% while carving the region into "math" vs "orchestration", which is the
        real readability gain.

**The "is it worth it" honest answer is in §5. Short version: the file is not broken, and the big
 stateful cleave (a whole VoroGlass component) is NOT worth it — it fights Svelte 5's reactivity
  model. The geometry-helper cut is worth it as a modest, safe legibility win, not a rescue.**

**The one gating question for the human:** *Do you want the small safe cut (pure geometry helpers →
 `VoroGlass.svelte.ts`, ~400 lines, zero behaviour change), or is "maybe it's fine" a decision to
  leave it entirely?* If the former, this doc is the map. If you were hoping to lift the WHOLE
   voronoi region (~1955 lines) into a sibling — that is the option this doc argues AGAINST (§3/§5):
    the reactive `$state` and `{#each}` bindings make it a rewrite, not a move.

---

## 1. The measurement

`Cytui.svelte` = 3684 lines. Region structure (`//#region` markers, `grep -n "#region"`):

| Region | Lines | Extent | Character |
|---|---|---|---|
| (top: imports + shared refs + module `$state`) | 1-123 | ~123 | `cy`, `container`, `matstyles`, `layout_name`, `status`, `grawave_dur` |
| `animations` | 124-282 | ~158 | wave/morph/settle timing |
| `overlays` | 283-738 | ~455 | Stuffing overlays, `node_src` map, `paint_overlays_now`, `reposition_overlays` |
| **`voronoi`** | **739-2694** | **~1955** | **the glass — over HALF the file** |
| `apply` | 2695-2940 | ~245 | `apply(wave, dur)` — the marker executor (NOT a diff, per Seemables §2) |
| `layout` | 2941-3232 | ~291 | fcose/cola/dagre layout drivers |
| (template markup) | 3235-3684 | ~449 | the `<div class="cytui">` render, `{#each vcells/vtips/vfams/vregions/vsubs}` |

**The voronoi region is the bloat — ~1955 lines, 53% of the file.** Everything below is about that
 region; the other regions are reasonably sized and cohesive.

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

## 3. What to move, and what stays behind

### Proposed cut — `VoroGlass.svelte.ts` (Layer A only)

Move Layer A (the ~400 lines of pure geometry/formatting) into a sibling `src/lib/O/VoroGlass.svelte.ts`.

**What travels:** the pure functions listed in Layer A. They import nothing from the component; they
 are plain TypeScript.

**What stays behind:** everything in Layers B and C — all `$state`, all `cy`/`container` access, all
 `{#each}`-bound arrays, all `toggle_*`, `voronoi_layout`, `paint_final`, `morph_voronoi`, the
  pointer handlers. The orchestration stays in `Cytui.svelte`.

**The seam signature** — the module exports pure functions, the component imports and calls them:

```ts
// VoroGlass.svelte.ts  (no reactivity — a plain .ts would even do; .svelte.ts only if a helper
//  later needs a rune, which none currently do)
export function convexHull(pts: Pt[]): Pt[]
export function clipHalfplane(poly: Pt[], nx: number, ny: number, d: number): Pt[]
export function resample(poly: Pt[], N: number): Pt[]
export function alignRing(pts: Pt[], ref: Pt[]): Pt[]
export function pcaAxis(pts: Pt[]): { ux: number, uy: number, flat: number }
export function riverOrder(cents: Pt[]): { seq: Pt[], wrap: boolean }
export function catmullD(pts: Pt[], closed: boolean): string
export function kindColor(kind: string | undefined): string | null
// … poly_chord, wide_chord, stretch, seg_hit, box_support, letter_of, kind_hue/glass/tint
```

The component keeps its Layer-B functions and calls `VoroGlass.convexHull(pts)` etc. No state
 crosses the boundary — arguments and return values only. That is the entire point: a pure seam,
  which is the only kind that survives Svelte 5 cleanly.

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

## 4. Svelte 5 reactivity + HMR risks (why the seam must be pure)

The repo's own constraints make the "pure functions only" boundary not just cleaner but necessary:

- **`$state`/`$derived` semantics differ across the `.svelte.ts` boundary.** Reactive state DOES
   work in `.svelte.ts` files (runes are allowed there), but `$effect` timing and the reactive graph
    behave differently than inside a component's instance scope, and `{#each}`-driving arrays are
     simplest kept in the component that renders them. Layer A has NO runes, so this risk is zero for
      the proposed cut — and that is exactly why the cut is limited to Layer A. The moment a moved
       function needs a `$state`, the seam stops being free.
- **`<script module lang="ts">` gotcha** (`module-script-lang-ts` memory): a new `.svelte.ts` (or any
   module script) carrying TS annotations MUST declare `lang="ts"` or it silently breaks esbuild's
    `optimizeDeps` scan — a latent parse error that surfaces only when an unrelated import invalidates
     the dep cache. A plain `.ts` file (no Svelte compilation) sidesteps this entirely. **Since Layer
      A needs no runes, prefer a plain `VoroGlass.ts` over `.svelte.ts`** — it dodges the module-script
       trap completely and is trivially unit-testable.
- **HMR re-mixes methods, not captured refs** (`hmr-remixes-ghost-methods`): this bites GHOST methods
   dispatched through the House. The Layer A helpers are NOT ghost methods — they are local component
    functions / module exports called directly, so HMR re-imports them normally on hot update. No
     stale-ref hazard for the pure cut. (The hazard WOULD appear if you moved stateful orchestration
      that stashed a function ref on a particle's `.c` — another reason to keep Layer B in place.)
- **No fixture / no snap risk.** Cytui is a VIEW — nothing here is snapped, so no `toc.snap` moves,
   no re-record. The blast of a mistake is VISUAL only, provable with `runner_shot.mjs --svg` (the
    voronoi glass as standalone SVG) and `--why` (the render telemetry film strip). That makes even a
     careless cut recoverable, but it also means the ONLY payoff is human legibility, not correctness.

---

## 5. Is it worth it — the honest paragraph

The file is 3684 lines and half of that is one region, which is a real "this is a lot" — but it is
 not BROKEN. It compiles, it renders, the voronoi work is recent and actively evolving (the Voro
  modes gallery, the radial hierarchy, the §6 sub-graph slice — see the recent commits and
   `Voro_todo.md`), so churn here is expected and the human is still shaping it. Splitting a file
    that is mid-evolution can hurt: it scatters the thing you are actively editing across two files
     and adds import friction to every change. The BIG cleave (a VoroGlass child component) is not
      worth it — it is a rewrite that fights Svelte 5's reactivity model (§3) and relocates coupling
       rather than removing it. The SMALL cleave (Layer A geometry → a plain `VoroGlass.ts`) is worth
        it as a modest legibility win: it is ~400 lines of stateless math that is conceptually a
         separate library, it decouples cleanly (verified zero coupling), it becomes unit-testable in
          isolation, and it carves the region's mental model into "math the glass uses" vs
           "orchestration that drives the glass" — which is the actual readability payoff. But it is a
            tidy, not a rescue. If the human's "maybe it's fine" means "I'm still cooking the voronoi
             and don't want to trip over a split mid-flight", then the right answer is: do nothing now,
              and take the Layer-A cut later once the glass design settles. The cut is safe to defer
               precisely because it is pure — it will be exactly as easy in a month.

---

## Cross-references

- **File:** `src/lib/O/Cytui.svelte` (3684 lines); regions at 124/283/739/2695/2941; template 3235+.
- **The stateful voronoi work (why it's churning):** `Voro_todo.md`, `Voro_vtuffing.md`,
   `voro-subgraph-slice`, `voro-imposed-from-above`, `voronoi-cells-render` memories.
- **Seemables overlap:** `Seemables_todo.md §2` (Cytui `morph_voronoi`/`apply` as a hand-rolled diff)
   — note its ground-truth correction: `apply` is a marker executor, 6 of 7 maps must stay, and
    `align_ring` is a DIFFERENT axis from a node move. A cleave and a Seem-ification are orthogonal;
     the Layer-A cut does not touch `morph_voronoi`'s diff.
- **Constraints:** `module-script-lang-ts` (prefer plain `.ts`), `hmr-remixes-ghost-methods` (pure
   functions re-import fine), `svelte-comment-tag-gotcha` (if any moved comment holds a literal tag).
- **Verify visually:** `runner_shot.mjs --svg` / `--why` against a live Voro runner (`?B=VoroMitosis`
   or `VoroScape`); the glass is a view, so pixels are the gate (`runner-shot-pixel-loop`).
