# Wordland_todo.md — the coming /L/: the room, the census, the electrodes, the bundles

`/L/` is three places that are one idea:

- **`src/routes/BigWordland` + `src/lib/L/`** — the ROOM.  *"a big empty space, yet Lies+Lang in
   disguise"* (the owner's framing, written atop `L/BigWordland.svelte`): the second toplevel beside
    BigSoundland, an editor room that boots the `Educarium` Book by default, shows ONE House fullscreen
     (the H\*\* toc across the top is a switcher), hides Lies until summoned, and carries the universal
      searchbar with a pin rail.
- **`Ghost/L/`** — the LAND's ghosts: `Atlas.g` (what the code SAYS — every doc's `%Map`, kept),
   `Electrode.g` (what the code DOES — both ends of every call; built 2026-09-08 night, then PARKED by
    the owner), `Lagoon.g` (**the reader layer — every ANSWER asked of a census; built the next
     afternoon, `Lagoon_todo.md`**), and their Books `Atlantation.g` / `Electrodation.g` / `Lagoonation.g`.
- **Atheory** (`Atheory_todo.md`) — what code IS LOADED where: the declared manifest, and the `TheA_<dige>`
   layered prototypes that the two pictures above are meant to inform.

The arc: **the one bet, turned on the code itself.**  `Homethink §1` — *turn every kind of state into the
 same legible living matter, held where a group can see it, prove it, and rewrite it while it runs.*  Here
  the state is the codebase: what it declares (Atlas), what it actually does (Electrode), what is loaded
   onto which House (Atheory) — each kept as particles a Book can swear and a room can show.  The room is
    where a person stands to look at all three; today it shows only the editor.

## 0. What to get on with next (the morning look-around, 2026-09-08)

**⛵ EVENING UPDATE — THE COURSE IS PLOTTED IN `Lagoon_todo.md §0`.  Start there, not here.**  Ten legs
 in dependency order, ten bombs first.  Leg 1 is `role:hacker` and everything visual waits on it.  This
  doc stays the land's overview; that one is the working plan.

**Landed overnight** (all uncommitted, in the working tree):

- `Ghost/L/Electrode.g` stands on the live runner (`ghost_load Ghost/L/Electrode.g --stand=Electrode`) and
   a `runner_ask electrode [top|arm|disarm|reset|reduce|hangs|film]` op reads it.  First real measurement:
    **3,595 ghost methods coated; one `AtlasStaple` run = 7,577 calls over 356 caller→callee flows; the
     hang list caught the very `runner_ask` being served** (`Lies_drain_inbound → Peeroleum_deliver →
      Peeroleum_deliver_do → Lies_runner_ask_recv`, all four open, all async).  Details §4/§4b.
- The picture already names a hot path nobody had measured: **`Creduler_ensure → Lies_ghost_get →
   Lang_ghostmeta_name`, 1,152 calls per run** — the ready-tick re-reads every spine ghost's version twice
    per tick, 16 ticks a run.  A one-line gate (only re-read when the enrolment set changed) takes it to
     36.  Not applied — it is `LiesLies.svelte`, the live spine; the owner should say.
- `Ghost/L/Electrodation.g` → **`ElectrodeStaple` GREEN: recorded 6/6 in `mode:new` (10 sworn), contract
   installed (10 `Assertion:` lines, unique slugs), then check-mode ×2 — `ok_pct:1, caveat:0`, declared 10 /
    sworn 10 / gaps 0 — and SABOTAGE-PROVEN without a reload** (broken hang-list → `failed` with exactly
     the two "closes" gaps named; revert → green; §4b).
- `AtlasStaple` green 6/6 **armed with `caveat:0`** — the coats are invisible to a fixture.
- The gen-write-reloads-every-tab TODO was **measured and its written cause was wrong**: a LocalGen
   write of a spine `.go` left the runner standing (no reload, no Vite event) and `Creduler_reswap`
    hot-swapped it.  Corrected in `Story_hygiene_todo §0`; what reloaded tabs on 09-06/07 is open.
- **The join (`electrode join`) built, and its first accusation fixed:** Atlas's `.svelte`/`.ts` call
   collector missed the cast form `(H as any).X(` (158 sites); `compile.ts` fixed, `ATLAS_MAPPER m12`,
    711 docs re-mapped, undeclared edges in the join 60 → 24 (§4c).  `ghost_load --swap` added so a
     recompiled L ghost takes without a tab reload.
- `SwarmSteal` confirmed green (7/7 sworn).  The wedge was a **duplicate `Assertion` slug** under one step —
   the same silent `begun/n:null` as a duplicate `step=` line (`Seen_split_todo`, `toc-surgery` memory).

**⏸ RULED 2026-09-08 after the owner read the above: the tap is PARKED and stays OFF.**  *"we should
 keep teetering around with other bits before innovating further… since it's all leading to
  integration… we can leave it off for the moment? and play with it via the upcoming Atlas, perhaps?"*
   So item 1 (pictures into the room) and the Atlas half of item 2 are live; items 4 and 5 are HELD
    until Atheory has a shape.  The reasoning, and the two things about the tap the owner expected to be
     heavier than they are (nothing recompiles; it is already per-process), live in `Electrode_todo §0`.
      The deep line-level version genuinely does wait on Atheory — see `Electrode_todo §1`, which is now
       the doc that explains why, and `Atheory_todo`'s naming: an electroded build is a `Variant`.

**Next moves, ranked** — each is a morning's decision, not a night's build:

