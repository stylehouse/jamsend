
// LakeNetherland — the Peeroleum test-case wrangler (the outer test layer).
//  Reached only after Peregrination.svelte (the hand-written bootstrap) has
//  compiled + included this dock and Ghost/N/Peeroleum.g, so its sibling methods
//  are live on H. Getting-started: prove we reached compiled code, then seed the
//  wrangler's root desire so the Peeroleum spine has something to pump.
//
// Step 1 was the bootstrap (compile + include) — owned by the loader. From here
//  A:Peregrination has the conn: LakeNetherland installs the eternal %req:wrangle
//   whose do_fn drives the *inner* steps, starting at 2. The toc.snap carries one
//    `step,…` line per inner step (real seq, lie diges till a run records them).
//
//   step 2  two sides up under one mock transport; a noop B→N proves carrier + ack
//   step 3  %req:handshake completes on both Piers; full outbox/inbox lifecycle + acks
//   step 4  per-req demand / waiting-reqs (heading 5) — placeholder
//   step 5  corruption tests (heading 6) — placeholder
//
// The heading-4 message lifecycle (outbox created→sent→acked, serial inbox
//  queued→handling→verified→done, acks, %recent whittle at the step boundary) is not
//   its own step — it rides the traffic of steps 2 and 3, in the Peeroleum spine.
//
// We do NOT use H.on_step: it keys off one H-global `did_on_step_n`, which the
//  bootstrap's step-1 table claims when compile/include spills into step 2 — that
//   starves step 2's setup (the symptom: step 3 fires, step 2's sides never lay).
//    Lake_drive keeps a req-local `did_step` instead, immune to any other caller.
LakeNetherland(A,w):
    w i %see:'y LakeNetherland — apparatus ready, Peregrination has the conn'
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
            &Lake_sides_up,w
        else if n === 3
            await &Lake_handshake,w
        else if n === 4
            i %reached:step_4
        else if n === 5
            i %reached:step_5
    await &Lake_pump_handshakes,w
    &Lake_witness,w
    await &Lake_order,w

// Lake_order — float all the A actors to the front of H/* (peers A:Bearing/A:Nearing
//  before the apparatus actors), the rest of H/* after, so the Run snap reads
//   actors-first, peers-first. A whole-/* place({},…): every child is re-entered
//    .is()'d (identity|data|/* untouched), and it no-ops once already in order. A
//     plain place({A:1},…) can't do this — replace() lands the matched set LAST, so
//      it'd sink the A's to the bottom; reordering the whole /* is the only way up.
async Lake_order(w):
    let As = H o %A
    if (As.length < 2) return
    let peer = (a) => (a%A === 'Bearing' || a%A === 'Nearing') ? 0 : 1
    let sorted = [...As].sort((a, b) => peer(a) - peer(b))
    let ordered = [...sorted, ...H.o().filter(c => !c%A)]
    await &place,{},ordered

// Lake_sides_up — step 2: stand up both sides directly (the wrangler lays them,
//  spec §15), pair their mock-ports, arm each w's step-boundary whittle, and push one
//   B→N frame. That frame is a `type:noop` (spec §4.2, §7.3) — a pure transport ping:
//    it proves the carrier (its %unemit reaches %done, stamping %witnessed:step_2) and
//     the ack path (its %outbox/emit comes back %acked), without sending a premature
//      hello — so the real hello is sent exactly once, at step 3 (this dissolves the old
//       duplicate-B→N-hello the heading-3 scaffold left). The H-receiver actor-laying is
//        stho (H i A:..$cap, heading L); only the objects-on-.c mock-port wiring stays
//         raw JS. Fired once at step 2.
Lake_sides_up(w):
    w i reached:step_2
    // stand up both sides: `H i A:..$cap/w:..$cap` lays the actor and its w on the
    //  House in one multi-assigning two-leg, capturing each leg's C (heading L).
    H i A:Bearing$:AB/w:Peeroleum$:wB
    H i A:Nearing$:AN/w:Peeroleum$:wN
    // each side: a Peering and a Pier named by the peer's identity (whom this Pier
    //  is a Pier to), plus a mock transport on the Peering's active_transport.
    wB i Peering,name:bearing$:peerB/Pier,pub:nearing$:pierB
    wN i Peering,name:nearing$:peerN/Pier,pub:bearing$:pierN
    // wire c.up below w: the belief walk wires A.c.up and w.c.up but NOT the
    //  domain particles under w (Peering/Pier), so a nested req's pump (pier.do())
    //   can't climb to the House to resolve its do_fn. Stamp the chain — the
    //    migration idiom (cf examining.c.up=w, funks.c.up=w). Objects-on-.c → raw JS.
    peerB.c.up = wB; pierB.c.up = peerB
    peerN.c.up = wN; pierN.c.up = peerN
    &transport,AB,wB
    &transport,AN,wN
    // each w culls its Piers' acked outbox / done inbox into %recent at the step
    //  boundary (spec §7.4, §12.1) — arm it once per side here.
    &Peeroleum_arm_whittle,wB
    &Peeroleum_arm_whittle,wN
    // pair the two mock-ports so each side delivers into the other (spec §15) —
    //  objects-on-.c stay raw JS.
    wB o active_transport$:bport.c.connection
    wN o active_transport$:nport.c.connection
    bport.partner = nport; nport.partner = bport
    // one noop B→N off the per-Pier counter (seq 1): carrier + ack proof, no hello.
    let s = this.Pier_next_seq(pierB)
    &Peeroleum_send,wB,{header:{type:'noop', from:'bearing', to:'nearing', seq:s}}

// Lake_handshake — step 3: seed %req:handshake on each Pier (the spine's
//  req_handshake stands up the four maz leaves) and pump it once — nested reqs
//   aren't swept by reqdo. The leaf do_fns (say/hear) are heading 3, so the tree
//    stands up but does not yet reach finished: an honest scaffold for now.
async Lake_handshake(w):
    for (const side of ['Bearing', 'Nearing']) {
        H o A:$side/w:Peeroleum/Peering/Pier$:pier
        if (!pier) continue
        pier oai %req:handshake
        await pier&do
    }
    w i %reached:step_3

// Lake_pump_handshakes — re-pump each Pier's %req:handshake every pass. The
//  handshake is nested (Pier/Peering/w), below reqdo_sweep's w-level reach, so the
//   wrangler drives it; each inbound frame's feebly_ponder brings the run back
//    here, advancing the maz leaves as their protocol particles land (say→hear→
//     say_trust→hear_trust). No-op before step 3 — no Piers stand up yet.
async Lake_pump_handshakes(w):
    for (const side of ['Bearing', 'Nearing']) {
        H o A:$side/w:Peeroleum/Peering/Pier$:pier
        if (!pier) continue
        await pier&do
    }

// Lake_witness — the readable assertion, polled each pass: once Nearing's inbox
//  shows a handled (%done) frame, stamp %witnessed:step_2 (the step rides in the
//   value — `step` is the Story mainkey, so it can't be a key). Idempotent via the probe.
Lake_witness(w):
    H o A:Nearing/w:Peeroleum/Peering/Pier$:npier
    npier o inbox/unemit$:landed?.sc.done
    if (landed && !(oa %witnessed:step_2)) i %witnessed:step_2
    // step 3: both Piers' %req:handshake reached finished (all four leaves done).
    H o A:Bearing/w:Peeroleum/Peering/Pier$:bpier
    let bh = bpier?.o({req:'handshake'})[0]
    let nh = npier?.o({req:'handshake'})[0]
    if (bh?.sc.finished && nh?.sc.finished && !(oa %witnessed:step_3)) i %witnessed:step_3
