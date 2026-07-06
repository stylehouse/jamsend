//#region ologist
// Peeroleum — the particle-only p2p spine (spec: src/lib/O/spec/Peeroleum_spec.md).
//  Getting-started scaffold: the req tree (p2pman → p2paddy → handshake) and the
//  three transports, compile-clean. Bodies range from real LangTiles req-seeds to
//  `// <` seams where the spec needs forms LangTiles can't yet say (deep/wildcard
//  drop, drilled req paths, object/.c payloads) — each a tracked language seam.
//  Progress lives in Peeroleum_handover.md.

// ── manager: appear online ────────────────────────────────────────────────────
// A:Peerologist/w:Peerologist — no identity, no transport; it only wants Peerings.
async Peerologist(A,w):
    w oai %req:p2pman,eternal
    await w&do

// %req:p2pman — top desire: a %Peering per online identity. Eternal foreman:
//  pump children, then settle the gate for this tick with %ok (re-armed next tick).
async req_p2pman(req):
    // < ensure a %Peering per identity-thang with online_want (spec §11.1);
    //    for the spine the wrangler lays the sides directly.
    await req&do
    req.sc.ok = 1

//#region oleum
// ── per-identity worker ───────────────────────────────────────────────────────
// A:Alice/w:Peeroleum — one per identity-presence; owns this address's Piers.
async Peeroleum(A,w):
    oai seemingly:`ya aooooolly`...figaro:Squelchbury
    // each installed %Peering manages its own Piers via %req:p2paddy
    S o Peering
        Peering oai %req:p2paddy
    await w&do

// %req:p2paddy — maintain this Peering's Piers + pick a transport.
async req_p2paddy(req):
    // < transport_select is seeded + driven by the wrangler (Lake_trial) directly on
    //    the Peering in this test, so req.c.up IS the Peering. Auto-seeding it here
    //     nests it under p2paddy (req.c.up = p2paddy), which breaks that navigation —
    //      restore (and walk up to the Peering) when p2paddy drives real peers (§11.2).
    // < per known peer: seed %req:dial → ensure a %Pier → seed its %req:handshake.
    await req&do
    req.sc.ok = 1

// req_Peering — the per-Peering worker, the node-level flock do_fn (the twin of req_Pier one
//  level up). A Peering is %Peering,name:…,req:N (oai Peering,$name,req): its MAINKEY Peering
//   names this handler, the serial req: just plugs it into the pump — so w.do() pumps each
//    Peering, which pumps each Pier (req_Pier), which pumps the handshake. The ambient w-level
//     sweep thus cascades the whole flock from ONE entry at w, so a nested flock needs no hand-pump.
//      oai wires Peering.c.up = w for us. Job: pump this Peering's Piers, then stay a live member.
async req_Peering(peering):
    await peering&do
    peering.sc.ok = 1

// req_Pier — the per-Pier worker, the flock's do_fn (spec §11.3).  A Pier is
//  %Pier,pub:…,req:N (oai Pier,$pub,req): its MAINKEY Pier names this handler — do_fn_for
//   dispatches a typed serial-req by mainkey, while the serial req: just plugs the Pier into
//    the req pump — so when its Peering does(), each Pier reconciles ITSELF.  Because WE mint
//     the Pier, its identity is ours: a peer can land frames in an existing Pier's inbox but
//      can never mint or re-key one (no gut-swap).  The job: pump whatever sub-reqs this Pier
//       hosts (handshake / trust / send, seeded by the caller), then stay a live flock member
//        — ok re-armed each pass, mirroring req_p2paddy.
async req_Pier(pier):
    await pier&do
    pier.sc.ok = 1

// ── the handshake (hello + trust) as %req (spec §8) ───────────────────────────
// Four maz-ordered leaves under a %Pier: highest maz runs first, lower gated behind.
//  Each leaf finishes when its protocol particle exists; the parent rolls up when
//  all four are done. The leaf do_fns + say/hear exchange are just below.
async req_handshake(req):
    req oai %req:said_hello,maz:4
    req oai %req:heard_hello,maz:3
    req oai %req:said_trust,maz:2
    req oai %req:heard_trust
    await req&do
    // parent rolls up once all four leaves finish (heard_trust last → handshake done).
    if (req.all_finished() && !req.sc.finished) (req.c.up).finish(req)

// ── handshake leaf do_fns (spec §8) — existence checks, not bool polls ─────────
// A leaf is `%Pier/%req:handshake/%req:<leaf>`, so its Pier is req.c.up.c.up and
//  its w is two hops above that (Pier→Peering→w). Each finishes the moment its
//   protocol particle exists. The said_* leaves also *perform* the say (idempotent
//    on their protocol particle); the heard_* leaves are pure existence checks, fed
//     by the far side's say landing through hear_* (Peeroleum_deliver dispatches the
//      inbound hello/trust frame). Symmetric: both sides run all four, so both
//       initiate and the round-trip converges. maz orders them: said_hello (4) then
//        heard_hello (3) then said_trust (2) then heard_trust (1), each gated behind
//         the last by the do() level's some(needs_work) — trust never precedes hello.
async req_said_hello(req):
    let pier = req.c.up.c.up
    let w = pier.c.up.c.up
    &say_hello,w,pier
    pier o protocol/hello/said$:said
    if (said) (req.c.up).finish(req)

async req_heard_hello(req):
    let pier = req.c.up.c.up
    pier o protocol/hello/heard$:heard
    if (heard) (req.c.up).finish(req)

async req_said_trust(req):
    let pier = req.c.up.c.up
    let w = pier.c.up.c.up
    &say_trust,w,pier
    pier o protocol/trust/said$:said
    if (said) (req.c.up).finish(req)

async req_heard_trust(req):
    let pier = req.c.up.c.up
    pier o protocol/trust/heard$:heard
    if (heard) (req.c.up).finish(req)

// ── say / hear — the hello+trust exchange (spec §8) ───────────────────────────
// say_* write our half of the protocol and emit one frame to the peer; idempotent
//  on the protocol particle so a re-pump never double-sends. hear_* read the
//   inbound frame (raw — it's a JS object off the wire), verify, and write the
//    far half. identity in the mock: a Peering's %name is our address, a Pier's
//     %pub is the peer it faces, and the pubkey we send IS our name (verify is
//      then startsWith(pub)). seq is the per-Pier monotone outbound counter
//       (Pier_next_seq, spec §7.1) — each say allocates the next and records it on
//        the protocol %said so the matching ack can stamp it %acked.
say_hello(w, pier):
    let proto = pier oai protocol
    let hello = proto oai hello
    if (hello.oa({said:1})) return
    let me = pier.c.up%name
    let seq = this.Pier_next_seq(pier)
    hello.i({said:1, seq})
    &Peeroleum_send,w,{header:{type:'hello', from:me, to:pier%pub, seq, pubkey:me}}

