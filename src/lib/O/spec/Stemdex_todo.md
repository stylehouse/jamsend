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

**Owed next, in order:**
1. Rescans on dige drift — genuinely owed, but lower urgency than first thought: Atlas isn't a durable
    daemon yet (item 2 below), so each `ghost_load` session gets a fresh scan anyway; the gap only
     bites within one long-lived session where a file changes mid-session.
2. Durability across a reload (the Dexie cache noted above), if reload frequency keeps making this
    ghost annoying to keep warm on a shared runner.

Roots now include `src/lib/data` + `src/lib/mostly` (the ground — TheC/TheX, Selection) and `spec/`
 (the doc-links census, `history/`/`shelved/` excluded) — 585 docs total.  The roster walks ONCE per
  world (`if (!w.c.rostered)`) — use `ghost_load --stand=Name --fresh` to force a genuine re-roster
   after a corpus-widening code change, not a bare re-stand (which is find-or-create and silently
    keeps the old roster).

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
