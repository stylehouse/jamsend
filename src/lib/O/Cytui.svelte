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
    import { GLASS_KINDS } from '$lib/O/glass_kinds'
    import { FACE_MAINKEYS } from '$lib/O/glass_faces'
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

    // the over-time story of model→cells: a bounded ring of what the render pipeline just did.
    //  can't live in w:Voronoiology — this is render-side, and nothing render-side snaps (metaphysics #2).
    //   pixels don't round-trip a fixture, so it's the Cyto twin of reactap: a live-tab-only signal.
    //  surfaced over the runner_ask rails (op:'why'/'shot'); mirrored onto top_House.c.cy_render each push.
    //   a `stuff:0` wave every beat is the empty-world tell — the seed never fired (the F6/VoroScape read).
    type RLog = { t: number, ev: string, [k: string]: any }
    let render_log: RLog[] = []
    let last_settle_t = 0            // performance.now() of the last layoutstop — the "since last shake-out" mark
    const RENDER_LOG_MAX = 48
    function vlog(ev: string, extra: Record<string, any> = {}) {
        render_log.push({ t: Math.round(performance.now()), ev, ...extra })
        while (render_log.length > RENDER_LOG_MAX) render_log.shift()
        try { (H.top_House().c as any).cy_render = render_snapshot() } catch { /* best-effort mirror */ }
    }
    // uncaught page errors ride the SAME film strip (op:'why') — a template-flush throw is
    //  otherwise invisible headless: state updates, vlogs fire, but the DOM silently stops
    //   after the throw point (the "cells but no panes" mystery, 2026-07-14).  Bounded ring
    //    like everything here; window-level, armed once per mount.
    $effect(() => {
        const oe = (e: ErrorEvent) => vlog('jserr', { m: String(e.message ?? e.error ?? '?').slice(0, 140) })
        const or = (e: PromiseRejectionEvent) => vlog('jserr', { m: ('rej: ' + String(e.reason)).slice(0, 140) })
        window.addEventListener('error', oe)
        window.addEventListener('unhandledrejection', or)
        return () => { window.removeEventListener('error', oe); window.removeEventListener('unhandledrejection', or) }
    })
    function render_snapshot() {
        const now = performance.now()
        const base = last_settle_t ? Math.round(last_settle_t) : 0
        return {
            voronoi_on, saw_stuffy, voronoi_pref,       // the gate + its inputs
            seeds: stuff_mounts.size, cells: vcells.length, nodes: cy ? cy.nodes().length : 0,
            vsubs: vsubs.length, vtips: vtips.length, sub_on: subgraph_on,   // ▦ DOM census (chasing the blank glass)
            since_settle_ms: last_settle_t ? Math.round(now - last_settle_t) : null,
            diag_cures,
            // each event's dt = ms since the last layout settle (negative = before it)
            log: render_log.map(r => ({ ...r, dt: base ? r.t - base : null })),
        }
    }

    // F2 — the render's "I've LANDED" signal for the Story Run.  The takeTurns handshake
    //  used to release the Run on a FIXED timer (grawave + dwell); a flood/morph step still
    //   mid-settle got the next wave shoved in — panes re-mounting Stuffing-first, the
    //    end-of-morph blink, "step 3 shows Stuffings before vtuffings + takes extra time".
    //   Now the render stamps the applied step here the moment it is truly at rest — morph
    //    done, no flood 2nd pass owed, not mid diagonal-satan cure — and Cyto's
    //     e_Cyto_animation_request awaits THIS stamp (floored at the dwell, hard-ceiling'd so
    //      it can never wedge the Run) instead of the blind timer.
    //   applied_step is keyed off wave.sc.step_n (the story_step the wave already carries), so
    //    a stamp of cy_settled===story_step means "the render for exactly that step landed".
    //   live .c only, NEVER snapped (metaphysics #2) — a render-side signal like cy_render, so
    //    fixtures don't move.
    let applied_step: number | null = null   // step_n of the wave the render is currently seating
    let flood_pending = false                 // a flood's 2nd free relayout is owed — not settled yet
    function mark_settled() {
        if (applied_step == null) return
        if (dragging || anim_busy || wave_queue.length) return   // still churning waves / motion
        if (flood_pending) return                                // the 2nd free pass hasn't landed
        if (diag_streak > 0) return                              // mid diagonal-satan cure — not a rest
        try { (H.top_House().c as any).cy_settled = applied_step } catch { /* best-effort */ }
        vlog('landed', { step: applied_step })
    }

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
        paint_final(L)   // live cadence — ▦ sub-graphs track too (cached tree + closed math)
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
                mark_settled()   // no-voronoi graph: layoutstop→reveal IS the rest (F2)
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
    //      are sc-copies of the live members.  MERGED in place, never wiped:
    //       the old drop-all+recreate made the mounted Stuffing rebuild its
    //        whole DOM (and pulse its commit spinner) on every membership
    //         change — on a streaming world (chunks landing, Stoker churn)
    //          that was the %gang_of blink loop.  A row whose sc still matches
    //           a member is left untouched — no version bump, no commit — so
    //            only the actual delta reaches the DOM.  Same-sig duplicates
    //             pair off by count (a multiset); merged rows append, so pane
    //              order can drift from gang order after churn — acceptable.
    const gang_mirrors = new Map<string, TheC>()
    function gang_stuff(id: string, src: TheC): TheC {
        const members = (src as any).c?.gang as TheC[] | undefined
        if (!members?.length) return src
        const mirror = gang_mirrors.get(id) ?? _C({ gang_of: Object.keys(src.sc ?? {})[0] ?? 'gang' })
        const sig = (sc: any) => JSON.stringify(sc ?? {})
        const stale = new Map<string, TheC[]>()
        for (const ch of mirror.o()) {
            const s = sig(ch.sc)
            const list = stale.get(s) ?? []
            list.push(ch); stale.set(s, list)
        }
        for (const m of members) {
            const sc: any = {}
            for (const [k, v] of Object.entries(m.sc ?? {}))
                if (typeof v !== 'object' && typeof v !== 'function') sc[k] = v
            if (!stale.get(sig(sc))?.pop()) mirror.i(sc)
        }
        for (const list of stale.values()) for (const ch of list) ch.drop(ch)
        gang_mirrors.set(id, mirror)
        return mirror
    }

    // ── sub-faces: ztuffing hosts registered components ──────────────────────
    //  the node-grain faces rail (create_face_overlay) at the SUB-cell grain: a fold|gang
    //   MEMBER wearing a face (worn sc.face, or imposed FACE_MAINKEYS — believed only when
    //    the commission said useFaces; the flag rides each wave c-side) mounts its component
    //     in a slot along its cell's bottom band instead of reading as text rows.  Mount
    //      once per stable key, reposition per paint, unmount when gone — the gang-mirror
    //       lifecycle.  These els never enter `overlays` (no cy node id), so neither
    //        reposition_overlays nor paint_final's mold ever fights the slots.
    let waves_use_faces = false
    const sub_face_mounts = new Map<string, { app: any, el: HTMLDivElement }>()
    function sub_face_kind(m: TheC): string | null {
        if (!waves_use_faces || !m?.sc) return null
        const kind = m.sc.face != null ? String(m.sc.face)
                   : FACE_MAINKEYS[Object.keys(m.sc)[0] ?? ''] ?? null
        return kind && GLASS_KINDS[kind] ? kind : null
    }
    function sub_faces_sync(wants: { key: string, kind: string, n: TheC,
                                     x: number, y: number, w: number, h: number }[]) {
        const seen = new Set<string>()
        for (const wf of wants) {
            seen.add(wf.key)
            let m = sub_face_mounts.get(wf.key)
            if (!m) {
                if (!overlay_container) continue
                const el = document.createElement('div')
                el.className = 'cyto-overlay face-overlay sub-face'
                overlay_container.appendChild(el)
                if (cy) el.style.fontSize = `${Math.max(6, vknob('stuff.fs', 12) * cy.zoom())}px`
                const app = mount(GLASS_KINDS[wf.kind], { target: el, props: { n: wf.n, H } })
                m = { app, el }
                sub_face_mounts.set(wf.key, m)
            }
            m.el.style.left   = `${wf.x.toFixed(1)}px`
            m.el.style.top    = `${wf.y.toFixed(1)}px`
            m.el.style.width  = `${wf.w.toFixed(1)}px`
            m.el.style.height = `${wf.h.toFixed(1)}px`
        }
        for (const [key, m] of sub_face_mounts) if (!seen.has(key)) {
            try { unmount(m.app) } catch (e) {}
            m.el.remove()
            sub_face_mounts.delete(key)
        }
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
        if (cy) el.style.fontSize = `${Math.max(6, vknob('stuff.fs', 12) * cy.zoom())}px`
        const mem = (H as any).imem('cytostuff:' + stuff_stash_key(source_n))
        const app = mount(Stuffing, { target: el, props: { stuff: gang_stuff(id, source_n), mem, H, self_row: !!self_mode } })
        // grow the node when the Stuffing's rendered size changes — content events only (commits,
        //  zoom font steps), not render frames, so the layout can settle between waves (waitCyto).
        const ro = new ResizeObserver(() => size_stuff_node(id, el))
        ro.observe(el)
        stuff_mounts.set(id, { app, ro })
    }

    // create_face_overlay — the stuff rail generalised: mount a REGISTERED component
    //  (glass_kinds.ts, keyed by the particle's sc.face) instead of a Stuffing.  Registering in
    //   stuff_mounts is what earns the node a voronoi cell + the paint_final mold; the component
    //    self-reacts off H.version, so the mount is once-only like the Stuffing's.
    function create_face_overlay(id: string, source_n: TheC | undefined, kind: string) {
        if (!overlay_container || !source_n) return
        if (overlays.has(id)) return
        const Face = GLASS_KINDS[kind]
        if (!Face) return
        const el = document.createElement('div')
        el.className = 'cyto-overlay face-overlay'
        el.dataset.nodeId = id
        overlay_container.appendChild(el)
        overlays.set(id, el)
        if (cy) el.style.fontSize = `${Math.max(6, vknob('stuff.fs', 12) * cy.zoom())}px`
        const app = mount(Face, { target: el, props: { n: source_n, H } })
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
        const sfs = vknob('stuff.fs', 12)   // once per call — this path runs per pan/zoom frame

        for (const [id, el] of overlays) {
            const node = cy.getElementById(id)
            if (!node.length) { remove_overlay(id); continue }

            // a cell-molded overlay (Stuffing OR face — dataset.molded, stamped by
            //  paint_final) is paint_final's to move — node-centering it here is the
            //   visible jump-to-the-node-and-back between a gesture settling and the
            //    morph re-molding it.  Leave it seated in its cell; clear_voronoi and
            //     the swallowed-cell fallback clear the mark before anything re-centers.
            //      (Was gated on el.style.clipPath — the clip is a knob now, default off.)
            if (el.dataset.molded) continue

            const pos = node.renderedPosition()

            // stuff overlays size THEMSELVES (width/height: max-content) — here we only center
            //  them on the node.  Growing the NODE to wrap the content happens in size_stuff_node,
            //   driven by a ResizeObserver on the overlay (content-change events), NEVER from this
            //    per-frame path — a node.style() write per render frame kept the layout perpetually
            //     energised, so a waitCyto Book never saw the wave settle and wedged between steps.
            if (el.classList.contains('stuff-overlay')) {
                el.style.fontSize = `${Math.max(6, sfs * zoom)}px`
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
            el.style.fontSize  = `${Math.max(6, sfs * zoom)}px`
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
    // ── region washes (Cyto_regions, Slice C) ────────────────────────────────
    //  the grasp (Voro.g Voro_grasp) buckets cells into continuous REGIONS by a
    //   `the:family` key it stamps off-snap (reached via src.c.D).  Where the
    //    ⬡ family hulls stroke one house's OUTER walls, ▧ backs each region with
    //     a translucent FILLED convex hull drawn BENEATH the cells, so same-family
    //      cells read as one continuous space — layout untouched, pure pixels.
    //  Default OFF: when off, nothing new draws and the render is byte-identical.
    //   The bucketing is grasp-fed but null-safe: a cell with no `the:family`
    //    (pre-grasp / non-fold) falls back to its c.fold_kind, else 'misc'.
    let region_pref     = $state<boolean | null>(null)
    const region_on     = $derived(region_pref ?? false)
    let vregions        = $state<{ id: string, d: string, color: string }[]>([])
    const REGION_COLORS = ['#8b6bb7', '#5b9a77', '#b78a5b', '#5b8ab7', '#b75b7a', '#7ab75b']
    // ── ▧ arc-rivers (Slice D) ────────────────────────────────────────────────
    //  the same ▧ toggle that backs a family with a wash also draws ONE big tidy
    //   arc down the middle of its territory — a river of one kind flowing through
    //    the landscape (the zen-garden trail).  Rides on region_on, so ▧ is now
    //     "the regroup face": washes + rivers together, and off = nothing new draws.
    //   The letterform (I|C|S|O) falls out of the fitted arc's curvature, not a
    //    choice; chips are the family's shared trait lined along the path's tangent.
    let vrivers = $state<{
        id: string, d: string, color: string, shape: string,
        chips: { x: number, y: number, ang: number, text: string }[],
    }[]>([])
    // the region a cell belongs to: the grasp's `the:family` awareness value,
    //  reached off the live particle's off-snap D-sphere; null-safe fallback to
    //   the crusher's fold_kind, else 'misc', so every cell buckets somewhere.
    function region_of(id: string): string {
        const src = node_src.get(id) as any
        const fam = src?.c?.D?.o?.({ the: 'family' })?.[0]?.sc?.val
        if (typeof fam === 'string' && fam) return fam
        return (src?.c?.fold_kind as string | undefined) ?? 'misc'
    }
    function toggle_regions() {
        region_pref = !region_on
        const str = (H as any).stashed
        if (str) str.Cyto_regions = region_pref
        if (!region_on) { vregions = []; vrivers = [] }   // ▧ off → wash AND river gone
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
    // ── DRAG THE ARTIST — the crater's IDENTITY is a grab handle wired straight to the cell's
    //  cytoscape node (the human: "make the Artist draggable, wire the drag to the cytoscape node
    //   underneath that cell").  Grabbing sp.id moves the RIGHT node deterministically — a voronoi
    //    seed can sit anywhere inside its cell, so a pass-through canvas grab is ambiguous, but the
    //     pane knows its own node.  node.position + pan_zoom_motion re-tessellates live (the same
    //      path as the gravity brush), so a hand can free a cell trapped by its neighbours.  Window
    //       listeners (not the element's) survive the live re-render the drag itself triggers.
    let vdrag: { node: any, sx: number, sy: number, px: number, py: number, zoom: number } | null = null
    function vsub_move(e: PointerEvent) {
        if (!vdrag || !cy) return
        vdrag.node.position({ x: vdrag.px + (e.clientX - vdrag.sx) / vdrag.zoom,
                              y: vdrag.py + (e.clientY - vdrag.sy) / vdrag.zoom })
        pan_zoom_motion()
    }
    function vsub_drop() {
        window.removeEventListener('pointermove', vsub_move)
        window.removeEventListener('pointerup', vsub_drop)
        window.removeEventListener('pointercancel', vsub_drop)   // touch interrupted — end cleanly too
        vdrag = null
    }
    function vsub_grab(e: PointerEvent, id: string) {
        if (!cy || live_layout || vdrag) return          // a running layout owns positions
        const node = cy.getElementById(id)
        if (!node?.length || node.isParent?.() || is_nucleus(node)) return
        const p = node.position()
        vdrag = { node, sx: e.clientX, sy: e.clientY, px: p.x, py: p.y, zoom: cy.zoom() }
        corr_clear()                                     // a drag re-tessellates → would strand a hover
        window.addEventListener('pointermove', vsub_move)
        window.addEventListener('pointerup', vsub_drop)
        window.addEventListener('pointercancel', vsub_drop)      // no stuck drag if pointerup never comes
        e.stopPropagation(); e.preventDefault()
    }
    let vcells        = $state<{ id: string, d: string, color: string, swapped?: boolean, fog?: number }[]>([])
    let vtips         = $state<{ id: string, x: number, y: number, color: string }[]>([])
    // ── vtuffing: what a pane SAYS (rows from Voro.g's Vtuff_build) ───────────
    //  The engine distils a fold|gang's members into a layout C** (title | shared facts |
    //   spreads-with-chips | member rows | the /*N dip); here we normalise that tree to
    //    plain row descriptors for the ▦ sub-graph below — its ONE consumer.
    //  (The old ▤ face — the same rows chord-fitted as text cards, a hand-rolled
    //   Stuffing-lookalike with k|v|annotation all one muddy string — is DELETED
    //    2026-07-11: its successor landed (the sub-graph speaking Stuffing's own
    //     grammar), and a demoted second face kept resurfacing through the toggles
    //      as the pre-grammar look.  Panes without a sub-graph read as the REAL
    //       Stuffing, molded to the cell; there is no third rendering.)
    type MicroChip = { text: string, n: number, member?: TheC, members?: TheC[], sub?: number, wgt?: number }
    // key|val|pn ride TYPED off the distiller's k/v fields (the Stuffing-shape cut, 2026-07-14) —
    //  text stays the composed display; consumers prefer the typed pair over re-parsing it.
    type VtuffDesc = { text: string, kind: string, color?: string | null, tag?: string, nk?: string,
                       key?: string, val?: string, pn?: number,
                       sub?: number, chips?: MicroChip[], member?: TheC, members?: TheC[], dip?: boolean, wgt?: number }

    // read a bare particle's display name and which key gave it — a render-side reader for any C
    //  with no Vtuffing tree of its own.
    //   used by the loner pane (a %see / beat-wrangler req) and by vtuff_rows' pre-gen-boot fallback.
    //   name = the mainkey's value, else the first of name|title|text|nick|label; namekey = which one won.
    function name_ts(m: any): string {
        const mk = Object.keys(m?.sc ?? {})[0]
        const v = m?.sc?.[mk]
        if (v !== 1 && v != null) return String(v)
        for (const k of ['name', 'title', 'text', 'nick', 'label'])
            if (k !== mk && typeof m?.sc?.[k] === 'string') return m.sc[k]
        return ''
    }
    function namekey_ts(m: any): string {
        const mk = Object.keys(m?.sc ?? {})[0]
        const v = m?.sc?.[mk]
        if (v !== 1 && v != null) return mk
        for (const k of ['name', 'title', 'text', 'nick', 'label'])
            if (k !== mk && typeof m?.sc?.[k] === 'string') return k
        return mk
    }

    // a Vtuffing row's weight, normalised to the 0..100 salience scale the render sizes by.  The grasp
    //  (Voro.g Voro_grasp) stamps real neighbourhood salience (always ≥20); a tree the grasp hasn't
    //   reached yet still carries the distiller's crude 1|2 — read that as "no reading yet": the title
    //    loud-most, all else at the 14pt floor, so a grasp-blind pane still renders sanely (enrich, never require).
    function wgt_norm(w: any, kind: string): number {
        return typeof w === 'number' && w >= 10 ? w
             : kind === 'title' ? 100 : kind === 'dip' ? 10 : 50
    }

    // a pane's rows, normalised to descriptors the fit can lay out.
    //  live path: normalise Voro.g's Vtuffing tree — meaning lives there, per the split.
    //  fallback: before the new gen deposits Vtuff_build, derive a plain title+members+dip right here,
    //   so a pane never degrades to just "Track" — the one place Cytui re-derives meaning, on purpose.
    function vtuff_rows(src: any): VtuffDesc[] {
        const build = (H as any).Vtuff_build
        if (build) {
            const root = build.call(H, src)
            if (!root) return []
            const out: VtuffDesc[] = []
            let memberTag: string | undefined   // the enclosing member row's kind, for sub-row tag hushing
            for (const r of root.o() as any[]) {
                const kind = (r.sc.row as string) ?? 'fact'
                const d: VtuffDesc = { text: String(r.sc.text ?? ''), kind, wgt: wgt_norm(r.sc.wgt, kind) }
                if (r.sc.k != null && (kind === 'fact' || kind === 'spread')) {
                    // a TYPED claim (the Stuffing-shape cut): carry the k/v pair and compose the
                    //  display right here — this IS paint, the one place a string may be born.
                    d.key = String(r.sc.k)
                    if (r.sc.v != null) { d.val = String(r.sc.v); d.text = `${d.key}: ${d.val}` }
                    else if (kind === 'fact' && r.sc.n) { d.pn = Number(r.sc.n); d.text = `${d.key} ×${d.pn}` }
                    else d.text = d.key
                } else if (r.sc.k != null && kind === 'list') {
                    // a list row carries a k too — which key its chips are values of ('title') — but
                    //  its text stays empty: the chips speak.  B0.2 (the first real-world read): this
                    //   branch was MISSING, so an %Artist fold's %Track members lost their title key
                    //    (only fact|spread captured d.key); now the list keeps it, and tag rides below.
                    d.key = String(r.sc.k)
                } else if (r.sc.text == null) {
                    // a TYPED presentation row (the 1b cut): compose its display here too.  A row
                    //  that DOES carry text is an old gen's cached tree (HMR skew) and keeps its
                    //   baked words — enrich, never require.
                    // B0.4: the title is IDENTITY ONLY (name + kind-tag) — the count rides the /*N
                    //  tail (the same root.sc.n), never an ×N on the name that reads as "N such".
                    if (kind === 'title') d.text = String(r.sc.name ?? '')
                    else if (kind === 'member' || kind === 'sub') d.text = String(r.sc.name ?? r.sc.tag ?? '')
                    else if (kind === 'dip') d.text = `/*${root.sc.n ?? ''}`
                }
                if (r.sc.tag) d.tag = String(r.sc.tag)
                // typed member|sub rows carry their kind-tag ALWAYS (honest data); the small chip
                //  BESIDE the text is paint's call: drawn only when a name rides (else the tag IS
                //   the text) and, for a sub, only when its kind differs from its member's (don't
                //    re-say the parent).
                if (r.sc.text == null) {
                    if (kind === 'member') { memberTag = d.tag; if (!r.sc.name) d.tag = undefined }
                    else if (kind === 'sub' && (!r.sc.name || d.tag === memberTag)) d.tag = undefined
                }
                if (r.sc.nk) d.nk = String(r.sc.nk)
                if (r.sc.sub) d.sub = r.sc.sub as number
                if (r.c.member) { d.member = r.c.member; d.color = kind_tint(Object.keys(r.c.member.sc ?? {})[0]) }
                if (kind === 'title') d.color = kind_tint(d.tag ?? src?.c?.fold_kind)
                if (kind === 'dip') d.dip = true
                if (r.c.members) d.members = r.c.members
                const bits = r.o() as any[]
                if (bits.length) d.chips = bits.map((b: any) => ({ text: String(b.sc.v ?? b.sc.text ?? ''), n: (b.sc.n as number) ?? 0, member: b.c.member, members: b.c.members, sub: b.sc.sub as number | undefined, wgt: wgt_norm(b.sc.wgt, 'chip') }))
                out.push(d)
            }
            return out
        }
        const members: any[] | null = src?.c?.gang ?? (src?.c?.stuff && typeof src.o === 'function' ? src.o() : null)
        if (!members?.length) return []
        const t_tag = src?.c?.gang ? (src?.c?.fold_kind as string) : Object.keys(src?.sc ?? {})[0]
        const t_name = src?.c?.gang ? '' : name_ts(src)
        const out: VtuffDesc[] = [{ text: `${t_name ? t_name + '  ' : ''}×${members.length}`,
                                    kind: 'title', tag: t_tag, nk: t_name ? namekey_ts(src) : undefined,
                                    color: kind_tint(t_tag), wgt: 100 }]
        const CAP = 8
        for (const m of members.slice(0, CAP)) {
            const sub = typeof m.o === 'function' ? m.o().length : 0
            const mk = Object.keys(m.sc ?? {})[0]
            const nm = name_ts(m)
            out.push({ text: nm || mk, kind: 'member', member: m, tag: nm ? mk : undefined,
                       sub: sub || undefined, color: kind_tint(mk), wgt: 50 })
        }
        if (members.length > CAP) out.push({ text: `+${members.length - CAP} more`, kind: 'fact', wgt: 20 })
        out.push({ text: `/*${members.length}`, kind: 'dip', dip: true, wgt: 10 })
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

    // the /*N surf — a member row|chip clicked pops THAT node out INTO THE GRAPH; the dip
    //  (member undefined) spills the top-K.  Vtuff_pop stamps the c.popped|c.popped_open
    //   intents and waves a re-scan — never expands inside the pane.  LOUD when the verb
    //    isn't aboard (an OLD gen makes every /*N a silent dead end — say why).
    function micro_click(id: string, member?: TheC) {
        const src = node_src.get(id) as any
        if (!src) return
        const pop = (H as any).Vtuff_pop
        if (!pop) { console.warn('▤ Vtuff_pop not aboard — this tab runs an old gen; reload to arm the /*N surf'); return }
        pop.call(H, src, member)
    }

    // ── H4: the CORRESPONDENCE reveal ── (the human: "there would be mouseover|click handler all
    //  over the tuple, so any one of the v we click on shows what other $v and $k are involved in
    //   it … mouse-over hilight all the data the tuple has, including black blurs over eg %remaster
    //    or %live if it doesn't have them").  Touch a claim chip → the member chips it speaks for
    //     LIGHT, plus every sibling claim sharing a carrier (the one-hop "what else is involved");
    //      touch a member chip → its claims light and every claim it LACKS takes the black blur —
    //       absence smudged in place.  Click PINS a claim chip (a member chip's click stays the
    //        pop surf); scoped to the touched pane, everything else untouched.
    let corr_hot = $state<VStat | null>(null)
    let corr_pin = $state<VStat | null>(null)
    let corr_pane_id = $state<string | null>(null)
    const corr_act = $derived(corr_pin ?? corr_hot)
    // I8: which crater is under the mouse — its hourglass ribbons show, all others stay hidden.
    //  Separate from corr_pane_id (that follows a CHIP hover); this follows the whole cell.
    let ribbon_pane = $state<string | null>(null)
    function corr_over(sp: VSubPane, s: VStat) { corr_hot = s; if (!corr_pin) corr_pane_id = sp.id }
    function corr_out(s: VStat) {
        if (corr_hot === s) corr_hot = null
        if (!corr_pin && !corr_hot) corr_pane_id = null
    }
    function corr_pin_toggle(sp: VSubPane, s: VStat) {
        if (corr_pin === s) { corr_pin = null; if (!corr_hot) corr_pane_id = null }
        else { corr_pin = s; corr_pane_id = sp.id }
    }
    // the ESCAPE catch (the human: "the hover effect can get stuck on … perhaps there's a catch to
    //  escape it?").  A live re-tessellation (spell/drag) destroys a hovered chip mid-hover, so its
    //   mouseleave never fires — and the reveal lights by STABLE refs (corr_hot by particle, the
    //    ribbon by cell id), so it persists.  corr_clear drops the transient reveal; `all` also drops
    //     a deliberate PIN.  Wired to Escape, to leaving the graph, and to a drag start (the biggest
    //      strander) — so there's always a way out.
    function corr_clear(all = false) {
        corr_hot = null
        ribbon_pane = null
        if (all) corr_pin = null
        if (!corr_pin) corr_pane_id = null
    }
    // 1 = lit (involved), -1 = the blur (a correspondence chip NOT involved with the touched one),
    //  0 = untouched chrome (keys without carriers, titles, other panes)
    function corr_mark(sp: VSubPane, s: VStat): number {
        const a = corr_act
        if (!a || sp.id !== corr_pane_id) return 0
        if (s === a) return 1
        if (a.members) {
            if (s.member) return a.members.includes(s.member) ? 1 : -1
            if (s.members) return s.members.some(m => a.members!.includes(m)) ? 1 : -1
            return 0
        }
        if (a.member) {
            if (s.members) return s.members.includes(a.member) ? 1 : -1
            if (s.member) return s.member === a.member ? 1 : -1
            return 0
        }
        return 0
    }

    // ── ▦ the sub-graph: a pane's face as SUB-CELLS (bamboo v2) ──
    //  "sub-voronois to each k and v and whatever they've been combined into": a pane
    //   tessellates ITSELF, cut by the same half-plane power walls as the parent scape,
    //    so the pane is a scape in miniature.  The layout is RADIAL — hierarchy has a
    //     slope and it flows from the core outward: the source's own statement holds the
    //      CENTRE (the %Track C at the centre), its keyed facts belt the middle at their
    //       vein bearings, and its members ring the RIM (all the tracks around the
    //        outside), washed by a radial gradient in their kind's hue — the asymmetric
    //         clue for which way hierarchy runs.  Multiplicities never own a cell: ×N
    //          and the /*N dig ride as superscripts (a member label clicked is the surf —
    //           Vtuff_pop, the seed of click-to-expand).  The pane's molded Stuffing dims
    //            underneath (a crossfade); ▦ off restores it — two pure faces, no third
    //             rendering, and the glass HIDES NOTHING: what can't fit is folded behind
    //              an annotated +N (expandable later), never silently dropped.
    //
    //  Every text on the glass is ONE grammar statement —
    //    [kind badge] [namekey|key] [lilac :] [value] [×N] [/*N]
    //  — a VStat, fitted into its polygon by fit_stat and rendered by the one vstat
    //   snippet.  Keys wear their vein hue and the ':', values stay plain — the
    //    Stuffing's own idiom, so k vs v reads at a glance.  (No % glyph anywhere:
    //     % prefixes a KEY in the house notation, and these are values — the poppable
    //      cue is the hot underline instead.)
    type VLine = { text: string, tl?: number }
    type VStat = { x: number, y: number, fs: number, cls: string,
                   hue?: string,                                        // key|whole-statement colour
                   tag?: string, tagcolon?: boolean, tagtint?: string | null,
                   nk?: string, nkhue?: string,
                   key?: string, colon?: boolean,
                   val?: string, tl?: number,                           // head value + its stretch
                   sup?: string, subn?: number,
                   lines?: VLine[],                                     // wrapped continuation
                   rot?: number,                                        // baseline angle (deg) — the tuples face
                   box?: boolean,                                       // a KIND label in its own subcell (a tinted pill)
                   member?: TheC,
                   members?: TheC[] }                                   // the claim's carriers — the correspondence
    type VWall = { d: string, hue: string, cls: string, grad?: boolean, fillid?: string }
    type VSubPane = { id: string, clipid: string, clip: string, color: string, tint: string,
                      walls: VWall[], spokes: { d: string, hue: string }[], stats: VStat[],
                      grad?: { cx: number, cy: number, r: number, hue: string },
                      lgrads?: { id: string, x1: number, y1: number, x2: number, y2: number,
                                 hue: string, o0?: number, o1?: number }[],
                      ribbons?: VWall[],                                 // H5 hourglass — hover-gated (I8)
                      dip?: { x: number, y: number, text: string },
                      hid?: { x: number, y: number, n: number },
                      com?: { x: number, y: number, n: number },
                      roomy?: boolean }                                 // seated with room to spare — the spell's lift signal
    let vsubs = $state<VSubPane[]>([])
    let sub_on_ids = new Set<string>()   // panes whose Stuffing is dimmed under sub-cells
    let subgraph_pref = $state<boolean | null>(null)
    const subgraph_on  = $derived(subgraph_pref ?? true)
    function toggle_subgraph() {
        subgraph_pref = !subgraph_on
        const sts = (H as any).stashed
        if (sts) sts.Cyto_subgraph = subgraph_pref
        if (!subgraph_pref) {
            for (const id of sub_on_ids) {
                const mel = overlays.get(id); if (mel) mel.style.opacity = ''
            }
            sub_on_ids = new Set(); vsubs = []
        } else voronoi_soon()
    }
    const dom_id = (s: string) => s.replace(/[^a-zA-Z0-9_-]/g, '_')

    // rows → TUPLE groups (owner: "they need to start taking on tuple geometry … I can't
    //  tell which v the year|habit k are connected to").  A keyed row is a GROUP — the key
    //   labels a REGION and its values live inside it: a spread ('year' + chips) is a
    //    many-leaf group, a fact ('year: 2007') a one-leaf group, a presence fact
    //     ('remaster ×2') a leaf-less key group wearing its count.  MEMBERS come back
    //      separately — they ring the pane's rim, they are not a region among regions.
    //       No silent caps: past 12 leaves the tail folds to a '+K' leaf (in-glass, so
    //        it's an annotated fold, not a drop).  Leaves sort numeric-aware, so
    //         '1998 · 2007 · 2019' reads in ORDER in every pane it appears in — the
    //          same meaning lands the same way (alignment of meanings).
    type VSubLeaf  = { tag?: string, tint?: string | null, val?: string, sup?: string, subn?: number,
                       member?: TheC, members?: TheC[], hw: number, hh: number,
                       wgt?: number }   // grasp salience 0..100 (Slice B2): how much this value sets its cell apart
    type VSubTuple = { key?: string, sup?: string, tag?: string, lead?: boolean, members?: TheC[],
                       leaves: VSubLeaf[], wgt?: number }
    function subgraph_tuples(descs: VtuffDesc[]): { keyed: VSubTuple[], members: VSubLeaf[] } {
        const keyed: VSubTuple[] = []
        const members: VSubLeaf[] = []
        const leaf = (it: Partial<VSubLeaf>): VSubLeaf => {
            const len = (it.val?.length ?? 0) + (it.tag ? it.tag.length * 0.7 : 0) + (it.sup ? 2 : 0)
            return { ...it, hw: Math.max(14, len * 2.8), hh: 6 } as VSubLeaf
        }
        for (const d of descs) {
            if (d.kind === 'title' || d.dip) continue
            if (d.kind === 'fact') {
                if (d.key != null) {   // typed k/v (the Stuffing-shape cut) — no re-parse, ever
                    // d.tag = WHOSE LEVEL the claim lives at (G1): a fact distilled off the %Tracks
                    //  wears their kind, so paint can keep the grouping boundary — never seat a
                    //   track's %year in the artist's own band.  d.members = the claim's carriers
                    //    (the correspondence H4 lights on hover).
                    if (d.val != null) { keyed.push({ key: d.key, tag: d.tag, wgt: d.wgt, leaves: [leaf({ val: d.val, members: d.members, wgt: d.wgt })] }); continue }
                    keyed.push({ key: d.key, tag: d.tag, members: d.members, sup: d.pn ? `×${d.pn}` : undefined, wgt: d.wgt, leaves: [] })
                    continue
                }
                // pre-typed fallback (an old gen's rows): the legacy text parse
                const i = d.text.indexOf(': ')
                if (i > 0) { keyed.push({ key: d.text.slice(0, i), wgt: d.wgt, leaves: [leaf({ val: d.text.slice(i + 2), wgt: d.wgt })] }); continue }
                const m = /^(.+?)\s*×(\d+)$/.exec(d.text)   // presence key counted: 'remaster ×2'
                if (m) { keyed.push({ key: m[1], sup: `×${m[2]}`, wgt: d.wgt, leaves: [] }); continue }
                keyed.push({ key: d.text, wgt: d.wgt, leaves: [] })
            } else if (d.kind === 'spread') {
                // REAL loudness (Slice B2): the grasp weighed each chip by how rare its value is
                //  across the neighbourhood — a value only this cell carries towers, one everyone
                //   shares recedes.  The tuple wears the row weight (the grasp set it to its loudest chip).
                const chips = d.chips ?? []
                keyed.push({ key: d.key ?? d.text, tag: d.tag, wgt: d.wgt, leaves: chips.map(ch =>
                    leaf({ val: ch.text, sup: ch.n > 1 ? `×${ch.n}` : undefined, member: ch.member,
                           members: ch.members, subn: ch.sub, wgt: ch.wgt })) })
            } else if (d.kind === 'list') {
                const lv = (d.chips ?? []).map(ch => leaf({ val: ch.text, sup: ch.n > 1 ? `×${ch.n}` : undefined,
                                                            member: ch.member, subn: ch.sub, wgt: ch.wgt }))
                if (d.tag != null)
                    // a fold's members are a DIFFERENT kind with their own naming key (an %Artist by
                    //  its %Tracks' title — Voro.g tags the list ONLY then): a KEYED, kind-tagged row
                    //   that LEADS, identity before the shared facts (B0.1/B0.2/B0.3).  A SAME-kind
                    //    list (flora species of one genus) stays bare trailing members — the human's
                    //     liked read ('Metrosideros / … / propinqua rhamnoides …'), not a redundant
                    //      'Metrosideros:' keyed row.
                    keyed.push({ key: d.key, tag: d.tag, lead: true, wgt: d.wgt, leaves: lv })
                else
                    // bare epithets of the family ITSELF (the flora species names) — flow at the end
                    for (const l of lv) members.push(l)
            } else {   // member | sub
                members.push(leaf({ val: d.text, tag: d.tag, tint: d.color, member: d.member, subn: d.sub, wgt: d.wgt }))
            }
        }
        for (const g of [{ leaves: members }, ...keyed]) if (g.leaves.length > 12) {
            const cut = g.leaves.length - 11
            g.leaves.length = 11
            g.leaves.push(leaf({ val: `+${cut}` }))
        }
        for (const g of keyed) if (!g.lead)   // a lead list keeps gather order (like the members it is)
            g.leaves.sort((a, b) => (a.val ?? '').localeCompare(b.val ?? '', undefined, { numeric: true }))
        return { keyed, members }
    }

    // the VEIN hue: one golden-angle slot per KEY NAME, global across panes — 'year' wears
    //  the same colour in every pane it appears in, so a key reads as a vein racing around
    //   the whole scape (owner: "a vein of Years I can see racing around").  The same slot
    //    also fixes the group's COMPASS ANGLE inside its pane, so the vein aligns spatially.
    const vein_slot = new Map<string, number>()
    let vein_seq = 0
    function vein_of(key: string): { hue: number, ang: number } {
        if (!vein_slot.has(key)) vein_slot.set(key, vein_seq++)
        const h = (vein_slot.get(key)! * 137.508) % 360
        return { hue: Math.round(h), ang: h * Math.PI / 180 }
    }

    // the widest chord in a horizontal band of a convex polygon — where a label breathes.
    //  Fixes the owner's "Artist:Palegold shoved into a corner": the naive top chord of a
    //   slant-walled cell is a sliver; sampling the band finds the room.
    function wide_chord(poly: {x:number,y:number}[], y0: number, y1: number, samples = 7) {
        let best: { x0: number, x1: number, y: number, w: number } | null = null
        for (let i = 0; i < samples; i++) {
            const y = y0 + (y1 - y0) * (samples === 1 ? 0.5 : i / (samples - 1))
            const ch = poly_chord(poly, y)
            if (ch && (!best || ch[1] - ch[0] > best.w)) best = { x0: ch[0], x1: ch[1], y, w: ch[1] - ch[0] }
        }
        return best
    }

    // ── the statement engine: ONE fitter for every text on the glass ──
    //  fit_stat finds the widest chord of a band, then the biggest fs whose greedy
    //   word-wrap fits, then hands every line its chord as a textLength target —
    //    Wes-Wilson: the words take ALL the room their glass offers, stretching to
    //     the walls (clamped so the warp stays lovely, not silly).
    const GLY = 0.62                     // em-width of one glyph in the mono face
    function stretch(room: number, len: number, fs: number): number | undefined {
        const nat = GLY * fs * len
        if (room <= 0 || len < 2) return undefined
        const tl = Math.max(Math.min(room, nat * 1.45), nat * 0.9)
        return Math.abs(tl - nat) < 2 ? undefined : Math.round(tl)
    }
    type VHead = { tag?: string, tagcolon?: boolean, tagtint?: string | null,
                   nk?: string, nkhue?: string, key?: string, colon?: boolean, sup?: string }
    function head_len(h: VHead, has_val: boolean): number {
        return (h.tag ? h.tag.length * 0.78 + 1 : 0)
             + (h.nk ? h.nk.length + 2 : 0)
             + (h.key ? h.key.length + (h.colon ? 2 : 0.5) : 0)
             + (h.sup ? h.sup.length * 0.7 : 0)
             + (h.tag && !h.nk && has_val ? 1.5 : 0)
    }
    // ── the loudness bands (Slice A: text stretch-ups) ──
    //  A statement's font band is set by how LOAD-BEARING it is, not by whatever
    //   happens to fit.  14pt is the hard legibility floor for anything a reader
    //    must actually READ — the identity of a pane, a member's name, the loudest
    //     fact.  A band with lo≥14 DRIVES shedding rather than clipping: fit_stat
    //      clips to '…' the moment even lo won't fit, and fit_ident reads that as
    //       "shed grammar and try leaner" — so a sliver that can't hold '14pt Artist
    //        name: Fernway' says '14pt Fernway' instead of a 7pt run-on.  Only genuine
    //         DECORATION (ring keys, superscripts, the /*N dig) keeps a sub-14 floor.
    //   REAL LOUDNESS now (Slice B2): the grasp (Voro.g Voro_grasp) reads the whole neighbourhood and
    //    stamps each statement 0..100 by how much it SETS ITS CELL APART — a fact every cell shares is
    //     quiet, one only this cell makes towers.  That weight rides the Vtuffing row's wgt field into
    //      band_for below.  The nucleus/title stay pinned VERY (identity out-shouts any fact); a
    //       grasp-blind pane falls back to the 14pt floor via wgt_norm, so nothing regresses.
    const BAND_VERY = { lo: 16, hi: 26 }   // the_very_* — the loudest, tied to the biggest cell
    const BAND_LOUD = { lo: 14, hi: 18 }   // the_* / load-bearing fact — at or above the 14pt floor
    const BAND_DECO = { lo: 7,  hi: 16 }   // decoration — ring keys, presence sups, folds
    // the grasp's weight → a fit band.  ≥80 towers (the defining trait / a the_very), ≥45 sits at the
    //  14pt floor (load-bearing), below recedes into decoration.  hiCap keeps each callsite's own
    //   ceiling (a rim member may go bigger than an inline fact), so the weight moves the FLOOR, not the
    //    roof — the meaning hierarchy becomes the size hierarchy without any one statement clipping.
    const band_for = (w: number | undefined, hiCap = 26): { lo: number, hi: number } => {
        const s = typeof w === 'number' ? w : 50
        if (s >= 80) return { lo: 16, hi: hiCap }
        if (s >= 45) return { lo: 14, hi: hiCap }
        return { lo: 7, hi: Math.min(hiCap, 15) }
    }
    function fit_stat(poly: {x:number,y:number}[], head: VHead, val: string | undefined,
                      opts: { band?: [number, number], lo?: number, hi?: number,
                              maxlines?: number } = {}): VStat | null {
        const pys = poly.map(p => p.y)
        const py0 = Math.min(...pys), phgt = Math.max(...pys) - py0
        const [f0, f1] = opts.band ?? [0.32, 0.68]
        const band = wide_chord(poly, py0 + phgt * f0, py0 + phgt * f1, 7)
        if (!band || band.w < 18) return null
        const lo = opts.lo ?? 7, hi = opts.hi ?? 16
        const hlen = head_len(head, !!val)
        const words = val ? val.split(/\s+/) : []
        // biggest fs whose greedy wrap fits the band — head + first words share line 1
        let fs = lo, first = '', lines: VLine[] = []
        for (let t = hi; t >= lo; t--) {
            const perline = band.w * 0.94 / (GLY * t)
            const maxl = Math.max(1, Math.min(opts.maxlines ?? 5,
                                              Math.floor((phgt * 0.72) / (t * 1.2))))
            const acc: string[] = []
            let cur = '', cap = perline - hlen, ok = true
            for (const wd of words) {
                const cand = cur ? cur + ' ' + wd : wd
                if (cand.length <= cap) { cur = cand; continue }
                if (!cur) { ok = false; break }
                acc.push(cur); cur = wd; cap = perline
                if (acc.length >= maxl) { ok = false; break }
            }
            if (!ok && t > lo) continue
            acc.push(cur)
            if (!ok) {
                const last = acc.length - 1
                acc[last] = acc[last].slice(0, Math.max(1, Math.floor(cap) - 1)) + '…'
            }
            fs = t; first = acc.shift() ?? ''
            lines = acc.map(text => ({ text, tl: stretch(band.w * 0.94, text.length, t) }))
            break
        }
        if (!words.length)
            fs = Math.max(lo, Math.min(hi, band.w * 0.8 / (GLY * Math.max(3, hlen))))
        return { x: (band.x0 + band.x1) / 2,
                 y: band.y - (lines.length * fs * 1.2) / 2 + fs * 0.35, fs, cls: '',
                 ...head,
                 val: first || undefined,
                 tl: first ? stretch(band.w * 0.94 - hlen * GLY * fs, first.length, fs) : undefined,
                 lines: lines.length ? lines : undefined }
    }
    const nk_hue = (nk: string | undefined) =>
        nk ? `hsl(${vein_of(nk).hue}, 52%, 68%)` : undefined
    // an IDENTITY statement sheds grammar before it sheds the name: full head →
    //  tag-only → bare value.  'Artist name: Fernway' in a sliver becomes 'Fernway',
    //   never 'Artist name: …' — the identity is the one thing a pane must say.
    function fit_ident(poly: {x:number,y:number}[], head: VHead, val: string | undefined,
                       opts: { band?: [number, number], lo?: number, hi?: number,
                               maxlines?: number } = {}): VStat | null {
        const heads: VHead[] = [head,
            { tag: head.tag, tagcolon: !!val, tagtint: head.tagtint, sup: head.sup },
            { sup: head.sup }]
        let last: VStat | null = null
        for (const h of heads) {
            const s = fit_stat(poly, h, val, opts)
            if (!s) return null              // hairline — nothing fits at any slimness
            last = s
            if (!val) return s
            const tail = s.lines?.length ? s.lines[s.lines.length - 1].text : (s.val ?? '')
            if (s.val && !tail.endsWith('…')) return s
        }
        return last
    }
    // the annotated fold: +N in the pane's corner says N statements didn't fit THIS
    //  beat's glass (crowded out or degraded away) — never a silent drop; the Stuffing
    //   (▦ off) and the /*N dig still hold everything.  Expandable eventually.
    function hid_mark(poly: {x:number,y:number}[], n: number): { x: number, y: number, n: number } {
        const pb = Math.max(...poly.map(p => p.y))
        for (const dy of [12, 18, 26]) {
            const chd = poly_chord(poly, pb - dy)
            if (chd && chd[1] - chd[0] > 24) return { x: chd[0] + 6, y: pb - dy + 4, n }
        }
        const cx2 = poly.reduce((a, p) => a + p.x, 0) / poly.length
        return { x: cx2, y: pb - 8, n }
    }

    // shared power-cut: tessellate a convex polygon by weighted seeds (the parent scape's
    //  wall math, reused at every level of the tuple recursion).  Returns null slots for
    //   crowded-out seeds.
    function power_cells(poly0: {x:number,y:number}[], pts: {x:number,y:number}[],
                         radii: number[], gap: number): ({x:number,y:number}[] | null)[] {
        return pts.map((p, i) => {
            let poly: {x:number,y:number}[] = poly0
            for (let j = 0; j < pts.length; j++) {
                if (j === i) continue
                const dx = pts[j].x - p.x, dy = pts[j].y - p.y
                const d = Math.hypot(dx, dy)
                if (d < 0.5) continue
                const ux = dx / d, uy = dy / d
                const t = (d * d + radii[i] * radii[i] - radii[j] * radii[j]) / (2 * d)
                poly = clip_halfplane(poly, { x: p.x + ux * t, y: p.y + uy * t }, { x: ux, y: uy })
                if (poly.length < 3) return null
            }
            if (poly.length < 3) return null
            const vmx = poly.reduce((a, q) => a + q.x, 0) / poly.length
            const vmy = poly.reduce((a, q) => a + q.y, 0) / poly.length
            return poly.map(q => {
                const dx = q.x - vmx, dy = q.y - vmy, dd = Math.hypot(dx, dy)
                const k = dd > gap ? 1 - gap / dd : 0
                return { x: vmx + dx * k, y: vmy + dy * k }
            })
        })
    }

    // ── coagulate geometry (G3/H1, the human: "each C coagulate … should have quite a smooth
    //  shape within the cell") — small pure moves that round a hard half-plane cut into a blob.
    // corner-cutting: convex in → convex out; two passes read as smooth
    function chaikin(poly: {x:number,y:number}[], iters = 2): {x:number,y:number}[] {
        let p = poly
        for (let t = 0; t < iters; t++) {
            const q: {x:number,y:number}[] = []
            for (let i = 0; i < p.length; i++) {
                const a = p[i], b = p[(i + 1) % p.length]
                q.push({ x: a.x * 0.72 + b.x * 0.28, y: a.y * 0.72 + b.y * 0.28 })
                q.push({ x: a.x * 0.28 + b.x * 0.72, y: a.y * 0.28 + b.y * 0.72 })
            }
            p = q
        }
        return p
    }
    // grow (d>0) | shrink (d<0) a polygon along its centroid rays — the coagulate insets a
    //  breath off its band's walls before the corner-cutting rounds it
    function poly_grow(poly: {x:number,y:number}[], d: number): {x:number,y:number}[] {
        const gx = poly.reduce((a, p) => a + p.x, 0) / poly.length
        const gy = poly.reduce((a, p) => a + p.y, 0) / poly.length
        return poly.map(p => {
            const dx = p.x - gx, dy = p.y - gy, dd = Math.hypot(dx, dy) || 1
            const k = Math.max(0, (dd + d) / dd)
            return { x: gx + dx * k, y: gy + dy * k }
        })
    }

    // ── the ▦ face parameter — a PARAMETER, not a bar button (the human, 2026-07-14:
    //  "a parameter (not in the UI because we'll probably take all this away to another
    //   UI, it's prototyping)").  'tuples' is the NEW DEFAULT: the pane speaks SNAP
    //    NOTATION — squished rows, aligned to the cell's own best wall.  'star' keeps
    //     the radial gem (nucleus/belt/rim) for the A/B.  Flip live over the ask rails
    //      (runner_shot --arm --face=vsub:star) or the Cyto_vsub_face stash.
    let vsub_face = $state<'tuples' | 'star' | 'phi'>('tuples')

    // ── LIVE KNOBS — the tunable constants of the ▦ layer, addressable at runtime ──
    //  The Attractor Ground (spec/Attractor_todo.md): a face is a builder from (cells,
    //   descs, KNOBS) → layers, and a judge tunes those knobs live to compete entries on
    //    the same data.  A knob is a plain number with a registered DEFAULT; an override
    //     lives in vknobs and rides the stash (Cyto_knobs) so it survives a reload.  vknob()
    //      is called in hot paint paths, so it must be cheap — one map read, register-on-miss.
    //   ADD a knob by reading it at its use site (vknob('crater.rmin', 24)); the first call
    //    registers the default, and every call after is the live value.  Read ONCE at the top
    //     of a function into a local — never per-iteration.
    const vknob_defs: Record<string, number> = {}
    let vknobs = $state<Record<string, number>>({})
    function vknob(name: string, def: number): number {
        if (vknob_defs[name] === undefined) vknob_defs[name] = def
        return vknobs[name] ?? def
    }

    // the WRITING DIRECTION of a tuples pane: text hangs off the cell's OWN shape —
    //  "they should mostly favour the shape of their cell, to align text with the
    //   biggest top-left-est cell wall" (the human).  Longest wall wins, weighted
    //    toward the top-left and away from unreadable steepness; the angle is
    //     normalised upright (a baseline never runs upside-down) and quantised to
    //      15° so near-agreeing neighbours agree EXACTLY — rows read parallel across
    //       the glass with no cross-cell solve ("something like but possibly not
    //        exactly cs").  A wall steeper than 45° is REJECTED outright, not just
    //         penalised — past that the notation tips toward vertical and reads badly
    //          (the human saw a ~150°-down baseline: a +60° wall the soft penalty let
    //           win); when no wall qualifies the pane stays horizontal (best = 0).
    function tuple_frame(poly: {x:number,y:number}[]): number {
        const xs = poly.map(p => p.x), ys = poly.map(p => p.y)
        const bx0 = Math.min(...xs), bw = Math.max(...xs) - bx0 || 1
        const by0 = Math.min(...ys), bh = Math.max(...ys) - by0 || 1
        let best = 0, score = -1
        for (let i = 0; i < poly.length; i++) {
            const a = poly[i], b = poly[(i + 1) % poly.length]
            const len = Math.hypot(b.x - a.x, b.y - a.y)
            if (len < 8) continue
            let th = Math.atan2(b.y - a.y, b.x - a.x)
            if (th > Math.PI / 2) th -= Math.PI            // upright: (-90°, 90°]
            else if (th <= -Math.PI / 2) th += Math.PI
            if (Math.abs(th) > Math.PI / 4 + 1e-3) continue   // >45° tips toward vertical — leave it horizontal
            const mx = (a.x + b.x) / 2, my = (a.y + b.y) / 2
            const tl = 1 - ((mx - bx0) / bw + (my - by0) / bh) / 2     // 1 at the top-left corner
            const read = 0.35 + 0.65 * Math.cos(th) * Math.cos(th)    // a steep baseline reads badly
            const s = len * (0.5 + tl) * read
            if (s > score) { score = s; best = th }
        }
        return Math.round(best / (Math.PI / 12)) * (Math.PI / 12)
    }

    // one pane as SNAP NOTATION — the 'tuples' face (the human, 2026-07-14: "ALL the
    //  info, arranged so I can read the notation that looks similar to snap but with
    //   multiple rows squished together … some venn diagramming or similar visual
    //    tricks (like treeing — it's VERY BASIC!)").  The distiller already DID the
    //     venn and the treeing: a fact row is the family's ∀-intersection said once,
    //      a spread its variance with counts, the title its kind said once — so this
    //       face simply SAYS the tree as stacked rows, the way a snap would read:
    //         Kunzea ×14            ← the title line (kind badge · name · ×N)
    //         habit: vine           ← a fact, the venn-intersection
    //         year: 1998 ×2 2007    ← a spread, key once + its value chips
    //         figaro tenuifolium…   ← the members, flowing
    //       left-aligned down the baseline of the cell's best wall (tuple_frame),
    //        wrapped lines indenting one em (the treeing).  Keys keep their vein hue
    //         and the lilac colon; keyed rows land in GLOBAL vein order so the same
    //          key sits at the same rank in every pane (meaning-alignment across
    //           cells without any solve).  Whatever the glass can't seat this beat
    //            folds into +N — annotated, never silent.  Rows sit UNDER the 14pt
    //             floor by design here: the notation wants density (the title keeps
    //              the loud floor; a loud claim's row still out-sizes its siblings).
    type VAtom = Partial<VStat> & { len: number, afs: number }
    // one atom's on-screen width estimate (em units) — pure, so the whole-cell pane and a crater
    //  sub-cell build atoms identically.
    const atom = (a: Partial<VStat>, afs: number): VAtom => ({ ...a, afs,
        len: (a.tag ? a.tag.length * 0.78 + 1 : 0)
           + (a.nk ? a.nk.length + 2 : 0)
           + (a.key ? a.key.length + (a.colon ? 1.5 : 0.5) : 0)
           + (a.val?.length ?? 0)
           + (a.sup ? a.sup.length * 0.7 : 0) + (a.subn ? 3 : 0) })
    // the salience → row size map ("squished": density beats the 14pt floor here)
    const row_fs = (w?: number) => { const s = w ?? 50; return s >= 80 ? 15 : s >= 45 ? 11.5 : 9 }

    // pane_rows — flow pre-built ROWS (each a line of atoms) into a convex polygon: rotate the
    //  baseline to the polygon's biggest top-left wall (tuple_frame), seat each line-BOX between
    //   the chords at its top AND bottom edge (a sloping wall can't clip the ascenders — the human:
    //    "a line obscured by the cellwall above it"), and INFLATE the whole stack to fill the spare
    //     height (the human: "inflating into its potential space").  This is the pure geometry
    //      behind BOTH the whole-cell tuples pane AND each B1 crater sub-cell — so a %Track's own
    //       sub-space aligns to its OWN wall and fills its OWN room.  rows[0] is load-bearing: if it
    //        can't seat, the pane degrades (null).  Stats return in ORIGINAL coords, pivoted cx,cy.
    function pane_rows(poly: {x:number,y:number}[], cx: number, cy: number, rows: VAtom[][],
                       opts?: { toppad?: number, inflate?: boolean, capfs?: number, norot?: boolean }):
            { stats: VStat[], hid: number, used: number, avail: number } | null {
        if (!rows.length) return null
        // norot keeps the baseline HORIZONTAL instead of tilting to the biggest wall — the identity
        //  arm wants it (a name reads level, never rotated down into a sharp corner of a slanted
        //   slice: the human's "the Artist … drifted down into a sharp corner of the cell").
        const th = opts?.norot ? 0 : tuple_frame(poly)
        const cosR = Math.cos(-th), sinR = Math.sin(-th)
        const rpoly = poly.map(p => ({ x: cx + (p.x - cx) * cosR - (p.y - cy) * sinR,
                                       y: cy + (p.x - cx) * sinR + (p.y - cy) * cosR }))
        const cosB = Math.cos(th), sinB = Math.sin(th)
        const deg = Math.abs(th) > 1e-3 ? +(th * 180 / Math.PI).toFixed(1) : undefined
        const rys = rpoly.map(p => p.y)
        const ry0 = Math.min(...rys), ry1 = Math.max(...rys)
        const availH = ry1 - ry0 - 6
        const toppad = opts?.toppad ?? 4
        const line_span = (ytop: number, lh: number): [number, number] | null => {
            const pad = Math.min(3, lh * 0.22)
            const a = poly_chord(rpoly, ytop + pad), b = poly_chord(rpoly, ytop + lh - pad)
            if (!a || !b) return null
            const lo = Math.max(a[0], b[0]), hi = Math.min(a[1], b[1])
            return hi - lo > 6 ? [lo, hi] : null
        }
        const layout = (zoom: number, tp = toppad): { stats: VStat[], hid: number, used: number, avail: number } | null => {
            const stats: VStat[] = []
            // the IDENTITY CEILING (G2, the human: "some of these Artist,name bits are really
            //  small. they must be the biggest!"): opts.capfs bounds the whole pane from outside
            //   (a crater member never out-sizes its header), and once the lead row has flowed,
            //    its landed size caps every later row — whatever shrank the identity shrinks the
            //     rest under it, so hierarchy survives a tight cell.
            let cap = opts?.capfs ?? Infinity
            let ycur = ry0 + tp, hid = 0, dry = false
            // one LINE of atoms, flowing left→right along the rotated chord, wrapping to an
            //  indented continuation; every atom is its own VStat so a member chip keeps its click.
            const flow = (atoms: VAtom[]) => {
                if (!atoms.length) return
                if (dry) { hid += atoms.length; return }
                const lh = Math.max(...atoms.map(a => Math.min(a.afs * zoom, cap))) * 1.24
                let ch = line_span(ycur, lh)
                while (!ch && ycur + lh < ry1 - 3) { ycur += lh * 0.5; ch = line_span(ycur, lh) }
                if (!ch || ycur + lh > ry1 - 3) { dry = true; hid += atoms.length; return }
                let x = ch[0] + 5, right = ch[1] - 4, fresh = true
                const indent = Math.min(atoms[0].afs * zoom, cap) * 1.4
                for (const a of atoms) {
                    if (dry) { hid++; continue }                       // the pane ran out mid-line
                    let afs = Math.min(a.afs * zoom, cap), w = a.len * GLY * afs
                    if (!fresh && x + w > right) {                     // wrap — the treeing indent
                        ycur += lh
                        const nch = line_span(ycur, lh)
                        if (!nch || ycur + lh > ry1 - 3) { dry = true; hid++; continue }
                        x = nch[0] + 5 + indent; right = nch[1] - 4
                    }
                    const room = right - x
                    if (w > room) {                                    // over-wide atom — shrink, floor 7
                        afs = Math.max(7, room / (GLY * a.len))
                        w = a.len * GLY * afs
                    }
                    const { len: _l, afs: _f, ...rest } = a
                    const rx = x + w / 2, ry = ycur + lh * 0.8
                    stats.push({ ...rest, fs: afs, rot: deg,
                                 x: cx + (rx - cx) * cosB - (ry - cy) * sinB,
                                 y: cy + (rx - cx) * sinB + (ry - cy) * cosB } as VStat)
                    x += w + afs * 0.55
                    fresh = false
                }
                ycur += lh + 1.5
            }
            for (let ri = 0; ri < rows.length; ri++) {
                flow(rows[ri])
                if (ri === 0) {
                    if (!stats.length) return null                     // the lead line didn't seat — degrade
                    cap = Math.min(cap, Math.max(...stats.map(s => s.fs)) * 0.92)
                }
            }
            return { stats, hid, used: ycur - ry0 - tp + toppad, avail: availH }
        }
        // measure at 1×, then INFLATE — only when nothing was crowded out and the fill grows;
        //  damped (·0.7) so the re-wrap doesn't overflow, kept only if it too seats everything.
        //   The ceiling sat at 1.35 for one round (H3 uniformity) and the human raised it ("it
        //    still wants more maxing out the space it has … things inline-text-looking up against
        //     the ceiling"): evenness now comes from the growth SPELL equalising the CELLS, so the
        //      text is free to fill what its cell actually holds; a narrow cell still WRAPS (H2)
        //       before it shrinks.
        let res = layout(1), zused = 1
        if (!res) return null
        if (opts?.inflate !== false && res.hid === 0 && res.used > 8 && availH / res.used > 1.15) {
            const zoom = Math.min(2.0, 1 + (availH / res.used - 1) * 0.7)
            const up = layout(zoom)
            if (up && up.stats.length && up.hid === 0) { res = up; zused = zoom }
        }
        // the CENTRAL UNFOLDMENT (the human: "some kind of typography-spatialising for maximum
        //  central unfoldment"): whatever height the block didn't use splits above|below — the
        //   whole stack re-seats dropped by half the spare, kept only if every atom still lands
        //    (a convex cell is widest in its middle, so the drop usually HELPS the seat; when a
        //     shape disagrees, the ceiling seat stands).
        const spare = availH - res.used
        if (spare > 10) {
            const down = layout(zused, toppad + spare / 2)
            if (down && down.hid === res.hid && down.stats.length === res.stats.length) res = down
        }
        return res
    }

    // zone_seat — COMPLETELY DIFFERENT text hosting: the space determines the font size,
    //  not the other way round.  Divide the polygon's height into zones proportional to
    //   weight, size each zone's text to FILL its territory (min of height-fill and
    //    width-fill), placed on its OWN measured chord.  No flowing, no wrapping.
    //  Three rules keep text either fully visible or honestly folded, never clipped
    //   mid-word (the human's 'Artist name:Palego' clip):
    //    (1) SAME-CHORD sizing AND placement — a zone is sized against, and placed on, the
    //         wide_chord's own y/x; sizing width === placement width, so a slant wall can
    //          never cut a row it wasn't measured for.
    //    (2) SPLIT-DON'T-SHRINK — a zone whose estimated landed fs would fall below
    //         zone.fsfloor with ≥2 atoms splits at the tag|name seam (atom0 | rest) instead
    //          of squashing onto one line; the identity lands as 'Artist' then 'name: Palegold',
    //           both BIG.  (Plus the old GROUP_MAX chunking of long member lists.)
    //    (3) EXACT-OR-FOLDED — if a sized row still overruns its chord, shrink ONLY the last
    //         atom to a 7pt floor (pane_rows' rule); if it still won't fit, drop trailing atoms
    //          into hid.  A glyph never paints past the wall.
    //  Return type matches pane_rows so callers switch without structural change.
    function zone_seat(
            poly: {x:number,y:number}[], cx: number, cy: number,
            zones: { atoms: VAtom[], weight: number }[],
            opts?: { toppad?: number, botpad?: number, capfs?: number }
    ): { stats: VStat[], hid: number, used: number, avail: number } | null {
        const GROUP_MAX = Math.max(1, Math.round(vknob('zone.groupmax', 5)))
        const FSFLOOR = vknob('zone.fsfloor', 10.5)      // below this a splittable zone splits
        const FSCEIL = vknob('zone.fsceil', 24)          // the per-row size ceiling
        const ys0 = poly.map(p => p.y)
        const y0 = Math.min(...ys0) + (opts?.toppad ?? 4)
        const y1 = Math.max(...ys0) - (opts?.botpad ?? 4)
        const H = y1 - y0
        if (H < 12) return null
        // one zone's text width in em (atoms + inter-atom gaps) — the sizing basis
        const zone_em = (atoms: VAtom[]) =>
            atoms.reduce((s, a) => s + a.len, 0) * GLY + Math.max(0, atoms.length - 1) * 0.55
        // an optimistic landed fs for a zone owning `share` of H, measured against the poly's
        //  widest chord anywhere (best case for width) — used only to DECIDE splitting.
        const wideAll = wide_chord(poly, y0, y1, 7)
        const wAll = wideAll ? wideAll.w - 12 : 0
        const est_fs = (atoms: VAtom[], share: number) => {
            const em = zone_em(atoms)
            const fh = share * H * 0.70
            const fw = em > 0 && wAll > 0 ? wAll / em : FSCEIL
            return Math.min(fh, fw, FSCEIL)
        }
        // EXPAND (split-don't-shrink) over a work queue: chunk a long list to GROUP_MAX, then
        //  keep splitting a still-too-small multi-atom zone at its atoms[0]|atoms[1..] seam.
        const tw0 = zones.reduce((s, z) => s + (z.atoms.length ? z.weight : 0), 0) || 1
        const queue = zones.filter(z => z.atoms.length)
            .map(z => ({ atoms: z.atoms, weight: z.weight }))
        const exp: { atoms: VAtom[], weight: number }[] = []
        let guard = 0
        while (queue.length && guard++ < 400) {
            const z = queue.shift()!
            if (z.atoms.length > GROUP_MAX) {          // long list → equal GROUP_MAX chunks
                const n = Math.ceil(z.atoms.length / GROUP_MAX), sw = z.weight / n
                for (let i = 0; i < n; i++)
                    queue.push({ atoms: z.atoms.slice(i * GROUP_MAX, (i + 1) * GROUP_MAX), weight: sw })
                continue
            }
            // would this zone land below the floor while it still has a seam to break at?
            if (z.atoms.length >= 2 && est_fs(z.atoms, z.weight / tw0) < FSFLOOR) {
                queue.push({ atoms: z.atoms.slice(0, 1), weight: z.weight * 0.5 },
                           { atoms: z.atoms.slice(1),    weight: z.weight * 0.5 })
                continue
            }
            exp.push(z)
        }
        if (!exp.length) return null
        const tw = exp.reduce((s, z) => s + z.weight, 0) || 1
        const stats: VStat[] = []
        let hid = 0, ycur = y0
        let cap = opts?.capfs ?? Infinity
        for (const zone of exp) {
            const zh = H * zone.weight / tw
            // SAME CHORD for sizing AND placement: measure the widest chord in the band, size
            //  the row to it, and seat the baseline on THAT chord's own y (clamped so the row's
            //   fs*1.24 box sits inside the band) — no second, narrower placement chord to overrun.
            const best = wide_chord(poly, ycur, ycur + zh, 6)
            if (!best || best.w < 12) { hid += zone.atoms.length; ycur += zh; continue }
            const avail_w = best.w - 12
            const text_em = zone_em(zone.atoms)
            const fs_h = zh * 0.70
            const fs_w = text_em > 0 ? avail_w / text_em : FSCEIL
            let fs = Math.min(fs_h, fs_w, cap, FSCEIL)
            if (fs < 7) { hid += zone.atoms.length; ycur += zh; continue }
            // identity ceiling: content zones must not exceed the identity's font size.  A floor
            //  of 10 keeps content legible even when a long identity compresses to near 7pt.
            if (cap === Infinity) cap = Math.max(fs, 10)
            // baseline on the wide chord's own y, box kept inside [ycur, ycur+zh]
            const box = fs * 1.24
            const ry = Math.min(Math.max(best.y, ycur + box * 0.8), ycur + zh - box * 0.2)
            // EXACT-OR-FOLDED: if the sized line still overruns (a splitless zone can), shrink the
            //  LAST atom to a 7pt floor; if it STILL overruns, drop trailing atoms into hid.
            const seat = zone.atoms.map(a => ({ a, fs }))
            const line_px = () => seat.reduce((s, e) => s + e.a.len * GLY * e.fs, 0)
                                + Math.max(0, seat.length - 1) * fs * 0.55
            while (seat.length && line_px() > avail_w) {
                const last = seat[seat.length - 1]
                const others = line_px() - last.a.len * GLY * last.fs
                const room = avail_w - others
                const shrunk = last.a.len > 0 ? room / (GLY * last.a.len) : 0
                if (shrunk >= 7) { last.fs = shrunk; break }
                seat.pop(); hid++                       // can't fit even at 7 — honestly fold it
            }
            if (!seat.length) { ycur += zh; continue }
            let x = best.x0 + Math.max(6, (best.w - line_px()) / 2)
            for (const e of seat) {
                const aw = e.a.len * GLY * e.fs
                if (aw < 0.5) { hid++; continue }
                const { len: _l, afs: _af, ...rest } = e.a
                stats.push({ ...rest, fs: e.fs, x: x + aw / 2, y: ry } as VStat)
                x += aw + e.fs * 0.55
            }
            ycur += zh
        }
        return stats.length ? { stats, hid, used: ycur - y0, avail: H } : null
    }

    // keyed_rows — the keyed claims as rows, banded by GRASP LEVEL (G1: "two different C/C levels
    //  cannot share data descriptions"): the container's own untagged facts first, then the member
    //   band — the lead list (their identity) followed by THEIR tagged facts, each wearing the kind
    //    chip so the boundary reads even flat.  A stable partition keeps sc order within each band.
    //     Every claim atom carries its members (the correspondence H4/H5 light up).
    function keyed_rows(keyed: VSubTuple[], kind: string | undefined): VAtom[][] {
        const rows: VAtom[][] = []
        for (const g of keyed) vein_of(g.key ?? '')
        const band = (g: VSubTuple) => g.lead ? 1 : g.tag ? 2 : 0
        const order = [...keyed].sort((a, b) => band(a) - band(b))
        // the kind badge is said ONCE per run (the human: "we say Track,title:… then also
        //  Track,year:… where the laters should just be eg year:…") — the band sort clusters
        //   a kind's rows, so the first wears the badge and the rest ride bare under it.
        let ptag: string | undefined
        for (const g of order) {
            const fs = row_fs(g.wgt)
            const hue = `hsl(${vein_of(g.key ?? '').hue}, 52%, 60%)`
            const showtag = g.tag && g.tag !== ptag ? g.tag : undefined
            if (g.tag) ptag = g.tag
            // the KIND ('Track') is its OWN boxed atom — a subcell, not inline text (the human:
            //  "always put Artist/Track in a subcell — they look like properties otherwise"); the
            //   key ('title:') flows after it as a separate atom, so the seam gets real spacing
            //    ('Track title:', never the run-together 'Tracktitle:').  The dedup still holds:
            //     only the first row of a tag run mints the boxed kind.
            const as: VAtom[] = []
            if (showtag) as.push(atom({ tag: showtag, tagtint: kind_tint(showtag),
                                        cls: 'vsub-gkey' }, fs))
            as.push(atom({ key: g.key, colon: g.leaves.length > 0, sup: g.sup,
                           members: g.members, hue, cls: 'vsub-gkey' }, fs))
            for (const l of g.leaves)
                as.push(atom({ val: l.val, sup: l.sup, subn: l.subn, member: l.member,
                               members: l.members, tag: l.tag, tagtint: l.tint, cls: 'vsub-label' },
                             (l.wgt ?? 50) >= 80 ? fs * 1.3 : fs))
            rows.push(as)
        }
        return rows
    }

    // tuple_rows — the tuples ROWS for one family: title (identity, loud), keyed rows (keyed_rows),
    //  then bare members.  A pure row-builder (no geometry), so a crater's header uses the same
    //   voice as a whole-cell pane.
    function tuple_rows(head: VHead, tname: string, keyed: VSubTuple[], members: VSubLeaf[],
                        tint: string, kind: string | undefined): VAtom[][] {
        const rows: VAtom[][] = []
        // the title line — identity stays loud, and it WRAPS at its grammar seam instead of
        //  shrinking (H2, the human: "does it know you can wrap Artist\nname:Palegold etc"): the
        //   kind badge and the name are SEPARATE atoms, so a narrow cell breaks between them and
        //    'name: Palegold' lands on the next line at full size (the flow's treeing indent).
        //     B0.4 holds: no ×N on the name — the count is the /*N tail.
        const trow: VAtom[] = []
        if (head.tag) trow.push(atom({ tag: head.tag,   // the container kind — a plain colour-coded word
                                       tagtint: tint, cls: 'vsub-ntitle' }, 16))
        if (tname || head.nk || head.sup)
            trow.push(atom({ nk: head.nk, nkhue: head.nkhue, val: tname || undefined, sup: head.sup,
                             cls: 'vsub-ntitle' }, 16))
        rows.push(trow.length ? trow
                              : [atom({ ...head, val: tname || undefined, cls: 'vsub-ntitle', tagtint: tint }, 16)])
        // a homogeneous gang's bare members ARE the genus's instances (each a %Genus:value), so they
        //  flow DIRECTLY under the identity — the genus's actual content — and their shared|partial
        //   traits come AFTER, reading as "across these", never ABOVE as if the genus itself carried
        //    them (the human, 2026-07-15: "we show Coprosma / woodystem / habit:shrub|vine / propinqua
        //     / rhamnoides, which is a lie given the data is eg %Coprosma:propinqua").  The distiller
        //      already emits this order (Vtuff_default: title → member_rows → keyrows); tuple_rows used
        //       to REVERSE it (facts led — a holdover from when they were the CONTAINER's own).  A
        //        cross-kind fold is untouched: its members ride a LEAD tuple inside `keyed`, so
        //         `members` here is empty and the identity-then-shared-facts order stands.
        if (members.length)
            rows.push(members.map(l => atom({ val: l.val, sup: l.sup, subn: l.subn, member: l.member,
                                              tag: l.tag && l.tag !== kind ? l.tag : undefined,
                                              tagtint: l.tint, cls: 'vsub-label' }, row_fs(l.wgt))))
        rows.push(...keyed_rows(keyed, kind))
        return rows
    }

    // H5 — the hourglass ribbon: a band from a claim chip to a member chip it speaks for, pinched
    //  to a waist at the midpoint (both edges pass through the same point) — wide where the words
    //   are, nothing in between, so the link reads without a boxy band covering the pane.
    function hourglass(a: VStat, b: VStat): string {
        const half = (s: VStat) => Math.max(3.5, ((s.val ?? s.key ?? '··').length * GLY * (s.fs ?? 9)) * 0.32)
        const wa = half(a), wb = half(b)
        const ay = a.y - (a.fs ?? 9) * 0.32, by = b.y - (b.fs ?? 9) * 0.32
        const mx = (a.x + b.x) / 2, my = (ay + by) / 2
        return `M${(a.x - wa).toFixed(1)},${ay.toFixed(1)}Q${mx.toFixed(1)},${my.toFixed(1)} ${(b.x - wb).toFixed(1)},${by.toFixed(1)}`
             + `L${(b.x + wb).toFixed(1)},${by.toFixed(1)}Q${mx.toFixed(1)},${my.toFixed(1)} ${(a.x + wa).toFixed(1)},${ay.toFixed(1)}Z`
    }
    // the static correspondence pass: for every laid-out claim chip, a faint ribbon to each member
    //  chip it involves.  Capped — past the cap the hover reveal carries the correspondence alone.
    function corr_ribbons(stats: VStat[], fallback: string, cap = 14): VWall[] {
        const bym = new Map<TheC, VStat>()
        for (const s of stats) if (s.member) bym.set(s.member, s)
        if (!bym.size) return []
        const out: VWall[] = []
        for (const s of stats) {
            if (!s.members?.length) continue
            for (const m of s.members) {
                const t = bym.get(m)
                if (!t) continue
                if (out.length >= cap) return out
                out.push({ d: hourglass(s, t), hue: s.hue ?? fallback, cls: 'vsub-hour' })
            }
        }
        return out
    }

    function tuple_pane(c: VCell, head: VHead, tname: string, keyed: VSubTuple[],
                        members: VSubLeaf[], tint: string, kind: string | undefined):
            { pane: VSubPane, hid: number } | null {
        const rows = tuple_rows(head, tname, keyed, members, tint, kind)
        // zone_seat: identity row gets zone.identw weight (it IS the cell), content rows share the rest.
        const identw = vknob('zone.identw', 3), roww = vknob('zone.roww', 1.5)
        const zones = rows.map((atoms, i) => ({ atoms, weight: i === 0 ? identw : roww }))
        const res = zone_seat(c.inset, c.acx, c.acy, zones)
        if (!res) return null
        return { pane: { id: c.id, clipid: `vsubclip-${dom_id(c.id)}`, clip: poly_d(c.inset),
                         color: c.color, tint, walls: [], spokes: [], stats: res.stats,
                         roomy: res.hid === 0 && res.used < res.avail * vknob('spell.roomy', 0.42) }, hid: res.hid }
    }

    // ── THE C-SPACE CRATER — ONE per cell ── (B1 2026-07-14, corrected by the human the same day:
    //  "I didn't intend for there to be a crater per C (ie tuple), they were going to be an entire
    //   Stuffing+Stuffusion (that's all things at a location and all groupings of those things), so
    //    just one in each cell … so we can conserve Track,title: and so forth".)  A cross-kind FOLD
    //     cell splits ONCE: the HEADER strip speaks the container's level (identity + its own facts
    //      — G1's boundary), and ONE smooth COAGULATE below holds the whole member band — the
    //       DISTILLED rows, compression conserved ('Track title:' said once, never per member).
    //        Which %title goes with which %year is the CORRESPONDENCE layer's job (H4 hover/click +
    //         H5 hourglass ribbons), not spatial repetition.  Programmatic, no second cytoscape;
    //          a tight cell stays flat (tuple_pane).
    let vsub_craters = $state(true)   // A/B the craters against flat tuples: runner_shot --face=craters:0

    function crater_pane(c: VCell, head: VHead, tname: string, keyed: VSubTuple[],
                         tint: string, kind: string | undefined): { pane: VSubPane, hid: number } | null {
        const lead = keyed.find(g => g.lead)
        const mem = lead ? lead.leaves.filter(l => l.member) : []
        if (mem.length < 1) { crater_skips.nofold++; return null }   // no cross-kind fold structure — flat tuples
        // G1's boundary: untagged rows are the CONTAINER's (they ride the header); the lead list +
        //  every tagged row is the MEMBERS' level and lives in the coagulate.
        const shared = keyed.filter(g => !g.lead && !g.tag)
        const memb = keyed.filter(g => g.lead || g.tag)
        let A2 = 0
        for (let i = 0; i < c.inset.length; i++) {
            const p = c.inset[i], q = c.inset[(i + 1) % c.inset.length]; A2 += p.x * q.y - q.x * p.y
        }
        const R = Math.sqrt(Math.abs(A2) / 2 / Math.PI)
        // a C-cradle nucleus insets on THREE sides, so it needs a touch more cell than a flat band;
        //  a smaller fold reads better flat (the spell grows a borderline one until the C fits).
        if (R < vknob('crater.rmin', 24)) { crater_skips.small++; return null }   // too small to draw a legible C
        // ── THE C-CRADLE (the human, 2026-07-15: "a standard C-shaped crater … the Artist wraps the
        //  members in a C") — the coagulate is a NUCLEUS inset toward the centre-right, and the cell's
        //   OWN Artist tint wraps it on THREE sides: the TOP arm holds the identity, the LEFT spine and
        //    BOTTOM lip close the C, and the C opens to the right (the cell's own wall).  "A cell-wall
        //     around its nucleus."  The identity sits at one end BY CONSTRUCTION, so same-kind cells
        //      huddle their Artist level with no chord search (the old huddle is now the C's geometry).
        const ys = c.inset.map(p => p.y), xs = c.inset.map(p => p.x)
        const cy0 = Math.min(...ys), cy1 = Math.max(...ys), CH = cy1 - cy0
        const cx0 = Math.min(...xs), cx1 = Math.max(...xs), CW = cx1 - cx0
        // the top arm holds the identity (room for its H2 wrap — kind on one line, 'name: Riverine'
        //  on the next); the bottom arm is a thin lip; the left arm is the C's spine.  All are
        //   fractions of the cell, so the whole C scales with the growth spell.
        const ahTop = Math.min(CH * 0.46, Math.max(38, 16 + (1 + shared.length) * 15))
        const ahBot = Math.min(CH * 0.20, 22)
        const aw    = Math.min(CW * 0.30, Math.max(18, CW * 0.14))
        const yTop = cy0 + ahTop, yBot = cy1 - ahBot, xLeft = cx0 + aw
        const cen = (poly: {x:number,y:number}[]) =>
            ({ x: poly.reduce((a, p) => a + p.x, 0) / poly.length, y: poly.reduce((a, p) => a + p.y, 0) / poly.length })
        // the identity's arm (the top band) and the nucleus (below the top arm, above the bottom lip,
        //  right of the left spine — open to the cell's right wall).
        const headerPoly = clip_halfplane(c.inset, { x: c.acx, y: yTop }, { x: 0, y: 1 })      // y ≤ yTop
        let coagBox = clip_halfplane(c.inset, { x: c.acx, y: yTop }, { x: 0, y: -1 })           // y ≥ yTop
        coagBox = clip_halfplane(coagBox, { x: c.acx, y: yBot }, { x: 0, y: 1 })                // y ≤ yBot
        coagBox = clip_halfplane(coagBox, { x: xLeft, y: c.acy }, { x: -1, y: 0 })              // x ≥ xLeft
        if (headerPoly.length < 3 || coagBox.length < 3) { crater_skips.geo++; return null }
        const walls: VWall[] = []
        const stats: VStat[] = []
        let hid = 0
        // the header identity (the top arm) — its landed size is the CEILING for the nucleus (G2:
        //  the identity "must be the biggest!").
        let hcap = 16
        {
            const hc = cen(headerPoly)
            const hrows = tuple_rows(head, tname, shared, [], tint, kind)
            const hzones = hrows.map((atoms, i) => ({ atoms, weight: i === 0 ? vknob('zone.identw', 3) : vknob('zone.roww', 1.5) }))
            const hres = zone_seat(headerPoly, hc.x, hc.y, hzones)
            if (!hres) { crater_skips.geo++; return null }   // the arm can't seat even one line — un-drawable
            const hts = hres.stats.filter(s => s.cls === 'vsub-ntitle')
            const htitle = hts.length ? Math.min(...hts.map(s => s.fs ?? 0)) : 0
            if (hts.length && htitle < vknob('crater.hfloor', 9)) { crater_skips.header++; return null }   // identity too small to crater
            hcap = htitle || 16
            stats.push(...hres.stats)
            hid += hres.hid
        }
        // the COAGULATE nucleus (the TRACK basin): one smooth shape in the members' kind tint — the
        //  STRONG level boundary ("two different C/C levels cannot share data descriptions").
        const mtint = (mem[0].member ? kind_tint(Object.keys(mem[0].member.sc ?? {})[0]) : null) ?? c.color
        const coag = chaikin(poly_grow(coagBox, -3), 2)
        if (coag.length < 3) { crater_skips.geo++; return null }
        // the fill is a LINEAR gradient transparent at the nucleus TOP (the identity seam) deepening
        //  down, + an INNER SHADOW on that top edge, so the nucleus reads as sunk INTO the cradle.
        const gid = `vcoag-${dom_id(c.id)}`
        const ymax = Math.max(...coag.map(p => p.y)), ymin = Math.min(...coag.map(p => p.y))
        // ── THE ARTIST BASIN (outer crater) — an EXPLICIT inset lining of the whole cell, so the
        //  container reads as its OWN carved bowl, DRAWN rather than leaning on the flat cell
        //   background (the human, 2026-07-15: "don't rely on the outer cell, draw a crater that
        //    lines it ... trying to get one around the Artist as well as Track").  A soft top-edge
        //     shadow (the carved lip) + two stepped rim contours in the container tint; the Track
        //      nucleus nests INSIDE, so basin-within-basin IS the Artist⊃Track nesting, drawn not
        //       implied.  Insets are px so they hold at every cell size (R≥40 leaves room for -7).
        const abgid = `vabas-${dom_id(c.id)}`
        const abLip = chaikin(poly_grow(c.inset, -3), 1)
        const abStep = chaikin(poly_grow(c.inset, -7), 1)
        const acy0 = Math.min(...c.inset.map(p => p.y)), acy1 = Math.max(...c.inset.map(p => p.y))
        const lgrads = [{ id: abgid, x1: c.acx, y1: acy0, x2: c.acx,
                          y2: Math.min(acy1, acy0 + 46), hue: '#000', o0: 0.20, o1: 0 },
                        { id: gid, x1: c.acx, y1: ymin, x2: c.acx, y2: ymax, hue: mtint },
                        { id: gid + 's', x1: c.acx, y1: ymin, x2: c.acx,
                          y2: Math.min(ymax, ymin + 30), hue: '#000', o0: 0.30, o1: 0 }]
        walls.push({ d: poly_d(abLip), hue: 'none', cls: 'vsub-abasinsh', fillid: abgid },
                   { d: poly_d(abLip),  hue: tint,   cls: 'vsub-abasin' },
                   { d: poly_d(abStep), hue: tint,   cls: 'vsub-abasin2' })
        // the Track nucleus, nested INSIDE the Artist basin.  Its rim is the container tint too — the
        //  member-tint fill plus the two basins' nesting carry the level distinction now.
        walls.push({ d: poly_d(coag), hue: tint, cls: 'vsub-coag', fillid: gid },
                   { d: poly_d(coag), hue: 'none', cls: 'vsub-coagsh', fillid: gid + 's' })
        // the member band flows INSIDE the nucleus — the distilled rows, capped under the identity.
        const cc2 = cen(coag)
        const nrows = keyed_rows(memb, kind)
        const nzones = nrows.map(atoms => ({ atoms, weight: vknob('zone.roww', 1.5) }))
        const bres = zone_seat(coag, cc2.x, cc2.y, nzones, { capfs: hcap * 0.9 })
        if (!bres) { crater_skips.geo++; return null }   // the nucleus can't seat — flat fallback
        stats.push(...bres.stats)
        hid += bres.hid
        // H5 — hourglass ribbons: each claim chip reaches for the member chips it speaks for
        //  ("which %title correspond to which %year"), a band pinched to a waist in the claim's
        //   hue.  HIDDEN until the crater is hovered (I8, the human: "not there until you mouse
        //    over the cell they're in … one more layer of stuff") — they'd clutter the resting
        //     glass (30 ribbons on a 5-Artist scape); the hover is the moment you're asking.
        const ribbons = R > 90 ? corr_ribbons(bres.stats, mtint) : []
        crater_ok++
        return { pane: { id: c.id, clipid: `vsubclip-${dom_id(c.id)}`, clip: poly_d(c.inset),
                         color: c.color, tint, walls, spokes: [], stats, lgrads, ribbons,
                         roomy: hid === 0 && bres.used < bres.avail * vknob('spell.roomy', 0.42) }, hid }
    }

    // nucleus_pane — the DEGENERATE pane: no structure worth tessellating (a bare loner,
    //  a one-fact fold, a sliver), so the whole cell speaks ONE grammar statement, value
    //   word-wrapped into the glass (a %see sentence fills its pane).  A pane too hairline
    //    to carry even one word keeps its Stuffing (never blank glass).  Whatever the
    //     statement can't say is the CALLER's to count into the +N fold mark.
    function nucleus_pane(c: VCell, tint: string, head: VHead, val: string): VSubPane | null {
        // the whole pane's ONE identity — load-bearing, so it lives at the 14pt floor and
        //  sheds grammar (via fit_ident) before it shrinks under it; a hairline that can't
        //   hold even the bare value at 14pt returns null and keeps its Stuffing.
        const s = fit_ident(c.inset, head, val || undefined, { ...BAND_LOUD, hi: BAND_VERY.hi, maxlines: 5 })
        if (!s) return null
        s.cls = 'vsub-ntitle'; s.tagtint = tint
        return { id: c.id, clipid: `vsubclip-${dom_id(c.id)}`, clip: poly_d(c.inset),
                 color: c.color, tint, walls: [], spokes: [], stats: [s] }
    }

    // ── ϕ THE GOLDEN LETTERING LAYER (face 'phi') ── (the human, 2026-07-17: "cast a phi
    //  sunflower grid onto the cells, assign continuous spaces across the grids with another
    //   bit of give+take basically ignoring cell boundaries, then we completely obscure what
    //    we have drawn so far with this other... labels stretched onto a phi spiral! with
    //     connective tissue showing expandy regions" — and the why: "phi is easy to see kinks
    //      in but not overly griddy, we can probably communicate pretty well a warping
    //       data-landscape").
    //  ϕ v2 (the human, 2026-07-17: "the center of the sunflower is off the screen, and we're
    //   dealing with a gently curving phi grid, which we assign runs of dots on to chunks of UI
    //    we want to fit there... 'Artist name:Vox' wants to be all in a line, Track** is below
    //     and indented... dragging the Artist phi blobule should still move the cyto node...
    //      blinklessly stream through the display layers... it gets small text too easily. we
    //       need more confidence about fitting the text should be able to really max it out").
    //  The pole is OFF-SCREEN (phi.pole_dist·half-diagonal at bearing phi.pole_ang) so every
    //   groove crossing the viewport is a gentle near-parallel smile-arc — no tight turns.  A
    //    cell's labels claim as ONE C-BLOCK, snap-notation-shaped: the TITLE whole on one groove,
    //     each child line INDENTED onto the adjacent groove that is screen-DOWN of the title
    //      (phi.indent em).  The whole block is claim-tested at each candidate anchor; a block
    //       that won't seat retries with fewer children (fold the tail into +N), down to
    //        title-only, else the cell folds entirely.  Sizing is INVERTED: fs is the LARGEST
    //         that fills the free gap on the groove (capped phi.fsceil, floored phi.fsfloor →
    //          smaller folds instead) — the human's "really max it out".  A title may claim TWO
    //           grooves (phi.titlegrooves) for a bigger cap.  The ledger stays TOTAL-spiral-angle
    //            intervals (big r → tiny angular spans, exact overlap check), so text can NEVER
    //             obscure text.  STABLE IDENTITY: pathids are deterministic (vphi-cellid-slug),
    //              and a module-level phi_prev seats each label at its previous interval first —
    //               so a drag re-validates in place instead of reshuffling every arc (the blink
    //                fix: the old global-seq pathids renamed every arc → full DOM recreation).
    const PHI_G = 17                                     // groove pitch px (label fs capped below it)
    type PhiArc = { pathid: string, d: string, fs: number, cls: string, tint: string,
                    k?: string, khue?: string | null, text: string, tl?: number, cellid: string }
    let vphi = $state<{ lattice: string, arcs: PhiArc[], ties: { d: string, tint: string }[],
                        folds: { id: string, x: number, y: number, n: number, tint: string }[],
                        labels: number, folded: number, held: number, moved: number } | null>(null)
    // hysteresis across rebuilds: a label's last claimed interval, keyed by its stable pathid.
    //  Each build re-seats a label at its previous [t0,t1] before searching (if still free), so a
    //   drag re-validates in place — no global reshuffle, no blink.  Replaced wholesale each build.
    let phi_prev = new Map<string, { t0: number, t1: number }>()
    const phi_boost = new Set<string>()                  // cells the human expanded (chip click)
    function phi_expand(id: string) {
        if (phi_boost.has(id)) phi_boost.delete(id); else phi_boost.add(id)
        voronoi_soon()                                   // the same repaint the runner ops ride
    }
    function phi_build(cells: VCell[],
                       dmap: Map<string, { descs: VtuffDesc[], tint: string, fkind?: string }>,
                       qmap: Map<string, Set<string>>): typeof vphi {
        const live = cells.filter(c => dmap.has(c.id))
        if (!live.length) return null
        // knobs read ONCE at the top (hot paint path — never a per-iteration map read)
        const G = vknob('phi.pitch', PHI_G)              // groove pitch px
        const phi_cap = Math.round(vknob('phi.cap', 9))          // labels per cell (resting)
        const phi_boostcap = Math.round(vknob('phi.boostcap', 22)) // labels per boosted cell
        const POLE_DIST = vknob('phi.pole_dist', 2.5)    // pole displacement in bbox half-diagonals
        const POLE_ANG = vknob('phi.pole_ang', 90)       // pole bearing deg (90 = straight down)
        const INDENT_EM = vknob('phi.indent', 1.5)       // child indent in em of the title fs
        const STICKY = vknob('phi.sticky', 1.6)          // a held label may sit this × its normal budget
        const REACH = vknob('phi.reach', 2.2)            // per-label distance budget factor
        const TITLE_GROOVES = Math.max(1, Math.round(vknob('phi.titlegrooves', 2))) // grooves a title may span
        const FSCEIL = vknob('phi.fsceil', 26)           // gap-sized fs ceiling
        const FSFLOOR = vknob('phi.fsfloor', 9)          // below this the line folds instead
        // the spiral pole sits OFF-SCREEN: the glass bbox centre displaced POLE_DIST half-diagonals
        //  at bearing POLE_ANG (90 = down in screen coords → grooves are gentle smile-arcs stacked
        //   vertically, big r everywhere so every angular span is tiny and near-parallel).
        const hxs = live.map(c => c.acx), hys = live.map(c => c.acy)
        const bx0 = Math.min(...hxs), bx1 = Math.max(...hxs)
        const by0 = Math.min(...hys), by1 = Math.max(...hys)
        const bcx = (bx0 + bx1) / 2, bcy = (by0 + by1) / 2
        const halfdiag = Math.max(G * 6, 0.5 * Math.hypot(bx1 - bx0, by1 - by0))
        const par = POLE_ANG * Math.PI / 180
        const px = bcx + Math.cos(par) * POLE_DIST * halfdiag
        const py = bcy + Math.sin(par) * POLE_DIST * halfdiag
        const R_of = (t: number) => G * t / (2 * Math.PI)
        const T_of = (r: number) => r * 2 * Math.PI / G
        // ONE ledger for the whole spiral — claimed [t0,t1] in total angle.  Turns differ by
        //  2π, so only true same-groove neighbours can ever collide, and they show here.  With an
        //   off-screen pole every r is big → every span px/r is tiny, so a groove crosses the
        //    viewport as an almost-straight arc but the exact-interval overlap check is unchanged.
        const claimed: [number, number][] = []
        // the containing gap of a bearing on ONE groove turn k: the free [lo,hi] the point sits in,
        //  measured in total angle on that turn.  Sizing reads the gap so a line MAXES OUT (fills it).
        const gap_at = (tc: number): { lo: number, hi: number } => {
            let lo = -Infinity, hi = Infinity
            for (const [a, b] of claimed) {
                if (b <= tc) { if (b > lo) lo = b }
                else if (a >= tc) { if (a < hi) hi = a }
                else return { lo: tc, hi: tc }           // tc lands inside a claim — no gap
            }
            return { lo, hi }
        }
        const free = (t0: number, t1: number) => !claimed.some(([a, b]) => t0 < b && a < t1)
        // one cell's labels off its Vtuffing descs — the SAME distilled voice the panes speak.  A
        //  cell claims as ONE C-BLOCK: the TITLE whole on one line (tag + name together, never split
        //   across grooves), the rest INDENTED below it (facts loud→quiet, then members).
        type PL = { cls: string, k?: string, khue?: string | null, text: string, wgt: number,
                    tint: string, slug: string }
        const cell_labels = (c: VCell): { title: PL | null, children: PL[], extra: number } => {
            const dm = dmap.get(c.id)!
            const quiet = qmap.get(c.id)
            const seen = new Map<string, number>()       // per-cell dedup for identical slugs
            const slug_of = (cls: string, key: string): string => {
                const base = dom_id(cls + '-' + key).slice(0, 40)
                const n = (seen.get(base) ?? 0); seen.set(base, n + 1)
                return n ? `${base}~${n}` : base
            }
            let title: PL | null = null
            const children: PL[] = []
            for (const d of dm.descs) {
                if (d.dip) continue
                const cid = claim_id(d)
                if (cid && quiet?.has(cid)) continue     // the river says this one
                if (d.kind === 'title') {
                    title = { cls: 'vsub-phit', k: d.tag, khue: d.tag ? kind_tint(d.tag) : dm.tint,
                              text: d.text, wgt: 200, tint: dm.tint,
                              slug: slug_of('vsub-phit', (d.tag ?? '') + d.text) }
                } else if (d.kind === 'fact' || d.kind === 'spread') {
                    const key = d.key ?? d.text
                    let txt = d.kind === 'fact'
                        ? (d.val ?? (d.pn ? `×${d.pn}` : ''))
                        : (d.chips ?? []).map(ch => ch.n > 1 ? `${ch.text} ×${ch.n}` : ch.text).join('  ')
                    if (txt.length > 30) txt = txt.slice(0, 28) + '…'
                    children.push({ cls: 'vsub-phif', k: key, khue: `hsl(${vein_of(key).hue}, 52%, 60%)`,
                                    text: txt, wgt: d.wgt ?? 50, tint: '#b9b9c6',
                                    slug: slug_of('vsub-phif', key + txt) })
                } else if (d.kind === 'list') {
                    for (const ch of d.chips ?? []) {
                        const t = ch.n > 1 ? `${ch.text} ×${ch.n}` : ch.text
                        children.push({ cls: 'vsub-phim', text: t, wgt: ch.wgt ?? 40,
                                        tint: (d.tag ? kind_tint(d.tag) : null) ?? dm.tint,
                                        slug: slug_of('vsub-phim', t) })
                    }
                } else {   // member | sub
                    children.push({ cls: 'vsub-phim', text: d.text, wgt: d.wgt ?? 40,
                                    tint: d.color ?? dm.tint, slug: slug_of('vsub-phim', d.text) })
                }
            }
            children.sort((a, b) => b.wgt - a.wgt)        // loud → quiet under the title
            const CAP = Math.max(1, (phi_boost.has(c.id) ? phi_boostcap : phi_cap) - (title ? 1 : 0))
            const extra = Math.max(0, children.length - CAP)
            if (extra) children.length = CAP
            return { title, children, extra }
        }
        const arcs: PhiArc[] = [], ties: { d: string, tint: string }[] = []
        const folds: { id: string, x: number, y: number, n: number, tint: string }[] = []
        let total = 0, folded = 0, held = 0, moved = 0
        const next_prev = new Map<string, { t0: number, t1: number }>()
        // one line's character count (key + colon-space + text).  Sizing is INVERTED: given the free
        //  gap on the containing groove, pick the LARGEST fs whose natural width fits it (capped by
        //   fsceil + the height allowance, floored by fsfloor → smaller folds).  The human: "really
        //    max it out — it gets small text too easily."
        const line_chars = (L: PL) => (L.k ? L.k.length + 2 : 0) + L.text.length
        // resolve a groove turn k for a home bearing φ so R(2πk+φ) ≈ target r; screen-down is +1 or −1
        //  in k depending on where the pole sits — computed EMPIRICALLY per title below.
        // try to place ONE line on groove turn k at bearing ph.  Returns the arc (unclaimed here — the
        //  caller commits the whole block at once) or null if it can't fit even at the floor.  fscap =
        //   the pitch fraction cap (0.92 for a single groove, ~1.8 for a two-groove title lower arc).
        type Placed = { t0: number, t1: number, arc: PhiArc, rlow: number }
        const place_line = (L: PL, k: number, ph: number, fscap: number, cid: string,
                            groovesLow: number): Placed | null => {
            if (k < 1) return null
            const tc = 2 * Math.PI * k + ph
            if (tc <= 2 * Math.PI) return null            // off the pole singularity
            const rlow = R_of(2 * Math.PI * groovesLow + ph)   // radius the text rides (lower groove)
            if (rlow <= 0) return null
            const gap = gap_at(tc)
            const gw = (Math.min(gap.hi, tc + 3) - Math.max(gap.lo, tc - 3))   // angular width, capped generous
            if (gw <= 0) return null
            const gap_px = gw * rlow                       // the gap's arc length in px
            const chars = line_chars(L)
            // biggest fs whose natural width (chars·GLY·fs) fits the gap minus pads, then capped
            let fs = Math.min(FSCEIL, G * fscap, (gap_px - 12) / (GLY * Math.max(1, chars)))
            if (fs < FSFLOOR) return null                  // too cramped → the caller folds this line
            fs = Math.min(fs, FSCEIL)
            const natpx = chars * GLY * fs
            const span = (natpx + 10) / rlow
            if (rlow <= 0 || span <= 0) return null         // degenerate span guard
            if (span > 2.2) return null                     // a near-full-circle line reads silly
            const t0 = tc - span / 2, t1 = tc + span / 2
            if (t0 <= 2 * Math.PI) return null
            if (!free(t0, t1)) return null
            // sample the LOWER groove arc; reverse if it runs right-to-left so text reads L→R
            const pts: { x: number, y: number }[] = []
            const n = Math.max(6, Math.min(80, Math.ceil(span / 0.07)))
            for (let i = 0; i <= n; i++) {
                const t = t0 + (t1 - t0) * i / n, r = R_of(t)
                const tt = t + 2 * Math.PI * (groovesLow - k)   // ride the lower groove at this bearing
                const rr = R_of(tt)
                pts.push({ x: px + rr * Math.cos(tt), y: py + rr * Math.sin(tt) })
            }
            if (pts[pts.length - 1].x < pts[0].x) pts.reverse()
            const d = 'M' + pts.map(p => `${p.x.toFixed(1)} ${p.y.toFixed(1)}`).join('L')
            const arc: PhiArc = { pathid: `vphi-${dom_id(cid)}-${L.slug}`, d, fs, cls: L.cls,
                                  tint: L.tint, k: L.k, khue: L.khue, text: L.text,
                                  tl: stretch(rlow * span - 10, chars, fs), cellid: cid }
            return { t0, t1, arc, rlow }
        }
        // big cells claim first (the give+take favours the load-bearing); a cell's whole C-block
        //  claims consecutively, so its lines land on NEIGHBOURING grooves — blind to the cell wall.
        const parea = (p: VCell) => { let s = 0
            for (let i = 0; i < p.inset.length; i++) {
                const u = p.inset[i], v = p.inset[(i + 1) % p.inset.length]; s += u.x * v.y - v.x * u.y }
            return Math.abs(s) }
        const order = [...live].sort((a, b) => parea(b) - parea(a))
        // commit a placed line: ledger it, remember its interval, arc it, held/moved-count it
        const commit = (p: Placed, prev?: { t0: number, t1: number }) => {
            claimed.push([p.t0, p.t1])
            next_prev.set(p.arc.pathid, { t0: p.t0, t1: p.t1 })
            arcs.push(p.arc)
            if (prev && Math.abs(prev.t0 - p.t0) < 1e-6 && Math.abs(prev.t1 - p.t1) < 1e-6) held++
            else if (prev) moved++
        }
        for (const c of order) {
            const { title, children, extra } = cell_labels(c)
            const nlabels = (title ? 1 : 0) + children.length + extra
            total += nlabels
            let miss = extra
            // home (r, φ) from the OFF-SCREEN pole
            const dx = c.acx - px, dy = c.acy - py
            const r_h = Math.max(G * 1.5, Math.hypot(dx, dy))
            let ph = Math.atan2(dy, dx); if (ph < 0) ph += 2 * Math.PI
            const k_h = Math.max(1, Math.round((T_of(r_h) - ph) / (2 * Math.PI)))
            // which k-step is screen-DOWN at this bearing?  sample the point one groove out (k+1) vs
            //  the home point and see whose y is larger — do NOT hardcode (depends on the pole side).
            const pt_at = (kk: number) => { const t = 2 * Math.PI * kk + ph, r = R_of(t)
                return { x: px + r * Math.cos(t), y: py + r * Math.sin(t) } }
            const down = pt_at(k_h + 1).y > pt_at(k_h).y ? 1 : -1   // +1 or −1 in k = screen-down
            const boost = phi_boost.has(c.id) ? 3 : 1
            const budget = boost * (REACH * G + 70)
            const dktitle = boost > 1 ? [0, 1, -1, 2, -2, 3, -3, 4, -4] : [0, 1, -1, 2, -2, 3, -3]
            const offs = [0, 0.02, -0.02, 0.05, -0.05, 0.09, -0.09, 0.15, -0.15, 0.24, -0.24]

            // try to seat the whole block anchored at title groove kt, bearing ph+off.  Children go
            //  on the grooves screen-down from the title, each indented by INDENT_EM em of the title
            //   fs converted to angle (/rlow).  Returns the placed set, or null if the title won't fit.
            const try_block = (kt: number, off: number, kids: PL[]): Placed[] | null => {
                if (!title) return null
                // TITLE: may span TITLE_GROOVES grooves (bigger cap) when all are free at this window
                let tp: Placed | null = null
                for (let ng = Math.min(TITLE_GROOVES, kt); ng >= 1; ng--) {
                    const low = kt                          // the lowest groove the title occupies
                    const cap = ng >= 2 ? 1.8 : 0.92
                    const cand = place_line(title, kt, ph + off, cap, c.id, low)
                    if (!cand) continue
                    // the upper grooves the title spans must ALSO be free over the same angular window
                    let ok = true
                    for (let g = 1; g < ng; g++) {
                        const t0u = cand.t0 - 2 * Math.PI * g, t1u = cand.t1 - 2 * Math.PI * g
                        if (!free(t0u, t1u)) { ok = false; break }
                    }
                    if (!ok) continue
                    tp = cand
                    // reserve the extra spanned grooves so a child can't invade the title's body
                    ;(cand as any).spanUp = ng - 1
                    break
                }
                if (!tp) return null
                const out: Placed[] = [tp]
                const spanUp: number = (tp as any).spanUp ?? 0
                const claim_local: [number, number][] = [[tp.t0, tp.t1]]
                for (let g = 1; g <= spanUp; g++) claim_local.push([tp.t0 - 2 * Math.PI * g, tp.t1 - 2 * Math.PI * g])
                const local_free = (t0: number, t1: number) =>
                    free(t0, t1) && !claim_local.some(([a, b]) => t0 < b && a < t1)
                // the indent, in angle, off the title's START bearing (a treeing indent like snap
                //  notation): INDENT_EM em of the title fs, converted to angle via /r.  A child line's
                //   arc START sits at the title's start + this indent; place_line centres a line, so we
                //    add half the child's own natural span back to turn a start into a centre.
                const indentAng = INDENT_EM * tp.arc.fs / tp.rlow
                const title_start = tp.t0                   // the title's arc start in total angle
                let kc = kt
                for (const kid of kids) {
                    kc += down                              // next groove screen-DOWN
                    const rc = R_of(title_start + 2 * Math.PI * (kc - kt))   // this child's groove radius
                    const half = (line_chars(kid) * GLY * FSFLOOR) / (2 * Math.max(1, rc))  // ≥ half-span guess
                    let cp: Placed | null = null
                    for (const nudge of offs) {
                        // start = title start + indent; centre = start + half its span (nudged out to dodge)
                        const centre = title_start + 2 * Math.PI * (kc - kt) + indentAng + half + nudge
                        const cand = place_line(kid, kc, centre - 2 * Math.PI * kc, 0.92, c.id, kc)
                        if (cand && local_free(cand.t0, cand.t1)) { cp = cand; break }
                    }
                    if (!cp) return null                    // a child couldn't seat here — whole anchor fails
                    out.push(cp)
                    claim_local.push([cp.t0, cp.t1])
                }
                return out
            }

            // HYSTERESIS: try each label at its PREVIOUS interval first (if still free), so a drag
            //  re-validates in place.  A held title drags its own block along; a held child re-seats
            //   alone.  We only fast-path the whole block if the title held AND all kids held.
            let placedSet: { p: Placed, prev?: { t0: number, t1: number } }[] | null = null
            if (title) {
                const tprev = phi_prev.get(`vphi-${dom_id(c.id)}-${title.slug}`)
                if (tprev && free(tprev.t0, tprev.t1)) {
                    // rebuild the title arc at its old interval, then try to re-seat kids at theirs
                    const set = seat_at_prev(c, title, children, tprev)
                    if (set) placedSet = set
                }
            }
            // fresh block search: anchor the block, walking grooves/bearings out from home, honouring
            //  the budget.  Retry with progressively fewer children (fold the tail) down to title-only.
            if (!placedSet && title) {
                let kids = children.slice()
                search: while (true) {
                    for (const dk of dktitle) {
                        const kt = k_h + dk
                        if (kt < 1) continue
                        if (Math.abs(dk) * G > budget) continue
                        for (const off of offs) {
                            const rk = R_of(2 * Math.PI * kt + ph)
                            if (Math.abs(off) * rk > budget) continue
                            const set = try_block(kt, off, kids)
                            if (set) { placedSet = set.map(p => ({ p })); break search }
                        }
                    }
                    if (!kids.length) break                 // even title-only wouldn't seat
                    kids = kids.slice(0, kids.length - 1)    // fold the tail, retry
                }
            }
            if (placedSet) {
                for (const { p, prev } of placedSet) commit(p, prev)
                // the tail folded off by the retry (or the child-seat) shows honestly in +N
                const placedKids = placedSet.length - 1
                miss += Math.max(0, children.length - placedKids)
                // connective tissue: if the block landed far from home, thread the title back
                const tmid = placedSet[0].p
                const midx = px + placedSet[0].p.rlow * Math.cos((tmid.t0 + tmid.t1) / 2)
                const midy = py + placedSet[0].p.rlow * Math.sin((tmid.t0 + tmid.t1) / 2)
                if (Math.hypot(midx - c.acx, midy - c.acy) > G * 3)
                    ties.push({ d: `M${c.acx.toFixed(1)} ${c.acy.toFixed(1)} Q${((c.acx + midx) / 2 + 10).toFixed(1)} ${((c.acy + midy) / 2 - 10).toFixed(1)} ${midx.toFixed(1)} ${midy.toFixed(1)}`,
                                tint: placedSet[0].p.arc.tint })
            } else {
                miss += (title ? 1 : 0) + children.length   // the block folds entirely
            }
            folded += miss
            if (miss > 0) folds.push({ id: c.id, x: c.acx, y: c.acy, n: miss, tint: dmap.get(c.id)!.tint })
        }
        phi_prev = next_prev
        // the faint reference lattice — the flat neutral the warping landscape reads against.  Only
        //  draw what's VISIBLE: for each turn whose radius band crosses the bbox (+margin), sample
        //   just the angular window subtending the bbox from the pole.  No miles of off-screen path.
        const marg = G * 3
        const rmin = Math.max(1, halfdiag * (POLE_DIST - 1) - marg)
        const rmax = halfdiag * (POLE_DIST + 1) + marg
        // the bearing window: the bbox corners' angles from the pole
        const corners = [[bx0, by0], [bx1, by0], [bx1, by1], [bx0, by1]] as const
        let amin = Infinity, amax = -Infinity
        for (const [cx, cy] of corners) {
            let a = Math.atan2(cy - py, cx - px); if (a < 0) a += 2 * Math.PI
            amin = Math.min(amin, a); amax = Math.max(amax, a)
        }
        if (amax - amin > Math.PI) { const t = amin; amin = amax - 2 * Math.PI; amax = t }  // wrap-safe
        const lat: string[] = []
        const kmin = Math.max(1, Math.floor(T_of(rmin) / (2 * Math.PI)))
        const kmax = Math.ceil(T_of(rmax) / (2 * Math.PI))
        for (let k = kmin; k <= kmax && k - kmin < 200; k++) {
            const seg: string[] = []
            for (let a = amin - 0.05; a <= amax + 0.05; a += 0.03) {
                const t = 2 * Math.PI * k + a, r = R_of(t)
                if (t <= 2 * Math.PI) continue
                seg.push(`${(px + r * Math.cos(t)).toFixed(0)} ${(py + r * Math.sin(t)).toFixed(0)}`)
            }
            if (seg.length > 1) lat.push('M' + seg.join('L'))
        }
        return { lattice: lat.join(''), arcs, ties, folds, labels: total, folded, held, moved }

        // re-seat a whole block at the title's PREVIOUS interval: rebuild the title arc there, then
        //  try each child at its own previous interval (or a fresh nearby groove).  Returns the placed
        //   set with prev-markers for held/moved counting, or null if the seated title no longer fits.
        function seat_at_prev(c: VCell, title: PL, children: PL[],
                              tprev: { t0: number, t1: number }): { p: Placed, prev?: { t0: number, t1: number } }[] | null {
            const p = rebuild_at(c.id, title, tprev, 0.92)
            if (!p) return null
            const out: { p: Placed, prev?: { t0: number, t1: number } }[] = [{ p, prev: tprev }]
            const local: [number, number][] = [[p.t0, p.t1]]
            const lfree = (t0: number, t1: number) => free(t0, t1) && !local.some(([a, b]) => t0 < b && a < t1)
            for (const kid of children) {
                const kprev = phi_prev.get(`vphi-${dom_id(c.id)}-${kid.slug}`)
                if (kprev && lfree(kprev.t0, kprev.t1)) {
                    const kp = rebuild_at(c.id, kid, kprev, 0.92)
                    if (kp) { out.push({ p: kp, prev: kprev }); local.push([kp.t0, kp.t1]); continue }
                }
                break                                       // a child moved — stop the fast path, fold the tail
            }
            return out
        }
        // rebuild a line's arc at a GIVEN total-angle interval (the hysteresis re-seat): its lower
        //  groove is the turn nearest the interval centre; fs is re-derived from the interval width.
        function rebuild_at(cid: string, L: PL, iv: { t0: number, t1: number }, fscap: number): Placed | null {
            const tc = (iv.t0 + iv.t1) / 2
            const k = Math.round((tc - 0) / (2 * Math.PI))
            if (k < 1 || tc <= 2 * Math.PI) return null
            const rlow = R_of(tc)
            if (rlow <= 0) return null
            const span = iv.t1 - iv.t0
            if (span <= 0) return null
            const chars = line_chars(L)
            let fs = Math.min(FSCEIL, G * fscap, (rlow * span - 12) / (GLY * Math.max(1, chars)))
            if (fs < FSFLOOR) return null
            const pts: { x: number, y: number }[] = []
            const n = Math.max(6, Math.min(80, Math.ceil(span / 0.07)))
            for (let i = 0; i <= n; i++) {
                const t = iv.t0 + span * i / n, r = R_of(t)
                pts.push({ x: px + r * Math.cos(t), y: py + r * Math.sin(t) })
            }
            if (pts[pts.length - 1].x < pts[0].x) pts.reverse()
            const d = 'M' + pts.map(pp => `${pp.x.toFixed(1)} ${pp.y.toFixed(1)}`).join('L')
            const arc: PhiArc = { pathid: `vphi-${dom_id(cid)}-${L.slug}`, d, fs, cls: L.cls,
                                  tint: L.tint, k: L.k, khue: L.khue, text: L.text,
                                  tl: stretch(rlow * span - 10, chars, fs), cellid: cid }
            return { t0: iv.t0, t1: iv.t1, arc, rlow }
        }
    }

    // one pane's RADIAL tessellation: the source's own statement holds the centre (its
    //  cell weight floors at a share of R, so the most important statement is never the
    //   smallest text — meaning hierarchy = visual hierarchy), keyed facts belt the
    //    middle at their vein bearings ('year' sits the same way in every pane), and
    //     the members ring the RIM walking from their kind's bearing, washed outward
    //      by the slope gradient.  Each many-value region divides ITSELF (phi spiral,
    //       same power walls) — cells within cells; a one-value region says its whole
    //        statement as a unit ('year: 2007'), never a floating key and an orphan
    //         number.  Everything crowded out of this beat's glass is counted, and the
    //          count rides the +N fold mark — annotated, never silent.
    function subgraph_build(c: VCell, descs: VtuffDesc[], tint: string,
                            kind: string | undefined, quiet?: Set<string>, frame = 0): VSubPane | null {
        // the HUSH (the 2026-07-14 steer): claims this cell's whole region states ride the
        //  region's river instead — drop them here and LEDGER the count (»N, distinct from
        //   the +N crowd-out: +N means "no room this beat", »N means "the river says it").
        //    Nothing is silently gone; compression wrt the neighbours, honestly annotated.
        let com = 0
        if (quiet?.size) descs = descs.filter(d => {
            const id = claim_id(d)
            if (id && quiet.has(id)) { com++; return false }
            return true
        })
        const { keyed, members } = subgraph_tuples(descs)
        const total = keyed.reduce((s, g) => s + 1 + g.leaves.length, 0) + members.length
        const td = descs.find(d => d.kind === 'title')
        const tm = td ? /^(.*?)\s*×(\d+)$/.exec(td.text) : null
        const tname = tm ? tm[1] : (td?.text ?? '')
        const head: VHead = { tag: td?.tag ?? kind,
                              tagcolon: !!tname && (!td?.nk || td.nk === td.tag),
                              nk: tname && td?.nk && td.nk !== td.tag ? td.nk : undefined,
                              sup: tm ? `×${tm[2]}` : undefined }
        head.nkhue = nk_hue(head.nk)
        let A2 = 0
        for (let i = 0; i < c.inset.length; i++) {
            const p = c.inset[i], q = c.inset[(i + 1) % c.inset.length]
            A2 += p.x * q.y - q.x * p.y
        }
        const area = Math.abs(A2) / 2
        let pane: VSubPane | null = null
        let hid = 0
        if (total < 2 || area < 900) {
            // no structure worth tessellating (one k|v) or true hairline cell: the pane
            //  DEGRADES to its one statement and everything it can't carry is counted
            pane = nucleus_pane(c, tint, head, tname)
            hid = total
        } else if (vsub_face === 'tuples') {
            // the notation face (the new default): the same tree said as snap-like rows.  A big
            //  cross-kind FOLD first tries the B1 CRATERS (each member C its own sub-cell); it
            //   returns null when there's no fold structure or the cell's too tight, and we fall to
            //    the flat tuples stack; a pane too tight for even a title degrades like everyone else.
            let tp = vsub_craters ? crater_pane(c, head, tname, keyed, tint, kind) : null
            // a fold too tight to crater legibly falls back to FLAT (which inflates big + reads fine);
            //  the EXISTING tiny() spell grows a genuinely-small one until it can crater — no separate
            //   "always chase a crater" push (that made every readable flat fold beg to grow → a
            //    zero-sum re-paint STORM, the human's "very blinky").  Big cells crater; small folds
            //     read flat; the human can DRAG a cell bigger to crater it (see cell drag).
            if (!tp) tp = tuple_pane(c, head, tname, keyed, members, tint, kind)
            if (tp) { pane = tp.pane; hid = tp.hid }
            else { pane = nucleus_pane(c, tint, head, tname); hid = total }
        } else {
            const R = Math.sqrt(area / Math.PI)
            const khue = kind_tint(kind) ?? tint
            // the cs frame (0 when cs is off) rotates the WHOLE compass — vein bearings and the
            //  member ring alike — so downstream-along-the-river is a fixed local direction and a
            //   key lands the same way river-relative in every cell of the region.  frame=0 leaves
            //    every angle exactly as before.
            const kang = vein_of(kind ?? head.tag ?? '').ang + frame
            const pull = (x: number, y: number, margin: number) => {
                for (let t = 0; t < 5; t++) {
                    const ch = poly_chord(c.inset, y)
                    if (ch && x > ch[0] + margin && x < ch[1] - margin) break
                    x = c.acx + (x - c.acx) * 0.7; y = c.acy + (y - c.acy) * 0.7
                }
                return { x, y }
            }
            const kpts = keyed.map(g => {
                const a = vein_of(g.key ?? '').ang + frame
                return pull(c.acx + Math.cos(a) * R * 0.55,
                            c.acy + Math.sin(a) * R * 0.55 * 0.8, 4)
            })
            const mpts = members.map((l, i) => {
                const a = kang + (i + 0.5) * 2 * Math.PI / members.length
                return pull(c.acx + Math.cos(a) * R * 0.85,
                            c.acy + Math.sin(a) * R * 0.85 * 0.8, 3)
            })
            const tlen = head_len(head, !!tname) + tname.length
            const gscale = (g: VSubTuple) =>
                Math.sqrt(g.leaves.reduce((s, l) => s + (l.hw * 2) * (l.hh * 2.4), 140))
            const radii = [Math.max(8 + 0.5 * Math.sqrt(tlen * 26), R * 0.34),
                           ...keyed.map(g => 6 + 0.55 * gscale(g)),
                           ...members.map(l => 4 + 0.45 * Math.hypot(l.hw, l.hh))]
            const polys = power_cells(c.inset, [{ x: c.acx, y: c.acy }, ...kpts, ...mpts], radii, 2.2)
            const npoly = polys[0]
            const walls: VWall[] = []
            const stats: VStat[] = []
            const spokes: { d: string, hue: string }[] = []
            const ncx = npoly ? npoly.reduce((a, p) => a + p.x, 0) / npoly.length : c.acx
            const ncy = npoly ? npoly.reduce((a, p) => a + p.y, 0) / npoly.length : c.acy
            keyed.forEach((g, gi) => {
                const gpoly = polys[1 + gi]
                if (!gpoly) { hid += 1 + g.leaves.length; return }   // crowded out this beat
                const hue = `hsl(${vein_of(g.key ?? '').hue}, 52%, 60%)`
                walls.push({ d: poly_d(gpoly), hue, cls: 'vsub-gwall' })
                // the SPOKE: nucleus → region in the region's hue, the "all linked to it"
                //  made visible — every fact hangs off the source it describes
                const scx = gpoly.reduce((a, p) => a + p.x, 0) / gpoly.length
                const scy = gpoly.reduce((a, p) => a + p.y, 0) / gpoly.length
                spokes.push({ d: `M${ncx.toFixed(1)},${ncy.toFixed(1)}L${scx.toFixed(1)},${scy.toFixed(1)}`, hue })
                const one = g.leaves.length === 1 && !g.leaves[0].member ? g.leaves[0] : null
                if (one) {
                    // a whole one-value fact ('year: 2007') is load-bearing — 14pt floor.
                    //  A key that won't fit its value at 14 with the colon sheds nothing
                    //   here (fit_stat, not fit_ident), so it clips: acceptable for a fact,
                    //    where the key names what the clipped value is.
                    const s = fit_stat(gpoly, { key: g.key, colon: true, sup: one.sup }, one.val,
                                       { ...band_for(g.wgt, 22), maxlines: 3 })
                    if (s) { s.cls = 'vsub-gkey'; s.hue = hue; stats.push(s) } else hid += 1
                    return
                }
                if (!g.leaves.length) {   // presence key — no v, no colon
                    // a presence marker ('remaster ×2') is a LABEL, not a statement to read —
                    //  decoration band, so it may sit under 14pt without forcing a shed
                    const s = fit_stat(gpoly, { key: g.key, sup: g.sup }, undefined, { ...BAND_DECO })
                    if (s) { s.cls = 'vsub-gkey'; s.hue = hue; stats.push(s) } else hid += 1
                    return
                }
                // many values: the KEY is a seed like its values — its statement gets a
                //  reserved sub-cell at the region's crown (no key/value overlap by
                //   construction, no wall of its own), the values tessellating around
                //    it on the phi spiral
                const gys = gpoly.map(p => p.y)
                const gy0 = Math.min(...gys), gh = Math.max(...gys) - gy0
                const gcx = gpoly.reduce((a, p) => a + p.x, 0) / gpoly.length
                const gcy = gpoly.reduce((a, p) => a + p.y, 0) / gpoly.length
                const kb = wide_chord(gpoly, gy0 + gh * 0.1, gy0 + gh * 0.35, 5)
                const kseed = kb ? { x: (kb.x0 + kb.x1) / 2, y: kb.y }
                                 : { x: gcx, y: gy0 + gh * 0.2 }
                const klen = (g.key?.length ?? 3) + (g.sup ? 2 : 0) + 1
                const gR = Math.sqrt(Math.abs(gh) * (wide_chord(gpoly, gcy, gcy, 1)?.w ?? gh) / Math.PI) * 0.6
                // un-compress ×N (Slice A): a '2007 ×3' chip shrinks its whole statement to
                //  make room for the superscript, so at the 14pt floor it may not fit.  When
                //   the region has SPARE sub-cells, split the ×N back into N plain copies —
                //    the multiplicity shows as repetition (three big '2007's), not one small
                //     '2007 ×3'.  Only expand within a seed budget the region can seat at 14pt
                //      (≈ area / a min legible sub-cell), so we never trade a fold for a smear;
                //       a chip whose split won't fit keeps its ×N and folds the rest to +N.
                const MIN_CELL = 22 * 22                    // a 14pt value needs ~this much sub-cell room
                let budget = Math.max(0, Math.floor(Math.PI * gR * gR / MIN_CELL) - 1 - g.leaves.length)
                const dleaves: VSubLeaf[] = []
                for (const l of g.leaves) {
                    const n = l.sup ? Number(/×(\d+)/.exec(l.sup)?.[1] ?? 0) : 0
                    if (n > 1 && budget >= n - 1) {         // room to seat every copy — un-compress
                        budget -= n - 1
                        const { sup, ...bare } = l           // drop the ×N; the copies ARE the count
                        for (let i = 0; i < n; i++) dleaves.push({ ...bare })
                    } else dleaves.push(l)                   // no room (or n≤1) — keep it compressed
                }
                const GA = Math.PI * (3 - Math.sqrt(5))
                const lpts = [kseed, ...dleaves.map((l, k) => {
                    const rr = gR * Math.sqrt((k + 0.5) / dleaves.length)
                    let x = gcx + Math.cos(k * GA) * rr
                    let y = gcy + gh * 0.06 + Math.sin(k * GA) * rr * 0.8
                    for (let t = 0; t < 5; t++) {
                        const ch = poly_chord(gpoly, y)
                        if (ch && x > ch[0] + 3 && x < ch[1] - 3) break
                        x = gcx + (x - gcx) * 0.7; y = gcy + (y - gcy) * 0.7
                    }
                    return { x, y }
                })]
                const lradii = [4 + klen * 1.6,
                                ...dleaves.map(l => 3 + 0.4 * Math.hypot(l.hw, l.hh))]
                const lpolys = power_cells(gpoly, lpts, lradii, 1.8)
                const kpoly = lpolys[0]
                // the KEY crown above its values is a small label — decoration band; the
                //  values below it carry the 14pt-floor reading, this just names them
                const ks = kpoly ? fit_stat(kpoly, { key: g.key, colon: true, sup: g.sup },
                                            undefined, { ...BAND_DECO, hi: 13 }) : null
                if (ks) { ks.cls = 'vsub-gkey'; ks.hue = hue; stats.push(ks) } else hid += 1
                dleaves.forEach((l, li) => {
                    const lpoly = lpolys[1 + li]
                    if (!lpoly) { hid += 1; return }
                    walls.push({ d: poly_d(lpoly), hue: c.color, cls: 'vsub-wall' })
                    // a value chip is an identity — 14pt floor, shedding grammar (fit_ident)
                    //  before it shrinks.  The spread's dominant chip (FAKED loud, the ×N
                    //   leader) gets the loudest floor so it towers over its siblings.
                    const band = band_for(l.wgt, 26)
                    const s = fit_ident(lpoly, { tag: l.tag, tagtint: l.tint, sup: l.sup }, l.val,
                                        { ...band, maxlines: 2 })
                    if (!s) { hid += 1; return }
                    s.cls = 'vsub-label'; s.subn = l.subn; s.member = l.member
                    stats.push(s)
                })
            })
            members.forEach((l, mi) => {
                const mpoly = polys[1 + keyed.length + mi]
                if (!mpoly) { hid += 1; return }
                walls.push({ d: poly_d(mpoly), hue: khue, cls: 'vsub-mwall', grad: true })
                // a member is an IDENTITY on the rim — 14pt floor, shedding grammar (the
                //  'Track name: X' → 'X' shed) before it drops under it; a rim sub-cell too
                //   small for even the bare name at 14pt folds into +N, never a 7pt smear.
                const s = fit_ident(mpoly, { tag: l.tag && l.tag !== kind ? l.tag : undefined,
                                             tagtint: l.tint, sup: l.sup }, l.val,
                                    { ...band_for(l.wgt, 26), maxlines: 2 })
                if (!s) { hid += 1; return }
                s.cls = 'vsub-label'; s.subn = l.subn; s.member = l.member
                stats.push(s)
            })
            if (!walls.length) {   // everything crowded out this beat — degrade, count it all
                pane = nucleus_pane(c, tint, head, tname)
                hid = total
            } else {
                // the kind said once, at its own bearing on the rim — the ring's engraving,
                //  the same compass point in every pane
                if (members.length && kind) {
                    const p = pull(c.acx + Math.cos(kang) * R * 0.95,
                                   c.acy + Math.sin(kang) * R * 0.95 * 0.8, 8)
                    stats.push({ x: p.x, y: p.y, fs: Math.max(8, Math.min(12, R * 0.09)),
                                 cls: 'vsub-ringkey', hue: khue,
                                 key: kind, sup: `×${members.length}` })
                }
                if (npoly) {
                    walls.push({ d: poly_d(npoly), hue: tint, cls: 'vsub-nwall' })
                    // the NUCLEUS statement is the loudest thing on the pane — the source's
                    //  own identity, seated in the biggest sub-cell (its radius floors at
                    //   R*0.34 above).  Loudest band, so meaning hierarchy = visual hierarchy:
                    //    the most important statement is never the smallest text.
                    const ns = fit_ident(npoly, head, tname || undefined, { ...BAND_VERY, maxlines: 3 })
                    if (ns) { ns.cls = 'vsub-ntitle'; ns.tagtint = tint; stats.push(ns) }
                }
                if (!stats.some(s => s.cls === 'vsub-ntitle')) {
                    // nucleus crowded out — the source statement floats as a one-line
                    //  headline, still load-bearing so still at the 14pt floor (sheds
                    //   grammar to fit one line rather than shrink under it)
                    const ts = fit_ident(c.inset, head, tname || undefined,
                                         { band: [0.05, 0.34], lo: BAND_LOUD.lo, hi: BAND_VERY.hi, maxlines: 1 })
                    if (ts) { ts.cls = 'vsub-title'; ts.tagtint = tint; stats.push(ts) }
                }
                pane = { id: c.id, clipid: `vsubclip-${dom_id(c.id)}`, clip: poly_d(c.inset),
                         color: c.color, tint, walls, spokes, stats }
                if (members.length) pane.grad = { cx: c.acx, cy: c.acy, r: R * 1.15, hue: khue }
            }
        }
        if (!pane) return null
        const pb = Math.max(...c.inset.map(p => p.y))
        // the /*N "surf" dip is GONE — it read as a fold-OPEN control but Vtuff_pop's stamp is
        //  one-way (opens, can't re-close: "there's no way back"), so it was a trap, not an
        //   affordance.  Popping a whole fold into the graph belongs to the drag/▦ gestures now.
        if (hid > 0) pane.hid = hid_mark(c.inset, hid)
        // the »N ledger: N claims left for the region's river (the promotion's receipt) —
        //  sits opposite the +N crowd-out mark, same low band, its own quiet green.
        if (com > 0) {
            const chd = poly_chord(c.inset, pb - 12)
            pane.com = chd ? { x: chd[1] - 8, y: pb - 18, n: com }
                           : { x: c.acx, y: pb - 18, n: com }
        }
        return pane
    }

    // ── 📻🕳 SHELVED: both drift modes are OFF ────────────────────────────────
    //  The tunnel never lets the tessellation settle (every radio dwell re-projects the
    //   walls), and both v1s were toggles bolted INSIDE the scape when they want to be
    //    their own artistic endeavour grown OUT of it — the owner parks them until that
    //     reimagining (spec/Voro_vtuffing.md north stars).  Like the rack: machinery kept
    //      behind the flag, buttons and stash-restore gated, so nothing can arm them and
    //       one flag re-opens the lab.
    const DRIFT_MODES_ON = false as boolean

    // ── 📻 the radio: attention as a supplied service (north star — spec/Voro_vtuffing.md) ──
    //  The .g tuner (Voro_drift_tick) ages the trail shut, picks the next locale, opens it a
    //   little; here we keep the dwell clock and GLIDE the camera onto whatever it returns.
    //    Touching the dial (grab|pan|zoom that isn't our own glide) holds the tuner off for
    //     15s — the listener's hand always outranks the program director.
    let radio_pref = $state<boolean | null>(null)
    const radio_on = $derived(DRIFT_MODES_ON && (radio_pref ?? false))
    let radio_timer: ReturnType<typeof setInterval> | null = null
    let radio_gliding = false
    let radio_hold_until = 0
    const RADIO_DWELL = 7000
    function radio_tick() {
        if (!cy || document.hidden || Date.now() < radio_hold_until) return
        const drift = (H as any).Voro_drift_tick
        if (!drift) { console.warn('📻 Voro_drift_tick not aboard — reload the tab for the new gen'); return }
        let w: any
        try { w = (H as any).Awo('Cyto') } catch { return }
        if (!w) return
        // 🕳 coupling: each dwell IS a step down the tube — advance the phase and repaint
        //  even when the tuner returns no focus, so the drift never stalls the walls
        if (tunnel_on) { tunnel_phase = (tunnel_phase + 0.16) % 1; voronoi_soon() }
        Promise.resolve(drift.call(H, w)).then((focus: any) => {
            if (!focus || !cy) return
            for (const [id, src] of node_src) if (src === focus) {
                const ele = cy.$id(id)
                if (!ele?.length) return
                radio_gliding = true
                cy.animate({ fit: { eles: ele.closedNeighborhood(), padding: 70 } },
                    { duration: 2400, easing: 'ease-in-out-cubic', complete: () => { radio_gliding = false } })
                return
            }
        })
    }
    function toggle_radio() {
        radio_pref = !radio_on
        const stv = (H as any).stashed
        if (stv) stv.Cyto_radio = radio_pref
        if (radio_timer) { clearInterval(radio_timer); radio_timer = null }
        if (radio_pref) { radio_tick(); radio_timer = setInterval(radio_tick, RADIO_DWELL) }
    }
    // ── 🕳 the tunnel: the tessellation drifts DOWN A TUBE (north star — spec/Voro_vtuffing.md) ──
    //  v1 skeleton = ONE projection at the seed-gather: tunnel on ⇒ voronoi_layout remaps every
    //   seed onto the wall of a tube before the power diagram runs, and EVERYTHING downstream
    //    (cells, molding, chips, hulls, the morph tween) follows for free — toggling literally
    //     morphs the flat glass into the rosette and back.  The arc is ~250° with the opening
    //      facing right, so the cross-section reads as the letter C; SOLIDITY sits LEFT: panes
    //       rank by fold mass and the heaviest takes θ=180° (the C's back), lighter fanning
    //        toward the lips.  Depth comes from layout y; near = big, far = small behind fog.
    //         Each radio dwell advances a phase that cycles panes front→back — drifting down
    //          the tube IS the tuner's dwell (the §North stars coupling).  cy itself stays 2D:
    //           this is a VIEW of the same layout, not a second layout space.
    let tunnel_pref = $state<boolean | null>(null)
    const tunnel_on = $derived(DRIFT_MODES_ON && voronoi_on && (tunnel_pref ?? false))
    let tunnel_phase = 0                       // camera z as a wrap-around phase [0,1), radio-advanced
    function toggle_tunnel() {
        tunnel_pref = !(tunnel_pref ?? false)
        const stt = (H as any).stashed
        if (stt) stt.Cyto_tunnel = tunnel_pref
        voronoi_soon()                         // morph into (or out of) the rosette
    }
    // project the seeds onto the tube wall, IN PLACE.  θ by fold-mass rank (solidity-left:
    //  heaviest at π, then ±Δ alternating toward the C's lips); depth d from normalised layout
    //   y plus the drift phase (wrapped — a pane past the camera rejoins at the far end);
    //    screen radius r = R0/d (near ring hugs the frame, far ring recedes toward the axis)
    //     and k = NEAR/d scales the content boxes, so nearer panes earn bigger cells.  tz = k
    //      rides out on each seed for the fog downstream.
    function tube_project(seeds: { id: string, x: number, y: number, hw: number, hh: number, node: any }[], CW: number, HH: number) {
        const SPAN = Math.PI * 250 / 180, NEAR = 0.8, FAR = 2.6
        let ymin = Infinity, ymax = -Infinity
        for (const s of seeds) { if (s.y < ymin) ymin = s.y; if (s.y > ymax) ymax = s.y }
        const yr = Math.max(1, ymax - ymin)
        const mass = (s: { id: string, hw: number, hh: number }) =>
            (((node_src.get(s.id) as any)?.c?.fold_n ?? 1) as number) * 1000 + s.hw * s.hh / 100
        const order = seeds.slice().sort((a, b) => mass(b) - mass(a))
        const dth = SPAN / Math.max(1, order.length)
        const R0 = Math.min(CW, HH) * 0.5 * 0.92 * NEAR
        order.forEach((s, i) => {
            const th = Math.PI + (i % 2 ? 1 : -1) * Math.ceil(i / 2) * dth
            const d = NEAR + (((s.y - ymin) / yr * 0.96 + tunnel_phase) % 1) * (FAR - NEAR)
            const k = NEAR / d
            const r = R0 / d
            s.x = CW / 2 + Math.cos(th) * r
            s.y = HH / 2 + Math.sin(th) * r
            s.hw = Math.max(14, s.hw * k)
            s.hh = Math.max(10, s.hh * k)
            ;(s as any).tz = k
        })
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
    let morph_backstop: ReturnType<typeof setTimeout> | null = null   // rAF-throttle safety net (below)

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
    const NUC_MIN = 1   // no threshold (owner: "it's okay if there's just one of them") — even a
                        //  lone edgeless child gets seated on a hub instead of floating.  The full
                        //   come-and-go snake backbone (Voro_vtuffing.md next-moves #10) is the plan;
                        //    this is its threshold half.
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
        // 🕳 tunnel depth factor (NEAR/d, 1 = nearest) — absent when the tunnel is off
        tz?: number,
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

    // last C1 clump signature — voronoi_layout runs per drag-frame, so its telemetry
    //  line fires only when the clump's shape changes (see the pass inside)
    let clump_sig = ''

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
            // the GROWTH SPELL (the human: "put a spell on the cell to grow it, until the cyto
            //  changes enough that it gets more than enough space and we can remove the spell"):
            //   a starved pane's verdict (spell_update, at the end of paint) swells this seed's
            //    content box, the power walls below yield it room next paint — and the spell
            //     lifts only at ABUNDANCE, so the wall never flutters at the boundary.
            const sp = vspell.get(id) ?? 1
            seeds.push({ id, x: p.x, y: p.y, hw: Math.min(hw, 260) * sp, hh: Math.min(hh, 200) * sp, node })
        }
        // no two-seed floor (owner: "just add more invisible nodes, sheesh") — and no phantom
        //  needed either: a lone seed simply meets no cutters in the loop below, so its poly
        //   stays the whole frame and the first pane owns the canvas from its first mount.
        //    Cells from the very first beat, not after some threshold of company.
        if (!seeds.length) return null

        // ── C1: regroup the families — same-family seeds drift toward their family's
        //  centroid BEFORE the walls are cut, so a family's cells land as one CONTIGUOUS
        //   territory (the scape wants continuous spaces an arc can flow through, not a
        //    checkerboard of interleaved kinds).  Buckets by region_of — the grasp's
        //     the:family with the crusher's fold_kind beneath it — the same grouping the
        //      ▧ washes draw, so what clumps IS what the wash shows.  One family total
        //       (a grasp-blind graph of misc) pulls nothing: the scape only regroups
        //        where there ARE distinct kinds to regroup.
        const CLUMP = 0.30, MINSEP = 84
        {
            const fams = new Map<string, typeof seeds>()
            for (const s of seeds) {
                const f = region_of(s.id)
                let m = fams.get(f); if (!m) fams.set(f, m = [])
                m.push(s)
            }
            let moved = 0, pull = 0
            if (fams.size > 1) {
                for (const [, mem] of fams) {
                    if (mem.length < 2) continue
                    const gx = mem.reduce((a, m) => a + m.x, 0) / mem.length
                    const gy = mem.reduce((a, m) => a + m.y, 0) / mem.length
                    for (const m of mem) {
                        const dx = (gx - m.x) * CLUMP, dy = (gy - m.y) * CLUMP
                        m.x += dx; m.y += dy; moved++; pull += Math.hypot(dx, dy)
                    }
                    // pulled kin must not fuse: a pair tighter than MINSEP is eased back
                    //  apart along its own axis, so no sibling swallows a sibling's cell
                    for (let i = 0; i < mem.length; i++) for (let j = i + 1; j < mem.length; j++) {
                        const a = mem[i], b = mem[j]
                        let dx = b.x - a.x, dy = b.y - a.y
                        const d = Math.hypot(dx, dy)
                        if (d >= MINSEP) continue
                        if (d < 1) { dx = 1; dy = 0 }
                        const need = (MINSEP - d) / 2 / Math.max(d, 1)
                        a.x -= dx * need; a.y -= dy * need
                        b.x += dx * need; b.y += dy * need
                    }
                }
            }
            // per-frame function (live drags repaint through here) — the film strip only
            //  gets a line when the family census changes, not per frame; and it speaks
            //   even when nothing pulls (fams:1) — a silent no-op is undiagnosable
            const sig = fams.size + ':' + moved
            if (sig !== clump_sig) {
                clump_sig = sig
                vlog('clump', { fams: fams.size, moved, avg: moved ? Math.round(pull / moved) : 0 })
            }
        }
        if (tunnel_on) tube_project(seeds, W, HH)   // 🕳 one remap, everything downstream follows

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
            // no half-size floor: the old Math.max(0.5, …) forced a Stuffing to at least
            //  half its natural size even in a cell that couldn't hold it — the guaranteed
            //   clip the owner kept seeing.  Slightly small beats cut-off words; 0.18 is
            //    only the dust guard.  (paint_final clamps again with the TRUE content box —
            //     s.hw/s.hh here are the capped gather-time dims, which lie for big content.)
            const fit = Math.max(0.18, smax * 0.92)

            cells.push({ id: s.id, seed: { x: s.x, y: s.y }, inset, acx, acy,
                color: cell_color(s.id, s.node), node: s.node,
                T11, T12, T21, T22, fit, edge_src, tz: (s as any).tz })
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

    // the glass a cell wears is the kind of what the cell IS.  A GANG rep is an artifice —
    //  the members ARE its identity, so it wears c.fold_kind.  A REAL container folding
    //   members of another kind (an Artist over its Tracks) wears its OWN mainkey: the
    //    header speaks that level, and the members' tint lives on the coagulate INSIDE.
    //     (Pre-craters this preferred fold_kind for every fold — a fold cell showed only
    //      its members then, but it left the human's Artist cell Track-pink: "Artist says
    //       it's supposed to be Teal tho, and it's pink like Track.")  Either way it goes
    //        through kind_glass, so an un-swatched kind still joins the stained glass by
    //         hue instead of falling to the teal node border.
    function cell_color(id: string, node: any): string {
        const src = node_src.get(id) as any
        if (src?.c?.gang) {
            const g = kind_glass(src.c.fold_kind as string | undefined); if (g) return g
        }
        const own = src?.sc ? Object.keys(src.sc)[0] as string : undefined
        return kind_glass(own) ?? kind_glass(src?.c?.fold_kind as string | undefined)
            ?? (node.style('border-color') as string)
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

    // Andrew's monotone-chain convex hull — the cheapest closed geometry that
    //  wraps a region's cells as one filled backing (Slice C).  O(n log n), no
    //   deps; the region wash is a hull of ALL member cells' inset vertices, so
    //    it hugs the cells rather than a loose centroid cloud.  Returns the hull
    //     ring (may be <3 pts for a degenerate region — caller guards).
    function convex_hull(pts: {x:number,y:number}[]): {x:number,y:number}[] {
        if (pts.length < 3) return pts.slice()
        const p = pts.slice().sort((a, b) => a.x - b.x || a.y - b.y)
        const cross = (o: {x:number,y:number}, a: {x:number,y:number}, b: {x:number,y:number}) =>
            (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
        const lower: {x:number,y:number}[] = []
        for (const q of p) {
            while (lower.length >= 2 && cross(lower[lower.length - 2], lower[lower.length - 1], q) <= 0) lower.pop()
            lower.push(q)
        }
        const upper: {x:number,y:number}[] = []
        for (let i = p.length - 1; i >= 0; i--) {
            const q = p[i]
            while (upper.length >= 2 && cross(upper[upper.length - 2], upper[upper.length - 1], q) <= 0) upper.pop()
            upper.push(q)
        }
        lower.pop(); upper.pop()
        return lower.concat(upper)
    }

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

    // ── ▧ arc-rivers (Slice D) — fit ONE tidy arc through a family's cells ─────
    //  a river is the family's centroids strung into a smooth path and read for its
    //   letterform.  Two orderings, and the family's own shape picks which: a family
    //    that WRAPS around something (its cells fan out around their common centroid)
    //     wants the angle order — walk the ring; a family that STREAKS across the
    //      scape wants the PCA main axis — project onto the direction of greatest
    //       spread and walk it end to end.  Wrap is told from streak by how evenly
    //        the angles fill the circle vs how flat the spread is off the main axis.
    //   No allocation storm: a handful of centroids, closed math, per settle|morph.

    // the family's centroids' 2×2 covariance → principal axis (largest-eigenvector),
    //  and the flatness ratio (minor/major spread) that says wrap-vs-streak.
    function pca_axis(pts: {x:number,y:number}[]): { ux: number, uy: number, flat: number } {
        const n = pts.length
        const cx = pts.reduce((a, p) => a + p.x, 0) / n
        const cy = pts.reduce((a, p) => a + p.y, 0) / n
        let sxx = 0, syy = 0, sxy = 0
        for (const p of pts) {
            const dx = p.x - cx, dy = p.y - cy
            sxx += dx * dx; syy += dy * dy; sxy += dx * dy
        }
        // closed-form eigen of the symmetric [[sxx,sxy],[sxy,syy]]
        const tr = sxx + syy, det = sxx * syy - sxy * sxy
        const disc = Math.max(0, tr * tr / 4 - det)
        const l1 = tr / 2 + Math.sqrt(disc)   // major eigenvalue
        const l2 = tr / 2 - Math.sqrt(disc)   // minor eigenvalue
        // eigenvector for l1: (sxy, l1 - sxx) unless sxy ≈ 0 (already axis-aligned)
        let ux: number, uy: number
        if (Math.abs(sxy) > 1e-6) { ux = l1 - syy; uy = sxy }
        else if (sxx >= syy)      { ux = 1; uy = 0 }
        else                      { ux = 0; uy = 1 }
        const mag = Math.hypot(ux, uy) || 1
        return { ux: ux / mag, uy: uy / mag, flat: l1 > 1e-6 ? l2 / l1 : 1 }
    }

    // order the centroids into the river's walk.  wrap ⇒ by angle around the family
    //  centroid (a ring); streak ⇒ by projection onto the PCA main axis (a line).
    //   wrap is claimed when the cloud is round enough (flat ratio high) AND the
    //    angles actually span most of the circle — otherwise it's a streak.
    function river_order(cents: {x:number,y:number}[]): { seq: {x:number,y:number}[], wrap: boolean } {
        const n = cents.length
        const cx = cents.reduce((a, p) => a + p.x, 0) / n
        const cy = cents.reduce((a, p) => a + p.y, 0) / n
        const { ux, uy, flat } = pca_axis(cents)
        // angular coverage: the largest gap between sorted angles; a full ring leaves
        //  no big gap, a streak leaves one huge one (the empty far side)
        const angs = cents.map(p => Math.atan2(p.y - cy, p.x - cx)).sort((a, b) => a - b)
        let maxgap = angs[0] + 2 * Math.PI - angs[angs.length - 1]
        for (let i = 1; i < angs.length; i++) maxgap = Math.max(maxgap, angs[i] - angs[i - 1])
        const wraps = n >= 4 && flat > 0.55 && maxgap < Math.PI * 0.9
        if (wraps) {
            const seq = cents.slice().sort((a, b) =>
                Math.atan2(a.y - cy, a.x - cx) - Math.atan2(b.y - cy, b.x - cx))
            return { seq, wrap: true }
        }
        const seq = cents.slice().sort((a, b) =>
            ((a.x - cx) * ux + (a.y - cy) * uy) - ((b.x - cx) * ux + (b.y - cy) * uy))
        return { seq, wrap: false }
    }

    // read the ordered walk's letterform from its curvature.  the signed turn at each
    //  interior vertex (z of consecutive edge cross-products) is the local bend; the
    //   number of times that sign flips is the number of inflections:
    //    a closed ring of ≥4 ⇒ O; ~straight (tiny total bend) ⇒ I; one steady bend
    //     (no flips) ⇒ C; two-plus flips (the S-curve) ⇒ S.  A dead-band on each turn
    //      keeps sampling jitter from inventing inflections the eye wouldn't see.
    function letter_of(seq: {x:number,y:number}[], closed: boolean): string {
        if (closed) return 'O'
        if (seq.length < 3) return 'I'
        let total = 0, flips = 0, last = 0
        const DEAD = 0.18   // radians — a turn shallower than this doesn't count as a bend
        for (let i = 1; i < seq.length - 1; i++) {
            const ax = seq[i].x - seq[i - 1].x, ay = seq[i].y - seq[i - 1].y
            const bx = seq[i + 1].x - seq[i].x, by = seq[i + 1].y - seq[i].y
            const cr = ax * by - ay * bx
            const la = Math.hypot(ax, ay) || 1, lb = Math.hypot(bx, by) || 1
            const turn = Math.asin(Math.max(-1, Math.min(1, cr / (la * lb))))   // signed bend
            total += turn
            if (Math.abs(turn) < DEAD) continue
            const sgn = turn > 0 ? 1 : -1
            if (last && sgn !== last) flips++
            last = sgn
        }
        if (Math.abs(total) < 0.35) return 'I'   // barely bends over the whole run
        if (flips >= 2) return 'S'
        return 'C'
    }

    // Catmull-Rom through the ordered points, emitted as cubic Béziers (each segment's
    //  control points are the neighbours' tangents / 6).  `closed` wraps the ring so
    //   an O joins seamlessly.  Self-contained formatter so it doesn't lean on
    //    paint_final's local P.
    function catmull_d(pts: {x:number,y:number}[], closed: boolean): string {
        const F = (v: number) => v.toFixed(1)
        const n = pts.length
        if (n < 2) return ''
        const at = (i: number) => closed ? pts[(i % n + n) % n] : pts[Math.max(0, Math.min(n - 1, i))]
        let d = `M${F(pts[0].x)} ${F(pts[0].y)}`
        const last = closed ? n : n - 1
        for (let i = 0; i < last; i++) {
            const p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2)
            const c1x = p1.x + (p2.x - p0.x) / 6, c1y = p1.y + (p2.y - p0.y) / 6
            const c2x = p2.x - (p3.x - p1.x) / 6, c2y = p2.y - (p3.y - p1.y) / 6
            d += `C${F(c1x)} ${F(c1y)} ${F(c2x)} ${F(c2y)} ${F(p2.x)} ${F(p2.y)}`
        }
        if (closed) d += 'Z'
        return d
    }

    // walk the ordered centroids as straight legs and drop a chip every STEP px,
    //  each rotated to the local leg's tangent — the "lined up tuples" of debris.
    //   The polyline (not the Bézier) is the ruler here: close enough to the drawn
    //    river for the eye, and trivial to arc-length-sample.  Angles are clamped
    //     to upright-ish so the trait stays readable (never upside down).
    //  Takes the region's whole SPEECH — the trait first, then every promoted shared claim —
    //   and cycles it station by station, each chip Wes-Wilson-sized to fill its station
    //    (short words tower, long claims stay legible at the floor): the river SAYS what the
    //     member cells no longer repeat.
    function river_chips(seq: {x:number,y:number}[], closed: boolean, texts: string[]) {
        const RIVER_CHIP_STEP = 110   // px between chips along the trail
        const chips: { x: number, y: number, ang: number, text: string, fs: number }[] = []
        if (!texts.length || seq.length < 2) return chips
        const legs = closed ? seq.length : seq.length - 1
        let carry = RIVER_CHIP_STEP / 2   // half a step in, so a lone leg still gets one
        let ti = 0
        for (let i = 0; i < legs; i++) {
            const a = seq[i], b = seq[(i + 1) % seq.length]
            const dx = b.x - a.x, dy = b.y - a.y
            const len = Math.hypot(dx, dy)
            if (len < 1) continue
            let ang = Math.atan2(dy, dx) * 180 / Math.PI
            if (ang > 90) ang -= 180; else if (ang < -90) ang += 180   // keep the text upright-ish
            for (let s = carry; s < len; s += RIVER_CHIP_STEP) {
                const t = s / len
                const text = texts[ti++ % texts.length]
                // fill ~80% of the station with the word — the Wes-Wilson stretch, clamped lovely
                const fs = Math.max(9, Math.min(22, (RIVER_CHIP_STEP * 0.8) / (GLY * Math.max(2, text.length))))
                chips.push({ x: a.x + dx * t, y: a.y + dy * t, ang, text, fs })
            }
            carry = RIVER_CHIP_STEP - ((len - carry) % RIVER_CHIP_STEP)
        }
        return chips
    }

    // a fact desc's claim identity — the (k,v) pair as one string key, matching between the
    //  promotion pre-pass (which claims does EVERY member pane state?) and the ▦ quieting
    //   (drop exactly those from the cell).  Typed descs only: an untyped fact (old gen)
    //    never participates — enrich, never require.
    function claim_id(d: VtuffDesc): string | null {
        if (d.kind !== 'fact' || d.key == null) return null
        return d.key + '' + (d.val ?? '×' + (d.pn ?? ''))
    }

    // the family's shared-trait value — the chip text.  Reach the grasp's `the:family`
    //  value off any member's live particle (the awareness the washes bucket by); fall
    //   back to the family bucket key when the grasp hasn't stamped a value.
    function family_trait(members: VCell[], famKey: string): string {
        for (const m of members) {
            const src = node_src.get(m.id) as any
            const val = src?.c?.D?.o?.({ the: 'family' })?.[0]?.sc?.val
            if (typeof val === 'string' && val) return val
        }
        return famKey
    }

    // last ▦ census signature + the pending census (filled mid-paint, logged at paint's end)
    let vsub_sig = ''
    let vsub_last = { face: '', cells: 0, descs: 0, subs: 0, err: '' }
    // WHY a crater didn't draw (the human: "a couple of Artist lack subcells for their /Track —
    //  why is that a sometimes maybe kinda deal?").  crater_pane returns null AND bumps a reason;
    //   reset per paint, rides the vsub census so the sometimes-ness becomes legible.
    //    small = R below crater.rmin; header = identity below crater.hfloor; geo = degenerate
    //     clip or a band that couldn't seat; nofold = no cross-kind fold structure (mem < 1).
    const crater_skips = { small: 0, header: 0, geo: 0, nofold: 0 }
    let crater_ok = 0
    // last ▧ river signature — paint_final runs per morph frame, so the telemetry
    //  line fires only when the river census (families / arcs / shapes) changes
    let river_sig = ''

    // ── paint_final: the vectorised rest state ────────────────────────────────
    //  cell outlines with the edge-braces IN the path (a brace is a notch of
    //  the border itself, cusp-tip pointing into the cell at the crossing —
    //  tightly coupled: it moves, scales and dies with its wall), a tip dot in
    //  the OTHER end's colour, the Stuffing stretched+molded into the cell.
    // wrap_applied: the last wrap width handed to each cell's content —
    //  the hysteresis memory that keeps the measure→wrap→measure loop damped
    const wrap_applied = new Map<string, number>()
    // ── the GROWTH SPELL ── (the human, 2026-07-15: "if … a cell is way too small for its
    //  content, we could put a spell on the cell to grow it, until the cyto changes enough that
    //   it gets more than enough space and we can remove the spell")
    //  A per-cell multiplier on the seed's content box (voronoi_layout reads it) — the power
    //   walls do the growing; nothing touches cytoscape, so the stream keeps flowing into the
    //    same graph.  Three regimes with a DEAD BAND between them (no flutter):
    //     STARVED (no pane seated, or atoms crowded out — +N)      → the spell grows, ×1.18/beat
    //     ROOMY   (everything seated using < 60% of the height)    → the spell decays, ×0.93/beat
    //     SNUG    (seated, but no great spare)                     → the spell HOLDS
    //  A change re-paints once so the walls actually move — rAF when visible; a hidden tab
    //   paints synchronously (rAF never fires there — the runner's shot would read pre-spell
    //    glass).  The chain terminates on its own (growth saturates at the cap, decay walks to
    //     1 and lifts); the counter is belt-and-braces.
    const vspell = new Map<string, number>()
    let spell_raf = 0, spell_chain = 0
    function spell_update(want: Iterable<string>, panes: VSubPane[], built: Set<string>) {
        const by = new Map(panes.map(p => [p.id, p]))
        // a pane is STARVED if it degraded (no crater/pane seated), crowded claims out (+N), or
        //  seated its identity/claims BELOW the legible floor — a 7px name is "too small" even
        //   though it technically landed (the human: "everything has the ability [to] be too
        //    small … put a spell on the cell to grow it").  Read the load-bearing atoms only
        //     (titles, keys, values) — a decorative sup at 8px is not a starvation signal.
        const LOADED = new Set(['vsub-ntitle', 'vsub-title', 'vsub-gkey', 'vsub-label'])
        // the legible floor (spell.floor, was 11 — the human: "just a bit more text bloat-up
        //  needed"): grow a cell until its load-bearing atoms clear it.  A higher floor also
        //   swells more cells past the crater threshold, so the cradle surfaces on more C's.
        const floor = vknob('spell.floor', 12)
        const grow = vknob('spell.grow', 1.18), decay = vknob('spell.decay', 0.93)
        const growcap = vknob('spell.cap', 3.0)
        const tiny = (p?: VSubPane) => {
            if (!p) return false
            const fss = p.stats.filter(s => LOADED.has(s.cls ?? '')).map(s => s.fs ?? 99)
            return fss.length > 0 && Math.min(...fss) < floor
        }
        // FREEZE the spell mid-drag: pan_zoom_motion repaints every frame while a cell is dragged, and
        //  a grow|shrink verdict landing on one of those frames flips a neighbour crater↔flat — the
        //   residual "blinks during dragging".  Hold all sizes steady until the drop; resume next paint.
        if (vdrag) return
        // HYSTERESIS (the human: "it needs to turn itself off only once the cell becomes even
        //  bigger than the size" — it was oscillating on+off): the GROW gate and the RELEASE gate
        //   are far apart, with a wide HOLD band between them, so a cell that just grew to fit does
        //    NOT immediately read as roomy and shrink back into starvation.  GROW while STARVED
        //     (identity/claims below the legible floor); once it seats fine it HOLDS at that size;
        //      it only LETS GO once the cell is CLEARLY oversized (`p.roomy` = content fills < 42%
        //       of the pane — set stricter than the old 60%).  Gentle steps damp the overshoot that
        //        fed the flip.  So: too small → grow; big enough → hold (never shrink); way too big
        //         → ease off.  A cell that grew this pass is never also shrunk in it.
        let cast = 0, lifted = 0
        const grewNow = new Set<string>()
        for (const id of want) {
            const p = by.get(id)
            const starved = !built.has(id) || (p?.hid?.n ?? 0) > 0 || tiny(p)
            const cur = vspell.get(id) ?? 1
            if (starved) {
                const nxt = Math.min(growcap, cur * grow)   // ceiling spell.cap — room to reach the floor
                if (nxt > cur + 1e-3) { vspell.set(id, nxt); cast++; grewNow.add(id) }
            } else if (p?.roomy && cur > 1 && !grewNow.has(id)) {
                const nxt = cur * decay
                if (nxt <= 1.03) vspell.delete(id); else vspell.set(id, nxt)
                lifted++
            }
        }
        const live = new Set(want)
        for (const id of [...vspell.keys()]) if (!live.has(id)) vspell.delete(id)   // departed cells
        if (!cast && !lifted) { spell_chain = 0; return }
        vlog('spell', { cast, lifted, held: vspell.size })
        if (spell_chain++ > 14) return
        const again = () => { const L2 = voronoi_layout(); if (L2) paint_final(L2) }
        // NEVER inline — spell_update runs INSIDE paint_final, and a synchronous re-paint here
        //  would let the outer (pre-spell) paint finish LAST and clobber the fresh glass.  A
        //   microtask runs after the outer paint returns; it also fires in a hidden tab, where
        //    rAF never would (the runner's shot must read post-spell walls).
        if (document.hidden) queueMicrotask(again)
        else if (!spell_raf) spell_raf = requestAnimationFrame(() => { spell_raf = 0; again() })
    }

    // ── the hover z-lift: feel your way into the pile ────────────────────────
    //  At stuff.scale > 1 neighbouring chunks overlap; the cell under the mouse
    //   lifts its overlay above all the others (the human: "they should z-index
    //    above all others when moused over, so you can feel your way into them").
    //     The glass SVG is pointer-events:none and the node ovals don't tile the
    //      plane, so the wrap's mousemove hit-tests the CELL polygons directly —
    //       ~15 cells × ~8 walls of cross products, cheap enough un-throttled.
    let lift_cells: { id: string, poly: { x: number, y: number }[] }[] = []
    let lift_id: string | null = null
    function in_poly(px: number, py: number, poly: { x: number, y: number }[]): boolean {
        let hit = false
        for (let i = 0, j = poly.length - 1; i < poly.length; j = i++) {
            const a = poly[i], b = poly[j]
            if ((a.y > py) !== (b.y > py) && px < (b.x - a.x) * (py - a.y) / (b.y - a.y) + a.x) hit = !hit
        }
        return hit
    }
    function vlift_apply(id: string | null) {
        if (id === lift_id) return
        if (lift_id) overlays.get(lift_id)?.classList.remove('vlift')
        lift_id = id
        if (id) overlays.get(id)?.classList.add('vlift')
    }
    function vlift_move(e: MouseEvent) {
        if (!lift_cells.length || !wrap_el) return
        const r = wrap_el.getBoundingClientRect()
        const px = e.clientX - r.left, py = e.clientY - r.top
        let hit: string | null = null
        for (const c of lift_cells) if (in_poly(px, py, c.poly)) { hit = c.id; break }
        vlift_apply(hit)
    }

    function paint_final(L: { cells: VCell[], seeds: any[], CW: number }) {
        // mold knobs, read ONCE per paint (hot path): stuff.scale = the molded content's
        //  size on top of its fits-the-cell clamp (1.5 = the split-the-difference ruling,
        //   walked back from 2 — "they're too big now"); stuff.clip = trim the content to
        //    the cell polygon (0 = overflow free, the human's ruling); stuff.top|bottom =
        //     the ABSOLUTE band on the final mold ("there should be a top and bottom
        //      level") — no chunk renders past top× its natural size however huge its
        //       cell, none below bottom× however cramped.
        const mold_scale  = vknob('stuff.scale', 1.5)
        const mold_clip   = vknob('stuff.clip', 0) >= 1
        const mold_top    = vknob('stuff.top', 2)
        const mold_bottom = vknob('stuff.bottom', 0.5)
        // the hover z-lift reads these polygons on every mousemove — refresh per paint,
        //  and re-assert the lifted class (a re-minted overlay el loses it silently)
        lift_cells = L.cells.map(c => ({ id: c.id, poly: c.inset }))
        if (lift_id) overlays.get(lift_id)?.classList.add('vlift')
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
            cells.push({ id: c.id, d, color: c.color, fog: c.tz })

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
                // molded = paint_final's to move — the mark reposition_overlays honours.
                //  (Was the clipPath itself; the clip is a KNOB now, default OFF — the
                //   human: "can they just not clip their cell? that'd be nice.")
                el.dataset.molded = '1'
                el.style.clipPath = mold_clip ? 'polygon(' + c.inset.map(p =>
                    `${(p.x - bx).toFixed(1)}px ${(p.y - by).toFixed(1)}px`).join(',') + ')' : ''
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
                    // the RIGHT amount of space (owner): never paint a Stuffing bigger than
                    //  its cell can hold.  c.fit was computed from the seed's gather-time
                    //   content box, which is CAPPED (260×200) — big content lies to it.
                    //    Re-clamp with the child's TRUE current box under the same support
                    //     formula: the transformed content must fit the cell's bbox on both
                    //      axes.  The polygon clipPath still trims corners; words survive.
                    const chw = (child.offsetWidth || 1) / 2, chh = (child.offsetHeight || 1) / 2
                    const fx = (bw / 2) / Math.max(1e-6, box_support(1, 0, chw, chh, c.T11, c.T12, c.T22, c.T21))
                    const fy = (bh / 2) / Math.max(1e-6, box_support(0, 1, chw, chh, c.T11, c.T12, c.T22, c.T21))
                    // stuff.scale rides ON TOP of the fits-the-cell clamp — above 1 the
                    //  content deliberately overflows its cell; with stuff.clip=0 (the
                    //   default) nothing trims it.  The stuff.top|bottom band then rules
                    //    ABSOLUTELY: a huge cell can't balloon its chunk past top× natural
                    //     size (the "one gets waaay too big"), and a cramped cell never
                    //      grinds below bottom× — it overflows instead, and the hover
                    //       z-lift is how you feel into the resulting pile.
                    const fit = Math.min(mold_top, Math.max(mold_bottom,
                        Math.min(c.fit, fx, fy) * mold_scale))
                    const a  = (fit * c.T11).toFixed(3), b12 = (fit * c.T12).toFixed(3)
                    const b21 = (fit * c.T21).toFixed(3), d2 = (fit * c.T22).toFixed(3)
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

        // ── the desc pre-pass: every pane's rows read ONCE, shared by the promotion
        //  (the regroup face below asks "what does EVERY member state?") and the ▦
        //   sub-graph pass (which draws them).  Panes with fold structure normalise
        //    their Vtuffing; a loner pane speaks its own sc the same grammar — typed
        //     k/v on its facts, so a popped member's claims promote like anyone's.
        const descmap = new Map<string, { descs: VtuffDesc[], tint: string, fkind?: string }>()
        if (subgraph_on && voronoi_on) {
            for (const c of L.cells) {
                const src = node_src.get(c.id) as any
                if (src?.c?.gang || src?.c?.stuff) {
                    const descs = vtuff_rows(src)
                    if (descs.length) {
                        // fkind stays the GRASP kind (the members' level — G1 tagging keys off
                        //  it); the TINT follows cell_color's rule — a real container's header
                        //   badge wears its OWN kind's tint, a gang rep its members' (I1: the
                        //    Artist badge was Track-pink through this line).
                        const own   = (src?.sc && Object.keys(src.sc)[0]) as string | undefined
                        const fkind = (src?.c?.fold_kind ?? own) as string | undefined
                        const ckind = src?.c?.gang ? fkind : (own ?? fkind)
                        descmap.set(c.id, { descs, tint: kind_tint(ckind) ?? '#9ab', fkind })
                        continue
                    }
                }
                if (src?.sc) {
                    const mk = Object.keys(src.sc)[0]
                    if (mk) {
                        const v = src.sc[mk]
                        const nm = (v !== 1 && v != null) ? String(v) : name_ts(src)
                        const nk0 = namekey_ts(src)
                        const descs: VtuffDesc[] = [{ text: nm, kind: 'title', tag: mk,
                                                      nk: nm ? nk0 : undefined }]
                        for (const [k, kv] of Object.entries(src.sc)) {
                            if (k === mk || (nm !== '' && k === nk0)) continue
                            descs.push(kv === 1 ? { text: k, kind: 'fact', key: k }
                                                : { text: `${k}: ${kv}`, kind: 'fact', key: k, val: String(kv) })
                        }
                        descmap.set(c.id, { descs, tint: kind_tint(mk) ?? '#9ab' })
                    }
                }
            }
        }
        // which claims each cell may hush this beat — filled by the promotion below,
        //  consumed by the ▦ pass; a cell not in the map quiets nothing.
        const quiet_map = new Map<string, Set<string>>()
        // the cs FRAME per member cell — the river's local flow direction (radians) where it
        //  passes through that cell, filled by the river fit below, consumed by the ▦ pass:
        //   the cell rotates its sub-cell compass so 0 = DOWNSTREAM.  A cell not in the map
        //    (region off, family of one) keeps the screen-fixed compass — byte-identical.
        const cs_frames = new Map<string, number>()

        // ── ▧ the regroup face (Slice C + D): washes AND rivers, one grouping ─────
        //  group the cells by the grasp's `the:family` (region_of, null-safe) ONCE,
        //   then draw two things per family from the same members so they share a
        //    colour: a translucent FILLED convex-hull backing (the wash — same-family
        //     cells read as one continuous space), and one big tidy arc down its
        //      middle (the river — a trail of one kind flowing through the landscape).
        //   Layout untouched; a family of one is skipped (its own cell already IS its
        //    space).  Off (region_on false) = both blocks skipped, byte-identical.
        const regs: typeof vregions = []
        const rivs: typeof vrivers = []
        if (region_on && L.cells.length > 2) {
            const groups = new Map<string, VCell[]>()
            for (const c of L.cells) {
                const r = region_of(c.id)
                let ms = groups.get(r)
                if (!ms) { ms = []; groups.set(r, ms) }
                ms.push(c)
            }
            let ri = 0
            for (const [rid, members] of groups) {
                ri++
                const color = REGION_COLORS[ri % REGION_COLORS.length]
                // the wash: a filled convex hull of ALL the family's inset vertices
                const pts: {x:number,y:number}[] = []
                for (const m of members) for (const p of m.inset) pts.push(p)
                if (pts.length >= 6) {
                    const hull = convex_hull(pts)
                    if (hull.length >= 3) {
                        let d = `M${P(hull[0].x, hull[0].y)}`
                        for (let k = 1; k < hull.length; k++) d += `L${P(hull[k].x, hull[k].y)}`
                        d += 'Z'
                        regs.push({ id: `reg:${rid}`, d, color })
                    }
                }
                // the river: string the members' centroids into a smooth arc, read its
                //  letterform, and line the shared trait along it.  A family under two
                //   cells has no arc to draw (its lone|paired cell is already the space).
                if (members.length >= 2) {
                    // carry the cell id on each centroid so the ordered walk can hand every
                    //  member its LOCAL river tangent (the cs frame) after ordering
                    const cents = members.map(m => ({ x: m.acx, y: m.acy, id: m.id }))
                    const { seq, wrap } = river_order(cents)
                    // a wrap that truly closes (last centroid back near the first, ≥4
                    //  members) draws the ring shut — that's the O; else an open arc.
                    const first = seq[0], lastc = seq[seq.length - 1]
                    const span = Math.hypot(lastc.x - first.x, lastc.y - first.y)
                    const spread = Math.hypot(
                        Math.max(...cents.map(c => c.x)) - Math.min(...cents.map(c => c.x)),
                        Math.max(...cents.map(c => c.y)) - Math.min(...cents.map(c => c.y)))
                    const closed = wrap && seq.length >= 4 && span < spread * 0.35
                    // the cs FRAME: hand every member the river's LOCAL flow direction where it
                    //  passes through — the tangent from its upstream to its downstream neighbour
                    //   (the ring wraps for a closed O).  The ▦ pass rotates that cell's sub-cell
                    //    compass by this angle, so 0 = downstream and a key sits the same way
                    //     RIVER-relative in every cell: the coordinate system the human named,
                    //      posable and twisted to fit the landform.  Only filled under cs (region_on),
                    //       so cs-off leaves every compass screen-fixed — byte-identical render.
                    const S = seq.length
                    for (let i = 0; i < S; i++) {
                        const id = (seq[i] as any).id as string | undefined
                        if (!id) continue
                        const prev = closed ? seq[(i - 1 + S) % S] : seq[Math.max(0, i - 1)]
                        const next = closed ? seq[(i + 1) % S] : seq[Math.min(S - 1, i + 1)]
                        const tx = next.x - prev.x, ty = next.y - prev.y
                        if (Math.hypot(tx, ty) > 1) cs_frames.set(id, Math.atan2(ty, tx))
                    }
                    const d = catmull_d(seq, closed)
                    if (d) {
                        const shape = letter_of(seq, closed)
                        const trait = family_trait(members, rid)
                        // THE PROMOTION (the 2026-07-14 steer): a claim EVERY member pane
                        //  states is the REGION's story, not any one cell's — say it once,
                        //   big, along the river, and hush it in the members (quiet_map →
                        //    the ▦ pass folds it behind the »N ledger).  Strict ∀ (every
                        //     member, typed claims only); the region-bucket claim itself
                        //      counts as promoted — the trait chip IS its promotion.
                        //       Nothing vanishes: cells mark »N, the river says the words.
                        const texts = [trait]
                        if (descmap.size) {
                            let shared: Map<string, string> | null = null
                            let all = true
                            for (const m of members) {
                                const dm = descmap.get(m.id)
                                if (!dm) { all = false; break }
                                const cm = new Map<string, string>()
                                for (const dd of dm.descs) {
                                    const id = claim_id(dd)
                                    if (id) cm.set(id, dd.text)
                                }
                                if (!shared) shared = cm
                                else for (const id of [...shared.keys()]) if (!cm.has(id)) shared.delete(id)
                                if (!shared.size) break
                            }
                            if (all && shared?.size) {
                                const quiet = new Set<string>()
                                for (const [id, text] of shared) {
                                    quiet.add(id)
                                    const val = id.slice(id.indexOf('') + 1)
                                    if (text !== trait && val !== rid) texts.push(text)
                                }
                                for (const m of members) quiet_map.set(m.id, quiet)
                            }
                        }
                        rivs.push({ id: `riv:${rid}`, d, color, shape,
                                    chips: river_chips(seq, closed, texts) })
                    }
                }
            }
        }
        vregions = regs
        vrivers = rivs
        // per-morph function (a live drag repaints through here) — the film strip only
        //  gets a river line when the census changes, and it speaks the shape mix so a
        //   glance at op:'why' says what letterforms the scape drew this beat
        {
            let promoted = 0
            for (const q of new Set(quiet_map.values())) promoted += q.size
            const sig = rivs.length + ':' + rivs.map(r => r.shape).join('') + ':' + promoted
            if (sig !== river_sig) {
                river_sig = sig
                const shapes: Record<string, number> = {}
                for (const r of rivs) shapes[r.shape] = (shapes[r.shape] ?? 0) + 1
                vlog('river', { fams: regs.length, arcs: rivs.length, shapes, promoted })
            }
        }

        // ── ▦ the sub-graph pass: EVERY pane speaks the grammar, ALL of it ──
        //  folds|gangs tessellate radially (nucleus core → fact belt → member rim);
        //   loners tessellate their own sc the same way; slivers degrade to their one
        //    statement + the +N fold mark — so ▦ mode has ONE face at every size and
        //     hides nothing (the Stuffings are the OTHER mode, ▦ off).  Only a hairline
        //      pane that can't carry a word keeps its Stuffing — never blank glass.
        //       Both cadences: the tree is cached .g-side and the geometry is the same
        //        closed math as the parent scape, so sub-cells track a drag live.
        if (subgraph_on && voronoi_on) {
            const subs: VSubPane[] = []
            const next = new Set<string>()
            let sub_err = ''
            const face_wants: Parameters<typeof sub_faces_sync>[0] = []
            const sub_subh = vknob('stuff.subh', 110), sub_subw = vknob('stuff.subw', 220)
            crater_skips.small = crater_skips.header = crater_skips.geo = crater_skips.nofold = 0
            crater_ok = 0
            for (const c of L.cells) {
                // ztuffing sub-faces: a faced MEMBER of this cell's fold|gang claims a slot
                //  along the cell's bottom band (side-by-side, centred) — its component mounts
                //   there via sub_faces_sync below.  The member still reads in the pane's rows
                //    too (the face ADDS a body, it doesn't hush the claim).
                {
                    const fsrc = node_src.get(c.id) as any
                    const kids: TheC[] = (fsrc?.c?.gang as TheC[] | undefined)
                        ?? (fsrc?.c?.stuff && typeof fsrc?.o === 'function' ? fsrc.o() : [])
                    const faced = (kids ?? []).map(m => ({ m, kind: sub_face_kind(m) }))
                                              .filter(f => f.kind) as { m: TheC, kind: string }[]
                    if (faced.length) {
                        const fxs = c.inset.map(p => p.x), fys = c.inset.map(p => p.y)
                        const fbx = Math.min(...fxs), fby = Math.min(...fys)
                        const fbw = Math.max(...fxs) - fbx, fbh = Math.max(...fys) - fby
                        const sh = Math.min(fbh * 0.5, sub_subh)
                        const sw = Math.min(fbw / faced.length, sub_subw)
                        const fx0 = fbx + (fbw - sw * faced.length) / 2
                        const dups = new Set<string>()
                        faced.forEach((f, i) => {
                            let key = `${c.id}·${stuff_stash_key(f.m)}`
                            while (dups.has(key)) key += "'"
                            dups.add(key)
                            face_wants.push({ key, kind: f.kind, n: f.m,
                                x: fx0 + i * sw, y: fby + fbh - sh, w: sw, h: sh })
                        })
                    }
                }
                // the pre-pass already read every pane (fold|gang via its Vtuffing, a loner
                //  via its own sc — same grammar, no key special); here each cell just draws,
                //   hushing the claims its region's river now speaks for it (quiet_map).
                const dm = descmap.get(c.id)
                if (!dm) continue
                let pane: VSubPane | null = null
                try { pane = subgraph_build(c, dm.descs, dm.tint, dm.fkind, quiet_map.get(c.id), cs_frames.get(c.id) ?? 0) }
                catch (e) { sub_err = String(e).slice(0, 120) }   // one broken pane must not blank the glass
                if (!pane) continue
                // ϕ owns all VISIBLE text (the lettering rides on top), but the pane's stats stay
                //  as DATA — the growth spell reads them, so cells still grow under ϕ and craters/
                //   structure surface on small cells.  The blanking is render-time now (markup gates
                //    the stats render on face !== 'phi'), not build-time.
                next.add(c.id)
                subs.push(pane)
            }
            // ϕ: build the global lettering layer off the SAME descs — every desc'd cell gets
            //  labels even where its pane degraded.  LIVE mid-drag (phi.livedrag=1, the default):
            //   hysteresis (phi_prev) re-validates most labels in place, so a per-frame rebuild is
            //    cheap and streams blinklessly — the dragged cell's block follows its home.  With
            //     livedrag=0 keep the old freeze.  A cheap perf FLOOR: >400 labels freezes regardless.
            if (vsub_face === 'phi') {
                const livedrag = vknob('phi.livedrag', 1) >= 1
                const big = (vphi?.labels ?? 0) > 400
                if (!vdrag || !vphi || (livedrag && !big)) vphi = phi_build(L.cells, descmap, quiet_map)
            } else vphi = null
            vsub_last = { face: vsub_face, cells: L.cells.length, descs: descmap.size,
                          subs: subs.length, err: sub_err }
            for (const id of next) { const mel = overlays.get(id); if (mel) mel.style.opacity = '0' }
            for (const id of sub_on_ids) if (!next.has(id)) {
                const mel = overlays.get(id); if (mel) mel.style.opacity = ''
            }
            sub_on_ids = next
            vsubs = subs
            sub_faces_sync(face_wants)
            // the spell pass reads this beat's verdicts (starved|roomy|snug per cell that
            //  WANTED a pane) and re-paints once if any spell moved — see spell_update above.
            //   Runs under ϕ too now: the stats survive as data (blanking is render-time), so
            //    the spell reads real sizes and GROWS small cells — structure returns under ϕ.
            spell_update(descmap.keys(), subs, next)
            // a swapped cell wears the Stuffing's chrome (dotted rim + fuller
            //  glass) so the pane still reads as a Stuffing, not a flat panel.
            for (const cc of cells) if (next.has(cc.id)) cc.swapped = true
        } else if (sub_on_ids.size || vsubs.length) {
            for (const id of sub_on_ids) {
                const mel = overlays.get(id); if (mel) mel.style.opacity = ''
            }
            sub_on_ids = new Set()
            vsubs = []
            vphi = null
            sub_faces_sync([])
        }

        // a seed whose cell got swallowed falls back to plain node-centering
        for (const s of L.seeds) {
            if (cell_by_id.has(s.id)) continue
            const el = overlays.get(s.id)
            if (!el) continue
            delete el.dataset.molded
            el.style.clipPath = ''; el.style.width = ''; el.style.height = ''; el.style.maxWidth = ''
            const inner = el.firstElementChild as HTMLElement | null
            if (inner) { inner.style.transform = ''; inner.style.width = ''; inner.style.maxWidth = '' }
            wrap_applied.delete(s.id)
            el.style.left = `${s.x - el.offsetWidth / 2}px`
            el.style.top  = `${s.y - el.offsetHeight / 2}px`
        }
        vcells = cells
        vtips = tips
        // ▦ census on the telemetry rails, at the TRUE END of paint (op:'why' reads it) —
        //  captures the fresh vsubs/vtips/vcells so an empty glass says WHY: no sources
        //   (descs 0 = node_src lost post-HMR), every pane degrading, or a builder throwing.
        //    One line only when the census CHANGES (never a per-drag-frame flood).
        const uniq = new Set(vsubs.map(s => s.id)).size   // a keyed-each dup id blanks the WHOLE block
        // ϕ signature: placed/labels-folded ONLY — held/moved churn every drag frame, so they ride
        //  the census payload (observable) but are EXCLUDED from the change-sig (never re-log a frame).
        const phisig = vphi ? `:ϕ${vphi.arcs.length}/${vphi.labels}-${vphi.folded}` : ''
        // WHY-NOT-CRATER census: the craters run under tuples AND phi (phi builds the panes as
        //  underpainting), so answer the human's "why a sometimes deal?" on either face whenever a
        //   counter fired.  Fold the numbers into the sig so a change re-logs.
        const ck = crater_skips
        const cratLive = (vsub_last.face === 'tuples' || vsub_last.face === 'phi')
                       && (crater_ok + ck.small + ck.header + ck.geo + ck.nofold) > 0
        const cratsig = cratLive ? `:C${crater_ok}/${ck.small}/${ck.header}/${ck.geo}/${ck.nofold}` : ''
        const vsig = `${vsub_last.face}:${cells.length}:${vsub_last.descs}:${vsub_last.subs}:${vsubs.length}:${uniq}:${tips.length}:${vsub_last.err}${phisig}${cratsig}`
        if (vsig !== vsub_sig) {
            vsub_sig = vsig
            vlog('vsub', { face: vsub_last.face, cells: cells.length, descs: vsub_last.descs,
                           built: vsub_last.subs, vsubs: vsubs.length, uniq, vtips: tips.length,
                           ...(vphi ? { phi: { labels: vphi.labels, placed: vphi.arcs.length,
                                               folded: vphi.folded, boosted: phi_boost.size,
                                               held: vphi.held, moved: vphi.moved } } : {}),
                           ...(cratLive ? { crater: { ok: crater_ok, small: ck.small,
                                               header: ck.header, geo: ck.geo, nofold: ck.nofold } } : {}),
                           ...(vsub_last.err ? { err: vsub_last.err } : {}) })
        }
    }

    // ── morph_voronoi: tween shown → next generation, then paint the rest state ──
    function morph_voronoi() {
        if (dragging) return   // live-drag owns the repaint; don't fight it
        const L = voronoi_layout()
        if (!L) {
            // the conversion FAILED this call — why (the F1 diagnosis, live): armed?  enough seeds?
            vlog('morph✗', { von: voronoi_on ? 1 : 0, seeds: stuff_mounts.size,
                             need: voronoi_on ? (stuff_mounts.size < 2 ? '<2 seeds' : 'layout null') : 'not armed' })
            if (vcells.length || vtips.length) clear_voronoi()
            settle_overlay_show()
            mark_settled()   // even an empty/degenerate render has "landed" — don't hang the Run (F2)
            return
        }
        vlog('morph', { seeds: stuff_mounts.size, cells: L.cells.length })
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
        // still (nothing moved) OR a HIDDEN tab jump straight to the settled paint — no tween.
        //  A background tab (every headless runner: booted ?B=, never focused) PAUSES
        //   requestAnimationFrame, so the animating branch below would clear vsubs/vtips and
        //    NEVER reach its terminal paint_final to restore them — the glass renders cells but
        //     blank sub-cells (the whole "0 vsub-groups" headless-capture bug, 2026-07-14).  A
        //      hidden tab has no animation to watch anyway, so the settled paint IS the right
        //       frame; a visible tab still tweens.  This also cleans up the dying cells the plain
        //        `still` path skipped (it's guarded on dying.length===0).
        if (still || document.hidden) {
            for (const c of L.cells) shown_pts.set(c.id, targets.get(c.id)!)
            for (const dc of dying) { shown_pts.delete(dc.id); shown_color.delete(dc.id) }
            paint_final(L); settle_overlay_show(); mark_settled(); return
        }

        cancelAnimationFrame(morph_raf)
        vtips = []   // tips re-arrive with the settled walls
        vsubs = []   // sub-cells too — stale walls mid-tween would lie
        // rAF-THROTTLE SAFETY NET: the tween restores vtips/vsubs only when its frame loop
        //  reaches k>=1.  An UNFOCUSED window (document.hidden false, so the sync path above
        //   didn't fire) throttles rAF to ~1fps, stretching a 300ms tween to seconds during
        //    which the glass shows cells but blank sub-cells.  setTimeout is NOT rAF-throttled,
        //     so it force-lands the settled paint if the tween hasn't by then — the render is
        //      never left mid-clear (the transient "0 vsub-groups" a headless shot could catch).
        if (morph_backstop) clearTimeout(morph_backstop)
        morph_backstop = setTimeout(() => {
            morph_backstop = null
            if (vsubs.length) return                       // the tween already landed
            cancelAnimationFrame(morph_raf)
            for (const c of L.cells) shown_pts.set(c.id, targets.get(c.id)!)
            for (const dc of dying) { shown_pts.delete(dc.id); shown_color.delete(dc.id) }
            paint_final(L); settle_overlay_show(); mark_settled()
        }, MORPH_MS + 150)
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
                if (morph_backstop) { clearTimeout(morph_backstop); morph_backstop = null }
                for (const dc of dying) { shown_pts.delete(dc.id); shown_color.delete(dc.id) }
                paint_final(L)
                settle_overlay_show()
                mark_settled()   // morph tween complete — the render has landed (F2)
            }
        }
        morph_raf = requestAnimationFrame(frame)
    }

    function clear_voronoi() {
        cancelAnimationFrame(morph_raf)
        lift_cells = []
        vlift_apply(null)
        vcells = []
        vtips = []
        vfams = []
        vrivers = []
        vsubs = []
        vphi = null
        for (const id of sub_on_ids) { const mel = overlays.get(id); if (mel) mel.style.opacity = '' }
        sub_on_ids.clear()
        shown_pts.clear()
        shown_color.clear()
        wrap_applied.clear()
        for (const el of overlays.values()) {
            if (!el.classList.contains('stuff-overlay') && !el.classList.contains('face-overlay')) continue
            delete el.dataset.molded
            el.style.clipPath = ''; el.style.width = ''; el.style.height = ''; el.style.maxWidth = ''
            const inner = el.firstElementChild as HTMLElement | null
            if (inner) { inner.style.transform = ''; inner.style.width = ''; inner.style.maxWidth = '' }
        }
        sub_faces_sync([])
        reposition_overlays()
    }

//#endregion
//#region apply

    function apply(wave: TheC, dur: number) {
        if (!cy) return
        // the commission's face opt-in, ferried c-side on every wave (Cyto make_wave) —
        //  gates the ztuffing sub-face mounts by the same believing rule as the node grain.
        waves_use_faces = !!(wave as any).c?.use_faces
        rush_animations()
        animations = _C({ animations: 1, started_at: performance.now() / 1000 })
        const ms = Math.round(dur * 1000)
        // F2 — the story_step this wave paints (rides on wave.sc.step_n, stamped in
        //  cyto_update_wave).  mark_settled stamps it as cy_settled once the render lands,
        //   and e_Cyto_animation_request awaits that.  Coerce defensively — an elvis-borne
        //    step can arrive as a string; a non-number would silently never match.
        const applied = Number(wave.sc.step_n)
        if (Number.isFinite(applied)) applied_step = applied
        // telemetry: the wave's shape — a `stuff:0` wave every beat IS an empty world
        //  (the seed never fired: the F6/VoroScape-is-just-self tell, now legible here)
        vlog('wave', { up: wave.o({ upsert: 1 }).length, rm: wave.o({ remove: 1 }).length,
                       stuff: (wave.o({ upsert: 1 }) as TheC[]).filter(n => n.sc.overlay_kind === 'stuff').length,
                       abs: wave.sc.absolute ? 1 : 0, von: voronoi_on ? 1 : 0, seeds: stuff_mounts.size })
        let length = wave.o({ upsert: 1 }).length
        // node ids BORN this wave — so a purely-additive wave can PIN the already-settled
        //  graph and let fcose place only the newcomers (see the layout step below): a late
        //   add of disconnected nodes (the witness %see claims) otherwise makes fcose re-pack
        //    the whole graph into a diagonal and throws away the grown rosette.
        const fresh_ids = new Set<string>()

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
                fresh_ids.add(id)
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
                if ((src as any)?.c?.stuffy) { if (!saw_stuffy) vlog('armed', { id }); saw_stuffy = true }
                proper_mounted.delete(id)    // wave-owned now; toggling proper off must not strip it
                create_stuff_overlay(id, src, overlay_bg, !!nd.sc.overlay_self)
                // a mounted gang rep: merge the mirror every wave (delta-only —
                //  untouched rows never bump, so a quiet gang costs no commit)
                if ((src as any)?.c?.gang && overlays.has(id)) gang_stuff(id, src as TheC)
            } else if (overlay_kind === 'face' && nd.sc.overlay_face) {
                // a registered face component (glass_kinds.ts) rides the same rail as a Stuffing
                create_face_overlay(id, src, String(nd.sc.overlay_face))
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
            // PURELY-ADDITIVE wave (nothing removed) with a grown graph already on screen:
            //  pin the settled nodes so the newcomers tuck in without re-tumbling everything.
            //   The first wave (flora born) is all-fresh → nothing to pin → full free layout.
            //  A FLOOD (newcomers outnumber the settled 2:1 — the 2-nodes→whole-bunch jump) is
            //   the opposite regime: there is no grown rosette worth protecting, and one pass
            //    from a near-empty board leaves a half-settled heap (the owner ran ⟳ by hand).
            //     So a flood pins nothing and buys a SECOND free pass once the first settles.
            let pins: any[] | null = null
            const additive = !wave.o({ remove: 1 }).length && !wave.o({ edge_remove: 1 }).length
            const settled_real = cy.nodes().filter((n: any) =>
                !fresh_ids.has(n.id()) && !n.hasClass('nucleus') && !n.isParent() && n.inside())
            const flood = fresh_ids.size > Math.max(2, 2 * settled_real.length)
            if (additive && fresh_ids.size && !flood) {
                const settled = cy.nodes().filter((n: any) =>
                    !fresh_ids.has(n.id()) && !n.hasClass('nucleus') && n.inside())
                if (settled.length)
                    pins = settled.map((n: any) => ({ nodeId: n.id(), position: { x: n.position('x'), y: n.position('y') } }))
            }
            relayout(ms, pins)
            if (flood && ms > 0) {
                // a 2nd free pass is OWED — hold the Run's settle (F2) until it lands, so the
                //  Run can't advance on the half-heap the first pass leaves.  Cleared on the
                //   2nd relayout's layoutstop; the morph after that then marks settled.
                //  (ms>0 only: a dur=0 yoink apply never animates → no layoutstop to clear on.)
                flood_pending = true
                vlog('flood', { fresh: fresh_ids.size, settled: settled_real.length })
                cy.one('layoutstop', () =>
                    setTimeout(() => {
                        cy.one('layoutstop', () => { flood_pending = false })
                        relayout(Math.max(ms, 300))
                    }, 80))
            }
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
    function relayout(animMs = 300, pins: any[] | null = null, randomize = false) {
        lay?.stop()
        const common = {
            animate:                     animMs > 0,
            animationDuration:           animMs,
            nodeDimensionsIncludeLabels: true,
            // randomize only on a diag_check escalation — a free re-lay that fell straight
            //  back onto the balanced line needs its symmetry broken, everyone else keeps
            //   their grown positions
            randomize,
        }
        // fixedNodeConstraint pins already-settled nodes (apply() passes them on a purely-
        //  additive wave) so a late node-add can't re-tumble the grown layout; a manual ⟳
        //   passes none and re-lays the whole graph freely.  Only fcose honours it.
        const pinCons = pins && pins.length ? { fixedNodeConstraint: pins } : {}
        let opts: any
        if (layout_name === 'fcose') {
            opts = { name: 'fcose', ...common, nodeSeparation: 30, quality: 'default',
                idealEdgeLength: (e: any) => e.data('ideal_length') ?? 80,
                edgeElasticity:  0.45, nodeRepulsion: () => 4000,
                ...constraints, ...pinCons }
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

    // the whole board collapses onto one line — a degenerate fcose equilibrium; detect it, break it.
    //  why it sticks: on a line every force cancels along it, so nothing ever pushes a node back off.
    //   the fresh_ids pins stop the classic trigger (a late disconnected add re-packs the board),
    //    not a collapse that forms anyway — that one sat until a manual ⟳.
    //  the cure is a free relayout — the human's own observation: it leaves a healthy board alone,
    //   but a repeat means it fell straight back, so randomize to break the symmetry; three failures rest.
    //  detection: the principal-axis spread ratio of the real node positions (2×2 covariance eigenvalues).
    //   √(minor/major) ~0 a line, ~1 a disc; a healthy rosette > 0.25, a satan < 0.1; gate at 0.1.
    let diag_cures  = 0     // total auto-cures this mount — stashed on top_House.c so op:'shot' can report it
    let diag_streak = 0     // consecutive still-diagonal settles — a cure that doesn't take escalates, then rests
    function diagonal_ratio(): number | null {
        if (!cy) return null
        const pts: {x:number,y:number}[] = []
        cy.nodes().forEach((n: any) => {
            if (n.isParent() || is_nucleus(n)) return
            pts.push(n.position())
        })
        if (pts.length < 6) return null   // a tiny board lines up legitimately
        let mx = 0, my = 0
        for (const p of pts) { mx += p.x; my += p.y }
        mx /= pts.length; my /= pts.length
        let xx = 0, yy = 0, xy = 0
        for (const p of pts) { const dx = p.x - mx, dy = p.y - my; xx += dx*dx; yy += dy*dy; xy += dx*dy }
        const tr = xx + yy, det = xx*yy - xy*xy
        const disc  = Math.sqrt(Math.max(0, tr*tr/4 - det))
        const major = tr/2 + disc
        if (major <= 0) return null
        return Math.sqrt(Math.max(0, tr/2 - disc) / major)
    }
    let diag_timer: ReturnType<typeof setTimeout> | null = null
    function diag_check_soon() {
        if (diag_timer) clearTimeout(diag_timer)
        // past the wave queue's settle pad, so a draining batch is judged at rest, not mid-tween
        diag_timer = setTimeout(diag_check, 1200)
    }
    function diag_check() {
        diag_timer = null
        if (!cy || dragging || anim_busy || wave_queue.length) { diag_check_soon(); return }
        const r = diagonal_ratio()
        if (r === null) return
        if (r > 0.1) { diag_streak = 0; mark_settled(); return }   // healthy (or healed) — re-arm the escalation, and a healed board is a rest (F2)
        diag_streak++
        if (diag_streak > 3) return   // three cures didn't take — stop thrashing; next wave re-arms via the streak reset
        diag_cures++
        try { (H.top_House().c as any).cy_diag_cures = diag_cures } catch { /* report is best-effort */ }
        vlog('diag_cure', { ratio: +r.toFixed(3), streak: diag_streak, randomize: diag_streak > 1 ? 1 : 0 })
        console.warn(`♒ diagonal satan (spread ratio ${r.toFixed(3)}, n=${cy.nodes().length}) — free relayout, cure #${diag_cures}${diag_streak > 1 ? ` (streak ${diag_streak}: randomize)` : ''}`)
        // first cure = the owner's manual ⟳ (free, unpinned); a repeat means the free re-lay
        //  fell straight back into the same balanced line — toss positions to break the symmetry.
        relayout(400, null, diag_streak > 1)
    }

    // ── cytoscape init ────────────────────────────────────────────────────────
    onMount(() => {
        const stashed_v = (H as any).stashed?.Cyto_voronoi
        if (typeof stashed_v === 'boolean') voronoi_pref = stashed_v
        const stashed_p = (H as any).stashed?.Cyto_properCellable
        if (typeof stashed_p === 'boolean') proper_pref = stashed_p
        const stashed_f = (H as any).stashed?.Cyto_families
        if (typeof stashed_f === 'boolean') families_pref = stashed_f
        const stashed_reg = (H as any).stashed?.Cyto_regions
        if (typeof stashed_reg === 'boolean') region_pref = stashed_reg
        const stashed_b = (H as any).stashed?.Cyto_gravity_brush
        if (typeof stashed_b === 'boolean') brush_pref = stashed_b
        const stashed_sg = (H as any).stashed?.Cyto_subgraph
        if (typeof stashed_sg === 'boolean') subgraph_pref = stashed_sg
        const stashed_vf = (H as any).stashed?.Cyto_vsub_face
        if (stashed_vf === 'tuples' || stashed_vf === 'star' || stashed_vf === 'phi') vsub_face = stashed_vf
        // live knob overrides survive a reload alongside the face (Attractor Ground)
        const sk = (H as any).stashed?.Cyto_knobs
        if (sk && typeof sk === 'object') vknobs = { ...sk }
        const stashed_cr = (H as any).stashed?.Cyto_craters
        if (stashed_cr === 0 || stashed_cr === false) vsub_craters = false
        else if (stashed_cr === 1 || stashed_cr === true) vsub_craters = true
        if (DRIFT_MODES_ON) {   // shelved: a stashed true from the play days must not resurrect the drift
            const stashed_r = (H as any).stashed?.Cyto_radio
            if (stashed_r === true) { radio_pref = true; radio_timer = setInterval(radio_tick, RADIO_DWELL) }
            const stashed_tu = (H as any).stashed?.Cyto_tunnel
            if (typeof stashed_tu === 'boolean') tunnel_pref = stashed_tu
        }
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

        // stash the live cytoscape handle where a GHOST can reach it — scripts/runner_shot.mjs asks
        //  Lies_runner_ask_recv (op:'shot') for cy.png() so a headless caller can finally SEE the
        //   rendered power-diagram: the one fault class no snap carries (pixels never round-trip a
        //    fixture).  top_House.c.cy is per-tab + never snapped (a live object belongs only in .c).
        try { (H.top_House().c as any).cy = cy } catch { /* no House root yet — a shot just reports none */ }

        // the remote FACE-ARM (runner_shot --arm → LiesFunk op:'face'): set this tab's ◈/▧/▦
        //  prefs over the ask rails — the stashes are per-tab, so before this a headless caller
        //   could never SEE a face nobody armed here.  Same writes as the toggles (pref + stash
        //    + repaint), SET not flip; answers the resulting gate so the caller knows what it got.
        try {
            (H.top_House().c as any).cy_face = (f: any) => {
                const sts = (H as any).stashed
                if (f.voronoi != null) { voronoi_pref = !!f.voronoi; if (sts) sts.Cyto_voronoi = voronoi_pref }
                if (f.regions != null) {
                    region_pref = !!f.regions
                    if (sts) sts.Cyto_regions = region_pref
                    if (!region_pref) { vregions = []; vrivers = [] }
                }
                if (f.subgraph != null) {
                    subgraph_pref = !!f.subgraph
                    if (sts) sts.Cyto_subgraph = subgraph_pref
                    if (!subgraph_pref) {
                        for (const id of sub_on_ids) { const mel = overlays.get(id); if (mel) mel.style.opacity = '' }
                        sub_on_ids = new Set(); vsubs = []
                    }
                }
                // the ▦ face parameter — 'tuples' (snap-notation rows) | 'star' (the radial
                //  gem) | 'phi' (the golden lettering layer: --face=vsub:phi)
                if (f.vsub === 'tuples' || f.vsub === 'star' || f.vsub === 'phi') {
                    vsub_face = f.vsub
                    if (sts) sts.Cyto_vsub_face = f.vsub
                }
                // B1: the C-space craters, A/B'd against flat tuples (--face=craters:0|1)
                if (f.craters != null && !Number.isNaN(f.craters)) {
                    vsub_craters = !!f.craters
                    if (sts) sts.Cyto_craters = vsub_craters ? 1 : 0
                }
                // ── the Attractor Ground: live knobs + named moments over the same rails ──
                let knob_err: string | undefined
                // f.knobs → hand back the whole registered table (name → {def, val}); nothing set.
                if (f.knobs) {
                    const table: Record<string, { def: number, val: number }> = {}
                    for (const k of Object.keys(vknob_defs).sort())
                        table[k] = { def: vknob_defs[k], val: vknobs[k] ?? vknob_defs[k] }
                    return { knobs: table }
                }
                // f.knob "name=value" → set one override (delete when it equals the default).
                //  An unknown name is REFUSED (its default is never registered until a use site
                //   reads it, so a typo can't silently invent a knob); persist the whole map.
                if (typeof f.knob === 'string') {
                    const eq = f.knob.indexOf('=')
                    const nm = (eq >= 0 ? f.knob.slice(0, eq) : f.knob).trim()
                    const vv = eq >= 0 ? Number(f.knob.slice(eq + 1)) : NaN
                    if (!(nm in vknob_defs)) knob_err = `unknown knob ${nm}`
                    else if (Number.isNaN(vv)) knob_err = `bad value for ${nm}`
                    else {
                        if (vv === vknob_defs[nm]) delete vknobs[nm]; else vknobs[nm] = vv
                        vknobs = { ...vknobs }
                        if (sts) sts.Cyto_knobs = { ...vknobs }
                    }
                }
                // f.moment_save/load/list/drop → a snapshot IS (face + knob overrides); a judge
                //  flips between saved entries on the same live data (spec/Attractor_todo.md).
                let moment_err: string | undefined, moment_out: any
                const moments = (): Record<string, { face: string, knobs: Record<string, number> }> =>
                    ((sts && (sts.Cyto_moments ??= {})) || {})
                if (typeof f.moment_save === 'string' && f.moment_save) {
                    moments()[f.moment_save] = { face: vsub_face, knobs: { ...vknobs } }
                }
                if (typeof f.moment_load === 'string' && f.moment_load) {
                    const m = moments()[f.moment_load]
                    if (!m) moment_err = `no moment ${f.moment_load}`
                    else {
                        if (m.face === 'tuples' || m.face === 'star' || m.face === 'phi') vsub_face = m.face
                        vknobs = { ...(m.knobs ?? {}) }
                        if (sts) { sts.Cyto_vsub_face = vsub_face; sts.Cyto_knobs = { ...vknobs } }
                    }
                }
                if (typeof f.moment_drop === 'string' && f.moment_drop) delete moments()[f.moment_drop]
                if (f.moment_list) {
                    const list: Record<string, { face: string, nknobs: number }> = {}
                    for (const [nm, m] of Object.entries(moments()))
                        list[nm] = { face: m.face, nknobs: Object.keys(m.knobs ?? {}).length }
                    moment_out = { moments: list }
                }
                voronoi_soon()
                if (moment_out) return moment_out
                return { voronoi: voronoi_on, regions: region_on, subgraph: subgraph_on,
                         vsub: vsub_face, craters: vsub_craters, knobs: Object.keys(vknobs).length,
                         ...(knob_err ? { knob_err } : {}), ...(moment_err ? { moment_err } : {}) }
            }
        } catch { /* no House root yet */ }

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
        // touching the dial: any motion that isn't the radio's own glide holds the tuner off
        cy.on('grab pan zoom', () => { if (!radio_gliding) radio_hold_until = Date.now() + 15000 })
        cy.on('layoutstart', () => start_live_layout())
        cy.on('layoutstop',  () => {
            stop_live_layout(); show_overlays_soon()
            // the "state-shaking-out layout()" the owner named as the telemetry epoch: stamp it,
            //  and log the settle geometry (ratio ~0 = the diagonal satan; the morph fires next,
            //   via show_overlays_soon's OVERLAY_QUIET_MS debounce → its own 'morph' entry)
            last_settle_t = performance.now()
            vlog('settle', { ratio: +(diagonal_ratio() ?? -1).toFixed(3), nodes: cy.nodes().length, seeds: stuff_mounts.size })
            diag_check_soon()
        })
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
            if (radio_timer) { clearInterval(radio_timer); radio_timer = null }
            clear_all_overlays()
            cy?.destroy()
        }
    })
</script>

<!-- Escape clears a stuck correspondence hover (see corr_clear) — top-level, as svelte:window must be -->
<svelte:window onkeydown={(e) => { if (e.key === 'Escape') corr_clear(true) }} />

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
        <button class="v-toggle v-cs" class:on={region_on} onclick={toggle_regions}
            title="rivers — the C/S squiggles: family washes + letterform arc-rivers (I/C/S/O) with ∀-shared claims promoted onto them (»N receipts in the cells).  PARKED OFF (the human, 2026-07-14: the squiggles aren't earning their ink yet; the cross-cell harmony they gesture at now lives in the tuples face's shared baselines)">∿</button>
        <button class="v-toggle" class:on={brush_pref} onclick={toggle_brush}
            title="gravity brush — wheel pinches|spreads the locale under the cursor (Ctrl+wheel still zooms)">🌀</button>
        <button class="v-toggle" class:on={subgraph_on} onclick={toggle_subgraph}
            title="sub-graph — every pane speaks the glass grammar and hides nothing; slivers say their one statement + a +N fold mark (off = molded Stuffings everywhere).  Face rides the vsub_face PARAMETER, not a button: 'tuples' (default — snap-notation rows aligned to the cell's best wall) | 'star' (the radial gem) | 'phi' (the golden lettering layer — labels claim groove arcs, text never obscures text)">▦</button>
        {#if DRIFT_MODES_ON}
            <button class="v-toggle" class:on={radio_on} onclick={toggle_radio}
                title="radio — the graph plays you: a tuner drifts attention pane to pane and opens each a little (touch anything to hold it off)">📻</button>
            <button class="v-toggle" class:on={tunnel_pref ?? false} onclick={toggle_tunnel}
                title="tunnel — the tessellation drifts down a tube: solidity takes the left wall, the opening reads as a C, and radio dwells advance the drift">🕳</button>
        {/if}
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
         onmousemove={vlift_move} onmouseleave={() => vlift_apply(null)}
         onpointerdown={wrap_pointerdown} onkeydown={wrap_key} onwheelcapture={visor_guard}
         onpointerleave={() => corr_clear()}>
        <div class="cytui-graph" bind:this={container}></div>
        <!-- voronoi layer between the canvas and the HTML overlays: the veil dims
             the raw graph so the cells (and the Stuffings stretched into them)
             carry the reading; it hides with the overlays during motion. -->
        <svg class="cytui-voronoi" style:opacity={motion_hidden ? 0 : 1}>
            {#if voronoi_on && vcells.length}
                <rect class="cytui-veil" width={vregion_w || '100%'} height="100%" />
                <!-- ▧ region washes (Slice C): beneath EVERYTHING, one translucent
                     filled convex hull per grasp `the:family`, so same-family cells
                     read as one continuous space.  Off by default → vregions empty →
                     nothing draws here and the layer is byte-identical to before.
                     A faint matching stroke seams the region's outer edge. -->
                {#each vregions as reg (reg.id)}
                    <path d={reg.d} fill={reg.color} fill-opacity="0.09"
                        stroke={reg.color} stroke-opacity="0.28" stroke-width="1.5"
                        stroke-linejoin="round" />
                {/each}
                <!-- ▧ arc-rivers (Slice D): between the washes and the cell strokes, one
                     wide translucent riverbed per family — the family's centroids fitted
                     into a big tidy I|C|S|O and stroked in its wash colour, so a river of
                     one kind reads as flowing through the landscape.  Rides the same
                     region_on toggle → vrivers empty when off, nothing draws here.  The
                     data carries its own letterform (river.shape) so op:'why' can say it. -->
                {#each vrivers as river (river.id)}
                    <path d={river.d} fill="none" stroke={river.color}
                        stroke-opacity="0.14" stroke-width="22"
                        stroke-linecap="round" stroke-linejoin="round" />
                    <path d={river.d} fill="none" stroke={river.color}
                        stroke-opacity="0.30" stroke-width="6"
                        stroke-linecap="round" stroke-linejoin="round" />
                    <!-- the debris: the family's shared trait as tiny chips lined along
                         the trail, each rotated to the local tangent — the zen-garden
                         "lined up tuples", higher opacity than the bed so they read. -->
                    {#each river.chips as chip, ci (ci)}
                        <text class="cytui-river-chip" x={chip.x.toFixed(1)} y={chip.y.toFixed(1)}
                            fill={river.color} text-anchor="middle" font-size="{chip.fs}px"
                            transform={`rotate(${chip.ang.toFixed(1)} ${chip.x.toFixed(1)} ${chip.y.toFixed(1)})`}>{chip.text}</text>
                    {/each}
                {/each}
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
                    <!-- a swapped (▦ sub-graph) cell wears the Stuffing's tabletty
                         dotted rim + a fuller glass fill; plain cells keep the
                         thin solid stroke.  Colour is the kind's swatch|hue. -->
                    <!-- fog: a tunnel cell fades with depth (fog = NEAR/d, 1 at the
                         camera); the stroke keeps a floor so the far glasswork still
                         draws as leading.  fog absent (tunnel off) = full strength. -->
                    <path d={cell.d}
                        fill={cell.color} fill-opacity={(cell.swapped ? 0.2 : 0.13) * (cell.fog ?? 1)}
                        stroke={cell.color} stroke-opacity={(cell.swapped ? 0.85 : 0.6) * (0.35 + 0.65 * (cell.fog ?? 1))}
                        stroke-width={cell.swapped ? 1.75 : 1.5}
                        stroke-dasharray={cell.swapped ? '1.5 3' : undefined}
                        stroke-linecap="round" stroke-linejoin="round" />
                {/each}
                {#each vtips as tip (tip.id)}
                    <circle cx={tip.x} cy={tip.y} r="2.4"
                        fill={tip.color} fill-opacity="0.95" />
                {/each}
                <!-- ▦ sub-graph: each pane a scape in miniature, radially — spokes under
                     walls under statements, the slope gradient washing the member rim.
                     Every text is ONE vstat statement (the grammar: badge · key · lilac
                     ':' · value · ×N · /*N, values stretching to their chords).  Clipped
                     to the pane polygon so nothing leaks through a wall.  A member label
                     is the surf (Vtuff_pop) — the seed of click-to-expand; the +N mark
                     is the annotated fold of whatever this beat's glass couldn't say. -->
                {#snippet vstat(sp: VSubPane, s: VStat)}
                    <!-- the KIND ('Artist'/'Track') is just its own colour-coded word (kind_tint) — no
                         box, no pill: "the regular colour-coded key visual … standard" (the human's
                         J-walkback all the way home: a field/button around a mainkey only added noise) -->
                    <!-- svelte-ignore a11y_click_events_have_key_events, a11y_no_static_element_interactions, a11y_interactive_supports_focus -->
                    <text class={s.cls} class:hot={s.member != null} class:corr-hot={!!s.members?.length}
                          class:corr-lit={corr_mark(sp, s) === 1} class:corr-dim={corr_mark(sp, s) === -1}
                          x={s.x.toFixed(1)} y={s.y.toFixed(1)}
                          font-size={s.fs.toFixed(1)} text-anchor="middle"
                          transform={s.rot != null ? `rotate(${s.rot} ${s.x.toFixed(1)} ${s.y.toFixed(1)})` : undefined}
                          role={s.member || s.members?.length ? 'button' : undefined}
                          onpointerdown={s.cls === 'vsub-ntitle' ? (e) => vsub_grab(e, sp.id) : undefined}
                          onmouseenter={s.member || s.members?.length ? () => corr_over(sp, s) : undefined}
                          onmouseleave={s.member || s.members?.length ? () => corr_out(s) : undefined}
                          onclick={s.member ? () => micro_click(sp.id, s.member)
                                 : s.members?.length ? () => corr_pin_toggle(sp, s) : undefined}>
                        {#if s.tag}<tspan class="vsub-tag" fill={s.tagtint ?? undefined}>{s.tag}</tspan>{#if s.tagcolon}<tspan class="vsub-colon">: </tspan>{:else}<tspan>{' '}</tspan>{/if}{/if}{#if s.nk}<tspan class="vsub-nk" fill={s.nkhue}>{s.nk}</tspan><tspan class="vsub-colon">: </tspan>{/if}{#if s.key}<tspan fill={s.hue}>{s.key}</tspan>{#if s.colon}<tspan class="vsub-colon">:{s.val ? ' ' : ''}</tspan>{/if}{/if}{#if s.val}<tspan class="vsub-v" textLength={s.tl} lengthAdjust={s.tl ? 'spacingAndGlyphs' : undefined}>{s.val}</tspan>{/if}{#if s.sup}<tspan class="vsub-sup" dy="-0.45em">{s.sup}</tspan>{/if}{#if s.subn}<tspan class="vsub-sup vsub-dig" dy={s.sup ? '0' : '-0.45em'}>/*{s.subn}</tspan>{/if}{#each s.lines ?? [] as ln, li (li)}<tspan class="vsub-v" x={s.x.toFixed(1)} dy={li === 0 && (s.sup || s.subn) ? '1.65em' : '1.2em'} textLength={ln.tl} lengthAdjust={ln.tl ? 'spacingAndGlyphs' : undefined}>{ln.text}</tspan>{/each}
                    </text>
                {/snippet}
                {#each vsubs as sp (sp.id)}
                    <clipPath id={sp.clipid}><path d={sp.clip} /></clipPath>
                    <g class="cytui-subgraph" clip-path={`url(#${sp.clipid})`}>
                        {#if sp.grad}
                            <!-- the slope of hierarchy, flowing outward: transparent at the
                                 source's core, the members' kind hue at the rim -->
                            <radialGradient id={`vgrad-${sp.clipid}`} gradientUnits="userSpaceOnUse"
                                            cx={sp.grad.cx} cy={sp.grad.cy} r={sp.grad.r}>
                                <stop offset="45%" stop-color={sp.grad.hue} stop-opacity="0" />
                                <stop offset="100%" stop-color={sp.grad.hue} stop-opacity="0.17" />
                            </radialGradient>
                        {/if}
                        {#each sp.lgrads ?? [] as lg (lg.id)}
                            <!-- the coagulate's depth: transparent on the parent side, the
                                 members' tint deepening away from it — and its inner shadow,
                                 the same axis with the opacities flipped (o0/o1 override) -->
                            <linearGradient id={lg.id} gradientUnits="userSpaceOnUse"
                                            x1={lg.x1} y1={lg.y1} x2={lg.x2} y2={lg.y2}>
                                <stop offset="0%" stop-color={lg.hue} stop-opacity={lg.o0 ?? 0} />
                                <stop offset="100%" stop-color={lg.hue} stop-opacity={lg.o1 ?? 0.24} />
                            </linearGradient>
                        {/each}
                        <!-- spokes first, under every wall: nucleus → region in the region's
                             hue — the visible clue that every fact hangs off the source -->
                        {#each sp.spokes as s, si (sp.id + '·s' + si)}
                            <path class="vsub-spoke" d={s.d} stroke={s.hue} />
                        {/each}
                        {#each sp.walls as w, wi (sp.id + '·w' + wi)}
                            <!-- svelte-ignore a11y_no_static_element_interactions, a11y_mouse_events_have_key_events -->
                            <path class={w.cls} d={w.d} stroke={w.hue}
                                  fill={w.fillid ? `url(#${w.fillid})` : w.grad ? `url(#vgrad-${sp.clipid})` : w.hue}
                                  onmouseenter={w.cls === 'vsub-coag' && sp.ribbons?.length ? () => ribbon_pane = sp.id : undefined}
                                  onmouseleave={w.cls === 'vsub-coag' && sp.ribbons?.length ? () => { if (ribbon_pane === sp.id) ribbon_pane = null } : undefined} />
                        {/each}
                        {#if ribbon_pane === sp.id}
                            <!-- I8: this crater's hourglass ribbons, drawn only while it's hovered -->
                            {#each sp.ribbons ?? [] as r, ri (sp.id + '·r' + ri)}
                                <path class="vsub-hour" d={r.d} stroke={r.hue} fill={r.hue} />
                            {/each}
                        {/if}
                        <!-- pane stats + »N are the tuples/star voice; ϕ owns all visible text
                             (its groove lettering rides on top, blind to cell walls), so under ϕ
                             the walls/tints stay as underpainting but the stats DON'T paint.  The
                             stats still built as DATA (the spell reads them → cells grow under ϕ). -->
                        {#if vsub_face !== 'phi'}
                            {#each sp.stats as s, si (sp.id + '·t' + si)}
                                {@render vstat(sp, s)}
                            {/each}
                            {#if sp.com}
                                <!-- »N: this pane's region-shared claims ride the river now -->
                                <text class="vsub-com" x={sp.com.x.toFixed(1)} y={sp.com.y.toFixed(1)}
                                      text-anchor="end">»{sp.com.n}</text>
                            {/if}
                        {/if}
                        <!-- the +N crowd-out mark is no longer PAINTED (the human: "the +1 … I'm not
                             wanting").  sp.hid still rides as DATA — the growth spell reads it to keep
                             swelling a cell until everything seats, so the fold heals by GROWING, not by
                             confessing a count. -->
                    </g>
                {/each}
                <!-- ϕ the golden lettering layer (face 'phi'): every label rides its own CLAIMED
                     groove arc — the ledger is exact, so text never obscures text; what found no
                     groove within budget folds into the +N chip (click = expandy, 3× reach for
                     that cell).  The faint lattice is the flat reference the landscape warps;
                     dashed ties thread a displaced label back home.  UNclipped — the whole point
                     is ignoring cell boundaries; the glass beneath is the underpainting. -->
                {#if vphi}
                    <path class="vsub-philattice" d={vphi.lattice} />
                    {#each vphi.ties as t, ti ('ϕt' + ti)}
                        <path class="vsub-phitie" d={t.d} stroke={t.tint} />
                    {/each}
                    {#each vphi.arcs as a (a.pathid)}
                        <path id={a.pathid} class="vsub-phigroove" d={a.d} stroke={a.tint} />
                        <!-- the TITLE arc (vsub-phit) is the cell's DRAG HANDLE: grab the Artist blobule
                             to move its cytoscape node (mirrors the pane identity's vsub-ntitle drag).
                             Fact/member arcs stay non-interactive.  svelte-ignore matches the pane's. -->
                        <!-- svelte-ignore a11y_click_events_have_key_events, a11y_no_static_element_interactions, a11y_interactive_supports_focus -->
                        <text class={a.cls} font-size={a.fs.toFixed(1)}
                              onpointerdown={a.cls === 'vsub-phit' ? (e) => vsub_grab(e, a.cellid) : undefined}
                              role={a.cls === 'vsub-phit' ? 'button' : undefined}>
                            <textPath href={`#${a.pathid}`} startOffset="4"
                                      textLength={a.tl} lengthAdjust={a.tl ? 'spacingAndGlyphs' : undefined}>
                                {#if a.k}<tspan fill={a.khue ?? undefined}>{a.k}</tspan><tspan class="vsub-phicolon">: </tspan>{/if}<tspan fill={a.tint}>{a.text}</tspan>
                            </textPath>
                        </text>
                    {/each}
                    {#each vphi.folds as f (f.id)}
                        <!-- svelte-ignore a11y_click_events_have_key_events, a11y_no_static_element_interactions -->
                        <g class="vsub-phifold" onclick={() => phi_expand(f.id)}>
                            <circle cx={f.x.toFixed(1)} cy={f.y.toFixed(1)} r="10" stroke={f.tint} />
                            <text x={f.x.toFixed(1)} y={(f.y + 3.5).toFixed(1)} text-anchor="middle">+{f.n}</text>
                        </g>
                    {/each}
                {/if}
            {/if}
        </svg>
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
/* ▧ arc-river debris: the family trait as tiny chips lined along the riverbed,
   each already rotated to the local tangent by an inline transform.  Fill is the
   family colour (inline, per-river); this only sets the small legible face and a
   fill-opacity above the bed so the tuples read as the trail's grain. */
.cytui-river-chip {
    font-size: 9px;
    font-weight: 600;
    letter-spacing: 0.02em;
    fill-opacity: 0.85;
}
/* ▦ sub-graph: walls thinner and softer than the pane strokes so the hierarchy
   reads — pane wall loud, sub-wall quiet.  Labels are the pane's words: keys
   tinted (fill inline, per-pane), values plain, superscripts small and lilac
   like the old dig glyph.  Only member labels and the dip take the pointer
   (pointer-events:none rules the layer) so pane drag survives. */
.cytui-subgraph .vsub-wall {
    fill-opacity: 0.04;
    stroke-opacity: 0.3; stroke-width: 0.7;
    stroke-dasharray: 1 2.5; stroke-linejoin: round;
}
/* the tuple region: the key's vein hue as a faint body + a firmer wall than the
   leaves — hierarchy reads pane > tuple > leaf by stroke weight alone.  The
   members region (.boundary) is the Artist/Track wall: solid, a touch louder. */
.cytui-subgraph .vsub-gwall {
    fill-opacity: 0.07;
    stroke-opacity: 0.45; stroke-width: 1;
    stroke-dasharray: 3 2; stroke-linejoin: round;
}
/* the C coagulate (H1): the member-group's ONE smooth shape — the STRONG level
   boundary.  Its fill is a linear gradient rising AWAY from the parent side
   (transparent at the header seam, the members' tint deepening toward the far
   wall — the human: "a background gradient on the subcell, going transparent
   from the parent side") so containment reads as depth, no drawn shadow. */
.cytui-subgraph .vsub-coag {
    fill-opacity: 1;                /* the gradient stops carry the alpha */
    stroke-opacity: 0.85; stroke-width: 2;   /* the cradle rim — the Artist wall, made to read */
    stroke-linejoin: round;
}
.cytui-subgraph .vsub-coagsh {
    fill-opacity: 1;                /* the inner shadow — black gradient, alpha in the stops */
    stroke: none;
    pointer-events: none;
}
/* the ARTIST BASIN — the OUTER crater's lining (the human: "draw a crater that lines it ...
   one around the Artist as well as Track").  Two stepped inset contours in the container tint
   = a carved lip, the inner one fainter reads as the stepped-in wall; fill:none (a stylesheet
   rule beats the fill="" presentation attribute) so only the lip LINES draw, and the top-edge
   shadow (vsub-abasinsh) carves the depth.  The Track nucleus sits inside → basin-in-basin. */
.cytui-subgraph .vsub-abasin  { fill: none; stroke-opacity: 0.55; stroke-width: 1.6; stroke-linejoin: round; }
.cytui-subgraph .vsub-abasin2 { fill: none; stroke-opacity: 0.26; stroke-width: 1;   stroke-linejoin: round; }
.cytui-subgraph .vsub-abasinsh { fill-opacity: 1; stroke: none; pointer-events: none; }
/* ϕ the golden lettering layer: the faint reference lattice, each label's groove arc,
   the dashed ties home, and the +N expandy chips.  Text fills ride tspan fill attrs
   (kind/vein/tint hues); classes here carry weight + the layer's quietness only. */
.cytui-voronoi .vsub-philattice { fill: none; stroke: #8a8a9a; stroke-opacity: 0.07; stroke-width: 1; pointer-events: none; }
.cytui-voronoi .vsub-phigroove  { fill: none; stroke-opacity: 0.10; stroke-width: 1.2; pointer-events: none; }
.cytui-voronoi .vsub-phitie     { fill: none; stroke-opacity: 0.20; stroke-width: 1; stroke-dasharray: 2 4; pointer-events: none; }
/* the TITLE arc is the cell's DRAG HANDLE — it opts back into the pointer-events:none SVG (the
   whole .cytui-voronoi layer is none, like the pane layer), so a grab lands on it and moves the
   cytoscape node.  cursor:grab is the affordance; fact/member arcs stay non-interactive (they
   inherit the layer's none). */
.cytui-voronoi text.vsub-phit   { font-weight: 600; pointer-events: all; cursor: grab; }
.cytui-voronoi text.vsub-phit:active { cursor: grabbing; }
.cytui-voronoi text.vsub-phif   { opacity: 0.92; }
.cytui-voronoi text.vsub-phim   { opacity: 0.95; }
.cytui-voronoi .vsub-phicolon   { fill: #8878aa; }
.cytui-voronoi .vsub-phifold    { cursor: pointer; }
.cytui-voronoi .vsub-phifold circle { fill: #101016; fill-opacity: 0.75; stroke-opacity: 0.6; stroke-width: 1.2; }
.cytui-voronoi .vsub-phifold text   { fill: #c8c8d4; font-size: 10px; }
/* H5 hourglass ribbons: claim ↔ member correspondence ("which %title goes with
   which %year"), faint bands pinched to a waist — hover carries the full read. */
.cytui-subgraph .vsub-hour {
    fill-opacity: 0.16;             /* a touch louder now they only show on hover (I8) */
    stroke-opacity: 0.28; stroke-width: 0.5;
    stroke-linejoin: round;
    pointer-events: none;          /* never steal the coagulate's hover tracking */
}
/* H4 correspondence: touched chips light; a correspondence-bearing chip NOT
   involved takes the black blur — absence smudged in place ("black blurs over
   eg %remaster or %live if it doesn't have them"). */
.cytui-subgraph text.corr-hot { pointer-events: all; cursor: pointer; }
.cytui-subgraph text.corr-lit { opacity: 1; text-decoration: underline; text-underline-offset: 2px; }
.cytui-subgraph text.corr-dim { opacity: 0.35; filter: blur(1.8px); }
/* member cells ring the rim in their kind's hue; the fill is the slope gradient
   (its alpha lives in the gradient stops, so no fill-opacity here) — hierarchy
   visibly flows centre → out. */
.cytui-subgraph .vsub-mwall {
    fill-opacity: 1;
    stroke-opacity: 0.5; stroke-width: 1.1;
    stroke-linejoin: round;
}
/* the NUCLEUS: the fold source's own cell — wall solid and a touch luminous, the one
   plate the spokes radiate from.  The spoke is a quiet dashed strand in the region's
   hue: the linkage, not a wall. */
.cytui-subgraph .vsub-nwall {
    fill-opacity: 0.09;
    stroke-opacity: 0.7; stroke-width: 1.4;
    stroke-linejoin: round;
}
.cytui-subgraph .vsub-spoke {
    fill: none;
    stroke-width: 1; stroke-opacity: 0.3;
    stroke-dasharray: 2 3; stroke-linecap: round;
}
.cytui-subgraph text { user-select: none; }
.cytui-subgraph .vsub-label { fill: #c9c9c9; }
/* the poppable cue is the hot underline (never a % — % prefixes a KEY in the house
   notation, and these are values) */
.cytui-subgraph .vsub-label.hot {
    pointer-events: all; cursor: pointer;
    text-decoration: underline dotted; text-underline-offset: 2px;
}
.cytui-subgraph .vsub-label.hot:hover { fill: #fff; }
/* the KIND word — the TYPE, said once, at natural size; colour is the inline kind_tint,
   so it reads as "a C begins here" the same way any key reads by its vein hue.  #667788 is
   only the fallback when no tint rides. */
.cytui-subgraph .vsub-tag { fill: #667788; }
.cytui-subgraph .vsub-v { fill: #cfcfcf; }
/* Stuffing's grammar, spoken in SVG: lilac colon (the k→v mark), violet counts —
   same signs, same colours. */
.cytui-subgraph .vsub-colon { fill: rgb(228, 163, 245); }
.cytui-subgraph .vsub-sup { fill: rgb(156, 140, 217); font-size: 68%; }
.cytui-subgraph .vsub-gkey { opacity: 0.95; }
/* the identity is the DRAG HANDLE (opts back into the pointer-events:none layer): grab the
   Artist to move its cell's cytoscape node.  cursor:grab is the affordance. */
.cytui-subgraph text.vsub-ntitle { opacity: 0.95; pointer-events: all; cursor: grab; }
.cytui-subgraph text.vsub-ntitle:active { cursor: grabbing; }
.cytui-subgraph .vsub-ringkey { opacity: 0.85; }
.cytui-subgraph .vsub-title { opacity: 0.92; }
/* (.vsub-dip / .vsub-hid are gone — the /*N surf and the +N crowd-out mark are no longer
   painted; the cell heals by GROWING, and a fold opens by drag, not a one-way badge.) */
/* »N — the promotion's receipt: these claims moved OUT to the region's river */
.cytui-subgraph .vsub-com { fill: #7fb08a; font-size: 9px; opacity: 0.85; }
.cytui-bar button.v-toggle.on {
    color: #7ab0d4;
    border-color: #2a3a4a;
}
/* cs — a two-letter label where its siblings are single glyphs: shrink it to sit on
   the same baseline (the region's coordinate-system face). */
.cytui-bar button.v-toggle.v-cs {
    font-size: 78%; font-style: italic; letter-spacing: -0.02em;
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
/* the hover z-lift (vlift_move): the moused-over cell's chunk surfaces above the
   whole overlapping pile, so you can feel your way into it */
:global(.cyto-overlay.vlift) {
    z-index: 40;
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
:global(.face-overlay) {
    /* a registered face component (glass_kinds): same posture as a stuff-overlay, but its
       INTERACTIVE bits re-arm pointer-events themselves (buttons) — the rest stays pannable */
    pointer-events: none;
    overflow: visible;
    background: transparent;
    width: max-content;
    height: max-content;
    max-width: 340px;
}
:global(.stuff-overlay) {
    pointer-events: none;
    /* visible, not hidden: in mold mode paint_final pins this div to the cell BBOX and
       stuff.scale>1 deliberately overflows it — hidden would rectangle-clip the content
       even with the polygon clip (stuff.clip) off.  In node mode the div is max-content
       sized, so nothing overflows and visible changes nothing. */
    overflow: visible;
    background: transparent;
    width: max-content;
    height: max-content;
    max-width: 520px;
    /* the microcosm crossfade: paint_final dims a micro'd cell's Stuffing to 0
       and restores it when the swap reverses — ~200ms each way */
    transition: opacity 0.2s ease;
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