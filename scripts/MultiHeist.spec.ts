// MultiHeist — UNIT TESTS FOR THE MULTIPLE-HEISTS CUT AND THE WHAT-HEISTED LEDGER (2026-08-13).
//
//  THE ASK BEHIND ALL OF IT (the owner, morning): *"we also need to make multiple Heists doable, I can't
//   be hanging around waiting for each one in fullscreen"*.  The ENGINE already did it — every standing
//    keep is walked per beat, one track in flight globally, oldest first.  The GLASS forbade it: any open
//     keep owned the belly, and pressing Radio or Door cancelled it.  So the cut is almost entirely about
//      focus and about what a press MEANS, which is exactly the kind of thing that is easy to get subtly
//       backwards and hard to notice — nothing crashes, the app just does the wrong thing quietly.
//
//  THE RULINGS PINNED HERE, each one a decision that could plausibly have gone the other way:
//   1. WANDERING AWAY STARTS A HEIST, it does not cancel it (the owner's Q1: *"nah I think we make the
//       Cancel prominent, and auto-Start them when wandered away from"*).  The old behaviour was cancel.
//        A regression here silently throws away setup the human meant to keep.
//   2. `focused_keep` AND `focused` ARE MUTUALLY EXCLUSIVE.  `focused_keep` outranks `focused` on the
//       belly ladder — it has to, or pressing a heist bud would be outranked by whatever you last
//        pressed — so naming an organ MUST release the pin, or pressing the Radio while a heist holds
//         the belly does nothing and reads as a broken button.
//   3. A HEIST BUD IS ADDRESSED BY PARTICLE, NOT BY MAINKEY.  All %Heists share a mainkey, so `focused`
//       (a key) cannot name one of three.  That is why a second field exists at all.
//
//  AND THE LEDGER: `%Hauls` is a dontSnap MIRROR of the newlyadded probation log, not a second store of
//   the truth — the doc claimed the What-Heisted ledger was unbuilt while that log had been recording it
//    for weeks.  What is testable here is the read side: newest-first, and a pure read that cannot mint.
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/MultiHeist.spec.ts
import { test, expect } from 'vitest'
import { mount } from 'svelte'
import { TheC } from '../src/lib/data/Stuff.svelte'
import Heist from '../src/lib/gen/M/Heist.go'
import Sounditron from '../src/lib/gen/Story/Sounditron.go'

const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))

// The commission is the thing under test's SIDE EFFECT, not the thing under test — it walks a whole
//  glass and wants a world this spec has no business building.  Stub it and COUNT it: "did the press
//   ask for a re-commission" is the actual claim (a focus change that does not re-commission leaves the
//    old belly on screen, which is the bug, not a slow render).
async function stub_house() {
    const H: any = new TheC({ c: {}, sc: { H: 'Mundo' } })
    H.eatfunc = async (obj: any) => { Object.assign(H, obj) }
    H.top_House = () => H
    H.Radio_trace = () => {}
    H.mainkey = (n: any) => Object.keys(n.sc)[0]
    H.c.humdinger = 1
    for (const Ghost of [Heist, Sounditron]) mount(Ghost, { target: document.body, props: { H } })
    for (let i = 0; i < 80 && !(typeof H.Sounditron_focus_keep === 'function'
        && typeof H.Heist_keep_start === 'function'
        && typeof H.Heist_haul_rows === 'function'); i++) await sleep(25)
    H.commissions = 0
    H.ponders = 0
    H.Sounditron_commission = () => { H.commissions++ }
    H.feebly_ponder = () => { H.ponders++ }
    return H
}

const world = () => new TheC({ c: {}, sc: { w: 'Radio' } }) as any

function shopWith(...seeds: string[]) {
    const shop: any = new TheC({ c: {}, sc: { Shop: 1 } })
    const keeps = seeds.map(s => { const k = shop.i({ Heist: s, seed: s, pub: 'them', state: 'primed' }); k.c.up = shop; return k })
    return { shop, keeps }
}

