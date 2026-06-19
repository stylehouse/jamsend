<script lang="ts">
    // LangRegions.svelte — region parsing, Point resolution, and fold-based
    // "openness" management for Lang.
    //
    // Deposits onto H via M.eatfunc():
    //
    //   Lang_build_regions(state)
    //     Pre-scans doc text for //#region NAME and //#endregion markers.
    //     Returns { regions: RegionEntry[], tree: RegionEntry[] }.
    //     Each RegionEntry: { label, depth, from_line, to_line, from_char, to_char, children }
    //     Used by Lang_apply_openness to know which char spans to fold/unfold.
    //
    //   Lang_resolve_point(state, dock, method_spec)
    //     Parses `method_spec` and matches against the compiled Map index
    //     (dock / Compile / Map / {def|call|region|controlflow:1, …}).
    //     Returns { from, to, line, kind, issues[] } or null (no index yet).
    //
    //     Spec forms (tried in order):
    //       "a / b"           → stack-path: def `a`, then `b` within its range
    //       "a / if cond"     → stack-path: def `a`, then ControlFlow matching `if cond`
    //       "SomeName"        → exact def, then region label, then call
    //       bare text         → fuzzy: defs, calls, regions, comments
    //
    //     Ranking: defs > calls > region headers > comments.
    //     Issues[] is non-empty for any imperfection (multiple matches, no def
    //     found, comment-only match, broken stack path).
    //
    //   Lang_apply_openness(view, regions, point_from)
    //     Given the flat region list and a resolved Point char offset, dispatches
    //     CM foldEffect / unfoldEffect so that only ancestor regions remain open.
    //     Requires codeFolding() (or foldGutter()) in the editor's extensions.
    //
    //   e_Lang_point_navigate(A, w, e)
    //     Fired from e_Dock_open when e.sc.point is present, or from Liesui when
    //     a Point row is clicked.  Resolves → applies openness → scrolls → reports.
    //     e.sc: { point: string, doc?: string }
    //
    // ── Region structure ─────────────────────────────────────────────────────
    //
    //   //#region Label   (any leading whitespace allowed)  → open a region
    //   //#endregion      (optional; implicit close at same/shallower //#region)
    //
    //   A new //#region at depth ≤ current depth implicitly closes the current
    //   one before opening the new one — matching how VS Code and most editors
    //   handle unpaired markers.
    //
    //   fold range = [end of //#region line, to_char] — the header stays visible,
    //   the body is hidden.  This matches foldInside semantics for { } blocks.
    //
    // ── Point spec → openness rule ───────────────────────────────────────────
    //
    //   A region is OPEN if it is an ancestor of (or equal to) the region that
    //   contains the resolved Point.  All siblings and unrelated regions are FOLDED.
    //   The innermost containing region is always fully unfolded.
    //   This is essentially "Fold All Except" applied to the Point's location.

    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { EditorState } from "@codemirror/state"
    import { EditorView } from "@codemirror/view"
    import { foldEffect, unfoldEffect } from "@codemirror/language"
    import { onMount } from "svelte"

    // RegionEntry mirrors what Lang_build_regions returns.
    // Defined here (script scope) so the type is available inside eatfunc.
    type RegionEntry = {
        label:     string
        depth:     number
        from_line: number
        to_line:   number
        from_char: number   // char offset of start of //#region line
        to_char:   number   // char offset of end of region (endregion or doc end)
        children:  RegionEntry[]
    }

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region Lang_build_regions

    // Pre-scan for //#region … //#endregion pairs.
    //
    // Returned flat list is in source order (parent before children).
    // `tree` is the root-level list; children are nested on each entry.
    //
    // from_char / to_char are tight so foldEffect can hide exactly the
    // body: from_char = line.from of the //#region header (the header
    // itself stays visible because we fold from header.to, not header.from).
    Lang_build_regions(state: EditorState): { regions: RegionEntry[], tree: RegionEntry[] } {
        const doc = state.doc
        const REGION_RE    = /^[\t ]*\/\/#region\s+(.+)$/
        const ENDREGION_RE = /^[\t ]*\/\/#endregion\b/

        const all:   RegionEntry[] = []  // flat list in source order
        const tree:  RegionEntry[] = []  // top-level regions (children nested)
        const stack: RegionEntry[] = []  // open-region stack

        for (let n = 1; n <= doc.lines; n++) {
            const line  = doc.line(n)
            const text  = line.text

            const regionM = text.match(REGION_RE)
            const isEnd   = ENDREGION_RE.test(text)

            if (regionM) {
                const label = regionM[1].trim()
                const depth = stack.length

                // Implicitly close any open region at same or greater depth
                // before opening the new one (handles unpaired markers).
                while (stack.length > depth) {
                    const closing      = stack.pop()!
                    closing.to_line    = n - 1
                    closing.to_char    = doc.line(Math.max(1, n - 1)).to
                }

                const entry: RegionEntry = {
                    label,
                    depth,
                    from_line: n,
                    to_line:   doc.lines,              // default: runs to end of doc
                    from_char: line.from,
                    to_char:   doc.line(doc.lines).to, // default: runs to end of doc
                    children:  [],
                }
                all.push(entry)

                // Attach to tree root or to the innermost open region's children.
                if (stack.length === 0) {
                    tree.push(entry)
                } else {
                    stack[stack.length - 1].children.push(entry)
                }
                stack.push(entry)

            } else if (isEnd && stack.length) {
                const closing   = stack.pop()!
                closing.to_line = n
                closing.to_char = line.to
            }
        }
        // Unclosed regions already have to_line/to_char set to doc end above.
        return { regions: all, tree }
    },

