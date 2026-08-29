# Networky directions — the one pattern the transport is missing

Distilled 2026-08-29 from a live flood + three independent architectural audits (bulk transport,
 gossip/presence/epoch, relay/connection). This is a **working `_todo`**, not a spec — the human
  preens a doc before it earns `_spec`. It states an *arc*, not a task list; the per-subsystem todos
   (`Backpressure_todo.md`, `Cluster_spec.md`) hold the detail.

## The one bet this doc makes

**Separate the data plane from the control plane — at BOTH layers where they are currently fused.**
 Every "do this first" the three audits reached independently is that same move at a different layer.
  The app is nominally peer-to-peer and nominally particle-native; today it is neither where it counts,
   because bulk audio bytes are threaded through the two mechanisms built for *coordination*, not *bytes*:
    the relay websocket (the wire) and the belief-loop inbox (the app). Pull those bytes out and the
     flood, the flap, the O(depth) drain, the gossip storm, and the byte-dropping backstop all lose their
      reason to exist at once.

## ⚠ Reality check (2026-08-29, the human): WebRTC DataChannels fail HEAPS of the time on NZ
 residential internet. So the audits' "keystone" — move bulk onto WebRTC (item 2) — is **NOT a keystone**;
  it can only ever be OPPORTUNISTIC with the relay ws as the normal-case fallback. The real job is not to
   *escape* the relay but to **make the relay survive bulk**. This demotes item 2 and promotes the cheap,
    relay-side, no-WebRTC wins (backoff, relay-side backpressure, gossip-off-lane). Do NOT sink effort into
     WebRTC as the answer until the NZ-failure cause (NAT traversal? TURN missing/misconfigured? — worth its
      own investigation) is understood; a p2p path that fails most of the time is a fallback, not a plan.

## 0. What to get on with next

Ranked by leverage-per-line, RE-ORDERED for the WebRTC-unreliable reality above: the relay ws is the
 real transport, so the priority is stopping it from flapping + starving under bulk, not moving bulk off it.

1. **[cheap, mine to land] Gossip off the shared serial inbox.** Add `ive_got` to the ephemeral
   receive-bypass (`Peeroleum.g:664`) so a boast never books an inbox `%req:unemit` + O(depth) rollup and
    can never starve Invite/LinkDevice handshakes. **Blocker, already scoped:** `SwarmGot` asserts on the
     boast being *booked*, not *delivered* — land it WITH a `Swarmation.g` rewrite that asserts on the
      `%IveGot` fact appearing (delivered) regardless of lane. That is the whole cost, and it finally
       settles the booked-vs-delivered question parked at `Peeroleum.g:665-674`. (The 2026-08-29
        `swarm_gossip_hi_ms` hi-boast throttle is correct triage but treats the symptom; this is the root.)
2. **[DEMOTED — opportunistic only, see reality check] Move bulk `repli_page` onto WebRTC DataChannels;
   relay = signaling/gossip only.** WebRTC fails heaps on NZ internet, so this is a best-case fast path with
    relay fallback, NOT the fix — and worthless until the NZ-failure cause is diagnosed. The
   substrate is ALREADY BUILT and idle: `Peerily.svelte.ts` has a real `RTCPeerConnection` +
    `createDataChannel` + `bufferedAmount` backpressure + STUN/TURN (`Peer_OPTIONS`); `Tribunal.g`'s
     carrier-trial + `Tribunal_redial` fall-to-relay machinery exists. Today it is exercised only by the
      PeeringLive test harness (`MachPeerily.svelte`), never the live swarm — `Swarm_station_up`
       (`Swarm.g:1299-1363`) goes straight to `Socket_real` + the relay ws with no webrtc probe. Wire the
        DataChannel as a real `%transport,type:webrtc` port whose `send` carries `repli_page`, run the
         webrtc-first trial in the *swarm* path, keep the relay as signaling + fallback.
3. **[cheap, do alongside 2] Backoff that survives a short-lived open + a ws health gate.** `tries` resets
   to 0 on every `onopen` (`Tribunal.g:292`), so a socket that dies 600ms after opening is pinned at
    attempt-1 forever — the jittered-exponential backoff (`Tribunal.g:307`) degenerates to a ~600ms fixed
     storm, exactly the live log. Only reset `tries` after a connection survives a threshold (~10s stable).
