# Lang / Point / Minimap — session 3 handover

Successor to sessions 1 and 2. Those stand; this records what session 3 changed and
what's still open. On reset, hand the assistant the **session-1** doc (data model +
the pieces table) and **this** one (current state + the next builds). The session-2
doc is mostly folded in below, but keep it for the Mapule/Navicade build detail and
the fold-marker (RefoldWidget / marked-vs-invisible) decisions.

This session built a whole vertical: a frozen-frame code overlay (DocCompost), an
attention tap-log that globulates onto `$region/$method` Points in a transient taker
Waft (the Ting), a multiplied LE (Interest|Undertaking, one name per reason), a
Funkcion-hosted req that brightens a trail, and the trail painted as a heatmap over
the minimap.

---

## Status update (supersedes parts of §1, §4, §5)

What was built stands as a record below, but the direction has moved on:

- **DocCompost / the PNG-overlay capture is shelved.** The frozen-frame *clone* and
  scribblespace clicks were interesting, but the **PNG/screenshot taking is whack** —
  it doesn't rasterise under software rendering, drops scoped CSS + web-fonts, and the
  live-capture fallback lags the machine. So Compost is parked: not mounted, not on the
  critical path, no `dock.c.compost` arming expected. It may come **roaring back** (the
  reveal/scribblespace idea is still good — *scribbles later*), but nothing soon should
  depend on it. Treat every "DocCompost must be mounted" / "fly-in" note below as dormant.

- **`{LE:'Undertaking'}` is dropped.** Multiplying the LE to hold the Ting turned out
  pointless — a one-way "where we've been" LE earns nothing. The Ting itself is the
  record. **Interest `{LE:1}` stays** (the real two-way checkout, ~11 readers). Read the
  "Undertaking" passages below as historical.

- **Funkcions don't do LE at all — they live in Lies.** LE is only the main giver Waft
  being checked out to Lang. A Funkcion is behaviour on `c.run` riding a Waft **directly**
  (`Waft/Funkcion:$name` — no `Seem:workon`, no req inside the Waft). Its hosting req lives
  centrally in **`Lies/Funkcions`** as an eternal **`req:Funkcion,funk_id:<waft>/<name>`**
  (keyed by a plain `funk_id` scalar — NOT `Waft`/`Funkcion` sc keys, which are mainkey
  type-tags a tree-walk reads to detect wafts|funkcions and would throw `req~up` on; the
  waft|funk are `.c` refs). The Funkcion spawns|knows its own req (`Lies_register_funkcion`),
  the central pump runs them
  all (`Lies_pump_funkcions` → `reqy(Funkcions).do()`), and `req_Funkcion` runs one per pass
  and sets `sc.ok` (re-runs each tick, stays inspectable). Keep it simple — complicate later.
  The "Multiply LE — one name per reason" idea (§ below) is **scrapped**; the trail Funkcion
  still works on its old LE wiring but that's the legacy path, not how Funkcions arrive now.

- **RefoldWidget is fine** — the TS parameter-property fix below holds, nothing pending.

### BUILT — the Waft:GhostList ghost-index Funkcion

A **Lies `Waft:GhostList`-hosted Funkcion that dirlists the ghost pile.** As built:

- **`Lies_spawn_ghostlist_waft(w)`** (LiesStore) — a singleton `Waft:GhostList`, marked
  **`sc.lists`** (the lister mark): a transient UI index, never persisted (`Lies_waft_save`
  short-circuits on `takes || lists`). It **dirlists itself into existence** each load, so
  there is nothing to save. (Nothing to do with LE — LE is only the main giver Waft being
  checked out to Lang; the GhostList just resides in its own Waft in Lies.)
- **`GhostList_funkcion(gl, w)`** (LiesStore) — installs `Waft/Funkcion:dirlist` (no Seem)
  whose behaviour rides **`funk.c.run`** (off-snap closure) and registers its central
  `req:Funkcion` (`Lies_register_funkcion`). The walker lists
  **`src/lib` and `src/lib/O`** (shallow — the deeper subtrees are rarely looked at) via
  `LiesStore_listing`, one **`%Doc`** per source file under a **`{group:<root>}`** child:
  the `GhostList/<root>/<file>` pattern. Throttled re-walk (`interval_ms`, `walked_at`)
  keeps it fresh; Phase 3's drop of the finished listing reqs re-arms the next walk.
