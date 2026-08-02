---
name: yore-moment-spool
description: "Yore/moment-spool design round 2026-07-19: NO continuous Cyto drive exists (watch_c-the-Scannable comments are UNBUILT intent) — glass freezes after last step; the human wants H%Run-owned commission + yore ring + enWaft moment diffs in a Storui-style panel"
metadata: 
  node_type: memory
  type: project
  originSessionId: c04d18c2-95b5-4c6f-9e9e-1966a05f5bee
---

**THE FINDING (verified 2026-07-19): Cyto has NO continuous drive.** The comments in
 Cyto.svelte (~24, ~109) and Sounditron.g (~119) say "Cyto watch_c's the Scannable and
  rescans on ANY version bump" — **no watch_c call exists anywhere**. The only things
   that ever fire `cyto_update_wave`: Story's per-step `Cyto_animation_request`
    (Story.svelte ~2294), `e_Cyto_seek`/`e_Cyto_wipe`, `Tuner_toggle`, `e_Cyto_crush`,
     Voro pop/unpop. Sounditron's toc now carries useCyto so the RAIL commissions
      (takeTurns + wave flags) and `Sounditron_glass` stands down → after the last step
       (or inside a long overtime hold) NOTHING pokes: the glass freezes while faces/
        Stuffings (live components) keep updating — that mismatch is the human's "Cyto
         not responding to changes later". The trickle's "re-tessellation paid on bump"
          comment is aspirational.

**The human's asks (design round, not yet built):** spool of moment-snaps so overtime
 failures keep the last N state changes visible; commission owned by H%Run not H%Story
  ("syncable but separate sense of steps"); a Story-like scrubber gizmo in Cyto —
   display-only time travel (never resume past C** state); catalogue states+waves+Voro
    statements; moments carry an **enWaft** encoding viewed in a Storui-style raw/diff
     panel. Prior art: `Sounditron_todo §4` (Yore — in-run half live via rail
      supports_seek; post-run half designed there), [[glass-commission-by-w]] calls
       CytoStep+seek the Yore seed. Zero `yore` in code yet.

**Radios agent's constraints (all verified sound):** commission handoff is a SWAP (kill
 the toc rail or gate it — two commissions fight over wave flags); drop
  wants_wave_done/animation_done from a continuous commission (stalls its own pump);
   commission furniture lookups are depth-sensitive (%Tuner walks H>A>w — new Scannable
    shape → check that seam, silent failure = "toggles do nothing"); carry useFaces or
     glass reverts jambley (allowlist inversion scoped cls===null); spool = VIEW-matter
      never world-matter (w:Cyto sits BESIDE the Run House → off run snap — CytoStep's
       accident of home is correct); piggyback the existing meaningful-only bump sites
        (Stoker_census/lineup/trickle/witness) ticking `w.c.yore_n`; capture on
         scan/wave side NEVER in a beat; diagonal-spring = Tuner_toggle deletes
          last_step_n → absolute wave relayouts from scratch (fix: seed layout from
           live positions).

**My design additions (proposed, awaiting the human):** ONE ring, two time senses —
 every capture gets monotonic `yore_n`, step captures ALSO carry `step_n` (pips seek by
  step_n, scrubber walks yore_n; never stamp step_n undefined — omit). Build the
   watch_c(Scannable) for real, coalesced per burst. Move wave_done/animation_done onto
    the REQUEST not the commission so waitCyto Books keep their handshake under a
     continuous commission. Display-only falls out free: CytoStep archives a graph
      MIRROR (topC) not world C**, and trigger 1 already suppresses live pushes while
       open_at is set (seek null = back to live). Moment rows also capture an enWaft
        text of the Scannable via the SAME ref-pass encoder as the Story snap → diff
         moment N vs N−1 in Storui's DMP machinery, and diff a moment vs the EXPECTED
          fixture (overtime forensics). Voro folds are c-side (never in enWaft) → stamp
           a small face/fold/mute summary on the moment row. Cap ~60 drop-oldest but
            FREEZE the ring on run-fail so evidence survives.

