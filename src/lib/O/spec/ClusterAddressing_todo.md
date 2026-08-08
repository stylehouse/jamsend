# ClusterAddressing_todo

How a runner becomes *reachable* and how it becomes *chosen* are two different mechanisms that keep
 getting confused for one. This doc separates them and parks the design questions.

Companion to `Cluster_spec.md` (§3.2b boot→channel map, §3.3 Brink badges + the diagnostic ladder).
 Nothing here is blessed — `Cluster_spec.md` is the promoted statement; this is the working doc.

## 0. What to get on with next

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
