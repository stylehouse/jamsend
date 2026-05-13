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
// Minimal Liesui/WaftComp emulation.
//
// Structure mirrors Liesui:
//   ave/{Lies:1}       — the examining-like signal; Liesui gates {#if Lies} on this
//   w/{Waft:'test1'}   — first waft, has a Doc added at step 1
//   w/{Waft:'test2'}   — second waft, unchanged
//
// The UI (ReactiveWaft.svelte) logs:
//   - whenever Lies ($state) is assigned (object identity change = remount)
//   - onMount of each WaftComp instance
//   - whenever adding_doc flips (the form open/close event we're hunting)
//
// Step 1 adds a Doc to test1 and bumps ave — mimicking Story trickle, which
// drives a flush that may churn examining and reassign Lies.

    async ReactiveWaft(A: TheC, w: TheC) {
        const H  = this as House
        const ave = H.oai_enroll(H, { watched: 'ave' })
        const li  = H.c.loggeri as ((end: string, sc?: Record<string,any>) => void) | undefined

        if (!w.c.initdone) {
            w.c.initdone = 1

            // Lies particle — mimics examining; Liesui reads this to gate {#if Lies}
            const lies = w.oai({ Lies: 1 })
            lies.c.w   = w           // back-ref, as in real Lies
            ave.i(lies)

            // two wafts with one pre-existing doc each
            const waft1 = w.oai({ Waft: 'test1' })
            const waft2 = w.oai({ Waft: 'test2' })
            waft1.i({ Doc: 1, path: 'a.g' })
            waft2.i({ Doc: 1, path: 'x.g' })
            ave.i(waft1)
            ave.i(waft2)

            H.logger(w)
            w.oai({ logger: 1 })   // ensure it exists for UI

            H.oai_enroll(H, { watched: 'UIs' })
                .oai({ UI: 'ReactiveWaft', component: ReactiveWaft })
        }

        // step 1: add a doc — bumps waft.version and ave.version, exactly as
        // Story trickle does when a Lies worker tick touches the waft tree
        await H.on_step({
            1: async () => {
                li?.('Aw', { adding_doc: 'b.g', to: 'test1' })
                const waft1 = w.oai({ Waft: 'test1' })
                waft1.i({ Doc: 1, path: 'b.g' })
                waft1.bump_version()
                ave.bump_version()
                li?.('Aw', { added: 'b.g' })
            },
        })
    },




//#endregion




    })
    })
</script>
