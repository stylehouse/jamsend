# Peeroleum spec

The settled design for retiring `Peerily.svelte.ts` + `MachPeerily.svelte` and growing
 **Peeroleum** in their place — the particle-only p2p transport/message/`%req` spine, the
  "linoleum floor" everything social stands on. Endgame: retire Peerily/MachPeerily and
   rename Peeroleum → Peerily (handover heading 12).

**This spec carries only what the source can't tell you.** The live spine is the LangTiles
 ghosts `Ghost/N/Peeroleum.g` (the envelope + lifecycle + mock carrier), `Ghost/N/Tribunal.g`
  (transport-trial carriers + real WS), and `Ghost/Story/Peregrination.g` (the Book + witness) —
   they compile, they are content-addressed, they are the law. So this doc deliberately does **not**
    re-draw particle layouts or lifecycle state-walks that a fresh read of those `.g` files (or the
     `%req` engine in `Stuff.svelte.ts`) gives you truer. What it keeps is the non-inferrable: the
      **bombs** (code that looks fine and silently fails), the **unbuilt** designs (no `.g` exists
       yet, so this is the only record), the **destination**, and the **rejected paths** (don't
        re-derive a dead end). If something here reads like a description of working code, it has
         earned its place only by the bomb attached to it. Don't re-bloat it.

**Realised-shape corrections to the original framing** (kept because they overturn assumptions a
 reader brings): the spine is **not** a hand-written `Peeroleum.svelte` — it's the `.g` ghosts above.
  `MachPeeroleum` was **never grown**: observation is a Story Book (§14), not a Mach layer. The
   `type:mock` substrate (two sides handshake to `%req:handshake,finished` under one House) is built
    and proven (handover rungs 0–4).

**Two-frequency pair — read before editing either.** This (LOW-frequency) holds settled design +
 bombs; `Peeroleum_handover.md` (HIGH-frequency) holds live status, proofs, next-move, what's-broken.
  Rule of thumb: "how the floor IS designed / what bites" → here; "what's DONE / NEXT / proven-at-
   step-N" → handover. When a handover engine-fact corrects this spec, promote it here and leave a
    one-line gravestone — no silent caps.

---

## 0. Notation

