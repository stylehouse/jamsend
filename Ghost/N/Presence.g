// Presence — WHO IS ONLINE, asked once instead of guessed a hundred times.
//  The relay already holds the only authoritative answer: `locals`, its addr→sockets map, kept
//   honest by the 15s ping/pong reaper (a half-open socket is terminated and unbound within ~2
//    rounds).  Until now nothing could READ it, so every layer above inferred presence by SENDING
//     — one `pulse` per friend every ~10s, one `swarm_hi` per friend at standup — and a miss is
//      silent to the sender (relay.ts warnDrop is server-side; ephemeral frames book no emit and
//       take no ack, Peeroleum.g's classification).  100 friends, ~5 online: 95 frames per round
//        purchasing nothing, and the answer still arrives only as the ABSENCE of a reply.
//  `{control:'who', addrs:[…]}` inverts it: one frame up, one frame down, O(1) per addr.
//
//  WHAT THIS IS NOT.  This is TRANSPORT presence — "the relay says a verified socket for that
//   prepub is open right now".  It is NOT `pier.c.heard_at`, which is APPLICATION presence — "that
//    friend's signed, voucher-checked frame reached me" (Swarm.g's hear funnel, the one place a
//     spoofer is kept from warming presence).  They answer different questions and MUST stay
//      separate particles: a socket can be open while the peer never speaks to US, and this layer
//       cannot tell the difference.  So nothing here writes heard_at.  Callers that want "can I
//        pull from them" should read BOTH — see Presence_live's contract below.
//
//  THE THREE-VALUED ANSWER is the load-bearing bit.  Presence_live returns true | false | null,
//   and `null` means DON'T KNOW (never asked, answer gone stale, relay refused).  A two-valued
//    version would answer `false` while unasked and starve the radio at boot — a presence layer
//     whose failure mode is "nobody is online" is worse than none.  Unknown ⇒ the caller keeps its
//      old evidence.
//
//  SCOPE: one relay.  `locals` is per-process and control frames never cross the r2r bridge, so
//   this answers "online on MY relay".  That is exactly right for the Radios case (one relay) and
//    would need the bridge leg before it means anything wider — say so rather than quietly widen.

// Presence_port(w) — the live websocket carrier's port object, or null.  Socket_real parks it on
//  the %transport,type:websocket child; the mock Socket has no `who` (relay-only control frame),
//   so a port without one reads as absent rather than throwing under a Book.
Presence_port(w):
    let t = w.o({ transport: 1, type: 'websocket' })[0]
    let port = t && t.c.port
    return (port && typeof port.who === 'function') ? port : null

// Presence_c(w) — the %Presence particle, find-or-create.  Its %Seen,pub children ARE the answer,
//  so presence is legible in the snap and on the graph like everything else.  Wall clock lives on
//   .c ONLY (asked_at/answered_at): a Date.now() in sc re-digests the particle every single pass
//    and turns any Book that touches presence permanently red.
Presence_c(w):
    return w.oai({ Presence: 1 })

// Presence_arm(w) — idempotent: install the control-frame hook Socket_real calls when a who_ok or
//  who_error lands (Tribunal.g on_message handles it inline — never the belief queue).  Call this
//   once the channel is up; re-arming is free.
Presence_arm(w):
    const H = this
    // stash the presence world on the top House so readers ELSEWHERE (the radio's note, the door
    //  face, a Supervisor probe) can reach the answer without being handed the station world —
    //   see Presence_here.  Set before the early-return so a re-arm re-points it after a restand.
    this.top_House().c.presence_w = w
    if (w.c.presence_armed) return true
    w.c.on_who = (frame) => H.Presence_take(w, frame)
    w.c.presence_armed = 1
    return true

// Presence_ask(w, addrs) — send ONE who for the whole list.  Returns the number asked, or 0 if we
//  could not ask at all (no port / nothing to ask), which the caller should read as "still
//   unknown", not "nobody home".
//  The relay REFUSES a who from a socket that has not proved an identity (its own leak gate), so
//   this is only meaningful after hello_ok.  We do not gate on that here — the refusal comes back
//    as who_error and is recorded, which is a far better diagnostic than a silent no-op.
Presence_ask(w, addrs):
    let port = this.Presence_port(w)
    if (!port) return 0
    let list = (addrs || []).map(a => String(a)).filter(a => a)
    if (!list.length) return 0
    let p = this.Presence_c(w)
    p.c.asked_at = Date.now()
    p.c.asked_n = list.length
    port.who(list, 'p' + ((p.c.corr = (p.c.corr || 0) + 1)))
    return list.length

// Presence_take(w, frame) — absorb the relay's answer.  REPLACES the %Seen set wholesale: presence
//  is a snapshot, not an accumulation, and a stale %Seen that merely failed to be contradicted is
//   the exact lie this layer exists to stop telling.
//  A who_error (we are not hello-bound yet) records the reason and leaves the set UNTOUCHED but
//   stale-dated, so Presence_live degrades to null (unknown) rather than to false.
Presence_take(w, frame):
    let p = this.Presence_c(w)
    if (!frame || frame.control === 'who_error') {
        p.c.error = (frame && frame.reason) || 'who refused'
        p.c.error_at = Date.now()
        return false
    }
    delete p.c.error
    let online = (frame.online || []).map(a => String(a))
    let want = {}
    for (const a of online) want[a] = 1
    for (const seen of p.o({ Seen: 1 })) { if (!want[String(seen.sc.pub)]) p.drop(seen) }
    for (const a of online) p.oai({ Seen: 1, pub: a })
    p.c.answered_at = Date.now()
    p.c.answered_n = online.length
    p.bump()
    return true

