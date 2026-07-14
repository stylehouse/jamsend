# Radio_multicast_todo.md — opportunistic WebRTC swarm chunk-sharing

Unblessed exploration (`_todo`, not `_spec`): the concrete design for the layer Radio_spec calls
 **Stretch** (stage 9) and **Mesh** (stage 8) once they stop being deterministic single-runner models
  and start moving real chunk bytes over real webrtc edges. Nothing here is built. This doc is the
   destination + the bombs + the ordering; the human promotes it to spec only after a preen.

The one sentence: **content-addressed audio chunks route along the cheapest edges — a peer who
 already holds segment N serves it to a peer who wants it over a webrtc data channel, and the relay
  uplink is crossed once, not once-per-listener — while grants still gate every byte and every chunk
   is verified by hash before it is trusted.**

---

## 0. What to get on with next

Nothing is built yet — this is a plan, not a landing. The **first rung is P1 (§7): advertise held
 chunks** — a peer publishes, as a compact bitmap over an `@channel` claimed per-track, WHICH
  `(enid, seq)` chunks it holds. It writes no serve path and no data channel; it is pure presence
   gossip riding the multicast primitive that already exists (`Peeroleum_publish` / `Peeroleum_subscribe`,
    Peeroleum.g:277/269). It is Book-gateable on **one** runner (a peer advertises, a second in-process
     Peering under the same `w` reads the fan-out — the same in-process multiplication `Peeroleum_deliver`'s
      channel branch already does, Peeroleum.g:417). Everything below P1 is a real-transport / 2-runner
       rung and must wait behind it.

**The load-bearing precondition** (get this right or the whole thing is sand): content-addressing must
 be **real end-to-end**. Today a chunk is addressed by `(track enid, seq)` — a pair, NOT a standalone
  content hash (Ra.g `Ra_enid` at :454 hashes the *whole source file* to 16 hex chars; a chunk has no
   independent digest, only a position `seq` under that enid). That pair is enough to ADDRESS a chunk in
    a swarm — but the swarm can only TRUST a served chunk if it can verify the bytes, and per-frame
     integrity today pins the *repli_page frame body* (`Peeroleum_body_digest`, Peeroleum.g:186), not a
      canonical *per-chunk* hash a wanting peer could pre-know. **Decide before P3 (serve): does a chunk
       get its own `sha256` (a real content id, so any holder's copy is byte-verifiable against a hash
        the wanter learned from a trusted source), or do we keep verifying the transport frame and lean
         on the origin-signed catalog for the chunk's identity?** The whole swarm's safety hinges on this;
          §5 lays out the choice, and it is the first thing to settle.

Candidate directions, cheapest-value-first: (a) P1 advertise — pure win, one runner; (b) the per-chunk
 hash decision above; (c) P2 discovery — a wanter picks a nearer holder off the advertised bitmaps
  using the real cost model (Mesh.g `Mesh_route`, :41). Do NOT batch these; each is a Book.

---

## 1. The model — swarm chunk-sharing as cheapest-edge routing

Radio_spec §1 already frames the whole platform as **one replicated `C**` sync with edges between the
 replicas, each edge a `cost` and a `kind`** (`peer` = webrtc, cheap, local; `relay` = the uplink,
  costly), and states the bet outright: *"content routes along the cheapest edges, not always back
   through the relay."* This layer is the concrete realisation of that sentence for audio chunks. It is
    not a new framing — it is the fill for a hole the platform doc already cut.

**The routing is already modelled, deterministically, in `Ghost/M/Mesh.g`.** That file holds the REAL
 algorithms the live system will use, exercised on a mock (no sockets) so the policy is single-runner
  testable:
- `Mesh_route(graph, from, to)` (Mesh.g:41) — Dijkstra cheapest path over edge costs; returns
   `{path, cost, relays}` where `relays` counts the RELAY-kind hops (the uplink cost).
- `Mesh_broadcast_naive(graph, source)` (:90) — the un-stretched baseline: every client independently
   pulls from source, so a relay-only source's uplink carries the content **N times**.
