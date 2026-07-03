<script lang="ts">
    // Otro
    import Ghost    from "$lib/O/Ghost.svelte"
    import { House } from "$lib/O/Housing.svelte"
    import { keyser } from "$lib/data/Stuff.svelte"
    import Actions from "$lib/O/ui/Actions.svelte"
    import Lens from "$lib/O/ui/Lens.svelte"
    import Stuffing from "$lib/data/Stuffing.svelte"
    import { onDestroy, onMount } from "svelte";
    import NaviScroll from "./ui/NaviScroll.svelte";
    import { boot_param } from "$lib/boot";
    import BootGate from "./ui/BootGate.svelte";
    import { sockcap_install, socklog_armed } from "$lib/O/sockcap";   // ALMOST-GONER: relay-socket tap (dumped via Wormhole) — sockcap.ts header

    //#region H:Mundo
    // ── all House construction inside $effect ─────────────────────────────────
    let H: House = $state(null!)
    let R
    // ?A=<World> chooses which top-level world boots (default Auto, the Library/Story owner;
    //  may_begin stands up A:<A>/w:<A>).  The editor and test runner are Story Books, NOT their
    //  own top-level worlds — they boot via ?B=<Book> (below) under the default Auto.
    //  boot_param abstracts the source: URL query in the browser, env var (A=) in node.
    //  Computed ONCE out here, and set on the LOCAL `h` below — NEVER as `H.c.x = …` inside
    //  the $effect: reading the $state H there makes the effect depend on H, which it also
    //  reassigns (`H = new House()`), so it self-retriggers forever, allocating a House every
    //  tick → the tab OOMs to multi-GB.  (Svelte 5: an effect re-runs on any $state it reads.)
    const toplevel = boot_param('A') || 'Auto'
    // ?B=<Book> auto-activates a Story Book under the default A=Auto (the Library/Story owner) —
    //  ?B=Editron boots the editor as a Book, ?B=PereStaple the test runner, etc.  Auto reads
    //   H.c.book on first boot and activates it (see Auto.svelte).  ?W=<Waft> rides alongside for
    //    the Book that opens one.  Stamped on the LOCAL `h`, never inside the $effect — same
    //     self-retrigger trap as toplevel above.
    // The param LETTER is the authoritative role: ?E=<Book> boots that Book as the EDITOR
    //  (full Lang chrome — what ?B=Editron did before); ?B=<Book> boots it as a UIless RUNNER
    //   (no w:Lang; Story + the Creduler).  Mundo carries the choice as %book + %boot_role; a Run
    //    House inherits boot_role at Story_subHouse, and a Book recipe only falls back to its own
    //     role when neither param is set (a Library-driven boot).  Computed out here and set on the
    //      LOCAL h — never read $state H inside the effect (the self-retrigger OOM trap above).
    const editor_book = boot_param('E')
    const book        = boot_param('B')
    const on_grid     = boot_param('I')   // ?I=<tag> ALONE (no ?E/?B) — an idle runner-on-the-grid
    // &remoteWormhole=1: this tab has NO local tree — it acquires a method:remoteWormhole backend,
    //  begging a trusted editor to proxy its disk (a headless flock runner; see Cluster_spec "beg
    //   through the Brink").  Stamped on the LOCAL h (never read $state H inside the effect — the
    //    OOM trap above).  (Was &disk=proxy.)
    const remote_wormhole = boot_param('remoteWormhole') != null
    // ── investigation scaffold (TEMP — remove once roster/dispatch is confirmed healthy) ──────────
    //  Auto-reload a runner|editor tab every few minutes so fresh come-up + see-each-other handshakes
    //   keep cycling unattended (no human at the tab).  Cluster boots only (?E=/?B=/?I=), never the
    //    Library.  DEFAULT OFF now the dispatch fix is verified (was 3 during the investigation) — it
    //     disrupts a human at the tab + accretes socklog files; re-enable with &watch=<minutes>.
    //       Identity + edits persist to Dexie/.stashed across a reload.
    const watch_min = (() => { const v = boot_param('watch'); return v == null ? 0 : Number(v) })()
    // tap the relay socket (before the channel boots) so its traffic is captured for the Wormhole dump —
    //  ARMED opt-in ONLY: ?socklog (or implied by ?watch), never a plain tab.  OFF by default the tap never
    //   installs, sockcap stays empty, and Lies_dump_socklog early-returns — so no _socklog files and no
    //    rw-req blob every ~10s (which is what an always-on capture was parking in the snap).  Browser-guarded.
    if ((editor_book || book || on_grid) && (boot_param('socklog') != null || socklog_armed() || watch_min > 0)) sockcap_install()
    if (typeof window !== 'undefined' && (editor_book || book || on_grid) && watch_min > 0) {
        onMount(() => {
            const id = setInterval(() => { try { location.reload() } catch {} }, watch_min * 60_000)
            return () => clearInterval(id)
        })
    }
    $effect(() => {
        const h = new House({ name: 'Mundo' })
        h.c.toplevel = toplevel
        if (editor_book) { h.c.book = editor_book; h.c.boot_role = 'editor' }
        else if (book)   { h.c.book = book;        h.c.boot_role = 'runner' }
        // ?I= with no Book: a runner-on-the-grid.  Same runner role as ?B= (Creduler + channel), but
        //  NO H.c.book — so no Story starts at boot; the tab idles connected until the editor hands it
        //   a become_book.  /Otro?I=new is the whole on-ramp; the identity layer (Auto) does the rest.
        //  (?E=/?B= still win: an editor or booked runner that ALSO carries ?I just gains an identity.)
        else if (on_grid) {                        h.c.boot_role = 'runner' }
        if (remote_wormhole) h.c.remote_wormhole = true
        H = h
        setTimeout(() => {
            houses = [H]
        },1)
    })

    // ── once ghosts have arrived, wire child Houses ───────────────────────────
    let setup_done = $state(false)
    $effect(() => {
        if (!H?.started || setup_done) return
        setup_done = true

        H.may_begin()

        // < drop this?
        setTimeout(() => {
            houses = H.all_House
        },1)

        setTimeout(() => {
            // S.i_elvisto(S, 'think')
            // S.todo.push("Blanks")
        },444)

        go_busily()
    })
    $effect(() => {
        if (!setup_done) return
        houses = H.all_House
    })

    // ── reactive house list via H.all_House ───────────────────────────────────
    // all_House lives on House so .o() / Xify() mutations stay inside H.*
    // and don't fire mid-derived in the template.
    let houses = $state([])

    function go_busily() {
        H.i_elvisto(H, 'think')
    }

    // ── disk|audio gate ────────────────────────────────────────────────────────
    // The fullscreen boot-permissions gate lives in ui/BootGate.svelte now (shared with
    //  BigWordland).  Otro's policy rides its defaults: the pure-audio beg defers to the
    //   Brink's Sound face under a dev boot, and the copy addresses the boot role.

    onDestroy(() => {
        H?.stop()
    })

    // Per-House toggle for the C** dump (the Stuffing tree).  Stored on the
    //  Dexie-backed .stashed, not in Opt/the C tree — it's a viewer preference,
    //   not Book state, so it shouldn't snap or bleed across Books.  Following
    //    the "lean stashed" doctrine we delete the key when off rather than
    //     storing a 0, so the autosave $effect (which tracks the key set) fires.
    function toggle_C(house) {
        if (house.stashed.showC) delete house.stashed.showC
        else house.stashed.showC = 1
    }
