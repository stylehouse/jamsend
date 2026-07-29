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
    import { Idento, peel } from "$lib/Y.svelte.ts"
    import { mint_grant, verify_grant, grant_to_C, grant_of_C, mint_revoke } from "$lib/O/Funk/Grant.ts"
    import { signHeader, verifyHeader, prepubOf } from "$lib/p2p/cluster_trust"

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

// Swarm_page_bound — a wire page's prepub MUST be the address its OWN pub derives. page.pub is proven
//  by the accompanying grant's signature; prepubOf(pub) is deterministic (the prepub is the pub's
//   pretty prefix) — so a mismatch is a FORGED prepub: a caller wearing its own key while CLAIMING
//    another's address. Swarm_seal keys the durable %Pier by prepub, so an unbound page lets a
//     redeemer plant a contact under — or overwrite — a victim's address (the SwarmSpoof tooth,
//      crypto audit 2026-07-22). Every seal-minting wire entry checks this BEFORE it spends a nonce,
//       advances a chain holder, or mints a grant. prepubOf(pub)==the honest page.prepub is ALREADY a
//        load-bearing equivalence here (Swarm_reinvite_ok gates on it), so this breaks no legit flow.
Swarm_page_bound(page):
    return !!(page && page.pub && page.prepub && prepubOf(page.pub) === page.prepub)

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

//#region Idzeug — the single-use invite (§6.2), worn as the COMPACT token
//  An Idzeug is an offer of a Feature (Music + params) under a single-use serial — proof your link
//   reached the other Pier, NOT an offline capability token: both Piers must be online, the live
//    handshake (below) mints the BOUND grants.
//  The QR face is the compact token <prepub>*<serial>*<n>*<presig16> (~45 chars against the old
//   428-char signed atom): no issuer pub (pier_accept reveals it), no expiry (single-use by serial
//    is the whole law), no third-party-checkable signature — the presig is an ISSUER-side MAC
//     (ed25519 is deterministic: the door re-signs its OWN ledger record and prefix-matches; 64
//      bits is ample for an online, single-use check). The full signed atom still rides the
//       maker's record (.c.iz) — the chain's lineage (§6.3a) keeps third-party verify; the QR
//        does not need it.

// Swarm_b64|Swarm_unb64 — the full-atom blob codec (UTF-8-safe base64; a friendly name may be
//  non-ASCII). The QR stopped wearing this — it rides the chain's embedded atoms + ReInvite ribs.
Swarm_b64(js):
    return btoa(unescape(encodeURIComponent(js)))
Swarm_unb64(b):
    return decodeURIComponent(escape(atob(b)))

// Swarm_token_n — the token's $n leg: the Feature mainkey + its params, tilde-joined (Music, or
//  Music~genre~Classical). '~' survives encodeURIComponent and never appears in a mainkey.
Swarm_token_n(to, params):
    let bits = [String(to)]
    for (const k of Object.keys(params || {})) {
        bits.push(k)
        bits.push(String(params[k]))
    }
    return bits.join('~')

Swarm_token_n_parse(n):
    let bits = String(n).split('~')
    let params = {}
    let i = 1
    while (i < bits.length - 1) {
        params[bits[i]] = bits[i + 1]
        i = i + 2
    }
    return { to: bits[0], params: params }

// Swarm_presig — the issuer-side MAC over the token's domain: a deterministic ed25519 signature
//  (signHeader — sorted-key JSON) truncated to 16 hex. Not third-party-verifiable BY DESIGN:
//   only the issuer's key can regenerate it, and regeneration IS the door's check (§6.2).
async Swarm_presig(keys, prepub, serial, n):
    let sig = await signHeader({ prepub: String(prepub), serial: String(serial), n: String(n) }, keys.key)
    return String(sig).slice(0, 16)

// Swarm_token|Swarm_token_parse — the compact QR codec: <prepub16>*<serial>*<n>*<presig16>.
//  '*' survives encodeURIComponent AND QR encoding; a serial may carry any user text (a blotter
//   tag), so the parse re-joins inner '*'s back into the serial instead of faulting. Null on
//    anything that isn't a token (an old base64 blob, a mangled scan) — never a throw.
Swarm_token(prepub, serial, n, presig):
    return [prepub, serial, n, presig].join('*')

Swarm_token_parse(token):
    let parts = String(token || '').split('*')
    if (parts.length < 4) return null
    let prepub = parts[0]
    let presig = parts[parts.length - 1]
    let n = parts[parts.length - 2]
    let serial = parts.slice(1, parts.length - 2).join('*')
    if (!/^[0-9a-f]{16}$/.test(prepub)) return null
    if (!/^[0-9a-f]{16}$/.test(presig)) return null
    if (!serial || !n) return null
    let picked = this.Swarm_token_n_parse(n)
    return { prepub: prepub, serial: serial, n: n, presig: presig, to: picked.to, params: picked.params }

// Swarm_iz_params — the Feature params riding a claim: every key that isn't the claim's envelope.
//  (Grant's `to` names the Feature mainkey; its params ride alongside as plain string keys — §6.1.)
//   ttl is INVITE policy, never grant policy (grants are infinite — §6.1): it stays on the maker's
//    %Idzeug record and the blob, and is stripped here so no sealed grant ever carries an expiry.
Swarm_iz_params(claim):
    let params = {}
    for (const k of Object.keys(claim)) {
        if (!['to', 'by', 'for', 'time', 'sign', 'nonce', 'prepub', 'friendly', 'ttl'].includes(k)) params[k] = claim[k]
    }
    return params

// Swarm_record_params — the Feature params riding a LEDGER record: every sc key that isn't the
//  record's envelope (the mint wrote {Idzeug, to, ...params}; the spend|chain|blotter flags land
//   later). The door's presig regeneration and its grant mint both read THIS — the maker's own
//    record is the law (§10.1), never the carried $n.
Swarm_record_params(record):
    let params = {}
    for (const k of Object.keys(record.sc)) {
        if (!['Idzeug', 'to', 'ttl', 'chain', 'holder', 'spent', 'blotter'].includes(k)) params[k] = String(record.sc[k])
    }
    return params

// Swarm_mint_idzeug — the inviter remembers the offer's serial (single-use) as an %Idzeug under
//  their %Peering; returns the COMPACT token (§6.2). feature = { Music: 1, genre: 'Classical' } —
//   a mainkey with params, never a bare flag. The record keeps the FULL signed atom on .c.iz —
//    the chain's lineage (§6.3a third-party verify) — while the QR wears only the token; both
//     ride .c (re-derivable — ed25519 is deterministic). The serial record is what must survive:
//      it is the spend ledger.
async Swarm_mint_idzeug(w, ident, feature, nonce, chain):
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
    let n = this.Swarm_token_n(mainkey, params)
    record.c.token = this.Swarm_token(page.prepub, nonce, n, await this.Swarm_presig(ident.c.keys, page.prepub, nonce, n))
    // chain policy (§6.3a): a re-assignable invite TRACKS its current holder (the tip) instead of
    //  spending on the first claim — the SHARE popup's kind. A plain invite (a blotter serial, the
    //   legacy link) stays single-use (`spent`). The maker's own record is the law (§10.1), so the
    //    flag lives here and survives reload through the iz-stash.
    if (chain) record.sc.chain = 1
    this.Swarm_iz_stash(ident, nonce, chain ? { to: mainkey, chain: 1, ...params } : { to: mainkey, ...params })
    return record.c.token

// Swarm_verify_idzeug — decode + verify a FULL signed atom. THROWS on forgery|garbage; returns
//  the claim (by = the inviter's full pub, to = the Feature mainkey, + params/nonce/prepub/friendly).
//   The QR token no longer carries one — this is the CHAIN's lineage verify (Swarm_verify_reinvite's
//    inner atom); the door proves a token by presig regeneration instead (Swarm_hello).
async Swarm_verify_idzeug(iz):
    let atom = JSON.parse(this.Swarm_unb64(iz))
    return await verify_grant(atom)
//#endregion

//#region blotter — a printed SHEET of one-time serials (§6.2)
//  A blotter is a BATCH of plain single-use Idzeugs minted in one act and grouped under a %Blotter
//   sheet — the "tear-off numbered tickets" face (the A4 page of QR cells, Vyto's display). Each
//    serial spends INDEPENDENTLY through the exact same single-use door (Swarm_hello spends its
//     nonce, refuses a replay), so a torn ticket is a one-timer remembered spent by its OWN nonce;
//      the sheet only GROUPS them so the maker sees the claimed count. NOTHING here is a chain
//       (§6.3a): the SHARE QR mints chain:1, a blotter never does — the two invite kinds part HERE.

// Swarm_mint_blotter — mint `count` serials <tag>-1..<tag>-count off the SAME Feature, each a plain
//  (never chain) Idzeug through the proven single-use mint, tagged with the sheet so the maker can
//   group + count them. Returns the SHEET: the ordered ?Iz= blobs the printed page's QR cells carry.
//    The %Blotter record holds the sheet SIZE (durable mint data); the CLAIMED count is DERIVED from
//     the members' spend flags (never a snapped counter — the ledger is each serial's own spend).
async Swarm_mint_blotter(w, ident, feature, count, tag):
    let peering = this.Swarm_peering(ident)
    let sheet = peering.oai({ Blotter: tag })
    sheet.c.up = peering
    sheet.sc.count = String(count)
    let izzes = []
    let i = 0
    while (i < count) {
        i = i + 1
        let nonce = String(tag) + '-' + i
        let iz = await this.Swarm_mint_idzeug(w, ident, feature, nonce)
        let record = peering.o({ Idzeug: nonce })[0]
        if (record) record.sc.blotter = tag
        this.Swarm_iz_stash(ident, nonce, { blotter: tag })
        izzes.push(iz)
    }
    return izzes

// Swarm_blotter_claimed — read a sheet's state: how many serials it holds, how many are spent
//  (claimed). Members are the %Idzeug records tagged with this sheet; a serial counts claimed once
//   its own single-use door spent it. Pure read — the maker's panel and the witness both call it,
//    and it survives reload without a snapped counter (the members + their spend flags rehydrate).
Swarm_blotter_claimed(ident, tag):
    let peering = this.Swarm_peering(ident)
    let members = peering.o({ Idzeug: 1, blotter: tag })
    let claimed = members.filter(m => m.sc.spent).length
    return { count: members.length, claimed: claimed }
//#endregion

//#region ReInvite — the re-assignable chain (§6.3a)
//  A chain invite (Swarm_mint_idzeug with chain:1) never spends; its first claimant is the tracked
//   HOLDER (the tip). The tip grows the chain via a ReInvite: an Alice-SIGNED capability that EMBEDS
//    the original invite and names the tip it authorises + the newcomer + the moment. The newcomer
//     carries it to the tip, who verifies Alice's signature and honours it PEER-TO-PEER — the TIP,
//      never Alice, grants the newcomer the embedded Feature. Both verify the SAME Alice signature
//       (her pub rides inside the embedded invite), so neither need have met before. The wire verbs
//        (honour, tip-advance-on-confirm) ride the handshake region below; THESE two are the pure
//         sign|verify, reusing the voucher's ed25519 (signHeader|verifyHeader) over an arbitrary key.

// Swarm_mint_reinvite — Alice signs a ReInvite off a HELD chain %Idzeug: it embeds the original invite
//  blob (so the newcomer learns the Feature AND Alice's pub to check this very signature), names the
//   current tip it lets grant, the newcomer, a fresh single-use rnonce (seam 2), and the moment. The
//    signature is by Alice's key — the lineage root both ends verify against.
async Swarm_mint_reinvite(w, ident, record, newcomer, rnonce):
    if (!record.sc.chain) throw 'reinvite: not a chain invite'
    if (!record.sc.holder) throw 'reinvite: unclaimed — no tip to extend from'
    let c = { tip: record.sc.holder, newcomer: newcomer, iz: record.c.iz, nonce: record.sc.Idzeug, rnonce: rnonce, at: this.Swarm_now(w) }
    c.sign = await signHeader(c, ident.c.keys.key)
    return this.Swarm_b64(JSON.stringify(c))

// Swarm_verify_reinvite — decode + verify BOTH signatures and their binding: the embedded invite is a
//  real Alice grant (verify_grant → her pub), and the ReInvite itself is signed by that SAME Alice pub.
//   THROWS on forgery|garbage; returns { tip, newcomer, nonce, rnonce, at, by, feature, params } — `by`
//    is Alice's pub, the lineage root the two ends verify each other against.
async Swarm_verify_reinvite(rib):
    let c = JSON.parse(this.Swarm_unb64(rib))
    let inner = await this.Swarm_verify_idzeug(c.iz)
    let who = await verifyHeader(c, [inner.by])
    if (who !== inner.by) throw 'reinvite: bad signature'
    return { tip: c.tip, newcomer: c.newcomer, nonce: c.nonce, rnonce: c.rnonce, at: c.at, by: inner.by, feature: inner.to, params: this.Swarm_iz_params(inner) }
//#endregion

//#region front door — the live self, the invite URL (Swarm_spec §10.1: the QR face of the Idzeug)
//  USER-FACING this is an Invite; the signed mechanics stay the Idzeug verbs above (renaming a green
//   handshake is a deliberate later pass, not a drive-by). The front door adds NO crypto: it resolves
//    the machine's ACTIVE identity — the one signing key, the shape Auto's Clustation_concrete makes,
//     never a parallel self — mints through Swarm_mint_idzeug, and dresses the blob as a scannable URL.

// Swarm_active_ident — the active %Identity in a Clustation-shaped container (active rides 1/absent,
//  keys on .c). SwarmInvite proves this against the REAL shape — Clustation_concrete's own output —
//   so shape drift turns the Book red instead of silently returning null in the panel.
Swarm_active_ident(container):
    if (!container) return null
    return container.o({ Identity: 1 }).find(i => i.sc.active) ?? null

