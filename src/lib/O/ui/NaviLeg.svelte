<script lang="ts">
    // NaviLeg.svelte — the workup's face: the pool, the presented leg, and the
    // two soft commits lingering in the clearing.
    //
    //   Mounted by NaviCado below the tools row.  Pure renderer of %LE/%workup
    //   and the req:git spool — holds no model of its own.
    //
    // ── Particle sources ──────────────────────────────────────────────────────
    //   H.ave/%Languinio/%LE        — /%workup/%Seemed,$at + /%leg
    //   H.ave/%git_hold (c.git)     — same-object hold on w:Lies' req:git,
    //                                 installed by e_workup_filed
    //
    // ── Three densities of permanence, top to bottom ─────────────────────────
    //   pooling   — ≈N quietly counting; the entrails of the tour so far
    //   leg       — presented batch: "rides your next move"; per-row ↩ discard,
    //               whole-leg ✕, · dismiss (keep pooling), ↑ commit now.
    //               Rows expand to the raw ± diff — the slot the coherently
    //               folded patch renderer will take over.
    //   soft      — the last two %Waftlet receipts, mute: label · age · ↩ ⋈.
    //               Just enough to realise the real memory moved and intervene.

    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"

    let { H }: { H: House } = $props()

    // ── derivation ────────────────────────────────────────────────────────────

    let languinio = $derived(H.ave.ob({ Languinio: 1 })[0] as TheC | undefined)
    let LE        = $derived(languinio?.ob({ LE: 1 })[0] as TheC | undefined)

    let workup = $derived.by(() => {
        void LE?.vers
        return LE?.o({ workup: 1 })[0] as TheC | undefined
    })
    let leg = $derived.by(() => {
        void LE?.vers
        return workup?.o({ leg: 1 })[0] as TheC | undefined
    })
    let seemeds = $derived.by(() => {
        void LE?.vers
        return (workup?.o({ Seemed: 1 }) ?? []) as TheC[]
    })

    let git = $derived.by(() => {
        const hold = H.ave.ob({ git_hold: 1 })[0] as TheC | undefined
        return hold?.c.git as TheC | undefined
    })
    let softs = $derived.by(() => {
        void git?.vers
        return ((git?.o({ Waftlet: 1 }) ?? []) as TheC[])
            .filter(x => x.sc.soft && !x.sc.reverted)
            .sort((a, b) => (b.sc.t as number) - (a.sc.t as number))
            .slice(0, 2)
    })

    // expanded raw-diff bodies, by address
    let expanded: Set<string> = $state(new Set())
    function toggle_expand(at: string) {
        const x = new Set(expanded)
        if (x.has(at)) x.delete(at)
        else           x.add(at)
        expanded = x
    }

    function rawdiff(s: TheC): string {
        const enc = s.o({ encode: 1 })[0] as TheC | undefined
        return (H as any).Workup_rawdiff(
            (enc?.sc.snap_origin  as string) ?? '',
            (enc?.sc.snap_working as string) ?? '')
    }

    function ago(t: number | undefined): string {
        if (!t) return ''
        const d = Date.now() / 1000 - t
        if (d < 90)   return `${Math.round(d)}s`
        if (d < 5400) return `${Math.round(d / 60)}m`
        return `${Math.round(d / 3600)}h`
    }

    const wk = (op: string, extra?: Record<string, unknown>) =>
        H.i_elvisto('Lang/Lang', 'workup', { LE, op, ...extra })
    const wl = (op: string, extra?: Record<string, unknown>) =>
        H.i_elvisto('Lies/Lies', 'waftlet', { op, ...extra })
</script>

