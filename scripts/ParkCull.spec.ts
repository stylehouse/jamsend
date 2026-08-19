// ParkCull — THE ASK IS THE LEASE (2026-08-14, Daemon_todo §11 — the immortal wants).
//
//  WHY THIS FILE EXISTS: a %parked_want used to be removed ONLY by being served, and on the daemon —
//   the first process here with no page lifetime — four of them (askers gone, recs off the shelf)
//    barked the L3 stall every 10s for six hours and cost pump/admission work on every pass, forever.
//     No Book can cover this: a Book's world quiesces and its piers never abandon anything; the leak
//      IS the abandonment, and only a unit test can manufacture one.
//
//  THE CLAIMS, each of which must be able to go red (mutation-test-every-claim):
//   1. a want whose lease lapsed is CULLED by the pump — remove the cull, this goes red.
//   2. a want asked recently SURVIVES — invert the cull condition, this goes red.
//   3. a re-ask REFRESHES the lease (Repli_park_want stamps asked_at OUTSIDE the !counted latch) —
//       move the stamp inside the latch and this goes red.
//   4. EVERY abandoned offset goes, not just the first per id — the cull sits BEFORE the seen-dedup;
//       swap them and this goes red.
//   5. a configured leash of 0 is honoured (the `== null` idiom, not `||`) — regress to `||` and
//       this goes red.
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/ParkCull.spec.ts
import { test, expect } from 'vitest'
import { mount } from 'svelte'
import { TheC } from '../src/lib/data/Stuff.svelte'
import Ra from '../src/lib/gen/M/Ra.go'
import Repli from '../src/lib/gen/N/Repli.go'

const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))

// The HeistUnity stub-House pattern: a real TheC wearing eatfunc/top_House, so the mounted .go's
//  verbs land and the pier tree is real particles with real o()/rm(). Peeroleum is NOT mounted —
//   Repli_park_want's park-reply frame needs its send seam, so those three verbs are stubbed inert.
async function stub_house() {
    const H: any = new TheC({ c: {}, sc: { H: 'Mundo' } })
    H.eatfunc = async (obj: any) => { Object.assign(H, obj) }
    H.top_House = () => H
    H.mainkey = (n: any) => Object.keys(n.sc)[0]
    H.Radio_trace = () => {}
    H.Pier_next_seq = () => 1
    H.Peeroleum_body_digest = async () => 'x'
    H.Peeroleum_send = () => {}
    for (const Ghost of [Ra, Repli]) mount(Ghost, { target: document.body, props: { H } })
    for (let i = 0; i < 80 && !(typeof H.Ra_transcode_pump === 'function'
        && typeof H.Repli_park_want === 'function'); i++) await sleep(25)
    expect(typeof H.Ra_transcode_pump, 'Ra.go deposited').toBe('function')
    expect(typeof H.Repli_park_want, 'Repli.go deposited').toBe('function')
    return H
}

function world_with_pier(H: any) {
    const w = H.i({ w: 'Swarm' }); w.c.up = H
    const pier = w.i({ Pier: 1, pub: 'sinkpub' }); pier.c.up = w
    w.c.tx = pier
    return { w, pier }
}

const ask = (H: any, w: any, pier: any, id: string, from_idx: number) =>
    H.Repli_park_want(w, pier, { id, stream: 'radio', from_idx, from: 'sinkaddr', to: 'mypub' })

const wants = (pier: any) => pier.o({ parked_want: 1 })

test('a want whose lease lapsed is culled; a fresh one survives', async () => {
    const H = await stub_house()
    const { w, pier } = world_with_pier(H)
    await ask(H, w, pier, 'dead1', 64)
    await ask(H, w, pier, 'alive', 12)
    expect(wants(pier).length).toBe(2)
    const dead = wants(pier).find((p: any) => p.sc.id === 'dead1')
    dead.c.asked_at = Date.now() - 100000            // past the 90s default leash
    dead.c.parked_at = Date.now() - 100000
    await H.Ra_transcode_pump(w)
    const left = wants(pier)
    expect(left.length, 'abandoned want culled, fresh want kept').toBe(1)
    expect(left[0].sc.id).toBe('alive')
})

test('a re-ask refreshes the lease even on an already-counted want', async () => {
    const H = await stub_house()
    const { w, pier } = world_with_pier(H)
    await ask(H, w, pier, 'track', 30)
    const p = wants(pier)[0]
    p.c.asked_at = Date.now() - 100000               // lapsed…
    await ask(H, w, pier, 'track', 30)               // …but the sink re-asks (same particle, oai)
    expect(wants(pier).length, 're-ask landed on the one particle').toBe(1)
    await H.Ra_transcode_pump(w)
    expect(wants(pier).length, 'refreshed lease keeps the want').toBe(1)
})

test('every abandoned offset of one id is culled, not just the first', async () => {
    const H = await stub_house()
    const { w, pier } = world_with_pier(H)
    await ask(H, w, pier, 'same', 10)
    await ask(H, w, pier, 'same', 12)
    expect(wants(pier).length).toBe(2)
    for (const p of wants(pier)) { p.c.asked_at = Date.now() - 100000; p.c.parked_at = Date.now() - 100000 }
    await H.Ra_transcode_pump(w)
    expect(wants(pier).length, 'cull runs before the per-id seen dedup').toBe(0)
})

test('a configured leash of 0 is honoured — the == null idiom, not ||', async () => {
    const H = await stub_house()
    const { w, pier } = world_with_pier(H)
    w.c.repli_want_leash = 0
    await ask(H, w, pier, 'snappy', 5)
    wants(pier)[0].c.asked_at = Date.now() - 1000    // 1s old — inside the 90s default, outside 0
    await H.Ra_transcode_pump(w)
    expect(wants(pier).length, 'leash 0 culls what || 90000 would keep').toBe(0)
})
