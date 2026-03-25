<script lang="ts">
    // Cytui.svelte — Cytoscape rendering widget for the LeafFarm graph.
    //
    // Receives H (the Story sub-House).  Reads the live wave from
    // H.graph/{cyto_graph:1}.wave which w:Cyto updates each tick.
    //
    // ── seek ─────────────────────────────────────────────────────────────────
    //
    //   When StoryRun opens a step it fires H.elvisto('Cyto/Cyto','cyto_seek',
    //   {seek_step:N}).  w:Cyto writes gn.sc.seek_step and bumps the graph
    //   particle.  The $effect here reads seek_step and finds the last wave
    //   in history whose .step_n <= seek_step, then applies it at duration=0
    //   so the graph snaps to that moment without animation.
    //
    //   Waves from ambient Cyto() ticks have step_n undefined; only waves
    //   emitted during intoCyto mode (story_cyto_step) are tagged.  When the
    //   panel is closed seek_step is null and we return to the live head.
    //
    // ── history ───────────────────────────────────────────────────────────────
    //
    //   Wave history is retained for the seek feature.  The ◀ ▶ walk-back UI
    //   controls have been removed — seeking is driven by StoryRun navigation.

    import { onMount }    from 'svelte'
    import cytoscape      from 'cytoscape'
    import fcose          from 'cytoscape-fcose'
    import type { House } from '$lib/O/Housing.svelte'
    import type { TheC }  from '$lib/data/Stuff.svelte'

    cytoscape.use(fcose)

    let { H }: { H: House } = $props()

    let container: HTMLDivElement
    let cy: ReturnType<typeof cytoscape>

    // ── wave types ────────────────────────────────────────────────────────────

    type NodeDesc = {
        id: string; label: string; style: Record<string,any>
        parent?: string; new_parent?: string; appear_from?: string
        isCompound?: boolean
    }
    type EdgeDesc = {
        id: string; source: string; target: string
        data?: Record<string,any>; style: Record<string,any>
    }
    type MigrateDesc = {
        id: string; toward: string
        then_parent?: string; harvest_detach?: boolean; mouthful_expire?: boolean
    }
    type Wave = {
        upsert:      NodeDesc[]
        edge_upsert: EdgeDesc[]
        remove:      string[]
        edge_remove: string[]
        migrate:     MigrateDesc[]
        constraints: any | null
        duration:    number
        step_n?:     number   // set by story_cyto_step; undefined for ambient ticks
    }

    let history:    Wave[] = []
    let status      = $state('no graph')
    let grawave_dur = $state(0.3)
    let last_tick   = -1

    // ── reactive: H.graph → cyto_graph particle ───────────────────────────────

    $effect(() => {
        const gn = H?.graph?.find((n: TheC) => n.sc.cyto_graph) as TheC | undefined
        if (!gn) return

        // ── seek ──────────────────────────────────────────────────────────────
        //
        //   seek_step set by w:Cyto when StoryRun opens a step.
        //   Find the last wave whose step_n <= seek_step and apply it frozen.
        //   seek_step null → return to live head (most recent history entry).
        const seek = gn.sc.seek_step as number | null | undefined
        if (seek != null && cy) {
            let target_idx = -1
            for (let i = 0; i < history.length; i++) {
                if (history[i].step_n != null && history[i].step_n! <= seek) {
                    target_idx = i
                }
            }
            if (target_idx >= 0) {
                // rebuild from scratch so nodes match the sought state exactly
                cy.elements().remove()
                for (let i = 0; i <= target_idx; i++) apply(history[i], 0)
                status = `seek step:${seek} (wave ${target_idx + 1}/${history.length})`
                return   // don't fall through to live-head enqueue below
            }
        }

        // ── live head ─────────────────────────────────────────────────────────
        const wave = gn.sc.wave as Wave | undefined
        const tick = (gn.sc.tick as number) ?? -1
        if (!wave || tick === last_tick) return
        last_tick = tick
        if (cy) enqueue(wave)
    })

    function enqueue(wave: Wave) {
        history = [...history, wave]
        apply(wave, wave.duration)
        grawave_dur = wave.duration
        const nu = wave.upsert?.length ?? 0
        const eu = wave.edge_upsert?.length ?? 0
        const rm = wave.remove?.length ?? 0
        const mg = wave.migrate?.length ?? 0
        const sn = wave.step_n != null ? ` step:${wave.step_n}` : ''
        status = `tick ${last_tick}${sn} · ${nu}n ${eu}e −${rm} ~${mg} · ⏱${wave.duration}s`
    }

    // ── NON_ANIM ──────────────────────────────────────────────────────────────
    const NON_ANIM = new Set([
        'shape','background-image','background-fit','content','label',
        'source-label','target-label','line-style','target-arrow-shape',
        'source-arrow-shape','curve-style','text-valign','text-halign',
        'font-size','font-weight','font-style','font-family','text-wrap',
        'text-max-width','padding','border-style',
        'min-width','min-height','min-width-bias-left','min-width-bias-right',
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

        // 2. remove stale nodes (skip migrating)
        const migrating = new Set((wave.migrate ?? []).map(m => m.id))
        for (const id of wave.remove ?? []) {
            if (!migrating.has(id)) cy.getElementById(id).remove()
        }

        // 3. upsert nodes
        for (const nd of wave.upsert ?? []) {
            const el = cy.getElementById(nd.id)
            const { anim, imm } = split_style(nd.style)
            if (el.length) {
                if (nd.new_parent && el.parent().id() !== nd.new_parent) el.move({ parent: nd.new_parent })
                el.data('label', nd.label)
                if (Object.keys(imm).length) el.style(imm)
                if (ms > 0 && Object.keys(anim).length) {
                    el.animate({ style: anim }, { duration: ms, easing: 'ease-out-cubic' })
                } else { el.style(anim) }
            } else {
                const data: any = { id: nd.id, label: nd.label }
                if (nd.parent) data.parent = nd.parent
                const added = cy.add({ group: 'nodes', data })
                added.style({ ...imm, ...anim })
                if (nd.appear_from) {
                    const spawn = cy.getElementById(nd.appear_from)
                    if (spawn.length) added.position(spawn.position())
                }
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
                } else { el.style(anim) }
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
            if (mg.harvest_detach) {
                el.move({ parent: null })
                el.connectedEdges().remove()
            }
            if (!toward.length || ms <= 0) {
                mg.then_parent ? el.move({ parent: mg.then_parent }) : el.remove()
                continue
            }
            const tpos   = toward.renderedPosition()
            const fly_ms = Math.round(ms * 0.75)
            const shr_ms = Math.round(ms * 0.20)
            if (mg.then_parent) {
                el.animate(
                    { renderedPosition: tpos },
                    { duration: fly_ms, easing: 'ease-in-out-cubic',
                      complete: () => { const s = cy.getElementById(mg.id); if (s.length) s.move({ parent: mg.then_parent! }) } }
                )
            } else if (mg.mouthful_expire) {
                el.animate(
                    { style: { opacity: 0, width: 3, height: 3 } },
                    { duration: Math.round(ms * 0.40), easing: 'ease-out-cubic',
                      complete: () => cy.getElementById(mg.id).remove() }
                )
            } else {
                // leaf harvest: fly to mat:basic then shrink
                el.animate(
                    { renderedPosition: tpos },
                    { duration: fly_ms, easing: 'ease-in-cubic',
                      complete: () => {
                          const s = cy.getElementById(mg.id)
                          if (!s.length) return
                          s.animate(
                              { style: { opacity: 0, width: 4, height: 4 } },
                              { duration: shr_ms, easing: 'ease-out-cubic',
                                complete: () => cy.getElementById(mg.id).remove() }
                          )
                      } }
                )
            }
        }

        // 6. layout with auto-fit
        if (wave.upsert?.length || wave.remove?.length || wave.edge_upsert?.length) {
            relayout(ms, wave.constraints)
        }
    }

    // ── layout ────────────────────────────────────────────────────────────────
    //
    //   After each animated layout, attach a one-shot layoutstop listener that
    //   fits all nodes with 16px padding.  Skipped for instant (ms=0) applies
    //   so seek rebuilds don't zoom-thrash; caller can fit manually if needed.

    let lay: any
    function relayout(animMs = 300, constraints?: any) {
        lay?.stop()
        lay = cy.layout({
            name:                        'fcose',
            animate:                     animMs > 0,
            animationDuration:           animMs,
            nodeSeparation:              30,
            nodeDimensionsIncludeLabels: true,
            randomize:                   false,
            quality:                     'default',
            idealEdgeLength: (edge: any) => {
                const il = edge.data('ideal_length')
                return typeof il === 'number' ? il : 80
            },
            edgeElasticity: (edge: any) =>
                (edge.id() as string).startsWith('e:helio:') ? 0.10 : 0.45,
            nodeRepulsion: () => 4000,
            ...(constraints ?? {}),
        })
        if (animMs > 0) {
            const on_stop = () => {
                cy.removeListener('layoutstop', on_stop)
                cy.fit(cy.nodes(), 16)
            }
            cy.on('layoutstop', on_stop)
        }
        try { lay.run() } catch (e) { console.warn('layout error', e) }
    }

    // ── cytoscape init ────────────────────────────────────────────────────────
    onMount(() => {
        cy = cytoscape({
            container,
            style: [
                {
                    selector: 'node',
                    style: {
                        label: 'data(label)', 'text-valign': 'center',
                        'text-wrap': 'wrap', 'text-max-width': '72px',
                        'font-size': '9px',
                        'font-family': "'Berkeley Mono','Fira Code',monospace",
                        color: '#ddd', 'background-color': '#222',
                        width: 24, height: 24,
                    },
                },
                {
                    selector: ':parent',
                    style: {
                        'text-valign': 'top', 'text-halign': 'center',
                        'font-size': '10px',
                        'min-width': 80, 'min-height': 60,
                    },
                },
                { selector: 'node:selected',
                  style: { 'border-width': 2, 'border-color': '#79b' } },
                {
                    selector: 'edge',
                    style: {
                        width: 1.2, 'line-color': '#2a2a2a',
                        'target-arrow-shape': 'none', 'curve-style': 'bezier',
                        opacity: 0.5,
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
        <button onclick={() => cy?.fit(cy.nodes(), 16)}>⊞</button>
        <span class="cytui-dur">⏱ {grawave_dur}s</span>
    </div>
    <div class="cytui-legend">
        <span class="l-leaf">🌿 leaf</span>
        <span class="l-mf">◦ bite</span>
        <span class="l-sun">◆ sun</span>
        <span class="l-poo">● poo</span>
        <span class="l-mat">■ mat</span>
        <span class="l-prod">▪ prod</span>
        <span class="l-prot">⬡ prot</span>
        <span class="l-enz">▬ enz</span>
        <span class="l-stem">─ stem</span>
        <span class="l-helio">╌ helio</span>
        <span class="l-flow">→ flow</span>
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
.cytui-dur { color: #2a2a44; font-size: 9px; }
.cytui-bar button {
    background: #141414; border: 1px solid #1e1e1e; border-radius: 2px;
    color: #555; cursor: pointer; font-size: 12px; line-height: 1;
    padding: 1px 5px; font-family: inherit;
}
.cytui-bar button:hover { background: #1e1e1e; color: #999; }
.cytui-legend {
    display: flex; flex-wrap: wrap; gap: 6px;
    padding: 2px 10px; background: #080808;
    border-bottom: 1px solid #141414;
    font-size: 8px; flex-shrink: 0; opacity: 0.6;
}
.l-leaf  { color: #4c9 } .l-mf   { color: #af5 }
.l-sun   { color: #fb0 } .l-poo  { color: #974 }
.l-mat   { color: #b82 } .l-prod { color: #46f }
.l-prot  { color: #c8f } .l-enz  { color: #4a8 }
.l-stem  { color: #3a6 } .l-helio { color: #880 }
.l-flow  { color: #556 }
.cytui-graph { flex: 1; min-height: 0; }
</style>