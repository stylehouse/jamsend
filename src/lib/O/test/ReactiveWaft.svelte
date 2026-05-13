<script lang="ts">
    // ReactiveWaft.svelte
    //
    // Gated subscription  — H.ave.ob({Waft:1}): fires once per flush/clear().
    // Ungated subscription — void waft_in_ave?.version: fires on every Atime bump,
    //                        including between replace()'s internal await points.
    //
    // Both call H.c.loggeri('UI', { src, docs, n }) via setTimeout(1).
    // The timeout breaks Svelte's tracking chain — the w.i() inside loggeri
    // doesn't re-trigger the $effect that called it.
    //
    // Log rows are read from void lg?.version — a fine-grained subscription
    // to the logger particle only, not to all of H.ave.

    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"

    let { H }: { H: House } = $props()

    let waft_in_ave = $state<TheC | undefined>()
    let lg_in_ave   = $state<TheC | undefined>()

    let prev_gated   = ''
    let prev_ungated = ''
    let gated_n      = 0
    let ungated_n    = 0

    const li = () => (H as any).c?.loggeri as ((end: string, sc?: Record<string,any>) => void) | undefined

    function snap(waft: TheC): string {
        return (waft.o({ Doc: 1 }) as TheC[])
            .map(d => d.sc.path + ((d.sc as any).active ? '●' : ''))
            .join('  ') || '∅'
    }

    // ── gated ────────────────────────────────────────────────────────────────
    $effect(() => {
        waft_in_ave = H.ave.ob({ Waft:   1 })[0] as TheC | undefined
        lg_in_ave   = H.ave.ob({ logger: 1 })[0] as TheC | undefined
        if (!waft_in_ave) return
        const docs = snap(waft_in_ave)
        if (docs === prev_gated) return
        prev_gated = docs
        const n = ++gated_n
        setTimeout(() => li()?.('UI', { src: 'gated', docs, n }), 1)
    })

    // ── ungated ──────────────────────────────────────────────────────────────
    // Fires between replace()'s await points — a mid-cycle 'UI,ungated' entry
    // appearing before the matching 'Aw,renamed' confirms direct exposure.
    $effect(() => {
        if (!waft_in_ave) return
        void waft_in_ave.version
        const docs = snap(waft_in_ave)
        if (docs === prev_ungated) return
        prev_ungated = docs
        const n = ++ungated_n
        setTimeout(() => li()?.('UI', { src: '---->', docs, n }), 1)
    })

    // ── log rows — fine-grained subscription to logger particle only ─────────
    let log_rows = $derived.by(() => {
        void lg_in_ave?.version
        return (lg_in_ave?.o({}) ?? []) as TheC[]
    })

    // ── current doc list — ungated (most live) ────────────────────────────────
    let docs_now = $derived.by(() => {
        void waft_in_ave?.version
        return waft_in_ave ? snap(waft_in_ave) : ''
    })
</script>

<div class="rw">
    <div class="rw-title">ReactiveWaft</div>

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

    <div class="rw-counts">
        <span class="g">G {gated_n}</span>
        <span class="sep">/</span>
        <span class="u">u {ungated_n}</span>
        {#if ungated_n > gated_n}
            <span class="rw-extra">+{ungated_n - gated_n} mid-cycle</span>
        {/if}
    </div>

    <div class="rw-log">
        {#each log_rows as row}
            {@const r = row as TheC}
            {@const is_ui = r.sc.UI}
            {@const is_gated = r.sc.src === 'gated'}
            <div class="rw-row" class:aw={!is_ui} class:g={is_ui && is_gated} class:u={is_ui && !is_gated}>
                <span class="rw-end">{is_ui ? (is_gated ? 'G' : 'u') : 'A'}</span>
                <span class="rw-body">
                    {#if is_ui}
                        {r.sc.docs}
                    {:else if r.sc.adding}    adding {r.sc.adding}
                    {:else if r.sc.added}     → {r.sc.docs}
                    {:else if r.sc.activating} act {r.sc.activating}
                    {:else if r.sc.activated}  → {r.sc.docs ?? ''}✓
                    {:else if r.sc.renaming}  ren {r.sc.renaming}
                    {:else if r.sc.renamed}   → {r.sc.docs}
                    {:else}{JSON.stringify(r.sc)}{/if}
                </span>
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
.rw-title  { font-size: .7rem; color: #445; text-transform: uppercase;
             letter-spacing: .06em; margin-bottom: .3rem }
.rw-docs   { display: flex; gap: .25rem; flex-wrap: wrap; min-height: 1.4rem;
             padding: .15rem .2rem; background: #0a0a12; border-radius: 3px;
             margin-bottom: .3rem }
.rw-doc    { padding: .05rem .25rem; background: #1a1a2a; border-radius: 2px; color: #99b }
.rw-doc.active { background: #142014; color: #8c8 }
.rw-dim    { color: #333; font-style: italic }
.rw-counts { display: flex; gap: .35rem; align-items: baseline;
             margin-bottom: .3rem; font-size: .74rem }
.g     { color: #88c }
.u     { color: #8a8 }
.sep   { color: #333 }
.rw-extra  { color: #c84; font-size: .7rem }
.rw-log    { border-top: 1px solid #1a1a28; padding-top: .2rem;
             max-height: 14rem; overflow-y: auto;
             display: flex; flex-direction: column; gap: 1px }
.rw-row    { display: flex; gap: .35rem; font-size: .73rem; padding: .03rem 0 }
.rw-end    { flex-shrink: 0; width: 1.2rem; text-align: right; font-weight: bold }
.rw-body   { color: #445 }
.rw-row.g  .rw-end  { color: #88c }
.rw-row.g  .rw-body { color: #aaa }
.rw-row.u  .rw-end  { color: #6a6 }
.rw-row.u  .rw-body { color: #6a6 }
.rw-row.aw .rw-end  { color: #a86 }
.rw-row.aw .rw-body { color: #876 }
</style>
