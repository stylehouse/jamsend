// Atlas.g — every doc's %Map, kept.  The first ghost in Ghost/L/ (the land; spec home for now:
//  Stemdex_todo.md §0 "relation EDGES", 2026-09-05).  `Atlas` is a PLACEHOLDER name — an atlas is a
//   kept collection of maps, which is exactly what this is; rename while it is cheap.
//
//  WHAT: the compiler already builds a precise per-doc index — dock/%Compile/%Map with %def, %call,
//   %region, %controlflow entries, from the REAL parser — but only for a dock OPEN in the editor, and
//    it .empty()s it on every recompile.  Atlas builds that same %Map HEADLESS (EditorState from text,
//     no dock, no w:Lang) for every doc on disk, and KEEPS it:
//
//       w:Atlas
//         %Doc:<path>,dige,lines        ← one row per file, the census (snaps: ~230 legible lines)
//           %Map,dontSnap                ← the compiler's own vocabulary, unchanged (bodies fold out)
//             %def  %call  %region  %controlflow
//
//  WHY FOAM, NOT MAPS: the Stemdex keeps its truth in off-snap JS Maps ("Maps are runtime brain").
//   Here the truth is particles — so the X index (TheX, Stuff.svelte.ts) does the grouping, o({def:X})
//    is a lookup not a scan, minisnap can READ it with no new op, and a Book can swear it.  Per-doc
//     baskets stay ~1% of the 6000 "giant stuff" ceiling (Vyto.g's 1988 lines → ~720 entries).  Caches
//      that can be thrown away (a reverse index, the roster walk) may live in .c; truth may not.
//
//  WHERE IT RUNS: a runner with FSA — spare capacity (nobody typing), current code (the runner rides
//   the live spine), reachable today (runner_ask), and A:Wormhole.c.nav reads the tree directly.
//    Never the editor (it must not ride the spine it is editing) and never a humdinger (someone's
//     music page pays for nothing here).
//
//  FIRST CUT, deliberately: the compiler's existing four kinds only; build once per (path, dige); a
//   polite budget per pass so the runner stays responsive.  STANDING on a live runner 2026-09-05:
//    226 docs, 0 errors, LangHold.svelte 49/49 eatfunc members (see ATLAS_MAPPER for the fix history —
//     the bug and its real fix both ended up living in compile.ts, not here).
//  Owed, in order — the second is a compile.ts collector gap CONFIRMED by this ghost's own census:
//   · top-level `function` decls in .ts: the tsstho walk collects PropertyDefinition + class names,
//      not FunctionDeclaration — vyto_foam.ts (all `export function`) maps to 0 defs.
//   · `via` on TS-branch calls: every .svelte/.ts %call lacks its enclosing def (ctx.current_method is
//      only set on the stho line branch), so "who calls X, from inside what" works for .g only.
//   · the three added kinds (%elvisto, %mint, %see); rescans on dige drift; .md docs; the reverse
//      lookup ("who calls X" across docs — a wildcard minisnap path already answers it minus the Doc
//       ancestry; the one genuinely 12k-wide thing, so derive on demand or page it, never one flat X).

