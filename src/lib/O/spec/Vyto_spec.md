# Vyto — the glass, reborn

Drafted 2026-07-19; round 2 the same day, after the human's design payload (hover-holds, the
 settling culture, the focus engine, scopes, semantic space, Zyto, the dictionary).
  **Unpreened** — this becomes a spec when the human has read it and says so; until then it is
   the founding argument.  Coined words are gathered in §14; several are the human's and carry
    proposed meanings awaiting their preen.

## 1. Why a new glass

Cyto began as a graph viewer and became the front of the app.  The voronoi glass, the faces,
 the molds and walls, the tuner — "the model IS the UI" — all arrived after the substrate was
  chosen, and the substrate is a node-and-edge library.  Every part of the glass that is not a
   node rides as an overlay synced to Cytoscape's render loop, and that seam is where a whole
    family of bugs lives: the rAF-throttle blanking, the text that can't size itself, the
     diagonal-and-spring relayout, the overlay positions that drift and hop.  We have been
      paying rent on a building we outgrew.

Two findings force the fork rather than the remodel:

- **The glass has no continuous drive.**  The comments say "Cyto watch_c's the Scannable and
   rescans on any version bump" — no such watch exists anywhere.  The only pokes are Story's
    per-step animation request and the hand gestures (tuner, pop, crush, seek, wipe).  After
     the last step, or inside a long overtime hold, nothing scans: the tessellation fossilises
      while the faces (live components) keep updating.  The drive isn't broken; it was never
       built.
- **The wave machinery is imperative.**  Waves are queued diffs (`gn.sc.waves` is literally an
   array clients can outrun) and animations replay them.  A model that flip-flops membership
    near a threshold turns that queue into a loop — the vanishing-node dance.  You cannot
     patch a queue into a fixed point; you have to change what a wave *is* (§3).

So: **Vyto**, a second glass, commissioned per world exactly the way Cyto is, coexisting while
 the fleet migrates.  What freezes is **Cyto.svelte + Cytui.svelte** — the scan-to-cytoscape
  pipeline and its renderer.  **Voro.g does not freeze**: the fold algorithm, the gang
   election, the drift's *knowledge* are model-side and become Vyto organs (§9); what dies of
    Voro is only its scattered magic arming — replaced by the focus engine (§4).  Strangler,
     not surgery; expressibility only ever goes up (what goes down is the number of ways the
      system can surprise us — see §12 on "unexpressible").

## 2. What Voro really wants

Six wants.  When a design question comes up later, answer it by asking which want it serves.

**Space that states.**  Area, shape, neighbourhood and enclosure *are* the sentence, not
 decoration on a dot.  The renderer's primitives are region, boundary, containment; nodes and
  edges are a special case, not the foundation.

**Expression first.**  `dose drives area` is one binding of one quantity to one channel.  The
 aim is the composable version: model quantities flowing into visual channels — area, weight,
  hue, depth, motion amplitude, background|foreground — as declared bindings (§7), so the
   glass can *look amazing* on purpose rather than by hand-tuned accident.

**Motion, never blink.**  The glass is watched continuously, like a face.  Identity must be
 trackable by eye: a cell moves, grows, merges, is absorbed — it never pops out of existence
  and reappears.  Even true deletion reads as matter going somewhere.  This law covers the
   overlays and faces exactly as much as the cells: a focus shift that makes a face hop or
    blink has broken it.

**Rest.**  Music has rests; the glass must be able to be *still*.  The magic wriggle is an
 entrance, not a lifestyle.  "Settled" is a real, detectable, reportable state, and stillness
  is the default from which motion is granted (§3) — not a lucky pause between splats.

**Interruptibility.**  Truth arrives mid-flight; the glass retargets from wherever it is,
 smoothly.  Nothing restarts from scratch; there is no relayout-from-nothing anywhere in the
  design.

