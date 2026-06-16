# Story, next level — one enWaft, continuity, time-surfing, fuzz

A scheme, not a fix. Diffmatication works badly and wants a full shakeout, but
 the shakeout is downstream of a bigger merge: there are **two snap encoders** in
  the tree doing nearly the same walk, and the interesting features (surf an
   object through time, label acknowledged non-determinism, fold a huge snap into
    a fern garden) all want the *same* missing thing — a **continuity map** that
     says which particle in step N is which particle in step N+1, carried as
      out-of-band `objecties` so every consumer reads it the same way.

This spec lays out that merge and the features it unlocks. Nothing here is built
 yet; `⛑️` marks the gaps. The snap line shape lives in `NOTATION.md` and in Text
  (`enL`/`deL`); read this alongside `Hovercraft.design.md` (req/maz, ttlilt,
   `beliefs()` as a `Selection.process()`).

## 0. The notation, briefly

`%Step` is a live session step; `%step` is its canonical-on-disk twin (see CLAUDE.md
 — `The` is storage, `This` is the session). A snap line is `stringies` (the
  diff-comparable, persisted part) then a TAB then `objecties` (out-of-band JSON,
   never diffed, never identity). Today `objecties` carries `{"mung":["age"]}`,
    `loopy:N`, `hid:1`. This spec mostly adds keys *there*.

---

## 1. Where we are: two encoders, one walk

There are two implementations of "walk a C tree, emit a snap":

- **Text** — `enWaft` → `encode_wh_lines` → `enLine`. Two passes: a `Travel.dive()`
   ref-count pass (`ref_count`, `ref_min_d`) then a `Travel.forward()` encode pass
    that stubs deeper occurrences of a shared C (`loopy:N` on the shallowest,
     `hid:1` munged shadow on revisits). Protocols are inline rule sets
      (`WAFT_PROTOCOL` = `Waft|What|Doc|Point`, each with `omit_sc: SESSION_KEYS`).
       Rules carry `omit_sc`, `blockquote_these_sc`, `munging`, `thence_matching`.
        Has a decode side too (`deWaft`/`decode_wh_lines`), though loopy-decode
         throws — `⛑️ <` not built.

