<script lang="ts">
    // BigWordland — a second toplevel, rivaling Otro.  The SAME machine underneath (Ghost
    //  mounts every ghost; an editor Book boots exactly as under Otro) presented as a BIG
    //   EMPTY ROOM instead of Otro's NaviScroll column:
    //    · ?E=<Book> parametrises which editor Book boots, DEFAULTING to Educarium — the
    //      Editron-shaped recipe living beside this file (L/Educarium.svelte).  No ?B/?I
    //      here: runners board through /Otro; this room is author chrome.
    //    · a toc of H** across the top — Mundo · Story · Educarium (the Run named after the
    //      book) · … — each a chip.  This is a SWITCHER, not a spread: clicking a chip makes
    //       that House the ONE fullscreen view (the show-one-thing policy).  Opens on Educarium
    //        (⇒ Langui, its editor UI); click Story to watch the runner, Mundo for the root.
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
    import { keyser } from "$lib/data/Stuff.svelte"
    import Actions    from "$lib/O/ui/Actions.svelte"
    import Lens       from "$lib/O/ui/Lens.svelte"
    import Stuffing   from "$lib/data/Stuffing.svelte"
    import Searchbar  from "$lib/O/ui/Searchbar.svelte"
    import BootGate   from "$lib/O/ui/BootGate.svelte"
    import { boot_param } from "$lib/boot"
    import { boot_qualand } from "$lib/O/BigQualand.svelte"

    //#region H:Mundo — the shared boot (the aufheben's common bit) lives in BigQualand now; this
    //  room supplies only its knobs — the editor Book, the editor role — and reads H + houses back.
    //  The OOM trap (assign H once, never read it in the construction effect) is baked in over there.
    const editor_book = boot_param('E') || 'Educarium'
    const q = boot_qualand({ book: editor_book, role: 'word' })   // role 'word' ⇒ Lies%humdinger: an end-user page, never a dispatch target
    let H      = $derived(q.H)
    let houses = $derived(q.houses)
    //#endregion

    //#region the room's own state
    // the fullscreen switcher.  `view` is the user's explicit pick (a House ip); undefined means
    //  "auto", which resolves to the Educarium Run (opens on the editor, Langui) or, before it
    //   stands up, the deepest House so the boot is visible.  `active` is the House shown.
    let view = $state<string | undefined>(undefined)
    let active_ip = $derived(
        view
        ?? houses.find(h => h.name === editor_book)?.c.ip
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
    //#endregion
</script>

<!-- the shared boot gate; audio begs fullscreen here — the Brink (its usual home) lives
     inside Liesui, and Lies hides in this room -->
<BootGate {H} who="the room" audio_fullscreen={true} />

<div class="bw">
    <!-- the top bar: room name · the H** toc · Lies summon · the searchbar -->
    <div class="bw-top">
        <span class="bw-name" title="BigWordland — ?E={editor_book}">BigWordland</span>
        <div class="bw-toc">
            {#each houses as house (house.c.ip)}
                <button class="bw-h" style="--d: {depth_of(house)}"
                        class:active={active_ip === house.c.ip}
                        class:off={!house.started}
                        onclick={() => view = house.c.ip}
                        title="{house.name} — show it fullscreen">
                    <span class="bw-h-name">{house.name}{#if house.todo.length}<span class="bw-todo">{house.todo.length}</span>{/if}</span>
                </button>
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
        {#if lies}
            <div class="bw-search"><Searchbar H={lies.house} w={lies.w} onpin={pin} /></div>
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
    <div class="bw-room" class:bw-railed={pins.length > 0} class:bw-sprawl={sprawl}>
        {#each (sprawl ? houses : houses.filter(h => h.c.ip === active_ip)) as house (house.c.ip)}
            {#each house.UIs.ob({ UI: 1 }) as uiC (keyser(uiC.sc))}
                {#if !ui_hidden(uiC.sc.UI)}
                    <section class="bw-piece" class:bw-piece-lies={uiC.sc.UI === 'Lies'}>
                        <span class="bw-tag">{house.name} · {uiC.sc.UI}</span>
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
    .bw-todo {
        position: absolute; left: 100%; top: -0.35em;
        font-size: 0.6em; line-height: 1; color: #e0965a;
        pointer-events: none; white-space: nowrap;
    }

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
