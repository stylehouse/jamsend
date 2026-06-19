
// Tribunal — a peer connection's reputation, constantly on trial (spec §4.1, §11.2).
//  WebRTC is always tried first: a direct DataChannel is the fastest carrier when the
//   network allows it, so it must EARN the carrier role rather than be trusted. The
//    trial is classic no-ack-then-give-up: hand the carrier to webrtc and probe it; if
//     no ack comes back, webrtc is stamped %faulty,reason:no-ack (it stays visible — the
//      user can be told their network throttles direct peer links) and the carrier falls
//       to the websocket relay, which then proves it carries.
//  The trial is paced by Story STEPS, not a wall-clock window: webrtc on step 4, detect
//   the no-ack and fall to websocket on step 5, confirm the relay carries on step 6. A
//    step boundary is a quiescence point (acks flush), so each phase gets a clean snap —
//     and there is no ttlilt/timer racing the snap (the wall-clock version did, and the
//      demotion lost the race). The wrangler (Lake_trial_*) drives the phases; this dock
//       owns the transport mechanics. Headings 9/10. Progress in Peeroleum_handover.md.

// PeerJS — the WebRTC carrier. Under the mock its port is a BLACK HOLE: send drops the
//  frame on the floor (no partner, no recv), so no ack ever returns — exactly the
//   silence the trial gives up on. The real PeerJS DataChannel is heading 9; note the
//    app-level no-ack timeout this models stays needed even then — PeerJS reports
//     connection-level errors (peer-unavailable, ICE failure, onclose) for free, but a
//      channel that opens then goes silent on a NAT rebind acks nothing and fires no
//       event. That silence is only catchable here.
PeerJS(w):
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
Socket(w):
    const H = this
    w i %transport,type:websocket
    // < the live port is an object on .c (a transport seam): a working shared-queue
    //    port, partner paired across the two sides by the wrangler (cf transport()).
    let port = { type: 'websocket', partner: null,
        send(frame) { H.post_do(async () => this.partner?.recv(frame)) },
        recv(frame) { H.Peeroleum_deliver(w, frame) } }
    w.o({ transport: 1, type: 'websocket' })[0].c.port = port

// Socket_real — the REAL websocket carrier (heading 10), for actual peers across two origins
//  (editor↔runner). Unlike Socket (the in-process mock the deterministic Story test pairs), this
//   opens a native WebSocket to our OWN-origin /relay?addr=<our id>; the relay routes by header.to
//    (locally, or once over the relay↔relay bridge to the other origin). addr is our Peering %name.
//     The mock stays untouched so the Peregrination test keeps its determinism; this is the
//      production path, installed by the consumer (Lies) for a real channel. Raw JS: WebSocket +
//       location + objects-on-.c are all transport seams. Delivery is wrapped in post_do so an
//        inbound frame off the (async, off-tick) socket lands in Atime, exactly as the mock's
//         partner.recv does — Peeroleum_deliver then feebly_ponders so a watching do_fn reacts.
Socket_real(w):
    const H = this
    w i %transport,type:websocket
    // < the live port is a real WebSocket on .c (the transport seam). send buffers until OPEN;
    //    onmessage parses a frame and delivers it through the same Peeroleum_deliver path.
    let peering = w.o({ Peering: 1 })[0]
    let addr = (peering && peering.sc.name) || ''
    let scheme = (location.protocol === 'https:') ? 'wss' : 'ws'
    let url = scheme + '://' + location.host + '/relay?addr=' + encodeURIComponent(addr)
    let pending = []
    let ws = new WebSocket(url)
    // Heartbeat traffic floods the console once the channel is healthy — log everything BUT
    //  ping/pong/ack, so dock_push/run_result/hello/trust still show. (A buffered send is
    //   always logged: it only happens before the socket opens, which is worth seeing.)
    let noisy = (h) => h && (h.type === 'ping' || h.type === 'pong' || h.type === 'ack')
    let port = {
        type: 'websocket', real: 1, ws,
        send(frame) {
            let h = frame && frame.header
            if (ws.readyState !== WebSocket.OPEN) { pending.push(frame); console.log(`🛰 ws SEND buffered (socket not open): ${h && h.type}`); return }
            if (!noisy(h)) console.log(`🛰 ws SEND ${h ? h.type + ' seq=' + h.seq + ' → ' + h.to : '(control)'}`)
            ws.send(JSON.stringify(frame))
        },
        recv(frame) { H.Peeroleum_deliver(w, frame) },
        close() { try { ws.close() } catch (e) {} },
    }
    ws.onopen = () => { console.log(`🛰 ws OPEN ${url} — flushing ${pending.length} buffered`); let q = pending.splice(0); for (const f of q) ws.send(JSON.stringify(f)) }
    ws.onclose = (ev) => console.log(`🛰 ws CLOSE code=${ev.code} clean=${ev.wasClean}`)
    ws.onerror = () => console.log(`🛰 ws ERROR (relay down? wrong origin?)`)
    ws.onmessage = (ev) => H.post_do(async () => {
        let frame
        try { frame = JSON.parse(ev.data) } catch (e) { return }
        // The relay speaks two things over this one socket: Peeroleum envelopes (carry a
        //  %header, routed by header.to) and its own control frames (role-confirm, error —
        //   no header).  Only envelopes belong in the deliver path; a control frame has
        //    nothing to deliver, so route it aside rather than dereference a missing header.
        if (frame && frame.control) {
            // The relay echoes its own server-side logs here (control:log) and the state of
            //  the server↔server bridge (control:peer-relay) so both surface in THIS origin's
            //   browser console — the server's own console.log is otherwise buried in the
            //    dev-server terminal among svelte-check noise.
            if (frame.control === 'log') { console.log(frame.line); return }
            if (frame.control === 'peer-relay') {
                let m = frame.up ? `🌉 relay bridge UP${frame.target ? ' → ' + frame.target : ''}` : `🌉 relay bridge DOWN — error=${frame.error || '?'}${frame.detail ? ' — ' + frame.detail : ''}`
                ;(frame.up ? console.log : console.warn)(m)
                return
            }
            console.log(`🛰 ws RECV control:${frame.control}${frame.role ? ' role=' + frame.role : ''}`)
            if (frame.control === 'error') console.warn('relay refused:', frame.error)
            return
        }
        let h = frame && frame.header
        if (!noisy(h)) console.log(`🛰 ws RECV ${h ? h.type + ' seq=' + h.seq + ' ← ' + h.from : '(headerless, dropped)'}`)
        port.recv(frame)
    })
    w.o({ transport: 1, type: 'websocket' })[0].c.port = port

