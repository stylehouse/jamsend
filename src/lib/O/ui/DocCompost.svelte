<script lang="ts">
    // DocCompost — a frozen frame of the editor you can twist, shrink and fly,
    //   then click your way back into.  The live CM editor stays untouched
    //   underneath|the frame floats over it as a sibling overlay (like DocMinimap),
    //   so motion that CM's snapping fold layout would fight happens here instead,
    //   on a detached copy.
    //
    //   The frame is a 1:1 DOM clone of the editor viewport by default — perfect
    //   fidelity, no font|taint trouble, and clickable: a click maps through
    //   view.posAtCoords back to a real doc position even while the frame is mid-
    //   twist, because a CSS transform never moves an element's own offsetX/offsetY
    //   space.  toPNG() rasterises the same clone for the "visual art compost" the
    //   live overlay can't be saved as|tweened between as plain images.
    //
    //   CM virtualises — only the viewport (visible lines + a small margin) is ever
    //   in the DOM, so the frame is the viewport.  A whole-doc raster would scroll-
    //   and-shoot in chunks, or draw from the doc text + highlighter (the measureText
    //   canvas in Lang is the seed of that)|park that until a use wants it.
    //
    // ── the tap-log (proto attention layer) ──────────────────────────────────────
    //
    //   Every reveal-click and every fly lands a weighted, timestamped tap on
    //   dock.c.taps — a capped ring of the recent part of where attention actually
    //   went, the lightest kind of Point activity.  suggest_Q reads it so a fly into
    //   a place you've been lately arrives OPEN (low Q) while an untouched place
    //   stays crunched.  This is the seed of the attention-trace Waft** device|when
    //   that graduates, taps move onto a real Waft layer (resolved through %Map by
    //   name, decaying, the heatmap streak the minimap draws) and this ring becomes
    //   its in-memory tail.
    //   < graduate dock.c.taps to a Waft** attention device — a heatmap layer the
    //     minimap reads, fed also by on-screen line visibility (lightest, decays)
    //     and by edits (heaviest, batched into one pleasing sweep).  Reversible
    //     navigation rides the same log, longer than the minimap's nav_hist.

    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { EditorView } from "@codemirror/view"

    let { H, view }: {
        H:    House
        view: EditorView | undefined
    } = $props()

    // Mirror DocMinimap's read of the active dock — Languinio is the one path.
    let languinio: TheC | undefined = $state()
    $effect(() => {
        void H.ave.version
        languinio = H.ave.ob({ Languinio: 1 })[0] as TheC | undefined
    })
    let active_path = $derived(
        (languinio?.ob({ active: 1 })[0]?.sc.dock as string | undefined) ?? '')
    let lang_dock = $derived(active_path
        ? languinio?.ob({ dock: active_path })[0] as TheC | undefined
        : undefined)

    //#region pose

    // A pose is the visual treatment of the frame|identity is the resting frame
    // sitting exactly over the live editor.  morph tweens between poses.
    type Pose = { x: number, y: number, scale: number, rotate: number, opacity: number }
    const REST: Pose = { x: 0, y: 0, scale: 1, rotate: 0, opacity: 1 }
    let pose = $state<Pose>({ ...REST })

    function pose_css(p: Pose): string {
        return `translate(${p.x.toFixed(2)}px, ${p.y.toFixed(2)}px) `
             + `rotate(${p.rotate.toFixed(3)}deg) scale(${p.scale.toFixed(4)})`
    }

    // rAF tween from the live pose to `to` over dur seconds, eased.  A fresh morph
    // supersedes the one in flight (we read the current pose as the start), so a
    // climb that re-flies mid-tween doesn't jumble|it just heads to the new pose.
    //   < this maps onto the Waver kernel (host + apply + duration) — when LangPoint
    //     is mounted, swap the rAF for H.Lang_wave_enqueue so Compost, the Q gallop
    //     and Cytui's graph all drain one queue.  Local rAF until that's wired so
    //     the frame works whether or not the ghost mixins loaded.
    // DEBUG: global slow-mo so the frame's motion is inspectable.  1 = production
    //  speed; bump it to crawl every morph (fly, peel, the gallop's step).  One knob,
    //  set back to 1 once the overlay's confirmed.
    const MORPH_SCALE = 3
    let _raf = 0
    function morph(to: Partial<Pose>, dur = 0.4): Promise<void> {
        cancelAnimationFrame(_raf)
        const from = { ...pose }
        const goal: Pose = { ...from, ...to }
        const t0 = performance.now()
        const ms = Math.max(1, dur * 1000 * MORPH_SCALE)
        return new Promise(resolve => {
            const tick = (now: number) => {
                const u = Math.min(1, (now - t0) / ms)
                const e = u < 0.5 ? 2 * u * u : 1 - Math.pow(-2 * u + 2, 2) / 2  // easeInOutQuad
                pose = {
                    x:       from.x       + (goal.x       - from.x)       * e,
                    y:       from.y       + (goal.y       - from.y)       * e,
                    scale:   from.scale   + (goal.scale   - from.scale)   * e,
                    rotate:  from.rotate  + (goal.rotate  - from.rotate)  * e,
                    opacity: from.opacity + (goal.opacity - from.opacity) * e,
                }
                if (u < 1) _raf = requestAnimationFrame(tick)
                else resolve()
            }
            _raf = requestAnimationFrame(tick)
        })
    }

    //#endregion
    //#region frame

    let visible = $state(false)
    let host_el: HTMLDivElement | undefined = $state()
    // The on-screen box the frame occupies — captured from the live scrollDOM at
    // grab time, so the frame lands exactly over the editor before any morph.
    let box = $state({ left: 0, top: 0, width: 0, height: 0 })
    // The live scrollDOM client rect at grab time, kept so a click on the (possibly
    // twisted) frame can be handed to view.posAtCoords in the live editor's own
    // coordinate space.  offsetX/offsetY on the frame are pre-transform local, which
    // equals this rect's local space since the clone is 1:1 with the scrollDOM.
    let live_origin = { left: 0, top: 0 }

    // Clone the editor viewport into the frame host as live DOM, 1:1.  Cloning the
    // whole scrollDOM (not just contentDOM) and replaying its scrollTop reproduces
    // the exact visible window — gutters, fold stubs, point fonts and all.
    function grab(): boolean {
        if (!view || !host_el) return false
        const scroll = view.scrollDOM
        const rect   = scroll.getBoundingClientRect()
        box = { left: rect.left, top: rect.top, width: rect.width, height: rect.height }
        live_origin = { left: rect.left, top: rect.top }

        host_el.replaceChildren()
        // Clone the EDITOR root (view.dom = .cm-editor), not just the scroller — CM's
        //  theme + base styles are scoped under a generated class on .cm-editor, so a
        //  bare .cm-scroller clone is detached from that scope and renders blank (the
        //  green-bordered-but-empty frame).  Cloning the editor carries the scope, so
        //  the frame paints with the real fonts|colours.  Still a one-shot DOM
        //  cloneNode — no SVG, no re-render — cheap to throw around the viewport.
        const clone = view.dom.cloneNode(true) as HTMLElement
        clone.style.width   = `${rect.width}px`
        clone.style.height  = `${rect.height}px`
        clone.style.margin  = '0'
        clone.style.pointerEvents = 'none'   // clicks land on the host, not the clone
        host_el.appendChild(clone)
        // replay the visible window onto the cloned scroller (it's inside the editor)
        const cloned_scroll = (clone.classList.contains('cm-scroller')
            ? clone : clone.querySelector('.cm-scroller')) as HTMLElement | null
        if (cloned_scroll) {
            cloned_scroll.scrollTop  = scroll.scrollTop
            cloned_scroll.scrollLeft = scroll.scrollLeft
        }

        pose = { ...REST }
        visible = true
        // (the screen-capture upgrade that used to run here was removed — the
        //  getDisplayMedia path lagged the machine and is disabled; see the capture
        //  region's note below.)
        return true
    }

    function clear() {
        cancelAnimationFrame(_raf)
        visible = false
        host_el?.replaceChildren()
    }

    // A click on the frame — turn the frame-local point into the live editor's
    // client coords (transform-proof, see header) and ask CM what's there, then
    // reveal it: a tap (long when the press was held, the articulated grain), seek
    // through the dock's own seek closure (fold-aware), and dismiss the frame so
    // you're back in the real code at that spot.  The tap goes two ways: the local
    // ring for suggest_Q, and Lang_tap, which globulates it onto $region/$method in
    // the taker Ting.
    let _down_at = 0
    function reveal(ev: MouseEvent) {
        if (!view) { clear(); return }
        const x = live_origin.left + ev.offsetX
        const y = live_origin.top  + ev.offsetY
        const pos = view.posAtCoords({ x, y })
        if (pos == null) { clear(); return }
        const from = view.state.doc.lineAt(pos).from
        const long = _down_at ? (Date.now() - _down_at) > 400 : false
        record_tap(long ? 'hold' : 'reveal', from, long ? 4 : 3)
        ;(H as any).i_elvisto?.('Lang/Lang', 'Lang_tap', { from, long, weight: long ? 4 : 3 })
        ;(lang_dock?.c.seek as ((v: EditorView, a: number, b: number) => void) | undefined)
            ?.(view, from, from)
        clear()
    }

    //#endregion
    //#region taps

    type Tap = { line: number, from: number, t: number, weight: number, kind: string }
    const TAP_CAP = 400   // the recent part — older taps fall off the tail

    function record_tap(kind: string, from: number, weight: number) {
        if (!view || !lang_dock) return
        const line = view.state.doc.lineAt(from).number
        const taps = ((lang_dock.c.taps as Tap[]) ?? []).concat(
            { line, from, t: Date.now(), weight, kind })
        if (taps.length > TAP_CAP) taps.splice(0, taps.length - TAP_CAP)
        lang_dock.c.taps = taps
    }

    // Recent taps near a target line want that area OPEN — newer + nearer taps add
    // heat, heat lowers Q.  Untouched|stale targets keep the resting crunch.  Pure|
    // unit-checked in node alongside the click hit-test.
    function suggest_Q(target_line: number,
        { base = 5, span = 40, halflife_ms = 60000 } = {}): number {
        const taps = (lang_dock?.c.taps as Tap[]) ?? []
        const now  = Date.now()
        let heat = 0
        for (const tap of taps) {
            const decay = Math.pow(0.5, Math.max(0, now - tap.t) / halflife_ms)
            const near  = Math.max(0, 1 - Math.abs(tap.line - target_line) / span)
            heat += decay * near * (tap.weight ?? 1)
        }
        const Q = Math.round(base - Math.min(base - 1, heat))
        return Math.max(1, Math.min(base, Q))
    }

    //#endregion
    //#region fly

    // Fly into a target: records the tap, climbs the editor to the Q the tap-log
    // suggests, then lands (seek).  The frozen-frame zoom is SUPPRESSED while capture
    // is disabled — the clone paints blank, so grab()+morph only flashed an empty green
    // box on every goto.  So a goto is now instant: tap-log + auto-Q + seek, no frame.
    //   < restore the grab()+morph zoom here once the frame can show real content.
    async function fly(from: number, { auto_q = true } = {}) {
        if (!view) return
        record_tap('fly', from, 2)
        ;(H as any).i_elvisto?.('Lang/Lang', 'Lang_tap', { from, long: false, weight: 2 })
        if (auto_q) {
            const line = view.state.doc.lineAt(from).number
            const Q = suggest_Q(line)
            // e:Lang_climb is LangPoint's|guarded so a fly still works before it mounts.
            ;(H as any).i_elvisto?.('Lang/Lang', 'Lang_climb', { Q })
        }
        revealAt(from)   // straight to the seek — no blank frozen frame in between
    }
    function revealAt(from: number) {
        ;(lang_dock?.c.seek as ((v: EditorView, a: number, b: number) => void) | undefined)
            ?.(view!, from, from)
        clear()
    }

    // Peel the frozen sheet open or closed from a corner hinge — a page-turn feel
    //  that swings the snapshot away to reveal the live editor beneath, then lets it
    //  settle back.  A true paper curl wants 3D|clip-path; this is the affine tease of
    //  it (corner-anchored rotate + lift + fade), cheap and on the same morph tween.
    //   < deepen to a real curl with perspective()+rotateY on a wrapper, or a clip-path
    //     wedge that grows from the corner, once the affine version reads right.
    async function peel(open = true, corner = 'top left') {
        if (!visible) { if (open) grab(); else return }
        if (host_el) host_el.style.transformOrigin = corner
        if (open) await morph({ rotate: -20, x: 16, y: -8, scale: 0.97, opacity: 0.3 }, 0.5)
        else      { await morph({ ...REST }, 0.4); if (host_el) host_el.style.transformOrigin = 'center center' }
    }

    //#endregion
    //#region png

    // Rasterise the current clone to a PNG data URL — the compost.  foreignObject
    // wraps a style-inlined copy of the viewport so it draws without external CSS|
    // fonts may not embed and cross-origin assets can taint, so this is best-effort
    // and returns null on failure (the live clone overlay is the reliable visual|
    // this is for saved|tweenable frames).
    //   < for fidelity drop in html2canvas when present, or draw from doc text +
    //     highlightingFor — both heavier, neither needed for the interactive frame.
    async function toPNG(): Promise<string | null> {
        if (!view) return null
        try {
            const scroll = view.scrollDOM
            const rect   = scroll.getBoundingClientRect()
            const w = Math.ceil(rect.width), h = Math.ceil(rect.height)
            const clone = scroll.cloneNode(true) as HTMLElement
            inline_styles(scroll, clone)
            clone.scrollTop = scroll.scrollTop
            const xml = new XMLSerializer().serializeToString(clone)
            const svg =
                `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}">`
              + `<foreignObject width="100%" height="100%">`
              + `<div xmlns="http://www.w3.org/1999/xhtml" style="width:${w}px;height:${h}px;overflow:hidden">`
              + xml + `</div></foreignObject></svg>`
            const url = await draw_svg_to_png(svg, w, h)
            return url
        } catch (e) {
            console.warn('🪻 compost toPNG failed', e)
            return null
        }
    }

    // Copy computed styles onto the clone subtree so foreignObject renders them.
    function inline_styles(src: Element, dst: Element) {
        const cs = getComputedStyle(src)
        let css = ''
        for (let i = 0; i < cs.length; i++) {
            const p = cs[i]
            css += `${p}:${cs.getPropertyValue(p)};`
        }
        ;(dst as HTMLElement).setAttribute('style', css)
        const sks = src.children, dks = dst.children
        for (let i = 0; i < sks.length && i < dks.length; i++)
            inline_styles(sks[i], dks[i])
    }

    function draw_svg_to_png(svg: string, w: number, h: number): Promise<string> {
        return new Promise((resolve, reject) => {
            const img = new Image()
            const blob = new Blob([svg], { type: 'image/svg+xml;charset=utf-8' })
            const src  = URL.createObjectURL(blob)
            img.onload = () => {
                const canvas = document.createElement('canvas')
                canvas.width = w; canvas.height = h
                const ctx = canvas.getContext('2d')!
                ctx.drawImage(img, 0, 0)
                URL.revokeObjectURL(src)
                resolve(canvas.toDataURL('image/png'))
            }
            img.onerror = (e) => { URL.revokeObjectURL(src); reject(e) }
            img.src = src
        })
    }

    //#endregion
    //#region capture — DISABLED (it all sucked)
    //
    //   Three ways to picture the editor, three dead ends — parked below, not deleted:
    //     • cloneNode of the editor renders BLANK — its whole look is .lte-cm-scoped
    //       component CSS, so a clone detached from that subtree inherits none of it.
    //     • toPNG via SVG <foreignObject> WON'T RASTERISE under software rendering, and
    //       even where it does it DROPS scoped CSS and web-fonts — a foreignObject is a
    //       fresh styling context, so only inlined computed styles survive and fonts
    //       usually don't embed, leaving the result unstyled|blank.
    //     • getDisplayMedia DID capture real pixels, but a live capture stream lags the
    //       machine hard (the browser composites + encodes the whole tab continuously)
    //       and it's an awkward per-session screen-share prompt.  Not worth it.
    //   Capture is off.  The surface methods + Shift+Alt+S/D keys are kept as no-ops so
    //   the UI stays put.  For a real screenshot one day, use an offscreen rasteriser
    //   (html2canvas) or a headed-browser shot — none of the parked approaches.

    // no-ops so dock.c.compost.{shoot,shoot_into_frame,snap,stop_capture} and the keys
    //  still resolve; nothing runs, nothing lags.
    async function shoot(_t?: HTMLElement | string): Promise<string | null> {
        console.warn('🪻 compost capture disabled (it sucked)'); return null }
    async function shoot_into_frame(_t?: HTMLElement | string): Promise<boolean> {
        console.warn('🪻 compost capture disabled (it sucked)'); return false }
    async function snap(_name = 'compost', _t?: HTMLElement | string): Promise<boolean> {
        console.warn('🪻 compost capture disabled (it sucked)'); return false }
    function stop_capture() { /* nothing live to stop while disabled */ }

    // Shift+Alt+S/D kept wired to the no-ops so the UI's there; they just warn now.
    $effect(() => {
        const onkey = (e: KeyboardEvent) => {
            if (!(e.shiftKey && e.altKey)) return
            const k = e.key.toLowerCase()
            if (k === 's') { e.preventDefault(); void shoot_into_frame() }
            if (k === 'd') { e.preventDefault(); void snap() }
        }
        window.addEventListener('keydown', onkey)
        return () => window.removeEventListener('keydown', onkey)
    })

    /* ── parked: the original capture implementation (it sucked, see note above) ─────
    let _cap_stream: MediaStream | null = null
    let _cap_video:  HTMLVideoElement | null = null
    let _cap_idle:   ReturnType<typeof setTimeout> | null = null

    // A live getDisplayMedia stream makes the browser composite + encode the whole tab
    //  every frame, continuously — THAT is the lag (a screen recorder left running).
    //  So we keep it only in short bursts: each shot re-arms an idle timer that tears
    //  the stream down a few seconds after the last capture.  Bursts stay instant; idle
    //  costs nothing.  frameRate is floored too — we only ever read single frames.
    function stop_capture() {
        if (_cap_idle) { clearTimeout(_cap_idle); _cap_idle = null }
        _cap_stream?.getTracks().forEach(t => t.stop())
        _cap_stream = null; _cap_video = null
    }
    function _cap_keepalive() {
        if (_cap_idle) clearTimeout(_cap_idle)
        _cap_idle = setTimeout(stop_capture, 4000)
    }

    async function ensure_capture(): Promise<HTMLVideoElement | null> {
        if (_cap_idle) { clearTimeout(_cap_idle); _cap_idle = null }
        if (_cap_video && _cap_stream?.active) return _cap_video
        try {
            _cap_stream = await (navigator.mediaDevices as any).getDisplayMedia(
                { video: { frameRate: 5 }, audio: false, preferCurrentTab: true } as any)
            const v = document.createElement('video')
            v.srcObject = _cap_stream; v.muted = true
            await v.play()
            await new Promise(r => requestAnimationFrame(() => r(null)))  // let dims populate
            _cap_stream.getVideoTracks()[0].addEventListener('ended',
                () => { _cap_stream = null; _cap_video = null })
            _cap_video = v
            return v
        } catch (e) { console.warn('🪻 compost capture denied|failed', e); return null }
    }

    // Resolve a target: an element, a CSS selector, or default to the live editor.
    function _target_el(t?: HTMLElement | string): HTMLElement | null {
        if (typeof t === 'string') return document.querySelector(t)
        return t ?? view?.dom ?? null
    }

    // Capture el to a PNG data URL by cropping the live tab-capture video to its rect.
    async function shoot(t?: HTMLElement | string): Promise<string | null> {
        const el = _target_el(t)
        if (!el) return null
        const v = await ensure_capture()
        if (!v || !v.videoWidth) return null
        const rect = el.getBoundingClientRect()
        const sx = v.videoWidth  / window.innerWidth      // CSS px → captured px
        const sy = v.videoHeight / window.innerHeight
        const canvas = document.createElement('canvas')
        canvas.width  = Math.max(1, Math.round(rect.width  * sx))
        canvas.height = Math.max(1, Math.round(rect.height * sy))
        const ctx = canvas.getContext('2d')
        if (!ctx) return null
        ctx.drawImage(v, rect.left * sx, rect.top * sy, rect.width * sx, rect.height * sy,
                      0, 0, canvas.width, canvas.height)
        _cap_keepalive()   // stream tears down a few seconds after the last shot
        try { return canvas.toDataURL('image/png') } catch (e) { console.warn('🪻 shoot toDataURL', e); return null }
    }

    // Fill the frozen frame with a real screenshot instead of the blank clone — the
    //  awkward-but-true path you can actually see.  Lands over the editor like grab().
    async function shoot_into_frame(t?: HTMLElement | string): Promise<boolean> {
        const el = _target_el(t)
        if (!el || !host_el) return false
        const url = await shoot(el)
        if (!url) return false
        const rect = el.getBoundingClientRect()
        box = { left: rect.left, top: rect.top, width: rect.width, height: rect.height }
        live_origin = { left: rect.left, top: rect.top }
        host_el.replaceChildren()
        const img = document.createElement('img')
        img.src = url
        img.style.width = `${rect.width}px`; img.style.height = `${rect.height}px`
        img.style.display = 'block'; img.style.pointerEvents = 'none'
        host_el.appendChild(img)
        pose = { ...REST }
        visible = true
        return true
    }

    // Shoot + download as a PNG file — for archiving before|after UI states so a change
    //  can be eyeballed (or diffed) across edits.  name gets a .png if it lacks one.
    async function snap(name = 'compost', t?: HTMLElement | string): Promise<boolean> {
        const url = await shoot(t)
        if (!url) return false
        const a = document.createElement('a')
        a.href = url; a.download = /\.png$/i.test(name) ? name : `${name}.png`
        a.click()
        return true
    }

    ──────────────────────────────────────────────────────────────────────────── */

    //#endregion
    //#region surface

    // Stash the compost controls on the dock so the gallop|gotos|any nav can drive
    // the frame without importing this component — the same .c-closure pattern as
    // seek|setPointFonts.  Rebuilt each time the dock changes so it never goes stale.
    $effect(() => {
        const dock = lang_dock
        if (!dock) return
        dock.c.compost = { grab, morph, clear, reveal, fly, peel, toPNG, suggest_Q,
            // real-pixel capture (getDisplayMedia): shoot(target?)→dataURL,
            //  shoot_into_frame(target?) to see it in the frame, snap(name,target?) to
            //  download a PNG.  target = element | CSS selector | default editor.  Call
            //  shoot() once from a click to grant the share, then it's silent.  Capture
            //  the minimap with shoot('.lmm-strip') etc.; snap() before|after a UI change
            //  to eyeball the diff.
            shoot, shoot_into_frame, snap, stop_capture,
            // step(prevQ,nextQ): grab a pre-fold frame so a Q climb can fold under a
            // held snapshot|LangPoint calls this just before it dispatches its folds.
            step: (_prevQ: number, _nextQ: number) => { grab() } }
        return () => { stop_capture(); if (dock.c.compost) dock.c.compost = undefined }
    })

    //#endregion
