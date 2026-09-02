# Ceremony_handover_todo.md

## ⓘ SUPERSEDED / UPDATED 2026-09-02 (night)

**The `foreign-want` blocker that cursed this whole handover is SOLVED, and its ROOT CAUSE was not what
 the body of this doc assumes.** It was never a foreign/stale relay holder of the `eed831f1` soul door —
  it was the tab's OWN TWO SOCKETS fighting for its soul name: a no-`want` Lies/role-channel hello seated
   the bare prepub unconditionally on the relay, so the station socket got suffixed OFF ITS OWN NAME by
    its sibling socket → door-yield → rehome → `foreign want` → `to:<soul>` dead-ended unprocessed in
     w:Lies. **FIXED + Book-green (SwarmBody 23/23, ok_pct:1, zero fixture churn):** seat-dodge in
      `LiesLies.svelte` (~413, role hello wants a throwaway `<prepub>_9<rand>` seat), in-family want-clamp
       + `on_hello` door-reclaim/soul-family guard in `Ghost/S/Swarm.g` (~1644). Proven first in
        `scripts/ceremony-addr-test.ts` §D (10/10) + relay-test. See memory `foreign-want-door-holder.md`.

**And the whole device-link MECHANISM this doc chases is being replaced (owner decision, 2026-09-02).**
 Device-link is now a **CREW of DISTINCT identities bound by a signed Charter cert — NOT one soul key
  copied across devices colliding on the relay.** Each device mints its OWN Identity; the inviter signs a
   Charter membership cert; friends are told the crew set and render any member as "you". The addressing
    collision this doc treats as the enemy is DELETED, not solved. The single clean statement of the new
     plan is `CrewLink_todo.md` — **read that, not the §1–§6 body below**, which is preserved as the
      forensic record of the disease (and §6's `%Reach` middleware, which still composes on top: the
       W1 primitive is COMPLETE + Book-gated, see memory `want-middleware-plan.md`).

**→ This doc is retirement-ready** (its blocker solved, its model superseded). Left in place for the human
  to retire; §6's Reach plan has already migrated to `Reach_todo.md` + `CrewLink_todo.md`.

---

**Handoff brief, 2026-09-02 evening. Context got cursed chasing a live device-link between two tabs that
 never completed. Read this before touching the ceremony again.** Sibling docs: `Division_todo.md` (the
  plan/destination), `Ceremony_layering_todo.md` (the architecture reckoning — read it, it predicted this).

## 0. WHAT TO GET ON WITH NEXT

**⚠ 2026-09-02 (night): items 1–4 below are LARGELY MOOT — see the ⓘ note at the top of this file.**
 Item 1 (the `foreign-want` mystery) is SOLVED (self-collision, not a foreign holder — fix landed +
  Book-green). Item 3 (the "nobody answered the door" error) survives as the `ferry_want`/`%Reach` W2
   port (see `CrewLink_todo.md` turn-key deliverables + `want-middleware-plan.md`). The cert-crew pivot
    (`CrewLink_todo.md`) retires the soul-door-collision framing that items 1/4 fight. Read that first.

**→ 2026-09-02 (night): the §5 think HAPPENED (three forked analyses, convergent) and became a PLAN — see
 §6. The missing middleware is named: the `%Want` — an addressed message as a standing snapped req that
  settles (landed | refused,why | dead,nobody-answered), generalising `%Reach`, on the Repli convergence
   contract. §6 supersedes items 3 and 4 below (both fall out of phase W2) and reframes item 1 (the
    foreign-want holder stops being fatal once the knock is multi-path + legible; a relay forensics tool
     stays worth having). Start at §6.**

1. **Solve the `foreign-want` mystery — this is THE blocker, and it is almost certainly NOT code.**
   The live symptom all session: the incognito knocks `pier_hello → eed831f1` and eed "never notices the
   ceremony." The tell is in eed's own boot log:
   `🪪☠ relay refused hello: foreign want` + `🪪 the door (eed831f1) is held by a sibling body — standing
   at my own name 5ade3510 instead`. So **the relay believes some OTHER party holds the `eed831f1` soul
   door**, and routes the knock there — into the void. The owner confirmed it is **NOT the daemon** (daemon
   isn't running / not this identity) and it is **NOT the reloaded browser tab** (that fell back to
   `5ade3510`). So who/what holds `eed831f1` on `wss://djamsend.duckdns.org:9999`? ~~Prime suspect: a
   stale relay binding~~ **CORRECTED (blindspot review, §6.4 W0): the relay heartbeats every 15s and
   reaps dead sockets in ~30s (relay.ts ~858) — the holder is ALIVE right now** (a forgotten daemon /
   service worker / tab on another machine). The `who` probe (W0) names it in one message. Until
   the door-holder is found/cleared, NO amount of tab-reload or code change fixes the live link — the knock
   never reaches running code. **This needs relay-side visibility the claude container does not have** (see
   §1). Start here next session.
   **DECISIVE (owner 2026-09-02): "no response from eed, with a FRESH `Invite:MyCave`."** A fresh invite
   rules out BOTH the stale-fc mismatch AND the derived-secret rebuild (§2) as the cause — the knock is not
   being rejected, it is not ARRIVING. This is purely a DELIVERY/ROUTING failure, upstream of all ceremony
   code. Which is the whole argument for §5.

