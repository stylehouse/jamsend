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
//  Everything in that first-cut owed list has since landed (see ATLAS_MAPPER's history and
//   spec/Stemdex_todo.md §0): FunctionDeclaration + via in .ts, the %elvisto/%mint/%proves kinds,
//    .md docs with %link, the reverse lookup (Atlas_callers), and — 2026-09-06 — FRESHNESS and
//     DURABILITY: `Atlas_refresh` (use nudges a pass: every query re-lists the roots, maps the movers
//      inline; mtime+size on doc.c are the cheap tell, the dige stays the truth) and the Dexie
//       `atlas` cache (adopt a Map from its row when mapper+mtime+size match, stamp it `warm`), plus
//        the lints — answers over what is already held.
//  What is deliberately NOT here: a timer (Stemdex_todo §0's standing constraint) and a reverse
//   INDEX (a query over 711 docs is milliseconds; a second structure would need keeping in step).
//
//  ⇢ 2026-09-08 — THE ANSWERS MOVED OUT.  `Atlas_callers`, `Atlas_lint`, `Atlas_resolve` and
//   `Atlas_unproven` now live in **`Ghost/L/Lagoon.g`**, the reader layer.  The line, ruled the same
//    day (`Wordland_todo §1.1`, `Lagoon_todo.md`): **ATLAS KEEPS; LAGOON ASKS.**  The test for anything
//     proposed here is one question — *does it change what is HELD, or ask a question OF what is held?*
//      This ghost had drifted to 12 keeping / 4 asking, one convenience at a time, which is what
//       globulation looks like from the inside: no single addition was wrong.  `Atlas_unproven` was the
//        tell — it did not ask of the census at all, it opened `wormhole/Story/**/*.snap` off disk, a
//         second source and a second concern inside a code index.  Keep this file a census.

