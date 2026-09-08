// LinkKinds — the collector gate for the markdown doc-link vocabulary (`compile.ts`'s
//  `Lang_collect_markdown_regions` sweep).  No runner, no browser, no relay: this boots the same
//   headless machine LocalGen uses, hands the REAL collector a document, and reads the `%link` rows
//    back off the `%Map` it builds.
//
//  WHY IT IS A SPEC AND NOT A BOOK.  A collector is a pure function of text — same bytes in, same rows
//   out — so there is no world to stand, nothing to converge, and no timing to get wrong.  (The same
//    reasoning that put `role:hacker` in `HackerRole.spec.ts`.)  What DOES need a live runner is the
//     census built on top of it, and that is Atlas's business, not this file's.
//
//  WHAT IT PINS.  Six link kinds now: `wiki`, `file`, `code` and — 2026-09-08, `ATLAS_MAPPER` m15 —
//   `sect`, `book`, `sworn`.  Every one of the three new ones is a regex whose whole job is to be
//    NARROWER than the obvious version, because the corpus punished the obvious version twice already
//     (bare `Name.ext` mentions in the 2026-09-05 census, backticked words without an underscore in
//      m14).  So the assertions below are as much about what must NOT be collected as what must.
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/LinkKinds.spec.ts
import { test, expect } from 'vitest'
import { mount } from 'svelte'
import { readFileSync, readdirSync } from 'node:fs'
import path from 'node:path'
import { EditorState } from '@codemirror/state'
import { lang, lang_for_path } from '../src/lib/O/lang/lang'
import Story_cli from './Story_cli.svelte'

const ROOT  = process.cwd()
const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))

// the fixture is a DOCUMENT, not a string of tokens: the sweep runs per line over a parsed markdown
//  tree, so the traps only bite in context (a § after an English word, a heading on the same line as
//   a link, a placeholder inside prose about the format).
const DOC = `# 0. A fixture

See Lagoon_todo §2.7 and Stemdex_todo.md §0 for the census, and spec/Radio_circuit_todo.md §1 too.
An older single-word doc still qualifies when it wears its extension: Frontier.md §1.
The corpus usually code-spans the name, so \`Voro_render_todo.md\` §0 must qualify too.
Elsewhere in this doc, see §9 and the §3 above; in §5 it is spelled out.
The gate is Book:LagoonStaple and the older Book=LakeSurprise.
It swears «the-reader-kept-nothing», which is printed as «slug» in the docs.
An ordinary [[wiki-slug]] and a pointer at compile.ts:250, plus a \`Lagoon_callers\` mention.

## 2.7 A numbered section
`

let H: any
async function boot() {
    if (H) return H
    mount(Story_cli, { target: document.body, props: { onhouse: (h: any) => { H = h } } })
    for (let i = 0; i < 80 && !(H && typeof H.Lang_collect_markdown_regions === 'function'); i++) await sleep(50)
    expect(typeof H?.Lang_collect_markdown_regions, 'Lang ghost deposited').toBe('function')
    return H
}

// collect — the real path Atlas_map_one takes, minus the disk: build the CodeMirror state for a .md
//  and let the collector write its %Map onto a throwaway particle.
async function collect(text: string, as = 'x.md') {
    const H = await boot()
    const exts  = await lang(lang_for_path(as))
    const state = EditorState.create({ doc: text, extensions: exts })
    const job   = H.i({ probe: 'links_' + Math.random().toString(36).slice(2) })
    H.Lang_collect_markdown_regions(state, job)
    const map = job.o({ Map: 1 })[0]
    return (map ? map.o({ link: 1 }) : []).map((l: any) => ({ ...l.sc }))
}

test('the three older kinds still collect', async () => {
    const links = await collect(DOC)
    expect(links.filter(l => l.kind === 'wiki').map(l => l.target)).toEqual(['wiki-slug'])
    expect(links.filter(l => l.kind === 'file').map(l => l.target)).toEqual(['compile.ts'])
    expect(links.filter(l => l.kind === 'code').map(l => l.target)).toEqual(['Lagoon_callers'])
})

