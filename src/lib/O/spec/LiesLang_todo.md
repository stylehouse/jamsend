# Lies|Lang — the editor machine, put together

The editor machine is two ghost families and the faces over them.  **Lies** holds and moves documents: it opens Wafts, reads
 and writes files, compiles a doc into a `.go`, ships it to a runner and hears back.  **Lang** is the language and the
  attention: the `.g` grammar, the docks, CodeMirror, the cursor's "understanding" of what you're looking at.  They meet in
   the **Waft** — a tree of What → Doc → Point that names code — and in the **Interest**, Lang's handle on a Waft that Lies
    holds.  It works.  This doc is not a plan to rebuild it (owner, 2026-10-25: *"it's about right, I just want it to all be
     put together more coherently"*) — it is the one map, linking the narrower docs and the long file headers that already
      say each part well.

## 0. What to get on with next

The destination (owner, 2026-10-26): **BigWordland becomes the one editor** — several docs open at once as viewports you
 grow, shrink and rearrange, standing on the Wafts that give it its sense of place.  Editron (`?E=`) is the legacy editor
  and is usually not awake, so nothing on the road may depend on it.  The road is §11.  Next moves, in order:

1. **"No wafts" — FOUND and fixed (2026-10-26).**  `story_harvest_desc` (Story.svelte) harvests a Book's step description
    with `fw.o({ desc: 1 })` — a presence wildcard, so it took ANY child carrying `desc`, and a Waft does: at every step snap
     it set the step's desc from the Waft and DROPPED the Waft.  Only Book rooms (Hackarium, Educarium — their tocs carried the
      stolen desc, now cleared) hit it.  Fixed to mainkey `desc` only.  Found by `Lies_waft_census` (`🗂⚠ Waft:X LEFT w:Lies`,
       stays) and a one-reload `drop()` probe.  Also landed on the way: a Waft read lost after the Book ends is retried (2s
        wake); close drops its Good; a loaded-but-missing Waft is said and re-read; STUCK reads are one line per 10s.
        ⚠ Any recorded Book that opened a Waft with a `desc` was recorded WITHOUT it — expect such a step to red once.
1b. **The boot read flood — found (2026-10-26).**  Not the Wafts themselves: the cave's search index.  BigWordland's cave
    clock (`open_cave`, ~:210/:231) fires `Lies_stemdex_scan` at boot, and its roster (`e_Lies_stemdex_scan`, LiesFunk ~:1582)
     is every Doc of every open Waft — so opening Waft:Everything made it read the whole corpus.  Everything is now left out of
      that roster.  Owed: the Stemdex should ask Atlas (`Atlas_nav()`, Lagoon's "at a press, never a sweep" seam) instead of a
       second read pipe through LiesStore; Atlas keeps dige/size/defs per doc but no text.
2. **The write seat** (§11 step 1).
3. **The compile authority off Editron** (§11 step 2).
4. **Viewports in Langui** (§11 step 3).
5. The first Atheory seam (§9); diagrams owed in §3–§5.

## 1. The map in one breath

A **room** (Editron, BigWordland/Hackarium, Educarium, Clerkdesk) boots a Story Book whose recipe stands `A:Lies/w:Lies` and
 `A:Lang/w:Lang` on the Run House and stamps a **role** (`editor` | `hacker` | `runner`).  The recipe asks Lies to **open a
  Waft**; Lies reads its toc through `req:Store`, places the `Waft:` tree on w:Lies, binds its Funkcions, and puts the
   **cursor** (`%Spotlight`) on a What.  Lang's **understanding** (`req:understanding`, LangHold's LE) checks out that What's
    Docs; Lies **provides each doc as a dock**; Lang mounts it in **CodeMirror** (Langui), grafts Points onto its defs
     (LangGraft), draws the minimap.  An edit goes back into particles; **compile** turns the doc into `gen/**.go`
      (`req:Cortex` → `req:Codebit`), and a **runner** takes it in (Vite HMR, or `Creduler_reswap` at a safe seam).

## 1b. The tech, in layers (2026-10-26)

Read top-down: a person's eye is at the top, the disk at the bottom.  Every layer is ghosts (eatfunc'd methods on the House)
 plus particles; the faces only READ particles and fire elvis at ghosts.  Sizes are lines, to say where the weight is.

