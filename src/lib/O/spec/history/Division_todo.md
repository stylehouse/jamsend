# ⚰ HISTORICITY NOTICE (2026-09-03)

The organism/organs design + the whole 2026-08/09 build log: land-of-prepub Model B, the roster mile,
 the seat war, Phases A–D, the ferry battles. Its living content — the teleology, the ladder, the
  substrate facts, the durable laws, the owed list — was distilled into `spec/Crew_todo.md` (the one
   living doc for this cluster). NB this doc's strata disagree with each other (the model moved twice
    on 2026-09-02: grantless stamp vs Grant:Crew at seal; "Charter deleted" vs demoted) — where they
     conflict, `Crew_todo.md` wins. Kept whole as the reasoning trail.

---

# Division_todo.md

## ⓘ UPDATED 2026-09-02 (night) — the LINK MECHANISM flips: cert-not-copy

**Division stands — the teleology (bodies as organs), the roster/Post/Charter machinery, land-of-prepub
 (Model B) all hold.** ONE ruling is deliberately REVERSED by the owner (2026-09-02): the `⚑⚑⚑` line
  below — *"LinkDevice is how that [soul] key gets copied around and turns up on the relay"* — is now
   **"LinkDevice certifies a NEW device key into the crew; it does NOT copy the soul key."**

