---
name: swarm-invite-features
description: "Completed Swarm invite/chain/protocol features (all green×2) — ReInvite chain (re-assignable, %ChainRoot lineage), Blotter serial sheet (one-time batch, count DERIVED), Peeroleum protocol back-signal (unenabled type→no_protocol), and the seal prepub-binding hole FIX (bind prepub not pub)"
metadata: 
  node_type: memory
  type: project
  originSessionId: 2f2e32df-77de-4509-9ea4-3454f9ecd5a7
---

Completed, green×2 Swarm invite-family features (details distilled; these are stable).

**ReInvite chain (SwarmChain).** A re-assignable A→B→C→D invite chain: TIP grants; `%ChainRoot` carries the lineage so a re-assigned invite traces back to its origin. Green×2.

**Blotter serial sheet (SwarmBlotter).** A one-time serial batch — the claimed count is DERIVED (from the ledger), never a stored counter. Green×2.

**Peeroleum protocol back-signal (PereComplain — "Organ 2").** An unenabled message type gets a `no_protocol` back-signal rather than silent drop; the invite trilogy of protocol handlers is DONE. Green×2. (Neighbour: PereProof, whose per-step fixtures went stale-red after commit `0662da0a` changed 6 ghosts it uses without re-recording — that red is fixture-staleness, not a regression; [[nested-replace-in-do-fn]] is the transport fix that was proven snap-neutral against it.)

**Seal prepub-binding hole (FIXED).** The seal bound the friend's **pub** where it should have bound the **prepub** → an identity-hijack hole (a different identity presenting the same pub could seal). Fix threaded `Swarm_page_bound` through ~5 sites; **SwarmSpoof** green×2 gates it. This is the security tooth behind the compact-invite presig-MAC path.

Security posture across all four: replying to a guessable probe confirms the door (so unknown serials refuse LOCALLY — see [[invite]]); a revocation tombstone is NEVER dropped ([[revocation-tombstone-durable]]); trust routes on the crypto identity, never the cosmetic [[cluster-identity-nick]]. See [[invite]], [[identity-thing-jamsend-track]], [[p2p-two-stacks-proto-vs-g]].
