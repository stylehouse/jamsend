# Crew_todo — one soul, many bodies, granted not copied

**The ONE living doc for the soul/bodies/device-link/crew cluster** (owner-called consolidation,
 2026-09-03: "way too many documents to come out of such a hell week — capture the going-forward vision
  most of all"). It absorbs and retires to `spec/history/`: `CrewLink_todo.md` (the pivot statement),
   `Division_todo.md` (the organism substrate), `Ferry_todo.md` + `Ferry_rebuild_todo.md` (the ceremony +
    its req rebuild), `Inv_ferry_todo.md` (the Book survey) — after `Ceremony_handover_todo.md` +
     `Ceremony_layering_todo.md` retired the same week. Battle-logs live in the corpses; THIS doc is the
      destination. Where the strata disagree (they moved twice on 2026-09-02), what stands here wins.

Companions still their own docs: `Reach_todo.md` (the cross-body procedure primitive),
 `SoundPooling_todo.md` (the pool), `Presence_todo.md` (the `who` probe), `Cluster_spec.md` (the blessed
  relay), `Onboarding_todo.md`, `Statehome_todo.md`. Memories: `crew-charter-glossary.md`,
   `device-link-cert-crew-pivot.md`, `foreign-want-door-holder.md`.

---

## 0. WHAT TO GET ON WITH NEXT

The grant-cert core is BUILT + PROVEN (committed `063d790c "Grant:Crew"`): minted at the seal, carried by
 the Cave, verified by `Swarm_voucher_ok`'s cert-crew road. Gates: `crew-cert-test.ts` 6/6, InvWalk 8/8
  (`Grant:Crew` lands both piers; `soul_key_copied` stays ABSENT), InvSeal 5/5, SwarmBody 23/23. In order:

1. **The library merge + reload-survival (the one real fork left).** Post-ferry the Cave holds TWO
    identities: its own keyed one (persists fine) and the Captain's account grafted as a separate keyless
     identity (the library — does NOT persist; the `soul.c.keys`-gated seams at `Swarm.g` ~7106 skip it).
      Merge the ferried library into the Cave's OWN identity — one identity, own key, a Grant:Crew, its
       own library copy. Rework `Swarm_ferry_heard`'s import; Book-gate on InvWalk; verify which identity
        is ACTIVE post-boot, on disk and live (the Door UI lies).
2. **Build the `/Crew` structure (§3)** — give the crew a home as matter: `/Crew/pier:<prepub>,role/`
    rows holding the `Grant:Crew`s; `Swarm_crew_grant` reads it instead of grant-scanning the Peering;
     the Charter becomes the signed export of the subtree. Migration: the seal mints the row + homes the
      grant there.
3. **SoundPooling over the crew.** A Cave is a Pier we talk certain music protocols to, QUIETLY (no UI
    ceremony): `Radio_dial_pool` → `Swarm_reach_book` → `Swarm_reach_serve` doer →
     `Heist_catalog_land(mardir:'pool')`. Then **daemon-as-Cave**: the daemon joins your Crew (same
      ceremony, own identity + Grant:Crew) — the while-you-sleep music-refreshing system. Enumerate
       `/Crew` for the pool peers.
4. **A Book where a FRIEND honours the crew voucher** (third identity: Captain, Cave, friend — the
    verify road is crypto-proven but not Book-proven from a friend's seat).
5. **Finish the %Ferry req inversion against the new carry** (§6) + **Stage-4 fail-closed consent**
    (send gates on `req:FerryConfirm.finished`, NEVER on humdinger-absence — the fails-open hole) +
     the **%Reach cert-offer** (settles landed | refused,why | dead — every dead-end names itself).
6. **Retire the soul-copy path**: `Swarm_adopt_redeem` (~5902) still key-copies; the `{ferry:1}` export
    already bypasses `Swarm_ferry_link`'s transplant — delete the dead branches once live-proven.
7. **Owner's live 2-device walk** of the rebuilt ceremony (cross-wire races are live-only by nature).
8. **Housekeeping:** prune eed's ~12 dead Caves (all NotGrant); stop reload-piling (trust the ~30s relay
    reaper); fix ~5 stale Swarm.g comments (4746/4857/5047/5126/5277) claiming decline mints a NotGrant.

Do NOT re-open the seat/`want`/soul-family arbiter — distinct identities never collide.

---

## 1. THE VISION — an organism growing organs

**One soul, many role-bearing bodies — a paradigm-general substrate, music poured through first.**
 A divided soul is one organism; its bodies are its ORGANS. An undivided soul is a single cell doing
  everything adequately and nothing deeply; division is the soul growing organs, and no organ is the
   whole soul — **the soul is the living relation among them**.

The two first organs: the **Captain** is the organ of REACH and WILL (the phone in your hand; the
 pocketful playable THIS SECOND offline; the invite helm; the soul's hands and voice). The **Cave** is
  the organ of DEPTH and MEMORY (the always-on box; the huge sprawling collection; the hearth — the
   soul's long memory and its patient body that never sleeps). **The Captain has what you want NOW; the
    Cave has EVERYTHING** — and it is the TRAFFIC between them that is the soul being alive across its
     machines. The organ set is open: an **Ear** (listen-only, all reach no depth), a **Loft** (the
      editing/compiling body), the daemon (a Cave that works while you sleep). A Post is a BUNDLE of
       organs; bodies specialise, the soul is their union.

**Roles are NOT a trust hierarchy** (owner): all bodies are equally high-trust — they are all YOU.
 Captain/Cave is forced only by (a) replication needing a singular coordinator and (b) genuinely
  different organs. Read "the Captain does X" as "the singular coordinator does X so two bodies don't
   fight," never "the privileged body."

**The division IS the backup.** "How else do you backup but with all your bodies? we want some stuff
 quite immortal, shared amongst our bodies." Lose a device and the organism regrows its lost organ from
  any surviving one (MyCaptain resume — deliberately human, never automatic; destructive if the
   surviving copy was stale, which is accepted).

Inter-body work is **living legible matter, not `.c` flags**: `%Organ` (what a body grows —
 `/Organ:ready,tracks:214/` vs `/Organ:trove,tracks:38k/`), `%Reach` (a request in flight — an EVENT,
  landed via `Reach_todo`), `%Bond` (the standing Captain↔Cave restock relation as ONE particle both
   write). And now `/Crew` (§3) — the gang itself as a subtree.

---

## 2. THE WORDS (settled — the week burned on wrong ones; see §10)

- **Soul** — the identity; its key exists ONCE, held by the Captain. **Body** — `(store × soul)`: a
   per-store keypair (Dexie, never replicated), its prepub IS its address. **Vessel** — one running
    instance (tab); vessels share their body's key, no address contention. Two orthogonal axes:
     vesselling slices a MACHINE by soul; division slices a SOUL by machine; a Body is where they cross.
- **Captain** — the ONE holder of the soul key ("there's only one of anything"). Alone controls the
   crew ledger: minting a `Grant:Crew` takes the soul key. Singular; succession evicts.
- **Cave** — a non-Captain crew member: a perfectly REGULAR keyed Identity (own key, own address,
   hellos as itself) distinguished ONLY by holding a Grant:Crew. Caves coexist. A Cave can INVITE
    (relay a wish), never bless.
- **Crew** — the living gang: the Captain + every identity holding an un-revoked `Grant:Crew` from it.
   **Grant-gated** — not key-possession, not ledger-membership, not key-absence. Homed at `/Crew` (§3).
- **`Grant:Crew`** — the cert: `{to:'Crew', by:soul-pub, for:cave-pub, time, sign}` — the SAME grant
   primitive friendships use. Minted AT the seal, handed over in the accept (the Cave is crew the
    instant it's sealed — no sync gap), one-way, revocable via `%NotGrant` (one stolen device ≠
     identity gone).
- **Charter** — the soul-signed EXPORT of `/Crew` (§3): a Captain-built artifact given to all Caves,
   for **display + recovery only**. NOT the trust root; no friend needs it. Crew = who is trusted (the
    grants); Charter = the picture+backup the Captain hands out.
- **Post / duty** — a body holds a Post (`role` on its crew row: Captain, Cave, daemon…); a vessel has
   a duty. A Post is not a label — it is which organs that body grows.
- **Seat** — merely "who holds the soul DOOR binding on the relay right now" (first-come; the one thing
   the relay still arbitrates). Not membership, not authority.
- Rename trail (old→new): SelfType→Post · vessel key→body key · Sibling/Facet→Vessel ·
   DivisionMaster→Seat · "Charter cert"→`Grant:Crew`.

---

## 3. THE STRUCTURE — `/Crew/pier,role/Grant` (owner, 2026-09-03)

The Crew gets a HOME in the tree instead of existing only as a scan:

    /Crew
      /pier:<prepub>,role:<Captain|Cave|daemon…>
        /Grant:'Crew',by:<soul-pub>,for:<body-pub>,…

- Lowercase **`%pier`** is its own mainkey — "a naming of a Pier" — whose value IS the join key (the
   `%Spotlight,src` idiom). It is NOT `%Pier`: a second shape wearing the transport mainkey under a
    different container would be the magazine-minted-`%Record` disease. `%Pier` in the Peering stays
     the one holding of the transport peer; `/Crew/pier:$prepub` points at it.
- **`role`** rides the row — what kind of crew member this is. This is where Division's Post concept
   lands (the old Charter payload `pub:Post:soulname` was trying to say exactly this).
- **Piers stay homed in the Peering** (transport untouched — every Peeroleum sweep keeps its one
   shelf); the crew matter moves: the `Grant:Crew` homes under the crew row, since it is crew matter,
    not pier matter (parking it on the pier was a convenience of the seal moment). The considered
     alternative — moving crew Piers bodily under `/Crew` — was rejected: every transport seam
      iterating `peering.o({Pier:1})` would need to tour two shelves, and a missed callsite is a crew
       member silently unreachable.
- **The Charter IS the signed export of this subtree.** Display = rendering the bundle; recovery =
   re-importing it; "the Captain controls the ledger" = only the soul key signs that snap. No parallel
    structure to keep in sync — the ledger and the picture are one thing.
- SoundPooling and every quiet crew protocol ENUMERATE `/Crew` directly; Books `%see` the bundle.
- Migration: the seal mints the row + homes the grant there; `Swarm_crew_grant(ident)` reads `/Crew`
   (fall back to the pier-scan for pre-migration accounts); the roster (`%Body` rows) stays the
    contact-learned ROUTING convenience it already is.

---

## 4. THE MODEL AS BUILT — Grant:Crew end to end

**Certify a new key; do NOT copy the old one.** Four moves: the new device MINTS its own key → knocks
 with the `?Iz` token (physical channel + `#fc` seal gate stands) → the Captain seals + CERTIFIES
  (mints the Grant:Crew, hands it over in the accept) → the ferry carries account DATA only
   (`Swarm_export(n,{ferry:1})` omits the private key).

**`Swarm_signas(ident)`** is the one seam for "who I sign+route as on the wire": soul key for a Captain
 (byte-identical to before → zero fixture churn), own body key for a Cave. Discriminator for crew-ness:
  `Swarm_crew_grant(ident)` (do I hold a Grant:Crew?) — never `!keys`.

**How a friend trusts a Cave** (`Swarm_voucher_ok`'s cert-crew road): the Cave's station voucher is
 `{control:'crew', from:body-prepub, pub:body-pub, era, ts, sign:<body-key sig>, grant:<the Grant:Crew>}`.
  The friend, sealed to soul-pub `held`, checks: `prepubOf(vh.pub) === from`; `verify_grant(vh.grant)`;
   `claim.by === held`; `claim.for === vh.pub`; body sig verifies → trust the Cave AS the Captain.
    Stateless — no ledger fetch, no era compare. Forgery-hammered in `crew-cert-test.ts` (grant-for-
     another-body / grant-by-wrong-soul / tampered-grant / body-sig-swap all refused).

Friends learn the crew via roster gossip and render any member as "you" — one presence, many bodies;
 grouping lives in the Pier/Peering table, never in relay-address collision. "Is this soul online" is
  the union of the crew's presences (`Presence_todo.md`).

**Pirate UI** (landed, `LinkDevice.svelte`): "add to Crew the device showing: $icons" / "joining the
 Crew of Captain Grav" (⚓/🏴, "muster a crew mate"); crew-roster panel; offer supersession (a fresh
  invite supersedes a stale non-pending cave req so consent surfaces).

---

## 5. THE SUBSTRATE — bodies, addresses, the ledger

**Land-of-prepub (Model B), landed:** every body hellos with its OWN key and IS its own address
 (`to:<prepubOf(body_pub)>` — derived, never assigned, never fought over; collisions impossible by
  construction). The soul hello remains only as the DOOR (one binding, first-come — all the relay
   arbitrates). Routing = membership × presence. The roster (`%Body,pub/post/name` rows, no address
    column) is contact-learned ("popped up by whoever you manage to talk to"), replicated grow-only by
     the roster mile; membership is proven at the door by the voucher, never by the roster.

**The ladder:** Soul (key stays home with the Captain; crew membership is grant-certified) → Body (own
 key per store; holds a Post; its `from` is stable for its whole life — Repli-friendly) → Vessel
  (per-pageload; has a duty; not in any roster).

**Never replicates:** which row is ME (computed by body-key match — a stored flag would replicate and
 lie); current address; presence; the Vessel table; the stolen flag; per-body wire state.

**Why a durable ledger at all** (even with the Charter demoted): presence structurally cannot be
 membership — offline members exist (the Captain is intermittent BY TELEOLOGY; reaches book durable
  intents against sleeping bodies); the relay is list-in and untrusted; wake-up self-knowledge needs a
   carried record. Presence is a live VIEW of the crew's subset, never the crew. That record is `/Crew`
    + its signed export.

---

## 6. THE CEREMONY GOING FORWARD

**The `?Iz` spine survives the model flip whole:** URL = `base + '?Iz=' + token + '#fc=' + secret` —
 the secret rides the FRAGMENT, never the relay; wrong code fails closed in unseal; the sealed frame
  carries no private-key hex. Presig is issuer-regenerated; the serial is single-use
   (`claimed:"3-5~9~14"`, `~`-joined; double-spend → `pier_reject`) and is the correlation key between
    the two interlocking req stacks. Spine: mint → carry → verify-at-door → claim → seal
     (`pier_hello/accept/confirm`) → ferry → `ferry_got` ack → consume clears secret + parked confirm +
      durable twin; reload never rehydrates a resolved ceremony.

**The %Ferry inversion (Stage 3 landed, finish against the new carry):** the ceremony was built BELOW
 the particle system — ~14 `top.c.ferry_*` flags, 3 hand-mirrored twins, 4 surface patches; `.c` never
  snaps, so the whole ceremony was invisible to every Book, which is WHY it drifted unchecked. The
   inversion: ONE legible req whose **phase walk IS the ceremony** (`req:Ferry_soul` /
    `req:Ferry_cave` under an eternal pump; phases land in Book fixtures), one write chokepoint
     (`Swarm_ferry_phase`) owning particle + twin + surface + terminal cleanup; readers DERIVE.
      LinkDevice reads one `Swarm_ferry_facts`.

**Consent, going forward:** aware all the time (every phase move surfaces itself); responsive to the
 end (every ack flips the face NOW; acks ride the control-plane carve-out and never starve); one
  heading + one line per side, upgraded in place; opening the link + "understand" IS the consent — no
   third ask; the joiner's terminal line is "reload — wake up as crew". Owed: Stage-4 fail-closed
    (§0.5) and the %Reach offer so "nobody answered the door" is a named settlement.

---

## 7. BOOKS + GATES

| Book | state | proves |
|---|---|---|
| SwarmStaple | 8/8 | friendship handshake + forged-presig/spent-nonce teeth; beat 7 = friend-trust byte-inert canary |
| SwarmInvite | 5 | QR front door mint→…→seal + spent-QR tooth |
| SwarmSeal | 2 | Sealbox fails closed |
| SwarmSpread | 5/5 | ferry-glue send/heard + tamper/withheld-consent teeth |
| InvSeal | 5/5 | seal-seam warmth gate (cold-refuses, warm-parks); consenter puppet |
| InvFerry | 6/6 | the full exchange walk, phases in snap |
| InvWalk | 8/8 | end-to-end cert-crew: grant lands, Cave keeps own key, `soul_key_copied` ABSENT |
| SwarmBody | 23/23 | body/roster substrate |
| `crew-cert-test.ts` | 6/6 | voucher forgery hammer |
| SwarmFerry | 1, hollow | vestigial — delete/fold; never copy its fixture |

**Missing:** friend-honours-crew-voucher (third seat); library-merge reload survival; forget→relink
 forgive efficacy; name-gate + silent-serial-refusal (land with the features); cross-wire races
  (live-only). Verify on the LIVE runner, never headless Story_cli; Books prove *inert*, only the live
   runner proves *works*.

---

## 8. STILL OWED (beyond §0's ordered head)

- `%Organ` made real on the live bodies (ties to the Disk cell); `%Bond` (the standing restock
   relation as one shared particle); B4 carry-out doer (bind `%Reach` booking to Heist/Repli — the
    sibling music-serve lane).
- Rung-2 restore: empty-Dexie + populated-FSA auto-resume with a "main account" pointer in the FSA.
- Repli self-lane: the joined device's library fills from the Captain over the crew address.
- Facet C: NACK-with-redirect for no-pier drops (`Peeroleum.g:607`); Facet D remainder: roster gossip
   to FRIENDS + live per-body presence.
- Held for owner: retire SwarmCharter/SwarmGossip Books, then the charter-era machinery + legacy
   grants-wire sidecar; Steal Back's meaning (the soul-DOOR contest is still real); may one daemon
    Cave serve several souls' pools?; the prepub→pubkey phase-out + the `%Pier.sc.pub` lie (holds a
     prepub) — wire-wide, wants a ruling.
- Retire the gap-Captain guard once grant replication survives a real interregnum; seat-expiry audit
   (relay binding lifetime); anchor-mint mystery (`Swarm_token_parse` refuses its own `#Iz` mint).
- Stage 5, once crew proves the shape: `Grant:Music` ceremony gets the same
   one-particle/one-phase-walk/ends-on-a-screen treatment.

---

## 9. DURABLE LAWS (a rebuild honours these or re-learns them expensively)

- A knock must never depend on a %Pier existing; the ceremony must never depend on the Pier's stream
   state. Nothing books onto a pier inbox before `%Ud` exists; first-contact rides the pier-less lane.
- A body isn't a friend — same-soul dispatch is pier-less. "Peering = who we listen as, Pier = who we
   dial"; `for`/`from` are IDENTITIES, never addresses; grants ride only piers (and now `/Crew`).
- Crew consent ≠ friendship grant: its own liveness rule; NEVER touch `Swarm_pier_live` (SwarmStaple
   beat 7 byte-identical is the canary). Freshest deliberate consent wins; epoch = the signed invite
    serial, never a wall-clock compare. A stale `%NotGrant` must not bury a fresh re-link
     (`Swarm_cave_forgive` at the proven-fresh redeem).
- Warmth gates: a grant is not presence — a cold pier parks NOTHING; warm parks consent and sends
   nothing until the human confirms. Surface teardown gates on ceremony-active, not warm-right-now.
- Consent split: `humdinger` = screen+disk only (Books never set it); `consenter` drives park/confirm;
   consent gates fail CLOSED. Never a boot hijack: grace valves sit far above honest boot time.
- The secret never rides sc; `.c` + ONE durable twin; terminals clear the twin; standup re-enters at
   the deepest unfinished phase. Acks fold in as phases, never side-flags.
- Deletion is PROVISIONAL (the space-deal): a pruned body can return and re-announce; retirement =
   "prune what I don't currently see," reversible, never a hard self-tombstone. Eviction is
    replacement, not a timer; Captain succession is never automatic; door succession is.
- Resolve-and-emit, no liveness cache: resolution (who/where — off the ledger) and reachability
   (discovered by SENDING) stay apart; reify EVENTS, never kept-fresh verdicts.
- Mutual consent, neither side silent: the soul side confirms the share, the device confirms the role;
   a mis-scan must never quietly hand over your soul. The instance name belongs to the BODY
    ("Captain Grav / Cave Guw"); the landed soul's `friendly` must not swallow the joiner's name.
- The relay does exact-address routing, no fan-out; whatever names an address must be carried.
   Transient bookings graduate and DROP. Merged-in-place ledger rows; async key ops ride
    `expecting()`. ttlilt is NOT a scheduler — steady asks stay real wire heartbeats.
- Book-inertness: total determinism; witness notes are boolean OUTCOMES, never timestamps; gate on
   ok/exit-code, never cross-run dige; fixtures re-record ONCE, at a declared seam.
- Two shapes under one mainkey = the identity tell (why `/Crew` rows wear `%pier`, not `%Pier`).
- Every dead-end must name itself — a vanished knock must be indistinguishable from nothing, not from
   "working, please wait."

---

## 10. HOW WE WEREN'T QUITE SEEING IT (the lens record)

Four models in one week, the first three all locating "being crew" in an INTRINSIC property:

1. **Crew = holding the soul key** (soul-copy). Cost: two live sockets fighting for one relay name —
    the whole foreign-want/seat/rid saga was referee machinery for a fight that shouldn't exist — and
     a Cave was cryptographically UNREVOCABLE.
2. **Crew = being named in the Charter** (the first pivot draft). Trust as state-held-elsewhere: a
    Cave couldn't prove itself until the ledger reached the verifier; a whole gossip apparatus just to
     hand the token over.
3. **Cave = the keyless identity** (the build error inside #2). Crew-ness as key-ABSENCE — hung the
    logic on the inactive husk and broke every `soul.c.keys`-gated persistence seam.
4. **Crew = holding a `Grant:Crew`** (the owner's model, the one that stuck). Trust as a RELATIONAL,
    granted, verifiable claim — the primitive the codebase already ran for friendships.

The lesson: **trust travels as portable signed matter carried by the trusted thing** — never an
 address to occupy, a ledger to sync, or a key-shaped absence. It is the identity-per-shelf law in
  trust clothes: the soul key exists ONCE (on the Captain); everything else saying "crew" is a
   referring particle. The tell we'd found the right shape: the scariest open problem (unrevocable
    Caves) deleted itself — revocation became one `%NotGrant`. When a correction deletes your worst
     problem as a side effect, you found the right shape. And the week's other lesson: the live
      failure was never ceremony code — a tab's own two sockets collided on its name, invisible for
       days because a vanished knock looked identical to "working, please wait."

---

## 11. WHERE THE HISTORY WENT

All in `spec/history/`, each under a ⚰ notice: `CrewLink_todo.md` (the pivot statement this doc
 absorbs), `Division_todo.md` (the substrate design + the whole Phase A–D battle-log + the seat war),
  `Ferry_todo.md` (the ceremony post-mortem + acceptance tests), `Ferry_rebuild_todo.md` (the 5-fork
   req-inversion synthesis), `Inv_ferry_todo.md` (the Book survey + the 11 assertion targets),
    `Ceremony_handover_todo.md` + `Ceremony_layering_todo.md` (the forensic week). A referenced
     `spec/X.md` that isn't there is almost certainly `spec/history/X.md`.
