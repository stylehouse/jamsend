<script lang="ts">
    import Agency from "$lib/ghost/Agency.svelte";
    import { House } from "./Housing.svelte";


    // top level!
    let H = new House({name:'Mundo'})
    let M = H // was named Modus
    $effect(() => {
        if (H.todo) {
            H.answer_calls()
        }
    })
</script>
<h3>Here we Are</h3>

<Agency {M} />