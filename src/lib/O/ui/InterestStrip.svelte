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
    //   Trail); light kinds (GhostList) are a pure lens swap.  %ActiveInterest drives
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
        key:         string
    }

    let languinio: TheC | undefined = $state()
    $effect(() => { languinio = H.ave.ob({ Languinio: 1 })[0] as TheC | undefined })

    let active = $derived.by(() => {
        void languinio?.vers
        const ai = languinio?.ob({ ActiveInterest: 1 })[0] as TheC | undefined
        return { kind: ai?.sc.kind as string | undefined, waft: ai?.sc.waft as string | undefined }
    })

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
                        : (waft?.split('/').pop() ?? 'trail')
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
                key:    `${kind}:${waft ?? ''}`,
            })
        }
        return out
    })

    // Engaged caps always show; the rest tuck behind a "+N more" toggle so a passive
    //  Credence Trail or the GhostList index doesn't claim the foreground switcher.
    let hot  = $derived(rows.filter(r => r.interesting))
    let cold = $derived(rows.filter(r => !r.interesting))
    let show_cold = $state(false)

    const foreground = (r: Row) =>
        H.i_elvisto('Lang/Lang', 'Lang_foreground', { kind: r.kind, ...(r.waft ? { waft: r.waft } : {}) })

    // Dismiss acts Lies-side — drop Lies/Waft (Waft_spec); the roster re-push then marks
    //  the Interest gone.  GhostList is the self-listing singleton — not dismissable here.
    const dismiss = (r: Row) => { if (r.waft && r.kind !== 'GhostList') H.i_elvisto('Lies/Lies', 'Lies_close_Waft', { path: r.waft }) }

    // ↳ Sprout a Sidetrack off the foreground Trail (the reverse arrow, Waft_spec).  One
    //  gesture: Lang sprouts the pending Sidetrack, Lies opens its tentative Waft, the
    //   roster re-push binds them by %from.  Only meaningful while a Trail is foreground.
    const sprout = () => {
        const from = active.waft
        if (active.kind !== 'Trail' || !from) return
        H.i_elvisto('Lang/Lang', 'Lang_sprout_sidetrack', { from })
        H.i_elvisto('Lies/Lies', 'Lies_open_sidetrack',   { from })
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
         class:isx-ghostlist={r.kind === 'GhostList'}>
        <button class="isx-btn"
                title={`${r.kind}${r.waft ? ' · ' + r.waft : ''} — ${r.state}${r.active ? ' (foreground)' : ''}`}
                onclick={() => foreground(r)}>{r.label}</button>
        {#if r.waft && r.kind !== 'GhostList'}
            <button class="isx-x" title="Dismiss this Interest" onclick={() => dismiss(r)}>×</button>
        {/if}
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
                onclick={() => show_cold = !show_cold}>{show_cold ? '− less' : `+${cold.length} more`}</button>
        {#if show_cold}
            {#each cold as r (r.key)}{@render cap(r)}{/each}
        {/if}
    {/if}
    {#if active.kind === 'Trail' && active.waft}
        <button class="isx-sprout" title="Sprout a Sidetrack off this Trail" onclick={sprout}>↳</button>
    {/if}
</div>
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
    /* the foreground Interest — its lens holds the primary stage */
    .isx-active {
        background:   rgba(196, 170, 238, 0.18);
        border-color: rgba(196, 170, 238, 0.7);
        box-shadow:   0 0 6px rgba(196, 170, 238, 0.35);
    }
    /* noticed but not yet locked (no LE armed) */
    .isx-pending  { opacity: 0.6; }
    .isx-ghostlist { background: rgba(120, 170, 140, 0.06); border-color: rgba(120, 170, 140, 0.28); }
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
    .isx-x {
        background:  none;
        border:      none;
        cursor:      pointer;
        color:       #5a4a6a;
        font-family: inherit;
        font-size:   10px;
        line-height: 1;
        padding:     0 1px;
    }
    .isx-x:hover { color: #e06c75; }
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
    /* ↳ sprout a Sidetrack off the foreground Trail */
    .isx-sprout {
        background:    none;
        border:        1px dashed rgba(196, 170, 238, 0.3);
        border-radius: 3px;
        cursor:        pointer;
        color:         #8a7aa6;
        font-family:   inherit;
        font-size:     11px;
        line-height:   1;
        padding:       2px 5px;
        margin-left:   2px;
    }
    .isx-sprout:hover { color: #c4aaee; border-color: rgba(196, 170, 238, 0.6); }
</style>
