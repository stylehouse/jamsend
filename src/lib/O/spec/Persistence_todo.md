# Persistence_todo — the account is a sprawl of mirrors; make it ONE boundary

Written 2026-08-21 out of the eed831f1 debug (a daemon that served music but could never make a
 friend). The bug was never one broken write — it was the **seams between independent mirrors**.
  This doc is the analysis + a proposal for a single Account persistence boundary. It EXTENDS, does
   not replace, `Identity_persist_todo.md` (resume/homing rulings) and `Daemon_todo.md` (the daemon
    seam); every ruling of theirs is honoured here and called out where it constrains the design.

## 0. Get on with next

**Phase 1 LANDED 2026-08-21 (working tree; the human commits).** And it landed SIMPLER than first
 designed here — the double-check found the codebase already held the right primitive:
  `Swarm_restash_all`, an idempotent, additive, live-self-guarded whole-ledger converge. So
   `Swarm_account_settle(ident, why)` is **convergent, not fact-typed**: it takes no facts, it
    re-mirrors the whole ledger + nudges the disk mirror — a forgotten call self-heals at the next
     one, and a new fact KIND cannot be missed because settle never enumerates kinds. Wired at three
      seams (Ghost/S/Swarm.g, compiled to gen/S/Swarm.go via LocalGen): the `hear` dispatcher after
       every ledger-mutating frame kind, and `Swarm_revoke` (whose tombstone previously reached the
        account snap only by coincidental version bump). Verified live-runner green, repeatedly:
         Swarmation ×2, SwarmInvite 5/5, SwarmDisk 7/7, SwarmChain 5/5 — fixtures unmoved (the
          live-self guard makes settle a no-op under Book puppets, by design).
 **Phase 1 PROVEN on the real seam 2026-08-21:** the rebuilt daemon minted eed831f1's invite from
  its own ledger via `/invite` and the seal held across the wire — the original wound is closed.

