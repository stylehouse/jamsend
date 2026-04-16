<script lang="ts">
    // Cytui.svelte — Cytoscape rendering widget for the H:Story/H** graph.
    //
    // ── HTML overlay system ──────────────────────────────────────────────────
    //
    //   Text nodes (overlay_kind='code') get a positioned <pre> element rendered
    //   over the cytoscape canvas. The overlay tracks the node's rendered position
    //   and size, giving crisp monospace typography independent of graph zoom.
    //
    //   Bookmark nodes (overlay_kind='cm-hole') get a <div class="cm-hole"> that
    //   can later mount a CodeMirror EditorView — the scaffold for opening a hole
    //   in graph space into code space. The cm-hole has pointer-events:all so the
    //   user can type into it once a CM is mounted.
    //
    //   Overlays are tracked in `overlays: Map<string, HTMLElement>` keyed by
    //   cytoscape node id. They are created/updated in apply() after node upsert,
    //   removed when their node is removed, and repositioned on every layout stop
    //   and cy 'render' event.
    //

    import { onMount }    from 'svelte'
    import cytoscape      from 'cytoscape'
    import fcose       from 'cytoscape-fcose'
    import coseBilkent from 'cytoscape-cose-bilkent'
    import cola        from 'cytoscape-cola'
    import dagre       from 'cytoscape-dagre'

    import type { House } from '$lib/O/Housing.svelte'
    import { _C, type TheC }  from '$lib/data/Stuff.svelte'
    import { now_in_seconds_with_ms } from '$lib/p2p/Peerily.svelte';
    import MatstyleEditor from './MatstyleEditor.svelte'
    let matstyles = $state<TheC[]>([])
    let ms_palette: string[] = []
    let ms_shapes: string[]  = []

    cytoscape.use(fcose)
    cytoscape.use(coseBilkent)
    cytoscape.use(cola)
    cytoscape.use(dagre)

    let { H }: { H: House } = $props()

    let container: HTMLDivElement
    let cy: ReturnType<typeof cytoscape>
    let layout_name = $state<string>('fcose')

    let status          = $state('no graph')
    let grawave_dur     = $state(0.3)
    let last_tick       = -1
    let seek_warning = $state<string | null>(null)

    // ── overlay system ───────────────────────────────────────────────────────
    // Map of cytoscape node id → positioned HTML overlay element.
    // Created in apply(), repositioned on layout/render, destroyed on remove.
    let overlays: Map<string, HTMLElement> = new Map()
    // Container div for all overlays — sits over the cy canvas with pointer-events:none
    let overlay_container: HTMLDivElement

    // the UI channel - %matstyle come from Story
    $effect(() => {
        const ave = H.ave
        if (!ave?.length) return
        const styles_C = ave.find((n: TheC) => n.sc.Styles) as TheC | undefined
        matstyles  = styles_C?.o({ matstyle: 1 }) ?? []
        ms_palette = (H as any).MATSTYLE_PALETTE ?? []
        ms_shapes  = (H as any).MATSTYLE_SHAPES ?? []
        if (!styles_C) console.log(`Cyto H:${H.name}.ave:  ${styles_C}`)
    })
    // the graph data channel - %cyto_graph,wave=
    $effect(() => {
        const gn = H?.graph?.find((n: TheC) => n.sc.cyto_graph) as TheC | undefined
        if (!gn) return
 
        seek_warning = (gn.sc.seek_warning as string | null) ?? null
        layout_name = (gn.sc.layout_name as string) ?? 'fcose'
 
        const waves = (gn.sc.waves as TheC[] | undefined) ?? []
        const tick = (gn.sc.tick as number) ?? -1
        if (!waves.length || tick === last_tick) return
        if (!cy) return
        last_tick = tick

        // drain the queue — each wave gets enqueued in order
        gn.sc.waves = []
        for (const wave of waves) {
            enqueue(wave)
        }

        const wave = waves[waves.length - 1]
        const dur = (wave.sc.duration as number) ?? 0.3
        grawave_dur = dur
        const sn = wave.sc.step_n != null ? ` step:${wave.sc.step_n}` : ''
        status = `tick ${last_tick}${sn}`
            + (wave.sc.absolute ? ' abs' : '')
            + ` · ${wave.o({ upsert:      1 }).length}n`
            + ` ${wave.o({ edge_upsert: 1 }).length}e`
            + ` −${wave.o({ remove:      1 }).length}`
            + ` ~${wave.o({ migrate:     1 }).length}`
            + ` · ⏱${dur}s`
    })
    $effect(() => {
        if (layout_name && last_tick >= 0) {
            // re-run current graph through the new engine
            if (cy) relayout(400)
        }
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
        anim_interval = setInterval(tick_animations, 40)
    }
    function stop_anim_interval() {
        if (anim_interval) { clearInterval(anim_interval); anim_interval = null }
    }

    function tick_animations() {
        // in seconds
        const now     = performance.now() / 1000
        const started = animations.sc.started_at
        if (H.stopped) return

        if (now - started > 10) { rush_animations(); return }

        // a %cue,regularly can decide to get on with the %cue,delay after it
        let wrapping_up = false
        for (const mg of animations.o({ migrate: 1 }) as TheC[]) {
            const pending = (mg.o({ cue: 1 }) as TheC[]).find(c => !c.c.done)
            if (!pending) { mg.drop(mg); continue }

            const delay = pending.sc.delay as number | undefined
            const until = pending.sc.until as number | undefined

            // not ready yet
            // < if before next interval we should pool it for an exact timeout
            if (!wrapping_up && delay != null && now < started + delay) continue

            // time expired — auto-complete, next tick picks up next cue
            if (until != null && now >= started + until) {
                pending.drop(pending); continue
            }

            if (pending.sc.regularly) {
                const done = pending.sc.fn()
                if (done) {
                    pending.drop(pending)
                    if (pending.sc.wraps_up) wrapping_up = true
                }
            } else {
                pending.sc.fn()
                pending.drop(pending)
            }
        }

        if (!animations.oa({ migrate: 1 })) stop_anim_interval()
    }

    function rush_animations() {
        for (const mg of animations.o({ migrate: 1 }) as TheC[]) {
            for (let fin of mg.o({ cue: 1,finality:1 })) {
                fin.sc.fn()
            }
        }
        animations = _C({ animations: 1 })
        stop_anim_interval()
    }

    function flying(wave:TheC, mg: TheC, dur: number) {
        const from_id   = mg.sc.id     as string
        const toward_id = mg.sc.toward as string
        let upsert = wave.o({upsert:1,id:toward_id})[0]
        const proj_id   = `${from_id}_proj`
        let since = now_in_seconds_with_ms()
        let now = () => {
            return (now_in_seconds_with_ms() - since).toFixed(2)
        }

        const am = animations.i({ migrate: 1, from: from_id, toward: toward_id })
        if (upsert) {
            am.i({ 
                cue: 'hide_arrival', 
                fn: () => {
                    let to = cy.getElementById(toward_id)
                    to.style({ opacity: 0 }) // debug
                    if (upsert.sc.parent) {
                        // make it spawn in the middle of there, rather than drifting in...
                        let pa = cy.getElementById(upsert.sc.parent)
                        console.log(`Migrate ${now()}: new node shifted`)
                        to.renderedPosition(pa)
                    }
                } 
            })
            am.i({ 
                cue: 'set-parent', 
                delay: dur/2,
                fn: () => {
                    if (upsert.sc.parent) {
                        // migrations dont add the new node to the parent immediately
                        //  as they want to drift over
                        //  before the bounding box is made to expand for them
                        let to = cy.getElementById(toward_id)
                        to.move({parent:upsert.sc.parent})
                        console.log(`Migrate ${now()}: new node parented`)
                    }
                },
            })
            am.i({ 
                cue: 'spawn_proj', 
                fn: () => {
                    const from_el = cy.getElementById(from_id)
                    if (!from_el.length) return
                    from_el.style({ opacity: 0 }) // debug
                    let data = { id: proj_id }
                    if (upsert.sc.label != null) data.label = upsert.sc.label
                    const proj = cy.add({ group: 'nodes', data })
                    proj.style({ ...upsert.sc.style, opacity: 1 })
                    proj.renderedPosition(from_el.renderedPosition())

                    let to = cy.getElementById(toward_id).renderedPosition()
                    let from = cy.getElementById(from_id).renderedPosition()
                    const dx = to.x - from.x
                    const dy = to.y - from.y
                    const dist = Math.sqrt(dx * dx + dy * dy).toFixed(1)
                    console.log(`Migrate ${now()}: [${from.x}, ${from.y}] -> [${to.x}, ${to.y}] | Δ: <${dx.toFixed(1)}, ${dy.toFixed(1)}> | Dist: ${dist}`)
                } 
            })

            am.i({ 
                cue: 'aim', 
                regularly: 1, 
                until: dur,
                wraps_up: 1, // %cue:arrive immediately after this returns true
                fn: () => {
                    const proj   = cy.getElementById(proj_id)
                    const toward = cy.getElementById(toward_id)
                    if (!proj.length || !toward.length) return true
                    const tpos = toward.renderedPosition()
                    const cur  = proj.renderedPosition()
                    const dx = tpos.x - cur.x
                    const dy = tpos.y - cur.y
                    if (Math.sqrt(dx * dx + dy * dy) < 8) return true
                    proj.renderedPosition({ x: cur.x + dx * 0.35, y: cur.y + dy * 0.35 })
                    console.log(`Migrate ${now()}: aiming`)
                    return false
                } 
            })
        }

        am.i({ 
            cue: 'arrive', 
            delay: dur, 
            finality: 1, 
            fn: () => {
                cy.getElementById(proj_id).remove()
                cy.getElementById(from_id).remove()
                cy.getElementById(toward_id).style({ opacity: 1 })
                console.log(`Migrate ${now()}: arrive`)
            } 
        })
    }

//#endregion
//#region overlays

    // ── overlay lifecycle ─────────────────────────────────────────────────────
    //
    // create_overlay: called from apply() when a node with overlay_str is upserted.
    //   Creates a positioned HTML element in overlay_container, stores in overlays map.
    //
    // update_overlay: called on existing overlay — updates text if changed.
    //
    // remove_overlay: called when node is removed — destroys the DOM element.
    //
    // reposition_overlays: called after layout stops and on cy 'render' — moves
    //   each overlay to match its node's rendered position and zoom-adjusted size.

    function create_overlay(id: string, str: string, kind: string) {
        if (overlays.has(id)) return update_overlay(id, str)
        if (!overlay_container) return

        const el = document.createElement('div')
        el.className = kind === 'cm-hole' ? 'cyto-overlay cm-hole' : 'cyto-overlay code-overlay'
        el.dataset.nodeId = id

        if (kind === 'code') {
            const pre = document.createElement('pre')
            const code = document.createElement('code')
            code.textContent = str
            pre.appendChild(code)
            el.appendChild(pre)
        } else if (kind === 'cm-hole') {
            // scaffold for future CodeMirror mount
            el.innerHTML = `<div class="cm-hole-inner" data-cm-id="${id}"></div>`
        }

        overlay_container.appendChild(el)
        overlays.set(id, el)
    }

    function update_overlay(id: string, str: string) {
        const el = overlays.get(id)
        if (!el) return
        const code = el.querySelector('code')
        if (code && code.textContent !== str) code.textContent = str
    }

    function remove_overlay(id: string) {
        const el = overlays.get(id)
        if (!el) return
        el.remove()
        overlays.delete(id)
    }

    function reposition_overlays() {
        if (!cy || !overlay_container) return
        const zoom = cy.zoom()
        const pan  = cy.pan()

        for (const [id, el] of overlays) {
            const node = cy.getElementById(id)
            if (!node.length) { remove_overlay(id); continue }

            const pos = node.renderedPosition()
            const w   = node.renderedWidth()
            const h   = node.renderedHeight()

            el.style.left      = `${pos.x - w / 2}px`
            el.style.top       = `${pos.y - h / 2}px`
            el.style.width     = `${w}px`
            el.style.height    = `${h}px`
            el.style.fontSize  = `${Math.max(6, 12 * zoom)}px`
            el.style.display   = zoom < 0.3 ? 'none' : ''  // hide at extreme zoom-out
        }
    }

    function clear_all_overlays() {
        for (const [id, el] of overlays) el.remove()
        overlays.clear()
    }

//#endregion
//#region apply

    function apply(wave: TheC, dur: number) {
        if (!cy) return
        rush_animations()
        animations = _C({ animations: 1, started_at: performance.now() / 1000 })
        const ms = Math.round(dur * 1000)

        console.log(`🌊 apply() this wave: upsert x${wave.o({ upsert: 1 }).length}`)

        if (wave.sc.absolute) {
            console.log(`wave%absolute removes and re-adds the entire graph`)
            cy.elements().remove()
            clear_all_overlays()
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
            const rid = n.sc.id as string
            if (!migrating.has(rid)) {
                cy.getElementById(rid).remove()
                remove_overlay(rid)
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
                if (parent && !migrating.has(id)) data.parent = parent
                const added = cy.add({ group: 'nodes', data })
                added.style({ ...imm, ...anim })
                if (nd.sc.appear_from) {
                    const spawn = cy.getElementById(nd.sc.appear_from as string)
                    if (spawn.length) added.position(spawn.position())
                }
            }

            // ── overlay sync ─────────────────────────────────────────
            // Create or update HTML overlay for nodes carrying overlay_str.
            // Cytoscape handles the box/border; the overlay renders crisp text.
            const overlay_str  = nd.sc.overlay_str  as string | undefined
            const overlay_kind = nd.sc.overlay_kind as string | undefined
            if (overlay_str != null) {
                create_overlay(id, overlay_str, overlay_kind ?? 'code')
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
            let am = flying(wave,mg,dur)
            if (!dur) {
                // no time, forget everything non-essential
                am.o({cue:1}).filter(cu => !cu.sc.finality).map(cu => cu.drop(cu))
            }
        }

        // 6. constraints — fcose wants the exact shape:
        //   alignmentConstraint:        { vertical: [[ids],[ids]], horizontal: [[ids]] }
        //   relativePlacementConstraint: [ {top,bottom,gap}, {left,right,gap} ]
        // Lang sends `type: "alignmentConstraint"` / `"relativePlacementConstraint"` already
        // (matches fcose key names directly), each cyto_cons describing one group.
        // We bucket by (type, axis) — each cyto_cons becomes one inner array
        // for alignment, or one entry in the array for relativePlacement.
        if (wave.sc.constraints) {
            constraints = {}
            for (const [_id, c] of Object.entries(wave.sc.constraints) as [string, any][]) {
                const { type, axis, gap, nodes, top, bottom, left, right } = c

                if (type === 'alignmentConstraint') {
                    if (!Array.isArray(nodes) || nodes.length < 2) continue
                    constraints.alignmentConstraint ??= {}
                    constraints.alignmentConstraint[axis] ??= []
                    constraints.alignmentConstraint[axis].push([...nodes])
                } else if (type === 'relativePlacementConstraint') {
                    constraints.relativePlacementConstraint ??= []
                    if (axis === 'vertical' && top && bottom) {
                        constraints.relativePlacementConstraint.push({ top, bottom, gap })
                    } else if (axis === 'horizontal' && left && right) {
                        constraints.relativePlacementConstraint.push({ left, right, gap })
                    }
                }
            }
            if (Object.keys(constraints).length) console.log(`Constraints: `, constraints)
        } else {
            // wave with no constraints — clear out stale ones from the previous layout
            constraints = {}
        }


        if (animations.oa({ migrate: 1 })) start_anim_interval()
 
        // 7. layout
        if (wave.o({ upsert:      1 }).length
         || wave.o({ remove:      1 }).length
         || wave.o({ edge_upsert: 1 }).length) {
            relayout(ms)
        }
    }
    let constraints = {}

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
    function relayout(animMs = 300) {
        lay?.stop()
        const common = {
            animate:                     animMs > 0,
            animationDuration:           animMs,
            nodeDimensionsIncludeLabels: true,
            randomize:                   false,
        }
        let opts: any
        if (layout_name === 'fcose') {
            opts = { name: 'fcose', ...common, nodeSeparation: 30, quality: 'default',
                idealEdgeLength: (e: any) => e.data('ideal_length') ?? 80,
                edgeElasticity:  0.45, nodeRepulsion: () => 4000,
                ...constraints }
        } else if (layout_name === 'cose-bilkent') {
            opts = { name: 'cose-bilkent', ...common, idealEdgeLength: 80, nodeRepulsion: 4500 }
        } else if (layout_name === 'cola') {
            opts = { name: 'cola', ...common, maxSimulationTime: animMs, edgeLength: 80 }
        } else if (layout_name === 'dagre') {
            opts = { name: 'dagre', ...common, rankDir: 'TB', nodeSep: 30, rankSep: 50 }
        } else {
            opts = { name: 'fcose', ...common }
        }
        lay = cy.layout(opts)
        if (animMs > 0) {
            const on_stop = () => {
                cy.removeListener('layoutstop', on_stop)
                cy.fit(cy.nodes(), 16)
                reposition_overlays()
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

        // Reposition overlays on viewport changes (pan/zoom/render)
        cy.on('render', () => reposition_overlays())
        cy.on('pan zoom', () => reposition_overlays())

        // rebuild from scratch on HMR
        H.elvisto('Cyto/Cyto', 'Cyto_wipe', {})
        return () => {
            lay?.stop()
            clear_all_overlays()
            cy?.destroy()
        }
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
    {#if matstyles.length}
        <div class="cytui-matstyles">
            <MatstyleEditor
                {matstyles}
                palette={ms_palette}
                shapes={ms_shapes}
                on_update={(key, prop, value) => {
                    // w:Cyto owns the stylesC reference now (from commission).
                    // Pass both cyto_w and stylesC explicitly to matstyle_update.
                    let cyto_w
                    try { cyto_w = (H as any).Awo('Cyto') } catch { return }
                    const stylesC = cyto_w?.c?.Styles
                    if (!stylesC) return
                    ;(H as any).matstyle_update(cyto_w, stylesC, key, prop, value)
                }}
            />
        </div>
    {/if}
    <div class="cytui-graph-wrap">
        <div class="cytui-graph" bind:this={container}></div>
        <!-- overlay container sits over the cy canvas, pointer-events:none
             so graph interactions pass through. Individual .cm-hole overlays
             opt back in with pointer-events:all for future CodeMirror input. -->
        <div class="cytui-overlays" bind:this={overlay_container}></div>
    </div>
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
.cytui-matstyles {
    padding: 2px 8px; background: #080808;
    border-bottom: 1px solid #141414;
}

/* ── graph + overlay stack ─────────────────────────────────────────────── */
/* The graph and overlay containers are stacked via position:relative/absolute
   so overlays sit exactly over their cy nodes. The overlay container has
   pointer-events:none to let graph interactions (pan/zoom/select) through. */
.cytui-graph-wrap {
    flex: 1; min-height: 0;
    position: relative;
}
.cytui-graph {
    position: absolute;
    inset: 0;
}
.cytui-overlays {
    position: absolute;
    inset: 0;
    pointer-events: none;
    overflow: hidden;
}

/* ── code overlay: positioned <pre> over a text node ───────────────────── */
/* Crisp monospace typography independent of cy zoom. The overlay tracks
   the node's rendered position/size via reposition_overlays(). */
:global(.cyto-overlay) {
    position: absolute;
    pointer-events: none;
    display: flex;
    align-items: center;
    justify-content: center;
    overflow: hidden;
    transition: left 0.15s ease-out, top 0.15s ease-out,
                width 0.15s ease-out, height 0.15s ease-out;
}

:global(.code-overlay) {
    /* text styling matches cy node's monospace font */
    font-family: 'Berkeley Mono','Fira Code',ui-monospace,monospace;
    color: #8b9a7b;
}
:global(.code-overlay pre) {
    margin: 0; padding: 0;
    white-space: pre;
    line-height: 1.4;
    /* inherit font-size from the overlay div (set by reposition_overlays) */
    font-size: inherit;
}
:global(.code-overlay code) {
    font-family: inherit;
    font-size: inherit;
}

/* ── cm-hole: scaffold for future CodeMirror mount ─────────────────────── */
/* pointer-events:all so typing works when a CM is mounted inside.
   The .cm-hole-inner div is the mount point — CM EditorView attaches here. */
:global(.cm-hole) {
    pointer-events: all;
    border: 1px solid #2a3a4a;
    border-radius: 3px;
    background: rgba(10, 15, 20, 0.9);
    cursor: text;
}
:global(.cm-hole-inner) {
    width: 100%; height: 100%;
    overflow: auto;
}
</style>