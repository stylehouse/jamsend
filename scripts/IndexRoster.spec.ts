// IndexRoster — Atlas rosters from the index Waft instead of walking the tree.
//
//  The other half of `StatusWaft.spec.ts`: that one proves the dev server WRITES a Waft the tab's
//   decoder can read; this proves Atlas READS it and gets a roster out of it — one `read_file` and a
//    decode in place of ~50 FSA directory listings spread across belief ticks (Docindex_todo).
//
//  IT USES A FAKE NAV ON PURPOSE.  The real one is an FSA handle that exists only in a browser tab,
//   and the whole point of the change is that Atlas now asks it for exactly ONE file — which is a
//    contract worth pinning: this nav records every call, so a regression that quietly reintroduces a
//     directory walk fails here rather than being discovered as a slow tab three weeks later.
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/IndexRoster.spec.ts
import { test, expect, beforeAll } from 'vitest'
import { mount } from 'svelte'
import Story_cli from './Story_cli.svelte'
import AtlasGo from '../src/lib/gen/L/Atlas.go'
import { status_waft } from '../src/lib/server/dige'

const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))
const ROOT = process.cwd()
let H: any

beforeAll(async () => {
    mount(Story_cli, { target: document.body, props: { onhouse: (h: any) => { H = h } } })
    for (let i = 0; i < 80 && !H?.started; i++) await sleep(50)
    mount(AtlasGo as any, { target: document.body, props: { H } })
    for (let i = 0; i < 80 && typeof H.Atlas_index_read !== 'function'; i++) await sleep(50)
    expect(typeof H.Atlas_index_read, 'the Atlas ghost deposited').toBe('function')
}, 30_000)

// a nav that answers exactly one file and REMEMBERS what it was asked — the walk-detector
function fake_nav(snap: string | null) {
    const calls: string[] = []
    return {
        calls,
        async read_file(dir: string, name: string) { calls.push(`read_file ${dir}/${name}`); return snap },
        async dir_at(p: string) { calls.push(`dir_at ${p}`); return null },
    }
}

function world() {
    const top = H.top_House()
    for (const old of top.o({ A: 'IdxTest' })) top.drop(old)
    return top.i({ A: 'IdxTest' }).i({ w: 'IdxTest' })
}

test('the roster comes out of the Waft — and NOTHING walked', async () => {
    const { snap, docs } = status_waft(ROOT, ['Ghost', 'scripts'])
    const w = world()
    const nav = fake_nav(snap)
    const n = await H.Atlas_index_read(w, nav)
    expect(n, 'every doc in the index became a %Doc row').toBe(docs)
    expect(w.o({ Doc: 1 }).length).toBe(docs)
    // the contract that matters: ONE read, and not a single directory listing
    expect(nav.calls).toEqual(['read_file wormhole/Docindex/toc.snap'])
})

test('mtime/size land on .c and the diges land where the adopt reads them', async () => {
    const { snap } = status_waft(ROOT, ['Ghost'])
    const w = world()
    await H.Atlas_index_read(w, fake_nav(snap))
    const doc = w.o({ Doc: 'Ghost/L/Atlas.g' })[0]
    expect(doc, 'a known file rostered').toBeTruthy()
    // mtime+size ride on .c — a cache, not truth, and never snapped (Atlas's own rule)
    expect(typeof doc.c.mtime, 'mtime is a number on .c').toBe('number')
    expect(doc.c.mtime).toBeGreaterThan(0)
    expect(typeof doc.c.size).toBe('number')
    expect(doc.sc.mtime, 'and NOT in sc, or every snap would churn on every touch').toBeUndefined()
    // dige_of is the map Atlas_cache_adopt corroborates against; asked_diges latched means the
    //  HTTP dige endpoint is not even tried on a tab that has the Waft
    expect(w.c.dige_of['Ghost/L/Atlas.g'][0]).toMatch(/^[0-9a-f]{16}$/)
    expect(w.c.dige_of['Ghost/L/Atlas.g'][1], 'the tuple is [dige, mtime, size]').toBe(doc.c.mtime)
    expect(w.c.asked_diges, 'the served-dige road is latched off').toBe(1)
})

test('a Testing doc is stamped from the index too — the border survives the new road', async () => {
    const { snap } = status_waft(ROOT, ['Ghost'])
    const w = world()
    await H.Atlas_index_read(w, fake_nav(snap))
    expect(w.o({ Doc: 'Ghost/Story/VoroTesting.g' })[0]?.sc.testing, '⚗ still stamped').toBe(1)
    expect(w.o({ Doc: 'Ghost/L/Atlas.g' })[0]?.sc.testing, 'and only on Testing docs').toBeUndefined()
})

