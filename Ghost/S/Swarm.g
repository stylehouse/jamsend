// Swarm.g — the swarm spine: identity, contacts, and the Idzeug invite (spec: Swarm_spec.md).
//  First of the S family (Ghost/S/, Waft:Ghost/Swarm/*) — the SOCIETY beside networking (N) and
//   music (M): a person is a portable identity-particle, a friendship is a pair of signed grants.
//  The particle model (§2): %Identity,<prepub> owns .c.keys (a secret — never sc, never encoded)
//   and its %Peering,name:<prepub> page; a %Pier under the page is one friend's DURABLE MEMORY —
//    their imported page + the Music grants both ways + any %NotGrant. The contact is the memory;
//     the living connection is the instance — a friend you can't reach is still a friend.
//  No Tyrant (§6): each peer is the authority for its own friendships — the old Idzeugnosis seat,
//   now held by the inviter itself.

// Crypto rides in by IMPORT (a capability for real external deps — the invite/grant logic itself
//  stays here in .g): Idento is the ed25519 pair, Grant.ts the signed-capability atom the Idzeug
//   is COMPOSED from (an Idzeug is an UNBOUND grant — for:'*' — plus a nonce and the inviter's page).
IMPORT()
    import { Idento } from "$lib/Y.svelte.ts"
    import { mint_grant, verify_grant, grant_to_C, mint_revoke } from "$lib/O/Funk/Grant.ts"

//#region self — keys, the account tree, the page

// Swarm_now — the swarm clock in seconds. A Book pins w.sc.now so every signed `time` (and so every
//  signature and snap byte) repeats run to run; unpinned = wall clock.
Swarm_now(w):
    return +(w?.sc?.now ?? Math.floor(Date.now() / 1000))

// Swarm_mint_keys — a fresh ed25519 keypair as a storable {pub, key, prepub} (Clustation_mint's
//  twin, here so the swarm mints without the Auto layer). A seed string makes it DETERMINISTIC —
//   the Book's fixed selves; no seed is the production path.
async Swarm_mint_keys(seed):
    let ido = new Idento()
    await ido.generateKeys(seed)
    let f = ido.freeze()
    return { pub: f.pub, key: f.key, prepub: ido.pretty_pubkey() }

// Swarm_identity — stand up %Identity,<prepub> owning its %Peering page under `container` — the
//  same shape Clustation_concrete makes, so an account tree reads the same everywhere. The keypair
//   rides .c.keys only (an object in .sc is a fatal encode).
Swarm_identity(container, keys, friendly):
    let ident = container.oai({ Identity: keys.prepub })
    ident.c.up = container
    ident.c.keys = { pub: keys.pub, key: keys.key }
    ident.sc.prepub = keys.prepub
    if (friendly) ident.sc.friendly = friendly
    let peering = ident.oai({ Peering: 1, name: keys.prepub })
    peering.c.up = ident
    if (friendly) peering.sc.friendly = friendly
    return ident

// Swarm_peering — the identity's own page (1:1 for now — the 1:N door is §2's deferred hold).
Swarm_peering(ident):
    return ident.o({ Peering: 1 })[0]

// Swarm_page — the PRUNED public face that crosses the wire: pub + prepub + friendly and nothing
//  else. The %Pier children (your contact list) stay private by CONSTRUCTION — the page is built,
//   not filtered (§6.5).
Swarm_page(ident):
    let peering = this.Swarm_peering(ident)
    return { pub: ident.c.keys.pub, prepub: ident.sc.prepub, friendly: peering?.sc?.friendly ?? '' }

// Swarm_online — the page's reachability flag. In production this is the relay bind (§3 — the
//  leased hold on the Peering address); in-process it is the flag the wire seam consults.
Swarm_online(ident, yes):
    let peering = this.Swarm_peering(ident)
    if (yes) {
        peering.sc.online = 1
    } else {
        delete peering.sc.online
    }
    peering.bump()
//#endregion

