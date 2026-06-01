<script lang="ts">
    // NaviCado — What-navigation toolbar above the DocMinimap capsule strip.
    //
    // ── What this is ─────────────────────────────────────────────────────────
    //
    //   A small toolbar that renders navigation controls for the active
    //   Understanding (%LE).  Sits above the Pmirror capsule strip in
    //   DocMinimap; receives %LE as a prop via Languinio and uses the
    //   LE_what_* helpers to know its position in the Waft tree.
    //
    //   The button slots (avocados) are generalised: NaviCado accepts Svelte
    //   snippets for each slot so any caller can put anything button-shaped
    //   inside them.  The default render is the What-navigation arrow set.
    //
    // ── Particle source ───────────────────────────────────────────────────────
    //
    //   LE        — w:Lies/{LE:1}; same-object hold via Languinio/%LE.
    //   LE.sc.target — the %What currently checked out.
    //   target.c.up  — back-ref chain to Waft (set by Lies_stamp_up).
    //
    // ── Buttons ───────────────────────────────────────────────────────────────
    //
    //   ↑   up       — move to parent %What.  Ghosted at depth 0 (top level).
    //   ←   prev     — step to previous sibling %What.  Ghosted at first sibling.
    //   →   next     — step to next sibling %What.  Ghosted at last sibling.
    //   ↘   branch   — create a new sibling %What after current, step into it.
    //   ↓   dive     — create a child %What inside current, step into it.
    //                  < branch and dive are Chunk 4c; buttons render but are ghosted.
    //
    // ── Slot generalisation ───────────────────────────────────────────────────
    //
    //   Each button position is a Svelte snippet slot.  DocMinimap passes no
    //   custom snippets — the defaults render the What-nav set.  Future callers
    //   can pass their own to reuse this toolbar layout for other navigation
    //   contexts (e.g. a bookmark navigator, a Point-set browser).
    //
    //   The avocado metaphor: each slot is a seed-shaped receptacle; the
    //   rendered snippet is the seed.  Empty seeds (no navigation target) are
    //   shown as ghost-opacity placeholders so the toolbar width stays stable.
    //
    // ── Reactivity ────────────────────────────────────────────────────────────
    //
    //   LE is a direct TheC ref (same object as w:Lies/%LE).  Reads LE.vers to
    //   subscribe — any LE_arm/LE_pull bumps it.  target is derived from
    //   LE.sc.target; siblings and depth re-derive on each target change.

    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import type { Snippet } from "svelte"

    let { H, LE, slot_up, slot_prev, slot_next, slot_branch, slot_dive }: {
        H:           House
        LE:          TheC | undefined
        // Snippet slots — each receives { ghosted: boolean, onclick: () => void }
        slot_up?:     Snippet<[{ ghosted: boolean, onclick: () => void }]>
        slot_prev?:   Snippet<[{ ghosted: boolean, onclick: () => void }]>
        slot_next?:   Snippet<[{ ghosted: boolean, onclick: () => void }]>
        slot_branch?: Snippet<[{ ghosted: boolean, onclick: () => void }]>
        slot_dive?:   Snippet<[{ ghosted: boolean, onclick: () => void }]>
    } = $props()

    // ── reactive derivation from LE ───────────────────────────────────────────

    let target   = $derived(LE && (void (LE as any).vers) && (LE.sc.target as TheC | undefined))
    let depth    = $derived(target ? (H as any).LE_what_depth(target) as number : -1)
    let has_prev = $derived(target ? !!(H as any).LE_what_prev(target) : false)
    let has_next = $derived(target ? !!(H as any).LE_what_next(target) : false)
    let has_up   = $derived(depth > 0)

    // ── nav actions ──────────────────────────────────────────────────────────

    function go_up() {
        if (!target) return
        const parent = (H as any).LE_what_parent(target) as TheC | undefined
        if (!parent) return
        H.i_elvisto('Lies/Lies', 'Lies_cursor_what', { what: parent })
    }

    function go_prev() {
        if (!target) return
        const prev = (H as any).LE_what_prev(target) as TheC | undefined
        if (!prev) return
        H.i_elvisto('Lies/Lies', 'Lies_cursor_what', { what: prev })
    }

    function go_next() {
        if (!target) return
        const next = (H as any).LE_what_next(target) as TheC | undefined
        if (!next) return
        H.i_elvisto('Lies/Lies', 'Lies_cursor_what', { what: next })
    }

    function go_branch() {
        // < Chunk 4c — create sibling %What after current and step into it.
    }

    function go_dive() {
        // < Chunk 4c — create child %What inside current and step into it.
    }

    // Label for the current What — shown in the middle of the toolbar.
    // Falls back to the path stem when target is a %Doc (no .label or .What on sc).
    let what_label = $derived(
        target
            ? ((target.sc as any).label as string | undefined)
              ?? ((target.sc as any).What as string | undefined)
              ?? ((target.sc as any).path as string | undefined)?.split('/').pop()
              ?? '?'
            : ''
    )
