---
name: interest-channel-graduated
description: "%Interest Lang↔Lies roster channel: fully graduated to prod; InterestLive is the gate; live handover doc named"
metadata: 
  node_type: memory
  type: project
  originSessionId: 557fc40b-0683-43b9-930d-d72d44800f5e
---

The `%Interest` cluster + Lang↔Lies `waft_roster` channel is **fully in production** on the real
`w:Lies`/`w:Lang`. Reducers are `interest_*` in `Interest.svelte` (pure logic over plain C); Lang
holds an eternal `req:waft_roster` + subscribes, Lies pushes via `Lies_waft_roster_pump`.

**Read `src/lib/O/spec/Interest.md` first when resuming** — it is the live,
git-tracked handover with the full per-phase record (don't trust this memory for detail; the doc is
canonical). As of 2026-06-17, done + verified live: multi-giver foreground arbitration + the
`InterestStrip` switcher; real Sidetrack origination; **per-Interest dual-LE crossfade** (each giver
keeps its own `w/{LE:<waft>}`, foreground resolved via `%ActiveInterest` not a singleton — see
`Lang_active_LE`/`Lang_active_interest`); Phase C polish; the NaviCado Pmirror resolution fix
(`pm === null`). Lenses: reframed to **stay Lies-side** (the future "Lens generalissimo" UI-router is
jotted in the doc, not built); `Lies_order_wafts` sinks the Ting to the bottom.

**The gate is Story Book `InterestLive`** (`wormhole/Story/InterestLive/`, 11 Preps, browser-driven
on :9091 — the human records/verifies snaps). The old `Interesting` Book + its `InterLies`/`InterLang`
stand-ins are **retired/deleted**; the reducers are now gated by the real wire, so the old
"frozen reducer" caution is lifted.

Remaining (in the doc): item 5 (surprise_read resume/diff UI) and the Lens generalissimo.

Codebase traps that shaped this work: [[o-query-wildcards-on-1]] (and the roster do_fn re-runs every
settle tick, so "a step later" must gate on a roster epoch, not on invocation — see the doc's Phase C).
