<script lang="ts">
    // NaviCado — What-navigation toolbar above the DocMinimap capsule strip.
    //
    // ── What this is ─────────────────────────────────────────────────────────
    //
    //   Toolbar for the active Understanding (%LE) plus the transport bar for
    //   req:desire playback.  Sits above the Pmirror capsule strip in DocMinimap.
    //
    // ── Particle sources ──────────────────────────────────────────────────────
    //
    //   LE              — w:Lies/{LE:1}; same-object hold via Languinio/%LE.
    //   ave/%desire     — reactive signal; c.desire / c.completion carry the
    //                     live req particles; .sc.playing:0|1 drives the timer.
    //
    // ── Buttons ───────────────────────────────────────────────────────────────
    //
    //   ↑   up       — parent %What.  Ghosted at depth 0.
    //   ←   prev     — previous sibling.  Ghosted at first.
    //   →   next     — next sibling.  Ghosted at last.
    //   ↘   branch   — < Chunk 4c; ghosted.
    //   ↓   dive     — < Chunk 4c; ghosted.
    //
    //   Transport bar (below nav row, shown when req:desire is active):
    //   ‖/▶  pause/play toggle   — e_Lies_desire_pause / e_Lies_desire_play
    //   →    step                — e_Lies_desire_step (also fired by UI timer)
    //
    // ── Auto-advance ─────────────────────────────────────────────────────────
    //
    //   UI-side setInterval at 4s when playing:1.  Fires e_Lies_desire_step
    //   each tick; Lies pauses when the Waft is exhausted.  Not a Story ttlilt —
    //   purely a presentation timer that doesn't hold Story open.

    import { onDestroy } from "svelte"
    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import type { Snippet } from "svelte"

    const PLAY_INTERVAL_MS = 4000   // advance every 4s when playing

    let { H, LE, slot_up, slot_prev, slot_next, slot_branch, slot_dive }: {
        H:           House
        LE:          TheC | undefined
        slot_up?:     Snippet<[{ ghosted: boolean, onclick: () => void }]>
        slot_prev?:   Snippet<[{ ghosted: boolean, onclick: () => void }]>
        slot_next?:   Snippet<[{ ghosted: boolean, onclick: () => void }]>
        slot_branch?: Snippet<[{ ghosted: boolean, onclick: () => void }]>
        slot_dive?:   Snippet<[{ ghosted: boolean, onclick: () => void }]>
    } = $props()

    // ── reactive derivation from LE ───────────────────────────────────────────

    // LE.vers is always ≥ 1 (truthy) — safe chain link that registers the reactive read.
    let target   = $derived(LE && LE.vers && LE.sc.target as TheC | undefined)
    let depth    = $derived(target ? (H as any).LE_what_depth(target) as number : -1)
    let has_prev = $derived(target ? !!(H as any).LE_what_prev(target) : false)
    let has_next = $derived(target ? !!(H as any).LE_what_next(target) : false)
    let has_up   = $derived(depth > 0)

    // ── desire / transport ────────────────────────────────────────────────────

    let desire_sig  = $derived(H.ave.ob({ desire: 1 })[0] as TheC | undefined)
    let completion  = $derived.by(() => {
        void desire_sig?.vers
        return desire_sig?.c.completion as TheC | undefined
    })
    let is_playing  = $derived.by(() => {
        void completion?.vers
        return !!(completion?.sc.playing)
    })
    let has_desire  = $derived(!!desire_sig?.c.desire)

    // Auto-advance timer — fires e_Lies_desire_step every PLAY_INTERVAL_MS
    // while playing.  Managed imperatively so the interval is always in sync
    // with the is_playing derived.
    let _play_timer: ReturnType<typeof setInterval> | null = null

    $effect(() => {
        if (is_playing) {
            if (!_play_timer) {
                _play_timer = setInterval(() => {
                    H.i_elvisto('Lies/Lies', 'Lies_desire_step', {})
                }, PLAY_INTERVAL_MS)
            }
        } else {
            if (_play_timer) { clearInterval(_play_timer); _play_timer = null }
        }
    })

    onDestroy(() => {
        if (_play_timer) clearInterval(_play_timer)
    })

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

<!-- Transport bar — only when req:desire is active -->
{#if has_desire}
<div class="nvc-transport">
    <button class="nvc-t-btn" class:nvc-t-playing={is_playing}
            title={is_playing ? 'Pause' : 'Play'}
            onclick={() => H.i_elvisto('Lies/Lies', is_playing ? 'Lies_desire_pause' : 'Lies_desire_play', {})}>
        {is_playing ? '‖' : '▶'}
    </button>
    <button class="nvc-t-btn" title="Step to next What"
            onclick={() => H.i_elvisto('Lies/Lies', 'Lies_desire_step', {})}>→</button>
    <span class="nvc-t-label">{is_playing ? 'playing' : 'paused'}</span>
</div>
{/if}

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

    /* Transport bar — play/pause + step for req:desire playback. */
    .nvc-transport {
        display:       flex;
        align-items:   center;
        gap:           4px;
        padding:       2px 4px;
        background:    rgba(20, 25, 32, 0.9);
        border-bottom: 1px solid rgba(255,255,255,0.04);
        min-height:    18px;
    }

    .nvc-t-btn {
        background:    transparent;
        border:        1px solid rgba(255,255,255,0.1);
        border-radius: 3px;
        color:         #556678;
        cursor:        pointer;
        font-size:     10px;
        line-height:   1;
        padding:       1px 4px;
        transition:    color 0.1s;
    }
    .nvc-t-btn:hover { color: #9aa5b4; border-color: rgba(255,255,255,0.25); }
    .nvc-t-btn.nvc-t-playing { color: #7ab0c0; border-color: rgba(122,176,192,0.4); }

    .nvc-t-label {
        font-size:  9px;
        color:      #3a4555;
        font-style: italic;
        flex:       1;
    }
</style>
