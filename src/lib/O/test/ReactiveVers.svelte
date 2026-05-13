<script lang="ts">
    // waft.version is the raw Atime $state signal 
    // < a UItime-buffered C.vers
    //    would require C→H awareness at bump time, which TheC doesn't have.
    // Gated fires once per flush; ungated fires on every Atime waft bump,
    // including between replace()'s internal await points.

    // ReactiveVers

    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"

    let { H }: { H: House } = $props()

    let waft_in_ave = $state<TheC | undefined>()

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

    $effect(() => {
        waft_in_ave = H.ave.ob({ Waft: 1 })[0] as TheC | undefined
        if (!waft_in_ave) return
        const docs = snap(waft_in_ave)
        if (docs === prev_gated) return
        prev_gated = docs
        const n = ++gated_n
        setTimeout(() => li()?.('UI', { src: 'gated', docs, n }), 1)
    })

    $effect(() => {
        if (!waft_in_ave) return
        void waft_in_ave.version
        const docs = snap(waft_in_ave)
        if (docs === prev_ungated) return
        prev_ungated = docs
        const n = ++ungated_n
        setTimeout(() => li()?.('UI', { src: '---->', docs, n }), 1)
    })
</script>

<div class="rv">
    <div class="rv-counts">
        <span class="g">G {gated_n}</span>
        <span class="sep">/</span>
        <span class="u">u {ungated_n}</span>
        {#if ungated_n > gated_n}
            <span class="rv-extra">+{ungated_n - gated_n} mid-cycle</span>
        {/if}
    </div>
    <div class="rv-docs">
        {#if waft_in_ave}
            {#each waft_in_ave.o({ Doc: 1 }) as TheC[] as doc ((doc as TheC).sc.path)}
                <span class="rv-doc" class:active={(doc as TheC).sc.active}>
                    {(doc as TheC).sc.path}
                </span>
            {:else}
                <span class="rv-dim">∅</span>
            {/each}
        {:else}
            <span class="rv-dim">waiting…</span>
        {/if}
    </div>
</div>

<style>
.rv        { font-family: monospace; font-size: .8rem; padding: .4rem .5rem;
             background: #0e0e18; border: 1px solid #2a2a3a; border-radius: 4px }
.rv-counts { display: flex; gap: .35rem; align-items: baseline; margin-bottom: .25rem; font-size: .74rem }
.g         { color: #88c }
.u         { color: #8a8 }
.sep       { color: #333 }
.rv-extra  { color: #c84; font-size: .7rem }
.rv-docs   { display: flex; gap: .25rem; flex-wrap: wrap; min-height: 1.2rem }
.rv-doc    { padding: .04rem .22rem; background: #1a1a2a; border-radius: 2px; color: #99b; font-size: .75rem }
.rv-doc.active { background: #142014; color: #8c8 }
.rv-dim    { color: #333; font-style: italic; font-size: .75rem }
</style>