1. **THE ONE THING — the code explorer, over Atlas, focused by `%Interest`.**  Ruled 2026-09-08 (§5.0):
    Atlas is the protein-space the execution map will later live in, because it is the only structure that
     holds docs, defs, call edges AND the 1,782 prose→code links as one substance.  Explorer first, map
      second, or the coordinates get invented twice.  The first cut builds no new surface (the Lens
       prior-art gate): feed the existing StemHive from Atlas rows, give the pin rail a `→ callers` glyph,
        and let focus be an Interest rather than a new idea.  Read `Interest.md` first.
2. **The join is BUILT and already paid for itself** (`electrode join`, §4c): its first run accused
    Atlas of missing the cast form `(H as any).X(`, the fix landed (`compile.ts`, `m12`/`m13`), and the
     undeclared column fell 60 → 24 — what remains is closures and by-name dispatch.  Still owner's:
      where the join LIVES long-term (it reads both censuses from Electrode today), and whether a
       fleet-wide armed sweep (path coverage per Book, union across the fleet) is worth a night — a
        four-Book taste is in §4d.
3. **The Creduler_ensure gate** above — cheap, measured, in the spine.  Yes or no.
4. **HELD — fold at the Story seam.**  `Electrode_reduce` is on demand today; the natural automatic seam
    is the end of a Story step (where `story_harvest_sworn` already moves evidence), giving every Book a
     per-step picture for free.  A few lines, but parked with the rest of the tap.
5. **HELD — line and branch tracing needs the compiler AND Atheory.**  A wrapper cannot see inside a
    body.  The deep version is a compiled variant of a ghost (`TheA_<Name>_<Variant>_<dige>`), and its
     purpose is teaching the program's flow, not profiling it (`Electrode_todo §1`).
6. **Atheory: the manifest as particles.**  `CREDULER_GHOSTS` (36 paths, a JS array), `GFILES` (4), and
    `Siphon_include` (6) still disagree (`Atheory_todo` "load-list inventory").  Electrode now gives the
     ROLE dimension a measurement instead of a guess: arm on a humdinger, play a track, and the flows say
      which of the 36 a music page actually touches (the static floor was 14 of 36, 2.38MB of 4.19MB).
7. Parked by the owner: the Atlas steady-state mtime hole (edit-notification CLI idea).  Not forgotten.

## 1. What stands today

| piece | path | status | door |
|---|---|---|---|
| the room | `src/lib/L/BigWordland.svelte`, route `/BigWordland` | built 2026-07-03, browser-verified by owner since | `?E=<Book>` (default Educarium), `?W=<Waft>` |
| its Book | `src/lib/L/Educarium.svelte` | Editron's sibling recipe — lays A:Educarium + Lies/Lang editor + Pantheate | boots with the room |
| the census | `Ghost/L/Atlas.g` (`ATLAS_MAPPER=m13`) | 711 docs, 0 errors, Dexie-warm, refresh-on-use; **12 functions, all keeping** since the readers moved out | `runner_ask ghost_load … --stand=Atlas`, `atlas_refresh`, minisnap |
| **the reader layer** | `Ghost/L/Lagoon.g` | **BUILT 2026-09-08** — callers · lint · unproven · join; keeps nothing | `ghost_load … --stand=Lagoon`, then `atlas_callers`, `atlas_lint`, `electrode join` |
| its Book | `Ghost/L/Lagoonation.g` → `LagoonStaple` | 6 steps, 7 sworn, green ×2 (`caveat:0`, gaps 0) — gates the CONCEPT LINE | `runner_ask run LagoonStaple` |
| its Book | `Ghost/L/Atlantation.g` → `AtlasStaple` | 6 steps, 10 sworn, green (re-swore under `story_swear` 2026-09-08) | `runner_ask run AtlasStaple` |
| the tap | `Ghost/L/Electrode.g` | built + stood live 2026-09-08; off by default | `runner_ask electrode …` |
| its Book | `Ghost/L/Electrodation.g` → `ElectrodeStaple` | compiles/parses; first recording pending | `runner_ask ghost_load Ghost/L/Electrodation.g` then `run` |
| the fixture corpus | `Ghost/L/test_corpus/` | frozen (`Sample.g`); **never edit** | — |
| the bundles | `Atheory_todo.md` | design + bench-verified mechanics; nothing built | — |

### 1.1 THE CONCEPT LINE — Atlas KEEPS; everything else ASKS

*The owner, 2026-09-08: "is Atlas something that's totally done now and we should build a separate thing
 that interacts with it for its elements? I need you thinking about conceptual globulation as we go piling
  on features to this new invention."  Yes to the separate thing — but "Atlas is done" is the wrong line
   to draw, because it dates.  The line that does not date is what the ghost is FOR.*

**Atlas has exactly one concept: the compiler's own index of every doc, kept fresh.**  A census.  The test
 for any new feature is one question — *does it change what is HELD, or does it ask a question OF what is
  held?*  Keeping and asking are different concepts, and only the first is Atlas.

**It has already drifted, measurably.**  Sixteen functions today:

| | |
|---|---|
| **keeping** (12) | `Atlas` · `_plan` · `_nav` · `_pass` · `_walk` · `_refresh` · `_map_one` · `_db` · `_cache_put` · `_cache_adopt` · `_forget` · `_report` |
| **asking** (4) | `_callers` · `_lint` · `_resolve` · `_unproven` |

