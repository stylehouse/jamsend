# Electrode_todo.md — runtime call-flow tracing: both ends of every call, reduced to a picture

A **capture doc, not yet a plan** (the `Atheory_todo`/`Trust_todo` pattern — an itch given an address).
 The owner, 2026-09-07/08:

- *"we'll need a way to bundle different versions of the bunch of code we're incorporating into some
   hypothetical runtime, which is runners or so, so we can inject lots of electrodes to log a picture of
    our entrance|exit at every call... or branch... so we can graph the flows through the code."*
- *"knowing what's hanging would be sweet... due to async everything won't stack nice on its own... this
   must be well-researched though."*
- On the three decisions below: *"however you want to start it, start simple I guess... I actually want
   both ends of the calls... to have the edges"* · *"push to an array? as probing gets more complex it
    may want reducing outside of Runtime into some C\*\* structure, probably of methods, maybe intensity
     of certain calls between"*.

## 0. What to get on with next

**BUILT 2026-09-08 night — `Ghost/L/Electrode.g` stands on the live runner.**  The plan below was
 followed with one addition: a ring alone loses edges past its cap, so beside the ring (the film strip)
  there is a LOSSLESS tally — one Map increment per call, keyed caller→callee — and it is the tally the
   reduce folds into particles.  Three runtime objects on `top_House().c.electrode`: `ring`, `tally`,
    `open` (the hang list, a set).  The reduce lands `w:Electrode/%Graph,dontSnap/%Method:<name>,n,ms/
     %Flow,of:<callee>,n,ms,max` (`%Flow` not `%Edge` — Swarm owns `%Edge`).  Arm/disarm coat and uncoat
      every function in the ghost bag (`top.ghosts`), the raw kept on the coat as `__electrode`; off by
       default.  CLI: `runner_ask electrode [top|arm|disarm|reset|reduce|hangs|film]`.  Book:
        `Ghost/L/Electrodation.g` → `ElectrodeStaple` (6 beats) — GREEN 2026-09-08: recorded 6/6, contract of
         10 installed, check-mode ×2 at `caveat:0`, 10/10 sworn, 0 gaps.  Sabotage owed at the next
          runner-reload boundary (an already-imported `.go` needs a reload to re-import).
         First live numbers + what they already say: **`Wordland_todo.md §4`** (the land doc is where the
          three L instruments are read together; this doc stays the tap's own).

**Also built the same night:** `Electrode_join` (`runner_ask electrode join`) — declared (Atlas `call,via`)
 vs measured (the tally) over the ghost bag; its first run found an Atlas collector gap (the cast form
  `(H as any).X(`, fixed in `compile.ts`, `ATLAS_MAPPER m12`).  And `ghost_load Ghost/L/X.g --swap`, so a
   recompiled L ghost takes on a live tab without a reload (the sabotage road).  Both in `Wordland_todo §4c`.

### ⏸ PARKED by the owner, 2026-09-08, after reading the above

*"we should keep teetering around with other bits before innovating further… since it's all leading to
 integration… we can leave it off for the moment? and play with it via the upcoming Atlas, perhaps?"*

**So: LEAVE IT OFF.  Do not extend the tap; use it.**  It ships disarmed, it is one method call to arm,
 and the next contact with it should be through Atlas — the join (`electrode join`), and the area
  switches §2 describes — not through more tracing machinery.  The reason is the owner's, and it is the
   right one: everything here converges on Atheory, and building the deep half before the bundle shape
    exists would be building it twice.

**Two corrections the owner asked for, both worth carrying forward** (they expected something heavier
 than what was built):
- **Nothing recompiles.**  Arming does not switch a dialect, emit a variant, or write a `.go`.  It
   replaces each entry of the flat function bag with a closure over the original and puts the originals
    back on disarm — milliseconds for 3,595 methods, disk untouched.  That is *why* it could be armed on
     a live tab mid-session.
- **It is already per-process.**  The state hangs off one tab's top House, so two tabs are independent
   and a reload clears it.  The per-runner granularity the owner asked about is what it already has, by
    construction rather than by design.
- And **the CLI is one door, not the design.**  `Electrode_arm(w)` is an ordinary House method; an
   editor button is a few lines.  The owner: *"I wasn't expecting to run this command to switch it on or
    off, I think it'd all be controlled from the editor, at least for me."*  Owed whenever the room grows
     a place for it (`Wordland_todo §5`).

Held, in order, for when it is picked up again: (1) fold at the Story step seam (a per-step picture for
 every Book); (2) area switches (§2); (3) real async-context attribution — `∅` (detached) dominates the
  by-time list because every belief-loop continuation is one, and only a frame id threaded through the
   dispatch fixes that; (4) the compiler tap for BRANCHES (§1); (5) measure the armed overhead (§3).

## 1. Two kinds of electrode — and only one of them needs Atheory

The owner expected electrodes to depend on Atheory *"spreading out the includable space for them, so we
 can have the cluster on a stable version more easily, and isolate changes in a particular A, even if
  overwriting the methods from some base ghostbundle."*  That instinct is right, and it applies to the
   half that is not built.  The split is the whole design, so say it once:

| | **call electrodes** — BUILT | **line/branch electrodes** — the destination |
|---|---|---|
| what they see | entry + exit of a method | every line, every branch taken, inside a body |
| how | a runtime wrapper around the bag entry | the compiler emits marks into the lowered body |
| cost to switch on | milliseconds, no compile, no disk | a genuinely different compiled ghost |
| needs Atheory? | **no** — a wrapper works from outside | **yes** — this IS the variant-bundle problem |

A wrapper cannot see inside a body; nothing outside one can.  So the deep version needs a second
 compiled form of a ghost living beside the first, selected per A — which is exactly
  `TheA_<Name>_<Variant>_<dige>` (`Atheory_todo`, "The shape").  **The variant slot is where an
   electroded build lives.**  That is the integration the owner means, and it is why this doc waits.

**Why the deep version is wanted, in the owner's own reason** (2026-09-08, and it is not a debugging
 reason): *"we totally want to trace all the way through every line in some cases, it'll be excellent
  for teaching the program's flow."*  A line-level trace of one real request is a program explaining
   itself — the same bet as the snap, pointed at execution instead of state.  Record that as the
    destination, because it changes what the deep version is FOR: a legible narrative of one flow, not a
     profiler's histogram.

