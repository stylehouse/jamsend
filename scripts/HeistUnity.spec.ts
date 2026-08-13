// HeistUnity — UNIT TESTS FOR THE UNITY, THE BLAG'S HANDOVER, AND THE HEIST QUEUE (2026-08-13).
//
//  WHY THIS FILE EXISTS AT ALL: everything it covers landed in one day, against a relay with no runner
//   answering, so not one line of it has been seen to run in a browser. A Book could not have covered it
//    either — `Ra_unity_stamp` is humdinger-gated (a new %Record sc key moves every recorded fixture, and
//     there was no runner to re-record them), so inside a Book the unity does not exist. That gate is a
//      holdback, not a design; this file is what stands in for the Book until it can be lifted.
//
//  WHAT IS ACTUALLY PROVABLE HERE: all of it is pure C-tree work — group a shelf by dirname, derive a
//   folder from cards already held, re-point picks from one census onto another, renumber a queue. No
//    disk, no wire, no AudioContext. So a green here is worth having, and it is worth being precise
//     about what it is NOT: proof that any of it is CALLED. The beat wiring (the 40-per-pass unity
//      re-stamp, the ask that now runs beside the blag, the loop that skips a paused keep) is
//       Heist_keep_beat's, and only a live runner proves that.
//
//  THE THREE CLAIMS MOST WORTH A TEST, and why:
//   1. `bytes` MEANS DIFFERENT THINGS ON A %Record AND ON A HUSK. A husk's is the file; a %Record's is
//       the sum of its PREVIEW's opus chunks, tens of times smaller. The first cut of the blag copied
//        one into the other and priced a whole folder at a fraction of itself — silently, since both
//         are plausible integers. `blag prices from src_size` is that bug, pinned.
//   2. THE TWO CENSUSES CANNOT SHARE IDS (source keep-id vs friend content-id), so the handover from a
//       blagged listing to the real one joins on PATH. Get it wrong and a human's ticks either vanish
//        or double-pull the same file. Three shapes: re-pointed, orphaned, already-present.
//   3. A QUEUE NOBODY TOUCHES MUST BEHAVE EXACTLY AS IT DID. `sc.pri` defaults to 0 and the sort is
//       stable, so z-order survives — that is the whole safety argument for putting a sort in the beat.
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/HeistUnity.spec.ts
import { test, expect } from 'vitest'
import { mount } from 'svelte'
import { TheC } from '../src/lib/data/Stuff.svelte'
import Ra from '../src/lib/gen/M/Ra.go'
import Heist from '../src/lib/gen/M/Heist.go'
import Crate from '../src/lib/gen/M/Crate.go'

const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))

// A REAL TheC AS THE HOUSE, not the plain-object stub KeepMemoDurable uses: the blag homes its %BlagLib
//  on `top_House()` (deliberately — see Heist_blag_folder's comment on why `rw` would let the minter and
//   the reader disagree), so the House here has to be able to hold a child. A TheC with `eatfunc` and
//    `top_House` bolted on is exactly that, and the mounted .go's verbs land on it as usual.
async function stub_house(humdinger = true) {
    const H: any = new TheC({ c: {}, sc: { H: 'Mundo' } })
    H.eatfunc = async (obj: any) => { Object.assign(H, obj) }
    H.top_House = () => H
    H.Radio_trace = () => {}
    // `mainkey` is House's, not Ra's or Heist's — and Ra_recs_deep leans on it to prune at a %Record.
    //  Same one-line definition the House carries (CLAUDE.md: a particle's type is the FIRST key of sc).
    H.mainkey = (n: any) => Object.keys(n.sc)[0]
    H.c.humdinger = humdinger ? 1 : 0
    // CRATE IS MOUNTED FOR REAL, not stubbed: `Ra_unity_look` decides what counts as a track with
    //  `Crate_is_audio`, and that is the whole point of the coupling — the unity must count exactly what
    //   the source's own folder census would offer. A stub here would let the two drift and still be green.
    for (const Ghost of [Ra, Heist, Crate]) mount(Ghost, { target: document.body, props: { H } })
    for (let i = 0; i < 80 && !(typeof H.Ra_unity_stamp === 'function'
        && typeof H.Heist_blag_folder === 'function'
        && typeof H.Heist_wire_supersede === 'function'
        && typeof H.Crate_is_audio === 'function'
        && typeof H.Heist_keep_first === 'function'); i++) await sleep(25)
    return H
}