- `Mesh_broadcast_stretch(graph, source)` (:113) — THE STRETCH: a minimum-cost broadcast tree (Prim,
   cheapest connecting edge). Because a webrtc peer-edge is far cheaper than the relay, once ONE cafe
    client has the content over the relay the rest receive it over webrtc — the relay edge is crossed
     **once**, and the multicast domain "stretches" over the peer edges.
- `Mesh_cafe_spec(clients)` (:145) — the canonical case: a relay-only SOURCE behind NAT, N clients each
   with a costly `relay` edge to source AND cheap `peer` edges to each other. `RELAY_COST=10`,
    `PEER_COST=1`; feeding it to naive vs stretch shows the uplink carrying content N× vs 1×.

So the *policy* exists and is proven green. What this doc designs is the **transport realisation**: how a
 real peer advertises what it holds, how a real wanter discovers a nearer holder, how the bytes actually
  cross a webrtc data channel, and how all that rides Repli's existing pull/page machinery instead of a
   parallel stack.

### 1.1 Content-addressing is the enabler

The reason a swarm CAN share is that a chunk is content-addressed: whoever holds `(enid, seq)` holds a
 byte-identical thing, so any holder is an equivalent source. From Ra.g:
- **`Ra_enid(raw)`** (Ra.g:454) — `sha256` over the *whole source file's* bytes, first 16 hex chars. This
   is the track's sole content identity (`rec.sc.id`, Ra.g:609). It contains no pub and no path, so *the
    identity moves with the bytes* — the property a swarm lives on.
- **A chunk is addressed by `(enid, seq)`** — a `%Preview,seq` or `%Stream,seq` child of the `%Record`,
   `seq` a string, ONE seq space across the preview→stream boundary (first `%Stream,seq` = last
    `%Preview,seq` + 1). Preview is the cached window (≈16 chunks = 32s ÷ 2s/seg, Ra.g `Ra_preview_secs`
     :64); Stream is the continuation, minted on demand as `Ra_transcode_advance` runs.
- **Presence IS fill state.** A chunk's bytes ride its `.sc.buf` (a `Uint8Array`); the snap encoder mutes
   that to a ~12-byte description, so the *presence* of the particle-with-bytes sits on the observable
    plane while the weight stays off it. There is no `have=` counter to keep honest — a peer holds exactly
     the segments whose particle carries a buf (`Repli_chunk_bytes`, Repli.g:77; `Repli_chunk_at`, :88).

**The corollary the swarm needs:** a peer's *inventory* is a set of `(enid, seq)` it can enumerate by
 walking `rec.o({seq:1})` and keeping those with bytes. That set is exactly what P1 advertises.

### 1.2 The document-vs-blob-store split (the human's frame)

Requesting and responding to audio is the **magazine (`%Mag`) request/response** mechanism, at every
 granularity *down to the chunk*: a want is a `%Mag` of wants; a response is a `%Mag` carrying pointers
  to chunks. But the persisted magazine document and the chunk blob store are **separate layers**, and
   multicast lives at the lower one:

- **The document plane** — the enWaft'd `%Mag` / `%Cloud` / `%Card` carries *cards*: pointers (id, enid,
   metadata), never chunk buffers. `Repli_offer` ships a Record's **husk** (`{husk:1}`, Repli.g:284) —
    head + non-buffer children — precisely so "a catalog card stays a card however much stock stands
     behind it." This plane is where interest, recommendation, and the knowledge graph live; it is
      origin-signed and consent-gated at the card level.
- **The blob plane** — the chunk bytes live in a content-addressed, rebuildable store (Ra's radiostock
   file `<ts>-<pub>-<enid>.jamsend_radiostock`, Ra.g `Ra_stock_name` :429 — a JSON header line then the
    preview bufs back-to-back; stream chunks re-transcode on demand from `rec.c.pcm`). Because it is
     content-addressed and rebuildable, it is **the thing a swarm shares**. Multicast is a blob-plane
      concern, below the document.

