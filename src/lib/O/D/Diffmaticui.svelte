<script lang="ts">
// Diffmaticui.svelte — Diffmatic animated diff frontend.
//
//   Reads from H.ave via ob() — one $effect per beliefs cycle.
//
//   ave particles consumed:
//     {dm_toc:1}               sc.step_count, sc.intro
//     {dm_cursor:1}            sc.step_n, sc.loading
//     {dm_diff:1, side}        sc.rows, sc.label_l, sc.label_r  (side: prev|exp|next)
//     {dm_snap:1, step_n}      sc.got, sc.exp
//     {dm_step:1, step_n}      (still published by toc decode for the strip)
//
//   Animated diff:
//     diff_rows renders as a list of DiffRow items with spring-physics
//     positions. When the cursor moves, old rows animate out, new rows
//     in — each row independently (staggered by index).
//
//     A "pinned" row stays visually stable at its y position while
//     everything around it reflows. The user clicks a diff line to pin it.
//     Pinning is by identity (dm_identity of the line text) so the same
//     particle stays stable across step transitions.
//
//   Viewing modes (toggle buttons):
//     prev — step(n-1).got → step(n).got  [default on cursor advance]
//     exp  — exp vs got for current step
//     next — step(n).got → step(n+1).got  [pre-loaded lookahead]
//
//   Step strip: click to set cursor. Steps from ave/%dm_step:1.
//   Intro text: from ave/%dm_toc:1.sc.intro — shown at top.

import type { TheC } from "$lib/data/Stuff.svelte"
import type { House } from "$lib/O/Housing.svelte"
import { onMount }    from "svelte"

let { H }: { H: House } = $props()


// ── types ─────────────────────────────────────────────────────────────────

type DiffRow =
    | { kind: 'pair';       left: string; right: string; tag: 'same' | 'changed'; ops?: Array<[number,string]> }
    | { kind: 'left_only';  line: string }
    | { kind: 'right_only'; line: string }
    | { kind: 'squish';     count: number }

type DmStep    = { n: number, dige: string, ok: boolean }
type DmDiff    = { rows: DiffRow[], label_l: string, label_r: string }
type ViewMode  = 'prev' | 'exp' | 'next'


// ── reactive state from H.ave ─────────────────────────────────────────────

let intro       = $state('')
let step_count  = $state(0)
let cursor_n    = $state<number | null>(null)
let cursor_load = $state(true)
let dm_steps    = $state<DmStep[]>([])
let diffs       = $state<Record<string, DmDiff>>({})   // keyed by side

$effect(() => {
    // one read gate — fires once per settled beliefs cycle
    const toc_p    = H.ave.ob({ dm_toc:    1 })[0] as TheC | undefined
    const cursor_p = H.ave.ob({ dm_cursor: 1 })[0] as TheC | undefined
    const diff_ps  = H.ave.ob({ dm_diff:   1 })    as TheC[]
    const step_ps  = H.ave.ob({ dm_step:   1 })    as TheC[]

    intro      = (toc_p?.sc.intro    as string) ?? ''
    step_count = (toc_p?.sc.step_count as number) ?? 0

    cursor_n    = (cursor_p?.sc.step_n  as number | undefined) ?? null
    cursor_load = !!(cursor_p?.sc.loading ?? true)

    dm_steps = step_ps
        .map(p => ({ n: p.sc.step_n as number, dige: (p.sc.dige as string) ?? '', ok: !!p.sc.ok }))
        .sort((a, b) => a.n - b.n)

    const next_diffs: Record<string, DmDiff> = {}
    for (const p of diff_ps) {
        const side = p.sc.side as string
        next_diffs[side] = {
            rows:    (p.sc.rows    as DiffRow[]) ?? [],
            label_l: (p.sc.label_l as string)   ?? '',
            label_r: (p.sc.label_r as string)   ?? '',
        }
    }
    diffs = next_diffs
})


// ── view mode ─────────────────────────────────────────────────────────────

let mode = $state<ViewMode>('prev')

