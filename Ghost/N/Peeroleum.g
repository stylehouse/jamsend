
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
    await w.do()

// %req:p2pman — top desire: a %Peering per online identity. Eternal foreman:
//  pump children, then settle the gate for this tick with %ok (re-armed next tick).
async req_p2pman(req):
    // < ensure a %Peering per identity-thang with online_want (spec §11.1);
    //    for the spine the wrangler lays the sides directly.
    await req.do()
    req.sc.ok = 1

// ── per-identity worker ───────────────────────────────────────────────────────
// A:Bearing/w:Peeroleum — one per identity-presence; owns this address's Piers.
async Peeroleum(A,w):
    // each installed %Peering manages its own Piers via %req:p2paddy
    S o Peering
        Peering oai %req:p2paddy
    await w.do()

// %req:p2paddy — maintain this Peering's Piers + pick a transport.
async req_p2paddy(req):
    req oai %req:transport_select
    // < per known peer: seed %req:dial → ensure a %Pier → seed its %req:handshake
    //    (spec §11.2). Roll-up finishes p2paddy when its children settle.
    await req.do()
    req.sc.ok = 1

// ── the handshake (hello + trust) as %req (spec §8) ───────────────────────────
// Four maz-ordered leaves under a %Pier: highest maz runs first, lower gated behind.
//  Each leaf finishes when its protocol particle exists; the parent rolls up when
//  all four are done. The leaf do_fns + say/hear exchange are just below.
async req_handshake(req):
    req oai %req:said_hello,maz:4
    req oai %req:heard_hello,maz:3
    req oai %req:said_trust,maz:2
    req oai %req:heard_trust
    await req.do()
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
//     %pub is the peer it faces, and the publicKey we send IS our name (verify is
//      then startsWith(pub)). seq: hello=1, trust=2 (per-type, heading-3 minimal;
//       the monotone per-Pier counter + acks are heading 4).
say_hello(w, pier):
    let proto = pier oai protocol
    let hello = proto oai hello
    if (hello.oa({said:1})) return
    hello i said,seq:1
    let me = pier.c.up.sc.name
    &Peeroleum_send,w,{header:{type:'hello', from:me, to:pier.sc.pub, seq:1, publicKey:me}}

say_trust(w, pier):
    let proto = pier oai protocol
    let trust = proto oai trust
    if (trust.oa({said:1})) return
    trust i said,seq:2
    let me = pier.c.up.sc.name
    &Peeroleum_send,w,{header:{type:'trust', from:me, to:pier.sc.pub, seq:2}}

// hear_hello — verify their key starts-with the pub we expect, record %heard +
//  the proven publicKey, set %Ud (their identity, survives resets — spec §6), and
//   if we have not said yet, say now (the single-initiator path; a no-op under the
//    symmetric dual-init). A failed verify writes nothing — the gap is the result
//     (spec §8: a corrupt hello that never arrives is the test passing).
hear_hello(w, pier, frame):
    const H = this
    let h = frame.header
    if (!String(h.publicKey).startsWith(pier.sc.pub)) return
    let hello = pier.oai({protocol: 1}).oai({hello: 1})
    hello.i({heard: 1, publicKey: h.publicKey})
    pier.oai({Ud: 1, publicKey: h.publicKey})
    if (!hello.oa({said: 1})) H.say_hello(w, pier)

// hear_trust — verify their grants (trivial under the mock) and record %heard.
hear_trust(w, pier, frame):
    pier.oai({protocol: 1}).oai({trust: 1}).i({heard: 1})

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
    at.c.connection = {
        type: 'mock', partner: null,
        send(frame) { H.post_do(async () => this.partner?.recv(frame)) },
        recv(frame) { H.Peeroleum_deliver(w, frame) },
    }

// PeerJS DataChannel: present, and in the spine immediately marked faulty so
//  selection falls through to the websocket relay — models "WebRTC is sucking"
//  deterministically under the mock. The real DataChannel path is heading 9.
PeerJS(A,w):
    w i %transport,type:webrtc,faulty,reason:no-direct-route

// The websocket relay — proxy every frame via the webserver's websocket when
//  WebRTC is being oppressed. Modeled this pass: c.connection rides the same
//  in-process shared queue as the mock, so the fallback is provable with no relay
//  server. The real /relay endpoint on the dev server is heading 10.
Socket(A,w):
    w i %transport,type:websocket
    // < c.connection = the shared-queue mock-port (raw JS), same as transport()

// %req:transport_select — try webrtc, fall through to websocket on faulty, point
//  %active_transport at it and leave webrtc present-and-faulty (spec §4.1, §11.2).
req_transport_select(req):
    let peering = req.c.up
    if (peering.o({transport:1, type:'webrtc'})[0]?.sc.faulty) peering.i({active_transport:1, type:'websocket', open:1})
    req.sc.ok = 1

// ── send / deliver — the one envelope across the active transport (spec §4.3) ──
// Peeroleum_send — hand a frame to this side's active transport, stamping a
//  %outbox/emit,sent on the sender's Pier (spec §7.1). Heading-2 minimal: %sent
//   only; acks + the rest of the outbox states are heading 4. Objects-on-.c and
//    drilled paths are LangTiles seams, so the body is raw JS.
Peeroleum_send(w, frame):
    let h = frame.header
    let pier = w.o({Peering:1})[0]?.o({Pier:1})[0]
    if (pier) pier.oai({outbox: 1}).i({emit: h.seq, type: h.type, seq: h.seq, sent: 1})
    w.o({active_transport:1})[0]?.c.connection?.send(frame)

// Peeroleum_deliver — land an inbound frame in this side's Pier inbox (spec §6,
//  §7.3). Heading-2 minimal: one %inbox/%unemit:seq,delivered; the full serial
//   handling (queued→handling→verified→delivered) + acks is heading 4. Runs
//    inside the carrier's post_do (Runtime asserted), so re-drive a think so a
//     watching do_fn (the wrangler's witness) reacts this same run.
Peeroleum_deliver(w, frame):
    const H = this
    let h = frame.header
    let pier = w.o({Peering:1})[0]?.o({Pier:1})[0]
    if (!pier) return
    pier.oai({inbox: 1}).i({unemit: h.seq, type: h.type, seq: h.seq, delivered: 1})
    // dispatch the protocol frame to its hear_* handler (acks are heading 4).
    if (h.type === 'hello') H.hear_hello(w, pier, frame)
    else if (h.type === 'trust') H.hear_trust(w, pier, frame)
    H.feebly_ponder()
