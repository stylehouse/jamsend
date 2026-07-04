// Swarmation.g — the Swarm* social-side tests, in the Musu* mould (spec: Swarm_spec.md §9). The
//  file is the artifact; SwarmStaple is the Book identity. The Creduler loads this ghost live
//   BEFORE the Story begins (once it is in CREDULER_GHOSTS), so Ghost/S/Swarm.g's spine is on H.
//  DETERMINISM is total: fixed selves (keys seeded off the person's name), a pinned clock
//   (w.sc.now stepped per beat), a fixed nonce — ed25519 signs deterministically, so every
//    signature, every grant, every snap byte repeats run to run (the LakeSurprise ideal).
//
//  SwarmStaple — two strangers become peers, end to end:
//   beat 2  Alice + Bob stand up — %Identity owning %Peering each, fixed keys, both OFFLINE
//   beat 3  Alice mints the Idzeug — an unbound Music grant (genre:Classical) + nonce → the ?Iz= blob
//   beat 4  the rebuffs — a TAMPERED blob is rejected; the true blob with Alice OFFLINE fails
//            (the Idzeug is proof of receipt — both Piers must be online)
//   beat 5  the seal — Alice online, Bob redeems: pier_hello echoes the Idzeug → pier_accept →
//            mutual %Pier with cross-signed Music grants + a social-graph edge at each end
//   beat 6  the replay — Carol redeems the SPENT Idzeug → rejected (single-use, the nonce is spent)
//   beat 7  revocation — Alice %NotGrants Bob's Music → her Pier retires at use (Bob's still
//            stands: revocation propagation is a later slice)
//   beat 8  the round trip — Alice's account exports (secret included) → imports into a fresh
//            container → re-exports byte-identical; the whole §4 robustness claim at the model layer
//
// CONVENTION (Musu*): no Run_A_ recipe — Story_subHouse stands up A:SwarmStaple/w:SwarmStaple by
//  default. The world MUST be named after the Book (do_fn_for dispatches by w.sc.w) or the
//   wrangle silently never fires.

SwarmStaple(A,w):
    w oai %req:wrangle,eternal
        await &SwarmStaple_drive,w,req
        req%ok = 1

// SwarmStaple_drive — the wrangle's own beat dispatch: fire a beat's setup once, the first pass a
//  new run step_n shows (tracked on req.c.did_step — req-local, immune to on_step's H-global, the
//   Pere* lesson), then pump the wire and re-sort H/* every pass. Separate guarded ifs sidestep
//    the bare-else tile mangle.
async SwarmStaple_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.SwarmStaple_sides_up(w)
        if (n === 3) await this.SwarmStaple_mint(w)
        if (n === 4) await this.SwarmStaple_rebuffs(w)
        if (n === 5) await this.SwarmStaple_seal(w)
        if (n === 6) await this.SwarmStaple_replay(w)
        if (n === 7) await this.SwarmStaple_revoke(w)
        if (n === 8) await this.SwarmStaple_roundtrip(w)
    }
    await this.SwarmStaple_pump(w)
    await this.SwarmStaple_order(w)

// SwarmStaple_pump — deliverance: every account's undone mail is handled each pass (the spine's
//  Swarm_pump), so a hello sent this beat is heard and answered before the beat's snap.
async SwarmStaple_pump(w):
    for (const acct of w.o({ Account: 1 })) {
        let ident = acct.o({ Identity: 1 })[0]
        if (ident) await this.Swarm_pump(w, ident)
    }

// SwarmStaple_person — one fixed self: an %Account,of:<name> holding %Identity/%Peering, keys
//  seeded off the name so the whole crypto repeats byte for byte.
async SwarmStaple_person(w, name):
    let acct = w.oai({ Account: 1, of: name })
    acct.c.up = w
    let keys = await this.Swarm_mint_keys('SwarmStaple-' + name)
    return this.Swarm_identity(acct, keys, name)

// SwarmStaple_ident — the named person's identity (test-side lookup, by the Book's own of: tag).
SwarmStaple_ident(w, name):
    return w.o({ Account: 1, of: name })[0]?.o({ Identity: 1 })[0]

// ── the beats ──────────────────────────────────────────────────────────────────────────────

