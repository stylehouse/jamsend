// SectResolve — the gate for how a `§` link RESOLVES, which is the half `LinkKinds.spec.ts` does not
//  cover.  That file gates the COLLECTOR (what `compile.ts` emits from a document's text); this one
//   gates the READER (what `Lagoon_lint` concludes from what Atlas holds).
//
//  WHY IT EXISTS.  In one night the resolution rules were got wrong four separate times, and every
//   single one was caught by MEASURING the corpus rather than by reading the code (Lagoon_todo §1.7):
//    the backtick between a doc name and its §, doc names without an underscore, numbered items that
//     are not headings, and the `_todo` suffix the corpus drops.  A fifth — the `history/` skip the
//      file-lint already had and the § pass did not — was found only by trying to ACT on the work
//       queue.  Five near-misses and nothing protected any of them.  This does.
//
//  IT USES HAND-MADE PARTICLES, NOT THE CORPUS, and that is the point: a census fixture built here is
//   exact and cannot drift, whereas a corpus-derived expectation moves every time somebody writes a
//    doc.  `LinkKinds`'s corpus sweep is a floor on a RATIO; this is an assertion about a RULE.
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/SectResolve.spec.ts
import { test, expect, beforeAll } from 'vitest'
import { mount } from 'svelte'
import Story_cli from './Story_cli.svelte'
import LagoonGo from '../src/lib/gen/L/Lagoon.go'

const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))
let H: any

beforeAll(async () => {
    mount(Story_cli, { target: document.body, props: { onhouse: (h: any) => { H = h } } })
    for (let i = 0; i < 80 && !H?.started; i++) await sleep(50)
    expect(H, 'Story_cli gave us a House').toBeTruthy()
    // the ghost arrives the way the app gets it: mount the generated module, whose onMount eatfunc
    //  deposits the Lagoon_* methods onto the House.  `Lies_ghost_set` is the browser path to the same
    //   thing (it enrols the module in watched:UIs for Otro to mount); here we mount it directly.
    mount(LagoonGo as any, { target: document.body, props: { H } })
    for (let i = 0; i < 80 && typeof H.Lagoon_lint !== 'function'; i++) await sleep(50)
    expect(typeof H.Lagoon_lint, 'Lagoon ghost deposited').toBe('function')
}, 30_000)

// ── the fixture census.  A:Atlas/w:Atlas on the top House, exactly where Lagoon_atlas() looks, with
//  hand-made %Doc rows.  Rebuilt per test so no test can see another's docs. ───────────────────────
function census(docs: Array<{ path: string, lines?: number, headings?: string[], anchors?: string[],
                             sects?: Array<{ target?: string, sect: string }> }>) {
    const top = H.top_House()
    for (const old of top.o({ A: 'Atlas' })) top.drop(old)
    for (const old of top.o({ A: 'Lagoon' })) top.drop(old)
    const aw = top.i({ A: 'Atlas' }).i({ w: 'Atlas' })
    const lw = top.i({ A: 'Lagoon' }).i({ w: 'Lagoon' })
    for (const d of docs) {
        const doc = aw.i({ Doc: d.path })
        doc.sc.lines = String(d.lines ?? 500)
        const map = doc.i({ Map: 1 })
        let ln = 1
        for (const h of d.headings ?? []) map.i({ region: 1, label: h, depth: 2, line: ln++ })
        for (const a of d.anchors ?? []) map.i({ anchor: 1, sect: a, line: ln++ })
        for (const s of d.sects ?? []) {
            const row: any = { link: 1, kind: 'sect', sect: s.sect, line: ln++ }
            if (s.target) row.target = s.target
            map.i(row)
        }
    }
    return lw
}
const lint = (lw: any) => H.Lagoon_lint(lw)

test('the fixture census is what Lagoon reads (the harness itself holds)', () => {
    const out = lint(census([{ path: 'spec/A_todo.md', headings: ['1. One'] }]))
    expect(out.error).toBeUndefined()
    expect(out.docs).toBe(1)
})

