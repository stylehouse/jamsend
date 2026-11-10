# Wordland_todo.md — the new editor: find text anywhere, string it together, group it by relevance

**What the field is.** Wordland is the editor being built at `/BigWordland`: **search-first**.  The old editor (Editron)
 starts from a file tree and a Waft; Wordland starts from a box you type into, and every word in the project (code and
  prose alike) answers.  It is the one bet turned on the code itself (`Homethink §1`): the codebase kept as the same
   legible matter as everything else, so the editor is just one more reader of it.

**Editron vs Wordland.** Editron (`Editron.md`) is the current `role:editor` webapp, and it stays **stable**: it's the
 one writer and the reference compiler, on a frozen spine.  Wordland is `role:hacker`, on the live spine: it reads
  everything and writes nothing, and it reuses Editron's parts (Lies, Lang, the Waft tree, the Stemdex, the Keep).
   It will **take the write seat by wresting it** when the human is working in it.  It will **never compile itself**:
    compiles go to Editron.  The full account of the editor's powers is in `Editron.md` §8.  Wordland's future is to
     **fuse with Atheory** (§4).

## 0. What to get on with next

**✓ /Desk?G=Land — the land as a page (2026-11-09).**  Waft:Everything's land What wears `main:Land,role:hacker`; wafts_keep carries
 those into the derived Ground/Land as `Main:Land` + `Role:hacker` (any area may: a Ground that is also a page).  Auto stands A:Land on
  Mundo; its think (Ghost/L/LandPage.g) loads Ground/Land with its Glass, stands Atlas · Electrode · Lagoon on the top House (Lagoon's face
   on the page), and says the land as rows — `%Census:Atlas,docs,mapped` · `%Census:Electrode,armed?,flavour?` · `%Census:Lagoon` ·
    `%Exercise:<Book>,flows`.  The face (L/LandFace.svelte) draws them and holds a hole for `:verb args` through Verb_run, so a
     writing verb is refused (role hacker).  Seen in the eye: `:verbs` and `:electrode top` answer; folderless, Atlas says why it waits.
  TWO ROOMS, ONE LAND: /BigWordland (the Hackarium Book) has the docks, Langui and the cave — for READING code; /Desk?G=Land has no
   Book under it — the place for the land's ORCHESTRATION (Electrode_todo §0 PARKED: build the flavour, arm, flavour on/off, prune twins).
  ⚠ vite does not watch wormhole/: a changed Ground toc reaches a FOLDERLESS page (the shipped copy) only after a dev-server restart.
  Each Exercise Book presses into `:lagoon join --book=X` (declared vs measured — Lagoon_todo §0).
  ⚠ THE PAGE HAS NO RELAY CHANNEL (role hacker), so it cannot yet orchestrate a RUNNER — arm it, flavour it, sweep with --exercise.
   Its verbs act on THIS tab, which runs no Book.  Orchestration needs either a channel for a hacker page or the editor terminal.
  **ANSWERED 2026-11-09 — REBUILD THE FACE, REUSE THE MODULES; DON'T STAND Lies+Lang ON THE PAGE.**  The owner's want: *"multiple
   codemirrors and multiple EditorStates, arbitrarily many, yet aligned by whatever, arranged however."*  Lang|Langui is built the
    other way: Langui is ONE EditorView swapping per-path EditorStates (its header, "Option B"), Lang has ONE foreground
     (`w.c.active_dock_path`, 34 sites in Lang.svelte, more in LangLang/LangHold/LiesCurse…), and `dock.c.view` is singular — so
      two panes of one doc can't even be said.  Standing A:Lies/A:Lang here would also bring the Book-shaped req stack, the
       editor-only Keep and the `hacker:1` recipe stamps the Ground is meant to replace (LiesLang_todo §11 "the recipe goes").
   What IS reusable, as plain modules: `$lib/O/lang/lang.ts` (`lang(name)`, `lang_for_path` — grammar + a hue per mount),
    `codemirror`'s basicSetup, `lang/compile.ts` (the translator — and Atlas already ran it into a `%Map` per doc, so Points
     and def lines come from the census, not LangGraft), and Atlas's nav for text.  **BUILT, slice 1:** `:pane open|close|align|arrange`
      (`verbs_Land`, a split read/land verb) — `%Pane:<n>,doc,line,at?` and `%Layout:grid|row|column` on w:Land, text on the row's
       .c; L/LandPane.svelte is one EditorView+EditorState per pane, read-only, scrolling its row's line to its top.  `open` takes a
        path[:line] or a method (Atlas finds its def, a .g first); `align <method>` moves every pane holding it to that def — panes
         line up on a KEY.  Proven: runner (open by method/path, missing named, align lined 1 of 3, arrange row) and the eye (3 panes,
          `Target` at lines 121 and 301 both at the pane tops).  Owed on the road:
   - **Alignment beyond the top line**: spacer block-widgets so several keys line up at once down two panes (what @codemirror/merge
      does for diff chunks — not installed; ours would key on Map rows: defs, calls, a Flow's caller/callee).  First press: a
       join's "never ran" pair opens caller + callee panes aligned on the call.
   - **Writing**: the panes are read-only until the page holds `%Seat:editor` — **the write seat and the relay channel ARE one
      decision**: a seat is held on a relay socket (relay.ts `seat`), and the same channel is what lets this page orchestrate a
       runner (arm, flavour, sweep).  Give the Land page a channel (hacker binds without editor duties, as BigWordland's room does)
        before either.  Compile then rides LocalGen-in-node (LiesLang_todo §11 step 2 re-aimed), not Lang's Codebit.
   - **Arrange however**: `%Layout` is three CSS modes; draggable/resizable panes would keep their sizes on the `%Pane` rows.
   - **Lagui is off this page** (owner: *"is Lagui Stuffica era? it might not be worth keeping much of it"* — it is not: September, polls
      the reader every 1.2s, its clicks go to `Lies_ghost_pick` which needs an A:Lies, so here each click was a `no House has A:Lies`).
       Lagoon stands `faceless` on the land page (`Lagoon_plan`); LandFace asks `Lagoon_seek` on a keystroke and a hit opens as a
        pane (`--reuse` moves the pane already on that doc, `--at=` names the method).  The clerk's desk goes with it.  Lagui stays in
         the Book rooms until they move; its reported 2.5s remount was not reproduced (folderless eye: no remount) and is moot here.
   ⚠ The `verbs_*` registry skipped split verbs (no `run`) — LiesFunk `Verbs_all` now takes `run` OR `read`.

**THE WEAVE — planning meeting, 2026-11-10 (owner's answers; Lies|Lang docs read: LiesEnd_spec, Lies_attention_todo, Story_future §13).**
 The land page holds several docs; Exercise says what ran between them.  The aim: see *what is woven where*, and keep a record of
  the looking that a person can reshape.
- **Taken from Lies|Lang — the ideas, not the machinery.**  The medium (Waft → What → Doc → Point; "Doc" stays the word, as Atlas's
   `%Doc` already is); one Interest per stream (Trail / Aside / Ting); **+time** (Story_future §13.4: at a significant change mint a
    sibling What — engaged Points carry forward, new ones move, the rest ghost); the LE's origin/working Seems as the later write path.
     Left behind: Langui's one view, `%Spotlight`, the P7 cursor debt, and **LiesStore** for this page — the nav writes directly
      (`write_file`), and a hacker's own record contends with nobody, so it needs no seat.
- **Slices are the user's to reshape (owner).**  A slice (the set held between two significant changes) shows its REASON and its
   MATTER, and the user can split, merge and unmerge slices into commits; a run of them becomes a slideshow, or smoothly a new part of
    the machine — "this part of the organ of language acquisition".  So the slice is a first-class row with a reason, never a log line.
- **Three layers of seriousness** for remembering (owner: agreed; the visual "fold-uppity" is his to find): Trail (deliberate —
   open, align, pin), Aside (passing — a seek hit moving a pane), Ting (dwell — fades, unsaved).  **Storage: hacker-instance-private**
    — `wormhole/Hacker/<who>/Trail|Aside/…` written through Atlas's nav (Wordland_todo §0 5 already wanted the Keep and the Asides
     under the person).  ○ unbuilt.
- **The drawing wants a PLAINER UI than CodeMirror (owner).**  A pane is CodeMirror only when really opened; otherwise it is a
   **stiff member** — the Doc as a hierarchical list of its objects: `Lagoon_beads` (regions in file order, defs under the bead their
    author drew), each bead's defs laid as a **StemHive** (the minimap's stem-factoring hive, `ui/StemHive.svelte`, plain props,
     `data-mid` on every chip).  Light is cast on each member's Map, and Exercise puts the edges in.
- **Two zooms (owner).**  Far: members side by side, wires between their chips (declared calls from Atlas `%call,via,method`,
   coloured by a chosen Book's Exercise — ran / never ran / undeclared).  Near: a member opened as CodeMirror — line-to-line wires
    only there, where there's room.  The map beyond the panes goes on the glass (Vyto guise), not Cytoscape.
- **✓ (1) BUILT 2026-11-10.**  A `%Pane` without `code` draws as **L/LandMember.svelte** (bead boxes of StemHives off
   `Lagoon_beads`); `:pane code <n> [method|line]` / `fold <n>` flip it; `:pane weave <Book>|off` reads that Book's Exercise
    (`%Weave:<Book>,flows`, the pairs on `w.c.weave`) and `Land_wires` keeps `%Wire,from,to,from_pane,to_pane,state?` — Atlas's declared
     cross-pane calls, state ran|never, plus measured-but-undeclared pairs; rebuilt only when the set moves.  LandFace draws them as an
      SVG layer (chip side to chip side, a scrolled-out chip pinned to its member's edge, a code pane wired at its bar), lights the
       wired chips, tallies ran/never/undeclared; ⇄ by a Book weaves it.  Proven: runner (Atlas.g + Lagoon.g + AtlasTesting.g woven by
        AtlasStaple → 10 wires, all Lagoon→Atlas `never` — true: that Book never runs Lagoon; the test↔Atlas wires are ABSENT because
         its Exercise reaches Atlas callerless — `Flow,of:Atlas_pass` — the call-site gap, Electrode queue (1)); the eye (3 members,
          25 chips, 6 staged wires drawn).  Owed: intra-member wires (a doc calling itself), more Books' Exercise (only AtlasStaple is
           kept — `runner_sweep --exercise`), and the owner's look with real data.
- **✓ (2) slices + erupt + direction/intensity BUILT 2026-11-10** (owner: *"mostly manual goo-partitioning, with some suggestion based
   on activity gaps which are taken automatically in some cases"*; *"something that explodes sets of Docs … the edges need direction and
    intensity"*).  `%Slice:<k>,auto?,from?` on w:Land holds `%Act:<reason>,docs,glance?` (each deliberate pane verb, in order — the
     REASON) and `%Doc:<path>` (the union held — the MATTER).  A quiet > LAND_SLICE_GAP_MS (2 min) cuts automatically, marked `auto`
      (dashed chip — a suggestion; ⊕ merges it back).  `:slice cut|merge k|split k i|go k`; acting after `go` mints `from:k` — a
       branch.  `:pane erupt <n|method>` opens the docs at the other ends of its calls (out + in, busiest first, `.ts` House primitives
        skipped unless `--all` — the join's rule; without it Housing.svelte.ts tops every erupt).  Wires carry `n` = declared call sites
         (stroke width) and an arrowhead to the callee.  Proven on the runner (erupt LandPage → LiesFunk 3, Atlas 2, Electrode 1;
          cut/merge/split/go→branch `Slice:3,from:1`) and the eye.  Slices live on .c-free rows but die on reload (no store yet).
   Owner's storage thought: `wormhole/Hacker/<who>/<session>/Trail|Aside/…` — "everything's regroupable in this Waft|Mag-like C**";
    Trail and Aside are datestamped already, and time is tricky.  ✓ carried-vs-fresh (2026-11-10): a slice's `%Doc` the slice before didn't hold wears `fresh` (NOT `new` — a session key the encoder strips, so it vanished from every snap).  Owed: the store.
- **✓ The map + focus + reach BUILT 2026-11-10** (spec/Land_guide.md is the manual).  The top is Everything's areas in DocIndex's
   sections (`src/lib/L/land_map.ts`), a Ground line (`%Aim`).  Pressing an area runs `:pane area <title>`: its busiest docs (4) open
    as members with the area's main functions as `%Focus` rows — bold, their beads open, beads without one folded.  A member scrolls to
     `at` or its first focus.  Pressing a def shows its REACH over the member (`Land_reach`: callers / callees grouped by file, off
      Atlas) — a file or method there opens as a member aimed at it; `{ } read` makes it code.
- **The Mag UI is where these belong (owner, 2026-11-10: *"perhaps we have to really expand the Mag UI (which is nowhere yet, but
   prototyped with Waft), so we can lay all these specifications on it, like folding areas, styleings, edges, arrangement, warp"*).**
    This page is already a hand-written renderer of exactly that vocabulary, as rows: folding/emphasis = `%Focus` (+ fold state, today
     local to the member), styling = `%Area,hue` and its tint by `%Cites`, edges = `%Wire,state,n`, arrangement = `%Pane` order +
      `%Layout`, time = `%Slice/%Act/%Doc`, the frame = `%Aim`.  So it is a catalogue of what a Mag UI must take as specifications;
       "warp" (relevance distorting the layout — the Lens idea, Lies_attention_todo §5) is the one not here yet.  Unbuilt; read
        Pile_todo §0.0 / Mag_todo with Waft.svelte before starting it.
- **✓ The glyph — the common frame of reference BUILT 2026-11-10** (owner: *"present this glyph-looking thing that is a tiny overview of
   Everything, with whatever placed inside it where it goes … Repli.g would be sitting magnified in amongst the entire structure, and if
    there were a list of such things, the glyph would stretch and hold multiple branchings"*).  `src/lib/L/LandGlyph.svelte`: sections →
     area cells (hue) → one tick per code file the area cites (its Waft's order; a file is at home in the FIRST area citing it) → a file
      in `things` magnified in place of its tick, its method lists stemmed (StemHive), its cell stretching; files no area cites in a last
       dashed cell.  Used twice: a def's REACH (callers ⟵ / callees ⟶ placed where they sit) and above the panes (the open panes, tagged
        #n — press one to scroll to it).  The flow arrangement is a stand-in: **the spaceship's layout** (owner: "we shall soon have a
         layout for the spaceship") replaces it; the frame — sections → areas → files → methods — stays.
- **RESOLUTION — the universal order that is missing (owner, 2026-11-10; a big project, wants human design work first).**
   *"we have loads of vague objects in Everything, then the minimap pane, then a codemirror pane … the minimap is supposed to be a Mag**
    structure styled to look like a minimap, and having no ability to CRUD … having a way to adjust the resolution the Mag was presented
     in to be able to CRUD it sometimes, is the universal order."*  Today the land page has three resolutions, each a different component
      with its own data path: an area chip (Everything — a What), a member (Atlas's Map as beads + hives — read-only), CodeMirror (the
       text — where editing would live).  The order wanted: ONE structure (a Mag** — the same C** a Waft prototypes) presented at a chosen
        resolution, the presentation a spec on rows (fold, style, edges, arrangement, warp — the bullet above), and CRUD appearing only at
         a resolution where it makes sense (text at the finest; renaming/moving a def at the member's; regrouping at the area's).
   What this page already proves about it: the levels share KEYS (a method name is one hop from area Def → member chip → CodeMirror line,
    which is why `--at` and `%Focus` work across all three), and every level change so far is a pane verb (`area`, `code`, `fold`) — a
     resolution dial would be those verbs made continuous.  Open, for the owner: what a Mag** of code IS (rows per def? per bead?), whether
      Atlas's `%Map` becomes that Mag or feeds it, and what CRUD at a coarse resolution writes back (to the .g? to Everything's tocs?).
- **Order:** (1) members + wires — `%Pane` without `code` draws as a member, `:pane code|fold`, `:pane weave <Book>` → `%Wire`
   rows; (2) slices as rows on w:Land (+time), reason + matter, split/merge; (3) the private Trail|Aside store; (4) slideshow /
    becoming machine; (5) the glass map.

**✓ The 2026-11-09 Atlas red is CLOSED.** AtlasStaple (6/6) and LagoonStaple (8/8) are green again.  Two causes: `atlas_diges`
 (src/lib/server/dige.ts) refused a nested root such as `Ghost/L/test_corpus`, so it answered `docs:0` — fixed to take plain segments
  joined by '/'; and the remaining reds (AtlasStaple step 5, LagoonStaple 3·5·6) were a STALE RUNNER TAB — `--reload` turned them green
   with no code change.  A red after a server-side fix: reload the runner before reading the code.

1. **Strings and groups (§1.2–1.3)**: the features that make Wordland more than a search box.  Neither is built.
2. **The write seat** (`Editron.md` §8.2 A): a lease at the relay, wrested by the active tab, with `Lies_holds_seat`
    replacing `=== 'editor'`.  Until then, Wordland writes nothing and Editron is the only writer.
3. **One compiler per ticket** (`Editron.md` §8.2 B): today a `ghost_compile` reaches every editor tab.
4. **The cave's rough edges** (`Glassbeast_todo.md`, the "THE CAVE" log entries): a pressed answer item still lands
    with `leave:1` and resets the query; middle-click paste is unverified.
5. **Seats and the map (owner, 2026-10-21).**
    - **Waft:Everything → `wormhole/Ghost/Everything` — DONE 2026-10-21.**  The map of the whole program now sits among
       the area Wafts it maps (`EVERYTHING` in `src/lib/L/wafts_keep.js`; the cave reads it by that constant).  Owner leaning: one vague big map leading everywhere, close-range knowledge as per-.g
          overlays — the area Wafts may go.
    - **The Keep is one person's seat, not a store.**  It holds their open Wafts (`WaftTimes`), cursor, per-Waft
       layout and Aside ledger — one `Waft:Keep` per repo, so two people stomp each other, and `Lies_keep_boot` is
        editor-only because it also writes, so a hacker room reopens nothing (Hackarium shows one Waft: `?W=`).
         Berth it — and the Asides — under the person's **prepub**: `wormhole/<prepub>/…`.  Then it is multi-user
          safe, a hacker reads its own person's seat, and it wants a firmer name than Keep.  Open: what a hacker room
           with no relay knows its prepub as.

## 1. The features — FIND, STRING, GROUP

Three verbs, in order of how built they are.  Each names what stands (✅), what's partly there (◐), and what's only
 wanted (○).

### 1.1 FIND — any text, anywhere in the project

You type; everything that mentions it answers, code and prose alike, down to the line.

- ✅ **One box** (the hole): a plain room input, drawn atop the cave's glass or, in the sprawl, atop the Vyto piece.
   `/`, the ⌕ chip and a click on the spine's head all bring you to it.  It debounces until a word is forming.
- ✅ **Every mention, per line**: `Lies_search` returns every line a word sits on (capped at 40 per doc), and the cave
   makes one hit per line, deduped by `path:line`.  The tiers are exact ▸ prefix ▸ substring over defs, then free text.
- ✅ **Code and prose in one index**: the Stemdex (stem → path → lines) over code, specs and todos alike.  A spec is a
   place: a file Atlas has no map of opens as a FLAT level (its hit lines, with the text landed beside).
- ✅ **A file's shape**: `doc:Heist` seeks a file's anatomy; a file opens to its methods in file order (`Lagoon_beads`
   gives the regions an author drew).
- ✅ **Who calls this, what it calls**: a method is a place with two doors, ⇝ calls and ⇜ callers (Atlas `call`/`elvisto`
   rows; `Lagoon_callers`).  Walking a door lands the code in the editor beside a rail.
- ✅ **Prose that names code**: Atlas holds every backticked `name` and file link in the docs.  `Lagoon_mentions` splits a
   real LINK (Atlas holds the def) from a phrase.  `Lagoon_prose_rot` finds docs naming things that are gone.
- ✅ **Verbs from the same box**: `:verb args` runs a tab's controls (`Verbs_todo.md`).
- ◐ **Ranking**: hits come in tier then file order.  Nothing yet ranks by what you've been looking at, how recent the
   file is, or how often a stem occurs.
- ○ **Phrases and near-words**: search is per stem.  There's no multi-word phrase match and no "did you mean".

### 1.2 STRING — hits tied together into a line of thought

A search answers once.  A string is what you keep: hits you've walked through, tied into a trail you can come back to,
 hand to someone, or prove.

- ✅ **The rope**: the cave's stack of steps (search › file › method › …), shown as the head's label; Escape climbs it.
   But it's a single path that goes away when you go back to rest.
- ✅ **Errands**: the Aside / Clerkdesk keeps *why* you went somewhere, by day (`Lagoon_errands`; `Clerkdesk_todo.md`),
   and marks visits whose target has gone (`gone:1`) without hiding them.
- ✅ **Pins**: a hit can be pinned into the rail at the right of the code.
- ○ **A string as a thing**: a named, ordered set of hits (`path:line` + the words that found it) that persists as a Waft
   (`What` > `Doc` > `Point` is already that shape), re-opens where you left it, and survives the code moving (re-found
    by its words when its line drifts).  The rope, the errands and the pins are three partial versions of this; **the
     feature is to make them one**, not to add a fourth.
- ○ **Strings that prove**: a string whose last knot is a sworn sentence in a Book — "this claim is tested here".
   `Lagoon_unproven` already knows which claims nothing swears.

### 1.3 GROUP — hits gathered up into groups of relevance

A hundred hits is a list; ten groups is a map.  Grouping is what makes "every mention" usable.

- ✅ **Families**: hits gather into stem families (methods sharing a stem, `Lagoon_families` / `Lagoon_cave_families`);
   at rest, the code's families stand around the hole.
- ✅ **Areas**: Waft:Everything's areas (`Lagoon_cave_areas`): one group per area of the program.
- ✅ **Files and folders, regions and sections**: the natural containers, which the glass already draws as places.
- ○ **Relevance groups**: hits clustered by how they relate, not where they sit.  By the call graph (hits that call each
   other belong together), by co-mention (docs that name the same three methods), and by the join (code that ran in the
    same Book).  Every input is already held: Atlas edges, Atlas links, Electrode flows.  **A group is a reader's
     answer, never a stored copy** (§2).
- ○ **Groups you can name**: promote a relevance group to a string (§1.2), so a cluster you found becomes a thing you keep.

## 2. The concept line — Atlas KEEPS; everything else ASKS

Ruled 2026-09-08.  Atlas has one concept: the compiler's own index of every doc, kept fresh.  For any feature, ask:
 *does it change what is HELD, or does it ask a question OF what is held?*  Finding, stringing and grouping all ASK.  So
  they live in Lagoon or in readers of their own, never in Atlas.  The tell that this is slipping: a smell given a
   *mitigation* instead of a *home*.  One generator maps code for the editor and the census alike: `Lang_map_into`
    (`src/lib/O/lang/compile.ts`, which contains NUL bytes, so use `grep -a`).

## 3. What stands

| piece | where | notes |
|---|---|---|
| the room | `src/lib/L/BigWordland.svelte`, `/BigWordland` | the H\*\* switcher, ⌐Lies, ▦ sprawl, the pin rail, the cave over all |
| its Book | `src/lib/L/Hackarium.svelte` | stands Atlas + Lagoon itself; `role:hacker` (`?E=` still boots the old `Educarium` editor) |
| the cave | `Ghost/L/Lagoon.g` THE CAVE + `Ghost/V/Vyto.g`/`Vytui.svelte` | search › file › method › area › watch; Book `LagoonCave` |
| the census | `Ghost/L/Atlas.g` | every doc's `%Map`; Book `AtlasStaple` |
| the readers | `Ghost/L/Lagoon.g` | seek, callers, mentions, families, beads, lint, rot, errands, join; Book `LagoonStaple`; `Lagoon_todo.md` |
| the word index | Stemdex + `Lies_search` (`LiesFunk.svelte`) | separate from Atlas, settled; `Stemdex_todo.md` |
| the tap | `Ghost/L/Electrode.g` | both ends of every call; **parked until Atheory** (`Electrode_todo.md`) |
| the index Waft | `vite.config.ts` digePlugin → `wormhole/Docindex/toc.snap`; `src/lib/server/watch.ts` | §5 |
| controls | `verbs_<Ghost>()`, `Ghost/L/Workshop.g`, `Ghost/Play/` | `Verbs_todo.md`; Book `WorkshopStaple` |
| the desk | `src/lib/L/Clerkdesk.svelte` | `Clerkdesk_todo.md` |
| the Waft tree | `src/lib/O/ui/Waft.svelte` (shared with Editron) | its own C sticks at the top, with a path-in breadcrumb under it |

L ghosts are not in the spine manifest: a runner gets them with `runner_ask ghost_load Ghost/L/X.g`, a reload drops
 them, and a Book's `*Testing.g` must be loaded too or the Book runs hollow.  Truth goes in particles and caches in `.c`.
  Never mint a particle per call or per line.  Bulky pictures are `dontSnap`.  No timers.

## 4. Wordland and Atheory — the fusion

Atheory (`Atheory_todo.md`) is the rebuild of how code loads onto Housing.  Wordland is where that rebuild becomes
 visible, and the two already share their irritations:
- **Load lists**: L ghosts sit outside `CREDULER_GHOSTS` and arrive by `ghost_load` or `Lies_ghost_include`, which is
   the "random lists" disease in miniature.  A declared A\*\* manifest is the cure, and Wordland is the room that would
    show it (which ghosts are loaded where, as particles).
- **Variants**: `TheA_<Name>_<Variant>_<dige>`, where an electroded build is the first variant.  The parked tap waits on
   this, and so does line-level tracing for teaching the program's flow.
- **The focus twin** (`Focus_todo.md`): "whoever is active" wrests the write seat.  Who is active is the attention
   authority's answer, so the seat and the focus coordinator should be built as one thing.
- **Not relying on itself**: when Atheory's headless compiler exists, it, not any tab, holds the compile authority
   (`Editron.md` §8.2 B).

## 5. The index the watcher writes (was `Docindex_todo`)

The dev server already watches the tree, so its plugin writes `wormhole/Docindex/toc.snap`: `%Doc:<path>,dige,mtime,size`
 for about 730 docs.  It is a Waft, and a tab opens it like any Waft.  Built on it:
- **The roster**: `Atlas_index_read`, with no walk and 0 reads paid (`IndexRoster.spec.ts`).
- **The SuperMap**: the census is one snap, decoded once (passes 12–21 → 1–2), and adopted only if the dige still matches.
- **The push**: `control:docindex` on rewrite (about 450ms from touch to heard).
- **The watch desk**: `watch.ts`, interest per socket and path, `control:changed` (`relay-test.ts`).
- **Waft retake**: a Waft that moved on disk is re-placed in one `place()`, so an armed `%Interest` survives (Book `HohoRetake`).

**Bombs:**
- The dige gate is the safety: weaken it and a stale Map serves silently.
- Only live-spine tabs hear pushes; Editron, on `pinned_stable/`, doesn't until it's re-pinned.
- Quote pass counts, never one wall clock.
- If a part seems missing, it's probably `C`/`Waft`/`Seem`/`Repli`/`req` under another name.  Three bespoke transports
   were built and retired learning that.

The destination, deliberately last: a Seem that *maintains* the Map across edits.  Which spans to re-run is a graph
 question, and the graph is already held.

**Opening a doc is not slow** (≈0.6–1.0s, measured).  The waits had two causes, both fixed:
- the room's clock was never handed back (`Story_release_clock`; a room Book must release it);
- the disk queue was queue-wide (`Wormhole_park` now runs per path, reads first).

## 6. Verify

```
node scripts/runner_ask.mjs ping --player=<code-room pub>               # role:"hacker"
node scripts/runner_ask.mjs ghost_load Ghost/L/LagoonTesting.g --runner=<addr>   # then run LagoonCave — via the Sonnet subagent
GFILES="Ghost/L/X.g" npx vitest run --config scripts/Story_cli.vitest.config.mjs scripts/LocalGen.spec.ts   # then esbuild-parse the .go
```

History:
- `history/Wordland_todo_2026-09.md` has the 2026-09-08 overview: the measurements, the two pictures and the join, five
   UX stories, the first order of work, and the naming questions.  **Older `Wordland_todo §N` citations point there.**
- `history/Docindex_todo.md` has the index's full build log and the doc-open hunt.