let active_diff = $derived(diffs[mode] ?? null)
let raw_rows    = $derived(active_diff?.rows ?? [])


// ── pinned line ───────────────────────────────────────────────────────────
//
//   Clicking a diff line pins it by identity.  The pinned identity floats
//   the row to a stable visual position; surrounding rows animate past it.

let pinned_id = $state<string | null>(null)

function line_identity(line: string): string | null {
    return H.dm_identity(line)
}

function row_line(row: DiffRow): string {
    if (row.kind === 'squish') return ''
    if (row.kind === 'pair')   return row.right || row.left
    return (row as any).line ?? ''
}

function toggle_pin(row: DiffRow) {
    const id = line_identity(row_line(row))
    if (!id) return
    pinned_id = pinned_id === id ? null : id
}

function row_pinned(row: DiffRow): boolean {
    if (!pinned_id || row.kind === 'squish') return false
    return line_identity(row_line(row)) === pinned_id
}


// ── animated rows ─────────────────────────────────────────────────────────
//
//   Each row has a spring-y target position.  When raw_rows changes, we
//   diff the old layout against the new by identity, so stable rows animate
//   to their new y rather than popping.  New rows fade in, removed rows fade out.
//
//   The pinned row is exempt from position animation — it stays at its
//   current y while the target list is derived without it, then re-inserted
//   at the same pixel position.  Layout rows around it shift to accommodate.

const ROW_H    = 19    // px per row (matches CSS line-height)
const SPRING_K = 0.14  // spring constant — higher = snappier
const FADE_DUR = 300   // ms for enter/exit opacity transitions

type AnimRow = {
    key:     string    // unique stable key
    row:     DiffRow
    y:       number    // current animated y
    ty:      number    // target y
    opacity: number
    t_op:    number    // target opacity (1=visible, 0=removing)
    pinned:  boolean
}

let anim_rows    = $state<AnimRow[]>([])
let anim_handle: number | null = null

// Recompute target layout whenever raw_rows changes
$effect(() => {
    const next_rows = raw_rows
    if (!next_rows.length) { anim_rows = []; return }

    // build new layout, matching by identity where possible
    const pinned_ar = anim_rows.find(ar => ar.pinned)
    const pin_id    = pinned_id   // read from state

    const prev_by_key = new Map(anim_rows.map(ar => [ar.key, ar]))

    // assign stable keys: squish rows by index, data rows by identity or index
    let target_y = 0
    const next_ars: AnimRow[] = []

    for (let i = 0; i < next_rows.length; i++) {
        const row = next_rows[i]
        const id  = row.kind !== 'squish' ? (line_identity(row_line(row)) ?? `idx:${i}`) : `sq:${i}`
        const is_pinned = pin_id != null && id === pin_id

        // if pinned, its y stays wherever the old animrow was
        const old       = prev_by_key.get(id)
        const start_y   = old?.y ?? target_y
        const start_op  = old?.opacity ?? 0   // new rows fade in

        next_ars.push({
            key:     id,
            row,
            y:       is_pinned ? (pinned_ar?.y ?? target_y) : start_y,
            ty:      target_y,
            opacity: start_op,
            t_op:    1,
            pinned:  is_pinned,
        })
        target_y += ROW_H
    }

    // mark removed rows (in old but not in next) for fade-out
    for (const ar of anim_rows) {
        if (!next_ars.find(n => n.key === ar.key)) {
            next_ars.push({ ...ar, t_op: 0 })
        }
    }

    anim_rows = next_ars
    if (!anim_handle) anim_handle = requestAnimationFrame(anim_tick)
})

function anim_tick() {
    let any_moving = false
    const still_alive: AnimRow[] = []

    for (const ar of anim_rows) {
        // position spring (skip for pinned)
        if (!ar.pinned) {
            const dy = ar.ty - ar.y
            if (Math.abs(dy) > 0.3) { ar.y += dy * SPRING_K; any_moving = true }
            else ar.y = ar.ty
        }
        // opacity spring
        const do_ = ar.t_op - ar.opacity
        if (Math.abs(do_) > 0.005) { ar.opacity += do_ * 0.12; any_moving = true }
        else ar.opacity = ar.t_op

        // drop rows that are fully faded out
        if (ar.t_op === 0 && ar.opacity < 0.01) continue
        still_alive.push(ar)
    }

    anim_rows = still_alive
    if (any_moving) anim_handle = requestAnimationFrame(anim_tick)
    else            anim_handle = null
}

