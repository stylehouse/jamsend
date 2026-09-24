# LinkDevice_leak_todo.md — one key, many hands: can LinkDevice launder a Grant to strangers?

Triggered by the owner, live, 2026-09-23: *"think up some way we can stop LinkDevice being used to leak
 access in for lots of other users to the same Invite|Grant by supposing they are all the same person...
  maybe the social graph needs more showing."* This doc is ANALYSIS AND ADVICE ONLY — nothing here is coded,
   nothing here is ruled. It exists so the next session (or the owner) has the threat model written down
    instead of re-deriving it.

## 0. WHERE THIS LANDED (consolidated 2026-09-24 — read this, the rest is the trail)

**What the owner actually wants, stated once:** Friend's side serves **one body of a given crew at a time**
 on a relationship — the Captain, or whichever Cave/borrower is using it now. A newer body taking the seat
  evicts the older one. A seat idle for a while (an hour? a day? — a knob, unruled) lapses, so the next
   body just takes it. The goal is **limiting the casual over-sharer**, not defeating a malicious insider
    ("that's supposing the app is running on the devil's computer").

**The facts that shape it (all traced in code, §1.6 and below):**
- Every crewmate holds the soul secret — sworn in `SwarmHelm`: *"every crewmate carries the whole ledger
   and the soul secret — held not wielded."* So inside the crew, "only the Captain's key can sign" is NOT a
    boundary: any Cave's device can sign as the soul, take the soul's relay address, mint loans, anything.
- Every certified Cave already reaches every friend's Pier via cert-crew's voucher road (§1.6), with no
   limit on how many at once. Friend's door can tell the bodies apart (each Cave vouches with its own
    `vh.pub`; the Captain vouches as the soul) — it just never uses that.

**So the coherent build is the SLOT, on Friend's side, per Pier — not the loan.** One small piece of state
 on Friend's `%Pier` (`c.slot = {body, at}`) set in the hear funnel right after `Swarm_voucher_ok` passes
  (~Swarm.g:1558, where `sealed` + the vouching body are both known): same body ⇒ refresh `at`; different
   body ⇒ it takes the seat, the old holder is refused (`rebuff 'seat_taken'`) until it's newest again;
    `at` older than the idle knob ⇒ seat free. Covers Captain, Caves and any borrower through one rule.
     Caveat to handle: `sealed.c.voucher_ok` caches ONE signature per Pier, so alternating bodies thrash
      it into full re-verifies — cache per body instead.

**GrantBorrow (landed 2026-09-23, `Swarm_mint_borrow`/`Swarm_verify_borrow` + Book `SwarmBorrow`, green)
 is now mostly redundant.** Crew members don't need it (cert-crew already admits them) and can forge it
  anyway (they hold the soul secret). It only means something for lending to someone OUTSIDE the crew — and
   Friend's door isn't wired to accept a loan as a credential at all yet. Recommendation: park it (or delete
    it) rather than wire it; the slot is what does the job. Its Book's "only the bearer may lend" oath is
     true against outsiders only — do not read it as a crew-internal guarantee.

**Abuse that remains once the slot exists — the honest list:**
| who | can do | matters? |
|---|---|---|
| casual over-crewing (5 friends added as Caves) | only one streams from a given friend at a time; they keep kicking each other | **this is the goal** — self-limiting, annoying, not a fan-out |
| any crewmate | kick the Captain (or each other) off the seat | availability only, internal; accepted — crew is high trust |
| any crewmate with a modified client | sign as the soul, take the soul's relay address, eject others, act as Captain outright | out of scope — "devil's computer"; same as handing over a house key |
| any crewmate | pool what they pulled (SoundPooling) and circulate it to their own friends | **the real remaining leak**, by design — the slot limits live access, not redistribution of bytes already held |
| crew taking turns | time-share the one seat | fine — equivalent to one person listening |

**Left to decide / build:** (1) the idle knob value; (2) build the slot (small, one seam + a Book with two
 Caves contesting); (3) park or delete GrantBorrow; (4) whether pooling of a friend's music by a Cave is
  acceptable — a SoundPooling policy question, not this doc's. Everything below (§1–§5) is the reasoning
   trail, including two conclusions later corrected (§1.5's "narrower than the worry", and §5's framing of
    the loan as a crew-internal boundary).

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

