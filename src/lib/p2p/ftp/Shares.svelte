<script lang=ts>
    import { onMount } from 'svelte';
    import type { Peering } from '../Peerily.svelte';
    import Things from '../../data/Things.svelte'
    import type { PeeringSharing } from './Sharing.svelte';
    import { DirectoryModus, DirectoryShare } from './Directory.svelte';
    import { SharesModus } from '$lib/mostly/Radio.svelte';
    import Thingstashed from '$lib/data/Thingstashed.svelte';
    import Modus from '$lib/mostly/Modus.svelte';
    import ActionButtons from '../ui/ActionButtons.svelte';
    // the fairly-global Peering and PeeringFeature object
    let { eer,F }:{ eer:Peering,F:PeeringSharing } = $props();
    let actions = $derived(F.actions)

    onMount(async () => {
        // < Things might F.shares.start()
        //   Thing then DirectoryShare.start()?
        setTimeout(async () => {
            //  await F.start()
             }, 2100)
        console.log("shares!: ",[F,F.shares.things])
    })



    let compat_mode = $state()
    $effect(() => { compat_mode = !('showDirectoryPicker' in window) })
</script>

<h2>The plot here.</h2>

{#each F.gizmos as [name, M] (name)}
    <Thingstashed {F} {name} {M} />
{/each}

<div class="custom-actions">
    <ActionButtons {actions} />
</div>
<Modus S={F} do_start=1></Modus>

<h2>Expect big shares</h2>
    <Things
            Ss={F.shares}
            type="share" 
        >
            {#snippet thing(S:DirectoryShare)}
                {#if compat_mode}
                    <h3>BROWSER IS TOO OLD</h3>
                    <p>You don't seem to allow Directory writing access. Sorry.</p>
                    <p>Try with Chrome.</p>
                {/if}


                <Modus {S} ></Modus>
                
            {/snippet}
    </Things>