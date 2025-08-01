<script lang="ts">
    import type { Pier } from "../Peerily.svelte";

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
        if (pier.stashed) {
            console.log(`Pier stashed save...`)
            pier.P.save_stash()
        }
    })
    $inspect('Pier shing',pier.stashed)
</script>
Pier: {pier.pub} 
{#if pier.disconnected}
    <span class="ohno tech">discon</span>
{/if}
    <button onclick={showstash}>stash</button>
    <button onclick={tweakstash}>~~</button>
