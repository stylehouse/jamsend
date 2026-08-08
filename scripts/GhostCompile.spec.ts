// GhostCompile — the PRE-COMPILE GATE for .g edits: does this dialect parse and lower?
//  Generalised 2026-08-08 from FlockCompile.spec.ts (which pins one fixed flock of files and
//   should stay pinned — it is that change's own gate).  This one takes whatever you are
//    actually editing: every .g modified in the working tree, or an explicit list via GHOSTS=.
//
//  WHY IT EARNS ITS KEEP.  The real compiler is `scripts/ghost_compile.ts`, and that targets the
//   EDITOR — which HMRs the resulting .go to every runner sharing the tree, landing in whatever
//    is in the run slot.  So the one thing you cannot casually do is "just compile it and see".
//     This runs the SAME in-app translator (Lang_compile_dock) headlessly, broadcasting nothing,
//      and answers the one question that blocks you: did I write legal .g?  It catches exactly
//       the dialect traps that bite here — a multi-line callback, a line-leading `else`.
//
//  WHAT IT DOES *NOT* PROVE, and the distinction is load-bearing: this is a PARSE gate, never a
//   behaviour gate.  A green here says the text lowers to JS, nothing whatsoever about what that
//    JS then does.  Behaviour is verified ONLY by a live runner on :9091 (CLAUDE.md, "Running a
//     Story Book") — a headless boot quiesces at a different depth and its green is a bubble.
//      Do not let this file grow assertions about runtime; that is how a bubble gets built.
//
//  Run:  node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/GhostCompile.spec.ts
//   or:  GHOSTS='Ghost/M/Radio.g Ghost/M/Ra.g' node_modules/.bin/vitest run -c … GhostCompile.spec.ts
import { test, expect } from 'vitest'
import { mount } from 'svelte'
import { readFileSync } from 'node:fs'
import { execSync } from 'node:child_process'
import path from 'node:path'
import Story_cli from './Story_cli.svelte'

const ROOT  = process.cwd()
const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))

// the working tree's own edited ghosts, so the gate follows the work without being re-pointed.
//  `git status --porcelain` covers modified AND untracked (a brand-new ghost is the case most
//   worth catching); -z + split on NUL so a path with a space cannot silently truncate the list.
function edited_ghosts(): string[] {
    if (process.env.GHOSTS) return process.env.GHOSTS.split(/\s+/).filter(Boolean)
    const out = execSync('git status --porcelain -z', { cwd: ROOT, encoding: 'utf8' })
    return out.split('\0')
        .filter(Boolean)
        .map(l => l.slice(3))              // strip the 2-char status + its space
        .filter(f => f.endsWith('.g'))
}

const FILES = edited_ghosts()

test('GhostCompile: every edited .g parses+lowers clean', async () => {
    if (!FILES.length) { console.log('· no edited .g in the working tree — nothing to gate'); return }

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

    const bad: string[] = []
    for (const f of FILES) {
        const err = await compile(f, readFileSync(path.join(ROOT, f), 'utf8'))
        console.log(`${err ? '✗' : '✓'} ${f}${err ? '  — ' + err : ''}`)
        if (err) bad.push(`${f}: ${err}`)
    }
    expect(bad, 'edited ghosts compile clean').toEqual([])
})
