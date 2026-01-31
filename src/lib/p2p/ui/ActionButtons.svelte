<script lang="ts">
    import type { ThingAction } from "$lib/data/Things.svelte";

    // Common behavior for any ThingIsms object
    interface ThingnessProps {
        actions?: ThingAction[]
    }

    let {
        actions
    }: ThingnessProps = $props()

    function handleAction(action: any) {
        try {
            action.handler()
        } catch (err) {
            console.warn(`Action "${action.label}" failed:`, err)
        }
    }
</script>

    {#each actions as action}
        <button 
            onclick={() => handleAction(action)}
            class="button button-{action.class}"
            title={action.label}
        >
            {action.icon || action.label}
        </button>
    {/each}

<style>
.button {
    padding: 0.3rem 0.6rem;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    line-height:0.8;
    font-size: 0.8rem;
    transition: all 0.2s ease;
    background: #2196F3;
    color: white;
}

.button:hover {
    background: #1976D2;
}

/* Start button */
.button-start {
    background: #4CAF50;
    color: white;
}

.button-start:hover {
    background: #45a049;
}

/* Stop button */
.button-stop {
    background: #f44336;
    color: white;
}

.button-stop:hover {
    background: #d32f2f;
}

.button-big {
    padding: 0.4rem 0.8rem !important;
    font-weight: 600;
    font-size: 0.85em;
    background: #FF5722 !important;
}

.button-big:hover {
    background: #E64A19 !important;
    transform: scale(1.05);
}

/* Remove/delete button */
.button-remove {
    background: #f44336;
    color: white;
    font-weight: bold;
    width: 24px;
    height: 24px;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 0;
}

.button-remove:hover {
    background: #d32f2f;
    transform: scale(1.1);
}
</style>