onMount(() => () => { if (anim_handle) cancelAnimationFrame(anim_handle) })

// container height = max of all row y positions
let list_h = $derived(
    anim_rows.length
        ? Math.max(...anim_rows.map(ar => ar.y + ROW_H)) + 8
        : 48
)


// ── cursor movement ────────────────────────────────────────────────────────

function go_to_step(n: number) {
    const w = dm_w()
    if (!w) return
    H.dm_set_cursor(w, n)
}

function dm_w(): TheC | undefined {
    for (const A of H.o({ A: 1 }) as TheC[]) {
        const w = A.o({ w: 1 })[0] as TheC | undefined
        if (w?.c.toc_loaded) return w
    }
    return undefined
}

// ── auto-advance ──────────────────────────────────────────────────────────
//
//   Once showing is ready and the user hasn't interacted, slowly walk
//   forward — one step every AUTO_MS ms.  Any click or key resets the timer.
//   Pauses at the last step.

const AUTO_MS   = 4200
let auto_timer: ReturnType<typeof setTimeout> | null = null
let user_acted  = $state(false)

function reset_auto() {
    if (auto_timer) clearTimeout(auto_timer)
    auto_timer = null
    user_acted = true
    // restart after a longer pause following user interaction
    auto_timer = setTimeout(tick_auto, AUTO_MS * 2)
}

function tick_auto() {
    auto_timer = null
    if (!cursor_n) return
    const idx = dm_steps.findIndex(s => s.n === cursor_n)
    if (idx < 0 || idx >= dm_steps.length - 1) return
    go_to_step(dm_steps[idx + 1].n)
    auto_timer = setTimeout(tick_auto, AUTO_MS)
}

// start auto-advance once toc loads
$effect(() => {
    if (!step_count || auto_timer) return
    auto_timer = setTimeout(tick_auto, AUTO_MS * 1.5)
    return () => { if (auto_timer) clearTimeout(auto_timer) }
})

// ── keyboard nav ──────────────────────────────────────────────────────────

function handle_key(e: KeyboardEvent) {
    if (!cursor_n) return
    const idx = dm_steps.findIndex(s => s.n === cursor_n)
    if (e.key === 'ArrowRight' && idx < dm_steps.length - 1) {
        e.preventDefault(); reset_auto(); go_to_step(dm_steps[idx + 1].n)
    } else if (e.key === 'ArrowLeft' && idx > 0) {
        e.preventDefault(); reset_auto(); go_to_step(dm_steps[idx - 1].n)
    } else if (e.key === 'p') {
        e.preventDefault(); reset_auto()
        mode = mode === 'prev' ? 'exp' : mode === 'exp' ? 'next' : 'prev'
    } else if (e.key === 'Escape') {
        pinned_id = null
    }
}
</script>

