# AtheoryNexus_todo.md — the open concepts, in one place, as few as they reduce to

*Started 2026-11-01 from the owner's overnight read of the threads ("keep it all well rounded and aware of what's proto and how").
 Atheory's record of what is BUILT stays `Atheory_design.md` (and its ledger §2); the order of the main works stays THE MAP
  (`Atheory_todo.md` §0.0).  This doc holds what is still a CONCEPT, reduced over four rounds with the owner (2026-11-01/02): each
   thread says what it is, what is ruled, and the lean.  When a thread is built it leaves here for `Atheory_design.md`; when it is
    parked it leaves for the doc named.  Older lists it gathers: `Atheory_design.md` §1.15 "Remaining conceptualisations" and §3
     "Where it's heading".*

## 0.0 The land — where the work is (2026-11-03, owner: "a big lay-of-the-Atheory-land picture … so I can direct you to the actual frontier")

**The spine of it.**  A thing should run because a row is WAITING for it (a pulse on a synapse, a knock kept at a door, a
 `%TheAWait` answered), never because a wake-up signal happened to fire (a timer, an `$effect`, a throttle, a ttlilt).  Rows
  can't be lost; signals can, and every stall of the last month was a lost or swallowed signal (the begun-wedge drain, the
   48s think-merge, the 90s hold that woke nothing, the Storui `$effect` that steered a Book).  So the map is two countries.

```
 relay / runner_ask ──▶ Otro · Auto · GhostList spine · everything.js(479)          OLD — the gate, retiring
                            │
                            ├─ H:Story ── Story.svelte(3329) ◀── twin tax ──▶ StoryFu.g(3401)   on A:Story in a Desk
                            │     waits: setTimeout 18 · ttlilt 28                waits: setTimeout 20 · ttlilt 30 · top_House() 22
                            │
                            ├─ Hovercraft reqs(1245) ── ttlilt 56, feebly_ponder 5
                            ├─ Storui/Storica ── $effect 18 / 3  (the UI used to steer Books from here)
                            │
 ═══════ Housing(3660) — the shared floor ══════════════════════════════════════════════════════════
   wakes by SIGNAL: main(true) · ponder_now · i_elvisto('think') · feebly_ponder(41 in Ghost/) · the todo_version $effect
                    · drain come-back + gate timers · stuffing_heartbeat 3s
   scaffolding over those (delete when the signals go): _drain_dog 🐕 · Wormhole 📭 hand-on guard · stop() diag (temp)
   the door, slice 1: knock / door_open / door_shut (a count, not rows yet)
 ═══════════════════════════════════════════════════════════════════════════════════════════════════
                            │
                            ├─ Desk (Ground.g 245) ── A:Desk / A:Story / A:Hand(%TheAAttend:run) / A:Strip
                            └─ Theory.g(1326) ── TheA_run · synapse · axon · Turn · tape · %TheAWait · tendrils     NEW — runs on ROWS
                                  run loop inside beliefs() for As under %TheAAttend:run · Stuffica views · /Pondland
```

**Already runs on rows** (the new country, 44 Athe Books green): the ponds and `TheA_run`; the run loop in `beliefs()`; the Desk
 strip (a click is a pulse); `%TheAWait` holds (toy only); time as a taped IO (`TheA_io`, toy only).
**Still runs on signals** (the old country, where the hours go): Housing's todo and drain; Wormhole disk replies; Story's drive
 (per-step blanket think, gate holds by ttlilt); Hovercraft reqs; the UI `$effect`s; runner_ask's `stop()` cascade and reloads.