test('the `_todo` / `_spec` suffix the corpus drops still resolves', () => {
    // prose cites `Social_demarcation §7`; the doc is `Social_demarcation_todo.md`.  Without the
    //  fallback this read "nothing rosters that doc" — 38 of 470 links across the real corpus.
    const out = lint(census([
        { path: 'spec/Social_demarcation_todo.md', headings: ['7. Seven'] },
        { path: 'spec/Wire_spec.md',               headings: ['1. One'] },
        { path: 'spec/Cite.md', sects: [{ target: 'Social_demarcation', sect: '7' },
                                        { target: 'Wire', sect: '1' }] },
    ]))
    expect(out.sect_nodoc, 'both resolved through the suffix fallback').toEqual([])
    expect(out.sect_gone).toEqual([])
})

test('an anchor is a section too — a numbered item that is not a heading', () => {
    // `**7.4 Per-peer fairness: OUT OF SCOPE.**` inside §7 is an anchor a § legitimately lands on.
    const out = lint(census([
        { path: 'spec/B_todo.md', headings: ['7. Questions'], anchors: ['7.4'] },
        { path: 'spec/Cite.md',   sects: [{ target: 'B_todo', sect: '7.4' }] },
    ]))
    expect(out.sect_gone, 'the bold numbered item counts').toEqual([])
})

test('a section number indexes every shorter prefix, and its letterless form', () => {
    // a doc whose only section-3 heading is `3.1b` still HAS a §3 and a §3.1 — a prefix names the
    //  section that CONTAINS the one cited, so the pointer is aimed at a real place either way.
    const lw = census([
        { path: 'spec/C_todo.md', headings: ['3.1b A lettered subsection'] },
        { path: 'spec/Cite.md',   sects: [{ target: 'C_todo', sect: '3' },
                                          { target: 'C_todo', sect: '3.1' },
                                          { target: 'C_todo', sect: '3.1b' }] },
    ])
    expect(lint(lw).sect_gone, 'prefix + letterless both index').toEqual([])
})

test('a target naming the shelf is never accused — Atlas does not roster history/', () => {
    // The file:line lint always skipped `history/`|`shelved/`; the § pass did not inherit it, so a
    //  reference that is already CORRECT (`history/Reqdrop_todo §0`) read as a doc nothing has.
    const out = lint(census([
        { path: 'spec/Cite.md', sects: [{ target: 'history/Reqdrop_todo', sect: '0' },
                                        { target: 'shelved/Old_todo',     sect: '2' }] },
    ]))
    expect(out.sect_nodoc, 'the shelf is not rot').toEqual([])
    expect(out.sect_gone).toEqual([])
    expect(out.sect_links, 'they are still COUNTED — skipped is not invisible').toBe(2)
})

test('a bare § is counted and never accused — its referent is prose', () => {
    // `see §9` inside a doc looks like a self-reference and often is not: `Seemables_todo` has 38 bare
    //  §s and numbers nothing but its own §0, because they point into whatever doc the sentence named.
    const out = lint(census([
        { path: 'spec/D_todo.md', headings: ['0. Zero'],
          sects: [{ sect: '9' }, { sect: '3' }, { sect: '0' }] },
    ]))
    expect(out.sect_self, 'all three counted as bare').toBe(3)
    expect(out.sect_gone, 'and none of them judged').toEqual([])
    expect(out.sect_links).toBe(3)
})

test('a genuinely dead anchor in a LIVE doc IS reported — the signal the kind exists for', () => {
    const out = lint(census([
        { path: 'spec/E_todo.md', headings: ['3. Three', '3.1 One', '3.4 Four'] },
        { path: 'spec/Cite.md',   sects: [{ target: 'E_todo', sect: '3.7' }] },
    ]))
    expect(out.sect_gone.length, 'the live doc has no §3.7').toBe(1)
    expect(out.sect_gone[0].target).toBe('spec/E_todo.md')
    expect(out.sect_gone[0].sect).toBe('3.7')
    expect(out.sect_nodoc, 'and it is NOT a missing-doc verdict — they route differently').toEqual([])
})