## 2. Switching areas on and off — cheaper than it looks, via Atlas

The owner: *"we should have a global switch or switches turning on|off areas of electrodes, per process
 as well, while leaving them on for most of a development session."*  Per-process is already true (see
  above).  Per-AREA is not, and the obstacle is real but shallow:

**The bag has no provenance.**  `ghostsHaunt` merges every ghost's methods into one flat
 `{name: Function}` map with no record of which ghost each came from (the only per-ghost identity is the
  synthetic `Ghostmeta_<ghost>` version reader).  Today the only filter is `ELECTRODE_SKIP`, a regex over
   names.

**But Atlas knows.**  Every `%Doc/%Map/%def` row carries the method name AND the file it is defined in.
 So "arm only the transport" is a query against the census — `Doc:Ghost/N/*` → def names → coat only
  those — and needs no new bookkeeping anywhere.  This is a better argument for Atlas and Electrode
   sharing a directory than the one written in `Wordland_todo §1`: the static census is what makes the
    dynamic tap selective.
 Second, cheaper source if Atlas is not standing: capture provenance AT `eatfunc` time (the hash arrives
  per-ghost, before the merge) into a `name → ghost` map on `.c`.  Two lines in `ghostsHaunt`, and it
   would serve the Atheory manifest work too, which needs exactly this fact.  Not built; noted because it
    is the kind of thing that gets re-derived three times.

## 3. What "hanging" the built version can and cannot tell you

The owner asked, of the built half: *"and can detect hanging inside asyncs?"*  Precisely:

- **YES for a hanging async CALL.**  An async method's frame opens on entry and closes only when its
   returned promise settles, so anything still pending is in the open set with its age.  `electrode
    hangs --older=1000` is that list, oldest first.  A sworn beat proves both directions (the frame is
     open across the await; it closes on settle) and a third proves a throw still closes it.
- **YES for the chain of coated frames.**  If a hanging method is itself waiting on another ghost
   method, both frames are open, so you get the stack that a stack trace cannot give you after an await.
- **NOT which line inside the body.**  Between two coated calls the tap is blind: a raw `fetch`, a
   `setTimeout`, an uncoated closure.  Line-level is §1's job.
- **And the open set is a SET, not a stack** — interleaved async legs do not nest, so oldest-open is the
   hang, and no tree should be reconstructed from it.

## 4. Unmeasured: the armed overhead

Books run green and correct while armed (`AtlasStaple` at `caveat:0` both ways, four Books in a sweep),
 so it is not disruptive.  But **armed-vs-unarmed wall clock was never measured** on the same work, and
  the owner's *"leaving them on for most of a development session"* is exactly the question that needs
   it.  ~20 minutes: run one Book ×3 each way on an idle runner, compare step durations.  Do that before
    anyone leaves it on by default.

