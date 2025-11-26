<script lang="ts">
    import { _C, keyser, Modusmem, TheC, type TheUniversal } from "$lib/data/Stuff.svelte";
    import Stuffing from "$lib/data/Stuffing.svelte";

    let {mem,C,match,see}:{
        mem:Modusmem,
        C:TheC,
        match:TheUniversal,
        see:Array<TheUniversal>,
    } = $props()
    let inners = C.o(match)
    if (C.sc.nib) {
        // hack to go %nib/%Tree**
        match = {Tree:1}
    }
    // copy what to see, the %%other,stuff at each node
    let D = _C({Filings:1})
    for (let sc of see) {
        C.o(sc).map((n:TheC) => D.i(n.sc))
    }
    // and display that
</script>
    Filings: {keyser(C)}
    <Stuffing {mem} stuff={D} />

<div>
    {#each inners as oC}
        <svelte:self {mem} C={oC} {match} {see} />
    {/each}
</div>

<style>
    div {
        margin-left:2em;
    }
</style>
