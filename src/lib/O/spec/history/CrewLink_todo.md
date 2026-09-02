# ⚰ HISTORICITY NOTICE (2026-09-03)

The pivot statement that carried the grant-based crew model out of the hell week. Its whole living
 content — the model, the glossary, §0's moves, the lens record — was absorbed into `spec/Crew_todo.md`
  (the one living doc for the soul/bodies/crew cluster), which also absorbed Division/Ferry/
   Ferry_rebuild/Inv_ferry. Kept whole as the cleanest single record of the pivot day.

---

# CrewLink_todo — device-link as a CREW of distinct identities, granted not copied

**The single clean statement of the device-link model (owner-settled, 2026-09-02 night, after a week lost
 to a device-link that never completed live — and after TWO intermediate models that were each subtly
  wrong; §5 records how).** A linked device is its OWN regular Identity that HOLDS a **`Grant:Crew`** from
   the Captain. Not a copy of the soul key. Not a carried Charter. Not a keyless husk. This doc replaces
    the models in `Ceremony_handover_todo.md`, `Ceremony_layering_todo.md` (both now in `spec/history/`),
     the soul-key-copy ruling in `Division_todo.md`, and THIS DOC'S OWN earlier draft (which named the
      Charter as the cert — superseded same night).

Companions: `Division_todo.md` (organism/organs teleology + Post/roster substrate — still live),
 `Reach_todo.md` (the cross-body procedure layer), `SoundPooling_todo.md` (the first consumer of crew),
  `Cluster_spec.md` (the blessed relay statement). Memories: `device-link-cert-crew-pivot.md`,
   `crew-charter-glossary.md`, `foreign-want-door-holder.md`, `want-middleware-plan.md`.

---

## 0. WHAT TO GET ON WITH NEXT

The grant-cert is BUILT + PROVEN (committed `063d790c "Grant:Crew"`, `Ghost/S/Swarm.g`): minted at the seal, landed on both
 piers, verified by `Swarm_voucher_ok`'s cert-crew road. Gates: `scripts/crew-cert-test.ts` 6/6 (accepts
  crew, refuses every forgery), InvWalk 8/8 (`Grant:Crew,by:Alice-soul,for:Cavey-body` lands; the Cave
   keeps its own key; `soul_key_copied` stays ABSENT), InvSeal 5/5, SwarmBody 23/23. The moves, in order:

1. **The library merge + reload-survival (the one real fork left).** Post-ferry the Cave holds TWO
    identities: its own keyed one (Piers, SocialGraph, the Grant:Crew — persists fine) and the Captain's
     account imported as a SEPARATE keyless identity (the library — does NOT persist: the identity-
      transition + persistence seams at Swarm.g ~7106 are `soul.c.keys`-gated and skip a keyless soul).
       Owner's "just a regular Identity" + SoundPooling's "a Cave holds its own copy of the library" both
        point at MERGING the ferried library into the Cave's own identity — one identity, own key, a
         Grant:Crew, its own library copy. Rework `Swarm_ferry_heard`'s import accordingly; Book-gate on
          InvWalk.