// beat 2 — two selves stand up, both offline. The witness rides its own swept req, minted LAST so
//  it observes each pass's settled state.
async SwarmStaple_sides_up(w):
    w i reached:step_2
    w.sc.now = 1751500000
    await this.SwarmStaple_person(w, 'Alice')
    await this.SwarmStaple_person(w, 'Bob')
    w.doai({req: 'witness', eternal: 1})?.(async (req) => { this.SwarmStaple_witness(w); req.sc.ok = 1 })

// beat 3 — Alice mints the Idzeug: the unbound Music offer (Classical only), single-use nonce.
//  The ?Iz= blob parks on w.c for the later beats (re-derivable — nothing durable rides it).
async SwarmStaple_mint(w):
    w i reached:step_3
    w.sc.now = 1751500010
    let alice = this.SwarmStaple_ident(w, 'Alice')
    w.c.iz = await this.Swarm_mint_idzeug(w, alice, { Music: 1, genre: 'Classical' }, 'staple_1')

// beat 4 — the two rebuffs, teeth first: a tampered blob (one signature byte flipped) must fail
//  verification; the TRUE blob redeemed while Alice is offline must fail delivery — proof of
//   receipt needs the party present.
async SwarmStaple_rebuffs(w):
    w i reached:step_4
    w.sc.now = 1751500020
    let bob = this.SwarmStaple_ident(w, 'Bob')
    this.Swarm_online(bob, true)
    let atom = JSON.parse(this.Swarm_unb64(w.c.iz))
    atom.sign = atom.sign.slice(0, -1) + (atom.sign.endsWith('0') ? '1' : '0')
    await this.Swarm_redeem(w, bob, this.Swarm_b64(JSON.stringify(atom)))
    await this.Swarm_redeem(w, bob, w.c.iz)

// beat 5 — the seal: Alice comes online, Bob redeems for real. hello → accept plays out through
//  the pump within this beat's passes; both ends land a %Pier + cross grants + an edge.
async SwarmStaple_seal(w):
    w i reached:step_5
    w.sc.now = 1751500030
    this.Swarm_online(this.SwarmStaple_ident(w, 'Alice'), true)
    await this.Swarm_redeem(w, this.SwarmStaple_ident(w, 'Bob'), w.c.iz)

// beat 6 — the replay: a third self redeems the SPENT blob. The signature verifies (it is a real
//  Idzeug) but Alice's spend ledger says no — Carol is rejected, no Pier forms.
async SwarmStaple_replay(w):
    w i reached:step_6
    w.sc.now = 1751500040
    let carol = await this.SwarmStaple_person(w, 'Carol')
    this.Swarm_online(carol, true)
    await this.Swarm_redeem(w, carol, w.c.iz)

// beat 7 — revocation: Alice %NotGrants the Music she gave Bob. Her Pier retires at use; his end
//  still stands until told (propagation is a later slice — the durable memory keeps both truths).
async SwarmStaple_revoke(w):
    w i reached:step_7
    w.sc.now = 1751500050
    let alice = this.SwarmStaple_ident(w, 'Alice')
    let pier = this.Swarm_peering(alice).o({ Pier: 1 })[0]
    await this.Swarm_revoke(w, alice, pier, 'Music')

// beat 8 — the robustness claim: export Alice's whole account (secret included) → import into a
//  fresh container → re-export. Byte-identical means the Pier, both grants, the spend ledger, the
//   %NotGrant, and the graph all survived — and the keys re-thaw onto .c. The verdict lands as a
//    %roundtrip particle (the exports are async, so the sync witness reads the stamp, not the act).
async SwarmStaple_roundtrip(w):
    w i reached:step_8
    w.sc.now = 1751500060
    let alice = this.SwarmStaple_ident(w, 'Alice')
    let blob = await this.Swarm_export(alice, { secret: 1 })
    let vault = w.oai({ Account: 1, of: 'AliceVault' })
    vault.c.up = w
    let back = this.Swarm_import(vault, blob)
    let blob2 = await this.Swarm_export(back, { secret: 1 })
    if (blob2 === blob) {
        w.i({ roundtrip: 'identical', bytes: String(blob.length) })
    } else {
        // stamp the first divergence window — a differ must be READABLE in the snap, not a rerun
        let at = 0
        while (at < blob.length && blob[at] === blob2[at]) at = at + 1
        w.i({ roundtrip: 'differs', bytes: String(blob.length), at: String(at), a: blob.slice(at, at + 40), b: blob2.slice(at, at + 40) })
    }

