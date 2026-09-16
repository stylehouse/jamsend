<script lang="ts">
    import type { House, Housemem } from '$lib/O/Housing.svelte.ts';
    import { Stuff, Stuffing } from '$lib/Stuff.svelte';
    import Stuffusion from './Stuffusion.svelte'
    import { getContext, setContext } from 'svelte'

    let { mem, stuff, M, H: H_prop, self_row }: {
        mem: Housemem,
        stuff: Stuff,
        M?: House,
        H?: House,
        // self_row: show the %stuff particle ITSELF as the single row (its k:v), not its
        //  children — the look of a leaf/structural particle rendered as a stuffing (Cyto chunks)
        self_row?: boolean,
    } = $props()
    mem = mem.further("Stuffing")

    // H flows down to nested Stuffings via context — Stuffzipper, Stuffusion etc never see H.
    //  re-seat only when a fresh H_prop arrived from outside this tree.
    const H: House = H_prop ?? getContext('H')
    if (!H) throw `Stuffing needs H — setContext('H', H) above this tree, or pass H prop`
    if (H_prop) setContext('H', H_prop)

    // one Stuffing instance for the lifetime of this component.
    //  groups starts empty; .commit() is the only writer. no brackology at script-level —
    //   H.check_stuffings drives the first one so we land in the same H.clear() flush
    //   as sibling Stuffings mounting in this tick.
    let stuffing = new Stuffing(stuff)
    stuffing.self_row = !!self_row

    let spinner = $state(false)
    // re-register when %stuff prop changes (different C handed in by parent).
    //  the prior registration's cleanup deregisters us automatically.
    $effect(() => {
        const S = stuff
        if (!S) return
        // key the registry by the mem's keys-path — mem.path is undefined (Housemem carries .keys,
        //  not .path). Two mounts may SHARE a keys-path (same-key sibling chunks in Cyto sharing a
        //   stash); register_stuffing individuates colliding keys itself, so both stay refreshed.
        //    reading .keys stays in-bounds (no lib/mostly).
        const deregister = H.register_stuffing(mem.keys.join('/'), S, () => {
            // called inside H.clear() — sibling Stuffings also committing in this flush.
            // < pure compute outside of any reactive scope, then atomic %state write
            stuffing.Stuff = S
            stuffing.commit(stuffing.compute_groups())
            spinner = true
            setTimeout(() => { spinner = false }, 333)
        })
        return deregister
    })

</script>

{#if stuffing.started}
    <div class="stuffing">
        <div class="content">
            {#each Array.from(stuffing.groups.values()) as stuffusion: Stuffusion (stuffusion.name)}
                <Stuffusion {mem} {stuffusion} />
            {/each}
        </div>
        {#if spinner}
            <div class="spinner"></div>
        {/if}
    </div>
{/if}

<style>
.stuffing {
    margin: 0.1em;
    border-radius: 4em;
    border: 1px dotted rgb(38, 110, 217);
    background-color: rgb(5, 46, 46);
    display: inline-block;
    padding: 0.1em;
    position: relative;
}
.content {
    display: inline-block;
    min-height: 1em;
    min-width: 1em;
}

.spinner {
    position: absolute;
    top: 0%;
    left: -1em;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: 0.3em 0.6em;
    color: rgb(38, 110, 217);
    font-size: 1.6em;
    animation: pulse 1s ease-in-out infinite;
    text-shadow: 2px 2px 2px rgb(12, 28, 51);
}
.spinner::before {
    content: "⟳";
    display: inline-block;
    animation: spin 0.3s linear infinite;
}
@keyframes spin {
    to { transform: rotate(360deg); }
}
@keyframes pulse {
    0%, 100% { opacity: 0.6; }
    50% { opacity: 1; }
}
</style>