```
 ROOM       BigWordland (614) ─ Hackarium (115)       Otro ?E= ─ Editron      Educarium         ← boots a Book, stamps a role
              │ H** switcher · Searchbar (451) · pin rail · ▦ sprawl
 FACES      Langui (2369) CodeMirror per doc · DocMinimap (950) · NaviCado (642) · InterestStrip (322)
            Liesui (471) Waft list → Waft.svelte (1237) → DocRow (288) · Storui (2431) / Storica (229)
              │ read particles; act by elvis
 ATTENTION  LiesCurse (649) %Spotlight cursor over What   ⇄   LangCurse (209) %Interest per Waft
            LangHold (1690) the understanding: the LE, the two Seems, checkout of a What's Docs
            LiesKeep (313) Waft:Keep — where the cursor sat, per Waft (editor writes, all read)
              │
 DOCUMENT   Lies (1627) Waft → What → Doc → Point; open/close/retake/place; LiesPersist; the tick
            LiesFunk (4224) Funkcions riding a Waft (req:Waftica carrier), GhostList, minisnap, verbs, CLI ops
            Lang (2036) docks — one EditorState per open doc · LangGraft (928) Point ↔ text range
            LangRegions (639) regions, Point resolution, openness · LangPoint (353) fold Q · LangWhatwhere (734)
              │
 COMPILE    LangCompiling (382) + lang/compile.ts (2169) the .g translator · LangSion (301) IOing helpers
            LangLang (202) grammar pick + parser gen · LiesCortex (394) req:Cortex → req:Codebit per dock (owns the .go write)
            LiesRun (367) req:Rundown → req:BlatDo — run a compiled thing, record %ran · Pantheate mounts it (non-editor)
              │
 IO + ROLE  LiesStore (1116) req:Store — a %Good per path, reads/writes in phases, STUCK narration
            LiesLies (2543) roles (editor|hacker|runner), the relay channel, the watch desk (disk moved → retake),
             the include door (Lies_ghost_include, %GhostInclude), Creduler (runner's ghost loading)
              │
 BELOW      Housing — the Wormhole actor (rw_op: read/write/list over WormholeNav: FSA folder, OPFS, or the relay)
            Hovercraft — the req machine (maz levels, ttlilt, wake ≠ hold) · Stuff — C, o/i/oai, replace/place, drop
```

**Beside the stack — what the editor stands in** (the picture as of the "no wafts" hunt, 2026-10-26):

```
 HARNESS    Story (3287) + Auto (1602): every room IS a Book.  The Run House is built by the recipe (Run_A_<Book>), driven
             step by step, SNAPPED, then the Story finishes and the heartbeat is released.  Story's own passes run over
              the room's w's at every snap (story_harvest_desc took the Wafts) — a room is under test whether it means it.
 GROUND     $lib/A/ground.ts (65) the FLOOR: loads a room's code bundle in order with no Theory (Ground/Land → Glass → Core)
             through the include door, then Ghost/A/Ground.g (84) on Theory.g (1001) SAYS it on the A (%GroundUsed,
              %TheACode per .g, Firm).  The lists come from the Ground tags on Waft:Everything (everything.js).
 THE LAND   Atlas.g (1035) KEEPS the code census: a %Doc per file (dige, size, mtime, defs/calls…), Dexie-cached, ~686
             docs, NO text.  Lagoon.g (2377) ASKS of it — the reader layer, the cave (search over the glass), one line
              read "at a press, never a sweep" (Atlas_nav).  Electrode.g (305) what the code DOES.  Workshop.g (121) verbs.
             Vyto.g (2762) + Voro.g (2130) the glass the cave draws on.
 SEARCH     the Stemdex (in LiesFunk ~:1414–1670) — the cave's full-text index.  Fed by BigWordland's cave clock at boot,
             its roster is every Doc of every open Waft (bar Waft:Everything), read through LiesStore — a SECOND read
              pipe beside Atlas's.  Joining them (Stemdex asks Atlas's nav; Atlas never keeps text) is owed.
 OUTSIDE    the dev server (:9091, Vite HMR delivers every .go) and relay.ts (1277): the websocket every tab meets on —
             runner_ask, the docindex push, the watch desk's inotify, gen_write, and (§11) the seat.  Editing it restarts
              the server and drops every socket.  On the owner's box the room reaches its folder over FSA through Caddy
               (djamsend:9999), so every read is slow — a sweep that is harmless headless floods there.
```

