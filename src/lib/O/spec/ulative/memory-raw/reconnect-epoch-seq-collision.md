---
name: reconnect-epoch-seq-collision
description: "reloaded peer restarts per-Pier seq LOW → finished-unemit collision mute: FIXED BOTH channels 2026-07-19 — swarm via swarm_hi ephemeral era greeting; Lies via ping-borne boot (Lies_pong resets reborn peer) + spine re-ack on collisions; pinned_stable Peeroleum RE-PINNED (authorized); PROVEN by Books PereReborn (collision re-ack + epoch reset, green ×3) + SwarmShare (mirror keying, suggest S&F, hi rebirth reset, green ×3)"
metadata: 
  node_type: memory
  type: project
  originSessionId: 7d992ead-6ef2-4f82-85d7-85669ab9454f
---

**SWARM-CHANNEL FIX SHIPPED 2026-07-19 (friend↔friend tabs — live gen, no re-pin needed):**
 `swarm_hi`, an EPHEMERAL frame kind (added to BOTH Peeroleum_send's no-emit list and
  Peeroleum_deliver's straight-dispatch lane — collision-immune by construction) carrying the
   station era (`w.c.station_era`, minted at standup).  Hearer (Swarm_heard_hi, sealed friends
    only): era CHANGED → `Peeroleum_reset_handshake(route)` (inbox unemit history dropped, %Ud
     kept) + `delete w.c.ra_wanted` (poisoned pull cursors) → reborn peer's reused seqs book
      fresh.  Sent on every socket (re)open (behind the signed hello, same-socket ordering) and
       from Swarm_pulse_all whenever a friend is silent >15s — self-heals from EITHER side.
        Paired with `Swarm_station_routes` (the PRIMARY reload bug: the transport %Pier was
         minted only at invite time — a reloaded tab had friendships but NO route, so it could
          neither send nor hear; now re-minted at standup + every re-open).  The editor↔runner
           channel still rides the send-side ack-gated retry below (pinned_stable, re-pin owed).

**The bug (diagnosed from socklog 2026-07-05, `wormhole/_socklog/*.jsonl`).** A `&remoteWormhole=1` runner that RELOADS restarts its per-Pier outbound seq LOW (6, 7, …). But the editor's Pier for that runner (keyed by pub, REUSED across the reload — the editor didn't reload) still remembers the OLD incarnation's high-water: it has FINISHED `%req:unemit` reqs for seq 6, 7. So the fresh runner's `wormhole_req seq=6` hits `oai({req:'unemit',seq:6,type})` → finds the finished old req → `inbox.do()` skips it (done) → **NO handler dispatch, NO reply, and not even a re-ack**. The read (`RemoteWormholeNav.send`) then dead-waited the full 20s `REQ_TIMEOUT` before re-dispatching, recovering only once the seq organically climbed past the stale high-water (observed: recovered at `seq=14`). User saw "can't download wormhole/Cluster/toc.snap, stuck 16s, not retrying?" then "it got there in the end". This is the reconnect-epoch gap the Peeroleum spec flags under heading 8 (the epoch handshake, NOT built).

**Only the editor-RECEIVES direction fails**: the party that DIDN'T reload keeps the stale high-water; the party that DID reload has a fresh (empty) inbox, so its receive of the peer's monotone-high seqs is fine.

**Wire-confirmed:** the collided 2nd `seq=6` got NEITHER ack NOR reply — on the reliable carrier the editor's `oai({req:'unemit',seq:6,type})` finds the FINISHED old req, `inbox.do()` skips it (done), and the ack is emitted INSIDE `req_unemit` → no processing → no ack. So "no reply" ⇔ "no ack" in this mode.

