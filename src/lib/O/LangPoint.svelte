<script lang="ts">
    // LangPoint.svelte — Point folding intensity (the "Q-factor") for Lang.
    //  Deposits onto H via M.eatfunc(): Lang_indent_blocks (doc → foldable indent blocks),
    //  Lang_fold_targets (outermost blocks at depth ≥ fold_depth, as char ranges),
    //  Lang_apply_Q (reconcile editor to Q 1–5: fold set + shrink body + grow headers,
    //  idempotent so it serves the climb up and down), Lang_point_climb / e:Lang_climb
    //  (gallop Q → toQ one level per wave, a visible cascade), and the Waver (Lang_wave_*,
    //  a generic timed wave queue).  Per-function detail below.
    //
    // ── Font scale ──
    //  The body scales by REAL font-size on %contentDOM + requestMeasure so CM reflows and
    //  scroll-sync stays honest — NOT a transform, which lies about geometry.  base_font_px
    //  is cached on dock.c so every climb scales from the same origin.  The surviving names
    //  move the opposite way (method names + //#region titles GROW) via an absolute-px mark
    //  decoration (dock.c.setPointFonts / pointFontField in Langui) — absolute so it
    //  overrides the inherited body shrink, turning a deep crunch into a contents view.
    //  Only the identifier swells; indent|keywords|args stay body-size.
    //   < a font Compartment in Langui would isolate the body scale (swap Lang_set_font_scale
    //     to dispatch fontCompartment.reconfigure) instead of touching contentDOM.style.
    //
    // ── Fold animation ──
    //  < CM folds snap (placeholder, no height tween); motion comes from the gallop.  A true
    //    tween needs a transitional fold decoration animating max-height before the real
    //    foldEffect lands.

    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { EditorState } from "@codemirror/state"
    import { EditorView } from "@codemirror/view"
    import { foldEffect, unfoldEffect } from "@codemirror/language"
    import { onMount } from "svelte"

    // A foldable indent block: header line, last body line, header indent width,
    // structural depth (0 = top level), and whether it's a //#region marker (never folds).
    type Block = { header: number, end: number, indent: number, depth: number, is_region: boolean }

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region < TODO: the canonical Pointer (region / method / if-keyword)
//   A Pointer addresses a code place by NAME along a path ("Cyto / cyto_scan / for node");
//    we build them (Ting bars, NaviCado, bookmarks) and resolve back to offsets via
//    LangRegions' Lang_resolve_point / Lang_resolve_stack_path.  Two jobs belong HERE:
//     1. a Pointer BUILDER: offset → shortest unambiguous Pointer (e_Lang_tap has the pieces).
//     2. fix region-scoped resolution: %Map holds only a region's HEADER-LINE span, so
//        "region / method" narrows to the header and the method lookup fails — needs region
//        BODY extents (Lang_build_regions from_char/to_char).
//   < and whether LiesCurse's branch/dive should ride this Pointer model vs its own cursor walk.

