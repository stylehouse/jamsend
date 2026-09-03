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

// Crypto for the adversarial beat (SwarmSpoof): mint_grant lets a Book hand-craft the reciprocal
//  grant a malicious pier_hello would carry — the same signed-capability atom Swarm.g composes an
//   Idzeug from. REAL dep (the .g→.ts import idiom), used only to STAGE the attack, never the spine.
IMPORT()
    import { mint_grant, verify_grant, grant_to_C } from "$lib/O/Funk/Grant.ts"
    import { seal, unseal } from "$lib/O/Funk/Sealbox.ts"
    import { sas_transcript, sas_row, sas_agree } from "$lib/O/Funk/Emojiconfirm.ts"

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
//  Swarm_pump), so a hello sent this beat is heard and answered before the beat's snap. EVERY
//   identity of the account — an account can hold an identity HISTORY (SwarmInvite's machine keeps
//    its older deactivated self) and mail lands under the identity it ADDRESSED, so [0] alone
//     starves the active one's inbox.
async SwarmStaple_pump(w):
    for (const acct of w.o({ Account: 1 })) {
        for (const ident of acct.o({ Identity: 1 })) await this.Swarm_pump(w, ident)
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

// beat 3 — Alice mints the Idzeug: the Music offer (Classical only), single-use serial.
//  The compact token parks on w.c for the later beats (re-derivable — nothing durable rides it).
async SwarmStaple_mint(w):
    w i reached:step_3
    w.sc.now = 1751500010
    let alice = this.SwarmStaple_ident(w, 'Alice')
    w.c.iz = await this.Swarm_mint_idzeug(w, alice, { Music: 1, genre: 'Classical' }, 'staple_1')

// beat 4 — the two rebuffs, teeth first: a MANGLED token (nothing like prepub*serial*n*presig)
//  must rebuff at the redeemer before a single frame crosses; the TRUE token redeemed while Alice
//   is offline must fail delivery — proof of receipt needs the party present. (The subtler tamper —
//    a flipped presig on a well-formed token — is beat 5's door tooth: only the ISSUER can check a
//     presig, so client-side verification is no longer a thing to prove.)
async SwarmStaple_rebuffs(w):
    w i reached:step_4
    w.sc.now = 1751500020
    let bob = this.SwarmStaple_ident(w, 'Bob')
    this.Swarm_online(bob, true)
    await this.Swarm_redeem(w, bob, 'not-a-token-at-all')
    await this.Swarm_redeem(w, bob, w.c.iz)

// beat 5 — the seal: Alice comes online. FIRST a tampered token knocks — the last presig hex
//  flipped: well-formed, real serial, but the door regenerates its OWN presig and the prefix
//   mismatches → refuse('forged') LOCALLY (nothing spends, Bob hears silence). THEN Bob redeems
//    for real: hello → accept → confirm play out through the pump within this beat's passes; both
//     ends land a %Pier + cross grants + an edge. The THIRD frame (pier_confirm) carries Bob's
//      DEFERRED reciprocal — Alice holding Bob's grant IS the proof it crossed.
async SwarmStaple_seal(w):
    w i reached:step_5
    w.sc.now = 1751500030
    this.Swarm_online(this.SwarmStaple_ident(w, 'Alice'), true)
    let bob = this.SwarmStaple_ident(w, 'Bob')
    let tam = w.c.iz.slice(0, -1) + (w.c.iz.endsWith('0') ? '1' : '0')
    await this.Swarm_redeem(w, bob, tam)
    await this.Swarm_redeem(w, bob, w.c.iz)

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

// ── the witness — %sworn assertions via this.story_swear (idempotent per run, shelf-checked, so
//  no oa guards ride the sentences). Every claim here is a happened-FACT of the handshake (two
//   selves, a mint, a rebuff, a seal, a revocation, a round trip) — once true it STAYS true.
//    Evidence lands on the ave/%Assertioning shelf (never snap bytes); the contract lives under
//     the toc step lines (`step=N/%Assertion`) and a missing one reds the run un-maskably.
SwarmStaple_witness(w):
    let alice = this.SwarmStaple_ident(w, 'Alice')
    let bob = this.SwarmStaple_ident(w, 'Bob')
    if (!alice || !bob) return
    let aPeering = this.Swarm_peering(alice)
    let bPeering = this.Swarm_peering(bob)
    // beat 2: two selves — each an %Identity owning its %Peering page, the keypair on .c only.
    if (aPeering && bPeering && alice.c.keys?.key) this.story_swear(w, 'two selves stand — each an Identity owning its Peering page — keys ride .c only')
    // beat 3: the offer exists as a nonce record — FOR the Music Feature scoped to Classical.
    let record = aPeering?.o({ Idzeug: 1 })[0]
    if (record && record.sc.to === 'Music' && record.sc.genre === 'Classical') this.story_swear(w, 'Alice holds a single-use Idzeug — an unbound Music grant scoped to Classical')
    // beat 4: teeth — the mangled token rebuffed at the parse; the offline redeem failed delivery.
    if (bob.o({ rebuff: 'forged' })[0]) this.story_swear(w, 'a mangled token is rebuffed at the redeemer — it never parses and no frame crosses')
    if (bob.o({ rebuff: 'offline' })[0]) this.story_swear(w, 'redeeming with the inviter offline fails — the token is proof of receipt not an offline capability')
    // beat 5: the tamper tooth then the mutual seal — read both Piers once, claim import +
    //  reciprocity + the graph. Alice holding the grant BOB signed is the third frame's own
    //   receipt: the deferred reciprocal only ever crosses as pier_confirm.
    let aPier = aPeering?.o({ Pier: 1, pub: bob.sc.prepub })[0]
    let bPier = bPeering?.o({ Pier: 1, pub: alice.sc.prepub })[0]
    if (alice.o({ rebuff: 'hello_forged' })[0] && aPier) this.story_swear(w, 'a flipped presig refuses locally at the door — only the issuer key can wear the MAC — and the true token still seals behind it')
    if (bPier && bPier.o({ Peering: 1 })[0]?.sc?.friendly === 'Alice') this.story_swear(w, 'Bob imported the page of Alice — the stashed Peering reborn under his Pier')
    let aGot = aPier?.o({ Grant: 'Music', by: bob.c.keys?.pub })[0]
    let bGot = bPier?.o({ Grant: 'Music', by: alice.c.keys?.pub })[0]
    if (aGot && bGot && aGot.sc.genre === 'Classical' && bGot.sc.genre === 'Classical') this.story_swear(w, 'each Pier carries a Music grant the OTHER signed — Classical only — reciprocity sealed')
    let aEdge = alice.o({ SocialGraph: 1 })[0]?.o({ Edge: 1, b: bob.sc.prepub })[0]
    let bEdge = bob.o({ SocialGraph: 1 })[0]?.o({ Edge: 1, b: alice.sc.prepub })[0]
    if (aEdge && bEdge) this.story_swear(w, 'the friendship is an edge logged in the social graph at both ends')
    // beat 6: single-use — the spent nonce rebuffs Carol at Alice's door; no Pier forms for her.
    let carol = this.SwarmStaple_ident(w, 'Carol')
    let carolPier = carol && this.Swarm_peering(carol)?.o({ Pier: 1 })[0]
    if (carol && carol.o({ rebuff: 'rejected_spent' })[0] && !carolPier) this.story_swear(w, 'the Idzeug is single-use — a second redeem finds the nonce spent and is rebuffed')
    // beat 7: revocation at use — Alice's Pier retires under its %NotGrant while Bob's still stands.
    if (aPier && bPier && aPier.o({ NotGrant: 'Music' })[0] && !this.Swarm_pier_live(aPier, 'Music') && this.Swarm_pier_live(bPier, 'Music')) this.story_swear(w, 'a NotGrant under the Pier retires it at use — the other end stands until told')
    // beat 8: the round trip — restored twin holds the Pier and the keys, and the blobs matched.
    let restored = w.o({ Account: 1, of: 'AliceVault' })[0]?.o({ Identity: 1 })[0]
    if (restored && this.Swarm_peering(restored)?.o({ Pier: 1, pub: bob.sc.prepub })[0] && restored.c.keys?.key && w.o({ roundtrip: 'identical' })[0]) this.story_swear(w, 'the account survives export and import byte for byte — Pier and grants and keys intact')

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
    w.sc.now = 1751600000
    let alice = await this.SwarmStaple_person(w, 'Alice')
    let bob = await this.SwarmStaple_person(w, 'Bob')
    await this.Lake_link(w, alice.sc.prepub, bob.sc.prepub)
    this.Peeroleum_arm_whittle(w)
    this.Swarm_arm(w)
    // seed %req:handshake NOW (the generic twin of Lake_handshake, which hardcodes its names) so the
    //  link authenticates over steps 2→3 — frames settle across think passes, so an early seed makes
    //   "authenticated by beat 3" deterministic and, crucially, provable BEFORE the beat-4 swarm frames.
    for (const peering of w.o({ Peering: 1 })) {
        for (const pier of peering.o({ Pier: 1 })) pier.oai({ req: 'handshake' })
    }
    w.doai({req: 'witness', eternal: 1})?.(async (req) => { this.SwarmWire_witness(w); req.sc.ok = 1 })

// beat 3 — the authenticated beat: pump each station once more; by now both handshakes have reached
//  finished (seeded at beat 2), so the witness confirms the link is trusted before any swarm frame.
async SwarmWire_handshake(w):
    for (const peering of w.o({ Peering: 1 })) await peering.do()

// beat 4 — the seal, over the wire: Alice mints (fresh serial, pinned clock), Bob redeems — the
//  hello rides his station's outbox to her inbox, her accept rides back, his pier_confirm carries
//   the deferred reciprocal, both accounts land a %Pier with the cross-signed grants. Deliverance
//    chose the spine on its own: the stations exist, so the mail fallback never fires.
async SwarmWire_seal(w):
    w.sc.now = 1751600030
    let alice = this.SwarmStaple_ident(w, 'Alice')
    w.c.iz = await this.Swarm_mint_idzeug(w, alice, { Music: 1, genre: 'Classical' }, 'wire_1')
    await this.Swarm_redeem(w, this.SwarmStaple_ident(w, 'Bob'), w.c.iz)

// beat 5 — the replay, over the wire: the same blob again — Alice's spend ledger refuses, and the
//  refusal crosses back as a pier_reject frame Bob surfaces as %rebuff.
async SwarmWire_replay(w):
    w.sc.now = 1751600040
    await this.Swarm_redeem(w, this.SwarmStaple_ident(w, 'Bob'), w.c.iz)

// SwarmWire_witness — %sworn assertions via this.story_swear (idempotent per run; evidence lands
//  on the Assertioning shelf, never snap bytes). Every claim is a happened-FACT of the wire
//   handshake (two stations, an authenticated link, real frames crossing, the seal, the
//    spent-nonce refusal). The n === K truth-gate is KEPT: a crossed frame reads as its live
//     inbox %req:unemit,done (sc.to = the frame type) only at the step it lands, so gating to
//      that beat catches the transient exactly when it is observable; the sworn then carries it
//       for the run. Contract under the toc step lines; a missing one reds the run un-maskably.
SwarmWire_witness(w):
    let n = (this.c.run)?.c.step_n
    let alice = this.SwarmStaple_ident(w, 'Alice')
    let bob = this.SwarmStaple_ident(w, 'Bob')
    if (!alice || !bob) return
    let stations = w.o({ Peering: 1 })
    // beat 2: two stations + the swarm kinds armed on the world.
    if (n === 2 && stations.length >= 2 && w.c.on?.pier_hello) this.story_swear(w, 'two stations stand on the spine — the swarm frame kinds armed on the world')
    let aPier = stations.find(p => p.sc.name === alice.sc.prepub)?.o({ Pier: 1 })[0]
    let bPier = stations.find(p => p.sc.name === bob.sc.prepub)?.o({ Pier: 1 })[0]
    if (!aPier || !bPier) return
    // beat 3: authenticated both ways BEFORE any swarm frame crossed.
    if (n === 3 && this.Peeroleum_peer_ready(aPier) && this.Peeroleum_peer_ready(bPier)) this.story_swear(w, 'the link authenticated first — hello and trust both ways before any swarm frame')
    // beat 4: the hello and accept each crossed as a real DONE inbox item, and the friendship sealed.
    let heard = (pier, kind) => pier.o({ inbox: 1 })[0]?.o({ req: 'unemit' }).some(u => u.sc.to === kind && u.sc.done)
    if (n === 4 && heard(aPier, 'pier_hello') && heard(bPier, 'pier_accept') && heard(aPier, 'pier_confirm')) this.story_swear(w, 'pier_hello and pier_accept and pier_confirm crossed as real frames — booked through outbox and inbox')
    let aGot = this.Swarm_peering(alice)?.o({ Pier: 1, pub: bob.sc.prepub })[0]?.o({ Grant: 'Music', by: bob.c.keys?.pub })[0]
    let bGot = this.Swarm_peering(bob)?.o({ Pier: 1, pub: alice.sc.prepub })[0]?.o({ Grant: 'Music', by: alice.c.keys?.pub })[0]
    if (n === 4 && aGot && bGot) this.story_swear(w, 'the friendship sealed over the wire — mutual Music grants at both ends')
    // beat 5: the refusal crossed back — a pier_reject frame heard at Bob and surfaced as %rebuff.
    if (n === 5 && heard(bPier, 'pier_reject') && bob.o({ rebuff: 'rejected_spent' })[0]) this.story_swear(w, 'the spent nonce refuses over the wire too — a pier_reject crossed back')

// SwarmWire_order — float A:SwarmWire to the front of H/* so the Run snap stays readable.
async SwarmWire_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'SwarmWire') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)


// ══ SwarmSteal — the THIRD Book: one key, many places — cooperation, theft, and Steal Back ═══════════
//  SwarmStaple proves the MODEL and SwarmWire the WIRE; SwarmSteal proves the ADDRESS — §3's
//   identity≠address split. Alice is ONE identity in several places. Sibling tabs of the SAME key are
//    COOPERATIVE (the Dexie-liveQuery "these are all our tabs" roster) and split the work — one plays
//     music, one encodes — so a 6-hour leak never takes it all down. A claimant that is NOT one of our
//      tabs is a THEFT: a remote copy contesting the name → Identity Stolen. Steal Back concedes the
//       bare name and re-presents at the next free suffix (<prepub>_2 here — a sibling already holds
//        _1), SAME key, so Alice's Piers still verify her. No wire — model layer only; own world
//         w:SwarmSteal (dispatch by world name, the usual bomb). Same fixed Alice as the staple.
//   beat 2  Alice stands — one identity holding its key-derived prepub as its canonical name
//   beat 3  two sibling tabs join (the roster) — no alarm — and the tabs split roles music|encode
//   beat 4  a foreign place (not one of our tabs) claims Alice's name → Identity Stolen
//   beat 5  Steal Back → Alice re-presents at <prepub>_2 (past thief + siblings) — the alarm clears
//   beat 6  the key never moved — identity ≠ address — the page's pub still verifies her at _2

SwarmSteal(A,w):
    w oai %req:wrangle,eternal
        await &SwarmSteal_drive,w,req
        req%ok = 1

// SwarmSteal_drive — beat dispatch (req-local did_step), then re-sort. No pump: SwarmSteal is all
//  model-layer (no mail, no frames) so there is nothing to deliver between beats.
async SwarmSteal_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.SwarmSteal_stand(w)
        if (n === 3) await this.SwarmSteal_siblings(w)
        if (n === 4) await this.SwarmSteal_theft(w)
        if (n === 5) await this.SwarmSteal_steal_back(w)
        if (n === 6) await this.SwarmSteal_verify(w)
    }
    await this.SwarmSteal_order(w)

// beat 2 — Alice stands: one %Identity holding its bare prepub as its only address. Witness rides its
//  own swept req, minted last so it observes each pass's settled state.
async SwarmSteal_stand(w):
    w.sc.now = 1751700000
    await this.SwarmStaple_person(w, 'Alice')
    w.doai({req: 'witness', eternal: 1})?.(async (req) => { this.SwarmSteal_witness(w); req.sc.ok = 1 })

// beat 3 — the cooperative tabs: two siblings of the SAME key join the roster (one holding _1, one _3
//  among them), and the places split the work — THIS place plays music, a sibling encodes. A known
//   sibling claiming our name is co-presence, not a theft — note_theft returns false, no alarm raised.
async SwarmSteal_siblings(w):
    w.sc.now = 1751700010
    let alice = this.SwarmStaple_ident(w, 'Alice')
    this.Swarm_take_role(alice, 'music')
    this.Swarm_sibling(alice, 'tab_encode', alice.sc.prepub + '_1', 'encode')
    this.Swarm_sibling(alice, 'tab_spare', alice.sc.prepub + '_3', 'serve')
    this.Swarm_note_theft(alice, 'tab_encode', 1751700010)

// beat 4 — the theft: a place we do NOT recognize claims Alice's name. Not a sibling → Identity Stolen
//  (the flag rises and a durable %Stolen,by:remote_copy husk lands for the banner).
async SwarmSteal_theft(w):
    w.sc.now = 1751700020
    let alice = this.SwarmStaple_ident(w, 'Alice')
    this.Swarm_note_theft(alice, 'remote_copy', 1751700020)

// beat 5 — Steal Back: concede the bare name, jump past the thief (bare) and the siblings (_1, _3) to
//  the next free suffix — <prepub>_2 — SAME key. The alarm clears; the %Stolen husk stays as history.
async SwarmSteal_steal_back(w):
    w.sc.now = 1751700030
    let alice = this.SwarmStaple_ident(w, 'Alice')
    let prepub = alice.sc.prepub
    w.c.new_addr = this.Swarm_steal_back(alice, [prepub, prepub + '_1', prepub + '_3'])

// beat 6 — identity ≠ address: Alice re-presents (online) at the new address — her key-derived NAME is
//  unchanged while she is reachable at _2, so a Pier still verifies her by pub.
async SwarmSteal_verify(w):
    w.sc.now = 1751700040
    let alice = this.SwarmStaple_ident(w, 'Alice')
    this.Swarm_online(alice, true)

// ── the witness — each %see is a per-beat OBSERVATION, gated to its own step (n === K) and reading the
//  LIVE truth of that beat, so it appears once and DROPS when the story moves on. %see is NOT a latch:
//   w_forgets_problems wipes {see:1} every think, and that is the FEATURE — do not re-mint a claim past
//    its beat (a persisting %see is the old %witnessed noise reborn). The drop is the signal — step 4's
//     `stolen` reads TRUE live and step 5's cleared flag reads FALSE, and the beat-gate keeps the
//      no-alarm claim from flickering back when the flag clears. [[see-is-not-a-latch]] corrected.
SwarmSteal_witness(w):
    let n = (this.c.run)?.c.step_n
    let alice = this.SwarmStaple_ident(w, 'Alice')
    if (!alice) return
    let peering = this.Swarm_peering(alice)
    if (!peering) return
    let prepub = alice.sc.prepub
    // beat 2: Alice stands alone — her key-derived name is her ONE address, no siblings yet.
    if (n === 2 && peering.sc.name === prepub && this.Swarm_address(alice) === prepub && !peering.o({ Sibling: 1 }).length && !(oa %see:'Alice stands alone — her key-derived name is her one address')) i %see:'Alice stands alone — her key-derived name is her one address'
    // beat 3: cooperative tabs — a known sibling raised NO alarm and the places split the work.
    let sib = peering.o({ Sibling: 'tab_encode' })[0]
    if (n === 3 && sib && peering.sc.duty === 'music' && sib.sc.duty === 'encode' && !this.Swarm_stolen(alice) && !(oa %see:'sibling tabs of one key cooperate — no theft alarm — and split the work — one plays music one encodes')) i %see:'sibling tabs of one key cooperate — no theft alarm — and split the work — one plays music one encodes'
    // beat 4: a claimant that is NOT one of our tabs raises the LIVE alarm — Identity Stolen.
    if (n === 4 && this.Swarm_stolen(alice) && peering.o({ Stolen: 'remote_copy' })[0] && !this.Swarm_is_sibling(alice, 'remote_copy') && !(oa %see:'a claimant that is not one of our tabs raises Identity Stolen — a remote copy contesting the name')) i %see:'a claimant that is not one of our tabs raises Identity Stolen — a remote copy contesting the name'
    // beat 5: Steal Back re-presented at the next free suffix past thief + siblings and cleared the alarm.
    if (n === 5 && this.Swarm_address(alice) === prepub + '_2' && !this.Swarm_stolen(alice) && !(oa %see:'Steal Back jumps past the thief and the siblings to prepub_2 and clears the alarm')) i %see:'Steal Back jumps past the thief and the siblings to prepub_2 and clears the alarm'
    // beat 6: identity is not address — the canonical name never moved while she is reachable at _2.
    if (n === 6 && peering.sc.name === prepub && this.Swarm_address(alice) === prepub + '_2' && peering.sc.online && !(oa %see:'identity is not address — the key never moved — a Pier still verifies her at prepub_2')) i %see:'identity is not address — the key never moved — a Pier still verifies her at prepub_2'
    // ── %sworn — the DURABLE assertions, via this.story_swear (idempotent per run). Stand beside the
    //  %see above; a sworn is a happened-FACT, latched once the first beat its truth holds — evidence
    //   on the Assertioning shelf (never snap bytes), contract under the toc step lines (the hosting
    //    step is the by-when); Cred_assertion_gaps reds a missing one.
    // theft-contested — latches at beat 4 (the %Stolen husk lands) and SURVIVES past beat 5, where the
    //  LIVE `stolen` flag clears: the observation drops but the fact "a theft happened" stays true. This
    //   is the whole point of the split — a latched fact where a %see would flicker out.
    if (n >= 4 && peering.o({ Stolen: 'remote_copy' })[0]) this.story_swear(w, 'a foreign claimant once contested the name of Alice — a copy that was not one of our tabs raised Identity Stolen')
    // identity-not-address — the culminating happened-fact (the doc's named latch candidate): latches at
    //  beat 6 when the key-derived name is unchanged while the address has moved to _2 and she is online.
    if (n >= 6 && peering.sc.name === prepub && this.Swarm_address(alice) === prepub + '_2' && peering.sc.online) this.story_swear(w, 'identity is not address — the key-derived name of Alice never changed while the address moved to prepub_2')

// SwarmSteal_order — float A:SwarmSteal to the front of H/* so the Run snap stays readable.
async SwarmSteal_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'SwarmSteal') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)


// ══ SwarmInvite — the FOURTH Book: the QR front door (Swarm_spec §10.1) ══════════════════════════
//  SwarmStaple proves the MODEL, SwarmWire the WIRE, SwarmSteal the ADDRESS; SwarmInvite proves the
//   FRONT DOOR: the invite as a scannable URL minted from the machine's LIVE-shaped identity — the
//    one Auto's own Clustation_concrete makes (called HERE, the real shape-maker, so Auto shape
//     drift turns THIS Book red) — parsed back exactly as the ?Iz= boot handler will, sealed into a
//      Pier, and dead to a second scanner. Mail wire (SwarmWire owns spine carriage); own world
//       w:SwarmInvite (dispatch by world name, the usual bomb); pinned clock, seeded keys.
//   beat 2  the machine stands — TWO identities concreted by Clustation_concrete, so only the
//            second is ACTIVE (its contract) — plus the Phone, a stranger with its own keys
//   beat 3  the mint — Swarm_invite_url from the ACTIVE self → <base>?Iz=<token>; the beat itself
//            re-parses the URL (the compact token — under sixty chars — stamps %minted for the witness)
//   beat 4  the scan — the Phone pulls the token out of the URL (Swarm_iz_of_url, the boot handler's
//            core) and redeems: hello → accept → confirm over the mail wire → mutual %Pier + grants
//   beat 5  the photograph — Eve scans the SAME QR later: the serial is spent, the door refuses

SwarmInvite(A,w):
    w oai %req:wrangle,eternal
        await &SwarmInvite_drive,w,req
        req%ok = 1

// SwarmInvite_drive — beat dispatch (req-local did_step), then the per-pass tail: pump every
//  account's mail (SwarmStaple_pump is generic over w's %Accounts — the machine IS an %Account
//   here, so its hello gets heard) and re-sort.
async SwarmInvite_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.SwarmInvite_stand(w)
        if (n === 3) await this.SwarmInvite_mint(w)
        if (n === 4) await this.SwarmInvite_scan(w)
        if (n === 5) await this.SwarmInvite_photograph(w)
    }
    await this.SwarmStaple_pump(w)
    await this.SwarmInvite_order(w)

// beat 2 — the machine stands. The identity is made by the REAL maker: Clustation_concrete, twice —
//  an older self first, then the current one — proving the active-flag contract (only ONE active,
//   the front door must pick it). The container is an %Account so the mail wire routes to it (the
//    A:Clustation hop under top_House is Swarm_live_self's live-only inch, exercised by the panel).
async SwarmInvite_stand(w):
    w i reached:step_2
    w.sc.now = 1751800000
    let acct = w.oai({ Account: 1, of: 'Machine' })
    acct.c.up = w
    let old = await this.Swarm_mint_keys('SwarmInvite-Machine-old')
    this.Clustation_concrete(acct, old.prepub, old)
    let cur = await this.Swarm_mint_keys('SwarmInvite-Machine')
    this.Clustation_concrete(acct, cur.prepub, cur)
    await this.SwarmStaple_person(w, 'Phone')
    w.doai({req: 'witness', eternal: 1})?.(async (req) => { this.SwarmInvite_witness(w); req.sc.ok = 1 })

// beat 3 — the mint: the front door resolves the ACTIVE self and dresses the Idzeug as the URL the
//  QR will carry (base pinned — live it is location.origin + the toplevel path). The beat then does
//   the round trip itself — pull the token back out of the URL, parse it — and stamps %minted with
//    what the parse SAW (plus the token LENGTH: the whole point of the compact form is a QR a phone
//     grabs across a table), so the sync witness reads a stamp, not an await.
async SwarmInvite_mint(w):
    w i reached:step_3
    w.sc.now = 1751800010
    let acct = w.o({ Account: 1, of: 'Machine' })[0]
    let ident = this.Swarm_active_ident(acct)
    this.Swarm_online(ident, true)
    w.c.url = await this.Swarm_invite_url(w, ident, { Music: 1 }, 'https://jamsend.example/BigSoundland')
    let back = this.Swarm_iz_of_url(w.c.url)
    let t = this.Swarm_token_parse(back)
    if (t) w.i({ minted: 'parsed', to: t.to, of: t.prepub, nonce: t.serial, chars: String(back.length) })

// beat 4 — the scan: the Phone does exactly what the ?Iz= boot handler will — pull the blob out of
//  the URL and redeem it. hello → accept ride the mail wire across this beat's passes; both ends
//   land a %Pier with cross-signed Music grants.
async SwarmInvite_scan(w):
    w i reached:step_4
    w.sc.now = 1751800020
    let phone = this.SwarmStaple_ident(w, 'Phone')
    this.Swarm_online(phone, true)
    await this.Swarm_redeem(w, phone, this.Swarm_iz_of_url(w.c.url))

// beat 5 — the photograph: Eve shot the QR over a shoulder and opens it later. The token is
//  real, but the machine's spend ledger says no — the QR on the screen is single-use.
async SwarmInvite_photograph(w):
    w i reached:step_5
    w.sc.now = 1751800030
    let eve = await this.SwarmStaple_person(w, 'Eve')
    this.Swarm_online(eve, true)
    await this.Swarm_redeem(w, eve, this.Swarm_iz_of_url(w.c.url))

// ── the witness — per-beat %see observations, n-gated, reading live truth (the SwarmSteal lesson) ──
SwarmInvite_witness(w):
    let n = (this.c.run)?.c.step_n
    let acct = w.o({ Account: 1, of: 'Machine' })[0]
    let phone = this.SwarmStaple_ident(w, 'Phone')
    if (!acct || !phone) return
    let ident = this.Swarm_active_ident(acct)
    // beat 2: the REAL maker stood the self — keys on .c, nick stamped, Peering owned — and its
    //  only-one-active contract held: the older self stands by deactivated.
    let actives = acct.o({ Identity: 1 }).filter(i => i.sc.active)
    if (n === 2 && ident && ident.c.keys?.key && ident.sc.nick && this.Swarm_peering(ident) && actives.length === 1 && acct.o({ Identity: 1 }).length === 2 && !(oa %see:'the machine self is made by its real maker — keys and nick and Peering — and only one identity is active')) i %see:'the machine self is made by its real maker — keys and nick and Peering — and only one identity is active'
    // beat 3: the invite IS a URL — the compact token inside parses back to the Music offer from
    //  the active self AND stays small enough for an easy QR (the %minted stamp is the parse's own
    //   sighting; only the ISSUER could verify further, and beat 4 proves that at the door).
    let minted = w.o({ minted: 'parsed' })[0]
    if (n === 3 && String(w.c.url).startsWith('https://jamsend.example/BigSoundland?Iz=') && minted && minted.sc.to === 'Music' && minted.sc.of === ident?.sc?.prepub && Number(minted.sc.chars) < 60 && !(oa %see:'the invite is a URL — the compact token inside parses back to a Music offer under sixty characters')) i %see:'the invite is a URL — the compact token inside parses back to a Music offer under sixty characters'
    // beat 4: the scan sealed it — the Phone holds a Pier for the machine with the machine's signed
    //  Music grant, and the machine holds the mirror Pier for the Phone.
    let pPier = this.Swarm_peering(phone)?.o({ Pier: 1, pub: ident?.sc?.prepub })[0]
    let mPier = ident && this.Swarm_peering(ident)?.o({ Pier: 1, pub: phone.sc.prepub })[0]
    if (n === 4 && pPier && pPier.o({ Grant: 'Music', by: ident.c.keys?.pub })[0] && mPier && !(oa %see:'the phone scans the URL and gains a Pier — a Music grant signed by the machine rides it both ways')) i %see:'the phone scans the URL and gains a Pier — a Music grant signed by the machine rides it both ways'
    // beat 5: the photograph is dead — Eve rebuffed on the spent nonce, no Pier forms for her.
    let eve = this.SwarmStaple_ident(w, 'Eve')
    if (n === 5 && eve && eve.o({ rebuff: 'rejected_spent' })[0] && !this.Swarm_peering(eve)?.o({ Pier: 1 }).length && !(oa %see:'a photographed QR is dead after its first scan — the spent nonce refuses at the door')) i %see:'a photographed QR is dead after its first scan — the spent nonce refuses at the door'

// SwarmInvite_order — float A:SwarmInvite to the front of H/* so the Run snap stays readable.
async SwarmInvite_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'SwarmInvite') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)


// ══ SwarmDoor — the FIFTH Book: FIRST CONTACT at the door (Swarm_spec §10.1 frontier rung) ══════
//  The others prove the model / wire / address / front-door with SYMMETRIC, pre-handshaked or
//   mail-wire pairs. SwarmDoor proves the ASYMMETRIC seam the live two-tab join runs — the one the
//    2026-07-07 station build added and existing Books only proved INERT: a station hears a
//     STRANGER's pier_hello for a prepub it holds NO %Pier for. That drives three new paths at once:
//      (1) Peeroleum_deliver's no-pier pier_hello branch (dispatch-then-ack-through-the-just-promoted
//       route), (2) Swarm_hello promoting the caller's transport %Pier at the door (Swarm_station_pier),
//        (3) Swarm_deliver counting a live carrier under an UP station as readiness — NO per-Pier
//         handshake, so peer_ready is false and the station_up arm is the ONLY thing that carries.
//  What this Book does NOT prove: the REAL Swarm_station_up dialing a websocket (un-Bookable — it
//   opens a live socket; the two-tab live join is that proof). It stands the deterministic station
//    SHAPE (a bare %Peering + a paired mock carrier, station_up stamped) its deliver/promote logic
//     runs on. Own world w:SwarmDoor (dispatch by world name — the usual bomb); seeded keys, pinned clock.
//   beat 2  two BARE stations stand on the spine — a mock carrier each, station_up, kinds armed, NO Piers
//   beat 3  the inviter mints an Idzeug — its station still routes to no one
//   beat 4  the joiner promotes its OWN transport Pier to the inviter (the panel move) and redeems
//   beat 5  settled: FIRST CONTACT sealed — the door promoted the route at the knock; readiness rode station_up

SwarmDoor(A,w):
    w oai %req:wrangle,eternal
        await &SwarmDoor_drive,w,req
        req%ok = 1

// SwarmDoor_drive — beat dispatch (req-local did_step), then re-sort. No explicit pump: the swarm
//  frames ride the REAL spine (outbox→mock carrier→inbox), crossing on the post_do cascade across
//   think passes exactly as SwarmWire's do — the eternal witness polls each pass and notices the seal.
async SwarmDoor_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.SwarmDoor_stand(w)
        if (n === 3) await this.SwarmDoor_mint(w)
        if (n === 4) await this.SwarmDoor_knock(w)
        if (n === 5) await this.SwarmDoor_settle(w)
    }
    await this.SwarmDoor_order(w)

// SwarmDoor_station — stand a BARE transport station under w for `ident`: a %Peering named by its
//  prepub (the name Socket_real would dial as ?addr=) with a mock carrier, but NO %Pier and NO
//   %req:handshake — the un-handshaked shape a LIVE station has before anyone calls. Returns the
//    carrier so two stations pair (partner ↔ partner). The mock carrier is Lake_peer's, minus the
//     Pier. AUTO-ASYNC'd (its send closure carries a bare await, the Lake_peer footgun) → AWAIT the
//      call, else the return is a Promise and .partner never pairs. Body runs sync, so the Peering
//       exists at once; only the returned carrier needs awaiting.
SwarmDoor_station(w, ident):
    const H = this
    let peering = w.oai({ Peering: 1, name: ident.sc.prepub })
    peering.c.up = w
    let at = peering.i({ active_transport: 1, type: 'mock', open: 1 })
    at.c.connection = {
        type: 'mock', partner: null, reliable: true,
        send(frame) {
            let to = frame && frame.header && frame.header.to
            if (to != null && String(to)[0] === '@') { H.post_do(async () => { await H.Peeroleum_deliver(w, frame) }, { see: 'swarmation_fan_channel' }); return }
            H.post_do(async () => { await this.partner?.recv(frame) }, { see: 'swarmation_send' })
        },
        recv(frame) { return H.Peeroleum_deliver(w, frame) },
    }
    return at.c.connection

// beat 2 — two bare stations, carriers paired. Two fixed selves (%Account each, key-seeded), a
//  station %Peering + mock carrier for each (NO Pier), station_up stamped, the step-boundary whittle
//   armed once, and the swarm frame kinds registered on the world. No traffic, no Piers yet.
async SwarmDoor_stand(w):
    w.sc.now = 1751900000
    let inviter = await this.SwarmStaple_person(w, 'Inviter')
    let joiner = await this.SwarmStaple_person(w, 'Joiner')
    let ca = await this.SwarmDoor_station(w, inviter)
    let cb = await this.SwarmDoor_station(w, joiner)
    ca.partner = cb
    cb.partner = ca
    w.c.station_up = 1
    this.Peeroleum_arm_whittle(w)
    this.Swarm_arm(w)
    w.doai({req: 'witness', eternal: 1})?.(async (req) => { this.SwarmDoor_witness(w); req.sc.ok = 1 })

// beat 3 — the inviter mints the Idzeug: an unbound Music offer (Classical), single-use nonce. Its
//  station still holds no Pier — the invite is the only thing pointing outward.
async SwarmDoor_mint(w):
    w.sc.now = 1751900010
    let inviter = this.SwarmStaple_ident(w, 'Inviter')
    w.c.iz = await this.Swarm_mint_idzeug(w, inviter, { Music: 1, genre: 'Classical' }, 'door_1')

// beat 4 — the knock: the joiner does exactly what InvitePanel.join does — promote its OWN transport
//  Pier to the inviter (the redeemer knows the target), then redeem. The pier_hello rides the joiner
//   station's carrier to the inviter station, which holds NO Pier for the joiner → the first-contact
//    branch dispatches it, Swarm_hello promotes the inviter-side route, seals, and answers.
async SwarmDoor_knock(w):
    w.sc.now = 1751900020
    let joiner = this.SwarmStaple_ident(w, 'Joiner')
    let inviter = this.SwarmStaple_ident(w, 'Inviter')
    this.Swarm_station_pier(w, joiner, inviter.sc.prepub)
    await this.Swarm_redeem(w, joiner, w.c.iz)

// beat 5 — settle: a whole beat after the knock so the post_do frame cascade has fully crossed
//  (the transport-frames-ride-post_do rule — witness the SETTLED seal, never mid-flight). Only
//   re-pins the clock; the witness reads the sealed state.
async SwarmDoor_settle(w):
    w.sc.now = 1751900030

// ── the witness — %sworn assertions via this.story_swear (idempotent per run; evidence on the
//    Assertioning shelf, never snap bytes — no commas, no apostrophes in sentences). Every claim
//     is a happened-FACT of the door handshake (two bare stations, a minted Idzeug, a promoted
//      Pier, first contact sealed, readiness riding station_up). The n === K gate is KEPT:
//       several gates read a state that holds only at their beat (bare "no Pier yet", the
//        pre-seal route), so gating pins the fact to when it is observable.  These are all
//         ACHIEVEMENTS today (no contract lines in SwarmDoor's toc); its fixtures were
//          re-recorded 2026-07-19 — they had carried a stale pre-hardening `see:` line. ──
SwarmDoor_witness(w):
    let n = (this.c.run)?.c.step_n
    let inviter = this.SwarmStaple_ident(w, 'Inviter')
    let joiner = this.SwarmStaple_ident(w, 'Joiner')
    if (!inviter || !joiner) return
    let iStation = w.o({ Peering: 1 }).find(p => p.sc.name === inviter.sc.prepub)
    let jStation = w.o({ Peering: 1 }).find(p => p.sc.name === joiner.sc.prepub)
    if (!iStation || !jStation) return
    let live = (s) => !!this.Peeroleum_carrier(s, w)
    // beat 2: two BARE stations — a carrier each, station_up, the swarm kinds armed, and NEITHER
    //  holds a Pier yet (first contact is still to come).
    if (n === 2 && live(iStation) && live(jStation) && w.c.station_up && w.c.on?.pier_hello && !iStation.o({ Pier: 1 }).length && !jStation.o({ Pier: 1 }).length) this.story_swear(w, 'two bare stations stand on the spine — a carrier each — and neither holds a Pier yet')
    // beat 3: the inviter holds a single-use Idzeug — its station still routes to no one.
    let record = this.Swarm_peering(inviter)?.o({ Idzeug: 1 })[0]
    if (n === 3 && record && record.sc.to === 'Music' && !iStation.o({ Pier: 1 }).length) this.story_swear(w, 'the inviter holds a single-use Idzeug — its station still routes to no one')
    // beat 4: the joiner promoted its OWN transport Pier to the inviter before dialing (the panel move).
    if (n === 4 && jStation.o({ Pier: 1, pub: inviter.sc.prepub })[0]) this.story_swear(w, 'the joiner promotes a transport Pier to the inviter before dialing — the redeemer knows the target')
    // beat 5: FIRST CONTACT — a stranger reached a station holding no prior Pier; the door promoted
    //  the transport route AND sealed the durable friendship, each grant signed by the other.
    let iRoute = iStation.o({ Pier: 1, pub: joiner.sc.prepub })[0]
    let jRoute = jStation.o({ Pier: 1, pub: inviter.sc.prepub })[0]
    let iPier = this.Swarm_peering(inviter)?.o({ Pier: 1, pub: joiner.sc.prepub })[0]
    let jPier = this.Swarm_peering(joiner)?.o({ Pier: 1, pub: inviter.sc.prepub })[0]
    let iGot = iPier?.o({ Grant: 'Music', by: joiner.c.keys?.pub })[0]
    let jGot = jPier?.o({ Grant: 'Music', by: inviter.c.keys?.pub })[0]
    if (n === 5 && iRoute && iGot && jGot) this.story_swear(w, 'first contact — a stranger reached a station with no prior Pier and the door promoted the route and sealed both grants')
    // beat 5: readiness rode station_up — NEITHER transport Pier ran a per-Pier handshake, yet the
    //  frames crossed (peer_ready false both ends — a live carrier under an up station was enough).
    if (n === 5 && iRoute && jRoute && w.c.station_up && !this.Peeroleum_peer_ready(iRoute) && !this.Peeroleum_peer_ready(jRoute) && iPier && jPier) this.story_swear(w, 'readiness rode station_up — neither transport Pier ran a handshake yet the frames crossed and sealed')

