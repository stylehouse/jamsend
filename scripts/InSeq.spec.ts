// InSeq — headless proof of the inbound seq-discipline floor (src/lib/O/peeroleum_inseq.ts), driven
//  partly THROUGH the adversarial carrier: dedup collapses a retransmit, a reorder buffers-and-fills.
//   Pure logic (no Creduler / no :9091) → a real regression gate for the correctness floor that
//    retransmit will sit on.  Run: node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/InSeq.spec.ts
import { test, expect } from 'vitest'
import { inseq_new, inseq_admit, inseq_is_dup } from '$lib/O/peeroleum_inseq'
import { make_lossy_partner } from '$lib/O/peeroleum_lossy'

// fold a raw arrival order through inseq; return the DELIVERED order.
function deliver(seqs: number[]): number[] {
    const st = inseq_new(); const out: number[] = []
    for (const s of seqs) out.push(...inseq_admit(st, s))
    return out
}

test('in-order: 1..5 deliver once, in order', () => {
    expect(deliver([1, 2, 3, 4, 5])).toEqual([1, 2, 3, 4, 5])
})

test('dup: a re-sent seq is dropped, never re-delivered', () => {
    expect(deliver([1, 2, 2, 3])).toEqual([1, 2, 3])
})

test('reorder: a gap holds until filled, then drains in order', () => {
    expect(deliver([1, 3, 2, 4])).toEqual([1, 2, 3, 4])     // 3 buffered behind the 2-gap
})

test('drop-then-retransmit: the gap holds 3/4; the late 2 fills and releases the tail', () => {
    expect(deliver([1, 3, 4, 2])).toEqual([1, 2, 3, 4])
})

test('dup of a delivered-then-culled seq is still a dup (last persists on .c)', () => {
    const st = inseq_new()
    inseq_admit(st, 1); inseq_admit(st, 2); inseq_admit(st, 3)
    expect(inseq_is_dup(st, 2)).toBe(true)
    expect(inseq_admit(st, 2)).toEqual([])                  // re-sent 2 → dropped, no re-dispatch
})

// the integration: an adversarial carrier dups + reorders; inseq must reconstruct the clean stream.
test('carrier dup+reorder → inseq reconstructs the in-order, deduped stream', () => {
    const landed: number[] = []
    const inbox = inseq_new()
    const real = { recv: (f: any) => { for (const s of inseq_admit(inbox, Number(f.header.seq))) landed.push(s) } }
    const lossy = make_lossy_partner(real, { dup: [2], delay: { 3: 1 } })   // 2 arrives twice, 3 held past 4
    for (const seq of [1, 2, 3, 4]) lossy.recv({ header: { seq } })
    lossy.tick()                                            // release the delayed 3
    expect(landed).toEqual([1, 2, 3, 4])                    // dup collapsed, reorder healed
})
