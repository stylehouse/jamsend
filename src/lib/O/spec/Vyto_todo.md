# Vyto — the working doc

The new glass.  Spec: `Vyto_spec.md` (unpreened — three rounds 2026-07-19).  Machine-level
 elaborations: `vyto_workingouts/` — shapes · pelt · calm · spool · commission · client,
  each checked against the LIVE code (not against the spec's hopes), most ending in open
   questions only the human can rule on.  This doc is the one todo; the workingouts are
    its appendices.  **`client.md` is the front door for anyone integrating as a Vyto
     client** — point a fresh agent there first.

## 0. What to get on with next

The arc: **wear the words in ✓ → give the glass eyes (Scan) ✓ → give it a memory (Spool) ✓
 → give it a body (the first cell) ✓ → hand it the abdomen (the Radio world as first
  tenant)**.  Milestone 3 landed 2026-07-20, same sitting as the rulings: the model solves
   a real power cut into targets, Vytui springs cells toward them and strikes settle
    itself, and VytoCell recorded GREEN ×2 beside a green VytoStaple regression.  Next
     moves:

- **First tenant — LIVE, in the other agent's hands (2026-07-20)**: the human's Radio
   agent is actively integrating Radio as a Vyto client (the Voro+Cyto → Vyto display
    move).  This side SUPPORTS, never edits display-side: keep `vyto_workingouts/
     client.md` current (their front door), the teaching Books green (VytoMitosis ·
      VytoRadio), and take model gaps they hit as requests against Vyto.g rather than
       letting the model fork.  Two runner tabs on the fleet — ours is the ★claude one;
        pin `--runner=` always.
- **Owed engineering — LANDED 2026-07-20** (the three units, all live-gated GREEN, see
   "what stands"): watch_c era-guarded multi-handler + teardown-on-decommission (Unit 1),
    spool freeze-on-run-fail (Unit 2), the step→yore_n shim + whichever-glass seek dispatch
     for Storui (Unit 3).  Awaiting the human's commit + confirmation of the three flagged
      decisions (below).
- **Seeing it**: nothing resident commissions Vyto yet, so the first cells are seen by
   running VytoCell on a visible runner tab — the parked-run gate lifts when the run
    stops driving and the springs animate the standing world.

- **The migration model — per-Book, from WITHIN the app (the human, 2026-07-21).** The `?VY=1`
   page-global boot flag (built 2026-07-20) is the WRONG shape — retiring it. The intent, never
    written down before now (which is exactly why it built wrong): move Cyto→Vyto **one Book at a
     time**, as a shift in *provenance*, not a component swap.
  - **Cyto was an observer**: Story, running a Book, casually attaches a Cyto view that scans the
     Book's tree from outside (`Sounditron_glass` → `Cyto/Cyto e_Cyto_commission` with
      `Scannable: <the Book/world>`). Cyto's home is Story; it *watches* a Book.
  - **Vyto is wired from WITHIN the application**: the app commissions its own glass as a
     first-class part of itself, not a Story-imposed watcher. So "per-Book, one at a time" =
      convert each app/Book to commission Vyto from within itself, retiring the Story-observer
       Cyto as each crosses. The Book's own commission IS the per-Book declaration — no global
        flag, no registry.
  - **Two gates before Sounditron flips for real** (why it was flagged, not committed):
    (1) **retire Voro too** — Voro is (suspected — verify) a viewer-imposed overlay riding ATOP
     the base regardless of Cyto|Vyto, which is why `?VY=1` looked identical to Voro; the
      migration must drop the overlay, not just swap the base.  (2) **parity** — Vyto v1 is plain
       cells (no faces, no Gang/crew, no sub-cell world), so a direct swap regresses Sounditron's
        face-heavy UI. Parity includes a **timeline UI** (the human's ask: step around in time,
         see the last few places we were, like an ongoing Story) — its data already exists in the
          Run's step/got_snap history that Storui's timeline reads; point Vyto's timeline at that
           same source.
  - **Plan (2026-07-21):** fully move Sounditron to Vyto (commission Vyto from within Sounditron;
     drop the Cyto+Voro+faces path + the `boot_param('VY')` flag) — **AFTER the ttlilt fixup**
      (Hovercraft.svelte:548 retract-on-drop, task #53 stage 1).

## What stands (built 2026-07-19, all live-proven to compile)

- `Ghost/V/Vyto.g` — the skeleton: `Vyto()` worker + `Vyto_plan`, `Vyto_board` (10 organ
   rows with reads/decides/writes as separate sc keys + 7 bar words), `e_Vyto_commission`
    (v1 refusals loud — a `rebuff` row), `Vyto_grapples` (explicit list | degenerate
     Scannable default; recipe/Sunpit stubbed), `Vyto_watch` + `Vyto_stir_soon` (the REAL
      watch_c drive with Vyto's own trailing-edge latch — the House flush fires once per
       changed C, not per burst), `Vyto_stir` (station order in the workings), organ stubs,
        `Vyto_settle` (hand-strikeable), `Vyto_spool_capture` (two clocks; step_n never
         stamped undefined), `Vyto_spool_cull` (60 drop-oldest; o/bless exempt),
          `e_Vyto_seek`, `Vyto_omark`.  Compiled via the live editor; gen loads — a
           VoroMitosis green on the runner proved the spine eats it.
- `src/lib/O/Vytui.svelte` — the board + strip render (bar · organ panel · moment ticks);
   mounts off the UIs registry via `Vyto_plan`; bundle-proven.  No cells yet — on purpose.
- Registered: `CREDULER_GHOSTS` (LiesLies.svelte) + the Vis Waft overlay
   (`wormhole/Ghost/Vis/Visua/toc.snap` — What:the new glass).
- Spec corrected where the workingouts caught it wrong: enWaft → snap_H (×3) + a header
   pointer to the workingouts.

- Milestone 2a+2b (2026-07-20): `Vyto_scan` writes the detached mirror (`w.c.mirror`; find-
   or-create by `.c.tok` = mainkey + join keys with value channels excluded — a quantity
    change morphs its row in place instead of faking a leave-and-enter; a vanished source
     wears `departing:1` one grace stir then drops).  `snap_H` grew `Se_home`
      (Story.svelte:1255 — the one existing caller unchanged) and `Vyto_spool_capture`
       stamps `row.c.snap` from the commissioned Run (`req.c.Run`) on Vyto's OWN Se.
- `Ghost/V/Vytonation.g` — VytoStaple, the first Book (8 steps): seed gear → commission →
   watch fires between beats → mirror morph-in-place → two-stir departure grace → settle
    strikes a moment with a full payload.  GREEN ×2 on the live runner 2026-07-20 and on
     the Credence board.  **The board has been seen live.**
- Milestone 3 (2026-07-20, same sitting): `src/lib/O/vyto_geometry.ts` (pure power-cut
   primitives ported from Cytui — clip_halfplane · power_cells · shoelace moments), the
    model's `Vyto_express` (dose→env_area on `.c`) + `Vyto_solve` (root `cell` solver on a
     fixed 800×450 frame: deterministic entry seeds, K=2 Lloyd η=0.25, targets
      `row.c.T={x,y,r}` — everything solver-side rides `.c`, never row sc, which Scan
       sweeps), Calm's real body (pointer-hold pin+damp rows under detached `w.c.calm`,
        `Vyto_calm_held` returns k∈[0,1], release tail cubic ease-out then retire), and
         Vytui's viewport: SVG cells keyed by tok, calm §5 closed-form springs
          (ω = 6/grawave — ONE constant, seeded ??=0.4 at commission), walls re-derived
           per frame, settle struck by the renderer (ε=0.5 · drift 0.25 · 8 frames),
            document.hidden sync-paint, and the **parked-run gate**: while
             `w.c.Run.c.run.c.driving` the renderer jumps-to-target and never strikes
              settle, so driven Books stay deterministic.
