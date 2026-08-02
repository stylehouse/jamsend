---
name: runner-wedge-begun
description: live runner wedged at phase begun = tab-level wedge; differential-test with a known-green Book; heal it YOURSELF with the `reload` CLI op (no longer human-only). A Book that hangs at begun PRE-commission is a per-Book standup bug reload won't fix.
metadata: 
  node_type: memory
  type: project
  originSessionId: 1245bbc1-4781-4a9b-9d58-88bb490141da
---

**REMOTE RELOAD NOW EXISTS (2026-07-28) — this memory's "no reload op / needs human" is STALE.**
`node scripts/runner_ask.mjs reload --runner=<id>` hits `op:'reload'` in `Lies_runner_ask_recv`
(LiesFunk.svelte, ~line 2513): RUNNER TABS ONLY (refuses an editor), acks first then `location.reload()`
a breath later. Tonight it rebooted a wedged 49dee91d in ~27s (poll ping until channel:up+advertising) and
the fresh tab picked up on-disk .svelte edits — so it heals a TAB-level wedge (HMR-lingering mount, dead
Vite socket, frozen-boot husk) AND is how you push a render change into a runner you can't touch.
**But it is NOT a cure-all:** a Book that hangs at `phase:begun` with `run.n:null` even AFTER a clean
reload is wedging in its OWN standup BEFORE it commissions anything (VytoNest did this repeatedly post-
reload; a shot found no `.vyto` DOM at all → nothing rendered yet). That is a per-Book bug (a Prep/expecting
that never quiesces, a stuck gen import), diagnose it as the Book, not the tab. Reload heals the tab; it
does not un-hang the Book. (`ledger_missing` is a THIRD, distinct phase — the Book's ledger/fixtures aren't
recorded — again not a tab wedge.) `reload` is in the OPS list; `runner_shot --svg` now also serialises the
Vytui glass (`.vyto svg.viewport`), so a Vyto-only runner is finally shootable [[verify-via-live-runner]].

Seen 2026-07-03: the one live :9091 runner (49dee91d) accepted `become_book` but sat at `phase:begun`,
n:null, zero steps — for SwarmStaple AND known-green MusuSkip alike, predating the session's edits.

**Why:** `Lies_become_book_drive` stamps `begun` then `i_elvisto('Auto/Auto','resetStory')`; if the tab's
Story never starts (a stuck `%Creduler_pending` — one failed gen import gates EVERY Book — or a dead Auto
elvis target), every run wedges at begun forever. `runner_ask` has NO reload op; ping/advertise stay green
so liveness masks it.

**How to apply:** diagnose with a differential run of a known-green Book (MusuSkip; GhoghoDrone deleted 2026-07-13) — if it
also wedges, the tab is broken, not your Book; stop debugging your code and ask the human to reload the
runner tab. `runners` lists the Waft:Cluster roster INCLUDING dead entries (they answer "busy" then go
silent); `--runner=<prefix>` courts one, no flag = first-to-ack broadcast (may pick the wedged one).
Release your lease after (`runner_ask.mjs release`). Meanwhile iterate headless via CredRunner.spec.ts
(fixture-record still owed to the live runner, [[verify-via-live-runner]]).

**SECOND SIGNATURE (2026-07-13, whole fleet at once):** become_book ACCEPTED and the engagement stamps
(book + at fresh, age_ms:0), but `run:null` forever — not even `phase:begun`. ping/state/release answer
(relay handlers alive) yet no run ever mints and `probe` gets "refused (busy)" then 12s-silence; a cheap
green Book fails identically; waking the EDITOR (ghost-compile forces a think) does NOT heal it. Reads
as the runner-side twin of [[editor-think-quiesce-decay]]: the deferred become_book work needs a beliefs
pass the tab never runs. All 3 runners at ~1am NZ (idle for hours) showed it despite the keep-awake
commit. Same remedy: host-side tab reload; iterate headless meanwhile.

----
## merged from pere-books-total-1.md

---
name: pere-books-total-1
description: "A WEDGED runner decodes EVERY Book to total:1 (Prep-only, exits GREEN) — not per-Book; a Book green 5/5 earlier the same session flips to total:1 after mid-session HMR/clobber churn. Clears ONLY on a runner tab reload."
metadata: 
  node_type: memory
  type: project
  originSessionId: ff56d2b0-d35b-4e33-96b4-b8f73a68a322
---

**Sharpened 2026-07-07** (was "Pere-specific, cause unknown" — now diagnosed). Symptom: a Book
 dispatched via runner_ask decodes only ONE step into The/Steps, runs step 1 (bare Prep), declares
  done, exits GREEN with `total:1` — while the toc on disk holds all N `step=N,dige:` lines and all N
   `.snap` fixtures, untouched. `total` is set by Story's toc DECODE (upstream of any Book/spine code),
    so a `total:1` means the runner's in-memory Story served a 1-step Book shape.

