<script lang="ts">
    import { _C, keyser, Modusmem, TheC, type TheUniversal } from "$lib/data/Stuff.svelte";
    import Stuffing from "$lib/data/Stuffing.svelte";

    let {mem,C,match,see}:{
        mem:Modusmem,
        C:TheC,
        match:TheUniversal,
        see:Array<TheUniversal>,
    } = $props()

    // the interesting stuff to see
    let inners = C.o(match)
    
</script>
    <span>{C.sc.name}</span>
    <Stuffing {mem} stuff={C} matches={see} />

<div>
    {#each inners as oC (oC.sc.name)}
        <svelte:self {mem} C={oC} {match} {see} />
    {/each}
</div>

<style>
    div {
        margin-left:2em;
    }
    span {
        font-family: monospace;
        width: 12em;
        display:inline-block;
        padding-left: 2em;
        text-indent: -2em; 
    }
</style>