{#if seemeds.length || softs.length}
<div class="nvl">

    {#if leg && seemeds.length}
        <!-- the presented leg: this batch rides the next move -->
        <div class="nvl-leg">
            <div class="nvl-leg-head">
                <span class="nvl-leg-mark">≈</span>
                <span class="nvl-leg-say">{seemeds.length} change{seemeds.length === 1 ? '' : 's'} ride your next move</span>
                <button class="nvl-op" title="Commit now" onclick={() => wk('commit')}>↑</button>
                <button class="nvl-op" title="Keep pooling — dismiss the presentation" onclick={() => wk('dismiss_leg')}>·</button>
                <button class="nvl-op nvl-op-red" title="Discard everything pooled" onclick={() => wk('discard_leg')}>✕</button>
            </div>
            {#each seemeds as s (s.sc.at)}
                <div class="nvl-row" class:nvl-row-live={s.sc.live}>
                    <button class="nvl-row-what" title="{s.sc.at} — toggle raw diff"
                            onclick={() => toggle_expand(s.sc.at as string)}>
                        {s.sc.what}
                    </button>
                    <span class="nvl-row-when">{ago(s.sc.t as number)}</span>
                    <button class="nvl-op" title="Discard this change" onclick={() => wk('discard_seemed', { at: s.sc.at })}>↩</button>
                </div>
                {#if expanded.has(s.sc.at as string)}
                    <pre class="nvl-raw">{rawdiff(s)}</pre>
                {/if}
            {/each}
        </div>
    {:else if seemeds.length}
        <!-- pooling quietly until the slope presents it -->
        <div class="nvl-pool" title="Changes pooling in the workup — surface up the What slope to present them">
            ≈{seemeds.length} pooling
        </div>
    {/if}

    {#if softs.length}
        <!-- the clearing: the last legs landed, still grabbable -->
        <div class="nvl-clearing">
            {#each softs as W (W.sc.Waftlet)}
                <div class="nvl-soft" title="{W.sc.label} — landed in the Waft; ↩ puts it back as it was">
                    <span class="nvl-soft-label">{W.sc.label}</span>
                    <span class="nvl-soft-when">{ago(W.sc.t as number)}</span>
                    <button class="nvl-op" title="Revert this commit" onclick={() => wl('revert', { id: W.sc.Waftlet })}>↩</button>
                </div>
            {/each}
            {#if softs.length === 2}
                <button class="nvl-op" title="Merge the two — keep going on the same topics" onclick={() => wl('merge')}>⋈</button>
            {/if}
        </div>
    {/if}

</div>
{/if}

<style>
    .nvl {
        display:        flex;
        flex-direction: column;
        gap:            2px;
        background:     rgba(14, 18, 25, 0.92);
        border-bottom:  1px solid rgba(255,255,255,0.04);
        font-size:      10px;
        padding:        2px 4px;
    }

    /* shared op buttons — same weight as NaviCado's tool row */
    .nvl-op {
        background:    transparent;
        border:        1px solid rgba(255,255,255,0.1);
        border-radius: 3px;
        color:         #6a7d8e;
        cursor:        pointer;
        font-family:   inherit;
        font-size:     10px;
        line-height:   1;
        padding:       1px 4px;
        transition:    color 0.1s, border-color 0.1s;
    }
    .nvl-op:hover     { color: #c0d0e0; border-color: rgba(255,255,255,0.28); }
    .nvl-op-red:hover { color: #e06c75; border-color: rgba(224,108,117,0.4); }

    /* pooling — the quiet counter */
    .nvl-pool {
        color:          rgba(229, 192, 123, 0.35);
        letter-spacing: 0.04em;
        padding:        1px 2px;
    }

    /* the presented leg */
    .nvl-leg {
        border:        1px solid rgba(229, 192, 123, 0.22);
        border-radius: 3px;
        padding:       3px 4px;
        background:    rgba(229, 192, 123, 0.04);
    }
    .nvl-leg-head {
        display:     flex;
        align-items: center;
        gap:         4px;
    }
    .nvl-leg-mark { color: #e5c07b; }
    .nvl-leg-say  { flex: 1; color: rgba(229, 192, 123, 0.7); }

    .nvl-row {
        display:     flex;
        align-items: center;
        gap:         4px;
        padding:     1px 0 1px 10px;
    }
    .nvl-row-live .nvl-row-what { color: #e5c07b; }
    .nvl-row-what {
        background:  none;
        border:      none;
        cursor:      pointer;
        color:       #9aa5b4;
        font-family: inherit;
        font-size:   10px;
        padding:     0;
        flex:        1;
        text-align:  left;
    }
    .nvl-row-what:hover { color: #fff; }
    .nvl-row-when { color: rgba(106, 125, 142, 0.5); }

    /* raw diff body — the slot the folded patch renderer takes over */
    .nvl-raw {
        margin:        1px 0 3px 14px;
        padding:       3px 5px;
        background:    rgba(0, 0, 0, 0.35);
        border-left:   2px solid rgba(229, 192, 123, 0.18);
        color:         #8a98a8;
        font-size:     9px;
        line-height:   1.4;
        white-space:   pre-wrap;
        word-break:    break-all;
    }

    /* the clearing — soft commits, mute */
    .nvl-clearing {
        display:     flex;
        align-items: center;
        gap:         5px;
        flex-wrap:   wrap;
        opacity:     0.8;
    }
    .nvl-soft {
        display:       flex;
        align-items:   center;
        gap:           4px;
        border:        1px dashed rgba(122, 176, 192, 0.25);
        border-radius: 3px;
        padding:       1px 4px;
        background:    rgba(122, 176, 192, 0.04);
    }
    .nvl-soft-label {
        color:         #7ab0c0;
        max-width:     160px;
        overflow:      hidden;
        text-overflow: ellipsis;
        white-space:   nowrap;
    }
    .nvl-soft-when { color: rgba(122, 176, 192, 0.45); }
</style>
