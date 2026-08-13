// Newlyadded — UNIT TESTS FOR THE DOWNLOAD LEDGER: the Mag join, and the rename that must not eat 177 rows.
//
//  WHAT CHANGED (2026-08-13, Mag_todo §11).  Three things at once, and each has a way of going wrong that
//   looks like nothing at all until a real collection is involved:
//    1. `%Probation` → `%Got`.  A mainkey rename on a document that ALREADY EXISTS ON THE OWNER'S DISK
//        with 177+ rows in it.  The failure mode is silent doubling: the reader stops seeing the old rows,
//         the writer's idempotence guard stops recognising them, and the first time each old path comes
//          past again it is logged afresh — a ledger that quietly says you downloaded everything twice.
//    2. `id:` — the Mag join to the landed holding, stamped from the `rec.sc.id` that
//        `Heist_catalog_land` has in hand one line later.  The failure mode is a blind stamp: a caller
//         without a record writes `undefined` into sc and the encoder brands the line `{"undef":["id"]}`
//          (CLAUDE.md — an undef in a snap is a MINT bug, not furniture).
//    3. `feeling` deleted.  It had no user-reachable writer; the only caller of `Heist_feel` in the whole
//        tree was a Book step.
//
//  WHY THESE ARE UNIT-TESTABLE AND WORTH IT.  The ledger's reader/writer are pure functions of a Waft —
//   a real TheC Waft IS the disk here, since `Heist_newlyadded_note` mints onto the tree BEFORE the
//    `Berth_append` IO, so stubbing that one seam inert leaves a faithful document to read straight back.
//     No runner, no FSA nav, no Book.  And a Book could NOT cover the migration claim anyway: a Book
//      sweeps its marrauding root every run, so it never has a legacy row to trip over.  The only place
//       the old shape and the new shape meet is a real collection — and this file.
//
//  WHAT A GREEN HERE IS NOT: proof that a landing ever calls this (that is Heist_catalog_land's wiring,
//   which MusuHeist covers), nor that a write reaches real disk (needs an FSA nav).
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/Newlyadded.spec.ts
import { test, expect } from 'vitest'
import { mount } from 'svelte'
import { TheC } from '../src/lib/data/Stuff.svelte'
import Ra from '../src/lib/gen/M/Ra.go'
import Swarm from '../src/lib/gen/S/Swarm.go'
import Repli from '../src/lib/gen/N/Repli.go'
import Heist from '../src/lib/gen/M/Heist.go'

const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))

// the KeepMemoDurable stub-House trick: a .go is a Svelte component whose onMount eatfuncs its verbs onto
//  H, so mounting against a stub gives the REAL compiled methods. Then we override exactly two seams —
//   the Waft open (so every call shares one in-memory "disk") and the append (so no IO happens).
async function stub_house(waft: any) {
    const H: any = {
        c: {},
        sc: {},
        async eatfunc(obj: any) { Object.assign(H, obj) },
        top_House() { return H },
        Radio_trace() {},
    }
    for (const Ghost of [Ra, Swarm, Repli, Heist]) mount(Ghost, { target: document.body, props: { H } })
    for (let i = 0; i < 80 && !(typeof H.Heist_newlyadded_note === 'function'
        && typeof H.Heist_newlyadded_rows === 'function'
        && typeof H.Heist_newlyadded_grouped === 'function'); i++) await sleep(25)
    H.Heist_newlyadded_waft = async () => waft
    H.Berth_append = async () => 1
    H.Berth_save = async () => {}
    return H
}

const ledger = () => new TheC({ c: {}, sc: { Waft: 'berth/Newlyadded' } }) as any
// a row in the OLD shape, exactly as it sits in the owner's toc.snap today.
const legacy = (waft: any, of: string, seq: number, feeling = 'fresh') => {
    const card = waft.i({ Probation: 1, of, seq: String(seq) })
    card.c.up = waft
    card.sc.feeling = feeling
    const cut = of.split('/'); cut.pop()
    if (cut.length) card.sc.dir = cut.join('/')
    return card
}

const ALBUM = '0 Latin/va - Evolution Of Dub/Disk 4'

// ── THE MAG JOIN ───────────────────────────────────────────────────────────────────────────────────
test('a landing carries BOTH the live join and the durable path', async () => {
    const waft = ledger()
    const H = await stub_house(waft)

    await H.Heist_newlyadded_note(null, '/music', `${ALBUM}/01 Loving Tonight.ogg`, null, '9f3a2c1e88b04d17')

    const rows = H.Heist_newlyadded_rows(waft)
    expect(rows.length).toBe(1)
    // the durable fact — the exact path, character for character. It must survive the holding's death,
    //  so it is NOT replaced by the id, it sits beside it (Mag_todo §11.3).
    expect(rows[0].sc.of).toBe(`${ALBUM}/01 Loving Tonight.ogg`)
    // the live join — 16 chars, the same content-id the holding is keyed by in the collection.
    expect(rows[0].sc.id).toBe('9f3a2c1e88b04d17')
    expect(rows[0].sc.dir).toBe(ALBUM)
    // and the feeling is gone, not merely unread
    expect(rows[0].sc.feeling).toBeUndefined()
})