- The teaching pair (2026-07-20 evening, gate closed same day): **VytoMitosis** (6 steps)
   + **VytoRadio** (5 steps), the main two Voro Books ported client-shaped into
    Vytonation.g with a commented **Vyto client kit** (plant · commission-in-place ·
     read-cells · rest-poll) — pedagogy for the Radio agent, GREEN ×2 each plus the
      VytoStaple/VytoCell regression green.  Mitosis: grow (lone newcomer nearest-to-mean
       then a batch spreading the rim) → extinction (departing escort then survivors
        re-seat) → fixed point.  Radio: dose drift re-sizes and re-seats across dwells;
         the hand pins one cell mid-drift (its seed byte-identical while a neighbour's
          target moved) then release eases free and retires.  Model refinement the pair
           forced AND verified: the perimeter entry-spread fires for ANY simultaneous
            batch>1 (not just a cold start) — a mid-run grow batch piled otherwise.
             The client-integration front door is `vyto_workingouts/client.md`.
- VytoCell (Vytonation.g sibling, 7 steps, GREEN ×2 2026-07-20): three dosed cogs
   grappled individually cut into distinct cells — express orders sizes by dose — an
    unchanged world grants no motion (T byte-identical at the fixed point) — a
     pointer-pinned cell holds its seat while a dose change rearranges the world around
      it — the released hold eases free and retires.  Two model fixes the Book forced:
       a COLD BATCH of newcomers now spreads around the frame perimeter at distinct
        deterministic points (all-at-once arrivals used to pile on one boundary point
         and power_cells never separates near-coincident seeds), and the T-write carries
          a settle tolerance EPS = 0.5 px (an exact `!==` rewrites T forever on
           sub-pixel relax drift — law 1 needs a rest threshold to be byte-true).

