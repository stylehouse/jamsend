<script lang="ts">
    // DocMinimap — floating overview strip for the active CM doc.
    //
    // ── Mount ────────────────────────────────────────────────────────────────
    //
    //   Mounted by Langui as a sibling of .lte-cm.  Receives:
    //     H           — the House
    //     view        — the live EditorView (for scroll dispatch and viewport reads)
    //     active_path — current doc path ($state from Langui)
    //
    //   Floats with position:absolute, top:0, right:0, height:100% over the
    //   editor's right margin.  Pointer events on the strip itself; click-through
    //   on the empty space behind it is not needed (CM has its own scrollbar).
    //
    // ── Data ─────────────────────────────────────────────────────────────────
    //
    //   Reads the compiled methods index that LangCompiling deposits at
    //     w:Lang/{docs}/{doc:path}/{Compile:1}/{Output:1}/{methods:1}  (via lang_docC)
    //   Pulls all {region:1}, {def:1}, {controlflow:1} children.
    //
    //   Falls back to live region scan when no compiled index is present yet,
    //   so the user sees structure before the first compile.
    //
    //   Points come from %Pmirror,N particles that LangGraft maintains under
    //   the lang-side docC's %Pmirrors,1.  Each Pmirror with a %graft,1 child
    //   has resolved to a live position; one without is unresolved and renders
    //   in the warning style.  The minimap does no resolution work itself.
    //
    // ── Layout model ─────────────────────────────────────────────────────────
    //
    //   The strip is a single vertical bar of height 100%.  Each region is
    //   a band whose top/height are computed from its line range relative to
    //   total doc lines.  Defs are short ticks inside the band.  Region nesting
    //   is shown as left-edge inset (depth * 5px).
    //
    // ── Rebuild throttle ─────────────────────────────────────────────────────
    //
    //   _structure is $state, not $derived.by.  A single $effect registers
    //   reactive deps cheaply (void reads) then calls schedule_rebuild().
    //   requestAnimationFrame collapses any burst of version-bumps within one
    //   frame into exactly one rebuild() call — silencing the 0→1→0 point-
    //   resolution oscillation that was flooding the console.

    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { EditorView } from "@codemirror/view"
    import { foldEffect, unfoldEffect, foldedRanges } from "@codemirror/language"

    type Region = {
        label:     string
        depth:     number
        from_line: number
        to_line:   number
        from_char: number
        to_char:   number
        defs:      Def[]
        points:    PointMark[]
    }
    type Def = { method: string, line: number, from: number, to: number }

    // A Point becomes a PointMark once its graft fields have been stamped by
    // Lang_graft_points.  unresolved:true means LangGraft hasn't found the
    // method in the compile index yet (pre-compile, or name changed).
    type PointMark = {
        spec:       string    // original Point method/label spec
        method:     string    // same as spec (resolved name lives here too, future)
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

    $effect(() => {
        console.log(`🗺 minimap view prop = ${view ? 'EditorView OK' : 'undefined'}, active_path = ${active_path}`)
    })

    // Only log when the structural summary actually changes.
    let last_log_summary = ''

    // Per-region collapsed state for the strip's own UI (independent of CM folds).
    // Keyed by `${from_line}:${label}` so re-orderings don't bleed state.
    let collapsed = $state(new Map<string, boolean>())

    // ── navigation history ───────────────────────────────────────────────────
    type NavEntry = { path: string, from: number, to: number, label: string }
    let nav_hist: NavEntry[] = $state([])
    let nav_pos               = $state(-1)
    let can_back    = $derived(nav_pos > 0)
    let can_forward = $derived(nav_pos < nav_hist.length - 1)

    // Reset history on doc switch — offsets only make sense in their original doc.
    let _last_path = ''
    $effect(() => {
        if (active_path !== _last_path) {
            nav_hist = []
            nav_pos  = -1
            _last_path = active_path
        }
    })

    // ── data sources ─────────────────────────────────────────────────────────
    //   docC:      the ave/{lang_doc:path} particle (text only; Compile lives on lang_docC).
    //   lang_docC: the w:Lang side {doc:path} particle (holds %Pmirrors,1).
    //   H.ave.ob() makes ave-version-bumps wake the $effect below.  The %active_doc,1
    //   particle is shared across paths and bump_version()s on doc switches, so
    //   we void-read sig.version to register that as a dep too.
    let docC: TheC | undefined = $state()
    let lang_docC: TheC | undefined = $state()
    $effect(() => {
        docC = active_path
            ? H.ave.ob({ lang_doc: active_path })[0] as TheC | undefined
            : undefined
        const sig = H.ave.ob({ active_doc: 1 })[0] as TheC | undefined
        void sig?.version
        lang_docC = (sig?.sc.path === active_path)
            ? sig?.c.doc as TheC | undefined
            : undefined
    })

    let total_lines = $derived.by(() => {
        void docC?.version
        const text = (docC?.sc.text as string) ?? ''
        if (!text) return 1
        let n = 1
        for (const ch of text) if (ch === '\n') n++
        return n
    })

    // ── throttled rebuild ─────────────────────────────────────────────────────
    //
    //   _structure is $state so Svelte never auto-tracks its internal reads.
    //   The $effect below registers reactive deps with cheap void-reads, then
    //   delegates to schedule_rebuild().  Any number of version-bumps that land
    //   within one animation frame collapse to a single rebuild() call.
    //
    //   This eliminates the console spam from the points=0 / points=1 oscillation
    //   that occurred when docC.version bounced twice during Point resolution.

    let _raf = 0

    let _structure: {
        regions:          Region[]
        top_level_defs:   Def[]
        top_level_points: PointMark[]
    } = $state({ regions: [], top_level_defs: [], top_level_points: [] })

    let regions          = $derived(_structure.regions)
    let top_level_defs   = $derived(_structure.top_level_defs)
    let top_level_points = $derived(_structure.top_level_points)

    function schedule_rebuild() {
        cancelAnimationFrame(_raf)
        _raf = requestAnimationFrame(() => { _raf = 0; rebuild() })
    }

    // Subscribe to the deps that should trigger a rebuild.
    // void-reads register the dependency without doing any work here.
    $effect(() => {
        void docC?.version
        void lang_docC?.version
        void active_path
        schedule_rebuild()
    })

    function rebuild() {
        if (!docC) {
            _structure = { regions: [], top_level_defs: [], top_level_points: [] }
            return
        }

        // Compile output lives on the Lang-side lang_docC, not the ave text particle
        const job     = lang_docC?.o({ Compile: 1 })[0]    as TheC | undefined
        const output  = job?.o({ Output: 1 })[0]           as TheC | undefined
        const methods = output?.o({ methods: 1 })[0]       as TheC | undefined

        // Collect Point marks from Pmirrors maintained by LangGraft.
        // No resolution work happens here — just reading pre-baked positions.
        const point_marks = collect_graft_marks()

        if (methods) {
            const region_entries = methods.o({ region: 1 }) as TheC[]
            const def_entries    = methods.o({ def:    1 }) as TheC[]

            const list: Region[] = region_entries.map(r => ({
                label:     r.sc.label as string,
                depth:     r.sc.depth as number,
                from_line: r.sc.line  as number,
                to_line:   total_lines,
                from_char: r.sc.from  as number,
                to_char:   r.sc.to    as number,
                defs:      [],
                points:    [],
            }))

            const text = (docC.sc.text as string) ?? ''
            patch_region_extents(list, text, total_lines)

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

            const top_points: PointMark[] = []
            for (const mark of point_marks) {
                const owner = innermost_region_for_line(list, mark.line)
                if (owner) owner.points.push(mark)
                else top_points.push(mark)
            }

            const unres  = point_marks.filter(p => p.unresolved).length
            const summary = `${list.length}r ${def_entries.length}d ${point_marks.length}p`
            if (summary !== last_log_summary) {
                console.log(`🗺 minimap rebuild ${active_path}: regions=${list.length} defs=${def_entries.length} points=${point_marks.length} unresolved=${unres}`)
                last_log_summary = summary
            }
            _structure = { regions: list, top_level_defs: top_defs, top_level_points: top_points }
            return
        }

        // Fallback: no compile index yet.  Scan regions directly from text;
        // surface any Points as unresolved (they'll cluster at line 1 in red).
        const fallback_regions    = scan_regions_from_text((docC.sc.text as string) ?? '')
        const fallback_top_points: PointMark[] = point_marks.map(p =>
            p.unresolved ? p : { ...p, line: 1, from: 0, to: 0, unresolved: true }
        )

        const summary = `${fallback_regions.length}r 0d ${point_marks.length}p (no compile)`
        if (summary !== last_log_summary) {
            console.log(`🗺 minimap rebuild ${active_path} (no compile yet): regions=${fallback_regions.length} points=${point_marks.length} (all unresolved)`)
            last_log_summary = summary
        }
        _structure = {
            regions:          fallback_regions,
            top_level_defs:   [],
            top_level_points: fallback_top_points,
        }
    }

    // ── collect_graft_marks ──────────────────────────────────────────────────
    //
    //   Walk the active doc's %Pmirrors,1 / %Pmirror,N — each one mirrors a
    //   Point in the cursored Something.  A Pmirror with %graft,1 has been
    //   resolved (live position cached in graft sc); one without is
    //   unresolved (spec didn't match any def in current compile output, or
    //   has no resolvable spec field at all).
    //
    //   This replaces the old walk through lies_w.o({Waft:1}) — Pmirrors are
    //   the single source of truth for "Points belonging to this doc right
    //   now", maintained by LangGraft.
    function collect_graft_marks(): PointMark[] {
        const out: PointMark[] = []
        if (!lang_docC) return out

        const Pmirrors = lang_docC.o({ Pmirrors: 1 })[0] as TheC | undefined
        if (!Pmirrors) return out

        for (const pm of Pmirrors.o({ Pmirror: 1 }) as TheC[]) {
            const spec = (pm.sc.spec as string) || ''
            if (!spec) continue
            const graft = pm.o({ graft: 1 })[0] as TheC | undefined
            if (!graft) {
                out.push({ spec, method: spec, line: 1, from: 0, to: 0, unresolved: true })
                continue
            }
            out.push({
                spec,
                method:     spec,
                line:       graft.sc.line as number,
                from:       graft.sc.from as number,
                to:         graft.sc.to   as number,
                unresolved: false,
            })
        }
        return out
    }

    // ── helpers ──────────────────────────────────────────────────────────────

    // Scan doc text directly for //#region / //#endregion when no compiled
    // index is available yet.  Mirrors LangRegions/Lang_build_regions but
    // doesn't need an EditorState.
    function scan_regions_from_text(text: string): Region[] {
        const REGION_RE    = /^[\t ]*\/\/#region\s+(.+)$/
        const ENDREGION_RE = /^[\t ]*\/\/#endregion\b/
        const lines = text.split('\n')

        const all:   Region[] = []
        const stack: Region[] = []
        let char_offset = 0

        for (let i = 0; i < lines.length; i++) {
            const line_text = lines[i]
            const line_num  = i + 1
            const line_from = char_offset
            const line_to   = char_offset + line_text.length

            const m = line_text.match(REGION_RE)
            if (m) {
                const depth = stack.length
                while (stack.length > depth) {
                    const closing   = stack.pop()!
                    closing.to_line = line_num - 1
                    closing.to_char = line_from
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

        const sorted = [...list].sort((a, b) => a.from_line - b.from_line)
        const stack: Region[] = []
        let next = 0
        let char_offset = 0

        for (let i = 0; i < lines.length; i++) {
            const line_num = i + 1
            const line_to  = char_offset + lines[i].length

            while (next < sorted.length && sorted[next].from_line === line_num) {
                while (stack.length && stack[stack.length - 1].depth >= sorted[next].depth) {
                    const closing = stack.pop()!
                    if (closing.to_line === total) {
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
        let winner: Region | undefined
        for (const r of list) {
            if (line >= r.from_line && line <= r.to_line) {
                if (!winner || r.depth >= winner.depth) winner = r
            }
        }
        return winner
    }

    // ── interactions ─────────────────────────────────────────────────────────

    // Scroll CM to a doc-char offset and place the cursor there.
    // Uses EditorView.scrollIntoView as a StateEffect (more reliable than the
    // boolean scrollIntoView:true on TransactionSpec, which only scrolls the
    // cm-scroller and not outer overflow ancestors).
    function go_to(from: number, to: number, label: string) {
        console.log(`🗺 minimap go_to('${label}' [${from}..${to}]): view=${view ? 'OK' : 'UNDEFINED'} active_path=${active_path}`)
        if (!view) return
        view.dispatch({
            selection: { anchor: from, head: to },
            effects: EditorView.scrollIntoView(from, { y: 'center' }),
        })
        view.focus()

        // Truncate any forward history then append (classic browser-style).
        const truncated = nav_hist.slice(0, nav_pos + 1)
        truncated.push({ path: active_path, from, to, label })
        nav_hist = truncated
        nav_pos  = truncated.length - 1
    }

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
        const key  = `${region.from_line}:${region.label}`
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
        const state       = view.state
        const header_line = state.doc.line(region.from_line)
        const fold_from   = header_line.to
        const fold_to     = Math.min(region.to_char, state.doc.length)
        if (fold_from >= fold_to) return

        // foldedRanges() returns the RangeSet CM maintains internally.
        // Walk it to check if any fold already covers our range.
        const folds = foldedRanges(state)
        let is_folded = false
        const cursor  = folds.iter()
        while (cursor.value !== null) {
            if (cursor.from <= fold_from && cursor.to >= fold_to) {
                is_folded = true
                break
            }
            cursor.next()
        }

        view.dispatch({
            effects: is_folded
                ? unfoldEffect.of({ from: fold_from, to: fold_to })
                : foldEffect.of({ from: fold_from, to: fold_to })
        })
    }

    // ── layout maths ─────────────────────────────────────────────────────────
    //   y-coords are percentages of the strip height.  A region spanning lines
    //   [a..b] of total N takes y = ((a-1)/N * 100)% to (b/N * 100)%.

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

<div class="lmm">
    <div class="lmm-head">
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
             Depth shrinks font-size and dims color so nesting reads visually. -->
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
                <!-- Points: Pmirror-resolved markers, always-visible label.
                     Higher z-index so they sit above stripes and region rows.
                     Warning style when unresolved (Pmirror has no %graft,1 — pre-compile, or spec didn't match a def). -->
                {#each r.points as p (p.spec)}
                    <button class="lmm-point" class:lmm-point-bad={p.unresolved}
                            style="top: {band_top(p.line)}; left: {r.depth * 5 + 4}px;"
                            title="{p.spec}{p.unresolved ? ' (unresolved)' : ''} → line {p.line}"
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

        <!-- Top-level Points — graft-resolved markers not inside any region. -->
        {#each top_level_points as p (p.spec)}
            <button class="lmm-point" class:lmm-point-bad={p.unresolved}
                    style="top: {band_top(p.line)}; left: 4px;"
                    title="{p.spec}{p.unresolved ? ' (unresolved)' : ''} → line {p.line}"
                    onclick={() => go_to(p.from, p.to, p.method)}>
                <span class="lmm-point-dot"></span>
                <span class="lmm-point-label">{p.method}</span>
            </button>
        {/each}

        <!-- Top-level defs (not inside any region) — warmer tick color. -->
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

<style>
    .lmm {
        position: absolute; top: 0; right: 0; bottom: 0;
        /* anchored to lte-mm-host (position:absolute), which is the containing block */
        width: 100%;    /* host controls width via --lte-minimap-w */
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
    .lmm-nav {
        background: none; border: none; cursor: pointer;
        color: #6a8a9a; padding: 0 3px; font-size: 12px; line-height: 1;
        font-family: inherit;
    }
    .lmm-nav:hover:not(:disabled) { color: #c0d0e0; }
    .lmm-nav:disabled { color: #2a3a45; cursor: default; }
    .lmm-title {
        color: #678; font-size: 10px;
        flex: 1; min-width: 0;
        overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
    }

    /* Strip surface holds three layers, all absolute-positioned within it:
         .lmm-stripe — colored bands sized by region line span (z-index 0)
         .lmm-row    — region label rows at each region's top line (z-index 2)
         .lmm-def    — method ticks at each def's line (z-index 1)
       overflow:hidden on the strip itself. */
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

    /* Region label row — fixed height, positioned at the region's top line. */
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

    /* Method def — tick + hover label.  Label fades in on hover and is
       allowed to extend beyond the strip edge. */
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

    /* Top-level defs (no enclosing region) get a warmer tick color. */
    .lmm-def-top .lmm-def-tick { background: rgba(220, 200, 140, 0.45); }
    .lmm-def-top:hover .lmm-def-tick { background: rgba(220, 200, 140, 0.95); }

    /* Points — graft-resolved markers, always-visible label, sit above defs.
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

    /* Unresolved Point (Pmirror with no %graft,1) — warning red, strikethrough. */
    .lmm-point-bad .lmm-point-dot { background: #e06c75; }
    .lmm-point-bad .lmm-point-label {
        color: #e06c75; text-decoration: line-through;
    }
</style>
