<script lang="ts">
    // Lang.svelte — ghost for Language / CodeMirror / Lezer integration.
    //
    // This is the high-level "join" ghost.  Most of the compilation guts live
    // in LangCompiling.svelte (Lang_compile / Lang_compile_step / …); Lang.svelte
    // keeps the per-doc lifecycle (plan / whatsthis / bookmark actions) and
    // threads the compile trigger + reply-polling into that lifecycle.
    //
    // ── Document registry ────────────────────────────────────────────────────
    //
    //   w/{docs:1}/{doc:path} — one particle per open document.
    //     c: { view, state, addBookmarkMark, clearAllBookmarks, saveEffect,
    //          last_whatsthis_doc }
    //     sc: { doc:path, active:1? }
    //     {bookmark:'bm_…', from, to, label}
    //     {Compile:1}
    //       {Output:1, name, source, dige}
    //       {Pending:1}
    //
    //   Bookmarks and compile live on docC, not w, so they can be r()'d per doc.
    //
    // ── Reactive text sync ───────────────────────────────────────────────────
    //
    //   ave/{langtiles_doc:path} — one per doc, holds sc.text.
    //   Lang_plan seeds it with default text on first run.
    //   Langui (keyed by `doc` prop) watches its own particle.
    //
    // ── Active doc ───────────────────────────────────────────────────────────
    //
    //   w.c.active_doc_path — routing concern (not business state, not r()'able).
    //   Lang_active_docC(w) resolves it to the {doc:path} particle.
    //   Lang_set_active_doc(w, path) sets it and marks docC.sc.active.
    //
    // ── DRY state update ─────────────────────────────────────────────────────
    //
    //   All CM events carry { doc:path, view, state } in e.sc.
    //   Lang_doc_from_event(w, e) finds-or-creates the docC particle and
    //   writes docC.c.view / docC.c.state in exactly one place — eliminating
    //   the scattered w.c.editorState = e.sc.state pattern.
    //
    // ── whatsthis cache ──────────────────────────────────────────────────────
    //
    //   docC.c.last_whatsthis_doc — the EditorState.doc rope from the last
    //   whatsthis() call.  CM doc ropes are immutable value objects; identity
    //   equality is O(1) and reliable.  Skipped when doc and bookmarks haven't
    //   changed since last tick.
    //
    // ── Deposits ─────────────────────────────────────────────────────────────
    //
    //   whatsthis(state, container, bookmarks, opt)
    //     — walks the EditorState's Lezer parse tree and i()s TheC nodes
    //       (Line, node, texts, text) into `container`.
    //
    // Consumed by w:Lang, which runs one whatsthis() call per w/%bookmark
    // into a per-bookmark subcontainer under model/**.

    import { _C, TheC } from "$lib/data/Stuff.svelte"
    import { syntaxTree } from "@codemirror/language"
    import type { EditorState } from "@codemirror/state"
    import { onMount, tick } from "svelte"

    import Langui from "$lib/O/Langui.svelte"
    import type { House } from "$lib/O/Housing.svelte";
    import { EditorView } from "codemirror";
    import LangWhatwhere from "./LangWhatwhere.svelte";
    import LangCompiling from "./LangCompiling.svelte";
    import LangSion from "./LangSion.svelte";
    import LangRegions from "./LangRegions.svelte";

    let { M } = $props()

    onMount(async () => {
    await M.eatfunc({

//#endregion
//#region plan

    async Lang_plan(A: House, w: TheC) {
        const H = this

        // ── the permanent viewable model ────────────────────────────
        // w/{model:1} — a stable TheC we hand to Cyto as Scannable.
        const model = w.i({ model: 1, cyto_dir:1 })
        w.c.model = model

        // UI registration — Otro mounts this alongside Cytui for H:Lang
        const uis = H.oai_enroll(H, { watched: 'UIs' })
        uis.oai({ UI: 'Langui' }, { component: Langui })

        const wa = H.oai_enroll(H, { watched: 'actions' })
        wa.oai({ action: 1, role: 'debookmark'   },
            { label: '-marks', fn: () => this.Lang_debookmark(w) })
        wa.oai({ action: 1, role: 'enbookmark'   },
            { label: '+marks', fn: () => this.Lang_enbookmark(w) })
        // compile trigger — translates the doc and writes the resulting
        // module to src/lib/gen/Somewhere.svelte via the Wormhole, then
        // notifies Pantheate.  Machinery provides Lang_compile.
        wa.oai({ action: 1, role: 'compile'      },
            { label: 'compile', fn: () => this.i_elvisto(w, 'Lang_compile') })

        // ── doc registry ────────────────────────────────────────────
        // w/{docs:1} — container for all open document particles.
        // Individual {doc:path} particles are created lazily via
        // e_Lang_open_doc when Lies hands us a loaded file.
        w.oai({ docs: 1 })

        // ── reach across to Story's Styles ──────────────────────────
        // Story persists Styles under its w.c.The/{Styles:1}.
        // We call The_Styles(storyw) so we get the same TheC.
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
        H.i_elvisto(`Cyto/Cyto`, 'Cyto_commission', { req: commission })

        w.c.plan_done = true
    },

//#region doc routing helpers

    // ── Lang_doc_from_event ──────────────────────────────────────────────────
    //
    //   DRY central router called at the top of every CM event handler.
    //   Every event from Langui carries { doc:path, view, state } in e.sc.
    //   This creates-or-finds the {doc:path} particle under w/{docs:1} and
    //   updates docC.c.view / docC.c.state in exactly one place.
    //
    //   Returns the docC so the caller can operate on it directly.
    Lang_doc_from_event(w: TheC, e: TheC): TheC {
        // e.sc.doc is stamped by Langui's Lang_i_elvis on every CM-sourced event.
        // Internally-fired events (e.g. e_Lang_i_bookmark → Lang_add_bookmark,
        // or automated test macros) don't go through Langui, so fall back to
        // the active doc — which is always the right target in that case.
        const path = (e.sc.doc as string) || (w.c.active_doc_path as string)
        if (!path) throw 'Lang_doc_from_event: no doc and no active doc yet'
        const docs = w.oai({ docs: 1 })
        const docC = docs.oai({ doc: path })
        // update view + state in exactly one place
        if (e.sc.view)  docC.c.view  = e.sc.view
        if (e.sc.state) docC.c.state = e.sc.state
        return docC
    },

    // ── Lang_active_docC ─────────────────────────────────────────────────────
    //
    //   Returns the {doc:path} particle for the currently active doc, or
    //   undefined if no doc has been registered yet (pre-editorBegins).
    Lang_active_docC(w: TheC): TheC | undefined {
        const path = w.c.active_doc_path as string | undefined
        if (!path) return undefined
        const docs = w.o({ docs: 1 })[0] as TheC | undefined
        return docs?.o({ doc: path })[0] as TheC | undefined
    },

    // ── Lang_set_active_doc ──────────────────────────────────────────────────
    //
    //   Marks a path as active. Stamps docC.sc.active so a tabs UI can see
    //   which doc is foregrounded, and updates ave/{active_doc:1}.path so
    //   Langui can reactively switch its EditorView to the right content
    //   without needing to know the path at mount time.
    Lang_set_active_doc(w: TheC, path: string) {
        w.c.active_doc_path = path
        const docs = w.o({ docs: 1 })[0] as TheC | undefined
        if (docs) {
            for (const d of docs.o({ doc: 1 }) as TheC[]) {
                if (d.sc.doc === path) d.sc.active = 1
                else delete d.sc.active
            }
        }
        // ave/{active_doc:1} is the reactive signal Langui watches to know
        // which ave/{langtiles_doc:path} particle to pull text from.
        const ave = (this as House).oai_enroll(this as House, { watched: 'ave' })
        const sig = ave.oai({ active_doc: 1 })
        sig.sc.path = path
        sig.bump_version()
    },

//#region e

    async e_Lang_editorBegins(A, w, e) {
        // Register view + state via the DRY router.
        const docC = this.Lang_doc_from_event(w, e)

        // CM StateEffects are per-view, so they live on docC.c — not w.c.
        docC.c.addBookmarkMark   = e.sc.addBookmarkMark
        docC.c.removeBookmarkMark = e.sc.removeBookmarkMark
        docC.c.clearAllBookmarks = e.sc.clearAllBookmarks
        docC.c.saveEffect        = e.sc.saveEffect

        // Only activate if we have a real path — empty string means the doc
        // isn't known yet and Lies hasn't fired e_Lang_open_doc yet.
        // The $effect in Langui re-fires editorBegins once active_path is real.
        if (!w.c.active_doc_path && e.sc.doc) {
            this.Lang_set_active_doc(w, e.sc.doc as string)
        }

        w.i({received:1,editorBegins:1})
    },

    // ── e_Doc_open ───────────────────────────────────────────────────────────
    //
    //   Fired by Liesui / Waft / DocRow when the user clicks a Doc label or a
    //   Point inside one.  Switches the active doc to `path`.
    //
    //   e.sc.point (optional) — the Point value to navigate to once the doc is
    //   active.  Finding + scrolling to it is handled here on the w:Lang side;
    //   the UI just passes the raw Point sc value and forgets about it.
    //
    //   e.sc: { path, point? }
    async e_Doc_open(A: TheC, w: TheC, e: TheC) {
        const path  = e.sc.path  as string | undefined
        const point = e.sc.point as string | undefined
        if (!path) return

        // Switch active doc — Langui's $effect on ave/{active_doc:1} reacts.
        this.Lang_set_active_doc(w, path)

        // Point navigation: resolve the point spec against the compiled methods
        // index, apply region-based openness (fold/unfold), and scroll the view.
        // e_Lang_point_navigate (in LangRegions) handles the full cycle and
        // reports issues back to Lies via e:Lies_point_issues.
        if (point) {
            this.i_elvisto('Lang/Lang', 'Lang_point_navigate', { point, doc: path })
        }

        this.i_elvisto(w, 'think')
    },

    // ── e_Lang_open_doc ──────────────────────────────────────────────────────
    //
    //   Called by Lies after it loads a Ghost source file.
    //   Creates the docC particle under w/{docs:1}, populates the ave
    //   text-sync particle so Langui pulls the content, and sets this doc
    //   as the active one.
    //
    //   gen_path is optional — if absent the doc can be soft-compiled
    //   (abstractions extracted) but the result is not written to disk.
    //
    //   e.sc: { path, text, gen_path? }
    async e_Lang_open_doc(A: TheC, w: TheC, e: TheC) {
        const H = this as House
        const path     = e.sc.path as string
        const gen_path = e.sc.gen_path as string | undefined   // optional
        const text     = (e.sc.text as string) ?? ''
        if (!path) throw 'e_Lang_open_doc: needs path'

        // create the docC particle; stamp gen_path only when present
        const docs = w.oai({ docs: 1 })
        const docC = docs.oai({ doc: path })
        if (gen_path) docC.sc.gen_path = gen_path

        // populate the ave text-sync particle so Langui pulls it
        const ave = H.oai_enroll(H, { watched: 'ave' })
        const docTextC = ave.oai({ langtiles_doc: path })
        if (docTextC.sc.text !== text) {
            docTextC.sc.text = text
            docTextC.bump_version()
        }

        // always activate — Lies owns doc order, last open wins for now
        this.Lang_set_active_doc(w, path)

        w.i({ received: 1, doc_opened: 1, doc: path })
        console.log(`📄 Lang opened doc: ${path}`)
    },

    async e_Lang_set_doc(A: TheC, w: TheC, e: TheC) {
        if (!A.sc.A) throw "!A"
        const path = e.sc.doc as string | undefined
        if (!path) return
        // update the ave text-sync particle for this doc path
        const ave = this.oai_enroll(this as House, { watched: 'ave' })
        const docTextC = ave.oai({ langtiles_doc: path })
        const text = e?.sc.text as string | undefined
        if (text == null) return
        if (docTextC.sc.text === text) return
        docTextC.sc.text = text
        docTextC.bump_version()
        // no main() — UI initiated this, no one else needs waking
    },

//#region w:Lang

    async Lang(A: TheC, w: TheC) {
        const H = this
        console.log(`Lang!`)

        if (!w.c.plan_done) await this.Lang_plan(A, w)
        // these go every time so their toggle state can visually change
        let on_change = () => this.main()
        await this.i_actions_to_c(w, 'compo',{ stashed: true, on_change })
        await this.i_actions_to_c(w, 'compi',{ stashed: true, on_change })

        const docC = this.Lang_active_docC(w)

        // compile reply polling — re-polls i_elvis_req while w/{docC}/Compile/Pending
        // is set; when the Wormhole reply lands, notifies Pantheate.
        if (docC?.oa({ Compile: 1 })) {
            await this.Lang_compile_step(A, w)
        }

        const model     = w.c.model as TheC
        const state     = docC?.c.state
        const opt       = {compound_nodes: !!w.c.compo}
        const bookmarks = (docC?.o({ bookmark: 1 }) ?? []) as TheC[]

        // ── whatsthis cache check ────────────────────────────────────
        // CM doc ropes are immutable — identity equality is O(1) and reliable.
        // docC.version covers everything on the doc particle: bookmark adds,
        // removes, position updates, compile state — no need to sum child
        // versions (they all start at 0 anyway, making a sum unreliable).
        const doc_unchanged  = state && state.doc === docC?.c.last_whatsthis_doc
        const docC_unchanged = docC?.version === docC?.c.last_docC_version

        model.empty()
        if (state && bookmarks.length && !(doc_unchanged && docC_unchanged)) {
            this.whatsthis(state, model, bookmarks, opt)
            this.wherewhatis(model, opt)
            if (docC) {
                docC.c.last_whatsthis_doc = state.doc
                docC.c.last_docC_version  = docC.version
            }
        }

        w.i({ see: `🟦 tiles ${bookmarks.length} bookmarks` })
        !H.sc.Run && 0 || H.i_elvisto('Cyto/Cyto', 'Cyto_animation_request', { Langy: 1 })
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
< &somefunc,A,w -> this.somefunc(A,w)
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

`

        
    },



//#region bm
    // onMount() ONLY, automate the test

    async Lang_enbookmark(w) {
        // +marks button: place a bookmark on line 6 via the generic handler
        this.i_elvisto('Lang/Lang', 'Lang_i_bookmark', { from: 98, to: 132 })
    },
    async Lang_debookmark(w) {
        const docC = this.Lang_active_docC(w)
        const view = docC?.c.view
        if (view && docC?.c.clearAllBookmarks) {
            view.dispatch({ effects: docC.c.clearAllBookmarks.of(null) })
        }
        // r() on the docC particle — bookmarks live there, not on w
        if (docC) await docC.r({ bookmark: 1 }, {})
        this.i_elvisto(w, 'think', {})
    },

    // ── e_Lang_i_bookmark ────────────────────────────────────────────────────
    //
    //   Generic Plan/Prep action: place a bookmark at a given char range.
    //   No action button — params must come from the Prep/esc children.
    //   from / to are char offsets into the doc.  If omitted or equal, the
    //   handler expands to the enclosing line (same as Ctrl+B on empty selection).
    async e_Lang_i_bookmark(A, w, e) {
        const docC = this.Lang_active_docC(w)
        const view = docC?.c.view
        if (!view) throw new Error("e_Lang_i_bookmark — no editor view")
        await new Promise(resolve => setTimeout(resolve, 30))
        await tick()

        let from = e?.sc.from as number | undefined
        let to   = e?.sc.to   as number | undefined
        // expand to enclosing line if range is absent or zero-width
        if (from == null || to == null || from === to) {
            const pos  = from ?? 0
            const line = view.state.doc.lineAt(pos)
            from = line.from
            to   = line.to
        }
        view.dispatch({ selection: { anchor: from, head: to } })
        await tick()
        const label = view.state.doc.sliceString(from, to).slice(0, 24).replace(/\s+/g, ' ')
        this.i_elvisto('Lang/Lang', 'Lang_add_bookmark', {
            from, to, label, view, state: view.state,
        })
    },

    // ── e_Lang_i_alterationStation ───────────────────────────────────────────
    //
    //   Generic Plan/Prep action: surgically replace a substring within a line.
    //   Operates within the existing text so CM can remap any bookmark decorations
    //   that span the edit — a whole-line replace would destroy them.
    //   No action button — params must come from the Prep/esc children:
    //
    //     Prep:4
    //       i_elvisto:Lang,e:Lang_i_alterationStation
    //         esc:line_n,v:6
    //         esc:sanity,v:    o hut/although:1,they,can,be,mixed
    //         esc:match,v:",they,can,be,mixed"
    //         esc:replacement,v:"/they,can,be,mixed"
    //
    //   line_n      — 1-based CodeMirror line number
    //   sanity      — expected full line text; warns on mismatch but still proceeds
    //   match       — JSON-encoded string: substring to find within that line (first occurrence)
    //   replacement — JSON-encoded string: what to replace it with (may be different length)
    //
    //   match and replacement are JSON-encoded so commas in values don't collide
    //   with the snap key:value,key:value delimiter format.
    async e_Lang_i_alterationStation(A, w, e) {
        const docC = this.Lang_active_docC(w)
        const view = docC?.c.view
        if (!view) throw new Error("e_Lang_i_alterationStation — no editor view")

        const line_n      = e?.sc.line_n      as number
        const sanity      = e?.sc.sanity      as string | undefined
        const match   = e?.sc.match       as string
        const replacement    = e?.sc.replacement as string
        if (!line_n || match == null || replacement == null)
            throw "e_Lang_i_alterationStation — needs line_n, match, and replacement"

        const line = view.state.doc.line(line_n)
        if (sanity != null && line.text !== sanity) {
            // warn but still proceed — test is re-runnable after the first replacement
            console.warn(`Lang_i_alterationStation — line ${line_n} sanity mismatch\n  expected: ${JSON.stringify(sanity)}\n  got:      ${JSON.stringify(line.text)}`)
        }

        const idx = line.text.indexOf(match)
        if (idx < 0) {
            console.warn(`Lang_i_alterationStation — match ${JSON.stringify(match)} not found in line ${line_n}: ${JSON.stringify(line.text)}`)
            return
        }

        // Surgical replace — CM remaps any decoration whose range spans this
        // position, so bookmarks within the line survive intact.
        // updateListener fires Lang_set_doc (docC updated) and arms the 800ms timer.
        view.dispatch({ changes: { from: line.from + idx, to: line.from + idx + match.length, insert: replacement } })

        // saveEffect flushes bookmark positions immediately — updateListener cancels
        // the debounce and fires Lang_update_bookmarks with the fresh editorState.
        view.dispatch({ effects: docC.c.saveEffect.of(null) })
        console.log(`Lang_i_alterationStation — line ${line_n} [${match}] → [${replacement}], saveEffect dispatched`)
    },


//#region bm e
    // Ctrl+B from the editor — create a w/{docC}/%bookmark at the current selection.
    //
    // The editor marks the range with a CodeMirror Decoration.mark so from/to
    // track document edits automatically. Periodic e_Lang_update_bookmarks
    // calls push the live mark positions (and a fresh editorState) back here.
    //
    // e.sc carries: doc, from, to, label?, view, state
    async e_Lang_add_bookmark(A: TheC, w: TheC, e: TheC) {
        const docC = this.Lang_doc_from_event(w, e)

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

        // bookmarks live on docC, not w, so they can be r()'d per doc
        const existingBookmark = docC.o({ bookmark: 1 }).find((bm: TheC) =>
            bm.sc.from === from && bm.sc.to === to
        ) as TheC | undefined;
        if (existingBookmark) {
            // Ctrl+B on an already-bookmarked range removes it
            view.dispatch({ effects: docC.c.removeBookmarkMark.of({ id: existingBookmark.sc.bookmark }) })
            await docC.r({ bookmark: existingBookmark.sc.bookmark }, {})
            console.log(`🔖 remove_bookmark id=${existingBookmark.sc.bookmark} [${from}..${to}]`)
            this.i_elvisto(w, 'think', {})
            return
        }

        // Deterministic id keyed on position — same range always gets the same id,
        // so TheC keys and CodeMirror decoration ids survive reloads and round-trips.
        const id = `bm_${from}_${to}`;
        view.dispatch({
            effects: docC.c.addBookmarkMark.of({ id, from, to }),
        });

        docC.i({ bookmark: id, from, to, label });
        console.log(`🔖 add_bookmark id=${id} [${from}..${to}] ${label}`);
        this.i_elvisto(w, 'think', {});
    },


    // Fired by the editor after the debounce (or immediately via saveEffect).
    //
    // Carries the live from/to for every bookmark still present in the CM
    // decoration set, plus a fresh editorState so whatsthis() sees the updated
    // parse tree.  Any known bookmark id absent from updates[] has vanished —
    // its decoration was wiped by an edit that fully replaced its span.
    //
    // e.sc carries: doc, updates=[{id, from, to}], view, state
    async e_Lang_update_bookmarks(A: TheC, w: TheC, e: TheC) {
        if (!A.sc.A) throw "!A"
        const docC = this.Lang_doc_from_event(w, e)
        const updates = e?.sc.updates as Array<{ id: string, from: number, to: number }> | undefined
        if (updates) {
            const seen = new Set(updates.map(u => u.id))
            for (const u of updates) {
                const bm = docC.o({ bookmark: u.id })[0] as TheC | undefined
                if (!bm) continue
                if (bm.sc.from === u.from && bm.sc.to === u.to) continue
                bm.sc.from = u.from
                bm.sc.to   = u.to
                bm.bump_version()
            }
            // detect vanished bookmarks — present in docC but absent from CM's live set
            for (const bm of docC.o({ bookmark: 1 }) as TheC[]) {
                if (!seen.has(bm.sc.bookmark)) {
                    this.Lang_bookmark_vanished(docC, bm)
                }
            }
        }
        // state already updated by Lang_doc_from_event above
        this.i_elvisto(w, 'think', {})
    },

    // ── Lang_bookmark_vanished ───────────────────────────────────────────────
    //
    //   Called when a bookmark's CM decoration is absent from the live set —
    //   meaning an edit fully replaced or deleted the span it was anchored to.
    //
    //   < STUB: eventually this should attempt re-anchoring by scanning the
    //     parse tree for the nearest surviving syntactic landmark (same Line:N,
    //     same node type, same label text) and re-dispatching addBookmarkMark
    //     at the recovered position.
    //
    //   < Copy+paste tracking: when a paste lands, compare incoming text chunks
    //     against the label/content of vanished bookmarks and re-anchor any that
    //     appear in the new location.
    //
    //   Takes docC (not w) so the log context is clearly per-document.
    Lang_bookmark_vanished(docC: TheC, bm: TheC) {
        console.warn(`🔖 bookmark vanished: ${bm.sc.bookmark} was [${bm.sc.from}..${bm.sc.to}] "${bm.sc.label}"`)
        bm.i({ vanished: 1 })
        // < re-anchor attempt goes here
        // < copy+paste recovery pass goes here
    },


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
        const FONT = `${fontSize}px Berkeley Mono,Fira Code,monospace`

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



    })
    })
</script>

<LangWhatwhere {M} />
<LangCompiling {M} />
<LangSion {M} />
<LangRegions {M} />
