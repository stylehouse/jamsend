# Vyto — the working doc

The new glass.  Spec: `Vyto_spec.md` (unpreened — three rounds 2026-07-19).  Machine-level
 elaborations: `vyto_workingouts/` — shapes · pelt · calm · spool · commission, each checked
  against the LIVE code (not against the spec's hopes), each ending in open questions only
   the human can rule on.  This doc is the one todo; the workingouts are its appendices.

## 0. What to get on with next

The skeleton stands (see "what stands" below) and the vocabulary is in the workings.  The
 arc: **wear the words in → give the glass eyes (Scan) → give it a memory (Spool) → give it
  a body (the first cell) → hand it the abdomen (the Radio world as first tenant)**.  Next
   moves, roughly in order:

- **The human preens**: the spec, the dictionary (§14 — words are still cheap to rename),
   and the workingouts' open questions.  The preen-hardest points are gathered below.
- **Milestone 2a — Scan writes the mirror**: the first real organ body.  Walk the grapples,
   build the mirror C** under `w.c` (hydrated trees ride `.c` — never a live C ref in sc,
    the CytoStep habit we are NOT carrying).  Scan must mint **deterministic cell identity**
     from line identity — the spool's replay claim depends on it (spool workingout §diff).
- **Milestone 2b — the spool captures for real**: `snap_H` payload on `.c.snap` (NOT enWaft
   — the workingout caught the spec assuming wrong).  Needs the one-line `Se?` parameter on
    `snap_H` so a Vyto capture stops sharing `Run.c.snap_Se` (it would advance Story's
     changed/is_new trace baseline — core Story surface, the human rules first).
- **VytoStaple — the first Book**: mint `A:Vyto > w:Vyto`, commission with an explicit
   grapple list, stir once, assert the board stands — "the board stands — every organ
    listed" is a natural first sentence.  Register on the Credence board
     (`Storying,of_Book` + `brand_new`, desc no commas).  All testing on the live runner.
- **Milestone 3 — the first cell**: Vytui grows the viewport; one shape (cell) + the
   pointer-hold + the critically-damped renderer law (calm workingout has the closed-form
    step; ω = 6/grawave with ONE constant, not the 0.4-seed/0.3-fallback split Cyto has).
- **First tenant**: one Radio world on BigSoundland end-to-end — recipe commission (the
   commission workingout §worked-example has the real gear rows), grapple watch, spool,
    strip, Calm's pointer-hold, one %Slope.

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

**Not yet seen live**: the board itself — nothing commissions Vyto yet, so no `w:Vyto`
 exists anywhere.  First sighting comes free with VytoStaple (or a drum-pad mint).

## The preen-hardest points (from the workingouts' open questions)

- **calm**: the spec's priority table is literally cyclic (deletion > pointer, pointer ∈
   gestures, seek < gestures, seek > everything ∋ deletion).  The workingout resolves it by
    making deletion a SUPERVENING event (holds convert into departure escorts) — needs the
     human's blessing.  Also ε = 0.5px / SETTLE_FRAMES = 8 proposed.
- **spool**: the `Se?` param on snap_H (core Story surface); bless persistence via
   H.stashed or not; O_CAP 24 for o-marks; freeze must watch step verdicts
    (`step.sc.unexpected` — a runner NEVER sets `failed_at` mid-run).
- **shapes**: the cell "seed-and-relax" loop is NEW matter — no relax exists today (fcose
   owned positions; power_cells only reinterpreted them); Lloyd-with-memory η=0.25 proposed.
    Plus slab squarify-when-orderless, band overlap-vs-z, who is the middle of wedge/ring.
- **pelt**: band is the one CROSS-LAID text shape (rows read level while matter flows
   downhill) — flagged; glyph law = translate + rotate + per-run uniform size ONLY.
- **commission**: refusal stance (proposed: refuse-the-key + loud %rebuff + still accept);
   slope write-back (dragging a Mag writes the weight) needs a `Radio_lineup_fill` seam.

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
