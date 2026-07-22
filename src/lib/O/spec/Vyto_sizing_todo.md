# Vyto sizing algebra — the global relative type-scale

The one law of the glass that was never written down.  Recovered from a design
 conversation 2026-07-21; grounded against `Voro_vtuffing.md` (the render system doc),
  `vyto_workingouts/commission.md §3` (Sunpit/IOexpr), and the retired landscape
   north-star in `spec/history/Voro_todo_parts_2026-07.md`.  A working `_todo`, not a
    blessed spec — the human preens before it earns `_spec`.

## 0. What to get on with next

The gap this fills: `Voro_vtuffing.md` has the **gem** (nucleus · belt · rim), the
 **growth spell** (`Cytui.svelte:3810`, the 60%/42% roomy thresholds), and `fill_fs`
  ("crowding IS the size signal") — but every one of those sizes text **per cell,
   independently**.  The missing law is that text size is **relative to every other text
    in the whole graph**, not just within its own pane.  That is what makes size a
     *legible* signal instead of "whatever fit locally".

Candidate next moves (vague on purpose):
- **read §9 first** — the ordered top-down pipeline is now drafted (2026-07-21, grounded against
   live code); it's the spine the moves below hang on, and it names WHICH stub each installs in;
- **then `vyto_workingouts/processes.md`** (2026-07-21) — the whole arc broken into C→C engines:
   the joints (local geometry × global S · the floor law · the crush's voice · nest-solve ·
    reframe), the risk register, and the five-Book build order.  The re-entry doc for this arc;
- **the floor law is Book-proven** (`Floorlaw`, Voronation.g, 2026-07-21 — green ×3 + red-gated):
   a family below the floor is superseded by its `Stuff_distil` crest; one-directional per pass at
    the exact re-admission point (the flutter defused); un-crush across passes by frame (the surf
     kernel) and by importance.  Owed: the tenancy into the stir order (processes.md §6 step 2);
- **②/③ Stuffing landed** — the distiller + a new cross-key `vein` leg are re-said in stho and
   Book-proven (`Stuff_todo.md`); the re-home into `Vyto_fold` (`Vyto.g:294`) is owed;
- **④ Typescale landed** — the global scale `S` is Book-proven in isolation (`Voronation.g`
   `//#region Typescale`; green + adversarially gated on the live runner): global ratio · order ·
    frame-spent · floor-fold · re-breathe, `φ=√` as a first cut. OWED: the wire into `Vyto_express`
     (⑤, replacing dose) + the taper (⑥), and your preen of the `φ`|area|floor model;
- pin `φ` (the importance→size compression) and prove the fixed point converges without
   wall-flutter (§4) — Typescale's `φ=√` is the first pin; the `φ`-vs-golden-ratio symbol clash is
    still owed a rename;
- prototype the **attention taper** (§5) in the flat glass first — cheapest, and it's most
   of the "recede into murk" feel without 3D;
- decide the 2D-aerial vs full-landscape fork (§6) — the landscape wants a tenant demanding
   it, same bar Sunpit is held to;
- wire the algebra as **Sunpit IOings** (§7) — the concrete tenant that un-parks IOexpr.

## 1. The core law — size is a graph-global sentence

Today the causality runs **cell → text**: a pane gets an area from the cut, then its text
 is fitted into whatever it got (`fill_fs`, chord÷length, per polygon).  So "big text" only
  ever means "filled its own cell" — it says **nothing across the graph**.  A big word here
   and a big word there are not comparable; each merely maxed out locally.

The law inverts it — **importance → text size → cell size** — and sets the size **globally**:

>   `size(t) = S · φ( importance(t) )`

