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
// Nine beliefs ticks: init + 8 i_elvis handlers.
// Three o_elvis types — add_doc, set_active, rename_doc.
//
// Measures how many times the ungated (waft.version) subscription fires
// vs the gated (H.ave.version) subscription per tick.
// rename_doc uses waft.r() which calls replace() with await gaps —
// the ungated subscription fires at each gap: empty, partial, full.
//
// H.c.UIlog writes into w/{logC:1}/* so every UI observation is in the snap.
// H.trace() mirrors each entry to the Run trace for timing context.
//
// The logC TheC is enrolled in ave alongside waft, so the UI reaches it
// via H.ave.ob({logC:1})[0].  Its version is a fine-grained subscription:
// only logC.i() bumps it — not H.ave.version — so reading log rows
// never subscribes to the whole ave channel.

    async ReactiveWaft(A: TheC, w: TheC) {
        const H     = this as House
        const waft  = w.oai({ Waft: 'test' })
        const ave_s = H.oai_enroll(H, { watched: 'ave' })

        const init = w.oai({ Storyinit: 1 })
        if (!init.sc.done) {
            init.sc.done = 1

            // seed the waft with one doc before any elvis fires
            waft.i({ Doc: 1, path: 'a.g' })

            // logC: dedicated log container, enrolled in ave so the UI can reach it.
            // UIlog writes here from UItime (via setTimeout in the UI's $effects).
            const logC = w.oai({ logC: 1 })
            ave_s.i(waft)
            ave_s.i(logC)

            H.c.UIlog = (src: string, extra: Record<string, any> = {}) => {
                // called from UItime — no setTimeout needed here, callers use it
                logC.i({ uiLog: 1, src, ...extra })
                H.trace(`UI:${src}`)
            }

            const uis = H.oai_enroll(H, { watched: 'UIs' })
            uis.oai({ UI: 'ReactiveWaft', component: ReactiveWaft })

            // 8 sequential elvisses → 8 more beliefs ticks after this one
            H.i_elvis(w, 'add_doc',    { path: 'b.g' })
            H.i_elvis(w, 'add_doc',    { path: 'c.g' })
            H.i_elvis(w, 'set_active', { path: 'a.g' })
            H.i_elvis(w, 'set_active', { path: 'b.g' })
            H.i_elvis(w, 'set_active', { path: 'c.g' })
            H.i_elvis(w, 'rename_doc', { old: 'a.g', new: 'aa.g' })
            H.i_elvis(w, 'set_active', { path: 'aa.g' })
            H.i_elvis(w, 'set_active', { path: 'b.g'  })
        }

        // ── o_elvis handlers ────────────────────────────────────────────────────

        for (const e of H.o_elvis(w, 'add_doc')) {
            waft.i({ Doc: 1, path: e.sc.path as string })
            ave_s.bump_version()
        }

        for (const e of H.o_elvis(w, 'set_active')) {
            const target = e.sc.path as string
            for (const doc of waft.o({ Doc: 1 }) as TheC[]) {
                if (doc.sc.path === target) doc.sc.active = 1
                else                        delete (doc.sc as any).active
            }
            waft.bump_version()
            ave_s.bump_version()
        }

        for (const e of H.o_elvis(w, 'rename_doc')) {
            // waft.r() calls replace() — await gaps between empty/fill/resolve
            // are where ungated fires mid-cycle while gated is still silent
            await waft.r(
                { Doc: 1, path: e.sc.old as string },
                { Doc: 1, path: e.sc.new as string },
            )
            ave_s.bump_version()
        }
    },




//#endregion




    })
    })
</script>
