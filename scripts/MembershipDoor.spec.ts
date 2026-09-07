// MembershipDoor — UNIT TESTS FOR `Swarm_pier_retired` / `Swarm_peers`, with no runner and no world.
//
//  WHY THIS FILE EXISTS.  The membership door (Social_demarcation_todo §2.0) decides which peers the
//   rest of the app can see, and it got built on a day when NO runner tab was booted — so the Books
//    that would gate it could not run at all.  The door is PURE LOGIC over particle children, which
//     means it does not need a runner, a peer, a wire or a clock: exactly the shape SupplyGuards.spec
//      exists to catch, and its preamble already names this bottleneck ("all busy or the human's own
//       music tabs").  Same trick here — mount the real compiled Swarm.go on a stub House and call the
//        verbs directly.  This is also the frontier claim in miniature (§7): the predicate is drilled
//         against fixture particles with NO social world standing at all.
//
//  WHAT THIS IS NOT: a substitute for the ceremony Books.  Nothing here proves `Swarm_station_routes`
//   actually stops routing a retired pier, or that the Door face hides one — those are wiring claims
//    and they belong to SwarmStaple / SwarmInvite / InvWalk / SwarmDoor.  Read a green here as "the
//     predicate says what it means", never as "the membership sweep works".
//
//  THE CLAIM UNDER TEST, and the reason it is worth a file: RETIRED IS NOT "NOT LIVE".  A %Pier with
//   no live grant is either NASCENT (mid-seal, grants not landed — it still needs a route, or the
//    handshake can never complete) or RETIRED (a %NotGrant stands, or a link was unlinked).  §2.1 of
//     the doc originally proposed "default ⇒ live only", which would have filtered out every nascent
//      pier and wedged new friendships SILENTLY.  The tests below pin the distinction so nobody
//       "simplifies" it back.
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/MembershipDoor.spec.ts
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
    for (let i = 0; i < 80 && typeof H.Swarm_pier_retired !== 'function'; i++) await sleep(25)
    return H
}

// An identity with a %Peering, the shape Swarm_peering(ident) walks.  Real TheC so `o()`/`i()` are
//  the genuine query primitives — a hand-rolled fake would prove nothing about the real matcher.
function ident_with(piers: Array<(p: any) => void>) {
    const ident: any = new TheC({ c: {}, sc: { Identity: 'me', prepub: 'me' } })
    const peering = ident.i({ Peering: 1, name: 'me' })
    peering.c.up = ident
    for (const build of piers) {
        const pier = peering.i({ Pier: 1, pub: 'p' + Math.random().toString(16).slice(2, 8) })
        pier.c.up = peering
        build(pier)
    }
    return ident
}

// the two halves of a grant pair, as Swarm_pier_live compares them: a %NotGrant revokes a %Grant only
//  when BOTH `by` and `for` match, so a revocation aimed elsewhere must not retire this bond.
const grant = (p: any, feature: string, by = 'them', to = 'me') => p.i({ Grant: feature, by, for: to })
const notgrant = (p: any, feature: string, by = 'them', to = 'me') => p.i({ NotGrant: feature, by, for: to })

test('a NASCENT pier — no grants, no revocations — is NOT retired (the wedge §2.1 would have caused)', async () => {
    const H = await stub_house()
    const ident = ident_with([() => {}])
    const [p] = H.Swarm_peering(ident).o({ Pier: 1 })
    // it is not live for anything...
    expect(H.Swarm_pier_live(p, 'Music')).toBe(false)
    // ...and that is precisely NOT evidence of retirement.  A pier mid-seal must keep its route.
    expect(H.Swarm_pier_retired(p)).toBe(false)
    expect(H.Swarm_peers(ident).length).toBe(1)
})

test('a live Music pier is not retired; revoke it and it is', async () => {
    const H = await stub_house()
    const ident = ident_with([(p: any) => grant(p, 'Music')])
    const [p] = H.Swarm_peering(ident).o({ Pier: 1 })
    expect(H.Swarm_pier_retired(p)).toBe(false)
    notgrant(p, 'Music')
    expect(H.Swarm_pier_live(p, 'Music')).toBe(false)
    expect(H.Swarm_pier_retired(p)).toBe(true)
    expect(H.Swarm_peers(ident).length).toBe(0)
    expect(H.Swarm_peers(ident, { live: 'all' }).length).toBe(1)   // the ledger keeps it — §2.2
})

