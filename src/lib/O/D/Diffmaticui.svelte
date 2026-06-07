<script lang="ts">
// Diffmaticui.svelte — Diffmatic diff frontend.
//
//   Receives H (the sub-House running the Diffmatic test).
//   Reads from H.ave via ob() — tracks H.ave.version reactively, same
//   pattern as Storui.  A single $effect drains ave on every settled
//   beliefs cycle; no other Atime-side reads.
//
//   ave particles read here:
//     {dm_state:1}          — sc.loading, sc.error, sc.step_count
//     {dm_step:1, step_n:N} — one per step, sc.dige, sc.ok
//     {dm_snap:1, step_n:N} — one per loaded snap, sc.snap
//
//   Three panels:
//     1. Orbit canvas — particles from dm_correlate drift to depth-band positions,
//                       animated by rAF.  Hover highlights matching diff rows.
//     2. Text diff    — two-column compute_diff view, highlighted by hovered particle.
//     3. Inspiration  — ranked interesting transitions from dm_inspire.
//
//   Time muting: shift-click two step pips to create a mute pointer (net diff).
//   Multiple mute pointers can coexist; click one to remove it.

import type { TheC } from "$lib/data/Stuff.svelte"
import type { House } from "$lib/O/Housing.svelte"
import { onMount }    from "svelte"

let { H }: { H: House } = $props()


// ── types ─────────────────────────────────────────────────────────────────

type DmStep = { n: number, dige: string, ok: boolean }
type DmSnaps = Record<number, string>

type DmParticle = {
    identity:   string
    left_line:  string | null
    right_line: string | null
    left_d:     number
    right_d:    number
    status:     'same' | 'changed' | 'added' | 'removed'
}

type MutePtr = { from_n: number, to_n: number, color: string }

type DiffRow =
    | { kind: 'pair';       left: string; right: string; tag: 'same' }
    | { kind: 'pair';       left: string; right: string; tag: 'changed'; ops: Array<[number,string]> }
    | { kind: 'left_only';  line: string }
    | { kind: 'right_only'; line: string }
    | { kind: 'squish';     count: number }

type Inspiration = { step_n: number, headline: string, rows: DiffRow[], score: number }


// ── reactive state — read from H.ave once per beliefs cycle ───────────────

let dm_loading  = $state(true)
let dm_error    = $state<string | undefined>(undefined)
let dm_steps    = $state<DmStep[]>([])
let dm_snaps    = $state<DmSnaps>({})

$effect(() => {
    // ob() reads H.ave.version — fires once per settled beliefs cycle
    const state_p = H.ave.ob({ dm_state: 1 })[0] as TheC | undefined
    const step_ps = H.ave.ob({ dm_step:  1 })    as TheC[]
    const snap_ps = H.ave.ob({ dm_snap:  1 })    as TheC[]

    dm_loading = !!(state_p?.sc.loading ?? true)
    dm_error   = state_p?.sc.error as string | undefined

    const steps: DmStep[] = step_ps
        .map(p => ({ n: p.sc.step_n as number, dige: (p.sc.dige as string) ?? '', ok: !!p.sc.ok }))
        .sort((a, b) => a.n - b.n)
    dm_steps = steps

    const snaps: DmSnaps = {}
    for (const p of snap_ps) snaps[p.sc.step_n as number] = p.sc.snap as string
    dm_snaps = snaps
})


// ── step selection ────────────────────────────────────────────────────────

let left_n  = $state<number | null>(null)
let right_n = $state<number | null>(null)

// seed defaults once steps arrive
$effect(() => {
    if (left_n !== null || dm_steps.length < 2) return
    left_n  = dm_steps[0].n
    right_n = dm_steps[1].n
})

// request snaps lazily when selection changes
$effect(() => {
    if (left_n  != null && !dm_snaps[left_n])  ensure_snap(left_n)
    if (right_n != null && !dm_snaps[right_n]) ensure_snap(right_n)
})

// find w:Diffmatication — the worker whose w.c.toc_loaded is set,
// or any w under A:Diffmatication (before toc loads)
function get_dm_w(): TheC | undefined {
    for (const A of (H.o({ A: 1 }) as TheC[])) {
        const w = A.o({ w: 1 })[0] as TheC | undefined
        if (w?.c.wh_path) return w   // toc loaded — proper wh
        if (w)            return w   // pre-toc — want will wait
    }
    return undefined
}

