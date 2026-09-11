// GrammarBuild — is the lezer grammar REBUILT on every editor mount?
//
//  Chasing "why does opening a doc take so long", the model side came back clean: the compiler is
//   315ms for Peeroleum.g, and click→compiled is 2-3 belief ticks regardless of file size. That left
//    the CM6 mount, and `build_editor` (Langui.svelte:1633) opens with `await lang(name)`.
//
//  `lang()` (lang.ts:36) calls `entry.resolve()` UNCONDITIONALLY — there is no memo. And stho's
//   `resolve()` (grammars/stho/index.ts:130) tries a generated artifact first via
//    `import.meta.glob('./stho.grammar.ts')` … **and that file does not exist**, anywhere in the repo,
//     with no script that produces it and no gitignore entry hiding it. So the fast path is dead code
//      that has never run, and every resolve falls through to the live `buildParser(grammar, …)` —
//       a full LR parser generation, in the browser, per editor mount. (It is also why
//        `@lezer/generator`, 142KB, is in the page's boot bill at all.)
//
//  This measures that cost and proves the absence of caching by resolving repeatedly: if every call
//   costs the same, nothing is being remembered.
import { test } from 'vitest'
import { resolve as stho_resolve } from '../src/lib/O/lang/grammars/stho'
import { lang } from '../src/lib/O/lang/lang'

test('GrammarBuild: what one grammar resolve costs, and whether it is remembered', async () => {
    const runs: number[] = []
    for (let i = 0; i < 4; i++) {
        const t = performance.now()
        const r = await stho_resolve()
        const ms = performance.now() - t
        runs.push(ms)
        console.log(`  resolve #${i + 1}  ${Math.round(ms)}ms   source:${r.source} stale:${r.stale}`
            + ` warnings:${r.warnings?.length ?? 0}`)
    }
    // and through the real front door the editor uses — for EVERY registered language, because
    //  stho is only what a `.g` dock uses. A `.ts`/`.svelte` dock takes tsstho (which nests stho via
    //   get_inner_parser) and a `.md` dock takes markdown. Fixing stho alone would leave two thirds
    //    of the docks paying whatever they pay, and I have twice now "fixed" something I had not
    //     measured — so measure all three, warm AND repeated, before touching any of them.
    console.log('')
    for (const name of ['stho', 'tsstho', 'markdown']) {
        const t1 = performance.now(); await lang(name); const cold = performance.now() - t1
        const t2 = performance.now(); await lang(name); const warm1 = performance.now() - t2
        const t3 = performance.now(); await lang(name); const warm2 = performance.now() - t3
        console.log(`  lang('${name}')`.padEnd(22)
            + `first ${Math.round(cold)}ms · again ${Math.round(warm1)}ms · again ${Math.round(warm2)}ms`
            + `   ${warm2 < 5 ? '' : '← STILL REBUILDING per mount'}`)
    }

    // WHAT THE CURVE MEANS depends on whether a memo is installed, and this test has now seen both:
    //   BEFORE (2026-09-11): 139 / 76 / 37 / 42ms — every call a real rebuild, `source:live` each
    //     time. The decline was V8 warming up. A first-vs-last ratio in an earlier version of this
    //      test read that as "something is memoising it" — exactly backwards, off its own good data.
    //   AFTER the hash-keyed memo in grammars/stho/index.ts: ~168 / 7 / 1 / 0ms. THAT is a cache.
    //  So do not infer a cache from the shape of the curve; the tell is the SIZE of the warm number.
    //   A rebuild is tens of ms; a memo hit is ~0. `source:live` stays `live` either way — it
    //    describes which BUILD PATH produced the parser, never whether it was remembered.
    const warm = runs.slice(1).reduce((a, b) => a + b, 0) / (runs.length - 1)
    const cached = warm < 5
    console.log(`\n  cold ${Math.round(runs[0])}ms · warm ${Math.round(warm)}ms`
        + `  ⇒ ${cached ? 'MEMO IS LIVE (a hit is ~0ms)' : 'NO MEMO — every editor mount rebuilds the parser'}`)
    console.log(`  build_editor calls lang() once per mount, so ~${Math.round(warm)}ms is the per-doc-open`
        + ` grammar floor. Compare: the compile itself is 282ms for Peeroleum.g.`)
}, 300000)
