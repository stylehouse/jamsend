// FlockCompile — headless compile gate for the %Pier,…,req flock edits.  Boots the
//  machine, wires a minimal editor, and runs each edited ghost through the REAL in-app
//   translator (Lang_compile_dock — the same path LakeRace exercises), asserting no
//    compile_error.  This proves the new DSL forms parse+lower (notably the Pier-flock
//     mint `oai Pier,$pub,req$:cap` and `req_Pier`); the handshake/trust BEHAVIOUR still
//      needs :9091 (the Creduler wrangler doesn't run in this plain Story_cli boot).
//   Run: node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/FlockCompile.spec.ts
import { test, expect } from 'vitest'
import { mount } from 'svelte'
import { readFileSync } from 'node:fs'
import path from 'node:path'
import Story_cli from './Story_cli.svelte'

const ROOT  = process.cwd()
const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))
const FILES = ['Ghost/N/Peeroleum.g', 'Ghost/Story/Peregrination.g', 'Ghost/N/Tyrant.g']

test('FlockCompile: the Pier-flock .g edits all compile clean', async () => {
    let H: any
    mount(Story_cli, { target: document.body, props: { onhouse: (h: any) => { H = h } } })
    for (let i = 0; i < 60 && !(H && typeof H.Lang_compile_dock === 'function'); i++) await sleep(50)
    expect(typeof H?.Lang_compile_dock, 'Lang ghost deposited').toBe('function')
    expect(typeof H?.Lang_compile_source_state, 'compile-source helper deposited').toBe('function')

    H.c.role = 'editor'
    const wire = (n: string) => { const A = H.i({ A: n }); A.c.up = H; const w = A.i({ w: n }); w.c.up = A; return w }
    wire('Lies'); const w = wire('Lang'); wire('Pantheate')

    // compile a .g's text on a dock keyed by its path (the key MUST end .g — the codetype
    //  rides the extension).  No editor state → the helper builds it via lang() headless.
    const compile = async (key: string, text: string) => {
        const docks = w.oai({ docks: 1 }); docks.c.up ??= w
        const dock  = docks.oai({ dock: key }); dock.c.up ??= docks
        dock.c.text = text
        delete dock.c.state
        const srcState = await H.Lang_compile_source_state(dock, text, key)
        await H.Lang_compile_dock(w, dock, srcState)
        return dock.o({ compile_error: 1 })[0]?.sc.msg as string | undefined
    }

    for (const f of FILES) {
        const err = await compile(f, readFileSync(path.join(ROOT, f), 'utf8'))
        console.log(`${err ? '✗' : '✓'} ${f}${err ? '  — ' + err : ''}`)
        expect(err, `${f} compiles clean`).toBeUndefined()
    }
})
