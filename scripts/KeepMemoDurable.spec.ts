// KeepMemoDurable — UNIT TESTS FOR THE DURABLE KEEP-MEMO AND THE A3 RE-MATERIALISE CONTRACT.
//  (fork C, Composition_todo §0c / §0.3: "the landings no Book touches".)
//
//  WHY THIS FILE, BESIDE SupplyGuards.spec.ts (they do NOT overlap — read this before adding here):
//   SupplyGuards proves the RUNTIME half of the lofi recipe — Heist_keep_remember → Heist_reheal_id over
//    `w.c.keep_memo`, plus Ra_pcm_admit's floors. That map dies with the page. This file proves the two
//     seams SupplyGuards only NAMES in a comment ("which is what Ra's A3 re-materialise reads"):
//      1. THE DURABLE %Keepsake MIRROR — flush → rehydrate ACROSS a process restart. The whole reason
//          the memo went to disk (Heist.go:1502): a keep-id is sha256(pub+base+path), one-way, so the
//           (id → base+path) map is the one fact a restarted source cannot recompute. Lose it and
//            Repli_serve_want misses an id it served a minute ago while BOTH ends look healthy — this
//             codebase's signature failure (see the memory note `a-hopeless-serve-looks-exactly-like-a-
//              slow-one`). Durability is also what makes the lofi bug REACHABLE more often (reheal fires
//               more), so the rendition claim must survive the disk round-trip 1-or-absent, never as `0`.
//      2. Ra's A3 RE-MATERIALISE (Ra.go:2435-2449) is a composition claim and belongs to MusuNeGrind —
//          but its load-bearing CONTRACT is Heist_materialise_one's mode-aware early-out
//           `(!!rec.sc.lofi) === (!!lofi)` (Heist.go:1333). That IS unit-testable: a match reuses the
//            standing bytes; a mismatch releases and re-reads. The lofi-pass fix (`rec.sc.lofi ? 1 : 0`,
//             Ra.go:2446) exists precisely so a lofi husk is not needlessly released and re-read.
//
//  WHY IT NEEDS NO RUNNER: the mirror is a Waft of %Keepsake rows, and a real TheC Waft IS the disk for
//   this test. flush MINTS its rows with `waft.oai(...)` BEFORE the append IO, so stubbing the only IO
//    seam (Berth_append / Berth_save) inert still leaves a faithful mirror to read straight back.
//
//  WHAT THIS IS NOT: proof the beat CALLS any of this — Heist_keep_memo_beat gates on
//   `top_House().c.humdinger` and that wiring is MusuNeGrind's; nor proof a write LANDS on real disk
//    (that needs an FSA nav). Read a green here as "the recipe survives a round-trip and the A3 early-out
//     is rendition-aware", not "durability works end to end".
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/KeepMemoDurable.spec.ts
import { test, expect } from 'vitest'
import { mount } from 'svelte'
import { TheC } from '../src/lib/data/Stuff.svelte'
import Ra from '../src/lib/gen/M/Ra.go'
import Swarm from '../src/lib/gen/S/Swarm.go'
import Repli from '../src/lib/gen/N/Repli.go'
import Heist from '../src/lib/gen/M/Heist.go'

const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))

// A STUB HOUSE (the SupplyGuards trick): a .go is a Svelte component whose onMount eatfuncs its verbs
//  onto H, so mounting against a stub gives the REAL compiled methods bound to the stub. The ONE thing
//   we override afterwards is the disk IO: Berth_append/Berth_save must not reach a real FSA nav. flush
//    mints its %Keepsake rows on the Waft before calling them, so a no-op append is a faithful "disk".
async function stub_house() {
    const H: any = {
        c: {},
        sc: {},
        traces: [] as any[],
        async eatfunc(obj: any) { Object.assign(H, obj) },
        top_House() { return H },
        Radio_trace(_n: any, m: any) { H.traces.push(m) },
    }
    for (const Ghost of [Ra, Swarm, Repli, Heist]) mount(Ghost, { target: document.body, props: { H } })
    for (let i = 0; i < 80 && !(typeof H.Heist_keep_memo_rehydrate === 'function'
        && typeof H.Heist_keep_memo_flush === 'function'
        && typeof H.Heist_materialise_one === 'function'
        && typeof H.Heist_reheal_id === 'function'); i++) await sleep(25)
    // inert IO — assign AFTER the mount so it wins over the real eatfunc'd verbs.
    H.Berth_append = async () => {}
    H.Berth_save = async () => {}
    return H
}

