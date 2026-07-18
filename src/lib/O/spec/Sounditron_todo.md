# Sounditron_todo.md — the resident diagnostic Book, the wild regime, and the time-travel seed

The one living doc for the Sounditron thread: /BigSoundland's resident Book that probes the REAL
 environment (machine → relay → the possibilities of peers → a peer → sound → the report), makes a
  user a reporting test-probe (POST /log), and grows the glass + graph-time-travel around itself.
   Born overnight 2026-07-18 from the human's brief ("yeah, Sounditron! … take over everything
    overnight"); the Radio thread's own doc stays `Radio_spec.md`/`Radio_todo.md`.

## 0. What to get on with next

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
- **%Heist,posed:1** — "the one they played last night" with four %Need children (grant / online /
   boast / the Repli pull), `met:1` kept honest by the witness each pass.  The SHAPE of the real
    heist face, tunable on sight before the machinery arrives here.
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
     snap changes, sealed Books stay Voro-blind.  First imposed: `%Heist` → HeistFace (posed
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
