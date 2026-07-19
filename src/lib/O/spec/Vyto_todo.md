# Vyto — the working doc

The new glass.  Spec: `Vyto_spec.md` (unpreened — three rounds 2026-07-19).  Machine-level
 elaborations: `vyto_workingouts/` — shapes · pelt · calm · spool · commission, each checked
  against the LIVE code (not against the spec's hopes), each ending in open questions only
   the human can rule on.  This doc is the one todo; the workingouts are its appendices.

## 0. What to get on with next

The arc: **wear the words in ✓ → give the glass eyes (Scan) ✓ → give it a memory (Spool) ✓
 → give it a body (the first cell) → hand it the abdomen (the Radio world as first
  tenant)**.  The six rulings landed 2026-07-20 and the build ran the same day: Scan writes
   the mirror — the spool captures snap_H payloads on Vyto's own Se — and VytoStaple
    recorded GREEN ×2 on the live runner (the board's first live sighting).  Next moves:

- **Milestone 3 — the first cell**: Vytui grows the viewport; ONE shape (`cell` — the other
   six parked by ruling f), the pointer-hold, and the critically-damped renderer law (calm
    workingout has the closed-form step; ω = 6/grawave with ONE constant, not the
     0.4-seed/0.3-fallback split Cyto has).  Settle stops being hand-struck: the renderer
      strikes it and the spool captures for free.
- **First tenant**: one Radio world on BigSoundland end-to-end — recipe commission (the
   commission workingout §worked-example has the real gear rows), grapple watch, spool,
    strip, Calm's pointer-hold, one %Slope.
- **Owed engineering** (small, any time): watch_c era-guarded multi-handler + teardown-on-
   decommission; spool freeze-on-run-fail (watch step verdicts); the step→yore_n shim +
    whichever-glass seek dispatch for Storui (§12 moult seam).

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

- `watch_c` dedups by C ref per House SILENTLY — one handler per (House, C).  Story already
   watches The_Styles/The_Opt on the Story House; a Vyto grapple there would no-op.  Owed:
    era-guarded multi-handler, and teardown (no unwatch exists — only House death).
- Version bumps NEVER propagate up the C tree — a shelf watch is blind to cards landing on
   a page.  The transitive `deep:` grapple derivation is load-bearing, not a convenience.
- Flush handlers run UNDER a fresh beliefs-mutex hold — "off the beat" is not "off the
   mutex"; an unbounded await in a handler starves beats exactly like in a do_fn.
- `run.c.step_n` is never cleared after a run — step_n stamping must gate on `run.c.driving`
   or overtime moments wear the last step's number.
- Storui's seek dispatch is hardwired `'Cyto/Cyto'` with open_at as a STEP number — the §12
   moult seam; Vyto needs the whichever-glass dispatch + a step→yore_n shim.
- A Story-run Run House goes QUIESCENT under a ttlilt hold — a debounced watch-flush stir
   never gets its `clear()` cycle there, so a Book driving the watch across beats must
    nudge `main()` while it polls (VytoStaple's expecting-poll does).  A resident glass on
     a live tab never sees this; only Story-railed Books do.
