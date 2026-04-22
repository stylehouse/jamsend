<script lang="ts">
    // Lang.svelte — ghost for Language / CodeMirror / Lezer integration.
    //
    // This is the high-level "join" ghost.  Most of the compilation guts live
    // in LangCompiling.svelte (Lang_compile / Lang_compile_step / …); Lang.svelte
    // keeps the per-tile lifecycle (plan / whatsthis / bookmark actions) and
    // threads the compile trigger + reply-polling into that lifecycle.
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
    import LangWhatwhere from "./LangWhatwhere.svelte";
    import LangCompiling from "./LangCompiling.svelte";
    import LangSion from "./LangSion.svelte";

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#region text measurement

    // ── measureText ──────────────────────────────────────────────────────
    // Monospace text measurement via OffscreenCanvas (or hidden canvas).
    // Returns { width, height } in px for a given string at a given font size.
    //
    // Since we use a monospace font, the per-char width is constant —
    // we cache the char width per fontSize and multiply by str.length.
    // Non-printable / tab chars get a fixed slot width.
    //
    // The measurement canvas is created once and reused across all calls.
    // Font: 'Berkeley Mono', 'Fira Code', monospace — same as Cytui.
    _measure_cache: {} as Record<number, number>,
    _measure_ctx: null as CanvasRenderingContext2D | null,

    measureText(str: string, fontSize = 12): { width: number, height: number } {
        if (!str) return { width: 0, height: 0 }

        if (!this._measure_ctx) {
            const canvas = document.createElement('canvas')
            canvas.width = 300; canvas.height = 40
            this._measure_ctx = canvas.getContext('2d')!
        }
        const ctx = this._measure_ctx
        const FONT = `${fontSize}px 'Berkeley Mono','Fira Code',monospace`

        let charW = this._measure_cache[fontSize]
        if (!charW) {
            ctx.font = FONT
            // measure a reference character — 'M' is widest in most fonts
            charW = ctx.measureText('M').width
            this._measure_cache[fontSize] = charW
        }

        // padding: 8px left + 8px right internal to the node
        const PAD = 16
        const width  = Math.ceil(str.length * charW) + PAD
        const height = Math.ceil(fontSize * 1.6) + 8  // line-height ~1.6 + vertical pad
        return { width, height }
    },

//#endregion
//#region plan

    async Lang_plan(A: House, w: TheC) {
        const H = this

        // ── the permanent viewable model ────────────────────────────
        // w/{model:1} — a stable TheC we hand to Cyto as Scannable.
        // i_elvis_req keyed on the req particle won't re-send while this
        // is the same object, so commissioning happens exactly once.
        const model = w.i({ model: 1, cyto_dir:1 })
        w.c.model = model

        // UI registration — Otro mounts this alongside Cytui for H:Lang
        const uis = H.oai_enroll(H, { watched: 'UIs' })
        uis.oai({ UI: 'Langui', component: Langui })

        const wa = H.oai_enroll(H, { watched: 'actions' })
        wa.oai({ action: 1, role: 'debookmark'   },
            { label: '-marks', fn: () => this.Lang_debookmark(w) })
        wa.oai({ action: 1, role: 'enbookmark'   },
            { label: '+marks', fn: () => this.Lang_enbookmark(w) })
        // compile trigger — translates the doc and writes the resulting
        // module to src/lib/gen/Somewhere.svelte via the Wormhole, then
        // notifies Pantheate.  Machinery provides Lang_compile.
        wa.oai({ action: 1, role: 'compile'      },
            { label: 'compile', fn: () => this.elvisto(w, 'Lang_compile') })

        // doc api — a single C on H.ave holding the whole document string.
        // UI pulls via H.ave.find(p => p.sc.langtiles_doc).sc.text
        // UI pushes via elvis 'Lang_set_doc' → e_Lang_set_doc below.
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
        return `// yeti etc
theCompiledStuff(A,w) {
    i hut/toot:3
    o hut/toot$
    let la = i hut/$toot
    o hut/although:1,they,can,be,mixed
    i $la/something
    i thung/with/etc
    i yeses/because,it:2
    i yeses/because,it:5

    [3]
    S o yeses/because
        let val = because.sc.it
        i figiura/datch:$val
    if 3
        i know
    if 0
        i dont/know
    elsif 1 && 0
        && 50
        i never/knew
    elsif 50 > 5
            && 3 > 2
        i helped
    i yep
}
`
    },

