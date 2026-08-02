---
name: transport-frames-post-do
description: Peeroleum frames deliver via post_do/H.todo — a Book do_fn can NEVER observe a round trip intra-beat; design pulls as fire-and-forget windows that settle between beats
metadata: 
  node_type: memory
  type: project
  originSessionId: a060c31b-3f6c-4aa7-b1a5-fa5fe9c87f36
---

The mock carrier's `send` is `H.post_do(() => partner.recv(frame))` (Peeroleum.g transport) — the frame
 rides **H.todo**, drained by the think loop BETWEEN passes, never inside the do_fn that sent it. So no
  amount of `pier.do()` / `peering.do()` pumping inside your own do_fn advances a round trip: a
   send-then-check-reply loop degrades to ONE trip per beat (hit building MusuReco 2026-07-04 — the
    chase pulled one page per beat and never reached the transcode frontier).

**Why:** post_do exists to keep mutations in Atime; the queue only drains when the current think returns.
 `Lake_pump_handshakes`-style pumping helps reqs already SITTING in inboxes, not frames still queued.

**How to design instead:** fire-and-forget. Send a WINDOW of requests (stride-aligned, want-once dedup),
 return, and let the beat's settling (multiple think passes to quiescence) complete every queued hop —
  ALL pending hops drain per step, so pipelining is free. Read the results NEXT beat. MusuReco_pull is
   the canonical shape; [[repli-protocol]]'s parked wants absorb requests that outrun a growing source.

Corollary: a "did it arrive" latch (e.g. MusuReco's `early:before_transcode_done`) must be CHECKED on a
 later beat's entry, not right after the send.