2. **Concordance audit (the owner's explicit ask): the last week self-conflicts — reconcile it with the
   plan.** Candidates in §3.

3. **Add the missing "nobody answered the door" error (owner 2026-09-02: "there's no 'that LinkDevice Adopt
   doesn't work' error … perhaps Invite:MyCave").** The linkee's "listening for the soul" wait (`awaiting`
   phase, pumped by `Swarm_ferry_ask` every ~3s) has NO timeout and NO failure surface, so a knock that
   vanishes into a foreign/stale door-holder (§0.1) looks IDENTICAL to "working, please wait" — forever.
   This single gap is why §0.1 was invisible for a whole session. Fix: after N seconds of `awaiting` with no
   `ferry`/`pier_accept` back, fold the linkee to a legible "no one answered — the other device may be
   offline, or this link is stale; get a fresh link" (mirror the stale-link message already in
   `LinkDevice.svelte`). Make it impossible for the ceremony to sit silent — every dead-end names itself.
   This is the highest-leverage legibility fix: do it EARLY so the next live attempt SHOWS its own failure.

4. Only AFTER 1: prove the derive rebuild (§2) end-to-end live. It is Book-green but has NEVER been proven
   on two live tabs, because of §0.1.

## 1. THE BOMB — knowledge that detonates the next session if they don't have it

- **The live two-tab link has NEVER completed this session. Every green is BOOKS.** Do not read "all
  ceremony Books green" as "it works." The live path failed every attempt, upstream of code.
- **A soul is MULTI-BODY and the relay routes a soul-addressed knock to whichever body holds the bare
  door.** `eed831f1` (soul "Grav") has ~4 bodies. The browser tab stands at `5ade3510` (a Captain body)
  because a *foreign* party already holds `eed831f1`. A knock to `eed831f1` does NOT necessarily reach the
  body you are looking at / reloaded. This wasted most of the session ("reload eed" never touched the body
  answering the door).
- **This container is WALLED OFF from the live relay and the daemon.** eed talks over
  `djamsend.duckdns.org:9999` (remote); `172.17.0.1:9099` (daemon control) is dead. The `runner_ask console`
  tool (built this session, real & useful) only reaches LOCAL runner tabs on `172.17.0.1:9091` — it returns
  "ring empty" for eed forever. **So this agent cannot observe eed or the relay bindings at all.** Live
  ceremony debugging from here is blind; it depends on the human's console pastes. A tool that can reach the
  djamsend relay (or introspect its address table) would end the blindness — worth building before more live
  ceremony work.
- **The device-link ceremony is the un-rebuilt subsystem** (`Ceremony_layering_todo.md`): random+transient
  reload-fragile secret (now fixed, §2), and %Pier overloaded as transport + ceremony-state + relationship
  all at once. "Two tabs saying hello" routes through: relay address binding → door-holder election →
  reborn-knock seq handling → Swarm_hello verify → seal → ferry secret → on_seal consent park → confirm →
  ferry send → unseal. Any layer silently eats it. The owner's read ("soooo trivial, right?") is correct and
  is itself the argument for the CLEAN-1/CLEAN-2 rebuild in the reckoning doc.

## 2. WHAT LANDED THIS SESSION (in-tree, UNCOMMITTED — the human commits)

All Book-verified (InvFerry/InvWalk/InvSeal/SwarmSpread/SwarmBody/SwarmDoor/SwarmChain green, ok_pct:1),
 NONE proven live (see §1). Files: `Ghost/S/Swarm.g`+`gen`, `Ghost/N/Tribunal.g`+`gen`,
  `src/lib/O/ui/LinkDevice.svelte`, `src/lib/O/ui/Splash.svelte`, `src/lib/V/BigSoundland.svelte`.

- **Ferry secret DERIVED, not random** (`Swarm_ferry_derive_secret` = MAC of soul key over
  `ferry_fc:<serial>`): mint derives it; `Swarm_hello` link branch stamps `pier.c.ferry_serial` + `heard_at`
  and fires the seam fire-and-forget (NOT await — await reordered the send ahead of pier_accept → InvFerry
  4-6 churn); `on_seal`/`confirm` derive as fallback when no stash. **Point: a reloaded giver re-derives and
  can always ship; the reheal/sweep/twin machinery is now vestigial.** Reload-proof by construction — but
  UNPROVEN live because the knock never reached this code (§0.1).
- **Self-pulse flood fixed** (`Swarm_pulse_all` pier loop skips own body address / soul prepub) — the
  `no Pier … to=5ade3510 — DROPPED` ~1/s spam was eed pulsing its own self-husk %Pier.
- **Legible stale-link failure** (`Swarm_ferry_consume` null-soul → loud console; `LinkDevice.svelte` →
  "this link is stale, mint a fresh one"). NOTE: fires only at the UNSEAL stage — useless while the knock
  never reaches eed (§0.1). The pre-ship "listening for the soul" wait STILL has no timeout (owed).
