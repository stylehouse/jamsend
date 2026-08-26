# Portability_todo.md

Account portability — one **soul**, many **bodies**: carry an identity to a second device, let
 each body do the work it is placed to do (the phone wants, the station executes), and hand
  authority around without corrupting the ledger or doubling yourself on the wire.

> Status: working `_todo`, written spec-close but **not** self-promoted. The mechanics below are
>  verified against the code (file:line inventory in §10); the *design* is proposed and wants the
>   human's preen before any of it is blessed `_spec`.
>
> Sibling docs, and what each owns: **`MobilenoFSA_todo` is FOLDED INTO THIS DOC**
>  (2026-08-26; the file is in `spec/history/` with a historicity notice) — its dated rulings
>   (the LinkDevice ceremony 2026-08-14, the `%Idzeug` block lease, the listening-only wire,
>    the %Like plan) live on below and keep their dates. **`Onboard_todo`** owns the first-run
>     funnel (namer bubble, welcome, invite landing). **`Daemon_todo`** owns the
>      phone-commands-station-executes verb arc (pokes, `PLAYER_OPS`); this doc owes it only
>       the wants ledger. **`Identity_persist` §7.4** owns the disk write-lease this extends.
>        **`Cluster_spec` §3** owns the relay. **`Persistence_todo`** is the durability arc
>         underneath.

---

## 0. Where to start, and the arc

**The destination.** A person's phone is the **Captain** — the soul's home, the social hand, the
 wanting surface — and it needs no folder access at all. A station with a real filesystem is the
  **Cave** — where the library lives, where Heists are fulfilled, where everything is backed
   up. The Captain likes and wants; the Cave acquires and keeps. Music flows back to the
    phone as a **SoundPool** — LOFI listening copies in OPFS — and two phones meeting in the
     world can swap SoundPool material directly, seeding introductions their Caves later
      fill out as Originals. Authority stays with the Captain; durability lives with the
       Cave; and no step double-spends an invite or doubles a name on the wire.
  The funnel (ruled 2026-08-14): the phone is the FIRST TOUCH — cold arrival → listening only
   → likes accrue → LinkDevice → the same identity on a capable station actions the wants.
  And a working bet to hold loosely (the owner, 2026-08-26): **pool↔pool exchange between
   phones may be the MAJORITY way music actually moves** — most transfer live and LOFI, hand
    to hand, with the Caves as the archival minority that HIFI-ifies what the pools discover.
     Design the pool paths as primary, not as a nicety bolted onto the library.

**What already exists** (so this is wiring, not invention):
- The **identity ≠ address** split, with suffix machinery: bare `<prepub>` is the primary place,
   `<prepub>_1` a second body's place; Piers verify by `pub`, so a suffix costs routing, never
    recognition. `Swarm_next_suffix` / `Swarm_steal_back` / `Swarm_reinstate` exist. (§4, §10)
- The **LinkDevice ceremony**, ruled (2026-08-14, ex-MobilenoFSA §3): a live self-Invite on the
   invite rails — high-entropy, single-use, short-lived, both devices online, account frames
    encrypted under a code-derived key, matching-emoji confirm. (§7)
- The **`%Idzeug` block lease**, ruled (same ruling): each linked device draws invite serials
   from its own range — no shared counter, no double-spend, no "primary". (§2C)
- The **wants ledger**: `%Jam,with:<dj>` + `%Like/%Spin/%Grab,of:<id>` referring particles
   (Ghost/M/Jam.g) — pure verbs, idempotent, today called only by a Book. The Captain's
    want-book is already shaped. (§5, §10)
- **OPFS plumbing**: `WormholeOpfs.svelte.ts` — an overlay nav (read-only seed under a scratch
   layer) speaking the same read_file/write_file/dir contract as every other nav. The SoundPool
    has a nav shape to ride. (§3, §10)
- The **disk write-lease** (`Identity_persist` §7.4f) and the **👥 collision tripwire** (a frame
   from our own key raises the alarm) — the safety rails under any handoff. (§8, §10)
