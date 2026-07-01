<script lang="ts">
    // InterestStrip — the foreground switcher (Waft_spec §"Presence … and the switcher").
    //
    //   A horizontal strip atop the MiniMap: one button per presence:active Interest
    //   (the giver Trails, a Sidetrack, the GhostList), highlighting the ActiveInterest.
    //   Click foregrounds it; × dismisses it (drops the Lies Waft).  presence:always
    //   Interests (the Ting heat) are ambient — they render in their own slot, never
    //   here, and never steal the stage.
    //
    //   Foreground routes through e_Lang_foreground: heavy kinds (Trail|Sidetrack)
    //   re-checkout via Lies (landing the cursor → arming the LE on that giver's own
    //   Trail); light kinds (GhostList) are a pure face swap.  %ActiveInterest drives
    //   the highlight; with several givers it carries the foreground giver's waft too.

    import type { TheC }  from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import SurprisePopover from "$lib/O/ui/SurprisePopover.svelte"

    let { H }: { H: House } = $props()

    type Row = {
        kind:        string
        waft:        string | undefined
        label:       string
        state:       string
        active:      boolean
        interesting: boolean   // engaged enough to hold a strip slot (else it collapses)
        // the Interest's own properties — what the inspector edits|shows (NOT its Waft
        //  content): the grapple, not the gripped.
        face:        string | undefined
        presence:    string | undefined
        from:        string | undefined   // the anchor it flew off (Sidetrack|Aside) — a posture
        in_doc:      string | undefined   // the doc its cursor is on
        key:         string
    }

    let languinio: TheC | undefined = $state()
    $effect(() => { languinio = H.ave.ob({ Languinio: 1 })[0] as TheC | undefined })

    let active = $derived.by(() => {
        void languinio?.vers
        const ai = languinio?.ob({ ActiveInterest: 1 })[0] as TheC | undefined
        return { kind: ai?.sc.kind as string | undefined, waft: ai?.sc.waft as string | undefined }
    })

    // tail_name — the cap label from a Waft path: the last segment that carries a
    //  letter, so a day-stamped scratch (Aside/2026-06-24) reads as "Aside", not the
    //   date, and a numbered slice (Foo/001) reads as "Foo".  Walks from the end and
    //    skips totally-numbery bits; falls back to the bare last segment if every part
    //     is numbery, then to `fallback` when there's no path at all.
    function tail_name(path: string | undefined, fallback: string): string {
        const segs = (path ?? '').split('/').filter(Boolean)
        for (let i = segs.length - 1; i >= 0; i--) if (/[a-z]/i.test(segs[i])) return segs[i]
        return segs[segs.length - 1] ?? fallback
    }

    // One row per presence:active Interest that hasn't left the roster.  {Interest:1}
    //  wildcards the kind value, so this collects Trail | Sidetrack | GhostList alike.
    let rows: Row[] = $derived.by(() => {
        void languinio?.vers
        if (!languinio) return []
        const out: Row[] = []
        for (const it of languinio.ob({ Interest: 1 }) as TheC[]) {
            if (it.sc.presence !== 'active') continue       // ambient kinds (Ting) live elsewhere
            if (it.sc.state === 'gone') continue            // left the roster
            const kind  = it.sc.Interest as string
            const waft  = it.sc.waft as string | undefined
            const label = kind === 'GhostList' ? 'ghosts'
                        : kind === 'Sidetrack' ? (it.sc.from ? `↳${it.sc.from}` : 'sidetrack')
                        : kind === 'Aside'     ? `🗒 ${tail_name(waft, 'aside')}`
                        : tail_name(waft, 'trail')
            const state    = (it.sc.state as string) ?? 'pending'
            const is_active = active.kind === kind && (active.waft ?? undefined) === (waft ?? undefined)
            // "Interesting" = actually engaged, so it earns a permanent slot: it's the
            //  foreground, it's been locked by a foreground at some point, or it carries
            //  an LE (the editing checkout's c.LE, or an armed {LE} child).  A merely
            //  loaded giver (a passive Trail) and the always-on GhostList sit at 'pending'
            //  with no LE — those collapse into "+N more" until the user reaches for them.
            const interesting = !!(is_active || state === 'locked' || it.c.LE || it.oa({ LE: 1 }))
            out.push({
                kind, waft, label, state,
                active: is_active,
                interesting,
                face:     it.sc.face     as string | undefined,
                presence: it.sc.presence as string | undefined,
                from:     it.sc.from     as string | undefined,
                in_doc:   it.sc.in_Doc   as string | undefined,
                key:    `${kind}:${waft ?? ''}`,
            })
        }
        return out
    })

    // Engaged caps always show; the rest tuck behind a "+N more" toggle so a passive
    //  Credence Trail or the GhostList index doesn't claim the foreground switcher.
    let hot  = $derived(rows.filter(r => r.interesting))
    let cold = $derived(rows.filter(r => !r.interesting))

    // show_cold — the "+N more" quiet-Interest toggle.  PROJECTED off the Keep (P5 layout
    //  service, 'global' chrome pref, Backbone P6) so the strip remembers whether you keep the
    //   quiet Interests unfolded across a reload.  Default folded, so the SHOWN state rides the
    //    flag (1-or-absent: absent ⇒ folded).  w:Lies reached via the shared %examining .c.w,
    //     same as Langui's `expanded`; no Keep (runner | early boot) ⇒ folded default.
    let lies_w = $derived(H.ave.ob({ examining: 1 })[0]?.c?.w as TheC | undefined)
    let show_cold = $derived((() => {
        const w = lies_w
        if (!w) return false
        void (w.o({ Waft: 'Keep' })[0]?.version ?? w.version)   // re-derive when the Keep loads|changes
        return !!H.Lies_keep_layout_get(w, 'global', '', 'isx_show_cold')
    })())
    const toggle_show_cold = () => {
        if (lies_w) H.Lies_keep_layout_set(lies_w, 'global', '', 'isx_show_cold', show_cold ? undefined : 1)
    }

    const foreground = (r: Row) =>
        H.i_elvisto('Lang/Lang', 'Lang_foreground', { kind: r.kind, ...(r.waft ? { waft: r.waft } : {}) })

    // The open|edit mode — the step JUST BEYOND being foregrounded.  Tapping a cap that
    //  isn't the foreground foregrounds it; tapping the one that already IS opens its
    //  inspector.  The inspector manages the INTEREST (the grapple) — a hyperlink to its
    //  Waft, its posture (where it flew off, whether it holds the stage), and a safe
    //  confirm-guarded dismiss — not the Waft's content (that's the editor/NaviCado).
    //  No bare × on the caps: dropping a Waft is a deliberate two-step in here.
    let open_key   = $state<string | undefined>()
    let confirming = $state(false)
    let open_row   = $derived(rows.find(r => r.key === open_key && r.active))

    const tap = (r: Row) => {
        if (r.active) { open_key = open_key === r.key ? undefined : r.key; confirming = false }
        else          { open_key = undefined; foreground(r) }
    }
    // Dismiss acts Lies-side — drop Lies/Waft; the roster re-push then marks it gone.
    //  GhostList is the self-listing singleton, not dismissable.
    const dismiss = (r: Row) => {
        if (r.waft && r.kind !== 'GhostList') H.i_elvisto('Lies/Lies', 'Lies_close_Waft', { path: r.waft })
        open_key = undefined; confirming = false
    }