**Do not build a new ring.  One already exists and is the right shape.**  `Radio_trace`
 (`Ghost/M/Radio.g:101`) is a capped ring of tiny `{t, ev, id, …}` marks on the top House
  (`M.c.supply_trace`, cap 1200, overridable via `M.c.supply_trace_cap`), always-on because the objects
   are tiny, off-snap by doctrine, surfaced by `runner_ask world` **which already computes inter-event
    deltas**.  The owner's *"push to an array?"* is that array.  What does not exist is the REDUCE.

So the first cut is two pieces, and only the second is new machinery:
1. **A call ring** — the same idiom, its own ring, entry and exit marks carrying the method name.
2. **A reducer** — fold the ring into a `C**` structure: a particle per method, an edge per
    caller→callee pair, intensity as a count on the edge.  This is the part the owner names as wanting
     to live *"outside of Runtime"*, i.e. not computed per-call but folded at a seam.

## The decisions, ruled by the owner 2026-09-08

| question | ruling |
|---|---|
| entry only, or both ends? | **BOTH ENDS** — the edges are the point, not the counts |
| where do marks live mid-run? | **an array** (the capped ring), not particles per call |
| where does structure come from? | a **reduce** into `C**` afterwards — methods, and intensity between them |
| compiler or runtime tap? | *"however you want to start it, start simple"* — open |

**Why both ends is the load-bearing half.**  An edge needs a caller, and the caller is whatever frame is
 still open when the callee is entered.  Entry-only gives counts; entry+exit gives the graph *and*
  answers "what is hanging" — the set of frames still open, oldest first.

## What "hanging" can and cannot be, here

The owner is right that async will not stack on its own: every `await` breaks the synchronous stack, so
 there is no call stack to read at the moment of a hang.  Two things follow.

- **The structure is a SET, not a stack.**  Interleaved async legs do not nest, so the honest shape is
   a set of open frames each with a start time; the oldest open frame is the hang.  Do not try to
    reconstruct a tree from it — that needs real async-context propagation (Node's `AsyncLocalStorage` /
     `async_hooks` exist for exactly this; a browser tab has no equivalent without threading a context
      by hand).  For "what has been open for 30 seconds" the flat set is sufficient.
- **This machine already has a hang primitive, and it is the `req`.**  `Coding_guide`: a HOLD is an
   unfinished req, and Story cannot snap while one stands; `history/Reqdrop §0`: *"leave in the snap only
    the reqs whose in-flight state is worth SEEING"*.  So at quiescence the standing reqs ARE the hang
     list, and they already snap.  **The gap the electrodes fill is detached work** — an `expecting()`
      async_fn, a floating promise, a leg returning via `reqyoncile` — which is in flight with no req
       standing for it, and is exactly where a hang hides invisibly today.

## Constraints inherited from the corpus

- **Never a particle per call.**  A tap fires thousands of times a second; minting per call would thump
   the belief loop and bloat the world — the `.c`-foam complaint in another coat.  The ring is `.c`
    (a vanishing, rightly interior per `Statehome`); the REDUCED picture is particles, and only that.
- **Fold at a seam**, not per tick — the end of a Story step is the natural one, matching how
   `story_harvest_sworn` moves evidence before the encode.
- **Off by default.**  `Radio_trace` earns always-on by being tiny; a per-call tap is a different order
   of volume, so it wants a flag, and a normal build should carry nothing.
- The console-echo lesson is already paid in `Radio_trace`: the ring is silent by doctrine, echoing only
   a small `SPEAK` set and only on a humdinger, *"so this can never become the 2026-08-06 burn"*.

## Open

- **Compiler or runtime tap.**  The `.g` compiler can emit a mark at each lowered method and is the only
   thing that can see BRANCHES (which the owner also wants); a runtime wrapper at `ghostsHaunt` needs no
    compiler change and covers hand-written `.svelte` methods too, but sees calls only.  Unruled.
- **What the reduced `C**` looks like** — a `%Method` per name with `%calls,of:<callee>,n:` edges is the
   obvious first shape, and it lands straight into Cyto/Matstyle (which style by mainkey) and beside the
    Atlas static call graph, which already holds `call` rows with `via` — so a measured edge and a
     declared edge could be compared. That comparison is probably the actual prize.
- Its relation to `Atheory_todo`'s `TheA_<dige>` bundles: the owner's original framing tied electrodes to
   bundling *versions* of code into a runtime, so a mark may want to carry which bundle it came from.
