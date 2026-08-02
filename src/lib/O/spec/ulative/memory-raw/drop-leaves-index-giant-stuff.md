---
name: drop-leaves-index-giant-stuff
description: "drop() is a soft-delete that leaves rows in the parent index; a live-for-minutes churny C (Pier %outbox) grows to the 6000 'giant stuff' fatal. FIXED generally: drop() counts un-reindexed drops and auto-compact()s at 500 + outbox specifics."
metadata:
  node_type: memory
  type: project
  originSessionId: 589b8f0b-32c5-427d-9aab-2e790bee64c1
---

`TheC.drop(n)` (Stuff.svelte.ts) is a **soft delete**: sets `n.c.drop = 1` and leaves n's row in the PARENT's
 index (`this.X.z` + every `/$k`, `/$k/$v` bucket). `o_query` re-scans the whole `X.z` and just filters
  `c.drop` out. So a **churny parent** grows its index length without bound; `TheX.i_z` throws the literal
   **`"giant stuff"`** once any `z` passes 6000. The canonical offender: a Pier **`%outbox`** — one `%emit`
    booked per sent frame (Peeroleum_send), culled only on ack — which on a **busy networked system running
     for minutes** (the tests never did this) piles up two ways: (1) un-acked emits to a STALLED peer;
      (2) acked emits that stamped `acked:1` but **nothing ever removed** (no Story-step reset in the live app).

**THE GENERAL FIX (2026-07-29, Stuff.svelte.ts — the human's "graph-overload impossible by design"):**
 `drop()` increments `this.X.pending_drops`; at **`DROP_COMPACT_AT` (500)** it calls a new **`compact()`** —
  rebuilds `z` + every bucket from the LIVE children only. `compact()` is SYNCHRONOUS + transaction-free on
   purpose: it re-indexes the SAME child identities via the proven `i()` path (no atom materialisation, no
    `resolve()` pairing, no `X_before`), preserving `serial_i` for observer version-continuity — so it is safe
     to fire from inside `drop()`. **`replace()` is NOT safe here** — it's an async transaction that throws
      "nested replace() transactions" inside a `do_fn`, and `drop()` runs inside do_fn constantly ([[nested-replace-in-do-fn]]).
       (The older i_z compaction — filter `c.drop` at 5000, throw at 6000 with a NAMED message — stays as a backstop.)

**OUTBOX SPECIFICS (2026-07-29, Peeroleum.g/Tribunal.g):** (a) `repli_want` made **ephemeral** (Peeroleum_send
 `ephemeral` set) → NO outbox emit booked + NO per-send log: the PULL re-asks every offset every 4s at the app
  layer (Ra `ra_want_ts`), so transport retransmit is dead weight; receiver still SERVES it (not in the receive
   bypass). (b) On ack (`Peeroleum_take_ack`) now `box.drop(emit)` (was: only stamp `acked:1`) → acked emits
    leave the outbox and feed the compactor. (c) Log flood (~3000/min) gated: `repli_want` joins ping/pong/ack
     in Tribunal's `noisy` (ws SEND + ws RECV); data REPLIES still log so downloads stay visible.

Tell: a caught `⨳ SHARE BEAT THREW — giant stuff: index 'z' reached N LIVE rows (compaction found nothing dropped
 to reclaim)` ⇒ the rows are genuinely LIVE/un-acked, not GC-lag — find the churny parent (almost always a Pier
  `%outbox` to a stalled peer). NOT live-verified headless — needs a real multi-tab run for minutes. See
   [[stream-continuation-starve-fix]], [[musurastream-real-streaming]], [[never-stash-shared-tree]].