</script>

{#if visible}
    <div class="compost" bind:this={host_el}
        role="button" tabindex="-1"
        style="
            left:{box.left}px; top:{box.top}px;
            width:{box.width}px; height:{box.height}px;
            transform:{pose_css(pose)}; opacity:{pose.opacity};"
        onclick={reveal}
        onpointerdown={() => { _down_at = Date.now() }}
        onkeydown={(e) => { if (e.key === 'Escape') clear() }}>
    </div>
{:else}
    <!-- host kept mounted but empty so grab() always has somewhere to clone into -->
    <div class="compost gone" bind:this={host_el}></div>
{/if}

<style>
    .compost {
        position: fixed;
        z-index: 40;                 /* over the editor, under modal UI */
        transform-origin: center center;
        cursor: zoom-in;
        will-change: transform, opacity;
        /* DEBUG: bright-green outline so the frozen frame is unmistakable while we
           verify the overlay fires (independent of toPNG, which software rendering
           can defeat).  outline (not border) so it adds no layout box.  Dial back to
           the faint lavender edge once the mechanism is confirmed.
             box-shadow: 0 0 0 1px rgba(143,130,255,0.25), 0 8px 40px rgba(0,0,0,0.45); */
        outline: 2px solid #00ff66;
        outline-offset: -2px;
        box-shadow: 0 0 24px rgba(0, 255, 102, 0.55), 0 8px 40px rgba(0, 0, 0, 0.45);
        border-radius: 2px;
        overflow: hidden;
        /* DEBUG: hue-shift + slight blur so the frozen sheet reads as a distinct
           ghosted layer floating over the live editor, not mistaken for the real one.
           Dial out (with the green outline) once the overlay's confirmed. */
        filter: blur(0.5px) hue-rotate(35deg) saturate(1.3);
    }
    .compost.gone {
        position: fixed;
        left: -1px; top: -1px; width: 0; height: 0;
        overflow: hidden; pointer-events: none; opacity: 0;
        box-shadow: none;
    }
</style>