- **Transcode machinery**, Cave-side: the daemon's native ffmpeg stocking (probe|measure|
   encode) and Radio's demand-driven transcode path — the HIFI→LOFI press already runs. (§3)

**What is missing** (the work this doc scopes):
1. **The wire is not plumbed to the address.** `Socket_real` dials `peering.sc.name` (bare),
    captured once; a Steal Back moves a field the relay never hears. (§4, §10)
2. **The SoundPool itself** — the OPFS audio shelf, its ledger, its cap, its eviction. (§3)
3. **The loosened landing head** — the Heist's landing seam assumes the real-FS share today;
    it must write through ANY nav (the OPFS nav speaks the same contract), so a Heist can land
     **in a pool** as readily as in a library. (§3)
4. **The pool exchange** — phone↔phone LOFI swap, live, no Cave required — possibly the
    majority transport (§0). (§5)
5. **The smuggle** — Captain→Cave backup of the SoundPool *and* the account, with every
    pooled LOFI standing as a want for its Original. (§5)
6. **The mend verb** — one machinery for "this copy is deficient, a better one exists":
    LOFI→HIFI upgrade and bit-rot repair are the same want. New interface to design. (§3, §9)
7. **The quick/still lease + adoption handoff** — who may touch the consumable ledger, and how
    a daemon takes over cleanly. (§6, §8)
8. **Relay-enforced exclusivity** — today two bodies at one address is cooperative-avoided,
    not prevented. (§4, §9)
9. **The phone push, in flight** (ex-MobilenoFSA §0 — "at least it does radio", 2026-08-19):
    (a) THE release gate — verify on a real phone that a friend's stream actually plays in
     `listen_only`; concrete risk: no nav in that mode, so if any tune-in/jam-join path needs a
      nav WRITE, radio silently no-ops on device while dev looks green — field trip only, not
       settleable headless. (b) `navigator.storage.persist()` at boot — one line, auto-granted
        once PWA-installed; the cheap mitigation for "clear browsing data = identity death".
         (c) the 🎧 badge on Door's self line + the mortal-identity whisper — `H.c.listen_only`
          is read NOWHERE in the UI today; the badge makes the mode legible and is where to
           whisper that a shareless identity is mortal until LinkDevice lands.

**Candidates to get on with next** (none blocks the others):
- Plumb `Socket_real` to dial `Swarm_address()` and re-dial on change — smallest change, widest
   payoff; it turns the existing suffix primitives into a working "step aside so my other body
    can have the name" gesture, which the whole tandem stands on.
- The %Like button + durable want row (§5 Flow 1 carries the folded plan; the Captain side of the tandem
   starts there, and it is deliberately buildable before LinkDevice).
- Draft the SoundPool shelf shape (§3) — the pool ledger + OPFS layout — since exchange,
   smuggle, and mend all read it.

---

## 1. The vocabulary

- **Soul** — the keypair. Immutable, key-derived, the thing `ident.sc.prepub` names. One soul
   per account, however many devices hold it.
- **Body** — a device (tab, phone, daemon) holding a soul. Bodies of one soul are `%Sibling`s
   when cooperative; an unrecognised body wearing your soul is a **theft** (`%Stolen`).
- **Vessel key** — a body's own autogen keypair, born with the device before any soul lands on
   it. What a body is addressable and encryptable-to *as itself*; the LinkDevice beacon's
    ephemeral pub plays this role in the ceremony (§7).
- **Captain** — the soul's home body, most likely the phone: no FSA (`showDirectoryPicker` is
   desktop-Chromium-only — the one hard fact, ruled ex-MobilenoFSA), storage in OPFS/Dexie only. The social
    hand (in-person QR, invites, likes) and the wanting surface. Carries **authority**.
- **Cave** — the deepest, stablest, least mobile region of a person's infrastructure: a body
   with a real filesystem (usually the laptop; at its most cave-like, an always-on daemon).
    The library's home, where Heists are fulfilled, transcoding runs, and backups land — what
     the Captain wants *wanders to the Cave* and waits there as treasure. Carries
      **durability**. The LapBob of the earlier design conversation is a Cave. (Named for the
       treasure cave, not the container: "TreasureChest" had the better image — open the
        laptop lid like a chest lid — but a chest is portable, and this concept is defined by
         being the thing that does not move. "Merchant" was the working name, retired as too
          market-flavoured for what is really a hoard.)
