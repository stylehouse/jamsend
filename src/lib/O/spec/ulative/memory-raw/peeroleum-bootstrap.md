---
name: peeroleum-bootstrap
description: Peeroleum p2p rewrite — the live handover doc + which .g pieces hold the spine
metadata:
  node_type: memory
  type: project
  originSessionId: 51f86304-44ce-4ef1-9acf-fe500af86b9e
---

Growing `Peeroleum` (particle-only p2p) to retire `Peerily`/`MachPeerily`. The settled
design is `src/lib/O/spec/Peeroleum_spec.md` (LOW-freq); the **live status + next move is
`src/lib/O/spec/Peeroleum_handover.md`** (HIGH-freq) — read the handover first, its
headings shrink as solved. The two are the two-frequency pair (promote an engine-fact up
to the spec with a one-line gravestone).

**The pieces:** `Ghost/N/Peeroleum.g` (envelope / lifecycle / mock carrier),
`Ghost/N/Tribunal.g` (transport-trial carriers + real WS), `Ghost/Story/Peregrination.g`
(the Book + `Lake_witness`; the Book is now named **PereStaple**, the file keeps the old
name). LangTiles can't yet express several spec forms → raw-JS seams flagged `// <`.

**STALE-loader correction:** the old hand-written `test/Peregrination.svelte` loader (that
compiled/included the `.g` then called through) is **GONE**. The runner now **acquires**
pre-built gen — the Creduler loads `CREDULER_GHOSTS` live, gated by `%Creduler_pending` —
so there's no inner Lang/Lies compile in the Run. See [[creduler-runner-architecture]]
(latest), [[reqy-deleted-c-native]], [[lang-compile-cli]], and [[peeroleum-no-libp2p]]
(why the transport stays hand-rolled on PeerJS, not libp2p).

----
## merged from peeroleum-no-libp2p.md

---
name: peeroleum-no-libp2p
description: Evaluated js-libp2p as a Peeroleum transport base and rejected it — stay on PeerJS
metadata: 
  node_type: memory
  type: project
  originSessionId: 33f44d85-df2d-4465-bc3a-6ef1eeda3cbe
---

Considered replacing the hand-rolled Peeroleum transport (and PeerJS) with **js-libp2p** for its swappable-transport + circuit-relay-v2 + identity machinery. **Rejected — staying on PeerJS (`peerjs@1.5.5`, the only p2p dep; no `simple-peer` installed).**

**Why:**
1. **Bundle.** PeerJS = ~30 KB gzip all-in. A minimal libp2p browser-to-browser setup (core + @libp2p/webrtc + noise + yamux + identify + circuit-relay-v2, deduped) realistically lands ~250–350 KB gzip (~700KB–1MB minified) — a net **+~270 KB gzip** for a music app whose stream already works over a PeerJS DataChannel. Parse cost on phones is the real worry, more than download.
2. **Opaque state vs. particles.** libp2p's connection/peer state lives in fat JS objects you can only poll — the exact thing Peeroleum exists to abolish (spec §6: `c.connection` is the *only* `c.*` state). Adopting it means a `%Pier` shim wrapping a libp2p `Connection`, re-surfacing its state as particles anyway.

**How to apply:** if the temptation returns, the answer is no for the *browser* stack. libp2p only earned its 10× bytes on the relay/NAT-fallback machinery — and that's the §5 relay topology, a server-side concern already realised in `src/lib/server/relay.ts`, not something to ship to the browser. Browsers already holepunch via WebRTC ICE/STUN; the only thing enthusiast servers add is the TURN/relay-fallback bytes for NATs ICE can't pierce. See [[peeroleum-bootstrap]].

----
## merged from peeroleum-multicast.md

---
name: peeroleum-multicast
description: "Peeroleum multicast/topics over a claimed @channel — publish once, relay fans out"
metadata: 
  node_type: memory
  type: project
  originSessionId: b8ab9686-3dd3-4168-8290-097a1dd463c8
---

Multicast for [[peeroleum-bootstrap]]: a publisher uploads ONCE to a topic and the relay fans out to
N subscribers (the "phone relaying to 100 listeners, don't upload 100 copies / don't hold 100 addresses"
need). **Settled design = `Peeroleum_spec.md` §18; live status = handover heading M.** Built + **:9091-
VERIFIED** (the human ran it: pile showed owns/mcast/subscribed + the stream_offer inbox round-trip). Now
lives in the **PereProof** Book at **step 29** (`Lake_multicast_arm` → `%witnessed:multicast`), NOT PereStaple
— moved by the [[perestaple-pereproof-split]]. Human floated `to:pub[]` as the sender-side small-fan-out twin
of `@handle` (an account-handle-looking name someone CLAIMS, community/crypto-gated later) — not built yet.

The shape: a `to` starting with **`@`** is a TOPIC (special case beside a peer `pub`). Spine calls in
`Ghost/N/Peeroleum.g`: `Peeroleum_claim`/`_subscribe`/`_publish`/`_offer_stream` + the `@`-branch atop
`Peeroleum_deliver`. **Publish is fire-and-forget** — NO outbox emit, NO ack (no 100-ack storm), per-CHANNEL
seq (not the per-Pier [[o-query-wildcards-on-1]] inseq). Handshake/trust stay 1:1; only the BULK goes
multicast, handed over via a `stream_offer` (a Pier hands a stream POINTER → peer subscribes). **`@name`
must be CLAIMED** (first-come now, community/crypto gate later; soft enforcement, trust-everything v1).
Relay (`relay.ts`): subscribe = `bind(@channel, ws)`, so `deliverLocal` (already a Set fan-out) does the
multiplication with NO routing change; `claims` map + `handleControl`. **One instance only — topic is
LOCAL-only, NOT bridged** (two-instance fan-out penciled). `Socket_real` got claim/subscribe control frames.

