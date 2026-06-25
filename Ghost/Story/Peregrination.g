
// PereStaple — the Peeroleum p2p test (the outer test layer), and the first of a
//  new kind of runtime test.  (The Book / actor / per-beat handler are all PereStaple;
//   this source file stays Peregrination.g — the file is the artifact, the Book is the
//    identity.)  The Creduler (the runner Lies on H:Mundo) loads this ghost live BEFORE
//     the Story begins, so its sibling methods are on H; there is no hand-written
//      bootstrap anymore.  Run_A_PereStaple wires the Run, then the per-beat
//       PereStaple(A,w) installs the eternal %req:wrangle whose do_fn drives the *inner*
//        steps, starting at 2.  The toc.snap carries one `step,…` line per inner step
//         (real seq, lie diges till a run records them).
//
//  THE SHAPE — one world.  Every node lives under the test world w:PereStaple as a %Peering,name flock
//   (a typed serial-req, pumped by req_Peering) with its one %Pier,pub and its own mock
//    carrier.  No per-peer A:/w: actors, no hand-stamped c.up (oai wires Peering.c.up=w and
//     Pier.c.up=Peering): a peer is one Lake_peer, a link is one Lake_link.  The spine routes
//      a frame to the right Peering|Pier by identity (Peeroleum_route), so a node owns many
//       peers exactly as production does — where a w is a single identity the same route
//        short-circuits, so this is a test-only shape, not a spine fork.
//
//   step 2  the Alice↔Bob link up under w:PereStaple; a noop A→B proves carrier + ack
//   step 3  %req:handshake completes on both Piers; full outbox/inbox lifecycle + acks
//   step 4  transport trial: carriers up, carrier handed to webrtc, probe sent
//   step 5  no-ack-then-give-up: webrtc faulty, carrier falls to the websocket relay
//   step 6  the relay carries (probe acked) -> reputation:good on both carriers
//   step 7  binary exercise: a 64-byte frame A→B, body-hash verified, round-trips over the live carrier
//   step 8  reliability heal: a fresh link on a lossy carrier loses a frame; retransmit re-sends it,
//            playing out over steps 9-10 (logical-tick backoff) until the drop heals and acks
//   step 11 permanent fault: a fresh link on a blackhole carrier loses EVERY transit; the retransmits
//            exhaust and the emit latches %stalled (carrier-down) — the heal's twin
//
// The heading-4 message lifecycle (outbox created→sent→acked, serial inbox
//  queued→handling→verified→done, acks, %recent whittle at the step boundary) is not
//   its own step — it rides the traffic of steps 2 and 3, in the Peeroleum spine.
//
// Run_A_PereStaple — the Book's Run recipe (Story_subHouse calls it to wire the Run).
//  Lay the single test actor + its one world w:PereStaple; the role is already 'runner'
//   (Auto/boot) — this just guards it.
Run_A_PereStaple():
    this.c.role ??= 'runner'
    H i A:PereStaple/w:PereStaple

// We do NOT use H.on_step: it keys off one H-global `did_on_step_n`, which a step-1
//  table would claim when setup spills into step 2 — that starves step 2's setup (the
//   symptom: step 3 fires, step 2's sides never lay).  Lake_drive keeps a req-local
//    `did_step` instead, immune to any other caller.
PereStaple(A,w):
    w oai %req:wrangle,eternal
        await &Lake_drive,w,req
        req%ok = 1

// Lake_drive — the wrangle's own step dispatch. Fires a step's setup once, the
//  first pass it sees a new run step_n (read the same way on_step does), tracked
//   on req.c.did_step (runtime, unsnapped). Witness polls every pass after.
async Lake_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if n != null && n !== req.c.did_step
        req.c.did_step = n
        if n === 2
            await &Lake_sides_up,w
        else if n === 3
            await &Lake_handshake,w
        else if n === 4
            await &Lake_trial_arm,w
        else if n === 5
            await &Lake_trial_fallback,w
        else if n === 6
            await &Lake_trial_confirm,w
        else if n === 7
            await &Lake_exercise_binary,w
        else if n === 8
            await &Lake_heal_arm,w
        else if n === 11
            await &Lake_stall_arm,w
    await &Lake_pump_handshakes,w
    &Lake_witness,w
    await &Lake_order,w

