// Retransmit — headless proof of the re-send decision (src/lib/O/peeroleum_retransmit.ts) and, in
//  the capstone, of the whole reliability floor composed: a transient DROP is healed by retransmit, and
//   the receiver's inbound seq discipline (peeroleum_inseq) fills the gap and dedups the re-send — pure
//    logic, no Creduler / no :9091, so it's a real regression gate beneath the .g wiring.
//   Run: node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/Retransmit.spec.ts
import { test, expect } from 'vitest'
import { retx_due, retx_delay, RETX_DEFAULT } from '$lib/O/peeroleum_retransmit'
import { inseq_new, inseq_admit } from '$lib/O/peeroleum_inseq'

// ── unit: the pure decision ──────────────────────────────────────────────────
test('backoff window widens by factor, capped', () => {
    const p = { base: 2, factor: 2, max_attempts: 9, cap: 16 }
    expect(retx_delay(1, p)).toBe(2)     // after the 1st send
    expect(retx_delay(2, p)).toBe(4)
    expect(retx_delay(3, p)).toBe(8)
    expect(retx_delay(4, p)).toBe(16)
    expect(retx_delay(5, p)).toBe(16)    // capped
})

test('a fresh emit is left alone until its ack window elapses', () => {
    const emits = [{ seq: 1, sent_tick: 0, attempts: 1 }]
    expect(retx_due(emits, 1, RETX_DEFAULT)).toEqual({ resend: [], dead: [] })   // base=2, 1<2 → wait
    expect(retx_due(emits, 2, RETX_DEFAULT)).toEqual({ resend: [1], dead: [] })  // window elapsed → resend
})

test('an acked emit is never resent or declared dead', () => {
    const emits = [{ seq: 1, sent_tick: 0, attempts: 9, acked: true }]
    expect(retx_due(emits, 99, RETX_DEFAULT)).toEqual({ resend: [], dead: [] })
})

test('attempts exhausted with no ack → dead (only after the last window elapses)', () => {
    const p = { base: 1, factor: 1, max_attempts: 3, cap: 1 }
    // attempts=3 = max: still inside its window → not yet dead
    expect(retx_due([{ seq: 1, sent_tick: 5, attempts: 3 }], 5, p)).toEqual({ resend: [], dead: [] })
    // window elapsed after the 3rd (last) send → dead, not resend
    expect(retx_due([{ seq: 1, sent_tick: 5, attempts: 3 }], 6, p)).toEqual({ resend: [], dead: [1] })
})

test('resend and dead partition a mixed outbox in one pass', () => {
    const p = { base: 1, factor: 1, max_attempts: 3, cap: 1 }
    const emits = [
        { seq: 1, sent_tick: 9, attempts: 1, acked: true },   // acked → ignored
        { seq: 2, sent_tick: 8, attempts: 1 },                // window elapsed, attempts remain → resend
        { seq: 3, sent_tick: 8, attempts: 3 },                // window elapsed, exhausted → dead
        { seq: 4, sent_tick: 9, attempts: 1 },                // 9==now → inside window → wait
    ]
    expect(retx_due(emits, 9, p)).toEqual({ resend: [2], dead: [3] })
})

// ── capstone: lossy(transient drop) + retransmit + inseq = reliable in-order delivery ─────
// A minimal sender/receiver mirroring the spine: the sender books an outbox emit per frame and a
//  sweep (retx_due) re-sends un-acked ones on backoff; the receiver runs the EXACT Peeroleum_deliver
//   inseq shape — deliver contiguous + ack, hold a gap (no ack), re-ack a delivered-dup.
function makeReceiver(ackBack: (seq: number) => void) {
    const st = inseq_new()
    const held: Record<number, any> = {}
    const landed: number[] = []
    return {
        recv(frame: any) {
            const seq = Number(frame.header.seq)
            const ready = inseq_admit(st, seq)
            if (!ready.length) {
                if (seq <= st.last) ackBack(seq)     // delivered-dup → re-ack (lost ack)
                else held[seq] = frame               // gap / buffered-dup → hold, no ack (unverified)
                return
            }
            for (const s of ready) {
                const f = s === seq ? frame : held[s]
                delete held[s]
                if (!f) continue
                landed.push(s)                       // "verify + dispatch"
                ackBack(s)                           // ack only after dispatch = verified-clean receipt
            }
        },
        landed, st,
    }
}

