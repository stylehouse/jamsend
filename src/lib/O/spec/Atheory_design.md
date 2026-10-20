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

### 1.6 Still to design

*From the todo's sketch, not yet built:* `%TheATurn` (one pass of one compartment, as history), `%TheATurf` (a leased
 region), the spheres (`%OtherSphere`), the scheduler proper (unwatched work costs nothing; order doesn't leak), the
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
- **Last audited 2026-10-20** against git through `1843be58` (CodePush): Housing — three rows, complete; Stuff — untouched;
   Story — two rows, complete.

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
| 2026-10-20 | `src/lib/O/Story.svelte`, the step seam right after `run.c.step_n = n` (`TheA_code_pushes_let`) | at the start of every step, the As in the run take in any code pushed to them while they waited | Story mediates how code comes through a Book (owner): a push to an A in a run waits on it as `%TheACodePush` until the next step, so a snap shows exactly when code changes |
| 2026-10-20 | `src/lib/O/Story.svelte` (`story_declare_one`, `story_declare_all`; called in accept-all and on a new recording's completion) | every sworn sentence is declared into the toc when a Book is recorded or accepted; the old "only the human clicks" rule is gone (owner: *"you just need to know what you're doing"*) | swears were sitting sworn but ungated, so a sentence that stopped turning up went unnoticed |
| 2026-10-20 | `scripts/LocalGen.spec.ts` | creates `gen/<dir>/` before writing, so a new `Ghost/<dir>/` compiles without a hand `mkdir` | `gen/` mirrors `Ghost/`; the relay's `gen_write` already did this (`relay.ts:997`), LocalGen didn't (met making `Ghost/A/`) |
| 2026-10-19 | `src/service-worker.js` | a `.go` module the worker re-fetches asks with `?import`; cache bumped to `jamsend-shell-v2` | a worker's re-fetch arrives `Sec-Fetch-Dest: empty`, Vite then served raw `.go` source, the browser sniffed it as HTML, and every Creduler ghost failed on the music page |
| 2026-10-18 | `src/lib/app_data_dir.ts` (new) | `APP_DATA_DIR = '.jamsend'`, dependency-free | read by Housing, NodeWormholeNav, the daemon, and ghosts via `IMPORT()` |