say_trust(w, pier):
    let proto = pier oai protocol
    let trust = proto oai trust
    if (trust.oa({said:1})) return
    let me = pier.c.up%name
    let seq = this.Pier_next_seq(pier)
    trust.i({said:1, seq})
    &Peeroleum_send,w,{header:{type:'trust', from:me, to:pier%pub, seq}}

// hear_hello — verify their key starts-with the pub we expect, record %heard +
//  the proven pubkey, set %Ud (their identity, survives resets — spec §6), and
//   if we have not said yet, say now (the single-initiator path; a no-op under the
//    symmetric dual-init). A failed verify writes nothing — the gap is the result
//     (spec §8: a corrupt hello that never arrives is the test passing).
// Returns true on a clean verify, false on reject — the serial inbox handler
//  (req_unemit) stamps %error on a false (the deliver-failure path, spec
//   §7.3); under the mock with no corruption this is always true (heading 6 arms it).
hear_hello(w, pier, frame):
    const H = this
    let h = frame.header
    if (!String(h.pubkey).startsWith(pier%pub)) return false
    let hello = pier.oai({protocol: 1}).oai({hello: 1})
    hello.i({heard: 1, pubkey: h.pubkey})
    pier.oai({Ud: 1, pubkey: h.pubkey})
    if (!hello.oa({said: 1})) H.say_hello(w, pier)
    return true

// hear_trust — verify their grants (trivial under the mock) and record %heard.
hear_trust(w, pier, frame):
    pier.oai({protocol: 1}).oai({trust: 1}).i({heard: 1})
    return true

// Pier_next_seq — the per-Pier monotone outbound counter (spec §7.1). On .c: it
//  survives across steps in the live tree and never snaps; the seq it hands out
//   lands on the %outbox/emit, which is what the snap shows. Acks do NOT consume a
//    seq (they book no emit), so the counter counts exactly our real outbound frames.
Pier_next_seq(pier):
    pier.c.seq = (pier.c.seq || 0) + 1
    return pier.c.seq

// ── binary body digest (spec §4.2, heading 7) ─────────────────────────────────
// A binary frame carries its payload as RAW bytes on frame.buffer (a Uint8Array), never
//  base64 — binary is the bulk of real traffic, so a 33% base64 tax is unacceptable. On
//   the wire a buffer-carrying frame is one binary message ([header JSON]\n[raw buffer], the
//    carrier's job — Socket_real/relay); the in-process mock carries frame.buffer by reference. The buffer
//     stays off-snap (mock: unemit.c.frame.buffer); only header.body_hash + body_len snap.
//  The integrity check is sha256 (crypto.subtle), the same digest the trust layer signs over —
//   so when header.sign lands it commits to the buffer through body_hash with no second algorithm.
//    It is async, and the whole delivery path is async all the way (carrier recv awaits
//     Peeroleum_deliver awaits inbox.do() → req_unemit awaits this), so the digest resolves INSIDE the
//      carrier's awaited post_do — still within the beliefs mutex / Atime (spec §15), deterministic.
//       (An FNV-1a digest stood here purely to stay synchronous under a sync inbox; going async
//        dissolved that constraint, and with it the forgeable hash — body_hash is now signable.)
// Peeroleum_body_digest — sha256 hex over the raw buffer bytes. Same bytes → same hex on
//  sender and receiver, so a clean buffer verifies and a meddled one does not. Raw JS:
//   crypto.subtle, no DSL verb. Async — the whole delivery path awaits it (see below).
async Peeroleum_body_digest(bytes):
    let b = bytes instanceof Uint8Array ? bytes : new Uint8Array(bytes || [])
    let digest = await crypto.subtle.digest('SHA-256', b)
    return Array.from(new Uint8Array(digest)).map(x => x.toString(16).padStart(2, '0')).join('')

// ── consumer seam (spec heading 10, asks 1–3): the editor↔runner channel and any other app
//     rides the same envelope/inbox/ack/faulty machinery without editing this spine ──────────
// Peeroleum_on — register an app-frame handler for a non-protocol header.type on this w. The
//  serial inbox (req_unemit, driven by inbox.do()) dispatches a verified frame of that type to fn(w,pier,frame)
//   inside the SAME lifecycle as hello/trust — pre-Ud gate, verified→done→ack, error→faulty — so a
//    consumer (Lies: dock_push/run_result) owns its frames here. fn returns false to reject (→
//     %error→%faulty), exactly like hear_*. The registry is an object on .c (a seam), keyed by type.
Peeroleum_on(w, type, fn):
    w.c.on = w.c.on || {}
    w.c.on[type] = fn

// Peeroleum_send_consumer — the consumer emit (ask 2): allocate this Pier's next monotone seq, fill
//  from/to from the Pier identity, and hand {header, ...body} to Peeroleum_send (which books the
//   %outbox/emit and carries it over the active transport). body holds the app payload (e.g. a dock's
//    path + .go text); it rides the one envelope untouched — the relay routes on header.to only.
//     Returns the seq so the caller can watch its %outbox/emit go %acked. (The durable form is a
//      Pier-hosted %req:send — when built it hits the c.up rule: stamp Pier.c.up=Peering; Peering.c.up=w
//       or its do_fn silently never pumps. Not built for v1 — the direct call drives via feebly_ponder.)
Peeroleum_send_consumer(w, type, body):
    let pier = w.o({Peering:1})[0]?.o({Pier:1})[0]
    if (!pier) return
    let me = pier.c.up%name
    let seq = this.Pier_next_seq(pier)
    this.Peeroleum_send(w, Object.assign({ header: { type, from: me, to: pier%pub, seq } }, body || {}))
    return seq

