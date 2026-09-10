# Docindex_todo.md — the off-tab doc index: a WAFT the watcher writes, not a thing the tab asks for

*(was `Docmag_todo.md` for about an hour on 2026-09-10 — see "IT IS A WAFT, NOT A MAG" below, which is
 the correction that makes most of the first draft unnecessary rather than wrong.)*

**The owner, 2026-09-10:**
> *"we should do an off-tab editor junk caching. we NEED to see mtime and so forth quickly, not from
>  the browser but pushing TO the browser. lets scan|watch those docs into some Mag-style overview
>   that we can then Repli to the editor? or something like that. Seem can see what changes."*
> *"we keep building variations of the perfect metaphysical system, try to reuse the parts... C, Seem, etc."*

## 0. What to get on with next

### ☀ WHERE IT STANDS — 2026-09-10 evening, handover. READ THIS FIRST.

**The road is built and measured end to end.** The tab no longer walks the tree, no longer reads 728
 files, and no longer rebuilds 43,945 particles a document at a time. It reads one Waft for the roster
  and decodes one snap for the census.

| | before | now |
|---|---|---|
| roster | recursive FSA walk, spread over belief ticks | **0.1–0.3s**, one `read_file` |
| reads | 728 | **0 paid**, 731 skipped |
| convergence | 12–21 passes | **1–2 passes** |
| what dominates | waiting (~60% belief ticks) | working (~90% decode + mint) |

**THE BOMBS — what will mislead you if you do not know it:**
1. **Do not quote a wall clock from one run.** Same tab, same code: 3.3s and 9.5s; `work_ms` alone
    varied 2×. The stable result is the PASS COUNT. See `instrument-blindness` in memory — three of my
     own instruments measured an interval that could not contain the thing under test, and each read as
      "no improvement", which is indistinguishable from a regression.
2. **`work_ms` counts IO wait**, because a pass body `await`s Dexie. The first stand after a reload
    looks ~5× busier purely from a cold IndexedDB. It is not CPU.
3. **`runner_ask runners` needs 3–5 rounds** before you believe "nothing is live" — the relay spends an
    addr-less `corr` on the first ack. I blocked on a phantom "no runners" for an hour; round 4 found
     two. And a `role:hacker` tab (BigWordland) stands no relay channel at all, so the owner being in
      the room gives you no runner — that needs a separate `?B=` tab.
4. **The supermap's safety is the dige gate, not the mapper key.** A snapped Doc is adopted only if the
    index Waft still reports the same dige. Weaken that and a stale Map serves silently — the failure
     mode where a cache makes things WRONG rather than slow.

**THE NEXT MOVE, if you want one:** the residue is the 5MB decode and 43,945 mints, so the only lever
 left is *not minting them all at stand* — a Map built lazily for the doc a reader actually asks about.
  That is a design change, not a knob, and **nothing needs it yet**. Prefer finishing what is owed:
   the Stemdex measured cold on a real editor tab (§ below), which is the last open question about
    whether the two indexes should share a producer.

### ☀ WHY THIS DOC EXISTS — the second sentence is a correction of the first day's work

2026-09-09/10 the warm Atlas stand went 15.0s → 3.5s in three fixes, and **all three were the same
 mistake**: a bespoke little transport invented to make ONE fact travel faster.

| what was slow | what I built | what it actually was |
|---|---|---|
| 726 FSA reads per warm boot | `/__atlas/dige` | a hand-rolled Mag of doc hashes |
| 38 `HEAD`s every 2s, every tab | `/__gen/dige` | a hand-rolled Mag of gen hashes |
| 709 IndexedDB `get`s per stand | `Atlas_cache_prefetch` | a hand-rolled page read |

Each one measured well (4×, 5×, 4.1×) and each one is a **variation of the system rather than the
 system**: its own JSON shape, its own ETag, its own memo, its own failure mode, none of it a particle,
  none of it visible in a snap, none of it replicable, none of it observable by Seem. They are the
   emergency fix and they are not the destination. *The tab should not be asking at all.*

**The bet says the index is the same legible living matter as everything else** — so it is a C tree, it
 travels by Repli, and Seem sees it change. Nothing new is needed. Every part already exists.

### IT IS A WAFT, NOT A MAG — and this deletes most of the plan

*The owner, 2026-09-10, mid-design: "I'm not sure we learnt anything playing with Mags as a new
 generation of the Waft type… but it had cursors."*

