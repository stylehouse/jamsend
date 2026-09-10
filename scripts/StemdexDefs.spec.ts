// StemdexDefs — the Stemdex can see a ghost method.
//
//  FOUND 2026-09-10 by an objective read of the two indexes, then verified by counting the corpus:
//   53 `.g` files hold **2,822** real methods; the Stemdex's def extractor found **714** "defs" in them
//    of which **zero** were methods.  `Ghost/L/Atlas.g` produced exactly one — `roots`, a local — because
//     the only alternative that matched the dialect was `const|let X = (`.
//  The method form in `.g` is `Name(args):` at column 0, with no trailing brace, so the regex that wants
//   `{` could never fire.  The fix teaches the scan the dialect rather than deleting the extractor:
//    Atlas holds all 2,822 correctly, but Atlas is FSA-only and refuses to stand without a granted
//     handle, while this scan rides LiesStore and works on any tab with an editor — deleting it would
//      remove ghost-method search from exactly the tabs Atlas cannot serve.
//
//  The test runs `Lies_stemdex_scan_text` — the REAL extractor on the House — over REAL corpus files,
//   because a hand-written fixture would only prove the regex I just wrote matches the example I chose.
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/StemdexDefs.spec.ts
import { test, expect, beforeAll } from 'vitest'
import { mount } from 'svelte'
import { readdirSync, readFileSync } from 'node:fs'
import { join } from 'node:path'
import Story_cli from './Story_cli.svelte'

const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))
const ROOT = process.cwd()
let H: any

beforeAll(async () => {
    mount(Story_cli, { target: document.body, props: { onhouse: (h: any) => { H = h } } })
    for (let i = 0; i < 80 && !H?.started; i++) await sleep(50)
    expect(typeof H?.Lies_stemdex_scan_text, 'the Stemdex extractor is on the House').toBe('function')
}, 30_000)

// the projection row calls the field `defs_e` (name/kind/line entries) — not `defs`.  Getting that
//  wrong made every assertion here fail against an empty array, including the .ts case that predates
//   the change, which is what said "the harness is wrong" rather than "the fix is wrong".
// the extractor ADOPTS its row into the index as it goes, so it needs the four live Maps a real
//  `Lies_stemdex(w)` hands out — `docs`, `post`, `defs`, `props`.  A bare {} gets as far as the first
//   `.get` and no further.
const fresh_dex = () => ({ docs: new Map(), post: new Map(), defs: new Map(), props: new Map(),
                           total: 0, done: 0, missing: 0, pass: 0 })
const scan = (path: string, text: string) =>
    H.Lies_stemdex_scan_text(fresh_dex(), path, 'deadbeefdeadbeef', text)
const def_names = (row: any): string[] => (row.defs_e ?? []).map((d: any) => d.name)

// the real declaration form, counted independently of the code under test
const real_methods = (text: string) => {
    const out = new Set<string>()
    for (const l of text.split('\n')) {
        const m = /^(?:async\s+)?([A-Za-z_][\w]*)\s*\(.*\)\s*:\s*$/.exec(l)
        if (m) out.add(m[1])
    }
    return out
}

function ghost_files(): string[] {
    const out: string[] = []
    const walk = (d: string) => {
        for (const e of readdirSync(d, { withFileTypes: true })) {
            const p = join(d, e.name)
            if (e.isDirectory()) { if (!['gen', 'history', 'shelved', 'test_corpus'].includes(e.name)) walk(p) }
            else if (e.name.endsWith('.g')) out.push(p)
        }
    }
    walk(join(ROOT, 'Ghost'))
    return out
}

test('a ghost method is found where none was before', () => {
    const text = readFileSync(join(ROOT, 'Ghost/L/Atlas.g'), 'utf8')
    const names = def_names(scan('Ghost/L/Atlas.g', text))
    expect(names, 'the census verbs are visible to the searchbar now').toContain('Atlas_pass')
    expect(names).toContain('Atlas_cache_adopt')
    expect(names).toContain('Atlas_index_read')
    // the regression this fixes: a local variable is not a definition
    expect(names, 'and a `let roots = (…)` local is not a def').not.toContain('roots')
})

test('across the whole ghost pile it finds real methods and almost no junk', () => {
    let found = 0, real = 0, correct = 0
    for (const f of ghost_files()) {
        const text = readFileSync(f, 'utf8')
        const rel = f.slice(ROOT.length + 1)
        const names: string[] = def_names(scan(rel, text))
        const truth = real_methods(text)
        found += names.length
        real += truth.size
        correct += names.filter(n => truth.has(n)).length
    }
    // before: found 714, correct 0, against 2822 real.  A floor, not an equality — the corpus grows.
    expect(real, 'the ghost pile really does hold thousands of methods').toBeGreaterThan(2000)
    expect(correct, 'and the scan now finds them').toBeGreaterThan(2000)
    expect(found - correct, 'with essentially no false rows left').toBeLessThan(found * 0.02)
})

test('the other languages are untouched — this was a `.g`-only blindness', () => {
    const ts = readFileSync(join(ROOT, 'src/lib/server/dige.ts'), 'utf8')
    const names = def_names(scan('src/lib/server/dige.ts', ts))
    expect(names, 'exported functions in .ts still found').toContain('status_waft')
    expect(names).toContain('serve_diges')
    const md = '# A heading\n\nsome prose\n'
    expect(def_names(scan('x/y_todo.md', md)), 'markdown headings still ride as defs').toContain('A heading')
})