test('RETIRED MEANS NOTHING STANDS — a Music revoke does not retire a pier still granted Crew', async () => {
    const H = await stub_house()
    const ident = ident_with([(p: any) => { grant(p, 'Music'); grant(p, 'Crew'); notgrant(p, 'Music') }])
    const [p] = H.Swarm_peering(ident).o({ Pier: 1 })
    expect(H.Swarm_pier_live(p, 'Music')).toBe(false)
    expect(H.Swarm_pier_live(p, 'Crew')).toBe(true)
    expect(H.Swarm_pier_retired(p)).toBe(false)
    // ...but it is no longer a MUSIC peer, and a caller that means music must say so.
    expect(H.Swarm_peers(ident).length).toBe(1)
    expect(H.Swarm_peers(ident, { live: 'Music' }).length).toBe(0)
})

test('a MyCaptain link rail is live — the Door used to hide it (the two-feature bug)', async () => {
    const H = await stub_house()
    // DoorFace tested only Music|MyCave, so a Cave that adopted a Captain read as retired and vanished.
    const ident = ident_with([(p: any) => grant(p, 'MyCaptain')])
    const [p] = H.Swarm_peering(ident).o({ Pier: 1 })
    expect(H.Swarm_pier_linklive(p)).toBe(true)
    expect(H.Swarm_pier_retired(p)).toBe(false)
    expect(H.Swarm_peers(ident).length).toBe(1)
})

test('an unlinked link stamp retires on its own evidence — no grant needed', async () => {
    const H = await stub_house()
    const ident = ident_with([(p: any) => { p.sc.link = 1 }])
    const [p] = H.Swarm_peering(ident).o({ Pier: 1 })
    expect(H.Swarm_pier_retired(p)).toBe(false)      // a standing chrysalis is a live rail
    p.sc.unlinked = 1
    expect(H.Swarm_pier_retired(p)).toBe(true)       // the human ended it; that IS the evidence
})

test('a revocation aimed at ANOTHER pair does not retire this bond', async () => {
    const H = await stub_house()
    const ident = ident_with([(p: any) => { grant(p, 'Music', 'them'); notgrant(p, 'Music', 'somebody_else') }])
    const [p] = H.Swarm_peering(ident).o({ Pier: 1 })
    expect(H.Swarm_pier_live(p, 'Music')).toBe(true)
    expect(H.Swarm_pier_retired(p)).toBe(false)
})

test('Swarm_peers answers FOUR questions, and never returns null', async () => {
    const H = await stub_house()
    const ident = ident_with([
        (p: any) => grant(p, 'Music'),                                   // live music friend
        (p: any) => {},                                                  // nascent, mid-seal
        (p: any) => { grant(p, 'Music'); notgrant(p, 'Music') },          // retired
        (p: any) => grant(p, 'Crew'),                                    // crew, no music
    ])
    expect(H.Swarm_peers(ident).length).toBe(3)                          // not-retired: live + nascent
    expect(H.Swarm_peers(ident, { live: 'Music' }).length).toBe(1)       // granted for the feature
    // GRANTED FOR ANYTHING — the fourth question, and the one that used to fall through to the default.
    //  It is not the default: a nascent pier is not yet an actual friend, so it drops out here and only
    //   here. Music friend + Crew mate = 2; the nascent and the retired both fail.
    expect(H.Swarm_peers(ident, { live: true }).length).toBe(2)
    expect(H.Swarm_peers(ident, { live: 'all' }).length).toBe(4)         // the ledger, history and all
    // an identity with no Peering at all is a legal question to ask, and the answer is an ARRAY —
    //  every caller iterates the result directly, so a null here would be a crash at 100 call sites.
    expect(H.Swarm_peers(new TheC({ c: {}, sc: { Identity: 'bare' } }))).toEqual([])
    expect(H.Swarm_peers(null)).toEqual([])
})
