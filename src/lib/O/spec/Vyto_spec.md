# Vyto — the glass, reborn

Drafted 2026-07-19; round 2 the same day (hover-holds, the settling culture, the focus
 engine, scopes, semantic space, the dictionary); round 3 the same evening (the shape
  catalogue, the pelt, bunching, the board rewritten — Zyto struck as a slip, the o-mark,
   "the moult").  **Unpreened** — this becomes a spec when the human has read it and says
    so.  Coined words are gathered in §14.  The machine-level elaborations live in
     `vyto_workingouts/` (shapes · pelt · calm · spool · commission) — each checked against
      the live code and each ending in open questions; `Vyto_todo.md` is the working doc.

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
 the fleet migrates.  What is eventually shed is **Cyto.svelte + Cytui.svelte** — the
  scan-to-cytoscape pipeline and its renderer.  **Voro.g is not shed**: the fold algorithm,
   the gang election, the drift's *knowledge* are model-side and become Vyto organs (§9);
    what dies of Voro is only its scattered magic arming — replaced by the focus engine (§4).
     A moult, not surgery (§12); expressibility only ever goes up — what goes down is the
      number of ways the system can surprise us (§12 on "unexpressible").

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

There will be an ongoing *culture* of settling doctrines — hover wants one, flight wants one,
 focus shifts want one, landmarks want one, and we have not met them all yet.  A culture
  needs a foundation, not a pile of special cases: **Calm**, the organ that owns stillness.
   Its primitive is the **%Hold**.

A Hold is a declared, composable claim of stillness: *this scope, these channels, this
 strength, while this condition lasts*.  Everything that used to be an ad-hoc trick becomes a
  Hold with a name:

- **The pointer-hold**: the moused-over cell is pinned — the tessellation solves with its
   seed fixed and its boundary damped, the world rearranges *around* it.  Released with an
    ease-out when the pointer leaves, so un-hovering never snaps.  If the model deletes the
     hovered particle, deletion wins (matter still goes somewhere) but the departure is
      choreographed (§4), never a blink under the cursor.
- **The flight-latch**: membership decisions (crush, gang, tuck, show, bunch) latch while any
   animation involving them is in flight, and may only flip after a settle since their last
    flip.
- **The shift-hold**: during a focus transaction (§4) everything not involved in the delta is
   held still by default.  **Motion is granted, not ambient** — the single sentence that
    sweeps the autosplat tricks away.
- **The landmark-hold**: while the glass is displaying a kept or blessed moment (§8), live
   capture continues but display follows nothing — the whole view is one big Hold with a
    "live" release.

> **%Hold** shape (furniture under `w:Vyto`, c-side, never snapped): `scope` (a cell, a
>  scope §5, or the view), `channels` (position | size | membership | face | all),
>   `strength` (pin | damp:k), `while` (pointer | flight | shift:<id> | seek | predicate),
>    `by` (which organ placed it — the board shows this).  Holds compose by priority:
>     pointer beats layout; deletion beats pointer; seek beats everything but the human's
>      own gestures.  Calm exposes one question the whole system asks: `Calm_held(cell,
>       channel)` — and one signal: **settled** = `max(cell displacement, boundary vertex
>        drift) < ε` sustained `SETTLE_FRAMES`, stamped `w.c.settled`, dropped on any new
>         target, emitted as a `%Settle` tick.  The spool captures at settle; ceremony can
>          await it; the `--why` successor reads it.  Renderer law: one target per cell,
>           retarget-from-current, superseded targets dropped, never a queue;
>            critically-damped tween, no overshoot.  Inherited visual constants: mold 1.5×
>             unclipped, `mold_max_fit` wall-bind, sqrt-damped overflow (`stuff.damp`),
>              hover z-lift, `document.hidden` → sync-paint.

With Calm in place the vanishing loop is not fixed but *unhostable*: the renderer has no
 queue to replay and the model has no permission to churn.  Whatever residual wriggle
  remains is target churn — visible in the spool, assertable, and the board (§9) shows which
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
     toward* the gang rep that absorbs it; an arrival *grows from* the parent seam, along
      the pelt (§5).  The viewer should be able to say afterwards how things ended up where
       they are.
4. Settle, release holds, capture a moment.

Because moments capture settled states (§8), any explanation can be *replayed*: the
 choreography between two spool moments is derivable from their diff — the same diff the
  panel shows as bytes, the glass shows as motion.  One truth, two renderings.

## 5. Scopes, shapes, and the pelt

### The recursion