// Peeroleum_send_to — the ADDRESSED consumer emit (Engage_integration C2): like Peeroleum_send_consumer
//  but picks the Pier by its %pub instead of [0], so an editor holding N runner Piers under its one
//   Peering talks to ONE chosen runner. header.to = that runner's prepub; the relay routes to:<prepub>
//    to its hello-verified socket (a role-broadcast `to:'runner'` can't single one out). Pier-by-pub is
//     the same select Peeroleum_route already does on inbound (piers.find pub === other). The Pier must
//      already exist — the editor promotes a roster entry first (Lies_runner_pier); no Pier ⇒ undefined,
//       and the caller says "no such runner". Returns the seq so the caller can watch its emit go %acked.
Peeroleum_send_to(w, to, type, body):
    let peering = w.o({Peering:1})[0]
    if (!peering) return
    let pier = peering.o({Pier:1}).find(p => p.sc.pub === to)
    if (!pier) return
    let me = peering%name
    let seq = this.Pier_next_seq(pier)
    this.Peeroleum_send(w, Object.assign({ header: { type, from: me, to, seq } }, body || {}))
    return seq

// Peeroleum_peer_ready — the watchable readiness signal (ask 3): true once this Pier's %req:handshake
//  has finished (hello+trust both ways). A consumer $effects off it before emitting app frames — and
//   the inbox's pre-Ud gate already refuses non-hello/noop until then, so this is the affirmative side
//    of the same coupling.
Peeroleum_peer_ready(pier):
    let hs = pier.o({req:'handshake'})[0]
    return !!(hs && hs%finished)

// ── multicast / topics: publish-subscribe over a claimed @channel (spec §18) ────────────
// WHY: a high-bandwidth publisher (a webserver relaying to 100 listeners) must NOT upload 100 copies, one
//  addressed to each Pier, nor even hold all 100 addresses. It publishes ONCE to a TOPIC — a `to` that starts
//   with `@` (the special case, beside a per-peer pub) — and the relay fans that single upload out to every
//    subscriber. The per-Pier handshake/trust still happens 1:1 (you know WHO each subscriber is); only the
//     BULK stream goes multicast, handed over as a stream POINTER (Peeroleum_offer_stream). An @name must be
//      CLAIMED before it carries — first-come for now, a community/crypto-signed gate later; the claim reserves
//       the name and records the owner, enforcement stays soft (trust-everything v1, spec §5).
// The reliability split from a 1:1 stream is deliberate: a topic frame is fire-and-forget (Peeroleum_publish
//  books NO outbox emit, expects NO acks — the whole point is not tracking N subscribers), carrying its own
//   per-channel seq so a subscriber can later detect a gap and NACK. The relay ws is reliable+ordered, so v1
//    needs none of that; on a lossy multicast carrier a per-channel inseq is the future, NOT the per-Pier one.

// Peeroleum_claim — reserve an @channel as ours to publish on. Tells the carrier (the real socket sends a
//  {control:claim} to the relay; the mock has nothing to tell — ownership is soft) and stamps a local %owns
//   marker on our Peering so the snap shows what we publish. Crypto-signed ownership is the community gate's job.
Peeroleum_claim(w, peering, channel):
    if (!peering) return
    if (!peering.oa({owns: channel})) peering.i({owns: channel})
    let conn = this.Peeroleum_carrier(peering, w)
    conn?.claim?.(channel)

// Peeroleum_subscribe — start receiving an @channel's broadcasts. Registers a per-Peering handler
//  (peering.c.subs[channel] = fn, read by Peeroleum_deliver's channel branch) and tells the carrier to
//   subscribe (the real socket sends {control:subscribe} so the relay binds us into the channel's fan-out
//    set; the mock needs nothing — the deliver branch scans subscribed Peerings in-process). fn is
//     (w, peering, frame): the topic frame, verified at source, no per-frame ack. %subscribed snaps the link.
Peeroleum_subscribe(w, peering, channel, fn):
    if (!peering) return
    peering.c.subs = peering.c.subs || {}
    peering.c.subs[channel] = fn
    if (!peering.oa({subscribed: channel})) peering.i({subscribed: channel})
    let conn = this.Peeroleum_carrier(peering, w)
    conn?.subscribe?.(channel)

// Peeroleum_publish — put ONE frame on an @channel: the single upload that fans out to every subscriber.
//  Fire-and-forget, the deliberate opposite of Peeroleum_send: NO outbox emit, NO ack expected, NO per-Pier
//   seq — a topic frame carries its OWN monotone seq (peering.c.chan_seq[channel], off-snap) so a subscriber
//    can later detect a gap and NACK. The carrier ships it once; the relay (or mock hub) does the multiplication.
//     body holds the payload (e.g. an audio chunk) and rides the one envelope untouched, routed by header.to only.
Peeroleum_publish(w, peering, channel, type, body):
    if (!peering) return
    let me = peering%name
    peering.c.chan_seq = peering.c.chan_seq || {}
    let seq = peering.c.chan_seq[channel] = (peering.c.chan_seq[channel] || 0) + 1
    let conn = this.Peeroleum_carrier(peering, w)
    if (!conn) { console.log(`🛰 Peeroleum_publish ${type} seq=${seq} → ${channel} ⚠ DROPPED — no live transport`); return }
    conn.send(Object.assign({header: {type, from: me, to: channel, seq}}, body || {}))
    return seq

// Peeroleum_offer_stream — the HANDOVER: an established 1:1 Pier hands the peer a stream POINTER (an @channel
//  to subscribe to) instead of streaming to it directly. Sends a `stream_offer` consumer frame over the
//   existing per-Pier link (so it rides the trusted, handshaked channel — the receiver's pre-Ud gate refuses
//    it otherwise), naming the channel in the header. The peer's registered stream_offer handler (Peeroleum_on)
//     subscribes to that channel and thereafter receives the bulk over the fan-out. This is the seam where a
//      unicast stream becomes multicast — the publisher stops addressing this peer by pub and starts addressing
//       the topic, and uploads once for all of them.
Peeroleum_offer_stream(w, pier, channel):
    let me = pier.c.up%name
    let seq = this.Pier_next_seq(pier)
    this.Peeroleum_send(w, {header: {type: 'stream_offer', from: me, to: pier%pub, seq, channel}})

