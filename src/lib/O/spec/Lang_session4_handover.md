# Lang / Lies — session 4 handover (Funkcions + GhostList)

The entry-point doc for the next session. This is current-state. The old session-1/2/3
handovers were chat pastes and have faded; their durable content is folded into the
"Foundations" primer below, into `CLAUDE.md`, and into the standing spec docs. Read
**alongside** (all in this spec dir unless noted):
- `CLAUDE.md` (repo root, loaded every session) — the C/particle data model + the
  subsystem map (House, reqy, Story, Cyto, Matstyle, Text, Lies).
- `Hovercraft.design.md` — the reqy machine (req / maz / sc.ok / ttlilt / do_fn).
- `LiesEnd_spec.md` — the LE / Seem / Understanding checkout model.
- `Waft_spec.md` + `Waft-palmtree-trajectory.md` — the Waft → What → Doc → Point model
  and What transport. **Its top section now holds the Lang↔Lies channel design**: the
  `%Interest` family (Trail|Sidetrack|Ting|GhostList|Testing), the shared cursor, the
  Waft/Funkcion embed model, and the Waft-roster subscription. Read it before touching
  the i|o traffic.
- `reactivity_docs.md` — `H.ave`, versioning, the Stuff/Housing reactivity.
- `NOTATION.md` — the `%Point` / `dock/%Map` / `// <` conventions.
- `StemHive_handover.md` — the stem-cluster methodmap + editor fold UX (the hive the
  GhostList render reuses).

(The old `Lang_Ting_handover.md` — the session-3 archive — has been folded into the
Backlog and Gotchas below and removed.)

This session reworked **how Funkcions are hosted** and built the **GhostList** (a
self-listing, persisted ghost-index Waft) on top of it.

## Foundations — the pieces this area sits on
(Distilled from the now-gone session-1/2 docs + the live code. Depth in the docs above.)
- **C (particle)** — `sc` = scalar children, encoded + persisted; `c` = runtime refs +
  closures, never encoded. **mainkey** = first key of `sc` (the type tag). `o(sc)` finds
  children (value `1` = wildcard, else exact), `oa` is a boolean probe, `oai` is
  find-or-create, `i` creates, `r`/`drop` removes. Creation bumps version; `$effect`/
  `watch_c` react off it. A **snap** is the text serialisation of a C tree.
- **Waft → What → Doc → Point** — the document tree. A **Waft** is a (usually persisted)
  set stored at `wormhole/<path>/toc.snap`; a **What** is a navigable sourcing node; a
  **Doc** names a source file; a **Point** marks a method/region within it.
- **dock** — the per-file editing unit Lang compiles. `dock.c.seek` navigates; the
  compiled method/region index lives at `dock/%Navicade/%Mapule` (kind `def`|`region`,
  `sc.key`, `sc.from`) — the minimap and StemHive feed on that. `%Map` holds name-spans
  (not bodies), used for tap→method resolution.
- **reqy machine** (Hovercraft) — `reqy(host).do()` pumps `req` children by `maz` level;
  `sc.ok` is a pass-local "satisfied this tick" gate (re-armed each `do()`); `eternal`
  reqs never finish; a `ttlilt` says "come back later". A req's do_fn resolves by the
  `req_$name` naming convention (or `doai`). **`req:Store`** (maz:7, eternal) is Lies' IO
  pump — its `req_Store` do_fn runs each tick; nothing else calls a pump.
- **LE / Seem** (LiesEnd) — there is **one** LE, Interest `{LE:1}`: a bounded checkout of
  a giver What's extent into an editable clone tree (origin Seem reads the remote for
  awareness, working Seem holds the clones). Nothing else needs an LE.
- **languinio / `H.ave`** — the shared space both worlds reach. The cross-w pattern that
  matters: **Lies-side host, Lang-side read through `languinio`** (no LE needed); a
  host-local Waft (Ting, GhostList) lives on `w:Lies` and is reachable from Lang.

## How to work in here (unchanged)
- **No runtime here** — `.svelte`/CM/`$lib` can't be executed. Node-check pure logic;
  hand CM/TheC glue to the human to run.
- **svelte-check baseline**: every `H.method` call reports *"Property X does not exist on
  type 'House'"* (House methods are eatfunc-haunted, not statically typed). That, plus a
  few pre-existing `'any'`/`possibly undefined` lints, is the floor. A clean change adds
  nothing beyond it — filter with `grep -ivE "does not exist on type 'House'"`.
- **Edit surgically**; whole-file `{}` counts are unreliable for `.svelte` — check your
  edit delta is balanced.
- **Never commit** — leave changes in the working tree; the human reviews + commits.
- **House mixins** (`Lang*`, `Lies*`): methods on `this` via `M.eatfunc({…})`; cross-house
  calls go by elvis, `H.i_elvisto('Lies/Lies', 'Lies_x', {sc})` → handler `e_Lies_x`.
  `req:$name` reqs resolve their do_fn by the `req_$name` naming convention (`do_fn_for`).

