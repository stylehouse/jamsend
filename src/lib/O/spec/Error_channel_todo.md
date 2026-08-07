# Error channel — todo

A Story-level channel that is **empty in a healthy run and UI'd as such**, capturing **any error within
 H%Story or H%Run**, snap-visible so a fixture diff catches it, and **gate-able** ("this run raised no
  errors"). The human, 2026-07-29: *"I totally need Errors|warnings to notice in the console or so, we might
   not see them in snap. Story should really have an error channel that should be empty but is UI'd as such."*

This is the systemic fix for the whole silent-failure class the download-stall hunt kept hitting
 ([[Download_stall_handover]]): today an error hides three ways — a swallowed `catch(er){}`, a snap that never
  particles it, a console line nobody watches. The channel closes all three. **NOT a `_spec` yet — the human
   preens it first; I think it's spec-worthy once built + proven.**

## 0. What to get on with next

**BUILT 2026-07-29. PROVEN + RECORDED ON A LIVE RUNNER 2026-08-07 — the channel is now a standing gate.**

**`ErrChannel` is green: 3/3 steps, 0 caveats, 3 declared assertions, 0 gaps.**
 `wormhole/Story/ErrChannel/` now holds `toc.snap` + `001..003.snap`. What the recording actually proved,
  read off the live snaps rather than inferred:
- **Lazy-mint holds.** Step 1's snap contains *zero* `Errlog` lines — an untroubled run carries not one
   channel byte, which is what makes this whole thing free for every other Book (no mass re-record).
- **The capture works end-to-end, into the gated fixture.** Step 3 carries, under the Book's own run world:

      Errlog
        Err,sig:ayabzn,kind:error,where:proof,msg:a deliberate error — …,n:2,count:1
        Err,sig:196wta0,kind:warn,where:proof,msg:a deliberate warning — …,n:2,count:1

   `n:2` = captured at step 2 and drained at that step's snap seam (so the home-world correction below is
    right — on the driver `w` this would have silently never snapped); `count:1` = the ring deduped.
- **`expect_errors` does its job**: the deliberate error records into the fixture without latching the run
   red, so the proof Book proves the channel while staying green.

**Recipe notes for the next brand-new Book** (these cost an hour to rediscover):
- A Book with **no toc runs exactly ONE step**, silently. The step count comes from the recorded toc, so a
   new Book needs a **hand-authored `toc.snap` with one `step…,dige:lie` line per intended step** first
    ([[new-book-cli-record-recipe]]) — `lie` is the "authored not yet recorded" placeholder, and steps
     against it read `ok:0`, correctly.
- `accept` only takes the steps that were **red**. A step that was already tolerated (`dige:lie` → `ok:1`
   with `caveat:1`) is NOT recorded by it and stays un-gated forever. Pin such a step's dige by hand from
    two agreeing runs, then re-run to verify — that is what turned step 1's caveat into a real gate here.
- Credence-board registration needs **no** hand edit: the board derives from `CREDULER_GHOSTS` +
   the recorded fixtures, and the run mints `Credulate/`+`Credulation/` itself.

**Still owed (small):**
- **Live-watch a REAL thrown belief step redden a run.** The Book drives `Story_error` directly, which is
   deterministic and proves capture→snap→gate; it does NOT exercise the `Housing:beliefs` catch. One
    genuine belief-loop throw is still worth seeing.
- The full-suite triage below has NOT been run deliberately (the human de-prioritised suite runs
   2026-08-07). **Partial evidence it will be quiet:** MusuStock 5/5, MusuRename 9/9 and MusuVend 11/11 all
    ran green on 2026-08-07 with this channel live in the tree — so those four Books were swallowing
     nothing. That is not the whole suite, but it is the opposite of alarming.

**Expect on the FIRST full-suite live run: some Books may go red that were "passing" before.** That is the
 channel WORKING, not a regression — a belief-loop throw that was silently swallowed (`Housing.svelte.ts:996`
  was console-only, no step attribution, drive stalled quietly) now particles a `%Err` → dige diff → red. TRIAGE
   each: a real throw is a real bug to fix (the whole point); a genuinely-benign one gets `The/Opt/{expect_errors:1}`
    on that Book (records the %Err clean, run stays green) or the throw source fixed. Do NOT blanket-`expect_errors`
     the suite — that re-buries exactly what this surfaces. [[adversarial-test-agent]] [[snap-data-not-judgement]]