// ── transports (spec §4) — one envelope, swappable carrier ────────────────────
// The mock: in-process, deterministic, tick-driven. Two mock-ports deliver into
//  each other via a partner ref (paired by the wrangler once both sides stand
//   up); a send is H.post_do(() => partner.recv(frame)) — instant, in Atime,
//    deterministic (spec §15). The live handle + partner ref are objects on .c.
transport(A,w):
    w i %transport,type:mock
    const H = this
    let at = w.i({active_transport: 1, type: 'mock', open: 1})
    // the mock-port on at.c.connection: `send` posts the frame to the partner
    //  port; `recv` lands an inbound frame in this side's Pier inbox. `partner`
    //   starts null — the wrangler pairs the two ports after both sides exist.
    //  reliable:true — in-process, ordered, exactly-once, so Peeroleum_deliver books
    //   straight and skips inseq; a lossy test wraps this port and sets reliable:false.
    at.c.connection = {
        type: 'mock', partner: null, reliable: true,
        send(frame) {
            let to = frame && frame.header && frame.header.to
            // a to:@channel publish has no single partner — fan it into the in-process relay (Peeroleum_deliver's
            //  channel branch scans subscribed Peerings). One post_do keeps it in Atime, exactly like a 1:1 send.
            if (to != null && String(to)[0] === '@') { H.post_do(async () => { await H.Peeroleum_deliver(w, frame) }); return }
            H.post_do(async () => { await this.partner?.recv(frame) })
        },
        recv(frame) { return H.Peeroleum_deliver(w, frame) },
    }

// The webrtc + websocket carriers and the carrier-selection trial (try webrtc,
//  fall to websocket on no-ack) live in their own flavour now — Ghost/N/Tribunal.g
//   (PeerJS, Socket, Tribunal_hand_to_webrtc, req_transport_select). This spine keeps
//    only the mock carrier + the envelope; the trial repoints %active_transport.

// ── routing: which Peering|Pier a frame belongs to (spec §11.3) ───────────────
// Peeroleum_route — resolve {peering, pier} for a frame. `mine` is the header key naming THIS
//  node: `from` when we send, `to` when we receive; the OTHER end names the Pier's %pub. ONE
//   Peering ⇒ use it (production: a w is one identity — the live channel / Tyrant / Relay Brink);
//    MANY ⇒ route by identity (the co-resident test swarm keeps every node's Peering under one
//     w:Peers). So a single-identity w is behaviour-identical; the swarm just disambiguates.
Peeroleum_route(w, h, mine):
    let peerings = w.o({Peering:1})
    let peering = (peerings.length === 1) ? peerings[0] : peerings.find(p => p.sc.name === h[mine])
    if (!peering) return {}
    let other = (mine === 'from') ? h.to : h.from
    let piers = peering.o({Pier:1})
    let pier = (piers.length === 1) ? piers[0] : piers.find(p => p.sc.pub === other)
    return {peering, pier}

// Peeroleum_carrier — the live connection for a frame's endpoint. The swarm hangs one carrier per
//  Peering (many peers under one w); production hangs ONE on the w (a single-identity node, where the
//   Relay Brink + keepalive read it off w). Prefer the Peering's own, fall back to the w's — so a
//    single-peer w is untouched and the swarm still gets its per-peer carrier. (w is passed in, not
//     walked via c.up, so it resolves before a production Peering's c.up is wired.)
Peeroleum_carrier(peering, w):
    return (peering && peering.o({active_transport:1})[0]?.c.connection) || (w && w.o({active_transport:1})[0]?.c.connection)

// ── send / deliver — the one envelope across the active transport (spec §4.3) ──
// Peeroleum_send — hand a frame to this side's active transport (spec §4.3). A real
//  outbound frame books a %outbox/emit (created→sent in one stamp — the mock hands off
//   instantly) that lives until its ack stamps %acked (spec §7.1). An ack is light: it
//    ferries but books no emit and is never itself acked (spec §7.2), so the outbox stays
//     exactly the set of frames awaiting acknowledgement. Objects-on-.c + dynamic-value
//      writes are LangTiles seams, so the body is raw JS.
Peeroleum_send(w, frame):
    let h = frame.header
    let {peering, pier} = this.Peeroleum_route(w, h, 'from')
    // ack, the heartbeat (ping/pong), run_phase (the progress blip) AND advertise (the grid presence
    //  beacon) book no outbox emit: an ack is light (spec §7.2); the rest are fire-and-forget — booking
    //   them piles %emit rows nothing reliably culls between Story steps. Only real app/protocol frames
    //    are tracked. (run_phase MUST be ephemeral: it is never acked, so a booked emit would never
    //     cull — and the ack it would otherwise draw re-wakes the runner's Story drive, wedging
    //      quiescence into an endless step_stall loop.  advertise is ephemeral for the TWIN reason: a
    //       booked emit is a snap mutation, so it could only fire IN-THINK — a quiesced/idle runner then
    //        stops beaconing and drops off the editor's roster though it's still alive (its pings ride the
    //         off-think keepalive).  As a beacon it's self-healing: the relay ws is reliable+ordered, so
    //          first-contact still lands and a lost beat is replaced ~15s later — app-level acks buy
    //           nothing.  Ephemeral lets the off-think keepalive emit it, so an idle runner stays visible.)
    let ephemeral = (h.type === 'ack' || h.type === 'ping' || h.type === 'pong' || h.type === 'run_phase' || h.type === 'advertise')
    if (pier && !ephemeral) {
        // a binary frame records body_hash + body_len on its emit so the snap shows
        //  "a test_binary of N bytes, hash X, sent" (the body itself rides off-snap on the frame).
        let esc = {emit: h.seq, type: h.type, seq: h.seq, sent: 1}
        if (h.body_hash != null) { esc.body_hash = h.body_hash; esc.body_len = h.body_len }
        let emit = pier.oai({outbox: 1}).i(esc)
        // retransmit bookkeeping (off-snap): the raw frame to re-hand the transport, the logical tick
        //  of this first send, the attempt count (Reliable.g retx_due reads these). Clean streams ack
        //   before a sweep tick elapses, so they stay attempts:1 and never re-send.
        emit.c.frame = frame
        emit.c.sent_tick = w.c.retx_tick || 0
        emit.c.attempts = 1
    }
    let conn = peering && this.Peeroleum_carrier(peering, w)
    // No transport is a real fault (the frame is lost) — always say so, clearly.  A live+loud
    //  frame logs normally; a live heartbeat stays quiet so a healthy channel doesn't spam.
    if (!conn) console.log(`🛰 Peeroleum_send ${h.type} seq=${h.seq} → ${h.to} ⚠ DROPPED — no live transport (channel down / re-establishing)`)
    if (conn && !ephemeral) console.log(`🛰 Peeroleum_send ${h.type} seq=${h.seq} → ${h.to} (transport live)`)
    conn?.send(frame)

