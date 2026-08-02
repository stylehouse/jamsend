---
name: roles-divide-addresses-deliver
description: "the mature address+role model: role = kind (gate/filter/pick), prepub address = delivery; relay role addr is ONE socket not a fan-out — a 2nd runner tab silently eats ALL role-addressed frames"
metadata: 
  node_type: memory
  type: project
  originSessionId: 7dad841a-1179-4f80-a256-604c7b2ce122
---

**Roles divide, addresses deliver** (canonical: `Cluster_spec.md §3.2a`; landed 2026-07-05). A **role** (editor|runner) is a *kind* — it gates behavior and picks candidates. An **address** (prepub) is an *identity* — it decides which socket a frame lands on. The relay binds **ONE socket per addr** (`become runner` = a single slot, NOT a subscription/fan-out).

**Why:** with two runner tabs (one local to the editor's relay :9092/staging, one across the r2r bridge on :9091/dev), the local one stole the `runner` role slot and ate EVERY role-addressed frame: all 286 wormhole_replies (bridge runner wedged at `begun`, no %Good ever landed), the pongs (its watchdog read DEAD → socket flap every ~35s), grant_offers, ghost_compiles (stale gen on the other runner). Socklog-proven (`wormhole/_socklog/*.jsonl` — "(local)" vs "(forwarded over bridge)" is the tell; `🎭 become runner — bound addr=runner (locals: …)` names the thief).

**How to apply:** every editor→runner frame is ADDRESSED to a prepub (the `become_book` pattern: pick by role from the roster, deliver via `Lies_runner_pier` + `Peeroleum_send_to`). Role broadcast survives ONLY as the identity-less fallback + runner→editor direction (one editor per relay = structurally singular). Concretely: wormhole replies → the corr's asker prepub (corr = `${Lies_self.prepub}-${ts}-${n}`, the LIVE asker — beats grant.for's frozen tier); pong → the pinger's `from`; grant_offer → the grantee; ghost_compile → fanned to every roster row. See [[robustness-plan]], [[engage-c2-dispatch]], [[runs-broadcast-both-runners-fix]].

**VERIFIED live 2026-07-05** (bridge runner `49dee91d`, editor reloaded): the exact A/B — MusuReco `failed 0/11` against the pre-reload editor (starved, no %Good landed) → `done 11/11 100%` (2 fuzz-ok caveats) once addressed replies were live. `ping` also confirmed `self === clustation_self`, so the whole wormhole-read chain (grant → addressed wormhole_reply reaching the asker) works with the fix in. `needsFSA:false` — MusuReco rides the wormhole proxy.
