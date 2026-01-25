<script lang="ts">
    import { onMount } from "svelte";

    // all F must host data:
    import Thingstashed from "./data/Thingstashed.svelte";
    import Modus from "./mostly/Modus.svelte";
    import { OurPeering, Trusting } from "./Trust.svelte.ts";
    import Things from "./data/Things.svelte";

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
    let grip = (S) => {
        console.log("Grip: ",S)
        setTimeout(() => S.stashed.fings = 3,1300)
    }


</script>

<h2>Trust!</h2>
{#if F}
    <button onclick={increase} >increase</button>

    <Modus S={F} do_start=1></Modus>

    <h3>Our Peerings</h3>
    <Things
            Ss={F.OurPeerings}
            type="ourpeering" 
        >
            {#snippet thing(S:OurPeering)}
                <p>a Peering</p>
                { grip(S) }

                <!-- is usually handled by S.M.init_stashed_memory(), which gizmos -->
                {#if S.started}
                    <Thingstashed {F} M={S} />
                {/if}
            {/snippet}
    </Things>
    <h3>Our Piers</h3>

    
    {#if M}
        <!-- is usually handled by F.gizmos -->
        <Thingstashed {F} {M} />
    {/if}
{/if}