// A NAV THAT ONLY LISTS. `dir_at` → {expand, files:[{name,size}]} is the whole surface Ra_unity_look
//  touches, which is itself the claim: pricing a folder is a STAT, never a read. `asked` records every
//   directory listed so the cap and the TTL are testable as the disk work they are meant to bound.
function fake_nav(tree: Record<string, Array<{ name: string, size?: number | null }>>, opts: any = {}) {
    const asked: string[] = []
    return {
        asked,
        dir_at: async (dir: string) => {
            asked.push(dir)
            if (opts.fail && opts.fail(dir)) throw new Error('no permission')
            const files = tree[dir]
            if (!files) return null
            return { expand: async () => {}, files: files.map((f) => ({ name: f.name, size: f.size === undefined ? 1 : f.size })) }
        },
    }
}

const shelf = (name = 'stock') => new TheC({ c: {}, sc: { [name]: 1 } }) as any
// a %Record as it sits on a shelf — note `bytes` is the PREVIEW weight and `src_size` the file, which is
//  the distinction claim 1 is about. Both are stamped, deliberately, so a test that confuses them fails.
const rec = (shelfC: any, id: string, path: string, extra: any = {}) =>
    shelfC.i({ Record: 1, id, path, bytes: 40000, ...extra })

// ── THE UNITY ──────────────────────────────────────────────────────────────────────────────────────
test('Ra_dir_of splits a crate-relative path, and a bare filename has no folder', async () => {
    const H = await stub_house()
    expect(H.Ra_dir_of('Nick Drake/Pink Moon/01 Pink Moon.flac')).toBe('Nick Drake/Pink Moon')
    expect(H.Ra_dir_of('loose.flac')).toBe('')
    expect(H.Ra_dir_of('')).toBe('')
    // a doubled separator must not invent an empty folder level, or two tracks in one directory would
    //  group apart and each read as a folder of one.
    expect(H.Ra_dir_of('a//b/c.flac')).toBe('a/b')
})

test('Ra_unity_stamp prices each folder from src_size, and counts only its own folder', async () => {
    const H = await stub_house()
    const s = shelf()
    rec(s, 'a1', 'Artist/Album One/1.flac', { src_size: 1000 })
    rec(s, 'a2', 'Artist/Album One/2.flac', { src_size: 2000 })
    rec(s, 'a3', 'Artist/Album One/3.flac', { src_size: 3000 })
    rec(s, 'b1', 'Artist/Album Two/1.flac', { src_size: 500 })

    expect(H.Ra_unity_stamp(s, 0)).toBe(4)
    const by = Object.fromEntries(H.Ra_recs(s).map((r: any) => [r.sc.id, r]))
    expect(+by.a1.sc.un_n).toBe(3)
    expect(+by.a1.sc.un_size).toBe(6000)
    expect(+by.a3.sc.un_n).toBe(3)
    // …and the neighbouring album is NOT folded in — the whole point is that the unity is the folder.
    expect(+by.b1.sc.un_n).toBe(1)
    expect(+by.b1.sc.un_size).toBe(500)
    // WRITES ONLY ON CHANGE: a settled shelf must cost a walk and no bumps, or every beat re-casts the
    //  whole crate to every friend.
    expect(H.Ra_unity_stamp(s, 0)).toBe(0)
})

test('a folder whose cards carry no src_size gets a count but NO size — never a wrong one', async () => {
    const H = await stub_house()
    const s = shelf()
    rec(s, 'x1', 'Old/Album/1.flac')          // `bytes` only: the preview weight, which is not the file
    rec(s, 'x2', 'Old/Album/2.flac')
    H.Ra_unity_stamp(s, 0)
    const r = H.Ra_recs(s)[0]
    expect(+r.sc.un_n).toBe(2)
    // the face says "size unknown" off this absence. Falling back to `bytes` here would have printed a
    //  confident 80KB for an album — the exact failure claim 1 is about, one level up.
    expect('un_size' in r.sc).toBe(false)
})