test('sect — a doc-qualified § carries its doc, a bare § carries none', async () => {
    const sect = (await collect(DOC)).filter(l => l.kind === 'sect')
    // doc-qualified: path prefix, .md suffix and the underscore-less .md form all tolerated
    const qualified = sect.filter(l => l.target).map(l => `${l.target} §${l.sect}`)
    expect(qualified).toEqual([
        'Lagoon_todo §2.7',
        'Stemdex_todo.md §0',
        'spec/Radio_circuit_todo.md §1',
        'Frontier.md §1',
        'Voro_render_todo.md §0',
    ])
    // bare: a § after an English word is a SELF-reference, not a link to a doc called "the".  This is
    //  the whole filter — the naive "word before §" reading collects `the §3` as a document.
    const bare = sect.filter(l => !l.target).map(l => l.sect)
    expect(bare).toEqual(['9', '3', '5'])
    // and NEVER a target key holding undefined: an undefined sc value encodes as an {"undef":…} brand,
    //  which CLAUDE.md calls a mint bug rather than furniture.
    for (const l of sect) expect(Object.hasOwn(l, 'target') && l.target === undefined).toBe(false)
})

test('book — the explicit form only, colon or equals', async () => {
    const books = (await collect(DOC)).filter(l => l.kind === 'book').map(l => l.target)
    expect(books).toEqual(['LagoonStaple', 'LakeSurprise'])
    // the bare prose form is deliberately NOT collected — it cannot be told from a sentence
    const prose = await collect('The Book Educarium boots the room.\n')
    expect(prose.filter(l => l.kind === 'book')).toEqual([])
    // a trailing `*` is a GLOB — `Book:Voro*` means every Voro Book, and capturing `Voro` from it
    //  reported a Book that does not exist.  It must collect NOTHING, not a truncated name: a naive
    //   lookahead lets the regex backtrack to `Vor`, which is worse than the bug.
    const glob = await collect('Every `Book:Voro*` shares one fixture, unlike Book:VoroRadio.\n')
    expect(glob.filter(l => l.kind === 'book').map(l => l.target)).toEqual(['VoroRadio'])
})

test('sworn — a slug, never a prose placeholder', async () => {
    const sworn = (await collect(DOC)).filter(l => l.kind === 'sworn').map(l => l.target)
    // «slug» is one word, so it fails the three-or-more-kebab-words shape and is left alone
    expect(sworn).toEqual(['the-reader-kept-nothing'])
    const noise = await collect('Prose about «X» and «uncoupled» and «slow producer starved».\n')
    expect(noise.filter(l => l.kind === 'sworn')).toEqual([])
})

// ANCHORS — not a link kind; the thing a § LANDS on when it is not a heading.  This corpus numbers
//  sub-items in bold inside a section and then points § at them, so a heading-only index calls them
//   rot.  Measured before adding it: counting these turned 2 of 10 cross-doc "dead" § links and 78
//    self-references back into live ones — the lint was wrong, not the docs.
test('anchor — a numbered bold item is an anchor, an ordinary bold line is not', async () => {
    const H = await boot()
    const rows = async (text: string) => {
        const exts  = await lang(lang_for_path('x.md'))
        const state = EditorState.create({ doc: text, extensions: exts })
        const job   = H.i({ probe: 'anch_' + Math.random().toString(36).slice(2) })
        H.Lang_collect_markdown_regions(state, job)
        const map = job.o({ Map: 1 })[0]
        return (map ? map.o({ anchor: 1 }) : []).map((a: any) => a.sc.sect)
    }
    expect(await rows('**7.4 Per-peer fairness: OUT OF SCOPE.**\n')).toEqual(['7.4'])
    expect(await rows('- **0.2e DESIGNED 2026-08-05** — reductionist Repli\n')).toEqual(['0.2e'])
    // an anchor is a line's OPENING, never something found mid-prose, and never a plain bold phrase
    expect(await rows('The ruling in **7.4 Per-peer fairness** was made mid-sentence.\n')).toEqual([])
    expect(await rows('**A bold heading with no number**\n')).toEqual([])
    // and it must not leak into the heading tree — a region row carries a label, an anchor has none
    const exts  = await lang(lang_for_path('x.md'))
    const state = EditorState.create({ doc: '# 1. Head\n\n**1.1 An item**\n', extensions: exts })
    const job   = H.i({ probe: 'anch_split' })
    H.Lang_collect_markdown_regions(state, job)
    const map = job.o({ Map: 1 })[0]
    expect(map.o({ region: 1 }).map((r: any) => r.sc.label)).toEqual(['1. Head'])
    expect(map.o({ region: 1 }).every((r: any) => r.sc.label !== undefined)).toBe(true)
})