// Swarm_live_self — the machine's active identity: A:Clustation under the top House (stood by Auto's
//  ensure_identity | ensure_default | adopt — every mint funnels through Clustation_concrete). Null
//   pre-boot: the panel shows its "no identity" face rather than minting a parallel self.
Swarm_live_self():
    let A = this.top_House().o({ A: 'Clustation' })[0]
    return this.Swarm_active_ident(A)

// Swarm_invite_url — the front door itself: mint the single-use Idzeug from `ident` and dress it as
//  the URL the QR carries — <base>?Iz=<token>. Live, base = location.origin + the toplevel path (the
//   scanning phone lands on the SAME app); a Book pins it. The URL is the whole invite.
async Swarm_invite_url(w, ident, feature, nonce, base):
    let iz = await this.Swarm_mint_idzeug(w, ident, feature, nonce)
    return base + '?Iz=' + encodeURIComponent(iz)

// Swarm_iz_of_url — the boot handler's core, isolated pure: pull the ?Iz= token back out of a
//  scanned URL. encodeURIComponent above ↔ URLSearchParams here — the token's *|~|- survive the
//   round trip untouched (none decodes as a space).
Swarm_iz_of_url(href):
    if (!href) return null
    let at = href.indexOf('?')
    if (at < 0) return null
    return new URLSearchParams(href.slice(at + 1)).get('Iz')
//#endregion

//#region legacy — the old garden's Idzeug (§6.2 rung 1: dual-parse at the door)
//  An OLD link is a URL hash-fragment `#<13-#-pad><prepub>-<advice>-<sign>` (Tyranny.svelte's
//   Idzeug_i_Idzeugi): prepub the 16-hex address, advice a peel-encoded {name, n} ('.'-sep,
//    '~'-hier, spaces as '+'), sign an ed25519 over `<prepub>-<advice>` TRUNCATED to 16 (the
//     presig regime). The parse is CHEAP AND PURE — rung 1. It does NOT verify: the spend ledger
//      and the signing key live in the old garden's Dexie (Trusting.OurIdzeugs, OurPier.stashed),
//       so until the rung-2 migrator lifts them into %Idzeug records the door can only say
//        deny('unknown') — honestly. And an old claim granted the hardcoded 'ftp' trust atom,
//         NEVER a Feature grant: `granted` surfaces that so nobody transcodes it as Music.

// Swarm_legacy_of_url — detect + parse the old shape; null on anything else (a modern ?Iz= link,
//  a plain #anchor, a mangled relic — never a throw). Mirrors Tyranny's Idzeugmance entry regex
//   PLUS '+': the old ENCODER wrote spaces as '+' but its matcher never admitted them — a spaced
//    name broke old links at their own door; we read what the encoder wrote. Only the '.'|'~'
//     advice ever rode a URL (the ','|':' peel variant predates the hash entry and reaches us
//      via Swarm_legacy_advice's other branch).
Swarm_legacy_of_url(href):
    if (!href) return null
    let at = href.indexOf('#')
    if (at < 0) return null
    let m = href.slice(at).match(/^#+([\w\.~+\-]{16,})$/)
    if (!m) return null
    let parts = m[1].split('-')
    if (parts.length !== 3) return null
    if (!/^[0-9a-f]{16}$/.test(parts[0])) return null
    let c
    try { c = this.Swarm_legacy_advice(parts[1]) }
    catch (er) { return null }
    if (!c || !c.name) return null
    let out = { legacy: 1, prepub: parts[0], friendly: c.name, sign: parts[2], granted: 'ftp' }
    if (c.n != null) out.n = Number(c.n)
    return out

// Swarm_legacy_advice — the old decode_Idzeugi_advice verbatim in spirit: '+' back to spaces,
//  peel by '.'|'~' (or the older ','|':' when both appear), first key is the name, the rest ride.
Swarm_legacy_advice(advice):
    let s = advice.replace(/\+/g, ' ')
    let c
    if (s.includes(',') && s.includes(':')) {
        c = peel(s, {sep: ',', hie: ':'})
    } else {
        c = peel(s, {sep: '.', hie: '~'})
    }
    let name = Object.keys(c)[0]
    let out = { name: name }
    for (const k of Object.keys(c)) {
        if (k !== name) out[k] = c[k]
    }
    return out
//#endregion

//#region wire — the deliverance seam
//  Deliverance is a SEAM with two wires under it. The REAL one is the Peeroleum spine: when the
//   sender's identity holds a transport station in w (a %Peering,name:<prepub> flock), a swarm
//    frame rides the one envelope as an ADDITIVE type — outbox/ack/retransmit/dedup for free, and
//     the pre-Ud gate means it only ever crosses an AUTHENTICATED link (Cluster_spec §3). The
//      fallback is the in-process %mail drop (deterministic — Swarm_spec §9) for transportless
//       worlds; delivered frames stay as husks (%frame,did) so the handshake leaves a legible
//        trace either way. Nothing above this seam knows which wire carried it.

// Swarm_account_of — the local-recipient resolution: the identity in w whose prepub this is.
//  The account tree in w is the Books' arrangement; a LIVE station world carries no accounts —
//   there the recipient can only be the machine's one live self (A:Clustation's active identity),
//    so fall through to it when the prepub matches. Book prepubs are seeded, never the live
//     random one, so the fallback can't cross-resolve a test frame.
Swarm_account_of(w, prepub):
    for (const acct of w.o({ Account: 1 })) {
        let ident = acct.o({ Identity: 1 }).find(i => i.sc.prepub === prepub)
        if (ident) return ident
    }
    let self = this.Swarm_live_self()
    if (self && self.sc.prepub === prepub) return self
    return null

// Swarm_deliver — carry a frame from `ident` to the page at `prepub`; false = unreachable.
//  Transport first: my station's %Pier for them carries it as a real frame (never falling
//   through — an unready link is unreachable, not a reason to whisper locally). No station →
//    the in-process mail drop, gated on the target's online flag. The frame object rides
//     .c.frame|the envelope (never snapped); the kind alone is the visible face.
Swarm_deliver(w, ident, prepub, frame):
    if (!prepub) return false
    let station = w.o({ Peering: 1 }).find(p => p.sc.name === ident.sc.prepub)
    let route = station && station.o({ Pier: 1 }).find(p => p.sc.pub === prepub)
    if (route) {
        // readiness: the Book wire runs the FULL per-Pier handshake, so peer_ready is the gate
        //  there. A LIVE station (v1 — the Lies-channel precedent) never seeds that handshake:
        //   it is trust-stamped at promotion and its link auth is the relay's signed hello-bind,
        //    so there a live carrier IS readiness. Books never set station_up — fixtures see the
        //     strict gate unchanged. The real per-Pier handshake at the door is the owed upgrade.
        let ready = this.Peeroleum_peer_ready(route) || (w.c.station_up && !!this.Peeroleum_carrier(station, w))
        if (!ready) return false
        let seq = this.Pier_next_seq(route)
        // attach the per-era voucher so the sealed receiver can prove it was US (the relay won't)
        if (w.c.station_voucher) frame.voucher = w.c.station_voucher
        this.Peeroleum_send(w, { header: { type: frame.kind, from: ident.sc.prepub, to: prepub, seq: seq }, swarm: frame })
        return true
    }
    let target = this.Swarm_account_of(w, prepub)
    if (!target) return false
    if (!this.Swarm_peering(target)?.sc?.online) return false
    let inbox = target.oai({ mail: 1 })
    inbox.c.up = target
    let m = inbox.i({ frame: frame.kind })
    m.c.frame = frame
    return true

// Swarm_arm — register the swarm frame kinds on the world's Peeroleum on-registry (additive
//  frames, ZERO spine change): an inbound pier_hello|pier_accept|pier_reject resolves its LOCAL
//   recipient by header.to and lands in the SAME handshake verbs the mail wire feeds. Once per w.
Swarm_arm(w):
    if (!w.c.on) w.c.on = {}
    let hear = async (w2, pier, frame) => {
        let ident = this.Swarm_account_of(w2, frame.header.to)
        if (!ident) return false
        let from = frame.swarm?.page?.prepub
        let sealed = from ? this.Swarm_peering(ident)?.o({ Pier: 1, pub: from })[0] : null
        // THE VOUCHER GATE — the relay routes on header.to only and never checks header.from,
        //  so on a LIVE station any socket could forge a sealed friend's prepub.  A frame from a
        //   SEALED pier must therefore carry a valid per-era voucher signed by the key we imported
        //    at seal, else it is DEAD here: no heard_at (a spoofer must not warm presence), no
        //     dispatch.  A stranger (no sealed pier) is ungated — their own credential is checked
        //      downstream; pier_hello is EXEMPT (it arrives BEFORE the seal, with its Idzeug proof).
        //       Books never set station_up, so the mail-wire fixtures never see this gate.
        if (sealed && w2.c.station_up && frame.header.type !== 'pier_hello') {
            let ok = await this.Swarm_voucher_ok(sealed, from, frame.swarm?.voucher)
            if (!ok) {
                this.Swarm_rebuff(ident, 'unvouched_' + frame.header.type, from)
                return false
            }
        }
        // PRESENCE, for free: a VOUCHED (or ungated) inbound frame from an already-sealed pier
        //  stamps heard_at (c-side — never snapped, Books untouched).  A stranger stamps nothing —
        //   the same law as ive_got: gossip never opens a door.  The 'pulse' kind exists ONLY to
        //    generate this traffic (Swarm_pulse_all); it needs no verb of its own.
        if (sealed) sealed.c.heard_at = Date.now()
        if (frame.header.type === 'pier_hello') await this.Swarm_hello(w2, ident, frame.swarm)
        if (frame.header.type === 'pier_accept') await this.Swarm_accept(w2, ident, frame.swarm)
        if (frame.header.type === 'pier_confirm') await this.Swarm_confirmed(w2, ident, frame.swarm)
        if (frame.header.type === 'pier_reject') this.Swarm_rejected(w2, ident, frame.swarm)
        if (frame.header.type === 'reinvite') await this.Swarm_reinvited(w2, ident, frame.swarm)
        if (frame.header.type === 'reinvite_honour') await this.Swarm_reinvite_honoured(w2, ident, frame.swarm)
        if (frame.header.type === 'reinvite_seal') await this.Swarm_reinvite_sealed(w2, ident, frame.swarm)
        if (frame.header.type === 'reinvite_ok') await this.Swarm_reinvite_ok(w2, ident, frame.swarm)
        if (frame.header.type === 'ive_got') this.Swarm_ive_got(w2, ident, frame.swarm)
        if (frame.header.type === 'swarm_hi') this.Swarm_heard_hi(w2, ident, frame)
        if (frame.header.type === 'suggest') this.Swarm_suggested(w2, ident, frame.swarm)
        if (frame.header.type === 'suggest_got') this.Swarm_suggest_got(w2, ident, frame.swarm)
        return true
    }
    for (const kind of ['pier_hello', 'pier_accept', 'pier_confirm', 'pier_reject', 'reinvite', 'reinvite_honour', 'reinvite_seal', 'reinvite_ok', 'ive_got', 'pulse', 'swarm_hi', 'suggest', 'suggest_got']) w.c.on[kind] = hear

// Swarm_voucher_ok — is this voucher a valid proof the sealed friend `from` sent the frame?
//  (1) a cache hit — a voucher whose sign we already proved this era — passes without crypto.
//   (2) otherwise: prepubOf(vh.pub) must equal the claimed sender, vh.pub must equal the pub we
//    IMPORTED at seal (their %Pier's %Peering page), and the ed25519 signature must verify against
//     vh.pub.  All three hold ⇒ cache the sign and accept; any fail ⇒ reject (caller rebuffs).
async Swarm_voucher_ok(sealed, from, vh):
    if (!vh || !vh.sign || !vh.pub) return false
    if (sealed.c.voucher_ok && sealed.c.voucher_ok === vh.sign) return true
    if (prepubOf(vh.pub) !== from) return false
    let held = sealed.o({ Peering: 1 })[0]?.sc?.pub
    if (!held || held !== vh.pub) return false
    let who = await verifyHeader(vh, [vh.pub])
    if (who !== vh.pub) return false
    sealed.c.voucher_ok = vh.sign
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
        if (frame.kind === 'pier_confirm') await this.Swarm_confirmed(w, ident, frame)
        if (frame.kind === 'pier_reject') this.Swarm_rejected(w, ident, frame)
        if (frame.kind === 'reinvite') await this.Swarm_reinvited(w, ident, frame)
        if (frame.kind === 'reinvite_honour') await this.Swarm_reinvite_honoured(w, ident, frame)
        if (frame.kind === 'reinvite_seal') await this.Swarm_reinvite_sealed(w, ident, frame)
        if (frame.kind === 'reinvite_ok') await this.Swarm_reinvite_ok(w, ident, frame)
        if (frame.kind === 'ive_got') this.Swarm_ive_got(w, ident, frame)
    }

// Swarm_rebuff — a failed redeem|hello surfaces as %rebuff under the identity: legible in the
//  snap, and the seed of §3's error-surfacing TODO (the owner should SEE a rebuff).
Swarm_rebuff(ident, why, say):
    console.log('🚪 rebuff %' + why + (say ? ' — ' + String(say).slice(0, 60) : ''))
    ident.i({ rebuff: why, say: String(say ?? '').slice(0, 60) })

// ── the invite ledger survives reload ───────────────────────────────────────────────────────
//  The %Idzeug records under the %Peering are runtime particles, so mint-then-reload made the
//   door deny its OWN invite ('unknown' — the 2026-07-18 two-tab seal failure).  The durable
//    twin rides the top House stash (auto-saved, the BigSoundland_sprawl rail) keyed
//     prepub → nonce; the station standup rehydrates records before any hello can arrive
//      (handlers only arm AT standup).  Spend marks both homes — a reload never un-spends.
Swarm_iz_stash(ident, nonce, c):
    let live = this.Swarm_live_self ? this.Swarm_live_self() : null
    if (!live || live !== ident) return
    let st = this.top_House().stashed
    if (!st) return
    if (!st.Swarm_izzes) st.Swarm_izzes = {}
    let prepub = ident.sc.prepub
    if (!st.Swarm_izzes[prepub]) st.Swarm_izzes[prepub] = {}
    let mine = st.Swarm_izzes[prepub]
    mine[nonce] = { ...(mine[nonce] || {}), ...c }

