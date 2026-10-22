# Aprac — building on Atheory

*Split from `Atheory_todo.md` 2026-10-22 (owner: "lets split now an Aprac_todo, for these things on top").*  Atheory is the
 theory, built as a toy and proven (`Atheory_design.md` §1); its remaining edges each lead into another topic and are listed in
  `Atheory_todo.md` §0.0.  **Aprac is the practice**: what we build on top of it, inside our own walls, so that the machine that
   makes code and the code it makes can grow together.

## 0. START HERE (2026-10-22)

**The arc.**  A solid UI pattern → prove it on a contained, chewy game (Vyto|Voro-like: nested things laid out and played with)
 → **rebuild Hackarium within our walls** on that pattern: the editor seat, where code is written, compiled centrally, pushed,
  and lands at an era seam — while the reader reading it is watched (Regard on Atlas's Points).

**Where it stands.**
- **Views — `Ghost/A/Stuffica.g`** ("Stuffing, made a citizen").  A view is a Seem on a compartment that the screen holds open.
   It is walked after a run only if that compartment moved (`%TheAWent`; nothing polls), committed only if what it shows
    changed (plain equivalence: the sheet said as one line, its digest against the last committed), and every changed view
     commits together at the run's tail — one bump of its handle (`view.c.ui.commit()`; a page hangs a `$state` counter
      there).  The UI reads the Seem's Trace points: plain C that only a walk rewrites.  What the user does comes in as IO
       (`TheA_io` on a `%TheAIO`), on the tape like time.
- **Book `AthePondView`** — walked only when what it shows moved; equivalence stops the wire; two turns and a hatch are one
   commit; a click is IO and only its tank's view is walked.  S24–S26 bit as predicted (design §1.10).
- **`/Pondland`** draws only through views: each figure (tanks, Host, clocks) reads its view's points; `beat++` is gone.  R's
   view is never walked.  The tracing paper is the view's own Seem showing through.

- **Done 2026-10-22 — keys, the read, a real reactivity test.**  Opt-in `%TheASeem:<name>,dip` stamps each point with
   `%Dip:seem,value:<name>_<n>` (Theory.g `TheA_dip`), kept across walks and through a hatch (oath E, S27 bit).
    `Stuffica_points` reads the handle's counter and the tree UNTRACKED — the render ledger on Pondland caught the tracked
     version re-rendering ~18× a commit (o() subscribes to each container's X, and a walk rewrites those over many awaits, so
      Svelte drew the middle of every walk).  Now: P 41 renders for 40 commits, Q 40 for 39, R once, ever.  Probe:
       `window.__pond_ledger()`; script in the scratchpad (`_pond_renders.mjs`, copy into scripts/ to run).

**The direction, owner 2026-10-22:** the new Hackarium is good at **putting code on TheACode first**; then it **explores the
 Books we have saved** — the C** of each recorded step observed on its own, rifled through as evidence of the system doing
  things, experimented with, and "brought to life" by a real Story run beside it.  The explorer's look is a new kind of
   Stuffing|Vyto|Voro thing: **spheres woven together, stretching out of sight.**

**Next, in order:**
1. **A converter, and Story as a `.g`.**  Story.svelte (3283 lines) is already a ghost — methods merged by `eatfunc`, as 28
    `.svelte` ghosts are — so porting it is a transform, not a rewrite.  `scripts/ghost_svelte_to_g.mjs`: methods →
     `Name(args):` with indented bodies, imports → `IMPORT()`; then it PROVES the port: compile with LocalGen, parse the
      original and the `.go` with esbuild, compare method by method (same names, same normalised bodies).  Story is the
       runner, so the swap goes on a second runner tab first, then a sweep.  As a `.g` it is stood with `%TheACode`, pushed
        like the toy, and lands between eras — Hackarium's first job: what runs where, and code taken at the seams.
