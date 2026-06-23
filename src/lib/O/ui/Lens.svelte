<script lang="ts">
    // Lens — a hoisted-UI HOSTPOINT: one surface that renders the held Lenses of a single KIND,
    //  stacked by altitude, mounting each through LensHost.
    //
    //   The bag (top_House().ave.{Lenses}) is the shared INDEX of suggested faces; the Lens-KIND
    //   (the mainkey value of Lens:<Kind>,of_Funkcion:<funk>) is the ROUTER.  So the app mounts one
    //   host per surface and each host filters the bag by its own kind (one host per kind, else a
    //   panel double-shows):
    //     • Otro mounts kind="Panel" — the global/fullscreen modals (e.g. IdHatch), fixed to the
    //       viewport bottom, accreting upward.
    //     • Liesui mounts kind="Brink" — the cluster faces (Runner/Relay) of %Aim, pinned INSIDE the
    //       Lies backend box (.ls-ui, position:relative), floating over the wafts.  Bottom-anchored
    //       at rest; an extra Vexpandy JUMPS the whole dock to the top of Liesui (it re-perches, it
    //       does not expand).  Bounded by .ls-ui, so a Brink can never bleed onto the Langui editor.
    //   Re-suggesting the same (kind, of_Funkcion) is the change-notice (oai merge + bump re-renders
    //   a face without tearing it down); altitude orders the stack.
    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"
    import LensHost from "$lib/O/Funk/LensHost.svelte"
    import Vexpandy from "$lib/O/ui/Vexpandy.svelte"

    let { H, kind = 'Panel' }: { H: House, kind?: string } = $props()

    let ave    = $derived(H.top_House().ave)
    let bag    = $derived((() => { void ave.version; return ave.o({ Lenses: 1 })[0] as TheC | undefined })())
    let panels = $derived((() => {
        void bag?.version
        const ps = (bag?.o({ Lens: kind }) as TheC[]) ?? []
        return [...ps].sort((a, b) => Number(a.sc.altitude ?? 10) - Number(b.sc.altitude ?? 10))
    })())

    // Brink only: the Vexpandy flips the dock between bottom-anchored (rest) and top-anchored
    //  (jumped) within the Liesui box — a re-perch, not an expand.
    let jumped = $state(false)
</script>

{#if panels.length}
    {#if kind === 'Brink'}
        <div class="lens-brink" class:lens-brink-top={jumped}>
            <div class="lens-brink-grip" title={jumped ? 'drop the cluster dock to the bottom of Lies' : 'jump the cluster dock to the top of Lies'}>
                <Vexpandy bind:expanded={jumped} />
            </div>
            {#each panels as p (p.sc.of_Funkcion)}
                <div class="lens-slot">
                    <LensHost {H} lens={p} />
                </div>
            {/each}
        </div>
    {:else}
        <div class="lens-dock">
            {#each panels as p (p.sc.of_Funkcion)}
                <div class="lens-slot" style={`z-index:${Math.round(Number(p.sc.altitude ?? 10) * 100)}`}>
                    <LensHost {H} lens={p} />
                </div>
            {/each}
        </div>
    {/if}
{/if}

<style>
    /* Panel: the global dock pinned to the viewport bottom; panels accrete upward (column-reverse).
       A fullscreen panel escapes the column via its own fixed chrome (IdHatch's FaceSucker). */
    .lens-dock {
        position: fixed; left: 0; right: 0; bottom: 0;
        display: flex; flex-direction: column-reverse; align-items: stretch;
        gap: 2px; pointer-events: none; z-index: 40000;
    }
    /* Brink: floats over the wafts INSIDE .ls-ui (absolute, no flow space), ~1/3 max / 1/5 min of
       the panel.  Bottom-right at rest (where the old .ls-health card sat), jumping to top-right on
       the Vexpandy.  z-index over the waft rows but well under the global Panel dock. */
    .lens-brink {
        position: absolute; right: 8px; bottom: 8px;
        max-width: 33%; min-width: 20%;
        display: flex; flex-direction: column; align-items: stretch; gap: 2px;
        z-index: 7; pointer-events: none;
    }
    .lens-brink-top { top: 8px; bottom: auto; }
    .lens-brink-grip { display: flex; justify-content: flex-end; pointer-events: auto; }
    .lens-slot { pointer-events: auto; }
    :global(.lens-brink .vx-btn) { color: #5a6488; }
</style>