**SKELETON BUILT (2026-07-19, same arc):** `Ghost/V/Vyto.g` + `src/lib/O/Vytui.svelte` stand —
 organs/board/bar/spool/commission as NAMED STUBS (high-level-first per spec §11), registered in
  CREDULER_GHOSTS + the Visua Waft overlay; live-editor compiled, bundle-proven, VoroMitosis
   green proved the runner eats the spine with Vyto.go in it.  FIVE WORKINGOUTS in
    `spec/vyto_workingouts/` (shapes·pelt·calm·spool·commission), each verified against live
     code.  CORRECTIONS that beat the spec: fixture snaps come from **snap_H not enWaft** (spec
      fixed ×3; moment payload must snap_H or fixture diffs carry shaping noise — and snap_H
       hardwires Run.c.snap_Se, needs an Se? param = human's call); the House watched-flush
        fires once per CHANGED C not per burst (Vyto_stir_soon latch added) and handlers run
         UNDER a fresh mutex hold; watch_c dedups per (House,C) SILENTLY (Story already claims
          The_Styles/The_Opt — cross-ghost no-op hazard, era-multi-handler owed + NO unwatch
           exists); version bumps never propagate up the tree (deep: grapples load-bearing);
            run.c.step_n never cleared (gate step_n stamping on run.c.driving); calm's priority
             table was CYCLIC (resolved: deletion = supervening event, human to bless).  Board
              NOT yet seen live — nothing commissions Vyto until VytoStaple/first tenant.
               `Vyto_todo.md` is the working doc.

**RULED + BUILT (2026-07-20):** all six preens answered in one sitting (deletion = departure
 escorts BLESSED — the human converged on the arcs independently; Calm stays; Se param YES;
  persistence session-only v1; refusal stance stands — only wave-ceremony keys ever refused;
   shapes parked — `cell` alone for M3).  Built the same day, opus agents doing the bulk:
    **Vyto_scan mirror** (detached at w.c.mirror; identity `.c.tok` = mainkey + join keys
     [id|of|pub|page|seq] with value channels EXCLUDED so a quantity change morphs in place;
      departures wear departing:1 one grace stir then drop), **snap_H grew Se_home**
       (Story.svelte:1255 — sole caller unchanged; Vyto captures on their OWN Se), capture
        stamps row.c.snap from req.c.Run.  **VytoStaple GREEN ×2** (Ghost/V/Vytonation.g —
         8 steps; the board SEEN LIVE; on the Credence board).  Sharp edges found: a
          Story-run House goes QUIESCENT under a ttlilt hold → a debounced watch-flush
           clear() starves — Books driving the watch must nudge main() while polling; and
            `this.c.up` is null in a Story-run context (resident-tab furniture only).
             ghost-compile here needed `EDITOR_URL=http://172.17.0.1:9091` (default :9092
              had no editor).

**M3 BUILT (2026-07-20, same sitting): the first cell.**  `vyto_geometry.ts` (power cut
 ported pure from Cytui) + model `Vyto_express` (dose→env_area) + `Vyto_solve` (root cell
  solver, K=2 Lloyd η=0.25, targets `row.c.T` — solver state rides `.c` ONLY, Scan sweeps
   unknown row sc) + Calm's real pointer-hold (pin+damp rows under detached w.c.calm,
    `Vyto_calm_held`→k∈[0,1], cubic ease-out tail then retire) + Vytui viewport (SVG cells
     by tok, calm §5 closed-form springs ω=6/grawave ??=0.4, walls re-derived per frame,
      RENDERER strikes settle ε=0.5/drift .25/8 frames, hidden-tab sync-paint).
       **PARKED-RUN GATE** (load-bearing): while `Run.c.run.c.driving` (NB extra `.c.run`
        hop) the renderer jumps-to-target and never strikes settle — else renderer settles
         bump yore_n nondeterministically and flake recorded Books.  **VytoCell GREEN ×2**
          (7 steps; VytoStaple regression green both sides).  Two fixes the Book forced:
           cold-batch newcomers spread around the frame perimeter (simultaneous arrivals
            piled on one boundary point; power_cells never separates near-coincident
             seeds), and T-writes carry EPS=0.5px (exact `!==` churns T forever on
              sub-pixel relax drift — law 1 needs a rest threshold).  Multi-cell Books:
               grapple siblings INDIVIDUALLY — each grapple is one top-level mirror row =
                one cell; nested children await the scope milestone.  Next: first tenant
                 (Radio world — BUT the Radio display side is the human's mid-refactor
                  avoid-zone, wait for their word) + owed engineering (watch_c
                   multi-handler/teardown, spool freeze-on-run-fail, Storui
                    whichever-glass seek + step→yore_n shim).

