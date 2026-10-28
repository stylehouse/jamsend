<script lang="ts">
    // BigWordland — a second toplevel, rivaling Otro.  The SAME machine underneath (Ghost
    //  mounts every ghost; an editor Book boots exactly as under Otro) presented as a BIG
    //   EMPTY ROOM instead of Otro's NaviScroll column:
    //    · ?H=<Book> parametrises which Book boots, DEFAULTING to Hackarium — the code-wandering
    //      recipe beside this file (L/Hackarium.svelte), which stands Atlas + Lagoon itself.  The
    //      room's role is 'hacker': the editor's local surface (docks, Lang, Langui) with NONE of
    //      its singular duties, so it is safe to open beside a working editor.  ?E=<Book> still
    //      boots the old EDITOR room, which takes the one editor slot and will evict one elsewhere.
    //      No ?B/?I here: runners board through /Otro; this room is author chrome.
    //    · a toc of H** across the top — Mundo · Story · Hackarium (the Run named after the
    //      book) · … — each a chip.  This is a SWITCHER, not a spread: clicking a chip makes
    //       that House the ONE fullscreen view (the show-one-thing policy).  Opens on the booted
    //        Book's Run (⇒ Langui, and the Lagoon panel); click Story to watch the runner, Mundo
    //         for the root.  The fullscreen-er presentation is why the hacker Book moved in here.
    //    · a ⚙ cog rides beside the ACTIVE chip only; it toggles that House's action-button
    //       rack (+ the C** dump) — the buttons stay hidden until you ask, so the room is calm.
    //    · ONE House's UIs at a time, fullscreen — except UI:Lies, which stays hidden even in
    //       its own view until called up (the ⌐Lies chip), and UI:Pantheate-include (the
    //        editor-compile artifact), suppressed until it sprouts from a real run.
    //    · a ▦ toggle escapes back to the ORIGINAL view — the sprawl: EVERY House's UIs dumped
    //       in order down one page (Lies rides too).  The choice lives in the stash, so it sticks.
    //    · the universal searchbar rides the top bar; a hit can be PINNED into the loose
    //      space at the right of the code — the pin rail.  (Folding pins into the
    //      DocMinimap proper is the natural next hop; the rail IS that space for now.)
    //   L/ is this room's home — a big empty space, yet Lies+Lang in disguise.
    import Ghost      from "$lib/O/Ghost.svelte"
    import { House }  from "$lib/O/Housing.svelte"
    import { keyser } from "$lib/Stuff.svelte"
    import Actions    from "$lib/O/ui/Actions.svelte"
    import Lens       from "$lib/O/ui/Lens.svelte"
    import Stuffing   from "$lib/data/Stuffing.svelte"
    import Searchbar  from "$lib/O/ui/Searchbar.svelte"
    import BootGate   from "$lib/O/ui/BootGate.svelte"
    import TodoSpool  from "$lib/O/ui/TodoSpool.svelte"
    import { boot_param } from "$lib/boot"
    import { boot_qualand } from "$lib/O/BigQualand.svelte"

    //#region H:Mundo — the shared boot (the aufheben's common bit) lives in BigQualand now; this
    //  room supplies only its knobs — the editor Book, the editor role — and reads H + houses back.
    //  The OOM trap (assign H once, never read it in the construction effect) is baked in over there.
    // ── 2026-09-08: THE ROOM IS A HACKER ROOM NOW ────────────────────────────────────────────────
    //  The owner, having opened /Otro?H=Hackarium and clicked a stem: *"it needs a fullscreen-er
    //   presentation… BigWordland was it I think?  nothing else is happening with BW, we should probably
    //    take this all there… they are very similar right?  unity a cleanse."*  They are: this room and
    //     that tab both boot a Book and render `H.UIs`.  What this room has and that tab lacks is the
    //      PRESENTATION — the H** switcher that makes one House fullscreen, the ▦ sprawl, the pin rail,
    //       the searchbar.  So the room takes the Book rather than the Book growing a room.
    //  What changes: default Book `Educarium` → `Hackarium`, and role `word` → `hacker`.  The room stops
    //   being "an editor room that is a humdinger" (which is why the L ghosts could never live here —
    //    `ghost_load` is refused on a humdinger) and becomes a room that STANDS ITS OWN LAND: Hackarium
    //     loads Atlas + Lagoon itself, so nothing needs the CLI or the relay.
    //  ?E=<Book> still boots the OLD editor behaviour for anyone who explicitly asks — but note it takes
    //   the single editor slot (`LiesFunk` ~:499, the Cluster claim supersedes every other editor row),
    //    so it will EVICT a working editor elsewhere.  The hacker default cannot.
    const editor_book = boot_param('E')
    const hacker_book = boot_param('H') || 'Hackarium'
    const q = editor_book
        ? boot_qualand({ book: editor_book, role: 'word' })     // explicit ?E= — the old editor room; takes the editor slot
        : boot_qualand({ book: hacker_book, role: 'hacker' })   // the default — docks without the duties
    // the Book actually booted, whichever road got us here — the switcher opens on its Run House
    const the_book = editor_book || hacker_book
    let H      = $derived(q.H)
    // window.__H — the live-state probe runner_eye --eval reads (same as BigShapeland:77)
    $effect(() => { if (H && typeof window !== 'undefined') (window as any).__H = H })
    let houses = $derived(q.houses)
    //#endregion

    //#region the room's own state
    // the fullscreen switcher.  `view` is the user's explicit pick (a House ip); undefined means
    //  "auto", which resolves to the booted Book's Run (opens on Langui + Lagoon) or, before it
    //   stands up, the deepest House so the boot is visible.  `active` is the House shown.
    let view = $state<string | undefined>(undefined)
    let active_ip = $derived(
        view
        ?? houses.find(h => h.name === the_book)?.c.ip
        ?? houses[houses.length - 1]?.c.ip
    )
    let active = $derived(houses.find(h => h.c.ip === active_ip))

    // THE WRITE SEAT (LiesLang_todo §11) — the room's w:Lies says whether this tab writes: %Seat:editor,held, or by:<who>.
    //  No answer yet (or no relay) → no badge.  Clicking "reads" wrests it — a deliberate act, which is what may wrest.
    let run_house = $derived(houses.find(h => h.name === the_book))
    let lies_w = $derived.by(() => { void run_house?.version; return (run_house as any)?.o({ A: 'Lies' })[0]?.o({ w: 'Lies' })[0] as any })
    let seat = $derived.by(() => { void lies_w?.version; const st = lies_w?.o({ Seat: 'editor' })[0] as any; void st?.version; return st ? { held: !!st.sc.held, by: st.sc.by as string | undefined, unproven: !!st.sc.unproven } : undefined })
    function wrest_seat() { if (lies_w && run_house) (run_house as any).Lies_seat_ask(lies_w, true, 'the seat badge, clicked') }

    // sprawl — the escape hatch back to the ORIGINAL view: every House's UIs dumped in
    //  order down one gutsy page, no switcher filter.  A workspace choice, so it lives in
    //   the stash (reactive $state on the House, like showC) and survives a reload; the ▦
    //    button in the top bar toggles it.  1-or-absent, matching toggle_C.
    let sprawl = $derived(!!H?.stashed?.BigWordland_sprawl)
    function toggle_sprawl() {
        if (!H?.stashed) return
        if (H.stashed.BigWordland_sprawl) delete H.stashed.BigWordland_sprawl
        else H.stashed.BigWordland_sprawl = 1
    }

    // the action-button rack hides until the ⚙ cog beside the active chip asks for it
    let show_actions = $state(false)

    function depth_of(house: House): number {
        return (((house as any).c?.ip as string | undefined)?.split('_').length ?? 1) - 1
    }
    function toggle_C(house: any) {                        // Otro's lean-stashed C** toggle
        if (house.stashed.showC) delete house.stashed.showC
        else house.stashed.showC = 1
    }

    // Lies hides unless called up — then it renders all straight as it has been
    let show_lies = $state(false)

    // UI:Pantheate-include is an editor-compile artifact (LiesCortex notifies Pantheate on every
    //  compile, so a 2-dock Waft mounts two): suppressed everywhere until it sprouts from a real
    //   %rungo run.  Lies is handled separately (show_lies).  Nothing else is hidden — Story/Cyto
    //    are simply on other Houses, so the show-one-thing view already leaves them off unless you
    //     switch to the House that owns them.
    // THE SPINE MUST MOUNT EVEN THOUGH IT IS HIDDEN (2026-09-17).  Peeroleum/Tribunal .go are Pantheate
    //  includes whose onMount eatfunc deposits Socket_real on the House — the channel's carrier.  This
    //   room hid every include, so a hacker room could never stand a socket ("no channel") and could not
    //    hear the dev server's docindex push.  They render nothing visible; mount them in a hidden block
    //     OUTSIDE the show-one-House view (below), for every House, whichever is fullscreen.
    const SPINE = /(^|\/)(pinned_stable|gen\/N)\/(Peeroleum|Tribunal)\.go$/
    function spine_ui(uiC: any): boolean { return uiC.sc.UI === 'Pantheate-include' && SPINE.test(String(uiC.sc.gen_path ?? '')) }
    function ui_hidden(kind: string): boolean {
        if (kind === 'Pantheate-include') return true
        // Lies stays folded unless summoned — but the sprawl dumps everything, so it rides too
        if (kind === 'Lies') return !(show_lies || sprawl)
        return false
    }

    // the Lies House + w for the searchbar (and pin deliveries): whichever House's ave
    //  carries %examining — the same seam Liesui reads
    let lies = $derived.by(() => {
        for (const house of houses) {
            void house.ave.version
            const ex = house.ave.ob({ examining: 1 })[0]
            const lw = ex?.c?.w
            if (lw) return { house, w: lw }
        }
        return undefined
    })

    // the pin rail — search hits kept in the loose space at the right of the code.  Session
    //  UI state only (never a particle); a pin click re-fires the same Aside-recorded
    //   delivery the searchbar makes, so a pin is a delivery you keep.
    let pins = $state<any[]>([])
    const pin_key = (h: any) => `${h.glyph}·${h.path}·${h.name ?? ''}·${h.line ?? ''}`
    const pin = (h: any) => { if (!pins.some(p => pin_key(p) === pin_key(h))) pins = [...pins, h] }
    const unpin = (p: any) => pins = pins.filter(x => x !== p)
    const goto_pin = (p: any) =>
        lies?.house.i_elvisto('Lies/Lies', 'Lies_ghost_pick', { path: p.path, point: p.point })
    function tail(path: string): string {
        const segs = (path ?? '').split('/').filter(Boolean)
        return segs[segs.length - 1] ?? path
    }

    // THE CAVE (2026-09-25; re-cut 2026-10-03; ONE VISUAL 2026-10-03; CLEANSED 2026-10-12) — search, worn as a creature,
    //  over the code (Lagoon.g THE CAVE).  The owner: *"that thing has to be on screen AT ALL TIMES if it's going to exist…
    //   it has to be The One Thing"* — so it is stood at boot and never hides: REST (the families) and a search fill the
    //    room; a method or a flat file folds it to a left RAIL so the landed code comes through beside it.
    //  THE HOLE IS A PLAIN INPUT, OURS (2026-10-12, the owner: *"whatever this input field is made of, it's the wrong
    //   stuff"*).  It used to be a box drawn inside the glass's SVG, rebuilt on every sowing, and focus, caret and scroll
    //    were all carried across those rebuilds by four separate contrivances.  This one is never rebuilt, so it keeps
    //     its focus and caret by being a normal input.  It calls the cave's two doors: Lagoon_cave_type (debounced there)
    //      and Lagoon_cave_command (Enter).  Escape reaches the head's press through Vytui's window key (climbs a step).
    //  The producer tells the room three things through `cave_on`: LAND (show this code — `Lies_ghost_pick`), LEAVE (the
    //   head pressed at the surface — back to rest) and MODE (rest|full|rail).
    let cave_open = $state(false)
    let cave_mode = $state('full')
    let dismiss   = $state(0)
    let vyto_ready = $state(false)
    let hole: HTMLInputElement | undefined = $state()
    // the rail's width — dragged at its right edge, remembered per viewer (a convenience: lost storage = the CSS default)
    const RAIL_KEY = 'bw-rail-w'
    let rail_w: number | null = $state((() => { try { const v = Number(localStorage.getItem(RAIL_KEY)); return v > 0 ? v : null } catch { return null } })())
    function rail_grip(e: PointerEvent) {
        const grip = e.currentTarget as HTMLElement
        grip.setPointerCapture(e.pointerId)
        const move = (m: PointerEvent) => { rail_w = Math.round(Math.max(180, Math.min(window.innerWidth * 0.6, m.clientX))) }
        const up = () => {
            grip.removeEventListener('pointermove', move); grip.removeEventListener('pointerup', up)
            try { if (rail_w) localStorage.setItem(RAIL_KEY, String(rail_w)) } catch {}
        }
        grip.addEventListener('pointermove', move); grip.addEventListener('pointerup', up)
        e.preventDefault()
    }
    function rail_reset() {
        rail_w = null
        try { localStorage.removeItem(RAIL_KEY) } catch {}
    }
    const lagoon_w = () => (H as any)?.o({ A: 'Lagoon' })[0]?.o({ w: 'Lagoon' })[0]
    function cave_on(ev: string, a: any) {
        if (ev === 'land' && a?.path) {
            // the code lands in the glass's own room — show that House so the code comes through beside the rail
            if (glass_house) view = (glass_house as any).c.ip
            lies?.house.i_elvisto('Lies/Lies', 'Lies_ghost_pick', a.point ? { path: a.path, point: a.point } : { path: a.path })
            if (a.leave) rest_cave()
        }
        if (ev === 'leave') rest_cave()
        if (ev === 'seek') focus_hole()
        if (ev === 'mode') cave_mode = a === 'rail' ? 'rail' : 'full'
    }
    function rest_cave() {
        if (hole) hole.value = ''
        H?.i_elvisto('Lagoon/Lagoon', 'Lagoon_cave', { open: 1 })
    }
    // the hand into the hole (the chip, the head, `/`).  Over the overlay no scrolling — the glass is a fixed layer, the
    //  input sits at its top.  In the sprawl the box rides the Vyto piece down the page, and the hand ASKED for it, so the
    //   page brings it on screen (only on this deliberate seek — nothing periodic ever focuses it)
    function focus_hole() {
        if (!cave_open) open_cave()
        hole?.focus({ preventScroll: true })
        hole?.select()
        if (sprawl) hole?.scrollIntoView({ block: 'center' })
    }
    function open_cave() {
        if (!H) return
        const lw = lagoon_w()
        if (lw) lw.c.cave_on = cave_on
        cave_open = true
        lies?.house.i_elvisto('Lies/Lies', 'Lies_stemdex_scan', {})
        H.i_elvisto('Lagoon/Lagoon', 'Lagoon_cave', { open: 1 })
    }
    function hole_input() {
        const lw = lagoon_w()
        if (lw && hole) (H as any).Lagoon_cave_type(lw, hole.value)
    }
    function hole_key(ev: KeyboardEvent) {
        const lw = lagoon_w()
        if (ev.key === 'Enter' && lw && hole) (H as any).Lagoon_cave_command(lw, hole.value)
    }
    // ONE CLOCK for the cave (was five: a glass-loaded poll, a stand-it poll, the Stemdex nudge, the watch refresh and a
    //  key-steering hook).  Twice a second: stand the cave once the room can; while it is up, show a watched creation
    //   live (the sowing's signature skips beats where nothing moved); every third beat feed the Stemdex while its small
    //    roster converges, re-asking the cave ONLY when it read something new; and keep the box agreeing with the cave
    //     when the hand is elsewhere (a family pressed at rest sets the query).
    $effect(() => {
        let beat = 0
        let seen_done = -1
        const t = setInterval(() => {
            beat++
            if (!vyto_ready && typeof (H as any)?.Vyto_guise === 'function') vyto_ready = true
            const lw = lagoon_w()
            if (!cave_open) {
                if (vyto_ready && lies && lw) open_cave()
                return
            }
            const st = (lw?.c.cave || []) as any[]
            if (st[0]?.lvl === 'watch' || st[st.length - 1]?.lvl === 'watch') H?.i_elvisto('Lagoon/Lagoon', 'Lagoon_cave', { refresh: 1 })
            if (hole && document.activeElement !== hole && !lw?.c.cave_typing && st[0]?.lvl === 'search') {
                const q = String(st[0].q ?? '')
                if (hole.value.trim() !== q && q.length) hole.value = q
            }
            if (beat % 3) return
            const dex = (lies?.w as any)?.c?.stemdex
            const converged = !!(dex && dex.total > 0 && dex.done >= dex.total)
            if (!converged && !dex?.scanning) lies?.house.i_elvisto('Lies/Lies', 'Lies_stemdex_scan', {})
            const fresh = !converged && dex && dex.done !== seen_done
            if (fresh) seen_done = dex.done
            // at rest with no families yet: Atlas is still mapping — look again
            const empty_rest = lw && lw.c.cave_browse_n === 0 && st[0]?.q === ''
            if (fresh || empty_rest) H?.i_elvisto('Lagoon/Lagoon', 'Lagoon_cave', { refresh: 1 })
        }, 500)
        return () => clearInterval(t)
    })
    // the fallback Searchbar (no glass on this tab) still drives the cave's old door
    function on_results(r: any) {
        const q = r?.q ? String(r.q) : ''
        if (!H || !q) return
        const lw = lagoon_w()
        if (lw) lw.c.cave_on = cave_on
        H.i_elvisto('Lagoon/Lagoon', 'Lagoon_cave', { q, r })
    }
    // '/' opens the hole from anywhere that is not already typing (capture phase, à la the Searchbar)
    $effect(() => {
        if (!vyto_ready) return
        const grab = (ev: KeyboardEvent) => {
            if (ev.key !== '/' || ev.ctrlKey || ev.metaKey || ev.altKey) return
            const t = ev.target as HTMLElement | null
            if (t && (t.tagName === 'INPUT' || t.tagName === 'TEXTAREA' || t.isContentEditable)) return
            ev.preventDefault()
            focus_hole()
        }
        window.addEventListener('keydown', grab, true)
        return () => window.removeEventListener('keydown', grab, true)
    })
    // the House that holds the glass (the cave stands A:Vyto on the room's Run House).  It is drawn from THERE as its
    //  own layer, whichever House the switcher shows — "on screen AT ALL TIMES" cannot depend on which chip is lit.
    let glass_house = $derived.by(() => {
        for (const h of houses) { void (h as any).UIs?.version; if ((h as any).UIs?.ob({ UI: 'Vyto' })[0]) return h }
        return undefined
    })
    let glass_ui = $derived.by(() => { void (glass_house as any)?.UIs?.version; return (glass_house as any)?.UIs?.ob({ UI: 'Vyto' })[0] })
    let has_glass = $derived(!!glass_ui)
    let cave_up = $derived(cave_open && has_glass)
    const is_glass = (uiC: any) => uiC.sc.UI === 'Vyto' && !sprawl
    //#endregion