// ── swarm helpers — stand up peers as %Peering/%Pier flocks under the one w:PereStaple ──
// A peer is one Lake_peer; a two-node link is one Lake_link.  No per-peer actor/world, no separate
//  transport/arm/pair dance — that whole double-handling is gone.

// Lake_peer — stand up one node-endpoint under w:PereStaple: a %Peering,name (→ req_Peering), its
//  %Pier,pub (→ req_Pier), and its own mock carrier on the Peering's %active_transport.  The mock-port
//   `send` posts to its partner; `recv` lands the frame back in the spine, which routes it to the right
//    Pier by identity.  Returns the Pier.  Objects-on-.c (the port) stay raw JS.
// c.up is HAND-STAMPED here, NOT left to oai: oai's c.up wiring on a typed serial-req is deferred to the
//  first pump, but Lake_link reads pier.c.up at SETUP time (step 2, before any pump) to find the carrier
//   to pair — so without this stamp pier.c.up is undefined, Lake_port throws, and the link never pairs
//    (the mock then never carries; the handshake says hello into the void). Stamp it now, like the old
//     wrangler did for the Peering.
Lake_peer(w, name, pub):
    const H = this
    let peering = w.oai({Peering: 1, name, req: 1})
    peering.c.up = w
    let pier = peering.oai({Pier: 1, pub, req: 1})
    pier.c.up = peering
    let at = peering.i({active_transport: 1, type: 'mock', open: 1})
    at.c.connection = {
        type: 'mock', partner: null, reliable: true,
        send(frame) { H.post_do(async () => { await this.partner?.recv(frame) }) },
        recv(frame) { return H.Peeroleum_deliver(w, frame) },
    }
    return pier

// Lake_link — a two-node link under w:PereStaple: stand up each side, pair their mock-ports so each
//  delivers into the other.  Returns [PierA, PierB].  This is the whole of "two peers talking".
// Lake_peer is auto-async'd by the compiler (the mock port's `send` closure carries a bare `await`,
//  which the auto-async heuristic catches and promotes the whole method) — so it returns a PROMISE,
//   not the Pier.  AWAIT it: an un-awaited `pa` is a Promise, and Lake_port(Promise) reads
//    `Promise.c.up` (undefined) and throws, so the link never pairs (the mock then never carries —
//     the bug that left the handshake saying hello into the void).  Lake_peer's body still runs
//      synchronously (no top-level await), so the Peerings exist; only the return needs awaiting.
async Lake_link(w, a, b):
    let pa = await this.Lake_peer(w, a, b)
    let pb = await this.Lake_peer(w, b, a)
    let porta = this.Lake_port(pa)
    let portb = this.Lake_port(pb)
    porta.partner = portb
    portb.partner = porta
    return [pa, pb]

// Lake_peering / Lake_pier / Lake_port — find a node's %Peering | its %Pier | its live carrier
//  by name, within w:PereStaple.  The witness and the trial steps navigate through these.
Lake_peering(w, name):
    return w.o({Peering: 1}).find(p => p.sc.name === name)

Lake_pier(w, name):
    return this.Lake_peering(w, name)?.o({Pier: 1})[0]

Lake_port(pier):
    return pier && pier.c.up.o({active_transport: 1})[0]?.c.connection

// Lake_sides_up — step 2: stand up the Alice↔Bob link in ONE Lake_link, arm the step-boundary
//  whittle ONCE for the whole world (its sweep iterates every Peering, so the heal/stall peers
//   added at later steps are swept without re-arming), and push one A→B noop.  The noop is a pure
//    transport ping (spec §4.2, §7.3): it proves the carrier (its %unemit reaches %done →
//     %witnessed:step_2) and the ack path (its %outbox/emit comes back %acked) without a premature
//      hello — so the real hello is sent exactly once, at step 3.  Fired once at step 2.
async Lake_sides_up(w):
    w i reached:step_2
    let [AlicePier, BobPier] = await this.Lake_link(w, 'alice', 'bob')
    this.Peeroleum_arm_whittle(w)
    let s = this.Pier_next_seq(AlicePier)
    this.Peeroleum_send(w, {header: {type: 'noop', from: 'alice', to: 'bob', seq: s}})