A quarter of the ghost is answers, and it grew there one convenience at a time — which is what globulation
 looks like from the inside: no single addition was wrong.

**`Atlas_unproven` is the clearest tell, and the owner's disbelief is the diagnosis.**  Told that Atlas
 opens Book fixture files off disk, the owner: *"I don't believe Atlas would… that's not code."*  It does,
  at `Atlas.g:573` — `nav.read_file('wormhole/Story/' + b.name, f.name)`, walking every numbered `.snap`
   under `wormhole/Story` to collect the `%see` sentences some fixture recorded:

```
    for (const b of books.directories) {
        for (const f of b.files) {
            if (!SNAP_NAME_RE.test(f.name)) continue
            let text = await nav.read_file('wormhole/Story/' + b.name, f.name)
```

**The instinct that it shouldn't is right, and the code already half-knew.**  Its own comment reads
 *"~1000 reads at the current corpus; opt-in for that reason"* — a previous session felt the wrongness and
  paid for it with a flag instead of moving the function out.  That is the whole mechanism of globulation
   in one line: the smell gets a mitigation rather than a home.  A second source (fixtures) and a second
    concern (which claims are proven) living inside a code index.  It belongs in the reader layer, and
     moving it is a cut-and-paste, since it takes only `nav` and the Doc rows it already reads publicly.

**So the boundary, going forward:**
- **In Atlas:** anything that changes what is held — a new kind in the `%Map`, a new root, freshness,
   the cache.  Growth here is the census getting richer, and it stays one idea.
- **Outside Atlas:** every answer.  `lint`, `callers`, `unproven`, the declared-vs-measured `join`, and
   the explorer.  These are readers.  They need no privilege — a query over 711 doc rows is milliseconds,
    and `minisnap` already reads inside a `dontSnap` — so there is no efficiency argument for putting them
     in, only convenience, which is exactly the pressure to resist.
- **The join is the worked example of doing it right.**  It reads BOTH censuses and belongs to neither, so
   it went in the consumer (Electrode) rather than the keeper.  If a third reader wants it too, that is the
    signal for a reader ghost of its own, not for pushing it down into Atlas.

**Is Atlas done?**  The keeping half is *trustworthy*, which is the property that matters for building on
 it: 711 docs, 0 errors, the collector's two blind spots closed the same night they were found (§4c), the
  mapper version stamped in every row so a fix re-maps the corpus.  It is not *finished* — the steady-state
   mtime hole is parked by the owner, the three swept kinds still carry no `region_path`, and the call
    regex still matches only `this`/`H` receivers and not aliases like `top.`/`SH.`.  **None of those block
     a reader**, which is the real answer: build beside it now, and let the census keep growing underneath.

### 1.2 THE THING IN FRONT OF ATLAS — **`Lagoon`, and it is BUILT** (2026-09-08)

