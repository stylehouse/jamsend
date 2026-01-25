<script lang="ts">
    import type { PeeringFeature } from "$lib/p2p/Peerily.svelte.ts";
    import { throttle } from "$lib/Y";
    import type { KVStore } from "./IDB.svelte";
    import type { ThingIsms } from "./Things.svelte.ts";

    type stashedHaver = Object & {stashed:Object,stashed_mem:KVStore}
    let {F,name,M}:{
        F:PeeringFeature,
        name?:string,
        M:stashedHaver,
    } = $props()
    // for debug
    name ||= M.constructor.name

    let save_stash = throttle(() => {
        let it = JSON.stringify(M.stashed)
        M.stashed_mem.put(it)
        // console.log(`stashedHaver ${name} saved`)
    },200)

    $effect(async () => {
        if (!M.stashed) {
            let json = await M.stashed_mem.get()
            M.stashed = json && JSON.parse(json) || {}
            if (json) {
                // console.log(`stashedHaver ${name} loaded`)
            }
        }
        if (Object.entries(M.stashed)) {
            // console.log(`stashedHaver ${name} saving...`)
            save_stash()
        }
    })
    // $inspect('stashedHaver ',M.stashed)
</script>