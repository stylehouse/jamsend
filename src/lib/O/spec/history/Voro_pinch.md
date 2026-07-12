> **HISTORICITY (retired 2026-07-13).**  This was the design note for `Voro_todo` task 7 (the
>  gravity-brush pinch|spread).  It LANDED as designed 2026-07-06 — 🌀 on the ◈ bar, stash
>   `Cyto_gravity_brush` (`src/lib/O/Cytui.svelte`).  The living statement is task 7 in
>    `Voro_todo.md` (BUILT); the built code is the implementation.  Kept for the falloff-curve /
>     coexistence-with-fcose reasoning.  (Mobile two-finger pinch, §"The gesture" line 7, is still
>      unbuilt — a loose end, but not enough to keep this as a live todo.)

# Voro_pinch — scroll = pinch|spread the locale (Voro_todo task 7, design note)

A toggleable mode where the wheel does not zoom the camera but sculpts THAT LOCALE:
 wheel-toward pulls the neighbourhood under the cursor together, wheel-away spreads
  it — a gravity brush over the glass.

On mobile devices it might be a two-fingered pinch gesture... Where the two points
are vertically aligned it could mean pinch|spread, horizontally means zoom.

## The gesture

- Falloff: gaussian, `w_i = exp(−d_i² / 2σ²)`, σ ≈ 140px (about one cell), cut off
   below w = 0.05. d measured in RENDERED px from cursor to node.
- The move: MODEL-position writes through cy —
   `node.position(p + (p − cursor_model) · k · w_i)` with k ≈ ±0.06 per wheel notch
    (negative = pinch toward the cursor). Model coords, so the sculpt strength does
     not depend on zoom level.
- Only non-compound, non-nucleus nodes move (compounds follow their children;
   nuclei are scaffold).

## Legality (metaphysics §1)

Position writes here are LAYOUT-SIDE INPUT, exactly like a user drag — allowed.
 Constraints:
- never while a layout is running (`lay` active → the wheel is ignored);
- every burst routes through `pan_zoom_motion()` so the live loop re-tessellates
   per frame and the settle repaints at quiet — the brush is just another motion;
- writes go through cy positions ONLY (no renderedPosition shortcuts), so waves,
   fit and every other consumer see one coherent state.

## Coexistence with fcose — said plainly

The next layout wave UNDOES the sculpting. Yes. That is fine for a play-mode: the
 brush is a hand-gesture on the current rest state, not a persistent constraint —
  like smoothing sand that the next tide re-ripples. If persistence is ever wanted,
   the road is fcose `relativePlacementConstraint`s derived from sculpted deltas —
    NOT frozen positions (freezing kills the sim and with it every future wave).

## Mode + hands

- Stash pref `Cyto_gravity_brush` (metaphysics §4), armed from the ◈ bar (🌀).
- The visor keeps owning the right strip either way — `visor_guard` runs
   capture-phase and steals first; the brush takes what reaches the graph.
- While armed: plain wheel = brush; Ctrl/Cmd+wheel = camera zoom (pass through to
   cy); middle-drag pans as always. Disarmed: everything as today.

## Open before build

1. Should the brush also weight by cell area (big panes resist)? Lean no — mass
    illusion comes free from σ.
2. A soft clamp keeping nodes inside the frame (soften at 40px from the edge) so a
    spread can't fling slivers off-screen.
