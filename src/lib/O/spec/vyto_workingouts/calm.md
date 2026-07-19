# Calm — workingout of Vyto §3

A workingout, not a spec: §3 of `spec/Vyto_spec.md` ("Calm — the foundation under the
 settling doctrines") elaborated to buildable shape, 2026-07-19.  Everything here is
  proposal until the human rules; the rulings owed are gathered at the end.

Calm is a governor: it places nothing, it permits.  It owns exactly three things —
 the **%Hold** (the composable claim of stillness), the one question everyone asks
  (`Calm_held`), and the one signal everyone reads (**settled**, emitted as a
   `%Settle` tick).  The renderer law rides underneath as the mechanism that makes
    every grant and every release smooth by construction.

## 1. The %Hold, concretely

Holds are c-side furniture under the Vyto world: at commission Calm makes itself a
 home hanging off `.c`, so the whole tree is unreachable from H\*\* and never snaps —
  Books stay Voro-blind by construction, not by discipline.

> ```
> w.c.calm                      ← _C({Calm:1}), made at commission, .c-side only
>   %Hold                       ← one claim of stillness
>   %Settle,settle_n:<n>        ← the tick conveyor (§6), a short ring
> ```
>
> One `%Hold` row:
>
> | key | kind | meaning |
> |---|---|---|
> | `scope:<id>` \| `scope:view` | sc | what it covers: a cell id, a scope id, or the whole view.  `.c.scope` backlinks the actual C (refs ride `.c`, never sc). |
> | `position` `size` `membership` `face` | sc, presence | the channels claimed — presence keys, `1`-or-absent (the snapped-boolean law kept even off-snap, for habit's sake).  `all:1` claims the lot. |
> | `pin:1` XOR `damp:<k>` | sc | strength.  `pin` = the channel may not move.  `damp:k`, k ∈ (0,1) = motion allowed at k-speed (mechanically: the spring's ω is scaled by k, §5). |
> | `while:pointer` \| `while:flight` \| `while:shift:<id>` \| `while:seek` \| `while:predicate` | sc | the release condition.  For `predicate`, the function lives on `.c.predicate` — an object or function in sc is fatal at encode and wrong everywhere. |
> | `by:<organ>` | sc | who placed it — Calm, Focus, Spool.  The board's **holds** toggle paints exactly this. |
> | `released_at:<ms>` `ease_ms:<ms>` | sc | the release tail (§4).  Absent while the hold is live; stamped when the while-condition ends; the row is retired (dropped) when the tail completes. |
> | `.c.except` | c | a Set of cells exempted from a view-scoped hold — how one shift-hold covers "everything uninvolved" without minting N rows. |
>
> Notation: `%Hold,position,pin,while:pointer,by:Calm` — the hovered cell's seed.

A hold that needs different strengths on different channels is two rows (the
 pointer-hold is: seed position pinned + boundary/size damped — two `%Hold`s, and the
  board shows both).  Rows are cheap; per-channel strength maps on one row are not
   worth the query awkwardness.

## 2. Resolution — the total order

The spec gives three sentences: *pointer beats layout — deletion beats pointer — seek
 beats everything but the human's own gestures*.  Read literally as one scalar
  priority they form a cycle (deletion > pointer, pointer is a gesture, gesture >
   seek, seek > "everything" ∋ deletion).  The cycle dissolves once you notice the
    three sentences talk about two different kinds of thing:

**Holds and grants rank; deletion supervenes.**  A hold constrains the motion of
 matter that exists.  Deletion is not a stronger claim in the same argument — it
  dissolves the subject.  When the model deletes a held particle, every hold on it is
   not *outranked* but *converted*: Calm retires the hold into an escort on the
    departure choreography (§4 of the spec — matter still goes somewhere), and the
     hold's ease shapes the departure's entry ramp, which is exactly why deletion
      under the cursor is choreographed and never a blink.  And under the
       landmark-hold there is no conflict at all: the parked display renders a
        captured `%Moment`, so a live deletion never even asks about it — it arrives
         as old truth in the retarget-from-current when **live** resumes.

What remains is a clean total order over claim sources, highest first:

> ```
> RANK = { gesture: 4, seek: 3, flight: 2, shift: 1, layout: 0 }
> ```
>
> - **gesture** — the human's own hand, live: drag writes, hover pins.  Nothing
>    argues with the hand.
> - **seek** — the landmark-hold.  Above every organ, below the hand: you can
>    hover and drag the parked display; the model cannot move it.
> - **flight** — the flight-latch.  Above shift: a new shift may retarget
>    positions freely mid-flight (that is the renderer law's whole point) but may
>     NOT flip a membership whose animation is still flying.
> - **shift** — the shift-hold, Focus's transaction.
> - **layout** — solvers' own damps, ambient claims.
>
> A hold **binds only askers of strictly lower rank** than its own source.  The
>  pointer-hold does not bind the hand that placed it (you may drag the hovered
>   cell); a shift's choreography is not bound by its own shift-hold (its involved
>    cells ride `.c.except` anyway).

**Combination rule.**  Per (cell, channel), among the holds that bind the asker:
 **pin short-circuits** — any live pin gives k = 0, stop.  **Damps stack
  multiplicatively** — k_eff = Π kᵢ.  Multiplication is the right algebra: it is
   order-free, it composes across nested scopes without a precedence table, and pin
    is simply its limit (k → 0).  A hold in its release tail contributes a strength
     lifted toward 1 along the ease curve, so releases are continuous by arithmetic,
      not by special case.

> ```
> Calm_held(cell, channel, asker = 'layout') → { k, by }
>     // k ∈ [0,1]: 0 = pinned, 1 = free, else damped (ω-scale, §5)
>     // by: the binding holds — the board's `holds` paint reads this verbatim
>   a  = RANK[asker]
>   k  = 1; by = []
>   for h of holds covering (cell, channel):          // scope match walks cell → scope → view
>     if h.scope is view and cell ∈ h.c.except:  continue
>     if RANK[source(h)] <= a:                   continue   // asker outranks it
>     s = strength_now(h)
>     if s == 0:  return { k: 0, by: [h] }                  // pin short-circuits
>     k *= s; by.push(h)
>   return { k, by }
>
> strength_now(h)
>   base = h.pin ? 0 : h.damp
>   if !h.released_at:  return base
>   u = clamp((now − h.released_at) / h.ease_ms, 0, 1)
>   if u >= 1:  retire(h)                                   // tail done — drop the row
>   return base + (1 − base) · (1 − (1 − u)³)               // cubic ease-out toward free
> ```
>
> Discrete channels (membership, face) have no half-flip: there, **any k < 1 means
>  refused this frame**.  Refusal is not a queue — the decision recomputes from
>   truth and asks again; if the truth stopped flapping, the flip lands after the
>    settle (§4, flight-latch).

The spec's signature is `Calm_held(cell, channel)`; the `asker` parameter is this
 workingout's addition, defaulting to `layout` so the common caller (a solver)
  writes the spec's two-argument form.

## 3. The four named holds — lifecycles

**The pointer-hold.**  Vytui owns the pointer facts (cells are real DOM now, so this
 is `pointerenter`/`pointerleave` on the cell element — the polygon hit-test of
  Cytui's `vlift_move` retires); it writes `w.c.pointer = {cell}` and pokes Calm.
   Calm mints, immediately, two rows on the entered cell — seed pinned, boundary
    damped:

> `%Hold,position,pin,while:pointer,by:Calm` +
>  `%Hold,size,damp:0.3,while:pointer,by:Calm` — the tessellation solves with the
>   seed fixed; the world rearranges *around* it.

On `pointerleave` Calm stamps `released_at` + `ease_ms:POINTER_EASE_MS` (=
 `grawave_duration`, so the release *feels like* one wave): strength eases 0 → 1
  along the tail, ω_eff ramps up from zero, and the ex-hovered cell accelerates
   gently toward whatever target now stands — **un-hovering never snaps** because
    motion resumes at zero speed, not because anything waits.  Hover moving A → B is
     just A's tail starting while B's fresh hold mints.  Deletion of the hovered
      particle supervenes (§2): the holds convert to the departure escort, the ease
       becomes the departure's entry ramp.  The hover z-lift (§8) rides alongside,
        untouched by Calm — z is presentation, not a channel.

**The flight-latch.**  Nobody "places" it by hand: Calm derives it continuously
 from renderer flight state, and mints a visible `%Hold,membership,pin,while:flight,
  by:Calm` row only while it actually binds (so the board's **holds** paint shows it
   exactly when it matters, and the row drops at settle — no tail; membership's ease
    IS the choreography).  Its real substance is per-decision bookkeeping, §4.

**The shift-hold.**  Focus places it at shift-open (transaction step 2): ONE
 view-scoped row, `%Hold,all,pin,while:shift:<id>,by:Focus`, with the shift's
  involved cells (and their overlays — "uninvolved" includes overlay matter) on
   `.c.except`.  The choreography moves the involved set by asking as
    `asker:'shift:<id>'`; everything else is pinned — **motion is granted, not
     ambient**.  Released at the shift's settle (step 4), with `ease_ms:0`: no tail
      is needed because the uninvolved never moved — any pent-up solver pressure
       releases through the spring, which is smooth from rest by construction.  A
        shift superseded by a newer shift releases its hold when Focus closes the
         transaction; and a shift that never settles must not wedge the glass — a
          `SHIFT_MAX_MS` backstop force-releases (the morph_backstop lesson: always
           a non-rAF ceiling on anything that "will land soon").

**The landmark-hold.**  Placed by Spool's seek machinery when display parks on a
 kept or blessed moment (the board's **live** toggle off): `%Hold,all,pin,
  while:seek,by:Spool`, scope:view.  It binds *display targets only* — Scan and
   Spool keep capturing live truth the whole time (the hold ranks below nothing
    they do, because they move no display matter).  Release is "live": the parked
     geometry becomes the current state of every spring and the newest truth
      becomes the targets — one big retarget-from-current, and the homecoming is
       the spring's ordinary glide.  Proposal: the homecoming rides the focus
        engine as a shift (the delta "everything that changed while parked"), so a
         long park comes home choreographed rather than as one simultaneous slide —
          ruled below (§9).

## 4. Flight-latch bookkeeping, precisely

The doctrine: a membership decision — **crush, gang, tuck, show, bunch** — latches
 while any animation involving its members is in flight, and may flip only after a
  settle since its last flip.  That needs two facts per decision and one counter per
   scope:

> Per scope (the enclosing scope's own settle clock, local — composition, §6):
> ```
> scope.c.settle_n     ← monotonic; bumps on each of the scope's false→true settles
> ```
>
> Per decision — stamped on the decision's OWN row, where its solver already keeps
>  its verdict (Fold's fold row, Gang's rep row, the %Bunch row, a tuck/show mark);
>   Calm does not mirror it:
> ```
> d.sc.state                  ← the enacted side (in|out, crushed|open, …)
> d.sc.last_flip_settle_n     ← scope.c.settle_n at the moment of the last flip
> d.c.members                 ← the constituency: the cells this decision moves
> ```
>
> The flip gate, which is what `Calm_held(·, 'membership')` computes for a
>  decision's cells:
> ```
> may_flip(d):
>   scope = enclosing_scope(d)
>   return scope.c.settle_n > d.sc.last_flip_settle_n     // a settle since last flip
>      and ∀ m ∈ d.c.members: at_rest(m)                  // nothing of theirs in flight
>
> on flip:  d.sc.last_flip_settle_n = scope.c.settle_n;  settled drops (motion begins)
> ```

A newborn decision initialises `last_flip_settle_n = scope.c.settle_n − 1`, so its
 first enactment is free (entrances are choreographed anyway; making a new fold wait
  for a settle it had no part in would read as lag).  The vanishing-node dance is now
   arithmetic: a model flapping across a threshold can flip a membership at most once
    per settle period, and never while its own animation flies — the queue the loop
     used to live in (`gn.sc.waves`) does not exist to host it.

`at_rest(m)` is the per-cell settle bit the renderer already keeps (§6): all of m's
 continuous springs within ε and no choreography holding m.

## 5. The renderer law as math

One critically-damped spring per animatable scalar — a cell's x, y, area; a wall
 vertex owns nothing (walls re-derive from seeds each frame).  Per scalar: current
  `x`, velocity `v`, target `T`.  **One target: retargeting is assignment.**  A
   superseded target is simply overwritten — there is no queue anywhere in the
    renderer, which is the single load-bearing difference from the wave machine
     (`gn.sc.waves = [...(gn.sc.waves ?? []), wave]` is the line this law abolishes).

> Critically damped: ẍ = −ω²(x−T) − 2ωẋ.  With y = x − T the exact per-frame step
>  (any dt, unconditionally stable — no Euler, no dt clamp):
> ```
> B  = v + ω·y
> e  = exp(−ω·dt)
> y′ = (y + B·dt) · e
> v′ = (v − ω·B·dt) · e
> x′ = T + y′
> ```
>
> ω from feel: the current glass's wave is `w.sc.grawave_duration` ≈ 0.4 s
>  (Cyto.svelte:100 seeds `??= 0.4`).  A critically damped step from rest has
>   residual e^(−ωt)(1 + ωt); choosing **ω = 6 / grawave_duration** (= 15 s⁻¹ at
>    0.4 s) leaves ~1.7% at t = grawave_duration — the motion *reads as done* in one
>     grawave, inheriting the feel without inheriting the fixed-duration tween.
>
> Calm plugs in as the ω-scale: per frame, per (cell, channel),
>  **ω_eff = Calm_held(cell, channel, asker).k × ω**.  k=1 free, k=0 pinned (no
>   motion, v decays to 0), damped in between — a damped boundary still follows the
>    world, sluggishly.  Targets are always written; a pinned cell just does not
>     chase, and on release it chases the *standing* target — the newest, the only
>      one there is.

**Why retargeting mid-flight is smooth:** replacing T changes only the frame the
 spring solves in; `x` and `v` carry over untouched, so position and velocity are
  continuous (C¹) across the retarget — only acceleration steps, and the eye does
   not read acceleration steps.  Truth arriving mid-flight therefore *bends* the
    motion instead of restarting it; ten retargets in a burst produce one curved
     glide, not ten animations.

**No overshoot**, one honest caveat: critical damping never overshoots from rest;
 a retarget inherited with large v *toward* the new target can cross it once,
  shallowly (bounded by v/(ω·e)), then settle — it reads as follow-through, never
   as bounce, and there is never oscillation.  If even that single crossing is
    unwanted, run slightly over-damped (ζ ≈ 1.05) at the cost of a visibly heavier
     tail — not proposed.

Discrete channels (membership, face) do not spring: they enact choreography
 (enter/leave along the pelt) once the flight-latch admits the flip.  Face motion
  *positions* (a face riding its cell) are the cell's springs; faces never get their
   own.

## 6. Settle — detection, composition, reset

> Per scope, per frame (in the scope's local coordinates):
> ```
> disp  = max over cells of ‖x − T‖                 // distance to rest
> drift = max over boundary vertices of ‖p_t − p_(t−1)‖   // derived-wall motion
> calm_frame = (max(disp, drift) < ε)
> settled after SETTLE_FRAMES consecutive calm frames
>     → scope.c.settled = 1; scope.c.settle_n += 1; (root only) w.c.settled = 1
>     → one %Settle,settle_n row minted (§7)
> ```
>
> Proposed constants, to be eye-tuned on the first tenant:
> **ε = 0.5 px**, with drift tightened to **0.25 px/frame** (vertex drift is
>  frame-relative; sub-quarter-pixel per frame is invisible at any zoom we run) —
>   prior art: Cytui's pre-tween "still" check uses 1.5 px on sampled boundary
>    points, and its wrap re-measure quantises at far coarser grain.
> **SETTLE_FRAMES = 8** (~130 ms at 60 fps) — long enough to reject a flap,
>  short enough that capture-at-settle still feels immediate.

Both maxes include drift measured on *derived* geometry, because a cell whose own
 seed is at rest still moves when a neighbour's wall shoves it — the eye watches
  walls, so settle must too.

**Composition** is the recursion of §5 of the spec: a scope is settled when **its
 own** disp/drift are under ε **and every child scope is settled**.  Each scope
  keeps its own `settle_n` clock (the flight-latch of §4 reads the *enclosing*
   scope's — a busy corner of the glass must not starve flips elsewhere, and a
    frozen unfocused scope is trivially settled, so it never blocks its parent).
     The global signal is the root's: `w.c.settled` is nothing but the root scope's
      bit, mirrored where the fleet expects it.

**Reset** — settled is dropped (deleted, 1-or-absent) by: adopting any target with
 ‖T−x‖ > ε; any membership flip enacting; any choreography or shift opening; a
  gesture beginning (drag-start, not hover — the pointer-hold *is* stillness).
   The consecutive-calm-frame counter zeroes with it.  `settle_n` never resets —
    it is a clock, not a state.

## 7. Emission discipline — where the tick runs, how it travels

The hard lesson stands behind this section: an unbounded await inside a belief beat
 deadlocks the beliefs mutex (the Sounditron lesson).  So:

> **The settle check runs at the tail of the render frame** — after springs
>  integrate and the paint lands, still UItime, a handful of maxes over cells:
> ```
> frame(dt):
>   1. integrate springs (closed form)          // §5
>   2. re-derive walls, paint, place faces
>   3. settle check                             // §6 — cheap, synchronous
>   4. on false→true:  queueMicrotask(Calm_settle_stamp)
> ```
> `Calm_settle_stamp` (still off any beat, off the hot paint path): stamps
>  `w.c.settled` / bumps `settle_n`, mints `%Settle,settle_n` under `w.c.calm`
>   (a short ring — drop-oldest, it is a tick conveyor, not a ledger), and
>    **bumps the version of a watched C** enrolled via `watch_c`.
>
> Delivery to model-side listeners rides the existing Housing machinery
>  (Housing.svelte.ts `start_watched_C_effect`): the debounced flush fires
>   handlers only after `this.clear(...)` — the Atime→UItime gate — i.e. after
>    any in-flight beliefs pass has released the mutex.  Spool's capture (the
>     enWaft of the moment), Situation checks, and ceremony resolution all run
>      in that flush: **model side, off the render loop, never inside a beat.**

Two corollaries, stated as law:

- **No beat ever awaits a %Settle.**  A req that wants to proceed at settle arms a
   ttlilt or re-checks `w.c.settled` next pass; ceremony that must *wait* rides the
    request layer (spec §10: ceremony rides the request, never the commission), the
     way `e_Cyto_animation_request` awaits the `cy_settled` stamp today — floored at
      a dwell, **hard-ceilinged** so a wedged glass can never wedge a Run.
- **Capture cost never rides the frame.**  Frame-side settle work is comparisons
   and one microtask; everything that allocates (enWaft, diffs, Situation
    matching) happens in the watch flush.

Hidden tabs run the same discipline through the sync-paint path (§8): the settle
 check runs right after the synchronous paint, and a jump-to-target landing declares
  settle immediately — SETTLE_FRAMES debounces wriggle, and a synchronous landing
   has none.

## 8. Inherited visual constants

Carried over verbatim — these are rulings already worn in on the current glass, not
 open design:

> - **mold 1.5× unclipped** — `stuff.scale` 1.5 (the split-the-difference ruling,
>    walked back from 2), `stuff.clip` 0: molded content deliberately noses past
>     its walls, untrimmed.
> - **`mold_max_fit` wall-bind** — the true bind is the largest scale seating the
>    content's *current* box inside the actual cell polygon (never the bbox),
>     applied at 0.92; the absolute band `stuff.top` 2 / `stuff.bottom` 0.5 still
>      rules.
> - **sqrt-damped overflow** — `stuff.damp` 0.5: whatever the band/scale asks past
>    the true bind grows like (want/bound)^0.5, so a floor-propped shelf noses out
>     ~1.8× where it used to bury the neighbourhood 3×.
> - **hover z-lift** — the moused-over cell surfaces above the pile.  In Vyto the
>    cell is real DOM, so the lift is `pointerenter` + a class on the cell element;
>     Cytui's per-mousemove polygon hit-test retires.  Keep Cytui's hard-won detail:
>      **re-assert the lifted class after any re-mint of the element** — a re-minted
>       node loses it silently.
> - **`document.hidden` → sync-paint** — rAF pauses in hidden tabs (every ?B=
>    runner): on a target change while hidden, land the closed form at t→∞ (jump to
>     target), paint synchronously via microtask, stamp settle.  The *unfocused*
>      (visible but throttled to ~1 fps) case that needed Cytui's `morph_backstop`
>       dissolves by construction: the exact integrator is dt-correct at any frame
>        gap, and Vyto never clears matter during motion (no vsubs-cleared-then-
>         restored window), so a slow tab shows slow frames of *correct* geometry
>          rather than blanks.
> - **`w.sc.grawave_duration` ??= 0.4** at commission — §5's ω derives from it.
>    (Note while inheriting: the current code seeds 0.4 at Cyto.svelte:100 but
>     falls back to 0.3 at its read sites and in Cytui — Vyto should read one
>      constant, one default, 0.4.)

## 9. Open questions

1. **Deletion's standing**: this workingout takes deletion out of the rank table —
    a supervening event that converts holds into departure escorts — rather than a
     rank above gesture.  Same observable behaviour ("deletion beats pointer", still
      choreographed), cleaner algebra.  Bless or overrule.
2. **Damp semantics**: chosen here as an ω-scale (motion allowed, slower).  The
    alternative — blending proposed targets toward current — damps *where things go*
     instead of *how fast*.  The ω-scale is proposed because it keeps Calm entirely
      out of the solvers' geometry.  Rule if the felt difference matters.
3. **ε = 0.5 px / drift 0.25 px/frame / SETTLE_FRAMES = 8** — proposals to eye-tune
    on the first tenant (the Radio world).  Also whether ε should scale with zoom
     (screen-px vs world-px; screen-px proposed, since settle is about the eye).
4. **Landmark release as a shift**: should coming home from a long park ride the
    focus engine (choreographed delta) rather than one big simultaneous
     retarget-from-current?  Proposed yes; it makes `live` a Focus client.
5. **The single shallow crossing** under inherited velocity (§5): accept as
    follow-through (proposed) or run ζ ≈ 1.05 slightly over-damped everywhere.
6. **Flight-latch clock scope**: the *enclosing* scope's `settle_n` is proposed
    (composition; a busy corner must not starve flips elsewhere).  The stricter
     alternative — the root's — is one word of change if the loose version ever
      lets a visible flap through.
