# Atheory_todo.md — the next rebuild of Housing (that's just A**)

A capture doc, not yet a plan — the owner has reached for this three times in one session
 (2026-08-28), which is the tell it wants its own plot:

- *"we have random lists of .go to include somewhere too... we really need to rethink how code
   loads onto the base Housing, shall surely be Atheory (the next rebuild of Housing thats just
    A**)"*
- *"perhaps we should redo the toplevel? must be a ton of crap built up now huh? could be so much
   simpler and easier to moonwalk through these such transpirings?"* — said while reading a boot
    log of the world-1-destroy → world-2-mount churn at storyFinished.

## 0.0 START HERE — where it stands and what's next (2026-10-21)

**Where it stands.**  `Ghost/A/Theory.g` runs compartments: an A holds its code (`%TheACode`), code is pushed and let
 through by Story (CodePush), and a batch is **moves then the boundary** (`TheA_move`, `TheA_send` into `%TheAOutbox`,
  `TheA_boundary`), each move committing a `%TheATurn` to a history that readers trim.  The toy (`AtheFishTesting.g`) is
   only handlers.  11 `AthePond*` Books are green, and every oath was sabotaged once and bit.  The words are
    `Atheory_design.md` §0, and what's built is §1.

**Ruled 2026-10-21 (owner):**
- **Synapse + Axon** replace wire + outlet ("might as well have science"): `%TheAWire` → `%TheASynapse` (held by the
   receiver, says `wake`, `sum`, `from`), `%TheAOutlet` → `%TheAAxon`.  Reason: "the wire" already means the network
    (Waft:Everything's first What; about 50 files say "over the wire").  **Not done yet — first move below.**
- **One event particle, in the background.**  Elvis and pulse are one idea seen from two ends (sender-addressed vs
   receiver-declared).  The theme: a single transcendent event particle with subtypes, an elvis that shows on the tree.
    Review the pulse interface toward that; don't rip elvis out meanwhile.
- **Atlas is the claim, Electrode is the evidence** for the manifest check: observed ⊆ predicted ⊆ declared, and where
   Electrode saw a call Atlas didn't predict, that's Atlas's blind spot (dynamic calls), shown on the tree.
- **Book proofing goes to subagents after a hacking stretch**, not during it: a compile hot-swaps the runner's ghosts and
   breaks a run in flight.

**Next moves, in order:**
1. The Synapse/Axon rename across `Theory.g`, the toy, `AtheTesting.g`, `Atheory_design.md`; then re-record the Books whose
    snaps show the names (WireSum, WireOrder, Stream, Loop, Turns, TurnReaders, SunpitPassOrder, SunpitFrontier, WakeOrder —
     the ones that stand wired tanks).  Particle names change, so `tol:same` won't cover it.
2. **Resisting CodePush during a run.**  Story already holds pushes for As in a run until the step seam.  What still breaks
    a run is code NOT loaded through `%TheACode` (the routines, the runner's own ghosts) hot-swapping mid-step.  Once
     everything a Book runs comes in through `%TheACode`, compiling during a run becomes safe — the push just waits.
3. A Book that shuffles move order at random every run (the boundary says order can't matter; prove it continuously).
4. CodePush with a visible effect — needs the A** shape (two versions in one heap) so a Book can push the second.
5. Owner-gated: candidate 2 "unwatched work costs nothing" (touches Housing); the manifest check (Atlas × Electrode, as
    ruled above).
- *Aside, being looked into:* in BigWordland's Lies tree only Waft:Ghost/Net/Easy of Waft:Everything's area Wafts loads.

## 0. What this is about

*2026-10-20 — §0.1 below is the current sketch and the owner's rulings; read it first.  What follows here is the
 original framing.*

*2026-09-08 — read `Wordland_todo.md` first: it is where this doc's A\*\* shape, Atlas (what the code says)
 and Electrode (what it does — built that night) are read together.  Electrode's `join` gives the
  static border measurement below its MEASURED twin (one Book run: 379 declared call pairs, 202 ran), and
   the ROLE dimension of the manifest question a measurement instead of a static floor.*

Two irritations, probably one rebuild:

1. **Code loading is random lists.**  Which `.go` ghosts mount is scattered hardcoded lists
    (LocalGen's GFILES default list is the compile-side twin of the same disease — a list you
     forget to be on is a silent absence).  Atheory would make loading DECLARED — the base
      Housing (`A**`) knowing what belongs on it, legibly, the way everything else in the world
       is legible matter.
2. **The toplevel has built-up crap.**  The app's boot IS a Story Book (`Sounditron`, run in check mode on
    every music page), so app behaviour that lives in "beat N" exists only if the run reaches N.  The
     cold-boot disease (Solo_todo bombs) was that, and its patches are sediment.  A simpler toplevel would
      make those seams walkable ("easier to moonwalk through these such transpirings").  *Corrected
       2026-10-18 — the old wording here (a world-1→world-2 remount at storyFinished; an un-buffered `cyto`
        derive balanced on it) does not hold today; see "Progressive startup" below.*

## 0.1 The sketch (2026-10-20) — read this before the case studies

*The owner and a session worked through a 100-sentence gist and two rounds of rulings.  This is what survived:
 settled where it says settled, candidate where it says candidate.  The sections further down are the evidence
  it rests on; where they disagree with this, this wins.*

**Scope first.**  The music app rests for a while.  The next non-architectural work is **tests for the Atheory rebuild
 itself**; rebuilding parts of the music app on it comes later, as rebuild terrain.  Slotting a new layer in must keep
  every existing Book working.

### What it is, in one breath

The next Housing.  Code and time become matter like everything else: which code runs where is a particle on the A
 that holds it, and every change is a recorded event that advances a version.  It spreads space out and loads code
  more efficiently first; harmonising all IO with it (IOexpr, streams) is the next wave, and it looms.

### Code, and who finds it

The A\*\* shape below (`TheA_<Name>_<Variant>_<dige>` prototypes) is how code would attach to an A.  What the A can say
 about its code today is **which files it runs and their digests** (`%TheACode` → `%TheALayer`, slice 1).
- **No method lookup of Atheory's own** (owner, 2026-10-20, after a day of goofy code chasing one).  Code calls methods by
   name; req dispatch stays in `do_fn_for` (Hovercraft), predictable: `req:Fish` is the kind, and that particle is two
    Classes at once.  In `Class_Aspect` the Class is any key a particle carries (`req_Pier` is Class `req`).
- **Joining data to code in general is the Sunpit's job**, much later.  How to get from everything to the Sunpit is open,
   and may involve leaving traces around while everything runs.
- **Clobbers are state.**  Two layers defining one name is shown (`%TheAClobber`, with whose copy won), never a silent
   own-property mask.  Later, a space mirroring `Ghost/*/*` where versions written out form trees and branches, like git.

### Spheres — what hangs off a particle

Seem holds them (not yet renamed Merge).  **Candidate names: Said / Held / Was / Regard** (owner: yes, as working names).

| | is | written by | tense | lives |
|---|---|---|---|---|
| **n**, Said | the particle's `sc`, what it says | its owner | present | as matter |
| **D**, Held | the resolved alignment: what the machine believes n's shape is (`resolve()`) | the Se | present | per walk; the seam everything else attaches to |
| **K**, Was | this point's past, as its own keeper remembers it: last pass, last send, last accept | n's owner | past | chosen: Repli's last-sent must survive reload |
| **O**, Regard | this point's present, as **another** organ sees it: Vyto's placement, a want's parked-ness | another organ | present | that organ's life |

The test for any `.c` entry is two questions: *whose is it, and which tense?*  Neither K nor O → a finger (an edge), flesh
 (an organ's handle) or a run's scratch.
- **n and D are under the hood** and carry the basis key all through.  **K and O live in `%OtherSphere:'<label>'/*`**,
   which IOexpr makes programmatically, one per organ (`OtherSphere:'Vyto'`); they don't need the basis key at every node.
- **Holsters.**  A C that keeps its contents out of the enclosing machinery's meaning: `Room/Box/Cat`, so the Cat isn't
   read as a `Room/Cat` beside the others.  Name each one for its use, not one generic word.  The designed Sunpit
    (`w.c.sunpit`, off the H\*\* walk) is one, **designed, not built** (`Vyto_sunpit` returns `null`).
- **Open: snap filtering needs its own look.**  A snap is "everything reachable from H\*\*".  Spheres want hiding by
   default even when D sits on n, so they need a place the walker skips: tucked behind n, or an OtherSphere with a no-snap
    mark the encoder honours.

### Versions

- **Code: an A's version is a digest over the digests of every `.go` on its chain.**  One name for the whole, and you can
   still see which file moved.  (This replaces the per-ghost vs per-closure question in "Open decisions" below.)  The
    Variant slot keeps an instrumented build beside the clean one.
- **Data: per compartment.**  An A or w advances a version when, and only when, something beneath it changed, and the
   version names its event: which pulses, under which code digest, by whom.  A buffer changing is a version too.
- **Time is versions.**  Wall-clock milliseconds are recorded but hidden (on `.c`), and Story imposes a grid that folds
   "when" into steps for snaps.  Not yet coherent; expected to settle when we get to it.
- **Schema changes ride the code wave.**  A code version carries its migrations as data ("this digest renames key a→b
   on mainkey X"), and code gossip delivers both.  A fracture names the digest it was written under, so a receiver can
    migrate it.  Extra credit: migrations reach disk lazily (applied on read, written back on the next save).
- **The compile authority never runs the code it compiles.**  It blesses a version as real and pushes it with its
   migrations.  Editron holds it now; a headless compiler later (`Editron.md` §8.2 B).

### The scheduler — elvises in space and time (candidate; the sketch to grow)

- **A pulse is addressed to a compartment** (an A or w), never to "the House", and in time by the versions it needs, not
   a moment.  A pulse whose causes are present is ready.
- **Summed per compartment.**  Ready pulses of one kind to one receptor merge into one wake.  Precedents, both working:
   the wants accumulator (`Lies.svelte:75`, `w/{req:'wants'}` piling up cursor intents for one desire) and Vyto's
    plain-form drive (watch each source, coalesce the trailing edge, one scan per burst, never inside a beat).
- **One batch, one pass, one version.**  Compartments that share no wires can run in any order; those joined by a wire
   run one after another along it.  The wire-tree (`Wire_spec.md`) is the space-flow map, and responding to a change is
    a lookup in it, not a broadcast `think`.
- **Sunpits iterate.**  An IOexpr row compiles the way `oai … + block` compiles to `doai`: the compiler emits a cursor
   (`.more()`, `LangSolver_report`'s `_io_cursor`) plus what it can see statically (which sources it reads → its watch
    list).  At runtime the Sunpit pulls rows and lands each by find-or-create, bumping only on real change.  Its version
     is how far it has read plus how many real changes it landed.  Sion's flock planner (plan many IOings together,
      knowing the entanglements) may be the same organ as the scheduler, at compile time.
- **Priority** comes from the will (`Emotion_todo.md`): nearest a strong, unsure will first.  **Backpressure** is a slow
   compartment holding its batch open.  A ttlilt may grow an alarm.
- **Isolation:** one heap is fine for now.  Two code versions in one tab are two prototypes over one House; real
   isolation (a Worker, an iframe, ShadowRealm) is possibly improvable later and is not this rebuild's job.

### Scopes, effects and the live|replay wall

- **Find services in the nearest enclosing scope.**  The MusuRadioAim leak was a lookup going to `top_House()` for "the
   Supervisor" and finding the runner's own.  With lexical lookup, a Book's Run world sees its own Supervisor, and the wall
    is the world boundary.  Supervisor and Story stack: both are expectors over a runtime; the Supervisor only watches,
     a Book may also drive.
- **The two hand-placed gates this replaces.**  `top.c.humdinger` (`BigQualand.svelte.ts:121`, 2026-07-12) marks a
   Big\*land room as an end-user page, never a dispatch target, so it isn't enrolled as a runner; it predates the richer
    roles and is a candidate to fold into role.  `Story_replaying()` (`Story.svelte:2170`) is true while any Book in the
     tab is stepping, and live readers go inert on it; it is tab-wide, so it silences live code the Book never touches.
- **Effects are addressable.**  Audio, WebRTC, disk and the relay are organs.  Show what breaks when we time-travel, and
   let a replay say which organs to mock, as a property of the system rather than a gate per reader.

### Authority and turfs

- **Turfs** (a wormhole path, a compartment) are mutexed by a lease held at the relay, generalising the editor's write
   seat (`Editron.md` §8).  Ask the relay for your other selves once, when acquiring; renew by heartbeat; write locally
    while the lease holds.  Only acquiring waits on becoming the single writer, which FSA writes need anyway.
- **Rules are particles**, in the shape Portability 2E found: the mainkey is the discipline, the value the role
   (`%SingleWriter:Captain`).  Rule engines decide which legs of an A may do what, and a person can read the rule graph
    instead of a stack trace.
- **Signatures are a scope above Seem.**  Crypto among Piers is the ultimate authority system and belongs to the wire
   and the crew.  `by|rule|hid|pass` is a different thing, where a quality came from, and its home is the Voro processor
    built as an organisation of Seems (Cstructures §3 is vague inspiration, not law for all of Seem).

### Rollback — to study

`replace()` isn't really reversible.  The likely shape: **an A knows how much C\*\* and process it must re-synthesize from
 a resumable point**, instead of transacting everything.  Restart bigger chunks of the program.  Study before choosing.

### Knowing the manifest is true

Atlas knows what the code says it calls; Electrode records what ran.  A Book over that join, against the declared
 manifest, reds on two complaints: **declared, never called** (today 22 of the 36 `CREDULER_GHOSTS` load on every
  music page, mostly Story `*Testing` code only some Books use) and **called, undeclared**.  Then a manifest can't go
   stale without someone hearing about it.  Test code should hot-load too.

### Asked and answered (2026-10-20)

| question | ruling |
|---|---|
| sphere names | Said / Held / Was / Regard as working names |
| the holster's name | one per use, named for what it holds |
| code digest scope | a digest over the chain's file digests (above) |
| isolation | one heap; note it as improvable |
| Atheory's tests as IOexpr recipes? | undecided; wants the scheduler sketched further first |
| where this doc lives | stays in `O/spec`; Atheory code lives in `Ghost/A/` (`Theory.g`, `AtheTesting.g`) |
| who looks methods up (2026-10-20) | **not Atheory.**  Code calls methods by name (9,487 direct `this.X_y()` calls in `Ghost/`); req dispatch stays in `do_fn_for`; the Sunpit, much later, is where data and code get joined in general.  An attempt at a handler table (`%TheAHandles`) was built and removed the same day: it made goofy code. |

**Ruled 2026-10-20 — the toy gets its own testing file, `Ghost/A/AtheFishTesting.g`** (loaded as modular A code
 inside a test; never by real applications).  A Book's snap holds two As: the routine (`A:<Book>`, code in `AtheTesting.g`,
  where `req:wrangle` does the thinking) and the toy it tests (`A:Athe_Tank`, whose `%TheACode` names only its own file).
   The routine calls across into the toy.  The name ends in `Testing.g` so `src/lib/L/testing.ts` marks it as test code.

**Still open:** snap filtering for spheres; rollback; time beyond "versions + a Story grid"; whether Sion and the
 scheduler are one organ; the next wave (IOing in harmony with all this).

## 0.2 The sketch, continued — shapes, one pass, the first tests (2026-10-20, all candidate)

*Every name here is a candidate for the owner to rule.  The worked example is `Ghost/Play/Pond.g`: one world on a
 700ms clock, eggs and fish and a heron, rules that push on each other.  Small enough to hold in your head, and
  already a Workshop creation, so a Book about it is the kind a kid would copy.*

### The names, each one meaning

| name | means | lives |
|---|---|---|
| `%TheACode` | which code this A runs: `TheACode:<Name>,variant,dige`; dige = the chain digest (absent until every layer loads) | on the A; snaps (for now: owner, 2026-10-20) |
| `%TheALayer` | one compiled `.g` on that chain, with the digest of the code loaded for it | under `%TheACode`; snaps |
| `%TheAClobber` | a method two of the A's layers both define, and whose copy is live (`won`) | under `%TheACode` |
| `%TheAWire` | a standing pathway: where pulses run and what they wake | on the compartment it wakes |
| `%TheAPulse` | one elvis waiting on a wire | in a holster on the wire; never snaps |
| `%TheATurn` | one pass of one compartment: the batch it ate, the version it made | the compartment's history; Was-sphere |
| `%TheATurf` | a leased region one writer holds | at the relay, mirrored on the holder |
| `%OtherSphere` | a non-basis sphere (Was, Regard), one per organ | on the compartment; skipped by the snap unless declared |
| `%Sunpit` | an iterating gathering of sources, compiled from `%IO` rows | on the world that commissions it; a holster |

### The A, holding its code — slice 1 BUILT 2026-10-20 (Book `AthePondCode`)

```
H:AthePondCode,Run
  A:AthePondCode                       the test routine (every Book runs inside an A named after it)
    w:AthePondCode
      req:wrangle,eternal,ok
  A:Athe_Tank                          the toy it tests (Athe_Tank, not AtheTank: Books match Athe[A-Za-z]+)
    TheACode:Athe_Tank,variant:plain,dige:…
      TheALayer:Ghost/A/AtheFishTesting.g,dige:…
    w:Athe_Tank
      Turns,count=4                    the tank's own clock (a 1 renders bare, `Turns,count`: fine, the code
                                        knows it's a count — owner)
      EggsNamed,count=2
      Fish:minnow 1,born=4             age = Turns.count − born; nothing on .c
      Fish:perch 2,born=4
```
- **Where methods came from** is kept by `Housing.ghostsHaunt` (`Atheory_design.md` §2): `ghost_origin` (method → the file that last
   defined it) and `ghost_files` (file → the methods its latest load carried, replaced whole each load, so deleted methods
    leave and a clobber is current state).  Each compiled `.g` arrives as one hash with one `Ghostmeta_*`, which is also its
     layer digest.
- **`TheA_code_stand(A, name, paths)`** (`Ghost/A/Theory.g`) stands the code rows; an unloaded layer has no `dige`, the chain
   digest waits for every layer, clobbers are read off `ghost_files`.  No method lookup.
- **The toy** (`Ghost/A/AtheFishTesting.g`, its own file since 2026-10-20 so `A:Athe_Tank`'s code names only it; the
   routines in `AtheTesting.g` call across into it): Pond's rules on the tank's own turn clock; every egg and fish
   carries `born`; the world line stays its name (*"w means w"*).  `Ghost/Play/Pond.g` stays the kids' creation.
- **The test routine** turns the toy by hand (its world's own tick `Athe_Tank(A,w)` does nothing) and swears three things,
   reading only the tree: the A carries the digest of the code loaded for it, an empty tank plants two eggs on its first
    turn, and the eggs hatch into two fish on turn four.  All three are declared in the toc, so a missing sentence reds the
     run.  The runner `ghost_load`s Theory.g, AtheFishTesting.g and AtheTesting.g; the Book loads no code itself.
- **Status:** re-recorded after the toy split (2026-10-20, runner e747): 5 steps, `TheALayer` names `AtheFishTesting.g`,
   assertions 3/3, gaps 0; 3 check runs green, caveat 0.
- **Not yet:** the base Housing as a layer (it has
   no `Ghostmeta`, so it isn't covered — say so, don't fake it); code pushes; the Sunpit.

### The loop queue (re-ordered 2026-10-20 after the adversarial review: finish the A before the frontier)

Work top to bottom.  Each item ends with its Book green (3 check runs, caveat 0, via the Sonnet subagent pinned to one
 runner, **never released**), this doc current (§0.2 status), `Atheory_design.md` current (§1 for what got built, §2 ledger for any Stuff/Housing touch), and memory current.
  Stop a thread and write the question into §0.1's open list rather than guess anything the owner names or rules.

1. ~~The toy's code apart from the routine's~~: done: ruled into its own file, `Ghost/A/AtheFishTesting.g` (§0.1), and `AthePondCode` re-recorded against it.
2. **CodePush** (`AthePondCodePush`): code pushed to the As that hold it, Story letting it through between steps — **BUILT 2026-10-20**, see "CodePush" below.
3. **The Sunpit's base layer, prototyped gradually** — **first slice (order) BUILT 2026-10-20**, see "The Sunpit by hand —
    order" below (owner, 2026-10-20: *"prototype the base layer of what we can see
    Sunpit doing, gradually… you might get away with oa() and o() to build the illusion of some majestic Sunpit rule engine
     giving us exactly the compute we need"*).  Plain `o()`/`oa()` over the toy, written so that what a Sunpit WOULD do is
      visible, starting with **order** (eggs → fish → heron as a declared order, sworn by showing a changed order changes
       the outcome).  Read first: `src/lib/O/LangSion.svelte` (`_o_drill`, `_i_drill`, `_o_iter` "Sunpit iteration",
        `_io_cursor`), `LangCompiling.svelte`'s comments on how `S o a/b` lowers to `_o_iter`, and
         `Ghost/test/Story/Hoho/HohoTiles.g` (the future code language itself).  No rule engine, no method lookup, no
          req-machine rebuild.  Small steps, each a green Book; stop and write it up when unsure.
4. ~~The snapped-digest churn~~: **done as EntropyArrest `tol:same`, see item 8.**  (Was deferred: the digest stays in the snap — it still does, now muted.)  Revisit once an
    A can load its own code and run it like before (the foundation Story_future builds on).  For then: EntropyArrest's
     `means,drop` omits a whole LINE; dropping one KEY (`dige`) needs the `key`/`these_sc` path half-built in
      `Hovercraft.svelte` (`means_of`, `lematch_to_rule`).

5. **Wires and their sums** (`AthePondWireSum`): `%TheAWire`/`%TheAPulse` by hand on the toy, `sum:count` vs `sum:latest` — **BUILT 2026-10-20**, see "Wires by hand".  Next candidates there.

6. **Order doesn't leak** (`AthePondWakeOrder`, candidate test 3): four pairs of tanks woken in opposite orders; a pair
    sharing a name counter (`%NamesFrom`) with no wire leaks its order — **BUILT 2026-10-20**, `Atheory_design.md` §1.6.
7. **A wire between two compartments** (`AthePondWireOrder`): the shared counter declared as `%TheAWire:names,from:<A>`;
    `Athe_Tanks_wake` orders a batch along wires — **BUILT 2026-10-20**, `Atheory_design.md` §1.6.
8. ~~Item 4, the digest churn~~ — **DONE 2026-10-20 as EntropyArrest `tol:same`** (`EntropyArrest.md` §11, owner's design):
    a toy edit no longer re-baselines anything.  Next candidates: pulses that travel along a wire between tanks (the fish
     of one tank feeding another's heron); candidate 2 "unwatched work costs nothing" (touches Housing — ask first).
9. **A pulse that carries something** (`AthePondStream`): `%TheAWire:stream,from:<P>,wake:arrive` — an old fish swims from P
    into Q with its AGE (Q's clock is nine turns behind), `Athe_Tank_wake` hands each run its pulse — **BUILT 2026-10-20**,
     `Atheory_design.md` §1.8.
10. **A loop of wires** (`AthePondLoop`): streams both ways leak the asked order; `lag:1` on one wire takes it out of the
     ordering and breaks the loop — **BUILT 2026-10-20**, `Atheory_design.md` §1.8.  A lagless loop is marked on its tanks, `%TheALoop`
      (BUILT, same Book).  Next candidates: candidate 2 "unwatched work
       costs nothing" (touches Housing, so ask first); candidate 5, the manifest check (needs Electrode × Atlas, the
        Land's L ghosts; which one is the truth is a design call for the owner).
11. **tol:same on the pause and sweep paths** — both now mute like `snap_step` (Atheory_design §2 ledger row); not yet
     exercised live.
12. **Art school: Pond Plates** (renamed from "Pond Atlas" 2026-10-21 — it is not Atlas.g) (2026-10-20) — a private artifact page drawing every recorded Athe snap as ponds (fish
     by age, wires, lags, loops): https://claude.ai/artifact/Uoma1XYQnvVGtBfSNQLkbm.  Built from the fixtures by a
      scratch extractor (parse NNN.snap → tanks JSON); to keep it current, that extractor wants a home in `scripts/`.
13. **The Turn, by hand** (`AthePondTurns`): opt-in `%TheAWas,keep` on a tank; one `%TheATurn` per wire woken, with
     its pulses, code digest, `%TheANeu`/`%TheAGoner` — **BUILT 2026-10-21**, `Atheory_design.md` §1.9.  Readers behind the
      Turns (`%TheAReader`, `AthePondTurnReaders`) BUILT 2026-10-21.  Each new oath was sabotaged once and bit
       (`Atheory_design.md` §1.10).  Next there: a reader that is a real compartment (a downstream tank reading upstream's
        history instead of pulses?) — ask the owner, it touches what a wire IS.
  (Seen in passing: a new Book's
        recording rewrites its toc without the seeded `EntropyArrest` Self_round block; WireOrder and Stream pass without it.)
14. **The boundary** (owner, 2026-10-21: "whatever is going to make more flawless compute… stepped through one coherent move
     at a time"): moves, sends, outboxes, the boundary, Turns and readers moved into `Theory.g` (`TheA_move`, `TheA_send`,
      `TheA_boundary`, `TheA_turn_commit`, `TheA_read`); the toy keeps only its handlers.  The wire-ordered scheduler, `lag`,
       `%TheALoop` and the names wire are gone.  WireSum, WireOrder (now: stopping between moves changes nothing), Stream and
        Loop re-recorded.  Words: `Atheory_design.md` §0.  The boundary was sabotaged once and bit (`Atheory_design.md`
         §1.10).  Next: a Book that reorders moves at random each run; CodePush with a visible effect (needs A**).

**Runners:** never share one with another agent.  If a sweep or another session holds the pinned runner, wait for it or
 pin a different idle one.

**Don'ts for the loop:** never `release` a run (it tears H:Story down while the tab keeps drawing the dead Story face,
 so the owner can't open steps; that face staying clickable is its own open bug); before handing a Book back, print one
  `NNN.snap` and read it as the owner will (memory `w-means-w`); no method lookup or handler tables; no commits or staging;
   oaths declare themselves when a Book is recorded or accepted (`story_declare_all`); no renaming of anything the owner named; `Ghost/Play` untouched; no changes to Lies or the
    relay; Housing/Stuff/Story only with a ledger row in `Atheory_design.md` §2 (Story mediates CodePush, owner 2026-10-20).

### CodePush (loop item 2; BUILT 2026-10-20, Book `AthePondCodePush`)

*Owner, 2026-10-20: code is compiled centrally, hot-updated, and **pushed to the As that hold it**; it arrives at each A
 **as an elvis that does a blank `think()`** (or more, as the A needs).  The operation is called **CodePush**, and **Story
  mediates how pushes come through a Book**.  (A first draft isolated code per A over `Object.create(H)`; withdrawn.)*

```
A:Athe_Tank
  %TheACodePush:Ghost/A/AtheFishTesting.g   ← this file arrived; the A hasn't taken it in yet (one row per file,
                                               however many times it arrives before it's let through)
  %TheACodeTaken,count:2                    ← how many pushes this A has taken in
  %TheACode:Athe_Tank,variant:plain,dige:…  ← re-stood by each push taken in
```

1. **Arrival.**  `Housing.ghostsHaunt` takes in every compiled `.g`; after the merge it calls `TheA_code_push(meta)` with
    the file's `Ghostmeta_*` name (`Atheory_design.md` §2).  Theory walks every House's As; an A whose `%TheALayer` names that file gets a
     `%TheACodePush` row.  An A that doesn't hold the file hears nothing.
2. **Mediation.**  An A in a Story run (its House, or one above, has `sc.Run`) keeps the row.  Story, at the start of each
    step (right after `run.c.step_n = n`), calls `TheA_code_pushes_let(Run)`, and every A in the run with a row waiting
     takes it in.  Outside a run the push goes through at once.
3. **Going through.**  `TheA_code_push_deliver` posts an elvis to the A's w; `e_TheA_code_arrive` stands the A's code again
    from the files it names (a changed file → a new digest), counts it in `%TheACodeTaken`, drops the waiting rows, and
     posts a blank `think` to the w.  Between turns for free: an elvis runs between ticks, never inside one.

**The Book** `AthePondCodePush` (6 steps): the tank and a bystander (`A:Athe_Bystander`, holding `Ghost/A/Theory.g`).
 Step 3 announces the toy's file once (calling `TheA_code_push` as `ghostsHaunt` would); step 4 Story lets it through;
  step 5 announces it twice; step 6 lets the two through.  Oaths: a push waits on the A until Story lets it through and the
   bystander hears nothing; let through, it's taken in once and the same file stands the same code; two arrivals wait as one
    push and are taken in once.  The elvis only thinks the tank, so the routine's witness also runs at the START of each
     step to read what the last let-through did.

**Open / next:**
- A real version change inside a Book: the Book re-announces the same file, so the digest can't change.  Needs a way to
   deliver a second version (owner).
- "Or more": what an A does on arrival beyond a blank think (migrations, a re-read) — none needed yet.
- A real recompile during a held (finished) run leaves a `%TheACodePush` row waiting forever on its As — the run will never
   step again.  Harmless and honest, but it shows in a re-snap.

### The Sunpit by hand — order (loop item 3, first slice BUILT 2026-10-20, Book `AthePondSunpitPassOrder`)

```
w:Athe_Tank
  Turns,count=22
  TheASunpit:turn            the order a turn takes, declared on the tank (a holster: its rows aren't tank contents)
    TheAPass:Egg             "this handler over all of these, before the next"
    TheAPass:Fish
    TheAPass:Heron
  Egg:… / Fish:… / Heron:grey
```
- **Plain `o()` and `i()`, in the toy's own file**, no Theory.g helper: if the toy called Theory.g, its `%TheACode`
   (which names only `AtheFishTesting.g`) would be lying.  `Athe_Tank_order(w)` reads the passes, and stands
    Egg/Fish/Heron if nobody declared an order first.  `Athe_Tank_pass(w, kind, turn)` names each kind's handler in code
     (an if-chain, as `do_fn_for` does for reqs): the order is data, which code runs is not.
- **The culture this slice has:** passes run in the declared order, and each pass takes its rows as they stand when it
   starts.  So the Fish pass sees fish the Egg pass hatched this turn, which does no harm: a fish aged 0 doesn't act.
- **The Book** stands three tanks with the same code: plain, fish-first, heron-first.  It turns them together to turn 23
   (simulated first: `scratchpad tanksim.mjs`, and the turn-22 divergence is the only one in 40 turns).  The oaths:
   - the plain tank declares eggs, fish, heron;
   - on turn 22 the hatch calls the heron to the plain tank, but the heron-first tank's heron looked before the hatch and
      stays away;
   - fish-first and plain hold exactly the same rows on turn 23.
   The last is candidate test 3, "order doesn't leak", in miniature: where order can't matter, it doesn't.
- **Second slice, the frontier (BUILT 2026-10-20, Book `AthePondSunpitFrontier`).**  Keys on the `%TheASunpit` line are
   its culture: `frontier:turn` takes every pass's rows once, as they stood when the turn started, and `gone:skip` passes
    over any of those that have left since.  Three heron-first tanks, turned to 25 (simulated first, `tanksim2.mjs`):
   - pass-start frontier (the default): the fish pass never meets a fish the heron just ate;
   - **turn-start frontier: on turn 25 the roach and bream the heron ate still lay two eggs** (`Egg:tench 17`,
      `Egg:dace 18`).  A stale frontier acts on rows that have left;
   - turn-start with `gone:skip`: identical to the pass-start tank.
  **Why it matters beyond the toy:** `_io_cursor` (LangSion) is "eager for now", meaning it takes its whole frontier up
   front, exactly the turn-start culture.  A Sunpit pulled a row at a time across passes or ticks must skip rows that
    left (or say it doesn't), or it acts on the dead.  The presence check here is plain `w.o().includes(row)`.
- **Next:** "all within some distance" needs positions the tank doesn't have; ask before inventing them.  Or the Sunpit
   compiled from these by hand-written prototypes, once two or three cultures show what they share.
- **Cost seen:** every edit to the toy changes its layer digest, which sits in every Athe snap, so each toy edit re-accepts
   every Athe Book (loop item 4, deferred by the owner; the bill so far is two re-accepts per edit).

### Wires by hand (loop item 5; BUILT 2026-10-20, Book `AthePondWireSum`)

```
w:Athe_Tank_Counted
  TheASunpit:turn  /TheAPass:Egg /TheAPass:Fish          ← no heron pass: the heron is woken by a wire instead
  TheAWire:clock,wake:turn,sum:count                     ← one turn per pulse
    TheAPulse                                            ← a clock pulse waiting (the routine is the clock, by hand)
    TheAWoke,count=22,pulses=22                          ← how many times it has woken, and how many pulses it ate
  TheAWire:fish,on:Fish,wake:heron,sum:count             ← each turn the fish change posts a pulse here
    TheAPulse,turn=19,fish=8
    TheAWoke,count=5,pulses=5
```
- **Plain `o()`/`i()` in the toy's file** (`Athe_Tank_wake`, `Athe_Tank_woken`), for the same reason as the Sunpit: the
   toy's `%TheACode` names only that file.  `Athe_Tank_wake` takes each wire in declared order, drops its waiting pulses, runs
    the wake once per pulse (`sum:count`) or once for the lot (`sum:latest`), and adds to its `%TheAWoke`.  Pulses a wake
     posts on a LATER wire are woken in the same pass (the clock's turns pulse the fish wire, which wakes after): the
      wire-tree order, by hand.  Only a turn posts fish pulses: a wake never pulses its own wire (a heron eating would wake
       itself).  A tank with no wires behaves exactly as before.
- **The Book** stands two tanks that differ only in the fish wire's `sum`.  Step 3 leaves three clock pulses waiting (they
   turn nothing by themselves); step 4 wakes them (three turns); step 5 sends eighteen more and wakes (turn 22).  Four
    fish-changed pulses pile up on the way: summed to the latest, the heron wakes once, arrives and eats nothing; summed by
     count it wakes four times, arrives and eats six fish at once (simulated first, `scratchpad/wiresim.mjs`).  That's
      candidate test 4, "counts are kept", and the doc's own claim: three "fish changed" pulses mean one reconsideration.
- **Pulses snap here**, against the names table's "never snaps": in a Book worked by hand, a pulse waiting between steps
   is the thing to see.  Revisit when pulses come from something other than the routine.
- **Next:** candidate test 2, "unwatched work costs nothing" — a tank with only wires is never visited between pulses.
   It needs the A's own tick to stop riding every belief pass, which touches Housing (ask first); the toy's
    `Athe_Tank(A, w)` already does nothing.  Candidate test 3, "order doesn't leak": two unwired tanks, the same pulses
     woken in either order, identical snaps — buildable now.

### Wires and pulses on Pond

```
w:Pond
  %TheAWire:clock,every:700,wake:step            ← the only clock-driven work Pond has, declared
  %TheAWire:heron,on:Fish,wake:Heron_step        ← "fish count changed → the heron reconsiders"
```

The clock wire posts a `%TheAPulse,kind:step` every 700ms.  Today `Pond(A,w)` checks `Date.now() - w.c.last` on every belief
 pass, so it rides every pass to do work once in 700ms.  With the wire, the pass doesn't visit Pond at all between steps.

**How pulses sum is the receptor's declaration, not a global rule.**  Three step pulses must mean three steps, or the pond
 skips time; three "fish changed" pulses mean one reconsideration.  So a wake says:
- `sum:count`: the handler gets all of them (Pond loops three steps);
- `sum:latest`: one wake, carrying the newest;
- `sum:all`: one wake, carrying the list (the wants accumulator's behaviour).

### One pass of the scheduler

```
1. ready   = pulses whose needs are met (the versions they name exist)
2. batches = group ready pulses by (compartment, wake), summed as each wake declares
3. order   = along the wire-tree: a compartment after the ones wired into it;
             ties broken by declared identity, never by arrival time        ← determinism for Books
4. for each batch:
     take the turf if the wake writes one
     run the handler once, with the batch
     commit one %TheATurn: batch pulse ids, code digest, what changed (the Seem's neus/goners/drift)
     follow the compartment's outgoing wires → new pulses
5. compartments with no ready batch are not visited at all
```

Step 3 is what keeps Story honest: two compartments with no wire between them may run in either order, so the snap must
 not depend on that order.  A Book can pin the order, or swear it doesn't matter (see the tests).

**A Turn is not a counter.**  `%TheATurn` records which pulses made it, under which `%TheACode`, and what changed.  That's the
 version.  Turns live in the compartment's Was-sphere and drop when no reader is behind them.  Wall-clock time rides on
  `.c` for instruments; Story's grid folds Turns into steps for snaps.

### A Sunpit — to study (the first attempt was not worked out)

*Owner, 2026-10-20, on a first compiled form (a `w.sunpit(...)?.({records:{watch, cursor, land}})` call): ugly, doing a lot of
 normal-looking work we may not need, and its `land()` turning each row into a tuple made no sense.  Withdrawn.*  What is
  actually known:
- **Sunpits iterate** (owner).  In LangSion a Sunpit is the iterating form: `Sunpit → _o_iter`, the flat frontier, with
   `_io_cursor` as its slow-motion twin, pulled a row at a time (`LangSolver_report.md`).
- **They compile like `doai`** (owner): the way `oai … + block` becomes a req whose `do_fn` is set once, a Sunpit gets
   callbacks set once, informed by whatever the compiler can work out ahead of time.
- **The designed shapes keep identity** (`vyto_workingouts/commission.md` §3): `mirror` places the SAME refs; `pick` and
   `slope` make referring rows wearing `of:`.  Nothing should copy a row into a tuple; the withdrawn `land()` broke that.
- **The compiler must know how to migrate one** (owner).  When the source of `%Sunpit:shelf` changes, the Sunpit already
   standing has to move to the new shape, so its compiled form carries its own version and a way to migrate.
- **Not built:** `Vyto_sunpit` returns `null`; the recipe form is still "wild speculation until a tenant proves it".

- **Lexical names and grouping** (owner, the frontier).  A Sunpit row wants a way to say which of the names it refers to
   become **lexical variables in the handler**, and which are **grouped**, so the handler can get a list of rows per such
    row (all the `%Card`s per `%Mag`, say).  That's the "ark" read-ahead in LangSolver (`parkar`: fold a fanned leg into
     columns) and Sion's `@name` reuse, seen from the handler's side.

- **Cultures, not one iterator** (owner, 2026-10-20).  The keys a Sunpit row carries (`req`, `req:Pier`, `req` plus
   something else) give a generic processor a *culture*: how to behave.  It might iterate differently, run some other
    handler first, take all of `%SomeSuch` within some distance first, or something not yet imagined.  **So types of Sunpit
     get prototyped by hand first, and compiling them comes after**, once the prototypes show what they share.  Cultures
      already in the code, as raw material:
   - the req machine: highest `maz` first, skip finished or already-ok, bow out on a ttlilt;
   - the tank's step (and Pond's): eggs, then fish, then the heron, where order matters, since fish hatched this turn
      also age this turn ("this handler over all of these, before that one");
   - Vyto's commission drive: watch each source, coalesce the trailing edge, one scan per burst;
   - none yet for "all of `%SomeSuch` within some distance": the tank could grow one (the heron eats only nearby fish).
  Prototypes live in `AtheTesting.g` with the tank as their ground, one Book per culture (`AthePondSunpit…`).

**Order of work (owner): do the A first** (`%TheACode`, `%TheALayer`); the Sunpit is the frontier after it.

To work out: what a compiled Sunpit hands the runtime, what its iteration produces each pass, its version, and its
 migration.  Read first: `commission.md` §3–4 in full, `LangSolver_report.md` (`_io_plan`, `_io_cursor`, Sion), and how
  the `.g` compiler lowers `oai … + block` today.  Expect it to start messy, start working, then get tidier.

### Spheres on Pond

```
w:Pond
  %Fish:perch 2                       ← Said: the particle
  %OtherSphere:'Vyto'                 ← Regard: Vyto's opinion of each point
    %At,of:<D id of perch 2>,x:…,y:…,calm:1
  %OtherSphere:'Story'                ← Was: what each point was at the last step
    %Was,of:<D id of perch 2>,age:4
```

Entries name their point by the **D identity** (the Se's first-sight id), not by the particle ref, so they follow the
 point through re-mints.  When the Held point drops, its entries drop with it: teardown is the alignment's job.

### The first Atheory tests

**Where the code lives:** the organ in `Ghost/A/Theory.g`, its proof in `Ghost/A/AtheTesting.g` (the `<Name>Testing.g`
 convention).  Particle names all start `TheA` so one grep finds every one of them; they're deliberately cumbersome
  while unsure, and get shorter names once they've earned them.

**Book names (owner, 2026-10-20):** `Athe`, then the toy, then what it proves: `AthePondCode`, later `AthePondCodePush`,
 `AthePondWireSum`…  Ugly is fine if it informs.  The toy (`Athe_Tank`) lives in `AtheFishTesting.g` and is shared by the series;
  its name has an underscore so it can't be taken for a Book.

The music app rests; these come first.  **Built: `AthePondCode`** (§0.2 above): the toy stands as an A and turns by hand,
 and the A carries the digest of the code loaded for it.  **Candidates**, each a later Book:

1. **A code change lands between turns, never inside one** (`AthePondCodePush`; loop queue item 2).
2. **Unwatched work costs nothing**: between clock pulses the toy isn't visited at all (needs `%TheAWire`).
3. **Order doesn't leak**: two toys with no wire between them, the same pulses in either order, identical snaps.  **Built:
    `AthePondWakeOrder`.**
4. **Counts are kept**: three step pulses make three turns (`sum:count`); three "fish changed" pulses make one heron
    reconsideration (`sum:latest`).  **Built: `AthePondWireSum`.**
5. **The manifest is checked**: Electrode during the run, joined with Atlas: every method called is on a declared layer,
    and every declared layer was called.

Each test is a sentence a person would say, and each can be sabotaged once to prove it bites (Homethink §3).

### What the sketch still doesn't say

- **Where Turns and pulses sit relative to the existing belief walk.**  The first build may run the scheduler *inside*
   today's `beliefs()` as one more leg, before replacing it.
- **Turf leases for compartments inside one tab** (no relay round-trip needed) versus across bodies.
- **Snap filtering** for OtherSpheres and holsters (§0.1).

## 0.3 Foundation ledger — moved to `Atheory_design.md` §2 (2026-10-20)

Every change Atheory makes to Stuff or Housing (and beside them) is collected in **`Atheory_design.md` §2**, with the rules
 for adding a row and how to audit the ledger against git.  Add rows there, in the same change as the edit.

## 0.4 Antipatterns — what the rebuild measures itself against (2026-10-20)

*How we code now, seen from the new era.  Each: the tell, a case we actually hit, what Atheory does instead.  A change
 that adds one of these needs a reason written beside it.*

**1. State hidden from the community**
- **The unlabelled drawer.**  `.c.anything`: 1,234 undeclared keys with no kind, lifetime or basis (`voucher_ok` outlived a
   revocation; `repli_sent_sc` split twins across a reload; the tank's egg counter on `w.c.n`).  *Instead:* `.c` holds only
    fingers (refs), flesh (functions, handles, buffers), a run's scratch, and caches that name their basis.  Facts go in
     `sc`, and are snapped, munged (EntropyArrest's `mung`: key shown, value hidden) or omitted (`omit_sc`, generalised
      to a declared list) by declaration.
- **Packed strings.**  Several facts in one value (`step_kinds:'Egg Fish Heron'`).  *Instead:* one child row per fact
   ("structured sc children over clever packed strings", `vyto_workingouts/commission.md`).
- **Placeholder values.**  A stand-in where absence belongs (`'unloaded'` as a digest; `undef` mints).  *Instead:* absence.

**2. Correctness that depends on every reader remembering**
- **Per-reader gates.**  `humdinger`, `Story_replaying()`, `w === radio_w && !w.c.Run`; a reader that forgets shows up only
   as a flaky Book (MusuRadioAim, red 5/5).  *Instead:* nearest-enclosing lookup, with the world as the wall.
- **Reaching for the top.**  `top_House()` finds the tab's Supervisor, not the scope's.  *Instead:* scoped lookup.
- **Side roads past a general mechanism.**  The music plane admitted on `from` alone; the service worker's re-fetch dropped
   the signal Vite needed.  *Instead:* one road.

**3. Behaviour in the wrong place**
- **App work inside test beats.**  `if (n === k)` doing boot work, so a short toc meant no music.  *Instead:* the machine
   stands itself; Books only watch and swear.
- **Test playthings in real code.**  A Book's needs reshaping `Ghost/Play/Pond.g`.  *Instead:* playthings live in the
   `*Testing.g`.
- **Existence tied to drawing.**  `Lies_ghost_set`: the mount is the load.  *Instead:* the manifest stands code.

**4. Time handled by polling**
- **Wall-clock checks every pass.**  `Date.now() - w.c.last` in Pond and Garden.  *Instead:* a declared clock wire, and no
   visit between pulses.
- **Polling for what could be pushed.**  `Creduler_reswap` every 2s; test helpers looping `setTimeout(200)`.  *Instead:*
   pushes addressed by the manifest; waits that are events.
- **Anonymous wakes.**  A bare `think`, then every pass re-derives the world (60–80% of a core on the idle daemon).
   *Instead:* pulses addressed to compartments that know they changed.

**5. Structure that is only a convention**
- **Lists that disagree.**  `CREDULER_GHOSTS` / `GFILES` / `Siphon_include`; scattered `.jamsend` (fixed: `APP_DATA_DIR`).
   *Instead:* one declared source, checked against Atlas × Electrode.
- **Everything flat on H.**  9,487 direct `this.X_y()` calls, 21 mutually recursive ghost pairs, no boundary.  *Instead:*
   A layers; lookup only where something genuinely looks up (req, e, the Sunpit).
- **One idea, several names.**  Four numberings of identity; LE, Repli and five hand-rolled merges.  *Instead:* one organ
   with policies.

**6. The tooling lies quietly**
- **Checks that look like passes.**  LocalGen had no `mkdir` (fixed); the esbuild parse misses duplicate imports; `accept`
   skips forgiven steps; a compile ack can claim a change that didn't land.  *Instead:* each check proves the thing:
    the module loads, the digest flipped, `caveat:0`.
- **Fixtures that snap their own volatility.**  A layer's own digest in the snap (four re-records in a day); wall clock in
   `sc`.  *Instead:* compare live in the witness; snap the verdict, not the value.

**Unsure: dated narrative comments.**  Long dated comment-essays keep the why, but rot silently (the "un-buffered cyto"
 claim was false for six weeks).  The rationale is worth keeping; the changelog may belong in the docs.

## The load-list inventory — DONE 2026-09-05 (the "when it starts" step below, paid)

Measured, so §0's irritation 1 now has a number instead of a suspicion.

**The three lists, and they do not agree.**
- `CREDULER_GHOSTS` — `LiesLies.svelte:56-101`, 36 paths, the RUNTIME manifest a runner loads live.
- `GFILES` default — `scripts/LocalGen.spec.ts:23`, **4** paths (`Reliable Peeroleum Tribunal
   Peregrination`), the COMPILE-side twin.  A stale subset of the above — whatever was in hand the
    day it was written.
- `scripts/Siphon_include.svelte` — 6 hand-written `gen/**.go` imports, existing ONLY because Siphon
   was deliberately left out of `CREDULER_GHOSTS`.  A workaround is the third list.

**What the manifest costs a page that does not want it.**  `gen/` is 4.4MB.  A humdinger music page
 loads all 36 (4.19MB) via `Creduler_ensure`.  Radio.g's full static call-closure — `this.`, `H.`,
  `&`, and elvisto edges followed — reaches **14 of them (2.38MB)**.  The other **22 (1.81MB) are
   loaded and never touched**, and the bulk of that is other pages' Story test Books:

```
 454K Story/Heistation   159K V/Vytonation    91K Story/Peregrination   19K M/Radiola
 325K Story/Swarmation   149K Story/Voronation 33K N/Tribunal           17K Story/InvFerry
 192K Story/Musuation    118K V/Voro          33K Story/InvWalk         14K M/Mixer
                         107K Story/Radiation                           13K Story/Berthation
```

`Sounditron.g` — the music page's OWN diagnostic Book — is correctly reached, so this is not "Books
 are unreachable": a humdinger loads *every other page's* tests.  ~1.5MB of Story test code parsed at
  boot on someone's phone.

Measured with `scripts/drawer.mjs needs M/Radio.g` (a static def/call index over 228 files / 157k
 lines: 3,670 defs, 12,790 call sites, 93.5% of callees resolving).  It is a FLOOR — dynamic dispatch
  (`do_fn_for` by `w.sc.w`) is not followed — so real need is somewhat higher, but the test-Book bulk
   is not in doubt.

**The cure §0 already names is the right one, and the numbers say so.**  Not "delete entries" but
 *"make loading DECLARED — the base Housing knowing what belongs on it, legibly, the way everything
  else in the world is legible matter"*: **the manifest wants to be particles, not a JS array.**  A
   role dimension then falls out (a humdinger stands the music spine, a runner stands everything
    because it genuinely runs those Books) without hardcoding a second array beside the first.

**Two enabling notes for whoever picks this up.**
- `Lies_ghost_set(path)` (`LiesLies.svelte:999`) takes an ARBITRARY path and dynamic-imports it.  It
   never consults `CREDULER_GHOSTS` — the manifest is only the default list `Creduler_ensure` walks.
    So loading is already path-driven; only the *roster* is hardcoded.
- The array lives inside `LiesLies.svelte`.  Extracting it to its own module first (the
   `runner_liveness.mjs` precedent — *"the channel-liveness thresholds live in ONE place now… was
    three inline literals that could drift"*) makes `LiesLies` a one-line import change and puts the
     role logic somewhere touchable.  `RUNNER_FACETS` (`LiesLies.svelte:100`) is the same pattern
      already applied to a different list, with the rationale written out.

Still owed from the "when it starts" list: the inventory of what the toplevel actually does between
 page-load and commission.

## THE A** SHAPE — proposed 2026-09-07 (the owner's `TheA_$dige`), measured and bench-verified

*Status honesty: the "Not yet" below asked for the toplevel inventory first, and that inventory is
 STILL OWED.  What follows is proposed on a different measurement — the CALL GRAPH — because the owner
  reached for the shape directly ("we're creating a class called `TheA_$dige` which pulls in a bundle of
   code to specifise, and superclass of Housing has the rest").  Nothing here needs the toplevel
    inventory to be judged; the inventory is still what tells us what the rebuilt toplevel DOES.*

### The shape

```
        House  (the spine — Housing's walk + the 72 generic names)
          ▲
   TheA_<Name>_<Variant>_<dige>   (the mutually-recursive core + the shared API)
          ▲
   TheA_<Name>_<Variant>_<dige>   (one Book, one leaf ghost)
```

Each layer is a real prototype; instances of an A hang off the topmost.  Chain lookup is live, so a
 method anywhere below is reachable, and a method on the bundle layer is invisible to a plain House —
  which is the specialisation the owner asked for.

**The name has three parts, ruled by the owner 2026-09-08: `TheA_SomeName_SomeVariant_<dige>`.**
- `Name` — WHICH bundle (the platform core, a Book, a leaf ghost).
- `Variant` — which BUILD of that bundle.  This is the slot that makes the whole scheme pay, and it has
   a first concrete tenant: an **electroded build**.  `Electrode_todo §1` splits tracing in two — a
    runtime wrapper sees entry and exit of a method and needs nothing from here, but LINE-level and
     BRANCH tracing (*"trace all the way through every line… excellent for teaching the program's
      flow"*) can only come from the compiler emitting marks inside the body, i.e. a genuinely different
       compiled form of the same ghost living beside the plain one.  That is a variant.  So the shape
        below is not only about isolating an A's overrides; it is the thing that lets an instrumented
         build and a clean build coexist, per A, with the cluster still pinned to one stable version.
- `dige` — the content hash, so a bundle's identity is what it IS, not what it was called.

### The seam it needs ALREADY EXISTS, unused

`do_fn_for` (`Housing.svelte.ts:1487`) already resolves `w_inst[method]` **before** `H[method]`, and
 `organise_scheme` marks only the `H` level `is_inst`.  Its own comment says the rest fall back on
  purpose: *"For is_inst levels (House at depth 0) sets T.sc.inst = n.  Otherwise inst stays undefined
   and _Aw_think falls back to H.\* (ghost-injected) methods."*  Give the `A` level `is_inst` and an
    instance to hang there and dispatch lands on it with `this` bound to that A.  The spine does not
     change.  This is an activation, not a rewrite.

### What the border actually measures (2026-09-07, every `.g` scanned)

The raw cross-ghost count looks fatal to partitioning and is not.  Of 3,088 cross-file `this.` calls,
 **2,445 are a Story Book calling its own subject ghost** — the test relationship, not a border.  The
  real domain-to-domain border is **643 calls**, and it concentrates hard:

| | |
|---|---|
| domain cross-called methods | 196 |
| carried by 16 methods with ≥3 callers | 292 calls (45%) |
| carried by 150 single-caller methods | 224 calls |

The 16 are a platform layer nobody designed: `Radio_trace` · `Ra_recs` · `Ra_rec_find` · `Crate_nav` ·
 `Radio_pub` · `Ra_home_self`/`_them`/`_shop` · `Radio_clean` · `Repli_chunk_at`/`_bytes` ·
  `Repli_xfer_get` · `Pier_next_seq` · `Swarm_now` · `Heist_keep_born` · `Radio_friendly`.  A trace
   facility, the record store, home/shop resolution, chunk IO, sequence allocation and a clock.  **That
    is the "backending in a superclass" the owner proposed, and it can be named today.**  The 150
     single-caller reaches are the audit: each is either an API that should join the 16, or a reach that
      should not exist.

**The hard constraint: 21 ghost pairs are mutually recursive** (`Ra ↔ Radio`, `Heist ↔ Ra`,
 `Heard ↔ Swarm`, `Ra ↔ Repli`, `Heist ↔ Repli` …).  A prototype chain is linear, so no ordering exists
  for a cycle — that cluster must be **flattened into ONE layer**.  Median fan-out among the other files
   is 1, so the leaves layer cleanly.  This kills the finer-grained variant (one class per ghost,
    chained) before anyone tries it.

### The mechanics, verified on the real `House` (not reasoned about)

- **Mutating a prototype in place WORKS.**  `Object.assign(TheA_X.prototype, fresh)` is seen immediately
   by already-constructed instances — replaced methods, brand-new methods, and deletions.
- **Svelte 5 `$state` is not a problem.**  Rune fields compile to accessors on the *declaring* class's
   prototype with a `#private` slot on the instance.  A generated subclass keeps `Housing.prototype` in
    its chain, so reactivity survives both mutation and re-pointing — including a `$state` write from a
     method that did not exist at construction time.  Chain verified:
      `House → StorableHousing → Housing → TheC → Stuff → TimeOffice → StuffAware → StuffIO`.
- **`setPrototypeOf` works but is the dangerous one.**  It is safe only while the new class extends the
   *same* `House` class object.  Against a different EVALUATION of `Housing.svelte.ts` it succeeds
    silently, resolves methods fine, and then throws `Cannot read private member #believing` —
     asynchronously, inside the persistence effect at `Housing.svelte.ts:452`.  A sync try/catch around
      the re-point catches nothing.  **Pin the base**: capture the one live `House` and always extend
       that object.  (Mitigating fact: nothing in `src/lib` calls `import.meta.hot.accept`, so a change
        to a non-component module bubbles to a FULL PAGE RELOAD by Vite's default — the observed
         behaviour all session, where every gen write reloaded every tab.  So this landmine is unlikely
          to fire from a Housing edit; pinning is cheap insurance, not a live hazard.)
- **So: construct a class once per dige, and MUTATE that prototype thereafter.**  Re-pointing becomes a
   deliberate act — an A adopting a different code version — not an automatic consequence of a reload.
    This is also the only shape that pays: two `TheA_` prototypes over one pinned `House` let two A's
     run different code versions in one tab, which one flat `H.ghosts` can never do.

### Two migration constraints, both sharp

1. **An own property permanently masks its prototype twin.**  `ghostsHaunt` today does
    `Object.assign(h, this.ghosts)` — own props on every House instance — and an own prop beats the whole
     chain.  A half-migrated method name reads the stale own copy forever.  **The cutover must be
      all-or-nothing per method NAME**, or `ghostsHaunt` must delete as it goes.
2. **`Object.assign` only ever adds.**  A method a bundle drops lingers on the prototype forever unless
    explicitly deleted — which matters directly for §0's "make loading DECLARED", since a bundle that no
     longer declares a method must not still answer to it.

### What this does NOT fix

**The 1.81MB.**  Class construction changes how methods ATTACH and DISPATCH, not which `.go` modules get
 imported and parsed.  The measured waste — a humdinger parsing every other page's Story Books — is
  decided upstream by `CREDULER_GHOSTS`, and stays exactly where it is until the manifest becomes
   particles (§0's own cure).  Do not let the A** shape be mistaken for that fix.

### Open decisions

- **What the dige covers.**  *Ruled 2026-10-20 (§0.1): an A's version is a digest over the digests of each `.go` on
   its chain.*  The old framing (a per-ghost dige vs a per-"closure" dige over the files Radio's methods reach, 14 of
    36) was confusing: everything sits on H, nothing includes anything.
- **Reactive state in generated code.**  *Corrected 2026-10-20:* a class built at RUNTIME from a dige can't use rune
   syntax (no rune compilation at runtime).  But the `.go` files are compiled by the Svelte compiler, so code generated
    at COMPILE time can hold classes with `$state`, and `svelte/reactivity` gives reactive classes with no compiler.
     Auto-generated Svelte components carrying `$state` classes are fine.  `$state` is only needed to reach the UI, so
      keep it to what the UI needs.
- **Where the 150 single-caller reaches land** — the audit above is unstarted.

## Case studies — what to feed Atheory

Owner, 2026-10-15: *"we will hand off Atheory, but give more case studies for it, eg the Se|Merge thing is quite it isn't
 it"*.

**Written:**
- **The serving box** (below): passes not change, code delivery by polling, the heap a body carries.
- **The merge organ** (below): Se → Merge, LE + Repli, the sole-writer world ending.
- **The `.c` smear** (below): 1,234 undeclared keys sorted into five kinds; spheres aligned at D; six design consequences.

**Already written elsewhere in this doc (pointers, not repeats):**
- **Three load lists that disagree** (`CREDULER_GHOSTS` / `GFILES` / the spine): the load-list inventory above, plus the
   editor riding a FROZEN spine (`pinned_stable/`).
- **Wakes nobody owns** (4,918 bare `think`s on an idle daemon; `feebly_ponder`; the trickles): the serving box,
   irritation 4, with numbers in `Perf_todo.md` §7.

### Shorter case studies (2026-10-15): what happened, what it cost, what Atheory must do

**The stale registration** (Cellui, 2026-10-14).  A cell's inlay never re-fit on a window resize or a content change, only
 on a manual cell switch.  `sizewatch` registered each mold in a module-level `molds` Map keyed by cell name.  A same-key
  remount mounted the new element *before* the old one's destroy ran, and the old destroy did `molds.delete(key)`, which
   deleted the NEW entry.  The fix was one line: `if (molds.get(key) === el) molds.delete(key)`.  It took an evening to
    find, because nothing showed the Map: the entry just wasn't there.
 *For Atheory:* a registration is a **finger** (see the `.c` smear) with a lifecycle nobody declared.  If registrations
  attach to the point they serve and die with it, "whose teardown is this?" has one answer and the bug can't be written.
   It also wants to be **visible**: a registry the glass could draw would have shown the missing cell at once.

**Live reads leaking into Books** (MusuRadioAim, red 5/5, 2026-10-14).  `Radio_alone_why` asked the Supervisor why the radio
 was alone, and on a runner the Supervisor it found was *the runner's own* live one, not the Book's.  So a replay's snap
  carried the live tab's state and differed every run.  The fix was a gate (`!Story_replaying()`), the same shape as the
   earlier `w === radio_w && !w.c.Run` (memory `live-read-leaks-into-books`).  Each new reader of live state has to
    remember the gate, and the ones that forget only show up as a flaky Book.
 *For Atheory:* **time|space isolation as a property of the pass, not of each reader.**  A pass runs *for* a world (live,
  or a Book's replay), and an edge out of that world is unreachable rather than gated.  Same consequence as the `.c` smear's
   rule 5, from the test side.

**The trust stack** (`Trust_todo.md` §1, re-read 2026-10-13).  Four layers each authenticate a different thing:
- the link: a signed hello binds an address at the relay;
- the era: a voucher, signed once per era, rides every Swarm frame;
- the society: invites, grants and the crew charter, ed25519 with single-use spends;
- and, since 2026-10-13, the relay from-check.
 There are two holes, and both are the same shape.  The voucher doesn't cover the frame's body, so a lifted voucher signs
  a forged frame until the era turns.  And the whole music plane (`repli_*` frames) went out with **no swarm bag at
   all**, admitted on `header.from` alone, until the relay check closed it at the transport.  Then `Signed_call_todo.md`
    designs a fifth thing, signed RPC from the command line, which is a sixth place to get proof right.
 *Owner, 2026-10-20: this reach is over-bearing.  Signatures (authority among Piers) are a scope above Seem, and
  `by|rule|hid|pass` belongs to the Voro processor as an organisation of Seems; read what follows as inspiration (§0.1).*
 *For Atheory:* **provenance is a property of every saying, not of a channel.**  `Cstructures_todo.md` §3 already wants each
  saying to carry `by:` / `rule:` / `hid:` / `pass:`; a frame, a verb call and a particle arriving over the wire are all
   sayings, so "signed by whom, over what" belongs in the same slot.  A frame with no proof should be as unrepresentable as
    a particle with no mainkey.  The music plane didn't skip the proof on purpose: it took a side road past the general
     mechanism (memory `app-infra-boundary`), and a design with one road has no side road.  The merge organ needs this too:
      its policy "signed by the soul wins" is only as good as the proof on the candidate.

## Case study: the serving box (2026-10-14) — two more irritations, measured, fed here rather than patched

The owner, after a week tuning the jamserve daemon: *"we do indeed need to compartmentalise and notice change better, but I
 think we might be scraping together a case study to feed to Atheory more than further optimising this now… this is a
  coherent point!"* The numbers and file:lines are in `Perf_todo.md` §7 (§7.6 is four surveys' evidence). What it says about
   Housing's next shape:

3. **Code arrives by polling.** `Creduler_reswap` (`LiesLies.svelte:1483`) asks the dev server "which `.go` changed?" every
    2 s from every runner tab (`/__gen/dige`, or ~35 HEADs without it). It even did so on the daemon, at prod, for nothing (now
     skipped there). Owner: *"we should not require polling like that, code changes should push out to the required runners."*
      The server already knows the instant a `.go` is written (the Docindex push, `control:docindex` ≈450 ms, is the precedent).
       And A** knows which runner holds which ghost (the declared manifest of §0 irritation 1). So delivery is a PUSH addressed
        by the manifest: "Swarm.go changed → the runners whose A** holds Swarm get it". The swap seam ("never mid-run") stays
         the receiver's rule. Visibility comes free: a code version becomes a particle on the A that holds it, so "which runner is
          on which Swarm.go" reads off the tree instead of an ETag map in `.c`.
4. **Change is noticed by re-running everything.** A belief pass re-derives the world (organise, attend, reqdo_sweep, officing)
    whether or not anything changed. The surveys found why that can't be cheaply gated today:
    - `version` is per particle and nothing carries it to the world or the House;
    - plain `sc` and `.c` writes record nothing;
    - every pass bumps every A itself (the `self_timekeeping` round, `A.replace({w:1})`);
    - eternal reqs look like work every pass;
    - wakes are anonymous (`think` from anyone, for anything).

    On a box that never sleeps, that re-running WAS the workload (60–80% of a core, idle). The Atheory answer is
     **compartments that know they changed**: each A/w carries a dirty mark raised by any mutation beneath it (an up-walk on
      bump, which REACTAP's per-host tap already half-does), cleared at the end of its own pass. A pass visits only dirty
       compartments plus those holding a HOLD (an unfinished req, a due ttlilt). Clock-driven work declares itself
        (`wants_clock`) instead of riding every pass. A wake names its compartment (`think(w)`, not `think`).

    **The owner's direction (2026-10-14), rejecting even a module-level counter many readers consume:** *"this need is going
     into the Atheory design, possibly some kind of space-flow map that refers to itself for responditivity and time|space
      isolation scheme… the need to make the entire weave of computation mergable."* Read as requirements:
    - **Space-flow map.** Which compartment feeds which is itself legible matter, the map the passes follow, not a global
       signal everyone polls.
    - **Refers to itself for responditivity.** A change finds who must respond by consulting that map, so responsiveness is
       a lookup, not a broadcast.
    - **Time|space isolation.** A compartment's pass sees a consistent slice: one place, one moment.
    - **Mergeable.** Two weaves of computation (two tabs, two bodies, a runner and an editor) can be joined like the
       particles they're made of, which only works if every change is a recorded, attributable event.

    That's a Housing redesign, not a patch. Its correctness rests on EVERY change being noticed, which is exactly what the
     code doesn't guarantee today. Hence: case study first, rebuild later.

5. **The heap a body carries should be chosen, not inherited (2026-10-15).** The jamserve daemon idles at ~725 MB RSS (~1.35 GB
    while encoding). The particle tree is ~5 MB of that; the rest is the whole app booted headless: vite-node, jsdom, every UI
     face, the Story/Vyto houses. A serving body needs perhaps a fifth of it. That's irritation 1's declared manifest with a
      ROLE: an A** that says "serve" loads the serving ghosts, prebuilt, and nothing that only exists to be looked at. Owner:
       *"it could lose some weight as part of Atheory which is going to be selective about the javascript heap we have
        running."* Measurements + the cheap interim levers: `Daemon_todo.md` §0.000.

*Interim on the daemon (deliberately small):*
- the tour rests with no audience;
- an idle floor with wake-on-queued-work;
- no stack capture per `replace()`;
- a dir-listing cache;
- the reswap skip.

None of these touches Housing's pass. The proposed "R1b" (a global bump counter to skip empty daemon thinks) is parked: it's
 a cheap imitation of irritation 4's dirty marks, and its blind spot (writes that don't bump) is the same blind spot.

## Case study: the `.c` smear — the other property space, and where it wants to sit relative to the C (2026-10-15)

> 👤 **For people.** Every particle has two drawers.  `sc` is what it says: snapped, sent, asserted, rewritable.  `.c` is
>  *everything else*, one unlabelled drawer per particle that any ghost can stuff anything into.  This case study counts
>   what's in the drawer and argues it isn't one drawer: it's four or five different spaces, each wanting its own shape,
>    lined up with the particle the way a tracing-paper overlay lines up with a map.

### What's in it, measured

`Ghost/**/*.g` alone: **1,234 distinct `.c.X` keys, 8,657 uses.**  679 keys are used three times or fewer, and 116 once.
 Nobody declared any of them; each was named on the spot by whoever needed somewhere to put something.  Sorting the 89
  most-used keys by hand (48% of all uses) gives five kinds, all present:

| kind | examples | share of uses (sorted part) | what it is relative to the C |
|---|---|---|---|
| **finger** | `up` (713), `source_n`, `radio_w`, `origin_mag`, `repli_src`, `client_w` | 17% | an **edge**: this point is joined to another |
| **run-cast** | `did_step` (294), `run`, `step_n`, `lis_pre`, `alice` | 12% | a Book's local variables, parked on the world |
| **overlay** | `humdinger`, `folded`, `held`, `ra_parked`, `grapples`, Vyto's `seed`/`calm`/`tok`/`press` | 9% | an **opinion another organ holds** about this point |
| **organ** | `rx`/`tx`, `pcm`, `dec`, `connection`, `secret`, `on` | 5% | flesh: a handle or a function that can't be said |
| **memory** | `repli_sent_sc`, `voucher_ok`, `heard_at`, `ra_want_ts`, `ra_missed`, `last_touch` | 4% | **what this point was**, last beat or last send |

The other 1,145 keys (53% of uses) are the long tail nobody sorted, which is the finding: **the drawer has no kinds, so
 nothing can know what any entry is for, how long it should live, or what it was derived from.**

`Statehome_todo.md` already rules the first cut (speech vs flesh: *"would the community SEE, PROVE, REWRITE it?"*) and
 pays several debts (`%Focus`, `%Owed`).  That rule decides *whether* a datum leaves `.c`.  It doesn't say what shape the
  survivors have, and the bugs below are all survivors: things that rightly stay off the snap but were still wrong.

### The bugs it made (each one already paid for)

| bug | key | kind | what was missing |
|---|---|---|---|
| a Repli mutation across a reload splits into a visible twin (`Repli_design.md` §5) | `repli_sent_sc` | memory | a **lifetime**: the memory had to outlive the tab and couldn't |
| a revoked friend still passes the door (memory `voucher-cache-outlives-revocation`) | `pier.c.voucher_ok` | memory | a **basis**: nothing linked the cache to the membership it was derived from |
| a Cello inlay never re-fits until a cell switch (2026-10-14) | Cellui's `molds` Map (a `.c` by another name) | finger | **identity on teardown**: the old mount's destroy deleted the new mount's entry |
| a Book reads the runner's own Supervisor and reds 5/5 (MusuRadioAim) | `radio_w` / `humdinger` | finger + overlay | **which world**: an edge to the live radio leaked into a replay |
| a refusal is re-offered forever (merge organ, "What each half lacks") | `ra_missed`, `breach` | memory | a **snap policy**: what was declined has to be remembered like what was taken |

Five bugs, five different missing properties, one cause: **an entry in an unlabelled bag carries no declaration**, so the
 machine can't keep its promises for it.

### The framing: spheres, aligned to the C

The owner, 2026-08-05 (`Repli_design.md` §5 and §6): *"any mention of `.c.*` is likely meant to be another attached
 sphere, hanging off the first D that an `n` finds"* and *"O and K are two other classes of information, layers,
  overlaid on the original n. there's a weird space of deformity between the n\*\* sphere and a K\*\* sphere… it's all
   really just graph data, not tree data per se."*

Read against the table, that framing fits the kinds almost one to one:

- **`n**`, the basis.**  The particles and their `sc`: the speech.
- **`D**`, the alignment.**  What the machine believes the shape of `n` is right now: the resolved diff (`Selection`,
   `resolve()`), mirroring `n` point for point.  This is the **seam**: every other sphere attaches *here*, not to `n`
    directly, so that when `n` moves (a rename, a reload, a re-parse) the layers follow the alignment instead of falling
     off.  That's the merge organ's rule 1 (declared identity) seen from the other side.
- **`K**`, memory over time.**  "What was this key last beat / last send / last accepted": `repli_sent_sc`, `heard_at`,
   `voucher_ok`.  Stitched at each D point.  A *sequence* of K trees slaved to one D basis is the multitude the owner
    says Seem is waiting on.
- **`O**`, overlays.**  Opinions *another organ* holds about the point: Vyto's placement and calm, the humdinger role,
   the parked-ness of a want.  Each overlay has an owner who isn't the particle.
- **Fingers aren't a sphere; they're the seams between spheres and between trees.**  `up` is the tree's own edge; the
   rest (`source_n`, `radio_w`, `origin_mag`, the molds Map) are **graph edges the tree can't see**.  That's the "graph,
    not tree": the C tree is a spanning tree of a larger graph, and `.c` is where the rest of the graph's edges were
     hidden.
- **Organs and run-cast stay outside the geometry.**  An organ is flesh (Statehome §5).  A run-cast is the scratch of
   one run, and its sphere is the run, not the point.

The **"space of deformity"** is then concrete: it's the difference between `n**` and a layer.  `K` minus `n` is *what
 changed since I last looked*, which is exactly the "notice change" the serving box case study is missing (irritation 4).
  `O` minus `n` is *where another organ disagrees with the particle*.  Both are drawable, which is the owner's wish for *"a
   biological space where things float along and react"*: the glass could render the deformity, not just the basis.

### What Atheory must therefore do

1. **No anonymous bag.**  Every off-snap datum names its sphere.  A sphere is declared once (a name, an owner organ, a
    lifetime, a snap policy, a basis).  `.c.anything` remains possible only as a counted, visible escape hatch.  The
     1,234-key count is the baseline to drive down.
2. **Layers attach to D, by declared identity.**  An entry lives and dies with its D point, so teardown is the
    alignment's job, not each caller's: the stale registration can't happen because no one owns a raw Map entry.
3. **Each sphere declares its lifetime and snap policy independently of its basis.**  `Repli_design` §6 ruling 3 asks
    whether a sphere may snap while its basis is `%dontSnap`; the answer this case argues for is **yes, always
     independently**.  K-shadows persist (no more reload twins), O-overlays live a session, run-cast lives a run, organs
      never snap.
4. **A derived entry names what it was derived from.**  When the basis changes, the derivation is stale *by
    construction*: `voucher_ok` dies with the membership change that should have killed it.  This is the same
     dependency record that would let a pass notice change instead of re-running (Perf §7), so one mechanism pays for
      both.
5. **Fingers become declared edges**, carrying which world they point into.  The Book/live leak becomes a type error,
    not a 5/5 red: an edge into the live radio isn't reachable from a replay.
6. **K is the merge organ's memory.**  Rule 3 of the organ ("key-level memory is a sphere, not a smear") is this case
    study applied to Repli.  Build the sphere once, in the Seem porcelain, not in `Repli.g` (`Repli_design.md` §5,
     "whether this generalises").

### Still the owner's (don't guess)

- **The names.**  *Answered 2026-10-20 (§0.1): K = Was, this point's past as its own keeper remembers it; O = Regard,
   its present as another organ sees it.  Working names.*
- **One sphere per organ, or one per kind?**  *Answered 2026-10-20: per organ, as `%OtherSphere:'<label>'/*`.*
- **Cost.**  A node per key per particle is a lot of nodes (`Repli_design` §5).  A sphere may store one node per point
   carrying a was-map, and that's an engine choice, not a model one.

## The merge organ — LE and Repli each hold half of it (expanding the retired Tend §7, 2026-10-15)

> 👤 **For people.** The owner wants Atheory to make *"the entire weave of computation mergeable"*: two tabs, two devices,
> a friend's copy, an LLM's suggestion, all able to meet and become one, the way particles already can.  The machine has
> TWO halves of the thing that would do that, built separately, and neither is whole.  One (LE, the editor's "understanding")
> can hold a rival version of something and decide whether to take it, but only for documents.  The other (Repli, the
> wire's replication) moves any kind of thing between bodies, but has no notion of a rival version at all: whatever arrives
> simply IS the new truth.  Meanwhile, every place two bodies actually share state has grown its own little merge by hand.
> This section says what one merge organ would be, and why it's an Atheory job rather than a patch.

Source: `history/Tend_todo.md` §7, "Why not LE, why not Repli" (scouted in full 2026-09-04; its references re-checked
 2026-10-15: `Repli_design.md` still asks for the Seem port, the sole-writer axiom is still `Repli.g:313`, LE's encode
  path is unchanged).  The rest of that retired doc's vocabulary (qua/grain/accord) is left where it is on purpose (owner:
   *"I don't really believe much of this language… maybe we'd better leave most of it"*).

### What the two share — the part that is already right

Both stand a `Selection` and bottom out in the SAME `resolve()` pairing (`Stuff.svelte.ts:1114`): given a new tree and an
 old one, pair each new particle with the old one it IS, by unambiguity scoring, and say what was born, what went, and what
  stayed.  Both independently dodged the same `est_D_T` footgun and both left `resolve_strict` off.  Twice-validated, by two
   teams of one, a month apart.  **Any merge organ is `Selection`/`resolve()` at its core.  Don't build another.**

### What each half lacks

| | LE (`LangHold`, `i_Seem`/`o_Seem`) | Repli (`Repli.g`) |
|---|---|---|
| **a candidate** — a rival version held BESIDE the canonical, decided on | ✅ `Seem_clone_C`: origin vs working | ❌ arriving lines go straight into the live `%Theirs` shelf (`Repli_merge:356`) |
| **who wins** | the human, by accepting | unaskable: the **sole-writer axiom** (`Repli.g:313`): only the sender ever writes, so its copy IS truth |
| **any mainkey** | ❌ `LE_encode_compare → Seem_toString → enWaft` faults outside `%What/%Doc/%Point` (silently corrupts the gate, not a crash) | ✅ protocol-blind lines |
| **depth** | ❌ clone extent hard-coded depth-1, in two places | ✅ whole subtrees, paged |
| **key-level memory** (which KEY moved, not just which particle) | partial (the D-sphere) | ❌ a `.c.repli_sent_sc` smear: never snaps, dies on reload, so a mutation across a restart splits into a twin (`Repli_design.md` §5) |
| **refusals** | ❌ `U%unaccepted` lives on `.c`, and the D-sphere is `r()`-wiped each walk | ❌ `ra_missed`/`breach` on `.c` |
| **proven** | ❌ no Book (only Svelte rigs) | ✅ eleven Books |

Read across a row: each column is strong exactly where the other is weak.

### Why it's urgent now: the sole-writer world is over

Repli's axiom was true when a body only ever mirrored a FRIEND's shelf.  It stopped being true when one soul got many
 bodies (crew, 2026-09) and when the same ledger began living on several devices.  Since then, every shared-state seam
  has hand-rolled its own merge:
- **`Heard_mirror_merge`** (`Heard.g:379`): per stamp, newest timestamp wins, plus a special case so an un-ticked LOFI can
   travel (the "listing copy only ever adds" bug, 2026-10-04).
- **`Swarm_crew_heard`** (`Swarm.g:241`): the crew ledger, signature-gated.
- **`Swarm_charter_heard`** (`Swarm.g:8280`) and **`Swarm_roster_heard`** (`Swarm.g:8037`): the charter and the roster.
- **`Repli_merge`** itself, with its identity table and `.c` shadow.
- **Pier marks** (☆/notes) — deliberately kept browser-local (2026-10-14) precisely because there was no merge to trust.

Each one re-decides "same thing?", "who wins?", "what about a delete?" and "what about a refusal?" on its own, and each
 has had its own bug where the answer was subtly wrong.  That's the anonymous-wake disease (Case study irritation 4) in
  data form: no shared organ, so everyone re-derives.

### The organ, in four rules (design, unbuilt)

1. **Pair with `resolve()`, on DECLARED identity.**  Identity is minted by whoever mints the thing (an id, a tok, a
    prepub), never inferred from content: inferred identity makes every rename a goner+newborn and every re-parse churn.
     `c.vyto_tok` is the precedent.
2. **Arriving data is a CANDIDATE, not the truth.**  It lands beside the canonical, and a per-kind POLICY accords it:
   - *derivations* (computed from the canonical; can only be stale) auto-accord;
   - *proposals* (want to become the canonical) need a rule or a person.
   "Newest stamp wins" (heard), "signed by the soul wins" (crew/charter) and "the sender owns it" (a friend's shelf: today's
    sole-writer case, now just one policy among several) are all policies, not separate mechanisms.
3. **Key-level memory is a sphere, not a smear.**  Per the owner's 2026-08-05 framing in `Repli_design.md` §5, the
    "what did I last send/accept for this key" memory is a second sphere in `D/*`, stitched at each particle.  It's a real
     C** that can persist, so restarts stop splitting twins.
4. **Refusals snap, with their reason.**  A refusal that lives on `.c` is re-offered forever.  The machine must remember
    what it declined and why, the same as what it took.

### Lineage and naming (owner, 2026-10-15)

- **LE came first, and Repli was written knowing it**, which is why Repli reused `Selection`/`resolve()` and why
   `Repli_design.md` asks to move onto `i_Seem`/`o_Seem`.
- **Se becomes known as Merge, eventually.**  `Selection` (the "Se") is the pairing engine both halves stand on.  It's on
   the same development path as `Cstructures_todo.md` §3, "what the Se wants": every saying carries its provenance
    (`by:` which engine, `rule:` which law, `hid:` what it subsumed, `pass:` when).  That's rule 4 above generalised: not
     only refusals but every merge decision states why.  The thing that holds state and reacts in certain ways.
- **"Bi-directional Repli" was never built.**  Today each side runs its own one-way Repli of its own shelf; friends mirror
   each other through two channels.  The real two-way case is the crew: two bodies of ONE soul writing the same ledger.
    That's what the hand-rolled merges above are doing.

### The next iteration — not a port, a successor

Owner: *"the next iteration will be another LE|Repli thing.  LE is going away, and Repli should be easily replaced by a
 more mature and feature-achieving version of itself… having it stream over the wire, be distributable, like fractures of
  conversations on the fediverse drifting by that can load their earlier bits."*

So the old "port Repli onto i_Seem/o_Seem first" is dropped.  The successor (call it Merge until it's named) is built new,
 keeping only what's twice-validated (`resolve()` pairing), and is shaped by these properties:

- **Fractures, not dumps.**  The unit on the wire is a fracture: a piece of a weave (a few particles, or one change)
   carrying its declared identity and a reference to what it came from.  A receiver can hold a PARTIAL weave.
- **Earlier bits load on demand.**  Like a fediverse reply drifting into your timeline, you can see it without the thread,
   and ask for its ancestors when you want them.  A fracture names its parents, and any holder can serve them.  Today's
    `repli_want` (pull the offsets you lack) is the seed of this, but it only knows "pages of one record".
- **Distributable.**  A fracture is valid from whoever holds it, not only its author.  It is authenticated by its own
   signature, not by the road it came on.  That's the same move as the signed call (`Signed_call_todo.md` §3) and the WT session
    keys (`Trust_todo.md` §1.3).  SoundPooling already distributes audio this way; Merge does it for state.
- **Streams.**  It applies as it arrives, in any order the parents allow.  No "whole catalog every 60 s" (Perf §7: R4c).
- **Candidate + policy + provenance** (rules 2–4): arriving fractures are candidates; a per-kind policy accords them; every
   decision, and every refusal, leaves its `by/rule/why`.

### Point (c), expanded: prove the organ on ONE known-answer merge

Before anything new rides it, the organ must reproduce a merge we already trust, exactly.  The heard mirror is the case:
- **Today:** `Heard_mirror_merge` (`Heard.g:379`) walks a sibling's Cards.  For each one, per stamp key, the newer
   timestamp wins.  Listing keys copy over when a stamp advanced, and `lofi` follows the press exactly.  That's about 25
    lines of hand logic.
- **On the organ:** the sibling's Mag arrives as a candidate; `resolve()` pairs Cards by their declared identity
   `(id, pub)`; the policy is "per key, max stamp; listing keys ride an advance; lofi rides the press".  The organ produces
    the accorded Mag and the provenance rows.
- **The proof:** MusuHeard, MusuMagnet and MusuHandoff stay byte-identical, with the old function deleted.  If the policy
   can't be said in a few lines, or the fixtures move, the organ's abstraction is wrong.  We'd learn that cheaply, on a
    merge we already understand, before trusting it with crew ledgers or the wire.
- **Why that one:** it's small, well fixtured, single-policy, already multi-writer (Captain + Cave), and it has had the
   exact class of bug the organ exists to end (the un-ticked LOFI that couldn't travel, 2026-10-04).

### What it unlocks

- **Pier marks** (☆/notes) that follow you across your Caves, which are browser-local today because nothing could merge
   them safely.
- **The crew's ledgers** (crew, charter, roster) without per-kind merge code.
- **Eventually the editor and runner sharing one weave.**  Today the editor compiles a `.go` and ships its bytes to each
   runner (`LiesStore_good → land_good`), and Atheory's case-study irritation 3 is that delivery being polled.  With Merge,
   code changes would be fractures like any other, pushed to the bodies that hold that ghost.

## Progressive startup — what we know (2026-10-18)

The owner: Book:Sounditron is *"for watching the machine progress through important steps of its boot towards
 playing music"*, and *"there could actually be layered and differently scoped Story going on at the same time…
  one watching basic startup that is blind to the more specific core of activity… multiple Story Book-expectors
   and their wills to control the one Runtime could cooperate"* — **separate booting from testing, with the same
    Story2 tech.**

**What's settled:**
- **The 1-step cold toc is fixed.**  `AppTreeNav` (`MountNav.svelte.ts:225`): a music folder with no `wormhole/`
   reads its app tree from `.jamsend/wormhole/` (their disk, the upper layer) over GitHub (the lower layer, and
    reads that miss upper WAIT for it), so a stranger gets the full 8-step Book rather than recording a fresh one.
     `.jamsend/` is the app's own namespace at the root of the Wormhole share (`account/`, `wormhole/`).
- **storyFinished remounts nothing.**  Live on eed8 (`?I=eed831f1977c4e81`, booted 09:56:45): from `📚 storyFinished`
   on, the console shows no destroy, no `life mount`, no Cello re-intent — only the Cred spool, then music.
    `Auto.svelte`'s handler just spools and reports.  The BigSoundland `cyto` derive has been held by `glass_hold`
     (6s) since 2026-08-31, and an end-user page draws Cello, not that glass.  The Cyto integration is going anyway
      (owner): *anything* should be able to hook a Story's progress to animate off the underlying structure.
- **The live check run is a clock, not a test.**  All 8 steps `mismatch accepted (lenient)` on a live tab.  It
   only counts beats.  `story_save` still runs on a humdinger (`toc unchanged, not rewritten`; harmless here, but
    `Story_future_directions §5.3` is unbuilt).

**The beats, sorted.**  Sounditron is mostly an expector already: most beats `expecting()` a machine fact.  The few
 that DO things are the ones the cold-boot patches had to pull out.

| n | desc | does (machine) | waits for (expector) | eed8, 2026-10-18 |
|---|---|---|---|---|
| 1 | — | `Sounditron_glass` (organs + Vyto commission) | — | 0.6s |
| 2 | the machine stands | supervise, glass again | `stoker_wait` 15s: the shelf stocked | 0.3s |
| 3 | the relay answers | — | `relay_wait` 10s: the channel live | 0.4s |
| 4 | who could we reach | `Sounditron_muse` | `muse_wait` 4s; tallies Possibilities | 0.4s |
| 5 | reach for a peer | **`Swarm_hi_all`** | `peer_wait` 20s with a music friend, else 2s | **20.2s**: 20 piers, `who_ok 0/6 online` |
| 6 | does sound run here | `Sounditron_listen` | `sound_wait` 6s: the probe | 3.1s |
| 7 | the music runs | — | `music_wait` 20s | **20.4s**: timed out |
| 8 | sum and report | — | — (tallies Session) | 0.5s |

Music started 09:57:49, 7s after storyFinished (`dial` → `Fourier Four — Query E ← @Grav+eed8 [pool]`).  Whether a
 gesture or `Radio_autopress` pressed it isn't in the log; the AudioContext started in the same ms.  Of 56s of Book,
  40s was two waits timing out on a peer nobody could reach.  Before the Book, `Liesui ready in 15.3s` (11.4s of it
   app→Lies).

**The shape this points at:** the machine-doing cells (glass, supervise, `hi_all`, muse, listen) stand on the page's
 own heartbeat, declared by the A** manifest.  Every beat becomes an expectation, and several Books can watch one
  runtime at different scopes: a startup Book blind to the core, a Radio Book that sees only the core.  Each expector
   that wants to *drive* (a Book's hand-crank) has to ask, which is a will over the runtime and the same question as
    the focus authority below.  The tell to enforce: an `if (n === k)` doing app work.  Only expectors read `step_n`.
     The cost is re-recording Sounditron and the Musu/Vyto fixtures that ride it, once, deliberately (today the humdinger
      gate keeps them byte-identical).

## The app's own storage — `.jamsend/`, surveyed (2026-10-18)

The owner: Berth *"needs moved into the foundation of the app… where-ever we hard-code .jamsend should probably be
 DOTAPPNAMESTORAGEDIR or something?  part of Jamsend is the app-supporting foundation."*

**One door already.**  Every user reaches disk through `A:Wormhole.c.nav`, a MountNav (`Crate_nav`, `Crate.g:131`).
 Aiming is by longest-prefix mounts keyed on the literal path strings, so callers spell `.jamsend/…` and the foundation
  re-aims some prefixes:

| prefix | where it really lands | set up by |
|---|---|---|
| `wormhole` (music folder, no `wormhole/`) | `.jamsend/wormhole/` on their disk, over GitHub | `AppTreeNav`, `Housing.svelte.ts:2625` |
| `.jamsend/account`, `.jamsend/identities` | a separate credentials folder, when one is granted | `Wormhole_mount_creds`, `:2641` |
| `pool/` | OPFS | `Wormhole_mount_pool` |
| `.jamsend/berth`, `.jamsend/radiostock` | the share, beside the music (deliberately unmounted) | — |

**The hard-coded spellings:**
- **Ghosts:** `Heist_meta_dir()` returns `'.jamsend'`, a helper nobody else uses.  The rest spell it out:
   `Berth_dir` and its sweep (Heist.g), `Ra_stock_dir` (Ra.g; its file extension `.jamsend_radiostock` too),
    `Swarm_account_dir` / `Swarm_roster_dir` (Swarm.g), and HeistTesting's `ogg-export` and `lossy-proof`.
- **Foundation:** Housing's AppTreeNav root and creds mounts, and **the serve wall**: the relay refuses any path with
   a `.jamsend` segment (`Housing.svelte.ts:2792`, "owner-local — never served over the wire").  On the node side,
    `NodeWormholeNav` keys its 0600 file mode on the same segment, and `scripts/daemon/main.ts` mounts it.
- **Tests and logs:** `MountNav.spec.ts` (18), Auto's log lines.

**The move:**
1. **One constant — DONE 2026-10-18: `APP_DATA_DIR` (`src/lib/app_data_dir.ts`, dependency-free).**  Every code spelling
    reads it: Housing (app tree root, creds mounts, the serve wall), NodeWormholeNav (0600/0700), the daemon, and the ghosts
     via `IMPORT()` (Heist, Ra, Swarm, HeistTesting).  It is one spelling, not a rename: the value stays `.jamsend`, or every
      existing disk is orphaned.  Left literal on purpose: `MountNav.spec.ts` (it pins the on-disk value), comments, a snapped
       `%see` sentence, and Ra's `.jamsend_radiostock` file extension (a file-format name, not the dir).
2. **Berth into the foundation.**  `Berth_dir/open/save/append/fold/reset` live in Heist.g (`//#region berth`), but they
    are encoders-only and zero-Lies, and Heist is their only caller (KeepMemo, Heists, HeistDefaults, Newlyadded, Musica,
     Faves/Zines).  Anything else wanting a per-identity Waft must have Heist loaded, which is the load-list disease again.
      They belong beside the Wormhole verbs, so Swarm, Radio and Story can use them directly.
3. **A humdinger's run records go to a berth.**  `Story_future_directions §5.3` wants a music page never to write
    fixtures into the app tree, or only to "a scratch path never read back".  Today it saves through `wormhole/`, i.e.
     `.jamsend/wormhole/`, where a short copy could shadow GitHub again.  A per-identity berth is that scratch path.

## Not yet

The toplevel inventory (what happens between page-load and commission) is half-owed: the post-Lies half is the
 table above, the 15s before it isn't measured.  §0's second irritation has a direction (above), not a design.  The A** shape
  above addresses the LOADING half's dispatch and identity; it does not on its own make the toplevel
   walkable.

## Its twin: the focus authority (`Focus_todo.md`)

The toplevel has TWO jobs and this doc names only one.  Atheory is the **loading** half (what code
 mounts onto the base Housing).  `Focus_todo.md` is the **attention** half (which fullscreen surface
  commands the user's screen at each moment — the "who's stealing the user's focus" the owner asked
   to have *"formulated carefully"*, 2026-08-28).  They meet here: the rebuilt toplevel should OWN
    the §3 focus authority from `Focus_todo` and stand it up early, rather than re-scattering the
     seven fullscreen surfaces that today each decide for themselves.  Design either without blocking
      on the other; land the focus coordinator on today's toplevel first to de-risk the rebuild.
