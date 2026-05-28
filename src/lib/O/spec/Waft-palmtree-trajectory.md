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
- Both rename handlers stubbed.

---

## Chunk 1 — LangGraft ttlilt  *(load-bearing — do first)*

Points still occasionally arrive unresolved on first open (compile beats the
graft tick to the snap, but the graft ran before `%methods` existed).  The fix:
arm `i_req_ttlilt` on a graft req while `%Compile/%Pending` is set, so Story
holds the snap open until compile settles.

Graft req lives on `docC`:

```
docC
  reqcons:1
    reqcon:req:graft
  req:graft,path:Ghost/test/Hello.g
    ttlilt:1,until_ts:T,waiting_for_compile:1
```

In `Lang_graft_points`, after the cache-key early-return and before the
Pmirror replace:

```js
const pending = job?.o({ Pending: 1 })[0]
if (pending && points.length) {
    // Compile hasn't settled yet — hold Story open and retry next tick.
    const graft_req = H.reqy(docC, { k: 'req:graft', noserial: 1 })
        .oai({ 'req:graft': 1, path: active_path })
    H.i_req_ttlilt(graft_req, 0.5, { waiting_for_compile: 1 })
    return
}
// Compile ready — clear any stale graft req so the ttlilt evaporates.
await docC.r({ 'req:graft': 1, path: active_path }, {})
```

`i_req_ttlilt` sets `w.c.has_req_ttlilt`; Story's quiescence check reads that
and refuses to snap.  No `demand_time_to_think` needed — `i_req_ttlilt` is the
whole ask.

---

## Chunk 2 — reqy migration: `open_waft_req` / `open_req` / `compile_pending`

Internal tidiness that makes the snap legible and sets the pattern for Chunk 3's
desire machinery.  The key naming choice: use the framework's default mainkey
`req` with a subtype field, so particles read naturally as `req:waft_load`,
`req:doc_load`, `req:compile_write`.  reqcons channel names match: `reqcon:req:waft_load`.

### 2a — Waft load

**Now:**
```
w:Lies
  open_waft_req,path:Ghost/Tour,done
```

**After:**
```
w:Lies
  reqcons:1
    reqcon:req:waft_load
  req:waft_load,path:Ghost/Tour
    req_sent
    started:1       ← reqonce stamp: watch_c registered, waft installed
    done:1
```

`reqonce(req, 'started')` gates the one-shot setup inside `do_fn`: decode snap,
install waft via `w.i(waft)`, register `watch_c → Lies_waft_save`.  Returns true
only once per req lifetime; subsequent ticks skip straight to `done` check.
`Lies_sync_waft_docs(w, waft)` is called unconditionally (outside the reqonce
block) so CRUD changes always re-sync.

`do_fn` shape:
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

### 2b — Doc load

**Now:**
```
w:Lies
  open_req,path:Ghost/test/Hello.g,from_waft:Ghost/Tour,done
```

**After:**
```
w:Lies
  reqcons:1
    reqcon:req:doc_load
  req:doc_load,path:Ghost/test/Hello.g,from_waft:Ghost/Tour
    req_sent
    done:1
```

`do_fn` reads source via `LiesStore_read`, fires `Lang_open_doc`, stamps `done:1`
and `base_dige` on the new `%loaded_doc`.  `Lies_sync_waft_docs` calls
`reqy(w, {k:'req:doc_load'}).oai({…path, from_waft})` instead of
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
  reqcons:1
    reqcon:req:compile_write
  req:compile_write,path:Ghost/test/Hello.g,gen_path:gen/test/Hello.go
    source: …
    dige: 87678b3…
    req_sent
    done:1
```

`e_Lies_compiled` calls `reqy(w, {k:'req:compile_write'}).roai({…path,gen_path},
{source,dige})` — `roai` updates `source` and `dige` in-place on an existing req
(fresher compile overtakes staler one automatically).  `LiesRealised_run` becomes
`reqy.do()` + `do_fn` that calls `LiesStore_write`, fires `Ghost_update_notify`
and `Lies_compile_settled`, stamps `done:1`.

### Full w:Lies snap after chunk 2

```
w:Lies
  reqcons:1
    reqcon:req:waft_load
    reqcon:req:doc_load
    reqcon:req:compile_write
    reqcon:wwrite
    reqcon:wread
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

---

## Chunk 3 — `accepted_entries` persistence

Two `// <` markers in `e_Lies_accept_What_Point` (`%LiesCurse`).

Accepted Points survive only in memory.  A reload re-opens the What but the
promoted set is blank — user has to re-accept each one.

Fix: stamp `accepted:1` on the `%Point` particle itself (already in the Waft
snap tree; `enWaft` passes sc scalars through).  `Lies_set_examining` reads it
back at cursor-placement time and re-populates the in-group.

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

This is the data dependency for Chunk 4.  Small — two `// <` markers.

---

## Chunk 4 — What-level transport and navigation

*Depends on Chunk 3.  Its own multi-reset sub-project; design here.*

### The overall desire

