// SendTo — prove the Engage_integration C2 primitive ROUTES.  Peeroleum_send_to picks the Pier by
//  %pub (not [0]), so an editor holding N runner Piers under its one Peering can address ONE runner.
//   No Story Book exercises this: the co-resident swarm runs ONE Pier per Peering, so Peeroleum_route's
//    pub-select takes the length===1 shortcut and the .find branch never fires.  This stands up the
//     PRODUCTION topology (one Peering, two Piers) headless and asserts the addressed send books on the
//      right Pier alone — plus Lies_runner_pier's find-or-promote.  Spine is Creduler-acquired (mirror
//       CredulerProbe), so the gen N/Peeroleum.go LocalGen just wrote is what runs.
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/SendTo.spec.ts
import { test, expect } from 'vitest'
import { mount, flushSync } from 'svelte'
import Runner from './Story_cli_runner.svelte'
import { NodeWormholeNav } from './NodeWormholeNav'
import { rmSync } from 'node:fs'

const ROOT  = process.cwd()
const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))
const allHouses = (H: any): any[] => { const out=[H]; const w=(h:any)=>{for(const s of (h.o?.({H:1})??[])) if(!out.includes(s)){out.push(s);w(s)}}; w(H); return out }

const OVERLAY = '/tmp/SendTo_fs'
try { rmSync(OVERLAY, { recursive: true, force: true }) } catch {}
const nodeNav = new NodeWormholeNav(ROOT, OVERLAY, false)

test('C2 send_to routes by pub + runner_pier promotes; C1 favoured-runner lookup', async () => {
    let H: any
    mount(Runner, { target: document.body, props: { onhouse: (h: any) => { H = h } } })
    for (let i = 0; i < 40 && !(H && typeof H.Creduler_ensure === 'function'); i++) await sleep(50)
    expect(typeof H?.Creduler_ensure, 'Lies ghost deposited (shell booted)').toBe('function')

    const WA = H.i({ A: 'Wormhole' }); WA.i({ w: 'Wormhole' }); WA.c.nav = nodeNav
    const liesW = H.i({ A: 'Lies' }).i({ w: 'Lies', runner: 1, creduler: 1 })
    const drain = async () => { for (const h of allHouses(H)) { let g=0; while (h.todo?.length && h.started && g++<300) { try { await h._really_answer_calls() } catch {} } } }

    for (let t = 0; t < 160 && typeof H.Peeroleum_send_to !== 'function'; t++) {
        for (const h of allHouses(H)) if (!h.started) h.started = true
        try { await H.Creduler_ensure(liesW) } catch {}
        flushSync()
        for (const h of allHouses(H)) h.i_elvisto?.(h, 'think')
        await drain(); flushSync()
        await sleep(60)
    }
    expect(typeof H.Peeroleum_send_to, 'Peeroleum spine acquired (send_to live)').toBe('function')

    // PRODUCTION topology: one Peering (a single identity), two Piers (two runners on the grid).
    const tw = H.i({ A: 'SendTo' }).i({ w: 'SendTo' })
    const peering = tw.oai({ Peering: 1, name: 'editor' }); peering.c.up = tw
    const pa = peering.oai({ Pier: 1, pub: 'AAA' }); pa.c.up = peering
    const pb = peering.oai({ Pier: 1, pub: 'BBB' }); pb.c.up = peering

    // address Pier B — the emit + seq must land on B, A untouched.
    const seq = H.Peeroleum_send_to(tw, 'BBB', 'become_book', { book: 'X' })
    expect(seq, 'returned B-seq').toBe(1)
    expect(pb.c.seq, 'B seq advanced').toBe(1)
    expect(pa.c.seq ?? 0, 'A seq untouched').toBe(0)
    const emitsB = pb.o({ outbox: 1 })[0]?.o({ emit: 1 }) ?? []
    const emitsA = pa.o({ outbox: 1 })[0]?.o({ emit: 1 }) ?? []
    expect(emitsB.length, 'emit booked on B').toBe(1)
    expect(emitsA.length, 'no emit on A').toBe(0)

    // absent pub → undefined (the "no such runner — say so" path).
    expect(H.Peeroleum_send_to(tw, 'ZZZ', 'become_book', { book: 'X' }), 'unknown pub → undefined').toBeUndefined()

    // Lies_runner_pier — find-or-PROMOTE: a fresh pub mints a Pier (Ud-stamped, c.up wired); idempotent.
    const promoted = H.Lies_runner_pier(tw, 'CCC')
    expect(promoted?.sc?.pub, 'promoted Pier keyed by pub').toBe('CCC')
    expect(!!promoted?.oa?.({ Ud: 1 }), 'Ud stamped (trust-everything v1)').toBe(true)
    expect(promoted?.c?.up, 'c.up wired to the Peering').toBe(peering)
    expect(H.Lies_runner_pier(tw, 'CCC'), 'idempotent — same Pier on re-call').toBe(promoted)
    expect(H.Lies_runner_pier(tw, 'BBB'), 'finds the pre-existing B').toBe(pb)

    // C1 lookup — Waft:Cluster/%HostedIdentity registry: a client finds the runner that favours it.
    //  No frame, no receiver — favourite_client is a property the lookup reads (advertise_recv mirrors
    //   it off the beacon; here we set it directly).  Lies_favoured_runner returns the to:<prepub> target.
    const cl = tw.oai({ Waft: 'Cluster' })
    ;(cl.oai({ HostedIdentity: 'RUNX' }) as any).sc.favourite_client = 'CLIENTY'
    cl.oai({ HostedIdentity: 'RUNZ' })   // unclaimed — favours nobody
    expect(H.Lies_favoured_runner(tw, 'CLIENTY'), 'finds the runner favouring CLIENTY').toBe('RUNX')
    expect(H.Lies_favoured_runner(tw, 'NOBODY'), 'unfavoured client → undefined').toBeUndefined()

    try { for (const h of allHouses(H)) h.stop?.() } catch {}
})
