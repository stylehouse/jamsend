<script lang="ts">
    import Strata from '$lib/data/Strata.svelte';
    import type { Matchy } from '$lib/mostly/Structure.svelte.ts';
    import type { Modus, Modusmem } from "$lib/mostly/Modus.svelte.ts";
    import { Stuff, Stuffing, type TheUniversal } from './Stuff.svelte.ts';
    import type { House } from '$lib/O/Housing.svelte.ts';
    import Stuffusion from './Stuffusion.svelte'
    import { getContext, setContext, untrack } from 'svelte'
    import { throttle } from '$lib/Y.svelte.ts'

    let { mem, stuff, matchy, M, H: H_prop }:{ 
        mem: Modusmem, 
        stuff: Stuff,
        matchy?: Matchy,
        hide?: Array<TheUniversal>,
        M?: Modus,
        H?: House,
    } = $props()
    mem = mem.further("Stuffing")

    // H flows down to nested Stuffings via context (Stuffzipper -> Stuffing)
    //  so Stuffzipper doesn't need to know about H at all
    const H: House | undefined = H_prop ?? getContext('H')
    if (H_prop) setContext('H', H_prop)

    let spinner = $state(false)

    // one Stuffing instance for the lifetime of this component.
    // groups is SvelteMap — reactive; started is $state — reactive.
    // brackology() is synchronous: started = true before it returns.
    let stuffing = new Stuffing(stuff, matchy)

    // fallback throttle for when H isn't threaded through — prevents naked brackology spam
    const throttled_brackology = throttle(() => {
        stuffing.Stuff = stuff
        stuffing.matchy = matchy
        stuffing.brackology()
        if (M) setTimeout(check_for_strata, 0)
    }, 200)

    $effect(() => {
        const S = stuff  // only dep we want
        if (!S) return

        // untrack: don't subscribe to anything brackology reads internally
        untrack(() => {
            stuffing.Stuff = S
            stuffing.matchy = matchy
            stuffing.brackology()
            if (M) setTimeout(check_for_strata, 0)
        })

        if (!H) {
            // no Housing to drive us — fall back to a local throttle watching stuff.version
            // < coarser than H-driven; misses deep mutations below stuff
            return  // $effect cleanup: nothing to deregister
        }

        const deregister = H.register_stuffing(S, () => {
            spinner = true
            untrack(() => {
                stuffing.Stuff = S
                stuffing.matchy = matchy
                stuffing.brackology()
            })
            setTimeout(() => { spinner = false }, 333)
            if (M) setTimeout(check_for_strata, 0)
        })
        return deregister
    })
    $effect(() => {
        if (H || !stuff) return
        void stuff.version   // single reactive dep
        throttled_brackology()
    })

    let strata_version = $state(0)
    let stratum = $state()
    let match = null
    // the props see and hide may be found here initially
    //  then recurse via UI:Strata**
    let nameclick = null
    function check_for_strata() {
        let some = false
        stuff.o().map(n => {
            if (!n.oa({Strata:1})) return
            some = true
        })
        if (!some) return

        let N = []
        // Stuff/%nib/%Strata,match/%Tree:1     # what to find first
        //           /*%Strata,see/*%the:1,Stuffing:1,matches:1
        //           /%Tree                     # as per %Strata,match/*%*
        match = null
        see = null
        hide = null
        nameclick = null
        stuff.o().map(n => {
            if (!n.oa({Strata:1})) return
            if (match) throw "< multi Strata"
            n.o({Strata:1,match:1}).map(ma => {
                ma.o().map(m => {
                    if (match) throw "< multi basis Strata"
                    match = {...m.sc}
                })
            })
            n.o({Strata:1,see:1}).map(se => {
                // *%the:1,Stuffing:1,matches:1
                se.o().map(m => {
                    see ||= []
                    see.push({...m.sc})
                })
            })
            n.o({Strata:1,hide:1}).map(se => {
                // *%the:1,invisible:1
                se.o().map(m => {
                    hide ||= []
                    hide.push({...m.sc})
                })
            })

            n.o({Strata:1,nameclick_fn:1}).map(na => {
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

</script>

{#if stuffing.started}
    <div class="stuffing">
        <div class="content">
            {#each Array.from(stuffing.groups.values()) as stuffusion:Stuffusion (stuffusion.name)}
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
                <Strata mem={mem.further('Strata')} C={stratum} {match} {see} {hide} {nameclick} ></Strata>
            {/key}
        </div>
    {/if}
{/if}



<style>
.strata {
    display:block;
}
.stuffing {
    margin: 0.1em;
    border-radius: 4em;
    border: 1px dotted rgb(38, 110, 217);
    background-color: rgb(5, 46, 46);
    display: inline-block;
    /* filter: hue-rotate(-50deg); */
    padding: 0.1em;
    position: relative;
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
.content {
    display: inline-block;
    min-height:1em;
    min-width:1em;
}
</style>