Swarm_iz_rehydrate(w, ident):
    let st = this.top_House().stashed
    let mine = st?.Swarm_izzes?.[ident.sc.prepub]
    if (!mine) return
    let peering = this.Swarm_peering(ident)
    for (const nonce of Object.keys(mine)) {
        let c = mine[nonce]
        let record = peering.o({ Idzeug: nonce })[0]
        if (!record) {
            record = peering.i({ Idzeug: nonce, to: c.to })
            record.c.up = peering
            if (c.ttl) record.sc.ttl = c.ttl
            if (c.chain) record.sc.chain = 1
            // Feature params survive too — the door's presig regeneration and its grant mint read
            //  the RECORD (never a carried $n), so a reloaded ledger must re-wear them exactly.
            for (const k of Object.keys(c)) {
                if (!['to', 'ttl', 'chain', 'spent', 'holder', 'blotter'].includes(k)) record.sc[k] = String(c[k])
            }
        }
        if (c.spent) record.sc.spent = 1
        // chain tip survives reload too — else a reloaded inviter forgets who holds it and its
        //  door would re-admit the link as a fresh first claim (§6.3a).
        if (c.chain) record.sc.chain = 1
        if (c.holder) record.sc.holder = c.holder
        // blotter membership survives reload — the sheet record re-derives its count from members,
        //  so no snapped counter to drift; the serial just re-declares which sheet it was torn from.
        if (c.blotter) {
            record.sc.blotter = c.blotter
            let sheet = peering.oai({ Blotter: c.blotter })
            sheet.c.up = peering
        }
    }
//#endregion

//#region station — the LIVE relay standup (§10.1 the frontier rung: two BigSoundlands become for each other)
//  The Books' wire is Lake_link's mock pair; THIS is the production twin — one real websocket to
//   our own-origin /relay, addressed by PREPUB, never by role. No `become` is ever sent: the
//    editor|runner role table stays untouched (a second role claimant eats the fleet's
//     role-addressed frames — roles divide, addresses deliver). Reachability is the ?addr=
//      bind (Socket_real dials ?addr=<our Peering name> = our prepub) upgraded by the SIGNED
//       relay hello, so a to:<prepub> frame routes to the proven key-holder.

// Swarm_station_world — the canonical oai spot for the live transport world: w:Swarm under
//  A:Clustation, beside the identity it serves. Its OWN world so the transport slots
//   (%transport/%active_transport) and the w.c.on registry never collide with w:Lies's channel.
Swarm_station_world():
    let A = this.top_House().o({ A: 'Clustation' })[0]
    if (!A) return null
    let w = A.oai({ w: 'Swarm' })
    w.c.up = A
    return w

// Swarm_station_up — idempotent: stand the station %Peering named our prepub (BEFORE Socket_real,
//  which reads the first Peering's name as its ?addr=), arm the swarm frame kinds, dial the relay,
//   and hello-bind our key on every (re)open. Returns the station, or null while the transport
//    ghosts haven't deposited (the boot window) — the caller just asks again.
Swarm_station_up(w, ident):
    if (!w || !ident?.c?.keys) return null
    if (!w.c.iz_rehydrated && this.top_House().stashed) { w.c.iz_rehydrated = 1; this.Swarm_iz_rehydrate(w, ident) }
    if (!w.c.piers_rehydrated && this.top_House().stashed) { w.c.piers_rehydrated = 1; this.Swarm_piers_rehydrate(w, ident) }
    if (!w.c.roots_rehydrated && this.top_House().stashed) { w.c.roots_rehydrated = 1; this.Swarm_chainroots_rehydrate(w, ident) }
    let station = w.o({ Peering: 1 }).find(p => p.sc.name === ident.sc.prepub)
    if (station && w.c.station_up) return station
    if (typeof this.Socket_real !== 'function') return null
    if (typeof WebSocket === 'undefined') return null
    station = w.oai({ Peering: 1, name: ident.sc.prepub })
    station.c.up = w
    this.Swarm_arm(w)
    this.Socket_real(w)
    let port = w.o({ transport: 1, type: 'websocket' })[0]?.c.port
    if (port?.on_open) {
        port.on_open(async () => {
            // the authenticated bind (relay.ts handleHello): sign {control,from,pub,ts} with the
            //  identity key so the relay routes to:<prepub> to the REAL key-holder, not whoever
            //   claimed the ?addr=. Re-fires on every reconnect. Failure = relay down; the
            //    socket's own backoff re-dials and this hook re-runs.
            try {
                let header = { control: 'hello', from: ident.sc.prepub, pub: ident.c.keys.pub, ts: Date.now() }
                let sign = await signHeader(header, ident.c.keys.key)
                port.ws?.send(JSON.stringify(Object.assign({}, header, { sign: sign })))
            } catch (e) { console.warn('⨳ station hello failed (relay down?)', e) }
            // the per-era VOUCHER: the relay authenticates the LINK (the hello above) but ROUTES
            //  on header.to alone and never checks header.from against the key we sealed, so a
            //   spoofer on any socket could forge a friend's prepub.  We sign a tiny proof our
            //    identity key holds this station and attach it to every swarm frame we route; a
            //     sealed friend re-verifies US against the pub they imported at seal.  One era per
            //      standup, re-signed on every (re)open so a stale one can't outlive an era change.
            try {
                w.c.station_era = w.c.station_era || Date.now()
                let vh = { control: 'voucher', from: ident.sc.prepub, pub: ident.c.keys.pub, era: w.c.station_era, ts: Date.now() }
                vh.sign = await signHeader(vh, ident.c.keys.key)
                w.c.station_voucher = vh
            } catch (e) { console.warn('⨳ station voucher failed', e) }
            // the rebirth greeting rides every (re)connect, right behind the hello-bind — same
            //  socket, ordered, so the relay routes it the moment the bind lands.  Routes first:
            //   a reconnect may follow a reload that hasn't re-minted them yet.
            this.Swarm_station_routes(w, ident)
            this.Swarm_hi_all(w, ident)
        })
    }
    this.Tribunal_activate_websocket(w)
    w.c.station_up = 1
    this.Swarm_station_routes(w, ident)
    return station

// Swarm_station_pier — promote first-contact into a transport route: the station's %Pier keyed by
//  their prepub, %Ud stamped (v1 trust — the pre-Ud inbox gate books their frames; the swarm layer
//   above re-verifies every signature itself). The Lies_runner_pier shape. No-op without a station,
//    so the Books' mail-wire worlds (and their fixtures) never see it.
Swarm_station_pier(w, ident, prepub):
    if (!w || !ident || !prepub) return null
    let station = w.o({ Peering: 1 }).find(p => p.sc.name === ident.sc.prepub)
    if (!station) return null
    let pier = station.oai({ Pier: 1, pub: prepub })
    pier.c.up = station
    pier.oai({ Ud: 1 })
    return pier

// Swarm_station_routes — re-mint the transport route for EVERY sealed friendship.  The route
//  %Pier (+%Ud) was minted only at invite time, so a reloaded tab held friendships it could
//   neither speak to nor hear (Peeroleum_deliver's no-pier drop swallowed every inbound frame):
//    the friendship SURVIVED the reload, the link did not.  Idempotent (oai all the way down);
//     runs at standup and on every socket (re)open.
Swarm_station_routes(w, ident):
    let n = 0
    for (const pier of this.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []) {
        if (!pier.sc.pub) continue
        if (this.Swarm_station_pier(w, ident, String(pier.sc.pub))) n = n + 1
    }
    this.Swarm_reaccept_incomplete(w, ident)
    return n

// Swarm_reaccept_incomplete — the SEAL SELF-HEAL (the human 2026-07-28: the pairing came out ONE-WAY —
//  Righto held a %Pier for Lefto but Lefto held NONE.  The single `pier_accept` frame builds the
//   redeemer's WHOLE %Pier, and if it's lost or seq-collision-muted after a reload NOTHING ever re-drives
//    it — every redial path iterates existing %Piers, so the side with none is invisible to all healing).
//   Cure, driven from the ISSUER (the side that reliably HOLDS a %Pier and can detect the gap): on every
//    redial, for each of my %Piers that lacks the friend's RECIPROCAL grant, re-send `pier_accept` reusing
//     my ALREADY-SIGNED grant atom (grant_of_C — never re-mint/re-sign).  Swarm_accept rebuilds the
//      redeemer's %Pier from scratch and re-confirms; the reciprocal grant lands, the predicate flips false,
//       the re-send stops.  Signature-safe: `page` is unsigned + bind-checked at the far end, the grant atom
//        is REUSED (the redeemer re-runs verify_grant and it checks out).  Cannot false-positive: a redeemer's
//         %Pier is born with BOTH grants (Swarm_accept), so only an issuer half-seal ever matches.
Swarm_reaccept_incomplete(w, ident):
    let me = ident.c.keys ? ident.c.keys.pub : null
    if (!me) return 0
    let n = 0
    for (const pier of this.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []) {
        if (!pier.sc.pub) continue
        let peer = pier.o({ Peering: 1 })[0]
        let theirPub = peer ? peer.sc.pub : null
        if (!theirPub) continue
        if (String(theirPub) === String(me)) continue                  // never re-drive the self-pier
        if (pier.o({ Grant: 1, by: String(theirPub) })[0]) continue     // already complete — has the reciprocal grant
        let mineC = pier.o({ Grant: 1, by: String(me) })[0]
        if (!mineC) continue                                            // no own grant to reuse — not an issuer half-seal
        this.Swarm_deliver(w, ident, String(pier.sc.pub), { kind: 'pier_accept', grant: grant_of_C(mineC), page: this.Swarm_page(ident) })
        n = n + 1
    }
    return n

// ── the rebirth greeting (swarm_hi) ─────────────────────────────────────────────────────────
//  A refreshed tab restarts its per-Pier seq at 1, and the surviving side's inbox still holds
//   finished %unemit rows for those (seq,type) pairs — every real frame the reborn side sends
//    books into a finished req and dies undispatched, unacked: the silent post-reload mute
//     (Cluster_spec's owed reconnect-epoch).  swarm_hi is the cure: an EPHEMERAL frame
//      (collision-immune by lane — Peeroleum_send/deliver) carrying my station ERA.  A changed
//       era at the hearer resets the route (Peeroleum_reset_handshake: stream history gone,
//        %Ud kept) so the reborn peer's frames book fresh.  Sent on every socket (re)open and
//         whenever a pulse pass finds a friend silent — the link self-heals from EITHER side.

// one greeting to one friend; reply:1 marks an answer (answers are never re-answered).
Swarm_hi_one(w, ident, prepub, reply):
    let route = this.Swarm_station_pier(w, ident, prepub)
    if (!route) return false
    let station = w.o({ Peering: 1 }).find(p => p.sc.name === ident.sc.prepub)
    if (!w.c.station_up || !this.Peeroleum_carrier(station, w)) return false
    w.c.station_era = w.c.station_era || Date.now()
    let hi = { kind: 'swarm_hi', era: w.c.station_era, page: this.Swarm_page(ident) }
    if (reply) hi.reply = 1
    // swarm_hi rides Peeroleum_send DIRECTLY (not Swarm_deliver), so carry the voucher itself —
    //  a sealed friend gates swarm_hi like every other frame (it isn't pier_hello).
    if (w.c.station_voucher) hi.voucher = w.c.station_voucher
    let seq = this.Pier_next_seq(route)
    this.Peeroleum_send(w, { header: { type: 'swarm_hi', from: ident.sc.prepub, to: prepub, seq: seq }, swarm: hi })
    return true

Swarm_hi_all(w, ident):
    let n = 0
    for (const pier of this.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []) {
        if (pier.sc.pub && this.Swarm_hi_one(w, ident, String(pier.sc.pub), 0)) n = n + 1
    }
    return n

// hear a greeting: sealed friends only (gossip never opens a door — the stranger's hi does
//  nothing, exactly like a stranger's boast).  Era change = the peer RESTARTED: reset the
//   route's stream state and clear the want-once cursors (a vanished want must be re-askable
//    after a rebirth — w.c.ra_wanted would otherwise hold every lost pull as a permanent hole).
//     A first hi is answered (they learn MY era) and followed by a fresh boast; a reply isn't.
Swarm_heard_hi(w, ident, frame):
    let hi = frame.swarm || {}
    // identity is the SIGNED page's prepub ONLY — the same key the hear() voucher gate checks
    //  (frame.swarm.page.prepub). The old `|| frame.header.from` fallback let a hi that OMITS its
    //   swarm.page slip the voucher gate (gate saw no page → skipped) and then rebind to the forgeable
    //    header.from — reopening the very hole the gate closes. No page = malformed = do nothing.
    let from = hi.page?.prepub
    if (!from) return
    let sealed = this.Swarm_peering(ident)?.o({ Pier: 1, pub: String(from) })[0]
    if (!sealed) return
    let route = this.Swarm_station_pier(w, ident, String(from))
    if (!route) return
    if (hi.era && route.c.peer_era && route.c.peer_era !== hi.era) {
        this.Peeroleum_reset_handshake(route)
        delete w.c.ra_wanted
        delete w.c.ra_want_ts
    }
    if (hi.era) route.c.peer_era = hi.era
    if (!hi.reply) {
        this.Swarm_hi_one(w, ident, String(from), 1)
        this.Swarm_gossip_music(w, ident)
    }
    // they are HERE — anything queued for them goes now (the store-and-forward drain)
    this.Swarm_suggest_resend(w, ident, String(from))
//#endregion

//#region handshake — live, both online (§6.3)

