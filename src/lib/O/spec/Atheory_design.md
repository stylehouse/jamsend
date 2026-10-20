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

## 1. The design as it stands

*Each part: what it is, where the code lives, the Book that proves it.  To flesh out.*

### 1.1 Where the code lives

- `Ghost/A/Theory.g` — the organ.  Particles all start `TheA`, so one grep finds every one.
- `Ghost/A/AtheFishTesting.g` — the toy, `Athe_Tank`: Pond's rules on its own turn clock.  Its own file so the toy's
   `%TheACode` names only the code it runs.  Prototypes of what Atheory will do (the Sunpit, wires) are written here in
    plain `o()`/`i()`, so they can be seen working before any of it moves into Theory.
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
   stood again, counted in `%TheACodeTaken`, and the A thinks once.  Open: delivering a genuinely different version inside
    a Book.

### 1.4 The Sunpit, by hand — `AthePondSunpitPassOrder`, `AthePondSunpitFrontier`

A turn's order is declared on the world: `%TheASunpit:turn` holding `%TheAPass:<Kind>` rows, each "this handler over all of
 these, before the next".  Keys on the `%TheASunpit` line are its culture: `frontier:turn` (take every pass's rows once, at
  the turn's start) and `gone:skip` (pass over what has left since).  Order is data; which code runs for a kind is not.

### 1.5 Wires, by hand — `AthePondWireSum`

`%TheAWire` is a standing pathway on the world: what it wakes, and how its waiting `%TheAPulse` rows sum (`sum:count`, once
 per pulse; `sum:latest`, once for the lot).  `%TheAWoke` keeps how often it woke and how many pulses it ate.  Wires wake
  in declared order, so pulses posted on a later wire wake in the same pass.

### 1.6 Order doesn't leak — `AthePondWakeOrder`

Two compartments with nothing between them come out the same whichever is woken first, so the scheduler is free to wake
 them in any order and a Book needn't pin it.  What breaks that is shared state nobody declared: two tanks naming eggs from
  one counter (`%NamesFrom:<A>` on the tank, said on the tree) with no wire between them leak their waking order — the
   eggs swap names.  The rule this proves: **anything two compartments share must be a wire**, so the scheduler can order
    along it.

**The fix, `AthePondWireOrder`.**  The same sharing, declared as a wire: the Q holds `%TheAWire:names,from:<P>`, and
 `Athe_Tanks_wake(names)` (the toy file, plain `o()`) wakes a batch in the order asked except that a tank holding a wire
  FROM another tank in the batch wakes after it.  Asked P-then-Q or Q-then-P, both pairs come out the same, and the routine's
   `%WakeOrder` rows show the asked order and the order it actually woke.

### 1.7 Code digests are pseudo-muted — `tol:same` (`EntropyArrest.md` §11)

Every edit to a toy moves its digest in every snap that shows it.  The `dige:` spayer now forgives that only as a
 consistent substitution over the run (each old digest → one new one everywhere, never two into one), and such a step is
  plainly ok, no caveat.  So a code edit costs no re-baselining, and a digest that moves in one place but not another reds.
   Proven 2026-10-20: a comment-only toy edit left all six Athe Books green, caveat 0, fixtures untouched.

### 1.8 A pulse that carries something — `AthePondStream`

Until now a pulse only said "something happened"; here one carries a thing between compartments.  Q holds
 `%TheAWire:stream,from:<P>,wake:arrive,sum:count`.  A fish too old for P (`OLD_AT`) swims down it instead of leaving for
  good — P posts `%TheAPulse,swims:<name>,age:<n>` on Q's wire (`Athe_Tank_downstream` finds the wires leading out: like
   names, the wire is held by the tank it leads INTO).  `Athe_Tank_wake` now hands each run its pulse (sum:latest the last
    one), and `wake:arrive` mints the fish in Q.