**PORTED PAIR + CLIENT PRIMER (2026-07-20 evening): the teaching round.**  The human's
 Radio agent went LIVE on the tenant integration (second agent, two runner tabs — ours is
  the ★claude tab; coordination rules in [[vyto-refactor-avoid-display]]).  For it:
   `vyto_workingouts/client.md` = the client-integration FRONT DOOR (§9 = what the glass
    does NOT do yet — the anti-parity section a Voro-fluent agent needs most), and the
     main two Voro Books ported as client-shaped teaching Books in Vytonation.g (with a
      commented Vyto client kit): **VytoMitosis** (grow — lone newcomer nearest-to-mean +
       batch rim-spread; extinction escort + re-seat; fixed point) and **VytoRadio** (dose
        drift re-size/re-seat; the hand pins mid-drift then releases — the tenant
         rehearsal).  BOTH GREEN ×2 + VytoStaple/VytoCell regression green.  Model
          refinement verified by that regression: the perimeter entry-spread now fires for
           ANY simultaneous batch>1, not just a cold start (mid-run grow batches piled
            otherwise).  Kit lesson: a settle poll at one solve per 200ms overruns
             --watch's 20s dead-detector on multi-cell worlds — burst solves per poll,
              declaring rest the instant a solve rewrites no target.

**ROUND 3 (same evening):** **Zyto STRUCK** (the human: spurious typo for Vyto — the organ
 board is "the board", part of the glass, §9 rewritten plain); **the pelt** = tiny hairs
  {at,dir,strength} over a cell's interior — "they're the field": solvers comb it, projection/
   text-baselines(Wes-Wilson)/mesh-grain/choreography/flow-docking READ it; **shape catalogue**
    CLOSED set (cell·slab·band·wedge·ring·mold·body — new shape = spec event); **%Bunch** =
     Relate-edge attraction → tessellation adjacency → homogeneity check → Express factors
      shared bits ONCE (visual TRANSFIGURES the snap encoding it was imitating); **the bar** =
       ~7 one-word toggles (live·depths·flows·frames·holds·pelt·o), **depths** = ▦'s
        successor; **o-mark** = seen-it tag, kept without typing (default What:$name), rung
         below blessing; organ guts-language one-liners (reads→decides→writes) + 4 families
          (solvers/governors/scribes/chroniclers); **"strangler plan" RENAMED "the moult"**
           (the human disliked strangler).

