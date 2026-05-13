<script lang="ts">
    // ReactiveWaft.svelte
    //
    // Two subscriptions to the same waft TheC:
    //
    //   gated   — H.ave.ob({Waft:1}): H.ave.version only bumps after flush/clear(),
    //             once the beliefs cycle is fully done.
    //
    //   ungated — void waft_in_ave?.version: the raw $state signal on waft.X.serial_i.
    //             Fires at every waft.i/r/bump_version call, including between
    //             replace()'s internal await points.
    //
    // Neither $effect writes to a $state variable inside itself.
    // Instead they call H.c.UIlog via setTimeout(1) — breaking Svelte's
    // reactive tracking chain so the w.i() inside UIlog doesn't re-trigger them.
    //
    // Log rows are read from logC.version — a fine-grained subscription that
    // fires only when UIlog writes a new entry, not on every H.ave bump.
    //
    // Snap assertions live in w** (uiLog particles), not in this component.

    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"

    let { H }: { H: House } = $props()

    // ── stable refs from H.ave ────────────────────────────────────────────────
    let waft_in_ave = $state<TheC | undefined>()
    let logC_in_ave = $state<TheC | undefined>()

    // dedup sentinels — plain vars, not $state, so writes don't re-trigger effects
    let prev_gated   = ''
    let prev_ungated = ''
    let gated_n      = 0
    let ungated_n    = 0

    function snap(waft: TheC): string {
        return (waft.o({ Doc: 1 }) as TheC[])
            .map(d => d.sc.path + ((d.sc as any).active ? '●' : ''))
            .join('  ') || '∅'
    }

    // ── gated — subscribes to H.ave.version via ob() ─────────────────────────
    $effect(() => {
        waft_in_ave = H.ave.ob({ Waft: 1 })[0] as TheC | undefined
        logC_in_ave = H.ave.ob({ logC: 1 })[0] as TheC | undefined
        if (!waft_in_ave) return
        const docs = snap(waft_in_ave)
        if (docs === prev_gated) return
        prev_gated = docs
        const n = ++gated_n
        setTimeout(() => (H as any).c?.UIlog?.('gated', { docs, n }), 1)
    })

    // ── ungated — subscribes to waft.version directly ────────────────────────
    // Fires between replace()'s await points — including mid-empty (docs='∅')
    // and mid-fill — showing intermediate states the gated path never sees.
    let ungated_docs = $derived.by(() => {
        void waft_in_ave?.version
        return waft_in_ave ? snap(waft_in_ave) : ''
    })

    $effect(() => {
        const docs = ungated_docs
        if (!docs || docs === prev_ungated) return
        prev_ungated = docs
        const n = ++ungated_n
        setTimeout(() => (H as any).c?.UIlog?.('---->', { docs, n }), 1)
    })

    // ── log rows — fine-grained: only fires when UIlog writes a new entry ─────
    let log_rows = $derived.by(() => {
        void logC_in_ave?.version
        return (logC_in_ave?.o({ uiLog: 1 }) ?? []) as TheC[]
    })
</script>

<div class="rw">
    <div class="rw-title">ReactiveWaft</div>

    <!-- current doc list -->
    <div class="rw-docs">
        {#if waft_in_ave}
            {#each waft_in_ave.o({ Doc: 1 }) as TheC[] as doc ((doc as TheC).sc.path)}
                <span class="rw-doc" class:active={(doc as TheC).sc.active}>
                    {(doc as TheC).sc.path}
                </span>
            {:else}
                <span class="rw-dim">∅</span>
            {/each}
        {:else}
            <span class="rw-dim">waiting…</span>
        {/if}
    </div>

    <!-- counts -->
    <div class="rw-counts">
        <span class="g">G {gated_n}</span>
        <span class="sep">/</span>
        <span class="u">u {ungated_n}</span>
        {#if ungated_n > gated_n}
            <span class="rw-extra">+{ungated_n - gated_n} mid-cycle</span>
        {/if}
    </div>

    <!-- log — written by UIlog into w**, read back via logC.version -->
    <div class="rw-log">
        {#each log_rows as row}
            <div class="rw-row" class:g={(row as TheC).sc.src === 'gated'} class:u={(row as TheC).sc.src === 'ungated'}>
                <span class="rw-src">{(row as TheC).sc.src === 'gated' ? 'G' : 'u'}{(row as TheC).sc.n ?? ''}</span>
                <span class="rw-docs-val">{(row as TheC).sc.docs}</span>
            </div>
        {/each}
    </div>
</div>

<style>
.rw {
    font-family: monospace; font-size: 0.8rem;
    padding: 0.5rem; background: #0e0e18;
    border: 1px solid #2a2a3a; border-radius: 4px; color: #ccc;
}
.rw-title  { font-size: 0.72rem; color: #556; text-transform: uppercase;
             letter-spacing: .05em; margin-bottom: .3rem }
.rw-docs   { display: flex; gap: .3rem; flex-wrap: wrap; min-height: 1.4rem;
             padding: .15rem .2rem; background: #0a0a12; border-radius: 3px;
             margin-bottom: .3rem }
.rw-doc    { padding: .05rem .25rem; background: #1a1a2a; border-radius: 2px; color: #99b }
.rw-doc.active { background: #142014; color: #8c8 }
.rw-dim    { color: #333; font-style: italic }
.rw-counts { display: flex; gap: .4rem; align-items: baseline; margin-bottom: .3rem; font-size: .75rem }
.g         { color: #88c }
.u         { color: #8a8 }
.sep       { color: #333 }
.rw-extra  { color: #c84; font-size: .72rem }
.rw-log    { border-top: 1px solid #1a1a28; padding-top: .2rem;
             max-height: 11rem; overflow-y: auto; display: flex; flex-direction: column; gap: 1px }
.rw-row    { display: flex; gap: .4rem; font-size: .74rem; padding: .04rem 0 }
.rw-row.g  { color: #99b }
.rw-row.u  { color: #6a6 }
.rw-src    { flex-shrink: 0; width: 2.2rem; text-align: right; font-weight: bold }
.rw-docs-val { color: #445 }
.rw-row.g .rw-docs-val { color: #aaa }
</style>
