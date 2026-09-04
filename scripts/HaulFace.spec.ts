// HaulFace — DOES THE ONLY WAY IN ACTUALLY DRAW? (2026-08-13)
//
//  WHY THIS FILE EXISTS.  Sounditron stopped budding heists individually when the Haul cell is on the rim
//   to speak for them (a ring of pink discs has no order, and the order is the thing you want with four
//    queued).  That makes **HaulFace the only way into a running heist**.  A face that throws, or that
//     quietly derives an empty list, now costs the owner access to their own downloads — and there is no
//      browser in this container to look with.
//  So it is mounted here, in jsdom, the same way the ghost specs mount a compiled `.go`.  A Svelte face is
//   just a component; `mount` + a stub `H` is all it takes, and it turns "I believe it renders" into a
//    thing that fails a check.  This is the cheapest possible stand-in for the runner, not a substitute
//     for it: no layout, no Vyto, no real House.  It proves the face's own logic and its wiring to the
//      ghost verbs, which is exactly the part that was written blind.
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/HaulFace.spec.ts
import { test, expect } from 'vitest'
import { mount, flushSync } from 'svelte'
import { TheC } from '../src/lib/data/Stuff.svelte'
import Heist from '../src/lib/gen/M/Heist.go'
import HaulFace from '../src/lib/O/ui/HaulFace.svelte'

const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))

// the ghost, mounted for its real verbs — Heist_live_rows/Heist_keep_gist/Heist_queue_order are the whole
//  contract between this face and the machine, so stubbing them would test nothing worth testing.
async function ghost_house() {
    const H: any = new TheC({ c: {}, sc: { H: 'Mundo' } })
    H.eatfunc = async (obj: any) => { Object.assign(H, obj) }
    H.top_House = () => H
    H.mainkey = (n: any) => Object.keys(n.sc)[0]
    H.Radio_trace = () => {}
    H.c.humdinger = 1
    H.Radio_pub = () => 'me'
    mount(Heist, { target: document.body, props: { H } })
    for (let i = 0; i < 80 && typeof H.Heist_live_rows !== 'function'; i++) await sleep(25)
    return H
}

// a world holding the shop shelf Heist_shop_find walks to, plus the %Hauls bag the face is handed.
function scene(H: any, heists: Array<Record<string, any>>) {
    const w: any = new TheC({ c: {}, sc: { w: 'Radio' } })
    H.c.radio_w = w
    const shelf = w.i({ Mine: 1, pub: 'me' }).i({ shop: 1, pub: 'me' })
    const keeps = heists.map((h) => {
        const k = shelf.i({ Heist: h.title, seed: h.title, pub: 'them', state: h.state || 'primed' })
        k.c.up = shelf
        if (h.paused) k.sc.paused = 1
        if (h.pri != null) k.sc.pri = h.pri
        if (h.landed != null) k.sc.landed_n = String(h.landed)
        if (h.total != null) k.sc.total_n = String(h.total)
        return k
    })
    const bag = w.i({ Hauls: 1, dontSnap: 1 })
    bag.c.up = w
    return { w, shelf, bag, keeps }
}

function draw(H: any, bag: any) {
    const target = document.createElement('div')
    document.body.appendChild(target)
    mount(HaulFace, { target, props: { n: bag, H } })
    flushSync()
    return target
}

// WAIT OUT THE TICK, deliberately, rather than reaching for `H.version`.  This face refreshes off its own
//  1s interval, and that is not belt-and-braces — the beat's `.c` marks (`queued_ts`, `no_route_ts`) are
//   runtime writes with NO bump behind them, so a version-riding derive would show "running" for a heist
//    that has been waiting its turn for a minute.  The tick IS the refresh path for half of what this cell
//     says, so the test exercises the tick.  (Written after the version-only assertions failed and the
//      first instinct was to wire more `.c.up` into the fixture — which would have tested a propagation
//       the live cell does not depend on.)
const TICK = 1100
const settle = async () => { await sleep(TICK); flushSync() }

const rowNames = (el: HTMLElement) =>
    [...el.querySelectorAll('.hf-liverow .hf-name')].map((e) => e.textContent!.trim())
const rowStates = (el: HTMLElement) =>
    [...el.querySelectorAll('.hf-liverow .hf-state')].map((e) => e.textContent!.replace(/\s+/g, ' ').trim())

