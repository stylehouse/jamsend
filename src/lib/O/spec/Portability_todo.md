# Portability_todo.md

Account portability — one **soul**, many **bodies**: carry an identity to a second device, let
 each body do the work it is placed to do, and hand authority around without corrupting the
  ledger or doubling yourself on the wire. The two bodies that matter are the **Captain** (the
   phone in your hand) and the **Cave** (the deep, stable, disk-bearing machine at home).

> Status: working `_todo`, written spec-close but **not** self-promoted. Mechanics are verified
>  against the code (inventory in §11); the design is proposed and wants the human's preen.
>
> Sibling docs: **`Onboard_todo`** owns the first-run funnel. **`Daemon_todo`** owns the
>  phone-commands-station-executes verb arc (pokes, `PLAYER_OPS`). **`Identity_persist`** owns
>   the account mirror + disk write-lease mechanics this doc leans on (§7.4 especially).
>    **`Cluster_spec` §3** owns the relay. (`MobilenoFSA_todo` was folded here 2026-08-26 and
>     deleted; its dated rulings — the LinkDevice ceremony 2026-08-14, the listening-only
>      wire — live on below and keep their dates; its serial-block-lease ruling was
>       SUPERSEDED 2026-08-27 by Captain-only invites, §2C.)

---

## 0. Where to start, and the arc

**The destination.** A person's phone is the **Captain** — the soul's home, the social hand —
 and it needs no folder access at all. A station with a real filesystem is the **Cave** — where
  the library lives, where Heists are fulfilled, where everything is backed up. What you'd
   Heist wanders to the Cave and waits there as treasure; music flows back to the phone as a
    **SoundPool** — LOFI listening copies in OPFS — and two phones meeting in the world can
     swap SoundPool material directly, seeding introductions their Caves later fill out as
      Originals. Authority stays with the Captain; durability lives with the Cave; and no step
       double-spends an invite or doubles a name on the wire.
  The funnel (ruled 2026-08-14): the phone is the FIRST TOUCH — cold arrival → listening only
   → LinkDevice → the same identity on a capable station does the heavy lifting.
  And a working bet to hold loosely (the owner, 2026-08-26): **pool↔pool exchange between
   phones may be the MAJORITY way music actually moves** — most transfer live and LOFI, hand
    to hand, with the Caves as the archival minority that HIFI-ifies what the pools discover.
     Design the pool paths as primary, not as a nicety bolted onto the library.

**What already exists** (so this is wiring, not invention):
- The **identity ≠ address** split, with suffix machinery: bare `<prepub>` is the primary
   place, `<prepub>_1` a second body's place; Piers verify by `pub`, so a suffix costs routing,
    never recognition. `Swarm_next_suffix` / `Swarm_steal_back` / `Swarm_reinstate` exist.
     (§4, §11)
- The **LinkDevice ceremony**, ruled (2026-08-14): a live self-Invite on the invite rails —
   high-entropy, single-use, short-lived, both devices online, account frames encrypted under
    a code-derived key, matching-emoji confirm. (§7)
- The **Captain-only invite ruling** (2026-08-27, superseding the earlier block-lease
   design): the Captain takes care of all Invites; Tier C has one writer by role, so there
    is no spend-merge problem at all. (§2C)
- **OPFS plumbing**: `WormholeOpfs.svelte.ts` — an overlay nav speaking the same
   read_file/write_file/dir contract as every other nav. The SoundPool has a nav shape to
    ride. (§3, §11)
- The **disk write-lease** (`Identity_persist` §7.4f) and the **👥 collision tripwire** (a
   frame from our own key raises the alarm) — the safety rails under any handoff. (§8, §11)
- **Transcode machinery**, Cave-side: the daemon's native ffmpeg stocking (probe|measure|
   encode) and Radio's demand-driven transcode path — the HIFI→LOFI press already runs. (§3)

**What is missing** (the work this doc scopes):
1. **The wire is not plumbed to the address.** `Socket_real` dials `peering.sc.name` (bare),
    captured once; a Steal Back moves a field the relay never hears. (§4, §11)
2. **The SoundPool itself** — the OPFS audio shelf, its ledger, its cap, its eviction, and
    the pool record's path scheme. (§3)
3. **The loosened landing head** — the Heist's landing seam assumes the real-FS share today;
    it must write through ANY nav (the OPFS nav speaks the same contract), so a Heist can land
     **in a pool** as readily as in a library. (§3)
4. **The pool exchange** — phone↔phone LOFI swap, live, no Cave required — possibly the
    majority transport (§0). (§5)
5. **The smuggle** — Captain→Cave backup of the SoundPool *and* the account. (§5)
6. **`%Invite:MyCave`** — the role invite on the existing %Idzeug rails, plus the graft
    ceremony around it. (§7)
7. **The quick/still lease + adoption handoff** — who may touch the consumable ledger, and
    how a daemon takes over cleanly. (§6, §8)
8. **The Door dialogue** — Invite-yourself in the Door, opening the portability explainer.
    (§9)
9. **The phone push, in flight** (ruled arc — "at least it does radio", 2026-08-19):
    (a) THE release gate — verify on a real phone that a friend's stream actually plays in
     `listen_only`; concrete risk: no nav in that mode, so if any tune-in/jam-join path needs
      a nav WRITE, radio silently no-ops on device while dev looks green — field trip only.
       (b) `navigator.storage.persist()` at boot — one line, auto-granted once PWA-installed;
        the cheap mitigation for "clear browsing data = identity death". (c) the 🎧 badge on
         Door's self line + the mortal-identity whisper — `H.c.listen_only` is read NOWHERE in
          the UI today; the badge makes the mode legible, and is where to whisper that a
           shareless identity is mortal until LinkDevice lands.

**LANDED 2026-08-27 (the night build — commits rehome · holdings · cohort · invitep):**
- ✅ **The wire dial** — `Socket_real` reads `address ?? name` fresh per connect (`home()`),
   gains `rehome()`; `Swarm_steal_back`/`Swarm_reinstate` call `Swarm_rehome(ident)` which
    syncs the station Peering and re-dials. A Steal Back now reaches the relay.
