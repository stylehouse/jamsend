<script lang="ts">
    // LangGen.svelte — language picker + parser-generation sub-ghost.
    //
    // Two Lang-header-adjacent concerns:
    //
    //   1. Language picker
    //      A dropdown listing names from $lib/O/lang/registry. Default per
    //      doc comes from file extension (lang_for_path). Override persists
    //      at docC.sc.lang_override and survives reload. Langui watches the
    //      override and reconfigures the editor's language Compartment on
    //      change — no remount.
    //
    //   2. Parser generation
    //      When the active doc's path matches a registered language's
    //      grammar_path, a "gen" action appears. It runs @lezer/generator's
    //      buildParserFile on the editor's current text, stamps a sha-256
    //      hash header, and writes the generated module to the language
    //      entry's generated_path via Wormhole. Next mount the resolver
    //      compares hashes and uses the artifact via fast path when matched.
    //
    //      Generation is one-off — the rw_op pattern follows Lies's writes:
    //      requesty_serial → oai with rw_op:'write' → i_elvis_req. If the
    //      Wormhole hasn't settled by the time we return, the eatfunc tick
    //      polling re-runs us; once req is fulfilled we don't refire.
    //
    // Deposits onto H:
    //   LangGen_tick(A, w)            — called by Lang(A,w) every tick
    //   e_Lang_set_lang(A, w, e)      — dropdown on_pick handler
    //   e_Lang_generate_parser(...)   — gen button handler

    import { _C, TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { onMount } from "svelte"
    import { buildParserFile } from "@lezer/generator"
    import { REGISTRY, LANG_OPTIONS } from "$lib/O/lang/registry"
    import { sha_hex, lang_for_path } from "$lib/O/lang/lang"

    let { M } = $props()

    // Build the .grammar.ts module the resolver expects: a header comment
    // for humans, the buildParserFile output, plus a grammar_hash export
    // the resolver checks (avoids comment-parsing).
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

    // Refresh actions for the current active doc. Called from Lang(A,w).
    async LangGen_tick(A: House, w: TheC) {
        const H    = this as House
        const wa   = H.oai_enroll(H, { watched: 'actions' })
        const docC = H.Lang_active_docC(w) as TheC | undefined
        const path = docC?.sc.doc as string | undefined

        const current_lang = (docC?.sc.lang_override as string)
            ?? (path ? lang_for_path(path) : 'stho')

        await wa.r({ action: 1, role: 'lang_pick' }, {
            kind:    'dropdown',
            label:   'language',
            icon:    '✎',
            value:   current_lang,
            options: LANG_OPTIONS,
            on_pick: (next: string) =>
                H.i_elvisto('Lang/Lang', 'Lang_set_lang', { lang: next }),
        })

        // Gen action: only when the active doc IS a registered grammar source.
        const matched = path
            ? Object.entries(REGISTRY).find(([, e]) => e.grammar_path === path)
            : null

        if (matched) {
            const [matched_name] = matched
            await wa.roai({ action: 1, role: 'gen_parser' }, {
                label: `gen ${matched_name}`,
                icon:  '⚙',
                fn: () => H.i_elvisto(w, 'Lang_generate_parser', { name: matched_name }),
            })
        } else {
            // particle absent = not rendered by Actions
            await wa.r({ action: 1, role: 'gen_parser' }, {})
        }
    },

    // Update the per-doc language override. Langui's $effect notices the
    // change via docC.version and reconfigures the language Compartment.
    async e_Lang_set_lang(A: TheC, w: TheC, e: TheC) {
        const H = this as House
        const docC = H.Lang_active_docC(w) as TheC | undefined
        if (!docC) return
        const next = e.sc.lang as string
        if (!next) return
        if (docC.sc.lang_override === next) return
        docC.sc.lang_override = next
        docC.bump_version()
        H.i_elvisto(w, 'think')
    },

    // Read the active grammar doc's current text, run buildParserFile, stamp
    // a hash header, write to the registry entry's generated_path via the
    // same Wormhole rw_op pathway Lies uses for Waft snaps and compile output.
    async e_Lang_generate_parser(A: TheC, w: TheC, e: TheC) {
        const H = this as House
        const name = e.sc.name as string
        const entry = REGISTRY[name]
        if (!entry?.generated_path) {
            w.i({ see: `⚠ gen: ${name} has no generated_path` })
            return
        }

        const docC  = H.Lang_active_docC(w) as TheC | undefined
        const state = docC?.c.state as { doc: { toString(): string } } | undefined
        if (!state) { w.i({ see: '⚠ gen: no active editor state' }); return }
        const source = state.doc.toString()

        // Re-entrancy guard: if we have a Pending gen for this path on w,
        // a previous tick already issued the rw_op and we're just polling.
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
        const rw  = await H.requesty_serial(w, 'rw_queue')
        const req = await rw.oai(
            { gen_parser_write: 1, name, path: entry.generated_path },
            { rw_op: 'write', rw_name: entry.generated_path, rw_data: job.sc.body as string },
        )
        if (!H.i_elvis_req(w, 'Wormhole', 'rw_op', { req })) {
            w.i({ see: `⏳ gen: writing ${entry.generated_path}…` })
            return   // resumes on the next tick once Wormhole settles
        }

        // Settled — clean up the job and notify.
        await w.r({ Gen: 1, path: entry.generated_path }, {})
        w.i({ see: `✅ gen: wrote ${entry.generated_path}` })
        H.i_elvisto(w, 'think')
    },

    })
    })
</script>
