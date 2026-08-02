---
name: force-clean-rerecord
description: "accept won't rewrite a caveat-ok step (accepting:0) — to force a clean caveat:0 fixture, reset the toc.snap to lie diges + delete the numbered snaps, then re-dispatch (the runner re-reads the toc → all RED → accept records fresh)"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 0da3cb3b-d094-4c32-8e27-daa138a39d1f
---

`runner_ask.mjs accept` only re-records steps that are RED. A step that differs only within
 tolerance is **taken-as-ok (a caveat)** and accept SKIPS it — it reports `accepting:0` and the
  fixture on disk keeps its stale value. So if a fixture recorded a benign wobble (e.g. `self,round=5`
   captured on a coldish accept-rerun while warm runs give `round=4` — the `mung:age` mask does NOT
    cover the belief-loop `round` counter), every later run caveat:1s against it and accept will
     NOT fix it.

**Why:** a deterministic in-memory Book (no EntropyProfile) SHOULD hit `caveat:0` like its siblings
 (MusuVend/MusuRename did). MusuVend/Rename only got caveat:0 by luck — their `round` happened to
  match. A `caveat:1` that is purely a `self,round` ±1 is the benign quiescence-margin wobble
   ([[pere-books-total-1]] "round= ≈"), GREEN overall — but worth cleaning for a determinstic Book.

**The force-clean-re-record (MusuRecast, 2026-07-14):**
1. `rm wormhole/Story/<Book>/0*.snap` (the numbered fixtures) and rewrite `toc.snap` back to the
    `dige:lie` seed (Styles/Plan/Opt/For header + `step,dige:lie` × N).
2. Re-dispatch the Book. The runner **re-reads the toc on dispatch** (become_book) — confirmed live:
    an already-acquired Book picks up the reset toc, so all steps go **RED vs lie** (NOT caveat).
     (This is distinct from the brand-new-Book total:1 seed→reload bomb — that needs a tab reload
      because the Book was never acquired; a Book already run re-reads fine.)
3. `accept` now records ALL steps fresh (`accepting:12`) from the current WARM steady state.
4. Confirm run(s) → `caveat:0`. Do it warm/warm (a thaw run first) so the recorded round matches
    the confirm round.

So: **accept can't lower a caveat; only a lie-reset + clear can.** Use it to turn a benign-but-noisy
 fixture into a clean caveat:0 baseline — don't hand-edit the snap (the round can still wobble; a warm
  re-record settles it). [[entropy-samples-fuzzok]] [[verify-via-live-runner]]