// ── the witness — %see once-noticed claims, polled every pass (structural + idempotent) ──────
SwarmStaple_witness(w):
    let alice = this.SwarmStaple_ident(w, 'Alice')
    let bob = this.SwarmStaple_ident(w, 'Bob')
    if (!alice || !bob) return
    let aPeering = this.Swarm_peering(alice)
    let bPeering = this.Swarm_peering(bob)
    // beat 2: two selves — each an %Identity owning its %Peering page, the keypair on .c only.
    if (aPeering && bPeering && alice.c.keys?.key && !(oa %see:'two selves stand — each an Identity owning its Peering page — keys ride .c only')) i %see:'two selves stand — each an Identity owning its Peering page — keys ride .c only'
    // beat 3: the offer exists as a nonce record — FOR the Music Feature scoped to Classical.
    let record = aPeering?.o({ Idzeug: 1 })[0]
    if (record && record.sc.to === 'Music' && record.sc.genre === 'Classical' && !(oa %see:'Alice holds a single-use Idzeug — an unbound Music grant scoped to Classical')) i %see:'Alice holds a single-use Idzeug — an unbound Music grant scoped to Classical'
    // beat 4: teeth — the flipped byte was rejected at verify; the offline redeem failed delivery.
    if (bob.o({ rebuff: 'forged' })[0] && !(oa %see:'a tampered Idzeug fails verification — one flipped signature byte and it is rejected')) i %see:'a tampered Idzeug fails verification — one flipped signature byte and it is rejected'
    if (bob.o({ rebuff: 'offline' })[0] && !(oa %see:'redeeming with the inviter offline fails — the Idzeug is proof of receipt not an offline token')) i %see:'redeeming with the inviter offline fails — the Idzeug is proof of receipt not an offline token'
    // beat 5: the mutual seal — read both Piers once, claim import + reciprocity + the graph.
    let aPier = aPeering?.o({ Pier: 1, pub: bob.sc.prepub })[0]
    let bPier = bPeering?.o({ Pier: 1, pub: alice.sc.prepub })[0]
    if (bPier && bPier.o({ Peering: 1 })[0]?.sc?.friendly === 'Alice' && !(oa %see:'Bob imported the page of Alice — the stashed Peering reborn under his Pier')) i %see:'Bob imported the page of Alice — the stashed Peering reborn under his Pier'
    let aGot = aPier?.o({ Grant: 'Music', by: bob.c.keys?.pub })[0]
    let bGot = bPier?.o({ Grant: 'Music', by: alice.c.keys?.pub })[0]
    if (aGot && bGot && aGot.sc.genre === 'Classical' && bGot.sc.genre === 'Classical' && !(oa %see:'each Pier carries a Music grant the OTHER signed — Classical only — reciprocity sealed')) i %see:'each Pier carries a Music grant the OTHER signed — Classical only — reciprocity sealed'
    let aEdge = alice.o({ SocialGraph: 1 })[0]?.o({ Edge: 1, b: bob.sc.prepub })[0]
    let bEdge = bob.o({ SocialGraph: 1 })[0]?.o({ Edge: 1, b: alice.sc.prepub })[0]
    if (aEdge && bEdge && !(oa %see:'the friendship is an edge logged in the social graph at both ends')) i %see:'the friendship is an edge logged in the social graph at both ends'
    // beat 6: single-use — the spent nonce rebuffs Carol at Alice's door; no Pier forms for her.
    let carol = this.SwarmStaple_ident(w, 'Carol')
    let carolPier = carol && this.Swarm_peering(carol)?.o({ Pier: 1 })[0]
    if (carol && carol.o({ rebuff: 'rejected_spent' })[0] && !carolPier && !(oa %see:'the Idzeug is single-use — a second redeem finds the nonce spent and is rebuffed')) i %see:'the Idzeug is single-use — a second redeem finds the nonce spent and is rebuffed'
    // beat 7: revocation at use — Alice's Pier retires under its %NotGrant while Bob's still stands.
    if (aPier && bPier && aPier.o({ NotGrant: 'Music' })[0] && !this.Swarm_pier_live(aPier, 'Music') && this.Swarm_pier_live(bPier, 'Music') && !(oa %see:'a NotGrant under the Pier retires it at use — the other end stands until told')) i %see:'a NotGrant under the Pier retires it at use — the other end stands until told'
    // beat 8: the round trip — restored twin holds the Pier and the keys, and the blobs matched.
    let restored = w.o({ Account: 1, of: 'AliceVault' })[0]?.o({ Identity: 1 })[0]
    if (restored && this.Swarm_peering(restored)?.o({ Pier: 1, pub: bob.sc.prepub })[0] && restored.c.keys?.key && w.o({ roundtrip: 'identical' })[0] && !(oa %see:'the account survives export and import byte for byte — Pier and grants and keys intact')) i %see:'the account survives export and import byte for byte — Pier and grants and keys intact'

