<script lang="ts">
    // Langminimap — floating overview strip for the active CM doc.
    //
    // ── Mount ────────────────────────────────────────────────────────────────
    //
    //   Mounted by Langui as a sibling of .lte-cm.  Receives:
    //     H          — the House
    //     view       — the live EditorView (for scroll dispatch and viewport reads)
    //     active_path — current doc path ($state from Langui)
    //
    //   Floats with position:absolute, top:0, right:0, height:100% over the
    //   editor's right margin.  Pointer events on the strip itself; click-through
    //   on the empty space behind it is not needed (CM has its own scrollbar).
    //
    // ── Data ─────────────────────────────────────────────────────────────────
    //
    //   Reads the compiled methods index that LangCompiling deposits at
    //     ave/{langtiles_doc:path}/{job}/{Compile:1}/{Output:1}/{methods:1}
    //   Pulls all {region:1}, {def:1}, {controlflow:1} children.
    //
    //   Falls back to live region scan via Lang_build_regions when no compiled
    //   index is present yet, so the user sees structure before the first compile.
    //
    // ── Layout model ─────────────────────────────────────────────────────────
    //
    //   The strip is a single vertical bar of height 100%.  Each region is
    //   a band whose top/height are computed from its line range relative to
    //   total doc lines.  Defs are short ticks inside the band (from MethodLike
    //   def entries).  Region nesting is shown as left-edge inset (depth * 4px).
    //
    // ── Future ───────────────────────────────────────────────────────────────
    //
    //   Painting gestures (wax-on / wax-off) for applying line styles and
    //   selecting sub-Points come later; this is the read-only first pass.

    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { EditorView } from "@codemirror/view"
    import type { EditorState } from "@codemirror/state"
    import { foldEffect, unfoldEffect } from "@codemirror/language"

    type Region = {
        label:     string
        depth:     number
        from_line: number
        to_line:   number
        from_char: number
        to_char:   number
        defs:      Def[]    // method defs that fall inside this region's range
        points:    PointMark[]    // resolved Points that fall inside this region's range
    }
    type Def = { method: string, line: number, from: number, to: number }

    // A Point becomes a PointMark once resolved against the methods index.
    // `spec` is the original method-spec string (may be fuzzy / stack-path);
    // `unresolved` flags Points we couldn't locate so the strip can show
    // them as warnings rather than dropping them silently.
    type PointMark = {
        spec:       string
        method:     string   // the resolved def method name (or spec if unresolved)
        line:       number
        from:       number
        to:         number
        unresolved: boolean
    }

    let { H, view, active_path }: {
        H:           House
        view:        EditorView | undefined
        active_path: string
    } = $props()

    // Diagnostic — should fire once view prop is set (after Langui constructs).
    // If this never fires after CM appears, the prop isn't reactive and clicks
    // will silently no-op.
    $effect(() => {
        console.log(`🗺 minimap view prop = ${view ? 'EditorView OK' : 'undefined'}, active_path = ${active_path}`)
    })

    // Visibility toggle — collapsible strip.  Persisted only in module memory
    // for now (no Stuff sc storage); flip with the chevron on the strip header.
    let visible = $state(true)

    // Per-region collapsed state for the strip's own UI (independent of CM folds).
    // Keyed by `${from_line}:${label}` so re-orderings don't bleed state.
    let collapsed = $state(new Map<string, boolean>())

    // ── navigation history ───────────────────────────────────────────────────
    //   A simple stack of {path, from, to, label} entries: every region/def
    //   click pushes one.  back()/forward() step through.  history is reset on
    //   doc switch — cross-doc nav goes through Lang_point_navigate instead.
    type NavEntry = { path: string, from: number, to: number, label: string }
    let nav_hist: NavEntry[] = $state([])
    let nav_pos               = $state(-1)   // index of current entry, -1 = none
    let can_back     = $derived(nav_pos > 0)
    let can_forward  = $derived(nav_pos < nav_hist.length - 1)

    // Reset history when the active doc changes — the entries reference char
    // offsets that only make sense in their original doc.
    let _last_path = ''
    $effect(() => {
        if (active_path !== _last_path) {
            nav_hist = []
            nav_pos = -1
            _last_path = active_path
        }
    })

    // ── data sources ─────────────────────────────────────────────────────────
    //   docC drives total_lines (for proportional layout) and the methods
    //   index.  H.ave.ob() makes ave-version-bumps wake this $effect.
    let docC: TheC | undefined = $state()
    $effect(() => {
        docC = active_path ? H.ave.ob({ langtiles_doc: active_path })[0] as TheC | undefined : undefined
    })

    let total_lines = $derived.by(() => {
        void docC?.version
        const text = (docC?.sc.text as string) ?? ''
        if (!text) return 1
        // count newlines + 1, matching CM's 1-based line count
        let n = 1
        for (const ch of text) if (ch === '\n') n++
        return n
    })

    // Pull regions, defs, and Points for the active doc.
    //
    //   regions, defs come from the compiled methods index at
    //     ave/{langtiles_doc:path}/{Compile:1}/{Output:1}/{methods:1}
    //
    //   Points live elsewhere — under Lies's Wafts at
    //     w/{Waft:p}/{Doc:1,path}/{Points:1}/{Point:1, method:'spec'}
    //   so we walk all Wafts to find any Doc whose `path` matches.  Each
    //   Point's `method` spec is resolved against the methods index here
    //   (a simplified version of Lang_resolve_point — exact def then fuzzy).
    //
    // Both `regions` and `top_level_defs` and `top_level_points` are produced
    // by one $derived so the bucket logic can mutate region children without
    // crossing into a separate $effect.
    let _structure = $derived.by((): {
        regions: Region[], top_level_defs: Def[], top_level_points: PointMark[],
    } => {
        void docC?.version
        if (!docC) return { regions: [], top_level_defs: [], top_level_points: [] }

        const job     = docC.o({ Compile: 1 })[0]    as TheC | undefined
        const output  = job?.o({ Output: 1 })[0]     as TheC | undefined
        const methods = output?.o({ methods: 1 })[0] as TheC | undefined

        // Collect Point specs for this doc — independent of whether the
        // methods index exists, because Points are user-promoted and we
        // want to surface them even before first compile (as unresolved).
        const point_specs = collect_point_specs_for_path(active_path)

        if (methods) {
            const region_entries = methods.o({ region: 1 }) as TheC[]
            const def_entries    = methods.o({ def:    1 }) as TheC[]

            const list: Region[] = region_entries.map(r => ({
                label:     r.sc.label as string,
                depth:     r.sc.depth as number,
                from_line: r.sc.line  as number,
                to_line:   total_lines,                  // patched below
                from_char: r.sc.from  as number,
                to_char:   r.sc.to    as number,         // patched below from text scan
                defs:      [],
                points:    [],
            }))

            // Patch to_line / to_char by scanning forward in the doc for
            // //#endregion or the next region at <= depth.  The compiler
            // doesn't currently emit close offsets per-region, so we do it here.
            const text = (docC.sc.text as string) ?? ''
            patch_region_extents(list, text, total_lines)

            // Bucket defs into their containing region (innermost wins).
            const top_defs: Def[] = []
            for (const d of def_entries) {
                const def: Def = {
                    method: d.sc.method as string,
                    line:   d.sc.line   as number,
                    from:   d.sc.from   as number,
                    to:     d.sc.to     as number,
                }
                const owner = innermost_region_for_line(list, def.line)
                if (owner) owner.defs.push(def)
                else top_defs.push(def)
            }

            // Resolve each Point spec against the def index.
            const top_points: PointMark[] = []
            for (const spec of point_specs) {
                const mark = resolve_point_to_mark(spec, def_entries)
                if (!mark) continue
                const owner = innermost_region_for_line(list, mark.line)
                if (owner) owner.points.push(mark)
                else top_points.push(mark)
            }

            console.log(`🗺 minimap rebuild ${active_path}: regions=${list.length} defs=${def_entries.length} points=${point_specs.length} unresolved=${top_points.reduce((n,p) => n + (p.unresolved ? 1 : 0), 0)}`)
            return { regions: list, top_level_defs: top_defs, top_level_points: top_points }
        }

        // Fallback path: no compiled methods index yet.  Scan regions
        // directly from doc text and surface any Points as unresolved
        // (they'll cluster at line 1 in red, indicating the user should
        // run compile to land them properly).
        const fallback_regions = scan_regions_from_text((docC.sc.text as string) ?? '')
        const fallback_top_points: PointMark[] = point_specs.map(spec => ({
            spec, method: spec, line: 1, from: 0, to: 0, unresolved: true,
        }))

        console.log(`🗺 minimap rebuild ${active_path} (no compile yet): regions=${fallback_regions.length} points=${point_specs.length} (all unresolved)`)
        return {
            regions:          fallback_regions,
            top_level_defs:   [],
            top_level_points: fallback_top_points,
        }
    })

    let regions          = $derived(_structure.regions)
    let top_level_defs   = $derived(_structure.top_level_defs)
    let top_level_points = $derived(_structure.top_level_points)

    // Collect Point specs for `path` by walking H.ave.examining/c/w/Waft*/Doc.
    // Reactive on H.ave (ob) so when Wafts/Points change the strip refreshes.
    function collect_point_specs_for_path(path: string): string[] {
        const out: string[] = []
        if (!path) return out
        const ex = H.ave.ob({ examining: 1 })[0] as TheC | undefined
        const lies_w = ex?.c?.w as TheC | undefined
        if (!lies_w) {
            console.log(`🗺 minimap: no examining.c.w found — Lies not booted yet?`)
            return out
        }

        const wafts = lies_w.o({ Waft: 1 }) as TheC[]
        let docs_matched = 0
        for (const waft of wafts) {
            const doc = waft.o({ Doc: 1, path })[0] as TheC | undefined
            if (!doc) continue
            docs_matched++
            const pointsC = doc.o({ Points: 1 })[0] as TheC | undefined
            if (!pointsC) continue
            for (const p of pointsC.o({ Point: 1 }) as TheC[]) {
                const spec = p.sc.method as string | undefined
                if (spec) out.push(spec)
            }
        }
        if (wafts.length && !out.length) {
            console.log(`🗺 minimap: ${wafts.length} Wafts, ${docs_matched} matched Doc:${path}, 0 Points`)
        }
        return out
    }

    // Resolve a Point's method-spec against the def list.  Mirrors the simpler
    // half of Lang_resolve_point: exact match → fuzzy substring → unresolved.
    // (Stack-path resolution is left to Lang_resolve_point in the backend.)
    function resolve_point_to_mark(spec: string, defs: TheC[]): PointMark | null {
        const exact = defs.find(d => d.sc.method === spec)
        if (exact) return {
            spec,
            method: exact.sc.method as string,
            line:   exact.sc.line   as number,
            from:   exact.sc.from   as number,
            to:     exact.sc.to     as number,
            unresolved: false,
        }
        const lc = spec.toLowerCase()
        const fuzzy = defs.find(d => (d.sc.method as string)?.toLowerCase().includes(lc))
        if (fuzzy) return {
            spec,
            method: fuzzy.sc.method as string,
            line:   fuzzy.sc.line   as number,
            from:   fuzzy.sc.from   as number,
            to:     fuzzy.sc.to     as number,
            unresolved: false,
        }
        // Unresolved Points are still returned with line 0 so the strip can
        // surface them — they'll cluster at the top with a warning style.
        return { spec, method: spec, line: 1, from: 0, to: 0, unresolved: true }
    }

    // ── helpers ──────────────────────────────────────────────────────────────

    // Scan doc text directly for //#region / //#endregion when no compiled
    // index is available yet.  Mirrors LangRegions/Lang_build_regions but
    // doesn't need an EditorState (cheaper for the strip's first paint).
    function scan_regions_from_text(text: string): Region[] {
        const REGION_RE    = /^[\t ]*\/\/#region\s+(.+)$/
        const ENDREGION_RE = /^[\t ]*\/\/#endregion\b/
        const lines = text.split('\n')

        const all:   Region[] = []
        const stack: Region[] = []
        let char_offset = 0

        for (let i = 0; i < lines.length; i++) {
            const line_text  = lines[i]
            const line_num   = i + 1
            const line_from  = char_offset
            const line_to    = char_offset + line_text.length

            const m = line_text.match(REGION_RE)
            if (m) {
                // Implicit close at same-or-shallower depth.
                const depth = stack.length
                while (stack.length > depth) {
                    const closing      = stack.pop()!
                    closing.to_line    = line_num - 1
                    closing.to_char    = line_from
                }
                const region: Region = {
                    label:     m[1].trim(),
                    depth,
                    from_line: line_num,
                    to_line:   lines.length,
                    from_char: line_from,
                    to_char:   text.length,
                    defs:      [],
                    points:    [],
                }
                all.push(region)
                stack.push(region)
            } else if (ENDREGION_RE.test(line_text) && stack.length) {
                const closing   = stack.pop()!
                closing.to_line = line_num
                closing.to_char = line_to
            }
            char_offset = line_to + 1   // +1 for the \n we split on
        }
        return all
    }

    // Patch to_line / to_char on regions whose close was not recorded by the
    // compiler.  Walks the doc text once for //#endregion markers and matches
    // them up against the open-region stack reconstructed from `list`.
    function patch_region_extents(list: Region[], text: string, total: number) {
        if (!list.length) return
        const ENDREGION_RE = /^[\t ]*\/\/#endregion\b/
        const lines = text.split('\n')

        // Build a stack-position-by-line map.
        // Sort regions by from_line so we can walk forward and maintain a stack.
        const sorted = [...list].sort((a, b) => a.from_line - b.from_line)
        const stack: Region[] = []
        let next = 0
        let char_offset = 0

        for (let i = 0; i < lines.length; i++) {
            const line_num = i + 1
            const line_to  = char_offset + lines[i].length

            // Open any regions starting on this line.
            while (next < sorted.length && sorted[next].from_line === line_num) {
                // Close any open regions at >= this region's depth first.
                while (stack.length && stack[stack.length - 1].depth >= sorted[next].depth) {
                    const closing      = stack.pop()!
                    if (closing.to_line === total) {  // not yet patched
                        closing.to_line = line_num - 1
                        closing.to_char = char_offset > 0 ? char_offset - 1 : 0
                    }
                }
                stack.push(sorted[next])
                next++
            }

            if (ENDREGION_RE.test(lines[i]) && stack.length) {
                const closing   = stack.pop()!
                closing.to_line = line_num
                closing.to_char = line_to
            }
            char_offset = line_to + 1
        }
        // Anything left on the stack runs to doc end (default already set).
    }

    function innermost_region_for_line(list: Region[], line: number): Region | undefined {
        // Linear scan; doc sizes are small enough that this isn't worth optimising.
        // Innermost wins because we keep overwriting on every match.
        let winner: Region | undefined
        for (const r of list) {
            if (line >= r.from_line && line <= r.to_line) {
                if (!winner || r.depth >= winner.depth) winner = r
            }
        }
        return winner
    }

    // ── interactions ─────────────────────────────────────────────────────────

    // Scroll CM to a doc-char offset and place the cursor there.  Pushes a
    // history entry unless we're navigating via back()/forward() (in which
    // case nav_pos is being moved without recording a new step).
    //
    // Uses EditorView.scrollIntoView as a StateEffect (more reliable than the
    // boolean `scrollIntoView: true` on TransactionSpec — that one only scrolls
    // the cm-scroller, but our outer .lte-cm wraps it and may be the actual
    // overflow surface).  The effect tells CM exactly where to scroll and
    // CM walks up the DOM to find scrollable ancestors.
    function go_to(from: number, to: number, label: string) {
        console.log(`🗺 minimap go_to('${label}' [${from}..${to}]): view=${view ? 'OK' : 'UNDEFINED'} active_path=${active_path}`)
        if (!view) return
        view.dispatch({
            selection: { anchor: from, head: to },
            effects: EditorView.scrollIntoView(from, { y: 'center' }),
        })
        view.focus()

        // Truncate any forward history (classic browser-style behaviour: a new
        // navigation drops everything past the current position) then append.
        const truncated = nav_hist.slice(0, nav_pos + 1)
        truncated.push({ path: active_path, from, to, label })
        nav_hist = truncated
        nav_pos  = truncated.length - 1
    }

    // Move backward / forward through nav_hist without recording a new entry.
    function go_back() {
        if (!can_back || !view) return
        nav_pos = nav_pos - 1
        const e = nav_hist[nav_pos]
        view.dispatch({
            selection: { anchor: e.from, head: e.to },
            effects: EditorView.scrollIntoView(e.from, { y: 'center' }),
        })
        view.focus()
    }
    function go_forward() {
        if (!can_forward || !view) return
        nav_pos = nav_pos + 1
        const e = nav_hist[nav_pos]
        view.dispatch({
            selection: { anchor: e.from, head: e.to },
            effects: EditorView.scrollIntoView(e.from, { y: 'center' }),
        })
        view.focus()
    }

    // Toggle the strip's own collapsed state for this region.  Independent of
    // CM folding — just hides def ticks below the heading on the strip.
    function toggle_collapse(region: Region) {
        const key = `${region.from_line}:${region.label}`
        const next = new Map(collapsed)
        next.set(key, !next.get(key))
        collapsed = next
    }
    function is_collapsed(region: Region): boolean {
        return collapsed.get(`${region.from_line}:${region.label}`) ?? false
    }

    // Fold / unfold this region in CM itself.  Body-only fold: header line
    // stays visible (matches Lang_apply_openness semantics).
    function toggle_fold(region: Region) {
        if (!view) return
        const state = view.state
        const header_line = state.doc.line(region.from_line)
        const fold_from   = header_line.to
        const fold_to     = Math.min(region.to_char, state.doc.length)
        if (fold_from >= fold_to) return

        // Detect whether this range is currently folded by checking if any
        // visible character exists between fold_from and fold_to in the
        // viewport.  Cheaper than introspecting the fold state directly:
        // if the line at the fold midpoint is in viewport, it's unfolded.
        const mid = Math.floor((fold_from + fold_to) / 2)
        const block = view.lineBlockAt(mid)
        const is_currently_visible = block.from <= mid && block.to >= mid &&
                                     block.bottom > block.top + 1

        view.dispatch({
            effects: [
                is_currently_visible
                    ? foldEffect.of({ from: fold_from, to: fold_to })
                    : unfoldEffect.of({ from: fold_from, to: fold_to })
            ]
        })
    }

    // ── layout maths ─────────────────────────────────────────────────────────
    //   y-coords are percentages of the strip's height.  The strip is the same
    //   height as the editor, so a region spanning lines [a..b] of total N
    //   takes y = ((a-1)/N * 100)% to (b/N * 100)%.

    function band_top(line: number): string {
        return `${((line - 1) / total_lines) * 100}%`
    }
    function band_height(from_line: number, to_line: number): string {
        return `${((to_line - from_line + 1) / total_lines) * 100}%`
    }

    // Hue per depth so nested bands are visually distinct.
    function band_color(depth: number): string {
        const hue = (210 + depth * 40) % 360
        return `hsla(${hue}, 50%, 50%, 0.18)`
    }
    function band_border(depth: number): string {
        const hue = (210 + depth * 40) % 360
        return `hsla(${hue}, 60%, 60%, 0.5)`
    }