//#endregion
//#region Lang_resolve_point

    // Resolve a Point method_spec against dock's compiled Map index.
    //
    // Returns null when there is no compiled index yet — the caller should
    // show a hint and ask the user to run compile first.
    //
    // The Map index lives at: dock / Compile / Map
    //   {def:1, method, from, to, line, region_path}
    //   {call:1, method, via?, from, to, line, region_path}
    //   {region:1, label, from, to, line, depth}
    //   {controlflow:1, keyword, title, from, to, line, via?, region_path}
    // Absolute [from,to) char span of a %Map entry.  Region entries store from/to
    //  absolute (the anchor a stack-path narrows within); def/call/controlflow
    //  store rel_from/rel_to against their enclosing region's from, so a text edit
    //  outside that region leaves their snapped offsets untouched (that relative
    //  encoding is what quiets the from=/to= snap churn).  c.abs_* is the live span
    //  the compile writes every pass; the rel reconstruction (region matched by its
    //  full region_path) is the fallback for a %Map decoded from a snap, no .c cache.
    Lang_map_span(regions: TheC[], e: TheC): { from: number, to: number } {
        if (e.sc.region) return { from: (e.sc.from as number) ?? 0, to: (e.sc.to as number) ?? 0 }
        if (typeof e.c.abs_from === 'number')
            return { from: e.c.abs_from as number, to: (e.c.abs_to as number) ?? (e.c.abs_from as number) }
        const rp = (e.c.region_path as string[] | undefined) ?? []
        let base = 0
        if (rp.length) {
            const key = rp.join(' ')
            const reg = regions.find(r => ((r.c.region_path as string[] | undefined) ?? []).join(' ') === key)
            if (reg) base = (reg.sc.from as number) ?? 0
        }
        const rf = (e.sc.rel_from as number) ?? 0
        return { from: base + rf, to: base + ((e.sc.rel_to as number) ?? rf) }
    },

    Lang_resolve_point(
        state:       EditorState,
        dock:        TheC,
        method_spec: string,
    ): { from: number, to: number, line: number, kind: string, issues: string[] } | null {
        const job     = dock.o({ Compile: 1 })[0]  as TheC | undefined
        // Map is a direct child of Compile, not nested under Output.
        // (Output holds source/dige; Map is a sibling.)
        const Map_C = job?.o({ Map: 1 })[0]  as TheC | undefined
        if (!Map_C) return null   // no compiled index yet

        const defs    = Map_C.o({ def:         1 }) as TheC[]
        const calls   = Map_C.o({ call:        1 }) as TheC[]
        const regions = Map_C.o({ region:      1 }) as TheC[]
        const flows   = Map_C.o({ controlflow: 1 }) as TheC[]

        const issues: string[] = []
        const spec = method_spec.trim()
        const span = (e: TheC) => this.Lang_map_span(regions, e)

        // ── stack-path: "a / b" or "a / if cond" ────────────────────────────
        if (spec.includes(' / ')) {
            return this.Lang_resolve_stack_path(
                state, spec, defs, calls, regions, flows, issues)
        }

        // ── exact def ────────────────────────────────────────────────────────
        const exactDef = defs.find(d => d.sc.method === spec)
        if (exactDef) {
            return { ...span(exactDef),
                     line: exactDef.sc.line as number, kind: 'exact_def', issues }
        }

        // ── exact region label ────────────────────────────────────────────────
        const exactRegion = regions.find(r =>
            (r.sc.label as string)?.toLowerCase() === spec.toLowerCase())
        if (exactRegion) {
            issues.push(`no def '${spec}'; matched region header`)
            return { ...span(exactRegion),
                     line: exactRegion.sc.line as number, kind: 'region', issues }
        }

        // ── exact call (def missing) ──────────────────────────────────────────
        const exactCall = calls.find(c => c.sc.method === spec)
        if (exactCall) {
            issues.push(`no def for '${spec}'; found a call (via: ${exactCall.sc.via ?? 'top-level'})`)
            return { ...span(exactCall),
                     line: exactCall.sc.line as number, kind: 'exact_call', issues }
        }

        // ── fuzzy: substring match in defs ───────────────────────────────────
        const lc = spec.toLowerCase()
        const fuzzyDefs = defs.filter(d => (d.sc.method as string)?.toLowerCase().includes(lc))
        if (fuzzyDefs.length === 1) {
            issues.push(`fuzzy match for '${spec}' → '${fuzzyDefs[0].sc.method}'`)
            const d = fuzzyDefs[0]
            return { ...span(d), line: d.sc.line as number, kind: 'fuzzy_def', issues }
        }
        if (fuzzyDefs.length > 1) {
            issues.push(`ambiguous: '${spec}' matches ${fuzzyDefs.map(d => d.sc.method).join(', ')}`)
            // Return the first (earliest in doc)
            const d = fuzzyDefs[0]
            return { ...span(d), line: d.sc.line as number, kind: 'fuzzy_def', issues }
        }

        // ── fuzzy: calls ─────────────────────────────────────────────────────
        const fuzzyCalls = calls.filter(c => (c.sc.method as string)?.toLowerCase().includes(lc))
        if (fuzzyCalls.length) {
            issues.push(`'${spec}': only call sites found, no def`)
            const c = fuzzyCalls[0]
            return { ...span(c), line: c.sc.line as number, kind: 'fuzzy_call', issues }
        }

        // ── fuzzy: region labels ──────────────────────────────────────────────
        const fuzzyRegions = regions.filter(r => (r.sc.label as string)?.toLowerCase().includes(lc))
        if (fuzzyRegions.length) {
            issues.push(`'${spec}': only region headers matched`)
            const r = fuzzyRegions[0]
            return { ...span(r), line: r.sc.line as number, kind: 'region', issues }
        }

        // ── fuzzy: comment text (last resort) ────────────────────────────────
        const commentMatch = this.Lang_search_comments(state, spec)
        if (commentMatch) {
            issues.push(`'${spec}': only found in a comment (line ${commentMatch.line})`)
            return { ...commentMatch, kind: 'comment', issues }
        }

        issues.push(`'${spec}': not found anywhere in this doc`)
        return null
    },

    // Resolve a stack-path spec like "story_save / if runH".
    //
    // Splits on " / " and resolves each segment within the previous match's range.
    // Issues are accumulated for each broken segment; we return the deepest match
    // we found before the path broke.
    Lang_resolve_stack_path(
        state:   EditorState,
        spec:    string,
        defs:    TheC[],
        calls:   TheC[],
        regions: TheC[],
        flows:   TheC[],
        issues:  string[],
    ): { from: number, to: number, line: number, kind: string, issues: string[] } | null {
        const segments = spec.split(' / ').map(s => s.trim())
        let range_from = 0
        let range_to   = state.doc.length
        let last: { from: number, to: number, line: number } | null = null

        for (let i = 0; i < segments.length; i++) {
            const seg   = segments[i]
            const found = this.Lang_find_within_range(
                state, defs, calls, regions, flows, seg, range_from, range_to, issues)
            if (!found) {
                const path_so_far = segments.slice(0, i).join(' / ')
                issues.push(`stack path broke at '${seg}' (searched within '${path_so_far || 'doc root'}')`)
                break
            }
            range_from = found.from
            range_to   = found.to
            last       = found
        }

        return last ? { ...last, kind: 'stack', issues } : null
    },

    // Find `seg` within [range_from, range_to].
    //
    // Search order: exact def → fuzzy def → controlflow keyword match → call → region.
    Lang_find_within_range(
        state:     EditorState,
        defs:      TheC[],
        calls:     TheC[],
        regions:   TheC[],
        flows:     TheC[],
        seg:       string,
        range_from: number,
        range_to:   number,
        issues:    string[],
    ): { from: number, to: number, line: number } | null {
        const lc = seg.toLowerCase()
        const span = (e: TheC) => this.Lang_map_span(regions, e)

        // Check if seg looks like a control-flow reference: "if X", "for X", etc.
        const CF_RE = /^(if|for|while|until|else)\s+(.*)/i
        const cfM   = seg.match(CF_RE)
        if (cfM) {
            const keyword   = cfM[1].toLowerCase()
            const condition = cfM[2].toLowerCase()

            // First try the indexed controlflow entries (faster, accurate range).
            const cfHit = flows.find(f =>
                (f.sc.keyword as string)?.toLowerCase() === keyword &&
                (f.sc.title  as string)?.toLowerCase().includes(condition) &&
                span(f).from >= range_from &&
                span(f).from <= range_to
            )
            if (cfHit) return { ...span(cfHit), line: cfHit.sc.line as number }

            // Fallback: raw doc text scan within range (catches non-indexed cases).
            const doc = state.doc
            for (let n = doc.lineAt(range_from).number; n <= doc.lines; n++) {
                const line = doc.line(n)
                if (line.from > range_to) break
                const text = line.text.trim().toLowerCase()
                if (text.startsWith(keyword + ' ') && text.includes(condition)) {
                    return { from: line.from, to: line.to, line: n }
                }
            }
            issues.push(`control flow '${seg}' not found in range`)
            return null
        }

        // Exact def within range.
        const inDef = defs.find(d =>
            d.sc.method === seg &&
            span(d).from >= range_from &&
            span(d).to   <= range_to
        )
        if (inDef) return { ...span(inDef), line: inDef.sc.line as number }

        // Fuzzy def within range.
        const fuzzyDef = defs.find(d =>
            (d.sc.method as string)?.toLowerCase().includes(lc) &&
            span(d).from >= range_from &&
            span(d).to   <= range_to
        )
        if (fuzzyDef) {
            issues.push(`fuzzy matched '${seg}' → '${fuzzyDef.sc.method}'`)
            return { ...span(fuzzyDef), line: fuzzyDef.sc.line as number }
        }

        // Call within range.
        const inCall = calls.find(c =>
            c.sc.method === seg &&
            span(c).from >= range_from &&
            span(c).to   <= range_to
        )
        if (inCall) {
            issues.push(`'${seg}' found only as a call site within range`)
            return { ...span(inCall), line: inCall.sc.line as number }
        }

        // Region label within range.
        const inRegion = regions.find(r =>
            (r.sc.label as string)?.toLowerCase().includes(lc) &&
            span(r).from >= range_from &&
            span(r).from <= range_to
        )
        if (inRegion) {
            issues.push(`'${seg}' matched region label only`)
            return { ...span(inRegion), line: inRegion.sc.line as number }
        }

        return null
    },

    // Scan doc lines for // or # comments that contain the search text.
    // Returns position of the first matching comment, or null.
    Lang_search_comments(
        state: EditorState,
        text:  string,
    ): { from: number, to: number, line: number } | null {
        const doc = state.doc
        const lc  = text.toLowerCase()
        for (let n = 1; n <= doc.lines; n++) {
            const line    = doc.line(n)
            const trimmed = line.text.trimStart()
            if ((trimmed.startsWith('//') || trimmed.startsWith('#')) &&
                line.text.toLowerCase().includes(lc)) {
                return { from: line.from, to: line.to, line: n }
            }
        }
        return null
    },

    // ── Lang_def_at_offset ───────────────────────────────────────────────────
    //
    //   Find the innermost method def whose compiled source range contains
    //   `offset`.  Returns the method name, or undefined when the compile
    //   index is absent or no def encloses the offset.
    //
    //   "Innermost" = smallest span, so a helper nested inside a larger
    //   function resolves to the helper name, not the outer one.
    //
    //   Used by e_Lang_point_fuzzify to upgrade a positional bookmark to a
    //   named method pointer without requiring the user to type a name.
    Lang_def_at_offset(dock: TheC, offset: number): string | undefined {
        // Map is a direct child of Compile (sibling of Output)
        const job   = dock.o({ Compile: 1 })[0] as TheC | undefined
        const Map_C = job?.o({ Map: 1 })[0]      as TheC | undefined
        if (!Map_C) return undefined

        const defs    = Map_C.o({ def: 1 })    as TheC[]
        const regions = Map_C.o({ region: 1 }) as TheC[]
        const span    = (e: TheC) => this.Lang_map_span(regions, e)

        // 1) a def whose own name-span contains the offset — the cursor sat right
        //    on the method name.  Innermost (smallest span) wins, so a helper
        //    nested in a larger function resolves to the helper.
        const onName = defs.filter(d => {
            const s = span(d)
            return s.from <= offset && s.to >= offset
        })
        if (onName.length) {
            onName.sort((a, b) =>
                (span(a).to - span(a).from) - (span(b).to - span(b).from))
            return onName[0].sc.method as string
        }

        // 2) a def declared on the same line — the MethodLike-on-the-line reducer.
        //    A bookmark dropped anywhere on `async o_elvis_Idzeugnosis(A,w) {`
        //    names the Point o_elvis_Idzeugnosis without landing on the name|
        //    the line carries one MethodLike so this is unambiguous now.  Richer
        //    cases (a call we'd rather name, nested arrows) come later.
        const state = dock.c.state as EditorState | undefined
        if (state) {
            const at = Math.max(0, Math.min(offset, state.doc.length))
            const ln = state.doc.lineAt(at).number
            const onLine = defs.filter(d => (d.sc.line as number) === ln)
            if (onLine.length) {
                onLine.sort((a, b) =>
                    (span(a).to - span(a).from) - (span(b).to - span(b).from))
                return onLine[0].sc.method as string
            }
        }
        return undefined
    },

    // ── e:Lang_tap ─────────────────────────────────────────────────────────
    //
    //   The giver side of the Point traffic — the elvis DocCompost's reveal|fly fire:
    //   i_elvisto('Lang/Lang', 'Lang_tap', { from, long?, weight? }).  It MUST be named
    //   e_Lang_tap (the e_ prefix is how i_elvisto resolves a handler) and take the
    //   (A, w, e) elvis shape — as a plain Lang_tap(w, from, opt) the dispatch logged
    //   "!method: e_Lang_tap" and the whole tap→globulate→trail pipeline never ran.
    //
    //   A tap at char `from` resolves to its $region/$method identity — by name, through
    //   %Map, never by stored offset — handed to the taker Ting (e_Lies_take_point),
    //   which globulates it.
    //
    //   %Map stores name-spans, not method|region bodies, so the owning method is the
    //   def whose header line most recently precedes the tap line — bounded to the
    //   region that actually contains the tap (its body span, from Lang_build_regions,
    //   the fold source of truth) so a def in an earlier region can't claim it.
    //   region rides the def's own region_path tail (the direct region it sits in); a
    //   tap with no def above it inside its region is method-less and lands on the
    //   region band itself, so a look at a region's header|preamble glows the band.
    //   < precise per-def body containment — a tap in a parent's body after a child
    //     region should read the parent, not the child's last def — needs def body
    //     extents %Map doesn't carry; the indent-block decomposition would give them.
    //   e.sc: { from, long?, weight? }
    async e_Lang_tap(A: TheC, w: TheC, e: TheC) {
        const H      = this as House
        const from   = e.sc.from as number | undefined
        if (typeof from !== 'number') return
        const opt    = { long: !!e.sc.long, weight: (e.sc.weight as number) ?? 1 }
        const dock   = this.Lang_active_dock(w)
        if (!dock) return
        const job    = dock.o({ Compile: 1 })[0] as TheC | undefined
        const Map_C  = job?.o({ Map: 1 })[0]      as TheC | undefined
        const state  = dock.c.state as EditorState | undefined
        if (!Map_C || !state) return

        const at       = Math.max(0, Math.min(from, state.doc.length))
        const tap_line = state.doc.lineAt(at).number

        // innermost region whose body span contains the tap — %Map's region entries
        //  carry only the header line, so containment comes from the from_char|to_char
        //  Lang_build_regions computes (with a proper open-region stack).  Regions
        //  nest, so the deepest containing one wins.
        const { regions } = this.Lang_build_regions(state)
        let reg: RegionEntry | undefined
        for (const r of regions) {
            if (r.from_char <= at && at <= r.to_char && (!reg || r.depth > reg.depth)) reg = r
        }

        // owning def — nearest def header at|above the tap, bounded to reg so an
        //  earlier region's def can't claim a tap that fell in this one (the def's
        //  name offset must sit inside reg's body span).  None above within reg →
        //  owner stays undefined: a method-less tap, landing on the region.
        const defs        = Map_C.o({ def: 1 })    as TheC[]
        const map_regions = Map_C.o({ region: 1 }) as TheC[]
        let owner: TheC | undefined
        for (const d of defs) {
            const ln = d.sc.line as number
            if (ln > tap_line) continue
            if (reg) {
                const df = this.Lang_map_span(map_regions, d).from
                if (df < reg.from_char || df > reg.to_char) continue
            }
            if (!owner || ln > (owner.sc.line as number)) owner = d
        }

        // region path for this tap, shallow→deep: a def carries its own (the region
        //  stack at its header); a method-less tap takes the chain of regions that
        //  contain it.  The tail is the direct region (the chip|band key the globule
        //  keys on, exactly as the Mapule does); the rest are ancestors the heat rolls
        //  up to, so a parent band warms from a nested method too.  A held tap also
        //  carries the line it lingered on, filed under the Point as articulation.
        const method = owner?.sc.method as string | undefined
        const path: string[] = owner
            ? ((owner.c.region_path as string[] | undefined) ?? [])
            : regions.filter(r => r.from_char <= at && at <= r.to_char)
                     .sort((a, b) => a.depth - b.depth).map(r => r.label)
        const region = path.length ? path[path.length - 1] : undefined
        const say    = opt.long ? state.doc.lineAt(at).text.trim() : undefined
        const doc    = dock.sc.dock as string | undefined   // which Doc this attention is in

        H.i_elvisto('Lies/Lies', 'Lies_take_point', {
            method, region, doc,
            region_path: path.length ? path.join('/') : undefined,
            long: !!opt.long, weight: opt.weight ?? 1,
            ...(say ? { say } : {}),
        })
    },