Build loop used: edit `.g` → `scripts/LocalGen.spec.ts` (GFILES=…) writes real gen `.go` headless →
`scripts/CredRunner.spec.ts` (BOOK=PereStaple) drives + piles to `/tmp/Story_cli/PereStaple/` → grep the
NNN.got.snap for the witness. 51/54 vs locked fixtures (the 3 misses = step-3 quiescence residual + new
un-recorded 53/54). NEXT: Accept/Resnapture 53–54, browser-verify on :9091, crypto claim, per-channel
NACK, cross-relay fan-out. First real customer = music slice-3 radiostock fan-out ([[music-cluster-kickoff]]).

----
## merged from peeroleum-swarm-refactor.md

---
name: peeroleum-swarm-refactor
description: "PereStaple refactored to ONE w:PereStaple with Peering+Pier as typed serial-reqs and per-Peering carriers; spine routes by identity; compile-clean, :9091-owed"
metadata: 
  node_type: memory
  type: project
  originSessionId: 2a8a4768-8f07-4903-bc12-3ba73061c0c9
---

PereStaple's per-peer `A:<Name>/w:Peeroleum` worlds are GONE — every node now lives under ONE `w:PereStaple` as a `%Peering,name,req` (a typed serial-req, new do_fn `req_Peering` in Peeroleum.g) holding its one `%Pier,pub,req` and its OWN mock carrier on the Peering's `%active_transport`. This is the production shape (a node owns many per-remote channels) forced into the test.

**Why:** the human asked to collapse the six per-peer worlds into one `w:PereStaple` "with tons of req,Pier,pub inside it," and to kill the ~30-line per-side `A:/w:/Peering/c.up/transport/arm/pair` setup boilerplate. The carrier-merge fear that had kept Alice/Bob as separate worlds ([[aw-req-level-uniformity]]) was MOOT — inbox/outbox/seq/inseq already lived on the Pier; only the carrier + the one-Pier-per-`w` lookup were `w`-bound.

