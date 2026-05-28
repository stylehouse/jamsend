# Waft palmtree trajectory — reqy migration + What transport

Carry-forward for post-🌴 work.  `Waft_spec.md` owns the *design* of the What
tree and transport; this doc owns the *implementation slice* — what's done, what
the reqy migration looks like in concrete particles, and what the remaining two
chunks need.

---

## State of play

Chunks 1–3 are effectively done:

- Write-on-init noise is gone (dige gate in `LiesStore_write`).
- Lazy doc loading: `eager_waft_load` gate in `Lies_sync_waft_docs` (w.c flag).
- Cursor autostart lands cleanly; DocRow glow is live.
- Class-method defs compile; Points resolve on open.
- `LiesStore` owns all IO with noserial reqy channels, `req.sc.finished` API,
  Phase 1/2/3 scan in `LiesStore_run`.
- `requesty_serial` is fully retired from Lies.

---

## Chunk 4 — reqy migration: `open_waft_req` / `open_req` / `compile_pending`

The remaining ad-hoc "not-a-real-reqy" particles in w:Lies.  Each follows the
same pattern as LiesStore: `noserial:1` req keyed by its natural identity,
`req.sc.done` as the settled marker, driven by `LiesPersist_run` (renamed from
the current procedural `LiesPersist` loop).

### 4a — Waft load reqy

**Now:**
```
w:Lies
  open_waft_req,path:Ghost/Tour,done
```

**After:**
```
w:Lies
  reqcons:1
    reqcon:waft_load    noserial:1
  waft_load:1,path:Ghost/Tour
    req_sent
    done:1
```

`LiesPersist` becomes `LiesPersist_run(A,w)` that calls `reqy(w, {k:'waft_load',
noserial:1, do_fn: LiesStore_waft_load_do_fn})`.  `do_fn` does the current
`open_waft_req` body: reads snap via `LiesStore_read`, decodes, installs waft,
registers `watch_c` → `Lies_waft_save`, stamps `done:1`.

The `done` check / re-sync path (`waft_req.sc.done → Lies_sync_waft_docs`) stays
the same logic; `do_fn` handles `!done` and early-exits on `!req.sc.finished`.
`LiesPersist_run` returns false until all `waft_load` + `doc_load` reqs are done.

### 4b — Doc load reqy

**Now:**
```
w:Lies
  open_req,path:Ghost/test/Hello.g,from_waft:Ghost/Tour,done
```

**After:**
```
w:Lies
  reqcons:1
    reqcon:doc_load    noserial:1
  doc_load:1,path:Ghost/test/Hello.g,from_waft:Ghost/Tour
    req_sent
    done:1
```

`Lies_sync_waft_docs` calls `reqy(w,{k:'doc_load',noserial:1}).oai({doc_load:1,
path,from_waft})` instead of `w.oai({open_req:1,…})`.  `do_fn` does the current
`open_req` body: reads source via `LiesStore_read`, fires `Lang_open_doc`, stamps
`done:1` and `base_dige`.

`LiesPersist_run` settled = all `waft_load:…,done:1` AND all `doc_load:…,done:1`.

### 4c — Compile write reqy

**Now:**
```
w:Lies
  compile_pending,path:Ghost/test/Hello.g,gen_path:gen/test/Hello.go,done:1
```

**After:**
```
w:Lies
  reqcons:1
    reqcon:compile_write    noserial:1
  compile_write:1,path:Ghost/test/Hello.g,gen_path:gen/test/Hello.go
    source: …
    dige: 87678b3…
    req_sent
    done:1
```

`e_Lies_compiled` calls `reqy(w,{k:'compile_write',noserial:1}).oai({compile_write:1,
path,gen_path}, {source,dige})`.  `e_Lies_compiled`'s current `delete pending.sc.done`
maps to the reqy pattern: `roai` finds the existing req and `.i()` updates `source`
and `dige` in place (fresher compile overwrites staler one).

`LiesRealised` becomes `LiesRealised_run`, driven by `reqy.do()`.  `do_fn`:
- calls `LiesStore_write` for the gen path if `!nogen`
- fires `Ghost_update_notify`
- fires `Lies_compile_settled`
- stamps `done:1`

### 4d — LangGraft ttlilt

This is where `reqy` + `ttlilt` pays off most visibly: Points resolve on first
open instead of after the next keystroke.

**Graft req on docC:**
```
docC
  reqcons:1
    reqcon:graft    noserial:1
  graft:1,path:Ghost/test/Hello.g
    ttlilt:1,until_ts:T    ← armed while %Compile/%Pending:1 set
```

In `Lang_graft_points`, after the cache-key early-return:

```js
// If compile is still pending, arm a ttlilt so Story holds open until
// it settles.  The next tick after Lies_compile_settled clears %Pending
// will have defs populated — graft will resolve then.
const pending = job?.o({ Pending: 1 })[0]
if (pending && points.length) {
    const graft_req = H.reqy(docC, {k:'graft', noserial:1})
        .oai({graft:1, path: active_path})
    H.i_req_ttlilt(graft_req, 0.5, { waiting_for_compile: 1 })
    H.demand_time_to_think(550)
    return
}
// No pending: clear any stale graft ttlilt so it doesn't hold Story
docC.r({graft:1}, {})
```

This is the one place `reqy` + `ttlilt` makes a user-visible difference in
the base case.  The rest of 4a–4c is internal tidiness.

### Full w:Lies snap after chunk 4