</script>

{#if visible}
<div class="lmm">
    <div class="lmm-head">
        <button class="lmm-toggle" onclick={() => visible = false} aria-label="Hide minimap" title="Hide">‹</button>
        <button class="lmm-nav" onclick={go_back} disabled={!can_back}
                title="Back" aria-label="Back">◂</button>
        <button class="lmm-nav" onclick={go_forward} disabled={!can_forward}
                title="Forward" aria-label="Forward">▸</button>
        <span class="lmm-title" title="{regions.length} region{regions.length === 1 ? '' : 's'}">
            {nav_pos >= 0 ? nav_hist[nav_pos].label : `${regions.length}r`}
        </span>
    </div>

    <div class="lmm-strip">
        <!-- Colored stripes: one per region, just a tinted vertical block.
             Width-shrunk by depth so nesting reads as a stack of stripes. -->
        {#each regions as r (r.from_line + ':' + r.label)}
            <div class="lmm-stripe"
                 style="top: {band_top(r.from_line)};
                        height: {band_height(r.from_line, r.to_line)};
                        left: {r.depth * 5}px;
                        background: {band_color(r.depth)};
                        border-left: 2px solid {band_border(r.depth)};"
                 aria-hidden="true"></div>
        {/each}

        <!-- Labels: rendered separately so band height doesn't squash them.
             Each is an absolutely-positioned row at the region's top line.
             Overflow allowed — long labels extend left over the strip.
             Depth shrinks font-size and dims color so nesting reads visually
             rather than just from indent: top-level labels are bold and bright,
             children are smaller and dimmer. -->
        {#each regions as r (r.from_line + ':' + r.label)}
            <div class="lmm-row" style="
                    top: {band_top(r.from_line)};
                    padding-left: {r.depth * 5 + 4}px;
                    font-size: {Math.max(11 - r.depth, 8)}px;
                    opacity: {Math.max(1 - r.depth * 0.12, 0.6)};
                ">
                <button class="lmm-chev"
                        onclick={() => toggle_collapse(r)}
                        aria-label="Toggle band">{is_collapsed(r) ? '▸' : '▾'}</button>
                <button class="lmm-label"
                        onclick={() => go_to(r.from_char, r.from_char, r.label)}
                        title="{r.label} (line {r.from_line}–{r.to_line})">{r.label}</button>
                <button class="lmm-fold"
                        onclick={() => toggle_fold(r)}
                        title="Fold/unfold in editor">f</button>
            </div>

            {#if !is_collapsed(r)}
                <!-- Points: promoted methods, shown as full-width rows with
                     method name always visible.  Higher z-index so they sit
                     on top of stripes; warning style when unresolved. -->
                {#each r.points as p (p.spec)}
                    <button class="lmm-point" class:lmm-point-bad={p.unresolved}
                            style="top: {band_top(p.line)}; left: {r.depth * 5 + 4}px;"
                            title="{p.spec}{p.unresolved ? ' (unresolved)' : ''} → {p.method} line {p.line}"
                            onclick={() => go_to(p.from, p.to, p.method)}>
                        <span class="lmm-point-dot"></span>
                        <span class="lmm-point-label">{p.method}</span>
                    </button>
                {/each}

                {#each r.defs as d (d.from)}
                    <button class="lmm-def"
                            style="top: {band_top(d.line)}; left: {r.depth * 5 + 4}px;"
                            title="{d.method} (line {d.line})"
                            onclick={() => go_to(d.from, d.to, d.method)}>
                        <span class="lmm-def-tick"></span>
                        <span class="lmm-def-label">{d.method}</span>
                    </button>
                {/each}
            {/if}
        {/each}

        <!-- Top-level Points — promoted methods that aren't inside any region. -->
        {#each top_level_points as p (p.spec)}
            <button class="lmm-point" class:lmm-point-bad={p.unresolved}
                    style="top: {band_top(p.line)}; left: 4px;"
                    title="{p.spec}{p.unresolved ? ' (unresolved)' : ''} → {p.method} line {p.line}"
                    onclick={() => go_to(p.from, p.to, p.method)}>
                <span class="lmm-point-dot"></span>
                <span class="lmm-point-label">{p.method}</span>
            </button>
        {/each}

        <!-- Top-level defs (defs not inside any region) — same tick style,
             rendered last so they paint over any stripe edges. -->
        {#each top_level_defs as d (d.from)}
            <button class="lmm-def lmm-def-top"
                    style="top: {band_top(d.line)}; left: 4px;"
                    title="{d.method} (line {d.line})"
                    onclick={() => go_to(d.from, d.to, d.method)}>
                <span class="lmm-def-tick"></span>
                <span class="lmm-def-label">{d.method}</span>
            </button>
        {/each}
    </div>
</div>
{:else}
    <button class="lmm-show" onclick={() => visible = true} aria-label="Show minimap" title="Show minimap">›</button>
{/if}

<style>
    .lmm {
        position: absolute; top: 24px; right: 0; bottom: 0;
        /* top:24px clears the .lte-bar; bottom:0 fills rest of .lte's height.
           Anchored to .lte (position:relative) so it sits over .lte-cm only. */
        width: 200px;
        display: flex; flex-direction: column;
        background: rgba(10, 10, 14, 0.78);
        border-left: 1px solid #1a1a1a;
        backdrop-filter: blur(4px);
        font-family: 'Berkeley Mono', 'Fira Code', ui-monospace, monospace;
        font-size: 11px; color: #aab;
        z-index: 10;
        pointer-events: auto;
    }
    .lmm-head {
        display: flex; align-items: center; gap: 6px;
        padding: 4px 6px; background: rgba(0, 0, 0, 0.3);
        border-bottom: 1px solid #1a1a1a;
        flex-shrink: 0;
    }
    .lmm-toggle {
        background: none; border: none; color: #6a8a9a; cursor: pointer;
        font-size: 14px; padding: 0 4px; line-height: 1;
    }
    .lmm-toggle:hover { color: #a0c0d0; }
    .lmm-nav {
        background: none; border: none; cursor: pointer;
        color: #6a8a9a; padding: 0 3px; font-size: 12px; line-height: 1;
        font-family: inherit;
    }
    .lmm-nav:hover:not(:disabled) { color: #c0d0e0; }
    .lmm-nav:disabled { color: #2a3a45; cursor: default; }
    .lmm-show {
        position: absolute; top: 24px; right: 0;
        background: rgba(10, 10, 14, 0.7);
        border: 1px solid #1a1a1a; border-right: none;
        border-radius: 3px 0 0 3px;
        padding: 4px 6px;
        color: #6a8a9a; cursor: pointer;
        z-index: 10;
    }
    .lmm-show:hover { color: #a0c0d0; }
    .lmm-title {
        color: #678; font-size: 10px;
        flex: 1; min-width: 0;
        overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
    }

    /* Strip surface holds three layers, all absolute-positioned within it:
         .lmm-stripe — colored bands sized by region line span (z-index 0)
         .lmm-row    — region label rows at each region's top line (z-index 2)
         .lmm-def    — method ticks at each def's line (z-index 1)
       overflow:hidden on the strip itself; rows are allowed to extend
       leftward over their parent stripes via negative margin if needed. */
    .lmm-strip {
        position: relative;
        flex: 1;
        overflow: hidden;
    }

    .lmm-stripe {
        position: absolute; right: 0;
        z-index: 0;
        pointer-events: none;
        min-height: 2px;
    }

    /* Region label row — fixed height, positioned at the region's top line.
       Sits above stripes, allowed to overflow horizontally if label is long.
       The row height adds some pixels which can extend slightly beyond the
       stripe in tiny regions, but that's better than clipped text. */
    .lmm-row {
        position: absolute; right: 0; left: 0;
        z-index: 2;
        display: flex; align-items: center; gap: 2px;
        height: 16px; margin-top: -1px;
        background: rgba(0, 0, 0, 0.55);
        border-top: 1px solid rgba(120, 140, 170, 0.25);
        padding-right: 4px;
        white-space: nowrap;
    }

    .lmm-chev, .lmm-fold {
        background: none; border: none; color: #6a8a9a;
        cursor: pointer; padding: 0 3px; line-height: 1;
        font-size: 10px;
        font-family: inherit;
        flex-shrink: 0;
    }
    .lmm-chev:hover, .lmm-fold:hover { color: #c0d0e0; }
    .lmm-fold { color: #4a5a6a; font-style: italic; }

    .lmm-label {
        background: none; border: none; cursor: pointer;
        color: #c0d0e0; padding: 0; flex: 1; text-align: left;
        overflow: hidden; text-overflow: ellipsis;
        font-family: inherit; font-size: inherit;
        line-height: 1.2;
    }
    .lmm-label:hover { color: #fff; }

    /* Method def — tick + hover label.  No background, no clipping; the
       label fades in on hover and is allowed to extend beyond the strip. */
    .lmm-def {
        position: absolute; right: 4px;
        z-index: 1;
        background: none; border: none; padding: 0; cursor: pointer;
        height: 8px; margin-top: -4px;
        display: flex; align-items: center; gap: 4px;
    }
    .lmm-def-tick {
        display: block;
        width: 14px; height: 2px;
        background: rgba(180, 200, 220, 0.45);
        flex-shrink: 0;
    }
    .lmm-def:hover .lmm-def-tick { background: rgba(180, 200, 220, 0.95); height: 3px; }

    .lmm-def-label {
        font-size: 9px; color: #889;
        opacity: 0;
        transition: opacity 0.1s;
        pointer-events: none;
        white-space: nowrap;
    }
    .lmm-def:hover .lmm-def-label { opacity: 1; color: #c0d0e0; }

    /* Top-level defs (no enclosing region) get a warmer tick color so they
       stand out from in-region defs at a glance. */
    .lmm-def-top .lmm-def-tick { background: rgba(220, 200, 140, 0.45); }
    .lmm-def-top:hover .lmm-def-tick { background: rgba(220, 200, 140, 0.95); }

    /* Points — user-promoted methods, always-visible label, sit above defs.
       The dot anchors the position; label extends to the right.  z-index 3
       so they're above both stripes (0) and rows (2). */
    .lmm-point {
        position: absolute; right: 4px;
        z-index: 3;
        background: rgba(0, 0, 0, 0.4);
        border: none; border-radius: 2px;
        padding: 1px 4px 1px 2px;
        cursor: pointer;
        margin-top: -7px;
        display: flex; align-items: center; gap: 4px;
        font-family: inherit;
    }
    .lmm-point:hover { background: rgba(0, 0, 0, 0.7); }
    .lmm-point-dot {
        display: block;
        width: 6px; height: 6px;
        background: #e5c07b;            /* gold — matches stho title tag */
        border-radius: 50%;
        flex-shrink: 0;
    }
    .lmm-point-label {
        font-size: 10px;
        color: #e5c07b;
        white-space: nowrap;
        max-width: 140px;
        overflow: hidden; text-overflow: ellipsis;
    }
    .lmm-point:hover .lmm-point-label { color: #fff; }

    /* Unresolved Point — strikethrough + warning red. */
    .lmm-point-bad .lmm-point-dot { background: #e06c75; }
    .lmm-point-bad .lmm-point-label {
        color: #e06c75; text-decoration: line-through;
    }
</style>
