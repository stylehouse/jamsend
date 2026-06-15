<script lang="ts">
    // LangPoint.svelte — Point folding intensity (the "Q-factor") for Lang.
    //
    // Deposits onto H via M.eatfunc():
    //
    //   Lang_indent_blocks(state)
    //     Decompose the live doc into foldable indent blocks — a header line
    //     plus the more-indented run beneath it — each with a structural depth.
    //     This is the "few basic parts" a subroutine breaks into, indent-based|
    //     it needs no grammar, so it works on any indented text.
    //
    //   Lang_fold_targets(state, blocks, fold_depth)
    //     The outermost blocks at depth ≥ fold_depth, as char ranges to fold.
    //     Outermost-only so folding a parent never strands a child fold when we
    //     climb back down.
    //
    //   Lang_apply_Q(dock, Q)
    //     Reconcile the editor to intensity Q (1–5): fold the target set (un-
    //     folding our previous set first), shrink the body font, and grow the
    //     surviving headers.  Idempotent toward Q, so it serves both the climb up
    //     and the climb down.
    //       Q=1  everything open, full size
    //       Q=2  fold the deepest nests
    //       …    each step folds one shallower indent level + shrinks a notch
    //       Q=5  every method body folded — only the method names remain
    //
    //   Lang_point_climb(w, toQ) / e:Lang_climb
    //     Gallop from the dock's current Q to toQ one level per wave, so the
    //     folds cascade and the font shrinks as a visible series of climbs rather
    //     than one jump.  Driven by the Waver below.
    //
    //   Lang_wave_enqueue / _step / _rush  — the Waver
    //     A queue of timed diff-waves drained forward, each applied for its
    //     duration, with a rush-to-end.  Deliberately generic (host + apply fn,
    //     no fold/Q knowledge) so Cytui's graph waves can adopt the same kernel
    //     later — its enqueue|drain|rush map onto this directly.
    //
    // ── Font scale ─────────────────────────────────────────────────────────────
    //
    //   The body scales by real font-size on %contentDOM + requestMeasure, so CM
    //   reflows (line heights, scroll maths stay honest) — not a transform, which
    //   would lie about geometry and break scroll-sync.  base_font_px is read once
    //   and cached on dock.c so repeated climbs scale from the same origin.
    //     The surviving names move the opposite way: as bodies fold and shrink, the
    //     method names and //#region titles GROW, via a per-name absolute-px mark
    //     decoration (dock.c.setPointFonts, the pointFontField in Langui) — only the
    //     identifier swells, the indent and any async|static keyword and the args
    //     stay body-size.  Absolute px so it overrides the inherited body shrink
    //     rather than scaling with it, turning a deep crunch into a contents view.
    //   < a font Compartment in Langui would isolate the body scale in a theme
    //     extension instead of touching contentDOM.style|swap Lang_set_font_scale's
    //     body to dispatch fontCompartment.reconfigure when that's wired.
    //
    // ── Fold animation ───────────────────────────────────────────────────────
    //
    //   < CM folds snap (the body is replaced by a placeholder, no height tween).
    //     Motion today comes from the gallop — folds cascade level by level and
    //     the font shrinks per step.  A true height tween needs a transitional
    //     fold decoration animating max-height before the real foldEffect lands|
    //     park that until the climb itself feels right.

    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { EditorState } from "@codemirror/state"
    import { EditorView } from "@codemirror/view"
    import { foldEffect, unfoldEffect } from "@codemirror/language"
    import { onMount } from "svelte"

    // A foldable indent block: header line, the last body line, the header's
    // leading-whitespace width, structural nesting depth (0 = top level), and
    // whether the header is a //#region marker (those never fold — see below).
    type Block = { header: number, end: number, indent: number, depth: number, is_region: boolean }

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region parts

    // Leading-whitespace width of a line, tabs counted as 4|−1 for a blank line
    // (blanks belong to whatever block encloses them, they neither open nor close).
    Lang_line_indent(text: string): number {
        if (text.trim() === '') return -1
        const m = text.match(/^[ \t]*/)
        return (m ? m[0] : '').replace(/\t/g, '    ').length
    },

    // Decompose the doc into foldable indent blocks.  A line heads a block when
    // the next non-blank line is more indented|the block runs to the last line
    // still deeper than the header.  Depth counts the blocks that strictly
    // contain this one, so it is structural nesting, not raw indent/4.
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
        // depth = blocks that strictly contain this block's header span.  A //#region
        // marker is organizational, not structural nesting, so it doesn't count as a
        // container — otherwise a method wrapped in a region would read one level
        // deeper than the same method outside one, and the Q scale would jump a step
        // just for being inside a region.
        for (const b of blocks) {
            b.depth = blocks.filter(o => o !== b && !o.is_region
                && o.header < b.header && o.end >= b.end && o.indent < b.indent).length
        }
        return blocks
    },

    // The OUTERMOST blocks crossing fold_depth that are also worth folding — the set
    // we actually fold.  Folding a parent already hides its children (a child would
    // only re-strand on the climb back down), so granularity is mostly the Q depth's
    // job: at Q5 (fold_depth 0) only top-level methods are direct targets and their
    // inner if|for blocks fold away *inside* them; an inner block becomes a direct
    // target only at a deeper Q that keeps its method open and dives.
    // The size floor is depth-aware: a top-level method body (depth 0) folds even at
    // 2 lines so the Q5 method list is complete, but a block INSIDE a method (depth ≥ 1)
    // must be substantial (MIN_INNER) to earn its own marker — a 3-line if saves nothing
    // and just litters the dive.  A //#region marker is navigational, never a fold
    // target — folding it would swallow the method names and region structure the climb
    // exists to surface — so region blocks stay counted for depth (their methods nest
    // under them) but are skipped here.  Shared by the fold-range and header-font builders.
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
    // Q → font scale for the SURVIVING headers, the inverse intent of Lang_Q_scale|
    // as detail folds away the lines that remain (method names, region titles) grow
    // so the overview reads as a table of contents.  1.0 at Q=1 (nothing folded, no
    // emphasis) up to ~1.34 at Q=5.  Absolute, not relative to the body shrink — a
    // header at Q=5 is ~1.34·base while bodies are ~0.64·base.
    Lang_Q_header_scale(Q: number): number {
        return +(1 + (Math.max(1, Math.min(5, Q)) - 1) * 0.085).toFixed(3)
    },

