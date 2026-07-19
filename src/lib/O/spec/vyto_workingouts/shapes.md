# shapes — the catalogue worked out (Vyto §5)

A workingout of the spec's §5: the seven catalogue shapes and the solver interface that
 makes them pluggable.  A sibling workingout (pelt.md, written in parallel) owns the
  hair-field machinery itself; this doc says how each shape *combs* it — formula-level —
   and everything about how each shape cuts, negotiates, degenerates and re-solves.
    Working matter, unpreened.  Evidence throughout is the living code: `Cytui.svelte`'s
     power cut, molding affine and fit bind, and `Ghost/V/Voro.g`'s crush governor and
      gang election.  Where this doc goes past what exists it says so.

## 0. Shared ground

### Local frames

Every scope solves in its own coordinates.  The parent hands the scope a **frame** — a
 convex polygon in the parent's local space (the scope's granted cell) — and the scope
  treats it as its entire universe.  Nothing inside a scope ever reads a screen
   coordinate; projection (the pelt workingout's job) carries local space to the screen.
    A solver may normalise its frame however it likes internally — the interface speaks
     frame coordinates at the boundary.

### The envelope

The envelope is the one thing a parent sees of a member — whether that member is a leaf
 cell or a whole nested scope.  Worked out from the spec's "area demand + shape
  preference + min text size" plus the weight the interface needs:

> ```
> Envelope
>   area      px²  — demand at scale 1: the content box (or the child scope's own
>                    stated envelope) times a breathing factor
>   aspect    { pref, lo, hi } — preferred w/h and the tolerated range; a shape that
>                    truly doesn't care states { 1, 0.25, 4 }
>   min_text  px   — the smallest chord that must hold the member's identity line at
>                    the 14px legibility floor (band_for's law: load-bearing text
>                    never renders under 14 — only true decoration may go to 7)
>   weight    the solve weight; defaults to sqrt(area); Express may drive it
>                    (dose-drives-area generalised — the binding lands here)
> ```

The floors and caps the current glass proved carry over as envelope discipline rather
 than measured-DOM hacks: a member's stated area never falls below a floor box (today
  40×30 half-extents) — a fold's floor is lifted by its hidden population on a log
   scale (`log2(1 + fold_n) · 9`) — and gather-time content claims are capped (today
    260×200 half-extents) so one fat member cannot starve the cut before the true fit
     re-binds it.  The **growth spell** survives too: a member whose granted polygon
      cannot hold its min-text chord gets its weight swollen next solve — and the
       swell releases only at *abundance* — never at bare sufficiency — so walls don't
        flutter at the boundary (the hysteresis ruling in the code).

### The geometry toolbox (inherited — these are not proposals)

All seven solvers stand on primitives the current glass already proved.  They move into
 Vyto verbatim in behaviour even where the code is rewritten:

> | primitive | what it does | source |
> |---|---|---|
> | `clip_halfplane(poly, m, dir)` | Sutherland–Hodgman against one wall | Cytui |
> | `power_cells(poly, pts, radii, gap)` | weighted half-plane cut: wall at `t = (d² + r_i² − r_j²)/(2d)` along the seed-to-seed line; null for crowded-out seeds; gap-inset toward the vertex mean | Cytui |
> | polygon moments | shoelace-extended area, centroid, covariance → eigenframe (long axis φ — elongation √(λ1/λ2)) | Cytui |
> | `mold_max_fit(...)` | the true bind: largest scale whose transformed content box clears every wall — per-wall `room / support(n̂)` with `support = |n̂·T·(w/2,0)| + |n̂·T·(0,h/2)|` | Cytui |
> | `chaikin(poly, 2)` | corner-cutting at 0.72/0.28 — two passes read as smooth | Cytui |
> | `poly_grow(poly, d)` | grow/shrink along centroid rays | Cytui |

