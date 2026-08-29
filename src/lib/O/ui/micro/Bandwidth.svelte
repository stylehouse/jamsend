<script lang="ts">
    // Bandwidth — a compact, REUSABLE live-activity readout bound to the shared wire meter (top_House().c.xfer,
    //  fed by Repli_meter: rx/tx KB/s + a rolling `spark`).  Born 2026-08-29 for the ferry ceremony (the owner:
    //   "a download progress bar + spinner that responds to REAL activity … we could use this on the splash too")
    //    so no dead zone ever looks frozen while the wire is busy.  TransferFace is the same binding at HUD scale;
    //     this is the inline, single-line sibling a cell can drop into a phase.
    //  (Named Bandwidth, NOT "Wire" — the owner reserves "Wire" for the future project that singularises
    //    reactivity across svelte ↔ Housing.  This is just a meter face.)
    //  Two modes:
    //   · INDETERMINATE (default): a spinner + live "N KB/s" + mini spark.  For a transfer whose TOTAL is unknown
    //      — the ferry account crosses as ONE sealed frame, so we cannot show a %, but we CAN prove it is really
    //       moving and how fast (and flag "congested, not stalled" when pages queue behind the wire).
    //   · DETERMINATE (`frac` 0..1 passed): a filled bar.  For a job with a known fraction — boot census
    //      (261/265 dirs), a paged pull's held/total.
    //  ⚠ Polls on its OWN 250ms macrotask timer, NOT H.version.  The wire writes `.c` with no version bump, and
    //   under a Repli flood version bumps are STARVED (the very reason the ferry cell looked frozen) — a private
    //    tick is immune to that.  SSR-safe (the timer only arms client-side); guarded reads throughout.
    //  NOTE (owner 2026-08-29): the real fix is to stop leaning on `.c` at all — model transfer/ceremony state as
    //   C particles + req so the belief loop reacts natively.  This component is the stopgap face; see the cellular
    //    UI rebuild brief (Focus_todo / CellUI) for the C-foam-not-.c refactor.
    interface Props { H: any; label?: string; frac?: number | null; dir?: 'rx' | 'tx' | 'both'; tint?: string }
    let { H, label = '', frac = null, dir = 'both', tint = '#d98a00' }: Props = $props()

    let tick = $state(0)
    $effect(() => {
        if (typeof window === 'undefined') return
        const iv = setInterval(() => { tick++ }, 250)
        return () => clearInterval(iv)
    })

    let m = $derived.by(() => {
        void tick
        const x = (H?.top_House?.()?.c as any)?.xfer
        if (!x) return { active: false, kbps: 0, moved: 0, spark: [] as number[], queued: 0 }
        const idle = Date.now() - (x.ts || 0) > 2500
        const rx = +(x.rx_kbps ?? 0), tx = +(x.tx_kbps ?? 0)
        const kbps = dir === 'rx' ? rx : dir === 'tx' ? tx : Math.max(rx, tx)
        // bytes moved THIS window (a real, climbing number so "coming over" reads as motion even at a trickle)
        const rxb = +(x.rxb ?? 0), txb = +(x.txb ?? 0)
        const moved = Math.round(((dir === 'rx' ? rxb : dir === 'tx' ? txb : Math.max(rxb, txb)) || 0) / 1024)
        return { active: !idle && kbps > 0, kbps: idle ? 0 : Math.round(kbps), moved, spark: (x.spark ?? []).slice(-24) as number[], queued: +(x.bulk_queued ?? 0) }
    })

    // FLOOR the spark's vertical extent (TransferFace's lesson): a trickle should DRAW a trickle, not a mountain.
    const FLOOR = 200
    const sparkPath = (s: number[]) => {
        if (!s.length) return ''
        const max = Math.max(FLOOR, ...s), w = 100 / Math.max(1, s.length - 1)
        return s.map((v, i) => `${i === 0 ? 'M' : 'L'}${(i * w).toFixed(1)},${(14 - (v / max) * 12).toFixed(1)}`).join(' ')
    }
    let pctf = $derived(frac == null ? null : Math.max(0, Math.min(1, frac)))
</script>

{#if pctf != null}
    <div class="bw" style="--tint:{tint}">
        {#if label}<span class="bw-lbl">{label}</span>{/if}
        <div class="bw-track"><div class="bw-fill" style="width:{(pctf * 100).toFixed(0)}%"></div></div>
        <span class="bw-pct">{Math.round(pctf * 100)}%</span>
    </div>
{:else}
    <div class="bw bw-live" style="--tint:{tint}">
        <span class="bw-spin"></span>
        {#if label}<span class="bw-lbl">{label}</span>{/if}
        <svg class="bw-spark" viewBox="0 0 100 14" preserveAspectRatio="none"><path d={sparkPath(m.spark)} /></svg>
        <span class="bw-rate">{m.kbps > 0 ? m.kbps + ' KB/s' : (m.moved > 0 ? m.moved + ' KB' : '…')}</span>
        {#if m.queued > 0}<span class="bw-q" title="pages queued behind the wire — congested, not stalled">⇥{m.queued}</span>{/if}
    </div>
{/if}

<style>
    .bw { display: flex; align-items: center; gap: .5rem; width: 100%; font-size: .8rem; color: #d8cbb0; }
    .bw-lbl { font-weight: 600; white-space: nowrap; }
    /* DETERMINATE — a filled bar for a known fraction (boot census, paged pull). */
    .bw-track { flex: 1; height: 5px; background: rgba(0, 0, 0, .3); border-radius: 3px; overflow: hidden; }
    .bw-fill { height: 100%; background: var(--tint, #d98a00); transition: width .3s linear; }
    .bw-pct { font-variant-numeric: tabular-nums; opacity: .8; min-width: 2.4em; text-align: right; }
    /* INDETERMINATE — spinner + live spark + rate.  Reuses LinkDevice's ld-spin geometry so the two match. */
    .bw-live { justify-content: center; }
    .bw-spin { width: .8rem; height: .8rem; flex: none; border: 2px solid color-mix(in srgb, var(--tint) 30%, transparent);
               border-top-color: var(--tint, #d98a00); border-radius: 50%; animation: bw-spin 700ms linear infinite; }
    @keyframes bw-spin { to { transform: rotate(360deg); } }
    .bw-spark { flex: 1; max-width: 8rem; height: 14px; }
    .bw-spark path { fill: none; stroke: var(--tint, #d98a00); stroke-width: 1; opacity: .75; vector-effect: non-scaling-stroke; }
    .bw-rate { font-variant-numeric: tabular-nums; font-weight: 600; color: var(--tint, #d98a00); white-space: nowrap; }
    .bw-q { font-size: .72rem; font-weight: 700; color: #e0a24a; white-space: nowrap; }
</style>
