// FlavourElectrode.spec.ts — the gate for the measuring build (src/lib/L/flavour_electrode.ts; spec/Electrode_todo.md §0).
//  Three things, each a reason to trust a .go nobody wrote by hand:
//   · the walk is TEXT FOR TEXT — with the rewrite off, every real module in src/lib/gen comes back byte-identical, so what the
//      flavour changes is exactly the awaits, the async bodies' braces and the prelude;
//   · the rewrite is RIGHT — the call tap's caller survives an await, for interleaved methods, a plain closure called by a coated one
//      (whose caller must keep its own frame), `for await`, a concise async arrow — and it leaks into nothing after;
//   · every flavoured module still COMPILES as the Svelte module it was.
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/FlavourElectrode.spec.ts
import { test, expect } from 'vitest'
import { readFileSync, readdirSync, statSync, existsSync } from 'node:fs'
import path from 'node:path'
import ts from 'typescript'
import { compile } from 'svelte/compiler'
import { flavour_electrode_script, flavour_electrode_go, FLAVOUR_ELECTRODE_PRELUDE } from '../src/lib/L/flavour_electrode'

const ROOT = process.cwd()
const walk = (d: string): string[] => readdirSync(d).flatMap(f => {
    const p = path.join(d, f)
    return statSync(p).isDirectory() ? walk(p) : p.endsWith('.go') ? [p] : []
})
const script_of = (go: string) => /^(<script[^>]*>\n)([\s\S]*?)(\n<\/script>)/m.exec(go)?.[2]

test('the walk is text for text — every real module comes back byte-identical with the rewrite off', () => {
    const mods = walk(path.join(ROOT, 'src/lib/gen'))
    expect(mods.length).toBeGreaterThan(20)
    const bad = mods.filter(f => {
        const s = script_of(readFileSync(f, 'utf8'))
        return s != null && flavour_electrode_script(s, true).source !== s
    })
    expect(bad).toEqual([])
})

const SCENE = `
const T: any = { cur: null }
;(globalThis as any).__ELECTRODE = T
const seen: string[] = []
const coat = (name: string, raw: any) => function (this: any, ...a: any[]) {
    const prev = T.cur; T.cur = { m: name }
    try { return raw.apply(this, a) } finally { T.cur = prev }
}
const leaf = (tag: string) => { seen.push(\`\${tag} ← \${T.cur ? T.cur.m : 'nobody'}\`) }
const tick = () => new Promise(r => setTimeout(r, 5))
const alpha = coat('alpha', async function () { leaf('alpha before'); await tick(); leaf('alpha after'); await tick(); leaf('alpha after2') })
const beta  = coat('beta',  async function () { leaf('beta before');  await tick(); leaf('beta after') })
const gamma = coat('gamma', function () {
    const c = async () => { leaf('closure before'); await tick(); leaf('closure after') }
    void c()
    leaf('gamma after calling closure')
})
const delta = coat('delta', async function () { for await (const x of [tick(), tick()]) leaf('delta loop') })
const eps   = coat('eps', async function () { const f = async () => leaf('concise'); await f(); await tick(); leaf('eps after') })
export async function scene() {
    seen.length = 0
    await Promise.all([alpha(), beta(), (gamma(), tick().then(tick)), delta(), eps()])
    leaf('after all')
    return [...seen].sort()
}
`
async function run(ts_src: string): Promise<string[]> {
    const js = ts.transpileModule(ts_src, { compilerOptions: { module: ts.ModuleKind.ESNext, target: ts.ScriptTarget.ES2022 } }).outputText
    const mod = await import('data:text/javascript;base64,' + Buffer.from(js).toString('base64'))
    return mod.scene()
}

test('the rewrite is right — the caller survives an await, and leaks into nothing after', async () => {
    const plain = await run(SCENE)
    expect(plain).toContain('alpha after ← nobody')            // the hole, as the plain build has it
    const r = flavour_electrode_script(SCENE)
    const got = await run(FLAVOUR_ELECTRODE_PRELUDE + '\n' + r.source)
    expect(got).toEqual([
        'after all ← nobody',                                  // nothing leaked out of a finished async function
        'alpha after ← alpha', 'alpha after2 ← alpha', 'alpha before ← alpha',
        'beta after ← beta', 'beta before ← beta',
        'closure after ← gamma', 'closure before ← gamma',       // a plain closure keeps the frame it was called in…
        'concise ← eps',
        'delta loop ← delta', 'delta loop ← delta',
        'eps after ← eps',
        'gamma after calling closure ← gamma',                   // …and its suspension never blanks its synchronous caller
    ])
})

test('every flavoured module still compiles', () => {
    const mods = walk(path.join(ROOT, 'src/lib/gen')).slice(0, 80)
    const bad: string[] = []
    for (const f of mods) {
        const go = readFileSync(f, 'utf8')
        if (!script_of(go)) continue
        try { compile(flavour_electrode_go(go).source, { generate: 'client' }) } catch (e: any) { bad.push(`${f}: ${String(e?.message).slice(0, 120)}`) }
    }
    expect(bad).toEqual([])
    expect(existsSync(path.join(ROOT, '.gitignore')) && /src\/lib\/gen-electrode\//.test(readFileSync(path.join(ROOT, '.gitignore'), 'utf8')),
        'the measuring build is gitignored').toBe(true)
}, 120_000)
