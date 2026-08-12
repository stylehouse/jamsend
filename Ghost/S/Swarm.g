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
//  NULL-SAFE IN THE ARGUMENT, not just the result (2026-08-04).  Every caller already treats a missing
//   peering as ordinary — `Swarm_address` reads `peering?.sc`, `Swarm_restash_piers` does `if (!peering)
//    return 0`, `SwarmDisk_witness` writes `Swarm_peering(x)?.o(…)` — but that `?.` guards the RETURN,
//     so an undefined `ident` still threw one frame earlier and took the whole req down.  The tell was a
//      witness that reads "each pass's settled state" being called at a beat where its subject does not
//       exist yet (SwarmDisk beat 2 asking after the beat-5 AliceReseed vault).  That is not a caller
//        bug: a not-yet-born identity HAS no page, which is exactly what undefined means here.
Swarm_peering(ident):
    return ident ? ident.o({ Peering: 1 })[0] : undefined

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
        if (!['Idzeug', 'to', 'ttl', 'chain', 'holder', 'spent', 'blotter', 'next', 'claimed'].includes(k)) params[k] = String(record.sc[k])
    }
    return params

// ── %Idzeug AS THE ISSUER (2026-08-12) ─────────────────────────────────────────────────────────
//  An %Idzeug is not an invite.  It is THE SCHEME BEHIND ONE — its class (the owner's word).  An
//   Invite is an INSTANCE: a serial drawn off an issuer, which wanders off into the world carrying
//    nothing but its number and a MAC.  Issuing winds `next`; claiming ticks a number off `claimed`.
//  This is free CRYPTOGRAPHICALLY because Swarm_presig is a deterministic MAC, not a third-party
//   signature — only the issuer's key makes it and regenerating it IS the door's check, so nothing
//    is stored in order to VERIFY.  The per-invite row was only ever doing three jobs, and the
//     issuer does all three without a row each: existence ("we issued this") becomes `i < next`;
//      the presig/grant params come off the issuer; the spend ledger is `claimed`.
//  ⚠ WHY THE RUN-LIST JOINS ON `~` AND NEVER `,`.  encode_stringies (Text.svelte:606) drops the
//   WHOLE line to a JSON blob if any value holds `, \t \n`.  `claimed:3-5,9,14` would snap as
//    {"Idzeug":"1","to":"Music","claimed":"3-5,9,14"} — legal, and it defeats the entire point of
//     this change, which is that an account file becomes readable by eye again.
//  `next` IS THE ISSUER TELL — there is no marker key.  An issuer always carries `next` (it is the
//   wound-up number, the whole point of it) and no legacy row ever can: a per-invite record wears
//    only `to`/`ttl`/`chain`/`holder`/`spent`/`blotter` + Feature params, and no Feature has a
//     `next` param.  A first cut did stamp a separate `scheme:1`, which was a marker asserting what
//      the real data already said — and it landed in every production account file for nothing.
//  Do NOT instead infer it from "the mainkey looks like a small integer": a legacy 12-hex nonce is
//   all-digits about 0.5% of the time, which across a few hundred rows is a coin-flip.  Every legacy
//    iteration filters `!sc.next`.

// Swarm_iz_issuer — find-or-create THE issuer for a Feature.  One per distinct feature+params, so a
//  plain { Music: 1 } account holds exactly one and every invite it ever issues is a number off it.
// Swarm_iz_issuer_of — the READ half: find the issuer for a Feature, or null. Split out because
//  Swarm_iz_issuer is find-or-CREATE, and a read path that calls it MINTS ONE BY ASKING. That is
//   not hypothetical: `Swarm_issued` called it, the SwarmBlotter witness calls `Swarm_issued` on
//    every pass, and an `Idzeug:1,next:1` duly appeared at beat 2 — before the sheet was
//     printed, in a Book whose whole point is when issuing happens. Read with THIS one.
Swarm_iz_issuer_of(ident, feature):
    let mainkey = Object.keys(feature)[0]
    let params = { ...feature }
    delete params[mainkey]
    let peering = this.Swarm_peering(ident)
    if (!peering) return null
    return peering.o({ Idzeug: 1, next: 1, to: mainkey, ...params })[0] || null

Swarm_iz_issuer(ident, feature):
    let mainkey = Object.keys(feature)[0]
    let params = { ...feature }
    delete params[mainkey]
    let peering = this.Swarm_peering(ident)
    let found = peering.o({ Idzeug: 1, next: 1, to: mainkey, ...params })[0]
    if (found) return found
    let z = 1
    for (const s of peering.o({ Idzeug: 1, next: 1 })) {
        let v = +(s.sc.Idzeug || 0)
        if (v >= z) z = v + 1
    }
    let iz = peering.i({ Idzeug: String(z), to: mainkey, ...params })
    iz.c.up = peering
    iz.sc.next = '1'
    // the durable twin is born WITH its `next` — Swarm_iz_rehydrate keys off `c.next` to know an
    //  issuer from a legacy row, so an issuer stashed without it would rehydrate as a one-shot
    //   invite and every serial ever drawn off it would refuse `unknown` after a reload.
    this.Swarm_iz_stash(ident, String(z), { to: mainkey, ...params, next: '1' })
    return iz

// Swarm_iz_wire / Swarm_iz_find — the two spellings of a serial.  THE PRESIG SIGNS THE CANONICAL
//  `z.i` ALWAYS; the wire omits a leading `1.` because issuer 1 is the overwhelming case and a QR
//   is smaller for it.  Sign the WIRE form instead and the day some path emits the long form for
//    z=1, every such invite dies `forged` — one crypto domain, one spelling.
Swarm_iz_wire(z, i):
    if (+z === 1) return String(i)
    return String(z) + '.' + String(i)

// Swarm_iz_find — resolve a carried serial to what the door needs: { canon, to, params } plus either
//  the legacy `record` or the `iz` issuer + its `i`.  Null = we never issued this.
//  ⚠ LEGACY IS TRIED FIRST, and that order is load-bearing.  An old 12-hex nonce can be all digits,
//   which would otherwise parse as serial-form `i=123456789012`, miss the issuer's `next`, and
//    refuse an invite we really did issue.  An existing row always wins; only an unmatched serial
//     falls through to the issuer arithmetic.  277 of the owner's 279 legacy rows are still
//      outstanding in the world, so this path is not a transitional courtesy — it is the door.
Swarm_iz_find(ident, serial):
    let peering = this.Swarm_peering(ident)
    let s = String(serial)
    let legacy = peering.o({ Idzeug: s })[0]
    if (legacy && !legacy.sc.next) {
        return { kind: 'legacy', record: legacy, canon: s, to: String(legacy.sc.to), params: this.Swarm_record_params(legacy) }
    }
    if (!/^(\d+\.)?\d+$/.test(s)) return null
    let dot = s.indexOf('.')
    let z = dot < 0 ? 1 : +s.slice(0, dot)
    let i = dot < 0 ? +s : +s.slice(dot + 1)
    if (!(i >= 1)) return null
    let iz = peering.o({ Idzeug: String(z), next: 1 })[0]
    if (!iz) return null
    if (i >= +(iz.sc.next || 1)) return null
    return { kind: 'serial', iz: iz, i: i, canon: String(z) + '.' + String(i), to: String(iz.sc.to), params: this.Swarm_record_params(iz) }

// Swarm_claimed_has / Swarm_claimed_add — the run-list codec.  "3-5~9~14" means 3,4,5,9,14 claimed.
//  Expansion is bounded by invites actually issued, so the naive walk is fine and stays legible.
Swarm_claimed_has(runs, i):
    if (!runs) return 0
    for (const part of String(runs).split('~')) {
        let dash = part.indexOf('-')
        let lo = dash < 0 ? +part : +part.slice(0, dash)
        let hi = dash < 0 ? lo : +part.slice(dash + 1)
        if (i >= lo && i <= hi) return 1
    }
    return 0

Swarm_claimed_add(runs, i):
    let seen = {}
    let nums = []
    let take = (v) => { if (!seen[v]) { seen[v] = 1; nums.push(v) } }
    if (runs) {
        for (const part of String(runs).split('~')) {
            let dash = part.indexOf('-')
            let lo = dash < 0 ? +part : +part.slice(0, dash)
            let hi = dash < 0 ? lo : +part.slice(dash + 1)
            let k = lo
            while (k <= hi) { take(k); k = k + 1 }
        }
    }
    take(i)
    nums.sort((a, b) => a - b)
    let out = []
    let j = 0
    while (j < nums.length) {
        let lo = nums[j]
        let hi = lo
        while (j + 1 < nums.length && nums[j + 1] === hi + 1) { j = j + 1; hi = nums[j] }
        out.push(lo === hi ? String(lo) : (String(lo) + '-' + String(hi)))
        j = j + 1
    }
    return out.join('~')

// Swarm_iz_spent / Swarm_iz_claim — one claim, whichever shape carries it.  A legacy row spends its
//  own `spent` flag exactly as it always did; a drawn serial ticks its number off the issuer.  Both
//   land through Swarm_iz_mark, so both reach sc, Dexie AND the disk mirror.
Swarm_iz_spent(f):
    if (f.kind === 'legacy') return f.record.sc.spent ? 1 : 0
    return this.Swarm_claimed_has(f.iz.sc.claimed, f.i)

Swarm_iz_claim(ident, f):
    if (f.kind === 'legacy') return this.Swarm_iz_mark(ident, f.record, { spent: 1 })
    return this.Swarm_iz_mark(ident, f.iz, { claimed: this.Swarm_claimed_add(f.iz.sc.claimed, f.i) })

// Swarm_mint_invite — ISSUE ONE.  Wind the issuer's number, hand back the token; no particle is
//  born.  This is the shipping mint: the "invite a friend" button, and every serial on a sheet.
//   (Swarm_mint_idzeug below still mints a per-invite record — it is now the CHAIN mint only, plus
//    the Books that name their own nonces.)
async Swarm_mint_invite(w, ident, feature):
    let iz = this.Swarm_iz_issuer(ident, feature)
    let z = +(iz.sc.Idzeug || 1)
    let i = +(iz.sc.next || 1)
    let page = this.Swarm_page(ident)
    let mainkey = String(iz.sc.to)
    let params = this.Swarm_record_params(iz)
    let n = this.Swarm_token_n(mainkey, params)
    let canon = String(z) + '.' + String(i)
    let presig = await this.Swarm_presig(ident.c.keys, page.prepub, canon, n)
    this.Swarm_iz_mark(ident, iz, { next: String(i + 1) })
    return this.Swarm_token(page.prepub, this.Swarm_iz_wire(z, i), n, presig)

// Swarm_mint_idzeug — mint ONE invite that wears its OWN per-invite record, under a caller-named
//  nonce. Since 2026-08-12 this is NO LONGER the shipping mint (that is Swarm_mint_invite, which
//   draws a number off an issuer and creates no particle). Two callers remain, and both need a row:
//    • a CHAIN invite (chain:1) — its moving `holder` is the one piece of invite state a counter
//       cannot represent, so a chain always wears a record (§6.3a);
//    • the Books — fourteen of them pin a named nonce ('pol_2', 'chain_1', 'spoof_1'…) so their
//       fixtures read as prose. Deterministic names, deterministic snaps.
//  feature = { Music: 1, genre: 'Classical' } — a mainkey with params, never a bare flag. The record
//   keeps the FULL signed atom on .c.iz — the chain's lineage (§6.3a third-party verify) — while the
//    QR wears only the token; both ride .c (re-derivable — ed25519 is deterministic).
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
//  A blotter is now a RANGE MINT, not a batch of particles: wind the issuer's number past `count`
//   and hand out `count` tokens. NOTHING records the group (the owner 2026-08-12: *"the %Blotter
//    doesn't hang around at all, the Serial is simply wound past them all, and their Invites wander
//     off into the world. we have no idea they're a group, ongoingly"*). Each serial still spends
//      INDEPENDENTLY through the exact same door — a torn ticket is a one-timer ticked off `claimed`.
//  Labelling a group so a maker could still count a sheet: the owner looked at it and said *"almost
//   but not quite for v1.0"*. When it comes it is a LABEL ON A RANGE, never a resurrected %Blotter
//    with 126 members. NOTHING here is a chain (§6.3a) — a chain wears its own record, and a blotter
//     never draws one.

// Swarm_mint_blotter — issue `count` invites off the one Feature. Returns the SHEET: the ordered
//  ?Iz= tokens the printed page's QR cells carry, in serial order.
async Swarm_mint_blotter(w, ident, feature, count):
    let izzes = []
    let i = 0
    while (i < count) {
        i = i + 1
        izzes.push(await this.Swarm_mint_invite(w, ident, feature))
    }
    return izzes

// Swarm_issued — what an issuer has done, for the maker's panel: how many invites it has ever put
//  into the world and how many of those came back. NOT per-sheet — no sheet survives issuing, so
//   this is the whole account's tally for that Feature, which is the only group that still exists.
Swarm_issued(ident, feature):
    let iz = this.Swarm_iz_issuer_of(ident, feature)
    if (!iz) return { count: 0, claimed: 0 }
    let issued = +(iz.sc.next || 1) - 1
    let claimed = 0
    if (iz.sc.claimed) {
        for (const part of String(iz.sc.claimed).split('~')) {
            let dash = part.indexOf('-')
            claimed = claimed + (dash < 0 ? 1 : (+part.slice(dash + 1) - +part.slice(0, dash) + 1))
        }
    }
    return { count: issued, claimed: claimed }
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

// Swarm_invite_url — the front door itself: ISSUE one invite off `ident`'s Idzeug and dress it as
//  the URL the QR carries — <base>?Iz=<token>. Live, base = location.origin + the toplevel path (the
//   scanning phone lands on the SAME app); a Book pins it. The URL is the whole invite.
//  No `nonce` parameter any more: the issuer assigns the number (§0 2026-08-12). A caller that wants
//   a NAMED serial with its own record wants Swarm_mint_idzeug — that is now the chain mint and the
//    Books' fixture mint, not the shipping one.
async Swarm_invite_url(w, ident, feature, base):
    let iz = await this.Swarm_mint_invite(w, ident, feature)
    this.Swarm_expect_arrival(w)
    return base + '?Iz=' + encodeURIComponent(iz)

// Swarm_expect_arrival — AN INVITE MEANS "COME HERE", so minting one is the moment we start
//  expecting somebody (the owner 2026-08-09: *"the cases when we'd expect a Pier are just right
//   after an Invite… when it is essentially just saying 'come here', in a QR code"*).  That includes
//    an invite to a Pier+Grant we ALREADY hold — you can keep your invite as a link for yourself and
//     it stops minting Grants, but it is still "come here", so it still arms the expectation.
//  This is the registration law working in the right direction: Swarm owns invites, so Swarm hands
//   the watch over — Supervisor never learns what an invite is, and this whole block is a no-op on a
//    tab with no Supervisor (a bare Book, a daemon mid-boot).
//  FIVE SECONDS, the owner's number.  Long enough for a scan to land, short enough that nobody sits
//   in silence wondering; after it, whoever asks is told plainly that we gave up.
//  ARMED AT `Swarm_invite_url`, NOT AT `Swarm_mint_idzeug`, and that distinction is the whole point:
//   the URL door is the LIVE one ("here is a QR, scan it now"), while the BLOTTER mints its 126
//    serials straight off Swarm_mint_idzeug for a sheet to be printed and handed out next week.  A
//     printed sheet is not "come here", and arming there would hold the radio for five seconds every
//      time somebody prepared one.  If a refactor ever routes the blotter through this door, it must
//       NOT inherit the expectation — that is a behaviour change, not a tidy-up.
Swarm_expect_arrival(w):
    let sup = this.Supervisor_w ? this.Supervisor_w(this.top_House()) : null
    if (!sup) return
    let watch = this.Supervisor_expect(sup, 'swarm.arrival', 'someone answered your invite', 'Swarm_probe_arrival', null, 5, this.Supervisor_stage('friend'))
    // WHY we are hoping, carried for whoever has to explain the give-up.  Without it the radio's
    //  bottom rung says "nobody answered your invite" on a boot where no invite was ever minted.
    // AND WHAT TO DO ABOUT IT — the sentence a listener gets when the five seconds run out.  Its
    //  twin in Swarm_expect_friends says "no friend is online"; here somebody was explicitly invited
    //   and did not come, which is a different fact and deserves a different sentence.  Either way
    //    the second half is the same and is the point of saying anything at all: this machine plays
    //     your own music perfectly well on its own.
    if (watch) { watch.sc.because = 'invite'; watch.sc.advice = 'nobody has answered your invite yet — your own music plays in the meantime'; watch.bump() }