// Swarm_redeem — the invitee opens the ?Iz= link WHILE ONLINE: parse the compact token and prove
//  receipt by dialing the issuer with a pier_hello that ECHOES it — carrying our page and NOTHING
//   else. The token no longer names the issuer's full pub, so our reciprocal grant cannot mint
//    here: it DEFERS to Swarm_accept (their pier_accept reveals page.pub) and rides back as
//     pier_confirm — THREE frames seal the friendship (§6.3, the ReInvite honour→seal shape).
//      The issuer offline → the redeem simply FAILS (%rebuff,offline): the token proves receipt,
//       it does not stand in for an absent party.
async Swarm_redeem(w, ident, iz):
    let t = this.Swarm_token_parse(iz)
    if (!t) {
        this.Swarm_rebuff(ident, 'forged', iz)
        return null
    }
    let hello = { kind: 'pier_hello', iz: iz, page: this.Swarm_page(ident) }
    if (!this.Swarm_deliver(w, ident, t.prepub, hello)) {
        this.Swarm_rebuff(ident, 'offline', t.prepub)
        return null
    }
    return t

// Swarm_hello — the issuer hears a pier_hello: the old Idzeugnosis seat with the peer its OWN
//  authority. Valid = the echoed token names OUR address, its serial is on our %Peering ledger,
//   and its presig REGENERATES from our own record (the issuer-side MAC — ed25519 is deterministic,
//    so we re-sign the domain and prefix-match; a guessed serial can never wear it). Then the seal:
//     spend the serial, mint our BOUND grant, seal ONE-SIDED (their reciprocal follows as
//      pier_confirm), import their page as a %Pier, and answer pier_accept.
async Swarm_hello(w, ident, frame):
    // VERIFY BEFORE WE LEAVE A TRACE (the F3 flood + the SwarmSpoof tooth): a junk / forged /
    //  misdirected / spoofed / UNKNOWN-serial hello must mint NO transport route, stamp NO %Ud,
    //   and send NO reply — replying only confirms us to a spammer, and serials are GUESSABLE
    //    (a blotter counts <tag>-1, <tag>-2…), so unlike the old full-signature door even an
    //     unknown serial refuses LOCALLY: without a ledger record there is nothing that proves
    //      the caller ever held OUR link. Only a presig-proven redeemer gets a route and a
    //       reasoned deny. (station_pier is a no-op without a station, so the Books' mail-wire
    //        fixtures never see the route either way — this is the live-relay surface, §10.1.)
    let refuse = (why) => { this.Swarm_rebuff(ident, 'hello_' + why, frame.page?.prepub); return null }
    let t = this.Swarm_token_parse(frame.iz)
    if (!t) return refuse('forged')
    if (t.prepub !== ident.sc.prepub) return refuse('not_ours')
    if (!this.Swarm_page_bound(frame.page)) return refuse('spoofed')
    let record = this.Swarm_peering(ident).o({ Idzeug: t.serial })[0]
    if (!record) return refuse('unknown')
    let n = this.Swarm_token_n(String(record.sc.to), this.Swarm_record_params(record))
    let presig = await this.Swarm_presig(ident.c.keys, ident.sc.prepub, t.serial, n)
    if (presig !== t.presig) return refuse('forged')
    // proven: OUR invite, on a bound page — a real redeemer. NOW promote the return route (the
    //  pier_accept and every reason below ride it), and answer with denials the honest redeemer can act on.
    this.Swarm_station_pier(w, ident, frame.page?.prepub)
    let deny = (why) => {
        this.Swarm_rebuff(ident, 'hello_' + why, frame.page?.prepub)
        this.Swarm_deliver(w, ident, frame.page?.prepub, { kind: 'pier_reject', why: why, prepub: ident.sc.prepub })
        return null
    }
    if (record.sc.spent) return deny('spent')
    // chain policy (§6.3a): a chain invite is not spent on first claim — its first claimant becomes
    //  the tracked HOLDER (the tip), sealed as a normal friend below. A LATER redeem by a NON-holder
    //   is the chain GROWING: the newcomer holds the link the tip passed them, so mint a ReInvite and
    //    let the newcomer carry it to the tip (§6.3a) — the tip, not us, grants + befriends them. The
    //     tip re-redeeming its OWN link is a benign no-op (deny('held')).
    if (record.sc.chain && record.sc.holder) {
        if (frame.page.prepub === record.sc.holder) return deny('held')
        return await this.Swarm_reinvite_begin(w, ident, record, frame)
    }
    // a plain invite SPENDS; a chain invite records its first holder (the tip the chain grows from)
    if (record.sc.chain) {
        record.sc.holder = frame.page.prepub
        this.Swarm_iz_stash(ident, t.serial, { holder: frame.page.prepub })
    } else {
        record.sc.spent = 1
        this.Swarm_iz_stash(ident, t.serial, { spent: 1 })
    }
    let mine = await mint_grant(ident.c.keys, frame.page.pub, String(record.sc.to), this.Swarm_record_params(record), this.Swarm_now(w))
    let pier = this.Swarm_seal(w, ident, frame.page, null, mine)
    this.Swarm_deliver(w, ident, frame.page.prepub, { kind: 'pier_accept', grant: mine, page: this.Swarm_page(ident) })
    return pier

// Swarm_accept — the redeemer hears pier_accept: verify the issuer's bound grant is really theirs
//  and really FOR US, then seal our own %Pier AND mint the DEFERRED reciprocal (§6.3): the compact
//   token never carried their full pub — HERE the accept's own page.pub names them (bound and
//    grant-proven above), so our grant mints now, seals beside theirs, and rides back as
//     pier_confirm — the third frame. Both being online, the living connection stands at once.
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
    if (!this.Swarm_page_bound(frame.page)) {
        this.Swarm_rebuff(ident, 'accept_spoofed', frame.page?.prepub)
        return null
    }
    let mine = await mint_grant(ident.c.keys, frame.page.pub, claim.to, this.Swarm_iz_params(claim), this.Swarm_now(w))
    let pier = this.Swarm_seal(w, ident, frame.page, frame.grant, mine)
    this.Swarm_deliver(w, ident, frame.page.prepub, { kind: 'pier_confirm', grant: mine, page: this.Swarm_page(ident) })
    return pier

// Swarm_rejected — the inviter said no (spent|held|bad_grant…): surface it, nothing sealed.
Swarm_rejected(w, ident, frame):
    this.Swarm_rebuff(ident, 'rejected_' + frame.why, frame.prepub)

// Swarm_confirmed — the issuer hears pier_confirm: the redeemer's DEFERRED reciprocal (§6.3, the
//  third frame; mirrors Swarm_reinvite_sealed). Only an ALREADY-SEALED redeemer may confirm —
//   Swarm_hello minted the %Pier one-sided, so a confirm from a stranger is a probe, not a seal:
//    rebuff locally, never reply, and never let Swarm_seal mint a fresh pier here. Idempotent —
//     the seal dedups grants, a re-delivered confirm no-ops.
async Swarm_confirmed(w, ident, frame):
    let deny = (why) => {
        this.Swarm_rebuff(ident, 'confirm_' + why, frame.page?.prepub)
        return null
    }
    if (!this.Swarm_page_bound(frame.page)) return deny('spoofed')
    if (!this.Swarm_peering(ident).o({ Pier: 1, pub: frame.page.prepub })[0]) return deny('unexpected')
    let theirs
    try { theirs = await verify_grant(frame.grant) }
    catch (er) { return deny('bad_grant') }
    if (theirs.for !== ident.c.keys.pub || theirs.by !== frame.page.pub) return deny('grant_mismatch')
    return this.Swarm_seal(w, ident, frame.page, frame.grant, null)

// ── the ReInvite chain wire (§6.3a) — Alice tracks, the TIP grants ──────────────────────────
//  Five frames grow the chain by ONE (A—B already sealed; Bob is the tip):
//   1. pier_hello   Carol→Alice   Carol redeems Alice's HELD chain link (Swarm_hello diverts here)
//   2. reinvite     Alice→Carol   Alice mints a single-use ReInvite (tip=Bob, newcomer=Carol)…
//   3. reinvite     Carol→Bob     …and Carol carries it to Bob, her new friend (same kind, other role)
//   4. reinvite_honour Bob→Carol  Bob verifies Alice's signature + grants Carol the capped Feature
//   5. reinvite_seal   Carol→Bob  Carol reciprocates; B—C is now a mutual, durable friendship
//   6. reinvite_ok     Bob→Alice  Bob confirms → Alice advances her tracker Bob→Carol, spends rnonce
//  Airtight by signature: the ReInvite EMBEDS Alice's original invite, so BOTH ends verify the SAME
//   Alice pub (Bob against his A—B friend; Carol against the link she redeemed). Bob — the tip, never
//    Alice — signs Carol's grant, capped at the embedded Feature (no escalation). Carol never seals
//     Alice (the transient redeem reference is dropped); she keeps only a LIGHT %ChainRoot so she can
//      honour a future ReInvite that names HER as tip (Carol→Dave), the chain growing past her.

// Swarm_reinvite_begin — Alice, hearing a NON-holder redeem her held chain link: mint a fresh
//  single-use ReInvite naming the current tip + this newcomer, remember it pending (seam 1: the
//   tracker only advances on the tip's later confirmation), and hand it to the newcomer to carry.
async Swarm_reinvite_begin(w, ident, record, frame):
    let newcomer = frame.page.prepub
    record.c.rseq = (record.c.rseq || 0) + 1
    let rnonce = String(record.sc.Idzeug) + '-r' + record.c.rseq
    let rib = await this.Swarm_mint_reinvite(w, ident, record, newcomer, rnonce)
    if (!record.c.pending) record.c.pending = {}
    record.c.pending[rnonce] = { newcomer: newcomer }
    this.Swarm_deliver(w, ident, newcomer, { kind: 'reinvite', rib: rib, page: this.Swarm_page(ident) })
    return null

// Swarm_reinvited — the `reinvite` frame, dispatched by MY role in the embedded credential:
//  I am the NEWCOMER → Alice just handed me the ReInvite; remember it and carry it to the tip (my
//   new friend). I am the TIP → the newcomer brought it to me; honour it. Neither → not mine.
async Swarm_reinvited(w, ident, frame):
    let r
    try { r = await this.Swarm_verify_reinvite(frame.rib) }
    catch (er) { return this.Swarm_rebuff(ident, 'reinvite_forged', frame.page?.prepub) }
    if (r.newcomer === ident.sc.prepub) {
        if (!ident.c.rib_in) ident.c.rib_in = {}
        ident.c.rib_in[r.tip] = r
        this.Swarm_station_pier(w, ident, r.tip)
        this.Swarm_deliver(w, ident, r.tip, { kind: 'reinvite', rib: frame.rib, page: this.Swarm_page(ident) })
        return null
    }
    if (r.tip === ident.sc.prepub) return await this.Swarm_reinvite_honour(w, ident, frame, r)
    return this.Swarm_rebuff(ident, 'reinvite_notmine', frame.page?.prepub)

// Swarm_reinvite_honour — Bob (the tip): the newcomer brought a ReInvite naming me. Validate it is
//  really mine to honour (tip==me, newcomer==caller), that its lineage root (Alice) is one I know —
//   a direct friend OR a %ChainRoot I kept from joining — then GRANT the newcomer, capped EXACTLY at
//    the embedded Feature (no escalation), and seal B—C. Their reciprocal follows in reinvite_seal.
async Swarm_reinvite_honour(w, ident, frame, r):
    let deny = (why) => {
        this.Swarm_rebuff(ident, 'reinvite_' + why, frame.page?.prepub)
        return null
    }
    // the tip mints the newcomer's grant for frame.page.pub with NO proof-of-possession (the audit's
    //  F1): bind the claimed address to that key so the tip can only ever grant the REAL newcomer's
    //   key — a captor of the plaintext rib can no longer wear its own key while claiming Carol's.
    if (!this.Swarm_page_bound(frame.page)) return deny('spoofed')
    if (r.tip !== ident.sc.prepub) return deny('not_tip')
    if (r.newcomer !== frame.page.prepub) return deny('newcomer_mismatch')
    if (!this.Swarm_chain_root_ok(ident, r.by)) return deny('unknown_root')
    let mine = await mint_grant(ident.c.keys, frame.page.pub, r.feature, r.params, this.Swarm_now(w))
    this.Swarm_seal(w, ident, frame.page, null, mine)
    if (!ident.c.honouring) ident.c.honouring = {}
    ident.c.honouring[frame.page.prepub] = { root: prepubOf(r.by), rnonce: r.rnonce, nonce: r.nonce }
    // route promoted only now, past every check — a forged reinvite leaves no transport trace (F3)
    this.Swarm_station_pier(w, ident, frame.page?.prepub)
    this.Swarm_deliver(w, ident, frame.page.prepub, { kind: 'reinvite_honour', grant: mine, page: this.Swarm_page(ident) })
    return null

// Swarm_reinvite_honoured — Carol (the newcomer): the tip granted me. Verify the grant is really
//  FOR me, by the very tip the ReInvite named (pub → prepub), and no wider than the chain Feature.
//   Reciprocate + seal B—C, keep a LIGHT %ChainRoot (the lineage authority, NOT a music contact),
//    DROP the transient Alice reference, and tell the tip I sealed so Alice can advance.
async Swarm_reinvite_honoured(w, ident, frame):
    let deny = (why) => {
        this.Swarm_rebuff(ident, 'honour_' + why, frame.page?.prepub)
        return null
    }
    if (!this.Swarm_page_bound(frame.page)) return deny('spoofed')
    let bob
    try { bob = await verify_grant(frame.grant) }
    catch (er) { return deny('bad_grant') }
    if (bob.for !== ident.c.keys.pub) return deny('not_for_me')
    let pend = ident.c.rib_in ? ident.c.rib_in[frame.page.prepub] : null
    if (!pend) return deny('unexpected')
    if (prepubOf(bob.by) !== pend.tip) return deny('tip_mismatch')
    if (bob.to !== pend.feature) return deny('escalation')
    let mine = await mint_grant(ident.c.keys, frame.page.pub, pend.feature, pend.params, this.Swarm_now(w))
    this.Swarm_seal(w, ident, frame.page, frame.grant, mine)
    let cr = ident.oai({ ChainRoot: 1, pub: pend.by })
    cr.c.up = ident
    cr.sc.prepub = prepubOf(pend.by)
    this.Swarm_chainroot_stash(ident, pend.by)
    if (ident.c.offered) delete ident.c.offered[pend.by]
    delete ident.c.rib_in[frame.page.prepub]
    // route promoted only now, past verify_grant + every check — a forged honour leaves no trace (F3)
    this.Swarm_station_pier(w, ident, frame.page?.prepub)
    this.Swarm_deliver(w, ident, frame.page.prepub, { kind: 'reinvite_seal', grant: mine, page: this.Swarm_page(ident) })
    return null