- **Device-link = a CREW of DISTINCT identities, GRANT-gated (settled same night, superseding the
   "Charter cert" phrasing that briefly stood here).** Each device mints its OWN Identity (own key, own
    address); the Captain mints a **`Grant:Crew`** (by:soul, for:device-key — the same grant primitive
     friendships use) AT THE SEAL and hands it over in the accept; friends `verify_grant` it and trust
      the Cave AS the Captain. The **Charter is NOT the trust root** — it demotes to a Captain-built
       display + recovery artifact (roster picture; destructive resume-Captain-from-Cave). Blessing is
        Captain-only (a Cave can invite, never mint). Grouping lives in the Pier/Peering table, not via
         relay-address collision. **Certify a new key; do NOT copy the old one.** Safer (revoke = one
          %NotGrant on the device's grant) and it deletes the soul-door contention entirely. The single
           clean statement is `CrewLink_todo.md` + memory `crew-charter-glossary.md`.
- **This EXTENDS working code, not greenfield.** DISK TRUTH (verify on disk, not the UI): eed's account
   `/app/.jamsend/account/eed831f1977c4e81/toc.snap` carries a live signed `Charter,era:137` = Captain +
    3 Caves, matching `%Body` rows + both-way MyCave grants. The cert-crew MODEL is already real and
     persisted — the pivot revises the FERRY (which today copies the account blob incl. keys) to
      cert-not-copy, and additionally makes the Charter an ACCOUNT-BACKUP vector (replicate + keep fresh,
       all FSA-able). This means §0's "Charter: deleted" ⚑⚑⚑ ruling is REVISED: the Charter is NOT deleted
        — it survives demoted, a display + recovery artifact (and candidate account-backup vector); the
         `Grant:Crew` is what proves membership. The roster stays the routing convenience.
- **The addressing self-collision is FIXED + Book-green** (memory `foreign-want-door-holder.md`): the
   live "two-founder war" / seat contention was a same-tab two-socket collision, cured client-side. Under
    cert-crew there is no soul-name collision to arbitrate at all.

**→ Division itself is NOT retirement-ready** (it is the live substrate). Only the soul-key-copy mechanism
  and the "Charter: deleted" sub-ruling are revised; read `CrewLink_todo.md` for the replacement.

---

**One soul, many role-bearing bodies — a paradigm-general substrate, music poured through first.**
 Division is how one soul (one keypair) inhabits several bodies across machines and *departmentalises*
  the work among them by role. The Cave|Captain split is music's instance; the substrate is meant to be
   shared beyond music.

---

## THE TELEOLOGY — a soul is an organism, its bodies are organs

*(the PURPOSE behind Division — what the bodies are FOR, drafted 2026-08-31 at the owner's ask for
 "a lovely teleology of the bodies providing a bunch of different organs… particle-expressive about
  relationing and working, Captain of readily-available mobile music vs Cave the huge sprawling
   collection." The mechanism below is unchanged; this is the WHY it serves. It sits ABOVE Post/Seat/
    Charter and points them at a destination.)*

**A divided soul is one organism; its bodies are its organs.** An undivided soul is a single cell
 doing everything adequately and nothing deeply. Division is the soul GROWING ORGANS — specialising
  its bodies so each does one thing wholly and leans on the others for the rest. No organ is the
   whole soul; the soul is the **living relation among them**. A **Post** (Captain, Cave) is not a
    label a body wears — it is *which organs that body grows*.

**The two first organs (music's instance):**

- **The Captain — the organ of REACH and WILL.** The phone in the hand: where the human actually
   is, decides, and acts. It carries **readily-available mobile music** — a pocketful you can play
    THIS SECOND, offline, on a train, curated small and warm. It holds the **invite helm** (the sole
     writer of who-joins; will is issued here, where the human is). Intermittent, mobile, sovereign.
      The Captain is *presence* — the soul's hands and voice.
- **The Cave — the organ of DEPTH and MEMORY.** The always-on box at home: the **huge sprawling
   collection**, the whole library too big for any pocket, kept warm and served on demand. It holds
    the **Seat** (routing anchor + Charter-signer — the body reliably awake to answer for the soul).
     Stationary, deep, tireless. The Cave is *hearth* — the soul's long memory and its patient body
      that never sleeps.

The contrast IS the point: **the Captain has what you want NOW; the Cave has EVERYTHING.** Reach vs
 depth, pocket vs trove, will vs memory. Neither is lesser; the organism needs both, and it is the
  TRAFFIC between them that is the soul being alive across its machines.

**…and a bunch more organs to come.** Captain and Cave are only the first two because music asked
 first. The organ set is open: an **Ear** (a listen-only body — a phone with no library, all reach
  no depth: the noFSA/listen-only life of Onboarding §5), a **Loft** (an editing/compiling body —
   the Wordland room), a Seat-only vs Serve-only split when one box grows too busy. A Post is a
    BUNDLE of organs; one day a body might grow organs à la carte rather than wear a fixed Post name.
     The teleology holds regardless: **bodies specialise into organs; the soul is their union.**

**RELATIONING + WORKING, made of PARTICLES (the §A law of Onboarding_todo, applied to the bodies).**

The organs don't merely co-exist — they WORK together, constantly, and that work should be **living
 legible matter in the mesh, not `.c` flags.** When the Captain wants a track its pocket doesn't
  hold it reaches into the Cave; when the Cave takes in newly-arrived music it restocks the Captain's
   ready set. That is the organism's bloodstream — and you should be able to SEE it in a snap. Sketch
    (words, not booleans; coinage renameable per the glossary):

- **The organs a body grows** — under each `%Body,pub:X`, an organ cluster you can read:
   `/Organ:ready,tracks:214,tags:vio+train,offline/` (the Captain's pocket) beside
    `/Organ:trove,tracks:38k,tags:*,served/` (the Cave's collection). The Post NAMES the bundle; the
     `%Organ` rows SPELL it, in the snap, as quantities. **The Disk cell of Onboarding §4 is exactly
      this organ made visible** — an OPFS/library readout is a body describing the organ it grows.
- **A reach in flight** — the Captain asking the Cave for a track is NOT a `.c.wanting` flag; it is a
   particle: `/Reach,from:Captain,of:<track>,for:play/` — or simply the existing `%Heist,of:X` Jam
    ledger, since *a reach into your own Cave IS a heist of your own trove*. It lives in the snap while
     in flight, graduates when the audio crosses, and is dropped like any served transient req.
      ⚠ This is NOT the reverted `%Reach` liveness cache (killed — see Appendix — for reifying "is the
       other side up" as a kept-fresh VERDICT). This reifies an EVENT — a request actually made,
        resolve-and-emit, fail-forward. **Work-in-flight is legible; liveness stays the transport's.**
- **The working bond itself** — the standing relation between two organs as one cluster both write and
   read: `/Bond,Captain:<pub>,Cave:<pub>,restock:auto,synced:<snaptime>/` — how the pocket keeps step
    with the trove. Not two private `.c` clouds guessing at each other (the very *"two clouds of state
     that want to unison"* the ferry ceremony kept hitting) — ONE particle, seen by both and by the mesh.

**Why this matters (for a reader with little context):** it turns "Division" from plumbing (Seat,
 Charter, routing tables) into a PURPOSE — the bodies are organs of one living soul, and their
  collaboration is the soul alive across its machines. Every future particle here should serve that:
   when you reach to express what an organ IS, or what two organs are DOING, reach for a
    `/cluster,of:words/` the mesh can see — never a `.c` bool. That is the one bet, poured through the
     bodies. **Next spin:** pick ONE of the three sketch-particles (`%Organ` is the cheapest + ties
      straight to the Disk-cell readout) and make it real on the live bodies; the mechanism below is
       ready to carry it.

---

## 0a. THE INVITE HELM IS ROLE-AWARE — MyCaptain is resume-from-backup (design, 2026-09-01)

*(the owner, live, after the family went green: "a Cave produces another MyCave invite? I thought it
 would produce a MyCaptain, and that's how you resume from backup?" — CORRECT, and it is this doc's own
  §LIFECYCLE doctrine; the code just never learned it: `Swarm_ferry_link` hardcodes `{MyCave:1}` for
   whoever presses the button.)*

*(and the owner's grounding, 2026-09-01: "how else do you backup but with all your bodies? we want some
 stuff to be quite immortal, and share it amongst our bodies" — BACKUP IS NOT A SEPARATE ARTIFACT. The
  division IS the backup: replication among your own bodies is the redundancy, and account-matter is
   "quite immortal" precisely because every body carries it. MyCaptain is not a restore tool bolted on —
    it is the organism regrowing its lost organ from any surviving one.)*

**The design, from the standing doctrine (§TWO AUTHORITIES, §LIFECYCLE, §POST'S TRUTH CHAIN):**

1. **The Link button offers by MY Post.**
   - Captain (or undivided founder): mint `%Invite:MyCave` — "add a Cave" (grow the family). Today's
      only road; stays the default face.
   - **Cave: mint `%Invite:MyCaptain` — "resurrect my Captain"** (the recovery road; the most dangerous
      token, deliberately human). The surviving Cave holds the whole account (its mirror); the new
       device redeems, the ferry carries the account exactly as today (soul-holder → blank device; only
        the conferred Post differs), and the newcomer stands as Captain.
   - A Cave minting MyCave: NO (the doc's line — invite-issuance is the Captain's helm, its sole
      ledger; a dead phone freezes issuance until MyCaptain succession). One deliberate exception per
       §LIFECYCLE, nothing else.
2. **Succession evicts (already ruled, §LIFECYCLE)**: Captain is a SINGULAR Post — the new holder's
    grant + re-charter OMITS the old one (`%NotGrant` + re-issue). Caves coexist; a new Cave evicts
     nobody.
3. **Every Post grant-backed — kill the founder-inference.** `Swarm_family_derive` currently infers
    "no husk grant ⇒ founding Captain". Cleaner per the truth chain (truth = the grant, everything else
     a cache): the FIRST ceremony also cross-signs a `%MyCaptain` for the original body, so every role
      including the Captain's derives from a standing grant and the inference dies. (Migration: the
       inference stays as the fallback for pre-existing divisions.)
4. **Attest = the SEAT, not the Captain** (§TWO AUTHORITIES: the Seat is roster-writer + Charter-signer;
    the Captain is the invite helm; orthogonal). `Swarm_family_heal` currently gates sign/gossip on
     role=Captain — right answer today only because they coincide on this deployment. The design gate:
      attest iff I hold the bare seat (`Swarm_address(ident) === prepub`). Seat succession is automatic
       (bare-name lapse + hello-v2); Captain succession never is.
5. **Retirement completes the loop** (the owner's 5-body roster): the heal today only ADDS rows. It must
    also RETIRE: a non-mine `%Body` row with NO live deriving grant (revoked or never-granted) drops at
     the next heal, and the Seat re-charters at era+1 so friends and siblings shrink too. UI: a forget
      affordance ON the family row (the kin-filtered pier hid the old one) → `%NotGrant` on its My*
       grant → derive skips → heal retires. Dead Gri exits by exactly this road.
6. **The cold-restore ladder** (resume-from-backup, both rungs):
   - Rung 1 — a Cave survives: MyCaptain invite (above). The account rides the ferry; nothing new.
   - Rung 2 — only the FSA folder survives: open the folder on a fresh device → account resumes → the
      roster it carries is all dead bodies → the human's "I am all that's left" = re-charter at era+1
       retiring every row but its own (needs a small UI act; NOT automatic — same caution as MyCaptain).
7. **Later hardening**: grants could carry `via:<bodypub>` (which body physically minted) so the helm
    doctrine is checkable, not just honoured; the `caveat:remint` clears at any successful re-charter.

### ✅ THE FORK IS ANSWERED — the owner ruled "A" (2026-09-01): the founding self-grant lives on a
### SELF-HUSK PIER. Built + Book-gated the same night.

**As built (`Swarm_founding_grant`, called from `Swarm_family_heal`):** a divided KEYED Seat holding
 no husk grant signs `%Grant:MyCaptain, by:<soul>, for:<own bodykey pub>` onto a pier keyed by the
  body-key prepub — the exact ceremony-husk shape `Swarm_family_derive` already reads, landed through
   `Swarm_seal` (idempotent, durably stashed, page_bound holds since a body key's prepub IS its pub's
    prefix). Minted from the HEAL, not the Link press: an already-divided live Seat migrates on the
     next 60s trickle, a fresh founder gains it one trickle after its first ceremony, and a lone
      undivided body never grows a keyed roster from a mere button press. The heal re-derives after
       minting, so the same walk is already grant-backed. Gated by SwarmBody beat 8's second `%see`
        ("the founder signs its own captaincy…").

**The corollary it forced — `Swarm_pier_husk` + three skips:** a husk pier (this one, or the Linkee's
 imported ceremony husk) is evidence of MY role, never a counterparty — nothing listens at its address.
  The reaccept sweep was ALREADY pier_accept-blasting the Linkee's husk forever (one face of the
   owner's boot-log storm) and hanging %Owed junk on it. Now the reaccept sweep, the charter gossip
    and the share-up repli_ready blast all skip husks.

**Grant replication between siblings — BUILT the same night** (the brick the guard analysis surfaced):
 `Swarm_family_grants_wire` collects every soul-signed My\* atom off my piers (each SELF-VERIFYING —
  a forgery fails `verify_grant` at the far end); the atoms ride the sibling charter mile
   (`grants:` on the frame) and `Swarm_family_grants_absorb` lands them at the sibling through
    `Swarm_seal` — verify, by-must-be-my-soul, page_bound (a legacy short-form `for` stays home on
     its minting body). So a sibling — a Cave holding the seat through a Captain-death interregnum —
      now derives the whole family from standing grants it absorbed, not from role-guesses. Gated by
       SwarmBody beat 9 (sibling derives the captaincy it never witnessed; a retargeted atom refuses;
        an unsigned relic stays home).

**The retirement gap-Captain guard still stays for now:** replication is trickle-eventual (it rides
 the sibling gossip, both ends live), so a freshly-woken seat may not hold the grants yet. Retire the
  guard only after the stash carries absorbed family grants across a reload and a real interregnum
   has been walked once.

**The §0a ledger as of 2026-09-01 overnight — BUILT + Book-gated (SwarmBody 8/8 green):**
 role-aware helm (1) — a Cave's link mints MyCaptain, the LinkDevice button/title/consent say the
  Captain deal, and `Swarm_offer_land` + InvitePanel treat ANY My\<Post\> as a device link (both were
   MyCave-hardcoded, so a MyCaptain link never even raised the consent) · succession eviction (2) ·
    attest = Seat (4) · retirement + charter shrink + family-row forget (5) · caveat:remint retires when
     a living grant vouches the pub (7, the clearing half) · `Swarm_cave_forgive`/`Swarm_cave_unbond`
      generalized by feature so a MyCaptain relink/forget follows the device-link law, not the friend
       tombstone law.
Now also built (same night, after the owner's "A"): founding self-grant (3) + sibling grant
 replication (above) — so every §0a point except these is DONE. Still owed: rung-2 "I am all that's
  left" restore act (6) · `via:<bodypub>` provenance (7, the audit half) · retiring the gap-Captain
   guard once replication has proven itself across a reload. The ferry, charter, derive, and %Owed
    machinery all already serve.

### ⚑ DOCTRINE CORRECTION (the owner, 2026-09-01) — roles are NOT a trust hierarchy

*"I'm not sure about 'only the Captain issues invites' because then how do we restore a Captain from a Cave
 if you lose your phone? I think they're all high-trust, it's just our replication model that necessitates
  making them different … and their different abilities of course."*

**All bodies are equally high-trust — they are all YOU.** The Captain/Cave split is NOT a trust tier. It is
 forced by two things and ONLY two: (a) the **replication model** needs a singular coordinator (one
  invite-helm, one roster-writer) to avoid split-brain; (b) bodies have **genuinely different abilities /
   organs** (the phone's pocket vs the laptop's 38k trove — §PURPOSE's %Organ). So:
 - "Only the Captain issues invites" is WRONG as a trust rule. A **Cave issues a MyCaptain** to restore a
    lost phone — we already built exactly that (§0a), and it is correct. The helm is a *coordination* role
     (who writes, to avoid two writers), not an *authority* one (who is allowed).
 - This DEFLATES `via:` provenance (§0a #7): if every body is high-trust, "which body minted this grant" is
    an *audit/coordination* nicety, not a security gate — even lower priority than filed.
 - The reframe to carry forward: when a doc says "the Captain does X," read it as "the singular coordinator
    does X so two bodies don't fight," never "the privileged body does X." Capability differences (who HAS
     the trove) are real and separate from trust (everyone is trusted).

### ⚑ RUNG-2 THINKING (deferred, but the owner's design captured, 2026-09-01)

*"what if nothing in Dexie but FSA has a bunch? we'd want to just automatically do something — perhaps point
 to the main account so the later resumer knows who to be … Crew not online can be deleted, but they can also
  come back when they come online again, announcing themselves. there's no way to keep them out or ensure
   they're gone, because of the deal with space."*

 - **Auto-resume shape**: empty Dexie + populated FSA → don't force the destructive button; AUTO-resume,
    and let a **"main account" pointer** in the FSA tell the resumer *who to be*. That likely dissolves most
     of the need for an explicit rung-2 act.
 - **The deep principle — deletion is PROVISIONAL (the space-deal).** You can never *guarantee* a body is
    gone: a pruned/offline body can always come back online and re-announce itself, and there is no way to
     keep it out. So **retirement is "prune what I don't currently see," not "evict forever"** — a returning
      body just re-announces and rejoins. This VALIDATES the current heal-retirement (drop unbacked rows;
       they self-resurrect on return) and means any "declare all dead" act is itself only provisional.
       Build retirement/restore in that spirit: convergent and reversible, never a hard tombstone-the-self.

## 0b. THE WEB OF ACTIVITY AFTER A LINK — booking Heists across bodies, offline-tolerant (design, 2026-09-01)

*(the owner, after the family went green live: "are we through to where I can book Heists on the phone and
 my laptop will carry them out? even if not online at the exact moment … I need this whole web of activity
  after a Link resolved, invented.")*

**Honest status.** No — not yet. But the hard half is done and the second half is ASSEMBLY, not invention.
 What's through: the IDENTITY web — the bodies know each other, their Posts, and how to route to each other
  (charter + roster + `Swarm_body_for`/`Charter_addr`). What's NOT: the ACTIVITY web — a request BOOKED on
   one body and CARRIED OUT by another, tolerant of the carrier being offline at booking time.
 `Swarm_serve_ask` (the serve resolve-and-emit) exists but is ONLINE-ONLY: it emits and returns false if the
  transport can't deliver *now* — no durable booking, no queue. That's the whole gap.

**The key realisation — this is the %Owed pattern pointed at music.** "Book now, carry out whenever the
 bodies next overlap" is structurally IDENTICAL to the charter-debt we shipped this session: a durable thing
  that STANDS on a row, retries on the 60s trickle, and settles on the presence edge. We are not inventing
   offline sync; we already built it (for charters) and proved it (SwarmBody beats 6–9). This arc points that
    same machine at a track request.

**The lifecycle (the %Reach/%Heist booking — §PURPOSE's "reach in flight" made real):**
 1. **BOOK** (phone): mint a STANDING snapped particle — `%Heist,of:<track>,for:play,by:<phone body pub>` —
     NOT a `.c.wanting` flag. It lives in the snap the instant it's booked, so both bodies and the mesh see it.
 2. **RESOLVE** (phone): which of MY OWN bodies serves music? Read it off my own charter — `Swarm_body_for(me,
     'Cave')` / `Charter_addr(my %Peering, 'Cave')` — the exact family routing built this session. Degrades to
      the Seat if no charter entry (the always-on anchor).
 3. **DISPATCH** (phone → laptop): the booking rides `Swarm_sibling_send` to the resolved body address. If the
     laptop is OFFLINE → the booking simply STANDS (it's durable — snapped + stashed), and the miss is a
      `%Owed,owe:heist` debt on the laptop's %Body row, retried by the family trickle, settled on the presence
       edge. **This is "even if not online at the exact moment" — for free, from the machine we already have.**
 4. **CARRY OUT** (laptop, when awake): the laptop's share/heist loop notices standing Heists addressed to it
     (heard over the wire, or replicated in), gates on the Music grant, and serves the track via Repli (the
      crate machinery that already moves audio).
 5. **GRADUATE**: the audio crosses (Repli), the `%Heist` graduates (audio landed) and DROPS like a served
     transient req (the owner's law — scaffolding, not ledger). On the phone the booking resolves to "arrived."

**→ SUPERSEDED BY THE REACH LAYER (2026-09-01, same day): see `Reach_todo.md`.** The owner generalized
 this design ("we've been under-abstracting … one foam layer between the foam layers"): the booking below
  is not a music-special mechanism — it is ONE INSTANCE of the `%Reach` primitive (a durable addressed
   cross-body intent), which LANDED Book-gated (SwarmBody beats 10–12): B1 booking = `Swarm_reach_book`
    ✓ · B2 charter resolve = `Swarm_reach_addr` ✓ · B3 dispatch + offline-standing + trickle retry =
     `Swarm_reach_dispatch`/`_settle` ✓ (the state IS the debt — no separate %Owed) · B5 graduation ✓ ·
      **B4 (the carry-out doer binding to Heist/Repli) is the remaining owner-seam** — it needs the
       sibling music-serve lane (a body serving its sibling like a listener), which is its own arc.
        The brick list below stays as the map of what the music slice still binds:

**The bricks (each Book-gateable, in SwarmBody's world or a new SwarmHeist Book):**
 - **B1 — %Heist as a durable BOOKING** with a lifecycle (booked → dispatched → serving → arrived), addressed
    by role, snapped + stashed. *(Today it's a Jam ledger of events — this gives it a standing lifecycle.)*
 - **B2 — bind the resolve to the FAMILY charter** (`Swarm_body_for` on my own %Peering — "who in my family
    serves music"), not just a friend's %Pier.
 - **B3 — cross-body dispatch + offline debt**: booking rides `Swarm_sibling_send`; a miss becomes
    `%Owed,owe:heist` on the target %Body row, retried on the trickle, settled on the presence edge. **Reuses
     `Swarm_owed_note/paid/settle` verbatim** — the settle knob (`w.c.owed_settle`) already exists to gate it.
 - **B4 — carry-out on the target**: the share loop picks up standing bookings addressed to it and serves them
    (bind `Swarm_serve_ask` → Repli at the Heist site — the "owed seam" §ROUTING step 5 already names).
 - **B5 — graduation + the phone-side "arrived"** resolution (drop the served Heist; the phone sees it land).

**THE ONE FORK for the owner (like the founding-grant "A"):** does the booking REUSE `%Heist` (the existing
 Jam ledger — one mainkey, add a lifecycle + `for`/`by` addressing) or is it a FRESH `%Reach` particle (the
  §PURPOSE sketch — a clean request atom, leaving `%Heist` as the pure event ledger it is)? The tension: one
   mainkey must not wear two shapes (the CLAUDE.md "only one of anything" law). Reuse is cheaper; a fresh
    `%Reach` is cleaner if `%Heist` is genuinely an event-ledger and a booking is a different KIND of thing.
     **Recommend `%Reach`** — a booking (a standing intent) and a heist-event (a thing that happened) are
      different particles; conflating them is the two-shapes-under-one-mainkey tell. Answer and B1 has its shape.

## 0. WHERE THIS IS (2026-08-28) — the live device-link path is the FERRY model

**⚑⚑⚑⚑ 2026-09-02 (night) — THE FERRY MODEL FLIPS TO CERT-NOT-COPY, and the cert is a `Grant:Crew`
 (grant-based, NOT a carried Charter — that intermediate stood for hours and was superseded). See the ⓘ
  note at the top of this file + `CrewLink_todo.md`.** The ferry below copies the account blob (incl.
   keys) at link time; the built model (`Ghost/S/Swarm.g`, InvWalk 8/8) has each device mint its OWN key
    and the Captain mint `Grant:Crew,by:soul,for:device-key` at the seal. The land-of-prepub (Model B)
     receive/send work in this §0 STANDS (bodies hello with own keys, roster gossip, contact-learned
      %Body rows) — it is exactly the substrate cert-crew needs. What changes: the MINT-STOP/ferry no
       longer transplants the soul key; the account DATA replicates (`Swarm_export {ferry:1}` omits the
        key), with the Charter as a backup/display vector only. The `⚑⚑⚑` "Charter: deleted" ruling
         further below stays REVISED — the Charter survives, but as artifact, not authority.

**✅ 2026-09-02 (midday) — THE REBORN-KNOCK WEDGE (live ceremony "stuck at receiving from eed"),
 two layers, both cured in `Peeroleum.g`'s reused-seq collision branch:** (1) a reborn knocker's
  `pier_hello` seq=1 hit a STALE pier's inbox history and was swallowed as a replay — Swarm_hello
   never ran, no accept ever crossed; the era reset only exists for sealed friends, and the KNOCK
    ITSELF is the rebirth proof (its ?Iz presig + serial ledger re-verify every time). (2) the
     first cure (reset + re-book through the pier inbox) died one layer deeper: **req_unemit's
      pre-Ud gate** passes only hello/noop on a %Ud-less pier, so the booked knock vanished with
       `error:'pre-Ud'` — no rebuff, no accept, perfectly silent. Landed: the collision branch now
        resets the dead stream and dispatches the knock **exactly like first contact** — handler-
         direct (`w.c.on['pier_hello'](w, null, frame)`), no inbox booking, ack via re-route.
          Law worth keeping: *nothing may book onto a pier inbox before %Ud exists; first-contact
           frames ride the pier-less lane.* Verified: SwarmDoor/SwarmWire/SwarmChain/InvFerry all
            ok_pct:1 (SwarmWire's caveat:4 is `round=` drift, assertions 5/5 sworn). Diagnosed,
             NOT chased: eed's `no Pier for pulse to=5ade3510` chatter is the tab pulsing its OWN
              Captain %Body row (5ade = prepubOf(own bodykey)) — the pulse fan may want a
               skip-self; parked beside the body-addressing rulings below.

**✅✅ 2026-09-02 (overnight) — PHASES A+B+C LANDED + VERIFIED (the owner: "finish eeeeverything";
 all Swarm* + Inv* Books green ok_pct:1 on the live e747 runner, TwoFounder green, fixtures
  re-recorded via `runner_ask accept` where the model legitimately moved them):**
  - **A — the crew road (receive).** `Peeroleum_crew_road` admits a pier-less frame whose VOUCHER
     names a soul we hold (station or route pier) — the voucher was ALREADY soul-signed, so
      "whoever can sign with that key is Crew" was one check too narrow, now generalised
       (`Swarm_voucher_ok` accepts a page-bound body-from pinned to the sealed soul key).
        `Swarm_account_of` resolves to:<my-body-prepub>; `Swarm_pier_of_body` finds a body's home
         pier; a vouched body-from is CONTACT-LEARNED as a %Body row under its pier ("the Charter
          just popped up by whoever you manage to talk to").
  - **B — land of prepub (send).** Every body hellos its OWN key (no want — nothing to arbitrate);
     the soul hello stays as the DOOR. `Swarm_sibling_send` speaks AS the body (body page +
      voucher); `Swarm_body_addr` derives every dial (prepubOf(pub), seat only as pre-migration
       fallback); reach/report/pulse/charter-mile all flipped. SwarmBody beats 10/12 re-authored
        to key-derived expectations.
  - **C — the grant purge (truth moved, cargo still riding).** `Swarm_seal` stamps `link`+`post`
     on the chrysalis pier (derived from the sealing grant while the wire still carries one; the
      rehydrate re-seals through seal, so the stamp survives reload; `cave_unbond` clears it —
       forget stays tombstone-free). `pier_linklive`/`grant_post`/`family_derive` all read the
        STAMP first (grant arms kept for pre-purge accounts). **THE MINT-STOP LANDED (morning,
         2026-09-02): a device-link redeem seals GRANTLESS** — `pier_accept` carries
          `link:{post,serial}`; the linkee verifies page_bound + THE ISSUER PREPUB IT SCANNED (the
           ceremony req armed at redeem — the QR's physical channel replaces the grant signature;
            the fc-sealed ferry stays the hard gate); `pier_confirm` echoes the link, NO reciprocal
             mint. Friendships keep the full grant handshake untouched. Plus a REAL BUG FIX found
              en route: the derive link-arm needed the PHANTOM-MEMBER GUARD (the linkee's chrysalis
               points at the SOUL — my own soul key derives no member; latent because Book piers
                are hand-planted, never sealed). ✅ BOOK-VERIFIED (runner returned ~09:00,
                 accept batch landed): InvFerry 6/6, InvWalk 8/8, InvSeal 5/5, SwarmSpread 5/5,
                  SwarmBody 17/17. Three REAL fixes fell out of running the ceremony live:
                   (1) the redeem's 'awaiting' arm moved OUT of `Swarm_redeem`'s station_up
                    gate — the scanned-issuer expectation is GHOST state (the accept link-arm
                     verifies against it), so a Book's redeem must arm it too (the
                      Ferry_rebuild law: req machinery works headless; only the %Invite vivify
                       stays live-tab-only). (2) the hello link path RE-FIRES the ferry seam
                        after stamping — `Swarm_seal` runs on_seal BEFORE the caller's stamp
                         lands, so a grantless pier wasn't linklive yet and the account crossed
                          a beat late via the retry pump. (3) `Swarm_pier_live` grew the STAMP
                           ARM — a link feature (My<Post>) is live off `link`+`post` match,
                            feature isolation intact ('Music' never reads the stamp); this is
                             what let InvWalk's puppet-confirm find its pier. InvWalk's beat
                              also re-authored to null addresses (it still hand-planted `_1`).
              - **founding_grant DELETED (same morning):** `Swarm_founding_grant` now seals the
                 self-husk pier grantless and stamps `link, post:Captain` — the same chrysalis
                  shape every rail wears. Beat 8 re-authored (stamp probe;
                   `founding_stamp_stands`), beat 9 REWRITTEN from grants-wire to THE ROSTER
                    MILE (plain rows union grow-only; the sibling sees the captain off ROWS;
                     the unsigned relic and the chrysalis stamp both stay home — new Assertion
                      'the-roster-mile-replicates'). `Swarm_family_grants_wire`/`_absorb`
                       remain as the legacy sidecar on roster frames — pre-purge interop only,
                        deletable once pre-stamp accounts are retired (owner's call).
  - **Fixture moves accepted:** SwarmBody 008-017 (the stamp line + cascade), InvFerry 004-006
     (both ceremony piers stamped), SwarmSpread 005 (the long-stale `_1`→`_2` healed — first
      all-green SwarmSpread). Credulate/Credulation churn reverted per discipline.
  - **D — THE LIVE PATH FORGETS THE CHARTER (landed same night, all Books re-verified green):**
     `family_heal` writes pub+role+name rows only, SCRUBS the address column, signs nothing —
      the **roster mile** (`Swarm_roster_gossip`/`Swarm_roster_heard`, new `roster` frame kind)
       replaces the charter mile, carrying the same grants+organs sidecars, membership proven by
        the voucher at the door, grow-only union converging views. `Swarm_serve_to` routes off
         the contact-learned rows (Charter_addr = pre-purge fallback). Ceremony finalise
          (`adopt_absorb`/`adopt_finalise`/`ferry_heard`) assigns NO seats. The COHORT CONSULT
           deleted; the adopt hook became the **DOOR YIELD** — a displaced tab stands at its own
            body name (no `_N` ever adopted; the courtesy prepub-bind gives door failover for
             free when the holder closes). `want` + the relay arbiter STAY (the door's
              single-delivery hinges on exactly one qaddr=bare socket — relay.ts:660-691).
     **Charter functions still exist, Book-driven only** (SwarmCharter green, unchanged): their
      deletion + the SwarmCharter/SwarmGossip Book retirement is the OWNER's call — they test a
       mechanism the live path no longer uses. Beats re-authored to the new truth: SwarmBody
        beat 8 ("no charter is minted for the roster is not a document"), SwarmSpread beat 3
         ("the roster routes both... no seat column at all") — toc sentences updated in place,
          slugs preserved. TwoFounder reworked: identical pub:role rosters with ZERO
           negotiation, no address columns, no charters — the war is not won, it is unfightable.
  - **HELD for the owner:** live eed-tab verification (reload both); retire SwarmCharter/
     SwarmGossip Books?; delete charter functions + Charter_addr + era machinery once the Books
      go; the C mint-stop pair (above); Steal Back's meaning under land-of-prepub (the soul-DOOR
       contest is still real; `next_suffix` survives only there).

**⚑⚑⚑ 2026-09-01 (night) — THE SETTLED MODEL (the owner, live): "Grants are for complicated
 relationships between PEOPLE; Links are just your Account in multiple places." "It's an Invite,
  but it doesn't birth a Grant." "The Charter doesn't need persisting at all — whoever can sign
   with that key is included in the set of Crew; LinkDevice is how that key gets copied around
    and turns up on the relay." This supersedes the §C fork below (Model B wins AND slims
     further) and puts §0a's grant-based founding ruling in question.** *[⚑ 2026-09-02 (night):
      itself superseded — crew IS grant-gated now (the Captain mints a `Grant:Crew` per device at
       the seal; the soul key never travels), and the Charter persists demoted to display +
        recovery. See the ⓘ at top + `CrewLink_todo.md`.]*

**The three-level ladder (each level its own key/token, its own membership rule):**
  | level | key | scope | membership | office |
  |---|---|---|---|---|
  | **Soul** | soul key | the identity | IS the identity — holds-the-key = member | — |
  | **Body** | body key (Dexie `bodykey_read`, per store, never replicated) | device/browser-profile | soul key ferried to it (LinkDevice) | a **Post** (`%Body,post` — Captain, Cave) |
  | **Sibling** | vessel `place` (per pageload/Mundo) | session tab | none — not in any roster | a **duty** (play/encode work-split) |
  Same-browser tabs share the Dexie store → share ONE body key → they are one Body, many
   Siblings (the eed "two-founder" war was really this case — no address contention exists
    under land-of-prepub, the vessels coordinate behind one body via `%Sibling`).

**The Invite is the shared root; what it births differs:**
  - **Friendship**: Invite → `%Pier` + `%Grant` (by/for/feature — Music &c.). Grants live HERE ONLY.
  - **Link**: Invite (`#Iz=<token>&fc=<secret>`) → ferry the sealed Account → new store mints its
     body key → a `%Body,pub/post/name` row. NO pier-to-self, NO `%Grant:My<Post>`, NO Charter.
  - **Charter: deleted.** Membership = can-sign-as-the-soul. The roster (`%Body` rows) is a
     ROUTING convenience, not a membership proof — replicated between bodies (`roster_of`/
      `roster_onto`, Tier-B grow-only union) and published to friends on the pier page /
       `pier_accept` (which ALREADY carries it — `charter_absorb` only funneled into the same
        `roster_onto`). Frames are body-signed; a friend trusts the roster the way it trusts
         every other frame. Era/single-writer/Seat-signing apparatus deletes with it.

**The purge surface (sweep 2026-09-01 — the grant is load-bearing at exactly FOUR seams; the
 ferry's core triggers already ride the Invite: serial-bound ~1070, secret ~1065, warmth
  `heard_at` ~5699 — the `%Grant:MyCave` minted at seal is cargo, not mechanism):**
  1. **`Swarm_pier_linklive` gates** (~1061, 2083, 4042, 5674, 5737, 5789 — ferry_want /
      on_seal / confirm / poke). New home: the ceremony's own state (serial + phase + no
       tombstone) — "a live link rail" becomes "an unfinished ceremony req whose serial matches."
  2. **Role source** — `Swarm_grant_post` (~4884), ferry_got's post derivation (~1177). New
      home: the ceremony/ferry hand-off names the Post directly (ferry_got ALREADY carries the
       far body's pub + chosen name — add post; the helm is already role-aware, §0a).
  3. **`Swarm_family_derive`/`heal`** (~4901/4941, grants → roster). New home: DELETE the
      derivation — the LinkDevice hand-off writes `%Body` directly at ferry_got, and roster
       replication (charter mile sans charter: the `grants`/`organs` sidecar frames) unions the
        rest. The 60s heal shrinks to roster-replication settling.
  4. **Revocation** — `%NotGrant:MyCave` (~1112, 3986, 4035) + the Stage-0/1 carve-outs
      (`cave_forgive` ~4058 "fresh consent wins", `cave_unbond` ~4082 "forget the bond WITHOUT
       a tombstone or it buries the next relink"). New home: an **UnLink tombstone on the
        roster** (soul-signed `%NotBody,pub` beside the grow-only union) — and KEEP both
         carved lessons: a fresh Link clears a stale UnLink of the same pub; forgetting a
          device drops its row without tombstoning, so a reused body-key can relink.
  Also deletes: `Swarm_founding_grant`/self-husk pier (~4457 — §0a's ruling "A" is superseded
   IF the owner confirms: the husk's job, proof-of-MY-role, moves to my own `%Body` row), the
    husk-exclusion carve-outs (~1722, 3289, 5273), `Swarm_post_from_feature` branching
     everywhere (~1981, 2139, 4017 — the "ANY My<Post> is a device-link, not a friendship"
      confession at 4013 IS the category-error tell this model cures).

**Naming ruling wanted:** the office axis wears three names — `Post` (grant-land), `role`
 (`%Body`), `role` (`%Sibling`, a DIFFERENT axis: per-tab work-split). Proposal: a body **holds
  a Post** (`%Body,post`, retire `post_from_feature` — nothing to extract a Post from), a
   sibling **has a duty** (`%Sibling,duty`). "Seat ≠ Post" (the code's own line ~1183) stays
    true; under this model the Seat shrinks to "who holds the soul DOOR binding right now."**

**THE PIER/PEERING LAW (the owner, same night): "Peering = who we listen as, Pier = who we
 dial."** Not a category error — a perspectival duality worth leaning into: my %Pier is my
  view of THEIR %Peering (and they see my Peering as their Pier — the `/Pier/Peering,pub` page
   child is literally that view, held). The law makes the violations legible:
  - a **husk pier** (a Pier to MYSELF) dials no one — confirmed cargo; deletes with the purge.
  - a **role-slot Pier** (`from:'runner'`, ClusterAddressing §6) dials a ROLE, not an identity
     — the whole §6 from-mess stated in one clause.
  - **sibling frames forced through Piers** (the "a body isn't a friend" drop, the pier-less
     same-soul dispatch patch): a twin needs a DIAL-HANDLE, not a friendship. Under this model
      the handles split cleanly: **%Body is the dial-handle for a twin** (pub → prepub → its
       address, land-of-prepub), **%Pier is the dial-handle for another soul**, and Grants
        ride only Piers. The Peeroleum same-soul carve-out becomes the rule, not the patch.
  - **dial-side session claims stamped on the listen-side object** (`%Peering.sc.address` /
     `stolen` / the seat claims) — already export-omitted, but the law names WHY they were
      always awkward there.

**SIMILAR AUTISTICS (wider sweep, 2026-09-01, ranked)** — most collapse into the two
 conflations this model cures (identity/address, dial/listen); listed so none get lost:
  1. `%Sibling.address` vs `%Body.address` — same key, opposite lifetimes (session seat claim
      vs durable roster field). Dies under land-of-prepub (address = derived from pub).
  2. `header.from` unverified + role-shaped (ClusterAddressing §6, known) — Model B gives
      every body a stable, verifiable `from` by construction.
  3. `role` triple-duty — ✅ CURED (naming pass, 2026-09-02 morning): **%Body.sc.post** (a Body
      HOLDS a POST — durable, and now DELIBERATELY exported: the old blanket `role:1` omit was
       silently stripping it from every ferried account, contradicting the %Body header's own
        "PERSISTENT, replicated" claim), **%Sibling.sc.duty** + `%Peering.sc.duty` (the tab
         work-split — session-only, export-omitted as before; `Swarm_take_duty`, with
          `Swarm_take_role` left as a thin alias until blessed away). Compat reads at every
           landing seam (`e.post || e.role`): rehydrate (old disk mirrors), roster_heard/onto
            (pre-flip senders), adopt_finalise, charter_payload (the deprecated charter format
             keeps its legacy `pub:role:address` shape verbatim). Cluster-tab `role`
              (runner|player) and Lang roles are DIFFERENT domains, untouched. All Swarm*/Inv*
               Books re-accepted green (`Body,…,role:X` → `post:X` fixture drift). STILL PARKED
                for the owner: the prepub→pubkey phase-out and the %Pier.sc.pub lie (holds a
                 prepub; the full pub sits on the /Peering child) — wire+relay-wide, wants a
                  real ruling.
  4. `humdinger` = presence ∧ consent (Ferry_todo §0 already flags the fails-open gate; the
      consenter split is owed SEPARATELY from this model).
  5. `claim.for` full-pub vs prepub-address leakage (Cluster_spec §3.2a half-fixed) — the
      rule "for is an IDENTITY, never an address" becomes cheap to enforce when address is
       always derivable.

**⚑⚑ 2026-09-01 (evening) — THE BIG THINK: does the Crew need a Charter at all, and where do
 addresses come from?  (The owner, mid-session: "it doesn't matter who among Crew holds the bare
  pub... what functionality connects to that holder though?" and "do we need [the Charter] if the
   relay can easily tell the Crew that is online?")  This supersedes the phase-3 framing below and
    the "Cave-first?" question — both were asking inside a model this section questions.**

**§A. What the bare-holder actually is (the corrected understanding).** The bare name is not a
 prestige address — it is the **Seat**, and exactly two functions attach to it: (1) it signs and
  distributes the **Charter** (the "ledger of the Crew" — `Swarm_charter_sign` + the sibling mile of
   `Swarm_charter_gossip`; single-writer so membership changes serialize), and (2) it is the **default
    door** — friends dial `to:<soul-prepub>`, and `Charter_addr`'s null-fallback dials the Seat. WHICH
     body holds it is genuinely arbitrary (the teleology's "the Cave holds the Seat" is an AVAILABILITY
      heuristic — the always-on box naturally wins first-come — not a rule to enforce). What must hold:
       exactly ONE holder, everyone AGREES who, and the body the ledger names at bare is the body
        actually BOUND at bare on the wire.

**§B. Do we need the Charter if the relay can tell who's online?  YES — but for MEMBERSHIP, not
 necessarily for ADDRESSES.**  Four things presence structurally cannot do:
  1. **Offline members exist.** The Crew is who IS of the soul, not who is awake — the Captain is
      intermittent BY TELEOLOGY, and the reach primitive books durable intents against sleeping
       bodies. Presence is a live VIEW of the Crew's subset, never the Crew.
  2. **The relay is list-in by design.** `who` (relay.ts ~514) answers "which of THESE addrs are
      online" and REFUSES to enumerate (`locals` unlistable — the owner's own parked anti-leak
       ruling, ClusterAddressing §4a). The addr list the probe needs comes FROM the roster. Presence
        is a lookup KEYED by the ledger — complement, not substitute.
  3. **The relay is untrusted.** Frames are signed precisely because the relay is readable/dumb
      (ferry security posture). A friend deciding "is body 19754b… really eed's?" cannot ask the
       relay — it doesn't know, and couldn't be believed if it claimed to. Only the soul-signed
        Charter (grants as proof, Charter as the compiled summary) answers portably.
  4. **Wake-up self-knowledge + cross-relay truth.** A body booting offline still knows its family
      (the stash + sibling-absorb pillar); bodies on different relays share no `locals` at all. The
       Charter travels in frames/piers/ferries; the relay's view is per-AP and dies with it.

**§C. THE FORK — where addresses come from.  Model S (status quo): one soul-name family, bodies at
 `<soul>`, `<soul>_1`, …, seats arbitrated by the relay (hello-v2 want/grant), succession + collision
  heals + adopt/rehome keeping ledger and wire aligned.  Model B ("land of prepub"): every body
   hellos with its OWN body key and IS its own address — `to:<prepubOf(body_pub)>` — collisions
    impossible BY CONSTRUCTION.**  Under B:
  - **The Charter slims to what §B proved it must be: membership + roles (+ organs) — `pub:role`
     per body, soul-signed, era-stamped.** The address column EVAPORATES: address = prepubOf(pub),
      derived, never assigned, never fought over. (Routing = membership × presence.)
  - **The entire seat apparatus deletes**: want/grant arbitration, familyAddr, adopt hook, rehome,
     next_suffix, collision heals, seat succession races — the whole class this week's bugs (dual-
      bare, era war, `--player=eed` clobber) came from. The relay needs NOTHING new — handleHello
       already binds any self-signed key; a body helloing with its bodykey works TODAY. (This
        SUPERSEDES "phase 3 hello-v3": instead of teaching the relay soul-families, stop needing them.)
  - **The doubled-stream disease dies at the root**: `from:<body-prepub>` gives each body its own
     stream identity by construction — hello-v2's arbiter was built to arbitrate around exactly this.
  - **The `--player` clobber dies**: deliverLocal's own-door ambiguity (two tabs, both `?addr=<bare>`,
     both "own") cannot form; each tab is dialable at its own name.
  - **The Seat survives, smaller**: the soul-name stays bound as the DOOR (the Seat hellos the soul
     key beside its body key — two hellos on one socket, both already routine) and the Seat stays the
      single Charter-signer. First-come arbitration of ONE binding is all the relay ever arbitrates.
  - **Migration inventory (bounded — all address consumers funnel through two necks):**
     `Swarm_sibling_send` (to:addr → to:body-prepub; from:seat → from:body-prepub) and
      `Charter_addr`/`Swarm_body_for`/`Swarm_reach_addr` (role→addr becomes role→pub→prepub).
       Receiver side, ONE real change: friend-traffic arriving `from:<body-prepub>` misses the
        soul-keyed %Pier lookup — needs a "body-of-my-friend" road (prefix-match `from` against the
         pier's absorbed charter pubs), mirroring the 2026-09-01 sibling road in Peeroleum. Plus
          fixture re-records (payload drops its address segment) and the `?I=` boot binding.
       Graceful path: charterless old friends keep dialing the soul door — the Seat still answers.
  - **Cost/risks**: N body prepubs visible to the relay instead of one family (equivalent leak to
     today's `_N` suffixes); spine-adjacent surgery in the from-resolution (§6's header.from caveats
      apply); the multi-writer question stays settled by keeping the Seat as sole signer.

**§D. Honest flaw-note on the shipped phase 2 (pub-sort).** As the SOLE authority it can contradict
 a live relay grant (higher-pub body helloed first and holds bare → the heal writes the ledger naming
  the LOWER pub at bare — ledger and wire disagree). It is safe as the no-arbiter FALLBACK (Books,
   relay-down founders — where it provably converges, the TwoFounder gate). Under Model B the whole
    question dissolves. So: pub-sort STAYS as shipped (strictly better than what preceded it), the
     three-authority rework (relay grant ▸ recorded claim ▸ pub-sort slot, sketched mid-session) is
      the Model-S successor ONLY IF the owner picks S. **Decision to make: Model S polish vs Model B
       migration. The recommendation is B** — it deletes the bug class instead of managing it, needs
        ~zero relay change, and makes the Charter exactly what §B says it is: the signed ledger of
         who the Crew IS, with the relay answering who is AWAKE, and identity itself answering WHERE.

**§E. Model B stress-tests + migration order (for the implementing session).**
  - **Half the codebase already lives in land-of-prepub**: grants' `for` carry body pubs; the ceremony
     husk pier is keyed by body-key prepub; page_bound holds because a body key's prepub IS its pub's
      prefix; SwarmSpread beat 2 has the blank device offering "itself as a body not a role" with its
       OWN key pre-ceremony. `?I=` keeps naming the SOUL (which account to load); the hello names the
        BODY. The Lies channel hellos with the body key too → `--player=<body-prepub>` addresses one
         specific tab — the introspection un-jam falls out for free.
  - **Repli stability bonus**: friend-side repli windows key on `header.from`. Under S a succession
     (body flips `_1`→bare) CHANGES its from mid-friendship — a latent stream-fork nobody has hit yet.
      Under B a body's from is its key: stable for the body's whole life.
  - **The Seat under B**: first-come arbitration of ONE binding (the soul door) — `heldByAnother`
     survives scoped to that single name; door-holder = Charter-signer (same invariant as today);
      the ledger doesn't record the door (it's live state; all-asleep = nobody home, correctly).
  - **Migration order (each step live-verifiable, old+new interoperate through the soul door):**
     (a) receiver-side "body-of-my-friend" road (absorb `from:<body-prepub>` by prefix-matching the
      pier's charter pubs — backward compatible, accepts both froms); (b) flip senders (sibling +
       friend) to body-prepub from/to; (c) drop the address segment from the Charter payload +
        re-record fixtures; (d) delete the seat apparatus (want/adopt/rehome/next_suffix/collision
         heals) + TwoFounder gate shrinks to "identical membership payload."

**⚑ 2026-09-01 — SEAT SUCCESSION: the dual-bare + era-climb diagnosis, rechecked against the code.
 This block is the front of the queue; the ferry material below it stands.**

*The live symptom (two `?I=eed` tabs, Grav + Gurn):* the charter carried TWO bodies at the bare seat
 (`…Cave:eed…;…Captain:eed…` — one Cave AND one Captain both bare) and the era climbed +1 every trickle
  with a byte-identical payload. The owner confirmed the design: **every body has its own key already
   (`ident.c.bodykey`, `Swarm_body_key`); binding and seat-pick must key off it.** Four root causes,
    each pinned:

1. **The "Captain = bare" legacy assumption is the dual-bare MINT — three sites in `Swarm_family_heal`
    (Ghost/S/Swarm.g).** Line ~4993: a member row with `role==='Captain'` is FORCED to the bare address
     — and that branch runs even on `collide`, so the 2026-09-01 collision heal never touches it (the
      Captain re-mints straight back to bare beside the seat's own bare row). Line ~4969-73: a huskless
       self defaults `myrole='Captain'` and takes bare. This contradicts the Seat doctrine the SAME
        function states at ~5028 ("the Seat — the bare-name holder — is roster-writer + Charter-signer;
         the Captain is merely the invite helm; **orthogonal**"). *Fix: role NEVER implies address.
          Address comes from the roster row / arbiter grant / next_suffix only; delete the
           Captain→bare forcing at both sites.*

2. **Seat-ness is decided off per-tab volatile state, not the signed roster.** `seat =
    Swarm_address(ident)===prepub` (~4951), and `Swarm_address` (~4339) is just
     `peering.sc.address ?? name` — local %Peering state. Two tabs can BOTH read bare in the pre-adopt
      window (boot ordering, reload before the hello_ok adopt hook fires) → two signers → era wars.
       *Fix: a body's durable address derives from ITS OWN `%Body,pub:<bodypub>` row in the absorbed
        charter (new `Swarm_address_of_body(ident, bodypub)`); the hello `want` (~1567) asks for THAT,
         falling back to arbiter/next_suffix for an un-rostered body. `Swarm_address` stays the live
          view but is fed by roster-first picks.*

3. **The relay cannot tell same-soul bodies apart.** The station hello (~1560) signs with the SOUL key
    only; `relay.ts handleHello` binds `prepubOf(pub)` and arbitrates seats per-SOCKET (`seats` vs the
     always-added courtesy bare bind, ~665). Seat succession is therefore first-come-per-connection:
      a reconnecting body cannot reclaim ITS seat, and with two same-soul tabs the courtesy binds make
       `to:<bare>` delivery ambiguous (the runner_ask --player clobber). *Fix (hello-v3): carry
        `body_pub` beside the soul-signed header; the relay stamps it on the socket; `heldByAnother`
         treats a holder with the SAME body_pub as self (idempotent reclaim across reconnects), and
          seat grants become per-body-stable. Optionally `deliverLocal` prefers the socket whose
           `seats` holds the addr, closing the two-station ambiguity.*

4. **The era climbs because identical payloads re-sign.** `Swarm_charter_sign` (~5172) bumps era
    unconditionally (`e = cur.era + 1`), and the heal re-signs whenever ANY `%Owed,owe:charter` debt
     stands (~5025) — an unpayable debt (sibling offline, or the pre-fix sibling drop) = +1 era per
      trickle forever, same payload. *Fix: in charter_sign, `if (cur && cur.sc.payload === payload &&
       cur.sc.sig) return cur` — the stashed signature still verifies; paying the debt means
        re-GOSSIPING the standing charter, not re-signing it.*

**Order of work (each phase independently landable + verifiable):** (1) kill Captain→bare + the
 identical-payload re-sign — pure Swarm.g, stops the bleeding; (2) roster-first seat pick
  (`Swarm_address_of_body` + want derivation); (3) hello-v3 body_pub at the relay (`relay.ts` +
   station hello — see `ClusterAddressing_todo` §4/§6, this intersects the parked address-model
    question); (4) live-verify: reload BOTH eed tabs (HMR caches the old .go), then minisnap
     `self>Peering>Charter` + `self>Peering>Body` on each body — era must FREEZE and addresses
      converge unique; `runner_ask --player=<prepub>_N` should then address a specific body.

**✅ PHASE 1 LANDED + BOOK-VERIFIED (2026-09-01, working tree, uncommitted).** Three edits in
 `Ghost/S/Swarm.g` (→ recompiled `src/lib/gen/S/Swarm.go`, LocalGen clean + esbuild strict-parse clean):
  - `Swarm_charter_sign` (~5178): `if (era == null && cur && cur.sc.payload === payload && cur.sc.sig)
     return cur` — an unpaid `%Owed,owe:charter` debt no longer re-signs a byte-identical roster every
      trickle; the standing charter is re-GOSSIPED (a separate call, still pays the debt), so the era
       FREEZES. Fixes the observed +1 era / ~10s climb.
  - `Swarm_family_heal` member loop (~4985): bare is now a CLAIM-ONCE seat. `wish` = kept-address, else
     bare for a founding Captain, else next suffix; `collide = seat && seen.has(wish)` re-suffixes ANY
      dup (bare or suffix) uniformly. Role never forces a SECOND bare beside the seat's own — kills the
       single-tab `Cave:bare;Captain:bare` charter.
  - `Swarm_adopt_finalise` (~5475): a second body is always suffixed regardless of Post (the inviter
     already holds bare) — the same dual-bare seed removed from the legacy adopt path.
  - **Verified no-regression on the LIVE e747 runner** (not headless): SwarmBody 17/17 `ok:true`
     (beat 8 = `family_heal`, beat 9 = replicate), SwarmCharter 4/4 `ok:true`, SwarmGossip 4/4
      `ok:true` — all `ok_pct:1` in check mode = zero fixture drift. SwarmSpread declared 5 / sworn 5 /
       gaps 0 (its `ok_pct:0.8` is the pre-existing §above stale-fixture drift, unchanged by this pass).
  - **NOT yet verified against the live eed two-tab symptom** — the Books use explicit eras / single-seat
     rosters, so they cover the machinery but not the cross-tab race. Phase 1 should stop the era climb
      on any tab running it, and stop single-tab dual-bare; the CROSS-tab dual-bare (two tabs each
       taking bare for their own `mine` row) is phase 2/3.

**✅ PHASE 2 LANDED + VERIFIED IN-PROCESS (2026-09-01, working tree, uncommitted).** The originally-
 planned "roster-first seat pick" resolved to something simpler and more robust: a **deterministic
  pub-sort seat assignment** in `Swarm_family_heal` (~4962, replacing the whole myaddr + member-loop
   block). Every body computes the SAME address map from its shared derived family — **bare goes to the
    LOWEST body_pub; the rest suffix `_1.._k` in pub order** — so two same-soul founders write a
     BYTE-IDENTICAL charter and phase-1's identical-payload guard freezes it instantly (no absorb race;
      equal-era cross-absorb, which never reconciled the old dual-bare, is now moot because there is
       nothing to reconcile). Kept/volatile addresses are no longer consulted (they diverge per tab —
        that WAS the bug); body-key order is the one truth both tabs share.
  - **Root cause proven, then fixed, in a throwaway in-process harness** (`scripts/TwoFounder.spec.ts` —
     mounts the real `gen/S/Swarm.go`, stands two identities of one soul with distinct body keys, runs
      `family_heal` + charter cross-absorb over 4 rounds; NOT a Book, no fixture). BEFORE (phase-1 only):
       `A→{A:bare,B:_1}` vs `B→{B:bare,A:_1}`, `IDENTICAL payloads=false` forever (era frozen at 1 but a
        permanent cross-tab dual-bare — equal era so neither absorbs the other). AFTER (phase 2): both
         write `{9557…:bare, ca7b…:_1}` (lowest pub = bare), `IDENTICAL payloads=true` from round 1, era
          frozen. Converged.
  - **No-regression on the LIVE e747 runner:** SwarmBody 17/17 `ok:true` + declared 19 / sworn 19 / gaps 0
     (beat 8 = `family_heal` — hana stays bare because a hex pub sorts below Kavi's `k…`, so the fixture is
      unchanged; `ok_pct:1` = zero drift), SwarmCharter 4/4, SwarmGossip 4/4 (3/3 sworn), SwarmChain 5/5
       (8/8 sworn), SwarmFerry ok. SwarmSpread 5/5 sworn (its `ok_pct:0.8` is the known stale fixture).
  - **NOT yet verified against the live eed tabs** — that needs a reload (below). The in-process harness
     is faithful to the charter mechanics but not to the relay/station layer (phase 3).

**OPEN DECISION FOR THE OWNER (phase 2 is role-BLIND).** Pub-sort makes WHICH body holds bare
 deterministic but arbitrary — it does NOT honour the teleology's "**the Cave holds the Seat**." Today
  that's fine (beat 8's founder-Captain lands at bare by luck of hex<`k`, and the eed tabs just need to
   AGREE), but if you want Cave-at-bare it's a one-line sort-key tweak (weight Cave ahead of pub). Say
    which: pure pub-sort (shipped), or Cave-first-then-pub.

**⛔ PHASE 3 — relay hello-v3 (`body_pub`) — HELD for the owner.** Phases 1+2 fix the CHARTER (era climb +
 dual-bare — the reported symptom). They do NOT fix the RELAY-binding half: two `?I=eed` tabs both dial
  `?addr=<bare>`, so `to:<bare>` delivery is ambiguous and `--player=eed` times out. That is spine surgery
   in `relay.ts` (stamp a `body_pub` on the socket; `heldByAnother` treats a same-body holder as self so a
    reconnect reclaims ITS seat; delivery prefers the `seats` holder) and it intersects the parked
     address-model question in `ClusterAddressing_todo` §4/§6 — so it's held for a decision, not landed blind.

**LIVE-VERIFY PHASES 1+2 (owner action).** Reload BOTH eed tabs onto the new `.go` (HMR caches the old
 one). The charter should converge to a SINGLE bare with a FROZEN era. To READ it, close one eed tab so
  `--player=eed` un-jams (or wait for phase 3), then minisnap `self>Peering>Charter` + `self>Peering>Body`.

**Already in the working tree, uncommitted (2026-09-01):** the Peeroleum same-soul pier-less dispatch
 (sibling frames no longer DROP — the charter-gossip/ack path phase 4 needs), the `_1` collision heal
  (correct but holed by #1 above), the removed relay-arbiter false-theft note, and the
   player-tab introspection reach (minisnap). All compiled + strict-parsed; the Peeroleum fix is NOT
    yet live-verified (needs the tabs stable through a roster convergence).

The device-link ("spread myself out") ceremony runs on a **handshake + ferry**, which SUPERSEDES the old
 `Swarm_adopt_*` seal-first model (that inverted the roles and never crossed — `Swarm_deliver` has no `%Pier`
  to route the seal over until a handshake forms one). The order:
  1. **SOUL device** presses "🔗 link a device" (in the Door) → `Swarm_ferry_link` mints an `%Invite:MyCave`.
  2. **NEW device** opens the `?Iz=` link → the ordinary invite path (`Swarm_redeem`) forms the `%Pier` both
      ways + cross-signs `%Grant:MyCave` (SwarmRole-proven).
  3. The soul's `Swarm_ferry_on_seal` fires when that pier seals → `Swarm_ferry_send` exports+seals+delivers
      the whole account over the now-live pier. New device `Swarm_ferry_park`s it; `Swarm_ferry_consume`
       unseals + imports → it holds the soul key, keeps its old key as body key, derives Post=Cave.

**⚠ THE `#fc` DECISION (owner, 2026-08-28) — it's redundant, remove it.** The seal today rides a random secret
 in the URL FRAGMENT (`#fc=…`, "hidden from the relay"). But the **adopt** ceremony beside it already sealed
  correctly with `ikm = offer.nonce` (a nonce that rides the offer frame over the relay) — the codebase already
   *trusts the relay*, which is the owner's stance ("we've got nothing to hide from the relay… eed is the
    security control point"). The ferry reinvented a more paranoid, worse version and made the human carry a
     fragment. **The fix: seal with the invite/redeem nonce like `Swarm_adopt_redeem`; drop `#fc`, the URL
      fragment, and the durable-secret twin; link goes back to plain `?Iz=<invite>`.** The big attended
       refactor (crown-jewel seal + re-record SwarmSpread beat 5) — do it carefully, not blind.

**LANDED 2026-08-28 — GRANTOR CONSENT LIVES ON THE PIER (owner: *"when the Pier turns up we should be pulled
 out of the QRcode openness over to where we're seeing that Pier having that Adopt with us, to confirm it"* +
  *"the one place that state goes"*).** The ferry no longer auto-fires on seal. Now:
  - `Swarm_ferry_on_seal` — on a **humdinger** (live end-user) tab, PARKS `top.c.ferry_confirm = {pub,name,at}`
     keyed to the just-sealed Cave pier and sends **nothing**. A runner tab (no humdinger, every Book) sends
      straight through as before — so `SwarmSpread` beat 5 dige is **unchanged (`ac0f77d14fc3ab55`)**, no churn.
  - `Swarm_ferry_confirm(w)` — the grantor's "✓ send my account", pressed ON the pier; does the one held send.
     `Swarm_ferry_cancel` also clears `ferry_confirm`.
  - **THE LINK CELL is the single home (revised 2026-08-28 — owner: *"it's a huge deal copying your account…
     should be on its own in the Link cell. both should be"*).** LinkDevice is a phase machine: Lobby → QR-
      sharing → **Linking** (RECEIVER consent on `ferry_pending` / GRANTOR confirm on `ferry_confirm`, each ALONE
       in the cell, both showing the 🎰 SAS) → Linked. Both ends are dragged here by the existing auto-surface
        (`Swarm_link_active` → `Sounditron_commission`: `ferry_secret` soul-side, `ferry_pending` new-device-side),
         so no bespoke navigation. The earlier DoorFace `.df-adopt` block + the LinkFace pull-to-Door were REMOVED;
          Door keeps only a quiet 🔗 marker on Cave piers (so a device doesn't read as a stranger — the *"wtf it
           grants Music?"* confusion). Also removed: the relay/origin warning under the QR (*"lose that stuff"*).
  - **3-EMOJI SAS — LANDED (Swarm.go 320094c).** `Swarm_ferry_sas(w)` computes a 3-glyph row identically on
     both ends from the two pubs the ferry `salt` binds (`<soulpub>:<bodypub>`) — grantor off the confirm pier's
      Peering pub (the SAME source `Swarm_ferry_send` salts from), new device straight off the parked frame's
       salt.  Shown in DoorFace's `.df-adopt` block and LinkDevice's accept prompt ("🎰 match both screens").
        NO `#fc` entanglement (that earlier worry was wrong — the salt already carries both pubs) and no crypto
         touch; display-only, snap-inert (SwarmSpread step-5 dige still `ac0f77d14fc3ab55`).  Reuses
          `Emojiconfirm.ts` (`sas_transcript`/`sas_row`, count=3).  Owner: *"three icons like jackpot machines."*
  - **QA PASS + FIXES — LANDED (Swarm.go 321835c, 2026-08-28).** Three subagents reviewed (correctness /
     adversarial-security / UX). Security verdict: **safe to ship** — the humdinger consent gate is a genuine
      wire-unforgeable boundary (`.c`-only, stamped at House construction, enforced in the ghost not the UI),
       the SAS binds correctly (salt is GCM-authenticated, no matching-rows-while-compromised splice). Fixes:
    - **`Swarm_ferry_confirm` now holds `ferrying` across its send** — without it, a pump firing during the await
       re-ran `on_seal`, which re-PARKED a fresh `ferry_confirm` and stranded the soul side (dead "give my soul").
    - **`Swarm_link_active` now also true on `ferry_confirm`/`ferry_awaiting`** — a confirm-only state no longer
       folds the cell away.
    - **THE LINKEE DEAD-WINDOW is fixed (owner's exact gripe: *"the Incognito side in Door just has ✉ #17 MyCave
       redeeming, nothing like the eed side"*).** `Swarm_redeem` arms `top.c.ferry_awaiting` when it redeems a
        MyCave link (`t.to==='MyCave'`, `station_up`-gated so Books never see it → dige `ac0f77d14fc3ab55`
         unchanged); LinkDevice shows a "**connecting to X · waiting for it to confirm**" phase instead of a blank
          Radio. Cleared by `Swarm_ferry_park`/`_cancel`.
    - **UX polish:** symmetric copy (*giving your soul → in your name* / *receiving the soul → in its name*),
       name/empty guards on both titles, unified SAS tooltip, dismissable + distinct done screens (declined no
        longer echoes itself), and a **"🎰 safety code · checking…" placeholder that DISABLES the confirm button
         until the SAS renders** (security LOW + UX: you can't approve a key-copy before you can check the code).
  - **⚠ SAS ENTROPY — YOUR CALL (kept at 3).** Security flagged 3 glyphs = **18 bits, grindable** (~2^18); it
     recommends **6** (36 bits, "six icons vs three", trivial human cost). But 3 is your *"jackpot machines"*
      choice and the SAS is defense-in-depth (real confidentiality rides the out-of-band `#fc` + GCM, not the
       emojis) — so I **kept 3** and flag it. To bump: change the `3` in `Swarm_ferry_sas` (`sas_row(…, 3)`) to 6.
    - **Soul NAME on the consent screen (Swarm.go 322259c).** `Swarm_ferry_send` now rides the soul's public
       `friendly` alongside the sealed blob, so the Linkee's most consequential screen reads *"receiving the soul
        of **Steve**"* not a raw pub8 (`arriving_name()` → falls back to pub8 → "a device"). Display-only, not
         the authenticator (the sealed blob is); snap-inert (dige unchanged).
  - **INTEGRATION REVIEW + FINAL FIX (Swarm.go 322773c, 2026-08-29).** A 4th agent re-reviewed the WHOLE
     session changeset as an integrated whole (the boot-gate, friendly-name, missing-code, and dead-window
      landed after the earlier 3-agent QA). Verdict: **broadly sound, ready for the two-tab test.** One real
       small-window bug found + fixed: the **FERRY SEAM (`Swarm.g:2078`) lacked the `!ferrying` guard** the retry
        path has — a re-seal during `Swarm_ferry_confirm`'s send-await could re-park `ferry_confirm` and strand a
         dead "give my soul". Added `&& !top_seam.c.ferrying`; dige `ac0f77d14fc3ab55` unchanged (the guard is
          inert in Books — `ferrying` isn't set at seal time there). Two acceptable tradeoffs noted, NOT bugs:
           (i) a brief boot-diagnostic-room flash on the Linkee before the glass commissions (self-heals when
            the Link cell auto-focuses); (ii) `ferry_awaiting` is `.c`-only, so a Linkee that reloads mid-"connecting"
             loses that reassurance (the account still crosses — `ferry_park` keys off the pier, not the flag).
  - **LINKOR HUNG ON THE QR — reactive advance + QR polish (Swarm.go 324233c, 2026-08-29).** Live test: 495
     (Linkee) sat correctly at "connecting… waiting for it to confirm", but **eed (Linkor) hung on the QR "waiting
      for it to connect" — never advanced to "giving your soul"**. Landed: **`Swarm_ferry_poke(w)`** + a LinkDevice
       effect that calls it while the QR is up — it parks `ferry_confirm` from ANY live MyCave pier the instant one
        appears (tied to H.version reactivity, not just the frame pump), so the cell swaps QR→confirm the moment
         the Cave is ready (the owner's "just go to another screen when the Cave has turned up"). Only PARKS, never
          sends. Also: dropped the "link a device as your Cave" heading + the "waiting for it to connect" line
           (owner), and the QR box (`.ld-face-qr`) now centres + hides overflow so it never scrolls ("QRcode looks
            bad when it scrolls"). **⚠ CAVEAT (needs eed's console to confirm):** the poke only helps if eed's pier
             actually bears a **live MyCave grant**. If eed still hangs after reloading, the pier isn't SEALING with
              a MyCave grant on eed — a peering issue (cross-origin → different relays → never seals, or tangled
               state from 495233 having already adopted eed's soul earlier this session). Clean re-test: a FRESH
                incognito Linkee (not the already-adopted 495233), both tabs on the SAME origin; if it still hangs,
                 eed's 🦑 ferry console lines will show whether the seal fires.
  - Verified live: `SwarmSpread` **5/5** (step-5 dige `ac0f77d14fc3ab55`) + `SwarmStaple` **8/8** green on runner
     e747cbed (Swarm.go 324233c), LinkDevice/LinkFace/Butler transform 200.
  - **"I DROPPED THE ADOPT AGAIN" — the ?Iz nuke, root-caused + fixed .svelte-only (2026-08-29, no compile).**
     Symptom (recurring): a Linkee reload mid-adopt shortened `?Iz=eed…*MyCave*…#fc=` → `?I=495233…#fc=` (495's OWN
      blank prepub) and lost the ceremony. **Root cause:** on reload the auto-join effect re-fires, the single-use
       MyCave redeem returns null (already spent), and `InvitePanel.join()`'s `if (!claim) { strip_iz(); … }` nuked
        the `?Iz` unconditionally. (`Clustation_mint_named` had separately added the `?I=495233` when the newborn
         named itself — it keeps `?Iz`; strip_iz is what removed it.) **Fix — three guards in InvitePanel:** (1) the
          redeem-fail `strip_iz` is now gated `if (invite?.to !== 'MyCave')` — a MyCave landing keeps its token and
           shows "… the adopt is already under way — resuming"; (2) the parse-fail `strip_iz` skips any `*MyCave*`
            token; (3) the auto-join effect bails when `Swarm_link_active(null)` is already true (ferry_awaiting
             rehydrated), so a reload never re-redeems. The URL now survives to `finalize_url` (Swarm_ferry_consume),
              which is the ONLY place a MyCave `?Iz` is meant to clear. No .g touched → Swarm.go unchanged.
  - **PRESENCE INDICATOR AT BOTH ENDS (owner: *"an online indicator on the giving your soul to… it's important to
     know if they're there"* / *"offline indicator at both ends"*) — LANDED .svelte-only (2026-08-29).** Each Link
      phase now shows the OTHER device's liveness as a small pill — `● online` / `◐ fading` / `○ offline` — read
       from the relevant pier's `heard_at` (the same pulse warmth DoorFace grades: here <15s · fading <45s · else
        away), decayed against a 1s tick so "offline" appears live when the peer goes quiet. Reachable without a
         ghost change: `Swarm_pulse_all` pulses ALL sealed piers (not just `Grant:Music`), so a MyCave pier's
          `heard_at` stays warm, and the hear funnel stamps it on ANY sealed frame so an active handshake reads
           "online" immediately. `other_pier()` picks the MyCave pier (Linkor) or the soul-pub pier (Linkee, falling
            back to the sole ceremony pier). Also fixed the last asymmetry: the Linkee "receiving" SAS lost its
             `🎰 match both screens:` words → icons-only `<b>{sas}</b>` with a `···` placeholder, matching the
              already-clean Linkor "giving" screen (owner: *"just have the icons, no words"*, one modality).
  - **RELOAD STATE-HEAL — eed refreshing (or 495 refreshing) no longer loses eed's focus on the Adopt (Swarm.go
     329563c, 2026-08-29). Books green, beat-5 dige `ac0f77d14fc3ab55` UNCHANGED (SwarmSpread 5/5 · SwarmStaple 8/8).**
     Owner: *"eed refreshing loses its focus on answering the Adopt… even reloading 495 doesn't renew eed's focus on
      the Link. do we build this with req? they should be quite in sync during this, 0.5s ping… snappy state-healing."*
     **Why it broke:** `ferry_confirm` is `.c`-only, and every reload path only ever CLEARED ferry state, never
      re-DERIVED it — even though all the proof is durable: the `%Grant:MyCave` on the sealed pier (`Swarm_pier_live`
       is pure grant state, no `heard_at`, so it reads live the instant the snap thaws) and the `ferry_pending_secret`
        twin in `stashed`. The seal-seam gate also read `.c.ferry_secret` (gone after reload), so a 495 re-seal
         couldn't re-trigger eed either. **The heal (all durable-truth, no round-trip, all humdinger-gated → Book-inert):**
     - STALE FERRY SWEEP gained its INVERSE: a live Cave + surviving twin → rehydrate `.c.ferry_secret` from the twin
        AND (humdinger only) re-park `ferry_confirm` right at standup. eed reload lands back on "giving your soul".
     - Seal-seam gate now honours the twin (`seam_secret`), so a **495 reload/re-seal** re-fires `on_seal` → re-parks
        eed's confirm even if eed's own `.c` secret was lost.
     - `Swarm_ferry_poke` gained a `!ferrying` guard, and the LinkDevice poke effect now fires on `Swarm_link_active`
        (not just `url`) — the snappy reactive heal: the instant reactivity ticks after a reload, poke re-parks the
         confirm from the still-sealed pier. With the ~0.5s pier cadence this feels immediate.
  - **STEADY "I WANT LINKAGE" ASK — the Linkee now DRIVES the Linkor's focus (Swarm.go 335503c, 2026-08-29). Books
     green, beat-5 dige `ac0f77d14fc3ab55` UNCHANGED.** Owner's reframe, which is the correct model: *"we need a steady
      flow of 'I want Linkage' sentiment from 495 to eed to keep it focused on serving the request. eed can only get
       rid of that by cancelling the token, which 495 then gives up from… right? because right now eed is not at the
        party."* The reload-heal (above) made eed re-derive from ITS OWN durable state — but that only helps when eed
         reloads; a **495 reload didn't re-seal**, so eed never got re-triggered. **The fix flips the driver:** the
          ceremony is held open by the Linkee's standing DEMAND, not by either end remembering a one-shot seal.
     - `Swarm_ferry_ask` (new): while `ferry_awaiting`, the Linkee sends a tiny sealed `ferry_want` to the soul device.
        Driven by a **3s ceremony-scoped tick in LinkDevice** (owner: *"3s wire chatter for the Link ceremony"*), with
         the ~5s presence pulse as a fallback; a shared `ferry_ask_at` throttle (~2.8s) means the two never double up.
     - `ferry_want` handler (Linkor): the far mirror of the seal-seam — a sealed pier bearing MY MyCave grant, while I
        hold the secret (`.c` or twin) and am not mid-send, re-fires `Swarm_ferry_on_seal` → re-parks the confirm. So
         eed leaps back to "giving your soul" within ~3s of a 495 reload, with NO eed reload and NO durable eed memory.
     - **No giveup** (owner: *"if we lose the other end we probably just sit waiting"*): the ask repeats forever; eed's
        parked confirm persists with the ● dot showing 495 offline, and it re-lands the instant 495 returns.
     - **Teardown** (owner: *"eed cancelling the token, which 495 then gives up from"*): `Swarm_ferry_cancel` now fires a
        best-effort `ferry_cancel` to the Cave (humdinger-gated → Book-inert); `Swarm_ferry_cancelled` clears the
         Linkee's `ferry_awaiting`+twin (matched on `from`), so its cell closes back to Radio. (A "link cancelled" toast
          is a nice follow-up, left out to avoid keeping a dead cell alive to host it.)
     - **Book-inert by construction:** the emitter rides the Book-muted pulse + a cell never mounted in a Book; both
        handlers only fire on frames never emitted in a Book; the cancel-send is humdinger-gated. Verified: dige held.
     - Also fixed the doubled "connecting" (LinkFace title + LinkDevice cap): the Linkee cap now reads "receiving from X".
  - **TWO FOLLOW-ON BUGS behind "eed is not pulled into any Link session" (Swarm.go 336664c, 2026-08-29). Books green,
     beat-5 dige `ac0f77d14fc3ab55` unchanged.**
     1. **The ask sent nothing** — the 3s LinkDevice tick called `Swarm_ferry_ask(world())` with NO ident, so it hit
        `if (!ident) return 0` and 495 silently asked for nothing (the ~5s pulse, the only other caller, doesn't run
         while the Link cell is up). Fixed: `Swarm_ferry_ask` self-resolves via `Swarm_live_self` and the call site
          passes `self`. Added console diagnostics both ends (`🦑 "I want linkage" → N` / `heard "I want linkage" …
           cave_pier= my_secret= ferrying=`) so a live console pinpoints any break — leave them until confirmed.
     2. **The token got nuked at boot** — the STALE FERRY SWEEP deleted eed's `ferry_secret` whenever no MyCave pier
        read live *at standup*, but the peering is usually not thawed that early, so the read went transiently false
         and killed a LIVE ceremony's secret; eed then read `my_secret=no` forever and could never be re-pulled. Fixed
          by making the token STICKY — retired only by explicit `Swarm_ferry_cancel` or a successful send, never by a
           boot-time "no pier right now". This is the owner's own contract (*"eed can only get rid of that by
            cancelling the token"*). Cost accepted: a never-scanned QR lingers as a cancellable "link in flight" cell;
             a delayed dead-QR sweep (decided well after piers thaw) is a possible future nicety, NOT re-added at standup.
  - **BUG #3 — THE DECISIVE ONE: clock-unit throttle silenced the ask after ONE fire (Swarm.go 336960c, adversarial
     review agent, 2026-08-29). Books green, dige `ac0f77d14fc3ab55`.** `Swarm_ferry_ask`'s throttle did
      `Swarm_now(w) - ferry_ask_at < 2800`, but `Swarm_now` is **seconds** on a live tab (`Math.floor(Date.now()/1000)`),
       so a ~3-second gap compared to 2800 was ALWAYS true → every ask after the first was suppressed for ~2800s
        (~47min), and `ferry_ask_at` is never cleared. So even with #1 (ident) and #2 (sticky token) fixed, 495 asked
         exactly ONCE and went quiet — a Linkor that reloaded after that lone ask was never re-asked. Fixed: throttle
          on wall-clock `Date.now()` ms. (Three bugs stacked behind one symptom; the review found #3 the same run it
           cleared the rest of the chain — voucher gate, theft guard, stash durability, Sounditron latches all sound.)
  - **"MORE WANTS-TO-HAPPENY" (owner) — the link now LEAPS instead of idling (2026-08-29).** `Swarm_ferry_ask` gained a
     `force` arg that BYPASSES the throttle; LinkDevice fires a forced ask (a) the instant the Link cell mounts and
      (b) the moment the other device flips to `● online` (a presence-`rung`→'here' edge watcher) — so the ceremony
       jumps to "giving your soul" as soon as both ends are present, rather than waiting out the 3s cadence. It still
        idles at a calm 3s between beats. Eager first-contact + eager re-lock, quiet steady state.
  - **⇒ RE THE REQ QUESTION (owner: *"do we build this with req?"*).** YES — and this heal is precisely the behaviour a
     `req:Ferry` gives you declaratively. What I did by hand (re-derive `ferry_confirm` from durable truth every
      standup + every reactive tick, self-clearing once the send lands) is a req's `do()` pass re-arming its `ok` off a
       standing condition. The honest status: I did the **targeted heal now** because it's low-risk and Book-verifiable
        in one pass; the **full `req:Ferry` refactor is still the clean destination** and is owed a deliberate pass (it
         touches the req machine — Coding_guide first). Sketch of the rungs, so the heal reads as a stepping stone not a
          detour: `req:FerryLink` (eternal, Linkor: holds while `ferry_pending_secret` lives, re-arms `ferry_confirm`
           from any live MyCave pier, retires when the send lands) · `req:FerryAwait` (eternal, Linkee: holds while
            `ferry_awaiting`/`ferry_pending`, retires on consume) · `req:FerryAck` (the owed receive-ack below, a natural
             rung: Linkee emits on consume, Linkor's req retires "✓ they became you"). Each rung's re-arm REPLACES a
              hand-rolled sweep/poke/rehydrate — same law, one place. Tracked as its own task.
  - **STILL OWED (feedback gap): no ACK back to the Linkor when the Linkee CONSUMES the soul.** eed sees "✓ soul
     given" the instant its send returns, but nothing tells it 495 actually *received & became it*. The presence dot
      mitigates ("are they even there") but a real receive-ack (a tiny frame 495→eed on consume, flipping eed's cell
       to "✓ they received your soul") is the honest close of the handshake. Needs a ghost frame → deferred to a
        compile+Book pass, not slipped in unverified. Fold into the `req:Ferry` rework (below) — an ack is a natural
         req rung.
  - **LINKEE BOOT-GATE — half-fixed 2026-08-28 (the "stuck at press start" on a fresh device).** A new device
     opening a `?Iz=<MyCave>#fc=` link does NOT go straight to the ceremony: the boot treats a device-link exactly
      like a friend-invite. `Butler.svelte`'s `landing` (line ~268) is derived purely from `boot_param('Iz')` —
       no MyCave/Music split — so the arrival FaceSucker holds its friend-join "door" over the ceremony, AND
        nothing made it step aside once the ferry was in flight → the Link cell was trapped behind the Butler.
    - **FIXED (safe half):** the Butler now stands aside on `Swarm_link_active` (Butler.svelte:373-ish). This
       goes true only AFTER the redeem arms `ferry_awaiting`, so it reveals the ceremony without disturbing
        naming. Fully gated to device-link tabs (an ordinary boot never fires it). `.svelte`-only, transforms 200.
    - **STILL OWED (attended — needs the live two-tab test + care):** the friend-join FRAMING. The name-ask on
       that door is **load-bearing** — InvitePanel's auto-join (line ~447) is gated on `named`, so a newborn
        Linkee must name itself before `Swarm_redeem` fires. So you can't just hide the friend-door for MyCave
         (that removes the name-ask → no redeem → wedge). The real fix: make the landing card MyCave-aware —
          frame it as *"name this device · you're receiving a soul"* not *"join X as a friend"*, still collect
           the name, then hand off to the Link cell. Touches Butler/InvitePanel/naming → verify live, not blind.
  - **⇒ THE FERRY WANTS TO BE A REQ (owner, 2026-08-29: *"are you using req enough? it was most perfect in
     LiesStore… see Hovercraft"*).** The ceremony has grown into ad-hoc `.c` flags (`ferry_secret`/`ferry_confirm`/
      `ferry_awaiting`/`ferry_pending`/`ferrying`) + a UI **poke** + a pump **retry** (Swarm.g ~1108) + a standup
       **sweep** — a hand-rolled reinvention of exactly what a **req-stack** gives for free (`Hovercraft.svelte`;
        `LiesCortex` is the model: `req:Store maz:7 → req:Cortex maz:5 → req:Codebit maz:2 → req:Rundown maz:1`,
         maz-ordered, `do()` pumps highest-maz first, a **ttlilt** holds the phase open, an un-`ok` un-finishes).
          Map: a `req:Ferry` whose maz phases are mint→seal→confirm→send (Linkor) / redeem→await→receive→consume
           (Linkee); the **retry + poke collapse into the req's `do()` pump**, the **sweep into un-finish on a lost
            pier**, the flags into the req's `sc`, and a **ttlilt keeps the ceremony from being abandoned** (like
             LiesCortex's `%ttlilt,waiting:run`). A DELIBERATE refactor — NOT mid-live-test; do it once the current
              flow is proven end-to-end on the live tabs, then delete the scaffolding.  See `Pier_todo` for the
               adjacent pier-kind cleanup.
  - **STILL OWED on this:** (b) a **`ferry_ok` ack** so the grantor's pier graduates "sent"→"adopted & confirmed"
     (today it can only know "sent" — secret cleared; entangled with the identity-transition, deferred); (c)
      **live two-tab proof** that the pull + confirm + SAS-match actually crosses the account (needs a fresh
       blank device — the human's gate).  See `Trust_todo.md` — payments on Trust beneath the protocols.

**The Cell:** `%Link` (`LinkFace`, in `glass_kinds.ts`, minted in `Sounditron_commission`) is **REACHED, not
 resident** — pressing "🔗 link a device" in the Door calls `Sounditron_focus('Link')` (a new world-resolved
  nav verb for faces), the cell takes the belly, and Door|Radio abandon it. Grappled only while focused or a
   link is in flight (`Swarm_link_active`); auto-surfaces once on the RECEIVING side (`w.c.link_surfaced` latch).

**Landed this session (all compiled + parse-gated + Books green — RaBreach/PortPlant/SwarmSpread):**
  - **Live blocker fixed:** a device-link Cave pier no longer arms the "a friend came online" expectation
     (`Swarm_expect_friends` filters to `Grant:'Music'` friend piers). A Cave is your own device, not a friend
      — it was reporting `nobody has come online` forever ("eed sees Grauc, Grauc says FAILED").
  - **Unstick + escape:** `Swarm_ferry_cancel` (the Link cell's cancel button) + a **stale-ferry sweep** at
     `Swarm_station_up` (clears a secret with no live MyCave pier) — so a wedged "ferrying now…" self-heals on
      reload. NB the auto-surface means a wedged soul boots INTO the Link cell, so the sweep matters.
  - **Onboarding:** the fullscreen "music here is shared with friends" beg-screen is GONE for a new/peerless
     tab (`Butler.svelte` — `friendless` no longer opens the door stage; `landing`/`Adopt`/`relic` still do).
      Instead a **peerless invite button** sits under the ♪ LOCAL sayer in `RadioFace` (shows on counted-zero
       `door_friends`), pressing it → the Door cell where the QR lives.

**Proven:** `SwarmSpread` **5/5** (beat 5 = the ferry glue, `step=5,dige:ac0f77d14fc3ab55`, «the-account-
 ferries-over»). Debug tool: `scripts/runner_watch.mjs` (remote run + named "pointer" predicates, exit-coded).

**✔ SwarmSpread is FUNCTIONALLY GREEN — the red is a STALE FIXTURE, not a bug (diagnosed 2026-08-31).**
 First read as a regression, but `runner_ask assertions` is decisive: **declared 5, sworn 5, gaps 0** — every
  `%see` swears, including #5 «the-account-ferries-over» *sworn at step 5*. `snap 5` confirms the behaviour:
   Ebox (right code) forms a `Body role:Cave` holding the soul; Fbox (wrong code) forms NO Body. The account
    ferries across correctly and fails closed on a wrong code. **The `ok:false, ok_pct:0.8` is a SNAP-FIXTURE
     DRIFT** — the live beat-5 (and beat-1) diges differ from the recorded `toc.snap`, so the STEP reads not-ok
      while the ASSERTIONS all pass. The `Sealbox unseal() OperationError, ikm="wrong_ferry_code"` in devtools
       is the EXPECTED, CAUGHT wrong-code fail-closed test (`Swarm.go:4874` swallows it, "no account landed");
        Chrome logs WebCrypto rejections even when caught — noise, not an escape. NOT the arrival work (humdinger-
         gated, ferry code untouched). **Cause of the drift:** an earlier snap-shape change (committed Ferry
          commits, or the loaded uncommitted `Heist.g`/`Radio.g`) moved what beat 5/1 snap. **Fix:** `runner_ask
           accept` to re-record (behaviour is correct), then keep only `NNN.snap` + `toc.snap` step,dige and
            revert Credulate/Credulation churn — but eyeball the diff first, since the drift cause is worth a
             glance. Owner's call whether to re-record now.

**NEXT MOVES (owed):**
  - **THE `#fc`→nonce refactor** (above) — the headline. Attended, with a Book re-record.
  - **Adoptee identity transition — LANDED, needs live proof.** `Swarm_ferry_consume` funnels the landed soul
     through `Clustation_concrete` (Auto.svelte, the single mint|adopt chokepoint) so the soul becomes the sole
      ACTIVE `%Identity` and the blank husk deactivates. Only full proof is the **live two-tab test** — confirm
       after "accept" the device presents AS the soul (eed), not its blank incognito self. Then DROP the husk
        `%Identity` once nothing (census/vessel/address bind) references it.
  - **The live gate:** a real **two-device test on ONE shared origin** (mint on the soul, open on the blank
     device). Note: `djamsend.duckdns.org:9999` is a REMOTE node running OLD code (unreachable from the
      container) — test on LOCAL `:9091` where this session's code actually runs, or deploy first.

---

## THE FIELD IN ONE BREATH

A **soul** is a keypair. It runs in one-or-more **bodies**, each on a machine, each holding the soul key
 and its own durable **body key**. An undivided soul is one body at the bare `<prepub>`, with no role.
  The **Division ceremony** (`%Invite:MyCave`, LinkDevice) confers a **Post** (Captain, Cave, …) on each
   body — the Post *is* a cross-signed grant, not a self-chosen tag. One body holds the bare name and
    anchors everything: the **Seat** (whoever is most reliably online — usually the always-on daemon). The
     Seat derives a soul-signed, era-stamped **Charter** — `{body-pub, post, address}[]` — from its
      current grants; the Charter is how any body OR any friend learns and *trusts* which body plays which
       Post. Routing is **resolve-and-emit**: read the address for a Post off the Charter, emit, let the
        transport fail forward — no liveness cache. Authority to *issue invites* is a separate thing, the
         **Captain**, which never auto-inherits. That is the whole machine.

---

## THE ATOMS

- **Soul** — one ed25519 keypair (`%Identity.c.keys`, Tier A, never encoded). The unit of identity and of
   every friend-facing grant. Replicated whole to each body at LinkDevice; never changes.
- **Body** — one soul's presence on one machine: the pair `(store × soul)`, NOT the machine itself. Holds
   the soul key, its own durable **body key**, a current **address**, and — once divided — a **Post**. A
    store serving two souls holds two Bodies, one per soul.
- **Body key** — a body's own durable keypair, minted when a soul first stands up in a store and persisted
   body-locally (the machine's Dexie, NEVER replicated). It is (a) the stable per-body identity that keys
    the Charter roster and lets a body find its own row, and (b) what the LinkDevice ceremony encrypts the
     account TO. *(Built — `Swarm_body_key`/`_ensure`, persisted via `vessel_store.ts`.)*
- **Vessel** — one running instance on a machine (a tab, the daemon process). Vessels of one store share
   Dexie but may differ in anything else — which soul they serve, which FSA mount they hold. Every vessel
    registers in the shared **Vessel table** (a Dexie table beside Housing's `db.House`, per store):
     `{vessel, root_prepub, address, fsa, alive}`. Queried by a root prepub it yields that individual's
      local **subnet** — the vessels serving that soul here, now. No crypto among vessels: same-store trust
       is the Web-Lock and the table.
- **Address** — `<prepub>` (bare) or `<prepub>_N` (suffixed), won via hello-v2 / Web-Lock. Mutable,
   body-local, non-replicating (already stripped from export), mostly stable across sessions (a body
    re-requests its prior suffix on bind). The root prepub is the individual's subnet: every vessel serving
     that soul addresses inside it, and the bare address is the Seat.
- **Post** — a body's role in the division: Captain, Cave, … General role NAMES that recur across
   paradigms; a paradigm binds only what a Post *does*. A body's Post IS the `%Grant:MyCave` (or
    `:MyCaptain`, …) its Seat cross-signed for it — crypto, revocable via `%NotGrant`. An undivided soul
     has no Post; dividing is exactly the act that confers them.

## THE TWO AXES

- **Vesselling** — per machine, cross-soul. A store partitions into running Vessels via the Vessel table.
   Vessels on the SAME root prepub are that soul's local subnet: they share the soul's Body (its body key,
    Post, grants), differ only by address suffix, and elect a **tab-primary** per soul via Web-Lock.
     Vessels on DIFFERENT prepubs coexist in one store — each soul's group is its own subnet, its own Body.
- **Division** — per soul, cross-machine. One soul's Bodies on different machines, joined by the LinkDevice
   ceremony and split by Post. Shares only the soul key; each Body keeps its own body key, address, and
    Post. This is the subject of the doc.

The axes are orthogonal: the Vessel table slices a MACHINE by soul; the Division slices a SOUL by machine.
 A Body is the cell where they cross.

## THE TWO AUTHORITIES (orthogonal — this is the crux)

- **the Seat** — the body at the bare `<prepub>`: routing anchor + roster-writer + Charter-signer. It is
   whoever is MOST RELIABLY ONLINE (the bare name is won via hello-v2), so in the standard phone +
    always-on-daemon deployment the daemon-Cave is the Seat, not the phone. That the Seat is the always-on
     body is a feature: the Charter-refresh anchor is reliably up. Exactly one Seat at a time.
- **the Captain** — the INVITE HELM: the sole writer of the Tier-C invite ledger (Portability §9). A Post,
   usually the phone, usually suffixed, usually asleep — invites happen when the human is on the phone.

Seat = *coordination* (who anchors the bare name). Captain = *authority* (who issues invites). They
 coincide only on a phone-only soul with no daemon. This orthogonality gives the right failure mode: a
  dead phone loses the Captain (invite-issuance freezes; the human re-mints one via `%Invite:MyCaptain`)
   WITHOUT losing the Seat (the daemon keeps routing + serving alive).

## THE POST'S TRUTH CHAIN (one truth, everything else a cache)

1. **Truth = the grant.** A Post IS the `%Grant:MyCave` the Seat cross-signed at the ceremony. Per-body,
    internal (friends never see it), revocable via `%NotGrant`. Not a string a body picks.
2. **Attestation = the Charter.** The Seat derives, from its current un-revoked grants, a roster
    `{body-pub, post, address}[]`, **signs it with the soul key**, and **stamps its era**. A friend (or
     any body) verifies the Charter against the soul pub; a spoofed "I am Alice's Cave" fails the signature;
      a split-brain can't flap because peers keep the highest-era Charter.
3. **Cache = the `%Body` roster** under `%Peering`, keyed by **body-pub**. Replicates (all a soul's bodies
    must agree who is Captain and who is Cave — keyed by whose-body-it-is, it can't confuse).

**Everyone routes via the Charter** — self-bodies and friends alike — so there is ONE routing path, no
 self-vs-friend fork. Raw grants only BUILD the Charter; nobody routes off them.

## STORAGE & REPLICATION (what crosses the wire, what stays home)

- **Replicates (shared soul-truth, must agree):** the soul key (Tier A, once); the `%Body` roster + the
   Charter (Tier B / signed snapshot); friendships, grants, the pool ledger (Tier B, grow-only union); the
    invite ledger (Tier C, Captain-write-only, replicated read-only to Caves).
- **NEVER replicates (body-local, computed — the existing `Swarm_protocol` strip):** which row is ME
   (computed by body-key match, never a stored flag); my current address; presence; the Vessel table (it
    IS the machine's runtime census); the stolen flag; per-body wire state (seq/era/voucher).

## ROUTING — resolve-and-emit, no liveness cache

find-body-by-role is TWO questions, kept apart:
- **RESOLUTION** — Post → body-pub → address, off the Charter. Pure, stateless, cannot lie.
- **REACHABILITY** — is that address answering? The transport's ground truth (`Swarm_deliver`'s boolean;
   the outbox ack/dead ledger). You discover it by SENDING, never by caching a verdict.

```
Musu_serve_ask(w, ident, pier, frame):
    if (!this.Swarm_pier_live(pier, 'Music')) return false   // grant gate — per-soul, checked at use
    let to = this.Charter_addr(pier, 'Cave') || pier.sc.prepub   // Cave address from the Charter; else the Seat
    return this.Swarm_deliver(w, ident, to, frame)           // EMIT; false = fail-forward, re-ask heals
```

Two hard transport facts the routing must honour:
- **The relay does EXACT-address routing, no fan-out** (`relay.ts:120,229` — `locals:Map<addr,sockets>`).
   A bare frame reaches only the Seat; reaching a Cave REQUIRES its Charter address. This is why the Charter
    is load-bearing, and why the always-on Seat is both the fallback anchor and the Charter-refresh source.
- **A friend holds one `%Pier` PER BODY** (per address — seq/era/voucher are per-body and never converge,
   Portability §7). The Charter tells the friend the Post→address map so it annotates each per-body pier
    with its Post; `Swarm_pier_body(soul, 'Cave')` = "my pier to this soul whose Post is Cave."

The one thing emit can't give a synchronous UI ("is Alice's Cave up, right now, before I act") is a
 DERIVED, non-persisted read — `Musu_serve_note(soul) → 'live'|'offline'|'unknown'` folding `Presence_here`
  + `Swarm_pier_live` at the read — not a particle.

## THE WELD — the Charter in the core language

The resolution layer already speaks C: `%Body` is a true particle (mainkey `Body`, identity `{Body,pub}`,
 oai-idempotent, scalar sc, `.c.up` backlink, bump()-driven watchers), and pure queries (`Swarm_body_for`)
  are the right shape for pure resolution — the o()/oai() register. The owed process layer (sign, gossip,
   absorb) is async work, and async work in this application speaks Hovercraft:

- **The Charter is a signed dige of the division.** Era = the version idiom (a counter bumped on change);
   the payload = a canonical scalar serialisation; re-charter = a watcher noticing the grants' digest
    moved. This is Story's own snap shape — a serialisation of state at a version, re-emitted when the dige
     changes — signed. Not a new concept in this app; its oldest one, given a signature.
- **ONE stable `%Charter` row, merged in place.** `{Charter:1}` under `%Peering`, sc: `era`, `sig`,
   `payload` (one scalar). oai + merge like `reset_interval`'s `%mo:main,interval` — NEVER replace()-churned
    (replace empties the container across two awaits: the Vytui childless-window class) and never
     one-row-per-era (goner+new snap churn).
- **The async sign/verify rides `expecting()`.** Key ops are async; a bare async fn lets a Story snap tear
   mid-sign. `expecting(w, 'charter_sign', secs, fn)` holds the snap coherent via ttlilt — resolve is
    causal, timeout is the bounded escape. Same on the receiving side's verify-then-absorb.
- **Friend-side `%Body` rows are minted ONLY by Charter-absorb** (verify → project), never by raw roster
   gossip. Routing off `%Body` rows then IS routing off the Charter, one hop removed — the cache-discipline
    rule becomes structural, not conventional. `Swarm_roster_of/onto` survive as the Charter's payload
     codec + projection, not as a parallel unsigned channel.
- **Cross-ghost = elvisto / vaguely_ponder.** The serve binding asks Swarm via the deferred call, so a
   context without Swarm stood up gives up cleanly instead of throwing.

## LIFECYCLE

- **Birth** — one body, at the bare name, no Post, no Charter. Routing = dial the bare name (it's the one
   body). Division machinery is entirely OFF.
- **First division** — the CEREMONY (see below): a blank device offers itself, the soul-holder scans and
   seals its account across, both consent, Posts are conferred (original → Captain, new → Cave), the
    more-online body takes the Seat, and the Seat writes Charter #1.
- **Post change / revoke** — the Seat mints a `%NotGrant` (existing machinery) and re-charters at a higher
   era; the new Charter gossips out. Change = revoke + re-issue.
- **Seat succession** — automatic: the bare name frees on the old Seat's relay-heartbeat lapse (~30s), the
   next-most-online body wins it via hello-v2 and re-charters. No election beyond the relay arbiter.
- **Captain succession** — NEVER automatic: the human re-mints via `%Invite:MyCaptain` (the most dangerous
   token — grants who-you-are, not what-you-serve). Invite-issuance stays frozen until then; nothing else
    is affected.
- **Eviction — replacement, NOT a timer.** A Post-holder leaves the Charter only when it is REPLACED: a new
   holder of that Post is `%NotGrant` + re-issue (the mechanism above), and the re-charter simply omits the
    old one. Whether a new holder evicts the incumbent is the Seat's call, defaulting by whether the Post is
     SINGULAR — a new **Captain** evicts the old (one invite-ledger writer, always); a new **Cave** COEXISTS
      (multi-Cave is permitted), evicted only on the admin's say-so. A body that dies and is NEVER replaced
       just lingers and fails-forward dark on each ask — harmless, because the Charter never asserted liveness
        (that is the `%Reach` cache we reverted): **liveness lives at the bare name**, where the Seat is alive
         by construction and every miss falls back to it. So there is NO dark-threshold timer and none is owed.

## FAILURE MODES (the honest table)

| Situation | Outcome |
|---|---|
| Seat asleep | Rare (it's the always-on body). Routing still works off the durable Charter; only re-chartering waits. |
| Captain (phone) dead | Invite-issuance freezes (safe); routing + serving + existing grants all continue. |
| Stale Charter + Cave moved address | Wedge until the Seat re-charters; bounded by address stability. The one real gap. |
| Split-brain (two Seats, a partition) | Peers keep the highest-era Charter; the loser's stale Charter is ignored. |
| Nobody plays the asked Post | `Charter_addr` → null → dial the Seat (bare); the transport declares `%dead` on exhaustion. |
| Multi-Cave | Permitted; the pick is deterministic (bare-first, address-asc); try-one-then-next on a miss (no broadcast). |

## THE CEREMONY — spread out by scanning (LinkDevice, the act of dividing)

Dividing rides the friend-invite rails **inverted**: the blank device shows the QR, the soul-holder scans.
The Door already IS this shape (InvitePanel mints an offer → InviteQR renders it → the OTHER device's native
 camera reads the `?…=` URL → live relay handshake); there is no in-app scanner and none is needed.

- **Offer — the Cave-to-be, a blank proto-identity.** A fresh device boots as *just a body key* — adopted by
   nobody, wearing **NO role** (it does not know it is a Cave). It shows a QR: an **adoption offer** (its
    body-key pub + nonce + presig), reusing the Idzeug compact codec. Role-agnostic by construction.
- **Scan — the soul-holder (the Captain-to-be).** The device that HAS the soul scans with its native camera.
   It DECIDES a role to propose (Cave, for an always-on box), **warns the human this is BODILY** — "this
    device will hold your keys and can serve your library AS you" — and on confirm SEALS its account to the
     scanned body-key pub (SwarmSeal, Phase 1) + mints `%Grant:MyCave` for it, delivering both over the relay.
- **Decide — the Cave consents.** The offered device RECEIVES the sealed account + the proposed grant and
   **decides**: the Cave doesn't know it's a Cave until now, and it must accept. On yes: it unseals (now holds
    the soul), derives its Post from the grant (`Swarm_body_repost` → Cave), and stands up as a body.
- **Seat + Charter.** The more-online body (usually the box) claims the bare name = the Seat; the Seat
   reposts both ends (original → Captain, new → Cave) and writes Charter #1, gossiped out.

**Consent is mutual and neither side is silent:** the soul-holder confirms the bodily *share*; the device
 confirms the *role*. A blank offer + a proposed role + a granted consent — never a self-declared Post.

**In the Door:** friend-invite stays the main act; a SMALLER **link a device** button opens the offer/scan.
 The device side shows a blank-body QR (never pre-labels a role); the phone side lands in its OWN colour with
  the bodily warning (NOT the friend colours) — a mis-scan must never quietly hand over your soul.

## VOCABULARY (glossary — rename freely, this is the coinage)

**Soul** · **Body** (`store × soul`, one Post) · **Body key** (durable per-body keypair + id) · **Vessel**
 (one running instance) · **the Vessel table** (the store's shared runtime census, grouped by root prepub =
  an individual's local subnet) · **Address** (bare / `_N`) · **Post** (role: Captain, Cave) ·
   **Vesselling** (per-machine, cross-soul partition) · **Division** (per-soul, cross-machine role-split) ·
    **the Seat** (bare-name anchor + Charter-signer) · **the Captain** (invite helm) · **the Charter**
     (soul-signed, era-stamped roster).

*Renamed along the way (old → current, for anyone holding an earlier draft): SelfType → Post ·
 vessel key → body key · Sibling / Facet → Vessel · DivisionMaster → the Seat.*

## BUILT vs OWED

**Built (model layer, additive, dormant — each RECORDED green on the live runner: real snaps + declared
 `%see` assertions, verified by inspecting the snaps not just the ok_pct; crypto proven standalone too):**
- **RESOLUTION register** — `%Body` roster + `Swarm_body_take/note/roster/pick/for/mine` + `Swarm_pier_body`
   + `Swarm_roster_of/onto`. Book **SwarmDivide** (Swarmation.g). `%Reach` was built then reverted (appendix).
- **1 · body key + Vessel table** — `Swarm_body_key`/`_ensure` (durable per-body keypair on `.c.bodykey`,
   Dexie-persisted via `src/lib/O/vessel_store.ts`, never replicated); `Swarm_body_mine` COMPUTES which row
    is me by body-key match (the stored `self:1` is GONE — a flag would replicate and lie); `Swarm_vessel_pick`
     + `Swarm_vessel_subnet` + the Vessel table (`{vessel, root_prepub, address, fsa, alive}`, registered at
      `Swarm_cohort_stand`). Book **SwarmBody**.
- **2 · the Charter** — `Swarm_charter_sign` (derive from the live `%Body` rows, sign with the soul key,
   stamp era, ONE `%Charter` row merged in place) + `_wire`/`_verify`/`_parse`/`_payload` + `Charter_addr`
    (resolve a Post→address, bare-first) + `Swarm_charter_absorb` (verify → land → project, highest-era wins).
     Book **SwarmCharter** + `scratchpad/charter_verify.ts` **16/16** (good verifies; moved-address / bumped-era
      / swapped-soul / wrong-pub rejected; supersede / stale / forged; multi-Cave pick).
- **3 · Post-from-grant** — `Swarm_post_from_feature` (My<Post> → Post) + `Swarm_grant_post` (the LIVE
   grant's Post, honouring `%NotGrant` as `Swarm_pier_live` does) + `Swarm_body_repost` (SET from a live grant,
    DROP under a revoke, body row stands). Book **SwarmPost** over SwarmRole's real redeem/revoke rails.
- **4 · Charter gossip** — a signed `charter` frame (`Swarm_charter_gossip` / `Swarm_charter_heard`), armed
   beside the other kinds, dispatched in both the pump and the hear funnel, SEEDED at `pier_accept`/`pier_confirm`
    (no-op for an undivided soul), re-emitted on a division change. Book **SwarmGossip**. Regression-clean:
     SwarmStaple 8/8 + SwarmChain 5/5 green against the shared-plumbing change.
- **5 · the serve binding** — `Swarm_serve_to` (Cave address off the Charter, else the Seat) + `Swarm_serve_ask`
   (gate on the Music grant at USE, resolve, emit — fail-forward). Book **SwarmServe**. The last mile — wiring
    the Heist/Ra dial to `Swarm_serve_ask` — is the owed CALL-SITE seam below.

**Fixtures RECORDED (live runner, `?B=<Book>`, 2026-08-27):** SwarmBody 4 steps / 5 assertions ·
 SwarmCharter 4 / 5 · SwarmPost 5 / 3 · SwarmGossip 4 / 3 · SwarmServe 4 / 3 — 19 declared swears, all
  sworn, all green. Checking the snaps caught a hollow-green in SwarmPost (a pier keyed `{Pier:1,pub}` was
   looked up as `{Pier:<prepub>}` — the same latent bug still sits in the SwarmRole Book at Swarmation.g
    ~2160, un-recorded so never caught); fixed + re-recorded with every derive/revoke flag firing.

**BUILT — THE CEREMONY (the "spread out" act, 2026-08-27):** `Swarm_adopt_offer`/`_verify` (role-agnostic
 body-adoption offer, presig-proven) · `Swarm_adopt_redeem` (verify → Sealbox-seal the whole account to the
  offered body-key → mint `%Grant:MyCave` → deliver) · `Swarm_adopt_absorb` (consent → unseal → import → the
   body holds the soul key → repost → Post) · `Swarm_adopt_finalise` (Captain + Cave rows + Charter #1) ·
    `adopt_seal`/`adopt_confirm` frames armed + dispatched · the UI front doors `Swarm_adopt_offer_url` /
     `_land` / `_pending` / `_consent`. Book **SwarmSpread** RECORDED green (4 steps / 4 assertions): the
      account genuinely crosses devices (`account_crossed`), the box derives Cave, Charter #1 routes both, and
       it fails closed on a tampered seal / wrong nonce / withheld consent. Regression-clean (SwarmStaple 8/8).
- **UI (`LinkDevice.svelte` + Door wiring, compile-clean, UNVERIFIED live):** the offer/land/consent faces;
   the role rides the offer (`Swarm_adopt_offer_url(w, base, role)`, default Cave) so both confirms NAME it;
    the **EmojiConfirm SAS** (`Swarm_adopt_sas_land`/`_consent`) shows on BOTH screens to catch a relay MITM;
     the warning is an opaque **cell takeover**; Link Device **auto-surfaces** on a landing `?Adopt=` or a
      parked consent; Butler shows "🪞 linking a device" (not the friend welcome); the Door paste slot accepts
       `?Adopt=` links; **🦑 squid logs** trace the handshake. Label "🪞 Link Device"; "TOTAL TRUST" opens the
        key-copy warning. **The human's two-device test is the gate** (see the check-list).

**Owed (the ceremony's remaining edges):**
- **The adoptee's identity transition.** After `Swarm_adopt_absorb` the device holds BOTH its old auto-vivified
   proto-identity (the body-key donor) AND the imported soul — so it can itself read as "two of you". Retiring
    the old self is NOT a naive husk-drop: the live self is stood up + managed by Auto/Clustation, so the
     transition "I am my own identity → I am a body of the soul" has to hand off through that layer, not just
      `container.drop`. Owed + Book-worthy (SwarmSpread proves the account crosses; it does not yet prune the
       donor). *(This is the most likely cause of a real post-adoption "two of you".)*
- **A role picker at the offer** (Cave / Captain) instead of the Cave default — small, offer-side.
- **Deploy to the remote node.** All of this lives on the local `/app`; the remote (djamsend) needs it pulled/
   built. The `?Adopt=` token proves the ceremony `.go` reached it; the UI batch above did not, yet.

**Owed (the other last mile):**
- **Wire the music dial to `Swarm_serve_ask`** at the Heist/Ra serve call site (needs live music fixtures +
   a serving daemon to verify), and **re-ground SwarmDivide onto per-body piers** — SwarmServe already proves
    the per-body Charter routing that supersedes SwarmDivide's roster-under-one-pier resolution.

**Owed a HUMAN ruling (not inventable):** whether the MUSIC paradigm lets one daemon Cave serve several
 souls' pools at once (Portability v1: one soul per Cave — deferred). One-store-many-souls is otherwise
  structurally native (the Vessel table groups by root prepub, and Body = `store × soul`, so a family daemon
   simply holds several Bodies). *(The dark-threshold prune number is RESOLVED: eviction is replacement, not
    a timer — see LIFECYCLE › Eviction. No quota is owed.)*

---

## APPENDIX — how we got here (the reasoning trail, compact)

- **The layering flip.** Captain/Cave were first placed as MUSIC-tenant vocabulary; the owner ruled them
   GENERAL ("below the Music realm"). The substrate owns the role NAMES; a paradigm binds only their MEANING.
- **The `%Reach` reversal.** A first pass reified "the other side" as a materialised liveness verdict
   (`%Reach`, kept fresh by a watcher off the presence pulse). Two adversarial Opus reviews + the owner's
    DNS-lookup instinct killed it: it re-introduced the exact "cache liveness + keep it fresh" shape the live
     transfer protocol (`repli_want`, `Repli.g`) already tore out for being "pure liability" that flooded the
      outbox and killed the deliver pump. Reverted. RESOLUTION stays pure; REACHABILITY is the transport's.
- **The Vessel straightening (owner, 2026-08-27).** The doc had hijacked "vessel" — the code's per-instance
   word (`Swarm_cohort_vessel`) — for the per-Body durable key. Straightened: Vessel = running instance
    (subsuming the old Facet/Sibling, and free to differ in soul/FSA/anything); the durable keypair is the
     BODY key; Body = `store × soul`; and a shared Vessel table grouped by root prepub is an individual's
      local subnet. This also made multi-soul stores structurally native.
- **The six cracks that shaped the field:** (1) relay has NO fan-out → the Charter is necessary [validated];
   (2) a stale Charter can wedge with no fan-out net [bounded by address stability]; (3) no durable per-body
    identity in code → the body key must be built; (4) Charter split-brain [fixed by the era stamp]; (5)
     friend-side is per-body piers, not roster-under-one-pier [reconcile before live]; (6) the always-on
      daemon-Cave is usually the SEAT, not the Captain [the insight that made Seat/Captain orthogonal and
       dissolved crack 2].
- **Resolved on inspection (not cracks):** per-body vs per-soul grants (both key off the soul — authz via
   the per-soul Music grant, authn via the soul-key voucher).
- **Death is eviction, not a timer (owner, 2026-08-27).** The last-owed HUMAN ruling — a "dark-threshold
   prune number" — dissolved once the frame flipped from *timeout* to *replacement*: a Post-holder leaves only
    when a new one takes its Post (`%NotGrant` + re-charter), singular Posts (Captain) evicting by default and
     plural ones (Cave) coexisting. A body that dies unreplaced lingers harmlessly, because the Charter never
      gated liveness (the `%Reach` lesson) — liveness lives at the bare name, where the Seat is alive by
       construction and every routing miss falls back to it. No quota, no clock, nothing owed.

*(This doc was consolidated 2026-08-27 from a long design + adversarial-review + crack-hunting arc.)*