- **Console noise cut** (`Tribunal.g` ambient set widened: ive_got/roster/repli_ready/run_phase/suggest
  suppressed; bare `(control)` sends silenced; pier-heal ×20 → 1 summary). Ceremony frames kept visible.
- **Boot spinner** (`Splash.svelte` + `BigSoundland.svelte`, off-snap, staged labels). ⚠ SUSPECT: the owner
  saw eed stuck on "sealing your links" — that phase reads `c.station_up`; VERIFY it reads the Swarm world's
  `station_up` and not a `top.c` that never flips, or the label sticks forever. Un-pixel-proven (runner_shot
  is Cyto-canvas only; only humdinger tab was the protected ceremony tab).

## 3. CONCORDANCE — where the week may self-conflict with the plan (audit these)

- **The multi-body soul-door model vs. a ceremony that must reach a specific body.** `Swarm.go:1655` "door
  held by a sibling — stand at my own name" + the relay's single-holder "foreign want" refusal means a
  soul-addressed knock is a coin-flip about which body (or ghost binding) answers. Is that the plan? A device
  link needs to reach the body actually running the ceremony. Reconcile with Division_todo's Pier/Peering law
  ("Pier = who we dial") and the land-of-prepub "body = own address" — maybe the knock should target a BODY
  address, not the soul door.
- **Founding self-husk %Pier** (plants a Pier at own body address for family_derive) — caused the self-pulse
  flood; is planting a self-pier concordant, or a smell?
- **Consent model drift.** The mint-stop "standing invite authorizes the ship" ruling I took (owner
  delegated) vs. the warmth-gated "give my soul" consent + the ferry_want refuse gating. Are these one
  coherent policy or three?
- **Half-migrated ferry state.** Derived secret made reheal/sweep/twin vestigial but they still run — dead
  code that can still fire the stale-sweep and retire a live ceremony. Finish the migration or it bites.

## 4. TOOLS BUILT THIS SESSION (committed, reusable)

- `node scripts/runner_ask.mjs console <tab> --tail/--grep/--follow` — pull a LOCAL tab's console over the
  relay (ends copy-paste for local runner tabs; blind to eed, §1). See memory `live-console-pull`.
- Runner `.go` hot-swap (`Creduler_reswap` in LiesLies.svelte) — recompiled spine .go goes live on a runner
  in ~2s, no reload, safe-seam guarded. See memory `reload-runner-after-recompile` (updated).
- `Ceremony_layering_todo.md` — the architecture reckoning (CLEAN-1 hoist pier_hello dispatch by type;
  CLEAN-2 sever ceremony from %Pier liveness; the silent-bail invariant).

## 5. THE MAJOR THINK (seed) — "built like shit; some middleware is missing" (owner 2026-09-02)

The fresh-invite finding (§0.1) reframes the whole week: the ceremony crypto/state is not the disease. The
 disease is that **the ceremony rides on a delivery substrate that has no robustness contract**, so a
  message can die silently in ~6 different places between two tabs and nobody — sender, receiver, or
   debugger — can tell where. "Two tabs saying hello" is trivial; it is hard here only because the substrate
    under it is missing. Grounding, from this session's evidence — the silent-death sites a single knock
     `pier_hello → eed831f1` passes through, any of which can eat it with NO signal to the sender:
  1. **Relay address election** (djamsend): the bare soul name `eed831f1` is held by ONE party, elected with
     no liveness check; a stale/foreign holder wins (`foreign want`) and the frame routes into the void.
  2. **`Peeroleum_route` → no-Pier drop** (`🛰☠ no Pier … DROPPED`): a frame for a peer this node holds no
     Pier for is dropped; counted, but the SENDER learns nothing.
  3. **reused-seq collision** (reborn peer, seq=1 on stale inbox history): re-ack, not re-dispatch.
  4. **`req_unemit` pre-Ud gate**: a booked frame on a Ud-less pier is silently held/dropped.
  5. **`Swarm_hello`**: `refuse()` is deliberately silent (anti-spam), and null-seal/throw were silent too.
  6. **`Swarm_ferry_on_seal`**: `if (!secret) return` — silent no-op; the linkee's `awaiting` never times out.
 Peeroleum HAS per-hop acks + retransmit + inbox/outbox — but that guarantees *hop* delivery to a Pier, NOT
  that an addressed message reached a LIVE HANDLER of the intended identity, or failed loudly if it didn't.
   That end-to-end guarantee is the gap.

**The missing middleware, named (this is the think to have next):**
- **(M1) Guaranteed-outcome delivery.** Every addressed app message resolves, within a bounded time, to
   exactly one of {delivered-to-a-live-handler, refused-with-reason, undeliverable-no-live-holder} — surfaced
    to the SENDER. No silent void. This is the generalization of the owner's "'never says why' should be
     impossible" — make it impossible at the transport boundary, once, instead of per-ceremony.
