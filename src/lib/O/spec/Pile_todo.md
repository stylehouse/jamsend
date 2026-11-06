# Pile — the showroom for Atheory: a music pile you walk, listen through, and write over

**Status: a todo, born 2026-11-03** from the owner's words (§1).  It is the brief for the agent who builds it: §0 says what to do
 next, §2 is the Atheory intro a newcomer needs first, §3 is the shape, §4 the rungs.  It is `AtheoryNexus_todo.md` §0.0 frontier
  **G**, the first app built on the new fabric — and `?G=Pile` is how a tab will stand on it (frontier E, built: `/Desk?I=…&G=Runner`).

---

## 0. What to get on with next

### 0.0 Where rung 1 stands (2026-11-05)

**Built, Book-proven: the tree, its identity, partitions, the three Mags, and their storage.**
- **The fs Mag is the directory tree** (§3 "Treeing, overflow, cursors"): `Dir` holds its `Dir`s and `File`s.  Each `Dir`
   carries `v`, a digest of what it holds (names, file sizes, sub-`Dir` `v`s); an empty one has none.
- **Identity rides on the rows (owner: a Seem is never kept beside the data).**  Each row carries an `id` minted once.  A walk
   reads the disk into a plain tree first (`Pile_disk`), then for each directory springs up a pairing (`TheA_pair`) between
    its listing and the rows it held.  Paired rows keep their id; a renamed file pairs by `ms`, a renamed `Dir` by `v`.
     What nothing paired is matched across the whole walk by the same keys (a move; a moved `Dir` brings its insides' ids);
      the rest get new ids.  No `TheASeem` in Pile any more.
- **Overflow anywhere**: a container (fs Mag or `Dir`) over `most` rows (fs Mag's `most`, 900; the Book uses 4) holds
   partitions `Mag:A-G`, then `Mag:A-G (2)` when full.  A row stays in its partition while its name is in range, newcomers
    fill the first partition with room, so a full one is never reshuffled or rewritten.  Each partition is its own file at
     `Pile/<fs Mag>/<range>` (top) or `Pile/<fs Mag>/<Dir id>/<range>`: by id, so a renamed `Dir` keeps its files.
- **Three Mags**: `w:Pile/Mag:Pile` holds `Mag:<folder>,side:A`, `Mag:Trail`, `%Ask:fsa,side:B` (unanswered yet).  Its file is
   only reference lines (mainkey + words, never numbers), so it is written once.
- **Storage reflex `Ghost/A/Store.g`**: `%TheAStore:<path>` marks a stored particle; `Store_settle(w, nav)` writes each whose
   text digest changed (`%TheAStoring` pending / with `why`; `%TheAStored:<path>,writes` ledger on w); `Store_open` reads and
    fills reference lines from their files (numbers too), recording what it read so an unchanged Mag isn't rewritten.
     `Store_memory_nav()` for Books; Pile uses `Pile_settle(w)` (nav on `w.c.nav`) and `Pile_open(H, name, nav)`.
- **Book `PileWalk`** — 8 steps, 13 oaths, 3/3 green in check mode: the tree with ids; three Mags + partitions + a serial one;
   each Mag in its own file; rename, move, `Dir` rename across ranges (insides come along) keep ids; untouched Mags written once;
    reload from files keeps every id and move with nothing noticed or rewritten; a rename after the reload keeps its id; three
     newcomers into a full partition fill `(2)` and spill into `(3)` without touching the full one.
- **Floor change**: a Book's `Stands:` takes a lone `.g` (`src/lib/A/ground.ts`).  `Cred_book_code` (Auto) still digests
   Grounds only — lone files aren't in a Book's Credence code digest yet.

- **The page, `/Desk?I=<who>&G=Pile`** (built 2026-11-04, owner-untested): `wormhole/Ground/Pile/toc.snap` (`Load:` Store.g,
   Pile.g, PilePage.g; `Main:Pile`; `Role:pile`).  Auto: a Ground page with no machine role is page `ground` (no Library), and
    `auto_ground` now loads Core plus the Ground's `Load:` files before standing the Mains (Runner Desk re-checked live: still stands
     `A:Runner`).  `Ghost/P/PilePage.g` is `Pile(A,w)`: registers `src/lib/O/ui/PileFace.svelte`, stores through the page's
      Wormhole nav under `.jamsend/pile/<who>/` (App_todo §0.5: a person's app data lives in `.jamsend/`), opens what's stored, walks a side when asked.  The face: "add a
       folder" answers `%Ask:fsa` (showDirectoryPicker, read-only), the handle kept in the House's Dexie `Handle` table as
        `Pile:<who>:<side>`, "open X again" re-grants after a reload, racks (`Dir`) of squares (`File`) per side, "look again".
         **Book `PilePage`** (3 steps, 2 oaths) drives `Pile(A,w)` with a fake directory handle (so `Pile_fsa_lister` is exercised)
          and a memory nav: grant → walk → stored; reload → the pile is there before re-grant → re-granted walk notices nothing.
           PilePage + PileWalk 3/3 green interleaved on one tab.
- **Where the page reads its wormhole**: a role-less page uses the folder share remembered for Mundo, else the GitHub-seeded OPFS
   cloud — which only has *committed and pushed* files, so `Ground/Pile`'s toc must be pushed before a share-less browser finds it.
- **Dispatch by name**: a runner that has loaded PilePage.g thinks any `w:Pile` as the page, so Books stand theirs as `w:PileW` /
   `w:PileP`.

- **Listening and taste** (built 2026-11-05, owner-untested).  A click on a square plays it, read off the disk through the
   lister's `file(path)`, and at the end of a track the next one plays.  The `Dir` holding what plays lights up and opens into
    a list of its tracks, scrolled into view (click a `Dir`'s name to open or close one).  ♥ on a track writes
     `%Like:<name>,of:<id>,side`; 👎 on a `Dir` writes `%Dislike`.  Both live in `%Mag:Taste`, stored at `Pile/Taste`:
      referring rows by id, never stamped on the fs rows.  Both are toggles, as Radio's heart is.  A disliked `Dir` keeps its
       liked tracks as `%Spare,of` rows under the `%Dislike`, a trace recomputed each turn; "next" skips a disliked `Dir`'s
        tracks but not its spares.  `%Playing` sits on w and is never stored.  Categories are `Dir`s named `0 <name>` (Heist's
         shelf marker, `Pile_category`); the face draws them purple, without the `0 `.  "add a folder" shrinks to a line under
          the panes once A and B are open.
- **The page's turn is a Sunpit** (`Pile_pit`): `%TheASunpit:turn` on w holds `%TheAPass:Press`, `%TheAPass:Want` and
   `%TheAPass:Dislike,in:Taste`, and `Pile_turn` runs `Pile_pass_<Kind>` over each kind's rows in that order.  The face only
    stands `%Press:<how>,side,of` rows through the Stuffica door (play, next, stop, like, dislike, look).  A grant or a "look
     again" stands `%Want:walk,side`, which waits until the side has a lister.  Nothing turned means nothing to settle.
      **Book `PilePage`** now has 5 steps and 6 oaths.  Steps 4–5: a like and a dislike in one turn spare the track; next skips
       the disliked album's rest; `0 chill` is a category; after a reload the taste is back with its spares and nothing plays.
        PilePage + PileWalk are 3/3 green interleaved on one tab.
- **What building this asked of the Sunpit** (for `AtheoryNexus_todo.md` §3.8, the `%J` / Sunpit design):
  1. **A pass must say where its rows are.**  Taste's rows live in a Mag under the home, not on w, so I added `in:`.  A real
      Sunpit wants an address (`@Taste/%Dislike`), which is §3.3's `S` read.
  2. **Dispatch by name is the whole runner.**  `this['Pile_pass_' + kind]` is ten lines every compartment would rewrite, so
      Theory should own it (`TheA_sunpit_turn(w, prefix)`), the same way `TheA_rows` already reads the pit.
  3. **Did anything happen?**  Each pass returns how much it changed so the page knows whether to settle and redraw.  That count
      is the `%TheATurn` Neu/Goner diff Theory already makes: a Sunpit run should leave one, and the settle should read it.
  4. **A pass whose rows are gestures** drops them as it goes, which is what an inbox does.  A gesture is a pulse, so `%Press`
      wants to be a `TheA_send` to the page's synapse, the face being one more sender; then the Stuffica door and the pulse
       boundary become the same thing.
  5. **A derived trace (`%Spare`) re-made every turn** is a Sunpit wanting a `watch`: it should wake only when a Like or a
      Dislike moved (coarse version, §5's "wake coarse, land fine").  Today it runs every turn that has any Dislike.
  6. **Order is a decision.**  Press before Dislike means a ♥ and the 👎 it softens land in one turn.  The pit makes that order
      readable in a snap.  That is its best feature, and the reason to keep pits as rows.

**Known limits:**
- A walk reads the whole disk before pairing (`v` needs the insides first); fine for now, but rung 2 (walk as Jobs) must stream.
   A `Dir` whose insides changed AND was moved loses its id (its insides keep theirs, each noticed as a move).
- An emptied partition stays; a `Dir` that shrinks back under `most` stays partitioned.  A moved `Dir`'s partitions are rebuilt
   at the same id path (rewritten, not orphaned).
- Two files with the same `ms` are matched first-come (sabotage still unrun).
- Cursors (`%Cursor`, `%Passed:<id>,v` on the Trail) are designed (§3) but not built.

**Still owed for rung 1, in order:**
1. **The owner opens the page** in Chrome on :9091 (`/Desk?I=<pub>&G=Pile`), picks a music folder, reloads, re-grants.  Then: the
    face's look (racks of squares is the plainest first cut), a stall-free walk for a big folder (see 3).
2. **Cursors**: `%Cursor:<name>,at:<id>` wandering the sorted tree, `%Passed:<id>,v` on the Trail, "snuck in behind" = a passed
    `Dir` whose `v` moved.
3. **The walk as Jobs**: each directory read a `%Job` arrival, dropped once served, so a giant folder fills as it lands; settle
    as the run's tail.
4. **The partial-hash confirm Job** (§5.1): today a pairing is trusted on `ms`/name/`v` alone.
5. **Sabotages still unrun**: two files with the same size+modified; an emptied directory renamed (no `v` — say so).
6. **The cull** — a Dislike's "default delete" (owner 2026-11-05): with readwrite permission and undoable Jobs, a disliked `Dir`
    goes, minus its `%Spare`s, which move somewhere kept, so a too-much album leaves one good track for the radio's diversity.
     Today it is only the plan, drawn (👎 keeps N).
7. **The intelligiser** (owner 2026-11-05, pushed back behind listening): an organ that slowly forms opinions about rows by id,
    kept in its own Mag, never on the fs rows.  It would guess the artist and album per `Dir` from names alone (`NN Artist -
     Title`, `Artist - Album (Year)`, a name repeated across siblings and parents), with confidence growing as the guesses
      agree; tags read from the files later, as Jobs; the face shows a guess as a label.
8. **Likes reaching the radio**: today `%Like` is the Pile's own.  Radio's heart is `take` on a Card in `%Mag:heard`
    (Heard.g); when the pile feeds the radio, the two should be one ledger, or one should name the other.

1. Read §2 (Atheory in one sitting) and `CLAUDE.md`; then `AtheoryNexus_todo.md` §0.0 (the land map) and its *E thought through*.
2. **Rung 1 — the listing as a Mag, drawn as squares** (§4): a `Ground/Pile` composition and a Book that streams a folder's
    listing (a fixture tree, then a real FSA handle) into a `Mag**` held under a Seem, and a new Stuffica-era view that draws it
     as plain squares in scrolly panes.  No Stuffing fold, no Waft, no typewriter yet — the basic square shape first (owner).
3. Every rung is a Book first (`Stands:<Ground>` in its toc, a Credence row), sworn with `story_swear`, run on the live runner.
4. Work out §5.1 yourself, proving each answer in a Book; ask the owner the §5.2 questions as they become load-bearing, not up front.

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

*2026-11-04, fourth:* "there's quite a bit of Seem to be noticing when inners remain the same and a rename happens, which we might have
 been the cause of anyway. yeah, managing and exploring the filesystem, should be kept in a log of the current session's activities,
  similar to Aside or Trail in the LiesLang system … so we can compute off that for what has|hasn't been seen|listened to. we'll be
   playing whole original tracks instead of making previews, probably... although the ability to jump around lots of unfamiliar music
    rapidly spliced together randomly would be a nice slow process we could enable in the background... I guess the process has some
     options like that, which switch on some UI tool which interacts with the Mag** substrate that way... so yeah our Mag:Trail (similar
      to Waft) would remember what we moved|renamed|listened-to, and Mag** would remember the moves|renames, and could one day be
       consulted as the source of chasable pointers if eg radiostock is still pointing the wrong place, although radiostock might be
        able to be updated if it too is indexed on Mag** so... bright future! keep things separate for now though, this all goes in the
         modern end of things as a free-standing but ?I using thing."

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

**The Mag\*\* of a Pile — three kinds, each stored on its own (owner, 2026-11-04).**  It all looks like `Mag**`, but there are three kinds:
- **`%Mag:Pile` — the enclosing one, all we're up to.**  Small, and the most stable thing there is.  It holds *references* to the
   others (one row per side naming its Mag, one naming the Trail), never their contents.  It is where the **add-another-FSA** control
    lives: a row asking for a handle, answered by a picker on the page.
- **One fs Mag per side — derived from the filesystem.**  The directory projected into being: `%Mag:<name>` for pile A, another for
   B.  Rebuilt from disk by walking; the Seem keeps its ids.
- **`%Mag:Trail` — the looser what-we-did one.**  Moments, by id.

**Each stored separately — by an Atheory-era storage reflex, not the Berth (owner, 2026-11-04).**  Radio ruled the naming
 (`Mag_todo.md` §1: `%Mag:<unique-name>` the way `%Waft:<path>` is, pages inside it, a durable Mag its own toc.snap).  It stored
  them through Heist.g's Berth, which is not elegant and is a radio ghost Pile mustn't call.  Pile gets a **separate prototype**
   instead, `Ghost/A/Store.g`, that the Berth might later learn from.

*Why storing C\*\* isn't trivial, and what dissolves each part:*
- **When to write**, without polling or timers.  Stuffica already answers this for views: after a run, digest what each one
   shows and commit only the ones that changed (Stuffica.g).  A stored Mag is the same: after the run, any stored Mag whose text
    digest differs from its last write gets **one write Job** (an arrival, decided from rows).
- **Big files grow slow**, which is why the Berth appends numbered parts and compacts them, and folds parts back by identity keys
   on open.  Partitioning makes all of that unnecessary: each partition Mag is its own **small** file, so a write is a whole-file
    rewrite (atomic on FSA close), and open is one read.  A nested stored Mag is written as **its reference line only** (folded,
     as `TheA_persist` folds `dontSnap`), so `%Mag:Pile` writes a handful of lines and each partition writes its own rows.
- **What must persist** is less than it looks.  An fs Mag's rows can be re-derived from disk at any time; what can't be is the
   **Seem's points with their id regards, and the `%Moved` history**.  That's the owner's "persisting parts of a Seem is a topic to
    come" (`Atheory_todo.md` §0.5) arriving: the stored file keeps the Trace tree; rows may be stored too as a cache, so a page
     can draw before the first walk.
- **Reading is an arrival** too: standing a stored Mag asks for its file; the reply thaws it (`TheA_thaw`) and its Seem
   carries on from the points it had.
- **One writer.**  One tab writes a stored Mag; the page claims it (`navigator.locks`, later).
- **Where**: the identity's app tree (a nav: `read_file`/`write_file`), `<app tree>/Pile/<mag name>/toc.snap`, never inside a
   music folder.  A Book gives it an in-memory nav.

*Its two ancestors, and why it calls neither (checked 2026-11-04).*  **LiesStore** (`src/lib/O/LiesStore.svelte`) is w:Lies'
 disk IO: one eternal `req:Store` pump, a req per write keyed by path + content digest (skipped when the `%Good`'s `/known` digest
  already matches the disk), reads landed on a `%Good` slot that wakes its `%subscribe`rs, and `writeCarefully`'s pull-before-push.
   The reflex keeps those ideas (known digest, skip an unchanged write, a read handed to whoever waits) but says them as Atheory rows
    and Jobs rather than req/maz/ttlilt, and doesn't call LiesStore: it lives on w:Lies, so using it would pull Lies into Ground/Pile.
     **The Berth** (Heist.g) is already deliberately LiesStore-free ("bound to the encoders only + the nav contract"); it holds Heist's
      own berths (`KeepMemo`, `Heists`, `HeistDefaults`).  **Neither is on the Mag replication path**: Repli carries a Mag over the
       wire (`Ra_offer_stock`) and touches no storage.  So the reflex gates nothing in Radio or production; the Berth can move onto
        it later, on its own schedule.  The design note is `Atheory_design.md` §1.15; its row in the old-machine ledger is
         `AtheoryNexus_todo.md` §1b.

*The prototype's rows*: `%TheAStore:<path>` on a Mag says it's stored and where; `.c` holds the last-written digest; a
 `%TheAStoring` Job per pending write, dropped once landed (or kept with `why` when it failed — never silent).

**Treeing, overflow, cursors (owner, 2026-11-04 evening — supersedes the flat rows and fixed ranges below).**
- **The Mag\*\* is the directory tree.**  `Dir` holds its `Dir`s and `File`s, as the disk does.  (Flat was a mistake: it
   guarded against the encoder's `max_child_depth`, which only cuts when a caller passes it — enWaft's default is unbounded.)  A
    directory renamed with the same insides then keeps its insides for free: they never moved.
- **Overflow, anywhere in the tree.**  A container (the fs Mag, or any `Dir`) over ~900 kids holds partition Mags instead —
   `Mag:A-G`, and when that fills, a serial `Mag:A-G (2)` — never reshuffling a full one, so a split rewrites nothing that
    was already stored.  Each partition is its own file; a small `Dir` is part of its parent's file.  This is the general fix
     for the ~6000-kids "giant stuff" ceiling: no container, rows or Seem points, ever gets near it.
- **Partitions are passed through** by identity: a row's place is the `Dir` above it, whatever partition holds it, so a
   rename that crosses a range moves the row between partitions and is still one rename.
- **Loosely content-versioned.**  Every `Dir` carries `v`, a digest of what it holds (today's `kids`, generalised: names,
   sizes, and each sub-`Dir`'s `v`), so a change anywhere shows in every `v` above it.
- **No Seem kept beside the data (owner).**  A Seem springs up, pairs, and leaves its traces ON the rows (the `id`, as a Dip is
   kept on a point) — it never holds a second copy of the tree.  Everything resumes from the rows.  (Built: Pile pairs per
    directory with `TheA_pair`; the earlier flat Seem with `TheARegard:pile,id` points is gone.)
- **Cursors.**  A cursor wanders the tree in its one sorted order and is a row (`%Cursor:<name>,at:<id>`, on the Trail).
   The Trail remembers each `Dir` the cursor passed and the `v` it had then (`%Passed:<id>,v`), dirs only, not files.
    **Snuck in behind** = a passed `Dir` whose `v` is no longer the one remembered; that is also "not seen since", so seen /
     unseen falls out of the same rows.

**Partitioned by name, as Mags in Mags (owner, 2026-11-04).**  `Mag**` is a freely partitionable `Mag/Mag/Mag/…/rows`, so
 nothing piles up in one place.  A wide layer splits by **name range**: `%Mag:<the FSA you loaded>/%Mag:A-G` is the first
  partition of a collection, made just by dividing the first character of the first layer's names (artist folders, usually); a
   partition still too big splits again (`A-G` → `A-B`, `C-D`, …, or by the next layer down), and so on.  Each partition is its
    own Mag and can be stored on its own (a berth per partition), so a page loads only the partitions it is looking at.
- **Partitioning is storage, not identity.**  Which partition a row sits in is decided by its name and how full things are; it
   says nothing about what the row *is*.  The id (minted once, carried by the Seem) and the row's place in the tree (`in:` its
    directory) are the identity.  So a rename that crosses a range boundary (`Abba` → `Zappa`) moves the row between partitions and
     is still one rename; a split or merge of partitions changes no id and notices nothing on the Trail.
- **The Seem pairs the logical tree, not the partitions.**  It walks every row of the fs Mag whatever partition holds it (a deep
   Seem, `%TheADeep`, over `Mag**`; rows with kinds File/Dir are the points, partition Mags are passed through), so a move or
    rename pairs exactly as in today's flat rung-1 shape.  If a whole collection's points are too many to hold at once, the walk
     goes partition by partition with `%TheALimbo` catching what crossed between them (Book `AthePondMoves`); limbo's key is kind +
      name today, so a moved-and-renamed file needs it to try `ms` too.
- **When to split** is a number (rows per partition, a few hundred) and a rule (first character, then the next, then the next
   layer); the rule lives in one method so it can change without touching identity.
- **No Waft, no Funkcion in this Ground.**  Funkcion (how Waft woke little UIs) is ~3k lines that are hard to say the point of.
   `Ground/Pile` stands on Core (Theory, Stuffica) and later Glass, never Lies/Waft/Funkcion.  Pile's UI is Svelte over Stuffica
    views; a control is a row on a Mag (the add-another-FSA ask), not a Funkcion.  Writing a Mag to disk needs only the encoder
     (`Text.svelte` `enWaft`), which is foundation, not the Waft editor.

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

**Listening is the instrument.**  You walk the pile by ear: a **whole original track** plays straight off the FSA handle (no
 radiostock, no preview encode — Pile is not the radio), and while it plays you dial in where it goes.  **Later, an option:** a slow
  background process that splices many unfamiliar tracks together at random so you can jump around a big strange pile fast.  A process
   option like that switches on its own UI tool over the same `Mag**` substrate; it is not a mode of the core view.  The Heist setup shows *what is already where it's going* — the destination's reality, not a form.

**The typewriter.**  Language as an artform, in a space made for music.  A text input that knows what is playing and what is attended,
 so what you type becomes a `Mag**` — a magazine page, a review, a list, a path through the pile — written **here or there**: directly
  into the filesystem (a real folder, a real file), or **superimposed** (an overlay, like `OpfsOverlayNav`, that leaves the pile
   untouched), and **shared** (a Mag crosses the wire already).

**Cave systems across Mags.**  A Mag can point into other Mags, yours or a friend's, so passages run between them — the code cave's
 shape (VytoSpine: head, rope, passage, torch) turned on music.  Presented as a magazine: you scroll it, it reads.

**Two memories, kept apart.**
- **`Mag**` remembers the filesystem**, including its own history: the moves and renames its Seem noticed.  A directory renamed with
   its insides unchanged is a rename, not a vanish plus an arrival, so the Seem pairs directories by their contents as well as by name.
- **`Mag:Trail` remembers the session**: what *we* explored, moved, renamed and listened to, one moment per act.  It is the Pile's
   Aside/Trail (`Interest.md`), so "seen / not seen / heard / not heard" is computed off it, never stamped onto the pile's rows.  Build it
    in the flat shape the Aside was ruled into but never reached (`Lagoon_todo.md` leg 3 ruling, `Clerkdesk_todo.md` §0): a moment
     carries **`about`** (what you went in there for) and **where you came from**, and its points are **referring** particles naming
      a `Mag**` row by id, never a copy of it.  The `about` is what the Aside lineage proved worth keeping: the research perspective,
       why you went somewhere, not just where.
- **The join is cause.**  When the Seem notices a move or rename, the Trail says whether **we** did it (a Job we carried out, predicted
   before the walk) or the world did (no Trail moment explains it).  Ours is quiet confirmation; the world's is news.
- **One day, not now:** `Mag**`'s move history becomes the source of chasable pointers for anything still naming an old path
   (radiostock, a Card, a friend's Mag), or radiostock itself is indexed on `Mag**` and moves with it.  **Keep it separate now.**  Pile
    calls nothing in `Ghost/M`'s radio, pool or heard ghosts, and nothing there reads Pile.

**Free-standing, but with an identity.**  Pile lives at the modern end (Atheory, Grounds, the Desk), stands on its own Ground, and
 uses `?I` only for *who*: whose stash keeps the FSA handles, the `Mag**` and the `Mag:Trail`.  That isn't much complication.
  `/Desk?I=…&G=Runner` already does exactly this, and FSA handle persistence with the permission re-ask already exists in
   `Housing.svelte.ts` (~:2480, `queryPermission` → `requestPermission`).

**Beside the radio tab, same `?I` (checked 2026-11-04).**  Pile on `/Desk?I=X&G=Pile` and the music page on `/?I=X` at once is
 fine, on three conditions.  (There's no `G=Radio` yet: the music app is still `/` on Auto until it's ported to a Ground.)
- **No second station door.**  The relay delivers a frame addressed to a prepub to every socket that dialled `?addr=<prepub>`
   (`relay.ts` `deliverLocal`).  Two such sockets means every music chunk arrives twice, in both tabs.  Pile stands on no Swarm/Wire
    Ground, so it never dials one: its Lies channel is a role socket, which never owns the door.  If Pile ever needs the wire (sharing
     a Mag), it must not open its own station for X.
- **Its own stash row.**  The House stash is one Dexie row per House **name**, shared by every tab of the origin, and a liveQuery
   replaces the whole blob on any change (`Housing.svelte.ts` ~:636).  So two tabs saving the same House name are last-writer-wins
    on the whole thing.  Keep Pile's `Mag**` and `Mag:Trail` in a House named for Pile and the identity (`Pile:<prepub>`), never in
     Mundo's row.  One Pile tab per identity: a second would race the first on that row (a `navigator.locks` claim, later).
- **The radio sees Pile's moves as the world's.**  Both tabs can hold a handle on the same music folder.  A Pile move is, to the
   radio tab, a file that vanished; radiostock still names the old path.  That's the "chasable pointers, one day" join above.  For
    now, check what the Stoker does with a vanished path before rung 4 moves real files.

**The workflow over sessions.**  A merge of a giant folder takes days.  Every decision is a row (state lives in particles, never in
 `.c` or localStorage — memory "state-home discipline"), so a session picks up where the last left it, and the mechanical part (move
  these 300 into there) is proposed as rows and carried out as Jobs, each one undoable until done.

---

## 4. Rungs — a Book per rung

| rung | what | Book proves |
|---|---|---|
| 1 | **The listing as a Mag, as squares** (and the first `Mag:Trail` moment for each walk): `Ground/Pile` (hand toc; `Main:Pile`); a directory listing streamed into `Mag**` on an A under a Seem (a fixture tree in the wormhole first, then a real FSA handle); a Stuffica-era view of plain squares in a scrolly pane | the Mag rows of a fixture tree; the walk is arrivals (one `%Job` per directory read), no timer; a file moved on disk, re-walked, is seen as a **move** (its point re-pairs) |
| 2 | **Two hemispheres, webbed**: B a second FSA handle streamed into its own Mag; two panes; "already in A" found and said as a relation row, drawn as a line between panes | relations minted for a fixture pair; nothing copied |
| 3 | **Listen and dial in**: play a B track, choose an A destination from A's own folders; a `%Move` proposal row | proposals; the destination's existing contents shown |
| 4 | **Carry out**: proposals become Jobs that really move (or copy) on disk, each undoable; resumable across reloads | a fixture move done, undone, resumed after a reload |
| 5 | **The typewriter**: text knowing the playing track makes a `Mag**` page — in the folder, superimposed, or shared | a Mag written all three ways |
| 6 | **Caves across Mags**: pointers between Mags, a friend's included; the magazine scroll | a passage walked between two Mags |

`/Desk?I=…&G=Pile` is the page once rung 1 lands; until then the Books run on the runner.

---

## 5. Open

### 5.1 For the builder to figure out (not the owner's calls)

*Folded in 2026-11-04 from the Atheory/E session's advice; the first two are the ones that fail silently.*

- **⚠ A new Ground loads nothing in a Book yet.**  Story's loader reads only baked Grounds (`grounds.gen.js`) and ones
   `auto_ground` learned; a hand-kept `wormhole/Ground/Pile/toc.snap` is invisible to it (owed in `AtheoryNexus_todo.md` E).
    Until then a Pile Book's toc says `Stands:<a baked Ground>` and lists its lone `.g` files.  No `Stands:` at all = a HOLLOW run
     (no `req:wrangle`, 0 sworn) that looks green.  Every new Book also gets its hand-kept Credence row.
- **⚠ Keep `Mag**` flat** (§3): one row per entry, `in:<parent id>`.  Deep nesting is cut by `max_child_depth` with no error.
   Books use small fixture piles.
- **The id is not the path** (§3).  Trail moments refer by that id under their own mainkey (`of:<id>`), never copying the row.
   Path-as-key turns every rename into a vanish plus an arrival and loses the history.
- **File pairing, cheap then sure.**  In the walk: name + size + `lastModified` (a move usually keeps lastModified).  Confirm with a
   partial hash (size + first/last 64KB) in a **background Job** — never an await on the walk's hot path (it flakes Books).  Only a
    confirmed pair becomes a rename/move.
- **Directory pairing by contents**: the overlap of children's name+size sets, above a threshold.  An empty directory can't pair —
   say so, don't guess.  Prove both with a sabotage in the Book: rename a fixture directory, re-walk, see one rename.
- **Ours vs the world's, in two phases.**  A Job writes its **intent** before touching disk and its **outcome** after.  A crash
   between leaves an intent with no outcome; the next walk settles it: a match → ours, done; no match → "attempted", shown as such.
    An unexplained change is the world's, and is news.
- **A stale path is history.**  A Trail moment naming a path that has since moved renders as a visit, never as a broken link and
   never silently repaired (`Clerkdesk_todo.md` §0).  Resolve it through `Mag**`'s move history when the history has it.
- **No wall clock in `.sc`.**  Order Trail moments by a counter; time goes on the clock/tape (`TheA_io`) or raw on `.c`.  Never
   stamp a maybe-undefined sc value (`{"undef":…}`); booleans are `1` or absent.
- **Big directories stream** as paging `%Job`s, and the Mag fills as they land; never enumerate a giant folder before drawing
   (`Wander_todo.md`).  **Drop each paging Job once served** (`host.drop`) or a big walk leaves thousands of finished rows.
- **A Book can't pick a folder** (no gesture, no `showDirectoryPicker` on a runner): drive a fixture pile through a nav.  A rename
   or move must exist in all three nav layers (`MountNav` → `WormholeNav` + `OpfsOverlayNav`) or the sabotage can't run.
- **Reloads lose the permission.**  A remembered FSA handle needs a click to be re-granted (`Housing.svelte.ts` ~:2480; the same
   thing reds MusuRadio on a reloaded runner).  The page's arrival treats "re-grant pile A / B" as an expected step, a row the Ground
    declares (`AtheoryArrive_todo.md`).
- **Where the Mags persist**: each its own toc.snap through the storage reflex in the identity's app tree (§3 "Each stored separately"), never inside either music
   pile.  Writing into the user's music folders is a rung-4 act, done by a Job, never bookkeeping.
- **Play originals with plain `<audio>`** over `URL.createObjectURL(file)`, revoked when done — no radio ghost.  Some codecs won't
   play; a refusal is a row, not silence.
- **Seen/heard is a query**, not a stamp: a function over `Mag:Trail`.
- **The usual footguns**: never read `o()` right after a bare `r()` (async replace); a presence wildcard `o({k:1})` matches more
   than you meant — filter on mainkey.

### 5.2 Ask the owner when a rung needs it

- Is B's merge a **move** or a **copy** by default, and where does an undone move go?
- ~~Is B another FSA or a pile over the wire?~~ Answered 2026-11-03: another FSA handle.  A friend's or the daemon's pile over the wire is later.
- Do the user's categories live only in folder names, or also in tags inside files?
- The typewriter's Mag: a new kind of page beside `%Mag:heard`, or a Mag of its own named by the writer?
- What does "superimposed" persist as — an overlay folder in `.jamsend/`, or a Mag that names paths?

---

## 6. Rules the builder keeps (from CLAUDE.md and the owner's standing constraints)

Never stage/commit/push; never `npm install`; compile every `.g` you touch before the turn ends (`GFILES=… vitest … LocalGen.spec.ts`)
 and esbuild-parse the `.go`; a new Book's toc gets `Stands:<Ground>` and a hand-edited Credence row; record fixtures only from the live
  runner (`runner_ask accept`, after reading `snap <n>`); any change to Housing or Stuff gets a ledger row in `Atheory_design.md` §2;
   never edit `src/lib/L/everything.js` while a tab is up; don't self-promote this doc to `_spec`.
