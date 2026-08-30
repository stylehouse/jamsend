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
    //   once it draws every OTHER H** UI vanishes.  ▦ toggles a sprawl of EVERY House's
    //    UIs dumped in order down one page (Cyto included) — the gutsy multi-UI interface, twin of
    //     /BigWordland's ▦.  Persisted in the stash (BigSoundland_sprawl) so the choice sticks.
    //  ▦ IS NOT DRAWN FOR A LISTENER (2026-08-10) — it appears only under the `guts` pref, which the
    //   Butler's semi-hidden switch and the `?` key set.  See the `guts` note further down.  Note the
    //      SEPARATE fullscreen gate: BootGate's FaceSucker (disk-share / audio tap) — cleared by GRANTING,
    //       not by ▦; if it's covering the screen, open the folder / tap for sound to get past it.
    import Ghost      from "$lib/O/Ghost.svelte"
    import { keyser } from "$lib/data/Stuff.svelte"
    import BootGate   from "$lib/O/ui/BootGate.svelte"
    import Butler     from "$lib/O/ui/Butler.svelte"
    import Splash     from "$lib/O/ui/Splash.svelte"
    import Actions    from "$lib/O/ui/Actions.svelte"
    import TodoSpool, { spool_open } from "$lib/O/ui/TodoSpool.svelte"
    import Lens       from "$lib/O/ui/Lens.svelte"
    import InvitePanel from "$lib/O/ui/InvitePanel.svelte"
    import SwarmStandup from "$lib/O/ui/SwarmStandup.svelte"
    import SchemeSwitcher from "$lib/O/ui/SchemeSwitcher.svelte"
    import { boot_param } from "$lib/boot"
    import { boot_qualand } from "$lib/O/BigQualand.svelte"

    // the resident Book — the Sounditron (the diagnostic probe this header long promised): it
    //  probes the REAL environment, commissions the glass ITSELF (world-side, not a toc Opt),
    //   and its guts — %Machine/%Relay/%Possibility/%Audio/%Session + the seen|log trail —
    //    ARE the graph the crusher folds.  ?B= overrides (?B=VoroScape for the music demo).
    const book = boot_param('B') || 'Sounditron'

    // THE RENDERER CRITIQUE SURFACE IS THE PLAYER'S ALONE (owner 2026-08-30: "editor|runner tabs have taken
    //  up Cello as well — it needs to be something about BigSoundland… the toplevel with the boot params").
    //   SchemeSwitcher persists its pick in localStorage['cello:renderer'], which is per-ORIGIN, so the
    //    owner flipping the music page to Cello colonised every OTHER tab on :9091 that mounts it — and a
    //     ?B= tab is exactly a dispatch tab (?B=Editron = the editor, ?B=<Book> = a runner), which must show
    //      the world's REAL commissioned glass so a Book verifies against what it actually renders.  So the
    //       switcher (and its persisted Cello) is gated to the genuine end-user player: a plain BigSoundland
    //        with NO ?B= override.  A ?B= boot renders the bare commissioned glass, no critique chrome.
    const critique_surface = !boot_param('B')

    //#region H:Mundo — the shared boot lives in BigQualand now (the aufheben's common bit): this
    //  scape supplies only its knobs — a music Book, the runner role (run it so the graph forms and
    //   crush-folds to glass) — and reads H + houses back.  The OOM trap is baked in over there.
    const q = boot_qualand({ book, role: 'sound' })   // role 'sound' ⇒ Lies%humdinger: an end-user page, never a dispatch target
    let H      = $derived(q.H)
    let houses = $derived(q.houses)
    //#endregion

    // the Cyto UI (Cytui) is registered by the Cyto ghost on whichever House carries the live graph;
    //  find it across H** and mount it full-bleed.  Its ◈ voronoi mode auto-arms on the crushed world.
    //  ?VY=1 — THE FIRST TENANT GATE (the Vyto moult): under the gate the page seats the NEW glass
    //   instead (Vytui, UI:'Vyto', same H prop) and Sounditron_glass commissions Vyto not Cyto; the
    //    ungated page stands exactly as before.
    // The glass — mount whichever the WORLD commissioned, Vyto PREFERRED.  The ?VY=1 URL gate is
    //  RETIRED (2026-07-27): a world chooses its own glass (Sounditron commissions Vyto; another Book
    //   may still commission Cyto) and the page just reflects that choice.  The badge reports which
    //    actually stood.  Vyto wins across ALL houses before any Cyto fallback is taken.
    // is the Butler holding the screen? `H.c.butler_up` is plain `.c` (a per-tab UI fact that must
    //  never reach a snap), so it announces nothing — read it off `H.version`, which bumps constantly
    //   through a boot, exactly as BootGate reads the same flag off its own poll. Its only consumer is
    //    the invite strip below: whoever owns the screen owns the door.
    let butler_up = $derived.by(() => { void H?.version; return !!(H as any)?.c?.butler_up })

    let cyto = $derived.by(() => {
        let fallback
        for (const house of houses) {
            void house.UIs.version
            const vyto = house.UIs.ob({ UI: 'Vyto' })[0]
            if (vyto) return { house, ui: vyto }
            const cy = house.UIs.ob({ UI: 'Cyto' })[0]
            if (cy && !fallback) fallback = { house, ui: cy }
        }
        return fallback
    })

    // ?VY=1 TRACE — when the badge is stuck at "no glass yet", walk for the A:Vyto world the
    //  commission stands and report what REALLY happened, the one thing the badge can't:
    //   • stood  — the A:Vyto>w:Vyto world exists (Sounditron_glass ran its VY block)
    //   • landed — w:Vyto.c.commission is set (e_Vyto_commission actually PROCESSED — the
    //               deferred elvis was pumped; if this stays false the world is off the pump)
    //   • rows   — its error/rebuff/see breadcrumbs (a fired-but-refused commission shows here)
    //  Diagnostic-only ($derived, cheap), and only meaningful under VY.
    let vyto_trace = $derived.by(() => {
        if (cyto?.ui.sc.UI === 'Vyto') return undefined   // Vyto is up — nothing to trace
        for (const house of houses) {
            void house.version
            const a = house.o?.({ A: 'Vyto' })?.[0]
            if (!a) continue
            void a.version
            const vw = a.o?.({ w: 'Vyto' })?.[0]
            if (!vw) return { where: house.name, stood: false, landed: false, rows: [] as string[] }
            void vw.version
            const rows: string[] = []
            for (const key of ['error', 'rebuff', 'see']) {
                for (const r of (vw.o?.({ [key]: 1 }) ?? [])) rows.push(`${key}: ${r.sc[key]}`)
            }
            return { where: house.name, stood: true, landed: !!vw.c?.commission, rows }
        }
        return { where: null, stood: false, landed: false, rows: [] as string[] }
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
    // ── THE GUTS SWITCH — ▦, and it is the ONLY one ────────────────────────────────────────────
    // The owner, 2026-08-10, in two moves.  First: *"we want that button hidden within our app —
    //  that and the Butler-overlay-exiting control should be one and the same"*.  Then, on seeing the
    //   first cut of that: *"lose `show me the guts` and just have ▦ hidden-ish (opacity:0.2) in the
    //    top right corner at all times. z-index above everything!"*
    //  SO THERE IS ONE BUTTON AND ONE STATE.  ▦ lives at `.scape-guts` — fixed, top-right, ALWAYS
    //   rendered, barely visible until you look for it, and above every FaceSucker on the page.  It
    //    is the way out of the arrival screen, the way into the sprawl, and the way back, all at once.
    //     The Butler no longer carries a switch of its own; a second control onto one state is the
    //      `boot_gate` lesson (two doors onto one permission) and it had already produced a "don't
    //       wait for me" that a person could press without ever learning where the machine went.
    //  ALWAYS RENDERED IS THE POINT, not laziness.  Every gated version of this had the same hole: the
    //   button that reverses a state was hidden BY that state, so the only way back was a keyboard
    //    shortcut nobody had been told about.  0.2 opacity costs a listener nothing and costs a
    //     stranded person their whole session.
    //  SPRAWL *IS* GUTS NOW.  `BigSoundland_sprawl` is retired: two persisted booleans meaning
    //   overlapping things ("show the machine" / "show every UI") is how the ▦ ended up on a
    //    listener's page in the first place.  One pref, owned by the model — `Supervisor_pref('guts')`
    //     is a particle + the House stash, so it snaps, survives a reload, and BOTH faces read the
    //      same answer instead of each deriving one and throwing it away at the face boundary.
    //  READ OFF THE STASH, not `Supervisor_pref`: that call MINTS the particle on first read (it
    //   mirrors the stash into the tree), and a `$derived` that mutates is a `$derived` that will one
    //    day loop.  `H.stashed` is reactive `$state` and Housemem burrows straight into it, so this is
    //     the same value by the shorter read-only road — and it works before the Supervisor world
    //      exists at all, which is most of a boot.
    let guts = $derived(!!(H?.stashed as any)?.Supervisor?.guts)
    function toggle_guts() {
        const M = H?.top_House ? H.top_House() : H
        const w = M?.o?.({ A: 'Supervisor' })[0]?.o?.({ w: 'Supervisor' })[0]
        if (!w || !(M as any)?.Supervisor_pref_set) return
        ;(M as any).Supervisor_pref_set(w, 'guts', guts ? 0 : 1)
    }
    let sprawl = $derived(guts)
    // ── THE GLASS IS THE APP (2026-08-09, the owner: "shake out the UI outside of Vyto, ie
    //  fullscreen the latter, with Invite management in there") ────────────────────────────────
    // When the glass is up, the page has NO chrome: no title, no book name, no badge, no strip.
    //  Everything the header used to say is either inside the glass now (identity + invites are
    //   DoorFace's cell) or is developer information that was being shown to every listener.
    //  The chrome does NOT go away, it goes CONDITIONAL: the sprawl and the boot-diagnostic rooms
    //   keep every bit of it, because those are the rooms you enter when something is wrong and
    //    they are worth nothing without their labels.  `.scape-peek` (and ? ) are the way back.
    let glass_full = $derived(!!cyto && !sprawl)
    // RADIO BEGINNING — the splash holds until BOTH the glass is up AND the Butler has lifted (owner 2026-08-29:
    //  "it should stretch all the way to the Radio beginning").  While the Butler is still holding (butler_up) the
    //   splash stays OVER it, so the owner never watches "the Supervisor get ready".  OPEN SHARE no longer fades the
    //    splash — it's layered above it (BootGate altitude 2100).
    let boot_ready = $derived(glass_full && !butler_up)
    // BOOT GAVE UP — the ONE thing that still fades the splash at once: the boot failed, so reveal the Butler's
    //  failure/▦ exit rather than sit behind a calm tree.  Reads the toplevel authority; false on a Book.
    let boot_gaveup = $derived.by(() => { void H?.version; let s: any = (H as any)?.top_House?.()?.c?.screen; if (!s) return false; return s.dominant === 'gaveup' })
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
    // the sticky top bar's LIVE height (it flex-wraps, so no fixed rem is honest) — the per-House
    //  sprawl headers stick just under it (their `top:`), so the tools stay on screen all the way
    //   down a big House's UIs (owner 2026-08-30: "fixed at the top of the viewport").
    let bar_h = $state(0)
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
    // ── THE TWO RADIO KEYS (the owner 2026-08-07: "the space key should go the next track, and enter
    //  key should heist") — page-level, because this is a RADIO: your hands are not on a particular
    //   widget, and hunting for the ⏭ button is the thing the keys exist to remove.
    //  NEVER STEAL A TYPED KEY.  Space is the single most-typed character there is, and this page
    //   carries real text fields (invite paste, friend rename, heist category + directories).  So we
    //    bail on any editable target — input, textarea, select, or anything contenteditable — and on
    //     a modified press (⌘/ctrl/alt), which belongs to the browser.  Without that guard "rename
    //      Lefto" would skip a track per word and never insert a space.
    //  preventDefault ONLY once we have decided to act: space would otherwise scroll the page.
    const radio_of = (h: any) => { const rw = h?.top_House?.()?.c?.radio_w; return rw?.o?.({ Radio: 1 })?.[0] ?? null }
    function radio_key(e: KeyboardEvent) {
        if (e.metaKey || e.ctrlKey || e.altKey) return
        const t = e.target as HTMLElement | null
        const tag = t?.tagName
        if (t?.isContentEditable || tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT') return
        // ? — THE WAY IN AND OUT OF THE MACHINE.  It used to toggle the sprawl; it now toggles the
        //  GUTS switch, because that is the one that can leave you with nothing to press: ▦ is drawn
        //   only while the guts are on, so with no keyboard route a listener who never presses "show
        //    me the guts" has no door at all and somebody who does has no way back.  Same guard as the
        //     radio keys above (never steal a typed key), and it works from either side.
        //  ▦ still toggles the sprawl.  Two different questions — "do I want the machine" and "which
        //   machine face" — and collapsing them would cost the glass its own escape hatch.
        if (e.key === '?') { e.preventDefault(); toggle_guts(); return }
        if (e.key !== ' ' && e.key !== 'Enter') return
        const A: any = H
        const n = radio_of(A)
        if (!n) return
        e.preventDefault()
        // through post_do like every other UI verb, so the write rides the House mutex rather than
        //  racing the pump — the same discipline HeistFace/RadioFace already use.
        if (e.key === ' ') A?.post_do?.(() => { A?.Radio_skip?.(n) }, { see: 'radio skip (space)' })
        else A?.post_do?.(() => { A?.Radio_heist_now?.(n) }, { see: 'radio heist (enter)' })
    }
</script>

<svelte:window onkeydown={radio_key} />

<!-- the boot splash (tree.webp) — the calm cover over the WHOLE multi-phase boot (Butler/Supervisor warmup lives
     behind it), pointer-CATCHING (no fall-through into the machine room), holding until the Radio beginning (glass
     up + Butler lifted) or a boot gave-up, or a safety cap.  OPEN SHARE punches through it (BootGate, above).  Splash. -->
<Splash ready={boot_ready} urge={boot_gaveup} />

<BootGate {H} who="the piracy-scape" audio_fullscreen={true} proactive={true} />
<!-- the Butler: the Supervisor's arrival screen, altitude 55 — UNDER BootGate, because a permission
     the listener has to grant outranks news about work in progress.  It lifts on ARRIVAL and on
      nothing else automatic (`Supervisor_arrived`, declared by this page's Book in beat 2 and met when
       the glass is drawing and music is playing); otherwise a person leaves via the ▦ guts switch
        below, which is why that button is drawn unconditionally and above this FaceSucker — since
         2026-08-10 the Butler has no dismiss tap of its own, so ▦ is the ONLY way off that card and
          removing it from any room would strand a listener on a boot screen.  It latches down for the
           tab, so it can never reappear over somebody's music.
         Mounted beside BootGate rather than inside the view switch for the spine_shims reason: a
          persisted `sprawl` must not be able to starve it. -->
<Butler {H} />
<!-- (the device-link ceremony is a BELLY CELL again — owner 2026-08-29 "I want a Cell" — not a FaceSucker.  The
     old LinkSurface overlay was removed; Sounditron_commission surfaces %Link in the belly, warmth-gated by
     Swarm_link_fresh so a dead/declined ceremony can't seize it.  No overlay mounts here anymore.) -->

<!-- ▦ THE ONE CONTROL, and the only piece of chrome on this page that is ALWAYS on screen (the owner
     2026-08-10: *"just have ▦ hidden-ish (opacity:0.2) in the top right corner at all times. z-index
      above everything!"*).  It toggles `guts` — the arrival screen off and every House's UIs on, or
       back.  Deliberately OUTSIDE `<main>`: it must survive the glass/diag/sprawl view switch, and it
        must be over the FaceSuckers rather than under them, because the state it reverses is the one
         that covers the screen.  A button hidden by the thing it undoes is not a way out. -->
<button class="scape-guts" class:on={guts} onclick={toggle_guts}
        title={guts
            ? 'the guts: every House’s UIs, no arrival screen — click (or ?) to go back to the music'
            : 'the guts — every House’s UIs down one page, and no arrival screen (? does the same)'}
        aria-label="show the machine">▦</button>

<main class="mound" class:full={glass_full}>
    {#if glass_full}
        <!-- THE PEEK IS GONE, AND WITH IT THE LAST CHROME ON THE RESIDENT GLASS (2026-08-11, the
             owner: *"`◇ VYTO` <- time to get rid of this pointless thing too"*).  The badge existed
              to answer "which stained glass actually mounted" back when ?VY=1 was a coin-toss between
               two look-alike voronoi glasses — a question that stopped existing when the flag was
                retired and every tab got a commissioned Vyto.  It had already outlived its ▦, which
                 moved to the fixed `.scape-guts` corner button; removing the badge empties the peek
                  entirely, so the <nav> goes with it rather than lingering as a hover target for
                   nothing.  The page is now the glass and NOTHING else, which is the whole point.
             STILL THERE WHERE IT EARNS ITS PLACE: the sprawl/diagnostic header below keeps the badge
              (and its `no glass yet` case, which is the first thing you read when the glass never
               stood up).  That is the room you enter when something is wrong, and it is worth
                nothing without its labels — `?` / ▦ is the way in. -->
    {:else}
    <header class="scape-top" bind:clientHeight={bar_h}>
        <span class="scape-name" title="BigSoundland — the music scape: Voronoi stained glass graphs of music (the /BigSoundland route)">◈ BigSoundland</span>
        <span class="scape-book">{book}</span>
        <!-- WHICH GLASS is actually mounted — the definitive VYTO/CYTO tell.  Under ?VY=1 the page
             seats UI:'Vyto' instead of Cyto; both draw voronoi cells and look alike, so without this
              badge "is it Vyto?" is a guess.  It reports what REALLY rendered: the mounted component's
               own UI key, or (when VY is asked but nothing seated) that the Vyto glass hasn't stood up. -->
        {#if cyto}
            <span class="scape-glass-badge" class:vy={cyto.ui.sc.UI === 'Vyto'}
                  title="the glass component mounted full-bleed below (its House: {cyto.house?.name})">{cyto.ui.sc.UI === 'Vyto' ? '◇ VYTO' : '◈ CYTO'}</span>
        {:else}
            <span class="scape-glass-badge waiting"
                  title="no glass has registered yet — the world hasn't commissioned one (Sounditron commissions Vyto).  The diagnostic below shows the boot state.">◇ no glass yet</span>
        {/if}
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
        <!-- ▦ moved out of the header — see `.scape-guts` below -->
    </header>
    {/if}

    <!-- the strip — the Invite front door (Swarm_spec §10.1), on the NON-GLASS rooms only.
         It has moved into the glass as DoorFace's invite door (2026-08-09), but it must stay
          here too, and this is not duplication for its own sake: someone who opens a scanned
           ?Iz link lands on this page BEFORE any world has commissioned a glass, and the boot
            diagnostic is the room they are standing in.  If the only join button lived in a
             cell, the entire invite funnel would depend on a successful boot — exactly the
              thing an invite is most likely to be arriving in the middle of. -->
    <!-- …AND EXACTLY ONE OF THEM MAY BE LIVE AT A TIME (2026-08-10).  The Butler now mounts this same
         panel while it holds the screen — it had to, because an arrival screen that waits for the glass
          covers this strip, and hiding the join door behind news about a booting machine is the funnel
           failing at the one moment it matters.  But TWO mounted instances both auto-join a scan
            landing (`landed_url && !auto_fired`, latched per instance), and a single-use ?Iz redeemed
             twice comes back a rebuff — the invite refusing itself.  So the strip stands down while the
              Butler is up, the same `butler_up` handshake BootGate already makes. -->
    {#if H && !glass_full && !butler_up}
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
                    <!-- the House's TOOL BAR — sticky just under the top bar, so its actions + the
                         elvis spool stay on screen all the way down a big House's UIs (owner
                         2026-08-30: "slap the ActionButtons on the end of every H heading by
                         default … fixed at the top of the viewport … only in show-guts mode" —
                         and this whole section IS guts mode).  Retires the navibar-⚙-opens-miles-
                         away dance for the sprawl.  TodoSpool is the flood-tracer: histogram of
                         queued elvises + the beliefs-mutex wedge line. -->
                    <div class="scape-house-hd" class:lifted={spool_open.ip === house.c.ip} style="top: {bar_h}px;">
                        <span class="scape-house-name" class:off={!house.started}>{house.name}</span>
                        <TodoSpool {house} {H} />
                        {#if house.actions.ob({ action: 1 }).length}
                            <div class="scape-house-acts"><Actions N={house.actions.ob({ action: 1 })} /></div>
                        {/if}
                    </div>
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
                <!-- SchemeSwitcher wraps the live glass (owner's temporary critique surface): opens on the REAL
                     selected renderer (`vyto` = cyto.ui.sc.component, correct house), a bar flips the SAME live
                     House through every C** renderer.  Revert to the bare <svelte:component> to drop it.
                     GATED to the player (critique_surface): a ?B= editor|runner tab renders the world's bare
                     commissioned glass, so its persisted localStorage Cello pick can't colonise dispatch tabs. -->
                {#if critique_surface}
                    <SchemeSwitcher H={cyto.house} vyto={cyto.ui.sc.component} />
                {:else}
                    {@const Glass = cyto.ui.sc.component}
                    <Glass H={cyto.house} />
                {/if}
            </section>
        {/key}
    {:else}
        <!-- the glass isn't drawing — show what the machine is doing so we can scan out what's wrong -->
        <section class="scape-diag">
            <div class="diag-line">
                <span class="diag-dot" class:on={boot_state.story_stood}></span>
                {#if boot_state.story_stood}
                    the run stood up — waiting for the world to commission its glass.  Sounditron
                     commissions <b>Vyto</b> on its organs (Radio · Stoker · Tuner · Door · Zine ·
                      Riffle …); if this persists the commission didn't seat a <code>UI:'Vyto'</code> —
                       the trace below says where it's stuck.
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
            <!-- the VY commission trace — pins WHERE the Vyto glass is stuck (see vyto_trace) -->
            {#if vyto_trace}
                <div class="vyto-trace">
                    <span class="vt-flag" class:ok={vyto_trace.stood}>{vyto_trace.stood ? '✓' : '✗'} A:Vyto world stood{#if vyto_trace.where} · under {vyto_trace.where}{/if}</span>
                    <span class="vt-flag" class:ok={vyto_trace.landed}>{vyto_trace.landed ? '✓' : '✗'} e_Vyto_commission processed (commission set)</span>
                    {#each vyto_trace.rows as row}
                        <span class="vt-row">{row}</span>
                    {/each}
                    {#if vyto_trace.stood && !vyto_trace.landed}
                        <span class="vt-row hint">world stood but commission never processed — the A:Vyto world is off the think pump (c.up / deferred-elvis race)</span>
                    {/if}
                </div>
            {/if}
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
        <!-- the swarm standup: self → station → share → boast.  Rides here for the SAME reason the
             spine shims do — it renders nothing, and its absence is invisible until a friend's scan
              times out.  It used to be carried by the strip's InvitePanel, which stopped being
               unconditional the moment invite management moved into a cell. -->
        <SwarmStandup {H} />
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

    /* THE RESIDENT GLASS — the page IS the glass: exactly the viewport, nothing above it, nothing
       to scroll.  (The other rooms keep .mound's min-height:100vh and document scrolling.) */
    .mound.full { height: 100vh; min-height: 0; overflow: hidden; }

    /* (.scape-peek went with the ◇ VYTO badge it existed to hold — 2026-08-11.  Nothing is fixed over
       the resident glass now except `.scape-guts`, the ▦ way out.) */
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

    /* the glass badge — which stained glass actually mounted.  Cyto (◈, cool blue) is the standing
       default; Vyto (◇, warm amber) is the moult — deliberately a DIFFERENT hue + glyph so the two
        voronoi glasses are never confused at a glance.  `.waiting` = VY asked, nothing seated yet. */
    .scape-glass-badge {
        font-size: 0.72rem; letter-spacing: 0.12em; font-family: monospace;
        padding: 0.08rem 0.5rem; border-radius: 999px;
        color: #bcd0f2; border: 1px solid rgba(150, 190, 240, 0.45);
        background: rgba(120, 150, 210, 0.12);
    }
    .scape-glass-badge.vy {
        color: #ffd9a0; border-color: rgba(240, 190, 120, 0.6);
        background: rgba(210, 160, 90, 0.16);
        box-shadow: 0 0 12px rgba(230, 180, 110, 0.35);
    }
    .scape-glass-badge.waiting {
        color: rgba(240, 200, 150, 0.75); border-color: rgba(240, 190, 120, 0.35);
        background: none; border-style: dashed;
    }

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
    /* ▦ THE ONE CONTROL — fixed top-right, on screen in every room, over every FaceSucker.
       z-index: FaceSucker computes `altitude * 1000`, so BootGate (77) sits at 77000 and the Butler
        (55) at 55000.  999999 is not a magic number picked for luck: it is "above anything that
         hoists itself", and the reason it has to be is that this button's whole job is to reverse a
          fullscreen state.  Under them it would be invisible exactly when it is needed.
       0.2 at rest, full on hover/focus.  A listener never notices it; anyone looking for a way out
        finds it in the corner every app puts one in.  `-webkit-tap-highlight` and a fat padding keep
         it pressable on a phone where 0.2 opacity is easy to miss but a corner is easy to hit. */
    .scape-guts {
        position: fixed; top: 0; right: 0; z-index: 999999;
        opacity: 0.2;
        background: none; border: none; border-radius: 6px;
        cursor: pointer; font-family: inherit; font-size: 1rem; line-height: 1;
        color: #cfe0ff; padding: 0.5rem 0.6rem;
        -webkit-tap-highlight-color: transparent;
        transition: opacity 0.15s ease, background 0.15s ease;
    }
    .scape-guts:hover, .scape-guts:focus-visible { opacity: 1; background: rgba(120, 150, 210, 0.18); }
    .scape-guts.on { opacity: 0.85; background: rgba(120, 150, 210, 0.16); }
    @media (prefers-reduced-motion: reduce) { .scape-guts { transition: none; } }
    /* (.scape-sprawl-btn is gone — there were two ▦s in two rooms and now there is one, fixed.) */
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
    /* the House TOOL BAR — sticky under the measured top bar (inline `top:`), so name + spool +
       actions ride the viewport across the whole section.  position:sticky is also the positioned
       anchor the spool's absolute .todo-pop hangs off.  Opaque-ish backdrop: UIs scroll UNDER it. */
    .scape-house-hd {
        position: sticky; z-index: 40;
        display: flex; align-items: center; gap: 0.6rem;
        background: rgba(8, 10, 16, 0.92); backdrop-filter: blur(4px);
        border-bottom: 1px dashed rgba(120, 140, 195, 0.18); padding: 0.15rem 0.2rem 0.25rem;
    }
    /* a spool popover must clear the SIBLING sticky bars below (equal z, later DOM wins) */
    .scape-house-hd.lifted { z-index: 55; }
    .scape-house-acts { margin-left: auto; display: flex; min-width: 0; }
    .scape-house-name {
        font-size: 0.72rem; letter-spacing: 0.1em; text-transform: uppercase;
        color: rgba(150, 170, 205, 0.6); font-family: monospace;
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

    /* the VY commission trace — a small ledger of where the Vyto glass got stuck */
    .vyto-trace {
        display: flex; flex-direction: column; gap: 0.2rem;
        padding: 0.5rem 0.7rem; border-radius: 8px;
        background: rgba(210, 160, 90, 0.07); border: 1px solid rgba(230, 180, 110, 0.22);
        font-family: monospace; font-size: 0.72rem;
    }
    .vt-flag { color: rgba(230, 150, 120, 0.85); }
    .vt-flag.ok { color: #8fd6a2; }
    .vt-row { color: rgba(200, 210, 230, 0.7); padding-left: 0.9rem; }
    .vt-row.hint { color: rgba(240, 200, 150, 0.8); font-style: italic; }
    .diag-ui { position: relative; padding-top: 1.1rem; }
    .diag-tag {
        position: absolute; top: 0; left: 0.15rem;
        font-size: 0.62rem; letter-spacing: 0.08em; color: rgba(120, 135, 170, 0.55);
        user-select: none; pointer-events: none;
    }
</style>