// ── the face's HOME.  Not a resolution rule, but it shares this file's harness (a mounted ghost on a
//  real House) and it was the last thing written tonight that had never been EXECUTED — which, an hour
//   earlier, is exactly how `Lagoon_oaths` turned out to throw on its first call.
//  It is also the fix for the bug the owner actually reported: *"UI:Lagoon appears to come out in
//   H:Mundo but shouldn't… I can see H:Hackarium's UI:Langui there but not UI:Lagoon"*.  The census must
//    stand on the top House (every reader looks it up there by name), so the face followed it there and
//     ended up on a different page of a room that shows one House's UIs at a time.  `w.c.face_on` lets
//      the room name itself as the face's home.  If this is wrong, the thing they asked for is broken.
test('the face mounts where the ROOM says, not where the census stands', () => {
    const top  = H.top_House()
    const room = top.subHouse('FaceRoom')
    const lw   = top.i({ A: 'LagoonFace' }).i({ w: 'LagoonFace' })
    lw.c.face_on = room
    H.Lagoon_plan(lw)
    const on_room = room.o({ watched: 'UIs' })[0]
    expect(on_room, 'the room grew a watched:UIs').toBeTruthy()
    expect(on_room.oa({ UI: 'Lagoon' }), 'and the face landed on it').toBeTruthy()
    expect(lw.c.faced, 'the world is marked faced so it mounts once').toBe(1)
})

test('with no room naming itself, the face falls back to where it always went', () => {
    // a CLI-stood Lagoon has no room; the old behaviour must survive untouched, or every runner tab
    //  that stands the reader by hand loses its face.
    const top = H.top_House()
    const lw  = top.i({ A: 'LagoonBare' }).i({ w: 'LagoonBare' })
    expect(lw.c.face_on, 'no room named itself').toBeUndefined()
    H.Lagoon_plan(lw)
    expect(top.o({ watched: 'UIs' })[0]?.oa({ UI: 'Lagoon' }), 'it went to the House it runs on').toBeTruthy()
})

test('a doc nothing has at all is a different verdict from a dead anchor', () => {
    const out = lint(census([
        { path: 'spec/Cite.md', sects: [{ target: 'Story_next_level', sect: '13' }] },
    ]))
    expect(out.sect_nodoc.length).toBe(1)
    expect(out.sect_nodoc[0].sect).toBe('13')
    expect(out.sect_gone, 'a doc that is gone cannot have a dead anchor').toEqual([])
})

// ── THE FIGURINES (2026-09-09).  `Lagoon_figurines` is a READING over two censuses — Electrode's
//  measured flows and Atlas's declared calls — and the owner's ask was precise about the three words:
//   popular (distinct callers), top-most (only ever entered from outside the coats), well connected
//    (sized).  A hand-made tally + a hand-made census pin each word to a number. ─────────────────────
function tally(rows: Array<{ from: string | null, to: string, n: number, ms?: number }>) {
    const top = H.top_House()
    const T: any = { armed: 1, seq: 0, cur: null, ring: [], tally: new Map(), open: new Map(), dropped: 0, cap: 4096, since: 1 }
    for (const r of rows) T.tally.set((r.from ?? '') + '>' + r.to, { from: r.from, to: r.to, n: r.n, ms: r.ms ?? 1, async: 0, threw: 0, max: r.ms ?? 1 })
    top.c.electrode = T
    return T
}

