// InvSeal.g — the FIRST Inv* ferry Book (Network_procedures_todo Phase 11: the Book comes FIRST).
//  ONE focused rung of the ferry exchange, unit-tested at the model layer: a Linkor mints its ferry link
//   (Swarm_ferry_link — the random secret on top.c + the durable twin in the stash + the #fc URL
//    fragment) and a WARM Cave pier sealing drives the seal-seam (Swarm_ferry_on_seal) to PARK a
//     ferry_confirm for the human — the secret held, NOTHING sent until the "give my soul" consent.
//  The chokepoint warmth gate is the tooth: the SAME seal on a COLD pier (no heard_at) parks nothing
//   (the stale-corpse family — grant is not presence).  The last beat is Swarm_ferry_cancel — both a
//    real assertion (every trace clears so a reload never rehydrates a dead ceremony) AND the tidy-up
//     that hands the runner tab back ferry-clean (link/secret state rides top_House, not this world).
//  BOOK-INERTNESS: the park branch is humdinger-gated in Swarm.g, so beat 4 raises top.c.humdinger for
//   exactly its two on_seal calls and drops it again; heard_at + humdinger + the random secret all ride
//    `.c`/stashed (never snapped) and the note rows are BOOLEANS ONLY — the snap stays byte-repeatable
//     even though the secret is crypto-random.  Cancel with no humdinger sends no frame and UnInvites
//      nobody (its own contract) — no fixture noise, no durable "no" left behind.
//  WITNESS: this.story_swear (the SwarmSpread/SwarmFerry pattern) — DURABLE sworn facts recorded as
//   Assertion: lines under the toc step lines (a missing one reds the run un-maskably), read off the
//    beat's own boolean note row.  (The earlier draft's inline `%see` guards evaporated each think and
//     latched no contract; story_swear is the stronger gate for a unit test — Inv_ferry_todo §7.)
//  CONVENTION (Swarm*): the world MUST be named InvSeal (do_fn_for dispatches by w.sc.w — the usual bomb).
//
//  ⚠ DRAFT 2026-08-30 — NOT yet compiled or run; authored WITHOUT editor/runner access.  Before this is
//   real (see Inv_ferry_todo.md §0):
//    1. register 'Ghost/Story/InvSeal.g' in CREDULER_GHOSTS (src/lib/O/LiesLies.svelte ~:56);
//    2. LocalGen compile (GFILES must include this .g or LocalGen silently skips it);
//    3. author the Book's Plan (5 steps) in the editor — a missing Plan yields the hollow 1-step green;
//    4. verify on the LIVE runner only (node scripts/runner_ask.mjs run InvSeal --watch), N>=5 runs.

InvSeal(A,w):
    w oai %req:wrangle,eternal
        await &InvSeal_drive,w,req
        req%ok = 1

InvSeal_T(w):
    let t = w.o({ testing: 1 })[0]
    if (!t) { t = w.i({ testing: 1 }); t.c.up = w }
    return t

InvSeal_note(w, sc):
    let t = this.InvSeal_T(w)
    let n = t.i(sc)
    n.c.up = t
    return n

async InvSeal_drive(w, req):
    let n = (this.c.run)?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) { await this.InvSeal_stand(w) }
        if (n === 3) { await this.InvSeal_mint(w) }
        if (n === 4) { await this.InvSeal_seal(w) }
        if (n === 5) { await this.InvSeal_cancel(w) }
    }
    await this.InvSeal_pump(w)
    this.InvSeal_witness(w)
    await this.InvSeal_order(w)

// the SwarmStaple pump — nothing SHOULD cross in this Book (the park sends no frame), but the wire
//  stays honest: if a send ever leaks, its mail lands and the nothing_sent tooth catches it.
async InvSeal_pump(w):
    for (const acct of w.o({ Account: 1 })) {
        for (const ident of acct.o({ Identity: 1 })) { await this.Swarm_pump(w, ident) }
    }