**What crosses is the age, never the birth turn.**  Each tank's time is its own (`Turns,count`); P is stood nine turns
 ahead of Q, so the two old fish arrive at Q's turn 13 born at −5 (`came:<P>`), and leave Q on its turn 14 — while Q's
  own oldest are ten.  A naive copy of `born` would have made them young in Q.  The rule: **a pulse between compartments
   carries quantities in the receiver's terms or in no one's** (an age, a count) — never a reading of the sender's clock.
    Batches are asked Q-then-P; the wires (`from:`) order them P first, so what P lets go is in Q the same wake.

**A loop, `AthePondLoop`.**  Streams both ways (P→Q and Q→P) can't be ordered: each tank waits on the other, so
 `Athe_Tanks_wake`'s visit stops where it started and the batch wakes as asked, and the loop leaks the asked order again
  (pairs 7 and 8 come out different).  A wire marked `lag:1` doesn't order the batch, and what comes down it waits for
   the receiver's next wake, because the receiver has already been woken.  It breaks the loop the way a register breaks a loop in a
    circuit (pairs 9 and 10 come out the same).  The rule: **every loop of wires carries at least one lag**.  A loop without
     one is said on the tree: `Athe_Tanks_wake` gives each tank on it a `%TheALoop:<its tanks, sorted>` row (current state —
      it goes when the loop is broken).  It warns, it doesn't refuse: the batch still wakes as asked.  And P's first two fish keep going round: each time they
      arrive too old, they leave on the fish pass before the heron's pass can take them.  At P's turn 30 they're in transit,
       `%TheAPulse,swims:minnow 1,age=19` waiting on P's lagged wire, which is how a lag looks on the tree.

### 1.9 The Turn, by hand — `AthePondTurns`

Step 4 of the scheduler sketch ("commit one `%TheATurn`"), opt-in on the toy.  A tank holding `%TheAWas,keep:<n>` (the
 Was-sphere, by its working name) commits one Turn each time a wire wakes it:

    TheAWas,keep=3,made=5
      TheATurn:3,wire:clock,pulses=9,code_dige:…
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

### 1.10 Each oath bites — sabotaged once (2026-10-21)

Homethink §3: each test can be sabotaged once to prove it bites.  Three sabotages went into the toy together, the three
 newest Books ran once in check mode, and the toy was put back byte for byte (checksums) and re-run green:

| sabotage | Book | oaths that stopped swearing | still sworn |
|---|---|---|---|
| S1: an arriving fish is `born: turn` (its age resets) | AthePondStream | keeps its age · the old fish leave on Q's next turn | carries nothing while young · swims down, gone from the first |
| S2: `Athe_Tanks_wake` ignores `lag` (and S1) | AthePondLoop | a lag breaks it · each lagless-loop tank is told · the first two fish go round | the loop leaks the asked order |
| S3: the Turn's "before" is taken after the runs | AthePondTurns | says what changed across it · laid-and-hatched shows only as fish | one Turn per wake · names its code · empty Turn kept |

Each oath fell to the sabotage aimed at it, and only to that: the unrelated oaths in each Book kept swearing.

### 1.11 Still to design

*From the todo's sketch, not yet built:* `%TheATurf` (a leased
 region), the spheres (`%OtherSphere`), the scheduler proper (unwatched work costs nothing), a wire whose pulses go
  somewhere other than a tank woken by the same batch (across Houses; across a network), the
  manifest check (Electrode joined with Atlas), and the A** shape that makes an A really run its own code.

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
| 2026-10-20 | the CodePush line at the end of `ghostsHaunt` (`if (meta) (this as any).TheA_code_push?.(meta)`) | after the merge, every compiled file that arrives is announced to Theory by its `Ghostmeta_*` name | CodePush: code compiles centrally and is pushed to the As that hold it; `ghostsHaunt` is the one place every compiled `.g` arrives | `Ghost/A/Theory.g` (`TheA_code_push`); Book `AthePondCodePush` | delete the line |
| 2026-10-20 | `House.ghost_origin`, `House.ghost_files`, the `if (meta) {…}` block in `ghostsHaunt` | `ghostsHaunt` finds the one `Ghostmeta_*` key in each eaten hash and records, on the **top** House: `ghost_files[meta]` = the methods this load carried (replaced whole each load, so a deleted method leaves), and `ghost_origin[method] = meta` (the file that last defined it).  A hash with no `Ghostmeta_*` (a hand-written `.svelte` ghost) records nothing.  (The first version kept a `ghost_clobbers` log that only grew; replaced the same day.) | `H.ghosts` is flat, so nothing could say which code an actor runs or where a method came from.  Each compiled `.g` arrives as exactly one hash with exactly one `Ghostmeta_*`, which is also its digest: the one cheap place to learn it. | `Ghost/A/Theory.g` (`TheA_clobbers_stand`); Book `AthePondCode` | delete the two fields and the `if (meta) {…}` block; nothing else depends on them yet |
| 2026-10-18 | `Wormhole_compose_app_tree` (AppTreeNav root), `Wormhole_mount_creds`, the serve wall (the `.jamsend` segment refusal), the import | the literal `'.jamsend'` became `APP_DATA_DIR` from `src/lib/app_data_dir.ts` | one spelling of the app's private corner; the serve wall and NodeWormholeNav's 0600 must agree on it (§ "The app's own storage") | — (same value) | inline the literal again; the value never changed |

