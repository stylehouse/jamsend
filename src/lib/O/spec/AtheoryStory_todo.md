# AtheoryStory_todo.md — Story, growing up inside Atheory

*Started 2026-10-29.  Story_future.md is a long list of features Story wants; this doc is how we climb onto it from the
 Atheory side — which feature needs which piece of Atheory, in what order, and what each step teaches (or changes) Atheory.
  Atheory's own record stays `Atheory_design.md` (built, plus the foundation ledger) and `Atheory_todo.md`.*

## 0. What to get on with next

0. **One tab, both Storys** (§1, "One tab"): load kept aside, then dispatch through the A (both BUILT 2026-10-29, Book `AthePondAside`).
1. **Desk slice 3, in two forms** (`Aprac_todo.md` §0.5): the page (`/Desk?G=…`) and a Desk **House standing inside a run**,
    so an old-Story Book can hold one.  Import Core, stand Wormhole, read the recipe, stand Grounds via `%TheACode`, wait for Firm.
2. **Book `AtheStoryInStory`.**  The old Story (the spine's) runs a Book that stands a Desk, which stands `Ghost/O/StoryFu.g`
    (`Ground/Story`); the inner Story runs one small AthePond Book; the outer snaps the inner — its steps, its verdicts, its
     Turns.  It will go red in instructive places first: every place the inner Story assumes it is alone (§1).
3. **The step explorer** (Storica grown, §3), fed two ways: recorded snaps, and the inner Story's live run.

## The arc

Two generations (`Atheory_todo.md` §0.0, "Newest").  The old one — Otro, the GhostList spine, `Story.svelte`, `runner_ask`
 runners — stays the gate and becomes the harness: it tests the new.  The new one is Desk + Theory + Stuffica + `StoryFu.g` stood as
  code on an A.  Story is refactored by being run nested and fixed where nesting breaks it, never by a big rewrite up front.
   When the inner Story gets the same greens, `/Desk?B=<Book>` tabs answer the relay as runners (so `runner_ask` keeps working)
    and the old generation retires.  On the way, Story_future's features land as Atheory things (§2), one at a time.

Until the retirement **a Story fix lands twice** — in `Story.svelte` and in `StoryFu.g`.  They drifted once (the 10-26
 "de-vanishing Wafts" guard; mirrored into the .g 2026-10-29).

## 1. Nestedness — what A** has to carry

A Story nested in a Story is an A in an A, and A\*\* already has the two lookups it needs (`Atheory_design.md` §1.11):
- **Code: `TheA_as(A)`** resolves a method name on the A's own versions first, then its ancestors'.  So the inner Story can run
   `StoryFu.g`'s methods while the outer runs the spine's — *if* every call goes through the A.  The open question for slice 2:
    eatfunc merges ghost methods flat onto the House, and a flat-merged `StoryFu.g` would land on top of the outer Story.
     Expect to stand it un-merged and call it only through `TheA_as`.
- **Services: `TheA_near(A, sc)`** walks the A's own world, then each enclosing A's, outward.  This is the cure for Story's
   habit of reaching for the top.  `StoryFu.g` calls `top_House()` at **22 sites** (2026-10-29 count), and each is a service it
    should find by nearness instead:
   - `i_elvisto('Auto/Auto', 'storyFinished')` ×4 — who hears that a Story finished: the enclosing Story, not the page.
   - `i_elvisto('Lies/Lies', 'Lies_open_Waft')`, `all_House` — the EntropyProfile open, aimed deliberately at the OUTSIDE Lies.
   - `c.boot_role`, `c.humdinger` (`is_runner`) — "am I a runner" becomes "what does my enclosing Desk say I am".
   - the error ring on the top House (`M.c.…` at ~1583, 1672, 1707, 2313, 2552, 2805, 2881) — each Story its own ring, the
      outer able to read the inner's.
   - `demand_time_to_think` ×2 — the clock.  One run owns the clock today (`Run.c.no_ambient`); nested, the inner's clock is
      a compartment the outer's drive pulses.
  These sites are the work list: `AtheStoryInStory` reds on them, one at a time.

### One tab, both Storys — what A\*\* gives and what it doesn't (read 2026-10-29)

**Data and services branch already.**  A Desk is an A; an inner Story's Run House, `This`, its error ring are particles under it,
 and `TheA_near` finds services from where it stands.  **Code does not branch yet.**  Every load goes through `Lies_ghost_include`
  (LiesLies ~1509), which mounts the `.go`; its `onMount` calls `H.eatfunc(hash)`, and `ghostsHaunt` (Housing ~755)
   `Object.assign`s the methods onto **every House in the tab**.  StoryFu.g has the same method names as Story.svelte, so standing
    it flat would turn the OUTER Story into StoryFu too — the renaming changes the file, not the names.  So one tab needs two
     small things, in this order:
1. **Load kept aside.**  `Lies_ghost_include(path, { aside: 1 })` mounts the `.go` with a shim `H` whose `eatfunc` only keeps the
    version (`ghost_versions`, `ghost_files`) and tells Theory (`TheA_code_push`) — no flat merge.  `TheA_loaded` must then read
     the dige from `ghost_versions` rather than off the House.  Code kept aside is reachable only through `TheA_as(A)`.  A Ground
      line or the stand call says aside; `Ground/Story` stood on a Desk inside a runner is the first user.  Book-provable on the
       pond: a toy file stood aside runs through its A and is absent from the House.
    **BUILT 2026-10-29, Book `AthePondAside` (5 steps, green warm ×3 and cold).**  Learned: what is kept aside is per TAB (on
     the top House) and outlives a run, so a Book stands its A only after the load has surely landed — standing it with the
      load gave a warm tab its digest two steps early.  A nested Story will meet the same: the inner StoryFu is loaded once per
       tab, and each inner run takes it already kept.  Not yet: a recompile of an aside file isn't re-included (the reswap
        sweeps the spine only).
