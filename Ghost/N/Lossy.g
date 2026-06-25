// Lossy — the adversary: a deterministic carrier wrapper that drops / dups / delays frames, so a Story
//  can exercise the sad path Reliable.g exists for. The clean mock pairs ports verbatim and never fails,
//   so reliability code that has never seen a lost frame is untested code; this wraps a real partner port
//    with a SEEDED, per-seq schedule. Two invariants keep it a regression gate, not a flake: deterministic
//     (an explicit per-seq list, no Math.random) and replay-safe (delay counts LOGICAL ticks, never ms —
//      tick() is driven by carrier beats, never read off the wall). Reorder is not its own knob: it falls
//       out of delay (holding seq N past N+1 IS a reorder). drop→retransmit, dup→dedup, delay→gap-buffer.
//  Test scaffolding — dormant until an adversarial Story (heading 6) hands a port through make_lossy_partner.

// lossy_decide — PURE: drop / dup / {delay} / pass for this seq. Precedence drop > dup > delay, so a seq
//  in two buckets has one unambiguous fate (the trace stays deterministic).
lossy_decide(s, seq):
    if (s.drop?.includes(seq)) return 'drop'
    if (s.dup?.includes(seq)) return 'dup'
    let d = s.delay?.[seq]
    if (d && d > 0) return { delay: d }
    return 'pass'

// make_lossy_partner — wrap realPartner (whose .recv delivers into its Pier inbox) so recv applies the
//  schedule. drop never delivers (→ the sender's emit stays un-acked = the retransmit trigger); dup
//   delivers twice (→ inseq must collapse it); delay holds N ticks (→ gap-buffer/reorder). tick() advances
//    the logical clock, releasing due frames in seq order. held/clock are exposed for assertions.
make_lossy_partner(realPartner, schedule):
    const H = this
    let held = []
    let clock = 0
    let deliver = (f) => realPartner.recv(f)
    return {
        recv(frame) {
            let seq = Number(frame?.header?.seq)
            let action = H.lossy_decide(schedule, seq)
            if (action === 'drop') return
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
        get clock() { return clock },
    }
