<script lang="ts">
    import { onMount }    from 'svelte'
    import cytoscape      from 'cytoscape'
    import fcose          from 'cytoscape-fcose'
    import type { House } from '$lib/O/Housing.svelte'
    import type { TheC }  from '$lib/data/Stuff.svelte'

    cytoscape.use(fcose)

    let { H }: { H: House } = $props()

    let container: HTMLDivElement
    let cy: ReturnType<typeof cytoscape>

    type NodeDesc = {
        id:          string
        label:       string
        style:       Record<string,any>
        parent?:     string
        new_parent?: string
        isCompound?: boolean
    }
    type EdgeDesc = {
        id: string; source: string; target: string
        data?: Record<string,any>; style: Record<string,any>
    }
    type MigrateDesc = {
        id:              string
        toward:          string
        then_parent?:    string
        harvest_detach?: boolean   // if true: move({parent:null}) before animating
    }
    type Wave = {
        upsert:      NodeDesc[]
        edge_upsert: EdgeDesc[]
        remove:      string[]
        edge_remove: string[]
        migrate:     MigrateDesc[]
        constraints: any | null
        duration:    number
    }

    let history:    Wave[] = []
    let pos         = $state(-1)
    let status      = $state('no graph')
    let grawave_dur = $state(0.3)
    let last_tick   = -1

    $effect(() => {
        const gn = H?.graph?.find((n: TheC) => n.sc.cyto_graph) as TheC | undefined
        if (!gn) return
        const wave = gn.sc.wave as Wave | undefined
        const tick = (gn.sc.tick as number) ?? -1
        if (!wave || tick === last_tick) return
        last_tick = tick
        if (cy) enqueue(wave)
    })

    function enqueue(wave: Wave) {
        if (pos < history.length - 1) history = history.slice(0, pos + 1)
        history = [...history, wave]
        pos = history.length - 1
        apply(wave, wave.duration)
        grawave_dur = wave.duration
        const nu = wave.upsert?.length ?? 0
        const eu = wave.edge_upsert?.length ?? 0
        const rm = wave.remove?.length ?? 0
        const mg = wave.migrate?.length ?? 0
        status = `tick ${last_tick} · ${nu}n ${eu}e −${rm} ~${mg} · ⏱${wave.duration}s`
    }

    const NON_ANIM = new Set([
        'shape','background-image','background-fit','content','label',
        'source-label','target-label','line-style','target-arrow-shape',
        'source-arrow-shape','curve-style','text-valign','text-halign',
        'font-size','font-weight','font-style','font-family','text-wrap',
        'text-max-width','padding','border-style',
    ])

    function split_style(style: Record<string,any> = {}) {
        const anim: any = {}, imm: any = {}
        for (const [k, v] of Object.entries(style)) {
            if (v == null) continue
            ;(NON_ANIM.has(k) ? imm : anim)[k] = v
        }
        return { anim, imm }
    }

    function apply(wave: Wave, dur: number) {
        if (!cy) return
        const ms = Math.round(dur * 1000)

        // 1. remove stale edges
        for (const id of wave.edge_remove ?? []) cy.getElementById(id).remove()

        // 2. remove stale nodes — skip migrating ids
        const migrating = new Set((wave.migrate ?? []).map(m => m.id))
        for (const id of wave.remove ?? []) {
            if (!migrating.has(id)) cy.getElementById(id).remove()
        }

        // 3. upsert nodes
        for (const nd of wave.upsert ?? []) {
            const el = cy.getElementById(nd.id)
            const { anim, imm } = split_style(nd.style)

            if (el.length) {
                if (nd.new_parent && el.parent().id() !== nd.new_parent) {
                    el.move({ parent: nd.new_parent })
                }
                el.data('label', nd.label)
                if (Object.keys(imm).length) el.style(imm)
                if (ms > 0 && Object.keys(anim).length) {
                    el.animate({ style: anim }, { duration: ms, easing: 'ease-out-cubic' })
                } else {
                    el.style(anim)
                }
            } else {
                const data: any = { id: nd.id, label: nd.label }
                if (nd.parent) data.parent = nd.parent
                const added = cy.add({ group: 'nodes', data })
                added.style({ ...imm, ...anim })
            }
        }

        // 4. upsert edges
        for (const ed of wave.edge_upsert ?? []) {
            const el = cy.getElementById(ed.id)
            const { anim, imm } = split_style(ed.style)

            if (el.length) {
                if (ed.data?.ideal_length != null) el.data('ideal_length', ed.data.ideal_length)
                if (Object.keys(imm).length) el.style(imm)
                if (ms > 0 && Object.keys(anim).length) {
                    el.animate({ style: anim }, { duration: ms })
                } else {
                    el.style(anim)
                }
            } else {
                const data: any = { id: ed.id, source: ed.source, target: ed.target }
                if (ed.data) Object.assign(data, ed.data)
                try {
                    const added = cy.add({ group: 'edges', data })
                    added.style({ ...imm, ...anim })
                } catch { /* source/target may not exist yet */ }
            }
        }

        // 5. migrations
        for (const mg of wave.migrate ?? []) {
            const el     = cy.getElementById(mg.id)
            const toward = cy.getElementById(mg.toward)
            if (!el.length) continue

            // ── harvest_detach: remove from parent compound immediately ───────
            // Without this the compound resizes to track the node's animated
            // position as it flies across the canvas — detaching first keeps the
            // farm box still.  Edges that referenced the node by parent compound
            // have already been removed in step 1 (edge_remove), so no dangling.
            if (mg.harvest_detach) {
                el.move({ parent: null })
                // also drop its stem/helio edges so they don't linger mid-flight
                el.connectedEdges().remove()
            }

            if (!toward.length || ms <= 0) {
                mg.then_parent ? el.move({ parent: mg.then_parent }) : el.remove()
                continue
            }

            const tpos   = toward.renderedPosition()
            const anim_ms = Math.round(ms * 0.82)

            if (mg.then_parent) {
                el.animate(
                    { renderedPosition: tpos },
                    { duration: anim_ms, easing: 'ease-in-out-cubic',
                      complete: () => {
                          const still = cy.getElementById(mg.id)
                          if (still.length) still.move({ parent: mg.then_parent! })
                      } }
                )
            } else {
                // harvest: shrink + fade into mat:basic, then remove
                el.animate(
                    { renderedPosition: tpos,
                      style: { opacity: 0, width: 4, height: 4 } },
                    { duration: anim_ms, easing: 'ease-in-cubic',
                      complete: () => { cy.getElementById(mg.id).remove() } }
                )
            }
        }

        // 6. layout
        if (wave.upsert?.length || wave.remove?.length || wave.edge_upsert?.length) {
            relayout(ms, wave.constraints)
        }
    }

    function walk(dir: -1 | 1) {
        const next = pos + dir
        if (next < 0 || next >= history.length) return
        if (dir === 1) {
            apply(history[next], 0.2)
        } else {
            cy.elements().remove()
            for (let i = 0; i <= next; i++) apply(history[i], 0)
        }
        pos = next
        status = `history ${pos + 1}/${history.length} (walk)`
    }

    let lay: any
    function relayout(animMs = 300, constraints?: any) {
        lay?.stop()
        lay = cy.layout({
            name:                        'fcose',
            animate:                     animMs > 0,
            animationDuration:           animMs,
            nodeSeparation:              22,
            nodeDimensionsIncludeLabels: true,
            randomize:                   false,
            quality:                     'default',
            idealEdgeLength: (edge: any) => {
                const il = edge.data('ideal_length')
                return typeof il === 'number' ? il : 80
            },
            edgeElasticity: (edge: any) => {
                const id = edge.id() as string
                return id.startsWith('e:helio:') ? 0.10 : 0.45
            },
            nodeRepulsion: () => 4000,
            ...(constraints ?? {}),
        })
        try { lay.run() } catch (e) { console.warn('layout error', e) }
    }

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
                        'text-max-width': '62px',
                        'font-size':      '7px',
                        'font-family':    "'Berkeley Mono','Fira Code',monospace",
                        color:            '#ddd',
                        'background-color': '#222',
                        width:  22, height: 22,
                    },
                },
                {
                    selector: ':parent',
                    style: { 'text-valign': 'top', 'text-halign': 'center' },
                },
                {
                    selector: 'node:selected',
                    style: { 'border-width': 2, 'border-color': '#79b' },
                },
                {
                    selector: 'edge',
                    style: {
                        width:                1.2,
                        'line-color':         '#2a2a2a',
                        'target-arrow-shape': 'none',
                        'curve-style':        'bezier',
                        opacity:              0.5,
                    },
                },
            ],
        })
        return () => { lay?.stop(); cy?.destroy() }
    })