test('the live half draws every standing heist, in the beat\'s own running order', async () => {
    const H = await ghost_house()
    const { bag, keeps } = scene(H, [
        { title: 'Blue Train', state: 'primed' },
        { title: 'Kind of Blue', state: 'pulling', landed: 4, total: 9 },
        { title: 'Giant Steps', state: 'pulling', pri: 2 },
    ])
    const el = draw(H, bag)

    // THE CLAIM THE WHOLE CHANGE RESTS ON: with the cell on the rim, this list IS the way in. An empty
    //  list here is not a cosmetic bug, it is a running download with no cell anywhere.
    expect(rowNames(el)).toEqual(['Blue Train', 'Kind of Blue', 'Giant Steps'])
    // …and in `Heist_queue_order`'s order, not the DOM's accident: pri 2 sorts last even though it was
    //  minted last too — so promote it and watch the list, not the mint order, decide.
    H.Heist_keep_first(keeps[2])
    await settle()
    expect(rowNames(el)[0]).toBe('Giant Steps')

    // the three words come from Heist_keep_gist, so the row cannot describe a state the machine does not
    //  have. A pulling heist carries its fraction; a form carries none (it has nothing to count yet).
    const states = rowStates(el)
    expect(states.join(' | ')).toContain('setting up')
    expect(states.join(' | ')).toContain('running 4/9')
})

test('pressing a row opens THAT heist — the particle, not its name', async () => {
    const H = await ghost_house()
    const { bag, keeps } = scene(H, [{ title: 'A' }, { title: 'B' }])
    const opened: any[] = []
    H.Sounditron_focus_keep = (_w: any, k: any) => { opened.push(k); return 1 }
    const el = draw(H, bag)

    // all %Heists share a mainkey, so a name could never have addressed one of two — the row carries the
    //  particle itself, which is the entire meaning of "building the ways through the UI to the objects".
    const btns = [...el.querySelectorAll('.hf-open')] as HTMLElement[]
    btns[1].click()
    expect(opened).toEqual([keeps[1]])
})

test('✕ arms once before it calls anything off, and ⏸ / ▶ are the same verbs the cell uses', async () => {
    const H = await ghost_house()
    const { bag, keeps } = scene(H, [{ title: 'A', state: 'pulling' }])
    const cancelled: any[] = []
    H.Heist_keep_cancel = (_w: any, k: any) => { cancelled.push(k) }
    const el = draw(H, bag)

    const x = () => el.querySelector('.hf-x') as HTMLElement
    // ONE PRESS MUST NOT CANCEL. Nothing is deleted by a cancel, but a minute of setup is — and in a LIST
    //  the row under your cursor moves as heists finish, which is precisely when a misclick happens.
    x().click(); flushSync()
    expect(cancelled).toEqual([])
    expect(x().textContent!.trim()).toBe('sure?')
    x().click(); flushSync()
    expect(cancelled).toEqual([keeps[0]])

    // pause flips the row to paused and swaps the button to resume — read straight off `sc.paused`, the
    //  flag the beat actually skips on, so the button cannot lie about whether the heist is stopped.
    const btn = (t: string) => [...el.querySelectorAll('.hf-b')].find((b) => b.textContent!.trim() === t) as HTMLElement
    btn('⏸').click()
    expect(keeps[0].sc.paused).toBe(1)
    await settle()
    expect(btn('▶')).toBeTruthy()
    btn('▶').click()
    expect(keeps[0].sc.paused).toBeUndefined()
})

test('with nothing in flight it is the old archive cell, and with nothing at all it still says what it is', async () => {
    const H = await ghost_house()
    const { bag } = scene(H, [])
    const el = draw(H, bag)

    // no live section, no separator, and the empty line is back — the cell must not grow furniture for a
    //  tense that has nothing in it. (The whole month's direction is the glass getting SMALLER.)
    expect(el.querySelectorAll('.hf-liverow').length).toBe(0)
    expect(el.querySelector('.hf-sep')).toBe(null)
    expect(el.querySelector('.hf-empty')).toBeTruthy()
    expect(el.querySelector('.hf-badge')!.textContent!.trim()).toBe('✓')
})

test('a face asked before the app is ready renders rather than throwing', async () => {
    const H = await ghost_house()
    // no radio world, no bag `.c.up`, no identity — every way the face can be commissioned early. The
    //  guards are `?.` and `?? []` throughout; this is the assertion that they are all actually there.
    H.c.radio_w = null
    H.Radio_pub = () => null
    const bare: any = new TheC({ c: {}, sc: { Hauls: 1 } })
    const el = draw(H, bare)
    expect(el.querySelector('.hf')).toBeTruthy()
    expect(el.querySelectorAll('.hf-liverow').length).toBe(0)
})

