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
