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
    import type { EditorView } from "@codemirror/view"
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
    }
    type Def = { method: string, line: number, from: number, to: number }

    let { H, view, active_path }: {
        H:           House
        view:        EditorView | undefined
        active_path: string
    } = $props()

    // Visibility toggle — collapsible strip.  Persisted only in module memory
    // for now (no Stuff sc storage); flip with the chevron on the strip header.
    let visible = $state(true)

    // Per-region collapsed state for the strip's own UI (independent of CM folds).
    // Keyed by `${from_line}:${label}` so re-orderings don't bleed state.
    let collapsed = $state(new Map<string, boolean>())

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

    // Pull regions and defs from the compiled methods index.  When no index
    // exists yet we fall back to a live regex scan so the strip still shows
    // structure on first paint.  controlflow entries are not surfaced here
    // (too dense for an overview); they remain available to Lang_resolve_point.
    //
    // Both `regions` and `top_level_defs` are produced by one $derived so the
    // bucket logic can mutate the region's defs[] without crossing into a
    // separate $effect.  The .by callback returns both via a single object.
    let _structure = $derived.by((): { regions: Region[], top_level_defs: Def[] } => {
        void docC?.version
        if (!docC) return { regions: [], top_level_defs: [] }

        const job     = docC.o({ Compile: 1 })[0]    as TheC | undefined
        const output  = job?.o({ Output: 1 })[0]     as TheC | undefined
        const methods = output?.o({ methods: 1 })[0] as TheC | undefined

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
            }))

            // Patch to_line / to_char by scanning forward in the doc for
            // //#endregion or the next region at <= depth.  The compiler
            // doesn't currently emit close offsets per-region, so we do it here.
            const text = (docC.sc.text as string) ?? ''
            patch_region_extents(list, text, total_lines)

            // Bucket defs into their containing region (innermost wins).
            const top: Def[] = []
            for (const d of def_entries) {
                const def: Def = {
                    method: d.sc.method as string,
                    line:   d.sc.line   as number,
                    from:   d.sc.from   as number,
                    to:     d.sc.to     as number,
                }
                const owner = innermost_region_for_line(list, def.line)
                if (owner) owner.defs.push(def)
                else top.push(def)
            }
            return { regions: list, top_level_defs: top }
        }

        // Fallback: regex-scan doc text directly.  No def info in this branch
        // — defs come from the compile step only.
        return {
            regions:        scan_regions_from_text((docC.sc.text as string) ?? ''),
            top_level_defs: [],
        }
    })

    let regions        = $derived(_structure.regions)
    let top_level_defs = $derived(_structure.top_level_defs)

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

    // Scroll CM to a doc-char offset and place the cursor there.
    function go_to(from: number, to: number) {
        if (!view) return
        view.dispatch({
            selection: { anchor: from, head: to },
            scrollIntoView: true,
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
    <div class="lmm-head" title="Toggle minimap">
        <button class="lmm-toggle" onclick={() => visible = false} aria-label="Hide minimap">‹</button>
        <span class="lmm-title">{regions.length} region{regions.length === 1 ? '' : 's'}</span>
    </div>

    <div class="lmm-strip">
        <!-- top-level defs (defs not inside any region) — rendered as ticks
             positioned by line, shown above the bands so they don't visually
             collide with region headings. -->
        {#each top_level_defs as d (d.from)}
            <button class="lmm-def lmm-def-top"
                    style="top: {band_top(d.line)}"
                    title="{d.method} (line {d.line})"
                    onclick={() => go_to(d.from, d.to)}>
                <span class="lmm-def-label">{d.method}</span>
            </button>
        {/each}

        <!-- region bands — rendered in source order; depth controls left inset
             so nested bands appear stacked rightward. -->
        {#each regions as r (r.from_line + ':' + r.label)}
            <div class="lmm-band"
                 style="top: {band_top(r.from_line)};
                        height: {band_height(r.from_line, r.to_line)};
                        left: {r.depth * 6}px;
                        background: {band_color(r.depth)};
                        border-left: 2px solid {band_border(r.depth)};">
                <div class="lmm-band-head">
                    <button class="lmm-chev"
                            onclick={() => toggle_collapse(r)}
                            aria-label="Toggle band">{is_collapsed(r) ? '▸' : '▾'}</button>
                    <button class="lmm-label"
                            onclick={() => go_to(r.from_char, r.from_char)}
                            title="line {r.from_line}–{r.to_line}">{r.label}</button>
                    <button class="lmm-fold"
                            onclick={() => toggle_fold(r)}
                            title="Fold/unfold in editor">⌐</button>
                </div>
                {#if !is_collapsed(r)}
                    {#each r.defs as d (d.from)}
                        <button class="lmm-def"
                                style="top: {band_top(d.line)}"
                                title="{d.method} (line {d.line})"
                                onclick={() => go_to(d.from, d.to)}>
                            <span class="lmm-def-label">{d.method}</span>
                        </button>
                    {/each}
                {/if}
            </div>
        {/each}
    </div>
</div>
{:else}
    <button class="lmm-show" onclick={() => visible = true} aria-label="Show minimap">›</button>
{/if}

<style>
    .lmm {
        position: absolute; top: 0; right: 0; bottom: 0;
        width: 180px;
        display: flex; flex-direction: column;
        background: rgba(10, 10, 14, 0.82);
        border-left: 1px solid #1a1a1a;
        backdrop-filter: blur(4px);
        font-family: 'Berkeley Mono', 'Fira Code', ui-monospace, monospace;
        font-size: 10px; color: #aab;
        z-index: 10;
        pointer-events: auto;
    }
    .lmm-head {
        display: flex; align-items: center; gap: 6px;
        padding: 3px 6px; background: rgba(0, 0, 0, 0.3);
        border-bottom: 1px solid #1a1a1a;
        flex-shrink: 0;
    }
    .lmm-toggle, .lmm-show {
        background: none; border: none; color: #6a8a9a; cursor: pointer;
        font-size: 13px; padding: 0 4px; line-height: 1;
    }
    .lmm-show {
        position: absolute; top: 24px; right: 0;
        background: rgba(10, 10, 14, 0.7);
        border: 1px solid #1a1a1a; border-right: none;
        border-radius: 3px 0 0 3px;
        padding: 4px 6px;
        z-index: 10;
    }
    .lmm-title { color: #556; font-size: 9px; }
    .lmm-strip {
        position: relative;
        flex: 1;
        overflow: hidden;
    }
    /* Region band — absolute-positioned vertical block over the strip. */
    .lmm-band {
        position: absolute; right: 0; left: 0;
        border-top: 1px solid;          /* color set inline per depth */
        border-top-color: inherit;
        min-height: 14px;
    }
    .lmm-band-head {
        display: flex; align-items: center; gap: 2px;
        padding: 1px 4px;
        font-size: 10px;
        background: rgba(0, 0, 0, 0.4);
        position: sticky; top: 0; z-index: 1;
    }
    .lmm-chev, .lmm-fold {
        background: none; border: none; color: #6a8a9a;
        cursor: pointer; padding: 0 2px; font-size: 10px; line-height: 1;
    }
    .lmm-fold { color: #4a5a6a; }
    .lmm-label {
        background: none; border: none; cursor: pointer;
        color: #c0d0e0; padding: 0; flex: 1; text-align: left;
        overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
        font-family: inherit; font-size: inherit;
    }
    .lmm-label:hover { color: #fff; }

    /* Method def tick — small clickable marker positioned by line within
       its parent (region band, or .lmm-strip for top-level). */
    .lmm-def {
        position: absolute; left: 2px; right: 2px; top: 0;
        height: 2px;
        background: rgba(180, 200, 220, 0.4);
        border: none; padding: 0; cursor: pointer;
        overflow: visible;
    }
    .lmm-def:hover { background: rgba(180, 200, 220, 0.9); height: 3px; }
    .lmm-def-label {
        position: absolute; left: 6px; top: -4px;
        font-size: 9px; color: #889;
        white-space: nowrap;
        opacity: 0;
        transition: opacity 0.1s;
        pointer-events: none;
    }
    .lmm-def:hover .lmm-def-label { opacity: 1; }
    .lmm-def-top {
        background: rgba(220, 200, 140, 0.4);
    }
    .lmm-def-top:hover { background: rgba(220, 200, 140, 0.9); }
</style>