**The proof it is the RUNNER, not the Book:** in ONE session I watched SwarmWire (5/5) and SwarmInvite
 (5/5) run FULL and green; then, after building SwarmDoor (a fresh Book: created its dir → dispatched
  → hit the [[toc-collapse-orphaned-save]] clobber → restored toc → `accept`ed → ghost-compiled
   Swarmation.g which HMR'd into the LIVE runner), SwarmInvite RE-RAN as `total:1`. A Book proven green
    minutes earlier cannot regress by its own toc — the runner's decode had degraded GLOBALLY (every
     Book now total:1, exactly like PereStaple/PereProof always were on this long-lived runner).

**Likely trigger:** mid-session churn that poisons the runner's Story/Book cache — a `ghost-compile`
 HMR of a Story ghost while the runner is live ([[hmr-remixes-ghost-methods]] + the "NEVER HMR
  mid-run" rule in [[runner-watch-false-red]]), and/or a toc clobber during a run. The FIRST SwarmDoor
   run was total:5 (fresh 5-step skeleton) — the wedge set in AFTER the clobber+accept+HMR cycle,
    consistent with cache poisoning, not a cold-boot fault.

**How to apply:**
- A `total:1` GREEN is a BUBBLE, not a pass. Never trust it; never `accept` off it (a 1-step done run
   is the shape that clobbers a toc — [[toc-collapse-orphaned-save]]). Gate: `total` MUST equal the
    toc's `step=N` line count before believing a verdict.
- The fix is a **runner tab reload** (the user's action; "runners are free, they reload"). It clears
   the poisoned decode cache; a fresh runner reads the full toc. `release` + re-acquire does NOT clear
    it (proven — survived release).
- To verify a Book WITHOUT a fresh runner, read the live run's SNAPS directly (`runner_ask snap <n>`):
   they carry the real got_snap even on a wedged decode — that is how SwarmDoor's logic was proven
    (snap 5 showed the full first-contact seal + both %see claims) though the verdict read total:1.
- Own hygiene: do NOT ghost-compile a Story ghost that the live runner is about to run against, then
   immediately dispatch — HMR then dispatch is the poison combo. Compile via LocalGen to disk, and
    let the runner pick it up on its next natural reload.
- **MULTI-RUNNER lesson (2026-07-07): a broadcast dispatch/state poisons the diagnosis.** With
   several runners registered (see `runner_ask runners`), role-broadcast `run`/`state` interleave
    replies from EVERY runner — different uids and totals mixing in one --watch stream; ONE wedged
     runner's total:1 reads like "the runner is wedged" when a healthy sibling ran the Book full.
      ALWAYS court one runner: `--runner=<prefix>` for run AND state AND steps AND snap AND accept.
       (That night: 3c5238c6 was dige-exact healthy while 91e751da sat wedged.)
- **caveat ≈ on `round=` keys is benign wobble**, not drift: the actor's belief-pass counter
   varies ±1 with tab load (HMR churn), already inside the mung/entropy tolerance — SwarmWire step
    2 has carried one for a while; SwarmGot steps 7-9 may show it. Diff the step snap: if the ONLY
     lines are `self,round=N`, it is this. A caveat on a SEMANTIC key is a different animal — look.

----
## merged from frozen-boot-empty-first-run.md

---
name: frozen-boot-empty-first-run
description: "runner tab that froze right after boot runs its FIRST dispatched Book with EMPTY steps (step 1 green, rest red, no reached:step_N) — Creduler acquire incomplete; self-heals on thaw; burn a cheap green Book before real dispatches"
metadata: 
  node_type: memory
  type: project
  originSessionId: 5208f8a1-b006-4307-96b3-31bdbb777ccb
---

2026-07-11: new wedge VARIANT beside [[pere-books-total-1]]/begun-wedge. A runner tab that
boots and immediately freezes (backgrounded — Page Lifecycle) queues inbound frames; a dispatch
that thaws it can BEGIN before the Creduler has deposited the Book's gen methods. Story machinery
(core) steps all N toc steps, but every do_fn silently no-ops.

**Signature:** run completes n=N done=N, step 1 green (machinery-only seed snap matches),
steps 2..N red with live snaps MISSING the Book's own work — no `reached:step_N`, no minted
particles. NOT the begun-wedge (steps DO advance) and NOT the total:1 decode bubble (total may
read 1 mid-run anyway — total only settles at done; phase done/failed with real total is fine).

**Differs from the old lore:** "needs human tab reload" is NOT required — the tab self-heals
once thawed (Creduler finishes); the SAME Book re-ran 5/5 green ~15 min later with no reload.

**Guards:** (1) after any tab reload/freeze suspicion, burn a cheap known-green Book
(MusuRaStock 5/5, ~20s) before real dispatches; (2) a `--watch` "runner DEAD" verdict during a
thaw can be FALSE — the run may be progressing/finished (state polls starved while stepping);
re-ask `state` before releasing; (3) the thaw is visible in the socklog as a burst of queued
`control:runner_ack`s flushed in ~ms.
