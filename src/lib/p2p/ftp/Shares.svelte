<script lang=ts>
    import { onMount } from 'svelte';
    import type { Peering } from '../Peerily.svelte';
    import Things from '../ui/Things.svelte'
    import type { PeeringSharing } from './Sharing.svelte';
    import { DirectoryShare, FileListing } from './Directory.svelte';
    import FileList from './FileList.svelte';
    import Sharability from './Sharability.svelte';
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
    
    <Things
            Ss={F.shares}
            type="share" 
        >
            {#snippet thing(S:DirectoryShare)}
                <Sharability {S}></Sharability>
                
            {/snippet}
    </Things>