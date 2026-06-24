# Lang — the base layer

< this doc eventually becomes Lang_doc

The Lang machine is the **base layer** of editing in jamsend: a CodeMirror editor over a tree of
 documents, a compiler that turns each document into an *index* (and, for `.g`, a runnable
  module), and a fold/navigation model that reads back through that index. Everything ornate
   rides on top of this — Editron ships the *authority to run* a compiled `.g` across origins
    (`Editron.md`); Lens hoists UI over it; Interest threads the cursor through it. This doc is
     the layer *underneath* all of them: what a dock is, how it compiles, how the pieces divide
      the labour, and the one structural seam (`dock.c.state`) that is the source of the editor's
       recurring bugs. Written at a resting point — the base is built and runs; the seam (§7) has
        now been **cut** (role #2 + #3, headless-verified, browser-verify pending — see §8).

**One sentence.** A `dock` is one document open in CodeMirror; compiling it walks its syntax tree
 into `%Compile/%Map` (regions + points), which fans out to a minimap, a fold model, and — for a
  `.g` — a generated `.go`; navigation and folding then resolve stored offsets back against the
   document.

---

## 1. The shape — the loop the whole base layer runs

```
edit ─▶ EditorState (dock.c.state)  ─compile▶  %Compile/%Map  ─┬─▶ MapReport   (minimap counts)
        ▲ display = view.state                                 ├─▶ Navicade/Mapule ─▶ DocMinimap
        │                                                      └─▶ (.g only) render → .go → Lies
        └────────────── fold / point-nav resolve offsets back ◀────────── %Map
```

Three codetypes flow through the same loop with different exits (`Lang_points_only`,
 `compile.ts:125`):
- **`.g`** (stho) → GEN: translate to TS, render a module, write a `.go`. The original payload.
- **`.ts` / `.svelte`** (tsstho) → SOFT: build `%Map` of method/call defs, write nothing.
- **`.md`** (markdown) → SOFT: build `%Map` of the heading TOC, write nothing.

A path that is none of these (a `.png`) indexes to nothing and the compile reqs no-op on it.

## 2. The pieces — who does what

The Lang ghost is split so `Lang.svelte` stays a *join* and the guts grow elsewhere. All deposit
 methods onto `H` via `M.eatfunc()`.

| Module | Size | Owns |
|---|---|---|
| `Lang.svelte` | 157K | the join: per-dock lifecycle, the compile **req-stack** (`req:compile` maz:2, `Lang.svelte:1876`), `Lang_Map_report` + `Lang_build_mapules`, the Interest tie-in, **the single `dock.c.state` writer** |
| `Langui.svelte` | 115K | the CodeMirror **view** — one `EditorView`, a per-path `EditorState` cache ("Option B", its own head comment), bake/reconfigure of the language compartment, doc-switch |
| `LangCompiling.svelte` | 29K | `Lang_compile_dock` (collect→render→dig→stamp), `Lang_compile_source_state`, settle-drain |
| `lang/compile.ts` | 105K | the translator + collectors: `Lang_compile_collect` (stho/tsstho), `Lang_collect_markdown_regions`, `Lang_full_tree`, `Lang_render_module` |
| `LangRegions.svelte` | 32K | region parsing, **Point resolution**, fold-based "openness" |
| `LangPoint.svelte` | 23K | the Q-factor: indent blocks, fold targets, the read-focal crunch |
| `LangGraft.svelte` | 42K | graft (surgical Map/region grafting — EntropyArrest-adjacent) |
| `LangWhatwhere.svelte` | 34K | `whatsthis` — bookmark span → syntax-tree dump |
| `LangLang.svelte` | 9K | the language-picker dropdown + parser-generation affordance |
| `LangSion.svelte` | 19K | runtime helpers for `IOing` expressions the translator emits |
| `lang/registry.ts` | — | static language map (`stho`, `tsstho`, `markdown`); adding a language is a code edit |
| `lang/lang.ts` | — | `lang(name)` → the extensions array `EditorState.create` wants; theme + highlight + linter |

## 3. The dock model

A **dock** is a particle `{dock: <path>}` under `w:Lang`. One document, one dock, keyed by path.

- `w.c.active_dock_path` — a cheap **routing string** (not business state, not `r()`'able,
   `Lang.svelte:155`). `Lang_active_dock(w)` resolves it to the dock particle (`:421`).
- `dock.c.view` — the live `EditorView` (Langui owns it; the view is shared, the *state* swaps).
- `dock.c.state` — the `EditorState`. **Written in exactly one place**: `Lang_dock_from_event`
   (`Lang.svelte:413`, `if (e.sc.state) dock.c.state = e.sc.state`). Stamped from a
    `Lang_i_elvis(view, 'Lang_compile', …)` carrying `state: view.state`. This single writer is
     the good part of the design; §7 is about its many *readers*.
- `dock.c.content_dige`, `dock.c.q_folds` — content hash (compile keying) and our own fold ledger.

## 4. The document tree — what the index points *into*

Docs live in a `Waft` tree: `Waft → What* → (Doc | Point*)`, nesting unstrict
 (`Text.svelte:353`, `WAFT_PROTOCOL = Waft|What|Doc|Point`, each `omit_sc: SESSION_KEYS`). The
  design lives in `Waft_spec.md`; `LiesEnd_spec.md` has the tight schema. A **What** is a topic, a
   **Doc** is a concrete file/blob, a **Point** is an authored location *in* a Doc. A What may hold
    several Docs (`multiDocWhat`); a click picks the alpha Doc (`what.c.alpha_doc`,
     `multidocwhat-chosen-doc` memory).

The compile index is how a Point binds to a place in text: `%Map` regions carry absolute
 `from/to` plus region-relative `rel_from/rel_to` and a `c.abs_*` cache (`map-rel-offsets`
  memory), so a Point survives edits above it. **This is the seed of the right answer to §7's
   role #3** — offsets resolved against the state the Map was built on, not against whatever the
    editor holds now.

## 5. The compile pipeline

Driven by the **req-stack** (`Lang.svelte:1779` lists the maz levels). `req:compile` (maz:2,
 reqonce, text-keyed) runs the synchronous index build once per text version:

```
req:compile ─▶ Lang_compile / Lang_compile_dock        (LangCompiling:229 / :258)
                 │  source = stateOverride ?? dock.c.state     ← §7 lives here (:268)
                 │  parser-gate: refuse if no lang parser wired (:304)
                 ├─ .g     : Lang_compile_collect → render module → esbuild gate → .go → Lies
                 └─ soft   : Lang_collect_markdown_regions  (md)   → %Compile/%Map
                            Lang_compile_collect             (tsstho) → %Compile/%Map
                 ▼
        Lang_Map_report(w, dock)        → %Interest/%MapReport  (n_region, the minimap counts; Lang:1411)
        Lang_build_mapules(w, dock)     → dock/%Navicade/%Mapule (the Mapulen; Lang:1467)
                 ▼
        DocMinimap reads dock/%Navicade only — bands carry their Mapule; a click is
          mapule.c.goto()|fold(); pointed Points lit via Mapule.c.is_pointedat (DocMinimap:14,218)
```

Two facts that bite (both fixed downstream this session, see §8): the **instrumentation sig**
 that gates the report/mapule rebuild must include `%Compile.version`, or a same-text reparse
  (e.g. a parser switch) leaves Navicade/MapReport stale (`Lang.svelte:865`); and the minimap
   subscribes via `void lang_dock?.vers`, so `Lang_build_mapules` must bump the **dock**, not
    only the navicade child.

## 6. Openness — fold as the reading surface

Regions (from `%Map`) drive folding. `LangPoint`'s **Q-factor** decomposes the live doc into
 indent blocks and folds away everything but the section around the Point you're reading, growing
  surviving headers as bodies vanish — "the crunch recedes *around* the point instead of sliding
   the doc off-screen" (`Lang_apply_Q`, `LangPoint:327`). We track our own folds on
    `dock.c.q_folds` so the climb never fights a manual fold. Note this is a **display**
     operation — it dispatches onto `dock.c.view` — which is exactly why §7 says it should read
      `view.state`, not the compiled snapshot.

---

## 7. The seam — the EditorState's indifferent realm of servitude

One `EditorState` on `dock.c.state` serves three masters and does not know it serves more than
 one. It answers a display read, a compile read, and an offset read with the same bytes and the
  same parser — indifferent to the fact that each caller wanted a *different* guarantee. **Every
   recurring editor bug is that indifference seen from a new angle.** This is the live work; §1–6
    are the ground it stands on.

### The three roles `dock.c.state` is secretly playing

1. **Display** — what CodeMirror shows. Properly `view.state`, always live.
2. **Compile source** — the bytes + parser to *index*. Wants an explicit state that owns its own
    parser (`lang(path)` from the registry), decoupled from the display buffer.
3. **Index oracle** — the state offsets resolve *back* against. Wants the frozen snapshot the
    `%Map` was compiled against, or `rel_*` offsets drift as you type.

And role #3 is really **two** roles: **3a live-structural** (folding — a *display* op that wants
 `view.state`) and **3b Map-anchored** (point-nav / whatsthis — wants the frozen snapshot).
  Conflating 3a and 3b under one object is its own latent bug.