function ensure_snap(n: number) {
    if (dm_snaps[n]) return
    const w = get_dm_w()
    if (w) H.dm_want_step(w, n)
}


// ── mute pointers ─────────────────────────────────────────────────────────

const MUTE_COLORS = ['#e07b39', '#5b9bd5', '#8fd16e', '#c97cb5', '#d4c35a']

let mute_ptrs     = $state<MutePtr[]>([])
let shift_anchor: number | null = null

function add_mute(from_n: number, to_n: number) {
    const [a, b] = from_n < to_n ? [from_n, to_n] : [to_n, from_n]
    if (a === b) return
    const color = MUTE_COLORS[mute_ptrs.length % MUTE_COLORS.length]
    mute_ptrs = [...mute_ptrs, { from_n: a, to_n: b, color }]
    ensure_snap(a); ensure_snap(b)
    if (a > 0) ensure_snap(a - 1)
}

function remove_mute(i: number) {
    mute_ptrs = mute_ptrs.filter((_, idx) => idx !== i)
}


// ── active diff ───────────────────────────────────────────────────────────

type ActiveDiff = {
    left_snap:  string
    right_snap: string
    label_l:    string
    label_r:    string
    is_muted:   boolean
    mute_label: string
}

let active_diff = $derived.by((): ActiveDiff | null => {
    if (mute_ptrs.length === 1) {
        const mp       = mute_ptrs[0]
        const baseline = dm_snaps[mp.from_n - 1] ?? ''
        const target   = dm_snaps[mp.to_n]        ?? ''
        if (!baseline && !target) return null
        return {
            left_snap:  baseline,
            right_snap: target,
            label_l:    `step ${mp.from_n - 1 > 0 ? mp.from_n - 1 : '—'}`,
            label_r:    `step ${mp.to_n}`,
            is_muted:   true,
            mute_label: `steps ${mp.from_n}–${mp.to_n} (net)`,
        }
    }
    if (left_n == null || right_n == null) return null
    return {
        left_snap:  dm_snaps[left_n]  ?? '',
        right_snap: dm_snaps[right_n] ?? '',
        label_l:    `step ${left_n}`,
        label_r:    `step ${right_n}`,
        is_muted:   false,
        mute_label: '',
    }
})

let correlation = $derived.by(() => {
    if (!active_diff || (!active_diff.left_snap && !active_diff.right_snap)) return null
    return H.dm_correlate(active_diff.left_snap, active_diff.right_snap)
})

let diff_rows = $derived.by((): DiffRow[] => (correlation?.rows ?? []) as DiffRow[])


// ── hovered particle ──────────────────────────────────────────────────────

let hovered_id = $state<string | null>(null)

function row_hi(row: DiffRow): boolean {
    if (!hovered_id) return false
    const line = 'line' in row ? (row as any).line : ('right' in row ? (row as any).right : '')
    return H.dm_identity(line) === hovered_id
}


// ── inspiration ───────────────────────────────────────────────────────────

let show_inspiration = $state(false)

let inspirations = $derived.by((): Inspiration[] => {
    if (Object.keys(dm_snaps).length < 3) return []
    return H.dm_inspire(dm_steps, dm_snaps, 6) as Inspiration[]
})

function jump_to_inspiration(ins: Inspiration) {
    const idx = dm_steps.findIndex(s => s.n === ins.step_n)
    if (idx < 1) return
    left_n  = dm_steps[idx - 1].n
    right_n = ins.step_n
    ensure_snap(left_n)
    ensure_snap(right_n)
    show_inspiration = false
}


// ── eagerly load first several steps for inspiration ─────────────────────

$effect(() => {
    if (dm_steps.length < 2) return
    for (const s of dm_steps.slice(0, 8)) ensure_snap(s.n)
})


// ── step strip ────────────────────────────────────────────────────────────

function step_click(n: number, e: MouseEvent) {
    if (e.shiftKey) {
        if (shift_anchor === null) { shift_anchor = n }
        else { add_mute(shift_anchor, n); shift_anchor = null }
        return
    }
    // first click → set left, clear right; second click → set right, order
    if (left_n === null || right_n !== null) {
        left_n  = n
        right_n = null
    } else {
        right_n = n
        if (left_n > right_n) { [left_n, right_n] = [right_n, left_n] }
        ensure_snap(left_n)
        ensure_snap(right_n)
    }
}