// Peeroleum_deliver — the transport handed us an inbound frame (spec §4.3). An ack is
//  handled here directly (spec §7.2): Peeroleum_take_ack stamps the outbox emit it names
//   %acked — it never enters the inbox or a hear_* handler. Any other frame lands in the
//    serial inbox as %unemit,queued (its raw frame stashed on .c for the handler) and
//     inbox.do() drains it (req_unemit per frame). feebly_ponder re-drives a think (Runtime asserted —
//      we run inside the carrier's post_do) so a watching do_fn reacts this same run.
async Peeroleum_deliver(w, frame):
    const H = this
    let h = frame.header
    // ── multicast: a to:@channel frame is a TOPIC broadcast, not a 1:1 Pier message (spec §18) ──
    // The relay (or, in the test, the mock hub) already fanned this one upload out to every subscriber's
    //  socket; here each Peering under THIS w that subscribed to the channel dispatches it to its handler.
    //   Best-effort + fire-and-forget by design — NO inbox booking, NO ack (a 100-subscriber ack storm is the
    //    very thing multicast avoids), NO per-Pier seq/inseq (a topic carries its OWN seq, for a future gap-
    //     NACK, not the per-Pier reliable stream). In production a w is one identity so exactly one Peering
    //      matches; the co-resident test swarm holds N under one w, so the scan fans out to all N — the same
    //       multiplication the relay does across N sockets, done in-process. A `to` with no `@` falls through.
    if (h.to != null && String(h.to)[0] === '@') {
        for (const peering of w.o({Peering:1})) {
            let fn = peering.c.subs && peering.c.subs[h.to]
            if (fn) await fn(w, peering, frame)
        }
        H.feebly_ponder()
        return
    }
    // an addr-less CLI ask (runner_ask.mjs / reactap.mjs / ghost_compile.ts — exactly the two types
    //  the relay corr-remembers) is NOT a peer envelope: its `from` is an ephemeral reply addr, never
    //   a Pier, and the reply is a raw control frame the relay corr-routes back.  So dispatch it by
    //    TYPE here, BEFORE routing, ephemeral-style (no inbox booking, no ack-back — there is no Pier
    //     to ack through, and a CLI never retransmits, it just times out).  Routing these was the bug:
    //      an EDITOR holds N runner Piers, so pub===from missed → the frame hit `if (!pier) return` and
    //       vanished; the single-Pier runner only ever matched by luck through Peeroleum_route's
    //        length===1 arm (then booked into its inbox).  By type, it lands whether this node holds
    //         0, 1, or N Piers, editor or runner alike.
    if (h.type === 'runner_ask' || h.type === 'ghost_compile') { let on = w.c.on && w.c.on[h.type]; if (on) on(w, null, frame); return }
    let {peering, pier} = this.Peeroleum_route(w, h, 'to')
    // first-contact: a pier_hello arrives BY DESIGN from a prepub no %Pier exists for yet — the
    //  invite front door (Swarm_spec §6.3/§10.1). The Pier/Ud booking discipline can't apply to a
    //   caller we haven't met, and doesn't need to: the Idzeug echoed inside is its own credential
    //    (Swarm_hello re-verifies the signature before anything seals). Dispatch to the registered
    //     handler (armed by Swarm_arm) — the handler promotes the %Pier — then ack through the
    //      fresh route so the caller's outbox emit retires. A pier this node ALREADY holds falls
    //       through to the normal booked path below; every other no-pier frame still drops.
    if (!pier && h.type === 'pier_hello') {
        let on = w.c.on && w.c.on[h.type]
        if (!on) return
        await on(w, null, frame)
        let now = this.Peeroleum_route(w, h, 'to')
        if (now.pier) this.Peeroleum_send(w, {header: {type: 'ack', from: h.to, to: h.from, ack: h.seq}})
        H.feebly_ponder()
        return
    }
    if (!pier) return
    // inbound-silence liveness (Reliable.g twin of the outbound %stalled): stamp the LOGICAL tick we last
    //  heard ANYTHING on this Pier — every frame, acks included (an ack is the cheapest liveness proof, so
    //   counting it closes the watchdog's ack-blindness). Replay-safe (logical tick, never ms), off-snap on
    //    .c. The silence sweep reads it; production's wall-clock keepalive is the other half (handover §8).
    pier.c.last_heard_tick = w.c.retx_tick || 0
    // only wake a watching do_fn if the ack actually advanced something (stamped an outbox emit or a
    //  protocol %said). An ack for an UNtracked frame — an ephemeral run_phase/ping the far side acked
    //   anyway (e.g. an un-fixed editor bootstrap that still inboxes+acks run_phase) — matches nothing,
    //    so feebly_ponder-ing on it would re-wake a quiescing Story drive into the step_stall wedge.
    //     This is robust to the PEER's behaviour: the runner ignores acks that advance nothing here.
    if (h.type === 'ack') { if (H.Peeroleum_take_ack(w, pier, h)) H.feebly_ponder(); return }
    // ping/pong (heartbeat), run_phase (progress blip) AND advertise (grid presence beacon) are
    //  ephemeral: dispatch straight to the registered handler, like an ack — NO inbox booking (so they
    //   never stack in the snap) and NO ack-back. The ack-back is the killer: a run_phase that gets
    //    acked sends the ack to the runner, whose Peeroleum_deliver feebly_ponders → re-wakes its Story
    //     drive so the step never quiesces → step_stall fires → another run_phase → another ack → an
    //      endless wedge (the 48s).  advertise joins them so a beacon never books/acks either — and the
    //       feebly_ponder is safe because advertise is editor-inbound only (runners send it to:'editor';
    //        the editor has no Story drive to re-wedge), and it nudges Lies_aim to refresh the roster Brink.
    if (h.type === 'ping' || h.type === 'pong' || h.type === 'run_phase' || h.type === 'advertise') { let on = w.c.on && w.c.on[h.type]; if (on) on(w, pier, frame); H.feebly_ponder(); return }
    // The inbox is a serial %req drain: a booked frame is a %req:unemit (discriminated by the sender's
    //  per-Pier seq) and inbox.do() runs each unemit-req's do_fn (req_unemit) one at a time, in arrival
    //   order, awaiting each — that IS the serial async drain, so the hand-rolled %queued/%handling lock
    //    is gone. The beliefs mutex (post_do is awaited across the whole delivery) means no two do()
    //     drains overlap, so no in-flight guard is needed. The inseq gate below decides WHICH frames book.
    let inbox = pier.oai({inbox: 1})
    inbox.c.up = pier   // do() climbs c.up to the House to resolve req_unemit; stamp the inbox→pier link
    // ── transport-gating: engage the seq discipline ONLY on a lossy carrier ──
    // A reliable+ordered carrier (the ws relay, the clean mock) already delivers in order, exactly once,
    //  so an ordering layer on top is redundant — and the redundancy is what bites. An ephemeral (ack/ping/
    //   pong/run_phase, all returned above) still burns a Pier_next_seq on the sender, but the receiver never
    //    books it, so inseq reads a PHANTOM gap and holds the next booked frame forever — the editor↔runner
    //     "only the first rungo lands" wedge, which the 5s keepalive guarantees by punching a hole between any
    //      two booked frames. So a reliable carrier books STRAIGHT, in arrival order. inseq + retransmit engage
    //       only where the carrier is genuinely lossy (its connection sets reliable:false — today the adversary
    //        mock, tomorrow the webrtc datachannel); the adversary IS that carrier, so the Story still drives
    //         every line of Reliable.g. (Reconnect-replay dedup on a reliable carrier is the epoch handshake,
    //          heading 8 — not a cold-start re-baseline smeared on the deliver site.)
    let conn = this.Peeroleum_carrier(peering, w)
    let reliable = conn?.reliable !== false   // default reliable; only an explicit false engages inseq
    let seq = Number(h.seq)
    if (reliable || !Number.isFinite(seq)) {   // reliable carrier, or a frame with no seq → book straight, never hold
        H.Peeroleum_book_unemit(inbox, w, pier, frame); await inbox.do(); H.feebly_ponder(); return
    }
    // ── inbound seq discipline (Reliable.g: inseq_admit) — LOSSY carriers only ──
    pier.c.inseq = pier.c.inseq || {last: 0, buffered: []}
    let ready = this.inseq_admit(pier.c.inseq, seq)
    if (!ready.length) {
        // delivered-dup (seq ≤ last) → re-ack only, never re-book (a 2nd hear_trust/dock_push is the
        //  corruption this guards). gap/buffered-dup → hold off-snap, no ack (unverified till dispatch).
        if (seq <= pier.c.inseq.last) {
            let me = pier.c.up%name
            H.Peeroleum_send(w, {header:{type:'ack', from:me, to:pier%pub, ack:seq}})
        } else {
            pier.c.held = pier.c.held || {}
            pier.c.held[seq] = frame
            // a hold must be LOUD, never silent: on a lossy carrier it is legitimate (retransmit will fill the
            //  gap), but on anything else it is the wedge this whole gate exists to prevent — so it screams.
            console.warn(`⚠ inseq HOLDING seq=${seq} type=${h.type} — gap above last=${pier.c.inseq.last} (need ${pier.c.inseq.last + 1}); legitimate only on a lossy carrier, else a wedge`)
        }
        H.feebly_ponder()
        return
    }
    // ready[0] is this frame; the tail are gap-held frames a fill just unblocked, in seq order.
    for (const s of ready) {
        let f = (s === seq) ? frame : (pier.c.held && pier.c.held[s])
        if (pier.c.held) delete pier.c.held[s]
        if (f) H.Peeroleum_book_unemit(inbox, w, pier, f)
    }
    await inbox.do()
    H.feebly_ponder()