That is the whole correction, and it is worth more than the section it replaces. The first draft reached
 for `%Mag`/`%Cloud` **by analogy** — Heard has a shelf of things, we want a shelf of things — which is
  the "variation of the system" reflex one paragraph after warning about it. The Mag experiment's one
   durable contribution was **cursors**; the container underneath it was always the older, proven thing.

**And the older thing already IS this.** The Waft vocabulary is literally `Waft > What > Doc > Point`,
 with `Cursor` already a member (`WAFT_PROTOCOL`, `Text.svelte`). An index of `%Doc:<path>` rows is not
  *shaped like* a Waft; **it is a Waft.** So:

```
Waft:<index key>
  Cursor,…                       resumable position — the one thing the Mag round taught
  Doc:<path>,dige,mtime,size
    Map                          ← proven to encode + round-trip (MapEncode.spec.ts, 6/6)
      def,method,line=…
      call,method,via,line=…
```

**What that deletes from this plan:**
- **no Mag, no `%Cloud` paging** — the Waft is the shelf and `%Cursor` is the resumption
- **no `Repli`, no new frame kind, no identity road** — `enWaft` → a wormhole file → `deWaft` is a road
   the machine has driven since the beginning (`LiesStore` saves every Waft this way;
    `Lies.svelte:807` loads one). The watcher writes `toc.snap`; the tab opens a Waft. That is all.
- **no `Atlas_cache_put`/`Atlas_cache_adopt`** — Dexie's hand-rolled serialiser was standing in for
   exactly this file, and its three `.c` fields are the gap noted above.
- **and it retires the three bespoke transports** (`/__atlas/dige`, `/__gen/dige`,
   `Atlas_cache_prefetch`) rather than adding a fourth kind of asking.

**The prize is unchanged and now nearer:** the tab does **no walk, no read, no hash, no parse, no
 Dexie** — it opens a Waft it already knows how to open. One machine pays the 1.5 minutes of CM6 once.

⚠ **The one thing genuinely still owed is the CURSOR**, because that is what the Mag round was for: a
 726-doc Waft is not something you want to re-read whole on every change. `%Cursor` in the protocol is a
  vocabulary entry, not a working incremental read — so *how a reader resumes* is the real design work
   here, and it is the same question the Seem-merge answers one level up. Do not assume it is solved
    because the mainkey exists.

### IS THE MAP IN C** FORMATION, AND CAN WE MAKE A SERIALISABLE BUNCH OF IT?