- **The owed-engineering trio (2026-07-20, all live-gated GREEN ×2)** — the three §0
   items, landed as one round while the Radio agent integrates:
  - **Unit 1 — watch_c era-guarded multi-handler + teardown** (`Housing.svelte.ts` core
     spine, one coherent write): `watched` entries carry an `owner` and their own last-seen
      `v` (the parallel `watched_v[]` is gone, so per-owner teardown is a clean filter);
       `watch_c(C, handler, owner?)` dedups per **(C, owner)** — every current ownerless
        caller stays byte-identical AND now coexists with an owned watch on the same C;
         new `unwatch_owner(owner)` tears down by owner, era-guarded (marks entries `dead`
          before filtering; the flush walks a stable snapshot with a `dead` check so a
           concurrent decommission never mis-fires).  `Vyto.g`: `Vyto_watch` tags each
            grapple `owner = w`; `Vyto_decommission(w)` → `unwatch_owner(w)`.  Gate:
             **VytoTandem** GREEN ×2 (two watchers on one C — old dedup dropped the second;
              decommission leaves only the survivor).  Regression: VytoStaple/Cell/Mitosis/
               Radio + **LakeTiles** (the Lies `watch_c(waft)` Book) all green — ownerless
                callers unperturbed.  **Retires the top hazard below.**
  - **Unit 2 — spool freeze-on-run-fail** (`Vyto.g`): `Vyto_spool_frozen(w)` reads the Run
     ref's `Run.c.run.sc.failed_at` (the step Story stamps when a run PAUSES at a failing
      step — the resident/editor forensics path, not a headless flag-and-continue); when
       frozen, `Vyto_spool_cull` returns early so a failed run's whole ring survives as
        evidence (extends the o/bless exemption to the ring).  Gate: **VytoFreeze** GREEN
         ×2 — green run culls to the ~60 cap, a mock Run then lands `failed_at` and a
          further cull freezes so all 66 survive.
  - **Unit 3 — Storui whichever-glass seek + step→yore_n shim** (`Storui.svelte`, Story's
     UI): beside the byte-unchanged `Cyto_seek` elvis sits a feeble `Vyto_seek` one — a
      commissioned glass gets the same step pip, no-ops for a Cyto-only run (glasses are
       mutually exclusive per run).  `Vyto.g`: `e_Vyto_seek` → `Vyto_seek_to(w, opts)` — a
        `yore_n` seek parks directly (byte-unchanged), a `step_n` seek translates to the
         yore of the moment carrying that step (a scrubber-only moment with no step_n is
          unreachable — `Number(undefined)` is NaN, matched by nothing; no match parks at
           live).  Gate: **VytoSeek** GREEN ×2 (step 4 → yore 20; unmatched step +
            scrubber-only stay unreachable).  Cyto path byte-identical; Storui bundle-proofed
             200.  Book-gated the resolver; only the `$effect`'s glass-pick is hand-verified
              (a headless Book can't drive UI reactivity).  **Retires the Storui-seek hazard
               below.**

## Fresh from the 2026-07-20 round

Three flags the human dropped this round, each folded into its workingout:

- **IOexpr are wild speculation** (commission §3): the Scannable recipe form is a guess at
   what many IOexpr in some locality can achieve — flagged speculation until a tenant proves
    it.  Coding stance beside it: IOexpr look like the webbing for something bigger around
     here, so put **lots of structure** in them — structured sc children over clever packed
      strings.
- **The pelt may be a two-way medium** (pelt §6): the vtuffing notator may need to *respond*
   to the shape plan and carry dynamic advice back for the shapes — a negotiation, not a
    handing-down, with the pelt the plausible surface.  Confirmed beside it: any UI bit or
     notation is shape-agnostic — erectable inside ANY shape, reading the pelt for
      orientation.
- **Deletion's departure-arc** (calm §2): the human converged independently on the escort
   resolution — when the place you stood vanishes the view returns upward and we animate
    that change of existence.  Folded into preen (a) below.

## Preen: ruled 2026-07-20

All six answered by the human in one sitting:

- **(a) Deletion.**  BLESSED — a supervening event; holds convert into *departure escorts*
   that draw the arc and walk the view upward.  (The human: "why not easily yes?" — it
    nearly was; the only cost is machinery: the mirror must keep a departed row alive until
     its escort lands, a lifetime rule rather than a rank.)
- **(b) The word.**  Calm stays.
- **(c) snap_H's Se parameter.**  YES — core Story surface may be touched; the build
   proceeds this round.
- **(d) Persistence.**  Session-only for v1; `H.stashed` waits.
- **(e) Refusal stance.**  Stands.  (The human: "why would it refuse?" — only ceremony it
   structurally cannot honor: the wave handshakes ask the glass to pause until a wave is
    done and Vyto has no waves — honoring them would stall its own drive.  Data is never
     refused; the rebuff row is there so an old-style client learns at the seam.)
- **(f) Shapes.**  Parked — milestone 3 ships `cell` alone; the other six (slab · band ·
   wedge · ring · mold · body) wait for a tenant to demand one.  (The human's "hmmm sure?"
    was tentative — noting it is reversible any time; a parked shape costs nothing.)

Defaults taken unless vetoed: ε = 0.5 px · drift 0.25 px/frame · SETTLE_FRAMES = 8 ·
 ω = 6/grawave · η = 0.25 (Lloyd-with-memory) · O_CAP 24 o-marks · spool 60 drop-oldest —
  all eye-tuned on the first tenant.

## Hazards the workingouts found (verify-against-live-code laws)

- ~~`watch_c` dedups by C ref per House SILENTLY — one handler per (House, C)~~ **RESOLVED
   Unit 1 (2026-07-20)**: dedup is now per **(C, owner)**; an owned grapple coexists with
    another ghost's ownerless watch on the same C, and `unwatch_owner` gives real teardown.
     Ownerless callers (Story ×2, Lies ×2, Auto, &c.) are byte-identical.
- Version bumps NEVER propagate up the C tree — a shelf watch is blind to cards landing on
   a page.  The transitive `deep:` grapple derivation is load-bearing, not a convenience.
- Flush handlers run UNDER a fresh beliefs-mutex hold — "off the beat" is not "off the
   mutex"; an unbounded await in a handler starves beats exactly like in a do_fn.
- `run.c.step_n` is never cleared after a run — step_n stamping must gate on `run.c.driving`
   or overtime moments wear the last step's number.
- ~~Storui's seek dispatch is hardwired `'Cyto/Cyto'` with open_at as a STEP number~~
   **RESOLVED Unit 3 (2026-07-20)**: a feeble `Vyto_seek` elvis sits beside the
    byte-unchanged `Cyto_seek` one; `e_Vyto_seek`/`Vyto_seek_to` translates step→yore.  One
     remaining hand-verified seam: the `$effect`'s choice of WHICH glass to poke (a headless
      Book can't drive UI reactivity — the resolver it calls is fully Book-gated).
- A Story-run Run House goes QUIESCENT under a ttlilt hold — a debounced watch-flush stir
   never gets its `clear()` cycle there, so a Book driving the watch across beats must
    nudge `main()` while it polls (VytoStaple's expecting-poll does).  A resident glass on
     a live tab never sees this; only Story-railed Books do.
- The driving flag rides `Run.c.run.c.driving` — one hop deeper than the obvious
   `Run.c.driving` (the run particle hangs off the Run House as `.c.run`).  The
    parked-run gate and any step_n stamping must take the extra hop.
- The story_save 1-step toc race (the toc-protection memory) bit VytoCell repeatedly
   while it was brand_new — an orphaned save collapses a multi-step toc to one line
    between runs.  Re-seed the step lines, then accept IMMEDIATELY once the Book is
     right so real diges lock in.  A variant bit VytoRadio: after seeding, the runner
      re-ran off a CACHED 1-step decode — a reload cleared it and the re-run saw all
       the steps.
- A settle poll pacing one solve per 200ms overruns runner_ask --watch's 20s
   dead-detector on multi-cell worlds (a 6-cell settle took ~14s and false-deaded).
    Burst solves per poll — up to a bounded batch, declaring rest the instant a solve
     rewrites no target (Vytonation's `Vyto_rest_poll` does).

## VYTO REQUESTS — from the wire side (Radio/Sounditron client, 2026-07-21)

Filed by the wire-side agent (licensed by the human) as the parity work that gates Sounditron's
 full move off Cyto+Voro+faces onto Vyto (see §0 "The migration model").  These are demands ON
  Vyto.g/Vytui — the wire side won't build them (avoid-zone); they are what Vyto must grow before
   Sounditron can commission it from within and drop the flag.

1. **A timeline face — step around in time (the human's headline ask).** Like Storui's timeline:
    a strip that steps back/forward through the run's moments and SHOWS the last few places the
     world was — an ongoing Story, not just the live frame.  The data already exists: the Run's
      step/got_snap spool history (`Vyto_spool_*` already captures moments; Storui's step→yore_n
       seek shim is the model — point the face at that same source).  This is the headline gap —
        Sounditron's value is the meander through time, which plain live cells don't carry.
2. **Face / crew parity for the Radio organs.** Vyto v1 is plain cells; Sounditron's UI is
    face-heavy (RadioFace / TunerFace / StokerFace / DoorFace / … + the Gang/crew crowd + the
     sub-cell world).  For Sounditron to move without regressing, a Vyto cell needs to host its
      organ's face (or an equivalent), the Gang needs a crowd rendering, and the sub-cell world
       needs a home.  Take these as individual requests as they're reached, not one big bang.
3. **Retire the Voro overlay per-Book.** Suspected reason `?VY=1` looked identical to Voro: the
    Voro glass rides ATOP the base regardless of Cyto|Vyto.  When a Book commissions Vyto its Voro
     overlay must not render — the migration drops the overlay, not just swaps the base.  (Wire
      side will confirm the suspicion at cutover; flagging it so Vyto owns the per-Book off-switch.)
