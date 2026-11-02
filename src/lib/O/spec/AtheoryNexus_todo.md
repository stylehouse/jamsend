# AtheoryNexus_todo.md — the open concepts, in one place, as few as they reduce to

*Started 2026-11-01 from the owner's overnight read of the threads ("keep it all well rounded and aware of what's proto and how").
 Atheory's record of what is BUILT stays `Atheory_design.md` (and its ledger §2); the order of the main works stays THE MAP
  (`Atheory_todo.md` §0.0).  This doc holds what is still a CONCEPT, reduced over four rounds with the owner (2026-11-01/02): each
   thread says what it is, what is ruled, and the lean.  When a thread is built it leaves here for `Atheory_design.md`; when it is
    parked it leaves for the doc named.  Older lists it gathers: `Atheory_design.md` §1.15 "Remaining conceptualisations" and §3
     "Where it's heading".*

## 0. What to get on with next

**Built 2026-11-02** (THE MAP item 4, the scheduler for real, §3.5): Theory's scheduler addresses As, not names (`AthePondTwoClocks`);
 the run loop in `beliefs()` — an A marked `%TheAAttend:run` has its As moved by pulse (`AthePondAttend`); one R3 resolver
  (`Housing._A_near` with opts; `TheA_nearest` calls it); `TheA_near` renamed `TheA_seek_out`; an A or H is its object — `resolve()`'s
   veto (`AthePondIdentity`).  Ledger rows in `Atheory_design.md` §2.