### Beside the foundation (tooling and the app shell)

| date | where | what | why |
|---|---|---|---|
| 2026-10-20 | `src/lib/O/Story.svelte`: the editor's pause-verify forgive (`run.sc.check_snap`) and the post-run forgive sweep (`run.sc.sweeping`) | each now sets `caveat` only when `entropy_forgive_muted` says the step needed more than `tol:same` | the two other places a step gets forgiven still caveated a digest-only move; `snap_step` already didn't.  Not yet exercised live (every Athe Book passes on the inline path) |
| 2026-10-20 | EntropyArrest `tol:same` (`EntropyArrest.md` §11): `Text.svelte` (`spay_same_pairs`, `spay_graft`'s `same` arg, `spay_within`), `Hovercraft.svelte` (`entropy_forgive`, `entropy_same_of`, `entropy_same_note`, `entropy_forgive_muted`), `Story.svelte` (`story_drive` makes `w.c.dige_same`; `snap_step`'s inline check notes exact steps and mutes; the GhostList read rule's `dige:` spayer `any` → `same`) | a `dige:` may change only as a consistent substitution over the run; a step forgiven by that alone passes with no caveat | every code edit moved the toy's digest in every Athe snap, costing a hand re-baseline of every Athe Book; and `tol:any` let a real digest move pass as noise.  Touches EVERY Book (the spayer reaches every `dige:` line) |
| 2026-10-20 | `src/lib/O/Story.svelte`, the step seam right after `run.c.step_n = n` (`TheA_code_pushes_let`) | at the start of every step, the As in the run take in any code pushed to them while they waited | Story mediates how code comes through a Book (owner): a push to an A in a run waits on it as `%TheACodePush` until the next step, so a snap shows exactly when code changes |
| 2026-10-20 | `src/lib/O/Story.svelte` (`story_declare_one`, `story_declare_all`; called in accept-all and on a new recording's completion) | every sworn sentence is declared into the toc when a Book is recorded or accepted; the old "only the human clicks" rule is gone (owner: *"you just need to know what you're doing"*) | swears were sitting sworn but ungated, so a sentence that stopped turning up went unnoticed |
| 2026-10-20 | `scripts/LocalGen.spec.ts` | creates `gen/<dir>/` before writing, so a new `Ghost/<dir>/` compiles without a hand `mkdir` | `gen/` mirrors `Ghost/`; the relay's `gen_write` already did this (`relay.ts:997`), LocalGen didn't (met making `Ghost/A/`) |
| 2026-10-19 | `src/service-worker.js` | a `.go` module the worker re-fetches asks with `?import`; cache bumped to `jamsend-shell-v2` | a worker's re-fetch arrives `Sec-Fetch-Dest: empty`, Vite then served raw `.go` source, the browser sniffed it as HTML, and every Creduler ghost failed on the music page |
| 2026-10-18 | `src/lib/app_data_dir.ts` (new) | `APP_DATA_DIR = '.jamsend'`, dependency-free | read by Housing, NodeWormholeNav, the daemon, and ghosts via `IMPORT()` |

