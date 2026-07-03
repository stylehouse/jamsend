<script lang="ts">
    // LangRegions.svelte — region parsing, Point resolution, fold-based "openness".
    //  Deposits onto H via M.eatfunc():
    //   Lang_build_regions     //#region/#endregion → flat list + nested tree
    //   Lang_resolve_point     method_spec → char span via the compiled Map index
    //   Lang_apply_openness    fold all but the ancestor chain to a resolved Point
    //   e_Lang_point_navigate  resolve → openness → scroll → report
    //
    //  Lang_resolve_point spec forms, tried in order (rank defs > calls > regions > comments):
    //    "a / b"        stack-path: def `a`, then `b` within its range
    //    "a / if cond"  stack-path: def `a`, then ControlFlow matching `if cond`
    //    "SomeName"     exact def, then region label, then call
    //    bare text      fuzzy: defs, calls, regions, comments
    //   issues[] is non-empty for any imperfection (ambiguity, no def, comment-only, broken path).

    import type { TheC } from "$lib/data/Stuff.svelte"
    import type { EditorState } from "@codemirror/state"
    import { EditorView } from "@codemirror/view"
    import { foldEffect, unfoldEffect } from "@codemirror/language"
    import { onMount } from "svelte"

    // RegionEntry — defined at script scope so the type is in scope inside eatfunc.
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

    // Pre-scan for //#region … //#endregion pairs → flat list in source order
    //  (parent before children) + `tree` (root-level, children nested per entry).
    //  from_char = line.from of the header; we fold from header.to not .from, so
    //   the header line stays visible.
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

                // Implicitly close any open region at depth ≥ new before opening (unpaired markers).
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

    // The compiled Map index that Lang_resolve_point + Lang_map_span query lives at
    //  dock / Compile / Map; a null result = no index yet (caller hints "run compile").
    //   {def:1,         method, from, to, line, region_path}
    //   {call:1,        method, via?, from, to, line, region_path}
    //   {region:1,      label,  from, to, line, depth}
    //   {controlflow:1, keyword, title, from, to, line, via?, region_path}
    // Absolute [from,to) char span of a %Map entry.  region entries store from/to
    //  absolute (the anchor a stack-path narrows within); def/call/controlflow store
    //  rel_from/rel_to vs their region's from, so an edit outside that region leaves
    //   their snapped offsets untouched — what quiets the from=/to= snap churn.
    //  c.abs_* is the live span compile writes each pass; the rel reconstruction
    //   (region matched by full region_path) is the fallback for a snap-decoded %Map.
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
        // text: a literal Point — find a word|phrase in the doc itself, not a named
        //  def|region.  Needs only state.doc, so it resolves even before a compile (no
        //  %Map); a Point,text:<str> with the SAME str in two docs bridges the substrates,
        //  each landing on its own occurrence.  Word-boundary exact first (so 'want' misses
        //  inside 'wanted'), then substring, then loose case-insensitive.
        const t0 = method_spec.trim()
        if (t0.startsWith('text:')) {
            const needle   = t0.slice(5).trim()
            const tIssues  = [`text '${needle}'`]
            if (needle) {
                const src = state.doc.toString()
                let at = -1
                if (/^\w+$/.test(needle)) at = src.search(new RegExp(`\\b${needle}\\b`))
                if (at < 0) at = src.indexOf(needle)
                if (at < 0) at = src.toLowerCase().indexOf(needle.toLowerCase())
                if (at >= 0)
                    return { from: at, to: at + needle.length,
                             line: state.doc.lineAt(at).number, kind: 'text', issues: tIssues }
                tIssues.push('not found in this doc')
            }
            return null
        }

        const job     = dock.o({ Compile: 1 })[0]  as TheC | undefined
        // Map is a direct child of Compile (Output holds source/dige; Map is its sibling).
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

    // Resolve a stack-path "story_save / if runH": split on " / ", resolve each
    //  segment within the previous match's range; return the deepest match reached
    //  before the path broke (issues accumulate per broken segment).
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
    //  Order: exact def → fuzzy def → controlflow keyword → call → region.
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

        const inDef = defs.find(d =>
            d.sc.method === seg &&
            span(d).from >= range_from &&
            span(d).to   <= range_to
        )
        if (inDef) return { ...span(inDef), line: inDef.sc.line as number }

        const fuzzyDef = defs.find(d =>
            (d.sc.method as string)?.toLowerCase().includes(lc) &&
            span(d).from >= range_from &&
            span(d).to   <= range_to
        )
        if (fuzzyDef) {
            issues.push(`fuzzy matched '${seg}' → '${fuzzyDef.sc.method}'`)
            return { ...span(fuzzyDef), line: fuzzyDef.sc.line as number }
        }

        const inCall = calls.find(c =>
            c.sc.method === seg &&
            span(c).from >= range_from &&
            span(c).to   <= range_to
        )
        if (inCall) {
            issues.push(`'${seg}' found only as a call site within range`)
            return { ...span(inCall), line: inCall.sc.line as number }
        }

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

    // First // or # comment line containing the search text, or null.
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

    // Lang_def_at_offset — innermost method def whose compiled range contains `offset`
    //  (smallest span wins, so a helper nested in a larger fn resolves to the helper),
    //  or undefined (no index | no enclosing def).  Used by e_Lang_point_fuzzify to
    //  upgrade a positional bookmark to a named method pointer with no typing.
    Lang_def_at_offset(dock: TheC, offset: number): string | undefined {
        // Map is a direct child of Compile (sibling of Output)
        const job   = dock.o({ Compile: 1 })[0] as TheC | undefined
        const Map_C = job?.o({ Map: 1 })[0]      as TheC | undefined
        if (!Map_C) return undefined

        const defs    = Map_C.o({ def: 1 })    as TheC[]
        const regions = Map_C.o({ region: 1 }) as TheC[]
        const span    = (e: TheC) => this.Lang_map_span(regions, e)

        // 1) def whose own name-span contains offset — cursor sat on the method name.
        //    Innermost (smallest span) wins.
        const onName = defs.filter(d => {
            const s = span(d)
            return s.from <= offset && s.to >= offset
        })
        if (onName.length) {
            onName.sort((a, b) =>
                (span(a).to - span(a).from) - (span(b).to - span(b).from))
            return onName[0].sc.method as string
        }

        // 2) a def declared on the same line — the MethodLike-on-the-line reducer: a
        //    bookmark dropped anywhere on the def's line names it without landing on the
        //    name (one MethodLike per line → unambiguous).  < richer cases (a call we'd
        //    rather name, nested arrows) come later.
        // `offset` + d.sc.line are Map-frame coordinates, so read them via Lang_index_state
        //  (the Map's frame), not the live buffer.
        const state = this.Lang_index_state(dock)
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

    // e_Lang_tap — the giver side of Point traffic — the elvis DocCompost reveal|fly fire:
    //  i_elvisto('Lang/Lang', 'Lang_tap', { from, long?, weight? }).  MUST be named
    //  e_Lang_tap and take the (A, w, e) elvis shape (the e_ prefix is how i_elvisto
    //  resolves a handler) — as a plain Lang_tap(w,...) the dispatch logs "!method:
    //  e_Lang_tap" and the whole tap→globulate→trail pipeline silently never runs.
    //  A tap at char `from` resolves to its $region/$method identity by NAME through
    //  %Map (never by stored offset), handed to the taker Ting (e_Lies_take_point).
    //  %Map stores name-spans not bodies, so the owning method = the def whose header
    //  most recently precedes the tap line, bounded to the region that contains the tap
    //  (its body span from Lang_build_regions, the fold source of truth) so an earlier
    //  region's def can't claim it.  region = the def's region_path tail (the direct
    //  region it sits in); a tap with no def above it within its region is method-less
    //  and lands on the region band itself (look at a header|preamble → the band glows).
    //  < precise per-def body containment (a tap in a parent's body after a child region
    //    should read the parent, not the child's last def) needs def body extents %Map
    //    lacks; the indent-block decomposition would give them.
    //  e.sc: { from, long?, weight? }
    async e_Lang_tap(A: TheC, w: TheC, e: TheC) {
        const H      = this as House
        const from   = e.sc.from as number | undefined
        if (typeof from !== 'number') return
        const opt    = { long: !!e.sc.long, weight: (e.sc.weight as number) ?? 1 }
        const dock   = this.Lang_active_dock(w)
        if (!dock) return
        const dpath  = dock.sc.dock as string   // dock path (the later `path` is the tap's region path)
        const view   = dock.c.view as EditorView | undefined
        // Reindex against the CURRENT text before resolving, so a tap lands even on a
        //  doc edited since the last compile (no waiting on req:compile's ~6s settle).
        //  Points-only: a .g reindex re-runs GEN (render→.go→runner), too heavy|side-
        //  effecting for a gesture, so a .g resolves against its last settled Map.  Re-
        //  stamps job.c.source_state = view.state so Lang_index_state shares the tap's
        //  frame — sub-millisecond, writes nothing.
        if (view && !H.Lies_gen_path(dpath) && H.Lang_points_only(dpath))
            await H.Lang_compile_dock(w, dock, view.state)
        const job    = dock.o({ Compile: 1 })[0] as TheC | undefined
        const Map_C  = job?.o({ Map: 1 })[0]      as TheC | undefined
        // Resolves to a $region/$method by NAME through %Map; map its char to a line in
        //  the Map's frame (Lang_index_state), which the reindex just pinned to the view.
        const state  = this.Lang_index_state(dock)
        if (!Map_C || !state) return

        const at       = Math.max(0, Math.min(from, state.doc.length))
        const tap_line = state.doc.lineAt(at).number

        // innermost region whose body span contains the tap — %Map region entries carry
        //  only the header line, so containment comes from Lang_build_regions' from_char|
        //  to_char (proper open-region stack); regions nest, deepest containing wins.
        const { regions } = this.Lang_build_regions(state)
        let reg: RegionEntry | undefined
        for (const r of regions) {
            if (r.from_char <= at && at <= r.to_char && (!reg || r.depth > reg.depth)) reg = r
        }

        // owning def — nearest def header at|above the tap, bounded to reg (its name
        //  offset must sit inside reg's body span) so an earlier region's def can't claim
        //  it.  None within reg → owner undefined: a method-less tap on the region.
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
        //  stack at its header); a method-less tap takes the chain of regions containing
        //  it.  Tail = the direct region (the chip|band key the globule keys on, like the
        //  Mapule); the rest are ancestors the heat rolls up to, so a parent band warms
        //  from a nested method.  A held (long) tap also carries the line it lingered on.
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

    // Dispatch CM fold/unfold so only the ancestor chain to `point_from` stays open;
    //  everything else, at every depth, folds.  Fold range = header.to … region.to_char
    //  (the //#region header line stays readable).  Requires codeFolding()|foldGutter()
    //  in the editor extensions, else foldEffect/unfoldEffect are silent no-ops.
    Lang_apply_openness(
        view:       EditorView,
        regions:    RegionEntry[],
        point_from: number,
    ) {
        const effects: ReturnType<typeof foldEffect.of>[] = []

        for (const region of regions) {
            const header_line = view.state.doc.line(region.from_line)
            const fold_from   = header_line.to   // end of header
            const fold_to     = region.to_char   // end of region body

            if (fold_from >= fold_to) continue   // empty or degenerate region

            // A region is on the open path if point_from falls inside its char span.
            const is_ancestor = point_from >= region.from_char && point_from <= region.to_char

            if (is_ancestor) {
                effects.push(unfoldEffect.of({ from: fold_from, to: fold_to }))
            } else {
                effects.push(foldEffect.of({ from: fold_from, to: fold_to }))
            }
        }

        if (effects.length) {
            view.dispatch({ effects })
        }
    },

//#endregion
//#region e_Lang_point_navigate

    // e_Lang_point_navigate — full resolve → openness → scroll → report cycle for a
    //  Point spec.  Called from e_Dock_open (when e.sc.point present) and directly from
    //  Liesui on a Point-row click.  e.sc: { point: string, doc?: string, tries?: number }
    //   A point can OUTRUN a freshly-opened dock: the CodeMirror view hasn't mounted yet,
    //    and a named def needs the %Map a first compile hasn't produced — resolving then
    //     goes nowhere, and the doc just shows its resumed position ("a random place").
    //      While the miss is plausibly transient, re-ask a few beats later (bounded,
    //       backing off ≈7s total — enough for view-mount + a first compile); a retry
    //        DROPS if the user has moved to another dock meanwhile.
    async e_Lang_point_navigate(A: TheC, w: TheC, e: TheC) {
        const H    = this
        const spec = e.sc.point as string | undefined
        if (!spec) return
        const tries = (e.sc.tries as number) ?? 0
        const again = () => {
            if (tries >= 6) return false
            setTimeout(() => H.i_elvisto('Lang/Lang', 'Lang_point_navigate',
                { point: spec, doc: e.sc.doc, tries: tries + 1 }), 350 * (tries + 1))
            return true
        }

        const dock  = this.Lang_active_dock(w)
        if (!dock) { again(); return }
        if (e.sc.doc && dock.sc.dock !== e.sc.doc) return   // stale retry — the user moved on
        const view  = dock.c.view  as EditorView | undefined
        const path  = dock.sc.dock as string
        if (!view) { again(); return }                      // fresh open — CM not mounted yet
        // Reindex against the CURRENT text before resolving, so a Point lands even on a
        //  doc edited since the last compile (no waiting on req:compile's ~6s settle).
        //  Points-only: a .g reindex re-runs GEN, too heavy for a nav gesture, so a .g
        //  resolves against its last settled Map as before.
        if (!H.Lies_gen_path(path) && H.Lang_points_only(path))
            await H.Lang_compile_dock(w, dock, view.state)
        // Resolve + build regions in the Map's frame (Lang_index_state, pinned to the live
        //  view by the reindex), so result.from and the fold|selection share one frame.
        const state = this.Lang_index_state(dock)
        if (!state) { again(); return }

        const result = this.Lang_resolve_point(state, dock, spec)

        if (!result) {
            // a named spec with NO %Map yet = the compile is still coming — retry, not report
            const has_map = !!(dock.o({ Compile: 1 })[0] as TheC | undefined)?.o({ Map: 1 })[0]
            if (!has_map && !spec.startsWith('text:') && again()) return
            // No compiled index (and retries spent) — ask user to compile first.
            w.i({ see: `⏳ Point '${spec}': no index yet — run compile first` })
            H.i_elvisto('Lies/Lies', 'Lies_point_issues', {
                doc:    dock.sc.dock  as string,
                point:  spec,
                issues: [`no compiled index for this doc; run compile first`],
            })
            return
        }

        const { regions } = this.Lang_build_regions(state)
        this.Lang_apply_openness(view, regions, result.from)

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
