<script lang="ts">
    import { onMount } from "svelte";

    // all F must host data:
    import Thingstashed from "./data/Thingstashed.svelte";
    import Modus from "./mostly/Modus.svelte";
    import { Trusting } from "./Trust.svelte.ts";

    let {P} = $props()
    let F = $state()
    onMount(() => {
        F = P.Trusting = new Trusting({P})
    })
    let w = $derived(F?.w)
    let M = $derived(F?.modus)
    // < our Modus 
    let increase = () => {
        M.i_elvis(w, "increase", { thingsing: "L" });
    }

</script>

<h2>Trust!</h2>
{#if F}
    <button onclick={increase} >increase</button>

    <Modus S={F} do_start=1 do_stash=1></Modus>

    and that's all.
{/if}