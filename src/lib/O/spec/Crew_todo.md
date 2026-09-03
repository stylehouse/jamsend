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

**▶ NEXT SESSION, IN ORDER (written 2026-09-03 evening for a compact; the owner: "prep for my next
 wanting-to-see-and-know session, possibly manual testing, and carrying on with wider developments").**

**A. SEE IT (10 min, both tabs on commit `03952ae1 Crewing` or later — reload both first).**
 1. Captain tab (eed, has a folder) Door: crew box lists ⚓ Captain Grav + 🏴 Cave Grewp **and nothing else**
    — the three dead Caves + two stale "Captain Grav" rows retire within ~60s (the trickle's tidy) or at
     once via `node scripts/runner_ask.mjs tidy crew --player=eed831f1977c4e81` (arm: socklog on + reload).
 2. Cave tab (incognito, NO folder — the phone-shaped life): Door lists ⚓ Captain Grav ● online + itself; the
    Captain's row wears a GLOW for ~4 min after a fresh link; **zero 🚪 unvouched rows** in the invite panel.
 3. **THE RELOAD PROOF (the one that matters):** reload the incognito Cave. Its Door must still list the
    Captain, `runner_ask crew --player=<cave>` must show `crew[].cert:1` on its own row, and the Captain's
     console must NOT show `🚪 rebuff %unvouched_*` from it. That is pillars 5+6 live (SwarmReboot proves
      them in a Book; this is the same thing on real Dexie). If it fails, the Book says WHICH pillar.
 4. Run a link ceremony again from scratch if you like: Link's last screen says "done", drops you in the
    Door on the glowing row; no "device link in progress" ghost.
 5. ⏰ still untested: "🔗 resurrect my Captain" (a Cave minting MyCaptain).
 Dial-in verbs: `runner_ask crew --player=<id>` (dump) · `tidy crew|rebuffs|forget:<pub>` (armed only) ·
  `console --grep='rebuff|🦑|🏴' --tail=40`.

**A½. TWO DESIGN QUESTIONS THE OWNER RAISED (2026-09-03 evening) — decide, then build:**
 1. ✅ **Crew ⇒ share — DONE the owner's way ("Crew better give Music grants as well").** The crew seal now
    mints `Grant:Music` both ways (seal arm → pier_accept `music:`; accept arm lands it, mints the reciprocal,
     rides it back in pier_confirm; `Swarm_confirmed` lands that), so `Swarm_share_granted` admits a crewmate
      with NO paradigm special-case (the trust agent's A-recommendation, ~8 lines; fixtures re-sworn: InvWalk
       4-8, InvFerry 4-6, SwarmReboot 2/3/5). ⚠ ONE BUG STILL BLOCKS A CAVE SERVING THE SOUL'S FRIENDS (trust
        agent, code-read): `Swarm_share_granted` / `Swarm_share_present` look up `Pier,pub:<peer>` with a BODY
         prepub and no `Swarm_pier_of_body` fallback (the hear funnel has one) — one line each; do it with
          MusuPoolBytes.
 2. **Moving the Captaincy** ("start as Captain on the box, then put the Captain on the phone and leave the
    box a Cave"). Captain = the ONE holder of the soul key, so this is a HANDOVER ceremony, not a role
     switch: (a) the box mints a link with the post CHOSEN (the Link's role drop-down — `Swarm_ferry_link`
      already takes `feature`, only the helm's default is role-derived); (b) a Captain link ferries a
       KEYED export (today's ferry is keyless `{ferry:1}` by design — the keyed flavour is the SwarmFerry
        Book's `{secret:1}`); (c) the box then DEMOTES ITSELF: mints a fresh own key, is granted Grant:Crew
         by the new Captain over the same wire, drops the soul key and re-homes its stash/account under
          its new prepub — the part that is NOT built and touches persistence (stash keyed by prepub,
           thang_put, the account dir). Friends never notice: they dial the soul, and the soul moved.
     ⚠ **"Caves by default resume the Captain" is BROKEN under cert-crew as built.** A Cave holds no soul
      key, so a Cave-minted MyCaptain link cannot hand one out; "recovery from a Cave" would mint a NEW
       soul and orphan every friendship. The glossary's answer is the Charter as RECOVERY: the Cave must
        carry a SEALED copy of the soul key (fc-code-locked, never readable by the Cave itself) — not yet
         built. Decide: (i) sealed key backup on every Cave (recovery works, one more secret at rest, sealed),
          or (ii) no recovery from a Cave — a lost Captain device = a new soul. (i) is the model's stance.
 3. **A location pool** ("one Pool taking from the Jam ledger, one for some defined location shuffled into
    me — e.g. a directory on the remote"): a compartment `%Pool,name,take:dir,from:<mate>,dir:<path>,cap`
     whose wants are that folder's tracks on the mate's catalog, shuffled, capped. The Pool cell's first
      form is therefore a FOLDER browser over the crew's union catalog (paths ride the catalog already) with
       one gesture: "shuffle this folder into my pool" = declare the compartment. That is the directory
        browsing the owner says is coming — folders, not files. Depends on (1).

 4. **The account on a phone — through OPFS, same protocol (owner 2026-09-03: "we want OPFS for SoundPooling
    with or without FSA … an OPFSWormhole talking the same protocol").** That backend EXISTS: `WormholeOpfs.svelte.ts`
     → `mount_opfs_pool_nav()`, mounted at `pool/` by `Wormhole_mount_pool` inside whichever MountNav stands (the
      share's, or the listen-only minimal one Housing stands for exactly this). So the pool is folder-blind already.
       **Decision to make:** also mount OPFS at `.jamsend/` on a folderless device (generalise mount_opfs_pool_nav
        to a subdir), so the account mirror + `Swarm_account_load` run UNCHANGED there — same paths, different
         backing. That retires pillar-counting (the six pillars stay as belt-and-braces, SwarmReboot keeps gating
          them) and beats the one-blob-in-Dexie spin-out: smaller, and it is the protocol doing its job. Eviction
           risk = Dexie's (both are the origin's site data; `navigator.storage.persist()` is already asked).
            Gate: a Book that boots a listen-only world, writes the account through the OPFS mount, wipes the
             tree, and loads it back — the folderless twin of SwarmReboot.

**B. THEN BUILD — pick by appetite:**
 - **SoundPooling, the byte lane** (SoundPooling_todo §0 ladder item 4, `MusuPoolBytes`): the Book that
    forces a served pool artifact's BYTES to land Captain-side. The feature the owner keeps asking for.
 - ✅ ~~The persistence gate, completed~~ — DONE 2026-09-03 evening: all six pillars take the stash as a
    parameter and SwarmReboot swears all six (7 sentences, 9/9 Books green). The one-blob spin-out is now
     SAFE to consider: it has a gate to stand under.
 - The %Ferry-only slog (§0.0 "half-spined") — a refactor; only if the ceremony misbehaves live.
 Do NOT start the one-blob account-in-Dexie spin-out before SwarmReboot covers all pillars.


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
     **✅ Completed the same evening:** piers · izzes · chainroots now take `st` too (`Swarm_pier_stash` /
      `Swarm_iz_stash` / `Swarm_chainroot_stash` + their rehydrates), and SwarmReboot's beat 5 runs the
       FULL station_up ladder in its order — sentence #7 swears the three oldest pillars back. **"Counting
        pillars"** (the owner asked): every durable shelf needs its own restash + rehydrate pair, six now,
         and a seventh is a silent phone-only loss until someone notices — versus stashing the whole keyless
          account snap in Dexie as ONE blob so nothing can ever be forgotten. That spin-out is now safe to
           design: SwarmReboot is the gate it stands under (flip its beat 5 to "the blob restores everything
            the snap would"), and the pillars become its belt-and-braces until it proves out.


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

## 4a. THE MODEL AS DECIDED (2026-09-03 evening, the owner's correction) — read this before §4

```
THE SOUL  S = (S.pub, S.key)      prepub(S) = "eed…" — the ONE name friends dial and grant to.
THE CREW  = the bodies that CARRY S.  Exactly one WIELDS it at a time (Captain = mutex); the rest HOLD it (Caves).

 ┌──────────────────────────── CAPTAIN (the box today) ────────────────────────────────────┐
 │ %Identity keys = S          ← wields the soul: hellos as "eed", signs vouchers with S.key │
 │   .c.bodykey = B            ← its own body key (its frames come FROM prepub(B))          │
 │   /Crew  mate:eed,role:Captain,body:B.pub                                                │
 │          mate:P,role:Cave,body:P.pub                                                     │
 │            Grant:Crew,by:S.pub,for:P.pub   ← the cert it signed for the phone            │
 │   Peering: friends' %Piers (Grant:Music), Idzeugs, %Body roster, %Charter, %Reach        │
 └──────────────────────────────────────────────────────────────────────────────────────────┘
                  │  LINK ceremony (QR + #fc): the ferry, SEALED by fc in transit
                  │  carries the ACCOUNT (Peering rows, /Crew, catalog…) AND S — pub and key
                  ▼
 ┌──────────────────────────── CAVE (the phone) ───────────────────────────────────────────┐
 │ %Identity keys = P          ← its OWN key: hellos as prepub(P), signs vouchers with P.key │
 │   .c.soul = S               ← HELD, not wielded (later: sealed at rest, code-unlockable)  │
 │   /Crew  the same ledger (merged); MY row holds the cert Grant:Crew,by:S.pub,for:P.pub    │
 │   Peering: the merged rows + my own %Reach bookings                                       │
 │   wire voucher = { pub:P.pub, sign:P.key, grant:<cert> }   "I am crew of eed"             │
 └──────────────────────────────────────────────────────────────────────────────────────────┘

 A FRIEND's door (its pier to "eed" imported S.pub at the seal):
   frame FROM prepub(P) + crew voucher → verify_grant(cert): by==S.pub ✓ for==P.pub ✓ sig by P ✓
   ⇒ trust the phone AS eed.   S.key was never needed on the wire ⇒ LOCKED copies work later.

 THE MUTEX: at any instant exactly ONE body has %Identity.keys == S.
 HANDOVER (box → phone) and RECOVERY (a Cave → a new device) are the SAME move, symmetric:
   phone:  .c.soul → %Identity.keys   and   P → .c.bodykey        "activate the held copy"
   box:    %Identity.keys → .c.soul   and   B → %Identity.keys    "stand down to Cave"
   then the new Captain signs a fresh Grant:Crew for the box's key, /Crew roles flip,
   the box's stash/account re-home under prepub(B).  Friends dial "eed" and reach the phone.
   A device therefore always holds exactly two keys: the one it wields, the one it holds.
```

**What this changes in what was built 2026-09-03 morning:** the ferry must carry S again (`Swarm_export` keyed for
 a ferry, sealed by fc as before), the merge lands it as `.c.soul` (held) — never as the Cave's acting key — and
  the three Book sentences that swear "the soul key never crosses" (InvWalk 6, InvFerry 5, SwarmSpread 5) are
   re-sworn to "the soul crosses sealed and is HELD, not wielded". Everything else (own key, cert, /Crew, the
    merge, the pillars) stands.

**⚑ REFINED LATER THE SAME EVENING (the owner: "the crap are you using .c for?" · "the Crew is the
 distributable, it contains the entire Crew's private keys and roles and grants" · "what is handover anyway?
  resuming a backup of Captain?").** The diagram above is right about the roads and WRONG about two things:
   nothing lives in `.c` (everything is snappable; `.c` is for WebAudio-grade runtime objects only — the
    existing `ident.c.keys` is a violation to migrate), and there is no two-key swap. The corrected picture:

```
 /Crew,soul:S.pub                      ← the crew's ONE name (what friends dial + grant to)
   Key,pub:S.pub,secret:S.key          ← the soul's secret, a PARTICLE (stripped by export protocol)
   mate:eed,role:Captain,pub:S.pub     ← the founder: its own key IS the soul (special case)
     Grant:… (the grants it holds)
   mate:phone,role:Cave,pub:P.pub      ← a mate: its OWN key; hellos + signs as P
     Key,pub:P.pub,secret:P.key
     Grant:Crew,by:S.pub,for:P.pub     ← the cert (proof to outsiders; enables LOCKED keys later)
     Grant:Music,by:S.pub,for:P.pub    ← crew shares music (the seal mints Music both ways)

 EVERY crewmate carries this WHOLE tree (the ferry moves it, fc-sealed).  So:
   "make X the Captain"  =  flip `role` on two rows.  NO key material moves — everyone already has it.
   the Captain            =  the mate whose role says Captain; it hellos + signs AS THE SOUL (S)
   a Cave                 =  hellos + signs as its own pub, proves crew by its Grant:Crew
   "resume from backup"   =  the same flip on a fresh device after any Cave ferries /Crew to it
   the mutex              =  at most one row says Captain — a RULE ("or data gets munted"), not crypto
 Which key a body wields is READ OFF ITS ROW'S ROLE — a snappable scalar, never a runtime flag.
```

 So the vocabulary is: **grant Captain** (a role choice on the Link: "make this device the Captain") and
  **resume** (the same, from a Cave, when the Captain device is gone). "Handover" was my word; retire it.
   A body that is never Captain still carries S — that is what makes resume possible from ANY crewmate, and
    why locking the secret at rest is the next step, not a new key road.

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


## 12. THE WHAT-IFS (2026-09-03 evening — three opus agents, briefed on §4a; code-read unless flagged)

**The five decisions these surface, distilled (decide these before the /Crew migration starts):**
1. **The mutex has ONE enforcement point today and the distributable breaks it.** The soul hello is gated on
   `if (ident.c.keys)` ("only a soul-key holder hellos the soul name"); once every mate carries S that guard
    admits the whole crew. The discriminator must move from key-POSSESSION to `role:Captain` on the row —
     across ~74 `.c.keys` reads in Swarm.g (154 repo-wide), incl. `Swarm_signas`, `Swarm_is_cave`,
      `Swarm_founding_grant`, `Swarm_family_heal`. The migration is mostly DELETION (`.c.bodykey` goes
       entirely under founder-pub == soul-pub). Proposed M0: narrow every read to `Swarm_signas` first, zero
        fixture movement, own commit.
2. **What munts under two Captains is last-writer-wins over convergent state, never a crash:** the account snap
   whole-file replace; two `next` counters issuing the same Idzeug serial and a snap overwrite UN-SPENDING
    claims; `Swarm_crew_tidy` on a stale ledger evicting a real crewmate; two %Reach bookings collapsing on
     the (to·of·for) triple so the loser settles a false `dead`; the relay's first-come door. The theft
      tripwire (`Swarm_note_theft`) is structurally blind (a second Captain is a rostered sibling). Detection
       needs a snappable tell: >1 row with `role:Captain`, plus a voucher clause for `pub === S.pub` from a
        non-Captain `from`.
3. **THE EPOCH (the biggest open question).** The role flip has no invite serial to hang on, and the laws forbid
   wall-clock compares — yet a monotonic soul-signed `/Crew,epoch` is what decides every race above (flip vs
    flip, the returning lost Captain, whether a booting mate may hello the soul name). A new ordering primitive:
     settle on paper first.
4. **Sealed-at-rest is not later polish; it is what PAYS for the distributable.** With clear `secret:` on every
   mate, a stolen Cave holds the soul, a %NotGrant against it is theatre, and any mate can write `role:Captain`
    on its own row. The Captain mutex is social (per the ruling) with nothing cryptographic behind it. Decide:
     does `sealed` land before the first Cave on a device you wouldn't physically trust? Corollary: revocation
      covers PRUNING; theft needs soul ROTATION + re-sealing every friendship.
5. **Two silent consequences of "nothing in .c":** `Swarm_export({ferry:1})` only knows how to strip a key on
   `.c.keys`, so a soul secret stored as sc crosses every ferry and lands in every mirror (fine in transit —
    fc-sealed; at rest it extends the account-snap landmine to every phone); and %NotGrant revocations ride
     PIERS, not /Crew, so a ledger ferry doesn't carry them and promoting a stale Cave UN-REVOKES mates. Also:
      `Swarm_restash_crew` stashes {mate, role, pub, grant} and nothing else — the moment keys are /Crew
       particles a folderless phone loses every key on reload unless the entry grows `%Key` + `/Crew,soul`
        (private keys in Dexie on a device that had none). A demoted box keeps its door binding until the socket
         bounces (the soul hello lives in `port.on_open`), so the flip must re-home explicitly.

Naming call wanted: `%Key` (lowercase `key` appears as a non-first sc key elsewhere; the §3 law reads as
 exact-string so capital `%Key` clears) or `%Keypair`. Proposed gates: **SwarmWield** (6 beats: the flip is two
  scalar writes, signas flips, a friend still trusts, and the failable tooth: a page/contact export containing
   no `secret:` anywhere) beside SwarmReboot.

### 12.1 The distributable /Crew
## THE DISTRIBUTABLE `/Crew` — the gang, its keys, and who wields what

The owner, 2026-09-03: *"everything basically wants to be snappable, unless it's some freaky edge
 where we're holding WebAudio objects"* — and *"the Crew is the distributable, it contains the
  entire Crew's private keys and roles and grants."* Both sentences indict one hoard: `ident.c.keys`
   and `ident.c.bodykey`, 154 + 59 touches, the biggest pile of hidden matter here — Homethink §4's
    first tell, worn for a year. Keys become particles under `/Crew`; what an export may SEE is
     decided at ENCODE time by protocol, where every other privacy decision here is already made.
      **Nothing lands in `.c`.**

### 1. The shape — the soul belongs to the CREW, not to a row

```
/Crew,soul:<S.pub>                        ← the crew names its soul ONCE, as a property
 ├ Key,pub:<S.pub>,secret:<hex>           ← THE SOUL KEY: one holding, under the crew
 ├ mate:Grav,role:Captain,pub:<S.pub>     ← the FOUNDER: own pub == soul pub, so NO Key
 │                                          child — /Crew/Key already IS its key
 ├ mate:Guw,role:Cave,pub:<P.pub>
 │   ├ Key,pub:<P.pub>,secret:<hex>       ← the phone's OWN key — every mate carries it
 │   └ Grant:'Crew',by:<S.pub>,for:<P.pub>,time,sign
 └ mate:Doze,role:daemon,pub:<D.pub>
     ├ Key,pub:<D.pub>,secret:<hex>
     └ Grant:'Crew',by:<S.pub>,for:<D.pub>,…

  THE SAME SUBTREE, BYTE FOR BYTE, ON EVERY CREWMATE.
  "put the Captain on the phone"  =  mate:Grav role:Captain→Cave
                                     mate:Guw  role:Cave→Captain
  No key material moves. The phone hellos as <S.pub> because its ROLE says it does.
```

**Laws.** `/Crew,soul` is the crew's identity; `/Crew/Key` is that soul's one holding — so **a mate
 row whose `pub` equals `/Crew,soul` carries no `Key` child**, because a second particle for the
  same secret is the magazine-minted-`%Record` disease. `mate:<name>,role,pub:<that mate's own pub>`,
   where `pub` is the key it signs its own frames with and that its `Grant:Crew` names in `for` —
    a rename of the `body:` field `Swarm_crew_row` already stamps, not a new column.

**`role` IS the wield scalar.** `role:Captain` ⇒ this body signs and hellos with `/Crew/Key`; any
 other role ⇒ with its own row's `Key`. One snappable scalar answers "which key am I wielding",
  legible in every fixture diff — never a runtime flag, and **never key-absence** (model 3 in §10,
   the build error that broke every `soul.c.keys`-gated seam). The founder's own pub *is* the soul
    pub, and that is not a wart: `Swarm_signas`'s first branch and `Swarm_crew_tidy`'s "ONE
     IDENTITY, ONE KEY" clamp (Swarm.g ~204) already behave exactly so. The model stops pretending
      there were two keys, and `.c.bodykey` is **deleted, not migrated**. A later Captain wields a
       soul that is not its own key — that is the general case; the founder is the degenerate one.

**Mainkey check:** `%Key` (capital) is unused as a mainkey. Lowercase `key` DOES appear as a
 non-first sc key (`Matstyle` dose maps, `DocMinimap`, `Swarm_import`'s transient root line), and
  the §3 precedent — `%mate` chosen because `%Caperlet` wears `pier:` — reads that law as
   exact-string, which clears `%Key`. *(One naming call I want confirmed; if the rule is
    case-insensitive, `%Keypair` is clean by the same grep. The `sc.key` seam that worries me most
     is the one this change deletes.)*

### 2. What each export sees — all of it at the protocol

`Swarm_protocol(kind)` (~4874) decides per mainkey; `Swarm_export` (~4900) picks kind off the ROOT
 mainkey — `%Identity`→`account`, `%Pier`→`contact`, `%Peering`→`page`. That does most of the work
  already: **`/Crew` hangs off the `%Identity`, so a `page` or `contact` export cannot reach it.**
   Add belt-and-braces anyway: `%Key` skipped for `page`/`contact`, `/Crew` onto `page`'s skip list
    beside `Pier`/`Idzeug`/`SocialGraph`.

- **The `.jamsend` account mirror** (`Swarm_account_save` ~5044) needs nothing added — secrets are
   in the snap because they are particles. `Swarm_snap_keyed` (~4918) and `Swarm_import`'s
    thaw-and-strip (~4934) become **deletable**: bespoke machinery removed, which is the measure of
     the change. The LANDMINE comment above `account_save` stays true and now covers more.
- **The ferry** (`Swarm_ferry_send` ~6537 → `Swarm_export(soul,{ferry:1})` → `seal(code,salt,blob)`
   under the `#fc` fragment): `{ferry:1}` stops meaning "strip the key" and starts meaning "the
    Identity ROOT line stays keyless" — secrets ride inside `/Crew`. Continuity worth naming:
     `Swarm_ferry_heard`'s peek (`got.C.sc.pub && got.C.sc.key`, ~6564) still tells a legacy keyed
      blob from a cert-crew one, **because the new secrets are not on the root line**.
- **Story fixtures**: the seam is `story_matching` (Story.svelte:1052, unioned with `entropy_rules`
   at 1226, walked by `snap_H` at 1270). One rule — `sc_has {Key:1}` ⇒ `omit_sc {secret:1}`.
    **Omit, not skip**: Book keys are deterministic (`Swarm_mint_keys(seed)`) so the hex would
     fixture fine, but no one can paste a key-laden fixture into a bug report — and keeping the LINE
      is the point. `Key,pub:<S.pub>` under a Cave's `/Crew` makes "this phone carries the soul" a
       snap-diff-visible fact, which `.c` denied outright.

### 3. Migration — counted, ordered, gated

`.c.keys`: **154** touches over 6 files (Swarm.g 86, Swarmation.g 54, Auto.svelte 5, InvFerry.g 4,
 InvWalk.g 3, daemon/main.ts 2). `.c.bodykey`: **59** over 5 (Swarm.g 20, Swarmation.g 28,
  Heistation.g 6, TwoFounder.spec.ts 4, InvWalk.g 1) — all of which **delete**. Production surface
   113; the rest Books. Inside Swarm.g the touch spreads over **≈44 verbs**: `Swarm_signas`,
    `Swarm_page`, `Swarm_is_cave`, `Swarm_crew_tidy`, `Swarm_voucher_mint`, `Swarm_station_up`,
     `Swarm_hello/_accept/_confirmed`, `Swarm_charter_sign`, `Swarm_export/_import`,
      `Swarm_account_save`, `Swarm_roster_save`, `Swarm_family_*`, the whole
       `Swarm_ferry_*`/`Swarm_adopt_*` block, `Diag_trouble`.

**M0 — narrow the door before moving it (zero fixture movement, own commit).** `Swarm_signas` calls
 itself "the one seam"; 86 direct `.c.keys` reads say otherwise. Sweep Swarm.g so the only readers
  are `Swarm_signas` (sign+route as me), a new `Swarm_soul_key` (act AS the soul — `charter_sign`,
   grant minting, `ferry_derive_secret`), and the export pair. Every other read is one of those
    questions in disguise. Gate: every Book green, every snap byte-identical.
**M1 — stand the particles.** `Swarm_identity` (~41) mints `/Crew,soul` + `/Crew/Key` + my row;
 `.c.keys` stays, written FROM the particles. Fixtures move once, at a declared seam.
**M2 — flip the readers.** `Swarm_signas` = "read my row's `role`; Captain ⇒ `/Crew/Key`, else my
 row's `Key`". Delete `Swarm_snap_keyed`, the import thaw, and all 59 `.c.bodykey`. If M0 was
  honest, fixtures do NOT move here.
**M3 — the ferry.** `{ferry:1}` carries `/Crew` whole; re-swear the three sentences §4a names
 (InvWalk 6, InvFerry 5, SwarmSpread 5) from "the soul key never crosses" to "the soul crosses
  sealed, and which body WIELDS it is a role".

**⚠ The one that gets forgotten: the stash.** `Swarm_restash_crew` (~3291) stashes
 `{mate, role, body, grant}` and nothing else; `Swarm_crew_rehydrate` (~3313) rebuilds from that.
  The moment keys are particles, a folderless phone — the whole reason that pillar exists —
   **loses every key on reload**. Grow the entry to carry `%Key` and `/Crew,soul`, and accept what
    that means: Dexie now holds private keys on a device that held none. It argues for §5.

**The Book — `SwarmWield`** (or SwarmReboot beats 6-8, the only fixture that has ever touched the
 stash). Swear: (1) the founder's row is `role:Captain,pub:<soul>` with no `Key` child; (2) a Cave's
  `/Crew` snap shows `Key,pub:<S.pub>` with `secret` protocol-omitted — the soul is carried and the
   fixture says so; (3) `Swarm_signas` on the Cave returns P, not S; (4) **the handover beat** —
    flip two `role` scalars, swear `signas` flips with them, no `Key` particle moved, and a friend's
     `Swarm_voucher_ok` still trusts; (5) **the tooth** — a `page`/`contact` export of that tree
      holds no `secret:` anywhere (a test must be able to fail); (6) restash→wipe→rehydrate returns
       every key and role.

### 4. "Carried, not wielded" — and the mutex it rests on

Carrying is not wielding, and one scalar a human can read in a snap is the whole difference. A mate
 row's `role` is authoritative for ME and **hearsay about everyone else** — `/Crew` is replicated,
  so two devices can disagree about who is Captain until the soul-signed export (the Charter, §3)
   reconciles them. And since every crewmate holds `/Crew/Key`, **any crewmate can unilaterally
    write `role:Captain` on its own row and start signing as the soul.** That is "there can only be
     one Captain or else data will get munted", stated exactly: the mutex is social and ceremonial
      and enforced by nothing else. Nothing cryptographic *can* enforce it — two wielders of one key
       are indistinguishable to every verifier alive. A data-munting hazard, not an auth hole.

### 5. Locked keys: same particle, one property over

`secret:<hex>` and `sealed:<b64>,by:fc` are the two states of a `%Key`, and **exactly one is
 present**. A `%Key` with `sealed` and no `secret` is carried-and-locked. Nothing new is needed
  cryptographically: the unlocker is the `seal`/`unseal` pair the ferry already runs (SwarmSeal-
   proven, fails closed) under a human-typed `#fc` code. The unsealed hex while wielding is the one
    freaky edge `.c` is for — it must never snap — so it lives as a memo with a lifetime
     (`ident.c.wielding`) while `/Crew` keeps only `sealed`.

This is not later polish, **it is what pays for the model.** §10 recorded that grant-certs deleted
 the "cryptographically unrevocable Cave" problem; shipping `/Crew/Key` to every mate brings it
  straight back, since a stolen Cave holds the soul key and a `%NotGrant` against it is theatre.
   Sealed-at-rest is the price of the distributable. Ladder: M0-M3 with `secret:` in the clear (no
    worse than today's `.jamsend` mirror), then `sealed` before any Cave is a device you would not
     physically trust.

---
**Read from code:** every count and seam; `Swarm_protocol`'s kind-by-root-mainkey behaviour; the
 lowercase-`key` collision and the `%mate` precedent; `Swarm_restash_crew`'s four-field entry;
  `Swarm_crew_tidy`'s one-identity-one-key clamp; the ferry peek surviving M3; `story_matching` as
   the fixture seam. **Guessed:** `%Key` vs `%Keypair` under the exact-string reading; "the founder's
    row carries no `Key` child"; the M0-M3 ordering; the `sealed`/`by:fc` pair; the SwarmWield beats.


### 12.2 The mutex — grant Captain, resume, and what munts

*Model (owner, tonight): the soul is a **crew-level property** — `/Crew,soul:<S.pub>` with S's
 secret as a particle beneath it; rows are `mate:<name>,role,pub:<own pub>`; every mate carries
  the WHOLE ledger, keys included; nothing in `.c`. "Make X the Captain" moves **no key material**:
   it flips `role` on two rows. Captain is a **role agreement**, enforced by nothing but the ledger.*

## The mutex, in code

Today it is enforced in exactly one place, by key possession — `Swarm.g ~1916`:
`if (ident.c.keys) { …hello the SOUL name… }`, commented *"only a SOUL-KEY holder hellos the SOUL
 name — that name is the crew's DOOR and contending for it is the whole collision this rebuild
  retires."* Under the new model every mate holds S, so **that guard silently opens to the whole
   crew**. It must become "my row says `role:Captain`". Same substitution at `Swarm_signas`,
    `Swarm_is_cave`, `Swarm_founding_grant`, `Swarm_family_heal`, `Swarm_family_grants_wire`:
     **74 `<x>.c.keys` reads in Swarm.g** (116 repo-wide on that pattern) now answer the wrong
      question. That is the largest mechanical consequence of tonight's ruling.

The flip's gift: **no grant is ever re-signed.** A `Grant:Crew` is `by:S.pub` and S does not move,
 so `Swarm_voucher_ok`'s friend-side `claim.by === held` keeps passing across any number of flips.

## What munts when two rows say Captain

Nothing crashes; everything is last-writer-wins over convergent state.

- **Account snap.** `Swarm_account_save` **whole-file replaces** `.jamsend/account/<prepub>/toc.snap`
   at the *soul* prepub, and `Swarm_account_settle` re-mirrors the whole ledger *it can see*. Two
    Captains on a shared or synced folder overwrite each other's entire account. This is the munting.
- **Idzeug serials.** Issuance winds `next`; spends tick `claimed:"3-5~9~14"`. Two Captains wind
   independently ⇒ **the same serial issued twice**, each admitting the other's redemption; then one
    snap overwrites the other and spends **un-spend** — the code's own words: *"a security fact, not
     a nicety."*
- **/Crew edits.** `Swarm_crew_row` merges in place with no epoch and no ordering. Then
   `Swarm_crew_tidy` — which retires any `%Body`/link `%Pier` "no mate backs" and settles to disk —
    runs on a stale ledger and **evicts a real crewmate**.
- **%Reach.** Both Captains book the same `(to·of·for)`; the Cave's `Swarm_reach_heard`
   find-or-creates on that triple, collapses them, serves once. The loser settles
    `dead, why:'nobody-answered'` — a **false receipt**, the "every dead-end names itself" law inverted.
- **Roster gossip.** `Swarm_family_heal` prunes only on the seat, then gossips the shrink. Two
   writers prune each other, re-learn by gossip, prune again — `after !== before` every pass, so
    `account_settle` fires every pass. Permanent write amplification.
- **The door.** First-come binding. The loser is clamped to bare, answered with a suffix, logs
   *"the door (…) is held by a sibling body"* — and per Swarm.g's note `to:<soul>` flows to the
    holder alone while every `_N` **dies client-side**. Half your friend traffic silently misrouted.

## Detecting a second Captain

The existing tripwire is **structurally blind**: `Swarm_note_theft` returns false for a known
 sibling (*"A ROSTERED SIBLING'S PULSE IS PRESENCE, NOT THEFT"*), and a second Captain is rostered
  by construction. Two tells to build, both snappable: **(1) ledger-local** — more than one row with
   `role:Captain`, reified as `/Crew/Contest,role:Captain,by,at` (the `%Stolen` shape on the crew
    shelf); **(2) on the wire** — a voucher with `pub === S.pub` whose `header.from` is not the
     Captain row's prepub, one clause at the voucher gate (~1509/1547). The only tell today is the
      door-held console line. *(Guess, unverified: era/seq churn on one `from` is a friend-side
       symptom; the laws forbid building a detector on era compares.)*

## (a) THE FLIP — box → phone

Both carry `/Crew` already, so nothing ferries.

    BOX (Captain, holds door prepub(S))          PHONE (Cave, already holds /Crew + S)
    ───────────────────────────────────          ─────────────────────────────────────
    Link cell → "hand the helm to…" → the phone
        │  sibling_send (pier-less, same-soul — the law)
        │  { kind:'crew_role', mate:<phone>, role:'Captain',
        │    epoch:n+1, sign:<by S.key> }
        ▼
                                     verify sign against /Crew.sc.soul   ✓
                                     epoch > my /Crew.sc.epoch           ✓
                                     mate:<phone> role → Captain
                                     mate:<box>   role → Cave
                                     epoch = n+1 ; account_settle('helm')
                                     ── re-hello: now hellos prepub(S) ──
        │◀────── { kind:'crew_role_ok', epoch } ──────
        ▼
    mate:<box> role → Cave ; mate:<phone> role → Captain   ⚠ PROMOTE FIRST,
    epoch = n+1 ; account_settle('helm')                      DEMOTE ON THE ACK
    ── drop the soul door: re-home / bounce the socket ──
        ▼
    roster gossip carries the roles onward; friends notice NOTHING —
    they dial prepub(S), which moved rooms, not identity.

**Failures.** (1) *Phone dark after the box demotes* → no Captain at all: every `to:<soul>`
 dead-ends and the crew reads offline to every friend. Hence demote-on-ack: a brief two-Captain
  window converges, a no-Captain window strands people. (2) *Box reloads mid-flip* → safe if the
   role write reached durability. On a folder device that is `account_settle`; on a **folderless
    phone there is no account snap at all** and it rides `Swarm_restash_crew`, which I confirmed
     already stashes `mate/role/body/grant` — **so `role` survives a phone reload today, for free**.
      It does *not* stash `pub` or any secret. (3) *The socket never bounces* → the soul hello lives
       in `port.on_open`, which fires on open/reconnect only, so a demoted box **keeps its door
        binding** and the new Captain loses the race. Sharpest and least obvious of the three; the
         flip must explicitly re-home. (4) *Both sides flip at once* → only an epoch saves you.

## (b) RESUMING — the Captain device is lost

Same act, with a ferry in front because the target holds no ledger.

    CAVE (holds soul pub+secret, all rows,       NEW DEVICE (fresh)
          all grants)
    ──────────────────────────────────           ──────────────────
    "take the helm on another device"
      → Swarm_ferry_link(w, ident, base, 'MyCaptain')
        (the helm ALREADY takes `feature`; only its default
         is role-derived — the drop-down is UI only)
      → base + '#Iz=' + token + '&fc=' + secret
        │ QR / physical channel; fc rides the FRAGMENT
        ▼
                            scan → knock → seal; link arm sets pier.sc.post='Captain'
                            (Swarm_post_from_feature('MyCaptain') = 'Captain')
        │  ferry: fc-sealed blob = the WHOLE /Crew —
        │  soul pub + secret + every mate row + every grant
        ▼
                            merge into own identity; /Crew lands whole
                            my row role:Captain ; the lost row role:Cave
                            epoch n+1 ; settle ; hello as prepub(S)

**If the lost Captain returns**, it rehydrates *its own* year-old `/Crew`, still reading
 `role:Captain` for itself, and hellos the soul door. It learns it was demoted **only by hearing a
  newer ledger** — crew/roster gossip carrying `epoch > mine`. Until then it is a genuine second
   Captain: it loses the door if the new Captain is online, wins it if the new Captain is asleep,
    and its stale snap will happily overwrite on the first shared-folder mirror. **The new
     invariant this demands: a booting mate must not hello the soul name until it has heard a crew
      frame confirming its epoch is current.** Fail-closed; the code has no equivalent today.

## The Cave never promoted, over a year

It is a complete offline copy of the soul. **Staleness is the whole risk**: mates added since are
 absent and — worse — mates *revoked* since are still present, because `%NotGrant` rides piers, not
  `/Crew`, so a ledger ferry **does not carry the revocations**; promoting that Cave un-revokes
   them. The owner has already accepted destructive resume (*"destructive if the surviving copy was
    stale, which is accepted"*), so the goal is **visible** staleness — home `%NotGrant` under the
     mate row so it ferries, stamp `/Crew.sc.as_of`, show it on the resume screen.
**Key rotation does not exist** (code-read: no rotate verb anywhere; the only key change is the
 merge's forced one-key + `caveat:remint`). Rotating S means re-signing every grant and re-sealing
  every friend pier, since a friend's pier imported `S.pub` at seal — so a Cave in a drawer is a
   permanent full-soul compromise. That is the honest price; rotation would need a signed
    "S2 succeeds S1" atom, unbuilt.
**New at-rest exposure:** `Swarm_export(n,{ferry:1})` strips the key today, but only a key on
 `.c.keys`. A secret living as sc under `/Crew` **crosses every ferry and lands in every mirror
  automatically**. In transit that is fine (fc-sealed); at rest, `Swarm_account_save`'s ⚠ LANDMINE
   now applies to *every* mate, phones included (Dexie, not a folder). LinkDevice's "TOTAL TRUST /
    unencrypted at rest" blurb is now literally accurate.

## Wording

Today: `my_role === 'Cave' ? '🔗 resurrect my Captain' : '🏴 muster a crew mate'`, with "resume from
 backup: this Cave carries the whole account". "Carries the whole account" is finally *true*;
  "resurrect" is wrong for the everyday case. Split by whether a Captain is live — **"hand the helm
   to…"** (mate picker, no ferry, no backup language) · **"take the helm — this crew has no
    Captain"** · **"put the Captain on a new device"** (ferry then flip). Keep "a new Captain
     replaces the old one" everywhere: that is the mutex in one line. Note too that several
      LinkDevice titles saying "copies your whole soul" were on the smoothing list as *stale* —
       under tonight's model they are **correct again**; re-read that list before deleting.

## One session vs. needs design

**One session, all Book-gatable:** `Swarm_i_am_captain(ident)` off the row, swapped into the ~1916
 soul-hello gate and `Swarm_signas` · the role drop-down (`Swarm_ferry_link` already takes
  `feature`) · the `crew_role` frame on the existing pier-less `Swarm_sibling_send` lane · the
   two-Captain detector + `%Contest` · `Swarm_restash_crew`/`_rehydrate` extended to `pub` + soul ·
    the row-shape migration (`mate:<name>` + `pub:`) across `crew_row`/`crew_view`/`crew_tidy`/
     `crew_grant`/`restash_crew` · the wording split.

**Needs design first:** (1) **the epoch** — the flip has no invite serial and the laws forbid
 wall-clock compares, yet a signed monotonic `/Crew.sc.epoch` decides every race above; get it
  right before any code. (2) `%NotGrant` inside the ledger so revocation ferries. (3) The
   fail-closed return rule, and what a mate does when nobody is online to confirm its epoch.
    (4) Rotation, or the explicit decision never to have it. (5) Whether the soul secret is snapped
     readable or sealed at rest — "nothing in `.c`" makes it snappable, not safe.


### 12.3 Trust — proving crew to outsiders, sharing inside, revocation
## TRUST — proving crew to outsiders, sharing inside the crew, and revocation

**[code]** = read in `Ghost/S/Swarm.g` / `src/lib/O/Funk/Grant.ts`. **[guess]** = proposal or inference.

### 1. What a friend actually verifies

The road is the hear funnel → `Swarm_voucher_ok` (Swarm.g:1512), and it is **stateless**: no ledger fetch,
no Charter read, no era compare **[code]**.

```
      Cave (phone, own key P, holds Grant:Crew by S for P.pub)
             │  frame: header.from = prepub(P) ── relay routes on header.to ONLY
             ▼
 ┌── A FRIEND'S DOOR (its %Pier to "eed" imported S.pub at seal) ──────────────────┐
 │ 1 RESOLVE the pier            Pier,pub:from?          → miss (a body ≠ a friend) │
 │   Swarm.g:1196-1206           Swarm_pier_of_body?     → contact-learned %Body    │
 │                               else Pier,pub:prepubOf(vh.pub) → the SOUL's pier   │
 │ 2 GATE (station_up only,      no voucher / any fail ⇒ Swarm_rebuff               │
 │   pier_hello exempt)                                 'unvouched_<type>' + DROP   │
 │ 3 Swarm_voucher_ok — cert-crew arm (vh.grant && vh.pub !== held):                │
 │     (a) prepubOf(vh.pub) === from ............ 'crew prepub mismatch'            │
 │     (b) verify_grant(vh.grant), ed25519 over . 'crew grant bad signature'        │
 │         sorted-key JSON of the whole claim                                       │
 │     (c) claim.by === held (S.pub off the pier) 'crew grant not by the sealed soul'│
 │     (d) claim.for === vh.pub ................. 'crew grant not for this body'    │
 │     (e) verifyHeader(FLAT {control,from,pub,   'crew body signature bad'         │
 │         era,ts,sign}, [vh.pub])                                                  │
 │   all five ⇒ sealed.c.voucher_ok = vh.sign (cache) ⇒ trust the Cave AS eed       │
 └─────────────────────────────────────────────────────────────────────────────────┘
```

**Forged** cert fails (b). **Stolen** (replayed on another body) fails (d) — `for` binds a pubkey the thief
can't sign with — and (e). **Wrong-Captain** fails (c). **Tampered**, any field, fails (b): `by`/`for` ride
*inside* the signed domain (`Grant.ts` claim_json) **[code]**. `crew-cert-test.ts` 6/6 hammers all four.

**Stale is the hole.** No `until` by design, no era monotonicity in `voucher_ok`, no revocation read on the
cert-crew arm **[code]**. A cert valid once is valid forever, at every friend's door.

**Inside the crew nothing else is checked, and `/Crew` is not the gate.** Crewmate→crewmate frames take the
same `Swarm_voucher_ok`; the Captain's own pier to its Cave hits the "crew member that is also the sealed
counterparty" arm (1576). `/Crew` is read only by `Swarm_crew_grant` (which cert do *I* present),
`Swarm_crew_view` (the Door) and `Swarm_crew_tidy` (pruning) — no authorisation decision reads a mate row
**[code]**. Keep it that way: the ledger is the picture, the cert is the proof.

### 2. The A-vs-B fork — recommend **A**

The §0 A½ symptom checks out. `Swarm_share_granted` → `Swarm_pier_live(p,'Music')` (3857/4775); a crew pier
carries `link:1, post:Cave` + `Grant:Crew` and no `Grant:Music`, and the stamp arm fires only for `My<Post>`
features, so `'Music'` reads **false** **[code]**. Downstream `Swarm_gossip_music` (3714), the share-beat
offer loop (4534), `Swarm_offer_to` (3951) and `Swarm_ive_got_tally` (3836) all skip the mate → no
`%MusuThem` crate → `Ra_pool_fill_homes` returns `from:null` and the fill reach stands 'arrived' forever
(Ra.g:4410) **[code]**. One missing grant explains the whole dead byte lane.

**A** — at `Swarm_hello`'s link arm (2606-2645) mint a second atom beside `crewgrant`, pass it as `myGrant`
to `Swarm_seal` (which lands *and stashes* grants, 2976/3076) and carry it on `pier_accept` under a new field
(`grant` is taken by the cert); at `Swarm_accept`'s link arm (2680-2700) verify, land, mint the reciprocal;
land that at `Swarm_confirmed` (2770). ~4 sites, ~8 lines, no new gate, persistence free.

**B** — for Music alone that is the 5-6 callsites above, each needing "or a `/Crew` mate", each a place to
forget the `%NotGrant` check `Swarm_pier_live` gives for free; every future paradigm re-litigates it.

**A wins:** smaller, reuses the revocation law (a crew Music grant tombstones like a friend's), keeps consent
one-shaped. Cost: a durable consent artifact that can drift from `/Crew` — mitigated, `Swarm_pier_forget`
already revokes every non-`My<Post>` feature on the pier (4749) **[code]**.

**A does not fix the friend lane, and that half is a resolution bug.** `Repli_allowed(w, h.from, h.to)`
(Repli.g:949) hands `Swarm_share_granted` a *body prepub*; the lookup is `o({Pier:1, pub:peer})` with no
`Swarm_pier_of_body` fallback, unlike the funnel **[code]**. So a Cave can't pull from the soul's friends and
they can't pull from it, whichever fork wins. Give both hooks (3857, 3876) the funnel's body→home-pier
resolve — one line each, orthogonal, **do it first**. (Gate: the missing friend-honours-crew Book, §0 item 4.)
**Daemon-as-Cave** rides A unchanged — and is the case that makes §4 urgent.

### 3. Revocation that travels

Today `Swarm_revoke` writes a signed `%NotGrant` under my own pier, honoured locally by `Swarm_pier_live`,
and `Swarm_pier_forget` drops the mate row under the comment *"Local only — revocation does not travel yet"*
(4753) **[code]**. The Cave keeps its cert; friends never hear.

**Minimal mechanism, on a mile that exists.** `Swarm_family_grants_wire`/`_absorb` (5282/5304) already ships
soul-signed atoms, far-side-verified, filtered to my own signature, capped at 32 **[code]**. Three additions
**[guess]**: (1) `Swarm_crew_revoke` — `mint_revoke(soul key, matepub, 'Crew')` homed as `%NotGrant:Crew` on
the mate's `/Crew` row, stashed by `Swarm_restash_crew`; (2) carry tombstones on the **friend** leg of
`Swarm_charter_gossip` (6226-6230), which today sends `charter` only — and since the Charter is meant to *be*
the signed export of `/Crew` (§3), they belong inside it, not beside it; (3) one check in the cert-crew arm
after (d): no `%NotGrant:Crew` on `sealed` matching `by`+`for` → `nope('crew grant revoked')`. Local, cheap,
still no fetch. **A friend then rebuffs that body as `unvouched_*`; the soul is untouched — the point of the
pivot.**

**Say the limit out loud:** gossip reaches whoever you talk to, so an offline friend keeps trusting a revoked
Cave. Fine for a prune. **Not** fine for a stolen device carrying §4a's sealed `.c.soul`: there, revocation
is not enough — the Captain must **rotate the soul** and re-seal with every friend **[guess]**. The sealed
backup buys recovery at the price of making theft unrecoverable by revocation alone.

### 4. Scoping — `Grant:Crew` is total impersonation

The cert is `{to:'Crew', by, for, time, sign}` and every verifier reads it as "act AS the Captain" **[code]**.
The seam exists: `mint_grant(grantor, granteePub, to, opt, time)` folds `opt` into the signed claim
(`Grant.ts:62`), and there is a working precedent for reading one at enforcement — `claim.mode === 'ro'` in
`LiesFunk.svelte:724` **[code]**. **Yes, scope the daemon:** `{ scope: 'music' }`, absent `scope` = total so
fielded certs keep working **[guess]**. This is where a *little* of B is right: **A for the grant, B for the
scope check** in each paradigm. Caveat: nothing reads scope today — ship the reader in the same change, or a
scoped cert only *looks* limited.

### 5. Forgotten Cave, shared friend grants

A merged Cave holds the friends' `Grant:Music` atoms, but they are `by: friend, for: S.pub` **[code]** —
forgetting cannot un-give them. Before the travelling tombstone, forgetting revokes nothing outside your own
tab and the Cave keeps using them. After, the friend's door refuses it; the atoms stay on its disk and stay
useless — the same shape as `Swarm_revoke` never deleting a Pier ("the durable memory keeps its history",
4713). The Door should say so: today `✕ forget` prunes and prints a reassuring line; the honest sentence is
*"this device can no longer act as you — once your friends hear about it."* **[guess]**
The asymmetry to design for: the friends' grants are `for` the **soul**, so a revoked Cave that keeps serving
isn't using a stolen credential of its own — it is impersonating. That is why the tombstone must reach the
friend, not the Cave.