**Cursors resolve all the way down to the chunk.** A `%Dogear` cursor (a stack of matches) is the
 universal "what I'm interested in" pointer, magazine → cloud → card → down to a specific `(enid, seq)`.
  "What I want" is a set of chunk-granular cursors. This is the tie-in that makes swarm-sharing pay: a
   listener's interest goes **wide, not deep-ahead** — they preview/browse many tracks at once rather
    than racing one playhead forward — so chunk-interest across a swarm OVERLAPS heavily (many peers want
     overlapping chunk sets). Heavy overlap is exactly the regime where a peer already holds what its
      neighbour is about to want. The wide-interest pattern is not incidental; it is *why* the peer edges
       carry their weight.

---

## 2. The mechanics

### 2.1 Advertise — who holds which chunks

A peer that holds chunks of a track publishes an **inventory beacon** onto a per-track topic, using the
 multicast primitive already built (Peeroleum §18, Peeroleum.g / relay.ts):
- The topic is an `@channel` derived from the track: `@chunks/<enid>` (an `@`-prefixed `to`, the topic
   sigil). `Peeroleum_claim(w, peering, channel)` (Peeroleum.g:258) reserves the name; `Peeroleum_subscribe`
    (:269) joins the fan-out; the relay's `bind(@channel, ws)` (relay.ts:338) makes the subscribe set
     reuse the existing `deliverLocal` fan-out with zero routing change.
- The beacon body is a compact **have-bitmap** over the seq space (`{enid, base, bits}`), fire-and-forget:
   `Peeroleum_publish(w, peering, channel, 'chunk_have', body)` (Peeroleum.g:282) books no outbox emit,
    expects no ack, carries its own per-channel seq (`peering.c.chan_seq`) so a subscriber can later detect
     a gap. No ack means no ack-storm — the same reason §18 chose publish for bulk.
- Presence is enumerable from the tree: walk `rec.o({seq:1})`, keep those where `Repli_chunk_bytes` is
   non-null, set that bit. This is the observable-plane inventory of §1.1 turned into a bitmap.

A subscriber accumulates a **holder map**: for the tracks it cares about, `{ (enid,seq) → [peer prepub…] }`,
 rebuilt from arriving beacons and pruned when a peer goes offline (the same presence gating Ra.g already
  uses via `w.c.ra_source_live`, Ra.g:1228 — a hook that answers "is this source still connected"). The
   holder map is `.c` runtime state, never snapped.

### 2.2 Discover — a nearer holder vs the origin

When a wanter needs `(enid, seq)` (a chunk-granular cursor resolves to a page it lacks), it chooses a
 SOURCE before it pulls:
1. Look up holders of `(enid, seq)` in the holder map (§2.1).
2. For each candidate (including the origin/relay path), score with the real cost model: build the local
    edge graph and run `Mesh_route(graph, me, holder)` (Mesh.g:41) — a webrtc `peer` edge to a nearby
     holder scores far below the `relay` uplink to origin. The graph is small (a cafe, not the internet),
      so the linear Dijkstra is plenty.
3. Pick the cheapest reachable holder. If it is a peer, PULL from that peer (§2.3). If none, or the peer
    fails, fall back transparently to the origin/relay (§3).

This is the concrete `Mesh_broadcast_stretch` decision made per-chunk at pull time: each wanter receives
 from its cheapest already-reached neighbour, so once one cafe client has a chunk over the relay the rest
  get it over webrtc.

### 2.3 Carry the bytes — a webrtc data channel, riding Repli's pull/page

The bytes cross **Repli's existing machinery**, not a new one. Repli already streams a `C**` of scalars +
 buffers page by page over the Peeroleum spine (Repli.g header, :1–53), and the transport under it is
  carrier-swappable (mock / websocket / **webrtc data channel** — the carrier lives in Tribunal.g, the
   spine keeps only the envelope, Peeroleum.g:330). So a peer-to-peer chunk pull is a Repli pull whose
    active carrier for that Pier is a webrtc data channel:

