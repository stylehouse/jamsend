# Pile — the showroom for Atheory: a music pile you walk, listen through, and write over

**Status: a todo, born 2026-11-03** from the owner's words (§1).  It is the brief for the agent who builds it: §0 says what to do
 next, §2 is the Atheory intro a newcomer needs first, §3 is the shape, §4 the rungs.  It is `AtheoryNexus_todo.md` §0.0 frontier
  **G**, the first app built on the new fabric — and `?G=Pile` is how a tab will stand on it (frontier E, built: `/Desk?I=…&G=Runner`).

---

## 0. What to get on with next

1. Read §2 (Atheory in one sitting) and `CLAUDE.md`; then `AtheoryNexus_todo.md` §0.0 (the land map) and its *E thought through*.
2. **Rung 1 — the listing as a Mag, drawn as squares** (§4): a `Ground/Pile` composition and a Book that streams a folder's
    listing (a fixture tree, then a real FSA handle) into a `Mag**` held under a Seem, and a new Stuffica-era view that draws it
     as plain squares in scrolly panes.  No Stuffing fold, no Waft, no typewriter yet — the basic square shape first (owner).
3. Every rung is a Book first (`Stands:<Ground>` in its toc, a Credence row), sworn with `story_swear`, run on the live runner.
4. Ask the owner the §5 questions as they become load-bearing — not up front.

---

## 1. What the owner asked for (verbatim, kept)

*2026-11-03, first:* "something to explore the filesystem listing as a floaty space, that can be remote mounted or whatever, and just
 present sort of like a landscape... and that will also let us put together a Heist setup visual that involves the reality of what's
  already where it's going, and let us choose from the user's extant categories instead of a given one, etc. … a separate page in this
   app for loading another FSA to another music pile, in order to incorporate it in your main music pile. as a way to have a
    music-pile-merging workflow seriously happen. that would want a top-down view of the exact pile of music, listening and dialing in
     where to put each one, and managing a huge workflow of that over a few sessions perhaps... for merging music download folders that
      might have become giant and want guided mechanical automation wrt moving into the collection structure."

*2026-11-03, later:* "the showroom for Atheory, where we UI+UX the Mag** scrolling shape, and having an A+B hemisphere of them that
 we're making relations between and pointers to the contents of... a place where you listen to music, and have a typewriter that knows
  that and can make Mag**, here or there, directly in the filesystem or superimposed and shared with others, so one can make cave
   systems across other Mag**, all presented like a magazine, with language as an artform, in a space made for music... Stuffing's whole
    idea is compression and expression in a sort of structured space."

*2026-11-03, third:* "Pile B is another FSA handle to some pile of music in a directory somewhere. we're going to be presenting a
 collection as landscape. ah! I forgot to say that FSA directory listings shall stream into a Mag** somehow! that's a Seem. stuff can
  hang out in there, and should notice being moved around. this is a nice careful reversible file manager, via being put into a Mag**
   that represents the filesystem, to give us some basic CRUD, and movings... I think Mag are presented as Waft are but more
    advanced... we'll just make another Stuffica era UI for now, to avoid touching Waft directly, but you get the idea of just racks
     of atoms... different scrolly panes that can vector-graphique between each other to show the webbing of sameness or movement or
      so... drawing the albums and bunches... kind of forget Stuffing initially, lets get the basic square-shape working first"

---

## 2. Atheory in one sitting — the intro

**The bet** (CLAUDE.md, `Homethink_todo.md`): every kind of state — a song, a test, a friendship, an error — is the same living matter,
 particles (`C`), held where a group can see it, prove it and rewrite it while it runs.  Music is poured through it first.

**A particle** is a `C`: `sc` (scalars, snapped) and `c` (runtime refs, never snapped); its type is its mainkey, the first sc key
 (`%Mag:heard`, `%Card,id`).  Find-or-create with `o`/`i`/`oai`.  A thing exists ONCE where it is held; anything that names it elsewhere
  wears its own mainkey and carries the id (`%Record,id` is the holding; `%Card,id` refers to it).  This rule is the whole of "pointers":
   §3's relations are referring particles, never copies.

**Houses and As.**  The old machine is Houses (`H:`), worlds (`w:`) and actors (`A:`), driven by thinks and the req machine.  **Atheory**
 (`Atheory_todo.md`, `Atheory_design.md`) is its rebuild, "A\*\*": **As standing in As**, each holding its own code (a compiled `.g`
  version), served the nearest thing by walking out through the As it stands in.  The words — compartment, row, pass, synapse, axon,
   pulse, move, boundary, Turn, Seem, point, Regard, tendril — are `Atheory_design.md` §0, each with the particle that carries it.
    Read that table once; it is short and everything below uses it.

