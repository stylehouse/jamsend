<script lang="ts">
    import type { Modus, Modusmem } from "$lib/mostly/Modus.svelte.ts";
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
