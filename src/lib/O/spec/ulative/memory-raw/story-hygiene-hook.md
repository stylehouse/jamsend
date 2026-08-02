---
name: story-hygiene-hook
description: "NEW Story primitive The/Hygiene/%Reset — an opt-in pre-step-1 disk sweep (an Assertion's inverse); PROVEN; the nav-FSA-cache gotcha; Sounditron is the WRONG first customer"
metadata: 
  node_type: memory
  type: project
  originSessionId: 2f2e32df-77de-4509-9ea4-3454f9ecd5a7
---

**`The/Hygiene/%Reset,path:<disk path>` — a NEW Story primitive (BUILT + PROVEN live 2026-07-26).**
A Book that declares a `The/Hygiene` bucket in its `toc.snap` gets its named disk paths **swept clean
 before step 1** (via `Heist_sweep` — files only, dir skeleton kept). Born from the human's ruling on the
  Sounditron "disk accumulates across runs" nondeterminism: *"no, we simply must be tidier"* — clean it,
   don't bless it with forgiving Entcases.

- **Landed:** `src/lib/O/Story.svelte` — method `Story_hygiene(w,Run,run)` (beside `Story_settingoff`) +
   an **opt-in `expecting(w,'hygiene',10,…)` arm** in `do_step` at n===1. **NOT awaited** — the human's
    ruling: a bare await freezes the Atime belief-loop mutex, which the Wormhole needs to service disk and
     get back to us. `expecting` (`Hovercraft.svelte:601`) runs the sweep OFF the mutex + hangs a finishing
      `%req:hygiene` + ttlilt; the ttlilt **holds step 1 from ADVANCING** until the sweep resolves (so a
       Book stages swept-disk reads at **step 2+**, never racing the wipe) and **times out → complains** at
        10s. Gate = `!run.c.hygiene_armed && (w.c.The)?.o({Hygiene:1})[0]` → falsy for every Book without
         the bucket = zero blast radius. **The fast req finishes and is DROPPED before the snap → NO
          `req:hygiene` row leaks into the fixture** (proven MusuLossy green×2, no churn — unlike
           Sounditron's longer `expecting` holds whose `req:*_wait,finished` rows DO snap).
- **It is the INVERSE of an Assertion:** an Assertion = declared observation AFTER a beat ("must be
   true"); a `%Reset` = declared imperative BEFORE the run ("must be reset — litter swept"). Distinct
    mainkey, opposite side of the run. Runs OUTSIDE the stepped/snapped timeline (cleaning inside step 1
     would risk snapping a mid-clean world). Abortive-run-safe: a crash's litter is cleaned by the NEXT
      run's sweep.
- **Payoff:** once a Book's disk resets deterministically, DELETE its forgiving EntropyArrest Entcases and
   record EXACT fixture values. Subsumes the `Heist_sweep` the heist Books hand-code in their census beat,
    and finally covers the **radiostock leak** (`.jamsend/radiostock`, `Ra.g:418`) no per-Book end-sweep
     touches.

**FSA-cache gotcha (assessed — optional, not a blocker):** the nav's `_cache: Map<path,DirectoryListing>`
 (`Housing.svelte.ts:2118`) returns a cached listing without re-walking, so a dir/file created **out-of-band**
  (a shell `mkdir`/write) is invisible until a reload re-expands the parent — a decoy planted by hand SURVIVED
   a sweep until I reloaded. BUT this bites ONLY out-of-band dirs: **real litter (e.g. `radiostock`) lives in
    dirs the nav itself `mkdirp`'d, so `_cache` already knows them and the sweep sees them with no reload.**
     So the cache-drop is NOT needed for the hook on real litter; if ever wanted for out-of-band robustness,
      add a `nav.forget(path)` (drop path+descendants from `_cache`, cf `mkdirp_fresh` `Housing.svelte.ts:2163`)
       at the top of `Heist_sweep` — a core-nav change, its own step. To PROVE a sweep by hand: use
        nav-written files, or reload before checking. Best-effort: `Heist_sweep` no-ops when the nav can't
         `deleteEntry` (a proxy/read-only runner).

**Sounditron is the WRONG first customer** — it probes the REAL environment under the REAL pub; a literal
 `Reset:radiostock` there deletes the **user's genuine warm cache**. The fix for Sounditron is *pin the
  probe* (test pub + deterministic `testsounds` sub-share), not wipe. The heist/Musu/berth family is the
   right first customer. Full design + proof recipe: `spec/Story_hygiene_todo.md`. See
    [[verify-via-live-runner]], [[force-clean-rerecord]], [[entropy-samples-fuzzok]].