// Lake_handshake — step 3: seed %req:handshake on each Pier (the spine's req_handshake stands up
//  the four maz leaves) and pump it once.  The leaf do_fns (say/hear) advance as frames cross.
async Lake_handshake(w):
    for (const name of ['alice', 'bob']) {
        let pier = this.Lake_pier(w, name)
        if (!pier) continue
        pier.oai({req: 'handshake'})
        await pier.do()
    }
    w i %reached:step_3

// Lake_pump_handshakes — pump every Peering under w:PereStaple each pass.  peering.do() runs each Pier
//  (req_Pier → the %req:handshake it hosts).  With Peering a typed serial-req the ambient reqdo_sweep
//   ALSO reaches these now (w.do() cascades through the Peering reqs) — so this is belt-and-braces,
//    guaranteeing the drive within the wrangle pass without waiting on the heartbeat.  No-op before
//     step 2 (no Peerings yet); harmless on the carrier-only heal/stall peers (no handshake to advance).
async Lake_pump_handshakes(w):
    for (const peering of w.o({Peering: 1})) {
        await peering.do()
    }

// Lake_trial_arm — step 4: put the carrier on trial (spec §4.1, §11.2; flavour in Tribunal.g).
//  Install the webrtc + websocket carriers on both Peerings, pair the relay ports, hand each live
//   %active_transport to webrtc, then probe A->B.  webrtc is a black hole (Tribunal.PeerJS), so the
//    probe goes un-acked and the no-ack step 5 falls the carrier to the websocket relay.  Park the
//     probe seq on the Pier .c for step 5 to read.
async Lake_trial_arm(w):
    w i %reached:step_4
    let Alice = this.Lake_peering(w, 'alice')
    let Bob = this.Lake_peering(w, 'bob')
    if (!Alice || !Bob) return
    this.PeerJS(Alice)
    this.PeerJS(Bob)
    this.Socket(Alice)
    this.Socket(Bob)
    this.Tribunal_pair_websocket(Alice, Bob)
    this.Tribunal_hand_to_webrtc(Alice)
    this.Tribunal_hand_to_webrtc(Bob)
    let AlicePier = this.Lake_pier(w, 'alice')
    if (!AlicePier) return
    let s = this.Pier_next_seq(AlicePier)
    AlicePier.c.webrtc_probe_seq = s
    this.Peeroleum_send(w, {header: {type: 'noop', from: 'alice', to: 'bob', seq: s}})

// Lake_trial_fallback — step 5: no-ack-then-give-up.  The step-4 webrtc probe is still un-acked, so
//  fall BOTH sides to the websocket relay first (demoting both before probing sidesteps the cross-side
//   ack race), then probe the relay A->B (a working shared-queue port, paired at step 4).
async Lake_trial_fallback(w):
    w i %reached:step_5
    let Alice = this.Lake_peering(w, 'alice')
    let Bob = this.Lake_peering(w, 'bob')
    let AlicePier = this.Lake_pier(w, 'alice')
    if (!Alice || !Bob || !AlicePier) return
    let probe = AlicePier.o({outbox:1})[0]?.o({emit: AlicePier.c.webrtc_probe_seq})[0]
    if (probe?.sc.acked) return   // webrtc carried after all -- no fall-back needed
    this.Tribunal_fall_to_websocket(Alice)
    this.Tribunal_fall_to_websocket(Bob)
    let s = this.Pier_next_seq(AlicePier)
    AlicePier.c.ws_probe_seq = s
    this.Peeroleum_send(w, {header: {type: 'noop', from: 'alice', to: 'bob', seq: s}})