2. **Storui rebuilt on Stuffica, not ported.**  2431 lines of effects off `H.ave` → the step list as a view over This's
    Steps, each step's snap a nested view; a step redraws only when it commits; rows keyed by Dip.  The first real UI on
     the pattern after Pondland, and the explorer's first form.
3. **The Book explorer — the game.**  A Book's `NNN.snap`s decode to C trees: a Book is a Was, one mark per step.  A Seem
    over the steps pairs each point with itself across them (`resolve()`, as a walk pairs walks), so a fish, a req, a pier
     has a life you can follow through a whole Book; sworn oaths hang as Regard on the points they speak of.  Brought to
      life: a real Story run beside the recording, the live step's sheet laid next to the recorded one — the diff shown
       where it is.
4. **The woven view.**  Each step a sheet of tracing paper stacked into the distance; each point a thread through the
    sheets; a hatch a thread changing colour; a fish changing tanks a thread crossing between stacks; regard as beads on
     the threads; Stuffing for one sheet's columns up close.  Vyto glass in depth — buildable now that identity across steps
      exists (resolve + Dip).
5. Then Hackarium's editor seat on all of it.

*(The earlier list — key by Dip, the read as the subscription, a real reactivity test — is done, above.  Its game, nested
 ponds as nested views, is set aside for the Book explorer: real evidence instead of a toy.)*

**Story on TheACode — PROVEN on a live runner 2026-10-22 (not yet the spine).**  `scripts/ghost_svelte_to_g.mjs` ports a `.svelte` ghost to a `.g` and proves it twice:
 (1) original vs compiled `.go`, member by member, types stripped — every difference must be DECLARED in `<name>.port.json`;
  (2) the `.g`'s own text vs the `.go` — the compiler carried every member faithfully (bar its own `const H = this` and the
   async it gives any method holding an await).  Story.svelte → `Ghost/O/Story.g`: 67 members, 72 of 80 printed identical,
    8 declared (6 braceless two-line if/else braced; a data property `story_matching` → a method, read through Hovercraft's new
     `story_matching_rules()`; `Story_plan`'s nested `async () => await x` → `() => x` so it stays sync — its caller uses the
      return; `story_drive`/`Story_demand_audio` allowed async — callers ignore the return, but a sync throw becomes a rejection;
       `story_save`'s `a && b` inside a template `${…}` rewritten — **the .g compiler applies its `&method` sugar inside template
        substitutions** (`a && s.x` came out `a & this.s().x`); a module-level template string loses 4 spaces a line).  What the
         .g compiler can't carry, learned by probing: braces in a header or return type, getters, data properties, a body line at
          column 0, `ReturnType<typeof this.x>`, a two-line braceless if/else.  The swap is per tab: `runner_ask ghost_load
           Ghost/O/Story.g` lays the `.go`'s methods over the `.svelte`'s (ghostsHaunt; `ghost_origin` says which).  Book
            `AtheStoryCode` proves a runner runs Story from the .g (swapped: both oaths; unswapped: both absent, `from:nowhere — a
             hand-written ghost`).  On the swapped runner every Book matched its unswapped baseline: LeafFarm 30/30, LeafJuggle 19/19,
              HohoTtlilt, all 25 AthePond, HohoRetake's known flake and Diffmatication's pre-existing red unchanged; no ⛔, no wedge.
               Two misses before that, both now gates in the converter: the .go header already imports `TheC` and `onMount`, so
                Story's own imports redeclared them and Vite refused the module (esbuild's parse doesn't check bindings — `--prove`
                 now does); and Story's own `...this.story_matching` needed to become a call once the property was a method.
                  **Next: the spine** — `Ghost.svelte` mounts `<Story {M}/>` from `Story.svelte`; switching it to `gen/O/Story.go`
                   (`<Story H={M}/>`) moves every tab (runners, music pages, the editor's own copy is pinned_stable).  Then
                    Story.svelte retires to history and edits go to the .g.

**Owner, 2026-10-22 (before a compaction) — the direction from here:**
- **Story.g becomes THE Story.**  Atheory-only aspects get added to `Ghost/O/Story.g` rather than the legacy `Story.svelte`; then
   the spine mounts the .go and Story.svelte retires to history.
- **UI next** — Storui rebuilt on Stuffica (item 2 above).
- **Hackarium direction: integrate the editor and Story.g a bit somehow** — the editor seat editing Story's own .g, pushing it,
   and the runner taking it at an era seam (CodePush, as the toy does).
- **Two .g compiler fixes — DONE 2026-10-22** (`src/lib/O/lang/compile.ts`): `&&` is one token, never the `&method` sugar, and
   the sugar never fires in string or template text; the "must not end on a method-final brace" dodge didn’t reproduce (its
    comments were deleted from all 14 .g and the converter).  55 .g recompiled byte-identical; pinned_stable unaffected; the converter's `&&` rewrite is gone.

**Storica — Storui on Stuffica, first slice (2026-10-22).**  `src/lib/O/Storica.svelte`, mounted by Story.g's Story_plan
 beside Storui (so only on a tab that ghost_loaded Story.g, until the spine swap).  The strip is two views in the strip's own
  compartment, reading Story's piles from outside (Theory: a Seem's `c.from` + `%TheASay`; Book `AthePondGlass`): `plan` over
   The's %step (dige, desc), `live` over This's %Step (ok, caveat, accepted, dige).  Refreshed after each settled flush
    (`Stuffica_refresh`), drawn only on a commit, pips keyed by Dip; `window.__storica_ledger()` counts draws.  **Not yet seen
     with eyes** — no console errors on the runner, but runner_ask has no eval, so nobody has looked at the tab.

