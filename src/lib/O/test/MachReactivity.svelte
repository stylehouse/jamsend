<script lang="ts">
    import { _C, keyser, objectify, TheC, TheX } from "$lib/data/Stuff.svelte";
    import { Selection } from "$lib/mostly/Selection.svelte";
    import { register_class, WormholeNav, type House } from "$lib/O/Housing.svelte";
    import { Peerily, Peering, Pier } from "$lib/p2p/Peerily.svelte.ts";
    import { armap, depeel, enhex, Idento, nex, peel, sex } from "$lib/Y.svelte";
    import { onMount } from "svelte";


    let {M} = $props()


    onMount(async () => {
    await M.eatfunc({




//#region StuffResolving


 
    async StuffResolving(A: TheC, w: TheC) {
        const H   = this as House
        const log = w.oai({ log: 1 }) as TheC

        let it = w.i({item:1})

        let n = it.i({blah:1})
        n.i({first:1})
        it.i({blah:1}).i({second:1})
        it.i({etc:1})

        await it.replace({}, async () => {
            it.i({blah:1})
            it.i(n)
            it.i({etc:1})
        }, { pairs_fn: async (a, b) => {
            let isn = (a) => a == n ? "n = " : ""
            log.i({
                msg:"resolved pair",
                before: a ? isn(a)+depeel(a.sc) : '-',
                after: b ? isn(b)+depeel(b.sc) : '-',
            })
        }})

        n.sc.bang = 1

 
    },
 




//#endregion




    })
    })
</script>
