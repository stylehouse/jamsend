// LocalGen — the BROWSERLESS .g→.go compiler.  `npm run ghost-compile` only sends a ticket to a
//  live editor on :9091 (it never compiles locally — see scripts/ghost_compile.ts), so with no editor
//   connected there is no way to refresh src/lib/gen/**/*.go on disk.  This is that missing way: it
//    boots the machine headless (the FlockCompile boot — Story_cli + a minimal editor wiring), runs
//     each .g through the REAL in-app translator (Lang_compile_dock), reads the generated module off
//      the dock's %Compile/%Output, and writes it to the REAL gen path (src/lib/ + Lies_gen_path).
//       That is what CredRunner's Creduler acquire imports, so this closes the edit→compile→run loop
//        with zero browser.  (ghost-compile's editor path additionally HMRs into a *live* runner; this
//         writes disk only — fine for the headless CredRunner loop, which re-acquires on each boot.)
//
//   GFILES="Ghost/N/Reliable.g Ghost/N/Peeroleum.g" \
//     node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/LocalGen.spec.ts
//   CHECK=1 …    # compile only, DON'T write — diff the output against the committed .go (a safety gate)
import { test, expect } from 'vitest'
import { mount } from 'svelte'
import { readFileSync, writeFileSync } from 'node:fs'
import path from 'node:path'
import Story_cli from './Story_cli.svelte'

const ROOT  = process.cwd()
const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))
const CHECK = !!process.env.CHECK
const FILES = (process.env.GFILES || 'Ghost/N/Reliable.g Ghost/N/Peeroleum.g Ghost/N/Tribunal.g Ghost/Story/Peregrination.g')
    .split(/\s+/).filter(Boolean)

test('LocalGen: compile each .g and write its real gen/.go', async () => {
    let H: any
    mount(Story_cli, { target: document.body, props: { onhouse: (h: any) => { H = h } } })
    for (let i = 0; i < 80 && !(H && typeof H.Lang_compile_dock === 'function'); i++) await sleep(50)
    expect(typeof H?.Lang_compile_dock, 'Lang ghost deposited').toBe('function')

    H.c.role = 'editor'
    const wire = (n: string) => { const A = H.i({ A: n }); A.c.up = H; const w = A.i({ w: n }); w.c.up = A; return w }
    wire('Lies'); const w = wire('Lang'); wire('Pantheate')

    const compile = async (key: string, text: string) => {
        const docks = w.oai({ docks: 1 }); docks.c.up ??= w
        const dock  = docks.oai({ dock: key }); dock.c.up ??= docks
        dock.c.text = text
        delete dock.c.state
        const srcState = await H.Lang_compile_source_state(dock, text, key)
        await H.Lang_compile_dock(w, dock, srcState)
        const err = dock.o({ compile_error: 1 })[0]?.sc.msg as string | undefined
        const out = dock.o({ Compile: 1 })[0]?.o({ Output: 1 })[0]
        return { err, gen_path: out?.sc.gen_path as string | undefined, source: out?.sc.source as string | undefined }
    }

    let wrote = 0
    for (const f of FILES) {
        const { err, gen_path, source } = await compile(f, readFileSync(path.join(ROOT, f), 'utf8'))
        expect(err, `${f} compiles clean`).toBeUndefined()
        expect(gen_path, `${f} has a gen_path`).toBeTruthy()
        expect(typeof source === 'string' && source.length > 50, `${f} produced source`).toBe(true)
        const real = path.join(ROOT, 'src/lib', gen_path!)
        if (CHECK) {
            let prev = ''
            try { prev = readFileSync(real, 'utf8') } catch {}
            const same = prev.trim() === (source as string).trim()
            console.log(`${same ? '=' : '≠'} ${f} → ${gen_path}  (${(source as string).length}c vs ${prev.length}c committed)`)
        } else {
            writeFileSync(real, source as string)
            wrote++
            console.log(`✓ ${f} → src/lib/${gen_path}  (${(source as string).length}c)`)
        }
    }
    if (!CHECK) console.log(`[LocalGen] wrote ${wrote} gen files`)
})