// ── RULING 2 + 3: THE TWO FOCUS FIELDS ─────────────────────────────────────────────────────────────
test('a heist bud is pinned by PARTICLE, and naming an organ releases the pin', async () => {
    const H = await stub_house()
    const w = world()
    const { keeps } = shopWith('A', 'B', 'C')

    // three heists share one mainkey, so `focused` — a KEY — could not have named one of them. This is
    //  the whole reason `focused_keep` exists, and it holds the particle itself.
    expect(H.Sounditron_focus_keep(w, keeps[1])).toBe(1)
    expect(w.c.focused_keep).toBe(keeps[1])
    expect('focused' in w.c).toBe(false)
    expect(H.commissions).toBe(1)
    expect(H.ponders).toBe(1)

    // …and pressing the Radio must RELEASE it. `focused_keep` outranks `focused` on the belly ladder, so
    //  without the release this press would set `focused`, be outranked, and read as a dead button.
    expect(H.Sounditron_focus_to(w, 'Radio')).toBe(1)
    expect(w.c.focused).toBe('Radio')
    expect(w.c.focused_keep).toBeUndefined()
    expect(H.commissions).toBe(2)

    // pinning again releases the organ, symmetrically — the two are one either/or, not two latches that
    //  can both be set and fight over the belly.
    H.Sounditron_focus_keep(w, keeps[2])
    expect(w.c.focused_keep).toBe(keeps[2])
    expect('focused' in w.c).toBe(false)

    // a press with nothing behind it is a no-op, not a state change: an empty key must not blank the pin.
    expect(H.Sounditron_focus_to(w, '')).toBe(0)
    expect(H.Sounditron_focus_keep(w, null)).toBe(0)
    expect(w.c.focused_keep).toBe(keeps[2])
    expect(H.commissions).toBe(3)
})

test('pinning a keep TOUCHES it, so the belly ladder and the dose agree about which one is live', async () => {
    const H = await stub_house()
    const w = world()
    const { keeps } = shopWith('A', 'B')
    keeps[0].c.last_touch = 1000
    keeps[1].c.last_touch = 2000

    H.Sounditron_focus_keep(w, keeps[0])
    // Heist_keep_step space-favours the most recently touched sibling. If the pin did not touch, the
    //  glass would show one keep in the belly while the ghost dosed a DIFFERENT one up — two subsystems
    //   disagreeing about the same word, which is how "fussy" happens.
    expect(+keeps[0].c.last_touch).toBeGreaterThan(+keeps[1].c.last_touch)
})

// ── RULING 1: WANDERING AWAY STARTS IT ─────────────────────────────────────────────────────────────
test('leaving an unstarted heist STARTS it — it does not cancel it (the owner\'s Q1)', async () => {
    const H = await stub_house()
    const w = world()
    const { keeps } = shopWith('A')
    const keep = keeps[0]
    expect(keep.sc.state).toBe('primed')

    expect(H.Sounditron_leave_keep(w, 'Radio', keep)).toBe(1)
    // THE RULING. The old behaviour was cancel, and a regression here silently throws away a setup the
    //  human meant to keep — no error, no trace, just a heist that never happened.
    expect(keep.sc.state).toBe('pulling')
    expect(w.c.focused).toBe('Radio')
    expect(w.c.focused_keep).toBeUndefined()

    // …and leaving with no form in the belly is just a focus change: nothing to start, nothing to lose.
    const before = keep.sc.state
    expect(H.Sounditron_leave_keep(w, 'Door', null)).toBe(1)
    expect(w.c.focused).toBe('Door')
    expect(keep.sc.state).toBe(before)
})

test('a started heist is not re-started by leaving it again', async () => {
    const H = await stub_house()
    const w = world()
    const { keeps } = shopWith('A')
    const keep = keeps[0]
    H.Heist_keep_start(keep)
    expect(keep.sc.state).toBe('pulling')
    const v = keep.version

    H.Sounditron_leave_keep(w, 'Radio', keep)
    // idempotent: the belly only ever hands `Heist_keep_start` the keep when it is still a FORM, but the
    //  verb must not churn a running heist's version even if it is handed one — a bump is a re-render for
    //   every face watching, on every wander, for nothing.
    expect(keep.sc.state).toBe('pulling')
    expect(keep.version).toBe(v)
})

// ── THE LEDGER'S READ SIDE ─────────────────────────────────────────────────────────────────────────
test('Heist_haul_rows is newest-first and CANNOT mint — a reader that creates is a writer', async () => {
    const H = await stub_house()
    const w = world()

    // no bag yet: an empty read, and — the load-bearing half — no bag conjured by asking. A reader built
    //  on `oai` mints by being asked, and a face runs its reader every pass, so it would grow the very
    //   thing it reports on. `%Hauls` is minted by the beat and by nothing else.
    expect(H.Heist_haul_rows(w)).toEqual([])
    expect(w.o({ Hauls: 1 }).length).toBe(0)

    const bag = w.i({ Hauls: 1, dontSnap: 1 })
    bag.i({ Haul: 1, dir: 'old', at: 100, tracks: 3 })
    bag.i({ Haul: 1, dir: 'newest', at: 300, tracks: 1 })
    bag.i({ Haul: 1, dir: 'middle', at: 200, tracks: 9 })

    expect(H.Heist_haul_rows(w).map((r: any) => String(r.sc.dir))).toEqual(['newest', 'middle', 'old'])
    // a row with no `at` sorts last rather than throwing the order — an undated album is the least
    //  interesting thing on a "what did I just get" list, not a reason for the list to be wrong.
    bag.i({ Haul: 1, dir: 'undated', tracks: 2 })
    expect(H.Heist_haul_rows(w)[3].sc.dir).toBe('undated')
})