**The model is the UI.**  Faces are the app, living in cells.  Cells are real DOM: a face is
 a child element, text is measured by the browser, and the overlay-sync bug class ceases to
  exist rather than getting fixed.

## 3. Calm — the foundation under the settling doctrines

The human is right that there will be an ongoing *culture* of settling doctrines — hover
 wants one, flight wants one, focus shifts want one, landmarks want one, and we have not met
  them all yet.  A culture needs a foundation, not a pile of special cases: **Calm**, the
   organ that owns stillness.  Its primitive is the **%Hold**.

A Hold is a declared, composable claim of stillness: *this scope, these channels, this
 strength, while this condition lasts*.  Everything that used to be an ad-hoc trick becomes a
  Hold with a name:

- **The pointer-hold** (the human's ask): the moused-over cell is pinned — the tessellation
   solves with its seed fixed and its boundary damped, the world rearranges *around* it.
    Released with an ease-out when the pointer leaves, so un-hovering never snaps.  If the
     model deletes the hovered particle, deletion wins (matter still goes somewhere) but the
      departure is choreographed (§4), never a blink under the cursor.
- **The flight-latch**: membership decisions (crush, gang, tuck, show) latch while any
   animation involving them is in flight, and may only flip after a settle since their last
    flip.  This is Law 1 from round 1, re-homed as a Hold on the *membership* channel.
- **The shift-hold**: during a focus transaction (§4) everything not involved in the delta is
   held still by default.  **Motion is granted, not ambient** — the single sentence that
    sweeps the autosplat tricks away.
- **The landmark-hold**: while the glass is displaying a blessed moment (§8), live capture
   continues but display follows nothing — the whole view is one big Hold with a "live"
    release.

> **%Hold** shape (furniture under `w:Vyto`, c-side, never snapped): `scope` (a cell, a
>  scope §5, or the view), `channels` (position | size | membership | face | all),
>   `strength` (pin | damp:k), `while` (pointer | flight | shift:<id> | seek | predicate),
>    `by` (which organ placed it — Zyto shows this).  Holds compose by priority: pointer
>     beats layout; deletion beats pointer; seek beats everything but the human's own
>      gestures.  Calm exposes one question the whole system asks: `Calm_held(cell,
>       channel)` — and one signal: **settled** = `max(cell displacement, boundary vertex
>        drift) < ε` sustained `SETTLE_FRAMES`, stamped `w.c.settled`, dropped on any new
>         target, emitted as a `%Settle` tick.  The spool captures at settle; ceremony can
>          await it; the `--why` successor reads it.  Renderer law (Law 2 from round 1):
>           one target per cell, retarget-from-current, superseded targets dropped, never a
>            queue; critically-damped tween, no overshoot.  Inherited visual constants:
>             mold 1.5× unclipped, `mold_max_fit` wall-bind, sqrt-damped overflow
>              (`stuff.damp`), hover z-lift, `document.hidden` → sync-paint.

With Calm in place the vanishing loop is not fixed but *unhostable*: the renderer has no
 queue to replay and the model has no permission to churn.  Whatever residual wriggle
  remains is target churn — visible in the spool, assertable, and Zyto (§9) will show which
   organ granted the motion.

## 4. The focus engine — shifts as transactions, explanation as choreography

Focus is a model fact, not a side effect of drift tricks.  One organ — **Focus** — owns
 "what matters right now" and *every* change of it, replacing the scattered magic
  (popped_auto ageing, drift's own openings, autosplat re-foldings) with one rule-driven
   channel.  Voro_drift survives as a *client* of Focus: the radio walks attention by
    submitting focus proposals, it never touches layout.

A focus change is a **shift** — a transaction with a computed delta:

1. Collect: what enters focus, what leaves, what merely re-ranks.
2. Hold: everything uninvolved gets the shift-hold (§3).  The overlays of uninvolved cells
    are part of "uninvolved" — this is where blink-and-hop dies.
3. Choreograph: the involved cells move through **intermediary visuals** that explain the
    outcome — a fold *gathers* its members visibly before merging; an eviction *shrinks
     toward* the gang rep that absorbs it; an arrival *grows from* the parent seam.  The
      viewer should be able to say afterwards how things ended up where they are.
4. Settle, release holds, capture a moment.

Because moments capture settled states (§8), any explanation can be *replayed*: the
 choreography between two spool moments is derivable from their diff — the same diff the
  panel shows as bytes, the glass shows as motion.  One truth, two renderings.

## 5. Scopes and projection — the compound-subgraph question, answered yes

Should subcell sub-graphs be compound nodes holding a subgraph, laid out and projected into
 the cell?  Yes — and it becomes the recursion at the heart of the layout:

Every cell is (potentially) a **scope**: a local model with its own layout solved in its own
 coordinates, its own settle, its own Holds.  The parent never solves the child's innards; it
  sees only the scope's **envelope** — a size demand and shape preference.  Projection maps
   the solved local layout into the cell's polygon.  Text is fitted *inside the scope*
    ("wiggle until Text fits really nice" is a local relaxation with text metrics as
     constraints) and glyphs render upright in screen space after projection — positions
      project, letterforms never shear.

The payoffs stack:

- **Settle composes.**  A scope reports settled; a parent is settled when its children are
   and its own motion is under ε.  The global settle signal is the root's.
- **Performance is the focus engine.**  An unfocused scope freezes its local solve entirely —
   its innards don't tick, its envelope holds.  Depth of liveness follows attention.
- **The ▦ gem generalises.**  The sub-graph slice stops being a special face and becomes what
   every scope *is*.
- **Organ-bodies fit the same shape.**  The "long bodies of meshed little dots" (§6) are just
   scopes whose local layout is a dot-mesh soft body; their envelopes pack against sibling
    envelopes like organs of different sizes claiming space in an abdomen.

> Scope furniture: `%Scope` on the holder cell (c-side), carrying `layout:` (which organ
>  solves it — fold | slope | mesh | physics | manual), `envelope` (area demand, aspect/shape
>   preference, min text size), `solved` (local positions, local settle flag).  Projection =
>    fit transform (translate/scale, gentle warp allowed for molds), never applied to glyph
>     geometry.  A scope's dots are still particles — Books remain Voro-blind because all of
>      this is c-side view matter.

## 6. Semantic space — when position IS meaning

"Seed from live positions" undersold what live positions *are*.  In this app a position can
 be model semantics: the human's shuffle-slope-queue — Piers or their Mags arranged on a
  slope where height means how much to select, or what plays first — is a layout in which
   **geometry is the value**.  So every scope declares who owns its positions:

- **Layout-owned**: the solver places things; positions are view matter (most scopes).
- **Meaning-owned**: the model places things and *reads them back* — a **%Slope** scope maps
   a model weight to position, and dragging a Mag up the slope writes the weight.  The glass
    becomes an instrument: arranging the queue is playing it.  This is the ground where the
     toys join on — mixing from friends' Mags by moving them, what-plays-first as a gesture.

Edges split into two castes with opposite rendering doctrines:

- **%Flow** — meaning-bearing relations: data flows (a pull streaming chunks, a cast going
   out, a suggestion arriving), affinities, conveyances.  Drawn loud and beautiful: the curvy
    stretch-slides, animated along their length, foreground vector work.  The Radios toplevel
     gets wired with these — the flows between organs *are* its visual.
- **%Frame** — layout-systemising relations: containment stand-ins, alignment, the solver's
   own scaffolding.  Drawn like the long straight lines on old maps — faint, straight,
    receding, present enough to explain the geometry and never louder than that.

And more edges should *exist*: a **Relate** organ derives %Flow edges from meaning (same
 artist, co-heist, played-together, freshly-flowed) — c-side, spool-visible, entirely view
  matter.  Generating relation from meaning is something the glass should do more of, not
   less; Relate is where that appetite lives.

## 7. Express — the channel bindings

The generalisation of `dose drives area`, and of Matstyle's auto-swatch instinct: **Express**
 owns declared bindings from model quantities to visual channels.

> binding: `%Express` rows under The/Styles-like furniture — `from:` (an sc key or derived
>  quantity), `to:` (area | weight | hue | saturation | z | blur | fg/bg | motion-amplitude |
>   edge-loudness), `curve:` (lin | log | sqrt | band), `range:`.  Background|foreground is a
>    first-class channel: systemic matter recedes (blur/desaturate/thin), meaningful matter
>     advances — the map-lines doctrine of §6 is just an Express binding on the %Frame caste.
>      All of it feeds an SVG-native renderer: real strokes, filters, gradients along %Flow
>       paths — the vector look is a *consequence* of channels being declared rather than
>        hand-painted per case.

## 8. The Spool — moments, blessing, landmarks

The yore ring as built foundation (round 1) stands: moments captured at settle, ring of ~60,
 drop-oldest, freeze on run-fail, enWaft payload diffable in the Storui machinery, seek is
  display-only, pips lock to `step_n`, the scrubber walks `yore_n` — spools are clocks with
   quantize-locks, not lists.

Round 2 adds what the human asked for: **free tagging — anchoring, blessing, tracking.**

- Any moment can be **tagged** freely (cheap, plural, disposable — a word stuck to a tick).
- A moment can be **blessed**: named, pinned outside the ring's retention (a blessed moment
   never drop-oldests), and pointed — `%Assertion`-style — at what it is mainly about, with
    the microsnap idiom capturing its subject.  Blessing is the human's act, like the declare
     door: code mints moments, only the human promotes one to a landmark.
- A blessed **landmark** is a state we might see again — so it is *watchable for*.  A
   Situation (§9) can be armed from a landmark: "tell me when the glass is substantially here
    again," judged by enWaft nearness, and the sighting pins its own moment as evidence.

> blessing rides the moment row in `w:Vyto` (off-snap as ever): `bless:<name>`,
>  `sentence:` (no commas — em-dashes; the assertion sentence laws apply), `.c.microsnap` of
>   the subject.  Tags are sc words on the row.  The scrubber strip renders blessed moments
>    as anchored marks (the pip-diamond idiom); seek-to-landmark is one click; landmark-hold
>     (§3) governs display while parked there.

## 9. Zyto — the organ board

The glass is now explicitly a body of **organs**: Scan, Fold (Voro.g's algorithm), Gang,
 Focus, Calm, Express, Relate, Slope(s), Flow, Spool, Settle.  **Zyto** is where the body is
  seen and handled — the toolbar-panel that shows the organs, their links, and their levers.

Each organ stands as furniture under `w:Vyto` (the `%Tuner` convention generalised): it
 declares its inputs and outputs, its toggles and dials, its current status.  Zyto renders
  that — and because organs-and-links are themselves particles, the organ graph can be shown
   *in a Vyto glass*: the machine seen in its own matter, which is the whole bet.

Zyto also hosts **Situations** — the human's "similar to Assertions, but looking for
 situations" made crisp.  An Assertion swears a truth once, gating a run.  A **%Situation**
  is a *standing recognizer*: it watches, run-agnostic, for a describable state of the glass
   — good or bad — and every recognition mints a **%Sighting** with a pinned spool moment as
    evidence.  First tenants: the pathologies we're designing away (membership churn above
     hysteresis, an overlay that moved during a shift-hold, text below its minimum fit, a
      settle that never came) — and the landmarks (§8).  Situations badge on Zyto; sightings
       are inspectable with the diff panel.  What Assertions are to a Book's contract,
        Situations are to the glass's ongoing life.

> Zyto heritage: the ballistics drum pad (struck-on-demand, off-snap) for organ pokes; the
>  Credence board for the at-a-glance status row; the assertion explorer for the
>   sightings list.  All c-side; a Book never sees Zyto.

## 10. The commission and the grapple

Corrected per the human: `watch_c(Scannable)` was aimed one joint too high.  The state that
 *feeds* the Scannable lives in bits of gear — stokers, lineups, piers, ledgers — and the
  Scannable is assembled from them (it will `.r()`).  So Vyto watches **the gear**, and the
   commission is where it learns what the gear is:

- **Plain form**: the commission hands a ready `Scannable` (+ `Styles`, `client_w`) and an
   explicit grapple list — the source Cs to watch.  Default, if no list: watch the Scannable
    itself (its `.r()`s bump it), which is the degenerate case that still beats today's
     nothing.
- **Recipe form** (the human's Sunpit sketch): the commission expresses *how to make* the
   Scannable — a bundle of **IOexpr**s, each naming a source and a shaping, landing in the
    **Sunpit**, the staging container where the poured-in sources assemble into the
     Scannable.  Because the recipe names its sources, Vyto derives the grapple set
      transitively — *a grapple on what it has a grapple on* — and `watch_c`'s the whole
       complicated bunch of input.  Radio-protocol specifics ride here naturally: the Radio
        commissions with a recipe ("my stoker's stock, these piers' Mags shaped as a slope,
         the trickle's presence"), and the watching follows from the saying.

> commission sc, v1: `Scannable` | `recipe` (IOexprs), `Styles`, `client_w`, `grapples`
>  (optional explicit list).  Nothing else: faces and the fold are Vyto's nature, not opts.
>   **No takeTurns, no wants_wave_done/animation_done — ever on the commission**; ceremony,
>    when Story needs it, rides the request.  The drive: `watch_c` on every grapple,
>     coalesced trailing-edge, one scan per burst, scans off the watch flush — never inside
>      a beat.  Owned by the run: stands with the Run House, lives as long as the world;
>       Story is a seek client.  Furniture lookups walk all three shapes (H > A > w — the
>        %Tuner lesson; the failure is silent and reads as "toggles do nothing").

## 11. The shape: Vyto.g + Vytui.svelte

**Vyto.g** — model side, in the DSL, because the work *is* minting hierarchy: organs, holds,
 scopes, spool rows, cell trees.  Indent-is-the-branch means the code's shape mirrors the
  C-tree it builds.  The closure-heavy scan passes stay in TS and are called (the parse-storm
   gotcha); real deps via IMPORT().  **Vytui.svelte** — render side, because it needs markup:
    SVG/DOM cells, faces as children, the viewport.  Home: `Ghost/V/Vyto.g` beside Voro.g,
     CREDULER_GHOSTS + overlay, ghost-compiled like family.

The human's build instinct is adopted as the plan: **high-level coding first** — the opening
 milestone writes Vyto.g's skeleton with the organs, furniture and dictionary words as named
  stubs (Zyto listing them from day one), so the vocabulary exists *in the workings* before
   any rendering is attempted, and the words get worn in while they're still cheap to rename.

## 12. The strangler plan

- **v1 refuses**: takeTurns, ceremony flags on the commission, cytowave snapping, headless
   anything, relayout-from-nothing.
- **First tenant**: one Radio world on BigSoundland end-to-end — recipe commission, grapple
   watch, spool, strip, Calm with the pointer-hold, one %Slope.  Fixes "not responding
    later" where it hurts most; hands the abdomen to the reality that should invent it.
- **What freezes**: Cyto.svelte + Cytui.svelte, maintenance only.  Voro.g lives on as the
   Fold organ (and lends Gang, and its drift knowledge to Focus).
- **On "unexpressible", clarified**: expressibility of *intent* goes up — more can be said
   (holds, shifts, slopes, situations).  What goes down is the expressibility of *failure*:
    Vyto has no from-scratch relayout, so the diagonal-and-spring cannot be written; no wave
     queue, so the vanishing loop cannot be hosted.  We are not porting those bugs' fixes —
      we are removing the vocabulary they were written in.
- **The migration tail**, so "supersede" has a definition of done: Storui's seek needs the
   whichever-glass-is-commissioned dispatch seam (today it elvistos `'Cyto/Cyto'` by name);
    `runner_shot` gets a Vyto twin (easier — the render *is* structured SVG); Books whose
     fixtures carry a cytowave convert or drop it; `--why` re-homes onto %Settle.  When
      every commissioned world is on Vyto and those four are done, Cyto and Cytui retire
       whole to `spec/history/` manners with a historicity notice.

## 13. Proving it

All testing is Story Books on the live runner, and the spool is its own best instrument:
 scrub two moments and watch the choreography between them, deterministically — the harness
  for every §3/§4 decision.  A model harness in the Voro_model/VoroTest manner asserts the
   doctrines: membership never flips within a settle (adversarial probe: one line removing
    the hysteresis must go red), targets converge when input stops, moments capture only at
     settle, the ring freezes on fail, a shift-hold really held (the overlay-hopped
      Situation is *itself* the assertion — the diagnostics and the tests are one
       vocabulary).  The glass swears with `story_swear` like everyone else; "the glass
        settled — every cell at rest" is a natural first sentence.

## 14. Dictionary — the words we are coining

The vocabulary, gathered so it can be preened *before* it hardens into mainkeys.  Mainkey
 candidates need the usual uniqueness check against the fleet before first mint.

| word | kind | proposed meaning |
|---|---|---|
| **Vyto** | ghost (.g) | the model side of the new glass: organs, scopes, spool, commission |
| **Vytui** | ghost (.svelte) | the render side: DOM/SVG cells, faces as children, viewport |
| **Zyto** | panel/organ | the organ board: organs, links, levers, Situations (the human's coinage) |
| **Calm** | organ | owns stillness: Holds, the settle signal, motion-is-granted |
| **%Hold** | particle | one composable claim of stillness (scope × channels × strength × while) |
| **%Settle** | tick | the settled-flip signal; capture/ceremony/telemetry all read it |
| **Focus** | organ | owns "what matters now"; all shifts are its transactions |
| **shift** | transaction | one focus change: collect → hold → choreograph → settle → moment |
| **%Scope** | particle | a cell's local world: own layout, own settle, envelope to the parent |
| **envelope** | value | what a parent sees of a scope: area demand + shape preference |
| **%Slope** | scope-layout | meaning-owned positions: geometry is the value (the shuffle-slope-queue) |
| **%Flow** | edge caste | meaning-bearing relation: loud, curvy, animated |
| **%Frame** | edge caste | layout-systemising relation: faint, straight, receding (old-map lines) |
| **Relate** | organ | derives %Flow edges from meaning (same-artist, co-heist, played-together) |
| **Express** | organ | declared bindings, model quantity → visual channel (dose→area generalised) |
| **Spool** | primitive | an ordered series of captured moments; a clock, not a list |
| **%Moment** | particle | one capture: yore_n, step_n lock, enWaft payload, tags |
| **bless / landmark** | act / particle | human promotes a moment: named, unforgettable, pointed at its subject |
| **%Situation** | particle | a standing recognizer — Assertion's run-agnostic sibling (the human's hunch) |
| **%Sighting** | particle | one recognition by a Situation, with a pinned moment as evidence |
| **Sunpit** | container | staging pit where a recipe's sources pour in and assemble the Scannable (the human's coinage) |
| **IOexpr** | value | one recipe line: name a source, shape it (the human's coinage) |
| **grapple** | verb/edge | Vyto's watch-hold on a source; transitively, on what the source grapples |
| **%Seek** | furniture | the seek state holder: open_at, live latch (was "%SeekThing" in the asking) |