// Lake_trial_confirm — step 6: the relay probe came back acked => the websocket carries.  Bless both
//  carriers %reputation:good.  The acked %emit may have whittled to %outbox/recent at the step-5
//   boundary (which STRIPS %acked) — so presence in %recent IS the ack proof; a still-live emit must
//    still carry %acked.  Idempotent.
async Lake_trial_confirm(w):
    w i %reached:step_6
    let Alice = this.Lake_peering(w, 'alice')
    let Bob = this.Lake_peering(w, 'bob')
    let AlicePier = this.Lake_pier(w, 'alice')
    if (!Alice || !Bob) return
    let ob = AlicePier?.o({outbox:1})[0]
    let live = ob?.o({emit: AlicePier.c.ws_probe_seq})[0]
    let recent = ob?.o({recent:1})[0]?.o({emit: AlicePier.c.ws_probe_seq})[0]
    let acked = (live && live.sc.acked) || !!recent
    if (!acked) return
    this.Tribunal_reputation_good(Alice)
    this.Tribunal_reputation_good(Bob)

// Lake_exercise_binary — step 7: the first transport-agnostic exercise (heading 7).  With the
//  handshake long settled (Bob has %Ud), send one binary frame A->B: a fixed 64-byte fixture as RAW
//   bytes on frame.buffer (spec §4.2 — no base64), the header carrying body_hash + body_len.  Bob's
//    serial inbox recomputes the digest (req_unemit), runs the registered test_binary handler (stamps
//     %got_binary on his Pier), and acks — so the witness sees the full round-trip.  The SAME exercise
//      runs over ANY carrier (it reads whatever %active_transport points at).  Fired once at step 7.
async Lake_exercise_binary(w):
    w i %reached:step_7
    let AlicePier = this.Lake_pier(w, 'alice')
    if (!AlicePier) return
    // the consumer seam rides w:PereStaple; only Bob's Pier ever inboxes a to:bob test_binary, so only it
    //  dispatches -- the handler stamps %got_binary on the receiving Pier, a witness target past the cull.
    this.Peeroleum_on(w, 'test_binary', (cw, pier, frame) => pier.i({got_binary: 1, seq: frame.header.seq, body_len: frame.header.body_len}))
    let bytes = new Uint8Array(64)
    for (let i = 0; i < 64; i++) bytes[i] = (i * 7 + 3) & 0xff
    let bh = await this.Peeroleum_body_digest(bytes)
    let s = this.Pier_next_seq(AlicePier)
    this.Peeroleum_send(w, {header: {type: 'test_binary', from: 'alice', to: 'bob', seq: s, body_hash: bh, body_len: bytes.length}, buffer: bytes})

// Lake_heal_arm — step 8: the reliability heal end-to-end (Reliable.g: inseq + retransmit + the
//  adversary).  A FRESH isolated link (Ivy/Jon) via ONE Lake_link — isolated so the trial's
//   webrtc/websocket state can't muddy it, fresh so its per-Pier seq starts at 1.  Mark the link LOSSY
//    (reliable:false) so the seq discipline engages, slip the adversary onto the Ivy->Jon path
//     (make_lossy_partner, drop:[s]) so seq s is swallowed once, and send one noop Ivy->Jon (admitted
//      pre-Ud, like step 2).  Jon never hears it -> Ivy's emit stays un-acked -> Peeroleum_retx_sweep
//       re-sends at the step boundaries -> the resend passes the now-spent drop -> Jon delivers + acks:
//        the heal, witnessed across steps 9-10.  (The whittle armed at step 2 already sweeps these.)
async Lake_heal_arm(w):
    w i %reached:step_8
    let [IvyPier, JonPier] = await this.Lake_link(w, 'ivy', 'jon')
    let Ivyport = this.Lake_port(IvyPier)
    let Jonport = this.Lake_port(JonPier)
    Ivyport.reliable = false
    Jonport.reliable = false
    let s = this.Pier_next_seq(IvyPier)
    IvyPier.c.heal_seq = s
    // slip the adversary between Ivy and Jon: Ivy->Jon goes THROUGH the lossy wrapper (drops seq s once);
    //  Jon->Ivy (the acks) rides the bare port.  Stash the wrapper on the Pier so the witness reads its
    //   drop-log off-snap (survives the cull).
    let lossy = this.make_lossy_partner(Jonport, {drop: [s]})
    IvyPier.c.lossy = lossy
    Ivyport.partner = lossy
    this.Peeroleum_send(w, {header: {type: 'noop', from: 'ivy', to: 'jon', seq: s}})