// SwarmDoor_order — float A:SwarmDoor to the front of H/* so the Run snap stays readable.
async SwarmDoor_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'SwarmDoor') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)

// ══ SwarmGot — the SIXTH Book: IveGotMusic (Radio_todo §9.1c) — the reachable-music tally ══════
//  The front door's PAYOFF: once two stations seal (SwarmDoor's rung) a friendship should COUNT.
//   Each side boasts a tiny collection summary — counts of records|artists, never Records — an
//    additive ive_got frame on the same wire; it lands as %IveGot,by,count facts under MY %Pier
//     for them, and Swarm_ive_got_tally folds my shelf + every live friend into ONE number.
//  Teeth: a SPOOFED boast (a page claiming a prepub never sealed) lands NOTHING — a %rebuff, no
//   fact, no Pier (gossip never opens a door); and a FRESH boast updates the standing fact IN
//    PLACE — one fact per dimension, never a pile.
//   beat 2  Ella (3 records 2 artists) + Fats (2 records 1 artist) stand: stations + a shelf each
//   beat 3  the knock — mint + promote + redeem (SwarmDoor compressed to one beat)
//   beat 4  sealed — and each side boasts its shelf (frames cross on this beat's cascade)
//   beat 5  the facts stand under each Pier; the tally reads five from either end
//   beat 6  the teeth — Fats spoofs a stranger boast at Ella; Ella grows a record and boasts again
//   beat 7  settled — the spoof left a rebuff and nothing else; the fresh boast updated in place
//   beat 8  the revocation — Ella %NotGrants Fats then grows her shelf again and boasts: the gate
//   beat 9  settled — the boast never crossed a revoked Pier; her tally let the friend go (his
//            side still counts the last boast heard — revocation propagation is a later slice)

SwarmGot(A,w):
    w oai %req:wrangle,eternal
        await &SwarmGot_drive,w,req
        req%ok = 1

// SwarmGot_drive — beat dispatch (req-local did_step), then re-sort. No explicit pump: the frames
//  ride the real spine over the mock carriers exactly as SwarmDoor's do.
async SwarmGot_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.SwarmGot_stand(w)
        if (n === 3) await this.SwarmGot_knock(w)
        if (n === 4) await this.SwarmGot_boast(w)
        if (n === 5) await this.SwarmGot_read(w)
        if (n === 6) await this.SwarmGot_teeth(w)
        if (n === 7) await this.SwarmGot_settle(w)
        if (n === 8) await this.SwarmGot_unfriend(w)
        if (n === 9) await this.SwarmGot_quiet(w)
    }
    await this.SwarmGot_order(w)

// SwarmGot_shelf — seed (or grow) a person's OWN music home (Radio_spec §2.2 rung 3): a
//  %MusuSelf,pub:<prepub> / stock shelf — the census convention, a shelf belongs to a KEY, never a
//   nickname. Single-word titles (a comma in a value is a line-codec landmine). Idempotent per Record id.
SwarmGot_shelf(w, ident, rows):
    let lib = this.Ra_home_self(w, ident.sc.prepub)
    for (const row of rows) {
        if (!lib.o({ Record: 1, id: row.id })[0]) lib.i({ Record: 1, id: row.id, title: row.title, artist: row.artist })
    }
    return lib

// beat 2 — the pair stands exactly where SwarmDoor leaves off (persons, bare stations, paired mock
//  carriers, station_up, kinds armed) PLUS a shelf each. Nothing counted yet: no Piers, no facts.
async SwarmGot_stand(w):
    w.sc.now = 1751910000
    let ella = await this.SwarmStaple_person(w, 'Ella')
    let fats = await this.SwarmStaple_person(w, 'Fats')
    let ca = await this.SwarmDoor_station(w, ella)
    let cb = await this.SwarmDoor_station(w, fats)
    ca.partner = cb
    cb.partner = ca
    w.c.station_up = 1
    this.Peeroleum_arm_whittle(w)
    this.Swarm_arm(w)
    this.SwarmGot_shelf(w, ella, [{id: 'e1', title: 'Air', artist: 'Bach'}, {id: 'e2', title: 'Bourree', artist: 'Bach'}, {id: 'e3', title: 'Gymnopedie', artist: 'Satie'}])
    this.SwarmGot_shelf(w, fats, [{id: 'f1', title: 'Naima', artist: 'Coltrane'}, {id: 'f2', title: 'Cousin-Mary', artist: 'Coltrane'}])
    w.doai({req: 'witness', eternal: 1})?.(async (req) => { this.SwarmGot_witness(w); req.sc.ok = 1 })

// beat 3 — the whole door in one beat (SwarmDoor proves its parts separately): mint, promote,
//  redeem. The seal crosses on the post_do cascade — witnessed settled at beat 4.
async SwarmGot_knock(w):
    w.sc.now = 1751910010
    let ella = this.SwarmStaple_ident(w, 'Ella')
    let fats = this.SwarmStaple_ident(w, 'Fats')
    w.c.iz = await this.Swarm_mint_idzeug(w, ella, { Music: 1, genre: 'Jazz' }, 'got_1')
    this.Swarm_station_pier(w, fats, ella.sc.prepub)
    await this.Swarm_redeem(w, fats, w.c.iz)

// beat 4 — sealed; now each side boasts. The ive_got frames cross on this beat's cascade and are
//  read settled at beat 5 (transport frames ride post_do — never witness mid-flight).
async SwarmGot_boast(w):
    w.sc.now = 1751910020
    this.Swarm_gossip_music(w, this.SwarmStaple_ident(w, 'Ella'))
    this.Swarm_gossip_music(w, this.SwarmStaple_ident(w, 'Fats'))

// beat 5 — a reading beat: the witness does the work (facts + tally).
async SwarmGot_read(w):
    w.sc.now = 1751910030

// beat 6 — the teeth. Fats fires a SPOOF: an ive_got whose page claims a prepub Ella never sealed
//  (it rides his REAL route — the wire is honest, the claim is the lie). And Ella's shelf grows a
//   record and she boasts again — the standing fact must update, never duplicate.
async SwarmGot_teeth(w):
    w.sc.now = 1751910040
    let ella = this.SwarmStaple_ident(w, 'Ella')
    let fats = this.SwarmStaple_ident(w, 'Fats')
    let spoof = { kind: 'ive_got', page: { pub: 'not-a-real-pub', prepub: 'c0ffee0000000000', friendly: 'Mallory' }, records: 99, artists: 9 }
    this.Swarm_deliver(w, fats, ella.sc.prepub, spoof)
    this.SwarmGot_shelf(w, ella, [{id: 'e4', title: 'Sarabande', artist: 'Bach'}])
    this.Swarm_gossip_music(w, ella)

// beat 7 — settle: the spoof and the fresh boast are both a beat old.
async SwarmGot_settle(w):
    w.sc.now = 1751910050

// beat 8 — the revocation gate (the probe found it unexercised — now it has teeth): Ella
//  %NotGrants Fats and THEN grows her shelf and boasts again. If the Swarm_pier_live gate holds
//   the boast never leaves — Fats must keep seeing FOUR while she plays five.
async SwarmGot_unfriend(w):
    w.sc.now = 1751910060
    let ella = this.SwarmStaple_ident(w, 'Ella')
    let fats = this.SwarmStaple_ident(w, 'Fats')
    let ePier = this.Swarm_peering(ella)?.o({ Pier: 1, pub: fats.sc.prepub })[0]
    if (ePier) await this.Swarm_revoke(w, ella, ePier, 'Music')
    this.SwarmGot_shelf(w, ella, [{id: 'e5', title: 'Gnossienne', artist: 'Satie'}])
    this.Swarm_gossip_music(w, ella)

// beat 9 — settle: the revoked quiet is a beat old.
async SwarmGot_quiet(w):
    w.sc.now = 1751910070

// ── the witness — per-beat %see observations, n-gated, reading live truth (no commas, no apostrophes) ──
SwarmGot_witness(w):
    let n = (this.c.run)?.c.step_n
    let ella = this.SwarmStaple_ident(w, 'Ella')
    let fats = this.SwarmStaple_ident(w, 'Fats')
    if (!ella || !fats) return
    let cE = this.Swarm_music_census(w, ella)
    let cF = this.Swarm_music_census(w, fats)
    let ePier = this.Swarm_peering(ella)?.o({ Pier: 1, pub: fats.sc.prepub })[0]
    let fPier = this.Swarm_peering(fats)?.o({ Pier: 1, pub: ella.sc.prepub })[0]
    // beat 2: two shelves nobody else can count yet — five records total, no Piers, no facts.
    if (n === 2 && cE.records === 3 && cE.artists === 2 && cF.records === 2 && cF.artists === 1 && !ePier && !fPier && !(oa %see:'each side holds a shelf the other cannot count yet — five records across the two libraries')) i %see:'each side holds a shelf the other cannot count yet — five records across the two libraries'
    // beat 4: the seal stands (grants both ways) — the boasts are in flight this very beat.
    let eGot = ePier?.o({ Grant: 'Music', by: fats.c.keys?.pub })[0]
    let fGot = fPier?.o({ Grant: 'Music', by: ella.c.keys?.pub })[0]
    if (n === 4 && eGot && fGot && !(oa %see:'the door sealed the friendship — now each side may boast its shelf')) i %see:'the door sealed the friendship — now each side may boast its shelf'
    // beat 5: the facts landed under each Pier — my view of THEIR shelf — and the tally folds my
    //  shelf plus every live friend into the same five from either end.
    let eFact = ePier?.o({ IveGot: 1, by: 'records' })[0]
    let fFact = fPier?.o({ IveGot: 1, by: 'records' })[0]
    let tE = this.Swarm_ive_got_tally(w, ella)
    let tF = this.Swarm_ive_got_tally(w, fats)
    if (n === 5 && eFact?.sc?.count === '2' && fFact?.sc?.count === '3' && !(oa %see:'the boasts landed as facts — Ella sees two records at Fats and Fats sees three at Ella')) i %see:'the boasts landed as facts — Ella sees two records at Fats and Fats sees three at Ella'
    if (n === 5 && tE.records === 5 && tF.records === 5 && tE.artists === 3 && tF.artists === 3 && tE.piers === 1 && tF.piers === 1 && !(oa %see:'the tally reads five records reachable from either end — my shelf plus every sealed friend')) i %see:'the tally reads five records reachable from either end — my shelf plus every sealed friend'
    // beat 7: the teeth bit. The spoof left ONLY a rebuff (no fact anywhere says 99, no Pier for
    //  the fake name); the fresh boast updated the standing fact in place (four, still one fact).
    let spoofPier = this.Swarm_peering(ella)?.o({ Pier: 1, pub: 'c0ffee0000000000' })[0]
    let spoofRebuff = ella.o({ rebuff: 'ive_got_stranger' })[0]
    if (n === 7 && spoofRebuff && !spoofPier && eFact?.sc?.count === '2' && !(oa %see:'a spoofed boast from an unsealed name left a rebuff and nothing else — no fact and no door opened')) i %see:'a spoofed boast from an unsealed name left a rebuff and nothing else — no fact and no door opened'
    if (n === 7 && fFact?.sc?.count === '4' && fPier?.o({ IveGot: 1, by: 'records' }).length === 1 && tF.records === 6 && !(oa %see:'a fresh boast updated the standing fact in place — four records now and still a single fact')) i %see:'a fresh boast updated the standing fact in place — four records now and still a single fact'
    // beat 9: the revocation gate held. Ella shelves five yet Fats still sees FOUR (the boast never
    //  crossed a revoked Pier) and her tally let the friend go entirely — while HIS side still
    //   counts the last boast heard (revocation propagation is a later slice — SwarmStaple beat 7).
    let eNot = ePier?.o({ NotGrant: 'Music' })[0]
    if (n === 9 && eNot && cE.records === 5 && fFact?.sc?.count === '4' && tE.records === 5 && tE.piers === 0 && !(oa %see:'a revoked friendship goes quiet — the fresh boast never crossed and the tally lets the friend go')) i %see:'a revoked friendship goes quiet — the fresh boast never crossed and the tally lets the friend go'
    if (n === 9 && eNot && tF.records === 6 && tF.piers === 1 && !(oa %see:'revocation stays one sided for now — the friend still counts the last boast heard')) i %see:'revocation stays one sided for now — the friend still counts the last boast heard'

// SwarmGot_order — float A:SwarmGot to the front of H/* so the Run snap stays readable.
async SwarmGot_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'SwarmGot') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)

// ══ SwarmPolicy — the SEVENTH Book: door policy (Swarm_spec §10.1 no-clock + §6.2 rung 1 legacy) ═════
//  Validity lives with the MAKER: what the door honours is ITS OWN %Idzeug record, checked at
//   hello-time. Two policies get teeth here:
//    no-clock — an invite works INDEFINITELY until its first claim: the compact token carries no
//     time, the door keeps no ttl, and single-use-by-serial is the WHOLE law. No sealed grant ever
//      carries an expiry either — grants are infinite by design (the inverse is a %NotGrant).
//    legacy — the old garden's `#<pad><prepub>-<advice>-<sign>` links parse at the new door
//     (Swarm_legacy_of_url — rung 1, pure): prepub|name|n lifted, granted='ftp' surfaced so nobody
//      transcodes it as Music. NOT verified — the old ledger and key live in the old garden's
//       IndexedDB (`Trust` v2) until the rung-2 migrator; garbage and modern links refuse with
//        null, never a crash.
//   beat 2  Vera + Otto stand on the mail wire — Vera online (the door that answers)
//   beat 3  a fresh invite seals as ever — and no sealed grant carries any expiry
//   beat 4  a second invite waits — no clock on its face
//   beat 5  the clock leaps a hundred seconds — the invite STILL seals and spends
//   beat 6  the relics — the old link parses (fields lifted) and the mangled|modern refuse null

SwarmPolicy(A,w):
    w oai %req:wrangle,eternal
        await &SwarmPolicy_drive,w,req
        req%ok = 1

async SwarmPolicy_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.SwarmPolicy_stand(w)
        if (n === 3) await this.SwarmPolicy_fresh(w)
        if (n === 4) await this.SwarmPolicy_second(w)
        if (n === 5) await this.SwarmPolicy_leap(w)
        if (n === 6) await this.SwarmPolicy_relics(w)
        if (n === 7) await this.SwarmPolicy_relic_redeem(w)
        if (n === 8) await this.SwarmPolicy_relic_teeth(w)
    }
    await this.SwarmStaple_pump(w)
    await this.SwarmPolicy_order(w)

// beat 2 — two selves on the plain mail wire (door policy needs no station): Vera answers her
//  own door, Otto scans. Vera online so hellos land.
async SwarmPolicy_stand(w):
    w.sc.now = 1751920000
    let vera = await this.SwarmStaple_person(w, 'Vera')
    await this.SwarmStaple_person(w, 'Otto')
    this.Swarm_online(vera, true)
    w.doai({req: 'witness', eternal: 1})?.(async (req) => { this.SwarmPolicy_witness(w); req.sc.ok = 1 })

// beat 3 — a fresh invite redeemed at once: the mail wire settles within the beat (the
//  SwarmStaple precedent), so the seal is witnessed this same beat.
async SwarmPolicy_fresh(w):
    w.sc.now = 1751920010
    let vera = this.SwarmStaple_ident(w, 'Vera')
    let otto = this.SwarmStaple_ident(w, 'Otto')
    this.Swarm_online(otto, true)
    let iz = await this.Swarm_mint_idzeug(w, vera, { Music: 1, genre: 'Baroque' }, 'pol_1')
    await this.Swarm_redeem(w, otto, iz)

// beat 4 — the second invite is minted and left waiting: no clock on its face, none anywhere.
async SwarmPolicy_second(w):
    w.sc.now = 1751920020
    let vera = this.SwarmStaple_ident(w, 'Vera')
    w.c.iz2 = await this.Swarm_mint_idzeug(w, vera, { Music: 1, genre: 'Baroque' }, 'pol_2')

// beat 5 — the clock leaps a hundred seconds and Otto redeems the waiting invite: it MUST still
//  seal and spend — a token works indefinitely until its first claim; no clock ever kills a
//   standing welcome (the door that once said deny('expired') no longer exists).
async SwarmPolicy_leap(w):
    w.sc.now = 1751920120
    let otto = this.SwarmStaple_ident(w, 'Otto')
    await this.Swarm_redeem(w, otto, w.c.iz2)

// beat 6 — a reading beat: the witness parses the relics (pure — constants inline there).
async SwarmPolicy_relics(w):
    w.sc.now = 1751920130

// SwarmPolicy_relic_url — mint an OLD GARDEN link the way Tyranny.svelte minted them: the advice
//  signed raw as `<prepub>-<advice>` and truncated to 16, hung off a 13-hash fragment. Signed with
//   the SAME key the door will re-sign with, which is the whole of the old scheme.
async SwarmPolicy_relic_url(w, ident, advice):
    let sign = await this.Swarm_legacy_presig(ident.c.keys, ident.sc.prepub, advice)
    return 'https://jam.example/BigSoundland#############' + ident.sc.prepub + '-' + advice + '-' + sign

// beat 7 — RUNG 2: an old garden link is REDEEMED, not merely read. Vera stands in for the migrated
//  garden — one %Idzeug issuer whose `next` sits above the old high water, which is exactly what the
//   real migration wrote — so every number the old garden ever signed resolves as an ordinary serial
//    and needs no legacy ledger at all. Pia holds a relic and it seals through the SAME door as a QR.
async SwarmPolicy_relic_redeem(w):
    w.sc.now = 1751920140
    let vera = this.SwarmStaple_ident(w, 'Vera')
    let pia = await this.SwarmStaple_person(w, 'Pia')
    this.Swarm_online(pia, true)
    let iz = this.Swarm_iz_issuer(vera, { Music: 1 })
    this.Swarm_iz_mark(vera, iz, { next: '50' })
    w.c.relic = this.Swarm_legacy_of_url(await this.SwarmPolicy_relic_url(w, vera, 'garden.n~7'))
    await this.Swarm_redeem(w, pia, this.Swarm_legacy_token(w.c.relic), w.c.relic.advice)

// beat 8 — the two teeth. A REPLAY of the same relic is refused because its number is claimed; and
//  the SERIAL SWAP — the same advice and the same genuine signature offered beside a DIFFERENT
//   number — is refused as forged. The second tooth is the one that matters: without the door
//    binding advice.n to the carried serial, ONE real old link would let its holder tick off every
//     unclaimed number in the issuer's space, and single-use would mean nothing for the whole era.
async SwarmPolicy_relic_teeth(w):
    w.sc.now = 1751920150
    let quin = await this.SwarmStaple_person(w, 'Quin')
    this.Swarm_online(quin, true)
    let relic = w.c.relic
    await this.Swarm_redeem(w, quin, this.Swarm_legacy_token(relic), relic.advice)
    await this.Swarm_redeem(w, quin, this.Swarm_token(relic.prepub, '9', 'Music', relic.sign), relic.advice)

// ── the witness — per-beat %see observations, n-gated, reading live truth (no commas, no apostrophes) ──
SwarmPolicy_witness(w):
    let n = (this.c.run)?.c.step_n
    let vera = this.SwarmStaple_ident(w, 'Vera')
    let otto = this.SwarmStaple_ident(w, 'Otto')
    if (!vera || !otto) return
    let vPier = this.Swarm_peering(vera)?.o({ Pier: 1, pub: otto.sc.prepub })[0]
    let oPier = this.Swarm_peering(otto)?.o({ Pier: 1, pub: vera.sc.prepub })[0]
    // beat 3: the fresh invite sealed — and no sealed grant carries any expiry field (grants are
    //  infinite; invite validity is the serial, never a clock). Vera holding OTTO's grant is the
    //   pier_confirm receipt — the deferred reciprocal crossed.
    let vGot = vPier?.o({ Grant: 'Music', by: otto.c.keys?.pub })[0]
    let ttlLeak = vPier?.o({ Grant: 1, ttl: 1 })[0] ?? oPier?.o({ Grant: 1, ttl: 1 })[0]
    if (n === 3 && vGot && oPier && !ttlLeak && !(oa %see:'a fresh invite seals as ever — and no sealed grant carries any expiry')) i %see:'a fresh invite seals as ever — and no sealed grant carries any expiry'
    // beat 4: the second invite waits with NO clock on its face.
    let rec2 = this.Swarm_peering(vera)?.o({ Idzeug: 'pol_2' })[0]
    if (n === 4 && rec2 && !rec2.sc.ttl && !rec2.sc.spent && !(oa %see:'a second invite waits — no clock on its face')) i %see:'a second invite waits — no clock on its face'
    // beat 5: the leap changed nothing — a hundred seconds on and the invite still sealed and
    //  spent: infinite-until-first-claim IS the policy.
    if (n === 5 && rec2 && rec2.sc.spent && !(oa %see:'the clock never kills an invite — a hundred seconds later it still seals and spends')) i %see:'the clock never kills an invite — a hundred seconds later it still seals and spends'
    // beat 6: the relics. The old garden link parses — prepub|name|n lifted, granted=ftp surfaced —
    //  while garbage and a modern ?Iz= link refuse with null.
    let relic = this.Swarm_legacy_of_url('https://jam.example/BigSoundland#############a1b2c3d4e5f60718-Elder+Gardener.n~7-deadbeefdeadbeef')
    let relicOk = relic && relic.prepub === 'a1b2c3d4e5f60718' && relic.friendly === 'Elder Gardener' && relic.n === 7 && relic.granted === 'ftp' && relic.legacy === 1
    if (n === 6 && relicOk && !(oa %see:'the old garden link parses at the new door — prepub and name and count lifted from the fragment')) i %see:'the old garden link parses at the new door — prepub and name and count lifted from the fragment'
    let dead = !this.Swarm_legacy_of_url('https://jam.example/BigSoundland#garbage') && !this.Swarm_legacy_of_url('https://jam.example/BigSoundland?Iz=abcdef') && !this.Swarm_legacy_of_url(null) && !this.Swarm_legacy_of_url('https://jam.example/#############nothexadecimal-Name.n~1-signsignsignsign')
    if (n === 6 && dead && !(oa %see:'a mangled relic and a modern link both refuse cleanly — null never a crash')) i %see:'a mangled relic and a modern link both refuse cleanly — null never a crash'
    // beat 7: rung 2 — the old link SEALS. Both halves of the friendship, and the number ticked off
    //  the migrated issuer, which is the ledger entry that makes it single-use from here on.
    let iz1 = this.Swarm_peering(vera)?.o({ Idzeug: '1', next: 1 })[0]
    let pia = this.SwarmStaple_ident(w, 'Pia')
    let pVera = pia && this.Swarm_peering(pia)?.o({ Pier: 1, pub: vera.sc.prepub })[0]
    let vPia = pia && this.Swarm_peering(vera)?.o({ Pier: 1, pub: pia.sc.prepub })[0]
    let took7 = this.Swarm_claimed_has(iz1?.sc?.claimed, 7)
    if (n === 7 && pVera && vPia && took7 && !(oa %see:'an old garden link seals a real friendship at the new door — its number ticks off the migrated issuer')) i %see:'an old garden link seals a real friendship at the new door — its number ticks off the migrated issuer'
    // beat 8: the teeth. Quin gets nothing from either attempt, and number 9 — the one the swap
    //  aimed at with a genuine signature for number 7 — is still unclaimed.
    let quin = this.SwarmStaple_ident(w, 'Quin')
    let noQuin = quin && !(this.Swarm_peering(vera)?.o({ Pier: 1, pub: quin.sc.prepub }).length)
    if (n === 8 && noQuin && took7 && !this.Swarm_claimed_has(iz1?.sc?.claimed, 9) && !(oa %see:'a relic cannot be torn twice nor re-aimed at another number — the replay and the serial swap both seal nothing')) i %see:'a relic cannot be torn twice nor re-aimed at another number — the replay and the serial swap both seal nothing'

// SwarmPolicy_order — float A:SwarmPolicy to the front of H/* so the Run snap stays readable.
async SwarmPolicy_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'SwarmPolicy') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)


// ══ SwarmShare — the EIGHTH Book: live-share keying + suggestion store-and-forward + rebirth reset ══════
//  This week's machinery on the Book wire (Swarm_spec §9 share/suggest + Repli §2.2 per-friend homes):
//   1) the per-friend MIRROR KEYING — Repli's opt-in repli_mirror_by_from/repli_mirror_w key what I hold
//    OF a friend under %MusuThem,pub:<THEM> (the caster) instead of one merged pile under my own key;
//   2) the SUGGESTION as store-and-forward — a %Suggest minted while the friend is unreachable stands
//    un-got under my Pier for them, and their rebirth greeting (swarm_hi) drains the queue when they
//     surface, the far side mirroring it and confirming with suggest_got (my copy wears got:1);
//   3) the REBIRTH RESET — a CHANGED station era in the greeting is the restart signal, so Swarm_heard_hi
//    resets the route's stream state (Peeroleum_reset_handshake: inbox/outbox/protocol gone, %Ud kept)
//     and re-baselines peer_era, dodging the seq-reset epoch a cold re-dial would force.
//  DISCIPLINE (the brief's warnings): NEVER Swarm_share_up (it starts a wall-clock setTimeout loop — a
//   Book must never), NEVER touch top_House().c.radio_w (the live tab's state), and NEVER set
//    w.c.station_up (it engages the voucher gate — the mechanics test cleanly with it off; the LIVE
//     two-tab join is that gate's proof, un-Bookable here).  TWO pairs so each concern stays isolated:
//      Cass→Deb carry the mirror (a station link, peer_ready, Repli armed); Alice+Bob carry the
//       suggestion (sealed over the MAIL wire, no station until Bob surfaces at beat 6 — so beat 5's
//        offline suggest genuinely has no route) and the rebirth.  Own world w:SwarmShare (dispatch by
//         world name — the usual bomb); seeded keys, pinned clock.
//   beat 2  the two pairs stand — Cass/Deb linked+handshaked+Repli-armed with Cass's shelf; Alice+Bob sealed
//   beat 3  Cass offers her two records with the per-friend keying flags set
//   beat 4  settle — the mirror landed keyed by Cass not merged under Deb
//   beat 5  Alice suggests a track to Bob while he is offline — it stands un-got under her Pier for him
//   beat 6  Bob surfaces — the transport link stands and its handshake seeds (holds until ready)
//   beat 7  the greeting arrives — Swarm_heard_hi drains the queue; the suggest crosses and confirms
//   beat 8  settle — Bob holds the mirrored suggestion and Alice's copy wears got
//   beat 9  Bob restarts — a changed era resets the route stream state while keeping %Ud

SwarmShare(A,w):
    w oai %req:wrangle,eternal
        await &SwarmShare_drive,w,req
        req%ok = 1

// SwarmShare_drive — beat dispatch (req-local did_step), then the per-pass tail: drain every account's
//  mail (SwarmStaple_pump — the seal wire) AND pump every station's handshake reqs (Lake_pump_handshakes —
//   generic over w's station %Peerings) and re-sort. Beats 4 and 8 arm nothing — the witness reads them settled.
async SwarmShare_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.SwarmShare_stand(w)
        if (n === 3) await this.SwarmShare_mirror(w)
        if (n === 5) await this.SwarmShare_suggest_offline(w)
        if (n === 6) await this.SwarmShare_arrive_link(w)
        if (n === 7) await this.SwarmShare_arrive_hi(w)
        if (n === 9) await this.SwarmShare_rebirth(w)
    }
    await this.SwarmStaple_pump(w)
    await this.Lake_pump_handshakes(w)
    await this.SwarmShare_order(w)

// beat 2 — the two pairs. Cass/Deb: a station link between their prepubs, the swarm+Repli kinds armed, the
//  caster's shelf registered, and the per-Pier handshake seeded (holds until %Ud both ends). Alice/Bob:
//   two fixed selves sealed as friends over the MAIL wire (both online, mint+redeem), no station yet — their
//    transport link stands only when Bob surfaces at beat 6, so beat 5's suggest has genuinely no route.
async SwarmShare_stand(w):
    w i reached:step_2
    w.sc.now = 1751940000
    let cass = await this.SwarmStaple_person(w, 'Cass')
    let deb = await this.SwarmStaple_person(w, 'Deb')
    let lc = await this.Lake_link(w, cass.sc.prepub, deb.sc.prepub)
    w.c.cass_tx = lc[0]
    w.c.deb_rx = lc[1]
    this.Swarm_arm(w)
    this.Repli_arm(w)
    let clib = this.Ra_home_self(w, cass.sc.prepub)
    clib.i({ Record: 1, id: 'c1', title: 'Take-Five', artist: 'Brubeck' })
    clib.i({ Record: 1, id: 'c2', title: 'So-What', artist: 'Davis' })
    this.Repli_register_caster(w, lc[0], clib)
    this.Repli_register_rx(w, lc[1])
    let alice = await this.SwarmStaple_person(w, 'Alice')
    let bob = await this.SwarmStaple_person(w, 'Bob')
    this.Swarm_online(alice, true)
    this.Swarm_online(bob, true)
    w.c.iz_ab = await this.Swarm_mint_idzeug(w, alice, { Music: 1, genre: 'Jazz' }, 'share_ab')
    await this.Swarm_redeem(w, bob, w.c.iz_ab)
    // seed the mirror pair's handshake (only Cass/Deb have a station Peering yet; the seed is generic over w's).
    for (const peering of w.o({ Peering: 1 })) {
        for (const pier of peering.o({ Pier: 1 })) pier.oai({ req: 'handshake' })
    }
    w.doai({ req: 'witness', eternal: 1 })?.(async (req) => { this.SwarmShare_witness(w); req.sc.ok = 1 })

// beat 3 — the per-friend keying (the new opt-in): key the mirror shelf by the frame SENDER and mint the
//  homes in THIS world, then Cass offers her two records. What I hold OF Cass lands under %MusuThem,pub:<Cass>,
//   not merged under my own listener key (the old default).
async SwarmShare_mirror(w):
    w i reached:step_3
    w.sc.now = 1751940010
    let cass = this.SwarmStaple_ident(w, 'Cass')
    let deb = this.SwarmStaple_ident(w, 'Deb')
    w.c.repli_mirror_by_from = 1
    w.c.repli_mirror_w = w
    let clib = this.Ra_home_self(w, cass.sc.prepub)
    for (const rec of clib.o({ Record: 1 })) await this.Repli_offer(w, w.c.cass_tx, cass.sc.prepub, deb.sc.prepub, rec)

// beat 5 — Alice suggests a track to Bob while he is unreachable: Bob offline + no station route, so
//  Swarm_deliver fails and the %Suggest stands un-got under Alice's Pier for him (store-and-forward).
async SwarmShare_suggest_offline(w):
    w i reached:step_5
    w.sc.now = 1751940030
    let alice = this.SwarmStaple_ident(w, 'Alice')
    let bob = this.SwarmStaple_ident(w, 'Bob')
    this.Swarm_online(bob, false)
    let alib = this.Ra_home_self(w, alice.sc.prepub)
    let arec = alib.o({ Record: 1, id: 'a1' })[0] || alib.i({ Record: 1, id: 'a1', title: 'Ruby', artist: 'Navarro' })
    this.Swarm_suggest(w, alice, bob.sc.prepub, arec, 'for a late night')

// beat 6 — Bob's tab comes up: stand the transport link between the two prepubs and seed the per-Pier
//  handshake (holds until peer_ready + %Ud both ends) so the greeting at beat 7 has a live ready route.
async SwarmShare_arrive_link(w):
    w i reached:step_6
    w.sc.now = 1751940040
    let alice = this.SwarmStaple_ident(w, 'Alice')
    let bob = this.SwarmStaple_ident(w, 'Bob')
    let lab = await this.Lake_link(w, alice.sc.prepub, bob.sc.prepub)
    w.c.alice_route = lab[0]
    w.c.bob_route = lab[1]
    for (const pier of [lab[0], lab[1]]) pier.oai({ req: 'handshake' })

// beat 7 — the greeting arrives: feed Alice a swarm_hi from Bob (a reply so no boast rides along). The
//  funnel's voucher gate is off (station_up unset), so Swarm_heard_hi answers by re-offering every un-got
//   suggestion over the now-ready route — the suggest crosses to Bob (mirrored under his Pier) and his
//    suggest_got confirms back, all on the post_do cascade witnessed settled at beat 8.
async SwarmShare_arrive_hi(w):
    w i reached:step_7
    w.sc.now = 1751940050
    let alice = this.SwarmStaple_ident(w, 'Alice')
    let bob = this.SwarmStaple_ident(w, 'Bob')
    let frame = { header: { type: 'swarm_hi', from: bob.sc.prepub, to: alice.sc.prepub, seq: 1 }, swarm: { kind: 'swarm_hi', era: 100, reply: 1, page: this.Swarm_page(bob) } }
    this.Swarm_heard_hi(w, alice, frame)

// beat 9 — Bob restarts: stamp a prior era on Alice's route for him, then feed a hi carrying a CHANGED era.
//  The changed era is the restart signal — Swarm_heard_hi resets the route stream state (Peeroleum_reset_
//   handshake: inbox/outbox/protocol gone, %Ud kept) and re-baselines peer_era, dodging a seq-reset epoch.
async SwarmShare_rebirth(w):
    w i reached:step_9
    w.sc.now = 1751940070
    let alice = this.SwarmStaple_ident(w, 'Alice')
    let bob = this.SwarmStaple_ident(w, 'Bob')
    let route = w.c.alice_route
    if (!route) return
    route.c.peer_era = 111
    let frame = { header: { type: 'swarm_hi', from: bob.sc.prepub, to: alice.sc.prepub, seq: 2 }, swarm: { kind: 'swarm_hi', era: 222, reply: 1, page: this.Swarm_page(bob) } }
    this.Swarm_heard_hi(w, alice, frame)

// ── the witness — sworn assertions via this.story_swear (the current regime; %see is extinct). Each is
//  n-gated to the beat its truth is observable (the un-got suggest reads true only at beat 5 before the
//   drain flips it got at beat 8 — the SwarmWire n-gate pattern), then latched for the run. Evidence rides
//    the off-snap ave/%Assertioning shelf; a declared contract is a toc step=N/%Assertion (declare via CLI).
SwarmShare_witness(w):
    let n = (this.c.run)?.c.step_n
    let cass = this.SwarmStaple_ident(w, 'Cass')
    let deb = this.SwarmStaple_ident(w, 'Deb')
    let alice = this.SwarmStaple_ident(w, 'Alice')
    let bob = this.SwarmStaple_ident(w, 'Bob')
    if (!cass || !deb || !alice || !bob) return
    // beat 4: the mirror landed keyed by the CASTER prepub — Cass's two records under my %MusuThem,pub:<Cass>
    //  crate, NEVER merged under the listener key (the per-friend keying the opt-in flags switched on).
    let cassMir = w.o({ MusuThem: 1, pub: cass.sc.prepub })[0]?.o({ stock: 1 })[0]
    let debMir = w.o({ MusuThem: 1, pub: deb.sc.prepub })[0]
    if (n === 4 && cassMir && cassMir.o({ Record: 1 }).length === 2 && !debMir) this.story_swear(w, 'the mirror lands keyed by the caster prepub — two records under MusuThem for the friend never merged under the listener key')
    // OWED (attended — pairs with the Repli.g `c.sc.from` stamp): add a beat-4 swear that each mirrored
    //  record wears its source prepub as a SNAPPABLE from (query `{ Record:1, from:cass.sc.prepub }`),
    //   then re-record + declare.  Held with the Repli line so SwarmShare's fixtures move exactly once.
    // beat 5: a suggestion minted while the friend is unreachable stands un-got under my Pier for them — the
    //  store-and-forward promise. Nothing crossed — no mirrored suggestion at Bob yet.
    let aPier = this.Swarm_peering(alice)?.o({ Pier: 1, pub: bob.sc.prepub })[0]
    let bPier = this.Swarm_peering(bob)?.o({ Pier: 1, pub: alice.sc.prepub })[0]
    let aSug = aPier?.o({ Suggest: 1, by: alice.sc.prepub })[0]
    if (n === 5 && aSug && aSug.sc.id === 'a1' && !aSug.sc.got && !bPier?.o({ Suggest: 1 }).length) this.story_swear(w, 'a suggestion minted while the friend is unreachable stands un-got under my Pier for them — store and forward')
    // beat 8: the friend surfaced and the greeting drained the queue — the suggestion crossed (mirrored under
    //  his Pier for me) and his suggest_got retired my copy (got now set).
    let bMirSug = bPier?.o({ Suggest: 1, by: alice.sc.prepub, id: 'a1' })[0]
    if (n === 8 && bMirSug && aSug?.sc?.got) this.story_swear(w, 'the rebirth greeting drains the queue — the suggestion crosses mirrored at the friend and his confirmation retires my copy got')
    // beat 9: a changed era in the greeting is the restart signal — the route stream state was reset (inbox
    //  and outbox gone) while %Ud was kept and peer_era re-baselined to the new era.
    let route = w.c.alice_route
    if (n === 9 && route && !route.oa({ inbox: 1 }) && !route.oa({ outbox: 1 }) && route.oa({ Ud: 1 }) && route.c.peer_era === 222) this.story_swear(w, 'a changed era in the greeting resets the route stream state while keeping Ud — the reborn peer re-baselines the link')

// SwarmShare_order — float A:SwarmShare to the front of H/* so the Run snap stays readable.
async SwarmShare_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'SwarmShare') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)