> | inherited constant | value | meaning |
> |---|---|---|
> | `stuff.scale` | 1.5 | content deliberately noses past its bind — the split-the-difference ruling |
> | `stuff.clip` | 0 | unclipped by default — molds overflow free |
> | `stuff.top` / `stuff.bottom` | 2 / 0.5 | the absolute band on any final fit scale |
> | `stuff.damp` | 0.5 | overflow past the true bind grows like `(want/bound)^damp` |
> | wall gap | 2.2 (1.8 in sub-cuts) | the breath between cells |
> | mold rotation caps | ≤ 20° — snapped to 0 under 8° — gated on elongation > 1.18 | text tilts — it never turns |
> | mold stretch blend | `ρ = 1 + (min(ρ, 1.8) − 1) · 0.55` | "a little" — the eigen stretch is blended and capped |
> | fit floor / safety | 0.18 / ×0.92 | the dust guard and the wall clearance factor |
> | governor window | 6..15 visible | the crush level escalates above 15 — relaxes below 6 |

One honest note on the catalogue's own words: the spec's table calls `cell`
 "seed-and-relax (Fold's own)" — but today no relax loop exists anywhere.  fcose owned
  the positions and `power_cells` only reinterpreted them.  The relax below is new
   matter standing on the proven cut.

## 1. The solver interface

Every shape implements the same contract so the seven are pluggable behind
 `%Scope.layout`:

> ```
> solve(scope, prior) → SolveResult
>
> scope:
>   members   Member[]        — id, envelope, order_key?, value?, pinned?
>   frame     Poly            — the granted polygon, scope-local
>   holds     (id, channel) → held?   — Calm's view; a held position is a constraint
>   params    the shape's parameter table (each shape's own section below)
>
> prior: SolverState | null   — null ONLY at scope birth; a re-solve with null prior
>                                on a living scope is a contract violation (the
>                                relayout-from-nothing ban — made structural)
>
> SolveResult:
>   placements  Map<id, { seed: Pt, poly: Poly }>   — a polygon and a seed per member
>   pelt        Hair[]        — { at: Pt, dir: UnitVec, strength: 0..1 } — combed
>                               at solve time by THIS solver; read by projection,
>                               text, mesh grain, choreography, flow-docking
>   envelope    Envelope      — the scope's own demand restated upward (see §2)
>   settle      SettleReport
>   state       SolverState   — becomes the next call's prior
>
> SettleReport:
>   displacement      px — max seed move + max boundary vertex drift this solve
>                          (Calm judges settled: < ε sustained SETTLE_FRAMES)
>   over_budget?      1  — too many members for this shape's legible range; a hint
>                          to Fold/Gang to fold — the solver itself never refuses
>   worst_aspect?     number — slab/band degradation telemetry
>   floor_violations? id[]   — members whose min-text chord did not fit even after
>                          grammar-shedding; feeds the growth spell
> ```

**Solver laws** — the doctrines every implementation carries:

1. **Targets — not frames.**  A solver emits target geometry.  The renderer tweens
    critically damped from current to target — one target per cell — superseded targets
     dropped — never a queue.  A solver whose output for a member equals its prior
      output grants that member no motion at all.