// Lake_stall_arm — step 11: the PERMANENT-fault twin of the heal.  A FRESH isolated link (Kim/Lee) via
//  one Lake_link; mark it LOSSY; set a TIGHT retx_policy on Kim's Peering (per-Peering now) so the
//   exhaustion lands in two ticks (production's {max_attempts:5,cap:16} would need ~46); slip a BLACKHOLE
//    (every transit lost) onto Kim->Lee; send one noop.  Lee never hears it and no resend ever lands, so
//     Peeroleum_retx_sweep marks the emit %dead, rolls %stalled onto KimPier, and culls the emit —
//      witnessed structurally (dropped>=2 + %stalled).
async Lake_stall_arm(w):
    w i %reached:step_11
    let [KimPier, LeePier] = await this.Lake_link(w, 'kim', 'lee')
    let Kimport = this.Lake_port(KimPier)
    let Leeport = this.Lake_port(LeePier)
    Kimport.reliable = false
    Leeport.reliable = false
    // the tight policy rides Kim's Peering (per-Peering retransmit policy) so only THIS link dies fast.
    KimPier.c.up.c.retx_policy = {base: 1, factor: 1, max_attempts: 2, cap: 1}
    let s = this.Pier_next_seq(KimPier)
    KimPier.c.stall_seq = s
    // a blackhole (EVERY transit lost): the resend never lands either, so the emit dies.  Stash the
    //  wrapper on the Pier so the witness reads its drop-log (>=2 transits) off-snap, past the cull.
    let lossy = this.make_lossy_partner(Leeport, {blackhole: [s]})
    KimPier.c.lossy = lossy
    Kimport.partner = lossy
    this.Peeroleum_send(w, {header: {type: 'noop', from: 'kim', to: 'lee', seq: s}})

