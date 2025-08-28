<script lang=ts>
    import { onMount } from 'svelte';
    import type { Peering } from '../Peerily.svelte';
    import Things from '../ui/Things.svelte'
    import { DirectoryShare, DirectoryShares } from './Directory.svelte';
    import type { Sharing } from './Sharing.svelte';
    // the fairly-global Peering and PeerilyFeature object
    let { eer,F }:{ eer:Peering,F:Sharing } = $props();

    onMount(async () => {
        // < Things might F.shares.start()
        //   Thing then DirectoryShare.start()?
        setTimeout(async () => {
            //  await F.start()
             }, 2100)
        console.log("shares!: ",[F,F.shares._shares])
    })
</script>

<h2>Expect big shares</h2>

    DSs:{F.shares._shares.size}
    {#each F.shares._shares as [k,DS] (k)}
        <div class=bitsies>
            DS:{DS.name} <button onclick={() => DS.start()}>o</button>
        </div>
    {/each}
    
    <!-- <Things 
            shelfware={DirectoryShares}
            type="share" 
            pfId={"eer:"+PF.eer.pub}
            defaultItems={["music"]}
            title="File Shares"
        /> -->