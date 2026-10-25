# Aprac — building on Atheory

*Split from `Atheory_todo.md` 2026-10-22 (owner: "lets split now an Aprac_todo, for these things on top").*  Atheory is the
 theory, built as a toy and proven (`Atheory_design.md` §1); its remaining edges each lead into another topic and are listed in
  `Atheory_todo.md` §0.0.  **Aprac is the practice**: what we build on top of it, inside our own walls, so that the machine that
   makes code and the code it makes can grow together.

## 0. START HERE (2026-10-22)

**Newest (2026-10-25): the Ground — §0.5.**  What a tab stands on, said as bundles in `wormhole/Ground/`, stood by one loader at
 two levels (the Desk, simple; Story, automated).  **Slices 1–2 built** (tags → 15 derived Grounds + `src/lib/A/grounds.gen.js`;
  the floor `src/lib/A/ground.ts` + `Ghost/A/Ground.g`, proved by Book AthePondGround; Hackarium stands on Ground/Land — not yet
   seen live).  Next: slice 3, Desk.

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

## 0.5 The Ground — what a tab stands on, said in the wormhole (design, 2026-10-25)

*Owner: "we need more Hackarium design to get the correct flock of Ghost/… code loaded for whatever is trying to execute, as
 Hackarium would have prepared the Ground (new idea) to know where we're going" … "Ground being something like Everything …
  another namespace for bundles of code that can be included, that come as big gobs of advice via the Wormhole" … "keeping the
   .g diges out of the Ground would help with the headless compiler and generally doing less all the time" … "make the two
    levels quite reusey, so we can see that it's a simple version first and then Story with extra automation".*
 Worked out below; the owner's rulings of 2026-10-25 are marked **(ruled)**, the rest is proposal.

### As built — slices 1 and 2, and Hackarium on its Ground (2026-10-25)
*Owner: "Hackarium does not yet run TheACode, so we can't build all this Ground stuff within it yet... it's a chicken or egg
 problem with the code provider providing itself... okay, you'll make it work".*
- **Tags** are marker strings in `everything_map()`: `'Ground:<Name>'` (and `'Stands:<Name>'` for a Ground it needs but doesn't
   cite) on Everything's area Whats, carried onto the What lines as `ground:`/`stands:`.  An inner What in an area Waft may wear
    its own.  Today: the wire → **Wire**, the swarm → **Swarm**, the music → **Music**, the cave → **Cave**, the visual →
     **Glass**, the land → **Land** (stands on Glass), the theory → **Core** (a new area, `Ghost/Atheory/Theory`), the foundation
      → **Story**.
- **Derived** by `grounds_derive` (everything.js) into `wormhole/Ground/<Name>/toc.snap` — `Ground:<Name>,desc,FromWhat` then
   `Stands:` / `Load:` (.g, in order) / `Beside:` (other code cited with it — not loaded by the Ground) / `Advice:` (.md) — and,
    baked, into **`src/lib/A/grounds.gen.js`** (`GROUNDS`), written only when it changes.