**CORRECTION 2026-09-24 — the paragraph above was wrong about the thing that actually matters.** It's
 correct that no grant *particle* gets copied onto a Cave's own Peering shelf. But the owner asked the
  right follow-up ("before it would've done so fine because there was a Crew member with the Grant it
   could impersonate... I dunno if we actually had that built") and the honest answer, traced below, is:
    **the DATA never copies, but the ACCESS already does, completely, automatically, for every feature —
     not just Music, not just the self-catalog mint this section describes.** §1.6 is that finding; it
      supersedes "today's actual shape is narrower and safer than the worry" above. Read §1.6 before
       trusting anything else in this section about what a Cave can or can't reach.

### 1.6 THE MECHANISM THAT ACTUALLY MATTERS: cert-crew's voucher road already gives a Cave full, permanent,
##  blanket access to every grant the soul has ever held — no copy, no separate mint, no GrantBorrowing needed

Traced live in `Swarm_voucher_ok` (`Ghost/S/Swarm.g` ~1870) and its caller (~1538-1554), prompted by the
 owner asking directly whether this was ever actually built and tested that far. It was built (2026-09-02,
  "the owner's model", with its own adversarial test file `crew-cert-test.ts`) — just never traced end to
   end against the SPECIFIC question this doc is about.

**How a Cave's frame gets trusted on a Pier it never personally sealed.** A Cave holds no soul key, so its
 outgoing frames route under its OWN distinct key (`Swarm_signas`, ~1461: "the BODY prepub for a keyless
  Cave"), not the Captain's. When that frame reaches Friend's tab, the ordinary lookup (`from` → an
   existing sealed Pier) misses — Friend never sealed anything with THIS key. The fallback (~1543-1548,
    "THE CREW ROAD, land-of-prepub") resolves the SOUL's pier instead — via a body Friend has already
     noted, or via the SOUL pub named inside the frame's own attached voucher — landing on the exact SAME
      shared `%Pier` particle Friend has always used for "the Captain". `Swarm_voucher_ok`'s cert-crew arm
       (~1905-1926) then accepts the frame as genuinely vouched for that Pier once it checks four things:
        the claimed body's key really produced the signature, the embedded `Grant:Crew` really names
         `by:<the Pier's own held soul>`, it really names `for:<this presenting body>`, and no
          `NotGrant:Crew` has ejected it since. **Nothing in this whole chain ever asks which FEATURE the
           Cave is trying to use.** It proves "this body genuinely belongs to the soul Friend already
            trusts" — full stop.

**Why that's enough, on its own, for Music (or anything else).** `Swarm_pier_live(pier, feature)`
 (~5719) — the function every content/Grant-gated door actually calls — takes the shared PIER, not a
  presenting identity: "does THIS Pier carry a live `Grant:<feature>` with no matching `NotGrant`." It has
   no idea, and no way to ask, which crew body's voucher authenticated the frame it's currently serving.
    Once `Swarm_voucher_ok` stamps `sealed.c.voucher_ok`, every subsequent feature check downstream on
     that same Pier — Music included — runs exactly as if the Captain itself were asking. A Cave never
      needed the "CREW SHARES MUSIC" self-catalog mint (§ above) to reach a FRIEND's music at all; that
       mint only ever mattered for the Captain's OWN library. Reaching a THIRD PARTY's grant needed
        nothing but the `Grant:Crew` cert every Cave already gets the moment device-link completes.

**This is, concretely, the exact shape of leak the owner's original question described** — "LinkDevice
 being used to leak access in for lots of other users to the same Invite|Grant by supposing they are all
  the same person" — except it needs no key-cloning at all (§1's Division/Ferry ceremony is a SEPARATE,
   heavier flow: same key everywhere). An ordinary `to:MyCave` Idzeug redeem — a normal-looking, single-use,
    one-body-at-a-time "add a device" invite, exactly the shape `SwarmRole`'s own adversarial Book proves is
     correctly ISOLATED at the grant-minting layer — is *also*, transitively, a grant of full, permanent,
      blanket standing on every relationship the soul has ever sealed with anyone, the instant the voucher
       road is reached. `SwarmRole`'s own sworn isolation ("a Cave is not thereby a music friend") is true
        and still holds — it tests whether Cara's OWN Pier carries a Music grant it was never minted (it
         doesn't) — but it never drives a live frame through the wire/voucher path this section traces, so
          it proves a real, narrower property and was never positioned to catch this one.

