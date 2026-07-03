# Stemdex — the Doc text index (freetext · methods · properties): where it goes

The universal search's brain, split out to its own doc (2026-07-03) so the destination is
 designed rather than accreted.  v1 is BUILT and works, but it polls, it rescans whole files,
  and its first index of the repo is thumpy — this doc is the elegant path out.
Companions: `reactivity_docs.md` (the time discipline everything below obeys),
 `Wire_spec.md` (the reactivity redesign — helps the READ side someday, not the scan),
  `Lens_posable_TODO.md` (the Plank the hits hang off).

## 1. What stands (v1)

`LiesFunk.svelte` region "Stemdex": `w.c.stemdex` (off-snap Maps) holds, per doc, clipped
 lines + three vocabularies — **defs** (line-start method patterns; .md headings), **props**
  (`sc.key` | `.c.key` | `%Notation` — the particle vocabulary), **stems** (camel|snake-split
   tokens, lightly stemmed; postings stem → path → lines).  `e_Lies_stemdex_scan` is a polite
    pass (≤24 store reads + ≤8 whole-file scans, dige-gated per doc, awaited — limbs in Atime);
     a **Dexie cache** (db `stemdex`, one projection row per doc, dige inside) warms the whole
      index on the first pass — the first search of a session answers from yesterday's index
       while disk truth trickles in and re-scans only the dige-movers; rows persist at
        pass-end (bulkPut) and prune with the roster.  Strictly an accelerator: no IDB (node
         runner) → the old cold scan.  When §3's regions land, the cached row unit shrinks
          from doc to region shard — same table, same row-shape idea;
     `Lies_search` is a pure sync query (exact ▸ prefix ▸ substring name tiers; AND-across-
      tokens freetext ranked by hit mass).  Fed from the `%Good text/Doc` disk cache only —
       covers every doc in the loaded Wafts + the whole GhostList, opened or not; %Goods are
        confirmed off-snap, and contents staying in `.c` is the session's snippet store.
`ui/Searchbar.svelte` ('/' summons) + the DocWaftMap hang render it.  The panel is the
 **StemHive**: one flat list, every matched name with its FULL path, sorted by path (the
  path is the structure; ƒ|%|≈ glyphs ride the rows).  Mousing over a Waft — editor column
   or Plank chip — glows the member rows (hover threads through Liesui; membership is a
    settled walk under `H.clear`).  A hit click is ONE elvisto, `Lies_ghost_pick{path,
     point}` (def NAME or the `text:` Point bridge): a pick WITH a point is a search
      DELIVERY — always recorded in today's Aside, reusing the day's moment %What for that
       Doc, the Point riding under the %Doc as `{Point:1, method}` — then the want lands and
        `Dock_open` scrolls to it.  Trail homes are never point-polluted (a Point under a
         curated What feeds the LE checkout extent).

## 2. Principle — track ALL change, don't re-derive

The index should FOLLOW the corpus.  The change feeds already exist; v2 subscribes instead of
 polling:
- **live buffers** — `e_Lang_texting`'s 80ms burst stamps `dock/{Text}.sc.dige`: the live
   truth for open docks (v1's known blind spot — it sees disk only);
- **disk** — `%Good/{known}.sc.dige` moves when LiesStore lands a read;
- **structure** — a recompile empties `dock/{Compile}` (job.version bumps) and re-emits `%Map`
   (defs with class+line, regions with spans): the PRECISE def layer for open docks, which
    should override the textual def regex wherever it exists.
Lang→Lies hand-off for (a) and (c) rides the existing channels (dock_content / %Interest
 patterns) — Lies never reaches into Lang's docks.

## 3. Partition the scan by REGION (the anti-thump)

Whole-file rescan on any dige move is the thump.  The unit of rescan should be the **region**:
- docs WITH a `%Map`: its regions already carry spans + `region_path` — key posting buckets by
   `(path, region)`; on an edit, re-stem only regions whose slice-dige moved.  Scan cost ∝ the
    edit, not the file.  Typing follows along in near-real-time without anyone noticing.
- docs WITHOUT (closed / never compiled): fixed line-window shards (~64 lines) as synthetic
   regions — same bucket shape, no compile needed.
- one region = one sync splice (see §5); the pass budget counts REGIONS, not files.

## 4. Schedule as an errand, not an elvisto storm

The searchbar currently nudges scan passes on an interval.  The scan is background work — it
 belongs to the `%Upkeep`/`%Errand` layer ([[upkeep-errand-brink]]): a `Errand:stemdex` that
  chews its region queue a budget per beat, visible in the Brink ("stemming 214/380"), retried
   pass-based, idle-paced.  The searchbar then only READS; convergence is the errand's job.
    First boot can pre-warm lazily (errand starts on first '/' — no cost for sessions that
     never search).

## 5. Reactivity rules (reactivity_docs, applied here)

- **Swap, don't clear.**  Build a doc's|region's new projection ASIDE, then splice it in one
   sync step.  Never an empty intermediate: a query (or any UItime read) between "cleared" and
    "refilled" sees the vanish-for-an-instant class of bug — the same law as never emitting an
     empty Waft list mid-rebuild.  v1's per-doc rescan is already one sync block; keep that
      invariant when the unit shrinks to regions.
- **Limbs within Atime.**  No floating store promises (v1 bug, fixed — reads are awaited in
   the handler's own time).  The errand form makes this structural.
- **UI reads plain data.**  The searchbar reads only `w.c` Maps — no tree walks, so no
   transacting-state hazard and no mutex.  If a surface ever needs tree state beside the hits,
    it subscribes on `vers` and re-reads settled inside `H.clear` (the Langui pattern).
- **Wire_spec's nirvana** (pure-IO effects, the read/assign split) would make the read side
   declarative — but it does not change scan economics.  Partitioning (§3) is the perf fix;
    don't wait for the wire.

## 6. Query growth

- Prefix match iterates every stem key today; when it drags, a sorted stem array +
   binary-search slice (a trie only if that earns it).
- Postings carry lines already — same-line co-occurrence should outrank doc-level AND
   (phrase-ish relevance for free).
- **Scoping**: search within the fg Waft / one Interest's Docs — the Plank hang begs for it,
   and the waftmap's attention ladder (enth) is a ready-made relevance boost: things you're
    AT rank above things that merely match.
- One flat "best 8" across kinds (weight × hit-mass × attention) once the grouped list feels
   rigid.

## 7. Surfaces & the gate

- Plank: hang hit-counts on calm rows too (v1 hangs only under listed Doc chips), so a search
   lights the whole map spatially.
- A **LakeSearch Story Book** — fixture corpus, `%see` assertions over stems/defs/props/
   AND-ranking/convergence, run on the live runner.  The feature has NO fixture gate yet;
    this is the owed piece before the index grows cleverer.

## 8. Open questions

- Stemmer conservatism (`er`-strip collisions: user|users → us).  Safe while scan and query
   share the stemmer; revisit only on real relevance complaints.
- Corpus edges: `gen/*.go` excluded (generated); wormhole snaps currently in scope via the
   GhostList — useful (find a Book by a step name) but noisy for prose queries; maybe a kind
    facet on the hit row instead of exclusion.
- Memory: clipped lines ≈ the repo in RAM (few MB, fine for a dev tool); if it grows teeth,
   drop `lines` for cold docs and re-read the %Good at snippet time.