**Send-side cure SHIPPED (`RemoteWormholeNav.send`, runner-only, HMR-able) — ACK-GATED re-emit:** every `RETRY_MS`=4s, if the last emit's outbox `%emit` is NOT `%acked` (the collision/loss case) re-emit with a FRESH seq (`Pier_next_seq` climbs monotonically past the editor's stale high-water); if it IS acked, the request LANDED+was processed (ack fires right after `req_unemit`, where the reply is also sent) so DON'T re-send (a wasteful double-land, esp. a 400KB bin_write) — just keep waiting for the slow/lost reply. `acked(seq)` mirrors `Peeroleum_take_ack`'s walk: `Peering→Pier→outbox→emit.find(seq)→sc.acked`. `Lies_send_binary_consumer` now RETURNS the seq (was bool) so the nav can watch it. Same corr every attempt; ops idempotent. Turns a 20s mute stall into a ~4-8s LOUD self-heal (`🕳↻ un-acked … re-emitting` / `🕳… acked but no reply … waiting`). No frozen-editor change.

**TRUE root cure STILL OWED (editor-side, FROZEN `p2p/pinned_stable/Peeroleum.go` — needs a re-pin, do NOT do blind):** the editor should reset a Pier's inbox/inseq epoch on a re-hello (a reloaded peer = new incarnation, seqs restart), AND/OR a reused-seq collision must at least RE-ACK instead of silently no-op'ing (right now the stale colliding outbox emit also retx's forever un-acked). Editor rides pinned_stable (frozen; `LiesLies.svelte:381`), runner rides live gen/N — so the failing direction can't be isolate-tested from the runner. A bad re-pin bricks the editor channel. Fits [[fight-back-on-core-changes]] — get explicit go-ahead. Relates to [[socklog-scaffold]] (the capture used to diagnose) + [[relay-r2r-reconnect]].

**DECISION 2026-07-05 (owner, "keep it simpler"):** BANK the shipped send-side retry — it fixes the user-visible problem. The editor re-ack + epoch reset is correct-but-not-urgent and gated behind a re-pin; DEFER it to the next time the spine is re-pinned ANYWAY, and build the PereProof step THEN (its `Lake_reset_arm`, `Peregrination.g:500`, already builds the `inbox unemit seq:7,done:1`+`inseq.last:7` stale state; the missing case is the ASYMMETRIC reconnect where only one side reset). GOTCHA to design for: re-ack ALONE + the shipped ack-gated retry = runner dead-waits (acked-but-no-reply); (i) re-ack-dup and (ii) epoch-reset must COMPOSE. socklog can't substitute for a Book (needs FSA on + it's observational, can't assert). Full write-up folded into `spec/Cluster_spec.md` §3.9 (the liveness architecture still owed); Runner_network.md deleted 2026-07-06.

**channel_up once-guard = OVERSTATED (traced 2026-07-05, [[todo-docs-overstate]] in action):** the relayed "highest-leverage / makes every runner fix land unreliably" claim does NOT hold — the frame handlers are pure dispatch to live `H.Lies_*` methods (`LiesLies.svelte:302-334`), so method-body fixes land on HMR via re-mix REGARDLESS of the `if (channel_up) return` guard (`:219`). The guard blocks ONLY re-STANDUP (new handler TYPE, socket re-open, Pier re-lay). Real failures already handled: Socket_real vanish (P1 reconcile `:214`) + never-deposited/cross-wired gen (loud note `:226`). Residual fix (optional, low-urgency): split the idempotent `on(...)` block from the once-only socket standup. It's Lies-layer (above the mock-carrier spine) so NOT PereProof-labbable. Conclusion folded into `Cluster_spec.md` §3.2b/§3.3. DON'T charge into core boot code for this.

**CONSUMER-SIDE ORDERING LAW (2026-07-28, Sounditron reliability).** The `swarm_hi` self-heal above only
 fires once a peer is silent **>15s** (`Swarm_pulse_all`, Swarm.g ~1294). So ANY code that WAITS on cross-Pier
  presence must give the rescue room: `Sounditron_peer`'s `peer_wait` ceiling was **12s** — `12 < 15`, so a
   briefly-stale-but-online peer could never be rescued before the wait quit → "a peer that IS online reads
    offline / doesn't keep working reliably". Fix (Sounditron.g `Sounditron_peer`): (1) **proactively kick
     `Swarm_hi_all(sw, ident)`** (station-world, self; ephemeral/collision-immune) at the top of the wait so a
      real peer refreshes in one round-trip instead of waiting on the ambient trickle's 15s-quiet phase — the
       wait then settles EARLY; (2) **widen the ceiling past 15** (→20, the file's Swarm_share window
        magnitude). The +ceiling only fully burns on a genuinely-offline/solo run; a peered run settles early
         off the kick. Health-verified on a solo runner (no peer to exercise it) — real win needs two tabs.
  Also live-confirmed here: the pulse driver is a bare `setTimeout` recursion (Sounditron_trickle_look, ~5s
   effective), so a BACKGROUNDED tab's outbound pulse is subject to browser timer throttling — presence can
    stretch past the window while the ws stays connected (no visibilitychange handling anywhere). Deferred
     (riskier, don't blind-touch): adding `'pulse'` to the ephemeral-dispatch table, or blanket-widening the
      freshness windows — both flagged wrong by the reader; the ceiling+kick covers the common case.

----
## merged from inseq-reload-baseline.md

---
name: inseq-reload-baseline
description: a reloaded peer's inbound seq cursor (last:0) gap-buffers the far side's continuing seq forever — "frame RECV'd but runner does nothing"; fixed by cold-cursor baseline adoption in Peeroleum_deliver
metadata:
  node_type: project
  type: project
  originSessionId: 5856ad5e-04a8-49ab-af3f-c1f5d9b62cc5
---

**Symptom:** reload ONLY the runner, finish its ?B= boot Story, then click PereStaple → editor sends
`become_book seq=569/570`, runner's `Tribunal.go 🛰 ws RECV become_book seq=569` logs it, but **no
`📥 become_book recv`** and the runner does nothing. The frame reaches the transport but never the
`Peeroleum_on('become_book')` handler.

**Root cause (Reliable.g inseq + Peeroleum.g deliver):** `Peeroleum_deliver` runs an inbound-seq gate
before booking a frame: `pier.c.inseq = ... || {last:0}` then `inseq_admit(st, seq)`. `inseq_admit`
(Reliable.g:17) buffers any `seq > st.last + 1` as a gap and delivers nothing. A freshly-reloaded
runner has `last:0`, but the **editor never reloaded** so its outbound `Pier_next_seq` kept climbing to
569. So `569 > 0+1` → every frame gap-buffers FOREVER waiting for 1..568 that already came and went.
Asymmetric reload = seq spaces desync; ping/pong/run_phase dodge this (dispatched ephemerally,
Peeroleum.g:297) which is why liveness looked fine while real frames (become_book / rungo / run_result)
silently died. Symmetric fix at the shared deliver → heals both directions (editor reload too).

**Fix (Peeroleum.g ~313, ghost-compiled):** cold-cursor baseline adoption —
`if (pier.c.inseq.last === 0 && seq > 1) { pier.c.inseq = {last: seq-1, buffered: []}; pier.c.held = {} }`
A receiver joining an ongoing stream adopts the first seq it sees as its baseline instead of assuming
the stream starts at 1. `last===0` (not `!inseq`) so it also self-heals an already-poisoned cursor; clears
stale gap-held frames. Safe because the real transport is in-order (no genuine sub-baseline frame to
lose); the adversary Story tests call `inseq_admit` directly, untouched by this deliver-site guard.

**To take effect: RELOAD the runner** (it re-acquires the LIVE spine via CREDULER_GHOSTS on fresh boot —
[[ghost-compile-after-g-round]]; HMR may re-mix the method but the poisoned pier.c.inseq persists in the
current session, and the `last===0` self-heal only fires on the NEXT cold become_book). Ghost-compiled OK
(`d0f210c645771724`), browser-UNVERIFIED. Design TODO (Peeroleum.g:308 already flags it): a real reconnect
should re-sync seq spaces / clear inseq+held — this adoption is the minimal receiver-side version.

The separate [[storyrun-run-record]] work (durable Storyrun:<ident> on w:Lies) is orthogonal observability,
NOT this bug — it makes a future stall self-evident but didn't cause/fix the dead runner.
