# Spool — workingout of §8 (+ §4's replay claim)

Working doc, 2026-07-19.  Elaborates Vyto_spec §8 (moments, the o-mark, blessing) and the
 §4 sentence it must make true: *the choreography between two spool moments is derivable
  from their diff*.  Everything here was checked against the live encoder, verdict and
   seek code; where the spec's wording and the code disagree, the code won and the
    disagreement is called out.

One correction up front, because it shapes the whole doc: **the spec says "enWaft
 payload" but fixtures do not come from enWaft.**  The text a Story fixture carries is
  `snap_H` (Story.svelte ~1253) — a Selection walk stamping `snap_line` per particle via
   `story_process_node`/`enL`, with entropy drops, `%boring` pruning and loopy-ref stubs —
    wrapped by `story_snap` (~1380) in a `Snap:H` header at depth 0.  `enWaft`
     (Text.svelte ~351) is the *wormhole document* codec: a front-end for
      `encode_wh_lines` whose protocol attaches `omit_sc` session-key stripping.  A
       moment that wants to be diffed against an expected fixture must ride the
        **snap_H path**, or every diff carries systematic shaping noise.  §8's "enWaft
         payload" should be read loosely as "the snap encoding"; concretely it is snap_H.

## 1. The row — %Moment

One capture is one particle under the spool holder in `w:Vyto` — off the run snap, since
 the glass world sits beside the Run House, but shaped as if it could be snapped anyway
  (the habit laws hold: booleans 1-or-absent, no undefined stamps, no objects in sc).

> ```
> w:Vyto
>   %Spool                          — the ring holder; frozen:<n> while evidence is held
>     %Moment,yore_n:12,step_n:4,dige:9f3a21c8,at:1752913
>     %Moment,yore_n:13,dige:0aa1b2c3,at:1752921,o:1,wild:1
>     %Moment,yore_n:15,dige:77e0d1f2,bless:first-friend,sentence:the grant sealed — both ends hold it
> ```

Field by field:

- **`yore_n`** — monotonic capture counter, never reused, bumped per kept moment.  It is
   identity, not position: drop-oldest leaves holes and the scrubber walks the *existing*
    rows in yore_n order.  (This is the counter Sounditron_todo §4a already called
     `w.c.yore_n` — same animal, now owned by the Spool.)
- **`step_n`** — the quantize-lock to Story steps.  Stamped **only when a step was in
   flight** when the capture's scan burst began (rules in §4 below).  When no step is in
    flight the key is **absent** — never stamped undefined; this codebase brands an
     undefined sc stamp `{"undef":[…]}` at encode and treats it as a mint bug, and
      Sounditron_todo §4a already carries the law verbatim: *NEVER stamp step_n
       undefined*.
- **`dige`** — `await dig(payload)` ($lib/Y.svelte — the same digest `snap_step` uses at
   Story.svelte ~2311).  Lets the ring dedup (§2) and lets a Situation judge landmark
    nearness cheaply before paying for a full diff.
- **`at`** — wall-clock ms, for the human's tooltip.  Fine here precisely because the row
   never reaches a fixture; if a moment ever does get snapped, `at` is a ready-made
    EntropyArrest `{INT}` case.
- **tags** — free sc words, value 1 (`wild:1`, `hover:1`).  They share the sc namespace,
   so the reserved keys (`Moment, yore_n, step_n, dige, at, o, bless, sentence, forced`)
    can never be tags.  No commas in a tag word.
- **`o:1`** — the o-mark.  Present or absent, never 0.  Un-marking **deletes** the key
   (via `r()`/replace, the tracked path — not a raw delete for delete's sake, though
    `delete n.sc.key` is query-safe here).
- **`forced:1`** — set on any capture not triggered by a clean %Settle (the run-fail
   evidence grab, an o-tap on a not-yet-settled present).  Absent on the normal path.
- **blessing** adds **`bless:<name>`** + **`sentence:`** (no commas — em-dashes; the
   assertion sentence laws apply because the peel parser splits fields on commas) and
    **`.c.microsnap`** — the `story_microsnap` idiom (Story.svelte ~250: sync, depth-cap
     3, no loopy bookkeeping) aimed at what the landmark is mainly *about*.

### The payload rides `.c.snap` — decided, and why

The big string goes on **`.c`**, not sc.  The row lives in w:Vyto which is off-snap, so
 snap size is not the deciding argument — these are:

- **`exactly(sc)` stringifies the whole sc.**  Any exact-match query against a Moment row
   would serialize a multi-KB payload per comparison.  Rows in a ring get queried
    constantly (drop-cull sorts, seek lookups, step→yore mapping); the payload must not
     be in the comparison surface.
- **Trace identity is built from every sc key.**  `snap_H`'s `trace_fn` does
   `Object.fromEntries(Object.keys(n.sc)…)` — any generic Selection/Travel pass that ever
    touches the row would fold the payload into identity.
- **Stuffing/MiniWaft render sc.**  A Moment row should be *legible* in any generic
   viewer: its provenance and marks, not sixty screens of snap text.
- Precedent cuts both ways — `Step.sc.got_snap` is a big string in sc, `%sworn` puts its
   microsnap on `.c` — and the `.c` side of the precedent is the right one to extend: a
    Step is opened deliberately and rarely; a Moment is machine-handled sixty at a time.

Same logic, applied twice more: the **fold/face summary** (§2) splits into small legible
 scalars on sc and a structured object on `.c.view` (an object value in sc is fatal at
  encode and dirty even off-snap); the blessed **microsnap** rides `.c.microsnap` as it
   already does on %sworn.  Rule of thumb the Spool obeys everywhere: **sc is for what a
    query or a strip needs; .c is for what only display and diff need.**

## 2. The capture pipeline at settle

The Spool is a chronicler: it reads %Settle ticks and writes moments (spec §9).  Capture
 runs **off the watch flush — never inside a beat**: `snap_H` awaits a Selection walk,
  and the Sounditron lesson stands (never await unbounded work under the beliefs mutex).
   Story's own `snap_step` runs via `post_do`; the Spool captures the same way.

> the exact calls, and the one change they need:
> ```
> on %Settle (post_do):
>   Run  = the commissioned Run House (the world the grapples feed)
>   w    = the Story world WHEN this Vyto serves a Book — snap_H reads entropy
>          rules + %boring/%dontSnap shaping off w.c.The; a resident glass
>          (BigSoundland) passes no w and gets the unshaped walk
>   Se   = vyto_w.c.spool_Se ??= new Selection()     ← the Spool's OWN Selection
>   body = await H.snap_H(Run, w, Se)                ← Se param DOES NOT EXIST YET
>   text = H.enL({ d:0, stringies:{ Snap:'H' } }) + '\n' + H.snap_indent(body, 1)
>   dige = await dig(text)
>   if dige === prev.sc.dige && same step_n && !forced:  no row — a settle that
>          changed nothing mints nothing (Sounditron §4a: a moment is a MEANINGFUL
>          state change, not a clock tick)
>   else mint %Moment; cull (§3)
> ```

**The Se parameter is load-bearing.**  Today `snap_H` hardwires `Run.c.snap_Se ??= new
 Selection()` — a *traced* Selection whose `traced_fn` stamps `changed`/`is_new` against
  the previous walk.  If the Spool shared it, every between-steps capture would advance
   Story's trace baseline and quietly eat the change-stamps the next real `snap_step`
    would have seen.  So: parameterize (`snap_H(Run, w?, Se?)`, defaulting to the current
     behaviour — a one-line seam) and the Spool brings `spool_Se`.  Bonus, free of
      charge: the Spool's own trace now stamps `changed` per line per capture — a cheap
       "what moved since the last moment" without paying for a text diff.

Wrapping the body in the same `Snap:H` header + indent as `story_snap` makes a moment's
 payload **byte-shape-identical to the Snap:H block of a fixture** — that is the whole
  game for §5's fixture forensics.  Moments never carry a `Snap:cytowave` block (Vyto has
   no waves; §12 retires them from fixtures too).

### What else a moment carries — the view summary

Voro folds, crews, tuner mutes and worn faces are all c-side in the live world, so
 **they never reach the payload** — snap_H cannot see them.  The summary is how the
  *imposed view* gets remembered, and it must be sufficient to re-impose at seek time:

> - sc, for the strip and for queries: `fold_n`, `face_n`, `mute_n` — counts only.
> - `.c.view`, structured, for seek re-imposition and view-diffing:
>   `{ folds: [fold-root identities], crews: {crew: shown|hidden}, mutes: […],
>      faces: [worn sc.face values] }` — identities as the same strings the payload
>       lines carry, so view and model diff in one vocabulary.

