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
    let _raf = 0
    function morph(to: Partial<Pose>, dur = 0.4): Promise<void> {
        cancelAnimationFrame(_raf)
        const from = { ...pose }
        const goal: Pose = { ...from, ...to }
        const t0 = performance.now()
        const ms = Math.max(1, dur * 1000)
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
        const clone = scroll.cloneNode(true) as HTMLElement
        clone.style.width  = `${rect.width}px`
        clone.style.height = `${rect.height}px`
        clone.style.overflow = 'hidden'
        clone.style.pointerEvents = 'none'   // clicks land on the host, not the clone
        host_el.appendChild(clone)
        clone.scrollTop  = scroll.scrollTop  // replay the visible window
        clone.scrollLeft = scroll.scrollLeft

        pose = { ...REST }
        visible = true
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

    // Fly into a target: a frozen frame zooms toward the spot while the editor (if
    // LangPoint is mounted) climbs to the Q the tap-log suggests for it, then we land
    // — seek + dismiss.  This is the auto-Q-on-fly-in the attention log exists for|
    // with no taps it lands at the resting crunch, which is the honest default.
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
        if (!grab()) { revealAt(from); return }
        await morph({ scale: 1.08, opacity: 0.92 }, 0.18)
        await morph({ scale: 1, opacity: 1 }, 0.22)
        revealAt(from)
    }
    function revealAt(from: number) {
        ;(lang_dock?.c.seek as ((v: EditorView, a: number, b: number) => void) | undefined)
            ?.(view!, from, from)
        clear()
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
    //#region surface

    // Stash the compost controls on the dock so the gallop|gotos|any nav can drive
    // the frame without importing this component — the same .c-closure pattern as
    // seek|setPointFonts.  Rebuilt each time the dock changes so it never goes stale.
    $effect(() => {
        const dock = lang_dock
        if (!dock) return
        dock.c.compost = { grab, morph, clear, reveal, fly, toPNG, suggest_Q,
            // step(prevQ,nextQ): grab a pre-fold frame so a Q climb can fold under a
            // held snapshot|LangPoint calls this just before it dispatches its folds.
            step: (_prevQ: number, _nextQ: number) => { grab() } }
        return () => { if (dock.c.compost) dock.c.compost = undefined }
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
        /* the clone carries its own backdrop|a faint frame edge reads as "frozen" */
        box-shadow: 0 0 0 1px rgba(143, 130, 255, 0.25),
                    0 8px 40px rgba(0, 0, 0, 0.45);
        border-radius: 2px;
        overflow: hidden;
    }
    .compost.gone {
        position: fixed;
        left: -1px; top: -1px; width: 0; height: 0;
        overflow: hidden; pointer-events: none; opacity: 0;
        box-shadow: none;
    }
</style>