IMPORT()
    import { EditorState } from "@codemirror/state"
    import { lang, lang_for_path } from "$lib/O/lang/lang"
    import { dig } from "$lib/Y.svelte"
    import { is_testing } from "$lib/L/testing"
    import { Dexie } from "dexie"

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
    //     m10 (2026-09-06): calls on a ControlFlow line in a .g file (`if (n === 2) this.Beat(w)`,
    //      the Book drive idiom) — the stho per-line CALL_RE sweep sat after branches that return
    //       early, so those calls were never recorded; the Atlas orphan lint listed every Book beat
    //        as uncalled.  Fixed in compile.ts with a whole-document CALL_GAP sweep (stho only,
    //         dedup by offset).  Bumped so every cached row re-derives with the missing calls.
    //     m11 (2026-09-06): FILE_RE's `\b` broke at a hyphen, so `relay-test.ts:55` truncated to
    //      `test.ts:55` — found by acting on the missing-link lint itself: two flagged "missing"
    //       targets were real, existing files (`scripts/relay-test.ts`, `scripts/runner-ask-test.ts`)
    //        misread by the regex, not stale docs.  Fixed with a negative lookbehind in compile.ts.
    //     (Atlas_lint itself changed the same day too, not the collector — no mapper bump needed for
    //      that: it now excludes a history/|shelved/ target from missing/beyond_eof, since Atlas
    //       never rosters those shelves and so cannot confirm or deny a link into one — CLAUDE.md's
    //        own corollary, "a referenced spec/X.md that isn't there is almost certainly history/X.md".)
    //     m12 (2026-09-08): CALL_RE / CALL_GAP_RE now match the cast form `(H as any).X(` /
    //      `(this as House).X(`.  Found by Electrode's join (Wordland_todo §4c): `Lies_role →
    //       Lies_inside_story` ×207 measured, zero declared, the source reading
    //        `(H as any).Lies_inside_story()`.  158 such sites in src/lib/O — ~8% of hand-written call
    //         edges had been missing from every census.  Bumped so every cached row re-maps.
    //     m13 (2026-09-08, same night): the OPTIONAL forms too — `H?.X(` and `(H as any).X?.(…)` — the
    //      join's next undeclared row (`Lies_cluster_idento → Clustation_active_identity`, source
    //       `(H as any).Clustation_active_identity?.(H)`).  Five sites; cheap; sound.
    //     m14 (2026-09-08): a THIRD link kind — `code`, a backticked_identifier in prose.  The corpus
    //      points at methods and keys on every page and had no link form for it (the vocabulary was two:
    //       wiki and file:line).  The underscore is the filter — of 15,160 backticked tokens in spec/,
    //        the 8,834 containing one are almost purely real symbols, and the 6,000 without are `sc`,
    //         `true`, `ok`.  Resolution is Lagoon's, not the collector's: an unresolvable target is a
    //          mention, not rot.  Bumped so every cached row re-derives with its prose links.
    //     m15 (2026-09-08 night): THREE more link kinds — `sect`, `book`, `sworn` (Lagoon_todo leg 2).
    //      The big one is `sect`: `<Doc> §N.N`, and it was found by MEASURING the corpus before choosing
    //       a form rather than after.  spec/ makes 4,257 §-references and not one was collected, while
    //        the `Doc#region` form the plan proposed appears twice — so the section-link language was
    //         already here, spelled §.  463 doc-qualified (113 distinct target docs) + 943 bare (a bare
    //          `§N` means THIS doc's §N and is emitted with no target at all).  `book` is `Book:<Name>`
    //           (18, explicit form only) and `sworn` is `«assertion-slug»` (4) — both small and both
    //            named anyway, because a form nobody can spell is a form nobody uses.
    //       Bumped so every cached row re-derives with the new kinds.
    const ATLAS_MAPPER = 'm15'
    // ATLAS_BUDGET — docs mapped per pass.  A %Map build is a real parse (the whole-doc tsstho tree
    //  walk on .svelte), so this is the Stemdex's "polite pass" idea: converge over passes, never thump.
    // ATLAS_SLICE_MS — THE POLITENESS BOUND, and it is a TIME not a count (2026-09-08).  The count-only
    //  budget below was measured hogging the beliefs mutex: the drain-lag electrode on the owner's own
    //   editor tab read `why=beliefs mutex held 4s by H:Mundo think Atlas/Atlas`, repeatedly, while a
    //    dozen of their Storui clicks sat undrained in H.todo behind it.  EVERY House drains under the
    //     top House's single beliefs mutex (Housing.svelte.ts:230), so a pass that parses six files
    //      without yielding freezes the whole tab for as long as that takes — and a count is the wrong
    //       bound because docs differ by 40×: `Atlas_map_one` measured 50-194ms each (Wordland_todo §4b).
    //  So: map until the slice is spent, then yield and re-poke.  A pass now holds the mutex for about
    //   one document, whatever that document costs, and convergence still happens over passes exactly as
    //    before — this changes the SHAPE of the hold, not the total work.
    const ATLAS_SLICE_MS = 120
    const ATLAS_BUDGET = 6
    // ATLAS_ADOPT — cache adoptions per pass.  An adopt rebuilds a %Map from its Dexie row with no
    //  read and no parse (mint-only), so it is far cheaper than a map and gets its own, wider lane.
    //  ⇢ 2026-09-08: this ceiling is now secondary to ATLAS_SLICE_MS — the adopt lane exits on the time
    //     bound like the map lane does, so 40 is a cap that is rarely the thing that stops a pass.
    const ATLAS_ADOPT = 40
    // ATLAS_REFRESH_MAP — docs a refresh will map INLINE before handing the rest to the pass.  A
    //  refresh runs inside a query op (the caller is waiting on the answer), so it settles the few
    //   movers a working session produces itself and only defers a bulk change (a branch switch).
    const ATLAS_REFRESH_MAP = 24
    // (ATLAS_DISPATCHED / SNAP_NAME_RE / SEE_LINE_RE MOVED OUT 2026-09-08 with the lints they served —
    //  Ghost/L/Lagoon.g.  Atlas KEEPS; Lagoon ASKS: Wordland_todo §1.1, Lagoon_todo.md.)
    // the corpus: the authored trees, not the generated ones.  gen/ is the compiler's output.
    //  data/ + mostly/ are THE GROUND (TheC/TheX, Selection/resolve) — the substrate everything
    //   else calls into; a code model that cannot see `o()`'s home is not a model of this code.
    //  spec/ is prose, walked since m8 for its doc-links; history/+shelved/ stay excluded — retired,
    //   not living content (CLAUDE.md's own retirement convention: a moved-out doc is done being read).
    //  2026-09-06: widened to the whole of src/ + scripts/ (+100 docs → 687).  The link lint's first
    //   run showed most "missing" targets were not gone but merely UNROSTERED (src/lib/ghost's
    //    Radios.svelte, p2p's Peerily.svelte.ts, scripts/daemon/main.ts, the relay) — a census that
    //     stops at src/lib/O cannot tell "moved to history/" from "lives one directory over".  The
    //      skip list still keeps gen/, history/, shelved/ out.  .mjs stays out: no grammar for it.
    const ATLAS_ROOTS = ['Ghost', 'src', 'scripts']
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
        // A RESUMABLE ROSTER (2026-09-08).  The roster was the last unbounded hold: one pass walked
        //  every root — 715 docs — with the beliefs mutex held, measured at 4s and then 6s on the
        //   owner's editor tab with their clicks queued behind it.  Chunking per ROOT was the first
        //    attempt and was not enough: `src` alone is most of the corpus, so a fresh stand still
        //     froze the tab for six seconds.
        //  So the frontier is a QUEUE OF DIRECTORIES on `w.c`, and a pass drains it for one slice.
        //   `Atlas_walk` itself is untouched and still recurses — `Atlas_refresh` NEEDS a complete walk
        //    to compute `gone` by comparing its `seen` set, and a half-finished refresh would drop live
        //     docs.  Only the roster, which has no such contract, is allowed to stop halfway.
        if (!w.c.walk_q) w.c.walk_q = (w.c.roots ?? ATLAS_ROOTS).slice()
        let q = w.c.walk_q
        if (q.length) {
            let until = Date.now() + ATLAS_SLICE_MS
            let first = 1
            while (q.length && (first || Date.now() < until)) {
                first = 0
                let dir = q.shift()
                await this.Atlas_walk_one(w, nav, dir, q)
            }
            await this.Atlas_report(w)
            this.i_elvisto(w, 'think')
            return
        }
        w.c.rostered = 1
        // the roster is complete, so the adopt lane starts next pass — pull the served dige index
        //  now, once, while there is nothing else in flight
        await this.Atlas_diges(w)
        await this.Atlas_report(w)
        this.i_elvisto(w, 'think')
        return
    }
    // Two lanes per pass.  A doc with NO Map yet may be ADOPTED from the Dexie cache (its row's
    //  mtime+size+mapper all match — no read, no parse); a doc whose Map is merely STALE (a mapper
    //   bump, a dige mover a refresh un-stamped) is always a real re-map — the cache row is what the
    //    stale Map came from, so adopting it would re-serve the very thing being replaced.
    let adopted = 0
    let mapped = 0
    let more = 0
    let slice_end = Date.now() + ATLAS_SLICE_MS
    for (const doc of w.o({ Doc: 1 })) {
        // the time bound, checked before every unit of real work — see ATLAS_SLICE_MS
        if ((adopted || mapped) && Date.now() > slice_end) { more = more + 1; continue }
        if (doc.sc.by === ATLAS_MAPPER && doc.oa({ Map: 1 })) continue   // mapped by THIS mapper
        if (doc.sc.by === ATLAS_MAPPER && doc.sc.error) continue          // failed under this mapper — don't spin
        let cold = doc.oa({ Map: 1 }) ? true : false
        if (!cold) {
            if (adopted >= ATLAS_ADOPT) { more = more + 1; continue }
            if (await this.Atlas_cache_adopt(w, nav, doc)) { adopted = adopted + 1; continue }
        }
        if (mapped >= ATLAS_BUDGET) { more = more + 1; continue }
        await this.Atlas_map_one(w, nav, doc)
        mapped = mapped + 1
    }
    await this.Atlas_report(w)
    if (adopted || mapped || more) this.i_elvisto(w, 'think')

