// PoolKeep — UNIT TESTS FOR THE POOL'S CANDIDATE DRAW AND ITS ONE-TRACK KEEP, no runner and no wire.
//
//  WHY THIS FILE EXISTS.  Two of the four faults that kept SoundPooling dark for days live in pure logic
//   over particles, and both were found by reading a live console rather than a red test:
//
//    · THE REACH STORM.  A friend's `%Theirs` mirror carries not only their stocked tracks but the
//       `husk,rummage` rows a folder DESCRIBE left behind — the listing of a folder someone browsed and
//        never stocked.  The pool draw ranked those like tracks and booked fills for them; the holder's
//         verdict consults its Mine only, so 17 of 18 reaches came back `not_in_library` at roughly four
//          reaches a second, forever.  A candidate must be something the holder actually stocked.
//
//    · THE KEEP THAT NEVER PULLED.  A pool keep is minted with `seed` = the holder's Mine/opus id, but its
//       %Picks are minted by the folder census under the holder's RUMMAGE ids; the seed appears only as
//        the mirror record's `re:`.  `Heist_keep_solo` looked for a pick whose `ref === seed`, found none,
//         answered -1 ("the seed's husk hasn't landed — wait"), and the keep sat `primed` with all
//          eighteen folder siblings attached, forever.
//
//  NO BOOK CAN REACH THE SECOND ONE (pool-keep-rummage-alias): a Book hand-mints its mirror, so a record's
//   id IS the seed and the two id-spaces collapse.  The alias only exists against a live holder whose
//    folder was rummaged.  A unit spec CAN build both id-spaces by hand, which is what this does.
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/PoolKeep.spec.ts
import { test, expect } from 'vitest'
import { mount } from 'svelte'
import { TheC } from '../src/lib/data/Stuff.svelte'
import Ra from '../src/lib/gen/M/Ra.go'
import Heist from '../src/lib/gen/M/Heist.go'
import Repli from '../src/lib/gen/N/Repli.go'

const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))

async function stub_house() {
    const H: any = {
        c: {},
        sc: {},
        async eatfunc(obj: any) { Object.assign(H, obj) },
        top_House() { return H },
        Radio_trace(_n: any, _m: any) {},
    }
    for (const Ghost of [Ra, Repli, Heist]) mount(Ghost, { target: document.body, props: { H } })
    for (let i = 0; i < 80 && typeof H.Heist_keep_pool_go !== 'function'; i++) await sleep(25)
    return H
}

const world = () => new TheC({ c: {}, sc: { w: 'Pool' } }) as any

// a friend's mirror: `%Theirs,pub` → `stock` → the records they have offered us.
function theirs(w: any, pub: string) {
    const t = w.i({ Theirs: 1, pub })
    t.c.up = w
    const stock = t.i({ stock: 1 })
    stock.c.up = t
    return stock
}
function stocked(stock: any, id: string, title: string) {
    const r = stock.i({ Record: 1, id, title })
    r.c.up = stock
    return r
}
// the residue of a folder describe: identity and path, marked husk + rummage. NOT a source.
function browsed(stock: any, id: string, seed: string) {
    const r = stock.i({ Record: 1, id, husk: 1, rummage: seed, path: 'x/' + id + '.flac' })
    r.c.up = stock
    return r
}

test('THE REACH STORM: browsed husks are not pool candidates — only what a holder stocked', async () => {
    const H = await stub_house()
    const w = world()
    const stock = theirs(w, 'holder')
    stocked(stock, 'real1', 'A Real Track')
    stocked(stock, 'real2', 'Another Real Track')
    // the shape that produced 17 refusals out of 18: a described folder's siblings sitting in the mirror.
    for (let i = 0; i < 6; i++) browsed(stock, 'browsed' + i, 'seedfolder')

    const out = H.Ra_pool_sources(w)
    expect(out.length).toBe(2)
    expect(out.map((r: any) => r.id).sort()).toEqual(['real1', 'real2'])
    expect(out.every((r: any) => r.from === 'holder')).toBe(true)
    // …and nothing marked husk or rummage survived the draw, however many of them there are.
    expect(out.some((r: any) => String(r.id).startsWith('browsed'))).toBe(false)
})

