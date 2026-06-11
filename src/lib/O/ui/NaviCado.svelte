<script lang="ts">
    // NaviCado — What-navigation toolbar + tools row + capsule strip.
    //
    // ── What this is ─────────────────────────────────────────────────────────
    //
    //   Toolbar for the active Understanding (%LE) plus the tools row for
    //   branch|dive gestures, Point injection, and req:desire transport.
    //   Owns the capsule strip and the unsent bar.
    //
    //   The strip is a pure renderer of %LE: it holds no parallel model.  Each
    //   capsule is one Point of the Understanding, read by joining the working
    //   clone tree (membership + clone//U meanings) to dock/%Pmirrors (the live
    //   CM position + resolved-vs-unresolved state).  Push|reset are op('push')
    //   |op('pull') on %LE; show|drop are e:mark ops on the clone's U node.  No
    //   Lies_accept_What_Point round-trip, no in_group|showing|pushed_snapshot —
    //   %LE is the single source, LE_arm resets it atomically so there is no
    //   coexistence window where a prior What's Points linger.
    //
    // ── Particle sources ──────────────────────────────────────────────────────
    //
    //   H.ave/%Languinio — same-object hold; carries:
    //     /%LE           — the live Understanding
    //     /%dock,active  — the foregrounded %Dock (carries %Pmirrors, %Compile)
    //   H.ave/%examining/%Spotlight,1 — the live cursor (nav-bar target).
    //
    // ── Nav buttons (top row) ─────────────────────────────────────────────────
    //
    //   ↑  ←  →  — emit op(kind) → i_elvisto(Lies, 'operate', { LE, op }) where op
    //   is 'up'|'prev'|'next'.  Handler (LiesEnd e_LE_operate) reads the live
    //   cursor from %examining/%Spotlight and drives movement from there.
    //
    //   < once LE_available_ops is wired into req:checkout, %LE/%moves.sc.ops
    //     replaces the static ↑←→ set with one chip per reachable move,
    //     deduplicated (e.g. ↑ suppressed when it resolves to the same What as ←).
    //
    // ── Tools row (second row, always when LE armed) ──────────────────────────
    //
    //   ↘ dive | ↓ branch — +time gestures.
    //   PeelItem — type a method name, Enter → mark('add', ...).
    //   req:desire transport (‖|▶, →step) — only when req:timemachine exists.
    //   Unsent bar (~↑↩) — overlay shown while %State%changey holds (working has
    //   diverged from origin).  ↑ = op('push'); ↩ = op('pull') (two-tap).
    //
    // ── Capsule strip ────────────────────────────────────────────────────────
    //
    //   One capsule per Point of the Understanding.  Orb = show|unshow toggle
    //   (clone//U%unshowing).  × = drop|undrop (clone//U%unaccepted — virtual
    //   deletion, struck through).  Label click — fires Dock_open%{path,point:spec}
    //   → e_Dock_open → Lang_point_navigate.

    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import type { Snippet } from "svelte"

    // A capsule is one Point of the Understanding, after the clone⨝Pmirror join.
    //   resolved:false — LangGraft has no def in the compile index for this spec
    //     yet (pre-compile, or a rename); rendered dim-red, strikethrough.
    //   unaccepted — clone//U%unaccepted: a virtual deletion, struck through,
    //     undroppable via the × (which toggles back to undrop).
    //   unshowing — clone//U%unshowing: folded out of the CM view; the orb dims.
    type Capsule = {
        spec:       string
        resolved:   boolean
        line:       number
        unaccepted: boolean
        unshowing:  boolean
        cls:        string
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
        (languinio?.ob({ dock: 1, active: 1 })[0]?.sc.dock as string | undefined) ?? ''
    )

    // lang_dock: the actual %Dock particle (carries %Compile, %Pmirrors).
    //   .ob so a %Pmirrors rebuild (graft bumps dock.version) re-derives.
    let lang_dock = $derived(
        active_path
            ? languinio?.ob({ dock: active_path })[0] as TheC | undefined
            : undefined
    )

    // %LE — the live Understanding.  .ob so a re-aim (languinio.i(LE)) re-derives.
    let LE: TheC | undefined = $derived(
        languinio?.ob({ LE: 1 })[0] as TheC | undefined
    )

    // working — the %Seem:working particle; clone_root is its C** root.  Both are
    //   tracked as join inputs: a cursor move bumps working; a clone add|drop on
    //   the root bumps clone_root.  LE_arm + e_LE_mark also bump LE.version, so
    //   void LE?.vers alone covers most, but tracking all three keeps the join
    //   live regardless of which lever moved.
    let working   = $derived(LE?.vers && (LE.o({ Seem: 'working' })[0] as TheC | undefined))
    let clone_root = $derived(working ? (working.sc.C as TheC | undefined) : undefined)

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
    // branch|dive always possible when a target is set
    let has_target = $derived(!!target)

    // ── changey — the unsent-bar signal ───────────────────────────────────────
    //
    //   %State%changey, set by LE_encode_compare when working has diverged from
    //   origin.  LE_encode_compare bumps LE.version on the changey edge, so the
    //   LE?.vers chain link wakes this derive when the encode settles.
    let is_changey = $derived(!!(LE?.vers && (LE.ob({ State: 1 })[0]?.sc.changey)))

    // ── capsule join — LE_clones ⨝ %Pmirrors ───────────────────────────────────
    //
    //   The strip is a join, not a function call: LE_clones / the Pmirror walk
    //   are .o()-internal (no version tracking), so the subscription comes from
    //   voiding the input versions here, not from the calls.  We then re-read the
    //   particle trees inside H.clear (UItime) so a mid-Atime replace() — LE_arm's
    //   Seem drop, Seem_clone_C, Pmirrors.replace, LE_replace_back — is never
    //   caught transacting (which for replace() reads momentarily empty).
    //
    //   Rows are driven by %Pmirrors (the doc-scoped, position-resolved Point
    //   projection); each Pmirror's c.src_clone//U supplies the meanings.  Dropped
    //   Points (clone//U%unaccepted) are excluded from %Pmirrors by LangGraft, so
    //   the direct-%Point residue is appended struck-through from LE_clones.
    //
    //   < capsule identity is sc.method for now — fragile across a method rename.
    //     the durable key is c.Dip: a unique id a Se assigns to every Waft OC at
    //     the Lies end, threaded OC→C through LE so the working clone carries it.
    //     key both the capsule row and %Pmirror,$spec on c.Dip once it exists,
    //     leaving sc.method purely cosmetic.
    let capsules: Capsule[] = $state([])

    const clone_spec = (c: TheC): string | null => {
        const sc = c.sc as any
        const v  = sc.method ?? sc.label ?? sc.Point
        if (v == null || v === 1 || v === true) return null
        return String(v)
    }

    $effect(() => {
        // subscribe to every join input — standalone `void X?.vers` reads then
        //   discards (reactive); the `&&` form would short-circuit before the read.
        void LE?.vers
        void (working as TheC | undefined)?.vers
        void clone_root?.vers
        void lang_dock?.vers
        const le_now   = LE
        const dock_now = lang_dock
        H.clear(async () => {
            const out:  Capsule[] = []
            const seen = new Set<string>()

            // Pmirror rows — accepted Points of the active doc, resolved or not.
            const Pmirrors = dock_now?.o({ Pmirrors: 1 })[0] as TheC | undefined
            for (const pm of (Pmirrors?.o({ Pmirror: 1 }) ?? []) as TheC[]) {
                const spec = (pm.sc.spec as string) || ''
                if (!spec) continue
                const graft = pm.o({ graft: 1 })[0] as TheC | undefined
                const u     = (pm.c.src_clone as TheC | undefined)?.c.U as TheC | undefined
                out.push({
                    spec,
                    resolved:   !!graft,
                    line:       (graft?.sc.line as number) ?? 0,
                    unaccepted: false,
                    unshowing:  !!u?.sc.unshowing,
                    cls:        (u?.sc.class as string | undefined)
                                ?? (pm.sc.class as string | undefined) ?? '',
                })
                seen.add(spec)
            }

            // Dropped-Point residue — direct %Point clones LangGraft skipped for
            //   being U%unaccepted; shown struck-through so they can be undropped.
            //   (Doc-nested Points have no clone of their own, so per-Point drop is
            //    only representable for direct %Point clones at this granularity.)
            if (le_now) {
                for (const c of (H as any).LE_clones(le_now) as TheC[]) {
                    const spec = clone_spec(c)
                    if (!spec || seen.has(spec)) continue
                    const u = c.c?.U as TheC | undefined
                    if (!u?.sc.unaccepted) continue
                    out.push({
                        spec,
                        resolved:   false,
                        line:       0,
                        unaccepted: true,
                        unshowing:  !!u?.sc.unshowing,
                        cls:        (u?.sc.class as string | undefined) ?? '',
                    })
                }
            }
            capsules = out
        })
    })

    // ── nav | mark actions ──────────────────────────────────────────────────────
    //
    //   op()  — structural cursor move | LE cluster trigger.  To w:Lies for moves
    //     (up|prev|next|branch|dive|next_doc), to w:Lang for push|pull — both land
    //     in e_LE_operate, which dispatches on the op.  Passes %LE as a particle so
    //     handlers need no ave round-trip.
    //   mark() — clone-tree | U mutation (e_LE_mark on w:Lang).
    const op   = (kind: string, extra?: Partial<TheUniversal>) =>
        H.i_elvisto('Lies/Lies', 'operate', { LE, op: kind, ...extra })
    const mark = (kind: string, extra?: Partial<TheUniversal>) =>
        H.i_elvisto('Lang/Lang', 'mark',    { LE, op: kind, ...extra })

    // push|reset are LE cluster triggers, routed to w:Lang's e_LE_operate.
    //   push — e_Lang_LE_push: encode|replace|verify, clean → no-op.
    //   pull — discard working edits, re-pull origin (destructive; two-tap).
    let reset_confirm = $state(false)
    const push  = () => { op('push'); reset_confirm = false }
    const reset = () => {
        if (!reset_confirm) { reset_confirm = true; return }
        op('pull')
        reset_confirm = false
    }

    // orb — show|unshow toggle on the clone's U node.
    const toggle_show = (cap: Capsule) =>
        mark(cap.unshowing ? 'show' : 'unshow', { spec: cap.spec })
    // × — drop|undrop (virtual deletion) on the clone's U node.
    const drop = (cap: Capsule) =>
        mark(cap.unaccepted ? 'undrop' : 'drop', { spec: cap.spec })

    // ── PeelItem — inject a Point into the working C** ────────────────────────
    //
    //   Type a method name and press Enter → mark('add') so the working clone tree
    //   gains the new Point; e_LE_mark bumps LE.version, the strip re-derives and
    //   req_workon re-grafts on the next think.  Only when armed at a %What target.
    let peel_text: string = $state('')

    function peel_commit() {
        const method = peel_text.trim()
        if (method && LE && (LE.sc.target as any)?.sc?.What !== undefined) {
            mark('add', { sc: { Point: 1, method } })
        }
        peel_text = ''
    }

    // Label for the current What — shown in the middle of the toolbar.
    // What:story → sc.What = 'story'; sc.label is a legacy|explicit override.
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
     ↘↓ branch|dive; PeelItem to inject Points; transport when req:desire active.
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

    {#if is_changey}
        <div class="lmm-wp-bar"
             onmouseleave={() => { reset_confirm = false }}>
            <span class="lmm-wp-tilde">~</span>
            {#if !reset_confirm}
                <button class="lmm-wp-arrow" onclick={push} title="Push">↑</button>
                <button class="lmm-wp-arrow" onclick={reset} title="Reset (discard working edits)">↩</button>
            {:else}
                <button class="lmm-wp-arrow lmm-wp-confirm" onclick={reset}>sure?</button>
            {/if}
        </div>
    {/if}

</div>

{/if}

<!-- Capsule strip — one capsule per Point of the Understanding.
     Orb = show|unshow toggle.  × = drop|undrop (struck through when unaccepted). -->
{#if capsules.length > 0}
    <div class="lmm-inbox"
         onmouseleave={() => { reset_confirm = false }}>
        {#each capsules as cap (cap.spec)}
            <div class="lmm-capsule"
                 class:lmm-capsule-bad={cap.resolved === false && !cap.unaccepted}
                 class:lmm-capsule-dormant={cap.unshowing}
                 class:lmm-capsule-unaccepted={cap.unaccepted}>
                <button class="lmm-capsule-orb"
                        class:lmm-capsule-orb-show={!cap.unshowing}
                        class:lmm-capsule-orb-unshowing={cap.unshowing}
                        title={cap.unshowing ? 'Hidden — click to show' : 'Showing — click to hide'}
                        disabled={cap.unaccepted}
                        onclick={() => toggle_show(cap)}>
                </button>
                <button class="lmm-capsule-label"
                        title="{cap.spec}{!cap.resolved && !cap.unaccepted ? ' (unresolved)' : cap.resolved ? ` → line ${cap.line}` : ''}"
                        onclick={() => {
                            // Dock_open with point:spec → e_Dock_open → Lang_point_navigate
                            H.i_elvisto('Lang/Lang', 'Dock_open', { path: active_path, point: cap.spec })
                        }}>
                    {cap.spec}
                </button>
                <!-- × drop|undrop on the clone's U node (virtual deletion) -->
                <button class="lmm-capsule-demote"
                        title={cap.unaccepted ? 'Restore Point' : 'Drop Point'}
                        onclick={() => drop(cap)}>{cap.unaccepted ? '↺' : '×'}</button>
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
