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
    //     folding our previous set first), and scale the font.  Idempotent toward
    //     Q, so it serves both the climb up and the climb down.
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
    //   Scaling is real font-size on %contentDOM + requestMeasure, so CM reflows
    //   (line heights, scroll maths stay honest) — not a transform, which would
    //   lie about geometry and break scroll-sync.  base_font_px is read once and
    //   cached on dock.c so repeated climbs scale from the same origin.
    //   < a font Compartment in Langui would isolate this in a theme extension
    //     instead of touching contentDOM.style|swap Lang_set_font_scale's body to
    //     dispatch fontCompartment.reconfigure when that's wired.
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
    // leading-whitespace width, and structural nesting depth (0 = top level).
    type Block = { header: number, end: number, indent: number, depth: number }

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
                blocks.push({ header: i, end, indent: ind[i], depth: 0 })
            }
        }
        // depth = number of blocks that strictly contain this block's header span
        for (const b of blocks) {
            b.depth = blocks.filter(o => o !== b
                && o.header < b.header && o.end >= b.end && o.indent < b.indent).length
        }
        return blocks
    },

    // Char ranges to fold for a given fold_depth — the OUTERMOST blocks crossing
    // the threshold (folding a parent already hides its children, so we never
    // dispatch a fold inside an already-folded span).  Fold range is body-only:
    // [end of the header line, end of the block] so the header stays readable.
    Lang_fold_targets(state: EditorState, blocks: Block[], fold_depth: number)
        : Array<{ from: number, to: number }> {
        if (!isFinite(fold_depth)) return []
        const doc = state.doc
        const crossing = blocks.filter(b => b.depth >= fold_depth)
        const outermost = crossing.filter(b =>
            !crossing.some(a => a !== b && a.header < b.header && a.end >= b.end))
        const ranges: Array<{ from: number, to: number }> = []
        for (const b of outermost) {
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

//#endregion
//#region apply

    // Set the editor font to base·scale and let CM remeasure so it reflows.
    Lang_set_font_scale(dock: TheC, scale: number) {
        const view = dock.c.view as EditorView | undefined
        if (!view) return
        const content = view.contentDOM as HTMLElement
        // cache the unscaled size once, from the live computed style
        let base = dock.c.base_font_px as number | undefined
        if (base == null) {
            const px = parseFloat(getComputedStyle(content).fontSize)
            base = isFinite(px) && px > 0 ? px : 13
            dock.c.base_font_px = base
        }
        content.style.fontSize = `${(base * scale).toFixed(2)}px`
        view.requestMeasure()
    },

    // Reconcile the editor to intensity Q: unfold whatever WE folded last time,
    // fold the new target set, scale the font.  Tracking our own folds on
    // dock.c.q_folds keeps the climb from fighting the user's manual region folds
    // (we only ever unfold ranges we put down).
    Lang_apply_Q(dock: TheC, Q: number) {
        const view  = dock.c.view  as EditorView | undefined
        const state = dock.c.state as EditorState | undefined
        if (!view || !state) return

        const blocks  = this.Lang_indent_blocks(state)
        const targets = this.Lang_fold_targets(state, blocks, this.Lang_Q_fold_depth(Q))

        const prev = (dock.c.q_folds as Array<{ from: number, to: number }>) ?? []
        const effects = [
            ...prev.map(r => unfoldEffect.of(r)),
            ...targets.map(r => foldEffect.of(r)),
        ]
        if (effects.length) view.dispatch({ effects })

        this.Lang_set_font_scale(dock, this.Lang_Q_scale(Q))

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
