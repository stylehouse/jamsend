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
    import Actions    from "$lib/O/ui/Actions.svelte"
    import Lens       from "$lib/O/ui/Lens.svelte"
    import InvitePanel from "$lib/O/ui/InvitePanel.svelte"
    import { boot_param } from "$lib/boot"
    import { boot_qualand } from "$lib/O/BigQualand.svelte"

    // the resident Book — the Sounditron (the diagnostic probe this header long promised): it
    //  probes the REAL environment, commissions the glass ITSELF (world-side, not a toc Opt),
    //   and its guts — %Machine/%Relay/%Possibility/%Audio/%Session + the seen|log trail —
    //    ARE the graph the crusher folds.  ?B= overrides (?B=VoroScape for the music demo).
    const book = boot_param('B') || 'Sounditron'

    //#region H:Mundo — the shared boot lives in BigQualand now (the aufheben's common bit): this
    //  scape supplies only its knobs — a music Book, the runner role (run it so the graph forms and
    //   crush-folds to glass) — and reads H + houses back.  The OOM trap is baked in over there.
    const q = boot_qualand({ book, role: 'sound' })   // role 'sound' ⇒ Lies%humdinger: an end-user page, never a dispatch target
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

    // the spine shims — the load-bearing plumbing.  A runner ACQUIRES each spine ghost by enrolling a
    //  UI:Pantheate-include (Creduler_ensure → Lies_ghost_set, one per CREDULER_GHOST); but the ghost's
    //   METHODS (Socket_real, the envelope spine, …) only land when that shim's COMPONENT MOUNTS and its
    //    onMount eatfunc runs ("a UIless run renders nothing, so onMount never fires" — LiesLies).  So
    //     these MUST be in the DOM regardless of which view is up: they render nothing, but if the view
    //      starves them the runner never gets its transport — guard 3 (Socket_real !== 'function') fires,
    //       the Relay Brink reads "down", it never even dials, Creduler_pending never clears, no Story.
    //        Mounted hidden OUTSIDE the glass/diag/sprawl switch so the view choice can't starve the boot
    //         — a persisted `sprawl` (which doesn't render them) used to do exactly that.
    let spine_shims = $derived.by(() => {
        const out: { house: any, ui: any }[] = []
        for (const house of houses) {
            void house.UIs.version
            for (const ui of house.UIs.ob({ UI: 'Pantheate-include' })) out.push({ house, ui })
        }
        return out
    })

    // the diagnostic surface — every real NON-Cyto UI the run has produced so far (the Story runner UI
    //  above all, which shows phase / step / see-assertions / verdict / errors), so you watch the machine
    //   come up (or fail to) instead of a blank "gathering the glass…".  Pantheate-include is excluded —
    //    it's the spine plumbing above, always-mounted hidden, not diagnostic content.
    let run_uis = $derived.by(() => {
        const out: { house: any, ui: any }[] = []
        for (const house of houses) {
            void house.UIs.version
            for (const ui of house.UIs.ob({ UI: 1 })) {
                if (ui.sc.UI !== 'Cyto' && ui.sc.UI !== 'Pantheate-include') out.push({ house, ui })
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
    // every UI the run has mounted, GROUPED by House (Cyto and all) — the sprawl's content.
    //  Grouping gives each House one anchor the jump-to-H chips scroll to, plus its own heading in
    //   the dump.  Pantheate-include is DROPPED silently: on a runner these are the Creduler's
    //    acquire shims — Creduler_ensure enrols one UI:Pantheate-include per CREDULER_GHOST
    //     (Lies_ghost_set) purely so the mounted .go's onMount deposits that ghost's methods; they
    //      render nothing (UIless spine plumbing), so they'd only clutter the page with empty
    //       sections.  Not worth a line — we skip them and sprawl the real UIs.
    let sprawl_view = $derived.by(() => {
        const groups: { house: any, uis: any[] }[] = []
        for (const house of houses) {
            void house.UIs.version
            const uis: any[] = []
            for (const ui of house.UIs.ob({ UI: 1 })) {
                if (ui.sc.UI === 'Pantheate-include') continue   // UIless spine plumbing — skip
                uis.push(ui)
            }
            if (uis.length) groups.push({ house, uis })
        }
        return { groups }
    })

    // ── the sprawl's own toc: jump-to-H chips + an action row (BigWordland's parity) ──────────
    // The sprawl dumps every House down one page; the chips are a JUMP toc — click a House and its
    //  section scrolls to the base of the sticky top bar (scroll-margin-top clears the bar height).
    //   The same click makes that House `active`, so the ⚙ cog beside it opens ITS action rack in
    //    the row below the bar.  That row rides IN FLOW (not sticky) so it scrolls away with the
    //     page, exactly like BigWordland's .bw-panel.  All of it shows only while sprawling.
    let view = $state<string | undefined>(undefined)   // the user's picked House (ip); undefined ⇒ auto
    let active_ip = $derived(
        view
        ?? cyto?.house.c.ip                       // default to the graph House — the interesting one
        ?? houses[houses.length - 1]?.c.ip
    )
    let active = $derived(houses.find(h => h.c.ip === active_ip))
    let show_actions = $state(false)               // the action rack hides until the ⚙ cog asks

    function depth_of(house: any): number {        // H** depth reads as chip indent
        return ((house.c?.ip as string | undefined)?.split('_').length ?? 1) - 1
    }
    function jump_to(ip: string) {                 // pick the House + scroll its section into view
        view = ip
        document.getElementById('sp-' + ip)?.scrollIntoView({ behavior: 'smooth', block: 'start' })
    }
</script>

<BootGate {H} who="the piracy-scape" audio_fullscreen={true} proactive={true} />

<main class="mound">
    <header class="scape-top">
        <span class="scape-name" title="BigSoundland — the music scape: Voronoi stained glass graphs of music (the /BigSoundland route)">◈ BigSoundland</span>
        <span class="scape-book">{book}</span>
        {#if sprawl}
            <!-- the jump toc — one chip per House with UIs; click scrolls to its section + arms its actions -->
            <nav class="scape-toc">
                {#each sprawl_view.groups as { house } (house.c.ip)}
                    <button class="scape-h" style="--d: {depth_of(house)}"
                            class:active={active_ip === house.c.ip}
                            class:off={!house.started}
                            onclick={() => jump_to(house.c.ip)}
                            title="{house.name} — jump to its UIs">{house.name}</button>
                    {#if active_ip === house.c.ip}
                        <button class="scape-cog" class:on={show_actions}
                                onclick={() => show_actions = !show_actions}
                                title="{house.name} — {house.actions.ob({ action: 1 }).length} action buttons">⚙</button>
                    {/if}
                {/each}
            </nav>
        {/if}
        <button class="scape-sprawl-btn" class:on={sprawl}
                title={sprawl
                    ? 'sprawl: every House’s UIs dumped in order — click to drop back to the glass'
                    : 'sprawl — the way out of the glass: dump every House’s UIs down one page'}
                onclick={toggle_sprawl}>▦</button>
    </header>

    <!-- the strip — chunky panels of varying heights atop the scape (Swarm_spec §10.1: the Invite
         front door lives here; siblings join beside it as the interface grows). In flow, not
         sticky — it scrolls away with the page rather than taxing the glass. -->
    {#if H}
        <div class="scape-strip">
            <InvitePanel {H} />
        </div>
    {/if}

    <!-- the active House's action rack — in flow beneath the bar, scrolls away with the page (sprawl only) -->
    {#if sprawl && show_actions && active}
        <div class="scape-panel">
            <span class="scape-panel-name">{active.name}{#if !active.started}<span class="scape-off">off</span>{/if}</span>
            <Actions N={active.actions.ob({ action: 1 })} />
        </div>
    {/if}

    {#if sprawl}
        <!-- the gutsy sprawl — every House's UIs in order, the escape from the single glass face.
             Grouped by House so each carries a jump anchor (id=sp-<ip>) the toc chips scroll to. -->
        <section class="scape-sprawl">
            {#each sprawl_view.groups as { house, uis } (house.c.ip)}
                <div class="scape-house" id={'sp-' + house.c.ip}>
                    <div class="scape-house-name" class:off={!house.started}>{house.name}</div>
                    {#each uis as ui (keyser(ui.sc))}
                        <div class="diag-ui">
                            <span class="diag-tag">{house.name} · {ui.sc.UI}</span>
                            <svelte:component this={ui.sc.component} H={house} />
                        </div>
                    {/each}
                </div>
            {/each}
            {#if !sprawl_view.groups.length}
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

<!-- the spine shims: ALWAYS mounted, hidden (see the spine_shims comment).  They render nothing but
     their onMount deposits each acquired ghost's methods (Socket_real, the envelope spine, …).  Kept
      OUT of the view switch so the view choice — a persisted sprawl above all — can never starve the
       boot: no shim mount ⇒ no transport ⇒ "relay down, not trying" ⇒ no Story. -->
{#if H}
    <div class="spine-shims" aria-hidden="true">
        {#each spine_shims as { house, ui } (keyser(ui.sc))}
            <svelte:component this={ui.sc.component} H={house} />
        {/each}
    </div>
{/if}

<!-- the global Panel Lens — hosts the fullscreen/global modals (the 🪪 IdHatch cluster-identity
     hatch, altitude:88).  Otro + BigWordland mount this; without it the Mundo 🪪 action toggles
      the lens particle but nothing renders it — the popup never shows.  Needed to see/switch which
       cluster Identity this runner is using. -->
{#if H}
    <Lens {H} kind="Panel" />
{/if}

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
    /* the spine shims mount here but never paint — they exist only for their onMount (method deposit).
       display:none still mounts them + fires onMount; it just spares any stray markup a layout. */
    .spine-shims { display: none; }
    /* the top bar — STICKY so it stays put while the sprawl scrolls the document beneath it
       (the glass/diag modes fit the viewport, so nothing scrolls there and sticky is inert) */
    .scape-top {
        position: sticky; top: 0; z-index: 60;
        display: flex; align-items: baseline; gap: 0.8rem; flex-wrap: wrap;
        padding: 0.5rem 1rem;
        background: rgba(5, 6, 11, 0.92); backdrop-filter: blur(4px);
        border-bottom: 1px solid rgba(120, 140, 195, 0.16);
    }
    .scape-name {
        font-size: 0.95rem; letter-spacing: 0.14em; text-transform: uppercase;
        color: #9fb2d8; text-shadow: 0 0 14px rgba(140, 170, 230, 0.4);
    }
    .scape-book { font-size: 0.75rem; color: rgba(150, 170, 205, 0.6); }

    /* the jump toc — chips that scroll to each House's section (sprawl only) */
    .scape-toc { display: flex; align-items: baseline; gap: 0.15rem; flex-wrap: wrap; min-width: 0; }
    .scape-h {
        background: none; border: none; cursor: pointer; font-family: monospace;
        font-size: 0.74rem; color: rgba(150, 170, 205, 0.75);
        padding: 0.1rem 0.45rem; border-radius: 6px;
        margin-left: calc(var(--d) * 0.55rem);   /* H** depth reads as indent */
        transition: color 0.12s, background 0.12s;
    }
    .scape-h:hover  { color: #e4ecff; background: rgba(120, 150, 210, 0.12); }
    .scape-h.active { color: #cfe0ff; background: rgba(120, 150, 210, 0.18); }
    .scape-h.off    { color: rgba(200, 110, 110, 0.6); }
    /* ⚙ beside the active chip — toggles that House's action rack in the row below */
    .scape-cog {
        background: none; border: none; cursor: pointer; font-family: inherit;
        font-size: 0.78rem; line-height: 1; color: rgba(180, 195, 225, 0.55);
        padding: 0.1rem 0.25rem; border-radius: 6px; flex: none;
        transition: color 0.12s, background 0.12s, transform 0.2s;
    }
    .scape-cog:hover { color: #e4ecff; background: rgba(120, 150, 210, 0.14); }
    .scape-cog.on    { color: #cfe0ff; background: rgba(120, 150, 210, 0.18); transform: rotate(40deg); }

    /* the active House's action rack — dropped just under the bar, IN FLOW (not sticky) so its
       height pushes the sprawl down and it scrolls away with the page (BigWordland's .bw-panel) */
    /* the strip — chunky panels of VARYING heights (align-items flex-start lets each size itself:
        the invite panel is one line until a QR blooms it tall) */
    .scape-strip {
        position: relative; z-index: 1;
        display: flex; align-items: flex-start; gap: 0.6rem; flex-wrap: wrap;
        padding: 0.3rem 1rem 0;
    }
    .scape-panel {
        position: relative; z-index: 1;
        display: flex; align-items: center; gap: 0.75rem; flex-wrap: wrap;
        padding: 0.45rem 0.9rem; margin: 0.4rem 1rem 0;
        background: rgba(16, 19, 30, 0.96);
        border: 1px solid rgba(150, 190, 240, 0.25); border-radius: 10px;
    }
    .scape-panel-name { font-size: 0.8rem; color: #cfe0ff; }
    .scape-off { color: #e05a5a; font-size: 0.75em; margin-left: 0.4em; }
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

    /* the gutsy sprawl — every House's UIs stacked down the page.  DOCUMENT-SCROLLED (no inner
       overflow, no min-height:0): the flex item grows to its content, .mound grows past 100vh,
        and the whole page scrolls under the sticky top bar — so the action row (in flow) scrolls
         away with it and the content's top sits flush at the bar's base. */
    .scape-sprawl {
        flex: 1;
        display: flex; flex-direction: column; gap: 1.6rem;
        padding: 1rem;
    }
    /* one House's block — its heading + its UIs; scroll-margin clears the sticky bar on a jump */
    .scape-house { display: flex; flex-direction: column; gap: 1.6rem; scroll-margin-top: 6rem; }
    .scape-house-name {
        font-size: 0.72rem; letter-spacing: 0.1em; text-transform: uppercase;
        color: rgba(150, 170, 205, 0.6); font-family: monospace;
        border-bottom: 1px dashed rgba(120, 140, 195, 0.18); padding-bottom: 0.25rem;
    }
    .scape-house-name.off { color: rgba(200, 110, 110, 0.6); }

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
