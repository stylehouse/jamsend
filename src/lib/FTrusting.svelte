<script lang="ts">
    import { onMount } from "svelte";

    // all F must host data:
    import Thingstashed from "./data/Thingstashed.svelte";
    import Modus from "./mostly/Modus.svelte";
    import { OurPeering, OurPier, Trusting } from "./Trust.svelte.ts";
    import Things from "./data/Things.svelte";
    import type { Peerily } from "./p2p/Peerily.svelte.ts";
    import Trust from "./ghost/Trust.svelte";

    let {P}:{P:Peerily} = $props()
    let F:Trusting = $state()
    onMount(() => {
        F = P.Trusting = new Trusting({P})
    })
    let M = $derived(F?.modus)
    let w = $derived(M?.w)
    // < our Modus 
    let increase = () => {
        M.i_elvis(w, "increase", { thingsing: "L" });
    }
    let grip = (S) => {
        console.log("Grip: ",JSON.parse(JSON.stringify(M.stashed)))
        setTimeout(() => S.stashed.fings = 3,1300)
    }
</script>

<div class='levity Trusting'>
<h2>Trust!</h2>
{#if F}
    <button onclick={increase} >increase</button>
    <button onclick={grip} >grip</button>



    <Modus S={F} do_start=1></Modus>


    <!-- and then we have to have these things exist to get S.stashed
         which we wait for sometimes somewhere -->



    <h3>Our Peerings</h3>
    <Things
            Ss={F.OurPeerings}
            type="ourpeering" 
        >
            {#snippet thing(S:OurPeering)}
                <div class='levity Peering'>
                    <p>a Peering</p>

                    <!-- is usually handled by S.M.init_stashed_memory(), which gizmos -->
                    {#if S.started}
                        <Thingstashed {F} M={S} />
                    {/if}
                </div>
            {/snippet}
    </Things>


    <h3>Our Piers</h3>
    <Things
            Ss={F.OurPiers}
            type="ourpier" 
        >
            {#snippet thing(S:OurPier)}
                {@const levity = console.log(`UI:Trusting/Pier:${S.name}`)}
                <div class='levity Pier'>
                    <p>a Pier</p>

                    <!-- is usually handled by S.M.init_stashed_memory(), which gizmos -->
                    {#if S.started}
                        <Thingstashed {F} M={S} />
                    {/if}
                </div>
            {/snippet}
    </Things>

    
    {#if M}
        <!-- is usually handled by F.gizmos -->
        <Thingstashed {F} {M} />
        <!-- is a bunch of code that can load into M.* without tearing down all this -->
        <Trust {M} />
    {/if}
{/if}
</div>
<style>
    .Trusting {
        border-left: 2em solid rgb(30, 100, 165);
    }
    .Peering {
        border-left: 2em solid saddlebrown;
    }
    .Pier {
        border-left: 2em solid rgb(97, 139, 19);
    }
    .levity {
        margin-left:-1em;
        border-radius:2em;
    }
</style>