- The wanter sends `Repli_want_next(w, rx, from, to, enid, stream, fromIdx)` (Repli.g:542) — a `repli_want`
   frame — to the **holder peer**, not the origin. The only change from today is *who* `to` addresses.
- The holder serves via `Repli_serve_want` → `Repli_serve_chunks` (Repli.g:376 / :420): it takes the
   fixed-stride page `[from, from+PAGE)`, lifts each chunk's binary `.sc.buf` into the bufmap
    (`Repli_lines_of`, :102), and ships a lean fragment — a `repli_lines` frame (identity + one line per
     chunk, each promising `objecties.buffer=<id>`) followed by one `repli_page` frame per buffer
      (`Repli_send_lines`, :229). Per-frame `sha256` (`Peeroleum_body_digest`) pins each chunk's byte
       identity on the wire.
- The wanter's receive path is unchanged: `Repli_recv_lines` merges the fragment into its mirror and opens
   an `awaitbuf` req per promised buffer (Repli.g:451); `Repli_recv_page` stashes the arriving bytes and
    `Repli_attach_page` restores them AS the chunk's `.sc.buf` — the mirror chunk becomes real the moment
     its bytes land, presence-is-fill-state (Repli.g:495). The served-and-landed `awaitbuf` then drops
      (:523) so the snap doesn't fill with dead reqs.

**The key insight: a peer is just another Repli source.** `Repli_register_caster(w, pier, lib)`
 (Repli.g:255) already enrolls a serving Pier with the library it casts FROM, and N casters + N wires
  into one listener already coexist in one `w` (`Repli_arm` disambiguates by which Pier a frame arrived
   at, :548). A wanting peer chasing many sources holds many rx Piers all landing into one mirror library
    (`w.c.repli_mirror_pier`, :262). The swarm is `Repli_register_caster` pointed at a **peer's** shelf
     instead of the origin's — the pull/page/park/serve code is untouched. What is NEW is only §2.1
      (advertise) and §2.2 (choose the source).

**The `stream_offer` handover** (Peeroleum.g `Peeroleum_offer_stream` :299 / §18) is the seam where a
 unicast Repli stream becomes a multicast one: an established Pier hands the peer a stream *pointer* (the
  `@channel` to subscribe to) over the trusted per-Pier link, and thereafter the bulk fans out. For P4
   (§7), the caster publishes each page ONCE onto `@chunks/<enid>` and every subscribed wanter receives
    it — the true multicast stretch — while the per-Pier handshake/trust stays 1:1 so the caster still
     knows *who* each subscriber is (the consent gate needs that, §4).

---

## 3. Opportunistic fallback — degrade honestly, never stall

The whole layer is *opportunistic*: peer edges are a cost saving, never a correctness dependency. The
 origin/relay path is always the floor.

- **No peer holder → origin.** If §2.2 finds no reachable peer holding `(enid, seq)`, the wanter pulls
   from the origin exactly as today (`Repli_want_next` addressed to the origin Pier). No swarm, no change.
- **Peer serve fails or is slow → origin.** A peer pull is a Repli pull, so it already inherits Repli's
   healing: the promised buffer opens an `awaitbuf` that WARNS if overdue (`Repli_awaitbuf_do`, :528), and
    the underlying transport re-transmits un-acked frames (Peeroleum `retx_sweep` / Reliable.g `retx_due`).
     A peer that goes silent trips the inbound-silence liveness sweep (`Peeroleum_liveness_sweep`, :708).
      The fallback rule: once a peer pull is overdue past a small budget (a couple of `awaitbuf` warns), or
       the holder drops off the holder map (presence gone), **re-issue the same want to the origin**. The
        want is idempotent — the mirror UPSERTs by `(Record id, seq)` — so a duplicate answer from origin
         and a late peer answer reconcile to the same bytes.
