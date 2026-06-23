<script lang="ts">
    // Lens — the ambient floating dock: the bottom-accreting stack of hoisted panels.
    //
    //   The presence:always sibling of the InterestStrip's presence:active foreground
    //   switcher.  Where the strip is a horizontal row that competes for one stage, the
    //   Lens is a vertical stack that builds upward from the bottom of the screen and never
    //   steals the stage — ambient UI a Funkcion (or a system poke) hoists over Lies.
    //
    //   Each hoisted panel is a held Lens:Panel,of_Funkcion:<kind> in the session ave on the
    //   top House (off-snap; Lies_lens_suggest stamps it, LiesWaft).  The dock shows only the
    //   Panel-kind Lenses; the InterestStrip shows the InterestSmall|Big kinds from the same
    //   bag.  altitude is the float height: low docks a chip at the bottom, high floats up (a
    //   fullscreen face — IdHatch's own FaceSucker — overlays everything).  The dock orders by
    //   altitude and renders each through LensHost; it stays dumb — the suggester decides what
    //   and how high.  Re-suggesting the same (kind, of_Funkcion) is the change-notice (an oai
    //   merge + bump on the held particle re-renders its face without tearing it down).
    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"
    import LensHost from "$lib/O/Funk/LensHost.svelte"

    let { H }: { H: House } = $props()

    // anchor on the top House's ave so the dock and the suggester share one session home
    //  (ave is per-House $state; Lies_lens_suggest writes top_House().ave too).
    let ave  = $derived(H.top_House().ave)
    let bag  = $derived((() => { void ave.version; return ave.o({ Lenses: 1 })[0] as TheC | undefined })())
    let panels = $derived((() => {
        void bag?.version
        const ps = (bag?.o({ Lens: 'Panel' }) as TheC[]) ?? []
        return [...ps].sort((a, b) => Number(a.sc.altitude ?? 10) - Number(b.sc.altitude ?? 10))
    })())
</script>

{#if panels.length}
<div class="lens-dock">
    {#each panels as p (p.sc.of_Funkcion)}
        <div class="lens-slot" style={`z-index:${Math.round(Number(p.sc.altitude ?? 10) * 100)}`}>
            <LensHost {H} lens={p} />
        </div>
    {/each}
</div>
{/if}

<style>
    /* the dock itself is a passthrough strip pinned to the bottom; panels accrete upward
       (column-reverse → the first/lowest-altitude lens sits at the very bottom).  Each slot
       re-enables pointer events; a fullscreen panel escapes the column via its own fixed chrome. */
    .lens-dock {
        position: fixed; left: 0; right: 0; bottom: 0;
        display: flex; flex-direction: column-reverse; align-items: stretch;
        gap: 2px; pointer-events: none; z-index: 40000;
    }
    .lens-slot { pointer-events: auto; }
</style>