- **Rules, as coded**: a .g's home is the **first** Ground that cites it (map order); a Ground citing another's .g **stands on
   it** (so Swarm stands on Wire, derived, not authored) — instead of the validator refusing a second citation; a `*Testing.g`
    or any .g under a `What:the tests` goes to **`<Name>Testing`**, which stands on `<Name>`; Core is never written as a stand.
     The validator refuses: a tag with no Waft, a name not one capitalised word, a tag on two areas, a stand nobody wears, a
      cycle, and no Core.  Every .g in no Ground is listed on Everything as **`What:the groundless`** (11 today: the Hoho test
       .g under Ghost/test, ErrchannelTesting, Atlas's test corpus).  15 Grounds.
- **The chicken and the egg** — Ground.g is a .g in Core, so Core can't be stood by Theory.  **The floor** is plain TS:
   `src/lib/A/ground.ts` — `ground_closure(names)` (Core first, each Ground after what it stands on, `via` for the pulled-in)
    and `ground_include(top, names)`, which includes each .g **in order, one at a time** (eatfunc is last-wins) through
     `Lies_ghost_include`, from the baked manifest — no Theory, no wormhole.  Then Theory is here and **`Ground_stand(A,
      names)`** (`Ghost/A/Ground.g`) says it: `%GroundUsed:<Name>[,via]`, `%TheACode:Ground/<Name>` with a `%TheALayer` per .g
       (via `TheA_code_stand`), `%GroundRefused:<Name>,why:unknown`; current state (a Ground no longer named loses its rows; its
        methods stay).  `Ground_firm(A)` = every used Ground's code has its dige.  A .g still not loaded is fetched once as a
         fallback (unordered).  **The floor loads and Theory says.**  (Deviation: Core is included through the door from the
          manifest, not imported statically — same "no wormhole", and it keeps one door and one shelf.)
- **Hackarium stands on Ground/Land** (`HACKER_GROUNDS`): its hand list (Atlas, Lagoon, Workshop, Vyto) is gone; `ground_include`
   brings Core + Glass + Land, then `e_Hackarium_grounded` stands the Atlas/Lagoon worlds and calls `Ground_stand(A:Hackarium,
    ['Land'])`.  **So the room runs TheACode** — its A says which code it stands on, per layer, at which version.  It now also
     loads Electrode (unarmed), Garden, Pond and Voro, which it didn't before.
- **The Grounds read the manifest, not the wormhole, yet.**  Reading `wormhole/Ground/<Name>/toc.snap` through `A:Wormhole` is
   Desk's slice; the manifest is HMR'd by Vite, so a re-tag reaches a dev tab either way.
- **Proof**: Book **AthePondGround** (AtheTesting.g) — stands the real Core and CoreTesting on a toy A (nothing fetched on a
   shared runner): Core alone is whole and Firm; CoreTesting pulls Core in `via`; an unknown name is refused by name; naming
    nothing lets the rows go.  Recorded 5/5, 4 oaths, two check runs green.
- **The freeze it found (not the Ground's)**: three runner tabs froze at the start of ANY Book.  Storica's snap view (2026-10-22)
   is a deep Seem pointed at null until a step is opened, and `TheA_seem_source` fell back to the Seem's own compartment — so
    the deep walk went down into the points it was making, forever, in microtasks.  Storica mounts with the Story UI, so every run
     froze as it began; the Books that recorded the snap panel ran before Storica was copied in.  Fixed in Theory.g: a deep Seem
      pointed at nothing reads an empty tree.  Reproduced offline first (a stub House: pointed at its own compartment the walk
       never yields — not even a 3s timer fires); with the fix, 0 points in 23ms.
- **Not yet**: the closure check (Atlas: no call outside a Ground + what it stands on — Music surely stands on Wire, and Cave on
   Music, but no map citation says so yet); `Ground/Runner` (CREDULER_GHOSTS) — today's Wire+Music+Cave+tests, by hand.

### The trouble
What code a tab runs is decided five unrelated ways, none knowing where it's going: the spine (`O/Ghost.svelte` mounts ~20
 .svelte ghosts); `CREDULER_GHOSTS` (LiesLies ~:56, the runner's ~30 .g); a recipe's own includes (`L/Hackarium.svelte` names
  Atlas/Lagoon/Workshop/Vyto); `runner_ask ghost_load` by hand (gone on reload — Storica lives only on a tab I loaded); and
   `/Pondland` importing .go.  Books paper over it: 28 `"X is not loaded — ghost_load them beside AtheTesting.g"` guards in
    AtheTesting.g; a hollow green is the symptom.

### The pieces already there (and how they line up)
| piece | what it is | in the Ground picture |
|---|---|---|
| `wormhole/GhostList` | the editor's self-walking file index (every Doc in src/lib + Ghost) | **what exists** — the raw shelf a Ground picks from |
| `wormhole/Ghost/Everything` | one What per area → that area's Waft; generated + validated by `scripts/wafts_everything.mjs` | **what it means** — areas, for readers — and **where Ground tags live** (on its Whats, inherited inward) |
| `wormhole/Ground/<Name>` (new, derived) | a bundle emitted from the tags: .g to load + the .md beside them + other advice | **what to stand on** |
| `wormhole/Credence` | one `Funkcion:Storying,of_Book:X` row per Book | **what proves it** — gains which Grounds each Book stands on |
| `wormhole/Story/<Book>/Credulate` | HEAD: one `%GhostInclude:<gen>,dige` per included ghost (+ `%last_ok`); `Credulation` = the last 20 runs | **at what versions** — already exactly the per-.g diges the owner wants kept OUT of the Ground |
| `%GhostInclude` shelf (`Lies_include_shelf`) | every include attempt, `stood` + `dige` | **what is loaded now** on this tab |
| `%TheACode`/`%TheALayer` (Theory.g) | the code an A runs, layer per .g; the chain digest exists only once every layer is loaded; pushes wait for the era seam | **the loader's own shape** — a Ground stood IS an A's code |
| `Creduler_pending` → Story `waits:loadingcoding` | the runner's "don't begin until the code is here" gate | **the Firm gate**, generalised |

So the new thing to Seem into being is the chain **GhostList → Ground → (Story toc) → Credulate → Credence**: what exists, what
 to stand on, what a Book asks for, at what versions it ran, and what that proves.  Everything stays the readers' map beside it.

### Ground tags live on Waft:Everything; the bundles are derived **(owner, 2026-10-25)**
*"Waft:Everything is like Waft:Net/Easy or so, but higher level, for everything … and with the Ground tags in it."*  Everything
 already has one What per area (`What:the wire,…,FromWhat:Waft:Ghost/Net/Easy`), and each area Waft has its Whats and Docs.  A
  **`Ground:<Name>` tag on a What** says what that code is FOR; the area Waft's inner Whats and Docs inherit it, and an inner one
   may carry its own tag to override.  A container whose inners all share a tag takes it off them and wears it itself — the
    tag lives as high as it's true.  So:

    What:the wire,desc:…,FromWhat:Waft:Ghost/Net/Easy,Ground:Runner
    What:the theory,desc:…,FromWhat:Waft:Ghost/Atheory/…,Ground:Atheory
      (inner, in the area Waft)  What:the toy,Ground:Fish     ← overrides for its Docs

- **The bundle is derived**: the emitter (`src/lib/L/everything.js`, run by `scripts/wafts_everything.mjs` or the
   `everything` verb) collects every Doc under each tag and writes `wormhole/Ground/<Name>/toc.snap` — generated, never
    hand-edited, like the area Wafts.  Its `.g` Docs are what to load (in the order the map lists them); its `.md` Docs become
     the bundle's read-first advice for free (an area's spec sits beside its code); other kinds are skipped.
- **No diges in it (ruled)**: a Ground names files only, so it changes only when someone re-tags — never on a recompile; the
   headless compiler and the Lies pump never touch it.  Versions live where they already do: Credulate, per .g, per Book.
- **One home Ground per .g**: a .g is IN one Ground; a Ground that needs another's code stands on it (`Ground:Fish` stands on
   `Ground:Atheory` — said as a What,stands_on line the emitter carries through).  The validator refuses a .g reached by two
    tags.  This is what makes a Ground a clean build unit (below).
