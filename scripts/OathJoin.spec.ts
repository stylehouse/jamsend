// OathJoin.spec.ts — THE OATH CONSTELLATION's gate (Lagoon_todo §0, 2026-11-09).
//  Two halves, each pinned headless on hand-made input:
//   · the SITE collector (compile.ts, ATLAS_MAPPER m18): a `story_swear(w, '…')` becomes %proves,sentence,sworn,via — an escaped
//      quote stays in the sentence, a doc's one-line swear wrapper (`let say = (s) => { this.story_swear(w, s) }`) counts, and a
//       template or variable sentence does not (the join reports it as declared-only instead of guessing);
//   · the JOIN (Lagoon_oath_join): site · declaration (a Book toc's Assertion lines, plain and JSON) · citation («slug») in one row
//      per sentence, the three lopsided shapes, and a Book's EXERCISE — what its own `<Book>_*` methods call outside the Testing docs.
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/OathJoin.spec.ts
import { test, expect, beforeAll } from 'vitest'
import { mount } from 'svelte'
import { EditorState } from '@codemirror/state'
import { lang, lang_for_path } from '../src/lib/O/lang/lang'
import Story_cli from './Story_cli.svelte'
import LagoonGo from '../src/lib/gen/L/Lagoon.go'

const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))
let H: any

beforeAll(async () => {
    mount(Story_cli, { target: document.body, props: { onhouse: (h: any) => { H = h } } })
    for (let i = 0; i < 80 && !(H?.started && typeof H.Lang_map_into === 'function'); i++) await sleep(50)
    expect(typeof H?.Lang_map_into, 'Lang ghost deposited').toBe('function')
    mount(LagoonGo as any, { target: document.body, props: { H } })
    for (let i = 0; i < 80 && typeof H.Lagoon_oath_join !== 'function'; i++) await sleep(50)
    expect(typeof H.Lagoon_oath_join, 'Lagoon ghost deposited').toBe('function')
}, 30_000)

const TESTING = `Fixa_witness(w):
    this.story_swear(w, 'a plain oath holds')
    this.story_swear(w, 'the people\\'s oath keeps its quote')
    this.story_swear(w, "a double-quoted oath holds")
    this.story_swear(w, \`a template oath \${1} is not known\`)
    this.story_swear(w, sentence)
    // this.story_swear(w, 'a commented oath is not a site')
    let say = (s) => { this.story_swear(w, s) }
    say('a wrapped oath holds')
`

async function sites(text: string, path = 'Ghost/Story/FixaTesting.g') {
    const exts  = await lang(lang_for_path(path))
    const state = EditorState.create({ doc: text, extensions: exts })
    const job   = H.i({ probe: 'oath_' + Math.random().toString(36).slice(2) })
    H.Lang_map_into(state, job, path)
    const map = job.o({ Map: 1 })[0]
    return (map ? map.o({ proves: 1, sworn: 1 }) : []).map((p: any) => ({ ...p.sc }))
}

test('the site collector — literal swears, escapes and wrappers; never a template, a variable or a comment', async () => {
    const got = await sites(TESTING)
    expect(got.map(p => p.sentence)).toEqual([
        'a plain oath holds',
        "the people's oath keeps its quote",
        'a double-quoted oath holds',
        'a wrapped oath holds',
    ])
    expect(got.every(p => p.via === 'Fixa_witness'), 'every site carries its enclosing def').toBe(true)
})

// ── the join, over a hand-made census and a nav that serves two Book tocs ─────────────────────────────
const TOCS: Record<string, string> = {
    Fixa: `The
  step,dige:aa
  step=2,desc:one,dige:bb
    Assertion:a-plain-oath,sentence:a plain oath holds
    {"Assertion":"a-comma-oath","sentence":"a comma, in an oath"}
  step=3,desc:two,dige:cc
    Assertion:a-declared-oath,sentence:a declared oath no code says
`,
    Fixb: `The
  step,dige:dd
    Assertion:a-plain-oath,sentence:a plain oath holds
`,
}
const nav = {
    dir_at: async (p: string) => p === 'wormhole/Story'
        ? { expand: async () => {}, directories: Object.keys(TOCS).map(name => ({ name })) } : null,
    read_file: async (dir: string, f: string) => f === 'toc.snap' ? TOCS[dir.split('/').pop()!] ?? null : null,
}

