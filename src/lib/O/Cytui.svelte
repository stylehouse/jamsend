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

    import { onMount, mount, unmount } from 'svelte'
    import cytoscape      from 'cytoscape'
    import fcose       from 'cytoscape-fcose'
    import coseBilkent from 'cytoscape-cose-bilkent'
    import cola        from 'cytoscape-cola'
    import dagre       from 'cytoscape-dagre'

    import type { House } from '$lib/O/Housing.svelte'
    import { _C, objectify, type TheC }  from '$lib/data/Stuff.svelte'
    import { now_in_seconds_with_ms } from '$lib/p2p/Peerily.svelte';
    import MatstyleEditor from './ui/MatstyleEditor.svelte'
    import Stuffing from '$lib/data/Stuffing.svelte'
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

    // Overlay state lives in the //#region overlays block further down
    // (overlays, overlay_bgs, overlay_container, OVERLAY_QUIET_MS, …).

    // H.ave and H.graph are stable TheC; ob() tracks their version for Svelte reactivity.
    $effect(() => {
        const styles_C = H.ave.ob({ Styles: 1 })[0] as TheC | undefined
        matstyles  = styles_C?.o({ matstyle: 1 }) ?? []
        ms_palette = (H as any).MATSTYLE_PALETTE ?? []
        ms_shapes  = (H as any).MATSTYLE_SHAPES ?? []
        if (!styles_C) console.log(`Cyto H:${H.name}.ave:  ${styles_C}`)
    })
    // the graph data channel - %cyto_graph,wave=
    $effect(() => {
        const gn = H.graph.ob({ cyto_graph: 1 })[0] as TheC | undefined
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
    //   The bg color matches the node so the cy-rendered label is covered — otherwise
    //   the label text bleeds through and turns the overlay into scribbles.
    //
    // update_overlay: called on existing overlay — updates text/bg if changed.
    //
    // remove_overlay: called when node is removed — destroys the DOM element.
    //
    // reposition_overlays: called after layout stops and on cy 'render' — moves
    //   each overlay to match its node's rendered position and zoom-adjusted size.
    //
    // ── visibility gating ────────────────────────────────────────────────────
    //
    // Positioning every overlay on every frame is expensive during pan/zoom/drag
    // — browsers struggle to composite dozens of moving divs over a canvas. So:
    //
    //   - On `grab` / `pan` / `zoom` / `layoutstart` we add `.overlays-hidden` to
    //     the container, which instantly invises every overlay via one CSS toggle.
    //   - On `free` / `pan`-quiet / `zoom`-quiet / `layoutstop` we schedule a
    //     re-show via debounced timer — after OVERLAY_QUIET_MS of no movement,
    //     reposition everything and remove the hidden class.
    //
    // The hidden class uses `visibility: hidden` not `display: none` so layout
    // positions don't reflow; also `will-change: transform` is cleared so we
    // don't keep promoting layers needlessly.

    const OVERLAY_QUIET_MS = 120

    let overlays: Map<string, HTMLElement> = new Map()
    // stuff-overlays mount a LIVE Stuffing component into the node's overlay div.
    //  track the mounted instance so we can unmount it when the node leaves the graph.
    let stuff_mounts: Map<string, { app: any, ro?: ResizeObserver }> = new Map()
    // Background color per node id — used when updating so we don't
    // re-read the node style on every tick
    let overlay_bgs: Map<string, string> = new Map()
    // Container div for all overlays — sits over the cy canvas with pointer-events:none
    let overlay_container: HTMLDivElement
    let overlay_quiet_timer: ReturnType<typeof setTimeout> | null = null

    function show_overlays_soon() {
        if (overlay_quiet_timer) clearTimeout(overlay_quiet_timer)
        overlay_quiet_timer = setTimeout(() => {
            overlay_quiet_timer = null
            if (!overlay_container) return
            reposition_overlays()
            motion_hidden = false
            if (voronoi_on) {
                // walls morph to the settled layout (divisions play out); the
                //  Stuffings reveal when the morph lands — they belong to the
                //  NEW cells, not the in-between shapes
                morph_voronoi(() => overlay_container?.classList.remove('overlays-hidden'))
            } else {
                if (vcells.length) clear_voronoi()
                overlay_container.classList.remove('overlays-hidden')
            }
        }, OVERLAY_QUIET_MS)
    }

    function hide_overlays_now() {
        if (!overlay_container) return
        motion_hidden = true
        overlay_container.classList.add('overlays-hidden')
        if (overlay_quiet_timer) { clearTimeout(overlay_quiet_timer); overlay_quiet_timer = null }
    }

    function create_overlay(id: string, str: string, kind: string, bg?: string) {
        if (overlays.has(id)) return update_overlay(id, str, bg)
        if (!overlay_container) return

        const el = document.createElement('div')
        el.className = kind === 'cm-hole' ? 'cyto-overlay cm-hole' : `cyto-overlay ${kind}-overlay`
        el.dataset.nodeId = id

        if (kind === 'cm-hole') {
            // scaffold for future CodeMirror mount
            el.innerHTML = `<div class="cm-hole-inner" data-cm-id="${id}"></div>`
        } else {
            // generic text-bearing overlay: code | annotation
            const pre = document.createElement('pre')
            const code = document.createElement('code')
            code.textContent = str
            pre.appendChild(code)
            el.appendChild(pre)
        }

        if (bg) {
            el.style.backgroundColor = bg
            overlay_bgs.set(id, bg)
        }

        overlay_container.appendChild(el)
        overlays.set(id, el)
    }

    // create_stuff_overlay: a node flagged %stuff (overlay_kind:'stuff') hosts a LIVE Stuffing of its
    //  particle, mounted into the overlay div. source_n is the live particle, ferried on the wave entry's
    //   .c (Cyto.make_wave). House IS the Modus, so a per-node mem (H.imem) keeps each Stuffing's
    //    registration distinct in the refresh climb. H is passed (imperative mount has no Svelte context).
    // stuff_stash_key: a STABLE identity for a chunk's Modusmem, so Stuffing openness
    //  (mem 'openness' → .stashed) survives re-scans and reloads — scan ids don't.  Built from
    //   the particle's mainkey:value plus up to three c.up ancestors' name-ish bits
    //    (DJ/Crowd.outbox ≠ Crowd/DJ.outbox).  Same-key siblings (eg awaitbuf reqs) still
    //     collide — they share one stash and toggle together; acceptable until it isn't.
    function stuff_stash_key(n: TheC): string {
        const bit = (p: any) => {
            const mk = Object.keys(p.sc ?? {})[0] ?? '?'
            const v  = p.sc?.[mk]
            const nm = (v !== 1 && v != null) ? v : (p.sc?.name ?? p.sc?.pub ?? p.sc?.pier ?? p.sc?.id ?? '')
            return nm !== '' ? `${mk}:${nm}` : mk
        }
        const parts: string[] = []
        let p: any = n, d = 0
        while (p && d < 4) { parts.unshift(bit(p)); p = p.c?.up; d++ }
        return parts.join('/')
    }

    function create_stuff_overlay(id: string, source_n: TheC | undefined, bg?: string, self_mode?: boolean) {
        if (!overlay_container || !source_n) return
        if (overlays.has(id)) return   // already mounted — the Stuffing self-refreshes via register_stuffing
        const el = document.createElement('div')
        el.className = 'cyto-overlay stuff-overlay'
        el.dataset.nodeId = id
        // no bg fill — the overlay is transparent; the oval node beneath is the backdrop.
        overlay_container.appendChild(el)
        overlays.set(id, el)
        // seed the zoom-scaled font BEFORE the first measure, else the observer sizes off 16px
        if (cy) el.style.fontSize = `${Math.max(6, 12 * cy.zoom())}px`
        const mem = (H as any).imem('cytostuff:' + stuff_stash_key(source_n))
        const app = mount(Stuffing, { target: el, props: { stuff: source_n, mem, H, self_row: !!self_mode } })
        // grow the node when the Stuffing's rendered size changes — content events only (commits,
        //  zoom font steps), not render frames, so the layout can settle between waves (waitCyto).
        const ro = new ResizeObserver(() => size_stuff_node(id, el))
        ro.observe(el)
        stuff_mounts.set(id, { app, ro })
    }

    // size_stuff_node: the oval stays REASONABLE — it just peeks out the sides of the Stuffing
    //  (a small fixed wing each side) and sits slightly SHORTER than the content, so the Stuffing
    //   reads as the material and the oval as its rim.  Model units (rendered px / zoom).  The
    //    delta gate keeps zoom-driven observer fires (content px ~linear with zoom → model size
    //     ~constant) from writing styles at all.
    function size_stuff_node(id: string, el: HTMLElement) {
        if (!cy) return
        // in voronoi mode the CELL owns the overlay's size (paint_final stretches it),
        //  so growing the node from el size here would feed the cell back into its own
        //   weight — a runaway loop.  Node sizes freeze at their last content-driven
        //    values (still the layout/weight input); content changes just re-tessellate.
        if (voronoi_on) { voronoi_soon(); return }
        const node = cy.getElementById(id)
        if (!node.length) return
        const zoom = cy.zoom()
        const cw = el.offsetWidth, ch = el.offsetHeight
        if (!(zoom > 0) || cw < 5) return
        // re-center on the node too — the overlay grows from its top-left, so a content-size
        //  change (a group toggled open, a zoom font step) skews it off the node until the next
        //   pan/zoom.  This is the content-event twin of reposition_overlays' centering; the
        //    node's center doesn't move when we restyle its size, so current pos is right.
        const pos = node.renderedPosition()
        el.style.left = `${pos.x - cw / 2}px`
        el.style.top  = `${pos.y - ch / 2}px`
        const want_w = Math.round(cw / zoom + 26)
        const want_h = Math.max(18, Math.round((ch / zoom) * 0.92))
        if (Math.abs(node.width() - want_w) > 6 || Math.abs(node.height() - want_h) > 6)
            node.style({ width: want_w, height: want_h })
    }

    function update_overlay(id: string, str: string, bg?: string) {
        const el = overlays.get(id)
        if (!el) return
        const code = el.querySelector('code')
        if (code && code.textContent !== str) code.textContent = str
        if (bg && bg !== overlay_bgs.get(id)) {
            el.style.backgroundColor = bg
            overlay_bgs.set(id, bg)
        }
    }

    function remove_overlay(id: string) {
        const sm = stuff_mounts.get(id)
        if (sm) { sm.ro?.disconnect(); try { unmount(sm.app) } catch (e) {} ; stuff_mounts.delete(id) }
        const el = overlays.get(id)
        if (!el) return
        el.remove()
        overlays.delete(id)
        overlay_bgs.delete(id)
    }

    function reposition_overlays() {
        if (!cy || !overlay_container) return
        const zoom = cy.zoom()

        for (const [id, el] of overlays) {
            const node = cy.getElementById(id)
            if (!node.length) { remove_overlay(id); continue }

            const pos = node.renderedPosition()

            // stuff overlays size THEMSELVES (width/height: max-content) — here we only center
            //  them on the node.  Growing the NODE to wrap the content happens in size_stuff_node,
            //   driven by a ResizeObserver on the overlay (content-change events), NEVER from this
            //    per-frame path — a node.style() write per render frame kept the layout perpetually
            //     energised, so a waitCyto Book never saw the wave settle and wedged between steps.
            if (el.classList.contains('stuff-overlay')) {
                el.style.fontSize = `${Math.max(6, 12 * zoom)}px`
                el.style.display  = zoom < 0.3 ? 'none' : ''
                const cw = el.offsetWidth, ch = el.offsetHeight
                el.style.left = `${pos.x - cw / 2}px`
                el.style.top  = `${pos.y - ch / 2}px`
                continue
            }

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
        for (const [, sm] of stuff_mounts) { sm.ro?.disconnect(); try { unmount(sm.app) } catch (e) {} }
        stuff_mounts.clear()
        for (const [id, el] of overlays) el.remove()
        overlays.clear()
        overlay_bgs.clear()
    }

//#endregion
//#region voronoi

    // ── Voronoi cells render mode ─────────────────────────────────────────────
    //
    //  Cyto stays the LAYOUT engine — fcose decides where the chunks want to
    //  sit — and the render becomes an interpretation of that result: each
    //  stuff-chunk seeds a cell at its node's rendered position, weighted by
    //  node size (a power diagram, so a big chunk claims proportionally more
    //  room), and its Stuffing stretches into the cell.  Adjacency reads as
    //  shared WALLS instead of wires: an SVG layer between the cy canvas and
    //  the HTML overlays draws the cells over a veil that dims the raw graph.
    //
    //  Pure pixels: no cy style writes, no wave or snap involvement, so no
    //  Book can see this mode (Leaf* keep checking Cyto basically works).
    //  It auto-arms when a wave ferries a crusher-stamped particle (c.stuffy —
    //  only the %crushCyto-gated crusher mints those) and the ◈ bar button
    //  overrides either way, remembered in the stash as Cyto_voronoi.
    let voronoi_pref  = $state<boolean | null>(null)   // user override; null = auto
    let saw_stuffy    = $state(false)                  // auto-arm: crushed world present
    const voronoi_on  = $derived(voronoi_pref ?? saw_stuffy)
    let vcells        = $state<{ id: string, d: string, color: string }[]>([])
    let vtips         = $state<{ id: string, x: number, y: number, color: string }[]>([])
    let vregion_w     = $state(0)                      // veil covers only the tessellated region (rack stays bright)
    let motion_hidden = $state(false)                  // cells fade with the overlays during motion
    let voronoi_timer: ReturnType<typeof setTimeout> | null = null

    // ── morph engine ─────────────────────────────────────────────────────────
    //  cells never blink between quiet states — they MORPH: every polygon is
    //  resampled to a fixed point count so any shape tweens to any other by
    //  plain point interpolation.  A newborn cell starts collapsed on its seed
    //  and grows out of the surrounding territory (a division); a dead cell
    //  shrinks to a point (apoptosis) while the survivors' walls slide in.
    const MORPH_MS   = 480
    const RESAMPLE_N = 44
    let shown_pts:   Map<string, {x:number,y:number}[]> = new Map()
    let shown_color: Map<string, string> = new Map()
    let morph_raf = 0

    function voronoi_soon() {
        if (voronoi_timer) clearTimeout(voronoi_timer)
        voronoi_timer = setTimeout(() => { voronoi_timer = null; morph_voronoi() }, 80)
    }

    function toggle_voronoi() {
        voronoi_pref = !voronoi_on
        const st = (H as any).stashed
        if (st) st.Cyto_voronoi = voronoi_pref
        if (voronoi_pref) { reposition_overlays(); morph_voronoi() }
        else clear_voronoi()
    }

    // segment p→q against wall a→b; returns the crossing point or null
    function seg_hit(p: {x:number,y:number}, q: {x:number,y:number},
                     a: {x:number,y:number}, b: {x:number,y:number}) {
        const rx = q.x - p.x, ry = q.y - p.y
        const sx = b.x - a.x, sy = b.y - a.y
        const den = rx * sy - ry * sx
        if (Math.abs(den) < 1e-9) return null
        const t = ((a.x - p.x) * sy - (a.y - p.y) * sx) / den
        const u = ((a.x - p.x) * ry - (a.y - p.y) * rx) / den
        if (t < 0 || t > 1 || u < 0 || u > 1) return null
        return { x: p.x + rx * t, y: p.y + ry * t }
    }

    // Sutherland–Hodgman against one wall: keep the side the seed is on,
    //  ie every p with dot(p − m, dir) <= 0.
    function clip_halfplane(poly: {x:number,y:number}[],
                            m: {x:number,y:number}, dir: {x:number,y:number}) {
        const out: {x:number,y:number}[] = []
        for (let k = 0; k < poly.length; k++) {
            const a = poly[k], b = poly[(k + 1) % poly.length]
            const da = (a.x - m.x) * dir.x + (a.y - m.y) * dir.y
            const db = (b.x - m.x) * dir.x + (b.y - m.y) * dir.y
            if (da <= 0) out.push(a)
            if ((da <= 0) !== (db <= 0)) {
                const t = da / (da - db)
                out.push({ x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t })
            }
        }
        return out
    }

    // one cell's computed geometry — voronoi_layout() makes these, paint_final()
    //  turns them into pixels and morph_voronoi() tweens between generations
    type VCell = {
        id: string, seed: {x:number,y:number}, inset: {x:number,y:number}[],
        acx: number, acy: number, color: string, node: any,
        // the molding affine (symmetric, unit-mean) + the fitted scale
        T11: number, T12: number, T22: number, fit: number,
    }

    // support of the content box under the molding transform, in direction n̂ —
    //  the one formula both the wall-placement and the fit use:
    //   T maps (±w/2, ±h/2); the box's farthest reach along n̂ is
    //   |n̂·T·(w/2,0)| + |n̂·T·(0,h/2)|
    function box_support(nx: number, ny: number, hw: number, hh: number,
                         T11 = 1, T12 = 0, T22 = 1) {
        return Math.abs(nx * T11 + ny * T12) * hw + Math.abs(nx * T12 + ny * T22) * hh
    }

    function voronoi_layout(): { cells: VCell[], seeds: any[], CW: number } | null {
        if (!cy || !container || !voronoi_on) return null
        const W = container.clientWidth, HH = container.clientHeight
        if (!W || !HH) return null

        // seeds = the stuff-chunk nodes in rendered coordinates, each carrying
        //  its content box (the Stuffing's natural size — transforms don't
        //  touch offsetWidth, so this is feedback-free).  For a couple dozen
        //  seeds the O(n²) half-plane intersection is exact and instant.
        const seeds: { id: string, x: number, y: number, hw: number, hh: number, node: any }[] = []
        for (const id of stuff_mounts.keys()) {
            const node = cy.getElementById(id)
            if (!node.length || !node.visible()) continue
            const p = node.renderedPosition()
            const child = overlays.get(id)?.firstElementChild as HTMLElement | null
            const hw = Math.max(24, (child?.offsetWidth  ?? node.renderedWidth())  / 2)
            const hh = Math.max(16, (child?.offsetHeight ?? node.renderedHeight()) / 2)
            seeds.push({ id, x: p.x, y: p.y, hw: Math.min(hw, 260), hh: Math.min(hh, 200), node })
        }
        if (seeds.length < 2) return null

        // ── the rack: haul the un-fitting subset aside ────────────────────────
        //  nodes that aren't sense-making cells (the spine equipment — Piers,
        //  reqs, Opt…) leave the tessellation area for a column pinned at the
        //  right edge: an un-veiled subgraph aside.  Compounds stay put (they
        //  follow their children).  Rendered-coords writes at quiet cadence, so
        //  the rack re-racks after every settle and stays docked through pans.
        const rack = cy.nodes().filter((node: any) =>
            !node.isParent() && !stuff_mounts.has(node.id()))
        rack.sort((a: any, b: any) =>
            String(a.data('label') ?? a.id()).localeCompare(String(b.data('label') ?? b.id())))
        const per_col = Math.max(1, Math.floor((HH - 50) / 34))
        const n_cols  = rack.length ? Math.ceil(rack.length / per_col) : 0
        rack.forEach((node: any, i: number) => {
            const col = Math.floor(i / per_col), row = i % per_col
            node.renderedPosition({ x: W - 65 - col * 72, y: 40 + row * 34 })
        })
        const CW = Math.max(W * 0.55, W - (n_cols ? 130 + (n_cols - 1) * 72 : 0))

        const GAP = 4
        const cells: VCell[] = []
        for (const s of seeds) {
            let poly = [{ x: 0, y: 0 }, { x: CW, y: 0 }, { x: CW, y: HH }, { x: 0, y: HH }]
            for (const o of seeds) {
                if (o === s) continue
                const dx = o.x - s.x, dy = o.y - s.y
                const d = Math.hypot(dx, dy)
                if (d < 1) continue
                // ANISOTROPIC power wall: each seed's radius toward this pair is
                //  its content box's support in the pair direction (tempered) —
                //  wide chunks push their walls out sideways, tall ones push
                //  vertically, so the cell sympathises with its content's shape
                const ux = dx / d, uy = dy / d
                const rs = 12 + 0.5 * box_support(ux, uy, s.hw, s.hh)
                const ro = 12 + 0.5 * box_support(ux, uy, o.hw, o.hh)
                const t  = (d * d + rs * rs - ro * ro) / (2 * d)
                poly = clip_halfplane(poly, { x: s.x + ux * t, y: s.y + uy * t }, { x: ux, y: uy })
                if (poly.length < 3) break
            }
            if (poly.length < 3) continue   // swallowed by a heavier neighbour

            // gutter: pull every vertex a few px toward the (vertex-mean) middle
            //  so shared walls read as gaps rather than double strokes
            const vmx = poly.reduce((a, p) => a + p.x, 0) / poly.length
            const vmy = poly.reduce((a, p) => a + p.y, 0) / poly.length
            const inset = poly.map(p => {
                const dx = p.x - vmx, dy = p.y - vmy, dd = Math.hypot(dx, dy)
                const k = dd > GAP ? 1 - GAP / dd : 0
                return { x: vmx + dx * k, y: vmy + dy * k }
            })

            // ── polygon moments → the molding affine ─────────────────────────
            //  exact area centroid and covariance via the shoelace-extended
            //  second moments; the covariance's eigenframe is the cell's own
            //  shape (long axis φ, elongation √(λ1/λ2)).  The molding T is the
            //  SYMMETRIC unit-area stretch along that frame, blended and capped
            //  ("a little") — it skews/stretches the Stuffing toward the cell's
            //  shape without rotating text upside-down.
            let A2 = 0, sx = 0, sy = 0, sxx = 0, syy = 0, sxy = 0
            for (let i = 0; i < inset.length; i++) {
                const p = inset[i], q = inset[(i + 1) % inset.length]
                const cr = p.x * q.y - q.x * p.y
                A2  += cr
                sx  += (p.x + q.x) * cr
                sy  += (p.y + q.y) * cr
                sxx += (p.x * p.x + p.x * q.x + q.x * q.x) * cr
                syy += (p.y * p.y + p.y * q.y + q.y * q.y) * cr
                sxy += (p.x * q.y + 2 * p.x * p.y + 2 * q.x * q.y + q.x * p.y) * cr
            }
            const A = A2 / 2
            let acx = vmx, acy = vmy, T11 = 1, T12 = 0, T22 = 1
            if (Math.abs(A) > 1) {
                acx = sx / (6 * A); acy = sy / (6 * A)
                const cxx = sxx / (12 * A) - acx * acx
                const cyy = syy / (12 * A) - acy * acy
                const cxy = sxy / (24 * A) - acx * acy
                const mean = (cxx + cyy) / 2
                const dev  = Math.hypot((cxx - cyy) / 2, cxy)
                const l1 = mean + dev, l2 = Math.max(mean - dev, 1e-6)
                const phi = 0.5 * Math.atan2(2 * cxy, cxx - cyy)
                let rho = Math.sqrt(Math.sqrt(l1 / l2))       // eigen ratio of EXTENTS is √(λ1/λ2)
                rho = 1 + (Math.min(rho, 1.8) - 1) * 0.55     // "a little": blend + cap
                const a1 = Math.sqrt(rho), a2i = 1 / Math.sqrt(rho)
                const cs = Math.cos(phi), sn = Math.sin(phi)
                T11 = a1 * cs * cs + a2i * sn * sn
                T22 = a1 * sn * sn + a2i * cs * cs
                T12 = (a1 - a2i) * cs * sn
            }

            // ── maximal fit under the molding ────────────────────────────────
            //  same closed form as the plain fit, with T folded into the
            //  support: for each wall, s·support_T(n̂) ≤ room(centroid→wall)
            let smax = 3.2
            for (let k = 0; k < inset.length; k++) {
                const a = inset[k], b = inset[(k + 1) % inset.length]
                let nx = b.y - a.y, ny = -(b.x - a.x)
                const nl = Math.hypot(nx, ny)
                if (nl < 1e-6) continue
                nx /= nl; ny /= nl
                let room = (a.x - acx) * nx + (a.y - acy) * ny
                if (room < 0) { nx = -nx; ny = -ny; room = -room }
                const denom = box_support(nx, ny, s.hw, s.hh, T11, T12, T22)
                if (denom > 1e-6) smax = Math.min(smax, room / denom)
            }
            const fit = Math.max(0.5, smax * 0.92)

            cells.push({ id: s.id, seed: { x: s.x, y: s.y }, inset, acx, acy,
                color: s.node.style('border-color') as string, node: s.node,
                T11, T12, T22, fit })
        }
        return { cells, seeds, CW }
    }

    const poly_d = (pts: {x:number,y:number}[]) =>
        'M' + pts.map(p => `${p.x.toFixed(1)} ${p.y.toFixed(1)}`).join('L') + 'Z'

    // uniform arc-length resample to N points, so any polygon tweens to any other
    function resample(poly: {x:number,y:number}[], N: number) {
        const at: number[] = []
        let total = 0
        for (let i = 0; i < poly.length; i++) {
            const a = poly[i], b = poly[(i + 1) % poly.length]
            at.push(total); total += Math.hypot(b.x - a.x, b.y - a.y)
        }
        if (total < 1e-6) return Array.from({ length: N }, () => ({ ...poly[0] }))
        const out: {x:number,y:number}[] = []
        let seg = 0
        for (let k = 0; k < N; k++) {
            const want = (k / N) * total
            while (seg < poly.length - 1 && at[seg + 1] <= want) seg++
            const a = poly[seg], b = poly[(seg + 1) % poly.length]
            const len = Math.hypot(b.x - a.x, b.y - a.y) || 1
            const t = (want - at[seg]) / len
            out.push({ x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t })
        }
        return out
    }

    // rotate the sample ring so it pairs with the previous generation minimally —
    //  without this a cell would "spin" to a new start vertex every morph
    function align_ring(pts: {x:number,y:number}[], ref: {x:number,y:number}[]) {
        let best = 0, best_d = Infinity
        for (let r = 0; r < pts.length; r++) {
            let d = 0
            for (let i = 0; i < pts.length; i += 4) {   // stride-4 sample is plenty
                const p = pts[(i + r) % pts.length], q = ref[i]
                d += (p.x - q.x) * (p.x - q.x) + (p.y - q.y) * (p.y - q.y)
            }
            if (d < best_d) { best_d = d; best = r }
        }
        return best ? [...pts.slice(best), ...pts.slice(0, best)] : pts
    }

    // ── paint_final: the vectorised rest state ────────────────────────────────
    //  cell outlines with the edge-braces IN the path (a brace is a notch of
    //  the border itself, cusp-tip pointing into the cell at the crossing —
    //  tightly coupled: it moves, scales and dies with its wall), a tip dot in
    //  the OTHER end's colour, the Stuffing stretched+molded into the cell.
    function paint_final(L: { cells: VCell[], seeds: any[], CW: number }) {
        const crossings = new Map<string, { wall: number, t: number, m: {x:number,y:number}, color: string }[]>()
        const cell_by_id = new Map(L.cells.map(c => [c.id, c]))
        cy.edges().forEach((e: any) => {
            const sid = e.source().id(), tid = e.target().id()
            for (const [own, other] of [[sid, tid], [tid, sid]] as [string, string][]) {
                const c = cell_by_id.get(own)
                if (!c) continue
                const on_node = cy.getElementById(other)
                if (!on_node.length) continue
                const q = on_node.renderedPosition()
                for (let k = 0; k < c.inset.length; k++) {
                    const a = c.inset[k], b = c.inset[(k + 1) % c.inset.length]
                    const h = seg_hit(c.seed, q, a, b)
                    if (!h) continue
                    const wl = Math.hypot(b.x - a.x, b.y - a.y) || 1
                    const t = Math.hypot(h.x - a.x, h.y - a.y) / wl
                    const color = cell_by_id.has(other)
                        ? on_node.style('border-color') as string
                        : on_node.style('background-color') as string
                    const list = crossings.get(own) ?? []
                    list.push({ wall: k, t, m: h, color })
                    crossings.set(own, list)
                    break   // convex + seed inside → one exit wall
                }
            }
        })

        const D = 8
        const P = (px: number, py: number) => `${px.toFixed(1)} ${py.toFixed(1)}`
        const cells: typeof vcells = []
        const tips: typeof vtips = []
        for (const c of L.cells) {
            const cross = (crossings.get(c.id) ?? []).sort((x, y) => x.wall - y.wall || x.t - y.t)
            let d = `M${P(c.inset[0].x, c.inset[0].y)}`
            for (let k = 0; k < c.inset.length; k++) {
                const a = c.inset[k], b = c.inset[(k + 1) % c.inset.length]
                const wlen = Math.hypot(b.x - a.x, b.y - a.y) || 1
                const wv = { x: (b.x - a.x) / wlen, y: (b.y - a.y) / wlen }
                let nx = wv.y, ny = -wv.x
                if ((c.acx - a.x) * nx + (c.acy - a.y) * ny < 0) { nx = -nx; ny = -ny }
                const BL = Math.min(13, wlen * 0.3)
                let along = 0   // distance already consumed on this wall
                if (BL >= 5) for (const cr of cross) {
                    if (cr.wall !== k) continue
                    const at = cr.t * wlen
                    if (at - BL < along + 2 || at + BL > wlen - 2) continue
                    // walk to the notch, then the brace: two cubics leaving the
                    //  wall smoothly and meeting in a cusp at depth D — the
                    //  border itself curls into the cell and back
                    const s1x = cr.m.x - wv.x * BL, s1y = cr.m.y - wv.y * BL
                    const s2x = cr.m.x + wv.x * BL, s2y = cr.m.y + wv.y * BL
                    const tpx = cr.m.x + nx * D,    tpy = cr.m.y + ny * D
                    d += `L${P(s1x, s1y)}`
                       + `C${P(s1x + wv.x * BL * 0.55, s1y + wv.y * BL * 0.55)} `
                       +    `${P(tpx - nx * D * 0.6 - wv.x * BL * 0.05, tpy - ny * D * 0.6 - wv.y * BL * 0.05)} `
                       +    `${P(tpx, tpy)}`
                       + `C${P(tpx - nx * D * 0.6 + wv.x * BL * 0.05, tpy - ny * D * 0.6 + wv.y * BL * 0.05)} `
                       +    `${P(s2x - wv.x * BL * 0.55, s2y - wv.y * BL * 0.55)} `
                       +    `${P(s2x, s2y)}`
                    along = at + BL
                    tips.push({ id: `${c.id}·${k}·${at.toFixed(0)}`,
                        x: cr.m.x + nx * (D + 3), y: cr.m.y + ny * (D + 3), color: cr.color })
                }
                d += `L${P(b.x, b.y)}`
            }
            d += 'Z'
            cells.push({ id: c.id, d, color: c.color })

            // ── the Stuffing, stretched and molded into its cell ─────────────
            const el = overlays.get(c.id)
            if (el) {
                const xs = c.inset.map(p => p.x), ys = c.inset.map(p => p.y)
                const bx = Math.min(...xs), by = Math.min(...ys)
                const bw = Math.max(...xs) - bx, bh = Math.max(...ys) - by
                el.style.left     = `${bx.toFixed(1)}px`
                el.style.top      = `${by.toFixed(1)}px`
                el.style.width    = `${bw.toFixed(1)}px`
                el.style.height   = `${bh.toFixed(1)}px`
                el.style.maxWidth = 'none'
                el.style.clipPath = 'polygon(' + c.inset.map(p =>
                    `${(p.x - bx).toFixed(1)}px ${(p.y - by).toFixed(1)}px`).join(',') + ')'
                const child = el.firstElementChild as HTMLElement | null
                if (child) {
                    const a = (c.fit * c.T11).toFixed(3), b2 = (c.fit * c.T12).toFixed(3)
                    const d2 = (c.fit * c.T22).toFixed(3)
                    const tx = c.acx - (bx + bw / 2), ty = c.acy - (by + bh / 2)
                    child.style.transform = `translate(${tx.toFixed(1)}px, ${ty.toFixed(1)}px)`
                        + ` matrix(${a}, ${b2}, ${b2}, ${d2}, 0, 0)`
                }
            }
        }
        // a seed whose cell got swallowed falls back to plain node-centering
        for (const s of L.seeds) {
            if (cell_by_id.has(s.id)) continue
            const el = overlays.get(s.id)
            if (!el) continue
            el.style.clipPath = ''; el.style.width = ''; el.style.height = ''; el.style.maxWidth = ''
            const inner = el.firstElementChild as HTMLElement | null
            if (inner) inner.style.transform = ''
            el.style.left = `${s.x - el.offsetWidth / 2}px`
            el.style.top  = `${s.y - el.offsetHeight / 2}px`
        }
        vcells = cells
        vtips = tips
    }

    // ── morph_voronoi: tween shown → next generation, then paint the rest state ──
    function morph_voronoi(on_done?: () => void) {
        const L = voronoi_layout()
        if (!L) {
            if (vcells.length || vtips.length) clear_voronoi()
            on_done?.()
            return
        }
        vregion_w = L.CW

        const targets = new Map<string, {x:number,y:number}[]>()
        const starts  = new Map<string, {x:number,y:number}[]>()
        for (const c of L.cells) {
            let pts = resample(c.inset, RESAMPLE_N)
            const prev = shown_pts.get(c.id)
            if (prev && prev.length === RESAMPLE_N) {
                pts = align_ring(pts, prev)
                starts.set(c.id, prev)
            } else {
                // BIRTH: the new cell grows out of its seed point — division
                starts.set(c.id, Array.from({ length: RESAMPLE_N }, () => ({ x: c.seed.x, y: c.seed.y })))
            }
            targets.set(c.id, pts)
            shown_color.set(c.id, c.color)
        }
        // DEATH: a shown cell with no target shrinks to its own middle
        const dying: { id: string, from: {x:number,y:number}[], cx: number, cy: number, color: string }[] = []
        for (const [id, pts] of shown_pts) {
            if (targets.has(id)) continue
            const cx = pts.reduce((a, p) => a + p.x, 0) / pts.length
            const cyy = pts.reduce((a, p) => a + p.y, 0) / pts.length
            dying.push({ id, from: pts, cx, cy: cyy, color: shown_color.get(id) ?? '#888' })
        }

        // nothing moved and nobody was born or died → skip straight to paint
        let still = dying.length === 0
        if (still) for (const c of L.cells) {
            const a = starts.get(c.id)!, b = targets.get(c.id)!
            for (let i = 0; i < RESAMPLE_N; i += 4) {
                if (Math.abs(a[i].x - b[i].x) > 1.5 || Math.abs(a[i].y - b[i].y) > 1.5) { still = false; break }
            }
            if (!still) break
        }
        if (still) { for (const c of L.cells) shown_pts.set(c.id, targets.get(c.id)!); paint_final(L); on_done?.(); return }

        cancelAnimationFrame(morph_raf)
        vtips = []   // tips re-arrive with the settled walls
        const t0 = performance.now()
        const frame = (now: number) => {
            const k = Math.min(1, (now - t0) / MORPH_MS)
            const e = 1 - Math.pow(1 - k, 3)
            const cur: typeof vcells = []
            for (const c of L.cells) {
                const a = starts.get(c.id)!, b = targets.get(c.id)!
                const pts = a.map((p, i) => ({
                    x: p.x + (b[i].x - p.x) * e, y: p.y + (b[i].y - p.y) * e }))
                shown_pts.set(c.id, pts)
                cur.push({ id: c.id, d: poly_d(pts), color: c.color })
            }
            for (const dc of dying) {
                const pts = dc.from.map(p => ({
                    x: p.x + (dc.cx - p.x) * e, y: p.y + (dc.cy - p.y) * e }))
                cur.push({ id: dc.id, d: poly_d(pts), color: dc.color })
            }
            vcells = cur
            if (k < 1) { morph_raf = requestAnimationFrame(frame) }
            else {
                for (const dc of dying) { shown_pts.delete(dc.id); shown_color.delete(dc.id) }
                paint_final(L)
                on_done?.()
            }
        }
        morph_raf = requestAnimationFrame(frame)
    }

    function clear_voronoi() {
        cancelAnimationFrame(morph_raf)
        vcells = []
        vtips = []
        shown_pts.clear()
        shown_color.clear()
        for (const el of overlays.values()) {
            if (!el.classList.contains('stuff-overlay')) continue
            el.style.clipPath = ''; el.style.width = ''; el.style.height = ''; el.style.maxWidth = ''
            const inner = el.firstElementChild as HTMLElement | null
            if (inner) inner.style.transform = ''
        }
        reposition_overlays()
    }

//#endregion
//#region apply

    function apply(wave: TheC, dur: number) {
        if (!cy) return
        rush_animations()
        animations = _C({ animations: 1, started_at: performance.now() / 1000 })
        const ms = Math.round(dur * 1000)
        let length = wave.o({ upsert: 1 }).length

        console.log(`🌊 apply() this wave: upsert x${length}`)
        for (let wa of wave.o()) {
            // console.log(`🌊 piece: ${objectify(wa)}`)
        }

        // Hide overlays while we mutate the graph — freshly-created overlays
        // start at left:0/top:0 and would flash there for a frame before
        // reposition_overlays() moves them.  The global layoutstop handler
        // below will re-show them after positions settle.
        hide_overlays_now()

        if (wave.sc.absolute) {
            console.log(`wave%absolute removes and re-adds the entire graph`)
            cy.elements().remove()
            clear_all_overlays()
            saw_stuffy = false   // a fresh graph re-decides the voronoi auto-arm
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
            // the auto-sizer owns a stuff node's width/height after creation (reposition grows
            //  the oval around the live Stuffing) — a wave re-applying the birth size would snap
            //   the chunk back every tick.
            const nds = nd.sc.style as Record<string,any>
            if (nd.sc.overlay_kind === 'stuff' && el.length && nds) { delete nds.width; delete nds.height }
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
            // overlay_bg matches the node's background so the cy-rendered label
            // underneath is completely hidden — without it the label bleeds
            // through and turns the overlay into scribbles.
            const overlay_str  = nd.sc.overlay_str  as string | undefined
            const overlay_kind = nd.sc.overlay_kind as string | undefined
            const overlay_bg   = nd.sc.overlay_bg   as string | undefined
            if (overlay_kind === 'stuff') {
                const src = (nd as any).c?.source_n as TheC | undefined
                // c.stuffy exists ONLY under the %crushCyto-gated crusher — a crushed
                //  world auto-arms the voronoi render (voronoi_pref still overrides)
                if ((src as any)?.c?.stuffy) saw_stuffy = true
                create_stuff_overlay(id, src, overlay_bg, !!nd.sc.overlay_self)
            } else if (overlay_str != null) {
                create_overlay(id, overlay_str, overlay_kind ?? 'code', overlay_bg)
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
            // if (Object.keys(constraints).length) console.log(`Constraints: `, constraints)
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
        } else {
            // no layout needed — bring overlays back now instead of waiting
            // for a layoutstop that will never fire
            show_overlays_soon()
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
                // overlays are repositioned + unhidden by the global
                // 'layoutstop' handler (show_overlays_soon) — no need to
                // duplicate that work here.
            }
            cy.on('layoutstop', on_stop)
        }
        try { lay.run() } catch (e) { console.warn('layout error', e) }
    }

    // ── cytoscape init ────────────────────────────────────────────────────────
    onMount(() => {
        const stashed_v = (H as any).stashed?.Cyto_voronoi
        if (typeof stashed_v === 'boolean') voronoi_pref = stashed_v
        cy = cytoscape({
            container,
            style: [
                {
                    selector: 'node',
                    style: {
                        label: 'data(label)', 'text-valign': 'center',
                        'text-wrap': 'wrap', 'text-max-width': '72px',
                        'font-size': '9px',
                        'font-family': "Berkeley Mono,Fira Code,monospace",
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

        // ── overlay visibility gating ────────────────────────────────
        // During motion (drag, pan, zoom, layout) we don't try to keep
        // overlays in sync — we hide them entirely via one CSS class
        // toggle on the container. A debounced timer brings them back
        // once the user stops moving things. This makes heavy graphs
        // feel snappy even though we have many positioned DOM elements.
        cy.on('grab',        () => hide_overlays_now())
        cy.on('free',        () => show_overlays_soon())
        cy.on('pan zoom',    () => { hide_overlays_now(); show_overlays_soon() })
        cy.on('layoutstart', () => hide_overlays_now())
        cy.on('layoutstop',  () => show_overlays_soon())
        // ── click-to-identify ─────────────────────────────────────────────────
        // Tap any node or edge to log its id / parent / data / style. Useful for
        // finding mystery greys (which are usually n particles falling through
        // cytyle_classify to the matstyle palette default) and for confirming
        // what a given cytoid corresponds to in C**.
        // < I guess ideally we would click on the syntax node that's wrong, then be able to probe when|where in the process (which we can replay deterministically) it began, what has happened in regards to resolving it and its neighbours...
        cy.on('tap', 'node', (evt) => {
            const n = evt.target
            const d = n.data()
            console.log(
                `🔎 node ${n.id()} parent:${n.parent().id() || '(root)'} label:${JSON.stringify(d.label ?? '')}`,
                { data: d, bg: n.style('background-color') }
            )
        })
        cy.on('tap', 'edge', (evt) => {
            const e = evt.target
            console.log(
                `🔎 edge ${e.id()} ${e.source().id()} → ${e.target().id()} label:${JSON.stringify(e.data('label') ?? '')}`,
                e.data()
            )
        })

        // rebuild from scratch on HMR
        H.i_elvisto('Cyto/Cyto', 'Cyto_wipe', {})
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
        <button class="v-toggle" class:on={voronoi_on} onclick={toggle_voronoi}
            title="voronoi cells — Cyto lays out, cells render">◈</button>
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
        <!-- voronoi layer between the canvas and the HTML overlays: the veil dims
             the raw graph so the cells (and the Stuffings stretched into them)
             carry the reading; it hides with the overlays during motion. -->
        <svg class="cytui-voronoi" style:opacity={motion_hidden ? 0 : 1}>
            {#if voronoi_on && vcells.length}
                <rect class="cytui-veil" width={vregion_w || '100%'} height="100%" />
                {#each vcells as cell (cell.id)}
                    <path d={cell.d}
                        fill={cell.color} fill-opacity="0.13"
                        stroke={cell.color} stroke-opacity="0.6" stroke-width="1.5"
                        stroke-linejoin="round" />
                {/each}
                {#each vtips as tip (tip.id)}
                    <circle cx={tip.x} cy={tip.y} r="2.4"
                        fill={tip.color} fill-opacity="0.95" />
                {/each}
            {/if}
        </svg>
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
.cytui-voronoi {
    position: absolute;
    inset: 0;
    width: 100%; height: 100%;
    pointer-events: none;
    transition: opacity 0.25s ease;
}
.cytui-voronoi .cytui-veil {
    fill: #070707;
    opacity: 0.5;
}
.cytui-bar button.v-toggle.on {
    color: #7ab0d4;
    border-color: #2a3a4a;
}
.cytui-overlays {
    position: absolute;
    inset: 0;
    pointer-events: none;
    overflow: hidden;
}

/* overlays-hidden: set during drag/pan/zoom/layout so we don't repaint
   dozens of positioned divs every frame. Toggled as one class on the
   container rather than touching each overlay's style.  visibility:
   hidden keeps position/layout stable so nothing reflows. */
:global(.cytui-overlays.overlays-hidden .cyto-overlay) {
    visibility: hidden;
}

/* ── code overlay: positioned box over a text node ─────────────────────── */
/* Crisp monospace typography independent of cy zoom. The overlay tracks
   the node's rendered position/size via reposition_overlays().
   Background color is set at create-time to match the node's bg, so the
   cy-rendered label underneath is completely hidden. */
:global(.cyto-overlay) {
    position: absolute;
    pointer-events: none;
    display: flex;
    align-items: center;
    justify-content: center;
    overflow: hidden;
    border-radius: 4px;
}

:global(.code-overlay) {
    /* text styling matches cy node's monospace font */
    font-family: 'Berkeley Mono','Fira Code',ui-monospace,monospace;
    color: #8b9a7b;
}
:global(.code-overlay pre) {
    margin: 0; padding: 0 4px;
    white-space: pre;
    line-height: 1.4;
    /* inherit font-size from the overlay div (set by reposition_overlays) */
    font-size: inherit;
}
:global(.code-overlay code) {
    font-family: inherit;
    font-size: inherit;
}

/* ── annotation overlay: syntax name + short string for node:Name ──────── */
/* Same idea as code-overlay but tuned for tiny boxes hovering above text. */
:global(.annotation-overlay) {
    font-family: 'Berkeley Mono','Fira Code',ui-monospace,monospace;
    color: inherit;
}
:global(.annotation-overlay pre) {
    margin: 0; padding: 0 3px;
    white-space: pre-wrap;
    line-height: 1.2;
    font-size: calc(1em * 0.75);  /* smaller than code overlays */
    text-align: center;
}
:global(.annotation-overlay code) {
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

/* ── stuff overlay: a live Stuffing component mounted inside a %stuff node ── */
/* pointer-events:none — the OVAL NODE beneath takes clicks and drags (pointer-events:all
   made the chunk undraggable). Transparent + scrollbarless: the overlay sizes to its
   content (max-content — reposition_overlays does NOT force width/height on it; it grows
   the NODE to wrap us instead), and the oval provides the backdrop + Matstyle border. */
:global(.stuff-overlay) {
    pointer-events: none;
    overflow: hidden;
    background: transparent;
    width: max-content;
    height: max-content;
    max-width: 520px;
}
/* the mounted Stuffing must keep its NATURAL size even when the voronoi mode
   pins the overlay to a cell bbox (flex would shrink it to the container and
   spoil the maximal-fit measure — offsetWidth has to stay the content size). */
:global(.stuff-overlay > *) {
    flex: none;
}
/* cap the chunk's content at a portrait-ish width so a wide crush wraps into a
   taller block that molds into a cell far better than a long thin strip — the
   overlay is width:max-content, so the 18em ceiling here pulls the whole oval
   in with it.  (Found by eye on the live tab; ~288px.) */
:global(.stuff-overlay > .stuffing > .content) {
    max-width: 18em;
}
/* the outer Stuffing keeps its SOLID background (visual clarity — the rows must not blend
   into edges and nodes behind the chunk); only its border goes, so the chunk's chrome is the
   oval's Matstyle rim alone.  !important outguns the component-scoped .stuffing rule;
   nested Stuffings keep theirs. */
:global(.stuff-overlay > .stuffing) {
    border: none !important;
}
/* the Stuffing's toggles stay CLICKABLE (expand bits; openness persists via Modusmem stash) while
   everything else passes through to the oval for dragging — buttons are the interaction surface. */
:global(.stuff-overlay button) {
    pointer-events: auto;
}
</style>