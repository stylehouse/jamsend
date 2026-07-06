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

---

## 2 — High-frequency "snappings" + an in-flight console

*(Moved here from `Perf_todo.md` 2026-07-06 — it is a Story-runner observation feature, not a perf lever.
 Its first piece, the `reactap` reactivity census, has landed; see `Perf_todo.md`'s Status log + the
  `reactap-reactivity-census` memory.)*

A second, opt-in cadence *beside* the Story-step snap: **super-intensely-often snappings** on any system we
 designate — e.g. taken **between event handlings**, armed **once some designated C\*\* exists** — that you
  can **remote into and look at + manipulate** the live editor via an **in-flight Story console**.

Why it belongs to the Story machinery: today the only structured snap of the C tree is the between-steps
 Story snap (`snap_H`/`story_snap`, `Story.svelte:1071`), which is a full-tree Travel+encode — too heavy and
  too coarse to fire between event handlers. The want is a *lighter, denser* observation track: a scoped snap
   (a subtree, not all of H) fired at a fine cadence on nominated systems, cheap enough to run between
    handlings without becoming a per-pass tax (the §3-shaped tax in `Perf_todo.md`).

Design constraints it must respect:
- **Scoped, not whole-tree.** Snap only the designated C\*\* subtree (Travel from a named root), never all of
   H — else it becomes another O(N)-per-beat tax.
- **Off the snap pump.** The observations are diagnostic; they ride `.c`/`H.ave` (like Cyto's `source_n`, like
   run pins), never `.sc` — no encode cost, no snap pollution.
- **Armed by presence, gated to designated systems.** "Once some C\*\* exists" = arm when a marker particle is
   present; "any system we designate" = an explicit opt-in flag per w/host, not global. Default off.
- **Between-handlings cadence, not per-tick.** Hook the observation to the event-handling boundary (the
   `answer_calls` drain edge), not the 3 s heartbeat — this is the "intensely often" the Story-step snap can't
    give.
- **Remote + manipulable.** The console rides the same `/relay` websocket the editor/runner already share
   (`runner_ask.mjs` is the request/reply precedent); it should both *read* the dense snap stream and *inject*
    mutations (an in-flight REPL against the live world), the interactive twin of `story_repl.mjs`.

Open questions:
- Cadence knob: per-handling vs. a fine timer (sub-heartbeat) vs. change-gated on the designated subtree's
   version.
- Retention: a ring buffer of the last N dense snaps (cf. the run-pin `KEEP` cap, `LiesFunk.svelte:1324`) so
   you can scrub, not just see now.
- Where the console mounts: a Lens/Brink face (the ambient dock layer) vs. a separate remote surface.
- Cost ceiling: a hard cap + a `log()` when it drops, so the observation track can never itself become the
   sluggishness it's meant to diagnose.

---

## 3 — Collapsing the elvisto hop chain (observe → collapse)

*(The "longer game" lever #5 from `Perf_todo.md`, examined here because its instrument is §2's observation
 track — the arc is one thing: **observe densely → reconstruct the slow chain → collapse it**.)*

### The floor being attacked

An edit→compile→run threads **~12-13 `i_elvisto` hops** (~8 compile + ~4-5 run), and each hop pays a full
 `ANSWER_CALLS_TICK_MS` = **50 ms** (`Housing.svelte.ts:20`). A logically-instant chain therefore pays
  `N × 50 ms` ≈ 0.6-1 s of pure latency floor before *any* O(N) work. Worse, each hop is also a separate
   `beliefs()` pass — so it drags the four unconditional O(N) tree-walks (`Perf_todo.md` §3) along with it.
    **Collapsing the chain is the only lever that attacks both floors at once:** kill the 50 ms × N *and* the
     per-pass O(N) × N.

### The two things in the drain, kept apart

1. **The "one pass later" is a correctness deferral, not the 50 ms.** `i_elvisto` builds `e` immediately but
    pushes it to the todo only at **UItime** (`this.clear(async … _push_todo(e))`, `Housing.svelte.ts:579-583`)
     — so the scheduler's mutations land before the target runs. This deferral is *load-bearing* and must
      survive any collapse.
2. **The 50 ms is a separate throttle.** `answer_calls` shifts ONE item, processes it under the beliefs mutex,
    then `setTimeout(…, 50 ms)` before it re-fires on the next `todo_version` bump (`:817-824`, drain at `:836`).
     This gap exists so "rapid-fire todo pushes don't pile up" and to yield to the browser — it is **not** a
      correctness barrier. It is the collapsible part.

### The trigger isn't causality — it's *gallop confidence*