- **Never block on the swarm.** A wanter must not hold a playhead waiting for a peer that might have the
   chunk. The origin request is issued in parallel or on a short timer, whichever the Glide/LiveEdge
    coverage budget can afford (Radiola.g controllers, Radio_spec §4) — the swarm is a *race the origin
     might win cheaply*, not a gate. The `coverage` metric (uncovered playback time, Radio_spec §4) is the
      wreckage the fallback exists to prevent; a stall is worse than a wasted relay byte.
- **Fallback is a first-class Book claim** (§6): the adversarial control is a swarm where the peer holder
   is a liar or a black hole, and the assertion is that the audio still arrives (from origin) with zero
    coverage gap.

---

## 4. Consent — grants gate forwarding

Chunk-sharing must not become a consent bypass. **Forwarding a chunk to an ungranted peer is a leak** —
 the foundational rule (Heist.g:16). The existing consent seam is exactly the right shape and this layer
  must ride it, not route around it.

- **The gate is `Repli_allowed(w, peer, at)`** (Repli.g:248): open only when no predicate is wired,
   else exactly what `w.c.repli_allow(peer, at)` answers for that peer — *asked at EVERY leg, cached
    nowhere*, so a grant revoked between two wants shuts the second one. `at` names the SERVING side (its
     prepub), because in a multi-caster world one hook must answer per-relationship. This is precisely a
      swarm: every peer is a potential caster, so the two-argument form is load-bearing.
- **Liveness is grant ∧ ¬tombstone.** `Swarm_pier_live(pier, feature)` (Swarm.g:555) returns true iff a
   `%Grant,<feature>` child exists under the Pier AND no matching `%NotGrant` overrides it. The Feature is
    `%Music` — the permission every Idzeug invite grants; receiving it *is* becoming a Pier (Swarm_spec
     §6.1). The Book wires it in: `w.c.repli_allow = (peer) => { let p = …Pier,pub:peer; return
      Swarm_pier_live(p,'Music') }` (Radiation.g:128). Repli never imports Swarm — the hook is the seam.
- **The tombstone is durable and negative.** A `%NotGrant` (`mint_revoke`, Swarm.g:548) is a signed
   negative-decision-fact kept *under the Pier it revokes*, never dropped by GC — because absence is
    ambiguous and `Swarm_pier_live` queries for it every time. If GC dropped a `%NotGrant`, an unfriended
     peer's grant would appear live again and a peer could re-serve it a chunk — a silent leak. **A swarm
      GC must never drop a tombstone** (memory: revocation-tombstone-durable).

### 4.1 How a grant travels with a peer-to-peer serve

The signed grant does NOT ride on the chunk. Instead **the serving peer checks the grant at its own
 origin before the bytes cross**: every `Repli_offer` (Repli.g:283) and every `Repli_serve_want`
  (:380) already calls `Repli_allowed(w, h.from, h.to)` first — a peer serving a chunk asks "is the
   *asking* peer live-granted for this content, from *me*?" and stays silent otherwise. Because the check
    is at the serving side and per-leg, a swarm forwarder cannot serve to an ungranted peer even if a
     THIRD party told it the peer wanted the chunk. The `@channel` subscribe set (§2.3) is the bulk
      carrier, but the per-Pier handshake stays 1:1 (Peeroleum §18) precisely so the caster can run
       `Repli_allowed` per subscriber before it publishes a page — a subscriber the hook refuses is never
        offered the `stream_offer` pointer, so it never joins the fan-out.

### 4.2 The known leak this layer MUST NOT inherit — and must close

There is a standing, un-asserted consent gap (memory: repli-send-lines-consent-gap, found 2026-07-14):
 `Repli_send_lines` (Repli.g:229) does **not** consult `Repli_allowed` — it unconditionally
  `Peeroleum_send`s — and `Musica_recast_offer` (Heist.g:706/:720) calls it DIRECTLY for goner deletes.
   So the gate is **asymmetric**: you revoke a follower, then drop a record at the origin, and the
    `op:delete` line *crosses to the revoked follower and mutates their mirror*, past a closed gate. The
     wire refuses to ADD to a revoked peer but will still DELETE from their mirror — a revoked peer's held
      copy should be frozen, not remotely editable.