// Swarm_expect_joining — THE INVITEE'S HALF of "an invite means come here" (2026-08-11, the owner:
//  *"we need some way to stop the Radio starting until we finish the Invite... otherwise it starts
//   playing some other Pier who is online"*).  Swarm_expect_arrival arms the INVITER at mint; a tab
//    that LANDS on an invite armed nothing — Swarm_expect_friends bails on a newborn ("NO PIERS, NO
//     HOPE", correct for its own case), so between redeem and seal the radio was free to start on
//      whoever else happened to be live.  Armed at Swarm_redeem, the ghost-side moment a landed
//       invite is actually being spent — not at ?Iz parse (a landed token someone never joins must
//        not hold anything).
//  SAME watch key, SAME probe: the arrival IS the inviter appearing as a live pier, so the seal
//   meets it naturally.  because='joining' is what Radio_dial reads to hold EVERY rung for the
//    invitee (the inviter's 'invite' holds only the own-shelf rung — minting a QR mid-session must
//     never stop music already playing).
//  FIFTEEN seconds, not the mint-side five: join() carries an 8s relay wait and an 8s seal wait,
//   and giving up while the seal is still legal hands the radio to a stranger at the worst moment.
Swarm_expect_joining(w, prepub):
    let sup = this.Supervisor_w ? this.Supervisor_w(this.top_House()) : null
    if (!sup) return
    let watch = this.Supervisor_expect(sup, 'swarm.arrival', 'your inviter came online', 'Swarm_probe_arrival', null, 15, this.Supervisor_stage('friend'))
    if (watch) { watch.sc.because = 'joining'; watch.sc.advice = 'the invite did not finish — ask your friend for a fresh QR'; watch.bump() }

// Swarm_expect_friends — THE OTHER EVENT THAT MAKES US EXPECT SOMEBODY: our own standup, on a machine
//  that already has friends (the owner 2026-08-10, having killed Lefto to produce the case: *"this is
//   that start-playing-our-own-music situation… which happens anyway, I actually want it to WAIT, and
//    start playing local music when peer given up on"*).
//  This is still event-driven, not the ambient hoping §the-expect-header warns off: the event is THIS
//   BOOT, it fires once per standup, and it is bounded by the same five seconds.  What it is not is
//    "any stored %Pier means somebody might turn up one day" — that is the reading Radio_alone_why's
//     `anyPier` makes, and it is why that function could never be the one to decide this.
//  ARMED HERE, at the bottom of Swarm_station_up, because that is the first moment the answer is even
//   knowable: the three rehydrates at the top of that verb are what put the %Piers back, so anywhere
//    earlier we would be asking whether we have friends before we had loaded them.  It is also inside
//     the `station_up` guard, so it arms ONCE — an expectation that re-armed on every reconnect would
//      restart its own clock forever and never give up, which is the failure mode of a patience.
//  NO PIERS, NO HOPE: a machine that has never met anybody is not waiting for anyone, and holding its
//   radio for five seconds would be five seconds of silence bought with nothing.
Swarm_expect_friends(w, ident):
    let sup = this.Supervisor_w ? this.Supervisor_w(this.top_House()) : null
    if (!sup) return
    let me = String(ident?.sc?.prepub || '')
    let piers = (this.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []).filter(p => p.sc.pub && String(p.sc.pub) !== me)
    if (!piers.length) return
    // SHORT FORM (owner, 2026-08-11: *"lets get Butler to just say … friend is online vs friend came
    //  online"*).  This DELIBERATELY overrides the em-dash rule in Sounditron_supervise, which keeps a
    //   tail that says WHY the claim matters — "somebody to play radio with" was exactly such a tail.
    //    The reason it goes anyway: this row sits one line under `a friend is online`, and the pair is
    //     only legible if the difference between them is the whole sentence.  Do not restore it.
    let watch = this.Supervisor_expect(sup, 'swarm.arrival', 'a friend came online', 'Swarm_probe_arrival', null, 5, this.Supervisor_stage('friend'))
    // THE SENTENCE THE OWNER ASKED FOR, verbatim in intent (2026-08-10): *"it should also explain
    //  clearly that no friend is online and you can play local music instead… it doesn't DO anything
    //   with your local music yet, but you can listen to it of course, as its what this machine
    //    does"*.  Note the scope — WORDS, not behaviour: nothing here plays anything, and the radio's
    //     own local rung (which already runs the moment this expectation expires) is what actually
    //      makes the sound.  This only stops the give-up from being a silent nothing.
    if (watch) { watch.sc.because = 'friends'; watch.sc.advice = 'no friend is online — you can listen to your own music'; watch.bump() }

// Swarm_watch_station — the one HIGH-LEVEL task this layer owns: are we on the relay at all?  A
//  milestone, because it completes: the door opens once per boot and then stays open (a reconnect is
//   the socket's own business and never re-closes this).  It is the sentence a listener should see on
//    a loading screen — everything else this app does is downstream of it, and a tab that never gets
//     it will sit forever looking like a slow start rather than a dead relay.
Swarm_watch_station(w):
    let sup = this.Supervisor_w ? this.Supervisor_w(this.top_House()) : null
    if (!sup) return
    // SHORT FORM (owner, 2026-08-11) — same ruling as the arrival row above; "friends can reach you"
    //  was a why-tail and goes anyway, so the three presence sentences read as one set.
    // ⚠ THE ONE HONEST WORRY ABOUT THIS SENTENCE, now that it is bare present tense: it is a
    //  MILESTONE, and `w.c.station_up` is set once at the bottom of Swarm_station_up and **never
    //   cleared anywhere in this file** (checked).  So "you are online" cannot go false — if the
    //    relay drops under a live tab, this row keeps saying yes.  Fine on the Butler, which is gone
    //     by then; NOT fine on SupervisorFace, which is the after-boot surface and the one place a
    //      latched presence claim can lie to somebody.  Making it `standing` alone would not help —
    //       the probe would still read the same latch.  It needs a LIVE read (Peeroleum_carrier, the
    //        check Swarm_deliver already makes at :565) before the tense is earned.  Not done here:
    //         that is a behaviour change to the loudest row on the roster and wants its own measurement.
    this.Supervisor_watch(sup, 'swarm.station', 'you are online', 'milestone', 'Swarm_probe_station', null, this.Supervisor_stage('door'))
    this.Supervisor_dial(sup, 'swarm.piers', 'friends', 'Swarm_dial_piers', null, this.Supervisor_stage('friend'))

// Swarm_watch_repair — RE-REGISTER THE TWO STANDUP-TIME WATCHES IF THE RACE ATE THEM.
//
//  MEASURED 2026-08-12 on both live players: `arrived:arrived`, every downstream row green — and
//   `swarm.station` and `swarm.arrival` MISSING ENTIRELY (9 watches where there had been 11). The
//    station was plainly up; only its watch was gone.
//  Both register exactly once, from inside standup: `Swarm_watch_station` at the top of
//   `Swarm_station_up`, `Swarm_expect_friends` at the bottom of it. Both open with
//    `if (!sup) return` — so if the Supervisor world is not yet on Mundo at that instant, they
//     register NOTHING and are never called again, because SwarmStandup stops re-entering
//      `Swarm_station_up` once the station stands. Silent, permanent, and invisible from inside:
//       every claim those rows would have made is true, so nothing else looks wrong.
//  WHAT TIPPED IT: the come-back work of 2026-08-11 moved the share-arm to the `radio_w` stamp at
//   beat 1 (~3s) and gave SwarmStandup a 750ms wall-clock tick, so standup now finishes EARLIER and
//    started winning the race against the Supervisor world's creation. A fix upstream turned a
//     latent ordering assumption into a live one — which is the tell to look for after any change
//      that makes something happen sooner.
//  THE PATTERN IS ALREADY IN THIS FILE: `swarm.beat` registers from inside the watch loop precisely
//   so it "keeps the watch alive across a Supervisor that stood up after this loop did". These two
//    lacked that, and now borrow the same loop.
//  ⚠ GUARDED ON ABSENCE, NOT CALLED BLIND, and that is load-bearing for the arrival one.
//   `Supervisor_expect` RE-ARMS its deadline by design (it is meant for event call sites), so calling
//    it from a pass that re-runs every beat would push the deadline forward forever and the patience
//     could never expire — "a clock that resets faster than it runs is not a clock", the exact
//      failure `Supervisor_patient` exists to avoid. Asking `oa` first means the clock is armed once.
//   A tab with no piers registers nothing and re-probes each beat; that is a lookup and a filter,
//    and it is correct — the expectation only means something once there is somebody to expect.
Swarm_watch_repair(w, sup):
    if (!sup.oa({ Watch: 'swarm.station' })) this.Swarm_watch_station(w)
    if (sup.oa({ Watch: 'swarm.arrival' })) return
    let ident = this.Swarm_live_self ? this.Swarm_live_self() : null
    if (ident) this.Swarm_expect_friends(w, ident)

// Swarm_dial_piers — WE HAVE PIER, with its parts.  This reading was computed inside DoorFace and
//  thrown away at the face boundary, which is why nothing else on the machine could see it and no
//   Book could assert it.
//  THE HALF-SEAL IS THE WHOLE REASON THIS DIAL EXISTS (rule 3).  A whole %Pier holds BOTH grants —
//   ours to them and theirs to us.  When only one landed the link SILENTLY half-works: asks leave,
//    answers die on the doorstep, and both ends read as merely slow.  That cost a live evening, and
//     `runner_ask world` could see it in one line while the glass could not.  So: "2 sealed · 1
//      sealing", never one boolean.
//  PREFIX MATCH on `by`, copied from DoorFace's own note: the grant mint form-matches whichever the
//   beacon carried, so `by` rides as a prepub here and a full pub elsewhere.  A prefix compare is
//    true for both and cannot false-positive across two different keys.
//  A PURE READ — o() only, nothing minted, nothing written (rule 1).
Swarm_dial_piers(subject, sup):
    let ident = this.Swarm_live_self ? this.Swarm_live_self() : null
    if (!ident) return { state: 'unknown', reading: 'no identity yet' }
    let me = String(ident.sc.prepub || '')
    let sealed = 0
    let half = 0
    let live = 0
    let unsure = 0
    let names = []
    for (const p of this.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []) {
        if (!p.sc.pub) continue
        let them = String(p.sc.pub)
        if (me && them === me) continue
        let grants = p.o({ Grant: 1 })
        let has = who => !!who && grants.some(g => String(g.sc.by || '').startsWith(who) || who.startsWith(String(g.sc.by || '')))
        let mine_ok = has(me)
        let theirs_ok = has(them)
        if (mine_ok && theirs_ok) sealed = sealed + 1
        if (mine_ok !== theirs_ok) half = half + 1
        // "online" here means ONLINE, not "granted" — and until 2026-08-12 this line said the
        //  opposite of what it claimed.  `Swarm_pier_live` is a GRANT check (a %Grant present, no
        //   %NotGrant over it) despite the name, so it was the only POSITIVE evidence here; the
        //    presence term could merely SUBTRACT, and only on a positive "they are absent".
        //     Presence is three-valued on purpose, so `null` (nobody asked / the answer went stale /
        //      presence never armed on this machine) sailed through and every granted pier read as
        //       online.  The owner's two long-closed incognito tabs sat in this roster as friends
        //        who were here, while the offer path on the SAME tab had them as `heard never`.
        //  So: LIVE needs a positive `=== true`, and unknown is now COUNTED AND SAID rather than
        //   folded into either side — "1 online · 2 unknown" is the honest sentence, and the one
        //    that tells you to go look at why nobody asked.  sealed|half stay facts about the
        //     friendship and still must not move because somebody closed their laptop.
        if (!(this.Swarm_pier_live && this.Swarm_pier_live(p, 'Music'))) continue
        let seen = this.Presence_here ? this.Presence_here(them) : null
        if (seen === true) { live = live + 1; names.push(p.sc.friendly ? String(p.sc.friendly) : them.slice(0, 8)) }
        if (seen == null) unsure = unsure + 1
    }
    if (!sealed && !half) return { state: 'no', reading: 'nobody' }
    let parts = []
    if (sealed) parts.push(sealed + ' sealed')
    if (half) parts.push(half + ' sealing')
    if (live) parts.push(live + ' online (' + names.join(' + ') + ')')
    if (!live) parts.push('none online')
    // WHY THE UNKNOWNS GET A REASON.  `Presence_note` has existed since presence landed and was
    //  called by nothing but its own spec — it is the one line that separates "the relay says
    //   nobody is there" from "nobody ever asked", which is exactly the question an unknown raises.
    //    Unwired, the distinction was unobservable on a live tab; that is how this bug survived.
    if (unsure) parts.push(unsure + ' unknown (' + this.Swarm_presence_note() + ')')
    let reading = parts.join(' · ')
    if (half && !sealed) return { state: 'part', reading: reading }
    if (!live) return { state: 'part', reading: reading }
    return { state: 'yes', reading: reading }

// Swarm_presence_note — Presence_note against the station world the presence family already uses,
//  with a plain answer when Presence is not on this build at all.  A helper because the dial must
//   stay a pure read and must never care where that world lives.
Swarm_presence_note():
    let w = this.top_House().c.presence_w
    if (!w) return 'presence never armed'
    if (!this.Presence_note) return 'no presence'
    return this.Presence_note(w)

// Swarm_probe_station — a pure read of the standup's own latch.  Reports the STAGE it is stuck at
//  rather than a bare no: "no identity yet" and "not on the relay yet" are two different mornings.
// NOT `Swarm_station_world()`, which is an `oai` and would MINT the world it was asked about — the
//  Ra_stock_standing trap the Supervisor header names ("a probe that collects"), and it would fire on
//   every tick of a world this file does not own.  `o()[0]` reads; that is the whole difference.
Swarm_probe_station(subject, sup):
    let ident = this.Swarm_live_self ? this.Swarm_live_self() : null
    if (!ident) return { verdict: 'wrong', note: 'no identity yet' }
    let A = this.top_House().o({ A: 'Clustation' })[0]
    let w = A ? A.o({ w: 'Swarm' })[0] : null
    if (!w) return { verdict: 'wrong', note: 'no station world yet' }
    if (!w.c.station_up) return { verdict: 'wrong', note: 'not on the relay yet' }
    return { verdict: 'ok', note: '' }

// Swarm_probe_arrival — is ANY pier of ours live on Music right now?  Deliberately not
//  `Radio_alone_why`: that one answers "who is around" (any stored %Pier counts), and a contact from
//   weeks ago is not somebody arriving.  This answers the only question an invite asks — did anyone
//    turn up — and it is a pure read, called from a tick it does not own.
Swarm_probe_arrival(subject, sup):
    let ident = this.Swarm_live_self ? this.Swarm_live_self() : null
    if (!ident) return { verdict: 'unknown', note: 'no identity yet' }
    let me = String(ident.sc.prepub || '')
    for (const p of this.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []) {
        if (!p.sc.pub) continue
        if (me && String(p.sc.pub) === me) continue
        // somebody ARRIVING is the whole question here, so a grant from weeks ago is the weakest
        //  possible evidence for it — drop a pier the relay says is not on it (Presence.g).
        if (this.Presence_offline && this.Presence_offline(String(p.sc.pub))) continue
        if (this.Swarm_pier_live && this.Swarm_pier_live(p, 'Music')) return { verdict: 'ok', note: p.sc.friendly ? String(p.sc.friendly) : '' }
    }
    return { verdict: 'wrong', note: 'nobody has come online' }

// Swarm_iz_of_url — the boot handler's core, isolated pure: pull the ?Iz= token back out of a
//  scanned URL. encodeURIComponent above ↔ URLSearchParams here — the token's *|~|- survive the
//   round trip untouched (none decodes as a space).
//  THE FRAGMENT IS CUT FIRST, and that is not decoration.  This was `indexOf('?')` on the raw href,
//   which gets two shapes wrong that a real link wears: `…?Iz=<token>#anything` handed the token
//    back with the fragment glued to its tail (chat apps and readers append them), and
//     `…#frag?Iz=x` read a `?Iz=` that lives INSIDE a fragment as though it were a query param.
//      `location.search` — what the live door reads through `boot_param` — has neither problem, so
//       this function was the only one carrying them, while its own comment called it "the boot
//        handler's core".  Cutting at the first '#' makes that claim true.  Safe by the token's own
//         alphabet: encodeURIComponent percent-encodes '#', so a raw one is never part of a token.
Swarm_iz_of_url(href):
    if (!href) return null
    let s = String(href)
    let hash = s.indexOf('#')
    if (hash >= 0) s = s.slice(0, hash)
    let at = s.indexOf('?')
    if (at < 0) return null
    return new URLSearchParams(s.slice(at + 1)).get('Iz')
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
    let out = { legacy: 1, prepub: parts[0], advice: parts[1], friendly: c.name, sign: parts[2], granted: 'ftp' }
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

