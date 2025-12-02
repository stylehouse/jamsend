<script lang="ts">
    import type { Modus } from "$lib/data/Stuff.svelte";
    import Stuffing from "$lib/data/Stuffing.svelte";
    import { throttle } from "$lib/Y";
    import { onDestroy } from "svelte";
    import NotPier from "../p2p/ui/repro-reactive-stashed-hierarchy/NotPier.svelte";
    import Strata from "$lib/data/Strata.svelte";

    let {M}:{M:Modus} = $props()


    let redraw_version = $state(1)
    let lets_redraw = () => {
        let N = M.o()
        // console.log("reacting to M.current.version=="+M.current.version, N)
        redraw_version++
    }
    $effect(() => {
        if (M.current.version) {
            if (M.current.X_before) return
            // setTimeout(() => lets_redraw(), 140)
        }
    })
    function stashy() {
        M.stashed.things = 3
    }

    let strata = $derived(M.a_Strata)


    onDestroy(() => {
        M.stop()
    })
</script>

    <button onclick={stashy}>stashy</button>
    <button onclick={lets_redraw}>redraw</button>

    {#key redraw_version}
        <Stuffing mem={M.imem('current')} stuff={M.current} {M} />
        {#if M.coms} <Stuffing mem={M.imem('coms')} stuff={M.coms} />{/if}
        {#if strata}
            <Strata {M} {strata} mem={M.imem('Strata')} />
        {/if}
    {/key}


<style>
</style>