//#region Idzeug — the single-use signed invite (§6.2)
//  An Idzeug is an UNBOUND %Grant (for:'*') carrying the Feature it offers (Music + params), a
//   nonce, and the inviter's page — proof your link reached the other Pier, NOT an offline
//    capability token: both Piers must be online, the live handshake (below) mints the BOUND grants.

// Swarm_b64|Swarm_unb64 — the ?Iz= blob codec (UTF-8-safe base64; a friendly name may be non-ASCII).
Swarm_b64(js):
    return btoa(unescape(encodeURIComponent(js)))
Swarm_unb64(b):
    return decodeURIComponent(escape(atob(b)))

// Swarm_iz_params — the Feature params riding a claim: every key that isn't the claim's envelope.
//  (Grant's `to` names the Feature mainkey; its params ride alongside as plain string keys — §6.1.)
Swarm_iz_params(claim):
    let params = {}
    for (const k of Object.keys(claim)) {
        if (!['to', 'by', 'for', 'time', 'sign', 'nonce', 'prepub', 'friendly'].includes(k)) params[k] = claim[k]
    }
    return params

// Swarm_mint_idzeug — the inviter signs the offer and remembers its nonce (single-use) as an
//  %Idzeug under their %Peering; returns the ?Iz= blob. feature = { Music: 1, genre: 'Classical' } —
//   a mainkey with params, never a bare flag. The blob rides .c (re-derivable — ed25519 is
//    deterministic); the nonce record is what must survive: it is the spend ledger.
async Swarm_mint_idzeug(w, ident, feature, nonce):
    let mainkey = Object.keys(feature)[0]
    let params = { ...feature }
    delete params[mainkey]
    let page = this.Swarm_page(ident)
    let opt = { ...params, nonce: nonce, prepub: page.prepub, friendly: page.friendly }
    let atom = await mint_grant(ident.c.keys, '*', mainkey, opt, this.Swarm_now(w))
    let peering = this.Swarm_peering(ident)
    let record = peering.oai({ Idzeug: nonce, to: mainkey, ...params })
    record.c.up = peering
    record.c.iz = this.Swarm_b64(JSON.stringify(atom))
    return record.c.iz

// Swarm_verify_idzeug — decode + verify the inviter's signature. THROWS on forgery|garbage; returns
//  the claim (by = the inviter's full pub, to = the Feature mainkey, + params/nonce/prepub/friendly).
async Swarm_verify_idzeug(iz):
    let atom = JSON.parse(this.Swarm_unb64(iz))
    return await verify_grant(atom)
//#endregion

//#region wire — the deliverance seam
//  Deliverance is a SEAM, not a commitment: today a frame drops into the target account's %mail
//   in-process (deterministic — Swarm_spec §9); the Peeroleum to:<pub> frame is the drop-in
//    replacement (Cluster_spec §3) and nothing above this seam changes. Delivered frames stay as
//     husks (%frame,did) — the handshake leaves a legible trace in the snap.

// Swarm_account_of — the in-process routing table: the identity in w whose prepub this is.
Swarm_account_of(w, prepub):
    for (const acct of w.o({ Account: 1 })) {
        let ident = acct.o({ Identity: 1 }).find(i => i.sc.prepub === prepub)
        if (ident) return ident
    }
    return null

// Swarm_deliver — drop a frame at a page, false if the holder is unreachable (offline|unknown).
//  The frame object rides .c.frame (never encoded); the kind alone is the snapped face.
Swarm_deliver(w, prepub, frame):
    if (!prepub) return false
    let ident = this.Swarm_account_of(w, prepub)
    if (!ident) return false
    if (!this.Swarm_peering(ident)?.sc?.online) return false
    let inbox = ident.oai({ mail: 1 })
    inbox.c.up = ident
    let m = inbox.i({ frame: frame.kind })
    m.c.frame = frame
    return true

