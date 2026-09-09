# Lagoon_todo.md — the code-wandering environment: the reader layer over Atlas

**`Lagoon` is a working title, the owner's, 2026-09-08.**  It replaced `Legend` on sight, and it is the
 better image: a lagoon is shallow enclosed water where structures *erupt* — reefs, atolls, things that
  surface and then get arranged around the place.  Which is the owner's own description of what happens
   here: *"little structures erupt when we go climbing call trees… they might be arranged around the
    place."*  The name carries the behaviour, not the mechanism.

Home of: the **reader layer** (every answer asked of a census, in one place) and the **wandering
 environment** built on it.  Its substrate is `Atlas` (`Wordland_todo §1.1`, `Stemdex_todo §0`); its
  surface is the BigWordland room (`Wordland_todo §5`); the execution map that lands on it later is
   `Electrode_todo`.

## 0. What to get on with next

### ☀ 2026-09-09 EVENING — the day lined up, and where it is going.  READ THIS FIRST.

The owner, tired, end of day: *"can we line up the rest of the day's work, and where are we going…"*
 This block is that.  The ~03:00 block below it is still true and is the record of the night.

**Where we are going, in one sentence:** the code is becoming the same legible living matter as
 everything else here — a census that KEEPS (Atlas, Electrode, the Stemdex), one reader that ASKS
  (Lagoon), and faces that are only renderings of one answer.  Every move today was that sentence
   applied to a new seam.

**What landed today, each a seam the bet crossed:**
- **The include door** — `Lies_ghost_include` (LiesLies).  *The mount was the load*: a ghost could
   only exist by being drawn, which is why the L ghosts kept evaporating.  Split.  A ghost can now be
    HAD without being SHOWN, and every attempt leaves `%GhostInclude:<gen>,stood:yes|<why>` on the
     shelf the Creduler already keeps — the spine and the hand-loaded land read off one list.
      `ghost_load`'s ack stopped lying the same afternoon (it reported `stood` after a no-op).
- **The served dige** — `src/lib/server/dige.ts` + `digePlugin` (vite.config.ts), `Atlas_diges`.
   Atlas already memoized the PARSE (Dexie); the 723 file READS it deliberately refused to skip now
    cost one conditional GET.  The dige still decides, and the tab CORROBORATES the server's stat
     against its own before reusing a hash.  Measured warm: `cache_none:0, cache_moved:1,
      dige_hit:722`.  The 1 was the corroboration catching a real mover on its first outing.
- **The Testing border** — `src/lib/L/testing.ts`; `Voronation.g → VoroTesting.g`.  A Testing doc is
   where the Book dialect meets a ghost's verbs — a place *"societies of language interact"* (the
    owner).  One predicate: Atlas keeps `%Doc,testing`, the Searchbar and Lagui draw the row with a
     teal border-rule + ⚗, runner_ask prints ⚗.  **Twelve `ation.g` files owe the same rename** and
      are deliberately NOT matched by the old name, so the rename cannot be skipped.

**Next, in order:**
1. **Rename the other twelve** `<Name>ation.g → <Name>Testing.g` (Swarmation, Musuation, Radiation,
    Atlantation, Lagoonation, Electrodation, Vytonation, Peregrination, Siphonation, Berthation,
     Errchannelation, Heistation).  Mechanical: mv, `CREDULER_GHOSTS` in LiesLies, drop the old
      `.go`, LocalGen.  Book names and fixtures do not move (a Book is named by its recipe, not its
       file).  The Credulation/GhostList toc.snaps churn — the accepted class.
2. **The figurines view** — the owner: *"figurines of things that are well connected… record runtime
    data about which methods are top-most, popular."*  The DATA ALREADY EXISTS: `Electrode_top` gives
     the hottest flows by count and by time; Atlas holds static popularity (`calls` per def and the
      caller index).  *Top-most* = a flow whose `from` is ∅ or never appears as anyone's `to` — a
       reduce over the tally, not a new tap.  So this is a Lagoon verb (`Lagoon_figurines`: joins
        Electrode's runtime tally onto Atlas's defs, ranks by in-degree × recency) and a FACE that
         sizes a figurine by that rank — `dose_drives` in Matstyle is the sizing idiom.  Ask first,
          keep nothing: the concept line holds.  Gate: a Book that arms Electrode, runs a known
           beat, and swears the top figurine by name.
3. **Rule on RETIRED vs GONE** and **`Story_next_level`** — still owed from the ~03:00 block.
4. **Style the Testing border in Cyto/Matstyle** if the owner wants it on the graph too — today it is
    on the two faces and the CLI only.

### ☀ WHERE IT STANDS — 2026-09-09, ~03:00, after the overnight run.

*The blocks below this one are the RECORD: the course as plotted, then what each leg cost and taught.
 They are worth reading and they are not a to-do list any more.  This is the to-do list.*

**Everything on the overnight plan is built, gated, and verified live** — legs 1, 2, 3 and 4, plus one
 thing the course did not contain at all.  Nothing is half-done and nothing is left broken.

**The big one is not on the course: §1.8, ONE ANSWER MANY FACES.**  It came out of four remarks the owner
 made in one night that read as four small complaints and were one.  The room had TWO seek machines — the
  Searchbar over the Stemdex and Lagui over Atlas — both ending in the same `Lies_ghost_pick`.  The
   Stemdex *is* a census; it keeps.  So it is looked up by name like Atlas and Electrode, `Lagoon_seek`
    asks over both, and the two surfaces are now renderings of one reply.
 **If you read one section before touching this land, read §1.8** — it is the concept line applied one
  level up, and the next person's instinct will be to add a third surface.

**What the night produced, in one list:** `Lagoon_seek` · `Lagoon_beads` · `Lagoon_rotwork` ·
 `Lagoon_oaths` · `Lagoon_sections` · three link kinds + the `anchor` row (`ATLAS_MAPPER` m15) · the
  `role:hacker` room · `scripts/LinkKinds.spec.ts` (7/7) · `scripts/SectResolve.spec.ts` (8/8) ·
   `LagoonStaple` grown 6→8 beats, 10 sworn,
   sabotage-proven · a Searchbar that is a surface rather than a dropdown · `runner_ask` auto-standing
    the land.  **Four real bugs fell out of using the thing**: `beyond_eof` counting unmapped docs as
     overshot (275→2), `Lagoon_defs` cutting before sorting, the § lint not inheriting the `history/`
      skip, and an `undef` mint in `Auto.svelte`.  Every one was found by looking at output, not code.

#### → THE NEXT MOVE, if you are the owner

1. **Look at the two faces.**  Nothing about how they LOOK has been seen by anybody — the Searchbar
    panel at 80vh, the beadchain, the families rail, `UI:Lagoon` landing beside `UI:Langui` in Hackarium
     now that `face_on` exists.  Reload `/Otro?H=Hackarium` (or BigWordland, which defaults to it).
