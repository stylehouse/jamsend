<script lang="ts">
    import { Modus, Modusmem } from "$lib/data/Stuff.svelte";
    import Stuffing from "$lib/data/Stuffing.svelte";
    import type { NamedT, Selection, TheD, Travel } from "$lib/mostly/Selection.svelte";
    import type { Strata } from "$lib/mostly/Structure.svelte";

    let {M, strata, mem, namedT}: {
        M?: Modus,
        strata: Strata,
        mem: Modusmem,
        namedT: NamedT,
    } = $props()

    // < make this a <button>
    let nameclick = strata.nameclick_fn || (() => {})
    
    // Derive from stable namedT
    let T = $derived(namedT.T)
    let D = $derived(T.sc.D)
    let indent = $derived(T.c.path.length - 1)
    let className = $derived(T.sc.not ? "not" : "")
</script>

<div style="margin-left: {indent}em" class={className}>
    <span onclick={() => nameclick(D)}>{D.sc.name}</span>
    <squidge>
        <Stuffing {mem} stuff={D} matchy={strata} />
    </squidge>
</div>

<style>
    .not {
        opacity:0.5;
    }
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