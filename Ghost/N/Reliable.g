// Reliable — the network-healing floor: an in-order, exactly-once stream over a lossy line.
//  Pure cursor|ledger algebra, no particles of its own; the methods ride on H and the spine calls them.
//   inseq is called from Peeroleum_deliver, retx from the outbox sweep off Runstepped.
//  Dormant on the happy path — the clean mock never drops|dups|reorders, so a real run touches none of it.
//   The adversary region below, or a retransmit re-sending a seq, is what first bends the stream.
//  No wall-clock anywhere: the Story replays, so deadlines count logical ticks, sweep|carrier beats, never ms.
//  The live gate is the in-app PereStaple run plus the heading-6 corruption tests.

// ── inbound: per-Pier sequence discipline, the correctness floor ──
// It MUST precede retransmit: a re-sent or reordered frame dispatched twice corrupts state.
//  The cursor st {last, buffered} rides pier.c, off-snap; `last` is the highest CONTIGUOUS seq delivered.
//  A dup ≤ last stays caught even after its req:unemit was %done and culled, because `last` persists.
//   That persistence closes the gap a bare oai-by-seq would leave open.

// inseq_admit — fold an arriving seq into st, returning the ordered seqs ready to deliver now.
//  An empty return means a dropped dup, or a gap held until it fills. Mutates st.
inseq_admit(st, seq):
    if (!Number.isFinite(seq) || seq <= st.last) return []         // already delivered | too old → drop
    if (st.buffered.includes(seq)) return []                       // already held → drop
    if (seq > st.last + 1) { st.buffered.push(seq); return [] }    // gap ahead → buffer, deliver nothing yet
    let out = [seq]
    st.last = seq                                                  // contiguous → deliver it,
    for (;;) {                                                     //  then drain the run a filled gap releases
        let i = st.buffered.indexOf(st.last + 1)
        if (i < 0) break
        st.buffered.splice(i, 1)
        st.last++
        out.push(st.last)
    }
    return out

// ── outbound: retransmit the un-acked ──
// Peeroleum_send stashes emit.c.frame, sent_tick, and attempts; Peeroleum_retx_sweep rides the Runstepped
//  boundary and drives retx_due, re-handing any due frame to the live transport.
//   The peer's inseq dedups the re-send, so a frame that was merely slow costs nothing.

// retx_delay — ticks to wait after the n-th send before the next; capped exponential backoff.
retx_delay(attempts, p):
    let n = Math.max(1, attempts)
    return Math.min(p.cap, p.base * Math.pow(p.factor, n - 1))

// retx_due — partition the un-acked emits {seq, sent_tick, attempts, acked} at logical-tick `now`.
//  Window elapsed with tries left → resend; window elapsed but exhausted → dead.
//   No-SACK: anything behind an unfillable gap dies too, so dead rolls on to faulty handling and reset.
//  Policy is {base:2, factor:2, max_attempts:5, cap:16}.
//  Pure — the caller bumps attempts and sent_tick when it actually re-sends.
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

// ── the adversary: a deterministic lossy carrier, so a Story can exercise the sad path ──
// The clean mock pairs ports verbatim and never fails, so healing code that never saw a lost frame is untested.
//  This wraps a real partner port with a seeded, per-seq schedule.
// Two invariants keep it a regression gate, not a flake:
//  deterministic — an explicit per-seq list, never Math.random;
//  replay-safe — delay counts logical ticks, since tick() rides carrier beats, never the wall.
// A dropped seq is TRANSIENT: lost on its first transit, passed on every retransmit — so the retry HEALS it.
//  That is the reliability test (drop → emit un-acked → retx re-sends → this time it lands).
//  A permanent dead link is the separate `blackhole` knob: every transit lost, so the emit eventually goes %dead.
// Reorder is not its own knob — it falls out of delay, since holding seq N past N+1 IS a reorder.
//  drop → retransmit-heals, dup → dedup, delay → gap-buffer, blackhole → dead.
// Test scaffolding, dormant until an adversarial Story hands a port through make_lossy_partner.

// lossy_decide — PURE: decide blackhole | drop | dup | {delay} | pass for this seq.
//  Precedence is blackhole > drop > dup > delay, so a seq in two buckets has one fate and the trace stays deterministic.
lossy_decide(s, seq):
    if (s.blackhole?.includes(seq)) return 'blackhole'
    if (s.drop?.includes(seq)) return 'drop'
    if (s.dup?.includes(seq)) return 'dup'
    let d = s.delay?.[seq]
    if (d && d > 0) return { delay: d }
    return 'pass'

// make_lossy_partner — wrap realPartner, whose .recv delivers into its Pier inbox, so recv applies the schedule.
//  drop loses a seq's FIRST transit (seen[] counts transits), then passes the resend — the sender's emit
//   goes un-acked, the retransmit re-sends, and this time it lands: a healed drop.
//  blackhole loses every transit — the permanent-fault case.
//  dup delivers twice, so inseq must collapse it; delay holds N ticks (the gap-buffer|reorder case).
//  tick() advances the logical clock, releasing due frames in seq order.
//  held, dropped (the seqs it actually swallowed — a witness target that survives the cull), and clock are exposed.
make_lossy_partner(realPartner, schedule):
    const H = this
    let held = []
    let clock = 0
    let seen = {}
    let dropped = []
    let deliver = (f) => realPartner.recv(f)
    return {
        recv(frame) {
            let seq = Number(frame?.header?.seq)
            let action = H.lossy_decide(schedule, seq)
            if (action === 'blackhole') { dropped.push(seq); return }
            if (action === 'drop') {
                seen[seq] = (seen[seq] || 0) + 1
                if (seen[seq] === 1) { dropped.push(seq); return }
                return deliver(frame)
            }
            if (action === 'dup') { deliver(frame); deliver(frame); return }
            if (typeof action === 'object') { held.push({ frame, due: clock + action.delay }); return }
            return deliver(frame)
        },
        tick() {
            clock++
            let due = held.filter(h => h.due <= clock).sort((a, b) => a.due - b.due)
            for (const h of due) { held.splice(held.indexOf(h), 1); deliver(h.frame) }
        },
        held,
        dropped,
        get clock() { return clock },
    }