// beat 2 — the parties stand: Alice the Linkor (a full soul — keys seeded off the name so the crypto
//  repeats byte for byte) and Cavey the Cave-to-be (a blank device with only a body key — the
//   SwarmSpread Ebox recipe).  Pinned clock; both online.
async InvSeal_stand(w):
    w i reached:step_2
    w.sc.now = 1756400000
    let aacct = w.oai({ Account: 1, of: 'Alice' })
    aacct.c.up = w
    let akeys = await this.Swarm_mint_keys('InvSeal-Alice')
    let alice = this.Swarm_identity(aacct, akeys, 'Alice')
    w.c.alice = alice
    this.Swarm_online(alice, true)
    let cacct = w.oai({ Account: 1, of: 'Cavey' })
    cacct.c.up = w
    let ckeys = await this.Swarm_mint_keys('InvSeal-Cavey-body')
    w.c.ckeys = ckeys
    let cavey = this.Swarm_identity(cacct, ckeys, 'Cavey')
    w.c.cavey = cavey
    this.Swarm_online(cavey, true)
    this.InvSeal_note(w, { stood: 1 })

// beat 3 — the Linkor mints: Swarm_ferry_link returns <base>?Iz=<token>#fc=<secret>.  The secret is
//  crypto-RANDOM, so it must never touch sc — the note row carries only booleans (the SwarmSpread
//   ciphertext-on-.c lesson).  Asserted: the URL carries both the token and the fragment; the live
//    secret rides the fragment (client-side, never the relay); the durable twin sits in the stash.
async InvSeal_mint(w):
    w i reached:step_3
    w.sc.now = 1756400010
    let alice = w.c.alice
    if (!alice) { return }
    let top = this.top_House ? this.top_House() : null
    w.c.url = await this.Swarm_ferry_link(w, alice, 'https://jamsend.example/BigSoundland')
    let url = String(w.c.url || '')
    let secret = top && top.c ? top.c.ferry_secret : null
    let twin = top && top.stashed && top.stashed.ferry_pending_secret ? top.stashed.ferry_pending_secret.secret : null
    let row = { minted: 1 }
    if (url.startsWith('https://jamsend.example/BigSoundland?Iz=') && url.includes('#fc=')) { row.url_carries_both = 1 }
    if (secret && String(secret).length === 32 && url.endsWith('#fc=' + String(secret))) { row.secret_rides_fragment = 1 }
    if (twin && String(twin) === String(secret)) { row.twin_stashed = 1 }
    this.InvSeal_note(w, row)

// beat 4 — THE BEAT: a MyCave pier seals and the seam parks the grantor consent.  A minimal sealed
//  pier Alice→Cavey is stood by hand (the SwarmSpread beat-5 recipe + the %Grant:MyCave that
//   Swarm_pier_live gates on).  The park branch is humdinger-gated (a bare runner sends straight
//    through) so humdinger is raised for exactly the two on_seal calls, then dropped.
//  Tooth first: the pier COLD (no heard_at) — the chokepoint warmth gate refuses to park (grant is
//   not presence — the stale-corpse cure).  Then warm (heard_at = wall-clock now, `.c` only, never
//    snapped) — the seam parks ferry_confirm keyed to the pier, holds the secret, and sends NOTHING.
async InvSeal_seal(w):
    w i reached:step_4
    w.sc.now = 1756400020
    let alice = w.c.alice
    let ckeys = w.c.ckeys
    if (!alice || !ckeys) { return }
    let top = this.top_House ? this.top_House() : null
    let peering = this.Swarm_peering(alice)
    let pier = peering.oai({ Pier: 1, pub: ckeys.prepub })
    pier.c.up = peering
    let cpage = pier.oai({ Peering: 1, name: ckeys.prepub })
    cpage.c.up = pier
    cpage.sc.pub = ckeys.pub
    pier.oai({ Grant: 'MyCave', by: ckeys.pub })
    if (top && top.c) { top.c.humdinger = 1 }
    await this.Swarm_ferry_on_seal(w, alice, pier)
    let cold_refused = top && top.c && !top.c.ferry_confirm ? 1 : 0
    pier.c.heard_at = Date.now()
    await this.Swarm_ferry_on_seal(w, alice, pier)
    let confirm = top && top.c ? top.c.ferry_confirm : null
    if (top && top.c) { delete top.c.humdinger }
    let cavey = w.c.cavey
    let crossed = cavey ? cavey.o({ mail: 1 })[0]?.o({ frame: 'ferry' })[0] : null
    let row = { sealed: 1 }
    if (cold_refused === 1) { row.cold_refused = 1 }
    if (confirm && String(confirm.pub) === String(ckeys.prepub)) { row.confirm_parked = 1 }
    if (top && top.c && top.c.ferry_secret) { row.secret_held = 1 }
    if (!crossed) { row.nothing_sent = 1 }
    this.InvSeal_note(w, row)

