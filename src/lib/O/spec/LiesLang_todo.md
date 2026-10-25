# Lies|Lang — the editor machine, put together

The editor machine is two ghost families and the faces over them.  **Lies** holds and moves documents: it opens Wafts, reads
 and writes files, compiles a doc into a `.go`, ships it to a runner and hears back.  **Lang** is the language and the
  attention: the `.g` grammar, the docks, CodeMirror, the cursor's "understanding" of what you're looking at.  They meet in
   the **Waft** — a tree of What → Doc → Point that names code — and in the **Interest**, Lang's handle on a Waft that Lies
    holds.  It works.  This doc is not a plan to rebuild it (owner, 2026-10-25: *"it's about right, I just want it to all be
     put together more coherently"*) — it is the one map, linking the narrower docs and the long file headers that already
      say each part well.

## 0. What to get on with next

1. **"No wafts" in the hacker room — not explained yet.**  /BigWordland opened `Waft:Ghost/Net/Easy` on both boots of
    2026-10-25 (console: `🗂 Waft:Ghost/Net/Easy opened`), then the `Waft:` particle was gone from w:Lies with no log line,
     leaving its `Good,type:text/Waft` and `Funkcions/req:Waftica` behind — exactly what `e_Lies_close_Waft`'s "minimal
      close" leaves (`Lies.svelte` ~:190).  Only two things drop a Waft: that close (fired by the Interest strip's ×) and the
       Lies panel's delete (`Liesui.svelte` `delete_waft`).  Both now log (`🗂 Waft:X closed — the Interest strip ×` /
        `🗂 Waft:X deleted from the Lies panel`).  Next time it happens, the console says who.  If neither logs, something
         else replaces w:Lies's children — then follow `w.place`/`replace` in `Stuff.svelte.ts`.
2. **The hacker room now opens Waft:Everything too** (`Hackarium.svelte`, 2026-10-25), beside its area Waft.  Nothing opened
    it before, anywhere.
3. **Close should finish the job**: GC the orphaned `Good` and the `Waftica` carrier (its own comment calls this "a separate
    follow-up").  The debris is what made (1) hard to read.
4. **The first Atheory seam** (§9): the `%GhostInclude` shelf + `CREDULER_GHOSTS` are a hand-built TheACode/Ground.
5. Diagrams owed in §3–§5 (the req stack per tick; doc → .go; a keystroke → a particle).

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