//#endregion
//#region Lang_apply_openness

    // Dispatch CM fold/unfold effects so that only the ancestor chain leading
    // to `point_from` stays open.  Everything else (at every depth) is folded.
    //
    // The fold range for a region is:
    //   from: end of the //#region header line  (header stays readable)
    //   to:   to_char of the region             (close at endregion or doc end)
    //
    // Requires codeFolding() or foldGutter() in the editor's extension list;
    // otherwise foldEffect / unfoldEffect are no-ops (no installed handler).
    Lang_apply_openness(
        view:       EditorView,
        regions:    RegionEntry[],
        point_from: number,
    ) {
        const effects: ReturnType<typeof foldEffect.of>[] = []

        for (const region of regions) {
            // fold range: body only — header //#region line itself stays visible
            const header_line = view.state.doc.line(region.from_line)
            const fold_from   = header_line.to   // end of header
            const fold_to     = region.to_char   // end of region body

            if (fold_from >= fold_to) continue   // empty or degenerate region

            // A region is on the open path if point_from falls inside its char span.
            const is_ancestor = point_from >= region.from_char && point_from <= region.to_char

            if (is_ancestor) {
                // Unfold: reveal the body so the Point is reachable.
                effects.push(unfoldEffect.of({ from: fold_from, to: fold_to }))
            } else {
                // Fold: hide everything not on the path to the Point.
                effects.push(foldEffect.of({ from: fold_from, to: fold_to }))
            }
        }

        if (effects.length) {
            view.dispatch({ effects })
        }
    },

