---
name: p2p-two-stacks-proto-vs-g
description: "TWO p2p stacks. PROTOTYPE (reference, good fundamentals) = src/lib/p2p/Peerily.svelte.ts + ghost/*.svelte (Trust/Tyranny) — signs every frame, rebuilds trust per-connect, signed trust tokens. PRODUCTION (the REAL comms, audit target) = the .g rewrite: Ghost/S/Swarm.g + Ghost/N/Peeroleum.g + Ghost/N/Tribunal.g. The .g suite is NOT a simulation — that was my error, twice-corrected by the human."
metadata:
  node_type: memory
  type: project
  originSessionId: 334456e9-f1e5-4e61-a0c4-7b0aaa37eec7
---

**There are TWO p2p stacks. Get which-is-which right (I got it wrong twice; the human corrected both).**

- **PROTOTYPE / REFERENCE = `src/lib/p2p/Peerily.svelte.ts`** (+ the `ghost/*.svelte` machine it feeds:
   `ghost/Trust.svelte`, `ghost/Tyranny.svelte`). The human: *"src/lib/p2p/ is all the previous
    generation, a prototype, which does a lot correctly."* It is the REFERENCE for what good p2p crypto
     looks like — still imported widely for identity primitives (`Idento` = `Id`/`Ud`). Its verified
      properties (read the code, they're real): **per-frame signing** — `emit` signs every frame's json,
       `crypto.sign = enhex(await Id.sign(json))` (Peerily:672), buffers too (676); **per-frame verify** —
        `process_single_unemit` throws on a bad sig before parse (745-746, 766-767); **per-channel trust
         rebuilt on EVERY (re)connect** — `reset_protocol_state()` wipes said/heard_trust+trust+trusted on
          both `con.on('close')` (496, "any time the connection might have been mitm attacked") and
           `con.on('open')`→`init_completo` (520); **signed trust tokens** — `verify_trust` (1011) checks
            the granter's sig over `{to,time,pub:receiver}`; feature messages gated on a held grant
             (804-806); an untrusted-msg hold window ~9.11s (779-783).

- **PRODUCTION / AUDIT TARGET = the `.g` comms rewrite** — `Ghost/S/Swarm.g` (identity/contacts/invite,
   spec: `Swarm_spec.md`), `Ghost/N/Peeroleum.g` (the protocol/transport frames), `Ghost/N/Tribunal.g`.
    The human: *"the .g suite of comms is supposed to be real."* **It is NOT a simulation.** The invite
     TRILOGY is BUILT + Book-green here: single-use signed Idzeug (`Swarm_hello` spends its nonce,
      `deny('spent')` refuses replay), blotter serial sheets ([[swarm-blotter-built]]), and the
       re-assignable chain / `%ChainRoot` lineage ([[reinvite-chain-built]]). The prototype path
        (`ghost/Tyranny.svelte`) ALSO has single-use — `claim_Idzeug_number` + the literal
         `"prize already claimed"` (Tyranny:722, 775) — so "add serial claiming" is a MYTH; it's built
          in both layers.

**The error to never repeat (I made it twice):** first I audited the `.g` invite logic and filed bogus
 "voucher forgery" findings; then I over-corrected and branded the whole `.g` suite a "Story-SIMULATION,
  NOT production crypto" — ALSO wrong. The `.g` rewrite IS the production comms. Before asserting which
   stack is live, ask + check the import graph + the specs; don't grep-and-declare. The real audit job:
    take Peerily's per-frame-sign / per-connect-trust-rebuild / signed-token properties as a checklist and
     verify each holds on the `.g` code (esp. the open question: does the Peeroleum WIRE sign every frame,
      or ride a "pre-Ud" authenticated link — Swarm_spec §6.3 line ~279). Handover: `Trust_audit_handover.md`.
       Related: [[cluster-trust]], [[peeroleum-bootstrap]], [[swarm-family-built]], [[swarm-seal-prepub-binding-hole]].