// Swarm_pump — handle an identity's undone mail (a Book's drive calls this each pass; production
//  hangs it off the transport's inbound). Async — every handler crosses the crypto.
async Swarm_pump(w, ident):
    let inbox = ident.o({ mail: 1 })[0]
    if (!inbox) return
    for (const m of [...inbox.o({ frame: 1 })]) {
        if (m.sc.did) continue
        m.sc.did = 1
        let frame = m.c.frame
        if (frame.kind === 'pier_hello') await this.Swarm_hello(w, ident, frame)
        if (frame.kind === 'pier_accept') await this.Swarm_accept(w, ident, frame)
        if (frame.kind === 'pier_reject') this.Swarm_rejected(w, ident, frame)
    }

// Swarm_rebuff — a failed redeem|hello surfaces as %rebuff under the identity: legible in the
//  snap, and the seed of §3's error-surfacing TODO (the owner should SEE a rebuff).
Swarm_rebuff(ident, why, say):
    ident.i({ rebuff: why, say: String(say ?? '').slice(0, 60) })
//#endregion

//#region handshake — live, both online (§6.3)

// Swarm_redeem — the invitee opens the ?Iz= link WHILE ONLINE: verify the signature, then prove
//  receipt by dialing the inviter with a pier_hello that ECHOES the Idzeug — carrying our page and
//   our reciprocal Feature grant (the claim names the inviter's pub, so the reciprocal mints NOW
//    and rides the hello; two frames seal the friendship). The inviter offline → the redeem simply
//     FAILS (%rebuff,offline): the Idzeug proves receipt, it does not stand in for an absent party.
async Swarm_redeem(w, ident, iz):
    let claim
    try { claim = await this.Swarm_verify_idzeug(iz) }
    catch (er) {
        this.Swarm_rebuff(ident, 'forged', er)
        return null
    }
    let grant = await mint_grant(ident.c.keys, claim.by, claim.to, this.Swarm_iz_params(claim), this.Swarm_now(w))
    let hello = { kind: 'pier_hello', iz: iz, page: this.Swarm_page(ident), grant: grant }
    if (!this.Swarm_deliver(w, claim.prepub, hello)) {
        this.Swarm_rebuff(ident, 'offline', claim.prepub)
        return null
    }
    // remember what we offered so the accept can seal our copy beside theirs (runtime memory —
    //  losing it costs only the my-copy convenience, never the friendship)
    if (!ident.c.offered) ident.c.offered = {}
    ident.c.offered[claim.by] = grant
    return claim

// Swarm_hello — the inviter hears a pier_hello: the old Idzeugnosis seat with the peer its OWN
//  authority. Valid = the echoed Idzeug is OURS (by === our pub — signature freshly re-verified)
//   and its nonce is on our %Peering UNSPENT. Then the seal: spend the nonce, keep their verified
//    reciprocal grant, mint our BOUND grant, import their page as a %Pier, log the graph edge, and
//     answer pier_accept. Every deny answers pier_reject so the redeemer sees why.
async Swarm_hello(w, ident, frame):
    let deny = (why) => {
        this.Swarm_rebuff(ident, 'hello_' + why, frame.page?.prepub)
        this.Swarm_deliver(w, frame.page?.prepub, { kind: 'pier_reject', why: why, prepub: ident.sc.prepub })
        return null
    }
    let claim
    try { claim = await this.Swarm_verify_idzeug(frame.iz) }
    catch (er) { return deny('forged') }
    if (claim.by !== ident.c.keys.pub) return deny('not_ours')
    let record = this.Swarm_peering(ident).o({ Idzeug: claim.nonce })[0]
    if (!record) return deny('unknown')
    if (record.sc.spent) return deny('spent')
    let theirs
    try { theirs = await verify_grant(frame.grant) }
    catch (er) { return deny('bad_grant') }
    if (theirs.for !== ident.c.keys.pub || theirs.by !== frame.page.pub) return deny('grant_mismatch')
    record.sc.spent = 1
    let mine = await mint_grant(ident.c.keys, frame.page.pub, claim.to, this.Swarm_iz_params(claim), this.Swarm_now(w))
    let pier = this.Swarm_seal(w, ident, frame.page, frame.grant, mine)
    this.Swarm_deliver(w, frame.page.prepub, { kind: 'pier_accept', grant: mine, page: this.Swarm_page(ident) })
    return pier

