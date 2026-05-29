# Waft palmtree trajectory — reqy migration + What transport

Carry-forward for post-🌴 work.  `Waft_spec.md` owns the *design* of the What
tree and its transport semantics; this doc owns the *implementation slice*.


---

## What has landed

- Write-on-init noise: dige gate in `LiesStore_write`.
- Lazy doc loading: `eager_waft_load` flag in `Lies_sync_waft_docs`.
- Cursor autostart; DocRow glow live.
- Class-method defs compile; Points resolve on open (most of the time — see Chunk 1).
- `LiesStore` owns all Lies IO: noserial reqy channels, `req.sc.finished` API,
  Phase 1/2/3 scan.  `requesty_serial` retired from Lies.
- Both rename handlers stubbed (they need git-level reference tracking across
  Points, Pmirrors, and every path reference — a separate project).
- Languish / snap-race fix
- Ghostmeta / Pantheate include monitor

##  Known bugs to chase before Chunk 3

Ghost write not firing — compile_pending → LiesRealised → LiesStore_write path seems not to complete. The snap showed compile_pending present with done:1 eventually, but you're saying Ghost writes don't land. Worth checking: do_write = !H.o_Opt_val(w, 'nogen') — if nogen opt is set, write is skipped silently. Also check whether LiesStore_write is getting its rw_name in the right format.

Every-keystroke elvis — likely the saveEffect debounce in Langui firing e_Lang_update_bookmarks or similar on each CM transaction. Worth adding a console filter to identify the type before the next session.

---

## Chunk 3 — `accepted_entries` persistence

Two `// <` markers in `e_Lies_accept_What_Point` (`%LiesCurse`).

Accepted Points survive in memory only.  A reload re-opens the What but the
promoted set is blank — user re-accepts from scratch each time.

Fix: stamp `accepted:1` directly on the `%Point` particle (already in the Waft
snap tree; `enWaft` passes sc scalars through without encoder changes).
`Lies_set_examining` reads it back at cursor-placement time.

```
Waft:Ghost/Tour
  Doc,path:Ghost/test/Hello.g
    Points:1
      Point,method:Idzeugnosis,accepted:1
      Point:Idzeuganise
```

`e_Lies_accept_What_Point` additions:
```js
point.sc.accepted = 1
waft.bump_version()   // → Lies_waft_save throttle
```

`Lies_set_examining` / cold-start: after installing `%What_Points,1`, walk
`src_C.o({Point:1, accepted:1})` and re-add each to the in-group.

Small — two `// <` markers and a cold-start guard.  Prerequisite for Chunk 4.

---

## Chunk 4 — What-level transport and navigation

*Depends on Chunk 3.  Multi-reset sub-project; design here.*

### The overall desire

The system carries an intention that it pursues toward showing the audience
something.  Right now it goes dormant once the Waft is open.  It should want:

```
w:Lies
  req:desire,Waft:Ghost/Tour
    req_sent
    started:1
    req:open_What           ← reqonce: opened first What, cursor set
      ttlilt:1,until_ts:T,playing:1   ← armed only in auto-advance mode
    req:next_What           ← when advancing: step sibling, or exhausted
```

`reqonce(desire_req, 'open_What')` fires once: opens the first `%What` in the
Waft, sets the cursor to it, arms a ttlilt if playing.  When the ttlilt expires
Story wakes, `do_fn` mints `req:next_What` and steps.  In pause mode the ttlilt
is never armed — `→` advances manually.

End-of-Waft: when no further `%What` exists, `req:next_What` transitions to
`req:waft_exhausted` and fires an `o_elvis` for the UI (loop, stop, prompt
for `+time`).

### Navigation gestures

```
→   continue          step to next sibling %What at the same depth.
                      "keep going the way we were going."

↘   sibling +time     create a new %What sibling beside the current one
                      and step into it.  Branch-point is the current accepted/
                      showing set; both threads remain live.
                      "let's explore a parallel line from here."

↓   child +time       dive: create a new %What *inside* the current one,
                      positioned between two chosen Points.
                      "let's go deeper into this pocket."
```

`e_Lies_cursor_next` currently steps `%Doc` within a Waft.  Promoting it to
step sibling `%What` particles is the first gesture (4a).  `↘` and `↓` need
new `e_Lies_branch_What` and `e_Lies_dive_What` events.

### The caving metaphor

A Waft is a cave system.  Each `%What` is a chamber — a moment of focused
attention with particular Points illuminated on the walls.  `→` walks the main
passage.  `↘` carves a side-tunnel from the current chamber.  `↓` drops into
a pit discovered between two Points in the floor.

The audience follows the spelunker.  The frame of reference is the chamber
they're in — its Points are the walls.  `→` is legible because the audience
knows where they came from.  `↘` is "we'll return to this junction."  `↓` is
"look what's down here" — a sub-thread that resurfaces to the parent when done.

`accepted:1` Points carry forward (Chunk 3) because the spelunker marks the
wall and that mark survives the return trip.

### `+time` carry-over heuristic

When a new `%What` is created (→ or ↘ or ↓), the heuristic seeds its in-group:

- Points with `accepted:1` AND `showing` → copied forward.
- Points created `< 30s` ago → moved forward (part of this thought).
- Everything else → ghost at 18% opacity, 10s rescue window, then fade.

`showing` is the DocMinimap capsule visibility (orb toggle).  Dormant Points
stay in the old chamber.  The rescue window: `reqonce(what_req, 'rescue_window')`
arms a ttlilt for 10s; after expiry, unrescued ghosts are dropped.

### `◀◀ rwnd`

Steps back through `%What` siblings in reverse, re-loading their showing set
into `%What_Points,1`.  Read-only — no mutations to accepted state.
The "you were here" marker.

### Sub-slices

- **4a** — `e_Lies_cursor_next` steps sibling `%What` (not just `%Doc`)
- **4b** — `req:desire` + playing/pause loop
- **4c** — `↘` / `↓` branch and dive gestures
- **4d** — ghost + rescue window + `◀◀ rwnd`

---

## Sequencing

- **1** first — graft ttlilt, ~ten lines, immediately visible.
  Needs `scheme:req` on `w:Lang` as a prerequisite (see `scheme-req-spec.md`).
- **2** — internal tidiness, one PR after 1.
- **3** — small, prerequisite for 4.
- **4** — multi-reset, design sub-slices before each.

Single-convo highest value: **1 + 3** — "Points resolve on open" and
"accepted set survives reload."

---

## Style notes

- Keep comments that stay true on rewrite; drop dev-mumbling.
- `// < …` marks a *lack* of development.
- `%like,this` naming a lone C object; `/%like,this/written:is` for structures.
  `$values` for sc scalars, `$C` for TheC refs in sc.
- `oai` sync, `roai` async.  `roai` from sync context returns a Promise and
  silently breaks the assignment — verify call-site async-ness when touching
  particle-creation code.
- `i_req_ttlilt(req, secs, sc)` sets `w.c.has_req_ttlilt` — Story's quiescence
  gate.  No separate `demand_time_to_think` needed.
- `reqonce(req, name)` stamps `req.sc[name]=1` once per req lifetime (via
  `req.c.oncelers`).  Gate one-shot setup inside `do_fn` with it.
- The `req` mainkey is the default; no need to customise it unless genuinely
  distinguishing different classes of request on the same host particle.