**Phase 2 LANDED 2026-08-21 (working tree).** Not the doc's original "delete the version-bump
 trigger" — the double-check found the trigger machinery worth keeping (the canonical-address
  write-lock, the owed-write loudness, the single-flight nudge are all load-bearing) and the rot
   confined to the MARK being a version-bump heuristic. Three edits make the snap a projection of
    ledger TRUTH instead of bump-luck:
 - **Auto.svelte `Clustation_mirror_account`**: the mark now folds in a **ledger print** — a djb2
    hash over `stashed.Swarm_izzes/Swarm_piers/Swarm_roots` content — so the admitted hole ("a
     mutation that bumps NEITHER would not re-mirror until the next boot") is closed, and a settle
      nudge can never be swallowed by a stale mark.
 - **Swarm.g `Swarm_account_settle`**: stamps `account_settle_owed` (runtime `.c`) on the top house.
 - **daemon main.ts `persist_account`**: the owed flag lets ONE fingerprint through the 20s throttle
    off-cycle — a settled seal reaches the daemon's disk in ~one tick instead of "within 20s unless
     we die first". The content fingerprint still gates the actual write (no key-spraying).
 Verified: Swarmation/SwarmInvite/SwarmDisk/SwarmChain all ok_pct 1 live; adversarial subagent
  review found no defects. **Needs a jamserve rebuild to reach the daemon.**
 **Next:** decide Phase 3 (§5.3 durability ack + atomic check-off) and Phase 4 (§5.4 write-lease).

**2026-08-21 also: a WRITE-CHURN AUDIT swept every durable-write site** (subagent, full table in the
 session; verdicts CHURNS/GATED/RARE). Four churn sites found and all four fixed the same day:
 - `Heist_keep_memo_flush` — re-appended a recipe whose only change was `ts` (→ `Heist_keep_memo_same`).
 - `Census.svelte` — appended a part per minute on sub-1% estimator drift (→ materiality gate, see
    `Wander_todo` §0).
 - `Heist_keep_persist` — a whole-shelf `Berth_save` per track landing with no change test (→ a
    full-content print on the top house; JSON of every seed+pick sc, not a field whitelist).
 - `Swarm_roster_save` — rewrote `identities/toc.snap` byte-identical on every account-mirror pass
    (→ compares the re-encode against the bytes `roster_open` just read; can never suppress a real
     change).
 Everything else came back GATED (real content gates: the stashed `$effect`'s `_last_written`, the
  mirror mark, the daemon fingerprint, Thangs `_last_json`, stemdex diges) or RARE (gesture/event-
   driven). The through-line for future writers: **every durable write wants a content gate at the
    write seam itself** — an upstream trigger heuristic is not one.
 The immediate live wound (eed can't befriend the daemon) is NOT fixed by this doc — it's the
  `/invite` route + one-body-per-identity discipline in `Daemon_todo` §0. This doc is the durable
   fix behind that incident.

## 1. The map — one identity's durable state lives in FOUR homes

| Home | Holds | Written when | Where |
| --- | --- | --- | --- |
| **Dexie/`DAEMON_STATE` stash** (`House.stashed`) | `Swarm_izzes` (invite ledger: issuer `next`/`claimed`), `Swarm_piers` (piers+grants), `Swarm_roots` (chain roots), `cluster_idento` (keys) | **any deep change** — a `$effect` deep-reads `stashed` and debounced-`put`s it (Housing.svelte.ts:442) | browser IndexedDB · daemon `DAEMON_STATE/House.json` (dexie-node.ts) |
| **`.jamsend/account/<prepub>/toc.snap`** | full export: keypair (in the clear) + Peering + Pier + Grant + **%Idzeug** | **version-bump heuristic** (`ident.version:peering.version:kin`) + 500ms debounce + 20s throttle (daemon) | the FSA-granted folder (browser) · `LIBRARY`/`.jamsend` (daemon) |
| **`.jamsend/identities/toc.snap`** | pub-only recognition roster | same mirror pass | same |
| **Keyfile** (daemon only) | the ed25519 pair | first boot if absent | `KEYFILE` (default outside the tree) |

The stash is **authoritative** and is rehydrated at station standup **before any handler arms**
 (`Swarm_iz_rehydrate`/`Swarm_piers_rehydrate`/`Swarm_chainroots_rehydrate`). The account snap is a
  **portable export** and the disk-seed fallback when Dexie is cleared (`Swarm_boot_seed`, gated
   disk→Dexie only-when-empty per `Identity_persist_todo` §2). **`%Idzeug` rides BOTH the stash and
    the snap** (Swarm_export walks it, Swarm.g:3281/3341) — one fact, two homes, two write triggers.

## 2. The failure taxonomy — every bug this session was a seam, not a store

- **A · write-trigger fragility.** The snap mirror fires only on a version bump; a spend/claim that
   bumps neither `%Identity` nor `%Peering` "reached disk only by luck" (Swarm.g:1065-1072). Plus a
    20s throttle window, and the once-per-boot latch that held one Pier while serving two across
     eight restarts (`main.ts:864`, fixed by content-fingerprint — but the *class* recurs anywhere
      a write hangs off "did the version move?").
- **B · two ledgers of one truth drift.** The seal ledger (`Swarm_piers`) and the spend ledger
   (`claimed`) are separate and separately triggered. Chain-holder moves and re-seals "find rather
    than create" and "never seal at all" (Swarm.g:1068-1071), so a friend can be **sealed without
     its serial ticked into `claimed`**. ⚠ CORRECTED 2026-08-21: the live daemon reading
      (`next:22224`, two friends, `claimed:[22222]`) is **NOT proof** — serial 22223 may simply be
       minted-and-never-redeemed (an outstanding invite, innocent), and a chain redeem marks
        `holder`, not `claimed`, BY DESIGN. The *class* stays real (the quoted comment admits it,
         and a lost check-off is re-redeemable — "un-spends an invite… a security fact") but the
          daemon reading is consistent with innocence; don't chase it as a live bug.
- **C · two-writer race.** Browser and daemon both mirror `.jamsend/account/<prepub>/` last-write-
   wins, and the Dexie stash is a full-object-replace ("the oldest two-writers bug", Identity_persist
    §7.4f). A stale body's mirror silently clobbers a fresher one (the 272-byte empty 7950 snap we
     watched get written over a populated one).
- **D · body divergence (the eed saga).** One prepub, N live bodies, each with its OWN stash
   (IndexedDB vs `DAEMON_STATE`) AND its own `.jamsend` mount (`/app` vs `/music`). Invites and piers
    minted in one body are invisible to the other. eed sealed with a browser body; the daemon rebuffed
     its `pier_hello` `hello_unknown` because the serial was in the browser's ledger, not the daemon's.
      **There is NO collision detection** — `Swarm_stolen`/`%Sibling` exist but have zero app callers;
       the canonical-address write-lock (§7.4f) is advisory only.
- **E · friendless restore.** Disk-seed grafts keypair-only into a detached vault; reload #2 loses
   piers/grants (Identity_persist §6.6, still open).

**The through-line:** durable truth is scattered across homes with independent triggers and no single
 transactional "this fact is now settled" seam. You cannot throttle-tune out of it — the shape is wrong.

## 3. Invariants we actually need

1. **Settled ⇒ on disk, observably.** A seal/claim/mint returns only once its fact is durable, and
    that durability is *visible* (an ack the UI/daemon can show). The human's exact ask.
2. **One truth per fact.** A claimed serial, a pier, a grant each has ONE authoritative home; every
    other representation (the portable snap) is a *projection* of it, never a parallel writer.
3. **Atomic co-facts.** A seal and its serial check-off move together or not at all (kills B).
4. **One writer per identity.** A body must hold the identity's write-lease to persist; a second
    body runs read-only or negotiates a handover (kills C and D). This is §7.4f made *enforced*.
5. **Provision/resume split preserved.** Browser provisions, daemon resumes (Identity_persist §4.1)
    — the boundary must not smuggle minting into the daemon except through its own explicit `/invite`.

## 4. Do we need a middle-layer? Yes — one Account boundary

The instinct is right. Introduce **`Account`** — a single module that owns ALL durable state for one
 identity as one consistent aggregate, and is the ONLY thing that reads or writes it. The rest of
  Swarm stops knowing about stashes, mirrors, version bumps, and nudges; it calls two verbs:

- **`Swarm_account_settle(ident, fact)`** — the ONE write seam. `fact` names the change
   (`{seal, pier}` · `{claim, serial}` · `{mint, serial}` · `{grant}` · `{revoke}`). settle applies
    it to the in-memory aggregate AND durably records it (append/idempotent-upsert of *that fact*,
     not a whole-tree "did the version move?" guess), AND ticks any co-fact in the same step (the
      seal+claim atomicity). It **awaits durability and returns a settled-ack**.
- **`Swarm_account_hydrate(ident)`** — the ONE read seam at standup: load the whole aggregate before
   any handler arms (it already does this via the three rehydrate calls; unify them).

What the boundary subsumes / demotes:
- `Swarm_iz_stash` + `Swarm_pier_stash` + `Swarm_chainroots` stashing → become settle's internals.
- `Clustation_mirror_account`/`mirror_nudge` version-bump heuristic → **deleted as a trigger**; the
   account snap becomes a **derived projection** regenerated from the aggregate on a debounced timer
    (one writer, one direction — kills B's drift and C's file race). It stays exactly as portable.
- "Reached disk only by luck" → impossible: every fact is durable *because it went through settle*.

**Why this is "simpler to instruct" (the human's phrase):** adding a new kind of durable fact today
 means remembering to mutate sc, stash the twin, bump the right parent's version, and nudge the
  mirror — four scattered obligations, and forgetting any one is a silent data-loss bug. After: you
   call `settle(ident, {yourfact})`. One obligation. The layer guarantees persistence, projection,
    and the ack.

## 5. Migration — incremental, non-breaking, ruling-safe

- **5.1 · Phase 1 (do first): funnel writes.** Introduce `Swarm_account_settle` as a thin facade over
   the EXISTING stash + mirror — no storage/format change. Replace the scattered `Swarm_iz_stash`/
    `Swarm_iz_mark`/`Swarm_pier_stash`/`mirror_nudge` call-sites with `settle`. Pure refactor; kills
     failure-class A (every fact now persists through one seam). Prove with the two-tab fingers-test
      + a daemon restart. **Ship this alone; measure.**
- **5.2 · Phase 2: snap becomes a projection.** Regenerate `.jamsend/account/<prepub>/toc.snap` from
   the aggregate on a debounced timer inside settle, and delete the version-bump mirror trigger. One
    writer, one direction (Identity_persist §2 already blesses this). Kills B (drift) and C (file race).
- **5.3 · Phase 3: the durability ack.** settle awaits the stash save and surfaces a "settled" state.
   The Door shows "invite settled ✓ / settling…"; the daemon logs "seal durable". Directly answers
    "an Invite should not be half-done and get lost." Also add the missing **atomic check-off**: any
     path that seals a pier ticks its serial into `claimed` inside the same settle (fixes the
      `claimed:[22222]` under-count and the double-spend it implies).
- **5.4 · Phase 4 (hardest, optional): the write-lease.** Enforce one-writer-per-identity — a body
   acquires the account lease (the daemon already has `lock_state()` for `DAEMON_STATE`; extend the
    concept to the identity, not just the process dir) before it may settle. A second body runs
     read-only or negotiates the §7.4 borrow (already designed, six pieces unwired — this is where they
      get wired). Kills C and D; makes `Swarm_stolen`/`%Sibling` finally load-bearing instead of dead.

## 6. Risks / do-NOT

- **Don't break §4.1** (browser provisions, daemon resumes). settle on the daemon persists only what
   the daemon legitimately produces (resumes, answers invites via `/invite`) — it must never become a
    provisioning back-door.
- **Spend-marks are security.** Any change to how `claimed` persists must preserve "a lost spend-mark
   un-spends an invite." Prefer append-only/idempotent over replace; never let a projection write back
    into the authoritative ledger.
- **The keypair rides the snap in the clear** — the three owner-local invariants (Swarm.g:3371) must
   still hold after the projection change; a projection that ever surfaced through a share walk leaks
    the key.
- **`node_modules` is two-libc** (CLAUDE.md) — none of this needs an `npm install`; keep it that way.
- **Commits are the human's job** — this is a `_todo`, not a `_spec`; the human preens before it earns
   `_spec`. Leave phases in the working tree; do not self-promote the design.

## 7. Cross-refs

- `Identity_persist_todo.md` — resume/homing, the §2 stream rule, §4.1 provision/resume split, §7.4
   borrow + canonical-address lock (Phase 4 wires these).
- `Daemon_todo.md` §0 — the live eed incident, the `/invite` mint route, one-body-per-identity, and
   the `persist_account` 20s/fingerprint seam this doc generalises.