The decoder ring used across all the Peeroleum docs and memories (it's a convention, not in any `.g`):

- `%Pier` = `{Pier:1}`; `%Pier,pub:abc` = `{Pier:1, pub:'abc'}` — **mainkey comes first**.
- `%req:handshake` = `{req:'handshake'}` — `req` is the mainkey, value `handshake`.
- Indentation is C depth. `Pier/protocol/hello/said` = `%said` inside `%hello` inside `%protocol`
   inside `%Pier`.
- `[,acked]` = the property may or may not be present.
- `e:hello%seq:3` = "an event of type hello carrying seq:3"; `source -> e:type%payload -> dest`
   traces a message.
- `// <` marks a deliberate hole — seen, not missed.
- `c.connection` is the live JS handle (DataChannel or mock port) — **the only `c.*` escape a `%Pier`
   keeps**; everything else that was a JS field becomes a particle.

Everything is `%req` now (the old `De:`-desire / `req:`-work split is gone): a "desire" is a `%req`
 that owns sub-`%req`; a leaf is a `%req` with no children. Depth carries the distinction the mainkey
  used to.

---

## 1. The one-line

> Every piece of a peer's state is a particle. The transport is swappable, with a `type:mock` that
> runs tests in-process and deterministic. Every message — hello, trust, data, binary — is one signed
> envelope. Reqs are unified on `%req`; a req that must wait is advised by a one-shot `%ttlilt` (the
> Lies family runs on this). The Peeroleum floor's own quiescence needs none — `feebly_ponder` +
> `post_do` + Story step-pacing drive the round-trip to completion inside a step (`Tribunal.g`
> deliberately avoids a ttlilt). Observation queries particles, not booleans.

---

## 2. Actor hierarchy

```
A:Peerologist / w:Peerologist      the manager — its own clean A (no identity, no transport)
    %req:p2pman                    brings Peerings up per our desire to appear online
A:Alice / w:Peeroleum              one A per identity-presence (room for A:Alice/w:OtherPresence later)
    %Peering,name:alice            a listen address (one Idento); owns its Piers
      %req:p2paddy                 manages the Piers under this Peering
      Id:Idento,prikey:…           this Peering's keypair (prikey private; pubkey the full public key)
      %active_transport,type:…     what is carrying right now
      %transport,type:…            an installed transport option (may be present-and-%faulty)
      %Pier,pub:…,req:N            one per known remote (§6); a typed serial-req flock member —
                                   pub is a prefix of the peer's pubkey, req_Pier pumps it
A:Alice / w:Thangs,thangs:peerings|identities   persisted lists (Dexie, §10)
```

**Why the shape (rationale, non-inferrable):** a Peering **owns** its Piers because a Pier only
 exists within an address scope — the same remote reached from two of our addresses is two Piers under
  two Peerings, so `Pier.c.up` is the Peering, not the worker. The manager is **its own A:Peerologist**
   (no identity/Peering/transport — it only wants Peerings to exist) so `w:Peeroleum` stays clean and
    the manager can elvis itself freely. `Peeroleum(A, w)` wires a worker.

---

## 3. The req model (unified %req)

Live API on any host C (engine in `Stuff.svelte.ts`): `host.oai({req,maz,eternal?,permanent?},sc?)`
 (sync), `host.doai(c,sc)?.(req=>…)`, `await host.do()`, `host.finish(child)`, `host.all_finished()`.
  `eternal` = never finished, self-settles via `req.sc.ok=1`; `permanent` un-finishes on input drift.
   The durable shape: everything is a `%req` (default mainkey `req`), desires nest under desires.
    (`reqy()` is gone.)

### 3.1 Nesting via req/*req
A childed `%req` with no own `do_fn` (no `doai`-set `req.c.do_fn`, no `H.req_<name>` handler) recurses
 `req/*req`, finishing the parent when all children finish. `maz` orders leaves: highest runs first,
  lower gated behind it (`do()` filters to the highest unfinished maz).

### 3.2 Waiting: ttlilt on a req that finishes
A leaf that can't finish yet stays `needs_work` and is re-pumped — there is no `%req:waiting` (an early
 per-leaf demand-client, never built). When a real transport makes a req span a snap, the way to advise
  how long to hold the snap open is a one-shot `%ttlilt` (`H.i_req_ttlilt(req, secs, {waiting})`). The
   floor itself needs none: it self-drives on `feebly_ponder` + `post_do` + step-pacing.

**Bomb — a ttlilt must ride a req that finishes.** It advises holding the snap open until that req
 reaches `finished`, and is dropped on `finish()`. A req that never finishes — an `eternal` foreman,
  self-settling via `req.sc.ok=1` — has nothing for a ttlilt to release, so it carries none.

---

## 4. Transport layer

A transport is a particle with a live `c.connection`. It knows nothing about hello/trust/data — it
 ships frames and reports liveness; verify happens above it, on the inbox.

### 4.1 The three kinds
`%transport,type:mock` (in-process, deterministic, tick-driven), `type:webrtc` (PeerJS DataChannel),
 `type:websocket` (relay via a WS endpoint we own). All install under a `%Peering`; `%active_transport`
  names the one carrying. **A failed transport stays present-and-`%faulty,reason:…`** rather than
   vanishing — so the user can be *told* their network is oppressing their speed (a webrtc that won't
    hole-punch is a particle, not a console line). Selection is `%req:p2paddy`'s job (§11), unbuilt.

### 4.2 The frame envelope (one shape, every message, every transport)
A signed `header` (`type,from,to,seq,time[,body_hash,body_len][,ack]`) + `header_sign` + optional
 `body`. Load-bearing choices:
- `from`+`to` ride **inside the signed header**, so a relay forwards by reading `to` without trusting
   or parsing `body` (§5). `sign` is cleartext (signed ≠ encrypted) so the relay still routes.
