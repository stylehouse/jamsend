---
name: sign-real-carrier-not-loopback
description: "THE main-spring next move (Radiobuddies): per-frame signing + real verify_trust must move TOGETHER with running friend-to-friend over a REAL carrier — signing a by-reference loopback is theater. The relay is ALREADY real (don't gate on WebRTC); it's a PORT not a build (the Idento key exists). Gate = the two-tab fingers-proof. Transport agent's zone."
metadata:
  node_type: memory
  type: project
  originSessionId: 334456e9-f1e5-4e61-a0c4-7b0aaa37eec7
---

**The coupled rung that turns "green everywhere" into "real."** Two facts pair, and must move
 together (agreed with the human + another agent, 2026-07-26):

1. **Transport crypto is mock v1.** Society signs for real (Swarm grants: ed25519, throws on
    forgery). The **Peeroleum transport does NOT**: `header.sign` is an unbuilt seam (Tribunal
     reserves `[sig]`), hello-verify is `startsWith(pub)` (Peeroleum.g ~150), trust-verify is a
      no-op (~157-160). `Peerily.svelte.ts` is the REFERENCE for the owed port — per-frame
       emit-signing (`emit` signs every frame, ~672) + real `verify_trust` (granter sig, ~1011).
2. **The real carrier is still a by-reference loopback.** EVERY Swarm/Musu/Heist Book rides
    **`Lake_link`** — the real Peeroleum *envelope* (outbox→inbox→ack→handshake) over an
     **in-process by-reference mock carrier** (`Swarm.g:484`: "the Books' wire is Lake_link's mock
      pair; THIS is the production twin — one real websocket"). No Book crosses a real wire.
       ([[jamsend-state-survey]] = LOOPBACK-ONLY.)

**Why they're inseparable: signing a by-reference loopback is THEATER.** Over `Lake_link` the frame
 is handed to the peer as a JS object reference — no wire, no middle-box, nothing to forge. So
  `header.sign`/`verify_trust` protect NOTHING until a frame crosses a real carrier. Land the crypto
   alone → green fixtures of a threat model never exercised. Cross them → real.

**My two refinements (don't lose these):**
- **The relay is ALREADY real — don't gate "real" on WebRTC.** `Socket_real` (WS relay) is built,
   carries editor↔runner daily, and SwarmDoor sealed *two real tabs over it* (manual, 2026-07-07).
    WebRTC is a black-hole mock — a LATER rung. Cheapest crossing = friend-to-friend over the
     **relay that exists** + signing. And the relay IS the untrusted middle-box, so signing has FULL
      teeth there (it sees/routes every frame).
- **It's a PORT, not a build.** The signing key already exists — Swarm/Cluster `Idento` signs grants
   for real; the SAME key signs frames. `header.sign` = apply the existing key one layer up, in the
    envelope. Peerily shows both halves.

**The gate = the two-tab fingers-proof** (still owed): seal → husks → preview → pool dials full
 track → suggest-while-offline → refresh both tabs, dots re-green ≤15s. MANUAL today; the durable
  version is a distributed Book across two runners (`Cluster_spec §5`). Cross manually FIRST, then
   Book it — don't block the first "real" on building distributed-Story.

**Bonus wiring:** real `verify_trust` on the handshake IS the actual content of `Peeroleum_spec §5`'s
 "Tyrant.g seam" — so this fills that seam for real and makes the mock [[tyrant-g-superseded-by-swarm]]
  doubly obsolete. Related: [[p2p-two-stacks-proto-vs-g]] [[live-share-wired]] [[radiobuddies-shebang-unnamed]]
   [[friendship-durable-pier-stash]].
