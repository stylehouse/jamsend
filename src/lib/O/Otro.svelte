<script lang="ts">
    import Agency from "$lib/ghost/Agency.svelte";
    import { onMount } from "svelte";
    import Housedemo from "./Housedemo.svelte";
    import { House } from "./Housing.svelte";


    // top level!
    let H = new House({name:'Mundo'})
    let M = H // was named Modus
    $effect(() => {
        if (H.todo.length) {
            H.answer_calls()
        }
    })
    H.i({ A: 'something' })
    H.o({ A: 'something' })[0].i({ w: 'withitall' })
    onMount(() => {
        H.post_do(async () => {
            await H.channel_beliefs(H.i({
                elvis: 'withitall',
                Aw: 'something/withitall',
                payload: 'hello',
            }))
        })
    })
</script>
<h3>Here we Are</h3>

<Agency {M} />

