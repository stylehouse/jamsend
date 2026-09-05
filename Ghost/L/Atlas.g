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
    //     m5 (2026-09-05): two more compile.ts collector fixes — top-level `export function` decls in
    //      `.ts` (were 0 defs; vyto_foam.ts → 7) and `via` on every .svelte/.ts %call (a def_spans
    //       side table + a post-pass; LangHold.svelte → 117/117 calls now carry via).  Bumped so the
    //        whole census re-derives with the richer Maps rather than serving stale m4 rows.
    //     m6 (2026-09-06): three added Map kinds — %elvisto (the deferred cross-ghost call), %mint
    //      (where a mainkey is first minted), %proves (a %see or %desc sentence).  Verified:
    //       Vytonation.g → 7 elvisto to Vyto/Vyto::Vyto_commission, 80 sees (deduped from the
    //        oa-guard/i-mint pair sharing one sentence), 70 descs; Vyto.g → 27 mints, Organ present,
    //         the A/H housing-shelf false positive excluded.
    //     m7 (2026-09-06): `via` for all three — a "last top-level def whose line ≤ this line" lookup,
    //      dialect-uniform (a .g method sits at column 0; its body runs until the next one) and built
    //       from the def words already collected, no new tree-walk.  100% via coverage verified on
    //        both a .g file (Vytonation.g's 7 elvisto calls attribute to 7 different enclosing beats)
    //         and a .svelte file (LangHold.svelte, 4 elvisto + 15 mint, all via).
    //     m8 (2026-09-06): `.md` docs — the doc-links census (`%link,kind:wiki|file`), the ORIGINAL
    //      high-value target from the very first census of this whole effort.  `spec/` un-skipped
    //       (`history/`/`shelved/` stay skipped — retired content, per CLAUDE.md's own convention);
    //        `md` added to ATLAS_EXT.  Verified: Radio_todo.md → 63 regions (headings, unaffected) +
    //         15 wiki-links + 70 file:line refs, matching the 2026-09-03 census (16/69) closely.
    //          Full corpus, live+headless: 585 docs (245 code + 340 markdown), 0 errors.
    //     m9 (2026-09-06): `region_path` for links — the enclosing heading chain, same "last entry
    //      before this line" trick as via, carrying the whole ancestor array (each heading word
    //       already recorded its own stack-at-that-moment).  100% coverage: Radio_todo.md's 85 links
    //        all carry a real 3-deep heading chain.
    const ATLAS_MAPPER = 'm9'
    // ATLAS_BUDGET — docs mapped per pass.  A %Map build is a real parse (the whole-doc tsstho tree
    //  walk on .svelte), so this is the Stemdex's "polite pass" idea: converge over passes, never thump.
    const ATLAS_BUDGET = 6
    // the corpus: the authored trees, not the generated ones.  gen/ is the compiler's output.
    //  data/ + mostly/ are THE GROUND (TheC/TheX, Selection/resolve) — the substrate everything
    //   else calls into; a code model that cannot see `o()`'s home is not a model of this code.
    //  spec/ is prose, walked since m8 for its doc-links; history/+shelved/ stay excluded — retired,
    //   not living content (CLAUDE.md's own retirement convention: a moved-out doc is done being read).
    const ATLAS_ROOTS = ['Ghost', 'src/lib/O', 'src/lib/L', 'src/lib/V', 'src/lib/data', 'src/lib/mostly']
    const ATLAS_SKIP  = { gen: 1, node_modules: 1, history: 1, shelved: 1, '.git': 1, '.svelte-kit': 1 }
    const ATLAS_EXT   = { g: 1, svelte: 1, ts: 1, md: 1 }

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
        // w.c.roots — a TEST override (off-snap; a Book sets it before the first tick) so a Book can
        //  point Atlas at a small, self-contained corpus (its own directory) instead of scanning the
        //  whole live repo — the compiler's own correctness is already unit-tested headless; what a
        //  Book should swear is the DRIVE (walk→map→converge, replace-not-pile, error handling).
        let roots = w.c.roots ?? ATLAS_ROOTS
        let n = 0
        for (const root of roots) {
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
            // Every census field below is stamped ONLY when non-zero, so a plain doc's row stays as
            //  legible as it was before each kind existed — a .g row never shows `links:0`, a .md row
            //  never shows `defs:0,calls:0`.  Plain, explicit, boring — the .g compiler parse-storms on
            //  closure/computed-key-heavy helpers, so this stays a flat list, not a loop over a table.
            let defs  = map.o({ def: 1 }).length
            let calls = map.o({ call: 1 }).length
            let elv   = map.o({ elvisto: 1 }).length
            let mnt   = map.o({ mint: 1 }).length
            let prv   = map.o({ proves: 1 }).length
            let rgn   = map.o({ region: 1 }).length
            let lnk   = map.o({ link: 1 }).length
            if (defs)  doc.sc.defs    = '' + defs
            if (calls) doc.sc.calls   = '' + calls
            if (elv)   doc.sc.elvisto = '' + elv
            if (mnt)   doc.sc.mints   = '' + mnt
            if (prv)   doc.sc.proves  = '' + prv
            if (rgn)   doc.sc.regions = '' + rgn
            if (lnk)   doc.sc.links   = '' + lnk
        } else {
            doc.sc.error = 'no map'
        }
    } catch (e) {
        doc.sc.error = ('' + (e && e.message ? e.message : e)).slice(0, 120)
    }

// Atlas_callers — the reverse lookup, owed since the first census (Stemdex_todo.md §0): "who calls
//  X" answered WITH the doc it lives in, not just a count-and-line the way a wildcard minisnap path
//  gives it (minisnap has no way to print a match's ancestry).  Walks every mapped Doc's `call` AND
//  `elvisto` rows for the name — a plain o() per doc, no index: at 585 docs this is milliseconds, and
//  building an actual reverse index would mean maintaining a SECOND structure in step with the first
//  (exactly the sync-code smell the "five readings, nothing stored" design elsewhere here avoids).
//  Returns [{doc, line, via, kind}], kind:'call'|'elvisto' so a caller can tell direct calls from
//  deferred cross-ghost ones without a second query.
Atlas_callers(w, name):
    let out = []
    for (const doc of w.o({ Doc: 1 })) {
        let map = doc.o({ Map: 1 })[0]
        if (!map) continue
        for (const c of map.o({ call: 1, method: name })) {
            out.push({ doc: doc.sc.Doc, line: c.sc.line, via: c.sc.via, kind: 'call' })
        }
        for (const e of map.o({ elvisto: 1, method: name })) {
            out.push({ doc: doc.sc.Doc, line: e.sc.line, via: e.sc.via, target: e.sc.target, kind: 'elvisto' })
        }
    }
    return out

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