// ── canvas: particle drift ────────────────────────────────────────────────

let canvas_el    = $state<HTMLCanvasElement | undefined>()
let canvas_w_px  = $state(640)
let canvas_h_px  = $state(280)

const STATUS_FILL: Record<string, string> = {
    same:    'rgba(100,100,120,0.35)',
    changed: 'rgba(212,168,75,0.88)',
    added:   'rgba(85,195,100,0.88)',
    removed: 'rgba(205,65,65,0.88)',
}

type CP = { id: string; status: string; x: number; y: number; tx: number; ty: number; r: number }

let cps = $state<CP[]>([])
let anim_handle: number | null = null

$effect(() => {
    if (!correlation) { cps = []; return }
    const particles = correlation.particles
    const by_depth  = new Map<number, DmParticle[]>()
    for (const p of particles.values() as IterableIterator<DmParticle>) {
        const d = Math.max(0, p.status === 'removed' ? p.left_d : p.right_d)
        if (!by_depth.has(d)) by_depth.set(d, [])
        by_depth.get(d)!.push(p)
    }
    const depths  = [...by_depth.keys()].sort((a, b) => a - b)
    const max_d   = depths.at(-1) ?? 0
    const x_band  = max_d > 0 ? (canvas_w_px - 80) / (max_d + 1) : canvas_w_px - 80

    const next: CP[] = []
    for (const d of depths) {
        const group = by_depth.get(d)!
        const x     = 40 + d * x_band + x_band / 2
        for (let i = 0; i < group.length; i++) {
            const p  = group[i]
            const ty = 24 + (i + 0.5) * ((canvas_h_px - 48) / Math.max(group.length, 1))
            const old = cps.find(c => c.id === p.identity)
            next.push({ id: p.identity, status: p.status,
                x: old?.x ?? x, y: old?.y ?? ty, tx: x, ty, r: p.status === 'same' ? 3.5 : 6 })
        }
    }
    cps = next
})

function draw() {
    const ctx = canvas_el?.getContext('2d')
    if (!ctx) return
    ctx.clearRect(0, 0, canvas_w_px, canvas_h_px)
    // depth guides
    ctx.strokeStyle = 'rgba(255,255,255,0.035)'
    ctx.lineWidth   = 1
    const xs = [...new Set(cps.map(p => p.tx))]
    for (const x of xs) { ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, canvas_h_px); ctx.stroke() }
    // particles
    for (const p of cps) {
        const hi = hovered_id === p.id
        ctx.beginPath()
        ctx.arc(p.x, p.y, hi ? p.r * 1.9 : p.r, 0, Math.PI * 2)
        ctx.fillStyle = STATUS_FILL[p.status] ?? 'rgba(150,150,150,0.4)'
        ctx.fill()
        if (hi) {
            ctx.strokeStyle = 'rgba(255,255,255,0.7)'; ctx.lineWidth = 1.2; ctx.stroke()
            ctx.fillStyle   = '#dde'; ctx.font = '10px monospace'
            ctx.fillText(p.id.slice(0, 32), p.x + 9, p.y + 4)
        }
    }
}

function tick() {
    let moving = false
    for (const p of cps) {
        const dx = p.tx - p.x, dy = p.ty - p.y
        if (Math.abs(dx) > 0.25 || Math.abs(dy) > 0.25) { p.x += dx * 0.13; p.y += dy * 0.13; moving = true }
        else { p.x = p.tx; p.y = p.ty }
    }
    draw()
    anim_handle = requestAnimationFrame(tick)
}

$effect(() => {
    void cps; void hovered_id
    if (!canvas_el) return
    if (!anim_handle) anim_handle = requestAnimationFrame(tick)
})

onMount(() => () => { if (anim_handle) cancelAnimationFrame(anim_handle) })

function canvas_move(e: MouseEvent) {
    const rect = canvas_el?.getBoundingClientRect()
    if (!rect) return
    const mx = e.clientX - rect.left, my = e.clientY - rect.top
    let best = 18, nearest: string | null = null
    for (const p of cps) { const d = Math.hypot(p.x - mx, p.y - my); if (d < best) { best = d; nearest = p.id } }
    hovered_id = nearest
}
</script>