//#endregion
//#region apply

    // The dock's unscaled font px, read once from the live computed style and
    // cached so every climb scales from the same origin (re-reading after a climb
    // would read the already-shrunk size and the base would creep).
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

    // The name token on a header line — the slice the font field swells, so the
    // indent, any leading async|static|const keyword and the arg list all stay at
    // body size and only the identifier grows.  Two shapes:
    //   //#region <title>  → the title slice
    //   <indent><keywords><name>(…)  → the name identifier
    // Control-flow heads (if|for|while|…) carry no name worth promoting, so they
    // return null and stay body-size even when their block folds.  Offsets are
    // absolute (lineFrom + the match index) for the mark range.
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

    // The names whose font grows against the body shrink: the name of every folded
    // block (method heads) and every //#region title.  Each carries an absolute px
    // over its name span|region titles get the extra bump since they're the overview's
    // backbone, and are pushed first so dedup keeps their larger size when a region
    // line also heads a block.  Empty at Q=1 — nothing's folded, so nothing earns it.
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

    // The doc position the crunch pivots around: the cursor when it's on screen, else
    // the line at the vertical middle of the viewport — so a plain climb recedes toward
    // the centre of what you're reading.
    Lang_focal_pos(view: EditorView): number | null {
        const head = view.state.selection.main.head
        const vp   = view.viewport
        if (head >= vp.from && head <= vp.to) return head
        const r   = view.scrollDOM.getBoundingClientRect()
        const pos = view.posAtCoords({ x: r.left + 8, y: r.top + r.height / 2 })
        return pos ?? vp.from
    },

    // Reconcile the editor to intensity Q: unfold whatever WE folded last time,
    // fold the new target set, shrink the body font and grow the surviving headers
    // (all in one transaction).  Tracking our own folds on dock.c.q_folds keeps the
    // climb from fighting the user's manual region folds (we only ever unfold ranges
    // we put down).
    //   A focal anchor keeps the point you're looking at pinned: we note its screen y
    //   before the reflow and, once CM remeasures the new font + folds, scroll so it
    //   lands back there.  Without it the whole doc slides as the font shrinks and the
    //   crunch floods off the screen; with it everything recedes AROUND the focus,
    //   which holds still — the code puddles where you're reading.
    Lang_apply_Q(dock: TheC, Q: number) {
        const view  = dock.c.view  as EditorView | undefined
        const state = dock.c.state as EditorState | undefined
        if (!view || !state) return

        const focal    = this.Lang_focal_pos(view)
        const anchor_y = focal != null ? (view.coordsAtPos(focal)?.top ?? null) : null

        const blocks  = this.Lang_indent_blocks(state)
        const targets = this.Lang_fold_targets(state, blocks, this.Lang_Q_fold_depth(Q))
        const base    = this.Lang_base_font_px(dock)
        const fonts   = this.Lang_point_fonts(state, blocks, Q, base)

        const prev = (dock.c.q_folds as Array<{ from: number, to: number }>) ?? []
        const effects = [
            ...prev.map(r => unfoldEffect.of(r)),
            ...targets.map(r => foldEffect.of(r)),
        ]
        // header fonts ride the same transaction as the folds so the name lines
        // grow in lock-step with the bodies vanishing — no flicker between them.
        const setFonts = dock.c.setPointFonts as { of: (v: any) => any } | undefined
        if (setFonts) effects.push(setFonts.of(fonts))
        if (effects.length) view.dispatch({ effects })

        this.Lang_set_font_scale(dock, this.Lang_Q_scale(Q))

        // re-pin the focus once the new font + folds have laid out (read runs after
        //  CM's measure phase, write nudges the scroller).  < the per-Q wave gives the
        //  step rhythm; a CSS font-size transition would smooth between steps but CM's
        //  discrete remeasure fights the anchor mid-tween, so it's left to the wave.
        if (focal != null && anchor_y != null) {
            view.requestMeasure({
                read:  () => view.coordsAtPos(focal)?.top ?? null,
                write: (now_top: number | null) => {
                    if (now_top != null) view.scrollDOM.scrollTop += (now_top - anchor_y)
                },
            })
        }

        dock.c.q_folds = targets
        dock.c.Q       = Q
    },

//#endregion
//#region waver

    // ── Waver — a generic forward-stepping wave queue ─────────────────────────
    //
    //   host  — any off-snap object to stash queue state on (here a dock).
    //   apply — apply.call(this, wave, dur) for one wave.
    //   waves — wave objects, each optionally carrying sc.duration (seconds).
    //
    //   Drains one wave per duration, so a series animates forward|rush() flushes
    //   the rest instantly (a fresh enqueue or teardown wants the end state now).
    //   No fold|Q knowledge here on purpose — Cytui's upsert|migrate|remove waves
    //   can ride the same three calls.
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

    // Gallop the active dock from its current Q to toQ, one level per wave, so
    // the folds cascade and the font shrinks as a visible climb.  Re-enqueueing
    // mid-climb rushes the pending steps to their end state first, then climbs
    // from there — no half-applied jumble.
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

    // ── e:Lang_climb ─────────────────────────────────────────────────────────
    //   The minimap's Q dial (and any goto wanting the current crunch) fires this.
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
