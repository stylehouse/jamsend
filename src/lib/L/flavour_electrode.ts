// flavour_electrode.ts — THE ELECTRODE FLAVOUR of a generated ghost (spec/Electrode_todo.md §0, Ground/Hacky/*): the same .go, rewritten
//  so the call tap (Ghost/L/Electrode.g) keeps its caller across an `await`.
//
//  THE HOLE.  The tap knows a call's caller only while the caller is on the JS stack (`T.cur`, set by each method's coat).  Code after
//   an `await` resumes later as a microtask with the stack EMPTY, so every call it makes read as from-nobody (26% of AtlasStaple's flows).
//  THE FIX — exact, because JS runs one thing at a time and nothing else runs between a resume and the next suspension:
//    · at entry, every async function notes the frame it runs in (`__ef`): its own coat's frame, or for a plain closure its caller's;
//    · on each resume it puts that frame back (`__E_on`), and marks itself resumed (`__er`);
//    · once resumed, it is running as a microtask with nobody below it, so at its next suspension and at its end it clears the frame
//       (`__E_off`, the `finally`) — never leaking its frame into whatever microtask runs next;
//    · BEFORE its first resume it clears nothing: there the suspension returns to a real synchronous caller, whose frame must stand.
//   `for await` is a suspension per iteration too: each loop body opens with the resume.
//  Not covered, said: a throw out of an `await` lands in a catch with the frame unrestored (the catch's calls read from-nobody).
//
//  The rewrite is text-for-text: every byte outside an `await`, an async body's braces and the prelude is the input's, so the build is
//   readable beside the plain one.  Helpers read `globalThis.__ELECTRODE` (Electrode_T sets it) — absent, every one is a no-op, so the
//    flavoured build runs exactly like the plain one when nothing is armed.
import ts from 'typescript'

export const FLAVOUR_ELECTRODE_PRELUDE = [
    `    // ELECTRODE FLAVOUR — src/lib/L/flavour_electrode.ts: the caller survives an await.  No-ops unless globalThis.__ELECTRODE is set.`,
    `    const __E = () => (globalThis as any).__ELECTRODE`,
    `    const __E_cur = () => __E()?.cur ?? null`,
    `    const __E_off = (v: any, er: any) => { const T = __E(); if (T && er) T.cur = null; return v }`,
    `    const __E_on = (f: any, v: any, _er: any) => { const T = __E(); if (T) T.cur = f; return v }`,
    `    const __E_end = (er: any) => { const T = __E(); if (T && er) T.cur = null }`,
].join('\n')

type Out = { source: string, awaits: number, fns: number }

// flavour_electrode_script — the rewrite over plain TS/JS text
// `dry` renders with no rewrite at all — the gate's proof that the walk reproduces every byte it does not mean to touch
export function flavour_electrode_script(text: string, dry = false): Out {
    const sf = ts.createSourceFile('x.ts', text, ts.ScriptTarget.Latest, true, ts.ScriptKind.TS)
    let awaits = 0
    let fns = 0
    const full = (n: ts.Node) => text.slice(n.getFullStart(), n.end)
    const trivia = (n: ts.Node) => text.slice(n.getFullStart(), n.getStart(sf))
    const is_async = (n: ts.Node) => !!(ts.canHaveModifiers(n) && ts.getModifiers(n)?.some(m => m.kind === ts.SyntaxKind.AsyncKeyword))
    const fnlike = (n: ts.Node): n is ts.FunctionLikeDeclaration =>
        ts.isFunctionDeclaration(n) || ts.isFunctionExpression(n) || ts.isArrowFunction(n) || ts.isMethodDeclaration(n)
    const OPEN = `const __ef = __E_cur(); let __er = 0; try {`
    const CLOSE = `} finally { __E_end(__er) }`

    // `inside`: within an async function (a top-level await has no frame of its own to keep — left as written)
    const render = (n: ts.Node, inside = false): string => {
        if (!dry && inside && ts.isAwaitExpression(n)) {
            awaits++
            return `${trivia(n)}__E_on(__ef, await __E_off(${render(n.expression, inside).trimStart()}, __er), __er = 1)`
        }
        if (!dry && fnlike(n) && is_async(n) && n.body) {
            fns++
            const body = n.body
            let out = ''
            for (const k of n.getChildren(sf)) {
                if (k !== body) { out += render(k, inside); continue }
                if (ts.isBlock(body)) {
                    const [open, list, close] = body.getChildren(sf)
                    out += render(open) + ` ${OPEN}` + render(list, true) + ` ${CLOSE}` + render(close)
                } else {
                    // a concise async arrow: `async (x) => expr` becomes a block that returns it
                    out += `${trivia(body)}{ ${OPEN} return (${render(body, true).trimStart()}) ${CLOSE} }`
                }
            }
            return out
        }
        if (!dry && inside && ts.isForOfStatement(n) && n.awaitModifier) {
            let out = ''
            for (const k of n.getChildren(sf)) {
                if (k !== n.statement) { out += render(k, inside); continue }
                if (ts.isBlock(k)) {
                    const [open, list, close] = k.getChildren(sf)
                    out += render(open) + ` __E_on(__ef, 0, __er = 1);` + render(list, inside) + render(close)
                } else {
                    out += `${trivia(k)}{ __E_on(__ef, 0, __er = 1); ${render(k, inside).trimStart()} }`
                }
            }
            return out
        }
        const kids = n.getChildren(sf)
        if (!kids.length) return full(n)
        // a non-async function starts a scope with no frame of its own: an await cannot appear in it except inside a nested async one
        const deeper = inside && !fnlike(n)
        let out = trivia(n).length && kids[0].getFullStart() > n.getFullStart() ? trivia(n) : ''
        for (const k of kids) out += render(k, deeper)
        return out
    }
    let source = ''
    for (const k of sf.getChildren(sf)) source += render(k)
    return { source, awaits, fns }
}

// flavour_electrode_go — a generated .go (a Svelte module: `<script lang="ts">…</script>` and maybe markup): rewrite the script and put
//  the prelude at its top
export function flavour_electrode_go(go: string): Out {
    const m = /^(<script[^>]*>\n)([\s\S]*?)(\n<\/script>)/m.exec(go)
    if (!m) throw new Error('flavour_electrode: no <script> in the module')
    const r = flavour_electrode_script(m[2])
    const source = go.slice(0, m.index) + m[1] + FLAVOUR_ELECTRODE_PRELUDE + '\n' + r.source + m[3] + go.slice(m.index + m[0].length)
    return { source, awaits: r.awaits, fns: r.fns }
}

// the flavoured build's home beside the plain one: gen/M/Heist.go → gen-electrode/M/Heist.go (same depth, so relative imports hold)
export const flavour_electrode_path = (gen_path: string) => gen_path.replace(/^gen\//, 'gen-electrode/')
