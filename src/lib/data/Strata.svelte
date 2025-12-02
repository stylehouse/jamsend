<script lang="ts">
    import { _C, keyser, Modus, Modusmem, TheC, type TheUniversal } from "$lib/data/Stuff.svelte";
    import Stuffing from "$lib/data/Stuffing.svelte";
    import type { Selection } from "$lib/mostly/Selection.svelte";
    import type { Strata } from "$lib/mostly/Structure.svelte";

    let {M,strata,mem,C}:{
        M?:Modus,
        strata:Strata,
        mem:Modusmem,
        C?:TheC,
    } = $props()
    
    let Se:Selection = strata.Se
    // the interesting stuff to see
    let inners = $derived(
        Se.c.T.sc.N.map(T => T.sc.D)
    )
    
</script>
{#if C}
    <!-- <button > -->
        <span onclick={() => nameclick(C)}  >{C.sc.name}</span>
    <!-- </button> -->
    <squidge>
        <Stuffing {mem} stuff={C} matchy={strata} />
    </squidge>
{:else}
    <div>
        {#each inners as D (Se.D_to_uri(D))}
            <svelte:self {M} {strata} {mem} C={D}  />
        {/each}
    </div>
{/if}
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
