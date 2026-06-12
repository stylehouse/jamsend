<script lang="ts">
    // NaviCado — What-navigation toolbar + tools row + capsule strip.
    //
    // ── What this is ─────────────────────────────────────────────────────────
    //
    //   Toolbar for the active Understanding (%LE) plus the tools row for
    //   branch/dive gestures, Point injection, and req:desire transport.
    //   Owns the capsule strip and the ~ bar.
    //
    // ── Particle sources ──────────────────────────────────────────────────────
    //
    //   H.ave/%Languinio — same-object hold; carries:
    //     /%LE           — the live Understanding
    //     /%dock,path    — the foregrounded %Dock (active:1)
    //   H.ave/%examining/%Spotlight — the cursored %What (nav buttons)
    //
    // ── Nav buttons (top row) ─────────────────────────────────────────────────
    //
    //   ↑ ← label →  — emit op(kind) → i_elvisto(Lies, 'operate', { LE, op })
    //   Handler (LiesCurse) reads the live cursor from %examining/%Spotlight.
    //
    //   < once LE_available_ops is wired into req:checkout, %LE/%moves.sc.ops
    //     replaces the static ↑←→ set with one chip per reachable move.
    //
    // ── Tools row (second row, always when LE armed) ──────────────────────────
    //
    //   ↘ dive / ↓ branch — splice in new What.
    //   PeelItem — type a method name, Enter → mark('add', ...).
    //   req:desire transport (‖/▶, →step) — only when req:timemachine exists.
    //   ~ bar — absolute overlay when %State%changey; push (↑) or reset (↩).
    //
    // ── Capsule strip ────────────────────────────────────────────────────────
    //
    //   Pure renderer of LE_clones().  No parallel in_group|showing Set — the
    //   clone IS the truth; U%unshowing|unaccepted and sc.class ride on it.
    //
    //   Keyed on clone.c.Dip (minted by Waft_dip, session-stable, rename-proof).
    //   Fallback key: spec_N so two same-method Points stay distinct even before
    //   Waft_dip has run on this waft.  each_keys() guards at construction time
    //   and throws with both colliding rows attached if a key clash slips through.
    //
    //   Orb = U%unshowing toggle → mark('unshow'|'show').
    //   × = appears when unshowing; fires mark('drop') → U%unaccepted.
    //   ↺ = appears when unaccepted; fires mark('accept') → clears both.
    //   Capsule label click → Dock_open → Lang_point_navigate.

    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import type { Snippet } from "svelte"

    // CapsuleRow — one entry in the strip per clone.
    //   key is what the {#each} keys on — unique even for same-method Points.
    //   body is what LE_capsule_body returns: kind:'name' today; kind:'patch'
    //   when a text-search hit or encode diff arrives on clone.c.body.
    type CapsuleRow = {
        clone:      TheC
        key:        string
        spec:       string
        body:       { kind: string, raw: string }
        unshowing:  boolean
        unaccepted: boolean
        cls:        string | undefined   // focus|caution|dim|ghost from sc.class
        line:       number | undefined
        unresolved: boolean
    }

    let { H, slot_up, slot_prev, slot_next }: {
        H:          House
        slot_up?:   Snippet<[{ ghosted: boolean, onclick: () => void }]>
        slot_prev?: Snippet<[{ ghosted: boolean, onclick: () => void }]>
        slot_next?: Snippet<[{ ghosted: boolean, onclick: () => void }]>
    } = $props()

    // ── particle derivation ───────────────────────────────────────────────────

    let languinio: TheC | undefined = $state()
    $effect(() => {
        languinio = H.ave.ob({ Languinio: 1 })[0] as TheC | undefined
    })

    let active_path = $derived(
        (languinio?.ob({ dock: 1, active: 1 })[0]?.sc.dock as string | undefined) ?? ''
    )

    let lang_dock: TheC | undefined = $state()
    $effect(() => {
        lang_dock = active_path
            ? languinio?.ob({ dock: active_path })[0] as TheC | undefined
            : undefined
    })

    let LE: TheC | undefined = $derived(
        languinio?.ob({ LE: 1 })[0] as TheC | undefined
    )

    // ── nav bar derivation ────────────────────────────────────────────────────
    //
    //   examining/Spotlight.sc.src is stamped synchronously in Lies_i_Spotlight
    //   so the nav bar updates immediately without waiting for a languinio round-trip.

    let examining   = $derived(H.ave.ob({ examining: 1 })[0] as TheC | undefined)
    let timemachine = $derived(examining && examining.vers
        && examining.o({ req: 'timemachine' })[0] as TheC | undefined)
    let is_playing  = $derived(!!(timemachine && timemachine.vers && timemachine.sc.playing))
    let has_desire  = $derived(!!timemachine)

    // target — the currently cursored %What.
    // Only set when src carries .What (not a bare %Doc).
    let target = $derived((() => {
        void examining?.vers
        const spot = examining?.ob?.({ Spotlight: 1 })?.[0] as TheC | undefined
        const src  = spot?.sc.src as TheC | undefined
        return src && (src.sc as any).What !== undefined ? src as TheC : undefined
    })())

    let depth      = $derived(target ? (H as any).LE_what_depth(target) as number : -1)
    let has_up     = $derived(depth > 0)
    let has_prev   = $derived(target ? !!(H as any).LE_what_dfs_prev(target) : false)
    let has_next   = $derived(target ? !!(H as any).LE_what_dfs_next(target) : false)
    let has_target = $derived(!!target)

    // ── ~ bar — changey state from %LE/%State ────────────────────────────────
    //
    //   is_changey reads %State directly so it wakes on the same bump
    //   LE_encode_compare fires.  reset_confirm is the two-tap gate on ↩.

    let is_changey  = $derived(
        !!(LE?.vers && LE.ob({ State: 1 })[0]?.sc.changey)
    )
    let reset_confirm: boolean = $state(false)

    // ── collect_pmirror_map ───────────────────────────────────────────────────
    //
    //   Map spec → graft annotation from lang_dock/%Pmirrors.
    //   Two same-method Points share one Pmirror (Pmirrors are still keyed by
    //   spec — the Dip-keyed LangGraft patch is a separate TODO).  Both capsule
    //   rows find the same annotation; both navigate correctly.

    function collect_pmirror_map(): Map<string, { line: number, from: number, to: number } | null> {
        const out = new Map<string, { line: number, from: number, to: number } | null>()
        if (!lang_dock) return out
        const Pmirrors = lang_dock.o({ Pmirrors: 1 })[0] as TheC | undefined
        if (!Pmirrors) return out
        for (const pm of Pmirrors.o({ Pmirror: 1 }) as TheC[]) {
            const spec = (pm.sc.spec as string) || ''
            if (!spec) continue
            const graft = pm.o({ graft: 1 })[0] as TheC | undefined
            out.set(spec, graft
                ? { line: graft.sc.line as number, from: graft.sc.from as number, to: graft.sc.to as number }
                : null)
        }
        return out
    }

    // ── capsule derivation ────────────────────────────────────────────────────
    //
    //   One CapsuleRow per clone in LE_clones().  Clones that have no legible
    //   spec (Doc clones, bare {What:1} stubs) are skipped — they appear as
    //   nav moves, not capsules.
    //
    //   Key: clone.c.Dip is the stable address minted by Waft_dip; the
    //   spec_N fallback covers the window before Waft_dip has run on this waft.
    //   each_keys() throws at construction time with both colliding rows if a
    //   clash slips through — faster than reading a Svelte index error.

    let capsules: CapsuleRow[] = $derived.by(() => {
        void LE?.vers
        void lang_dock?.vers
        if (!LE?.oa({ Seem: 'working' })) return []
        const clones  = (H as any).LE_clones(LE) as TheC[]
        const pmMap   = collect_pmirror_map()
        const rows: CapsuleRow[] = []
        for (let i = 0; i < clones.length; i++) {
            const clone = clones[i]
            const body  = (H as any).LE_capsule_body(clone) as { spec: string, kind: string, raw: string }
            if (!body.spec || body.spec === '?') continue
            const { spec } = body
            const key  = (clone.c.Dip as string | undefined) ?? `${spec}_${i}`
            const U    = clone.c?.U as any
            const pm   = pmMap.get(spec)
            rows.push({
                clone,
                key,
                spec,
                body,
                unshowing:  !!U?.sc?.unshowing,
                unaccepted: !!U?.sc?.unaccepted,
                cls:        (clone.sc as any).class as string | undefined,
                line:       pm?.line,
                unresolved: pm === undefined,   // absent from Pmirror map → unresolved
            })
        }
        return (H as any).each_keys(rows, (r: CapsuleRow) => r.key, 'capsules')
    })

    // ── nav actions ───────────────────────────────────────────────────────────
    //
    //   op()  — structural cursor move to w:Lies (e_operate → e_LE_operate).
    //   mark() — U-sphere mutation to w:Lang  (e_mark   → e_LE_mark).
    //   Both pass LE as a particle so the handlers need no ave round-trip.

    const op   = (kind: string, extra?: object) =>
        H.i_elvisto('Lies/Lies', 'operate', { LE, op: kind, ...extra })
    const mark = (kind: string, extra?: object) =>
        H.i_elvisto('Lang/Lang', 'mark',    { LE, op: kind, ...extra })

    // ── PeelItem ──────────────────────────────────────────────────────────────
    //
    //   Type a method name, Enter → mark('add') → clone appended to working C**
    //   → req:understanding re-encodes → %State%changey updates.
    //   Active only when LE is armed at a %What (or %Waft) target.

    let peel_text: string = $state('')

    function peel_commit() {
        const method = peel_text.trim()
        const sc = LE?.sc.target ? (LE.sc.target as TheC).sc as any : undefined
        const at_what = sc?.What !== undefined || sc?.Waft !== undefined
        if (method && LE && at_what) mark('add', { sc: { Point: 1, method } })
        peel_text = ''
    }

    // ── What label ────────────────────────────────────────────────────────────

    let what_label = $derived.by(() => {
        void target?.vers
        if (!target) return ''
        const wv = (target.sc as any).What
        return (typeof wv === 'string' ? wv : undefined)
            ?? (target.sc as any).label
            ?? ((target.sc as any).path as string | undefined)?.split('/').pop()
            ?? ''
    })
