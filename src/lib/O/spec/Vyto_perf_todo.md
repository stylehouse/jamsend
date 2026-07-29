# Vyto_perf_todo — the renderer fixes that make nested/branchy Vyto safe

Written 2026-07-29 by the wire-side worker (Claude), from a focused diagnosis, FOR the Vyto owner.
I do not edit `Vyto.g` / `Vytui.svelte` (the renderer core is yours); this is a precise handoff.

## 0. What's on fire and why you're reading this

The human wants **branchy (nested) Vyto** — e.g. a music "keep" cell tessellating into its track chips, or a
 friend's live download shown as a nested tree. Turning it on today **burns CPU then crashes the tab**, and even
  flat the glass "totally sucks at laying things out nice and big / not over the top of each other / not
   continuously adjusting every few seconds." I traced all three. I have GATED nested OFF on the wire side
    (`Sounditron` sets `commission.sc.nested` only when `M.c.heist_nested` — default unset) so nothing crashes
     today; flipping that flag back on is safe to TEST only once the four fixes below land.

The line refs are to the GENERATED files (`src/lib/gen/V/Vyto.go`, `src/lib/O/Vytui.svelte`,
 `src/lib/O/vyto_geometry.ts`); map them back to `Ghost/V/Vyto.g` as you work.

## 1. `power_cells` is O(M²) per scope, recomputed EVERY rAF frame, no memo — the crash

`power_cells` (`vyto_geometry.ts:39`) is `pts.map` × inner `for j<pts.length` = O(M²) half-plane clips per
 call. `Vytui.svelte build_cells`/`layout` calls it **once per scope, recursively, every animation frame**
  (`:243` top cut, `:274` per nested scope, driven from `integrate_world` `:324`) with **zero caching** — the
   walls are re-derived from scratch 60×/s. For a keep scope of 15 children on a 6-organ top cut that's ~2
    power_cells/frame (~261 clips) + **two full `tree_nodes` walks/frame** (`:226`, `:310`) + a real-DOM face
     re-diff on `paint_tick++` (`:365`), and it never stops (§3). Each extra scope adds another per-frame O(M²).

**Fix:** memoize each scope's polys keyed by (seeds, radii) and SKIP the re-cut when unchanged; when the world
 is settled, stop re-deriving walls at all. This is the single biggest CPU win and the direct crash fix.

## 2. Child radii are absolute + depth-blind — the overlap / too-small

`Vyto_express_rows` sizes every row `env_area = 2400*(1+dose)` regardless of depth (`Vyto.go:800`), and
 `Vyto_solve_scope` reads that same absolute area for a CHILD's radius with no parent normalization
  (`Vyto.go:970-971`, default √(2400/π)≈27.6px — sized for the whole 800×450 frame) then drops it into a parent
   cell maybe ~100px across. So a gentle dose difference across 800px becomes violent inside a small parent:
    the big sibling claims the cell, small siblings crowd out to `null`→the 6px disc fallback, or overlap.
     `budget_for(800,450)`=12 legible cells (`vyto_foam.ts:88`), so a 15-child scope is over budget even at the
      top, far over inside a sub-cell.

**Fix:** scale child radii by √(parentCellArea / frameArea) (or normalise Σ child area ≤ parent area) in
 `Vyto_solve_scope` so sub-cells fit their container. This also kills most of the crowd-out flicker in §3.

## 3. The settle-drift guard hard-fails on vertex-count change — the never-settle at 60fps

`Vytui.svelte:337` sets `drift = 1e9` on ANY wall vertex-count change (`prev.length !== poly.length`). A nested
 child crowded out returns `null` (`vyto_geometry.ts:49/51`) and drops from `curWalls` (`:247` only sets on a
  truthy poly), then re-appears next frame — so any cell flickering null↔poly, or whose vertex count changes as
   an oversized seed crosses a degeneracy (§2), pins `drift`→`1e9`→`calm_frame` false (`:344`)→`settleCount`
    never reaches `SETTLE_FRAMES`→**the rAF loop never returns false→runs at 60fps forever.** Self-sustaining,
     independent of external bumps.

**Fix:** a tolerance that doesn't hard-fail on poly↔null / vertex-count transitions (e.g. treat a
 disappearing/appearing cell as settled if its seed is stable, or cap the drift contribution).

## 4. No per-scope cell ceiling; fold only crushes the top

`Vyto_fold_scope` operates on `w.c.mirror` only (`Vyto.go:344`) — it can't cap a keep's children — and neither
 `Vyto_solve_scope` (`:960`) nor the renderer `layout` (`Vytui.svelte:234`) has a per-scope ceiling. So a
  whole-album keep (12-20 picks) always overflows.

**Fix:** a per-scope cell ceiling (e.g. `budget_for` on the cell's own bbox; overflow → a "+N more" chip), and/or
 make `Vyto_fold_scope` recurse per-scope instead of top-only.

## 5. What I already did on my side (so you don't chase ghosts)

- **Gated nested OFF** — `Sounditron_commission`: `if (anyKeep && M.c.heist_nested) commission.sc.nested = 1`
   (default unset ⇒ flat). Flip `M.c.heist_nested` to test nested once §1-§4 land.
- **Cut the per-beat re-stir churn** — `Heist_keep_step` bumped the grappled `%Keep` ROOT every ~600ms with
   progress-only writes (`landed_n`/`total_n`), re-stirring the whole glass ("adjusts every few seconds"). Now
    it bumps only when `landed` actually advances. (Layout bumps — dose/state/fold — still fire.) This helps the
     FLAT case too; the nested amplifier in §3 is separate and yours.
- The `KeepBar` / `Pick` faces are registered (`glass_kinds.ts`/`glass_faces.ts`) and DORMANT — they only draw
   under nested, so they cost nothing today and are ready when you re-enable it.

## 6. Suggested order

§1 (memoize/settled-skip) kills the crash and most of the burn. §3 (drift guard) stops the 60fps spin. §2
 (relative sizing) fixes overlap/too-small AND removes the flicker that feeds §3. §4 (ceiling) makes a big
  album legible. Then flip `M.c.heist_nested` on and watch a keep with a full album tessellate cleanly.