**How to apply (mechanism):**
- Spine `Peeroleum.g`: `Peeroleum_route(w,h,mine)` resolves `{peering,pier}` by identity (`from`→Peering on send, `to`→Peering on deliver; other end = Pier's `pub`); `Peeroleum_carrier(peering,w)` reads the Peering's carrier, falls back to `w`'s. **ONE Peering ⇒ short-circuit** (`length===1`→use it), so a single-identity `w` (production live channel, Tyrant, the Relay Brink reading `active_transport` off `w`) is BEHAVIOUR-IDENTICAL — that's why no Lies/svelte edits were needed. `retx_policy` moved per-Peering (stall test tightens just Kim's link); `retx_tick`+`on` registry stay per-`w`.
- The level-uniform payoff: Peering-as-req means `w:PereStaple.do()` cascades Peering→Pier→handshake (supersedes heading-3's "re-pump must live in the wrangler"). `Lake_pump_handshakes` KEPT as belt-and-braces. `oai` wires `Peering.c.up=w` + `Pier.c.up=Peering` (no hand-stamp).
- Book `Peregrination.g`: a peer is `Lake_peer(w,name,pub)`, a link is `Lake_link(w,a,b)`. Whittle arms ONCE on `w:PereStaple`. `w:PereStaple`→`w:PereStaple`.
- `Tribunal.g`: the 6 TEST trial fns (PeerJS/Socket/pair/hand/fall/reputation) take a Peering; production `Socket_real`/`Tribunal_activate_websocket` stay on `w`. `Reliable.g` UNTOUCHED.

**GOTCHA (cost a debug round):** the per-beat Book handler is dispatched BY THE W-NAME (`PereStaple`↔`w:PereStaple`, `Story`↔`w:Story`), so the test world MUST keep the name `PereStaple` — I renamed it `w:Peers` and the whole Book silently never ran (empty `w`, no `%req:wrangle`, no error). Mount peer flocks INSIDE `w:PereStaple`. A separate `w:*` is only warranted for stuff thinking at a DIFFERENT cadence (its own reqdo heartbeat entry — w = a frequency boundary, per [[aw-req-level-uniformity]]).

**Status: PROVEN GREEN on :9091 (2026-06-25, Peeroleum @ 50037abb / Tribunal @ 66b6bbb6 / Peregrination.go @ 349080831f4af54d).** One run witnessed the WHOLE arc: `req:handshake,finished` + `Ud` on both Piers, hello+trust said+acked+heard both ways, `got_binary` (NO `faulty`), and all eight stamps `witnessed:step_2,step_3,step_4,step_5,step_6,send_binary,heal,stall` (heal = ivy noop dropped→retx→jon got it; stall = kim noop blackholed→`%stalled,reason:no-ack` latched). Clean structure: one `w:PereStaple`, six Peering/Pier flocks, no per-side actors, no `seemingly`/`p2paddy` cruft. Two debug rounds got here (both above): the w-name handler GOTCHA, then the auto-async REAL BUG. Story_cli can't drive PereStaple's Creduler wrangler headless (ran stale gen, wrangler doesn't fire that boot) — verify on :9091. REAL BUG (cost two runs; c.up was a red herring): `Lake_peer` got AUTO-ASYNC'd by the compiler because the mock port's `send` closure carries `await this.partner?.recv(frame)` — the auto-async heuristic catches a nested-closure `await` and promotes the WHOLE method. So `Lake_peer` returns a PROMISE; `Lake_link` called it WITHOUT await → `pa`/`pb` were Promises → `Lake_port(Promise)` read `Promise.c.up` (undefined) → threw → the link never paired → mock never carried → handshake said hello into the void; heal/stall noops never sent (websocket worked only because `Tribunal_pair_websocket` pairs the Peering directly). `Lake_peer`'s BODY still runs synchronously (no top-level await) so the Peerings/Piers existed — only the pairing died. FIX: `await` the cascade — `async Lake_link` awaits `Lake_peer`, `async Lake_sides_up` awaits `Lake_link`, `Lake_drive` step 2 `await &Lake_sides_up`, heal/stall await `Lake_link`. Also kept the defensive `peering.c.up=w`+`pier.c.up=peering` stamps in `Lake_peer` (still correct — oai's c.up on a typed serial-req is deferred; `Lake_port` reads it at setup). GENERAL GOTCHA → [[g-authoring-gotchas]]: a method whose body has a closure with `await` is silently auto-async'd; its return becomes a Promise — await it. NEXT = Accept/Resnapture steps 2–15 to lock the new snaps as the regression gate (working tree uncommitted for the human). Live status in `spec/Peeroleum_handover.md`. Related: [[peeroleum-bootstrap]], [[oai-req-mainkey-only]], [[creduler-runner-architecture]], [[ghost-compile-after-g-round]].

----
## merged from peeroleum-reliability-arc.md

---
name: peeroleum-reliability-arc
description: "the Peeroleum network-healing / reliability arc — build order (adversarial carrier + logical clock → inbound seq discipline → retransmit → spine liveness → Tribunal fallback), what's DONE, and the headless-pure-primitive + thin-.g-wiring pattern"
metadata: 
  node_type: memory
  type: project
  originSessionId: a3077b3c-d41a-4880-939d-0bb7c8c747ac
---

Reliability = **absence-handling**, and absence is the **ambient sweep's** job (reqdo_sweep walking Piers), NOT reqyoncile/event-driven. Happy path (frame arrived) stays event-driven via `req_unemit`/`inbox.do()`; sad path (it didn't) is the sweep finding the overdue Pier. The `%outbox/emit` ledger is **a retransmit queue with no retransmitter** — the engine's wires aren't connected yet.

**Build order** (from the advisor reframe, endorsed):
0. **Traps (gate everything):** a deterministic ADVERSARIAL carrier (you can't test absence with the perfect mock that never drops) + a **logical clock** for deadlines (wall-clock `Date.now()` breaks Story replay — count **sweep-passes / carrier ticks**, never ms).
1. **Inbound seq discipline** (correctness floor) — dedup + gap-buffer; MUST precede retransmit or retries corrupt. = heading-6 "corruption".
2. **Retransmit** — deadline+tries on each `%outbox/emit`; the sweep re-sends overdue (deadline in sweep-passes).
3. **Spine liveness** — per-Pier `last_heard` in the sweep → stamp Pier dead → the presence (A/w) re-dials.
4. **Tribunal fallback** — transport-agnostic; seq is per-Pier so a carrier swap doesn't reset the stream.

**Pattern that works here:** build each piece as a PURE `.ts` primitive + a headless vitest spec FIRST (Story_cli boot can't run wranglers — Creduler doesn't load there — so a Book needs :9091; pure logic doesn't). Then a THIN `.g` wiring (ghost-compile). 

**DONE (this session):**
- Non-pinned watchdog: `LiesLies` `Lies_keepalive` is frame-agnostic (`Lies_heard` via the `on` wrapper stamps `last_heard` on every consumer frame) + three-state LIVE/SLUGGISH/DEAD (reconnect only on DEAD), on an INDEPENDENT `setInterval` (not riding think). `.svelte`→HMR, both roles, no re-pin.
- `relay.ts`: the outbound `peerLink` r2r bridge now gets the keepalive ping (was only `wss.clients`). Server → needs dev-server restart.
- `src/lib/O/peeroleum_lossy.ts` (+ `scripts/LossyCarrier.spec.ts`, 5/5) — adversarial carrier: seeded drop/dup/delay(=reorder) by seq, logical-tick clock.
- `src/lib/O/peeroleum_inseq.ts` (+ `scripts/InSeq.spec.ts`, 6/6) — per-Pier `last`+`buffered`: dedup (incl. delivered-then-culled, since `last` persists) + gap-buffer-and-drain. Integration test: lossy dup+reorder → inseq → clean stream.

**DONE (2026-06-24 continuation):** inseq WIRED into `Peeroleum_deliver`, then the human steered: **fold the `.ts` primitives INTO `.g`, no scattered files** ([[g-over-scattered-ts]]). End state:
- The 3 `.ts` (lossy/inseq/retransmit) + their 3 specs are **DELETED**; logic folded into **ONE** ghost, three regions:
  - **`Ghost/N/Reliable.g`** — `inseq_admit` (wired in `Peeroleum_deliver` via `this.inseq_admit`), `retx_delay`+`retx_due` (WIRED, see next para), and the **adversary** `lossy_decide`/`make_lossy_partner` (a deterministic lossy carrier, dormant test scaffolding). The adversary was briefly its own `Lossy.g`, but the human steered "Lossy could just be a region" — a separate ghost earns no keep for dormant scaffolding, so it folded to the bottom region here and `Lossy.g`/`Lossy.go`/its CREDULER_GHOSTS+Net/Easy+FlockCompile entries were all removed. In `CREDULER_GHOSTS` + Net/Easy; **gen ghost-compiled live** (`gen/N/Reliable.go @ 93e9371…`; FlockCompile headless ✓ all 4 .g). Behaviour :9091-owed.
  - **Net/Easy is a PRISTINE landmark space**, NOT a per-method index — the human: "we really don't need most of these Easy Points if they're just to every method." Curated each `What:` to its Doc + 1–2 front-door Points (the Book to run, the ghost's entry, the named concept); the compiler already indexes every symbol. See [[g-over-scattered-ts]].
  - **All `.g` comments re-cut to the indent-as-branch policy** ([[comment-style]]): each line is its own sentence, a deeper line is *inside* (a consequence|gotcha of) the one above — never a +1-space-per-wrapped-line staircase. The old Reliable/Lossy headers were exactly that staircase smell.
- inseq behaviour unchanged from the wire: contiguous→book+drain (pass-through on clean mock); delivered-dup (`seq ≤ pier.c.inseq.last`)→re-ack ONLY; gap/buffered-dup→hold off-snap on `pier.c.held`, NO ack (held=unverified). `< protocol reset (heading 8) rewinding Pier_next_seq must clear pier.c.inseq/held`.

**retransmit now WIRED** (2026-06-24, ghost-compiled live, DORMANT-safe, active path :9091-owed): `Peeroleum_send` stashes `emit.c.frame`/`sent_tick`/`attempts`; `Peeroleum_retx_sweep(w)` rides the `Peeroleum_arm_whittle` Runstepped boundary (before the cull), advances `w.c.retx_tick`, `retx_due` → re-hand `emit.c.frame` to the live transport (same seq, peer's inseq dedups), bump attempts + `%resent`; exhausted → `%dead`. Dormant on clean streams (emits ack within the step → skipped). `< %dead only marks — faulty/liveness/reset is heading 8/9, dead emits not culled yet (adversarial-only leak)`.

**adversarial verifier BUILT (2026-06-25, ghost-compiled live, browser-UNVERIFIED).** `Peregrination.g` **step 8 = `Lake_heal_arm`**: stands up a FRESH isolated pair (Ivy/Jon) on a clean mock carrier, slips the adversary onto the Ivy→Jon path (`make_lossy_partner, {drop:[s]}`), sends one `noop` seq s. A noop is admitted+acked pre-handshake (`req_unemit`: `ok = !(pre_ud && type!=hello && type!=noop)`), so no handshake needed — isolated + fresh-seq=1 by design. The drop leaves Ivy's emit un-acked → `Peeroleum_retx_sweep` re-sends at the step boundaries (`retx_delay(1)=2` logical ticks, so the heal plays out over steps 9-10) → resend passes the spent drop → Jon delivers+acks → emit `%acked`. `Lake_witness` stamps **`%witnessed:heal`** on three cull-surviving readings: the adversary's drop-log (`IvyPier.c.lossy.dropped`), Jon HANDLED it (`%done` unemit or `%recent`), Ivy's emit `%acked` (live or `%recent`). toc.snap got `step=8..11` (lie diges). **Carrier change:** `drop` is now drop-ONCE (transient → retransmit HEALS; `seen[]` counts transits) + a new `blackhole` knob = drop-every-transit (the permanent-fault/dead case); `dropped[]` log exposed.

**Gotcha (2026-06-25):** `gen/Story/Peregrination.go` got overwritten with Peeroleum's compiled output shortly after a ghost-compile. I blamed batched ghost-compile — WRONG (human corrected): its compile source is fresh-disk-decoupled per-path (`Lang_compile_source_state`) + per-ticket independent, so it can't cross. Cause is the live editor's OWN dock state (active session). Fix that worked: recompile the one file + verify the gen has its OWN methods (`Run_A_*`/`Lake_*`, not `Peeroleum_*`). See [[g-authoring-gotchas]] pt 4.

**TRANSPORT-GATING LANDED — the editor↔runner FIX (2026-06-25, ghost-compiled live `Peeroleum.go @ d1930f…`).** Root defect (other agent, confirmed in code): `Peeroleum_send_consumer` (`Peeroleum.g:203`) seqs EVERY consumer frame incl. ephemerals (ping/pong/run_phase), but `Peeroleum_deliver` routes ephemerals to handlers BEFORE the inseq gate → each ephemeral burns a `Pier_next_seq` inseq never books → phantom gap → the next booked frame gap-buffers forever; the 5s keepalive guarantees a hole between any two = **"only the first `rungo` lands"** (the broken dir is editor→runner: pinned editor seqs ephemerals, live runner gap-buffers). FIX = **transport-gating** (the human's call, option 4): the connection advertises `reliable` (default true via `conn?.reliable !== false`); a reliable+ordered carrier (ws relay + clean mock) books STRAIGHT, skips inseq; inseq+retransmit engage ONLY on `reliable:false` (the adversary mock today, webrtc datachannel tomorrow). **Receiver-side → fixes the pinned-editor direction without un-fossilizing.** Correct LAYERING, not a hack: running an ordering layer over an already-ordered carrier was the redundancy that bit. Also: **reverted the cold-start baseline** (`Peeroleum.g:321` `last===0&&seq>1` re-baseline) — dead weight under gating (that reload wedge was on the reliable relay, which no longer sequences); inseq's deliver site is clean again. **A held frame is now LOUD** (`console.warn` on every gap-hold) — the wedge was invisible because liveness rides ephemerals that bypass inseq. Adversary opts out (`Ivyport/Jonport.reliable=false` in `Lake_heal_arm`) so Reliable.g stays fully exercised. **SIDE EFFECT:** the clean Alice/Bob mock now bypasses inseq too → the trial-probe coupling (steps 5-7 gap-buffering seq5 behind the lost webrtc seq4) DISSOLVES → those steps revert to CLEAN → **re-record 5-7 again**. Promoting live→pinned_stable would NOT fix this (both ends gain inseq → symmetric wedge). **DEFERRED to the epoch handshake (heading 8):** reconnect-replay dedup on a reliable carrier + real lossy-reconnect resync; mark webrtc `reliable:false` when the datachannel goes live. Verify on :9091 (editor↔runner: every rungo lands; clean PereStaple still green).

**STALL RUNG BUILT (2026-06-25, ghost-compiled live, browser-UNVERIFIED).** Closed the two holes the retransmit left (`%dead` only marked + a dead emit re-died every sweep = the leak). `Peeroleum_retx_sweep` dead-branch latches per-Pier **`%stalled`** container holding the dead emit (`stalled/emit,type,seq,reason:no-ack`, parallel to %faulty/%unemit; outbound carrier-down signal, inbound-silence half stays LiesLies keepalive) → **drops the spent emit** (else re-enters `verdict.dead` forever). **PROVEN GREEN on :9091** (step-13 snap: `Kim/Pier/stalled/emit,…,reason:no-ack`, emit culled, `witnessed:stall` + `witnessed:heal`). **FREEZE scare + REAL cause:** an intermediate run froze (Kim stuck `resent=2` steps 13/14/15, no %stalled) — the retx/cull heartbeat is a self-re-pushing `Runstepped` rearm (`arm_whittle`), so ANY throw in retx_sweep skips `rearm()` → that w **stops sweeping forever**. I first blamed the nested create in a `Peeroleum_mark_stalled` helper — WRONG (next run ran it green); real cause = **HMR desync** (retx_sweep hot-updated before the new method deposited → "not a function"). Fix kept both robustnesses: **inline** the stamp (no separate method → nothing to desync) + **try/catch** the dead branch surfacing a residual throw IN THE SNAP (`%stall_err,msg`). Latent twin: `rollup_faulty`'s nested `faulty.i()` (untested, heading 6). **Lesson: a long-lived runner can keep a STALE gen after ghost-compile — RELOAD it before trusting a run (nested-vs-flat snap shape caught it).** `%stalled` is LATCHED not rebuilt-each-boundary like `%faulty` (emit gone, nothing to rebuild); only reset_handshake (heading 8) clears it. Retransmit **policy is now per-w** (`w.c.retx_policy`, default production `{base:2,factor:2,max_attempts:5,cap:16}`). Verifier = `Peregrination.g` step 11 **`Lake_stall_arm`** (heal's twin): fresh Kim/Lee pair, **`blackhole`** carrier (every transit lost), tight `{base:1,factor:1,max_attempts:2,cap:1}` so death lands in 2 ticks (prod ~46), one noop → emit dies → `%stalled`; `Lake_witness` stamps **`%witnessed:stall`** on dropped≥2 + latched `%stalled`. Placed at step 11 (after heal settles @10) so the heal gate (8–10) stays byte-identical. **:9091 PROVEN thru the resend** (step-13 run: Kim emit `sent,resent=2`, heal still green) — death needed one more boundary: the **arm-lag** (`arm_whittle` registered mid-step misses the first boundary drain, like the heal pair) spreads the two retx ticks over send@11/resend@13/exhaust@14, so toc.snap grew to step=15 (witnessed @14). Backoff replay-confirmed headless (death @tick2, 2 transits). **The re-dial itself** (mark active %transport faulty → Tribunal re-trials a carrier) is the **heading 9/10 seam** — only the signal is raised here.

**RELIABILITY THREAD CLOSED HEADLESS (2026-06-25) — silence + re-dial + Tribunal fallback built & CredRunner-verified, browser-owed.** The three remaining rungs, all proven headless (no :9091):
- **Spine inbound-silence liveness** (`Peeroleum.g`): `Peeroleum_deliver` stamps a LOGICAL-tick `pier.c.last_heard_tick` on EVERY inbound frame (acks included — closes ack-blindness); `Peeroleum_liveness_sweep(w)` (armed in `arm_whittle` after retx_sweep, before the cull) latches **`%silent,reason:no-inbound,since=N`** — the inbound twin of `%stalled` (no outbound to stall on). **OPT-IN:** engages only where a Peering's `retx_policy.silence_dead` is set, so it's provably dormant on every quiet peer of a run (production's inbound-silence detector stays the wall-clock keepalive; this logical-tick path is the replay-safe primitive a Story arms). Gate: only a Pier that HAS heard (last_heard set) can "go silent". `arm_whittle` rearm now **try/caught** so a sweep throw can't freeze the heartbeat (the documented freeze-scare).
- **Re-dial + Tribunal fallback** (`Tribunal.g`): `Tribunal_redial(peering,reason)` = autonomous twin of the step-paced `Tribunal_fall_to_websocket` — demote active `%transport` `%faulty,reason`, repoint `%active_transport` at the next non-faulty carrier (webrtc>websocket>mock), `Peeroleum_reset_handshake` each Pier (spec §9: drop protocol/outbox/inbox/faulty/%stalled/%silent/req:handshake + c.connection/held/last_heard, **keep %Ud**, KEEP c.seq/inseq for continuity = no epoch needed), leave a `%redialed:<type>,was,reason` breadcrumb. `Tribunal_redial_sweep(w)` scans **auto_redial** Peerings (opt-in, so it never disturbs the stall verifier's witnessed `%stalled`) for a `%stalled`|`%silent` signal and re-dials once; reason reaches through to the dead-emit child (`no-ack`) / inline (`no-inbound`). Spine DETECTS, Tribunal REASSIGNS (production: LiesLies keepalive drives it off the same signals). Driven each pass by the wrangler (`&Tribunal_redial_sweep,w` in `Lake_drive`).
- **Verifiers** (`Peregrination.g`): **step 16 `Lake_silence_arm`** (fresh Mae/Ned, `silence_dead:2`, one noop → Mae hears the ack then quiet → `%silent` latches ~step 18 → `%witnessed:silence`) + **step 19 `Lake_redial_arm`** (fresh Ola/Pam, both carriers like the trial, webrtc black-hole active + tight policy + `auto_redial`, probe stalls → autonomous fall to websocket ~step 21 → webrtc `%faulty` + active websocket + `%redialed` → `%witnessed:redial`). toc.snap grew step=16..24 (lie diges). **Both witnesses + the existing 8 fire headless; the 2–15 gate stays byte-identical (13/15, surprises 1,3).** Fixtures 016–024.snap deliberately NOT recorded (headless≠browser per Tier 1 — let a :9091/ACCEPT pass lock them; `since=N`/seq may want a spay rule).
- **THE NEW LEVERAGE — browserless compile loop.** `npm run ghost-compile` only sends a ticket to a LIVE editor (no local compile — so it "doesn't work" with no browser). Built **`scripts/LocalGen.spec.ts`**: boots the FlockCompile machine, runs each `.g` through `Lang_compile_dock`, reads `dock/Compile/Output.source`, writes the REAL `src/lib/gen/**/*.go` — **byte-identical to ghost-compile's output** (proven on 4 unchanged files). `GFILES="a.g b.g" vitest … LocalGen.spec.ts` (CHECK=1 = diff-only). This + CredRunner = full edit→compile→run→witness loop, ZERO browser, for the acquire-spine Books. **HOST-CONCURRENCY:** the human edits on the host mid-session — `Reliable.g` gained an uncommitted `p.cap ?? Infinity`; LocalGen faithfully recompiled `Reliable.go` to match. Re-check working tree after surprises ([[host-commits-midsession]]).

**CORRECTNESS-FLOOR PROOFS — 7 isolated headless verifiers (2026-06-25, CredRunner-confirmed, browser-owed).** The user's doctrine: "these should be the simple proofs first" (each feature in isolation; combining-features-tests-complexly is a LATER phase) + "go as far and add as many tests and confirm them yourself as you can." Built on the LocalGen+CredRunner loop — each a fresh isolated `Lake_*_arm` step + a structural `Lake_witness` stamp, so the 2–15 gate stays byte-identical (still 13/15, surprises 1,3). PereStaple grew to **step=38** (toc lie diges 25–38); ALL 17 witnesses fire headless (the 10 prior + these 7 concepts). Each proof:
- **step 25 corruption → %faulty** (heading 6, the named NEXT): Cad sends a noop with a real 4-byte buffer but a deliberately-wrong `body_hash`; Cob recomputes the sha256, mismatch → `%error:bad-body-hash` → `rollup_faulty` latches `%faulty/unemit,error:bad-body-hash`. A noop carries it (admitted pre-Ud) so NO handshake needed — the integrity check runs regardless. The errored unemit is NEVER culled (only `done` ones cull), so `%faulty` (rebuilt each boundary) stays latched. `witnessed:corruption`.
- **step 34 pre-Ud admission gate** (spec §7.3): Val never handshakes (no `%Ud`); Uma sends a CONSUMER-type frame (`test_preud`) → `req_unemit` refuses it `reason:pre-Ud` → `%faulty/unemit,error:pre-Ud`. Proves a peer can't push app frames before proving identity (only hello|noop admitted pre-Ud). `witnessed:preud`.
- **step 27 inseq dedup** (within-window): Fin→Gus on a LOSSY link (`reliable:false` so inseq engages); `%Ud` stamped on Gus + a counting consumer handler; adversary `dup:[s]` delivers seq s TWICE in one transit → inseq collapses the second (`seq≤last`→re-ack only). Airtight: adversary `duped`-log proves two arrived, `dup_count===1` proves one dispatched. (Added a `duped` log to `make_lossy_partner` paralleling `dropped` — test scaffolding.) `witnessed:dedup`.
- **step 36/38 dedup-survives-the-cull** (Reliable.g "last persists" — closes the gap a bare oai-by-seq leaves): Sib→Tom (lossy); one `test_cull` handled once + culled to `%recent` at the step-36 boundary (live req GONE); step-38 REPLAY of the same frame (direct `Peeroleum_deliver`, exactly as recv would) → `seq≤last` STILL caught (cursor on `pier.c.inseq`, off-snap, persists past the cull) → re-ack only, `cull_count` stays 1. `witnessed:dedup_cull`.
- **step 29/30 inseq reorder / gap-buffer-and-drain**: Hal→Ida (lossy); allocate two consecutive seqs, send the SECOND first → s2 arrives ahead, inseq buffers it (`pier.c.held`, no ack, last unmoved) — `witnessed:reorder_held` caught DURING step 29; step 30 sends s1 → fills the gap → inseq drains BOTH in seq order (Ida's `recent` shows unemit seq then unemit=2,seq=2). `witnessed:reorder` (gated on reorder_held so the gap was provably real). No adversary needed — out-of-order SEND order suffices; default retx policy (base 2) so the held s2's emit isn't resent in the 1-tick gap.
- **step 32 reset_handshake continuity** (heading 8, spec §9): a single peer Rex built with a FULL connection state (%Ud, protocol, outbox, inbox, %faulty, %stalled, %silent, the handshake %req, c.seq=9/c.inseq.last=7, c.connection/held/last_heard); one `Peeroleum_reset_handshake` DROPS every connection fact + clears the dead `.c` but KEEPS `%Ud` + the seq cursors — continuity across a reconnect is what dodges the epoch handshake a seq-reset would force on BOTH sides. Synthetic state via plain `.i` (oai on a req mainkey would run req_handshake + dirty the outbox); set `c.connection` so its clear-clause isn't vacuous. `witnessed:reset`.

**COMBINATORY BRAIDS — the LATER phase the user flagged, now started (2026-06-25, CredRunner-confirmed, browser-owed). FOUND + FIXED A REAL SPINE BUG.** "we will go around later combining features and checking they test complexly as well huh?" — after the isolated floor (25–38), braid several knobs onto ONE stream so they must hold TOGETHER. PereStaple grew to **step=52**; **21 witnesses** fire headless (17 prior + 4 braids); 2–15 gate byte-identical (13/15, surprises 1,3). Each is a fresh isolated `Lake_*` link, opt-in, non-disruptive:
- **step 40 storm** = `heal ∘ dedup ∘ reorder` on one stream: Que→Ros (lossy), `{drop:[s2], dup:[s3]}` over 4 consecutive seqs. s1 lands; s2 lost → s3,s4 arrive AHEAD and gap-buffer (the **drop MAKES the reorder** — no separate delay knob needed), the s3 dups collapse in the buffer; retx heals s2 → drains s3,s4 in order. End: `inseq.last===s4` + every seq's handler ran exactly once (`storm_counts[s]===1` for all 4). Witnessed across blank steps 41–43 (retx rides Runstepped, like the lone heal). `witnessed:storm`.
- **step 44 corrupt-stream** = `verify ∘ ordering`: Wyn→Xan (lossy), s1 good / s2 bad-body_hash / s3 good. inseq ADMITS s2 (cursor advances — a corrupt frame BURNS its slot, not re-requested) but req_unemit's sha256 rejects it → `%faulty,bad-body-hash`, handler never runs for s2; s3 dispatches normally. One bad frame does NOT wedge the good ones behind it. `witnessed:corrupt_stream`.
- **step 46/48 rededup** = `reset ∘ dedup` (the SECURITY consequence the lone reset proof only implied): Yul→Zoe (lossy), deliver s1 once; then `reset_handshake(Zoe)` (the re-dial) KEEPS `c.inseq`+`%Ud`; replay the OLD frame → `seq≤last` caught by the surviving cursor → no second dispatch (`rededup_count` stays 1). The reconnect does NOT re-open the replay window. `c.rededup_count` lives off-snap so it survives the reset (like inseq). `witnessed:rededup`.
- **step 50 storm_redial** = `reset ∘ dedup ∘ ordering`, a re-dial WHILE a gap is open — **FOUND A REAL BUG.** `reset_handshake` dropped `c.held` (the gap-buffered FRAMES) but kept `c.inseq` whole, incl. `c.inseq.buffered` (the seq NUMBERS of those frames). After a reset mid-gap, inseq believed those seqs were ready → the re-supplied tail drained the GHOST slots (no frame → silently skipped) then deduped the real re-sends = **data lost on a reconnect landing mid-gap.** The lone reset proof (step 32) built `buffered:[]` empty so never saw it; the braid did. **FIX (Peeroleum.g `reset_handshake`):** `if (pier.c.inseq) pier.c.inseq.buffered = []` with the `delete pier.c.held` (two halves of one fact), keep only cursor `last`. Driven DETERMINISTICALLY via awaited `Peeroleum_deliver` (mock's `Peeroleum_send` is post_do-deferred → racy to orchestrate a precise mid-gap reset; retx-redelivery already proven by heal/storm, so isolate the reset interaction synchronously). Witness: `sr_held_before>=2` (gap real) ∧ `sr_held_after===0` (reset emptied it) ∧ recovered (last>=s4) ∧ all 4 counts===1. **SPINE CHANGE — re-pin `pinned_stable/N/Peeroleum.go` + browser-verify editor↔runner.**
- KEY: a `reliable:false` carrier survives `reset_handshake` — the flag rides `peering.active_transport.c.connection`, not the Pier, so the replay's deliver still engages inseq. Behaviour-space map (NOT-yet-braided: corruption-during-redial, silence+retransmit race, multi-peer crossfire) + the real-app connect (runner↔editor v2 Story, Trust+Features port = float a `req**` under `w:PereStaple` NOT an `A:`, real-relay = ws headless / webrtc browser-only) all parked in `spec/Peeroleum_handover.md` §"Combinatory phase + behaviour-space map".

**NEXT:** **Tier 3 two-origin transport** is the one thing CredRunner can't prove — a REAL silent socket / dropped relay / partition (the mock proved the LOGIC; only the wire proves the TRANSPORT). Then re-record steps 11–24 on :9091 (heal gate 8–10 unchanged) + the epoch handshake (heading 8 reconnect-replay). Parked: held-too-long alarm. See `spec/Peeroleum_handover.md`, [[creduler-runner-architecture]], [[headless-creduler-runner]], [[ghost-compile-after-g-round]].

----
## merged from relay-r2r-reconnect.md

---
name: relay-r2r-reconnect
description: "the r2r relay↔relay bridge now auto-reconnects server-side (was: stranded until a manual staging restart); how the bridge is dialed and where the backoff loop lives"
metadata: 
  node_type: memory
  type: project
  originSessionId: 65e20774-d6b8-435a-a4a1-7d69fb977e72
---

`src/lib/server/relay.ts` — the editor↔runner **r2r bridge is asymmetric**: the RUNNER relay (:9091) dials the EDITOR/staging relay (:9092) via `dialEditor()`; the editor end is **passive** (only accepts an inbound `?r2r=1` socket, never dials — it can't, it doesn't know the runner's addr). So the runner is the only side that can re-establish the link.

**The bug (fixed 2026-06-26):** a dropped/half-open bridge USED to wait for a re-trigger to re-dial — `dialEditor` fired only on the first `become(runner)` or a runner **browser (re)connect** (relay.ts ~347); `link.on('close'|'error')` and the heartbeat's half-open terminate just **nulled `peerLink` and stopped**. So an editor/staging restart with the runner's tabs left open stranded the bridge (every editor↔runner envelope dropped at `routeFromBrowser`) until something re-triggered it — **bouncing staging by hand WAS the missing trigger**, not a real fix.

**The fix = server twin of `Socket_real`'s onclose loop** (Tribunal.g): added `scheduleRedial(why)` — backoff `min(15s, 500·2^tries)+jitter`, one pending timer, no-op once `peerLink` is OPEN or the relay is `close()`d, gated `role==='runner'` (editor stays passive). Wired into all four "bridge down" sites: `link.on('close')`, `link.on('error')`, the 5s connect watchdog (black-hole connect), and the heartbeat half-open terminate. `redialTries` resets on a clean `open`; `closed` flag + `clearTimeout` in `handle.close()`. The old browser-reconnect re-dial stays as belt-and-suspenders (composes via the OPEN/`redialTimer` guards).

**Proof:** `scripts/relay-test.ts` (headless node + `ws`, no browser — `npx vite-node scripts/relay-test.ts`) now has a reconnect scenario: bring the bridge up, `editor.close()`+`editorSrv.close()` while BOB (runner browser) stays connected, re-listen a fresh editor relay on the SAME port (`listenOn`), assert `runner.peerReady` heals on its own + cross-routing resumes both ways. 18/18 green. This is the regression gate the staging-restart bug slipped through (the old test only proved the bridge *forms*, never that it *recovers*).

Browser-side relay socket (`Tribunal.g` `Socket_real`) already had its own auto-reconnect — this fix brings the SERVER bridge up to the same standard. Uncommitted (working tree; human commits). See [[peeroleum-bootstrap]].

----
## merged from perestaple-pereproof-split.md

---
name: perestaple-pereproof-split
description: PereStaple split into two parallel Books — PereStaple (liveness 2-22) + PereProof (correctness 2-30)
metadata: 
  node_type: memory
  type: project
  originSessionId: b8ab9686-3dd3-4168-8290-097a1dd463c8
---

PereStaple grew to 54 linear steps; split into TWO Books so they run in PARALLEL → "all green" in ~half the
wall-clock (human wanted ~30 steps each). Both live in the SAME `Ghost/Story/Peregrination.g` (already a
CREDULER_GHOST — no manifest change); the `Lake_*` ARM methods are SHARED, only the dispatch + witness split.

- **PereStaple = LIVENESS arc (steps 2-22):** spine/trial/binary/heal/stall/silence/redial. Dispatch
  `Lake_drive`, witness `Lake_witness`. Fixtures `001-022.snap` UNCHANGED by the split (proof peers only ever
  appeared at step 25+, so 2-22 byte-identical) — kept, no re-record. CredRunner 21/22 (step-3 quiescence
  residual the lone miss). The old `023-054.snap` DELETED.
- **PereProof = CORRECTNESS arc (steps 2-30):** corruption/dedup/reorder/reset/preud/dedup_cull + combinatory
  braids (storm/corrupt_stream/rededup/storm_redial) + multicast(29). Dispatch `Lake_proof_drive`, witness
  `Lake_proof_witness`. Fixtures `wormhole/Story/PereProof/001-030.snap` recorded HEADLESS (no handshake → no
  step-3 residual → fully deterministic). CredRunner 30/30, all 12 `witnessed:*` fire.

GOTCHAS hit during the split: (1) world MUST be `w:PereProof` (per-beat `PereProof(A,w)` dispatched by W-NAME
— the [[peeroleum-swarm-refactor]] footgun); (2) `Lake_order` generalised to float `w.sc.w`'s actor (was
hardcoded 'PereStaple'); (3) THE TRAP — `Peeroleum_arm_whittle(w)` (retx/cull sweep) is armed by PereStaple's
`Lake_sides_up`; PereProof has none, so dedup_cull (needs cull) + storm (needs retx) silently never witnessed
until `Lake_proof_drive` arms it at its own step 2. Registered on Credence board via Net/Easy `Storying,
of_Book:PereProof` + `Point,method:Run_A_PereProof`. Run: `BOOK=PereProof … CredRunner.spec.ts`. Adding a Book
= Run_A_<Book> recipe + <Book>(A,w) per-beat (Story.svelte dispatches Run_A_ by name) + toc.snap + Credulate/
Credulation dirs + fixtures. Next split candidate = multicast → its own Book once pub[]/@handle grow it.