// Presence_fresh(w, ms) — is the last answer recent enough to be believed?  Default 30s: the relay
//  answer is a point-in-time snapshot and the asker is expected to re-ask on a ~10s cadence, so 30s
//   is three missed rounds — comfortably "the asking stopped", not "the network hiccuped".
Presence_fresh(w, ms):
    let p = w.o({ Presence: 1 })[0]
    let at = p && p.c.answered_at
    return !!(at && (Date.now() - at) < (ms || 30000))

// Presence_live(w, pub) — TRUE online, FALSE offline, NULL unknown.  The null is not politeness:
//  a caller must be able to tell "the relay says they are not there" from "nobody has asked".
//   Read it explicitly — `if (Presence_live(w,x) === false)` — because a bare falsy test collapses
//    the two and reintroduces the boot-time starvation this shape exists to prevent.
Presence_live(w, pub):
    if (!this.Presence_fresh(w)) return null
    let p = w.o({ Presence: 1 })[0]
    if (!p) return null
    return !!p.o({ Seen: 1, pub: String(pub) })[0]

// Presence_here(pub) — Presence_live WITHOUT needing the station world in hand.  The readers that
//  most want presence (the radio's note, an arrival probe, a door face) run on other worlds and only
//   know a friend's pub, so making them find the Swarm station world first would put transport
//    plumbing into every caller.  Same three values, same rule: null means DON'T KNOW — including
//     "presence was never armed on this machine", which is the case in every Book.
Presence_here(pub):
    let w = this.top_House().c.presence_w
    if (!w) return null
    return this.Presence_live(w, pub)

// Presence_offline(pub) — the ONE test a caller should use to suppress something: has the relay
//  positively told us this peer is not there?  Sugar for `=== false`, and it exists because the bare
//   falsy read (`!Presence_here(x)`) collapses unknown into offline, which is precisely the mistake
//    the three-valued answer is for.  Naming it makes the safe form the short form.
Presence_offline(pub):
    return this.Presence_here(pub) === false

// Presence_online(w) — the online prepubs as a plain list (the roster view, for a face or a census).
Presence_online(w):
    let p = w.o({ Presence: 1 })[0]
    if (!p || !this.Presence_fresh(w)) return []
    return p.o({ Seen: 1 }).map(s => String(s.sc.pub))

// ── the two verbs the Swarm calls, so the Swarm's own diff stays two lines ───────────────────────
//  All the policy lives HERE rather than inline in Swarm.g's heartbeat: the pulse loop is the most
//   load-bearing wall-clock loop in the app and the least pleasant place to grow a new idea.

// Presence_ask_roster(w, ident) — ONE who for the whole friend roster.  The roster is the %Pier set
//  under the identity's %Peering (Swarm.g's canonical walk); we ask about every friend's pub except
//   our own.  Returns how many were asked (0 = we could not ask, i.e. still unknown).
//  Cadence is the CALLER's: called from the ~10s pulse round, this replaces N speculative frames per
//   round with 1 — and unlike them, it comes back with an answer.
Presence_ask_roster(w, ident):
    if (typeof this.Swarm_peering !== 'function') return 0
    let me = String(ident?.sc?.prepub || '')
    let piers = this.Swarm_peering(ident)?.o({ Pier: 1 }) ?? []
    let addrs = piers.map(p => String(p.sc.pub || '')).filter(a => a && a !== me)
    if (!addrs.length) return 0
    return this.Presence_ask(w, addrs)

// Presence_worth_sending(w, pub) — should a speculative frame (pulse, hi, an offer) be spent on this
//  friend right now?  TRUE unless the relay has positively told us they are not there.
//  The asymmetry is the whole design: only a FRESH, POSITIVE "no socket for them" suppresses a send.
//   Unknown — never asked, stale, refused, no relay — sends exactly as before, so wiring this in can
//    only ever REMOVE frames we already knew were pointless, and can never strand a friend because
//     presence was unavailable.  That property is what makes it safe to put in the heartbeat.
Presence_worth_sending(w, pub):
    return this.Presence_live(w, pub) !== false

// Presence_note(w) — one legible line for a log|face: what we asked, what came back, how old.
//  Deliberately a sentence rather than a struct: this is the thing a human reads when the radio
//   says nobody is online and they want to know whether that is TRUE or merely UNASKED.
Presence_note(w):
    let p = w.o({ Presence: 1 })[0]
    if (!p) return 'presence never asked'
    if (p.c.error) return 'presence refused — ' + p.c.error
    if (!p.c.answered_at) return 'presence asked ' + (p.c.asked_n || 0) + ' — no answer yet'
    let age = Math.round((Date.now() - p.c.answered_at) / 1000)
    let stale = this.Presence_fresh(w) ? '' : ' (STALE — treated as unknown)'
    return (p.c.answered_n || 0) + '/' + (p.c.asked_n || 0) + ' online, ' + age + 's ago' + stale