// Atlas_walk — recurse one root, minting %Doc:<path> for every file with a wanted extension.
//  Plain recursion with a returned count (the .g compiler parse-storms on closure-heavy helpers).
//   nav.dir(...parts) hands back a DirectoryListing: .files[], .directories[], lazily .expand()ed.
//  `fresh` re-expands every listing (WormholeNav caches them, so a plain walk would re-read the
//   roster as it stood at the FIRST walk); `seen` collects every path met so a refresh can drop the
//    Docs whose file is gone.  Each file's mtime+size ride on doc.c — a cache, not truth (the dige
//     is the truth; these are the cheap tell that it MAY have moved), so they never snap.
// Atlas_walk_one — ONE directory: mint its files' Doc rows and push its subdirectories onto the
//  caller's frontier queue.  The non-recursive half of Atlas_walk, used only by the resumable roster
//   (see Atlas_pass).  Deliberately a near-duplicate of the file loop below rather than a shared
//    helper: the recursive walk owes `fresh`/`seen` semantics that the roster has no use for, and
//     threading a mode flag through both would make the one function that must stay correct for
//      refresh harder to read than two short ones.
async Atlas_walk_one(w, nav, path, queue):
    let dl = await nav.dir_at(path)
    if (!dl) return 0
    if (!dl.expanded) await dl.expand()
    let n = 0
    for (const f of dl.files) {
        let ext = f.name.split('.').pop()
        if (!ATLAS_EXT[ext]) continue
        let p = path + '/' + f.name
        let doc = w.o({ Doc: p })[0]
        if (!doc) doc = w.i({ Doc: p })
        // `testing` is a fact of the PATH, so it is stamped at mint and costs no read: a snapped 1 or
        //  absent, never 0.  Kept here so the census itself can be asked "which docs are the border
        //   between the Book dialect and the ghosts" (src/lib/L/testing.ts is the one predicate).
        if (is_testing(p)) doc.sc.testing = 1
        doc.c.mtime = f.modified ? f.modified.getTime() : 0
        doc.c.size = f.size ?? 0
        n = n + 1
    }
    for (const d of dl.directories) {
        if (ATLAS_SKIP[d.name]) continue
        queue.push(path + '/' + d.name)
    }
    return n

