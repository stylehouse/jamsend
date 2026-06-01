# Waft palmtree trajectory — reqy migration + What transport

Carry-forward for post-🌴 work.  `Waft_spec.md` owns the *design* of the What
tree and its transport semantics; this doc owns the *implementation slice*.

---

## Lang/LE architecture

```
w:Lies
  /%examining
    /%What_Points
        sc.src      $C → %What or %Doc    ← cursor target; %What from cursor_next,
                                             %Doc from cold-start / active_dock watch
        sc.src_Waft string
  /%LE                                    ← stable; not inside replace()
    /%State                               ← synthesised: armed/changey/stale
    // %push_dirty — fault child; present only when push didn't land clean
    /%Seem:origin
        sc.Se  Selection()
        sc.C   → live %What               ← the remote; never edited
        /%Demonstrations:origin
          /…D   one per child             ← awareness sphere; neus/goners = stale signal
        /%News:origin
    /%Seem:working
        sc.Se  Selection()
        sc.C   → clone root               ← our editable tree
        /%Demonstrations:working
          /…D   one per clone
            /%Understandable              ← U node; unshowing/unaccepted live here
        /%News:working

ave/%active_dock                          ← reactive signal: which %Dock is foregrounded
  sc.path  string
  c.dock   $C → %Dock                    ← direct ref; Langui reads for bookmarks

w:Lang
  /%docks
    /%Dock,path                           ← one per open file; carries CM state + compile
      /%Compile
        /%Output
      /%bookmark,N
      // < /%LE — per-Dock Understanding; armed when Lies_set_examining aims here

  /%Languinio
    /%Change                              ← three-leg display strip (storage/backend/compile)
    /%LE                                  ← same-object hold on w:Lies/{LE:1} ✓ wired
                                          //   re-installed on each Lies_set_examining call
                                          //   via e_Lang_LE_arm cross-world event

ave/%lang_dock,path                       ← text sync; sc.text / sc.text_dige / sc.disk_dige
```

Key structural facts:

- `LiesEnd` methods run on the same House as `Lies` — `H.LE_arm`, `H.LE_pull`
  etc. are available from any Lies tick or LiesCurse callback without a
  cross-world round-trip.
- The Understanding is **Lies's checkout, Lang's read**: Lang reaches it through
  the `%Languinio/%LE` same-object hold, so it can call `LE_clones()` and check
  `%State` without messaging.
- `Lies_set_examining` is the single seam: on a cursor move it calls
  `H.LE_arm(LE, src)` then fires `e_Lang_LE_arm` cross-world after the first pull.
- `i()` always inserts (never deduplicates), so `e_Lang_LE_arm` does
  `await languinio.r({LE:1},{})` before `languinio.i(LE)`.

---

## Chunk U — the Understanding ✓ done + grafted

*Built and proven in an isolated harness (Understandity → Understandium →
Understandication).  Now wired onto the live Lies+Lang cluster via Steps A–C.*

### Steps A–C (done)

**A** — `LiesEnd.svelte` unchanged; comment was already correct: `w/{LE}` under
`w:Lies`.

**B** — `LiesCurse.svelte` / `Lies_set_examining`: now `async`; after stamping
`wpt` and bumping:
- gets `w` via `examining.c.w`
- gets `LE` via `w.oai({LE:1})`
- calls `H.LE_arm(LE, src)` (sync)
- `await H.LE_pull(LE)` then `H.i_elvisto('Lang/Lang', 'Lang_LE_arm', { LE })`

`watch_c` handlers are now `async () =>` and the flush loop `await`s each handler
(`Housing_svelte.ts`).  All call sites of `Lies_set_examining` use `await`.

**C** — `Lang.svelte`: new `e_Lang_LE_arm` handler after `e_Lang_open_dock`.
Receives `e.sc.LE`, drops prior hold via `await languinio.r({LE:1},{})`, then
`languinio.i(LE)`.  Particle layout comment updated to document `%Languinio/%LE`.

### Open faults from Chunk U

```
// < vanish: unaccepted clone lands as goner on post-push awareness pull, firing
//   push_dirty.  Fix: LE_push stamps bD/was_disincluded:1; resolved_fn suppresses.
// < push_dirty not yet wired to a req fault particle in the reqy system.
// < Se_o as a standing watch (fire on every source mutation) — call-driven for now.
```

