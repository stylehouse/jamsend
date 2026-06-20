# Peeroleum spec

The nailed-down design for retiring `Peerily.svelte.ts` (+ `MachPeerily.svelte`)
and growing **Peeroleum** in their place — the particle-only p2p transport/message/
`%req` spine, the "linoleum floor" everything social stands on.

This is a spec, not a sketch. Where the brief said "sketch, not law", this says
law — every particle, every state, every transition is pinned down. Code comes
after; this is the thing code is checked against.

**Realised shape (corrects the original framing).** The live spine is **not** a
hand-written `Peeroleum.svelte` — it is the LangTiles ghost `Ghost/N/Peeroleum.g`
(compiled to `gen/`), with the transport-trial carriers in `Ghost/N/Tribunal.g`.
`MachPeeroleum.svelte` was never grown: **observation is a Story Book**
(`Ghost/Story/Peregrination.g`), not a Mach layer (§14). The endgame stands —
retire Peerily/MachPeerily and rename Peeroleum → Peerily (handover heading 12).

The first thing built against this spec was the `%transport,type:mock` spine: two
sides come up under one House, exchange hello+trust as particles only, and land at
`%req:handshake,finished` on both. That **is built and proven** (handover rungs
0–4); what follows is filling in.

**This doc is one of a two-frequency pair — read this rule before editing either.**
`Peeroleum_spec.md` (here) is the LOW-frequency half: the durable, settled design of
the floor — particle layouts, the one signed frame envelope, the outbox/inbox/ack/
whittle lifecycle, handshake-as-`%req`, the mock substrate, the realised relay
topology (§5). It changes rarely; it is the law code is checked against.
`Peeroleum_handover.md` is the HIGH-frequency half: the live `[x]`/`[~]`/`[ ]`
checklist, "start here", per-rung status and proofs, next moves, and the forward
look (the Garden.g/Tyrant.g cabinetry+party layer riding this floor). **Rule of
thumb:** a fact that is "how the floor IS designed, settled" belongs here; a fact
that is "what's DONE / BROKEN / NEXT / proven-at-step-N" belongs in the handover.
When a handover engine-fact corrects this spec, promote it here and leave a one-line
gravestone on the prose it replaced — no silent caps.

---

## 0. Notation

So the diagrams read unambiguously:

- `%Pier` means a particle `{Pier:1}`.
- `%Pier,pub:abc` means `{Pier:1, pub:'abc'}`. The mainkey comes first.
- `%req:handshake` means `{req:'handshake'}` — req is the mainkey, value is `handshake`.
- `%demand,until:T` means `{demand:1, until:T}`.
- Indentation is C depth — a child sits inside its parent.
  `Pier/protocol/hello/said` is `%said` inside `%hello` inside `%protocol` inside `%Pier`.
- `[,acked]` means the property may or may not be present.
- `e:hello%seq:3` reads as "an event of type hello carrying seq:3".
- `source -> e:type%payload -> destination` traces a message.
- A `// <` comment describes an absence of development — a hole left on purpose,
  trailing off into whatever the subject was
   so the next reader knows it was seen, not missed.
- `c.connection` is the live JS handle (DataChannel, or a mock port);
   it is the only `c.*` escape hatch a `%Pier` keeps,
    everything else that was a JS field becomes a particle.

