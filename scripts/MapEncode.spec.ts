// MapEncode — CAN THE INDEX BE SERIALISED?  (the owner, 2026-09-10: *"I mean, can we make a
//  serialisable bunch of it? is the Map|index in C** formation?"*)
//
//  This is step 1 of `spec/Docmag_todo.md`, and it is deliberately the FIRST thing built: the whole
//   plan — a watcher that scans docs into a `%Mag` and Replis it to every tab so no tab ever parses —
//    rests on one claim, that Atlas's `%Doc > %Map` tree can go through `enWaft` and come back
//     identical.  If it cannot, none of the plumbing after it is worth starting.  So it is proven here,
//      offline, with hand-made particles and no daemon, no wire and no corpus.
//
//  WHAT IS KNOWN GOING IN (read off Atlas.g, not guessed):
//   · the index IS real C — `%Doc:<path> > %Map > {def|call|link|region|anchor}` rows, minted with i()
//   · `map.sc.dontSnap = 1` is set at both mint sites, and `Text.svelte` prunes the subtree on it
//   · `region_path` (an ARRAY), `abs_from` and `abs_to` ride on `.c`, which is never encoded — which is
//      exactly why `Atlas_cache_put`/`Atlas_cache_adopt` hand-copy them in and out for Dexie, a
//       bespoke serialiser sitting beside the real one
//
//  So these tests CHARACTERISE first and demand nothing that is not true yet.  A test that asserted the
//   fixed behaviour before the fix would just be a red with an opinion; a test that pins what is
//    actually lost tells the next person precisely what to change and proves it when they do.
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/MapEncode.spec.ts
import { test, expect, beforeAll } from 'vitest'
import { mount } from 'svelte'
import Story_cli from './Story_cli.svelte'

const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))
let H: any

beforeAll(async () => {
    mount(Story_cli, { target: document.body, props: { onhouse: (h: any) => { H = h } } })
    for (let i = 0; i < 80 && !H?.started; i++) await sleep(50)
    expect(H, 'Story_cli gave us a House').toBeTruthy()
    expect(typeof H.enWaft, 'the encoder is on the House').toBe('function')
}, 30_000)

// a faithful miniature of what Atlas_map_one builds: one Doc, one Map, one row of each kind that
//  carries something interesting, including the three fields that live on .c
function doc_with_map(opts: { dontSnap?: boolean } = {}) {
    const top = H.top_House()
    for (const old of top.o({ A: 'MapEnc' })) top.drop(old)
    const w = top.i({ A: 'MapEnc' }).i({ w: 'MapEnc' })
    const doc = w.i({ Doc: 'Ghost/X/Sample.g' })
    doc.sc.dige = 'abc123def456789a'
    doc.sc.lines = '120'
    doc.sc.by = 'm15'
    doc.sc.defs = '2'
    const map = doc.i({ Map: 1 })
    if (opts.dontSnap) map.sc.dontSnap = 1
    map.i({ region: 1, label: 'the engine', depth: 2, line: 3 })
    const d1 = map.i({ def: 1, method: 'Sample_alpha', line: 9 })
    d1.c.region_path = ['the engine']
    d1.c.abs_from = 210
    d1.c.abs_to = 480
    map.i({ call: 1, method: 'Sample_beta', via: 'Sample_alpha', line: 14 })
    map.i({ link: 1, kind: 'sect', target: 'Wordland_todo.md', sect: '4b', line: 22 })
    map.i({ anchor: 1, sect: '4b', line: 40 })
    return { w, doc, map }
}

const MAG_PROTOCOL = [{ matching_any: [{ mk: 'Doc' }, { mk: 'Map' }], means: { omit_sc: {} } }]

test('the index IS in C** formation — Doc > Map > rows are ordinary particles', () => {
    const { doc, map } = doc_with_map()
    expect(doc.sc.Doc).toBe('Ghost/X/Sample.g')
    expect(map.o().length, 'five rows under the Map').toBe(5)
    expect(map.o({ def: 1 })[0].sc.method).toBe('Sample_alpha')
    expect(H.mainkey(map.o({ def: 1 })[0]), 'each row wears its own mainkey').toBe('def')
})