2. **Dispatch through the A.**  `TheA_as` decides `this` for calls made from code already speaking as the A — but Story is entered
    from outside: its w's think is called by name (`do_fn_for` → `w:Story`), its `e_*` handlers by elvis, its reqs by `do_fn`.
     All of those look on the flat House.  `do_fn_for` already has an unused `w_inst` seam (design §1.11): when the w's A holds
      code, resolve the w's method, the `e_*` and the req fns on `TheA_as(A)`.  That is the from-the-top list's item (2), "every
       call through its A", and nesting is what finally asks for it.
    **BUILT 2026-10-29 for the w leg only**, gated: `do_fn_for` resolves on `TheA_as(A)` when `TheA_dispatches(A)` — a layer of the
     A's code is kept aside and not flat.  An A holding an older version of FLAT code is still thought by the House's copy (a
      ruling, not a fix: AthePondVersions relies on it).  Not yet: the req leg (`req_<name>` by convention looks on the House;
       a `do_fn` made by code running as the A already closes over the A's `this`).  The owner's longer wish: the A always in
        scope, so every call takes the A's version — `_Aw_think` already passes A first to every handler; what changed is `this`.
Then the Desk-in-a-run stands `Ground/Story` aside, and `AtheStoryInStory` can begin.  StoryFu's 22 `top_House()` reaches (below)
 are what that Book reds on next.

**What this teaches Atheory:** whether `TheA_near` is enough for real services (it has only ever found `%Weather`), and
 whether "calls by name, `this` decided by `TheA_as`" holds up for a 3,200-line ghost.

## 2. Story_future's list, as Atheory things

| Story_future | What it wants | Atheory piece | State |
|---|---|---|---|
| §15 drive as a req\*\* | how and when a step happens | the drive as a compartment; a step is a pulse | — |
| (new) present a Book without running it | the Book stands, nothing drives | falls out of the above: no pulse to the drive | — |
| (new) pause at time's structure | stop at a round, a Turn, an Ate | `TheA_run(…, most:1)`; the crawl (10-28 §15) | scheduler built |
| (new) a Story nests in a Story | test Story with Story | A\*\*: `TheA_as`, `TheA_near` (§1) | lookups built |
| §2.3 continuity, §3.2 surfing | which particle is which across steps | Seem re-seat + Dip (`AthePondReseat`); the snapper's own pairing kept as `Snap:cont` | re-seat built |
| §5 ghosts, §6 fern gardens | what went; fold what didn't change | `gone` from a walk; limbo; a view that shows only changed points + parents | gone/limbo built |
| §2 channels, 10-28 §15 timing | time in the snap without red fixtures | `%TheATime`, tendrils (`AthePondTendril`); quantise in Story | tendrils built |
| §8 ttlilt, seeing what held | what a step waited on | holds (`%TheAWait`), the Atime ring | built |
| §16 UIless, agent as driver | drive Story from outside | arrivals through the door (verbs, `e:Verb`) | partly |
| §13 test is a Waft, §14 Points are Assertions | oaths on Points | Atlas `%Map` Points + Regard | — |
| directions §7 a Book declares its steps | no `req:wrangle` boilerplate | the Book as an A whose steps are its moves | — |

## 3. The step explorer

One window on a step, and everything else is a protrusion from it showing a change: **resnap** (today a modal — really
 "Story refreshed, here is what moved"), a **failure diff**, an **oath** and the Point it swore on, a **pinned particle**
  surfing through steps.  Build the protrusion once.  It reads recorded snaps (present, no run) and the inner Story's live run
   alike — Storica's re-seat already turns one into the other in place.  Wants: a focus (pinned points + their ancestors,
    the rest folded to counts), and "changed since the last step" as the default focus.

## 4. Ledger — what this work changed in Atheory

*(One row per change to Theory/Stuffica/Housing made for Story's sake; the foundation ledger in `Atheory_design.md` §2 gets the
 Stuff/Housing ones too.)*

| Date | Where | What | Why |
|---|---|---|---|
| 2026-10-29 | `Ghost/O/Story.g` → `Ghost/O/StoryFu.g` (+ `.port.json`, gen `.go`, Ground/Story, everything.js, AtheStoryCode) | renamed, a working title | not to confuse it with Story.svelte |
| 2026-10-29 | `Ghost/O/StoryFu.g` | mirrored the `%desc`-particle-only guard from Story.svelte | the two Storys had drifted |
| 2026-10-29 | Housing `ghost_aside`, LiesLies include `{aside}`, Theory `TheA_loaded`, Ground `{aside}`; toy `Ghost/A/AtheAside.g`; Book `AthePondAside` | code kept aside: kept as a version, run only through its A, on no House | §1 "One tab", step 1 — foundation ledger row in `Atheory_design.md` §2 |
| 2026-10-29 | Housing `do_fn_for` `opt.A`; Theory `TheA_dispatches`; toy gets `Athe_Aside(A,w)`; Book step 6 | the House thinks an aside A's w through the A | §1 "One tab", step 2 |