// ── rung 2: REDEEMING one (2026-08-12, the migration that made it possible) ──────────────────────
//  Rung 1 could only ever parse, because the old garden's signing key lived in ITS Dexie and nothing
//   here held it.  The owner migrated that account onto this door — `.jamsend/account/<prepub>/toc.snap`
//    carrying the old keypair, with ONE issuer `%Idzeug:1,to:Music,next:<high water>` standing for every
//     link the old garden ever posted.  That is the whole trick: the old design and this one are the SAME
//      design (Tyranny's `Upper_Number` + "not in the answered set" IS `next` + `claimed`), so an old
//       serial resolves through `Swarm_iz_find` untouched — `i < next` — and needs no legacy ledger at all.
//  What differs is ONLY the MAC.  New: signHeader over sorted-key JSON. Old: a raw ed25519 over
//   `<prepub>-<advice>`, truncated to 16 (Tyranny's Idzeug_i_Idzeugi). Same curve, same key encoding,
//    same "regeneration IS the check" regime — so one branch at the door covers both, and nothing about
//     the spend ledger, the grant mint or the seal moves.

// Swarm_legacy_presig — regenerate the OLD garden's MAC for `advice` and hand back its 16-hex prefix.
//  Only OUR key can make it, exactly as with Swarm_presig, so this verifies without storing anything.
//  THE ALPHABET GUARD IS A SECURITY BOUNDARY, not tidiness.  The caller hands us a string that becomes
//   a SIGNING DOMAIN, and we hold a second domain (signHeader's canonical JSON) signed by the same key.
//    Keeping the two disjoint is what stops a presig minted in one being replayed as the other: the old
//     encoder's own alphabet (`encode_Idzeugi_advice` threw on anything outside it) contains no `{`, `"`
//      or `:`, so a JSON domain can never be spelled as an advice.  Null on anything else — never sign it.
async Swarm_legacy_presig(keys, prepub, advice):
    let s = String(advice == null ? '' : advice)
    if (!s || !/^[\w.~+\-]+$/.test(s)) return null
    if (!keys?.key) return null
    let ido = new Idento()
    ido.thaw({ pub: keys.pub, key: keys.key })
    let sig = await ido.sig(String(prepub) + '-' + s)
    return String(sig).slice(0, 16)

// Swarm_legacy_token — render a parsed relic as a MODERN token so exactly one door serves both eras.
//  `<prepub>*<n>*Music*<sign16>`: the serial is the old `n` (which IS a serial in the issuer's space —
//   that is why the migration set `next` above the old high water), and the `n` slot carries `Music`
//    only to satisfy the codec — the door reads the Feature off its OWN record (§10.1), never off this.
//  The old link's `granted:'ftp'` stays on the RELIC, where it honestly describes what the old garden
//   promised; what a redemption actually mints is whatever our issuer says, which today is Music
//    (the owner 2026-08-12: *"all Invites are just for the entire Music thing"*).
Swarm_legacy_token(relic):
    if (!relic || !relic.prepub || relic.n == null || !relic.sign) return null
    if (!/^[0-9a-f]{16}$/.test(String(relic.sign))) return null
    if (!(Number(relic.n) >= 1)) return null
    return this.Swarm_token(relic.prepub, String(Number(relic.n)), 'Music', String(relic.sign))
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
        // HOLD AN UNVOUCHED FRAME THROUGH THE STANDUP WINDOW (2026-08-06).  station_up is set
        //  SYNCHRONOUSLY at the end of Swarm_station_up, but station_voucher is minted inside the
        //   socket's async on_open, behind two awaited signHeader calls.  In that gap we send frames
        //    with no voucher — and a sealed peer whose own station is up REFUSES them outright
        //     (Swarm_arm's gate: no heard_at, no era, no dispatch) and books a rebuff, whose count
        //      drives the era-kick backoff.  Caught live: our station up at t, an ive_got rebuffed
        //       `unvouched_ive_got` at t+862ms with the electrode reading `vpub:""` — the frame
        //        genuinely carried nothing.  So the frame was never going to land; sending it only
        //         bought a rebuff.  Return false instead and let the caller's beat re-send once the
        //          voucher exists (which is milliseconds away, in the same on_open).
        //  BOUNDED, not indefinite: if the mint THREW ("⨳⚠ station voucher failed") we must degrade
        //   to the old behaviour rather than go permanently mute — after the window we send unvouched
        //    exactly as before.  pier_hello is exempt here for the same reason it is exempt at the
        //     receiving gate: it arrives BEFORE the seal, carrying its own Idzeug proof.
        //  Books never set station_up, so no fixture sees this.
        if (w.c.station_up && !w.c.station_voucher && frame.kind !== 'pier_hello'
            && (Date.now() - (w.c.station_up_at || 0)) < 10000) return false
        let seq = this.Pier_next_seq(route)
        // attach the per-era voucher so the sealed receiver can prove it was US (the relay won't)
        if (w.c.station_voucher) frame.voucher = w.c.station_voucher
        // THE EPOCH RIDES EVERY SWARM FRAME (2026-08-04) — exactly like the voucher above, and for a
        //  kindred reason: a fact the far side MUST have cannot depend on one frame surviving.  `era`
        //   announces my incarnation, `saw` echoes theirs so they learn I hold it.  Both are read by
        //    Swarm_note_era in the hear funnel.  A station-less world (every Book) has no station_era,
        //     stamps nothing, and is byte-identical — the mail wire never sees this.
        if (w.c.station_era) {
            frame.era = w.c.station_era
            if (route.c.peer_era) frame.saw = route.c.peer_era
        }
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
            let ok = await this.Swarm_voucher_ok(sealed, from, frame.swarm?.voucher, ident)
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
        // THE EPOCH, off ANY vouched frame (2026-08-04): a reborn peer announces itself on every
        //  swarm frame it sends (Swarm_deliver stamps era+saw), so recovery no longer hangs on one
        //   greeting surviving.  THE GATE — `may_reset` is 1 only for the EPHEMERAL-lane kinds
        //    (pulse, swarm_hi: dispatched straight from Peeroleum_deliver, never booked).  A BOOKED
        //     kind (ive_got/suggest/pier_*) runs inside inbox.do(), where Peeroleum_reset_handshake
        //      would drop the very inbox being drained and strand every later frame — so there we
        //       only RECORD the era; the pulse lane acts on it within ~5s.  Sealed friends only:
        //        gossip never opens a door, and an era is a door onto our stream state.
        if (sealed && frame.swarm && frame.swarm.era) {
            let eroute = this.Swarm_station_pier(w2, ident, String(from))
            let ephemeral_lane = frame.header.type === 'pulse' || frame.header.type === 'swarm_hi'
            if (eroute) this.Swarm_note_era(w2, eroute, frame.swarm, ephemeral_lane ? 1 : 0)
        }
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
        if (frame.header.type === 'repli_ready') this.Swarm_repli_ready(w2, ident, frame.swarm)
        return true
    }
    for (const kind of ['pier_hello', 'pier_accept', 'pier_confirm', 'pier_reject', 'reinvite', 'reinvite_honour', 'reinvite_seal', 'reinvite_ok', 'ive_got', 'pulse', 'swarm_hi', 'suggest', 'suggest_got', 'repli_ready']) w.c.on[kind] = hear

// Swarm_voucher_ok — is this voucher a valid proof the sealed friend `from` sent the frame?
//  (1) a cache hit — a voucher whose sign we already proved this era — passes without crypto.
//   (2) otherwise: prepubOf(vh.pub) must equal the claimed sender, vh.pub must equal the pub we
//    IMPORTED at seal (their %Pier's %Peering page), and the ed25519 signature must verify against
//     vh.pub.  All three hold ⇒ cache the sign and accept; any fail ⇒ reject (caller rebuffs).
async Swarm_voucher_ok(sealed, from, vh, ident):
    // ELECTRODE (2026-08-06, the human "it seems super easy for our requests for rummage or the radio
    //  channel to break over time … hanging around is fatal?"): this gate is DEAD-SILENT about which of
    //   its four arms rejected, and the caller only records `unvouched_<type>`.  A rejection here kills
    //    the frame outright — no heard_at, no era, no dispatch — so a gate that starts failing is exactly
    //     the shape of "a tab that has been up a while stops being able to talk".  `.c`-only, so no
    //      fixture moves.  SUSPECT NAMED: line ~1196 resolves a friend with
    //       `.find(p => p.o({Peering:1})[0]?.sc?.pub === rootPub)` because SEVERAL %Pier can share one
    //        prepub (a peer that regenerated its root key) — but the hear funnel picks `[0]` blindly, so
    //         `held` below may be the STALE twin's pub while the voucher carries the live one.  `piers`
    //          and `held_i` below say whether that is what happened; `piers > 1` is the tell.
    let nope = (why) => {
        if (typeof this.Radio_trace !== 'function') return false
        try {
            let all = this.Swarm_peering(ident)?.o({ Pier: 1, pub: from }) ?? []
            this.Radio_trace(null, { ev: 'voucher-no', why: why, at: String(from || '').slice(0, 8),
                piers: all.length, held_i: all.indexOf(sealed),
                held: String(sealed?.o({ Peering: 1 })[0]?.sc?.pub || '').slice(0, 8),
                vpub: String(vh?.pub || '').slice(0, 8), era: vh?.era })
        } catch (er) {}
        return false
    }
    if (!vh || !vh.sign || !vh.pub) return nope('no voucher')
    if (sealed.c.voucher_ok && sealed.c.voucher_ok === vh.sign) return true
    if (prepubOf(vh.pub) !== from) return nope('prepub mismatch')
    let held = sealed.o({ Peering: 1 })[0]?.sc?.pub
    if (!held) return nope('no held pub')
    if (held !== vh.pub) return nope('held pub differs')
    let who = await verifyHeader(vh, [vh.pub])
    if (who !== vh.pub) return nope('signature bad')
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
    // ELECTRODE (2026-08-06) — every door slam, in the file rather than only in a console nobody
    //  was watching at the time.  The rebuff is the single funnel for "we refused a stranger" AND
    //   "we could not reach the issuer" (redeem's `offline`) AND "the token was junk" — so a pairing
    //    that never completes leaves its reason HERE and nowhere else.  Trace, don't move: the
    //     console line stays for the human watching live.
    if (typeof this.Radio_trace === 'function') {
        try { this.Radio_trace(null, { ev: 'rebuff', why: why, say: String(say ?? '').slice(0, 16) }) } catch (er) {}
    }

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

// Swarm_iz_mark — THE one way a live claim lands on a record.  Three homes, never two:
//  the record's sc (the door's law), the Dexie twin (survives reload), and a VERSION BUMP.
//  The bump is not decoration.  `Clustation_mirror_account` (Auto.svelte) decides whether to
//   re-write `.jamsend/account/<prepub>/toc.snap` from the mark `prepub:ident.version:peering.version`,
//    and confesses its own gap: *"a mutation that bumps NEITHER would not re-mirror until the next
//     boot."*  A spend is a bare `sc` write, and `bump()` is LOCAL (Stuff.svelte.ts — it moves this
//      particle's serial, never its parent's), so before this helper a claim moved no version and
//       reached disk only by luck: `Swarm_seal` creates a %Pier straight after, and creation bumps
//        the Peering.  Luck runs out on the paths with no seal behind them — a RE-seal finds rather
//         than creates, and both chain-holder moves never seal at all.  Losing a spend mark to disk
//          un-spends an invite on the next disk-seeded boot, which is a security fact, not a nicety.
//  It is also what makes the maker's panel move: only `version` is reactive, never `sc`.
Swarm_iz_mark(ident, record, patch):
    for (const k of Object.keys(patch)) record.sc[k] = patch[k]
    this.Swarm_iz_stash(ident, String(record.sc.Idzeug), patch)
    record.bump()
    let peering = this.Swarm_peering(ident)
    if (peering) peering.bump()

Swarm_iz_rehydrate(w, ident):
    let st = this.top_House().stashed
    let mine = st?.Swarm_izzes?.[ident.sc.prepub]
    if (!mine) return
    let peering = this.Swarm_peering(ident)
    for (const nonce of Object.keys(mine)) {
        let c = mine[nonce]
        // AN ISSUER REHYDRATES AS AN ISSUER.  Its `next` is what makes every outstanding serial
        //  redeemable (`i < next`), and its `claimed` is the whole spend ledger for them — lose
        //   either to a reload and the door forgets invites it really issued, or un-spends ones it
        //    already honoured.  Same stash rail, same key (the issuer's own number).
        if (c.next) {
            let iz = peering.o({ Idzeug: nonce, next: 1 })[0]
            if (!iz) {
                iz = peering.i({ Idzeug: nonce, to: c.to })
                iz.c.up = peering
                for (const k of Object.keys(c)) {
                    if (!['to', 'next', 'claimed'].includes(k)) iz.sc[k] = String(c[k])
                }
            }
            if (c.next) iz.sc.next = String(c.next)
            if (c.claimed) iz.sc.claimed = String(c.claimed)
            continue
        }
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
        // LEGACY blotter membership still rehydrates — a sheet minted before 2026-08-12 left 126
        //  real records and a %Blotter, and those tickets are outstanding in the world. New sheets
        //   are range mints that record no group at all, so nothing here is ever written again.
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
    // REGISTER THE DOOR AS A MILESTONE, at the top and on every retry — SwarmStandup re-enters this
    //  verb on each H bump until it takes, so registering here means the watch exists WHILE we are
    //   still trying, which is the only time it says anything.  Registering after standup would latch
    //    it met on its first read and the Butler would never once have a task to show.  Idempotent by
    //     key (oai merges), so the retries cost a lookup.
    this.Swarm_watch_station(w)
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
    // presence: install the who_ok hook BEFORE the socket can answer (Presence.g).  Idempotent, and
    //  arming it costs nothing if nobody ever asks — the ask itself rides the pulse round below.
    if (typeof this.Presence_arm === 'function') this.Presence_arm(w)
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
            } catch (e) { console.log('⨳⚠ station hello failed (relay down?)', e) }
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
            } catch (e) { console.log('⨳⚠ station voucher failed', e) }
            // the rebirth greeting rides every (re)connect, right behind the hello-bind — same
            //  socket, ordered, so the relay routes it the moment the bind lands.  Routes first:
            //   a reconnect may follow a reload that hasn't re-minted them yet.
            this.Swarm_station_routes(w, ident)
            this.Swarm_hi_all(w, ident)
        })
    }
    this.Tribunal_activate_websocket(w)
    w.c.station_up = 1
    w.c.station_up_at = Date.now()   // when the gate armed — Swarm_deliver holds unvouched frames for a bounded window after this
    // mint the era HERE, at standup, not lazily at first greeting: Swarm_deliver stamps it on every
    //  swarm frame but only `if (w.c.station_era)`, so a station whose voucher/greeting paths both
    //   failed (relay slow, sign threw) would otherwise pulse era-less forever and no friend could
    //    ever confirm it.  One assignment closes that.  LIVE-ONLY: the Books stamp station_up by hand
    //     rather than through this verb, so no fixture sees an era it did not see before.
    this.Swarm_era(w)
    // we are up and we have friends — start the five seconds (Swarm_expect_friends' header).  After
    //  Swarm_era so a failure here cannot cost the era, before the routes so the clock starts at the
    //   standup rather than after the greeting round trip we are timing.
    this.Swarm_expect_friends(w, ident)
    let routed = this.Swarm_station_routes(w, ident)
    // ELECTRODE (2026-08-06) — STANDUP, the t=0 every other discovery mark is relative to.  Without
    //  it a trace file opens mid-story and you cannot tell a peer that never appeared from one that
    //   appeared before the ring's window.  `era` is the identity of THIS boot, so it is also how you
    //    tell your own restart apart from theirs when reading a `rebirth` further down the file.
    //     `routed` vs `piers` is the reload wound (Swarm_station_routes' own header): friendships that
    //      survived but links that did not show up here as a shortfall, before any frame is sent.
    if (typeof this.Radio_trace === 'function') {
        try { this.Radio_trace(null, { ev: 'station-up', era: w.c.station_era, routed: routed,
            piers: (this.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []).length }) } catch (er) {}
    }
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
    // async now (rung 1 mints locally) — fire-and-forget from this sync seam; failures say why.
    this.Swarm_reaccept_incomplete(w, ident).catch((er) => console.log(`⨳⚠ pier heal failed: ${er && er.message || er}`))
    return n

