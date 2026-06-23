// LakeRace — emulate the CLI's ghost_compile against the REAL Ghost/N/Peeroleum.g,
//  headless, and prove the one-round lag is dead.
//
//   node scripts/LakeRace.run.mjs
//
// The bug: a channel-driven ghost_compile force-loads the changed .g, but the editor's
//  CodeMirror buffer (dock.c.state) reseats ASYNCHRONOUSLY — so a compile that reads
//   dock.c.state lands the PREVIOUS edit.  "Locked in at exactly one round."
//
// The fix (Lang_compile_source_state + Lang_compile_dock's stateOverride): the compile
//  source is built straight from the fresh disk text, decoupled from the editor's display
//   buffer.  This file drives BOTH branches of that helper, on the real Peeroleum.g:
//    - WARM (editor mounted): seed dock.c.state with the OLD text, ask for a compile of the
//       NEW text → the helper .update()s the editor's own config to the new doc.  The lag
//        would show here: a dock.c.state-reading compile gives the OLD dige.
//    - COLD/HEADLESS (no editor): the helper builds a fresh state via lang() — the DOM-free
//       bridge — which is also what lets this run with no browser at all.
//
// Story_cli can't mount CodeMirror (Ghost = logic only, the editor UI lives behind Otro),
//  so this exercises the compile spine directly — the closest faithful emulation headless.
import { test, expect } from 'vitest'
import { mount } from 'svelte'
import { readFileSync } from 'node:fs'
import path from 'node:path'
import { EditorState } from '@codemirror/state'
import Story_cli from './Story_cli.svelte'
import { lang, lang_for_path } from '$lib/O/lang/lang'
import { dig } from '$lib/Y.svelte'

