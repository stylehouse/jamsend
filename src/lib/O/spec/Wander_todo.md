# Wander — fair shuffling over a collection too big to enumerate

## 0. What to get on with next

**All three layers landed 2026-08-08** (§3 the base ladder, §6 census persistence, §7 the
 estimator). §2 is kept as written because it is the diagnosis, not the state — read it for *why*,
  then §6/§7 for what was done. The live candidates now:

- **Run it in a real browser, before anything else.** This is the one gap both agents declared and
   neither could close: every number in §6 and §7 is node against synthetic shapes, and **no Book
    exercises `Crate_nav_meander` at all**. The whole of tonight's wander work is proved correct and
     unproved *live*. See §7.2 for the exact five-minute test.

- **Persist the base-ladder stats too.** `Stoker_base_stat` (§3) keeps its yield memory on
   `top_House().c.dig_base_stat`, which is `.c` and therefore dies on reload — the *same* flaw as
    §2's census, just three entries instead of seven thousand. Deliberately NOT given its own
     persistence mechanism: when the census persistence lands, reuse it rather than building a
      second one. Cheap, and it means the ladder boots knowing which base pays.
- **Verify §3 by eye on a live player.** Every `tour` mark now carries `wgt` (the weight vector the
   draw actually saw, in ladder order `music / '' / testsounds`) and `yield` (`rate/dug` per base)
    — read them off `M.c.supply_trace` on a BigSoundland tab. Nothing has yet watched them move on
     a real share: the numbers in §3 are from an offline simulation of the *yield model*, which is
      not the same thing as the real wander. Say so until someone has looked.
- **`dig_barren` has the same 4096 cap** as the census (`Stoker_barren`). Far from binding at 62
   tracks, so it is not urgent, but it is the identical "past the cap we stop learning" shape and
    should be fixed in the same pass as §2's cap rather than separately. A sweep on 2026-08-08
     confirmed these two are the **only** bounded learners in the whole ghost tree, so that is the
      complete list, not a sample.
- A companion sweep for over-time accumulation claims came back clean too: the Heist magazine's
   "random samples accreting over time" (`Musica_fold`) is honest — it folds into a `Berth`, which
    is disk-backed. §2's census was the only false one.

## 1. The arc — what this is all for

The owner, 2026-08-08:

> "I feel we are not shuffling over the gradually revealed (by probing directories and remembering
>  approx how much was down each way once fully elucidated (which is a big tree buildup thing), but
>   only the branches leading outward and what they have on them, unfairly much. we should be able
>    to remember where 10000 tracks are by remembering how many are in each of 7000 directories, or
>     break those into piles of 300 directories and shuffle them, sizing the unknown expanse...
>      trying to establish the size of various large directories of things we can't enumerate all at
>       once, over time... yeah it hangs around testsounds/ far too much, all the legs confuse it.
>        this might be important for evenly wandering small collections... kinda try to weight
>         everything."

**The destination: a draw that is uniform over TRACKS, on a tree we are never allowed to
 enumerate.** The no-enumeration law is not negotiable — a share may hold 200k files and the app
  must stay responsive — so the only honest route is a census that is *built by the wandering
   itself* and *sharpens over time*. Everything below is a layer of that one idea.

Three layers, and each had its own version of the same bug — **uniform over BRANCHES instead of
 proportional to TRACKS**:

| layer | what draws | where | state 2026-08-08 |
|---|---|---|---|
| the base ladder | which of 3 share bases a dig starts from | `Radio.g` `Stoker_dig` | **fixed, §3** |
| the meander | which subdirectory to descend into | `Crate.g` `Crate_nav_meander` | **fixed, §7** |
| the census | what any of it remembers between reloads | was `.c` only — **nothing** | **fixed, §6** |

