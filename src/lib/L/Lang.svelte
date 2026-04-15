<script lang="ts">
    // Lang.svelte — ghost for Language / CodeMirror / Lezer integration.
    //
    // Deposits:
    //   whatsthis(state, container, {from?, to?})
    //     — walks the EditorState's Lezer parse tree and i()s TheC nodes
    //       (Line, node, texts, text) into `container`.
    //
    //     Caller owns container lifecycle — whatsthis never empties anything
    //     itself. Pass in a fresh subcontainer per logical scope (eg one per
    //     bookmark) so the caller can delete scopes as units.
    //
    //     opt.from / opt.to (optional) scope the walk via tree.iterate's
    //     range filter — Lezer only enters nodes whose span intersects
    //     [from, to]. Omitting them walks the whole doc.
    //
    // Consumed by w:LangTiles, which runs one whatsthis() call per w/%bookmark
    // into a per-bookmark subcontainer under model/**.

    import { _C, TheC } from "$lib/data/Stuff.svelte"
    import { syntaxTree } from "@codemirror/language"
    import type { EditorState } from "@codemirror/state"
    import { onMount, tick } from "svelte"

    import Langui from "$lib/O/ui/Langui.svelte"
    import type { House } from "$lib/O/Housing.svelte";
    import { EditorView } from "codemirror";

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region plan

    Lang_plan(A: House, w: TheC) {
        const H = this

        // ── the permanent viewable model ────────────────────────────
        // w/{model:1} — a stable TheC we hand to Cyto as Scannable.
        // i_elvis_req keyed on the req particle won't re-send while this
        // is the same object, so commissioning happens exactly once.
        const model = w.i({ model: 1 })
        w.c.model = model

        // UI registration — Otro mounts this alongside Cytui for H:Lang
        const uis = H.oai_enroll(H, { watched: 'UIs' })
        uis.oai({ UI: 'Langui', component: Langui })

        const wa = H.oai_enroll(H, { watched: 'actions' })
        wa.oai({ action: 1, role: 'debookmark'   },
             { label: '-marks', fn: () => this.Lang_debookmark(w) })
        wa.oai({ action: 1, role: 'enbookmark'   },
             { label: '+marks', fn: () => this.Lang_enbookmark(w) })

        // doc api — a single C on H.ave holding the whole document string.
        // UI pulls via H.ave.find(p => p.sc.langtiles_doc).sc.text
        // UI pushes via elvis 'langtiles_set_doc' → e_langtiles_set_doc below.
        const ave = H.oai_enroll(H, { watched: 'ave' })
        const docC = ave.oai({ langtiles_doc: 1 })
        if (docC.sc.text == null) {
            docC.sc.text = this.Lang_default_text()
            docC.bump_version()
        }
        w.c.docC = docC

        // ── reach across to Story's Styles ──────────────────────────
        // Story persists Styles under its w.c.The/{Styles:1}.
        // We call The_Styles(storyw) so we get the same TheC.
        // Story's watch_c on that bucket handles save-on-change for
        // edits made from either Cytui.
        const topH    = H.top_House()
        let stylesC: TheC | null = null
        try {
            const storyw = topH.o({H:'Story'})[0].Awo('Story', 'Story')
            stylesC = H.The_Styles(storyw)
        } catch {
            console.warn(`Lang: H:Story not present yet — Cyto will palette-fallback`)
        }

        // ── commission our own Cyto ─────────────────────────────────
        // Scannable = the permanent model C.
        // client_w  = w:Lang itself, so animation_done events come here.
        // No seek / takeTurns yet — this is the simple observer path.
        const commission = new TheC({ c: {}, sc: {
            Scannable:            w.c.model,
            Styles:               stylesC,
            client_w:             w,
            supports_constraints: true,
            supports_seek:        false,
            supports_takeTurns:   false,
            wants_wave_done:      false,
            wants_animation_done: false,
        }})
        // target our local A:Cyto/w:Cyto, not H:Story's
        H.elvisto(`Cyto/Cyto`, 'Cyto_commission', { req: commission })

        w.c.plan_done = true
    },
    Lang_default_text() {
        return `# yeti etc

i thung/with/etc

[y]
S o yeses/because/blon_itn
  yapto
  o figura/datch/#chang
`
    },

