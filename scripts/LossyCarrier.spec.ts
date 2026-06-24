// LossyCarrier — headless proof that the adversarial carrier (src/lib/O/peeroleum_lossy.ts) is
//  deterministic: a seeded drop/dup/delay schedule produces an identical delivery trace every run.
//   This is pure logic (no Creduler / no :9091), so it's a real regression gate — the foundation the
//    spine reliability builds (inbound seq discipline → retransmit) will be tested THROUGH.
//   Run: node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/LossyCarrier.spec.ts
import { test, expect } from 'vitest'
import { lossy_decide, make_lossy_partner, type LossySchedule } from '$lib/O/peeroleum_lossy'

// drive `seqs` through a lossy partner, then `ticks` logical beats; return what arrived, in order.
function run(schedule: LossySchedule, seqs: number[], ticks = 0): number[] {
    const arrived: number[] = []
    const real = { recv: (f: any) => arrived.push(Number(f.header.seq)) }
    const lossy = make_lossy_partner(real, schedule)
    for (const seq of seqs) lossy.recv({ header: { seq } })
    for (let i = 0; i < ticks; i++) lossy.tick()
    return arrived
}

test('lossy_decide: precedence drop > dup > delay', () => {
    const s: LossySchedule = { drop: [3], dup: [3, 5], delay: { 3: 2, 7: 1 } }
    expect(lossy_decide(s, 3)).toBe('drop')           // listed thrice — drop wins, unambiguous
    expect(lossy_decide(s, 5)).toBe('dup')
    expect(lossy_decide(s, 7)).toEqual({ delay: 1 })
    expect(lossy_decide(s, 9)).toBe('pass')
})

test('drop: a dropped seq never arrives (the retransmit trigger)', () => {
    expect(run({ drop: [3] }, [1, 2, 3, 4, 5])).toEqual([1, 2, 4, 5])
})

test('dup: a duplicated seq arrives twice (the dedup target)', () => {
    expect(run({ dup: [2] }, [1, 2, 3])).toEqual([1, 2, 2, 3])
})

test('delay/reorder: seq 2 held past 3 lands after it', () => {
    expect(run({ delay: { 2: 2 } }, [1, 2, 3], /* ticks */ 2)).toEqual([1, 3, 2])
})

test('deterministic: same schedule → identical trace, twice', () => {
    const s: LossySchedule = { drop: [2], dup: [4], delay: { 5: 1 } }
    expect(run(s, [1, 2, 3, 4, 5], 1)).toEqual(run(s, [1, 2, 3, 4, 5], 1))
})