const world = () => new TheC({ c: {}, sc: { w: 'Music' } }) as any
const waft = () => new TheC({ c: {}, sc: { Waft: 'KeepMemo' } }) as any
// a materialised rec as Heist_keep_remember reads it: id + path are mandatory (the recipe cannot rebuild
//  without a path), the rest is the promise it memoises.
const matrec = (id: string, extra: any = {}) =>
    new TheC({ c: {}, sc: { Record: 1, id, path: `crate/${id}.flac`, total: '24', body_hash: `H_${id}`, ...extra } }) as any

// ── SEAM 3: THE DURABLE ROUND-TRIP ─────────────────────────────────────────────────────────────────
test('a lofi recipe survives remember → flush → (restart) → rehydrate → reheal, 1-or-absent throughout', async () => {
    const H = await stub_house()

    // process A learns two recipes: one lofi rendition, one original.
    const wA = world()
    H.Heist_keep_remember(wA, matrec('lofiD', { lofi: 1 }), 'base1')
    H.Heist_keep_remember(wA, matrec('origD'), 'base1')

    // flush mirrors both to the shared "disk" (a real Waft). The rendition claim rides 1-or-ABSENT:
    //  a `0` here does not snap cleanly and would heal a lofi keep back as its ORIGINAL.
    const disk = waft()
    expect(await H.Heist_keep_memo_flush(wA, disk, {})).toBe(2)
    const rows = Object.fromEntries(disk.o({ Keepsake: 1 }).map((r: any) => [r.sc.id, r]))
    expect(rows.lofiD.sc.lofi).toBe(1)
    expect('lofi' in rows.origD.sc).toBe(false)     // absent, NOT `0` — the whole boolean rule
    // flush clears only what it wrote, so a second flush is a no-op rather than a re-write.
    expect(await H.Heist_keep_memo_flush(wA, disk, {})).toBe(0)

    // process B is a FRESH world (the daemon restart / OOM the durable rail exists for) that has learned
    //  nothing: without the mirror it could not answer either id. It reads the mirror back...
    const wB = world()
    expect(H.Heist_keep_memo_rehydrate(wB, disk)).toBe(2)
    expect(wB.c.keep_memo.lofiD.lofi).toBe(1)
    expect(wB.c.keep_memo.origD.lofi).toBeUndefined()

    // ...and now reheals an id it never served this life, with the rendition claim intact — which is
    //  exactly what Ra's A3 re-materialise reads to fetch the ogg rather than the original.
    const back = H.Heist_reheal_id(wB, 'lofiD')
    expect(back, 'reheal rebuilt a husk from the disk-restored recipe').toBeTruthy()
    expect(back.sc.lofi).toBe(1)
    expect(back.sc.body_hash).toBe('H_lofiD')
    expect(+back.sc.total).toBe(24)
    // the negative half matters as much: an original healed back must NOT sprout a lofi claim, or A3
    //  hunts an .ogg that was never made.
    expect(H.Heist_reheal_id(wB, 'origD').sc.lofi).toBeUndefined()
})

