<script lang="ts">
    import { Modusmem, Stuffusion } from './Stuff.svelte';
    import Stuffziad from './Stuffziad.svelte'
    import Stuffzipper from './Stuffzipper.svelte';
    
    let { mem,stuffusion }:{ mem:Modusmem,stuffusion: Stuffusion } = $props()
    mem = mem.further("Stuffusion:"+stuffusion.name)

    // < GOING nothing toggles here?
    // Track openness in the UI component to preserve across re-brackology()
    // thaw|freeze our openness to persistent memory
    let openness = $state(mem.get('openness') || true);
    function toggle() {
        openness = !openness;
        mem.set('openness',openness)
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
        <span title="Stuffusion row count" class="content count">x{stuffusion.row_count}</span>
    {/if}
    {#if openness}
        {#if stuffusion.innered}
            <Stuffzipper {mem} innered={stuffusion.innered}
                {stuffusion} ></Stuffzipper>
        {/if}
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