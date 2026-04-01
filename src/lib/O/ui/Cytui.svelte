<script lang="ts">
    // Cytui.svelte — Cytoscape rendering widget for the H:Story/H** graph.
    //

    import { onMount }    from 'svelte'
    import cytoscape      from 'cytoscape'
    import fcose          from 'cytoscape-fcose'
    import type { House } from '$lib/O/Housing.svelte'
    import { _C, type TheC }  from '$lib/data/Stuff.svelte'

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
        step_n?:     number   // story step this wave belongs to (always set now)
    }

    let status          = $state('no graph')
    let grawave_dur     = $state(0.3)
    let last_tick       = -1
    let seek_warning = $state<string | null>(null)

    $effect(() => {
        const gn = H?.graph?.find((n: TheC) => n.sc.cyto_graph) as TheC | undefined
        if (!gn) return
 
        seek_warning = (gn.sc.seek_warning as string | null) ?? null
 
        const wave = gn.sc.wave as TheC | undefined
        const tick = (gn.sc.tick as number) ?? -1
        if (!wave || tick === last_tick) return
        last_tick = tick
        const dur = (wave.sc.duration as number) ?? 0.3
        if (cy) enqueue(wave)
        grawave_dur = dur
        const sn = wave.sc.step_n != null ? ` step:${wave.sc.step_n}` : ''
        status = `tick ${last_tick}${sn}`
            + ` · ${wave.o({ upsert:      1 }).length}n`
            + ` ${wave.o({ edge_upsert: 1 }).length}e`
            + ` −${wave.o({ remove:      1 }).length}`
            + ` ~${wave.o({ migrate:     1 }).length}`
            + ` · ⏱${dur}s`
    })

    // ── NON_ANIM ──────────────────────────────────────────────────────────────
    // Cytoscape cannot tween these — apply immediately or they throw.
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
//#endregion
//#region animations

    let animations: TheC = $state(_C({ animations: 1 }))
    let anim_interval: ReturnType<typeof setInterval> | null = null

    function start_anim_interval() {
        if (anim_interval) return
        anim_interval = setInterval(tick_animations, 80)   // ~12fps for aiming
    }
    function stop_anim_interval() {
        if (anim_interval) { clearInterval(anim_interval); anim_interval = null }
    }

    function tick_animations() {
        animations.c.ticks = (animations.c.ticks ?? 0) + 1
        if (animations.c.ticks > 100) { rush_animations(); return }

        for (const mg of animations.o({ migrate: 1 }) as TheC[]) {
            // find first non-done cue in order
            const cues = (mg.o({ cue: 1 }) as TheC[])
                .sort((a, b) => (a.sc.order as number) - (b.sc.order as number))
            const cue = cues.find(c => !c.c.done)
            if (!cue) { mg.drop(mg); continue }

            if (cue.sc.regularly) {
                const done = cue.c.fn?.()
                if (done) cue.drop(cue)       // advance to next cue next tick
            } else {
                cue.c.fn?.()
                cue.drop(cue)                 // immediate cues run once and vanish
            }
        }

        if (!animations.oa({ migrate: 1 })) stop_anim_interval()
    }

    function rush_animations() {
        for (const mg of animations.o({ migrate: 1 }) as TheC[]) {
            const finality = (mg.o({ cue: 1 }) as TheC[]).find(c => c.sc.finality)
            finality?.c.fn?.()
        }
        animations = _C({ animations: 1 })
        stop_anim_interval()
    }



    function flying(mg: any, dur: number) {
        const from_id   = mg.sc.id     as string
        const toward_id = mg.sc.toward as string
        const proj_id   = `${from_id}_proj`

        const am = animations.i({ ...mg.sc })

        const c1 = am.i({ cue: 'hide_arrival', order: 1 })
        c1.c.fn = () => {
            cy.getElementById(toward_id).style({ opacity: 0 })
            am.c.src_pos = cy.getElementById(from_id).renderedPosition()
        }

        const c2 = am.i({ cue: 'spawn_proj', order: 2 })
        c2.c.fn = () => {
            const from = cy.getElementById(from_id)
            if (!from.length) return
            const proj = cy.add({ group: 'nodes', data: { id: proj_id } })
            proj.style({ ...from.style(), opacity: 1 })
            proj.renderedPosition(am.c.src_pos ?? from.renderedPosition())
        }

        const c3 = am.i({ cue: 'aim', until: dur, regularly: 1 })
        c3.c.fn = () => {
            const proj   = cy.getElementById(proj_id)
            const toward = cy.getElementById(toward_id)
            if (!proj.length || !toward.length) return true
            const tpos = toward.renderedPosition()
            const cur  = proj.renderedPosition()
            const dx = tpos.x - cur.x
            const dy = tpos.y - cur.y
            if (Math.sqrt(dx*dx + dy*dy) < 8) return true   // arrived
            proj.renderedPosition({ x: cur.x + dx * 0.35, y: cur.y + dy * 0.35 })
            return false
        }

        const c4 = am.i({ cue: 'arrive', delay: dur, finality: 1 })
        c4.c.fn = () => {
            cy.getElementById(from_id).remove()
            cy.getElementById(proj_id).remove()
            cy.getElementById(toward_id).style({ opacity: 1 })
        }

        return am
    }

