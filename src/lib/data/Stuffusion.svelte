<script lang="ts">
    import { Modusmem, Stuffusion } from './Stuff.svelte';
    import Stuffziad from './Stuffziad.svelte'
    import Stuffzipper from './Stuffzipper.svelte';
    
    let { mem,stuffusion }:{ mem:Modusmem,stuffusion: Stuffusion } = $props()
    mem = mem.further("Stuffusion:"+stuffusion.name)

    // Track openness in the UI component to preserve across re-brackology()
    let openness = $state(true)
    function toggle() {
        openness = !openness
    }
</script>

<div class="stuffusion">

    {#if openness}
        <span class="content">
            {#each Array.from(stuffusion.columns.values()) as stuffziad (stuffziad.name)}
                <Stuffziad {mem} {stuffziad} />
            {/each}
        </span>
    {/if}
    {#if stuffusion.rows.length !== 1}
        <span class="content count">x{stuffusion.row_count}</span>
    {/if}
    {#if stuffusion.innered}
        <Stuffzipper {mem} innered={stuffusion.innered} {stuffusion} ></Stuffzipper>
    {/if}
</div>

<style>
.stuffusion {
    margin: 0.1em;
    border-radius: 3em;
    border: 2px solid rgb(65, 38, 217);
    background-color: rgba(25, 10, 66, 0.6);
    display: inline-block;
    padding: 0.1em;
    &.count {
        color: rgb(156, 140, 217);
        font-size: 95%;
    }
    &.content {
        display: flex;
        flex-wrap: wrap;
        gap: 0.2em;
    }
}


</style>