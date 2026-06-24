<script lang="ts">
    // LangLang.svelte — language picker + parser-generation sub-ghost.
    //
    // Lang-header-adjacent concerns split out from Lang.svelte:
    //
    //   1. Language picker dropdown
    //      Options drawn from $lib/O/lang/registry. Default value tracks the
    //      active doc: lang_override if set, otherwise lang_for_path on the
    //      doc path. Langui watches the override and reconfigures its
    //      language Compartment on change — no editor remount.
    //
    //   2. Parser generation
    //      When the active doc's path matches a registered language's
    //      grammar_path, the gen action is enabled and labelled with the
    //      target language name. Pressing it runs buildParserFile on the
    //      editor's current text, stamps a sha-256 hash header, and writes
    //      the generated module to the language entry's generated_path via
    //      Wormhole. Re-mount picks up the artifact and the resolver's hash
    //      check then takes the fast path.
    //
    // Deposits onto H:
    //   LangLang_plan(A, w)            — called once by Lang_plan
    //   LangLang_tick(A, w)            — called by Lang(A,w) every tick;
    //                                   sync; updates dropdown value and
    //                                   gen button disabled/label
    //   e_Lang_set_lang(A, w, e)      — dropdown on_pick handler
    //   e_Lang_generate_parser(...)   — gen button handler

    import { _C, TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { onMount } from "svelte"
    import { buildParserFile } from "@lezer/generator"
    import { REGISTRY, LANG_OPTIONS } from "$lib/O/lang/registry"
    import { sha_hex, lang_for_path } from "$lib/O/lang/lang"

    let { M } = $props()

    // Build the .grammar.ts module the resolver expects: header comment for
    // humans, the buildParserFile output, plus a grammar_hash export the
    // resolver checks (avoids comment-parsing on the fast path).
    function build_generated_module(parser_src: string, hash: string, name: string): string {
        return `// auto-generated from ${name}.grammar — do not edit by hand
// hash: ${hash}
/* eslint-disable */
${parser_src}
export const grammar_hash = ${JSON.stringify(hash)}
`
    }

    onMount(async () => {
    await M.eatfunc({

    // Register the two header actions once. Same shape as Lang_plan's other
    // actions — wa.oai with role in the keying universal so re-runs are
    // find-or-create (no wildcard wipe possible).
    async LangLang_plan(A: House, w: TheC) {
        const H  = this as House
        const wa = H.oai_enroll(H, { watched: 'actions' })

        wa.oai({ action: 1, role: 'lang_pick' }, {
            kind:    'dropdown',
            label:   'language',
            icon:    '✎',
            options: LANG_OPTIONS,
            value:   'stho',
            on_pick: (next: string) =>
                H.i_elvisto('Lang/Lang', 'Lang_set_lang', { lang: next }),
        })

        // gen_parser starts disabled. LangLang_tick flips it on when the
        // active doc is a registered .grammar source. The fn re-derives the
        // target language name from the active dock at fire time, so the
        // closure doesn't need updating per tick.
        wa.oai({ action: 1, role: 'gen_parser' }, {
            label:    'gen',
            icon:     '⚙',
            disabled: true,
            fn: () => H.i_elvisto(w, 'Lang_generate_parser', {}),
        })
    },

    // Sync per-tick updates. Each particle is mutated in place and
    // bump_version'd only when a watched field actually changed.
    LangLang_tick(A: House, w: TheC) {
        const H   = this as House
        const wa  = H.o({ watched: 'actions' })[0] as TheC | undefined
        if (!wa) return
        const dock = H.Lang_active_dock(w) as TheC | undefined
        const path = dock?.sc.dock as string | undefined

        // ── lang_pick.value tracks the active doc ────────────────────────
        const pickC = wa.o({ action: 1, role: 'lang_pick' })[0] as TheC | undefined
        if (pickC) {
            const want = (dock?.sc.lang_override as string)
                ?? (path ? lang_for_path(path) : 'stho')
            if (pickC.sc.value !== want) {
                pickC.sc.value = want
                pickC.bump_version()
            }
        }

        // ── gen_parser.disabled/label track whether dock is a .grammar ──
        const matched = path
            ? Object.entries(REGISTRY).find(([, e]) => e.grammar_path === path)
            : null
        const genC = wa.o({ action: 1, role: 'gen_parser' })[0] as TheC | undefined
        if (genC) {
            const want_label    = matched ? `gen ${matched[0]}` : 'gen'
            const want_disabled = !matched
            let changed = false
            if (genC.sc.label !== want_label) {
                genC.sc.label = want_label
                changed = true
            }
            if (!!genC.sc.disabled !== want_disabled) {
                genC.sc.disabled = want_disabled
                changed = true
            }
            if (changed) genC.bump_version()
        }
    },

    // Update the per-doc language override. Langui's $effect notices the
    // change via active_dock.version and reconfigures the language
    // Compartment.
    async e_Lang_set_lang(A: TheC, w: TheC, e: TheC) {
        const H = this as House
        const dock = H.Lang_active_dock(w) as TheC | undefined
        if (!dock) return
        const next = e.sc.lang as string
        if (!next) return
        if (dock.sc.lang_override === next) return
        dock.sc.lang_override = next
        dock.bump_version()
        H.i_elvisto(w, 'think')
    },

    // Read the active grammar doc's current text, run buildParserFile,
    // stamp a hash header, write to the registry entry's generated_path
    // via the same Wormhole rw_op pathway Lies uses.
    //
    // Target language name re-derived from active dock when e.sc.name is
    // absent — lets the plan-time button closure stay constant.
    async e_Lang_generate_parser(A: TheC, w: TheC, e: TheC) {
        const H = this as House
        let name = e.sc.name as string | undefined
        const dock = H.Lang_active_dock(w) as TheC | undefined
        const path = dock?.sc.dock as string | undefined
        if (!name && path) {
            const matched = Object.entries(REGISTRY).find(([, en]) => en.grammar_path === path)
            if (matched) name = matched[0]
        }
        if (!name) { w.i({ see: '⚠ gen: no active grammar' }); return }

        const entry = REGISTRY[name]
        if (!entry?.generated_path) {
            w.i({ see: `⚠ gen: ${name} has no generated_path` })
            return
        }

        // The generated parser must match the grammar text on SCREEN, so read the LIVE
        //  view.state (Lang_handover.md §7, role #1), falling back to dock.c.state if no view.
        const state = ((dock?.c.view as any)?.state ?? dock?.c.state) as { doc: { toString(): string } } | undefined
        if (!state) { w.i({ see: '⚠ gen: no active editor state' }); return }
        const source = state.doc.toString()

        // Re-entrancy guard: if a Pending Gen job exists for this path,
        // a previous tick already issued the rw_op and we're polling.
        const existing = w.o({ Gen: 1, path: entry.generated_path })[0] as TheC | undefined
        if (!existing) {
            let built: { parser: string, terms: string }
            try {
                built = buildParserFile(source)
            } catch (err: any) {
                w.i({ see: `⚠ gen: ${err?.message ?? err}` })
                console.warn(`gen parser failed:`, err)
                return
            }
            const hash = await sha_hex(source)
            const body = build_generated_module(built.parser, hash, name)
            w.i({ Gen: 1, path: entry.generated_path, body, hash })
        }

        const job = w.o({ Gen: 1, path: entry.generated_path })[0] as TheC
        const rw  = w.oai({ rw_queue: 1 })   // off-pump queue: serial %req items, owner-driven
        const req = await rw.oai(
            { req: 'gen_parser_write', name, path: entry.generated_path },
            { rw_op: 'write', rw_name: entry.generated_path, rw_data: job.sc.body as string },
        )
        if (!H.i_elvis_req(w, 'Wormhole', 'rw_op', { req })) {
            w.i({ see: `⏳ gen: writing ${entry.generated_path}…` })
            return
        }

        await w.r({ Gen: 1, path: entry.generated_path }, {})
        w.i({ see: `✅ gen: wrote ${entry.generated_path}` })
        H.i_elvisto(w, 'think')
    },

    })
    })
</script>