// Swarm_reinvite_sealed — Bob: the newcomer reciprocated. Verify + complete the seal (idempotent —
//  adds their grant beside mine), then confirm UP the chain to the root (Alice) so she advances.
async Swarm_reinvite_sealed(w, ident, frame):
    let deny = (why) => {
        this.Swarm_rebuff(ident, 'sealed_' + why, frame.page?.prepub)
        return null
    }
    if (!this.Swarm_page_bound(frame.page)) return deny('spoofed')
    let carol
    try { carol = await verify_grant(frame.grant) }
    catch (er) { return deny('bad_grant') }
    if (carol.for !== ident.c.keys.pub) return deny('not_for_me')
    let h = ident.c.honouring ? ident.c.honouring[frame.page.prepub] : null
    if (!h) return deny('unexpected')
    this.Swarm_seal(w, ident, frame.page, frame.grant, null)
    // confirm UP the chain to the root (Alice), SIGNED by me — the tip may not be a friend of the
    //  root (a hop past the first: Carol dropped Alice), so the link is untrusted; my signature +
    //   prepubOf(pub)==her tracked holder is the credential that lets her advance, not the socket.
    let ok = { nonce: h.nonce, rnonce: h.rnonce, newcomer: frame.page.prepub, pub: ident.c.keys.pub }
    ok.sign = await signHeader(ok, ident.c.keys.key)
    this.Swarm_station_pier(w, ident, h.root)
    this.Swarm_deliver(w, ident, h.root, { kind: 'reinvite_ok', ok: ok, page: this.Swarm_page(ident) })
    delete ident.c.honouring[frame.page.prepub]
    return null

// Swarm_reinvite_ok — Alice: the tip confirmed the newcomer is sealed. VERIFY the tip's signature and
//  bind its pub to my tracked holder by prepub (only the CURRENT tip may advance — seam 1); the rnonce
//   is single-use (I minted it, delete the pending) and must match the newcomer I named. Then advance
//    the tracker to the newcomer (the chain next grows from THEM) and stash the new tip.
async Swarm_reinvite_ok(w, ident, frame):
    let ok = frame.ok
    if (!ok || !ok.sign || !ok.pub) return null
    let who = await verifyHeader(ok, [ok.pub])
    if (who !== ok.pub) return null
    let record = this.Swarm_peering(ident).o({ Idzeug: ok.nonce })[0]
    if (!record) return null
    if (prepubOf(ok.pub) !== record.sc.holder) return null
    let pend = record.c.pending ? record.c.pending[ok.rnonce] : null
    if (!pend) return null
    if (pend.newcomer !== ok.newcomer) return null
    record.sc.holder = pend.newcomer
    delete record.c.pending[ok.rnonce]
    this.Swarm_iz_stash(ident, ok.nonce, { holder: pend.newcomer })
    return null

// Swarm_chain_root_ok — may I honour a ReInvite signed by `rootPub`? Yes iff that root is a friend
//  I befriended directly (a %Pier whose imported page pub matches) OR a %ChainRoot I recorded when I
//   joined via their chain. Either way I trust that pub to name the tip — the lineage I stand in.
Swarm_chain_root_ok(ident, rootPub):
    let prepub = prepubOf(rootPub)
    let peering = this.Swarm_peering(ident)
    let friend = peering?.o({ Pier: 1, pub: prepub }).find(p => p.o({ Peering: 1 })[0]?.sc?.pub === rootPub)
    if (friend) return true
    return !!(ident.o({ ChainRoot: 1, pub: rootPub })[0])

// Swarm_chainroot_stash / _rehydrate — the LIGHT lineage reference survives reload (a %ChainRoot is
//  not a friendship, so the pier stash never carries it): keyed my-prepub → root-pub, prepub beside.
//   Without it a reloaded Carol would forget Alice's chain authority and deny Carol→Dave 'unknown_root'.
Swarm_chainroot_stash(ident, rootPub):
    let live = this.Swarm_live_self ? this.Swarm_live_self() : null
    if (!live || live !== ident) return
    let st = this.top_House().stashed
    if (!st) return
    if (!st.Swarm_roots) st.Swarm_roots = {}
    if (!st.Swarm_roots[ident.sc.prepub]) st.Swarm_roots[ident.sc.prepub] = {}
    st.Swarm_roots[ident.sc.prepub][rootPub] = { prepub: prepubOf(rootPub) }

Swarm_chainroots_rehydrate(w, ident):
    let st = this.top_House().stashed
    let mine = st?.Swarm_roots?.[ident.sc.prepub]
    if (!mine) return
    for (const rootPub of Object.keys(mine)) {
        let cr = ident.oai({ ChainRoot: 1, pub: rootPub })
        cr.c.up = ident
        cr.sc.prepub = mine[rootPub].prepub
    }

// Swarm_seal — both ends land here: the %Pier durable memory under MY %Peering — their imported
//  page (the "stashed Peering" reborn), the grant THEY signed for me, my copy of the one I signed
//   for them — plus the social-graph edge (§6.6, owner-side: each end's %SocialGraph is the local
//    view of who-befriended-whom). Idempotent: grants and edges are guarded, a re-seal no-ops.
Swarm_seal(w, ident, page, theirGrant, myGrant):
    // BACKSTOP (the SwarmSpoof tooth): never key a durable %Pier by an unbound address. Every wire
    //  entry already guards this before reaching here; a rehydrated page satisfies it (bound at its
    //   original seal), so this fires only on a corrupt stash or a future caller that skipped the wire
    //    guard — fail closed rather than plant a forged identity.
    if (!this.Swarm_page_bound(page)) return null
    let peering = this.Swarm_peering(ident)
    let pier = peering.oai({ Pier: 1, pub: page.prepub })
    pier.c.up = peering
    pier.sc.friendly = page.friendly
    // since = when the friendship BEGAN — a re-seal (redial, rehydrate) never resets it
    if (!pier.sc.since) pier.sc.since = String(this.Swarm_now(w))
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
    this.Swarm_pier_stash(ident, page, [theirGrant, myGrant], null)
    return pier

// ── the FRIENDSHIP survives reload (the iz-ledger disease, second organ) ────────────────────
//  Swarm_seal built %Pier|%Grant|%NotGrant as RUNTIME particles, and the r2r redial was quietly
//   re-sealing them only when the friend happened to be online to re-hello — a lone reload LOST
//    the friendship ("gets lost very easily", the human 2026-07-19).  The durable twin mirrors
//     Swarm_izzes exactly: top-House stash (auto-saved, the sprawl rail) keyed my-prepub →
//      their-prepub, holding their page, the RAW grant atoms, and every revocation atom.  A
//       tombstone is a negative decision-fact — the stash NEVER drops one, so a rehydrated
//        revoke still revokes.  Station standup rehydrates through Swarm_seal ITSELF
//         (idempotent), so every friendship stands before the first frame can arrive.
Swarm_pier_stash(ident, page, grants, nots):
    let live = this.Swarm_live_self ? this.Swarm_live_self() : null
    if (!live || live !== ident) return
    let st = this.top_House().stashed
    if (!st) return
    if (!st.Swarm_piers) st.Swarm_piers = {}
    let mine = st.Swarm_piers[ident.sc.prepub]
    if (!mine) { mine = {}; st.Swarm_piers[ident.sc.prepub] = mine }
    let e = mine[page.prepub]
    if (!e) { e = { page: {}, grants: [], nots: [] }; mine[page.prepub] = e }
    // merge fields, never blank a known page with a partial caller (revoke passes prepub only)
    if (page.prepub) e.page.prepub = page.prepub
    if (page.pub) e.page.pub = page.pub
    if (page.friendly) e.page.friendly = page.friendly
    for (const g of (grants || [])) {
        if (!g) continue
        let key = String(g.to) + '|' + String(g.by) + '|' + String(g.for || '')
        if (!e.grants.some(h => (String(h.to) + '|' + String(h.by) + '|' + String(h.for || '')) === key)) e.grants.push(g)
    }
    for (const a of (nots || [])) {
        if (!a) continue
        if (!e.nots.some(h => h.sign === a.sign)) e.nots.push(a)
    }

Swarm_piers_rehydrate(w, ident):
    let st = this.top_House().stashed
    let mine = st?.Swarm_piers?.[ident.sc.prepub]
    // (a) re-seal every pier the Dexie stash remembers — the WARM-reload rail, when the C tree below
    //  Clustation wasn't itself auto-saved (piers are runtime particles).
    if (mine) {
        for (const theirPrepub of Object.keys(mine)) {
            let e = mine[theirPrepub]
            if (!e?.page?.prepub) continue
            let pier = this.Swarm_seal(w, ident, e.page, e.grants?.[0] ?? null, e.grants?.[1] ?? null)
            let gi = 2
            while (gi < (e.grants?.length || 0)) {
                let g = e.grants[gi]
                if (g && !pier.o({ Grant: g.to, by: g.by })[0]) grant_to_C(pier, g)
                gi = gi + 1
            }
            for (const a of (e.nots || [])) {
                if (!pier.o({ NotGrant: a.not, by: a.by, for: a.for }).some(x => x.sc.sign === a.sign)) {
                    pier.i({ NotGrant: a.not, by: a.by, for: a.for, time: a.time, sign: a.sign })
                }
            }
            for (const s of (e.suggests || [])) {
                if (!s?.id || !s?.by) continue
                let sug = pier.oai({ Suggest: 1, id: String(s.id), by: String(s.by) })
                sug.c.up = pier
                if (s.title && !sug.sc.title) sug.sc.title = s.title
                if (s.artist && !sug.sc.artist) sug.sc.artist = s.artist
                if (s.note && !sug.sc.note) sug.sc.note = s.note
                if (s.got) sug.sc.got = 1
            }
        }
    }
    // (b) CONVERGE — a disk-SEEDED account (Swarm_boot_seed → Swarm_import → Swarm_graft) arrives with
    //  live grafted piers but an EMPTY Dexie stash: graft rebuilds the particles, it never routes through
    //   Swarm_pier_stash the way Swarm_seal does.  Left there, the friends would vanish on the NEXT
    //    reload (this rail reads Dexie, which never learned them).  Mirror every live pier into the stash
    //     now — idempotent, and guarded to the live self inside pier_stash, so a Book's puppets and a
    //      foreign tab never pollute the House stash.
    this.Swarm_restash_piers(ident)
//#endregion

// Swarm_pier_entry — the durable Dexie shape for ONE live %Pier: its page (pub-derived prepub + the
//  friend's pub + friendly) plus its raw grant + revocation atoms, re-derived straight from the
//   particle (grant_of_C is Grant.ts's swap-OUT reverse; a %NotGrant's sc IS its atom).  PURE, so a
//    Book can assert a disk-GRAFTED pier reconstructs to the exact same entry a SEALED one stashed —
//     the proof that grafted piers are stash-worthy without touching the House-global live guard.
Swarm_pier_entry(pier):
    let peer = pier.o({ Peering: 1 })[0]
    let page = { prepub: pier.sc.pub, pub: peer?.sc?.pub, friendly: pier.sc.friendly }
    let grants = pier.o({ Grant: 1 }).map(g => grant_of_C(g))
    let nots = pier.o({ NotGrant: 1 }).map(a => ({ not: a.sc.NotGrant, by: a.sc.by, for: a.sc.for, time: a.sc.time, sign: a.sc.sign }))
    return { page: page, grants: grants, nots: nots }

// Swarm_restash_piers — mirror an identity's LIVE %Pier children into the Dexie stash.  The
//  convergence half of Swarm_piers_rehydrate: reconstruct each pier's entry and hand it to the
//   (idempotent, live-self-guarded) Swarm_pier_stash, so a grafted friend is remembered exactly as a
//    sealed one is.  Returns the count mirrored.
Swarm_restash_piers(ident):
    let peering = this.Swarm_peering(ident)
    if (!peering) return 0
    let n = 0
    for (const pier of peering.o({ Pier: 1 })) {
        let e = this.Swarm_pier_entry(pier)
        this.Swarm_pier_stash(ident, e.page, e.grants, e.nots)
        n = n + 1
    }
    return n

//#region suggestion — "you'd love this": durable, store-and-forward, async to their being online
//  A %Suggest is a REFERRING particle (enid + display scalars + note — never a second %Record)
//   living under the friendship %Pier on BOTH sides and in the pier stash (reload-proof).
//    Delivery: best-effort NOW over the booked lane, then RE-OFFERED every time the friend's
//     rebirth greeting arrives (their standup his us), until their suggest_got retires it —
//      so a suggestion made at midnight lands when they surface at noon, no queue ceremony.
//       The far side resolves the enid against the share's mirror crate (usually already
//        there — the husk cast precedes it) and ▶ auditions at once.

// mint + stash + first send.  rec = a standing %Record (mine or a mirror's); note optional.
Swarm_suggest(w, ident, prepub, rec, note):
    if (!rec?.sc?.id || !prepub) return false
    let pier = this.Swarm_peering(ident)?.o({ Pier: 1, pub: String(prepub) })[0]
    if (!pier) return false
    let sug = pier.oai({ Suggest: 1, id: String(rec.sc.id), by: String(ident.sc.prepub) })
    sug.c.up = pier
    if (rec.sc.title) sug.sc.title = String(rec.sc.title).split(',').join(' ·')
    if (rec.sc.artist) sug.sc.artist = String(rec.sc.artist).split(',').join(' ·')
    if (note) sug.sc.note = String(note).split(',').join(' ·').slice(0, 80)
    sug.bump()
    this.Swarm_suggest_stash(ident, String(prepub), sug)
    this.Swarm_suggest_send(w, ident, String(prepub), sug)
    return true