//#endregion
//#region apply

    function apply(wave: TheC, dur: number) {
        if (!cy) return
        rush_animations()                          // finalize any in-flight
        animations = _C({ animations: 1 })        // fresh slate
        const ms = Math.round(dur * 1000)
        if (wave.sc.cyto_wipe) {
            console.log(`%cyto_wipe removes and re-adds the entire graph`)
            cy.elements().remove()
        }

        // 1. remove stale edges
        for (const n of wave.o({ edge_remove: 1 }) as TheC[])
            cy.getElementById(n.sc.id as string).remove()
 
        // 2. remove stale nodes (skip migrating ids)
        const migrating = new Set([
            ...(wave.o({ migrate: 1 }) as TheC[]).map(m => m.sc.id as string),
            ...(wave.o({ migrate: 1 }) as TheC[]).map(m => m.sc.toward as string),
        ])

        for (const n of wave.o({ remove: 1 }) as TheC[]) {
            if (!migrating.has(n.sc.id as string)) {
                cy.getElementById(n.sc.id as string).remove()
            }
        }
 
        // 3. upsert nodes
        for (const nd of wave.o({ upsert: 1 }) as TheC[]) {
            const id = nd.sc.id as string
            const el = cy.getElementById(id)
            const { anim, imm } = split_style(nd.sc.style as Record<string,any>)
            if (el.length) {
                const new_parent = nd.sc.new_parent as string | null | undefined
                if (new_parent !== undefined && !migrating.has(id)
                    && el.parent().id() !== (new_parent ?? '')) {
                    el.move({ parent: new_parent ?? null })
                }
                el.data('label', nd.sc.label)
                if (Object.keys(imm).length) el.style(imm)
                if (ms > 0 && Object.keys(anim).length) {
                    el.animate({ style: anim }, { duration: ms, easing: 'ease-out-cubic' })
                } else { el.style(anim) }
            } else {
                const data: any = { id, label: nd.sc.label }
                const parent = nd.sc.parent as string | undefined
                if (parent) data.parent = parent
                const added = cy.add({ group: 'nodes', data })
                added.style({ ...imm, ...anim })
                if (nd.sc.appear_from) {
                    const spawn = cy.getElementById(nd.sc.appear_from as string)
                    if (spawn.length) added.position(spawn.position())
                }
            }
        }
 
        // 4. upsert edges
        for (const ed of wave.o({ edge_upsert: 1 }) as TheC[]) {
            const id = ed.sc.id as string
            const el = cy.getElementById(id)
            const { anim, imm } = split_style(ed.sc.style as Record<string,any>)
            if (el.length) {
                if (ed.sc.ideal_length != null) el.data('ideal_length', ed.sc.ideal_length)
                if (Object.keys(imm).length) el.style(imm)
                if (ms > 0 && Object.keys(anim).length) {
                    el.animate({ style: anim }, { duration: ms })
                } else { el.style(anim) }
            } else {
                const data: any = { id,
                    source: ed.sc.source as string,
                    target: ed.sc.target as string,
                }
                if (ed.sc.ideal_length != null) data.ideal_length = ed.sc.ideal_length
                try {
                    const added = cy.add({ group: 'edges', data })
                    added.style({ ...imm, ...anim })
                } catch { /* source/target may not exist yet */ }
            }
        }
 
        // 5. migrations
        for (const mg of wave.o({ migrate: 1 }) as TheC[]) {
            // < attach other swooshing-over-there modes here
            let am = flying(mg,dur)
            if (!dur) {
                // no time, forget everything non-essential
                am.o({cue:1}).filter(cu => !cu.sc.finality).map(cu => cu.drop(cu))
            }
        }

        if (animations.oa({ migrate: 1 })) start_anim_interval()
 
        // 6. layout
        if (wave.o({ upsert:      1 }).length
         || wave.o({ remove:      1 }).length
         || wave.o({ edge_upsert: 1 }).length) {
            relayout(ms, wave.sc.constraints)
        }
    }