test('rehydrate REFUSES a half-row — a husk with a total but no body_hash parks forever', async () => {
    const H = await stub_house()
    const disk = waft()
    // a complete recipe...
    disk.i({ Keepsake: 1, id: 'whole', path: 'a/b.flac', total: '10', body_hash: 'HH', ts: '2' })
    // ...and three that Heist_reheal_id could never satisfy: A3's gate is `body_hash && total > 0`.
    disk.i({ Keepsake: 1, id: 'no_hash', path: 'a/c.flac', total: '10', ts: '3' })
    disk.i({ Keepsake: 1, id: 'no_path', total: '10', body_hash: 'JJ', ts: '4' })
    disk.i({ Keepsake: 1, id: 'no_total', path: 'a/d.flac', body_hash: 'KK', ts: '5' })

    const w = world()
    expect(H.Heist_keep_memo_rehydrate(w, disk)).toBe(1)
    expect(w.c.keep_memo.whole).toBeTruthy()
    expect(w.c.keep_memo.no_hash).toBeUndefined()
    expect(w.c.keep_memo.no_path).toBeUndefined()
    expect(w.c.keep_memo.no_total).toBeUndefined()
})

test('rehydrate: a recipe learned THIS session outranks its disk row, and the read is once-only', async () => {
    const H = await stub_house()
    const disk = waft()
    disk.i({ Keepsake: 1, id: 'shared', path: 'disk/old.flac', total: '10', body_hash: 'DISK', ts: '1' })

    const w = world()
    // this session already read the real file a moment ago — that promise beats a row an earlier
    //  incarnation wrote, so the disk row must NOT clobber it.
    H.Heist_keep_remember(w, matrec('shared', { body_hash: 'FRESH' }), 'b')
    expect(H.Heist_keep_memo_rehydrate(w, disk)).toBe(0)             // nothing NEW folded
    expect(w.c.keep_memo.shared.body_hash).toBe('FRESH')            // the fresh promise stands, not DISK

    // the read latch: a second rehydrate is a no-op even though the map has room and rows exist.
    const w2 = world()
    expect(H.Heist_keep_memo_rehydrate(w2, disk)).toBe(1)
    expect(H.Heist_keep_memo_rehydrate(w2, disk)).toBe(0)
})

test('rehydrate caps ON THE WAY IN, keeping the newest — a shelf grown under an older bound cannot flood', async () => {
    const H = await stub_house()
    const disk = waft()
    const CAP = H.Heist_keep_memo_cap()                              // 400
    const N = CAP + 2
    // ascending ts, so ids 0..N-1 are oldest..newest. Two over the bound.
    for (let i = 0; i < N; i++)
        disk.i({ Keepsake: 1, id: `k${i}`, path: `p/${i}.flac`, total: '5', body_hash: `h${i}`, ts: String(i) })

    const w = world()
    expect(H.Heist_keep_memo_rehydrate(w, disk)).toBe(CAP)
    // the two OLDEST fell off the front; the newest is kept.
    expect(w.c.keep_memo.k0).toBeUndefined()
    expect(w.c.keep_memo.k1).toBeUndefined()
    expect(w.c.keep_memo[`k${N - 1}`]).toBeTruthy()
})

// ── SEAM 3: THE FLUSH WRITE CONTRACT ───────────────────────────────────────────────────────────────
test('flush writes guarded stamps only — an absent field never becomes an {"undef"} row', async () => {
    const H = await stub_house()
    const w = world()
    // a bare recipe: id + path + the promise, no tag metadata, and a share-ROOT base ('') — the exact
    //  case the base guard exists for (a falsy '' must reconstruct as absent, not stamp an undef row).
    H.Heist_keep_remember(w, matrec('bare'), '')
    const disk = waft()
    expect(await H.Heist_keep_memo_flush(w, disk, {})).toBe(1)
    const row = disk.o({ Keepsake: 1 })[0]
    // the mandatory recipe fields are present...
    expect(row.sc.path).toBe('crate/bare.flac')
    expect(+row.sc.total).toBe(24)
    expect(row.sc.body_hash).toBe('H_bare')
    // ...and the absent ones are ABSENT, not stamped `undefined` (which the encoder brands {"undef":[…]},
    //  an honest marker of a sloppy mint — a bug, not furniture).
    for (const k of ['title', 'artist', 'album', 'genre', 'ext', 'lofi', 'base'])
        expect(k in row.sc, `${k} must be absent, not undef`).toBe(false)
})

