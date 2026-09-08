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