The system has an intention — an `I` particle — that it carries forward toward
consciousness.  Right now it sits dormant once the Waft is open.  It should want:

```
A:Lies
  w:Lies
    req:desire,Waft:Ghost/Tour
      req_sent
      started:1
      req:open_What        ← reqonce: opened the first What, waiting
        ttlilt:1,until_ts:T,playing:1   ← if playing, advances on expiry
      req:next_What        ← when advancing: step to sibling, or end-of-Waft handling
```

`reqonce(desire_req, 'open_What')` fires once: opens the first `%What` in the
Waft, sets the cursor to it, arms a ttlilt if "playing" (auto-advance mode).
When the ttlilt expires, Story wakes, `do_fn` sees it timed out and steps
`req:next_What`.  In "pause" mode the ttlilt is never armed — the user advances
manually via `→`.

End-of-Waft: when `cursor_next` finds no further `%What`, the desire req
transitions to a `req:waft_exhausted` child and emits an `o_elvis` for the UI
to handle (loop, stop, prompt for `+time`).

### Navigation arrows and their meanings

Three gestures, three different moves through the What tree:

```
→   continue          step to next sibling %What at the same depth.
                      "keep going the way we were going."

↘   sibling +time     branch: create a new %What sibling beside the current one
                      and step into it.  The current What's accepted/showing set
                      is the branch-point; both threads are now live.
                      "let's explore a parallel line from here."

↓   child +time       dive: create a new %What *inside* the current one,
                      between two chosen Points.
                      "let's go deeper into this pocket."
```

`e_Lies_cursor_next` currently steps `%Doc` within a Waft.  Promoting it to step
sibling `%What` particles is the first gesture.  The `↘` and `↓` gestures need
a new `e_Lies_branch_What` and `e_Lies_dive_What` respectively.

### The caving metaphor

A Waft is a cave system.  Each `%What` is a chamber — a moment of focused
attention with a particular set of Points illuminated.  The `→` arrow walks the
main passage.  `↘` carves a side-tunnel from the current chamber.  `↓` drops
into a pit discovered between two Points in the chamber floor.

The audience follows the spelunker.  The strong frame of reference is the chamber
they're currently in — its Points are its walls.  Moving to the next chamber
(→) is legible because the audience knows where they came from.  Branching (↘)
is "we'll come back to this junction".  Diving (↓) is "look what's down here" —
a sub-thread that resurfaces to the parent chamber when it ends.

This is why `accepted:1` Points carry forward (Chunk 3): the spelunker marks
the wall ("this passage is interesting") and that mark is still there when the
audience returns to the junction.

### `+time` carry-over heuristic

When a new `%What` is created (→ or ↘ or ↓), the heuristic seeds its in-group:

- Points with `accepted:1` AND `showing` → copied forward.
- Points created `< 30s` ago → moved forward (part of this thought).
- Everything else → ghost at 18% opacity (10s rescue window, then fade).

`showing` is the DocMinimap capsule visibility — dormant Points (orb toggled off)
stay in the old chamber.  The rescue window is a `reqonce` timeout on the new
`%What` req: `reqonce(what_req, 'ghost_rescue_window')` arms a ttlilt for 10s;
after expiry, ghosted Points that weren't rescued are dropped.

### `◀◀ rwnd`

Steps back through `%What` siblings in reverse, re-loading the showing set for
that chamber into `%What_Points,1`.  Read-only — no mutations to accepted state.
The "you were here" marker.

---

## Sequencing

- **1** (graft ttlilt) — do now, ten lines, visible immediately.
- **2** (reqy migration) — internal, do together in one PR.
- **3** (accepted persistence) — small, prerequisite for 4.
- **4** (What transport + navigation) — multi-reset, design first, build in slices:
  - 4a: `e_Lies_cursor_next` steps sibling `%What` (not just `%Doc`)
  - 4b: desire req + playing/pause loop
  - 4c: `↘` / `↓` branch and dive
  - 4d: ghost + rescue window + `◀◀ rwnd`

If a single convo must carry the most value: **Chunk 1 + Chunk 3** —
"Points resolve on open" + "accepted set survives reload".

---

## Style notes

- Keep comments that stay true on rewrite; drop dev-mumbling.
- `// < …` marks a *lack* of development.
- `%like,this` naming a lone C object; `/%like,this/written:is` for structures.
  `$values` for sc scalars, `$C` for TheC refs in sc.
- `oai` sync, `roai` async.  `roai` from sync context returns Promise silently —
  verify call-site async-ness when touching particle-creation code.
- `i_req_ttlilt(req, secs, sc)` sets `w.c.has_req_ttlilt` which is Story's
  quiescence gate.  No separate `demand_time_to_think` needed.
- `reqonce(req, name)` stamps `req.sc[name]=1` once per req lifetime (keyed on
  `req.c.oncelers`).  Returns true only on the first call — gate one-shot setup
  (watch_c, installs) inside `do_fn` with it.
- `noserial:1` on reqy channels where the req is keyed by its natural identity.
  Default (serial) only for genuinely unbounded fan-out.
