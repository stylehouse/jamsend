<script lang="ts">
    // BigSoundland — the music-half toplevel (lib/V/), the /BigSoundland route (the bare / 404s now —
    //  bots hammer it, so the root boots nothing; see routes/+page.ts).  The
    //  destination (owner): "Voronoi stained glass graphs of music" — the Cyto graph of a music world
    //   tessellated into stained-glass cells (Cytui's ◈ voronoi mode, power-diagram cells coloured by
    //    Matstyle).  Sibling to /BigWordland; both boot the SAME machine (BigQualand's boot_qualand) —
    //     Word as the editor room, Sound as a RUNNER on a music Book.
    //
    //  The Book (owner): today VoroScape (the graph-of-music twin of VoroMitosis — %Artist panes of
    //   %Track songs, %Peer panes sharing tracks as edges, a track many friends share blazing as a hub).
    //    It is BECOMING a **Sounditron** — the sound twin of Educarium/Editron: a central diagnostic
    //     Book (NOT a Musu* test, NO Lies+Lang) that lurks in the background, probes the real audio +
    //      networking environment ("is a track playing? are my people online?"), and surfaces coherent
    //       errors so a user becomes a reporting test-probe.  ?B= overrides the Book.
    //
    //  WHY THE GLASS MAY NOT DRAW ("gathering the glass…" forever): a runner boot HOLDS story-start
    //   until the Creduler loads the spine (Auto.svelte — "⏳ Creduler loading spine…").  A plain / tab
    //    with no ?I= identity, no granted share, no relay engagement may never acquire it → no Story,
    //     no Cyto.  So when the glass isn't up we show the DIAGNOSTIC below — the Story runner UI (once
    //      it stands up) plus the live House/Creduler state — to scan out what's wrong with the main bit.
    //
    //  THE ▦ SPRAWL — the way OUT of the single glass face: the glass is full-bleed (one Cyto UI), so
    //   once it draws every OTHER H** UI vanishes.  ▦ (in the header) toggles a sprawl of EVERY House's
    //    UIs dumped in order down one page (Cyto included) — the gutsy multi-UI interface, twin of
    //     /BigWordland's ▦.  Persisted in the stash (BigSoundland_sprawl) so the choice sticks.  Note the
    //      SEPARATE fullscreen gate: BootGate's FaceSucker (disk-share / audio tap) — cleared by GRANTING,
    //       not by ▦; if it's covering the screen, open the folder / tap for sound to get past it.
    import Ghost      from "$lib/O/Ghost.svelte"
    import { keyser } from "$lib/data/Stuff.svelte"
    import BootGate   from "$lib/O/ui/BootGate.svelte"
    import { boot_param } from "$lib/boot"
    import { boot_qualand } from "$lib/O/BigQualand.svelte"

    // the music Book whose graph becomes the stained glass; ?B= overrides (?B=VoroMitosis, etc.)
    const book = boot_param('B') || 'VoroScape'

    //#region H:Mundo — the shared boot lives in BigQualand now (the aufheben's common bit): this
    //  scape supplies only its knobs — a music Book, the runner role (run it so the graph forms and
    //   crush-folds to glass) — and reads H + houses back.  The OOM trap is baked in over there.
    const q = boot_qualand({ book, role: 'runner' })
    let H      = $derived(q.H)
    let houses = $derived(q.houses)
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

    // the diagnostic surface — every NON-Cyto UI the run has produced so far (the Story runner UI
    //  above all, which shows phase / step / see-assertions / verdict / errors), so you watch the
    //   machine come up (or fail to) instead of a blank "gathering the glass…".
    let run_uis = $derived.by(() => {
        const out: { house: any, ui: any }[] = []
        for (const house of houses) {
            void house.UIs.version
            for (const ui of house.UIs.ob({ UI: 1 })) {
                if (ui.sc.UI !== 'Cyto') out.push({ house, ui })
            }
        }
        return out
    })

    // is the Creduler still holding the spine open?  If the only House is Mundo (no H:Story yet), the
    //  runner is stuck BEFORE the story — the Creduler-spine hold, not a run error.
    let boot_state = $derived.by(() => ({
        creduler_up:   !!(H as any)?.c?.creduler_up,
        story_stood:   houses.some(h => h !== H),   // any House beyond Mundo ⇒ the Story world stood up
        houses,
    }))

    // ── the way OUT of the glass ────────────────────────────────────────────────────────────
    // The glass is a single full-bleed face (one Cyto UI); once it draws, every OTHER H** UI is
    //  gone.  The ▦ sprawl is the escape hatch back to the gutsy interface: EVERY House's UIs
    //   dumped in order down the page (Cyto included, as one panel among many), so you can reach
    //    the run controls / Brink / anything the run mounted.  A workspace choice, so it lives in
    //     the stash (reactive $state on the House, like BigWordland's) and survives a reload.
    let sprawl = $derived(!!H?.stashed?.BigSoundland_sprawl)
    function toggle_sprawl() {
        if (!H?.stashed) return
        if (H.stashed.BigSoundland_sprawl) delete H.stashed.BigSoundland_sprawl
        else H.stashed.BigSoundland_sprawl = 1
    }
    // every UI the run has mounted, across all Houses, Cyto and all — the sprawl's content.
    //  Pantheate-include is FOLDED OUT: LiesCortex notifies Pantheate on EVERY compile, so a many-
    //   dock Book mounts many identical include shims — noise, not run output (the real landing is
    //    Pantheate/BlastPit; the real cure is to sprout only from the %rungo run path — deferred,
    //     sensitive Lies/Run work).  We drop them but keep a count so nothing is hidden silently.
    let sprawl_view = $derived.by(() => {
        const uis: { house: any, ui: any }[] = []
        let pantheate = 0
        for (const house of houses) {
            void house.UIs.version
            for (const ui of house.UIs.ob({ UI: 1 })) {
                if (ui.sc.UI === 'Pantheate-include') { pantheate++; continue }
                uis.push({ house, ui })
            }
        }
        return { uis, pantheate }
    })