**But this is two states, not three.** #2 and #3 are the *same object* — the frozen snapshot the
 Map was compiled against (call it `stateCompiled`). So the whole machine holds exactly two
  EditorStates: `view.state` (live, moves every keystroke) and `stateCompiled` (frozen at last
   compile, **the Map's coordinate frame** by definition). A Map offset is *born* in
    `stateCompiled` coords; a reader that wants to interpret one reads `stateCompiled`. That is
     the easy half — no translation, just read the right object.

### Four masks, one seam

| Mask | Where it bites | The fusion underneath |
|---|---|---|
| Language-reconfigure lag | a `.md` compiles as `stho` until you Esc | compile read the display state *before* its parser compartment reconfigured |
| Channel one-round-lag | a `ghost_compile` compiles the *previous* edit | `dock.c.state` lags the async CodeMirror reseat; band-aided by building from disk `text` |
| Remote compile mounts a dock | `force_active` / dock-switch (`Lang:1245`) | "there is no headless compile" — role #2 is unreachable without role #1 |
| First-open extra step | open a `.md`, minimap shows one row, needs a nudge | the first compile indexed a not-yet-markdown state; the "extra step" is the *second* compile |

**The `#` that proves the last one.** `Lang_collect_markdown_regions` *strips* the heading marker
 (`label = …replace(/^\s*#{1,6}\s*/, '')`, `compile.ts:198`). A region it built reads
  `Peeroleum spec`, never `# Peeroleum spec`. The single minimap row you see *with* the `#` is the
   empty-Mapules **fallback** rendering the doc's first raw line — proof that on first open the
    markdown regions are **zero**, because role #2 indexed a state that wasn't markdown yet.

### Why the half-measures don't save you

The decoupling is *partially* built, which is why it half-works and confuses:
- The **normal** compile path reads `dock.c.state` **raw** (`LangCompiling:268`); only the
   channel/`force_active` path uses `Lang_compile_source_state`.
- `Lang_compile_source_state` (`LangCompiling:218`) builds fresh from `lang(path)` **only when no
   editor is mounted**; mounted, it *reuses the display state's parser* (`:219-220`).
- `Lang_full_tree` (`compile.ts:139`) forces a *complete* parse — but with the **display state's
   parser** (`state.facet(language).parser`). Fullness can't help if the grammar is wrong. (It
    still correctly fixes the off-view length-0 lazy-tree case it was written for — keep it.)

