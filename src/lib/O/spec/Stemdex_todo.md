# Stemdex_todo — the owed LakeSearch Book

## 0. What to get on with next

**LakeSearch is GREEN — sworn 2026-09-05, ×2 on the live runner** (`ok_pct:1, caveat:1`).  The §0
 below is now historical: the Book was not unverified-and-haunted, it was red on *furniture*.  All
  seven `SearchGate` assertions (`index_converged`, `method_search_finds_def`,
   `prop_search_covers_sc_and_notation`, `freetext_matches_on_shared_stem`,
    `two_token_and_ranks_denser_first`, `absent_word_returns_nothing`, `dige_move_reindexes`) stood
     in both the recorded and the live snap the whole time.  **Universal search has its fixture gate.**

*What the red actually was, worth knowing because it is a general trap:* the `want=` and `time,`
 spayers were fine.  What no spayer can forgive is a **structurally extra line** — a
  `see:🗂 3 docs` notice the live run reached and the recording had not.  A spay tolerates a noisy
   *value* in place (`EntropyArrest.md` §1); it cannot forgive a new particle.  So: one re-record for
    the settle, plus `Entcase:Self_round` for the `self,round={INT}` counter, then green twice.
     Fixture left clean per the hygiene rule — only `001.snap` + `toc.snap` (Entcase + `step,dige`);
      `Credulate`/`Credulation` run-log churn reverted.

### Next: relation EDGES in the index

The index knows NODES (defs, props, stems) and no EDGES.  Every navigation question that costs real
 time here — *who calls X, who elvistos whom, where is this mainkey minted, which `%see` proves this,
  which spec doc points at this line* — is an edge query over nodes the Stemdex already holds.

**Shape** (settled 2026-09-05 against the alternative of a Thangs/Relations home, which was scouted
 and rejected — Thangs is a Dexie↔particle mirror that puts every row *into* the C-tree as a particle
  with an object in `sc.stashed`, which is the encode-fatal shape this index explicitly refuses; and
   its liveQuery-per-change rhythm is the exact thump `Stemdex_spec` §3 avoids):

- `Lies_stemdex_scan_text` already receives `(path, dige, text)` and already walks every line emitting
   `defs_e` / `props_e`.  Add **`edges_e: [{from, kind, to, line}]`** as a fourth array on the same row.
- Adopt into `dex.edges` keyed by `to` (who calls X) and `dex.calls` keyed by `from`; drop
   symmetrically in `Lies_stemdex_drop`.  ~40 lines in a region that already has the pattern 3×.
- **Stamp an index-version inside the row.**  Dexie ignores the row body (only indexes need a schema
   bump), so cached rows from before would silently adopt with no edges and report "nothing calls X" —
    a wrong answer, not a missing one.  Version-stamp so stale rows re-scan.
- Kind order by value×reliability: **`calls`** (measured 93.5% of callees resolve to a known def) →
   **`mints`** (`w.oai({Mainkey` — the "verify unclaimed fleet-wide" need this codebase uniquely has)
    → `elvisto` (string literals, ~0% FP, the only cross-ghost edge) → `proves` (`%see:'…'`, 463 hits
     / 232 distinct, ~0% FP) → doc-links (1,708 `File:N` + 903 `[[slug]]` in `spec/`).
- **Not regex-extractable, needs the compiler:** the req↔do_fn graph.  Only 47/121 req names have a
   named `req_<name>`; `oai %req:X` with an indented block lowers to an anonymous `doai`, so a regex
    cannot tell "wired inline" from "orphaned".

**Two constraints on this work, both from the owner's own standing complaints:**
1. `.c` vs C\*\* foam.  This index is entirely off-snap `.c` Maps and edges add more.  Defensible (an
    index is a re-derivable derivation of disk; a Map in `.sc` is an encode fatal) but `Focus_todo`
     records the owner, 2026-08-29: *"hopefully with req and not using so much `.c` — you're not
      really supposed to."*  **Ask before adding index state; do not slide past it.**
2. No second timer.  The scan polls today (the searchbar nudges a pass).  `Stemdex_spec` §2 already
    wants v2 to SUBSCRIBE, and "Wire" is reserved for the reactivity project.  Riding the existing
     dige-gated pass is fine; **reaching for a new timer is the tell to stop.**

**Prior art check before designing any SURFACE for this:** `Lens_posable_TODO` — *"the
 posing/anchoring model is the unbuilt, uncooked part.  Don't build until the pose model is
  designed."*  And `Interest.md` already names the drawer ask (view-composition, gating the metromap),
   the flap mechanism (the lens "generalissimo" placement router, parked for want of proven need) and
    the AI-overlay idea (*"scribbles"* — an annotation/marginalia layer).  Read those first.

### 2026-09-08 — `ATLAS_MAPPER m12`: the cast-form call gap, found by the measured twin

