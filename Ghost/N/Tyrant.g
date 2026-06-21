// Tyrant — the cabinetry over the Peeroleum floor: identity & trust → admission.
//  A clean-room rebirth of legacy Tyranny, in stho, riding the Peeroleum transport
//   (the "linoleum floor") — it never touches a carrier, it emits through
//    &Peeroleum_send and plugs a hear_<verb> handler into the inbox dispatch via the
//     Peeroleum_on consumer seam, exactly like hello/trust. Design: Covenant_design.md.
//
//   M1 — trust over GIVEN identities (Alice+Bob magically provisioned: %Ud pre-stamped,
//         no meeting). A bidirectional vouch exchange that settles on acks and yields an
//          explicit %trust,grants on each Pier — the thing admission reads.
//   M2 — policy-gated admission. A %req:join on a side's w whose `finished` is the AND of
//         its policy leaves (proven ∧ trusted), maz-ordered; the admit leaf (lowest maz)
//          runs only once both pass and stamps w/%member,signed — "on the network".
//
//   Meet + prove (earning %Ud rather than being given it) is the deeper M2, deferred —
//    here %Ud is given, so the policy `proven` leaf reads the given %Ud. Inner steps:
//     step 2  given sides + run %req:trust          ⇒ %witnessed:step_2 (both %trust,grants)
//     step 3  arm %req:join + drive the policy gate ⇒ %witnessed:step_3 (both w/%member,signed)

// Run_A_Tyrant — the Book's Run recipe (Story_subHouse calls it to wire the Run),
//  mirroring Run_A_PereStartuppity. Lay the single test actor + its w; the role is
//   already 'runner' (Auto/boot) — this just guards it.
Run_A_Tyrant():
    this.c.role ??= 'runner'
    H i A:Tyrant/w:Tyrant

// Per beat: install the eternal %req:wrangle whose do_fn drives the inner steps. Like
//  PereStartuppity, we do NOT use H.on_step (it keys off one H-global did_on_step_n that a
//   step-1 table claims when setup spills into step 2); Tyrant_drive keeps a req-local
//    did_step instead.
Tyrant(A,w):
    w i %see:'y Tyrant — yyyyar!'
    w oai %req:wrangle,eternal
        await &Tyrant_drive,w,req
        req%ok = 1

// Tyrant_drive — the wrangle's step dispatch. Fire a step's setup once (the first pass it
//  sees a new run step_n, tracked on req.c.did_step), then pump + witness every pass after.
async Tyrant_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if n != null && n !== req.c.did_step
        req.c.did_step = n
        if n === 2
            &Tyrant_sides_up,w
        else if n === 3
            &Tyrant_admit_arm,w
    await &Tyrant_pump,w
    &Tyrant_witness,w

// Tyrant_sides_up — step 2: stand up both GIVEN sides directly (magic provisioning), pair
//  their mock-ports, register the vouch receive handler, and seed %req:trust on each Pier.
//   Mirrors PereStartuppity's Lake_sides_up, with two differences: %Ud is pre-stamped (so the
//    spine's pre-Ud inbox gate lets a `vouch` frame through), and a `vouch` handler is
//     registered via the Peeroleum_on consumer seam (no edit to the floor).
Tyrant_sides_up(w):
    const H = this
    w i %reached:step_2
    // lay each side: actor + its w:Tyrant, a Peering named by us, a Pier named by the peer.
    H i A:Alice$:AliceA/w:Tyrant$:Alicew
    H i A:Bob$:BobA/w:Tyrant$:Bobw
    Alicew i Peering,name:alice$:AlicePeering/Pier,pub:bob$:AlicePier
    Bobw i Peering,name:bob$:BobPeering/Pier,pub:alice$:BobPier
    // c.up: the belief walk wires A/w only, not the domain particles under w — stamp the
    //  Pier→Peering→w chain by hand or the Pier-hosted %req:trust silently never pumps (spec §8).
    AlicePeering.c.up = Alicew; AlicePier.c.up = AlicePeering
    BobPeering.c.up = Bobw; BobPier.c.up = BobPeering
    // GIVEN identities (M1 skips meet+prove): %Ud pre-stamped, so a vouch frame clears the
    //  spine's pre-Ud gate (which otherwise admits only hello|noop, spec §7.3).
    AlicePier i %Ud,id:bob
    BobPier i %Ud,id:alice
    // mock transport on each side + pair the two ports (reuse the floor's mock carrier).
    &transport,AliceA,Alicew
    &transport,BobA,Bobw
    &Peeroleum_arm_whittle,Alicew
    &Peeroleum_arm_whittle,Bobw
    Alicew o active_transport$:Aliceport.c.connection
    Bobw o active_transport$:Bobport.c.connection
    Aliceport.partner = Bobport; Bobport.partner = Aliceport
    // register the `vouch` receive handler on each side (the consumer dispatch seam): the
    //  serial inbox routes a verified vouch frame to hear_vouch inside the same lifecycle as
    //   hello/trust. A closure off a frame is an object payload — a raw-JS seam.
    H.Peeroleum_on(Alicew, 'vouch', (cw, cpier, cframe) => H.hear_vouch(cw, cpier, cframe))
    H.Peeroleum_on(Bobw, 'vouch', (cw, cpier, cframe) => H.hear_vouch(cw, cpier, cframe))
    // seed the trust exchange on each Pier; the first Tyrant_pump pass drives say_vouch.
    AlicePier oai %req:trust
    BobPier oai %req:trust

