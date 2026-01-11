<script lang="ts">
    import { onMount } from "svelte";

    import { _C, keyser, TheC, type TheN, type TheUniversal } from "$lib/data/Stuff.svelte.ts"
    import { SoundSystem, type Audiolet } from "$lib/p2p/ftp/Audio.svelte.ts"
    import { now_in_seconds_with_ms, now_in_seconds } from "$lib/p2p/Peerily.svelte.ts"
    import { erring, ex, grep, grop, map, sex, sha256, tex, throttle } from "$lib/Y.ts"
    import Record from "./Records.svelte";
    import Cytoscape from "$lib/mostly/Cytoscape.svelte";
   
    let {M} = $props()

    onMount(async () => {
    await M.eatfunc({

        async cytotermicaster(A,w) {
            w.i({see:"Some great visuals"})

            // "takes over" doing visuals for the Modus
            this.VJ = await w.r({VJ:w,UI_component:Cytoscape})
            for (let e of this.o_elvis(w,'IamyourUI')) {
                await w.r(sex({},e.sc,'node_edger'))
            }
            if (!w.oa({node_edger:1})) return w.i({waits:'for UI'})

            w.i({see:1,ready:1})
        },
    })
    })
</script>