**Storica's snap panel — it Seems into place (2026-10-22, second slice).**  Owner: *"the snap C** should stay still in the same
 view that starts looking at the live running version too.  It just Seems into place, with a slight green glow emit as things
  fit into place … the visual paradigm, how to talk to the user about the latest wriggle of state in the system."*  Built: the
   open step's snap is ONE deep view (Theory `%TheADeep`, not a view per level — a whole tree pairs in one walk), showing the
    recorded snap until the live run's `got_snap` arrives, then re-pointed at it: it re-seats, every line keyed by its point's
     Dip, so nothing is remade; each line glows what the walk did to it — fit green (only on a re-seat), shift amber (stays
      tinted), new fades in (`el.animate`).  The head says "seated — N fit · N changed · N new · N gone".  Book
       `AthePondReseat` proves the Theory half (4 oaths, 3× green).  Opening another step re-seats too, so what two steps
        share glows — a step-to-step diff for free; keep or tame it once seen.  **Not yet seen with eyes.**
 Next, in order:
  1. **Look at it** (owner, or the eye — `scripts/runner_eye.mjs` can photograph a page over ticks): is the glow a whisper
      or a strobe; is a 700-line snap readable at 40vh; does the re-seat land when a run reaches the open step.
  2. **The wriggle, said** — the paradigm question.  A re-seat's tally is already a sentence ("seated — 412 fit · 2 changed");
      the next layer is WHERE the eye goes: scroll the first shifted line into view, fold runs of fitting lines (Lang's
       openness folds a Doc around engaged Points — the same move), a gone line left as a fading ghost for a beat (limbo has
        it: `%TheALimbo` keeps gone points).
  3. **Waft → Book explorer, smoothed.**  Credence lists every Book; from a `Funkcion:Storying,of_Book:X` line in a Waft the
      way in should be one gesture — open the Book in Storica with its first step's snap seated, no run needed (the recorded
       snaps are the Book at rest).  Then running it is the same view coming alive.
  4. Notes and oaths as their own views; the diff panel retires once shift lines carry their old value (the walk has bD).
  5. A click becomes IO once Story is an A.