Every cell is (potentially) a **scope**: a local model with its own layout solved in its own
 coordinates, its own settle, its own Holds.  The parent never solves the child's innards; it
  sees only the scope's **envelope** — a size demand and shape preference.  Projection maps
   the solved local layout into the cell's polygon.  Text is fitted *inside the scope*
    ("wiggle until Text fits really nice" is a local relaxation with text metrics as
     constraints) and glyphs render upright in screen space — positions project, letterforms
      never shear.

The payoffs stack: settle composes (a parent is settled when its children are and its own
 motion is under ε — the global signal is the root's); performance follows attention (an
  unfocused scope freezes its local solve entirely, innards not even ticking); and the
   organ-bodies of §6 are just scopes whose solver is a dot-mesh.

### The shape catalogue

Tessellation needs a small closed set of shapes it knows how to cut and pack.  Closed on
 purpose: a new shape is a spec event, not a Tuesday.

> | shape | how it tessellates | its natural combing |
> |---|---|---|
> | **cell** | irregular polygon by seed-and-relax (Fold's own) | radiates from the seed |
> | **slab** | rectangles by slice-and-dice | parallel to the long axis |
> | **band** | stacked strips whose order means something (Slope's home) | combed downhill |
> | **wedge** | radial sectors of a disc | along the radius |
> | **ring** | orbital lanes around a middle | tangential, orbiting |
> | **mold** | the rounded organic fit — 1.5× unclipped inside its wall band | along the mold's spine |
> | **body** | the elongated dot-mesh organ, packed against siblings | along the spine, ribs across |

### The pelt — the tiny hairs are the field

The thing that does "into the cell's polygon" is not a matrix.  It is a **pelt**: a field of
 tiny hairs over the cell's interior.  One hair is a sample — *at this point, lie in this
  direction, this strongly*.  One hair is nothing; together they are the field.  The solver
   that owns the scope combs the pelt (each shape's natural combing, above); everything else
    reads it:

- **Projection** lays the local layout along the hairs — content flows with the comb instead
   of being scaled naively into place.
- **Text baselines** ride hairs.  This is the door Wes-Wilson walks through: lettering
   combed by its cell, the label flowing to fill the mold.
- **Mesh grain**: the dots of a body mesh along the pelt — the spine is the pelt's strongest
   streamline, the ribs its cross-currents.
- **Choreography** enters and leaves along field lines (§4) — matter arrives with the grain,
   so even an arrival explains itself.
- **Flow edges** dock at a boundary along the local hair, so a curvy slide meets its cell
   like a tangent, never a collision.

> `%Scope` furniture (c-side on the holder cell): `layout:` (fold | slope | mesh | wedge |
>  ring | manual — which solver owns it), `shape:` (from the catalogue), `pelt:` (the combed
>   field — sampled hairs `{at, dir, strength}`, combed by the solver at solve time, read by
>    projection/text/mesh/choreography/flow-docking), `envelope` (area demand, shape
>     preference, min text size), `solved` (local positions + local settle).  Projection =
>      field-guided lay-down, gentle warp allowed for molds, never applied to glyph
>       geometry.  All c-side view matter; Books stay Voro-blind.

## 6. Semantic space — when position IS meaning

"Seed from live positions" undersold what live positions *are*.  In this app a position can
 be model semantics: the shuffle-slope-queue — Piers or their Mags arranged on a slope where
  height means how much to select, or what plays first — is a layout in which **geometry is
   the value**.  So every scope declares who owns its positions:

- **Layout-owned**: the solver places things; positions are view matter (most scopes).
- **Meaning-owned**: the model places things and *reads them back* — a **%Slope** scope maps
   a model weight to position, and dragging a Mag up the slope writes the weight.  The glass
    becomes an instrument: arranging the queue is playing it.

Edges split into two castes with opposite rendering doctrines:

- **%Flow** — meaning-bearing relations: data flows (a pull streaming chunks, a cast going
   out, a suggestion arriving), affinities, conveyances.  Drawn loud and beautiful: the curvy
    stretch-slides, animated along their length, foreground vector work.  The Radios toplevel
     gets wired with these — the flows between organs *are* its visual.
- **%Frame** — layout-systemising relations: containment stand-ins, alignment, the solver's
   own scaffolding.  Drawn like the long straight lines on old maps — faint, straight,
    receding, present enough to explain the geometry and never louder than that.

**Bunching — when the pull is allowed to mean something.**  A Relate edge (same Artist,
 played-together, co-heisted) is also an *attraction* the solver honors.  Pull things close
  enough and the layout layer comes to know them as **neighbours** — the adjacency exists at
   the graphics solving layer, where vtuffing reads it like any other.  And neighbourhood,
    where it is determined they can, unlocks **shared expression**: the bunch factors its
     common bits and says them once — *Artist* written a single time across the group, the
      way the snap encoding factors a common prefix.  The glass has been imitating the
       snap-like encoding, badly sometimes; bunching is where the visual stops imitating and
        **transfigures** it — two dimensions let a bunch share bits-of-expression that the
         linear snap has to repeat per row.

> the chain, explicitly: Relate mints the edge → the solver honors it as attraction →
>  proximity becomes tessellation adjacency (the neighbour relation is now a fact the
>   vtuffing/overlay solving layer can read) → homogeneity is checked (the Repli_crush
>    instinct: only factor what is truly common) → Express writes the shared bits ONCE for
>     the **%Bunch**, each member keeping only its differences → un-bunching reverses
>      without blink: the shared crest splits back into members' own labels as they part.
>       The flight-latch (§3) covers bunch|unbunch like any membership decision.

And more edges should exist: the **Relate** organ derives %Flow edges from meaning — c-side,
 spool-visible, entirely view matter.  Generating relation from meaning is something the
  glass should do more of, not less; Relate is where that appetite lives.

## 7. Express — the channel bindings

The generalisation of `dose drives area`, and of Matstyle's auto-swatch instinct: **Express**
 owns declared bindings from model quantities to visual channels.

> binding: `%Express` rows under The/Styles-like furniture — `from:` (an sc key or derived
>  quantity), `to:` (area | weight | hue | saturation | z | blur | fg/bg | motion-amplitude |
>   edge-loudness), `curve:` (lin | log | sqrt | band), `range:`.  Background|foreground is a
>    first-class channel: systemic matter recedes (blur/desaturate/thin), meaningful matter
>     advances — the map-lines doctrine of §6 is an Express binding on the %Frame caste, and
>      a %Bunch's shared crest is Express writing factored bits once.  All of it feeds an
>       SVG-native renderer: real strokes, filters, gradients along %Flow paths — the vector
>        look is a consequence of channels being declared rather than hand-painted per case.

## 8. The Spool — moments, the o-mark, blessing

The yore ring stands as designed: moments captured at settle, ring of ~60, drop-oldest,
 freeze on run-fail, snap payload diffable in the Storui machinery (the encoder is `snap_H`
  — the same ref pass the fixtures come from, NOT enWaft, which turned out to be the Waft
   codec; the workingout caught it), seek is display-only,
  pips lock to `step_n`, the scrubber walks `yore_n` — spools are clocks with quantize-locks,
   not lists.

Keeping a moment is a ladder with three rungs, each cheaper than the last:

- **Tags** — free words stuck to a tick.  Cheap, plural, disposable.
- **The o-mark** — *we saw it.*  Point at a moment (in the strip, or at the present settle)
   and mark it `o`: it is kept — exempt from drop-oldest — with nothing typed.  The default
    capture, like `What:$name` with the name left to default.  Another tap lets it go.  A
     generous cap keeps o-marks from silently becoming a second unbounded ring.
- **Blessing** — the human's act, like the declare door: the moment is named, given a
   sentence (no commas — em-dashes; the assertion sentence laws apply), pointed
    `%Assertion`-style at what it is mainly about with the microsnap idiom.  A blessed
     **landmark** is a state we might see again — so it is watchable-for: a Situation (§9)
      can be armed from it ("tell me when the glass is substantially here again", judged by
       snap nearness), and the sighting pins its own moment as evidence.

> the row (in `w:Vyto`, off-snap as ever): tags as sc words; `o:1` for the mark (absent,
>  never 0 — the snapped-boolean law even off-snap, for habit's sake); blessing adds
>   `bless:<name>`, `sentence:`, `.c.microsnap`.  The strip renders o-marks as small held
>    dots and blessings as anchored marks (the pip-diamond idiom); seek-to-landmark is one
>     click; the landmark-hold (§3) governs display while parked there.

## 9. The board — the glass handled

There is no third ghost.  ("Zyto" was a slip of the tongue and is struck from the
 dictionary.)  The glass needs a place to be *handled*, and that place is part of the glass
  itself: **the board** — a bar of one-word buttons, and a panel behind it, rendered by Vytui
   like any other face.

**The bar.**  About seven buttons.  Each is one coherent word, each toggles one visible
 doctrine, and the rule that keeps the bar honest is: if a toggle cannot earn a single
  dictionary word, it cannot be on the bar.  No glyph mystery-meat — what ▦ was becomes a
   word too.  The opening seven:

> **live** — follow the newest settle | parked where you are (the landmark-hold).
> **depths** — ▦'s successor: show this scope's innards as notation rows instead of space.
> **flows** — show | hush the loud edge caste.
> **frames** — show | hush the quiet one.
> **holds** — paint every Hold and which organ placed it.
> **pelt** — comb the hair-field visible: the fur of the glass.
> **o** — the o-mark: keep this moment, nothing typed (§8).

**The panel.**  Behind the bar sit the organs, one row each: what it reads, what it decides,
 what it writes; its few dials; its current status.  Organs declare their links — what they
  grapple, what they feed — and because organs and links are particles, the panel can be
   rendered by a small glass: the machine seen in its own matter.

Each organ in one sentence, in one consistent guts-language (*reads → decides → writes*):

> **Scan** reads the grapples' worlds and writes the mirror.
> **Fold** reads the mirror and decides which subtrees become one cell.
> **Gang** reads a crowded sibling row and decides who is represented by whom.
> **Slope** reads a weight and writes a position — and reads the position back as the weight.
> **Mesh** reads a family and writes a dot-body with a spine.
> **Calm** reads everything in flight and decides what may move.
> **Focus** reads attention and decides what matters now.
> **Relate** reads meaning and writes %Flow edges.
> **Express** reads quantities and writes channels.
> **Spool** reads settles and writes moments.

They fall into four families: **solvers** (Fold, Gang, Slope, Mesh — each can own a scope's
 layout), **governors** (Calm, Focus — they place nothing; they permit), **scribes** (Relate,
  Express — meaning into visible matter), **chroniclers** (Scan, Spool — capture in, capture
   out).

**Situations.**  A Situation is a standing sentence about a state of the glass worth
 noticing: *membership flipped twice within one settle* — *an overlay moved while held* —
  *the glass is substantially at landmark <name> again*.  The glass checks its Situations as
   it settles; a match mints a **%Sighting**, which pins the current moment as evidence.
    Where an Assertion swears once and gates a run, a Situation watches always and gates
     nothing — it collects.  Sightings queue on the board with a badge; opening one lands in
      the diff panel with its pinned moment.  The first Situations to write are our own
       former bugs — the pathologies watched-for are the regression suite the glass carries
        with it, alive.

## 10. The commission and the grapple

`watch_c(Scannable)` was aimed one joint too high.  The state that *feeds* the Scannable
 lives in bits of gear — stokers, lineups, piers, ledgers — and the Scannable is assembled
  from them (it will `.r()`).  So Vyto watches **the gear**, and the commission is where it
   learns what the gear is:

- **Plain form**: the commission hands a ready `Scannable` (+ `Styles`, `client_w`) and an
   explicit grapple list — the source Cs to watch.  Default, if no list: watch the Scannable
    itself, the degenerate case that still beats today's nothing.
- **Recipe form**: the commission expresses *how to make* the Scannable — a bundle of
   **IOexpr**s, each naming a source and a shaping, landing in the **Sunpit**, the staging
    container where the poured-in sources assemble into the Scannable.  Because the recipe
     names its sources, Vyto derives the grapple set transitively — *a grapple on what it
      has a grapple on* — and `watch_c`'s the whole complicated bunch of input.
      Radio-protocol specifics ride here naturally: the Radio commissions with a recipe
       ("my stoker's stock, these piers' Mags shaped as a slope, the trickle's presence"),
        and the watching follows from the saying.

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
    SVG/DOM cells, faces as children, the viewport, the board.  Home: `Ghost/V/Vyto.g` beside
     Voro.g, CREDULER_GHOSTS + overlay, ghost-compiled like family.

The build starts **high-level first**: the opening milestone writes Vyto.g's skeleton with
 the organs, furniture and dictionary words as named stubs (the board listing them from day
  one), so the vocabulary exists *in the workings* before any rendering is attempted, and
   the words get worn in while they're still cheap to rename.

## 12. The moult

(Previously "the strangler plan" — the human vetoed the name, rightly.  Wrong picture: not a
 fig throttling a host tree, but a body that grew its new skin inside the old one and sheds
  the carapace whole.)

- **v1 refuses**: takeTurns, ceremony flags on the commission, cytowave snapping, headless
   anything, relayout-from-nothing.
- **First tenant**: one Radio world on BigSoundland end-to-end — recipe commission, grapple
   watch, spool, strip, Calm with the pointer-hold, one %Slope.  Fixes "not responding
    later" where it hurts most; hands the abdomen to the reality that should invent it.
- **What hardens while the new skin grows**: Cyto.svelte + Cytui.svelte, maintenance only.
   Voro.g lives on as the Fold organ (and lends Gang, and its drift knowledge to Focus).
- **On "unexpressible"**: expressibility of *intent* goes up — more can be said (holds,
   shifts, slopes, pelts, situations).  What goes down is the expressibility of *failure*:
    Vyto has no relayout-from-nothing, so the diagonal-and-spring cannot be written; no wave
     queue, so the vanishing loop cannot be hosted.  We are not porting those bugs' fixes —
      we are removing the vocabulary they were written in.
- **The shed**, so "supersede" has a definition of done: Storui's seek needs the
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
     settle, the ring freezes on fail, a shift-hold really held — and the overlay-hopped
      Situation is *itself* that assertion: the diagnostics and the tests are one
       vocabulary.  The glass swears with `story_swear` like everyone else; "the glass
        settled — every cell at rest" is a natural first sentence.

## 14. Dictionary — the words we are coining

Gathered so they can be preened *before* hardening into mainkeys.  Mainkey candidates need
 the usual uniqueness check against the fleet before first mint.  ("Zyto" is struck — a slip
  of the tongue for Vyto; the board is part of the glass, not a third thing.)

**The things:**

| word | kind | proposed meaning |
|---|---|---|
| **Vyto** | ghost (.g) | the model side of the new glass: organs, scopes, spool, commission |
| **Vytui** | ghost (.svelte) | the render side: DOM/SVG cells, faces as children, viewport, the board |
| **the board** | face | the glass handled: the bar of one-word toggles + the organ panel |
| **%Hold** | particle | one composable claim of stillness (scope × channels × strength × while) |
| **%Settle** | tick | the settled-flip signal; capture, ceremony and telemetry all read it |
| **shift** | transaction | one focus change: collect → hold → choreograph → settle → moment |
| **%Scope** | particle | a cell's local world: own solver, own settle, envelope to the parent |
| **envelope** | value | what a parent sees of a scope: area demand + shape preference |
| **the catalogue** | closed set | cell · slab · band · wedge · ring · mold · body (§5; a new shape is a spec event) |
| **pelt / hair** | field | tiny oriented samples over a cell's interior; one hair is nothing — together they are the field; solvers comb, everything else reads |
| **%Slope** | scope-solver | meaning-owned positions: geometry is the value (the shuffle-slope-queue) |
| **%Flow** | edge caste | meaning-bearing relation: loud, curvy, animated |
| **%Frame** | edge caste | layout-systemising relation: faint, straight, receding (old-map lines) |
| **%Bunch** | particle | an adjacency cluster allowed to factor its common expression, said once |
| **%Moment** | particle | one capture: yore_n, step_n lock, snap_H payload, tags |
| **o (the o-mark)** | tag/act | *we saw it*: point, mark, kept — nothing typed (a default `What:$name`) |
| **bless / landmark** | act / particle | the human promotes a moment: named, unforgettable, pointed at its subject |
| **%Situation** | particle | a standing sentence watched for — Assertion's run-agnostic sibling |
| **%Sighting** | particle | one recognition by a Situation, pinning a moment as evidence |
| **Sunpit** | container | staging pit where a recipe's sources pour in and assemble the Scannable |
| **IOexpr** | value | one recipe line: name a source, shape it |
| **grapple** | verb/edge | Vyto's watch-hold on a source; transitively, on what the source grapples |
| **%Seek** | furniture | the seek state holder: open_at, live latch |
| **the moult** | plan | the supersession (§12): grow the new skin inside, shed the carapace whole |

**The organs** (one sentence each in §9; families — *solvers* place, *governors* permit,
 *scribes* translate, *chroniclers* capture):

| organ | family | sentence |
|---|---|---|
| **Scan** | chronicler | reads the grapples' worlds, writes the mirror |
| **Fold** | solver | reads the mirror, decides which subtrees become one cell |
| **Gang** | solver | reads a crowded sibling row, decides who represents whom |
| **Slope** | solver | reads a weight, writes a position — and back |
| **Mesh** | solver | reads a family, writes a dot-body with a spine |
| **Calm** | governor | reads everything in flight, decides what may move |
| **Focus** | governor | reads attention, decides what matters now |
| **Relate** | scribe | reads meaning, writes %Flow edges |
| **Express** | scribe | reads quantities, writes channels |
| **Spool** | chronicler | reads settles, writes moments |

**The bar words** (each toggles one visible doctrine; a toggle that can't earn a word can't
 be on the bar): **live · depths · flows · frames · holds · pelt · o** — where **depths** is
  ▦'s successor: this scope's innards as notation rows instead of space.
