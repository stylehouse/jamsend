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

    // THE CAVE (2026-09-25; re-cut 2026-10-03; ONE VISUAL 2026-10-03) — search, worn as a creature, over the
    //  code.  The owner: *"I'm wanting just the one visual: a big spine-root spine-label-sized hole we type into,
    //   and everything pings around it pretty fast."*  So where the glass is loaded, the top bar holds no search
    //    box at all — a ⌕ chip (or `/`) opens the cave, and the HOLE you type into is the spine's own head
    //     (Lagoon.g THE CAVE, a Vyto guise `field`).  Empty, the code's families stand around it; typed, its
    //      files and their stem families.  The Searchbar remains only as the fallback when Vyto is absent.
    //  The producer tells the room three things through `cave_on`: LAND (show this code — the Searchbar's own
    //   delivery, `Lies_ghost_pick`), LEAVE (the head pressed at the surface, or Esc — the cave closes) and MODE
    //    (at a method the glass folds to a left RAIL and the room steps right, so the code sits beside its doors).
    //  The Stemdex is FED from here, as the Searchbar used to: nudged while the cave is open and the index has
    //   not converged, and the cave re-reads it so text hits fill in as they land.
    let cave_open = $state(false)
    let cave_mode = $state('full')
    let dismiss   = $state(0)
    let vyto_ready = $state(false)
    const lagoon_w = () => (H as any)?.o({ A: 'Lagoon' })[0]?.o({ w: 'Lagoon' })[0]
    $effect(() => {
        if (vyto_ready) return
        const t = setInterval(() => { if (typeof (H as any)?.Vyto_guise === 'function') { vyto_ready = true; clearInterval(t) } }, 400)
        return () => clearInterval(t)
    })
    function cave_on(ev: string, a: any) {
        if (ev === 'land' && a?.path) {
            lies?.house.i_elvisto('Lies/Lies', 'Lies_ghost_pick', a.point ? { path: a.path, point: a.point } : { path: a.path })
            if (a.leave) close_cave()
        }
        if (ev === 'leave') close_cave()
        if (ev === 'mode') cave_mode = a === 'rail' ? 'rail' : 'full'
    }
    function open_cave() {
        if (!H) return
        const lw = lagoon_w()
        if (lw) lw.c.cave_on = cave_on
        cave_open = true
        lies?.house.i_elvisto('Lies/Lies', 'Lies_stemdex_scan', {})
        H.i_elvisto('Lagoon/Lagoon', 'Lagoon_cave', { open: 1 })
    }
    function close_cave() {
        if (!cave_open) return
        cave_open = false
        cave_mode = 'full'
        H?.i_elvisto('Lagoon/Lagoon', 'Lagoon_cave', { clear: 1 })
    }
    // the fallback Searchbar (no glass on this tab) still drives the cave's old door
    function on_results(r: any) {
        const q = r?.q ? String(r.q) : ''
        if (!H || !q) return
        const lw = lagoon_w()
        if (lw) lw.c.cave_on = cave_on
        H.i_elvisto('Lagoon/Lagoon', 'Lagoon_cave', { q, r })
    }
    // feed the Stemdex while the cave is open and its (small — the room's own Wafts) roster is converging, and
    //  re-ask the cave ONLY when the index actually read something new.  (2026-10-06: a roster widened to every
    //   Atlas doc plus an unconditional 1.5s re-ask was a read-STUCK storm and a re-sow tailspin — reverted.)
    $effect(() => {
        if (!cave_open) return
        let seen_done = -1
        const t = setInterval(() => {
            const dex = (lies?.w as any)?.c?.stemdex
            if (dex && dex.total > 0 && dex.done >= dex.total) return
            if (!dex?.scanning) lies?.house.i_elvisto('Lies/Lies', 'Lies_stemdex_scan', {})
            if (dex && dex.done !== seen_done) {
                seen_done = dex.done
                H?.i_elvisto('Lagoon/Lagoon', 'Lagoon_cave', { refresh: 1 })
            }
        }, 1500)
        return () => clearInterval(t)
    })
    // '/' opens the hole from anywhere that is not already typing (capture phase, à la the Searchbar)
    $effect(() => {
        if (!vyto_ready) return
        const grab = (ev: KeyboardEvent) => {
            if (ev.key !== '/' || ev.ctrlKey || ev.metaKey || ev.altKey) return
            const t = ev.target as HTMLElement | null
            if (t && (t.tagName === 'INPUT' || t.tagName === 'TEXTAREA' || t.isContentEditable)) return
            ev.preventDefault()
            open_cave()
        }
        window.addEventListener('keydown', grab, true)
        return () => window.removeEventListener('keydown', grab, true)
    })
    let has_glass = $derived.by(() => {
        void active?.UIs?.version
        return !!(active as any)?.UIs?.ob({ UI: 'Vyto' })[0]
    })
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
        <span class="bw-name" title="BigWordland — {editor_book ? '?E=' + editor_book + ' (editor: takes the editor slot)' : '?H=' + hacker_book + ' (hacker: docks without the duties)'}">BigWordland{#if !editor_book}<span class="bw-hack">hacker</span>{/if}</span>
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
            <button class="bw-cave-chip" class:on={cave_open} onclick={() => cave_open ? close_cave() : open_cave()}
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
         class:bw-caverail={cave_up && cave_mode === 'rail'}>
        {#each (sprawl ? houses : houses.filter(h => h.c.ip === active_ip)) as house (house.c.ip)}
            {#each house.UIs.ob({ UI: 1 }) as uiC (keyser(uiC.sc))}
                {#if !ui_hidden(uiC.sc.UI)}
                    <section class="bw-piece" class:bw-piece-lies={uiC.sc.UI === 'Lies'}
                             class:bw-glass={is_glass(uiC)} class:up={is_glass(uiC) && cave_up}
                             class:rail={is_glass(uiC) && cave_mode === 'rail'}>
                        {#if is_glass(uiC)}
                            <button class="bw-glass-x" title="close the cave (and the search)"
                                    onclick={close_cave}>×</button>
                        {:else}
                            <span class="bw-tag">{house.name} · {uiC.sc.UI}</span>
                        {/if}
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
    .bw-piece.bw-glass.rail { right: auto; width: min(28rem, 34vw); }
    .bw-room.bw-caverail { padding-left: calc(min(28rem, 34vw) + 0.8rem); }
    .bw-piece.bw-glass.up { visibility: visible; pointer-events: auto; }
    /* the copper sheet goes translucent HERE only — a scoped :global, so no other page that mounts Vytui
       changes by a pixel — and the code ghosts through beneath the spine */
    .bw-glass :global(.vyto) {
        flex: 1; background-color: rgba(26, 20, 16, 0.62) !important; background-image: none !important;
        backdrop-filter: blur(1.5px);
    }
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
    .bw-cave-chip:hover, .bw-cave-chip.on { color: #ffe0a8; border-color: rgba(255, 210, 130, 0.85); background: rgba(60, 44, 24, 0.7); }
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
