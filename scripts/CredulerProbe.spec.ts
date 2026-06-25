// CredulerProbe — Tier 0 de-risk: can a runner ACQUIRE its spine (CREDULER_GHOSTS gen .go)
//  and have it deposit onto H, headless?  This is the one thing the plain Story_cli boot can't
//   do (Story_cli.svelte mounts <Ghost> only, never fires Creduler_ensure), and it's why every
//    wrangler-Book behaviour claim ends "verify on :9091".  If this goes green, PereStaple can
//     run headless through the existing pile/ACCEPT machinery.
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/CredulerProbe.spec.ts
import { test, expect } from 'vitest'
import { mount, flushSync } from 'svelte'
import Runner from './Story_cli_runner.svelte'
import { NodeWormholeNav } from './NodeWormholeNav'
import { rmSync } from 'node:fs'

const ROOT  = process.cwd()
const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))
const allHouses = (H: any): any[] => { const out=[H]; const w=(h:any)=>{for(const s of (h.o?.({H:1})??[])) if(!out.includes(s)){out.push(s);w(s)}}; w(H); return out }

const OVERLAY = '/tmp/CredulerProbe_fs'
try { rmSync(OVERLAY, { recursive: true, force: true }) } catch {}
const nodeNav = new NodeWormholeNav(ROOT, OVERLAY, false)

// the methods a fully-acquired spine deposits — one per CREDULER_GHOST that matters here
const WANT = ['Peeroleum_deliver', 'inseq_admit', 'Tribunal_pair_websocket', 'Tyrant_grant', 'Run_A_PereStaple']

test('Creduler acquires the spine headless (gen .go mounts + deposits)', async () => {
    let H: any
    mount(Runner, { target: document.body, props: { onhouse: (h: any) => { H = h } } })
    for (let i = 0; i < 40 && !(H && typeof H.Creduler_ensure === 'function'); i++) await sleep(50)
    expect(typeof H?.Creduler_ensure, 'Lies ghost deposited (shell booted)').toBe('function')

    // wormhole nav — the acquire/compile path reads disk
    const WA = H.i({ A: 'Wormhole' }); WA.i({ w: 'Wormhole' }); WA.c.nav = nodeNav

    // the Creduler runner Lies (mirror Auto.svelte:119), then fire the acquire by hand
    const liesW = H.i({ A: 'Lies' }).i({ w: 'Lies', runner: 1, creduler: 1 })

    const drain = async () => { for (const h of allHouses(H)) { let g=0; while (h.todo?.length && h.started && g++<300) { try { await h._really_answer_calls() } catch {} } } }
    const liveset = () => Object.fromEntries(WANT.map(m => [m, typeof H[m] === 'function']))

    let live = liveset()
    for (let t = 0; t < 160; t++) {
        for (const h of allHouses(H)) if (!h.started) h.started = true
        try { await H.Creduler_ensure(liesW) } catch (e) { console.log('Creduler_ensure threw:', (e as any)?.message) }
        flushSync()                                              // mount any freshly-enrolled includes
        for (const h of allHouses(H)) h.i_elvisto?.(h, 'think')  // let onMount-deposited reqs pump
        await drain()
        flushSync()
        live = liveset()
        if (WANT.every(m => live[m])) break
        if (t % 10 === 0) console.log(`t=${t} pending=${!!H.oa({ Creduler_pending: 1 })} live=`, live)
        await sleep(60)
    }

    const includes = (H.UIs?.ob?.({ UI: 1 }) ?? []).map((u: any) => u.sc.gen_path)
    console.log('enrolled includes:', includes)
    console.log('final live spine:', live, 'Creduler_pending=', !!H.oa({ Creduler_pending: 1 }))

    expect(typeof H.Peeroleum_deliver, 'Peeroleum spine deposited').toBe('function')
    expect(typeof H.Run_A_PereStaple, 'PereStaple Run recipe deposited').toBe('function')

    try { for (const h of allHouses(H)) h.stop?.() } catch {}
})