### The two-sphere stitch, API, and LE states

See `LiesEnd_spec.md`.

---

## Chunk 4 — What-level transport and navigation

*Depends on Chunk U.  Multi-reset sub-project; design sub-slices before each.*

### 4a — cursor_next steps %What ✓ done

`e_Lies_cursor_next` in `LiesCurse.svelte` now steps `%What` particles (direct
children of loaded Wafts), not `%Doc` particles.  Two new helpers:

- `Lies_what_has_points(what)` — true when a `%What` has at least one `%Point`
  in its immediate layer (direct children, or inside a direct `%Doc` child).
  Does not recurse into nested `%What` children.
- `Lies_what_first_doc_path(what)` — returns the first `%Doc` child's path, or
  `undefined` for a pure time-slice `%What` with direct Points (no Doc container).
  Used so `Lies_ensure_doc_loaded` can queue a load.

Position is tracked by **particle identity** (`c.what === cur_src`), not path —
`%What` has a label, not a path.

`e.sc.dock_path` is kept on the event for caller compat but is no longer read.

**Open seam:** `e_Lies_set_cursor` (click on a Doc row in Liesui) and the
cold-start / `active_dock` watch paths still deliver a `%Doc` as `src`.  That's
correct for now — they are path-driven.  LangGraft tolerates either: `src_path`
is `undefined` for a `%What` and the guard short-circuits harmlessly.

```
// < e_Lies_set_cursor (Liesui Doc-row click) passes a %Doc src — valid now
//   that LE arms for any src type.  Needs Liesui to surface Waft-level rows
//   as clickable targets before it can navigate at %What granularity.
```

### 4b — `req:desire` skeleton ✓ landed; playing/pause loop next

`req:desire` lives on `w:Lies` directly — one wanderer, not one per Waft.
Erupts in `LiesRealised` via `rq.doai`.  Structure now in place:

```
w:Lies
  /{req:'desire'}                  ← the wanderer; finds Waft via req:acquire
    /{req:'acquire'}               ← one-shot lock; stamps desire.sc.waft_C
                                     sc.active → src_Waft → first Waft
    /{req:'completion',playing:0}  ← open-ended session; steps when playing:1
    /{req:'git'}                   ← Waftlet accumulator; patches via LE_push
```

`doai` is the new gesture for seeding a req and wiring its `do_fn` in one call
(`Hovercraft.svelte`).  It delegates to `roai(c, sc, meta)` — `meta.existed`
tells `doai` whether the req is fresh; only fresh reqs get the setter back.
`?.()` on the return makes every re-entry tick a no-op.

```js
;(await rq.doai({ req: 'desire' }))?.(async (desire) => { ... })
```

**Still to wire for 4b:**
- `req:acquire` do_fn is live — picks active/src_Waft/first Waft, finishes once locked.
- `req:completion` do_fn — `reqonce(completion, 'open_What')` sets cursor to first
  `%What`; when `playing:1` arms a ttlilt so Story advances automatically.
- `req:next_What` — minted by completion's ttlilt expiry; steps sibling, or
  transitions to `req:waft_exhausted` at end of Waft.
- Transport bar in NaviCado reads `desire.sc.waft_C` and `completion.sc.playing`.

**`req:git` — deferred** (`// < Chunk 4b+`): receives `/%Waftlet` children as
`LE_push` patches land; do_fn flushes them to disk/remote.

### 4c — `↘` / `↓` branch and dive gestures

```
↘   sibling +time     create a new %What sibling beside the current one
↓   child +time       dive: create a new %What inside the current one
```

Needs `+time` carry-over heuristic (accepted+showing → forward, recent →
move, rest → ghost with 10s rescue window).  Sits on top of the `LE_push`
mechanism — each gesture is "re-aim `%What_Points`, clone, edit, push".

```
// < unaccepted carry-forward reads clone.c.U?.sc.unaccepted at branch time
// < vanish fix (from Chunk U) must land before unaccepted is usable here
```

### 4d — ghost + rescue window + `◀◀ rwnd`

Ghost decorations and `rwnd` (step backward through `%What` siblings in reverse,
read-only).  Depends on 4c for the ghost stamping.

### Navigation gestures summary