test('the humdinger gate and the per-pass cap both hold', async () => {
    // a Book must see no unity at all — that is what keeps every recorded fixture still.
    const quiet = await stub_house(false)
    const s0 = shelf()
    rec(s0, 'q1', 'A/B/1.flac', { src_size: 10 })
    expect(quiet.Ra_unity_stamp(s0, 0)).toBe(0)
    expect('un_n' in H_first_rec(quiet, s0).sc).toBe(false)

    // …and the cap exists so the FIRST pass over a standing shelf cannot bump a few hundred records in
    //  one beat, each one re-cast to every friend. Capped runs report the cap, so the caller knows to
    //   come back; the remainder lands on later passes and the shelf converges.
    const H = await stub_house()
    const s = shelf()
    for (let i = 0; i < 25; i++) rec(s, 'c' + i, `A/B/${i}.flac`, { src_size: 100 })
    expect(H.Ra_unity_stamp(s, 10)).toBe(10)
    expect(H.Ra_unity_stamp(s, 10)).toBe(10)
    expect(H.Ra_unity_stamp(s, 10)).toBe(5)
    expect(H.Ra_unity_stamp(s, 10)).toBe(0)
    expect(H.Ra_recs(s).every((r: any) => +r.sc.un_n === 25)).toBe(true)
})

function H_first_rec(H: any, s: any) { return H.Ra_recs(s)[0] }

// ── THE UNITY, PRICED OFF THE DISK ─────────────────────────────────────────────────────────────────
//  THE BUG THESE PIN, in the owner's own words: *"un_n seems always to be 2, the MB size is for only 2
//   (44MB, 2 original flacs)… which is about right for this 68 tracks in one directory four disc album"*,
//    and then the disproof of the old design's whole excuse: *"once I start that supposedly 2 track
//     Heist, it's immediately showing as un_n=68"*.
//  The old `Ra_unity_stamp` counted the radiostock SHELF, on the stated reasoning that an unstocked file
//   cannot be pulled. It can: `Heist_rummage_folder` hands the seed's folder to `Heist_census_heads`,
//    which walks it on disk. So the shelf — a bounded rotating cache with chronological eviction — was
//     being read as a manifest of what is servable, and priced a 476MB album at 44MB. Not a conservative
//      floor: a 10× understatement that arrives BEFORE the describe answers is the number the human sees
//       while deciding, and it is believed precisely because it looks like a measurement.
const dir68 = (n: number, mb: number) =>
    Array.from({ length: n }, (_, i) => ({ name: `${String(i + 1).padStart(2, '0')} Track.flac`, size: mb * 1024 * 1024 }))

test('THE OWNER\'S NUMBER: 2 stocked of a 68-track folder prices the FOLDER, not the shelf', async () => {
    const H = await stub_house()
    const s = shelf()
    // exactly the reported shape: two originals warm on the shelf, 22MB each, out of a 68-track album.
    rec(s, 'k1', 'Transient/0 Latin/Evolution Of Dub/Disk 4/01 Track.flac', { src_size: 22 * 1024 * 1024 })
    rec(s, 'k2', 'Transient/0 Latin/Evolution Of Dub/Disk 4/02 Track.flac', { src_size: 22 * 1024 * 1024 })
    const nav = fake_nav({ 'Transient/0 Latin/Evolution Of Dub/Disk 4': dir68(68, 7) })

    const census = await H.Ra_unity_look(s, nav, 4)
    expect(H.Ra_unity_stamp(s, 0, census)).toBe(2)
    const r = H_first_rec(H, s)
    expect(+r.sc.un_n).toBe(68)                       // was 2 — the whole report
    expect(+r.sc.un_size).toBe(68 * 7 * 1024 * 1024)  // was 44MB for a 476MB album
    // …and it says so: `un_d` is the POSITIVE mark, "I counted my disk". See the next test for why the
    //  flag has to name the good case rather than the bad one.
    expect(r.sc.un_d).toBe(1)
})

