// ServeResolve — UNIT TESTS FOR THE ID→RECORD RESOLUTION THAT SERVES BYTES, with no runner and no wire.
//
//  WHY THIS FILE EXISTS.  On 2026-09-07 SoundPooling finally ran end to end, and the last thing in its
//   way was a bug that had cost roughly two days and was INVISIBLE TO EVERY BOOK:
//
//     the holder had TWO %Records under ONE keep-id — a chunkless describe husk (`total:0`) standing
//      in one RummageLib, and the real materialised copy (18 chunks) in another.  `Repli_find_record`
//       returned whichever lib registered first — the husk — and `Repli_serve_chunks` then hit
//        `!Repli_page_ready` on a total-of-zero record and RETURNED IN SILENCE: `from < total` is
//         `0 < 0` = false, so no page, no park, no miss, no log.  The sink re-asked `repli_want ×35`
//          every ten seconds, forever, while 18 real chunks sat one lib over.
//
//  WHY NO BOOK COULD SEE IT (pool-keep-rummage-alias, and SoundPooling_todo §0): a Book hand-mints its
//   mirror records, so a record's id IS the seed and the two id-spaces collapse into one.  The twin can
//    only arise where a REAL folder describe ran against a live holder and a materialise followed.  A
//     fixture cannot reproduce it; a unit test over the resolver can, because the resolver is pure.
//
//  So this is the regression net the bug never had.  It pins the RESOLUTION and the SILENCE separately,
//   because they were two defects that only looked like one: pick the wrong record, then say nothing.
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/ServeResolve.spec.ts
import { test, expect } from 'vitest'
import { mount } from 'svelte'
import { TheC } from '../src/lib/data/Stuff.svelte'
import Ra from '../src/lib/gen/M/Ra.go'
import Repli from '../src/lib/gen/N/Repli.go'
import Heist from '../src/lib/gen/M/Heist.go'

const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))

async function stub_house() {
    const H: any = {
        c: {},
        sc: {},
        misses: [] as any[],
        async eatfunc(obj: any) { Object.assign(H, obj) },
        top_House() { return H },
        Radio_trace(_n: any, _m: any) {},
    }
    for (const Ghost of [Ra, Repli, Heist]) mount(Ghost, { target: document.body, props: { H } })
    for (let i = 0; i < 80 && typeof H.Repli_find_record !== 'function'; i++) await sleep(25)
    return H
}

const world = () => new TheC({ c: {}, sc: { w: 'Serve' } }) as any
const lib = (name: string) => new TheC({ c: {}, sc: { RummageLib: name } }) as any

// a materialised record: `total` is the PROMISE, and whole-file body chunks wear their grade as a mainkey.
//  The chunks carry REAL bytes on `sc.buf`, because presence is fill state: `Repli_chunk_at` only counts a
//   chunk that actually has bytes, so a byte-less particle is an unfilled slot, not a servable page. (This
//    spec's first draft minted empty chunks and the positive control failed — the code was right.)
function full(shelf: any, id: string, total = 3, bytes = true) {
    const rec = shelf.i({ Record: 1, id, path: 'a/' + id + '.flac', total: String(total) })
    rec.c.up = shelf
    let s = 0
    while (s < total) {
        const b = rec.i({ Original: 1, seq: '' + s })
        b.c.up = rec
        if (bytes) b.sc.buf = new Uint8Array([s, s + 1, s + 2])
        s = s + 1
    }
    return rec
}
// a describe HUSK: identity and path, no bytes, no promise. The catalog entry that started the trouble.
function husk(shelf: any, id: string) {
    const rec = shelf.i({ Record: 1, id, path: 'a/' + id + '.flac', husk: 1 })
    rec.c.up = shelf
    return rec
}

test('THE TWIN: two records under one id — the resolver takes the one that HAS BYTES', async () => {
    const H = await stub_house()
    const w = world()
    const describe_lib = lib('describe')       // registered FIRST — the old code took this one
    const materialised = lib('materialised')
    husk(describe_lib, 'twin')
    full(materialised, 'twin', 3)
    w.c.rummage_libs = [describe_lib, materialised]

    const hit = H.Repli_find_record(w, 'twin', null)
    expect(hit).toBeTruthy()
    expect(+(hit.sc.total || 0)).toBe(3)                       // the materialised copy, not the husk
    expect(H.Heist_has_body(hit)).toBe(3)
    // and the order of registration must not decide it — the bug was "whichever lib was first".
    w.c.rummage_libs = [materialised, describe_lib]
    expect(+(H.Repli_find_record(w, 'twin', null).sc.total || 0)).toBe(3)
})