</script>

<div class="cytui">
    <div class="cytui-bar">
        <span class="cytui-status">{status}</span>
        <button onclick={() => relayout(300)}>⟳</button>
        <button onclick={() => cy?.fit()}>⊞</button>
        <span class="sep"></span>
        <button onclick={() => walk(-1)} disabled={pos <= 0}>◀</button>
        <span class="cytui-hist">{pos + 1}/{history.length}</span>
        <button onclick={() => walk(1)} disabled={pos >= history.length - 1}>▶</button>
        <span class="sep"></span>
        <span class="cytui-dur">⏱ {grawave_dur}s</span>
    </div>
    <div class="cytui-legend">
        <span class="l-leaf">🌿 leaf</span>
        <span class="l-sun">◆ sun</span>
        <span class="l-poo">● poo</span>
        <span class="l-mat">■ mat</span>
        <span class="l-prod">▪ prod</span>
        <span class="l-prot">⬡ prot</span>
        <span class="l-enz">▬ enz</span>
        <span class="l-stem">─ stem</span>
        <span class="l-helio">╌ helio</span>
    </div>
    <div class="cytui-graph" bind:this={container}></div>
</div>

<style>
.cytui {
    display: flex; flex-direction: column;
    height: 50vh; min-height: 320px;
    border: 1px solid #1a1a1a; border-radius: 4px;
    overflow: hidden; background: #070707;
    font-family: 'Berkeley Mono','Fira Code',ui-monospace,monospace;
    font-size: 11px; color: #aaa;
}
.cytui-bar {
    display: flex; align-items: center; gap: 5px;
    padding: 4px 8px; background: #0f0f0f;
    border-bottom: 1px solid #181818; flex-shrink: 0;
}
.cytui-status {
    flex: 1; color: #3a3a3a; overflow: hidden;
    text-overflow: ellipsis; white-space: nowrap; font-size: 9px;
}
.sep { width: 1px; background: #1e1e1e; height: 12px; margin: 0 2px; flex-shrink: 0; }
.cytui-hist { color: #2a2a2a; font-size: 9px; min-width: 34px; text-align: center; }
.cytui-dur  { color: #2a2a44; font-size: 9px; }
.cytui-bar button {
    background: #141414; border: 1px solid #1e1e1e; border-radius: 2px;
    color: #555; cursor: pointer; font-size: 12px; line-height: 1;
    padding: 1px 5px; font-family: inherit;
}
.cytui-bar button:hover:not(:disabled) { background: #1e1e1e; color: #999; }
.cytui-bar button:disabled { opacity: 0.18; cursor: default; }
.cytui-legend {
    display: flex; flex-wrap: wrap; gap: 6px;
    padding: 2px 10px; background: #080808;
    border-bottom: 1px solid #141414;
    font-size: 8px; flex-shrink: 0; opacity: 0.6;
}
.l-leaf  { color: #4c9 } .l-sun   { color: #fb0 }
.l-poo   { color: #974 } .l-mat   { color: #b82 }
.l-prod  { color: #46f } .l-prot  { color: #c8f }
.l-enz   { color: #4a8 } .l-stem  { color: #3a6 }
.l-helio { color: #880 }
.cytui-graph { flex: 1; min-height: 0; }
</style>