- **Quick / still** — a body is **quick** when it holds the consumable-ledger lease (§6); every
   other body is **still**: it replicates, Heists, and writes grow-only state, but never touches
    the invite ledger. With block leases (§2C) quickness becomes per-range rather than global.
- **SoulInvite / LinkDevice** — the invite whose redemption makes you, not befriends you.
   "LinkDevice" is the ruled ceremony name (2026-08-19, after Signal/WhatsApp); "SoulInvite" the invite object
    itself. One thing; the human may pick one word.
- **Original** — the HIFI holding: a `%Record` in a real-filesystem `%Library`, the Cave's
   charge, the librarian's object of interest.
- **SoundPool** — a body's OPFS audio shelf: LOFI listening copies pressed from Originals (or
   received from another pool). A cache with a ledger — never a second library.
- **LOFI / HIFI** — the fidelity axis (§3). A pool copy is LOFI by station; an Original is the
   HIFI it wants to be.
- **Want / mend** — a want is a durable "acquire this for me" record (%Like is its first form);
   a mend is a want whose subject already exists here but deficiently (LOFI where HIFI is
    grantable, or a corrupt chunk where a healthy one exists). One machinery (§3).

Notation follows `CLAUDE.md`: `%Sibling`, `%Stolen`, `%Idzeug`; a property as `Peering%address`.

---

## 2. An account's data, by merge behaviour

Portability is a merge problem, and an account is three tiers that merge differently. The tier
 boundaries are what make "the Cave may Heist but not spend" precise rather than a vibe.

**Tier A — immutable (the soul).** The keypair. Never merges because it never changes;
 replication is the one-time secure ceremony of §7.

**Tier B — grow-only (friendships, grants, Heisted tracks, the newlyadded berth, the wants
 ledger, the pool ledger).** Append-mostly sets keyed by stable identities. Two bodies each
  befriending different people, or landing different tracks, or accruing different likes,
   **union-merge** cleanly — the berth append-door already folds parts by key, a log-structured
    merge waiting to be pointed at two devices. A still body writes this tier freely to its OWN
     replica; adoption (§8) takes the union. The %Jam shape is already merge-safe by design
      (ruled ex-MobilenoFSA §2: append-only events with `at` + device provenance merge trivially; a
       mutable "liked: yes/no" flag would not — that ruling generalises to every Tier-B shape
        this doc adds, the pool ledger included).

**Tier C — consumable (the invite ledger: `%Idzeug` `next` + `claimed`).** The poison. A serial
 spends exactly once; `claimed` is a run-list set (`"3-5~9~14"`) in one scalar, and the berth
  fold LWW-supersedes whole scalars — so two bodies ticking serials off the same issuer lose one
   tick silently, and **an invite un-spends** (the security property `Identity_persist` names).
  **The ruled answer is the block lease** (ex-MobilenoFSA §3, via the old garden's
   `IdzeugNumberLeap` +800): each linked body draws serials from its own disjoint range — no
    shared counter, no double-spend, no primary. Under block leases, Tier C is per-range
     single-writer, which unions as safely as Tier B. Until a body HOLDS a block lease it does
      no invite processing at all (the conservative v1 posture; §6).
  What no tier gets for free: per-field last-writer-wins by *causal* time. A snap carries no
   vector clock; the fold decides by part order on disk. Fine for a nickname; not fine where
    "which edit truly came later" is load-bearing.

---

## 3. The fidelity axis — Originals, the SoundPool, and the mend

**Two stations of being for one piece of music.** The **Original** is the holding: `%Record` in
 a `%Library` on a real filesystem, the Cave's charge. A **pool copy** is a LOFI pressing in
  some body's OPFS SoundPool, made for listening on a device that cannot (and should not) hold
   the library. The librarian's interest runs entirely to Originals; the pool is the people's
    music — portable, lossy, expendable.

