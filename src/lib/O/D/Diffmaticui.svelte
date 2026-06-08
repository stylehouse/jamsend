<script lang="ts">
// Diffmaticui.svelte — Diffmatic animated diff frontend.
//
//   Reads from %Diffmatic in ave — the one container the worker enrolls, same
//     shape as %Languinio for Langui and %examining for Liesui.  A single
//     $effect drains it each settled beliefs cycle; the live %This particle is
//     read straight off the container so snap arrivals update the UI through
//     watch_c → container bump, with no serialised copy in between.
//
//   %Diffmatic
//     /%This:1                  live container; This/%Step:N are loaded steps.
//     /%toc:1                   sc.step_count, sc.intro
//     /%cursor:1                sc.step_n, sc.loading
//     /%diff:1,side             sc.rows, sc.label_l, sc.label_r
//
//   A %Step carries sc.got_snap, optionally sc.exp_snap, and sc.ok (only set
//     once an exp exists to compare).  Steps not yet loaded are absent from
//     %This — the strip shows them hollow, never alarmed.

import type { TheC }  from "$lib/data/Stuff.svelte"
import type { House } from "$lib/O/Housing.svelte"
import { onMount }    from "svelte"

let { H }: { H: House } = $props()


// ── types ─────────────────────────────────────────────────────────────────

type DiffRow =
    | { kind: 'pair';      left: string; right: string; tag: 'same' | 'changed'; ops?: any[] }
    | { kind: 'left_only'; line: string }
    | { kind: 'right_only';line: string }
    | { kind: 'squish';    count: number }

type DmDiff   = { rows: DiffRow[], label_l: string, label_r: string }
type ViewMode = 'prev' | 'exp' | 'next'

// ── reactive state from %Diffmatic ──────────────────────────────────────────

let intro      = $state('')
let step_count = $state(0)
let cursor_n   = $state<number | null>(null)
let loading    = $state(true)
let diffs      = $state<Record<string, DmDiff>>({})
let This       = $state<TheC | undefined>()

$effect(() => {
    // ob() tracks ave.version (the settled cycle) and the container bumps from
    //   watch_c when a snap lands mid-cycle — both wake this drain.
    const dm = H.ave.ob({ Diffmatic: 1 })[0] as TheC | undefined
    dm?.ob()
    if (!dm) return

    const toc_p    = dm.ob({ toc:    1 })[0] as TheC | undefined
    const cursor_p = dm.ob({ cursor: 1 })[0] as TheC | undefined
    const this_p   = dm.ob({ This:   1 })[0] as TheC | undefined
    this_p?.ob()   // track %This — %Step snaps arrive here

    This       = this_p
    intro      = (toc_p?.sc.intro      as string)         ?? ''
    step_count = (toc_p?.sc.step_count as number)         ?? 0
    cursor_n   = (cursor_p?.sc.step_n  as number | null)  ?? null
    loading    = !!(cursor_p?.sc.loading ?? true)

    const next: Record<string, DmDiff> = {}
    for (const p of dm.ob({ diff: 1 }) as TheC[]) {
        const side = p.sc.side as string
        next[side] = {
            rows:    (p.sc.rows    as DiffRow[]) ?? [],
            label_l: (p.sc.label_l as string)   ?? '',
            label_r: (p.sc.label_r as string)   ?? '',
        }
    }
    diffs = next
})

// step list: from toc's step_count (we know N steps exist) and which are loaded.
//   hollow: a step the toc knows but whose %Step has not arrived in %This yet.
type StepEntry = { n: number, loaded: boolean }

let step_entries = $derived.by((): StepEntry[] => {
    This?.ob()   // re-derive when %This changes
    const loaded = new Set(
        ((This?.o({ Step: 1 }) ?? []) as TheC[]).map(s => s.sc.Step as number)
    )
    const count = step_count || loaded.size
    return Array.from({ length: count }, (_, i) => ({
        n:      i + 1,
        loaded: loaded.has(i + 1),
    }))
})

function live_step(n: number): TheC | undefined {
    This?.ob()
    return This?.o({ Step: n })[0] as TheC | undefined
}


// ── view mode ───────────────────────────────────────────────────────────────

let mode        = $state<ViewMode>('prev')
let active_diff = $derived(diffs[mode] ?? null)
let raw_rows    = $derived(active_diff?.rows ?? [])


// ── pinned line ───────────────────────────────────────────────────────────
//
//   A pin holds a particle by its identity, so the pinned line stays put while
//     the rows around it flow — the identity is the thing that persists, even as
//     the same particle changes side or position between steps.

