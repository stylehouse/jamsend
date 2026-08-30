# Ferry_rebuild_todo — the Pier | Iz | Link rebuild (5-fork Opus panel, 2026-08-31)

Owner: "we must refactor. I don't know what's going on with the code at all anymore. use req."
Five independent Opus designs were run on "rebuild Pier|Iz|Link + why does the origin always reject it now?"
They CONVERGED unanimously. This doc is the synthesis + the staged plan. Companion: `Ferry_todo.md` §0 (the post-mortem).

## 0. The one load-bearing insight (5/5 agree)

**A device-link is a CATEGORY ERROR as a friend-grant.** `MyCave` consent rides `%Grant`/`%NotGrant` on a
 `%Pier`, gated by the SHARED `Swarm_pier_live` (Swarm.g:3868) — whose tombstone match is `by`/`for` with
  **no clock**. That's correct for *unfriending* (a revoke is forever, replay-proof). It's catastrophic for a
   *device-link*, which the human re-does on purpose: a reused incognito body-key (same `by`/`for`) carries a
    stale `%NotGrant:MyCave` — minted ONLY by `Swarm_pier_forget` (the human's prune button, task #32) — that
     buries every fresh `Grant:MyCave` forever. The full seal handshake completes (`pier_hello → accept →
      confirm`) yet `cave_pier=no` the next tick. The comments (Swarm.g:4727 &c.) promise "a fresh mint
       outranks the tombstone" — **that outranking was designed, tried on 2026-08-31, and REVERTED** because a
        GLOBAL time-compare broke SwarmStaple beat 7 (friend grant-times vs Book-pinned revoke-times aren't
         comparable). The fix keeps getting reverted because it's the SHARED verb.

**Therefore: give the device-link its OWN liveness rule; never touch `Swarm_pier_live`.** Both atoms already
 carry a signed `time` (Grant.ts:39/:45), so outranking is expressible today — it was just never put anywhere
  safe.

## 1. The core model (the corrected wall)

- **%Pier** — durable friend-memory, keyed by prepub. Bears `%Grant`/`%NotGrant` (Music trust). **Untouched.**
- **Friend-grant** = standing capability, revoke-is-forever. Correct. `Swarm_pier_live` stays byte-identical.
- **Device-link (MyCave)** = a per-ceremony consent = "this body is me". NOT a friendship (twins-not-friends).
   Its liveness = **freshest deliberate consent wins**, read by a SEPARATE predicate. Its epoch is the
    **invite serial** (already minted fresh + singular-adopt + twin-backed) — monotonic, Book-pinnable,
     replay-proof (a fresh serial needs the soul's key), sidestepping the wall-clock incomparability that
      killed the global fix.
- **The ceremony** = one `%Ferry` particle, currently a "6th mirror" (Ferry_todo §0) smeared across ~12
   `top.c.ferry_*` flags + 3 stashed twins. Becomes the req-stack's SNAPSHOT (§3).

## 2. The outranking fix — a monotonic consent-epoch, NOT a global clock

Rejected: (a) time-compare in `Swarm_pier_live` (the reverted graveyard fix — breaks friend-trust). (b)
 runtime clear-the-tombstone at redeem (the RELOAD DURABILITY TRAP: the tombstone rides the durable stash,
  which "NEVER drops a NotGrant", so a runtime delete is re-buried on standup rehydrate).

Chosen: a **new device-link predicate** (`Swarm_cave_live`) that reads freshest-consent-wins, so nothing is
 cleared — the fresh higher-epoch consent and the old tombstone both persist durably and the COMPARISON
  resolves them every time (reload-stable). Security: a replayed OLD seal carries an OLD epoch → stays buried;
   only a genuinely fresh human-minted link raises the epoch (needs the soul's key). Stage 0 backs it with the
    `time` field already on the atoms; Stage 2 upgrades the backing to the signed invite-serial epoch.

## 3. Where the wall goes — the ceremony AS a reqy(w) stack ("use req")

One `%req:Ferry` (eternal) per ceremony, resolved on **`w`** (not top_House — so a Book's ceremony writes the
 Book's own world and `Ferry,phase:*` lands in the snap, assertable). Each phase is a req level whose
  `finished`/`ok` IS the phase: `mint → await/seal → confirm → send → held → got → done`, with terminals
   `declined|cancelled|ended|spent`. Wins the req machine gives for free:
- **ttlilt** drives the two waits — the seal-wait and the steady "I want linkage" ask. The ttlilt interval IS
   the throttle (kills `ferry_want_at` + the 30s `ferry_refused` map).
- **`!ferrying`** guard → the req's native single-flight.
- **teardown = one line**: `host.finish(req:Ferry)` yoinks the stack + drops its ttlilts (kills the 7
   divergent teardown sites).
- **reload** = req-persistence: `finished` snaps (sc); only the secret can't ride sc → `req.c.secret` + ONE
   `stashed.ferry` twin (down from 3). Standup re-enters at the deepest unfinished req.
- **two ends interlock, not mirror**: soul + cave run their OWN stacks; the wire frames (UNCHANGED, Ferry_todo
   §4) are the inter-stack signals — a hear-handler `reqyoncile`s the matching req instead of poking a flag;
    the serial is the correlation key.

DIES: 12 `top.c.ferry_*` flags, 2 of 3 twins, the 4 surface patches (bump/poke/pop_glass/link_open),
 `Swarm_ferry_poke`, the `Swarm_pier_live(_,'MyCave')` callers. The `%Ferry` particle becomes write-only
  downstream (readers derive, nobody pushes).

## 3b. CRITIQUE VERDICT (2 Opus adversarial reviewers, 2026-08-31) — read before building §3

The 5-fork panel was reviewed by two adversarial critics. Both are worth heeding:

**Critic A (correctness/security) killed the first Stage 0.** A time-compare `Swarm_cave_live` CANNOT work:
 `Swarm_seal:2353` AND `Swarm_pier_stash:2416` both dedup grants on `to|by|for` with NO time, so a fresh
  redeem's newer-timed grant is DISCARDED and the stale-timed grant it kept still loses to the tombstone —
   the fix evaporates on the first relink AND on reload. Also: the ferry_want `wrevoked` gate (Swarm.g:~1083)
    reads `%NotGrant:MyCave` directly (clock-blind), a split-brain the delegation didn't fix. And the `>=`
     tie-break buries a same-second relink. → **Stage 0 REVISED (below): retire the tombstone at redeem, don't
      out-time it.** Also flagged: ~5 stale comments (Swarm.g:4746/4857/5047/5126/5277) claim decline mints a
       MyCave `%NotGrant` — the code mints NONE (the singular-adopt law); the only tombstone source really is
        `Swarm_pier_forget`. Fix those comments in Stage 1.

**Critic B (soundness) found the req-stack §3 largely UNBUILDABLE as written.** Against the real machine:
 (a) **ttlilt is NOT a scheduler** — it's a snap-quiescence advisory ("does NOT re-fire at until_ts; DO NOT
  re-arm in-flight", Hovercraft:392/394), so it CANNOT drive the steady "I want linkage" ask; that stays a
   real wire heartbeat. (b) `eternal` (never-finish) contradicts `finish()`-as-teardown. (c) pass-local `ok`
    snaps → run-volatile diges (the known fixture-flap trap). (d) it is UNVERIFIED that the live tab's `w:Swarm`
     is pumped by a per-tick `.do()` at all — if not, a req-stack never advances live. And **resolving on `w`
      was already rejected by the codebase** (Ferry_todo §6-A): the ceremony is tab-singleton, wire-bound
       (`Swarm_deliver` needs the live identity), and humdinger-gated — all irreducibly `top`-global; moving it
        to `w` breaks the live tab and churns every Swarm-world Book's fixtures (not "once"). Blast radius is
         ~14 flags / 286 `ferry_` refs in Swarm.g / Books that poke the twins as fixtures — bigger than stated.
  → **§3 REVISED: drop the req-stack. Finish the %Ferry PARTICLE inversion ON `top`** (the Stage-1-landed
     authority): retire the flags reader-by-reader so `Swarm_ferry_phase`'s `%Ferry` is the only writer and
      `Swarm_link_active/fresh` derive off `Ferry%phase`; give Books snap-visibility via a runner accessor
       (`runner_ask snap` already round-trips live `%Ferry`), NOT by relocating the ceremony onto the Book
        world. This delivers the "one truth" win without the req machine's four falsehoods. If "use req" is
         still wanted, PROVE it first with a shadow-req slice (one write-only req on the tab world, one new
          Book, 3 deterministic runner runs) before the 286-ref migration. Both critics agree "device-link ≠
           friendship" (Stages 0-2) is EARNED; "use req" (§3) was prompt-anchored and mostly doesn't fit.

## 4. Staged plan (revised after the critique)

- **Stage 0 — LANDED (corrected) 2026-08-31 (the unblock):** `Swarm_cave_forgive(ident, pier, prepub)` —
   at the proven-fresh MyCave redeem seam (Swarm_hello, after Swarm_seal), DROP the `%NotGrant:MyCave` from the
    live pier AND splice it from the durable stash `e.nots`, then settle. `Swarm_pier_live` is 100% UNTOUCHED
     (critics' preference). Sidesteps the grant-dedup entirely (no time-compare) and fixes the wrevoked
      split-brain for free (no tombstone left). MyCave-only → friend trust inert. GATE (proven): SwarmStaple
       8/8, InvFerry 6/6, SwarmSpread 5/5, InvWalk 8/8 GREEN (inertness). ⚠ EFFICACY has NO Book coverage
        (no Book does forget→relink) — **needs the owner's live test**: prune a MyCave pier, re-link the same
         incognito body-key, watch the log say `🦑 ferry: a fresh device-link redeem forgave N stale MyCave
          "no"(s)` and the link seal. Composes: Stage 2's epoch makes supersession structural; forgive is the
           same "fresh consent wins" law in pencil.
- **Stage 1 — separate the carrier:** `Swarm_pier_forget`'s MyCave leg stops minting a friend `%NotGrant`
   (it forgets the *bond*, not the friendship); cancel/decline never tombstone (already true — the
    singular-adopt law). Gate: SwarmStaple/SwarmSpread inert; new InvFerry beat "forget → relink seals fresh".
- **Stage 2 — the epoch:** signed invite-serial `epoch` on the device-link atoms (`opt` key, zero new crypto);
   `Swarm_cave_live` backing swaps `time` → `epoch` (replay-proof, Book-pinnable). Optionally promote MyCave to
    its own `%Adopt`/`%CaveBond` kind off the friend-Pier. Gate: security fixture — revoke → replayed-old-seal
     STAYS buried, fresh-serial redeem OUTRANKS (design 2's "single most important gate").
- **Stage 3 — finish the %Ferry PARTICLE inversion ON `top` (NOT a req-stack — see Critic B):** retire the
   ~14 `top.c.ferry_*` flags reader-by-reader so `Swarm_ferry_phase`'s `%Ferry` particle is the ONLY writer;
    `Swarm_link_active`/`Swarm_link_fresh`/LinkDevice/BootGate/Sounditron-commission all derive off
     `Ferry%phase` (change-gated, to avoid re-entering the focus-storm loop the idempotent phase-verb guard
      already fights). Collapse the 3 twins → 1 `stashed.ferry` (secret only). Books get snap-visibility via a
       runner accessor over the wire (`runner_ask snap` already round-trips live `%Ferry`), so the ceremony
        STAYS on `top` and fixtures stay inert. Gate: Swarm* + Inv* green; no `w`-relocation churn.
      OPTIONAL "use req" (only if the owner still wants it): first prove the shadow-req slice (§3b) — one
       write-only req on the tab world + one new Book + 3 deterministic runner runs — before committing to
        the full migration.
- **Stage 4 — fail-closed consent (Ferry_todo §0 ⚠):** `req:FerrySend` gates on `req:FerryConfirm.finished`,
   never on the ABSENCE of humdinger (closes the boot-window exfiltration hole). `humdinger` = screen+disk
    only; `consenter` (Book-settable — already landed by the InvWalk agent) drives the park/confirm.
- **Stage 5 — the payoff:** the one-particle-one-phase-walk shape becomes the template for `Grant:Music`
   (Ferry_todo §0 NEXT ARC), once the ferry proves it.

## 5. Risk discipline (unanimous)

`Swarm_pier_live` + `Swarm_seal` are SHARED with the friend/Music trust ledger. The whole safety rests on
 NEVER changing the friend path — add a parallel device-link path. **SwarmStaple 8/8 (esp. beat 7) byte-
  identical = the proof friend-trust is inert** (it's the exact Book that reverted the global fix). InvFerry/
   InvSeal/InvWalk = the ceremony walk. Fixtures re-record ONCE, deliberately, only at Stage 3 when the phase
    snaps on `w`. The two-end wire mirror is only truly proven LIVE (a single-node Book puppets both stacks
     and can miss a cross-wire race — same reason facet C is not landed blind): Books prove *inert*, the live
      runner proves *works*.

Key files: `Ghost/S/Swarm.g` (Swarm_pier_live:3868, Swarm_cave_live:new, Swarm_revoke:3826,
 Swarm_pier_forget:3845, Swarm_seal:2335, Swarm_hello redeem+mint:2069, ferry_want hear:1027, on_seal:4704,
  Swarm_ferry_link:4666, Swarm_ferry_phase:4964); `src/lib/O/Funk/Grant.ts` (time on both atoms:39/45; opt
   keys ride the signed domain — epoch fits with zero new crypto); `src/lib/O/Hovercraft.svelte` (the req
    machine: do/finished/ok, ttlilt, reqyoncile, eternal/permanent); `src/lib/O/ui/LinkDevice.svelte` +
     `Ghost/Story/Sounditron.g` (UI/commission — derive off the req); Books
      `wormhole/Story/{InvFerry,InvSeal,InvWalk,SwarmSpread,SwarmFerry,SwarmStaple}/`.
