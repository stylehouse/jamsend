---
name: g-capture-oai-needs-let
description: "in .g, $:cap captures create-chain legs (i A/B$:cap) + o-drills only, NOT an oai verb result — the compiler SILENTLY DROPS $:cap on `recv oai peels$:cap`; capture an oai with `let X = recv oai peels`"
metadata: 
  node_type: memory
  type: reference
  originSessionId: a3077b3c-d41a-4880-939d-0bb7c8c747ac
---

`$:cap` (LangTiles row-capture, [[langtiles-peel-syntax]]) only binds:
- a **create-chain leg**: `Alicew i Peering,name:alice$:AlicePeering/Pier,pub:bob$:AlicePier`
- an **`o`-drill**: `H o A:Alice/w:Tyrant/Peering/Pier$:pier`

It does **NOT** bind a standalone **`oai` verb statement**: `AlicePeering oai Pier,pub:bob,req$:AlicePier` compiles to `AlicePeering.oai({Pier:1,pub:"bob",req:1})` with the `$:AlicePier` **silently dropped** — no `let AlicePier =`. `lang-compile`/FlockCompile PASS (the JS is valid); the failure is a **runtime ReferenceError** at the next use of the never-declared var, which **halts the rest of the method** (everything after the mint just doesn't run, no error surfaced in the snap).

**Capture an oai result with `let`:** `let AlicePier = AlicePeering oai Pier,pub:bob,req` — the proven idiom (cf `let proto = pier oai protocol`, `let hello = proto oai hello`).

Bit me building the Pier flock ([[oai-req-mainkey-only]]): `oai Pier,$pub,req$:cap` in Lake_sides_up/Tyrant_sides_up dropped the capture → `AlicePier i %Ud` threw → PereTyrant's trust/%Ud never set AND PereStaple's noop never sent (the missing `witnessed:step_2`). One silent-drop, two distant symptoms. Caught by reading the gen `.go` (the lowering showed no `let AlicePier =`); FlockCompile alone can't catch it. Closing this as a LangTiles seam (capture-on-verb-result) would be a heading-L win.