// ══ SwarmChain — the NINTH Book: the re-assignable ReInvite chain (Swarm_spec §6.3a) ═══════════════
//  SwarmStaple proves a SINGLE-USE invite; SwarmChain proves the RE-ASSIGNABLE one — an admission
//   ticket that threads a chain of friendships A—B—C—D. The issuer (Dee) tracks only the current
//    TIP; each newcomer befriends whoever brought them in, NEVER the issuer, capped at the embedded
//     Feature (no escalation). The airtight core: a ReInvite EMBEDS Dee's original invite, so both
//      the tip and the newcomer verify the SAME Dee signature; the TIP (not Dee) signs the grant;
//       Dee advances her tracker only on the tip's SIGNED confirmation. Mail wire, in-process, four
//        fixed selves; its own world w:SwarmChain (dispatch by WORLD NAME — the usual bomb).
//   beat 2  four selves stand up ONLINE — an issuer (Dee) a first tip (Eli) two newcomers (Fay Gus)
//   beat 3  Dee mints a CHAIN invite; Eli redeems — A—B seals and the tip is TRACKED not spent
//   beat 4  Fay (holding Eli's link) redeems — ReInvite → Eli honours + grants + seals B—C; tip → Fay
//   beat 5  Gus (holding Fay's link) redeems — Fay honours via her kept ChainRoot; C—D seals; tip → Gus

SwarmChain(A,w):
    w oai %req:wrangle,eternal
        await &SwarmChain_drive,w,req
        req%ok = 1

// SwarmChain_drive — beat dispatch (req-local did_step, the Pere* lesson), then pump the mail wire
//  and re-sort H/* every pass. Separate guarded ifs sidestep the bare-else tile mangle.
async SwarmChain_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.SwarmChain_sides_up(w)
        if (n === 3) await this.SwarmChain_root(w)
        if (n === 4) await this.SwarmChain_grow(w)
        if (n === 5) await this.SwarmChain_grow2(w)
    }
    await this.SwarmChain_pump(w)
    await this.SwarmChain_order(w)

// SwarmChain_pump — DRAIN the mail wire to a fixed point each pass. The chain is ~6 frames end to end
//  (hello → reinvite → reinvite → honour → seal → ok); the 2-frame hello|accept drains over a beat's
//   think passes, but a 6-hop chain would settle only across SEVERAL beats (frames ride post-do — the
//    memory), leaving the witness reading a half-settled world. So we loop the per-account pump until
//     no undone frame remains (bounded — never an unbounded await in a beat, the Sounditron lesson):
//      the whole chain completes within the beat that redeems, and the sworn truths hold at that beat.
async SwarmChain_pump(w):
    let guard = 0
    while (guard < 24) {
        guard = guard + 1
        for (const acct of w.o({ Account: 1 })) {
            for (const ident of acct.o({ Identity: 1 })) await this.Swarm_pump(w, ident)
        }
        let pending = 0
        for (const acct of w.o({ Account: 1 })) {
            for (const ident of acct.o({ Identity: 1 })) {
                let inbox = ident.o({ mail: 1 })[0]
                if (inbox) pending = pending + inbox.o({ frame: 1 }).filter(m => !m.sc.did).length
            }
        }
        if (pending === 0) break
    }

// SwarmChain_person — a fixed self seeded off the name (its own of: tag never collides with a staple
//  self in another world); brought ONLINE at once — the chain needs everyone reachable to relay.
async SwarmChain_person(w, name):
    let acct = w.oai({ Account: 1, of: name })
    acct.c.up = w
    let keys = await this.Swarm_mint_keys('SwarmChain-' + name)
    let ident = this.Swarm_identity(acct, keys, name)
    this.Swarm_online(ident, true)
    return ident

SwarmChain_ident(w, name):
    return w.o({ Account: 1, of: name })[0]?.o({ Identity: 1 })[0]

// beat 2 — the cast: four selves, all online. Witness armed last (own swept req) so it reads each
//  pass's settled state.
async SwarmChain_sides_up(w):
    w i reached:step_2
    w.sc.now = 1751700000
    await this.SwarmChain_person(w, 'Dee')
    await this.SwarmChain_person(w, 'Eli')
    await this.SwarmChain_person(w, 'Fay')
    await this.SwarmChain_person(w, 'Gus')
    w.doai({req: 'witness', eternal: 1})?.(async (req) => { this.SwarmChain_witness(w); req.sc.ok = 1 })

// beat 3 — the chain root: Dee mints a CHAIN invite (chain:1 → tracks a holder, never spends) and
//  Eli redeems it. A—B seals like any friendship, and Dee records Eli as the tip the chain grows from.
async SwarmChain_root(w):
    w i reached:step_3
    w.sc.now = 1751700010
    let dee = this.SwarmChain_ident(w, 'Dee')
    w.c.iz = await this.Swarm_mint_idzeug(w, dee, { Music: 1, genre: 'Classical' }, 'chain_1', 1)
    await this.Swarm_redeem(w, this.SwarmChain_ident(w, 'Eli'), w.c.iz)

// beat 4 — the chain grows by one: Fay holds the SAME link (Eli passed it out of band) and redeems
//  it. Dee — hearing a NON-holder — mints a single-use ReInvite naming Eli (tip) + Fay (newcomer);
//   Fay carries it to Eli; ELI (not Dee) verifies Dee's signature grants Fay the capped Music and
//    seals B—C; Eli's signed confirmation lets Dee advance her tracker Eli→Fay. Fay never befriends
//     Dee — she keeps only a light ChainRoot for later.
async SwarmChain_grow(w):
    w i reached:step_4
    w.sc.now = 1751700020
    await this.Swarm_redeem(w, this.SwarmChain_ident(w, 'Fay'), w.c.iz)

// beat 5 — the chain grows PAST the first tip: Gus holds the link (Fay passed it) and redeems. Dee
//  mints a ReInvite naming Fay (the NEW tip); Gus carries it to Fay; Fay honours it via the ChainRoot
//   she kept when she joined — NOT a friendship with Dee — grants Gus and seals C—D. The tracker
//    advances again Fay→Gus: the proof the chain outlives any single friendship with the issuer.
async SwarmChain_grow2(w):
    w i reached:step_5
    w.sc.now = 1751700030
    await this.Swarm_redeem(w, this.SwarmChain_ident(w, 'Gus'), w.c.iz)

// SwarmChain_witness — %sworn assertions via this.story_swear (idempotent per run; evidence on the
//  Assertioning shelf, never snap bytes). Each is a happened-FACT of the chain: the tracked tip, the
//   tip-not-issuer grant, the non-befriending newcomer, the tracker advance, the ChainRoot hop, the
//    no-escalation cap. Gated to the beat the truth first holds; the sworn then carries it for the run.
SwarmChain_witness(w):
    let n = (this.c.run)?.c.step_n
    let dee = this.SwarmChain_ident(w, 'Dee')
    let eli = this.SwarmChain_ident(w, 'Eli')
    let fay = this.SwarmChain_ident(w, 'Fay')
    let gus = this.SwarmChain_ident(w, 'Gus')
    if (!dee || !eli || !fay || !gus) return
    // beat 2: four online selves.
    if (n === 2 && [dee, eli, fay, gus].every(i => this.Swarm_peering(i)?.sc?.online)) this.story_swear(w, 'four selves stand up online — an issuer a first tip and two newcomers waiting to chain in')
    let rec = this.Swarm_peering(dee)?.o({ Idzeug: 'chain_1' })[0]
    let deeEli = this.Swarm_peering(dee)?.o({ Pier: 1, pub: eli.sc.prepub })[0]
    let eliDee = this.Swarm_peering(eli)?.o({ Pier: 1, pub: dee.sc.prepub })[0]
    // beat 3: the chain root — a chain invite (not spent) tracking Eli as the tip; A—B a real friendship.
    if (n === 3 && rec && rec.sc.chain && !rec.sc.spent && rec.sc.holder === eli.sc.prepub && deeEli && eliDee) this.story_swear(w, 'the chain invite seals its first friend and tracks him as the tip — never spent so the link can move on')
    // beat 4: B—C sealed by the TIP (mutual Music) — Eli granted Fay and Fay reciprocated.
    let fayGetsEli = this.Swarm_peering(fay)?.o({ Pier: 1, pub: eli.sc.prepub })[0]?.o({ Grant: 'Music', by: eli.c.keys?.pub })[0]
    let eliGetsFay = this.Swarm_peering(eli)?.o({ Pier: 1, pub: fay.sc.prepub })[0]?.o({ Grant: 'Music', by: fay.c.keys?.pub })[0]
    if (n === 4 && fayGetsEli && eliGetsFay) this.story_swear(w, 'a newcomer holding the link grows the chain — the TIP not the issuer grants her and seals a real friendship')
    // beat 4: the newcomer never befriends the issuer — no Pier at either end — only a light ChainRoot.
    let fayNotDee = !this.Swarm_peering(fay)?.o({ Pier: 1, pub: dee.sc.prepub }).length
    let deeNotFay = !this.Swarm_peering(dee)?.o({ Pier: 1, pub: fay.sc.prepub }).length
    let fayRoot = fay.o({ ChainRoot: 1, pub: dee.c.keys?.pub })[0]
    if (n === 4 && fayNotDee && deeNotFay && fayRoot) this.story_swear(w, 'the newcomer never befriends the issuer — no grant and no contact only a light chain-root kept for later')
    // beat 4: the tracker advanced Eli→Fay on the tip's signed confirmation.
    if (n === 4 && rec && rec.sc.holder === fay.sc.prepub) this.story_swear(w, 'the issuer advances her tracker to the newcomer on the tip signed confirmation')
    // beat 5: the chain grows PAST the first tip — Fay honoured Gus via the ChainRoot she kept, not a friendship with Dee.
    let gusGetsFay = this.Swarm_peering(gus)?.o({ Pier: 1, pub: fay.sc.prepub })[0]?.o({ Grant: 'Music', by: fay.c.keys?.pub })[0]
    let fayGetsGus = this.Swarm_peering(fay)?.o({ Pier: 1, pub: gus.sc.prepub })[0]?.o({ Grant: 'Music', by: gus.c.keys?.pub })[0]
    if (n === 5 && gusGetsFay && fayGetsGus && fayNotDee) this.story_swear(w, 'the chain grows PAST the first tip — the newcomer honours via the chain-root she kept not a friendship with the issuer')
    // beat 5: no escalation — the far hop's grant is still exactly the embedded Music Feature.
    if (n === 5 && gusGetsFay && gusGetsFay.sc.Grant === 'Music') this.story_swear(w, 'no escalation down the chain — the far hop still grants exactly the embedded Music Feature')
    // beat 5: the tracker advanced again Fay→Gus.
    if (n === 5 && rec && rec.sc.holder === gus.sc.prepub) this.story_swear(w, 'the tracker advances again to the second newcomer — the chain outlives any single friendship with the issuer')

// SwarmChain_order — float A:SwarmChain to the front of H/* so the Run snap stays readable.
async SwarmChain_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'SwarmChain') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)

// ══ SwarmBlotter — the TENTH Book: the one-time serial SHEET (Swarm_spec §6.2) ═══════════════════
//  The counterpart to SwarmChain. SwarmChain proves the RE-ASSIGNABLE invite (the SHARE QR — one
//   link threads a chain, tracking a moving tip). SwarmBlotter proves the OTHER kind: a printed
//    BLOTTER of numbered tickets, each a plain ONE-TIMER. The two invite kinds part at the mint —
//     a chain wears its own record because its holder MOVES, while a blotter is a RANGE MINT that
//      records no group at all: wind the issuer's number past three and three tokens wander off.
//       Each still spends through the exact single-use door: torn once, its number ticked off
//        `claimed`, a replay refused. The legacy ###### link is the same species (a one-timer,
//         granting the old ftp atom — never a Feature), so this Book pins its door-parse too.
//          Mail wire, in-process, five fixed selves; own world.
//   beat 2  five selves online — a sheet issuer (Host) three serial claimants (Uno Dos Tres) a replayer (Qua)
//   beat 3  Host winds THREE numbers off one issuer; Uno tears serial 1 — a friendship seals ticking only it
//   beat 4  Dos tears 2 and Tres tears 3 — three independent friendships and one unbroken claimed run
//   beat 5  Qua replays Uno's claimed number — REFUSED no friendship; and the legacy link still parses at the door

SwarmBlotter(A,w):
    w oai %req:wrangle,eternal
        await &SwarmBlotter_drive,w,req
        req%ok = 1

// SwarmBlotter_drive — beat dispatch (req-local did_step), then drain the mail wire and re-sort H/*.
async SwarmBlotter_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.SwarmBlotter_sides_up(w)
        if (n === 3) await this.SwarmBlotter_sheet(w)
        if (n === 4) await this.SwarmBlotter_claims(w)
        if (n === 5) await this.SwarmBlotter_replay(w)
    }
    await this.SwarmBlotter_pump(w)
    await this.SwarmBlotter_order(w)

// SwarmBlotter_pump — DRAIN the mail wire to a fixed point each pass (the SwarmChain lesson): a claim
//  is hello→accept (2 frames), a refused replay hello→reject (2 frames); bound the loop so every
//   exchange settles within the beat that fires it, never an unbounded await in a beat.
async SwarmBlotter_pump(w):
    let guard = 0
    while (guard < 24) {
        guard = guard + 1
        for (const acct of w.o({ Account: 1 })) {
            for (const ident of acct.o({ Identity: 1 })) await this.Swarm_pump(w, ident)
        }
        let pending = 0
        for (const acct of w.o({ Account: 1 })) {
            for (const ident of acct.o({ Identity: 1 })) {
                let inbox = ident.o({ mail: 1 })[0]
                if (inbox) pending = pending + inbox.o({ frame: 1 }).filter(m => !m.sc.did).length
            }
        }
        if (pending === 0) break
    }

// SwarmBlotter_person — a fixed self seeded off the name (its own of: tag), brought ONLINE at once.
async SwarmBlotter_person(w, name):
    let acct = w.oai({ Account: 1, of: name })
    acct.c.up = w
    let keys = await this.Swarm_mint_keys('SwarmBlotter-' + name)
    let ident = this.Swarm_identity(acct, keys, name)
    this.Swarm_online(ident, true)
    return ident

SwarmBlotter_ident(w, name):
    return w.o({ Account: 1, of: name })[0]?.o({ Identity: 1 })[0]

// beat 2 — the cast: five selves, all online. Witness armed last (own swept req) so it reads each
//  pass's settled state.
async SwarmBlotter_sides_up(w):
    w i reached:step_2
    w.sc.now = 1751800000
    await this.SwarmBlotter_person(w, 'Host')
    await this.SwarmBlotter_person(w, 'Uno')
    await this.SwarmBlotter_person(w, 'Dos')
    await this.SwarmBlotter_person(w, 'Tres')
    await this.SwarmBlotter_person(w, 'Qua')
    w.doai({req: 'witness', eternal: 1})?.(async (req) => { this.SwarmBlotter_witness(w); req.sc.ok = 1 })

// beat 3 — the sheet: Host prints a blotter of THREE serials off one Feature (each plain single-use,
//  never chain), and Uno tears serial 1. A—B seals like any friendship; the OTHER two serials on the
//   sheet stay unclaimed — a torn ticket spends only itself.
async SwarmBlotter_sheet(w):
    w i reached:step_3
    w.sc.now = 1751800010
    let host = this.SwarmBlotter_ident(w, 'Host')
    w.c.sheet = await this.Swarm_mint_blotter(w, host, { Music: 1, genre: 'Jazz' }, 3)
    await this.Swarm_redeem(w, this.SwarmBlotter_ident(w, 'Uno'), w.c.sheet[0])

// beat 4 — the sheet fills: Dos tears serial 2 and Tres serial 3. Each serial admits its OWN claimant
//  through its own single-use door — three independent friendships, and the whole sheet reads claimed.
async SwarmBlotter_claims(w):
    w i reached:step_4
    w.sc.now = 1751800020
    await this.Swarm_redeem(w, this.SwarmBlotter_ident(w, 'Dos'), w.c.sheet[1])
    await this.Swarm_redeem(w, this.SwarmBlotter_ident(w, 'Tres'), w.c.sheet[2])

// beat 5 — the one-timer bites: Qua replays serial 1 (the very ticket Uno already tore). The door
//  finds it spent and REFUSES — Qua seals no friendship and the sheet's claimed count never moves.
//   And the legacy garden link still parses at the door — the old ###### shape, granting ftp not Music.
async SwarmBlotter_replay(w):
    w i reached:step_5
    w.sc.now = 1751800030
    await this.Swarm_redeem(w, this.SwarmBlotter_ident(w, 'Qua'), w.c.sheet[0])

// SwarmBlotter_witness — %sworn assertions via this.story_swear. Each a happened-FACT of the sheet:
//  three one-time serials under one blotter, the independent single-use spend, the whole-sheet claim,
//   the refused replay, and the legacy door-parse. Gated to the beat the truth first holds.
SwarmBlotter_witness(w):
    let n = (this.c.run)?.c.step_n
    let host = this.SwarmBlotter_ident(w, 'Host')
    let uno = this.SwarmBlotter_ident(w, 'Uno')
    let dos = this.SwarmBlotter_ident(w, 'Dos')
    let tres = this.SwarmBlotter_ident(w, 'Tres')
    let qua = this.SwarmBlotter_ident(w, 'Qua')
    if (!host || !uno || !dos || !tres || !qua) return
    // beat 2: five online selves.
    if (n === 2 && [host, uno, dos, tres, qua].every(i => this.Swarm_peering(i)?.sc?.online)) this.story_swear(w, 'five selves stand up online — a sheet issuer three serial claimants and a replayer of a torn ticket')
    let peer = this.Swarm_peering(host)
    // THE SHEET LEAVES NO GROUP BEHIND (2026-08-12). There is no %Blotter and no record per serial —
    //  only the ISSUER, whose number was wound past all three. So the witness reads the issuer: how
    //   far it wound (`next`), and which numbers came back (`claimed`).
    let iz = peer?.o({ Idzeug: 1, next: 1, to: 'Music', genre: 'Jazz' })[0]
    let rows = peer?.o({ Idzeug: 1 }).filter(r => !r.sc.next) ?? []
    let hostUno = peer?.o({ Pier: 1, pub: uno.sc.prepub })[0]?.o({ Grant: 'Music', by: uno.c.keys?.pub })[0]
    let unoHost = this.Swarm_peering(uno)?.o({ Pier: 1, pub: host.sc.prepub })[0]?.o({ Grant: 'Music', by: host.c.keys?.pub })[0]
    // beat 3: three tickets issued off ONE issuer and not one particle minted for them; the first torn
    //  spends only its own number.
    if (n === 3 && iz && w.c.sheet?.length === 3 && +iz.sc.next === 4 && !rows.length) this.story_swear(w, 'a printed sheet is three numbers wound off one issuer — no particle is born for a ticket that has yet to come home')
    let claimed3 = this.Swarm_issued(host, { Music: 1, genre: 'Jazz' })
    if (n === 3 && hostUno && unoHost && this.Swarm_claimed_has(iz?.sc?.claimed, 1) && !this.Swarm_claimed_has(iz?.sc?.claimed, 2) && !this.Swarm_claimed_has(iz?.sc?.claimed, 3) && claimed3.claimed === 1) this.story_swear(w, 'the first torn serial seals a real friendship and ticks off only itself — its siblings on the sheet stay unclaimed')
    // beat 4: each serial admits its own claimant — three independent friendships and a fully claimed sheet.
    let hostDos = peer?.o({ Pier: 1, pub: dos.sc.prepub })[0]?.o({ Grant: 'Music', by: dos.c.keys?.pub })[0]
    let hostTres = peer?.o({ Pier: 1, pub: tres.sc.prepub })[0]?.o({ Grant: 'Music', by: tres.c.keys?.pub })[0]
    let dosHost = this.Swarm_peering(dos)?.o({ Pier: 1, pub: host.sc.prepub })[0]?.o({ Grant: 'Music', by: host.c.keys?.pub })[0]
    let tresHost = this.Swarm_peering(tres)?.o({ Pier: 1, pub: host.sc.prepub })[0]?.o({ Grant: 'Music', by: host.c.keys?.pub })[0]
    let claimed4 = this.Swarm_issued(host, { Music: 1, genre: 'Jazz' })
    // the run-list COALESCES: three separate claims arriving in order leave `1-3`, one run, not three
    //  entries — the compaction that makes an account file readable is a happened-fact here.
    if (n === 4 && hostDos && hostTres && dosHost && tresHost && iz?.sc?.claimed === '1-3' && claimed4.claimed === 3 && claimed4.count === 3) this.story_swear(w, 'each number admits its own claimant — three torn tickets seal three independent friendships and the issuer reads back one unbroken claimed run')
    // beat 5: the one-timer refuses a second tear; the legacy link still parses granting ftp not Music.
    let quaRebuff = qua.o({ rebuff: 'rejected_spent' })[0]
    let hostNoQua = !(peer?.o({ Pier: 1, pub: qua.sc.prepub }).length)
    let quaNoHost = !(this.Swarm_peering(qua)?.o({ Pier: 1, pub: host.sc.prepub }).length)
    let claimed5 = this.Swarm_issued(host, { Music: 1, genre: 'Jazz' })
    if (n === 5 && quaRebuff && hostNoQua && quaNoHost && claimed5.claimed === 3) this.story_swear(w, 'a torn ticket cannot be torn twice — replaying a claimed number is refused and seals no friendship')
    let leg = this.Swarm_legacy_of_url('https://jam/#0123456789abcdef-Alice-cafef00d')
    if (n === 5 && leg && leg.legacy && leg.granted === 'ftp' && leg.granted !== 'Music') this.story_swear(w, 'the old garden link still parses at the door — its hash-fragment shape grants the legacy trust atom never a Music Feature')

// SwarmBlotter_order — float A:SwarmBlotter to the front of H/* so the Run snap stays readable.
async SwarmBlotter_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'SwarmBlotter') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)

// ══ SwarmSpoof — the ELEVENTH Book: the prepub-forgery teeth (crypto audit 2026-07-22) ══════════════
//  SwarmStaple's beat-4 teeth reject a TAMPERED blob and an OFFLINE redeem. SwarmSpoof adds the tooth
//   the audit found MISSING: a pier_hello may declare ANY page.prepub while carrying its OWN page.pub
//    and a self-signed reciprocal grant — nothing bound the routing address (prepub) to the verified
//     key (pub). Swarm_seal keys the durable %Pier by prepub, so an UNBOUND hello lets a redeemer
//      plant a contact under — or overwrite — a VICTIM's address (an identity-slot hijack). Here
//       Mallory holds a REAL Music Idzeug from Alice and dials the door claiming to BE Vic: page =
//        {pub: Mallory's key, prepub: Vic's address}. The door MUST refuse — no contact under Vic's
//         address, the live invite unspent — because prepubOf(page.pub) !== page.prepub. Own world
//          w:SwarmSpoof (dispatch by WORLD NAME). RED until Swarm_page_bound gates the seal.
//  RE-EXPRESSED for the compact token (2026-07-27): the hello carries no grant any more and the
//   token no third-party signature — so beat 5 mounts the two attacks the compact form invites:
//    a GUESSED serial (they count — a blotter is <tag>-1, <tag>-2…) and a FORGED presig on the
//     real serial. Both refuse LOCALLY (no reply, no spend, no contact): the presig is a per-serial
//      MAC only the issuer's key regenerates.
SwarmSpoof(A,w):
    w oai %req:wrangle,eternal
        await &SwarmSpoof_drive,w,req
        req%ok = 1

// SwarmSpoof_drive — beat dispatch (req-local did_step), then drain the wire and re-sort H/*.
async SwarmSpoof_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.SwarmSpoof_sides_up(w)
        if (n === 3) await this.SwarmSpoof_mint(w)
        if (n === 4) await this.SwarmSpoof_spoof(w)
        if (n === 5) await this.SwarmSpoof_guess(w)
    }
    await this.SwarmSpoof_pump(w)
    await this.SwarmSpoof_order(w)

// SwarmSpoof_pump — bounded drain (the SwarmBlotter lesson): the attack is a DIRECT Swarm_hello (a
//  hand-crafted frame, as hear would deliver it), so there is little mail to settle — but keep the
//   bounded shape so a stray pier_reject to a routeless address never spins a beat.
async SwarmSpoof_pump(w):
    let guard = 0
    while (guard < 8) {
        guard = guard + 1
        for (const acct of w.o({ Account: 1 })) {
            for (const ident of acct.o({ Identity: 1 })) await this.Swarm_pump(w, ident)
        }
        let pending = 0
        for (const acct of w.o({ Account: 1 })) {
            for (const ident of acct.o({ Identity: 1 })) {
                let inbox = ident.o({ mail: 1 })[0]
                if (inbox) pending = pending + inbox.o({ frame: 1 }).filter(m => !m.sc.did).length
            }
        }
        if (pending === 0) break
    }

// SwarmSpoof_person — a fixed self seeded off the name (its own of: tag), brought ONLINE at once.
async SwarmSpoof_person(w, name):
    let acct = w.oai({ Account: 1, of: name })
    acct.c.up = w
    let keys = await this.Swarm_mint_keys('SwarmSpoof-' + name)
    let ident = this.Swarm_identity(acct, keys, name)
    this.Swarm_online(ident, true)
    return ident

SwarmSpoof_ident(w, name):
    return w.o({ Account: 1, of: name })[0]?.o({ Identity: 1 })[0]

// beat 2 — the cast: Alice (the inviter), Mallory (holds a real invite), Vic (the innocent whose
//  address Mallory forges). All online. Witness armed last so it reads each pass's settled state.
async SwarmSpoof_sides_up(w):
    w i reached:step_2
    w.sc.now = 1759000000
    await this.SwarmSpoof_person(w, 'Alice')
    await this.SwarmSpoof_person(w, 'Mallory')
    await this.SwarmSpoof_person(w, 'Vic')
    w.doai({req: 'witness', eternal: 1})?.(async (req) => { this.SwarmSpoof_witness(w); req.sc.ok = 1 })

// beat 3 — Alice mints a real single-use Music Idzeug (Jazz). Mallory legitimately holds it (a
//  shared/leaked link is a normal way to hold one) — the invite is LIVE, so beat 4's refusal is
//   about the SPOOF, not a dead invite.
async SwarmSpoof_mint(w):
    w i reached:step_3
    w.sc.now = 1759000010
    let alice = this.SwarmSpoof_ident(w, 'Alice')
    w.c.iz = await this.Swarm_mint_idzeug(w, alice, { Music: 1, genre: 'Jazz' }, 'spoof_1')

// beat 4 — the attack: Mallory crafts a pier_hello echoing Alice's REAL token, but declares VIC's
//  address as the page prepub. The door hears it as hear() would deliver it (a direct Swarm_hello
//   on the hand-crafted frame). Nothing Mallory carries proves the Vic address is theirs — the
//    seal must refuse: prepubOf(page.pub) !== page.prepub. (No grant rides a hello any more — the
//     compact seal defers the reciprocal to pier_confirm, so the forged-reciprocal leg of the old
//      attack simply has no seam left to land on.)
async SwarmSpoof_spoof(w):
    w i reached:step_4
    w.sc.now = 1759000020
    let alice = this.SwarmSpoof_ident(w, 'Alice')
    let mal = this.SwarmSpoof_ident(w, 'Mallory')
    let vic = this.SwarmSpoof_ident(w, 'Vic')
    let page = { pub: mal.c.keys.pub, prepub: vic.sc.prepub, friendly: 'Vic' }
    let frame = { kind: 'pier_hello', iz: w.c.iz, page: page }
    await this.Swarm_hello(w, alice, frame)

// beat 5 — the guesser: Mallory wears her OWN page now (bound — nothing forged there) and probes
//  the door twice: an INVENTED serial with a junk presig, then the REAL serial with a forged
//   presig. Serials are guessable by construction; the presig is the per-serial MAC only Alice's
//    key regenerates — both probes must refuse LOCALLY: no reply confirms the door exists, nothing
//     spends, no contact forms.
async SwarmSpoof_guess(w):
    w i reached:step_5
    w.sc.now = 1759000030
    let alice = this.SwarmSpoof_ident(w, 'Alice')
    let mal = this.SwarmSpoof_ident(w, 'Mallory')
    let page = { pub: mal.c.keys.pub, prepub: mal.sc.prepub, friendly: 'Mallory' }
    let guessed = this.Swarm_token(alice.sc.prepub, 'spoof_99', 'Music', 'deadbeefdeadbeef')
    await this.Swarm_hello(w, alice, { kind: 'pier_hello', iz: guessed, page: page })
    let t = this.Swarm_token_parse(w.c.iz)
    let forged = this.Swarm_token(t.prepub, t.serial, t.n, 'deadbeefdeadbeef')
    await this.Swarm_hello(w, alice, { kind: 'pier_hello', iz: forged, page: page })

// ── the witness — %sworn assertions via this.story_swear (idempotent per run, shelf-checked) ──────
SwarmSpoof_witness(w):
    let n = (this.c.run)?.c.step_n
    let alice = this.SwarmSpoof_ident(w, 'Alice')
    if (!alice) return
    let aPeering = this.Swarm_peering(alice)
    let record = aPeering?.o({ Idzeug: 'spoof_1' })[0]
    // beat 3: the invite is real (Music/Jazz) — a stable claim that does not depend on the later spend.
    if (n >= 3 && record && record.sc.to === 'Music' && record.sc.genre === 'Jazz') this.story_swear(w, 'Alice mints a real Music Idzeug scoped to Jazz — a single-use invite Mallory carries to the door')
    // beat 4: THE TOOTH — a page whose prepub its pub does not derive is refused BEFORE any state moves.
    //  Pairs the POSITIVE (the door rebuffed 'hello_spoofed') with the NEGATIVES (no contact under Vic's
    //   address, the invite unspent) so it can never pass vacuously — the guard must have actively fired.
    let vic = this.SwarmSpoof_ident(w, 'Vic')
    let spoofedPier = vic ? aPeering?.o({ Pier: 1, pub: vic.sc.prepub })[0] : null
    let spoofRebuff = alice.o({ rebuff: 'hello_spoofed' })[0]
    if (n >= 4 && spoofRebuff && !spoofedPier && record && !record.sc.spent) this.story_swear(w, 'a hostile hello declaring an address its key cannot derive is refused at the door — no contact seals under the forged address and the live invite stays unspent')
    // beat 4b: verify-first refuses LOCALLY (no route minted, no reply) — so the innocent address the
    //  attacker WORE hears nothing back; a spoof cannot be turned into a rejection-spam against a third party.
    let vicHeard = vic ? vic.o({ rebuff: 1 })[0] : null
    if (n >= 4 && spoofRebuff && !vicHeard) this.story_swear(w, 'the forged victim is left untouched — the refused spoof sends no reply so the innocent address the attacker wore is never spammed with a rejection')
    // beat 5: the presig teeth — a guessed serial refuses hello_unknown and a forged presig refuses
    //  hello_forged, both LOCALLY: Mallory hears nothing, nothing spends, no contact forms even on
    //   her honestly-bound page. Only the issuer key can wear the MAC.
    let mal = this.SwarmSpoof_ident(w, 'Mallory')
    let malPier = mal ? aPeering?.o({ Pier: 1, pub: mal.sc.prepub })[0] : null
    let malHeard = mal ? mal.o({ rebuff: 1 })[0] : null
    if (n >= 5 && alice.o({ rebuff: 'hello_unknown' })[0] && alice.o({ rebuff: 'hello_forged' })[0] && !malPier && record && !record.sc.spent && !malHeard) this.story_swear(w, 'a guessed serial and a forged presig both refuse locally — no reply and no spend and no contact — only the issuer key can wear the MAC')

// SwarmSpoof_order — float A:SwarmSpoof to the front of H/* so the Run snap stays readable.
async SwarmSpoof_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'SwarmSpoof') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)

// ══ SwarmDisk — the TWELFTH Book: identity persisted to .jamsend (Identity_persist_todo, 2026-07-27) ══
//  The other Swarm Books prove the LIVE machine; SwarmDisk proves it SURVIVES a fresh browser.  Two
//   strangers become friends, the owner's whole account is mirrored to the owner-local .jamsend disk
//    (account/<prepub>/toc.snap — the export snap with the keypair embedded, the human's ruling: keys
//     ride the snap; identities/toc.snap — the pub-only recognition roster), then a FRESH container
//      with no prior state reseeds the owner off that disk alone: the friendship reborn, the thawed
//       private key both verifies her old grant and signs a new one, and a re-save is byte-identical.
//   The nav is an IN-MEMORY double of the 7-method contract (dirs/read_file/write_file/dir_at): the
//    account round-trip logic is what changed, and the real FSA backend is already proven by the
//     Heist|Musu Books over the SAME contract — so this Book runs on ANY runner, no FSA grant, and a
//      reload never strands it (the two-tab fingers-test is the remaining real-disk proof, §3).
//   Own world w:SwarmDisk (dispatch by WORLD NAME — the usual bomb); seeded keys, pinned clock.
SwarmDisk(A,w):
    w oai %req:wrangle,eternal
        await &SwarmDisk_drive,w,req
        req%ok = 1

// SwarmDisk_drive — beat dispatch (req-local did_step), then drain the mail wire and re-sort H/*.
async SwarmDisk_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.SwarmDisk_sides_up(w)
        if (n === 3) await this.SwarmDisk_befriend(w)
        if (n === 4) await this.SwarmDisk_persist_beat(w)
        if (n === 5) await this.SwarmDisk_reseed(w)
        if (n === 6) await this.SwarmDisk_multi(w)
        if (n === 7) await this.SwarmDisk_revoke(w)
    }
    await this.SwarmDisk_pump(w)
    await this.SwarmDisk_order(w)

// SwarmDisk_pump — bounded mail drain (the SwarmBlotter lesson): let the 3-frame seal settle across
//  passes without spinning a beat.
async SwarmDisk_pump(w):
    let guard = 0
    while (guard < 8) {
        guard = guard + 1
        for (const acct of w.o({ Account: 1 })) {
            for (const ident of acct.o({ Identity: 1 })) await this.Swarm_pump(w, ident)
        }
        let pending = 0
        for (const acct of w.o({ Account: 1 })) {
            for (const ident of acct.o({ Identity: 1 })) {
                let inbox = ident.o({ mail: 1 })[0]
                if (inbox) pending = pending + inbox.o({ frame: 1 }).filter(m => !m.sc.did).length
            }
        }
        if (pending === 0) break
    }

// SwarmDisk_memnav — an in-memory double of the nav contract used by the persistence helpers.  Keyed
//  dirs[dirpath][filename] = content; dir_at lists the immediate child dir names below a path (the
//   only listing Swarm_account_list needs).  Rides w.c.nav (never encoded), so the disk store never
//    pollutes the got_snap — the fixture sees only the live C tree.
SwarmDisk_memnav():
    let dirs = {}
    let nav = { dirs: dirs }
    nav.read_file = async (dir, filename) => {
        if (dirs[dir] && dirs[dir][filename] != null) return dirs[dir][filename]
        return null
    }
    nav.write_file = async (dir, filename, content) => {
        if (!dirs[dir]) dirs[dir] = {}
        dirs[dir][filename] = content
    }
    nav.dir_at = async (path) => {
        let base = String(path).split('/').filter(Boolean)
        let kids = new Set()
        for (const dp of Object.keys(dirs)) {
            let segs = dp.split('/').filter(Boolean)
            if (base.length < segs.length && base.every((s, i) => segs[i] === s)) kids.add(segs[base.length])
        }
        let names = [...kids]
        return { directories: names.map(z => ({ name: z })), files: [], expand: async () => {} }
    }
    return nav

// SwarmDisk_person — a fixed self seeded off the name, brought ONLINE at once.
async SwarmDisk_person(w, name):
    let acct = w.oai({ Account: 1, of: name })
    acct.c.up = w
    let keys = await this.Swarm_mint_keys('SwarmDisk-' + name)
    let ident = this.Swarm_identity(acct, keys, name)
    this.Swarm_online(ident, true)
    return ident

SwarmDisk_ident(w, name):
    return w.o({ Account: 1, of: name })[0]?.o({ Identity: 1 })[0]

// beat 2 — the cast: Alice + Bob, both online, and the in-memory disk stood up on w.c.nav.  Witness
//  armed last (own swept req) so it reads each pass's settled state.
async SwarmDisk_sides_up(w):
    w i reached:step_2
    w.sc.now = 1759100010
    w.c.nav = this.SwarmDisk_memnav()
    w.c.root = ''
    await this.SwarmDisk_person(w, 'Alice')
    await this.SwarmDisk_person(w, 'Bob')
    w.doai({req: 'witness', eternal: 1})?.(async (req) => { this.SwarmDisk_witness(w); req.sc.ok = 1 })

// beat 3 — the friendship: Alice mints a single-use Music Idzeug (Jazz), Bob redeems it, the 3-frame
//  seal crosses.  Now Alice's account carries a real Pier + a cross-signed grant + a spent iz record
//   — a non-trivial thing to persist.
async SwarmDisk_befriend(w):
    w i reached:step_3
    w.sc.now = 1759100020
    let alice = this.SwarmDisk_ident(w, 'Alice')
    let bob = this.SwarmDisk_ident(w, 'Bob')
    w.c.iz = await this.Swarm_mint_idzeug(w, alice, { Music: 1, genre: 'Jazz' }, 'disk_1')
    await this.Swarm_redeem(w, bob, w.c.iz)

// beat 4 — the mirror: Alice's whole account is written to the owner-local disk (keys embedded) and
//  her recognition row to the roster (pub-only).  Read the raw artifacts back onto .c so the witness
//   can assert what LANDED without re-importing.
async SwarmDisk_persist_beat(w):
    w i reached:step_4
    w.sc.now = 1759100030
    let alice = this.SwarmDisk_ident(w, 'Alice')
    w.c.saved_snap = await this.Swarm_account_save(w.c.nav, w.c.root, alice)
    await this.Swarm_roster_save(w.c.nav, w.c.root, alice)
    w.c.disk_acct = await w.c.nav.read_file(this.Swarm_account_dir(w.c.root, alice.sc.prepub), 'toc.snap')
    w.c.disk_roster = await w.c.nav.read_file(this.Swarm_roster_dir(w.c.root), 'toc.snap')

// beat 5 — the fresh browser: a container with NO prior state reseeds the owner off disk alone.  Prove
//  the thawed key SIGNS (mint a fresh grant, verify it) and that a re-save is byte-identical (the
//   §4 robustness claim, now through the nav).
async SwarmDisk_reseed(w):
    w i reached:step_5
    w.sc.now = 1759100040
    let vault = w.oai({ Account: 1, of: 'AliceReseed' })
    vault.c.up = w
    let seed = await this.Swarm_boot_seed(w.c.nav, w.c.root, vault, null)
    if (!seed) return
    let ok = 0
    try {
        let fresh = await mint_grant(seed.ident.c.keys, '*', 'Music', {}, 1759100040)
        await verify_grant(fresh)
        ok = 1
        w.c.fresh_by = fresh.by
    } catch (er) { ok = 0 }
    w.c.fresh_ok = ok
    let resnap = await this.Swarm_account_save(w.c.nav, w.c.root, seed.ident)
    w.c.reseed_identical = (resnap === w.c.saved_snap) ? 1 : 0
    // grafted piers are STASH-WORTHY (the fix for "grafted piers never hit the Dexie stash"): the
    //  reseeded Alice's %Pier to Bob arrived via Swarm_graft, never Swarm_seal, so it was never
    //   stashed.  Swarm_restash_piers now mirrors it at standup — prove the mechanism here by
    //    reconstructing that grafted pier's durable entry and re-verifying its grant atom off the
    //     signature alone (a valid entry is what the next warm reload rehydrates from).
    let bob = this.SwarmDisk_ident(w, 'Bob')
    let rpier = this.Swarm_peering(seed.ident)?.o({ Pier: 1, pub: bob?.sc?.prepub })[0]
    if (rpier) {
        let e = this.Swarm_pier_entry(rpier)
        w.c.restash_page = (e.page.prepub === bob.sc.prepub && e.page.pub === bob.c.keys?.pub) ? 1 : 0
        let gok = 0
        try {
            if (e.grants[0]) { await verify_grant(e.grants[0]); gok = (e.grants[0].to === 'Music') ? 1 : 0 }
        } catch (er) { gok = 0 }
        w.c.restash_grant_ok = gok
    }

