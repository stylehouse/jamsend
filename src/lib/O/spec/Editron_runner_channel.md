# Editron ↔ runner channel — an ask to the Peeroleum layer

Written from the **Lies/Editron side**. The goal: an editor edits a `.g`, a runner *runs* it and
 reports back, across two different origins (editor on `localhost:9092`, runner on the public
  `jamsend.duckdns.org`). We do NOT want to build a bespoke socket bridge — the browser↔transport
   job is what Peeroleum does for real. This file expresses what we need from Peeroleum so it can
    do **both jobs**: real peer connections (its own roadmap) *and* this editor↔runner sync. The
     editor↔runner case is the simpler one and a good first customer for the **real websocket
      transport (Peeroleum heading 10)**.

Cross-checked against `Peeroleum_handover.md` / `Peeroleum_spec.md`; notation is theirs
 (`%particle`, the one-frame envelope, `header.type`, `Peeroleum_send`/`Peeroleum_deliver`).

## The use-case in one breath

Editor (`Lies%editor`) and runner (`Lies%runner`) are two Houses on two origins. The editor is the
 **host**: its node server carries the channel endpoint. A runner **dials in when it comes alive**
  and takes instructions. The editor pushes `.g` source; the runner re-lands it, recompiles, mounts,
   runs, and ships errors/results back. "Editors own runners" = the editor hosts, runners connect.

## Topology — why this is the websocket transport, hosted on the editor's server

- **No shared storage.** The two origins do NOT share OPFS (it's per-origin; `localhost` ≠ the
   public domain). So the channel must **carry the bytes**, not poke a "re-read" — there is no
    common disk to re-read.
- **No CORS problem on the hops we use.** browser→its-own-origin server (same origin), and the
   editor-server endpoint accepting a cross-origin **WebSocket** from the runner (WS is not gated by
    fetch-CORS). So Peeroleum's `/relay` model is exactly right, with one change of address:
- **The relay lives on the editor's server, not a neutral one.** Heading 10 specs a `/relay` WS
   endpoint "on the dev server (:9091) that forwards a signed frame by `header.to` without parsing
    `body`." For us that endpoint is **the editor's node server**. Editor browser connects to its own
     `/relay` (same origin); runner connects to the editor's `/relay` (cross-origin WS). The relay
      pairs the two `.c.port`s — with one runner this is the trivial pairing already prototyped as
       `Tribunal_pair_websocket` (the in-process mock), now over a real WS.
- WebRTC (heading 9) is NOT needed here and is in fact worse for us: the PeerJS broker host is
   derived from `location.host` (`Peerily.svelte.ts:27`), so two origins register with different
    brokers and never meet. The fixed editor-server endpoint sidesteps NAT and discovery entirely.

So: **editor↔runner = Peeroleum over the real websocket transport, relay on the editor's server.**

## What we need from Peeroleum (the asks)

### 1. An app-frame dispatch seam (the main ask)

Today `Peeroleum_deliver` dispatches inbound frames by `header.type` to the hardcoded
 `hear_hello`/`hear_trust`/`noop`/`ack` handlers in the spine. We need it to route **app-defined
  types** to a **registered consumer handler** instead — so a non-Peeroleum ghost (Lies) can own a
   frame type without editing the spine.

Concretely, a registration + dispatch contract, e.g.:

  - `Peeroleum_on(type, handler)` — register `handler(w, pier, frame)` for an app `header.type`.
  - `Peeroleum_deliver`: if `header.type` is registered (and not a protocol/ack type), call the
     registered handler (an `i_elvisto` into the owning ghost is fine) rather than hear_*.
  - handler returns truthy/falsy the same way `hear_*` now do (so the inbox `verified→done|error`
     lifecycle, acks, and `%faulty` rollup all still apply unchanged).

This is the generalisation that lets **both jobs** ride the same bus: the music app registers its
 types, Lies registers `dock_push`/`run_result`. The spine stays domain-free.

### 2. A public "send an app frame to the peer" call

Expose `Peeroleum_send(w, frame)` (or the §11.3 `%req:send`) as the consumer-facing emit, so Lies
 can do `Peeroleum_send(w, { header:{ type:'dock_push', to:<peer> }, body:{…} })`. Outbox/sent/acked
  lifecycle (heading 4) applies as-is; we *want* the ack — it tells the editor the runner received
   the source. (If `%req:send` is the chosen surface, note the **c.up rule** from heading 3/4: a
    Pier-hosted req silently never pumps unless `Pier.c.up=Peering; Peering.c.up=w` is stamped.)

### 3. A connection-ready signal we can watch