test('figurines — popular is DISTINCT callers, top-most is entered only from outside, and both are sized', () => {
    const lw = census([{ path: 'Ghost/X/Sample.g' }])
    const aw = H.top_House().o({ A: 'Atlas' })[0].o({ w: 'Atlas' })[0]
    const map = aw.o({ Doc: 'Ghost/X/Sample.g' })[0].o({ Map: 1 })[0]
    map.i({ def: 1, method: 'Sample_alpha', line: 3 })
    map.i({ def: 1, method: 'Sample_beta', line: 9 })
    map.i({ def: 1, method: 'Sample_gamma', line: 15 })
    map.i({ call: 1, via: 'Sample_alpha', method: 'Sample_beta', line: 5 })       // alpha DECLARES it calls beta
    tally([
        { from: null,           to: 'Sample_alpha', n: 5 },                      // alpha: entered from outside only
        { from: 'Sample_alpha', to: 'Sample_beta',  n: 500 },                    // beta hammered by alpha…
        { from: 'Sample_gamma', to: 'Sample_beta',  n: 1 },                      // …and touched once by gamma
        { from: null,           to: 'Sample_gamma', n: 2 },
        { from: 'Sample_beta',  to: 'Sample_gamma', n: 1 },                      // gamma is ALSO reached by beta — not top-most
    ])
    const r = H.Lagoon_figurines(lw, 10)
    expect(r.error, 'answered').toBeUndefined()
    const by = Object.fromEntries(r.figurines.map((f: any) => [f.name, f]))
    expect(r.figurines[0].name, 'beta is the most connected — two DISTINCT callers beat five hundred calls from one').toBe('Sample_beta')
    expect(by.Sample_beta.callers).toBe(2)
    expect(by.Sample_beta.declared, 'Atlas declares one caller of beta (alpha); gamma reached it undeclared').toBe(1)
    expect(by.Sample_beta.n, 'traffic is still reported, it just does not rank').toBe(501)
    expect(by.Sample_alpha.top, 'alpha is top-most: every entry came from outside the coats').toBe(1)
    expect(by.Sample_gamma.top, 'gamma is NOT top-most — beta reached it, even once').toBeUndefined()
    expect(by.Sample_beta.top).toBeUndefined()
    expect(by.Sample_alpha.fan, 'alpha reaches one distinct method').toBe(1)
    expect(by.Sample_beta.dose, 'the most connected wears dose 1').toBe(1)
    expect(by.Sample_alpha.dose, 'a method nobody coated calls wears dose 0 — it is where the world enters, not a hub').toBe(0)
    expect(by.Sample_beta.doc, 'the def is joined on from Atlas').toBe('Ghost/X/Sample.g')
    expect(by.Sample_beta.line).toBe(9)
    expect(r.tops).toBe(1)
    expect(r.ran).toBe(3)
    // the layer rule: a reader keeps nothing — the Lagoon world holds nothing after answering
    expect(lw.o().length, 'Lagoon_figurines minted nothing').toBe(0)
})

test('figurines — no tally is a NAMED refusal; an un-armed tally is an honest zero', () => {
    const lw = census([{ path: 'Ghost/X/Sample.g' }])
    const top = H.top_House()
    top.c.electrode = undefined
    const refused = H.Lagoon_figurines(lw, 10)
    expect(String(refused.error), 'refuses by name, never a throw or a silent empty').toMatch(/no electrode tally/)
    const T = tally([])
    T.armed = 0
    const zero = H.Lagoon_figurines(lw, 10)
    expect(zero.error).toBeUndefined()
    expect(zero.figurines.length).toBe(0)
    expect(zero.armed, 'and the reply says WHY it is empty').toBe(0)
})

// ── THE ERRANDS (2026-09-09).  `Lagoon_errands` reads a shelf it does not own — the Aside moments
//  `e_Lies_ghost_pick` has been writing all along (Clerkdesk_todo §0: shelf built, label built,
//   resolver built, surface never drawn).  These pin the two judgements in it: a moment's WEIGHT is
//    how often you returned, and a since-renamed path is HISTORY, not rot. ────────────────────────
function aside(days: Array<{ day: string, moments: Array<{ what: number, about?: string, from?: string,
                                                           docs: Array<{ doc: string, points?: string[] }> }> }>) {
    const top = H.top_House()
    for (const old of top.o({ A: 'Lies' })) top.drop(old)
    const lw = top.i({ A: 'Lies' }).i({ w: 'Lies' })
    for (const d of days) {
        const wf = lw.i({ Waft: d.day })
        wf.sc.aside = 1
        for (const m of d.moments) {
            const mc = wf.i({ What: m.what })
            if (m.about) mc.sc.about = m.about
            if (m.from) mc.sc.FromWhat = m.from
            for (const dd of m.docs) {
                const dc = mc.i({ Doc: dd.doc })
                for (const p of dd.points ?? []) dc.i({ Point: 1, method: p })
            }
        }
    }
    return lw
}

