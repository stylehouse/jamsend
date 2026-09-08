# Lagoon_todo.md — the code-wandering environment: the reader layer over Atlas

**`Lagoon` is a working title, the owner's, 2026-09-08.**  It replaced `Legend` on sight, and it is the
 better image: a lagoon is shallow enclosed water where structures *erupt* — reefs, atolls, things that
  surface and then get arranged around the place.  Which is the owner's own description of what happens
   here: *"little structures erupt when we go climbing call trees… they might be arranged around the
    place."*  The name carries the behaviour, not the mechanism.

Home of: the **reader layer** (every answer asked of a census, in one place) and the **wandering
 environment** built on it.  Its substrate is `Atlas` (`Wordland_todo §1.1`, `Stemdex_todo §0`); its
  surface is the BigWordland room (`Wordland_todo §5`); the execution map that lands on it later is
   `Electrode_todo`.

## 0. What to get on with next

### ⛵ THE COURSE — plotted 2026-09-08 evening, the owner: *"I want allll these things. heaps."*

**This is the handover.**  The owner is compacting and switching sessions to execute; everything a fresh
 session needs to NOT re-derive is here.  Destination first, then the bombs, then the legs in dependency
  order.  Each leg says what it needs from the one before, so nothing is started out of order and nothing
   waits on a decision that has already been made.

**Destination, in one sentence:** a code-wandering tab where you SEEK (families → methods → callers →
 prose) and every seek LANDS in a Langui, the landing is RECORDED as a trail, code shows as a BEADCHAIN
  rather than a screed, what a run TOUCHED is shaded onto it, doc rot arrives as WORK to do, and a
   document can ASK Claude a question in place — all of it over Atlas (what the code says), read through
    Lagoon (every answer), with Electrode (what it does) as a layer that lands on it later.

#### The bombs — read before touching anything

1. **Two runner-ish tabs exist and unpinned `runner_ask` lands on whichever acks first.**  This is how
    Atlas ended up on the owner's editor tab hogging the beliefs mutex.  **Always `--runner=<id>`** for
     anything that stands a world.  Their tab today: `e747cbed6a9ca919`.
2. **`AtlasStaple` and `LagoonStaple` re-aim `A:Atlas` at `Ghost/L/test_corpus` (ONE doc) and never put
    it back.**  After any Book run the face honestly shows three methods.  Re-stand:
     `ghost_load Ghost/L/Atlas.g --stand=Atlas --fresh --runner=<id>` (~75s to 715/715).
3. **Writing a gen `.go` while a tab is up can wedge Story at `begun/n:null` with NO console output.**
    `--swap` did not clear it.  `runner_ask reload` then re-stand the land is the reliable heal.  A Book
     recording after a recompile: compile → reload → re-stand → run.
4. **There is exactly ONE editor and Lies enforces it twice** (`LiesFunk` ~:499 the Cluster claim
    supersedes every other editor row; `Lies_aim_setup` gates on `=== 'editor'`).  **Never open a second
     editor-role tab**; it evicts the owner.  This is why leg 1 exists.
5. **`point` in `Lies_ghost_pick` is a STRING** — a def name, or `text:<words>`.  An object in `sc` brands
    every recorded Point junk.  Today's `wormhole/Aside/2026-09-08` carries a dozen such rows from before
     the fix; they are the owner's to prune.
6. **A report row writes ONLY ON CHANGE; a face asks ON A LEASH.**  Both halves of the tailspin.  A
    `$derived` off a census world's `version` re-runs on every mapped doc.
7. **For any Book against a ghost that LOOKS ITS SUBJECT UP:** stand where the reader looks
    (`top_House()`); gate claims on a snapped marker from an `expecting` beat, never on a flag a sync beat
     set; drive the passes, don't wait for a tick.  Four recordings paid for those.
8. **`compile.ts` carries two NUL bytes** — plain `grep` finds nothing in it; use `grep -a`.
9. **`LagoonStaple` flakes ~2 in 11**, both times in the run immediately after a fresh Atlas stand.  Not a
    clean gate yet; if it flakes on a QUIET tab that is a new bug.
10. **Atlas keeps; Lagoon asks.**  The test for any new feature: *does it change what is HELD, or ask a
     question OF what is held?*  Lagoon must never start keeping — `LagoonStaple` reds if it does.

#### The legs, in order

### ✅ LEG 1 IS BUILT — 2026-09-08 evening.  **`/Otro?H=Hackarium`**

`role:hacker` landed, and the audit below turned out to OVERSTATE the work: of the ~7 gates it listed as
 capabilities, **four were duties** (`Lies_send_rungo`, `Lies_drain_rungo`, `Lies_send_gen_write`,
  `Lies_ledger_broadcast` — all relay/dispatch, all correctly skipped) and **two more are Keep WRITES**
   (`Lies.svelte:1013/1018`) which stay editor-only because the Keep is single-writer and a hacker's
    own where-was-I belongs in its trail.  **Exactly one gate was re-pointed**: `Lies.svelte:233`, the
     cursor RESUME, which is a read.  What landed:
- `Lies_role` returns `'editor' | 'runner' | 'hacker'`; `w.sc.hacker` is its flag.  New
   `Lies_has_docks()` (editor ‖ hacker) for capabilities, `Lies_is_editor()` untouched for duties.
- `Otro`: `?H=<Book>` → `boot_role:'editor'` (so world layout and disk gating are inherited unchanged)
   plus `h.c.role = 'hacker'`, which every duty gate misses because they all test equality.