**The frontiers — each is one country moving, biggest payoff first (my order):**
| | frontier | what moves | deletes | proof |
|---|---|---|---|---|
| **A** | **The door finished** (§3.4) | knocks as ROWS `{what,by,from,corr,at}`; `feebly_ponder`, `main(true)`, `ponder_now`, `i_elvisto` enter through it; the step's blanket think becomes the door's own | the drain dog's reason to exist; feebly_ponder's Story gate | Athe* green, `door` trace on every step, 🐕 never fires |
| **B** | **Disk replies are rows** | a Wormhole settle lands as a pulse on the asker, not a `ponder_now` | the 📭 guard; the 48s class | AthePondTendril + a cold sweep with 0 📭 |
| **C** | **Story waits by news** (§0.1 item 1) | gate holds → `%TheAWait` answered by `Story_at`; the leash a pulse; a ttlilt that runs out alarms | most of StoryFu's 20 timers; `⏱ timeout` greens | AtheStory* faster, 0 timeouts |
| **D** | **Jobs as arrivals** (pure runner, step 2) | a relay `run` is a pulse on A:Runner; each job its own Desk; ending it drops the Desk | Auto teardown, `stop()` cascade, the reload wedge | `runner_sweep --desk` = normal sweep |
| **E** | **A page is an Identity standing on a Ground** (THE MAP 1, reworded — owner 2026-11-03: no `?B=`, a runner is told its Books) | `?I=` says who; the Ground says what it stands on — `Ground/Runner` = Core + Story + Runner, whose `A:Runner` takes `%Job` arrivals (D) in place of Auto's pick/teardown/rebuild; the Story's buttons become pokes on the Desk's Hand (like the step strip). RULED: `/Desk?I=…&G=Runner` — the Ground names the role (default: its name lowercased); see *E thought through* below | the twin tax; Auto; everything.js | the fleet green on Ground/Runner tabs |
| **F** | **Reqs by pulse** (Hovercraft) | one req held by `%TheAWait` instead of a ttlilt, then the rest | 56 ttlilts | its Book byte-identical |
| **G** | **The pile as a landscape** (owner 2026-11-03, replaces porting a music organ) — **its own doc now: `Pile_todo.md`** (the showroom for Atheory, with the intro) | a filesystem listing (local FSA or remote mount) drawn as a floaty space; then a Heist setup that shows what is already where it goes and offers the user's OWN categories; then a merge page: a second FSA's download pile listened through and dialled into the collection, a long workflow kept over sessions | — (the first app built on the fabric) | a Book per rung |

**Progress 2026-11-03 (afternoon).**  **A BUILT** — every think for a shut House is kept at the door as a row (`c.door_rows`), both
 Storys open/shut it, Run trace `door think×N`.  **B's root BUILT** — the drain drives itself (a push microtasks `answer_calls`, the gate
  timer comes back while rows wait); 🐕 and 📭 stay as alarms and fired 0× across ~280 runs.  Found on the way: the morning's merge fix
   merged no aimed think (a named elvis always carries `to_A`) — HohoWaftMap piled 1480 thinks; corrected.  **C, first part BUILT** —
    `Story_at`/`story_sel` knock their holder unthrottled; a step that ends on its ttlilt is ok WITH A CAVEAT (1 of 139 Books: VytoMemo
     step 4).  **D slice 2 BUILT** — `runner_ask run --desk` lands as `%Job:<Book>,n` on Mundo's `A:Runner/w:Runner`; the Runner's think
      stands a fresh Desk and releases the last (Ground.g `Runner`).  Sweeps: Athe* 42/42 normal; `--desk` 127/137 — red on both paths:
       SwarmGot, MusuMag, MusuReco, and MusuBuddy/Ogg/Reap/MusuMag's Preview `cid`s (every chunk hash moved, deterministic — the
        browser's encoder or /music, not timing); red only on `--desk`: MusuRadioAim (friends "did not come online"), HohoWaftMap and
         MusuRaStream NEVER STARTED.  HohoWaftMap's fixture is stale anyway (lists src/lib dirs culled 2026-09-16).  HohoNets/HohoSurprise
          re-accepted (a `see:lies` line the fixtures caught mid-drop).  Then the `--desk`-only reds: MusuRadioAim FIXED (`Story_replaying` now looks in a Desk too, both
           Storys — the live 'gave up' leaked in); MusuRaStream did run all 40 on the Desk (its known `now=` red) — the sweep called it
            NEVER STARTED because the Desk run's phase sat at `begun` while every step went red (a reporting gap, owed); HohoWaftMap is
             stale.  So **the Desk runner is at parity** with the page Story: E (the Desk is the page) is unblocked.

