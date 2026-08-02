---
name: invite-ledger-stash
description: "The %Idzeug invite ledger survives reload via H.stashed.Swarm_izzes (mint-then-reload had the door denying its OWN invite as 'unknown'); rebuffs now loud + surfaced"
metadata: 
  node_type: memory
  type: project
  originSessionId: 334456e9-f1e5-4e61-a0c4-7b0aaa37eec7
---

2026-07-18 (uncommitted): the two-tab BigSoundland seal failed because `Swarm_hello`'s nonce
 record (`%Idzeug` under the %Peering) was runtime-only — a reload between mint and scan made
  the inviter deny its OWN invite (`unknown`). Fixed in Swarm.g: `Swarm_iz_stash` (mint + spend
   write a durable twin under `H.stashed.Swarm_izzes[prepub][nonce]`, LIVE SELF ONLY — Book
    idents never pollute the tab stash) + `Swarm_iz_rehydrate` at station standup (handlers arm
     only at standup, so records exist before any hello). Every deny now logs `🚪 rebuff %<why>`
      on both ends and InvitePanel surfaces rebuffs (mint face) + names `rejected_<why>` (join
       face).

**Why:** durable decision-facts must live in storage, not run-memory — the same law as the
 %Grant ([[sounditron-wild-book]] observes grants as-is) and the %UnGrant tombstone.

**How to apply:** the "NO handler for frame type" warn on a pier_* frame is usually the
 DUPLICATE delivery on the second relay socket (addr=runner beside addr=prepub) — the real door
  answered on the other one; read the %rebuff on the identity for the actual why. Live-gated:
   SwarmStaple 8/8 + SwarmWire 5/5 + SwarmGot 9/9 + Sounditron 7/7. SEAL PROVEN two-tab
    2026-07-18. STORM LAW: a UI $effect reading live C can catch mid-Atime flicker (list 1→0→1)
     — keep MONOTONIC high-waters, never reset on shrink (the ive_got storm); and prefer
      panel-side guards over protocol-side (a same-census gossip guard changed Book semantics —
       reverted).