- **Unbundled is illuminated (owner)**: every .g no tag reaches is listed by the emitter (as it already lists Docs no area
   cites — its "unsorted" coverage line) and wears a "no Ground" badge in the Waft view; a tab that loaded one by hand shows a
    `%GhostInclude` with no `%GroundUsed` behind it.
- **Other advice rides as What kinds** (the loader acts on kinds it knows, lists the rest): `EntropyProfile,Wref:` → unioned
   into a Book's noise profile; **`Electrode:<doc or method>` → arm the call tap while the Ground stands** (owner: "how we tell
    runners of extra electroding we want them to do" — so a `Ground/Watch_Story` is a loadable layer of attention, and nobody
     forgets to disarm a shared runner); later verbs to enable, Styles, knobs.  A Ground with no code at all, only advice, is
      fine.
- **Configuring it in the editor (owner)**: in the editor's unit-hierarchy mode — today, the Waft view (Waft → What → Doc) — a
   What or Doc wears its Ground as a badge, and setting it is a gesture there.  ⚠ **The map is code** (`everything_map()` in
    everything.js), so the gesture needs somewhere to write: first slice, the tags are a `ground:` field in the map, set by
     hand; then the gesture becomes a verb that `writes` (editor terminal only) editing that field — or the tags move out of
      the code into a small data table the map reads.  Leaning: the data table, once there's a gesture.