**Identity across fidelities follows the standing law** (`CLAUDE.md`, "identity is per-shelf"):
 a pool copy is a **referring particle wearing its own mainkey** — `%Pool,of:<id>` (name to
  preen) beside its chunks — never a second `%Record` impersonating the holding. The `of:` join
   is what lets a pool copy *want* its Original, survive transcoding, and dedup across pools.
    The old magazine minted exactly this bug once; the tell is two shapes under one mainkey.

**The OPFS reality that shapes the pool.** OPFS works on phones and is invisible to the OS file
 manager ("hella inaccessible" — which is fine: it is a cache, not a collection). It is also
  **evictable**: browser storage pressure can clear it, and "clear browsing data" kills it
   outright (§0 item 9b owes the `navigator.storage.persist()` request at boot — cheap
    mitigation, auto-granted once PWA-installed). Two consequences, both load-bearing:
  - **The pool is designed expendable.** A pool entry is re-pressable from its Original; losing
     the pool loses convenience, never music — PROVIDED the smuggle (§5) has run, so the pool
      ledger (what was pooled, from what, at what fidelity) outlives the pool bytes.
  - **The pool needs its own economy**: a size cap, an eviction order (least-recently-listened
     first, wants-pinned last), and honesty in the UI about what is pooled vs merely wanted.

**The press.** HIFI→LOFI transcoding is Cave work and the machinery already runs: the
 daemon's native ffmpeg stocking (probe|measure|encode) and Radio's demand-driven transcode
  (`Ra_transcode_ensure|advance`). SoundPooling is that press pointed at a pool target instead
   of a stream — same gears, new destination.