test('the ATTESTATION is positive — absence must mean unattested, not "fine"', async () => {
    const H = await stub_house()
    const s = shelf()
    rec(s, 'p1', 'Priced/Album/1.flac', { src_size: 100 })
    rec(s, 'g1', 'Guessed/Album/1.flac', { src_size: 100 })
    // one folder lists, the other refuses (a permission blip, an unmounted drive, a rename mid-beat).
    const nav = fake_nav({ 'Priced/Album': dir68(5, 1) }, { fail: (d: string) => d === 'Guessed/Album' })

    const census = await H.Ra_unity_look(s, nav, 8)
    H.Ra_unity_stamp(s, 0, census)
    const by = Object.fromEntries(H.Ra_recs(s).map((r: any) => [r.sc.id, r]))
    expect(+by.p1.sc.un_n).toBe(5)
    expect(by.p1.sc.un_d).toBe(1)             // counted
    // THE FALLBACK MUST NOT BE A ZERO. Caching {n:0} for a folder that would not list, and then letting a
    //  10-minute TTL defend it, turns a momentary blip into a durable "this album is empty".
    expect(+by.g1.sc.un_n).toBe(1)
    // …and it carries NO attestation. THIS IS THE POLARITY CLAIM, and it is the whole reason the flag
    //  exists: these numbers are stamped by the SOURCE and ride the card to a reader on another machine
    //   running another build. A flag marking the GUESS would be absent on exactly the builds that most
    //    need catching — a peer on yesterday's code sends a shelf-derived 2 and no flag at all, and a
    //     reader distrusting only the flag would trust it completely. So the mark names the GOOD case,
    //      and absence means unattested. A new capability announces itself; old code cannot announce.
    expect('un_d' in by.g1.sc).toBe(false)
    // and once the disk does answer, the mark goes ON — 1-or-absent, never a snapped 0.
    const nav2 = fake_nav({ 'Priced/Album': dir68(5, 1), 'Guessed/Album': dir68(9, 1) })
    H.Ra_unity_stamp(s, 0, await H.Ra_unity_look(s, nav2, 8))
    expect(+by.g1.sc.un_n).toBe(9)
    expect(by.g1.sc.un_d).toBe(1)
})

test('a folder is a STAT per folder, capped per pass and believed for a TTL', async () => {
    const H = await stub_house()
    const s = shelf()
    const tree: any = {}
    for (let i = 0; i < 6; i++) {
        rec(s, 'd' + i, `D${i}/1.flac`, { src_size: 10 })
        tree[`D${i}`] = dir68(3, 1)
    }
    const nav = fake_nav(tree)

    // ONE LISTING PER FOLDER, never per record, and never the breadth-first walk of the whole crate that
    //  Crate_nav_meander's no-enumeration law forbids on a 200k-track share. The cap bounds a beat.
    await H.Ra_unity_look(s, nav, 2)
    expect(nav.asked.length).toBe(2)
    await H.Ra_unity_look(s, nav, 2)
    expect(nav.asked.length).toBe(4)
    const census = await H.Ra_unity_look(s, nav, 2)
    expect(nav.asked.length).toBe(6)
    expect(Object.keys(census).length).toBe(6)
    // …and a settled shelf then costs NOTHING: the TTL is what keeps this off the disk every beat forever.
    await H.Ra_unity_look(s, nav, 2)
    expect(nav.asked.length).toBe(6)
    // a capped pass still stamps what it already knows — it does not wait for the whole shelf to be priced.
    expect(H.Ra_unity_stamp(s, 0, census)).toBe(6)
    expect(H.Ra_recs(s).every((r: any) => +r.sc.un_n === 3)).toBe(true)
})