let pinned_id = $state<string | null>(null)

function row_line(row: DiffRow): string {
    if (row.kind === 'squish') return ''
    return (row as any).right ?? (row as any).left ?? (row as any).line ?? ''
}

function toggle_pin(row: DiffRow) {
    const id = H.dm_identity(row_line(row))
    if (!id) return
    pinned_id = pinned_id === id ? null : id
}


// ── animated rows ─────────────────────────────────────────────────────────
//
//   anim_rows is a plain array (NOT $state) so anim_tick writes never re-fire
//     the layout $effect.  anim_version ($state int) ticks each frame, and each
//     row folds it into its style string (--frame) so the row re-reads its own
//     mutated y|opacity every tick — reading anim_version only in the wrapping
//     {#if} updates the container but leaves the rows frozen at frame one.
//
//   key and pin_id are deliberately two different things:
//     pin_id   — the particle identity, what a pin matches on.
//     key      — unique per row, safe as the {#each} key even when two rows
//                share one identity, eg a %Waft removed on the left then
//                re-added on the right, which is the prev|exp diff that used
//                to crash on each_key_duplicate.

const ROW_H    = 19
const SPRING_K = 0.13

type AnimRow = {
    key:     string
    pin_id:  string | null
    row:     DiffRow
    y:       number; ty: number
    opacity: number; t_op: number
    pinned:  boolean
}

let anim_rows: AnimRow[]       = []
let anim_version               = $state(0)
let anim_handle: number | null = null
let prev_by_key                = new Map<string, AnimRow>()

$effect(() => {
    const next = raw_rows
    const pin  = pinned_id

    if (!next.length) {
        for (const ar of anim_rows) ar.t_op = 0
        if (!anim_handle) anim_handle = requestAnimationFrame(anim_tick)
        return
    }

    let ty = 0
    const next_ars: AnimRow[] = []
    const seen = new Map<string, number>()   // base → how many rows have claimed it

    for (let i = 0; i < next.length; i++) {
        const row    = next[i]
        const pin_id = row.kind !== 'squish' ? H.dm_identity(row_line(row)) : null
        const base   = pin_id ?? `idx:${i}`   // squish & undecodable rows key by position
        const nth    = seen.get(base) ?? 0; seen.set(base, nth + 1)
        const key    = nth ? `${base}#${nth}` : base
        const old    = prev_by_key.get(key)
        next_ars.push({
            key, pin_id, row,
            y:       old?.y ?? ty,
            ty,
            opacity: old?.opacity ?? 0,
            t_op:    1,
            pinned:  pin_id != null && pin_id === pin,
        })
        ty += ROW_H
    }

    // fade out rows that left
    for (const ar of anim_rows) {
        if (!next_ars.find(n => n.key === ar.key))
            next_ars.push({ ...ar, t_op: 0 })
    }

    anim_rows   = next_ars
    prev_by_key = new Map(next_ars.map(ar => [ar.key, ar]))
    if (!anim_handle) anim_handle = requestAnimationFrame(anim_tick)
})

function anim_tick() {
    let moving = false
    for (let i = anim_rows.length - 1; i >= 0; i--) {
        const ar = anim_rows[i]
        if (!ar.pinned) {
            const dy = ar.ty - ar.y
            if (Math.abs(dy) > 0.3) { ar.y += dy * SPRING_K; moving = true }
            else ar.y = ar.ty
        }
        const dop = ar.t_op - ar.opacity
        if (Math.abs(dop) > 0.005) { ar.opacity += dop * 0.12; moving = true }
        else ar.opacity = ar.t_op
        if (ar.t_op === 0 && ar.opacity < 0.01) anim_rows.splice(i, 1)
    }
    anim_version++
    if (moving) anim_handle = requestAnimationFrame(anim_tick)
    else        anim_handle = null
}

onMount(() => () => { if (anim_handle) cancelAnimationFrame(anim_handle) })

let list_h = $derived(
    anim_version >= 0 && anim_rows.length
        ? Math.max(...anim_rows.map(ar => ar.y + ROW_H)) + 8
        : 40
)


// ── cursor movement + keyboard ──────────────────────────────────────────────

function dm_w(): TheC | undefined {
    return H.ave.ob({ Diffmatic: 1 })[0]?.c?.w as TheC | undefined   // the c.w back-ref home
}

function go_to(n: number) {
    const w = dm_w(); if (!w) return
    H.dm_set_cursor(w, n)
}