Field observation: during a settle the todo doesn't hold a tidy causal chain one hop at a time — it holds
 **20-40 elvises churning for a while, earlier ones replacing themselves** (the `while todo[0]=='think'` merge
  at `:843` collapsing re-posted `think`s) as the machine rattles. That depth is not causal fan-out; it is the
   **trickle re-arm** (every waiting req's own 150 ms `think` poke, `Perf_todo.md` §2) plus the **eternal
    re-arm** (`sc.ok` cleared every pass so eternal reqs re-run, §4) piling up. So the earlier framing — "you
     can't see a serial chain in the queue" — is a red herring for the real workload: **you don't need to prove
      a causal relation.** When the queue is deep and sustained and nothing is painting, you are *convinced you
       are galloping*, and every one of those pokes is "make progress" work you may as well drain flat-out.
        Draining them one-per-50 ms is pure imposed latency on a machine that is visibly mid-settle.

### Technique A — gallop-tighten (queue-depth, causality-agnostic)

The blunt, general lever: watch todo depth over a window (a `reactap` sibling — `reactap` already measures the
 bump churn, the sister signal). When it's **deep + sustained** (clearly settling) switch the drain from
  50 ms-gated to **greedy to a wall-clock budget** (drain back-to-back, then yield to paint), and relax back to
   the 50 ms gate the moment it drains shallow. No per-edge marking, no chain reconstruction — just "we're
    rattling hard, drain it." The UItime deferral (1) still runs between items, so correctness holds; you only
     stop paying wall-clock you were spending to protect a paint that isn't happening anyway.

### Technique B — finish → re-pump the upper req (poll becomes event)

The structural lever, aimed at the Lies stack's *depth* (`Perf_todo.md` §4: Store `maz:7` → Cortex `maz:5` →
 Codebit `maz:2` → Rundown `maz:1`). `do()` (`Stuff.svelte.ts:647`) descends multiple maz levels in one pass —
  **but halts the moment a level bows out on a ttlilt** (`level.some(needs_work) → return`). Re-entry from the
   top then waits for the next `think`, which today is driven by the **150 ms trickle**, not by the child. So
    each async level costs a trickle-quantum of latency: arm ttlilt → bow out → …150 ms…→ re-enter → descend
     one more level. Your idea: when the awaited inner req** **`finish()`es** (`:682`), have the finish itself
      **re-pump `do()` on the ancestor chain** immediately, instead of waiting for the poll. That turns §2's
       busy-poll and §4's one-level-per-pass into an **event-driven up-walk** — which is exactly `Perf_todo.md`
        lever #3 ("trickle → single-wake") seen from the req side: the gate-clearer re-pumps, so the trickle can
         retire to a bare safety fire. This is where the Lies+Lang speed-up you're picturing actually comes from
          — the deep stack stops paying 150 ms per level to notice its own children finishing.

### The governing constraint — the snap *wants* the gallop (your hesitation, promoted)

This is the real reason it was left loose, and it's correct to guard. The **ttlilt is the snap-timing advisor**,
 not just a pacer (`ttlilt-not-a-keepalive`, `ttlilt-in-snap-means-timeout`): the discrete pass-boundaries are
  what let Story — and the §2 dense track — watch the world settle in consistent, mutex-frozen states. Pull the
   gallop tight enough and the settle becomes one atomic jump: fast, but the intermediate states never become
    observable. The reconciliation, so speed and observability stop fighting over one clock:
- **The step-snap fires at *quiescence*, and quiescence is a trailing-edge timeout — not a pass count.**
   `poll_step` (`Story.svelte:1979-1982`) calls it quiescent when `Run.todo` is EMPTY **and** it's been
    `quiesce_snap_time` (~`TICK_MS × 1.5` ≈ 75 ms) since the last cycle finished **and** no ttlilt is held.
     Nothing in that counts passes or measures interior drain speed. So tighten the gallop and you reach
      empty-todo *sooner*, then the same ~75 ms trailing guard fires: the snap moves **earlier, not
       different** — and the `!ttlilt_held()` term still holds it open for a req that genuinely has more to do.
        No new false-quiescence class appears (a req with more work either has todo pending or holds a ttlilt),
         and the `rekick` watchdog (`:1996`) that drives a stalled todo still stands. This is why the tension is
          smaller than it first looks: **step-snaps are safe and only get faster.**
- **What's actually at stake is *intermediate* observability** — a Story asserting mid-settle, or the dense
   observation track watching the descent. That is precisely what §2 is *for*. So: let a system that wants to
    watch its gallop keep it loose (or watch via the §2 track); tighten everything else.
- **Therefore both techniques are gated the §2 way** — default-off, **designated-system opt-in** (tighten only
   under a marked root). Lies+Lang settle opts in (nothing needs to snap its internal maz-descent); a Book that
    asserts on mid-settle progress does not.

### Scope + guardrails

- **The cross-machine rungo hop never collapses** — that latency is the network RTT, not the gate. Only the
   *local* hops (the ~8 compile, the local run hops, the Lies-stack descent) are in play.
- **Never re-pump past real async work.** Technique B fires on `finish()` — i.e. *after* the awaited work
   actually completed — so it never busy-spins a still-running compile/disk read; it just removes the poll
    latency between "done" and "parent notices."
- Hard wall-clock budget with a `log()` when it clips, so the collapse can never itself become the stall it
   removes; prove each in isolation on one settle first (`fight-back-on-core-changes` — this is the belief loop;
    read `src/lib/O/spec/Coding_guide.md` on wake≠hold + the ttlilt rules before touching `answer_calls`/`do()`).
- **Payoff:** flattening the gate during a gallop + event-driving the up-walk saves the `N × 50 ms`/150 ms
   pacing *and* the per-pass O(N) tax (§3) × the passes removed — the deepest lever in the perf map, and the one
    that most directly speeds Lies+Lang.