function census() {
    const top = H.top_House()
    for (const old of top.o({ A: 'Atlas' })) top.drop(old)
    for (const old of top.o({ A: 'Lagoon' })) top.drop(old)
    const aw = top.i({ A: 'Atlas' }).i({ w: 'Atlas' })
    const lw = top.i({ A: 'Lagoon' }).i({ w: 'Lagoon' })
    const t = aw.i({ Doc: 'Ghost/Story/FixaTesting.g' })
    t.sc.testing = 1
    const tm = t.i({ Map: 1 })
    tm.i({ proves: 1, sworn: 1, sentence: 'a plain oath holds', line: 4, via: 'Fixa_witness' })
    tm.i({ proves: 1, sworn: 1, sentence: 'a comma, in an oath', line: 5, via: 'Fixa_witness' })
    tm.i({ proves: 1, sworn: 1, sentence: 'an oath no Book declares', line: 6, via: 'Fixc_witness' })
    tm.i({ call: 1, method: 'Ghosty_go', via: 'Fixa_beat', line: 9 })
    tm.i({ call: 1, method: 'Ghosty_other', via: 'Fixc_beat', line: 10 })
    tm.i({ call: 1, method: 'Fixa_helper', via: 'Fixa_beat', line: 11 })
    const g = aw.i({ Doc: 'Ghost/M/Ghosty.g' })
    const gm = g.i({ Map: 1 })
    gm.i({ def: 1, method: 'Ghosty_go', line: 1 })
    gm.i({ def: 1, method: 'Ghosty_other', line: 5 })
    const md = aw.i({ Doc: 'src/lib/O/spec/Fixa_todo.md' })
    md.i({ Map: 1 }).i({ link: 1, kind: 'sworn', target: 'a-plain-oath', line: 3 })
    return lw
}

test('the toc parser — plain and JSON Assertion lines, each under its step', () => {
    expect(H.Lagoon_toc_oaths(TOCS.Fixa)).toEqual([
        { step: 2, slug: 'a-plain-oath', sentence: 'a plain oath holds' },
        { step: 2, slug: 'a-comma-oath', sentence: 'a comma, in an oath' },
        { step: 3, slug: 'a-declared-oath', sentence: 'a declared oath no code says' },
    ])
    expect(H.Lagoon_toc_oaths(TOCS.Fixb)).toEqual([{ step: 1, slug: 'a-plain-oath', sentence: 'a plain oath holds' }])
})

test('the join — one row per sentence, its three sightings, the three shapes', async () => {
    const r = await H.Lagoon_oath_join(census(), nav, '', 0)
    expect(r.tally).toEqual({ oaths: 4, whole: 2, site_only: 1, declared_only: 1, cited: 1 })
    const row = (s: string) => r.rows.find((x: any) => x.sentence === s)
    const plain = row('a plain oath holds')
    expect(plain.shape).toBe('whole')
    expect(plain.books.map((b: any) => `${b.book}@${b.step}`).sort()).toEqual(['Fixa@2', 'Fixb@1'])
    expect(plain.sites).toEqual([{ doc: 'Ghost/Story/FixaTesting.g', line: 4, via: 'Fixa_witness' }])
    expect(plain.cited).toEqual([{ slug: 'a-plain-oath', doc: 'src/lib/O/spec/Fixa_todo.md', line: 3 }])
    expect(row('a comma, in an oath').shape, 'a JSON-encoded Assertion joins like a plain one').toBe('whole')
    expect(row('an oath no Book declares').shape).toBe('site_only')
    expect(row('a declared oath no code says').shape).toBe('declared_only')
})

test('exercise — a method answers with the Books whose own methods call it, never a neighbour Book in the same doc', async () => {
    const r = await H.Lagoon_oath_join(census(), nav, 'Ghosty_go', 0)
    expect(r.home).toBe('Ghost/M/Ghosty.g')
    expect(r.exercised_by).toEqual(['Fixa'])
    expect(r.rows.map((x: any) => x.sentence).sort()).toEqual(['a comma, in an oath', 'a declared oath no code says', 'a plain oath holds'])
    // Fixc calls Ghosty_other from the same Testing doc, but declares nothing — so no Book exercises it
    expect((await H.Lagoon_oath_join(census(), nav, 'Ghosty_other', 0)).exercised_by).toEqual([])
})