//#region e
    async e_Lang_editorBegins(A,w,e) {
        w.c.addBookmarkMark = e.sc.addBookmarkMark
        w.c.clearAllBookmarks = e.sc.clearAllBookmarks
        w.c.editorState = e.sc.state
        w.c.editorView = e.sc.view
        // this.post_do(async () => {
            await this.test__couple_of_bookmarks(A,w)
        // },{ see: 'onMount test__couple_of_bookmarks'})
    },
    async e_langtiles_set_doc(A: TheC, w: TheC, e: TheC) {
        if (!A.sc.A) debugger
        const docC = w.c.docC as TheC | undefined
        if (!docC) return
        const text = e?.sc.text as string | undefined
        if (text == null) return
        if (docC.sc.text === text) return
        docC.sc.text = text
        docC.bump_version()
        // no main() — UI initiated this, no one else needs waking
    },
//#region w:Lang
    // is actually w:LangTiles, the test, for now calling this.
    async Lang(A: TheC, w: TheC) {
        const H = this

        if (!w.c.plan_done) this.Lang_plan(A, w)

        const model     = w.c.model as TheC
        const state     = w.c.editorState
        const bookmarks = w.o({ bookmark: 1 }) as TheC[]

        // we do our best to send Cyto's Se1 a Line%* that trace all bookmark ids in it.
        //  so it can notice when Line 3 becomes Line 4 upon the user hitting enter
        model.empty()
        if (state && bookmarks.length) {
            this.whatsthis(state,model,bookmarks)
            this.wherewhatis(model)
        }

        w.i({ see: `🟦 tiles ${bookmarks.length} bookmarks` })
        H.elvisto('Cyto/Cyto', 'Cyto_animation_request', { Langy: 1 })
    },

    whatsthis(state:EditorState,model:TheC,bookmarks:TheC[]) {
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
            })
        }

        // Second pass: edge each bookmark to every Line it touches.
        // Lines carry the_bm_${id}:1 tags from whatsthis_into, so we
        // can find them by tag without re-walking the tree.
        for (const bm of bookmarks) {
            const bm_id = bm.sc.bookmark as string
            const bm_key = `the_bm_${bm_id}`
            // mirror the bookmark itself into the model so Cyto can
            // treat it as a node (and as edge endpoint)
            const bmC = model.oai({
                bookmark_node: 1,
                bm_id,
                label: bm.sc.label ?? '',
                from:  bm.sc.from,
                to:    bm.sc.to,
            })
            const Lines = model.o({ Line: 1 }).filter((L: TheC) => L.sc[bm_key])
            for (const L of Lines) {
                model.oai({
                    bookmark_edge: 1,
                    bm_id,
                    the_line_from: L.sc.Line,
                }, {
                    source: bmC,
                    target: L,
                    label:  '@',
                })
            }
        }
    },