**Open questions.**
- A view whose handle isn't hung (no UI open) — keep walking it, or stand views only while open (Stuffing's register /
   deregister)?  Probably: a view stands while open; closing drops it, and its Seem with it.
- Regard drawn by the UI (an eye's opinion) changes what a view shows on every walk, defeating equivalence: an organ's regard
   belongs in its own view, not the figure's.
- `H.ave` is only safe at its top level (owner): a flat bag the H** space ejects.  Views are the structured replacement; how
   much of `H.ave` moves onto them, and when, is open.

## 1. The UI pattern — survey and proposal (2026-10-22, moved from Atheory_todo §0.0)

*The UI end (owner, 2026-10-22).*  The Atheory lump is down; what's left in it are edges into other works
 (turfs + crypto, synapses across Houses, the manifest check, rollback, the scheduler inside `beliefs()`).  The core gap is
  how a compartment reaches the screen.  Order: a solid UI pattern → prove it on a contained Vyto|Voro-like game → rebuild
   Hackarium within our walls.  Owner: "the way Stuffing regulates reactivity while reacting to everything opened on the UI
    is probably where we're heading."
*Survey of what we have (2026-10-22, read-only):* `o()` is NOT reactive (reads `$state X`, not the serial); `ob()` subscribes
 to the container's root serial only, so a child's sc change doesn't reach it (hence Stuffing's `stuff_matrix`, Housing
  ~1993).  Reading sc is never reactive.  `bump_version` fires several times per `i()`; `replace()` PUBLISHES its empty
   middle (reactivity_docs:18 — keyed `{#each}` teardowns, "the form closed by itself").  ~210 `$effect`, 130 `ob()`, 25 of 26
    Faces derive off `H.version` (whole House); Vytui/Pondland/BigShapeland bump a dummy counter; Lagui polls ("`$derived` off
     version was a tailspin").  Healthiest by the notes: `H.ave` "safe by construction", per-row `vers` after an in-place
      `oai`, trivial effect bodies, "trust a timer, not a reactive self-bump".  **Stuffing** is the one that regulates: an open
       UI registers (path, C, handler); after each `beliefs()` (throttled 200 ms, 3 s heartbeat) H diffs each registered C +
        its children's versions and commits the changed ones inside ONE `H.clear()`, one `$state` write each (`groups = next`);
         depth = nested registrations.  Wire_spec §7–8 already names it, watched channels and `%subscribe` "three spellings of
          one primitive".
*Proposal — Stuffing, made a citizen:* a VIEW is a compartment (`%TheAView`) standing for something open on screen; it
 hears a synapse from what it shows, so the boundary readies it only when that moved (no polling — `%TheAWent` already
  knows); its move is pure (Stuffing's `compute_groups`); the run's end is the commit: every readied view writes its one
   `$state` in one flush — so no half-run, and `replace()`'s empty middle, ever reaches Svelte.  Granularity = which views
    stand (a level of the tree gets its own refresh iff it has its own view).  Version-matrix stays the fallback for plain
     trees.  And the open edge (a form over a C that changes underneath it): what the user DOES is IO — a click or a keystroke
      is `TheA_io` on a view's `%TheAIO`, on the tape like time, so a UI session replays.
*First slice:* Pondland's figures become views (retire `beat++`), and a click feeds a tank (IO); Book `AthePondView`: only
 the views of what moved commit, one commit per run, nothing mid-run; replaying the tape of clicks gives the same view data.
  Then the game: nested ponds (A**) drawn as nested views, Vyto-glass-like.

*As built (2026-10-22), where it differs from the proposal:* the owner saw that sucking a sprinkle out of a larger pile IS a
 Seem — so a view is a Seem on the compartment it shows (not a separate compartment with a synapse), walked when the run's
  `%TheAWent` names that compartment; the "pure move" is the walk; the commit is plain equivalence on what the sheet says.