// Peeroleum_book_unemit — book ONE inbound frame as a %req:unemit under the inbox (discriminated by
//  the sender's per-Pier seq) and stash its w/pier/raw-frame on .c for req_unemit (avoids the deep
//   c.up walk). Booking only; the caller drains with inbox.do(). Split out of Peeroleum_deliver so the
//    inseq path can book a whole gap-released run before a single drain.
Peeroleum_book_unemit(inbox, w, pier, frame):
    let h = frame.header
    let usc = {req: 'unemit', seq: h.seq, type: h.type}
    if (h.body_hash != null) { usc.body_hash = h.body_hash; usc.body_len = h.body_len }
    let ureq = inbox.oai(usc)
    ureq.c.frame = frame
    ureq.c.w = w
    ureq.c.pier = pier
    return ureq

// req_unemit — the inbox do_fn (spec §7.3): handle ONE inbound frame, booked as %req:unemit by
//  Peeroleum_deliver and drained by inbox.do(). do() serialises these — one at a time, in arrival
//   order, each awaited — so this is the per-frame logic only; the old %queued/%handling lock is gone
//    (do()'s await-loop + the beliefs mutex are the serializer). Walk: a pre-%Ud frame may only be
//     hello|noop (spec §7.3); verify the body_hash (awaited sha256; header-sign verify lands here too);
//      then deliver to the hear_* / registered handler for its type. On success: mark %done+%to, finish
//       the req, ack the sender (spec §7.2). On a verify/deliver failure: mark %error, finish, roll up to
//        %faulty. w/pier/frame ride the req's .c (stashed at booking — cheaper than the deep c.up walk).
async req_unemit(req):
    const H = this
    let inbox = req.c.up
    let w = req.c.w
    let pier = req.c.pier
    let frame = req.c.frame
    let h = (frame && frame.header) || {}
    let pre_ud = !pier.oa({Ud:1})
    let ok = !(pre_ud && h.type !== 'hello' && h.type !== 'noop')
    let reason = pre_ud ? 'pre-Ud' : 'not-them'
    // body integrity (spec §4.2: header.body_hash covers the body) is part of verify, checked
    //  BEFORE delivery so a corrupt body fails identically to a tweaked header-sign — same
    //   %error→%faulty path. The digest is an AWAITED sha256 over the off-snap raw buffer
    //    (Peeroleum_body_digest); a mismatch is bad-body-hash. Header-sign verify lands here too.
    if (ok && h.body_hash != null && (await H.Peeroleum_body_digest(frame.buffer)) !== h.body_hash) {
        ok = false; reason = 'bad-body-hash'
    }
    if (ok) {
        let on = w.c.on && w.c.on[h.type]
        if (h.type === 'hello') ok = (await H.hear_hello(w, pier, frame)) !== false
        else if (h.type === 'trust') ok = (await H.hear_trust(w, pier, frame)) !== false
        else if (on) ok = (await on(w, pier, frame)) !== false
        else if (h.type !== 'noop') console.warn(`🛰⚠ Peeroleum: NO handler for frame type '${h.type}' from ${h.from} — acked but the work is LOST (typo'd handler? an editor-only frame reached a runner or vice-versa?). Robustness_plan Organ 2 — escalate to faulty/dont-ack once a live run proves no legit send-without-handler type retx-wedges.`)
        // else (noop): nothing to deliver — legitimately done, then acked.  An UNREGISTERED type now
        //  warns loudly above (was a silent ack — the "lies upward" bug); delivery is unchanged for now.
    }
    if (ok) {
        req.sc.done = 1
        req.sc.to = h.type
        inbox.finish(req)
        let me = pier.c.up%name
        H.Peeroleum_send(w, {header:{type:'ack', from:me, to:pier%pub, ack:h.seq}})
    } else {
        req.sc.error = reason
        inbox.finish(req)
        H.Peeroleum_rollup_faulty(pier)
    }