<!-- ═══════════════════════════════════════════════════════════════════════ -->
<div class="dm">

    <!-- header ─────────────────────────────────────────────────────────── -->
    <div class="dm-bar">
        <span class="dm-title">Diffmatic</span>
        <span class="dm-sub">LangTiles</span>
        {#if dm_loading}
            <span class="dm-pill loading">loading…</span>
        {:else if dm_error}
            <span class="dm-pill error">{dm_error}</span>
        {:else}
            <span class="dm-pill ok">{dm_steps.length} steps</span>
        {/if}
        <button class="dm-btn"
                class:on={show_inspiration}
                disabled={inspirations.length === 0}
                onclick={() => show_inspiration = !show_inspiration}>
            ✦ {inspirations.length}
        </button>
    </div>

    <!-- inspiration drawer ──────────────────────────────────────────────── -->
    {#if show_inspiration}
        <div class="dm-inspire">
            <div class="dm-inspire-hd">interesting transitions</div>
            {#each inspirations as ins (ins.step_n)}
                <button class="dm-ins-row" onclick={() => jump_to_inspiration(ins)}>
                    <span class="dm-ins-score">{ins.score | 0}pt</span>
                    <span class="dm-ins-hl">{ins.headline}</span>
                    <span class="dm-ins-sum">
                        +{ins.rows.filter(r => r.kind === 'right_only').length}
                        −{ins.rows.filter(r => r.kind === 'left_only').length}
                    </span>
                </button>
            {/each}
        </div>
    {/if}

    <!-- step strip ─────────────────────────────────────────────────────── -->
    {#if dm_steps.length > 0}
        <div class="dm-strip">
            {#each dm_steps as s (s.n)}
                {@const is_l   = s.n === left_n}
                {@const is_r   = s.n === right_n}
                {@const mute   = mute_ptrs.find(mp => s.n >= mp.from_n && s.n <= mp.to_n)}
                {@const anchor = s.n === shift_anchor}
                <button class="dm-pip"
                        class:ok={s.ok}
                        class:is-l={is_l}
                        class:is-r={is_r}
                        class:loaded={!!dm_snaps[s.n]}
                        class:in-mute={!!mute}
                        class:anchor={anchor}
                        style:box-shadow={mute ? `inset 0 0 0 2px ${mute.color}` : undefined}
                        onclick={e => step_click(s.n, e)}
                        title="step {s.n}  {s.dige.slice(0,6)}{s.ok ? '' : ' ✗'}">
                    {s.n}
                </button>
            {/each}
        </div>
        <div class="dm-mute-row">
            {#if mute_ptrs.length}
                {#each mute_ptrs as mp, i (i)}
                    <button class="dm-mute" style:border-color={mp.color}
                            onclick={() => remove_mute(i)}>[{mp.from_n}–{mp.to_n}] ×</button>
                {/each}
            {/if}
            <span class="dm-hint">
                {shift_anchor != null ? `shift-click to close mute from step ${shift_anchor}` : 'shift-click two steps to mute a range'}
            </span>
        </div>
    {/if}

    <!-- selection label ────────────────────────────────────────────────── -->
    {#if active_diff}
        <div class="dm-sel">
            {#if active_diff.is_muted}
                <span class="dm-muted">⊘ {active_diff.mute_label}</span>
            {:else}
                <span class="dm-sel-l">{active_diff.label_l}</span>
                <span class="dm-arrow">→</span>
                <span class="dm-sel-r">{active_diff.label_r}</span>
                {#if (left_n != null && !dm_snaps[left_n]) || (right_n != null && !dm_snaps[right_n])}
                    <span class="dm-pill loading">loading snaps…</span>
                {/if}
            {/if}
        </div>
    {:else if !dm_loading && dm_steps.length > 1}
        <div class="dm-sel dm-hint">click a step to pick left, then another for right</div>
    {/if}

    <!-- orbit canvas ───────────────────────────────────────────────────── -->
    {#if correlation && correlation.particles.size > 0}
        <div class="dm-canvas-wrap">
            <div class="dm-legend">
                <span class="leg same">same</span>
                <span class="leg changed">changed</span>
                <span class="leg added">added</span>
                <span class="leg removed">removed</span>
                <span class="leg-hint">← shallower · deeper →</span>
            </div>
            <canvas bind:this={canvas_el}
                    width={canvas_w_px} height={canvas_h_px}
                    class="dm-canvas"
                    onmousemove={canvas_move}
                    onmouseleave={() => hovered_id = null}></canvas>
        </div>
    {/if}

    <!-- text diff ──────────────────────────────────────────────────────── -->
    {#if diff_rows.length > 0}
        <div class="dm-diff">
            <div class="dm-diff-hdr">
                <span>{active_diff?.label_l ?? ''}</span>
                <span>{active_diff?.label_r ?? ''}</span>
            </div>
            <div class="dm-cols">
                <div class="dm-col">
                    {#each diff_rows as row, i (i)}
                        {#if row.kind === 'squish'}
                            <div class="dm-squish">… {row.count}</div>
                        {:else if row.kind === 'pair'}
                            <div class="dm-cell" class:changed={row.tag === 'changed'} class:hi={row_hi(row)}>
                                {@render ln((row as any).left)}
                            </div>
                        {:else if row.kind === 'left_only'}
                            <div class="dm-cell gone" class:hi={row_hi(row)}>{@render ln(row.line)}</div>
                        {:else}
                            <div class="dm-cell dm-gap"></div>
                        {/if}
                    {/each}
                </div>
                <div class="dm-col">
                    {#each diff_rows as row, i (i)}
                        {#if row.kind === 'squish'}
                            <div class="dm-squish">… {row.count}</div>
                        {:else if row.kind === 'pair'}
                            <div class="dm-cell" class:changed={row.tag === 'changed'} class:hi={row_hi(row)}>
                                {@render ln((row as any).right)}
                            </div>
                        {:else if row.kind === 'right_only'}
                            <div class="dm-cell neu" class:hi={row_hi(row)}>{@render ln(row.line)}</div>
                        {:else}
                            <div class="dm-cell dm-gap"></div>
                        {/if}
                    {/each}
                </div>
            </div>
        </div>
    {:else if active_diff && !dm_loading}
        <div class="dm-hint" style="padding:8px">no diff — snaps identical or not yet loaded</div>
    {/if}

</div>

<!-- ── snippets ──────────────────────────────────────────────────────────── -->
{#snippet ln(line: string)}
    {@const ind = line.match(/^ */)?.[0] ?? ''}
    {@const tab = line.indexOf('\t')}
    {@const obj = tab > ind.length ? line.slice(ind.length, tab) : ''}
    {@const str = tab >= 0 ? line.slice(tab + 1) : line.trimStart()}
    <span class="ind">{ind}</span>{#if obj}<span class="obj">{obj}</span> {/if}<span class="str">{str}</span>
{/snippet}

<style>
.dm {
    --bg:      #111214;
    --surf:    #191b1f;
    --bord:    #2a2d35;
    --text:    #c4c6cc;
    --dim:     #60636e;
    --amber:   #d4a84b;
    --green:   #58c56a;
    --red:     #cc4f4a;
    --blue:    #4f8ec9;
    --hi:      rgba(255,255,255,0.07);
    display:        flex;
    flex-direction: column;
    gap:            8px;
    background:     var(--bg);
    color:          var(--text);
    font-family:    'JetBrains Mono', 'Fira Mono', monospace;
    font-size:      12px;
    padding:        12px;
    min-height:     100%;
}

/* bar */
.dm-bar { display: flex; align-items: baseline; gap: 8px; border-bottom: 1px solid var(--bord); padding-bottom: 8px; }
.dm-title { font-size: 14px; font-weight: 700; color: #dde; letter-spacing: .04em; }
.dm-sub   { color: var(--dim); }
.dm-pill  { font-size: 10px; padding: 1px 6px; border-radius: 10px; border: 1px solid; }
.dm-pill.loading { border-color: var(--amber); color: var(--amber); }
.dm-pill.error   { border-color: var(--red);   color: var(--red); }
.dm-pill.ok      { border-color: #3a5a3a;      color: var(--green); }
.dm-btn {
    margin-left:   auto;
    background:    transparent;
    border:        1px solid var(--bord);
    color:         var(--dim);
    padding:       2px 8px;
    border-radius: 3px;
    cursor:        pointer;
    font:          11px/1 inherit;
    transition:    all .12s;
}
.dm-btn:hover, .dm-btn.on { border-color: var(--amber); color: var(--amber); background: rgba(212,168,75,.07); }
.dm-btn:disabled { opacity: .3; cursor: default; }

/* inspiration */
.dm-inspire { background: var(--surf); border: 1px solid var(--bord); border-radius: 3px; padding: 6px; display: flex; flex-direction: column; gap: 3px; }
.dm-inspire-hd { color: var(--dim); font-size: 10px; text-transform: uppercase; letter-spacing: .07em; margin-bottom: 3px; }
.dm-ins-row { display: flex; gap: 7px; align-items: center; background: none; border: 1px solid transparent; color: var(--text); padding: 3px 5px; border-radius: 2px; cursor: pointer; font: 11px/1.4 inherit; text-align: left; }
.dm-ins-row:hover { background: var(--hi); border-color: var(--bord); }
.dm-ins-score { color: var(--amber); width: 26px; flex-shrink: 0; font-size: 10px; }
.dm-ins-hl    { flex: 1; }
.dm-ins-sum   { color: var(--dim); font-size: 10px; white-space: nowrap; }

/* strip */
.dm-strip { display: flex; flex-wrap: wrap; gap: 3px; }
.dm-pip {
    background: var(--surf); border: 1px solid var(--bord); color: var(--dim);
    width: 26px; height: 20px; font: 10px/1 inherit;
    border-radius: 2px; cursor: pointer; padding: 0; transition: all .08s;
}
.dm-pip:hover  { border-color: #44475a; color: var(--text); }
.dm-pip.ok     { color: #4a7a4a; }
.dm-pip.loaded { border-color: #2f3240; }
.dm-pip.is-l   { border-color: var(--blue)!important;  background: rgba(79,142,201,.14); color: var(--blue); }
.dm-pip.is-r   { border-color: var(--green)!important; background: rgba(88,197,106,.11); color: var(--green); }
.dm-pip.anchor { border-color: var(--amber)!important; }
.dm-pip.in-mute { opacity: .7; }

.dm-mute-row { display: flex; gap: 5px; align-items: center; flex-wrap: wrap; min-height: 18px; }
.dm-mute { background: none; border: 1px solid; color: var(--text); font: 10px/1 inherit; padding: 1px 5px; border-radius: 2px; cursor: pointer; }
.dm-mute:hover { opacity: .65; }
.dm-hint { color: var(--dim); font-size: 10px; }

/* selection label */
.dm-sel { display: flex; align-items: center; gap: 6px; font-size: 11px; }
.dm-sel-l { color: var(--blue); }
.dm-sel-r { color: var(--green); }
.dm-arrow { color: #444; }
.dm-muted { color: var(--amber); }

/* canvas */
.dm-canvas-wrap { background: var(--surf); border: 1px solid var(--bord); border-radius: 3px; overflow: hidden; }
.dm-legend { display: flex; gap: 10px; align-items: center; padding: 5px 10px 0; font-size: 10px; }
.leg-hint  { color: var(--dim); margin-left: auto; }
.leg::before { content: '●'; margin-right: 3px; }
.leg.same    { color: #606070; }
.leg.changed { color: var(--amber); }
.leg.added   { color: var(--green); }
.leg.removed { color: var(--red); }
.dm-canvas   { display: block; width: 100%; cursor: crosshair; }

/* diff */
.dm-diff { background: var(--surf); border: 1px solid var(--bord); border-radius: 3px; overflow: hidden; }
.dm-diff-hdr { display: grid; grid-template-columns: 1fr 1fr; padding: 4px 8px; border-bottom: 1px solid var(--bord); font-size: 10px; color: var(--dim); text-transform: uppercase; letter-spacing: .06em; }
.dm-cols { display: grid; grid-template-columns: 1fr 1fr; gap: 1px; max-height: 500px; overflow-y: auto; }
.dm-col  { display: flex; flex-direction: column; overflow-x: auto; }
.dm-cell { padding: 1px 8px; white-space: pre; line-height: 1.5; transition: background .08s; }
.dm-cell.hi      { background: rgba(255,255,255,.08); outline: 1px solid rgba(255,255,255,.18); }
.dm-cell.changed { background: rgba(212,168,75,.08); }
.dm-cell.gone    { background: rgba(200,60,60,.11); color: #d87070; }
.dm-cell.neu     { background: rgba(85,190,100,.09); color: #60c970; }
.dm-gap          { background: rgba(255,255,255,.015); }
.dm-squish       { padding: 2px 8px; color: var(--dim); font-size: 10px; font-style: italic; }

/* line parts */
.ind { display: inline-block; }
.obj { color: #7870a0; margin-right: 2px; }
.str { color: var(--text); }
</style>