Lies needs to know when the one runner is connected so the editor can push the current dock(s) and
 mark it live. The existing `%Pier … %req:handshake,finished` (or, with the handshake deferred — see
  below — just `%Pier` present with `%active_transport,open`) is enough; we'll watch for it via the
   normal C-watch. An explicit `%peer,ready` marker on the Peering would be a nicety, not a
    requirement.

### 4. The real websocket transport, editor-server-hosted (heading 10)

This channel is the **first real consumer** of heading 10. What we need from it:
 - the `/relay` WS endpoint running on the **editor's** node server (not a fixed `:9091`);
 - editor browser + runner browser both connect as WS clients; relay forwards by `header.to`;
 - `body` is opaque to the relay (it carries `.g` source / a result snap as text — fits the JSON
    envelope; binary/chunking is Peeroleum heading 7 and not needed yet).
 - **Caution:** `vite.config.server.js` still lists `socket.io` as an external and references a
    `server.ts`, but that scaffolding was half-removed — `server.js` is a bare 27-line static+health
     Express server, `socket.io` is **not installed**, `server.ts` does **not exist**. Treat the
      node-server WS layer as greenfield; don't build on the phantom.

## The frame types Lies will register

Two app types, both plain-text bodies:

  dock_push   editor → runner   body: { path, source, dige }
  run_result  runner → editor   body: { path, dige, ok, errors[], snap_dige }

`dock_push` carries the edited `.g` source. `run_result` carries the runner's compile/run outcome
 (errors when red, the produced step-snap digest when green).

## What Lies provides on its side (so you know where frames originate and land)

- **Editor emit (outbound `dock_push`).** The editor save path is `req:LiesStore_writeCarefully` →
   `write_finished=1` (`LiesStore.svelte:108,141`) — the same signal that already fires the
    in-instance Pantheate `Ghost_update_notify`. On `write_finished` **when `w%editor`**, Lies calls
     `Peeroleum_send` with a `dock_push`. (And per the Editron split, the editor compiles for local
      lint but does NOT mount — `Ghost_update_notify`/`req:include` gated on `!w%editor`.)
- **Runner receive (inbound `dock_push`).** Our registered handler does the three lines
   `LiesStore.svelte:824-829 / 923-925` already name as the future "inotify backend":
     `good = LiesStore_good(wLies,'text/Doc',path)`
     `LiesStore_land_good(good, { content: source })`   // sets c.content, re-digests /known
     `LiesStore_drain_good(good)`                        // re-pushes to Lang's furnishing subscriber
   Lang's subscriber re-fires → recompile → because it's `w%runner`, it mounts + runs. **No new
    pipeline on our side** — Peeroleum's delivered frame feeds the drain the spine already has.
- **Result home (outbound `run_result`).** The runner's compile/run outcome (already threaded
   in-instance via `Codebit%of_dock`) goes back as `run_result`; the editor's handler re-attaches it
    to its `Codebit%of_dock` so the staging chrome lights up.

## Deferred for v1 (explicitly out of scope now)

- **Security, not identity.** A runner **has an `Id`** (an Idento identity — it's a peer like any
   other, so its Peering/Pier are already keyed by that Id). What's deferred is **trust
    *enforcement*** around it: for now **accept the one runner that connects, trusted implicitly** —
     the hello/trust handshake can run in trust-everything mode (or be skipped). Verifying `%Ud`
      against a known/allowed set, per-runner authorisation, and `Thangs` persistence of who's
       allowed (heading 11) are future. One editor, one runner (with its Id), one channel.
- **Many runners / addressing.** Multi-runner fan-out (a `dock_push` per connected runner over a
   list) waits on the trust/authorisation story above; with one runner, `header.to` is just its Id.
- **UIless runner.** The runner is a **dev browser tab** for v1, not a no-browser node runner —
   Peeroleum heading 1b and the Editron handover both note a UIless run can't yet mount a fresh
    `.go` (the gen UI never mounts → include times out). The channel is identical either way; only the
     last hop (which House terminates it) changes when 1b lands.

## Summary of the request

1. Generalise `Peeroleum_deliver` to dispatch app `header.type`s to registered consumer handlers
    (`Peeroleum_on`), keeping the inbox/ack/faulty lifecycle.
2. Expose `Peeroleum_send` (or `%req:send`) as the consumer emit.
3. A watchable "peer ready" signal (the existing `%Pier`/handshake state is fine).
4. Stand the real websocket transport (heading 10) on the **editor's** node server; editor↔runner is
    its first customer. Mind the half-removed `socket.io` scaffolding — it's greenfield.

With (1)+(2) Peeroleum becomes a named message bus that both the music app and Lies plug into — same
 envelope, same transport selection, same acks — which is what lets it do both jobs.