// beat 6 — the shared FSA point: a SECOND owner (Carol) persists to the same disk (no friendship
//  needed — a bare account is enough to test enumeration + the ?I= pick).  Swarm_account_list finds
//   BOTH; Swarm_boot_seed(want=Carol) picks CAROL not the first; the roster names both pub-only.  This
//    is the multi-identity path the human flagged (?I= selects; weakly supported by design).
async SwarmDisk_multi(w):
    w i reached:step_6
    w.sc.now = 1759100050
    let carol = await this.SwarmDisk_person(w, 'Carol')
    await this.Swarm_persist(w.c.nav, w.c.root, carol)
    w.c.acct_list = await this.Swarm_account_list(w.c.nav, w.c.root)
    let vault = w.oai({ Account: 1, of: 'CarolReseed' })
    vault.c.up = w
    let seed = await this.Swarm_boot_seed(w.c.nav, w.c.root, vault, carol.sc.prepub)
    if (seed) w.c.picked = seed.prepub
    w.c.roster_snap = await w.c.nav.read_file(this.Swarm_roster_dir(w.c.root), 'toc.snap')

// beat 7 — write-through UPDATE + tombstone durability: Alice REVOKES Bob (a %NotGrant, synchronous —
//  no wire), re-persists the whole account (whole-file replace, so the disk TRACKS the mutation not just
//   the first write), and a FRESH reseed must carry the revocation across disk — a reload never silently
//    re-grants (the durable-tombstone law, now across the disk round-trip).
async SwarmDisk_revoke(w):
    w i reached:step_7
    w.sc.now = 1759100060
    let alice = this.SwarmDisk_ident(w, 'Alice')
    let bob = this.SwarmDisk_ident(w, 'Bob')
    let pier = this.Swarm_peering(alice)?.o({ Pier: 1, pub: bob.sc.prepub })[0]
    if (pier) await this.Swarm_revoke(w, alice, pier, 'Music')
    w.c.saved_snap2 = await this.Swarm_account_save(w.c.nav, w.c.root, alice)
    let vault = w.oai({ Account: 1, of: 'AliceRevoked' })
    vault.c.up = w
    await this.Swarm_boot_seed(w.c.nav, w.c.root, vault, alice.sc.prepub)

// SwarmDisk_witness — %sworn assertions via this.story_swear.  Each a happened-FACT: the friendship,
//  the self-sufficient account snap, the pub-only roster, the reborn owner, the still-signing thawed
//   key, and the byte-identical disk round trip.  Gated to the beat the truth first holds; every claim
//    pairs a positive with the guard that makes it un-vacuous (a key IS on the account, is NOT on the
//     roster; the reseeded key EQUALS the original; the re-save EQUALS the saved snap).
SwarmDisk_witness(w):
    let n = (this.c.run)?.c.step_n
    let alice = this.SwarmDisk_ident(w, 'Alice')
    let bob = this.SwarmDisk_ident(w, 'Bob')
    if (!alice || !bob) return
    let aPeering = this.Swarm_peering(alice)
    let bPeering = this.Swarm_peering(bob)
    let key = alice.c.keys?.key
    let pub = alice.c.keys?.pub
    // beat 3: Alice and Bob become friends — a Pier each carrying the OTHER's signed Music grant.
    let aGrant = aPeering?.o({ Pier: 1, pub: bob.sc.prepub })[0]?.o({ Grant: 'Music', by: bob.c.keys?.pub })[0]
    let bGrant = bPeering?.o({ Pier: 1, pub: alice.sc.prepub })[0]?.o({ Grant: 'Music', by: pub })[0]
    if (n >= 3 && aGrant && bGrant) this.story_swear(w, 'Alice and Bob become friends — each Pier carries a Music grant the other signed — a real account to persist')
    // beat 4: the account snap stands alone (grant + pub + private key inline); the roster is pub-only.
    let acct = w.c.disk_acct
    let roster = w.c.disk_roster
    if (n >= 4 && acct && key && pub && acct.includes('Grant') && acct.includes(key) && acct.includes(pub)) this.story_swear(w, 'the account persists to disk — its snap carries the friendship grant and the keypair inline so the owner-local backup stands alone')
    if (n >= 4 && roster && pub && key && roster.includes(pub) && !roster.includes(key)) this.story_swear(w, 'the roster names its owner for recognition — pub and friendly on disk and never the private key')
    // beat 5: a fresh container reseeds the owner off disk — friendship + thawed key reborn, still
    //  signs, and a re-save is byte-identical.
    let vault = w.o({ Account: 1, of: 'AliceReseed' })[0]
    let rAlice = vault?.o({ Identity: 1 })[0]
    let rGrant = this.Swarm_peering(rAlice)?.o({ Pier: 1, pub: bob.sc.prepub })[0]?.o({ Grant: 'Music', by: bob.c.keys?.pub })[0]
    let thawed = rAlice?.c?.keys?.key
    if (n >= 5 && rGrant && thawed && thawed === key) this.story_swear(w, 'a fresh browser reseeds its owner off disk — the friendship and the private key reborn from the account snap alone')
    if (n >= 5 && w.c.fresh_ok === 1 && w.c.fresh_by === pub) this.story_swear(w, 'the reseeded key still signs — a new grant minted after the disk round trip verifies under the same public key')
    if (n >= 5 && w.c.reseed_identical === 1) this.story_swear(w, 'the account survives the disk round trip byte for byte — the reseeded self re-saves to the very same snap')
    if (n >= 5 && w.c.restash_page === 1 && w.c.restash_grant_ok === 1) this.story_swear(w, 'a disk-grafted Pier is stash-worthy — its durable entry rebuilds the friend page and a Music grant that still verifies — so the reseeded friend survives the next warm reload')
    // beat 6: two owners share the one FSA point; enumeration finds both and a ?I= pick lands the
    //  requested owner (not merely the first) with her own key thawed.
    let carol = this.SwarmDisk_ident(w, 'Carol')
    let list = w.c.acct_list
    let both = carol && list && list.includes(alice.sc.prepub) && list.includes(carol.sc.prepub)
    if (n >= 6 && both && list.length === 2) this.story_swear(w, 'two owners share the one FSA point — enumeration finds both accounts on disk keyed by prepub')
    let cVault = w.o({ Account: 1, of: 'CarolReseed' })[0]
    let rCarol = cVault?.o({ Identity: 1 })[0]
    if (n >= 6 && carol && w.c.picked === carol.sc.prepub && rCarol?.c?.keys?.key === carol.c.keys?.key) this.story_swear(w, 'the requested owner is the one reseeded — a named pick lands Carol not merely the first account and her own key thaws')
    let rs = w.c.roster_snap
    if (n >= 6 && rs && carol && rs.includes(alice.c.keys?.pub) && rs.includes(carol.c.keys?.pub) && !rs.includes(key) && !rs.includes(carol.c.keys?.key)) this.story_swear(w, 'the roster names both owners for recognition — each pub and friendly on disk and neither private key')
    // beat 7: a mutation (revoke) re-saves the WHOLE account (update not append), and the %NotGrant
    //  tombstone survives the disk round trip — a reseeded account can never silently re-grant.
    let rvAlice = w.o({ Account: 1, of: 'AliceRevoked' })[0]?.o({ Identity: 1 })[0]
    let rvNot = this.Swarm_peering(rvAlice)?.o({ Pier: 1, pub: bob.sc.prepub })[0]?.o({ NotGrant: 1 })[0]
    if (n >= 7 && w.c.saved_snap2 && w.c.saved_snap && w.c.saved_snap2 !== w.c.saved_snap) this.story_swear(w, 'the account write-through is an update not an append — a revocation re-saves the whole snap so disk tracks the live account')
    if (n >= 7 && rvNot) this.story_swear(w, 'a revocation survives the disk round trip — the reseeded account carries the NotGrant tombstone so a reload never silently re-grants')

// SwarmDisk_order — float A:SwarmDisk to the front of H/* so the Run snap stays readable.
async SwarmDisk_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'SwarmDisk') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)

// ══ SwarmCohort — the THIRTEENTH Book: the cohort seams + the %Invite autovivify ═══════════════════
//  SwarmSteal proves the ADDRESS drama end to end — cooperation, theft, Steal Back. SwarmCohort pins
//   the SEAMS under it one by one — the pure discriminators the cohort census and the ?Iz= boot
//    handler call directly: the sibling roster (Swarm_sibling|Swarm_is_sibling), note_theft's
//     family-vs-foe RETURN VALUE (the census branches on it — 👥 silence vs the theft banner),
//      next_suffix's first-free-berth pick, and the %Invite autovivify (Swarm_invite_note) —
//       arrived, idempotent, never resetting a walked state. Model layer only — no wire, no pump;
//        own world w:SwarmCohort (dispatch by WORLD NAME, the usual bomb). Same fixed Alice as the
//         staple, pinned clock.
//   beat 2  Alice stands and two vessel tabs join the roster — vessA at _1 (cave) and vessB at _3
//            (no role) — the discriminator knows them both and no stranger
//   beat 3  note_theft told about vessA answers FALSE (family, silence) — told about evil99 it
//            answers TRUE and Identity Stolen rises
//   beat 4  next_suffix over {bare, _1, _3} picks _2 — the first free berth
//   beat 5  a compact token knocks twice — ONE %Invite vivifies and stands at state arrived
//   beat 6  the state walks to redeeming and a re-note does NOT drag it back

SwarmCohort(A,w):
    w oai %req:wrangle,eternal
        await &SwarmCohort_drive,w,req
        req%ok = 1

// SwarmCohort_drive — beat dispatch (req-local did_step), then re-sort. No pump: SwarmCohort is all
//  model-layer (no mail, no frames) so there is nothing to deliver between beats.
async SwarmCohort_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.SwarmCohort_stand(w)
        if (n === 3) await this.SwarmCohort_alarms(w)
        if (n === 4) await this.SwarmCohort_berth(w)
        if (n === 5) await this.SwarmCohort_arrive(w)
        if (n === 6) await this.SwarmCohort_advance(w)
    }
    await this.SwarmCohort_order(w)

// beat 2 — Alice stands and the roster fills: two vessel tabs of the SAME key — vessA holds _1 with
//  the cave role, vessB holds _3 with NO role (the seam takes '' and writes nothing — no empty sc
//   leg lands). Witness rides its own swept req, minted last so it observes each pass's settled state.
async SwarmCohort_stand(w):
    w.sc.now = 1759200000
    let alice = await this.SwarmStaple_person(w, 'Alice')
    let prepub = alice.sc.prepub
    this.Swarm_sibling(alice, 'vessA', prepub + '_1', 'cave')
    this.Swarm_sibling(alice, 'vessB', prepub + '_3', '')
    w.doai({req: 'witness', eternal: 1})?.(async (req) => { this.SwarmCohort_witness(w); req.sc.ok = 1 })

// beat 3 — the discriminator's two answers in one beat, the RETURN VALUES parked on w.c (never
//  encoded): a known sibling claiming the name is family — false, no husk — while evil99 alarms —
//   true, the stolen flag rises and a durable %Stolen husk lands. Both calls pass a null `at` (the
//    census's own shape — it carries no clock), so the husk lands wall-clock; re-pin it to the beat
//     clock so the snap repeats byte for byte.
async SwarmCohort_alarms(w):
    w.sc.now = 1759200010
    let alice = this.SwarmStaple_ident(w, 'Alice')
    w.c.kin_alarm = this.Swarm_note_theft(alice, 'vessA', null)
    w.c.foe_alarm = this.Swarm_note_theft(alice, 'evil99', null)
    let husk = this.Swarm_peering(alice)?.o({ Stolen: 'evil99' })[0]
    if (husk) {
        husk.sc.at = String(w.sc.now)
        husk.bump()
    }

// beat 4 — the berth pick: the pure jump the census hands a newborn tab — past the bare name and the
//  held suffixes to the first free one. Parked on w.c for the witness (a string return, never sc).
async SwarmCohort_berth(w):
    w.sc.now = 1759200020
    let alice = this.SwarmStaple_ident(w, 'Alice')
    let prepub = alice.sc.prepub
    w.c.berth = this.Swarm_next_suffix(prepub, [prepub, prepub + '_1', prepub + '_3'])

// beat 5 — the autovivify: a compact token (the file's own codec — prepub16*serial*n*presig16, the
//  SwarmSpoof presig idiom: 16 hex chars or the parse refuses) knocks TWICE. One %Invite must stand —
//   state arrived, the offer legs on sc, the presig leg riding .c only — and the second knock finds
//    the first (oai, never a twin).
async SwarmCohort_arrive(w):
    w.sc.now = 1759200030
    let alice = this.SwarmStaple_ident(w, 'Alice')
    w.c.tok = this.Swarm_token(alice.sc.prepub, 'cohort_1', 'Music', 'deadbeefdeadbeef')
    this.Swarm_invite_note(w, w.c.tok)
    this.Swarm_invite_note(w, w.c.tok)

// beat 6 — the walked state sticks: the Door moves the %Invite to redeeming; the same token knocking
//  again (a re-render or a second scan re-noting the URL) must NOT drag it back to arrived.
async SwarmCohort_advance(w):
    w.sc.now = 1759200040
    let inv = w.o({ Invite: 'cohort_1' })[0]
    if (inv) {
        inv.sc.state = 'redeeming'
        inv.bump()
    }
    this.Swarm_invite_note(w, w.c.tok)

// ── the witness — each %see is a per-beat OBSERVATION, gated to its own step (n === K) and reading
//  the LIVE truth of that beat (the SwarmSteal lesson: %see is not a latch — the drop is the signal).
SwarmCohort_witness(w):
    let n = (this.c.run)?.c.step_n
    let alice = this.SwarmStaple_ident(w, 'Alice')
    if (!alice) return
    let peering = this.Swarm_peering(alice)
    if (!peering) return
    let prepub = alice.sc.prepub
    // beat 2: the discriminator — both vessels are known tabs (address + role landed) and a stranger is not.
    let sibA = peering.o({ Sibling: 'vessA' })[0]
    if (n === 2 && this.Swarm_is_sibling(alice, 'vessA') && this.Swarm_is_sibling(alice, 'vessB') && !this.Swarm_is_sibling(alice, 'stranger9') && sibA && sibA.sc.address === prepub + '_1' && sibA.sc.role === 'cave' && !(oa %see:'the roster knows vessA and vessB as our own tabs — a stranger is no sibling')) i %see:'the roster knows vessA and vessB as our own tabs — a stranger is no sibling'
    // beat 3: the two answers — family is silence (false, no husk) while a foe is the alarm (true + husk).
    if (n === 3 && w.c.kin_alarm === false && !peering.o({ Stolen: 'vessA' })[0] && !(oa %see:'a sibling claiming the name is family — note_theft answers false and raises nothing')) i %see:'a sibling claiming the name is family — note_theft answers false and raises nothing'
    if (n === 3 && w.c.foe_alarm === true && this.Swarm_stolen(alice) && peering.o({ Stolen: 'evil99' })[0] && !(oa %see:'an unknown claimant is a theft — note_theft answers true and Identity Stolen rises for evil99')) i %see:'an unknown claimant is a theft — note_theft answers true and Identity Stolen rises for evil99'
    // beat 4: the berth — past the bare name and the held _1|_3 to the first free suffix.
    if (n === 4 && w.c.berth === prepub + '_2' && !(oa %see:'next_suffix jumps past the bare name and the held tabs to the first free berth at prepub_2')) i %see:'next_suffix jumps past the bare name and the held tabs to the first free berth at prepub_2'
    // beat 5: the autovivify — ONE particle stands at arrived even after two knocks; the offer legs on sc.
    let inv = w.o({ Invite: 'cohort_1' })[0]
    let invs = w.o({ Invite: 1 })
    if (n === 5 && inv && inv.sc.state === 'arrived' && inv.sc.prepub === prepub && inv.sc.to === 'Music' && !(oa %see:'a scanned token vivifies an Invite particle standing at state arrived with its offer legs on it')) i %see:'a scanned token vivifies an Invite particle standing at state arrived with its offer legs on it'
    if (n === 5 && inv && invs.length === 1 && !(oa %see:'noting the same token twice is idempotent — one Invite particle stands not two')) i %see:'noting the same token twice is idempotent — one Invite particle stands not two'
    // beat 6: the walked state sticks — a re-note never resets it and still never twins the particle.
    if (n === 6 && inv && inv.sc.state === 'redeeming' && invs.length === 1 && !(oa %see:'a re-note never resets a walked state — the Invite stays redeeming after the token knocks again')) i %see:'a re-note never resets a walked state — the Invite stays redeeming after the token knocks again'

// SwarmCohort_order — float A:SwarmCohort to the front of H/* so the Run snap stays readable.
async SwarmCohort_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'SwarmCohort') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)

// ══ SwarmRole — LinkDevice Phase 0: a role Feature rides the standing rails and the features isolate ══════
//  Division (Portability_doc §10) is `%Invite:MyCave` on the %Idzeug rails — the same issuer, token codec,
//   redeem door, and grant mint that carry Music, carrying a ROLE.  The doc says the rails are generic and
//    the serve layer's 'Music' hardcodes are correct as music-serving; this Book PROVES both halves at the
//     model layer (SwarmStaple's mould: fixed keys, pinned clock, the in-process mail wire, no socket):
//   beat 2  Alice (the Captain) + Cara (the cave-to-be) + Bob (a mere friend) stand up
//   beat 3  Alice mints TWO invites off the one machinery: %Idzeug to:MyCave (role_1) and to:Music (role_m1)
//   beat 4  both redeem — Cara the role token, Bob the music token; hello → accept → confirm play out
//            through the pump; each seals a mutual %Pier whose grants WEAR THEIR OWN FEATURE end to end
//  THE DISCRIMINATION ([[adversarial-test-agent]]): the isolation is checked BOTH ways on BOTH piers —
//   Swarm_pier_live(cara-pier,'Music') must be FALSE (a Cave is not thereby a music friend) and
//    Swarm_pier_live(bob-pier,'MyCave') must be FALSE (a music friend is not thereby a body).  And the
//     RECIPROCAL grant is pinned to the offered feature — the accept derives `to` from the claim; if the
//      pier-heal's 'Music' fallback (Swarm.g:1434) ever leaked into the seal path this Book reddens.
//  CONVENTION (Musu*/Swarm*): the world MUST be named SwarmRole (do_fn_for dispatches by w.sc.w).

SwarmRole(A,w):
    w oai %req:wrangle,eternal
        await &SwarmRole_drive,w,req
        req%ok = 1

async SwarmRole_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.SwarmRole_stand(w)
        if (n === 3) await this.SwarmRole_mint(w)
        if (n === 4) await this.SwarmRole_seal(w)
    }
    await this.SwarmRole_pump(w)
    this.SwarmRole_witness(w)
    await this.SwarmRole_order(w)

async SwarmRole_pump(w):
    for (const acct of w.o({ Account: 1 })) {
        for (const ident of acct.o({ Identity: 1 })) await this.Swarm_pump(w, ident)
    }

async SwarmRole_person(w, name):
    let acct = w.oai({ Account: 1, of: name })
    acct.c.up = w
    let keys = await this.Swarm_mint_keys('SwarmRole-' + name)
    return this.Swarm_identity(acct, keys, name)

SwarmRole_ident(w, name):
    return w.o({ Account: 1, of: name })[0]?.o({ Identity: 1 })[0]

// beat 2 — three selves: the Captain, the cave-to-be, and a plain friend for the cross-check.
async SwarmRole_stand(w):
    w i reached:step_2
    w.sc.now = 1751600000
    await this.SwarmRole_person(w, 'Alice')
    await this.SwarmRole_person(w, 'Cara')
    await this.SwarmRole_person(w, 'Bob')

// beat 3 — the one machinery mints both kinds: a role invite and a music invite off the same issuer
//  door.  Named nonces so the fixture reads as prose (the Swarm_mint_idzeug Book idiom).
async SwarmRole_mint(w):
    w i reached:step_3
    w.sc.now = 1751600010
    let alice = this.SwarmRole_ident(w, 'Alice')
    w.c.role_iz = await this.Swarm_mint_idzeug(w, alice, { MyCave: 1 }, 'role_1')
    w.c.music_iz = await this.Swarm_mint_idzeug(w, alice, { Music: 1 }, 'role_m1')

// beat 4 — both seals play out over the pump within this beat's passes: Cara redeems the ROLE token,
//  Bob the MUSIC token.  From here the witness reads settled piers — %see fires the pass a truth holds.
async SwarmRole_seal(w):
    w i reached:step_4
    w.sc.now = 1751600020
    this.Swarm_online(this.SwarmRole_ident(w, 'Alice'), true)
    let cara = this.SwarmRole_ident(w, 'Cara')
    let bob = this.SwarmRole_ident(w, 'Bob')
    this.Swarm_online(cara, true)
    this.Swarm_online(bob, true)
    await this.Swarm_redeem(w, cara, w.c.role_iz)
    await this.Swarm_redeem(w, bob, w.c.music_iz)

// ── the witness — %see gated on TRUTH not beat number (no commas; em-dashes) ──
SwarmRole_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 4)) return
    let alice = this.SwarmRole_ident(w, 'Alice')
    let cara = this.SwarmRole_ident(w, 'Cara')
    let bob = this.SwarmRole_ident(w, 'Bob')
    if (!alice || !cara || !bob) return
    let peering = this.Swarm_peering(alice)
    if (!peering) return
    let pierC = peering.o({ Pier: cara.sc.prepub })[0]
    let pierB = peering.o({ Pier: bob.sc.prepub })[0]
    // #1 THE RAILS CARRY A ROLE: the MyCave redeem seals a mutual pier — the role Feature crossed the
    //  same issuer door and token codec and hello that Music rides.
    if (pierC && this.Swarm_pier_live(pierC, 'MyCave')) this.story_swear(w, 'a role invite rides the standing rails — the MyCave redeem seals a live pier with cross-signed MyCave grants')
    // #2 ISOLATION BOTH WAYS ON BOTH PIERS: a Cave is not thereby a music friend and a music friend is
    //  not thereby a body.
    if (pierC && pierB && this.Swarm_pier_live(pierC, 'MyCave') && !this.Swarm_pier_live(pierC, 'Music') && this.Swarm_pier_live(pierB, 'Music') && !this.Swarm_pier_live(pierB, 'MyCave')) this.story_swear(w, 'the features isolate — a MyCave pier never satisfies a Music check and a Music pier never satisfies a MyCave check')
    // #3 THE RECIPROCAL WEARS THE OFFERED FEATURE: a whole seal holds BOTH cross-signed grants and on
    //  the role pier both say MyCave — derived from the claim; the pier-heal Music fallback never leaks
    //   into the seal path (grant `by` is the FULL pub so the pair is counted not name-matched).
    let role_grants = pierC ? pierC.o({ Grant: 'MyCave' }) : []
    let wrong = pierC ? pierC.o({ Grant: 'Music' }) : []
    if (pierC && role_grants.length === 2 && wrong.length === 0) this.story_swear(w, 'both halves of the seal wear the offered feature — two cross-signed MyCave grants and no Music grant rides the role pier')

// SwarmRole_order — float A:SwarmRole to the front of H/* so the Run snap stays readable.
async SwarmRole_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'SwarmRole') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)

// ══ SwarmSeal — LinkDevice Phase 1: the symmetric brick that keeps the account transfer secret ═══════════
//  Division (Portability_doc §10) moves the account Waft over the relay — an unauthenticated forwarder, so
//   an eavesdropper is assumed — under a code-derived key.  Idento (Y.svelte) is ed25519 + SHA-256 ONLY: it
//    signs and it hashes, it never keeps a secret, so the codebase had NO symmetric cipher at all.  Sealbox.ts
//     (beside Grant.ts, imported above) is that one brick — WebCrypto AES-GCM under an HKDF-SHA-256 key, zero
//      deps — and this Book gates its contract at the model layer (no wire, no Swarm spine, runs on any live
//       browser runner where crypto.subtle is present):
//   beat 2  fix the inputs — a stand-in invite code (the IKM), both pubs as the salt, a mini account snap
//   beat 3  seal it TWICE + unseal both + tamper one + wrong-code one — all outcomes pinned as booleans
//  THE DETERMINISM LAW'S CRYPTO COROLLARY: a fresh random IV per seal is MANDATORY (a fixed GCM nonce under
//   one key is the catastrophic reuse break), so the ciphertext is non-deterministic and the Book asserts
//    BEHAVIOUR — never a byte.  The only snapped number is the FRAME LENGTH (iv 12 + plaintext + tag 16, hex
//     ×2 — fixed for a fixed plaintext), which proves a real frame was produced without pinning its content.
//  THE DISCRIMINATION ([[adversarial-test-agent]]): the two seals of one plaintext must DIFFER (a dead IV
//   flips it) yet BOTH unseal to the original (a broken cipher flips it); and both a flipped byte and a wrong
//    code must THROW — a sealbox that half-decrypts a tampered frame, or ignores the key, flips the fails-closed
//     witnesses.  This is the secrecy twin of MusuFloor's fails-closed vouch — one proves WHO said it, this
//      proves it stays UNREADABLE.
//  CONVENTION (Musu*/Swarm*): the world MUST be named SwarmSeal (do_fn_for dispatches by w.sc.w).

SwarmSeal(A,w):
    w oai %req:wrangle,eternal
        await &SwarmSeal_drive,w,req
        req%ok = 1

SwarmSeal_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

SwarmSeal_note(w, sc):
    let t = this.SwarmSeal_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

async SwarmSeal_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.SwarmSeal_setup(w)
        if (n === 3) await this.SwarmSeal_prove(w)
    }
    this.SwarmSeal_witness(w)
    await this.SwarmSeal_order(w)

// beat 2 — the fixed inputs.  The code stands in for whatever Phase 3's beacon agrees (a typed short code,
//  or an ephemeral-pub agreement — the brick's contract holds either way); the salt is both pubs, a value
//   an eavesdropper knows (that is what a salt is for — domain separation, not secrecy); the plaintext is a
//    mini account snap so the frame length is a real account-shaped size.  All on .c — no secret in a snap.
SwarmSeal_setup(w):
    this.SwarmSeal_note(w, { reached: 'step_2' })
    w.c.secret = 'linkdevice-code-7f3a2b'
    w.c.salt = 'capPub_e1e1e1e1|cavePub_c0c0c0c0'
    w.c.plain = 'Identity,prepub:c0c0c0c0c0c0c0c0\n  Peering,friendly:the cave\n  key:REDACTED-SECRET-MATERIAL'
    w.c.set_up = 1

// beat 3 — the four proofs, all async, all pinned as booleans a sync witness reads.  Nothing here that
//  varies run to run reaches sc: the frames live on .c and only their (fixed) LENGTH is stamped.
async SwarmSeal_prove(w):
    this.SwarmSeal_note(w, { reached: 'step_3' })
    if (!w.c.set_up) return
    let secret = w.c.secret
    let salt = w.c.salt
    let plain = w.c.plain
    let frame1 = await seal(secret, salt, plain)
    let frame2 = await seal(secret, salt, plain)
    let back1 = await unseal(secret, salt, frame1)
    let back2 = await unseal(secret, salt, frame2)
    let row = { proved: 1, frame_hex: '' + frame1.length }
    if (back1 === plain && back2 === plain) row.roundtrip = 1
    if (frame1 !== frame2) row.fresh_iv = 1
    // tamper: flip the last hex nibble of the frame — a single-bit change the GCM tag must reject.
    let bad = frame1.slice(0, -1) + (frame1.endsWith('0') ? '1' : '0')
    let caught_tamper = 0
    try { await unseal(secret, salt, bad) } catch (e) { caught_tamper = 1 }
    if (caught_tamper) row.tamper_caught = 1
    // wrong code: a different IKM derives a different AES key — the tag check fails, unseal throws.
    let caught_wrong = 0
    try { let x = await unseal(secret + 'X', salt, frame1); if (x !== plain) caught_wrong = 1 } catch (e) { caught_wrong = 1 }
    if (caught_wrong) row.wrongkey_caught = 1
    this.SwarmSeal_note(w, row)

// ── the witness — %see gated on TRUTH not beat number (no commas; em-dashes) ──
SwarmSeal_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 3)) return
    if (!w.c.set_up) return
    let T = this.SwarmSeal_T(w)
    let p = T.o({ proved: 1 })[0]
    if (!p) return
    // #1 THE ROUNDTRIP: unseal after seal returns the account whole — the core of a usable cipher.
    if (+p.sc.roundtrip === 1) this.story_swear(w, 'the sealed account unseals whole — encrypt then decrypt under the code returns the exact account snap')
    // #2 THE LIVE NONCE: two seals of one account differ yet both unseal — the fresh IV is real not a fixed
    //  reused nonce (the AES-GCM catastrophe) and the difference costs nothing to correctness.
    if (+p.sc.fresh_iv === 1 && +p.sc.roundtrip === 1) this.story_swear(w, 'each seal carries a fresh nonce — two seals of one account differ on the wire yet both unseal to it so the ciphertext leaks nothing by repetition')
    // #3 FAILS CLOSED ON TAMPER: a flipped byte is refused — the GCM tag authenticates so a mangled account
    //  crashes the open rather than half-decrypting.
    if (+p.sc.tamper_caught === 1) this.story_swear(w, 'a tampered frame fails closed — a single flipped byte is refused by the tag and never half-decrypts into a mangled account')
    // #4 THE CODE GATES: a wrong code cannot open the frame — the whole security rests here.
    if (+p.sc.wrongkey_caught === 1) this.story_swear(w, 'the code is the gate — a wrong code derives a wrong key and the frame refuses to open under it')

// SwarmSeal_order — float A:SwarmSeal to the front of H/* so the Run snap stays readable.
async SwarmSeal_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'SwarmSeal') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)

// ══ SwarmFerry — LinkDevice Phase 3 (the core): the whole account crosses a sealed channel, secret and all ══
//  Division (Portability_doc §10) moves the account Waft to the new body as relay frames encrypted under a
//   code-derived key.  Two proven halves compose here into that claim, at the model layer with no beacon and
//    no wire (the QR + emoji-confirm are the remaining UI; the DATA CROSSING is the load-bearing part):
//     • Swarm_export/import (SwarmStaple beat 8 proved export→import→export byte-identical, keypair and all)
//     • Sealbox (SwarmSeal proved seal/unseal fails closed) — imported above.
//   beat 2  Alice the Captain stands with a real account — Identity + Peering + keys + one self-issued Idzeug
//            (account CONTENT that must survive, not a bare identity)
//   beat 3  the ferry — export {secret} → SEAL → (the relay carries only the frame) → unseal → import into a
//            fresh vessel; and a WRONG code at the far end is tried against the same frame
//  THE DISCRIMINATION ([[adversarial-test-agent]]), the security claims this ceremony rests on:
//   • the account crosses WHOLE — the vessel re-exports byte-identical to Alice's export (a lossy transfer flips it)
//   • the SECRET never rides in clear — the sealed frame does NOT contain the private-key hex (a cleartext ferry flips it)
//   • the CODE gates arrival — a wrong code cannot unseal so NO account lands at the far end (only the code-holder is made)
//   • the keypair thaws right — the landed account keeps keys on .c and bears no pub/key in sc (the ride-.c-only invariant)
//  CONVENTION (Musu*/Swarm*): the world MUST be named SwarmFerry.

SwarmFerry(A,w):
    w oai %req:wrangle,eternal
        await &SwarmFerry_drive,w,req
        req%ok = 1

SwarmFerry_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

SwarmFerry_note(w, sc):
    let t = this.SwarmFerry_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

async SwarmFerry_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.SwarmFerry_stand(w)
        if (n === 3) await this.SwarmFerry_cross(w)
    }
    this.SwarmFerry_witness(w)
    await this.SwarmFerry_order(w)

// beat 2 — Alice the Captain, a real account: fixed keys (seeded — the export repeats byte for byte), a
//  pinned clock, and one self-issued Idzeug so the account carries CONTENT the ferry must preserve.
async SwarmFerry_stand(w):
    w i reached:step_2
    w.sc.now = 1751700000
    let acct = w.oai({ Account: 1, of: 'Alice' })
    acct.c.up = w
    let keys = await this.Swarm_mint_keys('SwarmFerry-Alice')
    let alice = this.Swarm_identity(acct, keys, 'Alice')
    w.c.alice = alice
    await this.Swarm_mint_idzeug(w, alice, { Music: 1, genre: 'Jazz' }, 'ferry_1')

// beat 3 — the sealed crossing.  The code + salt stand in for Phase 2's beacon agreement (a typed short
//  code or an ephemeral-pub exchange — the brick holds either way).  Everything the relay would see is the
//   FRAME alone; the cleartext blob never leaves this function except through the seal.
async SwarmFerry_cross(w):
    w i reached:step_3
    w.sc.now = 1751700010
    if (!w.c.alice) return
    let code = 'divide-code-4b8e1a'
    let salt = 'captainPub|vesselPub'
    let blob = await this.Swarm_export(w.c.alice, { secret: 1 })
    let frame = await seal(code, salt, blob)
    let row = { ferried: 1 }
    // the wire hides the secret: the frame must not carry the private key hex an eavesdropper could lift.
    let keyhex = w.c.alice.c.keys.key
    if (keyhex && frame.indexOf(keyhex) < 0) row.secret_hidden = 1
    // the far end, code in hand: unseal → import into a FRESH vessel account container.
    let back = await unseal(code, salt, frame)
    if (back === blob) row.blob_intact = 1
    let vessel = w.oai({ Account: 1, of: 'Vessel' })
    vessel.c.up = w
    let landed = this.Swarm_import(vessel, back)
    // the account crossed whole: the landed vessel re-exports byte-identical to Alice's own export.
    let re = await this.Swarm_export(landed, { secret: 1 })
    if (re === blob) row.whole = 1
    // the keypair thawed onto .c and left no scalar behind (the ride-.c-only invariant survived transit).
    if (landed.c.keys && landed.c.keys.key === keyhex && !landed.sc.key && !landed.sc.pub) row.keys_thawed = 1
    // the far end WITHOUT the code: a wrong code cannot open the frame, so nothing lands.
    let caught = 0
    try { await unseal('wrong-code-000000', salt, frame) } catch (e) { caught = 1 }
    if (caught) row.code_gated = 1
    this.SwarmFerry_note(w, row)

// ── the witness — %see gated on TRUTH not beat number (no commas; em-dashes) ──
SwarmFerry_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 3)) return
    let T = this.SwarmFerry_T(w)
    let f = T.o({ ferried: 1 })[0]
    if (!f) return
    // #1 THE ACCOUNT CROSSES WHOLE: through seal and unseal and import the vessel re-exports byte-identical.
    if (+f.sc.blob_intact === 1 && +f.sc.whole === 1) this.story_swear(w, 'the whole account crosses the sealed channel — through seal unseal and import the vessel re-exports byte-identical to the captain')
    // #2 THE SECRET NEVER RIDES IN CLEAR: the relay frame carries no private key an eavesdropper could lift.
    if (+f.sc.secret_hidden === 1) this.story_swear(w, 'the secret never rides in clear — the sealed frame the relay carries holds no private key for an eavesdropper to lift')
    // #3 THE CODE GATES ARRIVAL: a wrong code cannot open the frame so no account is made at the far end.
    if (+f.sc.code_gated === 1) this.story_swear(w, 'the code gates who is made — a wrong code cannot open the frame so no account lands at the far end')
    // #4 THE KEYS RIDE .c ONLY, EVEN ACROSS TRANSIT: the landed account thaws its keypair onto .c and bears
    //  no pub or key scalar in sc.
    if (+f.sc.keys_thawed === 1) this.story_swear(w, 'the keys ride .c only even across transit — the landed account thaws its keypair onto .c and keeps no key scalar in its snap')

// SwarmFerry_order — float A:SwarmFerry to the front of H/* so the Run snap stays readable.
async SwarmFerry_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'SwarmFerry') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)

// ══ EmojiConfirm — LinkDevice Phase 3 (the human gate): the SAS that catches a relay MITM ═══════════════
//  The ferry (SwarmFerry) crosses an UNAUTHENTICATED relay: a code-derived key keeps the account secret, but
//   secrecy is not authenticity — a machine sitting in the middle could hold two half-channels and read all.
//    The last brick is a human check: both bodies fold the SAME transcript (their two pubs + the channel salt,
//     in a fixed sorted order) through Emojiconfirm.ts and READ ALOUD the emoji row.  Equal rows ⇒ one channel,
//      no MITM.  A spliced transcript (an attacker's pub swapped in) yields a DIFFERENT row — the humans notice.
//   beat 2  fix two accounts' pubs + the salt — the true pair, and a MITM pair (attacker's pub on one side)
//   beat 3  derive rows for both sides of the TRUE channel + both sides of the MITM channel — pin agreement
//  DETERMINISM: sas_emojis is pure sha256 → alphabet fold, no IV, no clock — the rows repeat byte for byte.
//   The snapped values are the agreement BOOLEANS and the row LENGTH (fixed count), never a raw emoji (a glyph
//    round-trips a snap badly); the discrimination is entirely in the true-agree / mitm-diverge contrast.
//  THE DISCRIMINATION ([[adversarial-test-agent]]): the two honest sides MUST agree (a broken fold flips it)
//   AND the MITM side MUST diverge from the honest row (a fold that ignores the pubs — hashing only the salt —
//    would agree even under attack, silently passing the very thing this gate exists to catch).  This is the
//     authenticity twin of SwarmSeal's secrecy: that proved it stays UNREADABLE, this proves you know WHO.
//  CONVENTION (Musu*/Swarm*): the world MUST be named EmojiConfirm.

EmojiConfirm(A,w):
    w oai %req:wrangle,eternal
        await &EmojiConfirm_drive,w,req
        req%ok = 1

EmojiConfirm_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

EmojiConfirm_note(w, sc):
    let t = this.EmojiConfirm_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

async EmojiConfirm_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.EmojiConfirm_setup(w)
        if (n === 3) await this.EmojiConfirm_prove(w)
    }
    this.EmojiConfirm_witness(w)
    await this.EmojiConfirm_order(w)

// beat 2 — the pubs.  cap + cave are the honest pair; mallory is the interposer whose pub replaces the peer's
//  on ONE side of the channel (the classic relay MITM).  The salt is public channel data both honest sides see.
//   All on .c — pubs are not secret, but they are inputs, and inputs stay off the snap here for tidiness.
EmojiConfirm_setup(w):
    this.EmojiConfirm_note(w, { reached: 'step_2' })
    w.c.capPub = 'cap_11111111111111111111111111111111'
    w.c.cavePub = 'cave_2222222222222222222222222222222'
    w.c.malPub = 'mal_9999999999999999999999999999999'
    w.c.salt = 'chan_salt_a1b2c3'
    w.c.set_up = 1