// SwarmStaple_order — keep the Run snap readable: float A:SwarmStaple to the front of H/*.
async SwarmStaple_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'SwarmStaple') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)


// ══ SwarmWire — the SECOND Book: the SAME handshake riding the REAL Peeroleum spine ══════════════
//  SwarmStaple proves the MODEL (grants, nonce, revocation, portability) over the in-process mail
//   wire; SwarmWire proves the WIRE: pier_hello|pier_accept|pier_reject as additive frames through
//    the real outbox→carrier→inbox lifecycle (mock carriers, the PereStaple shape — Lake_link is
//     reused verbatim, transport stations named by the swarm PREPUBS so the deliver seam routes
//      1:1). The pre-Ud gate is part of the claim: no swarm frame crosses before the link
//       authenticates. Same fixed selves as the staple; its own world w:SwarmWire (dispatch is by
//        WORLD NAME — the usual bomb).
//   beat 2  two stations stand on the spine (Lake_link by prepub) + accounts + the frame kinds armed
//   beat 3  the transport handshake completes both ways — only NOW may a swarm frame cross
//   beat 4  Alice mints — Bob redeems — hello and accept cross as REAL acked frames — mutual %Pier
//   beat 5  Bob replays the spent Idzeug — the pier_reject crosses back over the same wire

SwarmWire(A,w):
    w oai %req:wrangle,eternal
        await &SwarmWire_drive,w,req
        req%ok = 1

// SwarmWire_drive — beat dispatch (req-local did_step), then the per-pass tail: pump every
//  station's handshake reqs (Lake_pump_handshakes is generic over w's %Peerings) and re-sort.
async SwarmWire_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.SwarmWire_link_up(w)
        if (n === 3) await this.SwarmWire_handshake(w)
        if (n === 4) await this.SwarmWire_seal(w)
        if (n === 5) await this.SwarmWire_replay(w)
    }
    await this.Lake_pump_handshakes(w)
    await this.SwarmWire_order(w)

// beat 2 — the stations: the same fixed selves as the staple, then ONE Lake_link between their
//  prepubs (each side a %Peering,name flock with a mock carrier), the step-boundary whittle armed
//   once, and the swarm frame kinds registered on the world. No swarm traffic yet.
async SwarmWire_link_up(w):
    w i reached:step_2
    w.sc.now = 1751600000
    let alice = await this.SwarmStaple_person(w, 'Alice')
    let bob = await this.SwarmStaple_person(w, 'Bob')
    await this.Lake_link(w, alice.sc.prepub, bob.sc.prepub)
    this.Peeroleum_arm_whittle(w)
    this.Swarm_arm(w)
    w.doai({req: 'witness', eternal: 1})?.(async (req) => { this.SwarmWire_witness(w); req.sc.ok = 1 })

// beat 3 — authenticate the link: seed %req:handshake on every station's Pier (the generic twin
//  of Lake_handshake, which hardcodes its names) and pump once; the leaves advance as frames cross.
async SwarmWire_handshake(w):
    w i reached:step_3
    for (const peering of w.o({ Peering: 1 })) {
        for (const pier of peering.o({ Pier: 1 })) {
            pier.oai({ req: 'handshake' })
        }
        await peering.do()
    }

// beat 4 — the seal, over the wire: Alice mints (fresh nonce, pinned clock), Bob redeems — the
//  hello rides his station's outbox to her inbox, her accept rides back, both accounts land a
//   %Pier with the cross-signed grants. Deliverance chose the spine on its own: the stations
//    exist, so the mail fallback never fires.
async SwarmWire_seal(w):
    w i reached:step_4
    w.sc.now = 1751600030
    let alice = this.SwarmStaple_ident(w, 'Alice')
    w.c.iz = await this.Swarm_mint_idzeug(w, alice, { Music: 1, genre: 'Classical' }, 'wire_1')
    await this.Swarm_redeem(w, this.SwarmStaple_ident(w, 'Bob'), w.c.iz)