test('a caller with no record in hand writes a truthful row, never an `undef` marker', async () => {
    const waft = ledger()
    const H = await stub_house(waft)

    // Heist_resume_sync's backfill replays paths off disk with no rec — the row is honestly unjoined.
    await H.Heist_newlyadded_note(null, '/music', `${ALBUM}/02 Reggae Style.ogg`)

    const rows = H.Heist_newlyadded_rows(waft)
    expect(rows.length).toBe(1)
    expect(rows[0].sc.of).toBe(`${ALBUM}/02 Reggae Style.ogg`)
    // ABSENT, not the string "undefined" and not an own key holding undefined: `i({id: rec.sc.id})` on a
    //  record without one brands the encoded line `{"undef":["id"]}`, which is a mint bug in a snap.
    expect('id' in rows[0].sc).toBe(false)
})

// ── THE RENAME, AND THE 177 ROWS IT MUST NOT EAT ───────────────────────────────────────────────────
test('a LEGACY %Probation row for a path blocks a duplicate %Got for the same path', async () => {
    const waft = ledger()
    const H = await stub_house(waft)
    legacy(waft, `${ALBUM}/01 Loving Tonight.ogg`, 1)

    // the same path comes past again — a resume re-verifying an already-landed pick, which is the
    //  everyday case, not an edge one.
    await H.Heist_newlyadded_note(null, '/music', `${ALBUM}/01 Loving Tonight.ogg`, null, '9f3a2c1e88b04d17')

    // ONE row, still the legacy one. Without the %Probation arm of the guard this is 2, and every one of
    //  the owner's 177 rows doubles the first time its path is seen again.
    expect(H.Heist_newlyadded_rows(waft).length).toBe(1)
    expect(waft.o({ Got: 1 }).length).toBe(0)
})

test('a replayed landing in the CURRENT shape does not double-log either', async () => {
    const waft = ledger()
    const H = await stub_house(waft)
    const p = `${ALBUM}/03 Dubwise.ogg`

    await H.Heist_newlyadded_note(null, '/music', p, null, 'aaaa1111bbbb2222')
    await H.Heist_newlyadded_note(null, '/music', p, null, 'aaaa1111bbbb2222')

    expect(H.Heist_newlyadded_rows(waft).length).toBe(1)
})

test('the reader returns legacy and current rows TOGETHER, in arrival order', async () => {
    const waft = ledger()
    const H = await stub_house(waft)
    legacy(waft, `${ALBUM}/01 Loving Tonight.ogg`, 1)
    legacy(waft, `${ALBUM}/02 Reggae Style.ogg`, 2)
    await H.Heist_newlyadded_note(null, '/music', `${ALBUM}/03 Dubwise.ogg`, null, 'cccc3333dddd4444')

    const list = await H.Heist_newlyadded_list(null, '/music')
    // the old rows did not vanish when the mainkey changed — read both, write one.
    expect(list.map((c: any) => String(c.sc.of).split('/').pop())).toEqual(
        ['01 Loving Tonight.ogg', '02 Reggae Style.ogg', '03 Dubwise.ogg'])
})

test('seq counts across BOTH shapes, so a new arrival after legacy rows is not seq 1 again', async () => {
    const waft = ledger()
    const H = await stub_house(waft)
    legacy(waft, `${ALBUM}/01 Loving Tonight.ogg`, 1)
    legacy(waft, `${ALBUM}/02 Reggae Style.ogg`, 2)

    await H.Heist_newlyadded_note(null, '/music', `${ALBUM}/03 Dubwise.ogg`, null, 'cccc3333dddd4444')

    const got = waft.o({ Got: 1 })
    expect(got.length).toBe(1)
    // counting only %Got would restart the ordinal at 1 and put the newest arrival FIRST in every
    //  seq-sorted read — a ledger that reorders itself the day it is renamed.
    expect(got[0].sc.seq).toBe('3')
})

// ── THE DIRECTORY IS THE UNIT ──────────────────────────────────────────────────────────────────────
test('grouping folds a whole album into one row, mixing shapes, and carries no feeling', async () => {
    const waft = ledger()
    const H = await stub_house(waft)
    legacy(waft, `${ALBUM}/01 Loving Tonight.ogg`, 1, 'love')
    await H.Heist_newlyadded_note(null, '/music', `${ALBUM}/02 Reggae Style.ogg`, null, 'bbbb2222cccc3333')
    await H.Heist_newlyadded_note(null, '/music', 'loose track.ogg', null, 'dddd4444eeee5555')

    const groups = await H.Heist_newlyadded_grouped(null, '/music')
    expect(groups.length).toBe(2)
    expect(groups[0].dir).toBe(ALBUM)
    expect(groups[0].cards.length).toBe(2)
    // a dir-less file stays its own row — "the whole directory of what we got" cannot invent a directory
    //  for something that landed loose.
    expect(groups[1].dir).toBe('')
    expect(groups[1].cards.length).toBe(1)
    expect('feeling' in groups[0]).toBe(false)
})