async Atlas_walk(w, nav, path, fresh, seen):
    let dl = await nav.dir_at(path)
    if (!dl) return 0
    if (fresh || !dl.expanded) await dl.expand()
    let n = 0
    for (const f of dl.files) {
        let ext = f.name.split('.').pop()
        if (!ATLAS_EXT[ext]) continue
        let p = path + '/' + f.name
        let mtime = f.modified ? f.modified.getTime() : 0
        let size = f.size ?? 0
        let doc = w.o({ Doc: p })[0]
        if (!doc) {
            doc = w.i({ Doc: p })
            if (is_testing(p)) doc.sc.testing = 1
            if (fresh) w.c.refresh_added = w.c.refresh_added + 1
        } else if (doc.c.mtime !== mtime || doc.c.size !== size) {
            // the file moved under a settled Doc: un-stamp the mapper so the pass re-maps it (the
            //  Map stays in place until then — a stale answer beats a missing one for a query that
            //   lands between the un-stamp and the re-map)
            if (doc.sc.by) {
                delete doc.sc.by
                w.c.refresh_changed = w.c.refresh_changed + 1
            }
        }
        doc.c.mtime = mtime
        doc.c.size = size
        if (seen) seen[p] = 1
        n = n + 1
    }
    for (const d of dl.directories) {
        if (ATLAS_SKIP[d.name]) continue
        n = n + await this.Atlas_walk(w, nav, path + '/' + d.name, fresh, seen)
    }
    return n