- ✅ **The cohort v1** (`Swarm_cohort_vessel/primacy/stand` in Ghost/S/Swarm.g's places
   region — a GHOST, by the Socket_real raw-browser-API precedent — + the SwarmStandup gate +
    the `Swarm_station_up` consult): Web Lock decides profile primacy (zero staleness,
     auto-release on tab death), BroadcastChannel census names `taken` and registers
      `%Sibling`s (that verb's first app-path caller — family no longer trips the 👥 alarm),
       and a non-primary tab suffixes BEFORE its first dial. The second tab quietly becomes
        the second tab. NOT yet live-verified with two real tabs — the next session's first
         proof. An address change also ROLLS THE ERA (`Swarm_rehome` re-mints station_era +
          drops the voucher), so peers treat a moved body as the rebirth it is.
- ✅ **`Ra_holding_keys()`** — the one authority on holding mainkeys; the three
   silently-failing seams (Repli_merge ×2, Repli_recv_lines breadcrumb, Repli_find_record)
    now ask it. Byte-identical today (set = `['Record']`).
- ✅ **`%Invite` autovivify** — `Swarm_invite_note` on the station world (export-blind,
   Book-blind home); InvitePanel vivifies on parse, `Swarm_redeem` walks it to `redeeming`.
    `sealed|refused` land with the Door work.

**LANDED 2026-08-27, WAVE 2 (commits arbiter · hellov2 · poolmount · doorface · cohortbook):**
- ✅ **Relay hello-v2 arbiter** (`relay.ts`, relay-test green): a signed hello may carry
   `want:<addr>`; the relay grants it if free, else binds the next free `<prepub>_N` and
    answers `hello_ok {addr, taken}`. Err-toward-suffixing; a dead incumbent's seat frees in
     ~30s (heartbeat). No `want` ⇒ byte-identical v1. This is the CROSS-MACHINE decider the
      local cohort census cannot be (it sees one browser profile).
- ✅ **hello-v2 client** (Swarm.g `on_hello` adopt hook + Tribunal.g surfacing): the station
   sends `want: Swarm_address(ident)`, adopts the relay's granted addr, and rehomes if it
    moved. Converges in one extra dial. Compiled; live-unproven (needs two machines on one
     relay).
- ✅ **Pool mount** (`WormholeOpfs.OpfsPlainNav` + Housing `Wormhole_mount_pool`): a `pool/`
   path routes to an OPFS nav via MountNav's existing prefix routing — so `%Record.sc.path =
    "pool/…"` reads/writes OPFS exactly as `music/…` reads FSA, ZERO serve-seam changes. Free
     gift: `w.c.mardir = 'pool'` already routes a whole heist into OPFS. (Phone no-share path
      is the one gap — it uses a raw OpfsOverlayNav, not MountNav; one wrap when wanted.)
- ✅ **Door surfaces** (DoorFace + new InviteYourself.svelte): the bodies line (this body's
   place + primary + siblings, null when unremarkable), the Invite-yourself dialogue (explains
    portability, LinkDevice QR stubbed honest), and %Invite rows (arrived/redeeming visible).
- ⚠️ **SwarmCohort Book** (Swarmation.g) — **its green is HOLLOW; do NOT trust or gate it as-is
   (caught 2026-08-27).** The `.g` authors 5 real beats (2–6: Swarm_sibling recognition,
    Swarm_note_theft family-vs-foe, Swarm_next_suffix berth, %Invite autovivify + idempotency +
     state-walk), each with a live `%see` witness — but the recorded Story **Plan is a 1-step
      stub**, so the runner advances `step_n` to 1 only and beats 2–6 (gated on `step_n===2..6`)
       **never fire**. Evidence: `runner_ask steps` returns `steps:[{n:1,ok:1}]` and `001.snap`
        is the empty settled world (no Alice, no Sibling roster, no %Invite); compare SwarmStaple,
         same convention, which runs `n:1..8` with `001–008.snap`. Neither Book declares its step
          count in source — the count comes ONLY from the recorded Plan/`NNN.snap` set, authored
           in the Story EDITOR (Storui), NOT via `runner_ask` (`accept` re-records only what
            actually ran = 1 step; check-mode caps at the recorded-snap count). **The fix is an
             editor authoring pass** that walks beats 2–6 and records `002–006.snap`; the CLI
              cannot bootstrap it, and hand-writing the snaps would be a forged gate. Until then
               the green means "the empty wrangle stood up", nothing more. **Do NOT commit
                `wormhole/Story/SwarmCohort/` — it would gate a hollow run.**
- ✅ **Regression closed**: the %Invite vivify was snapping onto Book worlds (SwarmStaple/
   SwarmInvite red); gated on `station_up` (Books never set it); both GREEN on live runner now.

**ALSO LANDED (off-lane, the owner surfaced it):**
- ✅ **Supervisor orphan cull** (`Supervisor_cull_orphans` + `auto_teardown_story` call):
   each Book the runner runs left its Watch/Dial rows on Mundo's Supervisor (they OUTLIVE the
    run by design, `Supervisor.g:189`; `Supervisor_alive` only stamped them 'unknown' per tick,
     never dropped them). Now `auto_teardown_story` drops every orphan (subject world detached)
      at the one instant it is cheap and certain. Scope falls out of `Supervisor_alive` — a
       null-subject boot milestone survives, a run world's watch is culled — so it needs no
        run-ownership tag, which is the owner's "virtualise to H%Story" instinct achieved
         WITHOUT moving the world. The bigger overlay-virtualisation (a per-run sub-roster
          under H%Story) stays the recorded direction; this cull is forward-compatible with it.

**VERIFICATION LEDGER (be honest about what is proven):**
- GREEN on live runner (2026-08-27 re-confirmed): SwarmStaple (`n:1..8`, all ok) + SwarmInvite
   (the regression, closed). LocalGen compile: Ra/Heist/Repli/Swarm clean, zero gen churn.
- relay-test.ts GREEN: the hello-v2 arbiter (relay side).
- ⚠️ **NOT actually proven — was a false green: SwarmCohort.** It runs 1 hollow step; beats 2–6
   never fire (see the ⚠️ entry above). Its verbs (sibling/note_theft/next_suffix/%Invite
    autovivify) are UNPROVEN at the Book layer until the Plan is authored to 6 steps in the editor.
   **Blast radius is exactly this one Book** — a disk audit of recorded step-snaps shows every other
    Swarm Book properly authored (SwarmStaple 8, SwarmGot 9, SwarmShare 9, SwarmPolicy 8, SwarmDisk
     7, SwarmSteal 6, the rest 5); only SwarmCohort sits at 1. The established suite is genuinely gated.
- NOT cleanly live-proven, needs a session with the right infra: the hello-v2 CLIENT adopt
   path (needs two machines on one relay); the cohort two-tab case (needs two real tabs); the
    Supervisor cull's cross-Book non-drift (Sounditron is environmentally red for friend-
     streaming so it can't prove it — gap evidence says safe, but a two-Book sweep or a
      dedicated model Book beat is owed); pool landing (proven INERT — no Book sets
       mardir='pool' — so nothing exercises it yet).
- Fixtures: **do NOT commit `wormhole/Story/SwarmCohort/`** (hollow gate, above). All other
   wormhole churn is run-volatile and should be reverted, not committed.

**RESOLVED BY DESIGN 2026-08-27 (analysis, no code — two lanes de-risked):**
- ✅ **Pool PRESS traced** (§3 "PRESS — what actually feeds the landing"): the landing is
   complete + correct; it is inert only because its two triggers (`mardir='pool'` + a pressed
    `lofi`/`body_hash`) go unlit. The owed driver is `Ra_press(shelf, origId)` REUSING
     `Heist_catalog_land` (never a parallel minter), and its verification Book MUST press through
      a pinned stub — the real transcode isn't bit-reproducible (`Ra.g:1300`), so a byte-exact
       fixture of a real press is impossible; assert shape, not bytes.
- ✅ **Signing floor resolved to "already coherent"** (§0 candidate + §10 reconciled): the
   feared ~15-20-unsigned-sites audit was a red herring. Seals are ed25519-signed, content
    transfers are vouch-gated fails-closed (`Heist_vouch_ok`/`Ra_verify`), the relay is a
     hello-bound dumb router, and live-cast `%MusuThem` gossip is structurally non-promotable to
      a holding (`Ra_holding_keys` exclusion). Per-frame gossip signing is HARDENING, NOT a
       pool-exchange ship-blocker (the old "land before pool exchange" is withdrawn). One
        invariant is worth a Book: `%MusuThem` never promotes off-vouch.

**Candidates to get on with next** (none blocks the others):
- **Author SwarmCohort's real Plan** — editor-only (confirmed 2026-08-27: `Story.svelte:1547`
   mints a fresh run with `total = 1` and the comment "user builds up the test step-by-step via
    Resume"; no `runner_ask`/`poke` verb drives step advance). RECIPE: boot the runner on
     SwarmCohort, hit **Resume** five times (steps 2→6, each beat's `%see` should light), then
      **Accept-All** (`runner_ask accept` = the same button over the wire) to record `002–006.snap`;
       finally re-run in check mode and confirm `steps` shows `n:1..6` all green — THAT is the real
        proof. Beats + witnesses are already written in `.g`; only the recorded Plan is missing.
- A dedicated model Book beat for `Supervisor_cull_orphans`
   (register watch → drop subject world → cull → assert gone) — clean-verifiable, no infra.
- Two-machine live proof of hello-v2; two-tab proof of the cohort.
- Build the pool PRESS driver — start with **v1 = byte-copy into the OPFS pool** (deterministic,
   so a NORMAL byte-exact Book proves it — shippable now, `Ra_rec_pool` already handles the
    no-transcode case); defer **v2 = ogg128 transcode** (non-reproducible → pinned-stub shape-Book).
     Both reuse `Heist_catalog_land`. Full trace + the v1/v2 split at §3.
- (Optional hardening, NOT a blocker) per-frame gossip signing — the signing floor is already
   coherent (resolved above & §10); the only owed test is the `%MusuThem`-never-promotes-off-vouch
    invariant guard.
- The LinkDevice ceremony proper (§7) — the encrypted account transfer riding repli. The
   InviteYourself dialogue is an honest stub awaiting this.
- `%Schema` law-book (§2E, drafted) — your preen, then wire `Berth_open/save` to read it.

---

## 1. The vocabulary

- **Soul** — the keypair. Immutable, key-derived, the thing `ident.sc.prepub` names. One soul
   per account, however many devices hold it.
- **Body** — a device (tab, phone, daemon) holding a soul. Bodies of one soul are `%Sibling`s
   when cooperative; an unrecognised body wearing your soul is a **theft** (`%Stolen`).
- **SelfType** — what a body IS within its soul's tandem: `Captain` or `Cave` (more may come).
   Not a job assignment but a station in life: which duties this body is placed to carry.
    Rides beside the address on the %Peering (a body has one SelfType at a time); advertised
     to peers so they can pick which body to talk to (§4).
- **The helm** — the authority relation of the tandem: the Captain holds the helm; the Cave
   serves it. Asymmetric on purpose (the phone is where the human is; the Cave obeys standing
    orders), and named for the ship, not for the bedroom.
- **Vessel key** — a body's own autogen keypair, born with the device before any soul lands
   on it. What a body is addressable and encryptable-to *as itself*; the LinkDevice beacon's
    ephemeral pub plays this role in the ceremony (§7). **Per-INSTANCE, quite specifically**
     (ruled 2026-08-27): one vessel key per install (browser profile × origin × device) —
      moving to a new Captain may deliberately FORGET the previous vessel, retiring its
       cohort-roster row. A vessel is a place the soul has stood, not a possession it keeps.
- **Instance memory** — the small store where a body remembers WHICH INSTANCE IT IS (its
   vessel key, its SelfType, which souls it has held) — scoped to the instance, never to a
    soul, so it cannot mix up when one browser holds two identities. Sits at the top of the
     one slope of persistence (Dexie|FSA behind the same abstraction); largely still to make
      up (§10).
- **Cohort** — the bunch of your device limbs currently standing: every live body of the
   soul, wherever it stands. Three faces, stacked: the cohort is the SET; "am I alone?" is
    the boot question a limb asks of it (Swarm_cohort_stand) before touching the wire; and
     "the identity stands in ONE place" is the guarantee built on the answer — exactly one
      limb at the bare name at a time, every other limb at a suffix, all verified by the same
       key. Detection radius grows by layer: the v1 census sees one browser profile (Web Lock
        + BroadcastChannel); the filesystem beats widen it to the machine; the relay hellos
         widen it to the world.
- **The cohort roster** — the cohort's MEMORY (ruled 2026-08-27): the limbs this soul has
   met, standing or not — a Tier-B shelf of instance rows (vessel id, SelfType, last
    address, last seen). This is "the something parameterised on the Cave end of the
     Account": each body's replica carries its own instance stamp, and the roster is the
      union of the stamps. The %Sibling machinery is its seed; the roster is %Sibling made
       durable and replicated.
- **Captain** — the soul's home body, most likely the phone: no FSA (`showDirectoryPicker` is
   desktop-Chromium-only — the one hard fact of the phone arc), storage in OPFS/Dexie only.
    The social hand: in-person QR, invites, the human's presence. Holds the helm.
- **Cave** — the deepest, stablest, least mobile region of a person's infrastructure: a body
   with a real filesystem. Concretely: Chrome-with-FSA on the user's computer at first, the
    always-on daemon at its most cave-like — often the same machine wearing both, and the
     daemon is where a Cave wants to end up (§7). The library's home, where Heists are
      fulfilled, transcoding runs, and backups land. Carries **durability**. (Named for the
       treasure cave, not the container: "TreasureChest" had the better image — open the
        laptop lid like a chest lid — but a chest is portable, and this concept is defined by
         being the thing that does not move. "Merchant" was the working name, retired as too
          market-flavoured for what is really a hoard.)
- **Quick / still** — a body is **quick** when it may write the consumable ledger; by the
   2026-08-27 ruling that is **the Captain, by definition** (§2C, §6) — so quick/still has
    collapsed from a lease into a synonym for the role split, kept in the vocabulary only
     because the wire-transition rule still needs the words: a body going still must unbind
      its address, not just stop writing (§6).
- **SoulInvite / LinkDevice / `%Invite:MyCave`** — the invite whose redemption makes you, not
   befriends you. "LinkDevice" is the ruled ceremony name (2026-08-19, after Signal/WhatsApp);
    `%Invite:MyCave` is how it meshes with the standing invite system: today's invites carry a
     Music Feature (`%Invite:Music` — *what I will serve you*); this one carries a ROLE
      Feature (*what you will be to me*). The role transcends the Music part of the system.
       One mechanism; the human may settle one word. A `%Invite` PARTICLE also now exists by
        ruling — the URL's token data autovivifies into one (§7), so the thing everyone
         thinks in has a body in the tree.
- **Original** — the HIFI holding: a `%Record` in a real-filesystem `%Library`, the Cave's
   charge, the librarian's object of interest.
- **SoundPool** — a body's OPFS audio shelf: LOFI listening copies pressed from Originals or
   received from another pool. A cache with a ledger — never a second library.
- **LOFI / HIFI** — the fidelity axis (§3). A pool copy is LOFI by station; an Original is
   the HIFI it points at.

Notation follows `CLAUDE.md`: `%Sibling`, `%Stolen`, `%Idzeug`; a property as `Peering%address`.

---

## 1b. The atlas of ids — which ids live where, and the seams between them

Five id families, each with its own lifetime and its own verifier. Every bug in this arc so
 far has lived at a SEAM — the place one family is translated into another — so the seams are
  drawn as first-class objects.

### The soul's derivation chain (one person)

```
key (ed25519 private) ──── SECRET. `.c.keys` at runtime; IN CLEAR in
 │                          .jamsend/account/<prepub>/toc.snap; Dexie identities row.
 ▼ derives
pub (full public key) ──── the VERIFICATION truth. Rides %Page in frames,
 │                          %Grant.by / %Grant.for, vouchers. Never routes anything.
 ▼ prepubOf()
prepub (16 hex) ────────── the NAME. `ident.sc.prepub`; the dir names
 │                          (account/<prepub>/, berth/<prepub>/); QR token leg 1;
 │                          the %Pier key at every friend; frame `page.prepub`.
 ▼ + optional session suffix
address = <prepub>|<prepub>_N ── REACHABILITY. `Peering%address` (session-only,
                            omitted from export); the relay `?addr=` bind; what
                            `deliverLocal` fans out on.
```

Seams in this chain, and their checks:
- **pub↔prepub**: `prepubOf(pub) === claimed` — enforced at every seal-minting entry and in
   the voucher; NOT on gossip or repli frames (§10, the signing floor).
- **prepub↔address**: `Swarm_address()` — and the known GAP: `Socket_real` dials the name,
   not the address (§4, item 1).
- **address↔socket**: the relay's `hello` ed25519-binds a prepub to a socket ONCE at
   connect; nothing per-frame after.

### One track's ids (the content family)

```
source bytes ──sha256──▶ id (16 hex, the enid) ─── WHAT it is. The join everywhere:
    │                     a friend's mirrored %Record carries the SAME id; %Keepsake.id;
    │                     heist picks. Survives every hop.
    ├─▶ path ("music/Artist/…", future "pool/…") ─── WHERE it is, base-relative,
    │     snap-portable. id↔path binding lives in the radiostock card (base+path
    │     on `.c`) and the keep-id map — which is RUNTIME-ONLY: a reload wipes it,
    │     which is why the heist re-census exists. WHAT is durable; WHERE is earned.
    ├─▶ body_hash (per repli frame) ─── transport INTEGRITY, not identity.
    └─▶ LOFI press ──▶ a NEW id (different bytes!) + `of:<original id>` ─── the
          cross-fidelity join (§3). A pool copy is a different WHAT that names
          its Original.
```

### The ledger's ids (the trust family)

```
issuer %Idzeug (ordinal, `next`) ──draws──▶ serial ──rides──▶ the QR token
    <prepub16>*<serial>*<n>*<presig16>     (params do NOT ride the token —
                                            the issuer's own record is the law)
spend ledger: `claimed` run-list ("3-5~9~14"), per issuer
one writer (§2C): the CAPTAIN alone draws and ticks serials — no partition needed
%Grant / %NotGrant atoms: `by` + `for` are FULL PUBS (not prepubs) + `sign`
```

The seam to respect: **the wire routes by prepub/address, but the trust atoms bind pubs** —
 page binding + `prepubOf` is the bridge, and it is checked exactly where the audit says
  (§10). Never compare a grant's `by` to a frame's `from`; they are different families.

### The wire's per-body state (⚠ the seam that isn't finished)

```
per BODY:  seq (stream counter) · era (station generation) · voucher (per-era proof)
per PAIR:  the state a FRIEND keeps about you: peer_era, repli windows, rtt —
           keyed by their %Pier for you, i.e. BY PREPUB, not by address.
per ASK:   corr (request ↔ reply correlation; relay ackBack, runner_ask)
```

⚠ Two bodies of one soul with distinct addresses solve the RELAY (each gets its own door,
 §4) — but at the FRIEND's end they still meet **one %Pier**, whose seq/era/window state
  assumes one body. Whose seq does the friend track when your Captain and your Cave both
   talk to them? Open, and load-bearing — §10 carries it.

### The body's own ids (the design family, §7)

```
vessel key ──── a body's pre-graft keypair (the LinkDevice beacon pub); what the
                SoulInvite encrypts toward. Lives in mortal browser storage (⚠ §10).
%Sibling place ─ the roster row key for a cooperative co-holder.
SelfType ────── Captain|Cave. ADVERTISORY, not enforcement: every body of a soul
                holds the same key and therefore the same cryptographic powers —
                SelfType is coordination among your own bodies, never security
                against a hostile one.
```

---

## 2. An account's data, by merge behaviour

Portability is a merge problem, and an account is three tiers that merge differently. The
 tier boundaries are what make "the Cave may Heist but not spend" precise rather than a vibe.

**Tier A — immutable (the soul).** The keypair. Never merges because it never changes;
 replication is the one-time secure ceremony of §7.

**Tier B — grow-only (friendships, grants, Heisted tracks, the newlyadded berth, the pool
 ledger).** Append-mostly sets keyed by stable identities. Two bodies each befriending
  different people, or landing different tracks, **union-merge** cleanly — the berth
   append-door already folds parts by key, a log-structured merge waiting to be pointed at two
    devices. A still body writes this tier freely to its OWN replica; adoption (§8) takes the
     union. The standing merge-safety ruling generalises to every Tier-B shape: append-only
      events carrying `at` + device provenance merge trivially; a mutable yes/no flag would
       not — shape new ledgers accordingly.

**Tier C — consumable (the invite ledger: `%Idzeug` `next` + `claimed`).** The poison. A
 serial spends exactly once; `claimed` is a run-list set (`"3-5~9~14"`) in one scalar, and the
  berth fold LWW-supersedes whole scalars — so two writers ticking serials off the same issuer
   would lose one tick silently, and **an invite un-spends** (the security property
    `Identity_persist` names). **The ruled answer (2026-08-27, superseding the earlier
     block-lease ruling): the CAPTAIN takes care of all Invites, full stop.** The role split
      dissolves the merge problem instead of solving it — Tier C has exactly one writer by
       definition of the helm, so there is nothing to partition, nothing to lease, and no
        allocator to design. Caves replicate the ledger read-only (they must SEE spends to
         refuse a revoked peer) and never write it. The block-lease design (per-body serial
          ranges) is retired to this parenthesis: it re-enters only if a future ever wants
           two Captains, which nothing currently does.
  What no tier gets for free: per-field last-writer-wins by *causal* time. A snap carries no
   vector clock; the fold decides by part order on disk. Fine for a nickname; not fine where
    "which edit truly came later" is load-bearing.

**2D — the partition audit (2026-08-26): is the right stuff per-Identity?** Two sweeps, disk
 and browser, answering "have we got the correct pool of stuff equivalent to tables that
  shouldn't be per Identity":
  - **Disk: yes — the layout is already correct.** Per-soul lives under a prepub:
     `account/<prepub>/`, `berth/<prepub>/{Heists, KeepMemo, HeistDefaults, Faves, Musica}` —
      all of it replicable soul data. Per-collection deliberately does NOT wear a prepub:
       `berth/Newlyadded/` (what landed in THIS collection, whoever caused it) and
        `berth/Census/` (this machine's directory estimator) — both would be wrong to carry
         to another device. No misfilings found.
  - **Browser: mostly — three bleeds, all fixable.** (1) `House.stashed` is ONE Dexie row
     keyed by House name, so any identity-flavoured key in it (UI state, the deprecated
      `cluster_idento` fallback) bleeds between identities sharing a browser — prepub-prefix
       such keys or move them to the identities table. (2) the `cluster_idento`-in-stashed
        legacy read (`LiesLies.svelte:670`) can diverge from the `?I=` identity — already
         flagged by an `identity_diverged` check; retire the fallback. (3) `localStorage`
          (invite-dismissed, audio-gesture) is origin-global — acceptable, those are browser
           prefs, but know a second identity inherits them. The identities Thang itself is
            correctly keyed by prepub; what it lacks is any cross-device sync — which is
             exactly what §7's graft is for, so that is a feature of this doc, not a bug of
              the table.

**2E — writing these schemas in IOexpr (investigated 2026-08-27).** The properties this
 section states in prose (keyed-by, replicates, writer, merge rule, home store) want to be
  DECLARED once and read by the seams (Berth open/save, the persist gates, the future
   replicator, the adoption union) instead of hardcoded per shelf. **IOexpr** is the standing
    candidate: `%IO` rows in a commission (`from:`/`find:` + `shape: mirror|slope|presence|
     pick`) — a declarative source-and-shaping language, fully specced in
      `vyto_workingouts/commission.md` §3 but still flagged "wild speculation," unbuilt,
       awaiting its first tenant (the Vyto sizing algebra). The investigation's verdict:
        **IOexpr is the right composition backbone and the wrong place for authority** — it
         says what to fetch and how to shape, but has no vocabulary for writer/merge/home.
          The natural extension is a thin **`%Schema,<shelf>`** particle referencing an
           `%IO` row and adding exactly the missing keys (`keyed_by`, `replicates`,
            `writer: captain-only|any-body|this-body-only`, `merge: union|lww|
             single-writer`, `home: dexie:<table>|berth:<path>|opfs:<mount>`). That keeps
              IOexpr pure and gives the account a machine-readable law-book — and it would
               make the account schemas IOexpr's first tenant, un-parking it with a real
                load.

  *The standard, drafted (2026-08-27, post-rulings — writer vocabulary reflects
   Captain-only Tier C, no leases):*

  ```
  %Schema,account            — Tier A+B+C, the soul's own book
    io: IO,account           —   find: {Identity:1, active:1}  shape: mirror
    keyed_by: prepub
    replicates: yes          —   the standing body-to-body stream (§7)
    writer: captain-only     —   Tier C rides inside; the role IS the lock (§2C)
    merge: single-writer
    home: berth:account/<prepub>/

  %Schema,heists             — Tier B, what the soul decided to take
    io: IO,heists            —   find: {Heist:1}  in: home shop  shape: mirror
    keyed_by: prepub
    replicates: yes
    writer: any-body         —   any body may Heist (§6)
    merge: union             —   keyed by id; same take twice = one row
    home: berth:<prepub>/Heists

  %Schema,pool               — the SoundPool ledger (§3)
    io: IO,pool              —   find: {Record:1, grade:1}  in: pool shelf  shape: mirror
    keyed_by: instance       —   THIS body's pool; the smuggle unions it Cave-ward
    replicates: smuggle-to:cave
    writer: this-body-only
    merge: union
    home: opfs:pool/ + berth:<prepub>/Pool (the Cave-side backup twin)

  %Schema,newlyadded         — per-COLLECTION, deliberately soul-blind (§2D)
    io: IO,newlyadded        —   find: {Got:1}  shape: mirror
    keyed_by: collection
    replicates: no           —   it describes THIS box's collection; travel would lie
    writer: any-body
    merge: union
    home: berth:Newlyadded
  ```

  The seams that would read these: `Berth_open/save` (home), the persist gates (writer),
   the §7 replication stream (replicates + merge), the §8 adoption union (merge). Deeper
    aspects update here as the tenant work teaches.

---

## 3. The fidelity axis — Originals and the SoundPool

**Two stations of being for one piece of music.** The **Original** is the holding: `%Record`
 in a `%Library` on a real filesystem, the Cave's charge. A **pool copy** is a LOFI pressing
  in some body's OPFS SoundPool, made for listening on a device that cannot (and should not)
   hold the library. The librarian's interest runs entirely to Originals; the pool is the
    people's music — portable, lossy, expendable.

**Identity across fidelities follows the standing law** (`CLAUDE.md`, "identity is
 per-shelf"): a pool copy is a **referring particle wearing its own mainkey** — `%Pool,of:<id>`
  (name to preen) beside its chunks — never a second `%Record` impersonating the holding. The
   `of:` join is what lets a pool copy name its Original, survive transcoding, and dedup
    across pools. The old magazine minted exactly this bug once; the tell is two shapes under
     one mainkey.

**The pool record's path — another type of radiostock, worked out (audited 2026-08-26).**
 Today a `%Record.sc.path` is **base-relative**: `"music/Artist/Album/Track.wav"` — the base
  is a mount/meander name (`music`, `testsounds`), the radiostock card keeps base+path split
   on `.c`, and the snap-time join produces the one portable scalar. The nav layer already
    abstracts all byte I/O behind the same duck-typed contract, and `MountNav` already routes
     per-method by mount prefix. **So the pool is simply another mount**: a pool record's path
      is `"pool/…"`, resolved to the OPFS nav exactly as `"music/…"` resolves to the FSA nav.
       Zero changes at the meander/serve seams (they never inspect path semantics), snap-safe
        (one scalar, no new fields), and the friend-exchange idiom comes free: a received
         `path:"pool/…"` that doesn't resolve yet is a dead reference that starts resolving
          the day a pool mount stands — the exact behaviour `"music/…"` has today before a
           share opens. A URI scheme (`opfs://…`) and an id-only+nav-tag shape were both
            considered and rejected (scheme-stripping at every seam; a new sc field that
             re-records ~8 Books). Touch-list: ~10 lines of MountNav pool-prefix routing, one
              line adding `'pool'` to the meander bases, ~5 lines standing the pool
               `OpfsOverlayNav` at boot.
  The mainkey question was then BURNED (the 2026-08-27 Repli-coupling trace, ranked verdict):
   pool rows should wear **`%Record`** — on the pool's own shelf, `id` = the hash of the LOFI
    bytes themselves, `of:<original-id>` the cross-fidelity join, **`grade:'ogg128'`** the
     pressing mark (a key `%Blob` already carries in the wire identity table for exactly this
      purpose). That is not a compromise of the identity law but a correct application of it —
       the law is per-shelf, and a pool row genuinely holds its bytes; provenance rides
        scalars (`of:`, `grade`, the standing `lofi:1` precedent at `Heist.g:1571`), which is
         how this codebase has always expressed it, not by minting a noun. The trace's
          sharpest line, kept: *"the flaw is not that %Record means holding, but that
           forty-five seams each privately re-decide that it does"* — hence `Ra_holding_keys()`
            (landed, §0) as the one place the question is answered from now on. Final word
             remains the human's preen; the machinery no longer cares which way it falls.

**The pool is Mag-based — the standards apply (ruled 2026-08-27).** The landing-Mag ruling
 already says it (`Heist.g:161`): *"every collection holding lives in the shelf's paged Mag,
  whatever verb minted it"* — and the pool is a collection of live holdings, so pool tracks
   mint through the ONE owned door (`Ra_rec_home`) into a paged Mag on the pool shelf, never
    a flat way-station. Its counterpart ruling cuts the other way (`Heist.g:4072`): *"a
     ledger is not a Mag"* — so the pool LEDGER (what was pooled, from what, when — the
      thing the smuggle backs up) stays a berth ledger beside the Mag, not inside it. Two
       standards, both already law; the pool invents neither.

**The OPFS reality that shapes the pool.** OPFS works on phones and is invisible to the OS
 file manager ("hella inaccessible" — which is fine: it is a cache, not a collection). It is
  also **evictable**: browser storage pressure can clear it, and "clear browsing data" kills
   it outright (§0 item 9b owes the `navigator.storage.persist()` request — cheap mitigation,
    auto-granted once PWA-installed). Two consequences, both load-bearing:
  - **The pool is designed expendable.** A pool entry is re-pressable from its Original;
     losing the pool loses convenience, never music — PROVIDED the smuggle (§5) has run, so
      the pool ledger (what was pooled, from what, at what fidelity) outlives the pool bytes.
  - **The pool needs its own economy**: a size cap, an eviction order (least-recently-
     listened first), and honesty in the UI about what is pooled here vs held elsewhere.

**The press.** HIFI→LOFI transcoding is Cave work and the machinery already runs: the
 daemon's native ffmpeg stocking (probe|measure|encode) and Radio's demand-driven transcode
  (`Ra_transcode_ensure|advance`). SoundPooling is that press pointed at a pool target instead
   of a stream — same gears, new destination.

**The pool is a Heist DESTINATION, not only a press target** (the owner, 2026-08-26: "OPFS
 can be Heisted to as well, we need to really loosen up that exchanger head"). The Heist's
  landing head — the seam that writes landed material somewhere — assumes the real-FS share
   today (mardir, the FSA nav). That assumption is the thing to loosen, and the loosening is
    cheap in principle because **the nav contract is already the seam**:
     `read_file/write_file/dir` is the whole interface, and the OPFS overlay nav
      (`WormholeOpfs`) already speaks it. A landing head parameterised over ANY nav lets a
       Captain Heist straight into its own pool — no Cave in the loop — and lets the pool
        exchange (§5 Flow 3) BE a heist whose destination is OPFS: one machinery, two
         destinations. What lands pool-side is pool-grade by posture (LOFI, expendable,
          `of:`-joined); the Cave remains where Original-grade landing and keeping happen.
           (This scopes the older "no heist setup on the phone" ruling of 2026-08-15 to the
            v1 *UI*, while the *machinery* below it goes destination-agnostic.)

**PRESS — what actually feeds the landing (traced 2026-08-27, the driver is the one hole left).**
 The catalog LANDING is already complete and correct: `Heist_catalog_land`'s pool branch
  (`Heist.g:972`) mints through `Ra_rec_pool` (`Ra.g:895`) — id = the lofi enid
   (`body_hash.slice(0,16)`), `of:<original>` the cross-fidelity join, `grade:'ogg128'`, `lofi:1`
    — and I proved it **inert**: no path in the tree lights its two triggers. It fires only when
     BOTH hold: (a) the mount side — `w.c.mardir` names `'pool'` (already free via MountNav prefix
      routing, §3 above); and (b) the byte side — the landed `rec` carries `sc.lofi=1` **and** a
       `sc.body_hash` that is the hash of the *pressed* bytes, not the Original's. Nothing sets (b),
        so every real heist takes the library branch byte-for-byte. **The missing driver is a press
         that produces those pressed bytes and hands them to the landing with both flags lit.**
  Shape of the driver (call it `Ra_press(shelf, origId)`): read the Original's bytes off its nav →
   encode ogg128 → compute the pressed `body_hash` → drive a heist whose `mardir='pool'` and whose
    mirror `rec` carries `lofi:1` + that `body_hash`, so it falls straight through the EXISTING pool
     branch. It must **reuse** `Heist_catalog_land`, never fork a parallel minting path — the whole
      point of routing the three Repli seams through `Ra_holding_keys()` (§0, landed) was to keep
       one authority; a bespoke press-minter would re-open the forty-five-seams flaw the coupling
        burn just closed.
  **⚠ The determinism trap that governs how this can be VERIFIED.** `Ra.g:1300` is explicit: the
   Ra-path transcode is **not bit-reproducible** — two presses of one Original yield different bytes,
    hence different enids, hence a different pool-record `id`/`body_hash` every run. So a Book that
     presses with the *real* codec can never be byte-exact, and a byte-exact snap fixture is the
      Story gate. The verification strategy therefore MUST split: a model Book presses through a
       **pinned stub** (fixed pressed-bytes → fixed enid) and asserts the *shape* — that a
        `%Record,of:<orig>,grade:ogg128,lofi:1` lands on the pool shelf with a `pool/…` path and the
         cross-fidelity join is well-formed (a `%see` claim, no comma) — while the *real* codec's
          fidelity is a separate, non-fixtured concern (listen, or measure, never snap). This is the
           same reason `%Original` cids are the only ones that ride a swarm-shared signature
            (`Ra.g:1300`): a grade's bytes are local truth, never shared truth. Build the driver and
             the stubbed shape-Book together; do not attempt to fixture the real press.
  **The trap has a clean way around it for v1 — split the press in two (2026-08-27).** A pool copy
   does NOT have to transcode: `Ra_rec_pool` already handles the no-press case (`lofiId===origId`,
    `grade` absent, `of:` elided — "a copy of itself needs no cross-fidelity join"). So **v1 press =
     a byte-for-byte copy of the Original into the OPFS pool nav** — which is *deterministic* (a copy
      reproduces bit-for-bit, unlike the codec), hence FULLY byte-exact-testable with a normal
       fixture, no stub required. It is already useful: it makes a track portable to a device that
        shouldn't hold the library, at Original fidelity, expendable. **v2 press = the ogg128
         transcode** (smaller, lossy) — THAT is the non-reproducible one that needs the pinned-stub
          shape-Book above. Ship v1 first (real driver, real fixture, real green); land v2 when the
           size win is wanted. This turns "the press is blocked on a non-deterministic codec" into
            "the press ships now; only its lossy optimization waits."

---

## 4. The relay — how bodies coexist, and how they collide

The relay is a dumb address-routed forwarder; two verified facts govern the design.

**Fact 1 — delivery fans out to a SET, keyed by address.** `locals` maps an address to a
 *set* of sockets; `deliverLocal` sends a `to:<addr>` frame to **every** station socket bound
  under that address (the `qaddr === to` own-door rule prefers station sockets over role
   sockets, but among station sockets of one address, all receive). Two bodies under the
    **same** address is therefore **duplication, not division**: both receive everything, both
     answer, each runs its own sequence counter stamped `from:<prepub>`, and a friend receives
      two interleaved streams one repli window can never reconcile (`repli_missed` forever —
       the observed two-daemon disease, and the standing
        `[[relay-locals-additive-bind-fanout]]` lesson: the relay is an unauthenticated
         forwarder; assume an eavesdropper, expect a fan-out).

**Fact 2 — music routes to the ASKER's address; recognition rides the pub.** Repli serves
 pages `to: h.from`; grants verify `prepubOf(pub)`, independent of address. So a body receives
  what it asks for **at whatever address it asked under**, and proves itself by key, not by
   name.

**The consequence — bodies coexist by holding DISTINCT addresses.** A Captain and its Cave
 can both be live, both talk to friends, both Heist: each receives its own pages at its own
  door, both verify as the same soul, neither collides. `Swarm_next_suffix` computes the
   place, `Swarm_steal_back` takes it, `Swarm_reinstate` returns to the bare name with the
    §7.4f disk-wins hold. Same-address collision is the disease; the suffix is the standing
     escape; the 👥 tripwire is the alarm for the case nobody chose.

**The bare name goes to whoever claimed it first.** No body has a birthright to the bare
 `<prepub>`; first claimant keeps it, later bodies suffix — and that is enough, because peers
  do not need the bare name to reach the body they want (below). `Swarm_reinstate` exists for
   the deliberate take-back, not for contesting a live holder.

**How peers know which address to use.** A soul's bodies advertise themselves: the hello /
 pier_accept a peer receives carries the working address of the body that sent it, and a
  body's SelfType (§1) rides beside it — so a peer wanting music asks the address that
   advertised Cave duties, and a peer answering a QR gesture talks to the Captain that showed
    it. A Captain↔Captain pool exchange (§5 Flow 3) needs no routing wisdom at all: each phone
     talks to the address of the phone in front of it, whatever suffix it wears. The precise
      frame fields for the advertisement are design-owed; the principle is settled — **peers
       address bodies, not souls**, and the soul is proven by pub either way.

**Enforcement at the relay is deliberately TODO.** `bind` is additive; honest bodies avoid
 collision by suffixing, and a crashed or modified one is caught by the 👥 tripwire rather
  than prevented. The security floor is not the relay — it is that **peers must sign with the
   key matching their prepub** and receivers verify. Audited 2026-08-26: **enforced on
    every seal-minting path (invites, grants, the reinvite chain), NOT enforced on gossip
     frames or music streams** — the full verdict and the make-it-universal work list are
      in §10. Relay-enforced address exclusivity stays on the
      list as hardening on top of that floor, not as the foundation. (The relay does verify
       one thing already: the `hello` handshake ed25519-binds a prepub to its socket at
        connect — authentication of the socket, not of any later frame.)

**Two relay duties ruled 2026-08-27:**
- **One socket, many addresses.** Today a tab opens TWO sockets (the station `?addr=<prepub>`
   and the role channel `?addr=runner|editor`), and the whole `qaddr` own-door dance in
    `deliverLocal` exists to un-double the delivery that dual binding caused. Tidier, ruled:
     **one websocket per body, binding several addresses over it** (hello binds a list; later
      binds add). One socket = one liveness, one delivery door, no phantom copies — and the
       own-door rule shrinks to "deliver once per socket." A wire change worth doing together
        with the signed-hello work.
- **The relay closes dead sockets — and it already does** (audited in the cohort burn:
   `HEARTBEAT_MS = 15000`, a socket missing one pong is terminated and unbound — squatting is
    bounded to ~30s). What remains of this ruling is only the ELECTION half: surviving bodies
     seeing the address free and a new primary stepping up (the cohort's lock does this
      within a profile automatically; cross-machine it is the hello-v2 work).

---

## 5. The tandem — what you'd Heist wanders to the Cave

The division of labour, stated once: **the Captain holds the helm; the Cave keeps the
 hoard.** The Captain is where the human is — it meets people, mints and redeems in person,
  listens. The Cave is where the disk is — it acquires, presses, keeps, and repairs, on
   standing orders.

**Flow 1 — the Heist.** The human marks something for Heisting; the Cave carries it out with
 the gears that already exist, against the friend grants the soul already holds. The
  confusing-sounding sentence from the design conversation is exactly right and worth
   keeping: **the Cave carries out the Heist "from the other Captain"** — the *grant chain*
    traces Captain-to-Captain (souls befriend souls, in person, by QR), while the *bytes* flow
     Cave-to-Cave (the bodies with the libraries and the uptime). Socially it is two people
      sharing music; mechanically it is their two stations doing the lifting overnight.

**Flow 2 — the pool press.** The Cave presses Originals to LOFI and fills the Captain's
 SoundPool (over the wire, to OPFS), so the phone actually *listens* — the Captain's music
  comes back to the Captain's hand. Pool contents are chosen by the human and by policy
   (recently played, recently jammed); the pool cap governs (§3).

**Flow 3 — the pool exchange, possibly the MAJORITY transport** (§0's working bet). Two
 phones in a room swap SoundPool material directly: live, phone↔phone, LOFI only, no Cave
  online. Not so exciting to the librarian — nothing archival moves — but socially potent,
   and mechanically it is just **a Heist whose landing nav is OPFS** (§3, the loosened head):
    one machinery, two destinations. Each pooled track arrives as a **referring particle with
     its `of:` identity intact**, so it is simultaneously (a) listenable now, LOFI, and (b) an
      **introduction** — something the receiving side's Cave can later fill out as an
       Original, through Flow 1, under whatever grant the two souls' friendship carries. The
        exchange is the discovery surface; the Caves make it a collection. If the majority bet
         holds, most music a person carries will have arrived THIS way — so the pool paths get
          first-class design attention, and the Cave's role sharpens to what only it can do:
           keep, verify, and HIFI-ify.

**Flow 4 — the smuggle.** The Captain's SoundPool (and the Captain's whole account — the
 phone's storage is mortal, §0 item 9b) replicates to the Cave **for backup**, not for
  listening. The Cave regards every arriving pool copy as **LOFI that wants to be
   HIFI-ified**: each carries its `of:` join, so the Cave can fetch the Original whenever it
    becomes reachable, at whatever pace its station affords. The backup is thereby also the
     upgrade queue, and the pool's expendability (§3) is underwritten: bytes may die with the
      browser; the ledger lives on the Cave's disk.

---

## 6. The ledger follows the helm

This section used to carry a two-shape lease design (quick/still bodies, serial block
 leases). The Captain|Cave split retired it (§2C, 2026-08-27): **the Captain is the one
  invite processor, by definition of the helm.** What remains worth stating:

- A Cave reads everything, Heists freely, and writes its own Tier-B replica (tracks landed,
   pool ledger) — it is forbidden exactly one thing: writing the consumable ledger. That is
    what makes a Cave useful while safe.
- The ledger replicates TO Caves read-only, continuously (§7's mutual backup) — a Cave must
   *see* spends and revocations to refuse a cut-off peer at serve time.
- **Standing down is a wire transition, not a permission bit.** A body ceasing its duties
   must actually unbind/re-dial its address (§4) — as long as it stays bound at a contested
    name it keeps receiving and answering the soul's fan-out, doubling streams regardless of
     what it's allowed to write.

---

## 7. The graft — `%Invite:MyCave`

**The mesh with the standing invite system.** jamsend already has one way trust moves: an
 `%Idzeug` invite — a serial drawn off an issuer, carried as a compact QR token, redeemed
  once, verified by presig, landing as a `%Grant`. Today the only Feature is Music
   (`%Invite:Music` — *I will serve you music*). The graft is the same machinery carrying a
    ROLE Feature — **`%Invite:MyCave`** (*you will be my Cave*) — because the role transcends
     the Music part of the system but has no reason to transcend its rails.
  **Audited 2026-08-26, and the news is unusually good: the rails are ALREADY generic.**
   `Swarm_iz_issuer` takes any `{Feature, ...params}` and stores `to:<mainkey>`; the token
    codec, redeem parse, hello/accept doors, and `mint_grant` all carry the Feature through
     without inspecting it; `mint_revoke` / `Swarm_pier_live` / the `%NotGrant` machinery
      take the feature as a parameter. **Minting, redeeming, and revoking `%Invite:MyCave`
       needs zero changes to the invite/grant/revoke layer.** What DOES need surgery is the
        SERVE layer, which hardcodes `'Music'`: six `Swarm_pier_live(p, 'Music')` call sites
         (Swarm.g:658, 716, 2371, 2471, 2586, 3130), a `'Music'` fallback in
          `Swarm_reaccept_incomplete` (~1363), and the legacy-token transcoder (~830, which
           may stay Music-only — see the `Old garden` note: that prototype is to be deleted
            once this doc captures its designs, so nothing new should cite it). Plus the
             mint UI, which never asks which Feature. That is the whole touch-list.

**What the Cave concretely is.** At first: a Chrome tab with FSA on the user's computer — the
 same Big*land page, opened at home, granted the music folder. At its most cave-like: the
  always-on daemon on that machine. Often both across a day — the tab does the interactive
   work, and the adoption handoff (§8) is how the daemon takes the Cave's duties over. A body's
    SelfType (§1) says which duties it carries; the graft is what bestows them.

**The ceremony** (ruled 2026-08-14/19, kept in force, restated Cave-ward):

- An invite **whose redemption makes you, not befriends you** — same rails as any invite,
   inverted consequence. Therefore: high-entropy, **single-use, short-lived (minutes), never
    posted**.
- **Both devices online is a feature**: the account travels as relay frames **encrypted under
   a code-derived key** (the relay is an unauthenticated fan-out forwarder — assume an
    eavesdropper), and liveness lets both screens show a **matching confirm** (same emoji
     pair) before key material moves.
- **The carry**: (a) the Cave-to-be shows its beacon (its address + an ephemeral pub — its
   vessel key doing its job) as a QR; the Captain scans it and issues — the secret never
    touches a third party, the camera does the carry. Build this. (b) a typed short code as
     the no-camera fallback — tolerable only because single-use + short-lived.
- **What moves**: the account Waft — `Identity,key` + `Peering` — with `%Idzeug` issuer
   state travelling READ-ONLY (§2C: the ledger stays the Captain's to write, wherever it is
    replicated).

**What a freshly grafted body is.** Three plain facts, each with its own reason:
- **It has no invite authority — and never gains it as a Cave.** Invite processing is the
   Captain's alone (§2C); a grafted Cave heists and replicates from day one and never
    spends. Invite authority moves only when a new CAPTAIN is grafted (`%Invite:MyCaptain`,
     below) — the helm changes hands whole, never splits.
- **The Captain writes it into the family register.** At issue time the Captain records the
   new body on its `%Sibling` roster. This is what keeps the alarm honest: when a frame later
    arrives from your own key, the tripwire checks the roster — family is co-presence,
     everyone else is a thief. A graft that skipped this step would trip its own alarm.
- **It answers at its own address.** The new body takes `<prepub>_N` on first bind (§4), so
   it never collides with the Captain on the relay. The bare name stays with whoever already
    holds it.

**The %Invite particle — autovivify what the human already thinks (ruled 2026-08-27).**
 Today no `%Invite` particle exists: an invite is smeared across the issuer's `%Idzeug`, the
  token string in a URL/QR, and the landed `%Grant` — yet everyone THINKS in invites. Ruled:
   the data read from an invite URL **autovivifies into a `%Invite` particle** in the live
    tree — token legs on `sc` (prepub, serial, n; presig on `.c` if it shouldn't snap), a
     state that walks `arrived → redeeming → sealed|refused`, and the landed grant/pier
      backlinked on `.c`. The mental model gets a real particle: the Door and the glass can
       show an invite as a thing with a lifecycle, instead of a string that vanishes into
        machinery. (The issuer's record remains the law — the %Invite is the visitor's copy
         of the claim, never a second source of truth.)

**Replication is continuous — they all back each other up.** The graft's account transfer is
 not a one-shot ceremony payload: it BOOTSTRAPS a standing replication stream among the
  soul's bodies, riding the same class of machinery a Heist rides (chunked, resumable,
   grant-gated repli transfer — the gears exist). From then on the bodies back each other up
    continuously: Tier B unions flow as they grow, the Tier-C ledger flows Captain→Caves
     read-only (§6), and the smuggle (§5 Flow 4) is just this stream's pool-ledger lane. A
      body that was offline catches up the way a heist resumes — same door, same discipline.

**Migration and backup are the same move, in either direction.** A soul is not revocable
 (§10) — but **either role can mint the other**: a Captain grafts a new Cave
  (`%Invite:MyCave`), and a Cave can graft a new Captain (`%Invite:MyCaptain` — the phone
   died, stand at the Cave, scan, walk away whole). That bidirectionality plus the continuous
    mutual backup above IS the whole backup story: as long as one body of the soul survives,
     the tandem can be rebuilt from it, current to its last stream. The adoption handoff (§8)
      is this same move performed on a live pair.

Distinct in kind from a music `%Idzeug`: that grants *what you'll serve*; this grants *who
 you are to me* — the most dangerous token the system can mint, handled accordingly.

---

## 8. The adoption handoff

The owner's arc: the Captain runs with a laptop Cave for a while; later "spins up a daemon to
 do everything, using the laptop's latest replica, and perhaps telling any body online at that
  point what's up." As a protocol:

1. The daemon boots as a **still** body and **adopts the freshest replica** — a wholesale
    take of Tier A + a union of Tier B (the laptop was the working Cave, so its copy is
     freshest; adoption is a copy-and-union, never a live merge).
2. The daemon announces it will take the Cave's duties; online bodies ack.
3. The standing Cave **stands down**: stops fulfilment, unbinds its address (§6).
4. The daemon **binds** and takes up fulfilment; any Tier-C block the old Cave held (Shape 2
    only) transfers or retires.

Ordered with an ack, the two-body window at any one address is a controlled instant; skipped,
 it is the doubled-stream disease on purpose — which the 👥 tripwire will catch and say so.
 `Swarm_reinstate`'s disk-wins hold guards the bare name specifically: a body taking it back
  must re-read disk before it may write, so a stale adopter cannot clobber a fresher ledger.

---

## 9. The Door — where all this lives in the UI

The Door (DoorFace) is already the identity surface: who am I, sealed friends with the
 liveness dot, a landed joining, the 👥 alarm, the ⛁ settle chips. Portability enters the UI
  through the same door, as one distinction:

- **Invite someone** — the standing gesture: mint `%Invite:Music`, show the QR, a friendship
   seals. Unchanged.
- **Invite yourself** — the new gesture beside it: opens a small dialogue that explains
   portability in a few sentences (this doc's §0 destination paragraph is the long-form it
    links toward), then runs the graft ceremony (§7) — beacon shown or scanned, emoji
     confirm, done. The dialogue is also the honest place for the phone's mortality whisper
      (§0 item 9c) and, later, the place a body's SelfType and address are visible.

The Door also inherits the tandem's status surfaces as they land: which bodies stand where
 (address + SelfType per %Sibling), the 👥 alarm it already has, and eventually the handoff
  controls (§8's announce/stand-down as buttons rather than console verbs).

A standing want recorded while we are here (the owner): **better UI lego for displaying and
 working through C beings** — generic components for browsing/inspecting particles, which
  every surface in this doc (sibling rosters, pool ledgers, grant lists) would ride. That is
   its own design effort, owed outside this doc, but the Door work should not build one-off
    what wants to be lego.

---

## 10. Open questions

- **The signing floor — audited 2026-08-26: enforced where trust is minted, unenforced
   where it is merely used.** Where it IS enforced: every seal-minting path — `pier_hello` by presig
    regeneration + page binding, `pier_accept`/`pier_confirm` by grant signature, the
     reinvite chain end-to-end, and sealed piers on a live station must carry a per-era
      **voucher** (`Swarm_voucher_ok`: prepubOf(pub) matches the claimed sender + ed25519
       over the canonical header). Where it is NOT: **gossip** (`ive_got`, `suggest`,
        `pulse`, `swarm_hi`) is seal-gated but per-frame unsigned — one sealed friend can
         spoof another sealed friend's prepub in advisory data; and **music chunks** carry
          `body_hash` (integrity) but no identity signature — `header.from` is forgeable by
           any bound socket, since the relay authenticates sockets once at `hello` and never
            per-frame. Enforcement is also gated on `station_up`, so Book fixtures bypass it
             (fine — those are in-process mocks).
  **REVISED by the 2026-08-27 transport read (see §0 "Gossip/stream signing — RESOLVED").** The
   deeper read reframes the residual above: the spoof is real but **cannot escalate**. What a
    sealed peer can forge is *advisory attribution* — a gossip `header.from` the relay never
     checks against the socket's bound prepub, and a music chunk's sender identity. What it
      CANNOT forge is anything that reaches the trusted tier: content lands only through
       `Heist_vouch_ok`/`Ra_verify` (fails closed, `Heist.g:471`/`Ra.g:1361`), and a live cast's
        `%MusuThem` is structurally non-promotable to a `%Record` (`Ra_holding_keys()`
         exclusion). So the four tiers already compose; **universalising per-frame signing is
          HARDENING, not a ship-blocker for pool exchange** (the earlier "land before pool
           exchange" is withdrawn — Captain↔Captain transfer rides the *vouched* Heist path, not
            raw gossip). If pursued later, the bounded work is unchanged (sign+verify the four
             gossip types + repli sender identity); the one invariant worth a Book first is the
              `%MusuThem`-never-promotes-off-vouch guard §0 names.
- **Multi-Cave is NOT guaranteed** (v1 stance: one Cave, one Captain, more bodies at your
   own risk). Someday-sharpening (the owner, 2026-08-26): a booting body should tell
    **within ~40s** whether someone is already around using an address, by reading marks on
     an agreed schematica. Audited: the natural signals already exist — the account mirror
      writes `.jamsend/account/<prepub>/toc.snap` on a **~20s cadence** on a live daemon
       (fingerprint-gated, so quiet when nothing changed — an mtime probe must allow that),
        with `berth/Newlyadded` and `berth/<prepub>/KeepMemo` mtimes as activity
         corroborators. One correction to the premise: `rw_op` is request-response, not a
          refresh loop — nothing today rewrites on a timer EXCEPT the account mirror, so the
           schematica either reads the mirror's mtime (free, ~40s detection on an active
            body, silent on an idle one) or adds a tiny `.jamsend/liveness/beat` written on
             the mirror's own seam (cheap, honest even when idle). Design owed; both halves
              are small.
- **Is a tab a whole Identity, or an address + a SelfType?** Today every tab autogens its own
   identity unless it restores one; the sibling roster is the local we-are-one-user glue. The
    multipliable addresses (`<prepub>_N`) soften the old reason for per-tab identities: a tab
     could instead be *a pointer to a part of the main Identity's business* — an address plus
      a SelfType saying which duties it carries. Undecided; the answer decides what %Sibling
       rows contain (identities vs addresses) and what the LinkDevice graft actually mints for
        a same-house second tab.
- **%Grant revocation — audited 2026-08-26: the rails hold, with two eyes-open caveats.** A
   soul cannot be revoked (a stolen body IS the soul — the only remedy is rotation: new
    keypair, signed succession, friends re-seal; undesigned, rare, accepted). A *grant*,
     though, revokes cleanly: `Swarm_revoke` mints a signed `%NotGrant` atom
      (`mint_revoke`), stashes it AND forces an account settle before returning (durable
       immediately), `Swarm_pier_live` consults it at **every** use, rehydrate re-creates
        the `%NotGrant` on every standup, and `Swarm_seal` dedups grants by `to+by` — so a
         stale snap or berth fold **cannot resurrect a revoked grant**. The role grants of
          §7 ride these exact rails with zero changes (the feature is a parameter all the
           way down) — so a defected Cave is cut off the same way a defriended peer is.
            The caveats, recorded so nobody over-trusts: (1) revocation is **lazy** — no
             wire frame tells the revoked party; they discover it when the next
              `Swarm_pier_live` check refuses them. (2) **in-flight streams finish** — only
               the next request sees the `%NotGrant`. Both are acceptable-by-design for
                Music; for a revoked CAVE (which holds your whole account) they mean: cutting
                 off a Cave stops its *service*, not its *knowledge* — what it already
                  replicated, it keeps. Only rotation truly un-knows a body.
- **At-rest encryption — RULED not yet (2026-08-27).** Any body can pop the admin console
   for the cohort it belongs to — that is democracy among your own bodies, and it is the
    point. A crypto layer (account wrapped under the vessel key at rest) goes in there some
     day, but people's disks are supposed to be fairly secure, and bothering the user to
      unlock things every session is a worse trade today. Recorded so the someday-door is
       marked, not open.
- **A naming preen: "Steal Back".** The verb (`Swarm_steal_back`) CONCEDES the contested
   name and steps aside to a suffix — the reclaim is `Swarm_reinstate`. The name reads
    backwards for what it does; candidates like "Step Aside" would read true. The human's
     call — recorded because two readers have now tripped on it.
- **The no-shared-anything bound** (`Identity_persist` §7.4i). Two bodies sharing neither
   filesystem nor relay have no common point to reconcile at; no lease covers them. Either
    full Tier-B/C sync or the house rule "one soul, one home at a time." A graft that is born
     still (§7) keeps the default on the right side of this.
- **The friend-side pier seam — RULED SOLVED IN PRINCIPLE (2026-08-27), verify in code.**
   The ruling: a friend holds one %Pier **per body** — multiple %Pier rows sharing one
    %Identity, each keyed by the address it talks to (`<prepub>` and `<prepub>_1` are two
     Piers that know they are one soul) — so per-body wire state (seq, era, windows) never
      converges. The code already leans this way: `o({ Pier: 1, pub: from })` is handled as a
       PLURAL (`Swarm.g:1013`). What remains: verify the repli window and era state actually
        key off the per-body row and not a first-match, and note that the protocols being
         built will refer to Captain|Cave subtly — a Pier should know its counterparty's
          SelfType, not just its address.
- **The graft's transport — RULED (2026-08-27): it rides the Heist machinery,
   continuously.** The account stream is chunked, resumable, grant-gated repli transfer —
    the gears exist — and it is a STANDING stream, not a ceremony payload: the bodies all
     back each other up, continuously (§7). Remaining design is just the lane naming (what
      shelf-set flows on which cadence) — no new transport.
- **Vessel-key mortality — SPECIFIED (2026-08-27).** The vessel key is per-instance (§1);
   a re-grafted device is a NEW instance with a new vessel, and the human may forget the old
    one — forgetting retires its cohort-roster row. What remains: the roster's aging story
     for vessels that vanish WITHOUT being forgotten (a ghost row should fade, not linger as
      a permanent 👥 suspect).
- **Instance memory — more to make up.** Where a body remembers which instance it is (§1):
   instance-scoped, at the top of the one slope of persistence (Dexie|FSA behind one
    abstraction), never mixed across souls. Undesigned: its exact home (a Dexie table keyed
     by nothing? a reserved OPFS file?), what it holds beyond vessel+SelfType+souls-held,
      and how the one-body-many-souls case (a family's shared daemon — the daemon boots one
       `I=` today) reads it. V1 stance: one soul per Cave; revisit deliberately.
- **Pool quota numbers** (§3). A cap, an eviction order, the persist() request (§0 item
   9b) — small, but someone must own the numbers.

---

## 11. Primitive inventory (what the code already gives us)

Verified at the time of writing; re-check before relying (a named symbol may have moved).

- **identity ≠ address** — `Ghost/S/Swarm.g` §region "places" (~3559): `Swarm_address`
   (address ?? name), `Swarm_next_suffix` (`<prepub>_N` from `_1`), `Swarm_steal_back`
    (concede + jump), `Swarm_reinstate` (bare name + `account_mirror_stale` disk-wins hold),
     `Swarm_sibling` / `Swarm_is_sibling`, `Swarm_note_theft` / `Swarm_stolen` (`%Stolen`
      husk + 👥 surface via `DoorFace.svelte`). All session-local, omitted from every export.
- **the wire dial (the gap)** — `Ghost/N/Tribunal.g:63,65` `Socket_real`: `addr =
   peering.sc.name`, captured once into `/relay?addr=`; never re-reads `Swarm_address()`,
    never re-dials on change. **Item 1 lives here.**
- **relay routing** — `src/lib/server/relay.ts`: `locals` (addr → Set, ~120), `deliverLocal`
   (fan-out to all `qaddr===to` station sockets, ~229), `ackBack` (corr-route, unbound CLI
    only, ~126), additive `bind`, no delivery gate in `handleHello`. ⚠ the file carries a NUL
     byte — grep runs binary-silent; `tr -d '\000'` first, or use the Read tool. Run
      `scripts/relay-test.ts` after touching it (it encodes the individuation contract no
       Book covers).
- **music routes to the asker; auth by pub** — `src/lib/gen/N/Repli.go:504,654` (pages
   `to: h.from` via `reply_to`); grant check `prepubOf(pub)` — `Ghost/S/Swarm.g` (~71).
- **Tier C (the consumable ledger)** — `Ghost/S/Swarm.g` iz region (~200–315):
   `Swarm_iz_issuer` (`next`), `Swarm_claimed_has/add` (the `claimed` run-list codec),
    `Swarm_token` (the compact QR codec `<prepub16>*<serial>*<n>*<presig16>`).
- **the berth append-door (Tier B transport)** — `Ghost/M/Heist.g`: `Berth_append` /
   `Berth_save` fold-supersede by key (~4074).
- **OPFS nav** — `src/lib/O/WormholeOpfs.svelte.ts`: `OpfsOverlayNav`, seed+scratch overlay
   on `navigator.storage.getDirectory()`, same read_file/write_file/dir contract as every
    nav — the shape the SoundPool store should ride.
- **transcode (the press)** — daemon-native ffmpeg stocking (probe|measure|encode, boot line
   in `scripts/daemon/main.ts`); `Ghost/M/Radio.g` `Ra_transcode_ensure|advance`
    (demand-driven HIFI→stream press — the pool press is the same gears, new destination).
- **integrity vocabulary** — `body_hash` rides every repli frame header (`Repli.go`).
- **revocation** — `Ghost/S/Swarm.g:3311` `Swarm_revoke` → `mint_revoke` (`Grant.ts:108`,
   signed `%NotGrant` atom) → `Swarm_pier_stash` + `Swarm_account_settle` (durable before
    return); checked at every use by `Swarm_pier_live` (~3323); rehydrated on standup
     (~1967); `Swarm_seal` dedup makes it resurrection-proof. Feature-generic throughout.
- **the generic Feature flow** — `Swarm_iz_issuer` (~215, any `{Feature,...params}` →
   `to:<mainkey>`), `Swarm_token_n` (~109), redeem/hello/accept (~1538–1665) — none inspect
    the Feature; the serve layer's six `Swarm_pier_live(p,'Music')` sites are the only
     hardcoding (§7).
- **record path semantics** — `Ghost/M/Ra.g:1388-1452` `Ra_record_from` (`sc.path` =
   base-relative join, `sc.id` = sha256 of source bytes); base+path split rides `.c` on the
    radiostock card (~1410); `MountNav.svelte.ts` routes per-method by mount prefix — the
     seam the pool mount rides (§3).
- **the relay's one verification** — `relay.ts` `hello` (~568): ed25519 over the header
   binds a prepub to its socket at connect; nothing per-frame after that (§10 signing
    floor).
- **listening-only boot (the Captain's posture)** — `Housing.svelte.ts` boot_role branch
   (`H.c.listen_only`), landed 2026-08-15; NOT yet verified on a real phone — §0 item 9a is
    the gate.
- **the disk write-lease** — `Identity_persist` §7.4f; daemon guard `scripts/daemon/main.ts`
   (`Swarm_address` check + stale hold); browser guard `src/lib/O/Auto.svelte`
    (`Clustation_mirror_account`).