**Is this a bug?** No — it reads as the deliberate, adversarially-tested DEFINITION of what "crew" means in
 this codebase (Crew_todo's own title: "one soul, many bodies"). A crew member IS meant to be able to act
  as the soul, everywhere, for as long as it's certified. The tension worth naming plainly: Crew_todo's
   title also says "granted not copied" — true of the DATA (one Grant particle, one Pier, never duplicated)
    but not of the ACCESS (every certified body exercises the full power of that one grant, indistinguishably
     from the Captain). "Not copied" describes the model; it does not describe a narrower blast radius.

**What this means for the rest of this doc.** GrantBorrowing (§5) is NOT made irrelevant by this — it
 answers a genuinely different question (lending scoped, temporary, revocable access to a party that should
  NOT become a full, permanently-trusted crew member) that cert-crew was never built to answer at all
   (cert-crew has exactly one trust tier: full member or nothing). But GrantBorrowing does nothing to narrow
    cert-crew's existing blanket model, and nobody should read its landing as having "fixed" this.

**Checked, not just asked: the Captain-side consent copy already says this plainly.** `LinkDevice.svelte`'s
 pre-mint "TOTAL TRUST" warning (the Captain's own screen, before an invite is even minted) reads *"the
  crew shares this account, its **friends** and its library, and any member can serve it in the crew's
   name"* — that is §1.6's finding, stated in the UI, already, today. The receiving Cave's offer screen
    mirrors it ("serves the Captain's shared account, friends, and music as part of the crew"). So the
     lever this doc first reached for here — better consent wording — turns out to already exist and
      already be honest. **The actual gap is the OTHER side of the relationship**: the FRIEND whose grant
       is being transitively shared is never told anything and has no way to check. §3.1's body-roster
        visibility (already proposed) is exactly that fix, and is now the clearest next thing to build —
         today a FRIEND has no way to see that "the Captain" they trust is, in practice, N different bodies with
            equal standing on the friendship — the roster idea would make that visible for the first time.

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

## 5. THE OWNER'S PROPOSAL (2026-09-23, live, named 2026-09-23) — GrantBorrowing: a live, single-target,
##  Captain-attested loan that never changes WHO holds the Grant

The owner's sketch, restated precisely: address-bind grants (already true, see below); by default only the
 Captain (or whichever Crew member actually redeemed it) holds an outside friend's Grant; when a DIFFERENT
  Crew member's Cave needs to reach that same friend Pier, the Captain — briefly online — signs a scoped
   loan naming that ONE Cave, for that ONE Pier; and since the two devices "want to regularly open the
    two of them anyway," the Captain's own client can do this the instant it comes online and sees the need,
     so it never feels like a manual step.

**The name (owner, 2026-09-23): "GrantBorrowing — the Captain lets Caves in, but remains the Grant-winner."**
 Worth stating why the name is load-bearing, not decoration: "Deputisation" reads as the Captain handing
  some of its own standing to another body — a small transfer of authority. "Borrowing" says the opposite,
   and says it correctly: the Captain is, and stays, the ONE who actually earned this — redeemed the friend's
    invite, built the relationship the Grant rests on. A Cave using a loan is a GUEST on the Captain's own
     standing, temporarily and revocably, never a co-holder. This matters for the friend on the other end
      too, not just internally: from A's point of view (§2), the answer to "who is B" never gets muddier —
       there is still exactly one grant-winner, the Captain, and every borrowed use traces back to a loan
        THAT SAME KEY signed. Nothing about this proposal creates a second, independent claimant the way
         LinkDevice's key-cloning does.

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
   ORIGINAL signer's pub without the two ends having met. A **GrantBorrowing** loan is a ReInvite over a held
    GRANT instead of over an Idzeug: `{ tip: <the friend Pier's pub>, borrower: <the Cave's pub>, iz: <the
     held Grant:Music, embedded>, at, sign }`, signed by the Captain. The borrower Cave presents this (instead
      of a bare Grant) when it dials the friend Pier; the friend's door verifies the embedded grant is real
       AND the loan's own signature traces to the SAME signer — one verify call, the exact shape
        `Swarm_verify_reinvite` already performs. Naming `tip`/`iz`/`sign` kept verbatim from the existing
         ReInvite shape on purpose (§1, §6.3a) — this is that primitive, not a lookalike.

**For the "automatic and smooth" half — reuse the existing WISH pattern, don't build a new request channel.**
 `top_House().c.aim_wish` (Radio_dial) is already "I want X, resolve when whoever's driving next gets a
  chance" — a Cave that wants to reach a friend Pier it only knows about through the Captain can leave the
   identical shape of wish (`c.borrow_wish = { for: <friend pier pub> }`), and the Captain's own driving
    beat, the moment it's next live, checks for outstanding wishes across its Crew and mints the loan
     unprompted. No new plumbing class, no new UI moment on the happy path — only a fresh wish-consumer,
      mirroring one the codebase already trusts.

**Two things to build IN from the start, not bolt on later, given the whole point was to be MORE secure:**
- **Expire it.** Every existing Pier grant in this codebase is documented as infinite-until-revoked
   ("retires at use, never deleted"). A GrantBorrowing loan should be the first exception — a short TTL
    (minutes-to-hours, not the friendship's whole lifetime), re-minted on the next Captain-online tick rather
     than renewed indefinitely. This is what actually delivers "more secure": a stale, unrevoked loan simply
      stops working on its own, and the Captain — as the one grant-winner of record — never has to chase
       down who still holds a copy of something, because nobody holds a permanent copy of anything.
- **Log it where §3.1 already put a light.** "Automatic the moment the Captain comes online" is exactly the
   kind of silent, no-human-looks-at-it moment §2 warned distinguishes a victim from a willing sharer. Route
    every mint through the same visible trail §3.1 proposed for the body roster — a Captain shouldn't need to
     go looking to notice it's been auto-lending to the same Cave every six minutes for a friend it never
      manually approved reaching.

Net assessment: yes — this is a materially better shape than a blanket copy-forever grant, and it costs
 almost nothing extra to build because the two primitives it needs (ReInvite-shaped signing, wish-shaped
  async request) already exist and are already trusted elsewhere in this codebase.

**LANDED 2026-09-23 — the loan primitives + their security proofs, not yet the auto-online wiring.**
 `Swarm_mint_borrow`/`Swarm_verify_borrow` (`Ghost/S/Swarm.g`, a new `//#region GrantBorrowing` right after
  ReInvite) are real: `grant_of_C` embeds the Captain's already-held, already-signed Grant verbatim (the
   friend's door verifies a signature it already trusts, nothing new to trust); the outer loan wrap is
    structurally required to be signed by that SAME embedded grant's own bearer (`claim.for`) — not the
     original external grantor, not the borrower — so "winner" can never drift no matter who mints how many
      loans to however many Caves. TTL'd (`exp`, seconds, Book-pinnable), checked at verify.
- New Book `SwarmBorrow` (`Ghost/Story/SwarmTesting.g`, appended after `SwarmHelm`): Friend mints a real
   Grant:Music for Captain (landed via `grant_to_C`, exactly how any pier carries one); beat 3 proves all
    four security properties as pinned booleans — the winner never moves, a non-bearer's mint is refused, a
     forged outer signature is refused, an expired loan is refused. **3/3 steps green, 4/4 assertions
      declared+sworn, 0 gaps** — verified live via `runner_ask` (`node scripts/runner_ask.mjs run
       SwarmBorrow`, then `declare` for each sentence since a brand-new Book's first swear needs an explicit
        declare pass before a rerun stops flagging its own assertions as gaps).
- **Two real bugs found and fixed during this build, both worth remembering**: (1) `grant_to_C(container,
   atom)` MINTS AND RETURNS THE CHILD — it does not mutate `container` in place (Grant.ts's own contract,
    easy to misread from usage sites that discard the return value because they only cared about the
     side effect). Keep the return value; a `w.i({Grant:1})` stub-then-pass-in pattern silently keeps the
      wrong, signature-less object. (2) A brand-new Book with no prior fixture needs `run.sc.total` set
       explicitly on `mode:'new'` (`if (run.sc.mode === 'new') { run.sc.total = 3 }`, mirroring
        `MusuRadioAim`'s own pattern) — without it the drive never advances past its first tick, a HOLLOW
         hang (not a crash, not an error — just `phase:'begun'` forever) distinct from, and easy to
          confuse with, the ordinary "reload after recompile" staleness this repo already knows about.
- **NOT built**: the wish-shaped auto-request (`c.borrow_wish`) and the Captain-side driving-beat consumer
   that would mint a loan unprompted the moment the Captain comes online — that's real application wiring
    into wherever a Cave's dial-attempt toward an unrecognized Pier currently lives, which hasn't been
     traced yet (unlike the crypto primitives, there's no existing call site to hang it off today). The
      §3.1 visibility trail (log every mint somewhere a Captain would actually see it) is equally unbuilt —
       it depends on UI surface work this doc's §3.1 only ever proposed, never shipped. Both are real next
        steps, not done here.

## 4. What this doc deliberately does NOT claim

- It does not claim LinkDevice has a "bug" — the cloning behaviour is the feature working as designed for
   legitimate multi-device use; the risk is a MISUSE surface, not a defect.
- It does not recommend a specific cap, threshold, or UI copy — those are product decisions for the owner.
- It does not touch Crew_todo §12's separate (and harder) two-Captains-mutex problem — that's about the
   SAME device-cloning mechanism producing a split-brain SOUL, a different failure mode than a friend's
    grant being laundered to strangers. Worth reading together, not merged into one doc.