</script>

<BootGate {H} who="the piracy-scape" audio_fullscreen={true} />

<main class="mound">
    <header class="scape-top">
        <span class="scape-name" title="BigSoundland — the music scape: Voronoi stained glass graphs of music (the /BigSoundland route)">◈ BigSoundland</span>
        <span class="scape-book">{book}</span>
        <button class="scape-sprawl-btn" class:on={sprawl}
                title={sprawl
                    ? 'sprawl: every House’s UIs dumped in order — click to drop back to the glass'
                    : 'sprawl — the way out of the glass: dump every House’s UIs down one page'}
                onclick={toggle_sprawl}>▦</button>
    </header>

    {#if sprawl}
        <!-- the gutsy sprawl — every House's UIs in order, the escape from the single glass face -->
        <section class="scape-sprawl">
            {#each sprawl_view.uis as { house, ui } (keyser(ui.sc))}
                <div class="diag-ui">
                    <span class="diag-tag">{house.name} · {ui.sc.UI}</span>
                    <svelte:component this={ui.sc.component} H={house} />
                </div>
            {/each}
            {#if sprawl_view.pantheate}
                <div class="diag-line diag-folded">{sprawl_view.pantheate}× Pantheate-include folded (per-compile artifact — the run lands in Pantheate/BlastPit)</div>
            {/if}
            {#if !sprawl_view.uis.length && !sprawl_view.pantheate}
                <div class="diag-line">nothing mounted yet — the run hasn't produced any UI to sprawl</div>
            {/if}
        </section>
    {:else if cyto}
        {#key keyser(cyto.ui.sc)}
            <section class="scape-glass">
                <svelte:component this={cyto.ui.sc.component} H={cyto.house} />
            </section>
        {/key}
    {:else}
        <!-- the glass isn't drawing — show what the machine is doing so we can scan out what's wrong -->
        <section class="scape-diag">
            <div class="diag-line">
                <span class="diag-dot" class:on={boot_state.story_stood}></span>
                {#if boot_state.story_stood}
                    the run stood up — waiting for its graph to draw as glass
                {:else if boot_state.creduler_up}
                    ⏳ the Creduler is loading the spine — a plain / tab with no identity / share / relay
                     may never acquire it (see the header note)
                {:else}
                    booting…
                {/if}
            </div>
            <div class="diag-houses">
                {#each boot_state.houses as h (h.c?.ip ?? h.name)}
                    <span class="diag-h" class:on={h.started}>{h.name}</span>
                {/each}
            </div>
            {#each run_uis as { house, ui } (keyser(ui.sc))}
                <div class="diag-ui">
                    <span class="diag-tag">{house.name} · {ui.sc.UI}</span>
                    <svelte:component this={ui.sc.component} H={house} />
                </div>
            {/each}
        </section>
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
    /* ▦ the way out of the glass — flip to the gutsy sprawl of every House's UIs */
    .scape-sprawl-btn {
        margin-left: auto;
        background: none; border: 1px solid rgba(120, 140, 195, 0.25); border-radius: 6px;
        cursor: pointer; font-family: inherit; font-size: 0.85rem; line-height: 1;
        color: rgba(150, 170, 205, 0.7); padding: 0.15rem 0.5rem;
        transition: color 0.12s, background 0.12s, border-color 0.12s;
    }
    .scape-sprawl-btn:hover { color: #e4ecff; border-color: rgba(150, 190, 240, 0.5); }
    .scape-sprawl-btn.on { color: #cfe0ff; background: rgba(120, 150, 210, 0.16); border-color: rgba(150, 190, 240, 0.45); }
    .scape-glass { flex: 1; min-height: 0; position: relative; }

    /* the gutsy sprawl — every House's UIs stacked down one scrollable page */
    .scape-sprawl {
        flex: 1; min-height: 0; overflow: auto;
        display: flex; flex-direction: column; gap: 1.6rem;
        padding: 1rem;
    }

    /* the boot diagnostic — shown while the glass hasn't gathered */
    .scape-diag {
        flex: 1; min-height: 0; overflow: auto;
        display: flex; flex-direction: column; gap: 0.9rem;
        padding: 1rem;
    }
    .diag-line {
        display: flex; align-items: baseline; gap: 0.5rem;
        font-size: 0.82rem; color: rgba(180, 195, 225, 0.75); line-height: 1.4;
    }
    .diag-folded { opacity: 0.55; font-style: italic; font-size: 0.74rem; }
    .diag-dot {
        width: 0.5rem; height: 0.5rem; border-radius: 50%; flex: none;
        background: rgba(200, 160, 90, 0.8);   /* amber = pre-run */
        box-shadow: 0 0 8px rgba(200, 160, 90, 0.6);
    }
    .diag-dot.on { background: #6fd08a; box-shadow: 0 0 8px rgba(110, 210, 140, 0.6); }  /* green = stood up */
    .diag-houses { display: flex; flex-wrap: wrap; gap: 0.3rem; }
    .diag-h {
        font-size: 0.72rem; font-family: monospace;
        color: rgba(150, 170, 205, 0.55);
        border: 1px solid rgba(120, 140, 195, 0.22); border-radius: 5px;
        padding: 0.05rem 0.4rem;
    }
    .diag-h.on { color: #cfe0ff; border-color: rgba(150, 190, 240, 0.5); }
    .diag-ui { position: relative; padding-top: 1.1rem; }
    .diag-tag {
        position: absolute; top: 0; left: 0.15rem;
        font-size: 0.62rem; letter-spacing: 0.08em; color: rgba(120, 135, 170, 0.55);
        user-select: none; pointer-events: none;
    }
</style>