- **One signature, header only**, key-sorted (`cluster_trust.ts` `canonicalHeader`); the header commits
   to the buffer via `header.body_hash`, so verifying the header authenticates the buffer transitively.
    Corrupting body bytes fails verify identically to a tweaked hello-sign — **no bifurcated error
     paths.** Signing primitives: `signHeader`/`verifyHeader` in `src/lib/p2p/cluster_trust.ts`.
- `body_hash` is **sha256** (`crypto.subtle`). *Gravestone:* it was briefly a sync FNV digest, the only
   reason being to keep the inbox synchronous inside Atime; the inbox went fully async this session
    (awaited drain), so the sync hack is retired and sha256 — signable for the trust layer — replaces it.
- **A buffer-carrying frame is `[header JSON]\n[raw buffer]` — one atomic message, never base64**
   (binary is the bulk; a 33% base64 tax is unacceptable). `JSON.stringify` never emits a raw `\n`, so
    the receiver splits on the **first `0x0A`**: header = the text before, buffer = a near-zero-copy
     byte-tail. One message ⇒ **no per-frame reassembly queue** (the old Peerily three-message
      crypto→data→buffer cycle needed one). Large-transfer reassembly lives one layer **up**, at the
       chunk layer. **Hybrid:** no-buffer frames (hello/trust/ack/noop) stay text JSON; only buffer
        frames go binary. The **mock** serialises nothing — it carries `{header, buffer:Uint8Array}` by
         reference. Buffer is off-snap; only `body_hash`+`body_len` reach the snap.

### 4.3 Transport interface (conceptual)
`send(frame)` (returns once handed off, not delivered; the Pier stamps `%sent`), inbound delivery as
 `e:frame%… -> Pier inbox` (transport delivers raw, Pier verifies), and liveness `e:open`/`e:close`
  (driving `%active_transport/%open` and `o_elvis:reset_handshake`). **The corruption meddle hook sits
   on `%active_transport`, read live on every `send`** — so the same corruption test runs under any
    carrier (it perturbs whatever is carrying). Heading 6, unbuilt.

---

## 5. Realised transport topology — relay, two-AP routing (the "heading 10" design)

Settled design for real transport. First customer is the **editor↔runner channel** — so music-app peers
 and Lies (editor/runner) become two consumers of ONE envelope/transport/ack/faulty machinery.

**Topology — two node relays, two ports.** Browsers talk only to their **own-origin** `/relay`
 (same-origin WS — sidesteps CORS/mixed-content/Origin). The two relays **bridge each other**
  server-to-server over plain `ws`; one dials the other at a **hardcoded editor endpoint** — not a mesh,
   a pair.

```
editor browser ─ws→ editor /relay ←relay↔relay (plain ws)→ staging /relay ←ws─ staging browser
```