## Funkcions — Lies-side, no LE
A Funkcion is just behaviour on `funk.c.run` (an off-snap closure) riding a Waft
**directly**: `Waft/Funkcion:$name`. No `Seem:workon`, no req inside the Waft, no LE.
- **Central host** — one `Lies/Funkcions` container holds an eternal **`req:Funkcion`** per
  Funkcion. `Lies_register_funkcion(w, host, funk, …args)` spawns it (the Funkcion knows
  its own req); `Lies_pump_funkcions(w)` = `reqy(Funkcions).do()` runs them all once per
  tick from `req_Store` (Phase 2b); `req_Funkcion` runs one Funkcion's `c.run(host, funk,
  …args)` and sets `sc.ok` (re-runs each tick, never finishes, stays inspectable).
- **Keying gotcha (load-bearing)**: the req is keyed `req:Funkcion,funk_id:<waft>/<name>`.
  Do **NOT** key it with `Waft`/`Funkcion` sc keys — those are mainkey type-tags a tree-walk
  reads to detect wafts|funkcions; a req carrying them gets misread (its `c.up` is the
  `Funkcions` container, not `w`) and throws `req~up`, stalling the whole Store pump (this
  bit us once: it killed the Ting's tap-globulation and the GhostList toggle together). The
  waft|funk are `.c` refs (`fr.c.host`, `fr.c.funk`), not sc.
- Phase 2b is wrapped in `try/catch` — a Funkcion error must never stall `req_Store` (it
  gates all the IO below it).
- The **trail** Funkcion (the Ting heatmap) still runs on the *old* LE-hosted path
  (`LE_host_funkcion`, pumped from Lang's `req_workon`) — legacy, works, left alone.
  Migrating it to a `req:Funkcion` is optional cleanup.

## GhostList — the self-listing, persisted ghost index
A `Waft:GhostList` (marked `sc.lists`) that dirlists the ghost pile and renders as a
stem-clustered, navigable tree in the Liesui Waft list.
- **`Lies_ghostlist(w)`** (LiesStore) — returns the loaded `Waft:GhostList`, or kicks
  `e_Lies_open_Waft('GhostList')` and returns undefined while it provisions. It **loads+
  saves like any Waft**: the Waft pipeline owns the container and its `watch_c` auto-saves
  on every change. (Replaced the old `Lies_spawn_ghostlist_waft`, which created the
  container directly — that fought the loader's `place()`.)
- **`GhostList_funkcion(gl, w)`** (LiesStore) — installs `Waft/Funkcion:dirlist`'s
  `c.run` (clearing `walked_at` so a fresh load walks at once) and registers its central
  `req:Funkcion`. The walker lists `src/lib` + `src/lib/O` + every opened dir via
  `LiesStore_listing` (the cross-tick poll idiom), recording per dir a `{group:<dir>}`
  child holding `{sub:<path>}` (subdirs) and `{Doc:<path>}` (source files). `oai` =
  update/add; **no prune** (deleted files linger — by design for now). Throttled by
  `interval_ms`/`walked_at`; bumps the waft only on real change.
- **Newly-noticed glow** — a Doc gets `noticed_at` the first time it's seen *after* a
  baseline walk (`gl.sc.seeded`). `DocGhostList` glows it amber for 24h via StemHive's
  per-id `styles`. Use **`noticed_at`, never `created_at`** (a stripped SESSION_KEY).
- **Persistence** — `seeded`, the `%open_dir` tree, and per-Doc `noticed_at` ride in
  `wormhole/GhostList/toc.snap`. Safe through the Waft pipeline because `Lies_sync_waft_docs`
  is a no-op (Docs aren't auto-loaded/compiled) and the `Lies_waft_mutated` notify is gated
  out by Lang (GhostList is never an LE target).
- **Render — `DocGhostList.svelte`** (mounted via the Waft switcheroo, `is_lister =
  !!waft.sc.lists`, beside the Ting's `is_taker`). Groups indent by path depth and sort by
  path → reads as a tree. Subdirs render first as `▸/▾` chips (click → `e_Lies_toggle_dir`
  adds/drops an `%open_dir`, kicks `think` for a prompt re-walk); files render as a StemHive
  (click → `e:Dock_open` switches the active doc). **Click-to-goto only** — no cursoring.
- **Delete CRUD caveat** — a waft's dot-menu delete (`delete_waft` → `Lies.drop`) only
  drops the in-memory container; it doesn't remove the snap. GhostList therefore
  auto-resurrects (next tick `Lies_ghostlist` reloads it). A real "delete waft + its snap"
  (`e_Lies_delete_waft` dropping the container *and* the snap via rw_op) is unbuilt.

## Open threads / next builds (this area)
- **Lang↔Lies channels + the `%Interest` family — designed (`Waft_spec`), unbuilt.** The
  old "clicks → fork the What" thread resolved into the design: a GhostList/Sidetrack pick
  is an `o Doc` (often `off_what`) over Lang's usual `o What`; flying off opens a
  `%Waft,tentative` whose `Interest:Sidetrack` you cursor into and graft back from. First
  build is the **`Lies_waft_roster` subscription** (the standing req Lies re-delivers to by
  ref — never `finish`ed), then per-Interest lock. See Waft_spec's Interest section.
  **[warm · designed]**
- **Waft taxonomy — folded shut (`Waft_spec`).** The giver/taker/lister flags
  (`active|takes|lists`) stop being the typing; the `%Interest` *kind* is the typing and the
  flag is just the stance it locks onto. Nothing left to design. **[resolved]**
- **All method def|call index** — a global, queryable index of every method definition and
  call site, likely **IndexedDB**. Feeds goto / fork-the-What / the hive. **[mid · cold]**
- **GhostList polish** — prune goners; cascade-collapse deeper opened dirs when a parent
  collapses; a faster `ttlilt` for GhostList listings (the ~1.6s beat before a newly-opened
  dir fills in is the wormhole re-check interval). **[low · cold]**
- **Pmirror non-resolution is silent.** Lang doesn't notice or surface that some Pmirrors
  fail to resolve — they only emit console warnings. Give it a noticing/UI. **Check once the
  current channel refactoring settles.** **[bug · deferred]**

## Backlog — carried items (folded from session 3)
Tagged **[weight · intensity]**: weight = how much it matters; intensity = how live it is.
Scrapped lines (multiplied-LE / the `Undertaking`) are gone, not carried.

- **Trail Funkcion + heatmap — legacy, working.** Taps globulate onto `%Point:method` in
  the taker Ting; a Funkcion derives decayed `heat`/`bright`; the minimap glows amber where
  you've been. Still on the *old LE-hosted path* (`LE_host_funkcion`, pumped from Lang's
  `req_workon`), not the central `req:Funkcion` — migrating it is optional cleanup.
  **Load-bearing**: `Mapule.c.bright` and `Lang_trail_brights` must key the same
  `${region} ${key}` template or the heatmap silently goes dark. **[mid · stable-legacy]**
- **Trail polish.** Region bands should glow from their own region-level globule, not the
  *sum* of their defs; tint by recency vs frequency (held/long a different hue). Long-tap
  `{say}` articulation (mark exists, no note child). Method-less taps don't reach a region
  yet (`%Map` has name-spans, not bodies). **[low · warm]**
- **E. Goto fold-policy "thus-crunchy" (remainder).** Unfold the target's ancestors (done)
  AND fold the rest per Q (not done) — the fold-around-target half. Overlaps Waft_spec's
  `depth`→`%openity` story. **[mid · warm]**
- **C. Active Pmirror + What recentre.** Double-click a Pmirror → primary/active (Points lay
  out evenly); click the What title to recentre; the active NaviCado pops a controls cluster
  (PeelInput, the generic add/edit form). Drive through the Waver. **[mid · cold]**
- **A. LangPoint must be mounted** for `e:Lang_climb` / auto-Q to fire. **[mid · cold]**
- **H. Cytui onto the Waver.** Map Cytui's `cyto_graph.sc.waves` drain/apply/rush onto
  LangPoint's `Lang_wave_enqueue/_step/_rush`; extract the kernel. The Cyto float above the
  Interest switcher (Waft_spec) is a fresh reason to want this. **[low · cold]**
- **F. Bookmarks → Seem:working.** A named bookmark should drop its `%Point:name` into
  Seem:working as NaviCado's `peel_commit` does ("old code over there"). Relates to the snap
  nesting migration below. **[low · cold]**
- **G. Attention heatmap — data + minimap render DONE.** Left: on-screen line visibility as
  a lightest decaying tap source; edits as the heaviest source batched into one sweep;
  history as a replayable streak (the Ting is the record; replay unbuilt). **[low · cold]**
- **DocCompost / PNG capture — shelved.** The frozen-frame clone + scribblespace was good,
  but PNG/screenshot is whack under software rendering (foreignObject won't rasterise, drops
  scoped CSS + web-fonts). Parked, off every critical path; may roar back (scribbles later).
  **[low · dormant]**
- **Scribble-ball.** Replace folded guts with a scribbley-ball graphic promoting a few key
  expressions out (needs invisible folds + `%Map` call/def entries). Pairs with PNG overlay.
  **[low · dormant]**

## Gotchas (still live)
- **Snap What/Doc/Point nesting migration — open.** Persisted snap is Waft→What→{Doc,Point};
  some in-memory code still nests Point under Doc (Lies.svelte ~546/698 vs ~606/652).
  Resolve before relying on the snap round-trip for Points; relates to bookmarks (F).
- **enWaft is relaxed; refs are fatal.** The vocabulary gate (mainkey ∉ Waft|What|Doc|Point)
  is parked as a re-armable commented relic — any mainkey encodes now. But a C reachable from
  >1 place pushes a fatal complaint (refs belong in `.c`, not the snap tree). Keep tap/Ting
  data scalar.
- **`%Map` has name-spans, not bodies.** Tap→method resolution uses "nearest header at/above
  the tap line" as the body bound — good enough for globulation; precise containment is a gap.