4. **[the deeper bulk fix] Bulk bytes off the belief-loop inbox.** Even on a DataChannel, if pages still
   land as `%req:unemit` and mint under the beliefs mutex, the O(depth) drain (`Peeroleum_book_unemit`'s
    per-frame `oai` scan + `Peeroleum_rollup_faulty` rescan) remains. Land chunk bytes in a plain per-Pier
     buffer, verify off-mutex, and let only the *completion fact* ("page N landed") become a particle. This
      retires the drain, the mutex convoy, the ephemeral/reliable type table, AND the 2000-frame backstop.
5. **[turn on, don't build] The self-clocking window.** The ack-clock + AIMD (`Backpressure_todo.md`
   §5.6/item 4, `Ra_clock_arm`/`Ra_clock_issue`, gated `heist_selfclock`) is written and default-off. Once
    (4) removes the O(depth) drain, the window can actually close the loop instead of racing its own drain.
6. **[medium, defer] Anti-entropy gossip: digest-then-delta with a reconcilable digest.** See Front C.
7. **[invasive, last, not under fire] Fold the epoch into the sequence space.** See Front D.

### Handover to the Invite/LinkDevice agent (their "Stage 5 / #37")

Your live Invite/LinkDevice tests didn't freeze on invite code — they froze on **belief-mutex
 starvation**. Reliable handshakes queue in the SAME single serial belief-loop inbox that the flood
  fills (the "one-pipe-two-layers" chain below); a gossip/bulk storm drains ahead of them and the
   O(depth) drain (`Peeroleum_book_unemit` per-frame `oai` scan + `Peeroleum_rollup_faulty` rescan)
    collapses under the backlog, so the mutex convoy never reaches your handshake. The C-foam refactor
     won't fix this — the fusion is the serial inbox, not the object model.

Hard coupling worth knowing: **§0-item-1 (gossip off the shared serial inbox) IS the SwarmGot
 re-record.** Item 1 must land WITH a `Swarmation.g` rewrite that asserts on the `%IveGot` fact
  appearing (**delivered**), not on the inbox `%req:unemit` being **booked** — which finally settles
   the booked-vs-delivered question parked at `Peeroleum.g:665-674` AND greens `SwarmGot`
    (`Swarm_compact_invite_todo.md` §5). So do not re-record `SwarmGot` off its current `state:redeeming`
     red in isolation; it lands as one change with the gossip-off-lane fix. The 2026-08-29
      `swarm_gossip_hi_ms` hi-boast throttle + the `Tribunal.g` backoff fix (§0-item-3, landed) are triage
       that stop the *amplifier*; item 1 + item 4 are the root that stop the *starvation*.

The deterministic reproduction of your freeze is `MusuNeGrind` (`Backpressure_todo.md` §0/§00) — the
 missing composition test level where pull + radio + replicate + a handshake all share the beat at once.
  Its load-bearing invariant, "the beat never overruns 600ms for N consecutive ticks," is exactly the
   starvation your handshake hit.

## The diagnosis — one pipe, two layers

The live incident (2026-08-29): a real album Heist over `wss://djamsend.duckdns.org:9999/relay` flooded the
 sink to 2050 undrained inbox frames, dropping real bytes at a 2000 backstop, while the relay `ws CLOSE
  code=1006 clean=false` / reconnected every ~600ms. That is not five bugs; it is one missing separation
   observed under stress:

> bulk saturates the **single relay ws** → buffer/keepalive starvation → `1006` flap → reconnect storm →
>  `swarm_hi` storm → full-census `ive_got` boast storm → the **single serial inbox** fills → the O(depth)
>   drain collapses → the backstop drops real `repli_page`/`ive_got` bytes → the 4s re-ask timer re-buys
>    pages already sitting undrained → deeper inbox → slower drain. Congestion collapse in a bounded window.

Two fusions cause it, and each audit found one end of them:

## Front A — the wire: bulk rides the ONE relay websocket (WebRTC is built but dormant)

`relay.ts` is a dumb address-routed frame forwarder over one ws per tab (`deliverLocal`, `relay.ts:229`).
 **Bulk `repli_page` bytes ride that ws, not a p2p DataChannel** (high confidence: `Socket_real.port.send`
  is the only path shipping pages, and its bulk lane is built around `ws.bufferedAmount`, `Tribunal.g:122-192`;
   the 1.5MB/s over the relay while it flapped confirms it). So:

