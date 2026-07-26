# Story_hygiene_todo.md — the pre-Story wormhole hygiene hook (a Reset is an Assertion's inverse)

A NEW Story primitive: a declared, per-run **reset** of the disk working-area a Book uses, run once
 just before step 1 so the run starts from a deterministic baseline. Born from the Sounditron
  "disk accumulates across runs" problem (Radio_todo §0) — the human's ruling: *"no, we simply must be
   tidier."* Not "bless the nondeterminism"; **clean it.**

---

## 0. What to get on with next

**BUILT + PROVEN live (2026-07-26).** The primitive is landed in `src/lib/O/Story.svelte`:
 `Story_hygiene(w,Run,run)` (a new method beside `Story_settingoff`) + an **opt-in `expecting()` arm** in
  `do_step` at step 1. It is byte-neutral to the ~50 existing Books (the gate is a cheap optional-chained
   find that is falsy for any Book without a `The/Hygiene` bucket → nothing armed, no I/O).
 **NON-BLOCKING (the human's ruling, 2026-07-26):** it is NOT awaited inline — a bare `await` in `do_step`
  would freeze the Atime belief-loop mutex for the sweep's whole extent, and Atime is exactly what the
   Wormhole needs to think and get back to us (plus every watcher/req besides). Instead the sweep is armed
    through `expecting(w,'hygiene',10,…)` (`Hovercraft.svelte:601`): it runs OFF the mutex, a ttlilt holds
     step 1 from ADVANCING until it resolves (so a Book stages its swept-disk reads at step 2+ and they
      never race the wipe), and on overrun 10s the ttlilt TIMES OUT → Story complains (`on_step_ending
       'timeout'`). This is the exact `expecting` shape Sounditron uses for `relay_wait`.
 **Proof (runner 49dee91d):** MusuLossy given a temp `The/Hygiene/{Reset:probe,path:.jamsend/hygiene-probe}`
  ran **green ×2** and a decoy planted at the target was **deleted** both runs (dir skeleton kept —
   Heist_sweep's contract). Bonus finding: the fast hygiene req finishes and is dropped **before the snap**,
    so **no `req:hygiene` row leaks into any fixture** — a Hygiene Book stays green with ZERO churn (unlike
     Sounditron's longer holds, whose `req:*_wait,finished` rows DO snap). Temp bucket reverted; MusuLossy is
      pristine, the demonstrator lives in §3.
 **The FSA-cache gotcha (assessed — a SEPARATE optional item, not a blocker):** the first decoy attempt
  survived because the nav's `_cache: Map<path,DirectoryListing>` (`Housing.svelte.ts:2118`) returned a
   parent listing cached BEFORE the shell-created probe dir existed, so `dir_at` returned null and the sweep
    never reached it; a reload cleared the cache. This bites ONLY out-of-band dirs — **real litter (e.g.
     `radiostock`) lives in dirs the nav itself `mkdirp`'d, so `_cache` already knows them and the sweep
      sees them without any reload.** So the cache-drop is NOT needed for the hook to work on real litter.
       IF we later want robustness to out-of-band litter (a crashed foreign process, another tool), the
        clean shape is a `nav.forget(path)` that drops the path + descendants from `_cache` (mirroring
         `mkdirp_fresh`'s re-expand-from-root, `Housing.svelte.ts:2163`), called at the top of `Heist_sweep`
          — ~10 lines, but a core-nav change, so its own reviewed step. Recommend DEFER unless a real
           out-of-band case appears.

**THE CUSTOMER SET (surveyed 2026-07-26) — a HANDFUL, not the suite.** The natural users are the ~8 Books
 that ALREADY hand-code a `Heist_sweep(this.Heist_meta_dir()+'/test-marrauding-of-<X>')` at start+end:
  **MusuHeist** (`Heistation.g:142,171`), **MusuBreach** (`:2586,2670`), **MusuBreach_wire** (`:2764,2862`),
   **MusuOgg** (`:3142`), **MusuReap** (`:3274,3332`), **MusuSoft** (`:3457,3582`), **MusuBay**
    (`:3745,3924`), **MusuLossy** (`:4028`) + the **Berthation** Books (`Berthation.g:102,159`). For them the
     hook is a DECLARATIVE re-home of a sweep they already run (imperative-in-step-1 → toc-resident `%Reset`),
      plus uniform abortive-safety — NOT a bug-fix (the hand-coded start-sweep already makes them
       deterministic). Everything ELSE needs nothing: most Books write deterministic-named
        overwrite-idempotent files (MusuLossy's `wav/opus/mp3`, `Heistation.g:4039-4044`) that never
         accumulate. NOT Sounditron (§4 — real user cache).

**radiostock is a SEPARATE lever from this hook (2026-07-26).** The `radiostock/` monotonic leak now has a
 PRODUCTION cap — `Ra_stock_gc(nav,pub)` keeps the newest `Ra_stock_cap()`=256 per pub (`Ra.g`, called in
  `Radio.g` per landed churn). But that cap is a **no-op in tests** (they never dig 256), so it does NOT make
   tests deterministic — and the human's ruling is we **TOLERATE radiostock in tests** (it is the ONLY
    timestamped disk filename, non-colliding, already absorbed by the Sounditron Entcases). So do NOT reflex
     a `Reset:radiostock` into every meander Book; the hook's job is the deterministic-named marauding roots
      above, where an exact fixture is the goal.

Next moves, in order:
- **First real customer = ONE heist Book, NOT Sounditron** (§4 — the sharp caveat). Convert e.g. MusuHeist's
   hand-coded start `Heist_sweep` into a declared `The/Hygiene/Reset,path:.jamsend/test-marrauding-of-bookrun`,
    delete the imperative call, prove green×2. Then roll the pattern across the ~8. (radiostock stays
     hand-tolerated per the ruling above — its production cap is the separate lever.)
- **V2 (deferred): the pre/post-manifest diff** = "the spurious things a run added" (a *hygiene gap*, the
   companion to `Cred_assertion_gaps`). Capture a `rw_op:'list'` manifest before step 1 and at run end;
    the diff surfaces to the human like the un-asserted-detail snap diff; human-accept writes the
     reset-list into the toc exactly as `e_story_declare` writes an `%Assertion`. V1 (the declared sweep)
      delivers the core value without it.

---

## 1. The arc — why this exists

The whole suite is green, but Sounditron is green only because its `toc.snap` is loaded with
 EntropyArrest Entcases that **bless** nondeterminism (`re:Stoker(.*),tol:any`; `means,drop` on
  environment rows; `means,dontSnap` on the stock fold). That is the same species of theater as signing
   a loopback: a fixture that cannot fail on the thing it is meant to watch. The leak is real —
    `Stoker_look` (`Radio.g:681`) **resurrects** every standing radiostock file for a pub off disk on
     first look, and each run's meander **digs** new tracks that `Ra_stock_gc` never evicts (it only
      culls older twins of the same enid), so run N+1's settled stock ⊇ run N's finds, monotonically.

The payoff of the hook is **deletion of forgiveness**: once the disk resets to a deterministic baseline
 before step 1, those forgiving Entcases can be removed and the fixture records EXACT values (`stood=N`)
  that catch real regressions. Tidier state → stricter fixtures → the green means more.

---

## 2. The design (as landed)

**A `%Reset` is the inverse of an `%Assertion`.** An Assertion is a declared *observation about the world
 AFTER a beat* ("must be true — its absence complains"). A Hygiene reset is a declared *imperative about
  the world BEFORE the run* ("this disk target must be reset — its litter is swept"). Same toc-resident,
   human-accepted, `story_save`-persisted machinery; **opposite verb, opposite side of the run.** So it
    earns a distinct `%Reset` mainkey (mainkey-exclusivity: don't overload "latch a sentence" with
     "delete a directory"), not an Assertion variant.

**Shape** — a new bucket under `The`, which `encode_toc_snap` round-trips for free (the codec is generic;
 `Story.svelte:506` — "Adding a new bucket under The is zero-code"):
```
The/Hygiene
  Reset:radiostock,path:.jamsend/radiostock          // Heist_sweep this target's FILES before step 1
  Reset:marrauding,path:test-marrauding-of-<bookrun>  // subsumes the sweep heist Books hand-code today
```

**Execution — declaration (where) separated from execution (how):**
- *Where:* declared in the `The/Hygiene` toc bucket; read at step 1.
- *How:* an **`expecting(w,'hygiene',10,() => Story_hygiene(…))`** armed in `do_step` at n===1 (after
   `Run.trace('step',n)`, before `Story_prepare_Prep`). NOT an inline `await` — the human's ruling: a bare
    await freezes the Atime belief-loop mutex for the sweep's whole extent, and Atime is what the Wormhole
     needs to service disk and get back to us. `expecting` runs the sweep OFF the mutex and hangs a
      finishing `%req:hygiene` + ttlilt (`Hovercraft.svelte:601`). The ttlilt **holds step 1 from
       ADVANCING** (via `ttlilt_held()` in `poll_step`, `Story.svelte:2212`) until the sweep resolves —
        so a Book stages its swept-disk reads at **step 2+** and they never race the wipe — and on overrun
         10s the ttlilt **times out → complains** (`on_step_ending 'timeout'`). This is the "ttlilt-step-1"
          shape the human named, done right: the sweep is off-timeline (never blocks Atime), and because
           the fast req finishes before the snap it leaves NO row in the fixture (proven).

**Why opt-in matters:** the gate `!run.c.hygiene_armed && (w.c.The)?.o({Hygiene:1})[0]` is a safe
 optional-chained find — falsy for every Book without the bucket → nothing armed, no ttlilt, no nav I/O.
  Zero blast radius on the existing suite.

**Best-effort by construction:** `Heist_sweep` (`Heist.g:849`) deletes FILES ONLY, never the dir skeleton
 (a deleted dir kills the nav's cached FSA handle → `NotFound` on the next `create:true`), and no-ops when
  the nav lacks `deleteEntry` (a proxy/read-only runner). So on a non-writable share the sweep silently
   does nothing rather than throwing — the determinism guarantee simply weakens there (gate a Book that
    NEEDS the reset on a writable share, the `no_writable_share` pattern).

**Abortive-run safety falls out for free:** because the reset is at run-START, a crashed prior run's
 litter is cleaned by the NEXT run's sweep — a run never depends on its own end-sweep firing. This is the
  exact property the human asked for ("in case of an abortive run").

---

## 3. How to prove it (the recipe for the next session)

1. Court/pin a **dedicated** runner (never a shared one — bleed would false-red the proof). Reload it onto
    the new `Story.svelte` (a `.svelte` edit needs a runner reload to take; no gen regen — Story is not a
     `.g`). Confirm idle.
2. Pick a fast green Book (e.g. a loopback Musu Book, or MusuLossy). Hand-add to its `wormhole/Story/<Book>/toc.snap`:
    ```
      Hygiene
        Reset:probe,path:.jamsend/hygiene-probe
    ```
    (a scratch path nothing writes → `Heist_sweep` no-ops, but the GATE fires and `Story_hygiene` runs —
     proves the wiring without changing the Book's behavior). Indent = 2 spaces under `story:<Book>` like
      `Styles`/`Plan`.
3. `runner_ask run <Book> --runner=<full-prepub> --watch` → expect **green** (Book unbroken by the hook)
    and the `hygiene` trace in the run. Rerun → **green×2**.
4. For a DELETION proof: point `path:` at a target the Book actually writes (e.g. MusuLossy's
    `.jamsend/lossy-proof`), confirm the file is gone at step-1 start then re-written by the beat — the
     Book stays green because it re-materializes. (Optional; deletion itself is already proven in the
      heist Books.)

---

## 4. The sharp caveat — Sounditron is the WRONG first customer

Sounditron's whole job is probing the **real** environment under the **real** pub. A literal
 `Reset:radiostock` there would delete the **user's genuine warm cache** — actively harmful to someone
  running the diagnostic. The honest fix for Sounditron is NOT "wipe" but **"pin the probe"**: run the
   stoker against a deterministic `testsounds` sub-share under a **test pub**, so the probe is
    reproducible without touching real stock. Build the hygiene hook as a general primitive for the
     heist/Musu/berth family (it subsumes their hand-coded start-sweeps and covers the radiostock gap);
      give Sounditron the pinning variant separately. Do NOT frame this hook AS the Sounditron fix.

---

## 5. File:line index

- Landed: `src/lib/O/Story.svelte` — `Story_hygiene(w,Run,run)` (just after `Story_settingoff` ~L1594);
   the `expecting(w,'hygiene',10,…)` arm in `do_step` (just before `Story_prepare_Prep`, after
    `Run.trace('step',…)`). The hold primitive: `expecting` (`Hovercraft.svelte:601`); the step-hold gate
     `ttlilt_held()` (`Story.svelte:2212`).
- Pre-step-1 seam it rides beside: `Story_settingoff` (`Story.svelte:1526`, called `:2129`), which
   already does a per-run reset (`story_assertioning_reset` `:238`) — the precedent for "a job before
    the Story starts."
- The sweep: `Heist_sweep(nav,path)` (`Heist.g:849`, files-only, best-effort); nav via
   `Crate_nav()` (`Crate.g:173` → `A:Wormhole.c.nav`).
- The leak it targets: `Ra_stock_dir='.jamsend/radiostock'` (`Ra.g:418`); resurrection `Radio.g:681`;
   dig/write `Ra.g:1102`; GC-only-twins `Ra.g:1105`.
- The codec that round-trips the bucket for free: `encode_toc_snap`/`decode` (`Story.svelte:506`+/`:554`+).
- What blesses the drift today (to be deleted once reset lands): the Entcases in
   `wormhole/Story/Sounditron/toc.snap`; drift visible in `.../Sounditron/{002,006}.snap`.