```
w:Lies
  reqcons:1
    reqcon:waft_load     noserial:1
    reqcon:doc_load      noserial:1
    reqcon:compile_write noserial:1
    reqcon:wwrite        noserial:1
    reqcon:wread         noserial:1
  waft_load:1,path:Ghost/Tour
    done:1
  doc_load:1,path:Ghost/test/Hello.g,from_waft:Ghost/Tour
    done:1
  doc_load:1,path:src/lib/p2p/Peerily.svelte.ts,from_waft:Ghost/Tour
    done:1
  Store:1
    wrote_at:wormhole/Ghost/Tour/toc.snap: 1748391234.567
  examining,active_path:Ghost/test/Hello.g
    What_Points,src_Waft:Ghost/Tour
      ← src: %Doc:1 ref
  Opt
    nogen
  Waft:Ghost/Tour
    Doc,path:Ghost/test/Hello.g
      Points:1
        Point,method:Idzeugnosis
        Point:Idzeuganise
    Doc,path:src/lib/p2p/Peerily.svelte.ts
      Points:1
        Point:Pier
        Point:emit
  loaded_doc,path:Ghost/test/Hello.g,gen_path:gen/test/Hello.go,base_dige:50d102…
```

Gone from the snap: `requesty_rw_queue*`, `open_waft_req`, `open_req`,
`compile_pending`.  Everything that was ad-hoc string-keyed is now in a reqcons
channel.

---

## Chunk 5 — `accepted_entries` persistence (unblocks chunk 6)

Two `// <` markers in `e_Lies_accept_What_Point` (`%LiesCurse` ~L209).

When a user accepts a Point into the active What, it lands in `%What_Points,1`
in-memory but is never written to the Waft snap.  So a reload loses the accepted
set — the `/%Doc/%Point` particles survive (they're in the snap already), but
which ones were *promoted* to the active What is gone.

**Plan:** stamp `accepted:1` on the `%Point` particle itself (it's already in
the Waft snap tree).  `Lies_set_examining` reads it back at cursor-placement time
and re-populates `%What_Points,1` from the `accepted:1` set.

Particle layout:
```
Waft:Ghost/Tour
  Doc,path:Ghost/test/Hello.g
    Points:1
      Point,method:Idzeugnosis,accepted:1
      Point:Idzeuganise
```

`Lies_waft_save`'s `enWaft` already walks `Doc/%Point` children — `accepted:1` is
an sc scalar so it round-trips through the snap format with no encoder changes.

`e_Lies_accept_What_Point` additions:
```js
point.sc.accepted = 1
waft.bump_version()   // triggers Lies_waft_save throttle
```

`Lies_set_examining` / cold-start guard: after installing `%What_Points,1`, walk
`src_C.o({Point:1})` and re-add any with `sc.accepted` to the What's in-group,
calling the same accept helper.

`e_Lies_cursor_next` (the `→` button): promoted to stepping sibling `%What`
time-slices in Chunk 6; for now it just steps `/%Doc` as-is.

---

## Chunk 6 — What-level transport (its own sub-project)

Lives in `Waft_spec.md` ~L161–228.  Depends on Chunk 5 (`accepted_entries`
readable on reload) being done.

Key mechanics recap:

**The in-group and `→`.**  Navigating A,B / A,C / A,D is done by promoting A
back to the in-group, which causes `→` (`e_Lies_cursor_next`) to step through
sibling time-slices (`%What` particles) rather than sibling `%Doc` particles.
`→` currently steps `%Doc`; it needs to be promoted to step `%What` when the
active examining particle has a `%What` parent.

**`+time` — create a new time-slice.**  The `◀◀ rwnd  ‖ pause  ＋time` bar.
`+time` runs the carry-over heuristic:
- Points with `accepted:1` that are `showing` → copy forward into the new What.
- Points created `< 30s` ago → move forward (they're probably part of this thought).
- Everything else → ghost at 18% opacity for 10s (rescue window) then fade.
The new `%What` is written to the Waft snap as a new time-slice sibling.

**`◀◀ rwnd`.**  Steps back through `%What` time-slices in the same `%Doc`
group; the showing set for that slice is re-loaded into `%What_Points,1`.

**Ghost display.**  DocMinimap shows ghosted capsules from the prior slice's
`%Pmirror` set at reduced opacity.  Clicking a ghost → rescue it into the
current slice (un-ghost, `accepted:1`).

**The showing gate for `+time`.**
```
// only propagate if showing in the current What
const to_carry = current_what_points.filter(p => p.sc.showing)
```
`showing` tracks whether the Point's capsule is currently visible in the minimap
balloon — see DocMinimap `orb=showing` toggle.  Not-showing = dormant = stays in
the old slice.

---

## Sequencing

- **4a–4c** are internal tidiness; do together, small PRs.
- **4d** (LangGraft ttlilt) is load-bearing — do first within chunk 4.
- **5** is small (two `// <` markers) and a prerequisite for 6.
- **6** is its own multi-reset sub-project; don't start until 5 is stable.

If a single convo must carry the most value: **4d then 5** —
"Points resolve on open" + "accepted set survives reload".

---

## Style notes

- Keep comments that stay true on rewrite; drop dev-mumbling.
- `// < …` marks a *lack* of development.
- `%like,this` for a lone C object; `/%like,this/written:is` for structures.
  `$values` for sc scalars, `$C` for TheC refs in sc.
- `oai` sync, `roai` async.  `roai` from sync context returns Promise silently —
  verify call-site async-ness when touching particle-creation code.
- `noserial:1` on reqy channels where identity is the natural key (path, dige).
  Omit (default serial) only for genuinely unbounded fan-out that needs counting.