- **(M2) Truthful, observable addressing + presence.** "Who holds address X, and is that holder ALIVE right
   now?" must have an authoritative, inspectable answer. The single-holder soul-door election with no liveness
    is the bug class behind §0.1. Land-of-prepub already says *body = own address*; a device-link (and most
     directed frames) should target a BODY address, never the contested multi-holder soul door. Reconcile the
      whole soul-door concept (Swarm.go:1655 "the door is held by a sibling") with this — it may be a
       mis-feature for anything that needs to reach a specific running body.
- **(M3) Cross-node message tracing.** A message's journey (posted → routed at N → delivered/dropped, why)
   must be inspectable end to end. This session was blind for a full day because no such trace spans nodes
    (and the container can't even reach the live relay). `runner_ask console` is a local-only start.

**Framing for the reckoning:** M1+M2+M3 are one layer — a *robust addressed-messaging middleware* the
 ceremony (and Repli, and Swarm, and Story-over-wire) should ALL sit on, replacing the current pattern where
  every subsystem re-improvises silent failure. This subsumes the reckoning's CLEAN-1/CLEAN-2 (pier_hello is
   just one message that should get M1/M2 for free). Decide: build the middleware and port the ceremony onto
    it, vs. keep patching the ceremony. The week says: patching loses.

---

## 6. THE THINK, HAD (2026-09-02 night) — and THE PLAN: the `%Want`

*(Three forked analyses ran independently over the whole corpus + the substrate code — Hovercraft,
 LiesStore, Peeroleum, Repli, Reach — and converged. This section is the synthesis + the implementation
  plan. The grounding code-facts were re-verified against the tree the same night.)*

### 6.1 The finding, in one breath

**A message in flight is the only kind of state in this system that is not a particle.** Songs, tests,
 errors, friendships — all legible living matter. But the moment a frame leaves `Swarm_deliver` it exists
  NOWHERE: gone from the sender's world, not yet in the receiver's. The wire is a hole in the one bet;
   all six silent-death sites of §5 live inside that hole, and the deaths are silent BECAUSE the thing
    that died was never visible matter. Pithy law: **this is Wake ≠ Hold, applied to the network** — every
     ceremony send is a *wake* (fire the frame, hope, compensate with pokes/sweeps/ticks/reheals); it
      should be a *hold* (a req that keeps the world unsettled until the outcome exists).

The fix is not "add robustness to delivery." It is: **replace "reliably deliver an event" with "book a
 standing intent and CONVERGE it."** An addressed app message is a snapped, unfinished req in the
  SENDER's own tree that can only ever exit through one of three doors:

    landed  |  refused,<why>  |  dead,nobody-answered   — there is no fourth exit.

Its frames are **ephemeral, self-re-asking, idempotent by identity** (Peeroleum's own reliability law:
 "self-re-asking = ephemeral"). Reliability moves out of the transport (acks/seq/inbox/retransmit) into
  the state layer (idempotent convergence) — where this system keeps ALL its other reliability. A dropped
   frame becomes a non-event (the next re-ask covers it); a refusal must be WRITTEN as a settlement to
    make the asking stop, so refusing silently stops being the lazy path and becomes the impossible path.

