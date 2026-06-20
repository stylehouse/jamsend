# EntropyArrest — Lines, Snapcaps, and spaying acknowledged noise

A scheme, architected before any code. It realises `Story_next_level_spec.md` §1
 (the two-encoders merge) and §4 (acknowledged non-determinism) as one concrete
  mechanism, and adds the authoring loop the spec left at "a human acknowledges it
   by adding a fuzz rule" — turning that hand-edit into a **click on the diff**.

Three moving parts, in dependency order:

1. **Lines** — collapse the two snap encoders into one parameterised walk. The
    precondition: the noise layer needs exactly *one* place to bite.
2. **spay** — neutralise a noisy token in a snap line in place (glyph it, or band
    it), keyed by a structural locator, not a line number.
3. **EntropyArrest / Snapcap** — the authored, data-form store of what to spay,
    compiled to one fat lematch + a handler table, included globally, offered to
     the diff UI.

The headline the user named: *refactor the snapper to be like `enWaft` and call it
 Lines — architect that first.* §1 is that. §2–§4 are what it unlocks.

## Status & grounding (read this first on a cold start)

**The engine is built (Stages 2–4); the authoring UI (Stages 5–6) is not.** What
 landed, all gated got-to-got on the headless runner (`scripts/Story_cli_run.mjs`):

