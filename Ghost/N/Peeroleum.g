
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
//  all four are done. Leaf do_fns (the say/hear writes) are headings 2-3.
async req_handshake(req):
    req oai %req:said_hello,maz:4
    req oai %req:heard_hello,maz:3
    req oai %req:said_trust,maz:2
    req oai %req:heard_trust
    await req.do()
    // < leaf do_fns: said_hello finishes when Pier/protocol/hello/%said exists, etc.
    //    Drilled existence checks + the e:hello/e:trust frame writes are raw JS the
    //     spine adds next; the cross-side short-circuit (spec §8) preserved there.
    if (req.all_finished() && !req.sc.finished) (req.c.up).finish(req)

// ── transports (spec §4) — one envelope, swappable carrier ────────────────────
// The mock: in-process, deterministic, tick-driven. Two mock-ports share a JS
//  array; delivery is H.post_do(() => partner inbox <- frame), instant, in Atime
//  (spec §15). The shared queue + c.connection are objects → they live on .c.
transport(A,w):
    w i %transport,type:mock
    w i %active_transport,type:mock
    // < wire the live handle + shared queue (raw JS, objects on .c):
    // <   let at = w.o({active_transport:1})[0]; at.c.connection = mock_port(shared)

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
