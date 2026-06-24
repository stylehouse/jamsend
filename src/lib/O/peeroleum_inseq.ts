// peeroleum_inseq — per-Pier INBOUND sequence discipline: the correctness floor beneath retransmit.
//
//   The clean mock delivers every frame once, in order, so the inbox never sees a duplicate or a gap.
//    The moment retransmit re-sends an un-acked frame, or a real carrier reorders, the inbox DOES —
//     and dispatching a dup twice (a second hear_trust, a second dock_push) corrupts state, while
//      dispatching out of order breaks the maz/handshake ordering.  So seq discipline MUST land
//       before retransmit (B's order), or every retry corrupts.  This is the pure decision; the
//        spine (req_unemit / Peeroleum_deliver) wires it.
//
//   Per-Pier state rides on .c (never snapped): `last` = highest CONTIGUOUS seq delivered, `buffered`
//    = out-of-order arrivals held until their gap fills.  Acks never pass through here (they book no
//     seq); only inbox frames do, and seq is the per-Pier monotone counter (Pier_next_seq), so the
//      stream is one space across all frame types (hello/trust/noop/app), which is what lets a single
//       contiguous cursor order them.
//
//   Verdict for an arriving seq:
//    • seq ≤ last, or already buffered → DUP: drop — re-ack so the sender stops retransmitting, but
//       NEVER re-dispatch (that re-dispatch is the corruption this exists to prevent).
//    • seq > last + 1 → GAP: buffer it, deliver nothing yet (the fill — or a retransmit of the
//       missing seq — releases it).
//    • seq == last + 1 → contiguous: deliver it, advance `last`, then drain the now-contiguous run
//       out of the buffer (a reorder/gap that just filled delivers its whole tail, in order).

export type InSeqState = { last: number, buffered: number[] }
export function inseq_new(): InSeqState { return { last: 0, buffered: [] } }

// inseq_admit — fold an arriving seq into the state; return the ordered seqs now ready to deliver
//  (empty for a dup-drop or a gap-hold).  Mutates the passed state; otherwise pure.
export function inseq_admit(st: InSeqState, seq: number): number[] {
    if (!Number.isFinite(seq) || seq <= st.last) return []        // already delivered (dup / old) → drop
    if (st.buffered.includes(seq)) return []                       // already held (dup) → drop
    if (seq > st.last + 1) { st.buffered.push(seq); return [] }    // gap → buffer, deliver nothing yet
    const out = [seq]; st.last = seq                               // contiguous → deliver
    // drain the now-contiguous run out of the buffer (a filled gap releases its tail in order)
    for (;;) {
        const i = st.buffered.indexOf(st.last + 1)
        if (i < 0) break
        st.buffered.splice(i, 1); st.last++; out.push(st.last)
    }
    return out
}

// inseq_is_dup — pure read (no mutation): is this seq one we've already delivered (or buffered)?
//  Lets req_unemit decide "re-ack but don't re-dispatch" — and, because `last` persists on .c, a
//   re-sent seq is still a dup even after the original was %done and culled to %recent (the gap the
//    naive oai-by-seq dedup leaves: a culled req:unemit is no longer found, so it would re-dispatch).
export function inseq_is_dup(st: InSeqState, seq: number): boolean {
    return Number.isFinite(seq) && (seq <= st.last || st.buffered.includes(seq))
}
