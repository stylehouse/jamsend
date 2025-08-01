<script lang="ts">
    import Pier from "./Pier.svelte";

    let {pub,eer} = $props()
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
        if (eer.stashed) {
            console.log(`Peering stashed save...`)
            eer.P.save_stash()
        }
    })
    $inspect('Peering shing',eer.stashed)
</script>
            <div>Listening: {pub} 
                {#if eer.disconnected}
                    <span class="ohno tech">discon</span>
                {/if}
                <button onclick={showstash}>stash</button>
                <button onclick={tweakstash}>~~</button>
                <button onclick={dropstashedPiers}>--</button>
            </div>
            <div class="bitsies">
                {#each eer.Piers as [pub,pier] (pub)}
                    <div class=bitsies>
                        <Pier {pier} />
                    </div>
                {/each}
            </div>
