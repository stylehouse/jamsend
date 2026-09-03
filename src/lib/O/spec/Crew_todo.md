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

0. ✅ **THE OWNER'S FIRST LIVE WALK (2026-09-03) — what it found, what landed.** Four symptoms, three
    causes, all fixed + InvWalk-gated (fixtures 4–8 re-sworn; the diff was EXACTLY the cleanup):
    - *"🚪 unvouched_roster — 5ade…" ×3 in the Cave's Door.* The merge grafted EVERY Peering row of the
      account — including the Captain's **self-husk pier** (`Pier,pub:<Captain BODY key>,link,post:Captain`),
      so the Cave held the Captain's body key where `Swarm_voucher_ok` expects the held SOUL key →
      'held pub differs' on every roster frame. **Fix:** the merge skips `link` piers (a link pier is the
      Captain's bond with ONE body: its husk, its piers to my sibling Caves, its pier to ME — none is my
      relationship; I hold my own pier to the Captain), skips the `%rebuff` ledger, prefix-skips my own rows.
    - *The Captain's door slamming the Cave's frames* ('signature bad', silent). A crew member that is ALSO
      the sealed counterparty (its key = the held pub) signs FLAT and attaches the grant AFTER, but the
      classic arm verified the whole envelope (canonicalHeader hashes every field). **Fix:** verify the
      flat header when a grant/charter rides along.
    - *"Captain Grewp" + "Cave Grewp" + two "Captain Grav"s + three dead Caves* in the crew list. The
      Cave's lone-body standup had minted a SEPARATE body key (post:Captain of itself) that survived the
      merge and gossiped into the Captain's roster; `Swarm_graft` keyed %Body rows by whole-sc so any
      post change twinned a row; the roster is a grow-only gossip union and never was a membership.
      **Fix:** the merge forces ONE key (`.c.bodykey` = the identity key, persisted via bodykey_write) and
      retires the old row + husk; graft dedupes %Body by `pub` (+ %Crew/%mate/%Charter/%rebuff); NEW
      **`Swarm_crew_tidy`** — once /Crew stands, a %Body row or link %Pier no mate backs (by prepub or its
      stamped `body:`) and that is not me is retired; rides the 60s trickle (human-gated) + the merge.
      Crew rows now carry **`body:<pub>`** (stamped at seal/accept/merge, learned at the door off a
      vouched frame's page) so the Captain's body row is backed by more than its post.
    - *"there's a CREW in the Link … isn't where I want that" / Door shows no crew.* The Link strip read
      the %Body roster; **removed**. The Door's family box now reads **`Swarm_crew_view`** over /Crew
      (role off the row, name off the pier/roster, presence off heard_at/heard; roster only lends organ
      sizes; a pre-/Crew account keeps the roster view). Link's last screen is "done — you're in the
      crew" (nothing to become under the merge; reload harmless, not required).
    - *Door ✕ (forget)* now drops the /Crew mate row + that key's %Body rows with the bond. Rebuffs are
      ONE row per (why, who) with a `n` count, capped at 24.
    - **Dial-in for the developer** (owner: "AI having access to the database and tidying it"):
      `runner_ask crew --player=<id>` dumps the live self (crew view, bodies, link/friend piers with
      grants/nots, rebuffs); `runner_ask tidy <crew|rebuffs|forget:<pub>> --player=<id>` mutates —
      refused unless the tab is ARMED (socklog on --reload: the dev switch is the consent). Fixed verbs,
      no eval (Swarm_spec's untrusted-relay ruling).
    STILL TO SEE LIVE: reload both tabs (this build), re-walk; the Cave's Door should list ⚓ Captain +
     🏴 itself and nothing else; the Captain's Door the same; zero 🚪 unvouched rows; the three dead
      Caves + the two stale Captain rows retire on the first trickle (~60s) or via `tidy crew`.

    **SECOND WALK (same day, on the fixed build) — the Door crew looked right at both ends.** Landed after it:
    - the Cave's "done" now runs `link_done()` (the Captain's terminal pack-up: finish the ceremony reqs, drop
      the twins, focus the Door) — a bare state clear left the flag pile standing → "you have a device link in
      progress" haunted the lobby. The received screen names the Captain with its live dot; the reload note is gone.
    - name-gate inputs are `autocomplete="off"` and `Clustation_friendly` refuses a URL-shaped name (the owner
      saw "add to your Crew the device showing https://djamsend.duckdns…" — the only road for a URL into
      `peering.sc.friendly` is that input; treat a recurrence as a real lead, not noise).
    - a crew row sealed <4 min ago wears `fresh` (crew_view `since` off the pier's seal stamp / grant time) and
      the Door GLOWS it — the receipt of a finished link, where the ceremony now dumps you.
    - ⏰ **OWNER REMINDER: test "🔗 resurrect my Captain"** (a Cave minting MyCaptain — the succession/recovery
      ceremony; `Swarm_ferry_link` role-aware helm). Untested since the merge; blind spot 6 (§8) applies.

    **IS THE CEREMONY CODIFIED, OR SPAGHETTI? (the owner's question, 2026-09-03) — honest answer: half-spined.**
    - The SPINE exists and is good: `Swarm_ferry_phase(w, phase, facts)` (12 phases: minted offered awaiting
      pending confirming sent held got received declined cancelled ended) writes ONE `%Ferry` req; `Swarm_ferry_facts`
      reads it back as `{offer, awaiting, pending, confirm, sent, got, ended, twin}`; LinkDevice's screen = a
      switch over those facts. That is the codification, and it is the right shape.
    - The SPAGHETTI is the two legacies still alive beside it: (1) **eight `top.c.ferry_*` flags** (secret, offer,
      offer_accepted, awaiting, pending, confirm, sent, world) that the phase verb mirrors rather than replaces,
      plus the stashed "durable twins" — every reload bug this month was a flag and its twin disagreeing;
      (2) the UI's own `$state` (LinkDevice: 19 `$state`, 11 `$derived`, 11 `$effect`, 33 template branches;
      `url/pending/sent/received/taking/auto_received` are a SECOND copy of the phase). Swarm.g holds 48
      ferry|link|adopt|redeem|seal|accept verbs across 7.8k lines, a third of them the retired soul-copy road
      (adopt_redeem, the keyed ferry branch, the MyCave/MyCaptain grant handshake the mint-stop replaced).
    - The slog that de-spaghettis it (§0.5/§0.6, unchanged in shape, now unblocked): make `%Ferry` the ONLY
      state — every `top.c.ferry_*` read becomes a `Swarm_ferry_facts` read, the twins die with them, LinkDevice
      keeps at most `name_draft`/`err` as local state; then delete the adopt road + the keyed ferry branch with
      SwarmSpread beat-3 re-sworn. ~2 sessions. Do it BEFORE daemon-as-Cave (a headless ceremony can't lean on
      UI-held state).

    **SMOOTHING LEFT FOR THE CREW PIVOT (seen, not yet done):** the "🏴 muster a crew mate" lobby still explains
     the OLD deal in its title ("copies your whole soul" wording survives in a few titles/comments — grep
      "soul" in LinkDevice); the Door's friend list still shows a Cave's inherited friends with no "shared
       with the crew" mark; `InvitePanel` renders rebuffs raw (`unvouched_roster` is a code name — say "a crew
        frame failed its voucher"); no way to see a mate's cert (the Grant:Crew) or revoke it from the Door row
         except ✕-forget (which does not travel, §8 blind spot 2); the splash's "🎧 listen without a folder"
          (BootGate) sets `top.c.listen_only` and stays out of the ceremony's way (BootGate suppresses only the
           audio nicety on `link_active`, never the FSA gate) — the GATE half of that is true.

    **⚑ THE LISTEN-ONLY TRACE (the owner: "this needs a really high-level tracking through") — and the
     REGRESSION it found, fixed same day.** Tracking "🎧 listen without a folder" end to end:
     `boot_gate.listen_only()` → `c.listen_choice=1`, `c.disk_gated=false`, share mode 'thin' stashed →
      Housing's Wormhole tick (`listen_choice || (!book && no showDirectoryPicker)`) → `disk_gated=false`,
       `listen_only=true`, `navigator.storage.persist()`, a MINIMAL no-op MountNav + OPFS pool mount, and
        **`return` early** → BootGate's bar renders on `disk_gated || (ac_wanted && …)`, so nothing about a
         live ceremony suppresses the gate (only the audio nicety waits on `link_active`). Escape:
          BigSoundland's OPEN SHARE deletes both flags and re-raises `disk_gated`. **That half held.**
     **What the trace actually exposed:** the listen-only LIFE has no account snap (no nav ⇒
      `.jamsend/account/<prepub>/toc.snap` is never written), and **a phone is always in that life** — no
       mobile browser has `showDirectoryPicker`. Durable identity state there survives ONLY through the
        House stash, whose whole surface is `Swarm_restash_all`: piers · izzes · chainroots · roster. When
         the cert moved onto `/Crew/mate:<me>/Grant:Crew` this morning it left the %Pier — **whose grants
          the pier stash already carried** — for a shelf with NO pillar. Consequence: on a folderless
           device's second boot, /Crew is gone, `Swarm_crew_grant` returns null, the station voucher falls
            back to the classic arm, and **the Cave silently stops being crew** — on exactly the device the
             cert-crew model exists for. **Fixed:** `Swarm_restash_crew` + `Swarm_crew_rehydrate` (the fifth
              pillar), wired into restash_all and the `Swarm_station_up` ladder BEFORE the voucher mint,
               SYNC (the grant lands unverified exactly as pier grants do — a cert is a credential you
                PRESENT, verified at the far side, so there is no race with the voucher). 8/8 Books green,
                 caveat:0, fixtures unmoved (every stash verb is live-self + `stashed` gated).

    **⚑ AND THE HOLE THAT LET IT THROUGH (the owner: "do we have some lovely abstractions that we can test
     with?").** For the CEREMONY, yes: %Ferry + `Swarm_ferry_phase`/`_facts` is a real spine and the eight
      Books gate it. For **PERSISTENCE, no** — and that is why eight green Books said nothing about a
       regression that breaks every phone. Every _stash/_rehydrate verb is gated on
        `Swarm_live_self() === ident` AND `top_House().stashed`, both false in a Book world, so **no fixture
         has ever exercised a single pillar**. The missing gate is one Book: **SwarmReboot** — raise the
          puppet as live-self (the consenter-puppet idiom) with a scratch `stashed`, restash_all, drop the
           live %Peering + /Crew, run the station_up rehydrate ladder, and swear all five pillars came back
            (piers with grants · izzes · chainroots · roster+charter · crew+cert). Author it before the
             %Ferry-only slog: it is the only thing that makes "survives a reload" a fact instead of a hope,
              and it would have caught this in the minute it was written.

    **✅ BOTH LANDED, LATER THE SAME DAY — and one correction.** The crew-pillar edit reported above as
     "fixed" **silently never reached disk** (a batch edit script exited on a later failed match before its
      single writeFileSync — see the sandbox-tooling memory: write per edit and read back). It is landed
       now, with three things beside it:
     - **`Swarm_stash_of(ident, st)`** — the stash is a PARAMETER. Pass your own and the live-self guard
        stands down (it protects the SHARED stash; a caller with its own resource needs none). This is what
         makes any pillar testable at all.
     - **The sixth pillar, `%Reach`** (`Swarm_restash_reaches` / `Swarm_reaches_rehydrate`): standing
        bookings survive a reload, terminal ones stay buried. Without it "book it and walk away" — the whole
         SoundPooling premise — was false on a phone. The rehydrate finds-or-creates on the same triple
          (to · of · for) `Swarm_reach_book` uses, so it can never double a live booking.
     - **`SwarmReboot`** (Swarmation.g, 5 beats, 6 sworn, recorded live): populate a lived-in account →
        restash into a scratch stash → **WIPE** the tree → run the rehydrate ladder → swear the crew ledger
         + cert, the roster + my post, and the standing booking came back, that a settled reach did NOT, and
          that a second ladder pass doubles nothing. The first fixture that has ever touched the stash.
     **Still owed:** piers · izzes · chainroots stash through their own verbs (which carry side effects), so
      they are not yet `st`-threaded or in SwarmReboot — do that next, then consider the spin-out: stash the
       whole keyless account snap in Dexie (one blob rather than N pillars) so a phone gets exactly what a
        folder gives. That is the better model, but it wants SwarmReboot standing first to be safe.


1. ✅ **The library merge — BUILT + Book-gated (2026-09-03).** `Swarm_ferry_heard` peeks the blob: a
    keyless (cert-crew) snap MERGES the account's Peering rows (Idzeugs/piers/roster/Charter) into the
     Cave's OWN identity — rows about ME skipped, no second `%Identity` ever minted, so the keyless-husk
      persistence gap cannot form (the merged matter rides my identity's own persist path). A merged
       Cave's body key IS its identity key (stated on `.c.bodykey` so body_mine resolves). A KEYED blob
        keeps the legacy graft-beside path (in-flight old-model ceremony only). Gates: InvWalk 8/8
         (merged_into_self + no_keyless_husk + content_crossed; soul_key_copied ABSENT), InvFerry 6/6 +
          SwarmSpread 5/5 (both re-authored off the old soul-copy claims; SwarmSpread's ferry %see
           re-sworn to "folds it into its own identity … the soul key never crosses"), InvSeal 5/5,
            SwarmBody 23/23, SwarmFerry 1/1, SwarmStaple 8/8 (beat-7 friend-trust canary byte-identical;
             beat-8 roundtrip still `identical`). STILL OWED LIVE: a real reload on a linked device
              (library + Grant:Crew survive; which identity is active post-boot — the Door UI lies,
               check disk).
2. ✅ **The `/Crew` structure — LANDED (2026-09-03).** `/Crew/mate:<prepub>,role/Grant:'Crew'` minted at
    BOTH seal arms (Captain's own row + each mate's row; the grant homes on the row of the member it is
     FOR); `Swarm_crew_grant` reads `/Crew` first (legacy pier-scan fallback for pre-migration accounts);
      the ferry merge carries the bundle so both sides render the SAME ledger (InvWalk beat 6 swears
       `crew_row_holds_cert` + `captain_ledger_lists_crew`; snap shows identical /Crew on both piers).
        Mainkey is **`%mate`** — not `%Pier` (impersonation) and not lowercase `%pier` (`%Caperlet`
         already wears `pier:` as a property). Owed on top: Charter-as-signed-export not yet wired. (The Crew UI now reads /Crew and
          `Swarm_crew_tidy` prunes — §0.0.)
3. ✅ **SoundPooling over the crew — FIRST INCREMENT LANDED (2026-09-03, Book `MusuPoolFill` 6/6).**
    The pool-fill is a booked `%Reach,to:Cave,of:<id>,for:serve` (`Ra_pool_fill_book`), served by the
     Cave from its OWN library (`Ra_pool_fill_serve` → `Siphon_pull` → `Ra_press` →
      `Heist_catalog_land(mardir:'pool')` — zero new transport, the Siphonation-proven chain), landed
       Captain-side off the crew mirror (`Ra_pool_fill_land`), all under one knob-gated tick
        (`Swarm_reach_pump` → `Ra_pool_fill_pump`, `w.c.reach_on`). Honest refusal stands as
         `state:refused,why:not_in_library` on both sides. OWED: the live cross-device BYTE lane (the
          Mag-travels shape — a live fill currently ends Cave-side with the Captain's reach standing
           'arrived' awaiting transport); the booking gesture (owner-gated glass); then
            **daemon-as-Cave** (same ceremony, own identity + Grant:Crew) — the while-you-sleep system.
4. **A Book where a FRIEND honours the crew voucher** (third identity: Captain, Cave, friend — the
    verify road is crypto-proven but not Book-proven from a friend's seat).
5. **Finish the %Ferry req inversion against the new carry** (§6) + **Stage-4 fail-closed consent**
    (send gates on `req:FerryConfirm.finished`, NEVER on humdinger-absence — the fails-open hole) +
     the **%Reach cert-offer** (settles landed | refused,why | dead — every dead-end names itself).
6. **Retire the soul-copy path**: `Swarm_adopt_redeem` (~5902) still key-copies, and **SwarmSpread's
    beat-3 %see still SWEARS it** ("the soul seals across … now holds the very same soul key") — that
     sworn sentence is the retirement's Book gate: re-author beat 3 + retire the adopt key-copy
      together. `Swarm_ferry_heard`'s legacy keyed branch goes at the same time, once live-proven.
7. **Owner's live 2-device walk** of the rebuilt ceremony (cross-wire races are live-only by nature).
8. **Housekeeping:** eed's dead Caves now retire via `Swarm_crew_tidy` (§0.0); stop reload-piling (trust the ~30s relay
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

## 3. THE STRUCTURE — `/Crew/mate:<prepub>,role[,body]/Grant:Crew` (owner, 2026-09-03; `%mate` not `%pier`)

The Crew gets a HOME in the tree instead of existing only as a scan:

    /Crew
      /pier:<prepub>,role:<Captain|Cave|daemon…>
        /Grant:'Crew',by:<soul-pub>,for:<body-pub>,…

- **`%mate`** is its own mainkey — "a naming of a crew member" — whose value IS the join key (the
   `%Spotlight,src` idiom). It is NOT `%Pier` (a second shape wearing the transport mainkey would be the
    magazine-minted-`%Record` disease) and not lowercase `%pier` either (`%Caperlet` already wears
     `pier:` as a property — a mainkey must never appear as another shape's non-first key). `%Pier` in
      the Peering stays the one holding of the transport peer; `/Crew/mate:$prepub` points at it.
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
- Two shapes under one mainkey = the identity tell (why `/Crew` rows wear `%mate`, not `%Pier`).
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
