<script lang="ts">
    // NaviCado — What-navigation toolbar + tools row + capsule strip.
    //
    // ── What this is ─────────────────────────────────────────────────────────
    //
    //   Toolbar for the active Understanding (%LE) plus the tools row for
    //   branch/dive gestures, Point injection, and req:desire transport.
    //   Owns the Pmirror capsule strip and the unsent bar.
    //
    // ── Particle sources ──────────────────────────────────────────────────────
    //
    //   H.ave/%Languinio — same-object hold; carries:
    //     /%LE           — the live Understanding
    //     /%dock,path    — the foregrounded %Dock (active:1)
    //   H.ave/%examining/%Spotlight,1 — sc.accepted_push_id / sc.accepted_entries
    //     echoed back from Lies_accept_What_Point round-trip.
    //
    // ── Nav buttons (top row) ─────────────────────────────────────────────────
    //
    //   ↑  ←  →  — emit op(kind) → i_elvisto(Lies, 'operate', { LE, op }) where op is
    //   'up'/'prev'/'next'.  Handler (LiesCurse) reads the live cursor from
    //   %examining/%Spotlight and drives movement from there.
    //
    //   < once LE_available_ops is wired into req:checkout, %LE/%moves.sc.ops
    //     replaces the static ↑←→ set with one chip per reachable move,
    //     deduplicated (e.g. ↑ suppressed when it resolves to the same What as ←).
    //
    // ── Tools row (second row, always when LE armed) ──────────────────────────
    //
    //   ↘ dive / ↓ branch — moved here from the nav bar.
    //   PeelItem — type a method name, Enter → mark('add', ...).
    //   req:desire transport (‖/▶, →step) — only when req:timemachine exists.
    //   Unsent bar (~↑↩) — absolute overlay when in_group state has drifted.
    //
    // ── Capsule strip ────────────────────────────────────────────────────────
    //
    //   in_group — specs currently in the strip (session only).
    //   showing  — subset of in_group whose fold/glow is active (session only).
    //   Orb = showing toggle.  × = demote; never re-auto-promotes.
    //   Auto-promoted on first Pmirror arrival; pushed_snapshot syncs so the
    //   unsent bar stays hidden until the user actually changes something.
    //
    //   Capsule label click — fires Dock_open%{path,point:spec} → e_Dock_open → Lang_point_navigate.
    //   × fires mark('drop', ...) when LE is armed at a %What; else
    //   local demote() for bare %Doc sessions.
    //   Push fires Lies_accept_What_Point; Reset reverts to pushed_snapshot (two-tap).

    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import type { Snippet } from "svelte"

    // A Point becomes a PointMark once its graft fields have been stamped by
    // Lang_graft_points.  unresolved:true means LangGraft hasn't found the
    // method in the compile index yet (pre-compile, or name changed).
    type PointMark = {
        spec:       string
        method:     string
        line:       number
        from:       number
        to:         number
        unresolved: boolean
    }

    let { H, slot_up, slot_prev, slot_next }: {
        H:         House
        slot_up?:  Snippet<[{ ghosted: boolean, onclick: () => void }]>
        slot_prev?: Snippet<[{ ghosted: boolean, onclick: () => void }]>
        slot_next?: Snippet<[{ ghosted: boolean, onclick: () => void }]>
    } = $props()

    // ── particle derivation ───────────────────────────────────────────────────

    let languinio: TheC | undefined = $state()
    $effect(() => {
        languinio = H.ave.ob({ Languinio: 1 })[0] as TheC | undefined
    })

    // active_path: which dock is currently foregrounded.
    let active_path = $derived(
        (languinio?.ob({ dock:1,active: 1 })[0]?.sc.dock as string | undefined) ?? ''
    )

    // lang_dock: the actual %Dock particle (carries Compile, Pmirrors etc.).
    let lang_dock: TheC | undefined = $state()
    $effect(() => {
        lang_dock = active_path
            ? languinio?.ob({ dock: active_path })[0] as TheC | undefined
            : undefined
    })
    let LE: TheC | undefined = $derived(
        languinio?.ob({ LE: 1 })[0] as TheC | undefined
    )

    // ── nav bar reactive derivation ───────────────────────────────────────────

    // examining first — target derives from it, not LE.sc.target.
    // LE.sc.target lags by one LE_arm + languinio round-trip; examining.Spotlight.sc.src
    // is stamped synchronously in Lies_i_Spotlight so the nav bar updates immediately.
    let examining   = $derived(H.ave.ob({ examining: 1 })[0] as TheC | undefined)
    let timemachine = $derived(examining && examining.vers
        && examining.o({ req: 'timemachine' })[0] as TheC | undefined)
    let is_playing  = $derived(!!(timemachine && timemachine.vers && timemachine.sc.playing))
    let has_desire  = $derived(!!timemachine)

    // target — the currently cursored %What, from examining/Spotlight.
    // Only set when src is a %What (not a bare %Doc).
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
    // branch/dive always possible when a target is set
    let has_target = $derived(!!target)

    // ── capsule state ─────────────────────────────────────────────────────────

    let in_group:        Set<string> = $state(new Set())
    let showing:         Set<string> = $state(new Set())
    // '' means nothing synced yet — unsent bar stays hidden.
    let pushed_snapshot: string      = $state('')
    let reset_confirm:   boolean     = $state(false)

    // Non-reactive; reset on path switch alongside the reactive state.
    let _auto_promoted: Set<string> = new Set()
    let _user_demoted:  Set<string> = new Set()
    let _our_last_push_id = 0

    let all_marks:    PointMark[]                                               = $state([])
    let le_membership: Map<string, { unaccepted: boolean, unshowing: boolean }> = $state(new Map())

    function current_what_point_json(): string {
        const entries = [...in_group].map(spec => ({ spec, showing: showing.has(spec) }))
        return JSON.stringify(entries)
    }

    let is_dirty = $derived(pushed_snapshot !== '' && current_what_point_json() !== pushed_snapshot)

    // ── Understanding switch — reset the strip when the checkout moves ─────────
    //
    //   Keyed on %Interest's in_What|in_Doc, not active_path.  A What hop on the
    //   same Doc leaves active_path untouched yet checks out a different Point
    //   set, so an active_path-only reset left the prior What's specs lingering
    //     as spurious capsules — and with no live %Pmirror behind them (pm
    //     undefined) they rendered as resolved.
    //   The Understanding identity moves on every checkout, so this shakes the
    //     strip clean on a same-Doc hop too.
    let understanding_key = $derived.by(() => {
        const interest = languinio?.ob({ Interest: 1 })[0] as TheC | undefined
        void interest?.vers
        const in_What = (interest?.sc.in_What as string | undefined) ?? ''
        const in_Doc  = (interest?.sc.in_Doc  as string | undefined) ?? ''
        return `${in_What}|${in_Doc}`
    })

    let _last_uk = ''
    $effect(() => {
        if (understanding_key !== _last_uk) {
            in_group        = new Set()
            showing         = new Set()
            pushed_snapshot = ''
            reset_confirm   = false
            _auto_promoted  = new Set()
            _user_demoted   = new Set()
            _last_uk        = understanding_key
        }
    })

    // ── collect_graft_marks ───────────────────────────────────────────────────
    //
    //   Walk lang_dock/%Pmirrors,1/%Pmirror,N.  A Pmirror with %graft,1 has been
    //   resolved (live position from compile index); one without is unresolved.
    function collect_graft_marks(): PointMark[] {
        const out: PointMark[] = []
        if (!lang_dock) return out
        const Pmirrors = lang_dock.o({ Pmirrors: 1 })[0] as TheC | undefined
        if (!Pmirrors) return out
        for (const pm of Pmirrors.o({ Pmirror: 1 }) as TheC[]) {
            const spec = (pm.sc.spec as string) || ''
            if (!spec) continue
            const graft = pm.o({ graft: 1 })[0] as TheC | undefined
            if (!graft) {
                out.push({ spec, method: spec, line: 1, from: 0, to: 0, unresolved: true })
                continue
            }
            out.push({
                spec,
                method:     spec,
                line:       graft.sc.line as number,
                from:       graft.sc.from as number,
                to:         graft.sc.to   as number,
                unresolved: false,
            })
        }
        return out
    }

    // ── collect_le_membership ─────────────────────────────────────────────────
    //
    //   Walk LE's working clones and return a Map of spec to membership flags.
    //   Membership (unaccepted, unshowing) is OF the Point within the Understanding,
    //   not IN the Point — it lives on clone.c.U.sc.
    //   class lives on clone.sc directly (not U).
    //
    //   Spec resolution mirrors Lang_point_spec: method ?? label ?? Point-value.
    //   Gate: LE must be armed at a %What src; empty Map for bare %Doc sessions.
    function collect_le_membership(): Map<string, { unaccepted: boolean, unshowing: boolean }> {
        const out = new Map<string, { unaccepted: boolean, unshowing: boolean }>()
        if (!LE?.oa({ Seem: 'working' })) return out   // don't oai() — not ready to insert
        const target_c = LE.sc.target as TheC | undefined
        if (!target_c || (target_c.sc as any).What === undefined) return out
        const clones = (H as any).LE_clones(LE) as TheC[]
        for (const c of clones) {
            const sc  = c.sc as any
            const raw = sc.method ?? sc.label ?? sc.Point
            if (raw == null || raw === 1 || raw === true) continue
            const spec = String(raw)
            out.set(spec, {
                unaccepted: !!(c.c?.U?.sc?.unaccepted),
                unshowing:  !!(c.c?.U?.sc?.unshowing),
            })
        }
        return out
    }

    // ── rebuild marks when Pmirrors or LE change ──────────────────────────────

    $effect(() => {
        void lang_dock?.vers
        void LE?.vers
        if (!LE?.oa({ Seem: 'working' })) return   // don't oai() create this accidentally!
        const marks      = collect_graft_marks()
        const membership = collect_le_membership()

        // Auto-promote newly arrived specs into in_group + showing.
        // Skips specs the user has explicitly demoted this session.
        // After promotion, syncs pushed_snapshot so the bar doesn't appear yet.
        const auto_ig = new Set(in_group)
        const auto_sh = new Set(showing)
        let did_promote = false
        for (const mark of marks) {
            if (_user_demoted.has(mark.spec))  continue
            if (_auto_promoted.has(mark.spec)) continue
            _auto_promoted.add(mark.spec)
            auto_ig.add(mark.spec)
            auto_sh.add(mark.spec)
            did_promote = true
        }
        if (did_promote) {
            in_group        = auto_ig
            showing         = auto_sh
            pushed_snapshot = JSON.stringify([...auto_ig].map(s => ({ spec: s, showing: auto_sh.has(s) })))
            reset_confirm   = false
        }

        all_marks     = marks
        le_membership = membership
    })

    // ── Spotlight echo — receive pushed state from Lies ───────────────────────
    //
    //   Fires on e_Lies_accept_What_Point round-trip.
    //   Our own push is identified by _our_last_push_id — ignore to avoid loop.
    $effect(() => {
        void examining?.vers
        const spot    = examining?.o?.({ Spotlight: 1 })?.[0] as TheC | undefined
        const push_id = spot?.sc.accepted_push_id as number | undefined
        const entries = spot?.sc.accepted_entries as { spec: string, showing: boolean }[] | undefined
        if (!push_id || !entries) return
        if (push_id === _our_last_push_id) return
        receive_what_point_from_lies(entries)
    })

    // ── capsule actions ───────────────────────────────────────────────────────

    function receive_what_point_from_lies(entries: { spec: string, showing: boolean }[]) {
        _auto_promoted  = new Set(entries.map(e => e.spec))
        _user_demoted   = new Set()
        in_group        = new Set(entries.map(e => e.spec))
        showing         = new Set(entries.filter(e => e.showing).map(e => e.spec))
        pushed_snapshot = JSON.stringify(entries)
        reset_confirm   = false
    }

    // Demote: remove from in_group+showing and prevent future auto-promotion.
    // Used for bare %Doc sessions; armed %What sessions go through LE_operate.
    function demote(spec: string) {
        _user_demoted.add(spec)
        const ig = new Set(in_group); ig.delete(spec)
        const sh = new Set(showing);  sh.delete(spec)
        in_group      = ig
        showing       = sh
        reset_confirm = false
    }

    // Toggle showing for an in-group spec (active vs dormant).
    // Local showing set controls the CM fold/glow (session-only view state).
    // U%unshowing on the clone is the Understanding-level persistence — both
    // are toggled here so the UI strip and the U sphere stay in agreement.
    function toggle_showing(spec: string) {
        const is_unshowing = le_membership.get(spec)?.unshowing
        const sh = new Set(showing)
        if (sh.has(spec)) sh.delete(spec)
        else              sh.add(spec)
        showing       = sh
        reset_confirm = false
        // fire U-sphere mutation when LE is armed at a %What
        if (LE && (LE.sc.target as any)?.sc?.What !== undefined)
            mark(is_unshowing ? 'show' : 'unshow', { spec })
    }

    function push_what_point() {
        const snap = current_what_point_json()
        _our_last_push_id = Date.now()
        H.i_elvisto('Lies/Lies', 'Lies_accept_What_Point', {
            dock_path:  active_path,
            what_point: JSON.parse(snap),
        })
        pushed_snapshot = snap
        reset_confirm   = false
    }

    // Two-tap: first tap arms; second tap executes.
    function reset_what_point() {
        if (!reset_confirm) { reset_confirm = true; return }
        if (pushed_snapshot) {
            const entries: { spec: string, showing: boolean }[] = JSON.parse(pushed_snapshot)
            in_group = new Set(entries.map(e => e.spec))
            showing  = new Set(entries.filter(e => e.showing).map(e => e.spec))
        } else {
            in_group = new Set()
            showing  = new Set()
        }
        reset_confirm = false
    }

    // ── nav actions ───────────────────────────────────────────────────────────
    //
    //   op()  — structural cursor move to w:Lies (e_operate → e_LE_operate in LiesCurse).
    //   mark() — U-sphere mutation to w:Lang  (e_mark   → e_LE_mark  in Lang).
    //   Both pass LE as a particle so the handlers need no ave round-trip.
    //   op flows through as the %want kind — chatty in the resolver log.
    const op   = (kind: string, extra?: Partial<TheUniversal>) =>
        H.i_elvisto('Lies/Lies', 'operate', { LE, op: kind, ...extra })
    const mark = (kind: string, extra?: Partial<TheUniversal>) =>
        H.i_elvisto('Lang/Lang', 'mark',    { LE, op: kind, ...extra })

    // ── PeelItem — inject a Point into the working C** ────────────────────────
    //
    //   Type a method name and press Enter.  Fires LE_operate{op:'add'} so the
    //   working clone tree gains the new Point immediately; req:understanding re-encodes
    //   on the next think and changey updates.
    //
    //   Only active when LE is armed at a %What target.
    let peel_text: string = $state('')

    function peel_commit() {
        const method = peel_text.trim()
        if (method && LE && (LE.sc.target as any)?.sc?.What !== undefined) {
            mark('add', { sc: { Point: 1, method } })
        }
        peel_text = ''
    }

    // Label for the current What — shown in the middle of the toolbar.
    // What:story → sc.What = 'story'; sc.label is a legacy/explicit override.
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
     Unsent bar overlays the right side absolutely — adds no row height. -->
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

    {#if is_dirty}
        <div class="lmm-wp-bar"
             onmouseleave={() => { reset_confirm = false }}>
            <span class="lmm-wp-tilde">~</span>
            {#if !reset_confirm}
                <button class="lmm-wp-arrow" onclick={push_what_point} title="Push">↑</button>
                <button class="lmm-wp-arrow" onclick={reset_what_point} title="Reset">↩</button>
            {:else}
                <button class="lmm-wp-arrow lmm-wp-confirm" onclick={reset_what_point}>sure?</button>
            {/if}
        </div>
    {/if}

</div>

{/if}

<!-- In-group capsule strip.
     All Pmirrors auto-promote here on arrival.
     Orb = showing toggle.  × = demote (always visible). -->
{#if in_group.size > 0}
    <div class="lmm-inbox"
         onmouseleave={() => { reset_confirm = false }}>
        {#each [...in_group] as spec (spec)}
            {@const pm   = all_marks.find(p => p.spec === spec)}
            {@const is_sh = showing.has(spec)}
            {@const mem  = le_membership.get(spec)}
            <div class="lmm-capsule"
                 class:lmm-capsule-bad={pm?.unresolved}
                 class:lmm-capsule-dormant={!is_sh}
                 class:lmm-capsule-unaccepted={mem?.unaccepted}>
                <button class="lmm-capsule-orb"
                        class:lmm-capsule-orb-show={is_sh && !mem?.unshowing}
                        class:lmm-capsule-orb-unshowing={mem?.unshowing}
                        title={is_sh ? 'Showing — click to make dormant' : 'Dormant — click to show'}
                        onclick={() => toggle_showing(spec)}>
                </button>
                <button class="lmm-capsule-label"
                        title="{spec}{pm?.unresolved ? ' (unresolved)' : pm ? ` → line ${pm.line}` : ''}"
                        onclick={() => {
                            // Dock_open with point:spec → e_Dock_open → Lang_point_navigate
                            H.i_elvisto('Lang/Lang', 'Dock_open', { path: active_path, point: spec })
                        }}>
                    {spec}
                </button>
                {#if !is_sh}
                    <!-- × fires mark('drop') when LE is armed at a %What;
                         falls back to local demote() for bare %Doc sessions. -->
                    <button class="lmm-capsule-demote" title="Remove Point" onclick={() => {
                        if (LE && (LE.sc.target as any)?.sc?.What !== undefined) {
                            mark('drop', { spec })
                        } else {
                            demote(spec)
                        }
                    }}>×</button>
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

    /* Tools row — transport, ↘↓, PeelItem, unsent bar.
       position:relative anchors the unsent bar overlay. */
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

    /* ↘↓ in the tools row — same weight as transport buttons */
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

    /* PeelItem — inline Point injection input. */
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

    /* Unsent bar — absolute overlay on the right of the tools row. */
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

    /* In-group capsule strip. */
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
    .lmm-capsule-bad { border-color: rgba(224, 108, 117, 0.35); }
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
    .lmm-capsule-bad .lmm-capsule-orb       { border-color: rgba(224, 108, 117, 0.5); }
    .lmm-capsule-bad .lmm-capsule-orb-show  { background: #e06c75; border-color: #e06c75; box-shadow: 0 0 4px #e06c7588; }
    /* U%unshowing — dim ring */
    .lmm-capsule-orb.lmm-capsule-orb-unshowing {
        background:   transparent;
        border-color: rgba(229, 192, 123, 0.2);
        box-shadow:   none;
    }
    .lmm-capsule-orb:hover { opacity: 0.75; }
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
    .lmm-capsule-label:hover               { color: #fff; }
    .lmm-capsule-dormant .lmm-capsule-label { color: #4a6070; }
    .lmm-capsule-bad     .lmm-capsule-label { color: #e06c75; text-decoration: line-through; }
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
