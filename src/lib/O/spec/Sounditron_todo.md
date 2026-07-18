# Sounditron_todo.md — the resident diagnostic Book, the wild regime, and the time-travel seed

The one living doc for the Sounditron thread: /BigSoundland's resident Book that probes the REAL
 environment (machine → relay → the possibilities of peers → a peer → sound → the report), makes a
  user a reporting test-probe (POST /log), and grows the glass + graph-time-travel around itself.
   Born overnight 2026-07-18 from the human's brief ("yeah, Sounditron! … take over everything
    overnight"); the Radio thread's own doc stays `Radio_spec.md`/`Radio_todo.md`.

## 0. What to get on with next

**THE BOMB — the live runner wedge (the one thing blocking the whole gate).**  Sounditron runs
 GREEN headless (CredRunner 7/7, twice) but on a LIVE :9091 runner the tab wedges at the
  **snap4→beat5 corridor**: `done:4` stamps (snap_step(4) entered), then the tab stops serving
   relay asks entirely (state/steps/ping all dead; court refused) and the toc never receives descs
    4-7.  Reproduced **3/3** on three different freshly-reloaded runners.  FALSIFIED already —
     don't re-chase these: (a) the Cyto wave (repro'd with useCyto OFF), (b) the finished-req
      sweep (repro'd with the sweep removed), (c) non-pure reads in the poll (Lies_engagement is a
       pure read).  Headless passes the SAME beats including the full 12s peer expecting, so the
        difference is live-tab-only (real relay channel, real station world, the CLI's own
         state-poll asks, the styles-watch toc write over the wh queue are the remaining
          suspects).  **Next move: open a runner tab WITH THE CONSOLE, `run Sounditron`, watch
           snap 4 land and beat 5 enter — the exception or loop will name itself.**  All three
            runner tabs (49dee91d ★claude / 20e3476 / 3c5238) are wedged and need HUMAN
             HARD-RELOADS before any live work.

After the wedge falls, the queue is: (1) re-gate Sounditron live ×2 (machine/relay/survey/report
 assertions should latch — the runner has an identity; peer probably latches off the CLI's own
  engagement lease); (2) eyeball /BigSoundland — the glass should form from the Sounditron guts
   with NO toc useCyto (the world-side commission below); (3) the Yore cut (§4); (4) descs → the
    rest of the fleet at leisure (Story annotations are live-proven — see §2).

## 1. What stood up tonight (all in the working tree, uncommitted)

- **`Ghost/Story/Sounditron.g`** + `wormhole/Story/Sounditron/toc.snap` + CREDULER_GHOSTS entry +
   Credence row (`brand_new`, `unusual:real-environment` — deliberate-run-only, NEVER run-all).
    Beats are event-paced (the human: "ttlilt until Story can capture meaningful state changes"):
     a beat arms `expecting()` (the ttlilt holds the snap) and the eternal witness req notices
      truths on whatever pass they land.  The guts are referring particles under w — `%Machine`,
       `%Relay`, `%Possibility` (per known address), `%Census`, `%Audio`, `%Session`.
- **The roster split that makes a wild Book honest:** ROSTERED %seen = "the machine works"
   (machine-stood, relay-answers, possibilities-surveyed, report-stands — must latch ANYWHERE);
    UNROSTERED %seen = achievements (granted, peer, sound, listening) that latch when the world
     provides.  A user with no friends online is a REPORTED session ("Pier not online", a %log),
      never a failed run.
- **`Opt/wild`** (Story.svelte, snap_step_after_wave): the environment IS the data, so the
   fixture game is off — no dige compare, no exp preload, no disk verify; steps snap+record
    (got_snap/dige land for the run-record), ok=true, and the RUN's verdict is the assertion
     roster + the report.  toc step lines carry `dige:wild` purely as the drive count.
      Fleet untouched: SwarmStaple ran green 8/8 live with all of this in place.
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

## 4. Yore — travel the graph back in time (design; the build is one small cut + a cadence)

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
