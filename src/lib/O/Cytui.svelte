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
    import Vexpandy from '$lib/O/ui/Vexpandy.svelte'
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
    // the reveal is a LATCH, not a per-morph callback: a morph in flight can be
    //  superseded (a ResizeObserver re-fires as a Stuffing re-renders after zoom,
    //   calling morph_voronoi() with no callback), which used to drop the pending
    //    reveal — the Stuffings then stayed hidden until a drag re-armed it.  Any
    //     morph that reaches its settled paint clears this latch, so whoever lands
    //      last does the reveal.
    let overlays_want_show = false
    function settle_overlay_show() {
        if (overlays_want_show && overlay_container) {
            overlay_container.classList.remove('overlays-hidden')
            overlays_want_show = false
        }
    }

    // ── adaptive drag rendering ───────────────────────────────────────────────
    //  the cheap path hides EVERY overlay the instant a drag starts.  But a
    //   capable machine can keep them live for the whole drag — so instead of
    //    hiding on grab, we keep them rendered and repaint each frame, MEASURING
    //     the repaint cost.  If a frame blows the budget the machine can't keep
    //      up, so we shed to the hide-all path for the rest of this drag (re-probed
    //       fresh on the next grab — no permanent lock-out, it self-heals if the
    //        graph shrinks or the box speeds up).  This is the "monitor performance
    //         at high|low visual quality" the graph asked for, per-drag.
    let dragging = false
    let live_layout = false        // the wave/relayout animation drives the same live-repaint loop
    let live_motion = false        // a pan / scroll-to-zoom gesture drives it too, self-stopping on quiet
    let drag_raf = 0
    let repos_cost_ema = 0
    const KEEP_BUDGET_MS = 9        // per-frame repaint budget before we shed quality

    function start_live_drag() {
        dragging = true
        repos_cost_ema = 0          // re-probe this machine fresh each drag
        motion_hidden = false
        overlays_want_show = false  // we're showing live, not via the settle latch
        overlay_container?.classList.remove('overlays-hidden')
        cancelAnimationFrame(morph_raf)   // a settle-morph must not fight the drag
        cancelAnimationFrame(drag_raf)
        drag_raf = requestAnimationFrame(drag_frame)
    }

    function drag_frame() {
        if ((!dragging && !live_layout && !live_motion) || !overlay_container) return
        const t0 = performance.now()
        if (voronoi_on) voronoi_paint_now()   // cells + clipped Stuffings track live
        else reposition_overlays()
        const cost = performance.now() - t0
        repos_cost_ema = repos_cost_ema ? repos_cost_ema * 0.8 + cost * 0.2 : cost
        if (repos_cost_ema > KEEP_BUDGET_MS) {
            // can't keep up — fall back to the cheap hide-all for the rest of this motion
            console.log(`🎚️ motion quality: shed to hide-all (repaint ${repos_cost_ema.toFixed(1)}ms > ${KEEP_BUDGET_MS}ms)`)
            dragging = false; live_layout = false; live_motion = false
            hide_overlays_now()
            return
        }
        drag_raf = requestAnimationFrame(drag_frame)
    }

    function end_live_drag() {
        if (dragging) { dragging = false; cancelAnimationFrame(drag_raf) }
        show_overlays_soon()
    }

    // the wave/relayout is ALSO motion — keep the overlays (and the voronoi cells with
    //  their clipped Stuffings) LIVE and tracking through the whole animation instead of
    //   hiding them until it settles.  Reuses the drag_frame budget self-heal: the owner
    //    runs software graphics and confirmed per-frame repaint keeps up; if a frame ever
    //     blows budget it sheds to hide-all for the rest of that layout, same as a drag.
    function paint_overlays_now() {
        if (voronoi_on) voronoi_paint_now(); else reposition_overlays()
    }
    function start_live_layout() {
        if (dragging || live_layout) return   // a manual drag already owns the live loop
        paint_overlays_now()          // seat everyone (incl. freshly-created overlays) BEFORE revealing — no 0,0 flash
        live_layout = true
        repos_cost_ema = 0            // re-probe the machine fresh each layout
        motion_hidden = false
        overlays_want_show = false    // we're showing live, not via the settle latch
        overlay_container?.classList.remove('overlays-hidden')
        cancelAnimationFrame(morph_raf)   // a settle-morph must not fight the live layout
        cancelAnimationFrame(drag_raf)
        drag_raf = requestAnimationFrame(drag_frame)
    }
    function stop_live_layout() {
        live_layout = false
        if (!dragging) cancelAnimationFrame(drag_raf)
    }

    // A pan or a scroll-to-zoom is motion too — keep the Stuffing overlays (and
    //  the voronoi cells with their clipped Stuffings) LIVE and tracking through
    //   the whole gesture, exactly like a drag or a layout wave, instead of
    //    blanking them until the wheel rests.  A wheel-zoom fires a BURST of
    //     'zoom' events with no natural stop (unlike layoutstop): the first arms
    //      the shared live loop, every event pushes the quiet-timer out, and
    //       OVERLAY_QUIET_MS after the last one we stop the loop and let
    //        show_overlays_soon settle the final positions.  Same per-frame budget
    //         self-heal as the drag — a machine that can't repaint in time sheds
    //          to hide-all for the rest of the gesture.
    let motion_quiet_timer: ReturnType<typeof setTimeout> | null = null
    function pan_zoom_motion() {
        if (dragging || live_layout) return   // a drag / layout already owns the live loop
        if (!live_motion) {
            paint_overlays_now()      // seat everyone at current positions BEFORE revealing — no flash
            live_motion = true
            repos_cost_ema = 0        // re-probe the machine fresh for this gesture
            motion_hidden = false
            overlays_want_show = false
            overlay_container?.classList.remove('overlays-hidden')
            cancelAnimationFrame(morph_raf)
            cancelAnimationFrame(drag_raf)
            drag_raf = requestAnimationFrame(drag_frame)
        }
        if (motion_quiet_timer) clearTimeout(motion_quiet_timer)
        motion_quiet_timer = setTimeout(() => {
            motion_quiet_timer = null
            live_motion = false
            if (!dragging && !live_layout) cancelAnimationFrame(drag_raf)
            show_overlays_soon()
        }, OVERLAY_QUIET_MS)
    }

    // repaint the voronoi at the CURRENT positions with no tween — the live-drag
    //  twin of morph_voronoi's settled paint (used per frame while a node is dragged)
    function voronoi_paint_now() {
        const L = voronoi_layout()
        if (!L) { if (vcells.length || vtips.length) clear_voronoi(); return }
        vregion_w = L.CW
        for (const c of L.cells) shown_pts.set(c.id, resample(c.inset, RESAMPLE_N))
        paint_final(L)   // live cadence — vtuffing rows track too (cached tree + chord math)
    }

    function show_overlays_soon() {
        if (overlay_quiet_timer) clearTimeout(overlay_quiet_timer)
        overlay_quiet_timer = setTimeout(() => {
            overlay_quiet_timer = null
            if (!overlay_container) return
            reposition_overlays()
            motion_hidden = false
            if (voronoi_on) {
                // walls morph to the settled layout (divisions play out); the
                //  Stuffings reveal when the morph lands (via the latch) — they
                //  belong to the NEW cells, not the in-between shapes
                overlays_want_show = true
                morph_voronoi()
            } else {
                if (vcells.length) clear_voronoi()
                overlay_container.classList.remove('overlays-hidden')
            }
        }, OVERLAY_QUIET_MS)
    }

    function hide_overlays_now() {
        if (!overlay_container) return
        motion_hidden = true
        overlays_want_show = false   // a fresh hide cancels any pending reveal
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

    // ── gang mirrors ─────────────────────────────────────────────────────────
    //  a gang REPRESENTATIVE (the Voro crusher's elected leaf, carrying its
    //   scattered same-mainkey siblings on c.gang) has no children of its own —
    //    so the Stuffing it hosts shows a MIRROR container instead: a free
    //     particle (never reachable from H**, so never snapped) whose children
    //      are sc-copies of the live members.  Rebuilt in place when the gang's
    //       size changes (the mounted Stuffing keeps its ref; rows refresh at
    //        the normal register_stuffing cadence).  Membership swaps at equal
    //         count can lag one beat — acceptable for assertion confetti.
    const gang_mirrors = new Map<string, { mirror: TheC, n: number }>()
    function gang_stuff(id: string, src: TheC): TheC {
        const members = (src as any).c?.gang as TheC[] | undefined
        if (!members?.length) return src
        const got = gang_mirrors.get(id)
        if (got && got.n === members.length) return got.mirror
        const mirror = got?.mirror ?? _C({ gang_of: Object.keys(src.sc ?? {})[0] ?? 'gang' })
        for (const ch of mirror.o()) ch.drop(ch)
        for (const m of members) {
            const sc: any = {}
            for (const [k, v] of Object.entries(m.sc ?? {}))
                if (typeof v !== 'object' && typeof v !== 'function') sc[k] = v
            mirror.i(sc)
        }
        gang_mirrors.set(id, { mirror, n: members.length })
        return mirror
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
        const app = mount(Stuffing, { target: el, props: { stuff: gang_stuff(id, source_n), mem, H, self_row: !!self_mode } })
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
        gang_mirrors.delete(id)
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
                // a cell-molded Stuffing (clipPath = its cell) is paint_final's to move —
                //  node-centering it here is the visible jump-to-the-node-and-back between
                //   a gesture settling and the morph re-molding it.  Leave it seated in its
                //    cell; clear_voronoi strips the clipPath before it repositions, and the
                //     swallowed-cell fallback clears its own, so an unmolded Stuffing still
                //      centers normally below.
                if (el.style.clipPath) continue
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
    //  only the Voro crusher mints those, Ghost/V/Voro.g) and the ◈ bar button
    //  overrides either way, remembered in the stash as Cyto_voronoi.  On a
    //  world whose Book never crushed, ◈ goes further and IMPOSES the crush
    //  (Cyto_crush → the crusher runs before each scan, all c-side) — the
    //  luxury layer lands on any graph and the Story underneath never knows.
    let voronoi_pref  = $state<boolean | null>(null)   // user override; null = auto
    let saw_stuffy    = $state(false)                  // auto-arm: crushed world present
    // Vexpandy: 50vh → 100vh (twice the height).  Pure pixels like voronoi_pref,
    //  and remembered the same way — in the stash as Cyto_tall — so the taller
    //   frame survives a re-scan and a reload (the height is a workspace choice,
    //    not per-graph state).
    let tall          = $state(!!(H as any).stashed?.Cyto_tall)
    // re-fit the graph after the height toggles so the frame fills the new box
    //  — skip the initial settle, only re-fit on an actual user toggle.
    let tall_settled = false
    $effect(() => {
        const st = (H as any).stashed
        if (st) st.Cyto_tall = tall
        if (!tall_settled) { tall_settled = true; return }
        requestAnimationFrame(() => { cy?.resize(); cy?.fit(cy.nodes(), 16) })
    })
    const voronoi_on  = $derived(voronoi_pref ?? saw_stuffy)
    // ── properCellable ────────────────────────────────────────────────────────
    //  a wordy loner particle — a %see claim above all, one long sentence on a
    //   24px oval — is unreadable as a bare node (it used to land in the rack;
    //    the rack is shelved, so now it just sits there, still unreadable).
    //  properCellable mounts each one a self-row Stuffing exactly like a
    //   crushed chunk gets — and thereby a voronoi CELL too, since any
    //    stuff-mount seeds the tessellation.  Entirely render-side off the
    //     node's source_n (which now rides EVERY wave upsert on .c): the wave
    //      carries no overlay_kind for these, so no snap can tell.
    //  A workspace pref (stash Cyto_properCellable, metaphysics §4); default
    //   follows the voronoi mode — glass wants every pane readable, the plain
    //    graph stays lean.  proper_mounted tracks OUR mounts so toggling off
    //     never strips a wave-owned (crusher) Stuffing.
    const PROPER_KINDS  = new Set(['see'])
    let proper_pref     = $state<boolean | null>(null)   // user override; null = follow voronoi
    const proper_on     = $derived(proper_pref ?? voronoi_on)
    const proper_mounted = new Set<string>()
    // node_src: every upserted node's live particle — lets a toggle flip
    //  re-classify EXISTING nodes without waiting for a wave
    const node_src = new Map<string, TheC>()
    const is_proper = (n: TheC | undefined) =>
        !!n && PROPER_KINDS.has(Object.keys(n.sc ?? {})[0] ?? '')
    function proper_sync() {
        if (!cy) return
        for (const [id, src] of node_src) {
            if (!is_proper(src)) continue
            const node = cy.getElementById(id)
            if (!node.length) continue
            if (proper_on && !overlays.has(id)) {
                create_stuff_overlay(id, src, undefined, true)
                proper_mounted.add(id)
                node.style('label', '')    // the Stuffing IS the words — the cy label would bleed through
            } else if (!proper_on && proper_mounted.has(id)) {
                remove_overlay(id)
                proper_mounted.delete(id)
                try { node.removeStyle('label') } catch {}
            }
        }
        reposition_overlays()
        if (voronoi_on) voronoi_soon()
    }
    function toggle_proper() {
        proper_pref = !proper_on
        const stp = (H as any).stashed
        if (stp) stp.Cyto_properCellable = proper_pref
        proper_sync()
    }
    // ── family hulls (Cyto_families) ─────────────────────────────────────────
    //  one faint shared outline per house: the cells of one compound family
    //   (Pier/**, an Artist's tracks…) get their union boundary stroked as a
    //    second, well-back line.  Pure pixels at settle cadence; stash pref.
    let families_pref   = $state<boolean | null>(null)
    const families_on   = $derived(families_pref ?? true)
    let vfams           = $state<{ id: string, d: string, color: string }[]>([])
    const FAM_COLORS    = ['#8b6bb7', '#5b9a77', '#b78a5b', '#5b8ab7', '#b75b7a', '#7ab75b']
    function toggle_families() {
        families_pref = !families_on
        const stf = (H as any).stashed
        if (stf) stf.Cyto_families = families_pref
        if (!families_on) vfams = []
        else voronoi_soon()
    }
    // ── the scroll visor ──────────────────────────────────────────────────────
    //  A strip over the right edge where the wheel scrolls the PAGE instead of
    //   zooming the graph — a hand-free gutter past a graph that would otherwise
    //    eat the wheel.  The visor element itself is pure pixels now
    //     (pointer-events:none): it only LIGHTS while the gutter is doing its
    //      job, then fades to nothing.  The actual stealing happens in
    //       visor_guard below, capture-phase on the wrap — so clicks and drags
    //        in the strip land on whatever is beneath; a cell there stays fully
    //         handleable, nothing is untouchable glass any more.
    let visor_lit     = $state(false)
    let visor_timer: ReturnType<typeof setTimeout> | null = null
    // a fixed fifth of the wrap: wide enough to catch a natural scroll gesture,
    //  and costless to the cells beneath now that only the wheel is claimed
    const VISOR_FRAC  = 0.2
    function visor_light() {
        visor_lit = true
        if (visor_timer) clearTimeout(visor_timer)
        visor_timer = setTimeout(() => { visor_lit = false }, 140)
    }
    // capture-phase wheel guard on the wrap: inside the strip, stopPropagation
    //  keeps the event from ever reaching cy's canvas (capture on the ancestor
    //   beats cy's own container listener), so cy can't zoom — and NO
    //    preventDefault, because the browser's default page scroll is exactly
    //     the point.  Stand-down: when the page has nowhere to scroll (a
    //      full-bleed toplevel like BigSoundland — the graph IS the page),
    //       stealing the wheel would serve nobody, so the strip lets cy zoom.
    //        The page's own shape is the switch; no prop, no mode.
    function visor_guard(e: WheelEvent) {
        const r = (e.currentTarget as HTMLElement).getBoundingClientRect()
        if (e.clientX >= r.right - r.width * VISOR_FRAC) {
            const doc = document.scrollingElement ?? document.documentElement
            if (doc.scrollHeight > doc.clientHeight) {
                e.stopPropagation()
                visor_light()
                return
            }
        }
        // 🌀 the gravity brush takes what reaches the graph (the visor stole its
        //  strip first, as ever): plain wheel sculpts the locale; Ctrl/Cmd+wheel
        //   passes through untouched so the camera zoom stays reachable.
        if (brush_pref && !e.ctrlKey && !e.metaKey) {
            e.preventDefault()
            e.stopPropagation()
            brush_wheel(e)
        }
    }
    // ── the gravity brush (task 7, Voro_pinch.md) ─────────────────────────────
    //  a toggleable mode where the wheel does not zoom the camera but sculpts
    //   THAT LOCALE: wheel-toward pulls the neighbourhood under the cursor
    //    together, wheel-away spreads it.  MODEL-position writes through cy —
    //     layout-side input exactly like a user drag (metaphysics §1 allows
    //      it) — gated off running layouts, and every burst rides
    //       pan_zoom_motion so the live loop re-tessellates per frame and the
    //        settle repaints at quiet.  fcose's next wave UNDOES the sculpt:
    //         a hand-gesture on the rest state, fine for a play-mode.
    let brush_pref = $state(false)
    function toggle_brush() {
        brush_pref = !brush_pref
        const stb = (H as any).stashed
        if (stb) stb.Cyto_gravity_brush = brush_pref
    }
    function brush_wheel(e: WheelEvent) {
        if (!cy || live_layout) return          // a running layout owns positions
        const rect = container.getBoundingClientRect()
        const rx = e.clientX - rect.left, ry = e.clientY - rect.top
        const zoom = cy.zoom(), pan = cy.pan()
        const cmx = (rx - pan.x) / zoom, cmy = (ry - pan.y) / zoom
        // gaussian falloff in RENDERED px (about one cell); the move itself is in
        //  MODEL coords so the sculpt strength doesn't depend on zoom level
        const SIG = 140
        const k = (e.deltaY > 0 ? -0.06 : 0.06)
            * Math.min(2, Math.max(0.2, Math.abs(e.deltaY) / 100))
        const M = 40   // soft frame clamp: a spread can't fling slivers off-screen
        cy.startBatch()
        cy.nodes().forEach((node: any) => {
            if (node.isParent() || is_nucleus(node)) return
            const rp = node.renderedPosition()
            const d = Math.hypot(rp.x - rx, rp.y - ry)
            const wgt = Math.exp(-(d * d) / (2 * SIG * SIG))
            if (wgt < 0.05) return
            const p = node.position()
            let nx2 = p.x + (p.x - cmx) * k * wgt
            let ny2 = p.y + (p.y - cmy) * k * wgt
            const rxn = nx2 * zoom + pan.x, ryn = ny2 * zoom + pan.y
            const cxn = Math.max(M, Math.min(rect.width - M, rxn))
            const cyn = Math.max(M, Math.min(rect.height - M, ryn))
            if (cxn !== rxn || cyn !== ryn) { nx2 = (cxn - pan.x) / zoom; ny2 = (cyn - pan.y) / zoom }
            node.position({ x: nx2, y: ny2 })
        })
        cy.endBatch()
        pan_zoom_motion()   // the brush is just another motion
    }
    let vcells        = $state<{ id: string, d: string, color: string, swapped?: boolean }[]>([])
    let vtips         = $state<{ id: string, x: number, y: number, color: string }[]>([])
    // ── the microcosm (task 6a/6b, Voro_microcosm.md) ─────────────────────────
    //  a big-enough cell swaps its molded Stuffing for its fold's MEMBERS laid
    //   out as a mini grid of row-cards in the cell's own frame — "just
    //    crunching on subsets": no second graph machine, the members are one
    //     fold.o() (or c.gang) away from the live particle we already hold.
    //  Settle-only (the live painter never pays for it), char-estimate card
    //   sizes (no DOM measure — metaphysics §6), clipped to the cell polygon.
    // ── vtuffing: what a big pane SAYS (rows from Voro.g's Vtuff_build, fitted to the cell) ──
    //  The engine distils a fold|gang's members into a layout C** (title | shared facts |
    //   spreads-with-chips | member rows | the /*N dip); here we normalise that tree to plain
    //    row descriptors and CHORD-FIT them into the convex cell polygon — text follows the
    //     slanted walls instead of a bbox grid.  Runs in BOTH cadences (the tree is cached
    //      .g-side, the fit is pure math) so the rows persist through a drag.  ▤ toggles the
    //       whole swap; member|dip rows are the pop-out surf (Vtuff_pop).
    type MicroChip = { text: string, n: number, member?: TheC, sub?: number }
    type MicroRow  = { text: string, kind: string, x: number, y: number, w: number, h: number, fs: number,
                       color: string | null, tag?: string, sub?: number,
                       chips?: MicroChip[], member?: TheC, dip?: boolean }
    type VtuffDesc = { text: string, kind: string, color?: string | null, tag?: string, sub?: number,
                       chips?: MicroChip[], member?: TheC, dip?: boolean }
    let vmicro       = $state<{ id: string, x: number, y: number, w: number, h: number, clip: string, rows: MicroRow[] }[]>([])
    let micro_on_ids = new Set<string>()   // hysteresis memory: which cells are swapped in
    let vtuffing_pref = $state<boolean | null>(null)
    const vtuffing_on = $derived(vtuffing_pref ?? true)
    function toggle_vtuffing() {
        vtuffing_pref = !vtuffing_on
        const stv = (H as any).stashed
        if (stv) stv.Cyto_vtuffing = vtuffing_pref
        if (!vtuffing_on) {
            for (const id of micro_on_ids) { const mel = overlays.get(id); if (mel) mel.style.opacity = '' }
            micro_on_ids = new Set(); vmicro = []
        } else voronoi_soon()
    }

    // one short identity line — the TS twin of Voro.g's Vtuff_ident, for the fallback
    //  rows an OLD gen serves until the tab reload deposits Vtuff_build.
    function ident_ts(m: any): string {
        const mk = Object.keys(m?.sc ?? {})[0] ?? '?'
        const v = m?.sc?.[mk]
        let t = (v === 1 || v == null) ? mk : `${mk}: ${v}`
        for (const k of ['name', 'title', 'text', 'nick', 'label'])
            if (k !== mk && typeof m?.sc?.[k] === 'string') { t += ` · ${m.sc[k]}`; break }
        return t
    }

    // rows for a pane: the Vtuffing tree normalised to descriptors — or, before the new gen
    //  boots, a plain fallback (title + member idents + dip) so panes never say just "Track".
    function vtuff_rows(src: any): VtuffDesc[] {
        const build = (H as any).Vtuff_build
        if (build) {
            const root = build.call(H, src)
            if (!root) return []
            const out: VtuffDesc[] = []
            for (const r of root.o() as any[]) {
                const kind = (r.sc.row as string) ?? 'fact'
                const d: VtuffDesc = { text: String(r.sc.text ?? ''), kind }
                if (r.sc.tag) d.tag = String(r.sc.tag)
                if (r.sc.sub) d.sub = r.sc.sub as number
                if (r.c.member) { d.member = r.c.member; d.color = kind_tint(Object.keys(r.c.member.sc ?? {})[0]) }
                if (kind === 'title') d.color = kind_tint(d.tag ?? src?.c?.fold_kind)
                if (kind === 'dip') d.dip = true
                const bits = r.o() as any[]
                if (bits.length) d.chips = bits.map((b: any) => ({ text: String(b.sc.text ?? ''), n: (b.sc.n as number) ?? 0, member: b.c.member, sub: b.sc.sub as number | undefined }))
                out.push(d)
            }
            return out
        }
        const members: any[] | null = src?.c?.gang ?? (src?.c?.stuff && typeof src.o === 'function' ? src.o() : null)
        if (!members?.length) return []
        // name|tag split, the TS twin of Vtuff_name (fallback until the gen boots)
        const name_ts = (m: any): string => {
            const mk = Object.keys(m?.sc ?? {})[0]
            const v = m?.sc?.[mk]
            if (v !== 1 && v != null) return String(v)
            for (const k of ['name', 'title', 'text', 'nick', 'label'])
                if (k !== mk && typeof m?.sc?.[k] === 'string') return m.sc[k]
            return ''
        }
        const t_tag = src?.c?.gang ? (src?.c?.fold_kind as string) : Object.keys(src?.sc ?? {})[0]
        const t_name = src?.c?.gang ? '' : name_ts(src)
        const out: VtuffDesc[] = [{ text: `${t_name ? t_name + '  ' : ''}×${members.length}`,
                                    kind: 'title', tag: t_tag, color: kind_tint(t_tag) }]
        const CAP = 8
        for (const m of members.slice(0, CAP)) {
            const sub = typeof m.o === 'function' ? m.o().length : 0
            const mk = Object.keys(m.sc ?? {})[0]
            const nm = name_ts(m)
            out.push({ text: nm || mk, kind: 'member', member: m, tag: nm ? mk : undefined,
                       sub: sub || undefined, color: kind_tint(mk) })
        }
        if (members.length > CAP) out.push({ text: `+${members.length - CAP} more`, kind: 'fact' })
        out.push({ text: `/*${members.length}`, kind: 'dip', dip: true })
        return out
    }

    // the widest horizontal chord of a CONVEX polygon at height y (the cells are half-plane
    //  intersections, so one interval always) — the whole fit leans on this.
    function poly_chord(poly: {x:number,y:number}[], y: number): [number, number] | null {
        let x0 = Infinity, x1 = -Infinity, hit = false
        for (let i = 0; i < poly.length; i++) {
            const a = poly[i], b = poly[(i + 1) % poly.length]
            if ((a.y - y) * (b.y - y) > 0) continue
            const dy = b.y - a.y
            if (Math.abs(dy) < 1e-6) { x0 = Math.min(x0, a.x, b.x); x1 = Math.max(x1, a.x, b.x) }
            else {
                const x = a.x + (b.x - a.x) * (y - a.y) / dy
                x0 = Math.min(x0, x); x1 = Math.max(x1, x)
            }
            hit = true
        }
        if (!hit || x1 <= x0) return null
        return [x0, x1]
    }

    // slab-fit: stack the rows down the cell, each row clamped to the polygon's chord at its
    //  band (top and bottom chords intersected — conservative, so slanted walls never clip
    //   text).  A `list` row is 2D: its chips WRAP into as many lines as the cell's width
    //   affords (no longer one clipped column), so its height counts for several units.  Too
    //    many rows → keep title + head + dip and say "+K more" (no silent caps).
    function micro_fit(inset: {x:number,y:number}[], descs: VtuffDesc[],
                       bx: number, by: number, bh: number): MicroRow[] {
        if (!descs.length) return []
        const usable = bh * 0.88
        // column capacity from the widest chord (the cell's belly) vs a typical chip width —
        //  drives how many lines a wrapping chip list needs.
        const midC = poly_chord(inset, by + bh / 2)
        const availW = midC ? Math.max(40, (midC[1] - midC[0]) - 12) : bh
        const CHIPW = 62
        const cols  = Math.max(1, Math.floor(availW / CHIPW))
        const listLines = (d: VtuffDesc) => Math.min(5, Math.max(1, Math.ceil((d.chips?.length ?? 1) / cols)))
        const hof = (d: VtuffDesc) => (d.kind === 'title' ? 1.35 : d.kind === 'list' ? listLines(d) : 1)
        const sum = (list: VtuffDesc[]) => list.reduce((s, d) => s + hof(d), 0)
        let unit = usable / sum(descs)
        unit = Math.max(12, Math.min(20, unit))
        let shown = descs
        if (unit * sum(descs) > usable + 1) {
            const title = descs.filter(d => d.kind === 'title')
            const dip   = descs.filter(d => d.dip)
            const mid   = descs.filter(d => d.kind !== 'title' && !d.dip)
            let keep = mid.length
            while (keep > 0 && unit * (sum(title) + sum(dip) + sum(mid.slice(0, keep)) + 1) > usable + 1) keep--
            const dropped = mid.length - keep
            shown = [...title, ...mid.slice(0, keep),
                     ...(dropped ? [{ text: `+${dropped} more`, kind: 'fact' } as VtuffDesc] : []), ...dip]
        }
        let y = by + Math.max(bh * 0.06, (bh - unit * sum(shown)) / 2)
        const rows: MicroRow[] = []
        for (const d of shown) {
            const h = unit * hof(d)
            const c1 = poly_chord(inset, y + h * 0.12)
            const c2 = poly_chord(inset, y + h * 0.88)
            if (c1 && c2) {
                const x0 = Math.max(c1[0], c2[0]) + 6, x1 = Math.min(c1[1], c2[1]) - 6
                // font-size rides the single LINE height, not a tall list block's total
                const fs = (d.kind === 'title' ? unit * 1.35 : unit) * 0.62
                if (x1 - x0 >= 36) rows.push({
                    text: d.text, kind: d.kind, x: x0 - bx, y: y - by, w: x1 - x0, h, fs,
                    color: d.color ?? null, tag: d.tag, sub: d.sub,
                    chips: d.chips, member: d.member, dip: d.dip })
            }
            y += h
        }
        return rows
    }

    // the /*N surf — a member row|chip clicked pops THAT node out INTO THE GRAPH; the dip
    //  (member undefined) spills the top-K.  Vtuff_pop stamps the c.popped|c.popped_open
    //   intents and waves a re-scan — never expands inside the pane.
    function micro_click(id: string, member?: TheC) {
        const src = node_src.get(id) as any
        if (!src) return
        ;(H as any).Vtuff_pop?.(src, member)
    }
    let vregion_w     = $state(0)                      // veil covers the tessellated region ([0, CW] — the full width unless the shelved rack returns)
    // ── the wheel-button grip ─────────────────────────────────────────────────
    //  middle-click-drag pans: grab the whole viewport by the wheel button, from
    //   ANYWHERE — over a node (cy only grabs on the primary button, so no
    //    fight), visor strip included (the visor is pointer-events:none, and the
    //     wheel guard only claims wheels).  Pointer capture rides the gesture
    //      outside the frame, and cy.panBy fires 'pan', so the live-overlay
    //       loop tracks it like any other motion.  preventDefault stops the
    //        browser's own middle-button autoscroll from starting underneath.
    function middle_pan_down(e: PointerEvent) {
        if (e.button !== 1 || !cy) return
        e.preventDefault()
        const el = e.currentTarget as HTMLElement
        el.setPointerCapture(e.pointerId)
        el.style.cursor = 'move'
        let px = e.clientX, py = e.clientY
        const move = (ev: PointerEvent) => {
            cy?.panBy({ x: ev.clientX - px, y: ev.clientY - py })
            px = ev.clientX; py = ev.clientY
        }
        const up = () => {
            el.style.cursor = ''
            el.removeEventListener('pointermove', move)
            el.removeEventListener('pointerup', up)
            el.removeEventListener('pointercancel', up)
        }
        el.addEventListener('pointermove', move)
        el.addEventListener('pointerup', up)
        el.addEventListener('pointercancel', up)
    }
    // ── story stepping from the canvas ───────────────────────────────────────
    //  the graph is a story surface too: with the canvas selected, ←/→ walk the
    //   story pips exactly like Storui's strip does.  The keys ride Storui's OWN
    //    pick() via the H.c.story_nav ref it publishes (a runtime ref, never
    //     encoded) — so the diff panel, Cyto_seek and the graph wave all follow
    //      as one, and Storui's re-assert effect sees its own echo, not a rival
    //       server jump.  No Storui mounted → the ref is absent and the keys
    //        fall through untouched.
    //  cy preventDefaults its mousedown, so a click on the canvas never focuses
    //   the wrap natively — wrap_pointerdown parks focus by hand (preventScroll:
    //    selecting the canvas must not yank the viewport to it).
    let wrap_el = $state<HTMLElement | null>(null)
    function wrap_pointerdown(e: PointerEvent) {
        wrap_el?.focus({ preventScroll: true })
        middle_pan_down(e)
    }
    function wrap_key(e: KeyboardEvent) {
        if (e.key !== 'ArrowLeft' && e.key !== 'ArrowRight') return
        const nav = (H as any).c?.story_nav
        if (!nav) return
        e.preventDefault()
        nav(e.key === 'ArrowRight' ? 1 : -1)
    }
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

    // ── flower-wireframe nuclei ──────────────────────────────────────────────
    //  orderless siblings (no edges among them) grid-jitter under fcose: nothing
    //  but mutual repulsion holds them, so they shuffle in a twitchy lattice and
    //  the cells riding them never sit still.  The cure is a radial singularity —
    //  a hidden hub per parent that every free child star-edges to, so the sim
    //  seats them as petals around a centre (a flower wireframe that voronois into
    //  a clean rosette).  Pure cytoscape scaffold: never in C**, never snapped,
    //  invisible, and skipped by both the tessellator and the rack.
    const NUC_MIN = 3
    const is_nucleus = (node: any) => !!node.data('nucleus')

    function install_nuclei() {
        if (!cy) return
        cy.elements('.nucleus, .nucleus-edge').remove()   // wipe last generation
        if (!voronoi_on) return
        // gather truly free (edgeless) real nodes, grouped by their parent — those
        //  are the orderless ones; anything already wired keeps its own structure
        const groups = new Map<string, any[]>()
        cy.nodes().forEach((node: any) => {
            if (node.isParent() || is_nucleus(node) || node.degree(false) > 0) return
            const pid = node.parent().id() || ''
            if (!groups.has(pid)) groups.set(pid, [])
            groups.get(pid)!.push(node)
        })
        for (const [pid, kids] of groups) {
            if (kids.length < NUC_MIN) continue
            const nid = `nuc:${pid || '__root__'}`
            const data: any = { id: nid, nucleus: 1, label: '' }
            if (pid) data.parent = pid
            const hub = cy.add({ group: 'nodes', classes: 'nucleus', data })
            // seat the hub at the group's centroid so the petals fold in, not lurch
            let cx = 0, cyy = 0
            for (const k of kids) { const p = k.position(); cx += p.x; cyy += p.y }
            hub.position({ x: cx / kids.length, y: cyy / kids.length })
            for (const k of kids) {
                // petal radius grows with the chunk's own box so big Stuffings sit
                //  clear of the hub instead of cramming (leaves keep the tight 70)
                const child = overlays.get(k.id())?.firstElementChild as HTMLElement | null
                const r = child
                    ? 55 + 0.5 * Math.hypot(child.offsetWidth, child.offsetHeight)
                    : 70
                cy.add({ group: 'edges', classes: 'nucleus-edge',
                    data: { id: `${nid}>${k.id()}`, source: nid, target: k.id(),
                            ideal_length: Math.round(r), nucleus: 1 } })
            }
        }
    }

    let crush_imposed = false         // we asked Cyto_crush to fold this world (◈ on an un-crushed graph)

    function toggle_voronoi() {
        voronoi_pref = !voronoi_on
        const st = (H as any).stashed
        if (st) st.Cyto_voronoi = voronoi_pref
        // the luxury layer: an un-crushed world (no Book opt ever stamped chunks) gets the
        //  crush IMPOSED — Cyto re-scans with the Voro crusher armed, the chunks arrive on
        //   the next wave and the morph divides them in.  All c-side; snaps stay blind.
        if (voronoi_pref && !saw_stuffy) {
            crush_imposed = true
            H.i_elvisto('Cyto/Cyto', 'Cyto_crush', { on: 1 })
        } else if (!voronoi_pref && crush_imposed) {
            crush_imposed = false
            H.i_elvisto('Cyto/Cyto', 'Cyto_crush', {})   // absence = off (snapped-boolean rule)
        }
        install_nuclei()              // grow (on) or dissolve (off) the flower hubs
        relayout(300)                 // let the sim re-settle around / without them
        proper_sync()                 // properCellable's default follows the mode
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
        // the molding affine (a symmetric eigenframe stretch, now composed with
        //  a capped legibility rotation, so T21 ≠ T12 in general) + fitted scale
        T11: number, T12: number, T21: number, T22: number, fit: number,
        // per-wall provenance: edge k (inset[k]→inset[k+1]) was cut by this
        //  neighbouring seed id, or null for the frame — the family hulls
        //   read it to find which walls face OUTSIDE the family
        edge_src: (string | null)[],
    }

    // support of the content box under the molding transform, in direction n̂ —
    //  the one formula both the wall-placement and the fit use:
    //   T maps (±w/2, ±h/2); the box's farthest reach along n̂ is
    //   |n̂·T·(w/2,0)| + |n̂·T·(0,h/2)|
    //  T21 defaults to T12 so every symmetric caller stays exact; the rotated
    //   molding passes its true T21.
    function box_support(nx: number, ny: number, hw: number, hh: number,
                         T11 = 1, T12 = 0, T22 = 1, T21 = T12) {
        return Math.abs(nx * T11 + ny * T21) * hw + Math.abs(nx * T12 + ny * T22) * hh
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
            // every chunk claims a floor box even when its content is a sliver, so a
            //  one-row Stuffing still earns a real cell instead of a hairline splinter.
            //  A bigger FAMILY claims a bigger cell: the fold count (c.fold_n, stamped
            //   by the crusher, read via node_src) lifts the floor on a gentle log
            //    scale — c-side only, and floor-only so measured content still rules.
            const fn   = (node_src.get(id) as any)?.c?.fold_n as number | undefined
            const lift = fn ? Math.log2(1 + fn) * 9 : 0
            const hw = Math.max(40 + lift,       (child?.offsetWidth  ?? node.renderedWidth())  / 2)
            const hh = Math.max(30 + lift * 0.6, (child?.offsetHeight ?? node.renderedHeight()) / 2)
            seeds.push({ id, x: p.x, y: p.y, hw: Math.min(hw, 260), hh: Math.min(hh, 200), node })
        }
        if (seeds.length < 2) return null

        // ── the rack, SHELVED ─────────────────────────────────────────────────
        //  hauled non-cell equipment (Piers, reqs, Opt…) into a label-sorted
        //  column at the right edge, shrinking the tessellation to [0, CW].
        //  Shelved: the scape reads better with the oddballs simply seated
        //  where fcose put them, under the veil among the cells.  Kept behind
        //  the flag (not deleted) as the seed of a future in|out-group process
        //  option; while it is off, no pixel geometry pushes into the layout
        //  AT ALL — the old "one sanctioned exception" is zero exceptions.
        const RACK_ON = false as boolean
        let CW = W
        if (RACK_ON) {
            const rack = cy.nodes().filter((node: any) =>
                !node.isParent() && !is_nucleus(node) && !stuff_mounts.has(node.id()))
            rack.sort((a: any, b: any) =>
                String(a.data('label') ?? a.id()).localeCompare(String(b.data('label') ?? b.id())))
            const per_col = Math.max(1, Math.floor((HH - 50) / 34))
            const n_cols  = rack.length ? Math.ceil(rack.length / per_col) : 0
            rack.forEach((node: any, i: number) => {
                const col = Math.floor(i / per_col), row = i % per_col
                node.renderedPosition({ x: W - 65 - col * 72, y: 40 + row * 34 })
            })
            CW = Math.max(W * 0.55, W - (n_cols ? 130 + (n_cols - 1) * 72 : 0))
        }

        const GAP = 4
        const cells: VCell[] = []
        for (const s of seeds) {
            let poly = [{ x: 0, y: 0 }, { x: CW, y: 0 }, { x: CW, y: HH }, { x: 0, y: HH }]
            // every applied cut, kept for post-hoc edge attribution: a final
            //  edge lying on a cutter's line was cut by that neighbour (family
            //   hulls need to know which walls face OUTSIDE the family)
            const cuts: { px: number, py: number, nx: number, ny: number, id: string }[] = []
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
                const mx = s.x + ux * t, my = s.y + uy * t
                poly = clip_halfplane(poly, { x: mx, y: my }, { x: ux, y: uy })
                cuts.push({ px: mx, py: my, nx: ux, ny: uy, id: o.id })
                if (poly.length < 3) break
            }
            if (poly.length < 3) continue   // swallowed by a heavier neighbour

            // attribute each final edge to the cut whose line contains it
            //  (midpoint within ε of the line); null = the frame.  O(edges·cuts)
            //   over a handful of each — noise next to the clipping itself.
            const edge_src: (string | null)[] = poly.map((p, k) => {
                const q = poly[(k + 1) % poly.length]
                const mx2 = (p.x + q.x) / 2, my2 = (p.y + q.y) / 2
                for (const c of cuts)
                    if (Math.abs((mx2 - c.px) * c.nx + (my2 - c.py) * c.ny) < 0.5) return c.id
                return null
            })

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
            let acx = vmx, acy = vmy, T11 = 1, T12 = 0, T21 = 0, T22 = 1
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
                const elong = rho                             // pre-blend elongation, gates the tilt
                rho = 1 + (Math.min(rho, 1.8) - 1) * 0.55     // "a little": blend + cap
                const a1 = Math.sqrt(rho), a2i = 1 / Math.sqrt(rho)
                const cs = Math.cos(phi), sn = Math.sin(phi)
                // the symmetric eigenframe stretch (no rotation yet)
                const S11 = a1 * cs * cs + a2i * sn * sn
                const S22 = a1 * sn * sn + a2i * cs * cs
                const S12 = (a1 - a2i) * cs * sn
                // a long cell wants a long Stuffing: rotate the molding toward
                //  the long axis φ, a LITTLE, under hard legibility caps —
                //   |θ| ≤ 20°, snapped to 0 below 8° (a barely-tilted line reads
                //    worse than a straight one), and only when the cell is
                //     genuinely elongated (a near-circular cell's φ is noise).
                //      Text tilts; it never turns.
                const MAXR = Math.PI / 9, SNAP = Math.PI / 22.5
                let th = elong > 1.18 ? Math.max(-MAXR, Math.min(MAXR, phi)) : 0
                if (Math.abs(th) < SNAP) th = 0
                const rc = Math.cos(th), rn = Math.sin(th)
                T11 = rc * S11 - rn * S12; T12 = rc * S12 - rn * S22
                T21 = rn * S11 + rc * S12; T22 = rn * S12 + rc * S22
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
                const denom = box_support(nx, ny, s.hw, s.hh, T11, T12, T22, T21)
                if (denom > 1e-6) smax = Math.min(smax, room / denom)
            }
            const fit = Math.max(0.5, smax * 0.92)

            cells.push({ id: s.id, seed: { x: s.x, y: s.y }, inset, acx, acy,
                color: cell_color(s.id, s.node), node: s.node,
                T11, T12, T21, T22, fit, edge_src })
        }
        return { cells, seeds, CW }
    }

    // a kind's Matstyle colour, READ-ONLY (metaphysics §5: a render path must
    //  never autovivify a style — o() only, no get_or_create); null when the
    //   style is absent so callers fall back to their own palette.
    function kind_color(kind: string | undefined): string | null {
        if (!kind) return null
        try {
            const stylesC = (H as any).Awo('Cyto')?.c?.Styles
            const ms = stylesC?.o({ matstyle: kind })[0]
            const bg = ms ? (H as any).ms_css(ms)['background-color'] : null
            if (bg) return bg as string
        } catch {}
        return null
    }

    // deterministic per-kind HUE — the stained-glass floor.  A kind with no
    //  authored Matstyle STILL earns its own hue, so the mosaic never collapses
    //   to one colour.  ("Where's the teal from?" — the old fallback was the fold
    //    node's single default border #79b, so every un-swatched fold went the
    //     same blue-grey.)  A raw hash of the name clusters (14 genera → five
    //      purples); instead each distinct kind takes the next GOLDEN-ANGLE slot
    //       (137.5° apart → maximal spread even for a handful), the fam_seq
    //        pattern the hulls already use.  Order-dependent but cosmetic.
    const kind_slot = new Map<string, number>()
    let kind_seq = 0
    function kind_hue(kind: string | undefined): number | null {
        if (!kind) return null
        if (!kind_slot.has(kind)) kind_slot.set(kind, kind_seq++)
        return Math.round((kind_slot.get(kind)! * 137.508) % 360)
    }
    // the glass colour of a cell: an authored Matstyle swatch first (the purple
    //  you dotted), else the kind's own stained-glass hue — saturated, because
    //   the cell fill is translucent.  null only for a truly kind-less cell.
    function kind_glass(kind: string | undefined): string | null {
        const ms = kind_color(kind); if (ms) return ms
        const h = kind_hue(kind); return h == null ? null : `hsl(${h}, 58%, 56%)`
    }
    // a lighter tint of the SAME hue, for pane text (rows) — readable on the dark glass.
    function kind_tint(kind: string | undefined): string | null {
        const ms = kind_color(kind); if (ms) return ms
        const h = kind_hue(kind); return h == null ? null : `hsl(${h}, 44%, 74%)`
    }

    // a fold's cell carries its dominant KIND's colour (c.fold_kind, stamped by
    //  the crusher, read via node_src); a plain cell carries its OWN mainkey's.
    //   Either way it goes through kind_glass, so an un-swatched kind still joins
    //    the stained glass by hue instead of falling to the teal node border.
    function cell_color(id: string, node: any): string {
        const src = node_src.get(id) as any
        const g = kind_glass(src?.c?.fold_kind as string | undefined); if (g) return g
        const own = src?.sc ? Object.keys(src.sc)[0] as string : undefined
        return kind_glass(own) ?? (node.style('border-color') as string)
    }

    // the family of a cell, for the ⬡ hulls — three answers, in priority order:
    //  1) an explicit c-side c.vfamily on the live particle (a Book stamps it —
    //     VoroMitosis tags each genus cell with its botanical family; c-side,
    //      so no snap ever sees it and no core changed for the demo),
    //  2) the compound ancestor one below the outermost — the classic route,
    //     which only fires when an intermediate cyto-compound exists,
    //  3) the MODEL parent (c.up) when it isn't the scan frame (w/H/A) — so
    //     sibling folds under one Pier/Artist hull together even though their
    //      parent drew as a plain node, not a compound.  Cells directly under
    //       w stay family-less unless route 1 names one.
    const fam_ids = new WeakMap<object, string>()
    let fam_seq = 0
    function family_of(node: any): string | null {
        const src = node_src.get(node.id()) as any
        if (src?.c?.vfamily) return `vfam:${src.c.vfamily}`
        const anc = node.ancestors().toArray()
        if (anc.length >= 2) return anc[anc.length - 2].id()
        const up = src?.c?.up
        if (up?.sc) {
            const mk = Object.keys(up.sc)[0]
            if (mk && mk !== 'w' && mk !== 'H' && mk !== 'A') {
                let fid = fam_ids.get(up)
                if (!fid) { fid = `vup:${++fam_seq}`; fam_ids.set(up, fid) }
                return fid
            }
        }
        return null
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
    // wrap_applied: the last wrap width handed to each cell's content —
    //  the hysteresis memory that keeps the measure→wrap→measure loop damped
    const wrap_applied = new Map<string, number>()
    function paint_final(L: { cells: VCell[], seeds: any[], CW: number }) {
        const crossings = new Map<string, { wall: number, t: number, m: {x:number,y:number}, color: string }[]>()
        const cell_by_id = new Map(L.cells.map(c => [c.id, c]))
        cy.edges().forEach((e: any) => {
            if (e.data('nucleus')) return   // flower spokes are scaffold, not adjacency
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
                    // wrap width FROM the cell: hand the content the cell's own
                    //  horizontal proportion as a WRAP CEILING only — max-width,
                    //   never width.  Forcing width made a short line measure as a
                    //    full box: the affine then scaled that wide box down to
                    //     the cell, so the text came out tiny with a dead gap after
                    //      it.  max-width alone lets .cytui-stuff keep its
                    //       max-content shrink-to-fit, so the box hugs the text and
                    //        the mold scales the TEXT, not the padding.  DAMPED
                    //         (metaphysics §6): quantised to 24px, re-applied only
                    //          on a >15% move, only here at settle cadence.
                    const targ = Math.max(96, Math.min(360,
                        Math.round((bw * 0.86 - 24) / 24) * 24))
                    const prev = wrap_applied.get(c.id) ?? 0
                    if (Math.abs(targ - prev) / (prev || targ) > 0.15) {
                        child.style.width    = ''            // ← keep max-content; never a fixed box
                        child.style.maxWidth = `${targ}px`
                        wrap_applied.set(c.id, targ)
                    }
                    const a  = (c.fit * c.T11).toFixed(3), b12 = (c.fit * c.T12).toFixed(3)
                    const b21 = (c.fit * c.T21).toFixed(3), d2 = (c.fit * c.T22).toFixed(3)
                    const tx = c.acx - (bx + bw / 2), ty = c.acy - (by + bh / 2)
                    // CSS matrix(a,b,c,d) is column-major: x' = a·x + c·y, y' = b·x + d·y
                    child.style.transform = `translate(${tx.toFixed(1)}px, ${ty.toFixed(1)}px)`
                        + ` matrix(${a}, ${b21}, ${b12}, ${d2}, 0, 0)`
                }
            }
        }

        // ── family hulls: one faint shared outline per house ─────────────────
        //  group the cells by compound family; a wall whose cutter is INSIDE
        //   the family is interior (skipped), everything else — foreign cell,
        //    frame — is boundary and gets stroked.  Disjoint segments, not a
        //     traced loop: visually identical, and immune to topology surprises.
        //  Mid-morph the hulls run one generation stale (they only repaint here
        //   at settle) — a faint sub-500ms ghost, accepted.
        const fams: typeof vfams = []
        if (families_on && L.cells.length > 2) {
            const fam_of = new Map<string, string>()
            for (const c of L.cells) {
                const f = family_of(c.node)
                if (f) fam_of.set(c.id, f)
            }
            const groups = new Map<string, VCell[]>()
            for (const c of L.cells) {
                const f = fam_of.get(c.id)
                if (!f) continue
                if (!groups.has(f)) groups.set(f, [])
                groups.get(f)!.push(c)
            }
            let fi = 0
            for (const [fid, members] of groups) {
                fi++
                if (members.length < 2) continue   // a family of one is just its cell
                const inside = new Set(members.map(m => m.id))
                let d = ''
                for (const m of members)
                    for (let k = 0; k < m.inset.length; k++) {
                        const srcid = m.edge_src[k]
                        if (srcid && inside.has(srcid)) continue   // interior wall
                        const a = m.inset[k], b = m.inset[(k + 1) % m.inset.length]
                        d += `M${P(a.x, a.y)}L${P(b.x, b.y)}`
                    }
                if (d) fams.push({ id: fid, d, color: FAM_COLORS[fi % FAM_COLORS.length] })
            }
        }
        vfams = fams

        // ── the vtuffing swap: ▤ on = the ENGINE owns every fold pane ──
        //  v1 swapped per-cell above a zoom threshold WITH per-cell hysteresis
        //   memory — so two same-size neighbours could differ purely by zoom
        //    HISTORY, and the board read as an arbitrary half-Stuffing
        //     half-Vtuffing mix (the owner: "weird").  One rule now: when ▤ is
        //      on, every fold|gang pane that can say ANYTHING (clears the tiny
        //       floor and fits ≥1 row) speaks rows; molded Stuffings live under
        //        ▤ off.  A sliver that fits nothing keeps its Stuffing — the
        //         dim only happens once rows really render (v1 could dim the
        //          Stuffing then fit nothing: a blank pane).  BOTH cadences:
        //           the tree is cached .g-side and the fit is pure math, so
        //            the rows track a drag live.
        if (vtuffing_on) {
            const MICRO_MIN = 70   // √px² below which no row is legible anyway
            const micro: typeof vmicro = []
            const next_on = new Set<string>()
            for (const c of L.cells) {
                const src = node_src.get(c.id) as any
                if (!src?.c?.gang && !src?.c?.stuff) continue
                let area2 = 0
                for (let i = 0; i < c.inset.length; i++) {
                    const p = c.inset[i], q = c.inset[(i + 1) % c.inset.length]
                    area2 += p.x * q.y - q.x * p.y
                }
                const px = Math.sqrt(Math.abs(area2) / 2)
                if (px < MICRO_MIN) continue
                const descs = vtuff_rows(src)
                if (!descs.length) continue
                const xs = c.inset.map(p => p.x), ys = c.inset.map(p => p.y)
                const bx = Math.min(...xs), by = Math.min(...ys)
                const bw = Math.max(...xs) - bx, bh = Math.max(...ys) - by
                const rows = micro_fit(c.inset, descs, bx, by, bh)
                if (!rows.length) continue
                next_on.add(c.id)
                micro.push({ id: c.id, x: bx, y: by, w: bw, h: bh,
                    clip: 'polygon(' + c.inset.map(p =>
                        `${(p.x - bx).toFixed(1)}px ${(p.y - by).toFixed(1)}px`).join(',') + ')',
                    rows })
            }
            // crossfade: dim the molded Stuffing of every swapped cell; restore leavers
            for (const id of next_on) { const mel = overlays.get(id); if (mel) mel.style.opacity = '0' }
            for (const id of micro_on_ids) if (!next_on.has(id)) {
                const mel = overlays.get(id); if (mel) mel.style.opacity = ''
            }
            micro_on_ids = next_on
            vmicro = micro
            // a swapped cell wears the Stuffing's chrome (dotted rim + fuller
            //  glass) so the pane still reads as a Stuffing, not a flat panel.
            for (const cc of cells) cc.swapped = next_on.has(cc.id)
        } else if (micro_on_ids.size || vmicro.length) {
            for (const id of micro_on_ids) { const mel = overlays.get(id); if (mel) mel.style.opacity = '' }
            micro_on_ids = new Set()
            vmicro = []
        }

        // a seed whose cell got swallowed falls back to plain node-centering
        for (const s of L.seeds) {
            if (cell_by_id.has(s.id)) continue
            const el = overlays.get(s.id)
            if (!el) continue
            el.style.clipPath = ''; el.style.width = ''; el.style.height = ''; el.style.maxWidth = ''
            const inner = el.firstElementChild as HTMLElement | null
            if (inner) { inner.style.transform = ''; inner.style.width = ''; inner.style.maxWidth = '' }
            wrap_applied.delete(s.id)
            el.style.left = `${s.x - el.offsetWidth / 2}px`
            el.style.top  = `${s.y - el.offsetHeight / 2}px`
        }
        vcells = cells
        vtips = tips
    }

    // ── morph_voronoi: tween shown → next generation, then paint the rest state ──
    function morph_voronoi() {
        if (dragging) return   // live-drag owns the repaint; don't fight it
        const L = voronoi_layout()
        if (!L) {
            if (vcells.length || vtips.length) clear_voronoi()
            settle_overlay_show()
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
        if (still) { for (const c of L.cells) shown_pts.set(c.id, targets.get(c.id)!); paint_final(L); settle_overlay_show(); return }

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
                settle_overlay_show()
            }
        }
        morph_raf = requestAnimationFrame(frame)
    }

    function clear_voronoi() {
        cancelAnimationFrame(morph_raf)
        vcells = []
        vtips = []
        vfams = []
        vmicro = []
        for (const id of micro_on_ids) { const mel = overlays.get(id); if (mel) mel.style.opacity = '' }
        micro_on_ids.clear()
        shown_pts.clear()
        shown_color.clear()
        wrap_applied.clear()
        for (const el of overlays.values()) {
            if (!el.classList.contains('stuff-overlay')) continue
            el.style.clipPath = ''; el.style.width = ''; el.style.height = ''; el.style.maxWidth = ''
            const inner = el.firstElementChild as HTMLElement | null
            if (inner) { inner.style.transform = ''; inner.style.width = ''; inner.style.maxWidth = '' }
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
            node_src.clear()
            proper_mounted.clear()
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
                node_src.delete(rid)
                proper_mounted.delete(rid)
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
            const src = (nd as any).c?.source_n as TheC | undefined
            if (src) node_src.set(id, src)   // rides every upsert now — the render-side classifiers read it
            if (overlay_kind === 'stuff') {
                // c.stuffy exists ONLY under the %crushCyto-gated crusher — a crushed
                //  world auto-arms the voronoi render (voronoi_pref still overrides)
                if ((src as any)?.c?.stuffy) saw_stuffy = true
                proper_mounted.delete(id)    // wave-owned now; toggling proper off must not strip it
                create_stuff_overlay(id, src, overlay_bg, !!nd.sc.overlay_self)
                // a mounted gang rep whose gang GREW: rebuild the mirror in place
                //  (the Stuffing keeps its ref and re-groups on the next flush)
                if ((src as any)?.c?.gang && overlays.has(id)) gang_stuff(id, src as TheC)
            } else if (overlay_str != null) {
                create_overlay(id, overlay_str, overlay_kind ?? 'code', overlay_bg)
            } else if (proper_on && is_proper(src)) {
                // properCellable: a wordy loner (%see) gets a self-row Stuffing —
                //  and thereby a cell — Cytui-local; the wave carried no
                //   overlay_kind for it, so no snap can tell
                create_stuff_overlay(id, src, undefined, true)
                proper_mounted.add(id)
                cy.getElementById(id).style('label', '')
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
            install_nuclei()   // (re)seat the flower hubs so the sim settles radial
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
            // radial smudge: with the flower on, the nuclei pull orderless nodes
            //  INTO a central hub — so we push back with stronger repulsion, wider
            //   separation and relaxed gravity, and the rosette breathes outward
            //    into an airy centre you can zoom into instead of a crowded knot.
            if (voronoi_on) {
                opts.nodeRepulsion  = () => 9000
                opts.nodeSeparation = 60
                opts.gravity        = 0.12
                opts.gravityCompound = 0.5
            }
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
        const stashed_p = (H as any).stashed?.Cyto_properCellable
        if (typeof stashed_p === 'boolean') proper_pref = stashed_p
        const stashed_f = (H as any).stashed?.Cyto_families
        if (typeof stashed_f === 'boolean') families_pref = stashed_f
        const stashed_b = (H as any).stashed?.Cyto_gravity_brush
        if (typeof stashed_b === 'boolean') brush_pref = stashed_b
        const stashed_t = (H as any).stashed?.Cyto_vtuffing
        if (typeof stashed_t === 'boolean') vtuffing_pref = stashed_t
        cy = cytoscape({
            container,
            // a livelier wheel: the default 1 needs a whole spin to move; the
            //  scape wants a flick to matter (owner request 2026-07-06)
            wheelSensitivity: 2,
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
                // flower-wireframe scaffold — a layout-only hub + its spokes, kept
                //  invisible and inert (events:'no' so taps pass through to real nodes)
                { selector: '.nucleus',
                  style: { width: 1, height: 1, opacity: 0,
                           'background-opacity': 0, label: '', events: 'no' } },
                { selector: '.nucleus-edge',
                  style: { opacity: 0, width: 0.5, events: 'no' } },
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
        // Every motion — a node drag, a background pan, a scroll-to-zoom,
        // a layout wave — drives the SAME live-repaint loop (drag_frame):
        // the overlays stay visible and track their nodes frame by frame.
        // A per-frame budget self-heal sheds to the cheap hide-all only if
        // a machine can't repaint in time; a debounced timer settles the
        // final positions once the user stops moving.
        cy.on('grab',        () => start_live_drag())
        cy.on('free',        () => end_live_drag())
        cy.on('pan zoom',    () => pan_zoom_motion())
        cy.on('layoutstart', () => start_live_layout())
        cy.on('layoutstop',  () => { stop_live_layout(); show_overlays_soon() })
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
        // ── un-pop: right-click folds a surfed node back ──────────────────────
        //  The pop's inverse gesture (Vtuff_pop's stamps are sticky by design —
        //   crush passes respect them until someone says fold-me-back).  Fires
        //    only on a node that is itself popped|popped_open or is the hub of
        //     popped children; everything else right-clicks as normal.
        cy.on('cxttap', 'node', (evt) => {
            const src = node_src.get(evt.target.id()) as any
            if (!src?.c) return
            let hit = src.c.popped || src.c.popped_open
            if (!hit && typeof src.o === 'function')
                for (const c of src.o() as any[]) if (c.c?.popped || c.c?.popped_open) { hit = true; break }
            if (hit) (H as any).Vtuff_unpop?.(src)
        })
        // the browser context menu would cover the graph on every cxttap — suppress it
        //  over the canvas only (the bar and panes above keep theirs).
        cy.container()?.addEventListener('contextmenu', (e: Event) => e.preventDefault())

        // rebuild from scratch on HMR
        H.i_elvisto('Cyto/Cyto', 'Cyto_wipe', {})
        return () => {
            lay?.stop()
            clear_all_overlays()
            cy?.destroy()
        }
    })
</script>

<div class="cytui" class:tall={tall}>
    <div class="cytui-bar">
        <span class="cytui-status">{status}</span>
        {#if seek_warning}
            <span class="cytui-warn">⚠ {seek_warning}</span>
        {/if}
        <button onclick={() => relayout(300)}>⟳</button>
        <button onclick={() => cy?.fit(cy.nodes(), 16)}>⊞</button>
        <button class="v-toggle" class:on={voronoi_on} onclick={toggle_voronoi}
            title="voronoi cells — Cyto lays out, cells render">◈</button>
        <button class="v-toggle" class:on={proper_on} onclick={toggle_proper}
            title="properCellable — wordy loners (%see) get a Stuffing, and a cell in voronoi mode">❝</button>
        <button class="v-toggle" class:on={families_on} onclick={toggle_families}
            title="family hulls — one faint shared outline per compound house">⬡</button>
        <button class="v-toggle" class:on={brush_pref} onclick={toggle_brush}
            title="gravity brush — wheel pinches|spreads the locale under the cursor (Ctrl+wheel still zooms)">🌀</button>
        <button class="v-toggle" class:on={vtuffing_on} onclick={toggle_vtuffing}
            title="vtuffing — a big-enough pane swaps its molded Stuffing for member rows fitted to the cell (off = Stuffings always)">▤</button>
        <span class="cytui-vx" title="taller — double the graph height (50vh ↔ 100vh), then re-fit">
            <Vexpandy bind:expanded={tall} />
        </span>
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
    <!-- tabindex=-1: clicking the canvas parks keyboard focus here (via
         wrap_pointerdown — cy eats the native focus click) so ←/→ can walk the
         story pips; role=application tells AT the arrows are app-handled.
         onwheelcapture is the visor guard — see the scroll-visor region. -->
    <div class="cytui-graph-wrap" bind:this={wrap_el} tabindex="-1" role="application"
         onpointerdown={wrap_pointerdown} onkeydown={wrap_key} onwheelcapture={visor_guard}>
        <div class="cytui-graph" bind:this={container}></div>
        <!-- voronoi layer between the canvas and the HTML overlays: the veil dims
             the raw graph so the cells (and the Stuffings stretched into them)
             carry the reading; it hides with the overlays during motion. -->
        <svg class="cytui-voronoi" style:opacity={motion_hidden ? 0 : 1}>
            {#if voronoi_on && vcells.length}
                <rect class="cytui-veil" width={vregion_w || '100%'} height="100%" />
                <!-- family hulls: behind the cell strokes, a chunky ROPE — the
                     boundary walls of one house lashed together.  Two passes over
                     the same segments (a wide soft body + a narrower bright core)
                     because a thin faint line here lies exactly ON the cell
                     strokes and disappears under them. -->
                {#each vfams as fam (fam.id)}
                    <path d={fam.d} fill="none" stroke={fam.color}
                        stroke-opacity="0.30" stroke-width="11" stroke-linecap="round" />
                    <path d={fam.d} fill="none" stroke={fam.color}
                        stroke-opacity="0.55" stroke-width="4.5" stroke-linecap="round" />
                {/each}
                {#each vcells as cell (cell.id)}
                    <!-- a swapped (vtuffing) cell wears the Stuffing's tabletty
                         dotted rim + a fuller glass fill; plain cells keep the
                         thin solid stroke.  Colour is the kind's swatch|hue. -->
                    <path d={cell.d}
                        fill={cell.color} fill-opacity={cell.swapped ? 0.2 : 0.13}
                        stroke={cell.color} stroke-opacity={cell.swapped ? 0.85 : 0.6}
                        stroke-width={cell.swapped ? 1.75 : 1.5}
                        stroke-dasharray={cell.swapped ? '1.5 3' : undefined}
                        stroke-linecap="round" stroke-linejoin="round" />
                {/each}
                {#each vtips as tip (tip.id)}
                    <circle cx={tip.x} cy={tip.y} r="2.4"
                        fill={tip.color} fill-opacity="0.95" />
                {/each}
            {/if}
        </svg>
        <!-- vtuffing layer: a big-enough cell swaps its molded Stuffing for the
             engine's rows (Voro.g Vtuff_build — title | shared facts | spreads
             with chips | members | the /*N dip), chord-fitted to the cell
             polygon and clipped by it.  Tracks BOTH cadences, so the rows ride
             a drag live.  member|dip rows are buttons: the surf pops nodes out
             into the graph (Vtuff_pop), never expands inside the pane. -->
        <div class="cytui-micro-layer" style:opacity={motion_hidden ? 0 : 1}>
            {#each vmicro as mc (mc.id)}
                <div class="cytui-micro" style:left={`${mc.x}px`} style:top={`${mc.y}px`}
                     style:width={`${mc.w}px`} style:height={`${mc.h}px`} style:clip-path={mc.clip}>
                    {#each mc.rows as row, ri (ri)}
                        {@const hot = row.member != null || row.dip}
                        <svelte:element this={hot ? 'button' : 'div'}
                             role={hot ? 'button' : undefined}
                             class="cytui-micro-row {row.kind}" class:hot
                             style:left={`${row.x.toFixed(1)}px`} style:top={`${row.y.toFixed(1)}px`}
                             style:width={`${row.w.toFixed(1)}px`} style:height={`${row.h.toFixed(1)}px`}
                             style:font-size={`${row.fs.toFixed(1)}px`}
                             style:align-items={row.kind === 'list' ? 'flex-start' : 'center'}
                             style:color={row.color ?? ''}
                             onclick={hot ? () => micro_click(mc.id, row.member) : undefined}>
                            <!-- the mainkey IS different from other keys: it rides as a small
                                 type-tag chip beside the bare NAME, never as inline prose -->
                            {#if row.tag}<span class="ktag">{row.tag}</span>{/if}
                            <span class="t">{row.text}</span>
                            {#if row.sub}<span class="subn">/*{row.sub}</span>{/if}
                            <!-- a chip carrying a member is its OWN pop-out handle (the
                                 homogeneous list form: 'figaro' pops figaro) -->
                            {#each row.chips ?? [] as chip, ci (ci)}
                                <svelte:element this={chip.member ? 'button' : 'span'}
                                     role={chip.member ? 'button' : undefined}
                                     class="chip" class:hot={chip.member != null}
                                     onclick={chip.member ? (e: Event) => { e.stopPropagation(); micro_click(mc.id, chip.member) } : undefined}>
                                    {chip.text}{chip.n > 1 ? ` ×${chip.n}` : ''}{#if chip.sub}<span class="subn">/*{chip.sub}</span>{/if}</svelte:element>
                            {/each}
                        </svelte:element>
                    {/each}
                </div>
            {/each}
        </div>
        <!-- scroll visor: the lit indicator for the wheel gutter over the right
             strip.  Pure pixels (pointer-events:none) — the wrap's capture-phase
             visor_guard does the actual wheel-stealing, so everything beneath
             the strip stays clickable and draggable.  Lights while a wheel is
             being gutter'd, then vanishes. -->
        <div class="cytui-visor" class:lit={visor_lit}
             style:width={`${VISOR_FRAC * 100}%`}></div>
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
/* Vexpandy: the V-toggle doubles the graph height (owner re-fits after). */
.cytui.tall { height: 100vh; }
/* the Vexpandy V sits inline in the bar — strip the boxed bar-button skin
   (.cytui-bar button {…}) off the nested .vx-btn so it reads as a clean
   rotating V, not a framed button. */
.cytui-vx { display: inline-flex; align-items: center; }
.cytui-vx :global(.vx-btn),
.cytui-vx :global(.vx-btn:hover) { background: none; border: none; padding: 0; }
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
    /* focusable (story-stepping keys land here) but never ringed — selecting
       the canvas is a quiet act; the pip strip shows where the story is */
    outline: none;
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

/* The scroll visor — the lit indicator over the wheel-gutter strip.
   pointer-events:none: the visor never takes an event itself (the wrap's
   capture-phase visor_guard steals wheels positionally), so cells and nodes
   under the strip stay fully handleable.  Invisible at rest so it never
   obscures the graph — .lit fades it in while a wheel is being gutter'd, and
   removing .lit lets the slow transition carry it back to nothing (the
   "vanish").  The glass is the same blue as the ◈/voronoi accent. */
.cytui-visor {
    position: absolute;
    top: 0; right: 0;
    height: 100%;
    pointer-events: none;
    opacity: 0;
    transition: opacity 0.5s ease;
    background: linear-gradient(to right, transparent, rgba(120,176,212,0.06));
    border-left: 1px solid rgba(120,176,212,0.22);
}
.cytui-visor.lit {
    opacity: 1;
    transition: opacity 0.08s ease;
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
    /* the microcosm crossfade: paint_final dims a micro'd cell's Stuffing to 0
       and restores it when the swap reverses — ~200ms each way */
    transition: opacity 0.2s ease;
}

/* ── vtuffing: engine rows chord-fitted inside a big-enough cell ──────────── */
.cytui-micro-layer {
    position: absolute;
    inset: 0;
    pointer-events: none;
    transition: opacity 0.25s ease;
}
.cytui-micro { position: absolute; }
.cytui-micro-row {
    position: absolute;
    display: flex;
    align-items: center;
    gap: 0.45em;
    overflow: hidden;
    white-space: nowrap;
    color: #c3d0da;
    background: none;
    border: none;
    padding: 0;
    text-align: left;
    box-sizing: border-box;
}
.cytui-micro-row .t {
    overflow: hidden;
    text-overflow: ellipsis;
    flex: 0 1 auto;
}
.cytui-micro-row.title {
    font-weight: 600;
    letter-spacing: 0.03em;
}
.cytui-micro-row.fact .t { opacity: 0.85; }
.cytui-micro-row.spread .t { opacity: 0.55; }
/* the homogeneous list form ('figaro · tenuifolium · +2') — the family said once in the
   title, the members as chips.  WRAPS into a 2D grid that fills the cell's belly instead
   of one clipped column (micro_fit gives the row height for the wrapped lines). */
.cytui-micro-row.list {
    gap: 0.3em 0.35em;
    flex-wrap: wrap;
    white-space: normal;
    align-content: flex-start;
    overflow: hidden;
}
.cytui-micro-row.sub { padding-left: 1.2em; opacity: 0.72; }
/* the TYPE badge: the mainkey drawn as metaphysics, not prose — a small outlined chip in
   the row's kind colour ('cell' beside Kunzea, 'Artist' beside Fernway, same shape always) */
.cytui-micro-row .ktag {
    flex: none;
    font-size: 0.68em;
    letter-spacing: 0.04em;
    border: 1px solid currentColor;
    border-radius: 3px;
    padding: 0 0.32em;
    opacity: 0.75;
}
/* the has-interior glyph: /*N in the dip's lilac wherever it appears (rows AND chips) —
   one consistent "there's more inside; it pops out with edges" affordance */
.cytui-micro-row .subn {
    flex: none;
    color: rgb(156, 140, 217);
    font-size: 0.8em;
}
.cytui-micro-row .chip .subn { margin-left: 0.25em; font-size: 0.9em; }
.cytui-micro-row .chip {
    flex: none;
    border: 1px solid #3d5a72;
    border-radius: 1em;
    padding: 0 0.5em;
    font-size: 0.82em;
    line-height: 1.5;
    background: rgba(7, 12, 16, 0.55);
    color: inherit;
    font-family: inherit;
}
/* a member-bearing chip is its own pop-out handle */
.cytui-micro-row .chip.hot {
    pointer-events: auto;
    cursor: pointer;
}
.cytui-micro-row .chip.hot:hover { text-shadow: 0 0 7px currentColor; border-color: currentColor; }
/* member|dip rows are the pop-out surf — clickable, everything else stays glass */
.cytui-micro-row.hot {
    pointer-events: auto;
    cursor: pointer;
    font: inherit;
    font-size: inherit;
}
.cytui-micro-row.hot:hover .t { text-shadow: 0 0 7px currentColor; }
.cytui-micro-row.dip {
    opacity: 0.75;
    color: rgb(156, 140, 217);  /* the Stuffzipper /*N lilac — the same handle, new outcome */
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
    min-width: 3.5em;    /* every chunk has body — no hairline slivers */
    min-height: 2em;
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