//#region e
    async e_Lang_editorBegins(A,w,e) {
        w.c.addBookmarkMark = e.sc.addBookmarkMark
        w.c.clearAllBookmarks = e.sc.clearAllBookmarks
        w.c.editorState = e.sc.state
        w.c.editorView = e.sc.view
        w.i({received:1,editorBegins:1})
    },
    async e_Lang_set_doc(A: TheC, w: TheC, e: TheC) {
        if (!A.sc.A) throw "!A"
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
        console.log(`Lang!`)

        if (!w.c.plan_done) await this.Lang_plan(A, w)
        // these go every time so their toggle state can visually change
        let on_change = () => this.main()
        await this.i_actions_to_c(w, 'compo',{ stashed: true, on_change })
        await this.i_actions_to_c(w, 'compi',{ stashed: true, on_change })

        // compile reply polling — if an earlier Lang_compile kicked off a
        // Wormhole rw_op 'write', Lang_compile_step re-polls i_elvis_req
        // here until the reply lands, then notifies Pantheate.
        if (w.oa({ Compile: 1 })) {
            await this.Lang_compile_step(A, w)
        }

        const model     = w.c.model as TheC
        const state     = w.c.editorState
        const opt       = {compound_nodes: !!w.c.compo}
        const bookmarks = w.o({ bookmark: 1 }) as TheC[]

        // we do our best to send Cyto's Se1 a Line%* that trace all bookmark ids in it.
        //  so it can notice when Line 3 becomes Line 4 upon the user hitting enter
        model.empty()
        if (state && bookmarks.length) {
            this.whatsthis(state,model,bookmarks,opt)
            this.wherewhatis(model,opt)
        }

        w.i({ see: `🟦 tiles ${bookmarks.length} bookmarks` })
        !H.sc.Run && 0 || H.elvisto('Cyto/Cyto', 'Cyto_animation_request', { Langy: 1 })
    },

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

        return;
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
                    cyto_edge: 1,
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
    // Helper function to check if r2 is contained by r1
    range_contained (r1: {from: number, to: number}, r2: {from: number, to: number}) {
        return r1.from <= r2.from && r1.to >= r2.to;
    },
    // Helper function to check if r2 overlaps r1
    range_overlaps (r1: {from: number, to: number}, r2: {from: number, to: number}) {
        return r1.from <= r2.to-1 && r1.to-1 >= r2.from;
    },



//#region caving

    caving() {
        ` // < this
system of diving into spaces that are developing
 for slowly opening a hive of realities into one over-place
  floating through the landscape of eg assail()
   dealing with some of the language across it all
 this shall be the collective attentions at things
 generalisable tech
  basically deriving openness from journey, see Dierarchy
   and that openness affects whatever its connected to, perhaps
    pigmenting? now with the html overlay each node can have crazy details
     to be more human readable while being a dense cluster of info

uses:

in this first use of this possibly generalisable tech
 we shall split the text by indent
  which promotes leaders
  which have among them more and less novel text... see assail()
 and give Wip, similar to Dip
  it implies ordering
   if we want to put something before 1.1,
    we put it at 1.1.0.1
    another at "before 1.1" at 1.1.0.2
     then something before that at 1.1.0.2.0.1
   but why?
    I cant remember right now.
  the dialectics these Wip schemes exist on should have the equivalent of
   Cyto_wipe
 
   
> for splitting types that emerge over time
 the shrine of types
 has a cell division process for eg a type of Se and what ever could be in it
  pieces of identity can go to one|both|neither of the new pair
 so those Se statements are collected and indexed somewhere.
  as would all the functions defined?
 
endless zooming through walls covered in code graffiti
 handles the open and close of the wormhole
 node gets bigger until it ruptures into being a very folded codemirror
  the folds look like paper planes crashed in from the right
  hovering along their tails projects|enlarges whats there behind it

having a new Cyto cluster spawn within (by location trickery) another
 and grow continuously like an embryo?
  panning through dimensions of being (clusters of language)
 so that each architectural subsystem of anything can be made to flash when executed,
  or reveal itself as a sentence|society momentarily
   in a hairball of over-connected everything with everySuch<->everySuch





 `

        
    },


