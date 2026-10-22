# Atheory — the design

*Started 2026-10-20 (owner: "start an Atheory_design, to flesh out later, and carefully collect all the changes we make to
 Housing or Stuff there").  Two jobs:*

1. *§1 — **the design as it stands**: what Atheory IS, one section per organ that has been built and proven by a Book.
    A skeleton for now, to flesh out later.*
2. *§2 — **the foundation ledger**: every change Atheory makes to `Stuff` or `Housing` (and what sits right beside them),
    collected carefully, so the foundation's drift is always readable in one place and every change can be taken back out.*

*The working doc stays `Atheory_todo.md`: the owner's rulings (§0.1), the loop queue and how each slice was built (§0.2),
 the antipatterns (§0.4), and the case studies.  When this doc and the todo disagree about what is BUILT, this one is
  meant to be right; about what to do NEXT, the todo is.  This is not a spec: only the owner promotes a doc.*

## 0. Words

*The words Atheory's design uses, as built.  The rows say which particle or function carries each.*

| word | means | carried by |
|---|---|---|
| **compartment** | one place that holds state and runs code on it; today an A's world (the tank) | `A:<name>` › `w:Athe_Tank` |
| **row** | a thing that lives in a compartment: an egg, a fish, the heron | the kinds its Sunpit passes over (`TheA_rows`) |
| **pass** | one handler over all rows of one kind, before the next pass | `%TheAPass:<Kind>` under `%TheASunpit` |
| **frontier** | which rows a pass sees: as they stood when the pass began (default) or when the turn began (`frontier:turn`) | the `%TheASunpit` line's culture |
| **pond turn** | the toy's own clock tick: eggs hatch, fish lay, the heron eats | `Turns,count`; each row's `born` |
| **synapse** | a standing inlet on a compartment: what it wakes, how its pulses sum, who it hears (`from:`) | `%TheASynapse:<name>,wake,sum[,from]` |
| **axon** | what a compartment sends on; it never looks for who hears | `%TheAAxon:<synapse name>` |
| **pulse** | one message: "something happened", maybe carrying a thing (a fish's name and age) | `%TheAPulse` |
| **inbox** | the pulses waiting on a compartment's synapses when its move begins; nothing new arrives during a batch | the synapses' `%TheAPulse` rows |
| **outbox** | what a compartment sent during this batch, not yet heard by anyone | `%TheAOutbox` (present only while in flight) |
| **move** | one compartment's go: reads only its own rows and inbox, writes only its own rows, sends only into its outbox | `TheA_move(w, wake)` |
| **boundary** | the end of a batch: every outbox is delivered to the synapses that hear it, in a fixed order | `TheA_boundary(names)` |
| **batch** | some moves, in any order, then the boundary.  No move sees another move of its batch, so order can't show | `Athe_Tanks_wake(names)` |
| **Turn** | the record of one synapse's part in a move: pulses eaten, code it ran under, rows new and gone, pulses sent.  Not a counter | `%TheATurn` with `%TheANeu`, `%TheAGoner`, `%TheASent` |
| **history** | a compartment's kept Turns (the Was-sphere, by its working name) | `%TheAWas,keep,made` |
| **reader** | someone reading the history; a Turn stays until every reader has read it | `%TheAReader:<name>,at:<Turn>`, `TheA_read` |
| **code push** | new code arriving at the As that hold it, let through by Story between steps | `%TheACodePush`, `%TheACodeTaken` |
| **A\*\*** | As standing in As.  Where an A stands says which code it runs (its ancestors' layers, then its own) and what it is served (the nearest) | `A:Pond` › `A:P`, `TheA_all`, `TheA_up` |
| **version** | one arrival of a compiled file, kept by its dige; an A runs the version its layer names | `House.ghost_versions`, `%TheALayer,dige` |
| **speaking as an A** | the House, but a method name resolves first on the A's own versions | `TheA_as(A)` |
| **served** | given the nearest matching thing, walking out through the As one stands in — never sideways, never from the top | `TheA_near(A, sc)` |
| **Seem** | a controller over a compartment: it walks the rows of the kinds it holds and keeps a point for each | `%TheASeem:<name>` with `%TheAKind` rows; `TheA_seem_walk` |
| **point** (Trace) | the Seem's reading of one row, paired walk to walk by what holds still (its name), so it survives a change of kind | `%TheATrace:<kind>,of:<name>` |
| **Regard** | another organ's opinion of a point, kept ON the point, so it lives and dies with it | `%TheARegard:<sphere>` under a point; `%TheASphere:<name>,tense:Regard` declares it |
| **mark**, **rollback** | a kept copy of the points; rolling back mints the rows again from it, and the points re-pair | `%TheAMark:<label>,dontSnap`; `TheA_seem_rollback` |

**Why synapse and axon (2026-10-21, renamed from wire and outlet).**  "The wire" already means the network — the relay,
 the socket, Waft:Ghost/Everything's first What.  A synapse is held by the RECEIVER and says what it wakes and whom it hears;
  an axon is what the sender sends down, blind to who hears.  The receiver declares, the sender doesn't address — which is
   also what separates a pulse from an elvis (sender-addressed); see Atheory_todo §0.0.

**One principle at two scales: nobody sees a write from the same round.**  Inside a compartment, the frontier gives each
 pass a snapshot of the rows.  Between compartments, the boundary gives each move a snapshot of the pulses.

## 1. The design as it stands

*Each part: what it is, where the code lives, the Book that proves it.  To flesh out.*

### 1.1 Where the code lives

- `Ghost/A/Theory.g` — the organ.  Particles all start `TheA`, so one grep finds every one.
- `Ghost/A/AtheFishTesting.g` — the toy, `Athe_Tank`: Pond's rules on its own turn clock.  Its own file so the toy's
   `%TheACode` names only the code it runs.  It holds only the toy's handlers (egg, fish, heron, arrive) and its hand-written
    Sunpit; moves, sends, the boundary, Turns and readers are Theory's (since 2026-10-21).
- `Ghost/A/AtheTesting.g` — the Books' routines.  Books are named `Athe` + toy + what they prove, and each has a row in
   Waft:Credence (`wormhole/Credence/toc.snap`, `What:Athe`).

### 1.2 An A holds its code — `AthePondCode`

```
A:Athe_Tank
  %TheACode:Athe_Tank,variant:plain,dige:…        the chain digest over its layers (absent until all load)
    %TheALayer:Ghost/A/AtheFishTesting.g,dige:…   one compiled .g, and the digest of the code loaded for it
    %TheAClobber:<method>,won:<Ghostmeta_…>       a method two of its layers define, and whose copy is live
```
An A arrives WITH its code (`TheA_stand`).  Where each method came from is read off the foundation (§2: `ghost_origin`,
 `ghost_files`).  Atheory does no method lookup: code calls methods by name.

### 1.3 CodePush — `AthePondCodePush`

Code compiles centrally and is pushed to the As that hold it.  `ghostsHaunt` announces each compiled file (§2); every A
 whose `%TheALayer` names it gets a `%TheACodePush` row.  In a Story run the row waits until Story lets it through at the
  next step (§2, the step seam); elsewhere it goes at once.  Going through is an elvis, `e_TheA_code_arrive`: the code is
   stood again, counted in `%TheACodeTaken`, and the A thinks once.
**What you can observe today is bookkeeping only** (owner asked, 2026-10-21): the push waiting, the count of pushes taken,
 and the digest, which every `%TheATurn` now carries as `code_dige`.  The Book pushes the SAME file, so behaviour can't
  change.  Two ways to a visible effect: (a) a live hot-swap, where someone edits the toy mid-run, Story lets it through at
   the next step, and the Turns after it show a new `code_dige` and the new behaviour.  That proves it once, but it can't be
    a Book with fixtures.  (b) the A** shape (§1.11, built 2026-10-21 — `AthePondVersions`), so two versions of the code can live in one heap and a Book can push
     the second one.  (b) is the real one.

### 1.4 The Sunpit, by hand — `AthePondSunpitPassOrder`, `AthePondSunpitFrontier`

A turn's order is declared on the world: `%TheASunpit:turn` holding `%TheAPass:<Kind>` rows, each "this handler over all of
 these, before the next".  Keys on the `%TheASunpit` line are its culture: `frontier:turn` (take every pass's rows once, at
  the turn's start) and `gone:skip` (pass over what has left since).  Order is data; which code runs for a kind is not.

### 1.5 Synapses, moves and the boundary — `AthePondSynapseSum`, `AthePondSynapseOrder`

`%TheASynapse` is a standing inlet on a compartment: what it wakes, and how its waiting `%TheAPulse` rows sum (`sum:count`,
 once per pulse; `sum:latest`, once for the lot).  `%TheAWoke` keeps how often it woke and how many pulses it ate.

**The boundary (2026-10-21, replacing a synapse-ordered scheduler).**  A batch is moves and then the boundary (`Theory.g`,
 "Moves and the boundary").  A move reads only its own rows and its inbox, writes only its own rows, and sends only into its
  own `%TheAOutbox`.  `TheA_boundary` delivers every outbox to the synapses that hear it, senders by name, so nothing about
   the order things happened in can show.  A compartment even tells itself this way: the turn that changes the fish sends on
    the tank's own fish synapse, and the heron wakes at the NEXT move (`AthePondSynapseSum`).
**So the order of moves can't matter, and neither can stopping between them** (`AthePondSynapseOrder`): a batch taken one
 move per Story step, with P's two old fish sitting in P's outbox while Q moves, comes out the same as one taken whole, and
  pairs woken in opposite orders come out the same.  Every move is one coherent step to watch: `(rows, sealed inbox) →
   (rows, outbox)`.  The cost is one batch per hop.

### 1.6 Order doesn't leak — `AthePondWakeOrder`

Two compartments with nothing between them come out the same whichever is woken first.  What breaks that is reaching into
 another compartment: a tank naming its eggs from another tank's counter (`%NamesFrom:<A>`) reads and writes it in the
  middle of a batch, so the eggs swap names depending on who woke first.  The boundary forbids exactly this, and the Book
   keeps it as the sabotage.  **Anything compartments share travels as pulses** — or isn't shared (`%NamesAs:<tag>` makes
    each tank's names its own).

*Superseded 2026-10-21:* the first fix declared the sharing as `%TheASynapse:names,from:<P>` and had `Athe_Tanks_wake` order
 the batch along synapses; loops then needed `lag:1` and a `%TheALoop` warning.  The boundary made all three unnecessary.

### 1.7 Code digests are pseudo-muted — `tol:same` (`EntropyArrest.md` §11)

Every edit to a toy moves its digest in every snap that shows it.  The `dige:` spayer now forgives that only as a
 consistent substitution over the run (each old digest → one new one everywhere, never two into one), and such a step is
  plainly ok, no caveat.  So a code edit costs no re-baselining, and a digest that moves in one place but not another reds.
   Proven 2026-10-20: a comment-only toy edit left all six Athe Books green, caveat 0, fixtures untouched.

### 1.8 A pulse that carries something — `AthePondStream`, `AthePondLoop`

P holds `%TheAAxon:stream`, Q holds `%TheASynapse:stream,from:<P>,wake:arrive`.  A fish too old for P (`OLD_AT`) is sent
 with its name and its age; it lands on Q's synapse at the boundary and arrives at Q's next move.
**What crosses is the age, never the birth turn.**  Each tank's time is its own (`Turns,count`); P is stood nine turns
 ahead of Q, so P's two old fish arrive born before Q's first turn (`came:<P>`), and leave Q on its next turn while Q's own
  oldest are ten.  The rule: **a pulse between compartments carries quantities in the receiver's terms or in no one's** (an
   age, a count), never a reading of the sender's clock.

**A loop needs nothing special.**  With streams both ways, a loop is simply two batches round; pairs woken P-first and
 Q-first come out the same, and P's first two fish go round for good, always in a tank or on the synapse between.

### 1.9 The Turn, by hand — `AthePondTurns`

Step 4 of the scheduler sketch ("commit one `%TheATurn`"), in `Theory.g` (`TheA_turn_commit`, called by `TheA_move`).  A compartment holding `%TheAWas,keep:<n>` (the
 Was-sphere, by its working name) commits one Turn each time a synapse wakes it:

    TheAWas,keep=3,made=5
      TheATurn:3,synapse:clock,pulses=9,code_dige:…
        TheANeu:Fish,of:carp 3        ← a row that wasn't there before the wake
        TheANeu:Egg,of:roach 5
        TheAGoner:Egg,of:…            ← a row that's gone

**A Turn is not a counter.**  Three clock pulses woken together are three pond turns (the tank's `Turns,count`, its
 clock) and ONE Turn.  What a Turn says changed is what changed ACROSS it: an egg laid and hatched inside one wake shows
  only as the fish it became.  A Turn that changes nothing is still a Turn.  `code_dige` is the A's `%TheACode` digest, so
   `tol:same` mutes it with the rest.

**Readers behind the history — `AthePondTurnReaders`.**  "Turns drop when no reader is behind them": a
 `%TheAReader:<name>,at:<Turn id>` on `%TheAWas` has read every Turn up to `at` (`Athe_Tank_read(w, name)` returns what's
  new and moves `at`).  A Turn stays while any reader hasn't read it, whatever `keep` says; once every reader has, only
   the last `keep` stay; with no readers, `keep` alone decides (`Athe_Tank_was_trim`).  So the slowest reader holds the
    history: with keep:2, a reader that waits keeps Turns 1–3 alive, and its catching up drops Turn 1.

### 1.10 Each oath bites — sabotaged once (2026-10-21, before the boundary)

Homethink §3: each test can be sabotaged once to prove it bites.  Three sabotages went into the toy together, the three
 newest Books ran once in check mode, and the toy was put back byte for byte (checksums) and re-run green:

| sabotage | Book | oaths that stopped swearing | still sworn |
|---|---|---|---|
| S1: an arriving fish is `born: turn` (its age resets) | AthePondStream | keeps its age · the old fish leave on Q's next turn | carries nothing while young · swims down, gone from the first |
| S2: `Athe_Tanks_wake` ignores `lag` (and S1) | AthePondLoop | a lag breaks it · each lagless-loop tank is told · the first two fish go round | the loop leaks the asked order |
| S3: the Turn's "before" is taken after the runs | AthePondTurns | says what changed across it · laid-and-hatched shows only as fish | one Turn per wake · names its code · empty Turn kept |

Each oath fell to the sabotage aimed at it, and only to that: the unrelated oaths in each Book kept swearing.

**The boundary, sabotaged once (S4, 2026-10-21).**  `TheA_send` delivered straight to the hearing synapses instead of the
 outbox.  These stopped swearing: SynapseOrder "what a tank sent waits in its outbox" and "opposite orders come out the same";
  Loop "a loop needs no order"; SynapseSum "the fish pulse waits for the next move".  Still sworn, rightly: SynapseOrder "a batch
   taken one move at a time comes out the same" (with no outbox the stepped pair and the whole pair both deliver at once)
    and all of Stream (its batch is asked Q first, so even instant delivery reaches Q a batch later; Stream proves the age,
     not the boundary).  Restored by checksum and re-run green.

**A\*\*, sabotaged once each (S5, S6, 2026-10-21).**  Each predicted before it ran; each came out as predicted.
- **S5 — `TheA_near` from the top** (the first `%Weather` in the House, as a `top_House()` lookup finds a Supervisor).
   Nest lost only "a tank is served the weather of the pond it stands in": the cold tank found the warm pond's weather
    and laid (roach 5, bream 6 at turn 13).  Versions and SynapseSum stayed green: no other Book has weather.
- **S6 — `TheA_as` answers with the flat House** (every A runs whatever was merged last).  Versions lost "after the seam
   V_Q runs the version it was pushed" and "the twins version lives only on V_Q" (no twin fish anywhere); Nest lost "a
    version pushed to a pond reaches the tank standing in it".  Still sworn, rightly: the push waiting and V_Q's code row
     (both bookkeeping, true whatever code runs), and Nest's "a tank with no code of its own runs its pond's" — **a gap**:
      the pond runs the loaded version, which is also what the flat House runs, so that oath can't tell them apart.  Its
       step-6 oath (the pushed pond's twins reach its tank) is what really proves heredity.
 Both restored by checksum and recompiled; the runner needs a reload before its next Book.

**Spheres, sabotaged once each (S7–S9, 2026-10-21, `AthePondSeem`).**  All three predicted in `Atheory_todo` §0.5 before
 they ran; all three came out as predicted, and the oaths not aimed at kept swearing.
- **S7 — the walk pairs strictly** (`resolve_strict`: a changed value is a new point).  Lost: "an egg that hatches is the same
   point" (the hatch became a goner Egg and a neu Fish) and "rolled back… the same point, still regarded".  Even `Turns`
    became a new point every walk.
- **S8 — rollback forgets `EggsNamed`.**  Lost: the rollback oath and "turned on from the mark… the same" — the eggs of turn
   22 were named tench 17… instead of carp 13….
- **S9 — regard kept beside the points, keyed by name** (the `.c`-by-name smear, in particles).  Lost: "a fish the heron
   eats takes the eye's regard with it" (the regards of minnow 1, perch 2 and the eaten fish lingered) and the rollback oath
    (the eaten fish came back with their old regard).
- **S10 — a two-way merge** (`AthePondMerge`; no base, theirs taken wherever it differs).  Lost: the refusal (carp 3 came
   across with N's birth, as a `TheATook:changed`), "only N's change comes across" (two takes, not one) and "merging again" (no
    refusal to say again).  Still sworn: "kept once".  The three oaths are coupled; predicted so before running.
- **S12 — a move that forgets the epiphytes** (`AthePondMoves`).  Lost: only "a fish that swims from P to Q is one point that
   moved — the eye's regard went with it" (the travellers arrived unregarded; the eye saw them afresh at walk 4).  Limbo's two
    oaths held.
- **S8 again, on the K shape** (marks in the Was): the same two oaths fell, the same two held.
- **S13 — merge pairs by key (kind and name) instead of through `resolve()`** (`AthePondMergeHatch`).  Lost both oaths: trout 4
   came across as an egg gone and a fish new, and carp 3 was refused as an egg AND minted as a fish — one name, two rows.
    `AthePondMerge` stayed green, as predicted: there both sides hatched alike, so key pairing got it right by luck.
 Restored by checksum before the next code went in.

**The scheduler, sabotaged once each (S14, S15, 2026-10-21, `AthePondRounds`).**  Both predicted in the todo before running.
- **S14 — the ambient way** (every A moves every round, as `think` does).  Lost all three step-3 oaths: R, and even the Book's
   own A, went every round from round 2, and the run never went quiet (`rounds=50,cut`).  Held: "a run with nothing poked takes
    no rounds" — with nothing ready the sabotaged loop never starts.
- **S15 — the boundary readies nobody.**  The run stopped after round 1; P's two old fish sat as pulses on Q's stream synapse,
   never arrived.  Lost: "a pulse sent in one round readies its receiver" and "goes quiet by itself — two rounds".  Held: R
    never visited, and the step-4 oath.
 Restored by checksum and recompiled; the runner needs a reload before its next Book.

**The era seam, sabotaged once each (S16, S17, `AthePondEra`) — predicted 2026-10-21 before running; BOTH BIT AS PREDICTED** (each lost exactly `a-run-takes-waiting`, 2 of 3 sworn; under S17 snap 4 showed `TheACodeTaken` with no `TheAArrived` — Story’s seam took it).  Restored by checksum and recompiled:
- **S16 — the run takes the code but doesn’t ready its A.**  Step 3’s rounds are `Clock_A` then `K_P K_Q`, with
   `TheAArrived:K_P` and the push taken — so only "a run takes waiting code before round one — that A moves in round one…" falls.
    Held: the mid-step oath (sworn before the run) and step 4’s.
- **S17 — the run doesn’t take at all.**  K_P’s push still waits after step 3’s run, no `TheAArrived` — the same step-3 oath
   falls.  Story’s seam at the start of step 4 then takes it (an elvis), so step 4 still shows `TheACodeTaken,count=1`, nothing
    arrived in its run — its oath HOLDS.  That is the tell that Story and the era seam are two seams for one thing.

**Time as IO, sabotaged once each (S18–S20, `AthePondTape`) — predicted 2026-10-21 before running; ALL THREE BIT AS PREDICTED** (S18 lost only `the-host-turns-the`, no `Spare` row; S19 lost all but step 3’s, no `Tape` rows and empty `EndedAgain`; S20 lost only `replaying-the-tape-runs` — `Tape:1,ms:1000 400 900 2300` and one `Replayed:1,rounds:Host +4 / Clock_A +8 / K_P K_Q`).  Restored by checksum and recompiled; all 23 AthePond Books green after.
- **S18 — the host ignores the ms: one beat per arrival.**  Step 3 still ends with `Beats,count=4` (1 + 2 + 1, by chance) but
   no `Spare` and different runs, so only "the host turns the outside’s ms into whole beats…" falls.  The replay oaths HOLD:
    a replay reproduces whatever the code does with the tape — it proves the tape is the whole outside, not that the code is right.
- **S19 — `TheA_io` pulses but writes no Heard.**  No tape: step 2’s "time comes in only through the host — what the outside
   said is on its tape…" falls, and step 4 has nothing to play — "replaying the tape runs as the outside ran" and "a replay
    hears exactly the tape it played" fall (no Tape rows), and "the replayed tanks end as the live ones did" falls too (the
     replayed tanks never turn).  Held: step 3’s.
- **S20 — `TheA_move` doesn’t count takes.**  Every Heard says `take=1`, so the tape is one take of four arrivals and the
   replay is ONE run.  "replaying the tape runs as the outside ran" falls; "the replayed tanks end as the live ones did" HOLDS
    (one run of four beats is four turns either way) and so does "a replay hears exactly the tape it played" (it records the
     same wrong grouping).  The tell: an end state can’t see how the outside was cut into runs — the rounds can.

**A hold, sabotaged once each (S21–S23, `AthePondAsk`) — predicted 2026-10-21 before running; ALL THREE BIT AS PREDICTED** (S21 lost steps 3 and 4 — round 1 read `Clock_A K_P` with K_P still waiting; S22 lost steps 2 and 3 — `TheARun,rounds=2,quiet` with a wait standing — and step 4’s snap matched clean; S23 lost step 4 — `quiet,waiting` beside `Fed:worms`).  Restored by checksum and recompiled; all 24 AthePond Books green after (SunpitPassOrder red once on `swapping-the-egg-and`, green on the rerun — a flake to watch).
- **S21 — the run polls: every A holding a wait is readied in round one.**  Step 2 holds (K_P asks during round one, so nothing
   waits when the run starts).  Step 3’s rounds become `Clock_A K_P +1 / Feeder` — "a waiting asker is never visited" falls —
    and step 4’s `Clock_A K_P +1 / Feeder +1 / K_P`, so "the answer lands and ends the wait — the asker moves once more…" falls
     too.  A poll looks harmless (K_P’s move finds no pulse and does nothing) and is exactly the cost the scheduler exists to avoid.
- **S22 — a quiet run is taken for settled (no `waiting`).**  Steps 2 and 3 fall (both owe an answer and say nothing); step 4
   HOLDS — a settled run looks the same either way.  The tell: a wake taken for a hold can only be seen while something is owed.
- **S23 — the answer doesn’t end the wait.**  Steps 2 and 3 hold; step 4 falls — fed, but still `waiting=1`, never settled.

**A view, sabotaged once each (S24–S26, `AthePondView`, Stuffica.g) — predicted 2026-10-22 before running; ALL THREE BIT AS PREDICTED** (S24 lost B C D — step 3 `commits=2` with the digest unchanged; S25 lost A D — K_R walked every step, K_Q walked in K_P’s run; S26 lost C D — `dige:2` held through the hatch).  Restored by checksum; all 25 AthePond Books green after.  Oaths: (A) step 2
 "walked only when what it shows moved — commits once — K_R is never read"; (B) step 3 "plain equivalence stops the wire"; (C)
  step 4 "two turns and a hatch in one run are one commit"; (D) step 5 "what the hand does is IO — only that tank’s view is walked
   and commits".  The checks are on absolute commit counts, so a sabotage that adds a commit cascades into later steps.
- **S24 — no equivalence: every walked view commits.**  A holds (the first commit happens either way); B, C and D fall
   (K_P commits 2, 3, 4 where 1, 2, 3 were sworn).
- **S25 — every view walked every run, moved or not.**  A falls (K_R walked, and its empty sheet commits once against no
   digest at all); B and C hold (they check K_P and K_Q); D falls (K_Q walked in a run that only readied K_P).
- **S26 — equivalence by shape: the count of points.**  A and B hold; C falls (two eggs hatching into two fish is still two
   points — no commit, the screen keeps drawing eggs); D falls by the cascade (the food makes three points — one commit, 2
    where 3 was sworn).  The tell: equality must be on content; a shape check misses the most important change in the pond.

**A point’s name, sabotaged (S27, `AthePondView` re-recorded with oath E) — predicted 2026-10-22 before running; BIT AS PREDICTED** (sworn 1 of 5 — only A; snap 3 showed `Dip:seem,value:fig,i=4` with fig_1…fig_4 on two points and `commits=2`).  Restored by checksum; all 25 AthePond Books green after.  E (step 4): "a
 point keeps its name through a hatch — the fish is drawn under the egg’s key and no new name was claimed".
- **S27 — `TheA_dip` ignores the name a point already has: every walk claims a new one.**  The point keeps its old `%Dip`
   and gains another, so what a view says changes on EVERY walk: A holds (first commit), B falls (step 3 commits with nothing
    in the pond changed — a churning key is a change the screen can’t tell from a real one), C and D fall by the cascade, and
     E falls (the seed has claimed far more than two).  The tell: identity that isn’t kept leaks into equivalence.

### 1.11 A\*\* — As in As, each running its own code — `AthePondVersions`, `AthePondNest`

**Owner, 2026-10-21:** A\*\* is a recursive pile of A (`A/A/A/A`), and where an A stands in it has meaning — what code it
 runs, what it can reach — a landscape data flows through, which may fit a relational database.  The first meanings built:

```
A:Pond_Warm                                   %TheACode:Athe_Pond, one layer (the toy)
  w:Athe_Pond  %Weather:warm                  what the pond serves
  A:Warm_P                                    %TheACode:Athe_Tank, no layers: dige = digest(the pond's dige)
    w:Athe_Tank
```
- **Code.**  Housing keeps every arriving version of a compiled file by its dige (§2, `ghost_versions`).  `TheA_as(A)` gives
   the House with method names resolved first on the versions the A's chain holds, its ancestors' layers then its own.  A
    move's wake named as a string runs that way (`TheA_move(w, 'Athe_Tank_woken')`).  So **a newer version merged flat
     doesn't reach an A until its push is let through**, and two versions of one file run side by side (`AthePondVersions`:
      V_Q hatches twins, V_P and the House don't).  A push can name the version (`TheA_code_push_to`, `dige`, `variant`).
- **Heredity.**  An A standing in an A starts its chain digest from its pond's.  A pond taking a push stands its tanks' code
   again, so a version pushed to a pond reaches exactly the tanks in it (`AthePondNest`).  An A in an A isn't ticked by any
    House, so it takes a push directly at the seam instead of by elvis.
- **Services.**  `TheA_near(A, sc)` walks the A's own world, then each enclosing A's, outward.  A tank asks for `%Weather`;
   the cold pond's fish don't lay.  This is the cure the MusuRadioAim leak asked for (a Book's run finding the runner's
    Supervisor via `top_House()`), in miniature.
- **Still calls by name.**  Nothing looks methods up in a table; `TheA_as` only decides what `this` is.  Class methods of
   the House stay bound to the House (Svelte `$state` fields are private slots a Proxy can't reach).

**What it resists, and what it doesn't yet.**  Code an A runs through `TheA_as` waits for Story's seam.  Code called flat
 still hot-swaps mid-step: a Book's routine (`A:<Book>` dispatched by `do_fn_for`, which already has an unused `w_inst`
  seam), and routines that call the toy directly (`this.Athe_Tank_turn`).  Compiling during a run is safe once those go
   through their A too.

### 1.12 Spheres on a Seem — `AthePondSeem`

**Owner, 2026-10-21:** versions of data wait for inventing time on Seem and the spheres; Seem is probably the only data
 controller that can roll back.  The first slice (`Theory.g`, "Seem"; working notes in `Atheory_todo.md` §0.5):

```
w:Athe_Tank
  Egg:chub 9,born=19                  Said: the row
  TheAWas                             K, Was: the compartment's past, there only because something asked
    TheAMark:20,dontSnap              a holster of row copies kept at turn 20 (line snaps, copies don't)
  TheASeem:rows,walks=5               a Seem over the tank; its Selection rides .c
    TheAKind:Egg …                    what it holds
    TheASphere:eye,tense:Regard       a declared sphere
    TheATrace:Egg,of:chub 9,born=19    D, Trace: a point — what the machine believes the row is
      TheARegard:eye,seen=3           O, Regard: the eye's opinion, ON the point
    TheAWalk:5                        what the last walk saw: TheABecame / TheANeu / TheAGoner
```
- **Trace** (`TheA_seem_walk`) is Selection's D sphere over the compartment's rows.  `resolve()` pairs each walk's points
   with the last walk's by observed identity.  The Trace copies the row's sc (its mainkey's value as `of:`, then the
    rest), and `resolve()` pairs on whatever is least ambiguous — a name holds a point together while its kind and birth
     change (an egg that hatches is the same point, now a fish), and a nameless row holds by what else it carries.  D%\* is
      written once and never edited; D/\* is replaced each walk except its epiphytes.  **Owner, 2026-10-21: a kept copy is K,
       not D** — the first build marked by copying the Trace; marks now live in the Was.  (A slimmed, identity-only Trace was tried
        and put back: nameless data must pair as well as it can.)
- **Regard** (`TheA_sphere`, `TheA_regard`): another organ's opinion, an epiphyte on the point.  A paired point takes its
   epiphytes along (`resume_X`); a gone point takes them with it.  **Nobody tidies.**  Nothing is written into an
    undeclared sphere.
- **Rollback** (`TheA_seem_mark`, `TheA_seem_rollback`): a mark copies the rows into the compartment's `%TheAWas` (the same
   Was that keeps its Turns); rolling back mints the Seem's kinds again from it.  No mark, no rollback — and that's fine:
    rollback is for merges and time travel, not error recovery (code shouldn't throw; when it does, restart the run).  New particles, the same points — Regard survives by the alignment alone, and a point that died after the
    mark comes back new (seen afresh).  Turned on from the mark, the tank comes out as it did the first time.
- **Two identities, both kept.**  A Turn (`%TheATurn`) speaks particle identity (an egg went, a fish came); a Seem's walk
   speaks observed identity (one point became a fish).
- **A merge policy, as particles — `AthePondStampMerge`** (the heard mirror as a cartoon).  `%TheAPolicy:<kind>` on the Seem
   holds `%TheAStamp:<key>` (newest wins, per key, no base needed) and `%TheARides:<key>,on:<stamp>` (travels only when its
    stamp advanced).  A kind with a policy is decided by it alone (`TheA_merge_policy`), so where a policy speaks nothing is
     refused, and merging either way comes out the same; a rider with no stamp stays home.  A fork carries its policies.
      What `Heard_mirror_merge` does in ~25 hand lines is three particles here.
- **Atoms that move — `AthePondMoves`.**  `resolve()` pairs only siblings, so a fish down a stream is a goner under P and a
   newcomer under Q.  A Seem with `%TheAOver` lives on a pond's world and walks the As standing in it, then their rows (the
    A\*\* tree read by a Seem).  With `%TheALimbo,keep:<n>` (the Seem's own K: points it remembers losing) every gone point is kept whole, with its epiphytes and `from:`, for
     n walks; a newcomer with the same key is that point **moved** (`%TheAMoved,from,to`) and gets its epiphytes back.  An
      atom in flight is in neither tank, and limbo says so.  A heuristic, said as one: "same key, soon enough".
- **What outlives a reload — `AthePondReload`.**  `TheA_persist(A)` says an A as text (folding every `dontSnap` subtree to its
   line plus `folded:1`, since `enWaft` ignores the flag) and `TheA_thaw` stands it again: every `.c` is gone.  Trace points
    and their Regard come back; the first walk with a fresh Selection finds nothing new, and a hatch after it is still the
     same point.  A mark that doesn't persist comes back folded, and rolling back to it is refused (`%TheARefused:rollback,why`).
      This Book found that **Selection itself wasn't reload-safe** (its back-chain read `.c.T` off old Ds; §2, beside the
       foundation).
- **Snap policy is `dontSnap`**, already honoured by `snap_H`: the line prints, the subtree folds.
- **Rows held elsewhere, and only what is said — `AthePondGlass` (2026-10-22, Storica's ground).**  A Seem may read rows from
   another container (`seem.c.from`, `TheA_seem_source`; runtime, re-pointed when the pile is replaced; pointed at nothing it
    reads its own compartment, where there are none) and may keep only some keys (a Seem holding `says` keeps its `%TheASay`
     keys, maybe none — the row's name only).  So a screen keeps its views in its own compartment, and a view's equivalence covers
      only what it shows: feeding the same food again changes the tally's points and not the menu's, so only the tally commits.
       `Stuffica_view(w, name, kinds, ui, {from, says})`, `Stuffica_from`, and `Stuffica_refresh(w, names)` for a compartment
        no run moves.  5 oaths, green 3× on a live runner; AthePondView/Seem/Merge/MergeHatch/Nest/Code and LeafFarm unchanged.
- **A tree seen whole, re-seated — `AthePondReseat` (2026-10-22, Storica's snap panel).**  A Seem holding `%TheADeep` holds a
   whole tree: its kinds pick the top rows (`TheAKind:*` — any) and every row below is a point nested as the rows are — a snap
    decoded to C (`decode_wh_lines`), seen whole.  Pointed at ANOTHER tree it **re-seats**: each point pairs with the one it was
     (resolve(), as ever), so the names (Dips) hold still and a screen keyed by them moves nothing.  Each point says how the walk
      took it (`.c.how` fit|shift|neu, `.c.at`), and the walk tallies `%TheAWalk:n,reseat,fit,shift,neu,gone` (zeros absent).
       A re-seat commits even when the sheet says the same (`Stuffica_walked`): the screen now shows another pile, and what
        fitted is worth showing — that is the green glow.  Walked again with nothing moved it commits nothing and nothing glows.
         4 oaths, green 3× on a live runner; Glass/View/Seem/Nest/Merge, AtheStoryCode and LeafFarm unchanged.
- **Merge with a base — `AthePondMerge`.**  `TheA_seem_fork` mints a mark into a sibling compartment; both Seems hold the
   mark, now their base.  `TheA_seem_merge(ours, theirs)` takes theirs as a **candidate** and decides each row (by key) against
    the base rows: only theirs changed → taken (`%TheATook:changed|new|gone`); only ours → kept; both alike → kept once; both
     differently → **refused**, ours kept, and `%TheARefused,ours,theirs` stays in the snap.  Merging again changes nothing.
      **The candidate is handed to `resolve()`** (`TheA_pair`): each row stands in as its Trace sc, so rows pair across
       compartments by observed identity — the name holds still, the kind doesn't count.  So an egg hatched on one side is
        one change, and a hatch against a change is refused, never an egg plus a fish of one name (`AthePondMergeHatch`).

### 1.13 The scheduler, by hand — `AthePondRounds`

**Owner, 2026-10-21:** not a Housing change — a ghost that drives a House with no ambient think, until there's a lot of
 experience in this field.  "It's made of elvises wanting to go places — do we group computables?"  Yes, nested: **pass**
  (one kind of row, the Sunpit) ⊂ **move** (one compartment eats its pulses) ⊂ **batch** (moves, then one boundary) ⊂
   **round** ⊂ **era** (everything run under one set of code versions; a push lands between eras).

```
w:AthePondRounds
  TheARun,rounds=2,quiet              a run, stopped by itself
    TheARound:1,landed=2              round 1: P moved; the boundary landed two pulses
      TheAWent:RP_P
    TheARound:2                       round 2: Q moved; nothing landed
      TheAWent:RP_Q
```
- `TheA_run(at, wake, ready, most)` holds a **ready set** — the As something poked; the caller says who, an elvis from
   outside in effect.  It never scans for work.  Each round every ready A moves, then `TheA_boundary(names, ready)` adds every A
    a pulse landed on to the next round.  Nothing ready: quiet.  `most` only caps a runaway (`cut`).
- **Unwatched work costs nothing:** R, a tank with a clock and nothing on it, is never visited — none of its handlers run,
   nothing of it is read.  Housing's todo already does part of this by hand: repeated `think`s collapse (`sum:latest`), and
    `organise` is a Seem over the House; but every `think` still visits everything.
- **A clock is a compartment — `AthePondClock`.**  `w:Athe_Clock` (in the toy file) has one synapse, `poke`, and one axon,
   `clock`; each poke is one tick: it counts `Ticks,count` and sends on `clock`.  A tank's clock synapse names it
    (`from:Clock_A`), so which clock a tank keeps time by is a wire, not an ambient.  Nobody outside pokes the tanks any more —
     only the clock — and a clock nobody pokes never ticks, so its tanks are never visited.
```
TheARun,rounds=2,quiet
  TheARound:1,landed=6        the clock moved: three pokes, three ticks to each of K_P, K_Q
    TheAWent:Clock_A
  TheARound:2
    TheAWent:K_P              each tank eats its three ticks in one move (sum:count = three turns)
    TheAWent:K_Q
```
- **Pondland — a page whose top is `TheA_run`** (`/Pondland`, `src/lib/A/Pondland.svelte`; a sibling of Otro).  A bare
   `new House({name:'Pondland'})` — no `main()`, so no ambient think, no Lies, no Lang, no cluster — mounts the two `.go`s it
    needs as components (`Theory.go`, `AtheFishTesting.go`; their `onMount` is `H.eatfunc`).  It stands two clocks and three
     tanks (P streams its old fish into Q; R keeps `Clock_B`'s time).  The page's `setInterval` is the only thing from outside:
      it pokes `Clock` and calls `TheA_run(log, null, ['Clock'])`.  Every run is two rounds (Clock; P · Q), three when a fish
       swims; R and `Clock_B` stay at zero visits forever.  For Theory to stand code without Lies/Lang it got two fallbacks:
        `TheA_meta(path)` (the Ghostmeta name rule, used when `Lang_ghostmeta_name` isn't loaded) and `TheA_loaded(path)`
         (the digest from the House's own `Ghostmeta_*` method when `Lies_ghost_get` isn't).
- **Code lands between eras — `AthePondEra`.**  On the page a push could never land: `TheA_code_push` posted an elvis, and a
   House with no `main()` never ticks, so `%TheACodePush` sat on the As for ever.  Now a House may declare **`%TheAEras`**
    (the page stands it): pushes to its As wait, as they do in a Story run (`TheA_code_waits`, was `TheA_in_run`).  **`TheA_run`
     is the era seam:** before round one every A with code waiting takes it (`TheA_code_take` — what the elvis did, without its
      think), is named `%TheAArrived:<A>` on the run, and moves in round one — a move with nothing asked IS the blank think.
```
TheARun,rounds=2,quiet
  TheAArrived:K_P                     the toy was pushed to K_P mid-step; this run took it first
  TheARound:1,landed=2
    TheAWent:Clock_A
    TheAWent:K_P                      moved with nothing asked: its first move under the new code
  TheARound:2
    TheAWent:K_P                      …and again with the tick
    TheAWent:K_Q
```
   So a run is all one era, and an era ends only where code arrives.  On `/Pondland`, a hot reload of the toy lands at the
    next poke: every A holding it moves once (R and `Clock_B` included — arrival is a wake, the only one they ever get).
- **Time is IO — `AthePondTape`.**  The page’s timer was the last elvis from outside; now it isn’t an elvis at all.  A
   compartment may declare **`%TheAIO:<synapse>`**: that synapse is fed from outside the House and from no A.  Everything from
    outside comes in by **`TheA_io(name, io, sc)`**, which pulses the synapse AND writes **`%TheAHeard:<n>,take:<k>,…`** under
     the `%TheAIO` — the **tape**.  `TheA_move` counts the IO's `takes`, so a Heard knows which move ate it, and so which run.
      `w:Athe_Host` (the toy file) is time's compartment: the outside says how many ms went by; the host owes them to its
       `%Beat,ms`, sends one `beat` per whole beat on to a clock, and keeps the rest as `%Spare,ms` — a timer that fires early
        or late loses nothing.
```
A:Host
  w:Athe_Host
    TheAIO:outside,heard=4,takes=3     the tape: what the outside said, and which move ate it
      TheAHeard:1,take=1,ms=1000
      TheAHeard:2,take=2,ms=400        early…
      TheAHeard:3,take=2,ms=900        …then late: one beat, 300 spare
      TheAHeard:4,take=3,ms=2300       2600: two beats, 600 spare
    Beat,ms=1000
    Beats,count=4
    Spare,ms=600
```
   `TheA_tape(name, io)` reads it back as plain takes (`[[{ms:1000}], [{ms:400},{ms:900}], [{ms:2300}]]`) and
    `TheA_replay(at, name, io, takes, after)` plays them into a pond stood again from nothing, one run per take.  The Book
     keeps each live run as one line (`%Ran:2,rounds=Host +1 / Clock_A +2 / K_P K_Q`) and each replayed one beside it: the
      same, run for run, the tanks the same egg for egg, and the replay hears exactly the tape it played.  This is what a
       replay mocks (From the top, item 3): the IO compartment, and nothing else — there is nothing else from outside.
- **A hold is a pulse not yet delivered — `AthePondAsk`** (owner’s ruling, 2026-10-21; the root named `%TheAWait`).  The
   Coding_guide’s worst trap, wake taken for hold, as two rows that can’t be confused.  `TheA_ask(w, axon, sc)` sends the ask
    AND, in the same move, writes **`%TheAWait:<A>#<n>,on:<axon>,…`** on the asker — the hold armed at the cause.  A wait wakes
     nobody: the asker isn’t visited while it waits.  The answer is an ordinary pulse carrying `wait:<id>` back; the move that
      eats it ends the wait (`TheA_move`).  So a run can be **quiet** (nothing ready) and not **settled** (an answer owed):
       `TheA_run` writes `waiting:<n>` on a quiet run while any wait stands, and `TheA_settled(run)` is quiet with none.  The
        toy’s `w:Athe_Feeder` takes orders on `ask` and serves them two ticks of its clock later on `fed`.
```
TheARun,rounds=2,quiet,waiting=1     step 2: K_P asked; quiet, but owed an answer
A:K_P
  w:Athe_Tank
    TheAAsked,count
    TheAWait:K_P#1,on:ask,food:worms
    TheASynapse:fed,from:Feeder,wake:eat    nothing on it until step 4 — K_P isn’t visited in step 3
A:Feeder
  w:Athe_Feeder
    Order:worms,wait:K_P#1,due=2
```
   An answer goes to every synapse that hears the feeder; only the asker whose id it carries stops waiting.  Addressing an
    answer to one asker, and a wait that times out (a ttlilt as a pulse the clock sends), are still to do.
- **Where it goes next:** (a) *done — time is IO, above;* the page’s timer was the last elvis from outside — it belongs to IO-as-compartments (From the
   top, item 3): real time as a compartment whose pulses come from the host, the same shape as audio or a socket; (b) req
   machinery woken by pulse instead of by sweep — *the toy done above (`%TheAWait`)*; the real one is the first step that touches Hovercraft (todo §0.0).

### 1.14 Still to design

*From the todo's sketch, not yet built:* `%TheATurf` (a leased
 region), the spheres beyond Trace and Regard (a Was that outlives a reload, §1.12), the scheduler beyond the toy (§1.13 has it by hand, a clock, and a page), a synapse whose pulses go
  somewhere other than a tank woken by the same batch (across Houses; across a network), the
  manifest check (Electrode joined with Atlas).  From A\*\* (§1.11): what an A may READ or WRITE by where it stands (turfs),
   `from:` resolved by nearness rather than a unique name, a Book's own routine running through its A, and whether the A\*\*
    tree maps onto relations (the owner's hunch).

## 2. The foundation ledger — every change Atheory makes to Stuff or Housing

*The owner, 2026-10-20: "I want to track everything we adjust in Stuff|Housing" — and again, "carefully collect all the
 changes we make to Housing or Stuff there".  Atheory grows out of the foundation, so each change to `Stuff.svelte.ts`,
  `Housing.svelte.ts`, and what sits right beside them (Story's seams, tooling, the app shell) gets a row here: what moved,
   why, who reads it, and how to take it back out.*

**The rules:**
- Add the row **in the same change** that makes the edit.  Name the place by symbol, never by line number.  Newest first.
- A change that's later reverted keeps its row, with a line saying when it went.
- **Audit it against git** whenever unsure: `git log --oneline -- src/lib/Stuff.svelte.ts src/lib/O/Housing.svelte.ts
   src/lib/O/Story.svelte` since `d88d2aed` (the commit before Atheory began), and `git diff` the working tree for the same
    files.  Every hunk there must have a row here.
- **Last audited 2026-10-21** against git through `5efb5cc7` plus the working tree: Housing — three rows, complete; Stuff —
   untouched; Story (+ Text, Hovercraft) — the working tree's hunks are the two `tol:same` rows, complete.

### `src/lib/Stuff.svelte.ts`

No Atheory adjustments yet.

### `src/lib/O/Housing.svelte.ts`

| date | where | what | why | read by | to undo |
|---|---|---|---|---|---|
| 2026-10-21 | `House.ghost_versions`, and four lines in `ghostsHaunt`'s `if (meta) {…}` block | every arriving hash is also kept by its dige: `ghost_versions[meta][dige] = hash`, the newest 8 per file, on the top House | A\*\*: an A runs the version its `%TheALayer` names, so a newer version merged flat doesn't reach it until its push is let through — two versions of one file in one heap | `Ghost/A/Theory.g` (`TheA_as`, `TheA_version_keep`); Books `AthePondVersions`, `AthePondNest` | delete the field and the four lines; `TheA_as` then finds no versions and answers with the flat House |
| 2026-10-20 | the CodePush line at the end of `ghostsHaunt` (`if (meta) (this as any).TheA_code_push?.(meta)`) | after the merge, every compiled file that arrives is announced to Theory by its `Ghostmeta_*` name | CodePush: code compiles centrally and is pushed to the As that hold it; `ghostsHaunt` is the one place every compiled `.g` arrives | `Ghost/A/Theory.g` (`TheA_code_push`); Book `AthePondCodePush` | delete the line |
| 2026-10-20 | `House.ghost_origin`, `House.ghost_files`, the `if (meta) {…}` block in `ghostsHaunt` | `ghostsHaunt` finds the one `Ghostmeta_*` key in each eaten hash and records, on the **top** House: `ghost_files[meta]` = the methods this load carried (replaced whole each load, so a deleted method leaves), and `ghost_origin[method] = meta` (the file that last defined it).  A hash with no `Ghostmeta_*` (a hand-written `.svelte` ghost) records nothing.  (The first version kept a `ghost_clobbers` log that only grew; replaced the same day.) | `H.ghosts` is flat, so nothing could say which code an actor runs or where a method came from.  Each compiled `.g` arrives as exactly one hash with exactly one `Ghostmeta_*`, which is also its digest: the one cheap place to learn it. | `Ghost/A/Theory.g` (`TheA_clobbers_stand`); Book `AthePondCode` | delete the two fields and the `if (meta) {…}` block; nothing else depends on them yet |
| 2026-10-18 | `Wormhole_compose_app_tree` (AppTreeNav root), `Wormhole_mount_creds`, the serve wall (the `.jamsend` segment refusal), the import | the literal `'.jamsend'` became `APP_DATA_DIR` from `src/lib/app_data_dir.ts` | one spelling of the app's private corner; the serve wall and NodeWormholeNav's 0600 must agree on it (§ "The app's own storage") | — (same value) | inline the literal again; the value never changed |

### Beside the foundation (tooling and the app shell)

| date | where | what | why |
|---|---|---|---|
| 2026-10-21 | `src/routes/Pondland/+page.svelte` + `src/lib/A/Pondland.svelte` (new) | a route whose page is a bare House driven by `TheA_run` (§1.13) — imports `gen/A/Theory.go` and `gen/A/AtheFishTesting.go` directly as components (`@ts-ignore`d: a .go has no type declarations); exposes `window.__pond()` for headless probes | the owner's "a replacement of Otro.svelte or something — minimal changes to Housing.svelte until we've got a lot of experience": nothing in Housing changed.  The first page to mount ghosts without GhostList |
| 2026-10-21 | `src/lib/A/Pondland.svelte` (time as IO; tracing paper) | the timer no longer pokes `Clock`: it tells `Host` the real ms since it last spoke (`TheA_io`, tape `keep:12`), Host beats `Clock` every 500 ms; a pause stops the pond’s time; "One beat" says 500 ms.  Each tank wears a Seem (`eye`, Egg+Fish) with a Regard sphere; after a run only the tanks that moved are walked (queued — walks are async), the eye regards each point `seen:n`, and the page draws the sheet: rings, regard dots, a red ring for `TheABecame`, crosses for `TheAGoner` | design §1.13 "Time is IO"; todo §0.0 overnight plan item 3 (art school).  Page only — nothing in Housing |
| 2026-10-22 | `src/lib/O/Hovercraft.svelte` `story_matching_rules()` (new) + its 4 readers; `src/lib/O/Storui.svelte` 1 reader | Story's default matching rules read through one helper that takes either shape — Story.svelte's data property or Ghost/O/Story.g's method (a .g has no data properties) | Aprac_todo §0 — Story ported onto TheACode; the port is per tab until the spine moves.  Behaviour unchanged with Story.svelte (helper returns the array) |
| 2026-10-22 | `scripts/ghost_svelte_to_g.mjs` (new) | ports a `.svelte` ghost to a `.g` and proves it: original vs `.go` per member (types stripped), every difference declared in `<name>.port.json`; the `.g`'s own text vs the `.go` (compiler faithful); module bindings unique.  `--allow-async=` names sync methods the compiler may make async | Aprac_todo §0 item 1.  Tooling only — nothing runs it at boot |
| 2026-10-21 | `src/lib/Selection.svelte.ts`, `SelectionItself.process`'s `pairs_fn` (the `a && b` branch) | `a.c.T.sc.bD` → `a.c.T?.sc.bD`, and `z?.c.T.sc.bD` → `z?.c.T?.sc.bD` (the point two walks back) | a D sphere thawed from text (`TheA_thaw`, Book `AthePondReload`) has no Travel on `.c`, so the first walk after a reload threw in `pairs_fn` (and, with only the first `?`, the second walk did) and the Seem never walked again — Selection assumed every old D was walked in this session.  Read by every Selection (Seem, Repli, LE, Voro, Story's snap); the old behaviour for a walked D is unchanged.  To undo: drop the two `?` |
| 2026-10-20 | `src/lib/O/Story.svelte`: the editor's pause-verify forgive (`run.sc.check_snap`) and the post-run forgive sweep (`run.sc.sweeping`) | each now sets `caveat` only when `entropy_forgive_muted` says the step needed more than `tol:same` | the two other places a step gets forgiven still caveated a digest-only move; `snap_step` already didn't.  Not yet exercised live (every Athe Book passes on the inline path) |
| 2026-10-22 | `src/lib/O/lang/compile.ts` (`Lang_amp_calls_in_text`; the decl-vs-call peek) | `&&` is one token, never `&method` sugar; the sugar never fires inside string or template text (it still does inside `${…}`); a method header with a body brace or trailing `:` is a declaration even with nothing after it | `a&&s.x` compiled to `a&this.s().x` (Story's story_save, met porting it); a bodyless stub at EOF made invalid JS.  All 55 .g recompiled byte-identical (CHECK=1) bar HohoTiles' pre-existing drift; pinned_stable unaffected.  The "must not end on a method-final brace" dodge didn’t reproduce; its comments were deleted (14 .g + the converter), the .go diffs only the comment |
| 2026-10-22 | `Ghost/A/Theory.g` (`TheA_seem_walk` %TheADeep; `TheA_nonzero`; rows_of `TheAKind:*`) | a deep Seem walks every row under its top rows, nested; each point marks `.c.how`/`.c.at`; the walk tallies fit/shift/neu/gone and `reseat` when the source changed | Storica's open-step snap: one view, re-pointed from the recorded snap to the live one, holding still (owner: "it just Seems into place, with a slight green glow").  Non-deep Seems unchanged (their walks carry no tally).  Book AthePondReseat |
| 2026-10-22 | `Ghost/A/Stuffica.g` (`Stuffica_view` opts.deep; `Stuffica_walked`) | a view may be deep; a re-seat commits though its digest holds | the re-seat is what the screen glows by |
| 2026-10-22 | `src/lib/O/Storica.svelte` (the snap panel) | the open step's snap as a deep view: recorded until the live run's arrives, then re-seated on it; lines keyed by Dip; a line glows what it just did (fit green on a re-seat, shift amber, neu fades in) via `el.animate`, so no element is remade | first answer to "how to tell the user about the latest wriggle of state" — unseen with eyes yet |
| 2026-10-22 | 14 .g + `scripts/ghost_svelte_to_g.mjs` | the "must not end on a method-final brace" comments deleted (owner) | the dodge didn't reproduce; .go diffs only the comment |
| 2026-10-22 | `src/lib/O/Storica.svelte` (new), mounted by `Ghost/O/Story.g`'s Story_plan beside Storui (`%UI:Storica`) | Storui rebuilt on Stuffica views: the step strip is two views in the strip's own compartment — `plan` over The's %step (says dige, desc), `live` over This's %Step (says ok, caveat, accepted, dige) — refreshed after each settled flush, drawn only on a commit; `window.__storica_ledger()` | Aprac §0 "Next" 2.  Only on a tab that ghost_loaded Story.g until the spine swap |
| 2026-10-20 | EntropyArrest `tol:same` (`EntropyArrest.md` §11): `Text.svelte` (`spay_same_pairs`, `spay_graft`'s `same` arg, `spay_within`), `Hovercraft.svelte` (`entropy_forgive`, `entropy_same_of`, `entropy_same_note`, `entropy_forgive_muted`), `Story.svelte` (`story_drive` makes `w.c.dige_same`; `snap_step`'s inline check notes exact steps and mutes; the GhostList read rule's `dige:` spayer `any` → `same`) | a `dige:` may change only as a consistent substitution over the run; a step forgiven by that alone passes with no caveat | every code edit moved the toy's digest in every Athe snap, costing a hand re-baseline of every Athe Book; and `tol:any` let a real digest move pass as noise.  Touches EVERY Book (the spayer reaches every `dige:` line) |
| 2026-10-20 | `src/lib/O/Story.svelte`, the step seam right after `run.c.step_n = n` (`TheA_code_pushes_let`) | at the start of every step, the As in the run take in any code pushed to them while they waited | Story mediates how code comes through a Book (owner): a push to an A in a run waits on it as `%TheACodePush` until the next step, so a snap shows exactly when code changes |
| 2026-10-20 | `src/lib/O/Story.svelte` (`story_declare_one`, `story_declare_all`; called in accept-all and on a new recording's completion) | every sworn sentence is declared into the toc when a Book is recorded or accepted; the old "only the human clicks" rule is gone (owner: *"you just need to know what you're doing"*) | swears were sitting sworn but ungated, so a sentence that stopped turning up went unnoticed |
| 2026-10-20 | `scripts/LocalGen.spec.ts` | creates `gen/<dir>/` before writing, so a new `Ghost/<dir>/` compiles without a hand `mkdir` | `gen/` mirrors `Ghost/`; the relay's `gen_write` already did this (`relay.ts:997`), LocalGen didn't (met making `Ghost/A/`) |
| 2026-10-19 | `src/service-worker.js` | a `.go` module the worker re-fetches asks with `?import`; cache bumped to `jamsend-shell-v2` | a worker's re-fetch arrives `Sec-Fetch-Dest: empty`, Vite then served raw `.go` source, the browser sniffed it as HTML, and every Creduler ghost failed on the music page |
| 2026-10-18 | `src/lib/app_data_dir.ts` (new) | `APP_DATA_DIR = '.jamsend'`, dependency-free | read by Housing, NodeWormholeNav, the daemon, and ghosts via `IMPORT()` |

