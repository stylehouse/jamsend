> **⌛ ARCHIVED — retired from `spec/` to `spec/history/` on 2026-07-07.** Historical; may be stale.
> Fully sublated into `Cluster_spec.md`: disease principle → §2 head; Organ 1 → §3.2b; Organ 2 → §1;
> Organ 3 (authoritative absence) → §2.0a; Organ 4 → §3.2a; Organ 5 → §3.8. Original plan (with the
> `file:line` specimen catalogues) follows.

# Robustness_plan.md — retired into Cluster_spec.md (bar Organ 3)

> **This doc is retired.** It was the plan of record for the 2026-07-04 hardening pass — one disease
> (*state asserted instead of derived; boundaries trusted instead of confirmed*) found in five "organs"
> after the remote-Wormhole grant saga. The cluster-shaped organs folded into **`Cluster_spec.md`**, which
> is now the single home. Only **Organ 3** (authoritative absence) is app-wide rather than cluster-only, so
> it stays here as a stub. The full `file:line` specimen catalogues for every organ live in this file's
> **git history** (pre-2026-07-06).

## Where the organs went

- **The disease** (assert-vs-derive, trust-vs-confirm) → graduated to a stated **principle** at the head of
  `Cluster_spec.md` §2.
- **Organ 1 — latched flags never reconciled** (`channel_up`/`transport_up`, the "relay down" wedge) →
  `Cluster_spec.md` §3.2b (latch-reconcile rule + the still-open backlog). ✅ `channel_up`/`transport_up`
  now clear-and-re-standup when `Socket_real` vanished.
- **Organ 2 — silent success over dropped work** (the Peeroleum ack) → `Cluster_spec.md` §1 (delivery-honesty
  contract). ⚠️ unregistered-frame WARN landed; mark-faulty-don't-ack deferred (retx-wedge risk).
- **Organ 4 — identity model 9→2** → `Cluster_spec.md` §3.2a. ✅ **DONE + verified live 2026-07-05/06**
  (`self===clustation_self`; MusuReco `0/11`→`11/11`; all editor→runner frames addressed — "roles divide,
  addresses deliver").
- **Organ 5 — lying errors / partial interfaces** → `Cluster_spec.md` §3.8 (the full 7-method nav contract as
  a hard invariant). ✅ nav-precedence + `bin_write`-over-proxy landed; full-contract parity across all four navs.

---

## Organ 3 — single source of truth: authoritative absence (app-wide, not cluster-only)

The one organ that is **not** cluster-specific — it governs every read that can overwrite durable data — so it
 stays here rather than folding into `Cluster_spec.md`. (If this file is ever deleted, lift this principle into
  `CLAUDE.md`; it is load-bearing app-wide.)

**Principle.** A read is **three-valued**: `present(content) | absent | unavailable(reason)` — never conflate
 "genuinely gone" with "couldn't fetch". **A transient or empty read must never overwrite durable data.**
  Enforce it at the ONE choke point (`LiesStore` `land_good`), which re-confirms once before trusting a
   `not_found`, so authoritative-absence is inherited by every consumer instead of scattered per-caller
    `notfound_once` band-aids. Gate any empty-read auto-save (`Lies.svelte:829`, the original grant-registry
     wipe site) on *confirmed* absence only.

**Landed 2026-07-05.** `land_good` re-asks ONCE before landing a `not_found` (deduped per-req via
 `req.c.nf_counted` across the Phase-2 + read_good sites); a transient not_found for a registry Waft never
  lands as absence; `Auto.svelte`'s Library got the same re-confirm on its `rw` queue; `text/Doc` is EXEMPT (a
   not_found doc is a new blank file, and a one-shot cold-subscribe would hang). This was the grant-registry-wipe
    thread that started the whole robustness saga.

**Residue / still-open.** The three-valued state at `land_good` is a *re-ask*, not yet a **contract flag on the
 reply** — so `RemoteWormholeNav` still forwards a `not_found` verbatim (only local FSA re-lists before
  answering). Positive templates already in the tree: `Story.svelte`'s re-confirm-before-accepting-absence, and
   `LiesKeep`'s one authoritative snapped home + a coalesced mirror that can't feed a write loop. The exhaustive
    specimen list is in this file's git history.
