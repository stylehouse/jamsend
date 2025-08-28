<script lang=ts>
    import { onMount } from 'svelte';
    import type { Peering } from '../Peerily.svelte';
    import Things from '../ui/Things.svelte'
    import { DirectoryShare, DirectoryShares } from './Directory.svelte';
    import type { Sharing } from './Sharing.svelte';
    // the fairly-global Peering and PeerilyFeature object
    let { eer,F }:{ eer:Peering,F:Sharing } = $props();

    onMount(() => F.start())
</script>

<h2>Expect big shares</h2>


    {#each F.shares._shares as [k,DS] (k)}
        <div class=bitsies>
            DS:{DS.name}
        </div>
    {/each}
    
    <!-- <Things 
            shelfware={DirectoryShares}
            type="share" 
            pfId={"eer:"+PF.eer.pub}
            defaultItems={["music"]}
            title="File Shares"
        /> -->