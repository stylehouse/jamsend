# Story — future directions

Design notes for the Story runner|snap machinery. Not built; each section is a build-ready sketch,
 not a promise. Grounded in the live code as of 2026-07-05 — correct anything that has since drifted.

---

## 1 — The %see-everywhere sweep (surface every observation under a world, not just `w/%log`)

### The itch

A Book emits observations to say "here is what just became true." Two kinds exist:

- **`%log`** — persists on the particle until Story comes along and folds it into the step's notes.
- **`%see:'sentence'`** — a **once-noticed** self-describing claim (the successor to the `%witnessed:N`
   latch — see `see-assertion-layer`). It is a *per-beat emission*, not state: it **drops** after its
    step, deliberately, so it can never accumulate into the `%witnessed` noise-drift it replaced
     (`see-is-not-a-latch` — "they drop for a reason").

The gap the generator surfaced: **an observation emitted *deep* in the world tree is not surfaced.**
 Story reliably harvests observations at the shallow, expected spots — but a `%see` (or any emission)
  hanging off `w/*`'s grandchildren, or buried inside a `req**` subtree, isn't collected. It flashes for
   one beat in the live world and is gone before the snap notices. In the generator's words: *"we don't
    actually %see every %see in a `w/*` or `w/req**`, but we should — only `w/%log` hangs around until
     Story comes along."*

So an author who wants to report progress from inside a req (the natural place — that's where the work
 runs) has no reliable channel. They fall back to stamping a durable `sc` key on `w` (e.g. the
  generator's old `generated=8` + `wav:` children, now `%file_written:<name>` markers) purely so the
   snap can *see* it. That works, but it conflates "an emission I want surfaced" with "durable world
    state the fixture gates on." The two should not be the same thing.

### The principle

**A `%see` is an emission, like a log line — not a state, like a key.** The bug is not that it drops;
 dropping is correct. The bug is that *the harvest is shallow*. Fix the harvest, not the lifetime.

Concretely: the collection of emissions should be **decoupled from the emission site.** It should not
 matter whether a `%see` is stamped on `w` directly, three children down, or inside a `req**` that is
  mid-`await`. If it is anywhere in the world's subtree at the beat the step snaps, Story should notice
   it, record it into that step's notes, and then let the live emission drop as it always has.

### The design — a per-beat seen-sweep

Story already does a **ref pass** over the world when it builds a step (`snap_step` → `snap_H`; the
 traced `beliefs()` phase; notes land under `The/Steps/<n>`). That pass is the natural — and only right —
  place to harvest.

Add a **seen-sweep** to that pass:

1. **Walk the whole subtree.** `Travel` the world `w` depth-first — through `w/*`, their descendants,
    and *into* `req**` subtrees (the sweep must not stop at a req boundary; a req is where work runs, so
     it is where observations are born). This is the same depth-first primitive the encoders already use.

2. **Harvest every emission.** At each node, collect any `%see` (and, if we unify, any `%log`). Key each
    by `(emission-text)` so a claim emitted from two beats running is one entry per beat, not two.

3. **Record into the step's notes.** Fold the harvest into `The/Steps/<n>` — a `seen:` bucket beside the
    existing note channels. This is the durable residue: *the step remembers what was seen at it.* The
     snap-fixture diff then gates on the seen-set for that step, exactly as it gates on `%log` today.

4. **Let the live emission drop.** After the harvest, the live `%see` on the particle expires on its
    normal schedule. Nothing accumulates in the *world*; the only durable trace is in the *step record*,
     which is where durable trace belongs. This is the whole point — surface without hoarding.

The shape to keep in mind: **`%see` is to a step's `seen:` note as a `console.log` is to a captured test
 log.** The program emits freely, wherever the work is; the harness collects at a fixed point and files
  it under the run. The emission site is free; the collection site is fixed.

### Semantics & edge cases

- **No accumulation across beats.** The sweep files each beat's harvest under *that beat's* step. A claim
   true for five beats appears in five step records, not as a growing pile on `w`. Same discipline as
    `%see` today, just harvested from everywhere.
- **A req mid-`await`.** An emission stamped inside a req whose `do_fn` is suspended on a promise is still
   a live child of the tree at snap time, so the Travel sweep sees it. (This is exactly the generator
    case: the writes are in flight under `req:gen_testsounds`; a `%see` there would otherwise vanish.)
- **Dedup within a beat.** Two subtrees emitting the same sentence in one beat → one `seen:` entry. Key on
   text; the sentence is the identity (it already forbids commas — the peel parser splits on them).
- **`dige` interaction.** The seen-set feeds change-sensitivity like any note: a step whose seen-set is
   unchanged from the recorded fixture is not "interesting" and needn't re-emit. Don't let the sweep
    inflate `dige` churn — an emission that recurs identically every beat is *not* a change.
- **Ordering.** Record in Travel (tree) order, stable, so the fixture diff is deterministic.
- **Cost.** One extra depth-first walk per step snap. Story already walks the tree for `snap_H`; fold the
   harvest into that existing walk rather than adding a second pass.

### Why not just make `%see` durable

Because that is the `%witnessed`-latch anti-pattern reborn: durable observation keys pile up on the world,
 every one a permanent fixture obligation, and the snap fills with stale "still true" noise. `%see` drops
  on purpose. The seen-sweep keeps the drop and moves the *memory* to the step record, which is bounded
   (one per step) and is the correct home for "what was true when."

### Relationship to the `%file_written` stopgap

`Musu_gen_testsounds` currently stamps a throwaway `%file_written:<name>` on `w` as each write lands. That
 is the shallow, durable-key workaround the seen-sweep is meant to retire: today the marker must live on
  `w` (a shallow, snappable spot) and be a real child; with the sweep, the generator could instead emit a
   `%see:'wrote <name>'` from *inside* `req:gen_testsounds` where the write actually completes, and the
    sweep would surface it. Until the sweep exists, `%file_written` is the honest stand-in — keep it.

### Phased build

1. **Harvest read-only.** Add the subtree `%see` sweep to `snap_H`, write the `seen:` bucket into
    `The/Steps/<n>`, change nothing about emission or lifetime. Prove it on a Book that emits a `%see`
     inside a `req` (a deliberate probe) and confirm it lands in the step record where a shallow emission
      already does. This is isolated and reversible — the right way to touch core (`fight-back-on-core-changes`).
2. **Unify `%log`.** If the sweep is sound, fold `%log` collection into it — one harvest, two emission
    kinds — and retire the bespoke `%log` path.
3. **Retire the stopgaps.** Move `%file_written` (and similar shallow-durable-key visibility hacks) to
    in-req `%see`, delete the durable markers, re-record the fixtures live.

### Open questions

- Does the seen-set belong in `The/Steps/<n>` proper, or in the `got_snap` beside the world state? The
   former makes it a first-class note; the latter keeps it nearer the raw capture.
- Should the sweep descend into *off-pump* subtrees, or only the snapped tree? (Snap inclusion is
   reachability in `H**`; an emission off-pump is invisible to the snap anyway — probably out of scope.)
- Multi-run churn: a held/swept run's seen-set vs a fresh run's — reconcile like the rest of the run
   record (`storyrun-run-record`), or leave per-run.