## 3. The ring

**`YORE_CAP = 60`, drop-oldest.**  After each mint: collect rows where `!o && !bless`,
 sort by yore_n ascending, drop from the front while the *total* row count exceeds the
  cap.  Dropping detaches the row from %Spool (the sweep iterates a fresh `o()` snapshot
   — the same detach-never-corrupts-iteration seam the req cull uses).

**o-marks are exempt, with a cap: `O_CAP = 24`.**  Generous — nearly half a ring of
 keeps — but a hard wall so the o-shelf never becomes a second unbounded ring.  At the
  wall the o-tap **refuses visibly** (the board's `o` button shows `24/24` and shakes)
   rather than silently dropping an older mark: an o-mark means *we saw it*, and the
    system un-seeing one on its own would break the word.  The human releases one or
     blesses one; blessed rows leave the o-accounting.

**Blessed rows are exempt and uncapped** — blessing is a human act and naturally scarce.

**Freeze on run-fail — evidence survives.**  How a failed run actually looks in code,
 all three shapes:

> - editor mismatch: `run.sc.failed_at = n`, `run.sc.paused = 2`, `run.c.driving =
>    false` (Story.svelte ~2398-2411); disk-drift via poll_check lands the same shape
>     (~2448-2459).
> - runner flag-and-continue: **no failed_at mid-run** — the straggler step gets
>    `step.sc.unexpected = 1` (~2416) and the drive goes on; the post-run sweep either
>     forgives (ok + caveat) or leaves `sc.ok` false.
> - the untried verdict: `w.c.step_blocked` (the step never got its audio voice — a
>    distinct !ok).

So the Spool freezes when **any** of: `run.sc.failed_at` appears; a Step lands with
 `!sc.ok` (covers `unexpected`); `w.c.step_blocked` is set.  Checked at each capture
  plus on the run particle's watch flush — the Spool already grapples the run for
   step-provenance (§4), so no new wiring.  Frozen state: `%Spool` wears
    `frozen:<step_n>` (the offending step; a scalar, peel-safe).

While frozen: **no drops** — and capture *continues*, because overtime forensics wants
 the post-fail moments too.  The growth is bounded: at `2 × YORE_CAP` total rows the
  Spool stops minting unmarked moments (o-taps and blessings still land) and badges the
   board.  Evidence is never traded for tidiness; tidiness just stops accruing.

Unfreeze on any of: `failed_at` deleted (story_accept does this at ~857/~903/~1822); a
 new run starting; the human explicitly (the board).  On unfreeze, cull immediately back
  to cap.

## 4. The two clocks

**The scrubber walks `yore_n`** — every kept moment, holes and all.  **Story pips seek
 by `step_n`** — the quantize-lock: a pip click lands on the *last* moment stamped with
  that step (the settle that concluded the step's truth), not the first.

Stamping rules, from the code's actual in-flight markers:

- A step is in flight while `run.c.driving` is true; the current step is `run.c.step_n`
   (set at do_step, Story.svelte ~2123).  **`run.c.step_n` persists after the drive
    stops** — it is *not* cleared — so `driving` must gate the stamp or every overtime
     moment would wear the last step's number.
- Provenance is latched **when the scan burst begins**, not at settle: the settle that
   answers step N's changes may land while step N+1 is already driving.  The Spool notes
    `(driving, step_n)` at the watch flush that triggers the scan; if several scans
     coalesce during one flight, the **latest** latched step wins (the settled state
      reflects the latest truth).
- If the latched provenance has no step (drive stopped, paused, pre-run): **yore_n
   only** — the key is simply never written (the album/body_hash guard idiom: `if (x !=
    null) row.sc.step_n = x`).

**Overtime** is therefore not a mode, just the absence of the lock: captures keep
 arriving at every meaningful settle, numbered by yore_n, unstamped by step_n.  The
  strip shows them past the last pip-aligned tick — the region where the old glass
   fossilised and the new one keeps chronicling.

## 5. Diffing — one machinery, three comparisons

The Storui diff stack is already exactly what the Spool needs, and it is **pure text
 functions on H** — despite Storui's header comment, they live in **Text.svelte**
  (`#region diff`, ~1094 on; the comment's "Textures.svelte" is stale):

> - `H.compute_diff(left, right)` — line-level DMP diff, lines normalized to canonical
>    stringies+objecties JSON for alignment, **original lines substituted back** into
>     the rows (Text.svelte ~1161).
> - `H.char_diff_ops(a, b)` — char-level DMP with `diff_cleanupSemantic` (~1118).
> - `H.squish_context(rows)` — collapses same-runs while **preserving the ancestor
>    chain** above every change (~1243).
> - `H.positional_diff` — the no-resync variant (Storui's `exp_naive` mode).
> - `enDif`/`deDif`/`depth_of` — the Dif codec, for copy-out.
> - the spay glow: `H.collect_spayers`, `H.entropy_rules(The)`,
>    `H.spay_classify_line(got, exp, spayers)` (Storui ~119-134) + the EntropyArrest
>     panel — acknowledged-noise marking on changed rows.
> - DiffRow kinds `pair | left_only | right_only | squish`; `ops_for_display` stays
>    render-side in the strip component.

Three comparisons, same rows:

- **Moment N vs N−1** — Storui's `prev` mode verbatim: `compute_diff(prev.c.snap,
   cur.c.snap)` → `squish_context` → panel.  The default panel when scrubbing.
- **Moment vs EXPECTED fixture** — overtime forensics: how far has the living world
   drifted from the last proven state?  Reference = the frontier step's fixture,
    fetched exactly as Storui does (`step.sc.exp_snap`, queued via `run.sc.fetch_snap`
     — the e_story_sel path, Story.svelte ~823-829).  Diff **only the `Snap:H` block**
      of the fixture (fixtures of useCyto Books also carry `Snap:cytowave`; moments
       never do).  The spay glow rides along, so acknowledged value-noise reads as
        noise here too instead of as drift.
- **Moment vs blessed landmark** — the Situation's "substantially here again": `dige`
   equality first, then a spay-forgiving diff whose changed-row count is the nearness.

### What the diff must preserve — §4's replay claim, made concrete

*Choreography between two moments is derivable from their diff* holds only if the diff
 preserves **identity per cell** — enough to compute enters, leaves and moves:

1. **DMP alignment, never positional.**  A `pair`-changed row means *the same particle,
    changed* → a morph; `left_only` → a leave; `right_only` → an enter.  A positional
     diff misreads one insertion as N phantom changes — a false mass-move on the glass.
2. **Original line bytes preserved.**  `compute_diff` already substitutes original
    lines back after normalized alignment — required, because cell identity must derive
     from the same bytes Scan derives it from.
3. **Ancestry available.**  An enter *grows from the parent seam* (§4), so choreography
    needs each row's parent chain — `squish_context`'s ancestor walk provides it, but
     the choreographer consumes the **un-squished** rows (squish is a display economy,
      not a truth).
4. **Deterministic cell identity from line identity.**  The constraint lands on
    **Scan**, not the diff: the cell for a particle must be a stable function of the
     particle's snap-line identity (mainkey + identity sc keys + ancestry) — *not* a
      per-scan counter the way `cyto_assign_ids` renumbers per walk.  Same line, same
       cell, across any two moments; then diff rows map one-to-one onto cell verbs and
        the same rows the panel shows as bytes replay as motion.  Known limit, accepted:
         two siblings with byte-identical lines are interchangeable to the diff — and
          visually interchangeable on the glass, so nothing observable is lost.

Char ops refine a morph: which sc key changed names which channel animates (via
 Express) — `dose` moved → area tween; a tag flipped → face swap; value noise under a
  spayer → no motion at all.

## 6. The seek protocol — display-only time travel

Carried forward from Cyto's good bones (`cyto_update_wave` triggers 1/2, Cyto.svelte
 ~215-310; `e_Cyto_seek` ~338): seek state cached c-side per world; **while `open_at`
  is set, live pushes are suppressed** (Cyto: the wave-push is gated `if (!open_at …)`);
   `seek null` returns to live (latest archive); adjacency (|Δ| = 1) gets the walking
    morph while far jumps go absolute; a missing target lands a visible
     `seek_warning`, never a throw.  One Cyto habit is *not* carried: CytoStep archives
      a live C ref in sc (`w.i({ CytoStep:1, step_n, C: topC })`, ~245) — never encoded
       so never fatal, but against the law; Vyto keeps hydrated trees on `.c`.

The Vyto version:

> - `%Seek` furniture under w:Vyto: `open_at:<yore_n>` while parked — key **absent**
>    when live (the live latch is the absence; never `open_at:0`/null-stamped).
> - `e_Vyto_seek {open_at}` — native clock, a yore_n.  Cache, then display update.
> - `e_Vyto_seek_step {open_at}` — the Storui bridge.  Today Storui dispatches
>    `H.feebly_i_elvisto('Cyto/Cyto', 'Cyto_seek', { open_at: display.open_at })`
>     (Storui ~1013) where open_at is a **step number**; §12's whichever-glass seam
>      routes it here, and the shim maps step → the last %Moment with that `step_n`.
>       No moment for the step → nearest earlier + the seek_warning idiom.
> - Seeking **decodes, never resumes**: the payload text hydrates (deL) into a
>    display-side mirror on `.c`, cells assemble from the mirror, `.c.view` re-imposes
>     folds/crews/mutes.  The Run House is never written; the C** state of the run is
>      never rewound.  Time travel is a rendering of evidence.
> - While parked: **capture continues** — the chronicle never stops — but display
>    follows nothing; the whole view is one big Hold with a "live" release (§3's
>     landmark-hold governs; seek beats everything but the human's own gestures).
> - Moving between moments while parked: adjacent steps choreograph via the diff (§5)
>    — the replay claim, cashed.  Far jumps assemble from the target payload as one
>     shift transaction with enters along the pelt — absolute, but still never
>      relayout-from-nothing.
> - `seek null` → live: choreograph from the parked moment to the latest settle via
>    their diff — returning to the present is itself an explained shift, not a cut.

## 7. The strip — Vytui's data contract

The strip is the Spool's face: a scrubber lane below the glass, o-dots and bless-marks
 riding it (the pip-diamond idiom Storui's `sr-amark` already renders).  Everything it
  needs per tick is sc-side on the rows plus a little spool state — no `.c` reads in
   the render path:

> per %Moment row: `yore_n` · `step_n?` (absent = overtime tick) · `dige` (short,
>  tooltip) · `at` (tooltip clock) · tag words · `o:1?` · `bless:<name>?` +
>   `sentence:?` · `forced:1?` (settled-vs-forced marker — forced ticks render
>    hollow-edged, the way a hollow pip already reads as "not proven").
>
> spool state: `frozen:<n>?` (freeze banner + reason) · row count vs `YORE_CAP` ·
>  o-count vs `O_CAP` (the `24/24` refusal display) · ceiling-reached badge (§3).
>
> seek state: `%Seek.open_at?` — which tick is parked (highlight), absent = live
>  (follow the newest settle; the board's **live** word shows which).
>
> derived, computed strip-side: step tick-marks grouped by `step_n` so the lane
>  visually quantizes under Storui's pips; the current diff panel selection
>   (moment vs prev | vs fixture | vs landmark) mirrors Storui's mode-button idiom.

Vytui receives `H` and the commissioned `w` (Storui's props pattern) and reads the rows
 with `ob()`-style version tracking; the Spool bumps %Spool on mint/drop/freeze so one
  subscription drives the lane.

## Open questions

- **Do blessed landmarks survive reload?**  w:Vyto is runtime-only, so today a blessing
   dies with the tab.  The invite ledger precedent (`H.stashed`) would carry
    `bless + sentence + dige + microsnap` (not the full payload) across reloads —
     wanted, or is a landmark a session creature until it graduates into a %Situation?
- **`snap_H(Run, w?, Se?)` parameterization** — the one-line seam in Story.svelte the
   capture path needs (own Selection, so Story's trace baseline stays virgin).  Core
    Story surface, so: the human's seam to cut, or to bless being cut.
- **Caps**: `YORE_CAP 60` is from the spec; is `O_CAP 24` the right generosity, and is
   the frozen-growth ceiling at `2 × YORE_CAP` acceptable for long runner Books that
    flag-and-continue past an early failure?
- **Should a runner's flag-and-continue failure freeze at the first bad step** (maximum
   evidence, bigger ring) **or at run end** (one freeze, smaller ring)?  This doc says
    first bad step.
- **Scan's identity rule** (§5.4: cell identity = stable function of line identity) is
   asserted here but belongs to the Scan workingout — flagging the dependency so the
    two docs don't drift.