</script>

{#if target}target!{/if}
{#if LE && target}
<div class="nvc-bar">

    <!-- ↑ up — ghosted at top level -->
    <div class="nvc-seed" class:nvc-ghost={!has_up}>
        {#if slot_up}
            {@render slot_up({ ghosted: !has_up, onclick: go_up })}
        {:else}
            <button class="nvc-btn" class:nvc-ghosted={!has_up}
                    disabled={!has_up} onclick={go_up} title="Up to parent What">↑</button>
        {/if}
    </div>

    <!-- ← prev -->
    <div class="nvc-seed" class:nvc-ghost={!has_prev}>
        {#if slot_prev}
            {@render slot_prev({ ghosted: !has_prev, onclick: go_prev })}
        {:else}
            <button class="nvc-btn" class:nvc-ghosted={!has_prev}
                    disabled={!has_prev} onclick={go_prev} title="Previous What">←</button>
        {/if}
    </div>

    <!-- current What label — mid-strip breadcrumb -->
    <div class="nvc-label" title="Current What: {what_label}">{what_label}</div>

    <!-- → next -->
    <div class="nvc-seed" class:nvc-ghost={!has_next}>
        {#if slot_next}
            {@render slot_next({ ghosted: !has_next, onclick: go_next })}
        {:else}
            <button class="nvc-btn" class:nvc-ghosted={!has_next}
                    disabled={!has_next} onclick={go_next} title="Next What">→</button>
        {/if}
    </div>

    <!-- ↘ branch — ghosted until Chunk 4c -->
    <div class="nvc-seed nvc-ghost">
        {#if slot_branch}
            {@render slot_branch({ ghosted: true, onclick: go_branch })}
        {:else}
            <button class="nvc-btn nvc-ghosted" disabled onclick={go_branch} title="Branch (↘ new sibling What) — coming soon">↘</button>
        {/if}
    </div>

    <!-- ↓ dive — ghosted until Chunk 4c -->
    <div class="nvc-seed nvc-ghost">
        {#if slot_dive}
            {@render slot_dive({ ghosted: true, onclick: go_dive })}
        {:else}
            <button class="nvc-btn nvc-ghosted" disabled onclick={go_dive} title="Dive (↓ new child What) — coming soon">↓</button>
        {/if}
    </div>

</div>
{/if}

<style>
    /* NaviCado toolbar — sits above the capsule strip in DocMinimap. */
    .nvc-bar {
        display:         flex;
        align-items:     center;
        gap:             2px;
        padding:         2px 4px;
        background:      rgba(30, 35, 42, 0.85);
        border-bottom:   1px solid rgba(255,255,255,0.06);
        font-size:       11px;
        min-height:      22px;
    }

    /* Each seed slot holds one button or snippet; fixed width keeps bar stable. */
    .nvc-seed {
        display:     flex;
        align-items: center;
        min-width:   18px;
    }

    .nvc-btn {
        background:    transparent;
        border:        1px solid rgba(255,255,255,0.12);
        border-radius: 3px;
        color:         #9aa5b4;
        cursor:        pointer;
        font-size:     11px;
        line-height:   1;
        padding:       1px 4px;
        transition:    color 0.1s, border-color 0.1s;
    }

    .nvc-btn:hover:not(:disabled) {
        color:        #fff;
        border-color: rgba(255,255,255,0.3);
    }

    /* Ghosted: present but non-interactive — stable width, invisible intent. */
    .nvc-btn.nvc-ghosted,
    .nvc-ghost .nvc-btn {
        color:        rgba(154, 165, 180, 0.25);
        border-color: rgba(255,255,255,0.04);
        cursor:       default;
    }

    /* Current What label — breadcrumb in the middle of the bar. */
    .nvc-label {
        flex:          1;
        text-align:    center;
        color:         #6b7a8d;
        font-size:     10px;
        overflow:      hidden;
        text-overflow: ellipsis;
        white-space:   nowrap;
        padding:       0 4px;
        letter-spacing: 0.02em;
    }
</style>