// Atlas_refresh — USE nudges a pass (the Stemdex's own rhythm: the searchbar nudges its scan; no
//  second timer, Stemdex_todo.md §0's standing constraint).  Every query op calls this first, so
//   an answer is as fresh as the disk at the moment of asking: re-walk the roots with forced
//    listings, mint the new, un-stamp the moved, drop the gone, then map the movers INLINE up to
//     ATLAS_REFRESH_MAP and hand any bulk remainder to the pass.  Before the first roster this IS
//      the roster.  Returns the tally so the caller can print what changed.
async Atlas_refresh(w, nav):
    w.c.refresh_added = 0
    w.c.refresh_changed = 0
    // A REFRESH IS THE MOMENT FILES MAY HAVE MOVED, so the served index is discarded and re-asked
    //  before anything is adopted against it.  Holding the boot's copy here would be the one way
    //   this accelerator could become the stale-adopt it exists beside; the walk below re-stats
    //    every file anyway, so a fresh map is what its mtime+size are then corroborated against.
    //  Clearing `asked_diges` too is what lets a tab that booted against a server with no endpoint
    //   pick one up later without a reload.
    w.c.dige_of = undefined
    w.c.asked_diges = undefined
    await this.Atlas_diges(w)
    let seen = {}
    let roots = w.c.roots ?? ATLAS_ROOTS
    for (const root of roots) {
        await this.Atlas_walk(w, nav, root, 1, seen)
    }
    let gone = []
    for (const doc of w.o({ Doc: 1 })) {
        if (seen[doc.sc.Doc]) continue
        gone.push(doc.sc.Doc)
        w.drop(doc)
    }
    await this.Atlas_forget(w, gone)
    let mapped = 0
    let pending = 0
    for (const doc of w.o({ Doc: 1 })) {
        if (doc.sc.by === ATLAS_MAPPER && (doc.oa({ Map: 1 }) || doc.sc.error)) continue
        if (!doc.oa({ Map: 1 })) {
            if (await this.Atlas_cache_adopt(w, nav, doc)) continue
        }
        if (mapped >= ATLAS_REFRESH_MAP) { pending = pending + 1; continue }
        await this.Atlas_map_one(w, nav, doc)
        mapped = mapped + 1
    }
    w.c.rostered = 1
    await this.Atlas_report(w)
    if (pending) this.i_elvisto(w, 'think')
    return { added: w.c.refresh_added, changed: w.c.refresh_changed, gone: gone.length, mapped, pending }

// Atlas_map_one — read, dige, parse, keep.  The %Map lands under the %Doc itself: Lang_compile_collect
//  writes to job.oai({Map:1}) on whatever job it is handed, so the %Doc IS the job — no %Compile
//   wrapper, no dock.  Markdown takes the heading collector; everything else the stho/tsstho one,
//    gated on Lang_has_lang_parser so a grammar miss records an error rather than raw passthrough.
//     dontSnap on the %Map: ~700 rows per big doc is truth worth keeping, not a snap worth reading.
async Atlas_map_one(w, nav, doc):
    let path = doc.sc.Doc
    let cut = path.lastIndexOf('/')
    let dir_path = path.slice(0, cut)
    let filename = path.slice(cut + 1)
    let text = await nav.read_file(dir_path, filename)
    if (text == null) {
        // stamp `by` here too, or the pass retries this doc EVERY tick (its skip rule needs both
        //  by and error) — the very spin the Book's beat 3 swears against.  A refresh drops a Doc
        //   whose file is gone and un-stamps one whose file changed, so nothing is lost by resting.
        doc.sc.error = 'unreadable'
        doc.sc.by = ATLAS_MAPPER
        return
    }
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
            delete doc.sc.warm                            // a real parse, not a cache adoption
            await this.Atlas_cache_put(w, doc)
        } else {
            doc.sc.error = 'no map'
        }
    } catch (e) {
        doc.sc.error = ('' + (e && e.message ? e.message : e)).slice(0, 120)
    }

