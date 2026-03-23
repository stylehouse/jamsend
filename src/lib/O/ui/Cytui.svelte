<script lang="ts">
    import { onMount } from 'svelte'
    import cytoscape    from 'cytoscape'
    import fcose        from 'cytoscape-fcose'
    import type { House } from '$lib/O/Housing.svelte'
    import type { TheC }  from '$lib/data/Stuff.svelte'

    cytoscape.use(fcose)

    let { H }: { H: House } = $props()

    // ── cytoscape instance ────────────────────────────────────────────────────
    let container: HTMLDivElement
    let cy: ReturnType<typeof cytoscape>

    // ── grawave history for walk-back ─────────────────────────────────────────
    // Each entry = the wave that was applied to reach that state.
    type Wave = { upsert: NodeDesc[]; remove: string[]; duration: number }
    type NodeDesc = { id: string; label: string; style: Record<string, any> }

    let history: Wave[] = []
    let pos = $state(-1)          // index of currently-displayed state
    let status = $state('no graph')
    let grawave_dur = $state(0.3) // seconds; shown in status

    // ── reactive: watch H.ave for cyto_graph particle ────────────────────────
    let last_tick = -1

    $effect(() => {
        const gn = H?.ave?.find((n: TheC) => n.sc.cyto_graph) as TheC | undefined
        if (!gn) return
        const wave = gn.sc.wave as Wave | undefined
        const tick = (gn.sc.tick as number) ?? -1
        if (!wave || tick === last_tick) return
        last_tick = tick
        if (cy) enqueue(wave)
    })

    // ── enqueue wave (only when at latest position) ───────────────────────────
    function enqueue(wave: Wave) {
        // If user walked back, discard forward history
        if (pos < history.length - 1) history = history.slice(0, pos + 1)
        history = [...history, wave]
        pos = history.length - 1
        apply(wave, wave.duration)
        grawave_dur = wave.duration
        status = `tick ${last_tick} | +${wave.upsert.length} -${wave.remove.length} | dur ${wave.duration}s`
    }

    // ── apply a wave to cy ────────────────────────────────────────────────────
    function apply(wave: Wave, dur: number) {
        if (!cy) return
        const ms = Math.round(dur * 1000)

        // Removals first
        for (const id of wave.remove) {
            cy.getElementById(id).remove()
        }

        // Upserts
        for (const nd of wave.upsert) {
            const existing = cy.getElementById(nd.id)
            if (existing.length) {
                // Animate style changes on existing nodes
                existing.data('label', nd.label)
                if (ms > 0) {
                    existing.animate({ style: nd.style }, { duration: ms, easing: 'ease-out-cubic' })
                } else {
                    existing.style(nd.style)
                }
            } else {
                cy.add({ group: 'nodes', data: { id: nd.id, label: nd.label }, style: nd.style })
            }
        }

        if (wave.upsert.length || wave.remove.length) {
            relayout(ms)
        }
    }

    // ── walk backward / forward through history ───────────────────────────────
    function walk(dir: -1 | 1) {
        const next = pos + dir
        if (next < 0 || next >= history.length) return

        if (dir === 1) {
            apply(history[next], 0.2)
        } else {
            // Undo: rebuild from scratch up to `next`
            cy.elements().remove()
            for (let i = 0; i <= next; i++) apply(history[i], 0)
        }

        pos = next
        status = `history ${pos + 1}/${history.length} (walk-mode)`
    }

    // ── layout ────────────────────────────────────────────────────────────────
    let lay: any
    function relayout(animMs = 300) {
        lay?.stop()
        lay = cy.layout({
            name: 'fcose',
            animate: animMs > 0,
            animationDuration: animMs,
            nodeSeparation: 130,
            nodeDimensionsIncludeLabels: true,
            randomize: false,
            quality: 'default',
        })
        try { lay.run() } catch {}
    }

    // ── cytoscape init ────────────────────────────────────────────────────────
    onMount(() => {
        cy = cytoscape({
            container,
            style: [
                {
                    selector: 'node',
                    style: {
                        label:            'data(label)',
                        'text-valign':    'center',
                        'text-wrap':      'wrap',
                        'text-max-width': '72px',
                        'font-size':      '8px',
                        'font-family':    "'Berkeley Mono', 'Fira Code', monospace",
                        color:            '#eee',
                        'background-color': '#2a2a2a',
                        width:  28,
                        height: 28,
                    },
                },
                {
                    selector: 'node:selected',
                    style: {
                        'border-width': 2,
                        'border-color': '#79b',
                    },
                },
                {
                    selector: 'edge',
                    style: {
                        width: 1.5,
                        'line-color': '#444',
                        'target-arrow-color': '#444',
                        'target-arrow-shape': 'triangle',
                        'curve-style': 'bezier',
                    },
                },
            ],
        })
        return () => { lay?.stop(); cy?.destroy() }
    })