one scale `S` for the entire scape, so for any two texts anywhere
 `size(a)/size(b) = φ(w_a)/φ(w_b)`.  **"As big as possible"** = push `S` up until the frame
  is spent: because important text now *demands* room, cells grow to hold their text at its
   rightful size (the growth spell, run **backwards** — from the text's target size, not from
    the cell's area).  The payoff is the clarify we kept losing: **the biggest words anywhere
     are the most important things in the whole graph, directly comparable** — not an accident
      of local fit.  ("A key is a global vein" already rhymes with this: a key's importance is
       graph-global, so its size must be too — `Voro_vtuffing.md:911`.)

## 2. The algebra — relations solved together

- **global ratio** — `size ∝ φ(importance)`, one `S` across all texts.  *(the "wider than the
   cell" part — the whole point.)*
- **intra-cell rank** — nucleus ≥ facts ≥ members; the source's own statement floors at
   `0.34·R` so "meaning hierarchy = visual hierarchy" (`Voro_vtuffing.md:975`).
- **legibility floor** — ≥14pt for load-bearing text; below it you **split** at the tag|name
   seam (`Cytui.svelte:1867`) or **fold** to a `+N` door — never shrink past legible, never
    silently drop.
- **conservation** — Σ demanded area ≤ frame; overflow becomes annotated `+N`, expandable,
   never a silent cull (`Voro_vtuffing.md:965`).
- **objective** — maximise `S`.  The growth spell is the solver: grow starved, shrink roomy,
   **release only at abundance, never bare sufficiency** (the anti-flutter damping).

## 3. Importance — what feeds `w(t)`

Composable, not one binding.  Sources: a particle's `dose`/weight (`Vyto.g:437`); a value's
 **shared-ness** (a value carried by many rows is a global vein → big everywhere); **rank**
  within its cell; and **attention** (§5).  `dose drives area` is the one binding we have
   today (`client.md:53`); the algebra is the composable version so the glass "looks amazing
    on purpose rather than by hand-tuned accident" (`Vyto_spec.md:51`).

## 4. The hard parts (why this is "complicated thinking")

1. **Dynamic range.**  Importance can span 100×; a linear `φ` sends the least thing sub-pixel
    while the top eats the frame.  `φ` must compress (√ or log); that exponent is a real design
     knob, traded against the 14pt floor and the fold.
2. **Stability.**  Global coupling wants to oscillate (the "walls flutter").  The spell's
    asymmetric release is the damping; `S` itself moves with **hysteresis**.
3. **The whole field re-breathes.**  Add one important thing and *everything* rescales, because
    `S` is global.  That is the cost **and** the point — a living, comparable field — but `S`
     must glide, not jitter.

## 5. The attention taper — aerial perspective

`one S for all texts` holds **at the first layer of C\*\*** — the surface we're pronouncing.
 Deeper matter **tapers into murk**: smaller *and* bluer, the painter's far-hills trick
  (aerial perspective — distant hills go blue-grey, low-contrast, hazy).  Formally, `S` is
   anchored at the **focus** (the branch attention is fixing — a *pronunciation of C\*\**) and
    falls off with distance-from-focus in the tree:

>   `size(t) = S · φ(importance(t)) · ψ( dist_from_focus(t) )`

and a matched **haze channel** rides the same `ψ`: as a cell recedes it desaturates, shifts
 toward blue-grey, drops contrast, and softens.  Near/attended = **big · warm · sharp**;
  far/unattended = **small · blue-grey · soft**.  A branch we *pronounce* props itself up —
   it does **not** taper — so attention carves a sharp valley of focus out of an otherwise
    receding landscape.  This is semantic level-of-detail + depth-of-field, driven by the
     **radio's** attention field (`Voro_vtuffing.md:3` — "the radio drives your attention
      around all of it").  It is also most of the landscape feeling (§6) with **zero 3D**.

## 6. The landscape endpoint — a sculpture for the animal soul

The taper's natural endpoint: project the scape as a **3D landscape onto a surface**.
 Importance × attention becomes a **heightfield** — salient/attended things are **mountains**
  (tall, near), the rest recede low into blue haze.  A near mountain **view-favours** what it
   stands in front of (occlusion = "this, atop what's behind it"), and you navigate by
    **moving through terrain** — which the **animal soul** reads pre-cognitively: we are built
     to judge near/far, high/low, occlusion and haze without thinking.  Tap that and "moving
      around" needs no manual.  (Prior seed, never built: *"SHADOWS revealing the hierarchical
       landscape + TUNNELS between cells"* — `history/Voro_todo_parts_2026-07.md:392`.)

**Two regimes, reconciled.**  The packed-flat **gem** wants to fill the frame (≥60–72%, the
 growth spell).  The **landscape sculpture** may *waste screen real estate* — empty sky is
  fine — when the terrain describes the structure more clearly than a tight pack would.  So
   these are different **faces**: fill-everything for reading a pane's contents, breathe-and-
    sculpt for reading the whole hierarchy's shape.  The algebra (§1–§5) is the same law under
     both; only the projection differs.

## 7. Wiring — the Sunpit tenant that un-parks IOexpr

IOexpr/Sunpit is flagged "wild speculation until a tenant proves it… webbing for something
 bigger" (`Vyto_todo.md:164`, `commission.md §3`).  **This algebra is that tenant.**  Its
  importance inputs (dose, shared-ness, attention) are exactly IO **sources**, and the sizing
   is the **shaping** — an IOexpr names a source and a shaping, lands in the Sunpit, assembles
    the Scannable (`Vyto_spec.md:360`).  So the relative type-scale is coded as **Sunpit
     IOings**: the sources pour in, `Sion` plans the flock, and the size field is the assembled
      result the glass reads.  Proving the algebra proves the Sunpit — the two un-park together.

## 8. The nucleus — the one fixed landmark, the free guts

A cell's guts are **deliberately arbitrary** — how facts, values and members lay out inside is
 open design space, a *face* to be chosen (the gem is one; others are fair game).  The **only**
  invariant is the **nucleus**: the anchor that IS the particle's graph node, sitting at the
   pane's heart.  Freedom everywhere else; the nucleus is the single landmark every face must
    honour.

**The nucleus is the glass↔graph join.**  The crush folds graph→glass; the **surf** pops
 glass→graph (`Voro_vtuffing.md:3`).  The nucleus is where that pivot lives — the node the pane
  was folded *from*, still present.  Two consequences:
- **Edges land on nuclei, not centroids.**  A reference (`of:`/`id:`) or a containment link
   between cells is really a link between their **nodes** — so a thread attaches nucleus-to-
    nucleus.  (Earlier sketches wrongly hung links off cell centroids; the join is the nucleus.)
- **Surf is per-nucleus.**  Act on a nucleus and the pane collapses back to a bare node in a
   node-link reading; the nucleus is the identity that survives both views — whichever renderer
    draws them (Vytui draws its own cells, no Cytoscape lib, but the node it stands for is the
     same particle).

**Multiple nuclei — yes; it's the general case.**  A cell folds a **region** of the graph, and
 every node in that region that keeps its identity is a nucleus.  The gem already shows the
  shape: the **source** is the central nucleus (the pane's subject), the **members ring the rim**
   as rim-nuclei — each its own surf-point and edge-landing.  A join-cell (a `Card,id:X` beside
    its `Record,id:X`, sharing the id) could carry two **peer** nuclei.  A lone leaf is the
     degenerate single-nucleus case.  So, usually: one subject-nucleus at the core, plus a
      nucleus per folded member.

**Where it meets the rest.**  Each nucleus carries identity-weight — the biggest text, floored
 at `0.34·R` (§2) — and the free guts fill the remainder under the same global `S` (§1); several
  nuclei in one pane compete for its area by the same algebra.  In the landscape (§6) the nuclei
   are the **peaks** the terrain rises to.

**Open (the human, 2026-07-21):** if the guts are arbitrary but for the nucleus, the live
 question is *what discipline the guts still owe* — probably only "stay legible under §1–§5 and
  keep every nucleus a findable graph-anchor", the rest left to expressive faces.  And: are
   rim-members **full** nuclei (surfable, edge-landing) from the start, or a lighter *membership
    mark* that only promotes to a nucleus once surfed?

## 9. The top-down algorithm — the one ordered pipeline

*(Draft law, 2026-07-21, grounded against the LIVE code by a pipeline read. §1–§8 are the pieces;
 this is the sequence that carries them. Not a spec — preen it.)*

**The truth the read surfaced: there are TWO stacks, and neither has this law.**
- **Live (Voro→Cytui):** `Voro_crush_scan` → grasp/model → `Vtuff_build` → Cytui `voronoi_layout`/
   `fit_stat`/`spell_update`. Mature, shipping. `dose` appears NOWHERE in it.
- **New (Vyto→Vytui):** `Vyto_stir` = Scan → Fold → Gang → Relate → Express → Solve (`Vyto.g:158`).
   Fold/Gang/Relate/Focus are `return` **stubs**; only Scan/Express/Solve are live. `dose→env_area→r`
    lives here.

The read confirmed §1 against code and sharpened it into **three structural facts the law must fix:**

1. **Sizing is LOCAL per-cell — there is NO graph-global scale `S` anywhere.** Live: cell size = own
    content box + own `log2(1+fold_n)·9` floor-lift (`Cytui:3256`) + own growth-spell multiplier
     (`spell_update`, `Cytui:3825` — STARVED ×1.18 / ROOMY ×0.93 at the live 42% threshold, not the
      stale 60%). Vyto: `r = √(own env_area/π)` from own `dose` (`Vyto.g:496,437`). The only inter-cell
       coupling is the power-diagram wall competition and positional clumping — never a shared scale.
2. **Importance enters as TWO channels that NEVER MERGE.** `c.fold_n` (fold count) lifts the CELL floor
    (`Cytui:3256`). `wgt` (the grasp's 0–100 neighbourhood loudness, `Voro_grasp_weight`, `Voro.g:660`)
     sets the TEXT font-band floor (`band_for`, `Cytui:1516`: ≥80→16pt · ≥45→14pt · else 7pt). **`wgt`
      is dropped for cell sizing** — a loud thing gets bigger TEXT but not a bigger CELL. Meaning-
       hierarchy and space-hierarchy are computed twice and reconciled never.
3. **Causality is CELL → TEXT.** `fit_stat` (`Cytui:1522`) sizes text DOWN to the chords of a cell the
    layout already fixed. Big text only ever means "filled its own cell."

**The law merges (2), inverts (3), and adds the missing global of (1) — installing in Stack B's stubs.**
 Reading order = data order:

- **① Scan** — *live* (`Vyto.g:178`). Mirror the grappled sources into `w.c.mirror` (off-snap).
- **② Fold · Gang** — *fill the stubs* (`Vyto.g:294,298`) with the ported crush (governor + gang rules)
   AND **`Stuff_distil`** (this session — `Voronation.g`; the re-home target). Each surviving pane gets
    its distilled `%Vtuffing`. **Importance is BORN here, and the two channels merge:** shared-ness (a
     value carried by many = a fact/vein) and count (`n`/`fold_n`) are the SAME signal read two ways —
      the grammar of compression already computes them (Springcore §the grammar). One number per thing:
       `importance(t)` = blend of intra-pane rank, graph-global shared-ness (a vein is global by
        construction), and fold count.
- **③ Relate** — *fill the stub* (`Vyto.g:421`). Within-pane relate is the **vein** (this session's new
   leg); cross-pane relate is edges landing nucleus-to-nucleus (§8). A relation lifts BOTH endpoints'
    importance (a thing that ties two branches matters more).
- **④ The global scale `S`** — *the NEW station, the law's heart; nothing today does this.* Collect
   `importance(t)` for EVERY text in the scape; solve ONE `S` with `size(t) = S·φ(importance(t))`, and
    **push `S` up until the frame is spent** (§1–§2). `φ` compresses the range (§4); the 14pt floor +
     split/fold (§2) catch the tail. Now the biggest word anywhere is the most important thing anywhere —
      the clarify §1 promised. This is the graph-global coupling both stacks lack.
- **⑤ Express — INVERTED** — *live scribe, new input* (`Vyto.g:431`). Today `env_area = 2400·(1+dose)`.
   The law: `env_area` = the area a cell's texts DEMAND at their `S·φ` sizes — the growth spell run
    **backwards**, from the text's rightful size to the cell that must hold it, enlarged toward a golden-
     shapely envelope when a whole truth won't fit (§2, the wholeness rule). `dose` becomes one input to
      `importance`, not the sole driver.
- **⑥ Focus — the taper** — *fill the stub* (`Vyto_focus`, `Vyto.g:415`, today `return`). Anchor `S` at
   the attended branch and fall off with `ψ(dist_from_focus)` (§5): far matter smaller AND bluer, a
    matched haze on the same `ψ`. The radio + `%Interest` drive the focus field (today the radio drives
     fold-SELECTION only, not a size field — this is the continuous field it's owed; pointer hover
      already damps size 0.3 at `Vyto.g:373` — the taper generalises that one cell to a landscape).
- **⑦ Solve** — *live* (`Vyto.g:453`). Power-diagram cells from `r = √(env_area/π)`, K=2 Lloyd, settle.
   The areas now encode importance×attention, so the geometry STATES the hierarchy.
- **⑧ Fit · paint — no longer shrinks-to-fit** (`Vytui`). Because ④–⑤ sized text globally and grew the
   cell to hold it, the fit PLACES text at its rightful size rather than clamping down to a pre-fixed
    cell. The nucleus floors at `0.34·R` (§8, `Cytui:2735`) so the subject is never the smallest voice.

**One line:** `Scan → (Fold·Gang·Relate: distil + compute importance) → S (one global scale) → Express
 (area = importance-demanded) → Focus (taper by attention) → Solve → place`. Importance computed ONCE at
  ②–③, scaled ONCE at ④, tapered ONCE at ⑥ — never the twice-computed-never-merged of today.

**The honest cost:** ④ makes the whole field re-breathe when one important thing arrives (§4.3) — `S`
 must glide with hysteresis, not jitter. And ④ is a genuine solve over all texts at once — the Sunpit
  `IOing` flock (§7) is exactly the shape for "N reaches that must resolve together," so the global-`S`
   station is the concrete tenant that un-parks the Sunpit. Prove ④ in isolation the way Stuffing proved
    ②: a Book that feeds importances and asserts the solved `S` + per-text sizes, no glass. **DONE
     (2026-07-21) — the `Typescale` Book** (`Voronation.g` `//#region Typescale`; Credence `What:Voro`)
      proves exactly this: global ratio · order · frame-spent · floor-fold · re-breathe, φ=√ as a first
       cut, green + adversarially gated (linear φ → red) on the live runner. What ④ still owes: the wire
        into `Vyto_express` (⑤, replacing dose) and the taper (⑥); and the human's preen of the φ|area|
         floor model this first cut committed to.

---

**Cross-refs:** `Voro_vtuffing.md` (gem · growth spell · fill_fs · veins), `vyto_workingouts/
 commission.md §3` (Sunpit/IOexpr), `vyto_workingouts/shapes.md` (envelope · min_text · 0.72),
  `Vyto_spec.md` ("space that states" §47; Sunpit §360/§487), `LangSolver_report.md` (the IOing
   language + `Sion`), `history/Voro_todo_parts_2026-07.md:392` (the shadows/landscape north-star).
