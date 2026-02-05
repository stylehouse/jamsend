<script lang="ts">
    import { onMount } from "svelte";

    // all F must host data:
    import Thingstashed from "./data/Thingstashed.svelte";
    import Modus from "./mostly/Modus.svelte";
    import { OurIdzeug, OurPeering, OurPier, Trusting, TrustingModus } from "./Trust.svelte.ts";
    import Things from "./data/Things.svelte";
    import type { Peerily } from "./p2p/Peerily.svelte.ts";
    import Trust from "./ghost/Trust.svelte";

    let {P}:{P:Peerily} = $props()
    let F:Trusting = $state()
    onMount(() => {
        F = P.Trusting = new Trusting({P})
    })
    let M = $derived(F?.modus) as TrustingModus
    let w = $derived(M?.w)
    // < our Modus 
    let increase = () => {
        M.i_elvis(w, "increase", { thingsing: "L" });
    }
    let jsonit = (s) => JSON.parse(JSON.stringify(s))
    let grip = () => {
        console.log("Grip: ",JSON.parse(JSON.stringify(M.stashed)))
    }
    let boing = (S) => {
        if (!S.instance) {
            return console.warn("Noinst")
        }
        if (!S.instance.stashed) {
            return console.warn("Nostashed")
        }
        S.instance.stashed.threeing = 3
    }
    // < move all this Thingstashed into Things because of an Ss.indication_of_such

    //    < configure Idzeug.stashed.give_them_trust
    //       from checkboxes of Features
    
    // < bizzarely needing this delay!?
    let appearing_Peering = $state(false);
    let whatsit = (S) => {
        return S.instance?.Id?.pretty_pubkey()
    }
    onMount(() => {
        setTimeout(() => appearing_Peering = true, 500)
    })

    let loaded = false
    $effect(() => {
        if (loaded) return
        if (!M?.stashed) return
        if (M.stashed.NoHeavyComputing != null) {
            F.P.NoHeavyComputing = M.stashed.NoHeavyComputing
        }
        if (M.stashed.showDetails != null) {
            showDetails = M.stashed.showDetails
        }
        if (M.stashed.NoRadio != null) {
            NoRadio = M.stashed.NoRadio
        }
        loaded = true
    })
    let showDetails = $state(false)
    let NoRadio = $state(false)
    let NoHeavyComputing = $derived(F?.P?.NoHeavyComputing)
    function tognoheavy(e) {
        let is = e.target.checked
        F.P.NoHeavyComputing = is
        M.stashed.NoHeavyComputing = is
    }
    function togdetails(e) {
        M.stashed.showDetails = showDetails = !showDetails
    }
    function tognoradio(e) {
        let is = e.target.checked
        M.stashed.NoRadio = NoRadio = is
    }

</script>

<div class='levity Trusting'>
<h2>Trust!</h2>
{#if F}
    <button onclick={increase} >increase</button>
    <button onclick={() => grip()} >grip</button>
    <input type="checkbox"
        onchange={(e) => tognoheavy(e)}
        id="NoHeavyComputing" checked={NoHeavyComputing} /> 
        <label for="NoHeavyComputing">
            NoHeavyComputing
        </label>
    <input type="checkbox"
        onchange={(e) => tognoradio(e)}
        id="NoRadio" checked={NoRadio} /> 
        <label for="NoRadio">
            NoRadio
        </label>



    <Modus S={F} do_start=1></Modus>

    {#snippet Stashedness(S)}
        <p>{JSON.stringify(S.stashed)}</p>
        <!-- is usually handled by S.M.init_stashed_memory(), which gizmos -->
        {#if S.started}
            <p><Thingstashed {F} M={S} /></p>
        {/if}
    {/snippet}


    <!-- and then we have to have these things exist to get S.stashed
         which we wait for sometimes somewhere -->

    <p>Our data <button onclick={togdetails}>show|hide</button></p>
    <div class:invis={!showDetails}>
    <h3>Our Idzeugs</h3>
    <Things
            Ss={F.OurIdzeugs}
            type="ouridzeug" 
        >
            {#snippet thing(S:OurIdzeug)}
                {@const levity = console.log(`UI:Trusting/Idzeug:${S.name}`)}
                <div class='levity Idzeug'>
                    <p>an Idzeug</p>
                    <button onclick={() => boing(S)} >boing</button>

                    

                    {#if S.name.match(/[^\w+ -]/)}
                        <p>Name contains illegal characters. Delete and add another. </p>
                    {/if}
                    {@render Stashedness(S)}
                </div>
            {/snippet}
    </Things>



    <h3>Our Peerings</h3>
    <Things
            Ss={F.OurPeerings}
            type="ourpeering" 
        >
            {#snippet thing(S:OurPeering)}
                <div class='levity Peering'>
                    {#if appearing_Peering}
                        <p>a Peering: {whatsit(S)}</p>
                    {/if}
                    {@render Stashedness(S)}
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
                    <button onclick={() => boing(S)} >boing</button>
                    {@render Stashedness(S)}
                </div>
            {/snippet}
    </Things>
    </div>
    
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
    .Idzeug {
        border-left: 2em solid rgb(115, 19, 139);
    }
    .levity {
        margin-left:-1em;
        border-radius:2em;
    }
    .invis {
        display:none;
    }
    summary {
        font-size: 1.6em;
        padding: 1em;
    }
    p {
        word-break: break-all;
    }
</style>
