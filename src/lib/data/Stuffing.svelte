<script lang="ts">
    import { Stuff,Stuffing } from './Stuff.svelte';
    import Stuffusion from './Stuffusion.svelte'

    let { stuff }: { stuff: Stuff } = $props()

    // Create Stuffing in an effect
    let stuffing: Stuffing | null = $state(null)

    $effect(() => {
        stuffing = new Stuffing(stuff)
    })
</script>

<style>
.stuffing {
    margin: 0.1em;
    border-radius: 4em;
    border: 1px dotted rgb(38, 110, 217);
    background-color: rgb(5, 46, 46);
    display: inline-block;
    /* filter: hue-rotate(-50deg); */
    padding: 0.1em;
}
</style>

{#if stuffing}
    <div class="stuffing">
        <div class="content">
            {#each Array.from(stuffing.groups.values()) as stuffusion:Stuffusion (stuffusion.name)}
                <Stuffusion {stuffusion} />
            {/each}
        </div>
    </div>
{/if}