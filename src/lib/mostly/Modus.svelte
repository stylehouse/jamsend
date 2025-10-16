<script lang="ts">
    import type { Modus } from "$lib/data/Stuff.svelte";
    import Stuffing from "$lib/data/Stuffing.svelte";
    import { throttle } from "$lib/Y";
    import { onDestroy } from "svelte";
    import NotPier from "../p2p/ui/repro-reactive-stashed-hierarchy/NotPier.svelte";

    let {M}:{M:Modus} = $props()

    let stuffocks = $state([])
    // data dumper
    function objectify(v:any):string {
        return typeof v == 'number' || typeof v == 'string' ? v
            : v == null ? 'null'
            : v.constructor == Array ? `[${v.map(n => objectify(n)).join(',')}]`
            : `${v.constructor.name}()`
    }

    // aka brackology
    let redraw = throttle((N) => restuffock(N), 1000/25)
    let lets_redraw = () => {
        let N = M.o()
        // console.log("reacting to M.current.version=="+M.current.version, N)
        redraw(N)
    }
    $effect(() => {
        if (M.current.version) {
            if (M.current.X_before) return
            // setTimeout(() => lets_redraw(), 140)
        }
    })

    function restuffock(N) {
        // console.log("restuffock "+(N.length))
        stuffocks = []
        M.o().forEach((n) => {
            let stuff = []
            Object.entries(n.sc).forEach(([k,v]) => {
                let say = objectify(v)
                stuff.push({k,say})
            })
            stuff.slice(-1)[0].last = 1
            stuffocks.push(stuff)
        })
    }
    onDestroy(() => {
        M.stop()
    })
</script>

    <button onclick={redraw}>redraw</button>

            {#each Object.entries(stuffocks) as [i,stuff] (i)}
                <span class=stuffock>
                    {#each Object.entries(stuff) as [i,s] (i)}
                        <span class=stuff>
                            <label>{s.k}
                            </label>{#if s.say != 1}
                                    :{s.say}
                                {/if}
                        </span>{#if !s.last}, {/if}
                    {/each}
                    {" "}
                </span>
            {/each}


        <Stuffing stuff={M.current} />
        {#if M.dump}<Stuffing stuff={M.dump} />{/if}
<style>
    .stuffock {
        margin: 1em;
    }
    .stuffock label {
        color:rgb(77, 179, 165);
    }
    .stuff {
        white-space: pre;
    }
</style>