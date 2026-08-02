---
name: vyto-nested-render-built
description: "Vytui now DRAWS the nested tree (was flat — prototyped-but-undrawn); recursive scope layout, gated additive; built+compiles+live but nested pixel-verification OWED (nested Books won't stand)"
metadata: 
  node_type: memory
  type: project
  originSessionId: c04d18c2-95b5-4c6f-9e9e-1966a05f5bee
---

2026-07-28: closed the long-standing gap the human laughed about — "we worked so much on treeing Vyto
prototypes and then it apparently isn't what Vyto does yet." The MODEL always solved the tree
(`Vyto_solve_scope` writes each child's `.c.T`/`.c.poly`, gated `w.c.nested`, proven by the VytoNest/
Nestcut Books); **Vytui just never descended** — `all_rows` returned `mirror.o()` = top rows only.

**What I built (Vytui.svelte, render-only — model untouched):**
- `all_rows` → `tree_nodes(w)`: a Node tree walk, GATED TWICE so a flat glass is byte-and-cost identical —
  (1) descent only when `w.c.nested`; (2) a kid is walked only if the model SOLVED it (`.c.T`) or is
  departing, so depth == the solve's reach and a deep-but-unsolved mirror subtree (a flat scan into an
  organ's guts) is never entered.
- `build_cells` is now a recursive `layout(nodes, framePoly, gap)`: cut each scope's walls from the
  siblings' SPRUNG seeds against **the parent's own sprung poly** (gap 0 — a scope FILLS its parent),
  emit parent-before-child (SVG paint order = children on top), lifted sibling ordered LAST within its
  group. Children always tile the VISIBLE parent because they're cut against it, not against the model's
  static `.c.poly`.
- **Spring/lift/`#each` keyed by a tree-unique `key` (`parentKey>tok`), NOT tok** — a mirror `tok` is only
  LOCALLY unique (Vyto_scan_walk: two byte-identical cousins share a tok). adopt/integrate/jump/build all
  rekeyed. Pointer→model hold fires for TOP cells only (`key===tok`); the model's %Hold scope is tok-keyed
  and would over-pin a same-tok cousin. Nested cells lift visually only.
- A container cell (`hasKids`) suppresses its OWN label+face and renders as a bare frame (`.cell.scope`);
  `.cell.nested` (depth>0) draws a finer wall. Both classes only ever ADD (flat never emits them).

**Verification state (2026-07-29):** both files compile (bundle HTTP 200) and are LIVE. **VytoNest ran GREEN
4/4** on a fresh runner (the earlier `begun`-hang was the CHURNED runner, NOT the Book — a clean `reload`+first-
run cured it; don't run several Books between reloads or the decode degrades to total:1, [[runner-wedge-begun]]).
The GATE is pixel-confirmed: VytoNest's LAST step re-commissions the rig FLAT as its control, and a post-`done`
`runner_shot --svg` (now serialises `.vyto svg.viewport`) showed EXACTLY the root `Rig:main` cell, no
scope/nested classes — so the render correctly does NOT descend when `nested` is off / kids lost their `.c.T`.
**NESTED PIXELS NOW CAPTURED HEADLESSLY (2026-07-29).** VytoNest couldn't be shot nested — its beat 4
re-commissions FLAT as the control, so by `done` the glass is flat, and the single-threaded runner won't reply
to a shot mid-drive (the transient nested step-3 window is gone before an external poll sees it). FIX: authored a
twin **VytoNestRest** Book (Vytonation.g, world MUST be named VytoNestRest) that reuses VytoNest_seed+nest+witness
VERBATIM but RESTS nested as its final beat (total=3, no flat control). Run it, and at `done` the descended glass
STANDS → `runner_shot --svg` lands. The shot: **6 paths** (was 1 flat) — `Rig:main`=`.cell.scope` (root frame,
no label), `Cog:A`=`.cell.nested.scope` (a nested cell that is ITSELF a scope over A1/A2 = a scope-in-a-scope),
`A1 A2 B C`=`.cell.nested` leaves; 4 idents (leaves labelled, containers bare). VytoNestRest is GREEN 3/3
caveat:0 (recorded fixtures) — a permanent nested-render-RESTS regression test AND the shootable reference.
Feeding a REAL nested tree (Heist collection scope) is still Radio's-agent side — sourcing unfed; tenants hand a
FLAT grapple list, so commission with `Vyto_commission_on(w, grapples, fresh, priced, nested=1)` AND give the
grapple root real `.o()` children. See [[vyto-process-engines]] [[vyto-foam]] [[story-step-false-flags-encode]].
