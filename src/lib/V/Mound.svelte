<script lang="ts">
    // Mound — the toplevel of the Piracy-scape (lib/V/), the Voro+Cyto cutting-edge UI that
    //  takes the / route over from the old p2p/ghost Intro.  The destination (owner): "Voronoi
    //   stained glass graphs of music" — the Cyto graph of a music world, tessellated into
    //    stained-glass cells (Cytui's ◈ voronoi mode, power-diagram cells coloured by Matstyle).
    //
    //  FIRST CUT (browser-verify OWED — pixels no Book can see): boot the SAME machine Otro boots,
    //   as a RUNNER on a music Book (default MusuScape — the graph-of-music twin of MusuMitosis:
    //    %Artist panes holding %Track songs, %Peer panes sharing tracks as edges, a track many
    //     friends share blazing as a hub), and render its Cyto UI full-bleed.  MusuScape crush-folds
    //      every artist and friend into one stuffed pane at its last beat, so `saw_stuffy` auto-arms
    //       the voronoi and the run rests in the stained-glass state a viewer sees.  ?B=<Book> swaps
    //        the Book (?B=MusuMitosis for the flora colony).  The bespoke Voro surface the owner wants
    //         ("Voro gets gathered in here later") grows from this — first prove the graph-of-music
    //          renders as glass at /, then replace the seeded Book with a LIVE gather (real library +
    //           real Piers off the Swarm side).
    //
    //  NOTE (owner call owed): a runner boot joins the relay flock (advertises, Creduler-acquires the
    //   spine) — one runner per / hit.  That is exactly how MusuMitosis is "watched" today, and the
    //    Piracy-scape is a live p2p thing, so it fits; but if / should NOT spawn a grid runner, switch
    //     boot_role to 'editor' (local, no flock — BigWordland's posture) and drive the run by hand.
    import Ghost      from "$lib/O/Ghost.svelte"
    import { House }  from "$lib/O/Housing.svelte"
    import { keyser } from "$lib/data/Stuff.svelte"
    import BootGate   from "$lib/O/ui/BootGate.svelte"
    import { onDestroy } from "svelte"
    import { boot_param } from "$lib/boot"

    // the music Book whose graph becomes the stained glass; ?B= overrides (?B=MusuMitosis, etc.)
    const book = boot_param('B') || 'MusuScape'

    //#region H:Mundo — construction, mirroring Otro's runner boot (the OOM trap: compute on a LOCAL
    //  `h` and assign H once; never read the $state H inside the construction effect — Otro's note).
    let H: House = $state(null!)
    $effect(() => {
        const h = new House({ name: 'Mundo' })
        h.c.toplevel  = 'Auto'
        h.c.book      = book
        h.c.boot_role = 'runner'     // run the Book so its graph forms + folds to glass (the ?B= path)
        H = h
        setTimeout(() => { houses = [H] }, 1)
    })

    let setup_done = $state(false)
    $effect(() => {
        if (!H?.started || setup_done) return
        setup_done = true
        H.may_begin()
        setTimeout(() => { houses = H.all_House }, 1)
        H.i_elvisto(H, 'think')
    })
    $effect(() => {
        if (!setup_done) return
        houses = H.all_House
    })
    let houses: House[] = $state([])

    onDestroy(() => { H?.stop() })
    //#endregion

    // the Cyto UI (Cytui) is registered by the Cyto ghost on whichever House carries the live graph;
    //  find it across H** and mount it full-bleed.  Its ◈ voronoi mode auto-arms on the crushed world.
    let cyto = $derived.by(() => {
        for (const house of houses) {
            void house.UIs.version
            const ui = house.UIs.ob({ UI: 'Cyto' })[0]
            if (ui) return { house, ui }
        }
        return undefined
    })
</script>

<BootGate {H} who="the piracy-scape" audio_fullscreen={true} />

<main class="mound">
    <header class="scape-top">
        <span class="scape-name" title="the Piracy-scape — Voronoi stained glass graphs of music">◈ jamscape</span>
        <span class="scape-book">{book}</span>
    </header>

    {#if cyto}
        {#key keyser(cyto.ui.sc)}
            <section class="scape-glass">
                <svelte:component this={cyto.ui.sc.component} H={cyto.house} />
            </section>
        {/key}
    {:else}
        <div class="scape-waiting">gathering the glass…</div>
    {/if}
</main>

{#if H}
    <Ghost {H} />
{/if}

<style>
    .mound {
        min-height: 100vh;
        display: flex; flex-direction: column;
        background: radial-gradient(130% 130% at 50% -20%, #10131f, #05060b 70%);
        color: #e7ecf5;
        font-family: system-ui, sans-serif;
    }
    .scape-top {
        display: flex; align-items: baseline; gap: 0.8rem;
        padding: 0.5rem 1rem;
        border-bottom: 1px solid rgba(120, 140, 195, 0.16);
    }
    .scape-name {
        font-size: 0.95rem; letter-spacing: 0.14em; text-transform: uppercase;
        color: #9fb2d8; text-shadow: 0 0 14px rgba(140, 170, 230, 0.4);
    }
    .scape-book { font-size: 0.75rem; color: rgba(150, 170, 205, 0.6); }
    .scape-glass { flex: 1; min-height: 0; position: relative; }
    .scape-waiting {
        flex: 1; display: grid; place-items: center;
        color: rgba(150, 170, 205, 0.5); font-size: 0.9rem; letter-spacing: 0.1em;
    }
</style>