// Tribunal_activate_websocket — point the live %active_transport at the websocket carrier WITHOUT
//  the no-ack trial (cf Tribunal_fall_to_websocket, which also stamps webrtc %faulty). For the
//   editor↔runner channel the relay is the chosen carrier from the start, so there is no webrtc
//    probe to demote — just open the relay and carry. Called by the consumer after Socket_real.
Tribunal_activate_websocket(w):
    // oai not o: the mock wrangler pre-creates %active_transport (its step 2), but the
    //  editor↔runner channel has no such step — activate IS where the slot is born, so
    //   create-or-find it.  Absent, Peeroleum_send found no .c.connection and dropped
    //    every envelope (hello, dock_push) while only direct-ws control frames crossed.
    let at = w.oai({ active_transport: 1 })
    let ws = w.o({ transport: 1, type: 'websocket' })[0]
    if (!ws) return
    at.sc.type = 'websocket'
    at.sc.open = 1
    at.c.connection = ws.c.port       // < .c port handoff (transport seam)

// Tribunal_hand_to_webrtc — repoint the single live %active_transport (the mock carrier
//  from step 2) at the webrtc port, to start its trial. The active_transport slot is
//   what Peeroleum_send reads, so handing it a new .c.connection is the whole of "switch
//    carriers". Called per side by the wrangler at step 4.
Tribunal_hand_to_webrtc(w):
    let at = w.o({ active_transport: 1 })[0]
    let webrtc = w.o({ transport: 1, type: 'webrtc' })[0]
    if (!at || !webrtc) return
    at.sc.type = 'webrtc'
    at.c.connection = webrtc.c.port   // < .c port handoff (transport seam)

// Tribunal_pair_websocket — pair the two sides' websocket ports so the relay delivers
//  each side into the other (cf the mock-port pairing in Lake_sides_up). Objects-on-.c
//   → raw JS. Called once by the wrangler with both sides' w.
Tribunal_pair_websocket(wB, wN):
    let bt = wB.o({ transport: 1, type: 'websocket' })[0]
    let nt = wN.o({ transport: 1, type: 'websocket' })[0]
    if (!bt || !nt) return
    bt.c.port.partner = nt.c.port
    nt.c.port.partner = bt.c.port

// Tribunal_fall_to_websocket — no-ack-then-give-up: stamp the webrtc carrier
//  %faulty,reason:no-ack (left present and visible) and repoint %active_transport at the
//   websocket relay port. Called per side by the wrangler at step 5 once the step-4
//    webrtc probe is seen un-acked.
Tribunal_fall_to_websocket(w):
    let at = w.o({ active_transport: 1 })[0]
    let webrtc = w.o({ transport: 1, type: 'webrtc' })[0]
    let ws = w.o({ transport: 1, type: 'websocket' })[0]
    if (!at || !ws) return
    if (webrtc) { webrtc.sc.faulty = 1; webrtc.sc.reason = 'no-ack' }
    at.sc.type = 'websocket'
    at.sc.open = 1
    at.c.connection = ws.c.port       // < .c port handoff (transport seam)

// Tribunal_reputation_good — bless the active carrier's %transport with
//  %reputation:good. Called per side by the wrangler at step 6 once the relay probe has
//   come back acked (proof the carrier actually carries, not just that we switched).
Tribunal_reputation_good(w):
    let at = w.o({ active_transport: 1 })[0]
    let carrier = at && w.o({ transport: 1, type: at.sc.type })[0]
    if (carrier && !carrier.oa({ reputation: 'good' })) carrier.i({ reputation: 'good' })