### Core, and the base **(ruled: base implied; `Ground/Core`)**
To read a Ground at all a tab needs Housing (the House, eatfunc, the req machine, and `A:Wormhole` — its nav is in
 `Housing.svelte.ts`), Text (`decode_wh_lines`) and Theory + Ground.g (the loader).  That is **`Ground/Core`**: the one Ground
  loaded WITHOUT the wormhole — imported statically, as `/Pondland` imports Theory today — and its toc kept anyway, as the plain
   statement of what's compiled in (and Credulate records its diges like any other).  Then the base every runner stands on,
    implied — a Book's toc never names them, Credulate records the full set used:
- `Ground/Runner` — today's `CREDULER_GHOSTS` (the wire, the music, their Testing .g);
- `Ground/Atheory` — Theory's companions: Stuffica (Pond Books add `Ground/Fish`, the toy);
- `Ground/Story` — `Ghost/O/Story.g` (laid over Story.svelte until the spine swap).

### Desk — the universal top **(owner: "load the basic bundle without the Wormhole, then operate Wormhole to find the rest")**
Desk is what Otro|Auto are now, made plain: **import Core → stand Wormhole → read the recipe → stand its Grounds → wait for
 Firm → execute.**  The recipe is what the boot asks for, and every boot role becomes one:
 `?B=<Book>` → base + the Book's toc `Ground:` lines (and Story drives it); `?H=Hackarium` → `Ground/Land` (Atlas, Lagoon,
  Workshop, Vyto — today hard-coded in L/Hackarium.svelte); a music page → `Ground/Music`; `/Desk?G=Atheory,Story` → just
   those, to play.  Otro keeps working untouched until Desk can stand in for it.
### Two levels, one loader **(ruled: simple version first, Story the automated one)**
**`Ground_stand(A, names)`** — the one loader, in a small `Ghost/A/Ground.g` beside Theory: read each `Ground/<name>` toc
 through Wormhole, follow `FromWhat`, collect the `.g` Docs (ordered, de-duplicated), and call `TheA_code_stand(A, …paths)`
  — so **Firm is just `A/%TheACode` having its dige** (every layer loaded), a fact Theory already computes.  It records
   `%GroundUsed:<name>` on A **(ruled: the name)** — one per bundle, `FromWhat`-reached ones included with `via:<name>`.
    Includes go through `Lies_ghost_include` (one door, one shelf); a missing gen path or failed import leaves that layer
     dige-less, so the A never goes Firm and says why on the shelf.
- **The Desk (simple).**  `/Desk?G=Atheory,Story` (or a recipe that names Grounds): stand `A:Desk`, `Ground_stand`, wait for
   Firm, then execute — mount the UIs the loaded code enrolled.  No Story, no fixtures, no Credulate.  This is where the loader
    is seen working plainly.
