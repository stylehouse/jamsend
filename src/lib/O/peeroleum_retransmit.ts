// peeroleum_retransmit — the pure RE-SEND decision: which un-acked %outbox/emit frames are due to go
//  again, and which have exhausted their attempts (the channel is presumed down).  The %outbox is
//   already "a retransmit queue" (every real outbound frame books an emit that lives until its ack
//    stamps %acked); this is the missing retransmitter — the part that NOTICES an emit has sat un-acked
//     too long and sends it once more.
//
//   It sits ON TOP of inbound seq discipline (peeroleum_inseq): a retransmit re-sends an already-
//    delivered seq, so the receiver's inseq MUST dedup it (delivered-dup → re-ack, never re-dispatch) —
//     wire inseq first (it is, in Peeroleum_deliver), or every retry corrupts.  That ordering is the
//      whole reason B's build order is carrier → inseq → retransmit.
//
//   Clock is LOGICAL ticks (carrier / sweep beats), NEVER wall-clock ms — the same doctrine as the
//    lossy carrier: reliability deadlines must replay deterministically and the Story runner replays.
//     The spine drives the tick from its sweep pass (Runstepped / the keepalive interval); a headless
//      spec drives it explicitly.  Count sweep-passes, not milliseconds.
//
//   Backoff: the window to wait after the n-th send (n = attempts) before re-sending is
//    base·factor^(n-1) ticks, capped at `cap`.  So a freshly-sent emit (attempts=1) waits `base` ticks
//     for its ack before the first retransmit; each further miss widens the gap (factor) up to `cap`, so
//      a flapping channel isn't hammered.  After `max_attempts` sends with no ack — i.e. the window
//       after the LAST allowed send also elapses — the emit is DEAD: the caller rolls it to %faulty and
//        kicks liveness (the frame is given up on, never silently retried forever).
//
//   No selective-ack (v1): the receiver acks only a frame it has VERIFIED + dispatched (inseq's
//    contiguous path), never one merely buffered behind a gap.  So a permanently-lost seq isn't the only
//     casualty — everything sent after it stays buffered, un-acked, and eventually dies too.  That
//      cascade is intentional: an unfillable gap means in-order progress has stopped, so killing the
//       channel (→ %faulty → reset_handshake) is the right outcome, not papering over it.  SACK (ack a
//        safely-buffered-but-unverified frame to spare the cascade) is a future optimisation, not v1.

export type RetxEmit = { seq: number, sent_tick: number, attempts: number, acked?: boolean }
export type RetxPolicy = { base: number, factor: number, max_attempts: number, cap: number }

// RETX_DEFAULT — conservative for a step-paced sweep: a fresh emit gets 2 ticks to be acked, then
//  re-sends with a doubling window (2,4,8,16) capped at 16, for 5 total sends before it's declared dead.
export const RETX_DEFAULT: RetxPolicy = { base: 2, factor: 2, max_attempts: 5, cap: 16 }

// retx_delay — ticks to wait after the n-th send (n = attempts) before the (n+1)-th.  Guards n≥1 so a
//  malformed attempts=0 still yields the base window rather than base/factor.  Pure.
export function retx_delay(attempts: number, p: RetxPolicy): number {
    const n = Math.max(1, attempts)
    return Math.min(p.cap, p.base * Math.pow(p.factor, n - 1))
}

// retx_due — partition the un-acked emits at now_tick into { resend, dead }.  An acked emit is ignored
//  (its ack already stamped it).  An emit whose backoff window has NOT yet elapsed is left alone (still
//   waiting for its ack).  Once the window elapses: attempts remaining → resend; attempts exhausted →
//    dead.  Returns seqs only (like inseq) so the spine re-looks-up the emit to get its off-snap frame;
//     mutates nothing — the caller bumps attempts/sent_tick when it actually re-sends.
export function retx_due(emits: RetxEmit[], now: number, p: RetxPolicy): { resend: number[], dead: number[] } {
    const resend: number[] = [], dead: number[] = []
    for (const e of emits) {
        if (e.acked) continue
        if (now - e.sent_tick < retx_delay(e.attempts, p)) continue   // still inside the ack window
        if (e.attempts >= p.max_attempts) dead.push(e.seq)            // window elapsed after the last send → give up
        else resend.push(e.seq)                                       // window elapsed, attempts remain → re-send
    }
    return { resend, dead }
}