For a swarm this is worse, not merely equal: a swarm multiplies the number of relationships and the
 number of `Repli_send_lines` call sites, so a delete-after-revoke has many more places to leak. **This
  layer must gate every wire emission on `Repli_allowed`** — either by gating `Repli_send_lines` at the
   primitive (check other callers first, it is core) or by guarding each goner-delete emission before the
    send. The swarm's P3 (serve) rung must land with a delete-after-revoke Book that asserts the dropped
     chunk/card does NOT reach a revoked mirror and zero frames burn (memory: fight-back-on-core-changes —
      prove a core change in isolation; an unrun security assertion is the worst false-green).

---

## 5. Integrity — verify by hash before trust

A swarm peer can lie: it can serve a chunk whose bytes are wrong (corruption, or a deliberate poison).
 Content-addressing means a received chunk is only trusted after its bytes verify against a hash.

- **The per-frame gate exists.** Every buffer-carrying frame commits to its body via
   `header.body_hash = sha256(bytes)` (Peeroleum `Peeroleum_body_digest`, :186), and `req_unemit`
    (Peeroleum.g:547) verifies it BEFORE delivery: a mismatch faults `bad-body-hash` and the frame is
     never delivered (:561). The hasher is `src/lib/O/Hashly.ts` — `sha256_hex` (one-shot) and
      `sha256_incremental` (streaming, `.update` per slice then `.hex()`), noble-backed, sync, isomorphic
       (browser + node harness), byte-for-byte the old SubtleCrypto encoding. This is the integrity floor
        the Pier already leans on (Radio_spec §5: a wrong-hash `%audiochunk` frame is faulted).
- **The gap for a swarm.** `body_hash` pins the *transport frame's* bytes — it proves the frame arrived
   intact, but a lying peer signs its *own* corrupt bytes with a matching `body_hash`, so the frame
    verifies while the content is a lie. To trust a *swarm* serve, the wanter must verify against a hash it
     learned from a TRUSTED source (the origin-signed catalog / the `%Mag` card / the enid), not from the
      serving peer. Two options, and **this is the decision to make before P3 (§0)**:
  - **(a) Per-chunk content hash.** Give each chunk its own canonical `sha256` (a real content id),
     carried in the origin-signed card. Any holder's copy is byte-verifiable against a hash the wanter
      pre-knows — the true content-addressed swarm, poison-proof by construction. Cost: a hash per chunk
       in the card, and a decision about what exactly is hashed (the Opus segment bytes as `Ra_chunk_cut`
        emits them). This is the clean answer.
  - **(b) Whole-track digest + trust the frame.** Keep verifying only `body_hash` per frame and rely on
     the enid (whole-file `sha256`) as the track-level identity; a fully-arrived track can be re-digested
      and checked against the enid, but a *single* mid-stream chunk cannot be independently proven. Cheaper
       now, weaker against a poisoning peer (a bad chunk is only caught at whole-track re-digest, after
        it may have already played).
- **Recommendation:** (a). A swarm without per-chunk content-addressing is not really content-addressed —
   it is "trust whoever answers," which the whole opportunistic premise cannot afford once a peer can be
    adversarial. Land (a) as the content-addressing precondition (§0) before any peer serves.

---

## 6. Why it's a slog to test (and how Books gate it anyway)

The app tests via **Story Books on a live `:9091` runner** (`scripts/runner_ask.mjs run <Book> --watch`);
 headless is BANNED (a false green — the GhostList footprint + boot-progress diverge from a live runner,
  CLAUDE.md). That constraint collides hard with a p2p swarm. The honest hard problems:

1. **Many peers on one runner.** A swarm is N peers; a runner is one browser tab. The deterministic
    substrate (as Mesh.g and PereStaple already do) is a **co-resident swarm**: many `%Peering` under one
     `w`, the mock carrier pairing ports in-process, `Peeroleum_deliver`'s channel branch fanning a publish
      to every subscribed Peering in-process (Peeroleum.g:417) — the same multiplication the relay does
       across N sockets, done deterministically. So P1/P2/P3 (advertise / discover / serve-one) are
        single-runner Book-able on the mock, exactly like Mesh's stretch model is today. What CANNOT be
         faked on one runner: real webrtc data channels and real fan-out across sockets (P4).
2. **Flaky NAT / ICE.** Real webrtc peer edges depend on ICE/NAT traversal that is inherently
    non-deterministic and environment-dependent — the antithesis of a byte-reproducible fixture. Books
     cannot gate ICE. Mitigation: keep the *policy* (advertise, choose, serve, fallback) on the mock
      carrier (deterministic, Book-gated), and treat the real webrtc carrier as an integration surface
       proven by a **2-runner** run over the actual relay, gated as liveness (crossed / verified /
        healed), not as a byte-exact fixture. This is the same split Radio_spec §7 already names: real
         multicast "needs 2+ runners to verify; the routing/accounting model is the spec for it."
3. **Partial availability.** The interesting swarm states are partial — peer A has [0..15], peer B has
    [8..23], the wanter needs [12..20] and must stitch. The mock swarm can seed exactly these inventories
     (mint specific `%Preview,seq`/`%Stream,seq` particles per peer) and assert the wanter reconstructs
      the union — a deterministic `%see` on "stitched the range from two holders."
4. **A lying / absent peer.** The adversarial control (memory: adversarial-test-agent — a test must be
    proven able to fail). Reliable.g already has the deterministic lossy carrier (`make_lossy_partner`,
     :91, with drop / dup / delay / blackhole per-seq schedules). Extend the mock with a **poisoning
      peer** (serves a chunk whose bytes fail the per-chunk hash) and a **black-hole peer** (advertises a
       chunk then never serves it). Assert: the poison is caught by §5 and the origin fallback (§3) still
        delivers clean bytes; the black-hole peer times out and the wanter falls back. An unrun sabotage
         assertion is a false green (memory: engage-c2-dispatch / MusuDoor sabotage discipline).
5. **The race between peer-serve and origin-fallback.** The subtlest gate: a chunk answered by BOTH a
    late peer and the origin must reconcile to one set of bytes, and the fallback must not double-count or
     corrupt the mirror. The mock's deterministic delay knob (Reliable.g `delay`) lets a Book stage the
      exact interleaving (peer answers on tick T+5, origin on T+2) and assert idempotent UPSERT + no
       coverage gap + exactly-one-plays.
6. **Consent under motion.** A revoke mid-swarm (§4.2): a Book grants, seeds a swarm, revokes one peer,
    then drops a chunk at origin, and asserts the dropped chunk does NOT reach the revoked mirror and zero
     frames burn — the delete-after-revoke gate. Live-gated, adversarially reviewed.

**The testing rule of thumb:** everything that is *policy* (what to advertise, whom to pick, when to fall
 back, whether to serve, what to trust) is deterministic and lives on the mock — Book-gate it on one
  runner. Everything that is *real transport* (webrtc data channels, cross-socket fan-out) is an
   integration surface — 2-runner, liveness-gated, never a byte-exact fixture. Do not chase a green on the
    headless boot; it is a bubble.

---

## 7. The phased build plan

Cheapest-value-first, each rung small, independent, and Book-gated. **Precondition (P0):
 content-addressing real end-to-end** — the per-chunk hash decision of §5(a). Nothing that SERVES should
  land before P0, because a served chunk you cannot independently verify is a swarm you cannot trust.

- **P0 — per-chunk content hash (the precondition).** Give each chunk a canonical `sha256` carried in the
   origin-signed card (§5a). Book: assert a chunk's bytes verify against the card's hash, and a tampered
    chunk fails. Single-runner (mock). *Must land before P3.*
