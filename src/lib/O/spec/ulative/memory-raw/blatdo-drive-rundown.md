---
name: blatdo-drive-rundown
description: the mid-rollover snap (stray finished req:BlatDo + ran-behind + Rundown no-ok) fixed by driving Rundown at run-landing instead of finishing BlatDo early — NOT by hiding it
metadata:
  node_type: memory
  type: project
  originSessionId: 5856ad5e-04a8-49ab-af3f-c1f5d9b62cc5
---

LakeTiles steps sometimes snapped the Lies runner **mid-rollover**: a stray `req:BlatDo,…,finished`
+ `req_sent`, `ran:` a moment behind, `req:Rundown` missing its `,ok`. Fixed at the BEHAVIOUR
(LiesCortex.svelte). Two wrong turns first, both instructive:
- a drop-Entcase hiding BlatDo from the snap — rejected, "duct-taping over dials we don't want to see."
- a bridge `%ttlilt` on **eternal** req:Rundown — WRONG: **a ttlilt rides a req that FINISHES**
  (Hovercraft.svelte:367 "should be inside one that does"; hygiene at :442 drops ttlilts only from
  finished reqs). The ttlilt is the timing slice, narrowly — not the work. If a req can't finish,
  the pattern is `req/req/ttlilt`: a finishing CHILD holds it. BlatDo already IS that child of Rundown.

**Root cause:** `req_run_method` (Pantheate) ended a run with `reqyoncile(blatdo,{finished:1})`.
`finish()` (Stuff.svelte.ts:657) drops BlatDo's ttlilt immediately, but Rundown records `%ran`+`ok`
only on a LATER pass (the finished-branch of e_reqyonciliation, Hovercraft:279, just
`host.finish + feebly_ponder` — it does NOT drive the host). poll_step (Story:1855-1874) snaps when
no ttlilt is held → it fired in that gap.

**Fix (drive Rundown, don't finish BlatDo early):** `req_run_method` now flags `blatdo.c.run_done`
(off-snap) and `reqyoncile(blatdo.c.up /* Rundown */, {see})` — `host._req_do_one(rundown)`
(Stuff:635) dispatches `req_Rundown` directly, bypassing maz. `req_Rundown` checks `blatdo?.c.run_done`
BEFORE minting: records `%ran`, `req.finish(blatdo)` (the clean done-signal — drops the ttlilt) then
`req.drop(blatdo)` (keeps the finished instance out of the snap — a finished req snaps as a leaf,
Hovercraft.design.md §4), prunes old ran, oks — all in that one driven pass. BlatDo's ttlilt now
holds the snap from fire THROUGH the record (nothing yanks it early), so the step only ever snaps a
settled Rundown. Single ordering-independent delivery (the run_done flag is set before the post). Stale
re-compile: moment changes, run_done never matches the new in-flight BlatDo, stray landing ignored.

Type-clean (lines 414/442 `i_req_ttlilt`/`reqyoncile` not-on-House are baseline ghost-method noise,
same as the original reqyoncile line). Authoritative ref = spec/Hovercraft.design.md (§4 finished reqs
captured as leaves; §6 e_reqyonciliation host-drives). Uncommitted, run-UNVERIFIED on :9091. Related:
[[want-drain-cap]], [[ttlilt-not-a-keepalive]], [[reqy-deleted-c-native]], [[nested-req-needs-cup-stamped]].
