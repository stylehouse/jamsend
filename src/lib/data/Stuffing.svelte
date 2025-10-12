<script lang="ts">
    import { Stuff,Stuffing } from './Stuff.svelte';
    import Stuffusion from './Stuffusion.svelte'

    let { stuff }: { stuff: Stuff } = $props()

    // Create Stuffing in an effect
    let stuffing: Stuffing | null = $state(null)

    $effect(() => {
        stuffing = new Stuffing(stuff)
    })

    // Track openness in the UI component to preserve across re-brackology()
    let openness = $state(true)

    function toggle() {
        openness = !openness
    }
</script>

<style>
.stuffing {
    margin: 0.3em;
    border-radius: 4em;
    border: 1px dotted rgb(38, 110, 217);
    background-color: rgb(5, 46, 46);
    display: inline-block;
    filter: hue-rotate(-50deg);
    padding: 0.5em;
}

.stuffing-btn {
    background: none;
    border: none;
    cursor: pointer;
    color: rgb(208, 245, 61);
    font-size: 117%;
    filter: hue-rotate(30deg);
}

.stuffing-arrow {
    color: rgb(228, 163, 245);
}

.stuffing-count {
    color: rgb(156, 140, 217);
    margin-left: 0.3em;
}

.stuffing-content {
    margin-top: 0.3em;
}
</style>

{#if stuffing}
    <div class="stuffing">
        <button class="stuffing-btn" onclick={toggle}>
            <span class="stuffing-arrow">
                {openness ? '▼' : '▶'}
            </span>
            Stuffing
            {#if stuffing.groups.size !== 1}
                <span class="stuffing-count">x{stuffing.groups.size}</span>
            {/if}
        </button>

        {#if openness}
            <div class="stuffing-content">
                {#each Array.from(stuffing.groups.values()) as stuffusion (stuffusion.name)}
                    <Stuffusion {stuffusion} />
                {/each}
            </div>
        {/if}
    </div>
{/if}