test('a mirror with no stock shelf is skipped without minting one — a read never creates', async () => {
    const H = await stub_house()
    const w = world()
    const bare = w.i({ Theirs: 1, pub: 'quiet' })
    bare.c.up = w
    expect(H.Ra_pool_sources(w)).toEqual([])
    expect(bare.o({ stock: 1 }).length).toBe(0)      // probe-first: the draw did not mint a shelf
})

// ── the keep ────────────────────────────────────────────────────────────────────────────────────────
function keep_with(w: any, seed: string, picks: string[], into = 'pool') {
    const shop = w.i({ shop: 1 })
    shop.c.up = w
    const k = shop.i({ Heist: 'A Track', seed, pub: 'holder', state: 'primed', into })
    k.c.up = shop
    for (const ref of picks) { const p = k.i({ Pick: 1, ref }); p.c.up = k }
    return k
}
// the holder's mirror, carrying BOTH id-spaces: the rummage-id record wears `re:<seed>`.
function srcmir_with(w: any, seed: string, rummage: string) {
    const mir = w.i({ Theirs: 1, pub: 'holder-mirror' })
    mir.c.up = w
    const r = mir.i({ Record: 1, id: rummage, re: seed, title: 'A Track' })
    r.c.up = mir
    return mir
}

test('THE ALIAS: a keep whose picks wear RUMMAGE ids still solos, via the mirror\'s re:<seed>', async () => {
    const H = await stub_house()
    const w = world()
    const SEED = '00bfacb6523d2149'          // the holder's Mine/opus id — what the reach asked by
    const RUMM = '64a77aae9db0b1a7'          // the folder census id — what the picks actually wear
    const keep = keep_with(w, SEED, [RUMM, 'sib1', 'sib2', 'sib3'])
    const srcmir = srcmir_with(w, SEED, RUMM)

    // solo by the SEED alone cannot see the pick — this is the -1 that stalled it for hours.
    expect(H.Heist_keep_solo(keep, SEED)).toBe(-1)
    expect(keep.o({ Pick: 1 }).length).toBe(4)

    // pool_go resolves seed → pick through the mirror (`srcmir` was passed all along and never read).
    expect(H.Heist_keep_pool_go(keep, srcmir, SEED)).toBe(1)
    expect(String(keep.sc.state)).toBe('pulling')
    const left = keep.o({ Pick: 1 })
    expect(left.length).toBe(1)                       // "a pool takes the track, not the album"
    expect(String(left[0].sc.ref)).toBe(RUMM)         // and the pick keeps the id it was minted under
    expect(String(keep.sc.lofi)).toBe('1')            // a pool copy is a rendition, always
})

test('the plain case still works — a pick already wearing the seed needs no alias', async () => {
    const H = await stub_house()
    const w = world()
    const SEED = 'seed-is-the-pick'
    const keep = keep_with(w, SEED, [SEED, 'sib1', 'sib2'])
    expect(H.Heist_keep_pool_go(keep, null, SEED)).toBe(1)
    expect(keep.o({ Pick: 1 }).length).toBe(1)
    expect(String(keep.o({ Pick: 1 })[0].sc.ref)).toBe(SEED)
    expect(String(keep.sc.state)).toBe('pulling')
})

test('a keep whose seed is nowhere WAITS — it must not solo down to a wrong track', async () => {
    const H = await stub_house()
    const w = world()
    const keep = keep_with(w, 'absent-seed', ['other1', 'other2'])
    const srcmir = srcmir_with(w, 'a-different-seed', 'other1')
    expect(H.Heist_keep_pool_go(keep, srcmir, 'absent-seed')).toBe(0)
    expect(String(keep.sc.state)).toBe('primed')      // still waiting, not pulling
    expect(keep.o({ Pick: 1 }).length).toBe(2)        // and nothing was cut on a guess
})

test('only a POOL keep is pooled — a plain heist is left entirely alone', async () => {
    const H = await stub_house()
    const w = world()
    const keep = keep_with(w, 'x', ['x', 'y'], 'library')
    expect(H.Heist_keep_pool_go(keep, null, 'x')).toBe(0)
    expect(keep.o({ Pick: 1 }).length).toBe(2)
    expect(keep.sc.lofi).toBeFalsy()                  // lofi is the POOL's rule, not a heist's
})