- **`Lies_register_funkcion` / `Lies_pump_funkcions` / `req_Funkcion`** (LiesEnd) — the
  central host: one `Lies/Funkcions` container holding an eternal `req:Funkcion` per
  Funkcion, pumped together each tick from `req_Store`. No LE, no Seem.
- **Render — `DocGhostList.svelte`** via the **Waft switcheroo** (`is_lister =
  !!waft.sc.lists`, beside the Ting's `is_taker`). One **StemHive per group**, so the
  `Lang*`/`Lies*` families fold onto shared stems (the MiniMap's clustering, reused).
  **Click-to-goto** only — picking fires `e:Dock_open` to switch the active doc; you
  don't cursor around it (it's an index, not an editable surface), so no tap globulation.

Directories are listed too (sorted first), each clickable to open|collapse into its own
group (`e_Lies_toggle_dir` adds|drops an `%open_dir` child; the walker lists every root +
opened dir). So it's a navigable tree, not just two flat listings.

Newly-noticed glow (BUILT, in-session): the walker marks a Doc `noticed_at` the first time
it's seen *after* a baseline walk (`gl.sc.seeded`), and `DocGhostList` glows it amber for
24h via StemHive's per-id style. `noticed_at`, NOT `created_at` (which is a stripped
SESSION_KEY). For "noticed since last session" it needs persistence (below) — without it,
`seeded` resets each load so nothing has a baseline to be newer than.

