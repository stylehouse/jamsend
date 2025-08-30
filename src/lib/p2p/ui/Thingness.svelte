<script lang="ts">
    import type { ThingAction } from "$lib/data/IDBThings.svelte";

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
        actions
    }: ThingnessProps = $props()


    let Actions = $derived([...(S.actions||[]),...(actions||[])])

    function handleAction(action: any) {
        try {
            action.handler()
        } catch (err) {
            console.warn(`Action "${action.label}" failed:`, err)
        }
    }

    async function handleStart() {
        if (S.start) {
            try {
                await S.start()
            } catch (err) {
                console.warn(`Failed to start ${type}:`, err)
            }
        }
    }

    async function handleStop() {
        if (S.stop) {
            try {
                await S.stop()
            } catch (err) {
                console.warn(`Failed to stop ${type}:`, err)
            }
        }
    }
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

    <!-- Custom actions from ThingIsms -->
    {#if showActions && Actions.length}
        <div class="custom-actions">
            {#each Actions as action}
                <button 
                    onclick={() => handleAction(action)}
                    class="action-button action-button-{action.class}"
                    title={action.label}
                >
                    {action.icon || action.label}
                </button>
            {/each}
        </div>
    {/if}

    <!-- Standard start/stop controls -->
    {#if showActions}
        <div class="standard-actions">
            {#if !S.started}
                <button 
                    onclick={handleStart}
                    class="control-button start-button"
                    title="Start {type}"
                >
                    ▶
                </button>
            {/if}
            
            {#if S.started}
                <button 
                    onclick={handleStop}
                    class="control-button stop-button"
                    title="Stop {type}"
                >
                    ■
                </button>
            {/if}
        </div>
    {/if}

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

    .action-button, .control-button {
        padding: 0.3rem 0.6rem;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        font-size: 0.8rem;
        transition: all 0.2s ease;
    }

    .action-button {
        background: #2196F3;
        color: white;
    }

    .action-button:hover {
        background: #1976D2;
    }


    .action-button-remove {
        background: #f44336;
        color: white;
        font-weight: bold;
        width: 24px;
        height: 24px;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 0;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        transition: all 0.2s ease;
    }

    .remove-button-remove:hover {
        background: #d32f2f;
        transform: scale(1.1);
    }


    .action-button-big {
        padding: 0.4rem 0.8rem !important;
        font-weight: 600;
        font-size: 0.85rem !important;
        background: #FF5722 !important;
    }

    .action-button-big:hover {
        background: #E64A19 !important;
        transform: scale(1.05);
    }

    .control-button {
        padding: 0.3rem 0.5rem;
        font-size: 0.7rem;
    }

    .start-button {
        background: #4CAF50;
        color: white;
    }

    .start-button:hover {
        background: #45a049;
    }

    .stop-button {
        background: #f44336;
        color: white;
    }

    .stop-button:hover {
        background: #d32f2f;
    }
</style>