## BUILT — the implementation as landed (2026-07-29)

**The crux the design GOT WRONG (and the fix): the home world.**  The design said "mint `w/%Errlog` in
 `Story_plan` (~1489)".  That `w` is the **driver Story world** — which is **NOT in any got_snap** (verified:
  `run`/`This`/`The`/`failed_at` never appear in a numbered fixture; `story_harvest_desc`'s own law —
   *"a %desc emitted on the Book's world would leak into the snap"* — proves the **Book's run world** `Run→A→w`
    is the snapped one).  Homing the Errlog on the driver `w` would have SILENTLY never snapped → the whole
     gate #2 dead.  **Fix:** `Story_errlog_world(Run)` returns the Book's run world (`Run.o({A:1})[0].o({w:1})[0]`),
      and the drain homes the Errlog THERE.  This is the load-bearing correction.

**LAZY-MINT (no mass re-record).**  The design's always-present empty `Errlog:1` line would have added a line
 to EVERY Book's fixture → a whole-suite re-record.  Instead the Errlog is minted only when the ring is
  non-empty (a real capture): a clean Book carries **zero** Errlog bytes → **no re-record**.  Storui synthesises
   the calm green `✓` from the channel's ABSENCE (same "empty in health, UI'd as such" UX, no snap byte).

**`expect_errors` opt.**  `The/Opt/{expect_errors:1}` lets a Book that DELIBERATELY tests error-capture record
 the `%Err` into its fixture (the dige diff IS the proof) without latching the run red — so the proof Book
  stays green while proving the channel works.  Every other Book reds on any captured error.

**Files (all uncommitted):**
- `Story.svelte` — `Story_error` (capture door: bulletproof, capped/deduped top-House ring), `Story_errlog_world`
   (the run-world resolver), `Story_errlog_drain` (ring→%Err at the snap seam BEFORE `story_snap`; stamps
    off-fixture `run.sc.err_n/warn_n`); the ring reset + `err_run` in `Story_settingoff`; the drain call before
     `story_snap`; gate #1 (`failed_at` latch on `kind:error`, `expect_errors`-gated), gate #3 (new-mode
      dirty-record flag).  Gate #2 (the dige diff) is FREE — `%Err` rides the snap.