// Swarm_accept — the redeemer hears pier_accept: verify the inviter's bound grant is really theirs
//  and really FOR US, then seal our own %Pier. The friendship is now MUTUAL — and both being
//   online, the living connection can stand up at once (.c.live — the transport layer links it
//    when this seam rides Peeroleum).
async Swarm_accept(w, ident, frame):
    let claim
    try { claim = await verify_grant(frame.grant) }
    catch (er) {
        this.Swarm_rebuff(ident, 'accept_forged', frame.page?.prepub)
        return null
    }
    if (claim.for !== ident.c.keys.pub || claim.by !== frame.page.pub) {
        this.Swarm_rebuff(ident, 'accept_mismatch', frame.page?.prepub)
        return null
    }
    let mine = ident.c.offered ? ident.c.offered[claim.by] : null
    return this.Swarm_seal(w, ident, frame.page, frame.grant, mine)

// Swarm_rejected — the inviter said no (spent|unknown|forged…): surface it, nothing sealed.
Swarm_rejected(w, ident, frame):
    this.Swarm_rebuff(ident, 'rejected_' + frame.why, frame.prepub)

// Swarm_seal — both ends land here: the %Pier durable memory under MY %Peering — their imported
//  page (the "stashed Peering" reborn), the grant THEY signed for me, my copy of the one I signed
//   for them — plus the social-graph edge (§6.6, owner-side: each end's %SocialGraph is the local
//    view of who-befriended-whom). Idempotent: grants and edges are guarded, a re-seal no-ops.
Swarm_seal(w, ident, page, theirGrant, myGrant):
    let peering = this.Swarm_peering(ident)
    let pier = peering.oai({ Pier: 1, pub: page.prepub })
    pier.c.up = peering
    pier.sc.friendly = page.friendly
    pier.sc.since = String(this.Swarm_now(w))
    let theirPage = pier.oai({ Peering: 1, name: page.prepub })
    theirPage.c.up = pier
    theirPage.sc.friendly = page.friendly
    theirPage.sc.pub = page.pub
    for (const g of [theirGrant, myGrant]) {
        if (g && !pier.o({ Grant: g.to, by: g.by })[0]) grant_to_C(pier, g)
    }
    let graph = ident.oai({ SocialGraph: 1 })
    graph.c.up = ident
    if (!graph.o({ Edge: 1, b: page.prepub })[0]) {
        graph.i({ Edge: 1, a: ident.sc.prepub, b: page.prepub, at: String(this.Swarm_now(w)) })
    }
    return pier
//#endregion

//#region revocation — the only way a grant ends (§6.4)

// Swarm_revoke — unfriending: a signed %NotGrant kept under the Pier it revokes (grants are
//  infinite — never an expiry). The Pier RETIRES at use (Swarm_pier_live), it is not deleted:
//   the durable memory keeps its history.
async Swarm_revoke(w, ident, pier, feature):
    let theirPub = pier.o({ Peering: 1 })[0]?.sc?.pub
    let atom = await mint_revoke(ident.c.keys, theirPub, feature, {}, this.Swarm_now(w))
    return pier.i({ NotGrant: atom.not, by: atom.by, for: atom.for, time: atom.time, sign: atom.sign })

// Swarm_pier_live — a Pier stands iff its Feature grants are present and NO matching %NotGrant
//  (same ability + by + for) overrides any of them — checked at use, never cached.
Swarm_pier_live(pier, feature):
    let grants = pier.o({ Grant: feature })
    if (!grants.length) return false
    let nots = pier.o({ NotGrant: feature })
    return !nots.some(n => grants.some(g => n.sc.by === g.sc.by && n.sc.for === g.sc.for))
//#endregion
