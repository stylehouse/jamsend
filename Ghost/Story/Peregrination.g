
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
//   step 2  two sides up under one mock transport; one frame B→N delivered
//   step 3  %req:handshake stands up on both Piers (leaf do_fns are heading 3)
//   step 4  outbox/inbox lifecycle + acks (heading 4) — placeholder
//   step 5  corruption tests (heading 6) — placeholder
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
    &Lake_witness,w
    await &Lake_order,w

// Lake_order — float the peers (A:Bearing/A:Nearing, the subject under test) above
//  the apparatus actors so the snap reads peers-first. place() re-enters the same A
//   C's in the chosen order (identity/data untouched) and no-ops once already ordered.
async Lake_order(w):
    let As = H o %A
    if (As.length < 2) return
    let peer = (a) => (a%A === 'Bearing' || a%A === 'Nearing') ? 0 : 1
    let sorted = [...As].sort((a, b) => peer(a) - peer(b))
    await &place,{A:1},sorted

// Lake_sides_up — step 2: stand up both sides directly (the wrangler lays them,
//  spec §15), pair their mock-ports, and push one frame B→N. The H-receiver actor-
//   laying is stho (H i A:..$cap, heading L); only the objects-on-.c mock-port
//    wiring stays raw JS. Fired once at step 2.
Lake_sides_up(w):
    w i reached:step_2
    // stand up both sides: `H i A:..$cap/w:..$cap` lays the actor and its w on the
    //  House in one multi-assigning two-leg, capturing each leg's C (heading L).
    H i A:Bearing$AB/w:Peeroleum$wB
    H i A:Nearing$AN/w:Peeroleum$wN
    // each side: a Peering and a Pier named by the peer's identity (whom this Pier
    //  is a Pier to), plus a mock transport on the Peering's active_transport.
    wB i Peering,name:bearing/Pier,pub:nearing
    wN i Peering,name:nearing/Pier,pub:bearing
    &transport,AB,wB
    &transport,AN,wN
    // pair the two mock-ports so each side delivers into the other (spec §15) —
    //  objects-on-.c stay raw JS.
    wB o active_transport$bport.c.connection
    wN o active_transport$nport.c.connection
    bport.partner = nport; nport.partner = bport
    &Peeroleum_send,wB,{header:{type:'hello', from:'bearing', to:'nearing', seq:1}}

// Lake_handshake — step 3: seed %req:handshake on each Pier (the spine's
//  req_handshake stands up the four maz leaves) and pump it once — nested reqs
//   aren't swept by reqdo. The leaf do_fns (say/hear) are heading 3, so the tree
//    stands up but does not yet reach finished: an honest scaffold for now.
async Lake_handshake(w):
    for (const side of ['Bearing', 'Nearing']) {
        let pier = this.o({A: side})[0]?.o({w: 'Peeroleum'})[0]?.o({Peering: 1})[0]?.o({Pier: 1})[0]
        if (!pier) continue
        pier oai %req:handshake
        await pier.do()
    }
    w i %reached:step_3

// Lake_witness — the readable assertion, polled each pass: once Nearing's inbox
//  shows the delivered frame, stamp %witnessed:step_2 (the step rides in the value
//   — `step` is the Story mainkey, so it can't be a key). Idempotent via the probe.
Lake_witness(w):
    let npier = this.o({A: 'Nearing'})[0]?.o({w: 'Peeroleum'})[0]?.o({Peering: 1})[0]?.o({Pier: 1})[0]
    let landed = npier?.o({inbox: 1})[0]?.o({unemit: 1})[0]?.sc.delivered
    if (landed && !w.oa({witnessed: 'step_2'})) w.i({witnessed: 'step_2'})
