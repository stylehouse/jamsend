<script lang="ts">
    import { _C, keyser, Modus, Modusmem, TheC, type TheUniversal } from "$lib/data/Stuff.svelte";
    import Stuffing from "$lib/data/Stuffing.svelte";
    import type { Selection, TheD, Travel } from "$lib/mostly/Selection.svelte";
    import type { Strata } from "$lib/mostly/Structure.svelte";

    let {M,strata,mem,T}:{
        M?:Modus,
        strata:Strata,
        mem:Modusmem,
        T?:Travel,
    } = $props()
    
    let Se:Selection = strata.Se
    let nameclick = strata.nameclick_fn || (() => {})
    let D:TheD = T.sc.D
    let indent = T.c.path.length-1
</script>


    <div style="margin-left: {indent}em">
        <!-- <button > -->
            <span onclick={() => nameclick(D)}  >{D.sc.name}</span>
            <span>@{T.sc.thetime}</span>
        <!-- </button> -->
        <squidge>
            {#key strata.thetime}
                <Stuffing {mem} stuff={D} matchy={strata} />
            {/key}
        </squidge>
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