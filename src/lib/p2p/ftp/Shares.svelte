<script lang=ts>
    import { onMount } from 'svelte';
    import type { Peering } from '../Peerily.svelte';
    import Things from '../ui/Things.svelte'
    import type { PeeringSharing } from './Sharing.svelte';
    import { DirectoryShare, FileListing } from './Directory.svelte';
    import FileList from './FileList.svelte';
    import Modus from '../ui/Modus.svelte';
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
    function click_push(file: FileListing) {
        console.log(`Would send ${file.name}`)
    }
</script>

<h2>Expect big shares</h2>

    DSs:{F.shares.things.size}
    
    <Things
            Ss={F.shares}
            type="share" 
        >
            {#snippet thing(S:DirectoryShare)}
                {#if S.modus}
                    <Modus M={S.modus}></Modus>
                {/if}
                
                <FileList 
                        title="Local Files" 
                        list={S.localList} 
                        onFileClick={click_push}
                        onRefreshClick={() => S.refresh()}
                    >
                </FileList>
            {/snippet}
    </Things>