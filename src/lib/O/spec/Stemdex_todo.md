# Stemdex_todo — the owed LakeSearch Book

## 0.

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