test('TWO loose files stay two rows — the empty dir is not a folder they share', async () => {
    const waft = ledger()
    const H = await stub_house(waft)
    await H.Heist_newlyadded_note(null, '/music', 'first loose.ogg', null, 'aaaa0000aaaa0000')
    await H.Heist_newlyadded_note(null, '/music', 'second loose.ogg', null, 'bbbb0000bbbb0000')

    const groups = await H.Heist_newlyadded_grouped(null, '/music')
    // caught by mutation: folding dir-less cards through the same `groups[dir]` map as real folders LOOKS
    //  right with one loose file and silently merges every loose file in the collection into a single
    //   phantom album. Heist_haul_look already knows this (it keys a loose row by its path, "so two loose
    //    files stay two rows") — the grouping underneath it has to agree.
    expect(groups.length).toBe(2)
    expect(groups.map((g: any) => g.cards.length)).toEqual([1, 1])
})

// ── THE VERB THAT WENT, AND THE ONE THAT DID NOT ───────────────────────────────────────────────────
test('Heist_feel is gone and Heist_scrub_one is not', async () => {
    const H = await stub_house(ledger())
    // the opinion verb had exactly one caller in the tree (a Book step) and is deleted…
    expect(typeof H.Heist_feel).toBe('undefined')
    // …but the destructive capability it wrapped is genuinely reached by Heist_keep_cancel, so it stays.
    //  These two travelled together for a session; asserting both is what stops a later tidy-up from
    //   taking the wrong one.
    expect(typeof H.Heist_scrub_one).toBe('function')
})

// ── THE 2026-08-14 REVIEW FINDINGS ─────────────────────────────────────────────────────────────────
test('a folder called __proto__ groups like any other and does not poison the ledger', async () => {
    const waft = ledger()
    const H = await stub_house(waft)
    // `dir` is a FOLDER NAME OFF A FRIEND'S DISK. `Heist_rel_for` sanitises `..` traversal and nothing
    //  else, so a prototype key can reach here. With a plain object literal `if (!groups[dir])` reads
    //   Object.prototype — truthy — the init is skipped and `.cards.push` throws. The row is on DISK, so
    //    that one card would re-throw on every slow-beat Heist_haul_look and every reload, for ever:
    //     the What-Heisted list simply stops. Found by review, not by a Book — no fixture has such a name.
    await H.Heist_newlyadded_note(null, '/music', '__proto__/01 a.ogg', null, 'aaaa1111aaaa1111')
    await H.Heist_newlyadded_note(null, '/music', '__proto__/02 b.ogg', null, 'bbbb2222bbbb2222')
    await H.Heist_newlyadded_note(null, '/music', 'constructor/03 c.ogg', null, 'cccc3333cccc3333')

    const groups = await H.Heist_newlyadded_grouped(null, '/music')
    expect(groups.length).toBe(2)
    expect(groups[0].dir).toBe('__proto__')
    expect(groups[0].cards.length).toBe(2)
    expect(groups[1].dir).toBe('constructor')
    expect(groups[1].cards.length).toBe(1)
})

test('a replay HEALS an unjoined row instead of leaving it unjoinable for ever', async () => {
    const waft = ledger()
    const H = await stub_house(waft)
    // every legacy %Probation row predates `id:`, and a resume-backfill %Got row has none either. The
    //  guard returns on a replay — so without healing, the one landing that COULD supply the id walks
    //   straight past the row that needs it, every time, and the join never happens.
    legacy(waft, `${ALBUM}/01 Loving Tonight.ogg`, 1)
    await H.Heist_newlyadded_note(null, '/music', `${ALBUM}/01 Loving Tonight.ogg`, null, '9f3a2c1e88b04d17')

    const rows = H.Heist_newlyadded_rows(waft)
    expect(rows.length).toBe(1)                       // healed IN PLACE — still no duplicate
    expect(rows[0].sc.id).toBe('9f3a2c1e88b04d17')
    expect(rows[0].sc.seq).toBe('1')                  // …and its arrival ordinal is untouched
})

test('healing never overwrites an id that is already there, nor invents one', async () => {
    const waft = ledger()
    const H = await stub_house(waft)
    const p = `${ALBUM}/04 Steady.ogg`
    await H.Heist_newlyadded_note(null, '/music', p, null, 'first111first111')
    // a re-landing of different bytes must not silently re-point an existing join…
    await H.Heist_newlyadded_note(null, '/music', p, null, 'second22second22')
    expect(H.Heist_newlyadded_rows(waft)[0].sc.id).toBe('first111first111')

    // …and a replay with no id in hand must not stamp `undefined` onto an unjoined row.
    const q = `${ALBUM}/05 Loose.ogg`
    await H.Heist_newlyadded_note(null, '/music', q)
    await H.Heist_newlyadded_note(null, '/music', q)
    const row = H.Heist_newlyadded_rows(waft).find((c: any) => c.sc.of === q)
    expect('id' in row.sc).toBe(false)
})