*Named by the owner the afternoon it was proposed (`Legend` was the proposal; `Lagoon` replaced it on
 sight and is better — shallow enclosed water where structures ERUPT, which is the owner's own picture of
  the surface: "little structures erupt when we go climbing call trees… they might be arranged around the
   place").  **Its doc is `Lagoon_todo.md`; read that, not this.**  Front 1 landed the same afternoon:
    `Ghost/L/Lagoon.g` stands, five readers moved out of the two censuses, `LagoonStaple` green ×2 with
     7/7 sworn and 0 gaps, and Atlas is back to 12 functions of pure census.*

The reasoning, kept here because it is the land's shape:

*The owner, 2026-09-08: "what's the next thing above Atlas that takes our complications going forward?…
 what's the infront-of-Atlas device going to be called?"*

**What it is, before what it is called.**  It is the one place every ANSWER lives, so that Atlas can stay a
 census while the questions multiply.  It has four tenants on day one, and three of them already exist and
  are homeless — this is not speculative surface, it is a move:

| tenant | where it lives today | what it is |
|---|---|---|
| `callers` | ✅ moved to Lagoon | reverse lookup over held `call,via` rows |
| `lint` | ✅ moved to Lagoon | missing / beyond-eof links, orphan defs |
| `unproven` | ✅ moved to Lagoon | which claims no Book ever recorded (§1.1 — the misfit that drew the line) |
| `join` | ✅ moved to Lagoon | declared vs measured; belongs to neither census |
| *the explorer* | still nowhere | the surface all four answer into — `Lagoon_todo §0` fronts 2-4 |

**Why it absorbs the complications rather than adding one.**  Every future question — coverage per Book,
 which ghosts a role actually loads, where a mainkey is minted, which doc link rotted, where this sentence
  is sworn — is a query over rows that are already held, and each one would otherwise be argued into Atlas
   individually.  A reader ghost makes the answer to "where does this go?" boring and permanent.  It also
    means the explorer is not a special case: **the UI is one more reader**, and the CLI ops become thin
     calls into the same verbs rather than a parallel implementation, which is what they are today.

**The name — RULED: `Lagoon`** (working title, the owner, 2026-09-08).  `Legend` was proposed here — the
 key printed beside an atlas — and the owner replaced it on sight with the better image: a lagoon is
  shallow enclosed water where structures erupt and settle, which is the behaviour rather than the
   mechanism.  Everything about it now lives in `Lagoon_todo.md`.

### 1.3 UX — five short stories

*Written to the owner's ask ("outline how UX will be in some short stories"), each grounded in real data
 from 2026-09-08 rather than invented.  They are ordered from the cheapest to the most distant.*

**1 · "Who calls this?"**  You are reading `Lies_role` in the editor and want to know who depends on it.
 The rail beside the code already holds pins; now it holds a caller list too, each row naming the
  *enclosing method* and its file, because that is what Atlas stores.  You click one and land on the line
   — the same one-elvisto delivery a search hit already makes, recorded in today's Aside.
 *Grounded:* this is `atlas_callers` at the CLI tonight, which answered `Lies_role → Lies_inside_story`
  only after the collector was fixed; before that the honest answer was an empty list, silently.

**2 · "This document is lying to me."**  You open a design doc.  Three of its file links are struck
 through.  Hovering says *target not found*.  You were about to follow one into a ghost that was deleted
  four days ago.
 *Grounded:* `atlas_lint` right now reports 1,782 file links across 711 docs, and several still point at
  `Ghost/M/Jam.g`, deleted 2026-09-04.  The data exists; nothing shows it to a human.

**3 · "What did this Book actually touch?"**  You run a Book, and the explorer shades every def the run
 entered, leaving the untouched ones pale.  The pale regions are the honest picture of what the suite does
  not exercise.  You are not reading a coverage percentage; you are looking at the map with the lights on
   in some rooms.
 *Grounded:* four Books under the tap reached 429 of 739 declared call pairs.  The shading is the join
  (§3), which already computes exactly this, printed as text.

**4 · "Where is this claim proven?"**  You are reading a sentence in a spec that asserts something.  You
 ask where it is sworn, and get either the Book and step that swears it, or the word *unproven* — meaning
  the corpus says it and nothing tests it.
 *Grounded:* `Atlas_unproven` computes this today, in the wrong ghost (§1.1), and nobody has ever seen its
  output outside a JSON blob.

**5 · "I'm lost, put me back."**  You come back the next morning, open the room, and it is where you left
 it: the same document, the same cursor, the same question half-asked.  Not a root listing, not a
  dashboard.
 *Grounded:* this is the one that needs no new invention and the one most likely to be reinvented.
  `%Interest` already carries stance, foreground, and per-Waft cursor memory off the Keep (`Interest.md`,
   `Keeping_spec`).  **Focus and intent are an Interest.**  If the explorer grows its own idea of "what am
    I looking at", that is the tell we built the third one.

Both L ghosts obey the same rules and it is worth saying them once: **truth in particles, caches in
 `.c`; never a particle per call/per line; `dontSnap` on the bulky picture so minisnap reads it and no
  fixture freezes it; no timer — use nudges a pass; a runner does the work, never the editor and never a
   humdinger; a new ghost needs no manifest edit (`Lies_ghost_set` takes any path) but its Book's own `.g`
    must be `ghost_load`ed before `run` or Story runs a hollow step.**

## 2. The two pictures, and why they are one

**Atlas** keeps what the compiler can see without running anything:

```
w:Atlas
  see:atlas,docs:585,mapped:585,errors:0
  Doc:Ghost/M/Heist.g,dige,lines:5249,defs:159,calls:337,by:m11
    Map,dontSnap
      def,method:Heist_keep,line,rel_from,rel_to
      call,method:Heist_has_body,via:Heist_keep,line
      controlflow,keyword:if,title:…,via:…
      elvisto | mint | proves | link | region
```

**Electrode** keeps what happened when it ran:

```
w:Electrode
  see:electrode,armed
  Graph,dontSnap,methods:189,flows:282,calls:7859,marks:15722,dropped:0,open:4
    Method:Lies_drain_inbound,n:21,ms:43,async:21,open:1
      Flow,of:Peeroleum_deliver,n:21,ms:42
    Method:∅                                  ← the detached caller: a resumed async body
      Flow,of:self_timekeeping,n:352,ms:10
```

Same vocabulary, opposite direction: Atlas puts the edge under the DOCUMENT it was written in; Electrode
 puts it under the CALLER it ran from.  `%Flow`, not `%Edge` — `%Edge,a,b` is Swarm's social-graph edge
  already, and two shapes under one mainkey is the tell we got identity wrong (CLAUDE.md).

## 3. The join — the actual prize

For a method `Y`:

| Atlas says | Electrode says | reading |
|---|---|---|
| `call,method:X,via:Y` exists | `Method:Y/Flow,of:X` exists | a declared call that ran — the normal case |
| exists | absent, after a full Book sweep | **never exercised** — dead branch or untested path |
| absent | exists | **dynamic dispatch the static walk cannot follow** — `do_fn_for` by `w.sc.w`, elvisto by string, a `.svelte` eatfunc — the 6.5% Atlas's own census already calls unresolved |
| `def,method:Y` exists, no `call` anywhere | `Method:Y` absent | the orphan (Atlas_lint already lists these) — now with a second witness |

The static border measurement in `Atheory_todo` (643 real cross-domain calls, 16 methods carrying 45%,
 21 mutually-recursive pairs) was a floor because it could not follow dispatch.  The measured picture is
  the ceiling.  The `TheA_` layers want to be cut between them.

## 4. First measurements (2026-09-08 night, live runner `da060c…`)

Armed the tap, ran `AtlasStaple` once, read the picture:

```
electrode: ARMED (coated 3564) — 7714 calls over 282 flows, 15432 marks in the ring (0 dropped), 4 open
  hottest by count:
     1152  Lies_ghost_get      → Lang_ghostmeta_name
     1152  Creduler_ensure     → Lies_ghost_get
      576  Creduler_ensure     → Lies_gen_path
      352  ∅                   → self_timekeeping
      297  Lies_role           → Lies_inside_story
      178  ∅                   → w_forgets_problems     (90ms total — the belief loop's own overhead)
  hottest by time:
      125ms  ∅ → agency_officing ×72 async     90ms  ∅ → w_forgets_problems ×178
       82ms  ∅ → Lies ×16                      72ms  ∅ → story_snap ×6  (71ms of it in snap_H)
hangs: 4 open frame(s), oldest first
    Lies_drain_inbound ← ∅ · Peeroleum_deliver ← Lies_drain_inbound · Peeroleum_deliver_do · Lies_runner_ask_recv
```

What that already says, plainly:

- **The hang list works and is honest.**  The four open frames ARE the ask being answered — the tap
   watching itself be read.  The film (`electrode film`) then shows all four close within a millisecond
    once the reply is sent.
- **`Creduler_ensure` is the loudest thing in the room** and it is doing nothing: every ready tick it
   walks all 36 spine ghosts reading their `Ghostmeta_*` version (twice — once for the ledger, once for
    `unmet`).  36 × 2 × 16 ticks = 1,152.  It exists to catch a hot-swap boundary (`Creduler_reswap`),
     which a changed-enrolment flag would catch for free.
- **`∅` is most of the time.**  Detached callers dominate the by-time list because everything the belief
   loop runs is an async continuation — which is the "async won't stack on its own" the owner predicted,
    measured.  The fix for attribution is real async-context propagation (threading a frame id through
     the belief loop's dispatch), not a smarter wrapper.  Deferred; the set is already useful.
- **Overhead is visible but small**: `Lies_ghost_get → Lang_ghostmeta_name` ×1,152 cost 3ms total.  The
   whole tally is one Map increment per call.
- **`AtlasStaple` went RED under the tap on that first armed run — and equally red UNARMED**, with
   identical step diges both ways, so the tap was innocent.  The step-1 diff said what it was: the
    fixture holds `req:wrangle,eternal,ok` under `w:AtlasStaple` and the live run did not — the Book's
     own handler was absent.  The owner's tab reload had dropped `Atlantation.g` (an L ghost is not in
      the spine manifest; `Stemdex_todo §0` names exactly this: *a Book's OWN `.g` must be `ghost_load`ed
       before `run`*).  So the numbers above are a trace of the Story machinery running a HOLLOW Book —
        still a true picture of what a run costs before the Book does anything, which is why
         `Creduler_ensure` dominates it.  The re-measurement with the Book actually working is §4b.

### 4b. The re-measurement — the Book actually working (same night, `Atlantation.g` re-loaded)

`AtlasStaple` **green 6/6 unarmed, then green 6/6 ARMED with `caveat:0`** — the coats are invisible to
 the fixture, which is the load-bearing property (a tap that changed a snap would be useless here).

```
electrode: ARMED (coated 3595) — 7577 calls over 356 flows, 15158 marks in the ring (0 dropped)
  hottest by count:                                 hottest by time:
     720  Lies_ghost_get → Lang_ghostmeta_name        3819ms  ∅ → AtlasStaple_await ×4   (the Book's own polls)
     720  Creduler_ensure → Lies_ghost_get             259ms  ∅ → Atlas_map_one ×4  max 194ms
     413  enL → encode_stringies  (the snap encoder)   247ms  ∅ → Atlas_pass ×10
     360  Creduler_ensure → Lies_gen_path               89ms  ∅ → story_snap ×6  (all of it in snap_H)
     333  enLine → enL                                  77ms  ∅ → Atlas_refresh ×4
      55  AtlasStaple_aw → AtlasStaple_SH               44ms  Atlas_pass → Atlas_map_one ×1
      53  AtlasStaple_witness → story_swear             14ms  ∅ → Atlas_cache_put ×4
```

And the picture, read as particles (`minisnap … Graph --depth=2`), shows the Book's own shape exactly as
 written — the drive fanning to five beats once each and the witness every tick:

```
Method:AtlasStaple_drive,n:11,ms:4,async:11
  Flow,of:AtlasStaple_witness,n:11     Flow,of:AtlasStaple_seed,n:1    Flow,of:AtlasStaple_bogus,n:1
  Flow,of:AtlasStaple_stale,n:1        Flow,of:AtlasStaple_drift,n:1   Flow,of:AtlasStaple_warm,n:1
Method:AtlasStaple_witness,n:11,ms:2
  Flow,of:story_swear,n:53             Flow,of:AtlasStaple_aw,n:11
Method:Atlas_pass,n:10,ms:247,async:10
  Flow,of:Atlas_walk,n:1   Flow,of:Atlas_cache_adopt,n:2   Flow,of:Atlas_report,n:6   Flow,of:Atlas_map_one,n:1,ms:44
Method:_collect_line,n:36,ms:2
  Flow,of:Lang_loose_and_split,n:24    Flow,of:Lang_sc_in_text,n:15    Flow,of:_collect_line,n:11   ← recursion, seen
```

What this run adds to §4's reading: **the Book spends 3.8 of its seconds polling** (`AtlasStaple_await`
 sleeps 200ms between truth checks — the honest cost of "expecting" over a belief loop the run does not
  pump, `Atlantation.g` beat 3's comment); the snap encoder (`enL`/`enLine`, ~750 calls) is the next thing
   after Creduler; and a real `Atlas_map_one` of `Sample.g` costs ~50–190ms, parse included.

**`ElectrodeStaple` recorded first time, 6/6, `mode:new`, 10 sworn.**  Contract installed by hand (10
 `Assertion:` lines, slugs unique — the SwarmSteal lesson); check-mode ×2 green, `caveat:0`, 10/10.
  **SABOTAGE-PROVEN the same night, no reload needed** (the `--swap` door, §4c): with `T.open.delete`
   removed from `Electrode_close`, the recompiled `.go` swapped in → `phase:failed`, `ok_pct:1`,
    `declared 10, sworn 8, gaps 2` — exactly *the open frame closes when its promise settles* and *a
     method that throws still closes its frame*; revert, recompile, swap → green 6/6, 10/10.  Fixture
      left as `001–006.snap + toc.snap` only (Credulate/Credulation churn stripped).

### 4c. The join, built and run the same night — `runner_ask electrode join`

`Electrode_join` (Ghost/L/Electrode.g) reads Atlas's `def`/`call,via` rows and the tap's tally, over the
 universe the tap can SEE (the ghost bag — Housing's class methods have Atlas defs but are never coated,
  so they sit in neither column).  One `AtlasStaple` run, Atlas at 711 docs / 5,458 defs:

```
join: 120 methods ran as callers · declared pairs 379, ran 202 → coverage 53.3%
      never-ran 177 · undeclared (dynamic) 60
  declared but never ran this session (via → callee):
    Peeroleum_deliver_do   ↛ Repli_xfer_get  Peeroleum_book_unemit  Peeroleum_rollup_faulty  Peeroleum_send …  (11)
    Lies_runner_ask_recv   ↛ Lies_audio_probe  Lies_ghost_set  minisnap  Lies_rungo_steps …             (8)
    Lies_become_book_drive ↛ Lies_book_refuse  Lies_secure_audio  Upkeep_errand …                        (8)
    Auto                   ↛ autovivify_Library  auto_reset_story  Cred_spool  Lies_runner_verdict …    (10)
    Story                  ↛ decode_toc_snap  The_frontier  entropy_forgive  story_sweep_next …          (12)
  measured but not declared:
     207  Lies_role → Lies_inside_story        32  story_harvest_sworn → story_assertioning
      34  Lies_is_runner → Lies_role           21  Peeroleum_deliver_do → Lies_heard
```

Read it as three kinds of row, because it is:

- **Never-ran that is simply "this Book didn't go there"** — `Peeroleum_deliver_do`'s eleven untaken
   branches are the transport's other frame kinds; `Auto`'s are the music/library legs; `Story`'s are
    the record/accept paths a check-mode run never enters.  This is *path coverage per Book*, which no
     fixture ever measured.  Run the whole fleet armed and the union is what the Books actually prove.
- **Undeclared that is a closure** — `Peeroleum_deliver_do → Lies_heard`: `Lies_heard` is called by the
   `on` wrapper `Lies_channel_up` installs; the wrapper is a closure (not coated), so the call is
    attributed to the innermost coated frame, which is the drain.  True, and the static walk cannot see
     it.  This is the "dispatch" column doing its job.
- **Undeclared that is an ATLAS GAP — the join's first accusation.**  `Lies_role → Lies_inside_story`
   ×207: the source reads `(H as any).Lies_inside_story()` (`LiesLies.svelte:146`), and
    `atlas_callers Lies_inside_story` returns `[]`.  `story_harvest_sworn → story_assertioning` is the
     same form (`Story.svelte:289`).  **The `.svelte`/`.ts` call collector does not match the cast form
      `(H as any).X(` / `(this as any).X(`** — 158 such sites in `src/lib/O` beside 1,901 plain `H.X(`
       sites, so ~8% of hand-written call edges were missing from the census.  **FIXED the same night:**
        `CALL_RE`/`CALL_GAP_RE` in `compile.ts` now admit `(H as any).X(` / `(this as House).X(` (same
         receivers, no new false positives; `CHECK=1` LocalGen shows the emitted `.go` of two ghosts
          byte-identical, so only the census changed), `ATLAS_MAPPER` → `m12`, Atlas swapped in and
           re-stood — all 711 docs re-mapped in ~40s.  Verified: `atlas_callers Lies_inside_story` now
            returns `Lies_role @ LiesLies.svelte:146`; `story_assertioning` gained `story_harvest_sworn`
             and `e_story_declare`.  **The same tally re-joined under m12: declared pairs 379 → 444,
              ran 202 → 238, undeclared 60 → 24** — the remaining 24 are closures and by-name dispatch
               (`Peeroleum_deliver_do → Lies_heard`, `→ Lies_runner_ask_recv`), which is what that
                column is for.  The join found the gap in its first minute and proved the fix in its
                 second run.  Its next row was another form — `(H as any).Clustation_active_identity?.(H)`,
                  the optional call — folded in as `m13` and verified (`atlas_callers
                   Clustation_active_identity` now lists `LiesLies.svelte:700` beside its two Auto.svelte
                    callers); regex tested against every form:
                   `this.X(`, `H.Y (`, `(H as any).Z(`, `(this as House).W()`, `H?.V(`, `X?.(`; `top.Q(`
                    deliberately still not matched — receiver aliases are a design question, not a gap).

