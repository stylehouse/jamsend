// peeroleum_lossy — a deterministic ADVERSARIAL mock carrier for testing Peeroleum reliability.
//
//   The clean mock pairs ports verbatim (Aliceport.partner = Bobport) — it never drops, delays,
//    reorders, or duplicates a frame.  So retransmit / inbound-seq-discipline / liveness code that
//     has never seen a lost frame is untested code.  This wraps a real partner port with a SEEDED
//      schedule keyed by frame seq, so a Story can exercise the sad path reproducibly.
//
//   Two invariants make it a regression gate rather than a flake source:
//    1. Deterministic — the schedule is an explicit per-seq list, no Math.random (which is banned
//        here anyway).  Same schedule → same delivery trace, every run.
//    2. Replay-safe clock — delay is counted in LOGICAL ticks (carrier beats), never wall-clock ms.
//        Reliability is clock-based (deadlines, last-heard) and the Story runner REPLAYS; a Date.now()
//         in a delay would make replay nondeterministic.  The tick is injected/driven, never read off
//          the wall.  (This is the seam the retransmit/liveness deadlines must also use — count
//           sweep-passes, not milliseconds.)
//
//   Reorder is not its own knob — it falls out of delay: delaying seq N past the arrival of N+1 IS a
//    reorder.  drop exercises retransmit; dup exercises dedup; delay/reorder exercises gap-buffering.

export type LossySchedule = {
    drop?: number[]                    // seqs that never arrive (→ retransmit must re-send)
    dup?: number[]                     // seqs delivered twice (→ dedup must drop the second)
    delay?: Record<number, number>     // seq → ticks to hold it (→ gap-buffer/reorder)
}

export type LossyAction = 'pass' | 'drop' | 'dup' | { delay: number }

// lossy_decide — PURE: what to do with the frame carrying this seq.  Precedence drop > dup > delay,
//  so a seq listed in two buckets has one unambiguous fate (keeps the trace deterministic).
export function lossy_decide(s: LossySchedule, seq: number): LossyAction {
    if (s.drop?.includes(seq)) return 'drop'
    if (s.dup?.includes(seq)) return 'dup'
    const d = s.delay?.[seq]
    if (d && d > 0) return { delay: d }
    return 'pass'
}

// make_lossy_partner — wrap `realPartner` (the far port, whose .recv delivers into its Pier inbox)
//  so that partner.recv(frame) applies the schedule.  Returns the wrapper plus `held` (the delayed
//   queue, for assertions) and `tick()` (advance the logical clock one beat, releasing due frames).
//
//   In the spine, tick() is driven by the carrier's delivery beats (one per post_do hop); in a
//    headless spec the harness drives it explicitly.  A dropped frame simply never calls deliver — so
//     the sender's %outbox/emit for that seq stays un-%acked, which is exactly the condition retransmit
//      must notice.  A dup calls deliver twice; dedup (inbox last-contiguous) must collapse it.
export function make_lossy_partner(
    realPartner: { recv: (frame: any) => any },
    schedule: LossySchedule,
) {
    const held: { frame: any, due: number }[] = []
    let clock = 0
    const deliver = (f: any) => realPartner.recv(f)
    return {
        recv(frame: any) {
            const seq = Number(frame?.header?.seq)
            const action = lossy_decide(schedule, seq)
            if (action === 'drop') return                       // lost — never delivered
            if (action === 'dup') { deliver(frame); deliver(frame); return }   // arrives twice
            if (typeof action === 'object') {                   // delayed — hold until due
                held.push({ frame, due: clock + action.delay })
                return
            }
            return deliver(frame)                               // pass — straight through
        },
        // advance one logical beat; release every held frame now due (in seq order for stability).
        tick() {
            clock++
            const due = held.filter(h => h.due <= clock).sort((a, b) => a.due - b.due)
            for (const h of due) { held.splice(held.indexOf(h), 1); deliver(h.frame) }
        },
        held,
        get clock() { return clock },
    }
}