function makeSender(p = RETX_DEFAULT) {
    const outbox = new Map<number, any>()
    const dead: number[] = []
    let now = 0
    let carrier: (frame: any) => void = () => {}
    return {
        setCarrier(c: (frame: any) => void) { carrier = c },
        emit(seq: number) {
            const frame = { header: { type: 'app', seq } }
            outbox.set(seq, { seq, sent_tick: now, attempts: 1, frame })
            carrier(frame)
        },
        ack(seq: number) { const e = outbox.get(seq); if (e) e.acked = true },
        tick() {
            now++
            const { resend, dead: d } = retx_due([...outbox.values()], now, p)
            for (const seq of resend) { const e = outbox.get(seq); e.attempts++; e.sent_tick = now; carrier(e.frame) }
            for (const seq of d) { dead.push(seq); outbox.delete(seq) }
        },
        get now() { return now },
        outbox, dead,
    }
}

// a carrier that DROPS only the FIRST delivery of each seq in `dropOnce`, then passes retransmits —
//  a transient glitch, the thing retransmit exists to heal (lossy's `drop` is permanent by design).
function transientDrop(receiver: (frame: any) => void, dropOnce: number[]) {
    const dropped = new Set<number>()
    return (frame: any) => {
        const seq = Number(frame.header.seq)
        if (dropOnce.includes(seq) && !dropped.has(seq)) { dropped.add(seq); return }
        receiver(frame)
    }
}

test('transient drop of seq 2 → retransmit heals it, inseq fills the gap, 1..3 land in order', () => {
    const sender = makeSender()
    const receiver = makeReceiver((seq) => sender.ack(seq))
    sender.setCarrier(transientDrop((f) => receiver.recv(f), [2]))

    sender.emit(1)   // delivered + acked
    sender.emit(2)   // first delivery dropped → un-acked
    sender.emit(3)   // arrives but gaps behind the missing 2 → buffered, NOT acked
    expect(receiver.landed).toEqual([1])
    expect(sender.outbox.get(2).acked).toBeFalsy()
    expect(sender.outbox.get(3).acked).toBeFalsy()

    sender.tick()    // now=1 < base(2): nothing due yet — no premature retransmit
    expect(receiver.landed).toEqual([1])

    sender.tick()    // now=2: 2 & 3 un-acked windows elapse → both re-sent; 2's resend fills the gap,
                     //  draining 3 out of the buffer → both land + ack; 3's own resend is a delivered-dup
    expect(receiver.landed).toEqual([1, 2, 3])
    expect(sender.outbox.get(2).acked).toBe(true)
    expect(sender.outbox.get(3).acked).toBe(true)
    expect(sender.dead).toEqual([])
    expect(sender.outbox.get(2).attempts).toBe(2)   // exactly one retransmit healed it
})

test('permanent loss of seq 2 → exhausts attempts → declared dead (no infinite retry)', () => {
    const p = { base: 1, factor: 1, max_attempts: 3, cap: 1 }
    const sender = makeSender(p)
    const receiver = makeReceiver((seq) => sender.ack(seq))
    // a carrier that drops seq 2 forever (lossy's permanent drop); 1 passes.
    sender.setCarrier((f: any) => { if (Number(f.header.seq) === 2) return; receiver.recv(f) })

    sender.emit(1)   // delivered + acked
    sender.emit(2)   // dropped forever
    for (let i = 0; i < 3; i++) sender.tick()   // 3 windows of 1 tick → 3 sends of seq 2, then dead
    expect(sender.dead).toEqual([2])            // given up on, not retried forever (→ caller faults+resets)
    expect(receiver.landed).toEqual([1])
    // NB: anything sent AFTER the unfillable gap also dies — it stays buffered (never dispatched, so
    //  never acked) until its own attempts exhaust.  That cascade is correct: with no selective-ack
    //   (ack = verified-clean dispatch, v1), an unfillable gap kills the channel → faulty → reset.
})