Electrode (`Ghost/L/Electrode.g`, the runtime call tap — read with Atlas in `Wordland_todo.md`) joined
 its measured caller→callee tally against Atlas's `call,via` rows and showed `Lies_role → Lies_inside_story`
  ×207 measured with NO Atlas caller.  The source reads `(H as any).Lies_inside_story()` — and the
   `.svelte`/`.ts` branch gets ALL its call words from the per-line `CALL_RE` sweep in `_collect_line`
    (`compile.ts:532`'s own comment), whose `(?:this|H)\.` never matched a cast receiver.  158 such sites
     in `src/lib/O` beside 1,901 plain ones: ~8% of hand-written call edges were missing from every census
      since m1.  Fixed in `CALL_RE` and `CALL_GAP_RE` (`(?:this|H|\((?:this|H) as \w+\))\.`), mapper bumped,
       711 docs re-mapped in ~40s; `atlas_callers Lies_inside_story` now answers.  Emitted `.go` unchanged
        (`CHECK=1` LocalGen, two ghosts byte-identical).  `m13`, minutes later: the optional forms `H?.X(`
         and `(H as any).X?.(…)` (the join's next row).  Still NOT matched, on purpose: other House aliases
          as receivers (`top.X(`, `M.X(`, `SH.X(` beyond its accidental `H.` substring) — a design question
           for whoever widens the receiver set.  The reverse-direction lesson for this doc: the census's
            blind spots are cheapest to find by comparing it with what actually ran.

### LANDED 2026-09-05 (later the same day): `Ghost/L/Atlas.g` — every doc's `%Map`, kept

The design above was superseded before it was built, by the owner's four-word correction *"that
 looks like Map"*: the shape I was about to invent IS `dock/%Compile/%Map` — the compiler's own
  per-doc index (`def`, `call`, `region`, `controlflow`, from the REAL parser), which only ever existed
   for an OPEN dock and was `.empty()`ed each recompile.  So the work became: build that same `%Map`
    **headless** (`EditorState` from text — no dock, no `w:Lang`) for every doc on disk, and **keep** it.

**Standing on the live runner** (`da060c…`, via `runner_ask ghost_load Ghost/L/Atlas.g --stand=Atlas`):

```
w:Atlas
  see:atlas,docs:226,mapped:226,errors:0
  Doc:Ghost/M/Heist.g,dige:bd46e083…,lines:5249,defs:159,calls:337
    Map,dontSnap
      def,method:…,line,rel_from,rel_to
      call,method:…,via:…,line,…
      controlflow,keyword:if,title:…,via:…
      region,label:…,depth,from,to
```

- **Truth in foam.** One `%Doc:<path>,dige,lines,defs,calls` row per file (the census — ~230 legible
   lines that snap) with the compiler's `%Map` beneath, wearing `dontSnap` so ~700-row bodies stay out
    of Story fixtures.  Per-doc baskets sit ~1% under TheX's 6000 "giant stuff" ceiling.
- **minisnap reads INSIDE a `dontSnap` Map.**  `dontSnap` folds a subtree out of the Story snap only;
   minisnap's enWaft still walks it.  So the Map bodies are both fixture-invisible and CLI-readable with
    no new op — `runner_ask minisnap 'mundo>A:Atlas>w:Atlas>Doc:<path>>Map' --depth=1`.
- **The parser is the authority for `.g`** — Heist.g: Atlas 159 defs vs the retired regex probe's 158.
- **The `.svelte`/`.ts` blindness was NOT the collector's logic — it was a lazy parse, and the FIX
   LANDED IN `compile.ts` ITSELF (2026-09-05).**  First cut mapped `LangHold.svelte` (1691 lines, 49
    eatfunc methods) as **1 def**; the tsstho walk at `compile.ts:371-411` was always correct — it was
     reading an incomplete tree.  Two stacked causes, both measured headless: (1) CodeMirror parses
      lazily — a fresh unattached state's tree covered **116 of 89,519 chars**, so the walk saw the
       first member only; (2) forcing the parse with `ensureSyntaxTree` advances the parse *context*,
        but re-reading `syntaxTree(state)` still returns the language field's *snapshot* of that first
         116 — a dispatched transaction refreshes it in the live editor, headless nothing does.  Two
          local workarounds were tried and worked (force + an empty transaction to roll the snapshot),
           but the bug lived in the collector, not the caller, so **the real fix is `compile.ts`'s TS
            branch (`:348`) now calling `this.Lang_full_tree(state)`** instead of bare `syntaxTree(state)`
             — the same fix the markdown collector already used one function up (`:180`), whose own
              comment names this exact failure mode.  `Lang_full_tree`'s `parser.parse(...)` fallback
               parses the raw text directly, bypassing the snapshot entirely, so a plain unforced
                headless build is now correct — confirmed via a headless vitest probe (`Lang_compile_collect`
                 on a fresh `EditorState`, no forcing) and live on the runner: **49/49 members**.  Both
                  workarounds were removed from `Atlas.g` once the real fix landed; the ghost is simpler
                   for it.  **This also fixes the same latent short-Map for any big open `.svelte` dock
                    in the editor itself** whose idle parse hadn't caught up — not an Atlas-only bug.
- **Rows carry the mapper version (`by:m5`).**  A row whose `by` lags is re-mapped even with an
   unchanged dige — the index changed, not the doc.  This is what let each mapper revision (through
    the fixes below) re-map the whole corpus with no reset.
- **Runner-side, FSA, one pass.**  Reads the tree through `A:Wormhole.c.nav` (the same handle the
   editor's remote-wormhole serves from); polite budget of 6 docs per pass.  Convergence time varies
    with how busy the shared runner is (a concurrent `--watch` poller measurably slows it — seconds
     when idle, a couple of minutes when another session is actively running Books on the same tab).
- **The door:** `ghost_load` op in `LiesFunk` (`Lies_ghost_set` never consults the manifest;
   `--stand=Name` mints `A:/w:` so the worker ticks) — runner-only, bounded to `.go` files already on
    disk.  No `CREDULER_GHOSTS` edit needed.
- **⚠ Ephemeral across a reload.**  `A:Atlas`/`w:Atlas` are minted at runtime on `top_House()`, never
   persisted — a tab reload (a real page reload, distinct from HMR; console shows `"Restored directory
    for share 'Mundo'"`) recreates Mundo from scratch and the census is gone, needing `ghost_load`
     again.  On a shared, actively-edited dev runner this happens more often than one session's own
      testing would suggest.  Not yet fixed — see the memory `two-runners-pin-with-runner-flag.md`.
       A Dexie cache (the Stemdex's own pattern: one row per path, dige inside, warm-on-boot) would
        make this instant instead of a full re-scan; not yet built, since re-scanning 245 docs is cheap
         enough on an otherwise-idle runner that it hasn't been worth the extra machinery yet.

**DONE 2026-09-05, both verified headless + live: the two `compile.ts` collector gaps.**
1. **Top-level `function` declarations in `.ts`.**  The tsstho walk collected `PropertyDefinition` and
    class names, not `FunctionDeclaration` — `vyto_foam.ts` mapped to 0 defs.  Fixed: a new
     `FunctionDeclaration` case in the walk (`compile.ts:~404`), using the `VariableDefinition` child
      for the name (jump-to point) and the whole node span for containment (item 2, below).  Verified:
       `vyto_foam.ts` → **7 defs** (`sig_of, group_edges, bucket_key_of, focus_mag, budget_for,
        fold_ladder, pull_step`).
2. **`via` on TS-branch calls.**  `ctx.current_method` is stho-only, so every `.svelte`/`.ts` `%call`
    was born via-less.  Fixed with a **`def_spans` side table + a post-pass**, not by threading
     `ctx.current_method` through the tree walk: `Property`/`MethodDeclaration`/`FunctionDeclaration`
      nodes all span their WHOLE body (confirmed: `e_Lang_lango` → `[2896,3219]`, exactly
       `"async e_Lang_lango(...) {…},"`) — not just the identifier `words` already records — so each
        def's full range is recorded once, and after the per-line call/controlflow sweep runs, every
         via-less entry is attributed to the smallest containing span.  Verified: `LangHold.svelte`
          **117/117 calls now carry `via`**; `upto_w`'s five call sites correctly report five distinct
           enclosing methods (`req_workon`, `req_understanding`, `req_ingredients`, `req_furnishing`,
            `req_instrumentation`).  A `.g`/stho file is provably untouched (`def_spans` stays empty on
             that branch): `Heist.g` unchanged at 159 defs / 337 calls before and after.

**DONE 2026-09-06: `AtlasStaple` — the Book that swears the DRIVE.**  `Ghost/L/Atlantation.g`
 (naming: Voro→Voronation, Vyto→Vytonation, Atlas→Atlantation).  Green ×2 on the live runner,
  `ok_pct:1, caveat:0` — 4 steps: load-on-demand, converge on a frozen fixture corpus
   (`Ghost/L/test_corpus/Sample.g`, never Atlas.g's own directory — editing Atlas.g will keep
    happening and a self-referential corpus would stale the fixture every time), inject an
     unreadable Doc and confirm the error path marks it without spinning, and stamp a stale mapper
      version to confirm a re-map REPLACES the Map rather than piling a second one.  All 5 `%see`s
       fired and are visible directly in the step-4 snap.  Two real bugs found and fixed getting
        here, both worth remembering for the NEXT `.g` Book authored from the CLI (neither is
         Atlas-specific):
1. **The hollow-1-step trap, twice over.**  The documented fix (`if (run.sc.mode==='new')
    run.sc.total = N`, the Vytonation/VytoCrest idiom) is necessary but was not sufficient here —
     the REAL first cause was that `Ghost/L/Atlantation.g` (the file DEFINING `AtlasStaple`) had
      never itself been `ghost_load`ed onto the runner.  Story silently ran an empty step and
       settled at n:1 with **no** `req:wrangle` particle even minted — do_fn_for found no handler.
        **A new Book's OWN `.g` file must be `ghost_load`ed before `run`, same as any other L/
         ghost — it does not become runnable just because a toc.snap and a matching world-name
          exist.**  Every hollow recording along the way needs `rm -rf wormhole/Story/<Book>` +
           a fresh toc seed before the next attempt (memory: `hollow-book-1step-green.md`).
2. **Never `await` real, multi-tick-dependent work directly from the drive.**  An early version
    `await`ed `Lies_ghost_set(...)` (a dynamic import whose eatfunc only lands once Otro reactively
     mounts the new UI row — which needs FURTHER belief-loop ticks) directly inside a beat called
      from the drive.  That holds the very tick loop the load depends on to complete — a circular
       wait.  `expecting()` exists precisely so real async work runs OFF the mutex; every beat
        function itself must stay fire-and-forget from the drive (matching every existing Book).
3. **`%desc` text needs the same comma discipline as `%see`.**  A `%desc:'…a, b, c'` with literal
    commas doesn't fault, but silently drops the step out of the normal `step=N,desc:…,dige:…`
     peel notation into a raw JSON blob in the toc — harmless but inconsistent with every other
      Book's fixture.  Use em-dashes, as `%see` already requires.
4. The one genuine environmental cost: this runner is shared with another live session running an
    automated Book sweep, and `run`/`accept` do not queue — a competing `run` request steals the
     engagement lease mid-flight, corrupting an in-progress recording into a fresh hollow one.
      Several attempts here were lost to exactly that interleaving; there is no fix from this side
       beyond retrying once contention clears, and not fighting for the lease aggressively.

**DONE 2026-09-06: the three added kinds — `%elvisto`, `%mint`, `%proves`.**  Verified headless
 against real files and live on the runner (Atlas's own census, `ATLAS_MAPPER='m6'`):
 `Vytonation.g` → 7 `elvisto` rows (`Vyto/Vyto::Vyto_commission`, matching the 2026-09-05 census),
  80 `proves` (deduped from 160 raw — see the bug below), 70 `proves,desc:1`; `Vyto.g` → 27 `mint`
   rows, `Organ` present, the `A`/`H` housing-shelf false positive excluded.

- **First attempt placed the sweep INSIDE `_collect_line` and it silently missed almost every
   `%see`.**  `%see:'…'` overwhelmingly appears inside the "once-noticed" idiom —
    `if (cond && !(oa %see:'X')) i %see:'X'` — a ControlFlow-shaped line, and `_collect_line`'s
     ControlFlow branch **returns before** reaching a sweep placed after the existing CALL_RE section.
      Headless test caught it immediately: 0 sees found, all 70 hits landed as `%desc` instead.
       **Fix: a TRULY INDEPENDENT full-document pass**, iterating `doc.line(i).text` for every line
        directly, placed after the main per-line while-loop — immune to any other branch's early
         return.  First cut deliberately carries no `via`/`region_path` (a line number is already the
          whole value here; enclosing-method attribution for these three is left owed).
- **The "once-noticed" idiom writes the same sentence TWICE per line** (`oa` guard + `i` mint) — one
   assertion, not two.  Deduped per-line by sentence text; `sees` dropped from 160 to the correct 80.
- **`mint` excludes `A` and `H`**, not just `A` — `.i({A:'X'})`/`.i({H:'X'})`-shaped mints are housing
   shelf tokens (a House/Actor), never a particle mainkey (2026-09-05 census finding).

**DONE 2026-09-06 (same day, `ATLAS_MAPPER='m7'`): `via` for all three, dialect-uniform.**  Not
 `def_spans` (character-range containment — tsstho-only, since only that branch populates it) but a
  simpler, UNIVERSAL heuristic: **the last top-level `def` whose line is ≤ this line, from the
   already-collected `def` words of EITHER branch.**  Sound because a `.g` method sits at column 0
    and its body runs to the next column-0 def — defs never nest (a class's own members are separate
     `def` words with their own line) — so "the nearest def above" is always the true enclosure, on
      both dialects, with no new tree-walk.  Verified 100% coverage both ways: `Vytonation.g`'s 7
       `elvisto` rows attribute to **7 different enclosing beats**
        (`VytoStaple_commission, VytoCell_commission, Vyto_commission_on, VytoFreeze_stand,
         VytoSeek_stand, VytoWeb_focus, VytoWeb_release`) — each Book's own commission call, correctly
          told apart; `Vyto.g`'s `Organ` mints all attribute to `Vyto_board` (correct — that's the one
           function that mints them); `LangHold.svelte`'s 4 `elvisto` + 15 `mint` rows all carry `via`.

**A genuine timing flake surfaced by running ×3, not settling for ×1 green** (Coding_guide: "a race
 is invisible in a single green run").  `AtlasStaple`'s `bogus_wait`/`stale_wait` beats held an 8s
  ttlilt; on this shared, contended runner that occasionally wasn't "above the worst case"
   (`expecting()`'s own contract), so Story sometimes snapped the ttlilt's TIMEOUT picture
    (`req:bogus_wait` still open) instead of its RESOLVE picture (`req:bogus_wait,finished`) — a
     structural presence/absence difference no `EntropyArrest` spay can paper over.  Fix: raised both
      to 20s, matching `seed_wait`'s existing headroom.  Robustly green ×4 after.

**DONE 2026-09-06, same day (`ATLAS_MAPPER='m8'`): `.md` docs — the doc-links census.**  This was the
 ORIGINAL high-value target from the very first census of this whole effort (1,708 `file:line` + 903
  `[[slug]]` refs measured in `spec/` on 2026-09-03) — code-side kinds came first only because they
   were cheaper to prove.  New `%link,kind:wiki|file` kind, added to `Lang_collect_markdown_regions`
    (a SEPARATE collector from `Lang_compile_collect` — headings, not defs — so this is its own small
     independent sweep, same idiom).  `spec/` un-skipped in `Atlas.g` (`history/`/`shelved/` stay
      excluded — retired, not living); `md` added to `ATLAS_EXT`.  **Full corpus, both live and
       headless: 585 docs (245 code + 340 markdown), 0 errors.**  `Radio_todo.md`: 63 regions
        (headings, unaffected) + 85 links (15 wiki + 70 file), matching the 2026-09-03 census closely
         both headless and live.  Bare `Name.ext` mentions (no `:line`) deliberately excluded — the
          census found them the noisiest of the three link forms.

- **A real gap in `ghost_load --stand` found along the way, unrelated to markdown itself.**  `--stand`
   is `oai` — find-or-create — so re-standing Atlas after widening its OWN corpus (this exact m8
    change) silently kept the OLD, narrower roster: a ghost like Atlas whose `Atlas()` do_fn only
     rosters once (`if (!w.c.rostered)`) never notices a code change that should have produced a
      bigger roster.  **Fixed: a new `--fresh` flag** (`ghost_load ... --fresh`) that drops any
       already-standing `A:<name>` before minting — the same "clean glass each run" the Book
        convention already uses (`AtlasStaple`/`VytoStaple`'s own `if (old) SH.drop(old)`), now
         available from the CLI.  Verified: without `--fresh`, a re-stand stayed at the stale 245;
          with it, 585.

**DONE 2026-09-06, same day (`ATLAS_MAPPER='m9'`): `region_path` for `link`.**  Same "last entry
 before this line" trick as `via`, but carrying the WHOLE ancestor array, not just a name — each
  heading word already recorded its own stack-at-that-moment as `region_path`, so the nearest heading
   at-or-above a link's line names the section chain it lives under.  **100% coverage**: `Radio_todo.md`'s
    85 links all carry a real chain (verified 3-deep for a `Heist.g` reference:
     `["Radio_todo.md — the music-piracy cluster, reborn on Housing+req", "0. Latest handover — …",
      "2026-08-24 — THE LOOP THAT NEVER GIVES UP…"]`).  `elvisto`/`mint`/`proves` (the code-side three)
       do NOT get this — a `.g`/`.svelte` `//#region` chain is a much weaker signal than a markdown
        heading (regions are sparse and often absent in code, ubiquitous in docs), so it stayed
         deliberately out of scope; `via` already carries the equivalent code-side information.

**DONE 2026-09-06, same day: the reverse lookup — `atlas_callers`.**  Not a reverse INDEX (a second
 structure to keep in step with the first — exactly the sync-code smell "five readings, nothing
  stored" avoids elsewhere here) but a plain query: `Atlas_callers(w, name)` walks every mapped
   `%Doc`'s `call` + `elvisto` rows for `name` and returns `[{doc, line, via, kind}]` — a which-file
    answer, not just minisnap's count-and-line.  At 585 docs this is milliseconds, no index needed.
     New `atlas_callers <name>` op (`LiesFunk`, read-only, player-safe like `minisnap`) refuses plainly
      if `A:Atlas` isn't standing yet, rather than silently returning `[]`.  CLI:
       `runner_ask atlas_callers upto_w`.

**DONE 2026-09-06 (later): the census stays current, survives a reload, and answers three lints.**
 The owner's question — *"does this not go out of date when things change? only if we use the
  thing..?"* — is the design: **use nudges a pass** (the Stemdex's own searchbar rhythm; no second
   timer, per the standing constraint above).  Verified live on both shared runners, under a reload
    storm from another session's compiles (every gen write full-reloads every tab on :9091).

- **`Atlas_refresh(w, nav)` — every `atlas_*` query runs it first** (`--stale` skips).  Re-list the
   roots with forced `expand()` (WormholeNav caches listings), mint the new, un-stamp `by` on any Doc
    whose **mtime+size** moved (they ride `doc.c`, a cache — the dige stays the truth), drop the gone,
     then map the movers INLINE up to `ATLAS_REFRESH_MAP=24` and hand a bulk remainder to the pass.
      Before the first roster it IS the roster.  Measured: 0.8s round trip for a no-change refresh of
       the full corpus; `touch` one spec → `changed:1,mapped:1`, its `warm` cleared, next refresh zeros.
        Repeated `atlas_refresh` calls also converge a cold census from the CLI with no belief loop at
         all (687 docs in 73s) — which is what made verification possible while the other session's
          Books held both runners' tick loops.
- **Dexie `atlas` cache — the Stemdex's own `Lies_stemdex_db` pattern** (PK `path`, row body = the
   Doc's sc + every Map row's sc with `region_path`/`abs_from`/`abs_to` carried as plain fields; the
    mapper version INSIDE the row invalidates, no schema bump).  A Doc with no Map is ADOPTED when the
     row's mapper+mtime+size match (`ATLAS_ADOPT=40` per pass — mint-only, far cheaper than a parse) and
      stamped `warm`; a Doc whose Map is merely stale is always a real re-map (the row IS what the stale
       Map came from).  **After a tab reload the whole 587-doc census came back warm in 2.8s inside one
        refresh call** (586 warm; the one cold doc was one the other session had edited since — correct).
         IndexedDB is per-origin, so the rows written by one runner warm the other.
- **Roster widened to `['Ghost', 'src', 'scripts']` (587 → 687 docs, 0 errors).**  The link lint's
   first run showed most "missing" targets were not gone but merely unrostered (`src/lib/ghost`, `p2p`,
    `scripts/daemon/main.ts`, the relay).  `.mjs` stays out — no grammar.  `gen/`, `history/`,
     `shelved/` still skipped.
- **`ATLAS_MAPPER='m10'` — one more collector gap, found BY the census.**  The stho per-line `CALL_RE`
   sweep sits after `_collect_line` branches that return early, so a call on a ControlFlow line — the
    Book drive idiom `if (n === 2) this.Beat(w)` — was never recorded; the orphan lint listed every
     Book beat as uncalled.  Fixed in `compile.ts` with a whole-document `CALL_GAP` sweep (stho only,
      dedup by offset, via + region_path from the enclosing def).  `atlas_callers AtlasStaple_seed` now
       answers `Atlantation.g:33 via AtlasStaple_drive`.
- **`atlas_lint` (+ `--sees`)** — three answers over what is held, no new state:
   `missing` (a `file:line` whose target file is in no living root — 18 real ones after the widening:
    `Ghost/M/Jam.g` ×6 (deleted 2026-09-04), `Interest.svelte`, `BigQualand.svelte`, `Housing.svelte`
     (now `.svelte.ts`), `LiesHold/LiesEnd/LiesWaft/Runner.svelte`…), `beyond_eof` (3 — target exists,
      cited line past its end), `orphans` (2084, a scan aid: do_fns named after their world, UI handlers
       wired in markup and `this[name]` dispatch all read as orphans; `IMPORT` and `req_/e_/Run_A_`
        excluded), and with `--sees` **`unproven`: 137 of 242 authored `%see` sentences are in NO Book
         fixture** — Voronation.g 68, Swarmation.g 28, Vytonation.g 25, Radiation.g 11.  Reads every
          numbered snap of every Book (~1000 reads, ~12s — sentences do NOT strictly accumulate across a
           Book's snaps, VytoStaple's 006 holds 4 and 007 holds 3, so the union is the truth).
- **`AtlasStaple` re-recorded at 6 beats, and the lint caught that the old 4-beat fixture was hollow
   at beat 3:** its recorded `003.snap` held `req:bogus_wait` with the ttlilt still OPEN and the
    'unreadable' sentence in no snap — every "green ×4" re-run had matched that broken picture.  Root
     causes, all fixed: (a) an injected Doc only got mapped when Atlas's world ticked, which a Story run
      does not pump — the beats now DRIVE `Atlas_pass`/`Atlas_refresh` directly (the logic under test);
       (b) `AtlasStaple_restale_ready` was trivially true before beat 4 stamped `m0` (gated on
        `w.c.stale_at` now); (c) the 'deleted' claim could fire off beat 3's NoSuchFile being dropped
         (gated on 'found' now); (d) the unreadable path never stamped `by`, so the pass retried it every
          tick — the very spin the sentence swears against; (e) **`Atlas_report`'s `w.r(...)` was an
           un-awaited async replace, and until a replace commits `o()` on that world answers with only
            what the replace has added so far** — one microtask after a pass the beats saw `docs: []`.
             Awaited it, then removed the replace entirely (oai + stamp; a per-tick replace keeps a
              partial-`o()` window open for every other do_fn on that tick).  Memory:
               `r-replace-partial-o-window.md`.  Beats 5 (drift: write → change → delete through the
                tab's own nav, refresh after each) and 6 (drop A:Atlas, re-stand, `warm` from the rows
                 beats 2-4 wrote) added.

**DONE 2026-09-06 (later still): acted on the lints — 7 real dangling references fixed, 2 bugs found
 IN THE LINT ITSELF, one real gap diagnosed and left for its owner.**  `ATLAS_MAPPER='m11'`.

- **Two lint false positives, both caught by investigating "missing" hits before touching any doc**
   (never trust a lint's own verdict without checking the target actually exists):
   1. `FILE_RE`'s `\b` breaks at a hyphen, so `relay-test.ts:55` truncated to `test.ts:55` and read as
       a dangling link to a file that never existed — `scripts/relay-test.ts` and
        `scripts/runner-ask-test.ts` both exist right now.  Fixed with a negative lookbehind.
   2. A target naming `history/` or `shelved/` (`Vyto_sizing_todo.md`'s own
       `history/Voro_todo_parts_2026-07.md:392`) was flagged missing because Atlas never rosters those
        shelves — it had no way to confirm OR deny the link, and guessed wrong.  `Atlas_lint` now skips
         a target that names either shelf explicitly, rather than claiming it's gone.
- **Five stale `file:line` references repaired to where the content actually lives now**, each verified
   by finding the real definition/anchor before touching the doc, never by guessing a nearby line:
    `Daemon_todo.md` → `BigQualand.svelte.ts:47` (the file gained a `.ts`, and the old 14-line range no
     longer matched a 63-line function — cited the def line, not a fabricated range);
      `Everything_todo.md` → `Housing.svelte.ts:581` (`setInterval … 3000` relocated) and
       `Lang.svelte:1796` (`Lang_bookmark_vanished` moved 346 lines down the same file);
        `SoundPooling_todo.md` → `Ghost/M/Siphon.g:92` (`Siphon_pull`, file shrank from >152 to 128
         lines); `Perf_todo.md` → `Lang.svelte:734` (`Lang_build_mapules`, moved off the deleted
          `LiesHold.svelte`).
- **One stale CLAIM caught alongside the stale reference, in `Perf_todo.md`.**  The line said
   `Lang_build_mapules` was ungated; its own current header comment says "Content-gated … Hashed once
    per recompile" — the fix already shipped and the doc's own later `## Ranked levers` section already
     says so (`§status: DONE`).  The earlier diagnosis paragraph just never got the same annotation.
      Added `(§status: DONE — see lever 6 below.)`, matching the doc's own established convention rather
       than inventing new phrasing.
- **One stale claim in `Mag_todo.md`** cited `Jam_event`/`Jam_tally` as still-standing proof of a design
   point, six other places in the SAME doc already note `Jam.g` was deleted 2026-09-04 — this one
    paragraph just predated the deletion and was never touched.  Annotated in the doc's own existing
     style ("kept here as the still-valid worked example") rather than rewriting the argument.
- **Left alone, on purpose, after checking:** the remaining 14 missing + 1 beyond-EOF are either (a) a
   `%Jam` reference already self-annotated as deleted inline in the SAME sentence (`Radio_todo.md`,
    `Voromay_todo.md` — nothing to fix, the doc already says so), (b) inside
     `spec/ulative/memory-raw/` — an explicitly-named raw archive, narrating a repo shape from before
      the file existed to move; editing it would falsify the record it's keeping, or (c)
       `Download_stall_handover.md`, a point-in-time diagnostic explicitly marked "retire to
        `spec/history/` when triaged" — not evergreen prose, not mine to edit.  **The corollary this
         confirms**: a lint over a corpus this size will always need a human eye on "missing" before
          any edit — the two false positives above were as common as the five real fixes.
- **The unproven-`%see` count (137 → 21) mostly resolved itself** as other work landed real Book
   recordings in the meantime — evidence the lint tracks live state, not a snapshot.

**DONE 2026-09-06 (owner's own call): `SwarmCohort` given its first real recording, and a genuine
 bug found in the process, not just a missing fixture.**  `wormhole/Story/SwarmCohort/toc.snap` had
  never recorded past step 1 (`001.snap`, zero `see:` lines) though `SwarmCohort_drive` dispatches
   five real beats (2–6, `Swarmation.g:1972`); it never set `run.sc.total` on a fresh run — the exact
    `hollow-book-1step-green.md` trap.  Fixed with the same `if (run.sc.mode==='new') run.sc.total=6`
     idiom this same file already uses on `SwarmReboot_drive` a few hundred lines up.  Re-recording
      surfaced a real bug the hollow fixture had hidden since authorship: beat 2's witness checked
       `sibA.sc.role === 'cave'`, but `Swarm_sibling` (`Swarm.g:5828`) mints the field as `sc.duty` —
        `Swarm_take_role` was renamed to `Swarm_take_duty` at some point (the alias comment right there
         says so) and this one check was never updated, so that sentence could never have fired under
          ANY recording.  Fixed the field name, not the fixture — recorded fresh, all 7 assertions
           confirmed firing across the 6 snaps, green ×3 (`ok_pct:1, caveat:0, mode:check` on both
            re-runs).  **The corollary this confirms**: a hollow fixture doesn't just mean "unverified"
             — it can hide a real, silent, permanent break in the very thing it exists to check.

**Owed next, in order:**
1. The remaining 14 unproven sentences (`SwarmGot`×7, `SwarmPolicy`×1, `VoroRadio`×2, `VoroMitosis`×2,
    `VytoMemo`×1, `VytoCrush`×2, `VytoOrchestra`×1) belong to Books with real, multi-step recordings
     already — "fixture never re-sworn" after the code moved on, not "never recorded" like
      `SwarmCohort` was.  Lower urgency, same fix shape if the owner wants them chased: re-run, check
       whether the gap is a stale fixture or another live `role`-style rename, re-accept.
2. Mtime as the ADOPT gate has a real, narrower-than-first-thought hole (owner's own challenge,
    2026-09-06): a same-nanosecond, same-byte-length edit — reproduced live only by deliberately
     forging a file's mtime with `touch -r`, never by any normal save — passes the mtime+size check
      with genuinely different content.  `Atlas_cache_adopt` now re-reads+diges before trusting a
       COLD adopt (cheap next to the parse it skips; closes the "just reloaded" case for real).  The
        STEADY-STATE case — a doc already mapped in the current world — never even reaches that check;
         it's gated purely on `Atlas_walk`'s own mtime/size listing comparison, so the same collision
          there is still live in principle.  Proposed, not built: a small rotating re-dige of already-
           mapped docs each refresh (independent of mtime), self-healing any missed drift within a
            bounded number of passes, in the same "polite budget" spirit as `ATLAS_BUDGET`/`ATLAS_ADOPT`.
             Separately: `RemoteWormholeNav.dir()` carries no mtime/size at all (bare `{name}` entries)
              — a real blind spot if Atlas is ever stood against a remote node's nav instead of the
               local FSA one, though not a live risk today (every current use is local).
3. `atlas_lint` reads for `--sees` could ride the census itself if `wormhole/Story/**/*.snap` were
    rostered as docs with a tiny `see:` collector — one read per snap per change instead of ~1000 per
     ask.  Only worth it if the lint gets asked often.
4. The `Atlas()` do_fn still calls `Atlas_pass` every tick once converged (an `o()` walk over all Docs,
    cheap but pointless); a `w.c.converged` latch cleared by refresh would quiet it.

Roots are `Ghost`, `src`, `scripts` (687 docs; `gen/`, `history/`, `shelved/`, `node_modules`
 skipped; `.mjs` has no grammar).  The pass rosters ONCE per world (`if (!w.c.rostered)`) and every
  query re-rosters via `Atlas_refresh` — so a corpus-widening code change is picked up by the next
   query, or by `ghost_load --stand=Name --fresh` (a bare re-stand is find-or-create and keeps the
    old world).

*(The regex probe `scripts/drawer.mjs` was deleted the same day — its regexes validated at 93.5%,
 its load inventory recorded in `Atheory_todo.md`, its one real find — `upto_w` byte-identical in
  `Hovercraft.svelte:308` and `Lang.svelte:551` — kept here.)*

---

*Historical §0 below (the scaffold note, superseded by the green above):*

**BUILT 2026-07-21 (scaffold, UNVERIFIED — commit f96d71eb).** Authored and compiles: `Run_A_LakeSearch`
 + `e_Lies_search_selftest` in Machinery.svelte, `wormhole/Story/LakeSearch/toc.snap` (placeholder dige
  a0a0…), Credence line (the linter placed it under What:Misc, not What:Lake — cosmetic; the Book still
   runs via Run_A_ + toc). Needs a first live `--accept` to mint 001.snap + the real step dige; some beats
    may want corpus tuning. Corrections the build found vs the brief below: (a) `Lies_search` returns
     `{defs,props,texts,done,total}` — NO `missing` (it lives on the dex handle: `Lies_stemdex(w).missing`);
      (b) a seeded %Good needs a `known` child for its dige (`good.oai({known:1}).sc.dige=…`) AND a roster
       `%Doc` node (`Waft>What>Doc:path`) — the Good alone isn't indexed; store = `await H.LiesStore_req(w)`
        (= `w/req:Store`); (c) quux.ts holds BOTH stems (records→record + frobnitz), so beat 4 KEEPS it and
         just ranks zorble denser-first — not excluded; (d) Present/toc.snap needs no entry, Credence line
          is bare. Verify: `runner_ask run LakeSearch --watch`, then `--accept` and green ×2 on the live runner.

Original brief below (kept for the corpus + beat design):

Next move: build **LakeSearch** — the Story Book gate for universal search (Stemdex + Searchbar),
 owed since the feature landed (spec §7 names it). The full plan is below, drafted 2026-07-20 from
  a source-verified research pass (LiesFunk "Stemdex" region 1262–1615, ui/Searchbar.svelte, the
   Lake* mould in test/Machinery.svelte). Execute after the pending commit lands. Arc: the feature
    has NO fixture gate today; this Book closes that, then the `%Map` live-defs layer (unsaved
     buffers) remains the next feature step per Stemdex_spec.

## Naming verdict: LakeSearch, not MusuSearch

Universal search is Lies/editor machinery — its siblings (LakeLocate, LakeFunk, LakeWaftMap,
 LakeLango, LakeKeep) are Lies self-test Books in `src/lib/O/test/Machinery.svelte`, dispatched
  `Run_A_<Book>`. Stemdex_spec §7 literally names "A LakeSearch Story Book". Credence home =
   the `What:Lake` cluster.

## Shape: the LakeLocate mould

One-Prep self-test: `Run_A_LakeSearch` wires the standard trio (A:Lies/w:Lies, A:Lang/w:Lang,
 A:Pantheate/w:Pantheate); toc `Plan > Prep > i_elvisto:Lies,e:Lies_search_selftest`; one
  `step,dige:` line. The async handler builds a synthetic corpus, drives the REAL index, fires
   every query, records durable claim markers `gate.i({<claim>:1})` under a gate particle —
    claim names in the snap are the gate, never raw result blobs. The DOM Searchbar can't mount
     on a runner (editor chrome, `!Lies_is_runner`); proving the brain (`H.Lies_search`) + the
      pick elvisto proves the feature.

## Corpus: coined, collision-proof, seeded — never disk

One backstage `Waft:SearchW` built `{equip:'Search'}` (folds from the snap, LakeLocate style).
 Per doc: `What > Doc:<path>` so Lies_walk_docs collects it, text seeded via the store —
  `store.oai({Good:1,type:'text/Doc',path})`, `g.c.content = text`, `known.sc.dige = fixed` —
   so NO store read ever fires (an unseeded doc = ttlilt + real disk = nondeterminism). Coined
    vocabulary (zorble/frobnitz/gleeb/wibble…) so a Dexie-warmed real-repo index can never
     collide with a query. ≤8 docs (one scan pass converges; stays under the Seemables
      paths.size>50 mirror gate). Three docs:

1. `SearchW/zorble.md` — `# Zorblender overview` (heading def); body holds `recording`
    (stem `record`) + `zorbler` (stem `zorbl`) + `frobnitz` several times.
2. `SearchW/frobnitz.ts` — `function frobnicate(x) {`; `const zorbler = (n) => {`;
    lines using `sc.gleeb`, `.c.wibble`, `%Zorblet`; contains `zorbling`.
3. `SearchW/quux.ts` — `records the frobnitz once` (second frobnitz doc, ONE hit — the
    thin partner for the AND-ranking beat; `records` → stem `record`).

## Beats (all inside the one Prep; bump gate + w at the end)

- **0 seed + one real pass**: seed all %Goods, `await e_Lies_stemdex_scan`; assert
   `Lies_search(w,'zorble',24)` gives `total===3 && done===3 && missing===0`.
   claim `index_converged` — "the index converged — every seeded document reports indexed
    with none missing"
- **1 method ƒ**: `'frobnicate'` → `.defs` has {name frobnicate, path frobnitz.ts, line L}.
   claim `method_search_finds_def` — "a method search finds the function definition by name
    with its file and line"
- **2 property %**: `'gleeb'` (sc key) and `'Zorblet'` (%Notation) both land in `.props`.
   claim `prop_search_covers_sc_and_notation` — "a property search surfaces the particle
    vocabulary — an sc key and a %Notation mark alike"
- **3 stem beats substring**: `'recorded'` — corpus only ever writes `recording`; substring
   fails both directions, shared stem `record` hits zorble.md in `.texts`.
   claim `freetext_matches_on_shared_stem` — "a freetext query matches on a shared stem —
    recorded finds recording which a plain substring scan would never see"
- **4 AND + rank**: `'frobnitz recording'` — only zorble.md holds both stems; quux.ts
   excluded; tune counts so the winner strictly exceeds the field (no tie).
   claim `two_token_and_ranks_denser_first` — "a two-word query keeps only docs holding both
    stems and ranks the denser match first"
- **5 the miss**: `'xyloburst'` → all three result arrays empty.
   claim `absent_word_returns_nothing` — "a query for a word nowhere in the corpus returns
    nothing — no false hit"
- **6 dige freshness** (recommended): re-scan unchanged → nothing re-tokenizes; mutate
   zorble.md content (+ token `snarfle`) + move its dige → re-scan → `'snarfle'` hits.
   claim `dige_move_reindexes` — "editing a document and moving its digest re-indexes only
    that document"
- **7 delivery pick** (DEFER from v1): `Lies_ghost_pick{path,point:'frobnicate'}` → Point
   lands in today's Aside — drags in Lang foreground + a date-keyed `Waft:Aside/<YMD>`
    (fixture churn). Leave out unless the YMD is munged by an Opt.

## Hazards (the load-bearing bits)

1. **GhostList roster = THE hazard.** toc `Opt > For > w:Lies > dontSnapGhostList` (opts out
    of the WORK, not just the snap) + defensive `gl.sc.dontSnap = 1` in the handler, exactly
     as every Lake* sibling. Verify live that `total` sits at 3 (no stray roster docs).
2. **Dexie `stemdex` warm** loads real-repo rows on a live runner — neutralized for results
    by the coined vocabulary; `total/done` count only the roster. Side effect: our synthetic
     rows bulkPut into the dev IDB cache; pruned on the next real >50-roster search. Fine.
3. **Await the scan** (async, store reads); seed EVERY doc's content first.
4. **`dex.scanning` mutex** — drive passes sequentially, never a burst.
5. **Tie order unspecified** — assert set membership + the strict `.texts[0]` top only.
6. Keep corpus small (Seemables mirror gate fires at paths.size>50 — never trip it).

## Fallback if the live fixture won't sit

Pure isolation: skip `e_Lies_stemdex_scan`; `Lies_stemdex(w)` fresh dex +
 `Lies_stemdex_scan_text(dex, path, dige, text)` per doc directly (no IDB, no store, no
  roster), then `Lies_search`. Keeps beats 1–6; loses only beat 0's convergence counts.

## Registration checklist

- `Run_A_LakeSearch` + `e_Lies_search_selftest` in `src/lib/O/test/Machinery.svelte`.
- `wormhole/Story/LakeSearch/toc.snap` (story, Styles, Plan/Prep, the Opt, one step line).
- Add to the Library `wormhole/Present/toc.snap`.
- Credence board: `Funkcion:Storying,of_Book:LakeSearch` under `What:Lake`, comma-free
   `desc:`, `brand_new:1`; NOT `%unusual` (must run in the sweep).
- Verify on the live runner only (`runner_ask.mjs run LakeSearch --watch`); record green ×2.
