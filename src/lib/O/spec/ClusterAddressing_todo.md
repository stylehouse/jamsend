# ClusterAddressing_todo

How a runner becomes *reachable* and how it becomes *chosen* are two different mechanisms that keep
 getting confused for one. This doc separates them and parks the design questions.

Companion to `Cluster_spec.md` (§3.2b boot→channel map, §3.3 Brink badges + the diagnostic ladder).
 Nothing here is blessed — `Cluster_spec.md` is the promoted statement; this is the working doc.

## 0. What to get on with next

- **NEW 2026-08-08 — `header.from` is not an address; the wire trusts it and never verifies it (§6).**
   Four "who sent this" channels, and the authoritative-looking one is unrouted + unverified. Findings
    ranked in §6: acks mis-route to the role-slot Pier (dev emits strand), N runners share one inbox
     (reused-seq false collisions), from-less ping fans out to a false-live pong. The one
      production-facing hole — `become <prepub>` shadow-subscribing a verified identity — is **FIXED**
       this pass (`relay.ts`, `relay-test.ts`). The `header.from`→prepub unification is spine surgery
        that intersects §4/§4.5's unresolved address-model question, so it is **deferred past v1.0**
         (tracked from `Everything_todo`'s ClusterAddressing line). Read §6 before touching the wire.
- **NEW 2026-08-08 — two channels share one prepub, so every peer frame is delivered twice (§4.5).**
   Traced to source: `Swarm_station_up` and `Lies_channel_up` each stand up a `Socket_real` on their own
    world, and both bind the identity because both genuinely need `to:<prepub>`. Nothing is
     malfunctioning — the dedup catches it and no state corrupts — but each duplicate costs a decode and
      a spurious re-`ack` on the wire. **This is §4's parked question with a measured cost attached**, so
       decide it there rather than patching §4.5. Do not "fix" it by deduping; the dedup already exists.

- **`?addr=<role>` is SETTLED — leave it alone** (§2). It is not redundant with `become`; the
   difference is a reconnect race that drops one-shot role-addressed frames. §2 records the
    precondition if anyone revisits it.
- **Capability advertising has no Book.** §3 is entirely untested — `fsa:1` in the beacon and
   `Lies_dispatch_target`'s preference are asserted by comments and by nothing else.
- The deeper question the human parked, worth a session of its own: **should role addressing exist at
   all**, or should everything route by identity now that `hello` binds a real key? §4.

## 1. The arc

A runner has to answer three separate questions, and today they are answered in three separate places
 that no single doc connects:

| question | mechanism | where |
|---|---|---|
| **Where do I send bytes?** | address binding | `relay.ts` |
| **Who are you, provably?** | signed `hello` | `relay.ts:373+` |
| **What can you DO?** | capability beacon | `LiesFunk.svelte` |

Confusing (1) with (3) is what produced the 2026-08-06 mess recorded in §5.

## 2. Address binding — THREE routes, all live

1. **`?addr=<role>` at connect time.** The browser opens `ws://<origin>/relay?addr=runner`
    (`LiesLies.svelte` `Lies_channel_up`, ~:257). **Unauthenticated** — `relay.ts:374` states it
     outright: *"any socket can open ?addr=BOB and start receiving BOB's frames."*
2. **`control:'become'` with `role:'editor'|'runner'`** → `bind(msg.role, ws)` (`relay.ts:293-303`).
    Its comment says this binding exists so role-addressed traffic (the editor↔runner keepalive, any
     `to:'runner'`) reaches the socket *"even when the socket didn't (or couldn't) carry `?addr=`"*.
3. **`control:'hello'`, ed25519-signed** → `bind(prepubOf(pub), ws)` (`relay.ts:373+`). This is the
    real identity leg — `to:<pub>` addressing, Cluster_spec §3.2. Explicitly **add-only**: `?addr=`
     still works for the un-migrated path.

So a runner tab is bound under **both** `runner` (role) and `a67a5d04…` (identity), simultaneously and
 by design. Seeing `?addr=runner` in a ws log is *not* evidence that the identity migration didn't
  happen.

**Role addresses are BROADCAST.** `bind` accumulates into a `Set` and `deliverLocal` sends to every
 open socket on that address (`relay.ts:133-157`). `to:'runner'` therefore reaches *all* runner tabs.
  Intentional, not a collision — but it means role addressing cannot select a *particular* runner,
   which is precisely why §3 exists as a separate mechanism.

**SETTLED 2026-08-06 — (1) is NOT redundant. Do not remove `?addr=<role>` from the browser URL.**
 It looked redundant: route 2's comment says it binds the role *"even when the socket didn't (or
  couldn't) carry `?addr=`"*, which reads as a timing-equivalent replacement. It is not — it is a
   fallback for a *missing* `?addr=`, and the difference is a real race.

- `?addr=` binds inside the server's `connection` handler (`relay.ts:480`), which runs to completion
   **before the client can fire `onopen` at all**. No window.
- `become` is sent *from* `onopen` (`LiesLies.svelte:325`, via `Tribunal.g`'s open hooks), so its bind
   lands only after a **full network flight** — and that hop is cross-container (`172.17.0.1:9091`),
    not loopback.
- In that window, role-addressed frames are **silently dropped** at `routeFromBrowser`
   (`relay.ts:266-279`) with only a `warnDrop`. The relay never queues or retries them.

Most traffic survives it — anything causally triggered by hearing from the peer is FIFO-safe on one
 socket, and `ping`/`advertise` resend every 5–15s. What does not: `Cluster_spec.md:479-497` keeps
  runner→editor traffic role-addressed, and some of it is **one-shot and never retried** —
   `wormhole_req`, terminal `run_phase` frames, and the cold "no runner known" `become_book` broadcast
    (`LiesFunk.svelte:1873`), which returns `true` once the send call is made regardless of delivery.

**Precondition if this is ever revisited:** make those one-shot sends wait for the relay's
 `{control:'role', role}` ack — proof that `become` landed — instead of the current `Lies_channel_live`
  gate, which goes true as soon as `channel_up` is locally stamped, before the socket is even
   guaranteed OPEN. Without that, removing `?addr=` trades an unauthenticated claim for silent loss.

**Not covered by any test:** `relay-test.ts:55` and `runner-ask-test.ts:37` both open with `?addr=<role>`
 *and* send `become`, so neither isolates `become`-only timing. Nothing would catch the regression.

**Do not conflate the CLI use.** The scripts pass a *unique cli id* as `addr`, never a role
 (`runner_ask.mjs:220`, `ghost_compile.ts:172`, `runner_shot.mjs:102`, `story_repl.mjs:265`,
  `reactap.mjs:36`), and none of them send `become` — `?addr=` is their only bind. A change scoped to
   the browser's URL construction (`Tribunal.g:65`) does not touch them.

## 3. Capability advertising — a SEPARATE axis

Reachability says nothing about suitability. A Book can declare requirements, and the dispatcher tries
 to honour them:

- A Book declares via `%Storying,of_Book:<book>` facets — `needsFSA:1`, `needAC:1`, needMusic.
- A runner **advertises** what it has: the beacon publishes `fsa:1` (`LiesFunk.svelte:2144`).
- The editor picks: `Lies_dispatch_target(w, needAC, needsFSA)` prefers a capable runner
   (`LiesFunk.svelte:1846`), falling back to broadcast, then to preempting our own runner.
- The runner itself gates on arrival: `if (needsFSA && !Lies_has_fsa(w))` (`LiesFunk.svelte:1977`),
   with sibling gates for AC and for the music collection.

**This axis has no test.** Every claim above is a comment. Whether the beacon actually carries `fsa:1`,
 whether `Lies_dispatch_target` actually prefers on it, and whether preference degrades sanely when no
  runner is capable — none of it is gated by a Book. Given the repo's recent record on comments that
   assert unmeasured runtime properties, treat all of it as hypothesis.

## 4. The parked design question

Role addressing exists because it predates identity addressing. Now that `hello` binds a verified key,
 `to:'runner'` is the only remaining reason for an unauthenticated address claim to exist at all — and
  it can only ever mean "any runner", never "that runner". Meanwhile capability routing already needs
   to name a *specific* runner, and does so by identity.

The question to think through some other day: **collapse role addressing into identity + capability?**
 A named `to:<pub>` plus a beacon that says what that peer can do covers everything `to:'runner'` does,
  with authentication and without broadcast. What would be lost is the bootstrap case — a tab that must
   be reachable *before* it has an identity to prove. Whether that case is real is the crux.

## 4.5 TWO sockets, one identity — every inbound frame delivered twice (2026-08-08)

**Evidence, from one live `/BigSoundland` console** (the owner's tab, wild-heron `f5da6599b8505881`):

    🛰 ws OPEN ws://localhost:9091/relay?addr=f5da6599b8505881 — flushing 0 buffered
    🛰 ws OPEN ws://localhost:9091/relay?addr=runner            — flushing 0 buffered
    🛰 ws SEND control:become role=runner
    🪪 ws SEND control:hello f5da6599b8505881
    🛰 ws RECV control:hello_ok
    🛰 ws RECV control:role role=runner
    🛰 ws RECV control:hello_ok          ← TWO hello_ok, so BOTH sockets bound an identity

and thereafter **every inbound frame logged twice**, interleaved rather than adjacent — two ordered
streams, not a doubled log line:

    ws RECV ive_got seq=10 · seq=10 · seq=12 · seq=14 · seq=12 · seq=14   (A:10,12,14 ⊕ B:10,12,14)

**Mechanism, and §2 already states it:** `bind` accumulates into a **Set** and `deliverLocal` sends to
*every* open socket on that address. §2 describes **one socket bound under two addresses** (role +
identity) — which is correct and by design. What this tab has is **two sockets bound under the same
identity**, so the Set holds two entries and each `to:<prepub>` frame is delivered to both.

**What it does NOT cause — checked, so nobody re-chases it.** No corruption. On a reliable carrier
`Peeroleum_deliver` asks `Peeroleum_served_before` *before* booking (`Peeroleum.g:720`), so the second
copy is refused re-dispatch. The `reused-seq collision` warn that would reveal this is throttled to
~1/s per (pier,type) — which is exactly why the console shows the doubling and never names it.

**What it does cost:** per duplicated frame, a decode, a ledger lookup, and — because the collision path
*must* re-ack to stand the sender's retry down — **a spurious `ack` back over the wire**. During a heist
that is a steady stream of acks the peer did not need, on the same beat the radio is starving on (see
`Composition_todo` §3.6). Small per frame; the frame rate is the problem.

**WHY there are two — answered from source, not guessed.** `Socket_real` has exactly two callers, on
two different worlds, and both are legitimate:

| socket | stood up by | world | dials | binds |
|---|---|---|---|---|
| A | `Swarm_station_up` (`Swarm.g:673`) | `w:Swarm` | `?addr=<prepub>` | `<prepub>` via its own signed `hello` in the `on_open` hook (`Swarm.g:676+`) |
| B | `Lies_channel_up` (`LiesLies.svelte:318`) | `w:Lies` | `?addr=runner` | `runner` via `become`, **and `<prepub>`** via a signed `hello` re-reading `Lies_cluster_idento` (§3.2b) |

So this is **not** a double-standup and **not** a stale half-open socket — the `channel_up` guard is
innocent. Two channels exist by design, and each independently binds the identity because each
genuinely needs `to:<prepub>` traffic: A for peer frames, B because cluster addressing is *also* by
prepub (§3.2b item 4 — engage `to:<prepub>`; `runner_ask --runner=<addr>` is exactly this).

**The actual defect is one address space serving two channels.** Cluster identity and swarm identity are
the same prepub, so the relay cannot tell a peer frame from a cluster frame by address — it routes both
to both. Everything downstream is working correctly *given* that: the Set-valued `bind` fans out, and
`Peeroleum_served_before` cleans up after it.

**Which makes this §4's question with a cost attached.** §4 parks "collapse role addressing into identity
+ capability?" — this is the same seam from the other side: identity addressing alone is *ambiguous*
while two channels share one prepub. Any resolution (a channel-qualified address like `<prepub>#lies`,
or B dropping its identity bind and taking cluster traffic by role only) is a real routing change, so it
is the human's call and not a tidy-up. **Do not "fix" it by deduping** — the dedup already exists; the
duplicate delivery is the symptom, the shared address space is the thing.

## 5. The 2026-08-06 needsFSA mess — a refusal must be reportable

`needsFSA` in a `runner_ask run` reply is the **Book's declaration echoed back**, not a refusal —
 `LiesFunk.svelte` builds the reply from `ask.needsFSA` and sets `accepted:true` in the same object.
  The CLI printed a warning for it unconditionally. Two independent readers concluded the runner lacked
   FSA; a 69-Book sweep wrote off **16 Books as un-runnable**. MusuHeist then ran **22/22 green** on
    that same runner, followed by MusuRadio, MusuLossy, MusuOgg, MusuSoft, MusuBay and MusuBerth.

Root cause was not the misleading print. It was that a **real** refusal had nowhere to go: the three
 pre-run gates called `Lies_runner_phase`, but they fire *before* `Lies_runner_begin` opens the run
  record, and `Lies_runner_track` starts `const sr = Lies_rungo_record(w); if (!sr) return`. The refusal
   was discarded every time. So the honest signal did not exist, and the misleading one was the only
    thing anyone could read.

Fixed by `Lies_book_refuse` (`.c`-only) → surfaced on the `state` reply as `refused` → reported by the
 watch loop with the runner's own reason. **The lesson worth keeping: a capability block must be
  reportable at the moment it happens, in a place a client already reads. A gate that refuses into the
   void is worse than no gate, because the absence gets explained by whatever plausible thing is
    nearby.**

## 6. The `header.from` survey (2026-08-08) — four findings, read from source

Prompted by the human noticing `from:"runner"` on the wire beside a body-level `from:<prepub>`.
 The short truth: **there are four "who sent this" channels, and `header.from` — the one that looks
  authoritative — is the only one neither routed on nor verified.** `header.to` routes
   (`relay.ts headerTo`); body `from` is patched in by hand three times (ping/pong/advertise,
    `LiesLies.svelte:1315,1347,1482`, each with its own humdinger guard); the Swarm carries
     `page.prepub` + a signed voucher and **deliberately ignores `header.from`** (`Swarm.g:468` says
      why). `header.from` is just `peering%name` — on the Lies channel, the role string.
 **Parked well beyond v1.0** (the human's call, 2026-08-08): the fix — make `header.from` the
  hello-bound prepub, same namespace as `to`, retiring the three body-`from` patches — is §4's
   collapse question wearing work clothes, and it lands inside §4.5's unresolved shared-prepub
    ambiguity. Spine surgery (`Peeroleum.g` → gen → pinned_stable promotion + wire-Book fixture
     churn), so NOT a pre-production tidy-up. Listed in `Everything_todo.md` §Parked.

The findings, each with its production-ops **tell** so nobody misdiagnoses live:

- **6.1 Acks from a runner never retire an ADDRESSED emit.** `Peeroleum_send_to` books the outbox
   emit on the promoted Pier (`pub:<prepub>`, `Lies_runner_pier`), but the runner's ack comes back
    `from:'runner'` (`Peeroleum.g req_unemit`, `me = pier.c.up%name`), so the editor's
     `Peeroleum_route(…, 'to')` resolves the ROLE-slot Pier (`pub:'runner'`) and `Peeroleum_take_ack`
      searches the wrong outbox. Every `rungo`/`ghost_compile`/`ghost_ledger`/addressed `become_book`
       emit strands un-acked, accumulating toward the 2000 backstop. Bonus hazard: promoted Piers
        allocate seq from 1 per promotion, so an `ack:1` can false-positive onto an unrelated
         role-Pier emit with seq 1. **Tell:** a `%outbox` steadily filling with `sent`-never-`acked`
          rungo/ghost_compile emits on a healthy channel is THIS, not a dead runner.
- **6.2 N runners share ONE inbox on the editor.** Same mis-route: every runner's booked frame
   carries `from:'runner'`, so all of them land in the single role-slot Pier's inbox, whose dedup
    key is `(seq,type)` only (`Peeroleum_book_unemit`). Two runners whose seq counters collide (two
     tabs reloaded together march in near-lockstep) → the second frame hits the reused-seq collision
      path: re-acked, **never dispatched**. **Tell:** `reused-seq collision … a reborn peer wants the
       epoch reset` with 2+ live runners and NO reload is THIS, not a reborn peer.
- **6.3 The fan-out pong keeps the wrong runner alive.** A from-less ping (editor's own, or any
   humdinger's) falls to `Peeroleum_send_consumer` → `to:'runner'` → `deliverLocal` fans to EVERY
    bound runner. `Lies_pong_recv` computes `rtt = now - fr.t` and stamps `last` without checking
     the echo was OUR ping — so runner B's 20s watchdog is kept green by runner A's heartbeat.
      The 2026-07-05 flap was the starvation face of role addressing; this is the **false-live**
       face. **Tell:** a runner whose `%channel_peer` reads fresh while its own sends strand.
- **6.4 `become <prepub>` shadow-subscribes a verified identity — FIXED 2026-08-08.** The §4a
   widening (`SANE_ROLE`) let an unauthenticated socket `become <any 16-hex prepub>`: `bind` is
    additive, `deliverLocal` fans out, so it received a COPY of every frame addressed to a
     hello-verified identity (swarm frames, music chunks, wormhole replies). Now refused shape-wise
      in `relay.ts` (`IDENTITY_SHAPED`, ≥16 pure hex — identities bind via signed hello alone);
       three checks in `relay-test.ts` gate it. **There were THREE doors into the same additive
        `locals` fan-out Set, not one:** `become <role>` (now refused if identity-shaped),
         `subscribe <name>` (now refused unless `@`-prefixed — legit channels always are, so free),
          and `?addr=<name>` at connect time. **Two shut; the third stays open by design:**
           `?addr=<prepub>` is load-bearing for the pre-hello window (`Swarm_station_up` dials
            `?addr=<own prepub>`). Closing it needs §2's precondition first (one-shot senders wait
             for `hello_ok`/role ack), else legitimate first frames drop silently. Until then,
              `to:<prepub>` privacy is NOT enforced against a pre-claiming eavesdropper.

**This conflicts with `Cluster_spec.md` §3.2a/§3.2b, and the SPEC is the stale one until this lands.**
 §3.2a/§3.2b read *"the relay binds one socket per addr — `become runner` is a single slot, not a
  subscription"*; wrong — `bind` accumulates into a **Set** and `deliverLocal` fans out to every socket
   on the addr (§2, §4.5). And §3.2's *"to:<pub> routes to a VERIFIED identity"* was true only of the
    hello-bound socket: `bind` being additive, a `become`/`subscribe`/`?addr=` claim bound a SECOND,
     unauthenticated socket under the same addr and got a copy — "…plus anyone who claimed the name."
      Two of those three doors are now shut (6.4); `?addr=` stays open by design.

### The fix (deferred — it intersects §4/§4.5, so it is the human's call, not a tidy-up)

Make `header.from` carry the **hello-bound prepub** on every frame (same namespace as `to`) and delete
 the three body-`from` patches (ping/pong/advertise). That makes `Peeroleum_route`'s Pier pick correct
  per-runner and closes findings 1–3 at once. Two things to settle first:
- **First-contact Pier promotion** for an unknown prepub on the RECEIVE side — transport-level only, so
   roster enrollment stays advertise's job and the humdinger leak does not reopen.
- **It is spine surgery.** `Peeroleum.g` → ghost-compile → `gen/N/` → hand-copy to `p2p/pinned_stable/`,
   and every wire Book's fixtures re-baseline. This is exactly the pre-production networking churn to
    avoid on a go-live week — and it lands dead-center in §4.5's shared-prepub-address ambiguity, which
     §4 already parks as an unresolved routing decision. Decide the address model there FIRST; unifying
      `header.from` before that risks baking in the ambiguity.

**Why this is safe to defer past v1.0.** The production/end-user path is the **Swarm** channel, which
 routes `to:<prepub>` and carries its own signed identity precisely because it never trusted
  `header.from`. Findings 1–3 bite the **editor↔runner dev cluster** (stranded dev emits, shared-inbox
   collisions with 2+ runners) — operational friction, not user-facing. The one genuinely
    production-facing hole was #4 (unauthenticated eavesdrop on a verified identity), and that is fixed
     now. So: mess recorded here with its tells, #4 closed in `relay.ts`, the rest deferred to the
      addressing-model session.