// the transcript is SORTED so both bodies build the identical string regardless of who speaks first — the
//  symmetry the SAS depends on.  A channel is the two endpoint pubs + the salt.
EmojiConfirm_chan(w, x, y):
    let pair = [x, y].sort()
    return sas_transcript([pair[0], pair[1], w.c.salt])

// beat 3 — four rows: the two HONEST sides (cap↔cave, each derives from the true pair) which must match, and
//  the MITM view (cap↔mallory) which must NOT match the honest row.  Pure — no async state but the sha256.
async EmojiConfirm_prove(w):
    this.EmojiConfirm_note(w, { reached: 'step_3' })
    if (!w.c.set_up) return
    // honest: both endpoints fold the SAME true pair — sorted, so cap's build == cave's build.
    let honest = this.EmojiConfirm_chan(w, w.c.capPub, w.c.cavePub)
    let rowCap = await sas_row(honest)
    let rowCave = await sas_row(honest)
    // MITM: cap talks to mallory (thinking it is cave); mallory talks to cave.  Cap's half-channel folds
    //  cap+mallory — a different pair, so a different row than the honest one cave would read.
    let mitm = this.EmojiConfirm_chan(w, w.c.capPub, w.c.malPub)
    let rowMitm = await sas_row(mitm)
    let row = { proved: 1, row_len: '' + rowCap.length }
    if (sas_agree(rowCap, rowCave)) row.honest_agree = 1
    if (!sas_agree(rowCap, rowMitm)) row.mitm_diverge = 1
    // and the gate is non-trivial: an empty/empty compare must be REFUSED (agree on nothing is not agreement).
    if (!sas_agree('', '')) row.empty_refused = 1
    this.EmojiConfirm_note(w, row)

// ── the witness — %see gated on TRUTH not beat number (no commas; em-dashes) ──
EmojiConfirm_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 3)) return
    if (!w.c.set_up) return
    let T = this.EmojiConfirm_T(w)
    let p = T.o({ proved: 1 })[0]
    if (!p) return
    // #1 HONEST SIDES AGREE: both endpoints of the true channel read the same emoji row — the gate passes
    //  when there is no interposer.
    if (+p.sc.honest_agree === 1) this.story_swear(w, 'both honest bodies read the same emoji row — the same transcript folds to the same short authentication string so a clean channel confirms')
    // #2 THE MITM DIVERGES: an interposed pub yields a different row — the humans SEE the mismatch and abort.
    if (+p.sc.mitm_diverge === 1) this.story_swear(w, 'an interposed pub changes the row — a relay MITM cannot forge the emoji string because it depends on both endpoint keys so the humans see the mismatch')
    // #3 AGREEMENT IS NON-TRIVIAL: comparing nothing to nothing is refused — the gate is a real check.
    if (+p.sc.empty_refused === 1) this.story_swear(w, 'empty agrees with nothing — comparing two empty rows is refused so the confirmation is a genuine match not a vacuous pass')

// EmojiConfirm_order — float A:EmojiConfirm to the front of H/* so the Run snap stays readable.
async EmojiConfirm_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'EmojiConfirm') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)

// ══ SwarmDivide — the DIVISION substrate: one soul, many role-bearing bodies, and peers routing by role ═══════
//  Division_todo (the imperial realm): a soul is not a device — it inhabits BODIES across machines, each a
//   department by ROLE, one of them the primary (DivisionMaster) at the bare <prepub>.  The substrate
//    (%Body + Swarm_body_* in Ghost/S/Swarm.g) is paradigm-GENERAL — it never names a role; the MUSIC tenant
//     binds 'Captain' (the social hand) and 'Cave' (the serving library) as opaque strings here.  And roles
//      are LOOKED FOR (the owner: "people have to be looking for a certain role"): a friend wanting a stream
//       resolves to the soul's SERVING body, not "the soul" — so the role is peer-visible over a %Pier.
//   beat 2  Alice stands two bodies — Captain at the bare <prepub> (self, the primary) + Cave at <prepub>_1 —
//            plus a third wearing a MADE-UP role ('Frobnicator') to prove the substrate is role-blind
//   beat 3  the routing queries resolve: find Cave → _1, find Captain → bare, primary → the Captain, the
//            made-up role resolves too (paradigm-blind), and an unheld role → null
//   beat 4  a FRIEND (Bob) holds a %Pier carrying Alice's published roster; Swarm_pier_body(pier,'Cave')
//            reaches Alice's Cave ADDRESS (the peer routing — who serves music for Alice), an unpublished
//             role misses, and the primary over the pier is still the Captain at the bare name
//  THE DISCRIMINATION ([[adversarial-test-agent]]): a substrate that branched on 'Cave' would not resolve
//   'Frobnicator'; a router that returned "the soul" would not carry the _1 address; a pick that ignored the
//    bare-first tiebreak would not name the Captain primary.  This is the imperial-realm claim, proven.
//  CONVENTION (Swarm*): the world MUST be named SwarmDivide.

SwarmDivide(A,w):
    w oai %req:wrangle,eternal
        await &SwarmDivide_drive,w,req
        req%ok = 1

SwarmDivide_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

SwarmDivide_note(w, sc):
    let t = this.SwarmDivide_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

async SwarmDivide_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) await this.SwarmDivide_stand(w)
        if (n === 3) this.SwarmDivide_route(w)
        if (n === 4) this.SwarmDivide_peer(w)
        if (n === 5) this.SwarmDivide_wire(w)
    }
    this.SwarmDivide_witness(w)
    await this.SwarmDivide_order(w)

// beat 2 — the soul takes two bodies + a role-blind third.  Fixed keys (seeded) + pinned clock keep the
//  roster byte-repeatable.  The running body is the Captain (self:1) at the bare prepub; the Cave and the
//   Frobnicator are NOTED (other machines' bodies, as a roster hand-off would carry them).
async SwarmDivide_stand(w):
    w i reached:step_2
    w.sc.now = 1751700000
    let acct = w.oai({ Account: 1, of: 'Alice' })
    acct.c.up = w
    let keys = await this.Swarm_mint_keys('SwarmDivide-Alice')
    let alice = this.Swarm_identity(acct, keys, 'Alice')
    w.c.alice = alice
    let bare = alice.sc.prepub
    this.Swarm_body_take(alice, bare, 'Captain', bare)
    this.Swarm_body_note(alice, 'cave_vessel_pub', 'Cave', bare + '_1')
    this.Swarm_body_note(alice, 'frob_vessel_pub', 'Frobnicator', bare + '_2')

// beat 3 — the routing queries over the soul's OWN roster.  Every outcome pinned as one note row; the
//  addresses are compared against the soul's own bare/suffixed names.
SwarmDivide_route(w):
    w i reached:step_3
    let alice = w.c.alice
    if (!alice) return
    let bare = alice.sc.prepub
    let cave = this.Swarm_body_for(alice, 'Cave')
    let cap = this.Swarm_body_for(alice, 'Captain')
    let prim = this.Swarm_body_primary(alice)
    let frob = this.Swarm_body_for(alice, 'Frobnicator')
    let none = this.Swarm_body_for(alice, 'Encoder')
    let row = { routed: 1, roster: '' + this.Swarm_body_roster(alice).length }
    if (cave && cave.sc.address === bare + '_1') row.cave_at_1 = 1
    if (cap && cap.sc.address === bare) row.captain_bare = 1
    if (prim && prim.sc.post === 'Captain' && prim.sc.address === bare) row.primary_captain = 1
    if (frob && frob.sc.address === bare + '_2') row.frob_resolved = 1
    if (none === null) row.encoder_miss = 1
    this.SwarmDivide_note(w, row)

// beat 4 — the PEER routing.  Bob befriends Alice: his %Pier carries Alice's PUBLISHED roster (the %Body
//  rows a replication would hand across).  Bob then asks "who is Alice's Cave" and reaches the ADDRESS —
//   the whole point: a friend routes to the serving body, not to a bare soul id.
SwarmDivide_peer(w):
    w i reached:step_4
    let alice = w.c.alice
    if (!alice) return
    let bare = alice.sc.prepub
    let bacct = w.oai({ Account: 1, of: 'Bob' })
    bacct.c.up = w
    let bkeys = { prepub: 'bob_prepub_000', pub: 'bob_pub_000', key: 'bob_key_000' }
    let bob = this.Swarm_identity(bacct, bkeys, 'Bob')
    let bpeer = this.Swarm_peering(bob)
    let pier = bpeer.i({ Pier: 1, prepub: bare, pub: alice.c.keys.pub })
    pier.c.up = bpeer
    // stamp Alice's published roster onto the pier — what the wire will carry (a later replication slice).
    for (const b of this.Swarm_body_roster(alice)) {
        let pb = pier.i({ Body: 1, pub: b.sc.pub, post: b.sc.post, address: b.sc.address })
        pb.c.up = pier
    }
    let served = this.Swarm_pier_body(pier, 'Cave')
    let primOverPier = this.Swarm_pier_body(pier, 'Captain')
    let missing = this.Swarm_pier_body(pier, 'Librarian')
    let row = { peered: 1 }
    if (served && served.sc.address === bare + '_1') row.serves_at_cave = 1
    if (primOverPier && primOverPier.sc.address === bare) row.captain_over_pier = 1
    if (missing === null) row.unpublished_miss = 1
    this.SwarmDivide_note(w, row)

// beat 5 — the roster crosses the WIRE as plain matter.  Swarm_roster_of publishes it as a scalar payload
//  (no C refs — it snaps and travels, Tier-B grow-only); a FRESH friend (Carol) with an empty pier absorbs
//   it off the wire (Swarm_roster_onto) and then routes to Alice's serving body.  Re-absorb mints no twin.
SwarmDivide_wire(w):
    w i reached:step_5
    let alice = w.c.alice
    if (!alice) return
    let bare = alice.sc.prepub
    let payload = this.Swarm_roster_of(alice)
    let scalar = 1
    for (const e of payload) { if (typeof e.pub !== 'string' || typeof e.post !== 'string' || typeof e.address !== 'string') scalar = 0 }
    let cacct = w.oai({ Account: 1, of: 'Carol' })
    cacct.c.up = w
    let ckeys = { prepub: 'carol_prepub_0', pub: 'carol_pub_0', key: 'carol_key_0' }
    let carol = this.Swarm_identity(cacct, ckeys, 'Carol')
    let cpeer = this.Swarm_peering(carol)
    let pier = cpeer.i({ Pier: 1, prepub: bare, pub: alice.c.keys.pub })
    pier.c.up = cpeer
    let landed = this.Swarm_roster_onto(pier, payload)
    let served = this.Swarm_pier_body(pier, 'Cave')
    this.Swarm_roster_onto(pier, payload)
    let count = pier.o({ Body: 1 }).length
    let row = { wired: 1, payload: '' + payload.length, landed: '' + landed, bodies: '' + count }
    if (scalar === 1) row.scalar = 1
    if (served && served.sc.address === bare + '_1') row.routed_off_wire = 1
    this.SwarmDivide_note(w, row)

// ── the witness — %see gated on TRUTH not beat number (no commas; em-dashes) ──
SwarmDivide_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 4)) return
    let T = this.SwarmDivide_T(w)
    let r = T.o({ routed: 1 })[0]
    if (!r) return
    // #1 THE DEPARTMENTS: the soul's bodies resolve by role — the Cave at its suffix the Captain at the bare
    //  name — a soul is not a device but a roster of role-bearing bodies.
    if (r && +r.sc.cave_at_1 === 1 && +r.sc.captain_bare === 1 && r.sc.roster === '3') this.story_swear(w, 'a soul is a roster of bodies not a device — find the Cave and it is the suffixed body find the Captain and it is the one at the bare name')
    // #2 THE DIVISIONMASTER: the primary is the body at the unsuffixed prepub — the one that holds the bare
    //  address and rosters the rest.
    if (r && +r.sc.primary_captain === 1) this.story_swear(w, 'the primary is the body at the bare name — the DivisionMaster holds the unsuffixed address and the rest wear suffixes')
    // #3 PARADIGM-BLIND: a made-up role resolves exactly as the music ones do and an unheld role misses — the
    //  substrate carries any vocabulary a paradigm brings so the imperial realm generalises beyond music.
    if (r && +r.sc.frob_resolved === 1 && +r.sc.encoder_miss === 1) this.story_swear(w, 'the substrate is paradigm-blind — a made-up role routes exactly as Captain and Cave do and an unheld role finds nothing so the realm generalises past music')
    let p = T.o({ peered: 1 })[0]
    // #4 PEERS ROUTE BY ROLE: a friend carrying the published roster reaches the SERVING body's address — who
    //  serves music for Alice is her Cave at its suffix not a bare soul id — and an unpublished role misses.
    if (p && +p.sc.serves_at_cave === 1 && +p.sc.captain_over_pier === 1 && +p.sc.unpublished_miss === 1) this.story_swear(w, 'a peer routes by the role it needs — carrying the published roster a friend reaches the serving Cave at its own address and an unpublished role finds nothing')
    let ww = T.o({ wired: 1 })[0]
    // #5 THE ROSTER TRAVELS AS PLAIN MATTER: published as a scalar payload (no C refs) it lands on a fresh
    //  friend's pier and routes to the serving body — and re-absorbing mints no twin — so who-serves-music
    //   crosses the wire, not just a same-process stamp.
    if (ww && +ww.sc.scalar === 1 && +ww.sc.routed_off_wire === 1 && ww.sc.payload === '3' && ww.sc.bodies === '3') this.story_swear(w, 'the roster travels as plain matter — published as a scalar payload it lands on a fresh friend pier and routes to the serving body and re-absorbing mints no twin')

// SwarmDivide_order — float A:SwarmDivide to the front of H/* so the Run snap stays readable.
async SwarmDivide_order(w):
    let As = H.o({A: 1})
    if (!As.length) return
    let first = (a) => (a.sc.A === 'SwarmDivide') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)

// ══ SwarmBody — the body key + the COMPUTED self + the vessel subnet (Division_todo step 1) ══════════════
//  Division_todo §ATOMS: a Body is (store × soul), and its durable identity is its own BODY KEY — minted
//   once per soul per store, never replicated.  The row a body takes is keyed by that key's pub, NOT the
//    soul prepub (one soul wears many bodies), and WHICH ROW IS ME is COMPUTED from the key, never a
//     stored `self:1` flag — because a stored flag would REPLICATE and a friend absorbing the roster would
//      then read MY self bit and mistake its own body for my Captain (the §STORAGE hazard this fixes).
//   beat 2  Alice mints a body key + takes her own body with NO explicit pub → the row is keyed by the
//            body key; ensure() honours the cache (idempotent); a second soul in the same store mints its
//             OWN key; Swarm_body_mine finds the row by pub-match and NO self flag rides it
//   beat 3  a FRIEND (Bob) absorbs Alice's published roster — his own body_mine is HIS body not Alice's
//            (the computed self is body-local) and no absorbed row carries a self flag (it never existed)
//   beat 4  the Vessel table's pure ordering — Swarm_vessel_pick picks the bare address first then
//            ascends the suffixes (an individual's local subnet has a deterministic primary), [] → null
//   beat 5  a REMINT is SEEN — minting a key while the division already stands keyed stamps
//            caveat:remint on the fresh row (Rema) while a virgin soul mints clean (Vera)
//   beat 6  the %OWED ledger — a frame that could not go stands as a debt on the counterparty row,
//            deduped by kind, cap-8-loud, paid detaches, the frame itself never stored
//   beat 7  the FAMILY DERIVES FROM THE GRANTS — a Captain reads its Cave off its own signature, a
//            Linkee reads its role+name off the husk, no phantom member, a foreign signature confers nothing
//   beat 8  the HEAL APPLIED — converges the roster on the grants + the Seat attests: member seated,
//            unbacked junk retired (gap-Captain survives), caveat retired, ghost dropped, charter signed;
//            and the FOUNDING SELF-GRANT (§0a "A") — a divided huskless Seat signs its own MyCaptain
//   beat 9  FAMILY GRANTS REPLICATE — the soul-signed atoms travel to a sibling (self-verifying), which
//            derives the captaincy it never witnessed; a retargeted atom refuses, an unsigned relic stays home
//   beat 10 THE %REACH primitive — one durable addressed cross-body intent (the foam layer): book stands,
//            routes off the family, an offline dispatch leaves it standing, target hears→serves→arrives→graduates
//  THE DISCRIMINATION: a row keyed by the soul prepub would fail keyed_by_bodykey; a stored self:1 would
//   show up on the friend's absorbed copy; a pick that ignored the bare-first tiebreak would not name the
//    primary.  This is step 1 of the field, proven off pure matter (no Dexie — the adapter is production).
//  CONVENTION (Swarm*): the world MUST be named SwarmBody.

SwarmBody(A,w):
    w oai %req:wrangle,eternal
        await &SwarmBody_drive,w,req
        req%ok = 1

SwarmBody_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

SwarmBody_note(w, sc):
    let t = this.SwarmBody_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

async SwarmBody_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) { await this.SwarmBody_stand(w) }
        if (n === 3) { this.SwarmBody_friend(w) }
        if (n === 4) { this.SwarmBody_subnet(w) }
        if (n === 5) { this.SwarmBody_remint(w) }
        if (n === 6) { this.SwarmBody_owed(w) }
        if (n === 7) { this.SwarmBody_family(w) }
        if (n === 8) { await this.SwarmBody_heal(w) }
        if (n === 9) { await this.SwarmBody_replicate(w) }
        if (n === 10) { await this.SwarmBody_reach(w) }
        if (n === 11) { await this.SwarmBody_reach_ack(w) }
        if (n === 12) { await this.SwarmBody_reach_road(w) }
        if (n === 13) { await this.SwarmBody_reach_crew(w) }
        if (n === 14) { await this.SwarmBody_organ(w) }
        if (n === 15) { await this.SwarmBody_organ_wire(w) }
        if (n === 16) { await this.SwarmBody_reach_cap(w) }
        if (n === 17) { await this.SwarmBody_reach_sweep(w) }
        if (n === 18) { await this.SwarmBody_reach_dead(w) }
        if (n === 19) { await this.SwarmBody_reach_latch(w) }
        if (n === 20) { await this.SwarmBody_reach_zombie(w) }
        if (n === 21) { await this.SwarmBody_reach_auth(w) }
        if (n === 22) { await this.SwarmBody_reach_doer(w) }
        if (n === 23) { await this.SwarmBody_reach_pump(w) }
    }
    this.SwarmBody_witness(w)
    await this.SwarmBody_order(w)

// beat 2 — the body key IS the row's identity.  Fixed seeds + pinned clock keep it byte-repeatable.  The
//  key is minted onto .c directly (deterministic, no Dexie in a Book); ensure() then returns the cache.
async SwarmBody_stand(w):
    w i reached:step_2
    w.sc.now = 1751700000
    let acct = w.oai({ Account: 1, of: 'Alice' })
    acct.c.up = w
    let keys = await this.Swarm_mint_keys('SwarmBody-Alice')
    let alice = this.Swarm_identity(acct, keys, 'Alice')
    w.c.alice = alice
    let bare = alice.sc.prepub
    alice.c.bodykey = await this.Swarm_mint_keys('SwarmBody-Alice-body')
    let k1 = this.Swarm_body_key(alice)
    let k2 = await this.Swarm_body_key_ensure(alice)
    // a SECOND soul in the SAME store gets its OWN body key — one per (store × soul).
    let zkeys = await this.Swarm_mint_keys('SwarmBody-Zoe')
    let zoe = this.Swarm_identity(acct, zkeys, 'Zoe')
    zoe.c.bodykey = await this.Swarm_mint_keys('SwarmBody-Zoe-body')
    let kz = this.Swarm_body_key(zoe)
    // take Alice's own body with NO explicit pub — it must key by the body key, not the soul prepub.
    let body = this.Swarm_body_take(alice, null, 'Captain', bare)
    let mine = this.Swarm_body_mine(alice)
    let row = { stood: 1 }
    if (body && String(body.sc.pub) === String(k1.pub)) { row.keyed_by_bodykey = 1 }
    if (body && String(body.sc.pub) !== String(bare)) { row.not_soul_keyed = 1 }
    if (k1 && k2 && String(k1.pub) === String(k2.pub)) { row.bodykey_durable = 1 }
    if (kz && k1 && String(kz.pub) !== String(k1.pub)) { row.per_soul_bodykey = 1 }
    if (mine && body && mine === body) { row.mine_is_computed = 1 }
    if (body && !body.sc.self) { row.no_self_flag = 1 }
    this.SwarmBody_note(w, row)

// beat 3 — the computed self is body-LOCAL.  Bob takes his own body, then absorbs Alice's published
//  roster onto his %Pier.  His body_mine is HIS row (pub-match against his own key); no pier row carries
//   a self flag (Swarm_roster_of never carried one, because Swarm_body_take never writes one).
SwarmBody_friend(w):
    w i reached:step_3
    let alice = w.c.alice
    if (!alice) { return }
    let bare = alice.sc.prepub
    let bacct = w.oai({ Account: 1, of: 'Bob' })
    bacct.c.up = w
    let bkeys = { prepub: 'bob_prepub_000', pub: 'bob_pub_00000000', key: 'bob_key_000' }
    let bob = this.Swarm_identity(bacct, bkeys, 'Bob')
    bob.c.bodykey = { pub: 'bob_body_pub_00', key: 'bob_body_key_00', prepub: 'bob_body_pre' }
    this.Swarm_body_take(bob, null, 'Captain', 'bob_prepub_000')
    let bpeer = this.Swarm_peering(bob)
    let pier = bpeer.i({ Pier: 1, prepub: bare, pub: alice.c.keys.pub })
    pier.c.up = bpeer
    let payload = this.Swarm_roster_of(alice)
    this.Swarm_roster_onto(pier, payload)
    let bmine = this.Swarm_body_mine(bob)
    let anyself = 0
    for (const pb of pier.o({ Body: 1 })) { if (pb.sc.self) { anyself = 1 } }
    let aliceself = 0
    for (const ab of this.Swarm_body_roster(alice)) { if (ab.sc.self) { aliceself = 1 } }
    let row = { friended: 1, absorbed: '' + pier.o({ Body: 1 }).length }
    if (bmine && String(bmine.sc.address) === 'bob_prepub_000') { row.bob_mine_is_bob = 1 }
    if (bmine && bmine.sc.post === 'Captain' && String(bmine.sc.pub) === 'bob_body_pub_00') { row.bob_mine_bodykey = 1 }
    if (anyself === 0) { row.no_self_on_pier = 1 }
    if (aliceself === 0) { row.no_self_at_source = 1 }
    this.SwarmBody_note(w, row)

// beat 4 — the Vessel table's pure ordering (no Dexie in a Book; the adapter is production-only): the
//  primary is the bare address, then the suffixes ascend, and an empty subnet picks nothing.
SwarmBody_subnet(w):
    w i reached:step_4
    let alice = w.c.alice
    if (!alice) { return }
    let bare = alice.sc.prepub
    let rows = [{ address: bare + '_2' }, { address: bare }, { address: bare + '_1' }]
    let prim = this.Swarm_vessel_pick(rows, bare)
    let suffixed = this.Swarm_vessel_pick([{ address: bare + '_3' }, { address: bare + '_1' }], bare)
    let empty = this.Swarm_vessel_pick([], bare)
    let row = { subnetted: 1 }
    if (prim && String(prim.address) === String(bare)) { row.primary_is_bare = 1 }
    if (suffixed && String(suffixed.address) === bare + '_1') { row.suffix_ascends = 1 }
    if (empty === null) { row.empty_null = 1 }
    this.SwarmBody_note(w, row)

// ── the witness — %see gated on TRUTH not beat number (no commas; em-dashes) ──
SwarmBody_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 2)) { return }
    let T = this.SwarmBody_T(w)
    let s = T.o({ stood: 1 })[0]
    if (!s) { return }
    // #1 THE BODY KEY IS THE ROW'S IDENTITY: keyed by the body key not the soul — one soul wears many bodies.
    if (s && +s.sc.keyed_by_bodykey === 1 && +s.sc.not_soul_keyed === 1) { this.story_swear(w, 'a body row is keyed by its own body key not the soul — one soul wears many bodies so the durable per-body key is what a roster row IS') }
    // #2 DURABLE + ONE-PER-SOUL: ensure honours the cache and a second soul in the same store mints its own.
    if (s && +s.sc.bodykey_durable === 1 && +s.sc.per_soul_bodykey === 1) { this.story_swear(w, 'the body key is durable and one per soul per store — ensure honours the cache and a second soul in the same store mints a key of its own') }
    // #3 SELF IS COMPUTED NOT STORED: body_mine finds me by the key and the mint writes no self bit.
    if (s && +s.sc.mine_is_computed === 1 && +s.sc.no_self_flag === 1) { this.story_swear(w, 'which row is me is computed from the body key never a stored flag — the mint writes no self bit onto the row so nothing false can replicate') }
    let f = T.o({ friended: 1 })[0]
    // #4 THE COMPUTED SELF IS BODY-LOCAL: a friend computes ITS OWN body as self and no self flag crossed.
    if (f && +f.sc.bob_mine_is_bob === 1 && +f.sc.bob_mine_bodykey === 1 && +f.sc.no_self_on_pier === 1 && +f.sc.no_self_at_source === 1) { this.story_swear(w, 'the self answer is body-local — a friend absorbing the roster computes its own body as self and no self flag ever crossed the wire') }
    let sub = T.o({ subnetted: 1 })[0]
    // #5 THE VESSEL SUBNET ORDERS BARE-FIRST: a deterministic primary then ascending suffixes and empty → null.
    if (sub && +sub.sc.primary_is_bare === 1 && +sub.sc.suffix_ascends === 1 && +sub.sc.empty_null === 1) { this.story_swear(w, 'the vessel subnet picks the bare address first then ascends the suffixes — an individual local subnet has a deterministic primary and an empty one picks nothing') }
    let rm = T.o({ reminted: 1 })[0]
    // #6 A REMINT IS SEEN: minting while the division stands keyed stamps caveat:remint; a virgin mints clean.
    if (rm && +rm.sc.caveat_stands === 1 && +rm.sc.old_seat_kept === 1 && +rm.sc.virgin_clean === 1 && +rm.sc.no_caveat_on_virgin === 1) { this.story_swear(w, 'a reminted body wears its caveat — minting a key while the division already stands keyed stamps remint onto the fresh row and keeps the old seat standing while a virgin soul mints clean — a fork is seen never silently absorbed') }
    let ow = T.o({ owed: 1 })[0]
    // #7 A MISSED FRAME STANDS AS DEBT: deduped by kind — paid does not stand — the cap folds loudly and its evidence survives.
    if (ow && +ow.sc.deduped === 1 && +ow.sc.at_pinned === 1 && +ow.sc.paid_gone === 1 && +ow.sc.capped_loud === 1 && +ow.sc.overflow_survives === 1) { this.story_swear(w, 'a frame that could not go stands as a debt on the counterparty row — deduped by kind so retries cannot grow it — a paid debt detaches and an empty shelf removes itself — the cap folds overflow into a dropped count that outlives full payment') }
    let fm = T.o({ familied: 1 })[0]
    // #8 THE FAMILY DERIVES FROM THE GRANTS: the ceremony instant stops mattering — Captain reads its Cave off its own signature — the husk names ME not a phantom — foreign signatures confer nothing.
    if (fm && +fm.sc.captain_sees_cave === 1 && +fm.sc.cave_page_named === 1 && +fm.sc.husk_is_me === 1 && +fm.sc.husk_keeps_my_name === 1 && +fm.sc.no_phantom_member === 1 && +fm.sc.foreign_sign_ignored === 1) { this.story_swear(w, 'the family derives from the standing grants at any time — a captain reads its cave off its own live signature and a linkee reads its own role and kept name off the husk — the soul never appears as a phantom member and a foreign signature confers nothing') }
    let hl = T.o({ healed: 1 })[0]
    // #9 THE HEAL CONVERGES AND THE SEAT ATTESTS: granted rows stand — unbacked ones retire (except the founding-gap captain) — the vouched caveat and the pre-key ghost leave — the charter lists exactly the standing division — a settled family heals to no change.
    if (hl && +hl.sc.heal_ran === 1 && +hl.sc.own_row_seated === 1 && +hl.sc.member_from_grant === 1 && +hl.sc.caveat_retired === 1 && +hl.sc.junk_retired === 1 && +hl.sc.gap_captain_survives === 1 && +hl.sc.ghost_dropped === 1 && +hl.sc.no_charter_minted === 1 && +hl.sc.settled_idempotent === 1) { this.story_swear(w, 'the heal converges the roster on the standing links and every body is its own address — no seat column survives while unbacked junk retires and the founding-gap captain survives — a living link retires the fork caveat and the pre-key ghost drops — no charter is minted for the roster is not a document — and a settled family heals to no change') }
    // #10 THE FOUNDER'S CAPTAINCY IS A STAMP (§0a #3 self-husk pier, mint-stop 2026-09-02): a divided
    //  huskless Seat stamps its own self-husk pier `link, post:Captain` — same chrysalis shape as
    //   every other link rail, no grant minted.
    if (hl && +hl.sc.founding_stamp_stands === 1 && +hl.sc.self_husk_pier === 1) { this.story_swear(w, 'the founder signs its own captaincy — a divided seat holding no husk stamps link post Captain onto its self-husk pier at the heal so every post including the captain derives from a standing stamp and the founder-inference decays to a fallback') }
    let rp = T.o({ replicated: 1 })[0]
    // #11 THE FAMILY'S VIEW TRAVELS (mint-stop): plain roster rows ride the roster frame — a VIEW that
    //  grow-only unions; proof stays at the voucher door, and neither relic grants nor stamps travel.
    if (rp && +rp.sc.roster_rode === 1 && +rp.sc.union_grows_only === 1 && +rp.sc.relic_stayed_home === 1 && +rp.sc.sibling_sees_captain === 1 && +rp.sc.stamp_stayed_home === 1) { this.story_swear(w, 'the roster mile replicates the family between siblings — plain rows union grow-only so a sibling sees the captain it never witnessed while the unsigned relic and the chrysalis stamp both stay home and proof lives at the voucher door') }
    let rc = T.o({ reached: 1 })[0]
    // #12 THE CROSS-BODY REACH primitive: one durable addressed intent that the five hand-rolled dialects collapse into.
    if (rc && +rc.sc.booked_stands === 1 && +rc.sc.addr_resolves === 1 && +rc.sc.offline_stands === 1 && +rc.sc.idempotent === 1 && +rc.sc.heard_serving === 1 && +rc.sc.doer_gates === 1 && +rc.sc.served_arrived === 1 && +rc.sc.graduated === 1) { this.story_swear(w, 'a reach is one durable addressed intent — it books and stands as legible matter routed off the family charter — an offline dispatch leaves the intent standing rather than minting a separate debt — and the target hears it serves it through its own doer marks it arrived and it graduates away') }
    let ac = T.o({ acked: 1 })[0]
    // #13 THE REACH ROUND-TRIP: the settle loop observes until the knob flips — the booker hears the outcome — success graduates and refusal stands.
    if (ac && +ac.sc.knob_off_observes === 1 && +ac.sc.knob_on_settles === 1 && +ac.sc.round_trip === 1 && +ac.sc.refused_stands === 1) { this.story_swear(w, 'the reach settle loop observes until its knob is flipped — then the booker hears the outcome and closes the trip — an arrived reach graduates away while a refused one stands as a visible receipt') }
    let rd = T.o({ roaded: 1 })[0]
    // #14 THE WIRE LANE IS GATED ON THE ROSTER: only my own soul's body books work on me — a stranger lands nothing — and the outcome reports back to the booker's rostered seat.
    if (rd && +rd.sc.kin_admitted === 1 && +rd.sc.stranger_refused === 1 && +rd.sc.report_resolves === 1) { this.story_swear(w, 'the reach wire lane is gated on the roster — a rostered sibling books work on me while a stranger lands nothing — and the outcome reports back to the seat the roster names for the booker') }
    let cw = T.o({ crewed: 1 })[0]
    // #15 THE CREW READ: the standing reaches project into one legible glance — tallied by state — the multi-body activity made readable.
    if (cw && +cw.sc.tallies_total === 1 && +cw.sc.tallies_states === 1 && +cw.sc.entry_shape === 1) { this.story_swear(w, 'the crew read projects the standing reaches into one legible glance — tallied by state with each intent carrying what it is and who it is for — so what the whole crew is doing reads at once instead of hiding across the ghosts') }
    let og = T.o({ organed: 1 })[0]
    // #16 THE %ORGAN readout: a body describes the organ it grows — pocket and trove as quantities on its own row.
    if (og && +og.sc.pocket_stood === 1 && +og.sc.trove_stood === 1 && +og.sc.idempotent_updated === 1 && +og.sc.read_by_kind === 1) { this.story_swear(w, 'a body describes the organ it grows — a pocket of what it wants now and a trove of everything as quantities on its own row — re-describing updates in place and each organ reads back by its kind') }
    let orw = T.o({ organ_wired: 1 })[0]
    // #17 ORGAN REPLICATION: a body's pocket/trove sizes travel to a sibling so the phone sees the laptop's trove.
    if (orw && +orw.sc.wire_shape === 1 && +orw.sc.sibling_organ_seen === 1 && +orw.sc.stray_skipped === 1) { this.story_swear(w, 'a body ships its own organ sizes and a sibling lands them onto the roster row they describe — so the phone sees the laptop trove — while an organ for a body it does not roster lands nothing') }
    let cap = T.o({ capped: 1 })[0]
    // #18 REACH BACKPRESSURE: a new booking beyond the cap is refused while a re-book of a standing reach is always honoured.
    if (cap && +cap.sc.under_cap_booked === 1 && +cap.sc.over_cap_refused === 1 && +cap.sc.rebook_honoured === 1) { this.story_swear(w, 'the reach shelf is bounded — a new booking beyond the cap is refused so a runaway loop cannot flood it — while re-booking a reach that already stands is always honoured so a retry is never lost') }
    let sw = T.o({ swept: 1 })[0]
    // #19 REFUSED RECEIPTS AGE OUT: a stale refused receipt is swept so it can't fill the cap; a fresh one survives.
    if (sw && +sw.sc.stale_swept === 1 && +sw.sc.fresh_survives === 1) { this.story_swear(w, 'a refused receipt ages out — the settle loop sweeps one older than its window so dead receipts cannot fill the cap — while a fresh refusal still stands for its moment to be seen') }
    let dd = T.o({ deaded: 1 })[0]
    // #20 THE THIRD EXIT (proving beat): a want past its deadline settles dead nobody-answered — the only exit besides landed and refused so it can never hang silent — while a want with no deadline stands forever.
    if (dd && +dd.sc.deadline_dies === 1 && +dd.sc.dead_at_pinned === 1 && +dd.sc.no_deadline_stands === 1) { this.story_swear(w, 'a want past its deadline settles dead — nobody answered — the third and only other exit besides landed and refused so a standing want can never hang silent — while a want with no deadline stands forever as the durable cross-body booking and the dead receipt is clocked by the world not the wall') }
    let lt = T.o({ latched: 1 })[0]
    // #21 THE TERMINAL LATCH (proving beat): first terminal wins and a landing outranks a refusal — a racing refusal cannot bury an arrived under a multi-path fan.
    if (lt && +lt.sc.landed_survives_refusal === 1 && +lt.sc.refusal_upgrades_to_landed === 1 && +lt.sc.first_terminal_wins === 1) { this.story_swear(w, 'a landed reach outranks a refusal so a racing refusal from a body that could not serve can never bury the one that did — a refusal upgrades when the holder later lands — and at equal rank the first terminal wins so a dead ack cannot flip a standing refused') }
    let zb = T.o({ zombied: 1 })[0]
    // #22 THE TERMINAL GUARD (proving beat): a settled reach never re-dispatches — dispatch refuses refused and dead alike while a booked one still resolves — so a receipt cannot flip back to dispatched and dodge its sweep.
    if (zb && +zb.sc.refused_guarded === 1 && +zb.sc.dead_guarded === 1 && +zb.sc.booked_dispatches === 1 && +zb.sc.settle_skips_terminals === 1) { this.story_swear(w, 'a settled reach never re-dispatches — dispatch refuses a refused and a dead one alike while a booked one still resolves its address — so the settle loop skips both failure terminals and a receipt can never flip itself back to dispatched and dodge its own sweep') }
    let au = T.o({ authed: 1 })[0]
    // #23 THE PIER-LESS REACH AUTH (proving beat): admission needs a valid soul-signed voucher — my own soul and a sealed friend pass while no voucher a tampered signature and an unknown soul each land nothing.
    if (au && +au.sc.own_soul_admitted === 1 && +au.sc.no_voucher_rejected === 1 && +au.sc.tampered_rejected === 1 && +au.sc.stranger_rejected === 1 && +au.sc.sealed_friend_admitted === 1) { this.story_swear(w, 'a reach admitted with no sealed pier needs a valid soul-signed voucher — a body of my own soul passes and a sealed friend passes while a frame with no voucher a tampered signature or an unknown soul each lands nothing — so a forged settle cannot land on the untrusted relay') }
    let dr = T.o({ doered: 1 })[0]
    // #24 THE DOER CONTRACT (proving beat): placed | not-yet | provably-cannot — a missing handler refuses no_handler instead of auto-landing — a throw stays serving but loud — the named why crosses the wire guarded.
    if (dr && +dr.sc.no_handler_refuses === 1 && +dr.sc.refusal_named === 1 && +dr.sc.throw_not_terminal_but_loud === 1 && +dr.sc.controls_hold === 1 && +dr.sc.why_crosses_guarded === 1) { this.story_swear(w, 'the doer answers in the req machine\'s three postures — placed lands it and not-yet leaves it serving while provably-cannot refuses with a named why — a missing handler refuses no handler instead of auto-landing the lie — a throw is never terminal but leaves a loud rebuff — and the why crosses the wire to the booker while an ack without one stamps nothing') }
    let pm = T.o({ pumped: 1 })[0]
    // #25 THE ONE PUMP (proving beat): self-throttling single entry — hygiene runs knob-off, the knob gates action only.
    if (pm && +pm.sc.sweeps_while_observing === 1 && +pm.sc.self_throttles === 1 && +pm.sc.knob_on_dispatches === 1) { this.story_swear(w, 'the reach pump is one self-throttling entry any driver may call — a second call inside its cadence no-ops — it sweeps stale receipts even while the settle knob leaves the ledger observing because the knob gates action never hygiene — and with the knob on the same entry dispatches the standing wants') }