- **Routing = two-AP, no discovery.** A relay reads `header.to`; local socket → deliver; else hand it
   **once** to the peer relay. Two APs ⇒ "not local → the other one" is the whole table. No local socket
    → **drop** (the sender's no-ack `%ttlilt` retries).
- **Bomb — loop-safety is structural, not a flag.** A frame from a **browser** socket may be forwarded
   once; a frame over the **relay↔relay** link is **deliver-local-or-drop, never re-forwarded**. Two
    relays, single hop, asymmetric rule ⇒ a frame cannot loop.
- **Bomb — role is runtime, browser-commanded, set-once.** `Lies%runner`/`Lies%editor` sends a control
   frame to its own server to lock `role`; the r2r link comes up lazily on the first remote-bound frame.
    A second, conflicting assignment **throws**. No docker/env role config.
- **Bomb — avoid the phantom.** `vite.config.server.js` points at a `server.ts` that does **NOT exist**
   (half-removed scaffold). Do not build on it. The real server is `src/lib/server/relay.ts`
    (`attachRelay`, a `configureServer` vite plugin; `ws` is vite's existing dep).
- **The four consumer asks (in code):** `Peeroleum_on(w,type,fn)` (per-`w` `w.c.on` dispatch inside the
   inbox/ack/faulty lifecycle), `Peeroleum_send` (books outbox emit + seq), `Peeroleum_peer_ready(pier)`
    (reads both Piers' handshake/`%Ud`), and the real WS server above.
- **Security v1 = trust-everything** — the seam **Tyrant.g** attaches to. The runner HAS an Id (Peering/
   Pier are keyed by it); trust *enforcement* is deferred. Accept the one runner that connects, hardcoded
    editor+runner Ids. `%Ud` verification / per-runner authz / Thangs persistence are future.
- **Why ship `.go` bytes to the runner** (editor `write_finished`+`w%editor` → runner
   `LiesStore_good→land_good→drain_good`): same-machine the win is negligible; the real payoff is **remote
    running**, where the runner's disk is away on a server with no shared disk to the editor.

---

## 6. The Pier particle layout

The live layout is in `Ghost/N/Peeroleum.g` (a `%Pier` carries `%Ud`, `%protocol/{hello,trust}/{said,
heard}`, `%outbox`, `%inbox`, optional `%faulty`, and the handshake `%req`). Read it there, not a
 diagram here. The invariants that aren't obvious from the layout:

- **`%Ud` lives at Pier top-level and survives `reset_handshake`** — we still know who they are across a
   reconnect; it is the thing a faulty handshake must not reach prematurely.
- **`c.connection` is the ONLY `c.*` state on a Pier** — nothing else to reverse-engineer; the garden has
   no hidden roots.
- **A `%Pier` is a typed serial-req — `%Pier,pub:…,req:N`** (minted `oai Pier,$pub,req`): the mainkey
   `Pier` keeps it a queryable type *and* names its worker (`req_Pier`, dispatched by mainkey since the
    serial `req:` can't name a method), while `req:N` plugs it into the req pump — so `Peering.do()`
     reconciles the whole flock. We mint each Pier, so its identity is ours: a peer fills an existing
      Pier's inbox but never mints or re-keys one (no gut-swap). `pub` is a prefix of the proven `pubkey`
       (on `%Ud`); the mock verify is `pubkey.startsWith(pub)`.
- **State is queried, not field-polled:** "did they say hello" is `q.o({heard:1})` on `Pier/protocol/
   hello`, not a `.c.inst` bool that can flip before `%Ud` is set. Errors are `%inbox/**/error:…` rolled
    up to `%faulty`, not a thrown string from a hot path.
- Post-fold, inbox items are `%req:unemit` (drained by the `%req` engine), not the old flat `%unemit` —
   so query them as `o({req:'unemit'})` (this bit the step-2 witness; see handover).

---

## 7. outbox / inbox lifecycle

The states live in `Ghost/N/Peeroleum.g` (`Peeroleum_send`/`_pump_inbox`/`_take_ack`/`_rollup_faulty`/
`_arm_whittle`; outbox `created→sent→acked`, light acks, the inbox folded into the `%req` engine so
 `inbox.do()` IS the serial drain). The non-inferrable bits:

- **Acks are light:** every inbound non-ack frame, once verified, sends `e:ack%ack:<their seq>` back; the
   receiver of an ack does **not** run protocol handlers — it finds the outbox emit with matching `seq`
    and stamps `%acked`. **Acks are never themselves acked** (no ack storm).
- **Serial inbox:** never more than one frame handled at once; a second arriving mid-handle waits. (The
   `%req` fold expresses this as `inbox.do()` running reqs one-at-a-time in arrival order; keep them
    maz-less.)

### 7.3 Query-safe delete (bomb)
At a terminal mark the transient lock flags are `delete`d so the serial-lock query stops matching.
 `delete`+query is **sound**: `n_matches_kv` checks `hasOwnProperty` and the encoder reads `sc` directly,
  so a dropped key vanishes from both query and snap even though the stale X index still lists it (the
   post-filter rejects it).

### 7.4 Whittle (bomb)
At the step boundary, acked outbox emits and done inbox items move into a whittled `%recent` (newest ~20).
 **`drop` targets the host** — `host.drop(goner)`, *not* the old wrong `n.drop(n)`. `%recent` items carry
  no `time` (order is creation order, which the snap preserves), so the snap stays deterministic; `%faulty`
   is **not** auto-culled (a fault is kept until the handshake resets).

---

## 8. The handshake (hello + trust) as %req

`%req:handshake` under a `%Pier` owns four leaves — `said_hello` (maz:4), `heard_hello` (maz:3),
 `said_trust` (maz:2), `heard_trust` — each a **particle-existence check** (e.g. said_hello finishes iff
  `Pier/protocol/hello/%said` exists), maz-ordered so each waits on the prior. The say/hear writes
   (`hear_hello` verifies key starts-with `pub`, sets `%Ud`, then say_hello if needed, then say_trust)
    live in `Peeroleum.g`. The **cross-side short-circuit** survives from MachPeerily: once the *other*
     side is settled, this side stops demanding — the gap is the result (heard_hello never arriving after
      a corrupt hello is the test *passing*).

**Bomb — the c.up rule (load-bearing).** A `%req` hosted below `w` (under `%Pier`/`%Peering`) **silently
 never pumps** unless the host chain's `c.up` is stamped by hand: `Pier.c.up = Peering; Peering.c.up = w`.
  The belief walk wires `A.c.up`/`w.c.up` only — not the domain particles under `w` — so `pier.do()`
   climbs an undefined `c.up`, never reaches the House to resolve the req, and it sits `needs_work` **with
    no throw**. (`req.oai`/`doai` DO set `req.c.up=host`, so the req *tree* is fine; it's the non-req host
     chain `Pier→Peering→w` the walk leaves unwired.) Production must stamp this wherever `req_p2paddy`
      ensures a `%Pier` (§11).

---

## 9. faulty + reset_handshake

`%faulty` is a roll-up, present only when there is something to roll up (`%inbox/**/error:…` hoisted, with
 a `claim:step_N` corruption-test stamp reserved for heading 6). `reset_handshake` (an `o_elvis` aimed at a
  `%Pier`, triggered by `%active_transport e:close`): drop `protocol/**`, `outbox/**`, `inbox/**`,
   `faulty`, and `%req:handshake/**`; **keep `%Ud`** (we still know who they are); drop `c.connection` (a
    close means the handle is dead — p2paddy re-dials). So a disconnect is a clean particle reset the snap
     shows before-and-after.

---

## 10. Thangs — persisting lists  (UNBUILT — handover heading 11; this is the only record)

Two Dexie-backed tables under `w:Thangs`:
- `thangs:peerings` — one `%thang,name:<peer-pub>,stashed:{trust:[…], address, transport:{prefer,
   last_good}, last_seen}` per known peer. The hello+trust round-trip mutates `stashed.trust`; the
    throttled save persists it. `%req:p2paddy` reads these to know which Piers to (re)dial and with which
     transport preference (`transport.last_good` seeds next session's choice).
- `thangs:identities` — one `%thang,name:<our-pub>,stashed:{keys, friendly, online_want}` per identity
   we listen as. `%req:p2pman` ensures a `%Peering` per `online_want` identity. `Id` is constructed from
    `keys` (`pubkey` the full public key, `prikey` the private); our `name` is our `pub`, a prefix of `pubkey`.

---

## 11. The manager: p2pman / p2paddy / per-Pier desires  (UNBUILT — forward design)

> **Forward design, largely unbuilt** — current spine bodies are `// <` seams that `req.do(); req.sc.ok=1`.
>  Two standing caveats on the diagrams below: a leaf that must wait carries **no `%req:waiting`** (never
>   built) — it stays `needs_work`, advised by a one-shot `%ttlilt` if a real transport spans a snap; and
>    any Pier-/Peering-hosted `%req` needs its host chain's `c.up` stamped (§8) or it silently never pumps.

Three tiers, each a `%req` owning sub-`%req` — motivation flows down, state up:
- **`%req:p2pman`** (under `A:Peerologist`) — reads `thangs:identities`; per `online_want` seeds a
   `%req:bring_up` that ensures a `%Peering` exists and its transport is open; finishes when `%open`.
- **`%req:p2paddy`** (per `%Peering`) — reads `thangs:peerings`; seeds a `%req:dial` per known peer; owns
   `%req:transport_select` (try webrtc, wait, fall to websocket on timeout, leaving webrtc present-and-
    `%faulty`). *In the test this is wrangler-driven — `req_transport_select` is GONE (nesting it under
     p2paddy broke the `req.c.up`→Peering navigation); the req version is reserved for real peers.*
- **per-Pier** — the `%Pier,pub:…,req:N` is itself the worker: `req_Pier` (dispatched by mainkey, §6) pumps
   the Pier's own sub-reqs — `%req:handshake` (§8) and `%req:send` (seed it to put a thing on the wire; its
    do_fn writes a `%outbox/emit`, the transport ferries it, the ack finishes the req). `Peering.do()` runs
     the whole flock. Replaces old `Pier.emit()` poking. **BUILT** for the test wranglers (Lake/Tyrant).

The `%exports`/`%aim` upward hoisting once specced for state-roll-up is **not built** and no consumer needs
 it until p2pman is real.

---

## 12. Step-boundary janitorial

### 12.1 What runs at the boundary  (built — `_resolve_runstepped`)
The boundary is `_resolve_runstepped` (defined on the Run in `Hovercraft.svelte`, called from Story's
 `advance` after each snap commits). It does three things, in order: runs any queued page-turn callbacks;
  drops every `%log` — on each `A/w` and under any `%req` beneath it (§12.3); culls each Pier's outbox/inbox
   into `%recent` (§7.4 — `%recent` holds only acked emits). The drop runs *after* the snap commits, so a
    `%log` appears in exactly one snap (the step that wrote it) and is gone from the next. Settled and built.

**Bomb — the witness stamps *during* the step (pre-boundary); do not move the cull earlier** or it strips
 the traffic the witness and the snap depend on. The cull is the *only* place outbox/inbox items vanish, so
  the snap taken *before* the boundary always shows the send/receive that happened during that step.

### 12.2 Munging times
Where a real run writes `header.time`/`last_seen` into a snapped particle, the boundary munges it to a
 stable token (`time:~`) before the dige, keeping the live value on `c`. Mock runs avoid times entirely
  (naturally stable); real runs are stable after munging.

### 12.3 `%log`: show-once-then-drop, under any `%req`  (BUILT) + `.c.gc_fn` (forward design)
A `%log` is transient: it rides in exactly the next snap, then the boundary drops it (§12.1). This now works
 **wherever a `%log` hangs under a `%req`**, not just directly on `w`. The per-`%req` sweep
  (`Runstepped_reqy_pageturning` → `reqy_recurse` over `w/req**`) was already written but orphaned; it's now
   wired into `_resolve_runstepped`. So a step's diagnostic chatter can hang under its driving `%req` —
    legible during the step, gone from the persisted snap, no hand-deletion. *Gap:* a `%req` nested under a
     Pier/Peering isn't reached by the req-recursion (the same blind spot as the §8 `c.up` bomb); no
      consumer hits it yet.

This is the structural answer to snap-noise: the driver/setup bookkeeping that clutters a run's snap
 (`%reached:step_N`, the apparatus banner, transient diagnostics) can become `%log` and vanish at the
  boundary — leaving only the **assertions** in the snap. (And the assertions' real teeth are the per-step
   recorded snaps themselves, §14 — `%witnessed:*` is a legible/timing-stable marker on top, not the gate.)

**Still forward design — `.c.gc_fn`, a per-particle boundary hook.** Generalise "drop logs + cull outbox"
 into "run each registered `.c.gc_fn` at the boundary," so any particle self-registers its own cleanup
  instead of the janitor hardcoding every case. Defer until something beyond logs+outbox needs it.

---

## 13. Per-req demand for time — removed (see §3.2)

The `%req:waiting` demand-client + computed-max-global (`leave_running_until`) design was never built; all
 three subjects (`%req:waiting`, the global, `reqy`) are gone. Waiting is a `%ttlilt` on a req that
  finishes — folded into §3.2.

---

## 14. Observation is a Story Book (PereStaple), not a Mach layer

`MachPeeroleum` was never grown — observation is `Ghost/Story/Peregrination.g`, acquired by the Creduler
 runner. What survives from the Mach idea:
- **Assertions are particle-existence queries**, not `.c.inst` polling (`Lake_witness` does `q.o(...)` on
   the right particle).
- **The witness is a particle `%witnessed:step_N`** — the step rides in the **value** (`step` is the Story
   mainkey, so it can't be a key), so it shows up in the snap diff like everything else.
- **Bomb — `Lake_drive` explicitly refuses `H.on_step`.** `on_step` keys off one H-global `did_on_step_n`;
   when cold-compile/include spills into the next step, the `on_step` table claims it and **starves the
    real setup** (tell: a step-3 snap with `%reached:step_3` but no `A:Alice`/`A:Bob`). So dispatch is off a
     **req-local `req.c.did_step`**, immune to any other caller.

### 14.1 Meddle attaches to %active_transport (corruption — heading 6, unbuilt)
An eternal `%req:emit_corruption` installs a hook on Mallory's `%active_transport`; on every `send` the
 carrier reads the live `meddle_fn` and applies it **post-sign**, so verify fails on the far side →
  `%error` → `%faulty,claim:step_N`. Transport-agnostic by construction (it perturbs whatever carries). The
   receive side is **already realised** (`hear_*` return false → `%error` → `Peeroleum_rollup_faulty`); the
    only missing piece is the meddle wrap.

---

## 15. The mock transport

Built (`Peeroleum.g` + the wrangler's port-pairing). The two things that make it the test substrate:
- **Delivery is `post_do(() => partner.recv(frame))`** — instant, but bounced **into the beliefs mutex**
   (inside Atime), so a full hello+trust round-trip completes within a step, deterministically. No ICE/SDP/
    second-measured timers.
- **No timestamps reach particles**, so snaps are stable with no munging. The meddle hook sits on the mock
   `%active_transport` exactly as it will on real ones, so corruption tests written against mock port
    straight across.

---

## 16. Build order

Tracked rung-by-rung in `Peeroleum_handover.md` (the `[x]`/`[~]`/`[ ]` checklist). The endgame rung stands:
 migrate Otro, delete Peerily/MachPeerily, rename Peeroleum → Peerily.

---

## 17. Seams left open on purpose

- `// <` how thin the Pier shim is — `c.connection` plus the read/write of surrounding particles, but the
   live DataChannel's own event handlers still need a JS home; "as thin as the handlers force, no thinner",
    pinned per-transport as each is built.
- `// <` whether `body` is fully opaque or carries a tiny `body_type:json|raw|file_chunk` — the envelope
   reserves room (`body_len`) but assumes opaque for now.
- `// <` reaping `%faulty` — kept until `reset_handshake`; if a Pier accumulates faults without
   disconnecting, a whittle on `%faulty` may be wanted (decide when corruption volume exists).
- relay forwarding — **RESOLVED**: the `from`+`to`-on-header design carries it (§5).

---

## 18. Multicast — topics over a claimed `@channel`  (built; headless-witnessed PereStaple step 53)

The need: a high-bandwidth publisher (a phone relaying audio to 100 listeners) must **not** upload 100
 copies, one addressed to each Pier, nor even hold all 100 addresses. It uploads **once** to a *topic* and
  the relay does the fan-out. So the envelope's `to` grows a **special case**: a `to` that starts with `@`
   is a **channel** (a topic), not a peer `pub`. Everything below hangs off that one sigil.

**The split from a 1:1 stream is the load-bearing design choice** — a topic is NOT a reliable per-Pier
 stream:
- **Discovery/handshake/trust stay 1:1.** You still know *who* each subscriber is (per-Pier `%Ud`, the
   §8 handshake). Only the **bulk** goes multicast. The seam from unicast→multicast is the **handover**:
    an established Pier sends a `stream_offer` (a stream *pointer* — the `@channel` to subscribe to) over
     its trusted link; the peer's registered handler subscribes and thereafter receives over the fan-out.
      `Peeroleum_offer_stream` is the sender; a `Peeroleum_on(w,'stream_offer',…)` handler is the receiver.
- **Publishing is fire-and-forget.** `Peeroleum_publish` books **no** `%outbox/emit`, expects **no** acks,
   allocates **no** per-Pier seq — the whole point is not tracking N subscribers. A topic frame carries its
    **own** per-channel seq (`peering.c.chan_seq[channel]`, off-snap) so a subscriber can later detect a gap
     and NACK. This is the deliberate opposite of `Peeroleum_send` (§7's reliable outbox). On the reliable
      relay ws v1 needs none of it; a per-channel inseq for a lossy multicast carrier is **future**, and is
       NOT the per-Pier `inseq` (§7) — don't reuse that cursor.
- **No ack means no ack-storm.** 100 subscribers acking one frame is exactly what we avoid; the receive
   path (`Peeroleum_deliver`'s `@`-branch) dispatches to the handler and **returns** — no inbox booking, no
    `req_unemit`, no ack-back.

**Claiming an `@name` (the ownership primitive).** "Someone has to come and claim that `@name`." A claim
 reserves the name before it carries — **first-come for now, a community/crypto-signed gate later**. The
  claim records the owner (relay-side `claims` map + a `%owns,@channel` marker on the Peering); v1 does
   **not** enforce publish-against-owner (trust-everything, §5). `Peeroleum_claim` is the spine call.

**Where the multiplication happens — the relay (`relay.ts`).** Subscribe **reuses the existing routing**:
 `bind(@channel, ws)` adds the socket to the channel's `Set` in `locals`, and `deliverLocal` is *already* a
  fan-out over that Set — so a `to:@channel` frame routes to every subscriber with **zero routing change**.
   `subscribe`/`unsubscribe`/`claim` are relay control frames (no header, handled in `handleControl`); a
    socket's subscriptions + claims are tracked on it and released on close.
- **Bomb — one relay instance only (v1).** A topic delivers **local-only**; it is NOT forwarded over the
   r2r bridge. With subscribers split across two relays this would drop the far ones — the **two-instance**
    follow-up is "fan a channel frame to the bridge too" (penciled, unbuilt). Single instance today, fine.
- **Reconnect forgets subscriptions.** The relay drops a socket's channel binds on close; a reconnecting
   consumer must **re-subscribe** (via `Socket_real`'s `on_open` hook). Not buffered forever in the carrier.

**The mock substrate (deterministic test).** The mock carrier's `send` mirrors the relay: a `to:@channel`
 frame fans into the in-process relay by calling `Peeroleum_deliver(w, frame)` once, and the `@`-branch
  scans the Peerings under `w` that subscribed (`peering.c.subs[channel]`) — in production a `w` is one
   identity so exactly one matches; the co-resident test swarm holds N under one `w`, so the scan fans out
    to all N, the same multiplication the relay does across N sockets. Witnessed at **PereStaple step 53**
     (`Lake_multicast_arm` → `%witnessed:multicast`): one publish, three subscribers land `%mcast` exactly
      once, the publisher books no emit, the claim + the offer-driven subscribe both hold.

**The realised spine calls** (all in `Ghost/N/Peeroleum.g`): `Peeroleum_claim(w,peering,channel)`,
 `Peeroleum_subscribe(w,peering,channel,fn)`, `Peeroleum_publish(w,peering,channel,type,body)` (returns the
  channel seq), `Peeroleum_offer_stream(w,pier,channel)`, and the `@`-branch atop `Peeroleum_deliver`.
   `Socket_real` (`Ghost/N/Tribunal.g`) gains `claim`/`subscribe`/`unsubscribe` port methods that send the
    relay control frames. **Open seams:** the crypto-signed claim gate, cross-relay topic fan-out, a
     per-channel inseq + NACK for a lossy multicast carrier, and re-subscribe-on-reconnect.