```
→   continue     step to next %What — e_Lies_cursor_next ✓ done (4a)
↑←→  NaviCado   up/prev/next via c.up chain — ✓ landed (e_Lies_cursor_what)
↘   sibling +time   e_Lies_branch_What — 4c
↓   child +time     e_Lies_dive_What   — 4c
◀◀  rwnd         reverse step        — 4d
```

`NaviCado.svelte` — toolbar above DocMinimap capsule strip; receives `%LE` via
Languinio; derives position from `LE_what_depth/siblings/next/prev` helpers in
`LiesEnd`.  `Waft_link_up` stamps `What.c.up` / `What.c.waft` on every node
after Waft decode (and after LE_push lands fresh children).  Waft is the ceiling:
`c.up` chain stops at `node.sc.Waft !== undefined`.

### The caving metaphor

A Waft is a cave system.  Each `%What` is a chamber — a moment of focused
attention with particular Points illuminated on the walls.  `→` walks the main
passage.  `↘` carves a side-tunnel from the current chamber.  `↓` drops into
a pit discovered between two Points in the floor.

The audience follows the spelunker.  The frame of reference is the chamber
they're in — its Points are the walls.  `→` is legible because the audience
knows where they came from.  `↘` is "we'll return to this junction."  `↓` is
"look what's down here" — a sub-thread that resurfaces to the parent when done.

---

## Style notes

- Keep comments that stay true on rewrite; drop dev-mumbling.
- `// < …` marks a *lack* of development.
- `%like,this` naming a lone C object; `/%like,this/written:is` for structures.
  `$values` for sc scalars, `$C` for TheC refs in sc.
- `oai` sync, `roai` async.  `roai` from sync context returns a Promise and
  silently breaks the assignment — verify call-site async-ness when touching
  particle-creation code.
- `rq.doai(c, sc?)` — seed a named req and wire `req.c.do_fn` in one gesture.
  Delegates to `roai(c, sc, meta)`; `meta.existed` distinguishes fresh from seen.
  Returns setter fn first time, `null` thereafter — `?.()` makes re-entry a no-op.
  `await` required at call site: `;(await rq.doai({...}))?.(async (req) => {...})`.
- `watch_c` handlers are now `async () =>` and the flush loop awaits each one
  (`Housing_svelte.ts`).  All `Lies_set_examining` call sites use `await`.
- `i()` always inserts — never deduplicates by identity.  When a same-object
  hold needs replacing, drop via `r({key:val},{})` or explicit `drop()` first.
- `i_req_ttlilt(req, secs, sc)` sets `w.c.has_req_ttlilt` — Story's quiescence
  gate.  No separate `demand_time_to_think` needed.
- `reqonce(req, name)` stamps `req.sc[name]=1` once per req lifetime (via
  `req.c.oncelers`).  Gate one-shot setup inside `do_fn` with it.
- The `req` mainkey is the default; no need to customise it unless genuinely
  distinguishing different classes of request on the same host particle.
- `Se.process({ n, process_D, match_sc, trace_sc, each_fn, trace_fn,
  resolved_fn, done_fn })` walks `n` against a D, building a transient `Travel`
  ropeway (`T**`).  `trace_fn` mirrors `n.sc` into D; D nodes `replace()` so a
  kept `D/U` persists across walks.  `resolved_fn(T, N, goners, neus)` is the
  diff.  `match_sc:{}` is all-inclusive and keeps no D/U.
- Vocabulary: **Understanding** (`U`) the bounded checkout; **UPoint** a
  checked-out Point; **`/%Understandable`** the U-sphere node hanging under
  **`/%Demonstrations`** (the D sphere); `C.c.U` the clone's direct ref to its
  U node, `C.c.D` to its D node.  `%Pointo` is retired.  Local meanings live on
  U (`C:Point//U%unshowing`), never on the source `%Point`.
- Particle rename (Lang-side only): `docC` → `dock`, `{doc:path}` → `{dock:path}`,
  `lang_doc` → `lang_dock`, `active_doc` → `active_dock`.  `loaded_doc` keeps its
  full name (Lies-side loaded-file record, not a Dock).  Waft-side `%Doc` particles
  are unchanged — `%Doc` is a document in the tour; `%Dock` is Lang's docked-file
  particle (carries `/Compile`, `/Pmirror`, `/bookmark`).
