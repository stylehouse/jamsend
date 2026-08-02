---
name: heist-seal-one-way
description: "Heist-pull stall root = a ONE-WAY seal (one tab has a %Pier, the other has NONE), caused by a lost pier_accept with no self-heal; FIXED by an issuer-side re-accept on redial (Swarm_reaccept_incomplete)"
metadata: 
  node_type: memory
  type: project
  originSessionId: 2f2e32df-77de-4509-9ea4-3454f9ecd5a7
---

Diagnosed + FIXED 2026-07-28 (two live tabs, Righto pub 56fbce / Lefto pub 77d26228). The **Heist
 stalls / both tabs play their own music** because the **friendship seal came out one-directional** —
  NOT any pull bug. The whole pull machinery works end-to-end over the relay.

**The seal is a 3-frame handshake; each side mints ITS OWN `%Pier` at the frame it RECEIVES:**
- `pier_hello` (redeemer→issuer): nobody has a Pier yet.
- `pier_accept` (issuer→redeemer): **issuer mints its Pier here** (one grant so far). `Swarm_hello`.
- `pier_confirm` (redeemer→issuer): **redeemer mints its Pier here** (both grants); then `Swarm_confirmed`
   adds the issuer's reciprocal grant.

The **issuer** (the tab that made the `?Iz=` invite — Righto here) seals FIRST and always ends up with a
 Pier. The **redeemer** (scanned the link — Lefto) only mints its Pier when `pier_accept` lands. Observed
  state = Righto HAS `%Pier,pub:77d262`, Lefto has **NONE** ⇒ **the single `pier_accept` frame was
   lost/rejected** (likely the post-reload seq-collision mute, see [[reconnect-epoch-seq-collision]]). The
    redeemer minted nothing; the issuer kept its one-sided Pier. (NOT a `pier_confirm` drop — that would
     leave BOTH sides with a Pier, the issuer's just missing one grant.) Correcting the earlier note: the
      culprit frame is **pier_accept**, and the redeemer's Pier is **absent**, not merely grant-short.

**No self-heal existed:** every redial path (`Swarm_station_routes`, `Swarm_hi_all`, `Swarm_pulse_all`,
 `Swarm_heard_hi`) iterates EXISTING `%Pier`s, so the side with none is invisible to all healing; redeem
  is a one-time user act that stashes no "awaiting-seal" state.

**FIX (built, compiled, needs live reload to verify):** `Swarm_reaccept_incomplete(w, ident)` in
 `Ghost/S/Swarm.g`, called from `Swarm_station_routes` (the redial seam — runs at standup + every socket
  reopen). For each of MY `%Pier`s that lacks the friend's **reciprocal grant** (a `%Grant` whose `by` ==
   the friend's full pub, read off the child `%Peering.sc.pub`), re-send `pier_accept` **reusing my
    already-signed grant atom** (`grant_of_C` — never re-mint/re-sign). `Swarm_accept` rebuilds the
     redeemer's Pier from scratch and re-confirms; the reciprocal grant lands, predicate flips, re-send
      stops. Cannot false-positive: a redeemer's Pier is born with BOTH grants, so only an issuer half-seal
       matches. Signature-safe: `page` is unsigned + bind-checked at the far end; the grant atom is reused
        (redeemer re-runs `verify_grant`). So **reloading BOTH tabs should heal the seal on redial.**

Also this session: **Radio made friend-exclusive** — see [[radio-friend-exclusive]] (the co-equal own+friend
 round-robin was why both tabs played their own). And a new **read-only `world` op** on `runner_ask.mjs`
  snaps the live resident tab (Piers + grant counts + depth-6 world snap) so the seal state is diagnosable
   without a test run — `node scripts/runner_ask.mjs world --runner=<prefix>`. See [[verify-via-live-runner]],
    [[cluster-trust]], [[repli-protocol]].
