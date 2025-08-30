<script lang="ts">
    import type { ThingAction } from "$lib/data/IDBThings.svelte";
    import ActionButtons from "./ActionButtons.svelte";

    // Common behavior for any ThingIsms object
    interface ThingnessProps {
        S: any // The ThingIsms instance (DirectoryShare, etc)
        type: string
        showStatus?: boolean
        showActions?: boolean
        actions?: ThingAction[]
    }

    let { 
        S, 
        type,
        showStatus = true,
        showActions = true,
        actions:generique_actions
    }: ThingnessProps = $props()


    let actions = $derived([...(S.actions||[]),...(generique_actions||[])])
    // also, isn't it called intuition because you know something because you see something, because standard?
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
    let standard_actions = $derived([maybe_playable()])

</script>

<div class="thingness" class:started={S.started} class:needs-attention={S.no_autostart}>
    <!-- Status indicators -->
    {#if showStatus}
        <div class="status-section">
            {#if S.started}
                <span class="status-badge started" title="Running">●</span>
            {:else if S.no_autostart}
                <span class="status-badge attention" title="Needs setup">!</span>
            {:else}
                <span class="status-badge stopped" title="Stopped">○</span>
            {/if}
            
            <span class="status-text">
                {S.started ? '' : S.no_autostart ? 'setup needed' : 'stopped'}
            </span>
        </div>
    {/if}

    <div class="custom-actions">
        <ActionButtons {actions} />
    </div>

    <div class="standard-actions">
        <ActionButtons actions={standard_actions} />
    </div>

    <!-- Slot for additional content -->
    <slot></slot>
</div>



<style>
    .thingness {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        transition: all 0.2s ease;
    }

    .status-section {
        display: flex;
        align-items: center;
        gap: 0.3rem;
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


    .custom-actions, .standard-actions {
        display: flex;
        gap: 0.3rem;
    }
</style>