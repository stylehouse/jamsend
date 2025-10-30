<script lang=ts>
    import { onMount } from 'svelte';
    import type { Peering } from '../Peerily.svelte';
    import Things from '../../data/Things.svelte'
    import type { PeeringSharing } from './Sharing.svelte';
    import { DirectoryShare, FileListing } from './Directory.svelte';
    import FileList from './FileList.svelte';
    import Sharability from './Sharability.svelte';
    // the fairly-global Peering and PeeringFeature object
    let { eer,F }:{ eer:Peering,F:PeeringSharing } = $props();

    onMount(async () => {
        // < Things might F.shares.start()
        //   Thing then DirectoryShare.start()?
        setTimeout(async () => {
            //  await F.start()
             }, 2100)
        console.log("shares!: ",[F,F.shares.things])
    })



    // always have this in there...
    let compat_mode = $state()
    $effect(() => {
        if (!('showDirectoryPicker' in window)) {
            compat_mode = true
        }
    })
</script>

<h2>Expect big shares</h2>
    
    <Things
            Ss={F.shares}
            type="share" 
        >
            {#snippet thing(S:DirectoryShare)}
                {#if compat_mode}
                    <h3>BROWSER IS TOO OLD</h3>
                    <p>You don't seem to allow Directory writing access. Sorry.</p>
                {/if}
                
                <Sharability {S}></Sharability>
                
            {/snippet}
    </Things>