//#region walk

    // whatsthis_into — dedup-friendly walker.
    //
    // Unlike the old whatsthis() which did bare .i() into a per-bookmark
    // subcontainer, this one uses oai() with stable keys so repeat walks
    // (same syntax span seen by two bookmarks) converge on the same TheC.
    //
    // Line addressing: {Line: from}  — doc position is the natural identity.
    // node addressing: {node: name, from, to} under its Line.
    // text addressing: {text: 1, from, to} under its Line.
    //
    // The bm_key tag (the_bm_${id}:1) is stamped on every Line this bookmark
    // touches, so multiple bookmarks on one Line coexist as multiple tags.
    whatsthis_into(
        state: EditorState,
        model: TheC,
        opt: { from: number, to: number, bm_id: string, bm_key: string, bm: TheC },
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
        const line_entries: Array<{ line_from: number, line_to: number }> = []
        tree.iterate({
            from: opt.from,
            to:   opt.to,
            enter: (ref) => {
                if (ref.name === 'Line') {
                    line_entries.push({ line_from: ref.from, line_to: ref.to })
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
            const LineC = model.oai({ Line: line_from, line_to })
            // Tag this Line with the bookmark id — may already be tagged by
            // a prior bookmark. Tags come and go across ticks via replace().
            LineC.sc[opt.bm_key] = 1
            LineC.bump_version()

            // Gather syntax nodes + text boundaries within this Line.
            const boundaries = new Set<number>([line_from, line_to])
            const syntax_hits: Array<{ name: string, from: number, to: number, parent_name?: string }> = []

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
                    syntax_hits.push({
                        name, from, to,
                        parent_name: (parent && parent.name !== 'Line' && parent.name !== 'Program')
                            ? parent.name : undefined,
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
                }
            }

            // text segments between boundaries, also direct children of Line.
            const sorted = [...boundaries].sort((a, b) => a - b)
            for (let i = 0; i < sorted.length - 1; i++) {
                const f = sorted[i], t = sorted[i + 1]
                const s = doc.sliceString(f, t)
                if (!s.trim()) continue
                const tC = LineC.oai({ text: 1, from: f, to: t })
                if (tC.sc.str == null) tC.sc.str = s
            }
        }
    },

//#region constraints
// wherewhatis(model: TheC): void
// Traverses the model, adds alignment constraints, and sets up text-node edges.

    // --- Main Traversal: wherewhatis ---
    wherewhatis(model: TheC) {
        const lines = model.o({ Line: 1 }) as TheC[];

        for (const line of lines) {
            const textSegments = line.o({ text: 1 }) as TheC[];
            const nodes = line.o({ node: 1 }) as TheC[];

            // Add vertical alignment constraint for the Line itself
            this.addAlignmentConstraint(model, [line], "vertical", "alignment");

            // Add horizontal alignment constraint for text segments
            if (textSegments.length > 1) {
                this.addAlignmentConstraint(model, textSegments, "horizontal", "alignment");
            }

            // Position nodes above their corresponding text
            for (let i = 0; i < Math.min(textSegments.length, nodes.length); i++) {
                const textNode = textSegments[i];
                const node = nodes[i];

                // Add edge between text node and specific descendant node
                if (node.sc.str?.includes("Sunpit") && textNode.sc.str?.startsWith("S")) {
                    this.addTextNodeEdge(model, textNode, node, "S");
                } else if (node.sc.str?.includes("IOpath") && textNode.sc.str?.includes("/")) {
                    this.addTextNodeEdge(model, textNode, node, "/");
                } else {
                    this.addTextNodeEdge(model, textNode, node);
                }

                // Add vertical alignment constraint for node above text
                this.addAlignmentConstraint(model, [node, textNode], "vertical", "relativePlacement", 16);
            }
        }

        // Global horizontal alignment for Lines
        if (lines.length > 1) {
            this.addAlignmentConstraint(model, lines, "horizontal", "alignment");
        }
    },

    // --- Alignment Constraint Helpers ---
    addAlignmentConstraint(
        model: TheC,
        nodes: TheC[],
        axis: "horizontal" | "vertical",
        type: "alignment" | "relativePlacement",
        gap?: number
    ) {
        const constraintType = type === "alignment" ? "alignmentConstraint" : "relativePlacementConstraint";
        const constraint = model.oai({
            constraint: 1,
            type: constraintType,
            axis,
            gap: gap ?? 32,
        });

        if (type === "alignment") {
            constraint.sc.nodes = nodes; // Store node objects
        } else {
            constraint.sc[axis === "vertical" ? "top" : "left"] = nodes[0];
            constraint.sc[axis === "vertical" ? "bottom" : "right"] = nodes[nodes.length - 1];
        }
    },

    // --- Text-Node Edge Helper ---
    addTextNodeEdge(
        model: TheC,
        textNode: TheC,
        node: TheC,
        label: string = "te"
    ) {
        model.oai({
            edge: 1,
            source: textNode,
            target: node,
            label,
            style: { "line-color": "#4488ff", width: 1.2, "curve-style": "bezier" },
        });
    },












//#region bm
    // onMount() ONLY, automate the test

    async Lang_enbookmark(w) {
        const view = w.c.editorView
        this.elvisto('LangTiles/LangTiles', 'test__couple_of_bookmarks')
    },
    async Lang_debookmark(w) {
        const view = w.c.editorView
        if (view && w.c.clearAllBookmarks) {
            view.dispatch({ effects: w.c.clearAllBookmarks.of(null) })
        }
        await w.r({ bookmark: 1 },{})
        this.elvisto(w, 'think', {})
    },
    async e_test__couple_of_bookmarks(A,w,e) {
        await this.test__couple_of_bookmarks(A,w)
    },
    async test__couple_of_bookmarks(A,w) {
        // Get the editor view from the state
        const view = w.c.editorView
        // < why did AI want to:
        // view =  w.c.editorState?.field(EditorView) as EditorView | undefined;
        if (!view) throw new Error("No editor view found");
        await new Promise((resolve) => setTimeout(resolve, 30));
        await tick();

        // Function to add a bookmark via elvis
        const addBookmark = (from, to) => {
            const label = view.state.doc.sliceString(from, to).slice(0, 24).replace(/\s+/g, ' ');
            this.elvisto('LangTiles/LangTiles', 'langtiles_add_bookmark', {
                from,
                to,
                label,
                view,
                state: view.state,
            });
        };

        // Add first bookmark (38..51)
        view.dispatch({
            selection: { anchor: 38, head: 51 },
        });
        await tick();
        addBookmark(38, 51);

        // Add second bookmark (55..55)
        view.dispatch({
            selection: { anchor: 55, head: 55 },
        });
        await tick();
        addBookmark(55, 55);
    },


//#region bm e
    // Ctrl+B from the editor — create a w/%bookmark at the current selection.
    //
    // The editor marks the range with a CodeMirror Decoration.mark so from/to
    // track document edits automatically. Periodic e_langtiles_update_bookmarks
    // calls push the live mark positions (and a fresh editorState) back here.
    //
    // e.sc carries: from, to, label?, editorState
    async e_langtiles_add_bookmark(A: TheC, w: TheC, e: TheC) {
        let from  = e?.sc.from  as number | undefined;
        let to    = e?.sc.to    as number | undefined;
        const label = (e?.sc.label as string | undefined) ?? '';
        const view  = e?.sc.view  as EditorView | undefined;
        const state = e?.sc.state as EditorState | undefined;

        if (from == null || to == null || !view || !state) {
            console.warn("Missing required fields in e_langtiles_add_bookmark");
            return;
        }
        if (from === to) {
            const line = view.state.doc.lineAt(from);
            from = line.from;
            to = line.to;
        }
        const existingBookmark = w.o({ bookmark: 1 }).find((bm: TheC) =>
            bm.sc.from === from && bm.sc.to === to
        );
        if (existingBookmark) {
            console.log(`🔖 Bookmark already exists for [${from}..${to}]. Skipping.`);
            return;
        }

        // Add the bookmark to the editor
        const id = `bm_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 6)}`;
        view.dispatch({
            effects: w.c.addBookmarkMark.of({ id, from, to }),
        });

        // Update the backend
        w.i({ bookmark: id, from, to, label });
        w.c.editorState = state;
        console.log(`🔖 add_bookmark id=${id} [${from}..${to}] ${label}`);
        this.elvisto(w, 'think', {});
    },


    // Fired by the editor ~800ms after the most recent doc-change transaction.
    //
    // Carries the live from/to for every bookmark (the editor is the source of
    // truth for positions — CodeMirror remaps decoration marks on every change,
    // so we read them out and push here) plus a fresh editorState so the next
    // tick's whatsthis() walks see the updated parse tree.
    //
    // e.sc carries: updates=[{id, from, to}], editorState
    //
    // Bookmarks whose id isn't in updates[] are implicitly untouched — this
    // lets the editor also use this event to report "this bookmark's mark was
    // deleted" by simply omitting it. (Not yet consumed, but the shape allows
    // future pruning: compare w/%bookmark ids against updates[].id.)
    async e_langtiles_update_bookmarks(A: TheC, w: TheC, e: TheC) {
        if (!A.sc.A) debugger
        const updates = e?.sc.updates as Array<{ id: string, from: number, to: number }> | undefined
        const state   = e?.sc.state
        if (updates) {
            for (const u of updates) {
                const bm = w.o({ bookmark: u.id })[0] as TheC | undefined
                if (!bm) continue
                if (bm.sc.from === u.from && bm.sc.to === u.to) continue
                bm.sc.from = u.from
                bm.sc.to   = u.to
                bm.bump_version()
            }
        }
        if (state) w.c.editorState = state
        this.elvisto(w, 'think', {})
    },




    })
    })
</script>