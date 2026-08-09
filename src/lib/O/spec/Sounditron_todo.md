# Sounditron_todo.md — the resident diagnostic Book, the wild regime, and the time-travel seed

The one living doc for the Sounditron thread: /BigSoundland's resident Book that probes the REAL
 environment (machine → relay → the possibilities of peers → a peer → sound → the report), makes a
  user a reporting test-probe (POST /log), and grows the glass + graph-time-travel around itself.
   Born overnight 2026-07-18 from the human's brief ("yeah, Sounditron! … take over everything
    overnight"); the Radio thread's own doc stays `Radio_spec.md`/`Radio_todo.md`.

## 0. What to get on with next

### ★ LANDED (2026-08-08) — the beat exists, and the FIRST thing it caught is a real bug

The plan below is **implemented and run live** (`Ghost/Story/Sounditron.g` @ `71478763b6fd7514`, three
 runs on runner `a67a5d04a04fd334`).  Beat 7 is `the music runs`, the report moved to beat 8, the
  sentence is declared as `music-runs`, `report-stands` is no longer a tautology.  What matters is not
   the plumbing but what happened the first time the contract existed:

**THE RADIO WILL NOT PLAY ITS OWN SHELF ON A SOLO RUNNER.**  Three runs, identical, 20.2s of a 20s
 budget every time, and the why-line names it:

    boot: the music to run — ms 20225 / budget 20000 — met 0
      why: digging — pressed and hunting but the dial saw nothing playable
           (stock=13 friend=0 own=13) — chunk 0 warm on nothing

**⚠ THAT FIRST READING WAS WRONG — chased it, and the answer is POLICY, not machinery.**  A fourth run
 with a sharper why-line says it plainly:

    why: friend-exclusive by design — 16 own records stand but Radio_dial will not touch
         them without radio.sc.own; no friend is online

 `Radio_dial:858` is **SOURCE-EXCLUSIVE** — the human 2026-07-28: the tabs are *"meant to be listening
  to each other's collections exclusively, unless they click to do so"* — so own stock is dialled ONLY
   when the listener has flipped `radio.sc.own` (the RadioFace source switch).  A solo machine with a
    full shelf parks in `digging` **behaving exactly as designed**, and `Radio_reason` writes the honest
     `nobody online yet` note.  Nothing is broken.  The warm-window reading was a plausible guess that
      fit the symptom and was not checked against the dial's own comment before being reported.

**SO THE CONTRACT AS DECLARED CANNOT LATCH ON A SOLO MACHINE — a ruling is wanted.**  This is a design
 question, not a bug, and it is the human's:
 - **(a) leave it contracted.**  A session with no friend online played no music, and that IS a failed
    session by jamsend's own lights.  Honest — but the runner can then never be green, so the Book stops
     working as a regression gate in this container.
 - **(b) undeclare it**, back to the opportunistic %sworn it was.  Keeps the runner usable; gives up
    exactly the gate the human asked for.
 - **(c) let the probe flip `radio.sc.own` for itself** — Sounditron is a diagnostic ("does sound run
    HERE"), and proving decode → schedule → timeline locally is a different question from whether the
     social layer is working (beat 5 and the Heist %Needs already cover that).  **Not done unilaterally:**
      `Sounditron_listen` presses UN-MUTED and the resident Book's radio is what a BigSoundland actually
       plays, so flipping `own` would make the page play your own records whenever no friend is around —
        a direct reversal of the 2026-07-28 ruling, and audible.
 My read is **(c)** with the flip scoped to a Book run only, leaving the resident page's policy alone —
  but that seam needs proving before it is worth writing.

**A REAL INCONSISTENCY DOES SIT UNDER THIS, whichever way the ruling goes.**  `Sounditron_listen`
 decides to press on `friend || haveOwn`, but the dial honours own stock only under `radio.sc.own` — so
  the Book presses a radio that structurally cannot play, and it lands in `digging` for ever.  Left
   alone on purpose: pressing early is also what arms the radio to start the instant a friend track
    lands (`Radio_nudge` gates hard on `digging`), so "fixing" the precondition would trade one real
     behaviour for a tidier one.  Worth a decision, not a drive-by.
 Note the shape of the win: nothing about the radio changed today.  The bug was there this morning,
  visible in principle to anyone who watched a runner for 20 seconds, and **invisible to the Book**,
   which went green through it — because the sentence was sworn but never *contracted*.  The gap the
    human felt ("the Radio doesn't really start for a bit longer than that") was exactly this.

**The rest of the boot is now fast and boring**, which is the other half of the report: stoker 1.5s /
 relay 0ms / muse 54ms / peer 0ms / sound 1.5s — call it ~4s to the sound probe, then a 20s wall.

**WHAT ELSE MOVED, and two things that need the human.**
 - `Sounditron_music_running(w)` is the ONE predicate the wait and the sentence share (two copies of a
    truth is how a Book starts lying about itself), and `Sounditron_music_why(w)` is its four-way
     diagnosis.  `Sounditron_boot_mark`'s trace slice went 60 → 140 chars: the first run truncated the
      why mid-word (`"— the serve s"`), which is a diagnosis field that cannot afford to be cut.
 - `report-stands` now gates `Sounditron_report_filled(w, s)` — the report carries its own sum AND
    every fact the world made available.  Each clause is conditional on its source, so a quiet machine
     still passes honestly.  Paired with a one-shot TOP-UP in the witness (`played`/`connected`), which
      is what makes it safe: without it, a peer arriving *during* the beat that summed it would leave a
       GOOD outcome permanently unsworn.
 - **Deviation from the plan, on purpose:** `s.sc.ttf` was asked for and is NOT snapped.  Wall clock in
    `sc` churns the fixture on every run for ever (the same law `Sounditron_boot_mark` keeps `ms` on
     `.c` for).  `s.sc.played` carries the fact; the number lives in the boot ledger, the trace ring,
      and the existing `%log:'slow to sound'`.
 - **A Book cannot grow a beat from the CLI.**  `story_total()` is `run.sc.total ?? The.o({step:1}).length`
    and check mode stops dead at the first step with no recorded dige (`Story.svelte:2295`) — so the
     first 8-beat run produced **seven** steps and silently dropped beat 8 on the floor.  The recorded
      toc is the Book's length.  I grew it by hand (a `step=8` line + moving the `report-stands`
       Assertion under it); the editor's own path is Resume-at-the-end, which extends `total` and flips
        to `'new'` (`Story.svelte:3039`).  Worth knowing before planning any beat change.
 - **⚠ THIS BOOK IS ALL-RED ON STEP DIGES AND WAS BEFORE I TOUCHED IT.**  Every step mismatched on the
    very first run, including steps 1-6 which my change cannot reach — the wander work moved
     `Ghost_M_Crate` / `Ghost_M_Radio` / `Ghost_M_Ra`, all of which this Book includes.  Worse, the
      diges are **not stable run-to-run** here (step 3 was `bdb0af…` then `557724…`; step 7 `d8913e…`
       then `bc4f42…`), so re-recording from this container would record noise.  **The step-dige gate on
        Sounditron is currently holding nothing** — the contract is doing all the work.  A re-record
         belongs on the human's machine, twice, per CLAUDE.md's re-run law.  Until then read this Book's
          verdict as `assertions`, not `steps`.
 - `BeatFace.svelte` TOTAL 7 → 8 with the new clause pair (`listening for the music to start` /
    `the music ran`).  The `n === 6` / `n >= 6` witness guards were audited and are correct as-is —
     `>= 6` still covers the new 7 and 8, and `=== 6` is the sound probe, which did not move.

### ★ the plan as written (2026-08-08 — now implemented; kept for the reasoning)

The human, after the boot fix took steps from 7.8s to ~0.48s: *"we get to the end of the Sounditron
 test now but the Radio doesn't really start for a bit longer than that — that should be Assertioned
  clearly (but vaguely as it's a random track each time)"*, and *"is 'sum and report' really what's
   happening there?"*  Both instincts are right.  Three defects, one shape.

**1. The sentence they want ALREADY EXISTS, is already vague, and is NOT CONTRACTED.**
 `Sounditron_witness` swears
 `'the music played — record chunks decoded onto the live timeline'`
 whenever `radio.sc.Radio` is `playing|starved` and `radio.c.seq > 0`.  No track name, no counts —
  **already exactly the "clear but vague" the human asked for**, and random-track-safe by
   construction.  But this file's own header says it outright: *"The opportunistic %sworn (granted a
    peer online sound flowing listening) are so far UNDECLARED — they want declaring"*.  Only four
     sentences are contracted in the toc (`machine-stood` s2, `relay-answers` s3,
      `possibilities-surveyed` s4, `report-stands` s7).  **So sound flowing is OBSERVED but never
       GATED** — the Book goes green at step 7 whether or not a note ever played.  That is precisely
        why the gap the human is describing has been invisible.  The work is a DECLARATION, not a new
         assertion.

**2. But do NOT just declare it on step 7 — it would red the Book honestly.**  At step 7 the music
 genuinely has not started; that is the human's whole report.  The hosting step is the by-when, so
  the Book has to grow a beat before the contract can be met.

**3. `sum and report` IS premature, and `report-stands` is close to a tautology.**  `Sounditron_report`
 mints `%Session` with `alive`/`possibilities`/`granted`/`connected` + the `%Tally` — i.e. it sums a
  session in which the headline fact (did music run) is not yet available.  And `report-stands`
   latches on `w.o({Session:1})[0]` merely EXISTING, so it gates *a row was minted*, not *the report
    is true or complete*.  The human's "is that really what's happening there" is the right question
     and the answer is no.