test('errands — the day’s trail reads back: what it was for, how often you returned, where from', () => {
    aside([
        { day: 'Aside/2026-09-08', moments: [
            { what: 1, about: 'old_thing', docs: [{ doc: 'Ghost/M/Ra.g', points: ['old_thing'] }] } ] },
        { day: 'Aside/2026-09-09', moments: [
            { what: 1, about: 'Heist_blag', from: 'Waft:Ghost/Music/Ality/What:the heist — a caper, §10',
              docs: [{ doc: 'Ghost/M/Heist.g', points: ['Heist_blag'] }] },
            { what: 2, about: 'Repli_serve_chunks',
              docs: [{ doc: 'Ghost/N/Repli.g', points: ['Repli_serve_chunks', 'Repli_find_record', 'Repli_park'] }] } ] },
    ])
    const lw = H.top_House().o({ A: 'Lagoon' })[0]?.o({ w: 'Lagoon' })[0] ?? H.top_House().i({ A: 'Lagoon' }).i({ w: 'Lagoon' })
    const r = H.Lagoon_errands(lw, 10)
    expect(r.error, 'answered').toBeUndefined()
    expect(r.total).toBe(3)
    expect(r.days.length).toBe(2)
    expect(r.days[0].day, 'newest day first').toBe('Aside/2026-09-09')
    expect(r.errands[0].about, 'inside a day, the most-returned-to moment leads — three visits beats one').toBe('Repli_serve_chunks')
    expect(r.errands[0].visits).toBe(3)
    expect(r.errands[0].docs[0].points).toEqual(['Repli_serve_chunks', 'Repli_find_record', 'Repli_park'])
    expect(r.errands[1].about).toBe('Heist_blag')
    expect(r.errands[1].from_waft, 'the locator splits at the LAST slash before a Mainkey: — a Waft key has slashes in it').toBe('Ghost/Music/Ality')
    expect(r.errands[1].from_tail).toBe('What:the heist — a caper, §10')
    expect(r.errands[2].day, 'yesterday sorts under today').toBe('Aside/2026-09-08')
    // the layer rule
    expect(lw.o().length, 'a reader keeps nothing').toBe(0)
})

test('errands — a since-renamed path is HISTORY: marked, never hidden, and never marked unseen', () => {
    aside([{ day: 'Aside/2026-09-09', moments: [
        { what: 1, about: 'VoroMitosis_seed', docs: [{ doc: 'Ghost/Story/Voronation.g', points: ['VoroMitosis_seed'] }] },
        { what: 2, about: 'Heist_blag', docs: [{ doc: 'Ghost/M/Heist.g', points: ['Heist_blag'] }] } ] }])
    // no Atlas: "I cannot see" must not render as "it is not there"
    for (const old of H.top_House().o({ A: 'Atlas' })) H.top_House().drop(old)
    const lw = H.top_House().o({ A: 'Lagoon' })[0]?.o({ w: 'Lagoon' })[0] ?? H.top_House().i({ A: 'Lagoon' }).i({ w: 'Lagoon' })
    const blind = H.Lagoon_errands(lw, 10)
    expect(blind.atlas).toBe(0)
    expect(blind.gone, 'with no census, nothing is accused').toBe(0)
    expect(blind.errands.every((m: any) => m.docs.every((d: any) => !d.gone))).toBe(true)
    // with a census that holds only the live file, the renamed one is marked — and still listed
    const aw = H.top_House().i({ A: 'Atlas' }).i({ w: 'Atlas' })
    aw.i({ Doc: 'Ghost/M/Heist.g' })
    const seen = H.Lagoon_errands(lw, 10)
    expect(seen.atlas).toBe(1)
    expect(seen.gone).toBe(1)
    expect(seen.total, 'the visit still happened — a stale path is never dropped from the trail').toBe(2)
    const stale = seen.errands.find((m: any) => m.about === 'VoroMitosis_seed')
    expect(stale.docs[0].gone).toBe(1)
    expect(seen.errands.find((m: any) => m.about === 'Heist_blag').docs[0].gone).toBeUndefined()
})

test('errands — no Lies world is a NAMED refusal, not an empty list', () => {
    const top = H.top_House()
    for (const old of top.o({ A: 'Lies' })) top.drop(old)
    const lw = top.o({ A: 'Lagoon' })[0]?.o({ w: 'Lagoon' })[0] ?? top.i({ A: 'Lagoon' }).i({ w: 'Lagoon' })
    expect(String(H.Lagoon_errands(lw, 10).error)).toMatch(/no A:Lies standing/)
})