### The realm of servitude — every reader, what it holds, what it wants

| Reader | Site | Role | Should hold |
|---|---|---|---|
| `Lang_compile_dock` | `LangCompiling:268` | #2 compile source | own source state, `lang(path)` parser |
| `Lang_compile_source_state` | `LangCompiling:219` | #2 | always `lang(path)`, never the compartment |
| parser-gate (`req_compile`) | `Lang:1916` | #2 | the source state |
| `Lang_apply_Q` (fold) | `LangPoint:329` | **3a live** | `view.state` — it dispatches onto `view` |
| region fold / offset | `LangRegions:459,505,631` | **3b anchored** | the compiled-against snapshot |
| whatsthis / bookmark dump | `Lang:2166` | 3b | the compiled-against snapshot |
| text read | `LangLang:161` | #1 | `view.state.doc` |
| Story-open monitor | `Lang:1732,:1849` | presence probe | unchanged (only tests existence) |

### The staleness contract — what you must NOT build

The scary version of this cut is a position-mapping layer of your own: keep the Map in compiled
 coords and thread a `from,to` change-map into every reader that touches the live doc. **Don't.**
  The design already delegates the syncery two ways, and the cut's job is to lean on them, not
   replace them:

- **Recompile-on-settle closes the big gap.** `req:compile` is text-keyed reqonce, so the Map is
   rebuilt every settled edit and `stateCompiled ≈ view.state` almost always. The only window
    where they diverge is an *un-settled typing burst*. The `rel_*`/`abs_*` work already committed
     to this — re-derive offsets each compile rather than map-on-read. The cut finishes that
      commitment; it does not open a new front.