test('at bud size it is ONE glyph and nothing else', async () => {
    const H = await ghost_house()
    const { bag, keeps } = scene(H, [{ title: 'A', state: 'pulling' }, { title: 'B' }])
    // Sounditron stamps `.c.pose = 'small'` on every bud; the pose law is "name, and an icon if you have
    //  one. Nothing else". This cell was drawing its head, its counts AND its whole live list at rim size.
    ;(bag as any).c.pose = 'small'
    const el = draw(H, bag)

    expect(el.querySelector('.hf-bud')).toBeTruthy()
    expect(el.querySelector('.hf-badge')!.textContent!.trim()).toBe('⇊')
    // the list, the head and the separator must all be GONE — not merely small. A bud that still renders
    //  rows is the "unreadable at rim size" complaint with extra steps.
    expect(el.querySelectorAll('.hf-liverow').length).toBe(0)
    expect(el.querySelector('.hf-head')).toBe(null)
    expect(el.querySelector('.hf-list')).toBe(null)
    // …and it does not swap glyph with the tense. At this size a changing glyph reads as a DIFFERENT cell
    //  — the mirror-tok lesson arriving through the eye instead of the renderer.
    for (const k of keeps) k.sc.state = 'done'
    await settle()
    expect(el.querySelector('.hf-badge')!.textContent!.trim()).toBe('⇊')
})

test('a capped bag says how many there really are, not how many it kept', async () => {
    const H = await ghost_house()
    const { bag } = scene(H, [])
    // `Heist_haul_look` whittles the bag to the newest 40 so the slow beat cannot re-mint and re-drop
    //  hundreds of rows a pass, and stamps the TRUE total as `n_all`. 20 rows here, 317 albums landed.
    for (let i = 0; i < 20; i++) {
        const r = bag.i({ Haul: 1, dir: 'D' + i })
        r.sc.name = 'Album ' + i
        r.sc.tracks = '9'
        r.sc.at = String(1000 + i)
    }
    bag.sc.n_all = '317'
    const el = draw(H, bag)

    // A SILENT CAP READS AS COMPLETENESS. Counting the rendered list would tell someone with 317 landed
    //  albums that they have 20 — wrong in the one direction that never looks wrong, because nothing on
    //   screen resembles an omission.
    expect(el.querySelector('.hf-mkv')!.textContent).toBe(':317')
    expect(el.querySelector('.hf-more')!.textContent!.trim()).toBe('…and 305 more')

    // …and with no cap in play the two agree, so the honest case gains no phantom rows.
    const { bag: b2 } = scene(H, [])
    for (let i = 0; i < 3; i++) { const r = b2.i({ Haul: 1, dir: 'E' + i }); r.sc.tracks = '2'; r.sc.at = String(i) }
    const el2 = draw(H, b2)
    expect(el2.querySelector('.hf-mkv')!.textContent).toBe(':3')
    expect(el2.querySelector('.hf-more')).toBe(null)
})

test('"new" is now a clock, not an opinion — today is highlighted and last week is not', async () => {
    const H = await ghost_house()
    const { bag } = scene(H, [])
    const now = Math.floor(Date.now() / 1000)
    // WHY THIS CHANGED (2026-08-13). The highlight read `feeling === 'fresh'`, and `feeling` had no
    //  user-reachable writer anywhere in the app — so in practice EVERY landed row was highlighted for
    //   ever, which is indistinguishable from no highlight at all. A row that is always emphasised
    //    emphasises nothing. The owner cut feelings; a download list's honest "new" is "arrived today",
    //     which `at` already knows and nobody has to maintain.
    const today = bag.i({ Haul: 1, dir: 'Today' }); today.sc.name = 'Today'; today.sc.tracks = '4'; today.sc.at = String(now - 3600)
    const older = bag.i({ Haul: 1, dir: 'Older' }); older.sc.name = 'Older'; older.sc.tracks = '4'; older.sc.at = String(now - 7 * 86400)
    const el = draw(H, bag)

    const rows = Array.from(el.querySelectorAll('.hf-row')) as HTMLElement[]
    const fresh = rows.filter((r) => r.classList.contains('fresh'))
    expect(rows.length).toBe(2)
    // exactly one, and it is the recent one — not both (the old always-on bug) and not neither.
    expect(fresh.length).toBe(1)
    expect(fresh[0].textContent).toContain('Today')
})