*(the owner's own question, 2026-09-10 — and it is the question the whole plan turns on)*

**Yes to both — and it needed NO unfencing at all.  Measured, not reasoned:
 `scripts/MapEncode.spec.ts`, 6/6.**

The index is already real C: `%Doc:<path> > %Map > {def|call|elvisto|link|region|anchor|mint|proves}`,
 every row minted with `i()`. It encodes today, round-trips today, and nobody had ever tried:

```
Doc:Ghost/X/Sample.g,dige:abc
  Map,dontSnap	{"dontSnap":1}
    def,method:Sample_alpha,line=9
```

⚠ **I got `dontSnap` wrong TWICE writing this section, and the test caught both.**  First I claimed the
 encoder prunes the Map on `map.sc.dontSnap` — it does not; pruning is driven by a matched RULE's
  `means.dontSnap`, never by the node's own key. Then I claimed such a rule prunes at encode — it does
   not either: `Text.svelte` says outright *"The line still encodes here; story_process_node forwards the
    flag, snap_H folds."*  **`enWaft` marks; the Story snap walk folds.**  So the encoder was always
     unconditionally willing to emit the whole index, and the flag is advisory metadata for one
      consumer. Both errors came from inferring behaviour off a comment; both died on first run. *That
       is the entire argument for characterisation tests over confident ones.*

**So the only real gap is the three fields on `.c`** — `region_path` (an array), `abs_from`, `abs_to` —
 because `.c` is never encoded. `abs_*` are numbers and move to `sc` trivially. `region_path` must NOT
  go in `sc` (an object value there is fatal at encode); it is either child particles, or — better —
   **re-derived at read time from the `%region` rows' own line spans**, which is what a beadchain
    computes anyway, making it a VIEW rather than stored data.
  And the tell that this is the right road: `Atlas_cache_put`/`Atlas_cache_adopt` walk the Map copying
   exactly those three fields out and back for Dexie — **a hand-rolled serialiser sitting beside
    `enWaft`**, written around a fence that was never there.

**The tell that this is the right road:** `Atlas_cache_put` and `Atlas_cache_adopt` already walk the Map
 copying those three fields out and back — **a hand-rolled serialiser sitting beside `enWaft`**, written
  because the real one was fenced off. That is the same mistake as the three transports above, in the one
   place where fixing it pays the most.

### ⚠ MEASURED 2026-09-10: ATLAS COLD IS 68s, NOT 5 MINUTES — so this plan is aimed at PART of it

Everything below this block was written before the cold case had ever been measured, on the assumption
 that 726 CM6 parses *were* the owner's 5 minutes. Forced cold on a live runner
  (`ghost_load --stand=Atlas --fresh --nocache`, a new flag built for exactly this):

| | passes | wall | what it did |
|---|---|---|---|
| warm | 16 | **3.5s** | 726 adopts, zero parses |
| **cold** | **274** | **68.0s** | 728 real parses, zero adopts |

728 docs at ~2.7 per pass with `pass_ms` 70–182ms ⇒ **~36s of parsing and ~30s of waiting for belief
 ticks.** Two things follow, and the second is the important one:

1. **Even cold, the politeness slicing roughly doubles the wall clock.** Shipping a pre-built index
    removes BOTH halves — no parse, and no 274-tick convergence — so the prize is bigger than "skip the
     parse". But `ATLAS_SLICE_MS` still must not be raised (it exists because a 4s mutex hold froze the
      owner's editor tab); the fix is not to hold longer, it is to have nothing to converge.
2. **68s ≠ 5 minutes, so Atlas is not the whole complaint.** Something else is running in that tab
    alongside it. **Prime suspect: the Stemdex** — a SECOND full-corpus scan, over the same ~726 docs,
     kept fresh by its own polite dige-gated pass (`Lagoon_lies` treats it as a third census). Atlas and
      the Stemdex have never been measured together, and a plan that removes one of two corpus walks
       will disappoint anyone who was feeling both.
 **Do not build further on this doc until the second walk is measured.** The same discipline that caught
  `dontSnap` twice and the ADOPT-cap inversion applies here: the justification for the whole design is
   now known to be partial, and finishing the sentence is cheaper than building the wrong half.

#### …and the second walk is real: THREE THINGS INDEPENDENTLY HASH THE SAME CORPUS

Confirmed by reading, not inferred (`LiesFunk.svelte` §Stemdex): the Stemdex is a **full second corpus
 walk** — its own Dexie table (`stemdex`), its own per-doc dige, its own polite passes with a
  `READ_BUDGET`, its own convergence, over the same ~726 docs, through the same beliefs mutex. It was
   invisible in every measurement above for a simple reason: **it had never scanned on the runner**
    (`lagoon seek` reports *"stemdex standing but UNINDEXED here — nothing has scanned on this tab"*),
     because nothing on a runner opens a searchbar. The owner's editor tab runs both.

So the tally of things that separately answer *"what is the hash of this doc"*:

| | cache | what it keeps |
|---|---|---|
| Atlas | Dexie `atlas` | `dige` + the `%Map` |
| Stemdex | Dexie `stemdex` | `dige` + defs/props/stems |
| the served index (2026-09-09) | in-process memo | `dige` + mtime + size |

**Three caches, three diges, one corpus.** The others duplicated a QUESTION; this looked like it
 duplicated the WALK.

⚠ **CORRECTION, measured 2026-09-10 — "a second FULL corpus walk" was overstated.** A `stemdex` CLI op
 was built to nudge the pass and watch it converge; on the runner it reached **12 docs and stopped**,
  and 12 is not a stall, it is the whole roster. The reason is in the code (`LiesFunk.svelte` ~:1558):
   the Stemdex's roster is **"every Doc in every LOADED WAFT + the whole GhostList"** — it is not an FSA
    tree walk at all. Atlas walks the filesystem and finds 728; the Stemdex indexes what is *open* plus
     the ghost pile. So its size is a function of how many Wafts a tab has loaded, and on a runner with
      almost none it is a dozen docs and converges instantly.
 **What survives the correction:** two caches, two diges, two vocabularies over an OVERLAPPING corpus,
  and `Lagoon_seek` already asking both. **What does not:** any claim that the Stemdex is half the
   owner's 5 minutes. It might be a large roster on a busy editor tab — with `SCAN_BUDGET = 8` fresh
    scans per pass it would converge slowly — but that is now an open question with a way to answer it
     (`runner_ask stemdex`, repeatedly, on the tab that actually feels slow), not a finding.
 *Third time this session that an asserted cost turned out to be a guess. The instrument keeps winning.*

#### THE MERGE QUESTION, ANSWERED — don't merge the censuses; merge the one thing actually duplicated

An objective read of both indexes (2026-09-10) settled the "big unification" question, and corrected two
 more things this doc had asserted:

- **The rosters are 728 vs ~233, and the second one is a BROWSING HISTORY.** The GhostList lists
   `src/lib` and `Ghost` **non-recursively**, plus whatever directories someone has clicked open — so
    `scripts/`, `Ghost/S`, `Ghost/V`, `src/lib/p2p` are simply absent, and one entry is a `.png`. Atlas
     indexes a corpus; the Stemdex indexes a session. **They are not two views of one corpus.**
- **The Stemdex does not hash at all.** It reads the dige off `LiesStore`'s `%Good/known` row, which
   `LiesStore_land_good` computed for `writeCarefully`'s base-dige gate anyway. So "three things
    independently hash the corpus" was wrong: the three `dig()` sites are Atlas, LiesStore and the
     served index, and one of those exists whether or not any index does.
- **Electrode is not in this category and should never be in a merge conversation about it.** Its
   universe is the runtime ghost bag, not a corpus; its truth lives in `.c` (`ring`/`tally`/`open`) and
    its `%Graph` is a *rendering* that `Electrode_reduce` drops and rebuilds. `Lagoon_join` exists
     precisely because declared and measured are different kinds of fact — two indexes of one corpus
      could not be joined that way, there would be nothing to compare.
- **The mainkey law does not argue for merging.** `%Doc` already lives in three shelves with three
   shapes (`w:Atlas`, `Waft:GhostList`, Waft trees) and the per-shelf rule permits exactly that. What
    the law *does* settle: if a stem projection ever moves into `w:Atlas`, it must be a CHILD under the
     existing `%Doc` (`%Stem`/`%Prop` rows), never a second `%Doc`.

**The scale asymmetry is the case against merging, and it is large:** Atlas keeps 43,945 structural rows;
 the Stemdex over the same corpus would need ~397,000 postings, ~11,500 prop entries and **16.9 MB of
  clipped source text** — ~9× the rows plus a copy of the repo. Shipping that to every tab as one Waft
   is shipping the corpus. Their rhythms differ too: Atlas must be COMPLETE (it computes `gone` by
    comparison) and is FSA-only; the Stemdex is allowed to be partial forever and works without FSA.

**✅ THE ONE REAL DUPLICATION WAS `defs`, AND IT WAS ALSO A LIVE BUG — now fixed.** Measured over the
 ghost pile: 53 `.g` files, **2,822** real methods, and the Stemdex's def extractor found **714 "defs"
  of which ZERO were methods** (`Ghost/L/Atlas.g` yielded exactly one: `roots`, a local variable). Its
   middle regex requires a trailing `{`; a `.g` method line ends in `:`, so the only alternative that
    ever matched was `const|let X = (` — i.e. locals. `Lagoon_todo §983`'s claim that a missing Atlas
     *degrades* the answer was therefore false for `.g`: ghost-method search did not degrade, it
      disappeared, and freetext stems hid it.
 The instinct was to delete the extractor and let Atlas own defs — but Atlas refuses to stand without a
  granted FSA handle while this scan rides `LiesStore`, so deleting it removes ghost-method search from
   exactly the tabs Atlas cannot serve. **Teaching it the dialect instead turns 0 correct into >2,000
    with under 2% false** (`scripts/StemdexDefs.spec.ts`, 3/3, counted against the corpus rather than a
     fixture). That is ~90% of the merge's benefit at ~5% of its cost.

**VERDICT: keep two censuses, one producer eventually.** The evidence rules out "they are the same
 index". It does not rule out "they should have the same PRODUCER" — and the number that would decide
  that is still the one this doc has been asking for since §0: **the Stemdex measured cold on a real
   editor tab, with a real roster.** ⚠ Live measurement is currently blocked: no `role:runner` tab is up.

**Which is the real shape of the plan, and it is better than the one below.** The index Waft should
 carry the whole reading of a doc — `%Doc` with its `%Map` (Atlas's vocabulary) *and* its stem
  projection (the Stemdex's) — produced by ONE walk, off-tab, once. Then neither census scans in a tab
   at all, and `Lagoon_seek`'s "one answer over three censuses" becomes one answer over one arrival.
 ⚠ Before building that: **measure the Stemdex cold the way Atlas was just measured.** It is the only
  number still missing, and this document has now twice been aimed by a number rather than a guess.

### THE ORIGINAL (pre-measurement) FRAMING — kept because it is still true of the parse half

The owner, 2026-09-10: *"it just takes 5 minutes of 80% CPU to start up, I think it's a bit heavy."*
 **Everything measured on 2026-09-09/10 was the WARM case** (`dige_hit:726`, zero parses, 3.5s) — a tab
  with a full Dexie. The 5 minutes is the COLD build: 726 × `Atlas_map_one`, measured at 50–194ms each
   (`Wordland_todo §4b`), which is ~1.5 minutes of pure CM6 parsing before the 120ms politeness slicing
    stretches it across the wall clock. **No amount of memoising the ask touches this**; the parse is the
     cost, and it is paid on every machine that has never seen the corpus.
  So the ruling below is not optional — it *is* the plan: **if the watcher ships `%Map` children, no tab
   ever parses.** One machine pays 1.5 minutes once; every tab receives a census. That is the prize, and
    a Mag of hashes alone would leave the owner's actual complaint exactly where it is.

### ✅ BUILT 2026-09-10 — the status Waft, and Atlas reading it

**The producer is the vite plugin, and that is not a compromise.** Vite already watches the tree for
 HMR, so the "inotify daemon" the design wanted is a process you are already running. A separate
  docker-compose service was considered and refused: a third image sharing `/app/node_modules` is the
   documented 2026-08-07 outage (Alpine/musl vs Debian/glibc native binaries), so here the cheapest
    option and the safest option are the same one.

| piece | state | gate |
|---|---|---|
| plugin writes `wormhole/Docindex/toc.snap` — 728 docs, `dige+mtime+size`, 71KB, debounced, gitignored | **working** | `StatusWaft.spec.ts` 4/4 |
| `Atlas_index_read` — roster from the Waft, no walk | **built** | `IndexRoster.spec.ts` 7/7 |
| `Atlas_refresh` served by the same read | **built** | same, 3 refresh tests |
| the SuperMap — census as ONE snap in Dexie | **built, measured** | live: `passes 12–21 → 1–2` |

### ✅ THE SUPERMAP — and why it was right to refuse it twice first

Asked for early ("cached chunks of SuperMap… all made on the tab, informed by the daemon about
 what|when") and **declined twice**, both times correctly:
- first because the per-adopt round trips were already down to ~4 bulk calls, so chunking would have
   moved a cost that was no longer there;
- second because the remaining cost turned out not to be IO at all.

It became right only when the instrument could finally see the reason: with the reads gone
 (`731 skipped, 0 paid`) and the roster gone (`0.1s`), the tab was **still rebuilding 43,945 `%Map`
  particles one document at a time, every stand**. No cache *shape* fixes that. What fixes it is that
   the census is a C tree: `enWaft` encodes it, `decode_wh_lines` reads it back (`MapEncode.spec.ts`),
    so keep ONE snap and decode it once.

**Measured, live, warm:**

| | passes | roster | total | what dominates |
|---|---|---|---|---|
| walk + per-doc adopt | 16 | (walk, unmeasured) | — | reads + walk |
| index Waft only | 12–21 | 0.1–0.8s | 4.2–17.3s | **waiting** (~60% belief ticks) |
| **+ supermap** | **1–2** | 0.1–0.3s | **3.3s best** | **working** (~90%: decode + mint) |

`super_took:731`, one decode, 5,124KB snap. The wait is gone; the residue is the decode and the mints.

**Three of my own instruments were wrong on the way here, all the same shape — placed where they could
 not see the thing they were installed for:** `ms` measured convergence *after* the roster, blind to the
  walk the index removes; `pass_ms` sampled the last (always empty) pass, so real work read as zero; and
   `pass_t0` started *after* the decode, which would have hidden the supermap's own cost. Each one
    would have read as "no improvement" exactly like a real regression. `see:atlas` now carries
     `roster_ms · ms · total_ms · work_ms · super_took · super_stale` so the next person needs none of
      this archaeology.

**Two design bugs caught before they shipped:**
- the save gated on `supermap_dirty`, set only by a REAL parse — so on a warm tab (the whole point)
   nothing was ever dirty and the supermap could only be written by a tab that did not need it;
- no floor on census size, so a half-built stand could store a nearly-empty snap that the next stand
   would adopt as a complete answer. A cache that makes things quietly WRONG is worse than a slow one.

**⚠ Wall clock stays noisy** — 3.3s to 9.5s on identical code, and `work_ms` itself varied 3.0s vs 6.4s
 for the same operation. Belief-tick latency and IDB warmth both move a lot run to run, so **no single
  run supports a speedup claim**; the pass count (12–21 → 1–2) is the stable, structural result.

**Next lever, if one is wanted:** not minting all 43,945 particles at stand — a Map built lazily on the
 doc a reader actually asks about. That is a design change, not a knob, and nothing needs it yet.

**What the gates actually pin**, beyond "it works":
- the tab's OWN decoder reads what node writes, and **numbers arrive as numbers** — `key:value` is a
   string and `key=value` is a number, and getting that backwards parses fine while every `mtime`
    comparison silently never matches again
- the server-side hash **equals the browser's `dig()`** — the whole road rests on one hash meaning one
   thing on both sides of it
- the fake nav records every call, so the assertion is `['read_file wormhole/Docindex/toc.snap']` and
   nothing else: **a regression that quietly reintroduces the walk fails in CI, not as a slow tab**
- every failure mode returns 0 and falls back to walking — no index, empty, junk, a nav that throws,
   no nav at all
- the refresh contract in full: `refresh_added`, `by` un-stamped on movers *and only movers*, and a
   `seen` set complete enough for `gone` (get that last one wrong and a refresh silently drops live
    docs from the census)

**Why the SuperMap is not built.** `Atlas_cache_prefetch` already cut the per-adopt round trips to ~4
 bulk calls, and the roster walk it shared the 3.5s with is now gone — so whether chunking buys anything
  is **unmeasured**, and no runner has been up to measure it. It is worth building for the aggregate-
   cache reason (one shelf holding Maps *and* stems, per the owner's own sketch), not for a speed claim.

⚠ **OWED: the before/after on a live runner.** Everything above is gated headlessly and nothing here
 claims a speedup. The last measured warm stand was `passes:16, ms:3504` WITH the walk; what it is
  without the walk is unknown, because no `role:runner` tab has been up since.

**→ `node scripts/atlas_bench.mjs [--nocache]` is that measurement, in one command.** It stands Atlas
 fresh, polls until the census row carries `ms` (the field `Atlas_report` stamps only once a pass finds
  nothing left to do), and prints the whole shape of the stand: whether the roster came from the index
   or WALKED, reads skipped vs paid, the three adopt-refusal reasons apart, passes/capped, and the wall
    clock with ms-per-pass split into work vs waiting. It refuses when no runner is up rather than
     inventing a number.
 It exists because *three separate "obvious" diagnoses were wrong this session the moment an instrument
  was pointed at them* — the adopt cap that was not the bound, the "5 minutes of parsing" that was 68
   seconds, the "second full corpus walk" that was a 233-doc browsing history. **The measurement has to
    be cheaper than the guess, or the guess wins.**

**The numbers to fill in, and what each decides:**

| run | decides |
|---|---|
| `atlas_bench` warm, index present | did removing the roster walk help, and by how much (`from_index` should be 728, `passes` should fall) |
| `atlas_bench --nocache` | the cold path — the one the owner actually feels. Baseline: `passes:274, ms:67997` |
| `runner_ask stemdex`, repeatedly, on the EDITOR tab | the last open question: whether Atlas and the Stemdex should share a producer |

### THE BREADCRUMB — the doc's slot exists before the doc does

*The owner, 2026-09-10: "we need a breadcrumb I guess, where the current doc we want to see is going to
 get itself in."*  And, the same minute: *"docks spend an awful long time in the spinner state sometimes."*

**Those are one thing.** A spinner says *something is happening somewhere*; a breadcrumb says *the thing
 you asked for is going to arrive HERE*. The spinner is what you get when the slot does not exist yet,
  so the only honest thing the UI can draw is an apology. Give the doc a slot the moment it is asked
   for, and the wait becomes legible instead of blank — the same move as the Clerkdesk keeping `held` on
    screen while it re-asks, one level down.

**The shape is already the census's own, and needs nothing new.** Atlas is deliberately two-phase: the
 roster mints a BARE `%Doc:<path>` row with no `%Map` — cheap, no read, no parse — and the Map lands on
  a later pass. *That bare row is the breadcrumb.* So:

- asking to see a doc `oai`s its `%Doc` row in the index Waft **immediately**, whether or not anything
   has mapped it, and lands the `%Cursor` on it — the doc "gets itself in" at the moment of asking
- the row is visible at once: path, and whatever is known (`dige`/`mtime` from the watcher, nothing at
   all if it is brand new). `Map` absent is a legible state — *arriving* — not an error and not a spinner
- the Clerkdesk's errand and this are the same particle seen twice: the Aside records *why* you went,
   the index row is *where it lands*. Neither needs the other's data.

⚠ **Do not implement this as a new "pending" mainkey or a `loading:1` flag.** The absence of `%Map`
 already says it, and a flag would be a second way to express one fact — the exact shape of every
  mistake in this document. If a reader cannot tell "not mapped yet" from "mapped and empty", that is a
   reason to make the empty case explicit (`Map` with no rows), not to add a marker beside it.

**Owed measurement before any of this is built:** *why* a dock sits spinning. It has never been
 measured, and this session has twice been wrong about a cost it had only read about. `Lies_ghost_pick`
  could not be instrumented on a runner (no docks — Clerkdesk_todo leg 1), so this needs the editor tab
   and the Electrode tap. **A breadcrumb makes a slow thing legible; it does not make it fast, and it
    must not be allowed to excuse never finding out.**

### THE MAP GENERATOR — one collector, but the DISPATCH has forked (2026-09-10)

*The owner: "what is our Map generator? is it getting fractured? we should have one thing we run changed
 bits of code against..."*

**The collector is NOT fractured.** There is exactly one pair, both in `src/lib/O/lang/compile.ts`
 (⚠ that file contains NUL bytes — `grep -a` or you will conclude it is empty):
 `Lang_collect_markdown_regions(state, job)` and `Lang_compile_collect(state, job, sthoParser)`. Both
  write into whatever container they are handed (`job.oai({Map:1})`), which is exactly why the same code
   serves the editor's compile dock and Atlas's census. That part is healthy and should stay.

**The dispatch around it has forked into two, and they already disagree:**

| | `LangCompiling.svelte` (editor) | `Atlas.g` (census) |
|---|---|---|
| markdown test | `is_md` computed at :179 | `/\.md$/` on the path, inline |
| no parser | **throws** | `doc.sc.error = 'no parser'`, returns |
| result | keeps `lines` to render | discards them |

Two copies of "which collector, and what if there is no parser" is one copy too many, and a daemon-side
 scanner would make it three. **So: `Lang_map_into(state, job, path)` in `compile.ts`, beside the
  collectors — the one thing you run changed bits of code against.** Collector choice only, no policy:
   it returns `{ lines?, no_parser? }` and each caller keeps its own error stance and its own use of
    `lines`. Then the editor, the census and the watcher are three callers of one generator.

⚠ **And a fourth quasi-producer to retire, not to join:** `Atlas_cache_adopt` rebuilds a `%Map` from
 Dexie rows without the collector, so the Map's shape is asserted in two places (what the collector
  emits, and what the adopt reconstructs). With the encode road proven above, that whole path becomes
   "decode a snap" — one shape, one producer, and `Atlas_cache_put`'s hand-rolled field copying goes
    with it.

### THE SEEM THAT MERGES — incremental mapping, not rebuilding (the destination)

*The owner: "it should be a Seem that merges the Map around from unchanged bits... and reruns bits of
 compile thinking depending on what changed, ie all the IOexpr are involved with each other"*

This is the answer to the 5-minute cold start AND to per-keystroke editor cost, and it is a different
 idea from everything above: the Map stops being REBUILT and starts being MAINTAINED.

- **`%Seem:origin` / `%Seem:working`** is already the machine's name for exactly this pair — a working
   clone walked beside an origin. It exists today in `LangSion._se_plan`, and it is honestly labelled
    *"FRONTIER — highly experimental… the %Seem lives in Selection beyond the cordon"*. So the shape is
     the machine's own, and the implementation is not there yet. **Do not write this up as reuse of a
      finished part.**
- **What merging buys:** a doc's `%Map` is mostly stable across an edit. The regions above the change
   are untouched; the defs below shift by a line delta and nothing else. Re-running the collector over
    the whole file to learn that is the waste. A Seem that holds origin, takes the CM6 change set, and
     re-runs only the spans it invalidates turns "parse 726 docs" into "re-parse the paragraph you typed
      in" — which is the only version of this that is fast on a cold machine as well as a warm one.
- **"All the IOexpr are involved with each other"** is the hard part and must not be hand-waved. An
   `IOing` is a multi-leg expression the compiler resolves against other declarations, so a change is
    not confined to its own line span: editing one leg can invalidate a plan somewhere else.
     **Therefore the invalidation set is a graph question, not a line-range question** — and the graph
      is already kept: Atlas holds `call`/`elvisto` edges, Electrode holds measured ones, and
       `Lagoon_join` already reads declared-vs-measured across both. A merge that re-runs "the changed
        span plus everything the span's defs are named by" has all its inputs in the censuses already.

**Order, and it is deliberately last:** merging is worth nothing until there is ONE generator to merge
 against (above) and a serialisable Map to hold as origin (proven). Build those two, ship the watcher,
  and only then make the watcher incremental — at which point the tab inherits it for free, because the
   tab is no longer parsing at all.

### THE PARTS, and what each is already for

- **The watcher** — `scripts/daemon/main.ts`. A real long-running node process, disk access, its own
   identity, and `RELAY=1` already joins the `/relay` websocket. **Not a new container** (that was
    considered and refused 2026-09-09 — the index is a fact about THIS host's files) and not the vite
     plugin, which can only answer, never push.
- **The shelf** — `%Mag`/`%Cloud` paging, `Ghost/M/Heard.g` is the worked example.
- **The transport** — `Ghost/N/Repli.g`, unchanged: `Repli_offer` / park / pages is paginated streaming
   C** replication and this is exactly its job. No new frame kind.
- **The change view** — **Seem**. `Atlas_report` already cites "the Seem/`%News` idiom" for a row that
   is replaced rather than piled; Seem is how a watcher says *what moved* instead of shipping the world.
- **The identity/permission road** — the daemon is already a peer with a prepub; a tab already decides
   who may serve it. Nothing new to authorise.

### → THE NEXT MOVE, in order

1. **Scan into the Mag, in the daemon, with no transport at all.** Build `%Mag:docs` as a real C tree in
    the daemon's own shelf and expose it on the existing `/c` introspect endpoint. Gate: the Mag's
     `%Doc` rows agree with `runner_ask lagoon lint`'s doc count and with `/__atlas/dige`'s hashes.
     *No push yet — prove the shelf before proving the wire.*
2. **Watch, don't rescan.** `fs.watch`/chokidar on the roots; a change restamps one `%Doc` and bumps the
    Mag. The daemon already re-stats cheaply (`dige.ts`'s memo is the prior art to fold in, then delete).
3. **Repli it to a runner.** `Repli_offer` the Mag; the tab lands `%Doc` rows straight into `w:Atlas`.
    Gate: a Book that stands Atlas with `w.c.roots` empty — nothing to walk — and still gets 726 docs.
4. **Seem the delta.** The tab shows what changed since it last looked, off the Mag, not off a poll.
5. **Retire the two endpoints.** `/__atlas/dige` and `/__gen/dige` become the BOOTSTRAP only — a tab
    with no watcher peer — and are deleted the day a runner can boot from the Mag. Leave the fallback in
     until then; a tab on a remote node with no daemon must still work.

**DO NOT:** invent a frame kind, a second identity road, or a new shelf mainkey. If a part seems to be
 missing, it is more likely to be one of `C` / `Seem` / `Mag` / `Repli` / `req` wearing a name this doc
  has not used yet — that is the whole lesson above, and it cost three bespoke transports to learn.

**Rulings owed:** ~~does the watcher hold `%Map` children~~ — **answered by the 5-minute cold case: it
 must.** A hash-only Mag leaves the actual complaint untouched. The daemon runs the CM6 collector
  headless, which `Atlas.g` already states is correct ("a plain headless build is correct with no
   forcing") and `LocalGen` proves nightly by compiling `.g` through the real translator in node.
 Still owed: does the Mag live under the daemon's identity or a well-known `pub` the flock shares? · is
  `region_path` child particles or a re-derived field (it is recomputable from the `%region` rows'
   line spans, which would make it a VIEW rather than stored data — cheaper and more honest)?

### THE ORDER THIS ACTUALLY WANTS TO BE BUILT IN

Step 1 below is no longer "scan into the Mag". **Make the Map encode first** — it is the smallest change,
 it is verifiable entirely offline with no daemon and no wire, and every later step is worthless without
  it. If `enWaft` can emit a `%Doc` with its `%Map` and `Text`'s decoder can read it back into an
   identical tree, the rest is plumbing that already exists. If it cannot, nothing else is worth starting.
 Gate: a spec that builds a `%Doc`+`%Map` by hand, encodes, decodes, and asserts the tree round-trips
  including `region_path`/`abs_*` — the same hand-made-particle discipline as `SectResolve.spec.ts`.
