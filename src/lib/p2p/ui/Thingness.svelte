<script lang="ts">
    import type { ThingAction } from "$lib/data/IDBThings.svelte";
    import ActionButtons from "./ActionButtons.svelte";

    // Common behavior for any ThingIsms object
    interface ThingnessProps {
        S: any // The ThingIsms instance (DirectoryShare, etc)
        name?: string
        type: string
        showStatus?: boolean
        showActions?: boolean
        actions?: ThingAction[]
    }

    let { 
        S,
        name,
        type,
        showStatus = true,
        showActions = true,
        actions:generique_actions
    }: ThingnessProps = $props()
    name ??= `${type}s`


    // also, isn't it called intuition because you know something because you see something, because standard?
    let is_playable = $derived(S.started != null)
    let maybe_playable = () => {
        // null doesn't == false, so this detects presence of it having a "started" ness
        if (S.started == false) {
            return {label:'start',icon:'▶',class:"start",handler: async () => {
                await S.start()
            }}
        }
        else if (S.started == true) {
            return {label:'stop',icon:'■',class:"stop",handler: async () => {
                await S.stop()
            }}
        }
    }
    let actions = $derived([
        ...(S.actions||[]),
        ...[is_playable && maybe_playable()].filter(v=>v),
        ...(generique_actions||[]),
    ])

</script>


<div class="thingness" class:started={S.started} class:needs-attention={S.no_autostart}>

    <div class="thing-content">
        <div class="thing-name-row">
            <span class="thing-name">{name}</span>
        </div>
        
        <div class="thing-meta">
            <!-- <span class="thing-type">{type}</span> -->
        </div>
    </div>

    
    {#if showStatus}
        <div class="status-section">
            {#if is_playable}
                {#if S.started}
                    <span class="status-badge started" title="Running">●</span>
                {:else}
                    <span class="status-badge stopped" title="Stopped">○</span>
                {/if}
            {/if}

            
            <span class="status-text">
                {S.started ? '' : S.no_autostart ? 'setup needed' : 'stopped'}
            </span>
        </div>
    {/if}

    <div class="custom-actions">
        <ActionButtons {actions} />
    </div>
</div>



<style>
    .thingness {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        transition: all 0.2s ease;
    }

    .thingness div {
        display: flex;
        align-items: center;
        gap: 0.3rem;
    }
    .thing-name {
        font-weight: 500;
        color: #333;
        font-size: 0.95rem;
    }

    .status-badge {
        font-size: 0.8rem;
        font-weight: bold;
    }

    .status-badge.started {
        color: #4CAF50;
    }

    .status-badge.stopped {
        color: #666;
    }

    .status-badge.attention {
        color: #FF9800;
        animation: pulse 2s infinite;
    }

    @keyframes pulse {
        0%, 100% { opacity: 1; }
        50% { opacity: 0.5; }
    }

    .status-text {
        font-size: 0.75rem;
        color: #888;
        font-style: italic;
        min-width: 80px;
    }
</style>