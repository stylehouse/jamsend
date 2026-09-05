# Story_hygiene_todo.md — the pre-Story wormhole hygiene hook (a Reset is an Assertion's inverse)

A NEW Story primitive: a declared, per-run **reset** of the disk working-area a Book uses, run once
 just before step 1 so the run starts from a deterministic baseline. Born from the Sounditron
  "disk accumulates across runs" problem (Radio_todo §0) — the human's ruling: *"no, we simply must be
   tidier."* Not "bless the nondeterminism"; **clean it.**

---

## 0. What to get on with next

### ⚠ TODO (2026-09-04, the owner: *"please push a TODO somewhere for that nondeterministic runner problem"*)

**A VERIFICATION SWEEP CANNOT CURRENTLY BE TRUSTED, and it fails SILENTLY GREEN.** Measured over a
 30-Book sweep today. Four separate faults compound; the first two are the dangerous ones because their
  failure mode is a Book that reports `ok:true, caveat:0` while proving nothing.

**1. Two live runner tabs make `runner_ask` NON-DETERMINISTIC.** With `da060c94…` and `e747cbed…` both
 advertising, an un-targeted call lands on whichever answers first: `ping` replied from `e747` while the
  sweep held `da06`, and `steps` returned **a different Book than the one just run** (asked for MusuReap,
   got MusuPoolRandom; asked after MusuBay, got MusuBuddy). Since `story_accept` writes fixtures from
    `snap <n>`, this is the same class as the guard it already carries — *"a degraded runner served
     SwarmBody's snap for a SwarmPost step … cross-Book corruption that only a `H:<Book>,Run` check
      catches"* — except one tab further out, where that guard cannot see it.
 - `--runner=<id>` pins `run`, but the FOLLOW-UPS (`steps`, `snap`, `state`) do not honour it reliably.
    **Until they do, a fixture-writing pass is only safe against exactly one live tab.**
 - *Wanted*: the lease/engagement id already on every reply (`engagement.client`) threaded through the
    follow-ups, so a session addresses ONE tab for a whole run→steps→snap transaction; and `runners`
     refusing (or loudly warning) when a write-path op is issued with more than one tab live.

**2. A HOLLOW RUN READS AS GREEN.** `MusuHeist` reported `ok:true, caveat:0` at `done:11` against **22**
 recorded steps; `MusuMag` 6/10; `MusuNeGrind` 6/11. Nothing in the outcome says "I only ran half of it" —
  `ok_pct` was 1 in each case, because the steps that DID run passed.
 - *Wanted*: the run outcome carries the toc's own step count, and `ok` is false when `done < total`.
    Until then **every caller must compare `done` against the fixture count itself** — see the count-check
     in this session's sweep script. `story_accept` already has a hollow retry; the raw `run` path has none.

**3. `ok:true` HIDES `caveat`.** Known ([[story-fixture-gate-vs-churn]]) and still true: `MusuStock`
 answered `ok:true, caveat:5`. Any gate that reads `ok` alone passes a Book whose diges have drifted.

**4. STOPPING A SWEEP DOES NOT STOP IT.** The harness's TaskStop kills the task wrapper, **not the shell
 script it spawned**. Two "stopped" sweeps kept driving the runner for ~20 minutes afterwards — including
  a `story_accept` mid-flight, which is a fixture WRITER. Verified afterwards that all 319 touched snaps
   were still exactly `committed + rename` and nothing had been overwritten, but that was luck of timing.
 - *Wanted*: any long sweep script writes its PID (`echo $ > …/x.pid`) so it can be killed for real, and
    a fixture-writing sweep should refuse to start if another one is already live.