// ⚠ THIS TEST EXISTS BECAUSE IT CAUGHT ME BEING WRONG.  I had read `map.sc.dontSnap = 1` plus
//  Text.svelte's dontSnap handling and told the owner the encoder prunes the Map — so the plan's first
//   step was going to be "remove the flag".  It is not true: pruning is driven by a matched RULE's
//    `means.dontSnap` (Text ~:748), and the only rule that sets it is Story's, for equip Wafts
//     (Story.svelte ~:1161).  `sc.dontSnap` is a MARKER a protocol may act on, not a property the
//      encoder honours by itself — so a protocol that does not ask for it encodes the rows fine.
//  Which means the index needed no unfencing at all: it was already serialisable and nobody had tried.
test('sc.dontSnap does NOT prune by itself — the encoder honours a RULE, not a flag', async () => {
    const { doc } = doc_with_map({ dontSnap: true })
    const { snap, errors } = await H.enWaft(doc, { matching: MAG_PROTOCOL })
    expect(errors, 'encoding does not fault').toEqual([])
    expect(snap).toMatch(/Doc:Ghost\/X\/Sample\.g/)
    expect(snap, 'the rows encode even with the flag set, because no rule asked to prune').toMatch(/Sample_alpha/)
    expect(snap, 'the flag itself rides as an ordinary snapped key').toMatch(/dontSnap/)
})

// …and wrong a SECOND time, in the same file, which is the useful part.  A `means.dontSnap` rule does
//  not fold anything at encode either — Text.svelte says so in as many words: *"The line still encodes
//   here; story_process_node forwards the flag, snap_H folds."*  enWaft MARKS; the Story snap walk is
//    what prunes.  So the encoder is unconditionally willing to emit the whole index and always was.
//  Twice in one sitting I inferred a behaviour from a comment and was contradicted by running it.  That
//   is the entire argument for characterisation tests over confident ones.
test('a dontSnap rule MARKS the line and still encodes the rows — folding is snap_H, not enWaft', async () => {
    const { doc } = doc_with_map({ dontSnap: true })
    const prune = [{ matching_any: [{ sc_has: { Map: 1 } }], means: { dontSnap: true } }]
    const { snap, errors } = await H.enWaft(doc, { matching: prune })
    expect(errors).toEqual([])
    expect(snap, 'the marker rides as an objecty on the Map line').toMatch(/Map,dontSnap\s+\{"dontSnap":1\}/)
    expect(snap, 'and the rows are emitted all the same — enWaft never folds').toMatch(/Sample_alpha/)
})

test('without dontSnap the Map encodes — so the index is serialisable in principle', async () => {
    const { doc } = doc_with_map()
    const { snap, errors } = await H.enWaft(doc, { matching: MAG_PROTOCOL })
    expect(errors).toEqual([])
    for (const want of ['Sample_alpha', 'Sample_beta', 'the engine', 'Wordland_todo.md']) {
        expect(snap, `${want} survived the encode`).toMatch(new RegExp(want.replace(/[./]/g, '\\$&')))
    }
})

test('…and it round-trips: decode rebuilds the same rows', async () => {
    const { doc } = doc_with_map()
    const { snap } = await H.enWaft(doc, { matching: MAG_PROTOCOL })
    const { C, errors } = (H as any).decode_wh_lines(snap)
    expect(errors, 'decoding does not fault').toEqual([])
    expect(C, 'a tree came back').toBeTruthy()
    const map2 = C.o({ Map: 1 })[0]
    expect(map2, 'the Map came back').toBeTruthy()
    expect(map2.o().length, 'every row came back').toBe(5)
    expect(map2.o({ def: 1 })[0].sc.method).toBe('Sample_alpha')
    expect(map2.o({ call: 1 })[0].sc.via).toBe('Sample_alpha')
    expect(map2.o({ link: 1 })[0].sc.sect).toBe('4b')
    expect(C.sc.dige, "the Doc's own census fields ride along").toBe('abc123def456789a')
})

// THE GAP, pinned so the fix has something to turn green.  `region_path`/`abs_from`/`abs_to` are on
//  .c and .c is never encoded, so a round-tripped Map is missing exactly the three fields Dexie's
//   hand-rolled serialiser copies by hand.  `region_path` cannot simply move to sc — an array in sc is
//    fatal at encode — so the honest options are child particles or re-deriving it from the %region
//     rows' line spans, which is what a beadchain does anyway.  See Docmag_todo §0.
test('THE GAP — the three .c fields do NOT survive, which is what Dexie hand-copies today', async () => {
    const { doc, map } = doc_with_map()
    expect(map.o({ def: 1 })[0].c.region_path, 'present in the live tree').toEqual(['the engine'])
    const { snap } = await H.enWaft(doc, { matching: MAG_PROTOCOL })
    expect(snap, 'but never reaches the snap').not.toMatch(/region_path/)
    const { C } = (H as any).decode_wh_lines(snap)
    const def2 = C.o({ Map: 1 })[0].o({ def: 1 })[0]
    expect(def2.c.region_path, 'and so is absent after the round trip').toBeUndefined()
    expect(def2.c.abs_from).toBeUndefined()
    expect(def2.c.abs_to).toBeUndefined()
})