- **Story** — `snap_H` → `story_process_node` → `enL`, plus `encode_toc_snap`/
   `decode_toc_snap` for the `The/**` tree. `snap_H` is built on
    `Selection.process()`: `each_fn` encodes a node, `trace_fn`/`traced_fn` mirror
     the walk into a D-tree and set `D.sc.changed` / `D.sc.is_new` by comparing to
      `bD` (the **before-D**, the prior step's D at this path). It does its *own*
       loopy pass afterward (collect `loopy_Cs`, stamp `loopy:N`, stub revisits
        with `hid:1`) — a second, hand-rolled copy of what `encode_wh_lines`
         already does.

These have drifted. They munge differently, they track loopy differently, they
 disagree about `SESSION_KEYS`. Diffmatication then reads the *output* of Story's
  encoder and re-derives identity by string-parsing (`dm_identity` = first
   `mainkey:value` of the stringies). Three places, three notions of "same
    particle."

**The merge.** One `enWaft` in Text, parameterised, owns the walk, the loopy
 pass, the protocol matching, and `enL`/`deL`. Story stops hand-rolling `snap_H`'s
  loopy pass and instead *passes Story-ness in* as parameters. Diffmatication
   stops re-deriving identity and *reads it out* of the side channels (§2).

### 1.1 The unified `enWaft` signature

`enWaft` already takes `{ all_knowing, matching, muted_log, max_child_depth }`.
 Grow it to accept the Story hooks that `snap_H` currently inlines:

```
enWaft(C, {
  matching,           // protocol rule set (WAFT_PROTOCOL, story_matching, …)
  max_child_depth,
  muted_log,

  // — Story parameterisation (new) —
  process?:   Selection,        // reuse a Selection across steps for continuity
  channels?:  Channel[],        // side channels to emit alongside Snap:H (§2)
  decorate?:  (n, T, mark) => void,   // last-chance line mark (glyph or objecties)
  bD_of?:     (T) => TheD | undefined,      // supply the before-D for continuity
}) => { channels: { [name]: { snap, dige } }, errors, muted_log, Se }
```

The key idea: `enWaft` always builds (or is handed) a `Selection`, so the D-tree
 mirror — the thing `snap_H` already produces — is *always available*, not a
  Story-private side effect. `beliefs()` is already "a `Selection.process()` over
   H/A/w" per Hovercraft.design; this just makes the snap encoder the same shape.

The loopy pass moves wholesale from `snap_H` into `encode_wh_lines` (it already
 lives there for Text). Story deletes its copy. `story_process_node`'s munge/
  blockquote/skip rules become a `matching` protocol (call it `STORY_PROTOCOL`)
   passed in, exactly like `WAFT_PROTOCOL`.

> Open: `enWaft` is `async` and walks once; `snap_H`'s loopy pass walks twice more.
>  The merged version should keep Text's two-pass (`dive` then `forward`) and fold
>   Story's third walk into the `forward` pass. ⛑️ verify the ref-count pass sees
>    the same tree Story's `process_sc:{snap_root:1}` selection sees.

---

## 2. Channels — the snap is plural, the main one stays clean

A snap is already more than one stream: a step's capture is `Snap:H` (House state)
 plus `Snap:cytowave` (graph data). Make that explicit and open-ended: **a step
  captures N channels**, each independently encoded, fuzz-wrangled (§4), diged, and
   diffed. The test suite grows channels the way it grows tests.

Why split: **a true text representation that isn't full of noise matters.** The
 main `Snap:H` channel should read like the House actually looks — clean lines, no
  machinery bolted on. Everything that is *about* the snap rather than *in* it
   (ref linkage, continuity, the event trace) belongs in its own channel, off to
    the side, where it can be as noisy as it needs without wrecking the one
     representation a human reads and diffs.

### 2.1 The channel set

- `Snap:H` — the canonical **clean** House text. The thing you read.
- `Snap:refs` — **ref-continuity** (loopy/hid) lifted *out* of `Snap:H`. The same
   `C` reappearing is a linkage fact, not House content; today it litters the main
    text with `{"loopy":N}` / `hid:1` stub lines. Move it. `Snap:H` then shows each
     particle once, cleanly; `Snap:refs` records "this line and that line are one C."
- `Snap:cont` — **non-ref continuity** across steps (§2.3): which line continues
   which from the prior step, what's `new`/`gone`, `.vers` bumps.
- `Snap:trace` — the event stream (§2.4).
- focused probe channels — declared captures (§2.5).
- `Snap:cytowave` — the existing graph wave.

Each channel carries its own dige, so determinism is checked **per channel**: a
 test can pass on `Snap:H` while a probe channel flags drift, or the trace channel
  catch non-determinism the settled House state hides (§2.4).

### 2.2 Three ways to mark — cheapest noise wins

When a fact *must* ride inline on a line rather than in a side channel, there's a
 noise hierarchy:

1. **a side channel** — zero noise in `Snap:H`. The default for refs, continuity,
    trace.
2. **a unicode glyph on a peelable** — the stringies are peel format
    (`k:v k2:v2`, space-separated, sayable); a single glyph tossed onto a token
     (`req:Store↺`, a leading `◇`) marks a line without a JSON blob and *stays
      readable text*. The peel codec already round-trips this; `deL` just needs to
       peel the glyph back off.
3. **objecties JSON** — `\t{"loopy":1,…}` after a tab. Full structured data, but it
    ends the line in a JSON object — the noisiest option, and `enL` only adds the
     tab when objecties is non-empty, so today every `loopy`/`mung` line pays it.

The rule going forward: prefer (1), then (2); spend (3) only when the data is
 irreducibly structured (a `mung` list, a `ref` payload). `Snap:H` should ideally
  carry **no objecties at all** — a clean canonical line per particle.

### 2.3 Continuity, as a channel not a blob

The snapper already resolves continuity and throws it away. `trace_fn` keys each D
 on the node's **full** `the_*` identity; `traced_fn` pairs each D to its `bD` (the
  prior step's D at that identity), setting `is_new`/`changed`. Two kinds:

- **ref-continuity** — the same `C` reappears → `Snap:refs`.
- **non-ref-continuity** — a *different* `C` resolving to the *same D-identity* the
   snapper saw last step → `Snap:cont` (or, when surfing wants it inline, a glyph
    per §2.2, never JSON in `Snap:H`).

Why it matters is unchanged: Diffmatication re-derives identity by parsing the
 first `mainkey:value` of each line (`dm_identity`) — strictly worse than the
  snapper's full-identity resolution, and it collides on sibling particles, patched
   with `:1`/`:2` suffixes. The fix is still "write down what the snapper knew"; the
    revision is *where* — a channel, keeping `Snap:H` clean, not objecties on every
     line.

`Snap:cont` records per step: `cont` (continued, same D-identity, not a ref), `new`
 (no `bD`), `gone` (`bD` with no D — a ghost, §5), `vers:[n,m]`. Surfing (§3.2)
  reads it; the fern fold predicate (§6) rolls it up. No global object-id, no
   cross-reload scheme — only the snapper's per-step resolution, written to a side
    channel. (Same `Selection.process()` Map pass Lang wants for the doc Map via
     `regroup()`: one pass, Lang reads it for space, Story for time.)

### 2.4 The trace channel

The event stream — `Run.trace(kind, tag)`, the ticks | attends | thinks | beliefs |
 elvis | ttlilt flow — wants the same treatment as House state: **store it as a
  channel and wrangle its non-determinism** (§4). The trace is the noisiest thing
   in the system — timing jitter on every line, ordering that varies run to run —
    so raw it is undiffable. Fuzz-wrangled (timings classed `kind:timing`,
     run-to-run ordering `kind:ordering` — sorted to canonical where it can be,
      acknowledged where it can't) the channel diffs down to *did the same sequence
       of attends/thinks/beliefs happen*, which is exactly the question a flaky test
        asks.

A diged trace channel is a stronger assertion than `Snap:H` alone: not "the House
 ended up the same" but "it *got there* the same way" — same beliefs walk, same
  elvis order. Much non-determinism is invisible in `Snap:H` (it settles to the
   same final state) yet shows up first in `Snap:trace` (it settled *differently*).
    The TimeSpool `surprise` trend (§4.3) should run **per channel** — surprise in
     the trace channel is an early warning the House-state channel hasn't caught.

### 2.5 Focused probe channels

Channels are configurable and can be **high frequency, hooked at trace points**. A
 probe channel declares what to catch:

- a certain elvis going somewhere — `elvisto('Story/Story', 'fn', …)` matching a
   pattern, captured every time it fires, with args.
- exact `ticks` | `attends` | `thinks` | `beliefs` for one ghost — chase a single
   actor's heartbeat without the rest of the trace's noise.

Each probe is its own channel: its own snap text, fuzz protocol, dige, and diff to
 surf. Chasing a bug becomes "turn on a probe for this elvis, run the test, diff
  the probe across runs" — declarative capture that lives beside the test, not
   scattered `console.log`. ⛑️ probe-declaration syntax and the trace-point hook
    API are unspecified; `trace_enable`/`trace`/`trace_drain` is the substrate.

---

## 3. Diffmatication shakeout

Don't fix it piecemeal; rebuild it on the merged encoder + continuity map. The
 current correlation-by-string-parse (`dm_correlate`, `dm_identity`) goes away —
  it re-derives, badly, what `objecties.cont` now states.

### 3.1 Keycodes, matching Story

Story's `handle_story_key` is the model. Bring the same vocabulary to
 Diffmaticui (today it only has Arrow-nav, `p` to cycle, Esc):

| key | Story today | Diffmatication wants |
|-----|-------------|----------------------|
| `e` | cycle exp ↔ prev | toggle exp ↔ prev (same) |
| `r` | raw (`naive`) snap, no diff | raw snap, one-way (same) |
| `f` | first ↔ got (Resnapture) | first-vs-now across all time |
| `t` | trace panel | trace panel |
| `a` | expand | expand |
| ←/→ | — | step nav (keep) |

Replace the `p` three-cycle (`prev→exp→next`) with Story's explicit `e`/`r`/`f`,
 plus a new mode for §3.2. Reuse Story's `eff_mode` auto-logic verbatim: an `ok`
  step defaults to raw, a mismatch prefers `exp`, fallback `prev`.

### 3.2 Surfing one object through time

The headline feature. Pin an object (click a row — pinning already exists, keyed
 by `dm_identity`; rekey it to the snapper's D-identity read from `Snap:cont`).
  Then ←/→ no longer steps the *snap*; it steps *that object* along its `cont` chain
   and shows:

- its stringies at each step (the diff is now temporal, object-local);
- its continuity transitions — when it appeared (`new`), continued (`cont`),
   bumped `.vers`, vanished (`gone`);
- a sparkline of `.vers` over the steps it lived.

This works only because the snapper marked its D-identity (§2). With
 `dm_identity`'s first-mainkey guess you can't reliably find "the same object" in
  step N+1 — which is precisely why Diffmatication is unreliable today.

### 3.3 The pip, re-decorated

The pip (step indicator, `·`/`○`, `ok`/`hollow`/`busy`) gains continuity-aware
 decoration:

- a step whose only changes are **acknowledged non-determinism** (§4) draws a
   distinct glyph — not pass-green, not fail-red, a third "noisy-but-ok" mark;
- a step that introduced new object refs vs. fewer than expected can tint;
- hovering a pip can preview the continuity delta (`+2 new, 1 gone, 3 vers-bumps`).

---

## 4. Acknowledged non-determinism + TimeSpool

`TimeSpool` exists today (Story `spool_time_sample` / `The/TimeSpool`,
 `{TimeTotal:'beliefs'}` keeping the last 10 timing samples, oldest evicted). It
  is timing-only. Generalise it into the home for **acknowledged non-determinism**.

### 4.1 The fuzz problem

Most step-to-step `Dif:change` rows in the example snap are *not* real changes —
 they're timestamps and counters: `at=1781596211.071` vs `at=1781589646.55`,
  `round=35` vs `round=38`, `want=…`, `time,compile=0.002` vs `0.003`,
   `walked_at`, `seeded`. These already get `{"mung":["age"]}` so they're flagged,
    but the diff still lights them up as `Dif:change`/`Dif:prev`, drowning the one
     row that matters.

These are **acknowledged non-determinism**: known, expected, allowed to vary. The
 goal is to *wrangle and label* them so they read as `Dif:fuzz` (or fold away
  entirely, §6), not `Dif:change`, and to *track whether the fuzz is growing*.

### 4.2 Classifying fuzz

The `matching` protocol already munges these (`mung:["age"]`). Extend a rule
 `means` with a fuzz class:

```
%fuzz,kind:age      monotonic time/age field (at, seeded, walked_at)
%fuzz,kind:counter  free-running counter (round, want)
%fuzz,kind:timing   measured duration (time,compile / all)
%fuzz,kind:ordering set/map order that varies run to run
```

The class is a line mark, so it follows the §2.2 hierarchy: a fuzz glyph on the
 peelable (`at⌁` say) keeps `Snap:H` readable, beating a `{"fuzz":…}` JSON blob.
  Diffmatication then renders a fuzz row as `Dif:fuzz` and the pip uses the §3.3
   "noisy-but-ok" glyph when a step's *only* non-`same` rows are `fuzz`. Trace and
    probe channels carry their own fuzz classes (§2.4) — `kind:timing`/`ordering`
     are the trace's whole problem.

### 4.3 TimeSpool → a non-determinism trend

The point of keeping a spool (not just the last value) is to answer: **is the
 non-determinism increasing, or vanishing?** Extend each TimeSpool sample beyond
  timing:

```
The/TimeSpool/{Sample,at}/{channel:H}      // one per channel (§2)
  fuzz_rows:    N        // count of Dif:fuzz this run
  surprise:     M        // Dif:change rows NOT covered by a fuzz class
  new_refs:     K        // Snap:cont `new` count
  gone_refs:    G        // Snap:cont `gone` count
  vers_churn:   V        // sum of .vers bumps
```

Per channel, because a test can be calm on `Snap:H` and noisy on `Snap:trace`
 (§2.4) — the spool needs to see each.

With the last-10 window already there, a simple slope over the spool tells you
 fuzz is creeping up (a test getting *more* non-deterministic — usually a
  regression) or settling toward zero (good). **`surprise > 0` is the real
   failure signal** — a change no fuzz class accounts for. Today that's buried;
    with the spool it becomes a first-class, trended number per test.

> A test may *acquire* fuzz legitimately (new timestamped field). The flow: it
>  shows up as `surprise`, a human acknowledges it by adding a fuzz rule, it moves
>   to `fuzz_rows`. The spool shows the surprise spike then the return to baseline.

---

## 5. Ghosts — `gone` rows from `Snap:cont`

Path-diff today can only say a line is `left_only`/`right_only`. With the snapper's
 continuity, a vanished object is `gone` and can be drawn as a **ghost row** at its
  last-known position (its `bD` knows where it was). This matters for
   surfing (§3.2): an object's timeline shouldn't just stop — it should show the
    step where it died, decorated. Reuse the existing fade-out animation
     (`opacity`/spring) the ui already runs frame-to-frame; a `gone` row fades but
      stays a tick so the eye catches the death.

---

## 6. Fern gardens — folds from the continuity map

The example snap is mostly `Dif:unchanged count:36` / `count:52` runs already —
 `squish_context` collapses unchanged stretches. That's a flat squish. The
  continuity map enables **structural** folds: present a large snap/diff as a
   *fern garden* — fronds that stay curled until you need them.

A frond is a subtree whose continuity is *uniform*: every descendant is `same` or
 only `fuzz`. The snapper's per-node continuity already knows this (roll up `cont`/
  `new`/`gone` + `fuzz` over children). So:

- a subtree that's entirely `same` curls to one frond line (deeper than squish:
   it's identity-aware, so it won't curl two *different* objects that happen to
    look alike);
- a subtree that's `same` modulo fuzz curls with the noisy-but-ok glyph;
- a subtree containing a `surprise` or `new`/`gone` ref stays *uncurled*, drawing
   the eye exactly to where real change lives.

This reuses Lang's fold machinery conceptually — `Lang_apply_openness` folds a doc
 around engaged Points; a fern garden is the same move applied to a snap diff, with
  the curl/uncurl decision driven by continuity rather than by cursor engagement.
   ⛑️ the actual fold widget is Diffmaticui work, but the *fold predicate* is a pure
    read of the snapper's per-node continuity.

---

## 7. Cyto symmetry — one delta, three renders

Cyto already does this diff. `make_wave` is documented `Ze n=topC → diffs C** vs
 bD** → wave`, and it takes `(adjacent, backwards, departing, absolute)` — it diffs
  the live C-tree against its `bD` and animates the delta *in either direction*
   (the `backwards` flag). That is the same `bD` resolution the snapper uses (§2)
    and the same forward/back the surf wants (§3.2). Three renders of one delta:

- **Cyto** — nodes move, pulse, fade (the wave).
- **Diffmatication** — rows align, change, ghost.
- **the channels** — `Snap:cont` (`cont`/`new`/`gone`/`vers`) and `Snap:refs`.

Pull the `bD`-diff into one primitive all three consume. Then **cross-drive** them:
 click a Diffmatication row ⇒ fire a Cyto wave centred on that object's node;
  hover a Cyto node mid-wave ⇒ scroll Diffmatication to that object's row and
   unfold its frond (§6). The two views become one instrument seen from two sides.
    Cyto's wave already carries `step_n`/`absolute` — the same step axis as the
     pips, so the strip (§10) can scrub Cyto too.

> Open: Cyto diffs *live C* vs bD; Diffmatication diffs *snap text*. The shared
>  primitive is the `bD` resolution, not the rendering. ⛑️ decide whether
>   Diffmatication decodes snaps back to C (needs loopy-decode, still `<`) or Cyto
>    learns to wave off a decoded snap. The latter lets Cyto replay *saved* history,
>     not just the live run — a big win for surfing.

## 8. ttlilt — seeing what held the step up

A req arms `req/%ttlilt,until_ts` to ask for time before Story snaps;
 `i_Story_o_req_ttlilt` gathers them onto `Run.o({ttlilt:1})` carrying `of_w` +
  `req` + `until_ts`, and `o_Story_req_ttlilt` already traces
   `"held by w:X k:v +Nms"` into the per-step `Run_trace`. So for every step we
    already know *exactly* which ttlilts gated it, whose req, which world, how long.
     Surface it:

- a step's panel lists the ttlilts that held it — `w:LakeFlush req:Store +203ms` —
   read straight from the captured `Run_trace`.
- each ttlilt **links to its req's row in the diff** — the req particle is right
   there in the snap (`req:Store,eternal,maz=7` in the example). The link is the
    `req` backlink → that line.
- clicking the link **induces the fern garden to unfold** the frond containing that
   req (§6), so you land on it even when it was curled — the same move as
    `Lang_apply_openness` opening a doc around an engaged Point.
- a ttlilt that **timed out** (`poll_ttlilt_expired`) decorates red: it held things
   up and never delivered.

This ties timing to structure: "this step took 6s — these three ttlilts; here they
 are in the tree; here's what each was waiting to write." The TimeSpool slope (§4.3)
  says *whether* a step is getting slower; the ttlilt links say *what* is making it
   slow and *where* it lives.

## 9. Islands — the macro map

A big snap is a few large islands plus scatter. Compile subtrees are *large but
 simple* — high node count, low change/fuzz, mostly `Map`/`def` lines. Draw the
  snap zoomed out: each major subtree an **island**, sized by node count, tinted by
   change/fuzz/surprise density. This is itself a graph — **reuse Cyto** (§7) to
    render islands as nodes and containment as edges.

- an all-`same` island stays one collapsed continent you never open;
- a `surprise` lights one island red on an otherwise calm map;
- "Compile, large but simple" becomes one fat pale island — opened only when it
   reddens.

Island membership is a roll-up of the same per-node continuity that drives fronds
 (§6) — islands are just fronds one zoom further out. The macro map and the line
  diff are the same fold predicate at two scales.

## 10. Pip thumbnails — the strip as a contact sheet

Replace the `·`/`○` pip glyph with a tiny **thumbnail of that step's fern-posed
 diff**: unchanged fronds curl to nothing, real changes bloom as marks, fuzz as a
  faint tint, surprise as one bright pixel. The step strip becomes a contact sheet
   — you read the whole run's shape at a glance and click toward the step whose
    thumbnail blooms. The `ok`/`hollow`/`busy` states still ride as border/pulse.
     A surfed object (§3.2) can light its row's pixel across *every* thumbnail, so
      the object's life shows as a streak down the strip.

## 11. More we could dream

Cheap to state, grounded in what now exists:

- **Playback.** Hold → to play the run as a movie: fronds bloom as changes land,
   ttlilts flash, Cyto waves in step. A test becomes a watchable thing.
- **Provenance channel.** A `Snap:wrote` channel could carry *who wrote* a line —
   the ttlilt already knows `req` + `of_w`; thread that to the lines that req
    settled. A changed row then links to its author; surprise rows get blamed
     automatically — and `Snap:H` stays clean.
- **Surprise bisect.** When `surprise` first appears at step K, auto-open K and
   surf the offending object's `bD` chain back to its last calm step — the diff
    narrows itself to the moment it went wrong.
- **Island heatmap over time.** Cross §9 with the TimeSpool (§4.3): which islands
   churn most across the last 10 runs. Rotting subsystems glow.
- **Cross-test islands.** The Compile island in test A vs test B — same structure,
   compare. A fleet-wide island view.
- **Snap minimap gutter.** Like DocMinimap for Wafts: a continuous gutter beside
   the diff marking where blooms and ghosts sit; click to jump.

## 12. Automating many tests

Once a test's non-determinism is a trended number (§4.3) and its real-change
 signal is `surprise > 0`, a fleet of tests becomes mechanically triageable.

- **Green/amber/red without eyeballing.** `surprise==0` ⇒ green. `surprise==0 &&
   fuzz rising` ⇒ amber (drifting). `surprise>0` ⇒ red. No human reads a diff
    unless red or amber.
- **Auto-acknowledge proposals.** When a run is all-`fuzz`+`same`, Story can
   *propose* the fuzz rules that would zero the surprise (it already knows which
    rows are `Dif:change` and what kind they look like — `age`/`counter`/`timing`
     are pattern-detectable). The human confirms; the rule lands in the protocol.
- **Batch reseed.** Resnapture across many tests at once (the `first_snap`/
   Resnapture path already exists per-test); gated so only green-after-reseed
    tests auto-save their new `got_snap`.
- **A TimeSpool dashboard.** Per-test sparklines of `surprise`/`fuzz_rows`/
   `vers_churn` over the last 10 runs — one screen says which tests are rotting.

This is the "somewhat explore" part: the spool + the channels are the substrate;
 the fleet view is a Storui/Diffmaticui surface over many `The/**` trees at once,
  and a test can declare *which channels* it cares about (most want `Snap:H`; a
   flaky one turns on `Snap:trace`; a bug hunt turns on a probe). ⛑️ scope of
    "many" (one repo's tests vs. cross-run history) deferred.

---

## 13. Staging

1. **Merge the encoder.** Move `snap_H`'s loopy pass into `encode_wh_lines`; recast
    `story_process_node` rules as `STORY_PROTOCOL`; route Story through `enWaft`
     with `matching: STORY_PROTOCOL`. Snaps should be byte-identical before/after
      (the regression gate is the existing `*.snap` fixtures in `wormhole/Story/`).
2. **Channels split.** Make `enWaft` return named channels; lift `loopy`/`hid` out
    of `Snap:H` into `Snap:refs`. `Snap:H` gets *cleaner* — fixtures change once,
     deliberately, and the change is "noise removed." Teach `deL` to peel a glyph
      off a token (§2.2) so the lightweight mark path exists.
3. **Continuity channel.** Have `enWaft` keep its `Selection` and emit `Snap:cont`
    (`cont`/`new`/`gone`/`vers`) from the `bD` resolution.
4. **Diffmatication on channels.** Replace `dm_identity` string-parse with the
    snapper's D-identity from `Snap:cont`; add `r`/`e`/`f` keys; pin-and-surf
     (§3.2); per-channel mode switch.
5. **Fuzz classes.** Add `%fuzz,kind` to the protocol; render `Dif:fuzz`; re-pip.
6. **TimeSpool trend.** Extend samples per channel (§4.3); slope; surface
    `surprise`.
7. **Trace channel.** Capture `Run.trace` as `Snap:trace`; fuzz-wrangle timing/
    ordering; dige it. Then focused probe channels (§2.5).
8. **Cyto symmetry.** Factor the `bD`-diff into one primitive (§7); cross-drive
    row↔node. Cheap after stage 4, since both read `Snap:cont`/`Snap:refs`.
9. **ttlilt surfacing.** List held-by ttlilts per step from `Run_trace`; link to
    req rows (§8).
10. **Fern garden.** Continuity-driven fold predicate + the curl widget; then
     ttlilt unfold-to-reveal lands for free.
11. **Islands + thumbnails.** Macro map (§9) and pip contact sheet (§10), both
     rollups of the §10 fold predicate.
12. **Fleet.** Multi-test triage surface (§12).

Each stage is shippable and gated by the snap fixtures. Stage 1 is pure
 de-duplication and should change *nothing* observable — do it first and prove it.
  Stage 2 only *removes* noise from `Snap:H`; every later channel is additive.

---

## Open / deferred

- ⛑️ Loopy *decode* still throws in `decode_wh_lines`. With refs lifted to
   `Snap:refs` (§2.1), `Snap:H` decodes *without* loopy at all — the re-link is a
    second pass that reads `Snap:refs` and stitches the shared `C` back. That may
     be easier than in-band loopy-decode, and it's what a replaying Cyto (§7) needs.
- ⛑️ Channel sync. Channels are separate snaps but describe one step; `Snap:cont`
   and `Snap:refs` reference `Snap:H` lines (by D-identity, not line number, so
    edits don't break them). Define the cross-channel reference key once.
- ⛑️ Glyph collision. A unicode mark on a peelable (§2.2) must use glyphs that can't
   occur in a sayable value, or `deL` can't tell mark from content. Reserve a small
    private-use band; `peel`/`depeel` own the reserve list.
- ⛑️ Identity across a *reload* (new session, C rebuilt from snap). In-session the
   snapper resolves D-identity off live refs; cold-start from a saved snap must
    re-establish the same resolution from the line content alone (full identity +
     path) — deterministic from the snap, so the chain re-links, but verify it.
- ⛑️ Fuzz `kind:ordering` is the hard one — set/map order. May need the encoder to
   sort deterministically rather than label, i.e. *remove* the non-determinism
    rather than acknowledge it. Acknowledge only what can't be sorted away.
- Open: does the standing continuity (the kept `Selection`) belong in `H.ave`
   beside `This` and the Matstyle swatches (session-scoped, graph-clean) or on
    `Run.c` (per-run)? Lean `H.ave` so Cyto/Matstyle can read it too — a node could
     pulse on a `.vers` bump using the same wave machinery (§7).
