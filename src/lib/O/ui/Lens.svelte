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
    //     • Liesui mounts kind="Brink" — the cluster faces (Rundar/Relay/Sound…) of %Aim, FLOATING
    //       inside the Lies backend box (.ls-ui, position:relative) over a zero-height sticky anchor, so
    //       it reserves no flow space yet stays pinned to a corner of the scrollport as the list scrolls
    //       — and is BOUND by .ls-ui, so it can never bleed onto the Langui editor below (nor float over
    //       it: when Lies scrolls out of view the HUD leaves with it).  The Vexpandy COLLAPSES it to a
    //       one-row MiniBrink summary; a side button perches it left↔right.
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

    // Brink only.  open = the Vexpandy unfurls the full-face stack; collapsed (default) shows just the
    //  grips bar + a one-row MiniBrink summary (connectivity at a glance).  The Brink is a flex child of
    //   Liesui's shared base-shell now — the shell owns the sticky-at-the-foot positioning and puts the
    //    Plank on the left, the Brink on the right, so there's no self-anchor and no left/right side button.
    let open = $state(false)
</script>

{#if panels.length}
    {#if kind === 'Brink'}
        <div class="lens-brink" class:lens-brink-open={open}>
            <div class="lens-brink-grips">
                {#if !open}
                    <!-- collapsed: the whole rack as a one-row MiniBrink summary, on the INTERIOR side of the
                         Vexpandy — a changing fleet width grows the row leftward, away from the toggle, so the
                         Vexpandy holds its spot and is always hit-able.  Same lens particles the pusher posits;
                         LensHost mounts each funk's comp_MiniBrink face and skips a funk that has none. -->
                    <div class="lens-brink-mini">
                        {#each panels as p (p.sc.of_Funkcion + ':' + (p.sc.pub ?? ''))}
                            <LensHost {H} lens={p} face="MiniBrink" mini />
                        {/each}
                    </div>
                {/if}
                <Vexpandy bind:expanded={open} />
            </div>
            {#if open}
                <div class="lens-brink-stack">
                    {#each panels as p (p.sc.of_Funkcion + ':' + (p.sc.pub ?? ''))}
                        <div class="lens-slot">
                            <LensHost {H} lens={p} />
                        </div>
                    {/each}
                </div>
            {/if}
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
    /* Brink: %Aim's cluster faces (Rundar/Relay/Sound…) — a flex child of Liesui's shared base-shell,
       which owns the sticky-at-the-foot-of-.ls-ui positioning; the Brink just renders its bar + guts.
         The grips bar (Vexpandy + collapsed mini row) is position:relative and one row tall — the guts
          float OFF it (absolute, up), so a growing stack can't resize the bar (no jump-up-its-own-height).
         collapsed (default): grips bar + a one-row MiniBrink summary (connectivity at a glance).
         open: the stack unfurls just ABOVE the bar, growing UP into Lies (never down onto NaviCado). */
    .lens-brink {
        position: relative;
        display: flex; align-items: center; gap: 4px;
        pointer-events: none;
    }
    .lens-brink-grips {
        display: flex; align-items: center; gap: 4px; pointer-events: auto;
        background: rgba(14, 12, 20, 0.9); border: 1px solid #2c3450; border-radius: 6px; padding: 2px 5px;
    }
    .lens-brink-mini { display: flex; align-items: center; gap: 6px; pointer-events: auto; }
    /* the guts: floated just above the grip bar (bottom:100%), right-aligned to it and growing UP.
       Height-capped + self-scrolling so a tall stack scrolls rather than climbing off-screen. */
    .lens-brink-stack {
        position: absolute; right: 0; bottom: calc(100% + 4px);
        display: flex; flex-direction: column; align-items: stretch; gap: 2px;
        min-width: 14rem; max-width: 28rem; max-height: 60vh; overflow-y: auto;
        pointer-events: auto;
    }
    .lens-slot { pointer-events: auto; }
    :global(.lens-brink .vx-btn) { color: #5a6488; }
</style>