// Peeroleum_take_ack — an inbound ack names a seq we sent (spec §7.2): stamp that
//  %outbox/emit %acked, and the matching protocol %said too (spec §6, so the handshake's
//   acked-ness is visible). Acks book no inbox item and run no protocol handler.
Peeroleum_take_ack(w, pier, h):
    let emit = pier.o({outbox:1})[0]?.o({emit:1}).find(e => e.sc.seq == h.ack)
    if (emit) { emit.sc.acked = 1; pier.bump() }
    let hit = !!emit
    let proto = pier.o({protocol:1})[0]
    for (const kind of ['hello','trust']) {
        let said = proto?.o({[kind]:1})[0]?.o({said:1})[0]
        if (said && said.sc.seq == h.ack) { said.sc.acked = 1; hit = true }
    }
    return hit

// Peeroleum_rollup_faulty — rebuild %faulty from the inbox's %error items (spec §9).
//  A roll-up present only while something is wrong; the detail stays on the unemit. Run
//   on every fault and at the step boundary, so a cleared inbox drops a stale %faulty.
Peeroleum_rollup_faulty(pier):
    let inbox = pier.o({inbox:1})[0]
    let errs = inbox ? inbox.o({req:'unemit'}).filter(u => u.sc.error) : []
    let faulty = pier.o({faulty:1})[0]
    if (!errs.length) { if (faulty) pier.drop(faulty); return }
    faulty ||= pier.i({faulty:1})
    faulty.r({unemit:1}, {})
    for (const u of errs) faulty.i({unemit:u.sc.seq, error:u.sc.error, seq:u.sc.seq})

// Peeroleum_reset_handshake — the clean particle reset behind a re-dial (spec §9). A dead carrier makes every
//  fact about THIS connection stale, so drop them all: protocol/**, outbox, inbox, faulty, the handshake %req,
//   and the carrier-down signals (%stalled outbound, %silent inbound) that flagged the death. KEEP %Ud — we
//    still know who they are across a reconnect, the one fact a reset must never reach. The fresh carrier re-
//     runs hello/trust from zero.
//  Runtime .c for the dead stream goes too: c.connection (the dead handle) and c.held (frames buffered behind a
//   now-irrelevant gap). last_heard_tick is CLEARED, not kept: a stale "last heard long ago" would make the
//    silence sweep re-latch %silent on the brand-new carrier instantly and loop the re-dial — clearing it means
//     the Pier reads "never heard" until the new carrier actually delivers, a fresh silence window. The seq
//      CURSOR `c.inseq.last` (and c.seq) is KEPT: it only ever climbs, so continuity costs nothing and dodges the
//       epoch-handshake (heading 8) a seq-reset would demand of BOTH sides. But `c.inseq.buffered` is CLEARED with
//        c.held — they are two halves of one fact (the held tail: buffered = its seq NUMBERS, held = its FRAMES).
//         Dropping the frames but keeping the numbers leaves inseq believing those seqs are ready: the re-supplied
//          tail would drain the ghost slots with no frame (silently skipped), then dedup the real re-sends — data
//           lost on a reconnect that lands mid-gap. (Found by the storm_redial braid; the lone reset test had an
//            empty buffered, so it never saw it.) The sender's emits for the held tail are un-acked → retx resupplies.
Peeroleum_reset_handshake(pier):
    for (const key of ['protocol', 'outbox', 'inbox', 'faulty', 'stalled', 'silent']) {
        let n = pier.o({[key]: 1})[0]
        if (n) pier.drop(n)
    }
    let hs = pier.o({req: 'handshake'})[0]
    if (hs) pier.drop(hs)
    delete pier.c.connection
    delete pier.c.held
    if (pier.c.inseq) pier.c.inseq.buffered = []   // drop the held-tail seqs with the held frames (keep last)
    delete pier.c.last_heard_tick

// ── retransmit sweep (Reliable.g: retx_due) ───────────────────────────────────
// Peeroleum_retx_sweep — the retransmitter the %outbox/emit queue was always waiting for. Each step
//  boundary advances a per-w LOGICAL tick (w.c.retx_tick — replay-safe, never ms) and, per Pier, asks
//   retx_due which un-acked emits' backoff windows have elapsed: re-hand each emit.c.frame to the
//    CURRENT active transport (no new emit booked — the same seq, which the peer's inseq dedups), bump
//     its attempts/sent_tick, mark %resent. Exhausted emits roll up %stalled and are culled (below).
//      Dormant on a clean stream: emits ack within the step, so retx_due skips them (acked), nothing re-sends.
//   The retransmit policy is per-w (w.c.retx_policy), so an adversarial Story can tighten it to land a
//    death in a couple ticks; it defaults to the production {base:2, factor:2, max_attempts:5, cap:16}.
Peeroleum_retx_sweep(w):
    const H = this
    w.c.retx_tick = (w.c.retx_tick || 0) + 1
    let now = w.c.retx_tick
    for (const peering of w.o({Peering:1})) {
        // policy is per-Peering (a swarm peer can tighten its own backoff — the stall test does),
        //  falling back to the w default; the carrier is this Peering's (or the single w one).
        let policy = peering.c.retx_policy || w.c.retx_policy || {base: 2, factor: 2, max_attempts: 5, cap: 16}
        let conn = H.Peeroleum_carrier(peering, w)
        for (const pier of peering.o({Pier:1})) {
            let outbox = pier.o({outbox:1})[0]
            if (!outbox) continue
            let emits = outbox.o({emit:1})
            let snap = emits.map(e => ({seq: e.sc.seq, sent_tick: e.c.sent_tick || 0, attempts: e.c.attempts || 1, acked: e.sc.acked}))
            let verdict = H.retx_due(snap, now, policy)
            for (const seq of verdict.resend) {
                let emit = emits.find(e => e.sc.seq == seq)
                if (!emit || !emit.c.frame) continue
                emit.c.attempts = (emit.c.attempts || 1) + 1
                emit.c.sent_tick = now
                emit.sc.resent = emit.c.attempts
                conn?.send(emit.c.frame)
            }
            for (const seq of verdict.dead) {
                let emit = emits.find(e => e.sc.seq == seq)
                if (!emit) continue
                try {
                    // latch the carrier-down signal: a %stalled container holding the emit that died (one
                    //  per dead frame — parallel to %faulty over %unemit). The durable record a re-dial reads
                    //   (heading 8); it does NOT rebuild like %faulty (the emit is gone), so only
                    //    reset_handshake clears it. Inlined (no separate method) so an HMR mid-update can't
                    //     leave the call dangling — the desync that froze a sweep once.
                    let stalled = pier.o({stalled:1})[0]
                    stalled ||= pier.i({stalled:1})
                    stalled.i({emit: emit.sc.seq, type: emit.sc.type, seq: emit.sc.seq, reason: 'no-ack'})
                    outbox.drop(emit)                      // then cull — else it re-dies every sweep
                } catch (err) {
                    // a throw here MUST NOT break the rearm: a frozen sweep silently strands every later
                    //  frame on this w. Surface the cause in the snap (not just console) so it is never a guess.
                    let msg = (err && err.message || String(err)).slice(0, 60)
                    if (!pier.o({stall_err:1})[0]) pier.i({stall_err:1, msg})
                    console.error(`⚠ Peeroleum stall stamp threw seq=${seq}: ${msg}`, err)
                }
            }
        }
    }

