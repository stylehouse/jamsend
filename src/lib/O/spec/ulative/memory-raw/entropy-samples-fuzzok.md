---
name: entropy-samples-fuzzok
description: "fuzz-ok loop — caveat taken as ok, computed without pip-open, pushed to Editron green+tagged; NNN-sweep + INLINE-at-check-time (preload exp snaps→forgive between steps) BUILT; EntropySamples.snap lean sidecar still deferred; EntropyArrest.md §10/§10.7/§10.8"
metadata: 
  node_type: memory
  type: project
  originSessionId: 51068ee3-a0db-49a2-b006-299903fab5b8
---

The "sample loop" — make fuzz-ok (a [[entropyarrest-spay-design]] caveat: a dige mismatch whose
 only diffs fall in acknowledged-noise spans) be **taken as ok, computed without a manual pip-open,
  and pushed to Editron** green+tagged. CORE BUILT 2026-06-24 (browser-UNVERIFIED); the lean
   `EntropySamples.snap` sidecar deferred. Status block = EntropyArrest.md §10.7.

**BUILT (3 edits, 4 files, typeclean):** (1) verdict tagging — `Cred_run_outcome` (Auto.svelte)
 +`caveat` count → `Lies_runner_verdict`→`Lies_report_result`→`run_result` frame→`Lies_run_result_recv`
  stamps `%run_result,caveat` → Liesui `≈N` badge. (2) runner flag-and-continue — Story.svelte
   snap_step gate now `!ok && !lenient && !is_runner()` (is_runner = `top_House().c.boot_role==='runner'`);
    runner stamps `step.sc.unexpected=1` + drives on (no fetch/graft, timing rule). (3) post-run
     sweep — `story_sweep_arm`/`story_sweep_next` + a sweep block in the `Story()` belief loop;
      do_step check-completion arms it instead of firing storyFinished, sweep walks `!ok && got_snap
       && !swept` steps one/round, reads NNN.snap (safe post-run), runs the SAME `entropy_forgive`
        the pause uses → `ok+caveat` or `%swept`, then fires storyFinished so Cred_run_outcome reads
         the swept result (no re-push). Editor strict path UNCHANGED (already auto-forgives at pause).

**INLINE-AT-CHECK-TIME BUILT 2026-06-24 (§10.8), browser-UNVERIFIED — fixes "pips solve too sluggishly":**
 the late paths (editor per-step PAUSE+disk-load, runner post-run sweep) did a disk round-trip every
  value-noise step. Now: (1) PRE-LOAD — Story() poll-loop reads every check-mode step's NNN.snap into
   `w.c.exp_snaps` AFTER toc-load+profile-open, BEFORE the drive (returning early gates the drive;
    cleared on toc reload); timing-safe (run hasn't begun). (2) INLINE forgive — snap_step on a dige
     mismatch, if `exp_snaps[n]` cached, runs `entropy_forgive(got,exp,n)` right there → ok+caveat, NO
      pause/round-trip (in-memory graft = µs, can't perturb later steps; §10.1 bomb was the DISK load,
       now at boot); `step.bump_version()` wakes the pip that step. (3) FALLBACKS unchanged — uncached/
        stale fixture → editor pause / runner flag+sweep (load fresh disk = correctness floor, stale
         can't mint wrong green: graft just fails+defers). ⇒ value-noise goes green-with-caveat AS it
          steps; lenient-by-default now sensible. Cost: 1 boot read/step (reads exact-match steps too).

**STILL DEFERRED (the lean cache, §10.2):** `EntropySamples.snap` sidecar write-at-record + prefer-over-NNN
 read (trims boot to ONE file + captures-not-snaps footprint), and the substitution-forgive (spay_graft_line
  variant: stored exp tokens into got, re-dige vs The_step_dige). Pure I/O optimisation — the NNN preload
   above is already correct.

**Verify on :9091** — re-run LakeSurfer headless (?B=LakeSurfer) with a value-noise step: should
 complete (not wedge), Editron Cred shows ✓ N/N ≈k; lenient editor run forgives all value-noise
  steps at completion without pip-opening each.

**Why it was needed:** §5 forgiveness is lazy (only fires at a non-lenient halt or a manual
 pip-open → `e_story_sel`→`fetch_snap`→`check_snap`) and unpushed (verdict = `Cred_run_outcome`
  at storyFinished, computed before any pip-open). So a `Lies%runner` sweep / lenient run finishes
   with value-noise steps red and the editor never sees the later caveat.

**Locked decisions:** both flows via a completion-level fix; editor keeps its live pause, runner
 flag-and-continues + post-run sweep; caveat reads GREEN + tagged forgiven-count (not amber);
  expected values in a new `EntropySamples.snap` sidecar + `NNN.snap` fallback (sidecar is a cache,
   can't mint a wrong green); timing rule is the runner's only — never load a snap mid-run (snaps
    carry the measured numbers; loading between steps perturbs later steps).

**Build map (anchors in §10):** `Cred_run_outcome` (Auto.svelte) +caveat count → `Lies_runner_verdict`
 → `Lies_report_result`/`run_result` frame +caveat → `Lies_run_result_recv` stamp → Liesui ≈N;
  `story_forgive_sweep(w)` new, called in Story.svelte check-mode completion branch BEFORE
   story_save/storyFinished; runner flag-and-continue gate at the mismatch branch (`!ok && !lenient`,
    Story.svelte ~1882) keyed on `Lies_is_runner`/`boot_role==='runner'`; EntropySamples fed from
     `spay_graft`'s graft log (sibling of the §9 number-wander spool). got_snap is already retained
      for !ok steps by the 5-step trim — the sweep needs it.

Terminology: `Lies%editor` = Editron (manages jobs), `Lies%runner` = job receiver/executor; one
 Lies ghost, role via `Lies_role(w)`. NOT renaming "runner".