</script>

<!-- ═══════════════════════════════════════════════════════════════════════ -->
<div class="cytui">

    <!-- toolbar -->
    <div class="cytui-bar">
        <span class="cytui-status">{status}</span>
        <button onclick={() => relayout(300)} title="Re-layout">⟳</button>
        <button onclick={() => cy?.fit()} title="Fit to screen">⊞</button>
        <span class="cytui-sep"></span>
        <button onclick={() => walk(-1)} disabled={pos <= 0} title="Walk back">◀</button>
        <span class="cytui-hist">{pos + 1}/{history.length}</span>
        <button onclick={() => walk(1)}  disabled={pos >= history.length - 1} title="Walk forward">▶</button>
        <span class="cytui-sep"></span>
        <span class="cytui-dur" title="grawave duration (seconds)">⏱ {grawave_dur}s</span>
    </div>

    <!-- legend -->
    <div class="cytui-legend">
        <span class="l-leaf">🌿 leaf</span>
        <span class="l-sun">◆ sun</span>
        <span class="l-poo">● poo</span>
        <span class="l-mat">■ material</span>
        <span class="l-prod">▪ producing</span>
        <span class="l-prot">● protein</span>
        <span class="l-enz">▪ enzyme</span>
    </div>

    <!-- cytoscape canvas -->
    <div class="cytui-graph" bind:this={container}></div>

</div>

<!-- ═══════════════════════════════════════════════════════════════════════ -->
<style>
.cytui {
    display: flex;
    flex-direction: column;
    height: 420px;
    border: 1px solid #222;
    border-radius: 4px;
    overflow: hidden;
    background: #0a0a0a;
    font-family: 'Berkeley Mono', 'Fira Code', ui-monospace, monospace;
    font-size: 11px;
    color: #ccc;
}

/* toolbar */
.cytui-bar {
    display: flex;
    align-items: center;
    gap: 5px;
    padding: 4px 8px;
    background: #141414;
    border-bottom: 1px solid #1e1e1e;
    flex-shrink: 0;
}
.cytui-status {
    flex: 1;
    color: #555;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    font-size: 10px;
}
.cytui-sep { width: 1px; background: #2a2a2a; height: 14px; margin: 0 2px; }
.cytui-hist { color: #444; font-size: 10px; min-width: 38px; text-align: center; }
.cytui-dur  { color: #557; font-size: 10px; }
.cytui-bar button {
    background: #1e1e1e;
    border: 1px solid #2a2a2a;
    border-radius: 2px;
    color: #888;
    cursor: pointer;
    font-size: 13px;
    line-height: 1;
    padding: 1px 5px;
}
.cytui-bar button:hover:not(:disabled) { background: #2a2a2a; color: #bbb; }
.cytui-bar button:disabled { opacity: 0.25; cursor: not-allowed; }

/* legend */
.cytui-legend {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    padding: 3px 10px;
    background: #0e0e0e;
    border-bottom: 1px solid #1a1a1a;
    font-size: 9px;
    flex-shrink: 0;
}
.cytui-legend span { opacity: 0.65; }
.l-leaf  { color: #4a9 }
.l-sun   { color: #fc0 }
.l-poo   { color: #a63 }
.l-mat   { color: #b84 }
.l-prod  { color: #48f }
.l-prot  { color: #b8f }
.l-enz   { color: #6a8 }

/* cytoscape canvas */
.cytui-graph {
    flex: 1;
    min-height: 0;
}
</style>