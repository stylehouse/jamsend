<script lang="ts">
    import type { ThingAction } from "$lib/data/Things.svelte";

    // Common behavior for any ThingIsms object
    interface ThingnessProps {
        actions?: ThingAction[]
    }

    let { 
        S, 
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
            class="but but-{action.class}"
            title={action.label}
        >
            {action.icon || action.label}
        </button>
    {/each}

<style>
.but {
    padding: 0.3rem 0.6rem;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    font-size: 0.8rem;
    transition: all 0.2s ease;
    background: #2196F3;
    color: white;
}

.but:hover {
    background: #1976D2;
}

/* Start button */
.but-start {
    background: #4CAF50;
    color: white;
}

.but-start:hover {
    background: #45a049;
}

/* Stop button */
.but-stop {
    background: #f44336;
    color: white;
}

.but-stop:hover {
    background: #d32f2f;
}

/* Big prominent button */
.but-big {
    padding: 0.4rem 0.8rem !important;
    font-weight: 600;
    font-size: 0.85rem !important;
    background: #FF5722 !important;
}

.but-big:hover {
    background: #E64A19 !important;
    transform: scale(1.05);
}

/* Remove/delete button */
.but-remove {
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

.but-remove:hover {
    background: #d32f2f;
    transform: scale(1.1);
}
</style>