Persistence (BUILT): GhostList **loads+saves like any Waft**. `Lies_ghostlist` no longer
spawns a container — it kicks `e_Lies_open_Waft('GhostList')` and returns the loaded one
(marking `sc.lists`), so the Waft pipeline owns it and its `watch_c` auto-saves on every
change. `seeded`, the `%open_dir` tree and per-Doc `noticed_at` ride in the snap. The
walker brings fresh scans in over the top (oai = update existing, add new) and **does
nothing with goners** (no prune — a deleted file lingers in the index). Safe because
`Lies_sync_waft_docs` is a no-op (Docs aren't auto-loaded) and the `Lies_waft_mutated`
notify is gated out by Lang (GhostList is never an LE target).

Threads left open on it:
- **Clicks → fork the What + add this Doc** (re-architecting). Today a pick only
  `Dock_open`s. The intent: the GhostList should do a bit of **`o Doc`** over the top of
  Lang's usual **`o What`** — needs the i|o channels Lang is growing with Lies. Likely lands
  with a **`%Waft,tentative`**: a lighter exploration Waft the cursor flies into for these
  trips (peer of the Ting), and when an exploration settles you bring this-and-that back
  into the main `%Waft` you cursor through. Design "a natural thing to do when you fly off
  to investigate a method."
- **All method def|call index** (TODO). A global index of every method definition and call
  site, somewhere queryable — likely **IndexedDB**. Feeds goto/fork-the-What and the hive.
- **Waft taxonomy (needs design — but it's all Lies, no need to be too elegant).** Right
  now the kinds are ad-hoc marks: a giver (`Waft:Look`, persisted, `sc.active`), the taker
  (`Waft:Ting`, `sc.takes`), the lister (`Waft:GhostList`, `sc.lists`). Open questions:
  is the cleaner shape to mark the **one** primary, navigation-sourcing, creative-control
  Waft (and let the rest be non-sourcing by default)? And should a kind be a relation
  rather than a flag — e.g. the Ting saying `%takesAwarenessFrom:Lang`? Unresolved; "I
  just want these things" — keep it working, tidy the taxonomy later.
- **Prune** sub|Doc entries whose dir|file has vanished, and collapsing a parent should
  cascade-collapse deeper opened dirs (their groups currently linger).

This is the concrete landing for the carried **doc-switcher index** idea (§4).

---

## 0. How to work in here (unchanged, re-stated)

- **Uploads lag the live codebase.** Trust the running snap/console over an uploaded
  file when they disagree; re-read before assuming.
- **No runtime here.** Svelte/CM/`$lib` can't be executed. Validate pure logic in node
  (this session: the click hit-test, tap-density→Q, the globulate upsert, and the
  trail-Funkcion heat/bright math were all node-checked). Keep CM/TheC glue idiomatic,
  hand it over for the human to run.
- **Edit surgically, never regenerate whole files.** Targeted replacements; re-check
  delimiter balance against the original — every opener-delta must equal its closer-
  delta. NOTE the whole-file `{}` count is an unreliable balance check for `.svelte`
  (template `{…}` expressions + CSS braces make Lang.svelte read "imbalanced" in its
  original form). The meaningful check is that your **edit delta** is matched pairs.
- **Uploads are read-only.** Write edits to `/mnt/user-data/outputs/…` (copy the file
  there first, then `str_replace`), and `present_files` them.
- **House-mixin files** (`Lang*.svelte`, `Lies*.svelte`) deposit methods onto `H` via
  `onMount(async () => { await M.eatfunc({ … }) })`. Inside a method `this` is the
  House. They're dynamically haunted, not imported by name. LiesEnd is mounted by both
  Lies and Lang, so its methods (LE_*, Waft_*) are reachable from either side, and a
  cross-house call is `H.i_elvisto('Lies/Lies', 'Lies_event', {sc})` → handler
  `e_Lies_event`. **UI files** (DocMinimap, DocCompost, NaviCado, Langui) are normal
  components taking `{ H, view }` (or similar).
- **Notation conventions** live in `NOTATION.md`. Short version in §6 below.

---

## 1. Done this session

### DocCompost.svelte (NEW) — the frozen-frame overlay + tap source
A floating overlay (a `{ H, view }` component like DocMinimap) that freezes the editor
viewport, transforms it, and lets you click back into it. PNG overlay item I, built.
- **Frame** = a 1:1 DOM **clone** of `view.scrollDOM` (scrollTop replayed), floated as a
  fixed overlay over the live editor's rect — perfect fidelity, no font|taint trouble,
  and the live editor stays untouched underneath.
- **Twist/shrink** via a `pose` (x,y,scale,rotate,opacity) tweened by a local rAF
  `morph(to,dur)`. `// <` marked to ride `H.Lang_wave_*` (the Waver) once LangPoint is
  mounted — that makes Compost the second Waver consumer (Cytui is the third).
- **Scribblespace — click-to-reveal.** A click maps frame-local `offsetX/offsetY`
  (transform-proof — CSS transforms never move an element's own offset space) → live
  editor client coords → `view.posAtCoords` → doc pos → seek (via `dock.c.seek`) +
  dismiss. Fold-aware for free, no matrix math.
  > **art:** "I also want to be able to randomly click my way into it, scribblespace or
  > slightly-revealed-thing"
- **toPNG()** rasterises the clone (foreignObject + inlined computed styles → Image →
  canvas → dataURL) for saved|tweenable "visual art compost". Best-effort, returns null
  on failure (foreignObject font embedding is fragile; drop in html2canvas if it
  disappoints). The interactive clone does NOT depend on it.
- **fly(from, {auto_q})** — records a tap, suggests a Q from the tap-log, fires
  `e:Lang_climb` (guarded), grabs a frame, morphs a gentle zoom, then seeks + clears.
  The auto-Q-on-fly-in.
- **Surface** stashed on `dock.c.compost = { grab, morph, clear, reveal, fly, toPNG,
  suggest_Q, step }` so the gallop|gotos drive it without importing the component.
  `step(prevQ,nextQ)` grabs a pre-fold frame (for the snapshot-per-Q-step tween — not
  yet driven by LangPoint).
- **Long-press**: `pointerdown` stamps a time; a press held >400ms is a **long**
  (articulated) tap (weight 4) vs a quick reveal (weight 3).

### The attention tap-log → the Ting (taker Waft)
A tap is the lightest Point activity. Two consumers:
- **Local ring** `dock.c.taps` (cap 400) drives `suggest_Q(line)` (recent + near taps
  add heat, heat lowers Q). Node-checked.
- **Lang_tap** (LangRegions) resolves the tap to `$region/$method` BY NAME through
  `%Map` — `Lang_def_at_offset`-style, but the owning method is the def whose header
  line most recently precedes the tap line (%Map keeps name-spans not bodies, so that's
  the cheap correct-enough bound); region = the def's `region_path` tail. Hands off to
  `e_Lies_take_point`.
  > **art:** "the Point needs to be talking about the $region / $method mostly… it would
  > globulate to them."
- **Globulation** (`e_Lies_take_point`, Lies): one `%Point:method` per `$region/$method`
  (region disambiguates same name in two regions), bumping `n`/`weight`/`last`/`first`.
  A long tap adds `held` + `long:1`. Quick taps stay ambient (just counts). Node-checked
  (coalescing, region split, held bonus, ambient skip).
  > **art:** "we generate plenty of Points easily? maybe long taps should be articulated
  > and meaningful. we're building a tactile social media out of this."
- **The Ting** = a transient **taker** Waft `Waft:Ting/$load-timestamp`
  (`Lies_spawn_ting_waft`, LiesStore). One per page load (key cached on `w.c.ting_key`,
  reused). Marked `sc.takes:1`. Does NOT take `sc.active` (runs alongside the giver
  What, found by its mark, not focus). Lazy-spawned on first take + the one-liner
  `e_Lies_now_Ting`.
  > **art:** "there's a Waft that gives Points and one that takes Points… the takers
  > will be marked as such." / "open a Lies/Waft:Ting-$timestamp every time the page
  > loads, and we just don't save it"
- **Persistence**: `Lies_waft_save` short-circuits on `sc.takes` — the one place the
  giver|taker split touches IO. Givers (Whats) persist; takers (Tings) never do.

### Multiply LE — one name per reason (LiesEnd)
> SCRAPPED (see Status update). We don't multiply LE per reason, and Funkcions don't use
> LE — Interest `{LE:1}` (the main giver Waft → Lang checkout) stays, the Undertaking is
> dropped, Funkcions live in Lies via `req:funkcion`. Kept below as the record of what was.

One LE was one Understanding. Now an LE exists per reason, named.
- **`LE_for(reason)` / `LE_spawn(reason)`** — resolver|spawner. **Encoding is additive:**
  Interest keeps `{LE:1}` (so all ~11 existing `o({LE:1})[0]` readers reach it
  unchanged), named reasons are `{LE:name}` siblings that an `o({LE:1})` query does NOT
  match. Spawn tags `sc.reason` for inspection (additive — the bare `{LE:1}` still
  matches). NOT a rename.
  > **art:** "we need to multiply LE, one name for every reason they exist."
- **Interest** (`{LE:1}`) — two-way. The existing checkout that deals with what comes
  OUT of it (the `%Map` report, the Points); feeds `%Interest/%MapReport` via
  `Lang_Map_report`.
  > **art:** "the one Interest has an LE and deals with what's coming out of it…"
- **Undertaking** (`{LE:'Undertaking'}`) — one-way. Mostly UI flavour, where we've been.
  Its working data is the Ting (`LE.c.ting`, off-snap ref); it never pulls|pushes, it
  accumulates. `LE_undertaking(w)` spawns it and points it at the taker Ting.
  > **art:** "the one Undertaking is more one-way, and mostly just for UI flavouring so
  > we know where we've been, like an animal's mind is overlaid in the visual language
  > of it all."

### Funkcion-hosted req (LiesEnd) — "brighten things up"
> LEGACY (see Status update). The trail still runs on this LE-hosted path, but new
> Funkcions arrive via the LE-free `req:funkcion` (`Lies_host_funkcion` / `req_funkcion`),
> living in Lies. Kept below as the trail's record.

- **`LE_host_funkcion(LE)`** — if a `%Funkcion` rides the LE's workon Seem, host a
  `req:funkcion` (via the same `reqy(host).doai({req})?.(cb)` cluster as `e_Lang_LE_push`),
  run its behaviour, finish per tick so it re-arms. Defensive — a no-op until a Funkcion
  is around.
  > **art:** "the ability to host a req derived from a Seem:workon C%Funkcion to brighten
  > things up… (req imparting? a careful word)"
- **The Funkcion's behaviour rides `c.run`** (off-snap closure, like seek|compost — so
  the snap side stays declarative, the .c side live, never stale). Confirmed-as-built
  binding (was a flagged guess; the human said "onwards" → proceeded): the Funkcion
  rides a real **`Seem:'workon'`** carrying **`{Funkcion:'trail'}`**, and
  `LE_host_funkcion` reads `Seem:'workon'` first, working Seem as fallback.

### The trail Funkcion + heatmap (LiesEnd, Lang, DocMinimap)
The first concrete Funkcion: paint the Ting trail as UI flavour.
- **`funk.c.run`** (set up in `LE_undertaking`): from the Ting globules, derive a decayed
  `heat = weight · 0.5^(age/halflife) (+0.5 if held)` and a normalised `bright` (0..1)
  per `$region/$method`. Bumps the Ting AND the LE version (so the minimap's
  LE.vers-sensitised derivation wakes). halflife default 60s. Node-checked.
- **Two clocks.** Taps brighten immediately (`e_Lies_take_point` → `LE_undertaking` +
  `LE_host_funkcion`). The trickle `think()` (~3.6s) cools it: `req_workon` (Lang's thin
  per-tick driver) pumps `LE_host_funkcion(undertaking)` each tick, guarded + defensive.
  > **art:** "pump the decay first… we rely on trickle think() for this aye… it's every
  > 3.6s or so."
- **Render — same rail as is_pointedat.** Each Mapule gains `m.c.bright(brights)` keyed
  `${region}\u0000${key}` (region = region_path tail) in `Lang_build_mapules`.
  `Lang_trail_brights()` reads the Undertaking's Ting globules into a matching map. The
  minimap derives `brights` sensitised on the Undertaking `LE.vers`, and `heat_style(m)`
  paints an amber `box-shadow` glow (≤0.02 → nothing) on all four def-chip columns and
  the region band labels. The minimap holds no Lang vocabulary — it asks Lang for the
  map and reads Mapule closures, exactly like pointed_specs.
  > **art (item G):** "a streak of heatmap careening all over the MiniMap… the lightest
  > kind of Point activity, mostly implied by where user looks."

### Minimap goto becomes a fly-in (DocMinimap)
`record_goto` routes through `dock.c.compost.fly(from)` when DocCompost has armed the
surface (fly-in + auto-Q), falling back to the plain `mapule.c.goto()`|seek otherwise.
Breadcrumb + back/forward preserved. This is the fly-in flavour of item E.

### enWaft protocol relaxation (Text.svelte)
So the Ting (Points with non-vocabulary sc like `n`/`held`/`region`, and one day a whole
tap tree) can encode for the wander-trail render.
- The `all_knowing` vocabulary gate (mainkey ∉ `Waft|What|Doc|Point` = fatal) is **parked
  as a commented relic** (both halves: the `known_mainkeys` derivation and the fatal
  block), re-armable. Any mainkey encodes now.
  > **art:** "the encoder probably wants to be entirely relaxed with its type situatings.
  > comment that out though as it's interesting…"
- **Refs are complained about** — a repeated C (reachable from >1 place) pushes a fatal
  complaint on first encounter ("refs belong in .c, not the snap tree"). The loopy pair
  still emits so the snap reads, but it surfaces + blocks a real save (a Ting is never
  saved, so for it it's purely diagnostic).
  > **art:** "I guess refs are to be complained about."
- **`max_child_depth`** is now forwarded through `enWaft` (it already existed in
  `encode_wh_lines`) — depth limiting for the format.
- Header comments updated to stay true.

### TS fix (Langui.svelte)
`RefoldWidget`'s `constructor(readonly from, readonly to)` — TS parameter-properties
aren't supported in Svelte `<script>` without a preprocessor. Expanded to explicit
fields + assignment. Behaviour identical.

---

## 2. Files touched this session
`DocCompost.svelte` (NEW), `DocMinimap.svelte`, `Text.svelte`, `Langui.svelte`,
`LiesStore.svelte`, `Lies.svelte`, `LangRegions.svelte`, `LiesEnd.svelte`, `Lang.svelte`.
(Uploads lag these — re-read live.)

---

## 3. The Lang↔Lies Waft traffic (the surface, now multiplying)
- `e:Lies_open_Waft(path)` → `Good,type:text/Waft` → LiesStore provisions → loaded Waft
  container. Persisted doc-sets.
- `e:Lies_now_Waft` → `Waft:Look/YMD/HH` hourly scratch, **persisted**, `sc.active=1`
  session-only.
- LE/Seem `working|origin` checkout clones ← the Point/Pmirror editing traffic (NaviCado,
  LiesEnd). NOW under the **Interest** LE (`{LE:1}`).
- bookmarks → Seem:working (pending item F).
- **Ting** `Waft:Ting/$load` — transient **taker**, `sc.takes`, never persisted, fed by
  `Lang_tap` globulation. The **Undertaking** LE (`{LE:'Undertaking'}`) is its one-way
  flavour overlay.

---

## 4. Pending — the next builds

### Wire / mount prerequisites (nothing fires without these)
- ~~**DocCompost must be mounted**~~ — **shelved** (see Status update). It is not on the
  critical path; `dock.c.compost` stays unarmed and `record_goto` uses plain goto, which
  is the intended path now.
- **LangPoint must be mounted** (carried item A, sessions 1–2) for `e:Lang_climb` /
  auto-Q to fire. (The Compost `fly()` it also gated is moot while Compost is shelved.)

### Trail / Compost follow-ons (close to done)
- **Decay-over-time is live** (this session). Remaining trail polish: region bands glow
  from their own region-level globule, not the **sum** of their defs' heat — an aggregate
  would read better. And the glow could **tint by recency vs frequency** (held|long a
  different hue) so it says not just where but how you were there.
- **Eager on-load Ting.** Currently lazy on first tap (`w` isn't in scope at Lies
  onMount). `// <` in `e_Lies_now_Ting` marks where to call `Lies_spawn_ting_waft` from
  the load pipeline if an empty Ting from the first frame matters.
- **Method-less taps** don't globulate to a region yet (no body extents in %Map). `// <`
  in `Lang_tap`: precise body containment via the indent-block decomposition | the Mapule
  region extents would also let a method-less tap land on its region.
- **Long-tap articulation.** `held`/`long` is marked but no `{say:…}` note child yet.
  `// <` in `e_Lies_take_point` — attach an articulation child so the Ting reads like a
  feed of deliberate Points (the tactile-social grain).
- ~~**toPNG fidelity**~~ — **shelved with Compost.** PNG/screenshot taking is whack:
  foreignObject won't rasterise under software rendering and drops scoped CSS + web-fonts,
  and the live-capture fallback lags. html2canvas was the marked fallback if it ever
  returns. Not needed for anything soon.
- ~~**Compost on the Waver**~~ — moot while Compost is shelved; revisit if it roars back.
- **Funkcion-req cadence** — `req_workon` calls `LE_host_funkcion` via `doai` per tick
  (re-arm). If the reqy fault UI gets chatty, the tidier form is an eternal workon stage
  (roai'd with a sig like the other stages) instead of a per-tick `doai`.

### Carried forward, still open (full verbatim quotes in sessions 1–2)
- **Doc-switcher index → now the `Waft:GhostList` Funkcion** (BUILT — see Status update).
  The OTHER Waft\*\*-family device (session 2 §3): a `Waft:GhostList` index of all ghosts
  (each a Doc), kept current by its own **dirlisting** Funkcion, residing in its own Waft
  in Lies (like the Ting); a pick could later drop a Doc into the **main giver Waft**
  (the What-pile). Render could move to the compressed cellular word-pile
  (`Understandi(cation|ity|ium)`) patterned on **Stuffing** (`Stuff_svelte.ts` +
  Stuffing/Stuffusion/Stuffziad/Stuffzipper): one line, one tree open, branch-crunch. The
  Stuff family compresses rows-by-shared-key into Stuffziado value cells; literal
  common-prefix folding is "similar but different", a new sibling. The "hosts a bit of req
  because it's active" part is just the Funkcion now — no LE needed.
- **C. Active Pmirror + What recentre.** Double-click (rapid) a Pmirror → primary|active
  (and un-become) so Points lay out evenly; click the What title to recentre. Drive it
  through the Waver. The active-Navicade Thing pops a controls cluster with UIguts
  (PeelInput.svelte is the generic TheUniversal add|edit form for the active Point, under
  the NaviCado zone).
- **E. Goto fold-policy "thus-crunchy" (remainder).** Unfold the target's ancestors (done
  in session 2) AND fold the rest per Q (not done). The fly-in routing (this session) is
  the seek half; the fold-around-target half remains.
- **F. Bookmarks inject into Seem:working.** A named bookmark should drop its
  `%Point:name` into Seem:working the way NaviCado's `peel_commit` does. "it's old code
  over there around bookmarks." Relates to the snap What/Doc/Point nesting flag (§5).
- **G. Attention heatmap — the data + minimap render are DONE this session.** What's left
  of the original vision: on-screen line visibility as a (lightest, decaying) tap source,
  edits as the heaviest source batched into one pleasing sweep, and pulling up history as
  a replayable streak (the Ting is the record; the wander-trail replay is unbuilt).
- **H. Bring Cytui onto the Waver.** Cytui's `cyto_graph.sc.waves` drain-on-tick +
  `apply` + `rush_animations` map onto LangPoint's `Lang_wave_enqueue/_step/_rush`.
  Extract the kernel; Cytui the second|third consumer (DocCompost's morph is the other
  candidate). "make it an easy fit."
- **Scribble-ball scheme.** Replace folded guts with a scribbley-ball graphic that
  promotes a few key expressions out (needs the invisible folds, built session 2, + %Map
  call/def entries to pick the promoted expressions). Pairs with the PNG overlay.

---

## 5. Gotchas / open notes
- **There is one LE** — Interest, `{LE:1}` (~11 readers do `o({LE:1})[0]`, so never
  rename it). It is the main giver Waft being checked out to Lang; nothing else needs an
  LE. (The Undertaking was dropped; the "multiply LE per reason" idea is scrapped.)
- **Lies-side host, Lang-side read through `languinio`** is the cross-w pattern that
  matters — no LE needed. A host-local Waft (the Ting, the GhostList) lives on the Lies
  `w` and is reachable from Lang through the shared `languinio`/`ave`.
  `dock === lang_dock` still holds (the seam's dock is the particle
  the minimap reads via languinio).
- **Trail key alignment is load-bearing.** `Mapule.c.bright` looks up
  `${region}\u0000${key}` (region = `region_path` tail, key = method|label|keyword) and
  `Lang_trail_brights` sets `${g.sc.region ?? ''}\u0000${g.sc.Point}`. They MUST stay the
  same template or the heatmap silently goes dark. `Lang_tap` feeds the globule region
  from the same `region_path` tail, so the three agree.
- **enWaft is relaxed but refs are fatal.** A Ting of `%Point` globules encodes (scalars
  only). If you ever nest C refs in a Ting it'll complain — keep tap data scalar +
  names.
- **`%Map` has name-spans, not bodies.** Tap→method resolution uses "nearest header
  at|above the tap line" as the body bound. Good enough for globulation; precise
  containment is a `// <`.
- **Snap What/Doc/Point migration** (from session 2, still open) — persisted snap is
  Waft→What→{Doc,Point}; some in-memory code still nests Point under Doc (Lies.svelte
  546/698 vs 606/652). Resolve before relying on the snap round-trip for Points; relates
  to bookmarks (F).
- **Verification habit.** Node-check pure logic before handover; edit-delta balance (not
  whole-file `{}` count) for `.svelte`.

---

## 6. Notation cheat-sheet (full version in NOTATION.md)
- Name C objects by mainkey; refer as `%Point`, `Text%dige`, `%like,this` alone,
  `and/like,this/written:is` in structures. `%LE` = `{LE:1}` (value-1 flag = bare key).
  `%Spotlight,src` = Spotlight with an unwritten src value. Prefer `%Point:name`.
- Tuple floating in language: `%kind,key,path,depth`.
- TYPE NAMES: `|` = and (`Navicade|Mapule`), `/` = host-of (`dock/%Map`,
  `Seem:workon/%Funkcion`).
- COMMENT PROSE: `|` = or (`decl|call`, `if inside/this|that`), `/` = inside-ness.
- Comments are eternal — keep what's still true, no dev-mumbling, no `<- NEW`. `// <`
  marks a lack of development (a deferred gap). Nest a stack of not-too-long sentences.
  Don't randomly cap lengths for presentation.

---

## 7. The vertical, end to end (the spine built this session)
> Historical: written when the trail was LE-hosted and Compost armed the tap. The live
> path drops the Undertaking LE and the Compost fly-in (see Status update) — taps arrive
> from the editor directly, and a Funkcion is hosted host-locally, not via an LE.

`reveal|fly on the DocCompost frame` → `Lang_tap` resolves `$region/$method` by name
through `%Map` → `e_Lies_take_point` globulates one `%Point:method` per
`$region/$method` into the taker **Ting** (`sc.takes`, never saved) → `LE_undertaking`
points the one-way **Undertaking** LE at the Ting and stands up its `Seem:workon/%Funkcion:trail`
→ `LE_host_funkcion` runs the Funkcion (on the tap, and every trickle via `req_workon`)
computing decayed `heat`|`bright` per globule → the **minimap** reads `Lang_trail_brights`
through each `Mapule.c.bright` and glows amber where you've been, cooling on its own as
the half-life decays. The animal's mind, overlaid on the visual language.