- `Housing.svelte.ts` — `Story_error?.(...)` from the beliefs catch (the single biggest swallow) + `_Aw_think`.
- `Ghost/N/Peeroleum.g` — `req_unemit` consumer call wrapped: a thrown handler (the `Repli_merge` nested-replace
   vector) is recorded + faulted cleanly instead of WEDGING the serial inbox (fixes agent A #1/#3). gen compiled.
- `Cytui.svelte` — the existing window `jserr`/`unhandledrejection` net also feeds `Story_error('error','window',…)`.
- `ui/ErrlogFace.svelte` + `glass_kinds.ts` + `glass_faces.ts` — the face (calm green empty, red w/ count+latest
   lines), imposed by mainkey (no snap byte to dress it).
- `Storui.svelte` — the run-bar `✓/⛔/⚠ N` cell (reads `display.run_sc.err_n/warn_n` via the `story_analysis`
   run_sc spread).
- `Ghost/Story/Errchannelation.g` (+ CREDULER_GHOSTS) — the `ErrChannel` proof Book (compiles; needs recording).

### (original design follows — its mint-location + always-empty-line guidance is superseded by the two notes above)
Build order was: the ring + `Story_error` helper + `%Errlog` mint + drain in `Story.svelte` → the two Housing
 taps → the Cytui tap → the face + glass registration → Storui cell → the `req_unemit` wrap → a PROOF Book.

## The one correction that shaped the design
**Do NOT tee console into the channel.** `Ghost/ghost/Radios.svelte` emits ~40 `console.warn/error` during
 HEALTHY streaming — a tee floods the channel, "empty in health" and the gate die on arrival. Capture the
  INVISIBLE class — **throws** — plus the global-uncaught net. Leave deliberate operational warns in the
   console. (A console tee is at most an opt-in `The/Opt/{tee_console:1}`, default OFF.)

## Design (verified file:line in the design-agent transcript)

**No channel exists today** — four partial pieces, none snap-visible/gating: Cytui window-net
 (`Cytui.svelte:341-347`, `.c`-only, never snapped); Housing beliefs catch (`Housing.svelte.ts:980-1001`,
  console.error only — the single biggest swallow); `_Aw_think` error stamp (`Housing.svelte.ts:1342-1350`,
   a real proto-channel but one-seam/uncapped/un-UI'd); `step.sc.error` (`Story.svelte:2406`, audio-timeout
    specific). **`caveat` is the WRONG thing to extend** — it's EntropyArrest fixture-forgiveness, not "code
     threw". Story does NOT today distinguish "assertion failed" (dige mismatch → red, normal) from "code
      threw" (caught at Housing:994 → console only, **no step attribution, drive silently stalls**). The
       channel is exactly that missing second category.

**Mechanism — ring-then-drain-at-snap (the crux):**
1. A capped `.c` ring on top_House — `M.c.err_ring`, the `Radio_trace`/`supply_trace` idiom (push a tiny
    `{kind,where,msg,at}`, splice at cap ~120, `.c`-only so it NEVER throws and never touches the tree
     mid-mutex). Dedup by signature `(kind|where|msg)` → `count++` (a per-beat thrower is one row, not N).
2. `Story_error(kind, where, msg)` helper pushes to the ring. Bulletproof (never throws). Wire into the
    HIGH-VALUE catches only (most throws funnel through one place): `Housing.svelte.ts:996` (beliefs catch —
     captures do_step/snap_step/req pumps/mutex-driven Peeroleum drains), `Housing.svelte.ts:1345` (`_Aw_think`),
      `Peeroleum.g:685` (wrap `req_unemit`'s consumer call so a thrown handler is RECORDED **and** the inbox
       req is properly finished/faulted — **this fixes the strand/wedge landmine as a bonus**).
3. Reuse Cytui's EXISTING `window` net (`Cytui.svelte:341-347`) for the truly-uncaught (`poll_step`'s
    bare-`setTimeout` throw, render-effect tears) — have its `jserr` handler ALSO call `Story_error`. One net.
4. **Drain the ring → `%Err` particles at the snap seam** (mirror `step.sc.Run_trace = Run.trace_drain()` at
    `Story.svelte:2379`), in `snap_step_after_wave` before `story_snap`. Tree mutation happens ONLY here, the
     safe seam — never from inside a catch/mutex (dodges [[nested-replace-in-do-fn]]).
   Active-run scoping: `M.c.err_run = run` set at `do_step` first entry (~`Story.svelte:2174`), cleared at run
    end; while set the drain routes into that run's `%Errlog`.

