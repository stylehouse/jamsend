<script lang="ts">
    // BigWordland — a second toplevel, rivaling Otro.  The SAME machine underneath (Ghost
    //  mounts every ghost; an editor Book boots exactly as under Otro) presented as a BIG
    //   EMPTY ROOM instead of Otro's NaviScroll column:
    //    · ?E=<Book> parametrises which editor Book boots, DEFAULTING to Educarium — the
    //      Editron-shaped recipe living beside this file (L/Educarium.svelte).  No ?B/?I
    //      here: runners board through /Otro; this room is author chrome.
    //    · a toc of H** across the top — every House a chip; click one to drop open its
    //      panel (the Actions button rack + the C** dump toggle).  No NaviScroll.
    //    · ONE BIG SET of H.UIs at once, loose in the room — except UI:Lies, which hides
    //      until called up (the ⌐Lies chip) and then renders all straight as it has been.
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
    import FaceSucker from "$lib/p2p/ui/FaceSucker.svelte"
    import { onDestroy, onMount } from "svelte"
    import { boot_param } from "$lib/boot"

    //#region H:Mundo — construction, mirroring Otro
    let H: House = $state(null!)
    // Computed ONCE out here, and set on the LOCAL `h` below — NEVER as `H.c.x = …` inside
    //  the $effect: reading the $state H there makes the effect depend on H, which it also
    //  reassigns, so it self-retriggers forever, allocating a House every tick → the tab
    //  OOMs to multi-GB (Otro's hard-won note; same trap, same cure).
    const editor_book = boot_param('E') || 'Educarium'
    $effect(() => {
        const h = new House({ name: 'Mundo' })
        h.c.toplevel  = 'Auto'          // the Library/Story owner activates the Book
        h.c.book      = editor_book
        h.c.boot_role = 'editor'        // this room only ever boots the editor role
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

    //#region gates — disk + audio (Otro's mechanics)
    // Under a dev boot the OPFS-from-github shadow disk is illegal; DirectoryOpener raises
    //  H.c.disk_gated until a real share opens.  Unlike Otro we do NOT suppress the pure-
    //   audio gate for editor boots: the Brink's Sound face lives INSIDE Liesui, and Lies
    //    hides in this room — so the fullscreen tap is the only reachable beg.
    let disk_poll = $state(0)
    let ac_poll   = $state(0)
    let pending_gats: any[] = []
    onMount(() => {
        const iv = setInterval(() => disk_poll++, 400)
        const on_want = (e: any) => {
            const g = e?.detail?.gat
            if (g && !g.AC_ready && !pending_gats.includes(g)) { pending_gats.push(g); ac_poll++ }
        }
        window.addEventListener('AudioContext_wanted', on_want)
        return () => { clearInterval(iv); window.removeEventListener('AudioContext_wanted', on_want) }
    })
    let disk_gated = $derived.by(() => { disk_poll; return !!H?.c.disk_gated })
    let ac_wanted  = $derived.by(() => { disk_poll; ac_poll; return pending_gats.some(g => !g?.AC_ready) })
    let share_error   = $state('')
    let opening_share = $state(false)
    async function wake_gat(g: any): Promise<boolean> {
        try {
            if (!g) return false
            if (!g.AC) { await g.init?.(); return !!g.AC_ready }
            return !!(await g.AC_OK?.())
        } catch { return false }
    }
    async function open_share() {
        share_error = ''
        opening_share = true
        const wakes = pending_gats.map(wake_gat)          // AC resume|init — within the gesture
        let disk_p: Promise<any> | null = null
        if (disk_gated) {
            const act = H?.o({ watched: 'actions' })[0]?.o({ action: 1, role: 'open_dir' })[0]
            if (!act?.sc.fn) { share_error = 'wormhole not ready yet — a moment'; opening_share = false; return }
            disk_p = act.sc.fn()                          // requestDirectoryAccess() — same gesture
        }
        try {
            await Promise.all(wakes)
            if (disk_p) await disk_p
        } catch (e) { share_error = String(e) }
        finally {
            pending_gats = pending_gats.filter(g => !g?.AC_ready)
            ac_poll++
            opening_share = false
        }
    }
    //#endregion

    //#region the room's own state
    // toc of H** — which House's panel is dropped open (one at a time; click again to fold)
    let open_panel = $state<string | undefined>(undefined)
    function childrenOf(house: House): House[] {           // ip-based, as NaviScroll derives it
        const ip = (house as any)?.c?.ip
        if (!ip) return []
        const depth = ip.split('_').length
        return houses.filter(h => (h as any).c?.ip?.startsWith(ip + '_')
                               && (h as any).c.ip.split('_').length === depth + 1)
    }
    function depth_of(house: House): number {
        return (((house as any).c?.ip as string | undefined)?.split('_').length ?? 1) - 1
    }
    function toggle_C(house: any) {                        // Otro's lean-stashed C** toggle
        if (house.stashed.showC) delete house.stashed.showC
        else house.stashed.showC = 1
    }

    // Lies hides unless called up — then it renders all straight as it has been
    let show_lies = $state(false)

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

{#if disk_gated || ac_wanted}
    <FaceSucker altitude={77} fullscreen={true}>
        {#snippet content()}
            <div class="bw-gate">
                {#if disk_gated}
                    <h2>the room needs a real folder</h2>
                    <p>OPFS is disabled while developing — open a shared directory so the
                        machine reads &amp; writes the real project tree.{#if ac_wanted} The
                        same tap also starts audio.{/if}</p>
                {:else}
                    <h2>the room needs a tap for sound</h2>
                    <p>The share is already open; audio just needs one gesture to start
                        (browser autoplay policy).</p>
                {/if}
                <button class="big" onclick={open_share} disabled={opening_share}>
                    {opening_share ? 'opening…' : '📂 open share'}
                </button>
                {#if share_error}<p class="bw-gate-err">{share_error}</p>{/if}
            </div>
        {/snippet}
    </FaceSucker>
{/if}

<div class="bw">
    <!-- the top bar: room name · the H** toc · Lies summon · the searchbar -->
    <div class="bw-top">
        <span class="bw-name" title="BigWordland — ?E={editor_book}">BigWordland</span>
        <div class="bw-toc">
            {#each houses as house (house.c.ip)}
                <button class="bw-h" style="--d: {depth_of(house)}"
                        class:open={open_panel === house.c.ip}
                        class:off={!house.started}
                        onclick={() => open_panel = open_panel === house.c.ip ? undefined : house.c.ip}
                        title="{house.name} — {house.actions.ob({ action: 1 }).length} buttons; click for its panel">
                    {house.name}{#if house.todo.length}<span class="bw-todo">{house.todo.length}</span>{/if}
                </button>
            {/each}
        </div>
        <button class="bw-lies-chip" class:on={show_lies}
                title="call Lies up — the straight Liesui, hidden by default in the room"
                onclick={() => show_lies = !show_lies}>⌐ Lies</button>
        {#if lies}
            <div class="bw-search"><Searchbar H={lies.house} w={lies.w} onpin={pin} /></div>
        {/if}
    </div>

    <!-- the opened House's panel — play with its buttons -->
    {#each houses.filter(h => h.c.ip === open_panel) as house (house.c.ip)}
        <div class="bw-panel">
            <span class="bw-panel-name">{house.name}{#if !house.started}<span class="bw-off">off</span>{/if}</span>
            <Actions N={house.actions.ob({ action: 1 })} />
            {#if house.stashed}
                <button class="bw-cstar" class:on={house.stashed.showC}
                        title="show this House's C** (Stuffing) tree in the room"
                        onclick={() => toggle_C(house)}>C**</button>
            {/if}
        </div>
    {/each}

    <!-- the room — one big set of H.UIs at once; Lies only when called up -->
    <div class="bw-room" class:bw-railed={pins.length > 0}>
        {#each houses as house (house.c.ip)}
            {#each house.UIs.ob({ UI: 1 }) as uiC (keyser(uiC.sc))}
                {#if uiC.sc.UI !== 'Lies' || show_lies}
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
        padding: 0 1.2rem 4rem;
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
    .bw-h:hover { color: #e4ecff; background: rgba(120, 150, 210, 0.12); }
    .bw-h.open  { color: #ffe0a8; background: rgba(224, 180, 110, 0.12); }
    .bw-h.off   { color: rgba(200, 110, 110, 0.6); }
    .bw-todo { font-size: 0.68em; color: #e0965a; margin-left: 0.25em; }

    .bw-lies-chip {
        background: none; border: 1px solid rgba(120, 140, 195, 0.25); border-radius: 6px;
        cursor: pointer; font-family: inherit; font-size: 0.74rem;
        color: rgba(150, 170, 205, 0.7); padding: 0.1rem 0.5rem; flex: none;
    }
    .bw-lies-chip:hover { color: #e4ecff; border-color: rgba(150, 190, 240, 0.5); }
    .bw-lies-chip.on { color: #cfe0ff; background: rgba(120, 150, 210, 0.16); }
    .bw-search { flex: 1; min-width: 14rem; max-width: 34rem; margin-left: auto; }

    /* the opened House's panel — its button rack, dropped just under the toc */
    .bw-panel {
        position: sticky; top: 2.4rem; z-index: 55;
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

    /* the room body — pieces floating with air between them */
    .bw-room { display: flex; flex-direction: column; gap: 2.2rem; padding-top: 1.4rem; }
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

    /* the fullscreen gate (disk|audio) — Otro's, restyled for the dark room */
    .bw-gate {
        position: absolute; inset: 0;
        display: flex; flex-direction: column; align-items: center; justify-content: center;
        gap: 1rem; text-align: center; color: #d7edff; padding: 2rem;
        font-family: monospace;
    }
    .bw-gate h2 { margin: 0; font-size: 1.5rem; }
    .bw-gate p  { max-width: 28rem; opacity: 0.8; }
    .bw-gate button.big { font-size: 1.35rem; padding: 0.7em 1.2em; cursor: pointer; }
    .bw-gate button:disabled { opacity: 0.5; cursor: default; }
    .bw-gate-err { color: #ff8a8a; font-size: 0.9rem; }
</style>