// Lake_witness — the readable assertions, polled each pass.  Navigates through w:PereStaple by node name
//  (Lake_pier/Lake_peering).  Each stamp is structural + idempotent; the step rides in the VALUE
//   (`step` is the Story mainkey, so it can't be a key).
Lake_witness(w):
    let BobPier = this.Lake_pier(w, 'bob')
    // step 2: the noop proved the carrier once Bob HANDLED it -- a %done req:unemit, or past the cull
    //  its %recent/unemit record (presence there = it round-tripped).
    let Bobinbox = BobPier?.o({inbox:1})[0]
    let landed = Bobinbox?.o({req:'unemit'})[0]?.sc.done || Bobinbox?.o({recent:1})[0]?.oa({unemit:1})
    if (landed && !(oa %witnessed:step_2)) i %witnessed:step_2
    // step 3: both Piers' %req:handshake reached finished (all four leaves done).
    let AlicePier = this.Lake_pier(w, 'alice')
    let Alicehandshake = AlicePier?.o({req:'handshake'})[0]
    let Bobhandshake = BobPier?.o({req:'handshake'})[0]
    if (Alicehandshake?.sc.finished && Bobhandshake?.sc.finished && !(oa %witnessed:step_3)) i %witnessed:step_3
    // step 4: both carriers handed to webrtc, probe sent (still un-acked -- black hole).  The carriers
    //  ride the Peering now, so read active_transport/transport off it.
    let Alice = this.Lake_peering(w, 'alice')
    let Bob = this.Lake_peering(w, 'bob')
    let Aliceactive = Alice?.o({active_transport:1})[0]
    let Bobactive = Bob?.o({active_transport:1})[0]
    if (Aliceactive?.sc.type === 'webrtc' && Bobactive?.sc.type === 'webrtc' && !(oa %witnessed:step_4)) i %witnessed:step_4
    // step 5: webrtc gave no ack -> both fell to the websocket relay (faulty, active ws).
    let Alicewr = Alice?.o({transport:1, type:'webrtc'})[0]
    let Bobwr = Bob?.o({transport:1, type:'webrtc'})[0]
    if (Alicewr?.sc.faulty && Bobwr?.sc.faulty && Aliceactive?.sc.type === 'websocket' && Bobactive?.sc.type === 'websocket' && !(oa %witnessed:step_5)) i %witnessed:step_5
    // step 6: the relay carries -- both websocket carriers blessed %reputation:good.
    let Alicews = Alice?.o({transport:1, type:'websocket'})[0]
    let Bobws = Bob?.o({transport:1, type:'websocket'})[0]
    if (Alicews?.oa({reputation:'good'}) && Bobws?.oa({reputation:'good'}) && !(oa %witnessed:step_6)) i %witnessed:step_6
    // step 7 (send_binary): Bob received + verified the binary (%got_binary) and Alice's emit %acked
    //  (live, or present in %recent which holds only acked emits).
    let Bobgot = BobPier?.oa({got_binary:1})
    let Aliceob = AlicePier?.o({outbox:1})[0]
    let binlive = Aliceob?.o({type:'test_binary'})[0]
    let binrecent = Aliceob?.o({recent:1})[0]?.o({type:'test_binary'})[0]
    let binacked = (binlive && binlive.sc.acked) || !!binrecent
    if (Bobgot && binacked && !(oa %witnessed:send_binary)) i %witnessed:send_binary
    // step 8 (heal): the dropped noop healed via retransmit.  Three cull-surviving readings: the
    //  adversary swallowed a frame (the drop-log), Jon HANDLED it anyway, Ivy's emit came back %acked.
    let IvyPier2 = this.Lake_pier(w, 'ivy')
    let JonPier2 = this.Lake_pier(w, 'jon')
    let healdropped = !!(IvyPier2 && IvyPier2.c.lossy && IvyPier2.c.lossy.dropped.length)
    let Joninbox2 = JonPier2 && JonPier2.o({inbox:1})[0]
    let healhandled = Joninbox2 && (Joninbox2.o({req:'unemit'})[0]?.sc.done || Joninbox2.o({recent:1})[0]?.oa({unemit:1}))
    let Ivyob2 = IvyPier2 && IvyPier2.o({outbox:1})[0]
    let healive = Ivyob2 && Ivyob2.o({emit:1})[0]
    let healacked = (healive && healive.sc.acked) || (Ivyob2 && Ivyob2.o({recent:1})[0]?.oa({emit:1}))
    if (healdropped && healhandled && healacked && !(oa %witnessed:heal)) i %witnessed:heal
    // step 11 (stall): the blackhole swallows EVERY transit, so Kim's emit exhausts its retransmits and
    //  LATCHES %stalled on the Pier.  Two cull-surviving readings: the adversary swallowed >=2 transits
    //   (original send + >=1 retransmit), and the Pier carries the latched %stalled.
    let KimPier2 = this.Lake_pier(w, 'kim')
    let stalldropped = !!(KimPier2 && KimPier2.c.lossy && KimPier2.c.lossy.dropped.length >= 2)
    let stalled = KimPier2 && KimPier2.oa({stalled:1})
    if (stalldropped && stalled && !(oa %witnessed:stall)) i %witnessed:stall

// Lake_order — keep the Run snap readable: float the peer world A:PereStaple to the front of H/*
//  (ahead of the apparatus actors A:Lies/A:Lang), the rest after.  A whole-/* place({}, ordered)
//   re-enters each child in order and no-ops once already sorted.  (No more per-peer A:Alice/A:Bob
//    actors to hoist — every peer is a %Peering under w:PereStaple now.)
async Lake_order(w):
    let As = H.o({A:1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'PereStaple') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)