// beat 5 — the honest way out AND the tidy-up: Swarm_ferry_cancel clears the live secret, the parked
//  confirm, and the durable twin (a reload must never rehydrate a resolved ceremony).  No humdinger
//   is up, so cancel sends no frame and UnInvites nobody — the runner tab is handed back clean.
async InvSeal_cancel(w):
    w i reached:step_5
    w.sc.now = 1756400030
    let top = this.top_House ? this.top_House() : null
    let did = this.Swarm_ferry_cancel(w)
    let row = { cancelled: 1 }
    if (did === 1) { row.cancel_ran = 1 }
    if (top && top.c && !top.c.ferry_secret && !top.c.ferry_confirm && !top.c.ferry_pending) { row.live_cleared = 1 }
    if (top && (!top.stashed || !top.stashed.ferry_pending_secret)) { row.twin_cleared = 1 }
    this.InvSeal_note(w, row)

// ── the witness — DURABLE sworn facts via this.story_swear (idempotent per run; evidence lands on the
//  Assertioning shelf never snap bytes; contract under the toc step lines).  Each claim reads the
//   beat's own boolean note row plus the LIVE top state.  No commas — em-dashes (the peel splits on
//    commas).  Gated on the exact recorded booleans (the SwarmSpread/SwarmFerry pattern). ──
InvSeal_witness(w):
    let T = this.InvSeal_T(w)
    let top = this.top_House ? this.top_House() : null
    // beat 3: the mint — secret off the relay in the fragment; durable twin stashed for reload.
    let m = T.o({ minted: 1 })[0]
    if (m && +m.sc.url_carries_both === 1 && +m.sc.secret_rides_fragment === 1 && +m.sc.twin_stashed === 1) { this.story_swear(w, 'the Linkor mints the ferry link — the secret rides the URL fragment never the relay — and its durable twin lands in the stash for a reload to rehydrate') }
    // beat 4: the tooth then THE beat — cold refused; warm sealed parks the consent and sends nothing.
    let s = T.o({ sealed: 1 })[0]
    if (s && +s.sc.cold_refused === 1) { this.story_swear(w, 'a cold Cave pier sealing parks nothing — the chokepoint warmth gate refuses a peer not heard within forty five seconds — grant is not presence') }
    if (s && +s.sc.confirm_parked === 1 && +s.sc.secret_held === 1 && +s.sc.nothing_sent === 1) { this.story_swear(w, 'a warm Cave pier sealing parks a ferry_confirm keyed to that pier — the secret is held and nothing crosses until the human gives their soul') }
    // beat 5: cancel clears every trace — live seam and durable twin both.
    let c = T.o({ cancelled: 1 })[0]
    if (c && +c.sc.cancel_ran === 1 && +c.sc.live_cleared === 1 && +c.sc.twin_cleared === 1) { this.story_swear(w, 'cancel clears every trace — the live secret the parked confirm and the durable twin all go — a reload never rehydrates a dead ceremony') }

// InvSeal_order — float A:InvSeal to the front of H/* so the Run snap stays readable.
async InvSeal_order(w):
    let As = H.o({A: 1})
    if (!As.length) { return }
    let first = (a) => (a.sc.A === 'InvSeal') ? 0 : 1
    let sorted = [...As].sort((a, b) => first(a) - first(b))
    let ordered = [...sorted, ...H.o().filter(c => !c.sc.A)]
    await this.place({}, ordered)