2. **Rule on RETIRED vs GONE** (leg 3's entry below).  9 of 34 "no such doc" hits are docs on the
    `spec/history/` shelf, which by CLAUDE.md's own corollary are *fine*, not rot.  Two ways to fix it,
     both cheap; I did not pick because excluding the shelf was your ruling.
3. **Decide what `Story_next_level` should say now.**  14 of the queue's 83 pointers name it and it
    exists nowhere — not in `history/`, not anywhere.  That is the single biggest cluster and it needs a
     human who remembers what happened to that doc.
4. **The Waft flattening** is a real candidate for an attended session and you lean yes — contained, not
    corpus-wide (one seam, `LiesCurse`, six Lake\* Books, Funk untouched).  Its gate is re-recording
     `LakeSurprise`, `Interest.md`'s sole regression gate, and that wants reading rather than accepting.

#### → THE NEXT MOVE, if you are a fresh session working alone

- **Read §1.8, then the bombs.**  Three of the bombs are new tonight and all three make a healthy tab
   look broken: the hollow-Book signature (3c), the starved start (3b), and the auto-stand (2b).
- **`runner_ask lagoon rotwork --k=40` is a real work queue**, and the dead-anchor half of it (30 items,
   live docs whose §N moved) carries a proposed fix the census computed.  **⚠ THE PROPOSAL MAKES A
    POINTER RESOLVE; IT DOES NOT MAKE IT RIGHT** — and an earlier draft of this handover said these were
     "safe to act on", which would have invited exactly the wrong thing.  `§3.7 → §3` aims at the section
      CONTAINING what the author meant, which is one level vaguer than what they wrote; a dead pointer
       that is specific still says *"something moved here"*, and a live pointer that is vague says
        nothing at all.  So the proposal is a **starting point for a human**, per item, not a patch to
         apply in bulk.  The "no such doc" half needs the ruling above before it can be touched at all.
- **Do not add a fifth link kind without reading §1.7** — the plan's own proposal (`Doc#region`) appears
   twice in the corpus while `§N.N` appears 3,873 times.  Measure the corpus before choosing a form.
- **Leg 5 (coverage map) and leg 8 (attention stacks) both want the owner**: leg 5 needs the Electrode
   tap armed on their own tab, leg 8 wants `Interest.md` read WITH them or it is the third design of a
    live thing.  Leg 9 (the portal) needs a ruling on where asks live.

### ⛵ THE COURSE — plotted 2026-09-08 evening, the owner: *"I want allll these things. heaps."*

**This is the handover.**  The owner is compacting and switching sessions to execute; everything a fresh
 session needs to NOT re-derive is here.  Destination first, then the bombs, then the legs in dependency
  order.  Each leg says what it needs from the one before, so nothing is started out of order and nothing
   waits on a decision that has already been made.

**Destination, in one sentence:** a code-wandering tab where you SEEK (families → methods → callers →
 prose) and every seek LANDS in a Langui, the landing is RECORDED as a trail, code shows as a BEADCHAIN
  rather than a screed, what a run TOUCHED is shaded onto it, doc rot arrives as WORK to do, and a
   document can ASK Claude a question in place — all of it over Atlas (what the code says), read through
    Lagoon (every answer), with Electrode (what it does) as a layer that lands on it later.

#### The bombs — read before touching anything

1. **Two runner-ish tabs exist and unpinned `runner_ask` lands on whichever acks first.**  This is how
    Atlas ended up on the owner's editor tab hogging the beliefs mutex.  **Always `--runner=<id>`** for
     anything that stands a world.  Their tab today: `e747cbed6a9ca919`.
2. **`AtlasStaple` and `LagoonStaple` re-aim `A:Atlas` at `Ghost/L/test_corpus` (ONE doc) and never put
    it back.**  After any Book run the face honestly shows three methods.  Re-stand:
     `ghost_load Ghost/L/Atlas.g --stand=Atlas --fresh --runner=<id>` (~75s to 715/715).
2b. **`runner_ask` now AUTO-STANDS the land** (2026-09-09).  Any `lagoon`/`atlas_*` op refused with
     *"no A:X standing"* stands that ghost itself and says the census needs ~90s — because during a
      working session **every edit to app source hot-reloads the tab and drops all three L ghosts**,
       and the refusal always named the exact command that fixes it.  It does NOT retry the op: an
        immediate answer off an empty census looks like an answer, which is worse than a refusal.
3c. **⚑ A RED WHERE EVERY STEP SHARES ONE DIGE AND `sworn 0` IS NOT A FAILURE — the Book's own ghost is
     not loaded** (2026-09-09, and it cost three runs plus a wrongly-reverted fix to recognise).
     `Ghost/L/Lagoonation.g` is an L ghost like the rest: **any** edit to app source hot-reloads the tab
      and drops it, `do_fn_for` then finds no handler for `w:LagoonStaple`, the world never ticks, and
       all eight steps snap identical empty state.  The run even completes in ~11s and logs *"8 steps
        clean"*.  `runner_ask`'s auto-stand covers Atlas|Lagoon|Electrode but NOT a Book's own ghost.
     **Tell it apart from a real red by the SHAPE, before bisecting**: a real failure has per-step diges
      and specific named gaps; this has one dige repeated and *every* declared assertion absent.  The
       fix is `ghost_load Ghost/L/Lagoonation.g` and re-run — nothing to debug.
     *(I chased this into `Auto.svelte` and reverted a correct change before spotting it.  The existing
       rule — "a red that reproduces on a stale tab is still not real" — has a sibling: a red that
        reproduces on a tab that has DROPPED the code under test is not real either.)*
3b. **A Book started right after `--stand=Atlas --fresh` sits at `begun/n:null` for ~2 minutes and is
     NOT wedged** (2026-09-09).  The 724-doc walk is hogging the belief loop, so the run cannot get
      going; `--watch` gives up first and it looks exactly like bomb 3.  Poll `state` before bisecting —
       it goes to `stepping` on its own.  Either wait for the census, or run the Book first.
3. **Writing a gen `.go` while a tab is up can wedge Story at `begun/n:null` with NO console output.**
    `--swap` did not clear it.  `runner_ask reload` then re-stand the land is the reliable heal.  A Book
     recording after a recompile: compile → reload → re-stand → run.
4. **There is exactly ONE editor and Lies enforces it twice** (`LiesFunk` ~:499 the Cluster claim
    supersedes every other editor row; `Lies_aim_setup` gates on `=== 'editor'`).  **Never open a second
     editor-role tab**; it evicts the owner.  This is why leg 1 exists.
5. **`point` in `Lies_ghost_pick` is a STRING** — a def name, or `text:<words>`.  An object in `sc` brands
    every recorded Point junk.  Today's `wormhole/Aside/2026-09-08` carries a dozen such rows from before
     the fix; they are the owner's to prune.
6. **A report row writes ONLY ON CHANGE; a face asks ON A LEASH.**  Both halves of the tailspin.  A
    `$derived` off a census world's `version` re-runs on every mapped doc.
7. **For any Book against a ghost that LOOKS ITS SUBJECT UP:** stand where the reader looks
    (`top_House()`); gate claims on a snapped marker from an `expecting` beat, never on a flag a sync beat
     set; drive the passes, don't wait for a tick.  Four recordings paid for those.
8. **`compile.ts` carries two NUL bytes** — plain `grep` finds nothing in it; use `grep -a`.
9. ~~**`LagoonStaple` flakes ~2 in 11**~~ — **FIXED 2026-09-08 night, and SABOTAGE-PROVEN.**  See §1.6.
    Two causes, one root (a step costing an extra belief round): an `expecting` beat whose in-flight-vs-
     settled state was frozen into a fixture, and sworn sentences latching at whichever step they first
      became true at.  Now 7 consecutive green runs including the exact trigger (a fresh `--stand=Atlas
       --fresh` over the real 715-doc corpus immediately before).  **The lessons generalise — read §1.6
        before writing any Book whose beats do real work.**
10. **Atlas keeps; Lagoon asks.**  The test for any new feature: *does it change what is HELD, or ask a
     question OF what is held?*  Lagoon must never start keeping — `LagoonStaple` reds if it does.

#### 🌙 THE OVERNIGHT PLAN — agreed 2026-09-08 night, before a compaction

*What a session with no human and no browser can honestly finish, in order.  The rule that picks them:
 **a leg is good overnight work iff its GATE is something I can run** — a spec, a measurement, a compile.
  A leg whose only proof is "open the tab and look" is not, however easy the code is.*

**DO, in this order:**
1. ~~**The `LagoonStaple` flake** (bomb 9) and its **sabotage proof**.~~  ✅ **DONE 2026-09-08 night — §1.6.**
2. ~~**Leg 7 — more link kinds.**~~  ✅ **DONE 2026-09-08 night — §1.7.**  Three kinds landed (`sect`,
    `book`, `sworn`) plus a fourth row type (`anchor`), gated by `scripts/LinkKinds.spec.ts` 7/7.
     **The plan's own proposal was wrong and the corpus said so** — read §1.7 before adding a fifth kind.
3. ~~**Leg 6 — rot as a work queue.**~~  ✅ **DONE 2026-09-09 — `Lagoon_rotwork`, `runner_ask lagoon
    rotwork`.**  Groups by DOC (you visit a document, not a link), proposes the fix where the census can
     compute one (`§3.7` → the doc has 3.1…3.4, so `§3`), and picks the likely exit.  **It caught a real
      bug in the existing lint within a minute of running**: `beyond_eof` compared against `doc.sc.lines`,
       which only a real map stamps — so every link into an as-yet-unmapped doc read as overshooting a
        0-line file (275 mid-walk, falling to ~100 as the census converged).  A convergence artifact
         wearing a verdict's clothes; the old lint printed a list, the queue printed *"that file is 0
          lines"* next to a file you know is fine.  Fixed.
    Also ruled, from a first cut that was wrong in an instructive way: **the exit turns on DISTINCT dead
     targets, not the count.**  `Wire_spec.md` has 13 dead pointers and read "stale, retire it" — but all
      thirteen name ONE vanished doc, so it is a single retarget, not thirteen repairs or a retirement.
    **Live over the whole 724-doc corpus: 83 rotted pointers over 43 docs — 42 to FIX, 1 STALE.**  Both
     rulings visibly hold: `Wire_spec.md` reads FIX (13 pointers, one vanished target — one retarget),
      and the single STALE is `ulative/memory-raw/music-cluster-kickoff.md`, which points into THREE
       different docs that no longer exist.  Read it with `runner_ask lagoon rotwork --k=40`.
    **AND ACTING ON IT FOUND TWO MORE THINGS, which is the point of a queue** (2026-09-09).  Trying to
     repair the biggest cluster surfaced both — neither was visible from reading the code:
    - **A rule I forgot to carry across.**  The `file:line` lint has always skipped targets naming
       `history/`|`shelved/` (Atlas never rosters those roots, so it can neither confirm nor deny them);
        the new § pass did not.  So a doc writing `history/Reqdrop_todo §N` — a reference that is already
         CORRECT and explicitly points at the shelf — was reported as pointing at a doc nothing has.
          Fixed; "no such doc" fell 37 → 35.
    - **⚑ A RULING OWED: the lint cannot tell RETIRED from GONE, and they are different work.**
       Cross-checking the 34 remaining "nothing rosters that doc" against `spec/history/`: **9 of them
        are retired docs sitting on the shelf** — `Division_todo` ×5, `Waft_spec` ×3, one more.  By
         CLAUDE.md's own corollary (*"a referenced `spec/X.md` that isn't there is almost certainly
          `spec/history/X.md`"*) those references are **normal and readable, not rot** — the convention is
           that a reader knows to look there.  The other 25 (`Story_next_level` ×14, `Cluster_design`,
            `Vyto_normal`, `MobilenoFSA_todo`…) name docs that exist NOWHERE, shelf included.
       Lagoon cannot separate them because Atlas deliberately excludes `history/` — *"retired"*, its own
        comment says.  **Two ways to fix it, and the choice is the owner's, not mine:** roster the shelf
         and stamp those Docs `retired` (the census then holds a fact instead of the rule living only in
          prose, at the cost of ~27 more mapped docs), or give the queue a nav and check the shelf on
           disk the way `Lagoon_oaths` does.  I did not pick, because excluding the shelf was a ruling.
    **It is a QUERY, not a document, and that is deliberate** — there is no queue file to check in and no
     "done" flag anywhere, because an item's disposition IS the edit: fix the pointer and it stops being
      derived; retire the doc and every item under it goes with it.  A work queue over a census needs no
       state of its own, which is the same layer rule one storey up.
4. ~~**Leg 4 — the beadchain.**~~  ✅ **DONE 2026-09-09 — `Lagoon_beads`, `runner_ask lagoon beads <doc>`,
    and `seek doc:<part>` when the scope lands on one file.**  It was cheaper than the plan guessed:
     Atlas records each def's enclosing region chain on `.c.region_path` as the collector walks, and
      `Atlas_cache_put` carries it through the Dexie row — so there is **no containment arithmetic and no
       span to intersect**; every def already knows its beads.  A flat `chain` in FILE ORDER with a
        `depth`, per the spec's own first cut: a chain, not a graph (no pose model invented).
    Live: `Atlas.g` → 3 beads / 13 defs, with "the cache" nested inside "the pass" and its four verbs
     under it.  `Lagoonation.g` → **0 beads, 16 defs, "16 outside every bead"** — which is the honest
      answer for a file whose author never drew one, and doubles as a tell for which files are screeds.

**DO NOT, and why:**
- **The Waft flattening** — RE-SCOPED after the owner pushed back, and it is CONTAINED, not corpus-wide
   (one seam, `LiesCurse`, six Lake\* Books, Funk untouched — see leg 3's note).  Still not an overnight
    job, but for a different and better reason: its gate is re-recording `LakeSurprise`, which is
     `Interest.md`'s sole regression gate for the Interest cluster, and that wants reading rather than
      accepting.  **It is now a real candidate for the next attended session, and the owner leans yes.**
- **Leg 9, the portal** — needs a ruling on where asks live.
- **Leg 8, attention stacks** — wants `Interest.md` read WITH the owner; it is the third design of a live
   thing if done alone.
- **Leg 5, the coverage map** — needs the tap armed on the owner's own tab and a Book sweep; doable but it
   touches their live tab while they sleep.  Ask first.
- **Anything whose gate is "open it and look."**

**THE ONE UNVERIFIED FOUNDATION, and it should be checked first thing:** legs 1 and 2 are gated in logic
 (`HackerRole.spec.ts` 9/9) but NOT in life — nobody has yet confirmed that a working editor elsewhere
  keeps its `%HostedIdentity` row while a hacker tab is open.  Everything visual now stands on that.  If
   it turns out false, stop and fix it before building further.

#### The legs, in order

### ✅ LEG 1 IS BUILT — 2026-09-08 evening.  **`/Otro?H=Hackarium`**

`role:hacker` landed, and the audit below turned out to OVERSTATE the work: of the ~7 gates it listed as
 capabilities, **four were duties** (`Lies_send_rungo`, `Lies_drain_rungo`, `Lies_send_gen_write`,
  `Lies_ledger_broadcast` — all relay/dispatch, all correctly skipped) and **two more are Keep WRITES**
   (`Lies.svelte:1013/1018`) which stay editor-only because the Keep is single-writer and a hacker's
    own where-was-I belongs in its trail.  **Exactly one gate was re-pointed**: `Lies.svelte:233`, the
     cursor RESUME, which is a read.  What landed:
- `Lies_role` returns `'editor' | 'runner' | 'hacker'`; `w.sc.hacker` is its flag.  New
   `Lies_has_docks()` (editor ‖ hacker) for capabilities, `Lies_is_editor()` untouched for duties.
- `Otro`: `?H=<Book>` → `boot_role:'editor'` (so world layout and disk gating are inherited unchanged)
   plus `h.c.role = 'hacker'`, which every duty gate misses because they all test equality.
- `src/lib/L/Hackarium.svelte` — the recipe.  Lays `w:Lies,hacker:1` and a flagless `w:Lang`, and **no
   Pantheate** (it mounts compile-run artifacts; a hacker does not compile).  **It stands Atlas and
    Lagoon ITSELF** — fire-and-forget `Lies_ghost_set`, never awaited from the do_fn (Atlantation beat
     2's circular-wait lesson) — so the tab comes up whole with no CLI, no relay and no editor.
- Mounted in `O/Ghost.svelte`; minimal `wormhole/Story/Hackarium/toc.snap` seeded.

**Three properties confirmed by reading the code, and they are what make it safe:**
1. **No channel at all.**  `Lies_channel_up` returns bare for any role that is not editor|runner|armed-
    player, `Lies_transport_up` is `!== 'editor'` → return, and `Lies.svelte:754` gates
     transport/channel/heartbeat the same way.  A hacker cannot collide with the editor because it never
      speaks to the relay.
2. **The spine still loads.**  `Creduler_ensure` is gated on `w.sc.creduler`, not on role, and Auto
    stamps that regardless — so a hacker gets all 36 ghosts.
3. **Not a humdinger** (that stamp comes from `boot_qualand`, which Otro does not use), so nothing is
    refused on it and `ghost_load` remains available if ever wanted.

**Verified:** all five touched components svelte-compile clean; `/Otro?H=Hackarium` SSRs 200 with 390KB;
 **the owner opened it, clicked a stem, and it landed** ("lovely").
**✅ GATED — `scripts/HackerRole.spec.ts`, 9/9, no runner and no browser.**  The safety claim is a PURE
 FUNCTION OF ROLE, so it did not need a Book: every duty in the spine is an equality test against
  `'editor'`, and one assertion that a hacker is not the editor therefore covers all seven of them at
   once.  The spec also pins the no-channel path, that the write gates stayed editor-only while the
    cursor RESUME became shared, that Creduler is gated on the flag rather than the role (so a hacker
     still gets its ghosts), and that both rooms boot it without taking the editor slot.  Test 1 asserts
      the source of `Lies_role` still matches the copy the tests reason over, so the gate cannot rot into
       agreement with itself.
**Still owed (browser-only):** that docks and Langui appear, and that a working editor elsewhere KEEPS
 its Cluster row while a hacker tab is open.  The logic is gated; the lived behaviour is not.

---

**LEG 1 — `role:hacker`.  Everything visual waits on this.**  *(the plan as written, kept for the audit)*  (Ruled by the owner: *"role:hacker for
 now?"* — yes.)  A tab that has the editor's LOCAL capabilities (A:Lang, Langui, docks, FSA read) and
  none of its SINGULAR duties (Cluster claim, %Aim, relay editor socket, Waft saves).  The audit in §2.7
   is complete; the build is:
- `BigQualand`/Otro: a new boot param (suggest `?H=<Book>`, mirroring `?E=`/`?B=`) → `boot_role: 'editor'`
   (machine stays two-valued, so worlds and disk gating are inherited) + `H.c.role = 'hacker'`.
- `Lies_role` type widened to `'editor' | 'runner' | 'hacker'`.  Every DUTY gate is `=== 'editor'` and
   opts out for free — do not touch them.
- New predicate `Lies_has_docks(w)` = editor || hacker.  Re-point the ~7 CAPABILITY gates
   (`Lies.svelte:233/1013/1018`, `LiesLies:573/606/650/970`).  Leave the 3 WRITE gates
    (`Lies.svelte:833`, `LangCompiling:274`, `LiesCortex:155`) editor-only: **a hacker reads**.
- A `Hackarium` Book recipe beside `Educarium` (`src/lib/L/`): lays `A:Lies editor:1`, `A:Lang editor:1`,
   then `Lies_ghost_set` Atlas + Lagoon and stands them ITSELF — so the hacker tab needs no `runner_ask`,
    no `ghost_load`, and no relay to come up.  Self-contained.
- **The one unknown, RESOLVED (checked 2026-09-08 evening): a hacker stays OFF the relay by
   construction, no code needed.**  `Lies_channel_up` (`LiesLies.svelte:306`) reads
    `if (role !== 'editor' && role !== 'runner' && !player) return   // bare: no channel`, and its caller
     (`Lies.svelte:754`) gates on `is_editor || is_runner || player_seen` before standing transport,
      channel or heartbeat.  A `'hacker'` matches none of those, so the six `peer = …` sites never run for
       it — there is no channel for them to run in.  That is exactly the v1 wanted: a self-contained
        local tab that cannot evict the editor because it never speaks to the relay at all.  (Later, if a
         hacker wants `runner_ask` reachability, it joins as `player`-style READ-ONLY — the door
          `Lies_player_seen` already opens — never as an editor.)
- Gate: a Book (`Hackation.g` → `HackStaple`?) swearing: the tab has docks; `Lies_role` is `hacker`;
   `Lies_aim_setup` did nothing; no `%HostedIdentity,role:editor` row was claimed.  The last is the one
    that protects the owner.

### ✅ LEG 2 IS DONE, AND THE ROOM ABSORBED THE TAB — 2026-09-08 evening

The owner opened `/Otro?H=Hackarium`, clicked a stem, and it landed: *"lovely"*.  Then: *"it needs a
 fullscreen-er presentation… BigWordland was it I think?  nothing else is happening with BW, we should
  probably take this all there… they are very similar right?  unity a cleanse."*

**They are the same thing wearing different clothes** — both boot a Book and render `H.UIs`.  What the
 room has that the tab lacks is PRESENTATION: the H\*\* switcher that makes one House fullscreen, the ▦
  sprawl, the pin rail, the searchbar.  So the room took the Book, rather than the Book growing a room.

- `/BigWordland` now defaults to **Book `Hackarium`, role `hacker`** (was `Educarium`, role `word`).
   `?H=<Book>` overrides.  A `hacker` badge sits beside the room's name so it is visible that this tab
    does not hold the editor slot.
- `boot_qualand` gained `'hacker'` as a fifth role: it maps to the `editor` boot_role like `word` does
   (so world layout and disk gating are inherited unchanged) and additionally stamps `H.c.role`.  It is
    still stamped `humdinger` — a room is never a dispatch target — and that costs nothing now, because
     **Hackarium stands Atlas and Lagoon ITSELF** rather than waiting for a `ghost_load` that a humdinger
      would refuse.  That refusal is exactly what kept the L ghosts out of this room until today.
- `?E=<Book>` still boots the old editor room for anyone who explicitly asks, with the eviction warning
   written at the call site.

**Verified:** `BigWordland` and `BigQualand` compile; `/BigWordland` serves 200 with 392KB of SSR.
 **Owed:** the same browser check as leg 1, plus confirming the switcher opens on the Hackarium Run.

**LEG 2 — the seek lands.**  *(the plan as written)*  Needs leg 1.  On a hacker tab the tab's own Liesui/Langui exists, so
 `Lies_ghost_pick` lands without any change to Lagui.  Verify by clicking a family → method → the editor
  moves.  Only if the owner wants the CodeMirror INSIDE the panel does Lagui mount its own `<Langui {H}/>`
   — and then it is the ONLY Langui on that tab, so the multi-editor bookmark/autosave races do not arise.

**LEG 3 — the trail.**  Needs leg 2 (points must land to be worth recording).  The Aside already IS the
 trail (`What` per moment → `Doc` → `Point`), and bomb 5 is fixed so Points are real now.  Build the
  trail VIEW first: today's Aside rendered as a chain in the hacker tab — that is the recipe's *linear
   stretch* (§1) and the beadchain's first instance at once.  Then enrich a Point at record time with
    what was looked at (the def, its family, its caller count) so the trail teaches.  The owner:
     *"you could probably loop for a long time making something that just records someone's trail
      through the code."*  This is the leg to loop on.

> **Leg 3 RULING, the owner, last thing before compacting (2026-09-08 evening):** *"it seems weird to
>  have What/Doc/Point now, perhaps What/Point with a Doc pointer as part of it… above the Map-like object
>   and lines… just having a context the Point is going for."*  **This is the identity law applied to the
>    trail, and the current shape breaks it.**  Today's Aside mints a `Doc:<path>` particle inside every
>     `What` — but the Doc is a HOLDING in Atlas (`w:Atlas/Doc:<path>`), so the Aside's copy is the second
>      shape under one mainkey, the exact tell CLAUDE.md names.  A trail Point is a REFERRING particle: it
>       wears its own mainkey and CARRIES the pointer.  So the shape becomes
>        **`What / Point,doc:<path>,at:<def-name>`** — flat, one level, the Doc as an `of:`-style key on the
>         Point.  "Above the Map-like object and lines" is the resolution: `at:` names a `def` row Atlas
>          already holds, so a Point resolves INTO the census rather than duplicating a bit of it.
>           "A context the Point is going for" is what `at:` is — not a line number, the thing you were
>            after.  **Atheory-meshed:** the owner also wants an overall UI concept that meshes with
>             `TheA_<Name>_<Variant>_<dige>`; the cheapest reading is that a Point's context should also
>              name the BUNDLE it sits in, which Atlas can supply from `Lagoon_families` today and from the
>               declared manifest once Atheory lands.  Not designed further — flagged as the owner's, and
>                leg 3 should build the flat shape from the start rather than migrate to it.

> **⚠ THE FLATTENING — PROPERLY SCOPED (2026-09-08 night, after the owner asked "have you properly
>  scoped it?").  My first answer was a headline count and it OVERSTATED the job.**  The real shape:
>  1. **There is ONE seam, not twelve.**  `Lies_walk_docs` is defined once (`LiesCurse.svelte`) and
>      already recurses through Whats — it IS the abstraction over "find the Docs in this Waft".  The
>       outside callers (Searchbar, DocWaftMap, LiesFunk, Lies) go through it and keep working.
>  2. **The concentration is `LiesCurse.svelte`** — 8 of the 20 direct `{Doc:1}` queries plus the walk
>      itself.  That is the CURSORING the owner named: *"it's got a cursoring looking it up… it wasn't
>       working that fantastically!… I simply don't use this."*  So the file carrying most of the cost is
>        the file whose behaviour is least loved.
>  3. **The fixtures are not 53 things, they are SIX BOOKS in one family** — LakeNets 14, LakeSurprise 13,
>      LakeTiles 10, LakeFlush 8, LakeWaftMap 3, LakeSurfer 3 (51 of the 53 files), plus one each from
>       Hackarium and Editron.  All Lake\*: the editor/Waft machinery itself.  They would need re-recording
>        because the thing they test changed, which is correct rather than collateral damage.  ⚠ Note
>         `LakeSurprise` is `Interest.md`'s **sole regression gate** for the Interest cluster — it is the
>          one to re-record carefully and read, not accept.
>  4. **Funk is SAFE, which was the owner's stated worry** (*"Waft carries Funk though, which is
>      important"*).  `Lies_instantiate_funkcions` walks with a generic `for (const k of c.o())` recursion
>       — shape-blind, so it finds a `%Funkcion` wherever it sits.  Flattening cannot lose it.
>  **Verdict: contained, not corpus-wide.**  One seam, one concentrated and unloved file, six Books in one
>   family, Funk untouched.  It is a real leg, and it should be its OWN leg with the Lake\* re-record as
>    its gate — but it is more tearable-up than I first said, and the owner's instinct was the right one.
>  **What WAS done instead, because it answers most of the complaint for one line:** a moment is no longer
>   anonymous.  `e_Lies_ghost_pick` now stamps `about:<the thing you were after>` on a fresh `What`
>    (`Lies.svelte`), which is the owner's *"a context the Point is going for"* without moving anything.
>     A day's trail reads as named moments from today.
>
> **The Aside junk IS this ruling, looked at (2026-09-08, the owner: *"check out these Waft:Aside though,
>  they're full of junk"*).**  The object-in-`sc` bug is fixed and today's file proves it —
>   `Point,method:Musica_cards` is a clean scalar, and `Musica_cards` really is in `Ghost/M/Heist.g`, so
>    the landing is correct.  What remains is not corruption, it is the SHAPE, and it is small: twelve
>     days, 58 lines total.  Three complaints, all of which the flat form above answers:
>  1. **Every `What` is anonymous.**  A day reads `What`, `What`, `What` — a pile of unnamed moments with
>      no idea what any of them was FOR.  The owner's *"a context the Point is going for"* is the missing
>       field, and it belongs on the Point, not on a container.
>  2. **`Doc` is a duplicated holding** (the identity-law break above), so the trail carries a second,
>      thinner copy of something Atlas holds properly.
>  3. **`FromWhat` is inconsistent across days** — a bare path (`Ghost/N/Peeroleum.g`) on 06-21, a full
>      locator (`Waft:Aside/2026-07-03/What:1`) on 07-03.  Two forms for one relation, which is its own
>       small identity smell; pick the locator.
> **The cleanse:** do NOT migrate the old files.  They are pre-shape, tiny, and genuinely historical —
>  leave them and let leg 3 write the new form from today.  A trail that changed shape is legible; a
>   rewritten one has lost the only thing it was for.

**LEG 4 — the beadchain.**  Needs leg 2.  Atlas holds `region,label,depth,from,to` for every doc — the
 beads, with depth as the clustering.  First cut: a doc rendered as its regions nested by depth with defs
  inside, in file order — a CHAIN, so no pose model is needed (`Lens_posable`'s gate).  Add it to Lagui as
   the way a doc is shown when you land in it.  Compound-node vocabulary later, from Cyto's own
    `compound` class.  §2.8.

**LEG 5 — the coverage map** (the owner: *"yes! this is important new ground"*).  Needs leg 4 (something
 to shade).  `Lagoon_join` already computes ran/never-ran per method; the union across Books is a reset →
  arm → run N Books → join (proven, §4d of `Wordland_todo`).  Shade beads by whether a run entered them.
   The tap is PARKED but arming it for a measured sweep is use, not extension.

**LEG 6 — doc rot as a work queue.**  Needs leg 2.  `Lagoon_lint.missing` (1,783 file links) and
 `Lagoon_prose_rot` (179 likely-rot symbols, §2.8) are the raw material.  Route each as a piece of work
  with a location and two exits — *fix the pointer* or *mark the doc obsolete* — and land the fix click in
   the editor.  The owner: *"higher level pointers or sending you around fixing|obsoleting things is the
    way."*

**LEG 7 — more link kinds.**  Independent; can run alongside any leg.  Each is a regex + `kind:` in
 `compile.ts`'s markdown sweep, an `ATLAS_MAPPER` bump, and a Lagoon resolver.  In value order: spec →
  sworn sentence (the owner kept this one), `Doc#region` (a bead), Book and step, `%Mainkey` notation.
   §2.8.

**LEG 8 — stacks of attention.**  Needs leg 3 (the trail is what a stack is made of).  **Read
 `Interest.md` first**; `%Interest` has stances, the foreground rule, multi-giver arbitration and per-Waft
  cursor memory off the Keep.  A stack is that, kept, not a new idea.

**LEG 9 — the portal.**  Needs leg 7's `[[ask: …]]` kind, and an owner ruling on WHERE requests live (a
 `%Ask` under the Aside is the natural home).  Mechanics in §2.8: a link mints a request particle; a
  Claude session watching that path answers by editing the doc in place; asynchronous by construction;
   show whether a session is watching, the way `Lies_channel_live` does for runners.

**LEG 10 — the recipe.**  Needs legs 3 and 7.  Tip / linear / spiral rendering of a doc, COMPUTED from
 what Atlas holds: the tip is `§0`, the linear stretch is sections whose links still resolve, the spiral
  is everything pointing into `history/` or at files that are gone.  No new discipline from a human.  §1.

**HELD behind Atheory** (not this course): fold Electrode at the Story seam; line/branch electrodes as a
 `TheA_<Name>_<Variant>_<dige>` Variant; the declared manifest.  `Electrode_todo §0`, `Atheory_todo`.

**Owed on what already landed:** a sabotage proof for `LagoonStaple`; the flake (bomb 9); `Lagui` should
 say out loud which corpus it is looking at (bomb 2); `Lagoon_resolve`'s duplicated constants.

---

### ✅ FRONT 1 IS DONE — 2026-09-08, the same afternoon it was proposed

`Ghost/L/Lagoon.g` stands, all five tenants moved, and **`LagoonStaple` is green ×2 on the live runner:
 `ok_pct:1, caveat:0`, declared 7 / sworn 7 / gaps 0.**  What landed:

- **Atlas is a census again** — 16 functions down to 12, all keeping.  `Atlas_callers`, `Atlas_lint`,
   `Atlas_resolve` and `Atlas_unproven` are gone from it, with the three constants only they used.
- **`Electrode_join` moved too**, becoming `Lagoon_join` — it reads both censuses and belongs to neither,
   which is the worked example the boundary exists for.
- **The CLI op names are unchanged** (`atlas_callers`, `atlas_lint`, `electrode join`), so no script
   breaks; they dispatch into Lagoon and refuse by name if it is not standing.
- **Proven live before and after the move**: `atlas_callers Lies_inside_story` returns the same two
   callers; the lint reports the same 1,783 file links over 711 docs; the join the same shape (192
    methods ran, 58.3% of declared pairs).  `AtlasStaple` and `ElectrodeStaple` still green.

**The Book gates the CONCEPT, not just the code**, which is the part worth keeping: three of its seven
 sentences are about the layer rather than any verb — a reader answers over a census it does not own; a
  reader with no census *refuses by name* (the exhaustive-named-exits law, `Fallen_out_of_mind §2.9`); and
   **a reader keeps nothing** — after every answer its own world holds only its report row.  That last one
    is the erosion alarm: the day someone caches an index in here, it reds.

**Four recordings' worth of lessons went into the Book's own comments** and they generalise to any Book
 written against a ghost that looks its subject up rather than being handed it:
1. **Stand where the reader looks.**  `AtlasStaple` can stand its subject anywhere because it *hands*
    Atlas the world; Lagoon looks its census up by name on the top House, so a Book that stands one
     elsewhere is not testing it at all.  The first recording swore happily against a command-line-stood
      census over the real 711-doc corpus.
2. **Gate on the truth, not on a beat.**  A synchronous beat that neither awaits nor holds anything is not
    guaranteed the tick you think it is; a claim gated on a flag such a beat sets can silently never be
     made, with every step green.  An `expecting` beat is different — its ttlilt holds the step open — so
      a marker *it* sets is a sound gate.  That is why the census claims here gate on a snapped
       `%aimed:fixture` row.
3. **Environment must not decide which step a sentence lands on.**  Whether a census happened to be
    standing changed the latch step, which would red the fixture on someone else's runner.
4. **Drive the pass, do not wait for a tick** (`Atlantation.g` beat 3's lesson, doubled): both censuses
    stand on the top House, whose belief loop a Story run does not pump.

**Still owed on this front:** a sabotage proof (break a reader, confirm the named gap), and deleting
 `Lagoon_resolve`'s duplicate constants if a third reader ever wants them.

*(The plan as written before it was done, kept because the reasoning is the durable part.)*  Five answers
 lived inside censuses and belonged here — `Atlas_callers`, `Atlas_lint`, `Atlas_resolve`,
  `Atlas_unproven`, and `Electrode_join`.  The cheapest possible first cut, because it invents nothing and
   makes the boundary real before a surface exists to blur it again.

`Atlas_unproven` is the one that proves the rule: it is not even a question *about* the census, it opened
 `wormhole/Story/**/*.snap` off disk — a second source and a second concern inside a code index, mitigated
  by an opt-in flag instead of being given a home.  After the move Atlas is 12 functions of pure census and
   the reader ghost owns every answer.

**Front 2 — the coverage map** (`Wordland_todo §1.3` story 3, the owner: *"yes! this is important new
 ground"*).  Shade every def a run entered; leave the untouched pale.  The join already computes it; what
  is missing is a surface and a union across Books.  This is the front the owner marked as the important
   one, so it leads once front 1 clears.

**Front 3 — doc rot as a WORK QUEUE, not a marker** (story 2, the owner: *"having higher level pointers
 or sending you around fixing|obsoleting things is the way"*).  So the lint's output is not a struck-
  through link in a margin.  It is a routed list: *this doc points at something that no longer exists —
   fix the pointer, or mark the doc obsolete.*  A rotted link is a small piece of work with a location,
    and the environment's job is to send someone to it.  1,782 file links are held right now, and the
     misses are already named.

**Front 4 — stacks of attention** (story 5, the owner: *"indeed, stacks of attention and stuff"*).  Note
 the plural: not one focus restored, a *stack* of them.  `%Interest` is the existing machinery
  (`Interest.md` — stances, the foreground rule, per-Waft cursor memory off the Keep) and it already has
   multi-giver arbitration with exactly one Trail bearing the LE.  A stack is that, kept.  **Read
    `Interest.md` before writing a line of this**; an explorer that invents its own notion of "what am I
     looking at and why" is the third design of a live thing.

**Downgraded by the owner:** story 4, *where is this claim proven*.  *"don't really care about this…
 pointers from the spec to the test assertion, sure."*  So: keep the spec→assertion pointer as a link
  kind; drop the unproven-census as a feature.  `Atlas_unproven` still MOVES here (front 1) — it is
   homeless either way — but it stops being a headline.

## 1. The recipe — a source part, wind-back-able

*The owner, 2026-09-08:* **"I think there should be a source part of the whole recipe for what we're
 building.  The recipe stays focused on the tip of itself, but is a wind-back-able thing, of all your
  moments… probably a linear bit and then a spiral off into infinity, so a hole we can pull open."**

Read plainly: the thing being built should carry the record of its own construction, and that record has
 a shape — a **tip** (what is live now), a **linear stretch** behind it (recent moments, legible in
  order), and then a **spiral** that curls away compressing indefinitely, which is not lost but *closed*,
   and can be pulled open like a hole when you need to descend into it.

**This is what `*_todo.md` is already reaching for and failing to be.**  The convention has the tip (`§0`,
 what to get on with next), a linear body, and a spiral (`spec/history/`) — but the three are held
  together by discipline rather than structure, so the linear part silts up, the spiral is a directory you
   must know to look in, and there is no pulling open: `history/` is a wall, not a hole.  The owner's
    complaint about handovers is the same complaint: *"a handover that's a changelog is the weakest, most
     disposable part; the load-bearing part is destination + the knowledge that detonates the bomb + the
      next move."*  The tip is load-bearing; the linear stretch is context; the spiral is everything that
       is true but no longer in the way.

**Why it belongs in Lagoon rather than in a style guide.**  Atlas already holds every doc as a particle
 with its headings, its links and its dige, and Lagoon is the thing that reads them.  A recipe with a
  tip, a linear stretch and a pull-open spiral is *a rendering of a doc*, not a new file format.  Nothing
   needs to be re-authored: the tip is `§0`, the linear stretch is the sections that still resolve against
    live code, and the spiral is everything whose links point into `history/` or into files that no longer
     exist.  **Lagoon can compute the fold from what Atlas already holds.**  That is the cheapest possible
      version of this idea and it needs no new discipline from a human.

**Adjacent prior art, honestly distinguished** (do not let these merge):
- **`ulative/memory-raw/yore-moment-spool.md`** (2026-07-19) is a spool of *world-state* moments — Cyto's
   glass, a Story-like scrubber, display-only time travel over `enWaft` diffs.  Same verb (wind back),
    different subject: that one winds back the RUNNING WORLD, this one winds back the RECORD OF THE WORK.
     They will want to look alike and should not be built as one thing.
- **`Whitehole_todo §3`** already owns a hole-shaped cosmology (a white hole is emit-only, the boot, never
   re-entered).  The owner's *"a hole we can pull open"* is the opposite direction — a hole you descend
    INTO — so the words rhyme and the concepts do not.  Flagged so nobody welds them.

**Open, and genuinely so:** what a "moment" is here.  A commit is too coarse and too rare; a session is
 unbounded; a doc edit is too fine.  The most promising unit is the one this machine already mints for
  everything else — *a claim and the evidence for it* — which would make the recipe's linear stretch a
   sequence of things that became true, each with the run that proved it.  Not decided.

## 2. The concept line it must not cross

From `Wordland_todo §1.1`, restated because this doc is the thing most likely to break it:

**Atlas KEEPS; Lagoon ASKS.**  The test for any addition: *does this change what is HELD, or ask a
 question OF what is held?*  Atlas already drifted to 12 keeping / 4 asking one convenience at a time,
  because no single addition was wrong.  Lagoon exists so that the answer to "where does this go?" is
   boring and permanent.

Its own version of the same trap, worth naming before it happens: **Lagoon must not start keeping.**  If
 a reader wants a cache, the cache is a derivation it can throw away and rebuild, never a second census.
  The moment Lagoon holds something Atlas cannot recompute, there are two truths.

## 2.5 THE AFTERNOON'S THREE BUGS — all found by the owner looking at their own tab

*Worth keeping together, because each is a different kind of mistake and only one was in the code I set
 out to write.*

### (a) Atlas was hogging the beliefs mutex, on the owner's EDITOR tab

**Symptom the owner reported:** a dozen `story_sel` clicks sitting undrained in `H.todo`, oldest 470s,
 *"not sure why it's not processing them, it's only the H%Run we want to pause hard."*

**It was not a pause.  It was a hog, and the machine's own electrode said so** — `runner_ask world` on
 that tab: `drain-lag … why=beliefs mutex held 4s by H:Mundo think Atlas/Atlas`, repeatedly.  EVERY House
  drains under the top House's single beliefs mutex (`Housing.svelte.ts:230`), so a pass that parses six
   files without yielding freezes the whole tab for as long as that takes, and every human click queues
    behind it.  `Atlas_pass` is a `%req` do_fn, so all of its `await`s run *inside* the mutex.

**Two unbounded holds, two fixes, both measured:**
- **`ATLAS_SLICE_MS = 120`** — the map/adopt loop now exits on a TIME bound rather than only a count.  A
   count was always the wrong bound: `Atlas_map_one` measured 50–194ms per doc, a 40× spread.
- **A RESUMABLE ROSTER** — the first pass used to walk every root (715 docs) in one go and return before
   ever reaching the slice check.  Chunking per ROOT was tried first and was *not enough*: `src` alone is
    most of the corpus, so a fresh stand still froze the tab for six seconds.  The frontier is now a QUEUE
     OF DIRECTORIES on `w.c.walk_q`, drained for one slice per pass, via a new non-recursive
      `Atlas_walk_one`.  **`Atlas_walk` itself is untouched**, because `Atlas_refresh` needs a COMPLETE
       walk to compute `gone` from its `seen` set — a half-finished refresh would drop live docs.  Only
        the roster, which has no such contract, may stop halfway.

| | worst mutex hold | worst wait a click feels |
|---|---|---|
| before | 4s, and 6s on a fresh stand | 2,553ms |
| after the time slice | ~1s | ~450ms |
| after the resumable roster | **no drain-lag mark at all** | — |

A fresh stand plus a full re-converge to 715/715 now produces **no lag marks whatever**, where the
 electrode reports anything past a healthy few tens of ms.  *Caveat, stated because it matters:* that
  re-converge was Dexie-warm, so it adopted more than it parsed — the ROSTER half is demonstrated, the
   worst-case parse half rests on the time slice.  **The real end state is still the pass running OFF the
    mutex**, which is what `expecting()` is for — parked because a standing `expecting` on Mundo arms a
     ttlilt and ttlilts extend Story's quiesce (`world` shows `ttlilt=382` inside a Book run), so it wants
      care rather than a quick edit.

**And the deeper mistake was mine before any of that: Atlas should never have been on that tab.**  Its own
 header says *"WHERE IT RUNS: a runner with FSA — spare capacity (nobody typing) … Never the editor (it
  must not ride the spine it is editing)"*.  My `runner_ask` calls were UNPINNED, so they landed on
   whichever tab acked first — the documented hazard in the `two-runners-pin-with-runner-flag` memory,
    walked straight into.  **Pin `--runner=` for anything that stands a world.**

### (b) "Lagoon seems like it has nothing in it" — the Books leave the census aimed at a fixture

`AtlasStaple` and `LagoonStaple` both re-aim `A:Atlas` at `Ghost/L/test_corpus` (one file, three defs) and
 **do not put it back**.  So after any Book run the face is honestly reporting a one-document census.  The
  owner read that as the face being empty; it was the fixture showing through.
 **Owed:** either the Books restore the previous roots, or the face says out loud *"aimed at a fixture
  corpus (1 doc)"* rather than quietly showing three methods.  The second is better — a surface that hides
   which world it is looking at will mislead again.

### (c) `div.usb-panel` covering the editor's scrollbar

The searchbar's dropdown was `right: 0`, so while a search was open it sat over the scrollbar underneath
 and you could not grab it.  Now `right: 1.1rem`; the panel is left-anchored to the input, so a gutter
  costs it nothing.

### A flake worth naming, not hiding

`LagoonStaple` measured over **11 runs: 9 green, 2 at `ok_pct:0.83, caveat:1`.**  Assertions were 7/7 with
 0 gaps in EVERY run, so no claim was ever lost — a step snap caught a different tick.  **Both flakes were
  the run immediately after a fresh Atlas stand**, i.e. with 715 docs converging in the background; the
   nine steady-state runs were green.  So the flake is contention, which is the very thing §2.5(a) fixes,
    and it should now be rarer.  **It is not yet a clean gate** — if it recurs in a quiet tab, that is a
     different bug and worth chasing properly.  *(It was.  §1.6.)*

## 1.6 THE FLAKE, CHASED PROPERLY — and two lessons that outlive this Book

**Reproduced on the first try** (`ghost_load` the three L ghosts, then run): `ok_pct:0.83, caveat:1`, with
 **step 5 a hard fail and step 6 a caveat**.  Then green twice more.  So it is not contention in general —
  it is what a COLD census costs, and it cost it in two different currencies.

**One root: a step that takes one more belief round than the recording did.**  Everything else follows.

**Symptom A — the hard fail — a frozen MOMENT in a fixture.**  Beat 5 (`refuse`) ran inside an
 `expecting`, and `005.snap` had recorded `req:refuse_wait` **still in flight, ttlilt armed**.  Whether a
  beat is still in flight when Story snaps its step is a coin-flip against how long its async work takes;
   on the cold run the beat settled first and step 5 snapped `refuse_wait,finished` instead.  **No spay
    forgives a missing line**, so a timing difference presented as a structural fail.
 The fix was to notice the async work was never needed: every part of the refusal is synchronous, and the
  only `await` was a re-map of the census that **nothing downstream reads** (beat 6 reads the Lagoon
   world).  Beat 5 is now a plain synchronous beat, exactly like beat 4's lint.
 **The general rule: a fixture must not encode a DURATION.**  If a step's snap differs depending on
  whether a beat has finished, that snap is a stopwatch, and it will read differently on a slower box.
   Either the beat holds the step open until it settles (and snaps settled) or it is synchronous (and
    snaps done) — never a race between the two.

**Symptom B — the caveat — `self,round` is a clock.**  `round` is already spayed by a hardcoded Story
 rule (`Story.svelte` ~:1096), and **a spay CREATES a caveat**; only an encode-time `drop` mutes one.  So
  one extra round anywhere upstream shifted every later step's `round` and stamped a caveat on each.  A
   test-scoped `Entcase:Self_round → means,drop` in the Book's own toc omits the line outright.
 A side effect worth seeing rather than hiding: **steps 2–6 now share one dige.**  That is honest — the
  world genuinely does not change shape between those steps, and what used to distinguish them was a
   clock and one transient req, neither of which was ever signal.  **The gate here is the sworn contract,
    and the snaps are furniture that proves nothing was minted.**

**Symptom C, found while fixing the others — a sworn sentence latches at whatever step it first becomes
 true at.**  A sworn sentence is DECLARED in the toc under its latch step, so if the same truth latches
  one step earlier or later, the declared `%Assertion` is absent from its step and **the run reds by name
   with no bug behind it**.  `a reader answers over a census` was true the tick beat 2's stand settled, so
    it declared at step 2 and would have moved to step 3 the moment the stand cost one round more.
 The fix is a **step floor**: `LagoonStaple_at(w, n)` — swear on truth **and** not before the step whose
  desc the sentence belongs to.  This is not the "gate on a beat" mistake the Book's header warns about:
   the floor never SUBSTITUTES for the truth check, it only refuses to swear early, and a fact that
    arrives late still latches because the witness runs every tick.
 The toc reads better for it — every `%Assertion` now sits under the step that describes it.

**Measured after the fix: 7 consecutive green, `caveat:0`,** including one run immediately after
 `ghost_load Ghost/L/Atlas.g --stand=Atlas --fresh` over the real 715-doc corpus — the exact trigger.

### The Book grew to eight beats, and the gate refused a wrong premise

Later the same night the seek (§1.8) and the beadchain (leg 4) went in as beats **5** and **6**, pushing
 the refusal to 7 and keeps-nothing to 8.  **They sit there on purpose**: beat 8's claim is that the
  reader's world holds only its report row *after every answer*, so every verb exercised above it makes
   that claim stronger.  A new reader verb belongs above beat 8 for exactly that reason.

**And the gate immediately caught me guessing.**  The beadchain beat first swore that `Sample.g` has
 ZERO beads — written without reading the fixture — and it simply did not latch, with every step green.
  `Sample.g` declares one region *on purpose* ("exercises the region kind too", its own comment), holding
   two of its three defs.  The real fixture is **better than the assertion I invented**: it tests
    attribution in both directions in one doc — the two inside are attributed to the bead their author
     drew, the third is left outside rather than annexed.  That is the whole property of a shape reader.
**10 sworn, 10 declared, 0 gaps; five consecutive green at `caveat:0`.**

**Then reading the recorded fixtures showed the snap half of the gate was proving nothing.**  Steps 2–8
 were BYTE-IDENTICAL — every beat put its result on `.c`, which does not snap, so the sworn contract was
  carrying the whole Book and seven fixtures were redundant bytes.  CLAUDE.md calls the snap-fixture diff
   *"the place to notice un-asserted detail"*; there was no detail to notice.
Each beat now leaves a **`saw` row** — clean scalar strings, deterministic against the frozen corpus —
 so a step's snap says what its beat FOUND and a change in an answer's shape shows as a diff rather than
  only as a sentence that stopped latching:

    saw:lint,docs:1
    saw:seek,defs:3,atlas:1,fixture_only
    saw:beads,beads:1,defs:3,inside:2,loose:1
    saw:refuse,callers,lint
    saw:kept,others:0

Distinct fixture contents went **2 → 7 of 8**, and the beads row now carries in DATA the very fact I got
 wrong by guessing (one bead, two defs inside it, one beyond).  Three consecutive green after re-record.

### The sabotage proof — the gate was made to fail on purpose

A green gate that has never been seen red is a decoration.  Two of Lagoon's concept laws were broken in
 `Lagoon_callers` at once — `return []` instead of the named error (the silent-empty law), and a
  `w.oai({Index: name})` cache (the keeps-nothing law) — then compiled, hot-swapped and run:

    ✗ «a-reader-with-no»      step 5 — ABSENT: a reader with no census refuses by name …
    ✗ «the-reader-kept-nothing» step 6 — ABSENT: the reader kept nothing …
    ✓ «every-reader-refuses-the» step 5 — sworn

**Two named gaps, and the third refusal sentence stayed green** — the one driven by `Lagoon_lint`, which
 the sabotage did not touch.  So the reds are specific to the law broken, not a blanket collapse; the
  Book can tell WHICH law went.  Reverted, recompiled, re-run: green.  *(The sabotage patch is not on
   disk — it was two lines, and it is written out above so it can be repeated in a minute.)*

## 1.7 THE LINK LANGUAGE GREW — `sect`, `book`, `sworn`, and one lesson learned four times

**Built 2026-09-08 night (`ATLAS_MAPPER` m15).  Gate: `scripts/LinkKinds.spec.ts`, 7/7, no runner and no
 browser** — a collector is a pure function of text, so it wants a spec, not a Book (the same reasoning
  that put `role:hacker` in `HackerRole.spec.ts`).

### The plan proposed `Doc#region`.  The corpus said §.

The leg as written listed `a region (Atlas.g#the cache)` among the kinds to add.  **Measuring the corpus
 before choosing the form killed that idea in one command**: `Doc#region` appears **twice** in `spec/`.
  `§N.N` appears **3,270 times**, and not one of them was collected.

    §                3,270   ← the corpus's actual cross-reference, uncollected until tonight
    `code`           8,967   (m14 — bigger in raw count, but it fires on every backticked symbol)
    file:line        1,569
    [[wiki]]           175
    Book:               18
    «sworn»              4

**This is the `code` insight a second time, and it should now be the DEFAULT MOVE: most of the link
 language is already written, and the job is to notice which form people actually type — not to invent a
  form and hope it catches on.**  A kind invented from the plan costs the same to build and collects
   nothing.

### The three kinds, and what each refuses

- **`sect`** — `<Doc> §N.N`, or a bare `§N.N`.  **470 doc-qualified across 113 target docs; 2,800 bare.**
- **`book`** — `Book:<Name>` / `Book=<Name>` only.  18 live.  The bare prose form (`Book LakeSurprise`,
   71 live) is **deliberately not collected**: it cannot be told from a sentence that happens to name
    something after the word "Book".
- **`sworn`** — `«assertion-slug»`, the spec→test-assertion pointer the owner kept from story 4.  4 live.
   The guillemets are not invented: they are what `runner_ask assertions` already prints, so an author
    pastes a line of CLI output and has a link.  Filtered to the slug shape, so the corpus's prose
     placeholders (`«slug»`, `«X»`, `«uncoupled»`) are left alone.
- **`anchor`** — *not a link*: the thing a § LANDS on when it is not a heading.  See below.

### Four corrections, each found by measuring rather than by reading the code

**Every one of them was the same mistake in a different coat, and each was caught BEFORE publishing.**
 That is the difference from m14's `prose_rot`, which over-claimed twice in public.

1. **The backtick between the name and the §.**  This corpus code-spans doc names, so
    `` `Voro_render_todo.md` §0 `` has a backtick sitting where the regex wanted a space.  Requiring a
     bare space demoted **189 of 470** doc-qualified links (40%) to bare ones.  *The single largest
      correctness win in the pass, and it was one character of regex.*
2. **Doc names without an underscore.**  `Frontier.md §1`, `Interest.md §2` — the older single-word docs.
    Requiring the house-style underscore silently linted the WRONG document, which is worse than a miss.
3. **Numbered items that are not headings.**  The corpus writes `**7.4 Per-peer fairness: OUT OF SCOPE.
    RULED.**` inside a section and then points § at it.  A heading-only index calls those rot: counting
     them turned **2 of 10** cross-doc "dead" links and **78** self-references back into live ones.  Hence
      the `anchor` row — kept separate from the heading tree, which carries depth and `region_path`.
4. **The `_todo` suffix the corpus drops.**  Prose cites `Social_demarcation §7`, `Radio_circuit §0.5`,
    `Vyto_sizing §8` — all real docs under their full `X_todo.md` names.  A tail-exact resolver reported
     **38** missing docs; with a `_todo`/`_spec` fallback, **16**.

### The ruling that matters most: a bare § is COUNTED, NEVER ACCUSED

The obvious reading is that `see §9` means *this* doc's §9.  Linting them that way produced **454 dead
 self-references** — and sampling killed the reading.  `Seemables_todo` has 38 bare §s and numbers
  nothing but its own §0, because its §s point into whatever doc the sentence just named: *"That work
   lives in `Voro_render_todo.md` §0"*.
**A bare § has an ambiguous referent that only prose resolves, so the lint says nothing about it.**  It
 is collected (it is a real reference) and counted, and the report says why it is not judged.

### What the § lint actually finds — the honest number

    § 3,270 over 133 docs — 470 doc-qualified, 2,800 bare (not linted)
      LIVE DOC, DEAD ANCHOR : 13     ← the new signal
      moved to history/     :  5     ← expected: CLAUDE.md's own corollary
      nothing has that doc  : 16

**Thirteen.**  Small enough to read, which is the point: after four corrections it is a list a human can
 act on rather than a wall to ignore.  Three were checked by hand and all three were real —
  `Backpressure_todo §3.7` (the doc goes 3.1…3.4 then 4), `Cello_todo §4` (Cello_todo numbers nothing past
   §0), `Heist_todo §0.2` (no such anchor anywhere in it).  **This list is leg 3's seed work queue.**

*And a wrinkle leg 3 has to answer, found immediately: quoting those three as evidence in this section
 made THIS doc report three dead pointers.  A lint cannot tell a citation from a claim, so a work queue
  needs a way to say "cited deliberately" — the routing question, not a regex question.*

### `Lagoon_oaths` had never been RUN, and it threw on the first call

Written, wired, documented, gated by nothing — and its first ever invocation returned **`nav is not
 defined`**.  The `atlas_*` op above declares its own `const nav` inside an else-branch, so the name
  simply did not exist in the `lagoon` block.  *A verb nobody has executed is an unverified claim,
   however carefully it was written* — worth a standing habit: run each new verb once, immediately.
Working, it gives the spec→assertion pointer the owner asked for:

    oaths: 167 toc(s) over 168 Book(s), 250 declared assertion(s)
           Book: links 9 (3 gone) · «sworn» links 4 (4 land, 0 gone)

**One of those four was written before the kind existed** — `Seen_split_todo.md:159 «a-re-stood-atlas-
 warms» → Book:AtlasStaple`, authored by somebody using guillemets as prose.  Collecting the form the
  corpus already typed found a real link nobody had to write, which is §1.7's whole argument, confirmed.

**And 2 of the 3 "gone" Book links were a GLOB** — `` `Book:Voro*` `` means *every* Voro Book, and the
 regex captured `Voro` from it.  **Every link form in this corpus has a pattern-or-placeholder variant**
  (`«slug»`, `the §3`, bare `Name.ext`, backticked words without an underscore, and now `Name*`): assume
   the next one does too.  The lookahead has to forbid a following name character as well as the `*`, or
    the regex just backtracks to `Vor` — worse than the bug.  Gated; corpus `book` links 6 → 4.

### A latent silent-loss bug in the collector, closed before it ever bit

Fenced blocks are skipped so a doc *showing* what a link looks like is not *making* one — but the skip
 is a stateful toggle, and **one unbalanced fence would have swallowed every link below it, with no
  error anywhere**.  Measured across `spec/`: 0 of 391 docs are unbalanced today, which is luck rather
   than safety, and silent loss is precisely what this layer exists to refuse.
So the sweep **counts fences first, and collects the whole document when the fencing does not balance** —
 trading silent under-collection for over-collection, which is harmless here because resolution is the
  reader's and an unresolvable target is a mention, not rot.  Gated in `LinkKinds` and sabotage-proven:
   forcing the old always-toggle behaviour reds exactly that one test.

### The resolution rules now have a gate of their own — `scripts/SectResolve.spec.ts`, 8/8

`LinkKinds` gates the COLLECTOR (what `compile.ts` emits from a document's text).  Nothing gated the
 READER (what `Lagoon_lint` concludes from what Atlas holds) — and **that is the half that was got wrong
  five times in one night**: the backtick, the underscore-less doc name, the non-heading anchor, the
   dropped `_todo` suffix, and the `history/` skip the § pass did not inherit.  Five near-misses, every
    one caught by measuring rather than by reading, and nothing protecting any of them afterwards.
**It uses hand-made particles, not the corpus, and that is the point.**  A census built in the test is
 exact and cannot drift; a corpus-derived expectation moves every time somebody writes a doc.
  `LinkKinds`'s corpus sweep is a floor on a RATIO; this asserts a RULE.
It runs headless by mounting the generated `gen/L/Lagoon.go` directly — its `onMount` eatfunc deposits
 the verbs onto the House, which is the same thing `Lies_ghost_set` does in a browser.
**Sabotage-proven**: removing the `history/` skip and the `_todo` fallback reds exactly the two tests
 that name them and leaves the others green.  A gate that has only ever been green is a decoration.

**It also gates `face_on`** — the fix for the owner's own reported bug, and the last thing written that
 night which had never been EXECUTED.  (An hour earlier that same question turned up `Lagoon_oaths`
  throwing on its first call, so it was worth asking twice.)  Two tests: the face mounts where the ROOM
   names, and with no room it falls back to where it always went — so a CLI-stood reader on a bare
    runner cannot lose its face.  Sabotaged by forcing `home = this`: the room test reds, the fallback
     stays green, which is what proves the two paths are actually distinct.

### THE HABIT THIS NIGHT ARGUES FOR

Nine defects, and **not one came from re-reading source**.  They came from three questions, in
 descending order of yield: *what does the output actually say?* (the 0-line files, the arbitrary index,
  the retired-vs-gone split) · *what have I written that has never been RUN?* (`oaths` threw; `face_on`
   was fine but unknown) · *what does my newest code do on input the corpus does not happen to contain?*
    (the unbalanced fence, the `Book:Voro*` glob).  Ask them in that order on anything built here.

### Where it is wired

`compile.ts`'s markdown sweep (three regexes + the anchor line-test) · `ATLAS_MAPPER` m14→**m15**, so
 every cached row re-derives · `Lagoon_lint` gained the § pass and `Lagoon_sections` · new async
  `Lagoon_oaths(w, nav)` resolves `book` and `sworn` against the Books themselves (one toc read per Book,
   ~80, versus `Lagoon_unproven`'s ~1000 snap reads) · `runner_ask lagoon oaths`, and `lagoon lint` now
    prints a report rather than a JSON wall.

### ✅ SEEN LIVE, 2026-09-09, over a converged 724-doc census

    724 docs · file:line 1,944 (14 missing, 2 past EOF)
      § 3,873 — 669 doc-qualified (37 no such doc, 30 no such section), 3,204 bare (not linted)
      orphan defs 2,042

The whole corpus, not just `spec/`, so the counts are larger than the headless measurement above and
 agree with it in shape.  **`past EOF` is the number to look at: 275 → 2.**  That is the convergence-
  artifact fix (leg 3's entry in §0) validated at full scale — the old lint was calling hundreds of
   perfectly good links rot because it compared against an unmapped doc's length of zero.  Two genuine
    line drifts in 1,944 links is a believable answer; 275 never was.

## 1.8 ONE ANSWER, MANY FACES — the seek, and the room stopped having two of everything

**Built 2026-09-09, from four remarks the owner made in one night.**  They read as four small complaints
 and they are one:

- *"there's the `search — ƒ methods · % props` searchbar, which is kinda annoying"*
- *"every search result should probably be 80% of the screen real estate, as usual"*
- *"UI:Lagoon appears to come out in H:Mundo but shouldn't… I can see H:Hackarium's UI:Langui there but
   not UI:Lagoon"*
- *"unify it beautifully with the current effort as well" … "you'll have to figure out what I mean."*

### What was actually wrong, and it was not the placeholder

**The room had TWO seek machines.**  The Searchbar over the Stemdex (ƒ methods · % props · ≈ text) and
 Lagui over Atlas (families, defs, callers, mentions).  Two inputs, two hit lists, two glyph
  vocabularies, mounted on two different Houses — and **both ending in the same act**,
   `Lies_ghost_pick{path, point}`.

A person typing `Heist_keep` does not care which index answers.  That placeholder was **one index
 announcing its own taxonomy at the seeker**, which is exactly why it read as annoying: it asks you to
  know how the machine is built before you can ask it anything.

### The unification is not one face.  It is one ANSWER.

**`Lagoon_seek` is the whole move**, and it is this session's own law applied one level up.  The Stemdex
 is a **census** — it keeps every name and every line of freetext the machine has read, kept fresh by a
  polite scan.  It was never treated as one only because it happened to arrive with a face attached.  So
   it is now looked up by name on the top House and never held, exactly like Atlas and Electrode
    (`Lagoon_lies()`), and one verb asks over both.

> **ATLAS KEEPS.  THE STEMDEX KEEPS.  LAGOON ASKS.**
> Two faces on one answer is fine.  Two answers behind two faces is the globulation.

The reply carries the readings in **the seeker's order, not the indexes' order**:

| reading | from | when |
|---|---|---|
| **families** — the larger objects | Atlas | the query is under two characters.  *"I can't remember a method name to look up"* is the commonest way a seek starts, so the answer to an empty box is the **map**, not an empty list |
| **ƒ defs** | Atlas ▸ Stemdex | always.  Atlas is authoritative (real `doc:line`); the Stemdex's own defs merge under it, so a missing census **degrades** the answer instead of emptying it |
| **¶ mentions** — the prose that names it | Atlas | only once the query resolves to a real def.  A backticked phrase that names nothing is a phrase, not a link — the m14 lesson, held |
| **% props · ≈ text** | Stemdex | always |
| **← callers** | Atlas, on demand | not in the reply at all: a reverse lookup over 724 docs per keystroke would be a second index in all but name.  Nothing is asked until you climb, nothing kept after |

**Ranking moved into the answer.**  Both surfaces used to sort by name or by path, which buries an exact
 hit under thirty substring ones.  The seek ranks exact ▸ prefix ▸ substring; the faces only order the
  *readings*.  A face that re-sorts throws the answer's own judgement away.

**And it names which censuses replied** — the silent-empty law one layer up.  With Atlas down you get
 the Stemdex readings and `atlas:0`, and the header says so.  A refinement found by running it: a runner
  tab HAS a `w:Lies` but never mounts a searchbar, so its Stemdex is standing and **empty** — which must
   not read the same as "answered".  *Standing is not the same as answering.*

### What the two faces became

- **The Searchbar is the handle.**  `/` still summons it, the input now says `search  ( / )` and nothing
   else — the glyph legend moved into the panel, beside the glyph column it decodes, which is the only
    place a legend is worth reading.  Its panel is a **surface**: `fixed`, measured off the input,
     `min(1180px, …)` wide and `min(80vh, …)` tall, with a sticky header, sticky kind breaks, a
      click-off backdrop, and a 24→200 result cap because a screenful can use them.  **A ƒ row climbs**:
       a caret erupts its callers under it, indented, same idiom and same rail colour as Lagui's.
- **Lagui is now genuinely the second rendering**, not just described as one.  It asked `Lagoon_defs`;
   it asks `Lagoon_seek`, and for that one changed call it gained everything the bar has — ranked defs
    (each carrying the **bead** its author drew it inside), the prose that names a symbol, and a whole
     document's beadchain under `doc:`.  **One reading stayed its own ask, and deliberately**: families
      do not depend on the query, so recomputing them per keystroke would be waste and caching them
       inside Lagoon would be *keeping*.  A face asking two questions at two cadences is right; two
        faces asking the same question two ways was the thing that was wrong.

### The `H:Mundo` split, which was a real conflation and not cosmetic

`Run_A_Hackarium` mints `A:Lies`/`A:Lang` on the **Hackarium sub-House**, so `UI:Langui` enrolls there.
 But the recipe stands the land with `top.oai({A:'Lagoon'})` — on **Mundo**, and it must: `Lagoon_atlas()`
  looks the census up on the top House by name, so do every `lagoon`/`atlas_*` CLI op and `LagoonStaple`
   ("stand where the reader looks", §1.6's neighbour).  So the face followed the census onto Mundo, and
    in a room that shows one House's UIs at a time **the face was on another page**.
**Where a census stands and where its face mounts are two questions.**  A room may now name itself as the
 face's home — `w.c.face_on`, a runtime House ref set by whoever stands the world — and `Lagoon_plan`
  mounts there, falling back to `this` when there is no room.  `UI:Lagoon` lands beside `UI:Langui`.

**Verified live** on a fresh 724-doc census: substring (`Heist_keep` → 12 ranked defs), exact (`Repli_serve_chunks`
 → 1 def + 12 prose mentions), empty (40 families), and the verb finds itself (`Lagoon_seek` →
  `Ghost/L/Lagoon.g:146`).  All three touched components svelte-compile with zero warnings.
**Owed, and it needs a browser:** the panel at 80vh has not been *looked at*.

## 2.7 THE SEEK NEEDS SOMEWHERE TO LAND — and `role:hacker` is the way

*The owner, 2026-09-08: "I definitely need an editor to go with this 'seek here' situation" … "by an
 editor I meant a Langui, a codemirror that takes me to all these Points the Lagoon walks" … "there's
  only allowed to be one editor for some thing iirc… it's Lies that makes it so… so we should avoid being
   that kind of editor? role:hacker for now?"*

**The owner's memory is correct, and it kills the obvious answer.**  I had suggested opening
 `/Otro?E=Educarium` beside their runner, because an Otro editor is not a humdinger and so would accept
  `ghost_load`.  **That would have evicted them from their own editor slot.**  The rule is enforced in two
   places and is not advisory:
- `LiesFunk` (~:499): *"the editor that is claiming supersedes every other editor row: the one editor is
   whoever is here now."*  A second editor tab takes over the `%HostedIdentity` directory.
- `Lies_aim_setup` returns immediately unless `Lies_role(w) === 'editor'` — the %Aim/Cluster endpoint
   targeting is the one editor's job, and `LiesFunk:423` says why: *"single-control-point state belongs to
    the one editor."*  Plus the relay itself: *"one editor per relay"*, fanning every runner→editor frame
     to the one editor socket.

**And their runner tab cannot host a Langui either**, which is the other half of why the seek lands
 nowhere: it has no `A:Lang` at all (`minisnap mundo` gives `A:Lies` with `w:Lies,runner,creduler` and no
  Lang), and `e_Lies_ghost_pick` already knows — *"a runner (no editor) has no Trail strip to foreground —
   no-op, don't throw"*.  So a click records a trail into today's Aside and shows you nothing.

### Why `role:hacker` is the right shape, and cheaper than it sounds

A hacker tab wants the editor's **local capabilities** (A:Lang, Langui, docks, FSA read, `ghost_load`) and
 none of its **singular duties** (the Cluster claim, %Aim, the relay's editor socket, Waft saves).

**The elegance is that the duty gates are EQUALITY tests.**  Every one of them reads
 `Lies_role(w) === 'editor'` or `Lies_is_editor(w)`, so a third role opts out of all of them *for free* —
  nothing needs a new condition, and nothing can forget to exclude a hacker.

**The audit** — every editor gate in the tree, classified:

| | sites | what a hacker does |
|---|---|---|
| **duties** — Cluster claim, `Lies_aim_setup`, relay editor handling (`LiesLies:1526/1586/1654`) | ~6 | **opts out free** (equality test) |
| **capabilities** — Keep focus + resume (`Lies.svelte:233/1013/1018`), the editor-local branches (`LiesLies:573/606/650/970`) | ~7 | **must be re-pointed** to `editor || hacker` |
| **writes** — `Lies_waft_save` (`Lies.svelte:833`), compile `dock_source` (`LangCompiling:274`, `LiesCortex:155`) | 3 | **stays editor-only** — a hacker READS |
| **cosmetic / boot** — `BootGate` labels, `MountNav:53` disk gating, `Housing:2356` | 3 | follow `boot_role`, unchanged |

So: `role: 'hacker'` → `boot_role: 'editor'` (the machine stays two-valued, as `BigQualand` insists, so
 the world layout and disk gating are inherited) but `H.c.role = 'hacker'` so `Lies_role` returns
  `'hacker'` and every duty gate misses.  Then re-point the ~7 capability gates to a new predicate —
   `Lies_has_docks(w)` = editor or hacker — which is the honest name for what they were really asking.

**The one genuinely unclear bit, flagged rather than guessed:** six sites read
 `peer = role === 'editor' ? 'runner' : 'editor'`.  With `role:'hacker'` the peer becomes `'editor'`, so a
  hacker would look for an editor peer on the channel.  For a local read-only wanderer that is probably
   harmless and possibly even right, but it is the one place where a third role meets a two-valued
    assumption, and it wants a look rather than a shrug.

**Not built** — a new role in the cluster's role vocabulary is the owner's to rule, and this one touches
 the relay.  The design above is complete enough to build in an afternoon once it is.

## 2.8 THREE MORE WANTS, HELD — the beadchain, the link language, and the portal

*Recorded 2026-09-08 in the owner's words, unbuilt, so none of them is re-derived from scratch later.*

### The beadchain — code as beads, not a screed

*"we then also want the code to not be so much of a screed but a beadchain, which could have clusters of
 stuff, compound nodes, etc… perhaps.  it's that world very soon now."*

**Atlas already holds the beads and nobody has drawn them.**  A `//#region` is an author-declared bead
 with a name and a span, and the census keeps `region,label,depth,from,to` for every doc — including the
  *depth*, which is the clustering.  So a beadchain view of a file is: its regions as beads, nested by
   depth, with each region's defs inside it.  No new collection, no new parse; a rendering of held rows.
 **The compound-node vocabulary also exists**, in Cyto: `cytyle_classify` already returns
  `skip|invisible|compound`, and Matstyle styles by mainkey.  So "clusters of stuff, compound nodes" is
   the graph layer's own language pointed at code instead of at a world.
 The honest gap is the same one the plant section names: arrangement.  A chain has an order and a
  chain-of-clusters has a layout, and that is the pose model `Lens_posable` says not to invent yet.  A
   first cut that dodges it: beads in file order, indented by region depth — a chain, not a graph.

### A whole language of links in markdown — ✅ THE THIRD KIND IS BUILT (2026-09-08)

*"we need a whole language of links you can do in markdown."*

**`code` landed the same afternoon** (`ATLAS_MAPPER m14`), and the insight was that most of the language
 is ALREADY WRITTEN — the corpus points at methods in backticks on every page and nobody was collecting
  it.  The filter is the underscore: of 15,160 backticked tokens in `spec/`, the 8,834 containing one are
   almost purely real symbols; the 6,000 without are `sc`, `true`, `ok`.  Live over 715 docs:
    **11,042 code links, 3,025 distinct.**
 **Resolution is the READER's, not the collector's** — `compile.ts` cannot know the corpus, so it emits
  every candidate and Lagoon decides.  That split is the concept line doing real work.
 Two verbs came with it, and a CLI door (`runner_ask lagoon <verb>`):
- **`Lagoon_mentions <name>`** — which docs TALK about a symbol, with lines.  The twin of `callers`:
   between them a method has both neighbourhoods, the code that depends on it and the prose that explains
    it.  `Repli_serve_chunks` → Backpressure_todo, Download_stall_handover, Fallen_out_of_mind.
- **`Lagoon_prose_rot`** — front 3's work queue for symbols.  **It over-claimed TWICE and the fixing is
   the interesting part.**  First cut: 1,343 "unresolved", topped by `body_hash`, `runner_ask`,
    `CREDULER_GHOSTS` — keys, a CLI name, a constant.  A backticked word is not a promise that a def
     exists.  Filtering to the ghost-method shape (`Capitalised_lowercase`) cut it to 254, still topped by
      `Daemon_todo`, `Division_todo` — DOC names, which wear the same shape.  Excluding doc names (Atlas
       holds all 715 paths) gives **179**, and spot-checking the top three found two genuinely gone
        (`Story_next_level`, `Repli_loc_keys`) and one alive.  **The lesson worth keeping: "looks like a
         symbol" and "is a symbol" are different questions, and only the census can tell them apart.**

Before this, the corpus had **two** link kinds and Atlas collected both: `[[wiki-slug]]` (174 live in `spec/`,
 resolving to `spec/ulative/memory-raw/<slug>.md`) and `file.ext:line` (1,783 live).  That is a
  vocabulary of two, and everything else a doc wants to point at has to be spelled out in prose:
- ~~a **method**~~ — ✅ BUILT as the `code` kind, above
- a **family** (the stem-buckets of §the index) — "the Heist family"
- ~~an **assertion / sworn sentence**~~ — ✅ BUILT 2026-09-08 night as `«slug»`, §1.7
- ~~a **Book**~~ — ✅ BUILT as `Book:<Name>`, §1.7.  A **step** of one is still unbuilt
- ~~a **region** (`Atlas.g#the cache`)~~ — ❌ **RULED AGAINST BY THE CORPUS**, §1.7: that form appears
   TWICE, while `§N.N` appears 3,270 times.  Built as the `sect` kind instead
- a **particle shape** (`%Record,total`) — the `%Notation` the Stemdex already tokenises

**Cheap, because the collector is one independent line-sweep** (`compile.ts`, the `WIKI_RE`/`FILE_RE`
 pass): each new kind is a regex plus a `kind:` tag, an `ATLAS_MAPPER` bump, and Lagoon gains a resolver.
  The value is that the lint then covers them — a link to a method that no longer exists rots exactly the
   way a `file:line` does, and §0 front 3's work-queue picks it up.

### The portal — talking to Claude from inside a document

*"we've got to put you in markdown… which I assume there's a… do we just talk to you through a portal or
 something?"*

**The honest mechanics first, because they constrain the design.**  Claude here is a CLI process in a
 container.  The app cannot summon it: there is no inbound door, and `runner_ask` runs the other way
  (the CLI asks the tab).  What the two DO share is the filesystem — the wormhole is the same disk from
   both sides — and a Claude session can watch a file and act on a change.

So the portal that needs no new transport is a **file-shaped mailbox**:
- a link kind, say `[[ask: how does the mutex hold work?]]`, mints a request row in the corpus (a `%Ask`
   under today's Aside, or a `wormhole/Ask/<YMD>/` doc — the Aside is already the trail's home)
- a Claude session watching that path picks it up and answers by **editing the doc in place**, which is
   what it already does all day
- the answer lands where the question was asked, which makes the document the conversation and needs no
   chat window at all

**Two properties worth keeping if this is built:** the request is a *particle*, so it snaps, and a Book
 could swear that an ask was answered.  And it is asynchronous by construction — the doc is not blocked
  waiting, which matches how a Claude session actually runs.
 **What it is NOT:** a live call.  Anything that wants an answer *now* needs a process already running,
  and the honest way to say that in the UI is to show whether a session is watching — the same
   liveness question `Lies_channel_live` already answers for runners.

## 3. THINKING LIKE A PLANT — the surface's stance

*The owner, 2026-09-08, on the first face: "any thoughts on the UI? I need you thinking like a plant
 there."*

**First, the honest read of what was just built: `Lagui` is not a plant, it is a dashboard.**  Three
 buttons you press to make three things happen.  Nothing grows; nothing responds to where you are looking;
  press nothing and it shows nothing.  It is a fine first cut for *making the work visible at all*, which
   was its whole job, and it is the wrong shape for what this wants to become.  Say that plainly before
    designing over it.

**What a plant actually does, and what each thing maps to here:**

- **Tropism — it grows toward light, it does not plan a shape.**  The light is ATTENTION, and attention
   already has a name and a machine: `%Interest`.  So nothing is placed; things grow where you are
    looking.  You land the cursor on a method and its callers *sprout* beside it — you do not press
     "callers".  You open a doc and its rot is already showing.  **The verb list stays; the buttons go.**
- **Local rules, no arranger.**  A plant has no layout algorithm and no pose model; form is what happens
   when every meristem follows the same local rule under different local conditions.  **This is the
    cleanest way through the `Lens_posable` gate** ("don't build until the pose model is designed"): we do
     not need a pose model if we are not posing.  Design the *growth rule*, let arrangement fall out.
- **Growth is rationed.**  A plant cannot grow everywhere; it spends where the return is.  The corpus has
   already designed this energy budget twice and built neither: `Matstyle`'s **`dose_drives`** (interpolate
    a size from a dose between min and max — the growth response, and it EXISTS) and `Lens_posable`'s
     **excitement/awakeness scheme** (a `run_when` floor plus an Interest-cursor excite level driving lens
      intensity, with an MRU budget on the awake set — designed, unbuilt, uncooked).  Those two are the
       plant's phototropism and its carbon budget, sitting on the shelf.
- **Apical dominance.**  A plant grows mostly at one tip and branches only when the tip is checked.  So the
   surface shows ONE growing point strongly and its branches faintly — not N equal panels.  **This is the
    same shape as the recipe** (§1): a tip, a linear stretch, a spiral curling away.  The apex is the
     question you are asking now; the branches are what you left.
- **Accretion, and nothing is deleted.**  Wood is the record of every year that happened; scars stay.  The
   spiral in §1 is heartwood — not lost, just no longer conducting.  A rotted doc link is deadwood you can
    see and prune.  This is also why the recipe should never be a changelog: rings are not a list of years,
     they are the shape the years left.
- **Dormancy is normal.**  Off by default, flushing when worked.  The tap being parked is a season, not a
   deletion (`Electrode_todo §0`).
- **Roots and shoots are one organism.**  `Atlas` is the root — down into the substrate, seeking, mostly
   invisible, doing the actual acquisition.  `Lagoon` and its face are the shoot — up toward attention,
    where the light is.  `Electrode` is the sap: what actually flowed, and how much.  That is a better
     account of why these three sit in one directory than "they are all about code".

**The claim worth testing, flagged as my read rather than the corpus's:** *thinking like a plant is not a
 new idea here — it is the name that unifies four designed-and-unbuilt things.*  `dose_drives` (size from
  attention), the excitement/awakeness scheme (the budget), `%Interest` (the light), and — the one that
   makes it more than a metaphor — **`Vyto_sizing_todo §7`'s sizing algebra, whose declared inputs are
    "dose, shared-ness, attention" and which is the named tenant that would un-park the Sunpit and
     `IOexpr`** (an `IOexpr` names a source and a shaping; growth *is* a shaping of sources).  If that
      holds, the plant-shaped surface and the un-parking of `IOexpr` are the same piece of work, and the
       owner's two open threads — "expressing Seem's sphere-joining more coherently" and "how IOexpr can
        play with it" — meet exactly here.  **Not decided; it wants the owner's read before anyone builds
         on it.**

**What that makes the next cut of `Lagui`** (small, and none of it needs a pose model):
1. **Delete the buttons.**  Read the Interest; show what is true about where the cursor already is.
2. **One apex.**  The current question big, its branches dim, everything else folded to a line.
3. **Dose as size.**  Reuse `dose_drives` rather than inventing a prominence rule.
4. **Nothing vanishes; it thins.**  A dropped branch greys out and stays for a while — the spiral, in
    miniature, so the surface teaches its own history.

## 3.9 Erupting structures — the surface's one idea

*"little structures erupt when we go climbing call trees… they might be arranged around the place."*

The pin rail in BigWordland is the seed of this and is already built: a search hit can be pinned into the
 loose space beside the code, and a pin click re-fires the same recorded delivery.  Climbing a call tree
  should erupt the same kind of small thing — a caller list, a coverage patch, a doc-link cluster — which
   can then be *placed* rather than dismissed.  Two constraints inherited:
- **No new pose model.**  `Lens_posable_TODO`: *"the posing/anchoring model is the unbuilt, uncooked part.
   Don't build until the pose model is designed."*  So arrangement in cut one is the rail's own list order,
    not free placement.  Free placement is the pose model, and it is a designed thing waiting its turn.
- **A structure is a view, never world-matter.**  The `yore` note's rule, and the same one that keeps
   Electrode's ring on `.c`: what you erupt while wandering is not state the world owes anyone.

## 3.5 WHERE YOU ACTUALLY SEE IT — the face, and why not in BigWordland

*The owner, 2026-09-08, looking for the afternoon's work in a browser: "where do I see the latest thing?
 …is the same old LiesLand I think… but only Langui visible? where's all the work?"*

**Honest answer at that moment: nowhere.** Everything the censuses knew was reachable only from the CLI,
 which is not a place anyone lives.  So `Lagui.svelte` (`src/lib/L/`) was built the same afternoon and
  `Lagoon_plan` mounts it the ordinary way — `uis.oai({UI:'Lagoon'}, {component: Lagui})`, the `Cyto_plan`
   idiom — so it appears as a `UI:Lagoon` row like Lies, Cyto and Supervisor do.  **Confirmed mounted on
    the live runner.**  Three readings stacked in one panel, matching the stories: *who calls X*, *rotted
     doc links as a work queue*, *declared vs measured*.  A hit click is the same recorded
      `Lies_ghost_pick` delivery the searchbar already makes — reusing navigation rather than inventing it.

**It keeps nothing**, exactly like the ghost beneath it: every number is asked on the tick it is drawn.  A
 face that cached would be the two-truths mistake one storey up.

**⚠ It cannot appear in `/BigWordland`, and that is structural.**  The room boots `role: 'word'` →
 `Lies%humdinger`, and `ghost_load` is REFUSED on a humdinger (`LiesFunk.svelte:2522`, "a music page is
  never made to load code").  L ghosts are outside `CREDULER_GHOSTS`, so a humdinger has no other way to
   get them.  **The room therefore shows only what the spine mounts — which is why the owner saw Langui
    and nothing else, and why that is not a bug.**  The face lives on the RUNNER tab, where the ghosts do.
 Getting it into the room is a *manifest* question and therefore Atheory's: either L ghosts join the
  declared manifest for an editor role, or the room learns to ask a runner over the relay (`Wordland_todo
   §5`, road (a)).  **Do not fix this by editing `CREDULER_GHOSTS`** — that is the load-list disease
    `Atheory_todo` exists to cure, and a humdinger would then parse every L ghost it never uses.

## 4. Where it lives

`Ghost/L/Lagoon.g`, beside `Atlas.g` — the land (`CLAUDE.md`, "the land").  L ghosts are not in the spine
 manifest, so a runner gets it with `ghost_load Ghost/L/Lagoon.g --stand=Lagoon` and a tab reload drops
  it.  Book: `Ghost/L/Lagoonation.g` → `LagoonStaple` (the `<Name>ation.g` convention: Voro→Voronation,
   Atlas→Atlantation).  CLI: the existing `atlas_lint` / `atlas_callers` ops keep their names for now and
    dispatch into Lagoon, so nothing a script calls changes on the move.
