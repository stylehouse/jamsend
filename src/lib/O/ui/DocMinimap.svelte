<script lang="ts">
    // DocMinimap — floating overview strip for the active CM doc.
    //
    // ── Mount ────────────────────────────────────────────────────────────────
    //
    //   Mounted by Langui as a sibling of .lte-cm.  Receives:
    //     H    — the House
    //     view — the live EditorView (for scroll dispatch and viewport reads)
    //
    //   active_path is derived internally from Languinio/%dock,active:1.
    //
    // ── Data ─────────────────────────────────────────────────────────────────
    //
    //   Reads the compiled methods index that LangCompiling deposits at
    //     w:Lang/{docks}/{dock:path}/{Compile:1}/{methods:1}  (via lang_dock).
    //   %methods is a direct child of %Compile; %Output only appears for
    //   hard-compiled (gen_path) docs.  Soft compiles have no %Output.
    //
    //   Points (Pmirrors) are owned by NaviCado — not rendered in the region body.
    //   The region/def body (lmm-strip) shows only region headers and def chips.
    //
    // ── Scroll sync ──────────────────────────────────────────────────────────
    //
    //   _hovering: true while mouse is over the strip.
    //   _navigating: true for 200ms after go_to() — suppresses the scroll event
    //     our own CM dispatch fires before it can fight the new position.

    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { EditorView } from "@codemirror/view"
    import { foldEffect, unfoldEffect, foldedRanges } from "@codemirror/language"
    import NaviCado from "$lib/O/ui/NaviCado.svelte"

    type Region = {
        label:     string
        depth:     number
        from_line: number
        to_line:   number
        from_char: number
        to_char:   number
        defs:      Def[]
        // path: the open-region stack at this region, itself included as the last
        // element (the compiler stamps it on every %Map entry).  Two regions are
        // the same container iff their paths are equal|defs nest by exact match.
        path:      string[]
        // < points: PointMark[] lived here for capsule nav lookup — now in NaviCado
    }
    type Def = { method: string, class?: string, line: number, from: number, to: number, path: string[] }
    const path_key = (p: string[]) => (p ?? []).join('\u0000')

    let { H, view }: {
        H:    House
        view: EditorView | undefined
    } = $props()

    // Trace the view↔minimap wiring, but only when it actually flips — the
    // beliefs heartbeat re-runs this $effect every cycle and we don't want it
    // narrating an unchanged "EditorView OK" while just sitting there.
    let _view_wire_seen = ''
    $effect(() => {
        const wire = `${view ? 'EditorView OK' : 'undefined'} ${active_path}`
        if (wire === _view_wire_seen) return
        _view_wire_seen = wire
        console.log(`🗺 minimap view prop = ${view ? 'EditorView OK' : 'undefined'}, active_path = ${active_path}`)
    })

    let last_log_summary = ''
    let collapsed = $state(new Map<string, boolean>())

    // ── navigation history ────────────────────────────────────────────────────
    type NavEntry = { path: string, from: number, to: number, label: string }
    let nav_hist: NavEntry[] = $state([])
    let nav_pos               = $state(-1)
    let can_back    = $derived(nav_pos > 0)
    let can_forward = $derived(nav_pos < nav_hist.length - 1)

    // Advance the Lies cursor to the next Doc across all loaded Wafts.
    // < What-level navigation (sibling time-slices) is in NaviCado.

    // ── doc switch ────────────────────────────────────────────────────────────
    let _last_path = ''
    $effect(() => {
        if (active_path !== _last_path) {
            nav_hist = []
            nav_pos  = -1
            _last_path = active_path
        }
    })

    // ── scroll guards ─────────────────────────────────────────────────────────
    let _hovering   = false
    let _navigating = false
    let _nav_timer  = 0
    function on_wheel(e: WheelEvent) {
        if (!scroll_container_el) return
        e.preventDefault()   // don't let the page scroll under us
        scroll_container_el.scrollTop += e.deltaY
    }

    // ── scroll sync ───────────────────────────────────────────────────────────
    let strip_el: HTMLDivElement | undefined = $state()
    let scroll_container_el: HTMLDivElement | undefined = $state()

    function sync_scroll() {
        if (_hovering || _navigating) return
        if (!view || !strip_el || !scroll_container_el) return
        const cm_scroll  = view.scrollDOM
        const doc_h      = cm_scroll.scrollHeight
        const vp_h       = cm_scroll.clientHeight
        const scrollable = doc_h - vp_h
        if (scrollable <= 0) { scroll_container_el.scrollTop = 0; return }
        const frac       = Math.min(cm_scroll.scrollTop / scrollable, 1)
        const map_h      = strip_el.scrollHeight
        const map_vp     = scroll_container_el.clientHeight
        const map_scroll = map_h - map_vp
        if (map_scroll <= 0) { scroll_container_el.scrollTop = 0; return }
        scroll_container_el.scrollTop = frac * map_scroll
    }

    $effect(() => {
        if (!view) return
        const cm_scroll = view.scrollDOM
        cm_scroll.addEventListener('scroll', sync_scroll, { passive: true })
        return () => cm_scroll.removeEventListener('scroll', sync_scroll)
    })

    // CM mounts its search / find toolbar as .cm-panels-bottom inside the editor;
    // it overlays the strip's foot since the minimap is an absolute sibling, not
    // a CM panel.  Measure the bottom panel stack and inset the strip above it so
    // nothing is hidden.  No panel → inset 0 → flush to the bottom as before.
    let _bottom_inset = $state(0)
    $effect(() => {
        if (!view) { _bottom_inset = 0; return }
        const root = view.dom
        const measure = () => {
            const panel = root.querySelector('.cm-panels-bottom') as HTMLElement | null
            const h = panel ? panel.offsetHeight : 0
            if (h !== _bottom_inset) _bottom_inset = h
        }
        measure()
        // panels appear|vanish via DOM mutation; their height can also reflow
        const mo = new MutationObserver(measure)
        mo.observe(root, { childList: true, subtree: true })
        const ro = new ResizeObserver(measure)
        ro.observe(root)
        return () => { mo.disconnect(); ro.disconnect() }
    })

    $effect(() => {
        void _structure
        requestAnimationFrame(sync_scroll)
    })

    // ── data sources ──────────────────────────────────────────────────────────
    //   lang_dock: the %Dock particle from Languinio — carries Compile, Pmirrors,
    //   sc.text, and everything else.  The old `dock` read from ave.ob({lang_dock:path})
    //   which is no longer set; lang_dock via languinio.ob({dock:path}) is the one path.
    let lang_dock: TheC | undefined = $state()
    $effect(() => {
        lang_dock = active_path
            ? languinio?.ob({ dock: active_path })[0] as TheC | undefined
            : undefined
    })

    // ── NaviCado / LE ─────────────────────────────────────────────────────────
    //   %Languinio is the same ave signal Langui reads; DocMinimap only cares
    //   about the grafted phase (gold) and stale phase (amber) spinners.
    //   active_path, LE, lang_dock are all derived by NaviCado from languinio
    //   directly — DocMinimap derives them here only for its own data sources.
    let languinio: TheC | undefined = $state()
    $effect(() => {
        languinio = H.ave.ob({ Languinio: 1 })[0] as TheC | undefined
    })
    // active_path: which dock is foregrounded.
    // %Languinio/%dock,path with active:1 carries sc.dock = the path string.
    let active_path = $derived(
        (languinio?.ob({ active: 1 })[0]?.sc.dock as string | undefined) ?? ''
    )
    // ── spinners — the %Languinio in-flight set ───────────────────────────────
    //   Each {spinner:$name} particle under %Languinio is one indicator; this
    //   renders them ALL, so a new phase spinner (Langspinner) shows up here with
    //   zero UI work.  Known names keep their colours via .lmm-spin-$name rules;
    //   unknown names fall back to the default grey.
    //   333ms floor on the graft spinner so a fast graft doesn't strobe a frame.
    let _graft_spin = $state(false)
    let _stale_spin = $state(false)
    let _spinners: string[] = $state([])
    $effect(() => {
        void languinio?.vers
        const grafting = !!languinio?.ob({ spinner: 'grafted' }).length
        if (grafting) { _graft_spin = true }
        else          { setTimeout(() => { _graft_spin = false }, 333) }
        _stale_spin = !!languinio?.ob({ spinner: 'stale' }).length
        // everything else, generically — grafted|stale keep their bespoke spots.
        _spinners = ((languinio?.ob({ spinner: 1 }) ?? []) as TheC[])
            .map(s => s.sc.spinner as string)
            .filter(name => name !== 'grafted' && name !== 'stale')
    })

    let total_lines = $derived.by(() => {
        void lang_dock?.version
        const text = (lang_dock?.c.text as string) ?? ''
        if (!text) return 1
        let n = 1
        for (const ch of text) if (ch === '\n') n++
        return n
    })



    // ── throttled rebuild ─────────────────────────────────────────────────────
    let _raf = 0

    let _structure: {
        regions:        Region[]
        top_level_defs: Def[]
    } = $state({ regions: [], top_level_defs: [] })

    let regions        = $derived(_structure.regions)
    let top_level_defs = $derived(_structure.top_level_defs)

    function schedule_rebuild() {
        cancelAnimationFrame(_raf)
        _raf = requestAnimationFrame(() => { _raf = 0; rebuild() })
    }

    $effect(() => {
        void lang_dock?.vers
        void active_path
        schedule_rebuild()
    })

    function rebuild() {
        if (!lang_dock) {
            _structure = { regions: [], top_level_defs: [] }
            return
        }

        // Compile output and sc.text both live on lang_dock (%Dock from Languinio).
        // %Map is a direct child of %Compile regardless of whether %Output exists.
        // %Output is only present for hard-compiled gen_path docs.
        const job   = lang_dock.o({ Compile: 1 })[0]  as TheC | undefined
        const Map_C = job?.o({ Map: 1 })[0]           as TheC | undefined

        if (Map_C) {
            const region_entries = Map_C.o({ region: 1 }) as TheC[]
            const def_entries    = Map_C.o({ def:    1 }) as TheC[]

            const list: Region[] = region_entries.map(r => ({
                label:     r.sc.label as string,
                depth:     r.sc.depth as number,
                from_line: r.sc.line  as number,
                to_line:   total_lines,
                from_char: r.sc.from  as number,
                to_char:   r.sc.to    as number,
                defs:      [],
                path:      (r.c.region_path as string[] | undefined) ?? [],
            }))

            const text = (lang_dock.c.text as string) ?? ''

            // De-facto head region: the span before the first //#region is a
            // region in its own right (the file head — <script…> and the bare
            // top-level methods), so it gets a band like everything else instead
            // of floating above the structure.  patch_region_extents closes it at
            // the first real region.  Labelled by the first non-blank line.
            const first_real = list.reduce((m, r) => Math.min(m, r.from_line), Infinity)
            let defacto: Region | undefined
            if (first_real > 1) {
                const head = (text.split('\n').find(l => l.trim()) ?? 'head').trim().slice(0, 40)
                defacto = {
                    label: head, depth: 0, from_line: 1, to_line: total_lines,
                    from_char: 0, to_char: text.length, defs: [], path: [head],
                }
                list.unshift(defacto)
            }

            patch_region_extents(list, text, total_lines)

            // index regions by their exact path for O(1) def nesting.  region_path
            // is the compiler's authoritative containment record (a def's path
            // equals its direct region's path), so this needs no text geometry.
            const by_path = new Map<string, Region>()
            for (const r of list) by_path.set(path_key(r.path), r)

            const top_defs: Def[] = []
            for (const d of def_entries) {
                const def: Def = {
                    method: d.sc.method as string,
                    class:  d.sc.class  as string | undefined,
                    line:   d.sc.line   as number,
                    from:   d.sc.from   as number,
                    to:     d.sc.to     as number,
                    path:   (d.c.region_path as string[] | undefined) ?? [],
                }
                // path-bearing defs match their region exactly (line geometry is
                // the fallback for older path-less compiles).  A path-less def in
                // the head falls into the de-facto region|otherwise it is genuinely
                // top-level (a rare def sitting after the last region).
                const owner = def.path.length
                    ? (by_path.get(path_key(def.path)) ?? innermost_region_for_line(list, def.line))
                    : (defacto && def.line <= defacto.to_line
                        ? defacto
                        : innermost_region_for_line(list, def.line))
                if (owner) owner.defs.push(def)
                else top_defs.push(def)
            }

            const summary = `${list.length}r ${def_entries.length}d`
            if (summary !== last_log_summary) {
                console.log(`🗺 minimap rebuild ${active_path}: regions=${list.length} defs=${def_entries.length}`)
                last_log_summary = summary
            }
            _structure = { regions: list, top_level_defs: top_defs }
            return
        }

        // Fallback: no compile index yet.  Scan regions from text.
        const fallback_regions = scan_regions_from_text((lang_dock.c.text as string) ?? '')
        const summary = `${fallback_regions.length}r 0d (no compile)`
        if (summary !== last_log_summary) {
            console.log(`🗺 minimap rebuild ${active_path} (no compile yet): regions=${fallback_regions.length}`)
            last_log_summary = summary
        }
        _structure = { regions: fallback_regions, top_level_defs: [] }
    }

    // ── helpers ───────────────────────────────────────────────────────────────

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
                    const c = stack.pop()!; c.to_line = line_num - 1; c.to_char = line_from
                }
                const r: Region = {
                    label: m[1].trim(), depth,
                    from_line: line_num, to_line: lines.length,
                    from_char: line_from, to_char: text.length,
                    defs: [],
                    path: [...stack.map(s => s.label), m[1].trim()],
                }
                all.push(r); stack.push(r)
            } else if (ENDREGION_RE.test(line_text) && stack.length) {
                const c = stack.pop()!; c.to_line = line_num; c.to_char = line_to
            }
            char_offset = line_to + 1   // +1 for the \n we split on
        }
        return all
    }

    // Patch to_line / to_char on regions whose close was not recorded by the
    // compiler.
    function patch_region_extents(list: Region[], text: string, total: number) {
        if (!list.length) return
        const ENDREGION_RE = /^[\t ]*\/\/#endregion\b/
        const lines  = text.split('\n')
        const sorted = [...list].sort((a, b) => a.from_line - b.from_line)
        const stack: Region[] = []
        let next = 0, char_offset = 0
        for (let i = 0; i < lines.length; i++) {
            const line_num = i + 1
            const line_to  = char_offset + lines[i].length
            while (next < sorted.length && sorted[next].from_line === line_num) {
                while (stack.length && stack[stack.length - 1].depth >= sorted[next].depth) {
                    const c = stack.pop()!
                    if (c.to_line === total) { c.to_line = line_num - 1; c.to_char = char_offset > 0 ? char_offset - 1 : 0 }
                }
                stack.push(sorted[next++])
            }
            if (ENDREGION_RE.test(lines[i]) && stack.length) {
                const c = stack.pop()!; c.to_line = line_num; c.to_char = line_to
            }
            char_offset = line_to + 1
        }
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

    // ── interactions ──────────────────────────────────────────────────────────

    // < ATTENTION LAYER (the lightest Point activity) — not built yet.
    //    A separate Waft layer recording where attention actually went, distinct
    //    from the structural %Points|its sources, lightest to heaviest:
    //      what line is visible on screen, where the cursor clicks around (a
    //      teacher tapping the board), a manual goto (this go_to), and certainly
    //      any edit.  Each lands a faint timestamped Point on the layer.
    //    The trail draws back as a heatmap streak careening over the MiniMap —
    //      pull up history and watch it move.  Edits batch against it so a session
    //      of changes replays as one pleasing sweep rather than scattered diffs.
    //    Manual gotos and edits weigh heaviest|mere on-screen visibility weighs
    //      least and decays.  All of it resolves through %Map by name, never by
    //      stored absolute offset — same crawl-to-method identity as %Points.

    function go_to(from: number, to: number, label: string) {
        _navigating = true
        clearTimeout(_nav_timer)
        _nav_timer = setTimeout(() => { _navigating = false }, 200) as any
        console.log(`🗺 minimap go_to('${label}' [${from}..${to}])`)
        if (!view) return
        view.dispatch({
            selection: { anchor: from, head: to },
            effects:   EditorView.scrollIntoView(from, { y: 'center' }),
        })
        view.focus()
        const truncated = nav_hist.slice(0, nav_pos + 1)
        truncated.push({ path: active_path, from, to, label })
        nav_hist = truncated
        nav_pos  = truncated.length - 1
    }

    function go_back() {
        if (!can_back || !view) return
        nav_pos = nav_pos - 1
        const e = nav_hist[nav_pos]
        view.dispatch({ selection: { anchor: e.from, head: e.to }, effects: EditorView.scrollIntoView(e.from, { y: 'center' }) })
        view.focus()
    }
    function go_forward() {
        if (!can_forward || !view) return
        nav_pos = nav_pos + 1
        const e = nav_hist[nav_pos]
        view.dispatch({ selection: { anchor: e.from, head: e.to }, effects: EditorView.scrollIntoView(e.from, { y: 'center' }) })
        view.focus()
    }

    function toggle_collapse(region: Region) {
        const key  = `${region.from_line}:${region.label}`
        const next = new Map(collapsed)
        next.set(key, !next.get(key))
        collapsed = next
    }
    function is_collapsed(region: Region): boolean {
        return collapsed.get(`${region.from_line}:${region.label}`) ?? false
    }

    // Fold / unfold this region in CM.  Body-only fold: header line stays
    // visible (matches Lang_apply_openness semantics).
    function toggle_fold(region: Region) {
        if (!view) return
        const state       = view.state
        const header_line = state.doc.line(region.from_line)
        const fold_from   = header_line.to
        const fold_to     = Math.min(region.to_char, state.doc.length)
        if (fold_from >= fold_to) return
        const folds = foldedRanges(state)
        let is_folded = false
        const cursor  = folds.iter()
        while (cursor.value !== null) {
            if (cursor.from === fold_from) { is_folded = true; break }
            cursor.next()
        }
        view.dispatch({
            effects: is_folded
                ? unfoldEffect.of({ from: fold_from, to: fold_to })
                : foldEffect.of({ from: fold_from, to: fold_to })
        })
    }

    // ── layout maths ─────────────────────────────────────────────────────────
    function band_color(depth: number): string {
        const hue = (210 + depth * 40) % 360
        return `hsla(${hue}, 50%, 50%, 0.18)`
    }
    function band_border(depth: number): string {
        const hue = (210 + depth * 40) % 360
        return `hsla(${hue}, 60%, 60%, 0.5)`
    }
</script>

<!-- _hovering suppresses scroll sync while user reads the strip.
     mouseleave also clears reset_confirm so it doesn't linger. -->
<div class="lmm"
     style="bottom: {_bottom_inset}px"
     onmouseenter={() => _hovering = true}
     onmouseleave={() => { _hovering = false }}
     onwheel={on_wheel}>

    <div class="lmm-head">
        <!-- nav history — only shown once there's something to navigate; before
             that, both buttons would just be disabled and the count reads fine alone. -->
        {#if nav_hist.length}
            <button class="lmm-nav" onclick={go_back}    disabled={!can_back}
                    title="Back"    aria-label="Back">◂</button>
            <button class="lmm-nav" onclick={go_forward} disabled={!can_forward}
                    title="Forward" aria-label="Forward">▸</button>
        {/if}
        {#if nav_pos >= 0}
            <span class="lmm-title" title={nav_hist[nav_pos].label}>{nav_hist[nav_pos].label}</span>
        {/if}
        {#each _spinners as name (name)}
            <span class="lmm-spin lmm-spin-{name}" title={name}>⟳</span>
        {/each}
        {#if _graft_spin}<span class="lmm-graft-spin" title="grafting Points">⟳</span>{/if}
        {#if _stale_spin}<span class="lmm-stale-spin" title="Understanding stale — remote moved">↻</span>{/if}
    </div>

    <NaviCado {H} />

    <div class="lmm-scroll" bind:this={scroll_container_el}>
        <div class="lmm-strip" bind:this={strip_el}>
            <!-- Flat two-column flow: region headers span both columns, def chips
                 pile between them in column-major order.  Points are NOT rendered
                 here — they live only in the capsule strip above. -->

            {#if top_level_defs.length}
                {@const half = Math.ceil(top_level_defs.length / 2)}
                <div class="lmm-def-col">
                    {#each top_level_defs.slice(0, half) as d (d.from)}
                        <button class="lmm-def-chip lmm-def-chip-top"
                                class:lmm-def-chip-class={!d.class}
                                title="{d.method} (line {d.line})"
                                onclick={() => go_to(d.from, d.to, d.method)}>{d.method}</button>
                    {/each}
                </div>
                <div class="lmm-def-col">
                    {#each top_level_defs.slice(half) as d (d.from)}
                        <button class="lmm-def-chip lmm-def-chip-top"
                                class:lmm-def-chip-class={!d.class}
                                title="{d.method} (line {d.line})"
                                onclick={() => go_to(d.from, d.to, d.method)}>{d.method}</button>
                    {/each}
                </div>
            {/if}

            {#each regions as r (r.from_line + ':' + r.label)}
                <div class="lmm-col-span lmm-row"
                     style="padding-left: {r.depth * 5 + 4}px;
                            font-size: {Math.max(11 - r.depth, 8)}px;
                            opacity: {Math.max(1 - r.depth * 0.12, 0.6)};
                            background: {band_color(r.depth)};
                            border-left: 3px solid {band_border(r.depth)};">
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

                {#if !is_collapsed(r) && r.defs.length}
                    {@const half = Math.ceil(r.defs.length / 2)}
                    <div class="lmm-def-col" style="padding-left: {r.depth * 5 + 4}px;">
                        {#each r.defs.slice(0, half) as d (d.from)}
                            <button class="lmm-def-chip"
                                    class:lmm-def-chip-class={!d.class}
                                    title="{d.method} (line {d.line})"
                                    onclick={() => go_to(d.from, d.to, d.method)}>{d.method}</button>
                        {/each}
                    </div>
                    <div class="lmm-def-col" style="padding-left: 2px;">
                        {#each r.defs.slice(half) as d (d.from)}
                            <button class="lmm-def-chip"
                                    class:lmm-def-chip-class={!d.class}
                                    title="{d.method} (line {d.line})"
                                    onclick={() => go_to(d.from, d.to, d.method)}>{d.method}</button>
                        {/each}
                    </div>
                {/if}
            {/each}
        </div>
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
    /* grafted-phase spinner — gold, parallel to Langui's blue/amber spinners */
    .lmm-graft-spin {
        color: rgb(180, 160, 40);
        font-size: 12px; line-height: 1;
        flex-shrink: 0;
        display: inline-block;
        animation: lmm-graft-spin 0.3s linear infinite;
    }
    @keyframes lmm-graft-spin { to { transform: rotate(360deg); } }

    /* generic phase spinners — one per %Languinio/{spinner:$name}.
       Default grey; named tints below for the phases we know about. */
    .lmm-spin {
        color: rgb(110, 125, 140);
        font-size: 12px; line-height: 1;
        flex-shrink: 0;
        display: inline-block;
        animation: lmm-graft-spin 0.5s linear infinite;
    }
    .lmm-spin-furnish   { color: rgb(90, 150, 200); }   /* dock content in flight */
    .lmm-spin-text_load { color: rgb(90, 170, 170); }   /* waiting on CM mount */
    .lmm-spin-compile   { color: rgb(150, 130, 200); }  /* methods index building */

    /* stale-phase spinner — amber; Understanding remote has drifted */
    .lmm-stale-spin {
        color: rgb(200, 120, 40);
        font-size: 12px; line-height: 1;
        flex-shrink: 0;
        display: inline-block;
        animation: lmm-stale-spin 0.8s linear infinite;
    }
    @keyframes lmm-stale-spin { to { transform: rotate(360deg); } }

    /* Strip:
         .lmm-scroll     — overflow:hidden scroll container (invisible bar)
         .lmm-strip      — two-column grid; all children are direct grid items
         .lmm-col-span   — full-width row (region headers)
         .lmm-def-col    — one half of a method pair */
    .lmm-scroll {
        flex: 1;
        overflow: hidden;        /* bar invisible; JS drives scrollTop */
        position: relative;
    }
    .lmm-strip {
        display: grid;
        grid-template-columns: 1fr 1fr;
        align-items: start;
        min-height: 100%;
    }
    .lmm-col-span { grid-column: 1 / -1; }

    .lmm-stripe { display: none; }
    .lmm-region-block { display: contents; }

    .lmm-row {
        display: flex; align-items: center; gap: 2px;
        height: 16px;
        background: rgba(0, 0, 0, 0.55);
        border-top: 1px solid rgba(120, 140, 170, 0.25);
        padding-right: 4px;
        white-space: nowrap;
    }

    .lmm-chev, .lmm-fold {
        background: none; border: none; color: #6a8a9a;
        cursor: pointer; padding: 0 3px; line-height: 1;
        font-size: 10px; font-family: inherit; flex-shrink: 0;
    }
    .lmm-chev:hover, .lmm-fold:hover { color: #c0d0e0; }
    .lmm-fold { color: #4a5a6a; font-style: italic; }

    .lmm-label {
        background: none; border: none; cursor: pointer;
        color: #c0d0e0; padding: 0; flex: 1; text-align: left;
        overflow: hidden; text-overflow: ellipsis;
        font-family: inherit; font-size: inherit; line-height: 1.2;
    }
    .lmm-label:hover { color: #fff; }

    .lmm-def-col {
        display: flex; flex-direction: column;
        min-width: 0;
        background: rgba(0, 0, 0, 0.18);
        padding: 1px 2px 2px;
    }

    .lmm-def-pile { display: contents; }

    .lmm-def-chip {
        background: none; border: none; cursor: pointer;
        font-size: 8px; color: rgba(180, 200, 220, 0.45);
        padding: 0; white-space: nowrap;
        overflow: hidden; text-overflow: ellipsis;
        font-family: inherit; line-height: 1.4; text-align: left;
        transition: color 0.1s;
    }
    .lmm-def-chip:hover { color: #c0d0e0; }

    /* Class name def (no %class on sc — it IS the class): bold, brighter. */
    .lmm-def-chip-class       { color: rgba(220, 200, 255, 0.7); font-weight: bold; }
    .lmm-def-chip-class:hover { color: #e0d0ff; }

    /* Top-level chips — warmer tint. */
    .lmm-def-chip-top       { color: rgba(220, 200, 140, 0.45); }
    .lmm-def-chip-top:hover { color: #e5c07b; }
</style>
