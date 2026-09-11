// CM6Mount — how much does CodeMirror itself cost when a doc opens?
//
//  The hunt for "why does opening a doc take so long" has cleared, by measurement, every stage on the
//   model side: the compiler (315ms), the open chain (2-3 belief ticks, independent of file size), the
//    elvis round-trips (2-3), and the grammar build (~71ms warm). The only stage left is CM6 itself —
//     `new EditorView(...)` in `Langui.svelte`'s `build_editor`, which every earlier measurement
//      deliberately skipped because `force_compile` exists to compile without mounting an editor.
//
//  ⚠ WHAT THIS CAN AND CANNOT SEE. jsdom has a DOM but NO LAYOUT: `getBoundingClientRect` returns
//   zeroes, so CM6's measure phase does almost nothing here and the viewport it computes is fake.
//    That means this UNDER-measures a real mount, and the gap is precisely the layout work. So a big
//     number here is conclusive (real CPU, would also be paid in a browser) while a small number is
//      NOT an all-clear — it just means the cost is in layout/paint, which needs the live `⏱ CM6
//       mount` line from Langui.svelte to see.
//  What IS honest here: the document parse. CM6 parses lazily by viewport, so a 113KB doc should NOT
//   cost proportionally at construction — and if it does, that is the finding.
import { test } from 'vitest'
import { readFileSync } from 'node:fs'
import path from 'node:path'
import { EditorState } from '@codemirror/state'
import { EditorView, basicSetup } from 'codemirror'
import { lang } from '../src/lib/O/lang/lang'

const ROOT = process.cwd()
const FILES = [
    'Ghost/L/Electrode.g',      //  ~40KB
    'Ghost/N/Peeroleum.g',      // ~117KB — the owner's example
    'Ghost/M/Radio.g',          // ~281KB
    'Ghost/S/Swarm.g',          // ~630KB
]

test('CM6Mount: what EditorState.create + new EditorView cost per doc size', async () => {
    const exts = await lang('stho')          // the real grammar the .g docks use
    const rows: any[] = []
    for (const f of FILES) {
        const doc = readFileSync(path.join(ROOT, f), 'utf8')
        const kb = Math.round(doc.length / 1024)

        const t0 = performance.now()
        const state = EditorState.create({ doc, extensions: [basicSetup, ...exts] })
        const t1 = performance.now()
        const parent = document.createElement('div')
        document.body.appendChild(parent)
        const view = new EditorView({ parent, state })
        const t2 = performance.now()
        view.destroy(); parent.remove()

        rows.push({ f, kb, state: t1 - t0, view: t2 - t1, total: t2 - t0,
                    per_kb: +((t2 - t0) / kb).toFixed(2) })
    }
    console.log('\n  %s', 'file'.padEnd(24) + 'KB'.padStart(6) + 'State.create'.padStart(14)
        + 'new View'.padStart(11) + 'total'.padStart(8) + 'ms/KB'.padStart(8))
    for (const r of rows)
        console.log('  %s', r.f.replace(/^Ghost\//, '').padEnd(24) + String(r.kb).padStart(6)
            + String(Math.round(r.state)).padStart(14) + String(Math.round(r.view)).padStart(11)
            + String(Math.round(r.total)).padStart(8) + String(r.per_kb).padStart(8))

    // VERDICT AGAINST THE RAW ROWS, not a ratio heuristic — four instruments in three sessions have
    //  now printed a summary that its own numbers did not support.
    const first = rows[0], last = rows[rows.length - 1]
    const grew = last.total / Math.max(1, first.total)
    const size = last.kb / first.kb
    console.log(`\n  ${Math.round(first.total)}ms at ${first.kb}KB → ${Math.round(last.total)}ms at ${last.kb}KB`
        + `  (${size.toFixed(1)}× the bytes, ${grew.toFixed(1)}× the time)`)
    console.log(`  ⇒ ${grew > size * 0.7 ? 'LINEAR IN DOC SIZE — CM6 is doing whole-document work at construction'
                                          : 'sub-linear — CM6 is parsing lazily by viewport as designed'}`)
    console.log(`  ⚠ jsdom has no layout, so this is a FLOOR. A small number here does not clear CM6;`
              + ` it points at layout/paint, which only the live ⏱ CM6 mount line can show.`)
}, 300000)
