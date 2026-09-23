# LinkDevice_leak_todo.md — one key, many hands: can LinkDevice launder a Grant to strangers?

Triggered by the owner, live, 2026-09-23: *"think up some way we can stop LinkDevice being used to leak
 access in for lots of other users to the same Invite|Grant by supposing they are all the same person...
  maybe the social graph needs more showing."* This doc is ANALYSIS AND ADVICE ONLY — nothing here is coded,
   nothing here is ruled. It exists so the next session (or the owner) has the threat model written down
    instead of re-deriving it.

## 0. WHAT TO GET ON WITH NEXT

Nothing is built. The owner asked for thinking, not code. The order to bring these to a ruling, cheapest
 first:
1. **Surface `Swarm_body_roster` growth to the grant-holder** (§3.1) — pure UI, no protocol change, no risk
    of breaking legitimate multi-device users. Ships fastest, and is a prerequisite for any of the harder
     options anyway (you can't gradually evict what you never show anyone).
2. **Decide whether a concurrent-stream cap is wanted at all** (§3.2) — this is a real product-policy call
    (does jamsend want to BE a "N simultaneous streams" service, Netflix-style?) and needs the owner's answer
     before anything gets coded, because it changes normal multi-device behaviour, not just abuse.
3. **Only if (2) is yes**, design the eviction rule itself (LRU vs random vs "ask the human") — §3.2 sketches
    three, none chosen.
4. §3.3 (linear-only re-share for LinkDevice specifically) is the deepest cut and should wait until the
    owner has seen §3.1 in practice — it may turn out the visibility alone is enough of a deterrent.

## 1. What the code actually does today (read, not guessed — Swarm.g, SwarmTesting.g)

**LinkDevice ("Division", the ferry ceremony) does not create a second, distinguishable identity — it
 CLONES the private key.** `SwarmFerry_cross` (`Ghost/Story/SwarmTesting.g` ~2350, exercising the real
  `Swarm_export`/`Swarm_import` in `Swarm.g`) exports the account WITH its secret
   (`Swarm_export(alice, {secret:1})`), seals it under a code-derived key (Sealbox, AES-GCM/HKDF — see
    `SwarmSeal`), and the far end's `Swarm_import` lands a vessel whose keypair is **byte-identical** to the
     source (`landed keys.key === keyhex`, asserted in the Book itself: "the keys ride .c only even across
      transit"). After a successful ferry, the two devices hold the SAME ed25519 keypair — the SAME `pub`.
       Every Grant, every Crew membership, every Idzeug that pub can present, wields identically and
        indistinguishably from either device. There is no cryptographic marker anywhere that says "this is a
         copy" — a copy of a private key is not a distinguishable object once made.

**The redeem front door IS single-use, but that does not bound re-export.** `%Idzeug` (Swarm.g §6.2, "the
 single-use invite") is single-use by serial for a plain invite (`spent`), and a "chain" invite (`chain:1`)
  is stricter still — it never fans out; only the current TIP can extend it forward one hop at a time via
   `Swarm_mint_reinvite`/`Swarm_verify_reinvite`, each hop naming the next single-use `rnonce`. This is a
    LINEAR handoff by construction (§6.3a) — good, deliberate design, and it already defeats the naive
     "broadcast one invite URL to twenty people, all twenty redeem it" attack for ordinary Invites.
      **But LinkDevice's actual payload — `Swarm_export`/`Swarm_ferry_cross` — is not gated by any of that.**
       It is a capability any account holder can invoke as many times as they like, to as many vessels as
        they like, because that is *correct* for its stated purpose (I own three devices; I want to link all
         three). The system has no way to tell "three of my own devices" apart from "I handed my key to three
          different friends" — both are, byte for byte, the same account holder running the same ferry three
           times. **This is not a bug in the ferry; it's the definition of what account cloning is.** The
            leak the owner is describing is a MISUSE of a working feature, not a broken one — which is why it
             needs a policy/observability answer, not a crypto patch.

**One thing that already exists and nobody surfaces yet: the body roster.** `Swarm_body_note`
 (`Ghost/S/Swarm.g` ~7175, "record ANOTHER of the soul's bodies — from roster replication or the LinkDevice
  roster hand-off") already accumulates every body a soul has ever linked, each with its own `pub`,
   `address`, `name`, and a `heard` liveness timestamp (`Swarm_body_pick`'s away/here/fading tiers, reused
    from the Door's own vocabulary — §Swarm.g ~7230). `Swarm_body_roster(ident)` reads the whole list. **This
     is exactly the raw material a leak-detection UI needs, and today nothing shows it to anyone except the
      owning soul's own tabs.**

### 1.5 Crew grant-sharing, in plain plumbing terms — and the one thing it does NOT do (corrected 2026-09-23,
##  owner live: "just having anyone on the Crew who got a Grant being able to share the Grant with the rest
##   of the Crew... I'd like to get how that works expressed somewhere nicer than this document")

This is a DIFFERENT mechanism from the key-cloning ferry above, and worth keeping strictly separate in your
 head — the two got tangled in conversation, so here is the plumbing, plainly:

- **Every body has its OWN keypair and its OWN separate Peering shelf** (`Swarm_peering(ident)`, keyed on
   the identity actually running — never a crew-shared ledger). A Cave is not a clone of the Captain's key;
    it is a distinct signing identity that happens to be *vouched for* by the Captain.
- **The vouching is a signed `Grant:Crew`**, minted BY the Captain's soul key, `for:` the Cave's own distinct
   pub, the moment a device links (`Ghost/S/Swarm.g` ~3028). This is what lets a THIRD friend trust a Cave
    "as me" without that Cave ever touching the soul key — the friend checks the Grant's signature, not who's
     holding what key.
- **Alongside it, the Captain ALSO mints a `Grant:Music`, again `for:` that same Cave's own distinct pub**
   (~3045, "CREW SHARES MUSIC"), and the Cave mints the mirror-image grant back (~3219, "the mate's
    reciprocal"). Read what this actually grants access to: **the SOUL'S OWN library**, mirrored to its own
     Cave over the same Repli lane a friendship would use. It is the Captain sharing itself with its own
      body — not a friend's grant being redistributed to anyone.

**The specific worry — a Cave that independently holds some OUTSIDE friend's Grant automatically leaking
 that access to the rest of the crew — is not what's built.** Peering is per-body; nothing here walks "does
  any of my crewmates hold a grant I don't have yet" and copies it over. If a Cave were to redeem some
   outside friend's invite on its own (nothing stops a Cave from doing that — it is a first-class signing
    identity, addressable on the relay exactly like the Captain), that grant would sit ONLY on that Cave's
     own Peering shelf. It doesn't reach the Captain or any sibling automatically.

**So today's actual shape is narrower and safer than the worry — but the worry is still the right one to
 have**, because the ONLY existing precedent for "share a grant across bodies" (§ above) is a blanket,
  permanent, install-time copy with no per-use gate and no expiry (the Pier convention elsewhere is
   "infinite — never an expiry", retiring only at explicit revoke). If anyone ever extends that same
    copy-once-forever pattern to an EXTERNALLY-held grant — "convenient, just mirror whatever Grant:Music
     the Captain gets onto every Cave too" — that is the exact moment the leak the owner described would
      start actually existing in code. §5 below is what to reach for instead, if that need ever comes up.

## 2. The actual threat, stated precisely

A grants B (a friend, via Music Idzeug) the right to pull B's shared library / hear B's radio. B then runs
 LinkDevice N times, handing the resulting sealed-ferry code (or the raw exported blob, or just the app's
  own "log in as me" backup flow — whichever channel exists) to N different real people, each of whom now
   holds B's exact keypair on their own device. All N people can now, indistinguishably from A's point of
    view, exercise EVERY grant B ever held or will hold — including A's. A has no way to know this happened:
     A granted "B", and cryptographically, all N devices ARE B. This is a **grant-laundering / access-sharing**
      attack, structurally identical to sharing a streaming-service password, except the account here is not
       a password but an unforgeable signing key — which makes it WORSE in one sense (nothing to rotate that
        doesn't also break B's own legitimate devices) and better in another (every one of B's bodies is
         individually addressable on the wire, which a shared password is not — see §1's roster).

Two sub-cases worth keeping separate, because they call for different answers:
- **B is complicit** (deliberately handing out access — e.g. "family plan" abuse, or selling access). No
   technical control fully stops a willing key-holder from photographing their screen and reading a QR code
    to someone else; this is the same limit every DRM scheme runs into. The honest goal here is FRICTION and
     VISIBILITY, not a hard wall.
- **B is a victim** (the ferry code/blob leaked — phished, a shared computer, a compromised backup). Here
   detection genuinely helps B too, not just A: an unexpected new body on B's own roster is signal B would
    want to see and act on (revoke a Cave, per the existing NotGrant:MyCave/MyCaptain tombstone machinery
     already in Swarm.g ~1655).

## 3. Options, cheapest and least-disruptive first

### 3.1 Surface the body roster to the counterparty (the owner's own instinct: "the social graph needs more showing")

Today `Swarm_body_roster` is a private, per-soul structure — A never sees how many bodies B has, or how
 recently each was active. The cheapest, lowest-risk move: let A's Door (or a friend-detail panel) show
  something like *"Grav is active from 3 places, 2 seen in the last hour"* — not identifying the bodies by
   raw pub, just a COUNT and a recency band (reusing the existing here/fading/away tiers, §1). This:
- costs nothing cryptographically and breaks nothing (pure read, existing data),
- turns an invisible, unbounded fan-out into an observable one — a friend legitimately using a phone +
   laptop looks like "2 places, both recent"; someone who handed their key to fifteen people looks
    conspicuously different, and A can just... ask B about it, or quietly stop granting,
- gives B the same visibility over their OWN roster (which may already exist locally — check before
   building a second surface) as an early-warning for the "B is a victim" case in §2.

This is advice, not a design: exact copy/threshold/placement (Door row? a tap-to-expand detail?) is a UI
 call for whoever picks this up, but the underlying read (`Swarm_body_roster` + `Swarm_body_pick`'s away
  math) already exists and needs no new plumbing.

### 3.2 A gradual, soft concurrent-session cap (the owner's "gradual eviction... without causing trouble")

If visibility alone isn't enough, the next lever is bounding how many bodies may hold an ACTIVE (currently
 connected / actively streaming) connection under one pub at once — not how many bodies may EXIST (that
  would break legitimate multi-device ownership outright), but how many may be LIVE simultaneously. This is
   the same shape as a streaming service's "your account is being used on another device" limit, and it is
    a genuinely different question from §3.1: it requires a RULING, not just a UI addition, because it
     changes behaviour for ordinary users too (someone who legitimately leaves their phone AND laptop both
      open would occasionally see one get bumped).

Three shapes, roughly in order of how much "trouble" they cause a legitimate multi-device owner:
- **LRU eviction on overflow** — the Nth+1 concurrent connection silently drops the least-recently-active
   existing one. Cheapest to build (reuses `Swarm_body_pick`'s heard/away bookkeeping as the recency clock),
    but "silent" is exactly the kind of surprise that erodes trust — a legitimate second device just stops
     working with no explanation, at a moment the owner explicitly warned against ("without causing
      trouble!").
- **Soft-notify, don't evict** — when the count is exceeded, tell every connected body "N places are active
   right now" (a natural extension of §3.1's UI) rather than kicking anyone. No functional change, pure
    friction/visibility escalation; never breaks a legitimate session, and for the complicit-sharing case it
     removes the "nobody will ever notice" assumption the abuse depends on.
- **Ask before evicting** — surface the overflow to the SOUL's own most-recently-active body ("a new place
   just joined — is that you?") and let a human decide whether to let it stand or knock the new one back.
    Most trouble-free of the three (a human is always the one making the call, never a silent surprise) but
     needs a UI moment and won't fire while nobody is actively looking at the app.

No recommendation is made here on WHICH shape, or on the cap number itself — this is squarely the "does
 jamsend want a session-limit product policy" question from §0 step 2, and belongs to the owner.

### 3.3 Make LinkDevice itself linear-only, like a chain invite (the deep cut)

The Idzeug chain mechanism (§1, §6.3a) already solves exactly this shape of problem for ordinary Invites:
 a chain invite tracks a single moving TIP and only the tip may extend it forward, one hop, to one
  newcomer — no fan-out is possible even in principle, because there is only ever one "current holder" the
   next hop must come from. **LinkDevice's ferry has no equivalent notion of a tip.** Every held account can
    re-ferry from scratch, unbounded, forever — which is correct for onboarding new personal devices but
     provides zero structural resistance to abuse.

A speculative direction (not designed, not scoped): wrap the ferry itself in a chain-shaped envelope — each
 LinkDevice code is minted FROM the currently-live body set (not from the bare account), single-use, and
  redeeming it doesn't just clone the key, it also mints a `%Body` row + bumps a monotonic "link serial" the
   roster can show ("this is body #4, linked 2026-09-23"). This wouldn't stop a determined B from re-running
    the ceremony fifteen times — nothing can, short of the human friction options above — but it WOULD make
     every clone individually numbered, timestamped, and (per §3.1) visible, turning an invisible mass-clone
      into an auditable trail. This is the biggest lift of the three options and should only be scoped once
       §3.1 has actually shipped and the owner has seen whether visibility alone changes anything.

## 5. THE OWNER'S PROPOSAL (2026-09-23, live) — GrantDeputisation: a live, single-target, Captain-attested loan

The owner's sketch, restated precisely: address-bind grants (already true, see below); by default only the
 Captain (or whichever Crew member actually redeemed it) holds an outside friend's Grant; when a DIFFERENT
  Crew member's Cave needs to reach that same friend Pier, the Captain — briefly online — signs a scoped
   delegation naming that ONE Cave, for that ONE Pier; and since the two devices "want to regularly open the
    two of them anyway," the Captain's own client can do this the instant it comes online and sees the need,
     so it never feels like a manual step.

**"Require the pubkey as address" is already true, not a gap.** `Swarm_body_addr` derives a body's relay
 address FROM its own key (`prepubOf(pub)`) — "never assigned, never fought over" — and every grant check
  (`Swarm_pier_live`, the `for:` match at `Swarm_confirmed` ~3219) already verifies the PRESENTING pub
   against the grant's named `for:` pub at time of use, not crew membership in general. The system already
    refuses to let membership alone stand in for a specific address. Good instinct, already the law.

**Why this is a real improvement over §1.5's existing pattern, not just a more complicated version of it:**
1. **Live-minted, not standing.** The existing self-catalog Grant:Music (§1.5) is permanent from the moment
    it's minted — revocation needs an explicit NotGrant. A delegation that only exists because the Captain
     JUST signed it, and expires quickly (see below), makes "stop sharing" the DEFAULT — it lapses unless
      renewed, rather than persisting unless torn down.
2. **Single-target, not blanket.** One delegation names exactly one Cave for exactly one Pier. Compromise one
    Cave and you've exposed one relationship, not the crew's whole friend list.
3. **The automation doesn't weaken the guarantee — it only removes the human's click.** The Captain's key
    still has to actually sign every single delegation; automating WHEN it fires (on coming online, seeing a
     standing want) is pure UX, not a security shortcut. This is the right way to remove friction — never by
      loosening what has to be true, only by making it fire promptly when it's already true.

**Build it on the primitive that already exists — don't invent a new signature shape.** `Swarm_mint_reinvite`/
 `Swarm_verify_reinvite` (§1, §6.3a) is already exactly this data shape: a signed capability that EMBEDS a
  held grant/invite, names a specific next holder, and lets a stranger verify the whole chain against the
   ORIGINAL signer's pub without the two ends having met. A "GrantDeputisation" is a ReInvite over a held
    GRANT instead of over an Idzeug: `{ tip: <the friend Pier's pub>, deputy: <the Cave's pub>, iz: <the
     held Grant:Music, embedded>, at, sign }`, signed by the Captain. The deputy Cave presents this (instead
      of a bare Grant) when it dials the friend Pier; the friend's door verifies the embedded grant is real
       AND the deputisation's signature traces to the SAME signer — one verify call, the exact shape
        `Swarm_verify_reinvite` already performs.

**For the "automatic and smooth" half — reuse the existing WISH pattern, don't build a new request channel.**
 `top_House().c.aim_wish` (Radio_dial) is already "I want X, resolve when whoever's driving next gets a
  chance" — a Cave that wants to reach a friend Pier it only knows about through the Captain can leave the
   identical shape of wish (`c.deputise_wish = { for: <friend pier pub> }`), and the Captain's own driving
    beat, the moment it's next live, checks for outstanding wishes across its Crew and mints the deputisation
     unprompted. No new plumbing class, no new UI moment on the happy path — only a fresh wish-consumer,
      mirroring one the codebase already trusts.

**Two things to build IN from the start, not bolt on later, given the whole point was to be MORE secure:**
- **Expire it.** Every existing Pier grant in this codebase is documented as infinite-until-revoked
   ("retires at use, never deleted"). A GrantDeputisation should be the first exception — a short TTL
    (minutes-to-hours, not the friendship's whole lifetime), re-minted on the next Captain-online tick rather
     than renewed indefinitely. This is what actually delivers "more secure": a stale, unrevoked delegation
      simply stops working on its own.
- **Log it where §3.1 already put a light.** "Automatic the moment the Captain comes online" is exactly the
   kind of silent, no-human-looks-at-it moment §2 warned distinguishes a victim from a willing sharer. Route
    every mint through the same visible trail §3.1 proposed for the body roster — a Captain shouldn't need to
     go looking to notice it's been auto-deputising the same Cave every six minutes for a friend it never
      manually approved reaching.

Net assessment: yes — this is a materially better shape than a blanket copy-forever grant, and it costs
 almost nothing extra to build because the two primitives it needs (ReInvite-shaped signing, wish-shaped
  async request) already exist and are already trusted elsewhere in this codebase. Not yet scoped into
   beats/a Book — this is still the "how's that" answer, not a build ticket.

## 4. What this doc deliberately does NOT claim

- It does not claim LinkDevice has a "bug" — the cloning behaviour is the feature working as designed for
   legitimate multi-device use; the risk is a MISUSE surface, not a defect.
- It does not recommend a specific cap, threshold, or UI copy — those are product decisions for the owner.
- It does not touch Crew_todo §12's separate (and harder) two-Captains-mutex problem — that's about the
   SAME device-cloning mechanism producing a split-brain SOUL, a different failure mode than a friend's
    grant being laundered to strangers. Worth reading together, not merged into one doc.
