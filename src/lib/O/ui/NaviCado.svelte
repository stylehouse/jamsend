<script lang="ts">
    // NaviCado — What-navigation toolbar + capsule strip above the DocMinimap region strip.
    //
    // ── What this is ─────────────────────────────────────────────────────────
    //
    //   Toolbar for the active Understanding (%LE) plus the transport bar for
    //   req:desire playback.  Owns the Pmirror capsule strip and the unsent bar.
    //   Self-supplies everything from H — derives languinio, LE, active_path,
    //   and lang_dock without props from DocMinimap.
    //
    // ── Particle sources ──────────────────────────────────────────────────────
    //
    //   H.ave/%Languinio — same-object hold; carries:
    //     /%LE           — the live Understanding
    //     /%dock,path    — the foregrounded %Dock (active:1)
    //   H.ave/%examining/%Spotlight,1 — sc.accepted_push_id / sc.accepted_entries
    //     echoed back from Lies_accept_What_Point round-trip.
    //
    // ── Nav buttons ──────────────────────────────────────────────────────────
    //
    //   ↑  ←  →  — up / prev / next What via c.up chain
    //   ↘  ↓     — branch (new sibling) / dive (new child) What
    //
    //   Transport bar (when req:timemachine exists):
    //   ‖/▶  — i_elvisto Lies_desire_pause / Lies_desire_play
    //   →    — i_elvisto Lies_desire_step
    //
    // ── Capsule strip ────────────────────────────────────────────────────────
    //
    //   in_group — specs currently in the strip (session only).
    //   showing  — subset of in_group whose fold/glow is active (session only).
    //   Orb = showing toggle.  × = demote; never re-auto-promotes.
    //   Auto-promoted on first Pmirror arrival; pushed_snapshot syncs so the
    //   unsent bar stays hidden until the user actually changes something.
    //
    //   Capsule label click — < fires Lang_navigate_to; needs handler on Lang side.
    //   × fires e_Lang_LE_drop when LE is armed at a %What; else local demote().
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

    let { H, slot_up, slot_prev, slot_next, slot_branch, slot_dive }: {
        H:            House
        slot_up?:     Snippet<[{ ghosted: boolean, onclick: () => void }]>
        slot_prev?:   Snippet<[{ ghosted: boolean, onclick: () => void }]>
        slot_next?:   Snippet<[{ ghosted: boolean, onclick: () => void }]>
        slot_branch?: Snippet<[{ ghosted: boolean, onclick: () => void }]>
        slot_dive?:   Snippet<[{ ghosted: boolean, onclick: () => void }]>
    } = $props()

    // ── particle derivation ───────────────────────────────────────────────────

    let languinio: TheC | undefined = $state()
    $effect(() => {
        languinio = H.ave.ob({ Languinio: 1 })[0] as TheC | undefined
    })

    // active_path: which dock is currently foregrounded.
    // %Languinio/%dock,path with active:1 carries sc.dock = the path string.
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

    // LE.vers is always >= 1 (truthy) — safe chain link that registers the read.
    let target     = $derived(LE && LE.vers && LE.sc.target as TheC | undefined)
    let depth      = $derived(target ? (H as any).LE_what_depth(target) as number : -1)
    let has_prev   = $derived(target ? !!(H as any).LE_what_prev(target) : false)
    let has_next   = $derived(has_next_val)
    let has_up     = $derived(depth > 0)
    let has_branch = $derived(!!target)   // ↓ new next sibling — always possible
    let has_dive   = $derived(!!target)   // ↘ new child — always possible
    // has_prev: direct sibling only (no fall-back for ←)
    // has_next: walks c.up so → stays live when the current level has no more siblings
    //   but an ancestor does — "falling out of depth"
    let has_next_val = $derived(target && LE?.vers ? (() => {
        let node: any = target
        while (node) {
            if ((H as any).LE_what_next(node)) return true
            node = (H as any).LE_what_parent(node) as any
        }
        return false
    })() : false)

    // ── transport ─────────────────────────────────────────────────────────────
    //   The timemachine lives on %examining (s3f).  vers-chains keep reads
    //   reactive — vers is always >= 1 (truthy).

    let examining   = $derived(H.ave.ob({ examining: 1 })[0] as TheC | undefined)
    let timemachine = $derived(examining && examining.vers
        && examining.o({ req: 'timemachine' })[0] as TheC | undefined)
    let is_playing  = $derived(!!(timemachine && timemachine.vers && timemachine.sc.playing))
    let has_desire  = $derived(!!timemachine)

    // ── capsule state ─────────────────────────────────────────────────────────

    let in_group:        Set<string> = $state(new Set())
    let showing:         Set<string> = $state(new Set())
    // JSON of in_group+showing at last push or auto-promote sync.
    // '' means nothing synced yet — unsent bar stays hidden.
    let pushed_snapshot: string      = $state('')
    let reset_confirm:   boolean     = $state(false)

    // Non-reactive; reset on path switch alongside the reactive state.
    let _auto_promoted: Set<string> = new Set()   // specs ever auto-promoted this session
    let _user_demoted:  Set<string> = new Set()   // specs user explicitly x'd; never re-auto-promote
    let _our_last_push_id = 0

    let all_marks:    PointMark[]                                               = $state([])
    let le_membership: Map<string, { unaccepted: boolean, unshowing: boolean }> = $state(new Map())

    function current_what_point_json(): string {
        const entries = [...in_group].map(spec => ({ spec, showing: showing.has(spec) }))
        return JSON.stringify(entries)
    }

    // Only show the unsent bar once the user has changed something from the
    // last auto-synced or pushed state.  Never show if nothing was ever synced.
    let is_dirty = $derived(pushed_snapshot !== '' && current_what_point_json() !== pushed_snapshot)

    // ── doc switch ────────────────────────────────────────────────────────────

    let _last_path = ''
    $effect(() => {
        if (active_path !== _last_path) {
            in_group        = new Set()
            showing         = new Set()
            pushed_snapshot = ''
            reset_confirm   = false
            _auto_promoted  = new Set()
            _user_demoted   = new Set()
            _last_path      = active_path
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
    //   Points keyed by value (Point:transport) join correctly against capsule specs.
    //
    //   Gate: LE must be armed at a %What src so the clone list is the What's
    //   Points; returns an empty Map for bare %Doc sessions.
    function collect_le_membership(): Map<string, { unaccepted: boolean, unshowing: boolean }> {
        const out = new Map<string, { unaccepted: boolean, unshowing: boolean }>()
        if (!LE) return out
        const target_c = LE.sc.target as TheC | undefined
        // bare %Doc as target has no .What on sc — skip
        if (!target_c || (target_c.sc as any).What === undefined) return out
        const clones = (H as any).LE_clones(LE) as TheC[]
        for (const c of clones) {
            const sc  = c.sc as any
            // mirror Lang_point_spec resolution order
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
    //   Fires on e_Lies_accept_What_Point round-trip and on e_Lies_cursor_next
    //   (the restored Spotlight from the next Doc's stored set).
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

    // Called when Lies sends a new What_Point replacing what Lang is working from.
    // Drops any unpushed local state and installs the Lies-side view.
    function receive_what_point_from_lies(entries: { spec: string, showing: boolean }[]) {
        _auto_promoted  = new Set(entries.map(e => e.spec))
        _user_demoted   = new Set()
        in_group        = new Set(entries.map(e => e.spec))
        showing         = new Set(entries.filter(e => e.showing).map(e => e.spec))
        pushed_snapshot = JSON.stringify(entries)
        reset_confirm   = false
    }

    // Demote: remove from in_group+showing and prevent future auto-promotion.
    function demote(spec: string) {
        _user_demoted.add(spec)
        const ig = new Set(in_group); ig.delete(spec)
        const sh = new Set(showing);  sh.delete(spec)
        in_group      = ig
        showing       = sh
        reset_confirm = false
    }

    // Toggle showing for an in-group spec (active vs dormant).
    // < should also fire i_elvisto to update fold/glow in CM for this spec.
    function toggle_showing(spec: string) {
        const sh = new Set(showing)
        if (sh.has(spec)) sh.delete(spec)
        else              sh.add(spec)
        showing       = sh
        reset_confirm = false
    }

    // Push current in_group+showing to Lies.
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

    // Revert local in_group+showing to the last pushed/synced state.
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

    // Advance Lies cursor to the next Doc across all loaded Wafts.
    // < What-level navigation (sibling time-slices) is a future arc.
    function cursor_next() {
        H.i_elvisto('Lies/Lies', 'Lies_cursor_next', { dock_path: active_path })
    }

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
        // fall out of depth: climb until we find an ancestor with a next sibling
        let node: any = target
        while (node) {
            const next = (H as any).LE_what_next(node) as TheC | undefined
            if (next) { H.i_elvisto('Lies/Lies', 'Lies_cursor_what', { what: next }); return }
            node = (H as any).LE_what_parent(node) as any
        }
    }

    function go_branch() {
        if (!target) return
        H.i_elvisto('Lies/Lies', 'Lies_branch_what', { what: target })
    }

    function go_dive() {
        if (!target) return
        H.i_elvisto('Lies/Lies', 'Lies_dive_what', { what: target })
    }

    // Label for the current What — shown in the middle of the toolbar.
    // Falls back to path stem when target is a %Doc (no .label or .What on sc).
    let what_label = $derived(
        target
            ? ((target.sc as any).label as string | undefined)
              ?? ((target.sc as any).path as string | undefined)?.split('/').pop()
              ?? ''
            : ''
    )
</script>

{#if LE && target}
<div class="nvc-bar">

    <!-- up — ghosted at top level -->
    <div class="nvc-seed" class:nvc-ghost={!has_up}>
        {#if slot_up}
            {@render slot_up({ ghosted: !has_up, onclick: go_up })}
        {:else}
            <button class="nvc-btn" class:nvc-ghosted={!has_up}
                    disabled={!has_up} onclick={go_up} title="Up to parent What">↑</button>
        {/if}
    </div>

    <!-- prev -->
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

    <!-- next -->
    <div class="nvc-seed" class:nvc-ghost={!has_next}>
        {#if slot_next}
            {@render slot_next({ ghosted: !has_next, onclick: go_next })}
        {:else}
            <button class="nvc-btn" class:nvc-ghosted={!has_next}
                    disabled={!has_next} onclick={go_next} title="Next What">→</button>
        {/if}
    </div>

    <!-- ↘ dive — new child %What inside current (go deeper) -->
    <div class="nvc-seed" class:nvc-ghost={!has_dive}>
        {#if slot_branch}
            {@render slot_branch({ ghosted: !has_dive, onclick: go_dive })}
        {:else}
            <button class="nvc-btn" class:nvc-ghosted={!has_dive}
                    disabled={!has_dive} onclick={go_dive}
                    title="Child (↘ new What inside current)">↘</button>
        {/if}
    </div>

    <!-- ↓ branch — new next sibling %What after current -->
    <div class="nvc-seed" class:nvc-ghost={!has_branch}>
        {#if slot_dive}
            {@render slot_dive({ ghosted: !has_branch, onclick: go_branch })}
        {:else}
            <button class="nvc-btn" class:nvc-ghosted={!has_branch}
                    disabled={!has_branch} onclick={go_branch}
                    title="Next (↓ new sibling What after current)">↓</button>
        {/if}
    </div>

</div>

<!-- Transport bar — only when req:desire is active.
     The unsent bar overlays the right side of this row absolutely so it
     doesn't add any height; stays hidden until something is dirty. -->
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

{/if}

<!-- In-group capsule strip.
     All Pmirrors auto-promote here on arrival.
     Orb = showing toggle.  x = demote (always visible). -->
{#if in_group.size > 0}
    <div class="lmm-inbox"
         onmouseleave={() => { reset_confirm = false }}>
        {#each [...in_group] as spec (spec)}
            {@const mark = all_marks.find(p => p.spec === spec)}
            {@const is_sh = showing.has(spec)}
            {@const mem  = le_membership.get(spec)}
            <div class="lmm-capsule"
                 class:lmm-capsule-bad={mark?.unresolved}
                 class:lmm-capsule-dormant={!is_sh}
                 class:lmm-capsule-unaccepted={mem?.unaccepted}>
                <button class="lmm-capsule-orb"
                        class:lmm-capsule-orb-show={is_sh && !mem?.unshowing}
                        class:lmm-capsule-orb-unshowing={mem?.unshowing}
                        title={is_sh ? 'Showing — click to make dormant' : 'Dormant — click to show'}
                        onclick={() => toggle_showing(spec)}>
                </button>
                <button class="lmm-capsule-label"
                        title="{spec}{mark?.unresolved ? ' (unresolved)' : mark ? ` → line ${mark.line}` : ''}"
                        onclick={() => {
                            // < fire Lang_navigate_to once wired on Lang side
                            if (mark) H.i_elvisto('Lang/Lang', 'Lang_navigate_to', { from: mark.from, to: mark.to, spec })
                        }}>
                    {spec}
                </button>
                {#if !is_sh}
                    <!-- x fires e_Lang_LE_drop when LE is armed at a %What;
                         falls back to local demote() for bare %Doc sessions. -->
                    <button class="lmm-capsule-demote" title="Remove Point" onclick={() => {
                        if (LE && (LE.sc.target as any)?.sc?.What !== undefined) {
                            H.i_elvisto('Lang/Lang', 'Lang_LE_drop', { spec })
                        } else {
                            demote(spec)
                        }
                    }}>×</button>
                {/if}
            </div>
        {/each}
        <!-- Step Lies cursor to the next What in the Waft order. -->
        <button class="lmm-cursor-next" title="Next What in Waft" onclick={cursor_next}>→</button>
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

    /* Transport bar — play/pause + step for req:desire playback.
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

    .nvc-t-label {
        font-size:  9px;
        color:      #3a4555;
        font-style: italic;
        flex:       1;
    }

    /* Unsent bar — abs overlay on the right of the transport row.
       ~ up reset floats over the label area; adds no row height. */
    .lmm-wp-bar {
        position:    absolute;
        right:       0;
        top:         0;
        bottom:      0;
        display:     flex;
        flex-direction: row;
        align-items: center;
        gap:         3px;
        padding:     0 6px;
        background:  rgba(16, 20, 28, 0.96);
        border-left: 1px solid rgba(229, 192, 123, 0.15);
    }

    .lmm-wp-tilde {
        font-size:   11px;
        line-height: 1;
        color:       rgba(229, 192, 123, 0.4);
    }

    .lmm-wp-arrow {
        background:   none;
        border:       none;
        cursor:       pointer;
        font-family:  inherit;
        font-size:    13px;
        line-height:  1;
        color:        rgba(229, 192, 123, 0.45);
        padding:      0 2px;
    }
    .lmm-wp-arrow:hover   { color: #e5c07b; }
    .lmm-wp-confirm       { color: rgba(224, 108, 117, 0.7) !important; font-size: 10px !important; }
    .lmm-wp-confirm:hover { color: #e06c75 !important; }

    /* In-group capsule strip — all Pmirrors live here, none in the region body. */
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

    /* U%unaccepted — virtual deletion; cross out the label, red tint */
    .lmm-capsule-unaccepted {
        background:   rgba(224, 108, 117, 0.06);
        border-color: rgba(224, 108, 117, 0.2);
    }
    .lmm-capsule-unaccepted .lmm-capsule-label {
        text-decoration: line-through;
        color:           rgba(224, 108, 117, 0.5);
    }

    /* Orb inside capsule — the showing toggle. */
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
    /* U%unshowing — orb shows a dim ring rather than full gold */
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

    /* x always visible — primary demote control. */
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

    /* Cursor advance — steps Lies to next What_Point. */
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