//#region assail

    assail() {
        ` // < this
sauntering up to some code
 look at subsets of the objects (regions+funcs+calls) in eg Housing.svelte.ts
 > do lexing stemming and text search with sqlite?
 pull it apart with regexes?
    no time to parse every language
    keep scoped to one show grammar
    is my code as typescript AST hard to find function calls and definitions...?
    its got to learn how to learn a new language
 
collect all words, make them linkable to each other?
 even to see all 1915 ifs, a bundle of 113 ifs leading into src/lib/O/Housing.svelte.ts
 style the rare words as such

threads of inquiry stack up on the left
 there's a + button that spawns one where we are
  name after their start
  and then they'll wander off, looking at various things with varying intensity+duration
   or along them, perhaps.
 the most concrete representations should hover on the right, ie lines in places...
 the set of them we're looking at should roll over
  depending on how well tacked-down each thing is
 



 `

        
    },

//#region regroup

    regroup() {
        ` // < this
done:
 - Expression Translation, its Selection.process(), if ok can write the gen/*
 - Sunpit-as-iteration and pythonic indentation
todo:
 - Map building, persisting and exchanging the meaningful bits
definitely not in the next phase:
 - Sunpit as Travel underneath
 - all Sunpits contribute clues to the local Selection...
    Se/* becomes its configuration and state.


to continuously compile this code we're editing
 it should respond efficiently to changes by reusing whole unchanged chunks
perhaps we need loads of marks, on every Line, so we can see very well what changes?
 though we'll also be resolving changes often, in small batches
 the kind of thing diff-match-patch could be used for
  but codemirror can can give us the most efficient diffing between two states
   moreover there are times when we have several states from several events,
    which must have any data relative to each state
     eg the from,to position of something at some time
     translated into unison with the other states...
     like how our bookmarks are separate to codemirror
      so we have to sync their new positions
 the Map
  keep a bunch of the meaningful syntax in a Selection.process()
   which is function calls, io expressions
  brings in knowing what $lib/Ghost/* we are editing
   so Langui could expand a bit at this point.
    and CRUD a flat list of Ghosts to know.
    just a sorted dropdown, one option being +
     via action buttons with type=dropdown.
  to generate a Map.
   dexie tables of... items, calls, notes
   hold off interacting with the others yet
   and in fact this thing we're working on isn't on disk anywhere...
    which is how it's supposed to be.
    do a one-off write of src/lib/gen/Example.go
     I think it should misrepresent itself as being go to github's languages measurer.
  to tell if certain things come+go,
   eg use of a database table, which we could automatically add a bit of schema for
    since our schema definition will be in this society of objects we're maintaining
     and we can connect definitions to calls, etc, supposing we parse them as such later.

swap these i|o expressions for... something
 we will scale the complexity depending on how complex IOing** gets
 we can assume the first thing in the path is implied to be w for now,
  but not if it starts with just a variable:
   o $la/something ->  la.o({something:1})
  i lots/of/levels -> w.i({lots:1}).i({of:1}).i({levels:1})
  o lots/of/levels -> (w.o({lots:1})[0]?.o({of:1})[0]?.o({levels:1})||[])
  o thing -> w.o(thing)
 also allow
  o hut/toot$ -> let toot = o hut/toot  # gives toot the variable
  o hut/$toot -> hut.o({toot})          # takes toot the variable
  o hut/toot:3 -> hut.o({toot:3},{exactly:{toot:true}})
   turns off wildcard - for they could have just said /toot to mean any toot
    although:1,they,can,be,mixed (%although must == 1, others may be anything)
   note it looks like peel() format, but variables can:$be,in:$it

and put the resulting typescript ghost code (wrapped in eatfunc etc)
 via the Wormhole, into src/lib/gen/Somewhere.svelte
  and then notify a downstream at w:Pantheate
   includes it as %watched:UIs, and may do more later...



pythonic indent
  if oa thisQua -> if (w.oa({thisQua:1})) {   // and somewhere the closing brace

Sunpit
 the new lump of potentially non-trivial activity
 S <IOing>
  is iteration, heading of a pythonic-indented block
  becomes a for loop containing that IOing!








IOing
  Travel if multi-layered. inline a big json of of the path (as iooia can do) is the parsed version of the syntax.
    in the story_rule_matches format for it.

 wonder if it is possible to allow these two expr: C o walls | o C/walls
  it might be ambiguous, needing to not be so casually slipped into javascript.


 Se <IOing>
  as above but creates a named Selection() that can react to changes upstream etc
   persists as usual, use concretion() to begin (interrupts the w)
   perhaps initially it perhaps (approximately):
    Se i scan/i/$model -> w.oai(%Se:scan).i(%i).i(model)
   then:
    Se i scan/trace/D
        compose a D from an n
         "trace" sounds like it ends in sc
   and all other details could probably be wedged in somehow...
   so a Selection can be composed without the big fat calls
   potentially broken down into quite small parts
   the pieces as they are are embryos that could sprout a new limb anywhere



 `

        
    },