test('the census counts what a heist could actually take — audio only, sizes only when all are known', async () => {
    const H = await stub_house()
    // COVER ART IS NOT A TRACK. The filter is Crate's, the same one the source's own census applies, so a
    //  unity of 12 and a folder offering 12 are the same 12. Counting the folder.jpg would inflate every
    //   album by one and price it with an image's bytes.
    const c = H.Ra_unity_census([
        { path: 'A/1.flac', bytes: 10 },
        { path: 'A/2.flac', bytes: 20 },
        { path: 'B/1.flac', bytes: 5 },
    ])
    expect(c['A']).toEqual({ n: 2, size: 30, unknown: 0 })
    expect(c['B'].n).toBe(1)

    const H2 = await stub_house()
    const s = shelf()
    rec(s, 'm1', 'Mixed/Album/1.flac', { src_size: 100 })
    const nav = fake_nav({ 'Mixed/Album': [
        { name: '01.flac', size: 1000 },
        { name: '02.flac', size: 2000 },
        { name: 'folder.jpg', size: 999999 },
        { name: 'notes.txt', size: 50 },
    ] })
    H2.Ra_unity_stamp(s, 0, await H2.Ra_unity_look(s, nav, 4))
    expect(+H_first_rec(H2, s).sc.un_n).toBe(2)
    expect(+H_first_rec(H2, s).sc.un_size).toBe(3000)

    // A PARTLY-KNOWN FOLDER GETS NO SIZE AT ALL. A backend that maps bare names (RemoteWormholeNav) hands
    //  back nulls; summing the ones it did know would produce a confident understatement, which is the
    //   exact failure this whole change exists to remove. Absent, readers fall back; short, they believe it.
    const H3 = await stub_house()
    const s3 = shelf()
    rec(s3, 'u1', 'Unknown/Album/1.flac', { src_size: 100 })
    const nav3 = fake_nav({ 'Unknown/Album': [
        { name: '01.flac', size: 1000 },
        { name: '02.flac', size: null },
    ] })
    H3.Ra_unity_stamp(s3, 0, await H3.Ra_unity_look(s3, nav3, 4))
    expect(+H_first_rec(H3, s3).sc.un_n).toBe(2)
    expect('un_size' in H_first_rec(H3, s3).sc).toBe(false)
})

test('Ra_unity_dirs is the work list — distinct folders, not records', async () => {
    const H = await stub_house()
    const s = shelf()
    rec(s, 'a', 'One/Album/1.flac')
    rec(s, 'b', 'One/Album/2.flac')
    rec(s, 'c', 'One/Album/3.flac')
    rec(s, 'd', 'Two/Album/1.flac')
    rec(s, 'e', 'loose.flac')
    // 5 records, 3 folders: this collapse is why pricing off the disk is affordable on a share beat at all.
    expect(H.Ra_unity_dirs(s)).toEqual(['One/Album', 'Two/Album', ''])
})

// ── THE BLAG ───────────────────────────────────────────────────────────────────────────────────────
test('the blag derives the seed\'s folder from cards we already hold, and prices it from src_size', async () => {
    const H = await stub_house()
    const mir = shelf('MusuThem')
    rec(mir, 'SEED', 'Artist/Album/2.flac', { src_size: 7_000_000, title: 'Two', un_n: 3, un_size: 21_000_000 })
    rec(mir, 'sib1', 'Artist/Album/1.flac', { src_size: 6_000_000, title: 'One' })
    rec(mir, 'sib3', 'Artist/Album/3.flac', { src_size: 8_000_000, title: 'Three' })
    rec(mir, 'other', 'Artist/Other Album/1.flac', { src_size: 999 })

    expect(H.Heist_blag_folder(mir, 'SEED')).toBe(3)     // the folder, not the shelf
    const husks = H.Heist_rummage_recs(mir, 'SEED')
    expect(husks.length).toBe(3)
    expect(husks.every((h: any) => h.sc.blag === 1)).toBe(true)
    // CLAIM 1, PINNED: a husk's `bytes` is the FILE. Copying the %Record's `bytes` (the preview weight,
    //  40000 above) across is the bug — it priced this 21MB album at 120KB and called it a total.
    const seedHusk = husks.find((h: any) => h.sc.id === 'SEED')
    expect(+seedHusk.sc.bytes).toBe(7_000_000)
    expect(+seedHusk.sc.src_size).toBe(7_000_000)
    // the heard track marks itself `re:<content-id>` exactly as the wire census would, so the defaulters
    //  spot it among its siblings without knowing which route built the list.
    expect(seedHusk.sc.re).toBe('SEED')

    // …and the unity read off the SEED's own card is the number that lets a short listing know it is short.
    //  `d` rides with it: this card was stamped by a friend, and whether THEY counted their disk or just
    //   guessed it from their shelf is not something we can re-derive here — it has to travel with the number.
    expect(H.Heist_unity_of(mir, 'SEED')).toEqual({ n: 3, size: 21_000_000, d: 0 })
    expect(H.Heist_unity_of(mir, 'nosuch')).toEqual({ n: 0, size: 0 })

    H.Heist_blag_drop('SEED')
    expect(H.Heist_rummage_recs(mir, 'SEED').length).toBe(0)
})