- **A single relay is a SPOF *and* the actual data pipe** — a "p2p" app whose peer traffic all transits one
   node is a star with extra steps.
- **Bulk-on-the-control-socket is the flap's root.** The code half-knows this: the bulk lane exists to keep a
   pong from queuing behind a 256KB page (`Tribunal.g:122-129`), but that mitigation is *sender-local*; the
    relay's egress buffer and the downlink still carry MB + keepalive on one socket. `1006 clean=false` at a
     ~600ms cadence is the fingerprint of a socket wedged by a full buffer / missed keepalive, then reaped.
- **The relay applies NO backpressure** — `deliverLocal` does a bare `ws.send()` with no `bufferedAmount`
   check, piling MB into a slow browser's server-side buffer. There is no end-to-end flow control.

## Front B — the app: bulk + gossip drain through the ONE serial inbox

Booked frames drain through a single per-Pier `%req:unemit` queue, one at a time under the beliefs mutex
 (`Peeroleum.g:689-694`). Feeding a byte stream through an app-state reconciliation queue is the core
  mismatch:

- Every insert is O(inbox-depth) (`Peeroleum_book_unemit`'s `oai` dedup scan) plus a conditional whole-inbox
   `Peeroleum_rollup_faulty`; so drain cost scales with backlog and **loses the race to its own RTO** under
    load — the flood is ~32 real pages served ~64× over.
- The **ephemeral-vs-reliable per-type table** (`Peeroleum.g:382-436`) is the tell: every bulk type had to be
   hand-carved OUT of the app's reliability machinery to stop it flooding the `%outbox`. When the data plane
    must opt out of the app plane one frame-type at a time, they are the same pipe and shouldn't be.
- The **2000-frame backstop dropping in-flight bytes** is the failure made load-bearing — admission control
   by amputation, feeding the 4s re-ask loop.

## Front C — gossip is full-census broadcast, not anti-entropy

`Swarm_gossip_music` (`Swarm.g:2591`) push-boasts a full census — two integers, records + artists — to every
 live friend, defended only by timers (the new per-ident cooldown, the 30s `Swarm_boast_floor`). Smells:

- **Re-broadcast instead of reconcile.** The change-gate is *sender-side* ("did MY shelf change") — it cannot
   know what the receiver already holds, so reconnect/rebirth re-sends a census the peer has. Under a flap,
    that is the storm. The right primitive: exchange a compact **digest**, transfer only on mismatch.
- **Counts are decorative.** Two integers cannot answer "what do you have that I don't"; you can't diff or
   dedup them (`Swarm_ive_got_tally` admits it). If a boast is going to cost an inbox slot, it should carry a
    **reconcilable set digest** (Merkle/Bloom of track IDs), not a scalar.
- Presence is O(N) full-mesh `pulse` with a fixed 15s "quiet" timeout and no suspicion/indirection — **SWIM**
   (randomized k-probing + indirect pings + suspicion) or a relay-issued presence **lease** belongs here at
    swarm scale (`Swarm_pulse_all:2504` already spells out the N-wasted-frames problem).

## Front D — the epoch machinery is scar tissue

`station_era` + `saw:` echo + `Swarm_note_era` + rebirth-reset + `era_kicks` 5s→60s backoff exist for ONE
 reason: `Pier_next_seq` is per-Pier and **persisted across reload on the sender** (`Swarm.g` seq `.c`
  survives), so a reload replays low seqs into the receiver's stale `%unemit` history → the `reused-seq
   collision` (`Peeroleum.g:648-653,723-738`). Namespace the sequence space by a **per-connection session
    nonce** (fresh each socket open) and a reload becomes a clean new session with seq=1 and no collision —
     deleting most of that apparatus. High reward (retires a subsystem), high blast radius (rebirth-reset
      currently drives want/park cursor cleanup — that must move, not vanish). **Do it deliberately, last,
       not under fire.**

## The convergent move, ranked across fronts

| # | Move | Front | Cost | Why |
|---|------|-------|------|-----|
| 1 | `ive_got` → ephemeral receive-bypass (+ Book rewrite for *delivered*) | B/C | low | gossip can't starve handshakes; settles booked-vs-delivered |
| 2 | bulk `repli_page` → WebRTC DataChannel; relay = signaling only | A | med | removes bulk from the flapping socket; substrate already built |
| 3 | backoff survives short-lived opens + ws health gate | A | low | stops the ~600ms fixed-interval reconnect storm |
| 4 | chunk bytes → plain buffer, only completion facts become particles | B | med | retires O(depth) drain, mutex convoy, ephemeral table, backstop |
| 5 | turn on the self-clocking window (already written, gated off) | B | low | closes the loop once (4) lands |
| 6 | anti-entropy gossip: digest-then-delta, reconcilable digest | C | med | idempotent by design, not by timer |
| 7 | fold epoch into a per-connection session nonce | D | high | deletes the era/rebirth subsystem |

## What is already built — turn on, don't build

- **WebRTC DataChannel + backpressure + TURN**: `Peerily.svelte.ts`, driven today only by `MachPeerily.svelte`
   (PeeringLive test). The carrier-trial + fall-to-relay lives in `Tribunal.g`.
- **Ack-clock + AIMD window**: `Ra_clock_arm`/`Ra_clock_issue` (`Ra.g`), fire branch in `Repli_land_rtt`
   (`Repli.g`), gated `heist_selfclock`/`heist_window` — `Backpressure_todo.md` §5.6/item 4.
- **Client-side bulk lane** honouring `ws.bufferedAmount`: `Tribunal.g:122-192` (needs its relay-side twin).

The architecture was clearly built to run bulk over p2p DataChannels and to self-clock the window; both are
 idle. This doc's bet is that the next networking work is mostly *activating and separating* what exists, not
  inventing — with the two Book rewrites (SwarmGot delivered-not-booked; and re-recording after the bulk lane
   moves) as the real, non-optional cost.

## Relationship to existing docs

- `Backpressure_todo.md` — the bulk/flow-control detail (drainbound, ack-clock, budget, the O(depth) drain,
   the MusuNeGrind reproducer). Fronts A/B live there in the small.
- `Cluster_spec.md` — the relay/boot/channel map (§3.2b, §3.3). Front A's relay reality lives there.
- The `swarm_gossip_hi_ms` throttle (2026-08-29, `Swarm.g` `Swarm_boast_on_hi`/`Swarm_hi_boast_cooling`) is
   the triage that bought time for Front C.

---

## Freeze-fix implementation plan — the SURGICAL BOUND (owner 2026-08-29: "freeze fix first, surgical bound")

The owner is hitting **10–20s** whole-UI freezes (not 0.1s) under a live `repli_page` flood (`7950f300 → eed`). Design-team intake done; owner's calls: **freeze-fix before the cell/foam rebuild; surgical bound before the full item-4 data-plane separation; verify on a live runner (owner leaves a tab up).** This is the grounded plan for the Opus implementation slog.

### The corrected root (read the code, 2026-08-29)

- `Peeroleum_rollup_faulty` is **NOT** the live melt any more — it was gated O(1) on 2026-08-05 (`Peeroleum.g:1158`: `if (!pier.c.faulty_owed && !faulty0) return`). The O(N²) comments around it (`:692,815,1145`) describe the *cured* old behaviour. Do not "fix" it again.
- The **live O(depth)** is `Peeroleum_book_unemit` (`Peeroleum.g:800`): `let ureq = inbox.oai(usc)` — `oai` scans the inbox's children to find/create the `{req:'unemit',seq,type}`, so it is **O(inbox-depth) per booked frame**.
- Under a **sustained** flood, `Peeroleum_bound_safe` (`:764,792`) only culls **served/finished** reqs into the `%inbox/recent` ledger; **in-flight (un-served) unemits accumulate**, so the inbox depth stays high, every `oai` stays O(depth), and booking N frames is **O(N²) under the beliefs mutex** → one tick holds the loop for the 10–20s = dead UI.

### The bound (do the least, keep the guards)

Three candidate cuts, in preference order; the slog picks/combines after reading `Backpressure_todo.md §0/§00/§5.6`:

1. **O(1) booking (highest leverage, most delicate).** By the time `Peeroleum_book_unemit` runs, the **inseq gate above it** (`:748-762`, `inseq_admit`) has already rejected `seq ≤ last` (re-ack, never re-book) and holds gaps — so a frame that reaches booking is **new by construction**. That means the `oai` find is provably a miss and can be a **direct create** (or an O(1) `.c` seq→req index), turning booking O(1). ⚠ THE GUARD THIS MUST NOT BREAK (`:800`-block comment): the reused-seq collision check re-acks off a **standing FINISHED `%req:unemit`** (the "already served" memory) to stand a sender's retry down instead of re-dispatching (a 2nd `hear_trust`/`dock_push` is the corruption at stake). That memory now lives in the `%inbox/recent` **ledger** (`Peeroleum_served_before`), so O(1) booking is safe **only** if the dup-detection reads the ledger, not a live `oai` over the inbox. Verify `Peeroleum_served_before` covers every path the old `oai` dedup did before switching.
2. **Cap in-flight depth WITHOUT dropping bytes.** The 2000-frame backstop drops real bytes (the doc's Front B sin). Instead, when in-flight depth crosses a threshold, **stop ACKing** so the sender's window closes — flow control, not amputation. This is the seam the **already-written, default-off self-clocking window** (`Ra_clock_arm`/`Ra_clock_issue`, `heist_selfclock`/`heist_window`, item 5) plugs into; turning it on may be most of this cut.
3. **Time-box the drain per mutex hold.** Bound `inbox.do()` to ~M ms (or N frames) per belief tick, then release + `feebly_ponder()` to resume — so no single tick can overrun the MusuNeGrind invariant ("the beat never overruns 600ms for N consecutive ticks"). Safest as a backstop *on top of* (1); on its own it bounds the freeze without curing the O(depth).

### Verify (owner leaves a runner tab up)

- **Reproducer:** `MusuNeGrind` (`Backpressure_todo.md §0/§00`) — the missing composition level where pull+radio+replicate+handshake share the beat; its invariant IS the freeze. Build/run it on the **live runner** (`scripts/runner_ask.mjs run MusuNeGrind --watch`), never headless.
- **Regression net:** `SwarmSpread` 5/5, `SwarmStaple` 8/8 — **N≥5 re-runs** (a bounded drain is a timing change; races only show across runs, Coding_guide:54-57). Exclude the `SwarmGot`/`SwarmWire` red — it is the OTHER (ive_got/Tribunal) thread's territory (`Focus_todo` bomb note), and item 1 (gossip off-lane) is coupled to its `SwarmGot` re-record; **do not touch gossip/ive_got here.**
- **Live feel:** the owner clicks during a flood — the ~10–20s dead windows must be gone (bounded to one tick's budget).

### Risk

HIGH — the beliefs mutex + the inbox dedup guard. Cut (1) must preserve the reused-seq/served-before memory exactly (corruption = a re-dispatched `hear_trust`). Keep files disjoint from the cell/foam track (which touches `Ghost.svelte`/`Cyto*`/`Vytui`/`vyto_*`/`package.json` only — zero overlap, confirmed).

### LANDED 2026-08-29 (live-runner verified): the monotonic-seq fast path

Implemented in `Ghost/N/Peeroleum.g` (Peeroleum_deliver reliable path + Peeroleum_book_unemit). A frame whose
 `seq > pier.c.hiseq` is provably new (per-pier monotone counter), so it skips BOTH O(depth) scans
  (Peeroleum_served_before + the book_unemit `oai` find) and creates the unemit directly; `seq ≤ hiseq` falls to
   the unchanged slow-path reused-seq guard.  `hiseq` is off-snap `.c`.
- **THE GOTCHA (cost a red MusuNeGrind, then fixed):** plain `inbox.i(usc)` is NOT equivalent to `inbox.oai(usc)`
   for a `%req` — `oai`'s named-req branch (Stuff.svelte.ts:693-697) stamps `req.c.up = host` + `req.c.initialdo = 1`
    AFTER the create, and `i()` skips it, so `req_unemit` throws at `(req.c.up).finish(req)` (undefined) and the
     unemit stalls `done`-but-never-`finished`.  Fix: replicate those two `.c` stamps in the fresh branch.  If you
      ever fast-create another kind of req, remember: `i()` gives you the particle, NOT the req-pump wiring.
- **Verified on the LIVE runner (e747):** MusuNeGrind (the freeze reproducer) GREEN 2/2 (baseline was green, my
   first buggy pass went red 0.18 — the diff is what caught the `.finish` throw); SwarmSpread 5/5 (caveat 1 =
    baseline), SwarmStaple 8/8.  Recommend a couple more MusuNeGrind runs for full N≥5 race confidence.
- **Still open (the deeper cuts, not needed for this freeze):** flow-control stop-ACK (item 5 self-clock window)
   and item 1 gossip-off-lane (other thread's SwarmGot).  This fast path alone should end the 10-20s freeze.
