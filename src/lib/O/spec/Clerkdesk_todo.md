# Clerkdesk_todo.md — the literal desktop of a clerk who expanding-foams information

**The owner, 2026-09-09 evening, tired, three sentences that are one thing:**
> *"I'm unimpressed with its ability to change Doc quickly… same as Lies+Lang was. and it forgets what
>  it was going in there to look at if that takes too long. so where do we keep what to look at and
>   what we're doing etc?"*
> *"we need to design the literal desktop of some clerk who expanding-foams information and etc etc."*

## 0. What to get on with next

### ☀ THE FINDING THAT CHANGES THE JOB — read this before designing anything

**"Where do we keep what to look at and what we're doing" is already answered, in the tree, three
 times over — and nothing has ever read it back.** The errand is not missing. Its SURFACE is.

Every search delivery already writes a moment into today's Aside (`Lies.svelte`, `e_Lies_ghost_pick`):

```
Waft:Aside/2026-09-09,aside
  What,FromWhat:Waft:Ghost/Net/Easy/What:the peer,about:text:repli_casters
    Doc:src/lib/O/spec/Daemon_todo.md
      Point,method:text:repli_casters
```

Read the row: `about` is **what you were going in there to look at** — stamped at mint, 2026-09-08,
 from the owner's own words *"just having a context the Point is going for"*. `FromWhat` is **where you
  came from**, a loose `Waft:<key>/<mainkey>:<value>` locator, deliberately a string so it survives the
   Aside being thrown away. `Doc` is what you opened. `Point` is where you landed. Repeat deliveries
    into one ghost accumulate on ONE moment — *the day's research trail*, the code's own words.

And the reader exists too: `Lies_resolve_locator` (`Lies.svelte` ~:1194) takes exactly that locator
 form, and its own comment says — of the FromWhat back-pop — *"write-only today, **this is the reader
  it was waiting for**"*. `Interest.md §309` lists the click-through as owed.

So: **shelf built · label built · resolver built · surface never drawn.** The intent evaporates not
 because it was never captured but because nothing shows it to you. This is the same shape as the
  beadchain (Atlas had held the beads for weeks and nobody had drawn them) and the same shape as
   `Fallen_out_of_mind §1` — *already ruled, then re-derived*. Do not design a new errand store.

