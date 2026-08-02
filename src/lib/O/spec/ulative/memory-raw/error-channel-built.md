---
name: error-channel-built
description: Story ERROR CHANNEL built (2026-07-29) — throws→w/%Errlog/%Err at snap seam, fixture-gated; the design's mint-world was WRONG (must be the Book's run world, not the driver Story world)
metadata:
  node_type: memory
  type: project
  originSessionId: 44a600bf-90a8-4f5a-a1f2-7e8fb2c1707a
---

The Story **error channel** (`spec/Error_channel_todo.md`) is BUILT (2026-07-29, all compile-green + bundle-verified,
 svelte-check adds ZERO new errors, UNCOMMITTED). The systemic fix for the silent-failure class the download hunt
  kept hitting ([[instrument-before-guessing]]): a THROW is captured (not the console — Radios warn ~40×/healthy run)
   into `w/%Errlog/%Err` at the snap seam, so the fixture diff gates it. Plan B after the download-memory fix ([[heist-download-crash-ive-got]]).

**THE CRUX the design got WRONG (load-bearing):** it said mint `w/%Errlog` in `Story_plan`. That `w` is the **driver
 Story world — NOT in any got_snap** (verified: `run`/`This`/`The`/`failed_at` never appear in a numbered fixture;
  `story_harvest_desc`'s law "a %desc emitted on the Book's world would leak into the snap" proves the **Book's run
   world `Run→A→w` is the snapped one**). Homing on the driver w would SILENTLY never snap → gate dead. FIX:
    `Story_errlog_world(Run)` = `Run.o({A:1})[0].o({w:1})[0]`; the drain homes the Errlog THERE.

**LAZY-MINT (no mass re-record):** the design's always-present empty `Errlog:1` line would add a line to EVERY
 fixture → whole-suite re-record. Instead the Errlog mints only when the ring is non-empty (a real capture) → a
  clean Book carries ZERO Errlog bytes → NO re-record. Storui synthesises the green ✓ from ABSENCE.

**Mechanism:** `Story_error(kind,where,msg)` = bulletproof capped/deduped ring on top_House (never mutates the tree —
 dodges [[nested-replace-in-do-fn]]). `Story_errlog_drain` moves ring→%Err at the snap seam BEFORE `story_snap` (so
  %Err rides the snap = gate #2, free) + stamps off-fixture `run.sc.err_n/warn_n`. Gate #1 = `failed_at` latch on any
   `kind:error` (`expect_errors`-Opt-gated, no halt). Gate #3 = new-mode dirty-record flag. `The/Opt/{expect_errors:1}`
    lets a Book that tests errors record the %Err clean + stay green.

**Files (uncommitted):** `Story.svelte` (Story_error/Story_errlog_world/Story_errlog_drain + settingoff reset + drain
 call + gates), `Housing.svelte.ts` (beliefs catch + _Aw_think taps, `this.Story_error?.(...)`), `Ghost/N/Peeroleum.g`
  (req_unemit consumer wrapped — a thrown handler is recorded + faulted cleanly, no more serial-inbox WEDGE; fixes
   agent A #1/#3), `Cytui.svelte` (window jserr net feeds it), `ui/ErrlogFace.svelte` + `glass_kinds.ts`/`glass_faces.ts`
    (face by mainkey), `Storui.svelte` (run-bar ✓/⛔/⚠ cell). Proof Book `Ghost/Story/Errchannelation.g` (ErrChannel,
     compiled + in CREDULER_GHOSTS).

**LEFT (needs a live runner):** record + declare + credence-register the ErrChannel Book ([[new-book-cli-record-recipe]]
 [[credence-board-desc-brandnew]] [[verify-via-live-runner]]); one live watch that a REAL belief-loop throw reddens a run.
