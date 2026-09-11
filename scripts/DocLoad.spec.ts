// DocLoad — WHY DOES OPENING A DOC TAKE SO LONG?  (owner, 2026-09-10: *"canwe chase why it takes so
//  long for eg Doc:Peeroleum.g to load"*.)
//
//  The complaint that started the whole doc-index thread was "I'm unimpressed with its ability to
//   change Doc quickly", and every measurement since has been about the CENSUS (Atlas, the Stemdex)
//    rather than the thing actually being waited on: one document opening.  This measures that.
//
//  WHAT IT TIMES, and why these seams.  Opening a doc runs two very different costs back to back and
//   they need separating, because the fix for each is in a different file:
//     parse    Lang_compile_source_state — text → EditorState, i.e. the lezer parse.  Grammar cost.
//     compile  Lang_compile_dock — translate + build the %Map.  Our own code's cost.
//   A wall clock for "open" cannot say which, and the two scale differently with file size, which is
//    the second thing this asks: run a SIZE LADDER and see whether cost is linear in bytes or worse.
//    Superlinear is the interesting answer — it means the big ghosts (Swarm.g at 630KB) are not just
//     5x Peeroleum's wait but much more, and that a per-doc fix beats any amount of caching.
//
//  ⚠ WHAT THIS IS NOT.  Headless jsdom, no CodeMirror rendering, no paint — so it measures the
//   COMPILING CHAIN only, not the editor's own draw (the owner's "one spinner in the middle of the
//    codemirror" is not in here).  It is also slower in absolute terms than a real browser.  Read the
//     RATIOS and the SHAPE of the ladder; do not quote these as the owner's seconds.
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/DocLoad.spec.ts
//     DOCS="Ghost/N/Peeroleum.g Ghost/S/Swarm.g"   # override the ladder
import { test, expect } from 'vitest'
import { mount } from 'svelte'
import { readFileSync } from 'node:fs'
import path from 'node:path'
import Story_cli from './Story_cli.svelte'

const ROOT  = process.cwd()
const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))
// a deliberate SIZE LADDER, smallest → largest, so the per-KB column is comparable across an order
//  of magnitude.  Peeroleum is the owner's example and sits in the middle.
const FILES = (process.env.DOCS || [
    'Ghost/L/Electrode.g',      //  ~40KB
    'Ghost/N/Peeroleum.g',      // ~117KB — the one asked about
    'Ghost/M/Radio.g',          // ~281KB
    'Ghost/S/Swarm.g',          // ~630KB
].join(' ')).split(/\s+/).filter(Boolean)

test('DocLoad: where the time goes when one document opens', async () => {
    let H: any
    mount(Story_cli, { target: document.body, props: { onhouse: (h: any) => { H = h } } })
    for (let i = 0; i < 80 && !(H && typeof H.Lang_compile_dock === 'function'); i++) await sleep(50)
    expect(typeof H?.Lang_compile_dock, 'Lang ghost deposited').toBe('function')

    H.c.role = 'editor'
    const wire = (n: string) => { const A = H.i({ A: n }); A.c.up = H; const w = A.i({ w: n }); w.c.up = A; return w }
    wire('Lies'); const w = wire('Lang'); wire('Pantheate')

    const rows: any[] = []
    for (const f of FILES) {
        const text = readFileSync(path.join(ROOT, f), 'utf8')
        const docks = w.oai({ docks: 1 }); docks.c.up ??= w
        const dock  = docks.oai({ dock: f }); dock.c.up ??= docks
        dock.c.text = text
        delete dock.c.state

        const t0 = Date.now()
        const srcState = await H.Lang_compile_source_state(dock, text, f)
        const t1 = Date.now()
        await H.Lang_compile_dock(w, dock, srcState)
        const t2 = Date.now()

        const err = dock.o({ compile_error: 1 })[0]?.sc.msg as string | undefined
        // the job's OWN accounting, read back rather than re-derived — if it disagrees with our
        //  stopwatch that is a finding about the instrument, not a rounding error
        const job  = dock.o({ Compile: 1 })[0]
        const selftimed = job?.o({ time: 1 })[0]?.sc.compile
        const kb = Math.round(text.length / 1024)
        rows.push({ f, kb, parse: t1 - t0, compile: t2 - t1, total: t2 - t0,
                    per_kb: +((t2 - t0) / kb).toFixed(2), selftimed, err })
    }

    console.log('\n  %s', 'file'.padEnd(28) + 'KB'.padStart(6) + 'parse'.padStart(9)
        + 'compile'.padStart(9) + 'total'.padStart(8) + 'ms/KB'.padStart(8))
    for (const r of rows)
        console.log('  %s', r.f.replace(/^Ghost\//, '').padEnd(28) + String(r.kb).padStart(6)
            + String(r.parse).padStart(9) + String(r.compile).padStart(9)
            + String(r.total).padStart(8) + String(r.per_kb).padStart(8)
            + (r.err ? `   ⚠ ${r.err}` : ''))
    // THE SHAPE, stated rather than left for the reader to divide in their head: flat ms/KB = linear
    //  (the only cure is doing less of it), rising ms/KB = superlinear (worth finding the hot loop).
    const first = rows[0], last = rows[rows.length - 1]
    console.log('\n  ms/KB %s → %s across %s×  ⇒ %s',
        first.per_kb, last.per_kb, (last.kb / first.kb).toFixed(1),
        last.per_kb > first.per_kb * 1.5 ? 'SUPERLINEAR — there is a hot loop worth finding'
                                         : 'roughly linear — cost is proportional to bytes')
    for (const r of rows) expect(r.err, `${r.f} compiles clean`).toBeUndefined()
}, 600000)