**The pool is a Heist DESTINATION, not only a press target** (the owner, 2026-08-26: "OPFS can
 be Heisted to as well, we need to really loosen up that exchanger head"). The Heist's landing
  head — the seam that writes landed material somewhere — assumes the real-FS share today
   (mardir, the FSA nav). That assumption is the thing to loosen, and the loosening is cheap in
    principle because **the nav contract is already the seam**: `read_file/write_file/dir` is
     the whole interface, and the OPFS overlay nav (`WormholeOpfs`) already speaks it. A landing
      head parameterised over ANY nav lets a Captain Heist straight into its own pool — no Cave
       in the loop — and lets the pool exchange (§5 Flow 3) BE a heist whose destination is
        OPFS, one machinery instead of two. What lands pool-side is pool-grade by posture
         (LOFI, expendable, `of:`-joined); the Cave remains where Original-grade landing and
          keeping happen. (This scopes the older "no heist setup on the phone" ruling of
           2026-08-15 to the v1 *UI* — likes instead of heist forms — while the *machinery*
            below it goes destination-agnostic.)

**The mend — one verb for "a better copy exists."** A LOFI pool copy that could be an Original
 (`of:` resolves, a grant stands) and a corrupt chunk whose healthy twin exists on a sibling or
  a friend are **the same shape**: a deficient copy naming a better one by content identity.
   So they share one machinery — a **mend want**: minted by an audit (hash walk over chunks;
    `body_hash` already rides every repli frame, so the wire's integrity vocabulary exists) or
     by policy (all LOFI wants HIFI-ification when its Original is reachable), fulfilled by
      whatever body holds the better copy, at whatever pace the fulfilling body's station
       affords. Bit-rot repair over time is then not a new subsystem — it is the mend loop
        running slowly over Tier-B holdings forever. **The interface for this is undesigned**
         (the owner: "that's a bit of new interface to design huh") — §9 carries it.

---

## 4. The relay — how bodies coexist, and how they collide

The relay is a dumb address-routed forwarder; two verified facts govern the design.

**Fact 1 — delivery fans out to a SET, keyed by address.** `locals` maps an address to a *set*
 of sockets; `deliverLocal` sends a `to:<addr>` frame to **every** station socket bound under
  that address (the `qaddr === to` own-door rule prefers station sockets over role sockets, but
   among station sockets of one address, all receive). Two bodies under the **same** address is
    therefore **duplication, not division**: both receive everything, both answer, each runs its
     own sequence counter stamped `from:<prepub>`, and a friend receives two interleaved streams
      one repli window can never reconcile (`repli_missed` forever — the observed two-daemon
       disease, and the standing `[[relay-locals-additive-bind-fanout]]` lesson: the relay is an
        unauthenticated forwarder; assume an eavesdropper, expect a fan-out).

**Fact 2 — music routes to the ASKER's address; recognition rides the pub.** Repli serves pages
 `to: h.from`; grants verify `prepubOf(pub)`, independent of address. So a body receives what it
  asks for **at whatever address it asked under**, and proves itself by key, not by name.

**The consequence — bodies coexist by holding DISTINCT addresses.** A Captain at the bare
 `<prepub>` and its Cave at `<prepub>_1` (or the reverse — §9) can both be live, both talk
  to friends, both Heist: each receives its own pages at its own door, both verify as the same
   soul, neither collides. `Swarm_next_suffix` computes the place, `Swarm_steal_back` takes it,
    `Swarm_reinstate` returns to the bare name with the §7.4f disk-wins hold. Same-address
     collision is the disease; the suffix is the standing escape; the 👥 tripwire is the alarm
      for the case nobody chose.

**The gap that makes this theory:** `Socket_real` dials `peering.sc.name` — the bare canonical
 name, read once at construction — never `Swarm_address()`, and it never re-dials on change. So
  today a Steal Back moves a model field the relay never hears, and every body binds bare.
   **Plumbing the dial is item 1** and the precondition for the whole tandem.

**Enforcement is cooperative today.** `bind` is additive; `handleHello` gates nothing. Honest
 bodies avoid collision by suffixing; a crashed or modified one won't. Relay-enforced
  exclusivity (a signed-hello refusal) is §9.

---

## 5. The tandem — the Captain wants, and it wanders to the Cave

The division of labour, stated once: **authority lives with the Captain; durability lives with
 the Cave.** The Captain is where the human is — it mints and redeems in person, it likes,
  it listens. The Cave is where the disk is — it acquires, presses, keeps, and repairs. This
   is the ruled "phone commands, station executes" arc (ex-MobilenoFSA §4), given its shape in the tandem.

**Flow 1 — the want → the Heist.** The Captain accrues wants (%Like rows, the machinery
 already standing in Jam.g). Wants replicate to the Cave (Tier B — trivially).
  The Cave actions them with the Heist gears that already exist, against the friend grants
   the soul already holds.

  *Flow 1 in practice — the %Like plan, folded from MobilenoFSA §2 (recon verified
   2026-08-15).* `Ghost/M/Jam.g` already IS the ledger: `%Jam,with:<dj>` under the listener's
    shelf; `%Spin/%Like/%Grab,of:<id>,title,at` as ordered referring particles; `Jam_home` /
     `Jam_like` pure and idempotent per (kind, track) — and nothing in the live app calls them
      (only `Radiation.g`, a Book). So the build is: **a button** (display, Vyto's zone) on the
       playing face — `Jam_like(Jam_home(shelf, dj), rec)`; the dj's prepub and the mirror
        shelf are both in reach (DoorFace resolves `%MusuThem,pub` → stock today). And
         **durability, the real gap**: a %Jam minted on a live tab dies on reload — TODAY,
          even on desktop. A like that is "a record of what would be Heisted" must outlive the
           tab: on a share, a Berth (`.jamsend/berth/<prepub>/Jams`); shareless, a Dexie row
            (the thang_put shape) — same particle either way, the store is the only fork.
             Carry enough to heist blind later: `of` (enid), `title`, the dj's prepub (the
              %Jam's `with`), and `at`. The far arc, the owner 2026-08-15, kept verbatim so it
               isn't flattened: *"I suppose that becomes a multiplicity thing later... having
                one's entire life+times with some piece of music."* — %Jam is the seed of
                 that: a per-relationship ledger of events over tracks; multi-device merge
                  makes it per-LIFE rather than per-session. The confusing-sounding sentence from the design conversation is
    exactly right and worth keeping: **the Cave carries out the Heist "from the other
     Captain"** — the *grant chain* traces Captain-to-Captain (souls befriend souls, in person,
      by QR), while the *bytes* flow Cave-to-Cave (the bodies with the libraries and the
       uptime). Socially it is two people sharing music; mechanically it is their two stations
        doing the lifting overnight.

**Flow 2 — the pool press.** The Cave presses Originals to LOFI and fills the Captain's
 SoundPool (over the wire, to OPFS), so the phone actually *listens* — the Captain's music
  comes back to the Captain's hand. Pool contents are chosen by the human and by policy
   (recently liked, recently jammed); the pool cap governs (§3).

**Flow 3 — the pool exchange, possibly the MAJORITY transport** (§0's working bet). Two
 phones in a room swap SoundPool material directly: live, phone↔phone, LOFI only, no Cave
  online. Not so exciting to the librarian — nothing archival moves — but socially potent,
   and mechanically it is just **a Heist whose landing nav is OPFS** (§3, the loosened head):
    one machinery, two destinations. Each pooled track arrives as a **referring particle with
     its `of:` identity intact**, so it is simultaneously (a) listenable now, LOFI, and
      (b) an **introduction** — a want the receiving side's Cave can later fill out as an
       Original, through Flow 1, under whatever grant the two souls' friendship carries. The
        exchange is the discovery surface; the Caves make it a collection. If the majority
         bet holds, most music a person carries will have arrived THIS way — so the pool
          paths get first-class design attention, and the Cave's role sharpens to what only
           it can do: keep, verify, and HIFI-ify.

**Flow 4 — the smuggle.** The Captain's SoundPool (and the Captain's whole account — see §9,
 the phone's storage is mortal) replicates to the Cave **for backup**, not for listening:
  the Cave regards every arriving pool copy as **LOFI that wants to be HIFI-ified** — a
   standing mend want (§3) against the `of:` Original, fulfilled when the Original is reachable
    (its holder's Cave online, a grant standing). So the backup is also the upgrade queue,
     and the pool's expendability (§3) is underwritten: bytes may die with the browser; the
      ledger and the wants live on the Cave's disk.

---

## 6. Two shapes, and the lease

**Shape 1 — primary/replica over Tier C (v1).** One quick body per issuer range; still bodies
 do no invite processing at all. The conservative posture from the design conversation ("LapBob
  cannot do any Invite processing") — nothing to merge, no double-spend possible.

**Shape 2 — block leases (the ruled destination).** the ruled serial-range split (§2C) makes
 every linked body quick *over its own range*: the Captain redeems and mints in person from its
  block; a Cave could mint from its block if a flow ever wants that. Union-merges safely by
   construction. Shape 1 is just "only the Captain holds a block yet," so the graduation is
    allocation, not rearchitecture.

**The lease is narrow on purpose.** It covers Tier C only. A still body reads everything,
 Heists freely, writes its own Tier-B replica (tracks landed, wants accrued, pool ledger) —
  forbidden only the consumable ledger. That is what makes a Cave useful while safe.

**Quick↔still is a wire transition, not a permission bit.** A body standing down must actually
 unbind/re-dial its address (§4) — as long as it stays bound at a contested name it keeps
  receiving and answering the soul's fan-out, doubling streams even with the ledger untouched.

---

## 7. The graft — LinkDevice / SoulInvite

**The ceremony is ruled; this doc defers to it** (ruled 2026-08-14/19, ex-MobilenoFSA §3, kept in force):

- An invite **whose redemption makes you, not befriends you** — same rails as any invite
   (compact code, relay addressing, voucher verify), inverted consequence. Therefore:
    high-entropy, **single-use, short-lived (minutes), never posted**.
- **Both devices online is a feature**: the account travels as relay frames **encrypted under a
   code-derived key** (the relay is an unauthenticated fan-out forwarder — assume an
    eavesdropper), and liveness lets both screens show a **matching confirm** (same emoji pair)
     before key material moves.
- **The carry**: (a) the desktop shows its beacon (addr + ephemeral pub) as QR and the phone
   scans — the secret never touches a third party; build this. (b) a typed short code as the
    no-camera fallback — tolerable only because single-use + short-lived.
- **What moves**: the account Waft — `Identity,key` + `Peering` — with `%Idzeug` issuer state
   split by block lease (§2C), never a shared counter.

What this doc adds to the ruling, in tandem terms: the redeeming body is born **still** (no
 block lease at graft; allocation is explicit, §6), it is born a **%Sibling** (registered
  cooperative co-holder, so the theft discriminator knows it), and it takes a **suffix address**
   on first bind (§4) so the graft never collides with the granter on the wire. The ephemeral
    beacon pub is the **vessel key** doing its job: the thing the transfer is encrypted toward,
     proven live by the matching confirm.

Distinct in kind from a music `%Idzeug`: that grants *what you'll serve*; this grants *who you
 are* — the most dangerous token the system can mint, handled accordingly.

---

## 8. The adoption handoff

The owner's arc: the Captain runs with a laptop Cave for a while; later "spins up a daemon
 to do everything, using the laptop's latest replica, and perhaps telling any body online at
  that point what's up." As a protocol:

1. The daemon boots as a **still** body and **adopts the freshest replica** — a wholesale take
    of Tier A + a union of Tier B (the laptop was the working Cave, so its copy is
     freshest; adoption is a copy-and-union, never a live merge).
2. The daemon announces it will take the Cave's place; online bodies ack.
3. The standing Cave **stands down**: stops fulfilment, unbinds its address (§6).
4. The daemon **binds** and takes up fulfilment; any Tier-C block the old Cave held (Shape
    2 only) transfers or retires.

Ordered with an ack, the two-body window at any one address is a controlled instant; skipped,
 it is the doubled-stream disease on purpose — which the 👥 tripwire will catch and say so.
  `Swarm_reinstate`'s disk-wins hold guards the bare name specifically: a body taking it back
   must re-read disk before it may write, so a stale adopter cannot clobber a fresher ledger.

---

## 9. Open questions

- **Who stands at the bare name — Captain or Cave?** Friends address the soul at bare
   `<prepub>`. Inbound *heist asks* want the Cave (the library, the uptime); inbound
    *invite redemptions* want the Captain (the ledger hand, v1). One address cannot land both
     at both. Candidates: the always-on Cave holds bare and **forwards invite-class frames
      to the Captain over the sibling channel**; or redeem flows learn suffixed addresses; or
       pier_accept reveals the working address per flow. Undecided — and it gates nothing in
        §0's next-candidates, so decide it with the lease work, not before.
- **Relay-enforced exclusivity.** Cooperative unbinding is honoured by honest code only.
   Enforcement needs the relay to refuse/evict a second claimant **on a signed hello** (else
    anyone knowing your prepub locks you out of your own name). Wire-format + `handleHello`
     work, `Cluster_spec` territory.
- **Cross-machine sibling roster.** `%Sibling` is fed by the local Dexie roster today; a body
   on another machine is invisible to it, so the theft-vs-cooperative discriminator is blind
    exactly where it matters. Siblings should register through the relay's verified hellos
     (LinkDevice is the natural minting moment — §7 already makes the graft a %Sibling).
- **The lost body — revocation is rotation.** A stolen phone or laptop *is* the soul: same
   key, indistinguishable by construction. There is no revoking a body without **rotating the
    soul** — a new keypair, a succession statement signed by the old key, friends' clients
     honouring the succession and re-sealing. Expensive, rare, and currently **undesigned**;
      until it exists, the honest posture is the mortal-identity whisper generalised: a body holds
       your whole identity — guard it like one. (The SoulInvite's short life and matching
        confirm exist to keep grafting from ever being the leak.)
- **The mend interface** (§3). What mints an audit, where wants surface in the UI, what pace
   fulfilment runs at, and how "pinned by want" interacts with pool eviction — the new
    interface the owner named. Wants designing beside DoorFace/Vyto, not in this doc.
- **Pool quota + eviction policy** (§3). A cap, least-recently-listened eviction, wants-pinned
   last, and the persist() request landed (§0 item 9b) — small, but someone must own
    the numbers.
- **The no-shared-anything bound** (`Identity_persist` §7.4i). Two bodies sharing neither
   filesystem nor relay have no common point to reconcile at; no lease covers them. Either
    full Tier-B/C sync or the house rule "one soul, one home at a time." A graft that is born
     still (§7) keeps the default on the right side of this.

---

## 10. Primitive inventory (what the code already gives us)

Verified at the time of writing; re-check before relying (a named symbol may have moved).

- **identity ≠ address** — `Ghost/S/Swarm.g` §region "places" (~3559): `Swarm_address`
   (address ?? name), `Swarm_next_suffix` (`<prepub>_N` from `_1`), `Swarm_steal_back`
    (concede + jump), `Swarm_reinstate` (bare name + `account_mirror_stale` disk-wins hold),
     `Swarm_sibling` / `Swarm_is_sibling`, `Swarm_note_theft` / `Swarm_stolen` (`%Stolen` husk
      + 👥 surface via `DoorFace.svelte`). All session-local, omitted from every export.
- **the wire dial (the gap)** — `Ghost/N/Tribunal.g:63,65` `Socket_real`: `addr =
   peering.sc.name`, captured once into `/relay?addr=`; never re-reads `Swarm_address()`,
    never re-dials on change. **Item 1 lives here.**
- **relay routing** — `src/lib/server/relay.ts`: `locals` (addr → Set, ~120), `deliverLocal`
   (fan-out to all `qaddr===to` station sockets, ~229), `ackBack` (corr-route, unbound CLI
    only, ~126), additive `bind`, no delivery gate in `handleHello`. ⚠ the file carries a NUL
     byte — grep runs binary-silent; `tr -d '\000'` first, or use the Read tool. Run
      `scripts/relay-test.ts` after touching it (it encodes the individuation contract no Book
       covers).
- **music routes to the asker; auth by pub** — `src/lib/gen/N/Repli.go:504,654` (pages
   `to: h.from` via `reply_to`); grant check `prepubOf(pub)` — `Ghost/S/Swarm.g` (~71).
- **Tier C (the consumable ledger)** — `Ghost/S/Swarm.g` iz region (~200–315):
   `Swarm_iz_issuer` (`next`), `Swarm_claimed_has/add` (the `claimed` run-list codec).
- **the berth append-door (Tier B transport)** — `Ghost/M/Heist.g`: `Berth_append`/`Berth_save`
   fold-supersede by key (~4074).
- **the wants ledger** — `Ghost/M/Jam.g`: `%Jam,with` + `%Spin/%Like/%Grab,of` referring
   particles; `Jam_home`/`Jam_like` pure + idempotent; live-app callers: none yet
    (§5 Flow 1 owns wiring the button + durability).
- **OPFS nav** — `src/lib/O/WormholeOpfs.svelte.ts`: `OpfsOverlayNav`, seed+scratch overlay on
   `navigator.storage.getDirectory()`, same read_file/write_file/dir contract as every nav —
    the shape the SoundPool store should ride.
- **transcode (the press)** — daemon-native ffmpeg stocking (probe|measure|encode, boot line
   in `scripts/daemon/main.ts`); `Ghost/M/Radio.g` `Ra_transcode_ensure|advance` (demand-driven
    HIFI→stream press — the pool press is the same gears, new destination).
- **integrity vocabulary** — `body_hash` rides every repli frame header (`Repli.go`); the mend
   audit (§3) speaks a language the wire already speaks.
- **listening-only boot** — `Housing.svelte.ts` boot_role branch (`H.c.listen_only`), the
   Captain's no-FSA posture, landed 2026-08-15 (ex-MobilenoFSA §1; NOT yet verified on a real phone — §0 item 9a is the gate).
- **the disk write-lease** — `Identity_persist` §7.4f; daemon guard `scripts/daemon/main.ts`
   (`Swarm_address` check + stale hold); browser guard `src/lib/O/Auto.svelte`
    (`Clustation_mirror_account`).
