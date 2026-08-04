<script lang="ts">
    import { lifewatch } from './micro/lifetell'   // DIAGNOSTIC — strip with the rest of the remount probes
    // TransferFace — the LIVE transfer HUD (the human 2026-07-30 "I keep wanting more transfer visual feedback
    //  but I don't see any").  Mounted by Cytui on a %Transfer particle (imposed by mainkey, glass_faces.ts —
    //   no snap byte).  Reads the shared top_House().c.xfer that the wire feeds (Repli_meter rates + rolling rx
    //    spark, Ra_pull_beat active pulls, Repli_serve_chunks serves, Heist_release_rec freed).  Polls on its OWN
    //     fast timer (the wire writes .c with NO version bump — a bump per packet would re-tessellate the glass),
    //      so the bars JIGGLE with real packet arrival and ease to rest when the wire goes quiet.
    //  Pointer-events:none root (no buttons) so the glass stays pannable.
    let { n, H } = $props()

    // DIAGNOSTIC (2026-08-04, the KeepFace remount hunt — strip with the rest of the probes): a
    //  CONTROL rung on the life ladder.  This face sits in the same glass, under the same stage and
    //   the same cell {#each}, and is mounted throughout a download — so if Keep's serial climbs
    //    while THIS one stays flat, the teardown is Keep-row-specific (its key/gate/source), not
    //     structural; if both climb together, the whole faces layer is being rebuilt.
    lifewatch(H, 'face:Transfer', () => 'xfer')

    let tick = $state(0)
    $effect(() => {
        const iv = setInterval(() => { tick++ }, 250)
        return () => clearInterval(iv)
    })

    const now = () => (globalThis.performance ? performance.now() : 0)  // display-only clock, never state

    let view = $derived.by(() => {
        void tick
        void H?.version
        const x = (H?.top_House?.()?.c as any)?.xfer
        if (!x) return { active: false, rx: 0, tx: 0, spark: [] as number[], pulls: [] as any[], serves: [] as any[], freed: [] as any[] }
        const age = Date.now() - (x.ts || 0)
        const idle = age > 2500
        const pulls = Object.values(x.pulls ?? {}).sort((a: any, b: any) => (b.ts || 0) - (a.ts || 0)).slice(0, 4)
        const serves = Object.values(x.serves ?? {}).sort((a: any, b: any) => (b.ts || 0) - (a.ts || 0)).slice(0, 4)
        const dropRecent = (Date.now() - (x.drop_ts || 0)) < 4000
        const breachRecent = (Date.now() - (x.breach_ts || 0)) < 4000
        return {
            active: !idle && (x.rx_kbps > 0 || x.tx_kbps > 0 || pulls.length > 0 || serves.length > 0),
            rx: idle ? 0 : +(x.rx_kbps ?? 0),
            tx: idle ? 0 : +(x.tx_kbps ?? 0),
            spark: (x.spark ?? []).slice(-32) as number[],
            pulls, serves,
            freed: (x.freed ?? []).slice(0, 3) as any[],
            drops: +(x.drops ?? 0),
            dropRecent,
            lastDrop: String(x.last_drop ?? ''),
            breaches: +(x.breaches ?? 0),
            breachRecent,
            lastBreach: String(x.last_breach ?? ''),
        }
    })

    // bar height %: log-ish scale so a trickle still shows and a full ~3MB/s pull pins near the top.
    const barPct = (kbps: number) => Math.max(0, Math.min(100, Math.round(Math.log2(1 + Math.max(0, kbps)) * 11)))
    const pct = (held: number, total: number) => total > 0 ? Math.round(held * 100 / total) : 0
    const sparkPath = (s: number[]) => {
        if (!s.length) return ''
        const max = Math.max(1, ...s)
        const w = 100 / Math.max(1, s.length - 1)
        return s.map((v, i) => `${i === 0 ? 'M' : 'L'}${(i * w).toFixed(1)},${(18 - (v / max) * 16).toFixed(1)}`).join(' ')
    }
</script>

