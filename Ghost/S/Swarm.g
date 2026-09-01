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
    import { bodykey_read, bodykey_write, vessel_register, vessel_subnet, vessel_drop, vessel_sweep } from "$lib/O/vessel_store"
    import { seal, unseal } from "$lib/O/Funk/Sealbox"
    import { sas_transcript, sas_row } from "$lib/O/Funk/Emojiconfirm.ts"

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

// Swarm_invite_note — THE %Invite AUTOVIVIFY (Portability §7, ruled 2026-08-27: "there is no
//  %Invite particle? I always think of them").  An invite used to be smeared across the issuer's
//   %Idzeug, a token string in a URL, and the landed %Grant — everyone THINKS in invites, so the
//    data read from a URL now vivifies into a particle with a lifecycle the Door and the glass
//     can show: state walks arrived → redeeming → (sealed|refused land with the Door work).
//  HOMED ON THE STATION WORLD, deliberately: w:Swarm is session furniture — Swarm_export walks
//   the %Identity subtree only, so a %Invite here can never ride an account snap, and no Book
//    stands a station, so no fixture can see one.  The issuer's own record remains the law
//     (§10.1); this particle is the VISITOR's copy of the claim, never a second truth.
//  Token legs: serial+prepub on sc (the identity of the offer), n on sc; the presig leg rides
//   .c — a raw signature fragment is not furniture worth snapping.
Swarm_invite_note(w, tok):
    if (!w || !tok) return null
    let t = this.Swarm_token_parse(tok)
    if (!t) return null
    let inv = w.oai({ Invite: t.serial, prepub: t.prepub })
    inv.c.up = w
    if (t.to) inv.sc.to = t.to
    inv.sc.n = String(t.n)
    if (!inv.sc.state) inv.sc.state = 'arrived'
    inv.c.presig = t.presig
    inv.bump()
    return inv

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
    // ONLY A MUSIC FRIEND CAN "COME ONLINE" (2026-08-28, the device-link false-red).  This armed on ANY
    //  pier, but the probe it arms (Swarm_probe_arrival) only counts a pier LIVE ON MUSIC — so a device-link
    //   pier, which bears a `MyCave` grant and no Music, armed an expectation it could never satisfy: a fresh
    //    Cave whose only pier is its own soul reported `nobody has come online` forever ("eed sees Grauc, but
    //     Grauc says a friend came online : FAILED").  A Cave is your OWN device, not a friend.  So filter to
    //      friend piers — the `Grant:'Music'` child is the same tell the Door reads to draw a friend at all —
    //       which drops Cave|Captain body piers on BOTH ends and leaves every music friendship untouched.
    let piers = (this.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []).filter(p => p.sc.pub && String(p.sc.pub) !== me && p.o({ Grant: 'Music' })[0])
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
    let frag = hash >= 0 ? s.slice(hash + 1) : ''
    if (hash >= 0) s = s.slice(0, hash)
    let at = s.indexOf('?')
    let q = at >= 0 ? new URLSearchParams(s.slice(at + 1)).get('Iz') : null
    if (q) return q
    // ANCHOR FORM (2026-08-30): the device link now rides wholly in the fragment (`#Iz=<token>&fc=<secret>`)
    //  so the token never reaches a server and landing is navigation-free.  The fragment parses as params;
    //   a `#frag?Iz=x` chat-mangled shape still refuses (its key is 'frag?Iz', not 'Iz') — the old caution holds.
    if (frag) { let f = new URLSearchParams(frag).get('Iz'); if (f) return f }
    return null
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
    // THE SEAT RESOLVES TO THE SOUL: a sibling-addressed frame arrives `to: <prepub>_N` (the suffixed
    //  seat a second body holds on the relay — Swarm_sibling_send's road).  The seat is an address of
    //   the SAME identity, so strip the suffix and resolve the bare name.  A prepub is hex, so `_` can
    //    only be a seat suffix; exact matches above always win.
    let base = String(prepub || '').split('_')[0]
    if (base && base !== prepub) { return this.Swarm_account_of(w, base) }
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
        // A CLAIM IN MY OWN NAME (Phase 4 rung 1 — Persistence_todo §5.4, Identity_persist §7.4):
        //  a standing-body frame whose signed page prepub IS the recipient's own means a SECOND live
        //   body of this identity is on the wire (the eed831f1 disease: a browser body and a daemon
        //    body of one prepub, each mirroring blind, invisible to each other until this moment).
        //     Note it — a registered %Sibling stays cooperative, note_theft returns false and no
        //      alarm rises — and DROP the frame: a body must never process itself as a peer.
        //  NO AUTO-YIELD (§7.4h ruling): the incumbent keeps the name and the write; the alarm is a
        //   DoorFace banner + a diag fact, and Steal Back stays a human move.  Standing kinds only —
        //    a multicast gossip echo must never raise a theft alarm.
        if (from && from === ident.sc.prepub && ['pier_hello', 'swarm_hi', 'pulse'].includes(frame.header.type)) {
            // A ROSTERED SIBLING'S PULSE IS PRESENCE, NOT THEFT (owner 2026-08-31: "not clear that
            //  the two of them can see each other").  The sibling pulse carries `body` — the sender's
            //   roster key — so stamp `heard` ON the %Body row (a standing particle the family box
            //    reads; its wobble is Entcase matter, never a reason to hide it on .c) and note its
            //     live seat.  Only an UNROSTERED claimant still raises the theft alarm.
            let sib_body = frame.swarm && frame.swarm.body ? String(frame.swarm.body) : ''
            let sib_row = sib_body ? this.Swarm_body_roster(ident).find((b) => String(b.sc.pub) === sib_body) : null
            if (sib_row) {
                sib_row.sc.heard = this.Swarm_now(w2)
                if (frame.swarm.addr && String(sib_row.sc.address || '') !== String(frame.swarm.addr)) { sib_row.sc.address = String(frame.swarm.addr) }
                sib_row.bump()
                return false
            }
            let by = String(frame.header.from || 'unknown_place')
            if (this.Swarm_note_theft(ident, by, null)) console.log('👥⚠ another live body of ' + String(ident.sc.prepub).slice(0, 8) + ' is on the wire (' + by + ') — name contested. This body keeps the write; resolution is the human\'s (close one body, or Steal Back).')
            return false
        }
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
        if (sealed) {
            // the presence EDGE (silent → speaking) pays the %Owed ledger — the one moment a re-send
            //  is worth anything.  A mid-conversation frame is no edge and costs nothing here.
            let owed_edge = !sealed.c.heard_at || (Date.now() - sealed.c.heard_at) > 30000
            sealed.c.heard_at = Date.now()
            if (owed_edge) { try { this.Swarm_owed_settle(w2, ident, sealed) } catch (er) {} }
        }
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
            let ephemeral_lane = frame.header.type === 'pulse' || frame.header.type === 'swarm_hi' || frame.header.type === 'ferry_want' || frame.header.type === 'ferry_cancel'
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
        if (frame.header.type === 'charter') await this.Swarm_charter_heard(w2, ident, frame.swarm)
        // the cross-body procedure lane (Reach_todo): a sibling books work on me / tells me the outcome.
        if (frame.header.type === 'reach') this.Swarm_reach_road(w2, ident, frame.swarm)
        if (frame.header.type === 'reach_done') this.Swarm_reach_ack(w2, ident, frame.swarm)
        if (frame.header.type === 'adopt_seal') this.Swarm_adopt_park(w2, ident, frame.swarm)
        if (frame.header.type === 'adopt_confirm') await this.Swarm_adopt_confirmed(w2, ident, frame.swarm)
        if (frame.header.type === 'ferry') this.Swarm_ferry_park(w2, ident, frame.swarm)
        // FERRY WANT — a Linkee's steady "I want linkage" ask (Swarm_ferry_ask): the far mirror of the seal-seam.
        //  It keeps the Linkor (me) focused on the confirm no matter how MY `.c` was reset — my focus is driven by
        //   the Linkee's standing demand, not by my remembering a one-shot seal.  Only a sealed pier that actually
        //    bears MY MyCave grant, while I still hold the ferry secret (`.c` or durable twin) and am not mid-send,
        //     may re-raise it; on_seal re-checks pier_live+secret and PARKS (humdinger) or sends (runner) as ever.
        if (frame.header.type === 'ferry_want') {
            let wsealed = sealed && this.Swarm_pier_linklive(sealed) ? sealed : null
            let wtop = this.top_House ? this.top_House() : null
            // the ceremony lives on the req now (Ferry_rebuild §4 Stage 3): secret/serial read through the
            //  one accessor pair (live req.c first, durable twin second — the twin fallback IS the reheal).
            let wsec = this.Swarm_ferry_secret() ? 1 : 0
            // THE SINGULAR-ADOPT BINDING (owner 2026-08-31): the ask carries the serial off the Linkee's ?Iz;
            //  we serve ONLY the ceremony whose token we minted (req:Ferry_soul%serial, twin-backed).  A stale
            //   device asking off an OLD ceremony — even warm, even grant-live — is simply "not the adopt I hold".
            //    Back-compat: if either side lacks a serial (mid-migration), don't brick a live ceremony — honor.
            let wser = this.Swarm_ferry_serial()
            let wask = frame.serial ? String(frame.serial) : ''
            let wbound = !wser || !wask || wser === wask ? 1 : 0
            let wsoul = this.Swarm_ferry_role('soul')
            let wfly = wsoul && wsoul.c.ferrying ? 1 : 0
            console.log('🦑 ferry: heard "I want linkage" from ' + String(from || '?').slice(0, 8) + ' — cave_pier=' + (wsealed ? 'yes' : 'no') + ' my_secret=' + (wsec ? 'yes' : 'no') + ' adopt_match=' + (wbound ? 'yes' : 'NO (' + wask.slice(0, 8) + '≠' + String(wser).slice(0, 8) + ')') + ' ferrying=' + (wfly ? 'yes' : 'no'))
            if (wsealed && wsec && wbound && !wfly) {
                // STAMP THE ASKING PIER with THIS adopt's serial + now (owner 2026-08-31: "I go into Link to make
                //  another one, and a preexisting ceremony seems to grab me").  Swarm_ferry_poke parks reactively
                //   off "a warm MyCave pier turned up" — which, on a fresh mint, grabbed an OLD warm cave that never
                //    asked for the NEW adopt.  This stamp is poke's proof that THIS pier is asking for the adopt I
                //     currently hold; poke parks for nobody else, so opening Link to re-mint no longer gets hijacked.
                wsealed.c.ferry_want_at = Date.now()
                wsealed.c.ferry_want_serial = wask
                // the ferry_want is LIVE proof this Cave pier is up NOW — Swarm_ferry_secret() above already
                //  re-derived the live req's `.c.secret` off the durable twin if a reload had dropped it, so
                //   the whole live seam (poke, link_active, the seal-seam, Swarm_ferry_confirm) reads one truth.
                this.Swarm_ferry_on_seal(w2, ident, wsealed).catch((er) => {})
            }
            // ANSWER AN UNSERVICEABLE ASK (owner 2026-08-30/31: "we aren't talking to someone who isn't listening";
            //  "check it runs to the end — logically").  An asker whose grant was REVOKED (the human's "no" →
            //   Swarm_revoke, so it fails the pier_live gate above) — or whose ceremony this side holds no secret
            //    for — used to machine-gun ferry_want into silence forever.  Tell it once per ~30s: ferry_cancel
            //     folds its "connecting…" to the ended screen and its ask stops.  RACE-SAFE by the far guard:
            //      Swarm_ferry_cancelled only folds while ferry_awaiting is set, so a straggler ask racing a
            //       just-landed soul can't kill the ceremony (park deletes awaiting first).  NOT during ferrying
            //        (wsec still set mid-send → this branch can't fire).  Humdinger-gated OR consenter-gated
            //         + wire-driven → Book-inert unless the Book raises top.c.consenter.
            // ⚠ "NOT SEALED YET" IS NOT "NO CEREMONY" (owner 2026-08-31, "it was suddenly called off again"):
            //  the old trigger `!wsealed` cancelled the instant the MyCave grant wasn't LIVE — but in the
            //   healthy redeem the grant seals a beat or two AFTER the cave's first ferry_want lands (the log
            //    that proved it: cave_pier=no my_secret=YES adopt_match=YES — eed holds the secret for the very
            //     adopt this cave is asking about, the seal is IN FLIGHT).  Cancelling there aborts a ceremony
            //      that is about to succeed, and the cave — flung off "connecting…" — falls through to whatever
            //       else it has (a Haul from its own FSA).  So REFUSE only when the ask is provably dead, never
            //        on a merely-late seal: (a) the serial isn't the adopt I hold (`!wbound` — I re-minted), or
            //         (b) I hold no secret at all (`!wsec` — the ceremony ended|was cancelled my side), or
            //          (c) the human REVOKED this cave (a signed %NotGrant:MyCave tombstone under its pier —
            //           Swarm_revoke's durable "no").  When I hold the secret + serial matches + no tombstone,
            //            STAY QUIET: the cave's steady ask is exactly the "I'm here, seal me" the ceremony wants,
            //             and on_seal fires the instant the pier goes live.  The cave never folds on its own; the
            //              human's cancel on THIS device drops the secret (→ `!wsec` → the honest refuse fires).
            let wrevoked = sealed && (sealed.o({ NotGrant: 'MyCave' })[0] || sealed.o({ NotGrant: 'MyCaptain' })[0]) ? 1 : 0
            if ((!wbound || !wsec || wrevoked) && wtop && wtop.c && (wtop.c.humdinger || wtop.c.consenter) && from) {
                // the refuse throttle rides the PUMP req's `.c` (the ceremony req may not exist at all here —
                //  that is often exactly why we refuse), vivified on demand: a wire courtesy, session-local.
                let wh = this.Swarm_ferry_host(1)
                if (wh && !wh.c.refused) { wh.c.refused = {} }
                let wref = String(from).slice(0, 24)
                if (wh && (Date.now() - (wh.c.refused[wref] || 0)) > 30000) {
                    wh.c.refused[wref] = Date.now()
                    this.Swarm_deliver(w2, ident, String(from), { kind: 'ferry_cancel', page: this.Swarm_page(ident) })
                    console.log('🦑 ferry: told ' + String(from).slice(0, 8) + ' there is no ceremony for it here (' + (!wbound ? 'not the adopt I hold' : !wsec ? 'no live secret' : 'the grant was revoked') + ') — it can stop asking; a fresh link is a fresh start')
                }
            }
        }
        // FERRY CANCEL — the soul device called the link off (Swarm_ferry_cancel).  A Linkee awaiting THAT soul
        //  gives up the "connecting…" wait (owner: "eed can only get rid of that by cancelling the token, which 495
        //   then gives up from").  Matched on `from` inside so a stray cancel can't knock out an unrelated adopt.
        if (frame.header.type === 'ferry_cancel') this.Swarm_ferry_cancelled(w2, ident, from)
        // FERRY HELD — the delivery-ack (the beat BEFORE ferry_got): the new device HOLDS the sealed soul
        //  and its consent screen is up.  Fold it into the standing ferry_sent (+ the durable twin, so a
        //   Linkor reload keeps the fact) — the cell's wait ladder reads `held` to say "delivered — they're
        //    looking at the consent" instead of a blind "waiting".  No state is retired here: the ceremony
        //     still ends only at ferry_got / ferry_cancel.
        if (frame.header.type === 'ferry_held') {
            let hs = this.Swarm_ferry_role('soul')
            if (hs && !hs.sc.finished && (hs.sc.phase === 'sent' || hs.sc.phase === 'held')) {
                hs.sc.held_at = this.Swarm_now(w2)
                // 'held' is a pull phase — the phase verb's surface policy upgrades the sent face NOW
                //  (owner 2026-08-30: "responsive all the way to the end"); it bumps + re-stashes the twin.
                this.Swarm_ferry_phase(w2, 'held', { role: 'soul' })
                console.log('🦑 ferry: ✓ delivered — the other device holds the sealed soul, its consent screen is up')
            }
        }
        // FERRY GOT — the receive-ack (task #21): the new device TOOK the soul ON.  Close the ceremony's arc on
        //  this (soul) side: the secret is SPENT (drop it + its durable twin, so no "link in flight" lingers and
        //   no later poke re-parks a confirm for an already-served mint) and leave `ferry_got` for the cell's
        //    "✓ received" lamp.  Only a live Linkee can send it (its consume is humdinger-gated) → Book-inert.
        if (frame.header.type === 'ferry_got') {
            let gtop = this.top_House ? this.top_House() : null
            if (gtop && gtop.c) {
                // the secret is SPENT: drop it off the soul req; the phase walk to 'got' re-stashes (and the
                //  twin drops with it — 'got' is a receipt, not a stashable wait), so no later poke can
                //   re-park a confirm for an already-served mint.  The req stays alive as the ✓ receipt.
                let gs = this.Swarm_ferry_role('soul')
                if (gs) { delete gs.c.secret; delete gs.c.ferrying }
                // 'got' is a pull phase — the ✓ done flip shows itself NOW (the phase verb's policy).
                this.Swarm_ferry_phase(w2, 'got', { pub: String(from || ''), role: 'soul' })
                // FACET D — the Captain FINALISES THE FAMILY ROSTER (the ferry path never did; only the old
                //  adopt finalise rostered).  It takes its OWN %Body,role:Captain wearing the name this human
                //   wrote at ITS name-gate (ident.sc.friendly), and notes the Cave that just acked — the
                //    ferry_got carried the Cave's own body-key pub + chosen name (facet D hand-over above), so
                //     the row is precise, not a guess off the shared soul pub.  Humdinger-gated OR
                //      consenter-gated (Books never roster unless consenter is raised — that keeps facet-D
                //       inert for existing Books; InvWalk's consenter puppet drives it).
                if ((gtop.c.humdinger || gtop.c.consenter) && ident) {
                    let capname = String(ident.sc.friendly || '')
                    // MY OWN role is what I already am (the roster/derive know), not a hardcoded Captain —
                    //  in the MyCaptain recovery ceremony the finalising soul-holder is a CAVE.
                    let fmine = this.Swarm_body_mine(ident)
                    let myrole0 = fmine && fmine.sc.role ? String(fmine.sc.role) : 'Captain'
                    let cap = this.Swarm_body_take(ident, (this.Swarm_body_key(ident)?.pub || ident.sc.prepub), myrole0, this.Swarm_address(ident) || ident.sc.prepub)
                    if (cap && capname && !cap.sc.name) { cap.sc.name = capname }
                    let cavepub = frame.swarm && frame.swarm.body ? String(frame.swarm.body) : ''
                    let cavename = frame.swarm && frame.swarm.name ? String(frame.swarm.name) : ''
                    // THE CONFERRED POST COMES OFF THE CEREMONY GRANT (Division_todo §0a #1): read it from
                    //  the pier the ferry_got rode — grant_post of a MyCaptain rail says Captain.  Never a
                    //   hardcoded 'Cave'.
                    let fpier2 = (this.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []).find((p) => String(p.sc.pub || '') === String(from || ''))
                    let post = (fpier2 ? this.Swarm_grant_post(fpier2) : null) || 'Cave'
                    // the seat: keep an existing row's address; a NEW body takes the next FREE suffix
                    //  (a second linked device must not collide with the first's _1 — owner 2026-08-31,
                    //   the second-incognito test).  Seat ≠ Post: even a new Captain starts suffixed and
                    //    wins the bare name by hello-v2 arbitration, not roster fiat.
                    if (cavepub) {
                        let prior = this.Swarm_peering(ident)?.o({ Body: 1, pub: cavepub })[0]
                        let taken = this.Swarm_body_roster(ident).map((b) => String(b.sc.address || '')).filter((a) => a)
                        let caddr = prior && prior.sc.address ? String(prior.sc.address) : this.Swarm_next_suffix(String(ident.sc.prepub), taken)
                        this.Swarm_body_note(ident, cavepub, post, caddr, cavename)
                        // SUCCESSION EVICTS (§LIFECYCLE: Captain is SINGULAR — a new one always evicts the
                        //  old).  Drop any OTHER Captain row; the re-charter below omits it for everyone.
                        if (post === 'Captain') {
                            for (const oldcap of this.Swarm_body_roster(ident)) {
                                if (String(oldcap.sc.role || '') === 'Captain' && String(oldcap.sc.pub) !== cavepub && oldcap !== cap) {
                                    this.Swarm_peering(ident).drop(oldcap)
                                    console.log('🦑 🪪 old Captain evicted — ' + String(oldcap.sc.pub).slice(0, 8) + ' (a new Captain always replaces the old)')
                                }
                            }
                        }
                    }
                    console.log('🦑 ferry: 🪪 family roster — I am ' + myrole0 + ' ' + (capname || '(unnamed)') + (cavename ? ', linked to ' + post + ' ' + cavename : ''))
                    // ATTEST + PROPAGATE THE DIVISION (2026-08-31, the owner live: "Link ceremony is done now,
                    //  they still don't know each other … as Piers").  The %Body rows just written are the
                    //   RESOLUTION register only — and the ceremony NEVER signed a %Charter over them (verified in
                    //    the InvWalk fixture: the Captain's Body rows land but no Charter row does).  So
                    //     Swarm_charter_wire stayed null, Swarm_charter_gossip sent nothing, and the division died
                    //      LOCAL: no friend of this soul, and no sibling, could ever learn it — the family existed
                    //       only in the Captain's own head.  Sign it now (the WELD — soul-signed, era-stamped
                    //        attestation of the roster) and gossip it to the sealed piers, INCLUDING the fresh
                    //         MyCave pier the redeem just formed to the Cave.  Async is fine (hear is async).  This
                    //          whole block is already humdinger/consenter-gated, so it stays Book-inert except in
                    //           InvWalk (which raises consenter and now records the Charter — the outcome the Book
                    //            never asserted).  ⚠ KNOWN-OPEN (the sibling-sync gap, see Division_todo): the Cave
                    //             has no %Pier for the Captain to ABSORB this charter onto (a body is not a friend),
                    //              so the reverse direction — Cave learning Captain — still needs a sibling channel;
                    //               this closes the Captain's half and unblocks all friend-facing division routing.
                    try { await this.Swarm_charter_sign(ident); this.Swarm_charter_gossip(w2, ident) } catch (e) {}
                    // …and make the family DURABLE now (the fourth stash pillar): without this settle the
                    //  roster+charter lived only in the C tree and the Captain forgot its own division at
                    //   the next reload.  Live-self-guarded inside, so InvWalk's puppet stays Book-inert.
                    try { this.Swarm_account_settle(ident, 'ferry_family') } catch (e) {}
                }
            }
            console.log('🦑 ferry: ✓ the other device took the soul on — ceremony complete, link retired')
        }
        // SEED THE CHARTER AT SEAL (Division_todo step 4), station wire twin of the pump seed above.
        if (frame.header.type === 'pier_accept' || frame.header.type === 'pier_confirm') this.Swarm_charter_gossip(w2, ident, from)
        // LEDGER OUTCOME ⇒ SETTLE (Persistence_todo §5.1): every frame kind that can move the durable
        //  ledger (a seal, a grant, a holder move, a root) settles the account on the way out — stash
        //   convergence AND the disk-mirror nudge in ONE seam, instead of each handler above carrying
        //    its own persistence chores.  Presence/gossip kinds are exempt: they mutate no ledger, and
        //     settling per-pulse would grind a restash on every heartbeat.  (Live-self-guarded inside,
        //      so a Book's mail-wire puppets skip it whole — fixtures unmoved.)
        if (['pier_hello', 'pier_accept', 'pier_confirm', 'reinvite', 'reinvite_honour', 'reinvite_seal', 'reinvite_ok'].includes(frame.header.type)) this.Swarm_account_settle(ident, frame.header.type)
        return true
    }
    for (const kind of ['pier_hello', 'pier_accept', 'pier_confirm', 'pier_reject', 'reinvite', 'reinvite_honour', 'reinvite_seal', 'reinvite_ok', 'ive_got', 'pulse', 'swarm_hi', 'suggest', 'suggest_got', 'repli_ready', 'charter', 'adopt_seal', 'adopt_confirm', 'ferry', 'ferry_want', 'ferry_cancel', 'ferry_got', 'ferry_held']) w.c.on[kind] = hear

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
        if (frame.kind === 'charter') await this.Swarm_charter_heard(w, ident, frame)
        if (frame.kind === 'reach') this.Swarm_reach_road(w, ident, frame)
        if (frame.kind === 'reach_done') this.Swarm_reach_ack(w, ident, frame)
        if (frame.kind === 'adopt_seal') this.Swarm_adopt_park(w, ident, frame)
        if (frame.kind === 'adopt_confirm') await this.Swarm_adopt_confirmed(w, ident, frame)
        if (frame.kind === 'ferry') this.Swarm_ferry_park(w, ident, frame)
        // SEED THE CHARTER AT SEAL (Division_todo step 4): a freshly sealed friend learns my division
        //  now, not at the next change.  No-op for an undivided soul (no Charter to gossip).
        if (frame.kind === 'pier_accept' || frame.kind === 'pier_confirm') this.Swarm_charter_gossip(w, ident, frame.page?.prepub)
    }
    // FERRY RETRY (robustness — "couldn't not work"): the seal-seam fires Swarm_ferry_on_seal at the sealing
    //  instant, but if that moment is missed — the pier sealed a tick before the secret was stashed, the
    //   first deliver didn't land while the redeemer was still standing up, a reload lost the timing — the
    //    account would silently never cross (the "✓ joined but nobody came online" stall).  So EVERY pump,
    //     while a ferry is pending (top.c.ferry_secret set by Swarm_ferry_link), re-attempt over any LIVE
    //      MyCave pier this ident holds.  on_seal guards (pier_live) + deletes the secret only on a
    //       successful send, so this is a self-clearing no-op the instant the account is on its way; the
    //        `ferrying` in-flight flag stops a second tick double-sending before the first await returns.
    let ftop = this.top_House ? this.top_House() : null
    let fsecret = this.Swarm_ferry_secret()
    let fsoul = this.Swarm_ferry_role('soul')
    if (ftop && ftop.c && fsecret && !(fsoul && fsoul.c.ferrying)) {
        let fpeer = this.Swarm_peering(ident)
        // LIVE (humdinger): re-attempt ONLY for the cave ASKING for the adopt I hold (owner 2026-08-31 — a fresh
        //  mint must not let this pump grab an OLD warm cave and re-park a phantom confirm, the twin of the poke
        //   bug just fixed).  BOOK / runner (no humdinger): keep the plain "first live MyCave" send path so the
        //    ask-less SwarmSpread beat-5 crossing stays byte-identical.
        let fcser = this.Swarm_ferry_serial()
        let fpier = null
        if (fpeer && ftop.c.humdinger) {
            fpier = fpeer.o({ Pier: 1 }).find((p) => {
                if (!this.Swarm_pier_linklive(p)) { return 0 }
                let wat = p.c ? p.c.ferry_want_at : 0
                if (!(wat && (Date.now() - wat) < 45000)) { return 0 }
                let pser = p.c ? String(p.c.ferry_want_serial || '') : ''
                if (fcser && pser && fcser !== pser) { return 0 }
                return 1
            })
        } else if (fpeer) {
            fpier = fpeer.o({ Pier: 1 }).find((p) => this.Swarm_pier_linklive(p))
        }
        if (fpier) {
            // Swarm_ferry_secret() re-derived the twin onto the soul req's .c, so the req exists here.
            let frq = this.Swarm_ferry_role('soul', 1)
            if (frq) { frq.c.ferrying = 1 }
            try { await this.Swarm_ferry_on_seal(w, ident, fpier) } catch (er) {}
            if (frq) { delete frq.c.ferrying }
        }
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
    // …and NUDGE the disk mirror (Clustation_mirror_nudge, Auto.svelte — debounced, single-flight).
    //  The bumps above move the mirror's mark, but a mint is a plain click handler: nothing about it
    //   ticks the beliefs drive, so without this the account write waits for the next unrelated tick
    //    (measured 2026-08-13: invites reached disk only at "the next time around to openshare").
    if (this.Clustation_mirror_nudge) this.Clustation_mirror_nudge()

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
    if (!w.c.roster_rehydrated && this.top_House().stashed) { w.c.roster_rehydrated = 1; this.Swarm_roster_rehydrate(w, ident).catch((er) => console.log('🪪⚠ roster rehydrate failed: ' + String(er).slice(0, 120))) }
    // hydrate THE ME-POINTER (pays the "ensure is called by no production path" debt): without the
    //  body key, a rehydrated roster is a family album with no idea which face is mine — body_mine
    //   null, no badge, no me-still-me.  Reads the body-local Dexie, mints-and-persists on a true
    //    first stand (the remint caveat marks the suspicious case).  Same stashed-gate as its
    //     siblings, so every Book world skips it byte-identically.
    if (!w.c.bodykey_hydrated && this.top_House().stashed) { w.c.bodykey_hydrated = 1; this.Swarm_body_key_ensure(ident).catch((er) => console.log('🪪⚠ body key hydrate failed: ' + String(er).slice(0, 120))) }
    let station = w.o({ Peering: 1 }).find(p => p.sc.name === ident.sc.prepub)
    if (station && w.c.station_up) return station
    if (typeof this.Socket_real !== 'function') return null
    if (typeof WebSocket === 'undefined') return null
    // THE COHORT CONSULT (Portability §10, 2026-08-27): if the profile census says another body
    //  of this soul holds the bare name, take a suffix BEFORE the first dial — the second tab
    //   quietly becomes the second tab, and the doubled-stream disease never starts.  Soft by
    //    construction: no cohort ran (every Book, the daemon, an API-less browser) ⇒ absent ⇒
    //     today's behaviour byte-for-byte.  The address rides the ident's %Peering (the one
    //      Swarm_address reads) and is COPIED to the station %Peering below, which is the one
    //       Socket_real's home() dials.
    let coh = this.top_House().c.cohort
    if (coh && !coh.primary && !this.Swarm_peering(ident)?.sc?.address) {
        let idp = this.Swarm_peering(ident)
        if (idp) {
            idp.sc.address = this.Swarm_next_suffix(ident.sc.prepub, coh.taken || [])
            idp.bump()
            console.log('👥 station standing at ' + idp.sc.address + ' — the bare name is held by a sibling in this profile')
        }
    }
    station = w.oai({ Peering: 1, name: ident.sc.prepub })
    station.c.up = w
    let saddr = this.Swarm_address(ident)
    if (saddr && saddr !== ident.sc.prepub) { station.sc.address = saddr } else { delete station.sc.address }
    this.Swarm_arm(w)
    this.Socket_real(w)
    // presence: install the who_ok hook BEFORE the socket can answer (Presence.g).  Idempotent, and
    //  arming it costs nothing if nobody ever asks — the ask itself rides the pulse round below.
    if (typeof this.Presence_arm === 'function') this.Presence_arm(w)
    // THE ARBITER ADOPT HOOK (Portability §4 hello-v2): the relay answers every hello with the
    //  addr it GRANTED.  If it differs from what we hold, a body of our soul held our wanted seat
    //   from somewhere our local cohort census could not see (another machine on this relay) —
    //    adopt the granted addr onto both %Peerings and REHOME so the reconnect dials `?addr=` at
    //     the granted place (own-door delivery then applies).  Converges: the re-dial asks for the
    //      granted addr, which is now ours, so the next hello_ok matches and no further rehome
    //       fires.  Soft: a relay that never sends addr (older) leaves us exactly where we dialed.
    let self_w = w
    if (self_w.c && !self_w.c.on_hello) {
        self_w.c.on_hello = (frame) => {
            let granted = frame && frame.addr
            if (!granted) return
            let cur = this.Swarm_address(ident)
            if (granted === cur) return
            let idp = this.Swarm_peering(ident)
            if (!idp) return
            if (granted === ident.sc.prepub) { delete idp.sc.address } else { idp.sc.address = granted }
            idp.bump()
            if (frame.taken && frame.taken.length) { try { this.Swarm_note_theft(ident, 'relay_arbiter', null) } catch (e) {} }
            console.log('🪪 adopted relay-granted address ' + granted + (cur ? ' (was ' + cur + ')' : '') + ' — a body of this soul held the seat we wanted')
            this.Swarm_rehome(ident)
        }
    }
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
                // WANT (Portability §4 hello-v2): the address this body wishes to hold — the cohort's
                //  local choice (bare, or a suffix if a same-profile sibling holds bare).  It rides
                //   BESIDE the signed header, never inside it (the signature stays over the 4 keys the
                //    relay verifies), and the relay may hand back a DIFFERENT addr (a cross-machine
                //     body held it — the case the local census cannot see); on_hello adopts the answer.
                let want = this.Swarm_address(ident)
                port.ws?.send(JSON.stringify(Object.assign({}, header, { sign: sign, want: want })))
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
    // STALE FERRY SWEEP (2026-08-28) — a device-link secret only means something while a MyCave pier is
    //  forming to ferry over.  A secret that survived a reload with NO such pier is a DEAD ceremony (the QR
    //   was for a session that's gone), and left alone it wedges the soul at "ferrying now…" forever — and,
    //    since the Link cell now auto-surfaces on Swarm_link_active, boots it into a stuck ceremony cell on
    //     every reload.  Standup runs ONCE per boot, before any fresh "link a device" mint, so clearing here
    //      can only catch a stale one.  A LIVE MyCave pier means a real ferry is mid-flight — leave that for
    //       on_seal/pump-retry.  (The durable-secret twin this sweeps is itself on the way out with #fc.)
    let sweep_top = this.top_House ? this.top_House() : null
    if (sweep_top && sweep_top.c) {
        // THE FERRY REHEAL (Ferry_rebuild §4 Stage 3): the ONE durable twin (stashed.ferry, ms clocks)
        //  re-seeds the ceremony reqs a reload lost — Linkor secret+sent-wait, Linkee awaiting — with the
        //   10-min staleness cap inside it (the OLD cap compared Date.now() ms to Swarm_now SECONDS and so
        //    silently dropped EVERY twin at standup — the #48 "survives a reload" bug, dead by construction
        //     now that both sides of the compare are ms).  THE TOKEN STAYS STICKY (owner 2026-08-29): a
        //      secret is retired only by cancel / a successful send / the got ack — never by a transient
        //       "no pier right now" at boot.  NO CONFIRM RE-PARK AT STANDUP (owner 2026-08-29): a confirm is
        //        demand-driven only — reheal restores 'minted'/'sent'/'awaiting', never 'confirming'; a live
        //         Linkee re-asks within ~3s and THAT re-parks it (task #23 holds).
        // ONE-BOOT MIGRATION: an account upgraded MID-CEREMONY still carries the three pre-req twins — fold
        //  them into the one stashed.ferry (old `at` stamps were Swarm_now SECONDS → ms) so the live ceremony
        //   survives the upgrade, then delete the legacy keys for good.
        if (sweep_top.stashed && !sweep_top.stashed.ferry) {
            let mig = {}
            let miga = 0
            let ops = sweep_top.stashed.ferry_pending_secret
            let oag = sweep_top.stashed.ferry_await_got
            let oaw = sweep_top.stashed.ferry_awaiting
            if (ops && ops.secret) { mig.soul = { phase: (oag ? 'sent' : 'minted'), secret: ops.secret, serial: String(ops.serial || ''), at: Date.now() }; miga = 1 }
            if (!mig.soul && oag) { mig.soul = { phase: 'sent', pub: String(oag.pub || ''), at: Date.now() }; miga = 1 }
            if (oaw && oaw.soul) { mig.cave = { phase: 'awaiting', pub: String(oaw.soul || ''), serial: String(oaw.serial || ''), at: Date.now() }; miga = 1 }
            if (miga) { sweep_top.stashed.ferry = mig; console.log('🦑 ferry: migrated the legacy twin(s) into the one stashed.ferry — the in-flight ceremony survives the upgrade') }
        }
        this.Swarm_ferry_reheal(w)
        // sweep the dead legacy blobs old accounts still carry: the UnInvite set (verb gone 2026-08-31) and
        //  the three pre-req ferry twins (ferry_pending_secret/ferry_awaiting/ferry_await_got — folded into
        //   the one stashed.ferry, so a stale copy must not linger as an un-swept "link in flight" ghost).
        if (sweep_top.stashed && sweep_top.stashed.uninvited) { delete sweep_top.stashed.uninvited }
        if (sweep_top.stashed) { delete sweep_top.stashed.ferry_pending_secret; delete sweep_top.stashed.ferry_awaiting; delete sweep_top.stashed.ferry_await_got }
        // PARK THE LANDED DEVICE-LINK OFFER GHOST-SIDE (owner 2026-08-30: "relying on a certain cell being
        //  mounted to hear a message is quite the design dissonance").  A ?Iz=…*MyCave*… in the bar IS the
        //   standing fact "this tab was opened from a device link"; the "become them?" consent must rise from
        //    the MACHINE, not from whichever face happens to be mounted (InvitePanel used to park it — and the
        //     Link cell seizing the screen unmounted the Door, orphaning the flow).  Non-durable `.c` (the URL
        //      is the durable copy — a reload re-parks it right here); cleared at the redeem seam, on cancel,
        //       and by the cell's decline (which strips the ?Iz).  jsdom/Books carry no ?Iz → no-op → fixtures
        //        untouched.  The consent CLICK stays in the Link cell — the one dependency on a mounted UI that
        //         is legitimate, because it IS the user OKing something.
        this.Swarm_offer_land(w)
    }
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
        // never re-drive a HUSK either (the founding self-grant pier / the Linkee's ceremony husk):
        //  it is evidence of MY role, not a counterparty — rung 2 used to pier_accept-blast it forever
        //   (one face of the owner's storm) and hang %Owed junk on it.
        if (this.Swarm_pier_husk(ident, pier)) continue
        let mineC = pier.o({ Grant: 1, by: String(me) })[0]
        let theirsC = pier.o({ Grant: 1, by: String(theirPub) })[0]
        // rung 3 — THE FORGOTTEN PIER (2026-08-14).  Rungs 1-2 heal a HALF-seal: a %Pier that exists
        //  and is missing a grant.  They cannot help the case where the far side lost the %Pier
        //   ENTIRELY, because every healing path — this one included — iterates existing %Piers, so
        //    the side with none has nothing to iterate and is invisible to all of it (the note at the
        //     top of this comment block already said so; this is the rung that answers it).
        //  MEASURED between the prod daemon 7950f300 ("S") and a live tab d101899a ("Agug"): the tab
        //   held a WHOLE pier — including `Grant:Music,by:<daemon>,for:<tab>`, the daemon's OWN
        //    signature — while the daemon held only an older pier to a third party.  It had made that
        //     seal and lost it.  Every tab boast was answered `🚪 rebuff %ive_got_stranger`, forever:
        //      gossip never opens a door (Swarm_ive_got), the rebuff never reaches the wire
        //       (Swarm_rebuff is local), and our side stays silent because WE are whole.  Deadlock —
        //        two peers reaching each other fine and behaving as though they had never met.
        //  THE CURE IS ALREADY LEGAL.  Swarm_accept does NOT require a pre-existing %Pier: it verifies
        //   the grant is really signed by us and really FOR them, checks page_bound, then seals and
        //    answers pier_confirm.  (Contrast Swarm_confirmed, which DOES demand one and denies
        //     'unexpected' — that asymmetry is deliberate and is what makes this safe.)  So re-sending
        //      our ALREADY-SIGNED grant is enough to be re-believed; no re-mint, no re-sign, no new
        //       frame kind, no invite, and nothing to restart on their side.
        //  GATED HARD, because a re-offer is not free: Swarm_accept stamps `aim_wish` on the far end,
        //   which steers their radio.  So this must fire only on real evidence of being forgotten,
        //    never as boot chatter:
        //   · whole only — we hold BOTH grants, so this re-asserts a relationship, never opens one.
        //   · station up — no point shouting down a dead link.
        //   · a grace from FIRST SIGHT of the pier, not from boot: `heard_at` is `.c` and so is empty
        //      after every reload, which would otherwise make every friend look forgotten at standup
        //       and fire a burst ([[a-newborn-cell-is-born-under-every-floor]] in another costume).
        //   · silence well past every normal cadence — the pulse trickle is ~5s and the liveness
        //      window 30s, so 120s of nothing is not a quiet patch, it is absence.
        //   · once per 10 min per pier, so a peer that is simply gone costs 6 frames an hour.
        if (mineC && theirsC) {
            if (!w.c.station_up) continue
            if (!pier.c.reoffer_seen) { pier.c.reoffer_seen = Date.now(); continue }
            let heard = pier.c.heard_at || 0
            let since = Date.now() - (heard || pier.c.reoffer_seen)
            if (since < 120000) continue
            if (pier.c.reoffer_at && (Date.now() - pier.c.reoffer_at) < 600000) continue
            pier.c.reoffer_at = Date.now()
            if (!this.Swarm_deliver(w, ident, String(pier.sc.pub), { kind: 'pier_accept', grant: grant_of_C(mineC), page: this.Swarm_page(ident) })) { this.Swarm_owed_note(w, pier, 'pier_accept') }
            console.log(`⨳⟲ pier heal: re-offered my standing grant to ${String(pier.sc.pub).slice(0, 8)} — whole here, ${heard ? 'silent ' + Math.round(since / 1000) + 's' : 'never heard'} (§9 rung 3, the forgotten pier)`)
            n = n + 1
            continue
        }
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
            // THE RUNG-2 THROTTLE (the owner's boot log, 2026-08-31: pier_accept blasting per sweep).
            //  This rung fired UNGATED on every heal sweep — the 60s trickle AND every station_routes
            //   call (each socket reopen) — so a pier whose far side never answers cost a frame a
            //    minute, forever.  Same law as rung 3 below: once per 10 min per pier; `.c` dies with
            //     the tab, so the FIRST attempt after a reload still goes instantly.
            if (pier.c.reaccept_at && (Date.now() - pier.c.reaccept_at) < 600000) { continue }
            pier.c.reaccept_at = Date.now()
            // note the miss only on a LIVE station — a Book's mail wire refuses offline parties by
            //  design and its fixtures must not grow ledger rows as a side effect of the heal sweep.
            if (!this.Swarm_deliver(w, ident, String(pier.sc.pub), { kind: 'pier_accept', grant: grant_of_C(mineC), page: this.Swarm_page(ident) }) && w.c.station_up) { this.Swarm_owed_note(w, pier, 'pier_accept') }
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
        // w.c.ra_no_idspace SURVIVES ON PURPOSE (Repli_idspace_todo §4b): the id-space partition is
        //  per-PEER (sha256 of pub+base+path — whose disk holds the file), not per-era, so a rebirth
        //   changes nothing about which ids can resolve there.  This wipe was exactly how the 60s
        //    ra_missed backoff never accumulated into a stop (the 7950f300 flood).  The only clear is
        //     the source re-OFFERING the id (Repli_recv_lines).  Do not add a delete here.
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
        this.Swarm_boast_on_hi(w, ident)
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
    // the %Invite lifecycle: the vivified particle (Swarm_invite_note) walks to `redeeming` the
    //  moment the hello is minted.  GATED on station_up — on a live tab w IS the station world
    //   (session furniture, snap-blind); in a Book w is the BOOK's world and it SNAPS, so an
    //    ungated vivify here moved every redeem fixture (found by the 2026-08-27 sweep — the
    //     SwarmStaple account-roundtrip went red on a %Invite it had never recorded).  Books
    //      never set station_up; that line is already this file's own law.
    if (w.c && w.c.station_up) {
        let inv = this.Swarm_invite_note(w, iz)
        if (inv) { inv.sc.state = 'redeeming'; inv.bump() }
        // DEAD-WINDOW FIX (2026-08-28) — redeeming a MyCave (device-link) invite means a soul is about to be
        //  ferried to THIS device.  Mark it so Swarm_link_active surfaces the RECEIVING cell in a "connecting…
        //   waiting for the other device" phase instead of a blank Radio until the sealed account lands (which,
        //    on the consent-gated path, waits on the human at the OTHER device pressing "give my soul").  Cleared
        //     by Swarm_ferry_park (soul arrived → ferry_pending takes over), _consume, or _cancel.  Live-tab only
        //      (station_up, like the vivify above), so Books never see it and fixtures stay put.
        if (this.Swarm_post_from_feature(t.to)) {
            // the cave's ceremony is ONE req whose phase walk is offered → awaiting → pending: arming
            //  'awaiting' here OVERWRITES a standing 'offered' (the offer consent is over once redeem arms
            //   the ceremony — the old delete-two-flags dance is now just the phase moving on), and the
            //    phase verb stashes the one durable twin so a reload mid-"connecting" returns here.
            //  `serial` binds this awaiting to THE adopt the soul currently holds (the singular-adopt law):
            //   every ferry_want carries it, and the soul serves only the ceremony whose token it minted.
            let acav = this.Swarm_ferry_role('cave')
            if (!(acav && !acav.sc.finished && acav.sc.phase === 'pending')) {
                this.Swarm_ferry_phase(w, 'awaiting', { pub: String(t.prepub || ''), serial: String(t.serial || ''), role: 'cave' })
            }
        }
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
    if (this.Swarm_iz_spent(f)) {
        // A SPENT LINK THAT STILL "STANDS" HERE IS A DEAD QR (owner 2026-08-31: "it is rejecting the link I
        //  copied").  A cave that redeemed-then-backed-out leaves the invite SPENT but the ferry secret standing —
        //   the lobby keeps saying "you have a device link in progress", copy-link copies a link NOBODY can ever
        //    redeem again, and every fresh tab that opens it lands exactly here.  When the spent hello names MY
        //     standing ceremony's serial AND the redeemer holds no honoured MyCave grant (a reloading LIVE cave
        //      does — its sealed pier survives in the ledger, so it must NOT retire the ceremony), the link is
        //       provably dead: retire it whole so the UI falls back to "mint a fresh link".  Humdinger-gated →
        //        Book-inert (fixtures untouched); self-heals the wedge the moment the dead link is tried.
        let sptop = this.top_House ? this.top_House() : null
        let spser = this.Swarm_ferry_serial()
        if (sptop && sptop.c && sptop.c.humdinger && spser && String(t.serial || '') === spser) {
            let sppier = this.Swarm_peering(ident)?.o({ Pier: 1, pub: frame.page?.prepub })[0]
            let splive = sppier && this.Swarm_pier_linklive(sppier) ? 1 : 0
            // LIVE-CEREMONY GUARD (security pass 2026-08-31): the iz rode pier_hello over the readable relay
            //  once, so an observer can REPLAY the spent hello from its OWN page.  Without this guard that
            //   replay retires a ceremony MID-FLIGHT for the legitimate cave (confirm parked, soul sent and
            //    awaiting its got, or the cave's pier warm under this very serial) — a cheap remote "called
            //     off".  Retire only when the ceremony shows no life ANYWHERE, not just none on the asker.
            let spsoul = this.Swarm_ferry_role('soul')
            let spph = spsoul && !spsoul.sc.finished ? String(spsoul.sc.phase || '') : ''
            let spbusy = (spph === 'confirming' || spph === 'sent' || spph === 'held') ? 1 : 0
            if (!spbusy) { spbusy = this.Swarm_peering(ident)?.o({ Pier: 1 }).some((p) => p.c && String(p.c.ferry_want_serial || '') === spser && this.Swarm_pier_linklive(p)) ? 1 : 0 }
            // PROVABLY dead, not merely not-yet-sealed (live catch 2026-08-31 "always eed condemns it as
            //  already used"): a DUPLICATE pier_hello re-delivered while the fresh seal was still QUEUED
            //   behind a starved beliefs mutex (the #37 flood had it 500s deep) hit this seam — spent +
            //    no-grant-YET — and retired the ceremony its own redeem had just legitimately opened.
            //     "No honoured grant" only proves death when the refusal is a signed %NotGrant tombstone
            //      (the revoked wedge this retire was built for) or the mint is OLD enough that any seal
            //       would have landed ages ago (15min >> any mutex storm short of a wedge).  A mid-flight
            //        duplicate now just draws the deny; the ceremony lives on to seal.
            let sptomb = sppier && sppier.o && sppier.o({ NotGrant: 1 })[0] ? 1 : 0
            let sptw = sptop.stashed && sptop.stashed.ferry && sptop.stashed.ferry.soul ? sptop.stashed.ferry.soul : null
            let spage = sptw && sptw.at ? ((Date.now() - sptw.at) / 1000) : 1000000000
            let spdead = (sptomb || spage > 900) ? 1 : 0
            if (!splive && !spbusy && spdead) {
                // retire the ceremony WHOLE: drop the secret and walk the soul req to its 'ended' receipt
                //  (why:'spent') — the phase verb re-stashes, which clears the twin for a receipt phase.
                if (spsoul) { delete spsoul.c.secret; delete spsoul.c.ferrying }
                this.Swarm_ferry_phase(w, 'ended', { pub: String(frame.page?.prepub || ''), why: 'spent', role: 'soul' })
                console.log('🦑 ferry: the standing link is DEAD — its invite was already redeemed once and the redeemer holds no honoured grant. Retired it; mint a fresh link.')
            }
        }
        return deny('spent')
    }
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
    // FRESH DEVICE-LINK REDEEM FORGIVES A STALE FORGET (Ferry_rebuild Stage 0): a re-linked, previously-pruned
    //  body-key reuses this same pier (keyed by prepub), so its old %NotGrant:MyCave would bury the fresh grant
    //   forever (Swarm_pier_live is clock-blind).  This redeem IS proven fresh consent (unspent Iz, presig-checked
    //    above) — retire the tombstone durably so the link seals.  MyCave-only; friend trust untouched.
    if (this.Swarm_post_from_feature(f.to)) { this.Swarm_cave_forgive(ident, pier, frame.page.prepub, f.to) }
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
    // SPENT MEANS NEVER (Linkee side; owner 2026-08-31 "it is rejecting the link I copied").  The soul just told
    //  us the invite this ceremony rides was already redeemed once.  With no sealed pier to fall back on the
    //   ceremony can NEVER complete — the steady ask would only draw the generic "called off" cancel, a lie of
    //    omission.  Fold NOW to an ended-with-why screen ("this link was already used").  Guard: a LIVE cave
    //     reloading mid-ceremony also re-hellos into 'spent' (the URL still carries ?Iz), but its sealed pier
    //      survived the reload in the ledger — if we still hold a live MyCave pier to this soul, stay in the
    //       ceremony and let ferry_want revive it.  Matched on the rejecter so a stray reject can't fold an
    //        unrelated adopt.
    if (String(frame.why) === 'spent') {
        let rcav = this.Swarm_ferry_role('cave')
        if (rcav && !rcav.sc.finished && rcav.sc.phase === 'awaiting') {
            let asoul = String(rcav.sc.pub || '')
            let rp = String(frame.prepub || '')
            let match = asoul && rp && (asoul === rp || asoul.startsWith(rp) || rp.startsWith(asoul)) ? 1 : 0
            let rpier = match ? this.Swarm_peering(ident)?.o({ Pier: 1 }).find((p) => { let pp = String(p.sc.pub || ''); return pp && (pp === rp || pp.startsWith(rp) || rp.startsWith(pp)) }) : null
            let rlive = rpier && this.Swarm_pier_linklive(rpier) ? 1 : 0
            if (match && !rlive) {
                this.Swarm_ferry_phase(w, 'ended', { pub: rp, why: 'spent', role: 'cave' })
                console.log('🦑 ferry: the link this tab opened was ALREADY USED once — it can never complete; folded to the ended screen (mint a fresh link on the soul device)')
            }
        }
    }

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
    // FERRY SEAM — the CAPTAIN who minted a MyCave link waits here: the instant that device's pier
    //  seals bearing a MyCave grant, ferry the sealed account over it (Swarm_ferry_on_seal no-ops
    //   for a plain friend seal or when no ferry_secret is pending, so this is safe on every seal).
    let top_seam = this.top_House ? this.top_House() : null
    // `!ferrying` mirrors the FERRY RETRY guard (~1108): while Swarm_ferry_confirm is mid-send it has already
    //  deleted `ferry_confirm` and set `ferrying`, so a re-seal landing in that await window must NOT re-fire
    //   on_seal — that would re-PARK a fresh `ferry_confirm`, and confirm's success then clears the secret,
    //    stranding a dead "give my soul" (no secret to send).  Small window, but the guard belongs on BOTH
    //     on_seal call sites, not just the retry.
    // SECRET FROM `.c` OR THE DURABLE TWIN: after a LINKOR reload the `.c.ferry_secret` is gone but the ceremony
    //  is alive in `stashed.ferry_pending_secret`.  A Linkee that reloads and RE-seals its pier must still re-fire
    //   on_seal so eed re-parks the confirm — gating on `.c.ferry_secret` alone silently dropped that re-seal
    //    (the owner: "even reloading 495 doesn't renew eed's focus on the Link").  on_seal reads the twin itself.
    let seam_secret = this.Swarm_ferry_secret() ? 1 : 0
    let seam_soul = this.Swarm_ferry_role('soul')
    if (top_seam && top_seam.c && seam_secret && !(seam_soul && seam_soul.c.ferrying)) {
        try { this.Swarm_ferry_on_seal(w, ident, pier) } catch (er) {}
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
             roots: this.Swarm_restash_chainroots(ident, src),
             roster: this.Swarm_restash_roster(ident, src) }

// ── the roster is the FOURTH stash pillar (2026-08-31, the owner: "if I do a Link ceremony again,
//  will they actually know each other as Crew?") ─────────────────────────────────────────────────────
//  The answer used to be "only until either side reloads": the ceremony's mutual knowing — the
//   Captain's %Body rows + signed %Charter, the Cave's sibling-absorbed copy — lived ONLY in the C
//    tree, and restash_all carried piers|izzes|chainroots and NOT the own division.  So the family
//     formed live, then evaporated on the next boot of each body, and the Door (gated on roster≥2)
//      went back to showing nothing.  Same disease, fourth organ.
//  The entry mirrors the pier-stash shape: the signed Charter WIRE (era, payload, sig, soul — the
//   attestation IS the durable truth) plus the raw %Body rows (belt and braces: `name`/`caveat` ride
//    the rows, not the payload, and a roster noted before any charter signs still deserves to live).
Swarm_restash_roster(ident, from):
    let live = this.Swarm_live_self ? this.Swarm_live_self() : null
    if (!live || live !== ident) { return 0 }
    let peering = this.Swarm_peering(from || ident)
    if (!peering) { return 0 }
    let st = this.top_House().stashed
    if (!st) { return 0 }
    let bodies = []
    for (const b of peering.o({ Body: 1 })) {
        if (!b.sc.pub) { continue }
        let e = { pub: String(b.sc.pub) }
        if (b.sc.role) { e.role = String(b.sc.role) }
        if (b.sc.address) { e.address = String(b.sc.address) }
        if (b.sc.name) { e.name = String(b.sc.name) }
        if (b.sc.caveat) { e.caveat = String(b.sc.caveat) }
        bodies.push(e)
    }
    let wire = this.Swarm_charter_wire(from || ident)
    if (!bodies.length && !wire) { return 0 }
    if (!st.Swarm_rosters) { st.Swarm_rosters = {} }
    st.Swarm_rosters[ident.sc.prepub] = { bodies: bodies, charter: wire }
    return bodies.length
// Swarm_roster_rehydrate — the boot half: re-note the stashed %Body rows onto the own %Peering, then
//  re-absorb the stashed Charter WIRE through the same verified door a gossiped one takes
//   (Swarm_charter_absorb onto the own %Peering — the sibling-absorb proved that shape) so the
//    %Charter row re-lands signature-checked and re-projects its roster.  A tampered stash fails
//     closed at the signature; the raw body rows still land (they are the resolution register, and
//      re-noting is idempotent oai).
async Swarm_roster_rehydrate(w, ident):
    let st = this.top_House().stashed
    let mine = st?.Swarm_rosters?.[ident.sc.prepub]
    if (!mine) { return 0 }
    let n = 0
    for (const b of (mine.bodies || [])) {
        if (!b || !b.pub) { continue }
        let row = this.Swarm_body_note(ident, String(b.pub), b.role, b.address, b.name)
        if (row && b.caveat && !row.sc.caveat) { row.sc.caveat = String(b.caveat); row.bump() }
        if (row) { n = n + 1 }
    }
    if (mine.charter && ident.c && ident.c.keys) {
        try { await this.Swarm_charter_absorb(this.Swarm_peering(ident), mine.charter, ident.c.keys.pub) } catch (er) {}
    }
    if (n) { console.log('🪪 roster rehydrated — ' + n + ' bodies of this soul survive the reload' + (mine.charter ? ' (charter era ' + String(mine.charter.era) + ')' : '')) }
    return n

// Swarm_account_settle — THE outcome seam (Persistence_todo §5.1, 2026-08-21): "this identity's
//  durable ledger just changed — make it durable NOW."  Convergent, not fact-typed: it re-mirrors
//   the WHOLE live ledger (restash_all is idempotent and additive — tombstones kept, grants deduped)
//    and nudges the .jamsend account mirror, so a caller cannot forget a fact KIND — settle takes no
//     facts, it converges state, and a missed call self-heals at the next one.  Before this seam only
//      Swarm_iz_mark nudged the disk mirror; a RE-seal, a revoke or a chainroot change reached Dexie
//       and then waited on a COINCIDENTAL version bump to reach the account snap ("reached disk only
//        by luck" — the class Persistence_todo §2.A names, and the eed831f1 session's whole disease).
//  Live-self-guarded like every _stash verb, so a Book's puppets and a foreign vault no-op here
//   (and skip the nudge too), keeping every mail-wire fixture byte-identical.
Swarm_account_settle(ident, why):
    let live = this.Swarm_live_self ? this.Swarm_live_self() : null
    if (!live || live !== ident) return null
    let r = this.Swarm_restash_all(ident)
    if (this.Clustation_mirror_nudge) this.Clustation_mirror_nudge()
    // …and stamp the OWED flag (Phase 2, Persistence_todo §5.2) for mirror loops that poll rather
    //  than listen: the daemon's persist_account fingerprints at most every 20s, and a seal landing
    //   just inside that window sat un-mirrored for the rest of it — the flag lets ONE off-cycle
    //    fingerprint through, and the fingerprint itself still decides whether bytes move.  Runtime
    //     `.c` only: never encoded, dies with the process, re-owed by the next settle.
    let top = this.top_House ? this.top_House() : null
    if (top && top.c) {
        top.c.account_settle_owed = Date.now()
        top.c.account_settle_why = String(why || '')
    }
    return r

// Swarm_persist_diag — the persistence health card (Persistence_todo §5.3): every ack and owed
//  flag the settle/mirror machinery keeps, in one read.  DoorFace derives its settled ✓/settling…
//   from this, the daemon rides it into /status, and a debugging session asks it instead of
//    grepping four `.c` keys.  Read-only, `.c` only, no encode cost — a card, not a ledger.
Swarm_persist_diag():
    let top = this.top_House ? this.top_House() : null
    let c = (top && top.c) ? top.c : {}
    let live = this.Swarm_live_self ? this.Swarm_live_self() : null
    return {
        stash_durable_at: +(c.stash_durable_at || 0),
        stash_saving: c.stash_saving ? 1 : 0,
        mirror_at: +(c.account_mirror_at || 0),
        mirror_owed: c.account_mirror_owed ? 1 : 0,
        mirror_muted: c.account_mirror_muted ? 1 : 0,
        mirror_stale: +(c.account_mirror_stale || 0),
        settle_owed: +(c.account_settle_owed || 0),
        settle_why: String(c.account_settle_why || ''),
        stolen: (live && this.Swarm_stolen && this.Swarm_stolen(live)) ? 1 : 0,
    }

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
    // RUNG 3 NEEDS A CADENCE (2026-08-14).  Swarm_reaccept_incomplete runs from Swarm_station_routes
    //  — standup and socket (re)open — which is enough for rungs 1-2 (a half-seal is a fact about
    //   durable state and does not change while we sit still).  Rung 3's evidence is SILENCE, which
    //    only accrues with time, and its grace anchor `pier.c.reoffer_seen` is `.c` and so is reborn
    //     on every reload: driven from standup alone the grace could never mature and the rung would
    //      never once fire.  So it also rides the pulse trickle, which is the clock that measures the
    //       very silence it reasons about.  Slow (60s) because the rung is itself throttled to one
    //        re-offer per pier per 10 min — this only has to be more frequent than that, not fast.
    if (!w.c.heal_look_at || (Date.now() - w.c.heal_look_at) > 60000) { w.c.heal_look_at = Date.now(); this.Swarm_reaccept_incomplete(w, ident).catch((er) => console.log(`⨳⚠ pier heal failed: ${er && er.message || er}`)) }
    // THE FAMILY HEAL rides the same clock: the division re-derived from the standing My* grants
    //  (Swarm_family_heal is change-gated + humdinger-gated, so a settled family costs a walk and a
    //   Book costs nothing).  This is what makes a ceremony that misfired — stale build, lost frame,
    //    mistimed reload — converge within a minute instead of never.
    if (!w.c.family_look_at || (Date.now() - w.c.family_look_at) > 60000) { w.c.family_look_at = Date.now(); this.Swarm_family_heal(w, ident).catch((er) => console.log(`🪪⚠ family heal failed: ${er && er.message || er}`)) }
    // the reach RETRY rides the same trickle (Reach_todo): re-dispatch standing cross-body intents.
    //  Self-gated on w.c.reach_on (default-off — the ledger observes until the knob is flipped).
    if (!w.c.reach_look_at || (Date.now() - w.c.reach_look_at) > 60000) { w.c.reach_look_at = Date.now(); try { this.Swarm_reach_settle(w, ident) } catch (er) {} }
    // ORGAN refresh (SoundPool): a body re-describes its own pocket/trove from the live library counts so
    //  the Plot's lanes show real sizes (and organ replication carries them to siblings).  Book-inert (no
    //   radio world → no-op).
    if (!w.c.organ_look_at || (Date.now() - w.c.organ_look_at) > 60000) { w.c.organ_look_at = Date.now(); try { this.Swarm_organ_refresh(w, ident) } catch (er) {} }
    // FERRY WANT rides the same heartbeat: while I am a Linkee awaiting a soul, keep asking the soul device for it
    //  (Swarm_ferry_ask) so its confirm stays parked through any reload on its end.  Best-effort, same ~5s cadence.
    this.Swarm_ferry_ask(w, ident)
    // ── THE SIBLING PULSE (owner 2026-08-31: "it's not clear that the two of them can see each
    //  other yet") — bodies of one soul had NO liveness channel at all: pulses walk %Piers, and a
    //   body is not a friend.  So each body also pulses every OTHER roster seat by ADDRESS, carrying
    //    `body` (my body-key pub — the roster row the far side should stamp) and `addr` (my seat).
    //     The far side's own-name claim branch stamps `heard` ON THE %Body ROW — presence as a
    //      standing particle (the Statehome ruling; EntropyArrest forgives the wobble), which is what
    //       the Door's family box reads.  Live-station only (Books untouched).  v1 trust note: the
    //        stamp is unsigned like a stranger's hello — a voucher-grade proof can harden it later.
    if (w.c.station_up) {
        let mykey = this.Swarm_body_key(ident)
        let mybody = mykey && mykey.pub ? String(mykey.pub) : ''
        let myaddr = this.Swarm_address(ident) || String(ident.sc.prepub)
        if (mybody) {
            for (const b of this.Swarm_body_roster(ident)) {
                let baddr = String(b.sc.address || '')
                if (!baddr || baddr === myaddr) { continue }
                if (this.Swarm_sibling_send(w, ident, baddr, { kind: 'pulse', page: this.Swarm_page(ident), body: mybody, addr: myaddr })) sent = sent + 1
            }
        }
    }
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

// Swarm_boast_on_hi — the boast a non-reply swarm_hi triggers, THROTTLED per ident.  swarm_hi is the
//  rebirth greeting re-sent on every reconnect, so under a flapping relay (live: ws 1006 every ~600ms
//   during a heavy heist) an un-throttled boast-per-hi is a STORM: each ive_got the far side hears books
//    a full inbox unemit + O(depth) rollup (ive_got is off the receive-bypass, Peeroleum :664), piling the
//     sink inbox to its 2000 backstop and starving the reliable handshakes (Invite/LinkDevice) queued in
//      the same serial lane.  The hi-time boast is usually worthless anyway — the census stands LATER than
//       the handshake (records:0, see Swarm_boast_floor), so the real boast is the change-triggered one.
//        The FIRST hi in a quiet spell still boasts a new friend promptly; repeats within the cooldown are
//         dropped.  Books drive Swarm_gossip_music DIRECTLY, so only the incidental hi-path boast is gated.
Swarm_boast_on_hi(w, ident):
    if (this.Swarm_hi_boast_cooling(w, ident)) return
    ident.c.gossip_hi_at = Date.now()
    this.Swarm_gossip_music(w, ident)

// Swarm_hi_boast_cooling — true while this ident's hi-boast is still inside its cooldown, so the caller
//  skips the boast.  Per-IDENT (not per-world) so two identities in a Book never cross-suppress.  Knob
//   `swarm_gossip_hi_ms` (default 15s; 0 restores the old fire-every-hi behaviour).
Swarm_hi_boast_cooling(w, ident):
    let floor = (w.c.swarm_gossip_hi_ms == null ? 15000 : +w.c.swarm_gossip_hi_ms)
    if (!floor) return 0
    return ident.c.gossip_hi_at && (Date.now() - ident.c.gossip_hi_at) <= floor

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
// Swarm_socket_fresh — "has the WIRE said anything lately?"  Reads the global socket_heard stamped at
//  raw ws receipt (Lies_deliver_soon — off-think, cannot be starved by a mutex hold).  Coarse on
//   purpose: it is only ever used to HOLD a subtractive gate open while the per-pier stamp catches up,
//    never as positive per-pier evidence.
Swarm_socket_fresh(p, ms):
    let M = this.top_House ? this.top_House() : null
    return !!(M && M.c.socket_heard && (Date.now() - M.c.socket_heard) < (+ms || 20000))

Swarm_share_present(from, w):
    let me = this.Swarm_live_self ? this.Swarm_live_self() : null
    let p = me ? this.Swarm_peering(me)?.o({ Pier: 1, pub: String(from) })[0] : null
    // heard_at is stamped in the hear funnel UNDER THE BELIEFS MUTEX (2026-08-13 audit #3), so a long
    //  hold starves the stamp while frames pour in fine — the gate then shut on a provably-live friend
    //   and SELF-LOCKED (shut → fewer frames → staler stamp).  Two repairs, both here: the window is
    //    ≥4× the ~5s pulse cadence (was exactly 4 missed drains from shutting), and a RECENTLY-HEARD
    //     SOCKET holds the gate open — undrained frames in the batch are presence the stamp hasn't
    //      caught up to, not silence.  Presence still only ever subtracts.
    let sockFresh = this.Swarm_socket_fresh(p, 20000)
    if (!(p && p.c.heard_at && ((Date.now() - p.c.heard_at) < 40000 || sockFresh))) return false
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
            if (this.Swarm_pier_husk(ident, p)) continue   // a husk is me — no repli_ready, no %Owed junk
            // ARM THE DOOR BEFORE KNOCKING: the reply (Swarm_offer_now at the friend) comes back
            //  within one round trip, but our per-route rx registration used to wait for our own
            //   first share beat — so the immediate reply would die in the exact dead window this
            //    announce exists to close.  Register the rx here, then speak.
            let route = this.Swarm_station_pier(w, ident, String(p.sc.pub))
            if (route && !route.c.repli_rx) this.Repli_register_rx(w, route)
            // a blast that missed is a DEBT, not noise: the %Owed on the pier row makes the offline
            //  fan-out visible (the eed storm) and Swarm_owed_settle re-fires it on the presence edge.
            if (!this.Swarm_deliver(w, ident, String(p.sc.pub), { kind: 'repli_ready', page: this.Swarm_page(ident) })) { this.Swarm_owed_note(w, p, 'repli_ready') }
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
    if (w.c.cull_flying && !this.Swarm_latch_stale(w, 'cull', w.c.cull_flying)) return 0
    if (typeof this.Ra_shuffle_cull !== 'function') return 0
    let epoch = (w.c.cull_epoch = (+(w.c.cull_epoch || 0)) + 1)
    w.c.cull_flying = Date.now()
    this.Ra_shuffle_cull(rw, stock).then(() => this.Swarm_cull_done(w, epoch)).catch(() => this.Swarm_cull_done(w, epoch))
    return 1

// Swarm_cull_done — one line, two callers (settle and throw), so a cull that FAILS still clears the
//  single-flight latch.  A latch left standing would silently retire the cull for the life of the tab.
Swarm_cull_done(w, epoch):
    if (epoch && epoch !== w.c.cull_epoch) return
    w.c.cull_bg_ms = Date.now() - (+(w.c.cull_flying || Date.now()))
    w.c.cull_flying = 0

// Swarm_latch_stale — THE STALE-LATCH BREAKER (2026-08-13, the lost-heist night).  The detached trio's
//  single-flight latches assumed their promise always SETTLES; a hung await inside (an FSA/Berth read
//   that never answers, a wedged elvisto) held the latch forever, and every later beat then skipped the
//    whole subsystem SILENTLY — for keep, that is "no rehydrate, no pulls, no watchdog": the owner's
//     lost Heist.  A hold downstream of a decoupling re-couples it — worse, invisibly.
//  Two parts, both needed:
//   · the breaker here: past LATCH_CAP the latch is declared dead, said OUT LOUD, and the op relaunches.
//      120s is far beyond any honest run of the three (cull's 70s crate sweep is the ceiling that set it).
//   · the epoch in each done(): the broken flight's orphan promise may STILL settle later — without the
//      epoch check it would clear the NEW flight's latch, and the one-writer law dies quietly.
Swarm_latch_stale(w, name, since):
    let LATCH_CAP = +(w.c.detached_latch_cap || 120000)
    let held = Date.now() - (+since || Date.now())
    if (held < LATCH_CAP) return 0
    let why = name + ' detached op hung ' + Math.round(held / 1000) + 's — latch broken, relaunching'
    if (name === 'keep') { why = why + (w.c.keep_beat_at ? ' (hung at: ' + w.c.keep_beat_at + ')' : ''); w.c.heist_beat_why = why }
    console.warn('⏳⚠ ' + why)
    if (typeof this.Radio_trace === 'function') this.Radio_trace(null, { ev: 'latch-break', op: name, held_s: Math.round(held / 1000) })
    return 1

// Swarm_tour_detached / Swarm_tour_done — the cull's twin, for the collection conveyor.  Deliberately
//  a SEPARATE pair rather than a shared generic: `Swarm_cull_detached`/`cull_bg_ms` are already named
//   in MusuNeGrind's (unbuilt) assertions, and renaming them to save six lines would break a Book
//    nobody has run yet — the worst kind of breakage to introduce, because it looks like it works.
//  Same contract: single-flight on a start stamp, duration reported as `tour_bg`, latch cleared on
//   BOTH settle and throw (a stuck latch would retire the conveyor for the life of the tab, and a
//    collection that stops touring stops growing — silently, which is this page's whole failure mode).
// Swarm_keep_detached / Swarm_keep_done — the cull|tour pair's third sibling, for the heist keep
//  driver (2026-08-13: keep=2602ms beats, 280 skips, the folder-describe crawling behind it).  Same
//   contract: single-flight on a start stamp (the one-writer law — the "spastic as fuck" double-write
//    of 2026-07-30 stays impossible, now by THIS latch instead of the beat's), duration reported as
//     `keep_bg`, latch cleared on BOTH settle and throw.  The error note keeps its old home
//      (heist_beat_why), so nothing that read it moves.
Swarm_keep_detached(w, ident):
    if (w.c.keep_flying && !this.Swarm_latch_stale(w, 'keep', w.c.keep_flying)) return 0
    if (typeof this.Heist_keep_beat !== 'function') return 0
    let epoch = (w.c.keep_epoch = (+(w.c.keep_epoch || 0)) + 1)
    w.c.keep_flying = Date.now()
    this.Heist_keep_beat(w, ident).then(() => this.Swarm_keep_done(w, null, epoch)).catch((er) => this.Swarm_keep_done(w, er, epoch))
    return 1

Swarm_keep_done(w, er, epoch):
    if (epoch && epoch !== w.c.keep_epoch) return
    if (er) w.c.heist_beat_why = '' + (er && er.message || er)
    w.c.keep_bg_ms = Date.now() - (+(w.c.keep_flying || Date.now()))
    w.c.keep_flying = 0

Swarm_tour_detached(w, rw, stock):
    if (w.c.tour_flying && !this.Swarm_latch_stale(w, 'tour', w.c.tour_flying)) return 0
    if (typeof this.Stoker_tour !== 'function') return 0
    let epoch = (w.c.tour_epoch = (+(w.c.tour_epoch || 0)) + 1)
    w.c.tour_flying = Date.now()
    this.Stoker_tour(rw, stock).then(() => this.Swarm_tour_done(w, epoch)).catch(() => this.Swarm_tour_done(w, epoch))
    return 1

Swarm_tour_done(w, epoch):
    if (epoch && epoch !== w.c.tour_epoch) return
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
    // POSTED ≠ ENTERED, AND THE BUTLER WAS TELLING THE WRONG STORY (2026-08-13, the owner's stuck tab:
    //  `[FAILED] your share is keeping itself up to date : keep has not completed in 50s (typical 0ms)`
    //   on a tab whose beat had never started at all).  Swarm_share_loop latches `share_beat_running`
    //    when it POSTS the beat, then post_do queues the callback; under a long belief-pass hold the
    //     callback sits in H.todo and nothing inside the beat ever runs.  Everything below reads the
    //      PHASE CURSOR, which describes the PREVIOUS beat — so the probe named `keep`, sending a reader
    //       into the heist driver, when the heist driver had not been called.  `typical 0ms` was the
    //        tell nobody could read: a phase with no learned duration is one that has never completed.
    //  The log line already forks these two states (Swarm_share_loop's `bstate`, same-day audit #1) and
    //   the Butler did not.  One surface short is how a fixed diagnosis stays unfixed for the person
    //    actually looking at the screen.  A queued beat is graded on its OWN clock — how long it has
    //     waited to start — and says who to suspect, which is never the phase.
    if (!w.c.beat_entered_at && w.c.beat_posted_at) {
        let queued = Date.now() - (+w.c.beat_posted_at)
        if (queued > floor_ms) return { state: 'stuck', phase: 'queued', for_ms: queued, why: `the beat has waited ${Math.round(queued / 1000)}s to start — something else is holding the belief pass` }
        if (queued > floor_ms / 3) return { state: 'slow', phase: 'queued', for_ms: queued, why: 'the beat is waiting its turn to start' }
        return { state: 'ok', phase: 'queued', for_ms: queued, why: '' }
    }
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
    for (const it of [{ k: 'cull', fly: w.c.cull_flying, bg: w.c.cull_bg_ms }, { k: 'tour', fly: w.c.tour_flying, bg: w.c.tour_bg_ms }, { k: 'keep', fly: w.c.keep_flying, bg: w.c.keep_bg_ms }]) {
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
                // QUEUED vs RUNNING is the first fork (audit #1): a beat posted but never entered is a
                //  MUTEX jam (read the drain-lag marks for who holds it), not a stuck phase — and the
                //   split below describes the PREVIOUS beat in that case, not this one.
                let bstate = (!w.c.beat_entered_at && w.c.beat_posted_at) ? `QUEUED ${Math.round((Date.now() - w.c.beat_posted_at) / 1000)}s behind the beliefs mutex (split below is the PREVIOUS beat)` : `running ${w.c.beat_entered_at ? Math.round((Date.now() - w.c.beat_entered_at) / 1000) : '?'}s`
                console.log(`⏳ Swarm_share_beat busy past 600ms — ${bstate} — skipping this tick (×${w.c.share_beat_skipped} so far) · cull=${+(sp.cull || 0)} tour=${+(sp.tour || 0)} flush=${+(sp.flush || 0)} peers=${+(sp.peers || 0)} (pump=${+(sp.pump || 0)} warm=${+(sp.warm || 0)}) keep=${+(sp.keep || 0)} · detached: cull_bg=${+(sp.cull_bg || 0)}${w.c.cull_flying ? '(flying)' : ''} tour_bg=${+(sp.tour_bg || 0)}${w.c.tour_flying ? '(flying)' : ''} keep_bg=${+(sp.keep_bg || 0)}${w.c.keep_flying ? '(flying)' : ''} · lead=${+(w.c.lead_s || 0)}s restock_held=${+(w.c.restock_held || 0)} (ms)`)
            }
        } else {
            w.c.share_beat_running = true
            // POSTED ≠ ENTERED (2026-08-13 audit #1): the guard is latched HERE, but post_do only queues —
            //  under a long beliefs-mutex hold the callback sits in H.todo while every tick logs "still
            //   running", and the split (zeroed at beat top) shows the PREVIOUS beat's numbers or all
            //    zeros.  The all-zeros "wedge" that misled tonight's debugging was this: a beat that had
            //     never ENTERED, blamed as one stuck in phase 1.  beat_posted_at forks the two states so
            //      the skip line can say which; entered_at is stamped first thing inside.
            w.c.beat_posted_at = Date.now()
            w.c.beat_entered_at = 0
            this.post_do(async () => {
                if (era !== w.c.share_era) { w.c.share_beat_running = false; return }
                w.c.beat_entered_at = Date.now()
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
                    try { this.Radio_trace(null, { ev: 'beat', ms: ms, skips: +(w.c.share_beat_skipped || 0), cull: +(sp.cull || 0), tour: +(sp.tour || 0), peers: +(sp.peers || 0), pump: +(sp.pump || 0), warm: +(sp.warm || 0), keep: +(sp.keep || 0), cull_bg: +(sp.cull_bg || 0), keep_bg: +(sp.keep_bg || 0) }) } catch (er) {}
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
    // CEREMONY PRIORITY (owner 2026-08-30: "needs to stop whatever it's doing and do the ferry… maybe no stop
    //  but you know what I mean").  A device-link ceremony is a human standing at two screens for a minute; the
    //   share beat is hours of patient background bulk.  While a ferry is actively TRANSACTING on a live tab
    //    (a counterparty engaged: confirm parked / soul landed / mid-send / awaiting), SIT the beat OUT so the
    //     belief mutex and the wire belong to the ceremony (the flood queued 511 beats and the confirm crawled).
    //      Pure deferral — nothing is cancelled; the next beat picks up where it was.  Deliberately NOT gated on
    //       link_active (a lingering QR or an unacked ✓ would starve sharing forever) and capped at 5 minutes as
    //        a honesty valve.  Humdinger-gated → Books never see it, fixtures untouched.
    let cerc = this.top_House().c
    let cfer = this.Swarm_ferry_facts(w)
    if (cerc.humdinger && (cfer.ferrying || cfer.confirm || cfer.pending || cfer.awaiting)) {
        if (!w.c.share_beat_ceremony_at) { w.c.share_beat_ceremony_at = Date.now() }
        if ((Date.now() - w.c.share_beat_ceremony_at) < 300000) {
            w.c.share_beat_ceremony = (w.c.share_beat_ceremony || 0) + 1
            if (w.c.share_beat_ceremony % 12 === 1) { console.log('🦑⏸ share beat sitting out — a device-link ceremony has the floor (×' + w.c.share_beat_ceremony + ')') }
            return
        }
    } else if (w.c.share_beat_ceremony_at) { delete w.c.share_beat_ceremony_at; delete w.c.share_beat_ceremony }
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
    w.c.beat_split = { cull: 0, tour: 0, flush: 0, peers: 0, keep: 0, cull_bg: +(w.c.cull_bg_ms || 0), tour_bg: +(w.c.tour_bg_ms || 0), keep_bg: +(w.c.keep_bg_ms || 0) }
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
        if (!p.c.heard_at || ((Date.now() - p.c.heard_at) >= 40000 && !this.Swarm_socket_fresh(p, 20000))) continue
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
    // ── AND THE KEEP FLIES DETACHED TOO (2026-08-13, the cull|tour disease two organs along) ──
    //  Measured live: keep=2602ms/958/1249 per beat with 280 skips while a heist pulled — the beat
    //   mutex held 1-3s by swarm_share_beat, the folder-describe answer crawling ("asking S for the
    //    folder takes aaages"), the pump and warm starved behind it.  Same shape, same cure: kick and
    //     bow out.  Nothing downstream reads keep's return (it is the LAST phase), and the one-writer
    //      law the beat's single-flight used to carry moves INTO the latch — `keep_flying` means at
    //       most one Heist_keep_beat ever runs, which is STRICTER than before (beats now tick on
    //        while a slow keep streams, but a second keep can never start on top of the first).
    this.Swarm_keep_detached(w, ident)
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
    // …and SETTLE: pier_stash alone reaches Dexie but never nudged the account snap, so a revoke
    //  could sit un-mirrored until a coincidental version bump — and a stale snap disk-seeding a
    //   cleared browser would resurrect the friend the tombstone exists to end (§5.1's class-A).
    this.Swarm_account_settle(ident, 'revoke')
    return pier.i({ NotGrant: atom.not, by: atom.by, for: atom.for, time: atom.time, sign: atom.sign })

// Swarm_pier_forget — the human's "forget this device" for a pier that will never return (a dead Incognito
//  test tab, an abandoned link attempt — owner 2026-08-29: "we have 6 Piers we tried to link to... none
//   indicate the Link failed which I think they all did... we don't need too much in there").  Retires EVERY
//    feature the pier holds via the standard signed %NotGrant law (Swarm_revoke — durable, stash-settled,
//     honoured at use by Swarm_pier_live; the Pier row itself remains as history, per "it is not deleted").
//      Also UnInvites the pub, so any parked ferry state naming it can never seize the screen again.
//       HUMAN-PRESSED ONLY (the DoorFace row's forget) — no Book calls it, so fixtures are untouched.
async Swarm_pier_forget(w, pub):
    let ident = this.Swarm_live_self ? this.Swarm_live_self() : null
    if (!ident) { return 0 }
    let pier = (this.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []).find((p) => String(p.sc.pub) === String(pub))
    if (!pier) { return 0 }
    let feats = {}
    for (const g of pier.o({ Grant: 1 })) { feats[String(g.sc.Grant)] = 1 }
    let n = 0
    let unbonded = 0
    for (const f of Object.keys(feats)) {
        // ANY My<Post> is a device-link, not a friendship: forget the BOND without a tombstone (Stage 1) —
        //  else the signed %NotGrant buries the next deliberate relink on a reused body-key.  NOT gated on
        //   Swarm_pier_live: a pier already poisoned by an old forget reads dead for the feature, yet its
        //    grant + poison still need clearing so it can link again.
        if (this.Swarm_post_from_feature(f)) { if (this.Swarm_cave_unbond(ident, pier, f)) { unbonded = unbonded + 1 }; continue }
        if (this.Swarm_pier_live(pier, f)) { await this.Swarm_revoke(w, ident, pier, f); n = n + 1 }
    }
    let top = this.top_House ? this.top_House() : null
    if (top && top.bump_version) { top.bump_version() }
    console.log('🦑 forgot pier ' + String(pier.sc.friendly || String(pub).slice(0, 8)) + ' — revoked ' + n + ' friend feature(s) (signed NotGrant, permanent) + unbonded ' + unbonded + ' device-link(s) (no tombstone, relinkable); the pier stays as history')
    return 1

// Swarm_pier_live — a Pier stands iff its Feature grants are present and NO matching %NotGrant
//  (same ability + by + for) overrides any of them — checked at use, never cached.
//  (A time-aware "latest safety state" variant lived here for an hour on 2026-08-31 and was REVERTED:
//   grant times and Book-pinned revoke times aren't comparable (SwarmStaple beat 7 went red), and the
//    singular-adopt law removed its one motivating consumer — ferry consent rides the held adopt token,
//     not grant/revoke bookkeeping.  If re-grant-after-revoke is ever wanted for FRIENDSHIPS, that's the
//      Grant.ts "corpus" TODO, to be done with comparable clocks — not a ferry concern.)
Swarm_pier_live(pier, feature):
    let grants = pier.o({ Grant: feature })
    if (!grants.length) return false
    let nots = pier.o({ NotGrant: feature })
    return !nots.some(n => grants.some(g => n.sc.by === g.sc.by && n.sc.for === g.sc.for))
// Swarm_pier_linklive — is this pier a LIVE device-link rail of ANY Post (MyCave | MyCaptain)?  The
//  ferry flow is Post-blind — the soul-holder always sends, only the conferred role differs — so its
//   liveness gates must not hardcode MyCave or the MyCaptain recovery ceremony (Division_todo §0a)
//    dies at the first gate.
Swarm_pier_linklive(pier):
    return this.Swarm_pier_live(pier, 'MyCave') || this.Swarm_pier_live(pier, 'MyCaptain')

// Swarm_cave_forgive — DEVICE-LINK CONSENT IS NOT FRIEND-TRUST (5-fork panel + 2-critic review 2026-08-31,
//  Ferry_rebuild_todo §0/§4 — the corrected Stage 0).  A MyCave link is a per-ceremony consent the human
//   re-does ON PURPOSE, so a stale forget-"no" (the ONLY MyCave %NotGrant source is Swarm_pier_forget, the
//    human's prune) must not bury the next deliberate yes.  A time-compare CANNOT fix this: Swarm_seal (2353)
//     and Swarm_pier_stash (2416) BOTH dedup grants on to|by|for with NO time, so a fresh redeem's newer-timed
//      grant is discarded and the stale-timed one it kept still loses to the tombstone.  So the honest fix is
//       to RETIRE the tombstone at the proven-fresh redeem — drop the %NotGrant:MyCave from the live pier AND
//        splice it from the durable stash (else standup rehydrate re-buries it — the reload-durability trap),
//         then settle.  Scoped to MyCave: the friend %NotGrant:Music permanent-unfriend law is never touched
//          (SwarmStaple inert).  Replay-safe: ONLY Swarm_hello's proven-fresh, unspent-invite, presig-verified
//           redeem reaches this seam, so a hostile relay replay of an old seal (which fails the spent-Iz gate)
//            never forgives.  This is Stage 0 of the rebuild; the eventual epoch model (Stage 2) makes the
//             supersession structural, but retiring the tombstone is the same "fresh consent wins" law drawn
//              once in pencil.
Swarm_cave_forgive(ident, pier, theirPrepub, feature):
    let feat = String(feature || 'MyCave')
    let dropped = 0
    for (const n of (pier.o({ NotGrant: feat }) ?? [])) { pier.drop(n); dropped = dropped + 1 }
    let st = this.top_House ? this.top_House().stashed : null
    let e = st && st.Swarm_piers && st.Swarm_piers[ident.sc.prepub] ? st.Swarm_piers[ident.sc.prepub][theirPrepub] : null
    if (e && e.nots) { e.nots = e.nots.filter(a => a.not !== feat) }
    if (dropped) {
        this.Swarm_account_settle(ident, 'cave_forgive')
        console.log('🦑 ferry: a fresh device-link redeem forgave ' + dropped + ' stale ' + feat + ' "no"(s) on ' + String(theirPrepub).slice(0, 8) + ' — a pruned device links again')
    }
    return dropped

// Swarm_cave_unbond — the human's "forget this device" for the MyCave feature (Stage 1, Ferry_rebuild §4).
//  A device-link is NOT a friendship, so forgetting it must forget the BOND, not lay a permanent unfriend
//   tombstone.  The old Swarm_pier_forget revoked MyCave through Swarm_revoke (a signed %NotGrant), and THAT
//    tombstone — same by/for on a reused Incognito body-key — is exactly what buried every fresh relink (the
//     "link is always called off" root cause: Stage 0's redeem-time forgive only wiped it AFTER the fact).
//      So here we DROP the %Grant:MyCave from the live pier AND from the durable stash grants, and clear any
//       legacy %NotGrant:MyCave (live + stash) so a pier poisoned by the old forget can link again — but we
//        mint NOTHING.  A fresh relink then seals a clean grant with no tombstone to outrank, so forget→relink
//         is durable across reload without leaning on the redeem forgive.  MyCave-scoped: the friend Music
//          trust ledger is untouched (Swarm_pier_forget still signs a real %NotGrant for every friend feature),
//           so SwarmStaple/SwarmSpread stay byte-identical.
Swarm_cave_unbond(ident, pier, feature):
    let feat = String(feature || 'MyCave')
    let n = 0
    for (const g of (pier.o({ Grant: feat }) ?? [])) { pier.drop(g); n = n + 1 }
    for (const a of (pier.o({ NotGrant: feat }) ?? [])) { pier.drop(a); n = n + 1 }
    let st = this.top_House ? this.top_House().stashed : null
    let e = st && st.Swarm_piers && st.Swarm_piers[ident.sc.prepub] ? st.Swarm_piers[ident.sc.prepub][pier.sc.pub] : null
    if (e) {
        if (e.grants) { e.grants = e.grants.filter(g => String(g.to) !== feat) }
        if (e.nots) { e.nots = e.nots.filter(a => a.not !== feat) }
    }
    if (n) { this.Swarm_account_settle(ident, 'cave_unbond') }
    return n
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
    // keep the bytes we just read: roster_save compares its re-encode against THIS, so an upsert
    //  that changes nothing costs no write (the churn audit's finding — every account mirror pass
    //   rewrote this file byte-identical).  `.c` only, dies with the call chain, exactly its scope.
    waft.c.roster_snap_was = snap || ''
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
    // byte-identical to what we read a moment ago ⇒ the upsert changed nothing ⇒ no write.  The
    //  compare is against the actual bytes on disk (not a proxy), so it can never suppress a real
    //   change; and the roster is pub-only, so even a false write here was waste, never danger.
    if (enc.snap === waft.c.roster_snap_was) return waft
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

// ══ %Body — the DIVISION roster (Division_todo §3): a soul's bodies across MACHINES, each a department
//  by ROLE. Distinct in kind from %Sibling above (same-store cohort tabs, session-only): a %Body is
//   PERSISTENT, replicated Tier-B, and role-partitioned — the paradigm-GENERAL substrate ("the imperial
//    realm"), with music binding Captain|Cave atop it. These seams NEVER branch on a role string; a
//     paradigm supplies the vocabulary. Keyed by the BODY KEY's `pub` (Division_todo §ATOMS: a body's
//      own durable identity, one per (store × soul), NOT the soul pub — many bodies share the soul).
//   WHICH ROW IS ME is COMPUTED, never stored (the §STORAGE rule): a `self:1` flag would REPLICATE —
//    a friend absorbing the roster would then see MY "self" bit and think its own body is my Captain.
//     So no flag rides the row; `Swarm_body_mine` matches the row's pub against this body's own body
//      key, an answer that is true on me and false on every friend, computed fresh each time.

// Swarm_body_key — this body's durable keypair on `ident.c.bodykey` (runtime cache, never encoded).
//  SYNC accessor: returns the cached key or null.  `Swarm_body_key_ensure` mints/hydrates it.
Swarm_body_key(ident):
    return ident?.c?.bodykey || null
// Swarm_body_key_ensure — mint-or-load the body key, once per soul per store.  Priority: the live
//  `.c.bodykey` cache → the body-local Dexie (bodykey_read, never replicated) → a fresh mint persisted
//   back (bodykey_write).  `seed` makes the mint DETERMINISTIC for a Book (the production path passes
//    none).  Best-effort at every hop: no IDB (daemon jsdom, a Story boot) simply mints and caches in
//     memory — the body still has a stable-for-this-session key, which is all a Book needs and no worse
//      than the keyless past for a runner.  Returns {pub, key, prepub}.
async Swarm_body_key_ensure(ident, seed):
    if (!ident) { return null }
    if (ident.c.bodykey) { return ident.c.bodykey }
    let root = ident.sc.prepub
    let got = await bodykey_read(root)
    if (got && got.pub) {
        ident.c.bodykey = { pub: got.pub, key: got.key, prepub: got.prepub }
        return ident.c.bodykey
    }
    let mint = await this.Swarm_mint_keys(seed)
    ident.c.bodykey = { pub: mint.pub, key: mint.key, prepub: mint.prepub }
    this.Swarm_body_remint_caveat(ident, mint.pub)
    await bodykey_write({ root_prepub: root, pub: mint.pub, key: mint.key, prepub: mint.prepub, at: this.Swarm_now(H) * 1000 })
    return ident.c.bodykey
// Swarm_body_remint_caveat — the fork-suspicion mark (Statehome_todo debts: "a fork must be seen").
//  The sanctioned join paths (adopt_absorb, the ferry become) HAND the body key over before ensure can
//   mint, so reaching ensure's mint branch while the soul's division ALREADY stands keyed means this
//    store lost — or was refused — its durable key: the fresh row may double a seat an old key still
//     holds in the roster.  Stamp the fresh %Body with `caveat:remint` so the suspicion STANDS in the
//      tree (snapped, seen, provable) instead of vanishing into one instance's interior.  Nothing here
//       clears it — retiring the caveat is a re-charter's job (the Seat re-attesting the division),
//        never an automatic forget.  Pure C-matter (no Dexie), so a Book proves it directly.
Swarm_body_remint_caveat(ident, pub):
    if (!ident || !pub) { return null }
    let keyed = this.Swarm_body_roster(ident).filter((b) => b.sc.pub && String(b.sc.pub) !== String(ident.sc.prepub))
    if (!keyed.length) { return null }
    let body = this.Swarm_body_take(ident, pub, null, null)
    body.sc.caveat = 'remint'
    body.bump()
    return body
// Swarm_caveat_retire — the caveat's EXIT (§0a: "caveat:remint clears at re-charter").  A LIVING
//  My<Post> grant for the marked pub means the Seat has since run the real ceremony over that key —
//   the suspicion is answered by the strongest truth we hold, so the heal walk (the re-attestation)
//    retires the mark.  `fam` is a Swarm_family_derive result; remint itself never clears anything.
//     Returns how many marks retired.  Pure C-matter, so a Book proves it directly.
Swarm_caveat_retire(ident, fam):
    if (!ident || !fam || !fam.length) { return 0 }
    let same = (a, b) => a && b ? (a.startsWith(b) || b.startsWith(a) ? 1 : 0) : 0
    let n = 0
    for (const b of this.Swarm_body_roster(ident)) {
        if (!b.sc.caveat) { continue }
        let bpub = String(b.sc.pub || '')
        if (!bpub || !fam.some((f) => same(String(f.pub), bpub))) { continue }
        delete b.sc.caveat
        b.bump()
        console.log('🦑 🪪 caveat retired — a living grant now vouches for ' + bpub.slice(0, 8))
        n = n + 1
    }
    return n
// Swarm_body_take — the running body declares its own %Body (role + the address it holds). Idempotent
//  per body-key `pub`; defaults pub to THIS body's key (Swarm_body_key), falling back to the soul
//   prepub only for the undivided single-body case that has minted no body key yet.  Stores NO self
//    flag — see the header: which row is me is computed by Swarm_body_mine, never written.
Swarm_body_take(ident, pub, role, address):
    let peering = this.Swarm_peering(ident)
    let mine = pub || this.Swarm_body_key(ident)?.pub || ident.sc.prepub
    let body = peering.oai({ Body: 1, pub: mine })
    body.c.up = peering
    if (role) body.sc.role = role
    if (address) body.sc.address = address
    body.bump()
    return body
// Swarm_founding_grant — §0a #3, the owner's ruling ("A", 2026-09-01): the SELF-HUSK PIER.  The
//  founder's captaincy becomes a STANDING grant — %Grant:MyCaptain by the soul FOR its own body-key
//   pub, riding a pier keyed by the body-key prepub: EXACTLY the ceremony-husk shape
//    Swarm_family_derive already reads (beat 7's husk_is_me), so no new derive code and the
//     "no husk ⇒ founding Captain" inference decays to a migration fallback.  Minted from the HEAL
//      (Seat + divided + keyed + no husk yet): an already-divided live Seat migrates on the next
//       trickle, and a fresh founder gains it one trickle after its first ceremony — never from a
//        mere button press (a lone undivided body must not grow a keyed roster).  Swarm_seal is the
//         landing: idempotent, durably stashed, page_bound holds (a real body key's prepub IS its
//          pub's prefix), and the ferry seam no-ops without a pending secret.
async Swarm_founding_grant(w, ident):
    let key = this.Swarm_body_key(ident)
    if (!key || !key.pub || !ident.c.keys) { return null }
    let mypub = String(key.pub)
    if (mypub === String(ident.sc.prepub)) { return null }
    let page = { prepub: prepubOf(mypub), pub: mypub, friendly: String(ident.sc.friendly || '') }
    let mine = await mint_grant(ident.c.keys, mypub, 'MyCaptain', {}, this.Swarm_now(w))
    let pier = this.Swarm_seal(w, ident, page, null, mine)
    if (pier) { console.log('🦑 🪪 founding grant — my own captaincy now STANDS as a MyCaptain grant on the self-husk pier (' + mypub.slice(0, 8) + ')') }
    return pier
// Swarm_pier_husk — is this pier MY OWN husk (the founding self-grant pier above, or the ceremony
//  husk a Linkee imported)?  A husk is evidence of MY role, never a counterparty: no frame should
//   ever be ADDRESSED to it (its address is me), so the reaccept sweep, the charter gossip and the
//    share blast all skip it — a husk pier collecting %Owed debts was the tell this guard fixes.
//     Prefix-compare (pier pubs ride short or full).
Swarm_pier_husk(ident, pier):
    let key = this.Swarm_body_key(ident)
    if (!key || !key.pub || !pier) { return 0 }
    let a = String(pier.sc.pub || '')
    let b = String(key.pub)
    return a && (a.startsWith(b) || b.startsWith(a)) ? 1 : 0
// Swarm_family_grants_wire — the family's PROOF, portable: every soul-signed My<Post> grant atom I
//  hold, in wire form.  Grants live on the piers of the body that MINTED them and never replicated —
//   so a sibling (a Cave holding the seat through an interregnum, say) could not derive the family it
//    plainly belongs to (Division_todo §0a "why the guard stays").  Each atom is SELF-VERIFYING
//     (soul-signed — a forgery fails verify_grant at the far end), so shipping them ships truth, not
//      gossip.  Bounded: a family is small; capped 32 with a loud log, never silently.
Swarm_family_grants_wire(ident):
    let out = []
    if (!ident || !ident.c || !ident.c.keys) { return out }
    let me = String(ident.c.keys.pub)
    let mypre = String(ident.sc.prepub || '')
    let same = (a, b) => a && b ? (a.startsWith(b) || b.startsWith(a) ? 1 : 0) : 0
    for (const pier of this.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []) {
        for (const g of pier.o({ Grant: 1 })) {
            if (!this.Swarm_post_from_feature(g.sc.Grant)) { continue }
            if (!same(String(g.sc.by || ''), me) && !same(String(g.sc.by || ''), mypre)) { continue }
            if (!this.Swarm_pier_live(pier, g.sc.Grant)) { continue }
            if (out.length >= 32) { console.log('🦑 🪪⚠ family grants wire capped at 32 — some grants did not ship'); return out }
            out.push(grant_of_C(g))
        }
    }
    return out
// Swarm_family_grants_absorb — land replicated family grants: verify each atom (verify_grant THROWS
//  on a forgery — caught, skipped), accept ONLY my own soul's signature over a My<Post>, and only a
//   full-pub grantee the page can bind (a legacy short-form or unsigned hand-relic cannot — skipped,
//    it stays derivable on the body that minted it).  The landing is Swarm_seal — idempotent, durably
//     stashed — so this body's OWN derive now reads the whole family off standing grants, and the
//      retirement guard's interregnum hazard (a seat that cannot see its members' grants) closes.
async Swarm_family_grants_absorb(w, ident, wires):
    if (!ident || !ident.c || !ident.c.keys || !wires || !wires.length) { return 0 }
    let me = String(ident.c.keys.pub)
    let n = 0
    for (const wire of wires) {
        let claim = null
        try { claim = await verify_grant(wire) } catch (er) { continue }
        if (!claim || String(claim.by) !== me) { continue }
        if (!this.Swarm_post_from_feature(claim.to)) { continue }
        let forPub = String(claim.for || '')
        let page = { prepub: prepubOf(forPub), pub: forPub, friendly: '' }
        if (!this.Swarm_page_bound(page)) { continue }
        let existing = this.Swarm_peering(ident)?.o({ Pier: 1, pub: page.prepub })[0]
        page.friendly = existing && existing.sc.friendly ? String(existing.sc.friendly) : forPub.slice(0, 8)
        if (this.Swarm_seal(w, ident, page, null, wire)) { n = n + 1 }
    }
    if (n) { console.log('🦑 🪪 family grants absorbed — ' + n + ' soul-signed post(s) now stand on this body too') }
    return n
// Swarm_body_mine — the running body's OWN roster row: the one whose pub matches this body's key.
//  The computed replacement for the old stored `self:1` — true on me, false on every friend's
//   absorbed copy, so it never crosses the wire as a lie.  Null before the body key is minted.
Swarm_body_mine(ident):
    let key = this.Swarm_body_key(ident)
    if (!key || !key.pub) { return null }
    return this.Swarm_body_roster(ident).filter((b) => String(b.sc.pub || '') === String(key.pub))[0] || null

// ── %Owed — the bounded debt ledger, hung on the counterparty's OWN row (Statehome_todo debts) ───────
//  A frame the far side NEEDED that did not go (Swarm_deliver said false) used to vanish into per-tick
//   re-fire noise — the eed storm: pier_accept/repli_ready blasted at 15 offline piers, invisible to
//    every snap.  Now the failure STANDS: one `%Owed` shelf per counterparty row (a friend's %Pier, a
//     sibling's %Body — the row IS the relationship's locality, so a dropped row drops its debts), its
//      items `owe:<kind>` deduped by kind (re-noting refreshes `at`, so the ledger cannot grow with
//       retries).  The frame itself is NEVER stored — a debt is the FACT a kind is owed; the frame is
//        re-derived at pay time (an object in sc is fatal, and a stale frame is worse than none).
//  BOUNDED, NEVER SILENTLY (cap 8 distinct kinds): overflow folds into a visible `dropped=N` scalar.
//  A paid debt does not stand (the transient-req rule): the item detaches, and an empty shelf with
//   nothing dropped removes itself.
Swarm_owed_note(w, holder, kind):
    if (!holder || !holder.oai || !kind) { return null }
    let shelf = holder.oai({ Owed: 1 })
    shelf.c.up = holder
    let item = shelf.o({ owe: String(kind) })[0]
    if (!item) {
        if (shelf.o({ owe: 1 }).length >= 8) {
            shelf.sc.dropped = (+shelf.sc.dropped || 0) + 1
            shelf.bump()
            return null
        }
        item = shelf.i({ owe: String(kind) })
        item.c.up = shelf
    }
    item.sc.at = this.Swarm_now(w)
    item.bump()
    return item
Swarm_owed_paid(holder, kind):
    let shelf = holder && holder.o ? holder.o({ Owed: 1 })[0] : null
    if (!shelf) { return 0 }
    let item = shelf.o({ owe: String(kind) })[0]
    if (!item) { return 0 }
    shelf.drop(item)
    if (!shelf.o({ owe: 1 }).length && !shelf.sc.dropped) { holder.drop(shelf) }
    return 1
// Swarm_owed_settle — pay the standing debts the moment the counterparty comes back (the presence
//  EDGE in the hear funnel — the one signal that replaces the per-tick blast).  Each owed kind is
//   re-derived and re-sent ONCE; a landed send pays the debt, a failed one leaves it standing for
//    the next edge.  Both kinds are idempotent at the far end (seal dedups; repli_ready meets an
//     armed rx), and a pier_accept debt was only ever noted at the HARD-GATED reaccept site — this
//      delivers that same single frame late, it re-decides nothing.
//  GATED DEFAULT-OFF (`w.c.owed_settle` — the backpressure-knob discipline): until flipped, the
//   ledger only OBSERVES.  repli_ready waits for our own share to actually be up.
Swarm_owed_settle(w, ident, pier):
    if (!w || !w.c.owed_settle) { return 0 }
    let shelf = pier && pier.o ? pier.o({ Owed: 1 })[0] : null
    if (!shelf) { return 0 }
    let n = 0
    for (const item of shelf.o({ owe: 1 })) {
        let kind = String(item.sc.owe)
        let frame = null
        if (kind === 'repli_ready') {
            if (!w.c.share_up) { continue }
            frame = { kind: 'repli_ready', page: this.Swarm_page(ident) }
        }
        if (kind === 'pier_accept') {
            let me = ident.c.keys ? ident.c.keys.pub : null
            let mineC = me ? pier.o({ Grant: 1, by: String(me) })[0] : null
            if (mineC) { frame = { kind: 'pier_accept', grant: grant_of_C(mineC), page: this.Swarm_page(ident) } }
        }
        if (!frame) { this.Swarm_owed_paid(pier, kind); continue }
        if (this.Swarm_deliver(w, ident, String(pier.sc.pub), frame)) {
            this.Swarm_owed_paid(pier, kind)
            console.log('⨳🧾 owed settled: ' + kind + ' → ' + String(pier.sc.pub).slice(0, 8) + ' (presence edge)')
            n = n + 1
        }
    }
    return n

// ══ %Reach — the CROSS-BODY PROCEDURE primitive (Reach_todo — the foam between the foam) ══════════════
//  The owner (2026-09-01): "we need C** to join simplicity to complexity — the one idea to the many ideas,
//   all along the world where it interacts."  A %Reach is a durable ADDRESSED INTENT: this body wants THAT
//    party (a body of my soul, or a friend) to do THIS, and the want STANDS as legible matter until served.
//     It is the ONE shape the five hand-rolled send-retry-settle-drop dialects (the Repli want, the Heist
//      stall, %Owed, charter gossip, grant replication) collapse into — the STATE is the debt: a booked
//       reach that hasn't landed IS what %Owed reached for, but on the same particle as the intent, so
//        there is nothing to keep in sync.
//  ROUTING reuses the division we made legible this session: `to` is a role (→ Swarm_body_for / the Seat),
//   a body pub or a friend pub (→ an address).  Lives on the booker's %Peering (the Crew locality, beside
//    %Body/%Charter).  Lifecycle: booked → dispatched → serving → arrived (then drop).
//  FIRST SLICE: the primitive + its state machine, PROVEN on pure C-matter (SwarmBody beat 10).  The WIRE
//   is station-gated (Book-inert) and the settle loop is knob-gated (w.c.reach_on, default-off — observe
//    until flipped, the backpressure discipline).  The doer binding (serve → Heist/Repli) and the live
//     forks (Reach_todo §7) await the human.  This is the JOIN, proven; not yet wired to music.
// Swarm_reach_book — mint the standing intent.  Pure C**; snapped, so the mesh/Cyto/a Book SEE it at once.
//  Idempotent per (to, of, for): re-booking refreshes `at`, never twins.
//  BOUNDED (the %Owed cap discipline, backpressure): a NEW booking beyond `w.c.reach_cap` (default 32) is
//   REFUSED (returns null + logs) — a runaway booking loop cannot flood the shelf.  Re-booking an EXISTING
//    reach is always honoured (idempotent), so the cap never blocks a retry of something already standing.
Swarm_reach_book(w, ident, sc):
    let peering = this.Swarm_peering(ident)
    if (!peering || !sc || !sc.to || !sc.for) { return null }
    let existing = peering.o({ Reach: 1, to: String(sc.to), of: String(sc.of || ''), for: String(sc.for) })[0]
    if (!existing) {
        let cap = (w && w.c.reach_cap != null) ? +w.c.reach_cap : 32
        if (peering.o({ Reach: 1 }).length >= cap) {
            console.log('⨳🫱⚠ reach cap reached (' + cap + ') — booking refused for ' + String(sc.of || sc.to))
            return null
        }
    }
    let reach = peering.oai({ Reach: 1, to: String(sc.to), of: String(sc.of || ''), for: String(sc.for) })
    reach.c.up = peering
    if (!reach.sc.by) { reach.sc.by = String((this.Swarm_body_key(ident) || {}).pub || ident.sc.prepub) }
    if (!reach.sc.state) { reach.sc.state = 'booked' }
    reach.sc.at = String(this.Swarm_now(w))
    reach.bump()
    return reach
// Swarm_reach_addr — RESOLVE where a reach is addressed (pure).  A role (a Post word) → the body that
//  plays it off my own Charter (Swarm_body_for), else the Seat; an explicit address → itself.  Null when
//   unresolvable.
Swarm_reach_addr(ident, reach):
    if (!reach) { return null }
    let to = String(reach.sc.to || '')
    if (!to) { return null }
    let body = this.Swarm_body_for ? this.Swarm_body_for(ident, to) : null
    if (body && body.sc.address) { return String(body.sc.address) }
    return to
// Swarm_reach_dispatch — send a standing reach to its resolved address (station-gated WIRE; the RESOLVE is
//  pure).  Landed → 'dispatched'.  Did NOT land → stays as-is (the intent STANDS; there is no separate
//   debt).  Idempotent — re-dispatching a standing reach IS the retry.  Returns the resolved address (so a
//    Book proves routing without a wire), or null.
Swarm_reach_dispatch(w, ident, reach):
    if (!reach || String(reach.sc.state || '') === 'arrived') { return null }
    let addr = this.Swarm_reach_addr(ident, reach)
    if (!addr) { return null }
    if (!w || !w.c.station_up) { return addr }        // Book / no station: routing proven, wire inert, intent stands
    let wire = { of: String(reach.sc.of || ''), to: String(reach.sc.to || ''), for: String(reach.sc.for || ''), by: String(reach.sc.by || '') }
    if (this.Swarm_sibling_send(w, ident, addr, { kind: 'reach', reach: wire })) {
        if (reach.sc.state !== 'dispatched') { reach.sc.state = 'dispatched'; reach.sc.at = String(this.Swarm_now(w)); reach.bump() }
    }
    return addr
// Swarm_reach_settle — the ONE loop (replaces owed_settle + the Heist stall + the charter-debt retry): on
//  the presence edge, re-dispatch every standing (not-arrived) reach.  KNOB-GATED default-off (w.c.reach_on)
//   — observe until flipped.
Swarm_reach_settle(w, ident):
    if (!w || !w.c.reach_on) { return 0 }
    let peering = this.Swarm_peering(ident)
    if (!peering) { return 0 }
    let n = 0
    for (const reach of peering.o({ Reach: 1 })) {
        if (String(reach.sc.state || '') === 'arrived') { continue }
        if (this.Swarm_reach_dispatch(w, ident, reach)) { n = n + 1 }
    }
    // SWEEP stale refused receipts (the cap's cousin, beat 16): a 'refused' reach STANDS as a receipt the
    //  human sees, but must not stand forever — else the shelf fills with dead receipts and the cap starts
    //   refusing live bookings.  Drop refused reaches older than the receipt TTL (default 1h).  Bounded,
    //    quiet — the receipt had its window to be seen.
    let ttl = (w.c.reach_receipt_ttl != null) ? +w.c.reach_receipt_ttl : 3600
    let now = this.Swarm_now(w)
    for (const reach of peering.o({ Reach: 1, state: 'refused' })) {
        if (now - (+reach.sc.at || now) > ttl) { peering.drop(reach) }
    }
    return n
// Swarm_reach_heard — the TARGET receives a reach frame: mint the inbound copy on MY OWN %Peering (same
//  particle shape, replicated across — the charter model), state 'serving', ready for Swarm_reach_serve.
Swarm_reach_heard(w, ident, frame):
    let r = frame && frame.reach ? frame.reach : null
    if (!r || !r.for) { return null }
    let reach = this.Swarm_reach_book(w, ident, { to: String(r.to || ''), of: String(r.of || ''), for: String(r.for) })
    if (!reach) { return null }
    if (r.by) { reach.sc.by = String(r.by); reach.bump() }
    if (String(reach.sc.state || '') === 'booked') { reach.sc.state = 'serving'; reach.bump() }
    return reach
// Swarm_reach_serve — the TARGET does the work: for each inbound serving reach, DELEGATE to the doer (Reach
//  does not re-implement landing — it hands off to Heist/Repli), mark 'arrived' when the doer places it.
//   The doer binding is the live/humdinger seam (Reach_todo §5 step 3); a Book proves the walk with a stub.
//    `doer(reach)` returns truthy when the work is placed; a falsy return leaves the reach serving (retry).
Swarm_reach_serve(w, ident, doer):
    let peering = this.Swarm_peering(ident)
    if (!peering) { return 0 }
    let n = 0
    for (const reach of peering.o({ Reach: 1, state: 'serving' })) {
        let placed = 1
        if (typeof doer === 'function') { try { placed = doer(reach) ? 1 : 0 } catch (e) { placed = 0 } }
        if (placed) { reach.sc.state = 'arrived'; reach.sc.at = String(this.Swarm_now(w)); reach.bump(); n = n + 1 }
    }
    return n
// Swarm_reach_graduate — drop FULFILLED reaches (the transient-req rule: leave in the snap only the reaches
//  whose in-flight state is worth SEEING).  Only 'arrived' (success) graduates; 'refused' STANDS as a
//   terminal receipt the human sees ("your Cave couldn't serve that").  Returns how many dropped.
Swarm_reach_graduate(ident):
    let peering = this.Swarm_peering(ident)
    if (!peering) { return 0 }
    let n = 0
    for (const reach of peering.o({ Reach: 1, state: 'arrived' })) { peering.drop(reach); n = n + 1 }
    return n
// Swarm_reach_refuse — the TARGET marks an inbound reach it cannot serve (the doer refused for good, not a
//  retry): a terminal 'refused', distinct from 'serving'.  The booker learns via a reach ack of state
//   refused; unlike 'arrived' it does not graduate — the failure stays visible.
Swarm_reach_refuse(w, ident, reach):
    if (!reach) { return null }
    reach.sc.state = 'refused'
    reach.sc.at = String(this.Swarm_now(w))
    reach.bump()
    return reach
// Swarm_reach_ack — the BOOKER hears the outcome (a reach_done / reach_refused frame): match my OWN
//  outbound reach by (to, of, for) and set it to the acked terminal state (arrived | refused).  This
//   closes the round trip — 'arrived' is then graduated by the booker, 'refused' stands.  Returns the
//    matched reach, or null.
Swarm_reach_ack(w, ident, frame):
    let r = frame && frame.reach ? frame.reach : null
    if (!r) { return null }
    let st = String(frame.state || 'arrived')
    let peering = this.Swarm_peering(ident)
    if (!peering) { return null }
    let reach = peering.o({ Reach: 1, to: String(r.to || ''), of: String(r.of || ''), for: String(r.for || '') })[0]
    if (!reach) { return null }
    if (reach.sc.state !== st) { reach.sc.state = st; reach.sc.at = String(this.Swarm_now(w)); reach.bump() }
    return reach
// Swarm_reach_road — the RECEIVER's gate for an inbound `reach` frame: only a body of MY OWN soul may
//  book work on me (the sibling law — `by` must prefix-match a rostered %Body pub), so a stranger's
//   frame lands nothing.  Passing the gate, the reach is heard (minted 'serving' on my %Peering) for
//    the doer.  The relay is untrusted — this gate is the whole reason `by` rides the wire.
Swarm_reach_road(w, ident, frame):
    let r = frame && frame.reach ? frame.reach : null
    if (!r || !r.by) { return null }
    let by = String(r.by)
    let same = (a, b) => a && b ? (a.startsWith(b) || b.startsWith(a) ? 1 : 0) : 0
    let kin = this.Swarm_body_roster(ident).some((b) => same(String(b.sc.pub || ''), by))
    if (!kin) { console.log('⨳🫱⚠ a reach from an unrostered body was ignored (' + by.slice(0, 8) + ')'); return null }
    return this.Swarm_reach_heard(w, ident, frame)
// Swarm_reach_report — the TARGET tells the BOOKER the outcome: resolve the booker's ADDRESS off my
//  roster (the row whose pub matches the reach's `by`) and send a `reach_done` carrying the terminal
//   state.  A miss is fine — the settle loop's re-dispatch makes the booker re-learn eventually.
Swarm_reach_report(w, ident, reach):
    if (!reach || !reach.sc.by) { return false }
    let by = String(reach.sc.by)
    let same = (a, b) => a && b ? (a.startsWith(b) || b.startsWith(a) ? 1 : 0) : 0
    let row = this.Swarm_body_roster(ident).find((b) => same(String(b.sc.pub || ''), by))
    let addr = row && row.sc.address ? String(row.sc.address) : null
    if (!addr) { return null }
    if (!w || !w.c.station_up) { return addr }        // Book / no station: resolution proven, wire inert
    let wire = { of: String(reach.sc.of || ''), to: String(reach.sc.to || ''), for: String(reach.sc.for || ''), by: by }
    return this.Swarm_sibling_send(w, ident, addr, { kind: 'reach_done', state: String(reach.sc.state || 'arrived'), reach: wire }) ? addr : null
// Swarm_reach_crew — the CREW ACTIVITY read (Reach_todo §6, the legibility half — the owner: "I don't
//  bother reading your code anymore").  A pure projection of the standing reaches into ONE legible glance:
//   what my crew is doing for me and what I'm doing for them, tallied by state, each with its age.  The
//    static read; a Seem over it (cross-beat arrivals/departures for the animated glass) is the upgrade.
//     Read-only, no bump — returns a plain object (the Swarm_ferry_facts idiom), Book-assertable.
Swarm_reach_crew(w, ident):
    let peering = this.Swarm_peering(ident)
    let out = { booked: 0, dispatched: 0, serving: 0, arrived: 0, refused: 0, total: 0, reaches: [] }
    if (!peering) { return out }
    let now = this.Swarm_now(w)
    for (const r of peering.o({ Reach: 1 })) {
        let st = String(r.sc.state || 'booked')
        if (out[st] != null) { out[st] = out[st] + 1 }
        out.total = out.total + 1
        out.reaches.push({ of: String(r.sc.of || ''), to: String(r.sc.to || ''), for: String(r.sc.for || ''), by: String(r.sc.by || ''), state: st, age: now - (+r.sc.at || now) })
    }
    return out
// Swarm_organ_take — a body DESCRIBES the organ it grows (Division_todo §PURPOSE / SoundPool §3): a
//  %Organ on its OWN %Body row, kind pocket|trove, carrying QUANTITIES (a count + the tag-shape), never
//   the tracks themselves (those are the library — the organ is the body naming what it holds).  snapped,
//    so the crew SEES what each machine holds; idempotent per kind (re-take updates in place).  Pure C**.
//  Replicating an organ to siblings (so the phone shows the laptop's trove) is a follow-on — a reach
//   for:organ, or an extension of the charter payload; this is the LOCAL self-description first.
Swarm_organ_take(ident, kind, sc):
    let mine = this.Swarm_body_mine ? this.Swarm_body_mine(ident) : null
    if (!mine || !kind) { return null }
    let organ = mine.oai({ Organ: 1, kind: String(kind) })
    organ.c.up = mine
    if (sc && sc.tracks != null) { organ.sc.tracks = String(sc.tracks) }
    if (sc && sc.tags != null) { organ.sc.tags = String(sc.tags) }
    organ.bump()
    return organ
// Swarm_organ_of — read a body's organ of a kind (my own row, or a roster sibling's %Body).  Null when none.
Swarm_organ_of(body, kind):
    if (!body || !body.o) { return null }
    return body.o({ Organ: 1, kind: String(kind) })[0] || null
// Swarm_organ_refresh — a body describes its OWN organ from the LIVE library counts (SoundPool §3): trove
//  = my full collection (the Stoker's `stock` count on the radio world), pocket = my pressed pool copies
//   (the Ra_home_pool census).  Reuses the PROVEN count pattern (RadioFace: Stoker.stock + Ra_recs), not a
//    blind guess.  LIVE only — no radio world (a Book, or pre-boot) → no-op, so it's Book-inert.  Cheap:
//     `stock` is a cached scalar; the pool census is small.  The mapping (what IS pocket vs trove) is the
//      sensible default; the owner refines it once the numbers show on the Plot.
Swarm_organ_refresh(w, ident):
    let top = this.top_House ? this.top_House() : null
    let rw = (top && top.c) ? top.c.radio_w : null
    if (!rw || !ident || !this.Swarm_body_mine || !this.Swarm_body_mine(ident)) { return 0 }
    let stoker = rw.o ? rw.o({ Stoker: 1 })[0] : null
    let trove = stoker ? (+stoker.sc.stock || 0) : 0
    let pocket = 0
    try {
        let pool = this.Ra_home_pool ? this.Ra_home_pool(rw, String(ident.sc.prepub)) : null
        if (pool && this.Ra_recs) { pocket = this.Ra_recs(pool).length }
    } catch (er) {}
    if (trove) { this.Swarm_organ_take(ident, 'trove', { tracks: trove }) }
    if (pocket) { this.Swarm_organ_take(ident, 'pocket', { tracks: pocket }) }
    return 1
// Swarm_organ_wire — my OWN organs as the wire shape ({pub, kind, tracks, tags}[]), each body authoritative
//  for its own self-description.  Rides the sibling charter mile beside `grants` (the family-grant pattern),
//   so the phone learns the laptop's trove size wherever the charter goes.  Empty until a body takes organs.
Swarm_organ_wire(ident):
    let out = []
    let mine = this.Swarm_body_mine ? this.Swarm_body_mine(ident) : null
    if (!mine) { return out }
    let pub = String(mine.sc.pub || '')
    for (const orn of mine.o({ Organ: 1 })) {
        out.push({ pub: pub, kind: String(orn.sc.kind || ''), tracks: String(orn.sc.tracks || ''), tags: String(orn.sc.tags || '') })
    }
    return out
// Swarm_organ_absorb — land replicated organs onto the roster %Body rows they describe (matched by pub).
//  A body only ever ships its OWN organ, so this trusts the self-description onto that body's row; a
//   pub with no roster row is skipped (nothing to describe yet).  Returns how many landed.
Swarm_organ_absorb(host, organs):
    if (!host || !organs || !organs.length) { return 0 }
    let peering = this.Swarm_peering(host)
    if (!peering) { return 0 }
    let same = (a, b) => a && b ? (a.startsWith(b) || b.startsWith(a) ? 1 : 0) : 0
    let n = 0
    for (const orn of organs) {
        if (!orn || !orn.pub || !orn.kind) { continue }
        let row = peering.o({ Body: 1 }).find((b) => same(String(b.sc.pub || ''), String(orn.pub)))
        if (!row) { continue }
        let organ = row.oai({ Organ: 1, kind: String(orn.kind) })
        organ.c.up = row
        if (orn.tracks) { organ.sc.tracks = String(orn.tracks) }
        if (orn.tags) { organ.sc.tags = String(orn.tags) }
        organ.bump()
        n = n + 1
    }
    return n

// ── the Post is the grant, projected (Division_todo §POST'S TRUTH CHAIN #1, step 3) ──────────────────
//  A Post is NEVER a string a body picks: it IS the `%Grant:My<Post>` its Seat cross-signed at the
//   ceremony.  So a body reads its Post OFF the grant, and a `%NotGrant` over that grant drops it — the
//    same revocable, crypto truth that carries Music, carrying a role (the SwarmRole rails).
// Swarm_post_from_feature — the Post a grant Feature confers: the invite wears 'My<Post>' (MyCave,
//  MyCaptain), the Post is the tail.  A non-My Feature (Music) is a capability, not a Post → null.
Swarm_post_from_feature(feature):
    let f = String(feature || '')
    if (f.slice(0, 2) !== 'My' || f.length <= 2) { return null }
    return f.slice(2)
// Swarm_grant_post — the Post a `holder` (a %Pier) confers on this body: the tail of its LIVE
//  'My<Post>' grant, honouring %NotGrant EXACTLY as Swarm_pier_live does (a revoked grant confers no
//   Post).  Deterministic — the first My-feature grant that still stands.  Null when none does.
Swarm_grant_post(holder):
    if (!holder || !holder.o) { return null }
    for (const g of holder.o({ Grant: 1 })) {
        let post = this.Swarm_post_from_feature(g.sc.Grant)
        if (!post) { continue }
        if (!this.Swarm_pier_live(holder, g.sc.Grant)) { continue }
        return post
    }
    return null
// ── THE FAMILY DERIVES FROM THE STANDING GRANTS, CONTINUOUSLY (2026-08-31, the owner's live test:
//  "both tabs are eed, know Gri… basically it's like you didn't do anything") ────────────────────────
//  The ceremony-moment welds (ferry_got finalise, sibling-absorb) are ONE-SHOT event handlers: a stale
//   build, a lost frame or a mistimed reload at THAT INSTANT and the family never forms — and nothing
//    ever retried.  But the ceremony's durable truth is not the moment: it is the cross-signed
//     `%Grant:My<Post>` still standing on the pier.  So the division is RE-DERIVABLE at any time —
//      the Post doctrine ("a Post is NEVER a string a body picks: it IS the grant") applied to the
//       whole roster.  Derive is PURE (Book-proven); heal applies it on the live heartbeat, so a
//        botched ceremony self-repairs within a minute of both tabs breathing.
// Swarm_family_derive — read the division OFF the grants I hold.  For each live My<Post> grant SIGNED
//  BY MY SOUL KEY: `for` names a body and <Post> its role.  `for` == my OWN body-key pub means the
//   pier is my ceremony HUSK (my pre-become identity, riding the imported account) — evidence of MY
//    role + my instance name, not a second member.  A grant signed by anyone else confers nothing.
Swarm_family_derive(ident):
    let out = []
    if (!ident || !ident.c || !ident.c.keys) { return out }
    let me = String(ident.c.keys.pub)
    let mypre = String(ident.sc.prepub || '')
    let mykey = this.Swarm_body_key(ident)
    let mypub = mykey && mykey.pub ? String(mykey.pub) : ''
    // `by`/`for` ride as a prepub in some mints and a full pub in others (the DoorFace seal-check's own
    //  warning) — prefix-compare, which is true for both forms and cannot false-positive across keys.
    let same = (a, b) => a && b ? (a.startsWith(b) || b.startsWith(a) ? 1 : 0) : 0
    for (const pier of this.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []) {
        for (const g of pier.o({ Grant: 1 })) {
            let post = this.Swarm_post_from_feature(g.sc.Grant)
            if (!post) { continue }
            if (!same(String(g.sc.by || ''), me) && !same(String(g.sc.by || ''), mypre)) { continue }
            if (!this.Swarm_pier_live(pier, g.sc.Grant)) { continue }
            let forPub = String(g.sc.for || '')
            if (!forPub) { continue }
            // the member's ROSTER key wants the full page pub the seal imported — but ONLY when the
            //  page IS the grantee (a grant can ride a pier that is not its grantee's: the Linkee's own
            //   redeem pier carries by-soul-for-me on a page that is the SOUL — taking page pub there
            //    would mint a phantom member keyed by the soul itself).  Else the grant's `for` stands.
            let page = pier.o({ Peering: 1 })[0]
            let ppub = page && page.sc.pub ? String(page.sc.pub) : ''
            let pub = ppub && same(ppub, forPub) ? ppub : forPub
            // dedup by key; the PAGE-MATCHED sighting wins (full pub + the grantee's own pier friendly
            //  — its instance name), over the short-form `for` riding some other pier.
            let dupe = out.find((e) => same(e.pub, pub))
            if (dupe) {
                if (pub.length > dupe.pub.length) { dupe.pub = pub; if (pier.sc.friendly) { dupe.name = String(pier.sc.friendly) } }
                continue
            }
            out.push({ pub: pub, role: post, name: String(pier.sc.friendly || ''), husk: mypub && same(forPub, mypub) ? 1 : 0 })
        }
    }
    return out
// Swarm_family_heal — apply the derivation: my own row (Captain when I granted a member a Post; the
//  husk's Post when I was the Linkee), the member rows, the pre-key GHOST row dropped, and — on a
//   CHANGED roster or an unpaid sibling charter debt — sign + gossip + settle, so both the wire and
//    the stash converge.  Humdinger/consenter-gated (Book-inert); idempotent, rides the 60s trickle.
async Swarm_family_heal(w, ident):
    let top = this.top_House ? this.top_House() : null
    if (!top || !top.c || (!top.c.humdinger && !top.c.consenter)) { return 0 }
    if (!ident || !ident.c || !ident.c.keys) { return 0 }
    let fam = this.Swarm_family_derive(ident)
    if (!fam.length) { return 0 }
    let row_key = (b) => String(b.sc.pub) + ':' + String(b.sc.role || '') + ':' + String(b.sc.name || '')
    let before = this.Swarm_body_roster(ident).map(row_key).sort().join('|')
    let key = await this.Swarm_body_key_ensure(ident)
    let mypub = key && key.pub ? String(key.pub) : String(ident.sc.prepub)
    let seat = (this.Swarm_address(ident) || String(ident.sc.prepub)) === String(ident.sc.prepub)
    let husk = fam.find((f) => f.husk)
    let members = fam.filter((f) => !f.husk)
    // §0a #3 (the owner ruled "A"): a divided KEYED Seat with no husk grant is the founding gap —
    //  sign my own captaincy onto the self-husk pier, then re-derive so THIS walk is grant-backed.
    if (seat && !husk && members.length && mypub !== String(ident.sc.prepub)) {
        try { await this.Swarm_founding_grant(w, ident) } catch (e) {}
        fam = this.Swarm_family_derive(ident)
        husk = fam.find((f) => f.husk)
        members = fam.filter((f) => !f.husk)
    }
    let myrole = husk ? husk.role : 'Captain'
    let myaddr = husk ? (this.Swarm_address(ident) || String(ident.sc.prepub) + '_1') : String(ident.sc.prepub)
    let mine = this.Swarm_body_take(ident, mypub, myrole, myaddr)
    if (mine && !mine.sc.name) {
        let nm = husk && husk.name ? husk.name : String(ident.sc.friendly || '')
        if (nm) { mine.sc.name = nm; mine.bump() }
    }
    for (const m of members) {
        // seat assignment mirrors the finalise: an existing row keeps its address; a new member takes
        //  the bare name if Captain, else the next FREE suffix (two Caves must not both read _1).
        let prior = this.Swarm_peering(ident)?.o({ Body: 1, pub: m.pub })[0]
        let maddr = prior && prior.sc.address ? String(prior.sc.address)
            : (m.role === 'Captain' ? String(ident.sc.prepub)
                : this.Swarm_next_suffix(String(ident.sc.prepub), this.Swarm_body_roster(ident).map((b) => String(b.sc.address || '')).filter((a) => a)))
        this.Swarm_body_note(ident, m.pub, m.role, maddr, m.name)
    }
    // grant-vouched rows shed their fork-suspicion here (the heal IS the re-attestation walk).
    this.Swarm_caveat_retire(ident, fam)
    // the pre-key GHOST: the undivided fallback row keyed by the soul prepub — once a real keyed own
    //  row stands, the fallback is a third body that never existed.  Drop it.
    let ghost = this.Swarm_body_roster(ident).find((b) => String(b.sc.pub) === String(ident.sc.prepub))
    if (ghost && mypub !== String(ident.sc.prepub)) { this.Swarm_peering(ident).drop(ghost) }
    // RETIREMENT (Division_todo §0a #5 — the owner's 5-body roster): the heal used to only ADD, so
    //  every experiment's row lingered forever.  A non-mine row with NO live deriving grant is retired
    //   — revoked (%NotGrant → derive skips it) or never-granted junk both exit here.  SEAT-ONLY: a
    //    non-seat body's roster is the charter's projection (it cannot tell "revoked" from "my grants
    //     haven't replicated yet"), so only the roster-writer prunes and the era-bumped re-charter
    //      spreads the shrink.  The eras-old Captain caveat: rows the founding-grant gap leaves
    //       underivable (a Captain row heard from the charter) survive on their ROLE until the
    //        founding self-grant lands (§0a #3) — retire only what NOTHING vouches for.
    if (seat) {
        let same2 = (a, b) => a && b ? (a.startsWith(b) || b.startsWith(a) ? 1 : 0) : 0
        for (const b of this.Swarm_body_roster(ident)) {
            let bpub = String(b.sc.pub || '')
            if (!bpub || same2(bpub, mypub)) { continue }
            if (fam.some((f) => same2(f.pub, bpub))) { continue }
            if (b.sc.role === 'Captain') { continue }
            this.Swarm_peering(ident).drop(b)
            console.log('🦑 🪪 body retired — ' + bpub.slice(0, 8) + (b.sc.name ? ' (' + String(b.sc.name) + ')' : '') + ' has no living grant; the re-charter will omit it')
        }
    }
    let after = this.Swarm_body_roster(ident).map(row_key).sort().join('|')
    let owing = this.Swarm_body_roster(ident).some((b) => { let s = b.o({ Owed: 1 })[0]; return s && s.o({ owe: 'charter' })[0] ? 1 : 0 })
    if (after === before && !owing) { return 0 }
    if (after !== before) { console.log('🦑 🪪 family healed from the standing grants — ' + this.Swarm_body_roster(ident).length + ' bodies of this soul (I am ' + String(myrole) + (mine && mine.sc.name ? ' ' + String(mine.sc.name) : '') + ')') }
    // ONLY THE SEAT ATTESTS (§TWO AUTHORITIES: the Seat — the bare-name holder — is roster-writer +
    //  Charter-signer; the Captain is merely the invite helm; orthogonal).  Was role-gated (`!husk`),
    //   which broke MyCaptain succession: the new Captain derives THROUGH a husk and could never sign.
    //    Seat-gating is the doctrine and covers succession for free — whoever wins the bare name
    //     re-charters.  A suffixed body never signs, so a partial roster can't out-era a fuller one.
    if (seat) {
        try { await this.Swarm_charter_sign(ident) } catch (e) {}
        this.Swarm_charter_gossip(w, ident)
    }
    try { this.Swarm_account_settle(ident, 'family_heal') } catch (e) {}
    return 1

// Swarm_sibling_send — the ADDRESSED send between bodies of one soul.  Swarm_deliver stamps
//  `from: ident.sc.prepub` (the bare name), and the far side's Peeroleum_deliver looks the sender's
//   route up BY that from — a sibling has no route pier for its own name, so every bare-from sibling
//    frame died at the receive gate ("🛰☠ deliver: no Pier for pulse from=eed831f1 to=eed831f1" —
//     the owner's log, the pulses ARRIVING and dropping).  So sibling frames ride `from: my SEAT`
//      (<soul>_N), which is precisely the route pier the far side mints to send to ME — symmetric by
//       construction, and each sibling gets its own stream (no shared-name seq collisions).
//  Ephemeral-lane by nature (pulse/charter re-derive cheaply); no voucher/era stamping — the hear
//   side treats an unmatched-from frame as a stranger and the claim/sibling roads gate on the SOUL
//    (roster pub match; charter signature), so a forged from buys nothing.
Swarm_sibling_send(w, ident, baddr, frame):
    if (!w || !ident || !baddr || !w.c.station_up) { return false }
    let station = w.o({ Peering: 1 }).find((p) => p.sc.name === ident.sc.prepub)
    if (!station || !this.Peeroleum_carrier(station, w)) { return false }
    let route = this.Swarm_station_pier(w, ident, String(baddr))
    if (!route) { return false }
    let myaddr = this.Swarm_address(ident) || String(ident.sc.prepub)
    let seq = this.Pier_next_seq(route)
    this.Peeroleum_send(w, { header: { type: frame.kind, from: String(myaddr), to: String(baddr), seq: seq }, swarm: frame })
    return true

// Swarm_body_repost — (re)derive a body's Post from the grant `holder` and stamp its %Body row: SET
//  when a live grant confers one, DROP when a %NotGrant has retired it.  "Change = revoke + re-issue"
//   (Division_todo §LIFECYCLE): dropping the Post leaves the body row standing — a body without a Post
//    is an undivided body, not a deleted one.  Returns the row (or null if it has none).
Swarm_body_repost(ident, pub, holder):
    let peering = this.Swarm_peering(ident)
    if (!peering) { return null }
    let body = peering.o({ Body: 1, pub: pub })[0]
    if (!body) { return null }
    let post = this.Swarm_grant_post(holder)
    if (post) { body.sc.role = post } else { delete body.sc.role }
    body.bump()
    return body
// Swarm_body_note — record ANOTHER of the soul's bodies (from roster replication or the LinkDevice
//  roster hand-off). oai per vessel `pub`; never marks self.
Swarm_body_note(ident, pub, role, address, name):
    if (!pub) return null
    let peering = this.Swarm_peering(ident)
    let body = peering.oai({ Body: 1, pub: pub })
    body.c.up = peering
    if (role) body.sc.role = role
    if (address) body.sc.address = address
    // the instance name (facet D — "the Name stays with the instance"): the far body's chosen name,
    //  handed over the roster/ferry so the our-box can list "Captain Grav" / "Cave Guw".
    if (name) body.sc.name = String(name)
    body.bump()
    return body
// Swarm_body_roster — the soul's bodies (the division).
Swarm_body_roster(ident):
    let peering = this.Swarm_peering(ident)
    return peering ? peering.o({ Body: 1 }) : []
// Swarm_body_pick — deterministic pick among role-matches on a page: the PRIMARY (bare address) first,
//  else address ascending. `bare` is the soul's unsuffixed prepub. Shared by the own-roster and the
//   peer-roster (Pier) lookups so both route identically.
Swarm_body_pick(rows, role, bare):
    let hits = rows.filter((b) => String(b.sc.role || '') === String(role))
    if (!hits.length) return null
    hits.sort((a, b) => {
        let ap = (String(a.sc.address || '') === String(bare)) ? 0 : 1
        let bp = (String(b.sc.address || '') === String(bare)) ? 0 : 1
        if (ap !== bp) return ap - bp
        return (String(a.sc.address || '') < String(b.sc.address || '')) ? -1 : 1
    })
    return hits[0]
// Swarm_body_for — THE ROUTING QUERY: the soul's body playing `role` (the department that does that
//  work). Returns the %Body row (address on its sc), or null. Paradigm-blind — `role` is opaque.
Swarm_body_for(ident, role):
    return this.Swarm_body_pick(this.Swarm_body_roster(ident), role, ident.sc.prepub)
// Swarm_body_primary — the DivisionMaster: the body at the bare <prepub> (holds the unsuffixed address,
//  rosters the rest). Null if no body has claimed the bare name yet.
Swarm_body_primary(ident):
    let bare = ident.sc.prepub
    return this.Swarm_body_roster(ident).filter((b) => String(b.sc.address || '') === String(bare))[0] || null
// Swarm_pier_body — the PEER routing: over a FRIEND's %Pier carrying the counterparty's published roster
//  (%Body rows imported onto the pier), find the counterparty body playing `role`. This is WHY a role is
//   peer-visible: "who serves music for soul X" resolves to a body + address, not to "the soul". `bare`
//    is the counterparty's routing name (pier.sc.prepub).
Swarm_pier_body(pier, role):
    if (!pier) return null
    return this.Swarm_body_pick(pier.o({ Body: 1 }), role, pier.sc.prepub)
// Swarm_roster_of — PUBLISH: the soul's roster as a PLAIN scalar payload ({pub, role, address}[]) — the
//  wire shape a Pier page / pier_accept carries. No C refs, so it snaps and travels; Tier-B grow-only, so
//   two bodies' rosters union cleanly. The receiver lands it with Swarm_roster_onto.
Swarm_roster_of(ident):
    return this.Swarm_body_roster(ident).map((b) => ({ pub: String(b.sc.pub || ''), role: String(b.sc.role || ''), address: String(b.sc.address || '') }))
// Swarm_roster_onto — ABSORB: land a published roster (from Swarm_roster_of, across the wire) as %Body
//  rows under a FRIEND's %Pier, so Swarm_pier_body can route to the counterparty's departments. oai per
//   pub; idempotent — re-absorbing an unchanged roster mints no twin. Returns how many rows it carried.
Swarm_roster_onto(pier, roster):
    if (!pier || !roster) return 0
    let n = 0
    for (const e of roster) {
        if (!e || !e.pub) continue
        let body = pier.oai({ Body: 1, pub: e.pub })
        body.c.up = pier
        if (e.role) body.sc.role = e.role
        if (e.address) body.sc.address = e.address
        body.bump()
        n = n + 1
    }
    return n

// ══ %Charter — the ATTESTATION over the roster (Division_todo §POST'S TRUTH CHAIN #2, step 2).  The
//  %Body rows above are the RESOLUTION register (pure, unsigned); the Charter is the soul-signed,
//   era-stamped snapshot of them that makes the resolution TRUSTABLE across the wire.  A friend (or any
//    body) verifies it against the soul pub — a spoofed "I am Alice's Cave" fails the signature, and a
//     split-brain can't flap because peers keep the HIGHEST ERA.  It is Story's own idiom given a
//      signature: a serialisation of state at a version, re-emitted when the digest moves (the WELD).

// Swarm_charter_payload — the roster as ONE canonical scalar: `pub:role:address` per body, segment-
//  sorted so the SAME division serialises byte-identically on every body (the signature depends on it).
//   Addresses/roles/pubs never carry ':' or ';' (hex prepubs + fixed role words), so the split is safe.
Swarm_charter_payload(roster):
    let segs = (roster || []).map((e) => String(e.pub || '') + ':' + String(e.role || '') + ':' + String(e.address || ''))
    segs.sort()
    return segs.join(';')
// Swarm_charter_parse — the payload back to a {pub, role, address}[] roster (address may be empty).
Swarm_charter_parse(payload):
    let out = []
    for (const seg of String(payload || '').split(';')) {
        if (!seg) { continue }
        let bits = seg.split(':')
        if (bits.length < 3) { continue }
        out.push({ pub: bits[0], role: bits[1], address: bits.slice(2).join(':') })
    }
    return out
// Swarm_charter_sign — derive the Charter from THIS soul's live %Body rows, sign it with the SOUL key,
//  stamp `era`, and merge it onto the ONE stable %Charter row in place (the reset_interval idiom —
//   oai + field writes, NEVER replace() which empties across awaits, NEVER a row-per-era which churns
//    the snap).  `era` explicit lets a caller step it; omitted, it bumps past the current row.  The
//     signed header binds {era, payload, soul} so a tampered address OR a replay onto another soul fails.
async Swarm_charter_sign(ident, era):
    let peering = this.Swarm_peering(ident)
    if (!peering || !ident.c.keys) { return null }
    let soulPub = String(ident.c.keys.pub)
    let cur = peering.o({ Charter: 1 })[0]
    let e = (era != null) ? +era : (+(cur?.sc?.era || 0) + 1)
    let payload = this.Swarm_charter_payload(this.Swarm_roster_of(ident))
    let head = { era: String(e), payload: payload, soul: soulPub }
    head.sign = await signHeader(head, ident.c.keys.key)
    let ch = peering.oai({ Charter: 1 })
    ch.c.up = peering
    ch.sc.era = String(e)
    ch.sc.payload = payload
    ch.sc.sig = head.sign
    ch.sc.soul = soulPub
    ch.bump()
    return ch
// Swarm_charter_wire — the Charter as the plain {era, payload, sig, soul} object the gossip frame
//  carries (no C refs — it snaps and travels).  Null before the soul has signed one.
Swarm_charter_wire(ident):
    let ch = this.Swarm_peering(ident)?.o({ Charter: 1 })[0]
    if (!ch) { return null }
    return { era: ch.sc.era, payload: ch.sc.payload, sig: ch.sc.sig, soul: ch.sc.soul }
// Swarm_charter_verify — does this wire Charter carry the soul's real signature?  Reconstructs the
//  signed header and checks it against `soulPub` (the account's known pub).  THROWS nothing; returns a
//   plain boolean — a forged Post or a mutated address changes the payload, so the signature fails.
async Swarm_charter_verify(ch, soulPub):
    if (!ch || !ch.sig || ch.payload == null) { return false }
    let head = { era: String(ch.era), payload: String(ch.payload), soul: String(ch.soul || soulPub) }
    head.sign = String(ch.sig)
    let who = await verifyHeader(head, [String(soulPub)])
    return who === String(soulPub)
// Charter_addr — THE ROUTING RESOLVE (Division_todo §ROUTING): the address for `role` off a Charter,
//  bare-first then address-asc (the Swarm_body_pick order).  `anchor` is any C holding a %Charter row —
//   the soul's own %Peering (route my own division) or a FRIEND's %Pier (route to the counterparty's
//    department).  Null when no Charter or no body plays the role — the caller then dials the Seat (bare).
Charter_addr(anchor, role):
    if (!anchor || !anchor.o) { return null }
    let ch = anchor.o({ Charter: 1 })[0]
    if (!ch || ch.sc.payload == null) { return null }
    // the bare routing name: a self %Peering wears it as `name`; a real %Pier (Swarm_seal keys by
    //  page.prepub) wears it as `pub`; a hand-built test pier wears `prepub`.  Any of the three.
    let bare = String(anchor.sc.prepub || anchor.sc.name || anchor.sc.pub || '')
    let hits = this.Swarm_charter_parse(ch.sc.payload).filter((e) => String(e.role) === String(role))
    if (!hits.length) { return null }
    hits.sort((a, b) => {
        let ap = (String(a.address) === bare) ? 0 : 1
        let bp = (String(b.address) === bare) ? 0 : 1
        if (ap !== bp) { return ap - bp }
        return (String(a.address) < String(b.address)) ? -1 : 1
    })
    return hits[0].address
// Swarm_charter_absorb — verify a friend's Charter and, if newer, land it on their %Pier (merge in
//  place) + project its roster into per-body %Body rows.  This is the ONLY mint path for friend-side
//   %Body rows (Division_todo §WELD): routing off %Body then IS routing off the signed Charter, one hop
//    removed — the cache-discipline rule made structural.  Highest-era wins: a stale or equal era is
//     ignored (the split-brain guard).  Returns 1 if it absorbed, 0 if forged / not newer.
async Swarm_charter_absorb(pier, ch, soulPub):
    if (!pier || !ch) { return 0 }
    let ok = await this.Swarm_charter_verify(ch, soulPub)
    if (!ok) { return 0 }
    let cur = pier.o({ Charter: 1 })[0]
    if (cur && +(cur.sc.era || 0) >= +(ch.era || 0)) { return 0 }
    let row = pier.oai({ Charter: 1 })
    row.c.up = pier
    row.sc.era = String(ch.era)
    row.sc.payload = String(ch.payload)
    row.sc.sig = String(ch.sig)
    row.sc.soul = String(ch.soul || soulPub)
    row.bump()
    this.Swarm_roster_onto(pier, this.Swarm_charter_parse(ch.payload))
    // THE SHRINK CROSSES TOO (Division_todo §0a #5) — but ONLY on the OWN-peering anchor (the sibling
    //  absorb: mainkey %Peering; a friend's %Pier absorb stays additive, its staleness cosmetic).  The
    //   Seat's re-charter OMITS retired bodies, so a sibling mirrors the payload: rows absent from a
    //    NEWER charter drop.  Never my own row off a wire frame — being omitted means EVICTED, which
    //     deserves a louder act than a silent self-delete; log it and stand still.
    if (pier.sc.Peering) {
        let entries = this.Swarm_charter_parse(ch.payload)
        let mykey = pier.c && pier.c.up ? this.Swarm_body_key(pier.c.up) : null
        let mypub2 = mykey && mykey.pub ? String(mykey.pub) : ''
        let same3 = (a, b) => a && b ? (a.startsWith(b) || b.startsWith(a) ? 1 : 0) : 0
        for (const b of pier.o({ Body: 1 })) {
            let bpub = String(b.sc.pub || '')
            if (!bpub) { continue }
            if (entries.some((e) => same3(String(e.pub || ''), bpub))) { continue }
            if (mypub2 && same3(bpub, mypub2)) { console.log('🦑 🪪⚠ this charter omits MY body — I may have been evicted; standing still (a human act decides)'); continue }
            pier.drop(b)
            console.log('🦑 🪪 sibling mirrored the shrink — ' + bpub.slice(0, 8) + ' left the charter')
        }
    }
    return 1
// Swarm_charter_gossip — emit MY current Charter as a `charter` frame to my sealed piers (Division_todo
//  step 4).  `onlyPub` targets one peer (the seed at pier_accept — announce the division to a freshly
//   sealed friend); omitted, it re-emits to EVERYONE (a division change, D6).  An UNDIVIDED soul has no
//    Charter (Swarm_charter_wire → null) so it gossips nothing — the machinery is silent until it matters.
Swarm_charter_gossip(w, ident, onlyPub):
    let wire = this.Swarm_charter_wire(ident)
    if (!wire) { return 0 }
    let peering = this.Swarm_peering(ident)
    if (!peering) { return 0 }
    let sent = 0
    for (const pier of peering.o({ Pier: 1 })) {
        let to = String(pier.sc.pub || '')
        if (!to) { continue }
        if (onlyPub && to !== String(onlyPub)) { continue }
        if (this.Swarm_pier_husk(ident, pier)) { continue }   // a husk is me — nothing listens at its address
        if (this.Swarm_deliver(w, ident, to, { kind: 'charter', charter: wire, page: this.Swarm_page(ident) })) { sent = sent + 1 }
    }
    // THE SIBLING MILE (2026-08-31): a body is not a friend, so the pier loop above can never reach
    //  the one party who needs the charter MOST — my own sibling.  But the roster knows each sibling's
    //   ADDRESS, and the relay does exact-addr routing (the ferry's own road: Swarm_station_pier mints
    //    a transport route to any addr string).  Receiver-side the frame has no matching %Pier and
    //     takes charter_heard's sibling road — soul-signature-gated, so a spoofed addr forges nothing.
    //  A miss is a DEBT (%Owed,owe:charter on the sibling's %Body row — the family_heal trickle
    //   retries while it stands, and pays it on a landed send).  Live-station only (Books untouched).
    if (!onlyPub && w.c.station_up) {
        let myaddr = this.Swarm_address(ident) || String(ident.sc.prepub)
        // the family's grants ride WITH the charter (§0a grant replication): the charter names the
        //  division but only the grants PROVE it, and they lived solely on the minting body's piers —
        //   so a sibling could never derive the family itself.  Each atom self-verifies at the far end.
        let fwires = this.Swarm_family_grants_wire(ident)
        let owires = this.Swarm_organ_wire(ident)   // my pocket/trove sizes ride the same mile (SoundPool)
        for (const b of this.Swarm_body_roster(ident)) {
            let addr = String(b.sc.address || '')
            if (!addr || addr === myaddr) { continue }
            // the ADDRESSED send (Swarm_sibling_send): a bare-from frame dies at the far side's
            //  route lookup — the owner's "no Pier for pulse from=eed831f1" log, same disease.
            if (this.Swarm_sibling_send(w, ident, addr, { kind: 'charter', charter: wire, grants: fwires, organs: owires, page: this.Swarm_page(ident) })) {
                sent = sent + 1
                this.Swarm_owed_paid(b, 'charter')
            } else { this.Swarm_owed_note(w, b, 'charter') }
        }
    }
    return sent
// Swarm_charter_heard — the receiver: absorb a gossiped `charter` onto the sender's %Pier, verifying
//  against the pub we imported at seal (never a pub the frame claims — the counterparty's real pub rides
//   the pier's %Peering child).  Highest-era wins inside absorb, so a replayed old frame is ignored.
//  …AND THE SIBLING ABSORB (2026-08-31, the owner live after the first real ferry: "Link ceremony is done
//   now, they still don't know each other").  A charter for MY OWN SOUL arrives with no matching %Pier —
//    the sender is my sibling body, and a body is not a friend — so this fn silently dropped the one frame
//     that completes mutual knowing: at ferry_got the Captain signs + gossips its division over the still-
//      standing ceremony pier (the Cave has not reloaded yet, so its pre-become address is still live), and
//       the Cave held an account whose soul IS the charter's soul, with nowhere to put it.  Now the `!pier`
//        fallthrough tries the sibling road: find a KEYED identity I hold whose soul pub equals the
//         charter's soul, verify the signature against that pub (only a real holder of the soul key can
//          sign — a stranger's forgery fails closed), and absorb onto that identity's OWN %Peering —
//           structurally the same absorb (the %Charter row + %Body rows live under %Peering exactly as
//            under a %Pier), so highest-era-wins convergence comes free.  The Cave thus lands the
//             Captain's %Body row + the era-1 %Charter INTO the imported soul account BEFORE the reload,
//              and wakes as the soul already knowing its family.  Book-inert: every existing charter
//               fixture (SwarmGossip/SwarmCharter/SwarmServe) is friend-directed — the pier path matches
//                and returns before this road; a pier-less charter frame reaches no existing Book.
async Swarm_charter_heard(w, ident, frame):
    let from = frame?.page?.prepub
    if (!from || !frame.charter) { return 0 }
    let pier = this.Swarm_peering(ident)?.o({ Pier: 1, pub: from })[0]
    if (!pier) {
        let soul = String(frame.charter.soul || '')
        if (!soul) { return 0 }
        // three roads to the soul identity I might hold: (1) beside the recipient in ITS OWN account
        //  container — the live Cave right after consume, where the imported soul sits next to the husk
        //   `ident` and is NOT under any w %Account row; (2) the world's %Account sweep — Book worlds;
        //    (3) the live self — the reloaded-as-the-soul tab.
        let sib = null
        if (ident && ident.c && ident.c.up && ident.c.up.o) {
            sib = ident.c.up.o({ Identity: 1 }).find((i) => i.c.keys && String(i.c.keys.pub) === soul)
        }
        if (!sib) {
            for (const acct of w.o({ Account: 1 })) {
                sib = acct.o({ Identity: 1 }).find((i) => i.c.keys && String(i.c.keys.pub) === soul)
                if (sib) { break }
            }
        }
        if (!sib) {
            let self = this.Swarm_live_self ? this.Swarm_live_self() : null
            if (self && self.c.keys && String(self.c.keys.pub) === soul) { sib = self }
        }
        if (!sib) { return 0 }
        let took = await this.Swarm_charter_absorb(this.Swarm_peering(sib), frame.charter, soul)
        // the accompanying family grants land regardless of charter newness (a same-era charter can
        //  still carry a grant this body never saw — the founding self-grant changes no roster row).
        let landed = 0
        try { landed = await this.Swarm_family_grants_absorb(w, sib, frame.grants || []) } catch (e) {}
        // the sibling's organ sizes (pocket/trove) land onto its roster row — the phone sees the trove.
        let orgs = 0
        try { orgs = this.Swarm_organ_absorb(sib, frame.organs || []) } catch (e) {}
        if (took) {
            console.log('🦑 🪪 sibling charter absorbed — my family roster now lists ' + this.Swarm_body_roster(sib).length + ' bodies of this soul')
        }
        if (took || landed || orgs) {
            // make the absorbed family DURABLE now (the fourth stash pillar): the Cave hears this
            //  charter AFTER its consume already restashed, so without this settle the absorbed
            //   roster was post-stash RAM and died at the become-reload — the very reload that
            //    should wake "already knowing its family".  Live-self-guarded inside (Book-inert).
            try { this.Swarm_account_settle(sib, 'sibling_charter') } catch (e) {}
        }
        return took
    }
    let soulPub = pier.o({ Peering: 1 })[0]?.sc?.pub
    if (!soulPub) { return 0 }
    return await this.Swarm_charter_absorb(pier, frame.charter, String(soulPub))

// ── the serve binding: resolve-and-emit (Division_todo §ROUTING, step 5) ─────────────────────────────
//  The last mile: a paradigm's dial (the music serve) reads WHERE a Post's server is off the Charter and
//   EMITS — it never caches a liveness verdict (the %Reach reversal).  RESOLUTION is pure; REACHABILITY
//    is the transport's boolean, discovered by SENDING.  The music dial hangs on Swarm_serve_ask; the
//     Heist/Ra call sites bind to it when SwarmDivide is re-grounded onto per-body piers (the owed seam).
// Swarm_serve_to — the RESOLVE half: the address a Post's server answers at, read off the Charter on
//  `pier`, else the Seat (the bare name — the always-on fallback anchor, since the relay does exact-
//   address routing with no fan-out, so a Post with no Charter entry degrades to "ask the Seat").
Swarm_serve_to(pier, role):
    if (!pier) { return null }
    return this.Charter_addr(pier, role || 'Cave') || String(pier.sc.pub || '')
// Swarm_serve_ask — resolve-AND-emit.  Gate on the Music grant (per-soul, checked at USE, never cached),
//  resolve the server address off the Charter, EMIT.  false = the grant refused OR the transport could
//   not deliver — fail-forward, a re-ask heals.  The 'Music' gate is the music paradigm's; the resolution
//    is paradigm-blind (pass any Post).  This is the whole of Musu_serve_ask, factored to the substrate.
async Swarm_serve_ask(w, ident, pier, role, frame):
    if (!pier || !this.Swarm_pier_live(pier, 'Music')) { return false }
    let to = this.Swarm_serve_to(pier, role)
    if (!to) { return false }
    return this.Swarm_deliver(w, ident, to, frame)

// ══ THE CEREMONY — spread out by scanning (Division_todo §CEREMONY / LinkDevice) ═══════════════════════
//  The act of dividing rides the invite rails INVERTED: a blank device (just a body key — no soul, no
//   role) OFFERS itself; the soul-holder SCANS and seals its account across.  Connective, no new crypto:
//    Sealbox (the AES-GCM account seal, proven by SwarmSeal) + Swarm_export/import (the account blob) +
//     mint_grant (the Post grant) + Swarm_body_repost + Swarm_charter_sign (just built).  Consent is
//      MUTUAL: the soul-holder confirms the bodily share (the UI's warned gate), the device confirms the
//       proposed role (it does not know it's a Cave until asked).  The seal IKM is the offer nonce — a
//        one-time secret both sides hold (the device made it, the soul-holder read it off the QR) and the
//         untrusted relay never sees; online-scan, dead after first use.  (Ephemeral-DH is the v2 upgrade.)

// Swarm_adopt_offer — the blank device's role-AGNOSTIC body-adoption offer.  `bodykeys` is its own fresh
//  keypair; `nonce` the one-time seal secret.  The presig proves the device HOLDS the body key (self-
//   signed over the offer domain) — the soul-holder checks it before sealing its account to that pub.
//    Returns { pub, prepub, nonce, presig } — the QR payload (compact-codec-able).
async Swarm_adopt_offer(bodykeys, nonce):
    let presig = await signHeader({ pub: bodykeys.pub, prepub: bodykeys.prepub, nonce: String(nonce) }, bodykeys.key)
    return { pub: bodykeys.pub, prepub: bodykeys.prepub, nonce: String(nonce), presig: presig }
// Swarm_adopt_verify — does the offer prove the device controls its body key?  NEVER seal an account to a
//  key nobody proved they hold.  Returns a plain boolean.
async Swarm_adopt_verify(offer):
    if (!offer || !offer.pub || !offer.presig) { return false }
    let head = { nonce: String(offer.nonce), prepub: offer.prepub, pub: offer.pub }
    head.sign = offer.presig
    let who = await verifyHeader(head, [offer.pub])
    return who === offer.pub
// Swarm_adopt_redeem — the SOUL-HOLDER scans an offer and DIVIDES.  Verify the offer; DECIDE a role to
//  propose (`role`, e.g. 'Cave'); SEAL the whole account to the offered body-key (ikm = the offer nonce,
//   salt = both pubs); mint a cross-signed `%Grant:My<role>` for the body; DELIVER the sealed account +
//    grant over the relay to the body's prepub.  The crown jewel — a warned, human-confirmed act (the UI
//     gate is the caller's).  Returns did-it-cross.
async Swarm_adopt_redeem(w, soulIdent, offer, role):
    let ok = await this.Swarm_adopt_verify(offer)
    if (!ok) { this.Swarm_rebuff(soulIdent, 'adopt_forged', offer?.prepub); return false }
    let soulPub = String(soulIdent.c.keys.pub)
    let salt = soulPub + ':' + offer.pub
    let blob = await this.Swarm_export(soulIdent)
    let sealed = await seal(String(offer.nonce), salt, blob)
    let grant = await mint_grant(soulIdent.c.keys, offer.pub, 'My' + role, {}, this.Swarm_now(w))
    let frame = { kind: 'adopt_seal', sealed: sealed, salt: salt, soulpub: soulPub, grant: grant, role: String(role) }
    console.log('🦑 adopt: sealing my account → ' + String(offer.prepub).slice(0, 8) + ' as ' + String(role))
    return this.Swarm_deliver(w, soulIdent, offer.prepub, frame)
// Swarm_adopt_absorb — the offered device DECIDES (consent) and BECOMES a body.  Unseal the account (ikm =
//  the nonce IT generated), IMPORT it into `container` (now it holds the soul key), keep its proto-identity
//   as its OWN body key, take its %Body row, land the proposed grant, and derive its Post from that grant
//    (the Cave doesn't know it's a Cave until here).  `consent` is the human's "yes, be my Cave".  Returns
//     the new soul %Identity (now a body of the soul), or null if refused / the seal did not verify (fails
//      closed — unseal THROWS on a tampered frame or a wrong nonce, and a wrong account never lands).
async Swarm_adopt_absorb(w, container, bodykeys, nonce, frame, consent):
    if (!consent || !frame || !frame.sealed) { return null }
    let blob = null
    try { blob = await unseal(String(nonce), frame.salt, frame.sealed) } catch (e) { return null }
    let ident = this.Swarm_import(container, blob)
    if (!ident || !ident.c.keys) { return null }
    ident.c.bodykey = { pub: bodykeys.pub, key: bodykeys.key, prepub: bodykeys.prepub }
    let addr = ident.sc.prepub + '_1'
    let body = this.Swarm_body_take(ident, bodykeys.pub, null, addr)
    if (frame.grant) { grant_to_C(body, frame.grant) }
    let post = this.Swarm_grant_post(body)
    if (post) { body.sc.role = post }
    body.bump()
    console.log('🦑 adopt: I am now a body of ' + String(ident.sc.prepub).slice(0, 8) + ' — my Post is ' + String(post || 'none'))
    return ident
// Swarm_adopt_finalise — the soul-holder finishes the division once the new body is up: take ITS OWN body
//  row as `role0` (Captain — the inviter becomes the helm), note the new body's Post + address, and write
//   Charter #1.  `newbody` is { pub, role, address }.  The more-online body claims the Seat later (Seat
//    succession); this writes the first roster so both bodies and every friend can route immediately.
async Swarm_adopt_finalise(w, soulIdent, role0, newbody, era):
    let bare = soulIdent.sc.prepub
    let mykey = this.Swarm_body_key(soulIdent)
    let mypub = mykey ? mykey.pub : bare
    this.Swarm_body_take(soulIdent, mypub, role0, bare)
    this.Swarm_body_note(soulIdent, newbody.pub, newbody.role, newbody.address)
    return await this.Swarm_charter_sign(soulIdent, era)
// Swarm_adopt_park — a blank device heard an adoption sealed to it: PARK it for the human's consent (the
//  UI reads top.c.adopt_pending and shows the bodily warning; its confirm calls Swarm_adopt_absorb).  Never
//   auto-absorbs — becoming a body is always a decided act.
Swarm_adopt_park(w, ident, frame):
    let top = this.top_House ? this.top_House() : null
    if (top && top.c) { top.c.adopt_pending = { frame: frame, at: this.Swarm_now(w) } }
    console.log('🦑 adopt: an account arrived sealed to me as ' + String(frame?.role || 'Cave') + ' — awaiting my consent')
    return true
// Swarm_adopt_confirmed — the new body accepted: the soul-holder finalises the division (its Captain row +
//  the Cave note + Charter #1, then gossip).  `frame` carries the new body's { pub, role, address }.
async Swarm_adopt_confirmed(w, soulIdent, frame):
    if (!frame || !frame.pub) { return }
    console.log('🦑 adopt: my new ' + String(frame.role || 'Cave') + ' accepted — writing Charter #1 and gossiping the division')
    await this.Swarm_adopt_finalise(w, soulIdent, 'Captain', { pub: frame.pub, role: frame.role || 'Cave', address: frame.address }, 1)
    this.Swarm_charter_gossip(w, soulIdent)

// ── the UI front doors (the Door's "link a device" flow rides these; the model above is what they call)
// Swarm_adopt_encode / _decode — the offer as a compact URL-safe token (UTF-8-safe base64 of the JSON).
Swarm_adopt_encode(offer):
    return this.Swarm_b64(JSON.stringify(offer))
Swarm_adopt_decode(token):
    try { return JSON.parse(this.Swarm_unb64(token)) } catch (e) { return null }
// Swarm_adopt_offer_url — THE OFFERING (blank/this) device: offer ITS OWN live keypair as a body key
//  (already stood up + reachable on the relay), stash the offer for the later consent/absorb, and dress it
//   as the URL the QR carries — <base>?Adopt=<token>.  The device that shows this is saying "adopt me AS a
//    <role>" — the ROLE is settled HERE, at the offering device, BEFORE the QR (the human at the device
//     knows what it is for), so the trust the soul-holder later grants is role-specific: "be my Cave".
//      `role` defaults 'Cave' (a linked device is almost always the Cave); the offer carries it end to end.
async Swarm_adopt_offer_url(w, base, role):
    let self = this.Swarm_live_self ? this.Swarm_live_self() : null
    if (!self || !self.c.keys) { return null }
    let bodykeys = { pub: self.c.keys.pub, key: self.c.keys.key, prepub: self.sc.prepub }
    let bytes = crypto.getRandomValues(new Uint8Array(12))
    let nonce = Array.from(bytes, (b) => b.toString(16).padStart(2, '0')).join('')
    let offer = await this.Swarm_adopt_offer(bodykeys, nonce)
    offer.role = String(role || 'Cave')
    let top = this.top_House ? this.top_House() : null
    if (top && top.c) { top.c.adopt_offering = { bodykeys: bodykeys, nonce: nonce, role: offer.role, container: self.c.up, at: this.Swarm_now(w) } }
    this.Swarm_expect_arrival(w)
    console.log('🦑 adopt: offering this device (' + String(bodykeys.prepub).slice(0, 8) + ') as a ' + offer.role + ' — scan/paste it from your soul device')
    return String(base) + '?Adopt=' + encodeURIComponent(this.Swarm_adopt_encode(offer))
// Swarm_adopt_land — THE SOUL-HOLDER scanned a ?Adopt= URL: decode the offer and DIVIDE with the role the
//  OFFER carries (the device chose it; the soul-holder is granting exactly that).  The bodily warning +
//   confirm is the UI's; this is the confirmed act.  Returns did-it-cross.
async Swarm_adopt_land(w, token):
    let offer = this.Swarm_adopt_decode(token)
    if (!offer) { return 'baddecode' }
    let self = this.Swarm_live_self ? this.Swarm_live_self() : null
    if (!self) { return 'noself' }
    if (!(await this.Swarm_adopt_verify(offer))) { return 'forged' }
    // distinguish the two failures the old boolean conflated: a bad signature (forged) vs the SEND
    //  failing because there is no channel to the device (unreachable — the pier the ceremony still owes).
    let sent = await this.Swarm_adopt_redeem(w, self, offer, offer.role || 'Cave')
    return sent ? 'ok' : 'unreachable'
// Swarm_adopt_role — the role the scanned offer carries (for the soul-holder's LAND screen to NAME it).
Swarm_adopt_role(w, token):
    let offer = this.Swarm_adopt_decode(token)
    return offer && offer.role ? String(offer.role) : 'Cave'
// Swarm_adopt_pending — the offering device reads whether an adoption has arrived awaiting its consent
//  (the UI's "become a Cave of X?" prompt reads this).  Returns the parked frame's soul pub, or null.
Swarm_adopt_pending(w):
    let top = this.top_House ? this.top_House() : null
    let p = top && top.c ? top.c.adopt_pending : null
    return p && p.frame ? { soulpub: p.frame.soulpub, role: p.frame.role } : null
// Swarm_adopt_consent — the offering device DECIDES: on accept, absorb the parked sealed account (with the
//  stashed body key + nonce) — becoming a body — and confirm back to the soul-holder so it charters.  On
//   reject, drop the offer.  Returns the new body %Identity, or null.
async Swarm_adopt_consent(w, accept):
    let top = this.top_House ? this.top_House() : null
    if (!top || !top.c) { return null }
    let off = top.c.adopt_offering
    let pend = top.c.adopt_pending
    if (!accept || !off || !pend || !pend.frame) { delete top.c.adopt_pending; return null }
    let ident = await this.Swarm_adopt_absorb(w, off.container, off.bodykeys, off.nonce, pend.frame, 1)
    delete top.c.adopt_pending
    if (ident) {
        let body = this.Swarm_body_mine(ident)
        this.Swarm_deliver(w, ident, ident.sc.prepub, { kind: 'adopt_confirm', pub: off.bodykeys.pub, role: pend.frame.role, address: body ? body.sc.address : ident.sc.prepub + '_1' })
    }
    return ident
// ══ THE FERRY — the account crosses a pier the HANDSHAKE just formed (the real transfer, the fix) ═══════
//  The dead-end in the offer→seal→Swarm_deliver path: Swarm_deliver has no route to an un-paired device.
//   The fix is the proven order — the Captain mints a MyCave invite, the new device REDEEMS it (pier_hello
//    /accept forms the pier BOTH ways + cross-signs %Grant:MyCave, SwarmRole-proven), and ONLY THEN the
//     Captain ferries its sealed account over that pier, where Swarm_deliver finally routes.  Reuses
//      Swarm_export + seal/unseal (SwarmFerry-proven, fails closed) + Swarm_body_repost.  The seal `code`
//       rode the invite's URL FRAGMENT (#fc=…) — client-side, never on the relay — so a passive relay
//        never reads the account.  (Ephemeral-DH can replace the fragment later; the seam is the same.)

// Swarm_ferry_send — the CAPTAIN, once a MyCave pier has sealed: export the whole account, seal it under
//  `code`, deliver it over the pier (which now routes).  Returns did-it-cross.
async Swarm_ferry_send(w, soulIdent, pier, code):
    if (!pier || !code || !soulIdent?.c?.keys) { return false }
    let theirPub = pier.o({ Peering: 1 })[0]?.sc?.pub
    if (!theirPub) { return false }
    let salt = String(soulIdent.c.keys.pub) + ':' + String(theirPub)
    let blob = await this.Swarm_export(soulIdent)
    let sealed = await seal(String(code), salt, blob)
    // the soul's chosen NAME rides alongside (not secret — it's the public friendly a friend already sees) so
    //  the receiving device can say "receiving the soul of Steve" on the consent screen, not a raw pub8.  It is
    //   only a display hint; the account itself is inside `sealed` and is what actually authenticates.
    let friendly = String(soulIdent.sc.friendly || soulIdent.sc.nick || '')
    console.log('🦑 ferry: sending my account → ' + String(pier.sc.pub).slice(0, 8) + ' over the sealed pier')
    return this.Swarm_deliver(w, soulIdent, String(pier.sc.pub), { kind: 'ferry', sealed: sealed, salt: salt, role: 'Cave', friendly: friendly })
// Swarm_ferry_heard — the NEW DEVICE: unseal the account with the fragment code, import it (now it holds
//  the soul key), keep its pre-ferry identity as its BODY key, take its body row, and derive Post=Cave off
//   the MyCave grant that crossed at the handshake.  Fails closed: a wrong code / tampered frame throws in
//    unseal, so no account lands.  `ident` is this device's pre-ferry self; `code` came off #fc.
async Swarm_ferry_heard(w, ident, frame, code):
    if (!frame || !frame.sealed || !code || !ident) { return null }
    let container = ident.c.up
    if (!container) { return null }
    let priorPier = this.Swarm_peering(ident)?.o({ Pier: 1 })[0]
    let priorPost = priorPier ? this.Swarm_grant_post(priorPier) : null
    let bodykeys = ident.c.keys ? { pub: ident.c.keys.pub, key: ident.c.keys.key, prepub: ident.sc.prepub } : null
    let blob = null
    try { blob = await unseal(String(code), frame.salt, frame.sealed) } catch (e) { console.log('🦑 ferry: unseal failed (wrong code or tampered) — no account landed'); return null }
    let soul = this.Swarm_import(container, blob)
    if (!soul || !soul.c.keys) { return null }
    if (bodykeys) { soul.c.bodykey = bodykeys }
    let addr = soul.sc.prepub + '_1'
    let body = this.Swarm_body_take(soul, bodykeys ? bodykeys.pub : soul.sc.prepub, priorPost || 'Cave', addr)
    // THE NAME STAYS WITH THE INSTANCE (owner 2026-08-30: "Captain Grav and Cave Guw"): the name this
    //  human wrote at THIS device's name-gate belongs to THIS body — the landed soul's friendly must not
    //   swallow it.  Filed on the %Body row (the family's own address book, Ferry_todo facet D); friends
    //    still see the ONE soul's friendly.  The pre-ferry `ident` IS this device's named husk.
    if (body && ident.sc.friendly) { body.sc.name = String(ident.sc.friendly) }
    console.log('🦑 ferry: account landed — I am now a body of ' + String(soul.sc.prepub).slice(0, 8) + ' as ' + (priorPost || 'Cave'))
    return soul
// Swarm_ferry_link — the CAPTAIN's "make another device my Cave" link: mint a MyCave invite (whoever
//  redeems it dials me, forming the pier), and a random ferry SECRET stashed for the next redeem, carried
//   in the URL FRAGMENT so it never rides the relay.  Returns <base>#Iz=<token>&fc=<secret> (anchor form).
async Swarm_ferry_link(w, soulIdent, base, feature):
    // THE HELM IS ROLE-AWARE (Division_todo §0a #1, the owner: "a Cave produces another MyCave invite?
    //  I thought it would produce a MyCaptain, and that's how you resume from backup").  No caller
    //   choice defaults by MY OWN Post: a Captain (or undivided founder) grows the family with MyCave;
    //    a CAVE's one legitimate mint is MyCaptain — the succession/recovery token, regrowing the lost
    //     organ from a surviving one.  The ferry itself is Post-blind (the soul-holder always sends).
    let f = String(feature || '')
    if (!f) {
        let mine0 = this.Swarm_body_mine(soulIdent)
        f = mine0 && String(mine0.sc.role || '') === 'Cave' ? 'MyCaptain' : 'MyCave'
    }
    let feat = {}
    feat[f] = 1
    let iz = await this.Swarm_mint_invite(w, soulIdent, feat)
    let bytes = crypto.getRandomValues(new Uint8Array(16))
    let secret = Array.from(bytes, (b) => b.toString(16).padStart(2, '0')).join('')
    let top = this.top_House ? this.top_House() : null
    // THE ADOPT IS SINGULAR (owner 2026-08-31: "it is so important and rare to do a Link Device — eed could
    //  hold on to the current Adopt… Adopt will only be one at a time, so just require we already know about
    //   the Adopt token itself, instead of tracking claims+revokes").  The serial of THIS mint is the binding:
    //    every ask must present it (the Linkee reads it off its own ?Iz), and only the matching ceremony is
    //     served.  Minting again REPLACES the adopt — new serial, old asks fall off — and cancel just DROPS it.
    //      No pardon ledger, no per-pier revocation traffic for the ferry: possession of the one adopt IS consent.
    let atok = this.Swarm_token_parse ? this.Swarm_token_parse(iz) : null
    let aserial = atok ? String(atok.serial || '') : ''
    // THE CEREMONY IS THE REQ (Ferry_rebuild §4 Stage 3): minting again REPLACES the singular adopt — the
    //  one soul req is re-armed fresh (stale counterparty facts dropped, new secret on `.c`), and the phase
    //   verb's stash writes the ONE durable twin so a reload between mint and seal rehydrates it.
    // stamp the ceremony world BEFORE the host(1) vivify below (mint's host precedes its phase call).
    if (top && top.c && w) { top.c.ferry_world = w }
    let msh = this.Swarm_ferry_host(1)
    let msold = this.Swarm_ferry_role('soul')
    if (msold && msold.sc.finished && msh) { msh.drop(msold) }   // a swept-not-yet ghost: never re-arm a finished req
    let ms = this.Swarm_ferry_role('soul', 1)
    if (ms) {
        delete ms.sc.pub; delete ms.sc.name; delete ms.sc.held_at; delete ms.sc.why
        delete ms.c.ferrying
        ms.c.secret = secret
    }
    this.Swarm_expect_arrival(w)
    this.Swarm_ferry_phase(w, 'minted', { serial: aserial, role: 'soul' })
    console.log('🦑 ferry: offering to make a device my Cave — link minted (redeem forms the pier, then I ferry)')
    // ANCHOR FORM UNPARKED (2026-08-31).  The whole link rides the fragment — `#Iz=<token>&fc=<secret>`:
    //  the token never reaches a server log, the two legs are atomic against fragment strippers, and a
    //   link pasted into a RUNNING tab's bar lands via hashchange (SwarmStandup's listener → offer_land)
    //    with NO reload — the owner's "not needing to reload the page".  THE REAL 2026-08-30 KILLER,
    //     finally caught live (owner's URL showed `<token>this.fc()=<secret>`): .g's `&name`
    //      subroutine interpolation is NOT string-aware — a literal '&fc=' compiles to 'this.fc()='
    //       INSIDE the string, gluing an unparseable tail onto the token ("token extracts, parse
    //        refuses", exactly).  Hence the split literal below: '&' must never sit adjacent to an
    //         identifier in a .g string.  The round trip itself is clean (proven headlessly for
    //          hostile serials through iz_of_url's frag branch + token_parse + LinkDevice's
    //           (?:^#|&)fc= regex); InvFerry beat 3 asserts the anchor shape with the same split.
    return String(base) + '#Iz=' + encodeURIComponent(iz) + ('&' + 'fc=') + secret
// Swarm_ferry_on_seal — called when a %Pier seals: if it bears a MyCave grant AND I have a pending ferry
//  secret (I minted the link), ferry my account over the now-live pier.  No-op otherwise (a plain friend
//   seal, or a device that isn't mine).  This is the seam that fires the transfer at the right instant.
async Swarm_ferry_on_seal(w, soulIdent, pier):
    if (!pier || !this.Swarm_pier_linklive(pier)) { return }
    let top = this.top_House ? this.top_House() : null
    if (!top) { return }
    // secret from the live req OR the durable twin (a reloaded ceremony has only the stash)
    let secret = this.Swarm_ferry_secret()
    if (!secret) { return }
    // GRANTOR CONSENT ON THE PIER (live end-user only, OR a Book that raises top.c.consenter for the
    //  consent beat).  The account is the crown jewels; a real person at a humdinger tab confirms the
    //   exfiltration ON the adopting pier (Door), where the QR pulls them the instant it turns up.  PARK
    //    the ask keyed to this pier and send NOTHING — Swarm_ferry_confirm does the one send.
    //    A runner tab (no humdinger, no consenter — every ordinary Book) has nobody to ask, so it sends
    //     straight through here: SwarmSpread beat 5 (the-account-ferries-over) stays green by construction,
    //      no fixture churn.  InvWalk raises consenter to drive the park→puppet-confirm path headlessly.
    if (top.c && (top.c.humdinger || top.c.consenter)) {
        // ⚠ THE CHOKEPOINT WARMTH GATE (adversarial pass 2026-08-29): three callers reach here — the seal-seam
        //  (fresh redeem, warm by construction), the ferry_want hear (the pier JUST spoke, warm), and the RETRY
        //   PUMP (~1122), which picks its pier by GRANT alone and so could still park a phantom confirm for a
        //    cold stale cave (the "giving your soul to Gag ○ offline" shape, resurrected via the third door).
        //     One warmth check HERE covers all three; the Book/runner SEND branch below is untouched
        //      (Book piers carry no heard_at — gating the send would break SwarmSpread beat 5).
        //  (The UnInvite consult that lived beside the warmth check is GONE, 2026-08-31 — a declined ceremony is
        //   now a signed %NotGrant on the pier (Swarm_revoke at cancel), so a revoked cave never passes the
        //    pier_live gate at the TOP of this verb and never reaches here at all.  Consent is per-ceremony:
        //     a fresh mint + redeem seals a NEWER grant that outranks the tombstone — no pardon ledger, no
        //      "allow" affordance, the owner's "we mint serial invites? so we can just tick them off".)
        let pha = pier.c ? pier.c.heard_at : 0
        let pwarm = pha && (Date.now() - pha) < 45000 ? 1 : 0
        // OBSERVABLE BLOCK (owner 2026-08-29: "eed has no idea it's happening"): when we hear the ask but refuse to
        //  park a confirm, the log used to say NOTHING — indistinguishable from "responded".  Name the reason so the
        //   next two-device log shows WHY the "give your soul" never rose.  ~1/s (ferry_want is floor-throttled).
        if (!pwarm) {
            console.log('🦑 ferry: heard the ask from ' + String(pier.sc.pub || '?').slice(0, 8) + ' but NOT surfacing a confirm — pier is cold (no heard_at within 45s); the "give your soul" stays down')
            return
        }
        // THE PARK IS A PHASE WALK NOW: 'confirming' on the soul req is the parked confirm (pub/name ride
        //  its sc; the req sc write + the phase verb's own bump replace the old `.c` write + manual bump).
        //   The phase verb is change-gated, so the steady ask (~3s, the task-#24 contract) re-drives the
        //    pull without feeding the version loop; a park for a DIFFERENT pub simply re-stamps sc.pub.
        let psoul = this.Swarm_ferry_role('soul')
        let pnew = !(psoul && !psoul.sc.finished && psoul.sc.phase === 'confirming' && String(psoul.sc.pub || '') === String(pier.sc.pub)) ? 1 : 0
        this.Swarm_ferry_phase(w, 'confirming', { pub: String(pier.sc.pub), name: String(pier.sc.friendly || ''), role: 'soul' })
        if (pnew) { console.log('🦑 ferry: a device sealed as my Cave — awaiting my confirm on its pier (pulled up NOW) before I send') }
        return
    }
    let sent = await this.Swarm_ferry_send(w, soulIdent, pier, secret)
    if (sent) {
        let ssoul = this.Swarm_ferry_role('soul')
        if (ssoul) { delete ssoul.c.secret }
        this.Swarm_ferry_phase(w, 'sent', { pub: String(pier.sc.pub || ''), role: 'soul' })
    }
// Swarm_ferry_confirm — the grantor's "give my soul", pressed in the Link cell's "giving your soul to X" phase.
//  Flips the consent gate and performs the one send that on_seal was holding.  No parked ask (or no live pier
//   for it) → no-op.  Returns did-it-cross.
//  ⚠ MUST hold `ferrying` across the send (mirroring the FERRY RETRY at ~1108): we delete `ferry_confirm` and
//   then await the send, and the retry's guard is `fsecret && !ferrying`.  Without the flag, a pump firing
//    during the await re-runs on_seal, which finds `ferry_confirm` gone and re-PARKS a fresh one — then our
//     send clears the secret, leaving a stranded confirm with no secret (a dead "give my soul" that can't send).
async Swarm_ferry_confirm(w):
    let csoul = this.Swarm_ferry_role('soul')
    if (!(csoul && !csoul.sc.finished && csoul.sc.phase === 'confirming')) { return 0 }
    let ident = this.Swarm_live_self ? this.Swarm_live_self() : null
    if (!ident) { return 0 }
    let want = String(csoul.sc.pub || '')
    let pier = (this.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []).find((p) => String(p.sc.pub) === want && this.Swarm_pier_linklive(p))
    if (!pier) { return 0 }
    // ⚠ hold `ferrying` on the req across the send: a pump firing during the await must not re-park a
    //  fresh confirm (it would strand once the send clears the secret) — same guard as the retry pump.
    csoul.c.ferrying = 1
    let secret = this.Swarm_ferry_secret()
    if (!secret) { delete csoul.c.ferrying; return 0 }
    let sent = 0
    try { sent = await this.Swarm_ferry_send(w, ident, pier, secret) } catch (er) { sent = 0 }
    delete csoul.c.ferrying
    if (sent) {
        // the secret is SPENT; the phase walk to 'sent' IS the durable "waiting for its received" — the
        //  phase verb stashes the one twin, so a Linkor reload lands back on this screen (task #48).
        delete csoul.c.secret
        this.Swarm_ferry_phase(w, 'sent', { pub: want, role: 'soul' })
    }
    return sent ? 1 : 0
// Swarm_ferry_poke — the Linkor cell's reactive "has a Cave turned up, ready for my confirm?".  on_seal parks
//  ferry_confirm at the sealing instant, but that fires off the frame PUMP; this ties the SAME park to the UI's
//   REACTIVITY (H.version bumps the moment the %Pier appears in the tree), so the cell leaves the QR for the
//    "giving your soul" screen as soon as the Cave's pier is live — not on the next frame that happens to land.
//     Only PARKS (never sends — the human's "give my soul" still gates the send).  No-op once parked, or with
//      no secret, or with no live MyCave pier yet.  Returns 1 if a confirm is (now or already) parked.
Swarm_ferry_poke(w):
    let top = this.top_House ? this.top_House() : null
    if (!top || !top.c) { return 0 }
    let ksoul = this.Swarm_ferry_role('soul')
    // MID-SEND: Swarm_ferry_confirm holds `ferrying` on the req while it awaits the one send.  Poke must
    //  NOT re-raise a fresh confirm in that window (it would strand once the send clears the secret) —
    //   the same reason the seal-seam carries !ferrying.  Cheap guard that makes poke safe to call from
    //    reactivity/standup as often as we like, which the reload-heal now does.
    if (ksoul && ksoul.c.ferrying) { return 0 }
    if (ksoul && !ksoul.sc.finished && ksoul.sc.phase === 'confirming') { return 1 }
    let secret = this.Swarm_ferry_secret()
    if (!secret) { return 0 }
    let ident = this.Swarm_live_self ? this.Swarm_live_self() : null
    if (!ident) { return 0 }
    // ⚠ WARMTH + UNINVITE GATE (owner 2026-08-29: "giving your soul to and ○ offline … peer's name is 'and'").  This
    //  poke fires on EVERY version-bump while a secret is live, and it used to pick the FIRST grant-live MyCave pier —
    //   but a %Grant:MyCave persists for every device ever (half-)linked, so it grabbed a stale OFFLINE cave and parked
    //    a phantom "give your soul" to it (then link_fresh refused, spamming the COLD log).  A Cave has only truly
    //     "turned up, ready for my confirm" when it is PRESENT: heard_at within 45s.  Grant alone is not presence, and
    //      an UnInvited cave is barred.  So a fresh mint parks NOTHING until a real device redeems + dials (warm), at
    //       which point on_seal/this poke park it for real.
    // SINGULAR-ADOPT: park ONLY for the pier that is ASKING for the adopt I currently hold (owner 2026-08-31:
    //  "I go into Link to make another one, and a preexisting ceremony seems to grab me").  The ferry_want hear
    //   stamps ferry_want_at/_serial on the asking pier; poke used to grab the FIRST warm MyCave cave (a stale
    //    one from a past ceremony).  Now: warm AND recently-asking AND its ask serial matches my ferry_serial.
    let cser = this.Swarm_ferry_serial()
    let pier = (this.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []).find((p) => {
        // pier_live is the WHOLE consent check now (2026-08-31): a declined ceremony left a signed %NotGrant,
        //  so a revoked cave simply is not MyCave-live; a fresh redeem's newer grant stands.  No UnInvite ledger.
        if (!this.Swarm_pier_linklive(p)) { return 0 }
        let ha = p.c ? p.c.heard_at : 0
        if (!(ha && (Date.now() - ha) < 45000)) { return 0 }
        // it must be ASKING, recently, for THIS adopt (back-compat: honor if either side carried no serial).
        let wat = p.c ? p.c.ferry_want_at : 0
        if (!(wat && (Date.now() - wat) < 45000)) { return 0 }
        let pser = p.c ? String(p.c.ferry_want_serial || '') : ''
        if (cser && pser && cser !== pser) { return 0 }
        return 1
    })
    if (!pier) { return 0 }
    this.Swarm_ferry_phase(w, 'confirming', { pub: String(pier.sc.pub), name: String(pier.sc.friendly || ''), role: 'soul' })
    console.log('🦑 ferry: the Cave asking for THIS adopt turned up warm — parked the confirm (QR → give my soul)')
    return 1
// Swarm_offer_land — park the landed device-link consent off the bar: a `Iz` naming a MyCave IS the
//  standing fact "this tab was opened from a device link" (the ghost-side parking, owner 2026-08-30:
//   "relying on a certain cell being mounted to hear a message is quite the design dissonance").
//  Called at station STANDUP (a scanned link boots a fresh tab) AND on a HASHCHANGE (an anchor-form
//   link landing on a LIVE tab is a fragment change — no navigation, no reboot; owner 2026-08-30:
//    "does it need to navigate the page though?").  Reads the fragment first (`#Iz=…&fc=…`, the atomic
//     anchor form), the query as the old-link fallback.  Guarded: a mid-flight ceremony is never
//      disturbed; jsdom/Books carry no Iz → no-op → fixtures untouched.  `at` is the seizure clock —
//       Swarm_link_fresh holds the belly-grab until the Butler lifts or 20s pass (never mid-boot).
Swarm_offer_land(w):
    let top = this.top_House ? this.top_House() : null
    if (!top || !top.c) { return 0 }
    if (typeof location === 'undefined') { return 0 }
    // a live cave-side ceremony in ANY phase means the offer question is moot — never re-park over it.
    let ocav = this.Swarm_ferry_role('cave')
    if (ocav && !ocav.sc.finished && ocav.sc.phase) { return 0 }
    let liz = ''
    try {
        if (location.hash) { liz = new URLSearchParams(String(location.hash).slice(1)).get('Iz') || '' }
        if (!liz) { liz = new URLSearchParams(location.search).get('Iz') || '' }
    } catch (er) { liz = '' }
    if (!liz || typeof this.Swarm_token_parse !== 'function') { return 0 }
    let lt = null
    try { lt = this.Swarm_token_parse(liz) } catch (er) { lt = null }
    // ANY My<Post> link is a device link (§0a role-aware helm): MyCave grows a Cave; MyCaptain is the
    //  resume-from-backup act.  The conferred Post rides the offer so the consent face can say WHICH
    //   deal this is — becoming a Cave and becoming the Captain are different weights of yes.
    let lpost = lt ? this.Swarm_post_from_feature(lt.to) : null
    if (!lt || !lpost) { return 0 }
    this.Swarm_ferry_phase(w, 'offered', { pub: String(lt.prepub || ''), name: String(lt.friendly || ''), role: 'cave', post: lpost })
    // the seizure clock rides `.c` (ms — link_fresh holds the belly-grab until the Butler lifts): the offer
    //  itself is non-durable BY DESIGN, the URL is its durable copy (stash skips 'offered').
    let onow = this.Swarm_ferry_role('cave')
    if (onow) { onow.c.offer_at = Date.now() }
    console.log('🦑 ferry: this tab was opened from a device link — the "become them?" consent will rise once the boot surface is up')
    return 1

// Swarm_ferry_park — the NEW DEVICE heard the sealed account: park it for the human's consent (the UI has
//  the #fc fragment code and calls Swarm_ferry_consume).  Never auto-imports — becoming a body is decided.
Swarm_ferry_park(w, ident, frame):
    let top = this.top_House ? this.top_House() : null
    // a LANDING soul supersedes whatever the cave req held — awaiting, or a stale "called off" note racing
    //  a slow ferry frame: the phase walk to 'pending' IS that supersession (one req, one truth).  The
    //   parked FRAME is an object → `.c` only (objects in sc are fatal at encode), never stashed.
    if (top && top.c && w) { top.c.ferry_world = w }   // stamp before the role('cave',1) vivify below
    let kcav = this.Swarm_ferry_role('cave', 1)
    if (kcav) { kcav.c.pending = { frame: frame, at: this.Swarm_now(w) } }
    this.Swarm_ferry_phase(w, 'pending', { pub: (frame && frame.salt ? String(frame.salt).split(':')[0] : ''), role: 'cave' })
    console.log('🦑 ferry: an account arrived sealed to me over the pier — awaiting my consent + code')
    // THE HELD-ACK (owner 2026-08-30: at "waiting for its received", "AS BEFORE, several times now, I'm
    //  begging for more feedback around what's going on").  The soul's ONLY ack used to be ferry_got —
    //   which fires after the human here CONSENTS, so the Linkor's wait could not distinguish "sent into
    //    the void" from "delivered, their consent screen is up".  Tell it the sealed soul is HELD, right
    //     now, before any consent: the salt already names the soul (`<soulpub>:<mypub>`).  Humdinger-gated
    //      OR consenter-gated (a Book raising top.c.consenter can drive the ack in a test);
    //       a plain Book stays local → fixtures untouched.  Rides the reliable outbox like ferry_got.
    if (top && top.c && (top.c.humdinger || top.c.consenter) && frame && frame.salt) {
        let hsoul = String(frame.salt).split(':')[0]
        if (hsoul && ident) { try { this.Swarm_deliver(w, ident, hsoul, { kind: 'ferry_held', page: this.Swarm_page(ident) }) } catch (er) {} }
    }
    return true
// Swarm_ferry_pending — the UI reads whether a ferried account is waiting (returns 1 or null).
Swarm_ferry_pending(w):
    let pcav = this.Swarm_ferry_role('cave')
    return pcav && !pcav.sc.finished && pcav.sc.phase === 'pending' && pcav.c.pending ? 1 : null
// Swarm_ferry_peek — the UI reads the parked ferry (its frame carries the salt `<soulpub>:<mypub>`, so the
//  RECEIVE face can show WHOSE account is arriving for the human to eyeball). Read-only; never consumes.
Swarm_ferry_peek(w):
    let pcav = this.Swarm_ferry_role('cave')
    return pcav && !pcav.sc.finished && pcav.sc.phase === 'pending' && pcav.c.pending ? pcav.c.pending : null
// Swarm_ferry_sas — the 3-glyph SAS row for the device-link, computed IDENTICALLY on both ends from the two
//  pubs the ferry `salt` already binds (`<soulpub>:<bodypub>`).  The GRANTOR reads soul off its live self and
//   the body off the confirm pier's Peering pub — the SAME source Swarm_ferry_send builds the salt from, so the
//    two rows are byte-equal absent a MITM.  The NEW device reads both straight off the parked frame's salt.
//     Equal rows on both screens ⇒ no relay swapped a pub (owner: "three icons to match, like jackpot
//      machines").  No nonce: the row's whole job is to expose a swapped pub, and the human compares live.
async Swarm_ferry_sas(w):
    let top = this.top_House ? this.top_House() : null
    if (!top || !top.c) { return '' }
    let facts = this.Swarm_ferry_facts(w)
    let soulpub = ''
    let bodypub = ''
    if (facts.confirm) {
        let ident = this.Swarm_live_self ? this.Swarm_live_self() : null
        if (!ident || !ident.c || !ident.c.keys) { return '' }
        let want = String(facts.confirm.pub)
        let pier = (this.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []).find((p) => String(p.sc.pub) === want)
        let theirPub = pier ? pier.o({ Peering: 1 })[0]?.sc?.pub : null
        soulpub = String(ident.c.keys.pub)
        bodypub = String(theirPub || want)
    } else if (facts.pending && facts.pending.frame && facts.pending.frame.salt) {
        let parts = String(facts.pending.frame.salt).split(':')
        soulpub = parts[0] || ''
        bodypub = parts[1] || ''
    } else if (facts.awaiting) {
        // the RECEIVER during "connecting" (pre-ferry): the frame hasn't landed, but the two pubs the salt will
        //  bind are ALREADY on the MyCave pier — the peer's Peering pub is the SOUL (the same value the Linkor
        //   salts with), my own key pub is the BODY.  Compute the SAS now so it shows on THIS screen at the same
        //    time as the Linkor's "giving your soul", to be matched — not only after the account has crossed.
        let ident = this.Swarm_live_self ? this.Swarm_live_self() : null
        if (ident && ident.c && ident.c.keys) {
            let pier = (this.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []).find((p) => this.Swarm_pier_linklive(p))
            let peerPub = pier ? (pier.o({ Peering: 1 })[0]?.sc?.pub || pier.sc.pub) : null
            if (peerPub) { soulpub = String(peerPub); bodypub = String(ident.c.keys.pub) }
        }
    }
    if (!soulpub || !bodypub) { return '' }
    return await sas_row(sas_transcript([soulpub, bodypub]), 3)
// ── THE FERRY REQ (Ferry_rebuild §4 Stage 3, owner 2026-08-31 "perhaps req-stack then… LiesStore was the
//  best req example") — the ceremony STOPS being ~14 flags latched on H:Mundo's snap-blind `.c` and becomes
//   a req hosted ON top (H:Mundo — the tab-singleton seat; see Swarm_ferry_host for why not w:Swarm),
//    LiesStore-shaped: one eternal `req:Ferry` pump hosting at most two children,
//    `req:Ferry_soul` and `req:Ferry_cave`, whose `sc.phase` walk IS the ceremony.  What this buys, exactly:
//     * sc IS LEGIBLE MATTER — `req:Ferry_soul,phase:confirming,pub:…` is a real particle row the daemon's
//        /c dump and the Cyto graph can SEE (the owner's "we only see H/** not H.c.*" — the whole disease
//         in one sentence; full Book-fixture visibility comes when a Book hosts its ceremony on its own w);
//     * one truth per role instead of a flag pile — offer→awaiting→pending is ONE cave req overwriting its
//        own phase, so the "delete the other five flags" dance at every seam simply stops existing;
//     * ONE durable twin (stashed.ferry, ms clocks) replaces the three (whose seconds-vs-ms staleness cap
//        was silently dropping every twin at standup — the #48 reload-survival bug, fixed by construction).
//  The SECRET and the parked FRAME stay on req.c (never sc — the secret must not snap, the frame is an
//   object and objects in sc are fatal at encode).  Books share the role split: InvWalk's two puppet ends
//    are exactly the two role reqs on the runner's one w:Swarm.
// Phases — soul: minted → confirming → sent → held → got, terminal receipts ended|cancelled;
//          cave: offered → awaiting → pending → received, terminal receipts ended|declined.
//  A receipt phase (got/ended/received/declined-shown) keeps the req ALIVE for the human's `done`;
//   `cancelled`/`declined`/`done` FINISH the req(s) and the pump sweeps them (two-pass, sc.seen).
Swarm_ferry_host(vivify):
    // the pump req lives on the CEREMONY'S OWN WORLD `w` — `w:Swarm` on a live tab (in the account tree,
    //  so Cyto + the daemon /c dump SEE it), `w:<Book>` in a Book (RIGHT IN THE STEP SNAP — the owner's
    //   "why can't we see any of it in snap?", 2026-08-31).  NOT on `top` (Mundo): in a Book that is the
    //    runner's Mundo, one House ABOVE the Book's snapped world, so the ceremony was invisible there.
    //     The world is a runtime ref stamped by the last write (Swarm_ferry_phase/reheal/mint/park set
    //      top.c.ferry_world = w — a `.c` pointer, the kind `.c` is FOR, never snapped); a live-tab pure
    //       read with no stamp yet falls back to finding w:Swarm directly.  reqdo_sweep pumps A→w, so a
    //        req on w:Swarm/w:<Book> is driven for free.
    let top = this.top_House ? this.top_House() : null
    if (!top) { return null }
    let cw = top.c ? top.c.ferry_world : null
    if (!cw) {
        let A = top.o({ A: 'Clustation' })[0]
        cw = A ? A.o({ w: 'Swarm' })[0] : null
    }
    if (!cw) { return null }
    let h = cw.o({ req: 'Ferry' })[0]
    if (!h && vivify) { h = cw.oai({ req: 'Ferry', eternal: 1 }); h.c.up = cw }
    return h || null
Swarm_ferry_role(role, vivify):
    // the ceremony req for one role ('soul' | 'cave') — the singular-adopt law makes role the identity.
    let h = this.Swarm_ferry_host(vivify)
    if (!h) { return null }
    let q = { req: 'Ferry_' + String(role) }
    let r = h.o(q)[0]
    if (!r && vivify) { r = h.i(q); r.c.up = h }
    return r || null
// req_Ferry — the pump do_fn (reqdo_sweep drives it every belief beat): pump the ceremony children,
//  then sweep finished ones with LiesStore's two-pass contract (first pass stamps seen so any reader
//   gets one full cycle at the receipt, second pass drops).
async req_Ferry(req):
    await req.do()
    for (const ch of req.o({ req: 1 })) {
        if (!ch.sc.finished) { continue }
        if (ch.sc.seen) { req.drop(ch); continue }
        ch.sc.seen = 1
    }
// the per-role do_fns are INERT: the ceremony is driven by the wire + the human (every transition is a
//  Swarm_ferry_phase call that writes the sc directly), NOT by the pump.  They exist only so do() finds a
//   handler when reqdo_sweep pumps the host world's reqs — no ttlilt (a waiting phase does not want Story
//    to hold quiescence; the Book drives each beat explicitly, and a ttlilt would only add snap noise +
//     run-volatile dige flap for zero gain).
req_Ferry_soul(req):
    return
req_Ferry_cave(req):
    return
// Swarm_ferry_secret — THE one way to read the soul's ferry secret: the live req's `.c`, else the durable
//  twin (re-derived onto the req so the whole live seam reads consistently — the old 1057 pattern, now law).
Swarm_ferry_secret():
    let s = this.Swarm_ferry_role('soul')
    if (s && s.c.secret) { return s.c.secret }
    let top = this.top_House ? this.top_House() : null
    let tw = top && top.stashed && top.stashed.ferry && top.stashed.ferry.soul ? top.stashed.ferry.soul : null
    if (tw && tw.secret) {
        if (s) { s.c.secret = tw.secret }
        return tw.secret
    }
    return null
Swarm_ferry_serial():
    let s = this.Swarm_ferry_role('soul')
    if (s && s.sc.serial) { return String(s.sc.serial) }
    let top = this.top_House ? this.top_House() : null
    let tw = top && top.stashed && top.stashed.ferry && top.stashed.ferry.soul ? top.stashed.ferry.soul : null
    return tw && tw.serial ? String(tw.serial) : ''
// Swarm_ferry_stash — mirror the live ceremony reqs to the ONE durable twin (top.stashed.ferry, ms clocks).
//  Only phases whose reload-survival means something are stashed: a soul mid-ceremony (minted/confirming —
//   stashed as minted, a confirm re-parks off the wire demand, never off a boot guess) and its sent/held
//    wait; a cave's awaiting (pending downgrades to awaiting — the frame can't survive, the steady ask
//     re-pulls the soul to resend, which is the natural fall-through).  Receipts/offers don't stash (the
//      URL is the offer's durable copy).  Empty → the twin is deleted, so link_active falls with the last req.
Swarm_ferry_stash():
    let top = this.top_House ? this.top_House() : null
    if (!top || !top.stashed) { return }
    let out = {}
    let any = 0
    let s = this.Swarm_ferry_role('soul')
    if (s && !s.sc.finished) {
        let ph = String(s.sc.phase || '')
        let keep = ph === 'minted' || ph === 'confirming' ? 'minted' : (ph === 'sent' || ph === 'held' ? ph : '')
        if (keep) {
            let e = { phase: keep, at: Date.now() }
            if (s.sc.serial) { e.serial = String(s.sc.serial) }
            if (s.sc.pub) { e.pub = String(s.sc.pub) }
            if (s.c.secret) { e.secret = s.c.secret }
            if (s.sc.held_at) { e.held_at = s.sc.held_at }
            out.soul = e
            any = 1
        }
    }
    let c = this.Swarm_ferry_role('cave')
    if (c && !c.sc.finished) {
        let ph = String(c.sc.phase || '')
        if (ph === 'awaiting' || ph === 'pending') {
            let e = { phase: 'awaiting', at: Date.now() }
            if (c.sc.serial) { e.serial = String(c.sc.serial) }
            if (c.sc.pub) { e.pub = String(c.sc.pub) }
            out.cave = e
            any = 1
        }
    }
    if (any) { top.stashed.ferry = out } else { delete top.stashed.ferry }
// Swarm_ferry_reheal — standup (and any belated read): the durable twin re-seeds the ceremony reqs a reload
//  lost.  A twin older than 10min is a dead ghost and is dropped, not restored (ms clocks BOTH sides now —
//   the old cap compared Date.now() ms against Swarm_now seconds and so dropped EVERY twin).  Idempotent:
//    a live req with a phase is never clobbered.
Swarm_ferry_reheal(w):
    let top = this.top_House ? this.top_House() : null
    let tw = top && top.stashed ? top.stashed.ferry : null
    if (!tw) { return 0 }
    if (top.c && w) { top.c.ferry_world = w }   // stamp before the role(role,1) vivify below
    let FERRY_STALE = 600000
    let n = 0
    for (const role of ['soul', 'cave']) {
        let e = tw[role]
        if (!e) { continue }
        if (e.at && (Date.now() - e.at) > FERRY_STALE) { delete tw[role]; continue }
        let r = this.Swarm_ferry_role(role, 1)
        if (!r) { continue }
        if (!r.sc.phase) {
            r.sc.phase = String(e.phase || (role === 'soul' ? 'minted' : 'awaiting'))
            if (e.serial) { r.sc.serial = String(e.serial) }
            if (e.pub) { r.sc.pub = String(e.pub) }
            if (e.held_at) { r.sc.held_at = e.held_at }
            r.sc.at = this.Swarm_now(w)
            n = n + 1
        }
        if (e.secret && !r.c.secret) { r.c.secret = e.secret }
    }
    if (!tw.soul && !tw.cave) { delete top.stashed.ferry }
    if (n) { console.log('🦑 ferry: rehydrated ' + n + ' ceremony end(s) across a reload off the one durable twin') }
    return n
// Swarm_ferry_facts — the ONE read surface for UI + Books: the flag pile's old shapes, synthesized off the
//  two role reqs, so a consumer asks for the ceremony ONCE instead of spelunking `.c`.  secret is presence
//   (1|0), never the string — the string stays inside the ghost (Swarm_ferry_secret).
Swarm_ferry_facts(w):
    let s = this.Swarm_ferry_role('soul')
    let c = this.Swarm_ferry_role('cave')
    let top = this.top_House ? this.top_House() : null
    let f = { secret: 0, serial: '', ferrying: 0, offer: null, awaiting: null, pending: null, confirm: null, sent: null, got: null, ended: null, twin: null }
    f.secret = this.Swarm_ferry_secret() ? 1 : 0
    f.serial = this.Swarm_ferry_serial()
    if (s && !s.sc.finished) {
        let ph = String(s.sc.phase || '')
        if (s.c.ferrying) { f.ferrying = 1 }
        if (ph === 'confirming') { f.confirm = { pub: String(s.sc.pub || ''), name: String(s.sc.name || ''), at: s.sc.at } }
        if (ph === 'sent' || ph === 'held') { f.sent = { pub: String(s.sc.pub || ''), at: s.sc.at, held: s.sc.held_at || 0 } }
        if (ph === 'got') { f.got = { pub: String(s.sc.pub || ''), at: s.sc.at } }
        if (ph === 'ended') { f.ended = { by: String(s.sc.pub || ''), at: s.sc.at, why: String(s.sc.why || ''), role: 'soul' } }
    }
    if (c && !c.sc.finished) {
        let ph = String(c.sc.phase || '')
        if (ph === 'offered') { f.offer = { from: String(c.sc.pub || ''), friendly: String(c.sc.name || ''), post: String(c.sc.post || ''), at: c.c.offer_at || 0 } }
        if (ph === 'awaiting') { f.awaiting = { soul: String(c.sc.pub || ''), serial: String(c.sc.serial || ''), at: c.sc.at } }
        if (ph === 'pending' && c.c.pending) { f.pending = c.c.pending }
        if (ph === 'ended') { f.ended = { by: String(c.sc.pub || ''), at: c.sc.at, why: String(c.sc.why || ''), role: 'cave' } }
    }
    if (top && top.stashed && top.stashed.ferry) { f.twin = top.stashed.ferry }
    return f
// Swarm_ferry_done — the human's terminal `done` (LinkDevice): FINISH both ceremony reqs (the pump sweeps
//  them), clear the twin, record the terminal on the %Ferry mirror.  A completed link has no counterparty
//   left to notify — a local pack-up, NOT Swarm_ferry_cancel.
Swarm_ferry_done(w):
    let h = this.Swarm_ferry_host()
    if (h) {
        for (const role of ['soul', 'cave']) {
            let r = this.Swarm_ferry_role(role)
            if (r && !r.sc.finished) { delete r.c.secret; delete r.c.pending; h.finish(r) }
        }
    }
    let top = this.top_House ? this.top_House() : null
    if (top && top.stashed) { delete top.stashed.ferry }
    return 1
// ── THE %FERRY PARTICLE (Ferry_todo §2 — the big refactor's spine, owner 2026-08-30 "go ahead then!") ──
//  POST-REBUILD (Ferry_rebuild §4 Stage 3): the ceremony's STORAGE is the two top-hosted role reqs
//   (Swarm_ferry_role) — that migration is DONE, the ~14 top.c.ferry_* flags are gone.  This `%Ferry`
//    particle under A:Clustation→w:Swarm is now only the live tab's ONE-GLANCE MIRROR + the SURFACE
//     POLICY seat (Radio_pop_glass / Sounditron_link_open, humdinger-gated).  Swarm_ferry_phase writes
//      the req FIRST (needs only `top`, so it advances headlessly — the Book can read the req), then
//       mirrors here IF a Swarm world exists.  Swarm_ferry_particle stays as the mirror's pure reader.
// Phases — soul: minted → confirming → sent → held → got, receipts ended|cancelled;
//          cave: offered → awaiting → pending → received, receipts ended|declined|cancelled.
Swarm_ferry_particle(w):
    // pure find (never mint): the pure A:Clustation → w:Swarm walk, so probes (UI ticks) can't vivify.
    let top = this.top_House ? this.top_House() : null
    let A = top ? top.o({ A: 'Clustation' })[0] : null
    let sw = A ? A.o({ w: 'Swarm' })[0] : null
    return sw ? sw.o({ Ferry: 1 })[0] : null
Swarm_ferry_phase(w, phase, patch):
    let top = this.top_House ? this.top_House() : null
    if (!top || !top.c) { return null }
    // STAMP THE CEREMONY WORLD (the runtime ref Swarm_ferry_host resolves against — see there): this
    //  chokepoint runs before any role read/vivify below, so a Book's w:<Book> (snap-visible) or the
    //   live tab's w:Swarm is set before req:Ferry is created on it.  `.c` ref, never snapped.
    if (w && top.c) { top.c.ferry_world = w }
    // ── THE REQ IS THE STORAGE NOW (Ferry_rebuild §4 Stage 3), and it comes FIRST: the req work needs
    //  only `top` (Mundo — exists on every tab AND headless), while the %Ferry mirror + surface policy
    //   below still need the live tab's A:Clustation→w:Swarm.  The old order bailed on `!sw` BEFORE any
    //    write, which made every phase a silent no-op on a runner — the exact Book-blindness this
    //     rebuild exists to end (caught by InvSeal beat 4 the first time the req machinery was gated).
    //  Role resolves: patch.role, else whichever ceremony req is live, else 'soul'.
    let role = patch && patch.role ? String(patch.role) : ''
    if (!role) {
        let rs = this.Swarm_ferry_role('soul')
        let rc = this.Swarm_ferry_role('cave')
        if (rs && !rs.sc.finished && rs.sc.phase) { role = 'soul' }
        if (!role && rc && !rc.sc.finished && rc.sc.phase) { role = 'cave' }
        if (!role) { role = 'soul' }
    }
    // SWEEP the finished receipts (LiesStore's two-pass contract, run here because the top-hosted req is
    //  outside reqdo_sweep's A/w walk): first sight stamps seen, next phase call drops.  Bounded ≤2.
    let swh = this.Swarm_ferry_host()
    if (swh) {
        for (const swc of swh.o({ req: 1 })) {
            if (!swc.sc.finished) { continue }
            if (swc.sc.seen) { swh.drop(swc); continue }
            swc.sc.seen = 1
        }
    }
    // terminal FINISHERS: cancelled kills both ends' reqs, declined kills the cave's, done is its own verb.
    if (phase === 'cancelled' || phase === 'declined') {
        let hh = this.Swarm_ferry_host()
        if (hh) {
            for (const rr of ['soul', 'cave']) {
                if (phase === 'declined' && rr !== 'cave') { continue }
                let rq = this.Swarm_ferry_role(rr)
                if (rq && !rq.sc.finished) { delete rq.c.secret; delete rq.c.pending; hh.finish(rq) }
            }
        }
    } else {
        let rq = this.Swarm_ferry_role(role, 1)
        if (rq) {
            let rchanged = rq.sc.phase !== String(phase) ? 1 : 0
            if (patch) {
                if (patch.pub && rq.sc.pub !== String(patch.pub)) { rq.sc.pub = String(patch.pub); rchanged = 1 }
                if (patch.name && rq.sc.name !== String(patch.name)) { rq.sc.name = String(patch.name); rchanged = 1 }
                if (patch.serial && rq.sc.serial !== String(patch.serial)) { rq.sc.serial = String(patch.serial); rchanged = 1 }
                if (patch.why && rq.sc.why !== String(patch.why)) { rq.sc.why = String(patch.why); rchanged = 1 }
                if (patch.post && rq.sc.post !== String(patch.post)) { rq.sc.post = String(patch.post); rchanged = 1 }
            }
            if (rchanged) { rq.sc.phase = String(phase); rq.sc.at = this.Swarm_now(w) }
        }
    }
    this.Swarm_ferry_stash()
    // THE %FERRY MIRROR + SURFACE POLICY — needs the live tab's A:Clustation→w:Swarm, which a Book runner
    //  tab does NOT have (no login → no Swarm world).  So resolve it HERE, AFTER the req work above has
    //   already landed on `top`: no Swarm world → the observable req still advanced, we just skip the
    //    one-glance mirror and the humdinger surface pull (a Book has neither anyway).  This ordering is
    //     the whole fix for the Book-blindness the rebuild exists to end.
    let A = top.o({ A: 'Clustation' })[0]
    let sw = A ? A.o({ w: 'Swarm' })[0] : null
    if (!sw) { return null }
    let f = sw.oai({ Ferry: 1 })
    f.c.up = sw
    // IDEMPOTENT RE-ASSERT (owner 2026-08-31, "the origin eed Link is going spastic" — Door faces
    //  mounting/destroying every tick): the poke/ask reheal paths RE-assert their phase every beat,
    //   and a verb that bumped + re-surfaced on every identical call fed the version loop its own
    //    output (poke → 'confirming' → bump → $effect → poke …).  A call that changes NOTHING now
    //     returns quietly: no at re-stamp (at = when the phase was ENTERED), no bump, no surface.
    //      The first transition still pulls the screen; a human who then walks away is not re-grabbed.
    let changed = f.sc.phase !== String(phase) ? 1 : 0
    if (patch) {
        if (patch.pub && f.sc.pub !== String(patch.pub)) { f.sc.pub = String(patch.pub); changed = 1 }
        if (patch.name && f.sc.name !== String(patch.name)) { f.sc.name = String(patch.name); changed = 1 }
        if (patch.serial && f.sc.serial !== String(patch.serial)) { f.sc.serial = String(patch.serial); changed = 1 }
        if (patch.role && f.sc.role !== String(patch.role)) { f.sc.role = String(patch.role); changed = 1 }
    }
    if (!changed) { return f }
    f.sc.phase = String(phase)
    f.sc.at = this.Swarm_now(w)
    // TERMINALS drop the particle's counterpart facts so the next ceremony starts clean (the particle
    //  itself stays — its terminal phase is the legible receipt until the next mint overwrites it).
    // THE SURFACE POLICY — one place (was four patches: bump/poke/pop_glass/link_open).  Humdinger-gated
    //  whole: a Book's ceremony advances the particle (snap-visible) but never touches focus.
    if (top.c.humdinger) {
        let pull = phase === 'confirming' || phase === 'pending' || phase === 'held' || phase === 'got' || phase === 'ended' || phase === 'received'
        if (pull) {
            try { if (typeof this.Radio_pop_glass === 'function') this.Radio_pop_glass() } catch (er) {}
            try { if (typeof this.Sounditron_link_open === 'function') this.Sounditron_link_open(w) } catch (er) {}
        }
        if (phase === 'done') {
            try { if (typeof this.Sounditron_link_done === 'function') this.Sounditron_link_done(w) } catch (er) {}
        }
    }
    if (top.bump_version) { top.bump_version() }
    return f
// Swarm_link_active — is a device-link ceremony in flight on THIS tab? True on the SOUL device while its
//  link is minted-and-unspent (top.c.ferry_secret) AND on the NEW device while a ferried account waits
//   (top.c.ferry_pending).  The glass reads this to raise the %Link takeover cell exactly during the
//    ceremony and drop it back to Door|Radio the instant it's done (LinkFace / Sounditron_commission).
Swarm_link_active(w):
    let top = this.top_House ? this.top_House() : null
    if (!top || !top.c) { return null }
    // a ceremony req ALIVE in any phase (receipts included — 'ended'/'got' hold the cell up for the human's
    //  `done`), or the durable twin (a reload's claim on the ceremony before reheal has run) → in flight.
    let s = this.Swarm_ferry_role('soul')
    let c = this.Swarm_ferry_role('cave')
    let live = (s && !s.sc.finished && s.sc.phase) || (c && !c.sc.finished && c.sc.phase) ? 1 : 0
    let durable = top.stashed && top.stashed.ferry ? 1 : 0
    return live || durable ? 1 : null
// Swarm_link_fresh — is the ceremony fresh enough to SEIZE THE SCREEN?  Swarm_link_active answers "any ferry
//  state present", which is right for durable persistence but WRONG for grabbing focus.  THE UNUSABLE BUG
//   (owner 2026-08-29, testing live): a boot went straight into "giving your soul to ○ <peer>" where the peer
//    was the first Pier in the list, OFFLINE FOR AGES.  Two rot sources: (a) `Swarm_pier_live(p,'MyCave')` is a
//     GRANT check with no presence, so a %Grant:MyCave from a ceremony days ago still reads "live" and the
//      standup reheal re-parks `ferry_confirm` off that corpse; (b) this fn only gated the AWAITING (Linkee)
//       side, so a stale `ferry_confirm` (Linkor) hit `return 1` and ALWAYS grabbed the screen.  Fix: a
//        ceremony seizes the screen ONLY while its counterparty pier is WARM — actually heard_at-recent or
//         socket-fresh — never on grant alone.  A live reload re-warms heard_at within a pulse (~5s) and
//          re-surfaces on its own; a dead one never does, so it stays reachable via the Door but stops
//           hijacking.  A declined ceremony needs no consult here (2026-08-31): its %NotGrant means the
//            poke/on_seal gates never park state for it, so there is nothing fresh to seize with.
//   Still identical to link_active for Books / non-live tabs (no humdinger → fixtures byte-identical).
Swarm_link_fresh(w):
    let active = this.Swarm_link_active(w)
    if (!active) { return active }
    let top = this.top_House ? this.top_House() : null
    if (!top || !top.c || !top.c.humdinger) { return active }
    let facts = this.Swarm_ferry_facts(w)
    // the RECEIVER's landed account (pending) always deserves the screen: it's HERE and needs the
    //  human's #fc consent — there is no counterparty-presence question to ask.
    if (facts.pending) { return 1 }
    // a freshly-OPENED device link awaiting the human's "become them?" consent (top.c.ferry_offer, parked
    //  ghost-side at standup off the landed ?Iz URL): their own deliberate act, so seize the screen to ask —
    //   there is no counterparty to have dialed yet, and the offer is non-durable so a stale one can't survive
    //    a reload (the URL is its durable copy).
    //  …but NOT MID-BOOT (owner 2026-08-30: "the state of ferry is kicking off way too early" — the consent
    //   cell seized a half-built stage, rendering giant/mispositioned over a boot that hadn't reached the
    //    Radio, while the splash/Butler still owned the screen).  The offer PARKS at standup (that fact is
    //     durable and early by design); the SEIZURE waits for the STAGE, read as a machine fact.
    //  ⚠ THE HOLD USED TO READ `top.c.butler_up` — AND THAT WAS A CIRCLE (found 2026-08-31, the incognito
    //   first-boot splash hang): the Butler's own ceremony-lift consults this verb (via Screen_decide's
    //    phase now, link_fresh(null) before), while this verb consulted the flag the Butler holds up —
    //     so a device-link boot waited on the Butler, which waited on us, until the 120s valve.  The
    //      reload "fix" only worked because the stashed thin choice rebooted down a different road.
    //  NOW: `glass_wanted`/`glass_stood` — mirrored onto top.c by the page itself (BigSoundland, the same
    //   .c-mirror pattern as boot_gate's ac_wanted) — say "this page intends a glass" and "the glass has
    //    actually mounted".  A glass-page offer holds only while the glass is genuinely still building; a
    //     page that never wants a glass (an ?Iz landing on a non-glass room) never holds at all — which is
    //      also the pre-2026-08-30 behavior for Butler-less pages.  Grace: an arrival that never comes must
    //       not strand the consent — the valve sits FAR above any honest boot (a slow remote-wormhole boot
    //        is ~25s).  120s: only a truly wedged boot gets overridden.
    if (facts.offer) {
        let ofr = facts.offer
        let building = top.c.glass_wanted && !top.c.glass_stood ? 1 : 0
        if (!building || (ofr.at && (Date.now() - ofr.at) > 120000)) { return 1 }
        return null
    }
    // a ceremony that ENDED (the far side called it off) needs the human's one `done` ack — the terminal screen
    //  is the whole point (never a silent vanish), so it deserves the screen exactly once.
    if (facts.ended) { return 1 }
    let ident = this.Swarm_live_self ? this.Swarm_live_self() : null
    let piers = ident ? (this.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []) : []
    // warm(pub) — is the pier we'd transact with ACTUALLY PRESENT?  ONLY per-pier `heard_at` (a voucher-checked
    //  frame from THEM in the last 45s) counts as positive presence.  ⚠ NOT Swarm_socket_fresh — it ignores its
    //   `p` arg and reads the GLOBAL relay-wire stamp (its own contract: "never as positive per-pier evidence"),
    //    so ORing it in made every pier read warm whenever our relay was chatty → "giving your soul to Gag ●
    //     online" for a peer that is not there (owner 2026-08-29).  Grant-liveness is likewise NOT accepted.
    let warm = (pub) => {
        if (!pub) { return 0 }
        let p = piers.find((q) => { let qp = String(q.sc.pub || ''); return qp && (qp === pub || qp.startsWith(pub) || pub.startsWith(qp)) ? 1 : 0 })
        if (!p || !p.c) { return 0 }
        let ha = p.c.heard_at || 0
        return ha && (Date.now() - ha) < 45000 ? 1 : 0
    }
    // SOUL side, "giving your soul": only seize while the Cave we'd give to is warm, and never for a pub the
    //  human already UnInvited (clicked "no" on — it stays reachable via the Door but won't hijack again).
    // ⚠ NO console.log in these branches — link_fresh is read on EVERY version-bump, so a log here MACHINE-GUNS the
    //  console (owner 2026-08-29 saw dozens of "COLD" lines/sec).  The decision is silent; the poke/on_seal warmth
    //   gate is what keeps a cold confirm from being parked in the first place.
    if (facts.confirm) {
        return warm(String(facts.confirm.pub || '')) ? 1 : null
    }
    // SOUL side, "waiting for its received": the soul has crossed; re-seize to CLOSE the arc (✓ received) ONLY while
    //  the Cave we fed is warm.  A rehydrated wait for a Cave that never comes back stays reachable via the Door but
    //   must not hijack — same warmth + UnInvite contract as the confirm branch just above.
    if (facts.sent) {
        return warm(String(facts.sent.pub || '')) ? 1 : null
    }
    // RECEIVER awaiting the soul ("connecting…"): only while the soul pier is warm.
    if (facts.awaiting) {
        let soul = String(facts.awaiting.soul || '')
        let target = soul
        if (!target && piers.length === 1) { target = String(piers[0].sc.pub || '') }
        return warm(target) ? 1 : null
    }
    // SOUL side, a bare unspent secret (minted QR nobody has sealed yet): this is the human's OWN standing
    //  intent, but with no counterparty it must NOT auto-seize on boot — the lobby (top.c.link_lobby, set when
    //   the human opens Door → Link) keeps a FRESHLY-minted QR up; a leftover from a past session stays a
    //    reachable "link in flight" on the Door without grabbing the screen.  on_seal re-parks a confirm the
    //     instant a real Cave seals, and THAT (warm) re-surfaces it.
    return null
// (The UnInvite verbs — Swarm_ferry_uninvite/_uninvited/_reinvite, a durable pub-keyed decline set — lived
//  here 2026-08-29→31 and are GONE, on the owner's ruling: "where in the interface can we cancel a
//   cancellation to a specific Pier? why would we — why not some slightly different arrangement that makes
//    it EASIER."  The easier arrangement is the codebase's own law: a "no" is a signed %NotGrant on the pier
//     (Swarm_revoke, §6.4), pier_live is latest-safety-state, and a fresh mint+redeem seals a newer grant that
//      outranks the tombstone.  Two verbs total — "link a device" and "no" — no pardon ledger, no allow button.
//       Any stashed.uninvited left in old accounts is simply never read again.)
// Swarm_ferry_cancel — the human's "call off this link" (the Link cell's reset button).  Clears every trace
//  of an in-flight device-link on THIS tab: the soul's unspent secret (live seam + durable twin) and any
//   parked inbound account.  Idempotent — safe to press when nothing is in flight — and the one honest way
//    out of a wedged ceremony that the old inline hatch never offered.
Swarm_ferry_cancel(w):
    let top = this.top_House ? this.top_House() : null
    if (!top || !top.c) { return 0 }
    let cfacts = this.Swarm_ferry_facts(w)
    // TELL THE CAVE (the owner's teardown: eed cancelling the token is HOW 495 gives up).  Before we drop our
    //  state, fire a best-effort ferry_cancel to the Cave we were about to feed — the Linkor knows its pier from
    //   the parked confirm's pub, else any live MyCave pier.  Humdinger-gated: only a real person cancels-and-tells
    //    (a Book calls cancel as a local test artifact and has no humdinger — so this stays Book-inert, no fixture
    //     frame).  A Linkee cancelling holds no secret/confirm, so the guard below finds no grantor pier and
    //      it simply gives up locally.
    let ct_ident = this.Swarm_live_self ? this.Swarm_live_self() : null
    if (top.c.humdinger && ct_ident && (cfacts.confirm || cfacts.secret)) {
        let want = cfacts.confirm ? String(cfacts.confirm.pub) : null
        for (const pier of this.Swarm_peering(ct_ident)?.o({ Pier: 1 }) ?? []) {
            if (!this.Swarm_pier_linklive(pier)) { continue }
            if (want && String(pier.sc.pub) !== want) { continue }
            this.Swarm_deliver(w, ct_ident, pier.sc.pub, { kind: 'ferry_cancel', page: this.Swarm_page(ct_ident) })
        }
    }
    // LINKEE TELLS THE SOUL (owner 2026-08-31: "the incognito side cancelling doesn't cancel eed's interest in
    //  it").  A Linkee holds an awaiting, not a secret, so the grantor-pier loop above found nothing and eed
    //   was never told — it sat on its parked "giving your soul".  Tell the soul directly: eed's
    //    Swarm_ferry_cancelled then folds its confirm for us.  Humdinger + wire-driven → Book-inert.
    if (top.c.humdinger && ct_ident && cfacts.awaiting && cfacts.awaiting.soul) {
        this.Swarm_deliver(w, ct_ident, String(cfacts.awaiting.soul), { kind: 'ferry_cancel', page: this.Swarm_page(ct_ident) })
    }
    // (No revocation minted here — the SINGULAR-ADOPT law, owner 2026-08-31: cancelling just DROPS the one
    //  held adopt, and with it every ask stops being served ("not the adopt I hold").  No per-pier NotGrant
    //   traffic for ferries; Swarm_revoke stays the law for real unfriending.)
    // 'cancelled' is a FINISHER: the phase verb finishes both ceremony reqs (secret + parked frame dropped
    //  with them), the pump sweeps, and the stash falls empty — the whole delete pile is one line now.
    this.Swarm_ferry_phase(w, 'cancelled', {})
    console.log('🦑 ferry: link cancelled — cleared the pending secret and any parked account')
    return 1
// Swarm_ferry_ask — the Linkee's steady "I want linkage" ask.  While a soul is inbound (ferry_awaiting) this
//  re-asks the soul device, every pulse, to (re)park its grantor-confirm — so the Linkor stays focused on serving
//   the adopt no matter how ITS `.c` was reset (a reload).  The ceremony is held open by the Linkee's standing
//    DEMAND, not by either end durably remembering a one-shot seal (owner 2026-08-29: "a steady flow of 'I want
//     Linkage' sentiment from 495 to eed to keep it focused on serving the request").  Sent to every sealed pier —
//      mid-adopt there is exactly one (to the soul); a stray to some other friend no-ops there (they hold no
//       ferry_secret for me).  Rides Swarm_pulse_all, which the caller never runs in a Book → Book-inert for free.
Swarm_ferry_ask(w, ident, force):
    let top = this.top_House ? this.top_House() : null
    if (!top || !top.c) { return 0 }
    let acave = this.Swarm_ferry_role('cave')
    if (!(acave && !acave.sc.finished && acave.sc.phase === 'awaiting')) { return 0 }
    // SELF-RESOLVE the identity: the LinkDevice tick calls this with only `w` (the cell has no clean handle on the
    //  live self), so fall back to Swarm_live_self — without this the 3s driver was a silent no-op (`!ident`) and
    //   495 never actually asked, so eed was never pulled in.  The pulse caller still passes ident and is unaffected.
    if (!ident) { ident = this.Swarm_live_self ? this.Swarm_live_self() : null }
    if (!ident) { return 0 }
    // ~2.8s THROTTLE in WALL-CLOCK MS.  ⚠ Swarm_now is SECONDS (Math.floor(Date.now()/1000)) on a live tab, so the
    //  old `Swarm_now(w) - ferry_ask_at < 2800` compared a ~3 gap to 2800 and SUPPRESSED every ask for ~47min after
    //   the first — the real "eed is not pulled in" bug (an unreloaded first ask, then silence).  Date.now() ms
    //    makes the 3s tick + 5s pulse fallback dedupe cleanly.  A `force` ask (first contact, or the instant the
    //     peer comes online) BYPASSES the throttle so the link LEAPS the moment both ends are present — the eager,
    //      "wants-to-happen" feel — instead of waiting out the idle cadence.
    let nowt = Date.now()
    // ABSOLUTE FLOOR that even `force` cannot cross (owner 2026-08-29: "it sends like 1000 of these on startup").
    //  The Link cell re-grapples on every version bump, so a mounted LinkDevice's fire_ask(true) mount-pounce
    //   re-fires in a tight remount loop; a forced ask that bypassed the throttle turned that into ~1000
    //    ferry_want/second (each Swarm_deliver bumps → re-commission → remount → pounce again).  An 1100ms floor
    //     BEFORE the force check caps the storm to <1/sec while still letting a genuine pounce jump the longer
    //      idle cadence.  force buys eagerness, never a machine-gun.
    let gap = acave.c.ask_at ? (nowt - acave.c.ask_at) : 1000000000
    if (gap < 1100) { return 0 }
    if (!force && gap < 2800) { return 0 }
    acave.c.ask_at = nowt
    let sent = 0
    for (const pier of this.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []) {
        if (this.Swarm_deliver(w, ident, pier.sc.pub, { kind: 'ferry_want', serial: String(acave.sc.serial || ''), page: this.Swarm_page(ident) })) { sent = sent + 1 }
    }
    if (sent) { console.log('🦑 ferry: "I want linkage" → ' + sent + ' pier(s) — awaiting my soul') }
    return sent
// Swarm_ferry_cancelled — the Linkee's side of the teardown: the soul we were awaiting called the link off, so
//  give up the "connecting…" wait and drop its durable twin (a reload must not rehydrate a dead ceremony).  Only
//   the very soul we're awaiting can call it off (`from` must match ferry_awaiting.soul), so a stray cancel can't
//    knock a Linkee out of an unrelated adopt.  Leaves a brief `ferry_offkey` note for the cell to show + dismiss.
Swarm_ferry_cancelled(w, ident, from):
    let top = this.top_House ? this.top_House() : null
    if (!top || !top.c) { return }
    let dsoul = this.Swarm_ferry_role('soul')
    let dcave = this.Swarm_ferry_role('cave')
    let fp = String(from || '')
    let pubmatch = (a, b) => a && b && (a === b || a.startsWith(b) || b.startsWith(a)) ? 1 : 0
    // SOUL-SIDE FOLD (2026-08-31): the Linkee DECLINED the landed soul — my "waiting for its received" must
    //  end on a screen too.  Matched on the pub I sent to, so a stray cancel can't kill an unrelated wait.
    //   The phase walk to 'ended' re-stashes (receipt → the twin drops) and the phase verb bumps.
    if (dsoul && !dsoul.sc.finished && (dsoul.sc.phase === 'sent' || dsoul.sc.phase === 'held') && fp) {
        if (pubmatch(String(dsoul.sc.pub || ''), fp)) {
            this.Swarm_ferry_phase(w, 'ended', { pub: fp, role: 'soul' })
            console.log('🦑 ferry: the other device declined the soul — the send is void, ceremony closed')
            return
        }
    }
    // SOUL-SIDE PRE-SEND FOLD (owner 2026-08-31: "cancel eed's interest in it").  The Cave backed out while I was
    //  still at "giving your soul" (confirming, nothing sent yet).  Fold that parked interest — matched on the
    //   confirm's pub so a stray cancel can't wipe an unrelated one.  My LINK stands (secret kept): the phase
    //    walks BACK to 'minted', so I drop to the QR rather than a dead-end "ended" — the natural fall-through.
    if (dsoul && !dsoul.sc.finished && dsoul.sc.phase === 'confirming' && fp) {
        if (pubmatch(String(dsoul.sc.pub || ''), fp)) {
            this.Swarm_ferry_phase(w, 'minted', { role: 'soul' })
            console.log('🦑 ferry: the device backed out before I sent — folded the parked "giving your soul"; the link still stands for another device')
            return
        }
    }
    if (!(dcave && !dcave.sc.finished && dcave.sc.phase === 'awaiting')) { return }
    if (fp && String(dcave.sc.pub || '') !== fp) { return }
    // EVERY CEREMONY ENDS ON A SCREEN, NEVER A VANISH (owner 2026-08-30: "check it runs to the end — logically").
    //  'ended' is a receipt phase: link_active/link_fresh count it, the cell shows "the link was called off",
    //   and the human's `done` finishes the req.
    this.Swarm_ferry_phase(w, 'ended', { pub: fp, role: 'cave' })
    console.log('🦑 ferry: the soul device called off the link — gave up awaiting it')
// Swarm_ferry_consume — the UI's "yes, become this Cave" with the #fc code: unseal + import the parked
//  account.  `ident` is this device's live self (its pre-ferry identity → body key).  Returns the soul.
async Swarm_ferry_consume(w, code, accept):
    let top = this.top_House ? this.top_House() : null
    if (!top || !top.c) { return null }
    let ccav = this.Swarm_ferry_role('cave')
    let dsoul = ccav && !ccav.sc.finished ? String(ccav.sc.pub || '') : ''
    let pend = ccav && !ccav.sc.finished ? ccav.c.pending : null
    if (!accept || !pend || !pend.frame) {
        // the human said "no" to becoming this soul's Cave: retire THIS ceremony's grant by the signed law
        //  (Swarm_revoke → %NotGrant on the soul's pier), so the next pulse/reload finds no honoured MyCave
        //   grant and nothing re-hijacks — while a fresh link deliberately opened later seals a newer grant
        //    and works.  Falls back to the pending frame's soulpub if the awaiting marker was already gone.
        let un = dsoul || (pend && pend.frame ? String(pend.frame.soulpub || '') : '')
        if (!accept && un) {
            // TELL THE SOUL (the singular-adopt law): its "waiting for its received" must end on a screen, not
            //  hang — a ferry_cancel folds its ferry_sent (Swarm_ferry_cancelled, soul-side branch).  Humdinger-
            //   gated OR consenter-gated: a Book raising top.c.consenter drives the cancel travel in a test;
            //    a plain Book's local decline stays local.
            let dident = this.Swarm_live_self ? this.Swarm_live_self() : null
            if ((top.c.humdinger || top.c.consenter) && dident) { this.Swarm_deliver(w, dident, un, { kind: 'ferry_cancel', page: this.Swarm_page(dident) }) }
        }
        // 'declined' is a FINISHER: the phase verb finishes the cave req (parked frame dropped with it),
        //  so a later reload never rehydrates a "connecting…" for a ceremony that already resolved.
        this.Swarm_ferry_phase(w, 'declined', {})
        return null
    }
    let ident = this.Swarm_live_self ? this.Swarm_live_self() : null
    let soul = ident ? await this.Swarm_ferry_heard(w, ident, pend.frame, code) : null
    if (ccav) { delete ccav.c.pending }
    if (soul) { this.Swarm_ferry_phase(w, 'received', { pub: (pend.frame && pend.frame.salt ? String(pend.frame.salt).split(':')[0] : ''), role: 'cave' }) }
    // IDENTITY TRANSITION (Division_todo §0 — the husk): the device WAS its own blank auto-vivified self
    //  (the active %Identity); now it holds the soul.  Funnel the landed soul through Clustation_concrete —
    //   the SINGLE chokepoint every mint|adopt funnels through (Auto.svelte) — so it becomes the sole ACTIVE
    //    identity: the blank husk is deactivated and Swarm_live_self resolves to the soul (else find(active)
    //     could still return the husk and the device would present as blank).  Guarded so a Book path with no
    //      Auto layer just skips it (the account still landed); this activation seam's only FULL proof is the
    //       live two-tab test (Auto's own note, Identity_persist §3), so it is verified live, not headless.
    if (soul && soul.c && soul.c.keys && soul.sc.Identity && soul.c.up && typeof this.Clustation_concrete === 'function') {
        try { this.Clustation_concrete(soul.c.up, soul.sc.Identity, { pub: soul.c.keys.pub, key: soul.c.keys.key, prepub: soul.sc.prepub, friendly: soul.sc.friendly }) } catch (er) { console.log('🦑 ferry: concrete threw — soul landed, activation deferred to boot') }
        // THE ARREST FIX (owner 2026-08-30: "disk holds 1 account(s) but none is eed…"): concrete
        //  ACTIVATES but never PERSISTS — it is the resume path's helper and presumes a disk row
        //   already exists.  A FERRIED soul has no row on this browser, so the post-done ?I=<soul>
        //    boot found nothing and ARRESTED — the whole ceremony succeeded and then evaporated on
        //     reload.  Mirror Clustation_adopt's thang_put here (identities Thang, row keyed by
        //      prepub — the Identity tag IS the prepub), so the next boot RESUMES the soul.
        //  HUMDINGER-GATED like the ferry_got ack: a Book's consume must never write its test soul
        //   into the runner browser's real identities store.
        if (top.c.humdinger && typeof this.thang_put === 'function') {
            try {
                let pA = soul.c.up
                let pwT = pA.o({ w: 'Thangs', thangs: 'identities' })[0] || pA.i({ w: 'Thangs', thangs: 'identities' })
                pwT.c.up = pA
                let pstored = { pub: soul.c.keys.pub, key: soul.c.keys.key, prepub: String(soul.sc.prepub || '') }
                if (soul.sc.friendly) { pstored.friendly = soul.sc.friendly }
                await this.thang_put(pwT, String(soul.sc.prepub || soul.sc.Identity), pstored)
                console.log('🦑 ferry: 🪪 soul keypair persisted — a reload will resume it, not arrest')
            } catch (er) { console.log('🦑 ferry: 🪪⚠ soul persist FAILED — it lives this session but a reload will arrest: ' + String(er).slice(0, 120)) }
            // THE ME-POINTER SURVIVES TOO (owner 2026-08-31: "no trace of 'I am actually this body'
            //  except 'two of you'").  ferry_heard set soul.c.bodykey — RAM only — so the become-reload
            //   forgot WHICH roster row is me: Swarm_body_mine → null, the CAVE badge never shows, and
            //    the only body-awareness left was the cohort's _1 suffix.  Persist it to the body-local
            //     Dexie (the store bodykey_read/ensure hydrates at the next standup).
            try {
                let bk = soul.c.bodykey
                if (bk && bk.pub) { await bodykey_write({ root_prepub: String(soul.sc.prepub), pub: String(bk.pub), key: String(bk.key), prepub: String(bk.prepub || ''), at: this.Swarm_now(w) * 1000 }) }
            } catch (er) { console.log('🦑 ferry: 🪪⚠ body key persist FAILED — me-still-me lives this session only: ' + String(er).slice(0, 120)) }
            // THE LEDGER TRAVELS WITH THE KEY (Ferry_todo §3.9 / facet B — account portability): the ferry
            //  blob carried the WHOLE account and Swarm_import grafted it, but the Dexie resume path reads
            //   the stash, which so far learned only the keypair — so the reborn Cave woke friendless and
            //    dropped the family's traffic ("no Pier for 7950f300").  Mirror the disk-seed idiom
            //     (Auto.svelte's Swarm_restash_all(live, vault)): read the ledger OUT of the grafted soul,
            //      stash it UNDER the live self concrete just activated — the same-prepub check inside
            //       restash_all is the guard that keeps a stranger's friends out of our stash.
            try {
                let plive = this.Swarm_live_self ? this.Swarm_live_self() : null
                if (plive && plive.sc.prepub === soul.sc.prepub) {
                    let pgot = this.Swarm_restash_all(plive, soul)
                    console.log(`🦑 ferry: 🪪 ledger restashed — ${pgot.piers} pier(s), ${pgot.izzes} invite(s), ${pgot.roots} chain root(s) travel with the key`)
                }
            } catch (er) { console.log('🦑 ferry: 🪪⚠ ledger restash FAILED (key is safe, friends will not survive reload) — ' + String(er).slice(0, 120)) }
        }
    }
    // RECEIVE-ACK (task #21, the last unlit lamp in "none indicate the Link failed/succeeded"): tell the soul
    //  device its account was actually TAKEN ON, so the Linkor's cell can close the arc with a real "✓ received"
    //   instead of the half-truth "sent".  HUMDINGER-GATED so a Book never emits it (fixtures untouched); rides
    //    the reliable outbox (not ephemeral) so a briefly-away Linkor still learns on return.  Best-effort —
    //     an ack that fails to send costs nothing (the soul already landed).
    if (soul && top.c.humdinger) {
        try {
            let ack_ident = this.Swarm_live_self ? this.Swarm_live_self() : ident
            let ack_piers = this.Swarm_peering(ack_ident)?.o({ Pier: 1 }) ?? []
            // prefer the pier that IS the soul we just took on (dsoul / the frame's salt names it); fall back to
            //  any MyCave-live pier (a fresh Linkee holds exactly one).
            let ack_soul = dsoul || (pend.frame && pend.frame.salt ? String(pend.frame.salt).split(':')[0] : '')
            let ack_pier = (ack_soul ? ack_piers.find((p) => { let pp = String(p.sc.pub || ''); return pp && (pp === ack_soul || pp.startsWith(ack_soul) || ack_soul.startsWith(pp)) ? 1 : 0 }) : null)
                || ack_piers.find((p) => this.Swarm_pier_linklive(p))
            // FACET D — the ack HANDS THE CAVE'S INSTANCE OVER (owner: "Captain Grav and Cave Guw"): the
            //  Captain's own roster can't know this new body's key or chosen name unless we tell it, so the
            //   ferry_got carries `body` (the Cave's own body-key pub, distinct from the shared soul pub) and
            //    `name` (what THIS human wrote at THIS device's name-gate — the pre-ferry ident's friendly).
            //     The Captain notes it as a %Body,role:Cave; friends still see the one soul.
            let ack_bodypub = soul.c && soul.c.bodykey ? String(soul.c.bodykey.pub || '') : ''
            let ack_name = String(ident.sc.friendly || '')
            if (ack_ident && ack_pier) { this.Swarm_deliver(w, ack_ident, ack_pier.sc.pub, { kind: 'ferry_got', body: ack_bodypub, name: ack_name }) }
        } catch (er) {}
    }
    return soul

// Swarm_adopt_sas — the emoji SAS both devices READ before the key copies (the EmojiConfirm gate, Phase 3):
//  fold the two pubs + the nonce (sorted, so both sides agree) into an emoji row.  EQUAL rows on both
//   screens = one channel, no machine in the middle; a relay MITM that swapped a pub yields a DIFFERENT row.
async Swarm_adopt_sas(soulpub, bodypub, nonce):
    return await sas_row(sas_transcript([String(soulpub), String(bodypub), String(nonce)]))
// Swarm_adopt_sas_land — the SAS for the soul-holder's LAND screen (my soul pub + the scanned offer).
async Swarm_adopt_sas_land(w, token):
    let offer = this.Swarm_adopt_decode(token)
    let self = this.Swarm_live_self ? this.Swarm_live_self() : null
    if (!offer || !self || !self.c.keys) { return '' }
    return await this.Swarm_adopt_sas(self.c.keys.pub, offer.pub, offer.nonce)
// Swarm_adopt_sas_consent — the SAS for the issuing device's CONSENT screen (the parked offer + frame).
async Swarm_adopt_sas_consent(w):
    let top = this.top_House ? this.top_House() : null
    let off = top && top.c ? top.c.adopt_offering : null
    let pend = top && top.c ? top.c.adopt_pending : null
    if (!off || !pend || !pend.frame) { return '' }
    return await this.Swarm_adopt_sas(pend.frame.soulpub, off.bodykeys.pub, off.nonce)
// NOTE (2026-08-27): a `%Reach` materialised-verdict cache used to live here (Swarm_reach_grade/addr/
//  refresh/darken/pick/for). It was REVERTED after two adversarial reviews: it re-introduced a presence
//   cache with its own ~40s clock — the exact "cache liveness + keep it fresh" shape the live transfer
//    protocol (repli_want, Ghost/N/Repli.g) already tore out for being "pure liability" that flooded the
//     outbox and killed the deliver pump. REACHABILITY is the transport's ground truth (Swarm_deliver's
//      boolean / the outbox ack-dead ledger), read at use — never a directory cache. RESOLUTION (role →
//       body → address) stays pure, above: Swarm_body_for / Swarm_pier_body. See Division_todo §4.

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
    this.Swarm_rehome(ident)
    return addr

// ── the cohort: the live bodies of one soul in one browser profile ─────────────────────────────
//  The race this kills (Portability §10, the 2026-08-27 burn): a tab boots, consults nothing,
//   binds the bare prepub — and a second tab of the same soul does exactly the same.  There was
//    NO aloneness check anywhere in the boot chain; this is it.  Three layers, each degrading to
//     the next (the spine: ERR TOWARD SUFFIXING — the bare name is the write lock, so corruption
//      flows only through wrongly-holding-bare, never wrongly-holding-_2):
//   · Web Locks — the same-profile DECIDER.  Zero staleness, held across background throttling,
//      auto-released on tab death: leadership IS the lock, no cadence, no stale row, ever.
//   · BroadcastChannel census — enumerate the living: who else is here, which addresses are
//      taken, and the place tokens that feed Swarm_sibling (its first app-path caller — what
//       turns the 👥 theft alarm into family silence).  Silence ≠ absence; advisory only.
//   · The relay + the 👥 tripwire stay the cross-machine layers; this promises nothing there.
//  Raw browser APIs in a ghost — the Socket_real precedent (Tribunal.g: "WebSocket + location
//   … are all transport seams").  Every API is feature-guarded: the daemon's jsdom and any
//    API-less browser get {primary:1, lockless:1} instantly, i.e. today's behaviour untouched.
//  The consumer contract is ONE thing: top_House().c.cohort = { primary, vessel, taken } —
//   Swarm_station_up reads it (soft; absent = no cohort ran = every Book) and suffixes the
//    session address when this body is not primary.  Runtime-only; no fixture can move.

// Swarm_cohort_vessel — the per-INSTANCE place token (Portability §1: "per-instance, quite
//  specifically").  sessionStorage: each TAB is its own place, surviving that tab's reloads,
//   dying with it.  Storage-denied fallback: a per-boot random — still a place, not stable.
Swarm_cohort_vessel():
    try {
        let v = sessionStorage.getItem('jamsend:vessel')
        if (!v) {
            let bytes = crypto.getRandomValues(new Uint8Array(6))
            v = Array.from(bytes, (b) => b.toString(16).padStart(2, '0')).join('')
            sessionStorage.setItem('jamsend:vessel', v)
        }
        return v
    } catch (e) {
        return 'v' + Math.floor(Math.random() * 0xffffffff).toString(16)
    }

// Swarm_cohort_primacy — take (or fail to take) the profile-wide bare-name lock.  Granted ⇒
//  candidate-primary, and the lock is HELD until the tab dies (the never-resolving callback
//   promise is the hold — the Web Locks idiom).  Refused ⇒ a sibling holds bare.  No API ⇒
//    primary with `lockless` marked, so downstream layers know this profile never arbitrated.
Swarm_cohort_primacy(prepub):
    let locks = (typeof navigator !== 'undefined' && navigator.locks) || null
    if (!locks || !locks.request) return Promise.resolve({ primary: 1, lockless: 1 })
    return new Promise((resolve) => {
        try {
            locks.request('jamsend:' + prepub + ':bare', { ifAvailable: true }, (lock) => {
                if (!lock) { resolve({ primary: 0, lockless: 0 }); return }
                resolve({ primary: 1, lockless: 0 })
                return new Promise(() => {})
            }).catch(() => resolve({ primary: 1, lockless: 1 }))
        } catch (e) { resolve({ primary: 1, lockless: 1 }) }
    })

// Swarm_cohort_stand — the boot-time claim + census, idempotent per tab.  Populates
//  top.c.cohort within its 250ms budget and keeps answering the channel for the tab's life,
//   registering every heard sibling so the hear funnel knows family from thief.
async Swarm_cohort_stand(ident):
    let top = this.top_House()
    if (!top || !top.c || top.c.cohort || top.c.cohort_standing) return
    let prepub = ident?.sc?.prepub
    if (!prepub) return
    top.c.cohort_standing = 1
    let vessel = this.Swarm_cohort_vessel()
    let claim = await this.Swarm_cohort_primacy(prepub)
    let taken = claim.primary ? [] : [prepub]
    let heard = {}
    let note_sibling = (m) => {
        if (!m || !m.vessel || m.vessel === vessel || heard[m.vessel]) return
        heard[m.vessel] = m
        if (m.addr && !taken.includes(m.addr)) taken.push(m.addr)
        try { this.Swarm_sibling(ident, m.vessel, m.addr || '', m.selftype || '') } catch (e) {}
    }
    let bc = null
    try { bc = new BroadcastChannel('jamsend:' + prepub) } catch (e) { bc = null }
    if (bc) {
        bc.onmessage = (ev) => {
            let m = ev.data
            if (!m || m.vessel === vessel) return
            note_sibling(m)
            if (m.t === 'hi') {
                let addr = ''
                try { addr = this.Swarm_address(ident) || '' } catch (e) {}
                try { bc.postMessage({ t: 'here', vessel: vessel, addr: addr, primary: top.c.cohort ? top.c.cohort.primary : 0 }) } catch (e) {}
            }
        }
        try { bc.postMessage({ t: 'hi', vessel: vessel }) } catch (e) {}
        await new Promise((r) => setTimeout(r, 250))
    }
    top.c.cohort = { primary: claim.primary, vessel: vessel, taken: taken, lockless: claim.lockless, at: Date.now() }
    delete top.c.cohort_standing
    if (!claim.primary) { console.log('👥 cohort: another body of ' + prepub.slice(0, 8) + ' holds the bare name in this profile — this tab will stand at a suffix') }
    // Retire the token into the durable Vessel census (Division_todo §ATOMS): the BroadcastChannel
    //  `taken` array is this instant's advisory view; the Vessel table is the store's persistent census
    //   a returning tab reads back.  Best-effort — no IDB, no census, exactly the pre-table behaviour.
    let addr0 = prepub
    try { addr0 = this.Swarm_address(ident) || prepub } catch (e) { addr0 = prepub }
    try { await vessel_register({ vessel: vessel, root_prepub: prepub, address: addr0, fsa: '', alive: Date.now() }) } catch (e) {}

// Swarm_vessel_pick — pure: among vessel rows, the PRIMARY (the one holding the bare `prepub` address)
//  first, else address ascending.  The Vesselling twin of Swarm_body_pick (no role — vessels of one
//   soul are the same Body, so they differ only by address), factored so a Book proves the ordering.
Swarm_vessel_pick(rows, prepub):
    let hits = (rows || []).slice()
    if (!hits.length) { return null }
    hits.sort((a, b) => {
        let ap = (String(a.address || '') === String(prepub)) ? 0 : 1
        let bp = (String(b.address || '') === String(prepub)) ? 0 : 1
        if (ap !== bp) { return ap - bp }
        return (String(a.address || '') < String(b.address || '')) ? -1 : 1
    })
    return hits[0]
// Swarm_vessel_subnet — the soul's local SUBNET off the durable census: every vessel serving this
//  soul in this store, address-ordered (Division_todo §ATOMS: "queried by a root prepub it yields
//   that individual's local subnet").  Best-effort — [] off-browser or uncensused.
async Swarm_vessel_subnet(ident):
    if (!ident?.sc?.prepub) { return [] }
    return await vessel_subnet(ident.sc.prepub)
// Swarm_vessel_sweep — reap vessel rows unseen since `before` (dead tabs that never dropped).  Pure
//  hygiene; a stale row merely fails-forward like a stale Charter entry.
async Swarm_vessel_sweep(before):
    await vessel_sweep(before)

// Swarm_rehome — carry an address change to the WIRE (Portability §4 item 1).  The address
//  rides the IDENT's %Peering (Swarm_address reads it there), but the socket dials off the
//   STATION Peering on w:Swarm — two particles, one meaning.  This verb syncs the station copy
//    and asks the live port to re-dial (Socket_real's rehome(): drop without the intentional
//     latch; its connect() reads the address fresh).  Soft everywhere: a Book has no station
//      world and no websocket port, so every step no-ops and no fixture moves; a live tab
//       whose Swarm world isn't up yet simply dials right the first time, because the dial
//        itself now reads `address ?? name`.
Swarm_rehome(ident):
    if (!ident) return 0
    let A = this.top_House().o({ A: 'Clustation' })[0]
    let w = A ? A.o({ w: 'Swarm' })[0] : null
    if (!w) return 0
    let station = w.o({ Peering: 1 }).find(p => p.sc.name === ident.sc.prepub)
    if (!station) return 0
    let addr = this.Swarm_address(ident)
    if (addr && addr !== ident.sc.prepub) { station.sc.address = addr } else { delete station.sc.address }
    station.bump()
    // AN ADDRESS CHANGE IS A REBIRTH (the 2026-08-27 cohort burn, §wake): roll the station era
    //  and drop the standing voucher so the reconnect's on_open re-signs at the new generation —
    //   peers' Swarm_note_era machinery then treats the comeback as the rebirth it is, instead
    //    of trusting stream state from the body's previous life at the old address.
    if (w.c) { w.c.station_era = Date.now(); delete w.c.station_voucher }
    let port = w.o({ transport: 1, type: 'websocket' })[0]?.c?.port
    if (port?.rehome) { port.rehome(); return 1 }
    return 0

// Swarm_reinstate — the backwards move Steal Back never had (Identity_persist §7.4f, the missing
//  primitive): drop the session suffix and stand at the canonical bare name again.  The §7.4f
//   condition rides as a HOLD, not a hope: a reinstating body's live tree is stale by whatever the
//    borrower wrote, so DISK WINS — this verb stamps `account_mirror_stale`, and the account mirror
//     REFUSES to write while it stands.  The caller's contract: re-read the account dir off disk
//      (the Swarm_boot_seed shape) into the live tree, then clear the flag; only then may this body
//       Swarm_persist again.  Enforcing the half we can see beats documenting the whole.
Swarm_reinstate(ident):
    let peering = this.Swarm_peering(ident)
    if (!peering) return null
    delete peering.sc.address
    peering.bump()
    let top = this.top_House ? this.top_House() : null
    if (top && top.c) top.c.account_mirror_stale = Date.now()
    this.Swarm_rehome(ident)
    return this.Swarm_address(ident)
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