**E thought through (2026-11-03 evening, owner: "/Desk?I=...&G=Runner should do it! lowercase that for a role name, but allow
 Ground to define its own, as well as lots else").**  One page, `/Desk`, two knobs: `?I=` WHO (an Identity), `?G=` WHAT it stands on
  (a Ground).  Everything else a tab is told, or its Ground declares.

 *What the knobs replace* — today a tab's kind is smeared over 9 knobs: route (`/Otro` `/BigSoundland` `/BigWordland` `/BigShapeland`),
  `?A=` toplevel, `?B=` `?E=` `?H=` (the letter IS the role), `?I=` alone (= idle runner), and five `H.c` stamps (`boot_role` editor|runner|daemon,
   `role:hacker`, `id_role` word|sound, `humdinger`, `book`).  The ack's role (runner|player) is derived from those.  The map:

 | today | on a Ground |
 |---|---|
 | `/Otro?I=x` (idle runner), `?B=Book` | `/Desk?I=x&G=Runner`; Books arrive as `%Job` (D) — no `?B=` |
 | `/Otro?E=Editron` | `G=Editor` (later; the frozen spine rides it — last to move) |
 | `?H=`, `/BigWordland` | `G=Land` (role hacker) |
 | `/BigSoundland`, `/` | `G=Music` (role player); `/` stays a mount of it for the invite links |
 | `/BigShapeland` | `G=Glass` |
 | daemon | `G=Daemon` — a runner that claims no role (Auto's own comment: creduler without the seat) |

 *The Ground's toc carries it.*  `wormhole/Ground/<Name>/toc.snap` already is a row shape (`Ground:Music … / Load:… / Beside:…`).  Add:
  `Role:<r>` (default: the name lowercased — Runner→runner), `Main:<A>` (the A the page runs from — Runner's is `A:Runner`, the one D built),
   `Face:<svelte>` (what the page mounts), and the knobs that are now `H.c` stamps (`Seat:none` for a humdinger/daemon, `Audio:aim`).
    Mundo then holds ONE row, `%Page,I:<prepub>,G:<Name>,role:<r>`, and every `boot_role ===` check reads it.  HAND-KEPT (owner: "shouldn't you be hand editing the Waft-like structure of the Ground? these generate-the-list scripts are quick to become obsoleted"): `wormhole/Ground/Runner/toc.snap` is written by hand — `Stands:Story`, `Main:Runner`, `Role:runner`, nothing else; every Book's code comes in by that Book's own `Stands:` when its Job runs.  The floor keeps reading Core from the bake (it has no wormhole yet); every other Ground is read from its toc.  everything.js only writes the Grounds it derives and never deletes one, so a hand toc survives it — its Ground half retires as the derived tocs get hand-kept one by one.

 *Two kinds of Ground, one shape* (owner: "many Ground/* are partitions of code we might load separately, but they are also whatever we
  might pack into a single executable|interpretable|docker-compose-but-for-this-paradigm").  A **partition** (Music, Glass, Swarm, Wire) only
   loads code.  A **composition** stands on partitions and says how to RUN: `Main:` (repeatable — a daemon might run `Main:Runner` and
    `Main:Music` side by side, like compose services), `Role:`, `Face:`, `Seat:`.  Having a `Main:` is what makes a Ground bootable;
     `?G=` refuses one without.  Its closure (`ground_closure`) IS the pack — the list of code plus the run rows — so the same toc that a
      tab boots from is what you'd bake into one interpretable bundle (`grounds.gen.js` is a first, code-only bake of it).  Naming habit
       open: compositions named for what runs (Runner, Daemon, Player), partitions for what the code is.

 *Running from a Ground*: `/Desk` boots a bare Mundo, the floor (`ground.ts`) loads Core + the closure of `G`, `Ground_stand` says it as
  particles, then stands the `Main:` A — and the page is that A's think.  Auto splits along its own regions: identity (`?I=` ensure / arrest /
   adopt / mirror) → an `A:Identity` every Ground stands under Main; the Creduler Lies + Supervisor + keep-awake → `Ground/Runner`; the Library →
    `Ground/Music` (or nowhere).  Auto stays for `/Otro` until the fleet is green on `/Desk` tabs, then retires.

 *Slice 1 (proposed)*: `src/routes/Desk` + `wormhole/Ground/Runner/toc.snap` (`Role:runner`, `Main:Runner`, stands on Story) + `%Page` on
  Mundo; Auto still runs underneath for identity + Creduler, but reads role from `%Page`.  Gate: `runner_sweep --desk` on a `/Desk` tab at
   parity with today's 127/137.  Slice 2: identity out of Auto into `A:Identity`.  Slice 3: Creduler/Supervisor into Ground/Runner; Auto off
    `/Desk`.

 *Slice 1 BUILT + LIVE 2026-11-03* (the owner's tab `/Desk?I=e747…&G=Runner`: Mundo holds `%Page,G:Runner,role:runner,I:e747…/%Main:Runner`, `A:Runner` stood at boot; AthePondRounds, AtheStoryInStory, HohoKeep green with NO `--desk`, each a `%Job`.  Found on the way: a Desk run never reported `step_done` — StoryFu `runner_phase` dropped every phase of a nested Story, the runner's own Desk Story included — so `runner_ask` gave up on any Desk run longer than RUNNER_BEGUN_MS (MusuRaStream's 'NEVER STARTED'); fixed by `w.c.report_up`, MusuRaStream now runs 40/40 (red only on its stale `now=`)): `src/routes/Desk` (mounts Otro); Otro reads `?G=` → `H.c.ground`, boot_role = the name
  lowercased when that is runner|daemon (the bootstrap: Core stays hard-wired in the bake until a toc is readable); `ground.ts` learns read
   Grounds over the bake (`ground_learn`/`ground_read`/`ground_role`/`ground_from_toc`); Auto `auto_ground` reads
    `wormhole/Ground/<G>/toc.snap`, stamps `%Page,G,role,I` + `%Main` rows on Mundo, includes Core, stands each Main's A; LiesFunk
     `Lies_page_runs('Runner')` makes every Book on such a page a Desk run (as `--desk`).  The Ground's `Stands:` is NOT included on the
      page — Story stands aside in each Desk (Desk_story), and each Book's own `Stands:` brings its code.  Gate: `runner_sweep` on a
       `/Desk?I=…&G=Runner` tab at parity with `--desk` 127/137.

 *Slice 2 BUILT + LIVE 2026-11-03*: Auto's whole who-am-I region (?I= ensure, arrest, legacy adopt, role default, mirror) is one method,
  `identity_settle` (Auto.svelte); on a `?G=` page it is `A:Identity/w:Identity`'s own think, which says `%Who:<prepub>` (or `%Arrested` while
   the IdHatch waits), and Auto holds the rest of its think until `%Who` stands; every other page runs it inline as before.  The owner's tab:
    `Who:e747cbed6a9ca919`, 3/3 green.  Next (slice 3): the Creduler Lies + Supervisor + keep-awake out of Auto into Ground/Runner — then Auto
     has nothing left to do on a /Desk page.
  *Slice 3, re-aimed (owner 2026-11-03: "shall we sublate Auto into something else? leaving it behind until the Music app at / is
   ported, then it can delete. but copy Credular etc out … perhaps Supervisor wants writing in the light of Atheory")*: don't move out of
    Auto — COPY out.  Auto stays as it is for `/`, `/Otro` and the Big*land pages until the Music app at `/` is ported onto a Ground;
     then it is deleted, not refactored.  Ground/Runner gets its own Creduler — and the Creduler and TheACode must sync up first: the
      Creduler loads the spine through its Lies and keeps `%GhostInclude` rows, while an A holds its code as `%TheACode`/versions
       (Atheory_design §1.2–1.3) — two ledgers of "what code is live" that a Ground/Runner page should keep as one.  Supervisor is
        rewritten, not copied, in Atheory's terms (a Seem over the runs? its roster as rows) — design pass with the owner.  Keep-awake
         copies as is.
  *Slice 3a BUILT + LIVE (2026-11-03 night) — the spine is the Ground's.*  `wormhole/Ground/Runner/toc.snap` carries hand-kept
   `Spine:` rows (WireTesting MusicTesting CaveTesting SwarmTesting GlassTesting + two lone .g no Ground wears yet: ErrchannelTesting,
    Supervisor).  On a `?G` page the Creduler loads THAT (LiesLies `Creduler_ghosts` → ground.ts `ground_spine_paths`: closures, Core
     first), holding pending until `auto_ground` has read the toc and woken it; elsewhere it is still `CREDULER_GHOSTS`.  Once loaded,
      A:Runner stands those Grounds (Ground.g `Runner_spine`), so what's live reads as `%TheACode:Ground/<Name>,dige` on A:Runner — the
       rows a Desk's A carries — beside the per-file `%GhostInclude` rows on the Creduler's w:Lies (which ARE the include door's shelf:
        already one per-file ledger).  33 includes live; 12/12 runs green across the Grounds.  **The arc:** the Spine shrinks as Books
         say their own `Stands:` (171 tocs still don't) until Runner points at one Ground and the run-Book verb brings the rest.
   Found on the way: on a Desk, a Book's `this.Story_error` (flat Story.svelte) rang on Mundo while the nested StoryFu drained its
    own House — ErrChannel red.  The flat door now homes on the nearest House a run marked (`err_run`); page runs unchanged.
   *Same night, owner "yes" to Credulate + "Stands would say which test code .g it uses right? so we can stop including all that
    everywhere?"*: **106 Book tocs gained `Stands:<X>Testing`** (recipe file → its Ground; scratchpad `stands_map.mjs`).  **Credulate
     records the Book's code as Grounds**: `%TheACode:Ground/<Name>,dige` per Ground in closure(Story + its Stands), digested as Theory
      does (Auto `Cred_book_code`; the diges match A:Runner's rows), and its `%GhostInclude` rows narrow to those Grounds' files; the
       trail's runs and `last_ok` carry the Ground rows too.  Off a Ground page (no Theory) it records every ghost, as before.
   **Test Grounds still to make (owner: "a few different test Grounds … containing fairly huge piles of code — like anything Radioey,
    anything Appey, anything Voroey")**: the Books whose recipe isn't in a `.g` — Hoho*, Leaf*, Understand*, Snap*, Stuff*, Engage
     (`test/Machinery.svelte`), Educarium — ride `.svelte` test ghosts every tab mounts; and the big app-side piles (Radios.svelte & the
      radio UI, the App/Big*land page code, the Voro svelte side) are mounted everywhere too.  Each pile wants a test Ground the Books
       that need it say they stand on, so a tab mounts it only then.  Needs: the floor loading a `.svelte` ghost (today `ground_include`
        loads gen `.go` only), and a hand-kept Ground being readable by Story's loader (today only the bake + what auto_ground learns —
         why ErrchannelTesting still rides the Spine as a lone .g).
   **The Spine trimmed to `Wire` + the two lone .g** (10 files flat, was 33) — every other Ground now comes by a Book's Stands.
    It showed the test Grounds are TANGLED: Music/Cave/Swarm/Wire Testing call into each other (MusuPier needs PeerTesting's `Lake_link`;
     scratchpad `xref.mjs` lists every cross-Ground `this.X`), while Glass/Core/Land Testing need only Story.  So the 80 Books of those
      four stand on all four (`Stands:WireTesting` `MusicTesting` `CaveTesting` `SwarmTesting`) — the first "huge pile" test Ground,
       spelt out per Book until a hand-kept Ground is readable by Story's loader (then one `Stands:Musu`-ish line).
   **AtheoryArrive — TALKED + slice 1 BUILT 2026-11-04: now its own doc, `AtheoryArrive_todo.md` §0 (read that, not this brief).**  The outcome is a new
    `AtheoryArrive_todo.md`: startup top-down in Atheory terms — arrival as an Identity standing on a Ground, told as rows (%Who,
     %Page, the Spine, the Mains up), the splash as the Ground's Face reading them, the Supervisor saying arriving|stuck|finished off
      them.  It absorbs `Arrival_todo.md`'s arrival authority (2026-08-31, old-generation parts) and the Supervisor laws; Arrival_todo
       goes to history/ once absorbed.  The old Story retires only after `/` is ported onto this (AtheoryStory_todo "The arc").
    A TALK, not a build: the
    owner wants the paranoias aired about tracking a program's overall state "from the outside or the top", for guiding what the
     splash page says while a person waits.  Read first: `Supervisor_todo.md` §0 (the two false sentences), §2 (slow vs stuck), §4
      (two tiers — in-tab outside the belief loop; the daemon "above", NOT BUILT), §8 (who decides depends on who watches);
       `Ghost/O/Supervisor.g` header (the laws); BigSoundland's boot badges (`spine_pending` &c., the splash it already has).
    The laws it already keeps, to carry over or break on purpose: it never names what it watches (watches ARRIVE from their owners —
     the roster is the coverage); it lives on the top House so it can say "the run died"; it works with no glass; a probe may not
      mutate; milestone (latches) vs standing (never latches); elapsed time can't tell slow from stuck — only monotonic progress can;
       a give-up must never contradict the evidence beside it; "posted" is not "entered" (one surface short keeps a fixed diagnosis
        unfixed for the person looking).
    Atheory angles to bring: decide from rows, not signals (a watch is a row that progress ARRIVALS touch, not a timer that polls);
     As report up (Story's `report_up`, `%StoryAt`) — is the roster just what As standing in As already say?; nearness (a watch is
      read by the nearest Supervisor out, so a Desk could have its own); is it a Seem over the runs; where it stands on a Ground page
       (A:Supervisor as a Main? the Ground's `Face:` is the splash?); the "top" is itself an A that can die — who watches it (tier 2).
    Not forgotten while doing it: StoryFu is the Story that stays (Ground/Story, aside in each Desk); Story.svelte and Auto.svelte
     go, and most of `/O/` is ported or rebuilt in time — so nothing new should land in them except as a bridge, said so (last night's
      `Story_error` home walk in Story.svelte is one such bridge: until a Book's `this` reaches StoryFu through its A).
   **Diffmatication + Interesting marked `unusual:rethink`** in Credence (owner: random projects that proved we need more Atheory first).
   **Low need, left here (owner 2026-11-03):** the recipes — each makes its own `A:<Book>/w:<Book>` (one name said twice) and
    defines the `<Book>(A, w)` method the w runs — could be reimagined: how a Book's actor comes to stand, and where its think lives.
   **Next (3b):** stand the Creduler Lies, keep-awake, Supervisor and the storyFinished → `Cred_spool`/verdict from A:Runner instead of
    Auto on a `?G` page (the Lies stand is floor work — it precedes Core); Credulate records the Desk's `%TheACode` Ground diges
     beside its per-ghost rows (churns every Credulate file — owner's call); Book tocs gain `Stands:` (mechanical: recipe file → Ground).
  *Sweep on the /Desk tab, 2026-11-03 evening*: 139 Books — 125 ✓, 3 flake, 11 ✗, 0 hollow, 0 never-started (was `--desk` 127/137).  Baseline reds now
   green: HohoTiles, VytoBunch/Mitosis/Seek/Staple/Freeze.  Still red, known: SwarmGot, MusuMag/Reco/Buddy/Ogg/Reap (cid drift), MusuRaStream
    (`now=`), HohoWaftMap.  New: SwarmWire (its witness ran before the Piers' inbox reqs landed beat 4's frames — now witnessed in a post_do
     after the pass, 4/4 green); MusuRadio + MusuTune REFUSED — the tab's AudioContext lost its gesture to my reloads (environment).

 *Off to the side — one Identity in two tabs* (owner: "should be possible and sane somewhere around here").  Not sane today: the relay's
  `bind()` is additive and `deliverLocal` fans out, so two tabs on one prepub each get every frame, and both answer (the "two of you" hazard,
   memory doorkeeper-and-two-of-you).  The sane shape is the Crew one: the Identity is the soul, a tab is a **seat** — `%Seat:<n>` under the
    Identity, addressed `<prepub>/<n>`, the relay delivering `to:<prepub>` to the seat that claimed it (or the Crew's choice) and `to:<prepub>/<n>`
     to exactly one.  Needs a relay change, so its own slice after E; E only must not assume one tab per Identity (put the seat in `%Page`).

A→B→C is the "decide from rows" migration (disk replies, Story steps, clicks, then the ambient tick — that last step is where
 Housing's wake paths get deleted).  D and E ride on it; F is the same move in Hovercraft; G is the app the fabric is for: explore a pile, then merge a giant download folder into the collection with guided, mechanical moves.

**Loose ends, small, any time** (none blocks a frontier): the `stop()` diag in Housing (temp); the drain-wedge root (the dog stays
 the alarm until A); `mode:new` picked before the toc read lands; Stands inferred from the Credence row; the 8 Desk-runner reds
  (HohoTiles, HohoWaftMap, Vyto Bunch/Mitosis/Seek/Staple/Freeze); `%Clock` in place of `w.sc.now`; HohoNets' verdict; TimeSpool
   and Credulation churn.  *Checked 2026-11-03:* MusuOgg has no revert damage (no diff).

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

## 1b. The old machine, Atheorised — part by part

*Started 2026-11-04 (owner: "where we shall track which parts of the old machine are becoming Atheorised").*  One row per part of
 the old machine, what it becomes on the new fabric, and how far along it is.  Add a row when a part starts moving; move its status
  as it does; delete nothing (a part that's fully gone says so).  The land map (§0.0) is the picture; this is the list.

| old part | becomes | status | where |
|---|---|---|---|
| `/Otro?I=`, `?B=`, the nine knobs of a tab's kind | `/Desk?I=<who>&G=<Ground>`; a Ground's toc says how to run | slices 1–2 built and live | §0.0 E |
| Auto's who-am-I region | `A:Identity`'s think (`identity_settle`) saying `%Who` | built (slice 2) | §0.0 E |
| the GhostList spine + everything.js bundles | hand-kept `wormhole/Ground/<Name>/toc.snap` read by `ground.ts` | in progress: Story's loader still reads only baked Grounds; a Book's `Stands:` takes a lone `.g` (2026-11-04) | §0.0 E, `Pile_todo.md` §0.0 |
| Story.svelte | StoryFu on `A:Story` in a Desk | working proto; the twin tax until Story.svelte retires | §1, `AtheoryStory_todo.md` |
| Stuffing | Stuffica views | Show built; In and Out not | §3.12 |
| Hovercraft reqs, ttlilt, `feebly_ponder` | rows waiting: `TheA_run`, synapses, `%TheAWait` | toy, proven by hand | §0.0, §1 |
| Wormhole disk replies (a signal) | an arrival row | not started | §0.0 |
| **LiesStore** (w:Lies' IO: known digest, skip an unchanged write, reads on a `%Good` that wakes its subscribers) and **Heist's Berth** (a named toc.snap per Waft, parts appended) | **the storage reflex — an Atheory-era `%Good` portal**: `Ghost/A/Store.g`, `%TheAStore:<path>` on a stored Mag, one `%TheAStoring` Job per changed Mag after a run, a read handed back as an arrival.  Calls neither ancestor | **prototype built 2026-11-04** (`Ghost/A/Store.g`, proven by Book PileWalk on a memory nav: write, reload, same ids back, unchanged Mags not rewritten).  Still owed: a real nav (the app tree), the write as a run-tail Job, one-writer claim.  LiesStore and the Berth stay as they are until something moves onto it | `Atheory_design.md` §1.15, `Pile_todo.md` §3 |
| the House stash (one Dexie blob per House name, whole-blob last writer wins) | maybe the storage reflex, one file per stored thing | open | `Pile_todo.md` §3 "Beside the radio tab" |
| the `%Crate` tree / the Stoker's disk read | the disk becomes a Mag as it's read: Pile's fs Mag, kept by a Seem, ids that survive renames and moves | rung 1 built flat; the reshape to partitioned Mags owed | `Pile_todo.md` §0.0 |
| Funkcion (Waft's little UIs) | not carried over; a control is a row on a Mag | ruled for `Ground/Pile` 2026-11-04 | `Pile_todo.md` §3 |

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