// Tyrant_admit_arm — step 3: seed %req:join on each side's w. The policy gate (req_join's
//  maz-ordered leaves) finishes once trust granted at step 2 satisfies `trusted` and the
//   given %Ud satisfies `proven`.
Tyrant_admit_arm(w):
    w i %reached:step_3
    H o A:Alice/w:Tyrant$:Alicew
    H o A:Bob/w:Tyrant$:Bobw
    if (Alicew)
        Alicew oai %req:join
    if (Bobw)
        Bobw oai %req:join

// Tyrant_pump — re-pump each side's nested reqs every pass: the Pier's %req:trust (below
//  reqdo_sweep's w-level reach) and the w's %req:join. Each inbound vouch's feebly_ponder
//   brings the run back here, advancing the leaves as their protocol particles land.
async Tyrant_pump(w):
    for (const side of ['Alice', 'Bob']) {
        H o A:$side/w:Tyrant/Peering/Pier$:pier
        if (pier) await pier.do()
        H o A:$side/w:Tyrant$:sw
        if (sw) await sw.do()
    }

// Tyrant_witness — the readable assertions, polled each pass (step rides in the value —
//  `step` is the Story mainkey, so it can't be a key). Idempotent.
Tyrant_witness(w):
    H o A:Alice/w:Tyrant/Peering/Pier$:AlicePier
    H o A:Bob/w:Tyrant/Peering/Pier$:BobPier
    // step 2: both Piers granted trust (the bidirectional vouch exchange settled).
    if (AlicePier?.o({trust:1})[0]?.sc.grants && BobPier?.o({trust:1})[0]?.sc.grants && !(oa %witnessed:step_2)) i %witnessed:step_2
    // step 3: both sides admitted — w/%member,signed (the policy gate finished).
    H o A:Alice/w:Tyrant$:Alicew
    H o A:Bob/w:Tyrant$:Bobw
    if (Alicew?.o({member:1})[0]?.sc.signed && Bobw?.o({member:1})[0]?.sc.signed && !(oa %witnessed:step_3)) i %witnessed:step_3

// ── M1: trust as an acked vouch exchange (spec §8 shape, vouch vocabulary) ─────
// %req:trust owns two maz-ordered leaves under a %Pier: said_vouch (we emit our vouch,
//  idempotent on the protocol particle) then heard_vouch (pure existence check on the far
//   side's vouch). When heard lands, grant: stamp %trust,grants:full. Parent rolls up when
//    both finish. The leaf is %Pier/%req:trust/%req:<leaf>, so its Pier is req.c.up.c.up.
async req_trust(req):
    req oai %req:said_vouch,maz:2
    req oai %req:heard_vouch
    await req.do()
    if (req.all_finished() && !req.sc.finished) (req.c.up).finish(req)

async req_said_vouch(req):
    let pier = req.c.up.c.up
    let w = pier.c.up.c.up
    &say_vouch,w,pier
    pier o protocol/vouch/said$:said
    if (said) (req.c.up).finish(req)

async req_heard_vouch(req):
    let pier = req.c.up.c.up
    pier o protocol/vouch/heard$:heard
    if (heard)
        &Tyrant_grant,pier
        req.c.up.finish(req)

// say_vouch — write our half of the vouch protocol and emit one `vouch` frame to the peer;
//  idempotent on the protocol particle so a re-pump never double-sends. seq is the per-Pier
//   monotone outbound counter (Pier_next_seq, spec §7.1). Mirrors say_trust.
say_vouch(w, pier):
    let proto = pier oai protocol
    let vouch = proto oai vouch
    if (vouch.oa({said:1})) return
    let me = pier.c.up.sc.name
    let seq = this.Pier_next_seq(pier)
    vouch.i({said:1, seq})
    &Peeroleum_send,w,{header:{type:'vouch', from:me, to:pier.sc.pub, seq}}

// hear_vouch — the far side's vouch landed (verified + gated by the spine's pre-Ud inbox).
//  Record %heard; the heard_vouch leaf grants on it. Returns true (M1 trusts the given
//   identity; a real verify is a later layer). Registered via Peeroleum_on(w,'vouch',…).
hear_vouch(w, pier, frame):
    pier.oai({protocol:1}).oai({vouch:1}).i({heard:1})
    return true

// Tyrant_grant — both directions vouched ⇒ stamp the trust grant on the Pier (the particle
//  admission's `trusted` policy reads). Idempotent.
Tyrant_grant(pier):
    pier oai %trust...%grants:full

// ── M2: policy-gated admission — a %req:join whose finished is the AND of its leaves ──
// The elegant core (LiesStore phased-%req shape): %req:join on a side's w owns policy leaves
//  (each finishes only when its condition holds) + an admit leaf at the lowest maz, so admit
//   runs only after every policy passes. Settling %req:join IS being on the network.
async req_join(req):
    req oai %req:policy,kind:proven,maz:3
    req oai %req:policy,kind:trusted,maz:2
    req oai %req:admit
    await req.do()
    if (req.all_finished() && !req.sc.finished) (req.c.up).finish(req)

// req_policy — one handler, kind-branched: a pure read of the particles M1/the given setup
//  produced. proven = identity present (%Ud on the Pier); trusted = M1 granted (%trust,grants).
//   The leaf is w/%req:join/%req:policy, so its w is req.c.up.c.up.
req_policy(req):
    let w = req.c.up.c.up
    let pier = w.o({Peering:1})[0]?.o({Pier:1})[0]
    if (!pier) return
    if (req.sc.kind === 'proven' && pier.oa({Ud:1})) (req.c.up).finish(req)
    else if (req.sc.kind === 'trusted' && pier.o({trust:1})[0]?.sc.grants) (req.c.up).finish(req)

// req_admit — the gate cleared (lowest maz, so every policy already finished): sign and admit.
req_admit(req):
    let w = req.c.up.c.up
    w oai %member...%signed:1
    req.c.up.finish(req)