// EVERY WAY IT CAN FAIL RETURNS 0, because 0 is what makes the caller fall back to the walk.  A throw
//  here would take the whole roster down on a tab that simply has no dev server.
test('no index, an unreadable one, or junk ⇒ 0 and the walk still happens', async () => {
    expect(await H.Atlas_index_read(world(), fake_nav(null)), 'no file').toBe(0)
    expect(await H.Atlas_index_read(world(), fake_nav('')), 'empty file').toBe(0)
    expect(await H.Atlas_index_read(world(), fake_nav('not a snap at all')), 'junk').toBe(0)
    expect(await H.Atlas_index_read(world(), fake_nav('Waft:Docindex\n')), 'a Waft with no docs').toBe(0)
    const thrower = { async read_file() { throw new Error('FSA said no') } }
    expect(await H.Atlas_index_read(world(), thrower), 'a nav that throws').toBe(0)
    expect(await H.Atlas_index_read(world(), null), 'no nav at all').toBe(0)
})

// ── THE REFRESH CONTRACT ─────────────────────────────────────────────────────────────────────────
//  Every `atlas_*` query runs `Atlas_refresh` first ("USE NUDGES A PASS"), and a refresh was a full
//   recursive FSA walk of every root — so the tree was re-listed on each `lagoon lint`, each
//    `atlas_callers`, each query of any kind.  The index answers all three of a refresh's questions
//     from one file read, but only if it answers them the SAME WAY the walk did: `refresh_added` for
//      new docs, `by` un-stamped on movers, and a `seen` set complete enough for `gone` to be computed
//       by comparison.  Get the last one wrong and a refresh silently DROPS live docs from the census.
const snap_of = (rows: Array<[string, string, number, number]>) =>
    'Waft:Docindex\n' + rows.map(([p, d, m, s]) => `  Doc:${p},dige:${d},mtime=${m},size=${s}`).join('\n') + '\n'

test('refresh: a doc the census has never seen counts as ADDED', async () => {
    const w = world()
    await H.Atlas_index_read(w, fake_nav(snap_of([['a/one.g', 'a'.repeat(16), 100, 10]])), 0, null)
    w.c.refresh_added = 0
    const seen: any = {}
    await H.Atlas_index_read(w, fake_nav(snap_of([
        ['a/one.g', 'a'.repeat(16), 100, 10],
        ['a/two.g', 'b'.repeat(16), 200, 20],
    ])), 1, seen)
    expect(w.c.refresh_added, 'exactly the new one').toBe(1)
    expect(Object.keys(seen).sort(), 'seen is COMPLETE — this is what `gone` is computed against').toEqual(['a/one.g', 'a/two.g'])
})

test('refresh: a mover is un-stamped so the pass re-maps it — and only the mover', async () => {
    const w = world()
    await H.Atlas_index_read(w, fake_nav(snap_of([
        ['a/one.g', 'a'.repeat(16), 100, 10],
        ['a/two.g', 'b'.repeat(16), 200, 20],
    ])), 0, null)
    // both settled under the current mapper, as a mapped census would be
    for (const d of w.o({ Doc: 1 })) d.sc.by = 'm15'
    w.c.refresh_changed = 0
    // two.g moved on disk; one.g did not
    await H.Atlas_index_read(w, fake_nav(snap_of([
        ['a/one.g', 'a'.repeat(16), 100, 10],
        ['a/two.g', 'c'.repeat(16), 999, 21],
    ])), 1, {})
    expect(w.c.refresh_changed).toBe(1)
    expect(w.o({ Doc: 'a/two.g' })[0].sc.by, 'the mover is un-stamped, so it re-maps').toBeUndefined()
    expect(w.o({ Doc: 'a/one.g' })[0].sc.by, 'the settled one is left alone').toBe('m15')
    // the Map is deliberately NOT dropped here — a stale answer beats a missing one for a query
    //  landing between the un-stamp and the re-map (Atlas_walk makes the same ruling)
})

test('refresh: a doc that left the corpus is absent from `seen`, which is how gone is found', async () => {
    const w = world()
    await H.Atlas_index_read(w, fake_nav(snap_of([
        ['a/one.g', 'a'.repeat(16), 100, 10],
        ['a/gone.g', 'b'.repeat(16), 200, 20],
    ])), 0, null)
    const seen: any = {}
    await H.Atlas_index_read(w, fake_nav(snap_of([['a/one.g', 'a'.repeat(16), 100, 10]])), 1, seen)
    expect(seen['a/gone.g'], 'the departed doc is not seen').toBeUndefined()
    expect(w.o({ Doc: 'a/gone.g' }).length, 'the row still stands — dropping it is Atlas_refresh’s call, not this one').toBe(1)
})
