---
name: tyrant-g-superseded-by-swarm
description: "Ghost/N/Tyrant.g is a MOCK society-cabinetry island that NOTHING calls (only its own in-file Book harness). Its job (stranger→trusted-friend admission) is done for real by Swarm.g with the OPPOSITE philosophy Swarm_spec chose ON PURPOSE (per-peer authority, 'no Tyrant'). The name 'Tyrant' is overloaded across 3 different jobs. Recommendation: retire — pending the human's call."
metadata:
  node_type: memory
  type: project
  originSessionId: 334456e9-f1e5-4e61-a0c4-7b0aaa37eec7
---

**`Ghost/N/Tyrant.g` = Covenant_design.md's "society cabinetry" (M1 vouch + M2 policy-gated
 `%req:join` admission), and it is a MOCK** (`say_vouch`/`hear_vouch` → `return true`, "a real
  verify is a later layer"; `Tyrant_verify` is the `startsWith` shim). **Nothing calls it** — grep
   for `hear_vouch`/`req_join`/`req_admit`/`Tyrant_*` across all `.g` (minus gen + Tyrant.g itself)
    hits ONLY `Idzeuzia.g`, and that's the *old ① server* (`M.amTyrant`, `TYRANT_URL` fetch), not
     Tyrant.g's methods. So Tyrant.g's M1/M2 is exercised by nothing but its own in-file Book harness
      (`Run_A_PereTyrant`, lines ~19-129). Drop it from `CREDULER_GHOSTS` (`LiesLies.svelte`, the
       Tyrant line ~60) and delete → nothing breaks but its own Book.

**"Tyrant" is ONE name doing THREE jobs — keep them straight:**
 - **① old third-party-authority SERVER** (`Idzeuzia.g` `M.amTyrant`/`TYRANT_URL`, `Cluster_spec §1`)
    — REJECTED ("ran ~90% red").
 - **② Covenant's Tyrant.g = SOCIETY cabinetry** (meet→prove→trust→admit two FRIENDS) — what the file
    IS. **SUPERSEDED by `Swarm.g`**, which does the same concern with real ed25519 + the philosophy
     `Swarm_spec` explicitly chose OVER a Tyrant (§0/§6/§11: "no Tyrant, no cert — each peer is the
      authority for its own friendships"). Swarm's Books (SwarmDoor/Invite/Chain/Blotter) all green.
       And Covenant's ONE good idea is already re-homed: `Swarm_spec §10.1`'s `challenge:voice|name`
        invite policy IS "Covenant_design.md's claim→challenge→prove→verdict ladder standing at the
         invite door."
 - **③ Peeroleum_spec §5's "Tyrant.g seam"** = TRANSPORT/relay/runner-flock admission (who's allowed
    on the wire) — a REAL open job, but that's **cluster-trust, NOT friendship** ([[cluster-trust]],
     [[runner-fleet-goal]]). The current mock Tyrant.g does NOT fill this seam. And the §5 attach point
      is *Peeroleum's* `hear_<verb>` dispatch + `Peeroleum_on` registry (Covenant: "they own no carrier
       code… plug in like hear_hello") — it survives whether or not Tyrant.g exists.

**Recommendation — GREENLIT by the human 2026-07-26 (runners reloaded, so the boot-verify is now
 doable); NOT yet executed, handoff-ready:** (a) retire
 `Ghost/N/Tyrant.g` + drop the `CREDULER_GHOSTS` line; (b) `Covenant_design.md` → `spec/history/`
  AFTER folding its still-live forward-note (Garden.g / M3 social cultivation — genuinely net-new,
   never built) into `Swarm_spec §6.6/§7`; (c) re-point `Peeroleum_spec §5`'s "Tyrant.g" at the
    cluster-trust seam (③) so a future reader doesn't resurrect the mock society file thinking it's
     transport-authz. **NO RENAMES (human, 2026-07-26): "DONT RENAME NOW that would be confusing."
      `Peeroleum` KEEPS its name; `Peerily` stays what it is (the prototype) — the specced
       Peeroleum→Peerily endgame is NOT now. Re-point §5's pointer TEXT only, never rename the file.
        Blessed doc vocabulary: wire / envelope / carriers / invite.** A retire touches: file · `CREDULER_GHOSTS` · the `%Doc` in `Waft:Ghost/Net/*`
      (files surface as `%Doc` in the Waft tree — not just an fs move) · spec cross-refs · gen `.go`
       (auto). Related: [[p2p-two-stacks-proto-vs-g]] [[cluster-trust]] [[runner-fleet-goal]].
