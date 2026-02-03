<script lang="ts">
    import type { Pier } from "./Peerily.svelte";
    import TrustEnabler from "./ui/TrustEnabler.svelte";

    // < rename -> ier
    let {pier}:{pier:Pier} = $props()
    async function showstash() {
        console.log("pier",pier.stashed)
    }
    // $inspect('Pier shing',pier.stashed)
</script>
 
<div id=levity class:stealth={pier.P.stealth && pier.stashed?.stealth}>
    Pier: <span class="title">{pier.pub} </span>
    {#if pier.disconnected}
        <span class="ohno tech">discon</span>
    {/if}
    {#if pier.stashed.stealth}
        <span class="tech">stealth</span>
    {/if}
    {#if pier.latency}
        <span class="tech latency" style="{pier.latency < 3 ? '' : 
            'font-size:'+ Math.min(4, pier.latency * 0.22 + 1) +'em'
        }">{pier.latency}</span>
    {/if}
    <!-- <button onclick={showstash}>stash</button> -->
    <!-- <button onclick={tweakstash}>~~</button> -->

    <TrustEnabler {pier} />

    {#if pier.P.Welcome}
    <div class=bitsies>
        {#each pier.features as [k,PF] (k)}
            <div class=bitsies>
                <svelte:component this={PF.UI_component} {pier} {PF} />
            </div>
        {/each}
    </div>
    {/if}
</div>

<style>
    #levity {
        margin-left:-1em;
        border-left: 2em solid rgb(97, 139, 19);
        border-radius:2em;
    }
    .stealth {display:none}
    .title {
        font-size: 1.6em;
    }
    .latency{margin:0.3em}
</style>