**The shape the editor is heading for** (§11): BigWordland is the one editor — a seat at the relay says who writes, a
 compiler nobody runs on says what compiles, Langui shows several docs as viewports, and the census (Atlas) rather than
  per-doc reads tells the faces what each doc is.  The pieces exist; what's missing is ownership — who writes, who
   compiles, who reads the corpus — said once, as particles, instead of by role equality and by whichever sweep got there.

**The four things that are easy to get wrong** (each bit someone in 2026-10):
- `replace()`/`place()` empty the container across awaits — any read in that window sees nothing; `drop()` marks the C
   itself, so a drop by ANY holder hides it everywhere (the "no wafts" was a Story harvest dropping Wafts).
- Role gates are equality tests against `'editor'` — hacker and runner opt out of every duty for free; keep it that way
   until the write seat (§11) replaces them with `Lies_holds_seat`.
- A Book room's Story finishes and stops ticking; anything still waiting after that needs its own wake.
- A query `{k:1}` matches anything CARRYING `k`, not just `%k` particles — a sweep that drops what it matched eats
   bystanders (`story_harvest_desc` vs the Wafts).  Filter on mainkey before dropping.

**Where the state lives:** documents and attention as particles on w:Lies / w:Lang (snapped in Books); text in Lang's
 EditorStates (`.c`, never snapped); disk truth on `%Good/known` (dige of the last read|write); the code census in Atlas
  (`w:Atlas`, Dexie-cached) — which Lies does not yet use (§0); the search index's text in the Stemdex (LiesFunk, own
   Dexie cache); what code a room stands on on its A (`%GroundUsed`, `%TheACode`).

## 2. Booting a room

| room | boot | role | opens | home doc |
|---|---|---|---|---|
| Editron | `?E=Editron` (any `?E=`) | editor — the ONE writer (`%HostedIdentity` claim; `Lies_aim_setup`) | `EDITOR_WAFT`, Keep, Cluster, GhostList | `Editron.md` |
| BigWordland → Hackarium | `/BigWordland` (`?H=`, `?W=`) | hacker — reads, compiles locally, no editor duties, no relay claim | `?W=` (default `Ghost/Net/Easy`) + `Ghost/Everything`, GhostList | `Wordland_todo.md` |
| Educarium | its recipe | editor (teaching room) | its Waft | `L/Educarium.svelte` header |
| a runner | `?B=<Book>` | runner — read · compile · include; no Wafts | none (Liesui says `runner`) | `Editron.md` §1 |

- Role is stamped once (`H.c.role`, and `w:Lies%hacker`); `Lies_role` (`LiesLies.svelte` ~:156) reads it.  Every duty is an
   **equality** test against `'editor'`, so a hacker opts out of each for free — and Keep/Cluster are editor-only by design.
- Hackarium stands its code from a **Ground** (`Ground/Land`, Aprac_todo §0.5) and says so on `A:Hackarium` (`%GroundUsed`,
   `%TheACode:Ground/*`).
- ⚠ The room is HMR-sensitive: an edit to a spine file re-mounts BigWordland and `auto_reset_story` boots a fresh Run House.

## 3. The req stack, per tick

Lies is a req stack (Hovercraft; `Coding_guide.md` for wake ≠ hold): `req:Store` (the IO pump — `Good` slots per path,
 LiesStore.svelte), `req:Cortex` (compile foreman) → `req:Codebit` (one per dock; owns the generated write), `req:Rundown`
  (the runner side, LiesRun), `req:wants` (cold wants → the cursor), `req:Langoer`, `Funkcions/req:Waftica` (one per open
   Waft).  Lang: `req:workon` → `req:understanding` → `req:ingredients` → `req:instrumentation`, `req:waft_roster`.
    *Owed: one diagram of a tick through both.*  Draws on: each file's header; `Hovercraft.design.md`.

## 4. Doc → dock → .go → running

Lang compiles (`LangCompiling`, `LangSion` for the IOing reduction) → `req:Codebit` writes `gen/**.go` through LiesStore →
 Vite HMR re-mounts it on every tab that imported it (`GhostHMR_todo.md`) → on a runner, `Creduler_reswap` folds a changed
  `.go` in at a safe seam; a loaded L/A ghost takes it via `runner_ask ghost_load --swap`; an A holding the file takes it at
   its era seam (`TheA_code_push`, Theory.g).  Authoring rules: `LangCompiler_TODO.md`.  Channel: `Editron.md` §2–3.