IMPORT()
    import { EditorState } from "@codemirror/state"
    import { lang, lang_for_path } from "$lib/O/lang/lang"
    import { dig } from "$lib/Y.svelte"

    // ATLAS_MAPPER — the mapper's own version, stamped on every %Doc as `by`.  A row whose `by` is
    //  behind gets re-mapped even though its text dige is unchanged: the INDEX changed, not the doc
    //   (the Stemdex plan's "version inside the row so stale rows re-scan, never silently report
    //    less").  Bump it whenever the collector or this ghost changes what a Map holds.
    //     m1 (2026-09-05): first cut — mapped 1 def per .svelte/.ts.  Root cause: CodeMirror parses
    //      LAZILY, so a fresh unattached state's incremental tree can stop partway through the doc
    //       (LangHold.svelte, 89,519 chars, parsed only its first 116 — one eatfunc member of 49) and
    //        bare `syntaxTree(state)` inside Lang_compile_collect's TS branch read that short tree.
    //     m2/m3 (2026-09-05, superseded): two local workarounds — force the parse (`ensureSyntaxTree`),
    //      then roll the state through an empty transaction to refresh its cached-tree snapshot.  Both
    //       lived here and both worked, but the bug was the collector's, not the caller's.
    //     m4 (2026-09-05): FIXED IN compile.ts instead — Lang_compile_collect's TS branch now calls
    //      `this.Lang_full_tree(state)` (the markdown collector's own fix, extended to the TS path).
    //       Its `parser.parse(state.doc.sliceString(0))` fallback parses the raw text directly, wholly
    //        bypassing CM6's cached-tree snapshot, so a plain headless build is correct with no forcing
    //         on this side.  Verified: LangHold.svelte → 49/49 members with a bare EditorState.create.
    const ATLAS_MAPPER = 'm4'
    // ATLAS_BUDGET — docs mapped per pass.  A %Map build is a real parse (the whole-doc tsstho tree
    //  walk on .svelte), so this is the Stemdex's "polite pass" idea: converge over passes, never thump.
    const ATLAS_BUDGET = 6
    // the corpus: the authored trees, not the generated ones.  gen/ is the compiler's output; spec/ is
    //  prose (owed — the Stemdex indexes it today, Atlas will once .md regions are wanted here).
    //  data/ + mostly/ are THE GROUND (TheC/TheX, Selection/resolve) — the substrate everything
    //   else calls into; a code model that cannot see `o()`'s home is not a model of this code.
    const ATLAS_ROOTS = ['Ghost', 'src/lib/O', 'src/lib/L', 'src/lib/V', 'src/lib/data', 'src/lib/mostly']
    const ATLAS_SKIP  = { gen: 1, node_modules: 1, spec: 1, history: 1, shelved: 1, '.git': 1, '.svelte-kit': 1 }
    const ATLAS_EXT   = { g: 1, svelte: 1, ts: 1 }

//#region the world — w:Atlas stands, walks the tree once, then maps a few docs per pass
Atlas(A, w):
    if (!w.c.plan_done) this.Atlas_plan(w)
    let nav = this.Atlas_nav()
    if (!nav) return w.r({ see: 'atlas' }, { waiting: 'no A:Wormhole nav — grant FSA on this tab' })
    w oai %req:index,eternal
        await &Atlas_pass,w,req,nav
        req%ok = 1

Atlas_plan(w):
    w.c.plan_done = 1

// Atlas_nav — the tree, read directly.  A:Wormhole mounts `new MountNav(new WormholeNav(DL))` the
//  moment a tab holds an FSA DirectoryListing (Housing.svelte.ts Wormhole()); the editor's remote-
//   wormhole handler reads its own files through exactly this handle, so it is the one idiom.
Atlas_nav():
    let top = this.top_House()
    let A = top.o({ A: 'Wormhole' })[0]
    if (!A) return null
    return A.c.nav ?? null
//#endregion

//#region the pass — roster once, then up to ATLAS_BUDGET maps
// Atlas_pass — one polite pass.  First pass walks the roots and mints a bare %Doc row per file (the
//  CENSUS — cheap, no reads).  Every pass after maps up to ATLAS_BUDGET rows that have no %Map yet,
//   reading + diging + parsing each, then wakes itself again while any remain.  A wake, not a hold:
//    on a runner with no Story run that is enough (Coding_guide "wake ≠ hold"); the Book that swears
//     this will add the hold.
async Atlas_pass(w, req, nav):
    if (!w.c.rostered) {
        let n = 0
        for (const root of ATLAS_ROOTS) {
            n = n + await this.Atlas_walk(w, nav, root)
        }
        w.c.rostered = 1
        this.Atlas_report(w)
        this.i_elvisto(w, 'think')
        return
    }
    let todo = []
    for (const doc of w.o({ Doc: 1 })) {
        if (todo.length >= ATLAS_BUDGET) break
        if (doc.sc.by === ATLAS_MAPPER && doc.oa({ Map: 1 })) continue   // mapped by THIS mapper
        if (doc.sc.by === ATLAS_MAPPER && doc.sc.error) continue          // failed under this mapper — don't spin
        todo.push(doc)
    }
    for (const doc of todo) {
        await this.Atlas_map_one(nav, doc)
    }
    this.Atlas_report(w)
    if (todo.length) this.i_elvisto(w, 'think')

