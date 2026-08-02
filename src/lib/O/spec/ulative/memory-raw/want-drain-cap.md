---
name: want-drain-cap
description: Lies_resolve_wants now caps the %want accumulator at 12 (was unbounded) — fixes the click-cursor slowdown/stall
metadata: 
  node_type: memory
  type: project
  originSessionId: 5856ad5e-04a8-49ab-af3f-c1f5d9b62cc5
---

`Lies_resolve_wants` (Lies.svelte) now **bounds the `req:wants` accumulator to the recent 12**
(drop oldest-first before resolving; newest is last-inserted so it always survives). Was
*"kept, never pruned"* (its own `:864` comment) → an unbounded pile of `%want,$ts` particles.

**Why:** every gesture (click/cold/next/…) appends a `%want` via `e_Lies_want`; the resolver picks
the newest onto the Spotlight and un-resolves the rest. With the pile unbounded it ran an O(N)
`reduce` + an O(N) resolved-relabel loop on EVERY beliefs heartbeat, N growing across a click
session → the editor beat dragged, the newest want resolved late → "stuck on not-the-last-click" +
"terribly slow". 12 > the busiest recorded oracle's 7 wants, so no Story snap shifts.

**Scope:** this kills the unbounded-growth drag only. The ACUTE starvation when a test is mid-run
(editor beat losing to the run's run_phase/ack churn) is the **req\*\* step_stall wedge** the
Peeroleum `.g` comments describe — a separate concern the human cordoned off (see [[creduler-runner-architecture]]).
type-clean, **browser-unverified**. Uncommitted (commits are the human's job).