// FENCING — a ``` block holds EXAMPLES, so a doc showing what a link looks like is not making one.
//  The toggle is stateful, which is the hazard: one stray fence would swallow every link below it with
//   no error anywhere.  So a document whose fencing does not balance is collected WHOLE — silent
//    under-collection traded for harmless over-collection (an unresolvable target is a mention, not rot).
test('fenced examples are skipped, and BROKEN fencing collects everything rather than losing it', async () => {
    const balanced = await collect(
        'A real `Real_symbol` here.\n```\nAn example `Example_symbol` inside a fence.\n```\nAnd `After_symbol`.\n')
    expect(balanced.filter(l => l.kind === 'code').map(l => l.target))
        .toEqual(['Real_symbol', 'After_symbol'])
    // the same document with the closing fence missing: nothing may vanish
    const broken = await collect(
        'A real `Real_symbol` here.\n```\nAn example `Example_symbol` inside a fence.\nAnd `After_symbol`.\n')
    expect(broken.filter(l => l.kind === 'code').map(l => l.target))
        .toEqual(['Real_symbol', 'Example_symbol', 'After_symbol'])
})

test('a § link keeps its line and its enclosing region, like every other kind', async () => {
    const sect = (await collect(DOC)).filter(l => l.kind === 'sect')
    expect(sect[0].line).toBe(3)                 // the first prose line after the heading
    expect(typeof sect[0].from).toBe('number')
    expect(typeof sect[0].to).toBe('number')
})

// THE CORPUS SWEEP — the same measurement the design was chosen on, run as a floor rather than a fact,
//  so it survives docs being written and retired.  The point is the RATIO: `code` is bigger in raw
//   count (it fires on every backticked symbol), but § is the corpus's NAVIGATION — one doc pointing
//    into another doc's section — and until m15 not one of the 3,266 was collected.
test('over the real spec/ corpus, § is the dominant cross-reference and nothing collected it', async () => {
    const dir = path.join(ROOT, 'src/lib/O/spec')
    const files = readdirSync(dir).filter(f => f.endsWith('.md'))
    expect(files.length).toBeGreaterThan(50)
    const n: Record<string, number> = { wiki: 0, file: 0, code: 0, sect: 0, book: 0, sworn: 0 }
    let sect_qualified = 0
    for (const f of files) {
        const links = await collect(readFileSync(path.join(dir, f), 'utf8'), f)
        for (const l of links) {
            n[l.kind] = (n[l.kind] ?? 0) + 1
            if (l.kind === 'sect' && l.target) sect_qualified++
        }
    }
    console.log(`[LinkKinds] spec/ ${files.length} docs →`, n, `(§ doc-qualified ${sect_qualified})`)
    expect(n.sect).toBeGreaterThan(2500)          // measured 2026-09-08: 3,266 over 133 docs
    expect(sect_qualified).toBeGreaterThan(400)   // measured 2026-09-08: 470 in spec/ top level
    expect(n.code).toBeGreaterThan(1000)          // m14's kind, unchanged by this pass
    expect(n.wiki).toBeGreaterThan(50)
})