// RELIABILITY (2026-07-29 audit — see Peeroleum_send's FRAME RELIABILITY POLICY): suggest/suggest_got are
//  RELIABLE, NOT ephemeral gossip, and deliberately so.  Unlike pulse/ive_got/repli_want they are NOT re-sent
//   every beat — a suggest fires on the user's act and is re-offered ONLY when the friend's rebirth greeting
//    arrives (Swarm_suggest_resend off Swarm_heard_hi), bounded to the un-`got` set (stash-capped at 24/friend),
//     and retired the moment suggest_got lands (`sug.sc.got`).  A delivered suggest's emit is acked-then-culled
//      like any app data; only an UNdelivered one (stalled peer) leaves an emit, and at most ~24 — nowhere near
//       the outbox cliff, and the structural backstop caps even that.  It NEEDS in-session redelivery (a drop to
//        an already-connected friend must resend before the next reconnect — that is the transport emit's job),
//         so making it ephemeral would silently lose suggestions.  Durable store-and-forward = reliable.
Swarm_suggest_send(w, ident, prepub, sug):
    if (sug.sc.got) return false
    let body = { kind: 'suggest', page: this.Swarm_page(ident), id: String(sug.sc.id) }
    if (sug.sc.title) body.title = String(sug.sc.title)
    if (sug.sc.artist) body.artist = String(sug.sc.artist)
    if (sug.sc.note) body.note = String(sug.sc.note)
    return this.Swarm_deliver(w, ident, prepub, body)

// re-offer everything they haven't confirmed — called when their hi says they're here.
Swarm_suggest_resend(w, ident, prepub):
    let pier = this.Swarm_peering(ident)?.o({ Pier: 1, pub: String(prepub) })[0]
    if (!pier) return 0
    let sent = 0
    for (const sug of pier.o({ Suggest: 1, by: String(ident.sc.prepub) })) {
        if (sug.sc.got) continue
        if (this.Swarm_suggest_send(w, ident, String(prepub), sug)) sent = sent + 1
    }
    return sent

// hear a suggestion: sealed friends only (a stranger's is a %rebuff, nothing lands).  Mint
//  the same referring shape under MY pier for them, stash it, confirm with suggest_got.
Swarm_suggested(w, ident, frame):
    let from = frame.page?.prepub
    let pier = from ? this.Swarm_peering(ident)?.o({ Pier: 1, pub: String(from) })[0] : null
    if (!pier) {
        this.Swarm_rebuff(ident, 'suggest_stranger', from)
        return
    }
    if (!frame.id) return
    let sug = pier.oai({ Suggest: 1, id: String(frame.id), by: String(from) })
    sug.c.up = pier
    if (frame.title && !sug.sc.title) sug.sc.title = String(frame.title).split(',').join(' ·')
    if (frame.artist && !sug.sc.artist) sug.sc.artist = String(frame.artist).split(',').join(' ·')
    if (frame.note && !sug.sc.note) sug.sc.note = String(frame.note).split(',').join(' ·').slice(0, 80)
    sug.bump()
    this.Swarm_suggest_stash(ident, String(from), sug)
    this.Swarm_deliver(w, ident, String(from), { kind: 'suggest_got', page: this.Swarm_page(ident), id: String(frame.id) })

// hear the confirmation: MY suggestion reached them — retire the re-offer, keep the memory.
Swarm_suggest_got(w, ident, frame):
    let from = frame.page?.prepub
    let pier = from ? this.Swarm_peering(ident)?.o({ Pier: 1, pub: String(from) })[0] : null
    if (!pier || !frame.id) return
    let sug = pier.o({ Suggest: 1, id: String(frame.id), by: String(ident.sc.prepub) })[0]
    if (!sug) return
    sug.sc.got = 1
    sug.bump()
    this.Swarm_suggest_stash(ident, String(from), sug)

// the durable lane beside grants/nots in the pier stash: keyed (id, by), capped, got carried.
Swarm_suggest_stash(ident, prepub, sug):
    let live = this.Swarm_live_self ? this.Swarm_live_self() : null
    if (!live || live !== ident) return
    let st = this.top_House().stashed
    if (!st) return
    if (!st.Swarm_piers) st.Swarm_piers = {}
    let mine = st.Swarm_piers[ident.sc.prepub]
    if (!mine) { mine = {}; st.Swarm_piers[ident.sc.prepub] = mine }
    let e = mine[prepub]
    if (!e) { e = { page: { prepub: prepub }, grants: [], nots: [] }; mine[prepub] = e }
    if (!e.suggests) e.suggests = []
    let row = { id: String(sug.sc.id), by: String(sug.sc.by) }
    if (sug.sc.title) row.title = String(sug.sc.title)
    if (sug.sc.artist) row.artist = String(sug.sc.artist)
    if (sug.sc.note) row.note = String(sug.sc.note)
    if (sug.sc.got) row.got = 1
    let kept = []
    for (const r of e.suggests) {
        if (!(r.id === row.id && r.by === row.by)) kept.push(r)
    }
    kept.push(row)
    e.suggests = kept.slice(-24)
//#endregion

//#region ive got — the reachable-music tally (Radio_todo §9.1c)
//  After the seal a friendship should COUNT: each side offers a tiny collection summary — counts,
//   never Records — as an ADDITIVE ive_got frame on the same wire as the handshake. It lands under
//    MY %Pier for them as %IveGot,by,count facts, and the tally folds my shelf plus every live
//     friend's last boast into ONE number a face can show (a Pier with music is a BIGGER cell).
//      The full tree stays a DELIBERATE pull (§9.2 Selections) — the tally is the appetite for it.

// Swarm_music_census — count MY OWN shelf in w: the %MusuSelf,pub:<my prepub> / stock home
//  (Radio_spec §2.2 rung 3 — was %Library,pier:; keyed by WHOSE it is, a key not a nickname, so live
//   and Book read the same). records = every %Record; artists = distinct sc.artist. No home counts
//    zero — an honest empty shelf, never an error.
Swarm_music_census(w, ident):
    let records = 0
    let artists = new Set()
    // opt-in census world (w.c.census_w — the live share points it at the RADIO world, where
    //  the stoker actually shelves): unset = census w itself, the Book behaviour, unchanged.
    let cw = w.c.census_w || w
    for (const home of cw.o({ MusuSelf: 1, pub: ident.sc.prepub })) {
        for (const shelf of home.o({ stock: 1 })) {
            for (const r of this.Ra_recs(shelf)) {
                records = records + 1
                if (r.sc.artist) artists.add(r.sc.artist)
            }
        }
    }
    return { records: records, artists: artists.size }

// Swarm_pulse_all — the PRESENCE heartbeat: one tiny 'pulse' frame to every sealed pier, so the
//  far side's heard_at stays warm while we live (the hear funnel stamps it — pulse carries no
//   payload beyond the page and asks nothing).  A reloaded|closed tab stops pulsing and its dot
//    dims in every friend's glass within the liveness window.  Best-effort, returns pulses sent;
//     the caller paces it (the Sounditron trickle: every ~5s on a live page, never in a Book).
Swarm_pulse_all(w, ident):
    let sent = 0
    for (const pier of this.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []) {
        if (this.Swarm_deliver(w, ident, pier.sc.pub, { kind: 'pulse', page: this.Swarm_page(ident) })) sent = sent + 1
        // self-heal: a friend we haven't heard for a while gets the rebirth greeting too —
        //  ephemeral, collision-immune, so it lands even when the booked lane is muted (their
        //   stale inbox history, our stale one, either way the hi exchange resets the stream).
        //    throttled (the human 2026-07-30, "ive_got gossip flood"): heard_at is stamped only by
        //     swarm-protocol frames (pulse/hi/ive_got/…), never by bulk repli_page/repli_lines traffic —
        //      so a heavy pull can leave swarm frames queued behind bulk data for its whole duration,
        //       `quiet` stays true continuously, and this self-heal used to re-fire every ~5s trickle
        //        tick for as long as that lasted, each kick answered by a full `Swarm_gossip_music`
        //         reply on the far end (Swarm_heard_hi) — traffic added exactly when the wire is already
        //          stressed, and the likely source of the flood-driven ws 1006 storm during a big keep.
        //           one kick per staleness episode, not per tick: cool down on the same 15s clock.
        let quiet = !pier.c.heard_at || (Date.now() - pier.c.heard_at) > 15000
        let cooled = !pier.c.hi_kick_at || (Date.now() - pier.c.hi_kick_at) > 15000
        if (quiet && cooled && w.c.station_up) {
            pier.c.hi_kick_at = Date.now()
            this.Swarm_hi_one(w, ident, String(pier.sc.pub), 0)
        }
    }
    return sent

// Swarm_gossip_music — the deliberate boast: census my shelf and tell every LIVE sealed friend
//  (a revoked Pier hears nothing — the grant gates the gossip). Unsigned v1: the frame rides an
//   authenticated link already (Books: the mail|mock wire; live: the hello-bound station) and a
//    boast is advisory — nothing grants off it. Best-effort: returns how many friends heard.
Swarm_gossip_music(w, ident):
    let counts = this.Swarm_music_census(w, ident)
    let told = 0
    for (const pier of this.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []) {
        if (!this.Swarm_pier_live(pier, 'Music')) continue
        let frame = { kind: 'ive_got', page: this.Swarm_page(ident), records: counts.records, artists: counts.artists }
        if (this.Swarm_deliver(w, ident, pier.sc.pub, frame)) told = told + 1
    }
    return told

// Swarm_ive_got — hear a boast: facts land ONLY under an already-sealed %Pier for the boaster.
//  A stranger's boast is a %rebuff and nothing else — no fact, no Pier: gossip never opens a door.
Swarm_ive_got(w, ident, frame):
    let pier = this.Swarm_peering(ident)?.o({ Pier: 1, pub: frame.page?.prepub })[0]
    if (!pier) {
        this.Swarm_rebuff(ident, 'ive_got_stranger', frame.page?.prepub)
        return null
    }
    this.Swarm_ive_got_fact(pier, 'records', frame.records)
    this.Swarm_ive_got_fact(pier, 'artists', frame.artists)
    return pier

// Swarm_ive_got_fact — one %IveGot,by,count fact, updated IN PLACE (oai finds by the by: key —
//  a fresh boast replaces the count, never a second fact).
Swarm_ive_got_fact(pier, by, count):
    let fact = pier.oai({ IveGot: 1, by: by })
    fact.c.up = pier
    fact.sc.count = String(count ?? 0)
    fact.bump()
    return fact

// Swarm_ive_got_tally — the number a face shows: my shelf plus every live friend's last boast.
//  Artists sum naively (counts cannot dedup across shelves) — a REACHABLE tally, not a union.
Swarm_ive_got_tally(w, ident):
    let own = this.Swarm_music_census(w, ident)
    let records = own.records
    let artists = own.artists
    let piers = 0
    for (const pier of this.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []) {
        if (!this.Swarm_pier_live(pier, 'Music')) continue
        let fact = pier.o({ IveGot: 1, by: 'records' })[0]
        if (!fact) continue
        piers = piers + 1
        records = records + Number(fact.sc.count || 0)
        artists = artists + Number(pier.o({ IveGot: 1, by: 'artists' })[0]?.sc?.count || 0)
    }
    return { records: records, artists: artists, piers: piers }
//#endregion

//#region share — the STANDING music session: what a friendship is FOR
//  After the seal the music must actually MOVE: my stock is served to every Music-granted
//   friend, and their casts fill per-friend %MusuThem crates in the RADIO world — the crates
//    the Riffle browses and the radio's pool dial draws from.  Every wire below is the proven
//     Repli machinery (the Radiation Books); this region is only the LIVE glue: arm, enroll,
//      offer, pump.  The pump is a detached era-guarded wall-clock loop OUTSIDE the beliefs
//       mutex, entering the machine through post_do (the carrier's own seam) so a beat never
//        overlaps a think and never awaits unbounded inside one.

// Swarm_share_granted — the Repli consent hook: the requester holds a LIVE Music grant on my
//  page (tombstones override — Swarm_pier_live checks at use, never cached).
Swarm_share_granted(peer):
    let me = this.Swarm_live_self ? this.Swarm_live_self() : null
    let p = me ? this.Swarm_peering(me)?.o({ Pier: 1, pub: String(peer) })[0] : null
    return !!(p && this.Swarm_pier_live(p, 'Music'))

// Swarm_share_present — the pull's source-liveness hook: only want pages over wires whose
//  caster has pulsed recently (a want at silence is a permanent ra_wanted hole).
Swarm_share_present(from):
    let me = this.Swarm_live_self ? this.Swarm_live_self() : null
    let p = me ? this.Swarm_peering(me)?.o({ Pier: 1, pub: String(from) })[0] : null
    return !!(p && p.c.heard_at && (Date.now() - p.c.heard_at) < 20000)

// Swarm_share_up — idempotent: arm Repli on the station world, wire the grant gate + the
//  mirror conventions, and start the pump.  Needs the radio world standing (top.c.radio_w —
//   Stoker_ensure stamps it) for the shelves; returns false until it is, callers just re-ask.
Swarm_share_up(w, ident):
    if (!w || !ident?.sc?.prepub) return false
    if (w.c.share_up) return true
    let rw = this.top_House().c.radio_w
    if (!rw) return false
    if (typeof this.Repli_arm !== 'function') return false
    this.Repli_arm(w)
    w.c.repli_mirror_pier = String(ident.sc.prepub)   // my addr — the pull's from-address (Ra_restock_beat)
    w.c.repli_mirror_by_from = 1                       // per-friend crates, keyed by the caster
    w.c.repli_mirror_w = rw                            // crates mint in the radio world — the glass sees them
    w.c.census_w = rw                                  // the boast counts the shelf the stoker actually fills
    w.c.repli_allow = (peer) => this.Swarm_share_granted(peer)
    w.c.ra_source_live = (from) => this.Swarm_share_present(from)
    w.c.share_up = 1
    this.Swarm_share_loop(w, ident)
    return true