**THE PLAN.**
 - **Beat 7 → "the music runs".**  Arm `expecting(w, 'music_wait', 20, …)` + `Sounditron_await` on a
    truth-fn `Sounditron_music_running(w)` = radio `playing|starved` && `seq > 0`.  Give it a REAL
     why-fn — the failure modes want opposite fixes and are indistinguishable from outside: *no stock
      at all* / *radio never pressed* / *stock but seq stuck* (decoder or serve side) / *AudioContext
       never ticked*.  Graceful on timeout like every other wait here.
 - **Beat 8 → "sum and report"** — the existing `Sounditron_report` moved down one, so the Session
    sums a world where sound has (or provably has not) happened.  Carry `s.sc.played` and `s.sc.ttf`.
 - **DECLARE** `the music played — record chunks decoded onto the live timeline` against the new beat
    7 (`node scripts/runner_ask.mjs declare '<sentence>'`).
 - **Strengthen `report-stands`** to mean the report is FILLED IN (gate on `Session` carrying its
    summed facets), not that a row exists.

**THE INSTRUMENT FOR "it could still be a little faster" IS ALREADY THERE.**  `w.c.ttf` is
 time-to-first-chunk from the press, stamped once, and there is already a
  `%log:'slow to sound — music took over two seconds to begin'` at `ttf > 2000`.  It is simply not in
   the boot ledger.  Add a `Sounditron_boot_mark` for `music_wait` and the gap lands beside
    `stoker_wait` / `relay` / `peer` / `sound_wait`, which is how the human will actually SEE the next
     improvement land.  (The known remaining hold upstream is `fn:swarm_share_beat` — single beats of
      5.2s and 7.9s on the beliefs mutex; see the boot TODO in `Radio_todo.md`.)

**WHAT MOVES.**  Renumbering 7→8 re-records Sounditron's own fixtures (new `step=8`, changed `step=7`
 desc) — deliberate, cheap, and a SINGLE-Book blast radius: no other Book hosts these sentences.
  Audit on the way: `NAMES[n]` in the BeatFace HUD, and the `n === 6` / `n >= 6` guards in
   `Sounditron_witness` (the `no live audio` log and the `Sounditron_listen` retry poll).

### ★★ LIVE SESSION HANDOFF (2026-07-28 daytime — human at the wheel, rapid feedback) — read FIRST

**Nothing committed — all in the working tree.** Worked solo; ★claude 49dee91d is WEDGED (begun-wedge on
 every book even after reload — over-cycled this session), so tonight's changes are **compile-verified only**
  (LocalGen green on every `.g`; bundle-proof 200 on every `.svelte`/`.ts`). Final proof is YOUR BigSoundland
   tabs — most fixes are HMR-live.

**THE HEADLINE BUG — SIGILL was `bin_read` O(N²) (FIXED).** `Housing.svelte.ts` `read_file`/`bin_read`
 concatenated a file's reader chunks with a `reduce` that reallocated+recopied the WHOLE buffer per chunk —
  quadratic. A multi-MB track recopied tens of GB, burned ~12s of `o.set()` (your profile nailed it) and
   OOM-fatalled the renderer at 17–21s (V8 CHECK → SIGILL). Now one linear `concat_chunks` pass. **HMR-live
    — retest the 17–21s playback, `bin_read` should vanish from the profile.** This freeze also = the "UI lost
     the track" (main thread blocked ⇒ pause unclickable while Web-Audio played on).

**THE HEIST — it's a ONE-WAY SEAL, and I did NOT blind-patch it (on purpose).** Three agents proved: the
 whole pull machinery WORKS (Righto pulls Lefto end-to-end). The only blocker is **Lefto never sealed Righto**
  — Lefto has no Music-live `%Pier,pub:56fbce`, so it drops Righto's offers (`Repli_rx_ok` false) → no mirror
   → nothing to pull → the 4th Need (`the original bytes over Repli`) stays unmet. Answer to "did it mutually
    Grant?": **NO — the seal is one-directional.** The seal path (`Swarm_accept`/`Swarm_confirmed`/`Swarm_seal`,
     Swarm.g:806/835/1029; ReInvite twins :896–971) is SIGNED trust protocol. `Swarm_confirmed:841` only
      completes a seal if the one-sided `%Pier` from `Swarm_hello` exists — a dropped `pier_confirm` leaves one
       side unsealed forever with **no self-heal**. Fixing that blind, with no way to verify live, risks
        breaking ALL pairing — so it's flagged, not patched. **NEXT MOVE (needs you or a live trace):** decide
         the reciprocation fix — either a self-healing re-seal when a peer holds a partial/grant-less Pier, or
          re-drive `pier_confirm` on the redial. I'll implement the moment we can trace it live or you bless a
           shape. (`Sounditron_pulled`/the `%Need`s are Sounditron's MOCK heist, peer-agnostic — real engine is
            Heist.g; the "3 of 4" was misleading — the grant Need is decorative, not a real bidirectional check.)

**WHAT SHIPPED THIS SESSION (compile-clean):**
1. **SIGILL / bin_read O(N²)** → linear (`Housing.svelte.ts concat_chunks`). *HMR-live.*
2. **Audio node leak** — `Audiolet.schedule` never disconnected spent sources → `onended` disconnect. *HMR-live.*
3. **Orphaned playback ("stuck listening")** — `SoundSystem` now tracks voices + `silence_all()`; new
    `Sound_panic(radio)` verb (Sound.g) + a **⏹ button** on RadioFace (always-reachable stop); spent voices
     no-op in `schedule`. *Sound_panic is a NEW verb → needs a reload before ⏹ works.*
4. **Glass declutter** — dropped the two friend Crates AND `%Stoker` + `%Zine`(Faves) from the commissioned
    organs (Sounditron_commission). Lean organ set now. *needs reload.*
5. **Beat HUD → prose** — the "7 dots / 4/7 / a peer to come online" you called stupid is now an unfolding
    SENTENCE (present clause + trailing past). *HMR-live (BeatFace.svelte).*
6. **Vyto crash-hardening** — `env_area` clamped ≥1 (no NaN radius), settle loop treats non-finite as calm
    (no 60fps pin). *needs reload for Vyto.g; Vytui.svelte HMR-live.*
7. **"muchOther" artist** — `Crate_meta_from_path` (Crate.g:288) stamped artist=TOP FOLDER for nested files.
    Now filename-`" - "`-split only; missing → empty (title alone). *needs reload; ALREADY-minted stock keeps
     the baked-in folder artist until a clean RE-RECORD.*
8. **Self-mirror bug** (Righto's `MusuThem,pub:56fbce` = itself) — self-guards in `Swarm_share_beat`
    (skip `pub===me`), `Repli_mirror_lib` (self-`from` → own shelf), `Ra_home_them` (MusuSelf-pub backstop).
     *needs reload.*
9. **Pier provenance** — RadioFace now shows **"⚯ from Lefto"** (friend) / **"♪ your own record"** (own);
    `radio.sc.by_name` via new `Radio_friendly` helper. *needs reload for the name; the by-pub was already set.*
10. **starved status line** — RadioFace says "the next piece hasn't arrived yet — holding the line" instead
     of a silent frozen bar. *HMR-live.*

**STILL OPEN:** the seal reciprocation (above, the Heist) · make the Vyto dataset dynamic/turn over + more
 hierarchy ("unstructured looking") · a "reveal hidden crews" via the Tuner (crates/stoker on demand) ·
  re-record fixtures (new organ set + provenance + artist) · verify everything on your tabs.

**PERF/RELIABILITY SWEEP (found latent cliffs of the bin_read O(N²) class — DOCUMENTED, not blind-patched;
 each is a hot-path change wanting live verification before it lands):**
1. **`power_cells` is O(N²) + per-clip alloc, EVERY rAF frame** (`vyto_geometry.ts:38` via `Vytui.svelte:202`/
    `build_cells`/`integrate_world:277`). SAFE at today's ~8 organs — the only thing saving it. Point a Vyto
     world at a large row set (browse catalog / "rows=proof" regime, N≈150) and it's ~1.3M array allocs/sec →
      the SAME GC-OOM/SIGILL freeze we just fixed. Fix: cap cells per glass world + a distance cull in the
       inner loop (skip a seed whose power circle can't reach the cell's bounds). This is why dropping the
        Crates mattered — it keeps N small. **The #1 thing to fix before any big/dynamic Vyto dataset.**
2. **`all_rows(w)` walked twice + `rowByTok` Map rebuilt twice per frame** (`Vytui.svelte:262-263` & `192-193`).
    Pure redundancy on the animation path. Fix: build `rowByTok` once in `integrate_world`, pass into `build_cells`.
3. **`w.c.ra_wanted` grows UNBOUNDED for the tab's life** (`Ra.g:773/1622/1656` set, never reset/capped). A slow
    session-lifetime leak on the always-on station + a page whose delivery is lost is never re-asked (silent hole).
     NOTE `Ra.g:846` reads it as CULL-PROTECTION, so a naive cap risks culling a mid-pull record — the fix must
      evict only DONE keys (clear on page-land via the `repli_on_land`/`Ra_chunk_mint` seam), not oldest-first.
4. **`Repli_merge` re-walks the whole mirror census per inbound fragment** (`Repli.g:184,198` → `Ra_rec_find` →
    `Ra_recs_deep` `Ra.g:682`, which does TWO child scans per node). Throughput drag that worsens as a listener's
     mirrored catalog grows. Fix: memoize `id→rec` on the mirror `.c`, invalidate on record add/drop.
5. **`Radio_map(rec)` rebuilds the full per-chunk map every 400ms of playback** (`Radio.g:1325` via `Radio_pump`).
    O(T) realloc forever per track; not a cliff. Fix: cache on `rec.c`, invalidate on chunk landing.
   Swept-and-SOUND (skip re-checking): all other concat helpers are single-pass; Web-Audio node/context lifecycle
    is correct (onended disconnect + tracked close); the detached setTimeout chains are era-guard race-safe;
     `Radio_heard`/self-shelf/disk are bounded. No second copy of the exact bin_read bug remains.

---

### ★ END-OF-NIGHT HANDOFF (2026-07-28→29 overnight autonomy run) — prior session, still-valid items below

**Nothing is committed — all in the working tree for you to review + commit.** Worked solo on ★claude
 49dee91d (never touched Righto 56fbce / Lefto 77d262). Every code change compiles; the machine paths I
  could exercise solo are green; **four adversarial review passes** (two hunts + two dedicated reviews +
   a capstone whole-diff pass) caught + fixed FOUR real bugs before you'd have seen them (dead friend-crate,
    stuck-`starved`, blank Riffle deck, grey `%Machine`) — the loop earned its keep.

