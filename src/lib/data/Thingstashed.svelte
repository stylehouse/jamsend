<script lang="ts">
    import { throttle } from "$lib/Y";
    import type { KVStore } from "./IDB.svelte";
    import { objectify } from "./Stuff.svelte";
    import type { ThingIsms } from "./Things.svelte";

    type stashedHaver = Object & {stashed:Object,stashed_mem:KVStore}
    let {S,name,M}:{
        S:ThingIsms,
        name:string,
        M:stashedHaver,
    } = $props()

    let save_stash = throttle(() => {
        console.log(`saving stashedHaver ${name}`)
        let it = JSON.stringify(M.stashed)
        M.stashed_mem.put(it)
    },200)

    $effect(async () => {
        if (!M.stashed) {
            let json = await M.stashed_mem.get()
            M.stashed = json && JSON.parse(json) || {}
            if(json) {
                console.log(`stashedHaver ${name} loaded`,M.stashed)
            }
        }
        if (Object.entries(M.stashed)) {
            console.log(`stashedHaver save...`)
            save_stash()
        }
    })
    // $inspect('stashedHaver ',M.stashed)
</script>