</script>

<!-- the shared boot gate; audio begs fullscreen here — the Brink (its usual home) lives
     inside Liesui, and Lies hides in this room -->
<BootGate {H} who="the room" audio_fullscreen={true} />

<div class="bw">
    <!-- the top bar: room name · the H** toc · Lies summon · the searchbar -->
    <div class="bw-top">
        <span class="bw-name" title="BigWordland — {editor_book ? '?E=' + editor_book + ' (editor: takes the editor slot)' : '?H=' + hacker_book + ' (hacker: docks without the duties)'}">BigWordland{#if !editor_book}<span class="bw-hack">hacker</span>{/if}</span>{#if seat?.unproven}<span class="bw-seat unproven" title="the relay gives seat:editor only to a socket a cluster flock key vouches for — open the repo as this tab's folder (it reads .env.cluster-editor once), or paste a flock key in the 🪪 Id hatch">unproven — sign in 🪪</span>{:else if seat?.held}<span class="bw-seat held" title="this tab holds seat:editor — its Waft and .g saves land">✍ writes</span>{:else if seat?.by}<button class="bw-seat" title="seat:editor is held by {seat.by} — this tab reads; saves wait for the seat. Click to take it." onclick={wrest_seat}>reads</button>{/if}
        <div class="bw-toc">
            {#each houses as house (house.c.ip)}
                <button class="bw-h" style="--d: {depth_of(house)}"
                        class:active={active_ip === house.c.ip}
                        class:off={!house.started}
                        onclick={() => view = house.c.ip}
                        title="{house.name} — show it fullscreen">
                    <span class="bw-h-name">{house.name}</span>
                </button>
                <!-- the drain-queue badge + flood tracer (Otro's and BigSoundland's own) — the traffic-jam readout -->
                <span class="bw-spool"><TodoSpool {house} {H} /></span>
                {#if active_ip === house.c.ip}
                    <button class="bw-cog" class:on={show_actions}
                            onclick={() => show_actions = !show_actions}
                            title="{house.name} — {house.actions.ob({ action: 1 }).length} action buttons">⚙</button>
                {/if}
            {/each}
        </div>
        <button class="bw-sprawl-btn" class:on={sprawl}
                title={sprawl
                    ? 'sprawl: every House’s UIs dumped in order — click for the one-thing switcher'
                    : 'sprawl — dump every House’s UIs down one page (the original view)'}
                onclick={toggle_sprawl}>▦</button>
        <button class="bw-lies-chip" class:on={show_lies}
                title="call Lies up — the straight Liesui, hidden by default in the room"
                onclick={() => show_lies = !show_lies}>⌐ Lies</button>
        {#if lies && vyto_ready}
            <button class="bw-cave-chip" onclick={focus_hole}
                    title="search — the hole you type into is the spine's head  ( / )">⌕ search <span class="bw-key">/</span></button>
        {:else if lies}
            <div class="bw-search"><Searchbar H={lies.house} w={lies.w} onpin={pin} onresults={on_results} {dismiss} /></div>
        {/if}
    </div>

    <!-- the active House's action rack — up only when the ⚙ cog asks -->
    {#if show_actions && active}
        <div class="bw-panel">
            <span class="bw-panel-name">{active.name}{#if !active.started}<span class="bw-off">off</span>{/if}</span>
            <Actions N={active.actions.ob({ action: 1 })} />
            {#if active.stashed}
                <button class="bw-cstar" class:on={active.stashed.showC}
                        title="show this House's C** (Stuffing) tree in the room"
                        onclick={() => toggle_C(active)}>C**</button>
            {/if}
        </div>
    {/if}

    <!-- the room — ONE House fullscreen (the show-one-thing view), OR the sprawl: every
         House's UIs dumped in order down the page.  Lies only when called up (or in sprawl). -->
    <!-- the spine — mounted hidden for EVERY House so the channel's carrier lands (see spine_ui) -->
    <div hidden>
        {#each houses as house (house.c.ip)}
            {#each house.UIs.ob({ UI: 1 }).filter(spine_ui) as uiC (keyser(uiC.sc))}
                <svelte:component this={uiC.sc.component} H={house} />
            {/each}
        {/each}
    </div>
    <div class="bw-room" class:bw-railed={pins.length > 0} class:bw-sprawl={sprawl}
         class:bw-caverail={cave_up && cave_mode === 'rail'} style:--rail-w={rail_w ? rail_w + 'px' : null}>
        {#each (sprawl ? houses : houses.filter(h => h.c.ip === active_ip)) as house (house.c.ip)}
            {#each house.UIs.ob({ UI: 1 }) as uiC (keyser(uiC.sc))}
                {#if !ui_hidden(uiC.sc.UI) && !is_glass(uiC)}
                    <section class="bw-piece" class:bw-piece-lies={uiC.sc.UI === 'Lies'}>
                        <span class="bw-tag">{house.name} · {uiC.sc.UI}</span>
                        {#if uiC.sc.UI === 'Vyto' && house === glass_house}{@render hole_box()}{/if}
                        <svelte:component this={uiC.sc.component} H={house} />
                    </section>
                {/if}
            {/each}
            {#if house.stashed?.showC}
                <section class="bw-piece">
                    <span class="bw-tag">{house.name} · C**</span>
                    <!-- exactly Otro's mount; the casts only paper the prop typings Otro's
                         untyped `houses` never surfaces -->
                    <Stuffing mem={house.imem('current') as any} stuff={house} H={house} M={house as any} />
                </section>
            {/if}
        {/each}
    </div>

    <!-- THE GLASS — its own layer, drawn from the House that holds it, whichever House the switcher shows -->
    {#if glass_ui && glass_house && !sprawl}
        <section class="bw-piece bw-glass" class:up={cave_up} class:rail={cave_mode === 'rail'} style:--rail-w={rail_w ? rail_w + 'px' : null}>
            {#if cave_mode === 'rail'}
                <div class="bw-rail-grip" role="separator" aria-orientation="vertical" title="drag to size the rail · double-click to reset"
                     onpointerdown={rail_grip} ondblclick={rail_reset}></div>
            {/if}
            <button class="bw-glass-x" title="back to rest — the hole and the families" onclick={rest_cave}>×</button>
            {@render hole_box()}
            <svelte:component this={glass_ui.sc.component} H={glass_house} />
        </section>
    {/if}

    <!-- the pin rail — the loose space at the right of the code -->
    {#if pins.length}
        <div class="bw-pins">
            <span class="bw-pins-name">pinned</span>
            {#each pins as p (pin_key(p))}
                <div class="bw-pin">
                    <button class="bw-pin-go" onclick={() => goto_pin(p)}
                            title="{p.path}:{p.line} — open & land on it (recorded in today's Aside)">
                        <span class="bw-pin-g">{p.glyph}</span>{p.name ?? p.snippet}
                        <span class="bw-pin-doc">{tail(p.path)}:{p.line}</span>
                    </button>
                    <button class="bw-pin-x" title="unpin" onclick={() => unpin(p)}>×</button>
                </div>
            {/each}
        </div>
    {/if}
</div>

{#if H}
    <Lens {H} kind="Panel" />
{/if}

{#if H}
    <Ghost {H} />
{/if}

<!-- THE HOLE — one plain input, drawn wherever the glass is: atop the overlay, or atop the Vyto piece in the sprawl
     (where there is no overlay).  Only one place renders at a time, so the one bind holds.  Before 2026-10-14 it lived
     in the overlay alone, so the sprawl had NO box — the chip, the head and '/' had nothing to seek. -->
{#snippet hole_box()}
    <input class="bw-hole" bind:this={hole} spellcheck="false" autocomplete="off"
           placeholder="search code & prose  ( / )   ·   :verbs"
           oninput={hole_input} onkeydown={hole_key} />
{/snippet}

<style>
    /* the room — big, dark, empty; the machine's pieces float in it */
    .bw {
        min-height: 100vh; box-sizing: border-box;
        background: radial-gradient(120% 130% at 30% -10%, #191a26, #0b0b12 70%);
        color: #b8c2d8; font-family: monospace;
        padding: 0;   /* full-bleed — the UI takes the whole screen (body margin:0 in app.css frees the viewport edge) */
    }

    /* top bar — room name, the H** toc, Lies summon, search */
    .bw-top {
        position: sticky; top: 0; z-index: 60;
        display: flex; align-items: center; gap: 0.9rem; flex-wrap: wrap;
        padding: 0.45rem 0.2rem; margin: 0 -0.2rem;
        background: rgba(11, 11, 18, 0.92); backdrop-filter: blur(4px);
        border-bottom: 1px solid rgba(120, 140, 195, 0.18);
    }
    /* the hacker badge — this room does not hold the editor slot, and that should be visible */
    .bw-hack {
        font-size: 0.62rem; letter-spacing: 0.1em; margin-left: 0.5em;
        color: #8fd3c8; border: 1px solid rgba(143, 211, 200, 0.4);
        border-radius: 5px; padding: 0.02rem 0.3rem; vertical-align: 0.1em;
    }
    .bw-seat {
        font: inherit; font-size: 0.62rem; letter-spacing: 0.1em; margin-left: -0.5rem; cursor: pointer;
        color: #c8b48f; background: none; border: 1px dashed rgba(200, 180, 143, 0.45);
        border-radius: 5px; padding: 0.02rem 0.3rem;
    }
    .bw-seat.unproven { color: #e0b88f; border: 1px solid rgba(224, 184, 143, 0.5); cursor: default; }
    .bw-seat.held { color: #b8e08f; border: 1px solid rgba(184, 224, 143, 0.5); cursor: default; }
    .bw-name {
        font-size: 0.85rem; letter-spacing: 0.14em; text-transform: uppercase;
        color: #8fa2c8; text-shadow: 0 0 12px rgba(140, 170, 230, 0.35);
        flex: none;
    }
    .bw-toc { display: flex; align-items: baseline; gap: 0.15rem; flex-wrap: wrap; min-width: 0; }
    .bw-h {
        background: none; border: none; cursor: pointer; font-family: inherit;
        font-size: 0.78rem; color: rgba(150, 170, 205, 0.75);
        padding: 0.1rem 0.45rem; border-radius: 6px;
        margin-left: calc(var(--d) * 0.55rem);   /* H** depth reads as indent */
        transition: color 0.12s, background 0.12s;
    }
    .bw-h:hover  { color: #e4ecff; background: rgba(120, 150, 210, 0.12); }
    .bw-h.active { color: #ffe0a8; background: rgba(224, 180, 110, 0.14); }
    .bw-h.off    { color: rgba(200, 110, 110, 0.6); }
    /* the ⚙ cog — rides beside the active chip only; toggles that House's action rack */
    .bw-cog {
        background: none; border: none; cursor: pointer; font-family: inherit;
        font-size: 0.8rem; line-height: 1; color: rgba(180, 195, 225, 0.55);
        padding: 0.1rem 0.25rem; border-radius: 6px; flex: none;
        transition: color 0.12s, background 0.12s, transform 0.2s;
    }
    .bw-cog:hover { color: #e4ecff; background: rgba(120, 150, 210, 0.14); }
    .bw-cog.on    { color: #ffe0a8; background: rgba(224, 180, 110, 0.16); transform: rotate(40deg); }
    /* the todo count rides as an EXPONENT floated off the end of the name — position:absolute so it
       is OUT OF FLOW: a flashing count never re-sizes the chip, so the toc no longer shoves the
       margin-left:auto searchbar (the vibrate).  left:100% pins it just past the last letter. */
    .bw-h-name { position: relative; }
    .bw-spool { display: inline-flex; align-items: center; font-size: 0.72rem; margin-left: -0.1rem; }

    /* ▦ the sprawl toggle — flip between the one-thing switcher and the dump-it-all page */
    .bw-sprawl-btn {
        background: none; border: 1px solid rgba(120, 140, 195, 0.25); border-radius: 6px;
        cursor: pointer; font-family: inherit; font-size: 0.78rem; line-height: 1;
        color: rgba(150, 170, 205, 0.7); padding: 0.1rem 0.4rem; flex: none;
        transition: color 0.12s, background 0.12s, border-color 0.12s;
    }
    .bw-sprawl-btn:hover { color: #e4ecff; border-color: rgba(150, 190, 240, 0.5); }
    .bw-sprawl-btn.on { color: #cfe0ff; background: rgba(120, 150, 210, 0.16); border-color: rgba(150, 190, 240, 0.45); }

    .bw-lies-chip {
        background: none; border: 1px solid rgba(120, 140, 195, 0.25); border-radius: 6px;
        cursor: pointer; font-family: inherit; font-size: 0.74rem;
        color: rgba(150, 170, 205, 0.7); padding: 0.1rem 0.5rem; flex: none;
    }
    .bw-lies-chip:hover { color: #e4ecff; border-color: rgba(150, 190, 240, 0.5); }
    .bw-lies-chip.on { color: #cfe0ff; background: rgba(120, 150, 210, 0.16); }
    .bw-search { flex: 1; min-width: 14rem; max-width: 34rem; margin-left: auto; }

    /* the opened House's panel — its button rack, dropped just under the toc.  IN NORMAL FLOW
       (not sticky): its height PUSHES the room below it down, instead of floating over the UI
        and covering it once you scroll into the editor.  It scrolls away with the page. */
    .bw-panel {
        position: relative; z-index: 1;
        display: flex; align-items: center; gap: 0.75rem; flex-wrap: wrap;
        padding: 0.45rem 0.7rem; margin: 0.4rem 0;
        background: rgba(18, 19, 30, 0.96);
        border: 1px solid rgba(224, 180, 110, 0.3); border-radius: 10px;
    }
    .bw-panel-name { font-size: 0.8rem; color: #ffe0a8; }
    .bw-off { color: #e05a5a; font-size: 0.75em; margin-left: 0.4em; }
    .bw-cstar {
        border: none; border-radius: 4px; cursor: pointer; font-family: inherit;
        font-size: 0.72rem; padding: 0.25rem 0.5rem;
        background: #2196F3; color: white; opacity: 0.45;
    }
    .bw-cstar:hover { opacity: 0.75; }
    .bw-cstar.on { opacity: 1; }

    /* the room body — ONE House fullscreen; its pieces stack, filling the space below the top bar */
    .bw-room {
        display: flex; flex-direction: column; gap: 2.2rem; padding-top: 1.4rem;
        min-height: calc(100vh - 3rem);
    }
    .bw-room.bw-railed { padding-right: 15rem; }   /* leave the loose space loose */
    .bw-piece { position: relative; min-width: 0; }
    .bw-tag {
        position: absolute; top: -1.05rem; left: 0.15rem;
        font-size: 0.62rem; letter-spacing: 0.08em; color: rgba(120, 135, 170, 0.55);
        user-select: none; pointer-events: none;
    }

    /* THE CAVE'S GLASS — UI:Vyto lifted out of the flow and laid over the code.  It IS the results while it
       is up (the Searchbar's dropdown stands down), so it takes the room's whole width; at a method it folds
       to a left RAIL and the room steps right (.bw-caverail) so the landed code sits beside the method's doors.
       Always MOUNTED so the glass keeps its world and its size; merely invisible and click-through until a
       search is up.  z 70 clears the top bar's stacking context (60). */
    .bw-piece.bw-glass {
        position: fixed; top: 3rem; left: 0; right: 0; bottom: 0; z-index: 70;
        display: flex; flex-direction: column;
        visibility: hidden; pointer-events: none;
    }
    /* the rail's width: --rail-w once dragged (rail_grip), else the default */
    .bw-piece.bw-glass.rail { right: auto; width: var(--rail-w, min(24rem, 30vw)); }
    .bw-room.bw-caverail { padding-left: calc(var(--rail-w, min(24rem, 30vw)) + 0.8rem); }
    .bw-rail-grip {
        position: absolute; top: 0; bottom: 0; right: -4px; width: 8px; z-index: 2;
        cursor: col-resize; touch-action: none;
    }
    .bw-rail-grip:hover, .bw-rail-grip:active { background: rgba(224, 180, 110, 0.25); }
    .bw-piece.bw-glass.up { visibility: visible; pointer-events: auto; }
    /* the copper sheet goes translucent HERE only — a scoped :global, so no other page that mounts Vytui
       changes by a pixel — and the code ghosts through beneath the spine */
    .bw-glass :global(.vyto) {
        flex: 1; background-color: rgba(22, 17, 13, 0.94) !important; background-image: none !important;
        backdrop-filter: blur(1.5px);
    }
    /* the hole — a plain input at the top of the glass, never rebuilt (2026-10-12) */
    .bw-hole {
        flex: none; margin: 0.45rem 2.6rem 0.35rem 0.6rem; padding: 0.42rem 0.8rem;
        font: 600 1.05rem/1.2 system-ui, sans-serif; color: #ffe6bd;
        background: rgba(30, 22, 14, 0.92); border: 1px solid rgba(224, 180, 110, 0.45); border-radius: 8px; outline: none;
    }
    .bw-piece:not(.bw-glass) > .bw-hole { display: block; width: calc(100% - 1.2rem); box-sizing: border-box; margin: 0.2rem 0.6rem 0.4rem; }
    .bw-hole:focus { border-color: rgba(255, 210, 130, 0.9); box-shadow: 0 0 18px rgba(255, 200, 110, 0.3); }
    .bw-hole::placeholder { color: rgba(230, 200, 160, 0.45); font-weight: 400; }
    .bw-glass-x {
        position: absolute; top: 0.3rem; right: 0.4rem; z-index: 5;
        background: rgba(14, 15, 25, 0.8); border: 1px solid rgba(224, 180, 110, 0.35); border-radius: 6px;
        cursor: pointer; font-family: inherit; font-size: 0.95rem; line-height: 1;
        color: rgba(255, 224, 168, 0.8); padding: 0.1rem 0.4rem;
    }
    .bw-cave-chip {
        margin-left: auto; flex: none; cursor: pointer; font-family: inherit; font-size: 0.82rem;
        background: rgba(30, 24, 16, 0.6); border: 1px solid rgba(224, 180, 110, 0.4); border-radius: 14px;
        color: rgba(255, 224, 168, 0.85); padding: 0.18rem 0.8rem;
    }
    .bw-cave-chip:hover { color: #ffe0a8; border-color: rgba(255, 210, 130, 0.85); background: rgba(60, 44, 24, 0.7); }
    .bw-key { font-size: 0.7em; opacity: 0.6; border: 1px solid currentColor; border-radius: 3px; padding: 0 0.25em; margin-left: 0.3em; }
    .bw-glass-x:hover { color: #ffe0a8; border-color: rgba(224, 180, 110, 0.7); }

    /* the pin rail — the loose space at the right of the code */
    .bw-pins {
        position: fixed; right: 0.7rem; top: 3.4rem; z-index: 50;
        display: flex; flex-direction: column; gap: 0.15rem;
        width: 13.5rem; max-height: 70vh; overflow: auto;
        padding: 0.4rem 0.5rem;
        background: rgba(14, 15, 25, 0.9); border: 1px solid rgba(120, 140, 195, 0.25);
        border-radius: 10px; backdrop-filter: blur(3px);
    }
    .bw-pins-name {
        font-size: 0.62rem; letter-spacing: 0.12em; text-transform: uppercase;
        color: rgba(140, 160, 200, 0.6); padding-bottom: 0.15rem;
    }
    .bw-pin { display: flex; align-items: baseline; gap: 0.2rem; }
    .bw-pin-go {
        flex: 1; min-width: 0; background: none; border: none; cursor: pointer;
        text-align: left; font-family: inherit; font-size: 0.72rem; color: #aab;
        padding: 0.08rem 0.25rem; border-radius: 4px;
        white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
    }
    .bw-pin-go:hover { background: rgba(120, 150, 210, 0.14); color: #e8f0ff; }
    .bw-pin-g   { color: #7a8fa8; margin-right: 0.3em; }
    .bw-pin-doc { color: #679; margin-left: 0.4em; }
    .bw-pin-x {
        background: none; border: none; cursor: pointer; font-family: inherit;
        font-size: 0.8rem; color: rgba(160, 120, 120, 0.6); padding: 0 0.25rem;
    }
    .bw-pin-x:hover { color: #ff9a9a; }

</style>