<div class="tf" class:live={view.active}>
    <div class="tf-head">
        <span class="tf-dot" class:on={view.active}></span>
        <span class="tf-title">transfer</span>
        <span class="tf-rate">{view.rx}<span class="tf-u">↓</span> · {view.tx}<span class="tf-u">↑</span> KB/s</span>
    </div>

    <div class="tf-meters">
        <div class="tf-bar-wrap" title="download rate">
            <div class="tf-bar tf-rx" style="height:{barPct(view.rx)}%"></div>
        </div>
        <div class="tf-bar-wrap" title="upload rate">
            <div class="tf-bar tf-tx" style="height:{barPct(view.tx)}%"></div>
        </div>
        <svg class="tf-spark" viewBox="0 0 100 18" preserveAspectRatio="none">
            <path d={sparkPath(view.spark)} />
        </svg>
    </div>

    {#if view.pulls.length}
        <div class="tf-sec">
            {#each view.pulls as p}
                <div class="tf-row" class:done={p.done}>
                    <span class="tf-glyph">⇊</span>
                    <span class="tf-name">{p.title}</span>
                    <span class="tf-n">{p.held}/{p.total}</span>
                    <div class="tf-track"><div class="tf-fill tf-fill-rx" style="width:{pct(p.held, p.total)}%"></div></div>
                </div>
            {/each}
        </div>
    {/if}

    {#if view.serves.length}
        <div class="tf-sec">
            {#each view.serves as s}
                <div class="tf-row">
                    <span class="tf-glyph tf-up">⇈</span>
                    <span class="tf-name">{s.title}</span>
                    <span class="tf-n">{s.n}/{s.total} →{s.to}</span>
                    <div class="tf-track"><div class="tf-fill tf-fill-tx" style="width:{pct(s.n, s.total)}%"></div></div>
                </div>
            {/each}
        </div>
    {/if}

    {#if view.drops > 0}
        <div class="tf-drops" class:hot={view.dropRecent}>⚠ {view.drops} frame{view.drops === 1 ? '' : 's'} dropped{view.lastDrop ? ` · ${view.lastDrop}` : ''}{view.dropRecent ? ' — the next piece is being lost on a torn socket' : ''}</div>
    {/if}

    {#if view.breaches > 0}
        <div class="tf-drops" class:hot={view.breachRecent}>✗ {view.breaches} landing breach{view.breaches === 1 ? '' : 'es'}{view.lastBreach ? ` · ${view.lastBreach}` : ''}{view.breachRecent ? ' — bytes on disk failed the hash check, retrying' : ''}</div>
    {/if}

    {#if view.freed.length}
        <div class="tf-freed">
            {#each view.freed as f}<span class="tf-freed-item">↯ {f.title}</span>{/each}
        </div>
    {/if}

    {#if !view.active && !view.pulls.length && !view.serves.length}
        <div class="tf-idle">idle · no transfer</div>
    {/if}
</div>

<style>
    .tf {
        pointer-events: none;
        width: max-content;
        min-width: 200px;
        max-width: 320px;
        padding: 8px 11px;
        font-family: ui-rounded, 'Trebuchet MS', sans-serif;
        color: #cfe6dc;
        background: #0e1c22;
        border: 1px solid #1e3a44;
        border-radius: 9px;
        text-align: left;
    }
    .tf.live { border-color: #2f7d5b; }
    .tf-head { display: flex; align-items: baseline; gap: 6px; margin-bottom: 6px; }
    .tf-dot { width: 7px; height: 7px; border-radius: 50%; background: #33505c; align-self: center; flex: none; }
    .tf-dot.on { background: #57c777; box-shadow: 0 0 6px #57c777; }
    .tf-title { font-size: 11px; font-weight: 700; letter-spacing: 0.04em; opacity: 0.85; }
    .tf-rate { font-size: 11px; font-weight: 700; margin-left: auto; color: #eafff0; }
    .tf-u { font-size: 8px; opacity: 0.6; }
    .tf-meters { display: flex; align-items: flex-end; gap: 4px; height: 20px; margin-bottom: 4px; }
    .tf-bar-wrap { width: 8px; height: 20px; background: #0a1418; border-radius: 2px; display: flex; align-items: flex-end; overflow: hidden; flex: none; }
    .tf-bar { width: 100%; border-radius: 2px 2px 0 0; transition: height 0.22s ease-out; }
    .tf-rx { background: #57c777; }
    .tf-tx { background: #5aa9e6; }
    .tf-spark { flex: 1; height: 20px; }
    .tf-spark path { fill: none; stroke: #57c777; stroke-width: 1; opacity: 0.7; vector-effect: non-scaling-stroke; }
    .tf-sec { display: flex; flex-direction: column; gap: 3px; margin-top: 4px; }
    .tf-row { display: grid; grid-template-columns: auto 1fr auto; grid-template-areas: 'g name n' 'g track track'; gap: 1px 5px; align-items: baseline; font-size: 10px; }
    .tf-glyph { grid-area: g; align-self: center; color: #57c777; font-size: 11px; }
    .tf-glyph.tf-up { color: #5aa9e6; }
    .tf-name { grid-area: name; overflow-wrap: anywhere; font-weight: 600; }
    .tf-n { grid-area: n; opacity: 0.7; white-space: nowrap; font-variant-numeric: tabular-nums; }
    .tf-track { grid-area: track; height: 3px; background: #0a1418; border-radius: 2px; overflow: hidden; margin-top: 1px; }
    .tf-fill { height: 100%; transition: width 0.3s linear; }
    .tf-fill-rx { background: #57c777; }
    .tf-fill-tx { background: #5aa9e6; }
    .tf-row.done .tf-fill { background: #7fd89a; }
    .tf-drops { margin-top: 5px; font-size: 9px; font-weight: 600; color: #c98a3a; opacity: 0.7; }
    .tf-drops.hot { color: #e06a5a; opacity: 1; }
    .tf-freed { margin-top: 5px; display: flex; flex-wrap: wrap; gap: 4px; }
    .tf-freed-item { font-size: 8px; opacity: 0.55; }
    .tf-idle { font-size: 9px; opacity: 0.4; margin-top: 3px; }
</style>