// Swarm_reaccept_incomplete — the SEAL SELF-HEAL (the human 2026-07-28: the pairing came out ONE-WAY —
//  Righto held a %Pier for Lefto but Lefto held NONE.  The single `pier_accept` frame builds the
//   redeemer's WHOLE %Pier, and if it's lost or seq-collision-muted after a reload NOTHING ever re-drives
//    it — every redial path iterates existing %Piers, so the side with none is invisible to all healing).
//  The predicate is WHOLENESS (Swarm_compact_invite_todo §9 rungs 1-2, 2026-08-06): a %Pier stands iff it
//   holds BOTH grants.  The first cut tested only "do I hold THEIRS?" on the stated invariant "a redeemer's
//    %Pier is born with BOTH grants" — which the human's live tabs DISPROVED (Righto: 1 pier, holding
//     theirs, missing its OWN — the redeemer half-seal, the mirror this healer was blind to).
//  Two cures, cheapest first:
//   · missing MY OWN grant → re-mint it LOCALLY (rung 1 — it is my signature; no wire, no security
//      surface, exactly the mint Swarm_accept does at seal).  to+params derive from THEIR grant's claim,
//       the same source Swarm_accept mints from; a pier with NEITHER grant falls back to Feature 'Music'.
//       Swarm_seal (idempotent, dedups by to+by) lands it AND stashes it durable.
//   · missing THEIRS while holding mine → re-send `pier_accept` reusing my ALREADY-SIGNED atom
//      (grant_of_C — never re-mint/re-sign).  Swarm_accept at the far end verifies, seals, and answers
//       pier_confirm; the reciprocal lands, the pier is whole, the re-send stops.  Signature-safe: `page`
//        is unsigned + bind-checked at the far end, and both handlers are idempotent (seal dedups).
async Swarm_reaccept_incomplete(w, ident):
    let me = ident.c.keys ? ident.c.keys.pub : null
    if (!me) return 0
    let n = 0
    for (const pier of this.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []) {
        if (!pier.sc.pub) continue
        let peer = pier.o({ Peering: 1 })[0]
        let theirPub = peer ? peer.sc.pub : null
        if (!theirPub) continue
        if (String(theirPub) === String(me)) continue                  // never re-drive the self-pier
        let mineC = pier.o({ Grant: 1, by: String(me) })[0]
        let theirsC = pier.o({ Grant: 1, by: String(theirPub) })[0]
        if (mineC && theirsC) continue                                  // WHOLE — nothing to heal
        if (!mineC) {
            // rung 1 — the local re-mint.  Their page rides the pier (Swarm_seal stored it); page_bound
            //  is re-checked inside Swarm_seal, so a corrupt stash fails closed, never plants a forgery.
            let page = { prepub: String(pier.sc.pub), pub: String(theirPub), friendly: pier.sc.friendly }
            let to = theirsC ? String(theirsC.sc.Grant) : 'Music'
            let params = theirsC ? this.Swarm_iz_params(grant_of_C(theirsC)) : {}
            let mine = await mint_grant(ident.c.keys, String(theirPub), to, params, this.Swarm_now(w))
            if (this.Swarm_seal(w, ident, page, null, mine)) {
                mineC = pier.o({ Grant: 1, by: String(me) })[0]
                console.log(`⨳⟲ pier heal: re-minted my own missing grant for ${String(pier.sc.pub).slice(0, 8)} (redeemer half-seal — §9 rung 1, no wire)`)
                n = n + 1
            }
        }
        if (!theirsC && mineC) {
            this.Swarm_deliver(w, ident, String(pier.sc.pub), { kind: 'pier_accept', grant: grant_of_C(mineC), page: this.Swarm_page(ident) })
            n = n + 1
        }
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

// ── the EPOCH, made un-loseable (2026-08-04) ────────────────────────────────────────────────
//  The greeting above was the ONLY carrier of the era, and the recovery it drives depended on a
//   chain of five conditionals — lose any one and the pair strands ("A stops sending B new music"):
//    (1) the single fire-and-forget swarm_hi on socket (re)open; (2) its only retry gated on
//     heard_at >15s stale; (3) but heard_at is warmed by the peer's OWN pulses, so `quiet` never
//      trips; (4) and `pulse` was NOT receive-side ephemeral, so a reborn peer's low seqs hit the
//       reused-seq collision and never dispatched at all — heard_at then never stamped, the
//        opposite failure; (5) even once the era lands, the re-offer needs both a presence gate and
//         an offered_mark change.  Sounditron already ate this shape once (its `12 < 15` ordering
//          bug, Sounditron.g's beat-5 comment) — the tell that a silence window is the wrong primitive.
//  THE CURE, in three parts, none of which adds a frame to the wire:
//   (a) the era rides EVERY swarm frame (Swarm_deliver stamps it exactly like the voucher), so any
//        surviving frame from a reborn peer announces the rebirth — pulse, ive_got, suggest, hi.
//   (b) `saw:` echoes the last era I heard from YOU, so a frame proves whether you hold MY current
//        era.  That is the actual fact the re-arm needs; `quiet` was only ever a proxy for it.
//   (c) one central Swarm_note_era does the check — Swarm_heard_hi delegates to it, so there is
//        exactly ONE implementation of "the peer restarted" rather than two that can drift.
//  Converges in one pulse round-trip (~5s) instead of depending on a 15s silence that busy traffic
//   suppresses.  All .c/runtime — no snap byte, and a Book (no station_era) stamps nothing and
//    checks nothing, so the mail-wire fixtures are byte-identical.

// Swarm_era — my station era, minted lazily on first use (a fresh boot = a fresh era, which is the
//  whole point: it is the thing that says "I am not the me you were talking to").
Swarm_era(w):
    w.c.station_era = w.c.station_era || Date.now()
    return w.c.station_era

// Swarm_note_era — hear an era from a sealed friend.  A CHANGED era means they restarted: reset the
//  route's stream state (Peeroleum_reset_handshake — stream history gone, %Ud kept) so their fresh
//   seqs book instead of colliding with our stale inbox history, and clear the want-once cursors (a
//    vanished want must be re-askable after a rebirth, else ra_wanted holds every lost pull as a
//     permanent hole).  Also records whether THEY hold MY current era (`saw`), which is what stands
//      the re-greet backoff down — an unconfirmed epoch keeps getting re-announced, a confirmed one
//       goes quiet.  Returns true if this was a rebirth (the caller may want to re-offer at once).
//  SAFE TO RESET FROM: every carrier of an era is on the EPHEMERAL lane (swarm_hi and, as of this
//   pass, pulse), so this never runs inside inbox.do() — dropping the inbox mid-drain would strand
//    the very frames the reset exists to unblock.  A booked frame's era is RECORDED, never acted on
//     (see the gate in the hear funnel), and the pulse lane resolves it within ~5s regardless.
Swarm_note_era(w, route, sf, may_reset):
    if (!route || !sf || !sf.era) return false
    let reborn = !!(route.c.peer_era && route.c.peer_era !== sf.era)
    if (reborn && may_reset) {
        // ELECTRODE (2026-08-06) — REBIRTH, the largest state event in the system and until now
        //  entirely invisible.  This branch discards the stream history, every want cursor, every
        //   park, both retx ladders and the offer mark, so a rebirth landing mid-heist presents as
        //    "the transfer stopped for no reason".  Read it FIRST when a gap has no other cause:
        //     a `rebirth` at the head of the gap means the peer restarted and nothing downstream is
        //      at fault.  Counts are taken BEFORE the deletes — after them they are all zero.
        if (typeof this.Radio_trace === 'function') {
            try { this.Radio_trace(null, { ev: 'rebirth', at: String(route.sc.pub || '').slice(0, 8),
                era: sf.era, was: route.c.peer_era,
                wanted: Object.keys(w.c.ra_wanted || {}).length,
                parked: Object.keys(w.c.ra_parked || {}).length,
                retx: Object.keys(w.c.ra_retx || {}).length }) } catch (er) {}
        }
        this.Peeroleum_reset_handshake(route)
        delete w.c.ra_wanted
        delete w.c.ra_want_ts
        delete w.c.ra_parked   // §5.3: a rebirth means the far side forgot every park too — nothing to suspend for
        delete w.c.ra_missed   // ditto (2026-08-06): a told miss describes the PREVIOUS incarnation's id map
        // §5.5: every in-flight ask is gone with them, so nothing is ambiguous any more — the Karn marks
        //  and the backoff ladders must go with the wants they describe, else the first want after a
        //   rebirth is un-sampleable and waits out a ×8 rung for an ask that no longer exists.
        //    (pier.c.rtt SURVIVES on purpose: the PATH outlives the peer's boot, and a one-boot-old
        //     srtt is a better prior than starting blind.)
        delete w.c.ra_retx
        delete w.c.ra_tries
        // a rebirth invalidates what we believe we have OFFERED them: their mirror is empty again.
        //  Clearing the mark makes the next share beat re-husk the whole shelf without waiting for
        //   the floor timer below — the fast path for the case we can actually detect.
        delete route.c.offered_mark
    }
    if (reborn || !route.c.peer_era) route.c.era_seen_at = Date.now()
    route.c.peer_era = sf.era
    // do they hold MY era?  `saw` is their echo of the last era they heard from me.  This is the
    //  ONLY affirmative proof the re-arm has landed on their side; everything else is a guess.
    route.c.era_confirmed = !!(sf.saw && String(sf.saw) === String(w.c.station_era || ''))
    if (route.c.era_confirmed) route.c.era_kicks = 0
    return reborn

// one greeting to one friend; reply:1 marks an answer (answers are never re-answered).
Swarm_hi_one(w, ident, prepub, reply):
    let route = this.Swarm_station_pier(w, ident, prepub)
    if (!route) return false
    let station = w.o({ Peering: 1 }).find(p => p.sc.name === ident.sc.prepub)
    if (!w.c.station_up || !this.Peeroleum_carrier(station, w)) return false
    let hi = { kind: 'swarm_hi', era: this.Swarm_era(w), page: this.Swarm_page(ident) }
    // echo THEIR era back so they learn we hold it (the confirmation half of the epoch handshake)
    if (route.c.peer_era) hi.saw = route.c.peer_era
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
    // the ONE epoch implementation.  Swarm_arm's hear funnel normally runs Swarm_note_era on every
    //  vouched swarm frame BEFORE dispatching here (swarm_hi is ephemeral-lane ⇒ may_reset:1), which
    //   makes this call a no-op — note_era is idempotent, a re-note of an already-noted era reads
    //    reborn:false and resets nothing.  It stays because this verb is ALSO called DIRECTLY, not
    //     only through the funnel (SwarmShare beat 9 feeds a raw rebirth frame at it), and the era
    //      reset is the whole point of that path — routing it through the funnel only would silently
    //       drop the restart signal for every non-funnel caller.
    this.Swarm_note_era(w, route, hi, 1)
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
//  `advice` rides only for an OLD GARDEN link (rung 2): the relic's raw advice string, which is the
//   re-signing domain its 16-hex presig was made over. Absent for every modern token, so the door's
//    branch is driven by what the CLAIM carries, and a modern redeem is byte-for-byte what it was.
async Swarm_redeem(w, ident, iz, advice):
    let t = this.Swarm_token_parse(iz)
    if (!t) {
        this.Swarm_rebuff(ident, 'forged', iz)
        return null
    }
    let hello = { kind: 'pier_hello', iz: iz, page: this.Swarm_page(ident) }
    if (advice) hello.relic = String(advice)
    if (!this.Swarm_deliver(w, ident, t.prepub, hello)) {
        this.Swarm_rebuff(ident, 'offline', t.prepub)
        return null
    }
    // the hello is on the wire — WE are now joining somebody, and the radio must wait for them
    //  rather than starting on whoever else is live (Swarm_expect_joining, the invitee's arm).
    this.Swarm_expect_joining(w, t.prepub)
    // ELECTRODE (2026-08-06) — a pairing STARTING, which brackets the `seal` mark at the other end.
    //  Both failure arms above already funnel through Swarm_rebuff (traced), so the three outcomes of
    //   a redeem are now all in the file: forged, offline, or this.  A `redeem` with no `seal` after
    //    it is the pairing that got as far as the wire and then died silently on the issuer's side —
    //     previously indistinguishable from a redeem that was never attempted.
    if (typeof this.Radio_trace === 'function') {
        try { this.Radio_trace(null, { ev: 'redeem', to: String(t.prepub || '').slice(0, 8),
            serial: String(t.serial || '').slice(0, 8) }) } catch (er) {}
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
    // Swarm_iz_find resolves BOTH shapes — a legacy per-invite row, or a serial drawn off an issuer
    //  (`i < next`). Either way it hands back the canonical presig domain, so the regeneration below
    //   is unchanged: it is still the maker's own state that decides, never the carried $n (§10.1).
    let f = this.Swarm_iz_find(ident, t.serial)
    if (!f) return refuse('unknown')
    let record = f.record
    let n = this.Swarm_token_n(f.to, f.params)
    // TWO ERAS, ONE DOOR (§6.2 rung 2). A relic carries its raw `advice`; everything else regenerates
    //  the modern MAC. Both are "re-sign our own domain and prefix-match", so past this point the
    //   spend, the grant mint and the seal are IDENTICAL — an old link becomes an ordinary claim.
    //  THE ADVICE MUST NAME THE SERIAL IT CAME WITH, and that check is the whole tooth. Without it one
    //   genuine relic is an unlimited pass: its {advice, sign} pair verifies on its own, so a holder
    //    could send it beside serial 9999, then 9998… and tick off every unclaimed number in the
    //     issuer's space from a single link. Binding advice.n === t.serial pins a relic to exactly the
    //      one number the old garden signed it for — which is what makes single-use mean anything here.
    //  SERIAL-FORM ONLY: a relic claims a NUMBER off the issuer. A legacy 12-hex per-invite row is a
    //   record of THIS era and has no advice to verify, so it may never be reached down this branch.
    let presig
    if (frame.relic) {
        if (f.kind !== 'serial') return refuse('forged')
        let c = null
        try { c = this.Swarm_legacy_advice(String(frame.relic)) } catch (er) { c = null }
        if (!c || c.n == null || String(Number(c.n)) !== String(t.serial)) return refuse('forged')
        presig = await this.Swarm_legacy_presig(ident.c.keys, ident.sc.prepub, frame.relic)
    } else {
        presig = await this.Swarm_presig(ident.c.keys, ident.sc.prepub, f.canon, n)
    }
    if (!presig || presig !== t.presig) return refuse('forged')
    // proven: OUR invite, on a bound page — a real redeemer. NOW promote the return route (the
    //  pier_accept and every reason below ride it), and answer with denials the honest redeemer can act on.
    this.Swarm_station_pier(w, ident, frame.page?.prepub)
    let deny = (why) => {
        this.Swarm_rebuff(ident, 'hello_' + why, frame.page?.prepub)
        this.Swarm_deliver(w, ident, frame.page?.prepub, { kind: 'pier_reject', why: why, prepub: ident.sc.prepub })
        return null
    }
    if (this.Swarm_iz_spent(f)) return deny('spent')
    // chain policy (§6.3a): a chain invite is not spent on first claim — its first claimant becomes
    //  the tracked HOLDER (the tip), sealed as a normal friend below. A LATER redeem by a NON-holder
    //   is the chain GROWING: the newcomer holds the link the tip passed them, so mint a ReInvite and
    //    let the newcomer carry it to the tip (§6.3a) — the tip, not us, grants + befriends them. The
    //     tip re-redeeming its OWN link is a benign no-op (deny('held')).
    //  A chain ALWAYS wears a per-invite record: a moving holder is the one piece of invite state a
    //   counter genuinely cannot represent, so `chain` never draws a serial (§0 2026-08-12).
    if (record && record.sc.chain && record.sc.holder) {
        if (frame.page.prepub === record.sc.holder) return deny('held')
        return await this.Swarm_reinvite_begin(w, ident, record, frame)
    }
    // a plain invite SPENDS (a legacy row's flag, or a number ticked off its issuer); a chain invite
    //  records its first holder instead — the tip the chain grows from.
    if (record && record.sc.chain) {
        this.Swarm_iz_mark(ident, record, { holder: frame.page.prepub })
    } else {
        this.Swarm_iz_claim(ident, f)
    }
    let mine = await mint_grant(ident.c.keys, frame.page.pub, f.to, f.params, this.Swarm_now(w))
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
    // FAVOUR THE INVITE'S ORIGIN (2026-08-11, the owner: *"would favour the Invite's origin when
    //  the Invite works out right"*).  Swarm_accept is ALWAYS the redeemer hearing the inviter's
    //   accept — the deliberate-join side — so the person to hear first is exactly frame.page.
    //    Stashed as a WISH on the top House, not written into radio.sc.aim here: the radio world
    //     may not be standing yet on a fresh tab, and their crate is certainly still empty — the
    //      dial consumes the wish into its own aim (Radio_dial), which the aimed pool then
    //       prefers the moment any of their records land.  `.c`, one-shot, never snapped.
    this.top_House().c.aim_wish = String(frame.page.prepub)
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
    this.Swarm_iz_mark(ident, record, { holder: pend.newcomer })
    delete record.c.pending[ok.rnonce]
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
    let re_seal = pier.sc.since ? 1 : 0   // read BEFORE the since-stamp below, for the electrode at the tail
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
    // ELECTRODE (2026-08-06) — a friendship reaching durable storage.  `grants` is the half-seal
    //  tell WITHOUT waiting for a badge: this verb is reached from both wire entries and from the
    //   standup rehydrate, and a pier that only ever seals with ONE grant is the one-way pairing
    //    (the 2026-07-28 Righto/Lefto shape) caught at the moment it forms rather than hours later.
    //     `re` distinguishes a fresh seal from an idempotent rehydrate — a storm of re-seals for one
    //      peer means the self-heal is looping, which reads as nothing at all in the UI.
    if (typeof this.Radio_trace === 'function') {
        try { this.Radio_trace(null, { ev: 'seal', at: String(page.prepub || '').slice(0, 8),
            who: String(page.friendly || '').slice(0, 12),
            grants: pier.o({ Grant: 1 }).length, re: re_seal }) } catch (er) {}
    }
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
//  `from` (2026-08-08) is the SOURCE to read the ledger out of, defaulting to `ident` itself.  It
//   exists because Auto's disk-seed does NOT land the account in the live tree: it seeds into a
//    DETACHED vault and harvests only the keypair, then Clustation_concrete mints a SEPARATE live
//     %Identity under A:Clustation.  So the two are different objects, and the live-self guard inside
//      every _stash verb (`live !== ident` → silent return) means "restash the vault" and "restash
//       the live self" are each half-useless alone — the vault has the ledger but fails the guard, the
//        live self passes the guard with an empty Peering.  Splitting read-from / stash-under is the
//         whole fix; both must name the SAME prepub, which Swarm_restash_all checks.
Swarm_restash_piers(ident, from):
    let peering = this.Swarm_peering(from || ident)
    if (!peering) return 0
    let n = 0
    for (const pier of peering.o({ Pier: 1 })) {
        let e = this.Swarm_pier_entry(pier)
        this.Swarm_pier_stash(ident, e.page, e.grants, e.nots)
        n = n + 1
    }
    return n

// Swarm_restash_izzes — the INVITE half, and the one that has teeth tonight.  A %Idzeug is the
//  single-use serial the door checks: Swarm_hello does `o({ Idzeug: t.serial })[0]` under the LIVE
//   %Peering and refuses('unknown') when it misses — SILENTLY, from the redeemer's side indistinguish-
//    able from a stranger.  A restored owner whose ledger never reached the stash therefore denies its
//     own invites, which is the 2026-07-18 two-tab seal failure wearing a different hat.
//  The entry IS the sc map minus the mainkey: Swarm_iz_rehydrate reads `to`/`ttl`/`chain`/`spent`/
//   `holder`/`blotter` by name and re-wears every OTHER key as a feature param (the door's presig
//    regeneration reads the record, never a carried $n), so copying sc wholesale is not laziness —
//     it is the only shape that survives a feature param nobody has invented yet.
Swarm_restash_izzes(ident, from):
    let peering = this.Swarm_peering(from || ident)
    if (!peering) return 0
    let n = 0
    for (const iz of peering.o({ Idzeug: 1 })) {
        let nonce = iz.sc.Idzeug
        if (!nonce) continue
        let c = {}
        for (const k of Object.keys(iz.sc)) { if (k !== 'Idzeug') c[k] = iz.sc[k] }
        this.Swarm_iz_stash(ident, nonce, c)
        n = n + 1
    }
    return n

// Swarm_restash_chainroots — the lineage third.  NOTE THE SHELF: a %ChainRoot hangs off the
//  %Identity, not off the %Peering (Swarm_chainroots_rehydrate does `ident.oai({ ChainRoot: 1 ... })`)
//   — the recipe in Identity_persist_todo §5/§6.6 says "the Peering's ChainRoots" and is simply wrong
//    about the shelf; walking the Peering here would find nothing and report a confident zero.
//  Without it a restored Carol forgets Alice's chain authority and denies Carol→Dave 'unknown_root'.
Swarm_restash_chainroots(ident, from):
    let src = from || ident
    if (!src) return 0
    let n = 0
    for (const cr of src.o({ ChainRoot: 1 })) {
        if (!cr.sc.pub) continue
        this.Swarm_chainroot_stash(ident, cr.sc.pub)
        n = n + 1
    }
    return n

// Swarm_restash_all — the whole durable ledger of one identity, mirrored into the Dexie stash in one
//  call: friendships, invites, lineage.  THE SECOND-RELOAD TRAP is what it exists for — reload #1
//   seeds off disk and grafts a ledger into memory; reload #2 finds the identity in Dexie, therefore
//    never touches disk (§6.0's "no disk read on a healthy boot", which is correct and stays), and
//     rehydrates its friends from a stash that was never written.  Friends vanish, invites go
//      'unknown', and nothing anywhere logs a fault.  Stash on the way IN and the boot after is a
//       plain Dexie hit that happens to know everything.
//  Guards, both load-bearing:
//   LIVE SELF — every _stash verb refuses when `ident` is not the machine's active identity, so the
//    caller must concrete FIRST and pass the live object.  A Book's puppets and a foreign tab must
//     never write the House stash, and that guard is the thing stopping them; do not route around it.
//   SAME PREPUB — reading from a vault means naming two objects, and naming two objects means someone
//    will eventually pass the wrong one.  A mismatch here would file a STRANGER's friends and invites
//     under our own prepub, which is worse than the bug being fixed: refuse it and say so.
//  Returns the counts, so a caller can log what it actually adopted rather than that it tried.
Swarm_restash_all(ident, from):
    let src = from || ident
    if (!ident || !src) return { piers: 0, izzes: 0, roots: 0 }
    if (src !== ident && src.sc.prepub !== ident.sc.prepub) {
        console.log('🪪 restash REFUSED — ' + String(src.sc.prepub) + ' is not ' + String(ident.sc.prepub))
        return { piers: 0, izzes: 0, roots: 0 }
    }
    return { piers: this.Swarm_restash_piers(ident, src),
             izzes: this.Swarm_restash_izzes(ident, src),
             roots: this.Swarm_restash_chainroots(ident, src) }

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
    // ── ask ONCE who is actually there, instead of guessing once per friend ──────────────────────
    //  This loop is the N-speculative-frames-per-round problem: with 100 friends and 5 online, 95
    //   pulses per round bought nothing, and a miss is silent (an ephemeral frame books no emit and
    //    takes no ack, so absence of a reply is the ONLY signal there ever was).  One `who` up the
    //     relay answers it properly — see Presence.g for the whole argument.
    //  Suppression is one-way by construction: Presence_worth_sending is false ONLY on a fresh,
    //   positive "no socket for them".  Unknown — never asked, stale, refused, no relay, a Book with
    //    the mock carrier — sends exactly as before, so this cannot strand a friend.
    //  NOT a race, though it reads like one: the ask below is a round trip, so the loop that follows
    //   uses the PREVIOUS round's answer (~10s old, well inside the 30s freshness window).  That is
    //    the intent — presence is a standing fact refreshed on a cadence, not a request/response this
    //     loop waits on.  A first-ever round therefore has no answer yet and pulses everybody, which
    //      is exactly the old behaviour.
    if (typeof this.Presence_ask_roster === 'function') this.Presence_ask_roster(w, ident)
    for (const pier of this.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []) {
        if (typeof this.Presence_worth_sending === 'function' && !this.Presence_worth_sending(w, pier.sc.pub)) continue
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
        // ── the re-greet, now driven by the EPOCH rather than by silence (2026-08-04) ──
        //  The old gate was `quiet` alone: re-greet a friend we have not heard from in 15s.  That is a
        //   PROXY for the thing we actually care about — "does this friend hold my current era?" — and
        //    it is the wrong way round: a friend who IS talking to us (so never quiet) but is talking
        //     from a stale epoch is precisely the stranded case, and the proxy can never see it.  Now
        //      the era rides every swarm frame and `saw` echoes it back (Swarm_note_era), so we know
        //       the fact directly.  BOTH triggers stand:
        //   · quiet — unchanged, the dead-link probe (no frames at all ⇒ nothing could carry an era).
        //   · unconfirmed — they have never echoed my current era back.  This is the reload case.
        //  BOUNDED so an old peer that never echoes `saw` cannot become a flood: the unconfirmed kick
        //   backs off 5s→10s→20s→40s→60s and settles there, and a confirmation zeroes the counter
        //    (Swarm_note_era).  The kick is one tiny ephemeral frame; it is the BACKSTOP now, not the
        //     primary path — the pulse itself carries the era, so the normal case converges with no
        //      extra frame at all and never reaches this branch.
        let quiet = !pier.c.heard_at || (Date.now() - pier.c.heard_at) > 15000
        // NON-MINTING lookup (the Swarm_deliver idiom), NOT Swarm_station_pier: a heartbeat must never
        //  have the side effect of promoting a transport route.  No route yet ⇒ nothing to confirm,
        //   and Swarm_hi_one (which does mint, deliberately) is still reachable via the `quiet` arm.
        let hstation = w.o({ Peering: 1 }).find(p => p.sc.name === ident.sc.prepub)
        let route = hstation && hstation.o({ Pier: 1 }).find(p => p.sc.pub === pier.sc.pub)
        let unconfirmed = !!(route && !route.c.era_confirmed)
        let kicks = (route && route.c.era_kicks) || 0
        let backoff = Math.min(5000 * Math.pow(2, kicks), 60000)
        let waited = Date.now() - ((route && route.c.hi_kick_at) || 0)
        let cooled = quiet ? (!pier.c.hi_kick_at || (Date.now() - pier.c.hi_kick_at) > 15000) : (waited > backoff)
        if ((quiet || unconfirmed) && cooled && w.c.station_up) {
            pier.c.hi_kick_at = Date.now()
            if (route) { route.c.hi_kick_at = Date.now(); route.c.era_kicks = kicks + 1 }
            // ELECTRODE (2026-08-06) — the EPOCH BACKSTOP firing.  In the healthy case this branch is
            //  never reached at all: the era rides every pulse and converges in one round trip.  So a
            //   kick is already a mild anomaly, and `kicks` CLIMBING (5s→10s→…→60s, then stuck at the
            //    ceiling) is the stranded pair — the link carries frames but the far side never echoes
            //     `saw`, which is exactly the case the old `quiet` proxy could not see.  `why` separates
            //      a dead link (quiet: nothing arriving) from a live-but-stale one (unconfirmed).
            if (typeof this.Radio_trace === 'function') {
                try { this.Radio_trace(null, { ev: 'era-kick', at: String(pier.sc.pub || '').slice(0, 8),
                    why: quiet ? 'quiet' : 'unconfirmed', kicks: kicks + 1, backoff: backoff,
                    route: route ? 1 : 0 }) } catch (er) {}
            }
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
    let piers = this.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []
    let granted = 0
    for (const pier of piers) {
        if (!this.Swarm_pier_live(pier, 'Music')) continue
        granted = granted + 1
        let frame = { kind: 'ive_got', page: this.Swarm_page(ident), records: counts.records, artists: counts.artists }
        if (this.Swarm_deliver(w, ident, pier.sc.pub, frame)) told = told + 1
    }
    // ELECTRODE (2026-08-06) — THE ADVERTISE RATIO, and it is three numbers because the boast can
    //  die at three different places that all look identical from the outside ("they can't see my
    //   music").  piers → granted is the GRANT gate (revoked, or a half-seal that never got a Music
    //    grant); granted → told is the TRANSPORT gate (Swarm_deliver found no carrier — offline, or
    //     no route minted).  `records` is what we were boasting; a census of 0 means the shelf is the
    //      problem and neither gate matters.  This verb previously returned `told` to a caller that
    //       discarded it, so all three facts existed for one stack frame and were never once seen.
    //  CENSUS BREAKDOWN (2026-08-06): live, BOTH tabs advertised `records:0` on every beat while one
    //   of them was demonstrably serving a 474-chunk track to the other — so each was telling the
    //    other "I have nothing" while the bytes moved fine.  A zero census has three distinct causes
    //     that the single number cannot tell apart, so name them:
    //      `cw`=0 ⇒ w.c.census_w was never pointed at the RADIO world, so we counted the swarm world,
    //        which holds no %MusuSelf and can only ever answer 0 (the default in Swarm_music_census is
    //         `w` itself — the BOOK behaviour, wrong for a live tab);
    //      `selfs`>0 but `homes`=0 ⇒ a %MusuSelf exists but under a DIFFERENT pub than ident.prepub —
    //        an identity mismatch, not an empty shelf;
    //      `homes`>0 and `stocks`=0 ⇒ the home stands but the stoker has shelved no stock yet.
    let cw_set = 0, homes = 0, selfs = 0, stocks = 0
    if (typeof this.Radio_trace === 'function') {
        try {
            let cw = w.c.census_w || w
            cw_set = w.c.census_w ? 1 : 0
            selfs = cw.o({ MusuSelf: 1 }).length
            for (const home of cw.o({ MusuSelf: 1, pub: ident.sc.prepub })) {
                homes = homes + 1
                stocks = stocks + home.o({ stock: 1 }).length
            }
        } catch (er) {}
        try { this.Radio_trace(null, { ev: 'advertise', piers: piers.length, granted: granted, told: told,
            records: +(counts.records || 0), artists: +(counts.artists || 0),
            cw: cw_set, selfs: selfs, homes: homes, stocks: stocks }) } catch (er) {}
    }
    return told

// Swarm_boast_floor — the boast's RE-SEND FLOOR, the twin of the re-offer floor in Swarm_share_beat.
//  Until 2026-08-06 `Swarm_gossip_music` had exactly ONE trigger: hearing a non-reply `swarm_hi`
//   (Swarm_hear_hi).  That fires at standup and on an era-kick — which is the one moment the census is
//    GUARANTEED wrong, because both things it counts stand LATER than the handshake: the radio world
//     (Stoker_ensure stamps top.c.radio_w when the dial first runs) and the share glue (Swarm_share_up
//      stamps w.c.census_w).  So the boast said `records:0`, nothing ever recomputed it, and the peer's
//       %IveGot read "they have nothing" for the whole session while bytes moved fine over the same
//        seal.  The tell in the trace ring was not the zero — it was that only THREE `advertise` marks
//         existed, all inside the first 40s, on a tab that had been up for eight minutes.
//  Change-triggered, with a floor under it, for the same reason the re-offer has one: a mark that is
//   wrong-but-stable is a silent permanent hole, and a floor turns any such hole into a bounded delay.
//    The census itself is throttled separately (`boast_look_at`) because it walks the shelf — cheap at
//     16 records, not something to run twice per 600ms beat at collection scale.
Swarm_boast_floor(w, ident):
    let now = Date.now()
    if (w.c.boast_look_at && (now - w.c.boast_look_at) < 5000) return
    w.c.boast_look_at = now
    let cn = this.Swarm_music_census(w, ident)
    let mark = String(cn.records || 0) + ':' + String(cn.artists || 0)
    let floor = (w.c.swarm_boast_floor_ms == null ? 30000 : +w.c.swarm_boast_floor_ms)
    if (w.c.boast_mark === mark && w.c.boast_at && (now - w.c.boast_at) <= floor) return
    w.c.boast_mark = mark
    w.c.boast_at = now
    this.Swarm_gossip_music(w, ident)

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
    // BOAST-HEARD electrode (2026-08-06, the trace lane): the sink half of `advertise` — without
    //  it, "the boast never arrived" and "the boast arrived but the husks didn't" read identically
    //   on the sink's ring.  With it the birth story is one unbroken line: advertise (their ring) →
    //    boast-heard → crate-born → mirror-merge → want-first → page-first → dial (this ring).
    if (typeof this.Radio_trace === 'function') {
        try { this.Radio_trace(null, { ev: 'boast-heard', of: String(frame.page?.prepub || '').slice(0, 8), records: +(frame.records || 0) }) } catch (er) {}
    }
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
//  Presence SUBTRACTS here, never adds: a relay socket being open does NOT mean that peer will
//   serve us, so it can only rule a source OUT (the relay says their socket is gone ⇒ the want is a
//    guaranteed hole), never in.  heard_at — an actual voucher-checked frame from them — stays the
//     positive evidence.  Unknown presence leaves the gate exactly as it was.
Swarm_share_present(from, w):
    let me = this.Swarm_live_self ? this.Swarm_live_self() : null
    let p = me ? this.Swarm_peering(me)?.o({ Pier: 1, pub: String(from) })[0] : null
    if (!(p && p.c.heard_at && (Date.now() - p.c.heard_at) < 20000)) return false
    if (w && typeof this.Presence_live === 'function' && this.Presence_live(w, from) === false) return false
    return true

// COME-BACK CATALOG, THE NEGATIVE RESULT (2026-08-11, Radio_todo §0): a pushed catalog into a
//  returning friend's startup window is lost (their Repli_arm hasn't run), and every back-signal
//   tried here — no_protocol complaints, offer-mark resets, a recap ask — measured a no-op,
//    because each ceases or fires before the one moment that matters (the peer BECOMING ready).
//     The mature fix is consent-shaped: don't push repli_lines until the peer's Grant is ACTIVE —
//      i.e. the receiving side says "my rx is armed, send" as part of the grant lifecycle, not as
//       frame-level reliability.  Design in Radio_todo §0 (Grant activation).

// Swarm_repli_ready — GRANT ACTIVATION, the receiving half.  A sealed friend announces its Repli rx
//  is ARMED — sent once from the bottom of ITS Swarm_share_up, i.e. from the side that KNOWS, at the
//   moment it becomes true.  This is the signal every back-channel above tried to synthesise and
//    could not: they all fired before or after the ready moment; this IS the ready moment.
//  AUTHENTICATED: it rides the swarm envelope with a page in the body, so the hear funnel's voucher
//   gate has already proven the sender is the sealed pier it claims — activation is a consent fact
//    and must not be forgeable.  Then: stamp the route ACTIVE and un-spend the offer mark, and the
//     ordinary 600ms beat re-offers through every gate it always used — landing, because the rx it
//      aims at is armed by definition (measured shape: come-back catalog ~at the peer's share_up,
//       not at the 60s floor).
//  TODAY AN ACCELERATOR, NOT YET A GATE: a route never stamped rx_ready keeps the floor-backstopped
//   behaviour, so an old peer that never announces loses nothing.  The maturation — offers HELD
//    until the grant is ACTIVE, the full consent reading — is Radio_todo §0 (Grant activation).
//  THE ASK IS ANSWERED HERE, NOT LEFT TO THE BEAT (2026-08-11, the owner: "a newly arrived peer
//   must ask for some Mag").  The first cut only un-spent the offer mark and trusted the 600ms
//    beat to re-offer — and two live trials still measured the come-back at the 60s floor: the
//     beat's cadence is nominal, its PHASES are minute-scale under a wedged tour/cull, so a mark
//      reset waits on whenever the offer loop next actually runs.  A request deserves a reply, so
//       the offer fires RIGHT HERE, detached (the funnel dispatch does not await this handler),
//        through the same gates and mark discipline the beat uses (Swarm_offer_now).  The reset
//         stays: if the immediate offer throws, the mark is still null and the beat + floor
//          backstop exactly as before.
Swarm_repli_ready(w, ident, frame):
    let from = String(frame?.page?.prepub || '')
    if (!from) return 0
    let sealed = this.Swarm_peering(ident)?.o({ Pier: 1, pub: from })[0]
    if (!sealed) return 0
    let route = this.Swarm_station_pier(w, ident, from)
    if (!route) return 0
    route.c.rx_ready = Date.now()
    route.c.offered_mark = null
    route.c.offered_at = 0
    if (typeof this.Radio_trace === 'function') {
        try { this.Radio_trace(null, { ev: 'repli-ready', of: from.slice(0, 8) }) } catch (er) {}
    }
    if (w.c.station_up) this.Swarm_offer_now(w, ident, from).catch((er) => console.error('⨳ offer-now threw —', (er && er.message) || er))
    return 1

// Swarm_offer_now — one friend's Mag, offered NOW: the reply half of repli_ready's ask.  The same
//  gates and the same mark discipline as the beat's offer loop (pier_live Music, register caster,
//   stamp offered_mark/offered_at BEFORE the send) so the beat sees a spent mark and does not
//    double-offer — Repli_merge dedups the far side anyway, so a race costs one husk, never a wound.
//     No presence check: the caller holds a frame that just crossed the voucher gate, which is
//      presence.  LIVE ONLY by the caller's station_up gate — a Book world never reaches this, so
//       no fixture can grow %frame husks from it.  Returns 1 iff the offer was sent.
async Swarm_offer_now(w, ident, pub):
    if (!w || !w.c.share_up) return 0
    let rw = this.top_House().c.radio_w
    if (!rw) return 0
    let me = String(ident.sc.prepub)
    let them = String(pub)
    if (them === me) return 0
    let p = this.Swarm_peering(ident)?.o({ Pier: 1, pub: them })[0]
    if (!p || !this.Swarm_pier_live(p, 'Music')) return 0
    let route = this.Swarm_station_pier(w, ident, them)
    if (!route) return 0
    let stock = this.Ra_home_self(rw, me)
    if (!route.c.repli_src) this.Repli_register_caster(w, route, stock)
    let n = this.Ra_recs(stock).length
    let tour = String(rw.o({ Stoker: 1 })[0]?.sc?.toured || 0)
    let mark = String(w.c.station_era || 0) + ':' + String(route.c.peer_era || 0) + ':' + n + ':' + tour
    route.c.offered_mark = mark
    route.c.offered_at = Date.now()
    await this.Ra_offer_stock(w, route, me, them, stock)
    if (typeof this.Radio_trace === 'function') {
        try { this.Radio_trace(null, { ev: 'offer-now', of: them.slice(0, 8), n: n }) } catch (er) {}
    }
    return 1

// Swarm_share_up — idempotent: arm Repli on the station world, wire the grant gate + the
//  mirror conventions, and start the pump.  Needs the radio world standing (top.c.radio_w —
//   Stoker_ensure stamps it) for the shelves; returns false until it is, callers just re-ask.
Swarm_share_up(w, ident):
    if (!w || !ident?.sc?.prepub) return this.Swarm_share_no(w, 'no station world or no identity')
    if (w.c.share_up) return true
    let rw = this.top_House().c.radio_w
    if (!rw) return this.Swarm_share_no(w, 'radio world not standing yet')
    if (typeof this.Repli_arm !== 'function') return this.Swarm_share_no(w, 'Repli verbs not deposited')
    this.Repli_arm(w)
    w.c.repli_mirror_pier = String(ident.sc.prepub)   // my addr — the pull's from-address (Ra_restock_beat)
    w.c.repli_mirror_by_from = 1                       // per-friend crates, keyed by the caster
    w.c.repli_mirror_w = rw                            // crates mint in the radio world — the glass sees them
    w.c.census_w = rw                                  // the boast counts the shelf the stoker actually fills
    w.c.repli_allow = (peer) => this.Swarm_share_granted(peer)
    w.c.ra_source_live = (from) => this.Swarm_share_present(from, w)
    w.c.share_up = 1
    if (typeof this.Radio_trace === 'function') {
        try { this.Radio_trace(null, { ev: 'share-up' }) } catch (er) {}
    }
    // GRANT ACTIVATION, the announcing half (2026-08-11, the owner: *"everything needs to hang off
    //  the Grant being established and perhaps activated"*).  Our Repli rx is armed AS OF THIS LINE
    //   — Repli_arm ran nine lines up — so tell every sealed friend.  Their change-triggered offer
    //    fired into our startup window and died there (the measured 65s come-back, the negative-
    //     result note above Swarm_share_up); this frame is the one signal that fires AT the ready
    //      moment, FROM the side that knows.  It lands in a MATURE tab by construction — the peer
    //       that wants to offer has been up all along — so it has no startup window of its own.
    //  Fire-and-forget: an offline friend misses nothing (their next offer meets our armed rx
    //   anyway), and Swarm_deliver quietly returns false when a route is not ready.
    //  LIVE STATION ONLY — Books never set station_up, and in a Book world Swarm_deliver falls to
    //   the in-process %mail drop, which leaves %frame husks in every share fixture.  The startup
    //    window this heals is a live-relay fact; a fixture has no startup window to lose frames in.
    if (w.c.station_up) {
        for (const p of (this.Swarm_peering(ident)?.o({ Pier: 1 }) || [])) {
            if (!p.sc.pub) continue
            // ARM THE DOOR BEFORE KNOCKING: the reply (Swarm_offer_now at the friend) comes back
            //  within one round trip, but our per-route rx registration used to wait for our own
            //   first share beat — so the immediate reply would die in the exact dead window this
            //    announce exists to close.  Register the rx here, then speak.
            let route = this.Swarm_station_pier(w, ident, String(p.sc.pub))
            if (route && !route.c.repli_rx) this.Repli_register_rx(w, route)
            this.Swarm_deliver(w, ident, String(p.sc.pub), { kind: 'repli_ready', page: this.Swarm_page(ident) })
        }
    }
    this.Swarm_share_loop(w, ident)
    // the SoundSupervisor rides alongside, on its own timer, deliberately NOT inside the beat it
    //  watches (see Swarm_watch_loop's header — a req-based watchdog queues behind its own wedge).
    this.Swarm_watch_loop(w)
    return true

// Swarm_share_no — WHY the share did not arm, said once per distinct reason.  Callers re-ask
//  constantly (every radio dial), so marking each refusal would be a flood; the reason CHANGING is
//   the whole signal, and a reason that never changes is precisely the bug — a tab stuck forever on
//    'radio world not standing yet' is a tab that will never share music, and until 2026-08-06 that
//     state was completely mute.  It cost an hour of reading `cw:0` and guessing which of three
//      places had failed, when the failing verb knew the answer and threw it away.
//  Returns false so each guard above stays a one-liner.  `.c`-only, no bump.
Swarm_share_no(w, why):
    if (w && w.c.share_no !== why) {
        w.c.share_no = why
        if (typeof this.Radio_trace === 'function') {
            try { this.Radio_trace(null, { ev: 'share-no', why: why }) } catch (er) {}
        }
    }
    return false

// the pump loop: ~600ms cadence, era-guarded (a re-up cancels the stale chain — the Radio
//  loop law), each beat a post_do so the req drains ride the mutex like a carrier delivery.
//   BUSY-GUARDED (the human 2026-07-30, watching a heist double-write a landed file — "spastic as
//    fuck"): `tick` used to fire `setTimeout(tick, 600)` UNCONDITIONALLY, regardless of whether the
//     post_do'd beat from the PREVIOUS tick had actually finished — post_do queues, it doesn't await,
//      so a beat that runs longer than 600ms (any real Heist pull, streaming megabytes) let a SECOND
//       Swarm_share_beat start — and with it a second, concurrent Heist_keep_step — while the first was
//        still mid-stream into the SAME destination file.  Two overlapping writers explains everything
//         that was seen: a landed file doubling in size, a .crswap reappearing beside an already-complete
//          .flac, sizes climbing then dropping non-monotonically.  `share_beat_running` skips firing a
//           new beat while one is still in flight — the 600ms check keeps ticking so the very next free
//            tick catches up immediately, no added latency once beats are fast again.
// Swarm_cull_detached — kick the shuffle cull and BOW OUT.  The cull is a janitor whose cost is a
//  per-record awaited disk expand, so its duration scales with the crate (539 dirs ⇒ tens of seconds)
//   while everything the radio eats sits downstream of it in the beat.  Nothing in the beat reads its
//    return, so the await bought us nothing and cost us the music.  Single-flight: `cull_flying` holds
//     the start stamp, so a 30s sweep can never have a second copy started on top of it.
//  It still REPORTS — `cull_bg_ms` is the last completed sweep's duration and rides the split as
//   `cull_bg`.  Detaching a slow thing while also making it invisible would just move the mystery.
Swarm_cull_detached(w, rw, stock):
    if (w.c.cull_flying) return 0
    if (typeof this.Ra_shuffle_cull !== 'function') return 0
    w.c.cull_flying = Date.now()
    this.Ra_shuffle_cull(rw, stock).then(() => this.Swarm_cull_done(w)).catch(() => this.Swarm_cull_done(w))
    return 1

// Swarm_cull_done — one line, two callers (settle and throw), so a cull that FAILS still clears the
//  single-flight latch.  A latch left standing would silently retire the cull for the life of the tab.
Swarm_cull_done(w):
    w.c.cull_bg_ms = Date.now() - (+(w.c.cull_flying || Date.now()))
    w.c.cull_flying = 0

// Swarm_tour_detached / Swarm_tour_done — the cull's twin, for the collection conveyor.  Deliberately
//  a SEPARATE pair rather than a shared generic: `Swarm_cull_detached`/`cull_bg_ms` are already named
//   in MusuNeGrind's (unbuilt) assertions, and renaming them to save six lines would break a Book
//    nobody has run yet — the worst kind of breakage to introduce, because it looks like it works.
//  Same contract: single-flight on a start stamp, duration reported as `tour_bg`, latch cleared on
//   BOTH settle and throw (a stuck latch would retire the conveyor for the life of the tab, and a
//    collection that stops touring stops growing — silently, which is this page's whole failure mode).
Swarm_tour_detached(w, rw, stock):
    if (w.c.tour_flying) return 0
    if (typeof this.Stoker_tour !== 'function') return 0
    w.c.tour_flying = Date.now()
    this.Stoker_tour(rw, stock).then(() => this.Swarm_tour_done(w)).catch(() => this.Swarm_tour_done(w))
    return 1

Swarm_tour_done(w):
    w.c.tour_bg_ms = Date.now() - (+(w.c.tour_flying || Date.now()))
    w.c.tour_flying = 0

// ── Swarm_beat_health — STEP 1 OF THE SUPERVISOR (spec/Supervisor_todo.md §0) ──
//  The human, after the third silent wedge found by pasting a console at me: "there has to be a
//   supervisor built still, to discern all these moments when we should give up and reload."
//  This is that, at its smallest honest size: a PURE READ over state that already exists, returning
//   a verdict. No req, no UI, no action, no reload. Those are steps 2–4 and each wants its own proof.
//
//  THE ONE HARD PART is telling SLOW from STUCK, and elapsed time cannot do it: `Ra_shuffle_cull`
//   legitimately runs 70s on a 543-directory crate, so at t=30s a healthy sweep and a permanent hang
//    are identical. The distinguisher is MONOTONIC PROGRESS — did the furthest-reached phase advance
//     since we last looked — which is why this reads a phase CURSOR and not a duration.
//  AND THE THRESHOLD IS SELF-CALIBRATED, per phase. A constant is wrong by construction here: `keep`
//   and `cull` differ by three orders of magnitude, so one number would either cry wolf at the cull or
//    never fire for the rest. Each phase learns its own rolling median and is judged against ITS OWN
//     typical cost. The medians live on `.c`, so a reload re-learns — correct for a supervisor (a
//      fresh tab should not inherit a wedged tab's idea of normal), and noted so nobody "fixes" it
//       into the snap later ([[learns-over-time-on-c-never-does]] is about caches that SHOULD persist;
//        this is the opposite case).
//
//  Returns { state: 'ok'|'slow'|'stuck', phase, for_ms, why } — `phase` is always named, because a
//   verdict that says only "something is wrong" spends the one thing this session proved valuable.

// Swarm_beat_phase — the furthest phase this beat has completed, as a name.  The split is a PROGRESS
//  BAR, not a cost table: fields are zeroed at the top of each beat and stamped only on completion, so
//   the LAST NON-ZERO field is how far the beat got.  Reading it as costs is what hid the tour stall.
Swarm_beat_phase(w):
    let sp = w.c.beat_split || {}
    let order = ['cull', 'tour', 'flush', 'peers', 'keep']
    let far = ''
    for (const k of order) { if (+(sp[k] || 0) > 0) far = k }
    return far

// Swarm_beat_note — call once per completed beat: fold each phase's cost into a rolling median-ish
//  centre (an EWMA — a true median would need a window per phase and this is a watchdog, not a
//   profiler) and stamp the phase cursor whenever it MOVES.  `phase_at` is the liveness clock.
Swarm_beat_note(w):
    let sp = w.c.beat_split || {}
    w.c.phase_avg = w.c.phase_avg || {}
    for (const k of ['cull', 'tour', 'flush', 'peers', 'keep']) {
        let v = +(sp[k] || 0)
        if (v <= 0) continue
        let prev = +(w.c.phase_avg[k] || 0)
        w.c.phase_avg[k] = prev > 0 ? Math.round(prev * 0.8 + v * 0.2) : v
    }
    let far = this.Swarm_beat_phase(w)
    if (far !== w.c.phase_far) {
        w.c.phase_far = far
        w.c.phase_at = Date.now()
    }

// Swarm_probe_beat — the SUPERVISOR'S read of the beat, and the reason Swarm_beat_health finally has
//  a reader.  It landed 2026-08-08 and had never once been consulted by anything; a sensor with no
//   reader gates nothing, and this repo has already caught one claim that was pure theatre.
//  `slow` is deliberately NOT wrong: the health verb grades it at a third of the stuck bar, which is
//   a warning about a machine that is still working.  Calling that a fault would make the sanity cell
//    shout at every busy moment and teach the owner to ignore it — the exact failure the idle HUDs
//     died of.  Only `stuck` is wrong.
Swarm_probe_beat(w, sup):
    if (!w) return { verdict: 'unknown', note: 'no swarm world' }
    let h = this.Swarm_beat_health(w)
    if (!h) return { verdict: 'unknown', note: 'no reading' }
    if (h.state === 'stuck') return { verdict: 'wrong', note: String(h.why || 'the share beat is stuck') }
    return { verdict: 'ok', note: h.state === 'slow' ? String(h.why || 'running long') : '' }

Swarm_beat_health(w):
    if (!w || !w.c.share_up) return { state: 'ok', phase: '', for_ms: 0, why: 'share is down' }
    let order = ['cull', 'tour', 'flush', 'peers', 'keep']
    let far = this.Swarm_beat_phase(w)
    let next = order[order.indexOf(far) + 1] || order[0]
    let since = Date.now() - (+(w.c.phase_at || Date.now()))
    // a beat that is not even in flight cannot be wedged — it is simply between beats.
    if (!w.c.share_beat_running) return { state: 'ok', phase: next, for_ms: since, why: 'idle between beats' }
    // the phase we are WAITING ON is the one after the furthest completed one.
    let typical = +((w.c.phase_avg || {})[next] || 0)
    let K = +(w.c.beat_stuck_k || 20)
    let floor_ms = (w.c.beat_stuck_floor_ms == null ? 30000 : +w.c.beat_stuck_floor_ms)
    let bar = Math.max(floor_ms, typical * K)
    if (since > bar) return { state: 'stuck', phase: next, for_ms: since, why: `${next} has not completed in ${Math.round(since / 1000)}s (typical ${typical}ms)` }
    if (since > bar / 3) return { state: 'slow', phase: next, for_ms: since, why: `${next} running long (typical ${typical}ms)` }
    return { state: 'ok', phase: next, for_ms: since, why: '' }

// Swarm_detached_health — §4b: the blind spot the detaches INTRODUCED.  A detached verb that never
//  settles leaves `flying` set forever while the beat sails past it looking perfectly healthy, so the
//   phase cursor above can report `ok` on a tab whose conveyor died. Judged the same way: against its
//    own learned duration, never a constant.
// ── Swarm_watch_loop — TIER ONE OF THE SOUND SUPERVISOR, AND IT MUST NOT BE A REQ ──
//  The design this replaces had the verdict carried by a `%Watch` req. That is wrong, and the daemon
//   session caught it: a req runs in `reqy(w).do()`, which runs in the belief pass, which runs UNDER
//    THE BELIEFS MUTEX. So a req-based watchdog is **queued behind the very wedge it exists to
//     detect**. Their reading off the daemon says it outright:
//        "drain_why": "beliefs mutex held 8s by H:Mundo fn:swarm_share_beat"
//        "queued": ["fn:handle_inbound", "think"]
//    `think` IS the belief pass. A supervisor in that queue reports nothing until the wedge clears,
//     at which point there is nothing left to report. I had worried about a watchdog CAUSING a wedge
//      and not about one BEING wedged.
//  WHY A PLAIN TIMER ESCAPES IT: a stuck `await` still lets timers fire (only a stuck `while(true)`
//   would not), and every wedge on the list is await-shaped — a detached verb that never settles, a
//    drive that never schedules, a socket that never answers. `Swarm_share_loop`'s own
//     `setTimeout(tick, 600)` demonstrates the seam: the TICK fires regardless of the mutex; only the
//      `post_do` inside it queues. So this loop uses the same outer timer and **never calls post_do,
//       never bumps, never writes sc** — it reads `.c` counters, which are plain JS objects needing no
//        mutex, and writes its verdict back to `.c`. It cannot be blocked by, and cannot block, the
//         machine it watches.
//  TIER TWO IS NOT THIS AND CANNOT BE: a tab wedged badly enough to matter cannot answer a
//   `runner_ask health` op either — "advertises, won't answer pings" is on the very list of wedges.
//    The external tier has to watch WITHOUT ASKING (the daemon, tracking per-peer `seq` monotonicity
//     over a socket that stays open), and it belongs in `scripts/daemon/main.ts`'s hand-cranked loop,
//      NOT the daemon's own belief loop — which is the thing that held the mutex for 8s.
//       See spec/Supervisor_todo.md §4/§6.
//  NOTICE ONLY. It logs and stamps. No reload, no user-visible action, nothing that could surprise a
//   listener — the consent question only bites at the `act` rung and this never reaches it.
Swarm_watch_loop(w):
    w.c.watch_era = (w.c.watch_era || 0) + 1
    let era = w.c.watch_era
    const tick = () => {
        if (era !== w.c.watch_era) return
        try { this.Swarm_watch_look(w) } catch (er) {}
        setTimeout(tick, 2000)
    }
    setTimeout(tick, 2000)

// Swarm_watch_look — one pass. Transition-triggered, never a repeating shout: a supervisor that
//  reprints every 2s trains people to filter it out, which is how the ⏳ skip line became furniture.
Swarm_watch_look(w):
    let v = this.Swarm_beat_health(w)
    let bad = v.state === 'stuck' ? v : null
    if (!bad) {
        let d = this.Swarm_detached_health(w)
        if (d.length) bad = d[0]
    }
    let now = bad ? (bad.phase + ':' + bad.state) : ''
    w.c.watch = bad || v
    // AND HAND IT TO THE SUPERVISOR.  `w.c.watch` has been stamped here every 2s since 2026-08-08 with
    //  NOTHING ANYWHERE READING IT — the console.log below is the only consumer, and it talks to a
    //   console nobody has open.  Registering is idempotent, so doing it from inside the loop keeps
    //    the watch alive across a Supervisor that stood up after this loop did.
    let sup = this.Supervisor_w ? this.Supervisor_w(this.top_House()) : null
    if (sup) this.Supervisor_watch(sup, 'swarm.beat', 'your share is keeping itself up to date', 'standing', 'Swarm_probe_beat', w, this.Supervisor_stage('share'))
    // …and the same courtesy for the two watches that only ever register at standup — see
    //  Swarm_watch_repair for why they go missing and why this is guarded rather than blind.
    if (sup) this.Swarm_watch_repair(w, sup)
    if (now === (w.c.watch_said || '')) return
    w.c.watch_said = now
    if (!now) return
    // NAME THE ORGAN. A verdict that says only "something is wrong" spends the one thing this whole
    //  session proved valuable — every finding today came from phase attribution, not from knowing a
    //   stall existed. The median is printed beside it so a reader can judge the judgement.
    console.log(`👁 SoundSupervisor: ${bad.why} — the beat has not advanced past this phase. Reload clears it if it does not self-heal.`)

Swarm_detached_health(w):
    let out = []
    for (const it of [{ k: 'cull', fly: w.c.cull_flying, bg: w.c.cull_bg_ms }, { k: 'tour', fly: w.c.tour_flying, bg: w.c.tour_bg_ms }]) {
        if (!it.fly) continue
        let since = Date.now() - (+(it.fly || Date.now()))
        let bar = Math.max((w.c.detached_stuck_floor_ms == null ? 180000 : +w.c.detached_stuck_floor_ms), (+(it.bg || 0)) * 4)
        if (since > bar) out.push({ state: 'stuck', phase: it.k + '(detached)', for_ms: since, why: `${it.k} has been flying ${Math.round(since / 1000)}s (last completed ${+(it.bg || 0)}ms)` })
    }
    return out

Swarm_share_loop(w, ident):
    w.c.share_era = (w.c.share_era || 0) + 1
    let era = w.c.share_era
    const tick = () => {
        if (era !== w.c.share_era || !w.c.share_up) return
        if (w.c.share_beat_running) {
            w.c.share_beat_skipped = (w.c.share_beat_skipped || 0) + 1
            if (w.c.share_beat_skipped % 10 === 1) {
                // carry the SPLIT into the skip line: this counter climbing is the symptom everyone
                //  pastes, and until 2026-08-08 it named no cause.  cull/tour are disk+dig, peers is the
                //   offer loop, keep is Heist_keep_beat — the whole heist driver, awaited inline.
                let sp = w.c.beat_split || {}
                // READ THIS AS A PROGRESS BAR, NOT A COST TABLE.  beat_split is zeroed at the top of
                //  each beat and each phase stamped only on completion, so the LAST NON-ZERO field is
                //   where the in-flight beat got to — an all-zero line means it never finished phase 1.
                console.log(`⏳ Swarm_share_beat still running past 600ms — skipping this tick (×${w.c.share_beat_skipped} so far) — the last non-zero field below is how FAR the stuck beat got · cull=${+(sp.cull || 0)} tour=${+(sp.tour || 0)} flush=${+(sp.flush || 0)} peers=${+(sp.peers || 0)} (pump=${+(sp.pump || 0)} warm=${+(sp.warm || 0)}) keep=${+(sp.keep || 0)} · detached: cull_bg=${+(sp.cull_bg || 0)}${w.c.cull_flying ? '(flying)' : ''} tour_bg=${+(sp.tour_bg || 0)}${w.c.tour_flying ? '(flying)' : ''} · lead=${+(w.c.lead_s || 0)}s restock_held=${+(w.c.restock_held || 0)} (ms)`)
            }
        } else {
            w.c.share_beat_running = true
            this.post_do(async () => {
                if (era !== w.c.share_era) { w.c.share_beat_running = false; return }
                let t0 = Date.now()
                try { await this.Swarm_share_beat(w, ident) } catch (er) { this.Swarm_share_why(w, er) }
                // RELEASE THE GUARD FIRST, ALWAYS.  Anything that runs between the beat and this line is a
                //  potential permanent freeze: a throw here never reaches the reset, `share_beat_running`
                //   stays true, and the busy guard skips EVERY subsequent tick — the share loop, and with it
                //    the whole heist, stops dead with no error anyone sees.  (Learned the hard way the same
                //     day the electrode below was added.)  Instrumentation goes AFTER the reset, wrapped.
                w.c.share_beat_running = false
                // SUPERVISOR STEP 1 (Supervisor_todo §4a): fold this beat's phase costs into their
                //  rolling centres and move the phase cursor.  AFTER the guard reset and wrapped, for
                //   the same reason the electrode below is: a throw between the beat and the reset is a
                //    permanent freeze, and a watchdog that can wedge the thing it watches is worse than
                //     none.  Cheap — five numbers and a comparison, no allocation per beat.
                try { this.Swarm_beat_note(w) } catch (er) {}
                // ELECTRODE (2026-08-05) — BEAT HEALTH, and it is silent in health.  A beat that outruns the
                //  600ms cadence makes the NEXT tick get skipped by the busy guard above, which is how a long
                //   landing steals the very window the OVERLAP pre-ask needed.  `ms` is this beat, `skips` is
                //    the running skip count — a gap in the heist with `ms` spiking here and `skips` climbing is
                //     that story; a gap with beats staying under 600ms means the cost is elsewhere (see the
                //      heist's own `ready` mark for the source round trip).
                let ms = Date.now() - t0
                if (ms > 600 && typeof this.Radio_trace === 'function') {
                    let sp = w.c.beat_split || {}
                    try { this.Radio_trace(null, { ev: 'beat', ms: ms, skips: +(w.c.share_beat_skipped || 0), cull: +(sp.cull || 0), tour: +(sp.tour || 0), peers: +(sp.peers || 0), pump: +(sp.pump || 0), warm: +(sp.warm || 0), keep: +(sp.keep || 0), cull_bg: +(sp.cull_bg || 0) }) } catch (er) {}
                }
            }, { see: 'swarm_share_beat' })
        }
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
    // BEFORE IT GOES OUT (the human's v1.0 ruling, 2026-08-06): check every Record in the shuffle
    //  Mag still has its source, and delete the ones that don't.  Here rather than inside
    //   Ra_offer_stock deliberately — that verb is also a Book's (Radiation.g:904/1291), and a
    //    disk-touching cull in it would move fixtures; the share beat is live-only, so this stays
    //     out of every Book by construction.  Once per beat (self-throttled to 30s inside), ahead
    //      of the friend loop: the Mag is the same for every friend, so checking it per friend
    //       would only repeat the work.  The drop shrinks the record count, which changes the
    //        offer `mark` below — so a cull re-offers by itself and the friend's mirror learns.
    // THE BEAT SPLIT (2026-08-08) — where the 600ms actually goes.  The electrode in Swarm_share_loop
    //  has reported a TOTAL `ms` since 2026-08-05, which proves the beat outran its cadence and says
    //   nothing about which of its four phases did it — and the phases are wildly different animals: two
    //    awaited disk/dig verbs, a per-friend offer loop, and `Heist_keep_beat`, which is the WHOLE heist
    //     driver awaited inline (its own comment concedes "cheap when no keep stands", i.e. not cheap when
    //      one does).  The 2026-08-08 console showed ×221 skipped ticks with no way to tell them apart.
    //  Four numbers cost four Date.now() calls per beat and turn the next paste into an answer instead of
    //   a suspicion.  Written to `.c` (runtime, never encoded) and read by the loop's electrode + skip log.
    let tmark = Date.now()
    w.c.beat_split = { cull: 0, tour: 0, flush: 0, peers: 0, keep: 0, cull_bg: +(w.c.cull_bg_ms || 0), tour_bg: +(w.c.tour_bg_ms || 0) }
    // ── THE CULL FLIES DETACHED (2026-08-08) — the split's first verdict, and it was the cull ──
    //  Measured on the human's tab: `cull=8475`, `cull=12327`, `cull=29671` with tour/peers/keep all 0.
    //   So the ×221 skipped ticks were ONE phase, and not the one I suspected (I had written the heist
    //    keep beat up as the likely culprit in Composition_todo §3.6 — the electrode refuted me).
    //  WHY IT IS SO SLOW: `Ra_source_alive` is an awaited FSA directory expand PER RECORD, walked
    //   serially over the whole shuffle Mag.  On a 539-directory crate that is hundreds of serial disk
    //    round trips.  Its 30s throttle bounds how OFTEN it starts, not how long it holds the beat — and
    //     at 29.7s it very nearly runs back-to-back with itself.
    //  WHY THAT STARVES THE MUSIC: everything the radio eats is DOWNSTREAM of this await —
    //   `Ra_transcode_pump` (the encoder frontier, so the 32s preview boundary never advances),
    //    `Ra_mag_warm`, `Ra_restock_beat`, and the full-length lead pass.  A janitor sweep was holding
    //     the supply chain hostage for up to half of every 60 seconds.  That is the starvation.
    //  THE FIX IS THE CALL, NOT THE SWEEP: the cull is a JANITOR — nothing in this beat reads its
    //   result, and its own comment already says "a cull re-offers by itself" because the drop changes
    //    the offer mark on a LATER beat.  So it does not need to be awaited here; it needs to not be in
    //     the way.  One in flight at a time (`cull_flying`), and its duration still gets reported, now as
    //      `cull_bg` — detaching a slow thing must not also make it invisible.
    //  Concurrency is the ordinary `o()` snapshot rule: the cull collects THEN drops, and every other
    //   walker here iterates its own fresh `o()` array, so a detached drop cannot corrupt a live walk.
    this.Swarm_cull_detached(w, rw, stock)
    w.c.beat_split.cull = Date.now() - tmark
    tmark = Date.now()
    // AND KEEP THE WINDOW MOVING (the owner's conveyor, 2026-08-07): spawn at the end, whittle off
    //  the top, so a friend tours the whole collection instead of its first rooms.  Here beside the
    //   cull for the same reason that one is here — the share beat is the live-only seam, so no
    //    Book can ever see a spontaneous dig — and BEFORE the offer below, so a turn of the wheel
    //     re-offers on the same beat it happens rather than waiting out the floor.
    // ── AND THE TOUR FLIES DETACHED TOO (2026-08-08, the SAME disease one organ along) ──
    //  The reading that convicted the cull convicted this next, and the tell was every phase reading
    //   ZERO while the beat overran ×241.  That is not "the beat is fast" — `beat_split` is zeroed at
    //    the TOP of each beat and each phase is stamped only when it FINISHES, so an all-zero split
    //     means the beat is wedged BEFORE the first stamp lands.  `cull=0` is now honest (the kick is
    //      sync); the first thing after it that can hang is this tour.  Same signature was already in
    //       the pre-detach paste (`cull=8475 tour=0 …`), so the tour stall PREDATES the retire flush
    //        below — it was simply hidden behind a cull that hogged the beat first.
    //  WHY IT IS SAFE TO DETACH: nothing in the beat reads a return value. The offer `mark` reads
    //   `Stoker%toured` off the particle, so a turn of the wheel is picked up by whichever beat runs
    //    after it lands — one beat later, which is exactly what the mark is for.
    //  WHAT THIS UNBLOCKS: everything downstream — the offer loop, `Ra_transcode_pump` (and with it
    //   the 32s ceiling), `Ra_mag_warm`, `Ra_restock_beat`, the lead pass. A wedged tour meant a tab
    //    that never offered and never transcoded, which is precisely "neither is taking the other's
    //     stream" with a healthy-looking relay.
    this.Swarm_tour_detached(w, rw, stock)
    w.c.beat_split.tour = Date.now() - tmark
    tmark = Date.now()
    // …AND TELL THE MIRRORS WHAT THE WHEEL DROPPED (2026-08-08, §3.9): the tour ledgers every
    //  whittled id on `stock.c.retire_due`; flush it to every registered caster as the wire's own
    //   op:delete line (Repli_retire — built, Book-proven, and never called live until today).
    //    Without this every drop leaves a stale mirror that asks for the dead id forever — the
    //     symmetric `serve want … no record for id` storm.  TIMED SEPARATELY (`flush`) rather than
    //     folded into `tour`: I added it minutes before this stall was read, and a mark that cannot
    //      exonerate my own newest edit is worth nothing.
    if (typeof this.Repli_retire_flush === 'function') await this.Repli_retire_flush(w, me, stock)
    w.c.beat_split.flush = Date.now() - tmark
    tmark = Date.now()
    this.Swarm_boast_floor(w, ident)
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
        // the tour count rides the mark because the count ALONE cannot see a rotation: a turn of the
        //  wheel that adds one and drops one leaves `n` identical, so a pure-count mark would call a
        //   completely different catalog "unchanged" and sit on it until the 60s floor tripped.
        let tour = String(rw.o({ Stoker: 1 })[0]?.sc?.toured || 0)
        let mark = String(w.c.station_era || 0) + ':' + String(route.c.peer_era || 0) + ':' + n + ':' + tour
        // ── THE RE-OFFER FLOOR (2026-08-04) — the last-resort backstop under the whole epoch machine ──
        //  Everything above makes "A learns B was reborn" robust; this makes "A stops sending B new
        //   music" structurally impossible even if all of it fails.  The mark is CHANGE-triggered, so a
        //    mark that is wrong-but-stable (a missed era, a mirror that lost the husks, a stock count
        //     that happens to match) is a silent permanent hole with no self-heal at all.  A floor turns
        //      any such hole into a delay of at most one interval.  Cheap: husk fragments only (no
        //       bytes), and Repli_merge dedups the whole thing at the far side — a re-offer costs the
        //        wire one catalog fragment per friend per minute, and buys an unconditional guarantee.
        let floor = (w.c.swarm_offer_floor_ms == null ? 60000 : +w.c.swarm_offer_floor_ms)
        let stale = !route.c.offered_at || (Date.now() - route.c.offered_at) > floor
        if (route.c.offered_mark !== mark || stale) {
            route.c.offered_mark = mark
            route.c.offered_at = Date.now()
            await this.Ra_offer_stock(w, route, me, pub, stock)
        }
    }
    for (const peering of w.o({ Peering: 1 })) await peering.do()
    // FINER GRAIN under `peers` (2026-08-08, hours after the split shipped): the four-way split
    //  convicted the cull in one paste, but its `peers` bucket spans the offer loop, the Peering
    //   drains, THE TRANSCODE PUMP, the warm/restock walk, and the lead pass — so it cannot say what
    //    the pump itself costs, and the pump is the verb the 32s ceiling hangs off.  Two more marks
    //     (`pump`, `warm`) cut that bucket into the pieces that matter; `peers` keeps its meaning as
    //      "everything in this bucket", so old readings stay comparable.
    w.c.beat_split.pump = 0
    w.c.beat_split.warm = 0
    let pmark = Date.now()
    if (typeof this.Ra_transcode_pump === 'function') await this.Ra_transcode_pump(w)
    w.c.beat_split.pump = Date.now() - pmark
    pmark = Date.now()
    // ── THE TRACK IN YOUR EARS BEATS THE ONE THAT MIGHT BE NEXT (the human 2026-08-08: "are we just
    //  prioritising stuff like crap?" — yes, we were, and their tab proved it) ──
    //  MEASURED on the live tab: FIVE distinct records held parked wants at the caster simultaneously
    //   (`waiting=` climbing past 30), four of them stalled at off=16 for 95–324s while exactly one
    //    advanced. Only ONE of those five was in anybody's ears. `Ra_restock_beat` deepens previews
    //     across the WHOLE mirror crate every beat, so the playhead's asks queue behind a pile of
    //      speculative ones — and the source's pump, which spends a bounded budget per record per
    //       beat, then spreads that budget across all five. Nobody was prioritising anything.
    //  THE LADDER, in the owner's own words: "prioritise the current track over the potential next
    //   track, unless we're >16s ahead". The lead pass already spends its ASK budget on that ladder;
    //    this applies the same rule one level up, to whether the speculative traffic runs at all.
    //  `warm` is deliberately NOT gated: it is chunk 0 of two records per mirror — the dial's whole
    //   domain ([[dial-domain-is-the-warm-window]]), so starving it would leave the radio with
    //    nothing to turn TO, which is a worse failure than a thin lead. Only the deep restock waits.
    //  Reads the PREVIOUS beat's lead (the leg that computes it runs below, ~600ms later). Staleness
    //   is the point of `lead_at`: no fresh stamp ⇒ nothing is playing ⇒ no gate, restock full speed.
    let lead_fresh = w.c.lead_at && (Date.now() - w.c.lead_at) < 3000
    let hungry = lead_fresh && +(w.c.lead_s || 0) < 16
    w.c.restock_held = hungry ? (+(w.c.restock_held || 0)) + 1 : 0
    for (const home of rw.o({ MusuThem: 1 })) {
        if (!home.sc.pub) continue
        let shelf = this.Ra_home_them(rw, String(home.sc.pub))
        // the §5 warm start FIRST (2 records × their opening page — autostart-ready fast),
        //  then the restock deepens whole previews behind it.
        await this.Ra_mag_warm(w, shelf)
        if (!hungry) await this.Ra_restock_beat(w, shelf, 2)
    }
    w.c.beat_split.warm = Date.now() - pmark
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
        // presence only (2026-08-05): this loop tests `map[off] == null` and nothing else.  Ra_chunk_map
        //  COPIED every held chunk of the playing record on EVERY beat — inside the very beat the console
        //   was reporting as overrunning 600ms ("skipping this tick ×71").
        let map = this.Ra_chunk_have(playing)
        w.c.ra_wanted = w.c.ra_wanted || {}
        w.c.ra_want_ts = w.c.ra_want_ts || {}
        let nowms = Date.now()
        // THE LEAD LADDER (2026-08-08, the owner: "the main cause is not prioritising the Records
        //  enough … prioritise the current track over the potential next track, unless we're >16s
        //   ahead").  The ask budget was a FLAT 3 per beat whether the playhead had 30 seconds of
        //    audio banked or two — which is the definition of not prioritising: a comfortable track
        //     spent exactly the same wire as a starving one.  Count the CONTIGUOUS chunks held from
        //      the head (a hole ends the lead — audio past a gap is not lead, it is after the gap)
        //       and spend accordingly:
        //        under 8s banked  → 6 asks, we are nearly dry and nothing else matters;
        //        under 16s banked → 3 asks, the old constant, holding station;
        //        16s or more      → 1 ask, just top the window up and leave the wire to everyone else.
        //  That last rung IS the owner's "unless we're >16s ahead": a comfortable current track stops
        //   hogging the beat, which is what leaves room for the next track's pages and the heist.
        //  seg_s is per chunk (2s), so 4 chunks = 8s, 8 chunks = 16s — the ladder is in SECONDS, and
        //   is written in chunks here only because the map is.
        let lead = 0
        while (map[head + lead] != null && lead < 64) { lead = lead + 1 }
        let lead_s = lead * seg_s
        let budget = 6
        if (lead_s >= 16) { budget = 1 } else if (lead_s >= 8) { budget = 3 }
        w.c.lead_s = lead_s        // off-snap, for the electrode + the Brink to read
        // STAMPED, so a LATER beat can tell "the playhead is comfortable" from "nobody is playing".
        //  A bare lead_s is indistinguishable between the two the moment the radio stops, and the
        //   restock gate below would then throttle itself forever off a corpse reading.
        w.c.lead_at = nowms
        let asked = 0
        let off = head - (head % PAGE)
        while (off < total && off < head + 16 && asked < budget) {
            // PAGE-WIDE, not the stride-aligned chunk alone (Ra_page_hole, Ra.g).  A live-window page
            //  that lost ONE of its chunks to the relay's bulk-lane shed read as held here, so the
            //   playhead ran into a hole this loop had already decided was filled — and re-asked nothing.
            if (this.Ra_page_hole(map, off, PAGE, total)) {
                let key = String(playing.sc.id) + ':' + off
                // RE-ASKABLE live-window want (the starve fix, the human 2026-07-28 "both go into 'the
                //  next piece hasn't arrived' mode after a little while"): a want lost to the wire (a
                //   dropped reply, a reused-seq inbox collision — the Peeroleum hazards) used to be
                //    re-askable ONLY on a full peer rebirth, so ONE lost page starved the live playhead
                //     until reconnect — a hole that never clears.  Re-ask a still-missing live-window
                //      page every 4s (bounded by asked<3/beat + the head+16 window), so a lost page
                //       self-heals in a few seconds instead of dropping the audio.  ra_want_ts carries
                //        the last-ask stamp beside the once-cursor; both clear on the same rebirth reset.
                //  …AND THE RE-ASK INTERVAL RIDES THE LADDER TOO (2026-08-08).  A flat 4s was the last
                //   constant in this loop, and it is the cruellest one when the playhead is nearly dry:
                //    at seg_secs=2 it means a lost page costs FOUR SECONDS — two whole chunks of silence
                //     — before anyone asks again, which is most of the 6s starve grace in Radio.g:439.
                //      Under 8s banked, chase it every 1.5s; otherwise keep the 4s that was tuned for a
                //       comfortable stream and which exists to stop a re-ask storm on a healthy wire.
                let again_ms = lead_s < 8 ? 1500 : 4000
                let last = w.c.ra_want_ts[key] || 0
                if (nowms - last > again_ms) {
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
    w.c.beat_split.peers = Date.now() - tmark
    tmark = Date.now()
    if (typeof this.Heist_keep_beat === 'function') {
        try { await this.Heist_keep_beat(w, ident) } catch (er) { w.c.heist_beat_why = '' + (er && er.message || er) }
    }
    w.c.beat_split.keep = Date.now() - tmark
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

//#region diag — "what is actually wrong right now?", answered once, for the glass
// Diag_trouble — the single reader behind the trouble badge.  Every entry is a LIVE RE-DERIVATION,
//  never a stored status: a trouble stops being reported because the CONDITION is gone, not because
//   someone remembered to clear a flag.  That matters more than it sounds — a badge that can go stale
//    red teaches the human to ignore the badge, which is worse than having no badge at all.
//  Ordered worst-first, pure read, and defensively wrapped: a diagnostic that can throw takes down the
//   glass it was meant to explain, so EVERY probe is independently caught and a broken probe simply
//    reports itself rather than silencing its siblings.
//  lvl: 'x' = will not self-heal without intervention;  '!' = degraded but self-healing.
Diag_trouble(w):
    let out = []
    if (!w) return out

    // ── the consent state of each link.  A HALF-SEALED %Pier is the cruellest failure we have: every
    //     outbound ask still leaves, the peer still answers, and the answers are dropped on arrival for
    //      want of a Pier to route them through.  Both ends therefore look merely SLOW — which is why
    //       this one deserves the top of the list and a sentence that names the asymmetry out loud.
    //  MY OWN pub rides `.c.keys`, NEVER `sc` (the human 2026-08-06: BOTH ends of the same link read
    //   "we never granted back" — a symmetric accusation nobody can act on, and impossible if it were
    //    true).  `Swarm_identity` puts the pair on `.c.keys` and only `prepub` in sc, and `Swarm_import`
    //     explicitly DELETES sc.pub/sc.key after thawing — so `self.sc.pub` is undefined on every live
    //      identity there has ever been.  `mine` was therefore always '', `got_mine` always null, and
    //       every whole pier holding their grant got reported half-sealed forever.  The same read burned
    //        `Radio_pub` (its comment: "the old c.keys.prepub read was ALWAYS undefined") in the other
    //         direction — sc has the prepub, .c.keys has the pub, and neither store has both.
    //  Read it the way the SELF-HEALER does (`Swarm_reaccept_incomplete`: `ident.c.keys.pub`) — which is
    //   also why the condition never healed: the healer was looking at the real grant and finding it
    //    present, while the badge was looking at a blank string and finding nothing.  With no live keys
    //     at all we cannot judge consent, so say nothing rather than accuse both ends (`bail`).
    try {
        let self = this.Swarm_live_self()
        let peering = self ? this.Swarm_peering(self) : null
        let mine = self && self.c.keys ? String(self.c.keys.pub || '') : ''
        for (const pier of (mine && peering ? peering.o({ Pier: 1 }) : [])) {
            let peer = pier.o({ Peering: 1 })[0]
            let theirs = peer ? String(peer.sc.pub || '') : ''
            if (!theirs || theirs === mine) continue
            let got_mine = pier.o({ Grant: 1, by: mine })[0]
            let got_theirs = pier.o({ Grant: 1, by: theirs })[0]
            if (got_mine && got_theirs) continue
            let who = pier.sc.friendly || theirs.slice(0, 8)
            out.push({ lvl: 'x', key: 'halfseal', text: `half-sealed link to ${who} — ${got_theirs ? 'we never granted back' : 'they never granted us'}. Asks leave, answers get dropped; it looks like slowness, it is consent.` })
        }
    } catch (er) { out.push({ lvl: '!', key: 'probe', text: 'seal probe failed: ' + (er && er.message || er) }) }

    // ── frames that reached us and died on the doorstep.  Counted at Peeroleum_deliver's no-Pier drop.
    try {
        let wd = w.c.wire_drop
        if (wd) {
            let total = 0
            let kinds = []
            for (const k of Object.keys(wd)) { total = total + (+wd[k] || 0); kinds.push(k + '×' + wd[k]) }
            if (total > 0) out.push({ lvl: 'x', key: 'wiredrop', text: `${total} frame(s) dropped on arrival — no Pier to route them (${kinds.slice(0, 3).join(' ')})` })
        }
    } catch (er) {}

    // ── a heist that is asking and asking and landing nothing.  The single most common shape of "it's
    //     stuck and I don't know why", and the one the human should never have to read a console for.
    try {
        let shop = this.Ra_home_shop(w, this.Radio_pub(w) || 'me')
        for (const keep of (shop ? shop.o({ Heist: 1 }) : [])) {
            let asks = +(keep.sc.asks || 0)
            if (asks < 3) continue
            let picks = keep.o({ Pick: 1 })
            let landed = picks.filter((p) => p.sc.landed).length
            if (landed >= picks.length && picks.length) continue
            if (landed === 0) out.push({ lvl: 'x', key: 'heist', text: `"${keep.sc.seed || 'heist'}" — 0 of ${picks.length} landed after ${asks} asks. Nothing is arriving.` })
        }
    } catch (er) {}

    // ── the wire is behind: pages queued locally, or shed to stay bounded (see Backpressure §5.1 —
    //     a shed MUST confess, because "sent" upstream has already overcounted by exactly this much).
    try {
        let shed = +(w.c.relay_bulk_dropped || 0)
        let q = +(w.c.relay_bulk_queued || 0)
        if (shed > 0) out.push({ lvl: '!', key: 'shed', text: `${shed} page(s) shed — the wire fell behind. The sink re-asks, but "sent" overcounts by this much.` })
        if (q > 0) out.push({ lvl: '!', key: 'queued', text: `${q} page(s) queued behind the wire — congested, not stalled` })
    } catch (er) {}

    // ── the source parked our want: it is not lost, the encoder frontier just hasn't reached it.
    try {
        let parked = w.c.ra_parked ? Object.keys(w.c.ra_parked).length : 0
        if (parked > 0) out.push({ lvl: '!', key: 'parked', text: `${parked} want(s) parked at the source — waiting on its encoder, not on the wire` })
    } catch (er) {}

    // ── silence where music should be.
    try {
        let radio = w.o({ Radio: 1 })[0]
        if (radio) {
            let drops = +(radio.sc.drops || 0)
            if (radio.sc.Radio === 'starved') out.push({ lvl: 'x', key: 'starved', text: 'the radio is starved — the chunk it needs never arrived and the timeline ran dry' })
            if (drops > 0) out.push({ lvl: '!', key: 'drops', text: `${drops} dropout(s) spliced — real gaps you would have heard` })
        }
    } catch (er) {}

    return out
//#endregion
