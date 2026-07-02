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

    // Brink only.  open = the Vexpandy unfurls the full-face stack; collapsed (default) shows just the
    //  grips bar + a one-row MiniBrink summary — connectivity at a glance.  The bar is position:fixed to
    //   a viewport corner, so it survives scrolling above Lies (the old sticky-in-.ls-ui anchor didn't).
    //    lefted = the side button perches it left↔right.
    let open   = $state(false)
    let lefted = $state(false)
</script>

{#if panels.length}
    {#if kind === 'Brink'}
        <div class="lens-brink" class:lens-brink-left={lefted} class:lens-brink-open={open}>
            <div class="lens-brink-grips">
                {#if !open}
                    <!-- collapsed: the whole rack as a one-row MiniBrink summary, on the INTERIOR side of
                         the grip buttons — a changing fleet width grows the row away from the screen edge,
                         so the Vexpandy + side button stay pinned to the corner and always toggle-able.
                         Same lens particles the pusher posits; LensHost mounts each funk's comp_MiniBrink
                         face and skips a funk that has none. -->
                    <div class="lens-brink-mini">
                        {#each panels as p (p.sc.of_Funkcion + ':' + (p.sc.pub ?? ''))}
                            <LensHost {H} lens={p} face="MiniBrink" mini />
                        {/each}
                    </div>
                {/if}
                <Vexpandy bind:expanded={open} />
                <button class="lens-brink-side" onclick={() => lefted = !lefted}
                    title={lefted ? 'perch the cluster dock on the right' : 'perch the cluster dock on the left'}>{lefted ? '⟩' : '⟨'}</button>
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
    /* Brink: a persistent cluster HUD FIXED to a viewport corner (bottom-right, or bottom-left when
       lefted) — it survives scrolling above Lies, unlike the old sticky-in-.ls-ui anchor.
         The grips bar (Vexpandy + side button + collapsed mini row) is the fixed one-row anchor and
          NEVER moves — the faces float OFF it, so the guts growing can't shift the bar (no more
           jump-up-its-own-height).
         collapsed (default): grips bar + a one-row MiniBrink summary (connectivity at a glance).
         open: the Vexpandy unfurls the full-face .lens-brink-stack just above the bar, growing UP and
               away from it (never reaching Langui's NaviCado below).
       z over the app but under the global Panel dock (IdHatch modals, 40000).  pointer-events:none on
        the bar itself so its empty stretch never blocks the content behind; the buttons/faces re-enable. */
    .lens-brink {
        position: fixed; right: 8px; bottom: 8px; z-index: 9500;
        display: flex; justify-content: flex-end; align-items: center; gap: 4px;
        pointer-events: none;
    }
    .lens-brink-left { right: auto; left: 8px; justify-content: flex-start; }
    .lens-brink-grips {
        display: flex; align-items: center; gap: 4px; pointer-events: auto;
        background: rgba(14, 12, 20, 0.9); border: 1px solid #2c3450; border-radius: 6px; padding: 2px 5px;
    }
    /* perched left: flip so the buttons hug the LEFT edge and the mini grows rightward (interior) —
       the buttons always hug whichever edge the dock is pinned to, mini always on the interior side. */
    .lens-brink-left .lens-brink-grips { flex-direction: row-reverse; }
    .lens-brink-mini { display: flex; align-items: center; gap: 6px; pointer-events: auto; }
    /* the guts: floated just above the grip bar (bottom:100%), right-aligned to it and growing UP.
       Height-capped + self-scrolling so a tall stack scrolls rather than climbing off-screen. */
    .lens-brink-stack {
        position: absolute; right: 0; bottom: calc(100% + 4px);
        display: flex; flex-direction: column; align-items: stretch; gap: 2px;
        min-width: 14rem; max-width: 28rem; max-height: 60vh; overflow-y: auto;
        pointer-events: auto;
    }
    .lens-brink-left .lens-brink-stack { right: auto; left: 0; }
    .lens-brink-side {
        font-family: monospace; font-size: 0.8rem; line-height: 1; cursor: pointer;
        color: #5a6488; background: transparent; border: 1px solid #2c3450; border-radius: 3px;
        padding: 0 0.3rem;
    }
    .lens-brink-side:hover { color: #8fa0d0; border-color: #44609e; }
    .lens-slot { pointer-events: auto; }
    :global(.lens-brink .vx-btn) { color: #5a6488; }
</style>
