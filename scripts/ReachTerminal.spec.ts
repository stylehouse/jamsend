// ReachTerminal — UNIT TESTS FOR THE REACH LIFECYCLE'S TERMINAL STATES, with no runner and no wire.
//
//  WHY THIS FILE EXISTS.  A %Reach is the standing intent — "I need this from that body" — and its
//   lifecycle is `booked → dispatched → serving → arrived → landed`, with `refused | dead` as the two
//    terminals.  Until 2026-09-06 the terminals barely existed, and the cost was measured live on eed:
//
//      · a closed Incognito window was still the crew Cave, so every reach addressed to it was
//         re-dispatched forever.  A reach to a body that will NEVER answer read, in a snap, exactly like
//          a reach to a peer that is merely slow — the ledger could not tell "gone" from "quiet".
//      · the 32-reach cap counted those corpses.  eed sat at 32/32 with 6 dead and 5 refused among them,
//         so every NEW booking was refused while a third of the shelf was receipts nobody would act on.
//          A cap that counts finished work is not backpressure; it is a permanent refusal to ask anyone
//           anything.  (Social_demarcation_todo §4.1; SoundPooling_todo §0 faults 2 and 4.)
//
//  All three repairs are pure logic over particles — no wire, no clock, no peer — so they gate here.
//   The Books that would cover the WIRING (does a dead reach really stop being re-sent on a live relay?)
//    are SwarmBody and the pool set, and those need a runner; this does not.
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/ReachTerminal.spec.ts
import { test, expect } from 'vitest'
import { mount } from 'svelte'
import { TheC } from '../src/lib/data/Stuff.svelte'
import Swarm from '../src/lib/gen/S/Swarm.go'

const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))

async function stub_house() {
    const H: any = {
        c: {},
        sc: {},
        async eatfunc(obj: any) { Object.assign(H, obj) },
        top_House() { return H },
    }
    mount(Swarm, { target: document.body, props: { H } })
    for (let i = 0; i < 80 && typeof H.Swarm_reach_book !== 'function'; i++) await sleep(25)
    return H
}

// an identity carrying a %Peering — the Crew locality a reach lives on, beside %Body/%Pier.
function ident_of(prepub = 'me') {
    const ident: any = new TheC({ c: {}, sc: { Identity: prepub, prepub } })
    const peering = ident.i({ Peering: 1, name: prepub })
    peering.c.up = ident
    return ident
}
const peering_of = (H: any, ident: any) => H.Swarm_peering(ident)

function pier(H: any, ident: any, pub: string, grants: string[] = []) {
    const p = peering_of(H, ident).i({ Pier: 1, pub })
    p.c.up = peering_of(H, ident)
    for (const g of grants) p.i({ Grant: g, by: 'them', for: 'me' })
    return p
}
// a world with no station: the WIRE is gated off, so dispatch resolves and returns purely (Book-inert).
const world = () => new TheC({ c: {}, sc: { w: 'Reach' } }) as any

test('a reach to a body with NO crew row and NO live grant is GONE — the 36-hour ghost', async () => {
    const H = await stub_house()
    const ident = ident_of()
    pier(H, ident, 'deadbody')                                  // a %Pier with no grant at all
    const reach: any = { sc: { Reach: 1, to: 'deadbody', of: 'trk', for: 'serve' } }
    expect(H.Swarm_reach_target_gone(ident, reach)).toBe(1)
})

test('…but a LIVE grant keeps it alive, and so does any crew body — never presence, always the ledger', async () => {
    const H = await stub_house()
    const ident = ident_of()
    pier(H, ident, 'musicfriend', ['Music'])
    pier(H, ident, 'crewmate', ['Crew'])
    pier(H, ident, 'mycave', ['MyCave'])
    for (const to of ['musicfriend', 'crewmate', 'mycave']) {
        expect(H.Swarm_reach_target_gone(ident, { sc: { Reach: 1, to, for: 'serve' } })).toBe(0)
    }
    // DELIBERATELY LEDGER-BASED, NEVER PRESENCE-BASED: a friend who is merely offline is not gone. If this
    //  ever consults heard_at, a quiet friend's reaches start dying and the bug inverts.
    const p = peering_of(H, ident).o({ Pier: 1, pub: 'musicfriend' })[0]
    p.c.heard_at = 0
    expect(H.Swarm_reach_target_gone(ident, { sc: { Reach: 1, to: 'musicfriend', for: 'serve' } })).toBe(0)
})