function handle_key(e: KeyboardEvent) {
    if (!cursor_n) return
    const idx = step_entries.findIndex(s => s.n === cursor_n)
    if (e.key === 'ArrowRight' && idx < step_entries.length - 1) {
        e.preventDefault(); go_to(step_entries[idx + 1].n)
    } else if (e.key === 'ArrowLeft' && idx > 0) {
        e.preventDefault(); go_to(step_entries[idx - 1].n)
    } else if (e.key === 'p') {
        e.preventDefault()
        // cycle only the modes that have a diff — exp|next are absent until their
        //   snaps load, and stepping onto an empty mode would feel broken.
        const avail = (['prev', 'exp', 'next'] as ViewMode[]).filter(m => diffs[m])
        if (avail.length) mode = avail[(avail.indexOf(mode) + 1) % avail.length]
    } else if (e.key === 'Escape') {
        pinned_id = null
    }
}
</script>

<!-- ═══════════════════════════════════════════════════════════════════════ -->
<div class="dm" tabindex="0" onkeydown={handle_key}>

    <!-- intro ──────────────────────────────────────────────────────────── -->
    <div class="dm-intro" class:loading={!intro}>{intro || 'loading story…'}</div>

    <!-- step strip ─────────────────────────────────────────────────────── -->
    {#if step_entries.length > 0}
        <div class="dm-strip">
            {#each step_entries as s (s.n)}
                {@const step = live_step(s.n)}
                {@const on   = s.n === cursor_n}
                {@const ok   = !!step?.sc.ok}
                <button class="dm-pip"
                        class:ok
                        class:on
                        class:hollow={!s.loaded}
                        class:busy={on && loading}
                        onclick={() => go_to(s.n)}
                        title="step {s.n}{s.loaded ? '' : ' (hollow)'}">
                    {s.loaded ? (ok ? '·' : '○') : '○'}
                </button>
            {/each}
        </div>
    {/if}

    <!-- mode bar ───────────────────────────────────────────────────────── -->
    {#if cursor_n != null}
        <div class="dm-bar">
            <button class="dm-mode" class:on={mode==='prev'} onclick={() => mode='prev'}>prev</button>
            <button class="dm-mode" class:on={mode==='exp'}  onclick={() => mode='exp'}
                    disabled={!diffs['exp']}>exp</button>
            <button class="dm-mode" class:on={mode==='next'} onclick={() => mode='next'}
                    disabled={!diffs['next']}>next</button>
            {#if active_diff}
                <span class="dm-label">{active_diff.label_l} → {active_diff.label_r}</span>
            {:else if loading}
                <span class="dm-label loading">computing…</span>
            {/if}
            {#if pinned_id}
                <button class="dm-unpin" onclick={() => pinned_id = null}>📌 {pinned_id} ×</button>
            {/if}
        </div>
    {/if}

    <!-- animated diff ──────────────────────────────────────────────────── -->
    {#if anim_version >= 0 && anim_rows.length > 0}
        <div class="dm-diff" style="height:{list_h}px">
            {#each H.each_keys(anim_rows, ar => ar.key, 'anim_rows') as ar (ar.key)}
                {@const row = ar.row}
                <div class="dm-row {row.kind}"
                     class:pinned={ar.pinned}
                     class:changed={row.kind === 'pair' && (row as any).tag === 'changed'}
                     style="transform:translateY({ar.y}px);opacity:{ar.opacity};--frame:{anim_version}"
                     onclick={() => toggle_pin(row)}>
                    {#if row.kind === 'squish'}
                        <div class="dm-squish">… {row.count} unchanged</div>
                    {:else if row.kind === 'pair'}
                        {@render two_col((row as any).left, (row as any).right)}
                    {:else if row.kind === 'left_only'}
                        {@render two_col(row.line, null)}
                    {:else if row.kind === 'right_only'}
                        {@render two_col(null, row.line)}
                    {/if}
                </div>
            {/each}
        </div>
    {:else if loading && cursor_n != null}
        <div class="dm-hint">loading snaps…</div>
    {:else if cursor_n != null}
        <div class="dm-hint">no diff — snaps identical</div>
    {:else if !intro}
        <div class="dm-hint">loading…</div>
    {:else}
        <div class="dm-hint">← → to navigate  ·  p to change mode  ·  click a line to pin it</div>
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

{#snippet two_col(left: string | null, right: string | null)}
    <div class="dm-2col">
        <div class="dm-l" class:gone={left != null && right == null} class:empty={left == null}>
            {#if left != null}{@render line_span(left)}{/if}
        </div>
        <div class="dm-r" class:neu={right != null && left == null} class:empty={right == null}>
            {#if right != null}{@render line_span(right)}{/if}
        </div>
    </div>
{/snippet}

<style>
.dm {
    --bg:    #111214;
    --surf:  #181b1f;
    --bord:  #272b33;
    --text:  #c0c2c8;
    --dim:   #585b66;
    --amber: #d3a74a;
    --green: #55c267;
    --red:   #cb4d49;
    --blue:  #4d8bc6;
    --pin:   rgba(211,167,74,.15);
    display:        flex;
    flex-direction: column;
    gap:            7px;
    background:     var(--bg);
    color:          var(--text);
    font-family:    'JetBrains Mono','Fira Mono',monospace;
    font-size:      12px;
    padding:        11px;
    min-height:     100%;
    box-sizing:     border-box;
    outline:        none;
}
.dm-intro { font-size: 11px; color: var(--dim); padding-bottom: 6px; border-bottom: 1px solid var(--bord); }
.dm-intro.loading { font-style: italic; }

/* strip */
.dm-strip { display: flex; flex-wrap: wrap; gap: 3px; }
.dm-pip {
    background: var(--surf); border: 1px solid var(--bord);
    color: var(--dim); width: 24px; height: 20px;
    font: 10px/1 inherit; border-radius: 2px; cursor: pointer; padding: 0;
    transition: all .08s;
}
.dm-pip:hover   { border-color: #404455; color: var(--text); }
.dm-pip.ok      { color: #4a7a4a; }
.dm-pip.hollow  { opacity: .45; }
.dm-pip.on      { border-color: var(--blue)!important; background: rgba(77,139,198,.13); color: var(--blue); }
.dm-pip.on.busy { border-color: var(--amber)!important; color: var(--amber); animation: pulse 1s ease-in-out infinite; }
@keyframes pulse { 0%,100%{opacity:1} 50%{opacity:.5} }

/* bar */
.dm-bar { display: flex; align-items: center; gap: 5px; }
.dm-mode {
    background: none; border: 1px solid var(--bord); color: var(--dim);
    padding: 2px 6px; border-radius: 2px; cursor: pointer; font: 11px/1 inherit;
    transition: all .08s;
}
.dm-mode:hover   { border-color: #505565; color: var(--text); }
.dm-mode.on      { border-color: var(--blue); color: var(--blue); background: rgba(77,139,198,.09); }
.dm-mode:disabled{ opacity: .28; cursor: default; }
.dm-label        { color: var(--dim); font-size: 10px; margin-left: 3px; }
.dm-label.loading{ color: var(--amber); }
.dm-unpin {
    margin-left: auto; background: none; border: 1px solid var(--amber);
    color: var(--amber); font: 10px/1 inherit; padding: 2px 6px; border-radius: 2px; cursor: pointer;
    max-width: 200px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
}

/* diff */
.dm-diff { position: relative; overflow: hidden; border: 1px solid var(--bord); border-radius: 3px; background: var(--surf); transition: height .35s cubic-bezier(.4,0,.2,1); }
.dm-row  { position: absolute; left: 0; right: 0; height: 19px; cursor: pointer; will-change: transform,opacity; }
.dm-row:hover  { background: rgba(255,255,255,.03); }
.dm-row.pinned { background: var(--pin)!important; z-index: 2; }
.dm-row.pinned::after { content:'📌'; position:absolute; right:5px; top:2px; font-size:9px; opacity:.5; }
.dm-2col       { display: grid; grid-template-columns: 1fr 1fr; height: 100%; }
.dm-l, .dm-r   { padding: 0 7px; overflow: hidden; white-space: pre; line-height: 19px; font-size: 11px; }
.dm-l.gone     { background: rgba(200,55,55,.11); color: #d07070; }
.dm-r.neu      { background: rgba(80,185,95,.09);  color: #5ec870; }
.dm-row.changed .dm-l,
.dm-row.changed .dm-r { background: rgba(211,167,74,.07); }
.dm-l.empty,
.dm-r.empty    { background: rgba(255,255,255,.012); }
.dm-squish     { padding: 0 8px; color: var(--dim); font-size: 10px; line-height: 19px; font-style: italic; }

.dm-hint { color: var(--dim); font-size: 11px; padding: 6px; font-style: italic; }

.ind { display: inline-block; }
.obj { color: #6e6898; margin-right: 2px; }
.str { color: var(--text); }
</style>