</script>

{#if LE && target}

<!-- Nav bar — structural cursor movement: ↑ ← label → -->
<div class="nvc-bar">

    <div class="nvc-seed" class:nvc-ghost={!has_up}>
        {#if slot_up}
            {@render slot_up({ ghosted: !has_up, onclick: () => op('up') })}
        {:else}
            <button class="nvc-btn" class:nvc-ghosted={!has_up}
                    disabled={!has_up} onclick={() => op('up')} title="Up to parent What">↑</button>
        {/if}
    </div>

    <div class="nvc-seed" class:nvc-ghost={!has_prev}>
        {#if slot_prev}
            {@render slot_prev({ ghosted: !has_prev, onclick: () => op('prev') })}
        {:else}
            <button class="nvc-btn" class:nvc-ghosted={!has_prev}
                    disabled={!has_prev} onclick={() => op('prev')} title="Previous What">←</button>
        {/if}
    </div>

    <div class="nvc-label" title="Current What: {what_label}">{what_label}</div>

    <div class="nvc-seed" class:nvc-ghost={!has_next}>
        {#if slot_next}
            {@render slot_next({ ghosted: !has_next, onclick: () => op('next') })}
        {:else}
            <button class="nvc-btn" class:nvc-ghosted={!has_next}
                    disabled={!has_next} onclick={() => op('next')} title="Next What">→</button>
        {/if}
    </div>

</div>

<!-- Tools row — always visible when LE armed.
     ↘↓ branch/dive; PeelItem to inject Points; transport when req:desire active.
     ~ bar overlays the right side absolutely — adds no row height. -->
<div class="nvc-transport">

    {#if has_desire}
        <button class="nvc-t-btn" class:nvc-t-playing={is_playing}
                title={is_playing ? 'Pause' : 'Play'}
                onclick={() => H.i_elvisto('Lies/Lies', is_playing ? 'Lies_desire_pause' : 'Lies_desire_play', {})}>
            {is_playing ? '‖' : '▶'}
        </button>
        <button class="nvc-t-btn" title="Step to next What"
                onclick={() => H.i_elvisto('Lies/Lies', 'Lies_desire_step', {})}>→</button>
    {/if}

    <!-- ↘ dive — new child %What inside current; ↓ branch — new next sibling -->
    <button class="nvc-t-op" class:nvc-t-op-ghost={!has_target}
            disabled={!has_target} onclick={() => op('dive')}
            title="↘ new child What inside current">↘</button>
    <button class="nvc-t-op" class:nvc-t-op-ghost={!has_target}
            disabled={!has_target} onclick={() => op('branch')}
            title="↓ new sibling What after current">↓</button>

    <!-- PeelItem — type a method name, Enter injects into working C** -->
    <input class="nvc-peel"
           bind:value={peel_text}
           placeholder="method…"
           disabled={!has_target}
           onkeydown={(ev) => { if (ev.key === 'Enter') { ev.preventDefault(); peel_commit() } }}
    />

    {#if is_changey}
        <div class="lmm-wp-bar"
             onmouseleave={() => { reset_confirm = false }}>
            <span class="lmm-wp-tilde">~</span>
            {#if !reset_confirm}
                <button class="lmm-wp-arrow" onclick={() => op('push')}  title="Push">↑</button>
                <button class="lmm-wp-arrow" onclick={() => { if (!reset_confirm) { reset_confirm = true } else { op('reset'); reset_confirm = false } }} title="Reset">↩</button>
            {:else}
                <button class="lmm-wp-arrow lmm-wp-confirm" onclick={() => { op('reset'); reset_confirm = false }}>sure?</button>
            {/if}
        </div>
    {/if}

</div>

{/if}

<!-- Capsule strip — pure renderer of LE_clones() keyed on c.Dip.
     Orb = U%unshowing toggle.  × = mark('drop') when unshowing.  ↺ = mark('accept').
     Capsule label click → Dock_open → Lang_point_navigate. -->
{#if capsules.length > 0}
    <div class="lmm-inbox">
        {#each capsules as row (row.key)}
            <div class="lmm-capsule"
                 class:lmm-capsule-bad={row.unresolved}
                 class:lmm-capsule-dormant={row.unshowing}
                 class:lmm-capsule-unaccepted={row.unaccepted}
                 class:lmm-capsule-ghost={row.cls === 'ghost'}
                 class:lmm-capsule-dim={row.cls === 'dim'}>
                <!-- Orb — the showing toggle -->
                <button class="lmm-capsule-orb"
                        class:lmm-capsule-orb-show={!row.unshowing}
                        class:lmm-capsule-orb-unshowing={row.unshowing}
                        title={row.unshowing ? 'Hidden — click to show' : 'Showing — click to hide'}
                        onclick={() => mark(row.unshowing ? 'show' : 'unshow', { spec: row.spec })}>
                </button>
                <!-- Label — navigates CM to the Point -->
                <button class="lmm-capsule-label"
                        title="{row.spec}{row.unresolved ? ' (unresolved)' : row.line != null ? ` → line ${row.line}` : ''}"
                        onclick={() => H.i_elvisto('Lang/Lang', 'Dock_open', { path: active_path, point: row.spec })}>
                    {#if row.body.kind === 'name'}
                        {row.spec}
                    {:else}
                        <!-- < coherently folded patch renderer goes here -->
                        <pre class="lmm-capsule-body">{row.body.raw}</pre>
                    {/if}
                </button>
                <!-- × — demote to unaccepted (only when already unshowing) -->
                {#if row.unshowing && !row.unaccepted}
                    <button class="lmm-capsule-demote" title="Mark for removal" onclick={() => mark('drop', { spec: row.spec })}>×</button>
                {/if}
                <!-- ↺ — restore from unaccepted -->
                {#if row.unaccepted}
                    <button class="lmm-capsule-accept" title="Restore" onclick={() => mark('accept', { spec: row.spec })}>↺</button>
                {/if}
            </div>
        {/each}
        <button class="lmm-cursor-next" title="Next What in Waft" onclick={() => op('next_doc')}>→</button>
    </div>
{/if}

<style>
    /* Nav bar — ↑ ← label → structural cursor movement. */
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
    .nvc-btn.nvc-ghosted,
    .nvc-ghost .nvc-btn {
        color:        rgba(154, 165, 180, 0.25);
        border-color: rgba(255,255,255,0.04);
        cursor:       default;
    }

    .nvc-label {
        flex:           1;
        text-align:     center;
        color:          #6b7a8d;
        font-size:      10px;
        overflow:       hidden;
        text-overflow:  ellipsis;
        white-space:    nowrap;
        padding:        0 4px;
        letter-spacing: 0.02em;
    }

    /* Tools row — transport, ↘↓, PeelItem, ~ bar.
       position:relative anchors the ~ bar overlay. */
    .nvc-transport {
        display:       flex;
        align-items:   center;
        gap:           4px;
        padding:       2px 4px;
        background:    rgba(20, 25, 32, 0.9);
        border-bottom: 1px solid rgba(255,255,255,0.04);
        min-height:    18px;
        position:      relative;
    }

    /* req:desire transport buttons */
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
    .nvc-t-btn:hover          { color: #9aa5b4; border-color: rgba(255,255,255,0.25); }
    .nvc-t-btn.nvc-t-playing  { color: #7ab0c0; border-color: rgba(122,176,192,0.4); }

    /* ↘↓ in the tools row */
    .nvc-t-op {
        background:    transparent;
        border:        1px solid rgba(255,255,255,0.1);
        border-radius: 3px;
        color:         #6a7d8e;
        cursor:        pointer;
        font-size:     11px;
        line-height:   1;
        padding:       1px 4px;
        transition:    color 0.1s, border-color 0.1s;
    }
    .nvc-t-op:hover:not(:disabled) { color: #c0d0e0; border-color: rgba(255,255,255,0.28); }
    .nvc-t-op.nvc-t-op-ghost,
    .nvc-t-op:disabled {
        color:        rgba(100,120,140,0.3);
        border-color: rgba(255,255,255,0.04);
        cursor:       default;
    }

    /* PeelItem */
    .nvc-peel {
        background:    transparent;
        border:        1px solid rgba(255,255,255,0.08);
        border-radius: 3px;
        color:         #9aa5b4;
        font-family:   inherit;
        font-size:     10px;
        line-height:   1;
        padding:       1px 5px;
        width:         72px;
        outline:       none;
        transition:    border-color 0.12s, color 0.12s;
    }
    .nvc-peel:focus {
        border-color: rgba(229, 192, 123, 0.45);
        color:        #e5c07b;
    }
    .nvc-peel::placeholder { color: rgba(90, 110, 130, 0.55); }
    .nvc-peel:disabled     { opacity: 0.3; }

    /* ~ bar — absolute overlay on the right of the tools row. */
    .lmm-wp-bar {
        position:       absolute;
        right:          0;
        top:            0;
        bottom:         0;
        display:        flex;
        flex-direction: row;
        align-items:    center;
        gap:            3px;
        padding:        0 6px;
        background:     rgba(16, 20, 28, 0.96);
        border-left:    1px solid rgba(229, 192, 123, 0.15);
    }
    .lmm-wp-tilde {
        font-size:   11px;
        line-height: 1;
        color:       rgba(229, 192, 123, 0.4);
    }
    .lmm-wp-arrow {
        background:  none;
        border:      none;
        cursor:      pointer;
        font-family: inherit;
        font-size:   13px;
        line-height: 1;
        color:       rgba(229, 192, 123, 0.45);
        padding:     0 2px;
    }
    .lmm-wp-arrow:hover   { color: #e5c07b; }
    .lmm-wp-confirm       { color: rgba(224, 108, 117, 0.7) !important; font-size: 10px !important; }
    .lmm-wp-confirm:hover { color: #e06c75 !important; }

    /* Capsule strip. */
    .lmm-inbox {
        display:       flex;
        flex-wrap:     wrap;
        gap:           4px;
        align-items:   center;
        padding:       5px 6px;
        min-height:    30px;
        background:    rgba(0, 0, 0, 0.35);
        border-bottom: 1px solid rgba(229, 192, 123, 0.12);
        flex-shrink:   0;
    }
    .lmm-capsule {
        display:       flex;
        align-items:   center;
        gap:           3px;
        background:    rgba(229, 192, 123, 0.08);
        border:        1px solid rgba(229, 192, 123, 0.28);
        border-radius: 3px;
        padding:       3px 4px 3px 3px;
        font-family:   inherit;
        line-height:   1;
    }
    .lmm-capsule-dormant {
        background:   rgba(80, 90, 100, 0.12);
        border-color: rgba(80, 100, 120, 0.25);
    }
    .lmm-capsule-bad      { border-color: rgba(224, 108, 117, 0.35); }
    .lmm-capsule-ghost    { opacity: 0.35; }
    .lmm-capsule-dim      { opacity: 0.6; }
    /* U%unaccepted — virtual deletion */
    .lmm-capsule-unaccepted {
        background:   rgba(224, 108, 117, 0.06);
        border-color: rgba(224, 108, 117, 0.2);
    }
    .lmm-capsule-unaccepted .lmm-capsule-label {
        text-decoration: line-through;
        color:           rgba(224, 108, 117, 0.5);
    }
    /* Orb — the showing toggle. */
    .lmm-capsule-orb {
        display:       block;
        width:         8px;
        height:        8px;
        border-radius: 50%;
        flex-shrink:   0;
        background:    transparent;
        border:        1px solid rgba(229, 192, 123, 0.4);
        cursor:        pointer;
        padding:       0;
        transition:    background 0.12s, box-shadow 0.12s;
    }
    .lmm-capsule-orb.lmm-capsule-orb-show {
        background:   #e5c07b;
        border-color: #e5c07b;
        box-shadow:   0 0 4px #e5c07b88;
    }
    .lmm-capsule-bad .lmm-capsule-orb      { border-color: rgba(224, 108, 117, 0.5); }
    .lmm-capsule-bad .lmm-capsule-orb-show { background: #e06c75; border-color: #e06c75; box-shadow: 0 0 4px #e06c7588; }
    .lmm-capsule-orb.lmm-capsule-orb-unshowing {
        background:   transparent;
        border-color: rgba(229, 192, 123, 0.2);
        box-shadow:   none;
    }
    .lmm-capsule-orb:hover { opacity: 0.75; }
    /* Label */
    .lmm-capsule-label {
        background:    none;
        border:        none;
        cursor:        pointer;
        color:         #e5c07b;
        font-family:   inherit;
        font-size:     10px;
        line-height:   1.3;
        padding:       0;
        max-width:     90px;
        overflow:      hidden;
        text-overflow: ellipsis;
        white-space:   nowrap;
    }
    .lmm-capsule-label:hover                { color: #fff; }
    .lmm-capsule-dormant .lmm-capsule-label { color: #4a6070; }
    .lmm-capsule-bad     .lmm-capsule-label { color: #e06c75; text-decoration: line-through; }
    /* patch body — the slot for search hits and encode diffs */
    .lmm-capsule-body {
        font-size:   9px;
        line-height: 1.3;
        margin:      0;
        white-space: pre-wrap;
        word-break:  break-all;
        max-width:   180px;
        color:       #8a98a8;
    }
    /* × demote */
    .lmm-capsule-demote {
        background:  none;
        border:      none;
        cursor:      pointer;
        color:       #3a5060;
        font-family: inherit;
        font-size:   10px;
        padding:     0 1px;
        line-height: 1;
    }
    .lmm-capsule-demote:hover { color: #e06c75; }
    /* ↺ accept */
    .lmm-capsule-accept {
        background:  none;
        border:      none;
        cursor:      pointer;
        color:       #4a7060;
        font-family: inherit;
        font-size:   10px;
        padding:     0 1px;
        line-height: 1;
    }
    .lmm-capsule-accept:hover { color: #89c06b; }
    /* → next What */
    .lmm-cursor-next {
        background:  none;
        border:      none;
        cursor:      pointer;
        color:       #2a4a5a;
        font-size:   11px;
        padding:     0 3px;
        font-family: inherit;
        margin-left: auto;
    }
    .lmm-cursor-next:hover { color: #c0d0e0; }
</style>