// beat 5 — REMINT-NOT-READ is SEEN (Statehome_todo debts: "a fork must be seen").  The sanctioned join
//  paths (adopt, the ferry become) HAND the body key over before ensure can mint, so a mint while the
//   division already stands keyed means this store lost its durable key — the fresh row may double an
//    old seat.  The caveat stamps the fresh row as a STANDING fact (snapped, provable); a virgin soul
//     (no keyed roster) mints clean.  Pure C-matter — ensure's Dexie adapter is production-only; the
//      Book proves the decision, not the IO (the beat-2/beat-4 stance).
SwarmBody_remint(w):
    w i reached:step_5
    let acct = w.oai({ Account: 1, of: 'Alice' })
    // Rema: her division ALREADY stands keyed (an old seat in the roster) but this store holds no key.
    let rkeys = { prepub: 'rema_prepub_000', pub: 'rema_pub_00000000', key: 'rema_key_000' }
    let rema = this.Swarm_identity(acct, rkeys, 'Rema')
    this.Swarm_body_note(rema, 'rema_old_body_pub', 'Captain', 'rema_prepub_000', 'OldSeat')
    let fresh = this.Swarm_body_remint_caveat(rema, 'rema_new_body_pub')
    // Vera: a VIRGIN soul — no keyed roster, so her mint is clean and stamps nothing.
    let vkeys = { prepub: 'vera_prepub_000', pub: 'vera_pub_00000000', key: 'vera_key_000' }
    let vera = this.Swarm_identity(acct, vkeys, 'Vera')
    let clean = this.Swarm_body_remint_caveat(vera, 'vera_new_body_pub')
    let row = { reminted: 1 }
    if (fresh && fresh.sc.caveat === 'remint') { row.caveat_stands = 1 }
    if (fresh && this.Swarm_body_roster(rema).length === 2) { row.old_seat_kept = 1 }
    if (clean === null) { row.virgin_clean = 1 }
    if (!this.Swarm_body_roster(vera).filter((b) => b.sc.caveat).length) { row.no_caveat_on_virgin = 1 }
    this.SwarmBody_note(w, row)

// beat 6 — THE %OWED LEDGER (Statehome_todo debts: a bounded debt hung on the counterparty's OWN row).
//  A frame that did not go used to vanish into per-tick re-fire noise (the eed storm); now the miss
//   STANDS as `Owed/owe:<kind>` on the very row the relationship lives on — a %Body sibling and a
//    %Pier friend take the same shape.  Proven pure (the note/paid verbs; the live wiring — deliver
//     misses noting and the presence-edge settle — is station-gated, the beat-5 stance).
SwarmBody_owed(w):
    w i reached:step_6
    let alice = w.c.alice
    if (!alice) { return }
    let body = this.Swarm_body_roster(alice)[0]
    let bacct = w.oai({ Account: 1, of: 'Bob' })
    let bob = bacct.o({ Identity: 1 })[0]
    let pier = bob ? this.Swarm_peering(bob).o({ Pier: 1 })[0] : null
    if (!body || !pier) { return }
    let row = { owed: 1 }
    // note stands + DEDUP: the same kind re-noted refreshes rather than grows.
    this.Swarm_owed_note(w, body, 'repli_ready')
    this.Swarm_owed_note(w, body, 'repli_ready')
    let shelf = body.o({ Owed: 1 })[0]
    if (shelf && shelf.o({ owe: 1 }).length === 1) { row.deduped = 1 }
    if (shelf && shelf.o({ owe: 'repli_ready' })[0] && +shelf.o({ owe: 'repli_ready' })[0].sc.at === 1751700000) { row.at_pinned = 1 }
    // PAID does not stand: the item detaches and the empty shelf removes itself.
    this.Swarm_owed_paid(body, 'repli_ready')
    if (!body.o({ Owed: 1 }).length) { row.paid_gone = 1 }
    // the CAP is loud never silent: 9 distinct kinds on the pier → 8 stand + dropped=1 folds visibly.
    for (const k of ['k1', 'k2', 'k3', 'k4', 'k5', 'k6', 'k7', 'k8', 'k9']) { this.Swarm_owed_note(w, pier, k) }
    let pshelf = pier.o({ Owed: 1 })[0]
    if (pshelf && pshelf.o({ owe: 1 }).length === 8 && +pshelf.sc.dropped === 1) { row.capped_loud = 1 }
    // a shelf with overflow evidence SURVIVES full payment — the drop stays seen.
    for (const k of ['k1', 'k2', 'k3', 'k4', 'k5', 'k6', 'k7', 'k8']) { this.Swarm_owed_paid(pier, k) }
    pshelf = pier.o({ Owed: 1 })[0]
    if (pshelf && !pshelf.o({ owe: 1 }).length && +pshelf.sc.dropped === 1) { row.overflow_survives = 1 }
    this.SwarmBody_note(w, row)

// beat 7 — THE FAMILY DERIVES FROM THE GRANTS (the owner's live failure: "both tabs are eed, know Gri…
//  like you didn't do anything").  The division is re-derivable at ANY time from the standing cross-
//   signed My<Post> grants — pure, so a botched ceremony instant stops mattering.  Four truths:
//    CAPTAIN side (Hera): a live Grant:MyCave BY me FOR a pier's page → that page is my Cave, wearing
//     the pier's friendly as its instance name.  LINKEE side (the husk): a by-me grant FOR my own
//      body-key pub → MY role + MY instance name, never a second member — even when the same grant
//       rides the redeem pier whose page is the SOUL itself (the phantom-member trap).  A grant signed
//        by a FOREIGN key confers nothing.  A revoked (%NotGrant) grant confers nothing.
SwarmBody_family(w):
    w i reached:step_7
    let acct = w.oai({ Account: 1, of: 'Alice' })
    // ── Hera the CAPTAIN: her pier for Gwen carries her own MyCave grant ──
    let hkeys = { prepub: 'hera_prepub_0000', pub: 'hera_prepub_0000_full_pub_00000', key: 'hera_key' }
    let hera = this.Swarm_identity(acct, hkeys, 'Hera')
    hera.c.bodykey = { pub: 'hera_body_pub_00', key: 'hbk', prepub: 'hera_body_pre' }
    let hp = this.Swarm_peering(hera)
    let gpier = hp.i({ Pier: 1, pub: 'gwen_prepub_0000', friendly: 'Gwen' })
    gpier.c.up = hp
    let gpage = gpier.i({ Peering: 1, pub: 'gwen_prepub_0000_full_pub_00000' })
    gpage.c.up = gpier
    let gg = gpier.i({ Grant: 'MyCave', by: 'hera_prepub_0000', for: 'gwen_prepub_0000' })
    gg.c.up = gpier
    // a FOREIGN-signed My* grant on another pier confers nothing
    let xpier = hp.i({ Pier: 1, pub: 'xena_prepub_0000', friendly: 'Xena' })
    xpier.c.up = hp
    let xg = xpier.i({ Grant: 'MyCave', by: 'stranger_pub_000', for: 'xena_prepub_0000' })
    xg.c.up = xpier
    let hfam = this.Swarm_family_derive(hera)
    // ── Gwen the LINKEE (post-become): holds the soul key; her huskiness rides TWO piers ──
    let wkeys = { prepub: 'wsoul_prepub_000', pub: 'wsoul_prepub_000_full_pub_00000', key: 'wsoul_key' }
    let wsoul = this.Swarm_identity(acct, wkeys, 'Wanda')
    wsoul.c.bodykey = { pub: 'gril_prepub_0000_full_pub_00000', key: 'glk', prepub: 'gril_prepub_0000' }
    let wp = this.Swarm_peering(wsoul)
    // her ceremony husk: the soul's pier FOR her old identity (imported with the account)
    let hup = wp.i({ Pier: 1, pub: 'gril_prepub_0000', friendly: 'Gril' })
    hup.c.up = wp
    let hpage = hup.i({ Peering: 1, pub: 'gril_prepub_0000_full_pub_00000' })
    hpage.c.up = hup
    let hg = hup.i({ Grant: 'MyCave', by: 'wsoul_prepub_000', for: 'gril_prepub_0000' })
    hg.c.up = hup
    // the PHANTOM trap: the same grant riding her old redeem pier, whose page is the SOUL itself
    let rpier = wp.i({ Pier: 1, pub: 'wsoul_prepub_000', friendly: 'Wanda' })
    rpier.c.up = wp
    let rpage = rpier.i({ Peering: 1, pub: 'wsoul_prepub_000_full_pub_00000' })
    rpage.c.up = rpier
    let rg = rpier.i({ Grant: 'MyCave', by: 'wsoul_prepub_000', for: 'gril_prepub_0000' })
    rg.c.up = rpier
    let wfam = this.Swarm_family_derive(wsoul)
    let row = { familied: 1 }
    if (hfam.length === 1 && hfam[0].post === 'Cave' && hfam[0].husk === 0) { row.captain_sees_cave = 1 }
    if (hfam.length === 1 && hfam[0].pub === 'gwen_prepub_0000_full_pub_00000' && hfam[0].name === 'Gwen') { row.cave_page_named = 1 }
    if (wfam.length === 1 && wfam[0].husk === 1 && wfam[0].post === 'Cave') { row.husk_is_me = 1 }
    if (wfam.length === 1 && wfam[0].name === 'Gril') { row.husk_keeps_my_name = 1 }
    if (!wfam.some((e) => e.pub === 'wsoul_prepub_000_full_pub_00000')) { row.no_phantom_member = 1 }
    if (!hfam.some((e) => e.pub && e.pub.indexOf('xena') === 0)) { row.foreign_sign_ignored = 1 }
    this.SwarmBody_note(w, row)

// beat 8 — THE HEAL APPLIED (the ceremony OUTCOME made durable): Swarm_family_heal converges the
//  roster on the standing grants and the Seat attests the result.  Hana (real seeded keys — the
//   charter must really sign) stands as Seat with one granted Cave (Kavi — pre-noted wearing a
//    caveat:remint) plus three impostors: an unbacked junk row (retires), a grantless CAPTAIN row
//     (survives — the founding-grant gap guard) and the pre-key ghost (drops).  The consenter
//      puppet (InvWalk's seam) raises the gate for exactly the heal call.  A second heal on the
//       settled family returns 0 — the trickle costs nothing once converged.
async SwarmBody_heal(w):
    w i reached:step_8
    let acct = w.oai({ Account: 1, of: 'Alice' })
    let hkeys = await this.Swarm_mint_keys('SwarmBody-Hana')
    let hana = this.Swarm_identity(acct, hkeys, 'Hana')
    hana.c.bodykey = await this.Swarm_mint_keys('SwarmBody-Hana-body')
    let bare = String(hana.sc.prepub)
    let mypub = String(hana.c.bodykey.pub)
    let hp = this.Swarm_peering(hana)
    // the granted Cave: pier + page + a live MyCave grant BY the soul FOR Kavi (the page carries the full pub)
    let kpier = hp.i({ Pier: 1, pub: 'kavi_prepub_0000', friendly: 'Kavi' })
    kpier.c.up = hp
    let kpage = kpier.i({ Peering: 1, pub: 'kavi_prepub_0000_full_pub_00000' })
    kpage.c.up = kpier
    let kg = kpier.i({ Grant: 'MyCave', by: bare, for: 'kavi_prepub_0000' })
    kg.c.up = kpier
    // Kavi's row pre-stands at _1 WEARING the fork-suspicion — the living grant must retire it
    let krow = this.Swarm_body_note(hana, 'kavi_prepub_0000_full_pub_00000', 'Cave', bare + '_1', 'Kavi')
    krow.sc.caveat = 'remint'
    krow.bump()
    // the three impostors: unbacked junk / the founding-gap captain / the pre-key ghost
    this.Swarm_body_note(hana, 'junk_body_pub_0000', 'Cave', bare + '_2', 'Junky')
    this.Swarm_body_note(hana, 'gapcap_body_pub_00', 'Captain', bare + '_3', 'GapCap')
    this.Swarm_body_note(hana, bare, 'Captain', bare)
    // the consenter puppet: raised for exactly the heal (dropped before the beat's read-back)
    let top = this.top_House()
    if (top && top.c) { top.c.consenter = 1 }
    let healed = await this.Swarm_family_heal(w, hana)
    let healed2 = await this.Swarm_family_heal(w, hana)
    if (top && top.c) { delete top.c.consenter }
    let roster = this.Swarm_body_roster(hana)
    let own = roster.find((b) => String(b.sc.pub) === mypub)
    let kavi = roster.find((b) => String(b.sc.pub) === 'kavi_prepub_0000_full_pub_00000')
    let ch = hp.o({ Charter: 1 })[0]
    let listed = ch ? this.Swarm_charter_parse(ch.sc.payload) : []
    // §0a #3 (mint-stop): the first heal on a divided huskless Seat should have STAMPED the founding
    //  captaincy onto a self-husk pier (link, post:Captain) — the re-derive reads it off the stamp.
    let fam2 = this.Swarm_family_derive(hana)
    let husk2 = fam2.find((f) => f.husk)
    let hpier = hp.o({ Pier: 1 }).find((p) => p.sc.link && String(p.sc.post || '') === 'Captain')
    let row = { healed: 1 }
    if (husk2 && husk2.post === 'Captain') { row.founding_stamp_stands = 1 }
    if (hpier && hpier.sc.pub && mypub.startsWith(String(hpier.sc.pub))) { row.self_husk_pier = 1 }
    if (healed === 1) { row.heal_ran = 1 }
    // land-of-prepub (Phase D): a body IS its own address — the heal writes NO seat column.
    if (own && own.sc.post === 'Captain' && !own.sc.address) { row.own_row_seated = 1 }
    if (kavi && kavi.sc.post === 'Cave' && !kavi.sc.address && kavi.sc.name === 'Kavi') { row.member_from_grant = 1 }
    if (kavi && !kavi.sc.caveat) { row.caveat_retired = 1 }
    if (!roster.find((b) => String(b.sc.pub) === 'junk_body_pub_0000')) { row.junk_retired = 1 }
    if (roster.find((b) => String(b.sc.pub) === 'gapcap_body_pub_00')) { row.gap_captain_survives = 1 }
    if (!roster.find((b) => String(b.sc.pub) === bare)) { row.ghost_dropped = 1 }
    // Phase D: the heal signs NOTHING — the roster is not a document ("the Charter doesn't need
    //  persisting at all"); membership is the key, the roster mile carries the view.
    if (!ch && listed.length === 0) { row.no_charter_minted = 1 }
    if (healed2 === 0) { row.settled_idempotent = 1 }
    this.SwarmBody_note(w, row)

// beat 9 — THE ROSTER MILE REPLICATES (mint-stop, Division §0 ⚑⚑⚑: "the Charter just popped up by
//  whoever you manage to talk to").  Grant atoms no longer carry the family — plain roster rows do,
//   riding the `roster` frame between same-soul bodies; membership PROOF lives at the door (the
//    soul-signed voucher, gated in Peeroleum's crew road), so the rows are a VIEW that grow-only
//     unions.  Teeth: a hand-relic grant without a signature still stays home (the legacy sidecar
//      absorbs nothing unsigned), and the chrysalis STAMP never travels — a sibling's rails are
//       re-earned per store, never gossiped into being.
async SwarmBody_replicate(w):
    w i reached:step_9
    let acct = w.oai({ Account: 1, of: 'Alice' })
    let hana = acct.o({ Identity: 1 }).find((i) => i.sc.friendly === 'Hana')
    if (!hana) { return }
    let wires = this.Swarm_family_grants_wire(hana)
    let rows = this.Swarm_roster_of(hana)
    // the TWIN: the same soul standing in another store — its own Account container + its own body key
    let tacct = w.oai({ Account: 1, of: 'HanaTwin' })
    tacct.c.up = w
    let hkeys = { prepub: String(hana.sc.prepub), pub: String(hana.c.keys.pub), key: String(hana.c.keys.key) }
    let twin = this.Swarm_identity(tacct, hkeys, 'Hana')
    twin.c.bodykey = await this.Swarm_mint_keys('SwarmBody-HanaTwin-body')
    // the roster frame lands (the wire shape Swarm_roster_gossip sends; heard = the receiver's whole job)
    let n = await this.Swarm_roster_heard(w, twin, { roster: rows, grants: wires, organs: [] })
    let mypub = String(this.Swarm_body_key(hana)?.pub || '')
    let before = this.Swarm_body_roster(twin).length
    let cap = this.Swarm_body_roster(twin).find((b) => String(b.sc.pub) === mypub)
    // hear the SAME view again — the union may only fill, never mint twins
    await this.Swarm_roster_heard(w, twin, { roster: rows, grants: [], organs: [] })
    let tstamped = (this.Swarm_peering(twin)?.o({ Pier: 1 }) ?? []).filter((p) => p.sc.link)
    let row = { replicated: 1 }
    if (n >= 2) { row.roster_rode = 1 }
    if (cap && cap.sc.post === 'Captain' && cap.sc.name === 'Hana' && !cap.sc.address) { row.sibling_sees_captain = 1 }
    if (this.Swarm_body_roster(twin).length === before) { row.union_grows_only = 1 }
    // the unsigned hand-relic (Kavi's planted grant carries no sign) stays home: verify throws, skipped
    if (wires.length === 1 && !this.Swarm_peering(twin).o({ Pier: 1, pub: 'kavi_prepub_0000' })[0]?.o({ Grant: 1 })[0]) { row.relic_stayed_home = 1 }
    if (tstamped.length === 0) { row.stamp_stayed_home = 1 }
    this.SwarmBody_note(w, row)

// beat 10 — THE CROSS-BODY REACH primitive (Reach_todo — the foam between the foam).  A %Reach is the ONE
//  shape the five hand-rolled send-retry-settle-drop dialects collapse into: a durable addressed intent
//   that STANDS as legible matter until served.  Proven on pure C-matter: book stands + carries `by`; the
//    address resolves off the family charter (a role → the body that plays it); an offline dispatch (no
//     station) resolves the route but LEAVES the intent standing (the state IS the debt — no separate
//      %Owed); re-booking is idempotent; the target hears → serves through a doer → arrives, a refusing
//       doer leaves it serving (the gate), and a fulfilled reach graduates away.
async SwarmBody_reach(w):
    w i reached:step_10
    let acct = w.oai({ Account: 1, of: 'Alice' })
    // Rex — the BOOKER: a Seat (Captain) whose family holds a Cave at <bare>_1
    let rkeys = await this.Swarm_mint_keys('SwarmBody-Rex')
    let rex = this.Swarm_identity(acct, rkeys, 'Rex')
    rex.c.bodykey = await this.Swarm_mint_keys('SwarmBody-Rex-body')
    let bare = String(rex.sc.prepub)
    this.Swarm_body_take(rex, null, 'Captain', bare)
    this.Swarm_body_note(rex, 'cove_body_pub_00', 'Cave', bare + '_1', 'Cove')
    // BOOK a reach to my Cave, RESOLVE its address, DISPATCH with no station (wire inert → intent stands)
    let reach = this.Swarm_reach_book(w, rex, { to: 'Cave', of: 'track_xyz', for: 'serve' })
    let addr = this.Swarm_reach_addr(rex, reach)
    let daddr = this.Swarm_reach_dispatch(w, rex, reach)
    this.Swarm_reach_book(w, rex, { to: 'Cave', of: 'track_xyz', for: 'serve' })   // idempotent re-book
    let rcount = this.Swarm_peering(rex).o({ Reach: 1 }).length
    // TARGET — Cove the laptop HEARS the reach, then serves it
    let ckeys = await this.Swarm_mint_keys('SwarmBody-Cove')
    let cove = this.Swarm_identity(acct, ckeys, 'Cove')
    let inb = this.Swarm_reach_heard(w, cove, { reach: { of: 'track_xyz', to: 'Cave', for: 'serve', by: String(rex.c.bodykey.pub) } })
    let heard_ok = inb && inb.sc.state === 'serving' ? 1 : 0   // capture BEFORE serve mutates the live ref
    let refused = this.Swarm_reach_serve(w, cove, (r) => 0)
    let stillServing = this.Swarm_peering(cove).o({ Reach: 1, state: 'serving' }).length
    let served = this.Swarm_reach_serve(w, cove, (r) => 1)
    let arrived = this.Swarm_peering(cove).o({ Reach: 1, state: 'arrived' }).length
    let dropped = this.Swarm_reach_graduate(cove)
    let left = this.Swarm_peering(cove).o({ Reach: 1 }).length
    let row = { reached: 1 }
    if (reach && reach.sc.state === 'booked' && reach.sc.by) { row.booked_stands = 1 }
    // land-of-prepub (Division §0 ⚑⚑⚑, 2026-09-02): the reach resolves to the Cave's KEY-DERIVED
    //  name — prepubOf of its roster pub — never the recorded seat (the address column is furniture).
    let want_addr = 'cove_body_pub_00'.slice(0, 16)
    if (addr === want_addr && daddr === want_addr) { row.addr_resolves = 1 }
    if (reach.sc.state === 'booked') { row.offline_stands = 1 }
    if (rcount === 1) { row.idempotent = 1 }
    if (heard_ok) { row.heard_serving = 1 }
    if (refused === 0 && stillServing === 1) { row.doer_gates = 1 }
    if (served === 1 && arrived === 1) { row.served_arrived = 1 }
    if (dropped === 1 && left === 0) { row.graduated = 1 }
    this.SwarmBody_note(w, row)

// beat 11 — THE REACH ROUND-TRIP + the receipts (completing the primitive's lifecycle).  The settle loop
//  is KNOB-GATED (observe until w.c.reach_on flipped — the backpressure discipline); the booker hears the
//   outcome and closes the trip: 'arrived' graduates away, 'refused' STANDS as a visible terminal receipt.
async SwarmBody_reach_ack(w):
    w i reached:step_11
    let acct = w.oai({ Account: 1, of: 'Alice' })
    let rkeys = await this.Swarm_mint_keys('SwarmBody-Rax')
    let rax = this.Swarm_identity(acct, rkeys, 'Rax')
    rax.c.bodykey = await this.Swarm_mint_keys('SwarmBody-Rax-body')
    let bare = String(rax.sc.prepub)
    this.Swarm_body_note(rax, 'cave_body_pub_11', 'Cave', bare + '_1', 'Caz')
    let ckeys = await this.Swarm_mint_keys('SwarmBody-Caz')
    let caz = this.Swarm_identity(acct, ckeys, 'Caz')
    // book reach A; the SETTLE LOOP observes-only until the knob is flipped
    let ra = this.Swarm_reach_book(w, rax, { to: 'Cave', of: 'track_A', for: 'serve' })
    let settle_off = this.Swarm_reach_settle(w, rax)
    w.c.reach_on = 1
    let settle_on = this.Swarm_reach_settle(w, rax)
    delete w.c.reach_on
    // ROUND TRIP on A: target hears → serves → booker acks 'arrived' → graduates away
    let inA = this.Swarm_reach_heard(w, caz, { reach: { of: 'track_A', to: 'Cave', for: 'serve', by: String(rax.c.bodykey.pub) } })
    this.Swarm_reach_serve(w, caz, (r) => 1)
    this.Swarm_reach_ack(w, rax, { state: 'arrived', reach: { to: 'Cave', of: 'track_A', for: 'serve' } })
    let a_arrived = this.Swarm_peering(rax).o({ Reach: 1, of: 'track_A' })[0]
    let a_state = a_arrived ? String(a_arrived.sc.state) : ''
    let a_grad = this.Swarm_reach_graduate(rax)
    let a_gone = this.Swarm_peering(rax).o({ Reach: 1, of: 'track_A' }).length === 0 ? 1 : 0
    // REFUSED arm on B: target refuses → booker acks 'refused' → it STANDS (graduate does not drop it)
    let rb = this.Swarm_reach_book(w, rax, { to: 'Cave', of: 'track_B', for: 'serve' })
    let inB = this.Swarm_reach_heard(w, caz, { reach: { of: 'track_B', to: 'Cave', for: 'serve', by: String(rax.c.bodykey.pub) } })
    this.Swarm_reach_refuse(w, caz, inB)
    this.Swarm_reach_ack(w, rax, { state: 'refused', reach: { to: 'Cave', of: 'track_B', for: 'serve' } })
    this.Swarm_reach_graduate(rax)
    let b = this.Swarm_peering(rax).o({ Reach: 1, of: 'track_B' })[0]
    let b_refused_stands = (b && String(b.sc.state) === 'refused') ? 1 : 0
    let row = { acked: 1 }
    if (settle_off === 0) { row.knob_off_observes = 1 }
    if (settle_on >= 1) { row.knob_on_settles = 1 }
    if (a_state === 'arrived' && a_grad === 1 && a_gone === 1) { row.round_trip = 1 }
    if (b_refused_stands === 1) { row.refused_stands = 1 }
    this.SwarmBody_note(w, row)

// beat 12 — THE REACH WIRE LANE's gates (the funnel routes are live now — `reach`/`reach_done` frames):
//  the ROAD only admits a body of MY OWN soul (`by` must prefix-match a rostered %Body pub — the relay
//   is untrusted, so a stranger's booking lands NOTHING), and the REPORT resolves the booker's return
//    address off the same roster (wire inert without a station — the resolution is the proof).
async SwarmBody_reach_road(w):
    w i reached:step_12
    let acct = w.oai({ Account: 1, of: 'Alice' })
    let tkeys = await this.Swarm_mint_keys('SwarmBody-Tove')
    let tove = this.Swarm_identity(acct, tkeys, 'Tove')
    tove.c.bodykey = await this.Swarm_mint_keys('SwarmBody-Tove-body')
    let bare = String(tove.sc.prepub)
    this.Swarm_body_note(tove, 'rex_body_pub_1200', 'Captain', bare, 'Rexa')
    // the KIN road: a rostered sibling's reach is admitted and stands serving
    let kin = this.Swarm_reach_road(w, tove, { reach: { of: 'track_R', to: 'Cave', for: 'serve', by: 'rex_body_pub_1200' } })
    // the STRANGER gate: an unrostered `by` lands nothing
    let stranger = this.Swarm_reach_road(w, tove, { reach: { of: 'track_S', to: 'Cave', for: 'serve', by: 'evil_body_pub_99' } })
    let standing = this.Swarm_peering(tove).o({ Reach: 1 }).length
    // the REPORT: after the doer serves — the booker's return address resolves off the roster
    this.Swarm_reach_serve(w, tove, (r) => 1)
    let back = kin ? this.Swarm_reach_report(w, tove, kin) : null
    let row = { roaded: 1 }
    if (kin && kin.sc.state === 'arrived') { row.kin_admitted = 1 }
    if (stranger === null && standing === 1) { row.stranger_refused = 1 }
    // land-of-prepub: the return address is the Captain's key-derived name, not the bare seat.
    if (back === 'rex_body_pub_1200'.slice(0, 16)) { row.report_resolves = 1 }
    this.SwarmBody_note(w, row)

// beat 13 — THE CREW READ (Reach_todo §6, the legibility half): the standing reaches project into ONE
//  legible glance — tallied by state, each entry carrying its (of, to, for, state).  This is the Crew
//   cell's data (what my crew is doing for me and I for them), made snap-readable and Book-assertable.
async SwarmBody_reach_crew(w):
    w i reached:step_13
    let acct = w.oai({ Account: 1, of: 'Alice' })
    let kkeys = await this.Swarm_mint_keys('SwarmBody-Krew')
    let krew = this.Swarm_identity(acct, kkeys, 'Krew')
    krew.c.bodykey = await this.Swarm_mint_keys('SwarmBody-Krew-body')
    let bare = String(krew.sc.prepub)
    this.Swarm_body_note(krew, 'kcave_body_pub_13', 'Cave', bare + '_1', 'Kave')
    this.Swarm_reach_book(w, krew, { to: 'Cave', of: 't1', for: 'serve' })                       // booked
    this.Swarm_reach_book(w, krew, { to: 'Cave', of: 't2', for: 'serve' })
    this.Swarm_reach_heard(w, krew, { reach: { of: 't2', to: 'Cave', for: 'serve', by: 'x' } })  // → serving
    let r3 = this.Swarm_reach_book(w, krew, { to: 'Cave', of: 't3', for: 'serve' })
    this.Swarm_reach_refuse(w, krew, r3)                                                          // → refused
    let r4 = this.Swarm_reach_book(w, krew, { to: 'Cave', of: 't4', for: 'serve' })
    r4.sc.state = 'dead'                                                                          // → dead (the third exit's receipt)
    r4.bump()
    let crew = this.Swarm_reach_crew(w, krew)
    let t1 = crew.reaches.find((r) => r.of === 't1')
    let row = { crewed: 1 }
    if (crew.total === 4) { row.tallies_total = 1 }
    if (crew.booked === 1 && crew.serving === 1 && crew.refused === 1 && crew.dead === 1) { row.tallies_states = 1 }
    if (t1 && t1.state === 'booked' && t1.to === 'Cave' && t1.for === 'serve') { row.entry_shape = 1 }
    this.SwarmBody_note(w, row)

// beat 14 — THE %ORGAN readout (SoundPool §3): a body describes the organ it grows — pocket vs trove,
//  as QUANTITIES on its own %Body row (not the tracks — the body naming what it holds).  The Crew/Pool/
//   Organ cells all read this.  Proven pure: pocket + trove stand with their counts + tag-shape; a
//    re-take updates in place (idempotent); the read resolves by kind.
async SwarmBody_organ(w):
    w i reached:step_14
    let acct = w.oai({ Account: 1, of: 'Alice' })
    let okeys = await this.Swarm_mint_keys('SwarmBody-Orin')
    let orin = this.Swarm_identity(acct, okeys, 'Orin')
    orin.c.bodykey = await this.Swarm_mint_keys('SwarmBody-Orin-body')
    let bare = String(orin.sc.prepub)
    this.Swarm_body_take(orin, null, 'Captain', bare)   // my own row, so body_mine finds it
    let pocket = this.Swarm_organ_take(orin, 'pocket', { tracks: 214, tags: 'vio+train' })
    let pocket0 = pocket ? String(pocket.sc.tracks) : ''   // capture BEFORE the idempotent re-take mutates the live ref
    let trove = this.Swarm_organ_take(orin, 'trove', { tracks: 38000, tags: 'all' })
    this.Swarm_organ_take(orin, 'pocket', { tracks: 220, tags: 'vio+train' })   // idempotent update
    let mine = this.Swarm_body_mine(orin)
    let organs = mine ? mine.o({ Organ: 1 }).length : 0
    let rp = this.Swarm_organ_of(mine, 'pocket')
    let rt = this.Swarm_organ_of(mine, 'trove')
    let row = { organed: 1 }
    if (pocket0 === '214') { row.pocket_stood = 1 }
    if (trove && String(trove.sc.tracks) === '38000' && String(trove.sc.tags) === 'all') { row.trove_stood = 1 }
    if (organs === 2 && rp && String(rp.sc.tracks) === '220') { row.idempotent_updated = 1 }
    if (rt && String(rt.sc.kind) === 'trove') { row.read_by_kind = 1 }
    this.SwarmBody_note(w, row)

// beat 15 — ORGAN REPLICATION (SoundPool §0.5): a body's pocket/trove sizes travel to a sibling so the
//  phone sees the laptop's trove.  Organs ride the charter mile beside the family grants; each body is
//   authoritative for its OWN organ (wire = my own rows); the receiver lands them onto the roster row
//    they describe (matched by pub), and an organ for a body it doesn't roster is skipped.
async SwarmBody_organ_wire(w):
    w i reached:step_15
    let acct = w.oai({ Account: 1, of: 'Alice' })
    // Sage — the sender: its own body + a trove organ
    let skeys = await this.Swarm_mint_keys('SwarmBody-Sage')
    let sage = this.Swarm_identity(acct, skeys, 'Sage')
    sage.c.bodykey = await this.Swarm_mint_keys('SwarmBody-Sage-body')
    this.Swarm_body_take(sage, null, 'Cave', String(sage.sc.prepub))
    this.Swarm_organ_take(sage, 'trove', { tracks: 38000, tags: 'all' })
    let wire = this.Swarm_organ_wire(sage)
    let sagepub = String(this.Swarm_body_key(sage).pub)
    // Rue — the receiver: already rosters Sage (a %Body row), absorbs Sage's organ onto it
    let rkeys = await this.Swarm_mint_keys('SwarmBody-Rue')
    let rue = this.Swarm_identity(acct, rkeys, 'Rue')
    this.Swarm_body_note(rue, sagepub, 'Cave', String(sage.sc.prepub), 'Sage')
    let landed = this.Swarm_organ_absorb(rue, wire)
    // a stray organ for a body Rue does NOT roster lands nothing
    let stray = this.Swarm_organ_absorb(rue, [{ pub: 'nobody_pub_15', kind: 'trove', tracks: '9' }])
    let row = { organ_wired: 1 }
    let saw = this.Swarm_peering(rue).o({ Body: 1 }).find((b) => String(b.sc.pub) === sagepub)
    let seen = saw ? this.Swarm_organ_of(saw, 'trove') : null
    if (wire.length === 1 && wire[0].kind === 'trove' && wire[0].tracks === '38000') { row.wire_shape = 1 }
    if (landed === 1 && seen && String(seen.sc.tracks) === '38000') { row.sibling_organ_seen = 1 }
    if (stray === 0) { row.stray_skipped = 1 }
    this.SwarmBody_note(w, row)

// beat 16 — REACH BACKPRESSURE (the %Owed cap discipline): a NEW booking beyond w.c.reach_cap is refused
//  so a runaway loop cannot flood the shelf; re-booking an EXISTING reach is always honoured (a retry of
//   something already standing is never blocked by the cap).
async SwarmBody_reach_cap(w):
    w i reached:step_16
    let acct = w.oai({ Account: 1, of: 'Alice' })
    let ckeys = await this.Swarm_mint_keys('SwarmBody-Cap')
    let cap = this.Swarm_identity(acct, ckeys, 'Cap')
    cap.c.bodykey = await this.Swarm_mint_keys('SwarmBody-Cap-body')
    let bare = String(cap.sc.prepub)
    this.Swarm_body_note(cap, 'capcave_pub_16', 'Cave', bare + '_1', 'Capa')
    w.c.reach_cap = 3
    let b1 = this.Swarm_reach_book(w, cap, { to: 'Cave', of: 'c1', for: 'serve' })
    let b2 = this.Swarm_reach_book(w, cap, { to: 'Cave', of: 'c2', for: 'serve' })
    let b3 = this.Swarm_reach_book(w, cap, { to: 'Cave', of: 'c3', for: 'serve' })
    let over = this.Swarm_reach_book(w, cap, { to: 'Cave', of: 'c4', for: 'serve' })   // beyond cap → refused
    let atcap = this.Swarm_peering(cap).o({ Reach: 1 }).length
    let rebook = this.Swarm_reach_book(w, cap, { to: 'Cave', of: 'c2', for: 'serve' })  // existing → honoured
    let still = this.Swarm_peering(cap).o({ Reach: 1 }).length
    delete w.c.reach_cap
    let row = { capped: 1 }
    if (b1 && b2 && b3) { row.under_cap_booked = 1 }
    if (over === null && atcap === 3) { row.over_cap_refused = 1 }
    if (rebook && still === 3) { row.rebook_honoured = 1 }
    this.SwarmBody_note(w, row)

// beat 17 — REFUSED-RECEIPT AGING (the cap's cousin): a refused reach stands as a receipt but must not
//  stand forever, or it fills the cap and starves live bookings.  The settle loop sweeps refused reaches
//   older than the receipt TTL; a fresh refused receipt survives (its window to be seen).
async SwarmBody_reach_sweep(w):
    w i reached:step_17
    let acct = w.oai({ Account: 1, of: 'Alice' })
    let skeys = await this.Swarm_mint_keys('SwarmBody-Swp')
    let swp = this.Swarm_identity(acct, skeys, 'Swp')
    swp.c.bodykey = await this.Swarm_mint_keys('SwarmBody-Swp-body')
    let bare = String(swp.sc.prepub)
    this.Swarm_body_note(swp, 'swpcave_pub_17', 'Cave', bare + '_1', 'Swpa')
    w.c.reach_on = 1
    w.c.reach_receipt_ttl = 100
    // an OLD refused receipt (at well past the ttl) and a FRESH one
    let old = this.Swarm_reach_book(w, swp, { to: 'Cave', of: 'old_r', for: 'serve' })
    this.Swarm_reach_refuse(w, swp, old)
    old.sc.at = String(this.Swarm_now(w) - 200)   // 200s old, past the 100s ttl
    old.bump()
    let fresh = this.Swarm_reach_book(w, swp, { to: 'Cave', of: 'fresh_r', for: 'serve' })
    this.Swarm_reach_refuse(w, swp, fresh)   // at = now (fresh)
    this.Swarm_reach_settle(w, swp)          // dispatches + sweeps
    delete w.c.reach_on
    delete w.c.reach_receipt_ttl
    let left = this.Swarm_peering(swp).o({ Reach: 1 })
    let hasOld = left.some((r) => String(r.sc.of) === 'old_r')
    let hasFresh = left.some((r) => String(r.sc.of) === 'fresh_r')
    let row = { swept: 1 }
    if (!hasOld) { row.stale_swept = 1 }
    if (hasFresh) { row.fresh_survives = 1 }
    this.SwarmBody_note(w, row)

// beat 18 — THE THIRD EXIT (W1, the proving beat): a standing want past its deadline settles 'dead'
//  ('nobody-answered') — the only exit besides landed|refused, so a want can NEVER hang silent (the
//   week's curse: the incognito hung "listening for the soul" forever).  The deadline is ms-epoch on
//    `.c` (volatile — never snapped, so the fixture stays byte-stable and a reloaded ceremony re-books
//     its own); a want with NO deadline STANDS forever (the durable cross-body booking).  Pinned: the
//      dead receipt's `at` is Swarm_now (the world clock), never wall clock, so the snap is repeatable.
async SwarmBody_reach_dead(w):
    w i reached:step_18
    let acct = w.oai({ Account: 1, of: 'Alice' })
    let dkeys = await this.Swarm_mint_keys('SwarmBody-Dex')
    let dex = this.Swarm_identity(acct, dkeys, 'Dex')
    dex.c.bodykey = await this.Swarm_mint_keys('SwarmBody-Dex-body')
    let bare = String(dex.sc.prepub)
    this.Swarm_body_note(dex, 'dcave_pub_18', 'Cave', bare + '_1', 'Dave')
    w.c.reach_on = 1
    // a want whose deadline already passed — nobody answered the door → the third exit
    let want = this.Swarm_reach_book(w, dex, { to: 'Cave', of: 'gone_track', for: 'serve' })
    let before = String(want.sc.state)          // 'booked' — not yet settled
    want.c.deadline = 1                          // ms-epoch far in the past (Date.now() > 1 always)
    // a want with NO deadline stands forever — the durable cross-body booking
    let durable = this.Swarm_reach_book(w, dex, { to: 'Cave', of: 'standing_track', for: 'serve' })
    this.Swarm_reach_settle(w, dex)             // one pass: gone_track → dead, standing_track stands
    delete w.c.reach_on
    let after = String(want.sc.state)
    let why = String(want.sc.why || '')
    let at = +want.sc.at
    let durable_state = String(durable.sc.state)
    let row = { deaded: 1 }
    if (before === 'booked' && after === 'dead' && why === 'nobody-answered') { row.deadline_dies = 1 }
    if (at === 1751700000) { row.dead_at_pinned = 1 }              // the receipt's clock is the world's, not the wall's
    if (durable_state !== 'dead') { row.no_deadline_stands = 1 }
    this.SwarmBody_note(w, row)