**The one good discovery from the same session**, because it removes the need for most sweeps:
 **`dige` == `sha256(<the whole snap file>)` sliced to the first 16 hex chars** (reproduced byte-for-byte
  against a live runner's reported dige). So a fixture change that is provably content-preserving — a pure
   rename, say — needs NO runner at all: recompute the diges locally and patch the toc. That is how 319
    stale diges across 30 Books were settled today without a single re-swear. ⚠ But note the corollary
     found the same way: the runner compares live-dige against the **toc**, never against the `.snap` file,
      so a `.snap` that has drifted from its toc is INVISIBLE to a green run. Six Books are in that state
       right now (Diffmatication · InvSeal · InvWalk · Peeringinst · SwarmBody · SwarmWire) — they run green
        with 28 snap files that no longer hash to what their toc claims.

---


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

**Committed toc diges that disagree with their own snap (found 2026-09-04, NOT acted on — out of scope).**
 Since `dige == sha256(<whole snap file>)[:16]`, toc-vs-snap consistency is checkable with no runner at all.
  Six Books are inconsistent **in committed state** (clean working tree), so every run of them reports
   caveats that mean nothing:

| Book | stale / total |
|---|---|
| `SwarmBody` | **22 / 23** |
| `Peeringinst` | 2 / 2 |
| `Diffmatication` | 1 / 1 |
| `InvSeal` | 1 / 4 |
| `InvWalk` | 1 / 7 |
| `SwarmWire` | 1 / 5 |

 The formula is sound — `MusuHeard` reads 0/9 and `MusuStanding` 0/12 — and none of these carry the
  legitimate `dige:0000000000000000` un-gated marker (SwarmBody has zero of them). `SwarmBody` matters most:
   it is the `%Want` W1 gate (23 beats), and 22 stale diges mean it has been reporting a wall of meaningless
    caveats since it was recorded.
 **The fix costs no runner:** rewrite each `step[=N],dige:` to `sha256(NNN.snap)[:16]`. That only settles
  BOOKKEEPING — a genuine content drift still surfaces as a red step, never a caveat — so it cannot hide a
   regression. Left undone deliberately: these are committed fixtures belonging to other work, and doing it
    would add ~27 unrelated files to an already large review. Worth one deliberate pass by whoever owns them.

**MUTING THE `self,round` CAVEAT NOISE — ⚠ REVERSED BY THE OWNER 2026-09-04, KEPT ONLY AS THE `drop` RECIPE.**
 ⛔ **Do NOT apply this to `self,round`.** The owner ruled the wobble is a READING ON TTLILT, not noise:
  *"self,round is fine to include, it shouldn't wobble unless our ttlilt is not functioning well — Story
   step-times should be predictable."* The three Entcases were removed and the Books re-recorded; §0a is the
    measurement that ruling produced. What follows is still the correct recipe for `means,drop` in general —
     use it for genuinely dead churn, never to make a Book green by deleting its instrument.
 The counter was ALREADY globally forgiven — `Story.svelte:1074` carries
  `spay:{ re:'\\bround(?:=\\d+)?\\b', tol:'any' }` — and that is precisely why it is noisy: a spay forgives
   at COMPARE, and a forgiven step is demoted to *ok with a **caveat***. So the caveat wall was the
    forgiveness working as designed. Forgiving harder cannot help; the line has to stop being snapped.
 EntropyArrest's structural means do exactly that (§5): **`drop` → `means.skip` omits the whole matched
  line at ENCODE**, so got and exp never carry it and there is nothing to forgive. `self,est` on the very
   next rule already uses this path. Authored **test-scoped** as an Entcase in the Book's own `The`, so no
    other Book is blinded (`Composition_todo.md` §2.3's objection to a global arrest stands — do NOT make
     this the global rule without deciding the ~120-Book fixture cost first):

```
  EntropyArrest                                        ← a top-level The bucket, beside Styles/TimeSpool
    Entcase:Round_noise
      note:the per-tick belief-round counter — dropped not forgiven so it stops tagging every step with a caveat
      lematch,self,round                               ← locator: the mainkey stripped off IS the sc_has
        means,drop                                     ← no `re` — encode-time omission, not a graft
```

 Write it straight into `wormhole/Story/<Book>/toc.snap` with the runner RELEASED, then
  `node scripts/story_accept.mjs <Book>`. It round-trips through `The` intact (verified) and the residual
   is empty by construction — `story_accept`'s `FILTER` already strips `self,round` — so the accept is
    automatic and reviewable. **`MusuHeist`, the very Book §2.3 measured at 20/14/1 caveats on identical
     code, came back `ACCEPTED → GREEN (22 steps, caveat 0)`.**
 ⚠ The cost, stated plainly: that Book can no longer see `self,round`, so it loses the one value in the
  snap that detects ambient work. The owner's standing design note (`Story.svelte:79`) wants the signal
   kept a better way — *"when that raises more than one since the last Story that's %interesting"* — i.e.
    hide the value but ASSERT on a jump greater than one. That is the real fix and it is not built.

## 0a. THE DETERMINISM SOAK (2026-09-04) — what flaps, and what it is

The owner's ruling that made this worth measuring: *"self,round is fine to include, it shouldn't wobble
 unless our ttlilt is not functioning well — Story step-times should be predictable."* So the wobble is a
  READING, not noise. 30 runs, five Books × six, serial on one live runner, code frozen throughout.

**Verdicts never moved. Content did.** `ok:true` / `ok_pct:1` in all 30 runs — no gaps, no wedges, no
 errors. Per-step `dige` across the six runs:

| Book | steps flapping | caveat range |
|---|---|---|
| `MusuHeist` | **21 / 22** | 0 → 20 |
| `MusuReco` | **8 / 11** | 1 → 8 |
| `SwarmShare` | 1 / 9 | fixed 8 |
| `MusuHeard` | **0 / 9** | 0 |
| `MusuStanding` | **0 / 12** | 0 |

**THE FINDING: the flap is `self,round` and NOTHING else.** `MusuHeist` step 22 captured on three
 consecutive runs — **304 lines each, one line different**: `self,round=39` vs `38` (and its duplicate at
  the w level). All 302 other lines identical. Earlier, `SwarmShare` step 7 gave the same answer:
   `self,round=14`→`15`, nothing else. **So the world state is reproducible; only the NUMBER OF BELIEF
    ROUNDS taken to reach it varies, by one.** This is jitter in the loop's step-timing, not divergence in
     what the app computes — which is precisely the condition the owner's ruling predicted, and the reason
      to keep the counter in the snap rather than arrest it.

**It is Book-specific, and all five Books carry the counter** (18-44 `self,round` lines each), so this is
 not "the counter is noisy" — it is that three Books have unpredictable step-times and two do not.

**Two hypotheses tested; report them so nobody re-runs them:**
- ❌ **NOT "the wire/peer Books flap".** `MusuStanding` uses `Lake_link` (2), `Peering` (3) and `Repli_` (6)
   and is perfectly stable at 0/12. Killed.
- ~ **ttlilt is implicated but is NOT the whole story.** `MusuHeist` is the ONLY one of the five that uses
   `expecting(`/ttlilt (4 and 5 occurrences) and it is by far the worst flapper (21/22) — which fits the
    owner's hypothesis. But `MusuReco` and `SwarmShare` flap with **zero** ttlilt, and `MusuStanding` is
     stable with zero. So ttlilt explains the worst case, not the class.

**Shape matters when you go looking:**
- `MusuHeist` flaps **per-run, not per-step** — runs 2 and 5 diverged as a BLOCK from step 10 onward, every
   step taking the same alternate value. One extra round early, propagated forward.
- `MusuReco` shifted **one-way mid-soak** — steps 4/5/7 gave value A for runs 1-3 and value B for 4-6 and
   stayed. Re-running it three times afterwards gave **byte-identical** step-7 snaps, so the shift is an
    occasional event, not per-run noise. Something settles into a new state and stays there.

⚠ **Consequence for recording.** `story_accept` writes fixtures from one live run and then verifies with
 another; if the round count differs between those two runs the Book cannot be re-recorded green.
  `MusuHeist` and `SwarmShare` both failed to land green for exactly this reason (`MusuReco` did land,
   11/11 caveat 0). **A Book that will not accept twice in a row is not necessarily broken — check whether
    its only diff is `self,round` before touching anything else.**


### 0a.1 WHY it flaps — quiescence is an IDLENESS heuristic, not a causal wait

The owner, reading the soak: *"we probably need more ttlilts not less — Heist might have way more flaps
 with less ttlilts… the way things execute is fairly direct?"* He is right, and the code says so plainly.
  `Story.svelte:2443`, commented **"the crux"**:

```js
let quiescent = long_after_Atime && dont_want_Atime && dont_leave_running() && !ttlilt_held()
```

`long_after_Atime` means **no belief-mutex activity for `quiesce_snap_time`** — default `1.5 × TICK_MS`,
 about **75ms** (`Story.svelte:2219`). So a Story step ends because *nothing has happened for 75ms*, NOT
  because the work finished. It is a wall-clock idleness heuristic.

**Therefore every real async boundary is a coin-flip against a 75ms timer.** A decode, a socket
 round-trip, an IndexedDB read, a transcode advance: resolve inside the window and the work joins THIS
  step; resolve outside it and the step was already declared quiescent and the work lands in the NEXT one,
   shifting the belief-round count from there onward. Which side you land on is decided by machine load.
    That is exactly the shape measured in §0a — `MusuHeist` runs 2 and 5 diverging **as a block from step
     10 onward**, one late arrival then every later step offset by one round.

**A `%ttlilt` is the only thing that makes the wait causal.** `o_Story_req_ttlilt` (Hovercraft.svelte:556)
 returns true — holding the world non-quiescent — while a live ttlilt has `until_ts > now` and its req is
  not finished. With NO ttlilt the list is empty, it returns false, and the step ends on the poll's own
   cadence with nothing forcing it to wait for in-flight work.
 ⇒ **More ttlilts, not fewer.** My first read of the soak ("MusuHeist has the most ttlilts AND the most
    flaps") had the causality backwards: MusuHeist has ttlilts *because* it is the most async-heavy Book,
     and they are already suppressing worse jitter. Removing them would make it flap harder.
 ⇒ Raising the `quiesce_snap_time` Opt widens the window, so the coin lands the same way more often — it
    reduces the flap RATE without removing the race, and slows every step. A ttlilt on the specific req
     removes the race instead of shrinking it. Longer ttlilts help only where a ttlilt already exists.

**The instrument already exists and is not on the wire: `run.c.quiesce_blame`** (`Story.svelte:2450`,
 added 2026-08-06 for exactly this — *"the four reasons want four different fixes, but from the outside
  they are one indistinguishable pause"*). It counts, per poll, WHICH of the four conditions held the
   step: `in_Atime` · `todo` · `leave_running` · `ttlilt`. It lives on `.c`, so it never reaches a snap,
    and the `steps` op explicitly drops `trace` too (`LiesFunk.svelte:2814` maps only n/ok/caveat/untried/
     error/dige/desc). **Surfacing `quiesce_blame` per step is the next move** — it turns "some part of the
      process is nondeterministic" into a named condition per step, which is the thing we cannot currently
       see. (Note the same block warns: blame must READ `leave_running`, never re-call the helper, which
        mutates.)

**Reading traces, practically.** `node scripts/runner_ask.mjs trace <n>` gives `{ok, n, caveat, dige,
 cycles, trace:[{t,kind,tag}]}` where `kind` runs step→todo→beliefs→think→beliefs done→quiescent→snap→
  snapped, and the `quiescent` tag is the idle seconds, suffixed **` timeout`** when the ttlilt expired
   rather than cleared (`Story.svelte:2555`). ⚠ **Traces are only readable while the run's `This` is still
    up** — collect them immediately after the run, and expect a ~30-40s window; one `trace` call per step
     is too slow to walk 22 steps before it clears.

**Observed, and worth chasing:** cycle counts vary enormously *within* a single run — step 1 = 8, step 2 =
 61, step 6 = 133, **step 10 = 351**, step 11 = 8. Step 10 is both the heaviest spinner and the exact point
  where the block divergence begins. When the runner stays in one mode, cycles and dige are perfectly
   reproducible (steps 9/10/11 gave identical `cycles`=73/351/8 and identical diges across three runs).

### 0a.2 THE STANDUP WEDGE IS A RELEASE→RUN RACE — and a pause clears it

The `phase:"begun", n:null, total:null, steps=0` wedge (console: `▶ Story subHouse created for <Book>`
 then TOTAL SILENCE — no `story_analysis`, no `story_save`, no `drive started`) is **not rare and not
  mysterious**. It is a race between `auto_reset_story`'s teardown and the next run's standup.

**Measured 2026-09-04, `MusuHeist`, same runner, back to back:**

| cadence | wedges |
|---|---|
| `release` → `run` immediately | **2 / 6** |
| `release` → wait 6s → `run` | **0 / 6** |

(n=6 per arm — small, so treat the RATE as indicative; the direction is clean and the mechanism below
 explains it.)

**Why.** `auto_reset_story` (Auto.svelte:1220) calls `auto_teardown_story` — which hand-walks `A → w → run`
 setting `run.c.driving = false`, then `existing.stop()`, `H.drop(existing)`, then culls Supervisor
  orphans — and only THEN schedules the new subHouse in a `post_do`, whose body ends with
   `S.i_elvisto(S, 'think')`. The wedge is that posted `think` never running: subHouse created, nothing
    after. Re-engaging while the previous teardown is still draining lands the new Story on a half-dropped
     one.

**This is a KNOWN SHAPE, already written up.** `Story_future.md` §8.3, verbatim: *"This is precisely the
 bug that bit `auto_reset_story`: a story drive leaked because its wake was a free `setTimeout` gated on a
  bare `.c.driving` flag, not a req-owned ttlilt — so 'stop the drive' was a hand-walk that silently
   no-op'd (it queried `w` one level too high, found nothing, and never set `driving=false`)."* The stated
    cure is the general one: a timing impulse held as a **particle** is *inspectable* (it is a
     `%req/%ttlilt,until_ts` in the snap — "the snap is the control panel of every timing impulse") and
      *structurally torn down* (drop the req subtree and its wake dies with it, so "stop" cannot silently
       fail). A `setTimeout` closure has neither property.
 ⚠ Scope check before over-applying it: §8.4 deliberately KEEPS the drive's own poll chain a timer —
  *"a timer that reads the ttlilts to decide when to snap can't itself be a ttlilt without circularity"* —
   and pushes the fix to §15, recasting the steps it drives as reqs. So the answer is not "make everything
    a ttlilt"; it is that everything *beneath* the drive's clock should be req-owned, and much of it isn't.

**DO THIS NOW, in every sweep/soak script: put a gap between `release` and the next `run`.** A large share
 of this session's false reds — `SwarmShare`'s "total standup wedge" that later ran 9/9 green on
  byte-identical files, the repeated `NO-RUN (try 2)`s, the hollow runs — are consistent with this one race.
   It costs seconds per Book and removes a whole class of un-reproducible red.

### 0a.3 TWO TOOLS BUILT FOR THIS (2026-09-04)

**`scripts/story_late.mjs <Book> [--runs=N] [--steps=A-B] [--settle=6]`** — names the nondeterminism in a
 step instead of guessing at it. Read-only: it drives runs and reads the runner's own `Run_trace`; no core
  code was changed to add it. Per step it reports:
 - **`late`** — entries after the final `gallop: off todo:0` and before `quiescent`. **This is the number
    that matters**: by definition that work was triggered by something the todo registry did not hold, i.e.
     an *unregistered async*. It should be 0, and each one names the think that ran. `late>0` is the
      wrap-it-in-a-req list, handed to you by name.
 - **`rekick`** — the watchdog's "actively re-drive a dropped wakeup", which fires off a wall-clock idle
    threshold *inside* the step (`rekick: todo:17 idle:0.04s` seen on MusuHeist step 10). A re-drive whose
     firing depends on the clock is a coin-flip in the middle of the ordering.
 - **`clip`** — `gallop: clip todo:N`: the drain was cut by a CAP with N todos still queued, not by running
    out of work.
 - **`timeout`** — the `quiescent` tag carried ` timeout`, i.e. a ttlilt expired rather than cleared.
 It cross-tabs those against whether the step's `dige` flapped, and — the honest part — **explicitly calls
  out steps that FLAP with `late=0 rekick=0 clip=0`**, meaning the divergence is upstream of the trace and
   the tool cannot see it. Do not guess past that line.

**`scripts/story_accept.mjs` now settles between `release` and `run`** (`SETTLE_MS`, default 6000, override
 with `STORY_SETTLE_MS`). This is the §0a.2 fix: no gap wedged the standup 2 of 6, a 6s gap 0 of 6. A
  wedged Book costs a whole re-record, so the seconds are cheap. **Any new sweep/soak script must do the
   same** — a large share of this session's un-reproducible reds were that one race.

⚠ **What `cycles` is NOT.** `LiesFunk.svelte:2843` sets `cycles = trace.length` — trace ENTRIES, not belief
 passes. MusuHeist step 10's famous 351 is 113 `todo` + 226 `beliefs` (113 begin/done pairs) + 4 `think` +
  3 `gallop` + 1 `rekick`, spanning ~1.1s: a gallop draining back-to-back at ~10ms a pass, and byte-identical
   across three runs. **The intensity is not the problem** — that much twisty compute stays perfectly
    ordered. Only the ~100ms after `gallop: off` is undecided.

### 0a.4 THE CAUSAL CHAIN, MEASURED (2026-09-04) — one dropped wake, inherited forward

`scripts/story_late.mjs MusuHeist --runs=3 --steps=1-9`:

```
step | dige flap | late | rekick | cycles
   1 |   stable |    0 |      0 | 8          <- causally settled: the baseline
   2 | FLAP 2   |   11 |      1 | 51/47/53   <- THE SOURCE (reqyonciliation +1 | think +1)
   3 | FLAP 2   |    0 |      1 | 33
   4 | FLAP 2   |    0 |      0 | 12         <- inherited (trace identical)
   5 | FLAP 3   |    4 |      1 | 37/33
   6 | FLAP 2   |    4 |      1 | 133/137
   7 | FLAP 2   |    0 |      0 | 8          <- inherited
   8 | FLAP 2   |    0 |      0 | 8          <- inherited
   9 | FLAP 2   |    4 |      1 | 73/69
```

**The chain, each link measured rather than argued:**
1. **A wake is dropped.** `rekick: todo:17 idle:0.04s` — the loop went idle *with 17 todos still queued*.
    A loop with queued work does not idle unless its wake was lost. That is exactly `Story_future.md`
     §8.3's named failure: a wake held as a free `setTimeout` on a bare `.c.driving` flag instead of owned
      by a req, so it can be silently dropped.
2. **The watchdog re-drives it on a WALL-CLOCK threshold** (`Story.svelte` ~2470, "actively re-drive a
    dropped wakeup"). When it fires is decided by the clock, not by the work.
3. **That re-drive lands work after `gallop: off todo:0`** — a LATE ARRIVAL, i.e. work the todo registry
    did not hold — costing one extra belief round.
4. **`self,round` is CUMULATIVE**, so from there on every downstream step's snap differs while those steps
    are themselves perfectly deterministic. Steps 4/7/8 prove it: `cycles` identical across all runs
     (12, 8, 8), traces identical, dige still flapping.

**Therefore "21 of 22 steps flap" massively overstates the problem.** There are ~4 real sources (steps 2,
 5, 6, 9); the rest is contamination carried by the counter. Three of the four share ONE signature —
  `4 late + 1 rekick` — so it is plausibly a single unregistered async shape recurring, not four bugs.
 Correlation worth noting: **every step with `late>0` also had `rekick=1`** (4/4); step 3 had a rekick
  with no late arrival, so rekick is the wider set. n=3 runs — suggestive, not established.

**The fix is now falsifiable, which is the point.** Wrap what step 2 names (`reqyonciliation +1`,
 `think +1`) in a req/`expecting()`, re-run `story_late`, and `late` should fall to 0 with the downstream
  flap vanishing behind it. If it does not, the model above is wrong and it says so immediately.
 ⚠ Not proven: steps 4/7/8 flapping with `late=0 rekick=0 clip=0` is CONSISTENT with inheritance but is
  not proof of it — a second, trace-invisible source is not excluded.

**On the inheritance claim — what is and is not proven.** Steps that flap with `late=0 rekick=0 clip=0`
 (MusuHeist 4/7/8) are claimed here to be INHERITING an earlier step's extra round via the cumulative
  `self,round`, not to be independent sources. The evidence:
 - their traces are IDENTICAL across runs — `cycles` 12, 8, 8 with no variation — so nothing about how
    those steps executed differed;
 - with an identical trace, the only thing that can move the dige is snap CONTENT, and the only
    run-varying content found anywhere today is `self,round`;
 - two DIRECT snap-level proofs exist on other steps: `MusuHeist` step 22 (304 lines, sole difference
    `self,round=39`→`38`) and `SwarmShare` step 7 (sole difference `self,round=14`→`15`).
 ⚠ **Not proven directly for 4/7/8**, because the runner retains `got_snap` for only SOME steps — `snap 4`,
  `snap 7` and `snap 8` all return `{"ok":1,"dige":"…","got_snap":null}` while `snap 22` returns full
   text — so the snap-level diff cannot be taken on those particular steps. A second, trace-invisible
    source is therefore not excluded, only made unlikely. Someone wanting certainty should find what
     governs `got_snap` retention first.

**The registry is not a thing to build — it already exists.** `expecting(w, name, secs, async_fn)`
 (Hovercraft.svelte:621) enrols an async: a `%req` hung on `w` hosting a `%ttlilt`, with the work running
  OFF the Atime mutex ("think() returns immediately… not holding it for its whole extent the way a bare
   `await` inside an eternal do_fn does"). `Run.o({ttlilt:1})` enumerates every thread in flight, and
    quiescence ALREADY consults it — `!ttlilt_held()` is one of the four conjuncts. The bug is that it is
     **ANDed with `long_after_Atime`**, so even a perfectly enrolled async still waits 75ms of silence.
      **The idle window is only the safety net for threads that never enrolled**; complete the coverage and
       that conjunct can go to ~0, making quiescence "todo empty and no live ttlilt" — fully causal.
 ⚠ The cost you cannot delete: wall-clock moves rather than vanishing — from an implicit global 75ms to a
  per-call `secs`. Undersize it and `expecting()` takes its TIMEOUT branch and snaps an in-progress
   picture — nondeterministic again, but LOUD (the `quiescent` tag carries ` timeout`; `story_late` has a
    column for it). A silent race becomes a sized promise you can be visibly wrong about.

### 0a.5 THE MECHANISM, EXACTLY — a 200ms throttle inside a 75ms window

Two constants decide it (`Housing.svelte.ts:35,39`):

```
ANSWER_CALLS_TICK_MS = 50     → quiesce_snap_time = 1.5 × TICK  ≈  75ms   (the window)
AMBIENT_MAIN_TICK_MS = 200                                                (the throttle)
```

**The throttle is longer than the window.** That is the whole bug, and everything measured in §0a–§0a.4
 falls out of it.

**The sequence, per late arrival:**
1. `expecting()` enrols an async: a `%req` hosting a `%ttlilt`. While that ttlilt is live the world is
    held non-quiescent — this part works, and is causal.
2. The async settles → `settle()` → `reqyoncile(req,{finished:1})` → posts a `reqyonciliation` elvis.
3. `e_reqyonciliation` (Hovercraft.svelte:285) runs → `host.finish(req)` → **the ttlilt is dropped**. The
    world is now eligible to quiesce after 75ms of silence. **The cover is gone.**
4. The same line then calls `H.feebly_ponder()` to wake the downstream work (Hovercraft.svelte:300,303).
    `feebly_ponder` → `main(true)` → `throttle(() => push_todo(think), AMBIENT_MAIN_TICK_MS)`.
5. **So the consequences of the completion are pushed through a 0-200ms throttle, while the step will
    declare itself quiescent after 75ms.** Throttle window open ⇒ the think lands in THIS step. Throttle
     recently fired ⇒ up to 200ms of delay ⇒ the step already snapped ⇒ the work lands in the NEXT step and
      `self,round` is offset from there on.

Whether the window is open depends on the wall-clock history of prior thinks. **That is the coin-flip**,
 and it is why `late>0` correlated 4/4 with `rekick=1`: a step sitting in a throttled wait with todos
  queued is exactly the "loop idle with work pending" state the watchdog exists to re-drive.

**Measured confirmation of the boundary (2026-09-04).** `MusuHeist` step 9, timestamps taken off the
 trace, three separate runs — the late arrivals land at **+115.6ms, +115.5ms and +112.2ms after
  `gallop: off todo:0`**, against a **75ms** quiescence window:

```
    +115.6ms  todo:    think +1
    +115.7ms  beliefs: begin think
    +116.6ms  think:   MusuHeist/MusuHeist→MusuHeist
    +117.2ms  beliefs: done
    [rekick]  todo:9 idle:0.04s
```

The work arrives **~40ms after the step is already eligible to snap**. It is not merely "sometimes late" —
 it lands, reproducibly, *just past* the boundary, which is precisely the signature of a 0-200ms throttle
  firing into a 75ms window. Whether it is included is then decided by where the 50ms poll phase happens to
   fall. The clustering (112-118ms over three runs) also says the throttle delay itself is fairly stable —
    so the mode flip comes from something shifting the phase, not from wild jitter.

⚠ **`got_snap` is retained for only SOME steps** (`snap 4` → `{"ok":1,"dige":"…","got_snap":null}` while
 `snap 7`/`22` return full text). So a snap-level comparison cannot be done on an arbitrary step; check for
  a null `got_snap` before concluding anything from an empty capture.

**The ttlilt covers the async but NOT the work its completion triggers.** Sizing ttlilts longer cannot fix
 this — the gap opens at `finish()`, after the ttlilt is already gone.

**The candidate fix is one call, and it is NOT mine to make.** `ponder_now()` (Housing.svelte.ts:942)
 exists for precisely this: *"an UNTHROTTLED think push, for a real event that must not wait out the
  ambient throttle… 'the disk answered' is not chatter… Use ONLY on a genuine settle — never on a poll."*
   The Wormhole op queue already uses it on IO completion (Housing.svelte.ts:2508,2512). A req settling is
    the same category of event, yet `e_reqyonciliation` uses the throttled path — an asymmetry, not an
     obvious design intent.
 ⛔ **Do not swap it unprompted.** `V1_cut_todo.md` §625 already reached this exact candidate from a
  different symptom (a starved nudge) and ruled: *"its own header says 'use ONLY on a genuine settle —
   never on a poll', so this wants the owner's eye, not a 6am swap."* That ruling stands. Note also
    `ponder_now` bypasses `no_ambient`, which a Story run sets deliberately — so the blast radius is the
     whole runtime, not just Books.

**How to test it when the owner rules.** `node scripts/story_late.mjs MusuHeist --runs=3 --steps=1-9`
 before and after: `late` should fall to 0 on steps 2/5/6/9, `rekick` with it, and the downstream flap on
  4/7/8 should vanish without those steps being touched. If it does not, this model is wrong and the tool
   says so on the first run.
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