A note on the `req` unification: previously the desire layer used mainkey `De`
(`%De:handshake`) and the work layer used mainkey `req` (`%req:said_hello`). Both
are gone-as-two; everything is `%req` now. A "desire" is just a `%req` that owns
sub-`%req` (driven by `handler_of_last_resort`'s `req/*req` recursion). A leaf
work item is a `%req` with no children. Depth carries the distinction the
mainkey used to.

---

## 1. The one-line

> Every piece of a peer's state is a particle. The transport is swappable, with a
> `type:mock` that runs tests in-process and deterministic. Every message — hello,
> trust, data, binary — is one signed envelope. Reqs are unified on `%req`; a req
> that must wait is advised by a one-shot `%ttlilt` (the Lies family runs on this).
> The Peeroleum floor's own quiescence needs none — `feebly_ponder` + `post_do` +
> Story step-pacing drive the round-trip to completion inside a step (`Tribunal.g`
> deliberately avoids a ttlilt). Observation queries particles, not booleans.

---

## 2. Actor hierarchy

Three kinds of House-worker, plus the storage workers.

```
A:Peerologist                                    the manager — its own clean A
  w:Peerologist
    %req:p2pman                                  brings Peerings up per our desire to appear online
    %sides,N:[Alice,Bob,Mallory]           (test only) single source of side names
    %witnessed:step_N                            (test only) was the step's expected event seen (step on value, §14)
    %meddle ...                                  (test only) corruption arming, see §14

A:Alice                                        one A per identity-presence
  w:Peeroleum
    %Peering,name:alice,prepub:7acf…           a listen address (one Idento)
      %req:p2paddy                               manages the Piers under this Peering
      Id:Idento,prepri:923f…                     immutable identity of this Peering
      %active_transport,type:mock[,open]         what is carrying right now
      %transport,type:mock                       an installed transport option
      [%transport,type:webrtc[,faulty,reason:…]] another option; may be there and failing visibly
      %Pier,pub:8cbc…                            one per known remote, within this Peering
        ... (see §6)

A:Bob / A:Mallory                            same shape as Alice

A:Alice
  w:Thangs,thangs:peerings                       persisted known-peer list (Dexie), see §10
    %thang,name:<peer-pub>,stashed:{…}
  w:Thangs,thangs:identities                     persisted own-identity list
    %thang,name:<our-prepub>,stashed:{…}
```

Why a Peering owns its Piers (rather than the flat `w/%Pier` of old Peerily):
a Pier only exists *within* an address scope. The same remote reached from two of
our addresses is two Piers under two Peerings. `Pier.c.up` is the Peering, not
the worker. `%req:p2paddy` is per-Peering and owns exactly the Piers beneath it.

Why the manager is its own A:Peerologist: it has no identity, no Peering, no
transport — it only wants Peerings to exist. Giving it its own A keeps `w:Peeroleum`
clean of management cruft and lets the manager send itself elvises freely
(`H.i_elvisto('Peerologist/Peerologist', …)`).

Construction: `Peeroleum(A, w)` wires a worker. The A name still matters (Houses
are named), but one A may carry several `w` — `A:Alice/w:Peeroleum` for the
main presence, room for `A:Alice/w:OtherPresence` later without a second House.

---

## 3. The req model (unified %req)

`reqy()` is **gone** — superseded by the C-native `%req` engine on any host C:
`host.oai({req,maz,eternal?,permanent?},sc?)` (sync), `host.doai(c,sc)?.(req=>…)`,
`await host.do()`, `host.finish(child)`, `host.all_finished()` (`Stuff.svelte.ts`
~574-652). `eternal` = never finished, self-settles via `req.sc.ok=1`; `permanent`
un-finishes on input drift. What is durable is the *shape*: everything is a `%req`
with the default mainkey `req`, and desires nest under desires.

### 3.1 Nesting via req/*req

A desire with children is driven by `handler_of_last_resort`: when a `%req` has
its own `%reqcons`, `do_one` finds no explicit `do_fn` and instead does each
`req/*req` recursively, finishing the parent when all children finish.

```
%req:handshake                                   the desire (has children → recursion drives it)
  %reqcons                                        child-req bucket (serialised anon reqs)
    %reqcon:req,serial_i:…
  %req:said_hello,maz:4                           leaf work items
  %req:heard_hello,maz:3
  %req:said_trust,maz:2
  %req:heard_trust                                last → finishing it finishes %req:handshake
```

`maz` orders the leaves: highest maz runs first, lower maz gated behind it
(`do()` filters to the highest unfinished maz). So heard_hello (maz:3) can't run
until said_hello (maz:4) is finished, and so on down to heard_trust (no maz = 1).

### 3.2 The waiting-req — VOIDED (never built)

The original design was a throwaway `%req:waiting,until:T` per leaf as the demand
client, with a computed-max global. **It was never built and is deliberately
abandoned** — `%req:waiting` appears in no engine code. A leaf that cannot finish
yet simply stays `needs_work` and is re-pumped; the realised demand mechanism is a
one-shot `%ttlilt` (a snap-timing advisor, §1), and the floor self-drives on
`feebly_ponder` + `post_do` + step-pacing. Full gravestone in §13; see handover
heading 5 (CLOSED).

---

## 4. Transport layer

A transport is a particle with a live `c.connection`. It knows nothing about
hello/trust/data — it ships frames and reports liveness. Verify happens above it,
on the inbox particle.

### 4.1 The three kinds

```
%transport,type:mock                              in-process, deterministic, instant, tick-driven
%transport,type:webrtc                            PeerJS DataChannel (the old path, relocated)
%transport,type:websocket                         relay via a separate WS endpoint we own
```

All three are installed under a `%Peering`. `%active_transport` names the one
currently carrying. Selection (try webrtc, fall back to websocket after N seconds
of no `/open`) is `%req:p2paddy`'s job and lives as reqs, not hidden timers.

```
%Peering,name:alice,prepub:7acf…
  %transport,type:webrtc,faulty,reason:no-direct-route   tried, failed — stays visible
  %transport,type:websocket
  %active_transport,type:websocket,open                  fell back; this is what carries now
```

The webrtc `%transport` staying present-and-`%faulty` is the point: the user can
be told their network is oppressing their speed by disallowing direct peer
connections. The failure is a particle, not a console line.

### 4.2 The frame envelope (identical on every transport)

One envelope, every message type, every transport:

```
frame
  header                                          JSON, signed as a unit
    type:hello|trust|trusted|data|test_binary|ack|noop
    from:<prepub>                                 sender identity
    to:<prepub>                                   destination identity
    seq:N                                         sender's per-Pier outbound counter
    time:T                                        sender wall-clock seconds
    [body_hash:<hex>]                             present iff body present
    [body_len:N]
    [ack:N]                                       present iff type:ack — the seq being acked
  header_sign:<hex>                               sig over JSON.stringify(header), by from's key
  [body:<bytes>]                                  opaque to transport; integrity via header.body_hash
```

- The signed `header` carries `from`+`to`. A relay (websocket server, or a mutual
  friend both can reach — unlikely but possible at a corporate-network edge) can
  forward by reading `to` without trusting or parsing `body`.
- One signature covers the header; `header.body_hash` covers the body. So
  `test_binary` corruption is just the meddle tweaking body bytes — verify fails
  identically to a tweaked hello-sign. No bifurcated error paths.
- Binary cannot ride inside JSON, so the body is a separate wire item. On WebRTC
  that is header-send then body-send (the receiver waits for body before
  delivering, exactly the old crypto→data→buffer cycle, now header→body). On
  WebSocket/mock it can be one chunk. Either way the *frame* is the unit the
  inbox tracks.

### 4.3 Transport interface (conceptual, not signatures)

A transport exposes three things to the Pier layer:

- `send(frame)` — hand a frame to the wire. Returns once handed off (not once
  delivered). Stamps nothing itself; the Pier stamps `%sent` on the outbox item.
- `e:frame%{from,to,header,header_sign,body?}` -> Pier inbox — inbound delivery.
  The transport delivers raw; the Pier verifies and handles.
- liveness: `e:open` and `e:close`, which drive `%active_transport/%open` and
  `o_elvis:reset_handshake` respectively.

The meddle hook (corruption testing) lives on `%active_transport`, read live on
every `send` (§14). Transport-agnostic: the same corruption tests run under any
type because they perturb whatever is carrying.

---

## 5. Realised transport topology — relay, two-AP routing, the frame spine (the "heading 10" design)

The settled design for real transport, promoted here from the handover. Kept
addressable as **"heading 10"** — its first customer is the editor↔runner channel,
which makes the music-app peers and Lies (editor/runner) two consumers of ONE
envelope/transport/ack/faulty machinery. (Transport *selection* is §4.1 + §11.)

**Topology — two servers on localhost, two ports.** Browsers talk only to their
**own-origin** `/relay` (same-origin WS — sidesteps CORS, mixed-content, Origin
checks). The two node relays **bridge each other server-to-server** over plain `ws`
to the one with a reachable domain (the **editor**). One relay dials the other at a
**hardcoded** editor endpoint — not a mesh, a pair.

```
editor browser ──ws──▶ editor /relay ◀──relay↔relay (plain ws)──▶ staging /relay ◀──ws── staging browser
   (same origin)         (node)              (no CORS)                (node)         (same origin)
```

**Routing = two-AP, no ARP / no discovery.** The 802.11g picture: your relay is the
**AP**, `header.to` is the destination address. A relay reads `header.to`; local
socket → deliver; else hand it **once** to the peer relay. With exactly two APs,
"not local → the other one" is the whole routing table. **No-local-socket → drop**
(the sender's no-ack `%ttlilt` retries).

**Loop-safety is structural, not a flag.** A frame from a **browser** socket may be
forwarded once to the peer relay; a frame over the **relay↔relay** link is
**deliver-local-or-drop, never re-forwarded**. Two relays, single hop, asymmetric
rule ⇒ a frame cannot loop.

**Role is runtime, browser-commanded, set-once.** `Lies%runner` sends a control
frame to its own server: *become runner-server.* The server locks `role=runner` and
opens exactly one r2r ws-client to the editor's hardcoded domain; `Lies%editor` locks
it `editor`. A second, conflicting assignment **throws** (errorific). The whole flow
is initiated from the browser by Lies — the servers are dumb pipes that wake on
browser traffic, and the r2r link comes up lazily on the first remote-bound frame.
NO docker/env role config.

**The four asks to this spine (all realised in code):**
1. **App-frame dispatch seam (`Peeroleum_on`)** — `Peeroleum_pump_inbox` routes a
   non-protocol `header.type` to a per-`w` registered handler (`Peeroleum_on(w,type,
   fn)` → `w.c.on[type]`, a `.c` seam), keeping the inbox/ack/faulty lifecycle +
   pre-Ud gate. This lets Lies own `dock_push`/`run_result` without editing the spine.
2. **Consumer emit via `Peeroleum_send`** — already books the outbox emit + seq for
   any non-ack frame; a consumer just calls it. Promoted to a Pier-hosted `%req:send`
   it hits the **c.up rule** (§8) or it silently never pumps.
3. **Peer-ready signal (`Peeroleum_peer_ready`)** — a thin read of both Piers'
   `%req:handshake,finished` / `%Ud` for a consumer to gate on (the pre-Ud inbox gate
   rejects app frames until handshake completes anyway).
4. **Real WS on the editor's server** — attach via a `configureServer` vite plugin on
   the dev `httpServer` (`ws` is already vite's transitive dep). **Avoid the phantom**:
   `vite.config.server.js` points at a `server.ts` that does NOT exist — half-removed
   scaffold; do not build on it. (Realised: `src/lib/server/relay.ts` `attachRelay`.)

**Security / v1 reality — the seam Tyrant.g attaches to.** The runner HAS an Id
(`%Peering`/`%Pier` are keyed by it) — identity is present, trust *enforcement* is
deferred. v1 = **trust-everything**: accept the one runner that connects, handshake
completes implicitly, hardcoded editor+runner Ids so there is *some* identity to
tighten later. `%Ud` verification, per-runner authorization, Thangs persistence are
future — this trust-everything seam is exactly where the cabinetry layer (Tyrant.g,
identity/trust) bolts on.

**Where frames land (the Lies side).** Editor emit hook = `write_finished` + `w%editor`;
runner receiver = `LiesStore_good → land_good → drain_good`. The channel carries the `.go`
**bytes**, not a path — there is no shared OPFS across the two origins, so a shared-disk
shortcut is *not* available (don't "optimise" the byte-shipping away).

---

## 6. The Pier particle layout (full)

This is the heart — the black-box JS state of old `Pier` becomes leaves.

```
%Pier,pub:8cbc…                                   c.connection = live DataChannel|mock-port
  %Ud[,publicKey:abcd…]                           their identity; set once hello verifies, survives resets
  %protocol                                       the handshake's recorded state (reset on disconnect)
    %hello
      %said[,seq:N][,acked]                        we sent hello; acked when they acked that seq
      %heard[,publicKey:abcd…]                     they sent hello; carries the full key they proved
    %trust
      %said[,seq:N][,acked]
      %heard
  %outbox                                          pending + recently-sent outbound, see §7
    %emit:N,type:hello,seq:N[,sent][,acked]
    %recent                                        whittled tail of the last ~20 acked, see §7.4
      %emit:N,type:hello,seq:N
  %inbox                                           arriving + recently-handled inbound, see §7
    %unemit:N,type:hello,seq:N[,queued][,handling][,verified][,done,to:hello]
    %recent
      %unemit:N,type:hello,seq:N
  [%faulty]                                        roll-up; present iff any inbox item is faulty
    %unemit:N,error:invalid-signature,seq:N[,claim:step_N]
```

What each win buys (against the four bugs in the brief):

- `heard_hello` is `Pier/protocol/hello/heard` — a query `q.o({heard:1})` on the
  right Pier, no `.c.inst` field-poll, no race with a bool flipped before `%Ud` is
  set. (Kills bug #1's class of asymmetry, makes #3 a query.)
- `%Ud` lives at Pier top-level and survives `reset_handshake` (we still know who
  they are across a reconnect). It is the thing a faulty handshake must *not*
  reach prematurely — and now reaching it is a visible particle write.
- Errors are `%inbox/unemit:N/error:…` rolled up to `%faulty`, not a thrown
  string from a hot path. (Kills bug #4's invisibility — the error is a stamp.)
- `c.connection` being the *only* `c.*` state means there is nothing else to
  reverse-engineer. The garden has no hidden roots.

`reset_handshake` (from a disconnect, via `o_elvis:reset_handshake`):
drops `Pier/protocol/**`, `Pier/outbox/**`, `Pier/inbox/**`, and `Pier/faulty`.
Keeps `%Ud` and `c.connection`. Then `%req:handshake` is reset (§9) so a fresh
round-trip re-seeds.

---

## 7. outbox / inbox lifecycle

Both are one-particle-per-message with a whittled `%recent` tail. The asymmetry:
outbound is ours to mark as it progresses; inbound must be **handled serially**.

### 7.1 Outbox states

A `%emit:N` walks:

```
(created)            %emit:N,type:hello,seq:S            we want to send this
  -> send(frame)
(handed to wire)     %emit:N,…,seq:S,sent                transport.send returned
  -> e:ack%ack:S from far side
(confirmed)          %emit:N,…,seq:S,sent,acked          they acked seq S
  -> step boundary
(culled)             moves into %outbox/recent, whittled to 20      (§7.4)
```

`seq` is the sender's per-Pier outbound counter (monotone). The ack references it.

### 7.2 Acks

We ack things now. Every inbound non-ack frame, once verified, causes us to send
`e:ack%ack:<their seq>` back. The ack is a frame (`type:ack`) but a light one: the
receiver of an ack does not run it through the protocol handlers — it finds
`outbox/emit` with matching `seq` and stamps `%acked`. Acks are never themselves
acked (no ack storm).

```
Alice -> e:hello%seq:7 -> Bob
Bob: verifies, delivers, then
Bob -> e:ack%ack:7 -> Alice
Alice: finds %outbox/emit:N,seq:7 -> stamps %acked
```

### 7.3 Inbox states (serial handling)

Inbound is the careful side. Frames arrive possibly faster than they verify
(verify is async). They must be handled **one at a time, in order** — the old
`unemit_queue` + `unemit_processing` guarantee, now expressed as particle state.

A `%unemit:N` walks:

```
(arrived, not started)    %unemit:N,type:hello,seq:S,queued        marked queued — the backlog is visible
  -> handler picks the oldest %queued (serial; at most one leaves queued at a time)
(being handled)           %unemit:N,…,handling                     exactly one %handling across the inbox
  -> verify header_sign with their %Ud (or, pre-Ud, only hello|noop allowed)
(verified)                %unemit:N,…,verified                     sig good; body_hash checked if body
  -> deliver to protocol handler for type
(done)                    %unemit:N,…,verified,done,to:hello       handed to hear_hello etc
  -> send ack, drop %queued+%handling
  -> step boundary -> %inbox/recent (whittled 20)

  on failure at verify or deliver:
(faulty)                  %unemit:N,…,error:invalid-signature      no %done; rolled up to %faulty
```

(`%done` is the inbox terminal — "we finished handling it, handed up to hear_*".
 It replaced the old `%delivered`, which read tautological: an inbox item is by
  definition arrived, so "delivered" said nothing — `%done` says we are through with it.)

The serial guarantee, stated plainly:
the handler refuses to run handlings in parallel.
There is never more than one `%unemit:N,handling` under a Pier's inbox.
A second frame arriving mid-handle sits at `%queued` until the first reaches a
terminal mark (`%done` or `%error`).

`%queued` is the "unhandled-yet" marking the brief asked for — backlog you can
see in the snap. In mock mode delivery is instant so backlog rarely persists into
a committed snap; under real transport it can, and then it is legible.

**Invariant (query-safe delete).** At `%done` the transient `%queued`/`%handling`
flags are `delete`d (the serial lock query `handling && !done` needs them gone).
`delete`+query is sound: `n_matches_kv` checks `hasOwnProperty` and the encoder
reads `sc` directly, so a dropped key vanishes from both queries and the snap even
though the stale X index still lists it (the post-filter rejects it).

### 7.4 Whittle (the cull)

From the brief's `whittle_N`, fixed so `drop` targets the host:

```
whittle  keep the newest `to` (default 20) of a list N under host;
         drop the older ones from the front (oldest first);
         host.drop(goner)   // < the old code called n.drop(n) — wrong; drop is the host's verb
```

Runs at the step boundary (§12). For each Pier:
- `%outbox/emit:N` that are `%acked` move into `%outbox/recent`, whittled to 20.
- `%inbox/unemit:N` that are `%done` move into `%inbox/recent`, whittled to 20.
- `%faulty` is rebuilt from whatever `%inbox/**/error:…` remain (faulty items are
  *not* auto-culled — a fault is worth keeping until the handshake resets).

Determinism: `recent` items carry no `time` (order is creation order, which the
snap preserves). The `header.time` that *did* matter is gone with the live frame;
the particle is just a record that "an emit of type hello, seq S, happened". Where
a real run does need a time in the snap, it is munged (§12) so the dige is stable.

---

## 8. The handshake (hello + trust) as %req

`%req:handshake` lives under a `%Pier` and owns four leaves. This is the old
`De:handshake` shape, one level deeper (under Pier, not under w) and renamed.

```
%Pier,pub:8cbc…
  %req:handshake,target:8cbc…
    %req:said_hello,maz:4                          finishes when Pier/protocol/hello/said exists
    %req:heard_hello,maz:3                         finishes when Pier/protocol/hello/heard exists
    %req:said_trust,maz:2                          finishes when Pier/protocol/trust/said exists
    %req:heard_trust                               finishes when Pier/protocol/trust/heard exists
                                                    -> finishing it finishes %req:handshake
```

Each leaf's do_fn is now a **particle existence check**, not a bool poll:

```
%req:said_hello   do:  if Pier/protocol/hello/%said exists -> finish
                       else -> stay needs_work; the wrangler/post_do chain re-pumps
                               it next pass (no %req:waiting — that was never built)
```

The protocol writes that drive these come from the hello/trust exchange:

```
say_hello:   we -> e:hello%{publicKey} -> them ; write Pier/protocol/hello/%said,seq:S
hear_hello:  them -> e:hello%{publicKey} -> us ; verify key starts-with pub ;
               write Pier/protocol/hello/%heard,publicKey ; set %Ud ;
               if !said -> say_hello ; then say_trust
say_trust:   we -> e:trust%{trust[]} -> them ; write Pier/protocol/trust/%said,seq:S
hear_trust:  them -> e:trust%{trust[]} -> us ; verify each grant ;
               write Pier/protocol/trust/%heard
```

The cross-side short-circuit (from MachPeerily) survives: once the *other* side
is settled, this side stops demanding — the gap is the result (e.g. heard_hello
never arriving after a corrupt hello is the test passing).

**The c.up bomb (load-bearing).** A `%req` hosted below `w` (under `%Pier`/
`%Peering`) silently never pumps unless the host chain's `c.up` is stamped by hand:
`Pier.c.up = Peering; Peering.c.up = w`. The belief walk wires `A.c.up`/`w.c.up`
only — not the domain particles under `w` — so `pier.do()` climbs an undefined
`c.up`, never reaches the House to resolve `req_handshake`, and the req sits
`needs_work` with no throw. In production the spine must do the same wherever
`req_p2paddy` ensures a `%Pier` (§11.2). (`req.oai`/`doai` DO set `req.c.up=host`,
so the req *tree* is fine; it's the non-req host chain `Pier→Peering→w` that the
walk leaves unwired.)

---

## 9. faulty + reset_handshake

`%faulty` is a roll-up, present only when there is something to roll up.

```
%Pier,pub:mallory…
  %faulty
    %unemit:N,error:not-them,seq:3                  the actual failed inbox item, hoisted
    %unemit:M,error:invalid-signature,seq:4[,claim:step_5]
```

`claim:step_N` is the corruption-test stamp (§14) marking which step expected this
fault — reserved for heading 6 (the meddle machinery is not built yet).

`reset_handshake` is an elvis — `o_elvis:reset_handshake` aimed at a `%Pier`:

```
trigger:   %active_transport e:close   (a disconnect)
  -> Peering -> o_elvis:reset_handshake -> Pier
action on Pier:
  drop Pier/protocol/**
  drop Pier/outbox/**
  drop Pier/inbox/**
  drop Pier/faulty
  keep Pier/%Ud           we still know who they are
  keep c.connection?      no — a close means the handle is dead; p2paddy re-dials
then:
  drop Pier/%req:handshake/**     so the next %req:p2paddy do() re-seeds a fresh round-trip
```

So a disconnect is a clean particle reset, and the snap before-and-after shows
exactly what was torn down and rebuilt.

---

## 10. Thangs — persisting lists

The old Things stack is gone; `Thangs.svelte` (Dexie-backed C** particles) holds
the persistent lists. Two tables matter for Peeroleum.

### 10.1 Known peers

```
w:Thangs,thangs:peerings
  %thang,name:<peer-pub>,stashed:{
    trust:        [ {to,time,sign}, … ]            what we've granted / they've granted
    address:      <last-seen prepub or relay hint>
    transport:    { prefer:webrtc|websocket, last_good:websocket }
    last_seen:    <munged-or-real seconds>
  }
```

One `%thang` per known peer. The hello+trust round-trip mutates the matching
`%thang`'s `stashed.trust`; the throttled save in `Thangs.svelte` persists it.
`%req:p2paddy` reads these to know which Piers to (re)dial and with which
transport preference — `transport.last_good` seeds the next session's choice.

### 10.2 Own identities

```
w:Thangs,thangs:identities
  %thang,name:<our-prepub>,stashed:{
    keys:         <storableIdento>                 our private+public, persisted
    friendly:     "alice"                        display name
    online_want:  true                             do we want to appear online as this?
  }
```

One `%thang` per identity we listen as. `%req:p2pman` reads these: for each with
`online_want`, it ensures a `%Peering` exists and is brought up. So a Peering
needs no custom persistence — its identity is a thang, its Piers are particles
backed by the peerings thang.

The old `Idento`/`prepri`/`prepub` setup becomes: `Id` constructed from the
identity thang's `keys`; `prepub` is `name`; `prepri` is a display fragment.

---

## 11. The manager: p2pman / p2paddy / per-Pier desires

Three tiers of desire, each a `%req` owning sub-`%req`. Motivation flows down;
state flows up.

> **Forward design, largely unbuilt** — the current spine bodies are `// <` seams
>  that just `req.do(); req.sc.ok=1`. Two corrections to the diagrams below: (1) a
>   leaf that must wait carries **no `%req:waiting`** (never built) — it stays
>    `needs_work` and is re-pumped, advised by a one-shot `%ttlilt` if a real
>     transport makes it span a snap; (2) any Pier-/Peering-hosted `%req` needs its
>      host chain's `c.up` stamped (§8) or it silently never pumps.

### 11.1 %req:p2pman — appear online

```
A:Peerologist/w:Peerologist
  %req:p2pman                                       top desire: be online per our identities
    %req:init                                        one-time wiring (on_hangup, side names)
    %req:bring_up,prepub:7acf…                       one per identity-thang with online_want
                                                     (waits by staying needs_work; no %req:waiting)
```

`%req:p2pman` reads `w:Thangs,thangs:identities`. For each `online_want` identity
it seeds a `%req:bring_up` whose do_fn ensures `A:<side>/w:Peeroleum/%Peering`
exists and its transport is open. `%req:bring_up` finishes when the Peering is
`%open`; until then it stays `needs_work`.

### 11.2 %req:p2paddy — manage this Peering's Piers

```
A:Alice/w:Peeroleum
  %Peering,name:alice,prepub:7acf…
    %req:p2paddy                                     desire: maintain Piers per known-peers
      %req:dial,target:8cbc…                          one per peer we want connected
      %req:transport_select                           try webrtc, fall back to websocket
                                                       (reserved for REAL peers; the test trial
                                                        is wrangler-driven — Tribunal.g, not a %req)
```

`%req:p2paddy` reads `w:Thangs,thangs:peerings`. For each known peer it seeds a
`%req:dial`. It also owns `%req:transport_select`, which seeds `%transport,type:webrtc`,
waits, and on timeout seeds `%transport,type:websocket` and points
`%active_transport` at it (leaving webrtc present-and-`%faulty`). **In the test this
is wrangler-driven** — `req_transport_select` is GONE (nesting it under p2paddy broke
the `req.c.up`→Peering navigation); the req version is reserved for real peers.

### 11.3 per-Pier desires — handshake and sends

```
A:Alice/w:Peeroleum
  %Peering,name:alice,prepub:7acf…
    %Pier,pub:8cbc…
      %req:handshake,target:8cbc…                     §8 — the round-trip
      %req:send,type:data,seq:S                        a thing we want on the wire
                                                       (finishes when %outbox/emit:S is %acked)
```

A `%req:send` is how the new world replaces `ier.emit()` poking. To send, seed a
`%req:send`; its do_fn writes a `%outbox/emit:N`; the transport ferries it; the
ack stamps `%acked`; `%req:send` finishes.

State flows up the hierarchy in principle — a Pier's `%faulty` summarised to its
Peering, a Peering's open-count to p2pman — so each tier sees the tier below without
walking it. (The `%exports`/`%aim` hoisting once specced for this is **not built**;
no consumer needs it until p2pman is real — see §12.)

---

## 12. Step-boundary janitorial

The brief wanted "a time to do things" — clear `w/**%log`, cull outbox, hoist
exports. That time already exists: `_resolve_runstepped` runs on Run after each
snap is committed (`Story.svelte` `advance` -> `_resolve_runstepped`). We extend
it, and we register per-w page-turning callbacks.

### 12.1 What runs at the boundary

In order, after the snap commits:

```
for each Run-stepped callback queued via Runstepped(cb):  run it (existing)
for each A under Run, each w under A:
  w_noproblemo(w, {log:1})                               drop %log (existing)
  for each %Peering under w, each %Pier under it:
    cull  Pier/outbox/emit:* where %acked    -> Pier/outbox/recent (whittle 20)
    cull  Pier/inbox/unemit:* where %done -> Pier/inbox/recent (whittle 20)
    rebuild Pier/%faulty from remaining inbox/**/error
```

This is the only place outbox/inbox items vanish, so the snap *before* this
boundary always shows the send/receive that happened during the step. That is the
"capture important moments before carrying on" the brief asked for. **The witness
stamps during the step (pre-boundary); do not move the cull earlier or it would
strip the traffic the witness and the snap depend on.**

### 12.2 Hoisting exports — VOIDED (not built)

The `%exports`/`%aim` hoisting once specced here (a particle declaring a summary to
lift to its parent for legibility) is **not in the engine**. No consumer needs the
Peering-level summary until `%req:p2pman` is real (handover heading 11). Deferred,
not designed.

### 12.3 Munging times

Where a real run writes `header.time` or `last_seen` into a particle that reaches
a snap, the boundary munges it to a stable token before the dige is computed
(e.g. replace any `time:<wallclock>` with `time:~` in the snap codec, keeping the
live value on `c` for behaviour). Mock runs avoid times entirely, so their snaps
are naturally stable; real runs are stable after munging. The brief accepted this:
"we'll have to."

### 12.4 want_savepoint / %waits_savepoint — VOIDED (not built)

`want_savepoint`/`%waits_savepoint` (force a snap before the boundary culls a
just-sent item) is **not in the engine**. Under the mock the `post_do` chain drives
the round-trip within a step, so the snap-visibility guarantee it bought isn't
needed yet; a real transport would reach for a `%ttlilt`, not this. Deferred.

---

## 13. Per-req demand for time — VOIDED (ttlilt is the realised mechanism)

This whole section specced a `%req:waiting` demand client + a computed-max global
`leave_running_until` + `reqy` as the demand client. **None of it was built**, and
all three subjects are gone: `reqy()` is deleted (§3); `%req:waiting` and the
computed-max global exist in no code. The realised mechanism is a one-shot `%ttlilt`
(`H.i_req_ttlilt(req, secs, {waiting})`, `Hovercraft.svelte:380`) — owned demand,
dropped on `finish()`, polled-not-mutated (no write-write race), already what the
live system runs on (LiesStore/Lang/LiesCortex). The floor itself uses none
(`Tribunal.g` deliberately avoids it; it self-drives on `feebly_ponder` + `post_do`
+ step-pacing). See handover heading 5 (CLOSED) — don't rebuild this.

---

## 14. Observation is a Story Book (Peregrination), not a Mach layer

The original design here was a `MachPeeroleum` Mach layer (an `on_step` choreography
table, force-finish-prior, the witness flag). **`MachPeeroleum` was never grown** —
observation is the Story Book `Ghost/Story/Peregrination.g`, acquired by the Creduler
runner. What survives from the Mach idea is durable and lives on:

- **Assertions are particle-existence queries**, not `.c.inst` polling. Every check is
  a `q.o(...)` on the right particle — e.g. "does `Pier/protocol/hello/%said` exist on
  the Pier with this `pub`". (`Lake_witness` in the Book does exactly this.)
- **The witness is a particle**: `%witnessed:step_N` — the step rides in the *value*
  (`step` is the Story mainkey, so it can't be a key), so the step-witnessing shows up
  in the snap diff like everything else.
  > Gravestone: the old shape was `%witnessed,step:N` — corrected to `%witnessed:step_N`.
- **The corruption meddle hook sits on `%active_transport`** (not `Pier.emit`), read
  live on every `send`, so the same corruption test runs under mock/webrtc/websocket —
  it perturbs whatever is carrying (§14.1). Reserved for heading 6; the meddle
  machinery itself is not built yet (legacy `MachPeerily` only).

**The realised observer.** `Run_A_Peregrination` wires the Run; `Peregrination(A,w)`
installs `%req:wrangle,eternal` whose do_fn calls `Lake_drive(w, req)` each pass.
`Lake_drive` dispatches per inner step off a **req-local `req.c.did_step`** — and
**explicitly refuses `H.on_step`**, which keys off one H-global `did_on_step_n`: when
cold-compile spills into the next step, an `on_step` table claims it and starves the
real setup (the exact bug the old Mach `on_step` would reintroduce). `Lake_witness`
stamps the witnesses; `Lake_sides_up` / `Lake_handshake` / `Lake_trial_*` are the
per-step setups.

### 14.1 Meddle attaches to %active_transport (corruption — heading 6)

```
A:Peerologist/w:Peerologist
  %req:emit_corruption,target:Mallory,eternal
    %req:wrap                                        install the meddle hook on Mallory's active_transport
    %req:N,corruption:publicKey,meddle_fn:Function   the live lie; re-arm latest-onlys it
```

The wrap installs a hook on `%active_transport`. On every `send` the transport reads
the live `meddle_fn` and applies it to the frame **post-sign**, so:

```
Mallory send path:  build frame -> sign header -> [meddle_fn(frame)] -> active_transport.send(frame)
Alice inbox:        %unemit:N,handling -> verify fails -> %unemit:N,error:invalid-signature
                                                            -> hoist to %faulty,claim:step_N
```

A step opt `transport:mock|webrtc|websocket` lets the same sequence run under each
carrier — the corruption × message-type × transport cross-product. The receive side is
**already realised**: `hear_*` `return false` on reject → `%error` →
`Peeroleum_rollup_faulty`; the missing piece for heading 6 is only the meddle wrap.

---

## 15. The mock transport (first thing built)

Deterministic, in-process, tick-driven. Two `%transport,type:mock` particles, one
per side, whose `c.connection`s share an in-process queue.

```
A:Alice/w:Peeroleum/%Peering/%active_transport,type:mock,open
   c.connection -> mock-port-B  ──┐
                                  ├─ shared queue (a JS array, plus a partner ref)
A:Bob/w:Peeroleum/%Peering/%active_transport,type:mock,open
   c.connection -> mock-port-N  ──┘
```

Delivery:

```
B.send(frame):
  push frame onto N's incoming
  H.post_do(() => N-side Pier inbox <- e:frame%frame)     bounce into beliefs mutex
                                                           instant, but inside Atime, deterministic
```

- No ICE, no SDP, no timers measured in seconds — delivery is a `post_do` in the
  same House, so a full hello+trust round-trip completes within a step.
- The meddle hook (§14.1) sits on the mock `%active_transport` exactly as it will
  on real ones, so corruption tests written against mock port straight across.
- No timestamps written to particles, so snaps are stable with no munging.

This is the 150-line skeleton the brief asked to open with: push two frames
through each other in-process and land at `%Pier/inbox/unemit:1,done` on each
side, then at `%req:handshake,finished` on both.

---

## 16. Build order

The rung-by-rung build order and its live status are tracked in
`Peeroleum_handover.md` (the `[x]`/`[~]`/`[ ]` checklist), which has diverged from
the original static list once here: rung 4 ("per-req demand") closed as
`%ttlilt`-not-`%req:waiting` (§13), the transport trial became `Tribunal.g`, and the
rungs renumbered. The endgame rung still stands: migrate Otro, delete Peerily/
MachPeerily, rename Peeroleum → Peerily (handover heading 12).

---

## 17. Seams left open on purpose

Holes flagged, not filled, so the next reader knows they were seen:

- `// <` how thin is the Pier shim, exactly — `c.connection` plus the read/write
  of surrounding particles, but the live DataChannel's own event handlers still
  need a JS home;
   the answer is "as thin as the handlers force and no thinner",
    pinned per-transport when each transport is built.
- `// <` whether the body is fully opaque or carries a tiny `body_type:json|raw|file_chunk`;
   the envelope reserves room (`body_len`) but the spec assumes opaque for now,
    type-tells-the-receiver-how-to-read it.
- relay forwarding (websocket server, or a mutual-friend relay) — **RESOLVED**: the
   `from`+`to`-on-header design carries it; the realised relay topology is §5.
- `// <` reaping `%faulty` — currently kept until `reset_handshake`;
   if a Pier accumulates faults without disconnecting,
    a whittle on `%faulty` may be wanted, decided when rung 5 generates volume.
```