2. **Verify which identity is ACTIVE post-boot** (the Cave's own resumes with its Grant:Crew) — falls out
    of move 1 if the merge lands.
3. **SoundPooling first increment.** A Cave is a Pier we can talk certain music protocols to;
    SoundPooling utilises them QUIETLY (no UI ceremony): `Radio_dial_pool` → `Swarm_reach_book` →
     `Swarm_reach_serve` doer → `Heist_catalog_land(mardir:'pool')`. **The daemon joins your Crew** (holds
      a Grant:Crew like any Cave) to do SoundPooling with you — the while-you-sleep music-refreshing
       system.
4. **A Book proving a FRIEND honours a crew voucher** (InvWalk has no third party; the verify road is
    crypto-proven but not Book-proven from a friend's seat).
5. **Retire the soul-copy path**: `Swarm_adopt_redeem` (~5902) still key-copies; `Swarm_ferry_link`'s
    key-transplant is already bypassed by `{ferry:1}` export but the dead branch should go once live-proven.
6. **Housekeeping owed:** prune eed's ~12 dead Caves (all NotGrant); stop reload-piling — let the ~30s
    relay reaper clear stale sockets.

Do NOT re-open the seat/`want`/soul-family arbiter — distinct identities never collide.

---

## 1. THE MODEL — a Grant:Crew from the Captain, verified like any grant

Vocabulary first, because the words did real damage this week (see `crew-charter-glossary.md`):

- **Captain** — the identity holding the soul key. There is exactly ONE holder of the soul key, ever
   ("there's only one of anything"). The Captain alone controls the crew ledger.
- **Crew** — the SET of identities trusted to act as this soul: the Captain + every identity holding an
   un-revoked `Grant:Crew` from it. Crew is **grant-gated**: you are crew because you HOLD the grant,
    not because you hold (or lack) any particular key, and not because a ledger somewhere names you.
- **Cave** — one crew member that isn't the Captain: a perfectly regular keyed Identity (own key, own
   address, hellos as itself) distinguished ONLY by holding a Grant:Crew. `Swarm_signas(ident)` is the
    one seam for "who I sign+route as": soul key for a Captain (byte-identical to before → zero fixture
     churn), own body key for a Cave.
- **The Grant:Crew** — the cert. `mint_grant(soulkeys, cavePub, 'Crew', {}, now)` → a claim
   `{to:'Crew', by:soul-pub, for:cave-pub, time, sign}` — the SAME grant primitive friendships already
    use, so friends verify it with machinery they already run. Minted by the Captain AT THE SEAL
     (Swarm_hello link arm ~2405), landed on both piers (`grant_to_C`), sent in `pier_accept`, landed by
      the Cave iff `by === the-soul-I-join && for === my-key` (Swarm_accept link arm ~2458). ONE-WAY —
       no reciprocal mint; the Captain doesn't need the Cave's blessing. Individually revocable via
        `%NotGrant` — one stolen device ≠ whole identity gone (under soul-copy, a stolen device WAS the
         identity, cryptographically unrevokable).
- **The Charter** — a Captain-BUILT artifact (era-versioned, soul-signed member ledger) given to all
   Caves, for **display + recovery ONLY**: it shows the crew roster, and it can sometimes DESTRUCTIVELY
    resume a Captain from a Cave (if the Cave's copy wasn't the most up to date, that's the accepted
     cost). **The Charter is NOT the trust root** — a friend never needs it to trust a Cave; the grant is
      sufficient and self-contained. Crew and Charter are two different things wearing neighbouring
       words: Crew = who is trusted (lives in the grants), Charter = the picture+backup the Captain
        hands out.
- **Blessing is Captain-only.** A Cave can INVITE (relay a wish), but it cannot bless crew — minting a
   Grant:Crew takes the soul key, and only the Captain wields it. The Captain controls that Crew ledger.

**How a friend trusts a Cave** (Swarm_voucher_ok's cert-crew road, ~1407): the Cave's station voucher is
 `{control:'crew', from:body-prepub, pub:body-pub, era, ts, sign:<body-key sig>, grant:<the Grant:Crew>}`.
  The friend, sealed to soul-pub `held`, checks: `prepubOf(vh.pub) === from`; `verify_grant(vh.grant)`
   holds; `claim.by === held` (granted by the very soul I'm sealed to); `claim.for === vh.pub` (granted
    to the very key that signed this); body sig verifies. Then it trusts the Cave AS the Captain.
     Forgery-hammered in `crew-cert-test.ts`: grant-for-another-body, grant-by-wrong-soul,
      tampered-grant, body-sig-swap — all refused.

**The ceremony in four moves:** the new device MINTS its own key → knocks with the `?Iz` token (the
 physical-channel + fc-seal gate stands) → the Captain seals and **certifies** (mints the Grant:Crew,
  hands it over in the accept — no post-ferry sync gap, the Cave is crew the instant it's sealed) → the
   ferry carries account DATA only (`Swarm_export(n,{ferry:1})` omits the private key). Friends learn the
    crew via roster gossip and render any member as "you" — grouping lives in the Pier/Peering table (app
     layer), never in relay-address collision.

**Pirate-theme UI wording** (landed in `LinkDevice.svelte`): the offer reads "add to Crew the device
 showing: $icons"; the joining side reads "joining the Crew of Captain Grav" (⚓/🏴, "muster a crew
  mate"); a crew-roster panel reads `Swarm_body_roster`.

---

## 2. WHAT DIES

- **The soul-key COPY** and the identity theory under it ("you are the key"). The ferry never transplants
   the root key; only account DATA replicates.
- **The soul-door COLLISION and everything built to survive it:** the seat arbiter, `foreign want`, the
   door-yield/rehome switcheroo, the `${prepub}_${rid}` room build, seat/primary/recapture failover.
    All existed to make two live sockets share one name — devices never share a name now.
- **The Charter-as-trust-root** (this doc's own first draft + the crew-VOUCHER-carries-Charter build):
   the carried-ledger cert had a sync gap (the Cave had to WAIT for a Charter naming it; family_heal
    doesn't re-sign), and it made membership mean "the ledger names you" when the owner's meaning is
     "the Captain granted you". Superseded by the Grant:Crew; the Charter demotes to display+recovery.
- **The keyless-Cave theory** (`Swarm_is_cave = !keys && bodykey` as the crew discriminator): it located
   crew-ness in key-ABSENCE and hung the crew logic on the inactive imported identity. A Cave is keyed;
    `Swarm_crew_grant(ident)` (do I hold a Grant:Crew?) is the discriminator.
- **The "Charter: deleted" sub-ruling** (`Division_todo.md` §0 ⚑⚑⚑) stays reversed — but the Charter
   survives as artifact, not authority.

**What does NOT die:** account/library DATA sync (replication, exists); the full Grant handshake for
 FRIENDSHIPS (grants between people); the `who` presence probe ("is this soul online" = the union of the
  crew's presences); the fc-sealed physical channel at link time; the durable taste from the layering
   reckoning — *a knock must never depend on a %Pier existing; the ceremony must never depend on the
    %Pier's stream state.*

---

## 3. THE CHARTER'S REMAINING JOBS (display + recovery, additive)

- **Display:** the roster picture every member carries — who's in the crew, which is the Captain.
- **Recovery:** "how else do you backup but with all your bodies?" Replicate the account blob across the
   crew and keep it fresh; lose the Captain device and MyCaptain resume regrows it from any surviving
    Cave — DESTRUCTIVELY if the surviving copy was stale, which is accepted. The division IS the backup;
     all FSA-able (a backup member is legible matter, not a `.c` flag — the one bet).
- Neither job gates trust. A friend verifying a Cave touches only the grant.

---

## 4. TURN-KEY DELIVERABLES

1. Library merge: one Cave identity holding own key + Grant:Crew + its own library copy; reload-survives. ← NEXT
2. SoundPooling over crew-Caves (quiet protocols; daemon-as-Cave). ← NEXT
3. Friend-honours-crew-voucher Book (third-party seat).
4. Retire `Swarm_adopt_redeem`'s key-copy; delete the dead transplant branch.
5. Charter refresh as account-backup vector (additive; §3).
6. Cert-offer on `%Reach` (settles landed | refused,why | dead) — the "nobody answered" error.
7. Prune dead Caves; trust the relay reaper.

DONE: grant mint-at-seal + land + verify road; `Swarm_signas`; ferry-without-key; addressing
 self-collision fix; pirate UI + crew panel; offer supersession (a fresh invite supersedes a stale
  non-pending cave req so consent surfaces).

---

## 5. HOW WE WEREN'T QUITE SEEING IT (record, so the lens error isn't re-ground)

Three models in one week, each locating "being crew" in the wrong kind of thing:

1. **Crew = holding the soul key** (the original soul-copy). Identity as key-POSSESSION. Cost: two live
    sockets fighting for one relay name (the whole foreign-want/seat/rid saga), and the horror property —
     a Cave was cryptographically UNREVOCABLE (it held the root key; un-caving meant key rotation).
2. **Crew = being named in the Charter** (the first pivot draft — this doc's own §1 for a few hours).
    Identity as ledger-MEMBERSHIP. Cost: the cert became a carried document with a freshness problem
     (the Cave waits for a Charter naming it; re-sign seams like family_heal don't re-sign; a whole
      gossip apparatus just to hand the trust token over).
3. **Cave = the keyless identity** (the build error inside pivot #2). Crew-ness as key-ABSENCE — which
    put the crew logic on the inactive husk and broke the persistence seams (they're all
     `soul.c.keys`-gated for good reason).
4. **Crew = holding a Grant:Crew** (the owner's model, the one that stuck). Trust as a GRANTED,
    VERIFIABLE claim — the exact primitive the codebase already used for friendships.

The common error: we kept trying to make crew-ness an INTRINSIC property of the identity (what key it
 holds, what ledger names it, what key it lacks) when the system's own trust vocabulary was already
  RELATIONAL — a grant by someone, for someone, checkable by anyone. It's the identity-per-shelf rule
   from CLAUDE.md wearing trust clothes: the soul key exists ONCE (the holding, on the Captain);
    everything else that says "crew" is a REFERRING particle — a Grant carrying `by`/`for` — never a
     second holder impersonating the identity. And the tell was the same tell: two different shapes
      under one mainkey (two "Identities" claiming one soul).

Corollary that fell out free: revocation. Under lens 1 it was impossible; under lens 4 it's one
 `%NotGrant`. When a model correction deletes your scariest open problem as a side effect, that's the
  sign you found the right shape.

The week's OTHER lesson stands apart: the live failure was never ceremony code at all — it was a tab's
 own two sockets colliding on its name (fixed; `foreign-want-door-holder.md`), invisible for days because
  a vanished knock looked identical to "working, please wait". Every dead-end must name itself.