2. **Prior is the seed.**  Positions come from `prior`; only a genuinely new member
    gets a synthesised entry position (each shape's rule below).  Everything retargets
     from where it is.
3. **Holds are constraints.**  A position-held member's seed is pinned; the cut solves
    around it (the pointer-hold: the world rearranges *around* the moused-over cell).
     A membership-held member may not enter or leave placements this solve.
4. **Deterministic.**  Same members — same prior — same params — same result.  The
    spool replays choreography from moment diffs; a stochastic solver would break that.
5. **Local on delta.**  A membership change perturbs only a neighbourhood (each
    shape's own locality rule below).  Members outside it keep byte-identical targets.
6. **The comb is the solver's.**  Nothing else writes hairs inside this scope.  The
    pelt is emitted with the solve — stale pelts die with superseded targets.
7. **Text floors are hard.**  A solver may shed grammar (the fit_ident ladder: full
    head → tag-only → bare value) but never sizes an identity under its min_text.
     What still doesn't fit is reported — not shrunk into a lie.

## 2. Envelope negotiation — the two-pass rhythm

Negotiation is a demand pass up and a grant pass down:

1. **Demand.**  Each child scope states its Envelope — computed by *its own* solver
    from its members' envelopes (each shape's formula below).  A leaf member's envelope
     is its content box plus breath.
2. **Grant.**  The parent solves with the demands as weights and hands each child its
    polygon.  The child then solves inside — in its own coordinates.
3. **Renegotiation is damped.**  A child may restate a bigger demand only at settle or
    on its own membership change — and the restatement rides the growth-spell
     hysteresis: swell on a floor violation — release only at abundance.  This is what
      keeps parent walls from fluttering while a child breathes.

A shape's demand formula always has the same skeleton — sum of member areas over a
 packing efficiency — plus its own aspect character:

> | shape | area up | aspect pref | notes |
> |---|---|---|---|
> | cell | `Σaᵢ / 0.72` | { 1, 0.4, 2.5 } tolerant | gap + irregularity overhead |
> | slab | `Σaᵢ / 0.90` | { 1, 0.25, 4 } near-free | rectangles pack tight |
> | band | `Σaᵢ / 0.85` | tall — `h ≥ n·h_min` binds `pref = W_nat/(n·h_min)` | order needs the stack axis |
> | wedge | `π·(r1² − r0²)` with `r1` from `Σaᵢ` | { 1, 0.8, 1.25 } strict | a disc wants a squarish cell |
> | ring | as wedge with lane overhead `/0.65` | { 1, 0.8, 1.25 } strict | lanes waste angular slack |
> | mold | `Σaᵢ / 0.60` | { 1, 0.4, 2.5 } tolerant | blobs breathe — inset + rounding |
> | body | `L·2R̄ / 0.8` | elongated — { 3, 1.8, 8 } | states its spine length as the long side |
> | min_text (all) | `max over members of min_textᵢ` | | the loudest floor rises |

## 3. cell — irregular polygons by seed-and-relax

The Fold's own shape and the default.  The proven power cut plus the relax the old
 glass never had.

**The cut.**

> ```
> params: gap 2.2 · relax.pull η = 0.25 · relax.iters K = 2 · spell as §0
>
> 1. seeds ← prior.seeds; a newcomer gets its entry seed (below); holds pin
> 2. rᵢ ← sqrt(envᵢ.area / π) · spellᵢ            — the power radius from demand
> 3. K times:
>      polys ← power_cells(frame, seeds, r, gap)
>      for each unpinned seed:
>        seedᵢ += η · (area_centroid(polyᵢ) − seedᵢ)
> 4. final cut + gap inset; anchorᵢ ← area centroid (shoelace moments)
> 5. placements: { seed: anchorᵢ, poly: insetᵢ }
> ```

K is small on purpose: convergence rides successive solve ticks — not an inner loop —
 so the relax is interruptible by construction (truth arrives mid-flight and step 1 of
  the next solve starts from wherever the seeds got to).  The relax converges toward a
   centroidal power diagram — cells whose seeds sit at their own centroids — which is
    what makes the tessellation look *settled* rather than sliced.

**Envelope up.**  `Σaᵢ / 0.72` — aspect tolerant — the 0.72 covers gap loss and the
 irregularity of power cells against demanded boxes.

**Combing — radiates from the seed.**  For a point `p` in the cell of anchor `a`:

> ```
> u = p − a;  d = |u|;  R = distance a → wall along u (one ray-cast)
> t = clamp(d / R, 0, 1)
> dir(p)      = u / d                    (undefined at the anchor — null hair there)
> strength(p) = t · (1 − 0.4·t)          (0 at the seed — peaks toward the wall —
>                                         eases slightly at the wall itself so
>                                         flow-docking meets a tangent not a spike)
> ```

Purely radial — no tangential component.  Content laid along this field grows outward
 from the identity at the anchor — an arrival choreographed along it *grows from* the
  seed with the grain.

**Degenerates.**  0 members: no placements — an empty pelt — demand states the floor
 box only.  1 member: its polygon is the whole frame (proven behaviour: a lone seed
  meets no cutters — "cells from the very first beat").  2 members: one power wall —
   the weighted bisector — the simplest honest statement of relative demand.  Very
    many: the cut stays exact O(n²) and instant to a few dozen; past the governor's
     taste (the 6..15 window per view — per scope it is a param) the solver keeps
      cutting but reports `over_budget` so Fold/Gang folds — the solver never refuses.

**Between solves.**  State kept: seeds — radii — last polygons — wall provenance
 (`edge_src` per wall: which neighbour cut it — the family-hull trick generalised) —
  spell multipliers.  **Arrival:** the newcomer's seed is synthesised at the frame
   boundary point nearest its affinity (its Relate neighbours' centroid if any — else
    the parent seam it choreographically enters through) with radius ramped 0 → full
     across the entry tween; only cells whose polygons intersect the newcomer's
      weighted disc (distance < rᵢ + r_new + gap margin) are recut — everyone else
       keeps byte-identical targets.  **Departure:** radius ramps to 0 — its area is
        absorbed by exactly the wall-sharing neighbours (`edge_src` names them) —
         matter visibly goes somewhere.

## 4. slab — rectangles by slice-and-dice

The rectangular workhorse for content that is honestly boxy — panels, docks, the
 board's own panel rows.

**The cut.**

> ```
> params: gap 2 · axis.first = long side of frame · order = the model's stable key
>
> 1. order members by order_key (NEVER by area — an area sort is churn: two members
>    trading sizes would swap places forever)
> 2. slice the frame along axis.first into runs proportional to Σweight per run;
>    alternate axis per recursion depth (slice-and-dice, the spec's own words)
> 3. split tree kept in state: each node = { axis, fractions[] }
> 4. rect per member — gap inset — seed at rect centre
> ```

**Envelope up.**  `Σaᵢ / 0.90` — aspect near-free (rectangles tile anything).

**Combing — parallel to the long axis.**  Per member rect — not per scope:

> ```
> dir(p)      = (1,0) if rect.w ≥ rect.h else (0,1)   (in the rect's own frame)
> strength(p) = 1 − 0.5 · edge01(p)     (edge01 = nearness to the rect border 0..1)
> ```

Piecewise-constant — the field jumps at rect boundaries and that is correct: slabs are
 the shape whose members do not flow into each other.

**Degenerates.**  0: nothing.  1: the whole frame.  2: one split along the frame's
 longer side at `a₁/(a₁+a₂)`.  Very many: slice-and-dice's known vice is aspect
  degradation — slivers.  The solver reports `worst_aspect`; when it passes the
   tolerance the answer is folding (Gang) — not a smarter treemap — because member
    ORDER is the shape's promise and squarified treemaps break order.

**Between solves.**  State kept: the ordered member list and the split tree with its
 fractions.  A weight change retargets fractions in place — every rect on the affected
  run shifts by a shared delta — the orthogonal splits stand untouched.  **Arrival:**
   a slot is inserted at the newcomer's ordered place; only its run re-proportions.
    **Departure:** its fraction is redistributed across its run pro-rata.  Perturbation
     never crosses a split-tree level.

## 5. band — stacked strips whose order means something

Slope's home — the shape where geometry is (or borders on) the value.  Full-width
 strips stacked along one axis; the stack order is a model fact.

**The cut.**

> ```
> params: axis = the stack direction (default vertical — "down" = increasing rank)
>         h_min = max(min_textᵢ) + padding · mode = rank | value
>
> rank mode (layout-owned):
>   1. order by order_key; strip heights hᵢ ∝ weightᵢ with hᵢ ≥ h_min
>   2. strip edges = cumulative fractions of frame height; gap inset
> value mode (meaning-owned — the %Slope contract):
>   1. yᵢ = value_to_pos(valueᵢ)  — the model's own mapping; the strip CENTRES there
>   2. overlap resolve: one-dimensional order-preserving relaxation — overlapping
>      strips push apart along the axis by the minimum total displacement that
>      restores h_min separations; order NEVER flips in the resolve
>   3. dragging a strip writes value_to_pos⁻¹(y) back to the model — the instrument
> ```

**Envelope up.**  `Σaᵢ / 0.85` — and the binding constraint is the stack axis:
 `h ≥ n · h_min` — the band *demands* its height and prefers tall.

**Combing — combed downhill.**  The simplest field in the catalogue:

> ```
> dir(p)      = ĝ         (the unit vector of increasing rank — constant everywhere)
> strength(p) = 1
> ```

Zero curl — zero divergence — one direction for the whole scope.  The pelt workingout
 can special-case it as the constant field; text baselines ride perpendicular to ĝ so
  rows read across the flow.

**Degenerates.**  0: nothing.  1: one full strip — in value mode still centred at its
 value (a lone slope member's height on the slope IS its statement).  2: two strips —
  the wall between them is the order statement.  Very many: when `n · h_min` exceeds
   the granted height the band reports `over_budget` — folding or paging is the
    parent's decision; the band never shrinks text under floor.

**Between solves.**  State kept: order — strip edges — mode — and in value mode the
 last resolved offsets (so the relaxation retargets rather than re-runs cold).
  **Arrival:** rank mode — strips after the insertion index share one shift; value
   mode — the relaxation touches only the overlap window around the entry value.
    **Departure:** the freed height is reabsorbed by the strips adjacent to the gap
     (rank) or the relaxation window (value).  An order flip demanded by the model is
      a *membership-class* decision — it latches under the flight-latch and may only
       land after a settle since the last flip.

## 6. wedge — radial sectors of a disc

Hierarchy has a middle: the holder's identity sits at the centre and the members fan
 around it — the ▦ star face's nucleus/belt/rim made a first-class shape.

**The cut.**

> ```
> params: r0 = nucleus radius (the middle is the SCOPE's own identity — not a member)
>         θ_anchor kept in state · arc_res = polyline segments per radian
>
> 1. θᵢ = 2π · weightᵢ / Σweight  — sector angles from demand
> 2. bearings cumulate from prior.θ_anchor in stable member order — the disc NEVER
>    re-zeroes (an anchor re-zero would spin every sector — the diagonal-and-spring
>    of discs)
> 3. sector polygon = annular sector [r0, r1] polylined at arc_res; gap inset along
>    both radii and both arcs
> 4. seed at the sector's area centroid — on the bisector at
>    r_c = (2/3)·(r1³ − r0³)/(r1² − r0²)
> ```

**Envelope up.**  `π(r1² − r0²)` with r1 solved from Σ demand — aspect strict near 1
 (a disc granted a sliver is a broken statement — better the parent knows).

**Combing — along the radius.**  Like cell but from one *shared* middle O:

> ```
> dir(p)      = (p − O) / |p − O|
> strength(p) = clamp((|p − O| − r0) / (0.35·(r1 − r0)), 0, 1)
> ```

Zero inside the nucleus (the identity's ground is still) — full strength through the
 belt and rim.  Text in a sector rides hairs rotated 90° from dir so labels stay
  readable — glyphs upright per the projection law.

**Degenerates.**  0: the bare nucleus.  1: the full annulus — one member owning the
 whole belt.  2: two half-annuli — the two walls form one diameter through O.  Very
  many: a sector whose arc chord at r_c falls under its min_text cannot say its name —
   the solver sheds grammar first — then reports `over_budget` + `floor_violations`.

**Between solves.**  State kept: θ_anchor — per-member bearings and angles — r0/r1.
 **Arrival:** a gap opens at the newcomer's ordered bearing — the two adjacent sectors
  donate angle first and the remainder re-proportions around the circle with a
   geometric falloff (γ = 0.5 per neighbour step) so antipodal sectors barely move.
    **Departure:** its angle flows to its two neighbours in weight proportion.  The
     anchor bearing drifts only by the mean of granted perturbations — so the disc as
      a whole holds its orientation.

## 7. ring — orbital lanes around a middle

Wedge's sibling for populations rather than parts: members are beads on concentric
 lanes — the lane a member rides is itself a statement (a rank quantity binds to lane
  index via Express).

**The cut.**

> ```
> params: r0 · lane_h = lane height (≥ max member min_text + padding)
>         pack_max = 0.8 (angular fill ceiling per lane) · lane_of = the binding
>                    (Express-driven rank → lane index; default: fill inward-out)
>
> 1. lane radii: r_k = r0 + k · lane_h
> 2. assign members to lanes: by lane_of when bound — else keep prior lane; a lane
>    over pack_max spills its LAST-ARRIVED member outward (one member per solve —
>    spills are visible choreography, not shuffles)
> 3. per lane: members hold angles from prior; arc widths wᵢ = envᵢ chord / r_k;
>    one-dimensional angular relaxation (order-preserving — as band's value mode
>    but periodic) restores gaps
> 4. member polygon = annular arc segment [r_k, r_k + lane_h] × [αᵢ − wᵢ/2, αᵢ + wᵢ/2]
>    — gap inset; seed at its area centroid
> ```

**Envelope up.**  As wedge with a lane overhead (`/0.65` — angular slack is the price
 of legible lanes) — aspect strict near 1.

**Combing — tangential, orbiting.**  The only shape whose field circulates:

> ```
> r̂(p) = (p − O)/|p − O|
> dir(p)      = w · rot90(r̂(p))     (w ∈ {+1, −1} — the winding — kept in state and
>                                     NEVER flipped while any member is in flight)
> strength(p) = 1 inside a lane — 0.3 in the gaps between lanes
> ```

The comb *orbits* — the motion does not.  Motion is granted — not ambient (§3): a ring
 at rest is perfectly still and the tangential field only shapes how content lies and
  how arrivals flow in along their lane.

**Degenerates.**  0: the bare middle.  1: one bead whose arc is its whole lane.  2:
 same lane — pushed to antipodal rest positions by the relaxation.  Very many: lanes
  spill outward until r_max hits the frame — then `over_budget`; the outermost lane is
   the natural gang candidate (far from the middle = least central = first to fold).

**Between solves.**  State kept: winding — lane radii — per-member (lane, angle).
 **Arrival:** joins its bound lane (or the outermost with room) at the angle nearest
  its entry seam; only that lane's relaxation window moves.  **Departure:** its
   lane-mates relax into the gap — other lanes byte-identical.  A lane *change* is
    membership-class: flight-latched — one lane per settle.

## 8. mold — the rounded organic fit

The catalogue's inheritor of everything the current glass learned about fitting
 content: cell's cut — rounded and breathed — with the full molding affine and the
  1.5×-unclipped doctrine carried over intact (the §3 blockquote's inherited
   constants).

**The cut.**

> ```
> params: cell's params + breath = 3 px (poly_grow inset) + chaikin.iters = 2
>         + the inherited knob table of §0 (stuff.scale/clip/top/bottom/damp)
>
> 1-4. exactly cell's steps 1-4 (seed-and-relax power cut)
> 5. blob = chaikin(poly_grow(insetᵢ, −breath), 2)      — the coagulate rounding
> 6. moments of blob → eigenframe molding affine T:
>      stretch ρ = 1 + (min(√(√(λ1/λ2)), 1.8) − 1) · 0.55  along φ — unit-area
>      rotation θ = clamp(φ, ±20°) if elongation > 1.18 — snapped to 0 under 8°
>      (text tilts — it never turns)
> 7. bind: bound = 0.92 · mold_max_fit(blob, anchor, hw, hh, T)
>    want  = clamp(min(fit_gather, bound) · stuff.scale, stuff.bottom, stuff.top)
>    fit   = want > bound ? bound · (want/bound)^stuff.damp : want
>    — content noses past its wall unclipped and sqrt-damped; the hover z-lift digs
>      what still piles up (a render fact — noted here because the solver's report
>      counts overshoot so the board can show it)
> 8. placements: { seed: anchor, poly: blob } — T and fit ride SolverState for
>    projection to read
> ```

**Envelope up.**  `Σaᵢ / 0.60` — the most generous overhead in the catalogue (blobs
 breathe: inset + rounding + the deliberate overflow all eat area) — aspect tolerant.

**Combing — along the mold's spine.**  The spine is the blob's long eigenaxis ê₁
 through its area centroid — and the hairs swing to follow the rounded wall near it:

> ```
> ê₁* = ê₁ sign-aligned with the prior solve's spine (orientation continuity —
>       an eigenvector's sign is arbitrary; the pelt must not flip end-for-end)
> n̂(p) = the nearest-wall outward normal;  t̂(p) = rot90(n̂) sign-aligned with ê₁*
> β(p) = smoothstep(0.6, 0.95, wallness(p))    (wallness = 1 − d_wall/d_wall_max)
> dir(p)      = normalize((1 − β)·ê₁* + β·t̂(p))
> strength(p) = fit_share · (0.5 + 0.5·(1 − β))   (fit_share = fit / stuff.top —
>               a cramped mold combs weakly; a roomy one combs hard)
> ```

Mid-blob the hairs run the spine; near the wall they bend tangent — so text laid along
 them fills the mold the Wes-Wilson way — flowing with the shape and never colliding
  with the boundary.

**Degenerates.**  0: nothing.  1: the whole frame rounded — the mold degenerates to
 exactly today's paint_final fit (one Stuffing molded into one cell) — the proof the
  shape is the right generalisation.  2: two blobs with one rounded shared wall — the
   gap breathes between them.  Very many: as cell — plus the rounding cost is linear
    so the same `over_budget` taste applies.

**Between solves.**  Everything cell keeps — plus per-member T (with φ unwrapped
 mod π so a slowly-turning cell never snaps its tilt) — the fitted scale — and the
  applied wrap width (the inherited damping: re-quantise at 24px steps and re-apply
   only on a >15% move — at settle cadence — never mid-flight).  Arrival and departure
    as cell; the rounding never changes locality since chaikin is per-polygon.

## 9. body — the elongated dot-mesh organ

Mesh's shape: an organ drawn as a dotted body with a spine — packed against sibling
 bodies by the parent.  Members are the dots; the body presents ONE elongated envelope
  upward.

**The cut.**

> ```
> params: R = rib half-width profile (from local dot density) · s_gap = min spine
>         spacing · rib_max = dots per rib
>
> 1. spine ← prior.spine (a polyline; at birth: the parent pelt's strongest
>    streamline through the granted polygon — THE handshake with the pelt doc —
>    else the frame's long eigenaxis)
> 2. arc-length parameterise; each member holds its s from prior; newcomers splice
>    at the s of their nearest affinity (order_key when the family is ordered)
> 3. rib layout: members at the same s-window stack across the spine —
>    dotᵢ = spine(sᵢ) + N̂(sᵢ)·offsetᵢ — alternating sides — |offset| ≤ R(sᵢ)
> 4. outline = the tube: offset hull of the spine at radius R(s) — chaikin-rounded
> 5. member polygons = power cut of the dots CLIPPED to the tube (uniform radii —
>    dots are peers); seed = the dot
> 6. spine retarget: endpoints tug toward the granted polygon's long-axis ends;
>    interior control points relax toward local dot centroids — damped — never
>    re-fit from scratch
> ```

**Envelope up.**  `L · 2R̄ / 0.8` with L the spine length — aspect *elongated*
 ({ 3, 1.8, 8 }): the body is the one shape that asks its parent for length — and the
  parent packs bodies against each other by honouring those long envelopes side by
   side.

**Combing — along the spine — ribs across.**  The two-current field the spec names
 (the spine is the pelt's strongest streamline — the ribs its cross-currents):

> ```
> s* = argmin over s of |p − spine(s)|;  d = |p − spine(s*)|
> T̂ = spine tangent at s*;  N̂ = its normal — sign toward p
> dir(p)      = normalize((1 − (d/R)²) · T̂ + κ·(d/R) · N̂)      κ = 0.35
> strength(p) = 1 − 0.6·(d/R)²
> ```

On the axis the hairs run pure tangent at full strength; toward the flanks they weaken
 and lean outward along the ribs — so mesh dots grain along the body and cross-detail
  ribs off it.

**Degenerates.**  0: no body.  1: a dot with a round bodylet (spine of length 0 —
 the tube degenerates to a disc).  2: a dumbbell — the spine is the segment between
  the two dots.  Very many: the spine lengthens and curls within its granted polygon;
   when R·rib_max is exhausted the body reports `over_budget` — a too-populous organ
    is Gang's business like anyone else.

**Between solves.**  State kept: the spine polyline — per-member (s, side, offset) —
 the radius profile.  **Arrival:** splices at its s — only members within one
  s_gap window shift along the spine (one-dimensional diffusion — band's rule bent
   along a curve).  **Departure:** its window closes the same way.  The spine moves
    only by the damped endpoint/centroid tug — its identity as a curve persists across
     every solve — which is what keeps an organ recognisable while it works.

## 10. The combing table — the pelt workingout's contract

One line per shape — the field the sibling doc must be able to sample and blend:

> | shape | field character | formula home |
> |---|---|---|
> | cell | radial from own anchor — null at seed | §3 |
> | slab | per-rect constant along the rect's long axis | §4 |
> | band | globally constant ĝ — downhill | §5 |
> | wedge | radial from the shared middle — still inside r0 | §6 |
> | ring | tangential with kept winding — circulates but never animates | §7 |
> | mold | spine-following with wall-tangent bend (β blend) | §8 |
> | body | two-current: spine tangent + rib normal | §9 |

Shared hair laws: unit `dir` — `strength` in 0..1 — orientation continuity across
 solves (sign-align with the prior field before emitting — the mold and body rules
  generalise) — a hair field is dropped with its superseded target and never blended
   across two targets by a reader.

## Open questions

- **cell/mold relax taste** — η = 0.25 and K = 2 are invented numbers standing on no
   eyes-on run.  The human tunes these live (knob idiom: `relax.pull`, `relax.iters`).
- **slab under aspect degradation** — is fold-on-`worst_aspect` the whole answer or
   may slab locally squarify a run when the members in it carry no order_key at all?
    Squarify breaks order — but an orderless run has no order to break.
- **band value mode overlap** — the order-preserving relaxation hides true value
   collisions (two members at one value get pushed apart and the geometry then lies
    slightly about the value).  Alternative: allow overlap and resolve by z.  Which
     lie is smaller is a ruling — geometry-fidelity versus separability.
- **the middle of wedge and ring** — worked out here as the scope holder's own
   identity face (never a member).  Confirm — or rule that a designated member may
    take the middle (a rep in the middle of its gang reads naturally too).
- **ring orbit drive** — this doc holds the line at "the comb orbits — the motion does
   not."  If any scope ever earns ambient rotation it needs a doctrine (a Hold class
    that grants perpetual motion) — that is a spec event.
- **packing efficiencies** — the η column in §2 (0.72/0.90/0.85/0.65/0.60/0.8) is
   taste awaiting measurement; the settle report could learn real per-scope η over
    time (granted area vs used area) and restate demand from evidence.  Adopt?
- **body member polygons** — worked out as real clipped polygons for interface
   uniformity even though dots mostly render as dots.  The cheap alternative is
    dot + radius with a synthesised disc polygon on demand.  Uniformity versus cost.
- **per-scope governor window** — the 6..15 visible taste is a view-level constant
   today.  Inside a nested scope the right window is probably smaller and
    depth-dependent.  Who owns it — the scope param or Fold globally?