//#region the served dige index — the read the cache could not skip
// THE CACHE ALREADY SKIPS THE PARSE; THIS SKIPS THE READ.  `Atlas_cache_adopt` refuses to trust
//  mtime+size and pays a real read+dige before adopting (see its own note — two edits in one second
//   at the same byte length is exactly the silent stale-adopt this project exists to refuse).  Right,
//    and unchanged.  But it means a WARM boot reads ~724 files through FSA, 40 per polite pass, only
//     to learn that nothing moved.  That is the whole of "a ton of docs reading every time".
//  So the dige is computed where the bytes already are.  The dev server holds the repo; it hashes it
//   once and memoizes by mtime+size on ITS side, where a stale memo is cheap because that process
//    owns the filesystem.  One conditional GET replaces 724 reads and the DECIDER IS STILL A CONTENT
//     HASH — the same sha256-first-16 `dig` makes, just not made here.  Nothing is trusted that was
//      not trusted before; the same fact simply costs a sentence instead of a corpus.
//  (src/lib/server/dige.ts + `digePlugin` in vite.config.ts.  Dev-only, hashes never contents.)
// FAILURE IS FREE.  A tab whose server lacks the endpoint — an older dev server, a remote node, a
//  Book — gets null and every doc falls back to its own read+dige, which is exactly the old
//   behaviour.  So this is an accelerator with no new way to be wrong, and it is asked ONCE: the
//    `asked_diges` latch stops a missing endpoint costing a request per pass forever.  A refresh
//     clears both so a re-walk re-asks.
async Atlas_diges(w):
    if (w.c.dige_of) return w.c.dige_of
    if (w.c.asked_diges) return null
    w.c.asked_diges = 1
    let roots = (w.c.roots ?? ATLAS_ROOTS).join(',')
    try {
        let r = await fetch('/__atlas/dige?roots=' + roots, { signal: AbortSignal.timeout(4000) })
        if (!r.ok) return null
        let j = await r.json()
        w.c.dige_of = j.dige
        console.log('🗺 atlas dige index — ' + j.docs + ' docs, served in ' + j.ms + 'ms')
        return w.c.dige_of
    } catch (e) {
        console.log('🗺 atlas dige index unavailable — reading each doc (' + String(e && e.message ? e.message : e) + ')')
        return null
    }
//#endregion

//#region the cache — Dexie 'atlas', one row per doc, the Map rows inside; strictly an accelerator
// Atlas_db — the Stemdex's own pattern (Lies_stemdex_db): browser-only, one handle across HMR
//  remixes, undefined where there is no indexedDB (a node runner) so every caller degrades to the
//   cold path.  The row body is the projection; only the PK is indexed, so a shape change needs no
//    schema bump — the mapper version INSIDE the row (sc.by) is what invalidates.
Atlas_db():
    if (typeof indexedDB === 'undefined') return undefined
    let g = globalThis
    if (!g.__atlas_db) {
        let db = new Dexie('atlas')
        db.version(1).stores({ doc: 'path' })
        g.__atlas_db = db
    }
    return g.__atlas_db

// Atlas_cache_put — after a real map: the Doc's census fields + every Map row's sc (a link's
//  region_path array rides along as a plain field — it lives on .c in the tree, never in sc).
//   mtime+size are the adopt key; the dige inside is the truth a future dige-check could use.
async Atlas_cache_put(w, doc):
    let db = this.Atlas_db()
    if (!db || w.c.nocache) return
    let map = doc.o({ Map: 1 })[0]
    if (!map) return
    let rows = []
    for (const r of map.o()) {
        let row = Object.assign({}, r.sc)
        // the flush parks these on .c (region_path: an array; abs_from/abs_to: recomputed each
        //  compile, never snapped) — carry them as plain fields so an adopt restores the same shape
        if (r.c.region_path) row.region_path = r.c.region_path
        if (r.c.abs_from != null) row.abs_from = r.c.abs_from
        if (r.c.abs_to != null) row.abs_to = r.c.abs_to
        rows.push(row)
    }
    let sc = Object.assign({}, doc.sc)
    delete sc.warm
    try {
        await db.doc.put({ path: doc.sc.Doc, mtime: doc.c.mtime ?? 0, size: doc.c.size ?? 0, sc, rows })
    } catch (e) {
        console.warn('🗺 atlas cache put failed', e)
    }

