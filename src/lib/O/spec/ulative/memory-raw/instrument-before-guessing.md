---
name: instrument-before-guessing
description: on a SILENT failure make it loud + re-run to read the trigger BEFORE fixing; no premature victory; complete fixes not half-fixes
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 756959e9-7fe3-49d5-b858-18de4576c696
---

The human, hunting the heist download stall (2026-07-29): *"I'm sick of half-fixing things"*, *"smells like
 needing more errors everywhere, you like silent failures"*, *"fix it properly!"*. Earlier they were angry
  that I'd reported "the source serves without dying" as progress while the download was still stuck at 0/13.

**Why:** this codebase swallows errors three ways — blanket `catch(er){}`, failures that never particle into
 the snap, and console lines nobody watches. A failure you can't SEE, you can only guess at — and a guess is a
  half-fix. The human would rather I spend the effort making the failure LOUD and re-running to read the true
   trigger than blind-patch the most-likely cause. (Concretely: the download's `req_unemit` no-ack branch drew
    no ack AND no log, so the real trigger — bad-body-hash vs a throw vs a startup gate — was un-pinnable from
     a snap; making it loud was the actual unlock, not any single code change.)

**How to apply:**
- When a failure is silent/undiagnosable, FIRST add the loud signal (throttled `console.warn` + a snap-visible
   mark / the [[see-assertion-layer]] channel), compile, and let the next run NAME the trigger. THEN fix that
    specific trigger. Don't flip a coin on the hot path.
- Distinguish load-bearing swallows (a merge/ack/transcode that strands the pipeline → make loud) from benign
   ones (closing an already-closed resource → LEAVE, adding noise is its own bad software).
- Never declare a bug fixed until the END-TO-END goal is verified live (a heist reaching `✓`), not an
   intermediate ("no longer crashes"). State plainly what is confirmed vs still-open. [[snap-data-not-judgement]]
- Prefer ONE complete change over incremental half-fixes; if you must land incrementally, say exactly what
   each piece does and does NOT fix. This pairs with [[fight-back-on-core-changes]] (prove in isolation) and
    the systemic answer: a Story error channel (`spec/Error_channel_todo.md`).