**And the `--swap` door.**  A recompiled L ghost used to need a tab reload to take (`import()` is
 idempotent per URL; `Lies_ghost_set` early-returns on an enrolled gen).  `runner_ask ghost_load
  Ghost/L/X.g --swap` now does `Creduler_reswap`'s dance for one non-spine gen — HEAD the ETag, re-import
   under `?swap=`, drop + re-enrol so Otro remounts and the fresh eatfunc lays the methods.  Proven twice
    tonight (the join arrived on a live tab with no reload; `T` on `Mundo.c` survived, so the tally did
     too).  This is also the sabotage road for `ElectrodeStaple` that §4b said needed a reload.

### 4d. A four-Book taste of the fleet sweep (same night)

Reset, arm once, run `AtlasStaple · SwarmSteal · SwarmInvite · SwarmCohort` back to back — **all four green
 under the tap, `caveat:0` each** — and read the UNION join after each:

| after | methods ran | declared pairs | ran | coverage | never-ran | undeclared |
|---|---|---|---|---|---|---|
| AtlasStaple | 122 | 479 | 256 | 53.4% | 223 | 11 |
| + SwarmSteal | 141 | 522 | 296 | 56.7% | 226 | 11 |
| + SwarmInvite | 184 | 715 | 403 | 56.4% | 312 | 12 |
| + SwarmCohort | **192** | **739** | **429** | **58.1%** | **310** | **12** |

