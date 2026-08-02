---
name: aw-req-level-uniformity
description: "H/A/w/req is really H/(A|w|req)**; reqdo_sweep's heartbeat enters ONLY at the w level, so tests over-mint w; the rule for when to mint a w vs float a req**"
metadata: 
  node_type: memory
  type: project
  originSessionId: 5cc0cd68-8ccd-4b37-bc05-d53e3569ab8a
---

The H/A/w/req scheme is not a fixed 4-deep ladder — it is `H/(A|w|req)**`: one homogeneous forest under H where `level%ark` (persistent A/w vs transient req) is the ONLY real distinction. The A/w/req names + the Aw string-path are just elvis-routing legibility for the top named levels; below w there is no string path at all (Hovercraft.design.md §1, §9 — "dive_middle treats them identically; the r in HAwr was always a placeholder for req"). The MECHANISM is already unified; the transience AXIS is what's real.

The ambient heartbeat (`reqdo_sweep`, Housing.svelte.ts) enters the forest at EXACTLY one level: it walks `H → A.o({w:1}) → w.do()`, nothing else. So a req** reacts to ABSENCE (peer silence, dropped ack) only if it sits under a swept w with c.up stamped. A req** floating BARE under H gets NO heartbeat — only event-driven reqyoncile, which is the lost-wakeup wedge ([[ttlilt-not-a-keepalive]]). That single-entry is why test authors reflexively mint `A:Side/w:Foo` for anything they want pumped: a w is the only way into the sweep. The w-duplication is the shadow of reqdo_sweep not yet being level-uniform — it special-cases w, lagging the H/(A|w|req)** design.

**Why:** Peeroleum/Peregrination tests (Tyrant.g etc.) duplicate loads of `w` (an A:Side/w per peer + more within). The user wants to tell the tests how to stop over-minting w.

**UPDATE (PereStaple swarm refactor — see [[peeroleum-swarm-refactor]]):** the "do NOT collapse Alice/Bob, you'd merge their carriers" caveat below was DISPROVEN — inbox/outbox/seq already lived on the Pier, only the carrier was w-bound, and it moves per-Peering cleanly. PereStaple now runs ALL peers under ONE `w:Peers` (Peering+Pier as typed serial-reqs), and making Peering a req IS the level-uniform fix in miniature: `w.do()` now cascades Peering→Pier→handshake, so the heartbeat reaches the nested flock from the w entry (no more wrangler-only re-pump). The deeper "make reqdo_sweep itself level-uniform" is still the global version.

**How to apply:** Mint a fresh `w` ONLY for an exclusive w-affordance — (1) peer/transport isolation (own active_transport + inbox: the LEGIT two-peer Alice/Bob case, do NOT collapse those — you'd merge their carriers), (2) an independent snap boundary, (3) independent absence-watching. Otherwise float a `req:Name**` under the EXISTING w, stamp c.up once (tests already hand-stamp Peering.c.up — [[nested-req-needs-cup-stamped]]), reconcile on the triggering frame. Caveat that bites: "in name-space" must mean under a SWEPT w, not bare under H (bare-under-H req** is event-only — fatal for anything watching for silence). The deeper fix that dissolves the scaffolding: make reqdo_sweep level-uniform (sweep any ark-node opted into the pump across the (A|w|req)** forest, not just A→w) — the design's own convergence direction. Related: [[reqy-deleted-c-native]], [[central-stuff-housing-hovercraft]].
