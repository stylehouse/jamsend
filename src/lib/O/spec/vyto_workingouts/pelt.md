# The pelt — workingout (Vyto_spec §5)

A workingout, not a spec: the field math under "the tiny hairs are the field".  The sibling
 doc `shapes.md` owns the tessellation — how the seven catalogue shapes get cut and packed;
  this doc owns what happens *inside* a cut shape: the hair-field, its combing, its readers,
   and the projection that lays a scope's solved layout along it.  Everything here is c-side
    view matter on the `%Scope` furniture (`scope.c.pelt`) — typed arrays and plain objects,
     never sc, never snapped; Books stay Voro-blind.

## 1. One hair

A hair is a sample of the field: *at this point, lie in this direction, this strongly*.

> `{ at: {x,y}, dir: unit {x,y}, strength: 0..1 }` — but stored packed (§2): the hair keeps
>  only `v = dir · strength`.  Direction and strength travel as one vector; a hair with no
>   opinion is simply short.

Two rulings up front, because everything downstream leans on them:

**The field is oriented.**  A fur field could be a *line* field (180°-ambiguous — hatching
 doesn't care which way it points).  Ours cannot: choreography arrives *along* field lines
  (an arrival grows from the parent seam — from has a sign), streamlines integrate a signed
   direction, and dock_dir hands an incoming %Flow the tangent it must *land* with.  So every
    comb formula below produces an oriented vector.  Text — the one reader that hates
     orientation (nobody reads downhill) — rectifies at read time (§5, baselines), never in
      the field.

**Strength is the insistence dial, and zero means "lay flat".**  `strength` gates how much
 any reader obeys the comb: at `s = 1` projection rides the field fully; at `s = 0` the
  reader falls back to its rest pose — the plain affine fit (today's molding T is exactly
   that rest pose).  This makes singularities free (§3) and gives every shape a tasteful
    default: a near-square slab combs *weakly*, so its content lays level.

The pelt lives in the **cell frame** — the polygon's own coordinates as the parent solve
 hands them, before the viewport transform.  Pan and zoom never touch a pelt.  Nested
  scopes each comb their own; frames compose only at render, and glyph uprightness is
   judged once, in screen space, at the final stamp (§6).

## 2. Sampling and storage

**Grid, not scatter.**  Reads dominate: projection touches every item anchor, baselines
 touch every glyph, streamlines call `pelt_at` twice a step.  A regular grid gives O(1)
  bilinear reads off cache-warm typed arrays; jittered or boundary-weighted scatter buys
   nothing the eye can see at hair spacing (~a line-height) and puts a nearest-neighbour
    search in the innermost loop.  The fur *look* (the board's **pelt** toggle) gets its
     organic scatter cosmetically: a deterministic hash-jitter applied at draw time only —
      the drawn hair wiggles, the read field never does.

**Plus a boundary ring.**  Docking wants exact hairs *at* the wall, where a bbox grid is at
 its sloppiest.  So each wall also carries a run of ring samples — every `step` of arc
  length along the wall, evaluated half a step inside — indexed by (wall k, arc t).  These
   are extra samples of the same comb, not a different field.

**Density** follows cell size, clamped:

```
step  = clamp(√A / 14, 10, 36)        // px between hairs; A = polygon area
grid  = ceil(bbox.w/step) × ceil(bbox.h/step)   // over the whole bbox — see §3 on outside
ring  = Σ walls ceil(len_k / step)
```

A typical 300×200 cell: step ≈ 17, ~200 interior hairs + ~40 ring hairs.  A thirty-cell
 glass ≈ 7k hairs ≈ 56 KB of Float32 — memory is a non-issue; the clamps exist so a
  monster cell stays ≤ ~2k hairs and a sliver keeps ≥ a 3×3 grid.

**Storage**, on `scope.c.pelt`:

```
pelt = {
  kind: 'grid' | 'const',        // slab and band comb to a constant — no arrays at all
  x0, y0, step, w, h,            // grid frame (cell coords)
  vx, vy: Float32Array(w·h),     // v = dir·strength, row-major; total function over the bbox
  mask:  Uint8Array(w·h),        // 1 = inside the polygon — used ONLY by the fur draw
  ring:  { k, t, vx, vy }[],     // boundary hairs per wall arc position
  spine?: { pts: {x,y}[], len }, // mold|body only — the traced carrier (§4)
  text_lay: 'grain' | 'cross',   // which axis baselines ride (§4 table)
  anchor: {x,y},                 // the chart origin projection walks from (§6)
  gen: number,                   // = the owning solve's generation; readers assert it
}
```

Typed arrays are objects — they would be fatal in sc anyway; on `.c` the encoder never
 sees them.  The whole pelt is rebuilt wholesale at comb time (§7); nothing in it is ever
  patched incrementally.

## 3. Reading between hairs — `pelt_at`

Bilinear on `v`, and the strength falls out of the length:

```
pelt_at(p):
  if kind=='const': return { dir: v̂0, strength: |v0| }
  gx = (p.x−x0)/step; gy = (p.y−y0)/step        // clamp to the grid
  v  = bilinear(vx,vy over the 4 surrounding hairs)
  s  = |v|
  return { dir: s > 1e-4 ? v/s : {0,0}, strength: min(s,1) }
```

Why not IDW or RBF: O(k·n) or a k-NN per read for smoothness below the perceptual floor.
 Why not interpolate angles: angle-wrap.  Interpolating `v` sidesteps both — and it makes
  singularities *honest*: at a radial comb's seed the four surrounding hairs point apart,
   their bilinear blend cancels, and the read comes back **weak**, which is exactly the
    truth — the field has no opinion there, so the reader lays flat (§1).  No special-case
     fallback, no declared singularity list.

The comb formulas are total functions, so the grid is evaluated over the **whole bbox**,
 outside the polygon included — a hair just outside the wall carries the comb's smooth
  continuation.  This keeps bilinear reads near the boundary undiluted (an outside sample
   of `v = 0` would drag boundary strengths down artificially).  `pelt_at` never tests
    containment; callers own that, and `mask` exists only so the fur draw doesn't paint
     the bbox corners.

## 4. Combing the seven shapes

The solver that owns the scope combs at solve time; everything else reads.  Per shape:
 the oriented direction formula, the strength profile, and which axis text rides.

Shared symbols: polygon P (cell frame, screen-handed — y down), seed `q`, area centroid
 `c`, eigenframe `(φ, elong)` from the shoelace second moments (the exact machinery
  `voronoi_layout` computes today — reuse it verbatim), `rot90(v) = (−v.y, v.x)`,
   `A` = area, `r₀ = 0.25·√(A/π)` (the singular-core radius).

| shape | dir(p) | strength | text_lay |
|---|---|---|---|
| **cell** | `normalize(p − q)` — radiate from the seed | `0.6 · min(1, |p−q|/r₀)` | grain |
| **slab** | `â(φ)` constant along the long axis | `0.7 · clamp((elong−1)/0.8, 0, 1)` | grain |
| **band** | `ĝ` the downhill unit — the Slope's meaning axis | `1.0` — the axis IS semantics | **cross** |
| **wedge** | `normalize(p − o)` — o the shared hub | `0.9 · min(1, |p−o|/r₀)` | grain |
| **ring** | `rot90(normalize(p − o))` — clockwise on screen | `0.9` in-lane, easing to 0.3 at lane edges | grain |
| **mold** | spine-tangent · wall blend (below) | `0.85`, tapered over the last 10% of spine at each tip | grain |
| **body** | spine-tangent · wall blend — spine handed by Mesh | `1 − 0.6·clamp(d_cross/halfwidth, 0, 1)` | grain |

Notes per shape:

- **cell**: strength plateaus at a *suggestion* (0.6), never insistence — an irregular
   fold-cell holds arbitrary content and mostly wants the radial grain for choreography
    (arrivals grow from the seam along the grain) rather than for hard warping.
- **slab**: `kind:'const'` — no arrays.  `â(φ)` sign-rectified into the +x half-plane.
   The elongation gate means a square slab combs to near-nothing and its content lays
    level; only a genuinely long slab earns its grain.
- **band**: constant downhill.  Baselines are **cross**-laid — the contour lines across
   the flow, so a queue's rows read level while matter (rank changes, arrivals) slides
    *downhill through* them.  This is the one shape where "baselines ride hairs" means
     the hairs' perpendicular; the pelt's cross-axis is first-class (the body's "ribs
      across" is the same axis), not a hack.
- **wedge / ring**: both comb about a hub `o` the *parent's* disc solve owns —
   shapes.md territory; the pelt just takes `o` as a comb parameter, so all sectors of
    one disc comb coherently.  Ring orbit sense is clockwise in screen coords so the top
     arc's grain points screen-right (reads forward where the eye enters).
- **mold** — the Wes-Wilson field.  The spine is traced, not assumed straight:

  ```
  mold spine:
    rotate P by −φ (the eigenframe long axis)
    sample M = 9..17 stations across the long extent
    at each, midpoint of poly_chord(rotated P, y)      // the widest-chord machinery
    rotate back; 3-tap lowpass → pts[]; arclength-parameterise
  dir(p):
    t̂ = spine tangent at nearest arclength station
    d = distance to nearest wall;  β = 1 − smoothstep(d / m),  m = 0.18·√A
    ŵ = wall tangent sign-aligned with t̂ (dot ≥ 0)
    dir = normalize((1−β)·t̂ + β·ŵ)                     // channel flow: spine mid-stream,
  ```                                                   //  wall-following at the banks

   A bent mold gets a bent grain; a straight one degenerates to the slab case.  The
    chord-midpoint trace assumes one chord interval per station — convex-ish molds only;
     a genuinely nonconvex mold needs a medial-axis trace and that is deferred (v1 molds
      live 1.5× unclipped in their wall band and stay convex-ish).
- **body**: the Mesh solver *already owns* a spine ("writes a dot-body with a spine") —
   the pelt takes it verbatim, applies the same wall blend as the mold, and adds the
    cross-falloff strength so flank dots relax while spine dots march.  The ribs are
     cross streamlines (§5) — the pelt defines them; Mesh reads them back for dot rows.

There is **no universal boundary-tangent pass**: only mold and body (the channel-like
 shapes) blend toward walls.  Radial and orbital combs are *supposed* to meet their walls
  at their own angle — dock_dir hands that angle out and the arriving curve does the
   bending (§5).

## 5. The read APIs

Four readers.  All pure over one pelt; all cell-frame in and cell-frame out.

**`pelt_at(p) → { dir, strength }`** — §3.  O(1); ~tens of ns; branchless inner loop.
 The universal primitive — every other reader is built on it.

**`streamline(from, steps, opts?) → pts[]`** — trace a field line.

```
streamline(from, steps, o = { sign:+1, h: step·0.6, min_s: 0.05, clip: true }):
  p = from
  repeat ≤ steps:
    k1 = pelt_at(p).dir · o.sign
    k2 = pelt_at(p + k1·h/2).dir · o.sign        // RK2 midpoint — Euler visibly
    stop if strength at p < o.min_s              //  polygonalises tight ring arcs
    stop if o.clip and p leaves P
    p += k2·h; emit p
```

 Cost: 2 `pelt_at` per step; a 100-step trace ~1–2 µs.  Used by: spine verification, the
  choreography paths (§4 of the spec — enter and leave along field lines: the path an
   arrival rides IS a streamline traced backward from its landing point), baselines
    (below), and the body's ribs (`sign` on the cross-axis).

**`baselines(box, n, opts?) → Baseline[]`** — n curved baselines for text layout.

```
Baseline = { pts: {x,y}[], tans: {x,y}[], len }      // even arc-length resample

baselines(box, n, o = { lay: pelt.text_lay, lh }):
  axis(p)  = o.lay=='grain' ? pelt_at(p) : rot90'd pelt_at(p)     // strength carried
  seeds    = walk a CROSS-axis streamline from box.anchor,
             dropping a seed every o.lh of arc length (n of them)
  each seed: trace the axis streamline both ways; clip to box ∩ P;
             resample to even arc steps; record tangents
  rectify:  reverse the whole run if mean tangent · x̂(screen) < 0   // per-RUN — a
                                                                    //  word never flips mid-run
  straighten by strength: pts ← lerp(flat chord, pts, s̄)            // s̄ = mean strength
  SNAP:     if total run bend < 8° → dead flat                      // "text tilts; it
  clamp:    per-em tangent delta ≤ 6°                               //  never turns" law,
```                                                                 //   carried from Cytui

 Cost O(n · trace).  The three post-passes are the whole text doctrine in miniature:
  strength interpolates each baseline between its streamline (s = 1) and its flat chord
   (s = 0); the SNAP threshold carries the human's standing ruling that a barely-bent
    line reads worse than a straight one; the per-em clamp keeps glyphs from fanning
     apart or crowding on a tight bend.

**`dock_dir(bp) → { dir, strength }`** — the flow-edge docking read.

```
dock_dir(bp):                       // bp on (or snapped to) the boundary
  wall k = nearest wall; t = arc position along it
  hair   = ring sample at (k, t)    // the ring exists for exactly this read
  flip so dir · n̂_inward ≥ 0
```

 O(walls) to find k, O(1) after.  Semantics: the tangent an incoming %Flow must *arrive
  with* — the slide's endpoint curvature is solved by the edge renderer so its end
   tangent equals `dock_dir`; the curve then continues into the cell's grain and the
    edge meets its cell like a tangent, never a collision.  Departures use the same hair
     with the sign flipped.

## 6. Projection — field-guided lay-down

The scope solved its layout in LOCAL coordinates (§5 of the spec: the parent never
 solves the child's innards).  Projection maps that solved layout into the cell polygon
  along the hairs.  The mechanism is a **chart walk** — flow-aligned coordinates (u along
   the grain, v across it) traced with streamlines rather than computed as a global
    parameterisation:

```
project(scope):                                  // at solve end, once per solve
  a0 = pelt.anchor                               // per shape: seed | hub | spine start |
                                                 //  slab's top-left — shapes.md hands it
  ku, kv = envelope fit                          // local box extents vs chart extents
                                                 //  (chart extents = spine len × mean
                                                 //   cross-chord for mold|body; bbox else)
  per item at local (x, y):
    p  = walk cross-axis from a0 by y·kv         // two short streamline walks
    p  = walk grain from p by x·ku
    θ  = atan2(grain at p)                       // the item's rotation
    land item with (translate p, rotate θ)       // its INNARDS untouched — it is a
                                                 //  scope; its own pelt rules inside
  text rows: baselines(row_block_box, n_rows)    // then glyphs advance along pts
```

Everything above is gated by strength exactly as §1 promised: the landing position is
 `lerp(affine_fit(x,y), chart_walk(x,y), s)` with `s` the strength at the landing — so a
  weak field degenerates to today's molding T (the symmetric eigenframe stretch + capped
   rotation, `mold_max_fit`-bound), which survives as the **rest pose**, and a strong
    field earns the full ride.  "Gentle warp allowed for molds" is therefore not a
     special mode: the mold's 0.85 plateau *is* the gentle warp, and the two hard caps
      below bound it.

**The glyph law, reconciled.**  The spec says both "text baselines ride hairs" and
 "glyphs render upright in screen space — letterforms never shear."  The reconciliation,
  ruled here precisely:

- The transform allowed on a glyph is **translation + rotation (+ one uniform font-size
   per run)**.  A glyph's anchor rides the baseline; the glyph rotates to the local
    baseline tangent; it stands perpendicular on its baseline with its outline rigid.
- **Banned on a glyph**: shear, nonuniform scale, per-glyph scale, and
   `lengthAdjust="spacingAndGlyphs"`.  Stretching a run to fill its chord is a
    *tracking* change — spacing between rigid glyphs (the `textLength` spacing-only
     discipline Cytui's `stretch()` already obeys) — never a glyph deformation.
- "Upright in screen space" therefore means: **never sheared, never inverted** — not
   "always screen-vertical" (which would ban Wes-Wilson outright).  The per-run
    rectification in `baselines` (±90° of screen-right, judged once per run in screen
     space after frame composition) is what makes "upright" true in the reading sense;
      the SNAP-to-flat rule makes it *literally* true wherever the field is weak — so
       ordinary text in ordinary cells sits exactly as it does today.
- Curvature is expressed by **anchor density**, never by deformation: a straight run is
   one anchor + one rotation; a bent run gets per-glyph anchors along the polyline.
    Positions project; glyphs are stamped rigid.

**Caps** (the "gentle" in gentle warp): per-em tangent delta ≤ 6°; and if the grain
 direction drifts more than ~30° across a single projected item's own box, that item
  falls back to its rest-pose affine (an item is a rigid-ish thing; only the *layout
   between* items bends freely).  A ring label may still sweep 180° — the cap is local
    curvature, not total bend.

## 7. Lifecycle and budget

**Combed by the owning solver at solve time** — the last act of a solve, before the
 settle is judged (so a settle always has a fresh pelt and the spool captures against
  it).  Cached on `scope.c.pelt` with `gen` = the solve generation; every reader asserts
   `gen` in dev builds — a stale-pelt read is a bug, not a fallback.

**Invalidates** (→ re-comb wholesale; never patched):
- polygon vertices moved beyond the settle ε
- shape or owning-solver change; seed, hub, or spine change (mold re-traces; body takes
   Mesh's new spine)
- a strength-relevant knob (the §4 constants are knobs and will be tuned by eye)

**Never invalidates**: pan/zoom (cell frame — §1); anything per-frame mid-flight.
 Choreography reads the pelt combed at the shift's start: paths are traced once at
  choreograph time and tweened as targets — no reader runs inside the animation loop.
   A held scope keeps its pelt frozen by construction: no solve → no comb.

**Budget**:

| op | cost | cadence |
|---|---|---|
| comb one cell | ~200 hairs × ~50 flops (+ mold: ~17 chord scans) | per solve |
| comb the glass | < 0.5 ms at 30 cells | per solve burst |
| `pelt_at` | ~30 ns | inner loops |
| `streamline` ×100 steps | ~1–2 µs | choreograph + text lay |
| full text lay, 12-row cell | ~0.2 ms | per solve |
| steady-state frame | **0** | — |

The fur draw (board's **pelt** toggle): decimated hairs (every 2nd) as one `<path>` per
 cell with the cosmetic hash-jitter, rebuilt only at comb — a diagnostic face, never in
  the frame loop.

## 8. What Cytui already knows (seed findings)

- `voronoi_layout`'s shoelace second-moments (centroid, φ, elong) are exactly the
   eigenframe §4 needs — lift verbatim.  `box_support` / `mold_max_fit` define the rest
    pose the strength gate falls back to.
- `tuple_frame` + `pane_rows` already rotate baselines — to the best *wall*, one angle
   per pane.  The pelt generalises wall-rotation to a field; but note `norot` exists
    because rotated identity text read badly ("a name reads level") — expect identity
     rows to want a low-strength or flat lay even inside a strong comb.
- The molding rotation is capped |θ| ≤ 20° and **snapped to 0 below 8°** ("text tilts;
   it never turns") — carried forward as the baseline SNAP rule (§5).
- `stretch()` uses SVG `textLength` spacing-adjust — the tracking-not-glyph-scale
   precedent §6 codifies.
- `poly_chord` / `wide_chord` assume convex polygons; the pelt grid does not care, but
   the mold spine's chord trace inherits the assumption (§4 flag).

## Open questions

1. **Ring bottom arc**: per-run rectification flips text on the lower half of a ring
    (readable but the orbit's visual continuity breaks at the sides) vs continuous flow
     (upside-down at the bottom).  Proposed: flip.  Needs the human's eye.
2. **Band baselines cross-laid** (§4): confirm the per-shape `text_lay` table — band is
    the only cross-laid shape and it bends "baselines ride hairs" to "ride the cross".
3. **The rest pose at s = 0**: flat-screen-horizontal vs the scope's local frame.
    Proposed: the affine molding T (which itself caps at 20°) — so "flat" still tilts a
     little in an elongated cell, exactly as today.
4. **Strength constants** (0.6 cell, 0.85 mold, the elongation gate…): all knobs; tune
    by eye on the first tenant, but is the *shape* of the table right — should any shape
     insist at 1.0 besides band and body-spine?
5. **The hub seam with shapes.md**: wedge and ring comb about a hub the parent disc
    owns — where the hub lives on the furniture (parent scope vs handed per-sector)
     needs the two docs to agree.
6. **Nonconvex molds**: defer medial-axis spine tracing (v1 molds convex-ish) — accepted?
