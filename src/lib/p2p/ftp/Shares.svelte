<script lang=ts>
    import { onMount } from 'svelte';
    import type { Peering } from '../Peerily.svelte';
    import Things from '../ui/Things.svelte'
    import type { PeeringSharing } from './Sharing.svelte';
    // the fairly-global Peering and PeerilyFeature object
    let { eer,F }:{ eer:Peering,F:PeeringSharing } = $props();

    onMount(async () => {
        // < Things might F.shares.start()
        //   Thing then DirectoryShare.start()?
        setTimeout(async () => {
            //  await F.start()
             }, 2100)
        console.log("shares!: ",[F,F.shares.things])
    })
</script>

<h2>Expect big shares</h2>

    DSs:{F.shares.things.size}
    {#each F.shares.things as [k,DS] (k)}
        <div class=bitsies>
            DS:{DS.name} <button onclick={() => DS.start()}>o</button>
        </div>
    {/each}
    
    <Things
            Ss={F.shares}
            type="share" 
        />