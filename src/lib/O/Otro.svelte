<script lang="ts">
    // Otro
    import Ghost    from "$lib/O/Ghost.svelte"
    import { House, Work, register_class } from "$lib/O/Housing.svelte"
    import Actions from "$lib/O/ui/Actions.svelte"
    import Stuffing from "$lib/data/Stuffing.svelte"
    import { Travel } from "$lib/mostly/Selection.svelte";
    import StoryRun from "./ui/StoryRun.svelte";

    // A Work subclass with a withitall() method
    class WithItAll extends Work {
        override async start() {
            console.log(`WithItAll ${this.name} starting`)
            this.started = true
        }
        async withitall(A, w, e, AT, wT) {
            console.log(`WithItAll.withitall() called! from ${e?.sc.from_name}`, e?.sc)
        }
    }
    register_class('w', WithItAll)

    //#region H:Mundo
    // ── all House construction inside $effect ─────────────────────────────────
    let H: House = $state(null!)
    let R
    $effect(() => {
        H = new House({ name: 'Mundo' })
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

        setTimeout(() => {
            houses = H.all_House
        },1)

        setTimeout(() => {
            // S.elvisto(S, 'think')
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
        H.elvisto(H, 'think')
    }

    function upthings() {
        H.stashed.things ||= 0
        H.stashed.things += 1
        H.elvisto(H, 'think')
    }


    
    
    //#region naviscroll
    const HEADER_HEIGHT_REM = 1.75 // keep in sync with CSS

    function remToPx(rem: number) {
        return rem * parseFloat(getComputedStyle(document.documentElement).fontSize)
    }

    // direct children of house in the current houses list
    function childrenOf(house) {
        const ip = house?.c?.ip
        if (!ip) return []
        const depth = ip.split('_').length
        return houses.filter(h =>
            h.c?.ip?.startsWith(ip + '_')
            && h.c.ip.split('_').length === depth + 1
        )
    }

    function scrollToHouseIdx(idx: number) {
        if (idx < 0 || idx >= houses.length) return
        const house = houses[idx]
        const header = document.getElementById(`house-${house.c.ip}`)
        if (!header) return

        const headerPx = remToPx(HEADER_HEIGHT_REM)
        const sticky_before = houses.slice(0, idx)
            .filter(h => h?.actions?.length > 0).length
        const this_is_sticky = house?.actions?.length > 0

        if (this_is_sticky) {
            const content = header.nextElementSibling as HTMLElement | null
            if (!content) return
            const contentTop = content.getBoundingClientRect().top + window.scrollY
            window.scrollTo({
                top: contentTop - (sticky_before + 1) * headerPx,
                behavior: 'smooth',
            })
        } else {
            const headerTop = header.getBoundingClientRect().top + window.scrollY
            window.scrollTo({
                top: headerTop - sticky_before * headerPx,
                behavior: 'smooth',
            })
        }
    }

    function scrollToHouseIp(ip: string) {
        scrollToHouseIdx(houses.findIndex(h => h.c?.ip === ip))
    }
    //#region each house
</script>

{#each houses as house, i (house.c.ip)}
    {@const hasActions = house?.actions?.length > 0}
    {@const stickyIndex = houses.slice(0, i).filter(h => h?.actions?.length).length}
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
                <Actions N={house.actions} />
            </div>
        {/if}
    </div>
    {#each house.UIs ?? [] as uiC (uiC.sc.UI)}
        <svelte:component this={uiC.sc.component} H={house} />
    {/each}
    {#if house.stashed}
        <Stuffing mem={house.imem('current')} stuff={house} M={house} />
    {/if}
{/each}

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
        z-index: 10;
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