- `src/lib/L/Hackarium.svelte` — the recipe.  Lays `w:Lies,hacker:1` and a flagless `w:Lang`, and **no
   Pantheate** (it mounts compile-run artifacts; a hacker does not compile).  **It stands Atlas and
    Lagoon ITSELF** — fire-and-forget `Lies_ghost_set`, never awaited from the do_fn (Atlantation beat
     2's circular-wait lesson) — so the tab comes up whole with no CLI, no relay and no editor.
- Mounted in `O/Ghost.svelte`; minimal `wormhole/Story/Hackarium/toc.snap` seeded.

**Three properties confirmed by reading the code, and they are what make it safe:**
1. **No channel at all.**  `Lies_channel_up` returns bare for any role that is not editor|runner|armed-
    player, `Lies_transport_up` is `!== 'editor'` → return, and `Lies.svelte:754` gates
     transport/channel/heartbeat the same way.  A hacker cannot collide with the editor because it never
      speaks to the relay.
2. **The spine still loads.**  `Creduler_ensure` is gated on `w.sc.creduler`, not on role, and Auto
    stamps that regardless — so a hacker gets all 36 ghosts.
3. **Not a humdinger** (that stamp comes from `boot_qualand`, which Otro does not use), so nothing is
    refused on it and `ghost_load` remains available if ever wanted.

**Verified:** all five touched components svelte-compile clean; `/Otro?H=Hackarium` SSRs 200 with 390KB;
 **the owner opened it, clicked a stem, and it landed** ("lovely").
**✅ GATED — `scripts/HackerRole.spec.ts`, 9/9, no runner and no browser.**  The safety claim is a PURE
 FUNCTION OF ROLE, so it did not need a Book: every duty in the spine is an equality test against
  `'editor'`, and one assertion that a hacker is not the editor therefore covers all seven of them at
   once.  The spec also pins the no-channel path, that the write gates stayed editor-only while the
    cursor RESUME became shared, that Creduler is gated on the flag rather than the role (so a hacker
     still gets its ghosts), and that both rooms boot it without taking the editor slot.  Test 1 asserts
      the source of `Lies_role` still matches the copy the tests reason over, so the gate cannot rot into
       agreement with itself.
**Still owed (browser-only):** that docks and Langui appear, and that a working editor elsewhere KEEPS
 its Cluster row while a hacker tab is open.  The logic is gated; the lived behaviour is not.

---

**LEG 1 — `role:hacker`.  Everything visual waits on this.**  *(the plan as written, kept for the audit)*  (Ruled by the owner: *"role:hacker for
 now?"* — yes.)  A tab that has the editor's LOCAL capabilities (A:Lang, Langui, docks, FSA read) and
  none of its SINGULAR duties (Cluster claim, %Aim, relay editor socket, Waft saves).  The audit in §2.7
   is complete; the build is:
- `BigQualand`/Otro: a new boot param (suggest `?H=<Book>`, mirroring `?E=`/`?B=`) → `boot_role: 'editor'`
   (machine stays two-valued, so worlds and disk gating are inherited) + `H.c.role = 'hacker'`.
- `Lies_role` type widened to `'editor' | 'runner' | 'hacker'`.  Every DUTY gate is `=== 'editor'` and
   opts out for free — do not touch them.
- New predicate `Lies_has_docks(w)` = editor || hacker.  Re-point the ~7 CAPABILITY gates
   (`Lies.svelte:233/1013/1018`, `LiesLies:573/606/650/970`).  Leave the 3 WRITE gates
    (`Lies.svelte:833`, `LangCompiling:274`, `LiesCortex:155`) editor-only: **a hacker reads**.
- A `Hackarium` Book recipe beside `Educarium` (`src/lib/L/`): lays `A:Lies editor:1`, `A:Lang editor:1`,
   then `Lies_ghost_set` Atlas + Lagoon and stands them ITSELF — so the hacker tab needs no `runner_ask`,
    no `ghost_load`, and no relay to come up.  Self-contained.
- **The one unknown, RESOLVED (checked 2026-09-08 evening): a hacker stays OFF the relay by
   construction, no code needed.**  `Lies_channel_up` (`LiesLies.svelte:306`) reads
    `if (role !== 'editor' && role !== 'runner' && !player) return   // bare: no channel`, and its caller
     (`Lies.svelte:754`) gates on `is_editor || is_runner || player_seen` before standing transport,
      channel or heartbeat.  A `'hacker'` matches none of those, so the six `peer = …` sites never run for
       it — there is no channel for them to run in.  That is exactly the v1 wanted: a self-contained
        local tab that cannot evict the editor because it never speaks to the relay at all.  (Later, if a
         hacker wants `runner_ask` reachability, it joins as `player`-style READ-ONLY — the door
          `Lies_player_seen` already opens — never as an editor.)
- Gate: a Book (`Hackation.g` → `HackStaple`?) swearing: the tab has docks; `Lies_role` is `hacker`;
   `Lies_aim_setup` did nothing; no `%HostedIdentity,role:editor` row was claimed.  The last is the one
    that protects the owner.

### ✅ LEG 2 IS DONE, AND THE ROOM ABSORBED THE TAB — 2026-09-08 evening

The owner opened `/Otro?H=Hackarium`, clicked a stem, and it landed: *"lovely"*.  Then: *"it needs a
 fullscreen-er presentation… BigWordland was it I think?  nothing else is happening with BW, we should
  probably take this all there… they are very similar right?  unity a cleanse."*

**They are the same thing wearing different clothes** — both boot a Book and render `H.UIs`.  What the
 room has that the tab lacks is PRESENTATION: the H\*\* switcher that makes one House fullscreen, the ▦
  sprawl, the pin rail, the searchbar.  So the room took the Book, rather than the Book growing a room.

- `/BigWordland` now defaults to **Book `Hackarium`, role `hacker`** (was `Educarium`, role `word`).
   `?H=<Book>` overrides.  A `hacker` badge sits beside the room's name so it is visible that this tab
    does not hold the editor slot.
- `boot_qualand` gained `'hacker'` as a fifth role: it maps to the `editor` boot_role like `word` does
   (so world layout and disk gating are inherited unchanged) and additionally stamps `H.c.role`.  It is
    still stamped `humdinger` — a room is never a dispatch target — and that costs nothing now, because
     **Hackarium stands Atlas and Lagoon ITSELF** rather than waiting for a `ghost_load` that a humdinger
      would refuse.  That refusal is exactly what kept the L ghosts out of this room until today.
- `?E=<Book>` still boots the old editor room for anyone who explicitly asks, with the eviction warning
   written at the call site.

**Verified:** `BigWordland` and `BigQualand` compile; `/BigWordland` serves 200 with 392KB of SSR.
 **Owed:** the same browser check as leg 1, plus confirming the switcher opens on the Hackarium Run.

**LEG 2 — the seek lands.**  *(the plan as written)*  Needs leg 1.  On a hacker tab the tab's own Liesui/Langui exists, so
 `Lies_ghost_pick` lands without any change to Lagui.  Verify by clicking a family → method → the editor
  moves.  Only if the owner wants the CodeMirror INSIDE the panel does Lagui mount its own `<Langui {H}/>`
   — and then it is the ONLY Langui on that tab, so the multi-editor bookmark/autosave races do not arise.

**LEG 3 — the trail.**  Needs leg 2 (points must land to be worth recording).  The Aside already IS the
 trail (`What` per moment → `Doc` → `Point`), and bomb 5 is fixed so Points are real now.  Build the
  trail VIEW first: today's Aside rendered as a chain in the hacker tab — that is the recipe's *linear
   stretch* (§1) and the beadchain's first instance at once.  Then enrich a Point at record time with
    what was looked at (the def, its family, its caller count) so the trail teaches.  The owner:
     *"you could probably loop for a long time making something that just records someone's trail
      through the code."*  This is the leg to loop on.

> **Leg 3 RULING, the owner, last thing before compacting (2026-09-08 evening):** *"it seems weird to
>  have What/Doc/Point now, perhaps What/Point with a Doc pointer as part of it… above the Map-like object
>   and lines… just having a context the Point is going for."*  **This is the identity law applied to the
>    trail, and the current shape breaks it.**  Today's Aside mints a `Doc:<path>` particle inside every
>     `What` — but the Doc is a HOLDING in Atlas (`w:Atlas/Doc:<path>`), so the Aside's copy is the second
>      shape under one mainkey, the exact tell CLAUDE.md names.  A trail Point is a REFERRING particle: it
>       wears its own mainkey and CARRIES the pointer.  So the shape becomes
>        **`What / Point,doc:<path>,at:<def-name>`** — flat, one level, the Doc as an `of:`-style key on the
>         Point.  "Above the Map-like object and lines" is the resolution: `at:` names a `def` row Atlas
>          already holds, so a Point resolves INTO the census rather than duplicating a bit of it.
>           "A context the Point is going for" is what `at:` is — not a line number, the thing you were
>            after.  **Atheory-meshed:** the owner also wants an overall UI concept that meshes with
>             `TheA_<Name>_<Variant>_<dige>`; the cheapest reading is that a Point's context should also
>              name the BUNDLE it sits in, which Atlas can supply from `Lagoon_families` today and from the
>               declared manifest once Atheory lands.  Not designed further — flagged as the owner's, and
>                leg 3 should build the flat shape from the start rather than migrate to it.

> **⚠ THE FLATTENING IS A CORPUS-WIDE MIGRATION, not a tweak — measured 2026-09-08.**  `What > Doc >
>  Point` is not the Aside's shape, it is the UNIVERSAL Waft shape (`Interest.md`: "the document tree is
>   Waft → What → Doc → Point").  Changing it touches **12 walk sites, 20 `{Doc:1}` query points, and 53
>    recorded Story fixtures** that snap a Doc under a What.  So the owner's "perhaps" is a real ruling
>     with a real bill, and it should be taken deliberately rather than slipped in beside a trail feature.
>  **What WAS done instead, because it answers most of the complaint for one line:** a moment is no longer
>   anonymous.  `e_Lies_ghost_pick` now stamps `about:<the thing you were after>` on a fresh `What`
>    (`Lies.svelte`), which is the owner's *"a context the Point is going for"* without moving anything.
>     A day's trail reads as named moments from today.
>
> **The Aside junk IS this ruling, looked at (2026-09-08, the owner: *"check out these Waft:Aside though,
>  they're full of junk"*).**  The object-in-`sc` bug is fixed and today's file proves it —
>   `Point,method:Musica_cards` is a clean scalar, and `Musica_cards` really is in `Ghost/M/Heist.g`, so
>    the landing is correct.  What remains is not corruption, it is the SHAPE, and it is small: twelve
>     days, 58 lines total.  Three complaints, all of which the flat form above answers:
>  1. **Every `What` is anonymous.**  A day reads `What`, `What`, `What` — a pile of unnamed moments with
>      no idea what any of them was FOR.  The owner's *"a context the Point is going for"* is the missing
>       field, and it belongs on the Point, not on a container.
>  2. **`Doc` is a duplicated holding** (the identity-law break above), so the trail carries a second,
>      thinner copy of something Atlas holds properly.
>  3. **`FromWhat` is inconsistent across days** — a bare path (`Ghost/N/Peeroleum.g`) on 06-21, a full
>      locator (`Waft:Aside/2026-07-03/What:1`) on 07-03.  Two forms for one relation, which is its own
>       small identity smell; pick the locator.
> **The cleanse:** do NOT migrate the old files.  They are pre-shape, tiny, and genuinely historical —
>  leave them and let leg 3 write the new form from today.  A trail that changed shape is legible; a
>   rewritten one has lost the only thing it was for.

**LEG 4 — the beadchain.**  Needs leg 2.  Atlas holds `region,label,depth,from,to` for every doc — the
 beads, with depth as the clustering.  First cut: a doc rendered as its regions nested by depth with defs
  inside, in file order — a CHAIN, so no pose model is needed (`Lens_posable`'s gate).  Add it to Lagui as
   the way a doc is shown when you land in it.  Compound-node vocabulary later, from Cyto's own
    `compound` class.  §2.8.

**LEG 5 — the coverage map** (the owner: *"yes! this is important new ground"*).  Needs leg 4 (something
 to shade).  `Lagoon_join` already computes ran/never-ran per method; the union across Books is a reset →
  arm → run N Books → join (proven, §4d of `Wordland_todo`).  Shade beads by whether a run entered them.
   The tap is PARKED but arming it for a measured sweep is use, not extension.

**LEG 6 — doc rot as a work queue.**  Needs leg 2.  `Lagoon_lint.missing` (1,783 file links) and
 `Lagoon_prose_rot` (179 likely-rot symbols, §2.8) are the raw material.  Route each as a piece of work
  with a location and two exits — *fix the pointer* or *mark the doc obsolete* — and land the fix click in
   the editor.  The owner: *"higher level pointers or sending you around fixing|obsoleting things is the
    way."*

**LEG 7 — more link kinds.**  Independent; can run alongside any leg.  Each is a regex + `kind:` in
 `compile.ts`'s markdown sweep, an `ATLAS_MAPPER` bump, and a Lagoon resolver.  In value order: spec →
  sworn sentence (the owner kept this one), `Doc#region` (a bead), Book and step, `%Mainkey` notation.
   §2.8.

**LEG 8 — stacks of attention.**  Needs leg 3 (the trail is what a stack is made of).  **Read
 `Interest.md` first**; `%Interest` has stances, the foreground rule, multi-giver arbitration and per-Waft
  cursor memory off the Keep.  A stack is that, kept, not a new idea.

**LEG 9 — the portal.**  Needs leg 7's `[[ask: …]]` kind, and an owner ruling on WHERE requests live (a
 `%Ask` under the Aside is the natural home).  Mechanics in §2.8: a link mints a request particle; a
  Claude session watching that path answers by editing the doc in place; asynchronous by construction;
   show whether a session is watching, the way `Lies_channel_live` does for runners.

**LEG 10 — the recipe.**  Needs legs 3 and 7.  Tip / linear / spiral rendering of a doc, COMPUTED from
 what Atlas holds: the tip is `§0`, the linear stretch is sections whose links still resolve, the spiral
  is everything pointing into `history/` or at files that are gone.  No new discipline from a human.  §1.

**HELD behind Atheory** (not this course): fold Electrode at the Story seam; line/branch electrodes as a
 `TheA_<Name>_<Variant>_<dige>` Variant; the declared manifest.  `Electrode_todo §0`, `Atheory_todo`.

**Owed on what already landed:** a sabotage proof for `LagoonStaple`; the flake (bomb 9); `Lagui` should
 say out loud which corpus it is looking at (bomb 2); `Lagoon_resolve`'s duplicated constants.

---

### ✅ FRONT 1 IS DONE — 2026-09-08, the same afternoon it was proposed

`Ghost/L/Lagoon.g` stands, all five tenants moved, and **`LagoonStaple` is green ×2 on the live runner:
 `ok_pct:1, caveat:0`, declared 7 / sworn 7 / gaps 0.**  What landed:

- **Atlas is a census again** — 16 functions down to 12, all keeping.  `Atlas_callers`, `Atlas_lint`,
   `Atlas_resolve` and `Atlas_unproven` are gone from it, with the three constants only they used.
- **`Electrode_join` moved too**, becoming `Lagoon_join` — it reads both censuses and belongs to neither,
   which is the worked example the boundary exists for.
- **The CLI op names are unchanged** (`atlas_callers`, `atlas_lint`, `electrode join`), so no script
   breaks; they dispatch into Lagoon and refuse by name if it is not standing.
- **Proven live before and after the move**: `atlas_callers Lies_inside_story` returns the same two
   callers; the lint reports the same 1,783 file links over 711 docs; the join the same shape (192
    methods ran, 58.3% of declared pairs).  `AtlasStaple` and `ElectrodeStaple` still green.

**The Book gates the CONCEPT, not just the code**, which is the part worth keeping: three of its seven
 sentences are about the layer rather than any verb — a reader answers over a census it does not own; a
  reader with no census *refuses by name* (the exhaustive-named-exits law, `Fallen_out_of_mind §2.9`); and
   **a reader keeps nothing** — after every answer its own world holds only its report row.  That last one
    is the erosion alarm: the day someone caches an index in here, it reds.

**Four recordings' worth of lessons went into the Book's own comments** and they generalise to any Book
 written against a ghost that looks its subject up rather than being handed it:
1. **Stand where the reader looks.**  `AtlasStaple` can stand its subject anywhere because it *hands*
    Atlas the world; Lagoon looks its census up by name on the top House, so a Book that stands one
     elsewhere is not testing it at all.  The first recording swore happily against a command-line-stood
      census over the real 711-doc corpus.
2. **Gate on the truth, not on a beat.**  A synchronous beat that neither awaits nor holds anything is not
    guaranteed the tick you think it is; a claim gated on a flag such a beat sets can silently never be
     made, with every step green.  An `expecting` beat is different — its ttlilt holds the step open — so
      a marker *it* sets is a sound gate.  That is why the census claims here gate on a snapped
       `%aimed:fixture` row.
3. **Environment must not decide which step a sentence lands on.**  Whether a census happened to be
    standing changed the latch step, which would red the fixture on someone else's runner.
4. **Drive the pass, do not wait for a tick** (`Atlantation.g` beat 3's lesson, doubled): both censuses
    stand on the top House, whose belief loop a Story run does not pump.

**Still owed on this front:** a sabotage proof (break a reader, confirm the named gap), and deleting
 `Lagoon_resolve`'s duplicate constants if a third reader ever wants them.

*(The plan as written before it was done, kept because the reasoning is the durable part.)*  Five answers
 lived inside censuses and belonged here — `Atlas_callers`, `Atlas_lint`, `Atlas_resolve`,
  `Atlas_unproven`, and `Electrode_join`.  The cheapest possible first cut, because it invents nothing and
   makes the boundary real before a surface exists to blur it again.

`Atlas_unproven` is the one that proves the rule: it is not even a question *about* the census, it opened
 `wormhole/Story/**/*.snap` off disk — a second source and a second concern inside a code index, mitigated
  by an opt-in flag instead of being given a home.  After the move Atlas is 12 functions of pure census and
   the reader ghost owns every answer.

**Front 2 — the coverage map** (`Wordland_todo §1.3` story 3, the owner: *"yes! this is important new
 ground"*).  Shade every def a run entered; leave the untouched pale.  The join already computes it; what
  is missing is a surface and a union across Books.  This is the front the owner marked as the important
   one, so it leads once front 1 clears.

**Front 3 — doc rot as a WORK QUEUE, not a marker** (story 2, the owner: *"having higher level pointers
 or sending you around fixing|obsoleting things is the way"*).  So the lint's output is not a struck-
  through link in a margin.  It is a routed list: *this doc points at something that no longer exists —
   fix the pointer, or mark the doc obsolete.*  A rotted link is a small piece of work with a location,
    and the environment's job is to send someone to it.  1,782 file links are held right now, and the
     misses are already named.

**Front 4 — stacks of attention** (story 5, the owner: *"indeed, stacks of attention and stuff"*).  Note
 the plural: not one focus restored, a *stack* of them.  `%Interest` is the existing machinery
  (`Interest.md` — stances, the foreground rule, per-Waft cursor memory off the Keep) and it already has
   multi-giver arbitration with exactly one Trail bearing the LE.  A stack is that, kept.  **Read
    `Interest.md` before writing a line of this**; an explorer that invents its own notion of "what am I
     looking at and why" is the third design of a live thing.

**Downgraded by the owner:** story 4, *where is this claim proven*.  *"don't really care about this…
 pointers from the spec to the test assertion, sure."*  So: keep the spec→assertion pointer as a link
  kind; drop the unproven-census as a feature.  `Atlas_unproven` still MOVES here (front 1) — it is
   homeless either way — but it stops being a headline.

## 1. The recipe — a source part, wind-back-able

*The owner, 2026-09-08:* **"I think there should be a source part of the whole recipe for what we're
 building.  The recipe stays focused on the tip of itself, but is a wind-back-able thing, of all your
  moments… probably a linear bit and then a spiral off into infinity, so a hole we can pull open."**

Read plainly: the thing being built should carry the record of its own construction, and that record has
 a shape — a **tip** (what is live now), a **linear stretch** behind it (recent moments, legible in
  order), and then a **spiral** that curls away compressing indefinitely, which is not lost but *closed*,
   and can be pulled open like a hole when you need to descend into it.

**This is what `*_todo.md` is already reaching for and failing to be.**  The convention has the tip (`§0`,
 what to get on with next), a linear body, and a spiral (`spec/history/`) — but the three are held
  together by discipline rather than structure, so the linear part silts up, the spiral is a directory you
   must know to look in, and there is no pulling open: `history/` is a wall, not a hole.  The owner's
    complaint about handovers is the same complaint: *"a handover that's a changelog is the weakest, most
     disposable part; the load-bearing part is destination + the knowledge that detonates the bomb + the
      next move."*  The tip is load-bearing; the linear stretch is context; the spiral is everything that
       is true but no longer in the way.

**Why it belongs in Lagoon rather than in a style guide.**  Atlas already holds every doc as a particle
 with its headings, its links and its dige, and Lagoon is the thing that reads them.  A recipe with a
  tip, a linear stretch and a pull-open spiral is *a rendering of a doc*, not a new file format.  Nothing
   needs to be re-authored: the tip is `§0`, the linear stretch is the sections that still resolve against
    live code, and the spiral is everything whose links point into `history/` or into files that no longer
     exist.  **Lagoon can compute the fold from what Atlas already holds.**  That is the cheapest possible
      version of this idea and it needs no new discipline from a human.

**Adjacent prior art, honestly distinguished** (do not let these merge):
- **`ulative/memory-raw/yore-moment-spool.md`** (2026-07-19) is a spool of *world-state* moments — Cyto's
   glass, a Story-like scrubber, display-only time travel over `enWaft` diffs.  Same verb (wind back),
    different subject: that one winds back the RUNNING WORLD, this one winds back the RECORD OF THE WORK.
     They will want to look alike and should not be built as one thing.
- **`Whitehole_todo §3`** already owns a hole-shaped cosmology (a white hole is emit-only, the boot, never
   re-entered).  The owner's *"a hole we can pull open"* is the opposite direction — a hole you descend
    INTO — so the words rhyme and the concepts do not.  Flagged so nobody welds them.

**Open, and genuinely so:** what a "moment" is here.  A commit is too coarse and too rare; a session is
 unbounded; a doc edit is too fine.  The most promising unit is the one this machine already mints for
  everything else — *a claim and the evidence for it* — which would make the recipe's linear stretch a
   sequence of things that became true, each with the run that proved it.  Not decided.

## 2. The concept line it must not cross

From `Wordland_todo §1.1`, restated because this doc is the thing most likely to break it:

**Atlas KEEPS; Lagoon ASKS.**  The test for any addition: *does this change what is HELD, or ask a
 question OF what is held?*  Atlas already drifted to 12 keeping / 4 asking one convenience at a time,
  because no single addition was wrong.  Lagoon exists so that the answer to "where does this go?" is
   boring and permanent.

Its own version of the same trap, worth naming before it happens: **Lagoon must not start keeping.**  If
 a reader wants a cache, the cache is a derivation it can throw away and rebuild, never a second census.
  The moment Lagoon holds something Atlas cannot recompute, there are two truths.

## 2.5 THE AFTERNOON'S THREE BUGS — all found by the owner looking at their own tab

*Worth keeping together, because each is a different kind of mistake and only one was in the code I set
 out to write.*

### (a) Atlas was hogging the beliefs mutex, on the owner's EDITOR tab

**Symptom the owner reported:** a dozen `story_sel` clicks sitting undrained in `H.todo`, oldest 470s,
 *"not sure why it's not processing them, it's only the H%Run we want to pause hard."*

**It was not a pause.  It was a hog, and the machine's own electrode said so** — `runner_ask world` on
 that tab: `drain-lag … why=beliefs mutex held 4s by H:Mundo think Atlas/Atlas`, repeatedly.  EVERY House
  drains under the top House's single beliefs mutex (`Housing.svelte.ts:230`), so a pass that parses six
   files without yielding freezes the whole tab for as long as that takes, and every human click queues
    behind it.  `Atlas_pass` is a `%req` do_fn, so all of its `await`s run *inside* the mutex.

**Two unbounded holds, two fixes, both measured:**
- **`ATLAS_SLICE_MS = 120`** — the map/adopt loop now exits on a TIME bound rather than only a count.  A
   count was always the wrong bound: `Atlas_map_one` measured 50–194ms per doc, a 40× spread.
- **A RESUMABLE ROSTER** — the first pass used to walk every root (715 docs) in one go and return before
   ever reaching the slice check.  Chunking per ROOT was tried first and was *not enough*: `src` alone is
    most of the corpus, so a fresh stand still froze the tab for six seconds.  The frontier is now a QUEUE
     OF DIRECTORIES on `w.c.walk_q`, drained for one slice per pass, via a new non-recursive
      `Atlas_walk_one`.  **`Atlas_walk` itself is untouched**, because `Atlas_refresh` needs a COMPLETE
       walk to compute `gone` from its `seen` set — a half-finished refresh would drop live docs.  Only
        the roster, which has no such contract, may stop halfway.

| | worst mutex hold | worst wait a click feels |
|---|---|---|
| before | 4s, and 6s on a fresh stand | 2,553ms |
| after the time slice | ~1s | ~450ms |
| after the resumable roster | **no drain-lag mark at all** | — |

A fresh stand plus a full re-converge to 715/715 now produces **no lag marks whatever**, where the
 electrode reports anything past a healthy few tens of ms.  *Caveat, stated because it matters:* that
  re-converge was Dexie-warm, so it adopted more than it parsed — the ROSTER half is demonstrated, the
   worst-case parse half rests on the time slice.  **The real end state is still the pass running OFF the
    mutex**, which is what `expecting()` is for — parked because a standing `expecting` on Mundo arms a
     ttlilt and ttlilts extend Story's quiesce (`world` shows `ttlilt=382` inside a Book run), so it wants
      care rather than a quick edit.

**And the deeper mistake was mine before any of that: Atlas should never have been on that tab.**  Its own
 header says *"WHERE IT RUNS: a runner with FSA — spare capacity (nobody typing) … Never the editor (it
  must not ride the spine it is editing)"*.  My `runner_ask` calls were UNPINNED, so they landed on
   whichever tab acked first — the documented hazard in the `two-runners-pin-with-runner-flag` memory,
    walked straight into.  **Pin `--runner=` for anything that stands a world.**

### (b) "Lagoon seems like it has nothing in it" — the Books leave the census aimed at a fixture

`AtlasStaple` and `LagoonStaple` both re-aim `A:Atlas` at `Ghost/L/test_corpus` (one file, three defs) and
 **do not put it back**.  So after any Book run the face is honestly reporting a one-document census.  The
  owner read that as the face being empty; it was the fixture showing through.
 **Owed:** either the Books restore the previous roots, or the face says out loud *"aimed at a fixture
  corpus (1 doc)"* rather than quietly showing three methods.  The second is better — a surface that hides
   which world it is looking at will mislead again.

### (c) `div.usb-panel` covering the editor's scrollbar

The searchbar's dropdown was `right: 0`, so while a search was open it sat over the scrollbar underneath
 and you could not grab it.  Now `right: 1.1rem`; the panel is left-anchored to the input, so a gutter
  costs it nothing.

### A flake worth naming, not hiding

`LagoonStaple` measured over **11 runs: 9 green, 2 at `ok_pct:0.83, caveat:1`.**  Assertions were 7/7 with
 0 gaps in EVERY run, so no claim was ever lost — a step snap caught a different tick.  **Both flakes were
  the run immediately after a fresh Atlas stand**, i.e. with 715 docs converging in the background; the
   nine steady-state runs were green.  So the flake is contention, which is the very thing §2.5(a) fixes,
    and it should now be rarer.  **It is not yet a clean gate** — if it recurs in a quiet tab, that is a
     different bug and worth chasing properly.

## 2.7 THE SEEK NEEDS SOMEWHERE TO LAND — and `role:hacker` is the way

*The owner, 2026-09-08: "I definitely need an editor to go with this 'seek here' situation" … "by an
 editor I meant a Langui, a codemirror that takes me to all these Points the Lagoon walks" … "there's
  only allowed to be one editor for some thing iirc… it's Lies that makes it so… so we should avoid being
   that kind of editor? role:hacker for now?"*

**The owner's memory is correct, and it kills the obvious answer.**  I had suggested opening
 `/Otro?E=Educarium` beside their runner, because an Otro editor is not a humdinger and so would accept
  `ghost_load`.  **That would have evicted them from their own editor slot.**  The rule is enforced in two
   places and is not advisory:
- `LiesFunk` (~:499): *"the editor that is claiming supersedes every other editor row: the one editor is
   whoever is here now."*  A second editor tab takes over the `%HostedIdentity` directory.
- `Lies_aim_setup` returns immediately unless `Lies_role(w) === 'editor'` — the %Aim/Cluster endpoint
   targeting is the one editor's job, and `LiesFunk:423` says why: *"single-control-point state belongs to
    the one editor."*  Plus the relay itself: *"one editor per relay"*, fanning every runner→editor frame
     to the one editor socket.

**And their runner tab cannot host a Langui either**, which is the other half of why the seek lands
 nowhere: it has no `A:Lang` at all (`minisnap mundo` gives `A:Lies` with `w:Lies,runner,creduler` and no
  Lang), and `e_Lies_ghost_pick` already knows — *"a runner (no editor) has no Trail strip to foreground —
   no-op, don't throw"*.  So a click records a trail into today's Aside and shows you nothing.

### Why `role:hacker` is the right shape, and cheaper than it sounds

A hacker tab wants the editor's **local capabilities** (A:Lang, Langui, docks, FSA read, `ghost_load`) and
 none of its **singular duties** (the Cluster claim, %Aim, the relay's editor socket, Waft saves).

**The elegance is that the duty gates are EQUALITY tests.**  Every one of them reads
 `Lies_role(w) === 'editor'` or `Lies_is_editor(w)`, so a third role opts out of all of them *for free* —
  nothing needs a new condition, and nothing can forget to exclude a hacker.

**The audit** — every editor gate in the tree, classified:

| | sites | what a hacker does |
|---|---|---|
| **duties** — Cluster claim, `Lies_aim_setup`, relay editor handling (`LiesLies:1526/1586/1654`) | ~6 | **opts out free** (equality test) |
| **capabilities** — Keep focus + resume (`Lies.svelte:233/1013/1018`), the editor-local branches (`LiesLies:573/606/650/970`) | ~7 | **must be re-pointed** to `editor || hacker` |
| **writes** — `Lies_waft_save` (`Lies.svelte:833`), compile `dock_source` (`LangCompiling:274`, `LiesCortex:155`) | 3 | **stays editor-only** — a hacker READS |
| **cosmetic / boot** — `BootGate` labels, `MountNav:53` disk gating, `Housing:2356` | 3 | follow `boot_role`, unchanged |

So: `role: 'hacker'` → `boot_role: 'editor'` (the machine stays two-valued, as `BigQualand` insists, so
 the world layout and disk gating are inherited) but `H.c.role = 'hacker'` so `Lies_role` returns
  `'hacker'` and every duty gate misses.  Then re-point the ~7 capability gates to a new predicate —
   `Lies_has_docks(w)` = editor or hacker — which is the honest name for what they were really asking.

**The one genuinely unclear bit, flagged rather than guessed:** six sites read
 `peer = role === 'editor' ? 'runner' : 'editor'`.  With `role:'hacker'` the peer becomes `'editor'`, so a
  hacker would look for an editor peer on the channel.  For a local read-only wanderer that is probably
   harmless and possibly even right, but it is the one place where a third role meets a two-valued
    assumption, and it wants a look rather than a shrug.

**Not built** — a new role in the cluster's role vocabulary is the owner's to rule, and this one touches
 the relay.  The design above is complete enough to build in an afternoon once it is.

## 2.8 THREE MORE WANTS, HELD — the beadchain, the link language, and the portal

*Recorded 2026-09-08 in the owner's words, unbuilt, so none of them is re-derived from scratch later.*

### The beadchain — code as beads, not a screed

*"we then also want the code to not be so much of a screed but a beadchain, which could have clusters of
 stuff, compound nodes, etc… perhaps.  it's that world very soon now."*

**Atlas already holds the beads and nobody has drawn them.**  A `//#region` is an author-declared bead
 with a name and a span, and the census keeps `region,label,depth,from,to` for every doc — including the
  *depth*, which is the clustering.  So a beadchain view of a file is: its regions as beads, nested by
   depth, with each region's defs inside it.  No new collection, no new parse; a rendering of held rows.
 **The compound-node vocabulary also exists**, in Cyto: `cytyle_classify` already returns
  `skip|invisible|compound`, and Matstyle styles by mainkey.  So "clusters of stuff, compound nodes" is
   the graph layer's own language pointed at code instead of at a world.
 The honest gap is the same one the plant section names: arrangement.  A chain has an order and a
  chain-of-clusters has a layout, and that is the pose model `Lens_posable` says not to invent yet.  A
   first cut that dodges it: beads in file order, indented by region depth — a chain, not a graph.

### A whole language of links in markdown — ✅ THE THIRD KIND IS BUILT (2026-09-08)

*"we need a whole language of links you can do in markdown."*

**`code` landed the same afternoon** (`ATLAS_MAPPER m14`), and the insight was that most of the language
 is ALREADY WRITTEN — the corpus points at methods in backticks on every page and nobody was collecting
  it.  The filter is the underscore: of 15,160 backticked tokens in `spec/`, the 8,834 containing one are
   almost purely real symbols; the 6,000 without are `sc`, `true`, `ok`.  Live over 715 docs:
    **11,042 code links, 3,025 distinct.**
 **Resolution is the READER's, not the collector's** — `compile.ts` cannot know the corpus, so it emits
  every candidate and Lagoon decides.  That split is the concept line doing real work.
 Two verbs came with it, and a CLI door (`runner_ask lagoon <verb>`):
- **`Lagoon_mentions <name>`** — which docs TALK about a symbol, with lines.  The twin of `callers`:
   between them a method has both neighbourhoods, the code that depends on it and the prose that explains
    it.  `Repli_serve_chunks` → Backpressure_todo, Download_stall_handover, Fallen_out_of_mind.
- **`Lagoon_prose_rot`** — front 3's work queue for symbols.  **It over-claimed TWICE and the fixing is
   the interesting part.**  First cut: 1,343 "unresolved", topped by `body_hash`, `runner_ask`,
    `CREDULER_GHOSTS` — keys, a CLI name, a constant.  A backticked word is not a promise that a def
     exists.  Filtering to the ghost-method shape (`Capitalised_lowercase`) cut it to 254, still topped by
      `Daemon_todo`, `Division_todo` — DOC names, which wear the same shape.  Excluding doc names (Atlas
       holds all 715 paths) gives **179**, and spot-checking the top three found two genuinely gone
        (`Story_next_level`, `Repli_loc_keys`) and one alive.  **The lesson worth keeping: "looks like a
         symbol" and "is a symbol" are different questions, and only the census can tell them apart.**

Before this, the corpus had **two** link kinds and Atlas collected both: `[[wiki-slug]]` (174 live in `spec/`,
 resolving to `spec/ulative/memory-raw/<slug>.md`) and `file.ext:line` (1,783 live).  That is a
  vocabulary of two, and everything else a doc wants to point at has to be spelled out in prose:
- ~~a **method**~~ — ✅ BUILT as the `code` kind, above
- a **family** (the stem-buckets of §the index) — "the Heist family"
- an **assertion / sworn sentence** — the owner's own downgraded story 4 was *"pointers from the spec to
   the test assertion, sure"*, which is exactly this
- a **Book**, and a **step** of one
- a **region** (`Atlas.g#the cache`) — a bead, per the beadchain above
- a **particle shape** (`%Record,total`) — the `%Notation` the Stemdex already tokenises

**Cheap, because the collector is one independent line-sweep** (`compile.ts`, the `WIKI_RE`/`FILE_RE`
 pass): each new kind is a regex plus a `kind:` tag, an `ATLAS_MAPPER` bump, and Lagoon gains a resolver.
  The value is that the lint then covers them — a link to a method that no longer exists rots exactly the
   way a `file:line` does, and §0 front 3's work-queue picks it up.

### The portal — talking to Claude from inside a document

*"we've got to put you in markdown… which I assume there's a… do we just talk to you through a portal or
 something?"*

**The honest mechanics first, because they constrain the design.**  Claude here is a CLI process in a
 container.  The app cannot summon it: there is no inbound door, and `runner_ask` runs the other way
  (the CLI asks the tab).  What the two DO share is the filesystem — the wormhole is the same disk from
   both sides — and a Claude session can watch a file and act on a change.

So the portal that needs no new transport is a **file-shaped mailbox**:
- a link kind, say `[[ask: how does the mutex hold work?]]`, mints a request row in the corpus (a `%Ask`
   under today's Aside, or a `wormhole/Ask/<YMD>/` doc — the Aside is already the trail's home)
- a Claude session watching that path picks it up and answers by **editing the doc in place**, which is
   what it already does all day
- the answer lands where the question was asked, which makes the document the conversation and needs no
   chat window at all

**Two properties worth keeping if this is built:** the request is a *particle*, so it snaps, and a Book
 could swear that an ask was answered.  And it is asynchronous by construction — the doc is not blocked
  waiting, which matches how a Claude session actually runs.
 **What it is NOT:** a live call.  Anything that wants an answer *now* needs a process already running,
  and the honest way to say that in the UI is to show whether a session is watching — the same
   liveness question `Lies_channel_live` already answers for runners.

## 3. THINKING LIKE A PLANT — the surface's stance

*The owner, 2026-09-08, on the first face: "any thoughts on the UI? I need you thinking like a plant
 there."*

**First, the honest read of what was just built: `Lagui` is not a plant, it is a dashboard.**  Three
 buttons you press to make three things happen.  Nothing grows; nothing responds to where you are looking;
  press nothing and it shows nothing.  It is a fine first cut for *making the work visible at all*, which
   was its whole job, and it is the wrong shape for what this wants to become.  Say that plainly before
    designing over it.

**What a plant actually does, and what each thing maps to here:**

- **Tropism — it grows toward light, it does not plan a shape.**  The light is ATTENTION, and attention
   already has a name and a machine: `%Interest`.  So nothing is placed; things grow where you are
    looking.  You land the cursor on a method and its callers *sprout* beside it — you do not press
     "callers".  You open a doc and its rot is already showing.  **The verb list stays; the buttons go.**
- **Local rules, no arranger.**  A plant has no layout algorithm and no pose model; form is what happens
   when every meristem follows the same local rule under different local conditions.  **This is the
    cleanest way through the `Lens_posable` gate** ("don't build until the pose model is designed"): we do
     not need a pose model if we are not posing.  Design the *growth rule*, let arrangement fall out.
- **Growth is rationed.**  A plant cannot grow everywhere; it spends where the return is.  The corpus has
   already designed this energy budget twice and built neither: `Matstyle`'s **`dose_drives`** (interpolate
    a size from a dose between min and max — the growth response, and it EXISTS) and `Lens_posable`'s
     **excitement/awakeness scheme** (a `run_when` floor plus an Interest-cursor excite level driving lens
      intensity, with an MRU budget on the awake set — designed, unbuilt, uncooked).  Those two are the
       plant's phototropism and its carbon budget, sitting on the shelf.
- **Apical dominance.**  A plant grows mostly at one tip and branches only when the tip is checked.  So the
   surface shows ONE growing point strongly and its branches faintly — not N equal panels.  **This is the
    same shape as the recipe** (§1): a tip, a linear stretch, a spiral curling away.  The apex is the
     question you are asking now; the branches are what you left.
- **Accretion, and nothing is deleted.**  Wood is the record of every year that happened; scars stay.  The
   spiral in §1 is heartwood — not lost, just no longer conducting.  A rotted doc link is deadwood you can
    see and prune.  This is also why the recipe should never be a changelog: rings are not a list of years,
     they are the shape the years left.
- **Dormancy is normal.**  Off by default, flushing when worked.  The tap being parked is a season, not a
   deletion (`Electrode_todo §0`).
- **Roots and shoots are one organism.**  `Atlas` is the root — down into the substrate, seeking, mostly
   invisible, doing the actual acquisition.  `Lagoon` and its face are the shoot — up toward attention,
    where the light is.  `Electrode` is the sap: what actually flowed, and how much.  That is a better
     account of why these three sit in one directory than "they are all about code".

**The claim worth testing, flagged as my read rather than the corpus's:** *thinking like a plant is not a
 new idea here — it is the name that unifies four designed-and-unbuilt things.*  `dose_drives` (size from
  attention), the excitement/awakeness scheme (the budget), `%Interest` (the light), and — the one that
   makes it more than a metaphor — **`Vyto_sizing_todo §7`'s sizing algebra, whose declared inputs are
    "dose, shared-ness, attention" and which is the named tenant that would un-park the Sunpit and
     `IOexpr`** (an `IOexpr` names a source and a shaping; growth *is* a shaping of sources).  If that
      holds, the plant-shaped surface and the un-parking of `IOexpr` are the same piece of work, and the
       owner's two open threads — "expressing Seem's sphere-joining more coherently" and "how IOexpr can
        play with it" — meet exactly here.  **Not decided; it wants the owner's read before anyone builds
         on it.**

**What that makes the next cut of `Lagui`** (small, and none of it needs a pose model):
1. **Delete the buttons.**  Read the Interest; show what is true about where the cursor already is.
2. **One apex.**  The current question big, its branches dim, everything else folded to a line.
3. **Dose as size.**  Reuse `dose_drives` rather than inventing a prominence rule.
4. **Nothing vanishes; it thins.**  A dropped branch greys out and stays for a while — the spiral, in
    miniature, so the surface teaches its own history.

## 3.9 Erupting structures — the surface's one idea

*"little structures erupt when we go climbing call trees… they might be arranged around the place."*

The pin rail in BigWordland is the seed of this and is already built: a search hit can be pinned into the
 loose space beside the code, and a pin click re-fires the same recorded delivery.  Climbing a call tree
  should erupt the same kind of small thing — a caller list, a coverage patch, a doc-link cluster — which
   can then be *placed* rather than dismissed.  Two constraints inherited:
- **No new pose model.**  `Lens_posable_TODO`: *"the posing/anchoring model is the unbuilt, uncooked part.
   Don't build until the pose model is designed."*  So arrangement in cut one is the rail's own list order,
    not free placement.  Free placement is the pose model, and it is a designed thing waiting its turn.
- **A structure is a view, never world-matter.**  The `yore` note's rule, and the same one that keeps
   Electrode's ring on `.c`: what you erupt while wandering is not state the world owes anyone.

## 3.5 WHERE YOU ACTUALLY SEE IT — the face, and why not in BigWordland

*The owner, 2026-09-08, looking for the afternoon's work in a browser: "where do I see the latest thing?
 …is the same old LiesLand I think… but only Langui visible? where's all the work?"*

**Honest answer at that moment: nowhere.** Everything the censuses knew was reachable only from the CLI,
 which is not a place anyone lives.  So `Lagui.svelte` (`src/lib/L/`) was built the same afternoon and
  `Lagoon_plan` mounts it the ordinary way — `uis.oai({UI:'Lagoon'}, {component: Lagui})`, the `Cyto_plan`
   idiom — so it appears as a `UI:Lagoon` row like Lies, Cyto and Supervisor do.  **Confirmed mounted on
    the live runner.**  Three readings stacked in one panel, matching the stories: *who calls X*, *rotted
     doc links as a work queue*, *declared vs measured*.  A hit click is the same recorded
      `Lies_ghost_pick` delivery the searchbar already makes — reusing navigation rather than inventing it.

**It keeps nothing**, exactly like the ghost beneath it: every number is asked on the tick it is drawn.  A
 face that cached would be the two-truths mistake one storey up.

**⚠ It cannot appear in `/BigWordland`, and that is structural.**  The room boots `role: 'word'` →
 `Lies%humdinger`, and `ghost_load` is REFUSED on a humdinger (`LiesFunk.svelte:2522`, "a music page is
  never made to load code").  L ghosts are outside `CREDULER_GHOSTS`, so a humdinger has no other way to
   get them.  **The room therefore shows only what the spine mounts — which is why the owner saw Langui
    and nothing else, and why that is not a bug.**  The face lives on the RUNNER tab, where the ghosts do.
 Getting it into the room is a *manifest* question and therefore Atheory's: either L ghosts join the
  declared manifest for an editor role, or the room learns to ask a runner over the relay (`Wordland_todo
   §5`, road (a)).  **Do not fix this by editing `CREDULER_GHOSTS`** — that is the load-list disease
    `Atheory_todo` exists to cure, and a humdinger would then parse every L ghost it never uses.

## 4. Where it lives

`Ghost/L/Lagoon.g`, beside `Atlas.g` — the land (`CLAUDE.md`, "the land").  L ghosts are not in the spine
 manifest, so a runner gets it with `ghost_load Ghost/L/Lagoon.g --stand=Lagoon` and a tab reload drops
  it.  Book: `Ghost/L/Lagoonation.g` → `LagoonStaple` (the `<Name>ation.g` convention: Voro→Voronation,
   Atlas→Atlantation).  CLI: the existing `atlas_lint` / `atlas_callers` ops keep their names for now and
    dispatch into Lagoon, so nothing a script calls changes on the move.
