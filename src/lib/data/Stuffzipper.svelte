<script lang="ts">
    import { type TheN,Modusmem,Stuffusion,Stuffziado } from "./Stuff.svelte";
    import Stuffing from "./Stuffing.svelte";

    type eitherzipperuzia = {stuffusion:Stuffusion} | {stuffziado:Stuffziado}
    let { mem,
        innered,
        // our client is either:
        stuffusion,
        stuffziado,
    }: { mem:Modusmem,
        innered: TheN } & eitherzipperuzia = $props();
    
    let either = stuffusion || stuffziado
    mem = mem.further("Stuffzipper:"+either.name)

    let anything = true
    
    // thaw|freeze our openness to persistent memory
    let openness = $state(mem.get('openness') || false);
    function toggle() {
        openness = !openness;
        mem.set('openness',openness)
    }

    // some rows here, have yay many rows in them
    let inner_sizing = (stuffusion||stuffziado).inner_sizing
    // we are the more-rows handle for
    if (stuffusion) {
        // a whole Stuffusion
    }
    if (stuffziado) {
        // a value
        stuffusion = stuffziado.up.up
        if (inner_sizing == stuffusion.inner_sizing) {
            // this value accesses the same rows as the whole stuffusion
            // hide it to avoid clutter
            anything = false
        }
    }
</script>

{#if anything}
<button class="btn" onclick={toggle}>
    <span class="count {openness && 'open'}"> {inner_sizing} </span>
</button>
<span class="inner">
    {#if openness}
        {#each innered as inner}
            <Stuffing {mem} stuff={inner} />
        {/each}
    {/if}
</span>
{/if}

<style>
    .open {
        background: black;
        min-height:2em;
    }
    .count {
        display:block;
    }
    .inner {
        display: block;
        filter:hue-rotate(33deg)
    }
    .btn {
        display: inline-block;
        background: none;
        border: none;
        cursor: pointer;
        padding: 0;
        align-items: center;
        gap: 0.25em;
        color: rgb(156, 140, 217);
        font-size: 95%;
    }
</style>
