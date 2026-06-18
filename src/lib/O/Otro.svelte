<script lang="ts">
    // Otro
    import Ghost    from "$lib/O/Ghost.svelte"
    import { House } from "$lib/O/Housing.svelte"
    import { keyser } from "$lib/data/Stuff.svelte"
    import Actions from "$lib/O/ui/Actions.svelte"
    import Stuffing from "$lib/data/Stuffing.svelte"
    import { onDestroy } from "svelte";
    import NaviScroll from "./ui/NaviScroll.svelte";
    import { boot_param } from "$lib/boot";

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
    //  ?B=Editron boots the editor as a Book, ?B=Peregrination the test runner, etc.  Auto reads
    //   H.c.book on first boot and activates it (see Auto.svelte).  ?W=<Waft> rides alongside for
    //    the Book that opens one.  Stamped on the LOCAL `h`, never inside the $effect — same
    //     self-retrigger trap as toplevel above.
    const book = boot_param('B')
    $effect(() => {
        const h = new House({ name: 'Mundo' })
        h.c.toplevel = toplevel
        if (book) h.c.book = book
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

    onDestroy(() => {
        H?.stop()
    })

    function upthings() {
        H.stashed.things ||= 0
        H.stashed.things += 1
        H.i_elvisto(H, 'think')
    }
</script>

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

                {#if hasActions}
                    <div class="house-actions">
                        <Actions N={house.actions.ob({ action: 1 })} />
                    </div>
                {/if}
            </div>
            {#each house.UIs.ob({ UI: 1 }) as uiC (keyser(uiC.sc))}
                <svelte:component this={uiC.sc.component} H={house} />
            {/each}
            {#if house.stashed}
                <Stuffing mem={house.imem('current')} stuff={house} H={house} M={house} />
            {/if}
        {/each}
    {/snippet}
</NaviScroll>

{#if H?.stashed}
    <button onclick={upthings}>upthings ({H.stashed?.things ?? 0})</button>
    <button onclick={go_busily}>think</button>
{/if}

{#if H}
    <Ghost {H} />
{/if}

<style>
    .ungood { color: red; }

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