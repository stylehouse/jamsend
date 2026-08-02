---
name: vyto-refactor-avoid-display
description: "Radio's DISPLAY side is mid-refactor by the human (Voro+Cyto → Vyto) — do NOT touch display-side code meanwhile; Mag candidate 3 (limbic show|hide, %Tuner retirement) and explode-on-connect PRESENTATION are parked behind it; wire/data side proceeds"
metadata: 
  node_type: memory
  type: project
  originSessionId: 334456e9-f1e5-4e61-a0c4-7b0aaa37eec7
---

**Ruled 2026-07-19**: the human is refactoring Radio's display side from Voro+Cyto to **Vyto**.
 Until that lands, do not edit display-side code (Voro faces, Cyto glass, %Tuner, the render legs
  of explode-on-connect). The human "never knew %Tuner" — no attachment to it; its retirement
   (Mag_todo §0 candidate 3, the limbic show|hide) is PARKED behind the Vyto refactor.

**Why:** parallel edits to a subsystem mid-rewrite are churn — the Vyto cut will remap the same
 seams. See [[host-commits-midsession]]: the human's commits can land under me.

**How to apply:** Mag work proceeds DATA/WIRE side only ([[mag-model-migration-built]] → the wire
 cut, MusuMag). If a fix seems to need a display-side edit, park it and say so instead. Books stay
  Voro-blind as ever, so re-records are fine.

**2026-07-20 — the refactor went LIVE as a second agent.** The human's "Radio agent" is now
 actively Vytoing (integrating Radio as a Vyto client), running in parallel with my sessions,
  with TWO runner tabs on the fleet. Consequences: the working tree changes under me mid-session
   (re-read Vyto.g/Vytonation.g/tocs from disk before editing — fold, never clobber); a sudden
    red or wedge mid-gate may be the other agent's ghost-compile HMR-ing gen under a driving run
     — re-run on a pinned --runner= before diagnosing; the display side stays theirs. Their
      onboarding doc is `src/lib/O/spec/vyto_workingouts/client.md` (the client primer — keep it
       current when client-facing seams change). Teaching Books for them: VytoMitosis + VytoRadio
        in Vytonation.g.