//#region whatsthis

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
            let text_order = 0
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
                tC.sc.order = text_order++

                tC.bump_version()
            }
        }
    },



//#region bm
    // onMount() ONLY, automate the test

    async Lang_enbookmark(w) {
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
        const addBookmark = async (from, to) => {
            view.dispatch({
                selection: { anchor: from, head: to },
            });
            await tick();
            const label = view.state.doc.sliceString(from, to).slice(0, 24).replace(/\s+/g, ' ');
            this.elvisto('LangTiles/LangTiles', 'Lang_add_bookmark', {
                from,
                to,
                label,
                view,
                state: view.state,
            });
        };

        // await addBookmark(73, 93); // line 5
        await addBookmark(98, 132); // line 6
    },


//#region bm e
    // Ctrl+B from the editor — create a w/%bookmark at the current selection.
    //
    // The editor marks the range with a CodeMirror Decoration.mark so from/to
    // track document edits automatically. Periodic e_Lang_update_bookmarks
    // calls push the live mark positions (and a fresh editorState) back here.
    //
    // e.sc carries: from, to, label?, editorState
    async e_Lang_add_bookmark(A: TheC, w: TheC, e: TheC) {
        let from  = e?.sc.from  as number | undefined;
        let to    = e?.sc.to    as number | undefined;
        const label = (e?.sc.label as string | undefined) ?? '';
        const view  = e?.sc.view  as EditorView | undefined;
        const state = e?.sc.state as EditorState | undefined;

        if (from == null || to == null || !view || !state) {
            console.warn("Missing required fields in e_Lang_add_bookmark");
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

        // Deterministic id keyed on position — same range always gets the same id,
        // so TheC keys and CodeMirror decoration ids survive reloads and round-trips.
        const id = `bm_${from}_${to}`;
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
    async e_Lang_update_bookmarks(A: TheC, w: TheC, e: TheC) {
        if (!A.sc.A) throw "!A"
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

<LangWhatwhere {M} />
<LangCompiling {M} />
<LangSion {M} />