//#region parts

    // Leading-whitespace width of a line, tabs counted as 4|−1 for a blank line
    // (blanks belong to whatever block encloses them, they neither open nor close).
    Lang_line_indent(text: string): number {
        if (text.trim() === '') return -1
        const m = text.match(/^[ \t]*/)
        return (m ? m[0] : '').replace(/\t/g, '    ').length
    },

    // Decompose the doc into foldable indent blocks: a line heads a block when the next
    // non-blank line is more indented, and the block runs to the last line still deeper
    // than that header.  (Depth — structural nesting, not raw indent/4 — is set below.)
    Lang_indent_blocks(state: EditorState): Block[] {
        const doc = state.doc
        const n   = doc.lines
        const ind: number[] = new Array(n + 1)
        for (let i = 1; i <= n; i++) ind[i] = this.Lang_line_indent(doc.line(i).text)

        const blocks: Block[] = []
        for (let i = 1; i <= n; i++) {
            if (ind[i] < 0) continue
            let j = i + 1
            while (j <= n && ind[j] < 0) j++
            if (j <= n && ind[j] > ind[i]) {
                let end = j, k = j
                while (k <= n) {
                    if (ind[k] < 0) { k++; continue }
                    if (ind[k] > ind[i]) { end = k; k++ } else break
                }
                const is_region = /^\s*\/\/#region\b/.test(doc.line(i).text)
                blocks.push({ header: i, end, indent: ind[i], depth: 0, is_region })
            }
        }
        // depth = blocks that strictly contain this header span, EXCEPT a //#region marker
        //  doesn't count as a container (organizational, not nesting); else a method inside
        //  a region would read one level deeper and the Q scale would jump a step.
        for (const b of blocks) {
            b.depth = blocks.filter(o => o !== b && !o.is_region
                && o.header < b.header && o.end >= b.end && o.indent < b.indent).length
        }
        return blocks
    },

    // The OUTERMOST blocks crossing fold_depth that are worth folding (folding a parent
    //  already hides its children, so depth granularity is mostly Q's job).  Size floor is
    //  depth-aware: a top-level method (depth 0) folds even at MIN_METHOD lines so the Q5
    //  list is complete; a block INSIDE a method (depth ≥ 1) must reach MIN_INNER or it just
    //  litters the dive.  A //#region marker is never a target — folding it swallows the
    //  names the climb surfaces — counted for depth, skipped here.  Shared by fold-range +
    //  header-font builders.
    Lang_folded_blocks(blocks: Block[], fold_depth: number): Block[] {
        if (!isFinite(fold_depth)) return []
        const MIN_METHOD = 2   // depth 0: header + one body line — fold even a tiny method
        const MIN_INNER  = 8   // depth ≥ 1: header through last body line, inclusive
        const long_enough = (b: Block) =>
            (b.end - b.header + 1) >= (b.depth === 0 ? MIN_METHOD : MIN_INNER)
        const crossing = blocks.filter(b =>
            !b.is_region && b.depth >= fold_depth && long_enough(b))
        return crossing.filter(b =>
            !crossing.some(a => a !== b && a.header < b.header && a.end >= b.end))
    },

    // Char ranges to fold for a given fold_depth.  Fold range is body-only:
    // [end of the header line, end of the block] so the header stays readable.
    Lang_fold_targets(state: EditorState, blocks: Block[], fold_depth: number)
        : Array<{ from: number, to: number }> {
        const doc = state.doc
        const ranges: Array<{ from: number, to: number }> = []
        for (const b of this.Lang_folded_blocks(blocks, fold_depth)) {
            const from = doc.line(b.header).to
            const to   = doc.line(Math.min(b.end, doc.lines)).to
            if (from < to) ranges.push({ from, to })
        }
        return ranges
    },

    // Q → fold depth.  Q=1 folds nothing|Q=2..5 fold progressively shallower
    // levels until Q=5 (depth 0) folds every method body.
    Lang_Q_fold_depth(Q: number): number {
        return Q <= 1 ? Infinity : (5 - Q)
    },
    // Q → font scale, 1.0 at Q=1 down to ~0.64 at Q=5 so the folded overview fits.
    Lang_Q_scale(Q: number): number {
        return +(1 - (Math.max(1, Math.min(5, Q)) - 1) * 0.09).toFixed(3)
    },
    // Q → font scale for the SURVIVING headers, inverse of Lang_Q_scale: as detail folds,
    //  the remaining names grow so the overview reads as a table of contents.  1.0 at Q=1 up
    //  to ~1.34 at Q=5 — absolute, not relative to the body shrink (Q5 header 1.34·base, body 0.64·base).
    Lang_Q_header_scale(Q: number): number {
        return +(1 + (Math.max(1, Math.min(5, Q)) - 1) * 0.085).toFixed(3)
    },

