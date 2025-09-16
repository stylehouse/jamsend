<script lang="ts">
    import type { Modus } from "$lib/data/Stuff.svelte";
    import { throttle } from "$lib/Y";
    import NotPier from "./repro-reactive-stashed-hierarchy/NotPier.svelte";

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
    $effect(() => {
        if (M.current.X.serial_i) {
            redraw(M.oa())
        }
    })
    function restuffock(N) {
        stuffocks = []
        M.oa().forEach((n) => {
            let stuff = []
            Object.entries(n.sc).forEach(([k,v]) => {
                let say = objectify(v)
                stuff.push({k,say})
            })
            stuff.slice(-1)[0].last = 1
            stuffocks.push(stuff)
        })
    }
</script>


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
<b>thing</b>nesses

<style>
    .stuffock {
        margin: 1em;
    }
    .stuffock label {
        color:rgb(77, 179, 165);
    }
</style>