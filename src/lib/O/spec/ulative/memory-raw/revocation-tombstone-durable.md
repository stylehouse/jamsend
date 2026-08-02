---
name: revocation-tombstone-durable
description: a revocation/%UnGrant is a negative DECISION-fact whose absence is ambiguous (never-granted vs revoked) — a GC must NEVER idle-drop a tombstone; the dual of derive-don't-assert
metadata:
  node_type: memory
  type: project
  originSessionId: 7d992ead-6ef2-4f82-85d7-85669ab9454f
---

**Revocations are the ONE thing you assert-and-KEEP.** The [[robustness-plan]] "derive don't assert" rule is for POSITIVE state — a grant is re-derivable, so forgetting it is fail-safe (you re-ask). A revocation (`%UnGrant`/tombstone on a `HostedIdentity` in Waft:Cluster) is the DUAL: a negative *decision*-fact you CANNOT re-derive from live state — live state shows only "grant absent", which conflates "never granted" with "revoked". So a GC idle-dropping a tombstone silently re-opens a door you closed, **no attacker needed**. Same category error as the P0 wipe (authoritative-absence), pointed the other way: treating a decision-fact as a derivable-fact. Tri-state `present|absent|revoked` — never fold revoked into absent.

**The distinction that dissolves the "should we even chase this?" worry (owner, 2026-07-05, leaning abandon-the-chase):**
- **Self-forgetting** — your own GC drops a revocation → you re-grant yourself. A CORRECTNESS bug, no adversary in it, cheap to fix, worth it. This is NOT "the last bit of a security bug."
- **Adversary-hardening** — unforgeable / gossiped / replay-proof revocation across the flock. THE last-bit rabbit hole → DEFER: no adversary yet, owner already built-then-REVERSED the cluster-cert machinery once ("we don't need new cluster certs, obvious"), and the identity model is collapsing 9→2 ([[robustness-plan]] Organ 4 / [[clustation-identity-layer]]) so any hardening now rides tiers about to vanish.

**Cheapest correct move — ask before you guard:** does `HostedIdentity/*` even ACCUMULATE? If it's few + small, DON'T idle-drop identities at all — that deletes the bug class instead of adding a guard (the [[todo-docs-overstate]] instinct: the fix is narrower than the framing). Only if they genuinely pile up (every `?I=`/fork/runner mints one) does the GC need the one-liner: drop expired/positive freely, NEVER a tombstone. **Discussed 2026-07-05, not built.**
