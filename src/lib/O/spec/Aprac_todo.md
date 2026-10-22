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