// the pump loop: ~600ms cadence, era-guarded (a re-up cancels the stale chain — the Radio
//  loop law), each beat a post_do so the req drains ride the mutex like a carrier delivery.
Swarm_share_loop(w, ident):
    w.c.share_era = (w.c.share_era || 0) + 1
    let era = w.c.share_era
    const tick = () => {
        if (era !== w.c.share_era || !w.c.share_up) return
        this.post_do(async () => {
            if (era !== w.c.share_era) return
            try { await this.Swarm_share_beat(w, ident) } catch (er) { this.Swarm_share_why(w, er) }
        })
        setTimeout(tick, 600)
    }
    setTimeout(tick, 600)

// Swarm_share_why — LOUD on a share-beat throw (the human 2026-07-29: "I want to KNOW what's going wrong",
//  "be fatal about insanity", "fragility!").  The beat used to swallow the error into a bare one-line warn;
//   now it prints the real error + STACK plus a size CENSUS of every collection that can silently accrue
//    dead/dropped entries without GC — so the giant one NAMES ITSELF on the throw instead of us guessing.
//     Pure diagnosis: every probe is wrapped so the census can never itself throw and mask the real error.
Swarm_share_why(w, er):
    let awaitreqs = 0
    let awaiting = 0
    let bufs = 0
    let piers = 0
    try {
        for (const pg of w.o({ Peering: 1 })) {
            for (const p of pg.o({ Pier: 1 })) {
                piers = piers + 1
                try { awaitreqs = awaitreqs + p.o({ req: 'awaitbuf' }).length } catch (e) {}
                try { if (p.c.awaiting) awaiting = awaiting + Object.keys(p.c.awaiting).length } catch (e) {}
                try { if (p.c.bufs) bufs = bufs + Object.keys(p.c.bufs).length } catch (e) {}
            }
        }
    } catch (e) {}
    let wanted = 0
    let wantts = 0
    try { if (w.c.ra_wanted) wanted = Object.keys(w.c.ra_wanted).length } catch (e) {}
    try { if (w.c.ra_want_ts) wantts = Object.keys(w.c.ra_want_ts).length } catch (e) {}
    let mirrecs = 0
    let pcmpages = 0
    let chunks = 0
    try {
        let rw = this.top_House().c.radio_w || w
        for (const home of rw.o({ MusuThem: 1 })) {
            try {
                let shelf = this.Ra_home_them(rw, String(home.sc.pub))
                for (const rec of this.Ra_recs(shelf)) {
                    mirrecs = mirrecs + 1
                    try { if (rec.c.pages) pcmpages = pcmpages + rec.c.pages.length } catch (e) {}
                    try { chunks = chunks + rec.o({ seq: 1 }).length } catch (e) {}
                }
            } catch (e) {}
        }
    } catch (e) {}
    let census = 'piers=' + piers + ' awaitbuf_reqs=' + awaitreqs + ' awaiting=' + awaiting + ' bufs=' + bufs + ' ra_wanted=' + wanted + ' ra_want_ts=' + wantts + ' mirror_recs=' + mirrecs + ' pcm_pages=' + pcmpages + ' chunks=' + chunks
    console.error('⨳ SHARE BEAT THREW —', (er && er.message) || er, '\n  census:', census, '\n  stack:', (er && er.stack) || '(no stack)')

// one beat, all idempotent + bounded: enroll every granted friend both ways, husk-offer my
//  stock when it (or the peer's incarnation) changed, drain the Peering reqs (awaitbufs +
//   parked wants), feed the transcoder, and keep every friend crate's previews warming.
async Swarm_share_beat(w, ident):
    let rw = this.top_House().c.radio_w
    if (!rw) return
    let me = String(ident.sc.prepub)
    let stock = this.Ra_home_self(rw, me)
    for (const p of this.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []) {
        if (!p.sc.pub) continue
        if (!this.Swarm_pier_live(p, 'Music')) continue
        let pub = String(p.sc.pub)
        // never treat my OWN Pier as a friend: a self-offer echoes back and Repli_mirror_lib would mint a
        //  spurious %MusuThem,pub:<me> right beside my %MusuSelf — the self-mirror the human saw on Righto.
        if (pub === me) continue
        let route = this.Swarm_station_pier(w, ident, pub)
        if (!route) continue
        if (!route.c.repli_src) this.Repli_register_caster(w, route, stock)
        if (!route.c.repli_rx) this.Repli_register_rx(w, route)
        // OFFER on change: stock grew, or the peer was reborn (offered_mark carries both).
        //  Presence-gated — husking at silence is litter.  Repli_merge dedups the far side,
        //   so a re-offer after rebirth is safe, just not free.  The unit is the MAG (the wire
        //    cut, Mag_todo §4.1): the whole shuffle Mag crosses as ONE husk fragment, so the
        //     friend's mirror wears the same paged shape — a collection arrives as its rooms.
        if (!p.c.heard_at || (Date.now() - p.c.heard_at) >= 20000) continue
        let n = this.Ra_recs(stock).length
        let mark = String(w.c.station_era || 0) + ':' + String(route.c.peer_era || 0) + ':' + n
        if (route.c.offered_mark !== mark) {
            route.c.offered_mark = mark
            await this.Ra_offer_stock(w, route, me, pub, stock)
        }
    }
    for (const peering of w.o({ Peering: 1 })) await peering.do()
    if (typeof this.Ra_transcode_pump === 'function') await this.Ra_transcode_pump(w)
    for (const home of rw.o({ MusuThem: 1 })) {
        if (!home.sc.pub) continue
        let shelf = this.Ra_home_them(rw, String(home.sc.pub))
        // the §5 warm start FIRST (2 records × their opening page — autostart-ready fast),
        //  then the restock deepens whole previews behind it.
        await this.Ra_mag_warm(w, shelf)
        await this.Ra_restock_beat(w, shelf, 2)
    }
    // ── the FULL-LENGTH leg: the radio is playing a FRIEND's record — keep the wire ahead of
    //  the REAL playhead (never the Books' simulated cursor: Ra_term_stream_beat advances its
    //   own head, and a second playhead racing the AudioContext would lie).  Want the next
    //    missing pages inside a ~32s ahead-window from the radio's live position; an ask past
    //     the preview PARKS at the caster and ignites its transcode (served back by its own
    //      Ra_transcode_pump as the chunks land).  Want-once rides ra_wanted — cleared by the
    //       rebirth reset like every other pull, so a lost want is re-askable.
    let radio = rw.o({ Radio: 1 })[0]
    let playing = radio ? radio.c.rec : null
    if (playing && playing.c.from && playing.c.rx && playing.sc.id) {
        let seg_s = +(playing.sc.seg_secs || 2)
        let head = Math.floor((+(radio.sc.at || 0)) / seg_s)
        let total = +(playing.sc.total || 0)
        let PAGE = +(w.c.repli_page || 2)
        let map = this.Ra_chunk_map(playing)
        w.c.ra_wanted = w.c.ra_wanted || {}
        w.c.ra_want_ts = w.c.ra_want_ts || {}
        let nowms = Date.now()
        let asked = 0
        let off = head - (head % PAGE)
        while (off < total && off < head + 16 && asked < 3) {
            if (map[off] == null) {
                let key = String(playing.sc.id) + ':' + off
                // RE-ASKABLE live-window want (the starve fix, the human 2026-07-28 "both go into 'the
                //  next piece hasn't arrived' mode after a little while"): a want lost to the wire (a
                //   dropped reply, a reused-seq inbox collision — the Peeroleum hazards) used to be
                //    re-askable ONLY on a full peer rebirth, so ONE lost page starved the live playhead
                //     until reconnect — a hole that never clears.  Re-ask a still-missing live-window
                //      page every 4s (bounded by asked<3/beat + the head+16 window), so a lost page
                //       self-heals in a few seconds instead of dropping the audio.  ra_want_ts carries
                //        the last-ask stamp beside the once-cursor; both clear on the same rebirth reset.
                let last = w.c.ra_want_ts[key] || 0
                if (nowms - last > 4000) {
                    w.c.ra_want_ts[key] = nowms
                    w.c.ra_wanted[key] = 1
                    await this.Repli_want_next(w, playing.c.rx, me, String(playing.c.from), String(playing.sc.id), 'opus', off)
                    asked = asked + 1
                }
            }
            off = off + PAGE
        }
    }
    // the ⇊ heist gesture's follow-through rides the same beat (the human 2026-07-28): serve friends'
    //  folder-describe asks, and carry my own %Keeps wanted→choosing→committing→done (pull the chosen
    //   tracks into the collection).  Cheap when no keep stands; the routes it needs were registered above.
    //   Guarded (the Ra_transcode_pump idiom) AND try-wrapped so a heist bug can NEVER break the radio
    //    share beat — the keep driver is additive follow-through, never a dependency of the share itself.
    if (typeof this.Heist_keep_beat === 'function') {
        try { await this.Heist_keep_beat(w, ident) } catch (er) { w.c.heist_beat_why = '' + (er && er.message || er) }
    }
//#endregion

//#region revocation — the only way a grant ends (§6.4)

// Swarm_revoke — unfriending: a signed %NotGrant kept under the Pier it revokes (grants are
//  infinite — never an expiry). The Pier RETIRES at use (Swarm_pier_live), it is not deleted:
//   the durable memory keeps its history.
async Swarm_revoke(w, ident, pier, feature):
    let theirPub = pier.o({ Peering: 1 })[0]?.sc?.pub
    let atom = await mint_revoke(ident.c.keys, theirPub, feature, {}, this.Swarm_now(w))
    // the tombstone goes durable IMMEDIATELY (pier.sc.pub = their prepub, the stash key) —
    //  a revoke that a reload could forget would re-grant on rehydrate.
    this.Swarm_pier_stash(ident, { prepub: pier.sc.pub }, null, [atom])
    return pier.i({ NotGrant: atom.not, by: atom.by, for: atom.for, time: atom.time, sign: atom.sign })

// Swarm_pier_live — a Pier stands iff its Feature grants are present and NO matching %NotGrant
//  (same ability + by + for) overrides any of them — checked at use, never cached.
Swarm_pier_live(pier, feature):
    let grants = pier.o({ Grant: feature })
    if (!grants.length) return false
    let nots = pier.o({ NotGrant: feature })
    return !nots.some(n => grants.some(g => n.sc.by === g.sc.by && n.sc.for === g.sc.for))
//#endregion

//#region portability — export | import (§4 pt 3: the "copy their snap in|out", thawEnteredStashed reborn)
//  The account's PORTABLE form is its C-snap — one blob that is the backup, the device-move, and the
//   shareable contact, depending on what you point it at. A JSON envelope {v, kind, snap} rides over
//    the enWaft snap.  An `account` snap carries its keypair INLINE (two hex sc scalars on the Identity
//     root) — the owner-local .jamsend law means the backup must be self-sufficient; a `page`/`contact`
//      carries pub-only, so a shared face never leaks a key.  See Swarm_export for the live-node guard.

// Swarm_protocol — the SWARM_PROTOCOL rule set (§6.5): the Swarm vocabulary with session keys
//  omitted (online is the relay's truth, never the snap's), wire husks and rebuffs skipped.
//   kind 'page' additionally SKIPS %Pier + %Idzeug + %SocialGraph — the shareable face is the
//    Peering's OWN fields; the contact list, the spend ledger, and the graph are private.
//  GOTCHA — skip rules must match by sc_has presence, NOT entry.mk: lematch (which decides skip)
//   doesn't know mk and reads such entries as match-ALL (matches(undefined) is vacuously true) —
//    an mk-keyed skip rule skips the whole tree to an empty snap. mk entries stay fine for
//     omit_sc/blockquote means (enLine's own collector is mk-aware). Mainkeys are exclusive, so
//      an sc_has presence probe on the mainkey IS an mk match.
Swarm_protocol(kind):
    let SESSION = { online: 1, active: 1, created_at: 1, new: 1, not_found: 1, stolen: 1, address: 1, role: 1 }
    let skips = ['mail', 'rebuff', 'Sibling', 'Stolen']
    if (kind === 'page') skips = [...skips, 'Pier', 'Idzeug', 'SocialGraph']
    let rules = []
    for (const mk of ['Account', 'Identity', 'Peering', 'Pier', 'Grant', 'NotGrant', 'Idzeug', 'SocialGraph', 'Edge', 'cap']) {
        if (!skips.includes(mk)) rules.push({ matching_any: [{ mk: mk }], means: { omit_sc: SESSION } })
    }
    for (const mk of skips) {
        let probe = {}
        probe[mk] = 1
        rules.push({ matching_any: [{ sc_has: probe }], means: { skip: 1 } })
    }
    return rules

// Swarm_export — a subtree as ONE pasteable blob. The root's mainkey names the kind: an %Identity
//  is an `account`, a %Pier a `contact`, a %Peering a `page` (pruned). An account export IS the
//   private backup, so its keypair rides IN THE SNAP (§ owner-local .jamsend law — the human 2026-07-27:
//    "Swarm_(ex|im)port doesn't need to env.keys — just put them in the snap"): two hex sc scalars on
//     the Identity root line, no sidecar field, so the blob is self-sufficient.  Guard it like the key
//      it carries.  (Every LIVE node still keeps "keys ride .c only": Swarm_page is hand-built pub-only
//       so no wire frame carries the key, and the embed is export-only — import thaws + strips it back.)
async Swarm_export(n, opt):
    let mk = Object.keys(n.sc)[0]
    let kind = mk === 'Identity' ? 'account' : (mk === 'Pier' ? 'contact' : 'page')
    let out = await this.enWaft(n, { matching: this.Swarm_protocol(kind) })
    if (out.errors?.length) throw 'Swarm_export: ' + out.errors.join('; ')
    let snap = out.snap
    if (mk === 'Identity' && n.c.keys) snap = this.Swarm_snap_keyed(snap, n.c.keys)
    return JSON.stringify({ v: '1', kind: kind, snap: snap })

