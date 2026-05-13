<script lang="ts">
    // ReactiveWaft.svelte
    //
    // Subscribes to the same waft TheC two ways and logs each firing.
    //
    //   gated   — reads H.ave.ob({Waft:1}).  H.ave.version only bumps after
    //             flush/clear(), so this fires once per settled beliefs cycle.
    //
    //   ungated — reads void waft.version directly.  waft.X.serial_i is $state;
    //             it bumps whenever Atime calls waft.i/r/replace/bump_version,
    //             including between replace()'s internal await points.
    //
    // The rename_doc tick uses waft.r(), which calls replace() with several
    // awaits.  Between those awaits Svelte can flush its microtask queue and
    // run the ungated $effect — so the log should show intermediate states:
    //   empty   (after replace's empty())
    //   partial (after fn() fills in the new doc, before bo() restores others)
    //   full    (after replace completes, after ave_s.bump_version() gates flush)
    //
    // If gated_n == ungated_n across all three ticks: no mid-cycle exposure.
    // If ungated_n > gated_n: waft.version fired between beliefs cycles —
    //   a C.vers buffer (UItime-only copy of version) would suppress the extras.

    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"

    let { H }: { H: House } = $props()

    type Entry = { source: 'gated' | 'ungated', n: number, paths: string[] }
    const log = $state<Entry[]>([])
    let gated_n   = 0
    let ungated_n = 0

    function snap(waft: TheC): string[] {
        return (waft.o({ Doc: 1 }) as TheC[]).map(d => {
            const p = d.sc.path as string
            return (d.sc as any).active ? p + '●' : p
        })
    }

    // ── gated ────────────────────────────────────────────────────────────────
    // Subscribes to H.ave.version via ob().  Only fires after Housing flush/clear.
    let waft = $state<TheC | undefined>()

    $effect(() => {
        const found = H.ave.ob({ Waft: 1 })[0] as TheC | undefined
        waft = found
        if (!found) return
        // log.push({ source: 'gated', n: ++gated_n, paths: snap(found) })
    })

    // ── ungated ──────────────────────────────────────────────────────────────
    // Subscribes to waft.version — the raw Atime $state signal.
    // Fires independently of the flush whenever waft is mutated in Atime.
    $effect(() => {
        if (!waft) return
        void (waft as TheC).version   // ungated Atime bump subscription
        // log.push({ source: 'ungated', n: ++ungated_n, paths: snap(waft as TheC) })
    })
</script>

<div class="rw">
    <div class="rw-title">ReactiveWaft</div>

    <!-- counts — the key readout -->
    <div class="rw-counts">
        <span class="g">gated {gated_n}</span>
        <span class="sep">/</span>
        <span class="u">ungated {ungated_n}</span>
        {#if ungated_n > gated_n}
            <span class="rw-note">← {ungated_n - gated_n} mid-cycle fire{ungated_n - gated_n > 1 ? 's' : ''}</span>
        {/if}
    </div>

    <!-- current doc list from ungated (most up-to-date) -->
    <div class="rw-docs">
        {#if waft}
            {#each (waft as TheC).o({ Doc: 1 }) as TheC[] as doc ((doc as TheC).sc.path)}
                <span class="rw-doc" class:active={(doc as TheC).sc.active}>{(doc as TheC).sc.path}</span>
            {:else}
                <span class="rw-dim">(no docs)</span>
            {/each}
        {:else}
            <span class="rw-dim">waiting for waft…</span>
        {/if}
    </div>

    <!-- log — interleaved gated/ungated entries show firing order -->
    <div class="rw-log">
        {#each log as e}
            <div class="rw-row" class:g={e.source === 'gated'} class:u={e.source === 'ungated'}>
                <span class="rw-src">{e.source === 'gated' ? 'G' : 'u'}{e.n}</span>
                <span class="rw-paths">{e.paths.join('  ') || '∅'}</span>
            </div>
        {/each}
    </div>
</div>

<style>
.rw {
    font-family: monospace; font-size: 0.8rem;
    padding: 0.5rem; background: #0e0e18;
    border: 1px solid #2a2a3a; border-radius: 4px;
    color: #ccc; min-width: 260px;
}
.rw-title  { font-weight: bold; color: #778; margin-bottom: 0.3rem; font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.05em }
.rw-counts { display: flex; gap: 0.4rem; align-items: baseline; margin-bottom: 0.35rem }
.g  { color: #88c }
.u  { color: #8a8 }
.sep { color: #444 }
.rw-note { color: #c84; font-size: 0.75rem; margin-left: 0.2rem }
.rw-docs {
    display: flex; gap: 0.25rem; flex-wrap: wrap;
    min-height: 1.5rem; margin-bottom: 0.35rem;
    padding: 0.2rem; background: #0a0a12; border-radius: 3px;
}
.rw-doc  { padding: 0.1rem 0.3rem; background: #1a1a2a; border-radius: 3px; color: #99b }
.rw-doc.active { background: #162416; color: #8c8 }
.rw-dim  { color: #333; font-style: italic }
.rw-log  {
    border-top: 1px solid #1a1a28; padding-top: 0.25rem;
    max-height: 12rem; overflow-y: auto;
    display: flex; flex-direction: column; gap: 1px;
}
.rw-row  { display: flex; gap: 0.5rem; padding: 0.06rem 0; font-size: 0.75rem }
.rw-row.g { color: #99b }
.rw-row.u { color: #686 }
.rw-src  { flex-shrink: 0; width: 2rem; text-align: right; color: inherit; font-weight: bold }
.rw-paths { color: #556 }
.rw-row.g .rw-paths { color: #aaa }
</style>
