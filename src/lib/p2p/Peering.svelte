<script lang="ts">
    import type { Peering } from "./Peerily.svelte";
    import Pier from "./Pier.svelte";


    let {pub,eer}:{eer:Peering} = $props()
    async function showstash() {
        console.log("eer",eer.stashed)
    }
    // $inspect('Peering shing',eer.stashed)
</script>

    <div id=levity>
        <!-- itself: -->
            <div>Listening: <span class="title">{pub} </span>
                {#if eer.disconnected}
                    <span class="ohno tech">discon</span>
                {/if}
                <button onclick={showstash}>stash</button>
                <!-- <button onclick={tweakstash}>~~</button> -->
                <!-- <button onclick={dropstashedPiers}>--</button> -->
            </div>

        <!-- others: -->
            <div class="bitsies">
                {#each eer.Piers as [pub,pier] (pub)}
                    <div class=bitsies>
                        <Pier {pier} />
                    </div>
                {/each}
            </div>

        <!-- F features on Peering  -->
        {#if eer.P.Welcome}
            <div class=bitsies>
                {#each eer.features as [k,F] (k)}
                    <div class=bitsies>
                        <svelte:component this={F.UI_component} {eer} {F} />
                    </div>
                {/each}
            </div>
        {/if}
    </div>
<style>
    #levity {
        margin-left:-1em;
        border-left: 2em solid saddlebrown;
        border-radius:2em;
    }
    .title {
        font-size: 1.6em;
    }
</style>