The play-side draw (`Radio_dial_pool`, which record plays next) was checked on 2026-08-08 and is
 **already fair**: it collects candidates across every friend crate into one flat list and draws
  uniformly from that, so it is uniform over records, not over crates. A friend holding 500 warm
   tracks does not weigh the same as one holding 5. No change wanted; recorded here so the next
    person does not re-audit it.

## 2. The census, and why "honest over time" has never once happened

`Crate_nav_meander` builds a map keyed by directory path — `{audio, open, subs, z, n}`: the true
 audio count, the still-drawable count, the child paths, consecutive-empty-visit strikes, and the
  slot cursor. Its own comment states the design intent: *"Biased at first, honest over time, zero
   extra IO."*

**It lives on `top_House().c.meander_learn`, and `.c` is never encoded.** The census dies with the
 page. Every reload restarts the wander at maximum bias.

Compounding it, the map is capped at 4096 entries (`Object.keys(learn).length < 4096`). The owner
 is describing 7000 directories. So on the collection this was built for, the census can be neither
  completed within a session **nor** carried across one — the "honest over time" state is not merely
   slow to reach, it is **unreachable by construction**. That is the finding that matters most in
    this doc.

(Second-order, worth checking when the cap is touched: `Object.keys(learn).length` is evaluated on
 every hop, which is an O(n) scan of the map to answer a question a counter would answer free.)

## 3. The base ladder — fixed 2026-08-08

`Stoker_dig` walked three bases, `['music', '', 'testsounds']`, starting from `dig_i % 3` — a plain
 uniform rotation. So a `testsounds/` of **eight files** took a full third of every dig's first
  attempt, and a dig start is not cheap: a dry base costs a whole 24-hop meander. Sharper here than
   in the meander proper, because **the bases overlap** — `''` is the share root and already
    contains both the others, so testsounds was reachable on two starts in three.

The fix follows the two-quantity discipline the meander had already proved:

- `rate` — an EMA of records landed per attempt (decay 0.7), what a base is giving **now**. It
   decays, so a spent crate falls away.
- `dug` — the honest lifetime total, which only ever sets the **floor**, sqrt-priced, so a base
   that once held hundreds stays cheaply reachable for when whittling re-opens it.
- Birth at `rate: 2`, optimistic, so an unprobed base is always tried early — writing a base off
   before ever seeing it is the whole failure mode in a small collection.
- The start is drawn by a **φ sweep over the weighted CDF**, the same low-discrepancy step the
   meander's slot cursor uses: an iid re-roll over three buckets is a coupon collector, so the
    ladder would re-tread one base while another waited.
- **A dry meander counts.** A base whose every file is held or learned barren returns *no picks at
   all*, which is exactly what testsounds does once its eight are shelved. A version that learned
    only from bases which returned picks would leave the one base we most need to demote sitting at
     its birth weight for ever — the instrument failing to record the case it was built for, which
      is the recurring shape of every bug in this area.
- `Math.round` (not `ceil`) on the live term, deliberately: `ceil` floors every positive rate at 1,
   and an EMA decays toward zero asymptotically without arriving, so the sqrt regret floor could
    never take over.

**Measured** offline over four synthetic yield shapes, 600 digs each
 (`scratchpad/ladder_sim.mjs`) — note this simulates the *yield model*, not the real wander:

| shape | testsounds share of starts | its wasted attempts | its tracks landed |
|---|---|---|---|
| owner's (music 4000 / root 600 / testsounds 8) | 33% → **9%** | 200 → **52** | 8 → 8 |
| inverted (music 0 / root 5 / testsounds 900) | 33% → **81%** | — | 900 → 900 |
| small (music 20 / root 12 / testsounds 8) | 33% → 26% | — | 8 → 8 |
| nothing anywhere | 33% → 33% | — | — |

The inverted row is the one that matters: this **follows the music** rather than encoding a grudge
 against a folder name. The last row is the other one that matters: with no information the draw
  stays uniform, because no information must mean no bias.