test('flush skips a dirty id whose memo entry was culled between mark and flush, and clears its dirt', async () => {
    const H = await stub_house()
    const w = world()
    H.Heist_keep_remember(w, matrec('real'), 'b')
    // a phantom: marked dirty but with no recipe behind it (the memo cap can drop an id between the
    //  end-of-materialise mark and the next beat's flush). It must be dropped from the dirty set, not
    //   written as a broken row.
    w.c.keep_memo_dirty.ghost = 1
    const disk = waft()
    expect(await H.Heist_keep_memo_flush(w, disk, {})).toBe(1)       // only `real` written
    expect(disk.oa({ Keepsake: 1, id: 'ghost' })).toBeFalsy()
    expect(w.c.keep_memo_dirty.ghost).toBeUndefined()               // and its dirt is cleared
    expect(w.c.keep_memo_dirty.real).toBeUndefined()
})

// ── SEAM 4: THE A3 RE-MATERIALISE CONTRACT (Heist_materialise_one's mode-aware early-out) ───────────
// A "full" rec: Heist_has_body counts %Original + %Lossy children, so one Original child with total:1
//  makes has_body >= total. Ra_rec_find locates it as a direct child of a lib listed in w.c.rummage_libs
//   — the found-rec branch reaches the early-out at Heist.go:1333 without ever touching `nav`.
function full_rec(lib: any, id: string, lofi?: 1) {
    const rec = lib.i(lofi ? { Record: 1, id, total: '1', body_hash: 'H', lofi: 1 } : { Record: 1, id, total: '1', body_hash: 'H' })
    rec.i({ Original: 1 })
    return rec
}

test('A3 early-out reuses the standing bytes when the rendition MATCHES the ask', async () => {
    const H = await stub_house()
    const w = world()
    const lib = w.i({ RummageLib: 'L' })
    const rec = full_rec(lib, 'R', 1)
    w.c.rummage_libs = [lib]
    // a lofi ask over a full lofi rec: `(!!lofi)===(!!lofi)` ⇒ return the SAME rec, no release, no read.
    //  nav is `{}` (truthy) and is proved unused: the standing bytes are never dropped.
    const out = await H.Heist_materialise_one(w, {}, 'me', 'R', 1)
    expect(out).toBe(rec)
    expect(rec.c.released).toBeUndefined()
    expect(H.Heist_has_body(rec)).toBe(1)
})

test('A3 does NOT reuse across a rendition MISMATCH — it releases and re-reads (the bug the lofi-pass fix prevents)', async () => {
    const H = await stub_house()
    const w = world()
    const lib = w.i({ RummageLib: 'L' })
    const rec = full_rec(lib, 'R', 1)
    w.c.rummage_libs = [lib]
    // an ORIGINAL ask over a full LOFI rec: `(!!1)===(!!0)` is false ⇒ fall through, release the bytes,
    //  re-materialise. This is exactly why Ra.go:2446 threads `rec.sc.lofi ? 1 : 0` instead of omitting
    //   it — omitting it made EVERY lofi rec take this needless release+re-read and park against a hash
    //    that could never match. The re-read then needs a real nav, so we only assert the release seam.
    try { await H.Heist_materialise_one(w, {}, 'me', 'R', 0) } catch { /* the whole-file read has no FSA nav */ }
    expect(rec.c.released, 'mismatch must fall past the early-out and release the standing bytes').toBeTruthy()
    expect(H.Heist_has_body(rec)).toBe(0)
})