- **Story (automated).**  A Book's `toc.snap` carries `Ground:<name>` lines **(ruled: only its extras — the base is implied)**.  At
   become_book Story reads them, stands them on the Run House's A (`Ground_stand` again), and the begin gate becomes "Firm"
    instead of `Creduler_pending`.  It adds what only Story needs: **Credulate gains the `%GroundUsed` lines** beside the
     `%GhostInclude` diges it already writes (so a run's versions are per .g, its intent per bundle); Credence's row for the
      Book names its Grounds (`wafts_everything.mjs` can generate that from the tocs); and the 28 hand guards become
       `Ground:Fish`-style lines in each Book's toc.
- **A Ground the runner can't stand is an exception, not a hollow run (ruled).**  If a named bundle has no toc, or a layer never
   loads (a player tab, a runner on an old spine without Theory), Story stops at begin with `%GroundRefused:<name>,why:…` and
    the run is red by name — never green-and-empty.
- **Unloading — not a goal (ruled: "very not important").**  eatfunc pushes methods onto every House and they stay; a Run
   House going away takes its `%GroundUsed` record with it, and a reload sheds the code.  Fine.
- **Changes while running** stay Theory's job: a .g in a stood Ground recompiles → `TheA_code_push` → held to the era seam
   (inside a Story run, at the step seam) — no Ground rewrite, because the Ground never held the dige.

### The UI — badges, not a pane **(owner: "seems more like a badge")**
- **In the Waft view**: a Ground badge on each What/Doc that carries a tag (inherited ones faint), "no Ground" on an unbundled
   .g, and — on a tab — the .g's live state off the `%GhostInclude` shelf (loaded at dige X / not / failed: why).  The badges
    coincide with Everything's grouping, as the owner expected: the tag IS the group.
- **In the Book explorer** — one of its aspects (the others not yet imagined: steps, oaths, Credulate's versions, Credence's
   row, recent runs, the snaps seated in Storica): the Book's Grounds as badges, the base faint, each green if this tab can stand
    it and red (`%GroundRefused`'s why) if not; and per .g, "the run is behind" — HEAD dige vs the last passing run's
     (Editron.md's unbuilt CreduFunk read side falls out here).
- As Stuffica views, so a load landing re-seats and the badges that went Firm glow.

### Prod: a Ground is a build unit **(owner: "eventually conventional javascript builds|bundles of these")**
Because each .g has exactly one home Ground, the Grounds partition the code, so the prod build can chunk by them: Vite's
 `build.rollupOptions.output.manualChunks(id)` maps a `src/lib/gen/**.go` to `ground-<Name>` from the derived Ground tocs —
  one request per Ground instead of one per .go, and Core in the entry chunk.  Dev is unchanged (one module per file, HMR as
   now).  ⚠ **A prod tab may have no wormhole tree to read** (a phone has no folder — memory no-fsa-persistence-model; a music
    tab's wormhole is its own folder or a GitHub lazy mount), so the build also bakes the Ground tocs into a small manifest and
     Desk reads that when Wormhole can't; the dev path reads the wormhole.

### Weird bits (worth knowing before building)
1. **The map is code** — see above; the editor gesture needs a writable home for the tags.
2. **Order matters**: eatfunc is last-wins (`ghostsHaunt` lays later files over earlier).  Stand order = what a Ground stands
    on first, then its .g in map order; clobbers are already reported (`TheA_clobbers_stand`).
3. **The .svelte spine isn't .g**: Lies, Lang, Cyto, Story.svelte… are mounted by `Ghost.svelte`.  The first cut covers .g
    only; a .svelte ghost could join a Ground later via the same dynamic-import door (`Lies_ghost_include` only knows gen .go
     today).  Core is static imports either way.
4. **Story.svelte vs Story.g**: `Ground/Story` names the .g; until the spine swap it is laid over the .svelte (as now).
5. **Re-tagging mid-session** changes nothing until the next stand — a Ground already stood keeps what it stood.  Fine.
6. **Electrode on a shared runner**: arming from a Ground must disarm when that Ground's A goes, or Books after it run
    instrumented.
### First slices, in order
1. ✅ *built 2026-10-25 — see As built* **Tags + emitter**: a `ground:` field in `everything_map()` on the area Whats (Core, Runner, Atheory, Fish, Story, Land);
    the emitter writes `Ground:` onto Everything's What lines and derives `wormhole/Ground/<Name>/toc.snap`; the validator
     (one home Ground per .g; every .g has a gen; the unbundled list; later, Atlas's closure: no call defined outside the Ground
      + what it stands on + Core).
2. ✅ *built + Book AthePondGround green 2026-10-25* **`Ghost/A/Ground.g`**: `Ground_read`, `Ground_stand(A, names)` on `TheA_code_stand`, `%GroundUsed`; Book `AthePondGround`
    proves it on a toy Ground (stands, goes Firm, a missing one refuses by name, a recompile waits for the seam).
3. **Desk's first slice**: `/Desk?G=…` — import Core, stand Wormhole, read, stand, Firm, mount.  The simple level, seen.
4. **Story**: `Ground:` lines in Book tocs (extras only), the Firm gate, `%GroundRefused`, Credulate's `%GroundUsed`; the Pond
    Books (and AtheStoryCode) off their hand guards; `CREDULER_GHOSTS` becomes `Ground/Runner`.
5. **Badges**: in the Waft view and as the Book explorer's Ground aspect.
6. **`Electrode:` Whats**: armed by `Ground_stand`, disarmed when the A that stood it goes.
7. Later: the editor gesture to re-tag (and the tags' writable home); prod `manualChunks` by Ground + the baked manifest.


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
