// StatusWaft — the dev server writes a Waft; the TAB'S OWN DECODER reads it.
//
//  This is the gate for `spec/Docindex_todo.md`'s first slice: one off-tab walk producing one Waft that
//   carries the whole corpus's `dige + mtime + size`, written where a Waft lives, opened with the code
//    the machine has had since the beginning.  No endpoint, no Mag, no Repli, no new frame kind.
//
//  WHY THIS GATE AND NOT A UNIT TEST OF THE WRITER.  The writer emits snap TEXT by hand in node, and
//   the format has a trap that fails silently: a string value takes `key:value` while a NUMBER takes
//    `key=value`.  Get that backwards and the file still parses — `mtime` simply arrives as the string
//     "1789002646553" and every comparison against a number quietly fails forever.  So the only gate
//      worth having runs the REAL decoder (`decode_wh_lines`, the same one `deWaft` calls) over the
//       REAL output of the writer and checks the TYPES that come back, not just the text that went in.
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/StatusWaft.spec.ts
import { test, expect, beforeAll } from 'vitest'
import { mount } from 'svelte'
import Story_cli from './Story_cli.svelte'
import { status_waft } from '../src/lib/server/dige'

const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))
const ROOT = process.cwd()
let H: any

beforeAll(async () => {
    mount(Story_cli, { target: document.body, props: { onhouse: (h: any) => { H = h } } })
    for (let i = 0; i < 80 && !H?.started; i++) await sleep(50)
    expect(typeof H?.decode_wh_lines, 'the decoder is on the House').toBe('function')
}, 30_000)

test('the writer emits a Waft the tab can open, with the whole corpus in it', () => {
    const { snap, docs, skipped } = status_waft(ROOT, ['Ghost', 'src', 'scripts'])
    expect(skipped, 'no path was dropped for carrying a comma or newline').toEqual([])
    expect(docs, 'the real corpus, not a sample').toBeGreaterThan(600)
    expect(snap.startsWith('Waft:Docindex\n'), 'a Waft root, so it lands as a Waft').toBe(true)

    const { C, errors } = (H as any).decode_wh_lines(snap)
    expect(errors, 'the tab’s own decoder reads it without fault').toEqual([])
    expect(C, 'a tree came back').toBeTruthy()
    expect(C.o({ Doc: 1 }).length, 'every doc arrived as a particle').toBe(docs)
})

test('numbers arrive as NUMBERS — the silent trap in the line format', () => {
    const { snap } = status_waft(ROOT, ['Ghost'])
    const { C } = (H as any).decode_wh_lines(snap)
    const doc = C.o({ Doc: 'Ghost/L/Atlas.g' })[0]
    expect(doc, 'a known file is in the index').toBeTruthy()
    expect(typeof doc.sc.dige, 'dige is a string — `key:value`').toBe('string')
    expect(doc.sc.dige).toMatch(/^[0-9a-f]{16}$/)
    // `key=value` is what makes these numbers; had the writer used `:` they would arrive as strings
    //  and every mtime/size comparison in the tab would silently never match
    expect(typeof doc.sc.mtime, 'mtime is a NUMBER — `key=value`').toBe('number')
    expect(typeof doc.sc.size, 'size is a NUMBER — `key=value`').toBe('number')
    expect(doc.sc.size).toBeGreaterThan(0)
})

test('the dige agrees with the tab’s own hash function', async () => {
    const { snap } = status_waft(ROOT, ['Ghost'])
    const { C } = (H as any).decode_wh_lines(snap)
    const doc = C.o({ Doc: 'Ghost/L/Atlas.g' })[0]
    const { readFileSync } = await import('node:fs')
    const text = readFileSync(`${ROOT}/Ghost/L/Atlas.g`, 'utf8')
    const { dig } = await import('../src/lib/Y.svelte')
    // the whole road depends on ONE hash meaning the same thing on both sides of it: the server
    //  computes it in node, the tab compares it against what `dig` gives.  A drift here would make
    //   every doc look changed forever and the index would be worse than useless.
    expect(doc.sc.dige, 'server-side hash === the browser’s dig()').toBe(await dig(text))
})

test('it is stable — the same corpus twice gives byte-identical text', () => {
    const a = status_waft(ROOT, ['Ghost', 'scripts'])
    const b = status_waft(ROOT, ['Ghost', 'scripts'])
    // stability is what lets a watcher write only on a real change, and what stops the file
    //  churning git on every keystroke; sorted paths are what buy it
    expect(a.snap).toBe(b.snap)
})