- **CodeMirror closes the small gap for free.** Folds, point decorations and graft marks live in
   **StateFields whose `.map` remaps `{from,to}` through every transaction** — see
    `Lang_update_grafts` (`LangGraft:597`) *receiving* already-mapped `{id,from,to}`. You never
     hand-roll a ChangeSet for the live surface; CM does it.

So the real obligation the split adds is a **contract, per reader, of who may be stale** — today
 invisible because everyone reads `dock.c.state`, which is all three frames smeared into one:

- **Offset *readers*** (jump-to-heading nav, `LangRegions`/whatsthis) may be lazy — a few chars
   stale during a burst is invisible. Repoint them at `stateCompiled`; it always matches the Map.
- **Offset *writers*** (graft marks, point decorations, region folds — all dispatched by
   `{from,to}` onto the view in `LangGraft:464,470,524,720`) must dispatch Map offsets **while the
    view still equals `stateCompiled`** (i.e. right after compile) and then let CM's StateField
     mapping carry them through the burst. Dispatch a Map offset onto a view that has *already*
      drifted and CM faithfully maps the **wrong** placement — silent, looks like "the highlight
       sits a few chars off." This writer/reader line is the only place the cut can corrupt
        anything; it lives on the `LangPoint`/`LangGraft` side, not the `LangRegions` read side.

### The cut — bounded blast radius

**Plumbing (2): both landed.** (1) `Lang_compile_source_state` now builds a source with the
 `lang(path)` parser for *every* compile, not only headless — first compile correct regardless of
  reseat timing, and remote compile stops mounting a dock. It takes the cheap form (below): reuse
   `dock.c.state` when its grammar already matches (a doc-swap transaction, byte-identical to before
    on the happy path), synthesize a fresh state only on a genuine parser mismatch. The match test is
     `Lang_state_lang_is(state, want)` (`compile.ts`) — positive grammar identity, so it can never
      *false-positive* into reusing a wrong-parser state. The normal path in `Lang_compile_dock` now
       routes through it instead of reading `dock.c.state` raw. (2) `job.c.source_state = state` is
        stamped at compile (`LangCompiling`), now the live anchor the role-#3 readers resolve against
         via `Lang_index_state(dock)`.

> **Perf caveat on step 1 — don't `EditorState.create` per settle.** The compile runs on every
>  settled keystroke; a fresh whole-state build there would re-detonate the boomerang latency
>   (`compile-boomerang-latency` memory). The cheap form is what `Lang_compile_source_state`
>    already half-does: *reuse the mounted state's doc, swap only the language compartment* to
>     `lang(path)` when it doesn't match — a `reconfigure` transaction, not a `create`. Build a
>      genuinely fresh state only on the headless branch (no view). Equivalently: stamp
>       `dock.c.state` itself as `source_state` whenever its parser already matches the path, and
>        only synthesize when it doesn't.

