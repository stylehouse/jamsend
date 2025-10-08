<script lang="ts">
    import { Stuffusion } from './Stuff.svelte';
    import Stuffziad from './Stuffziad.svelte'
    let { stuffusion }:{ stuffusion: Stuffusion } = $props()

    // Track openness in the UI component to preserve across re-brackology()
    let openness = $state(false)

    function toggle() {
        openness = !openness
    }
</script>

<style>
.stuffusion {
    margin: 0.3em;
    border-radius: 3em;
    border: 1px dotted rgb(38, 110, 217);
    background-color: rgba(10, 56, 66, 0.6);
    display: inline-block;
    padding: 0.4em;
}

.stuffusion-btn {
    background: none;
    border: none;
    cursor: pointer;
    padding: 0;
    display: inline-flex;
    align-items: center;
    gap: 0.2em;
}

.stuffusion-arrow {
    color: rgb(228, 163, 245);
}

.stuffusion-name {
    color: rgb(208, 245, 61);
    filter: hue-rotate(30deg);
    font-size: 110%;
}

.stuffusion-count {
    color: rgb(156, 140, 217);
    font-size: 95%;
}

.stuffusion-content {
    margin-top: 0.3em;
    display: flex;
    flex-wrap: wrap;
    gap: 0.2em;
}
</style>

<div class="stuffusion">
    <button class="stuffusion-btn" onclick={toggle}>
        <span class="stuffusion-arrow">
            {openness ? '▼' : '▶'}
        </span>
        <span class="stuffusion-name">{stuffusion.name}</span>
        {#if stuffusion.rowcount !== 1}
            <span class="stuffusion-count">x{stuffusion.rowcount}</span>
        {/if}
    </button>

    {#if openness}
        <div class="stuffusion-content">
            {#each Array.from(stuffusion.columns.values()) as stuffziad (stuffziad.name)}
                <Stuffziad {stuffziad} />
            {/each}
        </div>
    {/if}
</div>