</script>

<BootGate {H} />

<NaviScroll {H} {houses}>
    {#snippet children({ scrollToHouseIdx, scrollToHouseIp, childrenOf })}
        {#each houses as house, i (house.c.ip)}
            {@const hasActions = house.actions.ob({}).length > 0}
            {@const stickyIndex = houses.slice(0, i).filter(h => h.actions.ob({}).length).length}
            {@const kids = childrenOf(house)}
            <div class="house-header"
                class:sticky={hasActions}
                id="house-{house.c.ip}"
                style="--stack-index: {stickyIndex};">
                <h2 class="house-name" title="navigate to this House"
                    class:clickable={hasActions}
                    onclick={hasActions ? () => scrollToHouseIdx(i) : null}>
                    {house.name}
                    {#if !house.started}<span class='ungood'>off</span>{/if}
                    <span class="todo-count">{house.todo.length || ''}</span>
                </h2>
                <div class="house-nav">
                    <span class="arrow arrow-up" title="navigate to the previous House"
                        class:disabled={i === 0}
                        onclick={() => i > 0 && scrollToHouseIdx(i - 1)}>▲</span>
                    <span class="arrow arrow-down" title="navigate to the next House"
                        class:disabled={i === houses.length - 1}
                        onclick={() => i < houses.length - 1 && scrollToHouseIdx(i + 1)}>▼</span>
                </div>
                {#if kids.length}
                    <span class="kids-sep">/</span>
                    <div class="house-kids">
                        {#each kids as kid (kid.c.ip)}
                            <span class="kid" title="navigate to this House"
                                onclick={() => scrollToHouseIp(kid.c.ip)}>
                                {kid.name}
                            </span>
                        {/each}
                    </div>
                {/if}

                <div class="house-actions">
                    {#if hasActions}<Actions N={house.actions.ob({ action: 1 })} />{/if}
                    {#if house.stashed}
                        <button class="cstar" class:on={house.stashed.showC}
                            title="show this House's C** (Stuffing) tree"
                            onclick={() => toggle_C(house)}>C**</button>
                    {/if}
                </div>
            </div>
            {#each house.UIs.ob({ UI: 1 }) as uiC (keyser(uiC.sc))}
                <svelte:component this={uiC.sc.component} H={house} />
            {/each}
            {#if house.stashed?.showC}
                <Stuffing mem={house.imem('current')} stuff={house} H={house} M={house} />
            {/if}
        {/each}
    {/snippet}
</NaviScroll>

{#if H}
    <Lens {H} kind="Panel" />
{/if}

{#if H}
    <Ghost {H} />
{/if}

<style>
    .ungood { color: red; }

    /* Sits in the .house-actions row beside the data-driven <Actions>; styled to match them
       (a toggle: faint when off, solid when on) so the C** dump reads as just another action. */
    .cstar {
        padding: 0.3rem 0.6rem;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        line-height: 0.8;
        font-size: 0.8rem;
        background: #2196F3;
        color: white;
        opacity: 0.45;
    }
    .cstar:hover { opacity: 0.75; }
    .cstar.on { opacity: 1; }

    .house-header {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        background: var(--background, rgb(215, 237, 255));
        padding: 0 0.5rem;
        min-height: 1.75rem;
        z-index: 100;
    }
    .house-header.sticky {
        position: sticky;
        top: calc(var(--stack-index) * 1.75rem);
    }

    .house-name {
        margin: 0;
        flex: 0 0 auto;
        min-width: 4rem;
        display: flex;
        align-items: baseline;
        gap: 0.5rem;
        font-size: 1rem;
    }
    .house-name.clickable { cursor: pointer; }
    .house-name.clickable:hover { opacity: 0.7; }
    .todo-count {
        font-size: 0.7em;
        opacity: 0.5;
        margin-left: auto;
    }

    .house-nav {
        flex: 0 0 auto;
        position: relative;
        width: 0.1rem;
        align-self: stretch;
    }
    .arrow {
        position: absolute;
        left: 0;
        right: 0;
        text-align: center;
        font-size: 1rem;
        line-height: 1;
        cursor: pointer;
        opacity: 0.55;
        user-select: none;
    }
    .arrow-up   { top: 0; }
    .arrow-down { bottom: 0; }
    .arrow:hover { opacity: 1; }
    .arrow.disabled { opacity: 0.15; cursor: default; }

    .kids-sep {
        font-size: 1.3em;
        opacity: 0.4;
        flex: 0 0 auto;
        align-self: center;
    }
    .house-kids {
        flex: 0 1 auto;
        min-width: 0;
        max-height: 1.5rem;
        display: flex;
        flex-direction: column;
        flex-wrap: wrap;
        align-content: center;
        gap: 0 0.75rem;
        overflow: hidden;
    }
    .kid {
        font-size: 0.85em;
        opacity: 0.7;
        cursor: pointer;
        white-space: nowrap;
        line-height: 1.1;
    }
    .kid:hover { opacity: 1; }

    .house-actions {
        flex: 1 1 auto;
        display: flex;
        justify-content: flex-end;
        min-width: 0;
    }
</style>