- **spay `means` in the shared `enLine`** (Text.svelte) — `drop` (≡ today's mung),
   `blank` (regex → mirage marker), `band`/`add_step_mult` (snap to a step-scaled
    baseline within `factor×`, diverge past it with a `‼` blow-out flag). Helpers
     `spay_line` / `spay_num`; the marker constant `SPAY_MARKER`. The pre-spay text
      is kept on `q.raw_line` (and `D.sc.raw_line` + `D.sc.spayed` for the UI).
- **the global default**: `story_matching`'s `self,round` rule now carries
   `means.spay = {kind:'blank', re:'(?<=round=)\\d+'}` — the per-tick counter churns
    run-to-run, so blanking it makes the line deterministic. Proven: MundaneStation,
     formerly flaking on `round=N`, is now byte-identical across two runs. (round is
      listed under `blank` in §2.1; `blank` is chosen over the §6-Stage-3 `band`
       because a counter that can drift across the band boundary would re-introduce
        the very flake we're killing — `blank` is unconditionally deterministic.)
- **per-test store + compile**: `entropy_rules(The)` + `entropy_rule_of` /
   `lematch_to_rule` / `entropy_spayer_of` in Hovercraft's new `//#region entropy`
    (beside the determinism sibling `prandle`). `snap_H(Run, w)` compiles
     `story_matching ∪ entropy_rules(w.c.The)` and threads it + `step_n` through
      `story_process_node`. Proven end-to-end: a hand-authored `Snapcap` under
       `The/EntropyArrest` spayed exactly its targeted particle and nothing else.

**Storage shape decision (the UI must follow it).** Unlike the transient
 object-valued `sc_has` that `i_scheme_req` writes on the live `w`, an EntropyArrest
  locator persists in `toc.snap`, where an object in `.sc` is fatal at encode. So a
   `%lematch` stores its matcher as its **own scalar sc keys** (the mainkey `lematch`
    stripped off *is* the `sc_has`); a `%spayer` stores `kind`/`re`/`glyph`/`first`/
     `factor`/`add_step_mult`/`floor` flat, and `drop` names its target key as `key:`.
      Nested `%lematch` children become `thence_matching`; the spay rides the leaf.
       The toc codec is fully generic, so this round-trips with zero codec changes.

**Consequence — fixtures need a one-time re-record.** The `round` blank rewrites
 every `self,round=N` line in every Book's got snap, so the committed `*.snap`
  fixtures (already stale from earlier accepted changes) are now further off. Re-record
   deliberately under `ACCEPT=1` (`ACCEPT=1 node scripts/Story_cli_sweep.mjs`) — the
    human owns that commit. This is the parent spec's stage-2 "Snap:H gets cleaner".

**Not built: the authoring loop (§4, Stages 5–6).** `ui/EntropyArrest.svelte` does
 not exist; nothing yet *authors* a cap from a diff click, and the diff index
  (mirage-scan → `%spayer`, glowy pulse) is unbuilt. The store is hand-authorable in
   `toc.snap` today (and proven so). The remaining work is the interactive surface,
    best built with the app rendering on :9091 — see §4 and §6 Stages 5–6.

**The original first move (§1 Lines walker-merge) was deliberately skipped** as an
 unneeded risk: its whole purpose (§1.1) was to give spay *one* bite-point, but
  `enLine` is already the single per-node encoder both walkers call, so spay landed
   there directly with no merge. The `snap_H`-vs-`encode_wh_lines` *walk* unification
    (Selection D-mirror vs Travel) remains a cosmetic-only refactor with no behaviour
     payoff — leave it unless a concrete need appears.

The five code anchors a builder reads before touching anything:

- **Story.svelte** — `snap_H` (~916), `story_process_node` + `story_matching`
   (~786–914): the Story encoder and its hand-rolled loopy pass that §1 deletes.
- **Text.svelte** — `encode_wh_lines` (~143), `enWaft` (~306), `enLine` (~642,
   where `means`→`q` becomes a line; spay joins here as `q.spay`).
- **Hovercraft.svelte** — `i_scheme_req` (~400) + `i_Story_o_req_ttlilt`'s `follow()`
   (~467): the existing "build a `%scheme/%lematch` chain and descend it" pattern the
    §3.2 entropy compile mirrors; `prandle` (Housing.svelte.ts ~388) is its
     determinism sibling.
- **ui/EncodingSplatter.svelte** — the placeholder ancestor (§4.0): group-by-mainkey
   + lematch-snippet generation, clipboard-into-source. EntropyArrest.svelte grows
    from it.
- **LangRegions.svelte** — `Lang_def_at_offset` (~431): the bookmark→named-pointer
   reducer that §4.1/§4.4 reuse to turn a clicked line into a minimal locator.

Parent: `Story_next_level_spec.md` (§1 encoder merge, §4 fuzz, §13 the Waft framing
 this drops into later). The marker for every spay is **في غيابها كوّنتُ صورتها**
  (Darwish — *in her absence, I formed her image*).

---

## 0. The problem, exactly

The Story snap diff is the test signal (`On_the_artchitecture.md`: "this
 codebase's safety rests almost entirely on snap-diff vigilance"). Non-determinism
  drowns it. From the example `Step:2` diff:

```
self,round=15            {"mung":["age"]}     ← counter, value-key
want=1781935793885,kind:cold                  ← timestamp, MAINKEY value (identity!)
time,compile=0.008,all=0.259                  ← timings, value-keys
```

Today these are tamed by `story_matching` munging (Story.svelte) — but mung is
 **drop-the-key**: it removes the key from the diffed `stringies` entirely. That
  works for `age` (a pure-noise sidecar timestamp) but fails the three above:

- `want=<ts>` — the timestamp *is the mainkey value*. Drop it and you destroy the
   particle's identity; the line can't be matched to its prior self at all.
- `time,compile=…,all=…` — drop them and you lose the timing signal you might
   actually want to watch (the TimeSpool slope, §4.3 of the parent spec).
- `round=15` — drop it and you can't assert it at all; keep it and it churns ±1.

What's missing is a **third option between keep and drop**: rewrite the noisy
 *number* in place while keeping the line's shape and identity. The user's words:
  *"just replacing the number with some unicode characters."* That is **spay**.

And it must be **authored from the diff**, not hand-coded in `story_matching`: you
 are staring at the noisy line; clicking it should be how you silence it.

---

## 1. Lines — one walk, one bite-point

There are two implementations of "walk a C tree, emit snap lines":

| | encode | per-node | walk |
|---|---|---|---|
| **Text** | `encode_wh_lines` | `enLine` | `Travel.dive` (ref-count) then `Travel.forward` (encode), loopy stubs inline |
| **Story** | `snap_H` | `story_process_node` → `enLine` | `Selection.process` (each_fn/trace_fn/traced_fn), **then a hand-rolled second loopy pass** (Story.svelte ~968–1009) |

They share `enLine` already. They differ in the *walk* and in the loopy pass,
 which `snap_H` re-implements (`loopy_Cs`, `forward()`, the `hid:1` shadow stub) —
  a verbatim second copy of what `encode_wh_lines` does at lines 226–253.

**The merge.** Promote `encode_wh_lines` to the one walker; rename the concept
 **Lines** (`enLines` / `deLines`). It already owns the loopy pass. Grow its `opt`
  to accept what `snap_H` inlines today:

```
enLines(C, {
  matching,            // protocol rules (WAFT_PROTOCOL | STORY_PROTOCOL | …)
  max_child_depth,
  muted_log,
  all_knowing,

  // — Story parameterisation (folded in from snap_H) —
  process?:  Selection,          // reuse across steps; the D-tree mirror
  trace_fn?, traced_fn?,         // continuity (bD compare) — Story's change/is_new
}) => { snap, raw_snap, errors, muted_log, Se }
```

**spay is not a new parameter.** It rides the `matching` rules already passed in.
 The lematch a rule carries `means: { spay }`, and `enLine` delivers a `q.spay`
  alongside the `q.skip` / `q.mung` / `q.thence` it already produces — applied at
   the same point those are (§2). So EntropyArrest's compiled output (§3) is just
    *more `matching` rules*, concatenated onto `STORY_PROTOCOL` the way
     `thence_matching` already is. `enLines` learns nothing new; the vocabulary
      grows by one `means` key.

- `snap_H` becomes a thin caller: `enLines(Run, { matching: STORY_PROTOCOL,
   process: Run.c.snap_Se, trace_fn, traced_fn, spay })`. Its bespoke loopy block
    is **deleted** — `enLines` already stamps `loopy:N` / `hid:1`.
- `enWaft` stays a thin caller with `matching: WAFT_PROTOCOL`, no `spay`.
- `story_process_node`'s `story_matching` becomes `STORY_PROTOCOL`, passed in as
   `matching`, exactly like `WAFT_PROTOCOL` — no behaviour change.

> Open (encoder-internal): `encode_wh_lines` uses a two-pass `dive`+`forward`;
>  `snap_H` uses `Selection.process` for the D-tree mirror it needs for continuity.
>   The merged `enLines` keeps the `dive`+`forward` spine and drives the Selection's
>    `trace_fn`/`traced_fn` from the `forward` pass — one walk feeding both the line
>     emit and the D mirror. Verify the ref-count pass sees the same tree the
>      `process_sc:{snap_root:1}` selection saw. (Parent spec §1.1 flags this.)

**This stage is a provable no-op.** Gate it on the existing `wormhole/Story/*.snap`
 fixtures — byte-identical before/after. Nothing here removes noise yet; it only
  gives the noise layer a single door (one `means` key on the one walker) to walk
   through. *This is the "architect that first."*

### 1.1 Why Lines must land before spay

If two encoders survive, spay has to be wired into both, and the dige (computed
 over `snap_H`'s output) and the visual diff (Diffmaticui, over the same) could
  spay differently — re-deriving the same disagreement the parent spec §2.3
   diagnoses three times over. One walker → one spay pass → one notion of "what
    this line really says."

---

## 2. spay — the third option

**spay** is a `means` in the matching vocabulary. A matched rule carries
 `means: { spay: <spayer> }`; `enLine` collects it into `q.spay` exactly as it
  collects `omit_sc` / `munging` today (Text.svelte 668–682), and applies it where
   it already rewrites the rendered line — after `parent_line` is built (721–725),
    beside the mung-drop and BQ handling. No separate pass, no new walker arg. The
     line goes out spayed; the pre-spay text is kept on `q.raw_line` for the UI.
      Three spayers, cheapest-noise-first (mirrors parent spec §2.2):

| spayer | does | for | line after |
|---|---|---|---|
| `drop` | remove the key from stringies (today's mung) | pure-noise sidecars (`age`) | `self,round=15` |
| `blank` | regex-replace the matched number with the mirage marker | identity-bearing or uninteresting numbers (`want=<ts>`, `round`) | `want=في غيابها كوّنتُ صورتها,kind:cold` |
| `band` | snap the value to its nailed baseline while within tolerance; let it diverge past `factor×` | measured timings you want to *watch but tolerate* (`compile`, `all`) | `time,compile=0.005,all=0.18` (baseline) — until a run blows 10× |

`drop` is the existing rule, re-expressed. `blank` and `band` are new.

### 2.1 `blank` — the regex spay

The user's core gesture: *"make a regex pattern for matching the noisy number in
 the snap line and replace it with unicode characters."* A spayer carries:

```
%spayer,kind:blank
  re:    (?<=want=)\d+(\.\d+)?    // the noisy span within the rendered line
  glyph: في غيابها كوّنتُ صورتها   // THE MARKER — one phrase for all spayings
```

It runs on the **rendered line text**, because the noise can sit anywhere — a
 mainkey value (`want=…`), a value-key (`round=…`), even inside an objecties JSON
  blob — and the regex is the only thing that reaches all three uniformly.

**The marker — a mirage.** The token that replaces a number must be one that
 *cannot occur in snap content*, so `deL`/peel never confuse a spayed hole with a
  real value, and so the diff (§4) can find every spayed line by scanning for it.
   Snap content is ASCII peel (`k:v`, sayable), so an Arabic RTL phrase is
    content-impossible by construction. The marker, for **all** spayings, is the
     Mahmoud Darwish line:

> **في غيابها كوّنتُ صورتها** — *in her absence, I formed her image.*

Which is precisely what a spay is: the value is *absent* (noise, a mirage), and what
 stands in its place is the image we formed — the baseline, or just the mark of a
  thing that looked like water and wasn't. One phrase, every spay; `peel`/`depeel`
   reserve it. Canonically it is the full line (deterministic in the dige, unmistakable
    in the raw text); the UI may render it abbreviated/dimmed so a long sentence
     doesn't bloat the read — display is cosmetic, the canonical marker is the line.

The dige is computed over the spayed `snap`, so a `blank`ed token can no longer
 flip `story_ok`. The **raw** line is kept (`raw_snap` / `D.sc.raw_line`) so the UI
  can reveal "what it really was" and so authoring (§4) can diff raw got-vs-prev to
   *propose* the regex.

The dige is computed over the spayed `snap`, so a `blank`ed token can no longer
 flip `story_ok`. The **raw** line is kept (`raw_snap` / `D.sc.raw_line`) so the UI
  can reveal "what it really was" and so authoring (§4) can diff raw got-vs-prev to
   *propose* the regex.

### 2.2 `band` — the "not 10× what it was nailed down at" scheme

The user: *"want=… and compile=… non-deterministic — a scheme to handle that;
 perhaps ensure it is not 10× what it was first nailed down at."* Timings shouldn't
  vanish (you lose the regression signal) nor churn (every run flips the dige). The
   band:

```
%spayer,kind:band
  re:    (?<=compile=)\d+\.\d+
  first: 0.005          // the baseline, set when the cap is authored (§3.3)
  factor: 10            // tolerance multiplier
```

Encode-time realisation, so the **dige stays stable inside the band and flips out
 of it**:

```
v = parse(match)
out = (v <= factor * first) ? render(first) + MARKER   // within band → baseline + mirage
                            : render(v) + ' ‼'          // blown → real value, blow-out flag
```

Within band the line carries the **deterministic baseline *and* the marker** — the
 baseline keeps the dige stable, the marker makes the line findable by the §4.3 index
  ("the quote for all spayings"). So `compile=0.008` renders `compile=0.005 ‹mirage›`
   every run (identical dige, still indexed as spayed) until a run is >`0.05` (10×),
    which drops the marker and renders the true value with a blow-out flag `‼` — a
     `Dif:change` that *means something*. `first` is set when the cap is authored
      (§3.3) and persists in `The` — **not** recomputed each run. This is `surprise > 0`
       (parent spec §4.3) made local and cheap: the only timings that ever diff are
        real regressions.

> A `band` could also assert a floor (`< first/factor` = suspiciously fast, e.g. a
>  no-op'd step). Symmetric; defer until wanted.

#### `add_step_mult` — a step-linear baseline

A counter that legitimately advances each step (`round`, a per-step `want` index)
 breaks a constant band: at step 11 its value is ~11, which a `first:1, factor:10`
  band rejects (`11 > 1×10`). `add_step_mult` makes the baseline grow with the step
   number instead of staying flat:

```
%spayer,kind:band,add_step_mult
  re:    (?<=round=)\d+
  first: 1               // the per-step increment, NOT a fixed value
  factor: 2              // tolerance around the step-scaled baseline
```

```
baseline = first * step_n          // step 11 → 11, not 1
out = within(value, baseline, factor) ? render(baseline) + MARKER : render(value) + ' ‼'
```

So `first:1` *expects step 11 to read 11* — the baseline tracks the step axis, and
 only a value off the line (a counter that double-counted, or stalled) escapes the
  band and diffs. `step_n` is in hand at encode time (the snap knows its step). This
   is the counter analogue of the timing band: same "snap to the expected, diverge on
    real surprise," with an expectation that *moves*.

### 2.3 Encode-time, not diff-time — and why

spay bites in `enLine` (via `q.spay`), changing the persisted `snap` and therefore
 the dige — **not** only in the diff renderer. Rationale:

- the dige is the pass/fail signal (`story_ok`). If spay were diff-only, the snap
   on disk and its dige still churn on every noisy value; the test still flakes.
   "Shush" has to be *real silence*, which means at the dige.
- it's the one place every channel (parent spec §2) flows through after the merge.
- it keeps `Snap:H` canonically clean (parent spec §2.2) — the on-disk fixture
   *is* the de-noised text a human reads.

The diff UI consumes already-spayed lines; it does not spay independently. It
 *can* reveal the raw line on demand (`raw_snap`) and surfaces the spay marks for
  authoring (§4). One spay, two readings — never two spays.

> Consequence for fixtures: introducing spay **deliberately rewrites** the
>  `wormhole/Story/*.snap` files once (noise removed / banded). That is the parent
>   spec's stage 2 ("Snap:H gets cleaner — fixtures change once, deliberately"),
>    distinct from the stage-1 Lines no-op. Re-record under `ACCEPT=1`.

### 2.4 The line-order caveat, bounded

The user: *"we can't know when lines change order too easily."* Correct — and it's
 why the locator is **structural (a lematch), not positional**. A Snapcap matches
  *the particle*, wherever it has drifted in the walk order, so a reordered-but-same
   line is still spayed. spay handles **value-noise**.

What spay does *not* fix is **set/map ordering** — the same children emitted in a
 different order run to run (parent spec §4.2 `kind:ordering`, Open: "the hard
  one"). That is an *encoder* problem (sort the children deterministically before
   emit), not a per-line spay. Keep them separate: Snapcaps shush noisy *numbers*;
    a deterministic child-sort in `enLines` removes noisy *order*. A Snapcap whose
     locator keeps "missing" its line across runs is the diagnostic that you have an
      ordering problem, not a value problem.

---

## 3. EntropyArrest / Snapcap — the authored store

### 3.1 The bucket

A new bucket under `The`, beside `The/TimeSpool` and `The/Styles`:

```
w:Story/The/EntropyArrest         per-test; absent until the first cap is authored
  Snapcap:<slug>            one acknowledged-noise entry
    %lematch,sc_has:{…}     the locator recipe (nested %lematch for descent)
    %spayer,kind:blank|band|drop, re, glyph | first,factor[,add_step_mult]
    note:…                  human reason ("ttlilt deadline is wall-clock")
    scope:step=N            optional; omitted ⇒ ALL steps ("does all steps by default")
```

A `Snapcap` is `(locator, spayer)`:

- **locator** — a `%lematch` (the existing C\*\* pattern: `sc_has` + nested
   `%lematch` children, walked by `Housing.find_lematch`/`unwrap_lematch`). It says
    *which particles*. Stored as a **recipe** — enough of the clicked particle's
     identity to re-find it (mainkey + discriminating sc keys), not a frozen ref.
- **spayer** — *how* to neutralise (§2). The "get-spayed handler."
- a `band` spayer additionally stores `first` (§3.3).

`The/EntropyArrest` is itself **never spayed and never the test subject** — it's
 metadata about the test, like `Styles`. It rides in `The` so it persists in
  `toc.snap` and travels with the Book.

### 3.2 The compile — Hovercraft `region:entropy`, beside `prandle`

The user: *"EntropyArrest turns [the Snapcaps] into a big fat lematch with all the
 get-spayed handlers — try not to overload the diff UI… some of this goes in
  Hovercraft, new `region:entropy` along with `prandle()`."*

Where it lives. Hovercraft already owns the "build a `%scheme/%lematch` chain on
 `w` and descend it" pattern — `i_scheme_req` (Hovercraft.svelte 400) writes
  `w/%scheme:req/%lematch,sc_has:{…}` and `i_Story_o_req_ttlilt`'s `follow()` walks
   it (467–485). The entropy compile is the same move under a new
    `//#region entropy`: read `The/EntropyArrest/Snapcap**`, emit matching rules.
     It sits beside `prandle` deliberately — `prandle` is *injected* determinism (a
      seeded PRNG, on the House class), spay is *acknowledged* non-determinism. The
       two halves of controlling entropy in a test: remove it at the source, or name
        it at the snap. Same region, same concern.

What it produces. **Not** a bespoke `SpaySet` object — `matching` rules, the shape
 `STORY_PROTOCOL` already uses, so they concatenate straight on:

```
prandle's sibling, entropy_rules(The) -> Array<Rule>
  // one rule per Snapcap, nested thence_matching for descent locators
  { matching_any: [{ sc_has: <locator.sc_has> }],
    means: { spay: <spayer>,
             thence_matching: [ …nested locators… ] } }
```

`Story.snap_H` concatenates `entropy_rules(w.c.The)` onto `STORY_PROTOCOL` before
 calling `enLines`. The "big fat lematch" is that merged rule array; the "handlers"
  are the `means.spay` on each. Cost is **one `n.lematch(rules)` per node** — the
   call `enLine` already makes (Text.svelte 656) — not N passes. "Don't overload"
    holds because spay adds zero walks: it's a richer `means` on the walk already
     happening.

The merged rules are also handed to the UI (§4) so it can show which lines a rule
 spays and author new ones. One compiled artifact, two readers — never two spays.

### 3.3 EntropyArrest is per-test; the defaults are the global layer

EntropyArrest is **per-test** — it lives in `The`, which *is* the Book's `toc.snap`
 (its instructions and expected fields). It travels with the Book and nothing else.
  There is no shared global EntropyArrest particle.

The global layer already exists, in code: the default `story_matching` rules. A
 `means.spay` rides them exactly as it rides a Snapcap — **the same expand function
  turns either into a matching rule**. So `self,round` and the rest can carry a
   `band,add_step_mult` (or a `drop`) directly in `story_matching`, applying to
    *every* Book, with no `The/EntropyArrest` stored anywhere. A test gets global
     spaying for free; it only grows a `The/EntropyArrest` once you author something
      test-specific.

This matters for the UI (§4): when the diff lands on a line spayed by a *default*
 rule, the same index/pulse leads to that rule — **the test appears to have an
  EntropyArrest at play even though `The` holds no caps**, because the defaults flow
   through the identical pipeline. The UI reads one merged rule set (defaults ∪ this
    Book's caps) and need not care which half a given spay came from.

`compile` (§3.2) is therefore `story_matching ∪ entropy_rules(w.c.The)` — both
 sides already `matching` rules. The per-test caps are the only ones authored from
  the UI and persisted; the defaults are source.

**Promotion to globality** is the EncodingSplatter move, reborn (§4.0): a per-test
 cap you find yourself wanting everywhere (a fresh `self,round`-shaped noise)
  generates a `story_matching` rule snippet to paste into source — the same
   copy-to-`Text.svelte` gesture EncodingSplatter already does for skip/omit rules.
    Per-test caps live in `The`; promotion graduates one into the default set.

`first` and any band baseline are set **when the cap is authored** (the UI's OK,
 §4) and persist in `The` as ordinary accepted state — *"separate from Accept; our
  changes go into what is Accepted."* No per-run re-nailing.

"Tells it to shush" = these merged rules are the silence applied at encode time —
 the defaults always, this Book's caps once authored.

---

## 4. The authoring loop — `ui/EntropyArrest.svelte`

The user: *"a UI that pushes a pointer for a C\*\* situation from a snap line click,
 and leaves on that snap D\*\* some advice that comes out when we find the text
  encoded from that D in the diff… `ui/EntropyArrest.svelte` appears if there are
   already rules defined in this test (and a step is open) to CRUD; clicks on snap
    diff lines cause the birth of locators down there, and you can tweak the autogen
     regex; click OK to actually put them in, which auto-saves toc.snap; then
      restart to use them."*

### 4.0 It is EncodingSplatter, grown up

`ui/EncodingSplatter.svelte` is the ancestor — *"almost almost nearly, not the same;
 a placeholder."* It already: groups encode/decode complaints by mainkey, parses the
  offending mainkey + props out of the message, and **generates a lematch snippet**
   (`skip_snippet`, `omit_snippet`) — `{ matching_any:[{mk}], means:{…} }`. What it
    lacks is everything that makes a Snapcap live rather than advisory:

| EncodingSplatter (placeholder) | EntropyArrest.svelte |
|---|---|
| source: encode/decode **errors** | source: diff **noise** (a clicked `Dif:change`) |
| output: clipboard text to **paste into `Text.svelte`** | output: a **`Snapcap` particle** under `The/EntropyArrest` |
| means: `skip` / `omit_sc` | means: `spay` (drop / blank / band) |
| mute is **visual-only**, never feeds `enWaft` | OK **commits + saves toc.snap**; restart applies |

So EntropyArrest.svelte **supersedes** EncodingSplatter for the noise case and can
 lift its group/snippet helpers wholesale. (Whether the encode-error case folds in
  too — same panel, two sources — is a later call; the lematch-snippet machinery is
   identical, only the `means` differs.)

### 4.1 When it shows, and what it does

Shows **iff** the test already has `The/EntropyArrest/Snapcap**` *and* a step is
 open — a CRUD surface for the existing rules (list, edit regex, change spayer,
  delete, toggle scope). It is not a permanent panel; absent rules, absent UI.

Birth of a locator, from a click on a `Dif:change` row:

1. **The row is a `D`** carrying both line sides (`Dif:change` got + its `Dif:prev`
    sibling) and the source particle's identity — `trace_fn` keyed each D on the
     full `the_*` identity and stashed `D.sc.copy = {...n.sc}` (Story.svelte 910,
      955–959). The click has, free: mainkey, sc, and both texts.
2. **Reduce to a minimal locator** — *"reduce a lematch that satisfies the thing,"*
    the same move as `Lang_def_at_offset` (LangRegions 431): a raw positional mark →
     the smallest *intelligible* identity that uniquely resolves. Here: start from
      the full `the_*` identity, drop the noisy key, and narrow to the fewest
       `sc_has` keys that still single out this particle among its siblings (mainkey
        first, then discriminators). Bootstrapping a structural pointer from a click,
         exactly as LangPoint bootstraps a Point from a bookmark.
3. **Autogen the regex.** Diff got vs `Dif:prev` (both in hand): the changed run is
    the noisy number. Offer `(?<=key=)\d+(\.\d+)?` for `blank`, or — duration-shaped
     float — a `band` with `first` = the prev value. The user **tweaks** this regex
      in the panel before committing ("attacking numbers").
4. **OK commits.** Only on OK is the `Snapcap` written under this Book's
    `The/EntropyArrest`. This is the deliberate "click ok to actually put them in" —
     no half-formed rule leaks. (Recurring noise can later be *promoted* to a
      default `story_matching` rule via the copy-to-source snippet, §3.3/§4.0.)

We do **not** live-test the locator/regex in the panel. *"Then probably test how it
 works right there? but we can't really — that's too far."* Verification is the next
  run's diff, not an inline preview.

### 4.2 Saving and the restart boundary

toc.snap *"is not too reactive atm, unless you Accept something."* A `Snapcap` lands
 in `The`, which only persists to `toc.snap` on Accept today. So **OK explicitly
  drives a toc.snap save** (the same write `story_accept` triggers, called for the
   Snapcap edit alone — not a full step accept). The compiled rules (§3.2) are read
    at snap time, so **a restart/re-run is required** for new caps to take — the UI
     says so. Making it hot (recompile + re-diff in place) is a later nicety; the
      restart boundary is acceptable and honest for v1.

"Advice that comes out when we find the text encoded from that D in the diff": when
 the diff renders a line carrying the mirage marker, it draws it dimmed + a hover —
  *"spayed by `want-ts` · reveal raw · edit · undo."* The advice is **stored on
   EntropyArrest keyed by the lematch**, not on the ephemeral per-step D (a D dies
    with its step; the Snapcap persists in `The`) — but the gesture and the
     recognition are both "from this D's text," so it reads as advice on the line.

This is granular, per-situation Resnapture: instead of accepting a whole noisy snap,
 you name one noise source and it's silenced for every step of this test.

### 4.3 The index — every spayed line, leading to its `%spayer`

The diff UI gains a **handy index of every line a spayer touched**, each entry
 leading to its exact `%spayer` (in the EntropyArrest panel or the default set) by a
  **glowy pulse** — click the index entry, the line and its rule pulse in sync, so
   you can see which rule silenced what. This is the contact surface between "the
    noise I'm reading" and "the cap that explains it."

Building the index is the fiddly part, and it's where the §2.4 caveat bites
 concretely. spay applies **per `enLine`**, on the particle as the snap traversal
  found it. But the *diff* runs over the whole `got_snap` string, aligned into
   `Dif:same` / `Dif:change`+`Dif:prev` / `Dif:+` / `Dif:-` rows — each row a
    **from** side (prev) and/or a **to** side (got). So to find the spayed lines in
     the diff we **scan both the from and the to text of every row for the mirage
      marker** ("pick apart from|to from the same|new parts… to find any with holes
       in them"). The marker is the join: it survived from the per-line encode into
        whichever diff cell that line landed in, on either side, regardless of how
         the alignment shuffled. Reverse-map a marked span → the spayer whose `re`
          produced it → the index entry.

This is *why* the marker must be content-impossible (§2.1): the whole index is a
 text-scan for it across the diff, and a false positive would mis-route a pulse.

### 4.4 Shaping the locator — superscript substitution buttons

A fresh `%spayer` opens in **edit mode**, and the panel is *sensitive*: each token
 of the locator carries a **superscript button** to widen or narrow the match
  without retyping a lematch.

- `w:Lies` shows a superscript `*` — click it and the token becomes the general
   `w` (value wildcarded: `{w:1}`); the superscript now reads `Lies`, click it to
    snap back to `w:Lies`. One toggle, both directions, the label always naming the
     *other* state.
- a further step drops the token altogether (stop matching on `w` at all — *"just
   look for `req:wants/want,kind`"*), climbing the lematch toward the leaf that
    actually carries the noise.
- each token is also **directly editable** — type a different value when neither the
   stored one nor the wildcard is what you want.

This *is* the answer to recipe-looseness: the auto-reduced locator (§4.1 step 2) is
 only a starting guess; the superscripts let you *"beat it into shape"* — too tight,
  widen a token to `*`; too broad, pin a value or add a parent — reading the match
   shrink and grow as you go. The `Lang_def_at_offset` reducer proposes; these
    buttons dispose.

### 4.5 Gone parents — clickable while awake, never stored

Reducing or widening a locator walks an ancestor chain, and some of those parents
 will be **gone** — present in the live tree you clicked from but not in the
  committed locator, or vanished from the current step (parent spec §5 ghosts). Keep
   them **clickable at `opacity:0.5` while the session is awake** — so you can climb
    back into a parent you generalised away — but **do not store them** in
     `Story/*/toc.snap`. Only the committed (tightened) locator persists; the faded
      gone-parents are session-scoped scaffolding for shaping, not part of the cap.
       (Same discipline as the parent spec's ghost rows: a gone thing stays a tick,
        interactive, then is not written.)

### 4.6 Don't overload the diff UI

- spaying adds **zero walks** — a richer `means` on the `n.lematch` call `enLine`
   already makes (§3.2). The UI renders pre-spayed lines.
- spay **marks** fold into the line, not extra rows — the mirage dimmed in place,
   not a `Dif:` sibling. A fully-spayed line reads `Dif:same` and *leaves the diff
    entirely*; the §4.3 index is how you still find it.
- the CRUD panel shows **only when caps exist + a step is open**; authoring is a
   click on a row, not a standing fixture.

---

## 5. How this lands against the parent spec

This is a focused, shippable slice of `Story_next_level_spec.md`:

- **§1 (merge the encoder)** → §1 here (Lines), the no-op stage.
- **§4 (acknowledged non-determinism / fuzz classes)** → §2 here. `drop`/`blank`/
   `band` are the concrete fuzz handlers the parent spec sketched as
    `%fuzz,kind:…`. `band` is the parent spec's "is it 10× / surprise>0" made a
     per-line encode rule.
- **§4.3 (TimeSpool trend)** → unchanged; `band` *feeds* it (the blow-out glyph is
   exactly a `surprise` sample).
- **§14.2 (surprise → fuzz-rule-or-Point)** → §4 here is the "acknowledge as fuzz"
   half, given a real authoring gesture.
- Snapcaps are **data**, so they drop cleanly into the eventual `%Interest,Testing`
   framing (parent §13) — an EntropyArrest cap is a per-test declaration like a Point.

What this slice deliberately does **not** do: the Waft/Interest unification (§13),
 channels split (§2 of parent), continuity surfing (§3.2), fern gardens (§6). It
  needs only the Lines merge under it.

---

## 6. Staging

1. **Lines (no-op).** Merge `snap_H`'s loopy pass into `encode_wh_lines`; rename to
    `enLines`; recast `story_matching` as `STORY_PROTOCOL`; route `snap_H` and
     `enWaft` through it. Gate byte-identical on `wormhole/Story/*.snap`.
2. **spay `means`.** Add `spay` to the `means` vocabulary: `enLine` collects
    `q.spay` (beside `omit_sc`/`munging`, Text 668–682) and applies it after
     `parent_line` (721–725); keep the pre-spay text on `q.raw_line`. Implement
      `drop` (re-express one existing mung rule through it to prove parity), then
       `blank` with the mirage marker (teach `peel`/`depeel` the reserved phrase).
3. **Defaults carry spay.** Move the noisiest `story_matching` rules to `band`/
    `blank` spayers through the **same** expand fn — the global layer, in code, no
     store. `self,round` → `band,add_step_mult`. Re-record affected fixtures *once*
      (deliberate noise removal — parent §18 stage 2).
4. **EntropyArrest store + entropy compile.** Per-test `The/EntropyArrest`,
    `Snapcap` shape; Hovercraft `region:entropy` `entropy_rules(The)` → `matching`
     rules with `means.spay` (sibling to `i_scheme_req`/`prandle`); `compile =
      story_matching ∪ entropy_rules(w.c.The)`. `first` set at authoring.
5. **Authoring UI.** `ui/EntropyArrest.svelte`, lifting EncodingSplatter's
    group/snippet helpers: shows iff caps-exist + step-open; click `Dif:change` →
     reduce locator (à la `Lang_def_at_offset`) + autogen+tweak regex; superscript
      widen/narrow buttons (§4.4); gone-parents at 0.5, unstored (§4.5); **OK** mints
       the Snapcap and drives a toc.snap save; restart to apply. No live-test.
6. **The diff index.** Scan both from|to sides of every diff row for the mirage
    marker (§4.3); reverse-map each → its `%spayer`; glowy-pulse line↔rule. Promotion
     snippet (per-test → default) reuses EncodingSplatter's copy-to-source.

Stage 1 is the keystone the user named and is a provable no-op — do it first and
 prove it. Everything after is additive and gated by the same fixtures.

---

## Open / to decide

*Resolved in this pass:* encode-time spay (dige stability, raw kept); EntropyArrest
 is **per-test**, the defaults are the global layer (§3.3); `first` set at authoring,
  not re-nailed (§2.2/§3.3); recipe-looseness is the superscript-button job (§4.4);
   **the marker is `في غيابها كوّنتُ صورتها`** (Darwish), one phrase for every spay (§2.1).

Still open:

- **Marker → spayer reverse-map.** The §4.3 index needs each mirage span to name the
   `re` that made it, and the marker is now uniform across all spayings. So
    disambiguation rides *beside* the phrase: tag it with a tiny cap-id at encode time
     (`…صورتها#7`, still content-impossible) — O(1) at scan — or re-run each cap's `re`
      against the raw line to attribute, keeping the canonical phrase pristine. Lean
       tag-with-id; the UI strips the `#id` when it renders the line dimmed.
- **Hot vs restart.** v1 requires a restart for new caps (§4.2). Recompiling
   `entropy_rules` and re-diffing in place is the eventual nicety; decide if it's
    worth it before the per-test caps see real use.
- **Promotion ergonomics.** Per-test → default `story_matching` is a copy-to-source
   snippet today (§3.3). Whether a default set ever becomes editable *data* (a real
    global `The`) rather than source is deferred — the user explicitly kept defaults
     in code for now.