107,015 calls over 578 flows; the ring dropped 190,038 marks past its 20k cap while the tally stayed
 lossless — which is exactly why the tally exists.  What the union says that a single run could not:

- **Coverage climbs slowly because Books share a spine.**  Each new Book adds ~40–50 caller methods but
   the never-ran list barely moves: `Peeroleum_deliver_do`'s eleven other frame kinds, `Lies_runner_ask_recv`'s
    twenty-five other ops (every `atlas_*`/`Swarm_*` verb a run never asks), `Lies_become_book_drive`'s
     refuse/secure legs.  A fleet-wide sweep would show which of these NO Book ever reaches — the
      honest "untested" list.
- **Two new hot spots, from the Atlas `m13` re-map that overlapped the sweep:** `Lang_compile_collect →
   _collect_line` ×38,329 (the per-line collector, 145 docs) and **`Creduler_ensure → Creduler_reswap` ×48,
    7.6 s, max 2.8 s per sweep** — the hot-swap poll HEAD-fetches all 36 spine `.go`s every 2 s at a ready
     tick.  The Creduler gate from §0 item 3 would quiet both the version re-read and this poll together
      (one flag: "did the enrolment or the disk change").  Measured, not applied — the spine.
- **The `undeclared` column is now honest.**  Twelve rows, all of one kind: closures and by-name dispatch
   (`Peeroleum_deliver_do → Lies_heard` ×123, `→ Lies_runner_ask_recv` ×95, `Lies_advertise →
    Lies_engagement`).  Before `m12` the column was mostly collector gaps; the join cleaned its own input.