// Atlas_cache_adopt — rebuild a Doc's Map from its row with no read and no parse.  Only when the
//  row was made by THIS mapper and the file's mtime+size still match what the row saw; the Doc is
//   stamped `warm` so a census row tells a cache adoption from a real parse (a real parse clears it).
async Atlas_cache_adopt(w, nav, doc):
    let db = this.Atlas_db()
    if (!db || w.c.nocache) return false
    let row = null
    try {
        row = await db.doc.get(doc.sc.Doc)
    } catch (e) {
        return false
    }
    // WHY THE THREE REFUSALS ARE COUNTED SEPARATELY (2026-09-09).  A cache that never hits and a
    //  cache that always hits look identical from outside — both are "it ran and the answers were
    //   right" — so the only honest way to know is a number.  This was learned the embarrassing way:
    //    the memo was declared broken here on the strength of a grep for `warm:1`, which never
    //     matches because a snapped 1 renders as a BARE KEY (`,warm`) — the census had been saying
    //      so correctly all along and the reader was wrong.  Hence a tally, which cannot be misread.
    //  Three, not one, because the three misses have completely different fixes: no row at all
    //   (nothing was ever written, or a different db), a row from an older mapper (a version bump —
    //    self-healing and expected), a row whose file genuinely moved (real work to redo).
    //  First live measurement, warm runner, 723 docs: cache_none 0, cache_moved 1, dige_hit 722.
    //   The 1 was Atlas.g itself, recompiled between the server's stat and the tab's — the
    //    corroboration catching a real mover on its first outing, which is the best kind of proof.
    if (!row || !row.sc) { w.c.cache_none = (w.c.cache_none ?? 0) + 1; return false }
    if (row.sc.by !== ATLAS_MAPPER) { w.c.cache_old = (w.c.cache_old ?? 0) + 1; return false }
    if (row.mtime !== (doc.c.mtime ?? 0) || row.size !== (doc.c.size ?? 0)) {
        w.c.cache_moved = (w.c.cache_moved ?? 0) + 1
        return false
    }
    // mtime+size matching is only a HINT the row might still be good, never proof — the owner's own
    //  challenge 2026-09-06 ("I don't think we know the mtime"): two edits inside the same wall-clock
    //   second that leave a file's byte length unchanged (a single-character substitution, exactly
    //    the shape of bumping ATLAS_MAPPER's own version string this session) would pass this check
    //     while genuinely changing content — a silent stale-adopt, the one class of bug this whole
    //      project exists to refuse.  A real read+dige is cheap next to the PARSE this adopt exists
    //       to skip, so pay it here and let the dige — the actual truth, never the listing metadata —
    //        decide.  git's own index does the identical mtime+size-then-hash two-step for the same
    //         reason; there is no daemon-side git integration to lean on instead (checked: neither the
    //          runner tab, sandboxed to FSA, nor scripts/daemon/main.ts shells out to git today).
    //  ⇢ 2026-09-09: the read below is usually SERVED now — `Atlas_diges` holds a path→[dige,mtime,
    //     size] map the dev server computed off the same bytes with the same sha256-first-16.
    //  AND IT IS CORROBORATED, NOT BELIEVED.  A served dige is a claim about the file AT THE MOMENT
    //   THE SERVER HASHED IT, where the read below was a claim about now — so taking it on its own
    //    word would quietly reintroduce the stale-adopt this function's whole existence refuses.  It
    //     is used only when the server's OWN stat agrees with the mtime+size this tab's FSA walk
    //      recorded independently on doc.c — which the Dexie row above has already had to match too.
    //       Three observers of the same metadata, from two processes, before a hash is reused.
    //  The residual window is honest and worth stating: a write landing between the server's stat and
    //   the tab's, that leaves byte length AND mtime identical, would pass.  That is git's index
    //    heuristic exactly, it needs a same-second same-length edit to two observers at once, and
    //     `Atlas_refresh` — which every query nudges — re-pulls the map and re-walks, so it closes.
    //      Disagreement is not an error: it just falls through to the read, as before.
    let path = doc.sc.Doc
    let served = w.c.dige_of ? w.c.dige_of[path] : null
    let dige = null
    if (served && served[1] === (doc.c.mtime ?? 0) && served[2] === (doc.c.size ?? 0)) dige = served[0]
    if (dige) {
        w.c.dige_hit = (w.c.dige_hit ?? 0) + 1
    } else {
        // COUNTED, not assumed.  Every corroboration this can fail — a clock precision mismatch, a
        //  root the server does not walk, an endpoint that isn't there — fails the same silent way:
        //   correct answers, no saving, and nothing on screen to say so.  So the two lanes are
        //    tallied onto the census row (`see:atlas,dige_hit,dige_read`), and a hit rate near zero
        //     is then a thing you can SEE rather than a speedup you assumed you had.
        w.c.dige_read = (w.c.dige_read ?? 0) + 1
        let cut = path.lastIndexOf('/')
        let text = await nav.read_file(path.slice(0, cut), path.slice(cut + 1))
        if (text == null) return false
        dige = await dig(text)
    }
    if (dige !== row.sc.dige) return false
    let old = doc.o({ Map: 1 })[0]
    if (old) doc.drop(old)
    Object.assign(doc.sc, row.sc)
    doc.sc.warm = 1
    let map = doc.i({ Map: 1 })
    map.sc.dontSnap = 1
    for (const r of row.rows) {
        let sc = Object.assign({}, r)
        delete sc.region_path
        delete sc.abs_from
        delete sc.abs_to
        let c = map.i(sc)
        if (r.region_path) c.c.region_path = r.region_path
        if (r.abs_from != null) c.c.abs_from = r.abs_from
        if (r.abs_to != null) c.c.abs_to = r.abs_to
    }
    return true