//#endregion
//#region layout

    // ── wave queue ────────────────────────────────────────────────────────────
    //
    // IDEAS TO REVISIT:
    //   - phantom/ghost nodes: add invisible target-side clone before reparenting
    //     so compound bounds are correct before the animation begins (open→move→close)
    //   - FLIP (First Last Invert Play): snapshot renderedPosition() before structural
    //     change, apply change instantly, animate from inverted delta back to 0
    //   - lock non-migrating nodes during migration phase so only compounds resize
    //   - partial layout: only run layout on the subgraph that actually changed
    //     (fcose supports fixed positions via fixedNodeConstraint)
    //   - fade-out on remove: opacity→0 over shr_ms before .remove()
    //   - staggered entry: new nodes fade in from opacity 0 over first 30% of dur
    //   - compound pre-sizing: emit phantom children at target parent before migration
    //     so fcose sees correct compound bbox from the start

    const YOINK_MS = 50

    let wave_queue: TheC[] = []
    let anim_busy   = false
    let anim_end_at = 0

    function enqueue(wave: TheC) {
        const now = Date.now()
        if (anim_busy && now < anim_end_at - YOINK_MS) {
            // a wave is mid-flight — yoink all elements to their end state
            cy.elements().stop(true, true)  // jumps to animation end-values
            lay?.stop()
            // drain anything already queued at dur=0 so state is consistent
            while (wave_queue.length) apply(wave_queue.shift()!, 0)
            anim_busy = false
            // small pause so cytoscape commits the jumped positions
            wave_queue.push(wave)
            setTimeout(process_queue, YOINK_MS)
        } else {
            wave_queue.push(wave)
            if (!anim_busy) process_queue()
        }
    }

    function process_queue() {
        if (!wave_queue.length) { anim_busy = false; return }
        const wave = wave_queue.shift()!
        // if more waves are already waiting, drain at 25fps
        const dur = wave_queue.length ? 0.04 : ((wave.sc.duration as number) ?? 0.3)
        anim_busy   = true
        anim_end_at = Date.now() + dur * 1000
        apply(wave, dur)
        setTimeout(process_queue, dur * 1000 + 20)
    }


    // ── layout ────────────────────────────────────────────────────────────────

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
        // after animated layouts, fit to fill the container
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
                    // compound (worker) containers — always rendered, even when empty
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
        // rebuild from scratch on HMR
        H.elvisto('Cyto/Cyto', 'cyto_wipe', {})
        return () => { lay?.stop(); cy?.destroy() }
    })
</script>

<div class="cytui">
    <div class="cytui-bar">
        <span class="cytui-status">{status}</span>
        {#if seek_warning}
            <span class="cytui-warn">⚠ {seek_warning}</span>
        {/if}
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
.cytui-warn { color: #c88; font-size: 9px; font-style: italic; }
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