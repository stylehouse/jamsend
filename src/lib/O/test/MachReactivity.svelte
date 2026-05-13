<script lang="ts">
    import { _C, keyser, objectify, TheC, TheX } from "$lib/data/Stuff.svelte";
    import { Selection } from "$lib/mostly/Selection.svelte";
    import { register_class, WormholeNav, type House } from "$lib/O/Housing.svelte";
    import { Peerily, Peering, Pier } from "$lib/p2p/Peerily.svelte.ts";
    import { armap, depeel, enhex, Idento, nex, peel, sex } from "$lib/Y.svelte";
    import { onMount } from "svelte";
    import ReactiveWaft from "./ReactiveWaft.svelte"

    let {M} = $props()


    onMount(async () => {
    await M.eatfunc({




//#region ReactiveWaft
//
// Nine steps: init seeds the waft, on_step 2–9 fire one elvis each.
// Three o_elvis types — add_doc, set_active, rename_doc — each logs
// what it does with li('Aw', ...) before and after the mutation.
//
// logger(w) wipes w/{logger:1}/* after each snap via Runstepped,
// so the snap shows only the log for that step.
//
// The UI calls H.c.loggeri('UI', { src, docs, n }) via setTimeout(1)
// from its gated and ungated $effects — breaking out of Svelte's
// reactive tracking to avoid subscription loops.
//
// rename_doc uses waft.r() (replace()) — the ungated UI subscription
// may fire between its internal await points, showing intermediate states.
// A mid-cycle 'UI,ungated' entry appearing before 'Aw,renamed' in the log
// confirms direct waft.version exposure during Atime.



    async ReactiveWaft(A: TheC, w: TheC) {
        const H     = this as House
        const waft  = w.oai({ Waft: 'test' })
        const ave_s = H.oai_enroll(H, { watched: 'ave' })

        const li = H.c.loggeri as ((end: string, sc?: Record<string,any>) => void) | undefined

        // ── init ─────────────────────────────────────────────────────────────
        if (!w.c.initdone) {
            w.c.initdone = 1

            waft.i({ Doc: 1, path: 'a.g' })

            // enroll waft and logger into ave so the UI reaches both
            const lg = w.oai({ logger: 1 })
            ave_s.i(waft)
            ave_s.i(lg)

            H.logger(w)   // arms w.c._logger_armed, H.c.loggeri

            const uis = H.oai_enroll(H, { watched: 'UIs' })
            uis.oai({ UI: 'ReactiveWaft', component: ReactiveWaft })
        }

        // ── test driver: one elvis per step ──────────────────────────────────
        await H.on_step({
            2: () => { H.i_elvis(w, 'add_doc',    { path: 'b.g'             }) },
            3: () => { H.i_elvis(w, 'add_doc',    { path: 'c.g'             }) },
            4: () => { li?.("switching active")
                       H.i_elvis(w, 'set_active', { path: 'a.g'             }) },
            5: () => { H.i_elvis(w, 'set_active', { path: 'b.g'             }) },
            6: () => { H.i_elvis(w, 'set_active', { path: 'c.g'             }) },
            7: () => { li?.("rename")
                       H.i_elvis(w, 'rename_doc', { old: 'a.g', new: 'aa.g' }) },
            8: () => { H.i_elvis(w, 'set_active', { path: 'aa.g'            }) },
            9: () => { H.i_elvis(w, 'set_active', { path: 'b.g'             }) },
        })

        // ── o_elvis handlers ─────────────────────────────────────────────────

        for (const e of H.o_elvis(w, 'add_doc')) {
            const path = e.sc.path as string
            li?.('Aw', { adding: path })
            waft.i({ Doc: 1, path })
            li?.('Aw', { added: path, docs: doc_list(waft) })
            ave_s.bump_version()
        }

        for (const e of H.o_elvis(w, 'set_active')) {
            const target = e.sc.path as string
            li?.('Aw', { activating: target })
            for (const doc of waft.o({ Doc: 1 }) as TheC[]) {
                if (doc.sc.path === target) doc.sc.active = 1
                else                        delete (doc.sc as any).active
            }
            waft.bump_version()
            li?.('Aw', { activated: target })
            ave_s.bump_version()
        }

        for (const e of H.o_elvis(w, 'rename_doc')) {
            const { old: old_path, new: new_path } = e.sc as any
            li?.('Aw', { renaming: `${old_path}→${new_path}` })
            // waft.r() = replace() with several awaits — ungated UI subscription
            // may fire between each, exposing mid-cycle states to the UI
            await waft.r(
                { Doc: 1, path: old_path },
                { Doc: 1, path: new_path },
            )
            li?.('Aw', { renamed: `${old_path}→${new_path}`, docs: doc_list(waft) })
            ave_s.bump_version()
        }
    },




//#endregion




    })
    })


    function doc_list(waft: TheC): string {
        return (waft.o({ Doc: 1 }) as TheC[])
            .map(d => d.sc.path + ((d.sc as any).active ? '●' : ''))
            .join(' ') || '∅'
    }
</script>
