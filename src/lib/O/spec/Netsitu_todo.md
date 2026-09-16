# Netsitu — the carriers under Peeroleum, and the WebRTC heap

*(Name floated by the owner 2026-09-16 — "Neture / Netsitu… our abstraction over any form of networking,
 including perhaps sneakernets". Rename freely; the content is what's parked.)*

## 0. What to get on with

Nothing, yet. This doc PARKS a working WebRTC carrier so it can be picked up without archaeology. The
 owner's ruling: *"leave it in a bit of a heap, no need to test, just park it in some state."* When it is
  picked up, the order is §2 → §3 → §4; the seam it plugs into (§1) is already built and proven under the
   mock.

The arc: Peeroleum's floor already selects and re-selects carriers (`%active_transport`, Tribunal); the
 relay websocket is the one live carrier; WebRTC is a black-hole mock that always loses the trial. Making
  it real means ONE port object and our own PeerServer for signalling — then two devices on one wifi
   talk directly, which is the point ("quite ideal" — owner).

## 1. The seam that exists (don't rebuild it)

A carrier is a **port**: `{ type, send(frame), recv(frame), partner? }`, an object on `.c` of a
 `%transport,type:X` particle under a Peering. The one slot the floor reads is `%active_transport`
  (`sc.type` + `c.connection` = the port): switching carriers IS `at.sc.type = X; at.c.connection = port`.
   `Ghost/N/Tribunal.g`:
- `PeerJS(peering)` — mints `%transport,type:webrtc` with a **black-hole** port (`send` drops, no ack).
- `Socket(peering)` / `Socket_real` — the websocket carrier (mock pair | real `/relay`).
- `Tribunal_hand_to_webrtc` → probe → no ack → `Tribunal_fall_to_websocket` (stamps webrtc `%faulty,
   reason:no-ack`, visible) → `Tribunal_reputation_good`. `Tribunal_redial` re-selects on a carrier-down.
- The trial is paced by Story steps under the mock; live, the app-level no-ack timeout is what catches a
   DataChannel that opens and then goes silent on a NAT rebind (PeerJS fires no event for that).

Books proving it: PereStaple steps 4–6 (trial), PereProof (heal / stall / redial). All on the mock.

## 2. The heap — what the Peerily era had working (deleted 2026-09-16, recover from git)

`git show c04544d5:src/lib/p2p/Peerily.svelte.ts` (the last commit that still has it — deleted from the tree 2026-09-16). The parts a real
 webrtc port needs, by line in that revision:

- **`Peer_OPTIONS()`** (:23–71) — `{ host, port, path: "peerjs-server", config: { iceServers, iceTransportPolicy:
   'all', iceCandidatePoolSize: 10 } }`. host/port = `location.host` (own origin; Caddy `handle_path
    /peerjs-server` strips the prefix in front of the peerjs container). **We do not need our own STUN/TURN**
     (owner): keep the four public STUN lines, drop the `VITE_PROD_DOMAIN` turn block. On one LAN, host
      candidates connect with no STUN at all — the PeerServer is only the signalling rendezvous.
- **`new PeerJS(prekey, opt)`** (:254) — the Peering IS a `Peer` keyed by our prepub, so peers dial by identity.
- **`create_Peering`** (:372–408): `eer.on('connection', con => Peering_i_Pier(eer, con.peer, con, true))`
   (inbound), `eer.on('open')` (signalling up), `eer.on('disconnected', () => eer.reconnect())`, the
    `peerfail = /^Could not connect to peer (\w+)$/` error → `Pier_wont_connect(prepub)`.
- **Dial**: `this.Peer.connect(pub, opt)` (:280–287) — returns a `DataConnection`.
- **The DataChannel as a port** (:480–660; `handle_data_etc` :602): `con.on('open')` → ready; `con.on('data', msg => unemit(msg))`
   = the port's `recv`; `con.on('close')` = carrier-down; `con.send(x)` = `send`. **Backpressure** that
    took a while to get right: `MAX_BUFFER` / `LOW_BUFFER = MAX*0.8` (:19–20, 64KB / 80%), `dataChannel.
     bufferedAmountLowThreshold = LOW_BUFFER`, `onbufferedamountlow` resumes a `send_queue`;
      `send_ready = dataChannel.readyState == "open"`. Keep this — it is what streaming audio needed.
- **The server**: `docker-compose.yml` `peerjs:` service (commented out, ~line 173): image
   `peerjs/peerjs-server`, `172.17.0.1:9995:9995`, `--port 9995`; prod has it live (`docker-compose.prod.yml`
    :65). The dev vite server has NO `/peerjs-server` proxy — add one (or point `Peer_OPTIONS` at :9995
     directly in dev).

- **The frozen Idento pool** — `src/lib/p2p/Identos.ts` + `scripts/gen-identos.ts` (deleted 2026-09-16; `git show
   c04544d5:src/lib/p2p/Identos.ts`): 100 deterministic ed25519 keypairs (`jamsend-pool-<i>`) with a friendly name
    each, meant for a round-robin `Identos_draw` so consecutive Story runs claim FRESH prepubs that PeerServer's
     name table hasn't still got registered from the last run. `Identos_draw` was never written; nothing read the
      pool. The need returns with a live PeerServer (a name collides until its lease expires) — regenerate then.

## 3. The port, in Peeroleum terms (the ~40 lines to write)

Replace `PeerJS(peering)`'s black hole:

    PeerJS(peering):
        peering i %transport,type:webrtc
        let P   = peering.c.peerjs ??= new PeerJS(peering.sc.name, Peer_OPTIONS())   // signalling
        let port = { type: 'webrtc', con: null,
            send(frame) { if (port.con?.open) port.con.send(frame) /* else: silence → no ack → trial fails, as designed */ },
            recv(frame) { H.Peeroleum_deliver(w, frame) } }
        P.on('connection', con => { port.con = con; con.on('data', port.recv); con.on('close', () => H.Tribunal_redial(peering, 'webrtc-closed')) })
        // dial: when %active_transport is handed to webrtc and no con yet → P.connect(<peer prepub>) … same handlers
        peering.o({ transport: 1, type: 'webrtc' })[0].c.port = port

Frames are already strings/bytes off `Peeroleum_send` (the envelope is carrier-agnostic), so nothing
 above the port changes. Backpressure: wrap `send` in the `send_queue` from §2 when audio rides it.

## 4. What the trial needs live that the mock never did

- A **no-ack timeout in wall time** for the webrtc probe (the mock used step boundaries). Tribunal's
   header already says this; it is the one timer the design admits.
- `Presence` and `Swarm_deliver` gate on `Presence_offline` — unchanged; the carrier is below them.
- A **`%transport` may export medium facts** (the owner's "warp ttl to suit the medium"): latency class,
   MTU, store-and-forward yes|no. Nothing reads such a thing yet; when a second live carrier exists,
    `Tribunal_redial` is where it would.

## 5. Naming (owner, 2026-09-16, undecided)

The mock wire in `Ghost/Story/PeerTesting.g` is `Lake_link / Lake_peer / Lake_port / Lake_peering /
 Lake_pier` (the carrier) plus `Lake_trial_* / Lake_storm_* / Lake_silence_* / Lake_stall_* /
  Lake_reorder_*` (the wranglers). The carrier half is a third `%transport,type:mock` in the terms above
   and could take the abstraction's name; the wranglers are test code and can stay. The `Lake*` BOOKS
    (`Ghost/test/Story/Lake/`) are Housing + compiler tests and are becoming **Hoho\*** — a different
     rename, same day, not to be confused.

## 6. Where the networking docs are (and what each owns)

The layers, bottom up — read the one for the layer you are touching:
- **carriers** (this doc) — ports under `%active_transport`; the mock wire, the relay websocket, WebRTC parked.
- **the spine** — `Peeroleum_spec.md` (frames, outbox/inbox, inseq, retx, fault, multicast; §5 is the relay
   topology, §11 the retired p2pman/p2paddy). `Peeroleum_handover.md` is its build log.
- **admission + the runner flock** — `Cluster_spec.md` (§2 trust substrate = `src/lib/cluster_trust.ts`; §3.2b the
   boot→channel map and standup guards; §3.3 Brink badges + the diagnostic ladder for "runner won't connect").
    `ClusterAddressing_todo.md` is superseded 2026-09-02 (read its ⓘ first).
- **who's on it** — `Swarm_spec.md` (identity, presence, friendship, sharing) + `Crew_todo.md` (grant-gated crew);
   `Swarm_compact_invite_todo.md`. `Social_demarcation_todo.md` is the editor|runner|player role split.
- **how to build a multi-party feature** — `Network_procedures_todo.md` (the recipe); `Networky_directions_todo.md`
   (the missing bulk/gossip pattern, an arc not a task list); `Backpressure_todo.md`.
- **the frozen editor spine** — `src/lib/pinned_stable/{Peeroleum,Tribunal}.go` (was `p2p/pinned_stable/`): the
   editor's own channel rides this copy, never the `gen/N/` it is editing — `LiesLies.svelte` names it.