**Gated on `humdinger`** (end-user pages only), the same predicate the meander's weighting, its hop
 budget and the dig skip-set already use — the starting base decides which tracks a dig stocks, so
  a driven world must keep the plain rotation or every stocking Book needs re-recording. Verified:
   MusuStock 5/5 with its recorded step diges unchanged (the only `toc.snap` movement was
    TimeSpool's rolling samples), MusuRadio 9/9 caveat 0.

Note on reading those results: MusuStock reports a caveat on **all five** steps and always has.
 `caveat` is `entropy_forgive` — a step whose snap differs only in acknowledged value-noise passes
  as ok-with-caveat. It is the designed tolerance, not a symptom. MusuRadio's `caveat: 0` on the
   same build is the control that proves it.

## 4. In flight — do not collide

- ~~`Ghost/M/Crate.g` — the estimator.~~ **LANDED 2026-08-08**, compile `5b3e478c4dc7eacc` — see §7.
- ~~Census persistence.~~ **LANDED 2026-08-08** — see §6.

## 6. Census persistence — landed 2026-08-08

`src/lib/O/census_codec.ts` (pure codec, node-measurable), `census_store.ts` (the one Dexie table),
 `Census.svelte` (the driver: 5s look, 30s change-gated write, re-read-then-merge so two tabs are
  additive), plus two lines in `Ghost.svelte`. **No `.g` was touched** — it reads and writes
   `top_House().c.meander_learn` from the outside, so no hook inside `Crate_nav_meander` is owed.

**Storage shape.** A preorder tree of directory names, not a flat map: almost all the bytes are path
 strings, and the live map spends every path *twice* (once as its own key, once inside its parent's
  `subs`). Measured on a synthesised 6721-entry census — `JSON.stringify` 1060 KiB (162 B/entry) →
   **preorder tree 276 KiB (42 B/entry)**, 3.85× smaller.

**Rejected, and the reasons are worth keeping.** `sc` particles: ~1 MB of fixture in every snap of
 any world with a share, diffed between every Story step, for state no assertion reads — and `subs`
  is an array, which is fatal in `.sc`. `H.stashed`: Housing's persistence `$effect` re-stringifies
   the *whole* blob on any nested change at `AMBIENT_MAIN_TICK_MS` = 200 ms, i.e. **1 MB / ~5 ms,
    five times a second on the main thread, for ever**. A new ghost: each manifest ghost adds a
     `GhostInclude` row to ~30 recorded `Credulate/toc.snap` fixtures, and with re-records blocked
      that is a real bill for no benefit.

**The stale-restore prune hazard was REAL, and measured.** A verbatim restore of that census pruned
 **356 directories on evidence nobody checked this session** — `dead()` is permanent for the life of
  the page, so that is a whole branch of the collection written off from stale data. Fixed by
   capping restored `z` at 1, so a restored barren directory must earn one live confirming visit
    before `dead()` can fire; total evidence is then strictly stronger than the live rule asks.
     Measured with the cap: 0 pruned until a live visit says so, and **0 of 6721 draw weights
      change** (`z` is read only by `dead`, never by `est`/`est_true`, so the cap is free).

**The 4096 cap is the binding constraint, confirmed independently.** `CENSUS_RESTORE_MAX` is pinned
 at 3000 only because a full restore would fill `Crate.g`'s learn map and freeze discovery. At 3000
  the branch-draw total variation distance is 0.049; with the whole census restored it is **0.000**.
   So raising that cap buys an exact reproduction of the draw. The store itself holds up to 24000
    and each save merges live onto stored, so what one session cannot carry is not lost — that
     accretion is the "over time" half of the owner's ask.

**⚠ Coordination rule, permanent.** The codec carries **exactly** `{audio, open, subs, z, n}`. Any
 sixth field added to a learn entry **must** be added to `census_codec.ts` in the same change, or it
  is silently dropped on every reload — invisible within a session, surfacing later as a slow
   unattributable regression. Restored entries also carry `_cr:1` / `_cn:<n at restore>`; because
    `n` moves only when `Crate.g` steps a node's cursor, `n !== _cn` is a hook-free proof of revisit.

**Verified:** MusuRaStock 1/1 and MusuBerth 7/7 green, `svelte-check` byte-identical to baseline,
 `/BigSoundland` still SSRs 200, exact codec round trip on all 6721 entries, identical `est`/
  `est_true` weights for all of them, five malformed blobs decode without throwing.

**NOT verified — the honest gap.** *Nothing has run in a real browser tab.* Every number is node
 against a synthetic census. No real `meander_learn` has been observed restored on a live
  `/BigSoundland`, no Dexie write seen to land, `Census_diag()` never called in situ. **The codec is
   proven; the wiring is not.** The test is one end-user page: wander a while, reload, check
    `Census_diag()` reports `restored > 0`. Also untested: two-tab concurrency (reasoned only), and
     the `visibilitychange` flush (best-effort; the 30 s timer is the actual guarantee). And note
      no Book exercises `Crate_nav_meander` at all — only `Ghost/Story/Sounditron.g` does, and it
       was mid-edit by another agent — so fixture safety rests on the humdinger gate, not on a
        wander Book.

**One-time cost to the human:** adding `<Census>` to `Ghost.svelte` introduces a new child import in
 the mount tree, so open player tabs take **one** reload when vite propagates it. Subsequent edits
  to `Census.svelte` HMR normally — which is exactly why the Dexie handle was split into
   `census_store.ts` (a `<script module>` block would have killed the component's HMR boundary).

### 6.1 The alternative nobody weighed: a Berth Waft — and the objection that actually holds

The census agent weighed `sc`-in-the-world, `H.stashed`, a new ghost, and Dexie. It **never considered
 the Berth** — verified: zero occurrences of `Berth`, `enWaft` or `deWaft` anywhere in `Census.svelte`,
  `census_codec.ts` or `census_store.ts`. That is a real omission, because the Berth *is* the project's
   answer to "a durable document homed under an identity": `<root>/.jamsend/berth/<prepub>/<name>/toc.snap`,
    the exact wormhole shape, encoders-only, and the human's own ruling on the last hand-rolled format
     (2026-07-30, on the newlyadded log): *"it's got to be snap|enWaft… you can't just make up formats."*
      By that rule `census_codec.ts` is a made-up format, and the burden is on it, not on the Berth.

**Three arguments for the Berth, and the size one evaporates on measurement.** Real snaps run 29–70 B a
 line, so the whole census via `enWaft` is ~350 KB against 276 KB bespoke — a rounding error, not an
  argument. The two that survive are stronger than size ever was. First, **`omit_sc` inverts the failure
   mode**: a protocol declares what to *omit* (`Text.svelte:369`, `SESSION_KEYS`), where the codec's
    five-key whitelist declares what to *keep* — and a whitelist fails **silently and in the wrong
     direction** when someone adds a sixth field, which is precisely the seam defect §7.1 records. The
      permanent coordination rule above exists only because the format cannot fail safe. Second,
       **legibility**: a Berth Waft is a C tree, so it is Cyto-visible, editor-mountable, Book-assertable,
        and it travels with the music instead of dying with the browser profile.

**The objection that holds is the human's, 2026-08-08: whole-file rewrites.** `Berth_save` is
 documented as *"Whole-file replace — these documents are small"* (`Heist.g:3071`) and they are no
  longer small. Measured: `/app/.jamsend/berth/Newlyadded/toc.snap` is **43,395 bytes over 177
   `%Probation` cards** (~245 B a line — long paths), and `Heist_newlyadded_note` does a full **read +
    parse + encode + 43 KB write per landed track**. Landing an album of 12 rewrites it 12 times; the
     cost per arrival grows with the collection for ever, because a probation card is never removed (a
      `drop` keeps its card, honestly). That is **quadratic in collection lifetime**, on the disk actor,
       competing with the downloads themselves. Putting a 350 KB census on a 30 s timer through the same
        door would be strictly worse. **So the Berth as it stands cannot host the census — but the
         reason has nothing to do with the census.**

**The fix is already the house shape, and it is sitting in the repo.** A Waft is *a dir with a
 `toc.snap`* — and a Story Waft is `toc.snap` **plus numbered part files** (`wormhole/Story/Sounditron/`
  holds `001.snap`…`008.snap` beside its toc; `Housing.svelte.ts:2304-2312` is the `read_snap`/`write_snap`
   pair that serves them). An append-structured Berth is therefore not a new format, not even a new
    mechanism — it is the Waft shape the wormhole already uses, applied one directory over:
  - `Berth_append(nav, waft, particles)` writes only the delta as the next `NNN.snap`.
  - `Berth_open` reads `toc.snap` then folds the parts in order; a later line for a key supersedes an
     earlier one, which covers mutation (a `feeling` flipping to `love`) as well as pure arrival.
  - compaction folds the parts back into `toc.snap` and unlinks them past some part count — the
     whole-file write still exists, it just stops being **per arrival**.
 Newlyadded, Heists, the Musica magazine (638 records) and the census are four users of one mechanism.
  Sequence matters: **fix the door before moving the census through it** — otherwise the census inherits
   the rewrite and the Berth's advantages get blamed for the Berth's cost.

**Not started, and not to be started unprompted** — this is a change to the persistence layer that
 Heist, the magazine and the newlyadded log all sit on. What is established is that the census's Dexie
  codec is **provisional**, and that the objection to migrating it is a fixable property of `Berth_save`
   rather than anything about the census.

## 5. The shape that keeps recurring

Worth stating plainly, because it has now appeared at three layers in one subject and half a dozen
 times across the Radio work this week: **the instrument does not record the case it was built
  for**, so the failure reads as normal operation.

The census that stops learning at a cap. The `open` value that could never reach 0 because the
 write sat below the bail-out. The dry base that taught the ladder nothing because only successful
  bases were counted. The electrodes that reported a previous dig's numbers for hours. Each one is
   silent, each one is indistinguishable from working correctly, and each was found by asking "what
    would this look like if it were broken?" rather than by anything throwing.

## 7. The estimator — landed 2026-08-08, compile `5b3e478c4dc7eacc`

**The single biggest win was a bug nobody had suspected: the learn map's root key was broken for the
 whole-share base, so the weighting was INERT at exactly the level that decides "all the legs
  confuse it".** `here` strips leading slashes; the child key did not. For `base === ''` — one of
   `Stoker_dig`'s three bases — the root's `here` is `''` and its children were written as
    `'/name'`, while those same children record themselves as `'name'`. Consequences, all silent:
     `est()` found no entry for *any* top-level branch and priced every one at the prior for ever;
      `dead()` took its `if (!e) return false` exit and could never prune a barren top-level leg; and
       the map grew a shadow set of `/name` entries that nothing ever read. Fixed with a `kid()`
        helper. **Same failure shape as the `[object Object]` key already documented above it** — a
         key that is in no map ever, failing in the safe direction, so nothing throws.

Also landed: the prior is a **measurement** now, not the constant 8 (`mean-subtree = ā·(d̄+1)`, an
 exact identity for the mean subtree size of a uniformly random directory, shrunk toward 8 with 8
  pseudo-observations so it starts vague and sharpens by ~60 directories); a weight scale `SC = 64`
   so `est()` works in fractional track units (**load-bearing** — without it a share averaging 0.4
    tracks/dir rounds to 1 and the whole learned signal is lost, so prior and scale are one change,
     not two); the cap 4096 → **131072** behind a counter; a per-hop memo on `est`/`est_true`; the
      depth cutoff 6 → 40 (a seatbelt, not a bound); and `Crate_pile_draw` — piles of 300 with
       *cached* per-pile sums and a two-level Kronecker sweep, one cursor per pile.

| shape | coverage | tours to 50% | est() calls | KL vs uniform (ideal) | top 1% of tracks' share |
|---|---|---|---|---|---|
| owner (5192 tk, 4-deep + legs) | 93.3% → **100%** | 2147 → **1303** | 1.48M → 2.20M | 1.480 → **0.330** (0.371) | 27.9% → **3.4%** |
| broad (200 tk in 7000 dirs) | 7% → **47%** | – | 16.4M → **0.66M** | 1.561 → **0.878** (0.084) | 4.8% → 4.9% |
| deep (208 tk, 9 levels) | 77.9% → **100%** | 94 → **54** | 448k → **165k** | 0.348 → **0.022** (0.028) | 6.8% → **1.7%** |
| tiny (30 tk) | 100% → 100% | 8 → 8 | 10.4k → **3.4k** | 0.023 → **0.006** (0.005) | 4.4% → 3.7% |
| flat (200k files) | unchanged | – | 0 → 0 | 6.502 → 6.502 | – |

Two rows deserve reading twice. **owner**: the stationary dry-tour rate went 21.9% → **0.1%** — the
 wander essentially stopped coming back empty. **deep**: KL 0.348 → 0.022 against an ideal-uniform
  floor of 0.028, i.e. the draw became *statistically indistinguishable from fair*, and the depth
   cutoff was worth all of that on its own (1.567 → 0.022 in isolation) while being **literally zero
    change on the owner's own 4-deep shape** — a live hazard for a deeper library, not a current one.

**The gate was proved, not asserted.** `equiv.mjs` runs 300 tours per shape per config with
 `humdinger` off and compares the full pick sequence *and* the final PRNG state: 9 configs × 5 shapes
  all byte-identical. MusuVend 11/11 caveat 0, MusuStock 5/5, and no recorded step dige moved in
   either fixture.

### 7.1 Integration with §6 — checked 2026-08-08, no bug, two gaps

The estimator added four per-entry fields (`seen`, `p`, `q`, `pk`) and one global (`meander_stat`).
 The codec carries only `{audio, open, subs, z, n}`, so **all five are dropped on reload.** Traced
  through rather than assumed:

- `p`/`q`/`pk` are the pile cache. A restored entry has no `p`, and `Crate_pile_draw` rebuilds on
   `!node.p || node.pk !== live.length`. **Benign** — a rebuilt cache, not lost correctness.
- `seen` marks a directory as already folded into `meander_stat`. **Persisting it would be actively
   harmful, not merely lossy** — every restored entry would arrive pre-marked, `meander_stat.dirs`
    would stay 0 for the life of the page, and PRIOR would be pinned at its vague cold value of 8
     for ever: the exact defect the learned prior was built to remove, resurrected by the
      persistence layer. **Absence is the signal.** An unmarked entry is folded and marked by the
       next meander call, so the statistic rebuilds itself from whatever was restored, whenever the
        async restore lands — order-independent by construction.
- **This supersedes an earlier reading in this doc** (that the two omissions "cancel by luck" and
   the fix was to persist `seen` plus a per-entry depth). That was wrong twice over: the fold is
    better than persisting the stat, and persisting `seen` is the one thing that must not happen.
     Recorded because the wrong version was written here first and someone will otherwise re-derive
      it.

**The fold is worth landing on its own** — measured, broad shape, 7000 dirs, 5 seeds, second session
 on a restored census: tracks held after 20 tours were **1.2 (±1.6) cold, 8.0 (±1.3) warm without
  the fold, 23.2 (±3.0) warm with it** — 2.9× over a warm map that does not fold. It also removes a
   real sampling bias: without it the statistic only ever samples directories the walk *revisited*,
    which are the music-rich ones, so PRIOR drifts high (deep shape 27.88 vs 16.44, a 1.7×
     overestimate). Capping the restored map's confidence at 64 or 256 directories was tried and is
      **worse** (6.4 and 8.4 tracks at 20 tours) — the remembered census deserves its full weight.

**And the fold exposed a consistency bug worth its own line:** the fold can only see keys, so it
 counted depth as the key's slash count, while the live per-visit fold counted `rel`. For
  `base === ''` those disagree by one — two halves of one average disagreeing about what a level
   is. Both now count off the key. That fix alone moved the broad shape from 35% → **47%** coverage.

`CENSUS_RESTORE_MAX` **3000 → `CENSUS_STORE_MAX` (24000)**, since the 4096 cap that pinned it was
 raised to 131072 hours later. Measured payoff: branch-draw TVD against the full census was 0.049 at
  budgets 1000–4000 and **0.000 once the whole census fits**. Headroom is now ~107k entries rather
   than ~1100; the ceiling that still binds is `CENSUS_MAX_BYTES`, not this.

### 7.2 Still owed

- **Nothing in §6 or §7 has run in a real browser tab.** Both agents worked from synthetic shapes
   plus Book regressions, and no Book exercises `Crate_nav_meander` at all (only
    `Ghost/Story/Sounditron.g` does, and it was mid-edit). Fixture safety rests on the `humdinger`
     gate — which *is* proved byte-identical — but live behaviour rests on nothing yet. The test is
      one end-user page: wander, reload, `Census_diag()` reports `restored > 0`; and watch the
       `tour` trace for `top:` naming albums rather than structure and `died` no longer thrashing
        near the root.
- **Three bases share one `meander_stat`.** `d0` is depth-below-base, so a track 4 deep under
   `music` and one at depth 0 under `testsounds` pool into the same `d̄`. Not obviously wrong,
    unmeasured.
- **`SC = 64` was chosen from three candidates on five shapes**, not finely swept. `SC = 8` had a
   marginally better KL on the broad shape (0.688 vs 0.716) at half the coverage (28% vs 35%);
    coverage won.
- **The pile path was never exercised against a flapping listing** — the partial-`expand()` case the
   `flap` electrode exists for. `node.pk !== live.length` rebuilds when the child count moves, which
    is the right shape, but that is reasoning, not measurement.
- **MusuStock is a weaker gate than it looks**: its live diges have not matched its recorded fixture
   for some time, so its green rests on the assertion verdict, not the snap.

### 7.3 The fold gate — a regression introduced and removed the same night

Raising `CENSUS_RESTORE_MAX` to `CENSUS_STORE_MAX` (§7.1) had a cost nobody had measured. The
 restored-census fold does an `Object.keys(learn)` pass **per meander call**; the estimator agent
  measured it free at ≤2200 entries and explicitly flagged it unmeasured above that. Measured at the
   new budget:

| entries | ms per fold pass |
|---|---|
| 2200 | 0.30 |
| 12000 | 2.44 |
| 24000 | **6.18** |

6.2 ms on the main thread per meander call, for the life of the page — and after the first pass it
 is scanning the whole map to find nothing. **The do-nothing case had become the expensive one**,
  which is the same shape as everything else in this doc: the cost lives in the path that looks
   idle.

Fixed with a dirty flag rather than by lowering the budget back: a **restore is the only thing that
 can create an unfolded entry** (the live walk marks `seen` at visit time, `Crate.g:568`), so
  `Census.svelte` sets `meander_fold_due` when a restore installs entries and the fold clears it.
   Order-independence is preserved by construction — the flag may land at any time and the next
    meander call absorbs it. Compile `d3cf1af0637f614b`. **MusuVend 11/11, caveat 0, and no
     recorded step dige moved.**

The general lesson, worth carrying: **a budget raised in one file changed the cost of a loop in
 another, and neither file's author could see it.** The census agent measured its own format, the
  estimator agent measured its own draw; the interaction between the two belonged to neither. When
   two workstreams share a data structure, the seam needs its own measurement, and nobody owns the
    seam by default.