## 5. CodeMirror ↔ particles

`Langui.svelte` keeps an EditorState per doc; `LangGraft` binds each Point to its def's range (the Pmirror, `🔩 graft` lines);
 `LangPoint` folds; `LangRegions` resolves a Point; `DocMinimap` draws the map.  *Owed: "a keystroke becomes a particle
  write", traced once.*  The four headers are good and say nothing of each other — this section should join them.

## 6. Attention — Interest, the cursor, the understanding

`%Interest` (on w:Lang's `Languinio`) is Lang's handle on a Waft Lies holds; `interest_roster` is recomputed every tick off
 `w.o({Waft:1})` and `interest_reconcile` marks an Interest `state:gone` when its Waft leaves (`LangCurse.svelte` ~:38–159)
  — so `state:gone` is a plain readout of "w:Lies has no such Waft".  The cursor is `%Spotlight` (LiesCurse); the checkout is
   LangHold's LE.  Docs: `Interest.md` (the channel), `Lies_attention_todo.md` (the cursor model, open work P7),
    `LiesEnd_spec.md` (the LE/Seem), `Keeping_spec.md` (the Keep — what's remembered across reloads).

## 7. The Waft tree and its chrome

Waft → What → Doc → Point; the medium is documented atop `ui/Waft.svelte` (`history/Waft_spec.md` has the old grammar table).
 Chrome: NaviCado, DocMinimap, Searchbar, the Interest strip, Liesui's Waft list.  Wafts are generated, mostly: the area Wafts
  and **Waft:Everything** come from `src/lib/L/everything.js` (`scripts/wafts_everything.mjs` or the `everything` verb) —
   never hand-edited — and Everything's area Whats carry the **Ground tags** (`ground:Land` …) that derive `wormhole/Ground/`.

## 8. Role gates and who writes

The editor is the one writer (Waft saves, the compile `dock_source`, Keep cursor writes); a hacker compiles locally and reads;
 a runner reads, compiles, includes.  A verb that `writes` is refused by name outside the editor (`Verb_run`, CLAUDE.md
  "Verbs").  The seat/compile-authority design that would move writing is `Editron.md` §8 (unbuilt).  ⚠ Preserve the
   three-way split verbatim in any re-expression; it is load-bearing and easy to collapse.

## 9. Where Atheory meets it (ranked, from the 2026-10-25 survey)

1. **Code tracking duplicates TheACode/Ground**: `CREDULER_GHOSTS` (LiesLies ~:56) is a hand list; the `%GhostInclude`
    shelf (`Lies_ghost_get`, `Lies_ghost_include` ~:1300) tracks per-file diges; `Creduler_ensure`/`_reswap` is a hand-built
     era seam.  → `Ground/Runner` + `Ground_stand` on a runner A; Story's begin gate becomes Firm (Aprac §0.5 slice 4).
2. **Faces that re-derive every flush** — Liesui (its own header says so), InterestStrip's `$derived.by`s, DocMinimap — are
    Stuffica's target: a view per list, committed only when its sheet changes (as Storica did for Storui).
3. **State on `.c` / local `$state` that mirrors particles**: `languinio.c.roster_sig`, `w.c._waft_subs`, Liesui's
    `loaded_docs/errors/all_wafts/run_results`.  Off-snap by design; candidates once views exist.
4. **Where a compile lands** — Codebit `write_finished`, `Creduler_reswap`, the include door — is where the era seam goes when
    Hackarium's editor seat is rebuilt on Atheory (Aprac §0, the arc).

## 10. The narrower docs

`Editron.md` (editor ↔ runner, Credence, the seat) · `Wordland_todo.md` (the hacker room, the land) · `Interest.md` ·
 `Lies_attention_todo.md` · `LiesEnd_spec.md` · `Keeping_spec.md` · `LangCompiler_TODO.md` · `LangSolver_report.md` ·
  `GhostHMR_todo.md` · `Verbs_todo.md` (a terminal's controls) · `Clerkdesk_todo.md` · `Lagoon_todo.md` (the reader layer) ·
   Aprac_todo §0.5 (the Ground).

## 11. Toward the one editor (plotted 2026-10-26)

**Which room means what, today.**  `/Otro?E=<Book>` boots `role:editor` (the one writer — Waft saves, Keep, Cluster,
 compile tickets); `/Otro?B=<Book>` boots a runner; `/Otro?H=<Book>` a hacker.  `/BigWordland` defaults to `?H=Hackarium`
  (hacker: reads, compiles locally, writes nothing) and takes `?E=<Book>` for the old editor role in its presentation — so
   `/BigWordland?E=Editron` is Editron wearing BigWordland's room, and it takes the editor slot.  BigWordland has no `?B`:
    runners board through /Otro.  So BigWordland does not merge the meanings; it picks one at boot, and the editor one
     rides the LIVE spine (Editron proper rides `pinned_stable/`), which §8.2 B of `Editron.md` says a compiler must not.

**The road** — `Editron.md` §8.2 is the design; this is the order, changed by Editron being asleep:

1. **The write seat** (§8.2 A): `seat:editor` held at the relay (hello's `seats` arbiter, one more name), asked for by a
    deliberate act, lost with `seat_lost` after flushing; every `=== 'editor'` write gate reads `Lies_holds_seat(w)`.
     First slice: BigWordland takes the seat when no holder is live (the manual rule of §8.3, automated), so the hacker
      room can save Wafts and `.g`.  Needs the seat's liveness ping — the "two of you" hazard is the same problem.
2. **The compile authority off Editron** (§8.2 B, its "Later — Atheory's" made first): Editron is not awake, so the compile
    holder is headless — LocalGen's real translator in node, behind the dev server, answering `ghost_compile` tickets as
     `seat:compiler`, verdict by corr.  Wordland saves; the compiler compiles; nobody compiles the spine it rides.  Editron
      becomes a fallback holder of the same seat.
3. **Viewports** — Langui shows several docs at once, each a viewport you grow, shrink and rearrange.  The layout is
    particles (one per viewport, under the room), each viewport an Interest; Lang already arbitrates several givers for the
     one LE (§6), so the step is from "one foreground" to "several visible, one with the keys".
4. **Editron retires to fallback** — kept stable, honours the seat, otherwise left alone.

**Step 1 landed (2026-10-27, unverified live).**  `relay.ts` holds named seats (`editor`, `compiler` reserved) on a socket:
 `{control:'seat', want, take?, who, why}` → `seat_ok` | `seat_taken` (the asker waits, and hears `seat_free` when it frees) |
  `take` wrests and the old holder hears `seat_lost`; `{ask:'who'}` reads it.  Liveness is the relay's existing ping round —
   a closed or half-open holder is dropped and the seat frees.  Hello-verified sockets only while cluster trust is
    configured (gen_write's posture).  Node proof: scratch `seat-test` against a private relay, 9/9.
 The tab's side (LiesLies `#region seat`) is a **particle**, not a role: `%Seat:editor` on w:Lies — `want:take|free`, then
  `held` or `by:<who>`.  A room with docks plants it at channel-up (`?E=` → take, wresting once per life; hacker → free) and
   asks on every open and `hello_ok`.  `Lies_holds_seat(w)` is true|false once the relay answered, **undefined if it never
    did** — and every gate keeps its OLD behaviour on undefined (`Lies_writer = holds_seat ?? role==='editor'`), so Books,
     runners and relay-less tabs are untouched.  Gated now: typed `.g` saves (`e_Lies_source_write` — refused saves are
      held back and **wrest** the seat; paid on `seat_ok`), Waft saves (`Lies_waft_save` entry — held back, paid when the seat
       comes; an already-throttled save still fires, which is the loser's flush), today's Aside, the create-from-nothing save.
  BigWordland's top bar shows `✍ writes` or `reads` (click = wrest).
 **Not yet on the seat:** the Keep (cursor / resume-last — opening it in the hacker room is its own slice), the Cluster
  claim + `Lies_aim_setup`, compile `dock_source` (step 2's).  A JS-wedged holder keeps the seat (the browser answers pings
   for it) — wresting is the cure; the two-of-you hazard is otherwise this.

**The recipe goes; Ground becomes advice and control** (the owner, 2026-10-27).  A room today is a `Run_A_<Book>` method that
 hand-mints `A:Lies/w:Lies,hacker:1` and stamps `H.c.role` — the role then gates by equality all the way down.  The direction:
  a **Ground that names other Grounds for its code and carries instructions for its A's** — the particles to plant
   (`%Seat:editor,want:free`, the Wafts to open), the elvises to send (as HohoTiles' toc sends `i_elvisto:Lies,e:Lies_open_Waft`
    and Story's `Opt` configures a run) — so a room, and most of a test, is a stack of Grounds someone can go and look around
     instead of a named method.  The seat is built for that: what asks is the `%Seat` particle, not the role, so when a Ground
      plants it the role stamp has one fewer reader.  Next readers to move the same way: `hacker:1`/`editor:1` on w:Lies, the Keep.

**Step 2 re-aimed — a node editor, and code that knows what it is** (the owner, 2026-10-28; nothing built).
- **No seat to compile.**  A `.go` is content-addressed (Ghostmeta = the `.g` dige): two compilers from the same bytes make
   the same file.  The seat guards the TEXT.  LocalGen already compiles in node (it is what Claude compiles with); the
    ticket-to-Editron road in `ghost_compile.ts` is the fragile one.
- **A node editor** — LocalGen + fs — asks for `seat:editor` take-if-free (never a wrest) when no Chrome editor holds it, and
   asks the relay|disk every time: Dexie is a browser luxury.  When Chrome comes back it asks `want:take`; node flushes and
    yields.  Chrome then **reconciles by tree, like git**: a Ground's dige chains its layers (`TheACode:Ground/<Name>` has one;
     `AthePondGround_whole` checks it), Grounds standing on Grounds make the tree, and Chrome compares roots against its
      last-known one, descending only mismatched branches to the `.g` — each a three-way (`%Good` | disk | unsaved buffer),
       a clash a `%TheARefused`-shaped row the merge popover shows (`TheA_seem_merge`'s shape).  The CLI compile becomes one
        of its verbs, and `runner_ask stand <Ground>` (closure in order, then the Ground's plants and elvises) replaces
         per-file `ghost_load --stand=`.  Claude's own disk writes are the unseated case: ask `seat_who` first, `seat:<path>` later.
- **Every function knows its kind — first by stamp, eventually by genesis.**  The House dispatches a few shapes
   (`Housing.svelte.ts` ~1582: `w.sc.w`|`w.sc.method` → method): **w method** `Foo(A,w)` (on `%w:Foo` under its `%A`), **e
    handler** `e_Foo` (reached by an `%elvisto` or an `o_elvis` its w method opens), **req** do_fn, **verbs** table, **recipe**
     `Run_A_<Book>` (going), **helper** `Foo_drive` (its w by prefix — the grouping that already exists).  The links are
      already kept: Atlas's `%Map` has `%def`/`%mint`/`%elvisto` with `via` (the enclosing method — so per call site, filed
       under a method); Ground maps `.g` → Ground.  Missing: `kind:` and `of:` on each `%def`, stamped by the one generator
        (`Lang_map_into`) so Atlas carries it — an m9 bump; what won't classify shows as an orphan.  **Name the rows by the
         prefix, not the argument form:** a call is `%i_elvis:<target>,via:<method>` (that `i_elvisto` takes one argument form is
          incidental — it may become plain `i_elvis`), a handler it opens is `%o_elvis:<type>,via:<method>` — today not
           collected at all (28 `o_elvis` + 3 `o_elvis_req` sites, by grep).  One row per site; the method's set is its `via`s.  **Eventually (spicy):** genesis in the editor — you want a `%w`, hang it on an `%A`, and
         the stub is written already classified, grouped and linked.
- **Everything kept by the editor, not by hand** (the owner, 2026-10-28).  `src/lib/L/everything.js` hand-authors every area,
   Point and Ground tag, and something has to keep it up to date — today that is an AI re-running `wafts_everything.mjs`.
    Aim: the editor keeps the `.g`s, their Grounds and Waft:Everything in sync as it saves — a new method merges in on its own,
     a renamed one moves — so Everything becomes where any extra culture hangs (descs, kinds, the verb and ActionButton
      alignments) rather than a list someone maintains.  No mass verification on save; a sweep can check it all some day.
- **Sphere means a Seem layer** (the owner's correction): how a Seem lays several Spheres — of `n**`, `D**`, `K**` — together
   where they coincide on meaning (Atheory_design §1.12; still in development).  The `.g` ↔ Ground link would be one:
    perhaps `%TheASphere:Grounding` (key and arrangement unruled) — and the Sphere's name could be how we find the code that
     knows the process of having one.  Data plus the code that knows about it: what OOP really is, housed by name.
- **Later: the shape census.**  Every IOing path is a Lezer parse, so one `%Shape:X` per mainkey can be derived (keys, the leg
   it sits under, makers vs readers), with cardinality read off the consuming form (`[0]` at most one, iterated many, `oai`
    exactly one, `[0].sc` unguarded = null fatal).  The yield is contradictions: two makers' key sets under one mainkey, a
     read key no maker writes, a null-fatal read with no maker first.  Authored parameters only as corrections (§12's `%lematch`).


## 12. The guts, reimagined (dwelling, 2026-10-28 — nothing here is built; Story_future grows from it next)

**The order, smallest real thing first.**
1. **A small flock of editors looking around together.**  Each editor's attention is already particles (Interest, Lang's
    focus); share them over the relay as presence.  Splitting work with basic locking, later, is the seat generalised to
     turfs — `seat:<path>` — which relay.ts can already hold (`SEAT_NAMES` is its only fence).
2. **Tendrils between events** — moved to Atheory_todo "Tendrils — consistent eventing": the Turn is the unit of event,
    a pulse carries `from:` its Turn's address, a Turn keeps an `%TheAAte` per pulse, and Story is a `%TheAReader`.  Proven
     by Book first.
3. **A purely Atheory-run UI, small, on Pondland.**  Every arrival goes through `TheA_io`, which already writes the tape
    (`%TheAHeard`) and `TheA_replay` plays it back — so recording comes by construction.  Then Story is adapted to read
     tapes (Story_future).
4. **Regards and the Believer** — after those, below.

**Ids — Atheory already answers most of it.**  It stores no ids: `TheA_pair` pairs rows by OBSERVED identity (a row stands
 in as its Trace sc — kind and name; the name holds still, the kind doesn't count), and `TheA_seem_merge` decides each thing
  against a base and REFUSES a change both sides made differently as a `%TheARefused` row that stays in the snap — the native
   "merge wanted" complaint.  A position, stringified, is the minisnap pointer: `H:Story>H:Hackarium>A:Lies>w:Lies>Waft:Ghost/Net/Easy`
    (`mainkey:value` per level).  The live hole: two siblings with one `mainkey:value` — `o(sc)[0]` picks one silently.  That
     is where to complain (a `%TheARefused`-shaped row), and it wants a Book that hammers pairing and merging.

**Aiming into code for a flock.**  Block ids are invented elsewhere (tree-sitter node paths, Yjs relative positions,
 Unison's content-addressed definitions, git's move detection).  For editors looking around together: (doc path, the
  `%Map` Point's method, line offset within the method) needs no new ids and no renumbering ceremony — the method name is
   the stable part, the offset is local.  Named blocks only if aiming inside long methods turns out to need it.

**Qualities of a quality — reuse `lematch` (later).**  `lematch` (Stuff.svelte.ts:568) is already the matcher snap encoding,
 EntropyArrest's Entcases and `i_scheme_req` use: `matching_any` (sc_has|sc_only), `unless_any`, and `means`.  So a Ground's
  table of qualities is `%lematch` rows whose `means` say `%seen` (skip, munging, dontSnap, spay — all existing), `%kept`
   (Dexie, disk via Wormhole, both, none; on settle|change|idle — new: App_todo §7 says WHAT is durable, nothing yet says
    where|when) and `%known` (whether this family is addressed, and how).  The match is the indirection — a row matching every
     `%Waft` is a `%lematch,sc_has:{Waft:1}`, never a bare Waft line.  (Not "Regard": `%TheARegard` already means an organ's
      opinion of a point on a Seem, Theory.g:805.)

**The Believer (later).**  One `%Belief` per thing meant to be true, holding only the `want`; whether it holds is READ from
 where the answering event is stored, never written twice.  Today's `.c` latches (`Hackarium_stood`, `channel_up`,
  `keep_opened`, `seat_asked`, `loading_wake`) are what it would hold; `%Seat` (§11) is the first built.  The trick: a big
   hidden want becomes one visible belief with a cost (the boot read flood was the Stemdex silently wanting ~200 docs).
 The req machine stays the doer — a req is an interface to continuation and can do anything inside its pass; only `sc.ok`
  ("already ran this pass") is re-armed per pass.  Atheory-era: `%ttlilt` alarms when it runs out, not only expires.