test('a lone husk is still returned — the resolver prefers bytes, it does not require them', async () => {
    const H = await stub_house()
    const w = world()
    const only = lib('describe')
    husk(only, 'lonely')
    w.c.rummage_libs = [only]
    const hit = H.Repli_find_record(w, 'lonely', null)
    expect(hit).toBeTruthy()                                   // a describe answer is still an answer…
    expect(+(hit.sc.total || 0)).toBe(0)                       // …it just has nothing to serve yet
    expect(H.Repli_find_record(w, 'never-minted', null)).toBe(null)
})

test('THE SILENCE: a total-of-zero record is neither servable nor parkable — and must SAY so', async () => {
    const H = await stub_house()
    const w = world()
    // `from < total` is `0 < 0` = false, so the old code fell out of the park branch and returned with
    //  no page, no park and no log. This is the exact arithmetic that made the stall invisible.
    const h = husk(lib('describe'), 'quiet')
    expect(H.Repli_page_ready(h, 0, 2)).toBe(false)
    expect(0 < +(h.sc.total || 0)).toBe(false)

    // Repli_serve_miss is the tell that now fires there. It is throttled 5s per id and returns 1 when it
    //  PASSED the throttle — so a first miss speaks, and a re-ask storm does not become a log storm.
    expect(H.Repli_serve_miss(w, { id: 'quiet', from: 'them', from_idx: 0 }, 'chunkless husk')).toBe(1)
    expect(H.Repli_serve_miss(w, { id: 'quiet', from: 'them', from_idx: 0 }, 'chunkless husk')).toBeFalsy()
    expect(H.Repli_serve_miss(w, { id: 'other', from: 'them', from_idx: 0 }, 'chunkless husk')).toBe(1)
})

test('a materialised record IS servable at its first page — the positive control', async () => {
    const H = await stub_house()
    const shelf = lib('materialised')
    const rec = full(shelf, 'good', 3)
    expect(H.Repli_page_ready(rec, 0, 2)).toBe(true)
    expect(H.Repli_page_ready(rec, 3, 2)).toBe(false)          // past the end is honestly not ready
    expect(H.Heist_body_at(rec, 0)).toBeTruthy()
})

test('PRESENCE IS FILL STATE — a promised chunk with no bytes is not a servable one', async () => {
    const H = await stub_house()
    const shelf = lib('midtranscode')
    // total says 3 and three chunk particles stand, but they hold no bytes yet: the frontier has not
    //  reached them. The right answer is "not ready" (so the want PARKS and is served when it is), not
    //   "ready" — which would ship empty pages and let a sink believe it had the track.
    const rec = full(shelf, 'promised', 3, false)
    expect(+(rec.sc.total || 0)).toBe(3)
    expect(rec.o({ Original: 1 }).length).toBe(3)
    expect(H.Repli_chunk_at(rec, 0)).toBe(null)
    expect(H.Repli_page_ready(rec, 0, 2)).toBe(false)
    // …and this one IS parkable, unlike the husk above: `from < total` is 0 < 3. That is the whole
    //  difference between "wait, bytes are coming" and the silent death the husk caused.
    expect(0 < +(rec.sc.total || 0)).toBe(true)
})

test('the holding set is what makes a body a body — a %Preview is not one', async () => {
    const H = await stub_house()
    const shelf = lib('materialised')
    const rec = shelf.i({ Record: 1, id: 'prev', total: '2' })
    rec.c.up = shelf
    // %Preview/%Stream share the seq space with the whole-file body; counting them as body chunks is how
    //  a heist reads "finished" while the track is only streamable (preview-chunks-are-not-download-progress).
    const p = rec.i({ Preview: 1, seq: '0' }); p.c.up = rec
    expect(H.Heist_has_body(rec)).toBe(0)
    expect(H.Heist_body_at(rec, 0)).toBeFalsy()
    const b = rec.i({ Lossy: 1, seq: '0' }); b.c.up = rec
    expect(H.Heist_has_body(rec)).toBe(1)                      // a graded whole-file chunk counts
})
