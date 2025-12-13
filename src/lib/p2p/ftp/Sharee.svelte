<script lang="ts">
    import { PierSharing } from '$lib/p2p/ftp/Sharing.svelte';
    import Modus from '$lib/mostly/Modus.svelte';
    import ActionButtons from '../ui/ActionButtons.svelte';
    import type { FileListing } from './Directory.svelte';
    
    // the global Peerily and PeeringFeature object
    let { pier,PF } = $props();
    let sharing:PierSharing = PF;

    // Convert transfer objects to FileListing-like objects
    let transfers = $derived(
        Array.from(sharing.tm?.transfers.values() ?? []).map(t => ({
            name: t.filename,
            size: t.size,
            modified: t.created_ts,
            progress: t.progress,
            status: t.status
        }))
    );

    // < higher level things to click on, eg tags
    // < modes of picking at huger collections:
    //    nab - all
    //    rummage - randomly
    //     should offer to heal the gaps left in the result
    function click_push(file: FileListing) {
        sharing.sendFile(file.name);
    }
    function click_pull(file: FileListing) {
        sharing.pull(file.name)
    }
</script>

I am a Sharee



<Modus S={PF} do_start=1></Modus>


<div class="file-sharing">
    <div class="lists-container">
        {#if transfers.length > 0}
            <div class="transfers">
                <h3>Active Transfers</h3>
                {#each transfers as transfer}
                    <div class="transfer">
                        <span class="name">{transfer.name}</span>
                        <div class="progress-bar">
                            <div 
                                class="progress" 
                                style="width: {transfer.progress}%"
                            ></div>
                        </div>
                        <span class="status">{transfer.status}</span>
                        {#if transfers.errorMessage}
                            <span class="status">{transfer.errorMessage}</span>
                        {/if}
                    </div>
                {/each}
            </div>
        {/if}
    </div>
</div>

<style>
    .file-sharing {
        width: 100%;
    }

    .lists-container {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 1rem;
        margin-top: 1rem;
    }

    .transfers {
        grid-column: 1 / -1;
        border: 1px solid #444;
        border-radius: 4px;
        padding: 0.5rem;
        background: rgba(0, 0, 0, 0.2);
    }

    .transfer {
        display: flex;
        align-items: center;
        gap: 1rem;
        padding: 0.5rem;
    }

    .progress-bar {
        flex: 1;
        height: 4px;
        background: #444;
        border-radius: 2px;
        overflow: hidden;
    }

    .progress {
        height: 100%;
        background: #4CAF50;
        transition: width 0.3s ease;
    }

    .status {
        font-size: 0.9em;
        color: #888;
    }

    h3 {
        margin: 0 0 0.5rem 0;
        font-size: 1rem;
        color: #aaa;
    }
</style>