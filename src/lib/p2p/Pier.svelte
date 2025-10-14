<script lang="ts">
    import type { Pier } from "./Peerily.svelte";
    import Trusticles from "./ui/Trusticles.svelte";

    let {pier}:{pier:Pier} = $props()
    async function showstash() {
        console.log("pier",pier.stashed)
    }
    async function tweakstash() {
        pier.stashed.leg ||= 2
        pier.stashed.leg = pier.stashed.leg + 1
        pier.stashed.thinke = 3
        console.log(`Pier thinked`)
    }
    $effect(() => {
        if (Object.entries(pier.stashed)) {
            console.log(`Pier stashed save...`)
            pier.P.save_stash()
        }
    })
    $inspect('Pier shing',pier.stashed)
</script>

<div id=levity>
    Pier: {pier.pub} 
    {#if pier.disconnected}
        <span class="ohno tech">discon</span>
    {/if}
    <!-- <button onclick={showstash}>stash</button> -->
    <!-- <button onclick={tweakstash}>~~</button> -->
    <Trusticles {pier} />

    <div class=bitsies>
        {#each pier.features as [k,F] (k)}
            <div class=bitsies>
                <svelte:component this={F.UI_component} {pier} {F} />
            </div>
        {/each}
    </div>
</div>

<style>
    #levity {
        margin-left:-1em;
        border-left: 2em solid rgb(97, 139, 19);
        border-radius:2em;
    }
</style>