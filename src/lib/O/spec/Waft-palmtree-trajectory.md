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

---

## Chunk 1 — LangGraft ttlilt  *(load-bearing — do first)*

### What Pmirrors are

A `%Pmirror` is the Lang-side shadow of a `%Point` from the Waft cursor.  It
lives on `docC` because it needs to resolve against the compile output (defs,
regions) to find a line position.  The `%graft,1` child is the resolved
position — `{from, to, line, bookmark_id}`.  Without `%graft`, the CM mark
doesn't exist; the Pmirror is a declaration of intent.  Graft is Pmirror's
reality, not a control layer above it.

```
docC (w:Lang/docs/doc:$path)
  Pmirrors:1
    Pmirror:1,src_Waft:Ghost/Tour,spec:Idzeugnosis
      graft:1,bookmark_id:bm_…,from:14,to:60,line:4   ← resolved; CM mark placed
    Pmirror:1,src_Waft:Ghost/Tour,spec:emit
                                                        ← no graft: unresolved
  Compile:1
    Pending:1     ← while compiling
    methods:1
      def,method:Idzeugnosis,from:14,to:60,line:4
      region,label:Pier,…
```

DocMinimap reads `lang_docC/%Pmirrors/%Pmirror` and their `/%graft`
children to build the capsule strip and gold dot overlay.

### The timing bug

`Lang_graft_points` runs every tick.  On first open, compile hasn't finished
yet — `%Compile/%Pending` is set, `%methods` is absent.  The graft runs,
resolves nothing, Pmirrors land without `%graft` children.  Story snaps.
The user sees unresolved capsules until the next keystroke triggers a recompile.

Fix: arm `i_req_ttlilt` on a graft req while `%Pending` is set, so Story holds
the snap open until compile settles. 

### Graft req

Lives on `docC` (found by `i_Story_o_req_ttlilt` via the `w/scheme:req` /
lematch chain declared on `w:Lang` — see `scheme-req-spec.md`).

```
docC
  req:graft,path:Ghost/test/Hello.g
    ttlilt:1,until_ts:T,waiting_for_compile:1
```

### `Lang_graft_points` patch

After the cache-key early-return, before the Pmirrors replace:

```js
const pending = job?.o({ Pending: 1 })[0]
if (pending && points.length) {
    // Compile hasn't settled — hold Story open and retry next tick.
    const graft_req = docC.oai({ req: 'graft', path: active_path })
    H.i_req_ttlilt(graft_req, 0.5, { waiting_for_compile: 1 })
    return
}
// Compile ready — drop stale graft req so its ttlilt evaporates.
await docC.r({ req: 'graft', path: active_path }, {})
```

`i_req_ttlilt` would usually climb `req → docC → docs → w:Lang` and set
`w.c.has_req_ttlilt`, but there aren't .c.up wirings through the non-req
`w/%docs/%doc`, so we must make setting `w.c.has_req_ttlilt` separately
a feature of what sets up `w/%scheme`, lets do it with a helper called
`i_scheme_req()`

No separate `demand_time_to_think` needed.

Prerequisite: `scheme:req` declared on `w:Lang` so the walker finds `docC`-hosted
reqs — see `scheme-req-spec.md`.

---

## Chunk 2 — reqy migration: `open_waft_req` / `open_req` / `compile_pending`

Internal tidiness that makes the snap legible and sets the pattern for Chunk 4's
desire machinery.  All reqs use the default mainkey `req` with a plain string
subtype — `{req:'waft_load'}`, `{req:'doc_load'}`, `{req:'compile_write'}`.
No k/noserial options unless there's a genuine fan-out reason for them.

### 2a — Waft load

**Now:**
```
w:Lies
  open_waft_req,path:Ghost/Tour,done
```

**After:**
```
w:Lies
  req:waft_load,path:Ghost/Tour
    req_sent
    started:1       ← reqonce: watch_c registered, waft installed once
    done:1
```

`reqonce(req, 'started')` gates the one-shot setup inside `do_fn`: decode snap,
`w.i(waft)`, register `watch_c → Lies_waft_save`.  `Lies_sync_waft_docs` is
called unconditionally (outside the reqonce block) so CRUD re-syncs every tick.

```js
async LiesPersist_waft_load_do_fn(req, q) {
    if (req.sc.done) return
    const snap_req = await H.LiesStore_read(w, snap_path)
    if (!snap_req.sc.finished) { H.i_req_ttlilt(req, 0.5, {waiting:'snap'}); return }

    if (H.reqonce(req, 'started')) {
        const waft = H.deWaft(snap_req.sc.reply?.content ?? '', path)
        await w.i(waft)
        H.watch_c(waft, () => {
            H.Lies_sync_waft_docs(w, waft)
            H.Lies_waft_save(w, waft)
        })
    }
    H.Lies_sync_waft_docs(w, waft)
    req.sc.done = 1
},
```

Minting: `w.oai({ req: 'waft_load', path })` — plain oai, no wrapper needed.

### 2b — Doc load

**Now:**
```
w:Lies
  open_req,path:Ghost/test/Hello.g,from_waft:Ghost/Tour,done
```

**After:**
```
w:Lies
  req:doc_load,path:Ghost/test/Hello.g,from_waft:Ghost/Tour
    req_sent
    done:1
```

`do_fn` reads source via `LiesStore_read`, fires `Lang_open_doc`, stamps
`done:1` and `base_dige` on the new `%loaded_doc`.  `Lies_sync_waft_docs`
calls `w.oai({req:'doc_load', path, from_waft})` instead of
`w.oai({open_req:1,…})`.

### 2c — Compile write

**Now:**
```
w:Lies
  compile_pending,path:Ghost/test/Hello.g,gen_path:gen/test/Hello.go,done:1
```

**After:**
```
w:Lies
  req:compile_write,path:Ghost/test/Hello.g,gen_path:gen/test/Hello.go
    source: …
    dige: 87678b3…
    req_sent
    done:1
```

`e_Lies_compiled` calls `roai({req:'compile_write', path, gen_path}, {source, dige})`
— `roai` updates `source` and `dige` in-place on an existing req, so a fresher
compile overtakes a staler one automatically.  `LiesRealised_run` becomes a
`do_fn` that calls `LiesStore_write`, fires `Ghost_update_notify` and
`Lies_compile_settled`, stamps `done:1`.

### Full w:Lies snap after chunk 2

```
w:Lies
  req:waft_load,path:Ghost/Tour
    started:1
    done:1
  req:doc_load,path:Ghost/test/Hello.g,from_waft:Ghost/Tour
    done:1
  req:doc_load,path:src/lib/p2p/Peerily.svelte.ts,from_waft:Ghost/Tour
    done:1
  Store:1
    wrote_at:wormhole/Ghost/Tour/toc.snap: 1748391234.567
  examining,active_path:Ghost/test/Hello.g
    What_Points,src_Waft:Ghost/Tour
  Waft:Ghost/Tour
    Doc,path:Ghost/test/Hello.g
      Points:1
        Point,method:Idzeugnosis,accepted:1
        Point:Idzeuganise
    Doc,path:src/lib/p2p/Peerily.svelte.ts
      Points:1
        Point:Pier
        Point:emit
  loaded_doc,path:Ghost/test/Hello.g,gen_path:gen/test/Hello.go,base_dige:50d102…
```

Gone: `requesty_rw_queue*`, `open_waft_req`, `open_req`, `compile_pending`.
The wwrite/wread reqs from LiesStore only appear during active IO and are
dropped on completion — nothing to show at rest.

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