<!-- ═══════════════════════════════════════════════════════════════════════ -->
<div class="dm" tabindex="0" onkeydown={handle_key} onfocus={() => {}}>

    <!-- intro ──────────────────────────────────────────────────────────── -->
    {#if intro}
        <div class="dm-intro">
            {intro}
            {#if !user_acted}<span class="dm-auto">auto ▶</span>{/if}
        </div>
    {:else}
        <div class="dm-intro loading">loading story…</div>
    {/if}

    <!-- step strip ─────────────────────────────────────────────────────── -->
    {#if dm_steps.length > 0}
        <div class="dm-strip">
            {#each dm_steps as s (s.n)}
                {@const on = s.n === cursor_n}
                <button class="dm-pip"
                        class:ok={s.ok}
                        class:on
                        class:loading={on && cursor_load}
                        onclick={() => { reset_auto(); go_to_step(s.n) }}
                        title="step {s.n}  {s.dige.slice(0,7)}{s.ok ? '' : ' ✗'}">
                    {s.n}
                </button>
            {/each}
        </div>
    {/if}

    <!-- view mode + label ──────────────────────────────────────────────── -->
    {#if cursor_n != null}
        <div class="dm-bar">
            <button class="dm-mode" class:on={mode==='prev'} onclick={() => { reset_auto(); mode='prev' }}>prev</button>
            <button class="dm-mode" class:on={mode==='exp'}  onclick={() => { reset_auto(); mode='exp' }} >exp</button>
            <button class="dm-mode" class:on={mode==='next'} onclick={() => { reset_auto(); mode='next' }}
                    disabled={!diffs['next']}>next</button>
            {#if active_diff}
                <span class="dm-label">{active_diff.label_l} → {active_diff.label_r}</span>
            {:else}
                <span class="dm-label loading">computing diff…</span>
            {/if}
            {#if pinned_id}
                <button class="dm-unpin" onclick={() => pinned_id = null}>unpin ×</button>
            {/if}
        </div>
    {/if}

    <!-- animated diff ──────────────────────────────────────────────────── -->
    {#if anim_rows.length > 0}
        <div class="dm-diff" style="height:{list_h}px">
            {#each anim_rows as ar (ar.key)}
                {@const hi = ar.pinned}
                {@const row = ar.row}
                <div class="dm-row {row.kind}"
                     class:pinned={hi}
                     class:changed={row.kind === 'pair' && row.tag === 'changed'}
                     style:transform="translateY({ar.y}px)"
                     style:opacity={ar.opacity}
                     onclick={() => { reset_auto(); toggle_pin(row) }}>
                    {#if row.kind === 'squish'}
                        <span class="dm-squish">… {row.count} unchanged</span>
                    {:else if row.kind === 'pair'}
                        {@render diff_row(row.left, row.right, row.tag === 'changed')}
                    {:else if row.kind === 'left_only'}
                        {@render gone_row(row.line)}
                    {:else if row.kind === 'right_only'}
                        {@render neu_row(row.line)}
                    {/if}
                </div>
            {/each}
        </div>
    {:else if cursor_load}
        <div class="dm-hint">loading…</div>
    {:else if cursor_n != null}
        <div class="dm-hint">no diff — snaps identical</div>
    {/if}

</div>

<!-- ── snippets ──────────────────────────────────────────────────────────── -->

{#snippet line_span(line: string)}
    {@const ind = line.match(/^ */)?.[0] ?? ''}
    {@const tab = line.indexOf('\t')}
    {@const obj = tab > ind.length ? line.slice(ind.length, tab) : ''}
    {@const str = tab >= 0 ? line.slice(tab + 1) : line.trimStart()}
    <span class="ind">{ind}</span>{#if obj}<span class="obj">{obj}</span> {/if}<span class="str">{str}</span>
{/snippet}

{#snippet diff_row(left: string, right: string, changed: boolean)}
    <div class="dm-2col">
        <div class="dm-side" class:changed>{@render line_span(left)}</div>
        <div class="dm-side" class:changed>{@render line_span(right)}</div>
    </div>
{/snippet}

{#snippet gone_row(line: string)}
    <div class="dm-2col">
        <div class="dm-side gone">{@render line_span(line)}</div>
        <div class="dm-side dm-gap"></div>
    </div>
{/snippet}

{#snippet neu_row(line: string)}
    <div class="dm-2col">
        <div class="dm-side dm-gap"></div>
        <div class="dm-side neu">{@render line_span(line)}</div>
    </div>
{/snippet}

<style>
.dm {
    --bg:    #111214;
    --surf:  #181a1e;
    --bord:  #282b33;
    --text:  #c2c4ca;
    --dim:   #5c5f6a;
    --amber: #d4a84b;
    --green: #57c268;
    --red:   #cc4e4a;
    --blue:  #4e8cc7;
    --pin:   rgba(212,168,75,0.18);
    display:        flex;
    flex-direction: column;
    gap:            8px;
    background:     var(--bg);
    color:          var(--text);
    font-family:    'JetBrains Mono', 'Fira Mono', monospace;
    font-size:      12px;
    padding:        12px;
    min-height:     100%;
    box-sizing:     border-box;
    outline:        none;
}

/* auto indicator */
.dm-auto { float: right; font-size: 10px; color: var(--amber); opacity: 0.5; }

/* intro */
.dm-intro { font-size: 11px; color: var(--dim); padding: 2px 0 4px; border-bottom: 1px solid var(--bord); }
.dm-intro.loading { font-style: italic; }

/* strip */
.dm-strip { display: flex; flex-wrap: wrap; gap: 3px; }
.dm-pip {
    background: var(--surf); border: 1px solid var(--bord);
    color: var(--dim); width: 26px; height: 20px;
    font: 10px/1 inherit; border-radius: 2px; cursor: pointer; padding: 0;
    transition: border-color .1s, color .1s, background .1s;
}
.dm-pip:hover     { border-color: #44475a; color: var(--text); }
.dm-pip.ok        { color: #4a7a4a; }
.dm-pip.on        { border-color: var(--blue)!important; background: rgba(78,140,199,.15); color: var(--blue); }
.dm-pip.on.loading { border-color: var(--amber)!important; color: var(--amber); }

/* bar */
.dm-bar { display: flex; align-items: center; gap: 6px; }
.dm-mode {
    background: none; border: 1px solid var(--bord); color: var(--dim);
    padding: 2px 7px; border-radius: 2px; cursor: pointer; font: 11px/1 inherit;
    transition: all .1s;
}
.dm-mode:hover   { border-color: #555; color: var(--text); }
.dm-mode.on      { border-color: var(--blue); color: var(--blue); background: rgba(78,140,199,.1); }
.dm-mode:disabled { opacity: .3; cursor: default; }
.dm-label        { color: var(--dim); font-size: 10px; margin-left: 4px; }
.dm-label.loading { color: var(--amber); }
.dm-unpin        { margin-left: auto; background: none; border: 1px solid var(--amber); color: var(--amber); padding: 1px 6px; border-radius: 2px; cursor: pointer; font: 10px/1 inherit; }

/* diff container — position:relative so rows can be absolute */
.dm-diff {
    position:   relative;
    overflow:   hidden;
    transition: height 0.4s cubic-bezier(.4,0,.2,1);
    border:     1px solid var(--bord);
    border-radius: 3px;
    background: var(--surf);
}

/* individual animated row — absolute so spring can move it */
.dm-row {
    position:    absolute;
    left:        0; right: 0;
    height:      19px;
    cursor:      pointer;
    transition:  background .1s;
    will-change: transform, opacity;
    user-select: none;
}
.dm-row:hover       { background: rgba(255,255,255,.04); }
.dm-row.pinned      { background: var(--pin)!important; z-index: 2; }
.dm-row.pinned::before {
    content:    '📌';
    position:   absolute; right: 6px; top: 1px;
    font-size:  10px; opacity: .6;
}

/* two-column layout inside each row */
.dm-2col { display: grid; grid-template-columns: 1fr 1fr; height: 100%; }
.dm-side { padding: 0 8px; overflow: hidden; white-space: pre; line-height: 19px; font-size: 11px; }
.dm-side.changed { background: rgba(212,168,75,.08); }
.dm-side.gone    { background: rgba(200,55,55,.12); color: #d07070; }
.dm-side.neu     { background: rgba(80,190,95,.10); color: #5ec870; }
.dm-gap          { background: rgba(255,255,255,.015); }

/* squish */
.dm-squish { padding: 0 8px; color: var(--dim); font-size: 10px; line-height: 19px; font-style: italic; }

/* hint */
.dm-hint { color: var(--dim); font-size: 11px; padding: 8px; font-style: italic; }

/* line parts */
.ind { display: inline-block; }
.obj { color: #6e6898; margin-right: 2px; }
.str { color: var(--text); }
</style>