// beat 19 — THE TERMINAL LATCH (W1, the proving beat): cross-node truth where the FIRST terminal wins and
//  a landing OUTRANKS a refusal.  Under a multi-path fan only the holder can land while every other body
//   legitimately refuses, so a racing refusal must NEVER bury a landed.  Three arms: a landed survives a
//    later refusal (X); a refusal upgrades when the holder later lands (Y); and at equal rank the first
//     terminal wins so a dead ack cannot flip a standing refused (Z).
async SwarmBody_reach_latch(w):
    w i reached:step_19
    let acct = w.oai({ Account: 1, of: 'Alice' })
    let lkeys = await this.Swarm_mint_keys('SwarmBody-Lex')
    let lex = this.Swarm_identity(acct, lkeys, 'Lex')
    lex.c.bodykey = await this.Swarm_mint_keys('SwarmBody-Lex-body')
    let bare = String(lex.sc.prepub)
    this.Swarm_body_note(lex, 'lcave_pub_19', 'Cave', bare + '_1', 'Lave')
    // X — a landed reach cannot be buried by a racing refusal (the multi-path fan)
    this.Swarm_reach_book(w, lex, { to: 'Cave', of: 'landed_x', for: 'serve' })
    this.Swarm_reach_ack(w, lex, { state: 'arrived', reach: { to: 'Cave', of: 'landed_x', for: 'serve' } })
    this.Swarm_reach_ack(w, lex, { state: 'refused', reach: { to: 'Cave', of: 'landed_x', for: 'serve' } })
    let x = this.Swarm_peering(lex).o({ Reach: 1, of: 'landed_x' })[0]
    let x_state = x ? String(x.sc.state) : ''
    // Y — a refusal THEN a landing upgrades (the holder lands after another body refused)
    this.Swarm_reach_book(w, lex, { to: 'Cave', of: 'upgrade_y', for: 'serve' })
    this.Swarm_reach_ack(w, lex, { state: 'refused', reach: { to: 'Cave', of: 'upgrade_y', for: 'serve' } })
    this.Swarm_reach_ack(w, lex, { state: 'arrived', reach: { to: 'Cave', of: 'upgrade_y', for: 'serve' } })
    let y = this.Swarm_peering(lex).o({ Reach: 1, of: 'upgrade_y' })[0]
    let y_state = y ? String(y.sc.state) : ''
    // Z — equal rank: a dead ack cannot flip a standing refused (first-terminal-wins)
    this.Swarm_reach_book(w, lex, { to: 'Cave', of: 'first_z', for: 'serve' })
    this.Swarm_reach_ack(w, lex, { state: 'refused', reach: { to: 'Cave', of: 'first_z', for: 'serve' } })
    this.Swarm_reach_ack(w, lex, { state: 'dead', reach: { to: 'Cave', of: 'first_z', for: 'serve' } })
    let z = this.Swarm_peering(lex).o({ Reach: 1, of: 'first_z' })[0]
    let z_state = z ? String(z.sc.state) : ''
    let row = { latched: 1 }
    if (x_state === 'arrived') { row.landed_survives_refusal = 1 }
    if (y_state === 'arrived') { row.refusal_upgrades_to_landed = 1 }
    if (z_state === 'refused') { row.first_terminal_wins = 1 }
    this.SwarmBody_note(w, row)

// beat 20 — THE TERMINAL GUARD (W1, the proving beat): a SETTLED reach never re-dispatches.  The zombie
//  was a 'refused' reach re-sending every pass and flipping itself back to 'dispatched', dodging its own
//   receipt sweep — the guard was `=== 'arrived'` only.  Now dispatch REFUSES a refused and a dead one
//    alike (returns null), while a booked one still resolves its address (the control that proves the
//     guard cuts something real), and the settle loop skips both failure terminals in one pass.
async SwarmBody_reach_zombie(w):
    w i reached:step_20
    let acct = w.oai({ Account: 1, of: 'Alice' })
    let zkeys = await this.Swarm_mint_keys('SwarmBody-Zed')
    let zed = this.Swarm_identity(acct, zkeys, 'Zed')
    zed.c.bodykey = await this.Swarm_mint_keys('SwarmBody-Zed-body')
    let bare = String(zed.sc.prepub)
    this.Swarm_body_note(zed, 'zcave_pub_20', 'Cave', bare + '_1', 'Zave')
    // a REFUSED reach — dispatch refuses to touch it (null), so it can never flip back to 'dispatched'
    let refd = this.Swarm_reach_book(w, zed, { to: 'Cave', of: 'refused_z', for: 'serve' })
    this.Swarm_reach_refuse(w, zed, refd)
    let d_refused = this.Swarm_reach_dispatch(w, zed, refd)
    let refd_state = String(refd.sc.state)
    // a DEAD reach — the same guard (both failure terminals stand still)
    let deadr = this.Swarm_reach_book(w, zed, { to: 'Cave', of: 'dead_z', for: 'serve' })
    deadr.sc.state = 'dead'
    deadr.bump()
    let d_dead = this.Swarm_reach_dispatch(w, zed, deadr)
    // a BOOKED reach — the CONTROL: dispatch DOES resolve its address (proves the guard cuts something)
    let bookd = this.Swarm_reach_book(w, zed, { to: 'Cave', of: 'live_z', for: 'serve' })
    let d_live = this.Swarm_reach_dispatch(w, zed, bookd)
    // and the settle loop skips both terminals in one pass — only the live booking re-dispatches
    w.c.reach_on = 1
    let n = this.Swarm_reach_settle(w, zed)
    delete w.c.reach_on
    let refd_after = String(refd.sc.state)
    let row = { zombied: 1 }
    if (d_refused === null && refd_state === 'refused') { row.refused_guarded = 1 }
    if (d_dead === null) { row.dead_guarded = 1 }
    // the CONTROL: a booked reach STILL resolves to a truthy address (the guard cuts only terminals)
    if (typeof d_live === 'string' && d_live) { row.booked_dispatches = 1 }
    if (n === 1 && refd_after === 'refused') { row.settle_skips_terminals = 1 }
    this.SwarmBody_note(w, row)

// beat 21 — THE PIER-LESS REACH AUTH (Ceremony §6 rule 6, "auth before mint|settle"): a reach|reach_done
//  that resolves no sealed pier at the hear funnel is admitted only by a valid soul-signed voucher.  Proven
//   on pure matter (Swarm_reach_vouched is not station-gated — the FUNNEL that calls it is; that 4-line
//    guard mirrors the sealed-pier voucher gate right above it, proven live by SwarmWire's seal): a body of
//     my OWN soul passes (its voucher is signed by our shared soul key); a SEALED friend passes (delegates
//      to Swarm_voucher_ok against the pub imported at seal); while NO voucher, a TAMPERED signature, and an
//       UNKNOWN soul each land nothing — so a forged reach_done cannot settle a standing reach.
async SwarmBody_reach_auth(w):
    w i reached:step_21
    let acct = w.oai({ Account: 1, of: 'Alice' })
    let akeys = await this.Swarm_mint_keys('SwarmBody-Auth-Alice')
    let alice = this.Swarm_identity(acct, akeys, 'AuthAlice')
    // a valid per-era voucher signed by Alice's OWN soul key — a body of my soul
    let av = await this.Swarm_voucher_mint(alice, 1)
    let own = await this.Swarm_reach_vouched(alice, { voucher: av })
    // no voucher at all
    let none = await this.Swarm_reach_vouched(alice, {})
    // a tampered voucher — the signature no longer covers the (changed) era
    let tampered = await this.Swarm_reach_vouched(alice, { voucher: Object.assign({}, av, { era: 999 }) })
    // a STRANGER — a different soul's valid voucher, with no sealed pier for it
    let ekeys = await this.Swarm_mint_keys('SwarmBody-Auth-Eve')
    let eve = this.Swarm_identity(acct, ekeys, 'AuthEve')
    let ev = await this.Swarm_voucher_mint(eve, 1)
    let stranger = await this.Swarm_reach_vouched(alice, { voucher: ev })
    // a SEALED FRIEND — Bob, with a %Pier under Alice holding the pub she imported at his seal
    let bkeys = await this.Swarm_mint_keys('SwarmBody-Auth-Bob')
    let bob = this.Swarm_identity(acct, bkeys, 'AuthBob')
    let bv = await this.Swarm_voucher_mint(bob, 1)
    let apeer = this.Swarm_peering(alice)
    let pier = apeer.i({ Pier: 1, pub: String(bob.sc.prepub) })
    pier.c.up = apeer
    let held = pier.i({ Peering: 1, pub: String(bkeys.pub) })
    held.c.up = pier
    let friend = await this.Swarm_reach_vouched(alice, { voucher: bv })
    let row = { authed: 1 }
    if (own === true) { row.own_soul_admitted = 1 }
    if (none === false) { row.no_voucher_rejected = 1 }
    if (tampered === false) { row.tampered_rejected = 1 }
    if (stranger === false) { row.stranger_rejected = 1 }
    if (friend === true) { row.sealed_friend_admitted = 1 }
    this.SwarmBody_note(w, row)

// beat 22 — THE DOER CONTRACT (Ceremony §6 rule 4, the req machine's three postures at the wire): a doer
//  answers placed (truthy → arrived) | not-yet (falsy → stays serving) | provably-cannot ({refuse:<why>} →
//   refused with its named why).  A MISSING handler refuses 'no_handler' — the old code AUTO-LANDED it, a
//    lie in the ledger.  A THROW is NOT terminal (the tri-state lesson): the want stays serving for the
//     re-ask, but a loud %rebuff marks it.  And the why CROSSES THE WIRE: a reach_done ack carrying why
//      lands it on the booker's receipt (guarded — an ack without one stamps nothing, no undef marker).
//  Each arm gets its own hear→serve window (serve iterates ALL serving reaches, so order is the harness).
async SwarmBody_reach_doer(w):
    w i reached:step_22
    let acct = w.oai({ Account: 1, of: 'Alice' })
    let skeys = await this.Swarm_mint_keys('SwarmBody-Serl')
    let serl = this.Swarm_identity(acct, skeys, 'Serl')
    // arm A — NO handler: the only serving reach refuses 'no_handler' (never auto-lands)
    let a = this.Swarm_reach_heard(w, serl, { reach: { of: 's1', to: 'Cave', for: 'serve', by: 'x' } })
    this.Swarm_reach_serve(w, serl, null)
    let a_ok = (String(a.sc.state) === 'refused' && String(a.sc.why) === 'no_handler') ? 1 : 0
    // arms D|E — the controls: falsy leaves it serving, truthy lands it
    let d = this.Swarm_reach_heard(w, serl, { reach: { of: 's4', to: 'Cave', for: 'serve', by: 'x' } })
    this.Swarm_reach_serve(w, serl, (r) => 0)
    let e_still = String(d.sc.state) === 'serving' ? 1 : 0
    this.Swarm_reach_serve(w, serl, (r) => 1)
    let d_ok = String(d.sc.state) === 'arrived' ? 1 : 0
    // arm B — the doer names its refusal
    let b = this.Swarm_reach_heard(w, serl, { reach: { of: 's2', to: 'Cave', for: 'serve', by: 'x' } })
    this.Swarm_reach_serve(w, serl, (r) => ({ refuse: 'shelf_full' }))
    let b_ok = (String(b.sc.state) === 'refused' && String(b.sc.why) === 'shelf_full') ? 1 : 0
    // arm C — a throw is not terminal: serving stands + a loud %rebuff
    let c = this.Swarm_reach_heard(w, serl, { reach: { of: 's3', to: 'Cave', for: 'serve', by: 'x' } })
    this.Swarm_reach_serve(w, serl, (r) => { throw 'boom' })
    let c_serving = String(c.sc.state) === 'serving' ? 1 : 0
    let c_loud = serl.o({ rebuff: 'reach_doer_threw' })[0] ? 1 : 0
    // the WIRE arm — the why crosses on the ack (and an ack WITHOUT one stamps nothing)
    let w1 = this.Swarm_reach_book(w, serl, { to: 'Cave', of: 'w1', for: 'serve' })
    this.Swarm_reach_ack(w, serl, { state: 'refused', why: 'no_handler', reach: { to: 'Cave', of: 'w1', for: 'serve' } })
    let w2 = this.Swarm_reach_book(w, serl, { to: 'Cave', of: 'w2', for: 'serve' })
    this.Swarm_reach_ack(w, serl, { state: 'refused', reach: { to: 'Cave', of: 'w2', for: 'serve' } })
    let wire_why = (String(w1.sc.state) === 'refused' && String(w1.sc.why) === 'no_handler') ? 1 : 0
    let wire_guard = (String(w2.sc.state) === 'refused' && w2.sc.why == null) ? 1 : 0
    let row = { doered: 1 }
    if (a_ok) { row.no_handler_refuses = 1 }
    if (b_ok) { row.refusal_named = 1 }
    if (c_serving && c_loud) { row.throw_not_terminal_but_loud = 1 }
    if (d_ok && e_still) { row.controls_hold = 1 }
    if (wire_why && wire_guard) { row.why_crosses_guarded = 1 }
    this.SwarmBody_note(w, row)

// beat 23 — THE ONE PUMP ENTRY (Ceremony §6 build notes — un-bury the retry): reach_pump is callable
//  from any driver and paces ITSELF (reach_cadence ms — the buried 60s trickle throttle is gone), so a
//   second call inside the cadence no-ops (null).  Hygiene is knob-independent: with reach_on OFF (the
//    observing ledger) the pump still sweeps stale failure receipts — the knob gates ACTION never
//     hygiene — while flipping the knob makes the same entry dispatch the standing wants.
async SwarmBody_reach_pump(w):
    w i reached:step_23
    let acct = w.oai({ Account: 1, of: 'Alice' })
    let pkeys = await this.Swarm_mint_keys('SwarmBody-Pum')
    let pum = this.Swarm_identity(acct, pkeys, 'Pum')
    pum.c.bodykey = await this.Swarm_mint_keys('SwarmBody-Pum-body')
    let bare = String(pum.sc.prepub)
    this.Swarm_body_note(pum, 'pumcave_pub_23', 'Cave', bare + '_1', 'Puma')
    // knob OFF + a STALE refused receipt: the pump must sweep it anyway (hygiene is unconditional)
    w.c.reach_receipt_ttl = 100
    let stale = this.Swarm_reach_book(w, pum, { to: 'Cave', of: 'stale_p', for: 'serve' })
    this.Swarm_reach_refuse(w, pum, stale)
    stale.sc.at = String(this.Swarm_now(w) - 200)
    stale.bump()
    let p1 = this.Swarm_reach_pump(w, pum)
    let swept_off = this.Swarm_peering(pum).o({ Reach: 1, of: 'stale_p' }).length === 0 ? 1 : 0
    // an immediate second call sits inside the cadence — the pump throttles ITSELF
    let p2 = this.Swarm_reach_pump(w, pum)
    // knob ON (fresh cadence window): the same entry now dispatches the standing want
    delete w.c.reach_pump_at
    w.c.reach_on = 1
    this.Swarm_reach_book(w, pum, { to: 'Cave', of: 'live_p', for: 'serve' })
    let p3 = this.Swarm_reach_pump(w, pum)
    delete w.c.reach_on
    delete w.c.reach_pump_at
    delete w.c.reach_receipt_ttl
    let row = { pumped: 1 }
    if (p1 === 0 && swept_off === 1) { row.sweeps_while_observing = 1 }
    if (p2 === null) { row.self_throttles = 1 }
    if (p3 === 1) { row.knob_on_dispatches = 1 }
    this.SwarmBody_note(w, row)

// SwarmBody_order — float A:SwarmBody to the front of H/* so the Run snap stays readable.
async SwarmBody_order(w):
    let As = H.o({A: 1})
    if (!As.length) { return }
    let first = (a) => (a.sc.A === 'SwarmBody') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)

// ══ SwarmCharter — the soul-signed era-stamped roster (Division_todo step 2) ═════════════════════════════
//  §POST'S TRUTH CHAIN #2: the %Body rows are pure resolution; the Charter is the SIGNED snapshot of them
//   that makes routing trustable across the wire.  A friend verifies it against the soul pub — a spoofed
//    "I am Alice's Cave" fails the signature, and a split-brain can't flap because peers keep the HIGHEST
//     ERA.  It is Story's own idiom (state serialised at a version re-emitted when the digest moves) given
//      a signature — the WELD, proven.
//   beat 2  Alice signs her division (Captain bare + Cave _1) at era 1 → ONE %Charter row that SELF-
//            verifies and ROUTES (Charter_addr finds the Cave at its suffix the Captain at the bare name)
//   beat 3  every tamper fails the signature — a moved address a bumped era a swapped soul — while the
//            genuine wire still verifies (the control that proves the teeth cut something real)
//   beat 4  a FRIEND absorbs the genuine Charter and routes off it — a HIGHER era supersedes when Alice
//            moves her Cave — a STALE era is ignored (highest-era wins) — a FORGED one is refused — and
//             the pier holds exactly ONE Charter row merged in place
//  CONVENTION (Swarm*): the world MUST be named SwarmCharter.

SwarmCharter(A,w):
    w oai %req:wrangle,eternal
        await &SwarmCharter_drive,w,req
        req%ok = 1

SwarmCharter_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

SwarmCharter_note(w, sc):
    let t = this.SwarmCharter_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

async SwarmCharter_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) { await this.SwarmCharter_stand(w) }
        if (n === 3) { await this.SwarmCharter_tamper(w) }
        if (n === 4) { await this.SwarmCharter_peer(w) }
    }
    this.SwarmCharter_witness(w)
    await this.SwarmCharter_order(w)

// beat 2 — Alice signs her division at era 1.  Fixed seeds + pinned clock + deterministic ed25519 keep
//  the signature (and so the snap) byte-repeatable.  Captain is her OWN body (body key, bare); Cave is
//   another machine's body (noted at _1).
async SwarmCharter_stand(w):
    w i reached:step_2
    w.sc.now = 1751700000
    let acct = w.oai({ Account: 1, of: 'Alice' })
    acct.c.up = w
    let keys = await this.Swarm_mint_keys('SwarmCharter-Alice')
    let alice = this.Swarm_identity(acct, keys, 'Alice')
    w.c.alice = alice
    let bare = alice.sc.prepub
    alice.c.bodykey = await this.Swarm_mint_keys('SwarmCharter-Alice-body')
    this.Swarm_body_take(alice, null, 'Captain', bare)
    this.Swarm_body_note(alice, 'charter_cave_pub', 'Cave', bare + '_1')
    let ch = await this.Swarm_charter_sign(alice, 1)
    let wire = this.Swarm_charter_wire(alice)
    let ok = await this.Swarm_charter_verify(wire, alice.c.keys.pub)
    let peering = this.Swarm_peering(alice)
    let one = peering.o({ Charter: 1 }).length
    let caveAddr = this.Charter_addr(peering, 'Cave')
    let capAddr = this.Charter_addr(peering, 'Captain')
    let noneAddr = this.Charter_addr(peering, 'Nobody')
    let row = { signed: 1 }
    if (ch && ch.sc.era === '1') { row.era_one = 1 }
    if (one === 1) { row.one_row = 1 }
    if (ok === true) { row.self_verifies = 1 }
    if (caveAddr === bare + '_1') { row.cave_resolves = 1 }
    if (capAddr === bare) { row.captain_bare = 1 }
    if (noneAddr === null) { row.none_null = 1 }
    this.SwarmCharter_note(w, row)

// beat 3 — the teeth.  Three mutations of the genuine wire — a moved Cave address a bumped era a swapped
//  soul — each fail the signature; the untouched wire still verifies (the control).
async SwarmCharter_tamper(w):
    w i reached:step_3
    let alice = w.c.alice
    if (!alice) { return }
    let bare = alice.sc.prepub
    let soulPub = alice.c.keys.pub
    let good = this.Swarm_charter_wire(alice)
    let bad_addr = { era: good.era, payload: good.payload.replace(bare + '_1', bare + '_9'), sig: good.sig, soul: good.soul }
    let bad_era = { era: '99', payload: good.payload, sig: good.sig, soul: good.soul }
    let bad_soul = { era: good.era, payload: good.payload, sig: good.sig, soul: 'deadbeefdeadbeef' }
    let g = await this.Swarm_charter_verify(good, soulPub)
    let a = await this.Swarm_charter_verify(bad_addr, soulPub)
    let e = await this.Swarm_charter_verify(bad_era, soulPub)
    let s = await this.Swarm_charter_verify(bad_soul, soulPub)
    let row = { tampered: 1 }
    if (g === true) { row.genuine_ok = 1 }
    if (a === false) { row.addr_rejected = 1 }
    if (e === false) { row.era_rejected = 1 }
    if (s === false) { row.soul_rejected = 1 }
    this.SwarmCharter_note(w, row)

// beat 4 — the friend's routing.  Bob absorbs Alice's genuine era-1 Charter (verify → land → project the
//  %Body rows) and routes off it.  When Alice moves her Cave and re-charters at era 2 the higher era
//   supersedes; a stale era-1 re-absorb is ignored; a forged Charter is refused; the pier keeps ONE row.
async SwarmCharter_peer(w):
    w i reached:step_4
    let alice = w.c.alice
    if (!alice) { return }
    let bare = alice.sc.prepub
    let soulPub = alice.c.keys.pub
    let bacct = w.oai({ Account: 1, of: 'Bob' })
    bacct.c.up = w
    let bkeys = { prepub: 'bob_prepub_000', pub: 'bob_pub_00000000', key: 'bob_key_000' }
    let bob = this.Swarm_identity(bacct, bkeys, 'Bob')
    bob.c.bodykey = { pub: 'bob_body_pub_00', key: 'bob_body_key_00', prepub: 'bob_body_pre' }
    let bpeer = this.Swarm_peering(bob)
    let pier = bpeer.i({ Pier: 1, prepub: bare, pub: soulPub })
    pier.c.up = bpeer
    let e1 = this.Swarm_charter_wire(alice)
    let got1 = await this.Swarm_charter_absorb(pier, e1, soulPub)
    let caveOverPier1 = this.Charter_addr(pier, 'Cave')
    let bodies1 = pier.o({ Body: 1 }).length
    this.Swarm_body_note(alice, 'charter_cave_pub', 'Cave', bare + '_2')
    await this.Swarm_charter_sign(alice, 2)
    let e2 = this.Swarm_charter_wire(alice)
    let got2 = await this.Swarm_charter_absorb(pier, e2, soulPub)
    let caveOverPier2 = this.Charter_addr(pier, 'Cave')
    let gotStale = await this.Swarm_charter_absorb(pier, e1, soulPub)
    let forged = { era: '9', payload: e2.payload.replace(bare + '_2', bare + '_7'), sig: e2.sig, soul: soulPub }
    let gotForged = await this.Swarm_charter_absorb(pier, forged, soulPub)
    let caveFinal = this.Charter_addr(pier, 'Cave')
    let charterRows = pier.o({ Charter: 1 }).length
    let row = { peered: 1 }
    if (got1 === 1 && caveOverPier1 === bare + '_1' && bodies1 === 2) { row.absorbed = 1 }
    if (got2 === 1 && caveOverPier2 === bare + '_2') { row.superseded = 1 }
    if (gotStale === 0 && caveFinal === bare + '_2') { row.stale_ignored = 1 }
    if (gotForged === 0) { row.forged_refused = 1 }
    if (charterRows === 1) { row.one_pier_charter = 1 }
    this.SwarmCharter_note(w, row)

// ── the witness — %see gated on TRUTH not beat number (no commas; em-dashes) ──
SwarmCharter_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 2)) { return }
    let T = this.SwarmCharter_T(w)
    let s = T.o({ signed: 1 })[0]
    if (!s) { return }
    // #1 THE CHARTER SIGNS AND ROUTES: one row era-stamped self-verifying and Charter_addr resolves each Post.
    if (s && +s.sc.era_one === 1 && +s.sc.one_row === 1 && +s.sc.self_verifies === 1 && +s.sc.cave_resolves === 1 && +s.sc.captain_bare === 1 && +s.sc.none_null === 1) { this.story_swear(w, 'the soul signs its division into one era-stamped Charter that verifies against its own pub — and routing reads the address for a Post off it the Cave at its suffix the Captain at the bare name an unheld Post nothing') }
    let t = T.o({ tampered: 1 })[0]
    // #2 TAMPER FAILS THE SIGNATURE: a moved address a bumped era a swapped soul all rejected — genuine still ok.
    if (t && +t.sc.genuine_ok === 1 && +t.sc.addr_rejected === 1 && +t.sc.era_rejected === 1 && +t.sc.soul_rejected === 1) { this.story_swear(w, 'a tampered Charter fails the signature — move an address bump the era swap the soul and each is rejected while the untouched Charter still verifies so a spoofed I-am-your-Cave cannot pass') }
    let p = T.o({ peered: 1 })[0]
    // #3 A FRIEND ABSORBS AND ROUTES: verify → land → project the %Body rows → route to the serving Cave.
    if (p && +p.sc.absorbed === 1) { this.story_swear(w, 'a friend absorbs the signed Charter and routes off it — verify then land then project the roster into per-body rows so routing off %Body IS routing off the Charter one hop removed') }
    // #4 HIGHEST ERA WINS: a newer era supersedes when the division moves and a stale era is ignored.
    if (p && +p.sc.superseded === 1 && +p.sc.stale_ignored === 1) { this.story_swear(w, 'the highest era wins — when the soul moves its Cave and re-charters the newer era supersedes and a stale earlier era is ignored so a split-brain cannot flap the routing') }
    // #5 FORGED REFUSED AND MERGED IN PLACE: a bad signature never lands and the pier keeps ONE Charter row.
    if (p && +p.sc.forged_refused === 1 && +p.sc.one_pier_charter === 1) { this.story_swear(w, 'a forged Charter is refused at absorb and the pier keeps exactly one Charter row merged in place — the attestation never churns into a row-per-era') }

// SwarmCharter_order — float A:SwarmCharter to the front of H/* so the Run snap stays readable.
async SwarmCharter_order(w):
    let As = H.o({A: 1})
    if (!As.length) { return }
    let first = (a) => (a.sc.A === 'SwarmCharter') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)

// ══ SwarmPost — the Post is the grant projected (Division_todo step 3) ═══════════════════════════════════
//  §POST'S TRUTH CHAIN #1: a body's Post is NOT a string it picks — it IS the `%Grant:My<Post>` its Seat
//   cross-signed, revocable via %NotGrant.  This Book rides the SAME SwarmRole rails (mint the invite →
//    redeem over the pump → a mutual %Pier wearing the feature) and proves a body READS its Post off that
//     grant and DROPS it when a %NotGrant retires it — the imperial-realm truth given a signature.
//   beat 2  Alice (the Seat) stands with three counterparts — Cara (a Cave body) Dave (a Captain body)
//            Bob (a plain Music friend)
//   beat 3  Alice mints MyCave + MyCaptain + Music off the one machinery; all three redeem and seal
//   beat 4  Alice takes the two body rows with NO hand-passed role and DERIVES each Post off its grant —
//            Cave from MyCave Captain from MyCaptain — while a Music grant confers NO Post (a capability
//             is not a role) and the pure map holds
//   beat 5  Alice %NotGrants the MyCave — re-deriving now DROPS Cara's Post while her body row STANDS
//            (a body without a Post is undivided not deleted — change is revoke plus re-issue)
//  CONVENTION (Swarm*): the world MUST be named SwarmPost.

SwarmPost(A,w):
    w oai %req:wrangle,eternal
        await &SwarmPost_drive,w,req
        req%ok = 1

SwarmPost_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

SwarmPost_note(w, sc):
    let t = this.SwarmPost_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

async SwarmPost_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) { await this.SwarmPost_stand(w) }
        if (n === 3) { await this.SwarmPost_seal(w) }
        if (n === 4) { await this.SwarmPost_derive(w) }
        if (n === 5) { await this.SwarmPost_revoke(w) }
    }
    await this.SwarmPost_pump(w)
    this.SwarmPost_witness(w)
    await this.SwarmPost_order(w)

async SwarmPost_pump(w):
    for (const acct of w.o({ Account: 1 })) {
        for (const ident of acct.o({ Identity: 1 })) { await this.Swarm_pump(w, ident) }
    }

async SwarmPost_person(w, name):
    let acct = w.oai({ Account: 1, of: name })
    acct.c.up = w
    let keys = await this.Swarm_mint_keys('SwarmPost-' + name)
    return this.Swarm_identity(acct, keys, name)

SwarmPost_ident(w, name):
    return w.o({ Account: 1, of: name })[0]?.o({ Identity: 1 })[0]

// beat 2 — the Seat and three counterparts: a Cave body a Captain body and a plain Music friend.
async SwarmPost_stand(w):
    w i reached:step_2
    w.sc.now = 1751650000
    await this.SwarmPost_person(w, 'Alice')
    await this.SwarmPost_person(w, 'Cara')
    await this.SwarmPost_person(w, 'Dave')
    await this.SwarmPost_person(w, 'Bob')

// beat 3 — the one machinery mints all three features; each redeems and seals over the pump.
async SwarmPost_seal(w):
    w i reached:step_3
    w.sc.now = 1751650010
    let alice = this.SwarmPost_ident(w, 'Alice')
    w.c.cave_iz = await this.Swarm_mint_idzeug(w, alice, { MyCave: 1 }, 'post_cave')
    w.c.capt_iz = await this.Swarm_mint_idzeug(w, alice, { MyCaptain: 1 }, 'post_capt')
    w.c.music_iz = await this.Swarm_mint_idzeug(w, alice, { Music: 1 }, 'post_music')
    this.Swarm_online(alice, true)
    let cara = this.SwarmPost_ident(w, 'Cara')
    let dave = this.SwarmPost_ident(w, 'Dave')
    let bob = this.SwarmPost_ident(w, 'Bob')
    this.Swarm_online(cara, true)
    this.Swarm_online(dave, true)
    this.Swarm_online(bob, true)
    await this.Swarm_redeem(w, cara, w.c.cave_iz)
    await this.Swarm_redeem(w, dave, w.c.capt_iz)
    await this.Swarm_redeem(w, bob, w.c.music_iz)

// beat 4 — the derivation.  Take the body rows with NO role, then read the Post off each grant: the
//  MyCave pier confers Cave the MyCaptain pier confers Captain the Music pier confers nothing.
async SwarmPost_derive(w):
    w i reached:step_4
    let alice = this.SwarmPost_ident(w, 'Alice')
    if (!alice) { return }
    let cara = this.SwarmPost_ident(w, 'Cara')
    let dave = this.SwarmPost_ident(w, 'Dave')
    let bob = this.SwarmPost_ident(w, 'Bob')
    let peering = this.Swarm_peering(alice)
    let pierC = peering.o({ Pier: 1, pub: cara.sc.prepub })[0]
    let pierD = peering.o({ Pier: 1, pub: dave.sc.prepub })[0]
    let pierB = peering.o({ Pier: 1, pub: bob.sc.prepub })[0]
    if (!pierC || !pierD || !pierB) { return }
    let bare = alice.sc.prepub
    this.Swarm_body_take(alice, cara.c.keys.pub, null, bare + '_1')
    this.Swarm_body_take(alice, dave.c.keys.pub, null, bare)
    let rc = this.Swarm_body_repost(alice, cara.c.keys.pub, pierC)
    let rd = this.Swarm_body_repost(alice, dave.c.keys.pub, pierD)
    let bobPost = this.Swarm_grant_post(pierB)
    let row = { derived: 1 }
    if (rc && rc.sc.post === 'Cave') { row.cave_from_grant = 1 }
    if (rd && rd.sc.post === 'Captain') { row.captain_from_grant = 1 }
    if (bobPost === null) { row.music_no_post = 1 }
    if (this.Swarm_post_from_feature('MyCave') === 'Cave' && this.Swarm_post_from_feature('MyCaptain') === 'Captain' && this.Swarm_post_from_feature('Music') === null) { row.map_pure = 1 }
    this.SwarmPost_note(w, row)

// beat 5 — the revoke.  Alice %NotGrants the MyCave; re-deriving now drops Cara's Post while her body
//  row stands (change = revoke + re-issue; a Post-less body is undivided not deleted).
async SwarmPost_revoke(w):
    w i reached:step_5
    w.sc.now = 1751650030
    let alice = this.SwarmPost_ident(w, 'Alice')
    if (!alice) { return }
    let cara = this.SwarmPost_ident(w, 'Cara')
    let peering = this.Swarm_peering(alice)
    let pierC = peering.o({ Pier: 1, pub: cara.sc.prepub })[0]
    if (!pierC) { return }
    await this.Swarm_revoke(w, alice, pierC, 'MyCave')
    let postAfter = this.Swarm_grant_post(pierC)
    let rc = this.Swarm_body_repost(alice, cara.c.keys.pub, pierC)
    let stillThere = peering.o({ Body: 1, pub: cara.c.keys.pub })[0]
    let row = { revoked: 1 }
    if (postAfter === null) { row.post_gone = 1 }
    if (rc && !rc.sc.post) { row.role_dropped = 1 }
    if (stillThere) { row.body_kept = 1 }
    this.SwarmPost_note(w, row)

// ── the witness — %see gated on TRUTH not beat number (no commas; em-dashes) ──
SwarmPost_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 4)) { return }
    let T = this.SwarmPost_T(w)
    let d = T.o({ derived: 1 })[0]
    if (!d) { return }
    // #1 THE POST IS THE GRANT PROJECTED: Cave read off MyCave Captain off MyCaptain and the map is pure.
    if (d && +d.sc.cave_from_grant === 1 && +d.sc.captain_from_grant === 1 && +d.sc.map_pure === 1) { this.story_swear(w, 'a body reads its Post off the grant — the MyCave pier confers Cave the MyCaptain pier confers Captain and the Post is never a string the body picks but the invite feature projected') }
    // #2 A CAPABILITY IS NOT A POST: a Music grant confers no Post — roles and capabilities do not blur.
    if (d && +d.sc.music_no_post === 1) { this.story_swear(w, 'a capability is not a Post — a Music grant confers no role so serving music and being a body stay distinct kinds of grant') }
    let r = T.o({ revoked: 1 })[0]
    // #3 A NOTGRANT DROPS THE POST BUT KEEPS THE BODY: revoke retires the role while the body row stands.
    if (r && +r.sc.post_gone === 1 && +r.sc.role_dropped === 1 && +r.sc.body_kept === 1) { this.story_swear(w, 'a NotGrant drops the Post but keeps the body — re-deriving after the revoke retires the role while the body row still stands so a Post-less body is undivided not deleted') }

// SwarmPost_order — float A:SwarmPost to the front of H/* so the Run snap stays readable.
async SwarmPost_order(w):
    let As = H.o({A: 1})
    if (!As.length) { return }
    let first = (a) => (a.sc.A === 'SwarmPost') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)

// ══ SwarmGossip — the Charter crosses the real wire (Division_todo step 4) ═══════════════════════════════
//  §POST'S TRUTH CHAIN: the signed Charter is only useful if a friend HEARS it.  This Book rides the SAME
//   redeem→seal→pump machinery Music rides and proves a `charter` frame is (a) SEEDED at the seal — a
//    freshly sealed friend learns the division with no ask — and (b) RE-EMITTED on a division change, with
//     the highest era winning on the receiver over the wire as it does in memory.
//   beat 2  Alice divides (Captain bare + Cave _1) and signs her Charter at era 1
//   beat 3  Bob befriends Alice over the real handshake — and by seal's end Bob's pier ALREADY holds
//            Alice's era-1 Charter (the seed at pier_confirm) and routes to her Cave at _1
//   beat 4  Alice moves her Cave to _2 re-charters at era 2 and re-gossips — Bob's pier supersedes to era
//            2 and routes to _2 — while a genuine-but-OLD era-1 frame re-delivered over the wire is ignored
//  CONVENTION (Swarm*): the world MUST be named SwarmGossip.

SwarmGossip(A,w):
    w oai %req:wrangle,eternal
        await &SwarmGossip_drive,w,req
        req%ok = 1

SwarmGossip_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

async SwarmGossip_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) { await this.SwarmGossip_stand(w) }
        if (n === 3) { await this.SwarmGossip_seal(w) }
        if (n === 4) { await this.SwarmGossip_change(w) }
    }
    await this.SwarmGossip_pump(w)
    this.SwarmGossip_witness(w)
    await this.SwarmGossip_order(w)

async SwarmGossip_pump(w):
    for (const acct of w.o({ Account: 1 })) {
        for (const ident of acct.o({ Identity: 1 })) { await this.Swarm_pump(w, ident) }
    }

async SwarmGossip_person(w, name):
    let acct = w.oai({ Account: 1, of: name })
    acct.c.up = w
    let keys = await this.Swarm_mint_keys('SwarmGossip-' + name)
    return this.Swarm_identity(acct, keys, name)

SwarmGossip_ident(w, name):
    return w.o({ Account: 1, of: name })[0]?.o({ Identity: 1 })[0]

// beat 2 — Alice divides and signs era 1.  The era-1 wire is stashed for the stale-gossip tooth in beat 4.
async SwarmGossip_stand(w):
    w i reached:step_2
    w.sc.now = 1751680000
    let alice = await this.SwarmGossip_person(w, 'Alice')
    await this.SwarmGossip_person(w, 'Bob')
    let bare = alice.sc.prepub
    alice.c.bodykey = await this.Swarm_mint_keys('SwarmGossip-Alice-body')
    this.Swarm_body_take(alice, null, 'Captain', bare)
    this.Swarm_body_note(alice, 'gossip_cave_pub', 'Cave', bare + '_1')
    await this.Swarm_charter_sign(alice, 1)
    w.c.e1_wire = this.Swarm_charter_wire(alice)

// beat 3 — the real seal.  Bob redeems a Music invite; the handshake plays out over the pump, and Alice's
//  seed (at the pier_confirm she processes) gossips her era-1 Charter to Bob within the same beat.
async SwarmGossip_seal(w):
    w i reached:step_3
    w.sc.now = 1751680010
    let alice = this.SwarmGossip_ident(w, 'Alice')
    w.c.music_iz = await this.Swarm_mint_idzeug(w, alice, { Music: 1 }, 'gossip_m1')
    this.Swarm_online(alice, true)
    let bob = this.SwarmGossip_ident(w, 'Bob')
    this.Swarm_online(bob, true)
    await this.Swarm_redeem(w, bob, w.c.music_iz)
    // settle the seal + the seed-at-seal absorb WITHIN this beat, then capture the seed as a STABLE note.
    //  The era-1 window is transient (beat 4 supersedes it on the very next step, before a live witness can
    //   catch it), so the seed is proven HERE — after the pump drains — not by a live read.
    for (let i = 0; i < 8; i++) { await this.SwarmGossip_pump(w) }
    let bare = alice.sc.prepub
    let bpier = this.Swarm_peering(bob)?.o({ Pier: 1, pub: alice.sc.prepub })[0]
    let bch = bpier ? bpier.o({ Charter: 1 })[0] : null
    let t = this.SwarmGossip_T(w)
    let mark = t.i({ seeded: 1 })
    mark.c.up = t
    if (bch && bch.sc.era === '1' && this.Charter_addr(bpier, 'Cave') === bare + '_1') { mark.sc.seed_at_seal = 1 }

// beat 4 — the division moves and re-gossips; then a stale era-1 frame is re-delivered as the tooth.
async SwarmGossip_change(w):
    w i reached:step_4
    w.sc.now = 1751680020
    let alice = this.SwarmGossip_ident(w, 'Alice')
    if (!alice) { return }
    let bare = alice.sc.prepub
    this.Swarm_body_note(alice, 'gossip_cave_pub', 'Cave', bare + '_2')
    await this.Swarm_charter_sign(alice, 2)
    this.Swarm_charter_gossip(w, alice)
    let bob = this.SwarmGossip_ident(w, 'Bob')
    if (w.c.e1_wire && bob) {
        this.Swarm_deliver(w, alice, bob.sc.prepub, { kind: 'charter', charter: w.c.e1_wire, page: this.Swarm_page(alice) })
        let t = this.SwarmGossip_T(w)
        let mark = t.i({ stale_sent: 1 })
        mark.c.up = t
    }