- **P1 — advertise held chunks.** A peer publishes its have-bitmap over `@chunks/<enid>` via
   `Peeroleum_publish`; subscribers accumulate a holder map (§2.1). No serve, no data channel — pure
    presence gossip. Book: two co-resident Peerings, one advertises, the other's holder map reflects the
     inventory; a peer going offline prunes it. Single-runner (mock), in-process fan-out. **This is the
      first rung — pure win, cheapest, no new trust surface.**
- **P2 — discover a nearer holder.** A wanter, needing `(enid, seq)`, scores candidate holders with
   `Mesh_route` (Mesh.g:41) and picks the cheapest reachable one (§2.2). No bytes yet — just the *choice*.
    Book: assert a wanter with a cheap peer holder picks the peer over the costly origin; with no peer
     holder it picks origin. Single-runner (mock) — this is pure `Mesh` policy, already the shape Mesh's
      stretch model proves.
- **P3 — serve one chunk peer-to-peer.** The wanter pulls the chosen page from the peer via
   `Repli_want_next` → `Repli_serve_chunks` (Repli.g:542/:420), bytes verified by §5/P0, consent-gated by
    `Repli_allowed` (§4). Book: peer A serves a chunk to peer B; B's mirror chunk becomes real
     (presence-is-fill-state); a poison chunk faults and does NOT land; a revoked peer is refused (§4.2).
      Single-runner (mock carrier as the "webrtc" stand-in) + the delete-after-revoke security Book.
- **P4 — full opportunistic swarm.** The caster publishes each page ONCE onto `@chunks/<enid>` and every
   subscribed granted wanter receives it (the true stretch, §2.3 / `stream_offer` handover); a wanter with
    no peer holder falls back to origin transparently (§3); a lying/absent peer is survived (§6.4). This
     is the rung that needs **2 runners** and the real webrtc carrier — Book-gated as liveness (crossed /
      verified / healed / stretched-not-N-times), the way Radio_spec §7's "real multicast over the Pier"
       is scoped. The negative control is the relay-only topology (Mesh's `Mesh_broadcast_naive` shape)
        proving the saving is the peer edges, not the algorithm (Radio_spec §9: "no free lunch").

**Ordering rationale.** P1 (advertise) is pure win with no new trust surface and gates on one runner — do
 it first. P2 (discover) is pure policy over the existing cost model — cheap, one runner. Both are safe
  and land value (a holder map + a cheapest-source chooser) before any byte crosses a peer. P3 (serve)
   is where consent + integrity + a real Repli pull converge — it MUST wait behind P0 (per-chunk hash) and
    carry the delete-after-revoke security Book. P4 (full swarm) is the only rung that needs real webrtc
     and 2 runners, so it lands last, on the integration rails Radio_spec §7 already reserves. At every
      rung the origin/relay path stays the floor — the swarm is always a cheap race the origin can win,
       never a gate.

---

## 8. What this does NOT change

To keep the seam narrow and the review honest:
- **Repli's pull/page/park/serve is untouched.** A peer is just another registered caster
   (`Repli_register_caster`, Repli.g:255). No new delivery model — the C** stream stays orthogonal to
    `%Good`/`req:Store` (Radio_spec §2 principle; the stream is walked, not GET).
- **The transport spine is untouched.** Multicast (`@channel` publish/subscribe/claim) already exists
   (Peeroleum §18); the webrtc carrier already lives in Tribunal.g. This layer adds beacons + a chooser,
    not a new carrier.
- **The consent seam is untouched — it is CLOSED (§4.2).** `Repli_allowed` / `Swarm_pier_live` / `%Grant`
   / `%NotGrant` stay the gate; the only code change is making sure EVERY wire emission (including goner
    deletes) passes through it before a swarm multiplies the leak.
- **The relay stays a dumb router.** It routes on `header.to` only, never inspects the body (relay.ts) —
   a signed/opaque body passes through. Cross-relay topic fan-out (the two-instance follow-up, §18 bomb)
    is out of scope here; P4's 2-runner gate assumes the single-relay local fan-out.