**The spine of this era: decide from rows, not from signals.**  What runs is decided by rows waiting (a `%Job`, a held think at a
 door, a pulse on a synapse), never by timers, `$effect`s or throttles waking things up.  A click is an arrival; a disk reply is an
  arrival; a step of a Book is an arrival.  If you find yourself adding a setTimeout to make something happen, stop — make it a row.

**Grounds** are what a tab stands on (`src/lib/A/ground.ts`, `Ghost/A/Ground.g`, `wormhole/Ground/<Name>/toc.snap`).  A *partition*
 Ground only loads code (Music, Glass, Swarm, Cave…); a *composition* also says how to run — `Main:` (the A the page runs from),
  `Role:`, `Face:`.  The tocs are hand-kept rows.  A page is **an Identity standing on a Ground**: `/Desk?I=<who>&G=<Ground>`.  So
   this app is `wormhole/Ground/Pile/toc.snap` (stands on Music, Glass, …; `Main:Pile`) and `/Desk?I=…&G=Pile`.

**The Desk and the Story.**  A Book (a Story test, `wormhole/Story/<Book>/`) runs in a Desk — its own House holding an `A:Story` —
 snapping the particle tree between steps and comparing against fixtures.  Books are how anything here is proven; the live runner
  tab is how they run (`scripts/runner_ask.mjs`, `scripts/runner_sweep.mjs`; never headless).

**Stuffica / Stuffing — the showroom's own idea.**  Stuffing (`src/lib/data/Stuffing.svelte`, `Stuff.svelte.ts`) renders a particle
 tree by grouping and zipping its rows — *compression and expression in a structured space*: many alike things fold into one row that
  says how many and how they vary, and open again when attended.  Stuffica (`Atheory_design.md` "Stuffica, the shape";
   `AtheoryNexus_todo.md` §3.12) is that idea on views: **Show** (built), **In** (a backend pile swapped whole through the door — not
    built) and **Out** (a click as one arrival — not built).  **The Pile is Stuffica's first real In and Out**: a folder listing IS a
     backend pile, and every gesture on it is an arrival.

**What exists to build on** (don't rebuild): the Mag (`Mag_todo.md` — `%Mag` of `%Cloud,page` of `%Record`/`%Card`; `Mag**` is walked
 recursively), the radio and listening (`Ghost/M/Radio.g`, `Sound.g`), heisting a track into a library (`Ghost/M/Heist.g`,
  `Heist_todo.md`), the collection-too-big-to-list (`Wander_todo.md`, `Census_todo.md`), the navs (`MountNav` → `WormholeNav` +
   `OpfsOverlayNav` — an overlay over a folder already exists), remote mounts (`RemoteWormholeNav`, `RemoteHeist_todo.md`), sharing
    over the wire (Repli, `Ghost/N/Repli.g`), the glass (`Ghost/V/Voro.g`, `Vyto.g` — the landscape renderer, guises for non-particles),
     and the code cave (`VytoSpine`, memory "the code cave": a producer presses guises, Vyto only draws — passages and torches).

---

## 3. The shape

**The listing is a Mag\*\*, kept by a Seem.**  An FSA directory listing streams into a `Mag**` that *represents* the
 filesystem — a Mag per directory (nesting is `Mag**`, walked recursively the way `Ra_recs_deep` already does), a row per
  file.  The Mag is held on an A and controlled by a **Seem** (`Atheory_design.md` §0: a controller over a compartment that
   walks the rows of the kinds it holds and keeps a **point** per row, paired walk to walk by what holds still).  That pairing is
    what lets a thing **notice being moved**: re-walk after a move, and the point that lost its old place pairs with the row in
     its new one — a move, not a delete-plus-create.  And a Seem is the one controller that can **roll back** (`%TheAMark`,
      `TheA_seem_rollback`), which is what makes this a **careful, reversible file manager**: CRUD and moves are proposed on
       the Mag, carried to disk as Jobs, and every one has a mark to return to.  Things can also just *hang out* in the Mag —
        notes, relations, pointers — superimposed on the listing without touching a file.

