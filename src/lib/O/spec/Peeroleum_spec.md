# Peeroleum spec

The nailed-down design for retiring `Peerily.svelte.ts` (+ `MachPeerily.svelte`)
and growing `Peeroleum.svelte` (+ `MachPeeroleum.svelte`) in their place.

This is a spec, not a sketch. Where the brief said "sketch, not law", this says
law — every particle, every state, every transition is pinned down. Code comes
after; this is the thing code is checked against.

The first thing built against this spec is the `%transport,type:mock` spine: two
sides come up under one House, exchange hello+trust as particles only, and land
at `%req:handshake,finished` on both. No real network, no corruption, no binary.
If that compiles and the snap is clean, everything else is filling in.

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
> trust, data, binary — is one signed envelope. Reqs are unified on `%req` and a
> req that waits says so by spawning a throwaway `%req:waiting` that carries its
> demand for time, droppable by its parent. The Mach choreography survives; it
> queries particles instead of polling booleans.

---

## 2. Actor hierarchy

Three kinds of House-worker, plus the storage workers.

```
A:Peerologist                                    the manager — its own clean A
  w:Peerologist
    %req:p2pman                                  brings Peerings up per our desire to appear online
    %sides,N:[Alice,Bob,Mallory]           (test only) single source of side names
    %witnessed,step:N                            (test only) was the step's expected event seen
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

`reqy()` is unchanged in mechanism (see `Hovercraft.svelte`). What changes is that
*everything* uses it with the default mainkey `req`, and desires nest under desires.

### 3.1 Nesting via req/*req

A desire with children is driven by `handler_of_last_resort`: when a `%req` has
its own `%reqcons`, `do_one` finds no explicit `do_fn` and instead does each
`req/*req` recursively, finishing the parent when all children finish.

```
%req:handshake                                   the desire (has children → recursion drives it)
  %reqcons                                        protocol bucket (reqy bookkeeping)
    %reqcon:req,serial_i:…
  %req:said_hello,maz:4                           leaf work items
  %req:heard_hello,maz:3
  %req:said_trust,maz:2
  %req:heard_trust                                last → finishing it finishes %req:handshake
```

`maz` orders the leaves: highest maz runs first, lower maz gated behind it
(`do()` filters to the highest unfinished maz). So heard_hello (maz:3) can't run
until said_hello (maz:4) is finished, and so on down to heard_trust (no maz = 1).

### 3.2 The waiting-req (per-req demand for time)

This is the mechanism the brief asked for and §13 details. The shape:

A leaf `%req` that cannot finish yet does **not** itself hold demand (it will
finish, and a finished req must not pin time open). Instead it spawns a throwaway:

```
%req:heard_hello,maz:3                            the waiting work item
  %req:waiting,for:heard_hello,until:T            throwaway — carries the demand
```

- `%req:waiting` is the *client* of the demand. While it exists with `until:T` in
  the future, the global `leave_running_until` is at least `T`.
- The parent (`%req:heard_hello`) drops `%req:waiting` the moment hello is heard,
  **or** when it decides to give up — either way the demand vanishes with it.
- Cancelling your own demand = dropping your own waiting-req. No global mutation,
  no race: the global is recomputed each poll as the max `until` over all live
  `%req:waiting` anywhere in the tree (§13).

A req can have at most one live `%req:waiting`; re-running its do_fn while still
waiting bumps `until` on the existing one (or leaves it; see §13 on initialdo).

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

## 5. (reserved)

*(Section numbering kept stable with the brief; transport selection logic is in §4.1
 and §11.)*

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
                       else -> spawn|keep %req:waiting,for:said_hello (demand)
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

---

## 9. faulty + reset_handshake

`%faulty` is a roll-up, present only when there is something to roll up.

```
%Pier,pub:mallory…
  %faulty
    %unemit:N,error:not-them,seq:3                  the actual failed inbox item, hoisted
    %unemit:M,error:invalid-signature,seq:4[,claim:step_5]
```

`claim:step_N` is the Mach mechanism (§14) stamping which step expected this fault.

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

### 11.1 %req:p2pman — appear online

```
A:Peerologist/w:Peerologist
  %req:p2pman                                       top desire: be online per our identities
    %req:init                                        one-time wiring (on_hangup, side names)
    %req:bring_up,prepub:7acf…                       one per identity-thang with online_want
      %req:waiting,for:peering_open,until:T          throwaway demand while the Peering connects
```

`%req:p2pman` reads `w:Thangs,thangs:identities`. For each `online_want` identity
it seeds a `%req:bring_up` whose do_fn ensures `A:<side>/w:Peeroleum/%Peering`
exists and its transport is open. `%req:bring_up` finishes when the Peering is
`%open`; until then it carries a `%req:waiting`.

### 11.2 %req:p2paddy — manage this Peering's Piers

```
A:Alice/w:Peeroleum
  %Peering,name:alice,prepub:7acf…
    %req:p2paddy                                     desire: maintain Piers per known-peers
      %req:dial,target:8cbc…                          one per peer we want connected
        %req:waiting,for:connected,until:T
      %req:transport_select                           try webrtc, fall back to websocket
        %req:waiting,for:webrtc_open,until:T          dropped on open OR on fallback decision
```

`%req:p2paddy` reads `w:Thangs,thangs:peerings`. For each known peer it seeds a
`%req:dial`. It also owns `%req:transport_select`, which seeds `%transport,type:webrtc`,
waits, and on timeout seeds `%transport,type:websocket` and points
`%active_transport` at it (leaving webrtc present-and-`%faulty`).

### 11.3 per-Pier desires — handshake and sends

```
A:Alice/w:Peeroleum
  %Peering,name:alice,prepub:7acf…
    %Pier,pub:8cbc…
      %req:handshake,target:8cbc…                     §8 — the round-trip
      %req:send,type:data,seq:S                        a thing we want on the wire
        %req:waiting,for:acked,until:T                 dropped when %outbox/emit:S is %acked
```

A `%req:send` is how the new world replaces `ier.emit()` poking. To send, seed a
`%req:send`; its do_fn writes a `%outbox/emit:N`; the transport ferries it; the
ack stamps `%acked`; the waiting-req drops; `%req:send` finishes.

State flows up the same hierarchy as exports (§12): a Pier's `%faulty` can hoist
to its Peering, a Peering's open-count to p2pman, so each tier sees a summary of
the tier below without reaching into it.

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
    hoist Pier exports (see 12.2)
```

This is the only place outbox/inbox items vanish, so the snap *before* this
boundary always shows the send/receive that happened during the step. That is the
"capture important moments before carrying on" the brief asked for.

### 12.2 Hoisting exports

`reqy.do` already hoists `%aim` from `req` to `w`. Generalise: a particle may
declare `%exports` it wants lifted to its parent for legibility.

```
%Pier,pub:8cbc…
  %faulty …                                            present -> export a summary up
-> at boundary ->
%Peering,name:alice
  %pier_faulty,pub:8cbc…                               hoisted summary, so Peering shows trouble
```

Exports are *summaries*, not moves — the detail stays on the Pier; the parent
gets a flag. p2pman thereby sees "some Peering has a faulty Pier" without walking
every Pier each tick.

### 12.3 Munging times

Where a real run writes `header.time` or `last_seen` into a particle that reaches
a snap, the boundary munges it to a stable token before the dige is computed
(e.g. replace any `time:<wallclock>` with `time:~` in the snap codec, keeping the
live value on `c` for behaviour). Mock runs avoid times entirely, so their snaps
are naturally stable; real runs are stable after munging. The brief accepted this:
"we'll have to."

### 12.4 want_savepoint and %waits_savepoint

A req may declare `%req:…,waits_savepoint:1`. When its do_fn makes the progress
it was waiting to record (e.g. `%req:send` stamps `%outbox/emit:S,sent`), the
do-loop calls `H.want_savepoint()` — zeroing demand so Story snaps *now*, before
the next boundary culls the just-sent item. So a send is guaranteed at least one
snap-frame of visibility even if its ack arrives in the same Atime.

```
%req:send,type:hello,waits_savepoint:1
  do: write %outbox/emit:N,sent
      H.want_savepoint()        -> Story snaps -> boundary culls -> %outbox/recent
```

---

## 13. Per-req demand for time (the waiting-req, in full)

The old `demand_time_to_think(ms)` mutates one global `H.c.leave_running_until`,
extend-only, with `want_savepoint()` the only (sledgehammer) cancel. The new
model: demand is owned by throwaway `%req:waiting` particles; the global is a
*computed max*, never directly mutated by waiters.

### 13.1 The waiting-req

```
%req:heard_hello,maz:3                              a leaf that may need to wait
  %req:waiting,for:heard_hello,until:T              throwaway; T = now + this phase's ms
```

- `for:` is a label for the snap ("what are we waiting on").
- `until:` is wall-clock seconds; the demand this waiter contributes.
- At most one `%req:waiting` per parent req.

### 13.2 The computed global

`poll_step` (in `Story.svelte`) computes, each tick:

```
leave_running_until = max( until of every live %req:waiting anywhere under Run )
                      , falling back to 0 if none
```

- A waiter extends time by *existing* with a future `until`.
- A waiter cancels its demand by being *dropped* — if it held the max, the global
  drops to the next-highest automatically. No write-write race: dropping removes
  from the set the max reads from; there is no shared mutable number to clobber.
- Two waiters racing (one drops, one extends) resolve cleanly: the max is taken
  after both edits land, because it is recomputed, not incrementally maintained.

### 13.3 initialdo and not extending forever

The MachPeerily lesson (don't re-extend on every heartbeat tick) becomes: a
waiting-req sets `until` **once**, when first created (the parent's `initialdo`
pass). Subsequent do_fn runs while still waiting *leave `until` alone* — so the
deadline genuinely elapses on failure and the step can end. Only a fresh phase
(a new waiting-req for a different `for:`) sets a new `until`.

```
first run (initialdo):  spawn %req:waiting,for:heard_hello,until: now+0.8
later runs (waiting):    %req:waiting already there -> do not touch until
hello heard:             parent drops %req:waiting -> demand gone
gave up / other settled: parent drops %req:waiting -> demand gone, gap recorded
```

### 13.4 reqy as the demand client

This is the brief's "reqy() should be the %client for a demand for time, so they
can cancel their own demand". Realised: the reqy do-loop, when a leaf cannot
finish, owns the spawn/keep/drop of that leaf's `%req:waiting`. The leaf never
touches the global; it only manages its own throwaway. Cancellation is local and
safe by construction.

---

## 14. Mach layer (MachPeeroleum) — observing particles

The Mach pattern from `MachPeerily` survives almost unchanged: `on_step` table,
per-step force-finish-prior, the witness flag, `expected_error` + `claim:step_N`,
the `meddle_fn` mechanic. What changes is *what it observes* — particles, not
booleans through `.c.inst`.

### 14.1 What stays

```
on_step({ 1:…, 2:…, 4:…, 5:… })                    step choreography table (unchanged shape)
force-finish prior step's %req before seeding next  (unchanged)
%witnessed,step:N                                    the witness flag — now a particle on the mgr w
expected_error + claim:step_N                        stamps which step expected which %faulty
%req:emit_corruption (was %De:emit_corruption)       eternal; swappable meddle child
```

The witness flag moving from `H.c._pl_step_error_witnessed` to a particle
`%witnessed,step:N` is the §8-style win applied to the test harness itself: the
step-witnessing shows up in the snap diff like everything else.

### 14.2 Meddle attaches to %active_transport

```
A:Peerologist/w:Peerologist
  %req:emit_corruption,target:Mallory,eternal
    %req:wrap                                        install the meddle hook on Mallory's active_transport
    %req:N,corruption:publicKey,meddle_fn:Function   the live lie; re-arm latest-onlys it
```

The wrap installs a hook on `%active_transport` (not `Pier.emit`). On every
`send`, the transport reads the live `meddle_fn` from the corruption req and
applies it to the frame post-sign. Because it sits on the transport, the same
corruption test runs under mock, webrtc, or websocket — the meddle perturbs
whatever is carrying.

```
Mallory send path:
  build frame -> sign header -> [meddle_fn(frame)] -> active_transport.send(frame)
                                  ^ reads %req:emit_corruption/%req:N/meddle_fn live
Alice inbox:
  %unemit:N,handling -> verify fails -> %unemit:N,error:invalid-signature
                                          -> hoist to %faulty,claim:step_5
```

### 14.3 Reading state — existence, not polling

Old: `Pier_n.c.inst.said_hello` (escape hatch into JS). New:
`Pier_n.o({protocol:1})[0].o({hello:1})[0].oa({said:1})` — particle existence.
Every Mach assertion is a `q.o(...)` on the right particle. The `De_handshake`
target filter that was fixed last week stays, but it is now "does
`Pier/protocol/hello/%said` exist on the Pier with this `pub`", a structural
query.

### 14.4 Step opts gain transport

```
on_step(2): happy-path hello+trust under type:mock
  seed %req:handshake on both sides ; mock delivers instantly ; both reach finished
on_step(4): Mallory dials Alice, meddle publicKey -> Alice %faulty,error:not-them
on_step(5): meddle sign -> Alice %faulty,error:invalid-signature
```

A step opt `transport: mock|webrtc|websocket` lets the same step sequence run
under different transports — the cross-product the brief wanted (corruption ×
message-type × transport).

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
- The meddle hook (§14.2) sits on the mock `%active_transport` exactly as it will
  on real ones, so corruption tests written against mock port straight across.
- No timestamps written to particles, so snaps are stable with no munging.

This is the 150-line skeleton the brief asked to open with: push two frames
through each other in-process and land at `%Pier/inbox/unemit:1,done` on each
side, then at `%req:handshake,finished` on both.

---

## 16. Build order

Strict order; each rung must snap clean before the next.

```
1  mock transport spine
     %transport,type:mock ; shared-queue delivery ; one frame A->B delivered
2  hello+trust under mock
     %req:handshake on both sides ; both reach finished ; clean snap   ← MachPeeroleum on_step(1|2)
3  outbox/inbox lifecycle + acks + whittle
     %emit/%unemit states ; serial handling ; boundary cull ; %recent tails
4  per-req demand (waiting-reqs) replacing global demand
     %req:waiting ; computed-max global ; initialdo-once ; want_savepoint
5  corruption tests (re-use meddle, now on %active_transport)
     on_step(4) publicKey -> not-them ; on_step(5) sign -> invalid-signature
6  binary frames (body + body_hash) folded into the envelope
     test_binary as just-another-frame ; corruption identical to hello-sign
7  disconnect + reset_handshake
     %active_transport e:close -> reset ; p2paddy re-dials ; phases re-run
8  webrtc transport alongside mock
     %transport,type:webrtc ; tries, may go %faulty,reason visibly
9  websocket fallback (separate relay endpoint)
     %req:transport_select fall-through ; %active_transport switches
10 Thangs persistence wired
     identities + peerings thangs drive p2pman + p2paddy
11 migrate Otro over ; delete Peerily ; rename Peeroleum -> Peerily
```

Rungs 1–4 are the spine and the riskiest (they prove particle-only state +
per-req demand actually work). If they reveal friction it is cheap to find here.
Rungs 5–7 are re-applications of patterns that already worked in MachPeerily.
Rungs 8–11 are real-world transport and cleanup, each its own session.

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
- `// <` the relay forwarding case (websocket server, or a mutual-friend relay) —
   the `from`+`to`-on-header design supports it,
    but the relay endpoint itself is rung 9, deliberately not specified here.
- `// <` whether `%req:waiting` should carry `for:` only or also a small reason
   when it gives up;
    leaving it `for:` until rung 4 shows whether give-up needs its own record.
- `// <` reaping `%faulty` — currently kept until `reset_handshake`;
   if a Pier accumulates faults without disconnecting,
    a whittle on `%faulty` may be wanted, decided when rung 5 generates volume.
```