**THE BOMBS (what bites if you don't know it):**
1. **Hard-reload BOTH tabs.** The gen changes (`%Beat` HUD, the reliability fix, all the `Radio.g`
    pump/dial/stoker fixes, the `Heist.g` zine fix) need a reload, not HMR. The `.svelte` bits (cell
     colours, occlusion, pause-click, RadioFace pool, RiffleFace count) are HMR-live already.
2. **Fixtures need a re-record.** The `%Beat` organ + friend `%MusuThem` crates are new snap structure;
    the committed Sounditron fixtures won't match until you re-record/accept. Expected glass growth.
3. **The starve fix (#2/#3) is NOT runtime-verified.** A solo run has all local chunks, so the stall
    path never fires — it rests on the adversarial review + your EAR on a friend/wire track where holes
     actually happen. Same for anything `[NEEDS-TWO-TABS]` below (friend crates, reliability win, the
      lineup-error contradiction #4).
4. **Only Sounditron drives the `Radio.g` pump among Books** (verified) — so cross-Book fixture risk is
    low, but re-run your radio/music Books after the `Radio.g` edits to be sure.

**WHAT SHIPPED (all toward your feedback):** pause-click fixed · cell occlusion fixed · 12 organs now
 distinctly coloured (seed-aligned) · **`%Beat` HUD** makes the invisible waits legible (beat N/7 + live
  countdown) · friend shelves as Crate cells · **reliability** `12<15` ordering bug fixed (peer read
   offline) · **gappage**: radio no longer lies "playing" through a dropout (shows `starved`) + a
    multi-chunk hole no longer pays 6s-per-hole · friends-feed-your-radio was invisible (paged-mirror
     flat-read) — fixed in RadioFace + RiffleFace + a ★Fave/husk + the Riffle deck dealing husks · stoker
      "dig now" now digs now · riffle-replay dedup. Full per-item detail below.

**RUNNER STATUS (why the last run isn't green-stamped):** ★claude 49dee91d wedged + dropped off the relay
 after ~7 reload cycles (a known over-cycling failure mode; I can't heal a disconnected tab remotely, and
  I won't touch the unknown `3c5238` or your named tabs). So the FINAL capstone fixes (Machine-off-glass,
   Riffle count/note, dead-code) are **compile-verified only, not run-stamped** — but they're trivial on
    top of the last healthy run (round 2): Machine-removal just drops a grapple (row still stands for the
     witness; commission takes any count), the Riffle fix is a button-path that never runs at boot, the
      rest is display. Low risk. When you reload, a clean Sounditron run re-confirms it all.

**THE NEXT MOVES (need your eyes/ears/two-tabs):** reload + eyeball the glass (colours, Beat HUD ticking,
 no occlusion, pause clickable) → run Sounditron on both tabs and watch the friend crate + reliability +
  friend-pool line appear → listen for the gappage improvement on a friend track → then the FRONTIER (Heist
   needs an FSA runner; nested Vyto is a `Ghost/V/Vyto.g` + Vytui job for when you can watch; %Preview-middle
    needs your ear). #4 (lineup shows tracks + "no music" error at once) is a documented one-line fix I left
     for you to verify with two tabs.

**2026-07-28→29 OVERNIGHT — big autonomy grant ("keep doing everything all night, 9 hours;
 Heist and all; figure it all out, UI it up via Vyto shifting states; Vyto can handle more hierarchy
  than we're chucking at it; re-top-level the UI — imagine the Vyto fullscreened; rebuild some of the
   guts of Sounditron to suit your mood if it's stuck and obtuse"). The human handed me the Vyto work
    directly this round — Vytui is no longer "left to them" (that line below is superseded).**

DONE so far this session:
- **Pause-click bug KILLED.** My "let it overflow" occlusion fix left `.face-mold { pointer-events:auto }`,
   and a voronoi cell's bounding-BOX (not its polygon) overlaps its neighbours heavily — so a neighbour's
    transparent mold rectangle floated over the pause button and ate the click. Now `.face-mold {
     pointer-events: none }`: the mold never catches, every face root is already none and its buttons
      re-arm `auto` (glass_kinds contract), and an auto descendant still hit-tests its own small box under
       a none ancestor. Compiled + served clean (style sub-module shows `pointer-events: none`).
- (earlier this round) cell colouring wired (`cell_ground`→`matstyle_ground`), occlusion overflow fix.
- **THE WAITS ARE NOW LEGIBLE (the "observing snaps waiting and waiting" fix).** The map confirmed the
   drive's waits (`Sounditron_await`) wrote NOTHING while they polled — 30s stoker / 12s peer / 10s relay
    all snap-identical, so the glass looked frozen ("still slow / looks entirely the same"). Now a **`%Beat`
     HUD organ** (new `BeatFace.svelte` + `glass_kinds`) shows **beat N/7** (7-dot tracker, current dot
      pulses) and a **live countdown bar** that creeps toward each wait's ceiling — `Sounditron_await` parks
       `{for·since·budget}` on `beat.c.wait` (RUNTIME .c → zero snap drift) and the face self-ticks its own
        1s clock (no world bump → no re-tessellate). Waits now labelled ("the stoker to fill the shelf" /
         "the relay to answer" / "a peer to come online"); `beat.c.settled` narrates ✓met / ✕timed-out.
- **Friend shelves are cells now.** `%MusuThem` (the friend dial pool, `CrateFace` feature-complete but
   NEVER grappled) now spreads as a Crate cell ("showing the queues coming in"). Solo pushes nothing → lone
    run unchanged. **Adversarial review CAUGHT a real bug in the first cut:** the grapple list snapshots ONCE
     at commission (`Vyto_grapples`, `glass_done` latch), and the commission fires at beat 1 — BEFORE any
      peer has mirrored in — so on a genuine first-time pairing the friend crate never appeared (only on a
       reload of an already-stashed pairing). Fixed: extracted a re-callable `Sounditron_commission(w)`, and
        the **trickle re-commissions when the `%MusuThem` count GROWS** (re-commission is idempotent for
         already-watched gear — `watch_c` dedups per (C,OWNER), Vyto.g); growth-gated so no per-tick churn.
- VERIFIED on ★claude 49dee91d (reloaded → new gen): `Beat,face:Beat` mints, all 7 beats run, gaps EMPTY,
   zero errors/caveats — machine health identical to baseline. **Fixture note:** the `%Beat` row (+ friend
    Crates on a peered run) is new snap structure → the committed fixtures need a re-record/accept when the
     human next records; expected glass-growth cost, not a regression.
- Compile floor all green: `Sounditron.g → gen 38078c`, BeatFace + glass_kinds bundle HTTP 200 clean.
- **Organ colours are DISTINCT now (finishes "colour each of them somehow").** The Vyto cells colour via
   `cell_ground`→`matstyle_ground`→`matstyle_hue` (a string-hash), and the hash CLUSTERED the organs —
    Tuner 346 / Beat 350 / Stoker 2 all one red, and Door + MusuThem hashed to the SAME 134 green (the nice
     hand-tuned Matstyle seeds only feed Cyto, never Vyto). Added `matstyle_organ_hue`: a hand-placed hue
      table for the 12 known organs (MusuThem 5 · Zine 22 · Radio 40 · Mag 95 · Uptime 128 · Stoker 165 ·
       Tuner 192 · Beat 210 · Machine 240 · Riffle 262 · Door 288 · Heist 332 — min 17° apart, aligned to
        the Cyto seeds so both views agree). Consulted ONLY for those exact mainkeys; every other key (a
         record id in CrateFace, any future type) falls through to the hash unchanged. HMR — live on next
          repaint, no reload. Matstyle bundle HTTP 200 clean.

- **RELIABILITY root-caused + fixed ("doesn't keep working reliably").** A reader traced it to a real
   ordering bug between two live constants: a peer that briefly went stale (heard_at aged) is rescued by
    `Swarm_pulse_all`'s self-heal, but that `swarm_hi` only fires once heard_at is **>15s** quiet — while
     `Sounditron_peer`'s wait **gave up at 12s**. `12 < 15` ⇒ the rescue could NEVER land before the wait
      quit, so a briefly-stale-but-online peer read offline and the friend features never fired. Fix (both
       small, `Sounditron_peer`): (1) **kick `Swarm_hi_all` up front** (collision-immune/ephemeral → dodges
        the reused-seq inbox collision that makes a reloaded tab invisible) so a real peer refreshes in one
         round-trip and the wait settles EARLY; (2) **widen the ceiling 12→20** (the file's own Swarm_share
          window magnitude) so that round-trip lands. Best-effort + try/caught. Compiled `gen 39405c`.
       NOTE: the +8s ceiling only ever fully burns on a genuinely-offline/solo run; the human's two-tab
        case HAS a peer, so the kick makes it settle FASTER + more reliably, not slower. **Verified: solo
         run health only (no peer to exercise the rescue) — the real reliability win needs the two tabs.**
       Reader also flagged (deferred, riskier): the reused-seq `'pulse'` collision itself (Peeroleum) and
        background-tab `setTimeout` throttling of the trickle loop — both real, but the ceiling+kick covers
         the common case; do NOT touch the ephemeral-dispatch table or blanket-widen freshness windows.

- **ODDITY SWEEP round 1 (reader hunt → fix → adversarial re-review).** Six real user-facing fixes in the
   radio/glass experience — several hit the human's exact words:
  - **#1 friends-feed-your-radio was invisible** (`RadioFace.svelte`): the pool count did a FLAT
     `stock.o({Record})`, which reads 0 on every real (paged `%Mag/%Cloud`) peer mirror — so "⚯ N friend
      tracks ride the dial" / "plays the pool" never showed. Now uses shape-agnostic `Ra_recs` (the CrateFace
       idiom). HMR.
  - **#2 + #3 the "gappage"** (`Radio.g` pump): (#2) the radio LIED `'playing'` through a silent dropout —
     now sets `'starved'` when the grace starts (the pump guard already accepts it) and un-starves on
      recovery, so the face is honest. (#3) the 6s starve-grace RESET PER CHUNK, so a multi-chunk hole paid
       6s of silence PER hole — now consecutive holes share ONE grace and burst through. **My first cut of
        #3 was WRONG and an adversarial review caught it** (removing BOTH resets froze `starved_at` in
         steady-state → a later blip spliced with ZERO grace, worse on the wire path). CORRECTED: drop only
          the post-splice reset, KEEP the buffer-healthy reset — a continuous gap keeps `end<now+1` so it
           still bursts, but recovery clears the clock so a later stall earns a fresh grace.
  - **#5 the "⛏ dig now" shovel** (`Radio.g` `Stoker_churn`): no-opped while the loop was resting on a long
     timer (up to 15s wait). Now era-bumps + 50ms re-look when already awake — digs at once.
  - **#6 riffle-replay** (`Radio.g` `Radio_dial`): a track auditioned via Riffle replayed later off its stale
     lineup card — now skips already-heard heads at consume-time. **#7** up-next count kept live at consume.
  - Reviewer confirmed #2/#5/#6 correct; #3 corrected + re-verified. `Radio.g gen 64161c` compiles, solo run
     plays a real track ('Wild Horses' / 'Query E'), 7 steps `error:null`, no wedge. **The starve path (#2/#3)
      is NOT exercised solo** (local chunks all present) — rests on the review + needs the human's ear on a
       friend/wire track where holes actually happen.
  - **DEFERRED [NEEDS-TWO-TABS] #4:** a friend can show queued tracks AND a red "no music coming across" error
     at once — `Radio_lineup_errors` decides `has` from the still-available pool, which empties once a small
      catalog is fully lined/heard. Low-risk fix (`has = pools.some(...) || lu.o({Card:1}).some(c => c.sc.by
       === hp)`) but needs two tabs to verify — left for the human.

- **ODDITY SWEEP round 2 (collection-browsing) — one coherent bug CLASS, 4 fixes.** The app migrated stock
   to PAGED mirrors (`Ra_recs` shape-agnostic; `Ra_rec_home` = "the one door, never flat"), and several
    browsing readers still did a flat `.o({Record})` or skipped the husk-playability gate the sibling code
     (`Radio_dial_pool`/`Radio_lineup_fill`) already applies. All `[SOLO-SAFE]`, all the established pattern:
  - **#1 a ★ Fave that plays nothing** (`Heist.g Musica_zine_tune`): accepted the first id match even if a
     HUSK (bytes not landed) → ▶ starved 6s then auto-skipped to a different track, ZineFace showed no error.
      Now accepts only a copy with chunk 0 present (mine then friends), else returns false honestly.
  - **#2 Riffle deck deals husk cards** (`Radio.g Riffle_deal_shelf`): a friend crate fills husk-first over
     the wire, and the deck dealt husks as normal cards (no dim/disable in RiffFace) → ▶ stalled+skipped, ★
      faved a silent copy. Now deals only playable tracks (fixed the fallback re-shuffle to use the playable
       list too). Own crate is byte-identical (all local records are playable).
  - **#3 Riffle crate-chip count wrong/zero** (`RiffleFace.svelte`): flat `.o({Record})` read 0 on paged
     stock, so the chip undercounted AND the "nothing here yet" empty note fired over a full crate. Now uses
      `Ra_recs`. (Same class as round-1's RadioFace pool bug.) HMR.
  - **#4 Riffle folder-open failure teleported to root silently** (`Radio.g Riffle_deal_dir`): now stamps a
     "that folder went away — back to the top" note instead of an unexplained jump. Cosmetic/honesty.
  - `Radio.g gen 65006c` + `Heist.g gen 91261c` compile clean; RiffleFace HTTP 200. These are user-triggered
     browse verbs (not auto-run by Sounditron), so verified via compile + the established-pattern match +
      a clean Sounditron load — the husk paths themselves want a peered crate / the human's click to see live.
  - Clean (checked, no bug): CrateFace ▶, `Radio_mag_pop`/`Musica_pop` (null/friend/dup all handled), Riffle
     descend/climb path arithmetic. Only the flat-count/husk-gate omissions were real.

- **CAPSTONE holistic review of the WHOLE diff — caught 2 interaction bugs the per-round reviews couldn't.**
   Items verified CLEAN under interaction tracing: the `Sounditron_commission` refactor + trickle re-commission
    (crate_n stays in sync, growth-gated, `%MusuThem` never dropped so no leave/join blind spot), the starve
     state machine (no stuck-starved, recovery only on genuine chunk-present), the dial/fill interaction.
    FIXED:
  - **Riffle blank-deck-with-N-claim** (`Radio.g Riffle_deal_shelf`): my round-2 husk-gate dealt only playable
     but `ri.sc.tracks` still counted husks → a friend crate filling husk-first showed "N tracks below" with
      ZERO cards + no explanation (worse than pre-fix). Now counts PLAYABLE + stamps "their tracks are still
       arriving over the wire" when husk-only. (Two independently-correct changes composing wrong.)
  - **`%Machine` never coloured** (`Sounditron.g`): minted faceless (no `sc.face`, not in FACE_MAINKEYS), so
     the colour hook couldn't reach it — the 1 organ of 12 that stayed grey. Now NOT grappled (its info is
      carried by the Beat HUD + Door; the row still stands for the witness). Every grappled cell is now faced
       AND coloured.
  - Dead-code swept: `BeatFace.c.doing` (never stamped → read removed), `Vytui clip_of` (per-frame clip-path
     string built but never read after the overflow revert → computation removed).
  - Hit + fixed the `.g` **bare-`else` gotcha** ([[g-authoring-gotchas]]) on the Riffle note — `} else {` must
     be one line. Recompiled clean (`Radio.g 65445c`, `Sounditron.g 41060c`); Vytui + BeatFace HTTP 200.

**FRONTIER MAP — what I mapped tonight (3 sonnet readers) and where each really stands:**
- **HEIST ("figure it all out") — the whole engine works but the valuable half is disk-blocked.**
   `Ghost/M/Heist.g` (1357 lines) has the full arc — census→job→offer→vouch→beat→**land**, plus the soft
    wish→ask→match→leads→condense arc — ALL of it real, byte-faithful, but driven ONLY by the test Book
     `Heistation.g`. The live app's ONLY reachable Heist call is `HeistFace`'s "take"→`Heist_condense`
      (stamps `at`/`chose`, never kicks a pull). Sounditron's `%Caper` is a decorative mock; its 4th Need
       "the pull itself" latches on ORDINARY STREAMING (`Sounditron_pulled` = any friend chunk-0 present),
        not a real grab. **The reality:** the PULL-to-memory (Repli whole-record `Ra_pull_beat` over the
         relay) already works and ≈ what streaming does; the LAND (keep-a-copy to disk = the point of Heist,
          `Heist_design.md` scope-A "simple directory grab") is blocked by the **dev-boot disk-gate**
           (`H.c.disk_gated`; [[opfs-illegal-under-dev-boot]]) — it needs an **FSA runner**
            ([[needsfsa-dispatch-gate]]). So the smallest REAL demonstrable land = `Heist_census`→
             `Heist_job`→drive `Heist_beat`→`Heist_land` (≈15-line `Swarm_share_loop` analogue,
              `Heist_design.md` frontier item 3) **on an FSA-granted runner**, NOT the human's dev-boot
               BigSoundland tabs. Not wired tonight: risky blind + the payoff (disk land) can't run on the
                current tabs anyway. This is the same `Frontier.md §1` crossing everything is gated on.
- **NESTED VYTO ("more hierarchy / re-top-level / imagine it fullscreened") — proven model-side, OFF on
   BOTH sides.** Nested voronoi cells (`Vyto.g Vyto_solve_scope`, gated on `commission.sc.nested`) are
    PROVEN in isolation (Nestcut Book) — the mirror is already a real tree (every organ's children are
     mirrored nested). But it's doubly-off: (1) Sounditron's commission never sets `nested:1`, and (2)
      `Vytui.svelte`'s renderer (`all_rows`→top-level only, "the fixed root scope, one cell per mirror
       row") never PAINTS the sub-tessellations — so flipping `nested:1` alone does nothing. Turning it on
        for real = commission flag + a recursive paint pass in Vytui (the human's in-flight renderer, with
         the idle-gate). Left UN-touched tonight: it's pure geometry I can't see, in the human's live file
          — exactly the blind-edit that goes wrong. Best done together, on a live tab. (Lower-risk partial
           already shipped: friend shelves as top-level Crate cells via the `%MusuThem` grapple.)
- **TUNER/CREWS are vestigial in the live Vyto path.** `CREW_MAINKEYS` + `Tuner_toggle` only ever worked
   through the now-retired Cyto scan (`Vytui` never imports `CREW_MAINKEYS`; `tuner.c.crews` is never
    populated; pressing the dial hides nothing). If "grouping/structure" work resumes, the Tuner needs
     re-homing into the Vyto pipeline (populate crews on the mirror scan + a cell-filter in Vytui).
- **%PREVIEW-MIDDLE** stays parked as before: deep multi-site encode change (`Ra_record_from` preview
   window + seq + `Ra_transcode` + card + resurrect), needs AUDIO verification (mid-track Opus decode) +
    a full re-record — do it with the human's ear, not blind.

TONIGHT'S PLAN (in flight): 3 sonnet readers mapping (a) the Sounditron drive/waits for a guts-rebuild
 into finer OBSERVABLE steps, (b) the Vyto glass hierarchy for "more hierarchy / queues coming in /
  re-top-level", (c) the Heist flow end-to-end. Live baseline running on **★claude 49dee91d** (my SOLO
   runner — NOT Righto 56fbce / Lefto 77d262, the human's tabs; sticky was wrongly pinned to Righto,
    cleared; ALWAYS `--runner=49dee91d`). Verification floor while unattended = LocalGen browserless
     compile (.g) + bundle-proof (.svelte); live greenness only on my own runner.

**2026-07-28 (late) — live-feedback round 2 (human running BigSoundland, rapid feedback). DONE:**
tone-blast killed (`Lies_audio_probe` played 440Hz to the speaker for 1.5s → now `osc→analyser→gain(0)→dest`);
 friend tracks no longer cut at 32s (`Radio_supply_go` `if (rec.c.from) return` — wire supplies it, never cap);
  `peer_live` now detects a real online Music friend (was checking a Lies lease → 12s timeout every run);
   radio AUTO-STARTS un-muted on any stock (`Sounditron_listen`, via the BootGate tap); Vyto commissions at
    step 1; my cross-Pier wake was firing on the wrong world (station vs radio) → fixed via `repli_mirror_w`;
     **UPTIME heartbeat cell** (`%Uptime` organ + `UptimeFace.svelte` + `glass_kinds`) ticks every second off
      its own timer (no world bump), amber for its first 10s so a reload is unmistakable.
**FRONTIER (needs the human's ear / their zone — NOT built blind):**
- **"still slow / doesn't keep working reliably"** — after the `peer_live` fix, remaining wall-clock is the
   FIXED waits (`muse_wait` 4s wander, `sound_wait` probe ~2.5s) + settles, and the PULSE reliability
    (`peer_live`/`heard_at` depend on `Swarm_pulse_all` flowing both ways — flaky presence = intermittent
     timeouts). Deeper than a ceiling tweak.
- **Gappage** — the want side is healthy (`Swarm.g:1467` pulls to `head+16` ≈32s ahead); the bottleneck is the
   friend's demand-transcode keeping up over the relay + the pump's **6s starve-grace** (`Radio.g` `starved_at > 6`).
    The cap-removal traded clean-32s-cut for full-length-with-gaps — tune by ear (shorter grace / re-cap when chronically behind).
- **%Preview jump to middle (30–70%)** — DESIGNED, contained to the ENCODE side (seq stays 0-based everywhere;
   only `Ra_stock_one` preview-encode + `Ra_transcode` continuation + the card + resurrect need a per-track
    deterministic `offset_seg` from the enid, mapped into 30–70%, grid-aligned). Re-cuts ALL stock → re-record.
     Not built blind (needs audio: does the mid-track Opus encode decode clean — it should, fresh encode from PCM).
- **Vyto spastic/sizing/occlusion/grey-border** — `Vytui.svelte` is the HUMAN's in-flight refactor (104 uncommitted
   lines, incl. an "IDLE GATE" that IS the spastic-movement fix). Left to them; colour + cell-structure flow via
    Matstyle + face components (Style subagent).


**2026-07-28 — CONTINUOUS MUSIC (Stream B) EXECUTED overnight (human's go: "play the trick · fold
 onto BigSoundland · soft searching cue" + "get on with it").  Compile-proven, NOT yet live-verified
  (two-Pier proof needs the human — see the recipe).**

*The real diagnosis (from Righto/Lefto Step:7 snaps the human pasted).* The bytes were NEVER the
 problem: two BigSoundland tabs are two JS contexts, so they cross the **relay** (Socket_real), not
  the in-process loopback — and the snaps PROVE the cross-Pier preview pull works over it (each side
   holds the other's `%Preview` chunks, `stage:previewed`). The bug was `Radio:off` on both: the
    previews landed and just sat there — nothing pressed play, nothing dialed the friend's previewed
     record. NOT slowness, NOT the carrier. (This is also the "one gate" of `Frontier.md §1` more
      crossed than that doc admits — two distinct Piers exchanged real chunks over the relay.)

*What landed (all four `.g`/`.svelte` compile clean; gen written; InvitePanel bundle-proof HTTP 200):*
- **The missing wake (`Repli.g` + `Radio.g`).** The local dig nudges a digging radio the instant a
   track stands (`Radio_nudge`, `Stoker_look`) — but a friend's chunk crossing the wire had NO such
    wake, so the playhead waited out its 3s dig poll (the "why isn't it audible in a second" gap).
     `Repli_attach_page` now fires a generic `w.c.repli_on_land` on a real landing (breach = no fire);
      `Radio_ensure` subscribes it to `Radio_nudge`. Cross-Pier landing now wakes the radio at once.
- **Sounditron plays the trick (`Sounditron.g`).** Beat 6 now presses the radio **muted + detached**
   (`Radio_go opts.mute`; detached because `Sound_gat`'s resume pends on a gestureless tab — the
    step-6 deadlock law), aimed at a friend's previewed record (`Radio_dial_pool` → `tune_rec`, played
     first). The decode+schedule pipeline runs gesture-free (AudioDecoder needs no resume), so
      `radio.c.seq` advances — the snap-provable trick — even where muted output reaches no speaker.
       New witness lines: `the music played — record chunks decoded onto the live timeline` (contract)
        and `music from a friend played — their track streamed off their shelf over Repli`
         (opportunistic — latches only with a peer online). The **4th Heist Need** ("the pull itself"),
          never-checked before, now goes `met` when a friend record holds its first chunk
           (`Sounditron_pulled`). A `slow to sound` %log fires if time-to-first-chunk > 2s.
- **The soft searching cue (`Sound.g`).** New `Sound_searching` (a low ~110Hz breathing hum at ~0.06,
   the human's "not dead-silent" pick) + a DISTINCT `searching` radiostock kind, so the entropy-measure
    Books keep synth's wide histogram untouched. NOTE the app path never actually installs synth
     (only Musuation test Books + Mixer do) — a no-share tab digs SILENT today, so the cue is a
      primitive **still to be wired into the dial** (see owed, below).
- **Invite leaves the URL when spent OR complete (`InvitePanel.svelte`).** `strip_iz` now drops `?Iz`
   on a refused redeem and on a dead/unparseable landed token too — not only the pinned-success path
    that used to gate it (a reload no longer re-presents a dead blob).

**→ THE HUMAN'S NEXT MOVES (live-runner gestures I can't do solo):**
1. **Hard-reload Righto + Lefto** (they hold pre-change gen; the NEW methods `Sounditron_listen`/
    `_pulled` need a reload, not HMR). Run Sounditron on both. Expect: `Radio` flips to `playing`,
     `radio.sc.title` shows a friend's track, seq advances, the 4th Heist Need goes `met`. THAT is the
      trick, witnessed.
2. **Fixtures: the committed (solo) ones stay GREEN — no re-record needed.** `Sounditron_listen`
    early-returns unless a friend's previewed track is actually ready (`Radio_dial_pool`), so a
     solo/CI run is byte-identical to before (radio stays off, no new rows, the new %sworn don't
      fire). Only the TWO-PIER environment (Righto/Lefto, each other's peer) presses play → adds
       `Radio:playing`+title+seq — but that environment already reds the solo shelf's fixtures by
        construction (the Book's stated regime), so nothing regressed. Record the two-Pier state as a
         fixture only if you WANT it as a gate ([[force-clean-rerecord]]); otherwise leave it.
3. **Declare the 3 new %sworn** via the declare door (`runner_ask declare`) so they're contract, not
    undeclared caveats ([[sworn-assertioning-rulings]]).
4. **Owed — wire the searching cue into the dial** (Stream B tail): a no-share/ digging radio should
    play `Sound_searching` (mint a searching-record, or a dial fallback) instead of dead silence,
     superseded by real records on landing. Touches the radio dial/caster → the Vyto-adjacent zone +
      needs AUDIBLE verification (a gesture), so left for the human to steer.

**2026-07-27 — the human's fresh asks: FASTER STEPS + CONTINUOUS MUSIC (write-down + parallel
 plan; do NOT execute — human still reading).**  *(Stream B now executed above, 2026-07-28; Stream A
  step-speed + Stream C standalone still owed.)*

**A. The steps take too long.** Likely the Story step-*driver*, not the organs: `story_drive`'s
 `poll_step` re-arms at 50ms with no visibility gate (~20 belief passes/sec while `run.c.driving`),
  and event-paced beats sit on their wait ceilings (`stoker_wait` 30s, `peer_wait` 12s) until real
   state changes — a never-settling `expecting()`/ttlilt holds the run open. Levers, cheapest
    first: (1) shorten/parallelise wait ceilings where a beat waits on something already knowable;
     (2) hunt a never-settling expecting (a live ttlilt in `got_snap` = timed out); (3) a
      `document.hidden` gate on `poll_step` — **CORE SEAM, needs the human's blessing**
       ([[fight-back-on-core-changes]]). Connects to C below — the driver overhead is exactly what
        Story adds.

**B. It's a 1s bleep, not continuous music.** Two independent causes to run down:
- **Source ladder.** The production dig tries bases `['music','',testsounds']` (`Radio.g:844`) —
   root IS searched, `testsounds/` is only the last-resort fallback. **But Sounditron's own ladder
    is `['testsounds','music','']` (`Sounditron.g:371`) — it tries `testsounds` FIRST**, which is
     why the resident probe favours the 8-track fixture. Open FSA at `/music` (files at the root)
      and it still falls through to `''` root when no `testsounds/`/`music/` subdir is present — but
       reordering Sounditron's ladder (or dropping `testsounds` for the resident probe) is the
        direct lever.
- **Synth vs real-file.** Separately, `Sound.g`'s `Sound_synth` is a generated PCM source ("synth
   today, real directory-walked collection tomorrow" — `Sound.g:9/54/61`); a generated ~1s chord is
    itself a candidate for the "bleep." **Confirm which path feeds the live player** — the Ra.g
     real-file stream (`Crate_nav_meander`→`Ra_stock`→`rastock→racast→raterm`) or `Sound_synth`.
      Continuous real music = the live player on the real-file dig + the gapless pump ([LIVE]) not
       bleeping.

**C. Run `w:Sounditron` without Story around it** (the human's question). Sounditron today is a
 Book — its beats are driven by the Story step-runner; it does not need a fixed step *count*, but
  the world only progresses because the driver runs belief passes. Booting the world standalone is
   the **Layer-0 destination in `Radiobuddies_handover §1`** ("the app runs with `Ghost/Story/*`
    deleted") — a real build (decouple the organs from the beat-driver so they self-tick), not a
     "hit the world" switch. Doing it also removes the (A) overhead — A and C are the same lever
      from two ends.

**Parallelisation (disjoint code → safe to run concurrently, on the human's go):**
- **Stream A — step-speed diagnosis** (read-only first): trace where the wall-clock goes (wait
   ceilings vs `poll_step` vs a stuck expecting). No core edit without blessing.
- **Stream B — continuous music**: the Sounditron source ladder + synth-vs-real-file source-of-truth
   + gapless confirm. Needs the human to confirm which path feeds the live player.
- **Stream C — the cross-machine crossing** (`Frontier.md §1`): needs the human for R1 (seal two
   tabs).
A (perf/driver), B (audio source), C (transport) touch disjoint code — genuinely parallel. Gated on
 the human's go; not started.

---

**THE WEDGE IS DEAD — Sounditron is LIVE-GREEN ×3** (2026-07-18: uids 3d6cc6b2/0f8830d8/173ef364
 on runner 3c5238, 7/7 ok, gaps empty, descs riding the steps op, the latched set in snap 7).
  ROOT CAUSE (named by the human's console eyes — step 5 good, hang during 6, "doesn't seem to do
   any beliefs()", CPU 10%): `Lies_audio_probe`'s `await ac.resume()` **pends forever on a
    gestureless tab** (autoplay policy resolves it only on a user gesture; the flagged fleet never
     hits it), and beat 6 awaited the probe **inside the wrangle req's do — under the beliefs
      mutex** — so the whole Atime machine deadlocked: no beliefs, Storui dead, asks unanswered,
       no exception, no spin.  The remotewormhole-mutex-deadlock lesson, re-learned: **a beat fn
        must never await an unbounded promise; anything that can pend runs DETACHED inside an
         expecting() (the ttlilt holds the snap, the mutex stays free), stamps w.c, and the
          witness reads it in Atime.**  Fixes: `Sounditron_probe` (detached + 5s race) and a 1s
           race on the core probe's resume() so the `probe` ask op can't deadlock unflagged tabs
            either.  The earlier suspects (Cyto wave, req sweep, poll reads) were all falsified
             en route — the watcher's "died at n=4" was a lag artifact (state polls starve during
              held waits; the run was alive through 5).

**THE TWO-TAB SEAL (2026-07-18 midday) — diagnosed + fixed, retry owed.**  The failed seal's
 shape: the inviter's door HEARD the hello and denied it (`Swarm_hello`'s deny ladder:
  forged/not_ours/**unknown**/spent/expired/bad_grant/grant_mismatch — the pier_reject carries the
   why but nothing surfaced it); the "NO handler" console warns are only the DUPLICATE delivery on
    the second relay socket (`addr=runner` beside `addr=<prepub>` — that world has no swarm kinds).
     Root suspect CONFIRMED by construction: the `%Idzeug` nonce record was runtime-only, so
      mint-then-reload made the door deny its OWN invite as `unknown` — and the inviter tab's log
       shows a fresh boot.  FIXES LANDED (all live-gated — SwarmStaple 8/8 · SwarmWire 5/5 ·
        Sounditron 7/7): the invite ledger now survives reload (`Swarm_iz_stash`/`_rehydrate`,
         durable twin under `H.stashed.Swarm_izzes`, rehydrated at station standup, live-self only
          so Books never pollute); every deny logs `🚪 rebuff %<why>` loudly on both ends;
           InvitePanel shows recent rebuffs on the mint face and the join face names a
            `rejected_<why>` instead of "is the inviter tab still open?".
             **RETRY RECIPE: hard-reload BOTH BigSoundland tabs (they hold pre-fix bundles), mint
              a FRESH QR on one, open it in the other, click join — expect the seal; any deny now
               names itself on both faces.**

The queue now: (1) the retry recipe above → then a Sounditron run on a BigSoundland tab should
 latch `granted` + count the contact in the census (the runner-side census is honestly 0 — that
  identity has no contacts); (2) EYEBALL the glass forming from the Sounditron guts on
   /BigSoundland (pixels are watch-verified); (3) the Yore cut (§4); (4) descs → the fleet at
    leisure (§2); (5) re-add the finished-wait-req sweep with a proven-safe seam (§6); (6) glance
     SwarmWire's caveat:1 (2026-07-18 run — history says caveat:0; entropy-forgiven, roster clean).

## 1. What stood up tonight (all in the working tree, uncommitted)

- **`Ghost/Story/Sounditron.g`** + `wormhole/Story/Sounditron/toc.snap` + CREDULER_GHOSTS entry +
   Credence row (`brand_new`, `unusual:real-environment` — deliberate-run-only, NEVER run-all).
    Beats are event-paced (the human: "ttlilt until Story can capture meaningful state changes"):
     a beat arms `expecting()` (the ttlilt holds the snap) and the eternal witness req notices
      truths on whatever pass they land.  The guts are referring particles under w — `%Machine`,
       `%Relay`, `%Possibility` (per known address), `%Census`, `%Audio`, `%Session`.
- **The contract split that keeps the diagnostic honest:** DECLARED %Assertions = "the machine
   works" (machine-stood, relay-answers, possibilities-surveyed, report-stands — must latch
    ANYWHERE); UNDECLARED %sworn (granted, peer, sound, listening) latch when the world provides
     — they still WANT declaring (the explorer shows them amber ◇), they're just not yet in the
      contract.  A user with no friends online is a REPORTED session ("Pier not online", a %log),
       never a failed run.
- **`Opt/wild` is DEAD (2026-07-19 — the human: "I wanted both").**  Sounditron now records AND
   fixture-checks like any Book; the three Story.svelte wild gates (exp-preload skip, disk-verify
    skip, ok-always verdict) are deleted and `wild` left the toc Opt block.  What made it
     checkable was determinism at two seams + one cap, found by diffing consecutive live runs:
     - `stoker_wait` expecting in beat 2 holds the snap until the Stoker SETTLES (parked with
        census stamped) — a mid-provisioning frame pins a racing stock shelf no re-run matches
         (structural drift, beyond EntropyArrest, which forgives values never rows);
     - the meander's picks are SORTED and bounded 12 (was 6) — a small share (the runner's
        8-track testsounds) sweeps whole and mints in stable order; a big share stays a real
         bounded probe whose fixtures will honestly wobble;
     - `Entcase:Session_alive` (toc EntropyArrest, `re:Session.alive={INT},tol:any`) forgives
        the seconds-alive counter — the caveat:1 on every green run.
    Live: all 7 fixtures re-recorded, green 7/7 caveat:1 ×2 consecutive, contract 4/4.  A
     DIFFERENT environment (another machine's music, other peers) will still red the fixtures —
      that red is that environment's tell, and the assertion contract stays the portable verdict.
- **`%desc` on steps — LIVE-PROVEN.**  A Book describes its own step: `i %desc:'a few words'`
   (NO COMMAS — em-dash) at the beat; `story_harvest_desc` harvests it The-side at
    snap_step_after_wave BEFORE the encode (never snap bytes → retrofits never churn fixtures);
     the toc line becomes `step=N,dige:…,desc:…` (round-trips both codecs, zero codec work);
      Storui shows it (pip title + panel header `.sr-pdesc`) and the `steps` op carries it.
       PROOF: the live runs wrote `desc:the machine stands` / `desc:the relay answers` into
        `wormhole/Story/Sounditron/toc.snap` before the wedge.  WART: step ONE's line re-encodes
         as bare `step` ({step:1} numeric → presence form) — decodes fine, reads odd.
- **The world-side glass commission** (`Sounditron_glass`, beat 2): the WORLD commissions Cyto —
   `new TheC({sc:{Scannable:this, Styles, client_w:w, useVoroCyto:1}})` →
    `i_elvisto('Cyto/Cyto','Cyto_commission')` — no toc useCyto, no wave/animation waits, snaps
     stay pure H.  Cyto watch_c's the Scannable (ANY version bump rescans — zero step-time
      coupling, already built) and useVoroCyto arms the crusher Cyto-side.  This is the
       "commissioned by w:Sounditron itself" cut, and it's the DEMO idiom generalised, not a new
        engine.
- **/BigSoundland default Book → Sounditron** (`?B=VoroScape` keeps the music demo).  The guts
   ARE the graph the crusher folds — the "dump its guts into Voro" start.
- **`Cred_report_wild`** (Auto.svelte, called from Cred_spool): a Book with `The/Opt/report`
   POSTs `/log?stream=Startup-<user8>` in Tyranny's batch format (newline-joined JSON): ALWAYS
    one outcome line (ok, ok_pct, gaps, the latched %seen set — successes are the census
     denominator for "how many webrtc connections ever work"), plus per-step rows (+desc,
      +untried, +error) when red.  Fire-and-forget; dev servers without /log just warn.  The old
       server side: Tyranny.svelte:15 — "replicate the reverse proxy handle_path for /log, see
        git:leproxy 15d26579" — the Mojolicious/perl logger expects exactly these batches.

## 2. The Story annotations arc (steps, checks — "the fundamental concepts of its soul")

`%desc` is the first annotation: authored WHERE the step is meaningfully created (the beat), no
 commas, harvested to the toc line, shown everywhere steps show.  Retrofit is free (never in
  fixture bytes) — sweep the fleet Book by Book when touched, not as a batch.  The next
   annotations ride the same harvest seam (story_harvest_desc): whatever else a beat wants to
    say ABOUT its step rather than IN its world.

## 3. The peer-possibilities layer (does not exist — the census is its first draft)

The human, 2026-07-17: *"haven't done any sort of having the possibilities of peers and which one
 to connect to."*  Sounditron's beat 4 census (`%Possibility,<pub8>,via:pier|peering|roster|client`)
  is deliberately that layer's v1: enumerate every address we know a way toward (station-world
   Peering/Pier rows, the editor-channel %Runner roster, the courting client), so choosing-which
    has a surface to grow on.  When the real chooser arrives it should REPLACE this census's
     sources with its own roster, keeping the %Possibility face.

## 4. Yore — travel the graph back in time (the IN-RUN half is LIVE; post-run designed below)

**DISCOVERY (2026-07-18): the in-run series shipped with the rail flip.**  The Story commission
 carries `supports_seek: true`, so CytoStep archives EVERY step's graph mirror, and Storui's pips
  fire `Cyto_seek {open_at}` (Storui.svelte:882) — **arrowing/clicking the step pips scrubs the
   stained glass back through the run**, on the runner and on BigSoundland's diagnostic Storui
    alike.  Nothing was built for this; the toc rail turned it on.  What remains below is the
     POST-RUN moment series only.

The discovery: **time travel is already half-built.**  Cyto archives a full graph mirror per step
 (`w.i({CytoStep:1, step_n, C:topC})`, Cyto.svelte ~240) and `e_Cyto_seek {open_at}` re-waves any
  archived step with adjacency/backwards morphs — Storui's pips already drive it for Story runs
   (`supports_seek` on the commission).  What's missing for a CONTINUOUS w-commissioned client:
- **The cut:** when `supports_seek` and `incoming_step_n` is undefined (a version-watch rescan,
   not a Story step), auto-number the archive from a per-w counter instead of keeping latest-only.
    One guarded line at the archive site; NEVER stamp step_n undefined (the undef brand).
- **The cadence:** a moment is a MEANINGFUL state change, not a clock tick — bump the counter when
   a %seen latches, the census changes, a peer connects/drops.  The witness already sees all of
    these; it bumps `w.c.yore_n` and pokes the scan.
- **Post-run life:** after step 7 the drive stops but the world lives on; the heartbeat for
   onward moments is the %Upkeep/%Errand layer (ave.{Upkeep}), not Story.
- **The UI:** nothing new — the pips/e_Cyto_seek and Cytui's ←/→ walk already travel; they just
   need the archive series to exist.
   Retention: cap the ring (say 60 moments) and drop-oldest — the report carries the summary.

## 4b. The two-instance morning (2026-07-18, the human's rulings)

- **Two BigSoundland instances invite each other** (?I=new mints the second — e.g.
   `?I=56fbce4437d7265c`); the Invite to Music is RECIPROCAL (Swarm_seal stores BOTH grants).
    Sounditron now OBSERVES the seal: `Sounditron_grants` reads the durable `%Pier,pub` contacts
     under my %Peering + their %Grant pairs — **observe, never re-set-up** (the %Grant lives in
      storage beside anything a run could mint; a wild diagnostic reads it as-is).  Contacts are
       a census source (`via:contact`, `granted:1` on the row) and `granted — a sealed friendship
        holds Music grants in storage` latches unrostered.  Fixed en route: the station census
         row read `p.sc.Pier` (the presence 1) — it's `p.sc.pub`.
- **DEFERRED by the human, explicitly:** (a) properly modelling two instances of Story:Sounditron
   talking to each other — each instance runs its OWN Sounditron observing its own end, no
    cross-instance Story coordination; (b) any deep modelling of browsing files.  The nearest
     destination is only what lib/ghost/Radios|Pirate.svelte once did: browse either end, push
      either end, both ways.
- **THE NO-ENUMERATION LAW (critical, verified):** never scan the whole music share (200k tracks)
   into memory.  It holds by construction today — `Crate_walk` expands ONE level lazily and
    `meander` wanders it descend-on-demand; Stemdex warms from its own Dexie cache + loaded Waft
     docs only; `ive_got` shares COUNTS never Records.  Future browse = the meander, random
      wander down into the share — never an index-it-all pass.

## 4c. The seal LANDED (2026-07-18 afternoon) + the storm after it

The two-tab seal WORKS ("that works!" — the human).  Two aftermath fixes, both landed:
- **The ive_got storm** (seq 300+ both ways): InvitePanel's gossip effect derives `friends` from
   live reads that can catch MID-ATIME transacting state (the reactivity_docs trap) — the list
    flickers 1→0→1, and `gossiped = n` on shrink reset the high-water, so EVERY flicker re-boasted.
     Fix: the high-water is MONOTONIC (never lowered).  A ghost-side same-census guard was tried
      and deliberately REVERTED — it changes Book semantics (a second same-census seal legitimately
       re-boasts); SwarmGot 9/9 live confirms the protocol untouched.  LAW: a UI effect reading
        live C state must treat shrink as possible flicker, never as change.
- **The QR face** ("too hard to get out of"): the stopPropagation on the QR block left only a
   sliver of escapable margin.  Now: click ANYWHERE closes + a fat ✕ + Escape.  (CONFESSION: the
    Escape's `<svelte:window>` first shipped INSIDE the `{#if}` — svelte_meta_invalid_placement —
     breaking InvitePanel/BigSoundland for several soak cycles; every gate ran green because
      runner tabs never mount panels.  Fixed top-level + bundle-fetch-proven; the discipline is
       now a memory: bundle-fetch every edited .svelte.)
- The residual `NO handler for frame type` warns are the DUP-SOCKET delivery (addr=runner beside
   addr=prepub — the real door answers on the other socket).  Understood, documented; the proper
    quiet is Robustness_plan Organ 2 (dont-ack escalation), not tonight's knife.
- The human runs both BigSoundland tabs on a 600s auto-refresh — a rolling soak rig: each cycle
   takes the current working tree, re-runs Sounditron, re-loads the stash (grants + izzes).

## 4d. The glass filled (2026-07-18 afternoon — "the model IS the UI")

The human's cut, verbatim: *"put other UI nuggets in Voro, keep changing what's in its model as
 a way to avoid figuring out how to divide the screen... just put anything I'd be interested in
  there, then I'll tune it to a user experience when I'm back... fully make stuff up if you have
   to... start showing what the heist needs to complete."*  What now stands in the Sounditron
    world (all live-gated 7/7 ×3, and SEEN in the glass via `runner_shot --svg`):
- **%Found** — the MEANDER's finds: `Crate_nav_meander` (new, Crate.g — ONE directory listed per
   hop, random descent, GIVE_UP-bounded, prandle-seeded; the no-enumeration law by construction)
    wanders known musical grounds first (`testsounds`, `music`, then the root) and up to six real
     track names stand as panes — "The Sines - Deep A,dir:testsounds" confirmed in the SVG.
      Re-rolls every run — on the 600s rig the glass changes each cycle.
- **%Friend** — the sealed contacts: friendly name as the mainkey value, pub8/music-grant/records
   boast as facets.  (The runner identity has none; the human's tabs will show each other.)
- ~~**%Caper,posed:1**~~ — **DELETED 2026-08-09** (the owner: *"is that debug crap?"* → *"it's time
   to delete the fake"*).  It was "the one they played last night" with four %Need children, and its
    retirement guard could never fire on a player tab, so the fiction was permanent UI.  The four
     Needs WERE honest and were promoted, not dropped: they are now registered watches on
      `w:Supervisor` (`Sounditron_supervise`, four `Sounditron_probe_*` reads), and the glass carries
       **%Supervisor** — the one sanity cell — in its place.  See `Supervisor_todo.md` §0.
- **%Tally** (records reachable · shelves counted), **%Machine,friendly**, richer %Session.
- The %seen choir crushes behind a husk (MANY+homogeneous — the grammar working as designed).
   The glass rail is toc `useCyto+dontSnapCyto+useVoroCyto` (pure-H snaps); `Sounditron_glass`
    stands DOWN when that rail commissioned (two commissions fight over wave flags) and remains
     for tocless contexts.
- **Seeing it without a browser:** `node scripts/runner_shot.mjs <out.png> --runner=…` (NOTE: no
   'shot' op word — the first bare arg IS the filename) for the canvas; `--svg` for the voronoi
    glass with greppable pane text.  The canvas PNG alone shows bare Cyto nodes — the glass lives
     in the SVG overlay.

## 4e. FACES — a live UI component laid out by the glass (2026-07-18, the stuff rail generalised)

The human: "we want to send a UI component into Voro|Cyto for laying out, much like it does with
 Stuffings."  Built as the smallest generalisation of the proven stuff rail — same mount, same
  cell seeding, same `paint_final` mold, a REGISTERED component instead of a Stuffing:
- A particle wearing **`sc.face:'<Kind>'`** (a display request, never identity — the mainkey stays
   the type) styles as `overlay_kind:'face'` + `overlay_face` (`cyto_nstyle`, checked BEFORE the
    stuff skins so the crusher's blanket `c.stuffy` can't shadow it; descent suppressed like a
     stuffed chunk).  `source_n` ferries on the wave for kind 'face' exactly as for 'stuff'.
- **`glass_kinds.ts`** = the registry (the FUNK_KINDS pattern worn by the glass): face kind →
   component.  `Cytui.create_face_overlay` mounts it with props `{ n, H }` (react off
    `void H?.version` — the InvitePanel idiom) and registers in `stuff_mounts`, which IS what
     earns a voronoi cell.  CSS: `.face-overlay` stays `pointer-events:none` (the glass must pan);
      only the component's BUTTONS re-arm `pointer-events:auto`.
- First face: **`RadioFace`** (`O/ui/RadioFace.svelte`) on the `%Radio` particle
   `Sounditron_glass` now stands in EVERY run's world (mint sits ABOVE the per-tab `glass_done`
    latch — the first run on the stale tab proved the latch was eating the mint).  ▶/⏭ call
     `Radio_toggle`/`Radio_skip` straight on H.  The radio itself = `Ghost/M/Radio.g`
      (Radio_todo §0).
- **Caveat for shots:** a face is live DOM — neither the canvas PNG nor the SVG glass carries its
   pixels; the PROOF a face mounted is its CELL standing in the `--svg` tessellation (a cell only
    seeds off a successful mount).
- **IMPOSED faces (2026-07-18 late):** a face can also arrive BY MAINKEY — `FACE_MAINKEYS` in
   **`glass_faces.ts`** (the component-free half; Cyto imports THIS, never glass_kinds.ts, so the
    headless spine never drags .svelte components).  Imposition is viewer-side: no sc changes, no
     snap changes, sealed Books stay Voro-blind.  First imposed: `%Caper` → HeistFace (posed
      needs | soft wish→Leads→take).  Resolution = `cyto_face_kind(n)` (worn sc.face wins).
- **CREWS + the %Tuner (2026-07-18 late — the make-space dial):** every cell-holder tessellates
   under a CREW — `cyto_crew(n)`: explicit `sc.crew` || face kind || stuffed mainkey.  cyto_scan
    censuses crews into the %Tuner's `.c.crews` (silent write) and DROPS muted crews at classify
     (census BEFORE drop, so a hidden crew stays listed and un-hidable).  TunerFace = ▣/☐ rows →
      `Tuner_toggle` (Cyto.svelte) → `.c.mute` flip + the unfold-idiom absolute rescan.  Mute +
       census ride `.c` ONLY — a Book's snap never churns on a viewer's taste.  The tuner is
        minted by the COMMISSIONER (opt-in — `Sounditron_glass` does; a bare Leaf* world keeps
         its fixtures), and it can never mute itself.  Faces so far: Radio (gold) · Stoker
          (green, crew:'Radio' — one toggle hides the whole listening pair) · Tuner (blue) ·
           Heist (crimson).

## 5. Speculation — thrown-on steps (designed earlier, unbuilt)

A `Speculation:<slug>` = a What-shaped bundle (the Mag/Grasp idiom) of NON-canonical steps + its
 own mini-roster, grafted onto a live run after|between canonical achievements.  This-side ONLY
  (never bake speculative steps into the canonical toc — the clobber family); evidence rides the
   run-record; graduation to canon is a human Accept.  The wait primitive needs nothing new: a
    req probing `oa({seen:…})` stays unfinished until the latch, a ttlilt carries the deadline
     (a live ttlilt in the snap = timed out).  Build after the wedge falls and the Book breathes.

## 6. Standing cautions

- The finished `relay_wait`/`peer_wait` reqs are LEFT STANDING in the snap for now — the sweep
   that dropped them was falsified as the wedge cause but was removed during bisection; re-add
    only with a live-proven safe seam (suspect the Run-republished ttlilt row must clear with it).
- `Lies_audio_probe` returns `realtime`/`heard` (NOT real_time) — Sounditron reads it right now;
   don't regress.
- Sounditron must NEVER join run-all (unusual:real-environment) — it probes the machine it's on,
   wedges tabs while the BOMB stands, and holds 12s+ waits by design.

## 7. Advisory — the %sworn/%Assertioning upgrade LANDED (Seen_split build, 2026-07-18)

**Update, same day: it's live and Sounditron is already converted** — green ×2 on the real runner,
 sabotage-probe red ×1, runner released.  The witness now calls **`this.story_swear(w, 'sentence',
  subjectC?)`** (sync, idempotent per run, no more `oa` guards; subject → microsnap at go-off);
   bare `i %sworn:'…'` also works.  The contract sits under the toc step lines; evidence lands on
    the `ave/%Assertioning,Story:Sounditron` shelf, so got_snaps carry NO assertion bytes now.
     `node scripts/runner_ask.mjs assertions` shows contract-vs-evidence + the microsnaps.  If you
      re-touch the witness: swear in Atime only (a detached leg stamps `w.c`, the witness swears
       next pass), keep sentences comma-free, and never hand a %Grant (sealed key material) as a
        subject.  The paragraph below is the original advisory, kept for the why.

### (original advisory, superseded)

To the agent on Radios + Sounditron: the assertion layer your Book leans on is being rebuilt under
 you — nothing to do yet, just know the shape so nothing surprises.  `%seen` becomes **`%sworn`**
  (greppable at last), and your beat idiom barely moves: `i %sworn:'sentence'` as before, plus an
   OPTIONAL subject param when the witness wants the latch to carry a **microsnap** of the particle
    it read the truth from (frozen under the mutex — "the relay answers" will carry the %Relay it
     saw).  The declared side moves INTO the step lines: `The/Steps/step=N/%Assertion:slug,
      sentence:…` — the hosting step is the by-when, `by_n` dies.  The latched side leaves the
       world snap entirely: a harvest seam (your `%desc` rails) moves each latch to a per-run shelf
        `ave/%Assertioning,Story:<book>` stamped `n:` — so your guts stay pure %Machine/%Relay/
         %Census and fixtures never churn on assertions again.  Your unrostered achievements stay
          opportunistic ("unclaimed evidence", harvestable into the contract only on the human's
           Accept); the wild regime and the /log report are untouched (the report still carries the
            sworn census).  Leniency becomes structural: pending until its step, overdue after, red
             only at run end.  A `runner_ask assertions` op (contract-vs-evidence per run) is
              coming for CLI eyes.  NEVER say "roster" for any of this — that word belongs to the
               Cluster runner roster.  Coordinate via `spec/Seen_split_todo.md §0` (the rulings
                block); details there as they land.