test('a target nothing vouches for IS gone — and that is how a DELETED pier kills its reaches', async () => {
    const H = await stub_house()
    const ident = ident_of()
    pier(H, ident, 'someone', ['Music'])
    // `to` matches no pier and no crew body, so nothing in the ledger vouches for it ⇒ gone. This is not
    //  an edge case, it is the MAIN case: ejecting the dead Cave from the Door removed its row, and that
    //   absence is what finally let its reaches die. (An ejected body is exactly "no row vouches for it".)
    expect(H.Swarm_reach_target_gone(ident, { sc: { Reach: 1, to: 'never-met', for: 'serve' } })).toBe(1)

    // TWO NON-ANSWERS, deliberately 0 rather than 1: an EMPTY `to` and a missing reach are malformed
    //  questions, not dead targets. Answering "gone" to a malformed reach would let a booking bug quietly
    //   mark healthy intents dead — so the predicate declines to judge instead of guessing.
    expect(H.Swarm_reach_target_gone(ident, { sc: { Reach: 1, to: '', for: 'serve' } })).toBe(0)
    expect(H.Swarm_reach_target_gone(ident, null)).toBe(0)
})

test('A SETTLED REACH NEVER RE-DISPATCHES — arrived, refused and dead all stand still', async () => {
    const H = await stub_house()
    const w = world()
    const ident = ident_of()
    // the guard used to test `=== 'arrived'` alone, so a 'refused' reach re-sent every pass and flipped
    //  itself back to 'dispatched' — dodging its own receipt sweep, forever.
    for (const st of ['arrived', 'refused', 'dead']) {
        const r: any = { sc: { Reach: 1, to: 'somebody', for: 'serve', state: st } }
        expect(H.Swarm_reach_dispatch(w, ident, r)).toBe(null)
        expect(String(r.sc.state)).toBe(st)                     // and it was not mutated on the way out
    }
    // a STANDING reach still resolves (the wire is station-gated off, so this is the pure routing answer).
    const live: any = { sc: { Reach: 1, to: 'somebody', for: 'serve', state: 'booked' } }
    expect(H.Swarm_reach_dispatch(w, ident, live)).toBe('somebody')
})

test('THE CAP COUNTS STANDING WORK, NOT RECEIPTS — a shelf of corpses must not refuse new bookings', async () => {
    const H = await stub_house()
    const w = world()
    w.c.reach_cap = 3
    const ident = ident_of()
    const peering = peering_of(H, ident)
    // three terminal rows: exactly the shape that had eed refusing every booking at 32/32.
    for (const [i, st] of ['dead', 'refused', 'dead'].entries()) {
        const r = peering.i({ Reach: 1, to: 'gone' + i, of: 'o' + i, for: 'serve', state: st })
        r.c.up = peering
    }
    expect(peering.o({ Reach: 1 }).length).toBe(3)              // the shelf is "full" by the old count
    const booked = H.Swarm_reach_book(w, ident, { to: 'alive', of: 'fresh', for: 'serve' })
    expect(booked).toBeTruthy()                                 // …and a new intent is still admitted
    expect(String(booked.sc.state || 'booked')).toBeTruthy()

    // the cap is REAL, though: three STANDING reaches do refuse the fourth.
    const id2 = ident_of('other')
    const pr2 = peering_of(H, id2)
    for (let i = 0; i < 3; i++) {
        const r = pr2.i({ Reach: 1, to: 't' + i, of: 'o' + i, for: 'serve', state: 'dispatched' })
        r.c.up = pr2
    }
    expect(H.Swarm_reach_book(w, id2, { to: 'nope', of: 'x', for: 'serve' })).toBe(null)
    // …and re-booking something ALREADY standing is always honoured, cap or no cap (idempotent).
    expect(H.Swarm_reach_book(w, id2, { to: 't0', of: 'o0', for: 'serve' })).toBeTruthy()
})
