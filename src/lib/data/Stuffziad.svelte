<script lang="ts">
    import Stuffziad from './Stuffziad.svelte'
    let { stuffziad }:{ stuffziad: Stuffziad } = $props()

    // Track openness in the UI component to preserve across re-brackology()
    let openness = $state(false)

    function toggle() {
        openness = !openness
    }

    // Get all Stuffziado values
    const stuffziados = $derived(Array.from(stuffziad.values.values()))
</script>

<style>
.stuffziad {
    margin: 0.2em;
    border-radius: 2em;
    border: 1px dotted rgb(38, 110, 217);
    background-color: rgba(20, 70, 80, 0.4);
    display: inline-block;
    padding: 0.2em 0.5em;
    filter: hue-rotate(20deg);
}

.stuffziad-btn {
    background: none;
    border: none;
    cursor: pointer;
    padding: 0;
    display: inline-flex;
    align-items: center;
    gap: 0.25em;
}

.stuffziad-name {
    color: rgb(208, 245, 61);
    filter: hue-rotate(10deg);
    font-size: 100%;
}

.stuffziad-colon {
    color: rgb(228, 163, 245);
}

.stuffziad-count {
    color: rgb(156, 140, 217);
    font-size: 85%;
}

.stuffziad-arrow {
    color: rgb(228, 163, 245);
    font-size: 85%;
}

.stuffziad-values {
    margin-top: 0.3em;
    margin-left: 0.5em;
    display: flex;
    flex-wrap: wrap;
    gap: 0.2em;
}

.stuffziado {
    margin: 0.1em;
    padding: 0.1em 0.3em;
    border-radius: 1em;
    background-color: rgba(50, 90, 100, 0.3);
    display: inline-block;
    filter: hue-rotate(-30deg);
}

.stuffziado-count {
    color: rgb(156, 140, 217);
    font-size: 90%;
}

.stuffziado-name {
    color: rgb(208, 245, 61);
    filter: brightness(0.7);
    margin-left: 0.2em;
    font-size: 90%;
}

.stuffziado-inline {
    color: rgb(208, 245, 61);
    filter: brightness(0.7) hue-rotate(-10deg);
    margin-left: 0.2em;
    font-size: 95%;
}
</style>

<div class="stuffziad">
    <button class="stuffziad-btn" onclick={toggle}>
        <span class="stuffziad-name">{stuffziad.name}</span>
        <span class="stuffziad-colon">:</span>
        
        {#if stuffziad.values.size !== 1}
            <span class="stuffziad-count">x{stuffziad.values.size}</span>
        {/if}
        
        {#if stuffziad.values.size > 1}
            <span class="stuffziad-arrow">{openness ? '▼' : '▶'}</span>
        {/if}
    </button>

    {#if openness && stuffziad.values.size > 1}
        <div class="stuffziad-values">
            {#each stuffziados as stuffziado (stuffziado.name)}
                <div class="stuffziado">
                    {#if stuffziado.rowcount !== 1}
                        <span class="stuffziado-count">x{stuffziado.rowcount}</span>
                    {/if}
                    <span class="stuffziado-name">{stuffziado.name}</span>
                </div>
            {/each}
        </div>
    {:else if stuffziad.values.size === 1}
        <!-- Single value (compressed) - show inline -->
        <span class="stuffziado-inline">
            {stuffziados[0]?.name}
        </span>
    {/if}
</div>