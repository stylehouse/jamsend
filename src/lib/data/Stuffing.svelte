<script lang="ts">
    import Strata from '$lib/data/Strata.svelte';
    import type { Matchy } from '$lib/mostly/Structure.svelte.ts';
    import type { Modus, Modusmem } from "$lib/mostly/Modus.svelte.ts";
    import { Stuff, Stuffing, type TheUniversal } from './Stuff.svelte.ts';
    import type { House } from '$lib/O/Housing.svelte.ts';
    import Stuffusion from './Stuffusion.svelte'
    import { getContext, setContext } from 'svelte'

    let { mem, stuff, matchy, M, H: H_prop }: {
        mem: Modusmem,
        stuff: Stuff,
        matchy?: Matchy,
        hide?: Array<TheUniversal>,
        M?: Modus,
        H?: House,
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
    let stuffing = new Stuffing(stuff, matchy)

    let spinner = $state(false)
    // re-register when %stuff prop changes (different C handed in by parent).
    //  the prior registration's cleanup deregisters us automatically.
    $effect(() => {
        const S = stuff
        if (!S) return
        // key the registry by the mem's keys-path, distinct per mounted Stuffing — mem.path is
        //  undefined (Modusmem carries .keys, not .path), which collides the moment more than one
        //   Stuffing registers (eg one per Cyto node). reading .keys stays in-bounds (no lib/mostly).
        const deregister = H.register_stuffing(mem.keys.join('/'), S, () => {
            // called inside H.clear() — sibling Stuffings also committing in this flush.
            // < pure compute outside of any reactive scope, then atomic %state write
            stuffing.Stuff = S
            stuffing.matchy = matchy
            stuffing.commit(stuffing.compute_groups())
            spinner = true
            setTimeout(() => { spinner = false }, 333)
            if (M) setTimeout(check_for_strata, 0)
        })
        return deregister
    })

    //#region Strata
    let strata_version = $state(0)
    let stratum = $state()
    let match: any = null
    let see: any = null
    let hide: any = null
    let nameclick: any = null
    // the props see and hide may be found here initially, then recurse via UI:Strata**
    function check_for_strata() {
        let some = false
        stuff.o().map(n => {
            if (!n.oa({ Strata: 1 })) return
            some = true
        })
        if (!some) return

        const N: TheC[] = []
        // Stuff/%nib/%Strata,match/%Tree:1     # what to find first
        //           /*%Strata,see/*%the:1,Stuffing:1,matches:1
        //           /%Tree                     # as per %Strata,match/*%*
        match = null
        see = null
        hide = null
        nameclick = null
        stuff.o().map(n => {
            if (!n.oa({ Strata: 1 })) return
            if (match) throw "< multi Strata"
            n.o({ Strata: 1, match: 1 }).map(ma => {
                ma.o().map(m => {
                    if (match) throw "< multi basis Strata"
                    match = { ...m.sc }
                })
            })
            n.o({ Strata: 1, see: 1 }).map(se => {
                // *%the:1,Stuffing:1,matches:1
                se.o().map(m => {
                    see ||= []
                    see.push({ ...m.sc })
                })
            })
            n.o({ Strata: 1, hide: 1 }).map(se => {
                // *%the:1,invisible:1
                se.o().map(m => {
                    hide ||= []
                    hide.push({ ...m.sc })
                })
            })
            n.o({ Strata: 1, nameclick_fn: 1 }).map(na => {
                nameclick = na.sc.nameclick_fn
            })
            if (match) {
                // find the first %Tree
                N.push(...n.o(match))
            }
        })
        // may not
        stratum = N[0]
        strata_version++
    }
    //#endregion
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
    {#if stratum}
        <div class="strata">
            {#key strata_version}
                v{strata_version}
                <Strata mem={mem.further('Strata')} C={stratum} {match} {see} {hide} {nameclick} />
            {/key}
        </div>
    {/if}
{/if}

<style>
.strata {
    display: block;
}
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