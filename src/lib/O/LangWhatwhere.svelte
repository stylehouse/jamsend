<script lang="ts">
    // LangWhatwhere.svelte — ghost for Language / CodeMirror / Lezer integration.

    import { _C, TheC } from "$lib/data/Stuff.svelte"
    import { syntaxTree } from "@codemirror/language"
    import type { EditorState } from "@codemirror/state"
    import { onMount, tick } from "svelte"

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({


//#region whatsthis

    whatsthis(state:EditorState,model:TheC,bookmarks:TheC[],opt={}) {
        // First pass: walk the syntax tree for each bookmark.
        // whatsthis_into() finds-or-creates Line / node / text
        // at stable addresses on `model` so duplicate bookmarks
        // collapse onto the same particles.
        for (const bm of bookmarks) {
            const bm_id = bm.sc.bookmark as string
            const bm_key = `the_bm_${bm_id}`
            this.whatsthis_into(state, model, {
                from:  bm.sc.from as number,
                to:    bm.sc.to   as number,
                bm_id,
                bm_key,
                bm,
                ...opt,
            })
        }
    },
    
    // whatsthis_into — dedup-friendly walker.
    //
    // Unlike the old whatsthis() which did bare .i() into a per-bookmark
    // subcontainer, this one uses oai() with stable keys so repeat walks
    // (same syntax span seen by two bookmarks) converge on the same TheC.
    //
    // Line addressing: {Line: line_number, from, to}
    // node addressing: {node: name, from, to} under its Line.
    // text addressing: {text: 1, from, to} under its Line.
    //
    // The bm_key tag (the_bm_${id}:1) is stamped on every Line this bookmark
    // touches, so multiple bookmarks on one Line coexist as multiple tags.
    //
    // Text nodes get measured_width/height from measureText() so Cyto can
    // size them to fit their string content. They also get an `order` index
    // (0-based, left-to-right within the Line) for constraint generation.
    whatsthis_into(
        state: EditorState,
        model: TheC,
        opt: { from: number, to: number, bm_id: string, bm_key: string, bm: TheC,
                compound_nodes: Boolean,
        },
    ) {
        const tree = syntaxTree(state)
        if (!tree || tree.length === 0) return

        const doc = state.doc

        // Walk Line-by-Line. tree.iterate() with a range enters Lines whose
        // span intersects [from..to]. For each Line we gather its nodes +
        // text-boundary splits locally, then i() them as Line/node, Line/text.
        //
        // Two parallel sequences under each Line, both ordered by `from`:
        //   Line/node:Foo, Line/node:Bar, ...
        //   Line/text:{...}, Line/text:{...}, ...
        //
        // We don't nest nodes structurally here (flat under Line) — that
        // matches the request's "Line/node:Sunpitness/node:IOpath" ideal
        // being a later extension, while keeping dedup trivial for now.

        // Collect Lines in range first so we can set up per-Line boundary sets.
        //
        // tree.iterate with a range is too permissive — it can enter a Line
        // whose `from` equals our `opt.to` (or whose `to` equals `opt.from`),
        // pulling in the neighbouring Line. Apply a strict intersection filter
        // after collecting: a Line must satisfy `line.from < opt.to` AND
        // `line.to > opt.from` with strict inequality both ways. This is the
        // standard open-interval intersection test and correctly excludes
        // Lines that just abut our range.
        const line_entries: Array<{ line_from: number, line_to: number }> = []
        tree.iterate({
            from: opt.from,
            to:   opt.to,
            enter: (ref) => {
                if (ref.name === 'Line') {
                    if (ref.from < opt.to && ref.to > opt.from) {
                        line_entries.push({ line_from: ref.from, line_to: ref.to })
                    }
                }
            },
        })

        // Handle the degenerate case where the selection is zero-width and
        // falls between Lines — fall back to the containing Line.
        if (!line_entries.length) {
            const line = doc.lineAt(opt.from)
            line_entries.push({ line_from: line.from, line_to: line.to })
        }

        for (const { line_from, line_to } of line_entries) {
            // Key LineC by doc line number — Lezer may emit several "Line" nodes per
            // doc line (one per statement/expression). Visually they must converge
            // on one L<n> compound. Multiple Lezer-Line hits on the same doc line
            // reinforce the same LineC; we remember the full doc-line span for
            // callers that want a concrete range.
            const docLine = doc.lineAt(line_from)
            // < should really include all these properties in the .oai(), once?
            //    paranoid mode: blow up on subsequent calls if c arg isn't as the found LineC is
            //   as it is we don't index properties set on sc after the .oai(),
            //    but because of the way we only use the index for the first column,
            //     any o %Line,* will work since Line is indexed in the call to .oai() / .i()
            const LineC = model.oai({ Line: docLine.number }, {
                line_from: docLine.from,
                line_to: docLine.to,
            })

            // Tag this Line with the bookmark id — may already be tagged by
            // a prior bookmark. Tags come and go across ticks via replace().
            LineC.sc[opt.bm_key] = 1

            // line_number = the actual document line number, so sorting by
            // it always puts Lines in doc order regardless of which bookmark
            // created them first.
            LineC.sc.line_number = docLine.number
            LineC.sc.label       = `L${docLine.number}`

            // containium flag — tells Cyto this particle is a compound node
            // that visually wraps its model-children (the text/node particles
            // oai'd onto this LineC below). Cyto's supports_constraints path
            // reads this to set isCompound in cyto_nstyle.
            if (opt.compound_nodes) LineC.sc.containium = 1

            LineC.bump_version()

            // Gather syntax nodes + text boundaries within this Line.
            //
            // For each syntax hit we also capture parent_name / parent_from /
            // parent_to so wherewhatis can find the parent node by address
            // (two different hits in one Line could share a name — address
            // is the only reliable identifier).
            const boundaries = new Set<number>([line_from, line_to])
            const syntax_hits: Array<{
                name: string, from: number, to: number,
                parent_name?: string, parent_from?: number, parent_to?: number,
            }> = []

            tree.iterate({
                from: line_from,
                to:   line_to,
                enter: (ref) => {
                    const { name, from, to } = ref
                    if (name === 'Program' || name === 'Line') return
                    const str = doc.sliceString(from, to)
                    if (!str.trim()) return
                    boundaries.add(from)
                    boundaries.add(to)
                    const parent = ref.node.parent
                    const hasParent = parent && parent.name !== 'Line' && parent.name !== 'Program'
                    syntax_hits.push({
                        name, from, to,
                        parent_name: hasParent ? parent.name : undefined,
                        parent_from: hasParent ? parent.from : undefined,
                        parent_to:   hasParent ? parent.to   : undefined,
                    })
                },
            })

            // i() nodes under Line with stable keys for dedup across bookmarks.
            for (const h of syntax_hits) {
                const nodeC = LineC.oai({ node: h.name, from: h.from, to: h.to })
                const s = doc.sliceString(h.from, h.to)
                if (s.length <= 120 && nodeC.sc.str == null) nodeC.sc.str = s
                if (h.parent_name && nodeC.sc.parent_name == null) {
                    nodeC.sc.parent_name = h.parent_name
                    nodeC.sc.parent_from = h.parent_from
                    nodeC.sc.parent_to   = h.parent_to
                }
            }

            // text segments between boundaries, also direct children of Line.
            // Each gets an `order` index (0-based L→R) and measured dimensions.
            const sorted = [...boundaries].sort((a, b) => a - b)
            for (let i = 0; i < sorted.length - 1; i++) {
                const f = sorted[i], t = sorted[i + 1]
                const s = doc.sliceString(f, t)
                if (!s.trim()) continue
                const tC = LineC.oai({ text: 1, from: f, to: t })
                if (tC.sc.str == null) tC.sc.str = s

                // measure for Cyto node sizing — monospace at 12px
                const m = this.measureText(s, 12)
                tC.sc.measured_width  = m.width
                tC.sc.measured_height = m.height

                tC.bump_version()
            }

            // Re-assign order for ALL text children of this Line in one pass,
            // sorted by from — this is idempotent and correct even when
            // multiple bookmarks contribute boundaries to the same line.
            const allTexts = (LineC.o({ text: 1 }) as TheC[])
                .sort((a, b) => (a.sc.from as number) - (b.sc.from as number))
            for (let idx = 0; idx < allTexts.length; idx++) {
                allTexts[idx].sc.order = idx
            }
        }
    },


//#region constraints
    // wherewhatis(model: TheC): void
    //
    // Emits constraints + edges grouped into cyto_fold buckets so they don't
    // drown the flat model tree.  Each fold is `{cyto_fold:1, mode:'cyto_fold',
    // label:<purpose>}` and is classified as invisible by cytyle_classify —
    // Cyto walks through it (children still produce constraints) but nothing
    // is drawn for the fold itself.
    //
    // Folds emitted (all direct children of `model`):
    //   pose_Lines        — Lines stack vertically, left-edge alignment
    //   flow_Lh_<n>       — one per Line: Line→text[0] and text[i]→text[i+1]
    //                       horizontal chain + baseline alignment
    //   nodes_over_text_<n> — one per Line: syntax node above its best-overlap
    //                        text segment, annotation edges
    //   syntax_parent_<n> — one per Line: child syntax node → parent syntax node
    //                       edges (the hierarchy that used to be implicit)

    wherewhatis(model: TheC) {
        const lines = (model.o({ Line: 1 }) as TheC[])
            .sort((a, b) => (a.sc.line_number as number) - (b.sc.line_number as number))
        const nonCompoundLines = lines.filter(L => !L.sc.containium)

        if (nonCompoundLines.length > 1) {
            // align doesn't work on compound nodes
            let someLines = nonCompoundLines

            // first-text per Line cached for use in pose_Lines (redundant vertical
            // ordering + left-alignment of the actual code gutter).
            const first_text_of_line = new Map<TheC, TheC>()
            for (const L of someLines) {
                const texts = (L.o({ text: 1 }) as TheC[])
                    .sort((a, b) => (a.sc.order as number) - (b.sc.order as number))
                if (texts.length) first_text_of_line.set(L, texts[0])
            }
        
            // ── FOLD: pose_Lines ─────────────────────────────────────────
            // Vertical stacking of Lines (both on the Line marker AND on
            // the first text of each Line — redundant constraints give fcose
            // more to go on, which usually simplifies the solve).
            // Left-edge alignment keeps the code gutter straight.
            const pose = model.i({ cyto_fold: 1, mode: 'cyto_fold', label: 'pose_Lines' })
            for (let i = 0; i < someLines.length - 1; i++) {
                pose.i({
                    cyto_cons: 1,
                    label: `lineMarkV${i}`,
                    type: 'relativePlacementConstraint',
                    axis: 'vertical',
                    gap: 8,
                    top: someLines[i],
                    bottom: someLines[i + 1],
                })
                const ta = first_text_of_line.get(someLines[i])
                const tb = first_text_of_line.get(someLines[i + 1])
                if (ta && tb) {
                    pose.i({
                        cyto_cons: 1,
                        label: `txtRowV${i}`,
                        type: 'relativePlacementConstraint',
                        axis: 'vertical',
                        gap: 8,
                        top: ta,
                        bottom: tb,
                    })
                }
            }
            pose.i({
                cyto_cons: 1,
                label: `linesAlignV×${someLines.length}`,
                type: 'alignmentConstraint',
                axis: 'vertical',   // vertical alignment = same X position
                nodes: [...someLines],
            })
            // also left-align all first-texts so the code column is straight
            const firsts = someLines.map(L => first_text_of_line.get(L)).filter(Boolean) as TheC[]
            if (firsts.length > 1) {
                pose.i({
                    cyto_cons: 1,
                    label: `txtFirstsAlignV×${firsts.length}`,
                    type: 'alignmentConstraint',
                    axis: 'vertical',
                    nodes: firsts,
                })
            }

            // later comes a nodes-above-text, which is useful in %containium too
            //  keeps syntax nodes in the space between two lines
            const syntaxBelow = model.i({
                cyto_fold: 1,
                mode: 'cyto_fold',
                label: 'syntax_nodes_below_lines',
            });
            for (let i = 0; i < lines.length - 1; i++) {
                const line = lines[i];
                const nextLine = lines[i + 1];
                const syntaxNodes = nextLine.o({ node: 1 }) as TheC[];

                if (syntaxNodes.length > 0) {
                    syntaxBelow.i({
                        cyto_cons: 1,
                        label: `syntaxBelowLine${i}`,
                        type: 'relativePlacementConstraint',
                        axis: 'vertical',
                        gap: 20, // Adjust as needed
                        top: line,
                        bottom: syntaxNodes[0], // Place first syntax node below the line
                    });
                }
            }
        }

        // Per-Line folds
        for (const line of lines) {
            const textSegments = (line.o({ text: 1 }) as TheC[])
                .sort((a, b) => (a.sc.order as number) - (b.sc.order as number))
            const nodes = line.o({ node: 1 }) as TheC[]
            const line_n = line.sc.line_number as number

            // When the Line is a containium (compound in Cyto), its text and
            // node children are nested inside its compound box — placing the
            // Line horizontally relative to its own child (or aligning it on Y
            // with its own child) is circular and fcose doesn't handle it.
            // So in containium mode we skip those Line-involving constraints
            // and let the compound layout + inner text constraints do the job.
            const line_is_compound = !!line.sc.containium

            // ── FOLD: flow_Lh_<n> ─────────────────────────────────────
            // Text segments form a horizontal row within the Line. When the
            // Line is NOT compound, the Line marker sits left of text[0]
            // on a shared baseline; when it IS compound, it just contains
            // them and we only constrain the inner text chain.
            const flow = model.i({
                cyto_fold: 1, mode: 'cyto_fold',
                label: `flow_Lh_${line_n}`,
            })

            if (!line_is_compound && textSegments.length > 0) {
                // Line marker sits left of first text, same baseline.
                flow.i({
                    cyto_cons: 1,
                    label: 'lineToText',
                    type: 'relativePlacementConstraint',
                    axis: 'horizontal',
                    gap: 12,
                    left: line,
                    right: textSegments[0],
                })
                // thin edge: Line marker → first text, visual anchor
                flow.oai({
                    cyto_edge: 1,
                    line_text_edge: 1,
                    the_line: line_n,
                }, {
                    source: line,
                    target: textSegments[0],
                    label:  '',
                    style: {
                        'line-color': '#222',
                        width: 0.8,
                        'curve-style': 'bezier',
                        opacity: 0.5,
                        'target-arrow-shape': 'none',
                    },
                })
            }

            // Text chain: text[i] → text[i+1]
            for (let i = 0; i < textSegments.length - 1; i++) {
                flow.i({
                    cyto_cons: 1,
                    label: `txtH${i}`,
                    type: 'relativePlacementConstraint',
                    axis: 'horizontal',
                    gap: 4,  // tight spacing between code tokens
                    left: textSegments[i],
                    right: textSegments[i + 1],
                })
                // thin edge connecting adjacent text segments
                flow.oai({
                    cyto_edge: 1,
                    text_chain_edge: 1,
                    the_line: line_n,
                    the_order: i,
                }, {
                    source: textSegments[i],
                    target: textSegments[i + 1],
                    label: '',
                    style: {
                        'line-color': '#1a1a1a',
                        width: 0.6,
                        'curve-style': 'bezier',
                        opacity: 0.35,
                        'target-arrow-shape': 'none',
                    },
                })
            }

            // Texts share Y baseline. Include the Line marker only when it's
            // NOT a compound (including a compound alongside its own children
            // in a horizontal alignment produces circular constraints).
            const row_members = line_is_compound
                ? textSegments
                : [line, ...textSegments]
            if (row_members.length > 1) {
                flow.i({
                    cyto_cons: 1,
                    label: `rowBaseH×${row_members.length}`,
                    type: 'alignmentConstraint',
                    axis: 'horizontal',   // shared Y
                    nodes: row_members,
                })
            }

            // ── FOLD: nodes_over_text_<n> ─────────────────────────────
            // Each text segment gets an annotation edge from the single
            // deepest syntax node that overlaps it — NOT from every
            // overlapping ancestor. Ancestors reach the text via the
            // parent-chain edges in the syntax_parent fold below, so
            // the visual chain reads: ancestor → ... → deepest → text.
            //
            // Rule: for each text segment, find syntax nodes whose span
            // overlaps it, and pick the one with the smallest span
            // (span = to - from). A smaller span means deeper in the
            // Lezer tree (children are always contained by parents).
            // Ties are broken by deeper parent-chain depth.
            const over = model.i({
                cyto_fold: 1, mode: 'cyto_fold',
                label: `nodes_over_text_${line_n}`,
            })

            // parent-chain depth for each node — 0 for roots, +1 per parent.
            // Used as tiebreaker when two nodes share a span (eg Leg:x and
            // Name:x both at [44..51]).
            const depth_of = (nd: TheC): number => {
                let d = 0
                let cur: TheC | undefined = nd
                const seen = new Set<TheC>()   // cycle guard — shouldn't happen but cheap
                while (cur && !seen.has(cur)) {
                    seen.add(cur)
                    const pn = cur.sc.parent_name as string | undefined
                    const pf = cur.sc.parent_from as number | undefined
                    const pt = cur.sc.parent_to   as number | undefined
                    if (!pn || pf == null || pt == null) break
                    const parent = nodes.find(m =>
                        m.sc.node === pn && m.sc.from === pf && m.sc.to === pt
                    )
                    if (!parent) break
                    d++
                    cur = parent
                }
                return d
            }

            for (const ts of textSegments) {
                // find all overlapping syntax nodes
                const candidates: Array<{ nd: TheC, span: number, depth: number }> = []
                for (const nd of nodes) {
                    if (!this.range_overlaps(nd.sc,ts.sc)) continue
                    candidates.push({
                        nd,
                        span: nd.sc.to - nd.sc.from,
                        depth: depth_of(nd),
                    })
                }
                if (!candidates.length) continue

                // sort: smaller span first, then deeper parent-chain first
                candidates.sort((a, b) => a.span - b.span || b.depth - a.depth)
                const chosen = candidates[0].nd

                // vertical: chosen node above its text (gap bigger than text→text)
                over.i({
                    cyto_cons: 1,
                    label: 'ndAbove',
                    type: 'relativePlacementConstraint',
                    axis: 'vertical',
                    gap: 10,
                    top: chosen,
                    bottom: ts,
                })

                // annotation edge: deepest-syntax-node → text it describes
                over.oai({
                    cyto_edge: 1,
                    annotation_edge: 1,
                    source_from: chosen.sc.from,
                    source_to:   chosen.sc.to,
                    source_name: chosen.sc.node,
                    target_from: ts.sc.from,
                }, {
                    source: chosen,
                    target: ts,
                    label:  chosen.sc.node ?? '',
                    gap:5,
                    style: {
                        'line-color': '#334',
                        width: 0.8,
                        'line-style': 'dotted',
                        'target-arrow-shape': 'none',
                        'curve-style': 'bezier',
                        opacity: 0.4,
                    },
                })

                // stack of syntax nodes above text containing them
                const containedSyntaxNodes: TheC[] = [];
                for (const nd of nodes) {
                    // Only consider syntax nodes contained by this text node
                    // if (ts.sc.str == "S " && nd.sc.str.startsWith("S ")) debugger
                    if (!this.range_contained(ts.sc,nd.sc)) continue;
                    containedSyntaxNodes.push(nd);
                }
                // Add a vertical alignment constraint for all contained syntax nodes
                if (containedSyntaxNodes.length) {
                    // if (containedSyntaxNodes.length != 1) debugger
                    over.i({
                        cyto_cons: 1,
                        label: `valign_contained_${ts.sc.from}`,
                        type: 'alignmentConstraint',
                        axis: 'vertical',
                        nodes: [ts,...containedSyntaxNodes],
                    });
                }
            }

            // ── FOLD: syntax_parent_<n> ───────────────────────────────
            // Parent-chain edges: child syntax node → parent syntax node
            // (using parent_from/parent_to to address the parent reliably,
            //  since two siblings could share a name within one Line).
            // Also places parent visually above child so the hierarchy
            // reads top-down.
            const parentFold = model.i({
                cyto_fold: 1, mode: 'cyto_fold',
                label: `syntax_parent_${line_n}`,
            })
            for (const nd of nodes) {
                const pn = nd.sc.parent_name as string | undefined
                const pf = nd.sc.parent_from as number | undefined
                const pt = nd.sc.parent_to   as number | undefined
                if (!pn || pf == null || pt == null) continue
                // find the parent node in this Line's nodes by address
                const parent = nodes.find(m =>
                    m.sc.node === pn && m.sc.from === pf && m.sc.to === pt
                )
                if (!parent) continue

                parentFold.oai({
                    cyto_edge: 1,
                    syntax_parent_edge: 1,
                    // Key must distinguish edges that share a `from` on both
                    // endpoints — e.g. IOpath[38..60] → Leg[38..43] and
                    // Leg[38..43] → Name[38..43] both have child_from=38 and
                    // parent_from=38 when you only look at `from`.  Adding
                    // child_to and parent_to makes each edge uniquely keyed.
                    child_from: nd.sc.from,
                    child_to:   nd.sc.to,
                    parent_from: pf,
                    parent_to:   pt,
                    parent_name: pn,
                }, {
                    source: parent,
                    target: nd,
                    label:  '',
                    style: {
                        'line-color': '#2a3a2a',
                        width: 0.9,
                        'target-arrow-shape': 'triangle',
                        'target-arrow-color': '#2a3a2a',
                        'curve-style': 'bezier',
                        opacity: 0.5,
                    },
                })

                // vertical ordering: parent above child (syntactic enclosure
                // reads top→bottom), but a tighter gap than node→text so
                // the parent chain compacts nicely above the code row.
                parentFold.i({
                    cyto_cons: 1,
                    label: 'parentAbove',
                    type: 'relativePlacementConstraint',
                    axis: 'vertical',
                    gap: 14,
                    top: parent,
                    bottom: nd,
                })
                // make syntax nodes look like a branch hanging rightwards
                // < causes a crash if used with: stack of syntax nodes above text containing them
                0 && parentFold.i({
                    cyto_cons: 1,
                    label: 'parentLeft',
                    type: 'relativePlacementConstraint',
                    axis: 'horizontal',
                    gap: 14,
                    left: parent,
                    right: nd,
                })
            }
        }
    },

    })
    })
</script>