</script>

<!-- A surprise_read on any open Doc pops out of the channel as a fixed popover,
     above the strip itself.  Rendered unconditionally — it has its own gate. -->
<SurprisePopover {H} />

{#snippet cap(r: Row)}
    <div class="isx-cap"
         data-waft={r.waft ?? ''}
         class:isx-active={r.active}
         class:isx-pending={r.state === 'pending'}
         class:isx-ghostlist={r.kind === 'GhostList'}
         class:isx-aside={r.kind === 'Aside'}
         class:isx-open={open_key === r.key && r.active}>
        <button class="isx-btn"
                title={`${r.kind}${r.waft ? ' · ' + r.waft : ''} — ${r.state}${r.active ? ' (foreground — tap to inspect)' : ''}`}
                onclick={() => tap(r)}>{r.label}</button>
    </div>
{/snippet}

{#if hot.length || cold.length}
<div class="isx">
    {#each hot as r (r.key)}{@render cap(r)}{/each}
    {#if cold.length}
        <!-- the quiet ones: loaded-but-unengaged givers, the GhostList index.  Collapsed
             until clicked — they're reachable, just not claiming a foreground slot. -->
        <button class="isx-more" class:isx-more-open={show_cold}
                title={show_cold ? 'hide the quiet Interests' : `${cold.length} quiet Interest${cold.length > 1 ? 's' : ''} (loaded, not engaged)`}
                onclick={toggle_show_cold}>{show_cold ? '− less' : `+${cold.length} more`}</button>
        {#if show_cold}
            {#each cold as r (r.key)}{@render cap(r)}{/each}
        {/if}
    {/if}
</div>

{#if open_row}
    {@const or = open_row}
    <!-- the Interest inspector — the open|edit step beyond foregrounding.  Shows the
         Interest (the grapple), not its Waft content.  Grows toward the channel nature
         (tell|be-told) noted at the foot. -->
    <div class="isx-panel">
        <div class="isx-panel-hd">
            <span class="isx-panel-kind">{or.kind}</span>
            {#if or.waft}
                <!-- hyperlink to the Waft: re-foreground / re-land the cursor on it -->
                <button class="isx-panel-waft" title="go to this Waft" onclick={() => foreground(or)}>↗ {or.waft}</button>
            {/if}
        </div>
        <div class="isx-panel-facts">
            {#if or.face}<span>face <b>{or.face}</b></span>{/if}
            {#if or.presence}<span>presence <b>{or.presence}</b></span>{/if}
            <span>state <b>{or.state}</b></span>
            {#if or.from}<span class="isx-panel-posture" title="the anchor this flew off">off <b>{or.from}</b></span>{/if}
            {#if or.in_doc}<span title="the doc its cursor is on">in <b>{or.in_doc}</b></span>{/if}
        </div>
        <div class="isx-panel-actions">
            {#if or.kind !== 'GhostList' && or.waft}
                {#if !confirming}
                    <button class="isx-panel-dismiss" onclick={() => confirming = true}>dismiss…</button>
                {:else}
                    <span class="isx-panel-q">drop this Waft from the desk?</span>
                    <button class="isx-panel-yes" onclick={() => dismiss(or)}>yes, drop</button>
                    <button class="isx-panel-no"  onclick={() => confirming = false}>keep</button>
                {/if}
            {/if}
        </div>
        <div class="isx-panel-note">an Interest is a channel — what it can tell · be-told lands here</div>
    </div>
{/if}
{/if}

<style>
    .isx {
        display:       flex;
        flex-wrap:     wrap;
        gap:           4px;
        align-items:   center;
        padding:       4px 6px;
        background:    rgba(24, 20, 32, 0.85);
        border-bottom: 1px solid rgba(196, 170, 238, 0.14);
        flex-shrink:   0;
    }
    .isx-cap {
        display:       flex;
        align-items:   center;
        gap:           2px;
        background:    rgba(196, 170, 238, 0.06);
        border:        1px solid rgba(196, 170, 238, 0.22);
        border-radius: 3px;
        padding:       2px 3px 2px 4px;
        line-height:   1;
    }
    /* the foreground Interest — its face holds the primary stage */
    .isx-active {
        background:   rgba(196, 170, 238, 0.18);
        border-color: rgba(196, 170, 238, 0.7);
        box-shadow:   0 0 6px rgba(196, 170, 238, 0.35);
    }
    /* inspector open on this cap — a notch brighter, reads as "drilled in" */
    .isx-open {
        border-color: rgba(196, 170, 238, 0.9);
        box-shadow:   0 0 8px rgba(196, 170, 238, 0.5);
    }
    /* noticed but not yet locked (no LE armed) */
    .isx-pending  { opacity: 0.6; }
    .isx-ghostlist { background: rgba(120, 170, 140, 0.06); border-color: rgba(120, 170, 140, 0.28); }
    /* Aside — the daily scratch dump; a warm amber tint, kin to but distinct from a Trail */
    .isx-aside     { background: rgba(214, 178, 110, 0.08); border-color: rgba(214, 178, 110, 0.30); }
    .isx-aside .isx-btn { color: #d9b877; }
    .isx-btn {
        background:    none;
        border:        none;
        cursor:        pointer;
        color:         #c4aaee;
        font-family:   inherit;
        font-size:     10px;
        line-height:   1.3;
        padding:       0 1px;
        max-width:     120px;
        overflow:      hidden;
        text-overflow: ellipsis;
        white-space:   nowrap;
    }
    .isx-btn:hover            { color: #fff; }
    .isx-active .isx-btn      { color: #e7dcff; font-weight: 600; }
    .isx-ghostlist .isx-btn   { color: #8fc7a6; }
    /* "+N more" — the collapsed quiet Interests; muted dashed pill, lights on open */
    .isx-more {
        background:    none;
        border:        1px dashed rgba(150, 160, 180, 0.28);
        border-radius: 3px;
        cursor:        pointer;
        color:         #6a6f80;
        font-family:   inherit;
        font-size:     9px;
        line-height:   1;
        padding:       2px 5px;
    }
    .isx-more:hover     { color: #aab; border-color: rgba(170, 185, 215, 0.55); }
    .isx-more-open      { color: #99a; border-style: solid; }

    /* ── the Interest inspector — opens below the strip for the foregrounded cap ── */
    .isx-panel {
        display:       flex;
        flex-direction: column;
        gap:           3px;
        padding:       5px 8px 6px;
        background:    rgba(18, 15, 26, 0.95);
        border-bottom: 1px solid rgba(196, 170, 238, 0.18);
        font-family:   inherit;
        font-size:     10px;
        color:         #b6a8cc;
    }
    .isx-panel-hd { display: flex; align-items: baseline; gap: 8px; }
    .isx-panel-kind {
        color: #e7dcff; font-weight: 600; letter-spacing: 0.04em;
    }
    /* the hyperlink to the Waft — the Interest's subject */
    .isx-panel-waft {
        background: none; border: none; padding: 0; cursor: pointer;
        color: #9ab8e8; font-family: inherit; font-size: 10px;
        overflow: hidden; text-overflow: ellipsis; white-space: nowrap; max-width: 22ch;
    }
    .isx-panel-waft:hover { color: #cfe2ff; text-decoration: underline; }
    .isx-panel-facts { display: flex; flex-wrap: wrap; gap: 2px 10px; color: #7e7494; }
    .isx-panel-facts b { color: #b6a8cc; font-weight: 600; }
    .isx-panel-posture b { color: #d9b877; }   /* the off-anchor reads amber, like an Aside */
    .isx-panel-actions { display: flex; align-items: center; gap: 6px; min-height: 1.1em; }
    .isx-panel-dismiss {
        background: none; border: 1px solid rgba(224, 108, 117, 0.3); border-radius: 3px;
        cursor: pointer; color: #a06a72; font-family: inherit; font-size: 9px; padding: 1px 6px;
    }
    .isx-panel-dismiss:hover { color: #e06c75; border-color: rgba(224, 108, 117, 0.6); }
    .isx-panel-q   { color: #c98a90; }
    .isx-panel-yes {
        background: rgba(224, 108, 117, 0.16); border: 1px solid rgba(224, 108, 117, 0.5);
        border-radius: 3px; cursor: pointer; color: #e06c75; font-family: inherit; font-size: 9px; padding: 1px 6px;
    }
    .isx-panel-yes:hover { background: rgba(224, 108, 117, 0.3); }
    .isx-panel-no {
        background: none; border: none; cursor: pointer; color: #777; font-family: inherit; font-size: 9px; padding: 1px 4px;
    }
    .isx-panel-no:hover { color: #aaa; }
    .isx-panel-note { color: #5a5470; font-style: italic; font-size: 9px; }
</style>
