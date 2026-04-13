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
</script>

<h3>Here we Are</h3>

{#each houses as house, i (house.name)}
    {@const hasActions = house?.actions?.length > 0}
    {@const stickyIndex = houses.slice(0, i).filter(h => h?.actions?.length).length}
    <div class="house-header" class:sticky={hasActions} style="--stack-index: {stickyIndex};">
        <h2 class="house-name">
            {house.name}
            {#if !house.started}<span class='ungood'>off</span>{/if}
            <span class="todo-count">{house.todo.length || ''}</span>
        </h2>
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
    .ungood {
        color: red;
    }
    .house-header {
        display: flex;
        align-items: center;
        gap: 1rem;
        background: var(--background, #5f2222);
        padding: 0.25rem 0.5rem;
        z-index: 10;
    }
    .house-header.sticky {
        position: sticky;
        /* each sticky header parks below the previous. tweak 2.5rem to your header height. */
        top: calc(var(--stack-index) * 2.5rem);
    }
    .house-name {
        margin: 0;
        flex: 0 0 auto;
        min-width: 8rem;
        display: flex;
        align-items: baseline;
        gap: 0.5rem;
    }
    .todo-count {
        font-size: 0.8em;
        opacity: 0.6;
        margin-left: auto;
        padding-left: 0.5rem;
    }
    .house-actions {
        flex: 1 1 auto;
        display: flex;
        justify-content: flex-end;
        min-width: 0;
    }
</style>