## 5. The room — what BigWordland becomes

### 5.0 THE ORDER OF WORK, ruled by the owner 2026-09-08

*"Electrode will help build some visual map of execution soon… but we need the protein-space that that
 map lives in, some kind of editor… which is Atlas hopefully? or just a code explorer to begin with…
  focus and intent is key."*

**Yes — Atlas is that space, and it is the only thing in the repo that already is one.**  Not because it
 is a nice index, but because of what it holds: 711 docs as particles, every def with its line, every
  call with its enclosing method, and — the part that makes it a *space* rather than a list — **1,782
   `%link` rows joining the prose to the code**.  Nothing else in the machine spans design docs and
    ghosts in one structure.  A map of execution needs somewhere to be drawn, and the drawing surface has
     to be the same substance as the thing drawn on it, or the two drift.  Atlas rows are particles, and
      so is Electrode's picture, and so is everything else here.  That is the whole answer to "protein-
       space": it is not a metaphor for a UI, it is the requirement that the medium be the same matter.

**So the order is: explorer first, execution map second.**  Electrode's picture is a *layer over* the
 explorer's space — `Method:` and `Flow` rows land on defs and call edges Atlas already holds (§3's join
  is exactly that registration, proven at the CLI).  Building the map before the space would mean
   inventing coordinates twice.  This is also why the tap is parked (`Electrode_todo §0`): not because it
    is unfinished, but because its next useful step is downstream of this one.

**"Focus and intent is key" already has a name here, and it is not new machinery.**  `%Interest` is the
 corpus's own word for exactly this — *"Interests are attention channels: the IDE escalates state through
  them"* (`Interest.md`).  It carries stances (giver / taker / lister / aside), a foreground rule (exactly
   one Trail bears the LE), an `ActiveInterest`, and a cursor that resumes per Waft off the Keep.  An
    explorer that invents its own notion of "what am I looking at and why" would be the third design of a
     thing that is built and live.  **The explorer's focus IS an Interest; its intent is the Interest's
      stance.**  Read `Interest.md` before writing a line of it.

**What that makes the first cut** (and it is smaller than "a code explorer" sounds): Atlas rows entering
 the surface that already exists, with focus carried by the Interest that already exists, and no new pose
  model — which is also what the prior-art gate below demands.  The two bullets after it are that cut.

Today (its own header): the H\*\* switcher, the ⚙ action rack, ⌐Lies summon, ▦ sprawl, the searchbar
 with a pin rail — *"a hit can be PINNED into the loose space at the right of the code."*  The owner's
  own next hop, unchanged: fold the pins into the DocMinimap proper.