test('the WIRE census wins whenever it exists — and is what the ask must gate on', async () => {
    const H = await stub_house()
    const mir = shelf('MusuThem')
    rec(mir, 'SEED', 'Artist/Album/2.flac', { src_size: 10 })
    H.Heist_blag_folder(mir, 'SEED')
    // with only a blag in hand, the blended list is populated but the WIRE list is empty — and that
    //  difference is the whole fix: gating the describe-ask on the blended list is what made one husk
    //   we happened to hold count as a complete answer, so the ask never went out.
    expect(H.Heist_rummage_recs(mir, 'SEED').length).toBe(1)
    expect(H.Heist_rummage_wire(mir, 'SEED').length).toBe(0)

    // the source answers: tagged husks land on the mirror itself, and now both lists agree.
    rec(mir, 'KEEP_A', 'Artist/Album/1.flac', { rummage: 'SEED' })
    rec(mir, 'KEEP_B', 'Artist/Album/2.flac', { rummage: 'SEED' })
    expect(H.Heist_rummage_wire(mir, 'SEED').length).toBe(2)
    expect(H.Heist_rummage_recs(mir, 'SEED').length).toBe(2)
    // a multi-valued tag matches by membership, not equality — one husk can serve two heists.
    rec(mir, 'KEEP_C', 'Artist/Album/3.flac', { rummage: 'SEED,OTHER' })
    expect(H.Heist_rummage_wire(mir, 'OTHER').length).toBe(1)
})

// ── THE HANDOVER (claim 2) ─────────────────────────────────────────────────────────────────────────
test('supersede re-points blagged picks onto their wire twins BY PATH, and drops the rest', async () => {
    const H = await stub_house()
    const mir = shelf('MusuThem')
    const shop: any = new TheC({ c: {}, sc: { Shop: 1 } })
    const keep = shop.i({ Heist: 'Album', seed: 'SEED', pub: 'them', state: 'primed' })
    keep.c.up = shop

    // what the human ticked while the blag stood: three content-id picks.
    keep.i({ Pick: 1, ref: 'cid1', path: 'Artist/Album/1.flac', blag: 1 })
    keep.i({ Pick: 1, ref: 'cid2', path: 'Artist/Album/2.flac', blag: 1 })
    keep.i({ Pick: 1, ref: 'gone', path: 'Artist/Album/9.flac', blag: 1 })
    // …and one ordinary wire pick that was already there, sharing a path with a blagged one. The
    //  defaulters can legitimately produce this: they adopt wire husks on the same beat.
    keep.i({ Pick: 1, ref: 'KEEP_2', path: 'Artist/Album/2.flac' })

    // the source's answer: keep-ids, and no track 9 — they do not have it.
    rec(mir, 'KEEP_1', 'Artist/Album/1.flac', { rummage: 'SEED', src_size: 1234 })
    rec(mir, 'KEEP_2', 'Artist/Album/2.flac', { rummage: 'SEED' })

    expect(H.Heist_wire_supersede(keep, mir, 'SEED')).toBe(1)
    const refs = keep.o({ Pick: 1 }).map((p: any) => String(p.sc.ref)).sort()
    // cid1 became KEEP_1 (re-pointed, mark dropped, weight picked up); cid2 collapsed into the wire pick
    //  that already held its path — NOT left beside it, which would pull the same file twice; `gone` is
    //   dropped, because the source has just said that file is not there.
    expect(refs).toEqual(['KEEP_1', 'KEEP_2'])
    const one = keep.o({ Pick: 1, ref: 'KEEP_1' })[0]
    expect('blag' in one.sc).toBe(false)
    expect(+one.sc.src_size).toBe(1234)
    expect(keep.o({ Pick: 1, blag: 1 }).length).toBe(0)

    // ONCE ONLY, and the blag is SPENT rather than merely cleared: `blagged = 0` re-opened the mint gate
    //  in the beat, so the next pass re-derived the guess it had just superseded, every beat until the
    //   3-try ceiling caught it.
    expect(H.Heist_wire_supersede(keep, mir, 'SEED')).toBe(0)
    expect(keep.c.blag_tries).toBe(9)
})