**C-tree — home = the Run world `w` (H%Run)** (snap-visibility: `snap_H` walks from the Run House,
 `Story.svelte:1255`; the Story world is not in the per-run snap, so Story-world throws route into the active
  run's Errlog via the ring). Mint once in `Story_plan` (~1489):
```
w/%Errlog:1, face:'Errlog'
   /%Err:1, kind:error, where:beliefs, msg:"Cannot read x of undefined", n:2, count:1
   /%Err:1, kind:warn,  where:window,  msg:"…",                          n:3, count:4
```
Fields are clean scalars only (`msg` sliced ≤140, **commas/newlines stripped** — the peel parser splits on
 commas, [[see-assertion-layer]]); `at` rides `.c` (keep timing OUT of sc so the fixture diff is about the
  error's IDENTITY). Snapped-boolean rules ([[delete-sc-key-safe]]); cap ~50 via drop→compact
   ([[drop-leaves-index-giant-stuff]]). Minting the empty `Errlog:1` line means a clean fixture always carries
    exactly that stable line — proof it was watched and empty; any `%Err` child is an `is_new` diff → red free.

**Face — `ui/ErrlogFace.svelte`** (model on `RadioFace.svelte`; register kind in `glass_kinds.ts`, impose by
 mainkey via `glass_faces.ts:FACE_MAINKEYS` so no snap bytes change to dress it): calm `✓`/"no errors" green
  when empty; red with count + latest 2-3 msgs (⛔ error / ⚠ warn) when not. Same loud-when-broken posture as
   the `.face-err` tile ([[vytui-face-crash-shows-ident]]).

**Gate:**
1. Built-in run verdict (every Book, no authoring): at the snap seam, if the run gained any `kind:error`, set
    `run.sc.failed_at = n` exactly like the dige-mismatch path (`Story.svelte:2464`) → run bar red
     (`Storui:563/1247`), `Cred_run_outcome` reports it. Covers "ANY error within H%Story or H%Run".
2. Snap-diff gate (free): `%Err` lines are `is_new` → `check` mode fails the step's dige. Belt + braces.
3. **`new`-mode dirty-record guard (important):** a RECORDING run that threw must NOT silently bake `%Err`
    into the fixture — refuse/flag ("recorded with N errors — not clean") so a dirty record can't become the
     accepted baseline ([[adversarial-test-agent]], [[snap-data-not-judgement]]).
4. Optional standing `%see:'the run raised no errors'` (durable `%Assertion` via `story_swear`) — sugar for
    the sworn explorer / credence board.
**Errors gate red; warnings SHOW but do NOT fail** (warnings are frequently benign-operational here — failing
 on them re-creates the flood problem). A Book that cares asserts `%see:'the run raised no warnings'`.

## Implementation plan (extend Story — do NOT add a ghost)
1. `Story.svelte` — `Story_error`+ring helper (copy `Radio_trace`); mint `w/%Errlog:1` in `Story_plan`;
    set/clear `M.c.err_run`; ring→`%Err` drain in `snap_step_after_wave` beside `Run_trace`; the `failed_at`
     verdict + the `new`-mode dirty-record guard; optional standing `%see`.
2. `Housing.svelte.ts` — call `Story_error` from the beliefs catch (996) and `_Aw_think` (1345). One line each.
3. `Ghost/N/Peeroleum.g` — wrap `req_unemit`'s consumer call (685): record a thrown handler AND still
    finish/ack/`%faulty`. Fixes the strand/wedge. `ghost-compile` after. (Coordinate with A#3 recv-wrapper
     honesty.)
4. `Cytui.svelte` — the existing `jserr` handler also calls `Story_error('error','window',m)`. No new listener.
5. `glass_kinds.ts` + new `ui/ErrlogFace.svelte`; add `Errlog` to `glass_faces.ts:FACE_MAINKEYS`.
6. `Storui.svelte` — a run-bar cell beside `sworn …` (~1239): `err N` red when the run's Errlog is non-empty.

**Proof Book** ([[testing-is-story-books]], [[new-book-cli-record-recipe]]): Step 1 clean → assert the channel
 is empty (bare `Errlog:1` line). Step 2 a req do_fn that **deliberately throws** + a `Story_error('warn',…)` →
  assert the channel goes non-empty, a `%Err,kind:error,where:beliefs` appears, the run cell reddens, and the
   built-in verdict flips `failed_at` (**prove the gate can FAIL**, [[adversarial-test-agent]]). Step 3 clean
    again. Register on the credence board ([[credence-board-desc-brandnew]]); `git checkout` accidental
     re-records after verify ([[live-runner-persists-fixtures]]). Semantics: **cumulative** per run (one throw
      taints the whole run's verdict, matching `failed_at`) — document it.

## Load-bearing notes
- Ring-then-drain-at-snap is the crux: a catch records by pushing a plain object, NEVER by mutating the tree in
   place (the nested-replace-in-do-fn hazard). Tree mutation only at the snap seam, where `trace_drain` already
    safely does it.
- Home on the **Run world `w`**, not the Story world — the fixture-diff gate depends on `snap_H` walking the
   Run House.
- The primer's `The/OtherStuff` bucket does NOT exist; real `The` buckets are Steps/Styles/Plan/Opt/Hygiene/
   TimeSpool. The Errlog goes under `w`, not `The`.
