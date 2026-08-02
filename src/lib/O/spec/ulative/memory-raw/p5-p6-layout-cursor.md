---
name: p5-p6-layout-cursor
description: "P5 Keep layout service BUILT+gated; P6 cursor-memory mechanism gated; the live position-resume bug diagnosed (Point-level, owner territory)"
metadata: 
  node_type: memory
  type: project
  originSessionId: f0479bcc-815c-423c-b7b3-65406dfb41f5
---

2026-06-30 (autonomous overnight, after [[lake-fleet-rerecord]]). Built+gated on the live runner, uncommitted:

**P5 — the layout (scope,key) service** (Backbone_plan P5). `Lies_keep_layout_host/_get/_set(w, scope, id, key[, val])` in Lies.svelte — ONE front door over three Keep homes: `'global'`→Keep ROOT sc, `'waft'`→`WaftTimes,of_Waft:<id>`, `'lens'`→NEW `Layout,of_Lens:<id>`. get = RAW lookup ($derived-safe); set is COALESCED (write == stored value → no-op, no bump → an ave→Keep mirror can't feed a write loop = the write-only-on-user-change discipline); set bumps the Keep ROOT so the top-only watch_c re-saves a WaftTimes|Layout CHILD mutation. The existing typed `Lies_keep_cfg_*`(per-Waft)/`Lies_keep_pref_*`(global) stores stay for current callers (Waft minimise, Langui expand) until P6 migrates them. NOT built (spec said "no clients yet — prove the shape first"): the Keep's-own-Funkcion hoist→suggest-Lens wiring. GATE: LakeKeep `e_Lies_keep_selftest` asserts a set→(reopen-like raw get) round-trip per scope + the coalesce no-bump — markers `layout_{waft,lens,global}_round_trips` + `layout_set_coalesces`, GREEN clean (caveat:0).

**P6 — cursor-memory mechanism** (the part that's verifiable). LakeKeep gate now also drives `Lies_keep_note_cursor`→`Lies_keep_resume_what` DIRECTLY (records cursor on the 2nd What, resolves back to it): markers `cursor_memory_resumes_last_what` + `cursor_memory_not_first_what`, GREEN. Proves the record→resolve chain the foreground's resume branch (Lies.svelte e_Lies_foreground_waft:228-230) leans on is SOUND.

**The live "cursor don't resume" bug — DIAGNOSED, owner territory.** NOT the Keep mechanism (gated sound). It's downstream and LIVE-ONLY: (1) the cursor-memory wiring is role-gated to `Lies_role==='editor'`, and `Lies_role` returns UNDEFINED for a Lies inside a Story Run (LiesLies.svelte:81, the >1-Lies short-circuit) → can't exercise the live wiring in ANY headless/Story gate; (2) the What/Doc level WORKS live (owner confirmed "the What stays there") — the gap is the within-Doc POINT/line level: the live cursor src is a `Point` (mainkey Point, value bare 1, identified by `method:`/`from=`/`to=`), and `Lies_resolve_locator`→`Lies_locate_in_waft` only walk What+Doc, never Point → a Point src records an unresolvable `Point:1` locator → resume returns undefined → lands on first. Fixing it = Point-level cursor-memory, which is ENTANGLED with the UNSOLVED Point re-anchoring problem (method names like `bm_<offset>` drift when you edit above them; the open NEXT in [[req-langoer-built]]'s lineage / Lang_handover). Do with the owner, live, on :9091.

**DEFERRED to owner** (verification boundary the user set — "P4+5+6 if nothing unhandlable emerges"): rest of P6's UI layout clients (Brink pose, Langui minimap_open, DocTing, MiniWaft, InterestStrip — bind to P5, browser-verify the reload-persistence); %FromWhat click-through UI; per-(Interest,Waft) keying; the live Point-level position-resume. And ALL of P4 (cut-over + D7 renames) — destructive, collides with the human's live LiesLies/Auto WIP, changes live focus → needs owner on :9091.