**Two hemispheres, A and B.**  B is another FSA handle (a second directory picker in the same browser) to some pile of music
 somewhere; it streams into its own Mag the same way.  A is the collection (the main pile, its own folder structure — the user's *extant* categories, read
 off the tree, never a given taxonomy); B is the incoming pile (another FSA: a giant downloads folder, a friend's mount).  Each is an
  A holding rows read from its tree.  The work is making **relations** between them: "this B album belongs under that A folder", "this
   is already in A", "this B track is the better copy".

**Relations are particles, pointers are referring particles.**  A relation is its own mainkey, held by whoever made it, carrying both
 ids — never a copy of either side.  A pointer into a pile's contents is a `%Card`-like referring row.  The tell you got this wrong:
  two different shapes under one mainkey.

**The view: racks of atoms, panes webbed together.**  A Mag is presented the way a Waft is, but more advanced — and for now
 we **don't touch Waft**: Pile gets a new Stuffica-era UI of its own.  First shape, deliberately plain: **squares**.  A
  directory is a rack, a file is an atom (a square), albums and bunches drawn as the racks they are.  Several **scrolly panes**
   side by side (A's racks, B's racks, a destination), and **vector lines between panes** draw the webbing — *sameness* (this B
    file is that A file) and *movement* (this went from there to here).  **Stuffing's fold comes later** (a folder of 400 alike
     files reading as one row until attended), and so does the floaty landscape on the glass (Voro/Vyto) — square shape first.

**Listening is the instrument.**  You walk the pile by ear: a track plays (the radio and the pool exist), and while it plays you dial
 in where it goes.  The Heist setup shows *what is already where it's going* — the destination's reality, not a form.

**The typewriter.**  Language as an artform, in a space made for music.  A text input that knows what is playing and what is attended,
 so what you type becomes a `Mag**` — a magazine page, a review, a list, a path through the pile — written **here or there**: directly
  into the filesystem (a real folder, a real file), or **superimposed** (an overlay, like `OpfsOverlayNav`, that leaves the pile
   untouched), and **shared** (a Mag crosses the wire already).

**Cave systems across Mags.**  A Mag can point into other Mags, yours or a friend's, so passages run between them — the code cave's
 shape (VytoSpine: head, rope, passage, torch) turned on music.  Presented as a magazine: you scroll it, it reads.

**The workflow over sessions.**  A merge of a giant folder takes days.  Every decision is a row (state lives in particles, never in
 `.c` or localStorage — memory "state-home discipline"), so a session picks up where the last left it, and the mechanical part (move
  these 300 into there) is proposed as rows and carried out as Jobs, each one undoable until done.

---

## 4. Rungs — a Book per rung

| rung | what | Book proves |
|---|---|---|
| 1 | **The listing as a Mag, as squares**: `Ground/Pile` (hand toc; `Main:Pile`); a directory listing streamed into `Mag**` on an A under a Seem (a fixture tree in the wormhole first, then a real FSA handle); a Stuffica-era view of plain squares in a scrolly pane | the Mag rows of a fixture tree; the walk is arrivals (one `%Job` per directory read), no timer; a file moved on disk, re-walked, is seen as a **move** (its point re-pairs) |
| 2 | **Two hemispheres, webbed**: B a second FSA handle streamed into its own Mag; two panes; "already in A" found and said as a relation row, drawn as a line between panes | relations minted for a fixture pair; nothing copied |
| 3 | **Listen and dial in**: play a B track, choose an A destination from A's own folders; a `%Move` proposal row | proposals; the destination's existing contents shown |
| 4 | **Carry out**: proposals become Jobs that really move (or copy) on disk, each undoable; resumable across reloads | a fixture move done, undone, resumed after a reload |
| 5 | **The typewriter**: text knowing the playing track makes a `Mag**` page — in the folder, superimposed, or shared | a Mag written all three ways |
| 6 | **Caves across Mags**: pointers between Mags, a friend's included; the magazine scroll | a passage walked between two Mags |

`/Desk?I=…&G=Pile` is the page once rung 1 lands; until then the Books run on the runner.

---

## 5. Open — ask the owner when a rung needs it

- What does a Seem pair a file's point on, so a move is noticed: its **name** (survives a move, breaks on rename), its
   **content hash** (survives both, costs a read of every file), or size+name as a cheap first guess confirmed by hash?
- Is B's merge a **move** or a **copy** by default, and where does an undone move go?
- The remote mount: is B usually another FSA in the same browser, or a friend's/daemon's pile over the wire?
- Do the user's categories live only in folder names, or also in tags inside files?
- The typewriter's Mag: a new kind of page beside `%Mag:heard`, or a Mag of its own named by the writer?
- What does "superimposed" persist as — an overlay folder in `.jamsend/`, or a Mag that names paths?

---

## 6. Rules the builder keeps (from CLAUDE.md and the owner's standing constraints)

Never stage/commit/push; never `npm install`; compile every `.g` you touch before the turn ends (`GFILES=… vitest … LocalGen.spec.ts`)
 and esbuild-parse the `.go`; a new Book's toc gets `Stands:<Ground>` and a hand-edited Credence row; record fixtures only from the live
  runner (`runner_ask accept`, after reading `snap <n>`); any change to Housing or Stuff gets a ledger row in `Atheory_design.md` §2;
   never edit `src/lib/L/everything.js` while a tab is up; don't self-promote this doc to `_spec`.