// Swarm_snap_keyed — fold the keypair onto the account snap's Identity ROOT line as two sc scalars.
//  pub/key are pure hex (no encode/escape hazard), so a plain line-append round-trips through
//   decode_wh_lines as sc.  Exactly one Identity roots an account export; a missing root is a mint
//    bug, not furniture, so it throws rather than silently dropping the key.
Swarm_snap_keyed(snap, keys):
    let lines = snap.split('\n')
    let at = lines.findIndex(l => /^\s*Identity:/.test(l))
    if (at < 0) throw 'Swarm_export: account snap has no Identity root to key'
    lines[at] = lines[at] + ',pub:' + keys.pub + ',key:' + keys.key
    return lines.join('\n')

// Swarm_import — paste a blob, get particles: decode the snap and GRAFT it into `container`,
//  idempotently.  An account snap carries its keypair inline; import THAWS it back onto .c.keys and
//   STRIPS the two scalars off sc, so the live node keeps the "keys ride .c only" invariant — only
//    the on-disk/transit snap ever bore them.
Swarm_import(container, blob):
    let env = JSON.parse(blob)
    let got = this.decode_wh_lines(env.snap)
    if (!got.C) throw 'Swarm_import: ' + (got.errors?.join('; ') || 'bad snap')
    let n = this.Swarm_graft(container, got.C)
    if (n.sc.pub && n.sc.key) {
        n.c.keys = { pub: n.sc.pub, key: n.sc.key }
        n.sc.prepub = String(n.sc.pub).slice(0, 16)
        delete n.sc.pub
        delete n.sc.key
    }
    return n

// Swarm_graft — fold a DECODED subtree into a live parent. Each node is found by its mainkey +
//  IDENTITY KEYS (the table below) so a re-import MERGES onto the twin instead of duplicating;
//   an unknown mainkey falls back to whole-sc match (exact re-import still merges). A fresh node
//    is created with the node's FULL sc in one i() — key order survives, so export→import→export
//     is byte-identical.
Swarm_graft(parent, node):
    let ID = { Identity: [], Peering: ['name'], Pier: ['pub'], Grant: ['sign'], NotGrant: ['sign'], Idzeug: [], SocialGraph: [], Edge: ['a', 'b'], Account: ['of'] }
    let mk = Object.keys(node.sc)[0]
    let find = {}
    find[mk] = node.sc[mk]
    for (const k of (ID[mk] ?? Object.keys(node.sc).slice(1))) find[k] = node.sc[k]
    let twin = parent.o(find)[0]
    if (twin) {
        for (const k of Object.keys(node.sc)) twin.sc[k] = node.sc[k]
        twin.bump()
    } else {
        twin = parent.i({ ...node.sc })
    }
    twin.c.up = parent
    for (const child of node.o()) this.Swarm_graft(twin, child)
    return twin

// ── the .jamsend disk homes (§5 boot ladder — owner-local) ─────────────────────────────────────
//  Two homes under the share's private corner (Heist_meta_dir = '.jamsend').  Everyone uses the SAME
//   FSA point (the human 2026-07-27), so the <prepub> path segment is what keeps two owners apart —
//    no per-device root.  `root` is the durable collection ('' = the share root); a Book passes its
//     marrauding root so its writes sweep with the run.
Swarm_account_dir(root, prepub):
    return (root || '') + '/.jamsend/account/' + prepub
Swarm_roster_dir(root):
    return (root || '') + '/.jamsend/identities'

// Swarm_account_save — persist the account as its export snap (keypair embedded) at
//  account/<prepub>/toc.snap.  Reuses Swarm_export whole, so the disk file IS the canonical portable
//   account — the same artifact a paste-backup carries, minus the JSON envelope — and stays Waft-editable
//    in the grid (the "editable on disk as Waft" stance).  Whole-file replace; accounts are small.
//  ⚠ LANDMINE — this writes the PRIVATE KEY in the clear to disk.  It is safe ONLY while THREE
//   invariants all hold (owner-local .jamsend law): (1) `.jamsend` is never peer-readable; (2)
//    `Crate_nav_paths` returns AUDIO files only, so a share walk never surfaces this toc.snap; (3)
//     Repli replicates C PARTICLES, never raw disk files.  Break any one — a non-audio return, a
//      peer-readable share, a raw-file cast — and this key LEAKS.  A change to Crate/Repli/share-scope
//       MUST revisit key-at-rest (encrypt, or move the key back to Dexie-only).
async Swarm_account_save(nav, root, ident):
    if (!nav || !ident?.c?.keys) return null
    let env = JSON.parse(await this.Swarm_export(ident))
    await nav.write_file(this.Swarm_account_dir(root, ident.sc.prepub), 'toc.snap', env.snap)
    return env.snap

// Swarm_account_load — read account/<prepub>/toc.snap and Swarm_import it into `container` (thaws the
//  keypair onto .c, strips it off sc).  Returns the live %Identity able to SIGN, or null when no
//   account sits on disk OR the file is CORRUPT.  Rewraps the bare snap in the export envelope so ONE
//    import path serves both paste-restore and disk-seed.  A present-but-corrupt snap (half-written,
//     hand-mangled) makes Swarm_import THROW — caught here to null (treated as absent) so a bad file
//      degrades to a fresh mint at the boot seam rather than bricking the boot with an unhandled throw.
async Swarm_account_load(nav, root, prepub, container):
    if (!nav) return null
    let snap = null
    try { snap = await nav.read_file(this.Swarm_account_dir(root, prepub), 'toc.snap') } catch (er) { snap = null }
    if (!snap) return null
    try {
        return this.Swarm_import(container, JSON.stringify({ v: '1', kind: 'account', snap: snap }))
    } catch (er) {
        console.log('🚪 account load: corrupt snap for ' + prepub + ' — ' + String(er).slice(0, 60))
        return null
    }

// Swarm_account_list — the prepubs that have an account on disk.  The account DIRS themselves are the
//  source of truth for "who lives here" (never a cache that can drift); the roster below is only a
//   friendly-name convenience.  Empty when no share, no dir, or no dir_at (a nav without listing).
async Swarm_account_list(nav, root):
    if (!nav?.dir_at) return []
    let dl = null
    try { dl = await nav.dir_at((root || '') + '/.jamsend/account') } catch (er) { dl = null }
    if (!dl) return []
    await dl.expand()
    return dl.directories.map(d => d.name)

// Swarm_roster_open — the recognition roster as a %Waft at identities/toc.snap.  A DERIVED cache of
//  "who lives here" (one %Identity row per owner: prepub + pub + friendly + born — pub-only, NEVER a
//   key), so a fresh browser can name its owners without importing (and thawing) every account.  A
//    drift heals on the next roster_save; existence's truth is Swarm_account_list, not this.
async Swarm_roster_open(nav, root):
    let dir = this.Swarm_roster_dir(root)
    let snap = null
    try { snap = await nav.read_file(dir, 'toc.snap') } catch (er) { snap = null }
    let waft = null
    if (snap) {
        let dec = this.deWaft(snap, 'identities')
        waft = dec.Waft
    }
    if (!waft) waft = new TheC({ c: {}, sc: { Waft: 'identities' } })
    waft.c.roster_dir = dir
    return waft

// Swarm_roster_save — upsert one owner's recognition row and write the roster whole.  Pub-only by
//  construction: the roster never carries a key, so it stays safe even if the owner-local law is ever
//   relaxed for this ONE file.
async Swarm_roster_save(nav, root, ident):
    if (!nav || !ident?.c?.keys) return null
    let waft = await this.Swarm_roster_open(nav, root)
    let row = waft.oai({ Identity: ident.sc.prepub })
    row.c.up = waft
    row.sc.pub = ident.c.keys.pub
    let peering = this.Swarm_peering(ident)
    if (peering?.sc?.friendly) row.sc.friendly = peering.sc.friendly
    if (ident.sc.born) row.sc.born = ident.sc.born
    let enc = await this.enWaft(waft)
    await nav.write_file(waft.c.roster_dir, 'toc.snap', enc.snap)
    return waft

// Swarm_persist — one call to mirror an identity to BOTH homes: the account (agency, keyed) and the
//  roster row (recognition, pub-only).  The write-through seam (§4 stream rule: Dexie is the working
//   store, this throttled mirror the durable one) — a caller invokes it on a Waft:Account version bump.
async Swarm_persist(nav, root, ident):
    if (!nav || !ident?.c?.keys) return null
    await this.Swarm_account_save(nav, root, ident)
    await this.Swarm_roster_save(nav, root, ident)
    return ident

// Swarm_boot_seed — §5 step 3: a browser with NO Dexie state but a share present reads its owner(s)
//  back off disk.  Enumerate the account dirs, pick the target (`want` = a ?I= prepub if given and
//   present; else the sole account; else the first — multi-identity is ?I=-explicit, "not well
//    supported" by design, the human 2026-07-27), and load it into `container` (keys thawed, grants +
//     piers + iz ledger reborn).  Returns { ident, prepub, others } or null when disk is bare.
//   PURE by design: session activation (sc.active) and the Dexie re-mirror are the app-boot caller's
//    (Auto ensure_identity → adopt this before minting a parallel self), so a Book can prove the
//     disk→identity→signing lift without fighting the House-global active-self.  The Auto wiring is
//      the one seam whose only real proof is a live reboot (the two-tab fingers-test) — see
//       Identity_persist_todo §3.
async Swarm_boot_seed(nav, root, container, want):
    let prepubs = await this.Swarm_account_list(nav, root)
    if (!prepubs.length) return null
    // try the preferred (a ?I= want) FIRST, then the rest — so ONE corrupt|unreadable account never
    //  strands the others (Swarm_account_load returns null on a bad file, so we just fall through).
    let order = []
    if (want && prepubs.includes(want)) order.push(want)
    for (const p of prepubs) { if (p !== want) order.push(p) }
    for (const prepub of order) {
        let ident = await this.Swarm_account_load(nav, root, prepub, container)
        if (ident) return { ident: ident, prepub: prepub, others: prepubs }
    }
    return null
//#endregion

//#region places — one key, N addresses (§3: siblings, the stolen name, Steal Back)
//  The identity≠address split. `ident.sc.prepub` is the immutable key-derived NAME; a %Peering also
//   holds a session ADDRESS — bare <prepub> is the primary place, <prepub>_1 / _2 a NON-first them.
//    (name stays canonical so deliver-routing and the byte-identical export never move with a suffix.)
//  Local tabs of ONE identity are cooperative SIBLINGS — the Dexie-liveQuery "these are all our tabs"
//   roster, modeled here as %Sibling records; they split the work (one plays music, one encodes) so a
//    tab that leaks or crashes every 6 hours never takes the whole identity down. A claimant that is
//     NOT a known sibling is a THEFT: a remote copy of your key contesting your name. Steal Back
//      concedes the bare name and jumps to the next free suffix — SAME key — so your Piers still verify
//       you (a page's `pub` is the truth; the address is only where you're reachable this session).
//  All session-local: `stolen`/`address`/`role` and the %Sibling/%Stolen husks are omitted from every
//   export (Swarm_protocol) — a backup is the canonical identity, never a moment's reachability.

// Swarm_address — the session address this place currently HOLDS. Defaults to the canonical name;
//  becomes <prepub>_N after a Steal Back.
Swarm_address(ident):
    let peering = this.Swarm_peering(ident)
    return peering?.sc?.address ?? peering?.sc?.name

// Swarm_next_suffix — the next free <prepub>_N not among `taken` (the addresses we can see held). The
//  bare <prepub> is the primary; suffixes start at _1. The relay's "taken — jump to _1" done locally.
Swarm_next_suffix(prepub, taken):
    let held = new Set(taken || [])
    let n = 1
    while (held.has(prepub + '_' + n)) n = n + 1
    return prepub + '_' + n

// Swarm_sibling — record a cooperative co-holder of THIS identity: another tab/place (a row of the
//  Dexie-liveQuery roster). `place` is the tab's own token, `address` the name it holds, `role` its job.
Swarm_sibling(ident, place, address, role):
    let peering = this.Swarm_peering(ident)
    let sib = peering.oai({ Sibling: place })
    sib.c.up = peering
    if (address) sib.sc.address = address
    if (role) sib.sc.role = role
    sib.bump()
    return sib

// Swarm_is_sibling — is `place` one of our known tabs? (the cooperative-vs-theft discriminator).
Swarm_is_sibling(ident, place):
    return !!this.Swarm_peering(ident)?.o({ Sibling: place })[0]

// Swarm_take_role — this place's job among the tabs (music | encode | serve …). Only one tab plays
//  music; another encodes; the big role hands off one by one for robustness (§3).
Swarm_take_role(ident, role):
    let peering = this.Swarm_peering(ident)
    peering.sc.role = role
    peering.bump()

// Swarm_note_theft — a claimant `by` is holding our name as of `at`. A KNOWN sibling is cooperative
//  co-presence (no alarm — return false); anyone else is a THEFT: raise the page's `stolen` flag and
//   leave a durable %Stolen,by/at husk the warning banner reads. Returns true when it alarmed.
Swarm_note_theft(ident, by, at):
    if (this.Swarm_is_sibling(ident, by)) return false
    let peering = this.Swarm_peering(ident)
    peering.sc.stolen = 1
    let husk = peering.oai({ Stolen: by })
    husk.c.up = peering
    husk.sc.at = String(at ?? this.Swarm_now(H))
    husk.bump()
    peering.bump()
    return true

// Swarm_stolen — is our name currently contested by an unrecognized place? (the banner's gate).
Swarm_stolen(ident):
    return !!this.Swarm_peering(ident)?.sc?.stolen

// Swarm_steal_back — concede the contested name and re-present at the next free suffix, SAME key.
//  `taken` is every address we can see held (the thief's + our siblings'); we jump past all of them,
//   clear the alarm, and return the new address. The re-hello/re-advertise under it is the caller's
//    next move — the %Stolen husk stays as history.
Swarm_steal_back(ident, taken):
    let peering = this.Swarm_peering(ident)
    let addr = this.Swarm_next_suffix(ident.sc.prepub, taken)
    peering.sc.address = addr
    delete peering.sc.stolen
    peering.bump()
    return addr
//#endregion
