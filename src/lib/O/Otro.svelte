<script lang="ts">
    import { House } from "./Housing.svelte";


    // top level!
    let u = new House({name:'Mundo'})
    $effect(() => {
        if (u.todo) {
            u.answer_calls()
        }
    })

</script>
<h3>Here we Are</h3>