// beat 5 — the replay, over the wire: the same blob again — Alice's spend ledger refuses, and the
//  refusal crosses back as a pier_reject frame Bob surfaces as %rebuff.
async SwarmWire_replay(w):
    w i reached:step_5
    w.sc.now = 1751600040
    await this.Swarm_redeem(w, this.SwarmStaple_ident(w, 'Bob'), w.c.iz)

// SwarmWire_witness — %see claims over the WIRE's truths (the model claims stay the staple's).
//  A %see is NOT a latch: w_forgets_problems wipes {see:1} from the world at EVERY think, and the
//   witness re-mints each claim while its truth holds — so a condition must read DURABLE state.
//    Frame passage therefore reads the spine's whole trace: a live inbox %req:unemit,done (sc.to =
//     the frame type) OR the %recent husk the step-boundary whittle moved it into.
SwarmWire_witness(w):
    let alice = this.SwarmStaple_ident(w, 'Alice')
    let bob = this.SwarmStaple_ident(w, 'Bob')
    if (!alice || !bob) return
    let stations = w.o({ Peering: 1 })
    // beat 2: two stations + the swarm kinds armed on the world.
    if (stations.length >= 2 && w.c.on?.pier_hello && !(oa %see:'two stations stand on the spine — the swarm frame kinds armed on the world')) i %see:'two stations stand on the spine — the swarm frame kinds armed on the world'
    let aPier = stations.find(p => p.sc.name === alice.sc.prepub)?.o({ Pier: 1 })[0]
    let bPier = stations.find(p => p.sc.name === bob.sc.prepub)?.o({ Pier: 1 })[0]
    if (!aPier || !bPier) return
    // beat 3: authenticated both ways BEFORE any swarm frame crossed.
    if (this.Peeroleum_peer_ready(aPier) && this.Peeroleum_peer_ready(bPier) && !(oa %see:'the link authenticated first — hello and trust both ways before any swarm frame')) i %see:'the link authenticated first — hello and trust both ways before any swarm frame'
    // beat 4a: the hello and the accept each crossed as a real DONE inbox item (or its whittled husk).
    let heard = (pier, kind) => {
        let inbox = pier.o({ inbox: 1 })[0]
        if (!inbox) return false
        if (inbox.o({ req: 'unemit' }).some(u => u.sc.to === kind && u.sc.done)) return true
        return !!inbox.o({ recent: 1 })[0]?.o({ unemit: 1 }).some(u => u.sc.type === kind)
    }
    if (heard(aPier, 'pier_hello') && heard(bPier, 'pier_accept') && !(oa %see:'pier_hello and pier_accept crossed as real frames — booked through outbox and inbox')) i %see:'pier_hello and pier_accept crossed as real frames — booked through outbox and inbox'
    // beat 4b: the friendship sealed over the wire — each account's %Pier carries the OTHER's grant.
    let aGot = this.Swarm_peering(alice)?.o({ Pier: 1, pub: bob.sc.prepub })[0]?.o({ Grant: 'Music', by: bob.c.keys?.pub })[0]
    let bGot = this.Swarm_peering(bob)?.o({ Pier: 1, pub: alice.sc.prepub })[0]?.o({ Grant: 'Music', by: alice.c.keys?.pub })[0]
    if (aGot && bGot && !(oa %see:'the friendship sealed over the wire — mutual Music grants at both ends')) i %see:'the friendship sealed over the wire — mutual Music grants at both ends'
    // beat 5: the refusal crossed back — a pier_reject frame heard at Bob and surfaced as %rebuff.
    if (heard(bPier, 'pier_reject') && bob.o({ rebuff: 'rejected_spent' })[0] && !(oa %see:'the spent nonce refuses over the wire too — a pier_reject crossed back')) i %see:'the spent nonce refuses over the wire too — a pier_reject crossed back'

// SwarmWire_order — float A:SwarmWire to the front of H/* so the Run snap stays readable.
async SwarmWire_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'SwarmWire') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)