**Repoints (~5): landed.** 3b readers → the compiled-against frame via `Lang_index_state(dock)`
 (`= job.c.source_state ?? dock.c.state`): `Lang_def_at_offset` (`LangRegions`), the tap
  (`e_Lang_tap`), point-nav (`e_Lang_point_navigate`), and the whatsthis dump (`Lang.svelte`). 3a +
   text → `view.state`: the Q-fold (`LangPoint`) and the parser-gen text read (`LangLang`). The
    `req_compile` parser-gate (`Lang:1916`) is left in place but is now belt-and-suspenders — it
     guards "no parser at all", not "wrong parser", because the compile rebuilds on `lang(path)`
      itself (comment updated there).

**Where the residual risk lives — and why it stayed small.** The scary failure was offset drift on
 the first keystroke after a compile. It didn't materialize, for a structural reason: plumbing-1
  *reuses the mounted doc* (only the parser may be synthesized), so `source_state.doc` is the **same
   text** `dock.c.state` held at compile — the 3b readers that only do `doc.lineAt`/`doc.length`
    (`Lang_build_regions` is text-based, no parse tree) get identical answers either way today; the
     repoint just pins them to the Map's frame so they *stay* correct if the frames ever diverge. The
      only behavioural deltas are strict improvements: whatsthis now dumps with the **right parser**;
       fold + gen-text now read the **live** buffer instead of the ~debounce-stale one. No offset
        *writer* was touched (graft/decorations ride CM's StateField `.map`, untouched), which is the
         only place the cut could have corrupted placement.

## 8. Next move + current uncommitted state

**The cut is landed (role #2 + role #3).** Both plumbing steps and all ~5 repoints are in the
 working tree, type-clean (no new svelte-check errors at the edited lines; `compile.ts` — the only
  file with genuinely-typed additions — is wholly clean). Files touched: `compile.ts`
   (`Lang_state_lang_is` + `Lang_index_state` helpers), `LangCompiling.svelte`
    (`Lang_compile_source_state` rewrite + `Lang_compile_dock` source routing), `LangRegions.svelte`
     (×3 reader repoints), `LangPoint.svelte` (fold→`view.state`), `LangLang.svelte`
      (gen-text→`view.state`), `Lang.svelte` (whatsthis→`Lang_index_state`, parser-gate comment).

**Verified headless.** `node scripts/LakeRace.run.mjs` (3/3 pass) exercises the rewritten
 `Lang_compile_source_state` on real `Peeroleum.g` across both branches — WARM (stale buffer + fresh
  disk text → reuse-and-swap-doc) and COLD/headless (no editor → synth on `lang()`) — plus the full
   `force_active` recv path. So the `.g` path (the one that writes a `.go`) is proven through the cut.

**Next move — browser-verify on `:9091`** (the part LakeRace can't reach — it can't mount CodeMirror):
- **The first-open extra step (mask #4).** Open `Peeroleum_spec.md` cold → the minimap should fill
   with the heading TOC on the **first** compile, no second nudge, and no `# `-prefixed fallback row.
- **The 3b bookmark round-trip (the guarded risk).** Drop a bookmark, compile, type *above* it, jump
   to a Point/tap — must still land on the right span (offsets must not drift post-compile).
- **Fold + lang-gen** still behave (now reading `view.state`).

**Diagnostics removed.** The `md_parser`/`md_heads`/`md_kids` TEMP stamps in
 `Lang_collect_markdown_regions` (the instrument that proved the first-open diagnosis) are now
  stripped — the cut makes them moot. The first-open verify above is therefore purely visual (TOC
   fills on the first compile, no `#`-fallback row), no snap field to read.

**Also in the tree from earlier sessions** (downstream reactivity, not this cut): `Actions.svelte`
 lang-dropdown reactivity; `Lang.svelte` instrumentation `n_sig` += `%Compile.version`;
  `Lang_build_mapules` `dock.bump_version()`. All left in the working tree (**commits are the
   human's job**).

**Adjacent reading:** `Editron.md` (the channel/runner layer that rides *on* this), `Waft_spec.md`
 (the document tree), `map-rel-offsets` + `nong-pointing` memories (the offset/TOC work),
  `Langui`'s own "Option B" head comment (the per-path EditorState cache this seam extends).