**The week already discovered this five times by hand:** the ferry_want 3s ask-loop ("a steady flow of
 'I want Linkage' sentiment"), the derived ferry secret (re-derive from durable truth, reload-proof by
  construction), repli_want (the pull that Peeroleum's policy calls the model ephemeral citizen),
   `%Reach`/`%Owed` ("the state IS the debt"), and LiesStore itself (a disk write is a booked req that
    finishes when the reply lands, settled in phases, two-pass dropped). Each conversion made its site
     robust. `%Want` is that pattern promoted to the primitive: **Peeroleum-as-it-should-be is LiesStore
      pointed at the relay — a peer is just a slow, unreliable disk; the wire is another Wormhole.**

### 6.2 Why it dissolves (not patches) the week

- **M1 structural**: no fire-and-forget send left to police. The §0.3 "nobody answered the door" error
   is not a bolted-on timeout — it's the want's deadline firing, the only other exit the shape has.
- **M2 without the forbidden cache**: presence = "does my standing want settle" — discover-by-sending
   incarnate, satisfying the `%Reach`-reversal law (an event that resolves, never a kept-fresh verdict).
    And idempotent-by-identity re-asking makes **multi-path addressing safe**: knock the soul door AND
     every known body address; whichever live handler sees any copy settles once; duplicates are oai
      no-ops. The single-holder door election degrades from correctness-critical to a routing
       optimization — the `foreign want` curse eats one path of many, once per re-ask, and the deadline
        still surfaces it in bounded time.
- **M3 free**: the want + its settlement are particles in the snap on both ends — minisnap, Story steps,
   snap diffs, Cyto trace them without building a tracing system. The Books-green/live-red divide
    dissolves: every green was a Book because the failing thing was unfixturable; delivery outcomes
     become snap-visible and Book-gateable (`%see:'the knock settled refused — no live holder'`).
- **Both layering-doc diseases die at the root**: ceremony traffic is ephemeral-by-construction, never
   books, never touches seq/inbox/pre-Ud — a stale pier CANNOT capture it (CLEAN-1 becomes moot, not
    done). Ceremony progress = wants settling, never `pier_linklive` (CLEAN-2 subsumed); the %Pier
     shrinks to the Pier/Peering law's dial handle. And the layering doc's "pier_hello must stay
      reliable on send" dissolves: that was only true because the knock was ONE-SHOT — a standing
       re-asking want IS the thing behind the knock that heals it.
- **Wake ≠ Hold on the wire**: an in-flight want is an unfinished req → holds the Story snap →
   the flaky-ceremony-Book class is structurally gone and ceremonies become naturally Book-able.
- **What it does NOT fix** (honesty): the stale `eed831f1` relay binding is still a relay-side fact —
   demoted from invisible-fatal to one legible `dead,nobody-answered` in seconds, and routed around by
    the multi-path fan. A relay introspection endpoint stays worth one small tool, for forensics only.
     Bulk cargo (the account blob, audio) stays on Repli rails AFTER a want settles the agreement; the
      reliable booked lane keeps its real jobs (dock_push, run_result between sealed friends).

### 6.3 Grounding: the three gifts already in the tree (verified 2026-09-02)

- **`%Reach` is the seed, ~80% built** (Swarm.g ~4823–4902, Book-gated SwarmBody 10–12): idempotent
   identity triple `{Reach, to, of, for}` under %Peering (the triple IS the correlation — no corr id
    needed), states booked→dispatched→arrived|refused, capped (`reach_cap` 32), refused receipts
     MEANT to stand a TTL (1h) then sweep — the error-home PATTERN is there but is a ZOMBIE today
      (checker: `refused` is not terminal — both loops skip only `'arrived'`, so a refusal
       re-dispatches, flips back to `'dispatched'`, and dodges its own sweep; and the sweep sits
        below a default-off knob, `w.c.reach_on`). W1 makes it real. Missing:
      cross-soul dispatch (it's `Swarm_sibling_send`-only), a `deadline→dead` exit, settlements that
       carry `why`, per-want cadence (it retries on the 60s trickle), the receiver-side settle seam,
        AND auth (today `reach_done` settles ungated; `reach_road` is a plaintext prefix match).
- **Repli|Mag is the working proof of the convergence contract** (Repli.g): pull re-heals silently
   (~4s re-ask), `parked_want` is a lease — "THE ASK IS THE LEASE" (Repli.g ~613: every re-ask updates
    `asked_at`; the serving side culls a lapsed lease) — bounded park falls back to ordinary re-ask,
     arrivals are UPSERTs by identity table, completion is a state both sides converge on. It works
      *despite* complexity because a lost frame is a non-event. `%Want` copies this contract, not
       just the vibe. ("Not a request-response RPC — a walk through a landscape.")
- **The Linkor's `ferry_want` handler already computes the full verdict and throws it away**
   (Swarm.g ~1098–1162): four gates (sealed/secret/serial-match/not-ferrying) logged as
    `cave_pier= my_secret= adopt_match= ferrying=` — refused-with-reason EXISTS on the receiver and
     dies on the wrong side of the wire. The want merely carries home information already computed.
      Same story one layer down: Peeroleum's `%error` marks + `%faulty` rollup (Peeroleum.g ~1246).

### 6.4 THE PLAN — phases, each landable + Book-verifiable alone

*(Adversarially checked 2026-09-02 night — 13 findings, 4 load-bearing, ALL folded into the bullets
 below: the hold-shape (a want rides its OWN finishing req, never the eternal ceremony req), the
  settlement latch+auth (landed-beats-refused, per-kind credentials are NEW crypto wiring), the pump
   realities (knob/throttle/Book-drive), and the pier-EXISTS dispatch for settle kinds. Deferral
    honesty: SAFE-2's non-want silent sites — `hear`'s `!ident` bail, the crew-claim drops — stay an
     ORTHOGONAL errand this plan does not cover.)*

**W0 — forensics + baseline FIRST (blindspot review 2026-09-02 night; land before W1):**
  - ✅ **SAFE-3 — ALREADY LANDED** (Swarm.g ~2211–2218, the null-seal guard + `Swarm_rebuff`; found
     in-tree 2026-09-02 night). SAFE-1 (refuse an accept the giver can't fulfil) still WAITS for W2,
      where it lands properly as a settlement.
  - **The door-holder forensic — CHEAPEST PATH IS THE RELAY'S OWN LOG (verified 2026-09-02 night).**
     Correction to the blindspot claim: the `who` control frame IS real (relay.ts ~502–544, batch
      presence) BUT it is **hello-gated** — the asker's socket must be a VERIFIED hello-bind
       (`(ws).bound`), and `runner_ask` connects with an ephemeral pre-hello `?addr=` socket, so a
        who-probe would be REFUSED until runner_ask gains signed-hello (a real lift, not ~50 lines).
         AND the container is EGRESS-WALLED from djamsend:9999 (re-confirmed: TCP timeout), so any
          probe is HOST-run regardless. **So the zero-code forensic the human should do:** read the
           djamsend relay's OWN stdout/log — it logs every hello/bind/claim lifecycle event, a
            `👥 who … online` transition line, and a 10s per-(addr,type,lane) tally (relay.ts
             ~848–862, ~534–542). Whatever holds `eed831f1` prints there. The signed-hello who-probe
              is a real-but-later tool (folds into W5), not a W0 blocker.
  - **The stale-binding theory is probably WRONG**: relay.ts ~858–882 heartbeats every 15s and
     terminates+unbinds a socket missing a pong — a dead tab's binding clears in ~30s. Whatever
      holds `eed831f1` is ALIVE (a forgotten daemon / service worker / tab on another machine).
       §0.1's suspect list updated accordingly; the who-probe names it.
  - **Live BASELINE before substrate**: after SAFE-3, one real two-tab attempt on LOCAL :9091 (both
     tabs on the code under test — djamsend runs OLD code and is NOT a valid gate until a deploy).
      Record what actually breaks with the crash guard in. The W1–W5 scope is then evidence-driven,
       not theory-driven. ALL later "live two-tab" gates mean :9091 unless a deploy lands.

**W1 — generalise `%Reach` into the standing-intent primitive** (Swarm.g, at the reach code; ~1 pass).

The **six irreducible rules** (everything else is implementation detail for code comments):
1. **Three exits, no fourth**: `landed | refused,<why> | dead,nobody-answered`. Writing a refusal is
    what stops the asking — refusing silently becomes the impossible path.
2. **`refused` and `dead` are terminal in BOTH loops.** Today both skip only `'arrived'`, so a
    refused reach re-dispatches and dodges its own sweep — a zombie. Fix dispatch AND settle.
3. **First terminal latches on the PARENT; `landed` outranks `refused`.** Under a fan only the
    secret-holder can land; every other body legitimately refuses — a racing refusal must not
     overwrite a landed. Any path landing → parent `state:'landed'` (the one field readers check).
      A handler re-asked after its copy landed re-answers `landed`, never `deny('spent')`.
4. **A throw is NOT terminal** — leave unsettled + loud rebuff; the re-ask covers a transient race.
    Refuse only when provably dead (the 2026-08-31 tri-state lesson). No registered handler →
     `refused,'no_handler'` — today `reach_serve` auto-lands unknowns (`placed=1`); fix it.
5. **Each want rides its own transient FINISHING req** (`req/req/ttlilt` form), armed synchronously
    at mint, finished at settlement so hygiene drops the ttlilt. NEVER the eternal ceremony req
     (re-arm is a no-op → the second ceremony snaps mid-flight).
6. **Auth before mint.** `reach_done` is UNGATED today and `reach_road` is a plaintext prefix match.
    `Swarm_voucher_ok` gates sibling/pier-less admission before any mint or settle; pre-relationship
     kinds carry their OWN credential (?Iz presig / ferry-secret-MAC / grant-sig) — real crypto
      wiring, budget it. Inbound obligations get a SEPARATE cap from my outbound wants.

Build notes (the deltas, not a spec):
  - Particle: keep `%Reach`. Add `deadline` (the ONE timing fact — the ttlilt DERIVES from it, and
     cadence is a pump-mode constant ~3s ceremony / ~5s idle, NOT a per-want field), `why` (guarded
      — never stamp maybe-undefined), `state:'dead'`. Fan = child particles `/Reach/%path,addr:X/`
       with per-path `asked/answered/refused` (state-home law: no `.c` arrays) — the snap shows
        which door answered.
  - One pump entry, `reach_pump()`, callable from ANY driver (pulse, ceremony tick, a Book beat) —
     self-throttling, all math `Date.now()` ms (never `Swarm_now` seconds). Un-bury it: remove the
      60s throttle, lift the TTL sweep out from under the default-off `reach_on` knob.
  - Terminal wants ARE the error home: stand for the receipt TTL (1h sweep), fire `Radio_trace`,
     then drop; settled-ok wants two-pass drop like any served transient. "Try again" on a terminal
      = DROP-then-mint (oai re-book of a terminal triple is a no-op).
  - Receiver-side obligation wears its own two-word mainkey under its pier (coinage owed — see
     rulings; decide BEFORE W3, the mis-ack fix depends on it).
  - Peeroleum: want/settle kinds join the EPHEMERAL class + the pier-less lane, credential-gated
     per kind. Nothing in the booked lane changes.
  - Gate: one Book beat per terminal (landed / refused-with-why / dead-on-deadline) + idempotent
     re-book + caps; verify on the live runner, several runs.

**W2 — port `ferry_want`** (smallest live message; delivers the "nobody answered" error day one):
  - Linkee: `req:Ferry_cave` phase `awaiting` books `{Reach, to:<soul>, of:'ferry', for:<serial>}`,
     45s deadline. DELETE the LinkDevice tick, the `ask_at` throttle pair, the pulse fallback.
  - Linkor: the existing four-gate verdict (Swarm.g ~1098) feeds the settle seam — serviceable →
     `landed`; unserviceable → `refused,'no_offer'|'wrong_serial'|'ferrying'` (SAFE-1 lands here as
      a settlement; the throttled 30s ferry_cancel retires).
  - Settle kinds must ALSO ride the pier-EXISTS ephemeral direct-dispatch branch (Peeroleum.g
     ~740–751, where ferry_want lives): the Linkee's chrysalis pier is Ud-less, so a settlement that
      books into its inbox dies silently `'pre-Ud'` → the WRONG terminal. W2 needs this branch; it
       does NOT need W3's pier-less admission.
  - Linkee `dead` → "no one answered — get a fresh link" (mirror the stale-link message).
  - Gate: InvFerry/InvWalk/InvSeal + SwarmSpread green; new refused/dead beats; live two-tab attempt
     — expect it to NAME its failure even if the relay binding still eats the knock.

**W3 — port the knock (`pier_hello`) + multi-path:**
  - **THE KNOCK TARGETS THE MINTING BODY — RULED (owner 2026-09-02: "there's a Captain we need to
     find, obviously… pub+bodyid to qualify where the Link should go specifically").** The ?Iz today
      carries soul+serial+secret+presig but NOT which body minted it — that gap IS the soul-door
       coin-flip. Fix: **stamp the minter's body-prepub into the ?Iz**; the redeem knocks THAT body
        directly — uncontested by construction (land-of-prepub already gives every body its own
         address). The fan demotes to a boring 2-rung ladder: body-addr first, soul door as
          BACKSTOP (minter reloaded/moved). The soul door stays the general-purpose door for friend
           traffic (the Seat answers) — the link was special because it must reach the ONE body
            holding the adopt secret.
  - Idempotent + cross-node truth: `Swarm_hello` re-verifies, `Swarm_seal` is idempotent (layering
     §2); oai dedup exists only WITHIN one tree — the ?Iz serial-spend ledger is the CROSS-NODE
      arbiter; rank a non-holder's refusal below the holder's `landed` (the latch law); a handler
       re-asked by the SAME want that landed re-answers the same settlement, never `deny('spent')`.
        The knock runs at CEREMONY cadence — a slow trickle against a short-lived QR re-opens the
         lost-first-knock exposure.
  - Receiver: knock frames ride the pier-less lane BY TYPE, before any pier lookup — CLEAN-1 lands
     as a byproduct; the reborn-knock collision clause (Peeroleum.g ~814) DELETES.
  - `pier_accept` rides back AS the knock-want's settlement payload (recommended — subsumes layering
     §5.1's ruling; accept/confirm stay "pre-relationship until the ceremony completes").
  - Gate: full Swarm*/Inv* suite + the live two-tab reborn knock, re-run several times.

**W4 — sever + delete (CLEAN-2 + the vestigials):**
  - Ceremony progress watches its wants, never `pier_linklive`; delete the poke, the stale-ferry
     sweep, the standup reheal, the twin-rehydrate scaffolding, and the now-vestigial
      reheal/sweep/twin machinery (§3 item 4 closes). %Pier back to dial-handle + relationship.
  - Re-audit §3 concordance: the multi-body-door question stops mattering (multi-path idempotent
     asks); consent policy gets one home (consent = what the handler settles); the self-husk pier
      question stays parked (orthogonal).

**W5 — later, on ask:** point Repli's ask-side and Story-over-wire at the same primitive; the relay
 forensics tool ("who holds addr X") as a small separate errand.

### 6.5 Cautions (the discipline the slog must keep)

- **Books stay inert**: humdinger/consenter gates preserved; new frames never fire in a Book unless
   the Book drives them. Expect DELIBERATE fixture drift where wants now stand in snaps — that is the
    point (in-flight state worth SEEING); accept batches knowingly, revert unrelated churn.
- **ms vs seconds**: all cadence/deadline math on `Date.now()` ms; `Swarm_now` is SECONDS on live.
   And DON'T put raw wall-clock ms in `sc` — fixture-volatile; snap LOGICAL stamps (state, why,
    serial), keep volatile ms in `.c` under the state-home law's "vanishing" exemption.
- **Bounds (checker flaw 6)**: inbound obligations must NOT share `reach_cap` with my own outbound
   wants (~32 junk knocks would lock MY ceremony for the receipt TTL) — split the caps / per-origin
    quota, credential-check BEFORE any mint, and give the serving side a lease-style throttle
     (Repli's `asked_at` lease is the model).
- **The undef law**: `why`/optional stamps are guarded (`if (frame.why)`) — never stamp a
   maybe-undefined into sc (the encoder brands `{"undef":[…]}` and that's a mint bug).
- **Compile ladder**: LocalGen CHECK→write (GFILES trap), esbuild strict-parse the .go script block,
   reload the runner before trusting (HMR caches old .go), re-run Books for races.
- **State-home law (owner ruling, 2026-09-02)**: throughout the port, avoid `.c.*` state — favour
   child particles (`/%*/`, nested `/%*/%*` where reasonable, the Matstyle C-within-C precedent).
    `.c` only for the standing exemptions: secret / runtime ref / organ / genuinely-vanishing. The
     ferry's `.c` flag cloud (`ferry_secret`/`ferry_confirm`/`ferry_awaiting`/`ferrying`) does NOT
      get re-homed wholesale into new `.c` — each either becomes want/req sc state or dies with its
       pump. (Secrets stay `.c` — an object/secret in sc is fatal at encode.)
- **Don't touch**: the friendship grant handshake; Repli's cargo rails; Peeroleum's booked lane.

### 6.6 THE GENERAL LESSON — the mud-tells (so SoundPooling and every next invention is born clean)

*(the owner, 2026-09-02: "have we really figured out how to avoid hitting the mud like this, in
 general?" — the week's corpse, distilled to the tells that were visible EARLY every time. Wants
  promotion into Coding_guide once the W-port proves itself — the human's preen, not ours.)*

1. **The five-pumps tell.** A feature growing a `.c` flag + a poke + a sweep + a standup reheal + a
    retry tick is not five utilities — it is ONE missing hold, screaming. The ferry had all five. The
     second compensating pump you write is the signal to stop: the state wants to be a req.
2. **The silence tell.** Any async thing that can end in NOTHING (no settle, no rebuff, no trace) will
    eventually cost a blind week. Rule: every async op declares its exits BEFORE it is built — three
     doors, no fourth — checkable in the design doc, before any code.
3. **The fixture-gap tell.** If a feature's FAILURE mode is unfixturable (lives where Books can't
    snap), "Books green" is a bubble and you WILL debug it live and blind. Design question to ask
     first: *what does its failure look like in a snap?* If the answer is "it doesn't", the missing
      thing is an abstraction, not a test.
4. **The reinvention counter.** Corr-correlated request|reply existed hand-rolled FOUR times
    (runner_ask, ghost_compile, Wormhole, ferry) before promotion. The second hand-rolling of a shape
     is the last cheap moment to promote it ("one foam layer between the foam layers").
5. **The deferred-instinct tell.** The docs record the owner asking "do we build this with req?"
    (2026-08-29) and the session answering "targeted heal now, req refactor later" — twice. The heals
     worked; the mud deepened. When the instinct says "this wants to be a req," the PORT is the fix
      and the heal is the debt.

**Applied forward (SoundPooling &c.):** any new cross-node feature is born on the substrate — intents
 as standing wants (settling landed|refused|dead), cargo on Repli rails, every failure a legible
  terminal in the snap, Books asserting the REFUSALS not just the successes. Built that way, it cannot
   reproduce this week: its silent-death sites never exist to be found.

### 6.7 RULINGS OWED (the human's, before/during W1)

1. **Name** — analysis sharpened by the owner's clash question (2026-09-02 night): **keep `%Reach`**,
    and not just for fixture economy — "want" already carries THREE live senses (the relay's hello-v2
     seat "want" — literally the week's "foreign want"; repli_want/parked_want; ferry_want), so a
      `%Want` mainkey would be a fourth and muddy them all. `%Reach` has exactly ONE prior sense —
       the teleology's own `/Reach,from:Captain,of:track,for:play/` — which IS this thing. Coupling:
        contained (under `%Peering`, beside Pier/Body/Charter — the shelf scopes the word), nested
         (`/Peering/Reach/%path,addr:X/`), and the level-split resolves Reach-vs-Want cleanly:
          **Reach is the matter; want is the wire verb** — the particle is a `%Reach`, the frames it
           speaks stay `*_want`/`*_settle` (repli_want's precedent). Stretch rule: the kind rides
            `of:` (ferry/knock/pool…), never a new mainkey per kind; the over-stretch tell is
             needing a DIFFERENT identity shape (the Card-vs-Record law) — then it's a new particle.
              The receiver-side obligation wears a TWO-WORD mainkey under the pier it arrived by
               (parked_want's precedent; e.g. `%reach_held` — final coinage the owner's), so it can
                never mis-ack against my own outbound `%Reach` (checker flaw 11).
2. **`pier_accept` as the knock-want's settlement** (recommended) — this decides layering §5.1.
    NAMING (owner 2026-09-02: "pier_accept is a crappy name… maybe add more words"): under W3 the
     frame mostly DISSOLVES into the knock-Reach's settlement; if a frame name survives, more-words
      candidates: `knock_accepted` / `door_answer` / `link_accepted` — the coinage is the owner's.
3. ✅ **Knock addressing — RULED (owner 2026-09-02, unprompted convergence with blindspot #3):**
    the ?Iz carries the MINTING BODY's prepub; the redeem knocks that body DIRECTLY (uncontested by
     construction under land-of-prepub); soul door = backstop rung only. "Multi-path fan" as a
      mechanism is DEMOTED to this 2-rung ladder.
4. ✅ **Deadline feel — RULED (owner 2026-09-02: "whatever, sure")**: ~45s before "no one answered";
    "try again" is a button (drop-then-mint a fresh want), never auto.