//#endregion
//#region e_Lang_point_navigate

    // ── e_Lang_point_navigate ─────────────────────────────────────────────────
    //
    //   Full resolution → openness → scroll cycle for a Point spec.
    //   Called from e_Dock_open (point navigation TODO is now done here) and
    //   directly from Liesui when a Point row is clicked.
    //
    //   Flow:
    //     1. Check that we have a compiled Map index (needs Lang_compile first).
    //     2. Resolve the Point spec (exact / stack / fuzzy / comment).
    //     3. Build the region tree and apply fold/unfold so only the ancestor
    //        chain is visible.
    //     4. Scroll and select the resolved range.
    //     5. Fire e:Lies_point_issues back to Lies with any diagnostic info.
    //
    //   e.sc: { point: string, doc?: string }
    async e_Lang_point_navigate(A: TheC, w: TheC, e: TheC) {
        const H    = this
        const spec = e.sc.point as string | undefined
        if (!spec) return

        const dock  = this.Lang_active_dock(w)
        if (!dock) return
        const view  = dock.c.view  as EditorView | undefined
        const state = dock.c.state as EditorState | undefined
        if (!view || !state) return

        const result = this.Lang_resolve_point(state, dock, spec)

        if (!result) {
            // No compiled index — ask user to compile first.
            w.i({ see: `⏳ Point '${spec}': no index yet — run compile first` })
            H.i_elvisto('Lies/Lies', 'Lies_point_issues', {
                doc:    dock.sc.dock  as string,
                point:  spec,
                issues: [`no compiled index for this doc; run compile first`],
            })
            return
        }

        // Apply fold/unfold so only the ancestor region chain is open.
        const { regions } = this.Lang_build_regions(state)
        this.Lang_apply_openness(view, regions, result.from)

        // Scroll and select the resolved range in the editor.
        view.dispatch({
            selection: { anchor: result.from, head: result.to },
            effects:   EditorView.scrollIntoView(result.from, { y: 'center' }),
        })

        // Report issues back to Lies (even when empty — clears stale diagnostics).
        H.i_elvisto('Lies/Lies', 'Lies_point_issues', {
            doc:    dock.sc.dock as string,
            point:  spec,
            kind:   result.kind,
            from:   result.from,
            to:     result.to,
            issues: result.issues,
        })

        const flag = result.issues.length ? ` (${result.issues.length} issue${result.issues.length > 1 ? 's' : ''})` : ''
        w.i({ see: `📍 '${spec}' → line ${result.line}${flag}` })
        this.i_elvisto(w, 'think')
    },

    })
    })
</script>