⚠ **The corollary that will bite:** because the desk reads what is ALREADY on disk, a day's Aside is
 real data with real history in it — including `Doc:` rows naming files that have since been renamed
  (`Ghost/Story/Voronation.g` sits in today's, from before the `Testing.g` rename). A moment is a
   record of a visit, so a stale path is HISTORY and must render as such, never as a broken link and
    never silently repaired. Decide what a click on one does before writing the click.

### ⛵ WHERE THIS IS GOING — the destination, not the diff

A **clerk's desk**: the surface where what-you-are-doing, what-you-are-about-to-look-at, and
 where-you-came-back-from are all VISIBLE AT ONCE, as objects, while the slow thing loads.

The three complaints are one mechanism. Changing Doc is slow; the wait is where intent is lost;
 intent is lost because nothing holds it in front of you during the wait. **The desk is what is on
  screen during the wait.** That reframes the latency work: making the switch fast is worth doing and
   is leg 1, but a desk that holds the errand makes the remaining slowness survivable rather than
    corrosive. Fix both, in that order, and never let the second wait on the first.

**"Expanding-foams information."** Take the image literally: a foam is cells that pack against each
 other and press for room — and a soap foam *is* a Voronoi tessellation, which is what the Voro/Vyto
  glass already draws. So the desk's eventual rendering is not a new engine; it is the existing glass
   given a new subject, which is `Lagoon_todo §1.8`'s one-answer-many-faces line one level up.
  **RULING OWED before anyone builds that** — the glass lives in the VISUAL branch
   (`Glassbeast_todo`/`Meaningfold_todo`, its own front door, possibly another agent's hands). Until
    the owner says the desk may use it, the desk is built plainly — cells in a strip, sized by weight —
     and the foam is marked here as the step after. Do not reach into Vyto to do it.

### → THE NEXT MOVE

### ✅ THE NIGHT'S RESULT — 2026-09-09, legs 1–3 built and measured

**Leg 1 gave a negative and a bigger positive, and the negative is worth keeping.**
 The `pick` op now fires `Lies_ghost_pick` from the CLI (`runner_ask pick <path> [<point>]`, runner-only,
  no new authority — it presses the button a search hit presses), so the path is instrumentable for
   good. But **the pick could not be measured on a runner**: a runner has no editor docks, so the
    elvisto lands with nothing to open and the tally shows no flow for it at all. Measuring the real
     Doc change needs an EDITOR tab with docks — that is owed and it is the owner's tab.
 **What the instrument found instead was bigger.** `Creduler_reswap` fired **38 serial `HEAD` requests
  every 2 seconds, on every editor and runner tab, forever** — its own comment called this "correct +
   cheap"; the Electrode tap measured **280–315ms per sweep**, the largest recurring cost on a live
    runner by a wide margin. That is a constant background tax on everything the tab does, which is a
     real and sufficient explanation for *"same as Lies+Lang was"*.
 **Fixed by the shape, not the logic:** `/__gen/dige` (`src/lib/server/dige.ts`, the same dev-server
  plugin the Atlas index uses) hashes the gen tree and serves all 54 in one conditional GET — 3KB, 1ms,
   and a 304 with no body when nothing moved. `Creduler_gen_diges` asks once per sweep; every ghost then
    reads its answer out of the map. Absent endpoint ⇒ each ghost falls back to its own HEAD exactly as
     before. **Measured after: 315ms → 61ms max per sweep, ~5×**, and 179 of the remaining 183ms is the
      single fetch, i.e. the sweep is now one round trip.
 ⚠ **The hazard that was caught before shipping:** a vite ETag and a content dige are different
  alphabets for one question, so a tab that flipped between the two sources would find all 38 baselines
   "changed" and hot-swap the entire spine mid-session for nothing. Two baseline maps
    (`reswap_diges` / `reswap_etags`), never compared across; a source flip costs one re-baseline and no
     swap. A dige is also STRONGER than the ETag it replaces — vite's moves with mtime, so a
      touched-but-identical `.go` used to force a re-import.

**Leg 2 — `Lagoon_errands`** reads the Aside back: moments newest-day-first, and inside a day
 most-returned-to first, each with `about`, its Docs, its Points, and `FromWhat` split into
  `from_waft`/`from_tail` (greedy on the key half — a Waft key contains slashes). Refuses by name if
   `w:Lies` is absent; keeps nothing. `runner_ask lagoon errands`. Gate: three tests in
    `scripts/SectResolve.spec.ts` (15/15) pinning both judgements — weight is *returns*, and a
     since-renamed path is **history**: marked `gone`, still listed, never repaired, and never accused
      when no census is standing ("I cannot see" must not render as "it is not there").

**Leg 3 — `src/lib/L/Clerkdesk.svelte`**, mounted by `Lagoon_plan` as `UI:Clerkdesk` beside `UI:Lagoon`.
 Two faces because they answer two questions — Lagui asks the corpus *where is X*, the desk asks the day
  *what was I doing*. Cells sized by return-count; click opens the errand's docs and the way back;
   reopening fires the same `Lies_ghost_pick` delivery a search hit does, so there is no second road in.
  **The one behaviour that is the whole point:** `held` keeps the last good trail on screen and a re-ask
   only DIMS it. A desk that blanks while something loads is precisely the failure being fixed.

**The hot-swap was verified, and verifying it took three tries — the two failures are the lesson.**
 `Creduler_reswap`'s real job is to notice a recompiled ghost and swap it without a reload; making it
  5× cheaper is worthless if it stopped doing that. First attempt recompiled `Electrode.g`, which is an
   L ghost and **not in `CREDULER_GHOSTS`**, so the sweep would never have looked at it. Second attempt
    used a manifest ghost but the tab had reloaded in between, and a reload empties the baseline map, so
     the changed `.go` was simply re-baselined as current — correct behaviour, and unfalsifiable as a
      test. The change has to land while the tab is UP and BASELINED. Third attempt, done properly:
```
👻 reswap gen/Story/MusuTesting.go @ 75a7431da3d93c9a
👻 Creduler reswap: 1 ghost(s) hot-swapped (no reload)
```
 That `@` value is a **dige, not a vite ETag** — proof the served map drove the swap — and it is **one**
  ghost, not 38, so the baseline separation holds. A green Book on the swapped ghost follows it.
 ⚠ A fourth non-result worth keeping: an earlier check found the sweep swapping nothing because another
  client held the runner with a Book in flight, and the safe-seam guard was correctly refusing. *A guard
   doing its job and a feature being broken look identical from outside.* Check the engagement first.

**A TAB STATE WORTH RECOGNISING — `accepted:true, uid:null`, forever.** After a long night on one runner
 (many reloads, a live hot-swap, and another client's run in the middle), `run Siphonation` came back
  `{accepted:true, uid:null}` and then sat at `run:null` for 80 seconds — the Book was taken and never
   started. `--watch` makes this look like a fast clean finish, because the watcher sees `run:null` and
    prints "run settled": **a Book that never starts and a Book that finishes instantly are the same
     shape at the CLI.** Always read `steps` (`done:0`, `steps:[]`) rather than the settle message.
  A reload cleared it and the same Book went 6/6 caveat 0 on the fresh tab, so this is TAB STATE and not
   the reswap change — the documented "reload before bisecting" rule earned its keep again. What I do
    NOT have is the cause; the honest candidates are the hot-swap re-mounting a Pantheate-include under
     a live Story machine, or simple accumulated wedge. **Do not record this as a diagnosed bug**, and
      if it recurs, catch it with the swap disabled first (`Creduler_gen_diges` returning null is the
       exact pre-change behaviour, so it is a one-line bisect).

**Books green tonight, all `caveat:0`:** `Siphonation` 6/6 · `MusuBerth` 7/7 · `VoroRadio` 9/9 ·
 `LagoonStaple` 8/8 · `SwarmBody` 23/23 — across five different renamed recipe files, so the rename and
  the reswap change are both covered by running code, not just by compiling.
 `MusuTesting.go`'s own recompile is proven valid by parse + a diff against `HEAD:Ghost/Story/Musuation.g`
  showing **0 non-comment changed lines**; `MusuBounce` was attempted as a live Book for it and is simply
   long/streaming-dependent, so it is not evidence either way.

**⚠ I LEFT THE RUNNER `da06` WEDGED — it needs a manual reload.** `MusuBounce` hung, and after it the tab
 stopped answering the relay entirely, so `runner_ask reload` cannot reach it (self-serve reload needs the
  tab to answer). `e747` is live but belongs to another agent and was deliberately not touched. The app
   itself is healthy (`/BigWordland` 200). Open `:9091?B=<Book>` again and the flock is whole.

### ✅ 2026-09-10 — "WHAT DO WE MEMOISE?" ANSWERED WITH NUMBERS, AND THE ANSWER WAS NOT WHAT I THOUGHT

The owner: *"if I wait these 30s for a ridiculous amount of reads of 700 docs… then it parses them all
 and stuff? what do we memoise?"* Both halves of that guess were already handled, and neither was the cost.

| | memoised? | evidence |
|---|---|---|
| the 726 reads | **yes** | one served dige index — `dige_hit:709/726` |
| the parses | **yes** | Dexie `%Map` adoption — only `cache_moved:17` re-parsed |
| **the census assembly** | **no** | `passes:56 · ms:15026` |

**The real cost was 709 separate IndexedDB `get`s** — one per adopt, ~10ms each, which is why barely a
 dozen fitted in a 120ms slice and why a warm stand needed 56 belief-tick round-trips. `Atlas_cache_prefetch`
  pulls a bounded window (`ATLAS_PREFETCH = 200`) in ONE `bulkGet` per pass and adopts out of memory.
   **`ms:15026 → 3668`, 4.1×.** Bulk-first with a per-key fallback, and `cache_solo` counts any adopt
    that had to go it alone, so a silent regression to the old shape would show on the census row.

**Third instance of one disease in two days** — 726 file reads → one dige index · 38 HEADs every 2s →
 one `/__gen/dige` · 709 IndexedDB gets → one bulk read. **Many small asks where one answers**, and each
  site carried a comment asserting it was cheap. None had ever been measured. *A claim about cost that
   no instrument has checked is a guess wearing a comment's clothes.*

**Then the cap inverted, which is the part worth remembering.** With the round trip gone, `capped` went
 3-of-56 → 13-of-32: `ATLAS_ADOPT = 40` had become the binding constraint, sized for work that no longer
  cost what it used to. Raised to 200 → `passes:32→16, capped:13→1` — the constraint provably gone — but
   `ms:3668→3504`, ~4%, on runs that are not clean twins. **Written up as tidying an obsolete constant,
    not as a speedup.** The pass count had already stopped being the dominant term.

**Where the remaining ~3.5s lives:** the roster walk plus ~16 × 120ms of real adopting — work, not
 waiting. The next honest gain is memoising the census ASSEMBLY, which is a design change, not a knob.
  The politeness bound (`ATLAS_SLICE_MS = 120`) was never touched: it exists because a 4s mutex hold
   froze the owner's editor tab, and raising it would trade today's complaint for that one.

**New instrument, kept:** `see:atlas` now carries `passes · capped · pass_ms · ms · cache_solo` beside
 `dige_hit · cache_none · cache_moved`, so the shape of a stand is readable from the census itself.

**Also built (the owner, same evening): the HEADING band on the desk** — *"we need a heading where I can
 track what we're really up to… which docs are we actively working on and just in the vicinity of?"*
 One typed heading, persisted as `heading` on the day's Aside Waft (one key on a particle that already
  exists — the day's Aside IS the day's work, so it needs no new shelf); written by `Lies_aside_heading`
   because Lagoon reads and must never keep. Two rings under it, both from the trail and **today only**:
    `working on` = docs you came BACK to, with the return count; `in the vicinity` = docs you passed
     through once. Deliberately not derived from Atlas's call graph — one hop from the working set is a
      claim about the CODE, and these rings are a claim about the WORK. The input holds a `draft` so the
       1.5s poll cannot yank the caret mid-type, and a blank heading DELETES the key rather than storing
        `''`, which would be furniture.

**Still owed:** leg 4 (the desk visible during a Doc load — needs the editor-tab measurement first, so
 it is not built blind) · the LagoonStaple beat for errands · the foam ruling · the `né X` header note
  now on `VoroTesting.g` and `MusuTesting.g`, wanted on the other eleven.

**Overnight legs, in order (2026-09-09 night):**

1. **MEASURE the Doc change.** `Lies_ghost_pick` is the path; Electrode now coats every ghost method
    and `lagoon figurines` reads the tally. Two false regressions were chased today by NOT measuring
     first (`no-baseline-no-attribution`), so: numbers before any change. Needs a CLI way to fire a
      pick — that op is part of the leg, and it makes the path measurable for good.
2. **The errand read-back** — `Lagoon_errands`: today's (and prior days') moments as an answer —
    `about`, `doc`, points, `FromWhat`, weight. A reading over a shelf it does not own, refusing by
     name, keeping nothing. Gate with hand-made particles in `scripts/SectResolve.spec.ts`.
3. **The desk face** — the docket (what I'm doing), the trail back (`FromWhat` resolved), the visit
    list. Cells sized by weight. Plain, not foam. It is the thing on screen during the wait.
4. **Hold intent across the wait** — the desk visible WHILE a Doc loads, which is the exact window
    where the errand is currently lost.

**DO NOT, overnight:** the Waft flattening (attended, gate is re-recording `LakeSurprise`) · bulk edits
 from the rot queue (per-item human judgment; `§3.7 → §3` resolves but aims vaguer than the author
  meant) · any further `Testing.g` renaming · anything under the visual branch's Vyto/Glassbeast files
   · the `What / Point,doc:,at:` corpus migration (53 Story fixtures — `Lagoon_todo §leg-3` has the
    cost) · committing anything.

**Rulings owed by the owner** (carried from `Lagoon_todo §0`, still open): `spec/history/` retired-vs-
 gone · what `Story_next_level` should say · `PeerTesting`/`RaTesting` (my names, not derived) · may
  the desk use the glass.