const ROOT  = process.cwd()
const PEER   = 'Ghost/N/Peeroleum.g'
const sleep  = (ms: number) => new Promise(r => setTimeout(r, ms))
// distinct dock keys that still END in .g — Lies_gen_path reads the codetype off the
//  extension (GEN_ABLE_CODETYPES=['g']), so a `foo.g#warm` suffix makes the compile a
//   silent no-op.  source_dige depends only on the source text, so the tag is free.
const key = (tag: string) => PEER.replace(/\.g$/, `_${tag}.g`)
// the Nubblecroft→Wumpledonk jiggle, as a token swap on the real source.
const jiggle = (s: string) => s.includes('Thrumblefix')
    ? s.replace('Thrumblefix', 'Wumpledonk')
    : s.replace(/(\bseemingly:`[^`]*`)/, '$1/* jiggled */')

test('LakeRace: ghost_compile lag is dead (real Peeroleum.g)', async () => {
    // ── boot the machine; wire a minimal editor-machine so the Lies handoff has a home ──
    let H: any
    mount(Story_cli, { target: document.body, props: { onhouse: (h: any) => { H = h } } })
    for (let i = 0; i < 60 && !(H && typeof H.Lang_compile_dock === 'function'); i++) await sleep(50)
    expect(typeof H?.Lang_compile_dock, 'Lang ghost deposited').toBe('function')
    expect(typeof H?.Lang_compile_source_state, 'compile-source helper deposited').toBe('function')

    H.c.role = 'editor'
    const wire = (n: string) => { const A = H.i({ A: n }); A.c.up = H; const w = A.i({ w: n }); w.c.up = A; return w }
    wire('Lies'); const w = wire('Lang'); wire('Pantheate')

    // the real source, and a "jiggle" of it — the Nubblecroft→Wumpledonk edit, as a token swap.
    const OLD = readFileSync(path.join(ROOT, PEER), 'utf8')
    const NEW = jiggle(OLD)
    expect(NEW, 'jiggle actually changed the source').not.toBe(OLD)
    const dige_old = await dig(OLD)
    const dige_new = await dig(NEW)
    console.log(`\nsource diges:  OLD=${dige_old.slice(0, 8)}  NEW=${dige_new.slice(0, 8)}  (${OLD.length}c → ${NEW.length}c)`)

    // compile `text` on dock `key`, with dock.c.state optionally pre-seeded to `stale` (the
    //  warm-editor lag setup).  Returns the source_dige the compiler actually read.
    const compile = async (key: string, text: string, stale?: string) => {
        const docks = w.oai({ docks: 1 }); docks.c.up ??= w
        const dock  = docks.oai({ dock: key }); dock.c.up ??= docks
        dock.c.text = text
        if (stale !== undefined) {
            // seed the editor buffer with the STALE text — exactly the warm-jiggle race.
            const exts = await lang(lang_for_path(key))
            dock.c.state = EditorState.create({ doc: stale, extensions: exts })
        } else {
            delete dock.c.state   // headless / cold: no mounted editor
        }
        const srcState = await H.Lang_compile_source_state(dock, text, key)
        await H.Lang_compile_dock(w, dock, srcState)
        const out = dock.o({ Compile: 1 })[0]?.o({ Output: 1 })[0]
        const err = dock.o({ compile_error: 1 })[0]?.sc.msg
        return { source_dige: out?.sc.source_dige as string | undefined, err }
    }

    // ── WARM branch — the actual jiggle: editor buffer holds OLD, disk now has NEW ──
    console.log(`\n── WARM (editor mounted, buffer stale) ──`)
    const warm = await compile(key('warm'), NEW, /* stale buffer = */ OLD)
    console.log(`compiled source_dige=${warm.source_dige?.slice(0, 8)}  want NEW=${dige_new.slice(0, 8)}  err=${warm.err ?? '—'}`)
    expect(warm.err, 'warm compile clean').toBeUndefined()
    expect(warm.source_dige, 'WARM compiles the NEW disk text, not the stale buffer (no lag)').toBe(dige_new)
    expect(warm.source_dige, 'and definitely not the OLD text').not.toBe(dige_old)

    // ── COLD/HEADLESS branch — no editor; helper builds the state via lang() ──
    console.log(`\n── COLD (headless, no editor state) ──`)
    const cold = await compile(key('cold'), NEW)
    console.log(`compiled source_dige=${cold.source_dige?.slice(0, 8)}  want NEW=${dige_new.slice(0, 8)}  err=${cold.err ?? '—'}`)
    expect(cold.err, 'cold compile clean').toBeUndefined()
    expect(cold.source_dige, 'COLD compiles the NEW disk text headless (the bridge)').toBe(dige_new)

    // ── the lag, demonstrated: what a dock.c.state-reading compile WOULD have produced ──
    //   (compile the stale buffer directly — this is the pre-fix behaviour, one round behind.)
    const lagged = await compile(key('lagged'), OLD)   // OLD == the stale buffer's text
    console.log(`\n  the old bug would have emitted source_dige=${lagged.source_dige?.slice(0, 8)} (OLD) — one round behind.`)
    expect(lagged.source_dige).toBe(dige_old)

    console.log(`\n✓ lag dead: ghost_compile now emits the NEW dige (${dige_new.slice(0, 8)}) in both warm and cold paths.`)
})

test('LakeRace: compile cost curve (real Peeroleum.g, scaled)', async () => {
    let H: any
    mount(Story_cli, { target: document.body, props: { onhouse: (h: any) => { H = h } } })
    for (let i = 0; i < 60 && !(H && typeof H.Lang_compile_dock === 'function'); i++) await sleep(50)
    expect(typeof H?.Lang_compile_dock, 'Lang ghost deposited').toBe('function')
    H.c.role = 'editor'
    const wire = (n: string) => { const A = H.i({ A: n }); A.c.up = H; const w = A.i({ w: n }); w.c.up = A; return w }
    wire('Lies'); const w = wire('Lang'); wire('Pantheate')

    const base = readFileSync(path.join(ROOT, PEER), 'utf8')
    const lines0 = base.split('\n').length
    console.log(`\n── compile cost (Peeroleum.g = ${lines0} lines), 3 passes, best sync ──`)
    const compile_n = async (key: string, text: string) => {
        const docks = w.oai({ docks: 1 }); docks.c.up ??= w
        const dock  = docks.oai({ dock: key }); dock.c.up ??= docks
        dock.c.text = text; delete dock.c.state
        const srcState = await H.Lang_compile_source_state(dock, text, key)
        const t0 = performance.now()
        await H.Lang_compile_dock(w, dock, srcState)
        const wall = performance.now() - t0
        const job = dock.o({ Compile: 1 })[0]
        return { sync: job?.o({ time: 1 })[0]?.sc.compile as number | undefined, wall,
                 err: dock.o({ compile_error: 1 })[0]?.sc.msg, lines: text.split('\n').length }
    }
    for (const k of [1, 2, 4]) {
        const text = Array.from({ length: k }, () => base).join('\n\n')
        let best: any
        for (let p = 0; p < 3; p++) { const r = await compile_n(key(`x${k}p${p}`), text); if (!best || (r.sync ?? 1e9) < (best.sync ?? 1e9)) best = r }
        const per = best.sync != null ? (best.sync * 1000 / best.lines).toFixed(3) : '—'
        console.log(`×${k}: lines=${String(best.lines).padStart(5)}  sync=${best.sync != null ? (best.sync * 1000).toFixed(1).padStart(7) + 'ms' : '   —'}  wall=${best.wall.toFixed(1).padStart(7)}ms  per-line=${per}ms  err=${best.err ?? '—'}`)
    }
    expect(true).toBe(true)
})

test('LakeRace: the real dock_content force_active handover (recv path) emits NEW', async () => {
    // This is the CLI's request as it actually arrives — minus transport + signature: a
    //  %Good carrying the fresh disk text + force_active, handed to e_Lang_dock_content
    //   exactly as Lies_ghost_compile_recv → Lies_provide_dock would.  It exercises the wiring
    //    (dock_content → Lang_compile_source_state → Lang_compile_dock), not just the primitive.
    let H: any
    mount(Story_cli, { target: document.body, props: { onhouse: (h: any) => { H = h } } })
    for (let i = 0; i < 60 && !(H && typeof H.e_Lang_dock_content === 'function'); i++) await sleep(50)
    expect(typeof H?.e_Lang_dock_content, 'Lang dock_content handler deposited').toBe('function')
    H.c.role = 'editor'
    const wire = (n: string) => { const A = H.i({ A: n }); A.c.up = H; const w = A.i({ w: n }); w.c.up = A; return { A, w } }
    wire('Lies'); const lang = wire('Lang'); wire('Pantheate')
    const w = lang.w

    const OLD = readFileSync(path.join(ROOT, PEER), 'utf8')
    const NEW = jiggle(OLD)
    const dige_new = await dig(NEW)
    const dpath = key('recv')

    // the %Good the recv hands over: path + fresh disk content + its known dige, force_active.
    const good = w.i({ Good: 1, path: dpath })
    good.c.content = NEW
    good.i({ known: 1, dige: dige_new })
    // i_elvisto pushes the elvis through an async `targeting` step, and o_elvis reads it off
    //  w.c.e — which the beliefs drive normally sets while invoking the handler.  Driving the
    //   handler by hand, we await the targeting and seat the elvis on w.c.e ourselves so
    //    e_Lang_dock_content's `for (ev of o_elvis(w,'dock_content'))` sees it.
    const e = H.i_elvisto('Lang/Lang', 'dock_content', { Good: good, force_active: 1 })
    await e.c.targeting
    w.c.e = e
    await H.e_Lang_dock_content(lang.A, w)

    const dock = w.o({ docks: 1 })[0]?.o({ dock: dpath })[0]
    const out  = dock?.o({ Compile: 1 })[0]?.o({ Output: 1 })[0]
    const err  = dock?.o({ compile_error: 1 })[0]?.sc.msg
    console.log(`\nrecv-path: compiled source_dige=${(out?.sc.source_dige as string | undefined)?.slice(0, 8)}  `
        + `want NEW=${dige_new.slice(0, 8)}  active=${w.c.active_dock_path === dpath}  err=${err ?? '—'}`)
    expect(err, 'recv-path compile clean').toBeUndefined()
    expect(out?.sc.source_dige, 'the real dock_content force_active path compiles the NEW disk text')
        .toBe(dige_new)
    console.log(`✓ the recv handover (dock_content + force_active) emits the NEW dige — wiring proven headless.`)
})
