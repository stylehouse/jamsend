// Siphonation_asserts — the headless "assertions FIRED" gate for the Siphon spin-out
//  (Siphon_todo.md rung 4).  Story_cli.spec.ts proves the Book boots and walks its steps, but
//   the %see evidence (story_swear → the ave/%Assertioning shelf) hangs OFF the w:Story dump
//    (H/%watched:ave — snap-invisible by design), so a got-snap grep cannot see it.  This spec
//     runs the same drive loop and then reads the shelf itself: SIX sworn sentences, each the
//      Siphonation witness's exact claim.  Fixture diges are NOT consulted (the toc skeleton
//       carries placeholder diges until a live recording pass) — the verdict here is only
//        "the machine stood, the beats ran, the truths latched".
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/Siphonation_asserts.spec.ts
import { test, expect } from 'vitest'
import { mount } from 'svelte'
import Story_cli from './Story_cli.svelte'
import Siphon_include from './Siphon_include.svelte'
import { NodeWormholeNav } from './NodeWormholeNav'

const ROOT = process.cwd()
const BOOK = 'Siphonation'
const nodeNav = new NodeWormholeNav(ROOT, '/tmp/Siphonation_asserts_fs', false)
const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))
const allHouses = (H: any): any[] => { const out=[H]; const w=(h:any)=>{for(const s of (h.o?.({H:1})??[])) if(!out.includes(s)){out.push(s);w(s)}}; w(H); return out }

test(`Siphonation: the six %see claims latch headlessly`, async () => {
    let H: any
    mount(Story_cli, { target: document.body, props: { onhouse: (h: any) => { H = h }, include: Siphon_include } })
    for (let i = 0; i < 40 && !(H && typeof H.story_drive === 'function'); i++) await sleep(50)
    expect(typeof H?.story_drive, 'ghosts deposited').toBe('function')

    const WA = H.i({ A: 'Wormhole' }); WA.i({ w: 'Wormhole' }); WA.c.nav = nodeNav
    const S = H.subHouse('Story')
    S.i({ A: 'Story' }).i({ w: 'Story', Book: BOOK })
    S.i_elvisto(S, 'think')

    const drain = async () => { for (const h of allHouses(H)) { let g=0; while (h.todo?.length && h.started && g++<300) { try { await h._really_answer_calls() } catch {} } } }
    const find_w = () => H.o({ H: 'Story' })[0]?.o({ A: 'Story' })[0]?.o({ w: 'Story' })[0]
    let w: any, run: any
    for (let t = 0; t < 400; t++) {
        for (const h of allHouses(H)) {
            if (!h.started) h.started = true
            const o = h.The_Opt_val?.bind(h)
            if (o && !h._noc) { h._noc = true; h.The_Opt_val = (ww: any, k: string) => k === 'useCyto' ? false : o(ww, k) }
        }
        if (w && !w.c.lenient) w.c.lenient = true
        if (!run?.c?.driving) for (const h of allHouses(H)) h.i_elvisto?.(h, 'think')
        await drain()
        await sleep(60)
        w ||= find_w(); run ||= w?.o({ run: 1 })[0]
        if (run && run.c.driving === false && w?.c?.This?.o({ Step: 1 })?.length) break
    }

    // the evidence shelf: ave/%Assertioning,Story:Siphonation — one %sworn per latched claim.
    const shelf = S.story_assertioning(w)
    const sworn = (shelf?.o({ sworn: 1 }) ?? []).map((s: any) => String(s.sc.sworn))
    console.log(`[Siphonation_asserts] sworn (${sworn.length}):\n  ` + sworn.join('\n  '))
    const expected = [
        'a tag defined twice is one tag — the tags shelf holds a single Tag named lofi',
        'applying a tag twice to one track keeps one Tagged row — the playlist walk reads o1 then o2 in application order',
        'a tag is a playlist — after one unapply the walk yields exactly o1 and a second unapply finds nothing to drop',
        'the siphon presses the whole body through the one catalog door — the pool card wears the original id and the bytes land byte for byte',
        'a landed siphon drops its scaffolding — no Siphon row and no press job stand once the card is pooled',
        'a re-siphon is a no-op — one pool card stands and no second write reaches the pool',
    ]
    for (const s of expected) expect(sworn, `sworn: ${s}`).toContain(s)

    try { if (run) run.c.driving = false; for (const h of allHouses(H)) h.stop?.() } catch {}
})
