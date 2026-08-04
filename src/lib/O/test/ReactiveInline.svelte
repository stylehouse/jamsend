<script lang="ts">
    // ReactiveInline — the UNGATED twin of ReactiveWaft, reduced from a live bug (2026-08-04).
    //
    // ReactiveWaft (its sibling) exists to prove the GOOD shape: it buffers the list into a
    //  $state array assigned inside `H.clear()`, so the callback queues behind the beliefs mutex
    //   and `.o()` never runs mid-replace.  Its header says why in one line — *"so it never
    //    catches waft.o() mid-replace returning []"*.
    //
    // This file is the same list read with the gate taken OFF, in the exact shape the Vyto glass
    //  had it: the walk is called FROM THE TEMPLATE EXPRESSION.  No $state buffer, no clear(), no
    //   settled-state guarantee — whatever the tree returns at that instant is what the keyed
    //    {#each} is handed.  One render that lands mid-replace returns [], the each destroys every
    //     child, and the next render brings the SAME objects back and rebuilds them.
    //
    // Why that is worth a Book of its own: the failure is invisible to every value-comparison
    //  probe.  The key never changes, the objects never change, no field flips — so a "did the key
    //   move / did the gate flip" detector stays silent while the whole subtree is being recreated
    //    on a loop.  Only a LIFECYCLE-true tell (WaftComp's onMount, tagged `imount` here) can see
    //     it, and only next to a gated control that ISN'T remounting can you tell "everything
    //      remounts" from "this one remounts".  That side-by-side is the point of the file.
    //
    // What it cost in the wild: every KeepFace in the glass was torn down and rebuilt on each
    //  Housing tick, which resets component-local $state — so the directories editor "snapped
    //   shut" mid-type and a confirm prompt vanished under the pointer.  The bug read as a focus
    //    or an editing bug for weeks; it was this.
    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"
    import WaftComp       from "./ReactiveWaftComp.svelte"

    let { H }: { H: House } = $props()

    // THE SHAPE UNDER TEST — a live tree-walk evaluated during render.
    function inline_wafts(): TheC[] {
        const lies = H.ave.ob({ Lies: 1 })[0] as TheC | undefined
        return ((lies?.c?.w as TheC | undefined)?.ob({ Waft: 1 }) as TheC[]) ?? []
    }
</script>

{#each inline_wafts() as waft (waft.sc.Waft)}
    <WaftComp {waft} {H} tag="imount" />
{/each}
