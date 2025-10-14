<script lang="ts">
    import type { Peering } from "./Peerily.svelte";
    import Pier from "./Pier.svelte";


    let {pub,eer}:{eer:Peering} = $props()
    async function showstash() {
        console.log("eer",eer.stashed)
    }
    async function tweakstash() {
        eer.stashed.leg ||= 2
        eer.stashed.leg = eer.stashed.leg + 1
        eer.stashed.thinke = 3
        console.log(`Peering thinked`, eer.stashed)
    }
    async function dropstashedPiers() {
        delete eer.stashed.Piers
    }
    $effect(() => {
        if (Object.entries(eer.stashed)) {
            console.log(`Peering stashed save...`)
            eer.P.save_stash()
        }
    })
    $inspect('Peering shing',eer.stashed)
</script>

    <div id=levity>
        <!-- itself: -->
            <div>Listening: {pub} 
                {#if eer.disconnected}
                    <span class="ohno tech">discon</span>
                {/if}
                <button onclick={showstash}>stash</button>
                <!-- <button onclick={tweakstash}>~~</button> -->
                <button onclick={dropstashedPiers}>--</button>
            </div>

        <!-- others: -->
            <div class="bitsies">
                {#each eer.Piers as [pub,pier] (pub)}
                    <div class=bitsies>
                        <Pier {pier} />
                    </div>
                {/each}
            </div>

        <!-- apps on the  -->
            <div class=bitsies>
                {#each eer.features as [k,F] (k)}
                    <div class=bitsies>
                        <svelte:component this={F.UI_component} {eer} {F} />
                    </div>
                {/each}
            </div>
    </div>
<style>
    #levity {
        margin-left:-1em;
        border-left: 2em solid saddlebrown;
        border-radius:2em;
    }
</style>