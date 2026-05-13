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
// Four steps of waft mutation; UI reads all_wafts inside H.clear() so it
// never catches waft.o() mid-replace returning [].
//
// Step 1: init — Lies + two wafts + one doc each
// Step 2: add a second doc to waft1
// Step 3: add a new waft (waft3) — tests whether UI picks it up without remount
// Step 4: rename a doc in waft1 via replace()
//
// The {#each} in the UI is keyed by waft.sc.Waft. WaftComp onMount fires only
// on true remount; 'render' fires on every {#each} re-derive. The logger
// shows which events trigger which, across the H.clear() boundary.

    async ReactiveWaft(A: TheC, w: TheC) {
        const H  = this as House
        const ave = H.oai_enroll(H, { watched: 'ave' })
        const li  = H.c.loggeri as ((end: string, sc?: Record<string,any>) => void) | undefined

        const lies = w.oai({ Lies: 1 })
        if (!w.c.initdone) {
            w.c.initdone = 1

            lies.c.w   = w
            ave.i(lies)

            const waft1 = w.oai({ Waft: 'test1' })
            const waft2 = w.oai({ Waft: 'test2' })
            waft1.i({ Doc: 1, path: 'a.g' })
            waft2.i({ Doc: 1, path: 'x.g' })
            ave.i(waft1)
            ave.i(waft2)

            H.logger(w)

            H.oai_enroll(H, { watched: 'UIs' })
                .oai({ UI: 'ReactiveWaft', component: ReactiveWaft })
        }

        await H.on_step({
            2: () => {
                li?.('add doc to test1')
                w.oai({ Waft: 'test1' }).i({ Doc: 1, path: 'b.g' })
                ave.bump_version()
            },
            3: () => {
                lies.c.be_weird = true
                li?.('add waft3')
                const waft3 = w.oai({ Waft: 'test3' })
                waft3.i({ Doc: 1, path: 'q.g' })
                ave.i(waft3)
                ave.bump_version()
            },
            4: async () => {
                li?.('rename doc in test1')
                await w.oai({ Waft: 'test1' }).r(
                    { Doc: 1, path: 'a.g' },
                    { Doc: 1, path: 'aa.g' },
                )
                ave.bump_version()
            },
            5: async () => {
                lies.c.be_weird = false
            },
        })
    },




//#endregion




    })
    })
</script>
