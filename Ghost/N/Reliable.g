// Reliable — the network-healing floor: keep an in-order, exactly-once stream over a lossy line.
//  Pure cursor/ledger algebra, no particles of its own — its methods ride on H and the spine calls them
//   (inseq from Peeroleum_deliver, retx from a future outbox sweep). Dormant on the happy path: the clean
//    mock never drops/dups/reorders, so a real run touches none of this until Lossy.g — or a retransmit —
//     makes the stream imperfect. NO wall-clock anywhere: the Story replays, so deadlines count logical
//      ticks (sweep/carrier beats), never ms. Proven shape lived in peeroleum_inseq/_retransmit.ts before
//       folding here; the in-app PereStaple run + heading-6 corruption tests are the live gate now.

// ── inbound: per-Pier sequence discipline (the correctness floor) ──
// MUST precede retransmit: a re-sent (or reordered) frame dispatched twice corrupts state. The cursor st
//  {last, buffered} rides pier.c (off-snap); `last` = highest CONTIGUOUS seq delivered. A dup ≤ last stays
//   caught even after its req:unemit was %done+culled, since last persists (the gap bare oai-by-seq left).

// inseq_admit — fold an arriving seq into st; return the ordered seqs ready to deliver now (empty = dup
//  dropped, or gap held till it fills). Mutates st.
inseq_admit(st, seq):
    if (!Number.isFinite(seq) || seq <= st.last) return []        // already delivered / old → drop
    if (st.buffered.includes(seq)) return []                       // already held → drop
    if (seq > st.last + 1) { st.buffered.push(seq); return [] }    // gap → buffer, deliver nothing yet
    let out = [seq]
    st.last = seq                                                  // contiguous → deliver,
    for (;;) {                                                     //  then drain the run a filled gap releases
        let i = st.buffered.indexOf(st.last + 1)
        if (i < 0) break
        st.buffered.splice(i, 1)
        st.last++
        out.push(st.last)
    }
    return out

// ── outbound: retransmit the un-acked (< not wired — needs Peeroleum_send to stash emit.c.frame +
//     sent_tick/attempts, and a sweep off Runstepped driving retx_due) ──

// retx_delay — ticks to wait after the n-th send before the next; capped exponential backoff.
retx_delay(attempts, p):
    let n = Math.max(1, attempts)
    return Math.min(p.cap, p.base * Math.pow(p.factor, n - 1))

// retx_due — partition un-acked emits {seq, sent_tick, attempts, acked} at logical-tick `now` into
//  {resend, dead}: window elapsed + tries left → resend; window elapsed + exhausted → dead (no-SACK, so
//   anything stuck behind an unfillable gap dies too → faulty/reset). Policy {base:2,factor:2,
//    max_attempts:5,cap:16}. Pure; the caller bumps attempts/sent_tick when it actually re-sends.
retx_due(emits, now, p):
    let resend = []
    let dead = []
    for (const e of emits) {
        if (e.acked) continue
        if (now - e.sent_tick < this.retx_delay(e.attempts, p)) continue
        if (e.attempts >= p.max_attempts) {
            dead.push(e.seq)
        } else {
            resend.push(e.seq)
        }
    }
    return { resend, dead }
