
// Tribunal — a peer connection's reputation, constantly on trial (spec §4.1, §11.2,
//  §13). WebRTC is always tried first: a direct DataChannel is the fastest carrier
//   when the network allows it, so it must EARN the carrier role rather than be
//    trusted. The trial is classic no-ack-then-give-up: send a probe over the current
//     carrier and wait; if no ack lands inside the window, the carrier is stamped
//      %faulty,reason:no-ack (it stays visible — the user can be told their network
//       throttles direct peer links) and the carrier falls to the websocket relay.
//        The select req is eternal: the carrier never stops being on trial.
//  Separated from the Peeroleum spine (envelope/handshake/inbox) as its own flavour.
//  Headings 9/10. Progress in Peeroleum_handover.md.

// PeerJS — the WebRTC carrier. Under the mock its port is a BLACK HOLE: send drops
//  the frame on the floor (no partner, no recv), so no ack ever returns — exactly the
//   silence the trial gives up on. The real PeerJS DataChannel is heading 9; note the
//    app-level no-ack timeout this models stays needed even then — PeerJS reports
//     connection-level errors (peer-unavailable, ICE failure, onclose) for free, but a
//      channel that opens then goes silent on a NAT rebind acks nothing and fires no
//       event. That silence is only catchable here.
PeerJS(A,w):
    const H = this
    w i %transport,type:webrtc
    // < the live port is an object on .c (a transport seam): a black-hole send.
    let port = { type: 'webrtc', partner: null,
        send(frame) { /* oppressed: dropped, no delivery, no ack */ },
        recv(frame) { H.Peeroleum_deliver(w, frame) } }
    w.o({ transport: 1, type: 'webrtc' })[0].c.port = port

// Socket — the WebSocket relay carrier. Under the mock its port rides the same in-
//  process shared queue as the mock transport (the wrangler pairs the two sides), so
//   the fallback delivers for real with no relay server. The real /relay endpoint on
//    the dev server is heading 10.
Socket(A,w):
    const H = this
    w i %transport,type:websocket
    // < the live port is an object on .c (a transport seam): a working shared-queue
    //    port, partner paired across the two sides by the wrangler (cf transport()).
    let port = { type: 'websocket', partner: null,
        send(frame) { H.post_do(async () => this.partner?.recv(frame)) },
        recv(frame) { H.Peeroleum_deliver(w, frame) } }
    w.o({ transport: 1, type: 'websocket' })[0].c.port = port

// Tribunal_hand_to_webrtc — repoint the single live %active_transport (the mock
//  carrier from step 2) at the webrtc port, to start its trial. The active_transport
//   slot is what Peeroleum_send reads, so handing it a new .c.connection is the whole
//    of "switch carriers". Called per side by the wrangler at step 4.
Tribunal_hand_to_webrtc(w):
    let at = w.o({ active_transport: 1 })[0]
    let webrtc = w.o({ transport: 1, type: 'webrtc' })[0]
    at.sc.type = 'webrtc'
    at.c.connection = webrtc.c.port   // < .c port handoff (transport seam)

// Tribunal_pair_websocket — pair the two sides' websocket ports so the relay
//  delivers each side into the other (cf the mock-port pairing in Lake_sides_up).
//   Objects-on-.c → raw JS. Called once by the wrangler with both sides' w.
Tribunal_pair_websocket(wB, wN):
    let bport = wB.o({ transport: 1, type: 'websocket' })[0].c.port
    let nport = wN.o({ transport: 1, type: 'websocket' })[0].c.port
    bport.partner = nport
    nport.partner = bport

// req_transport_select — the trial (spec §4.1, §11.2, §13). The carrier is on trial:
//  it must get a probe acked or be demoted.
//   first pass — send a noop probe over the current carrier (webrtc) and arm the wait.
//    A ttlilt (the waiting-req, heading 5) holds the Story snap open across the window;
//     a single re-drive timer brings think back when it elapses, because the ttlilt
//      alone never re-fires think (cf MachPeerily's setTimeout(feebly_ponder)).
//   probe acked — the carrier earned it: record %reputation:good and settle.
//   window elapsed, still no ack — no-ack-then-give-up: stamp the carrier
//    %faulty,reason:no-ack, fall to websocket, and re-probe over the working relay.
//  Eternal: once settled it idles, but the carrier stays on trial for a future pass
//   (a real retry of webrtc is heading 9/10). The probe's outbox emit is the evidence,
//    so we read it before the step-boundary whittle moves it to %recent (then settled
//     short-circuits). do_fn body is .c/timer/object heavy — a transport seam, raw JS.
async req_transport_select(req):
    const H = this
    if (req.c.settled) { req.sc.ok = 1; return }
    let peering = req.c.up
    let w = peering.c.up
    let at = w.o({ active_transport: 1 })[0]
    let pier = peering.o({ Pier: 1 })[0]
    if (!at || !pier) { req.sc.ok = 1; return }
    let me = peering.sc.name
    let probe = (seq) => H.Peeroleum_send(w, { header: { type: 'noop', from: me, to: pier.sc.pub, seq } })

    // first pass: probe the current carrier and start the clock.
    if (!req.c.probed) {
        req.c.probed = 1
        req.c.probe_seq = H.Pier_next_seq(pier)
        probe(req.c.probe_seq)
        H.i_req_ttlilt(req, 3, { waiting: 1, for: 'carrier_ack' })   // hold the snap open
        // < re-drive: the ttlilt holds the snap but never re-fires think; one timer does.
        setTimeout(() => { req.c.window_elapsed = 1; H.feebly_ponder() }, 3000)
        req.sc.ok = 1
        return
    }

    // did the probe get acked? its outbox emit carries %acked once the ack lands.
    let emit = pier.o({ outbox: 1 })[0]?.o({ emit: req.c.probe_seq })[0]
    if (emit?.sc.acked) {
        let carrier = w.o({ transport: 1, type: at.sc.type })[0]
        if (carrier && !carrier.oa({ reputation: 'good' })) carrier.i({ reputation: 'good' })
        req.c.settled = 1
        req.sc.ok = 1
        return
    }

    // no ack yet and the window is still open — keep waiting.
    if (!req.c.window_elapsed) { req.sc.ok = 1; return }

    // no-ack-then-give-up: demote webrtc and fall the carrier to the websocket relay.
    if (at.sc.type === 'webrtc') {
        let webrtc = w.o({ transport: 1, type: 'webrtc' })[0]
        webrtc.sc.faulty = 1
        webrtc.sc.reason = 'no-ack'
        let ws = w.o({ transport: 1, type: 'websocket' })[0]
        at.sc.type = 'websocket'
        at.sc.open = 1
        at.c.connection = ws.c.port    // < .c port handoff (transport seam)
        // re-probe over the relay; its ack stamps a fresh emit %acked on a later pass.
        //  Re-arm a short waiting-req (a fresh `for:` phase, spec §13.3) so the snap
        //   stays open across the relay round-trip — the original carrier_ack window
        //    has elapsed by now. Both sides demote on the same ~3s window, so the ack
        //     only lands once the peer is also on websocket; this holds for that.
        req.c.probe_seq = H.Pier_next_seq(pier)
        req.c.window_elapsed = 0
        probe(req.c.probe_seq)
        H.i_req_ttlilt(req, 2, { waiting: 1, for: 'relay_ack' })
        H.feebly_ponder()
    }
    req.sc.ok = 1