**Evening 2026-11-02 — read this first.**
- **Aip BUILT** (§3.10): `Housing.Aip_claim` → `n.c.Aip` (Dip path, never reused, never snapped); `attend` and Theory `TheA_tree`
   claim; `TheA_by`/`TheA_aip`/`TheA_say`; `TheA_at`/`TheA_io`/`TheA_tape`/`TheA_refs` take an A, an Aip or a name.  Book
    `AthePondAip` accepted, green ×3; AthePond* + AtheStoryInStory/Walk swept green.  Left: `e%Aw` → Aip (Housing's elvis path).
- **One attention mark BUILT, recorded, swept green** (§3.2): Housing `attends(n)` — `%TheAAttend:think` (= `%TheABelieves`, still
   read) all four legs; `%TheAAttend:run` = findable + watched.  Book `AthePondAttendMark` accepted (3 oaths).
- **Storica's strip pocket — BUILT, recorded (night, 2026-11-02).**  Ground.g `Desk_pick` stands `A:Desk/A:Hand(%TheAAttend:run)/A:Strip/w:Desk_Strip`
   and pokes it; `Desk_Strip_woken` keeps `%Picked:n` and elvises `story_sel` to the inner Story.  Storica's `pick` calls it again.
    Book `AtheStoryPick` accepted (2 oaths), green ×3; inner-Story + AthePond Books swept green after.  Three bugs it took:
   - `TheA_poke` woke by `feebly_ponder`, which only fires on a Story Run House mid-step — a Desk sub-House never woke, the
      pulses sat.  Now a House with no Story clock (`c.runtime` never set) is woken by `main(true)`.
   - `e_story_sel` minted `This/Step:n` (`i_step`) for a step never run — the panel read it as run: "snap not yet loaded", not ok
      (owner's live glitch).  Now found only (`step_c(...,soft)`), in StoryFu.g and Story.svelte.
   - a nested `story_sel` never woke its holder (`Story_at` does) — a ttlilt HOLDS, it never wakes, so the outer step slept its
      90s ttlilt and was snapped on the timeout, `ok:1`, its gate and witness never run.  Now it wakes `TheA_base.up`.
   Also: the leash poll (`schedule()` every 200ms while held) no longer logs `⏭ schedule`.
- **A step that outlives its ttlilt — SURFACED, not yet red.**  It came out `ok:1`, a timeout recorded as the truth.  Now Story
   stamps `Step%timeout` (Story.svelte + StoryFu.g), `runner_ask steps` shows it, `runner_sweep` prints `⏱ timeout step N`.  Athe*
    sweep (42): ONE timeout, and it was a bug — AthePondIdentity held step 1 for twins stood at step 2, 90s every run, its
     fixture recording the held gate; fixed + re-recorded.  Before it caveats: sweep the music/Hoho families (expecting() waits)
      and count.  Also re-recorded AthePondAip (its fixtures were taken under the `--swap` misdiagnosis: TheACode without dige).
- **Hollow runs were a missing `Stands:CoreTesting`**, not stale code: a new Book's toc is born without it, so no runner loads
   AtheTesting.g for it (my `--swap` advice was a misdiagnosis; the swap only loaded it by hand).  Added to the 8 Books since
    AthePondNear.  Want: StoryFu inferring a missing Stands from the Credence
     row's ghost, so a new Book can't forget it.
- **A hollow first run saves itself (bug, 2026-11-02 night).**  AtheStoryPick dispatched with no toc and no Stands ran one empty
   step (its method never loaded) and wrote a 1-step toc + 001.snap — a blank Book, silently.  A new-mode run whose Book method
    is absent should refuse to save (and say so), not record nothing as the truth.  Its dir is now a bare toc with `Stands:CoreTesting`.
- **Wanted: a format to work in together (owner, 2026-11-02 night).**  What we say to each other — spec links, particle notation, .g
   excerpts, snaps — is printed into a terminal or buried in Waft tocs, so nothing links and nothing renders.  Wanted: a place where a
    reply can link a doc and a line (`spec/X.md §3`, `Ground.g Desk_pick`) and show the notation laid out (a particle tree as a tree,
     a snap with its diff) — a working surface, not a Waft database.  Candidates to weigh: Wordland's doc reading (spec/Wordland_todo.md)
      grown to render this notation; a published page per session; markdown with a renderer for `%particle` and snap blocks.  Unruled.
- **Inner Books are shared.**  AthePondRounds is the inner Book of AtheStoryInStory, Walk, Sabotage and Pick (AthePondFocus of Show):
   one fixture, four outer Books — a change to it reds all four.  Nested Stories no longer write TimeSpool into it (StoryFu
    `collect_time_sample` returns when `TheA_base`).  Story_future §19: the Credence `desc:` as the runner's headline would show this.
- **ReactiveWaft kept**: the only guard on the gated-vs-ungated read that once tore down KeepFace for weeks (subagent stopped
   short of deleting).  Re-record its fixtures, don't delete — owner to confirm.

**The night of 2026-11-02/03 — where it got to (read this first):**
- **The begun-wedge is a LOST DRAIN, not the disk.**  ~8% of Book starts (12 of 149 in the non-Athe sweep, at random) sat at
   `phase:begun` forever: the toc read settles in ~20ms, `ponder_now` pushes a think onto Mundo — *second* in the todo — the drain
    takes the item ahead of it, and Mundo's todo is never drained again (diag, HohoLocate: `ponder_now pushed … todo 2 waiting=true
     pending=true` → `drain took an item before it … todo now 1` → nothing).  Mundo is NOT stopped.  Suspect: the drain's own
      come-back timer and the gate timer that clears `answer_calls_waiting` fire at the same gate ms; when come-back loses, the
       next drain rests on the `todo_version` $effect re-bump, which Housing's own 2026-08-08 comment says can fail.  **Watchdog
        built** (Housing `ponder_now`): a ponder think still queued 2s on is logged with the drain counters (calls/gated/tries,
         drain_why, waiting/pending, mutex) and driven; `runner_ask world` prints "🐕 drain watchdog rescued N×".  Next: read a 🐕
          line, fix the re-arm at its root, keep the watchdog as the alarm.  (diag lines in `stop()`, `ponder_now`, Wormhole_park
           are TEMPORARY — take them out with the fix.)
- **The leash by news — built, re-gate owed.**  A held drive parks (`run.c.leash_resume`); `Desk_leash_carry` calls it when the
   leash moves; Storica's no-Desk hand sends `story_unleash`; a 5s fallback warns `⛓ leash moved with no news`.  The first cut
    elvised the inner w and broke every AtheStory* Book (`no House has A:[object Object]` — a w stood that same think has no
     route); fixed by calling the resume.  One mixed run after the fix (the owner was running Books on the same tab): Walk/Sabotage/
      Pick green, AtheStoryInStory red with its inner run snapping `open_at=2` — re-run it clean before believing.
- **Refuse a hollow recording — built (StoryFu only; Story.svelte left to drift, owner 2026-11-03).**  `Story_hollow`: no
   `Run_A_<Book>` and no handler for the Book's w ⇒ a new-mode run stops before step 1 with `∅ hollow`.
- **Another way to record from nothing:** a run that picks `mode:new` BEFORE its toc read lands (a slow read, or a diskless tab —
   the headless eye recorded AthePondAttend that way) records over a Book that has fixtures.  The mode must wait for the read.
- **The Desk runner, slice 1 — built, untested** (the pure Atheory runner, below).  `runner_ask run <Book> --desk` /
   `runner_sweep --desk`: `Lies_desk_book` stands Core if the tab lacks it, tears down H:Story, resets the tab's H:Desk and asks it
    for the Book (`%DeskRunner` on w:Desk → the Story's `w.c.report_up` → StoryFu `Story_finished` tells Auto, so verdict,
     Credence spool and run_result land as for any run).  `Lies_runner_story_w()` and `Cred_run_outcome` read the Desk's inner
      Story while `top.c.desk_running`.  First trial: the Athe Ponds, a few Hoho/Vyto/Swarm, then one normal run to see H:Story return.
- **The Desk runner, 2026-11-03 morning:** AthePond*, the AtheStory* re-gate (normal) and VytoStaple green; then after one fix
   **63 of 71** of Hoho*/Vyto*/AthePond* green with `--desk`.  The fix was the predicted class: Lang found the Story by
    `top.o({H:'Story'})` — none at the top under a Desk, so w:Lang grew its own `Styles` (HohoKeep/HohoFlush's only diff); Lang
     now walks up from its own House (page H:Story, a Desk's A:Desk/A:Story, or Mundo's own H:Story).  Left: HohoTiles, HohoWaftMap,
      VytoBunch, VytoMitosis, VytoSeek, VytoStaple (1–2 `see:` lines each), VytoFreeze (`⏱ timeout step 3`), and HohoKeep/VytoFoam
       NEVER STARTED at begun once each — the drain watchdog was ponder-only then; it is now **general** (`_drain_dog`, one timer per
        House armed by any push: the head waited 2s, no drain since, mutex free ⇒ say why + drive).  Not yet seen firing.
- **e747 twice failed to come back from an agent's `runner_ask reload`** ("refused (busy)" for an hour; a headless cold boot of the
   same code is fine both times; the owner's manual reload cured the first).  Until understood: after a reload, if 3 pings fail within
    3 min, stop and ask the owner — don't loop reloads.
- **The non-Athe census:** 0 `⏱ timeout` steps across ~149 Books — the timeout caveat costs nothing outside Athe.  Reds: MusuPier
   (order flake), MusuRaStream (wall-clock `now=` in sc), MusuReco (body_hash), MusuSmuggle/MusuMag (more steps than fixture),
    MusuRadio (needs AudioContext), SwarmGot (redeeming→sealed timing), PortPain (∅ — toc lacks `Stands:`); InvFerry/Seal/Walk
     "more steps than fixture" once, unverified.  Runner-killers this night: MundaneStaying, MusuRaChase (each wedged twice).
- **Diffmatication**'s committed toc said `c5c6…` while its own 001.snap hashes `539f…`; the toc now says `539f…`.
- **Sweep agents and tokens:** a Monitor that reports every poll wakes the agent AND the parent every few seconds — one batch cost
   ~25 double wakes.  Sweep prompts now say: emit only on batch-exit or a 60s wedge.

**The pure Atheory runner — the plan (owner 2026-11-03: "the next generation of this sit there and run every job that comes along
 thing … with the runner role on the editor").**  1. The Desk runner on today's spine (slice 1 above) — reds there are where StoryFu
  still assumes it is alone (its 22 `top_House()` reaches).  2. Jobs as arrivals: a relay `run` becomes a pulse on an A:Runner
   compartment, each job its own Desk, ending a job drops its Desk — no Auto teardown, no `stop()` cascade.  3. The editor's runner
    role through the same door.  4. Story.svelte retires when the fleet is green on Desk runners.

**Overnight queue (2026-11-02 night, owner leaving it running after a compact — no Book runs inline, a Sonnet agent per sweep):**
1. Sweep the music/Hoho/other non-Athe families for `⏱ timeout` (runner_sweep, unusual rows skipped) — the count decides whether a
    timeout caveats (§0 "a step that outlives its ttlilt").  Report per family; fix only Book-side holds that wait for nothing.
2. The leash by news (§0.1 item 1): `Desk_leash_carry` changing `%StoryLeash` wakes the inner drive; the leashed `schedule()` stops
    polling.  Gate: AtheStoryInStory/Walk/Sabotage/Pick green, and faster.
3. Refuse a hollow new-mode save (§0 "A hollow first run saves itself").
4. AtheStoryPick variant: let the inner run to step 2 before the clicks, so the selection lands on a ran step.
**Next, in order** (items 1–3 below are DONE as of 2026-11-02 night; next: the ttlilt-timeout-ok bug, the hollow-saves bug, Stands from Credence, `e%Aw` → Aip):
1. **Aip on `A.c.Aip`** (§3.10, ruled) — a Dip-path id claimed when an A stands, never snapped.  Then the by-name readers
    (`TheA_at`, `TheA_io`, `TheA_tape`, tendril addresses) look up by it — the tendril-printing Books re-record.
2. **One attention mark** (§3.2) — `%TheAAttend:think` (= today's `%TheABelieves`: thought, pumped, findable, watched) and
    `%TheAAttend:run` (findable + watched only).
3. **Storica's step strip, the first run-loop duty** (§6 DECISION A, ruled) — a click is one arrival through the door (Stuffica's
    "Out"), a pulse on the strip's compartment; the views commit after the run.

*Open for the owner:* §6 DECISION B (what a turf lease names).  *Side thread, any time:* IOexpr's `%ioing` rows (§3.3).
*Tooling:* `scripts/runner_sweep.mjs` runs Books one line each, skipping Credence's `unusual:` rows.  A new Book needs `Stands:<Ground>` in its toc (memory new-book-hollow-first-runs).

## 0.1 Where it's going — the night think (2026-11-02, owner: "read Atheory docs and give it a good long think")

**What tonight showed.**  Every bug in the strip pocket was a WAKE.  `TheA_poke` woke by `feebly_ponder`, which a Story clock gates
 (`c.runtime`) — a Story idea deciding whether an Atheory poke wakes a House.  A ttlilt held step 3 and woke nothing, so it slept 90s
  and was snapped on the timeout.  `story_sel` changed what the inner Story shows and told no one.  The leash is a 200ms poll.  And
   AthePondIdentity paid 90s every run on a hold with nothing to wait for — found only because a timeout is now stamped.  The legacy
    generation waits by TIME (ttlilt, poll, `setTimeout`: 14 in StoryFu alone, 13 gate holds in AtheTesting, 43 `feebly_ponder`s in
     Ghost/); Atheory waits by NEWS (a pulse on a synapse that declared it hears it).  Where the two meet, a wait that should have been
      a hearing becomes a timeout, and a timeout reads as a pass.

**So the arc, said once.**  From a House that thinks everything every tick and waits by clock, to a tree of compartments that move
 when news arrives — news entering at one door, written on a tape, with Story a reader of that tape.  Each level says which loop it
  attends (§3.2); each wait says what it is waiting FOR (a `%TheAWait` answered by a pulse), and its timeout is an alarm, not a verdict
   (design §3 "the Believer": "a `%ttlilt` that runs out should alarm, not only expire" — tonight is the proof).  The screen is pockets
    (§3.13): run-loop compartments the UI pokes and reads.  The Desk becomes the page and the old generation retires (THE MAP 1).

**Three things to hold onto.**
1. **The wait is the next duty, not another button.**  DECISION A put the strip on the run loop; the next run-loop duties are the
    WAITS the two generations share: the leash (a `%DeskLeash` change is a pulse into the inner Story, not a poll it notices), the
     gate holds (`AtheStoryInStory_hold` — a `%TheAWait` on the outer's compartment, answered when the inner says `Story_at`), and
      `Story_at` itself (already a wake; make it a pulse).  Each one converted deletes a timeout path, and its Book gets faster and
       more honest.  A Book's step that ENDS on news is causal; one that ends on time is now `Step%timeout` — the measure of progress.
2. **The harness must not believe absence.**  Tonight it took for truth: a hollow run (no `Stands`), an unaccepted new-mode run
    (it saved itself), a click-minted step (read as failed), a timeout (read as ok).  One motif (design §4.2 #5, "record what
     landed, not what was asked", has a twin): **nothing recorded from nothing.**  A recording should need positive evidence — a step
      that ended causally, the Book's method seen running, an oath per step that claims anything.  Credence's `desc:` as the
       headline (Story_future §19) is the human half of it.
3. **The poke's wake rule is a patch on a missing door.**  `TheA_poke` now asks `c.runtime === undefined` to decide how to wake — a
    House-level fact read off a Story field.  The door (§3.4: a per-House arrival queue, its own qualities) is where "wake this House
     for this arrival" belongs.
    *Checked 2026-11-02 (owner asked):* Story's between-steps freeze is **not** a shut door yet — it is half of one.  Between
     steps `Run.c.runtime = false` (StoryFu.g ~2688, Story.svelte ~2672) makes `feebly_ponder` (Housing.svelte.ts ~1177)
      return: the **knock is dropped**, not queued.  The **letter survives** — `TheA_poke` writes `%TheAPulse` onto the synapse
       before it knocks — and the next step's blanket `setTimeout(() => Run.i_elvisto(Run, 'think'), 1)` (StoryFu.g ~2520) is the
        hand that checks the mat: a whole-House think that finds it.  Meanwhile `main(true)` / `ponder_now` / `i_elvisto` walk
         straight past (Story_at, disk settles, Desk_pick).  So the door is: a queue of knocks held while shut, opened at step start
          in place of that blanket think, with the bypassers either going through it or named as exceptions.
    *First slice BUILT 2026-11-03* (Atheory_design §2 Housing row): Housing `knock()` / `door_open()` / `door_shut()`; a knock on a
     shut door is KEPT (`c.knocks`), counted in at the next `door_open` (Run trace `door`), delivered by the step's own think;
      `TheA_poke` knocks, its runtime rule gone.  Still owed: knocks as ROWS (with the arrival shape `{what, by, from, corr, at}`),
       `feebly_ponder` and the bypassers (`main(true)`, `ponder_now`, `i_elvisto`, `UItime`, Storica's In) entering through it, and
        the step's blanket think becoming the door's own.

**What that orders.**  (a) the waits onto the run loop, one by one, each with its Book faster and timeout-free; (b) "nothing from
 nothing" in the recorder (refuse hollow saves, refuse timeout greens — after the music/Hoho count); (c) the door, small: an arrival
  queue per House that `TheA_poke`, `UItime` and Storica's In movement all enter through.  THE MAP 1 (the Desk is the page) waits
   on all three: a StoryFu that waits by news is one worth making the page.

## 1. How real each part is

| how real | what | so |
|---|---|---|
| **Foundation** (keep; a ledger row per change) | As in As by mark (`%TheABelieves`); addressing R1–R3 (`_A_near` — the one resolver, `e.c.to_A`, `A.c.up` = holder); an A or H is its object (`resolve()` veto); code kept aside + `TheA_as`; `ghost_versions`, CodePush; Ground loading; the Atime ring | built to last |
| **Working proto** (real, thin — grows when a use asks) | StoryFu in a Desk: the leash (ready · step · red), Storica's hand, `Desk_reset`; the sabotage Book; Stuffica views | more debugger controls (run to N, rerun with a variant, break on an oath) whenever we actually need them — not before |
| **Toy, proven by hand** | the scheduler: `TheA_run`, move, batch, boundary, Turn, synapse, tape, hold (`%TheAWait`), tendrils | runs on ponds, Books and `/Pondland` — and, since 2026-11-02, inside `beliefs()` for any A marked `%TheAAttend:run` (no real duty marked yet: §0 item 3) |
| **Sketch** | the door, IO as compartments, `%J`, `@name`, spheres beyond Trace/Regard, turfs, the Believer, migrations riding code | words |
| **Tax** (paid while the old generation lives) | two Storys (every Story fix twice); everything.js; `%InnerRun`; a `Self_round` Entcase in every nested Book | ends when everything moves into the new tube-ways (§3.1) |

## 2. Words, pinned

- **compartment** — an addressable chunk of the belief-scape: an A's w today (`A:K_P/w:Athe_Tank`).  It has an address (R3 finds it
   by name, a ref reaches it by handle) and holds rows.  *Owner 2026-11-02:* w stays the compartment — "a nice round piece of work";
    an A is a more flexible container that divides space more incidentally, and may stand inside a w.
- **seam** — the edge between two compartments.  News crosses a seam only as a **pulse** (sent on an axon, landed at the boundary on
   a synapse that hears it).  A write that stays inside a compartment crosses no seam.
- **move** — one compartment's go: it eats its inbox, writes only its own rows, sends only into its outbox (`TheA_move`).
- **Turn** — the RECORD of one synapse's part in a move: what it ate (`%TheAAte`), the code it ran under, rows new and gone
   (`%TheANeu`, `%TheAGoner`), what it sent (`%TheASent`).  So **a write inside a move is not a Turn of its own — it is a Neu or Goner
    on the move's Turn.**
- **version** (of a compartment) — `(era, n)`: n counts its moves (the Turn number); era is its birth, or the code era, so a count
   compared across a reload or a `Desk_reset` reads as "everything changed", never "nothing did".  *Ruled 2026-11-02.*  (Not Stuff's
    `C.version`: that bumps on every C at every level and doesn't roll up.)
- **tendril** — the thread between two events: **back** is a pulse's `from:` (the address of the move that sent it, or `/Heard<n>`
   from outside); **forward** is the `%TheAAte` rows that name you (`TheA_led_to`).  Two particles on a Turn, opt-in per House
    (`%TheATendrils`), kept only while a `%TheAReader` follows them.  Built 2026-10-28 (Book `AthePondTendril`; the board on
     `/Pondland`).  Why: "event after event can be traced back or forward … consistent eventing" (owner).
- **elvis vs pulse** — an elvis is sender-addressed ("you, do this"); a pulse is receiver-declared (the synapse says whom it hears).
   Housing runs on elvises; Theory on pulses.  The door (§3.4) is where an elvis from outside becomes a Heard pulse.
- **loop** — a compartment with an axon: its beats are pulses, and to want its attention is to hear it.  `think` (Housing's walk),
   a clock, the door, a Story step, `TheA_run`'s rounds are all loops (§3.2).

**One shape at every zoom.**  Pass ⊂ move ⊂ batch ⊂ round ⊂ era; Sunpit ⊂ J ⊂ A\*\* ⊂ House ⊂ tab ⊂ flock.  The owner (2026-11-02):
 the spreading of words for one shape is the thing to watch.  The reduction: one kind seen at different magnifications, told apart
  by qualities (hosted more than once, attends which loop, declares its API), not species.

## 3. The threads

### 3.1 The tube-ways — everything moves into the new fabric
*Ruled (owner 2026-11-01): "everything has to move within the new tube-ways."*  The Desk becomes the page (`/Desk?B=`), the spine
 becomes `Ground/Runner`, everything.js is sublated, Story.svelte/Otro/Auto retire once StoryFu has their greens.  THE MAP item 1.
  Mostly porting, but it is what ends the tax in §1.  Waits on: Lies (the relay seat) standable by a Ground.

### 3.2 Attention — each level says which loop it wants
*Ruled (owner 2026-11-01/02):* every level asks for attention by a mark; depth stops meaning anything.  **Absent means the `think`
 loop** — today's default, so every Book keeps working.  Other loops are named.  An A that names another loop is that loop's; an
  A\*\* pond is `TheA_run`'s.  Then the ponds and the Housing walk are one tree with several drivers, and the scheduler-in-beliefs is
   one more loop on it.
- *Shape (lean):* `%TheAAttend:<loop>` on the A; `%TheABelieves` becomes "my As attend my loop".
- **What `%TheABelieves` bundles today** (Housing, read 2026-11-02) — four things, and a loop mark must say which it carries:
  1. **thought** — organise/attend walk into the A's As and call their w's method each tick (`get_next_levels`);
  2. **pumped** — the req sweep tugs their reqs (`reqdo_sweep`);
  3. **findable** — `_A_near` walks into them, so a name from outside reaches them;
  4. **watched** — their w's `%watched` channels enrol for the UI (`enroll_watched`).
  The run mark (`%TheAAttend:run`, built) takes **none** of them today.  Lean: a run-marked A's As are **findable** and **watched**
   (an address and a screen need them), never **thought** or **pumped** (that is the think loop's; a run-loop A's reqs wake by pulse,
    §3.5 "reqs woken by pulse").  So the unified mark is `%TheAAttend:think` = all four (today's believing), `%TheAAttend:run` = 3+4.
- **The door, clocks, time and Story's steps are one thing** (owner: "indeed") — loops, each named by `@` (§3.9).

### 3.3 IO — boring `i|o`, reactive `S`, the two ends related
*Owner 2026-11-01:* "we have non-reactive i|o, and more plausibly reactive S i|o … something that meaningful not in the code is
 fundamentally discordant."
- **`i %X` stays boring** — `w.i({X:…})`, no runtime cost.  Inside a move it is a Neu on the Turn.
- **`S` is how an IOexpr is reactive, and what it reacts to is written in it** (*ruled 2026-11-02*): a `@name` mentioned in an `S`
   expression is a loose reference to another thing's version that should notify this one — the expression's `@`s ARE its watch
    list.  `S o @Clock/%Tick` reads and subscribes.  The compiler knows every `@` statically, so Atlas can draw the wire and check it
     (each `@` resolves; the `S` sits where a Sunpit may home, §3.8).  Svelte's runes track reads at runtime; here it is lexical, so
      an editor and an LLM see it without running anything.  (Syntax beyond that — play with it once the basics roll.)
- **Tendrils, extended: declared sensitivity against observed** (owner: "tendrils … extended to doing the inter-IO sensitivity").
   A tendril is OBSERVED — what a Turn ate, from whom.  An `S` expression's `@`s are the same thread DECLARED — "this read wakes on
    that"; at runtime the declaration stands a synapse and the Ates say whether it fired.  Three views of one wire, each checking the
     others: **static** (Atlas: this line reads X, made by those lines), **declared** (the `@`s), **observed** (the tendril).  A read
      that keeps seeing changes with no declaration = missing reactivity; a declaration never eaten = dead.  That is the dialectic an
       LLM can contribute inside: propose a declaration, and the three views agree or show where they don't.
- **The i end and the o end, related in the editor** — code-graph knowing.  Atlas's `%Map` has make rows (`%mint`, `%probe`, m16);
   missing are READ rows (raw `.o({` is 3080 sites) and the per-mainkey join (the shape census, IOexpr_todo §3–4).  The side thread
    in §0.

### 3.4 The door — one shape for every arrival
Every arrival (a frame, a key, a click, a verb, a timer, a `runner_ask`) is one shape `{what, by, from, corr, at}`, through the
 inbound batcher (which exists: Tribunal → `Lies_deliver_soon`), into a compartment as a taped `TheA_io` pulse.  Replay, audit,
  security and Story read one tape.  A click is one of these — Storica's hand calls `Desk_leash_on` directly today because the Desk
   is driven by Housing, not the scheduler.  THE MAP item 3; design `Atheory_design.md` §3 "The patch".
- **Writes into someone else's compartment become sends** (*ruled 2026-11-02: yes, eventually*).  Today a Book's drive writes
   `%DeskLeash` onto `w:Desk` and Storica writes `%StoryLeash` onto the inner w.  The rule: you send the compartment something and it
    changes itself; a click is one more sender; **turf** (a region someone holds the right to write — `seat:editor` on the relay is the
     one built) is checked on the send, in one place.

### 3.5 The scheduler for real — steps 1 and 2 BUILT 2026-11-02
`TheA_run` inside `beliefs()` for a believed tree first (the Desk); unwatched work costs nothing; reqs woken by pulse; every call
 through its A.  THE MAP item 4.  Its ground is laid: addressing R1–R3 (2026-10-30, Housing's elvis side).  **Step 1 — the same in
 Theory — BUILT 2026-11-02** (`Atheory_design.md` §1.15, Book `AthePondTwoClocks`; tendril addresses, `TheA_io` and `TheA_tape`
  still read by name).  What it was: a synapse hears `from:` when `synapse.sc.from === A.sc.A` — any
  A of that name anywhere in the House (`TheA_boundary`); `TheA_run`'s ready set and `TheA_boundary(names)` are sets of names, so two
   As of one name (a Story in a Story, two ponds each with a `Clock_A`) are one to the scheduler.  So: the ready set and the batch
    become As (refs), names accepted only at the edge and resolved once; a synapse's `from:` binds to the NEAREST A of that name from
     the synapse's own A (up through its holders, then down — R3's walk over the A\*\* tree), kept on `synapse.c`.  Proof: a pond Book —
      two ponds each holding a `Clock_A` and a tank; each tank hears only its own pond's clock (today each hears both).  **Step 2 — BUILT 2026-11-02** (Book `AthePondAttend`; Housing ledger row):
       an A marked `%TheAAttend:run`, found through believing As, has its As run by the House's own think whenever one has a pulse waiting
        (`TheA_attend_runs`, scoped `TheA_run`, `TheA_poke`); `beliefs()` is the abdomen the duties get racked in.  Was: `TheA_run` inside `beliefs()` for the Desk — shaped by §3.2.  Writes from the `think` loop stay gapped (no Turn, no pulse) — fine: we are moving into the new fabric,
   not bridging the old one (owner 2026-11-02).

### 3.6 Toc rows are programmatic; advice about a Book goes in Credence
*Ruled (owner 2026-11-01):* the declared sabotage **stays** in `wormhole/Story/AthePondRounds/toc.snap` — `AtheStorySabotage` reads
 it off the inner Story's The.  The rule: **a toc row is something a run reads; a note about a Book that no run reads goes in
  Credence**, as a child of its `Funkcion:Storying,of_Book:…` row.  The hand sabotages S1–S6 (`Atheory_design.md` §1.10) become toc
   rows when a Book runs them.

### 3.7 Addressing — built; one habit left
R1 holding, R2 refs, R3 nearness are built (`Atheory_design.md` §1.15, Book `AthePondNear`).  R4 — names only at a boundary (the
 wire, a toc, a Credence row, a person typing) — is a habit: a string `i_elvisto` becomes a ref the day a second one of its target
  stands.

### 3.8 `%J` — a hostable organism, its Sunpits its API
*Owner 2026-11-01:* "Sunpits should kinda hoist out of their context, as closures, so one blob of code can define some
 ExoticObject() it abstracts, and the Sunpit create an API of sorts to play with that object … register that whole thing as some
  named hostable computation … most like the %w methods, how they're the nexus of reality for that topic … Sunpit couples to our
   A|w|J things, rather than appearing in random lower level methods.  It implies more of a stately organism."  And: "%J is like a
    more particular, clearly named A, which we might end up modelling everything as, in the large."
- **J is an A that has said what it is** — *ruled 2026-11-02: a quality on A first* (one tree walk, one resolver, one ledger; a
   mainkey only if reading snaps shows it needs one).  Its code declares its rows and its Sunpits; it has a name a reader recognises;
    it can be hosted more than once.  A bare A is a J that hasn't said yet.
- **Its Sunpits are its API**: each an `S` read (what it watches, §3.3) with a body.  You reach a J by poking one; a Sunpit with a
   known watch list can be dispatched to directly, without waking a whole method.
- **Homed.**  Plain `i|o` sits anywhere, in any helper; a Sunpit belongs to an A, w or J — so it can be addressed, watched, moved and
   replayed.  "Coherent rules about when it'll be homed to what" (owner): a Sunpit homes to the nearest A|w|J enclosing its
    definition; an `S` outside one is an error Atlas reports.
- **Reqs.**  A Sunpit could be an eternal req on its J whose wake is its synapses — the req machine keeps doing, the Sunpit says
   when.  To test, not assume.
- *First build (when it's time):* a toy J on a pond — one kind, two instances on one tank, one Sunpit each, poked directly; a Book
   swears only the poked instance moved.

### 3.9 One tree for names and attention
*Owner 2026-11-01:* "the recursive name-space and attention-space are very similar … one also wants to look for some data anywhere
 above, or in some @namething that we resolve at editortime … runtime looking for names is likely ok, but has to be fast … maybe some
  loops should be accessible via @namething, which brings attention from that time|loop into those S i|o expressions."
- **They are one tree.**  Names are found by walking it (R3, nearness from the asker); attention flows down it (§3.2).
- **`@name`** — a reference in code to the nearest thing called name.  Lean: **check at editor time** (against what the Grounds
   declare stands where), **bind at stand time** (R3 once, when the A|w|J holding the code is stood; a ref on `.c`), **re-bind when the
    tree under the binding changes** (an A stood or dropped).  R3's cost goes to stand time; a call costs a property read.  `@` is free
     in stho (reserved as a Sigil; only `$` is used).
- **`@Loop` in an `S` expression** brings that loop's attention to the line: `S o @Clock/%Tick` wakes on the nearest Clock's beats.

### 3.10 Aip — every standing A has an id of its own
*Owner 2026-11-02:* "perhaps we should have a Dip for the A that exist?  maybe call it Aip … I've been inventing the A in waves for a long
 time now."  Then: "it's just to have a unique id for all the A … yeah to A.c.Aip."
- **The want.**  A name is what you SAY (R3 finds the nearest A called it); a ref is what you HOLD (R2, dies with the tab).  Neither can be
   written down and read back exactly: `Aw` (`Desk/Story/Story`) is long and says nothing when two of a name stand; a tendril address
    (`Clock_A/Athe_Clock/Turn3`) points at whichever `Clock_A` comes first.  An Aip is a short id for one standing A.
- **RULED — it is a Dip, on `A.c.Aip`, never snapped.**  The value is the slot path (`Dip_assign`'s shape): `1.1.4.6` = the first H, its
   first H, its fourth A, that A's sixth A.  The holder (House or A) keeps the slot counter on its `.c`; never reused, so a dropped A's id
    can't turn up on a stranger.  The name is printed beside it for reading (`1.1.4.6 Clock_A`) and is never part of it.  Not in any
     snap, so no Book re-records for it; after a reload the tree re-stands in the same order and the ids come out the same.
- **H and w carry one too** (owner: "H is basically a type of A, and w a type of A, very loosely … having storage is via H") — one
   scheme for every standing thing; an Aip path says where the thing's storage lives (the H in it).
- **Identity, not resemblance — BUILT 2026-11-02.**  Se's `resolve()` paired a new D with an old one by what their particles look like,
   so a lookalike A could inherit another's D (and anything riding it).  Owner: "a total negation if !==, if %A or %H."  Now
    `Stuff.resolve()` takes `q.resolve_veto`; `Selection.process` passes `Se_veto_A_H` by default (`Se.c.resolve_veto` overrides, `false`
     = none); a w keeps resemblance (agency_officing re-adds the same w objects).  Book `AthePondIdentity`.
- **What it replaces (next):** `e%Aw` stamped as the target's Aip; tendril addresses `<Aip>/<w>/Turn<n>` — so `TheA_at`, `TheA_io`,
   `TheA_tape` look up the id, never the first A of a name; a board's places and a Stuffica point's key for an A.
- **Ties (owner):** "a tie is likely some warn|error situation.  Ground should advise if not to warn perhaps."  Warn by default (now); a
   Ground may advise per name — `%TieIs:error` refuses, `%TieIs:fine` stays quiet.  With Aips a tied name can always be said exactly.
- **Not yet:** ids unique across Houses beyond the path; Aips across the network (§3.11).

### 3.11 Turf — where an arrival is let in
*Owner 2026-11-02:* turf "should be where authorisation to do things is checked at the door, eg the %Grant:Music"; a synapse across the
 network "seems similar to the turf idea allowing some stuff to 'arrive' somewhere that matters."
- **One thought, three faces:** an arrival (§3.4) reaches a compartment; the door checks the turf it enters (who holds the lease, and
   whether the arrival's `by:` holds the Grant the turf asks for); a pulse to another body is the same arrival, routed to the lease's
    holder.  Today's one lease is `seat:editor` (relay.ts); the general one is `seat:<address>` — the address an Aip (§3.10).
- **Leases nest like As:** holding a compartment covers what stands in it unless something deeper is leased; who holds a thing is
   found by nearness.  A lease changing hands starts a new era of that compartment's version (§2), so readers see "everything changed".
- **Across the network:** the relay is the arbiter of record, the holder mirrors it, renews by heartbeat, writes locally while it
   holds; on a partition both sides' leases lapse, the side without it holds its sends as waits, and the tapes explain the merge.
    Authority beyond one relay is the crew's: a lease the Captain signs.  The pulse that crosses is the `%Remote` over Reach layer
     (RemoteHeist_todo) seen as a synapse — join the two rather than build a third.
- **Open for the owner:** a lease names a compartment or a whole A subtree; a relay-held lease is enough until the crew signs.

### 3.12 Stuffica's showroom — tracked, not yet a page
*Owner 2026-11-02:* "keep tracking all that … we'll rebuild those *ui at some point, when we have the core more worked out … the Editron
 has seemed quite sluggish and does want refactoring with the new model."
- **Where it is today:** `/Pondland` (every figure a view), Storica (the step strip on views, beside Storui in StoryFu), and Books
   AthePondView, Glass, Seem, Reseat.  The shape is `Atheory_design.md` "Stuffica, the shape": **Show** built; **In** (a backend pile
    swapped whole through the door) and **Out** (a click as one arrival) not.
- **`reactivity_docs.md`** is demoted, not retired: its hazards (`replace()` publishes its empty middle; the per-tick
   `agency_officing`) still bite every legacy UI — Cytui, Vytui, Langui, Editron.  When those move onto views, it goes to `history/`.
- **Owed:** a Book gating renders-per-commit; the first In/Out subject (a Book explorer, or Editron's slow paths).
- **Bug seen live (owner 2026-11-02, "Stuffica is buggy!"):** on the runner's Desk, Storica stood at step 0 (inner Story held at
   ready); a click on a step showed steps 1+2 failed.  Not yet told apart from the new click path (Ground.g `Desk_pick`, same day).
    Wants: what Storica draws for a step of a HELD Story (never run ≠ failed), checked against the old direct `story_sel`.

### 3.13 The UI arena — pieces of screen declared, then arranged
*Owner 2026-11-02:* "we need to standardise the to-UI channel … we send it some C to read stuff off, like %Languinio, but bringing the UI
 svelte component itself to some shared arena where they are all arranged … how to declare pieces of the UI and start doing some kind of
  window managing … each UI might be a tapestry of stuff with lots of layout options that might all join across with everything else on
   the screen.  the Otro list of each H with a list of their UIs, is just the basic first way."
- **Today:** a ghost puts `%UI:<Name>,component` on its House (`watched:UIs`); Otro lists each House and mounts its UIs in a column;
   what a UI reads comes on a C it is handed (`%Languinio`, a `%watched` channel).  Placement is the list's order — nobody declares more.
- **The want, in this paradigm:** a piece of UI is a declared thing — what it shows (a Stuffica view: compartment + kinds), what it
   wants of the screen (size, priority, which other pieces it sits beside), and its arrivals (clicks into the door, §3.4).  An **arena**
    holds every declared piece from every House and lays them out — first by rule, later computed — so pieces can join across Houses.
- **The channel:** the to-UI channel is the view's commit (one counter per view, Stuffica) — the arena only places components; it never
   carries data.  `%watched` channels are the legacy road (the believing bundle's 4th part, §3.2).
- *Next when it's time:* Storica as the first declared piece (it already reads only views); Otro's column as the first arena rule.
- **Pockets (owner 2026-11-02, a wild take to grow):** "perhaps some A are defined to be the interchangeable pockets that read|write
   the front|back end."  An A whose whole job is the seam: a run-loop compartment the screen pokes (clicks in, as pulses) and reads
    (its rows, as a view), and that speaks to the back end only by sending.  Interchangeable because the seam is its synapses and
     axons, not its code: swap a pocket (another layout, a test puppet, a remote screen) and nothing behind it changes.  Storica's
      `A:Strip` (§0 item 3) is the first pocket; the arena would hold pockets, not components.  Open: is a pocket a kind of A (a mark,
       `%TheAPocket`?) or just any A that a UI reads; does one pocket serve many screens (a turf question, §3.11).

## 4. Parked — moved out, with where
- **A Story's runs as a collection** → `Story_future.md` "Open / deferred".  Owner: "might be useful eventually but is Story_future."
- **A step pointing at part of attention, snapping a subset** (a whole snap still at regular intervals); **Story as a reader / a step
   as a Sunpit**; **a warnings|errors layer for StoryFu** (a cut, a spill, an ambiguous name, a hold run out — warned so Story sees
    them) → AtheoryStory_todo §2's table.  Owner: stays on the todo "until we can see it's really time to build it".
- **More debugger controls** → AtheoryStory_todo §6, built when a use asks.
- **The loopy shadow's name, `%InnerRun`'s retirement, AtheStoryCode's own Ground** → AtheoryStory_todo §0 (small).
- **Spheres beyond Trace/Regard, merge on the wire, the Believer, migrations** → Atheory_todo §0.0 "Vaguer".

## 5. Notes kept from the rounds

- **Glitch-freedom from the boundary — the diamond.**  A changes; B and C both read A; D reads B and C.  A naive push system can run D
   after B and before C — D sees the new B with the old C (a "glitch"), then runs again.  In rounds: round 1 A moves and the boundary
    lands its pulse on B and C; round 2 B and C move (neither sees the other) and the boundary lands both on D; round 3 D moves ONCE,
     seeing both new.  *Honest limit:* rounds are not a topological order — if D also reads A directly (A→D and A→B→D), D moves in
      round 2 off A and again in round 3 off B.  A Turn records what it ate, so it shows; the fix, when one is needed, is D summing
       over the run (`sum` on its synapse) or a lag.
- **Coarse versions over-wake** — a Sunpit on `@Pond/%Fish` wakes when the heron moves.  Lean: wake coarse, land fine (a Sunpit's
   find-or-create lands only real changes).  Figure it out when one over-wakes.
- **A reactive loop** (P reads @Q, Q reads @P) is handled by rounds and capped by `TheA_run`'s `most` — silently today; the cap is
   one of the malfunctions to warn (§4).

## 6. Open, for when a build needs them
- **DECISION A — which duty gets the `run` mark first** (owner 2026-11-02: "I don't know.  perhaps you can present it for me
   better").  The mark moves a compartment off the `think` loop onto pulses.  The first real one should be small, already
   pulse-shaped, and seen by a Book:
  | candidate | what moves | for | against |
  |---|---|---|---|
  | **Storica's step strip** | a click → a pulse on the strip's compartment; the views commit after the run | already Stuffica views; StoryFu's debugger hand is where clicks land wrongly today (the AtheStoryWalk bug was a click) | Storui still beside it; two Storys |
  | **the Desk's leash** | ready · step · red as pulses into A:Story | the Desk is the believed tree §3.5 named; the leash is already rows | the inner Story is legacy `think` code — the run would only carry the leash, not the steps |
  | **the Atime ring / a clock** | a timer's beat → `TheA_io` → a Host, as /Pondland does | proven shape (AthePondTape); costs nothing when idle | no user-facing gain |
  | **a verb** | `e:Verb` arrival → the owner's compartment, taped | §3.4's one arrival shape; verbs already enter through UItime | touches every `verbs_*` owner |
  *RULED 2026-11-02 (owner: "should be fine doing it in Storica"):* **Storica's step strip** first — the frontend→backend vector: a click is one arrival through the door, a pulse on the strip's compartment.  Was the lean — clicks are the IO Stuffica's "Out" movement is missing, and a click that lands on the right Story
   by pulse is exactly what addressing and identity were built for.
- **DECISION B — what a turf lease names** (§3.11).  Three shapes:
  1. **a compartment** (`seat:<Aip>/<w>`) — finest; a flock of editors can each hold one doc.  Many leases, many heartbeats.
  2. **an A subtree** (`seat:<Aip>`) — holding the A covers every w and A standing in it unless something deeper is leased (nested,
     like R3).  Fewer leases; matches "authorisation at the door" — a Grant names an A (`%Grant:Music` ≈ the Music A).
  3. **a wormhole path** (`seat:wormhole/<path>`) — what FSA writes need, independent of the A tree.
  *Lean:* **2, with 3 as the disk's own case** — the door checks the nearest leased A above the target; files keep path leases since
   the disk is not an A tree.  A relay-held lease is enough until the crew signs (then the Captain signs the lease).
- **An A inside a w** (owner 2026-11-02, §2): what it means for the walk, the address (`A/w/A/w`) and R3.
- **What a stand-time `@name` binding listens to** — the House keeping a tree version (bumped on A stand/drop), one integer compare
   per use?
- **Three ways to say "not done yet"** — a req (ttlilt, needs_work), a Sunpit (wakes on change), a `%TheAWait` (holds for an answer).
   A Sunpit as an eternal req is the test of whether they collapse to one.