// Atlas_walk — recurse one root, minting %Doc:<path> for every file with a wanted extension.
//  Plain recursion with a returned count (the .g compiler parse-storms on closure-heavy helpers).
//   nav.dir(...parts) hands back a DirectoryListing: .files[], .directories[], lazily .expand()ed.
async Atlas_walk(w, nav, path):
    let dl = await nav.dir_at(path)
    if (!dl) return 0
    if (!dl.expanded) await dl.expand()
    let n = 0
    for (const f of dl.files) {
        let ext = f.name.split('.').pop()
        if (!ATLAS_EXT[ext]) continue
        w.oai({ Doc: path + '/' + f.name })
        n = n + 1
    }
    for (const d of dl.directories) {
        if (ATLAS_SKIP[d.name]) continue
        n = n + await this.Atlas_walk(w, nav, path + '/' + d.name)
    }
    return n

// Atlas_map_one — read, dige, parse, keep.  The %Map lands under the %Doc itself: Lang_compile_collect
//  writes to job.oai({Map:1}) on whatever job it is handed, so the %Doc IS the job — no %Compile
//   wrapper, no dock.  Markdown takes the heading collector; everything else the stho/tsstho one,
//    gated on Lang_has_lang_parser so a grammar miss records an error rather than raw passthrough.
//     dontSnap on the %Map: ~700 rows per big doc is truth worth keeping, not a snap worth reading.
async Atlas_map_one(nav, doc):
    let path = doc.sc.Doc
    let cut = path.lastIndexOf('/')
    let dir_path = path.slice(0, cut)
    let filename = path.slice(cut + 1)
    let text = await nav.read_file(dir_path, filename)
    if (text == null) { doc.sc.error = 'unreadable'; return }
    doc.sc.dige  = await dig(text)
    doc.sc.lines = '' + text.split('\n').length
    doc.sc.by    = ATLAS_MAPPER
    delete doc.sc.error
    let old = doc.o({ Map: 1 })[0]
    if (old) doc.drop(old)                       // a re-map replaces, never piles
    try {
        let exts  = await lang(lang_for_path(path))
        let state = EditorState.create({ doc: text, extensions: exts })
        // A plain, unforced state is now correct: Lang_compile_collect (compile.ts) reaches for
        //  Lang_full_tree internally, which forces its own complete parse (m4 above).  Nothing to
        //  do here but hand the state over.
        if (/\.md$/.test(path)) {
            this.Lang_collect_markdown_regions(state, doc)
        } else {
            if (!this.Lang_has_lang_parser(state)) { doc.sc.error = 'no parser'; return }
            this.Lang_compile_collect(state, doc, this.Lang_stho_parser(state))
        }
        let map = doc.o({ Map: 1 })[0]
        if (map) {
            map.sc.dontSnap = 1
            doc.sc.defs  = '' + map.o({ def: 1 }).length
            doc.sc.calls = '' + map.o({ call: 1 }).length
        } else {
            doc.sc.error = 'no map'
        }
    } catch (e) {
        doc.sc.error = ('' + (e && e.message ? e.message : e)).slice(0, 120)
    }

// Atlas_report — the one summary row, replaced not piled (the Seem/%News idiom).
Atlas_report(w):
    let docs = w.o({ Doc: 1 })
    let mapped = 0
    let errors = 0
    for (const d of docs) {
        if (d.oa({ Map: 1 })) mapped = mapped + 1
        if (d.sc.error) errors = errors + 1
    }
    w.r({ see: 'atlas' }, { docs: '' + docs.length, mapped: '' + mapped, errors: '' + errors })
//#endregion