// ── inbound-silence liveness sweep (Reliable.g: the inbound twin of retx_due) ──
// Peeroleum_liveness_sweep — the inbound half of carrier-down detection. retx_due/%stalled catches "I sent
//  and heard no ack"; this catches the symmetric "I was hearing them and they went silent" — a peer whose
//   carrier died while I had nothing outbound to stall on. Per Pier: silence = now - last_heard_tick (logical
//    ticks). Past the window, latch %silent,reason:no-inbound — latched (one-shot, like %stalled), the durable
//     carrier-down signal a re-dial reads. Only reset_handshake clears it.
//  OPT-IN, by design: it engages ONLY where the Peering's policy carries a `silence_dead` window. Production's
//   inbound-silence detector is the wall-clock keepalive (handover §8); THIS logical-tick path is the replay-
//    safe primitive a deterministic Story arms (tighten silence_dead, like the stall test tightens retx_policy),
//     so the gate stays provably dormant on every link that doesn't ask for it — an idle-but-alive channel with
//      no keepalive looks silent, so a blanket default would false-trip the quiet peers of an existing run.
//  GATE: only a Pier that has HEARD at least once (last_heard_tick set) can "go silent" — a never-heard Pier is
//   a handshake-never-started fault, not this one. Skipped once %silent is latched, so it fires exactly once.
Peeroleum_liveness_sweep(w):
    let now = w.c.retx_tick || 0
    for (const peering of w.o({Peering:1})) {
        let policy = peering.c.retx_policy || w.c.retx_policy
        let dead = policy && policy.silence_dead
        if (!dead) continue                                   // opt-in: no window → no inbound-silence check
        for (const pier of peering.o({Pier:1})) {
            let heard = pier.c.last_heard_tick
            if (heard == null) continue                       // never heard → not "went silent" (a different fault)
            if (pier.oa({silent:1})) continue                 // latched already → one-shot
            if (now - heard >= dead) pier.i({silent:1, reason:'no-inbound', since:heard})
        }
    }

// ── step-boundary whittle (spec §7.4, §12.1) ──────────────────────────────────
// Peeroleum_arm_whittle — register the per-w sweeps at each step boundary, re-arming itself each pass
//  (the logger idiom: Runstepped drains its queue every boundary, so a standing callback must re-push).
//   Guarded so a w arms exactly once. Runs in Atime (clear()), so drop/r/i are safe. Retransmit sweeps
//    BEFORE the cull (re-send the un-acked, then archive the acked — disjoint sets, order is just intent).
//  The body is try/caught so a throw in any sweep can NEVER skip rearm(): a frozen heartbeat silently
//   strands every later frame on this w (the freeze-scare, handover §8). The cause surfaces (console), and
//    the next boundary still sweeps — strictly safer than the bare chain that froze once.
Peeroleum_arm_whittle(w):
    const H = this
    if (w.c._whittle_armed) return
    w.c._whittle_armed = 1
    let rearm = () => H.Runstepped(async () => {
        try { H.Peeroleum_retx_sweep(w); H.Peeroleum_liveness_sweep(w); H.Peeroleum_runstepped(w) }
        catch (e) { console.error('⚠ Peeroleum whittle sweep threw — rearming anyway', e) }
        rearm()
    })
    rearm()

// Peeroleum_runstepped — the cull, per Pier under w (spec §7.4): acked %outbox/emit move
//  to %outbox/recent (whittled 20); %done %inbox/unemit move to %inbox/recent (whittled
//   20); %faulty is rebuilt from any remaining inbox errors (faults are kept, not culled).
//    %recent items carry only their emit|unemit/type/seq — no flags, no time (record order
//     is the order). This is the one place outbox/inbox items vanish, so the snap taken
//      *before* this boundary always shows the step's traffic (spec §12.1).
Peeroleum_runstepped(w):
    const H = this
    for (const peering of w.o({Peering:1})) {
        for (const pier of peering.o({Pier:1})) {
            let outbox = pier.o({outbox:1})[0]
            if (outbox) {
                let recent = outbox.oai({recent:1})
                for (const e of outbox.o({emit:1}).filter(e => e.sc.acked)) {
                    recent.i({emit:e.sc.emit, type:e.sc.type, seq:e.sc.seq})
                    outbox.drop(e)
                }
                H.whittle_N(recent.o({emit:1}), 20)
            }
            let inbox = pier.o({inbox:1})[0]
            if (inbox) {
                let recent = inbox.oai({recent:1})
                for (const u of inbox.o({req:'unemit'}).filter(u => u.sc.done)) {
                    recent.i({unemit:u.sc.seq, type:u.sc.type, seq:u.sc.seq})
                    inbox.drop(u)
                }
                H.whittle_N(recent.o({unemit:1}), 20)
            }
            H.Peeroleum_rollup_faulty(pier)
        }
    }
