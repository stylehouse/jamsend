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
    //   Reads ONLY the generic overview layer: dock/%Navicade, the Mapulen Lang
    //   builds next to %Compile (one %kind,key,path,depth tuple per Map entry, with
    //   the finished band geometry and the goto|fold|is_pointedat closures on .c).
    //   The minimap reads no %Map, parses no //#region, knows nothing Lang — it lays
    //   out bands and chips from the Mapulen and drives every action through their
    //   closures.  The only other reads are generic: lang_dock.c.text for the line
    //   count, and %Languinio/%LE for the spinners and the working-Point set.
    //
    //   Points (Pmirrors) are owned by NaviCado — not rendered in the region body.
    //   The region/def body (lmm-strip) shows only region bands and def chips, with
    //   the working Points lit bigger+yellow (Mapule.c.is_pointedat).
    //
    // ── Scroll sync ──────────────────────────────────────────────────────────
    //
    //   _hovering: true while mouse is over the strip.
    //   _navigating: true for 200ms after a nav move (begin_nav) — suppresses the
    //     scroll event our own CM dispatch fires before it can fight the new position.

    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { EditorView } from "@codemirror/view"
    import { unfoldEffect, foldedRanges } from "@codemirror/language"
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
        // element (Lang stamps it on every Mapule).  Two regions are the same
        // container iff their paths are equal|defs nest by exact match.
        path:      string[]
        // the Mapule this band came from — navigation, fold and pointedat all ride
        // it, so the minimap holds no Lang.  The de-facto head band has none.
        mapule?:   TheC
    }
    type Def = { method: string, class?: string, line: number, from: number, to: number, path: string[], mapule: TheC }
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

    // ── Mapulen — the generic overview layer (dock/%Navicade) ──────────────────
    //
    //   Lang builds one Mapule per Map entry next to %Compile; the minimap renders
    //   ENTIRELY from these — bands, chips, nesting, navigation, fold and pointedat —
    //   and reads no %Map, parses no //#region, knows nothing Lang.  Each band|chip
    //   carries its Mapule, so a click is just mapule.c.goto()|mapule.c.fold(), and
    //   pointedat is mapule.c.is_pointedat against the working-Point set.
    let LE = $derived(languinio?.ob({ LE: 1 })[0] as TheC | undefined)

    let pointed_specs = $derived.by(() => {
        void LE?.vers
        return ((H as any).Lang_pointed_specs?.(LE) as Set<string> | undefined) ?? new Set<string>()
    })

    // pointedat_m(mapule) — does this entry test as a working Point.  Routes through
    //   Mapule.c.is_pointedat so the membership rule stays Lang-side|reactive on
    //   pointed_specs (LE.vers), so the styling tracks Point toggles.
    function pointedat_m(m: TheC | undefined): boolean {
        return m ? !!(m.c.is_pointedat as ((s: Set<string>) => boolean) | undefined)?.(pointed_specs) : false
    }

    // ── trail heat ──────────────────────────────────────────────────────────
    //   The Undertaking LE's trail (where we've been) painted over the map.  Same
    //   rail as pointed_specs: a Lang-side map ($region/$method → 0..1), sensitised
    //   on the Undertaking LE.vers (the trail Funkcion bumps it each tap + trickle),
    //   read per entry through Mapule.c.bright.  An amber glow blazes on recent
    //   attention and cools on its own as the trickle decays it — the animal's mind
    //   overlaid on the visual language, no Lang vocabulary in the minimap.
    let undertaking = $derived(languinio?.ob({ LE: 'Undertaking' })[0] as TheC | undefined)
    let brights = $derived.by(() => {
        void undertaking?.vers
        return ((H as any).Lang_trail_brights?.() as Map<string, number> | undefined) ?? new Map<string, number>()
    })
    // warms — same rail, the deliberateness 0..1 (held|long share vs graze) the glow
    //   tints by.  Sensitised on the same LE.vers so it re-reads in lock-step.
    let warms = $derived.by(() => {
        void undertaking?.vers
        return ((H as any).Lang_trail_warm?.() as Map<string, number> | undefined) ?? new Map<string, number>()
    })
    function heat_style(m: TheC | undefined): string {
        const b = m ? ((m.c.bright as ((br: Map<string, number>) => number) | undefined)?.(brights) ?? 0) : 0
        if (b <= 0.02) return ''
        // hue by deliberateness: amber where attention only grazed, warming toward
        //   pink where it lingered (held|long taps) — the glow says where AND how.
        const w  = m ? ((m.c.warm as ((wr: Map<string, number>) => number) | undefined)?.(warms) ?? 0) : 0
        const gg = Math.round(190 - 70 * w)
        const bb = Math.round(80 + 120 * w)
        // glow only on the RIGHT of each thing: offset the shadow right and flatten it
        //   vertically (negative spread) so it streaks off the right edge instead of
        //   haloing the whole chip — a heat gutter down the strip's right side.
        const off    = (b * 6).toFixed(1)
        const blur   = (b * 11).toFixed(1)
        const spread = (-(b * 4 + 1)).toFixed(1)
        return `box-shadow: ${off}px 0 ${blur}px ${spread}px rgba(255,${gg},${bb},${(b * 0.9).toFixed(2)}); border-radius: 3px;`
    }



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
        // The whole structure comes from dock/%Navicade now — the Mapulen Lang builds
        // next to %Compile.  No %Map read, no //#region scan|each band and chip keeps
        // its Mapule for goto, fold and pointedat.  Before the first compile there are
        // no Mapulen and the strip is simply empty until one lands.
        const navicade = lang_dock?.o({ Navicade: 1 })[0] as TheC | undefined
        if (!navicade) {
            _structure = { regions: [], top_level_defs: [] }
            last_log_summary = ''
            return
        }
        const mapules   = navicade.o({ Mapule: 1 }) as TheC[]
        const region_ms = mapules.filter(m => m.sc.kind === 'region')
        const def_ms    = mapules.filter(m => m.sc.kind === 'def')
        const text      = (lang_dock!.c.text as string) ?? ''

        const list: Region[] = region_ms.map(m => ({
            label:     m.sc.key as string,
            depth:     (m.sc.depth as number) ?? 0,
            from_line: (m.sc.line as number) ?? 1,
            to_line:   (m.sc.end_line as number) ?? total_lines,
            from_char: (m.sc.from as number) ?? 0,
            to_char:   (m.c.body_to as number) ?? text.length,
            defs:      [],
            path:      (m.c.path as string[] | undefined) ?? [],
            mapule:    m,
        }))

        // De-facto head band: the span before the first region (the file head) gets a
        // band like the rest, labelled by the first non-blank line.  Presentation only
        // — line numbers and a label, no Lang.  It has no Mapule|clicking its label
        // seeks to the file top.
        const first_real = list.reduce((m, r) => Math.min(m, r.from_line), Infinity)
        let defacto: Region | undefined
        if (first_real > 1) {
            const head = (text.split('\n').find(l => l.trim()) ?? 'head').trim().slice(0, 40)
            defacto = {
                label: head, depth: 0, from_line: 1,
                to_line: isFinite(first_real) ? first_real - 1 : total_lines,
                from_char: 0, to_char: text.length, defs: [], path: [head],
            }
            list.unshift(defacto)
        }

        // index regions by their exact path for O(1) def nesting.  path is Lang's
        // authoritative containment record (a def's path equals its region's path),
        // so this needs no text geometry.
        const by_path = new Map<string, Region>()
        for (const r of list) by_path.set(path_key(r.path), r)

        const top_defs: Def[] = []
        for (const m of def_ms) {
            const def: Def = {
                method: m.sc.key as string,
                class:  m.sc.cls as string | undefined,
                line:   (m.sc.line as number) ?? 0,
                from:   (m.sc.from as number) ?? 0,
                to:     (m.sc.to   as number) ?? 0,
                path:   (m.c.path as string[] | undefined) ?? [],
                mapule: m,
            }
            // path-bearing defs match their region exactly|a path-less def in the head
            // falls into the de-facto band, otherwise it is genuinely top-level (a rare
            // def after the last region).
            const owner = def.path.length
                ? (by_path.get(path_key(def.path)) ?? innermost_region_for_line(list, def.line))
                : (defacto && def.line <= defacto.to_line
                    ? defacto
                    : innermost_region_for_line(list, def.line))
            if (owner) owner.defs.push(def)
            else top_defs.push(def)
        }

        const summary = `${list.length}r ${def_ms.length}d`
        if (summary !== last_log_summary) {
            console.log(`🗺 minimap rebuild ${active_path}: regions=${list.length} defs=${def_ms.length} (mapulen)`)
            last_log_summary = summary
        }
        _structure = { regions: list, top_level_defs: top_defs }
    }

    // ── helpers ───────────────────────────────────────────────────────────────

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
    //      teacher tapping the board), a manual goto (record_goto), and certainly
    //      any edit.  Each lands a faint timestamped Point on the layer.
    //    The trail draws back as a heatmap streak careening over the MiniMap —
    //      pull up history and watch it move.  Edits batch against it so a session
    //      of changes replays as one pleasing sweep rather than scattered diffs.
    //    Manual gotos and edits weigh heaviest|mere on-screen visibility weighs
    //      least and decays.  All of it resolves through %Map by name, never by
    //      stored absolute offset — same crawl-to-method identity as %Points.

    // Land on a target: open whatever fold hides it, select its name span, and
    // centre it — all in one transaction so the scroll measures against the
    // already-unfolded geometry instead of a fold placeholder.  At a high Q the
    // target method's body is folded (its fold begins on the target's own header
    // line) and an outer block may fold over it too|we open both so a goto reveals
    // real code, not a crunched stub.  LangPoint still owns the overall Q set; this
    // only lifts the folds in the way of this one target, and the next climb
    // reconciles the rest.
    function seek(from: number, to: number) {
        if (!view) return
        const doc  = view.state.doc
        const line = doc.lineAt(from)
        const opens: Array<{ from: number, to: number }> = []
        foldedRanges(view.state).between(0, doc.length, (f, t) => {
            // a fold starting on the target's header line is the target's own body|
            // a fold spanning the target is an ancestor hiding it — open either.
            if ((f >= line.from && f <= line.to) || (f <= from && t >= from))
                opens.push({ from: f, to: t })
        })
        view.dispatch({
            selection: { anchor: from, head: to },
            effects: [
                ...opens.map(r => unfoldEffect.of(r)),
                EditorView.scrollIntoView(from, { y: 'center' }),
            ],
        })
        view.focus()
    }

    // _navigating guards the scroll-sync for a beat after we move the editor, so our
    // own dispatch doesn't bounce back through sync_scroll and fight the new position.
    function begin_nav() {
        _navigating = true
        clearTimeout(_nav_timer)
        _nav_timer = setTimeout(() => { _navigating = false }, 200) as any
    }
    function push_nav(from: number, to: number, label: string) {
        const truncated = nav_hist.slice(0, nav_pos + 1)
        truncated.push({ path: active_path, from, to, label })
        nav_hist = truncated
        nav_pos  = truncated.length - 1
    }

    // Look at an entry through its Mapule (mapule.c.goto), recording the move so the
    // breadcrumb + back/forward keep working.  The de-facto head band has no Mapule|
    // its fallback seeks to the file top.
    //   When DocCompost has armed dock.c.compost, a goto becomes a fly-in: a frozen
    //   frame zooms toward the spot while the editor auto-crunches to the Q the
    //   tap-log suggests for it, then lands.  Without compost it's the plain goto|
    //   seek, so the minimap holds no Lang and works either way.
    function record_goto(m: TheC | undefined, fallback?: { from: number, label: string }) {
        begin_nav()
        const compost = lang_dock?.c.compost as
            { fly: (from: number) => void } | undefined
        if (m) {
            const from = (m.sc.from as number) ?? 0
            push_nav(from, (m.sc.to as number) ?? 0, String(m.sc.key))
            if (compost) compost.fly(from)
            else (m.c.goto as (() => void) | undefined)?.()
        } else if (fallback) {
            push_nav(fallback.from, fallback.from, fallback.label)
            if (compost) compost.fly(fallback.from)
            else seek(fallback.from, fallback.from)
        }
    }

    function go_back() {
        if (!can_back || !view) return
        nav_pos = nav_pos - 1
        const e = nav_hist[nav_pos]
        begin_nav()
        seek(e.from, e.to)
    }
    function go_forward() {
        if (!can_forward || !view) return
        nav_pos = nav_pos + 1
        const e = nav_hist[nav_pos]
        begin_nav()
        seek(e.from, e.to)
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

    // Fold / unfold this region's body in CM — through the Mapule, so the minimap
    // computes no fold range itself.  The de-facto head band has no Mapule|nothing
    // to fold there.
    function toggle_fold(region: Region) {
        ;(region.mapule?.c.fold as (() => void) | undefined)?.()
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

    // ── Q-factor — fold intensity, 1 (open) … 5 (only method names) ────────────
    //   The dial just asks Lang to climb; LangPoint owns the fold/font waves and
    //   the gallop between levels.  Per active doc, so switching docs shows that
    //   doc's intensity (LangPoint reads dock.c.Q).
    let q_factor = $state(1)
    function set_q(q: number) {
        q_factor = q
        H.i_elvisto('Lang/Lang', 'Lang_climb', { Q: q })
    }
    // Native <select> doesn't wheel-change, and a wheel here would otherwise
    // bubble to the strip's on_wheel and scroll the map|so we own the event:
    // nudge Q one notch per detent (wheel-down climbs toward folded), clamp 1..5.
    function q_wheel(e: WheelEvent) {
        e.preventDefault()
        e.stopPropagation()
        const next = Math.max(1, Math.min(5, q_factor + (e.deltaY > 0 ? 1 : -1)))
        if (next !== q_factor) set_q(next)
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
        <select class="lmm-q" bind:value={q_factor} onchange={() => set_q(q_factor)}
                onwheel={q_wheel}
                title="fold intensity — Q1 open … Q5 only method names">
            {#each [1, 2, 3, 4, 5] as q}<option value={q}>Q{q}</option>{/each}
        </select>
        {#each _spinners as name (name)}
            <span class="lmm-spin lmm-spin-{name}" title={name}>⟳</span>
        {/each}
        {#if _graft_spin}<span class="lmm-graft-spin" title="grafting Points">⟳</span>{/if}
        {#if _stale_spin}<span class="lmm-stale-spin" title="Understanding stale — remote moved">↻</span>{/if}
    </div>

    <NaviCado {H} />

    <div class="lmm-scroll" bind:this={scroll_container_el}>
        <div class="lmm-strip" bind:this={strip_el}>
            <!-- Single column: region headers span the strip, def chips pile under
                 them in source order.  Points are NOT rendered here — they live only
                 in the capsule strip above. -->

            {#if top_level_defs.length}
                <div class="lmm-def-col">
                    {#each top_level_defs as d (d.from)}
                        <button class="lmm-def-chip lmm-def-chip-top"
                                class:lmm-def-chip-class={!d.class}
                                class:lmm-pointedat={pointedat_m(d.mapule)}
                                style={heat_style(d.mapule)}
                                title="{d.method} (line {d.line})"
                                onclick={() => record_goto(d.mapule)}>{d.method}</button>
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
                            class:lmm-pointedat={pointedat_m(r.mapule)}
                            style={heat_style(r.mapule)}
                            onclick={() => record_goto(r.mapule, { from: r.from_char, label: r.label })}
                            title="{r.label} (line {r.from_line}–{r.to_line})">{r.label}</button>
                    <button class="lmm-fold"
                            onclick={() => toggle_fold(r)}
                            title="Fold/unfold in editor">f</button>
                </div>

                {#if !is_collapsed(r) && r.defs.length}
                    <div class="lmm-def-col" style="padding-left: {r.depth * 5 + 4}px;">
                        {#each r.defs as d (d.from)}
                            <button class="lmm-def-chip"
                                    class:lmm-def-chip-class={!d.class}
                                    class:lmm-pointedat={pointedat_m(d.mapule)}
                                    style={heat_style(d.mapule)}
                                    title="{d.method} (line {d.line})"
                                    onclick={() => record_goto(d.mapule)}>{d.method}</button>
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
    /* Q-factor dial — fold intensity */
    .lmm-q {
        margin-left: auto; flex-shrink: 0;
        background: rgba(0, 0, 0, 0.3); color: #8aa; border: 1px solid #223;
        font-family: inherit; font-size: 10px; line-height: 1;
        padding: 0 2px; border-radius: 3px; cursor: pointer;
    }
    .lmm-q:hover { color: #cde; border-color: #345; }
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
        grid-template-columns: 1fr;   /* one column of methods */
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

    /* Pointed-at — this entry is one of the working Points (Mapule.c.is_pointedat).
       Bigger and yellow so the Points stand out of the overview at a glance.
       Wins the colour over the chip-class|top tints above by following them. */
    .lmm-pointedat {
        color: #e8d24a !important;
        font-size: 1.25em;
        font-weight: 600;
    }
    .lmm-pointedat:hover { color: #f4e26a !important; }
</style>
