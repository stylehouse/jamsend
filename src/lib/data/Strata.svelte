<script lang="ts">
    import { _C, keyser, Modus, Modusmem, TheC, type TheUniversal } from "$lib/data/Stuff.svelte";
    import Stuffing from "$lib/data/Stuffing.svelte";
    import type { Selection, TheD, Travel } from "$lib/mostly/Selection.svelte";
    import type { Strata } from "$lib/mostly/Structure.svelte";
    import Stratum from "./Stratum.svelte";

    let {M,strata,mem}:{
        M?:Modus,
        strata:Strata,
        mem:Modusmem,
    } = $props()
</script>

<div>
    {#each strata.by_order as namedT (namedT.name)}
        <Stratum {M} {strata} {mem} {namedT} />
    {/each}
</div>

<style>
    div {
        margin-left:2em;
    }
</style>