**ROUND 2 (same day, the human's design payload — spec rewritten, still unpreened):**
 Calm organ = foundation for the settling CULTURE (%Hold algebra: pointer-hold keeps the
  moused-over cell STILL, flight-latch, shift-hold — "motion is granted, not ambient");
   Focus engine sweeps drift/autosplat magic (shifts = transactions, intermediary visuals
    explain outcomes, replayable from spool diffs); %Scope recursion (compound subgraphs
     laid out locally + PROJECTED into cells, text never shears, unfocused scopes freeze);
      semantic space (%Slope = meaning-owned positions — geometry IS the value; %Flow loud
       curvy vs %Frame receding old-map edges; Relate mints meaning-edges); Express organ
        (dose→area generalised to channel bindings incl bg/fg); spool blessing (human
         promotes moment → landmark, %Assertion-pointed, Situations watch for recurrence);
          **Zyto** = organ board + %Situation/%Sighting (standing recognizers — Assertion's
           run-agnostic sibling); commission recipe form (**Sunpit IOexpr** → derive grapple
            set, watch the GEAR not just Scannable — the human's correction); §14 DICTIONARY
             of coined words for preening; build = HIGH-LEVEL SKELETON FIRST (vocabulary in
              code before rendering). Voro.g does NOT freeze (Fold organ); only Cyto+Cytui
               freeze; "unexpressible" = failure modes lose their vocabulary, intent gains.

**Round 1 spine (superseded in file but still true)**: the five wants
 (space that states · motion never blink · rest · interruptibility · model-is-UI), the
  settling doctrine (Law 1 model hysteresis / Law 2 single-target renderer, no wave queue —
   the vanishing-loop class dies by construction; settle = first-class %Settle signal,
    moments capture AT settle), commission = Scannable+Styles+client_w ONLY, strangler plan
     with named migration tail (Storui seek dispatch seam · runner_shot twin · cytowave
      Books · --why re-home).

**DIRECTION SET (the human, same round): fork fresh Vyto + Vytui** rather
 than merging into Cyto — and **Vyto is a .g** ("probably should... the secret to making
  the code prettier — graph data wants tons of hierarchy expression"; Vytui stays .svelte
   for markup). The human also framed the two-clock design as MUSIC-fundamental: "the way
    to lock certain rhythms of step together... a music paradigm that's fundamental" —
     spools as clocks with quantize-locks (join keys), not lists — strangler via commission (two glasses coexist; Cyto frozen,
  Story-railed Books stay on it; Vyto v1 REFUSES takeTurns/wave-flags). Vytui =
   tessellation-first cells as real DOM/SVG (kills the overlay-sync bug class; text
    sizing native; seed = runner_shot --svg). AND: build the spool as **generic
     series-of-steps machinery** intended for a future Story revamp — the evidence
      side only (captured moments: index + join keys, enWaft payload, retention,
       strip-scrubber UI, DMP diff panel, seek protocol); the CONTRACT side (The/toc,
        dige, req machine, EntropyArrest verdicting) stays Story's own. Extract
         Storui's strip + diff row machinery as the shared components (Storui = the
          proving instance); promote the data shape when Story's revamp arrives as
           second tenant.

**OWED-ENGINEERING TRIO LANDED (2026-07-20, all live-gated GREEN ×2)** — the three §0
 items, one round while the Radio agent integrates Vyto live as first tenant:
- **Unit 1 watch_c** (`Housing.svelte.ts` spine): dedup now per **(C, owner)** not
  (House, C); `watched` entries carry `owner` + own `v` (parallel `watched_v[]` deleted);
  `watch_c(C, handler, owner?)` — ownerless callers byte-identical AND coexist with an
  owned watch on the same C; new `unwatch_owner(owner)` teardown, era-guarded (`dead` flag
  before filter; flush walks a stable snapshot). `Vyto_watch` tags grapples `owner=w`;
  `Vyto_decommission`. Gate VytoTandem; regression LakeTiles (Lies watch_c(waft)).
- **Unit 2 freeze-on-fail** (`Vyto.g`): `Vyto_spool_frozen` reads `Run.c.run.sc.failed_at`
  (Story stamps it on the resident/editor PAUSE path, not headless flag-and-continue);
  frozen ⇒ `Vyto_spool_cull` early-returns, whole ring survives as evidence. Gate VytoFreeze.
- **Unit 3 Storui seek** (`Storui.svelte`): feeble `Vyto_seek` elvis beside byte-unchanged
  `Cyto_seek`; `e_Vyto_seek`→`Vyto_seek_to` translates step_n→yore of the moment carrying
  that step (scrubber-only no-step moment unreachable: Number(undefined)=NaN). Gate VytoSeek;
  only the $effect's glass-pick hand-verified (headless can't drive UI reactivity).
Three decisions FLAGGED for the human: (1) dedup (C,owner) w/ ownerless=current; (2) version
 moved onto entry (representation only); (3) freeze reads failed_at (resident-path signal).
COMMIT POINT reached; nothing staged — runtime churn (GhostList/Keep/Sounditron TimeSpool/
 Credulate) is discardable, separate from the coherent Vyto diff.