**The prior-art gate applies** (`Lens_posable_TODO`: *"the posing/anchoring model is the unbuilt part —
 don't build until the pose model is designed"*; `Stemdex_todo §0`: read `Interest.md` first).  So the
  first cut is NOT a new Lens kind or a new panel.  It is two hit sources for a surface that exists:

- **Atlas rows into the StemHive.**  `Lies_search` today tiers exact ▸ prefix ▸ substring over the
   Stemdex's regex defs.  Atlas's `def` rows are the compiler's truth for the same names (Heist.g: 159 vs
    the regex's 158; `.svelte` eatfunc members the regex never saw).  A hit row already carries
     `{glyph, path, name, line, point}` and a click is already one `Lies_ghost_pick` delivery — Atlas rows
      fit that shape with no new UI.  Add one glyph: `→` for *callers of* (Atlas_callers), so typing a
       method name offers "12 callers" beside its def.
- **The measured picture in the pin rail.**  A pinned method is a natural place for a tiny live readout:
   its `Method:` row's `n`/`ms` and its top `Flow`s, when the tap is armed.  Read-only, pin-scoped, no
    new pose.

**Where the room reads from.**  Atlas and Electrode live on a RUNNER (they need FSA and spare capacity;
 the doctrine says never the editor).  The room is an editor tab.  Two honest roads: (a) the relay — the
  room asks the runner exactly as `runner_ask` does (`atlas_callers`, `electrode top`), which is the road
   `Cluster_spec` already paves for editor↔runner asks; (b) the shared Dexie — Atlas's `atlas` cache is
    per-browser, so a room tab beside a runner tab in the SAME browser can adopt the census rows directly,
     no wire.  (b) is faster and works offline; (a) is the general one.  Start with (a): it is the same
      shape the CLI already proves every day.

## 6. Open for the owner — ONE thing, and it is naming

*Trimmed 2026-09-08.  This section had grown four bullets, three of which were decisions this doc could
 make and was handing upward instead.  The owner, reading them: "that's chasing stuff, apparently needing
  me? I kind of doubt you need me for it… I don't know any context afaict."  Correct, and the general rule
   it implies is worth keeping: **a question costs the owner context they may not have; only ask when the
    answer is genuinely theirs — taste, product direction, or a risk only they can accept.**  What is left:*

- **Names.**  `Atlas` says in its own header that it is a placeholder.  `Wordland` is this doc's guess
   (the room is BigWordland, so the land is the Wordland).  `%Method` / `%Flow` / `%Graph` are the first
    mainkeys under `w:Electrode` and would be cheapest to change now.  Naming is the owner's by
     precedent — the rename-at-once pattern is theirs — and it is the one thing here nobody else can do.
  - **`GhostElectrode`** — proposed by the owner 2026-09-08, *"to deconfuse"*.  It reads well and sits
     beside `GhostList`; `Electrode` alone is a generic word wearing a ghost's slot.  **But it does not
      deconfuse the axis that will actually need it.**  Line and branch electrodes are electrodes on
       ghosts too, so `Ghost` does not separate them from what is built.  The real axis is *what a mark
        can see*: `CallElectrode` (entry and exit, a wrapper, built) versus `LineElectrode` /
         `BranchElectrode` (inside a body, compiled, a `Variant`).  So: take `GhostElectrode` if the
          confusion being cured is "the word is too generic to name a ghost", and it is a good fix for
           that.  If the confusion is "which electrodes are these", the split wants to be by sight, not
            by subject.  Costed either way: renaming touches the `.g`, its Book, the world name, the gen
             path, the CLI op and the `ElectrodeStaple` fixture directory — an hour, and cheapest now.
  - **`Legend`** — proposed here for the reader layer (§1.2), for the owner to accept or replace.

*Decided, not asked (each was in this list and should not have been):* the join lives in Electrode until
 something needs it elsewhere; the Story-seam fold stays on demand while the tap is parked; the
  eatfunc-deposited Housing methods (`w_forgets_problems`, `self_timekeeping`, `agency_officing`) stay
   coated — they ARE ghost code by the machine's own definition, so the picture showing the belief loop's
    overhead beside the ghosts' work is correct, and `ELECTRODE_SKIP` is there if it ever drowns a signal.

## 7. Verify (for whoever picks this up)

```
node scripts/runner_ask.mjs ghost_load Ghost/L/Electrode.g --stand=Electrode
node scripts/runner_ask.mjs electrode arm
node scripts/runner_ask.mjs run AtlasStaple --watch      # or any Book
node scripts/runner_ask.mjs electrode top --k=25
node scripts/runner_ask.mjs electrode hangs --older=1000
node scripts/runner_ask.mjs electrode reduce
node scripts/runner_ask.mjs minisnap 'mundo>A:Electrode>w:Electrode>Graph' --depth=2 --nodes=400
node scripts/runner_ask.mjs electrode disarm             # take the coats off a shared runner when done

node scripts/runner_ask.mjs ghost_load Ghost/L/Atlas.g --stand=Atlas   # then, with both standing:
node scripts/runner_ask.mjs electrode join --k=40        # declared (Atlas) vs measured (tap), per ran method
node scripts/runner_ask.mjs ghost_load Ghost/L/Electrode.g --swap      # after a RECOMPILE of an L ghost — no reload
```

A tab reload loses `A:Electrode` (runtime-minted on Mundo, like Atlas) — stand it again.  The compile
 ladder for either `.g`: `GFILES="Ghost/L/X.g" node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs
  scripts/LocalGen.spec.ts`, then esbuild-parse the emitted `<script>` block (both did, 2026-09-08).