// ── the witness — reads Bob's LIVE pier each pass; %see fires the pass a truth holds ──
SwarmGossip_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 3)) { return }
    let alice = this.SwarmGossip_ident(w, 'Alice')
    let bob = this.SwarmGossip_ident(w, 'Bob')
    if (!alice || !bob) { return }
    let bare = alice.sc.prepub
    let pier = this.Swarm_peering(bob)?.o({ Pier: 1, pub: alice.sc.prepub })[0]
    if (!pier) { return }
    let ch = pier.o({ Charter: 1 })[0]
    // #1 SEEDED AT THE SEAL: Bob learned Alice's division at seal over the armed frame — no ask.  Read off
    //  the stable beat-3 note (the live era-1 is gone by the time a witness could see it — see the seal).
    let seeded = this.SwarmGossip_T(w).o({ seeded: 1 })[0]
    if (seeded && +seeded.sc.seed_at_seal === 1) { this.story_swear(w, 'the Charter is seeded at the seal — a freshly sealed friend hears the division over the armed charter frame and routes to the Cave at its suffix without ever asking') }
    // #2 RE-EMITTED ON CHANGE: a higher era gossiped after the move supersedes on the friend.
    if (ch && ch.sc.era === '2' && this.Charter_addr(pier, 'Cave') === bare + '_2') { this.story_swear(w, 'a division change re-emits the Charter — the soul moves its Cave and re-charters and the gossiped higher era supersedes on the friend so routing follows the move') }
    // #3 A STALE GOSSIP IS IGNORED: an older era re-delivered over the wire never downgrades the friend.
    let stale = this.SwarmGossip_T(w).o({ stale_sent: 1 })[0]
    if (ch && ch.sc.era === '2' && stale && this.Charter_addr(pier, 'Cave') === bare + '_2') { this.story_swear(w, 'a stale gossiped Charter is ignored — an older era re-delivered over the wire never downgrades the friend so the split-brain guard holds end to end') }

// SwarmGossip_order — float A:SwarmGossip to the front of H/* so the Run snap stays readable.
async SwarmGossip_order(w):
    let As = H.o({A: 1})
    if (!As.length) { return }
    let first = (a) => (a.sc.A === 'SwarmGossip') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)

// ══ SwarmServe — the serve binding: resolve-and-emit (Division_todo step 5) ══════════════════════════════
//  §ROUTING: a paradigm's dial reads WHERE a Post's server is off the Charter and EMITS — no liveness
//   cache.  This Book grounds the music serve on per-body routing: a friend serving Music to Alice
//    resolves her CAVE's address off the signed Charter (not the bare soul id) and the frame lands THERE;
//     with no Charter it degrades to the Seat; without the Music grant the dial refuses and emits nothing.
//   beat 2  Alice divides (Captain bare + Cave at its own address) signs her Charter and befriends Bob
//            over the real seal (a Music grant + the seeded Charter); the Cave department is an online node
//   beat 3  Bob serves Music to Alice's Cave — serve_to resolves the CAVE address off the Charter and the
//            emit LANDS at the Cave department not at the bare Seat (per-body routing proven end to end)
//   beat 4  the edges — a charter-less pier resolves to the Seat (the bare name the always-on fallback) —
//            and after the Music grant is revoked the dial REFUSES and emits nothing (the gate at use)
//  CONVENTION (Swarm*): the world MUST be named SwarmServe.

SwarmServe(A,w):
    w oai %req:wrangle,eternal
        await &SwarmServe_drive,w,req
        req%ok = 1

SwarmServe_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

SwarmServe_note(w, sc):
    let t = this.SwarmServe_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

async SwarmServe_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) { await this.SwarmServe_stand(w) }
        if (n === 3) { await this.SwarmServe_serve(w) }
        if (n === 4) { await this.SwarmServe_edge(w) }
    }
    await this.SwarmServe_pump(w)
    this.SwarmServe_witness(w)
    await this.SwarmServe_order(w)

async SwarmServe_pump(w):
    for (const acct of w.o({ Account: 1 })) {
        for (const ident of acct.o({ Identity: 1 })) { await this.Swarm_pump(w, ident) }
    }

async SwarmServe_person(w, name):
    let acct = w.oai({ Account: 1, of: name })
    acct.c.up = w
    let keys = await this.Swarm_mint_keys('SwarmServe-' + name)
    return this.Swarm_identity(acct, keys, name)

SwarmServe_ident(w, name):
    return w.o({ Account: 1, of: name })[0]?.o({ Identity: 1 })[0]

// beat 2 — Alice divides, signs, and seals with Bob.  The Cave department is a distinct ONLINE node whose
//  prepub IS the Cave address (the mail wire routes by prepub — the model-layer stand-in for the relay's
//   suffix routing), so an emit to the Cave address actually LANDS somewhere the Book can see.
async SwarmServe_stand(w):
    w i reached:step_2
    w.sc.now = 1751690000
    let alice = await this.SwarmServe_person(w, 'Alice')
    await this.SwarmServe_person(w, 'Bob')
    let cacct = w.oai({ Account: 1, of: 'CaveBody' })
    cacct.c.up = w
    let caveKeys = { prepub: 'cave_dept_addr', pub: 'cave_dept_pub00', key: 'cave_dept_key' }
    let caveBody = this.Swarm_identity(cacct, caveKeys, 'CaveDept')
    this.Swarm_online(caveBody, true)
    let bare = alice.sc.prepub
    alice.c.bodykey = await this.Swarm_mint_keys('SwarmServe-Alice-body')
    this.Swarm_body_take(alice, null, 'Captain', bare)
    this.Swarm_body_note(alice, 'serve_cave_pub', 'Cave', 'cave_dept_addr')
    await this.Swarm_charter_sign(alice, 1)
    w.c.music_iz = await this.Swarm_mint_idzeug(w, alice, { Music: 1 }, 'serve_m1')
    this.Swarm_online(alice, true)
    let bob = this.SwarmServe_ident(w, 'Bob')
    this.Swarm_online(bob, true)
    await this.Swarm_redeem(w, bob, w.c.music_iz)

// beat 3 — the serve.  Ensure Bob's pier holds the current Charter (absorb is idempotent — the seed at
//  seal already carried it; this removes timing from the proof), resolve the Cave address off it, EMIT.
async SwarmServe_serve(w):
    w i reached:step_3
    let alice = this.SwarmServe_ident(w, 'Alice')
    let bob = this.SwarmServe_ident(w, 'Bob')
    if (!alice || !bob) { return }
    let pier = this.Swarm_peering(bob)?.o({ Pier: 1, pub: alice.sc.prepub })[0]
    if (!pier) { return }
    let wire = this.Swarm_charter_wire(alice)
    if (wire) { await this.Swarm_charter_absorb(pier, wire, alice.c.keys.pub) }
    let to = this.Swarm_serve_to(pier, 'Cave')
    let ok = await this.Swarm_serve_ask(w, bob, pier, 'Cave', { kind: 'serveprobe', tune: 'serve-probe' })
    let caveBody = this.SwarmServe_ident(w, 'CaveBody')
    let inbox = caveBody?.o({ mail: 1 })[0]
    let landed = inbox ? inbox.o({ frame: 'serveprobe' }).length : 0
    let row = { served: 1 }
    if (to === 'cave_dept_addr') { row.resolved_cave = 1 }
    if (ok === true) { row.emit_ok = 1 }
    if (landed >= 1) { row.landed_at_cave = 1 }
    this.SwarmServe_note(w, row)

// beat 4 — the edges.  A charter-less pier falls back to the Seat (the bare name).  Then the Music grant
//  is revoked on Bob's pier and the dial REFUSES — false, and the Cave inbox does not grow (the gate).
async SwarmServe_edge(w):
    w i reached:step_4
    w.sc.now = 1751690030
    let alice = this.SwarmServe_ident(w, 'Alice')
    let bob = this.SwarmServe_ident(w, 'Bob')
    if (!alice || !bob) { return }
    let bare = alice.sc.prepub
    let pier = this.Swarm_peering(bob)?.o({ Pier: 1, pub: alice.sc.prepub })[0]
    if (!pier) { return }
    // (a) FALLBACK — Carol's pier to Alice carries NO Charter → serve_to = the Seat (the bare name).
    let cacct = w.oai({ Account: 1, of: 'Carol' })
    cacct.c.up = w
    let ckeys = { prepub: 'carol_prepub_0', pub: 'carol_pub_000000', key: 'carol_key_0' }
    let carol = this.Swarm_identity(cacct, ckeys, 'Carol')
    let cpeer = this.Swarm_peering(carol)
    let cpier = cpeer.i({ Pier: 1, pub: bare })
    cpier.c.up = cpeer
    let seatAddr = this.Swarm_serve_to(cpier, 'Cave')
    // (b) GATE — revoke the Music grant on Bob's pier; the dial refuses and emits nothing.
    let caveBody = this.SwarmServe_ident(w, 'CaveBody')
    let inbox0 = caveBody?.o({ mail: 1 })[0]
    let before = inbox0 ? inbox0.o({ frame: 'serveprobe' }).length : 0
    await this.Swarm_revoke(w, bob, pier, 'Music')
    let gated = await this.Swarm_serve_ask(w, bob, pier, 'Cave', { kind: 'serveprobe', tune: 'gated-probe' })
    let after = inbox0 ? inbox0.o({ frame: 'serveprobe' }).length : 0
    let row = { edged: 1 }
    if (seatAddr === bare) { row.fallback_seat = 1 }
    if (gated === false) { row.gate_refused = 1 }
    if (after === before) { row.no_emit_when_gated = 1 }
    this.SwarmServe_note(w, row)

// ── the witness — %see gated on TRUTH not beat number (no commas; em-dashes) ──
SwarmServe_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 3)) { return }
    let T = this.SwarmServe_T(w)
    let s = T.o({ served: 1 })[0]
    if (!s) { return }
    // #1 RESOLVE-AND-EMIT: the Cave address read off the Charter and the frame lands THERE not at the Seat.
    if (s && +s.sc.resolved_cave === 1 && +s.sc.emit_ok === 1 && +s.sc.landed_at_cave === 1) { this.story_swear(w, 'the serve dial resolves and emits — a friend serving music reads the Cave address off the signed Charter and the frame lands at the serving body not at the bare soul id') }
    let e = T.o({ edged: 1 })[0]
    // #2 FALLBACK TO THE SEAT: no Charter → dial the bare name (the always-on anchor the relay can always route).
    if (e && +e.sc.fallback_seat === 1) { this.story_swear(w, 'a Post with no Charter entry degrades to the Seat — resolve-and-emit falls back to the bare name so a missing entry fails forward dark never wrong') }
    // #3 THE GATE AT USE: no live Music grant → the dial refuses and emits nothing.
    if (e && +e.sc.gate_refused === 1 && +e.sc.no_emit_when_gated === 1) { this.story_swear(w, 'the grant gate is checked at use — once the Music grant is revoked the serve dial refuses and emits nothing so resolution never outruns permission') }

// SwarmServe_order — float A:SwarmServe to the front of H/* so the Run snap stays readable.
async SwarmServe_order(w):
    let As = H.o({A: 1})
    if (!As.length) { return }
    let first = (a) => (a.sc.A === 'SwarmServe') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)

// ══ SwarmSpread — the CEREMONY: spread out by scanning (Division_todo §CEREMONY / LinkDevice) ════════════
//  The ACT of dividing, proven at the model layer.  A blank device (just a body key, no soul, no role)
//   offers itself; the soul-holder seals its whole account across (Sealbox), proposes Cave, the device
//    consents, and both end up bodies of ONE soul with Posts + a Charter.  Rides the proven bricks:
//     Swarm_export/import (the account blob) + seal/unseal (proven by SwarmSeal) + mint_grant +
//      Swarm_body_repost + Swarm_charter_sign.  The Book drives both sides in-process (the live wire
//       routes same-soul bodies by suffix address — the relay's job, not the mail wire's).
//   beat 2  Alice (a soul) + a BLANK box (only a body key).  The box mints a role-agnostic adoption offer
//            and it verifies (the box proves it holds the key nobody will otherwise seal an account to)
//   beat 3  Alice DIVIDES: verify → seal her account to the box's key → mint %Grant:MyCave → the box
//            CONSENTS + unseals + imports (now it HOLDS her soul key) + derives Post=Cave from the grant;
//             Alice finalises (Captain at bare + Cave at its suffix) and writes Charter #1 that routes both
//   beat 4  the teeth — a tampered seal a wrong nonce and a withheld consent each yield NO body (the soul
//            never crosses to a device that flubs the seal or that the human did not confirm)
//  CONVENTION (Swarm*): the world MUST be named SwarmSpread.

SwarmSpread(A,w):
    w oai %req:wrangle,eternal
        await &SwarmSpread_drive,w,req
        req%ok = 1

SwarmSpread_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

SwarmSpread_note(w, sc):
    let t = this.SwarmSpread_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

async SwarmSpread_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) { await this.SwarmSpread_stand(w) }
        if (n === 3) { await this.SwarmSpread_divide(w) }
        if (n === 4) { await this.SwarmSpread_teeth(w) }
        if (n === 5) { await this.SwarmSpread_ferry(w) }
    }
    await this.SwarmSpread_pump(w)
    this.SwarmSpread_witness(w)
    await this.SwarmSpread_order(w)

async SwarmSpread_pump(w):
    for (const acct of w.o({ Account: 1 })) {
        for (const ident of acct.o({ Identity: 1 })) { await this.Swarm_pump(w, ident) }
    }

// beat 2 — a soul, and a blank box that offers itself.  Fixed seeds + pinned clock keep the offer (a
//  deterministic ed25519 presig) byte-repeatable.
async SwarmSpread_stand(w):
    w i reached:step_2
    w.sc.now = 1751700000
    let aacct = w.oai({ Account: 1, of: 'Alice' })
    aacct.c.up = w
    let akeys = await this.Swarm_mint_keys('SwarmSpread-Alice')
    let alice = this.Swarm_identity(aacct, akeys, 'Alice')
    alice.c.bodykey = await this.Swarm_mint_keys('SwarmSpread-Alice-body')
    w.c.alice = alice
    this.Swarm_online(alice, true)
    // the BLANK box — only a body key, addressable at its body-key prepub so the seal can reach it.
    let bacct = w.oai({ Account: 1, of: 'Box' })
    bacct.c.up = w
    w.c.bacct = bacct
    let bkeys = await this.Swarm_mint_keys('SwarmSpread-Box-body')
    w.c.bkeys = bkeys
    let bproto = this.Swarm_identity(bacct, bkeys, 'Box')
    this.Swarm_online(bproto, true)
    let offer = await this.Swarm_adopt_offer(bkeys, 'spread_nonce_1')
    w.c.offer = offer
    let verified = await this.Swarm_adopt_verify(offer)
    let row = { stood: 1 }
    if (verified === true) { row.offer_verifies = 1 }
    if (offer && !offer.role) { row.role_agnostic = 1 }
    this.SwarmSpread_note(w, row)

// beat 3 — the division.  Alice redeems (delivers the sealed account to the box); the box absorbs with
//  consent and becomes a body; Alice finalises + charters.  The seal frame is read off the box's inbox
//   (the real wire path), then handed to absorb (the human's confirm).
async SwarmSpread_divide(w):
    w i reached:step_3
    let alice = w.c.alice
    let bacct = w.c.bacct
    let bkeys = w.c.bkeys
    let offer = w.c.offer
    if (!alice || !bacct || !offer) { return }
    let crossed = await this.Swarm_adopt_redeem(w, alice, offer, 'Cave')
    let bproto = bacct.o({ Identity: 1 }).find((i) => i.sc.prepub === bkeys.prepub)
    let m = bproto ? bproto.o({ mail: 1 })[0]?.o({ frame: 'adopt_seal' })[0] : null
    let frame = m ? m.c.frame : null
    w.c.frame = frame
    let bident = frame ? await this.Swarm_adopt_absorb(w, bacct, bkeys, offer.nonce, frame, 1) : null
    w.c.bident = bident
    // Alice finalises the division off the box's confirmed body — land-of-prepub: NO seat to assign,
    //  each body answers at its own key-derived name (Swarm_body_addr).
    let bare = alice.sc.prepub
    if (bident) { await this.Swarm_adopt_finalise(w, alice, 'Captain', { pub: bkeys.pub, role: 'Cave' }, 1) }
    let peering = this.Swarm_peering(alice)
    let charter = peering ? peering.o({ Charter: 1 })[0] : null
    let wire = this.Swarm_charter_wire(alice)
    let charter_ok = wire ? await this.Swarm_charter_verify(wire, alice.c.keys.pub) : false
    let boxBody = bident ? this.Swarm_body_mine(bident) : null
    let row = { divided: 1 }
    if (crossed === true) { row.sealed_crossed = 1 }
    if (bident && bident.c.keys && String(bident.c.keys.pub) === String(alice.c.keys.pub)) { row.account_crossed = 1 }
    if (boxBody && boxBody.sc.post === 'Cave') { row.box_is_cave = 1 }
    let caveRow = this.Swarm_body_for(alice, 'Cave')
    let caveAt = caveRow ? this.Swarm_body_addr(caveRow) : ''
    if (caveAt === String(bkeys.prepub) && !caveRow.sc.address) { row.roster_routes_both = 1 }
    if (charter_ok === true && peering.o({ Body: 1 }).length === 2) { row.charter_verifies = 1 }
    this.SwarmSpread_note(w, row)

// beat 4 — the teeth.  A tampered seal a wrong nonce and a withheld consent each produce NO body.
async SwarmSpread_teeth(w):
    w i reached:step_4
    let bkeys = w.c.bkeys
    let offer = w.c.offer
    let frame = w.c.frame
    if (!bkeys || !offer || !frame) { return }
    let ccont = w.oai({ Account: 1, of: 'Cbox' })
    ccont.c.up = w
    let flip = (h) => { let a = String(h).split(''); a[10] = (a[10] === 'a' ? 'b' : 'a'); return a.join('') }
    let bad = { kind: 'adopt_seal', sealed: flip(frame.sealed), salt: frame.salt, grant: frame.grant, role: 'Cave' }
    let tampered = await this.Swarm_adopt_absorb(w, ccont, bkeys, offer.nonce, bad, 1)
    let wrongNonce = await this.Swarm_adopt_absorb(w, ccont, bkeys, 'wrong_nonce_xx', frame, 1)
    let noConsent = await this.Swarm_adopt_absorb(w, ccont, bkeys, offer.nonce, frame, 0)
    let row = { teethed: 1 }
    if (tampered === null) { row.tamper_no_body = 1 }
    if (wrongNonce === null) { row.wrongnonce_no_body = 1 }
    if (noConsent === null) { row.noconsent_no_body = 1 }
    if (ccont.o({ Identity: 1 }).filter((i) => i.sc.prepub === bkeys.prepub).length === 0) { row.no_soul_landed = 1 }
    this.SwarmSpread_note(w, row)

// beat 5 — THE FERRY (the live device-link path, Division_todo §0).  Proves the ferry GLUE end-to-end and
//  deterministically: once a MyCave pier stands, Swarm_ferry_send exports+seals+delivers Alice's WHOLE
//   account over it; the blank Ebox reads the frame off its inbox (the real wire path) and Swarm_ferry_heard
//    unseals it with the fragment code — Ebox now holds the very same soul key, as a Cave.  Fails closed: a
//     fresh device given the frame with a WRONG code lands no account.  The seal ciphertext rides `.c`
//      (m.c.frame), so it never dirties the fixture; the note row is booleans, so the snap stays repeatable.
async SwarmSpread_ferry(w):
    w i reached:step_5
    let alice = w.c.alice
    if (!alice) { return }
    // a fresh blank device, addressable at its body-key prepub (same recipe as the Box in beat 2)
    let eacct = w.oai({ Account: 1, of: 'Ebox' })
    eacct.c.up = w
    let ekeys = await this.Swarm_mint_keys('SwarmSpread-Ebox-body')
    let eproto = this.Swarm_identity(eacct, ekeys, 'Ebox')
    this.Swarm_online(eproto, true)
    // a minimal MyCave pier Alice→Ebox — Swarm_ferry_send reads theirPub off the pier's %Peering and
    //  delivers to pier.sc.pub (same-world mail lands it in Ebox's inbox synchronously, as beat 3's redeem does)
    let peering = this.Swarm_peering(alice)
    let pier = peering.oai({ Pier: 1, pub: ekeys.prepub })
    pier.c.up = peering
    let epage = pier.oai({ Peering: 1, name: ekeys.prepub })
    epage.c.up = pier
    epage.sc.pub = ekeys.pub
    let code = 'ferry_seed_e1'
    let sent = await this.Swarm_ferry_send(w, alice, pier, code)
    let m = eproto.o({ mail: 1 })[0]?.o({ frame: 'ferry' })[0]
    let frame = m ? m.c.frame : null
    let esoul = frame ? await this.Swarm_ferry_heard(w, eproto, frame, code) : null
    // fails-closed — a fresh device given the same frame with a WRONG code unseals nothing
    let fcont = w.oai({ Account: 1, of: 'Fbox' })
    fcont.c.up = w
    let fkeys = await this.Swarm_mint_keys('SwarmSpread-Fbox-body')
    let fproto = this.Swarm_identity(fcont, fkeys, 'Fbox')
    let badHeard = frame ? await this.Swarm_ferry_heard(w, fproto, frame, 'wrong_ferry_code') : null
    let ebody = esoul ? this.Swarm_body_mine(esoul) : null
    let row = { ferried: 1 }
    if (sent === true) { row.ferry_sent = 1 }
    // THE LIBRARY MERGE (Crew_todo §0.1): the account DATA folds INTO the receiving device's own
    //  identity (ferry_heard returns eproto itself); the soul key never crosses — the old row asserted
    //   the copy (the retired model).
    if (esoul && esoul === eproto && esoul.c.keys && String(esoul.c.keys.pub) !== String(alice.c.keys.pub)) { row.ferry_account_crossed = 1 }
    if (ebody && ebody.sc.post === 'Cave') { row.ferry_post_cave = 1 }
    if (badHeard === null) { row.ferry_wrongcode_no_body = 1 }
    this.SwarmSpread_note(w, row)

// ── the witness — %see gated on TRUTH not beat number (no commas; em-dashes) ──
SwarmSpread_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 2)) { return }
    let T = this.SwarmSpread_T(w)
    let s = T.o({ stood: 1 })[0]
    if (!s) { return }
    // #1 THE OFFER IS A ROLE-AGNOSTIC BODY: it verifies (the device proves it holds the key) and wears no role.
    if (s && +s.sc.offer_verifies === 1 && +s.sc.role_agnostic === 1) { this.story_swear(w, 'a blank device offers itself as a body not a role — the adoption offer proves the device holds its own key and carries no Post so the device does not yet know it will be a Cave') }
    let d = T.o({ divided: 1 })[0]
    // #2 THE ACCOUNT CROSSES: the soul seals across and the box now HOLDS the soul key — it became a body.
    if (d && +d.sc.sealed_crossed === 1 && +d.sc.account_crossed === 1) { this.story_swear(w, 'the soul seals across on a scan — the soul-holder seals its whole account to the blank device and the device unseals it and now holds the very same soul key so it is no longer blank but a body of that soul') }
    // #3 THE POST IS THE PROPOSED GRANT AND THE CHARTER ROUTES BOTH: box→Cave phone→Captain both routed.
    if (d && +d.sc.box_is_cave === 1 && +d.sc.roster_routes_both === 1 && +d.sc.charter_verifies === 1) { this.story_swear(w, 'the device consents to the role and the roster routes both — the box derives Cave from the proposed grant the phone takes Captain and each body answers at its own key-derived name — the first charter still verifies while carrying no seat column at all') }
    let t = T.o({ teethed: 1 })[0]
    // #4 THE TEETH: a tampered seal a wrong nonce a withheld consent each yield NO body and no soul lands.
    if (t && +t.sc.tamper_no_body === 1 && +t.sc.wrongnonce_no_body === 1 && +t.sc.noconsent_no_body === 1 && +t.sc.no_soul_landed === 1) { this.story_swear(w, 'the ceremony fails closed — a tampered seal a wrong nonce and a withheld consent each produce no body and the soul never lands on a device that flubbed the seal or that the human did not confirm') }
    let f = T.o({ ferried: 1 })[0]
    // #5 THE FERRY (the live path): the handshake-formed pier carries the whole sealed account across; wrong code lands nothing.
    if (f && +f.sc.ferry_sent === 1 && +f.sc.ferry_account_crossed === 1 && +f.sc.ferry_post_cave === 1 && +f.sc.ferry_wrongcode_no_body === 1) { this.story_swear(w, 'the account ferries over the sealed pier — once a MyCave pier stands the soul exports and seals its account data across to the device which unseals it with the fragment code and folds it into its own identity as a Cave keeping its own key while the soul key never crosses and a wrong code lands no account at all') }

// SwarmSpread_order — float A:SwarmSpread to the front of H/* so the Run snap stays readable.
async SwarmSpread_order(w):
    let As = H.o({A: 1})
    if (!As.length) { return }
    let first = (a) => (a.sc.A === 'SwarmSpread') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)

// ══ SwarmReboot — DOES IT SURVIVE A RELOAD? (2026-09-03, the owner: "no-FSA mode … it just seems very
//  important to get through the model") ═══════════════════════════════════════════════════════════════
//  THE GAP THIS BOOK CLOSES: durable identity state has four homes — the C tree (live only), the House
//   STASH (Dexie, no folder needed), the ACCOUNT SNAP (.jamsend/…/toc.snap, needs a real nav ⇒ a FOLDER),
//    and body-local Dexie.  A PHONE has no folder (no browser on a phone has showDirectoryPicker), so on
//     a phone the stash is the ONLY durable home, and its whole surface is Swarm_restash_all.  Anything
//      not in a pillar dies at the next boot — silently.  That is how /Crew + Grant:Crew (moved off the
//       %Pier this morning) and every standing %Reach were lost on exactly the devices they are for.
//  Until today NO Book could see any of it: every _stash verb was gated on `Swarm_live_self() === ident`
//   AND `top_House().stashed`, both false in a Book world.  Swarm_stash_of makes the stash a PARAMETER —
//    a caller with its own scratch stash needs no guard — so a fixture can finally drive the round trip:
//     populate → restash → WIPE the tree → rehydrate → swear it all came back.
//  Covers ALL SIX pillars: piers (with page + grants) · izzes (a named serial) · chainroots · roster ·
//   crew (with the cert) · reaches (standing only).  Every _stash writer takes the stash as a parameter.
SwarmReboot(A,w):
    w oai %req:wrangle,eternal
        await &SwarmReboot_drive,w,req
        req%ok = 1

SwarmReboot_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

SwarmReboot_note(w, sc):
    let t = this.SwarmReboot_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

async SwarmReboot_drive(w, req):
    // A BOOK DECLARES ITS OWN BEAT COUNT (the Vytonation idiom).  Without this a Book with no recorded
    //  toc runs HOLLOW from the CLI — total 1, one step, green, zero beats fired — because a fresh Run
    //   grows its total only by a human pressing Resume in the editor.  'new' mode only: a recorded Book
    //    takes its total from the toc.
    let run = (this.c.run)
    if (run && run.sc && run.sc.mode === 'new') { run.sc.total = 5 }
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) { await this.SwarmReboot_stand(w) }
        if (n === 3) { await this.SwarmReboot_stash(w) }
        if (n === 4) { await this.SwarmReboot_wipe(w) }
        if (n === 5) { await this.SwarmReboot_back(w) }
    }
    this.SwarmReboot_witness(w)
    await this.SwarmReboot_order(w)

// beat 2 — A LIVED-IN ACCOUNT: Reba the Captain with every shelf a real account carries — a friend pier
//  with its grant, a self-issued Idzeug, a %Body roster row, a /Crew ledger (my Captain row + a Cave mate
//   holding my Grant:Crew), and two %Reach bookings: one STANDING and one already arrived.
async SwarmReboot_stand(w):
    w i reached:step_2
    w.sc.now = 1751700000
    let acct = w.oai({ Account: 1, of: 'Reba' })
    acct.c.up = w
    let keys = await this.Swarm_mint_keys('SwarmReboot-Reba')
    let reba = this.Swarm_identity(acct, keys, 'Reba')
    w.c.reba = reba
    let mate = await this.Swarm_mint_keys('SwarmReboot-Mate')
    w.c.matekeys = mate
    // a friend pier, the transport shelf (its own pillar — here as tree furniture the wipe must clear)
    this.Swarm_seal(w, reba, { pub: mate.pub, prepub: mate.prepub, friendly: 'Mate' }, null, null)
    await this.Swarm_mint_idzeug(w, reba, { Music: 1 }, 'reboot_1')
    // a chain root (lineage): the shelf the third pillar carries
    let cr = reba.oai({ ChainRoot: 1, pub: String(mate.pub) })
    cr.c.up = reba
    cr.sc.prepub = String(mate.prepub)
    // the roster: my own body row, wearing my name
    let body = this.Swarm_body_take(reba, keys.pub, 'Captain', null)
    if (body) { body.sc.name = 'Reba'; body.bump() }
    // the crew ledger: my row + the mate's, the mate's row holding the cert I signed for it
    this.Swarm_crew_row(reba, reba.sc.prepub, 'Captain', keys.pub)
    let crow = this.Swarm_crew_row(reba, mate.prepub, 'Cave', mate.pub)
    let cert = await mint_grant(keys, String(mate.pub), 'Crew', {}, this.Swarm_now(w))
    if (crow && cert) { grant_to_C(crow, cert) }
    // two bookings: one standing (survives), one terminal (history — must NOT come back)
    this.Swarm_reach_book(w, reba, { to: 'Cave', of: 'tune-alpha', for: 'serve' })
    let done = this.Swarm_reach_book(w, reba, { to: 'Cave', of: 'tune-omega', for: 'serve' })
    if (done) { done.sc.state = 'arrived'; done.bump() }

// beat 3 — THE STASH, into a scratch of this Book's own (never the House's Dexie-backed one: a Book must
//  not write a runner's durable memory).  Swarm_stash_of takes it and the live-self guard stands down.
async SwarmReboot_stash(w):
    w i reached:step_3
    w.sc.now = 1751700010
    if (!w.c.reba) { return }
    w.c.st = {}
    let r = this.Swarm_restash_all(w.c.reba, null, w.c.st)
    let row = { stashed: 1 }
    if (r && +r.roster >= 1) { row.roster_stashed = 1 }
    if (r && +r.piers === 1) { row.pier_stashed = 1 }
    if (r && +r.izzes === 1) { row.izz_stashed = 1 }
    if (r && +r.roots === 1) { row.root_stashed = 1 }
    if (r && +r.crew === 2) { row.crew_stashed = 1 }
    if (r && +r.reaches === 1) { row.one_reach_stashed = 1 }
    let mates = w.c.st.Swarm_crews?.[w.c.reba.sc.prepub]?.mates || []
    if (mates.some((m) => m.grant && String(m.grant.to) === 'Crew')) { row.cert_stashed = 1 }
    this.SwarmReboot_note(w, row)

// beat 4 — THE RELOAD: everything the C tree held is gone.  A real boot keeps only what Dexie carried —
//  the keypair (thang_put) — and re-stands an EMPTY %Peering, which is exactly what a phone wakes to.
async SwarmReboot_wipe(w):
    w i reached:step_4
    w.sc.now = 1751700020
    let reba = w.c.reba
    if (!reba) { return }
    let peering = this.Swarm_peering(reba)
    for (const child of peering.o()) { peering.drop(child) }
    for (const crew of reba.o({ Crew: 1 })) { reba.drop(crew) }
    for (const cr2 of reba.o({ ChainRoot: 1 })) { reba.drop(cr2) }
    let row = { wiped: 1 }
    if (!reba.o({ ChainRoot: 1 }).length) { row.roots_gone = 1 }
    if (!peering.o().length) { row.peering_bare = 1 }
    if (!reba.o({ Crew: 1 }).length) { row.crew_gone = 1 }
    if (!this.Swarm_crew_grant(reba)) { row.cert_gone = 1 }
    this.SwarmReboot_note(w, row)

// beat 5 — THE REHYDRATE LADDER, the same three calls Swarm_station_up makes at boot, against the scratch
//  stash.  What must come back: the roster row, the crew ledger WITH my cert (so Swarm_crew_grant answers
//   again — the phone is still crew), and the STANDING booking only.
async SwarmReboot_back(w):
    w i reached:step_5
    w.sc.now = 1751700030
    let reba = w.c.reba
    if (!reba || !w.c.st) { return }
    // the SAME ladder Swarm_station_up runs, in its order, against the scratch stash
    this.Swarm_iz_rehydrate(w, reba, w.c.st)
    this.Swarm_piers_rehydrate(w, reba, w.c.st)
    this.Swarm_chainroots_rehydrate(w, reba, w.c.st)
    await this.Swarm_roster_rehydrate(w, reba, w.c.st)
    this.Swarm_crew_rehydrate(w, reba, w.c.st)
    this.Swarm_reaches_rehydrate(w, reba, w.c.st)
    let peering = this.Swarm_peering(reba)
    let row = { back: 1 }
    let pier = peering.o({ Pier: 1, pub: String(w.c.matekeys.prepub) })[0]
    if (pier && String(pier.sc.friendly) === 'Mate' && String(pier.o({ Peering: 1 })[0]?.sc?.pub || '') === String(w.c.matekeys.pub)) { row.pier_back = 1 }
    let izz = peering.o({ Idzeug: 'reboot_1' })[0]
    if (izz && String(izz.sc.to) === 'Music') { row.izz_back = 1 }
    if (reba.o({ ChainRoot: 1, pub: String(w.c.matekeys.pub) })[0]) { row.root_back = 1 }
    let crew = reba.o({ Crew: 1 })[0]
    if (crew && crew.o({ mate: 1 }).length === 2) { row.crew_back = 1 }
    let mine = crew ? crew.o({ mate: String(reba.sc.prepub) })[0] : null
    if (mine && String(mine.sc.role) === 'Captain') { row.my_role_back = 1 }
    let mrow = crew ? crew.o({ mate: String(w.c.matekeys.prepub) })[0] : null
    if (mrow && mrow.o({ Grant: 'Crew' })[0]) { row.cert_back = 1 }
    if (mrow && String(mrow.sc.pub || '') === String(w.c.matekeys.pub)) { row.body_back = 1 }
    let bodies = peering.o({ Body: 1 })
    if (bodies.length === 1 && String(bodies[0].sc.name || '') === 'Reba') { row.roster_back = 1 }
    let reaches = peering.o({ Reach: 1 })
    if (reaches.length === 1 && String(reaches[0].sc.of) === 'tune-alpha') { row.standing_reach_back = 1 }
    if (!reaches.some((r) => String(r.sc.of) === 'tune-omega')) { row.terminal_reach_stayed_dead = 1 }
    if (reaches.length === 1 && String(reaches[0].sc.state) === 'booked') { row.reach_state_back = 1 }
    // the round trip is idempotent: a second ladder pass must not double a single row.
    this.Swarm_iz_rehydrate(w, reba, w.c.st)
    this.Swarm_piers_rehydrate(w, reba, w.c.st)
    this.Swarm_chainroots_rehydrate(w, reba, w.c.st)
    this.Swarm_crew_rehydrate(w, reba, w.c.st)
    this.Swarm_reaches_rehydrate(w, reba, w.c.st)
    if (crew && crew.o({ mate: 1 }).length === 2 && peering.o({ Reach: 1 }).length === 1
        && peering.o({ Pier: 1 }).length === 1 && peering.o({ Idzeug: 1 }).length === 1 && reba.o({ ChainRoot: 1 }).length === 1) { row.idempotent = 1 }
    this.SwarmReboot_note(w, row)

// ── the witness ───────────────────────────────────────────────────────────────────────────────────
SwarmReboot_witness(w):
    let n = (this.c.run)?.c.step_n
    if (!(n >= 5)) { return }
    let T = this.SwarmReboot_T(w)
    let s = T.o({ stashed: 1 })[0]
    let d = T.o({ wiped: 1 })[0]
    let b = T.o({ back: 1 })[0]
    if (!s || !d || !b) { return }
    // #1 THE PHONE'S ONE DURABLE HOME CARRIES THE CREW: cert and all, with no folder anywhere.
    if (+s.sc.crew_stashed === 1 && +s.sc.cert_stashed === 1 && +b.sc.crew_back === 1 && +b.sc.cert_back === 1) this.story_swear(w, 'the crew ledger and its cert survive a reload through the stash alone — the home a device with no folder actually has')
    // #2 A WIPE IS A REAL WIPE: the fixture proves the tree was empty before anything came back.
    if (+d.sc.peering_bare === 1 && +d.sc.crew_gone === 1 && +d.sc.cert_gone === 1) this.story_swear(w, 'the reload is real — the peering stands bare and the crew grant answers nothing until the rehydrate runs')
    // #3 A BOOKING IS DURABLE INTENT: it outlives the boot that was standing when it was made.
    if (+s.sc.one_reach_stashed === 1 && +b.sc.standing_reach_back === 1 && +b.sc.reach_state_back === 1) this.story_swear(w, 'a standing booking outlives the boot that made it — reach comes back booked so book-it-and-walk-away is true on a phone')
    // #4 HISTORY STAYS BURIED: a settled reach is not resurrected by its own stash.
    if (+b.sc.terminal_reach_stayed_dead === 1) this.story_swear(w, 'a settled reach stays settled — only live intent is carried so a reload never resurrects work already finished')
    // #5 THE ROSTER + MY OWN ROLE RETURN: the family album and which face is mine.
    if (+b.sc.roster_back === 1 && +b.sc.my_role_back === 1 && +b.sc.body_back === 1) this.story_swear(w, 'the roster and my own post return with the crew — a rebooted body knows what it is and which key each mate answers at')
    // #7 THE OLDER THREE PILLARS, FINALLY UNDER A FIXTURE: a friend pier with its page, a named invite
    //  serial, a chain root — stashed, wiped, and back.
    if (+s.sc.pier_stashed === 1 && +s.sc.izz_stashed === 1 && +s.sc.root_stashed === 1 && +d.sc.roots_gone === 1 && +b.sc.pier_back === 1 && +b.sc.izz_back === 1 && +b.sc.root_back === 1) this.story_swear(w, 'a friend pier with its page an issued invite serial and a chain root all come back from the stash — the three oldest pillars finally stand under a fixture')
    // #6 THE LADDER IS IDEMPOTENT: boot runs it once but a re-entry must not double a row.
    if (+b.sc.idempotent === 1) this.story_swear(w, 'running the rehydrate ladder twice changes nothing — every pillar finds-or-creates so a re-entered boot cannot double a mate or a booking')

// SwarmReboot_order — float A:SwarmReboot to the front of H/* so the Run snap stays readable.
async SwarmReboot_order(w):
    let As = H.o({A: 1})
    if (!As.length) { return }
    let first = (a) => (a.sc.A === 'SwarmReboot') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)