// ── THE QUEUE (claim 3) ────────────────────────────────────────────────────────────────────────────
test('Heist_keep_first renumbers 0..n-1 and leaves everyone else in their existing order', async () => {
    const H = await stub_house()
    const shop: any = new TheC({ c: {}, sc: { Shop: 1 } })
    const mk = (s: string) => { const k = shop.i({ Heist: s, seed: s }); k.c.up = shop; return k }
    const a = mk('A'), b = mk('B'), c = mk('C')

    // NOBODY HAS TOUCHED THE QUEUE: every pri is absent, so the beat's stable sort is pure z-order and
    //  a world that never reorders behaves exactly as it always did. This is the safety argument.
    const order = (): string[] => shop.o({ Heist: 1 }).slice()
        .sort((x: any, y: any) => (+(x.sc.pri || 0)) - (+(y.sc.pri || 0)))
        .map((k: any) => String(k.sc.seed))
    expect(order()).toEqual(['A', 'B', 'C'])

    expect(H.Heist_keep_first(c)).toBe(1)
    expect(order()).toEqual(['C', 'A', 'B'])
    expect([a, b, c].map(k => +(k.sc.pri || 0))).toEqual([1, 2, 0])
    // …and the one at the head carries NO key: 0 is written as absent, so only the keeps actually
    //  displaced grow one and a shop nobody reordered snaps exactly as it did before this existed.
    expect('pri' in c.sc).toBe(false)

    // promoting again is total, not relative — no ever-shrinking number to bound.
    H.Heist_keep_first(b)
    expect(order()).toEqual(['B', 'C', 'A'])
    expect([a, b, c].map(k => +(k.sc.pri || 0))).toEqual([2, 0, 1])
    expect('pri' in b.sc).toBe(false)
    expect(+c.sc.pri).toBe(1)
    // …and promoting the one already first changes nothing at all.
    H.Heist_keep_first(b)
    expect(order()).toEqual(['B', 'C', 'A'])
})

test('pause is a FLAG, 1-or-absent, and resume restores the state it left', async () => {
    const H = await stub_house()
    const shop: any = new TheC({ c: {}, sc: { Shop: 1 } })
    const keep = shop.i({ Heist: 'A', seed: 'A', state: 'pulling' })
    keep.c.up = shop

    expect(H.Heist_keep_pause(keep)).toBe(1)
    expect(keep.sc.paused).toBe(1)
    // THE STATE IS UNTOUCHED, which is the reason this is a flag and not a `paused` state: a state would
    //  have to remember what to go back to, and a Berth resume would have to trust that memory.
    expect(keep.sc.state).toBe('pulling')
    expect(H.Heist_keep_pause(keep)).toBe(0)             // idempotent

    expect(H.Heist_keep_resume(keep)).toBe(1)
    // ABSENT, not `0` — a JS boolean does not snap cleanly, and a `paused: 0` in a Berth entry would
    //  read back as a truthy string on the next resume and silently park the heist forever.
    expect('paused' in keep.sc).toBe(false)
    expect(keep.sc.state).toBe('pulling')
    expect(H.Heist_keep_resume(keep)).toBe(0)
})