// Atlas_forget — drop cache rows (a refresh's gone docs; a Book clearing its fixture paths so a
//  run starts cold and deterministic).
async Atlas_forget(w, paths):
    let db = this.Atlas_db()
    if (!db || !paths.length) return
    try {
        await db.doc.bulkDelete(paths)
    } catch (e) {
        console.warn('🗺 atlas cache forget failed', e)
    }
//#endregion


// Atlas_report — the one summary row, replaced not piled (the Seem/%News idiom).
//  AWAITED, and every caller awaits it: r() is an async replace(), and until it commits, o() on
//   the world answers with only what the replace has added so far (Stuff.svelte.ts: "o() will only
//    have what we've added so far").  Un-awaited, a caller that queries the world right after a
//     pass — the AtlasStaple beats, a query op — saw NO Docs at all (2026-09-06, the Book's console:
//      `docs: []` one microtask after a pass that had just iterated them).
//   Even awaited, an r() per pass puts the world through a replace on EVERY tick, and any other
//    world's do_fn that runs while it is in flight (the Book's witness) reads a partial o().  So:
//     find-or-create the one row and stamp it, the way every other census field here is written —
//      no replace, no partial window.  (Kept async so the awaiting callers need no change.)
async Atlas_report(w):
    let docs = w.o({ Doc: 1 })
    let mapped = 0
    let errors = 0
    for (const d of docs) {
        if (d.oa({ Map: 1 })) mapped = mapped + 1
        if (d.sc.error) errors = errors + 1
    }
    let row = w.oai({ see: 'atlas' })
    row.sc.docs   = '' + docs.length
    row.sc.mapped = '' + mapped
    row.sc.errors = '' + errors
    // THE MEMO'S OWN VITAL SIGNS.  Each absent until it happens, so a cold snap stays as legible as
    //  it was — but the moment the cache is doing nothing, the row SAYS which of the three ways.
    //   `cache_none` climbing to the doc count is the tell that the memo is not memoizing at all.
    if (w.c.cache_none) row.sc.cache_none = '' + w.c.cache_none
    if (w.c.cache_old) row.sc.cache_old = '' + w.c.cache_old
    if (w.c.cache_moved) row.sc.cache_moved = '' + w.c.cache_moved
    // the served-dige tally — the two lanes of the corroboration, hit meaning a read was skipped
    if (w.c.dige_hit) row.sc.dige_hit = '' + w.c.dige_hit
    if (w.c.dige_read) row.sc.dige_read = '' + w.c.dige_read
    delete row.sc.waiting
//#endregion
