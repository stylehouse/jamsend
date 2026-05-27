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
    // ── Data ─────────────────────────────────────────────────────────────────
    //
    //   Reads the compiled methods index that LangCompiling deposits at
    //     w:Lang/{docs}/{doc:path}/{Compile:1}/{methods:1}  (via lang_docC).
    //   %methods is a direct child of %Compile; %Output only appears for
    //   hard-compiled (gen_path) docs.  Soft compiles have no %Output.
    //
    //   Points come from %Pmirror,N under lang_docC/%Pmirrors,1.
    //   They are auto-promoted to in_group on first appearance (unless the user
    //   has explicitly demoted that spec this session via ×).  Auto-promotion
    //   sets pushed_snapshot to match so the bar doesn't appear until the user
    //   actually changes something.
    //
    //   Points are only rendered in the capsule strip — not strewn through the
    //   region body.  The region/def data still carries point positions so the
    //   capsule strip can navigate on click.
    //
    // ── In-group / showing ───────────────────────────────────────────────────
    //
    //   in_group — specs currently in the capsule strip (session only).
    //   showing  — subset of in_group whose fold/glow is active (session only).
    //
    //   Capsule orb = showing toggle (gold glow = showing; ring = dormant).
    //   × = demote: removes from in_group and marks spec in _user_demoted so
    //     auto-promote won't re-add it on the next rebuild.
    //
    //   "Not showing" excludes a spec from carry-forward on +time (future transport).
    //
    //   The unsent bar appears only once the user has changed something since
    //   the last push (or since auto-promote synced the snapshot).
    //   < Lies_accept_What_Point and Lies_cursor_next backend not yet written.
    //   < receive_what_point_from_lies needs a call site when Pmirror identity
    //     changes substantially (new What_Point replacing current from Lies).
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

    type Region = {
        label:     string
        depth:     number
        from_line: number
        to_line:   number
        from_char: number
        to_char:   number
        defs:      Def[]
        points:    PointMark[]   // < not rendered in body; kept for capsule nav lookup
    }
    type Def = { method: string, class?: string, line: number, from: number, to: number }

    // A Point becomes a PointMark once its graft fields have been stamped by
    // Lang_graft_points.  unresolved:true means LangGraft hasn't found the
    // method in the compile index yet (pre-compile, or name changed).
    type PointMark = {
        spec:       string
        method:     string
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

    let last_log_summary = ''
    let collapsed = $state(new Map<string, boolean>())

    // ── navigation history ────────────────────────────────────────────────────
    type NavEntry = { path: string, from: number, to: number, label: string }
    let nav_hist: NavEntry[] = $state([])
    let nav_pos               = $state(-1)
    let can_back    = $derived(nav_pos > 0)
    let can_forward = $derived(nav_pos < nav_hist.length - 1)

    // ── in-group + showing ────────────────────────────────────────────────────

    let in_group:        Set<string> = $state(new Set())
    let showing:         Set<string> = $state(new Set())
    // JSON of the in_group+showing state at last push (or auto-promote sync).
    // '' means nothing has been pushed/synced yet — bar stays hidden.
    let pushed_snapshot: string  = $state('')
    let reset_confirm:   boolean = $state(false)

    // Non-reactive tracking — reset on doc switch alongside the reactive state.
    let _auto_promoted: Set<string> = new Set()   // specs ever auto-promoted this session
    let _user_demoted:  Set<string> = new Set()   // specs user explicitly ×'d; never re-auto-promote

    function current_what_point_json(): string {
        const entries = [...in_group].map(spec => ({ spec, showing: showing.has(spec) }))
        return JSON.stringify(entries)
    }

    // Only show the unsent bar once the user has changed something from the
    // last auto-synced or pushed state.  Never show if nothing was ever synced.
    let is_dirty = $derived(pushed_snapshot !== '' && current_what_point_json() !== pushed_snapshot)

    // Demote: remove from in_group+showing and prevent future auto-promotion.
    function demote(spec: string) {
        _user_demoted.add(spec)
        const ig = new Set(in_group); ig.delete(spec)
        const sh = new Set(showing);  sh.delete(spec)
        in_group      = ig
        showing       = sh
        reset_confirm = false
    }

    // Toggle showing for an in-group spec (active ↔ dormant).
    // < should also fire i_elvisto to update fold/glow in CM for this spec.
    function toggle_showing(spec: string) {
        const sh = new Set(showing)
        if (sh.has(spec)) sh.delete(spec)
        else              sh.add(spec)
        showing       = sh
        reset_confirm = false
    }

    // Push current in_group+showing to Lies.
    // < Lies_accept_What_Point not yet written.
    function push_what_point() {
        const snap = current_what_point_json()
        H.i_elvisto('Lies/Lies', 'Lies_accept_What_Point', {
            doc_path:   active_path,
            what_point: JSON.parse(snap),
        })
        pushed_snapshot = snap
        reset_confirm   = false
    }

    // Revert local in_group+showing to the last pushed/synced state.
    // Two-tap: first tap arms; second tap executes.
    function reset_what_point() {
        if (!reset_confirm) { reset_confirm = true; return }
        if (pushed_snapshot) {
            const entries: { spec: string, showing: boolean }[] = JSON.parse(pushed_snapshot)
            in_group = new Set(entries.map(e => e.spec))
            showing  = new Set(entries.filter(e => e.showing).map(e => e.spec))
        } else {
            in_group = new Set()
            showing  = new Set()
        }
        reset_confirm = false
    }

    // Called when Lies sends a new What_Point replacing what Lang is working from.
    // Drops any unpushed local state and installs the Lies-side view.
    // < call site: when lang_docC Pmirror identity changes substantially.
    function receive_what_point_from_lies(entries: { spec: string, showing: boolean }[]) {
        _auto_promoted  = new Set(entries.map(e => e.spec))
        _user_demoted   = new Set()
        in_group        = new Set(entries.map(e => e.spec))
        showing         = new Set(entries.filter(e => e.showing).map(e => e.spec))
        pushed_snapshot = JSON.stringify(entries)
        reset_confirm   = false
    }

    // Advance the Lies cursor to the next What_Point.
    // < Lies_cursor_next not yet written.
    function cursor_next() {
        H.i_elvisto('Lies/Lies', 'Lies_cursor_next', { doc_path: active_path })
    }

    // ── doc switch ────────────────────────────────────────────────────────────
    let _last_path = ''
    $effect(() => {
        if (active_path !== _last_path) {
            nav_hist        = []
            nav_pos         = -1
            in_group        = new Set()
            showing         = new Set()
            pushed_snapshot = ''
            reset_confirm   = false
            _auto_promoted  = new Set()
            _user_demoted   = new Set()
            _last_path      = active_path
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

    $effect(() => {
        void _structure
        requestAnimationFrame(sync_scroll)
    })

    // ── data sources ──────────────────────────────────────────────────────────
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
    let _raf = 0

    let _structure: {
        regions:          Region[]
        top_level_defs:   Def[]
        all_marks:        PointMark[]   // flat list for capsule nav lookup
    } = $state({ regions: [], top_level_defs: [], all_marks: [] })

    let regions        = $derived(_structure.regions)
    let top_level_defs = $derived(_structure.top_level_defs)
    let all_marks      = $derived(_structure.all_marks)

    function schedule_rebuild() {
        cancelAnimationFrame(_raf)
        _raf = requestAnimationFrame(() => { _raf = 0; rebuild() })
    }

    $effect(() => {
        void docC?.version
        void lang_docC?.version
        void active_path
        schedule_rebuild()
    })

    function rebuild() {
        if (!docC) {
            _structure = { regions: [], top_level_defs: [], all_marks: [] }
            return
        }

        // Compile output lives on the Lang-side lang_docC, not the ave text particle.
        // %methods is a direct child of %Compile regardless of whether %Output exists.
        // %Output is only present for hard-compiled gen_path docs.
        const job     = lang_docC?.o({ Compile: 1 })[0]  as TheC | undefined
        const methods = job?.o({ methods: 1 })[0]        as TheC | undefined
        const point_marks = collect_graft_marks()

        // Auto-promote newly arrived specs into in_group + showing.
        // Skips specs the user has explicitly demoted this session.
        // After promotion, syncs pushed_snapshot so the bar doesn't appear yet.
        const auto_ig = new Set(in_group)
        const auto_sh = new Set(showing)
        let did_promote = false
        for (const mark of point_marks) {
            if (_user_demoted.has(mark.spec))  continue
            if (_auto_promoted.has(mark.spec)) continue
            _auto_promoted.add(mark.spec)
            auto_ig.add(mark.spec)
            auto_sh.add(mark.spec)
            did_promote = true
        }
        if (did_promote) {
            in_group = auto_ig
            showing  = auto_sh
            pushed_snapshot = JSON.stringify([...auto_ig].map(s => ({ spec: s, showing: auto_sh.has(s) })))
            reset_confirm   = false
        }

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
                    class:  d.sc.class  as string | undefined,
                    line:   d.sc.line   as number,
                    from:   d.sc.from   as number,
                    to:     d.sc.to     as number,
                }
                const owner = innermost_region_for_line(list, def.line)
                if (owner) owner.defs.push(def)
                else top_defs.push(def)
            }

            // Point marks are sorted into regions for position lookup only.
            for (const mark of point_marks) {
                const owner = innermost_region_for_line(list, mark.line)
                if (owner) owner.points.push(mark)
            }

            const unres   = point_marks.filter(p => p.unresolved).length
            const summary = `${list.length}r ${def_entries.length}d ${point_marks.length}p`
            if (summary !== last_log_summary) {
                console.log(`🗺 minimap rebuild ${active_path}: regions=${list.length} defs=${def_entries.length} points=${point_marks.length} unresolved=${unres}`)
                last_log_summary = summary
            }
            _structure = { regions: list, top_level_defs: top_defs, all_marks: point_marks }
            return
        }

        // Fallback: no compile index yet.  Scan regions from text.
        const fallback_regions = scan_regions_from_text((docC.sc.text as string) ?? '')
        const summary = `${fallback_regions.length}r 0d ${point_marks.length}p (no compile)`
        if (summary !== last_log_summary) {
            console.log(`🗺 minimap rebuild ${active_path} (no compile yet): regions=${fallback_regions.length} points=${point_marks.length}`)
            last_log_summary = summary
        }
        _structure = { regions: fallback_regions, top_level_defs: [], all_marks: point_marks }
    }

    // ── collect_graft_marks ───────────────────────────────────────────────────
    //
    //   Walk lang_docC/%Pmirrors,1/%Pmirror,N.  A Pmirror with %graft,1 has been
    //   resolved (live position from compile index); one without is unresolved.
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
                    defs: [], points: [],
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
     onmouseenter={() => _hovering = true}
     onmouseleave={() => { _hovering = false; reset_confirm = false }}
     onwheel={on_wheel}>

    <div class="lmm-head">
        <button class="lmm-nav" onclick={go_back}    disabled={!can_back}
                title="Back"    aria-label="Back">◂</button>
        <button class="lmm-nav" onclick={go_forward} disabled={!can_forward}
                title="Forward" aria-label="Forward">▸</button>
        <span class="lmm-title" title="{regions.length} region{regions.length === 1 ? '' : 's'}">
            {nav_pos >= 0 ? nav_hist[nav_pos].label : `${regions.length}r`}
        </span>
    </div>

    <!-- Unsent bar — only when user has changed something since last push. -->
    {#if is_dirty}
        <div class="lmm-wp-bar">
            <span class="lmm-wp-tilde">~</span>
            {#if !reset_confirm}
                <div class="lmm-wp-arrows">
                    <button class="lmm-wp-arrow" onclick={push_what_point} title="Push to Lies">↑</button>
                    <button class="lmm-wp-arrow" onclick={reset_what_point} title="Reset">↩</button>
                </div>
            {:else}
                <button class="lmm-wp-arrow lmm-wp-confirm" onclick={reset_what_point}>sure?</button>
            {/if}
        </div>
    {/if}

    <!-- In-group capsule strip.
         All Pmirrors auto-promote here on arrival.
         Orb = showing toggle.  × = demote (always visible). -->
    {#if in_group.size > 0}
        <div class="lmm-inbox">
            {#each [...in_group] as spec (spec)}
                {@const mark = all_marks.find(p => p.spec === spec)}
                {@const is_sh = showing.has(spec)}
                <div class="lmm-capsule"
                     class:lmm-capsule-bad={mark?.unresolved}
                     class:lmm-capsule-dormant={!is_sh}>
                    <button class="lmm-capsule-orb"
                            class:lmm-capsule-orb-show={is_sh}
                            title={is_sh ? 'Showing — click to make dormant' : 'Dormant — click to show'}
                            onclick={() => toggle_showing(spec)}>
                    </button>
                    <button class="lmm-capsule-label"
                            title="{spec}{mark?.unresolved ? ' (unresolved)' : mark ? ` → line ${mark.line}` : ''}"
                            onclick={() => mark && go_to(mark.from, mark.to, spec)}>
                        {spec}
                    </button>
                    {#if !is_sh}
                        <button class="lmm-capsule-demote" title="Remove Point" onclick={() => demote(spec)}>×</button>
                    {/if}
                </div>
            {/each}
            <!-- < Lies_cursor_next backend not yet wired. -->
            <button class="lmm-cursor-next" title="Next What_Point in Lies" onclick={cursor_next}>→</button>
        </div>
    {/if}

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

    /* Unsent bar — only when user changed something since last push. */
    .lmm-wp-bar {
        display: flex; flex-direction: column; align-items: center;
        padding: 3px 0 4px;
        background: rgba(229, 192, 123, 0.05);
        border-bottom: 1px solid rgba(229, 192, 123, 0.1);
        flex-shrink: 0; gap: 2px;
    }
    .lmm-wp-tilde {
        font-size: 17px; line-height: 1;
        color: rgba(229, 192, 123, 0.5);
    }
    .lmm-wp-arrows { display: flex; gap: 8px; }
    .lmm-wp-arrow {
        background: none; border: none; cursor: pointer;
        font-family: inherit; font-size: 13px; line-height: 1;
        color: rgba(229, 192, 123, 0.45); padding: 0 3px;
    }
    .lmm-wp-arrow:hover   { color: #e5c07b; }
    .lmm-wp-confirm       { color: rgba(224, 108, 117, 0.7) !important; font-size: 10px !important; }
    .lmm-wp-confirm:hover { color: #e06c75 !important; }

    /* In-group capsule strip — all Pmirrors live here, none in the region body. */
    .lmm-inbox {
        display: flex; flex-wrap: wrap; gap: 4px; align-items: center;
        padding: 5px 6px;
        min-height: 30px;
        background: rgba(0, 0, 0, 0.35);
        border-bottom: 1px solid rgba(229, 192, 123, 0.12);
        flex-shrink: 0;
    }

    .lmm-capsule {
        display: flex; align-items: center; gap: 3px;
        background: rgba(229, 192, 123, 0.08);
        border: 1px solid rgba(229, 192, 123, 0.28);
        border-radius: 3px;
        padding: 3px 4px 3px 3px;
        font-family: inherit;
        line-height: 1;
    }
    .lmm-capsule-dormant {
        background: rgba(80, 90, 100, 0.12);
        border-color: rgba(80, 100, 120, 0.25);
    }
    .lmm-capsule-bad { border-color: rgba(224, 108, 117, 0.35); }

    /* Orb inside capsule — the showing toggle. */
    .lmm-capsule-orb {
        display: block; width: 8px; height: 8px;
        border-radius: 50%; flex-shrink: 0;
        background: transparent;
        border: 1px solid rgba(229, 192, 123, 0.4);
        cursor: pointer; padding: 0;
        transition: background 0.12s, box-shadow 0.12s;
    }
    .lmm-capsule-orb.lmm-capsule-orb-show {
        background: #e5c07b;
        border-color: #e5c07b;
        box-shadow: 0 0 4px #e5c07b88;
    }
    .lmm-capsule-bad .lmm-capsule-orb      { border-color: rgba(224, 108, 117, 0.5); }
    .lmm-capsule-bad .lmm-capsule-orb-show { background: #e06c75; border-color: #e06c75; box-shadow: 0 0 4px #e06c7588; }
    .lmm-capsule-orb:hover { opacity: 0.75; }

    .lmm-capsule-label {
        background: none; border: none; cursor: pointer;
        color: #e5c07b; font-family: inherit; font-size: 10px; line-height: 1.3;
        padding: 0; max-width: 90px;
        overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
    }
    .lmm-capsule-label:hover              { color: #fff; }
    .lmm-capsule-dormant .lmm-capsule-label { color: #4a6070; }
    .lmm-capsule-bad     .lmm-capsule-label { color: #e06c75; text-decoration: line-through; }

    /* × always visible — primary demote control. */
    .lmm-capsule-demote {
        background: none; border: none; cursor: pointer;
        color: #3a5060; font-family: inherit; font-size: 10px;
        padding: 0 1px; line-height: 1;
    }
    .lmm-capsule-demote:hover { color: #e06c75; }

    /* Cursor advance — steps Lies to next What_Point. */
    .lmm-cursor-next {
        background: none; border: none; cursor: pointer;
        color: #2a4a5a; font-size: 11px; padding: 0 3px;
        font-family: inherit; margin-left: auto;
    }
    .lmm-cursor-next:hover { color: #c0d0e0; }

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
