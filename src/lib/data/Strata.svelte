<script lang="ts">
    import { _C, keyser, Modusmem, TheC, type TheUniversal } from "$lib/data/Stuff.svelte";
    import Stuffing from "$lib/data/Stuffing.svelte";

    let {mem,C,match,see,hide,nameclick}:{
        mem:Modusmem,
        C:TheC,
        match:TheUniversal,
        see:Array<TheUniversal>,
        hide:Array<TheUniversal>,
        nameclick:Function,
    } = $props()

    // the interesting stuff to see
    let inners = C.o(match)
    
</script>
    <!-- <button > -->
        <span onclick={() => nameclick(C)}  >{C.sc.name}</span>
    <!-- </button> -->
    <squidge>
        <Stuffing {mem} stuff={C} {see} {hide} />
    </squidge>

<div>
    {#each inners as oC (oC.sc.name)}
        <svelte:self {mem} C={oC} {match} {see} {hide} {nameclick} />
    {/each}
</div>

<style>
    button {
        display: inline-block;
        background: none;
        border: none;
        cursor: pointer;
        padding: 0;
        align-items: center;
        gap: 0.25em;
        color: rgb(156, 140, 217);
        font-size: 100%;
        line-height: 1em;
    }
    div {
        margin-left:2em;
    }
    span {
        font-family: monospace;
        width: 12em;
        display:inline-block;
        padding-left: 2em;
        text-indent: -2em; 
        padding: 0;
        align-items: left;
        gap: 0.25em;
    }
    squidge {
        display:inline-block;
        margin-top:-0.4em;
        margin-bottom:-0.4em;
    }
</style>
