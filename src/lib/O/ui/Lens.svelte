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
    //     • Liesui mounts kind="Brink" — the cluster faces (Runner/Relay) of %Aim, FLOATING inside
    //       the Lies backend box (.ls-ui, position:relative) over a zero-height sticky anchor, so it
    //       reserves no flow space (its growing height never pushes the list) yet stays pinned to a
    //       corner of the scrollport however the list scrolls.  Vexpandy re-perches it bottom↔top, a
    //       side button right↔left.  Bounded by .ls-ui, so a Brink can never bleed onto the Langui editor.
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

    // Brink only: the dock re-perches between corners of the Liesui box — a move, not an expand.
    //  jumped = the Vexpandy flips it bottom↔top; lefted = the side button shoots it right↔left.
    let jumped = $state(false)
    let lefted = $state(false)
</script>

{#if panels.length}
    {#if kind === 'Brink'}
        <div class="lens-brink-anchor" class:lens-brink-top={jumped} class:lens-brink-left={lefted}>
            <div class="lens-brink">
                <div class="lens-brink-grips" title={jumped ? 'drop the cluster dock to the bottom of Lies' : 'jump the cluster dock to the top of Lies'}>
                    <Vexpandy bind:expanded={jumped} />
                    <button class="lens-brink-side" onclick={() => lefted = !lefted}
                        title={lefted ? 'send the cluster dock to the right of Lies' : 'send the cluster dock to the left of Lies'}>{lefted ? '⟩' : '⟨'}</button>
                </div>
                {#each panels as p (p.sc.of_Funkcion + ':' + (p.sc.pub ?? ''))}
                    <div class="lens-slot">
                        <LensHost {H} lens={p} />
                    </div>
                {/each}
            </div>
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
    /* Brink: a ZERO-HEIGHT sticky anchor reserves NO flow space; the dock floats OUT of it
       (absolute), overlaying the wafts and staying pinned to a corner of the .ls-ui scrollport
       however the list scrolls (sticky on the 0-height anchor = the .ls-nokey trick, minus the
       reserved strip — so its growing height never pushes the list).  Vexpandy jumps it bottom↔top;
       the side button shoots it right↔left, so it can perch in any corner.  z-index over the waft
       rows but well under the global Panel dock. */
    .lens-brink-anchor {
        position: sticky; bottom: 8px; height: 0;
        z-index: 7; pointer-events: none;
    }
    .lens-brink-anchor.lens-brink-top { top: 8px; bottom: auto; }
    .lens-brink {
        position: absolute; right: 8px; bottom: 0;
        width: max-content; max-width: 33%; min-width: 14rem;
        display: flex; flex-direction: column; align-items: stretch; gap: 2px;
        pointer-events: none;
    }
    .lens-brink-top  .lens-brink { bottom: auto; top: 0; }
    .lens-brink-left .lens-brink { right: auto; left: 8px; }
    .lens-brink-grips { display: flex; justify-content: flex-end; align-items: center; gap: 4px; pointer-events: auto; }
    .lens-brink-side {
        font-family: monospace; font-size: 0.8rem; line-height: 1; cursor: pointer;
        color: #5a6488; background: transparent; border: 1px solid #2c3450; border-radius: 3px;
        padding: 0 0.3rem;
    }
    .lens-brink-side:hover { color: #8fa0d0; border-color: #44609e; }
    .lens-slot { pointer-events: auto; }
    :global(.lens-brink .vx-btn) { color: #5a6488; }
</style>