//#endregion
//#region apply

    // The dock's unscaled font px, read once from the live computed style and cached:
    //  re-reading after a climb would read the already-shrunk size and the base would creep.
    Lang_base_font_px(dock: TheC): number {
        let base = dock.c.base_font_px as number | undefined
        if (base == null) {
            const view = dock.c.view as EditorView | undefined
            const content = view?.contentDOM as HTMLElement | undefined
            const px = content ? parseFloat(getComputedStyle(content).fontSize) : NaN
            base = isFinite(px) && px > 0 ? px : 13
            dock.c.base_font_px = base
        }
        return base
    },

    // Set the editor body font to base·scale and let CM remeasure so it reflows.
    Lang_set_font_scale(dock: TheC, scale: number) {
        const view = dock.c.view as EditorView | undefined
        if (!view) return
        const content = view.contentDOM as HTMLElement
        const base = this.Lang_base_font_px(dock)
        content.style.fontSize = `${(base * scale).toFixed(2)}px`
        view.requestMeasure()
    },

    // The name token on a header line — the slice the font field swells (only the identifier
    //  grows; indent, keywords, args stay body-size).  Two shapes: a //#region title, or the
    //  name after any keywords.  Control-flow heads (if|for|…) → null, so they stay body-size
    //  even when folded.  Offsets absolute (lineFrom + match index) for the mark range.
    Lang_header_name_span(text: string, lineFrom: number): { from: number, to: number } | null {
        const region = text.match(/^(\s*\/\/#region\s+)(\S.*?)\s*$/)
        if (region) {
            const from = lineFrom + region[1].length
            return { from, to: from + region[2].length }
        }
        const m = text.match(
            /^(\s*(?:(?:export|default|async|static|public|private|protected|readonly|get|set|function|const|let|var)\s+)*)([A-Za-z_$][\w$]*)/)
        if (!m) return null
        const name = m[2]
        const control = new Set([
            'if', 'for', 'while', 'switch', 'case', 'catch', 'do',
            'else', 'try', 'return', 'with', 'throw',
        ])
        if (control.has(name)) return null
        const from = lineFrom + m[1].length
        return { from, to: from + name.length }
    },

    // The names whose font grows against the body shrink: every folded-block (method) head
    //  and every //#region title, each an absolute px.  Region titles get the extra bump and
    //  are pushed FIRST, so dedup keeps their larger size when a region line also heads a block.
    Lang_point_fonts(state: EditorState, blocks: Block[], Q: number, base: number)
        : Array<{ from: number, to: number, px: number }> {
        if (Q <= 1) return []
        const doc   = state.doc
        const hs    = this.Lang_Q_header_scale(Q)
        const rs    = +(hs * 1.18).toFixed(3)
        const fonts: Array<{ from: number, to: number, px: number }> = []
        const seen  = new Set<number>()
        const push  = (lineNo: number, scale: number) => {
            const ln   = doc.line(lineNo)
            const span = this.Lang_header_name_span(ln.text, ln.from)
            if (!span || seen.has(span.from)) return
            seen.add(span.from)
            fonts.push({ from: span.from, to: span.to, px: base * scale })
        }
        for (let i = 1; i <= doc.lines; i++)
            if (/^\s*\/\/#region\b/.test(doc.line(i).text)) push(i, rs)
        for (const b of this.Lang_folded_blocks(blocks, this.Lang_Q_fold_depth(Q)))
            push(b.header, hs)
        return fonts
    },

    // The doc position the crunch pivots around: the cursor if on screen, else the line at
    //  the viewport's vertical middle — so a plain climb recedes toward what you're reading.
    Lang_focal_pos(view: EditorView): number | null {
        const head = view.state.selection.main.head
        const vp   = view.viewport
        if (head >= vp.from && head <= vp.to) return head
        const r   = view.scrollDOM.getBoundingClientRect()
        const pos = view.posAtCoords({ x: r.left + 8, y: r.top + r.height / 2 })
        return pos ?? vp.from
    },

    // Run a fold|layout mutation while keeping the focal point pinned: note its y, let
    //  `mutate` reflow, then (after CM remeasures) re-scroll so it lands at the same y.
    //  Stops a fold ELSEWHERE — a Q climb, a background Point-fold settle — from bumping you
    //  off what you're reading.  A deliberate goto's seek stays OUTSIDE this.
    //   < a CSS transition would smooth steps but CM's discrete remeasure fights mid-tween.
    Lang_keep_focal(view: EditorView, mutate: () => void) {
        const focal    = this.Lang_focal_pos(view)
        const anchor_y = focal != null ? (view.coordsAtPos(focal)?.top ?? null) : null
        mutate()
        if (focal != null && anchor_y != null) {
            view.requestMeasure({
                read:  () => view.coordsAtPos(focal)?.top ?? null,
                write: (now_top: number | null) => {
                    if (now_top != null) view.scrollDOM.scrollTop += (now_top - anchor_y)
                },
            })
        }
    },

    // Reconcile the editor to Q: unfold whatever WE folded last, fold the new target set,
    //  shrink the body font, grow the surviving headers — one transaction under
    //  Lang_keep_focal so the crunch recedes AROUND what you're reading.  Tracking our own
    //  folds on dock.c.q_folds keeps the climb from fighting the user's manual region folds
    //  (we only ever unfold ranges we put down).
    Lang_apply_Q(dock: TheC, Q: number) {
        const view  = dock.c.view  as EditorView | undefined
        // Fold is a DISPLAY op (dispatched onto `view`) so it computes against the LIVE view.state,
        //  not the debounce-stale dock.c.state (Lang_handover.md §7 role 3a) — ranges then match the screen.
        const state = view?.state as EditorState | undefined
        if (!view || !state) return

        const blocks  = this.Lang_indent_blocks(state)
        const targets = this.Lang_fold_targets(state, blocks, this.Lang_Q_fold_depth(Q))
        const base    = this.Lang_base_font_px(dock)
        const fonts   = this.Lang_point_fonts(state, blocks, Q, base)

        const prev = (dock.c.q_folds as Array<{ from: number, to: number }>) ?? []
        const effects = [
            ...prev.map(r => unfoldEffect.of(r)),
            ...targets.map(r => foldEffect.of(r)),
        ]
        // header fonts ride the same transaction as the folds → grow in lock-step, no flicker.
        const setFonts = dock.c.setPointFonts as { of: (v: any) => any } | undefined
        if (setFonts) effects.push(setFonts.of(fonts))

        this.Lang_keep_focal(view, () => {
            if (effects.length) view.dispatch({ effects })
            this.Lang_set_font_scale(dock, this.Lang_Q_scale(Q))
        })

        dock.c.q_folds = targets
        dock.c.Q       = Q
    },

//#endregion
//#region waver

    // ── Waver — a generic forward-stepping wave queue ──
    //   host = any off-snap object for queue state; apply = apply.call(this, wave, dur);
    //    waves = wave objects, each optionally carrying a duration (seconds).  Drains one
    //    per duration so a series animates forward; rush() flushes the rest instantly (a
    //    fresh enqueue or teardown wants the end state now).  No fold|Q knowledge here —
    //    Cytui's upsert|migrate|remove waves can ride the same three calls.
    Lang_wave_enqueue(host: any, apply: (wave: any, dur: number) => void, waves: any[]) {
        host._waves = ((host._waves as any[]) ?? []).concat(waves)
        if (!host._waving) this.Lang_wave_step(host, apply)
    },
    Lang_wave_step(host: any, apply: (wave: any, dur: number) => void) {
        const q = (host._waves as any[]) ?? []
        if (!q.length) { host._waving = false; return }
        host._waving = true
        const wave = q.shift()
        const dur  = (wave.duration as number) ?? 0.18
        apply.call(this, wave, dur)
        host._wave_timer = setTimeout(() => this.Lang_wave_step(host, apply), dur * 1000)
    },
    Lang_wave_rush(host: any, apply: (wave: any, dur: number) => void) {
        clearTimeout(host._wave_timer)
        const q = (host._waves as any[]) ?? []
        host._waves = []
        for (const wave of q) apply.call(this, wave, 0)
        host._waving = false
    },

//#endregion
//#region climb

    // Gallop the active dock from its current Q to toQ, one level per wave (cascade).
    //  Re-enqueueing mid-climb rushes the pending steps to their end first, then climbs
    //  from there — no half-applied jumble.
    Lang_point_climb(w: TheC, toQ: number) {
        const dock = this.Lang_active_dock(w)
        if (!dock) return
        const target = Math.max(1, Math.min(5, Math.round(toQ)))
        const apply  = (wave: any) => this.Lang_apply_Q(dock, wave.q as number)

        // settle any in-flight climb to its end, then read where we actually are
        this.Lang_wave_rush(dock, apply)
        const from = (dock.c.Q as number) ?? 1
        if (from === target) { this.Lang_apply_Q(dock, target); return }

        const dir   = target > from ? 1 : -1
        const waves: any[] = []
        for (let q = from + dir; ; q += dir) {
            waves.push({ q, duration: 0.16 })
            if (q === target) break
        }
        this.Lang_wave_enqueue(dock, apply, waves)
    },

    // e:Lang_climb — the minimap's Q dial (or a goto wanting the current crunch) fires this.
    //   e.sc: { Q }
    async e_Lang_climb(A: TheC, w: TheC, e: TheC) {
        const Q = e.sc.Q as number | undefined
        if (Q == null) return
        this.Lang_point_climb(w, Q)
        this.i_elvisto(w, 'think', {})
    },

//#endregion

    })
    })
</script>
