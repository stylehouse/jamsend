<script lang="ts">
    import type { PeeringSharing, PierSharing } from "$lib/p2p/ftp/Sharing.svelte";
    import type { DirectoryShare } from "$lib/p2p/ftp/Directory.svelte";
    import type { Modus as SomeModus , Modusmem } from "$lib/mostly/Modus.svelte.ts";
    import Stuffing from "$lib/data/Stuffing.svelte";
    import { onDestroy, onMount } from "svelte";
    import Strata from "$lib/data/Strata.svelte";
    import { SoundSystem } from "$lib/p2p/ftp/Audio.svelte";
    import Scrollability from "$lib/p2p/ui/Scrollability.svelte";
    import GatHaving from "$lib/p2p/ui/GatHaving.svelte";

    type Sthing = PeeringSharing | PierSharing | DirectoryShare
    let {S}:{S:Sthing} = $props()

    let M:SomeModus = $state()
    let gat:SoundSystem = $state()
    onMount(() => {
        if (!S) throw "!S"
        M = S.modus = S.modus_init()
        gat = M.gat = new SoundSystem({M})
    })
    $effect(() => {
        if (S.started) {
            S.modus.main()
        }
    })
    onDestroy(() => {
        M.stop()
    })




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


</script>

{#if M}
<p>
    I am a {M.constructor.name} 
    {#if gat}with a gat. <GatHaving {gat}/>{/if}
    <button onclick={stashy}>stashy</button>
    <button onclick={lets_redraw}>redraw</button>
</p>
<Scrollability maxHeight="80vh" class="content-area">
    {#snippet content()}
    {#key redraw_version}

        <Stuffing mem={M.imem('current')} stuff={M.current} {M} />

        {#if M.coms} <Stuffing mem={M.imem('coms')} stuff={M.coms} />{/if}

        {#if strata}
            <Strata {M} {strata} mem={M.imem('Strata')} />
        {/if}
        
    {/key}
    {/snippet}
</Scrollability>
{/if}



<style>
</style>