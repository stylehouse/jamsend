# Portability_doc.md

**Relationship to `Portability_todo.md` (2026-10-15): this is meant as the reader-facing calm
 summary — but it was last written 2026-08-27, before the cert-crew account model landed, so §2,
  §4, §9, §10, §11 and part of §12 below were STALE in the same way the todo was, and are
   corrected in place here. Read `Crew_todo.md` for the live account model; the "superseded by
    Crew" notes below say what changed and why.**

Account portability: one soul, many bodies. Carry an identity to a second device, let each
 body do the work it is placed to do, and hand authority around without corrupting the ledger
  or doubling yourself on the wire. The two bodies that matter are the Captain — the phone in
   your hand — and the Cave — the deep, stable, disk-bearing machine at home.

> This is the calm, linear statement of the design. The working status — what landed, what is
>  proven, what to get on with next — stays in `Portability_todo.md` §0. Sibling docs:
>   `Crew_todo` owns the account model itself (keys as particles, the ledger as the mutex, the
>    LinkDevice/`Grant:Crew` ceremony) — read it, don't edit it from here. `Onboard_todo` owns
>     the first-run funnel; `Daemon_todo` owns the phone-commands-station-executes verbs;
>      `Identity_persist` owns the account mirror and disk write-lease; `Cluster_spec` §3 owns
>       the relay; `Mag_todo` §0.2e owns the replication successor design this doc leans on in
>        §5.

## 1. The destination

A person's phone is the Captain: the soul's home, the social hand. It needs no folder access
 at all. A station with a real filesystem is the Cave: where the library lives, where Heists
  are fulfilled, where everything is backed up. What you'd Heist wanders to the Cave and waits
   there as treasure; music flows back to the phone as a SoundPool — lofi listening copies in
    OPFS — and two phones meeting in the world can swap SoundPool material directly, seeding
     introductions their Caves later fill out as Originals. Authority stays with the Captain;
      durability lives with the Cave; no step double-spends an invite or doubles a name on the
       wire.

The funnel: the phone is the first touch — cold arrival, listening only, then LinkDevice, and
 the same identity on a capable station does the heavy lifting.

A working bet, held loosely: pool-to-pool exchange between phones may be the majority way
 music actually moves — most transfer live and lofi, hand to hand, with the Caves as the
  archival minority that hifi-ifies what the pools discover. So the pool paths get first-class
   design attention, not a nicety bolted onto the library.

## 2. Vocabulary

- **Soul** — the identity's name (`ident.sc.prepub`, key-derived). **Fixed 2026-10-15,
   superseded premise:** this used to call the soul "the keypair," implying one secret every
    device ends up holding. Under cert-crew (`Crew_todo.md` §2, §4a) the soul is the relation
     among a crew's bodies: at most one body wields the soul key at a time (whichever `/Crew`
      row says `role:Captain`); every other body holds its own key and proves membership by a
       cert.
- **Body** — a device: its own ed25519 keypair, minted the first time it needs one
   (`Swarm_body_key_ensure`), never the soul's. Bodies of one soul are **crew**: a
    `/Crew,mate:<prepub>` row holding a `Grant:Crew` the Captain signed for that body's own key
     (Crew_todo §3) — never `%Sibling`s wearing a shared soul key, and never admitted by a
      roster. An unrecognised body wearing your OWN key is a theft; a Cave that merely loses
       its own key to a thief is ejected cleanly with a soul-signed `%NotGrant:Crew`, no key
        rotation needed (Crew_todo §12.3).
- **Post** (was SelfType) — what a body is within its crew: `Captain` or `Cave`. A station in
   life, not a job assignment: the signed `role` on that body's `/Crew` row (Crew_todo §2–§3),
    not a flag beside an address; advertised to peers so they can pick which body to talk to
     (§7).
- **The helm** — the authority relation: the Captain holds the helm (wields the soul key,
   alone mints `Grant:Crew`); the Cave serves it. Asymmetric on purpose — the phone is where
    the human is; the Cave obeys standing orders.
- **Body key** (was vessel key) — a body's own ed25519 keypair, minted the first time the
   device needs one — not a pre-soul placeholder, but the key the body signs and hellos with
    for its whole life. One body key per (store × soul). Moving to a new Captain may
     deliberately forget a previous body, retiring its row — a body is a place the soul's
      crew has stood, not a possession it keeps.
- **Instance memory** — the small store where a device remembers which body it is (its own
   key, its Post, souls held). Scoped to the device, never to a soul, so one browser holding
    two identities cannot mix them up. Largely still to design (§13).
- **Cohort** — the set of the soul's live bodies. "Am I alone?" is the boot question a body
   asks of it before touching the wire, and "the identity stands in one place" is the
    guarantee built on the answer: exactly one body at the bare name, every other at a
     suffix, all verified by the same key. Detection radius grows by layer: the census sees
      one browser profile (Web Lock + BroadcastChannel), the filesystem beats widen it to the
       machine, the relay hellos widen it to the world.
- **The crew ledger `/Crew`** (was "the cohort roster") — **fixed 2026-10-15, superseded
   premise:** this used to describe a `%Sibling`-derived "cohort roster" as the cross-device
    MEMBERSHIP record. Membership is never a roster lookup — it is the `Grant:Crew` cert each
     body holds, checked fresh at every friend's door (Crew_todo §5: "membership is proven at
      the door by the voucher, never by the roster"). `/Crew` (Crew_todo §3) is the durable
       record — one row per mate, role, pub, cert, any ejection — soul-signed and gossiped
        whole. The separate `%Body` roster that does exist is a **cache**, contact-learned,
         read for routing convenience only; it never admits or refuses anyone.
- **Captain** — the soul's home body, most likely the phone. No FSA (`showDirectoryPicker`
   is desktop-Chromium-only — the one hard fact of the phone arc); storage in OPFS/Dexie
    only. The social hand: in-person QR, invites, the human's presence. Holds the helm.
- **Cave** — the deepest, stablest, least mobile region of a person's infrastructure: a body
   with a real filesystem. Concretely a Chrome tab with FSA at first, the always-on daemon at
    its most cave-like — often the same machine wearing both across a day. The library's
     home, where Heists are fulfilled, transcoding runs, and backups land. Carries
      durability. (Named for the treasure cave: a chest is portable, and this concept is
       defined by being the thing that does not move.)
- **Quick / still** — a body is quick when it may write the consumable ledger, and that is
   the Captain by definition (§4, §9) — under cert-crew, simply the body whose `/Crew` row
    says `role:Captain` (Crew_todo §4a). The words survive only because the wire-transition
     rule needs them: a body going still must unbind its address, not just stop writing.
- **LinkDevice / `Grant:Crew`** (was "LinkDevice / `%Invite:MyCave`") — **fixed 2026-10-15,
   superseded premise:** this used to describe a role-Feature invite (`%Invite:MyCave`) that
    would graft the account onto the redeemer (§10, now superseded). What is live is narrower:
     the same ceremony ends with the Captain signing a `Grant:Crew` for the new device's own
      key — a credential, not a role-Feature invite needing its own serve-layer plumbing.
       "LinkDevice" stays the ceremony's user-facing name.
- **Original** — the hifi holding: a `%Record` in a real-filesystem `%Library`, the Cave's
   charge, the librarian's object of interest.
- **SoundPool** — a body's OPFS audio shelf: lofi listening copies pressed from Originals or
   received from another pool. A cache with a ledger, never a second library.
- **Lofi / hifi** — the fidelity axis (§6). A pool copy is lofi by station; an Original is
   the hifi it points at.

Notation follows `CLAUDE.md`: `%Idzeug`, `/Crew`, `%Body` name particles, `Peering%address` a
 property, and a slash pins containment — `/SingleWriter:Captain` under a row is definitely
  its child. (`%Sibling`/`%Stolen` are the pre-cert-crew names for the family roster and the
   theft alarm; the live names are `%Body` — a routing cache, never membership — and
    `%NotGrant:Crew`, an ejection.)

## 3. The ids, and the seams between them

Five id families, each with its own lifetime and verifier. Every bug in this arc so far has
 lived at a seam — where one family is translated into another — so the seams are drawn as
  first-class objects.

The soul's derivation chain: `key` (ed25519 private — secret; `.c.keys` at runtime, in clear
 in `.jamsend/account/<prepub>/toc.snap` and the Dexie identities row) derives `pub` (the
  verification truth: rides %Page in frames, %Grant.by/for, vouchers; never routes anything),
   which `prepubOf()` shortens to `prepub` (16 hex — the name: `ident.sc.prepub`, the
    directory names, QR token leg 1, the %Pier key at every friend), which an optional
     session suffix extends to `address` = `<prepub>` or `<prepub>_N` (reachability: the
      relay bind, what `deliverLocal` fans out on; session-only, omitted from export).

The chain's seams and their checks: pub↔prepub is enforced by `prepubOf(pub) === claimed`
 at every seal-minting entry and in the voucher, but not on gossip or repli frames (§12);
  prepub↔address is `Swarm_address()`, and the wire follows it — `Socket_real.home()` reads
   `address ?? name` fresh per connect and `rehome()` re-dials on change; address↔socket is
    the relay's `hello`, which ed25519-binds a prepub to a socket once at connect, nothing
     per-frame after.

One track's ids: source bytes sha256 to `id` (16 hex — what it is; the join everywhere, it
 survives every hop), beside `path` (where it is, base-relative and snap-portable —
  `music/…`, `pool/…`; the id↔path binding is runtime-only, which is why the heist re-census
   exists), `body_hash` (per-frame transport integrity, not identity), and a lofi press
    yields a new id — different bytes — carrying `of:<original id>`, the cross-fidelity join.

The ledger's ids: an issuer `%Idzeug` draws ordinal serials that ride the QR token
 (`<prepub16>*<serial>*<n>*<presig16>`; parameters stay on the issuer's record, which is the
  law); the spend ledger is a `claimed` run-list per issuer; the Captain alone draws and
   ticks (§4). Grant atoms bind full pubs, not prepubs. The seam to respect: the wire routes
    by prepub/address, but trust atoms bind pubs — never compare a grant's `by` to a frame's
     `from`; they are different families.

The wire's per-body state: each body has its own `seq`, `era`, and voucher; a friend keeps
 per-pair state (peer era, repli windows, rtt) keyed by their %Pier for you. The ruling: a
  friend holds one %Pier per body — several %Pier rows sharing one %Identity, keyed by the
   address each talks to — so per-body wire state never converges. The code already leans
    plural (`o({Pier:1, pub: from})` handled as a set); what remains is verifying the window
     and era state key off the per-body row, and giving a Pier knowledge of its
      counterparty's SelfType.

The body's own ids: the body key (what the LinkDevice beacon's ephemeral pub plays the role
 of; lives in mortal browser storage), the `/Crew` mate row (not a `%Sibling` roster row —
  §2's superseded note), and Post — which is advisory coordination among your own bodies,
   never security against a hostile one. Under cert-crew each body holds its OWN key, not a
    shared soul key, so "every body holds the same key" is exactly the premise that changed;
     what every crew body shares is the ABILITY to present a valid `Grant:Crew` and be
      trusted as the Captain — real power, but gated by a revocable cert, not by key
       possession.

## 4. The account's data, by merge behaviour

Portability is a merge problem, and an account is three tiers that merge differently. The
 tier boundaries are what make "the Cave may Heist but not spend" precise rather than a vibe.

**Tier A — the soul's name, and its one wielder.** **Fixed 2026-10-15, superseded premise:**
 this used to say "the keypair... replication is the one-time secure ceremony of §10" — the
  secret key itself travelling, once, at the graft. Under cert-crew (`Crew_todo.md` §2, §4a):
   each body mints its OWN keypair; becoming crew means receiving a signed `Grant:Crew` for
    that body's own key, a credential it presents rather than an authority conferred on itself;
     the soul's secret stays put, wielded by whichever row says `role:Captain` — a rule on the
      ledger, not a lock on the key. The soul's secret does cross a wire on one path only: the
       ferry/resume capability (Crew_todo §4), where a Cave may carry the whole `/Crew` tree,
        Keys included, sealed — held but not wielded, so it could later become Captain. That is
         a deliberate backup feature, not ordinary linking.

**Tier B — grow-only.** Friendships, grants, Heisted tracks, the newlyadded berth, the pool
 ledger: append-mostly sets keyed by stable identities. Two bodies each befriending
  different people, or landing different tracks, union-merge cleanly — the berth append-door
   already folds parts by key. The standing merge-safety rule generalises to every Tier-B
    shape: append-only events carrying `at` plus device provenance merge trivially; a
     mutable yes/no flag would not — shape new ledgers accordingly.

**Tier C — consumable.** The invite ledger: `%Idzeug` `next` + `claimed`. A serial spends
 exactly once, `claimed` is a run-list in one scalar, and the berth fold supersedes whole
  scalars — so two writers would lose a tick silently and an invite would un-spend. The
   ruled answer: the Captain takes care of all invites, full stop. The role split dissolves
    the merge problem instead of solving it — Tier C has exactly one writer by definition of
     the helm, so there is nothing to partition and no allocator to design. Caves replicate
      the ledger read-only (they must see spends to refuse a revoked peer) and never write
       it. An earlier per-body serial-block-lease design is retired; it would return only if
        two Captains were ever wanted, which nothing is.

What no tier gets for free: per-field last-writer-wins by causal time. A snap carries no
 vector clock; the fold decides by part order on disk. Fine for a nickname; not fine where
  "which edit truly came later" is load-bearing.

**The partition audit** (is the right stuff per-identity?): on disk, yes — per-soul lives
 under a prepub (`account/<prepub>/`, `berth/<prepub>/{Heists, KeepMemo, HeistDefaults,
  Faves, Musica}`), and per-collection deliberately does not (`berth/Newlyadded`,
   `berth/Census` — both would be wrong to carry to another device). In the browser, mostly —
    three fixable bleeds: identity-flavoured keys in the House.stashed Dexie row should be
     prepub-prefixed or moved; the legacy `cluster_idento`-in-stashed read should retire;
      `localStorage` prefs are origin-global, acceptable but known.

**What berth is.** Berth is the Waft-document store, not a share-tier. It holds per-soul
 docs under a prepub and soul-blind box docs without one, side by side. The account is not
  under berth at all: `account/<prepub>/` and `berth/<prepub>/` are top-level siblings on
   disk, and the daemon mirrors the account to `account/<prepub>/toc.snap`. Three homes, one
    rule: the prepub in the path says per-soul; the schema says who writes and whether it
     travels.

### The schema law-book — `%AppdataSchema`

The properties this section states in prose (keyed-by, who writes, how it merges, where it
 lives, whether it travels) want to be declared once and read by the seams — the persist
  gates, the replication stream, the adoption union, `Berth_open/save` — instead of
   hardcoded per shelf. The declaration is a thin law-book of schema particles. The broader
    IOExpr level (the `%IO` composition language: what to fetch, how to shape) is the
     coming home for the mechanical half; until it lands, those lines ride as comments — 
      clues kept deliberately, because the thing can't be built usefully without saying
       concisely where the data is. Expect them to be a bit prototypey of that feature.

The table name rides in the key (`%AppdataSchema:account`), the way `%Invite:Music` names
 its Feature. Policy is a child particle: the merge discipline is its mainkey and the
  penholder role its value, so one particle says both. Each entry lists the schema row's own
   sc keys first, then its children.

```
%AppdataSchema:account       — the soul's own book (Tier A+B+C), private, outside berth
  replicates: body-to-body   —   syncs between your own devices (Captain ↔ Cave, both ways,
                                  whenever both are up — the ceremony §10 establishes it,
                                   the tandem §8 rides it); friends never receive it
  # io (future IOExpr sketch, not built): pipe %IO,account; rows gathered off the shelf
  #  by find {Identity:1, active:1} — "the particle that has Identity and has active"
  #   (1 = presence wildcard); doc shape = mirror of that query result (snapshot, no
  #    transform — doc-from-shelf shape; the cross-body merge rule is the policy child's job)
  # home: account:<prepub>/  — a top-level store, sibling of berth/ on disk;
  #        the daemon mirrors here (".jamsend/account/<prepub>/toc.snap")
  /SingleWriter:Captain      —   merge discipline (mainkey) + penholder role (value);
                                  Tier C rides inside — the role is the lock

%AppdataSchema:heists        — Tier B, what the soul decided to take
  replicates: body-to-body
  # io: pipe %IO,heists · find {Heist:1} · shape mirror
  # home: berth:<prepub>/Heists  — per-soul berth doc
  /Union                     —   any body may Heist (§9); union-merge keyed by id —
                                  same take twice = one row

%AppdataSchema:newlyadded    — per-collection, deliberately soul-blind
  replicates: no             —   it describes this box's collection; travel would lie
  # io: pipe %IO,newlyadded · find {Got:1} · shape mirror
  # home: berth:Newlyadded  — box-local berth doc (no prepub in the path)
  /Union

(no %AppdataSchema:pool — deliberate: replication ignores the pool; its bytes live in
 FSA|OPFS and move by app reality — press, pull, exchange, smuggle — under the
  pool-steward's decisions, §6. The pool ledger the smuggle backs up is likewise an app
   flow riding heist machinery, not a row in this book.)
```

`replicates:` has two honest values: `body-to-body` (the standing stream among one soul's
 bodies) and `no` (box-local). A possible sharpening, C-boolean style: drop `no` and let
  absence of the key say it, making replication opt-in — not ruled yet. `%SingleWriter` and
   `%Union` collide with no existing mainkey anywhere in the codebase (checked).

## 5. The replication foundation — Repli, and its edges

The account stream of §10 and the `replicates: body-to-body` promise of §4 both land on the
 machinery jamsend already has: `Ghost/N/Repli.g`, the paginated streaming C** replication
  protocol. It is real, battle-tested software — offer a particle's head as an enWaft-shaped
   line fragment, deal out the rest on demand, bytes pulled page by page, sha256-verified,
    wants that outrun the transcode frontier parking until the frontier passes. Its merge is
     find-or-create on the receiver: each line splits into a locate pattern (the `loc` keys)
      and merge props, then upsert. It is worth being precise about where it is solid and
       where it is naive, because "telling other nodes C**" is the foundation everything
        here stands on.

**The drama, chased down.** The pain remembered as "it was hard to put another mainkey into
 a replicated space" is real and has a specific shape: the wire identity of a particle — 
  which keys make it *that* particle — comes from `Repli_identity_keys`, a hand-maintained
   per-mainkey table inside the transport. A new mainkey crossing the wire without a row
    falls back to identity-by-all-keys, which splits instead of merging: every re-offer
     mints a fresh twin at the mirror. This happened live (`%Prehead`, the night the head
      serve went live), and its predecessor — a spelling heuristic — was hand-patched seven
       times and silently broke the friend's Jam ledger (every `%Spin` upserting onto the
        first). (The Jam ledger and `%Spin` were deleted entire 2026-09-04 — see
         `Radio_circuit_todo.md` — but the identity lesson below still stands.) The direction
          of failure is deliberate and correct — a too-wide loc splits
         visibly, a too-narrow one merges silently, so wide is the safe way to be wrong, and
          a console warn announces each unknown mainkey — but the baseline being paid is
           that the transport carries a model of the app vocabulary, and every new crossing
            shape must edit the transport file.

**The successor already exists, designed and prototyped.** `Mag_todo` §0.2e traced every
 mint site and found the table is a reconstruction of information the mints already state:
  find-pattern equals identity at every real mint, because `Repli_merge` is the same
   algorithm as `oai`. Two designs fell out. The first — stamp `oai_loc` at the mint funnel —
    was superseded the same day by the owner's better instinct: identity observed, not
     declared. That is `Repli_loc_shadow`, prototyped behind `opts.shadow_loc`: a
      per-particle shadow of the stringies last transmitted; an unchanged line patterns on
       all keys (a resend lands on its own last transmission); a changed line patterns on
        the keys that held still — identity is what doesn't change. No table, no stamps, no
         schema, and the unknown-mainkey warn loses its reason to exist. It is gated behind
          the RepliShadow Book and awaits the ruling (§0.2e question 0). Ruling it in is the
           single biggest step toward a robust foundation: new mainkeys would cross the wire
            correctly by default, with the table shrinking to a reload-bridging fallback.

**The three edges portability actually hits.** With the table question answered, what
 remains naive is specific:

1. *Repli is one-way and single-writer; body-to-body is neither.* The shadow design is
    sound exactly because "the sender is the sole writer, so the mirror's copy equals the
     shadow." That holds for `%AppdataSchema:account` (`/SingleWriter:Captain` — the
      discipline guarantees the assumption) and fails for `%Union` tables, where both
       bodies write and each is the other's mirror. Union tables need the merge discipline
        the law-book declares: union by the declared identity key, which is precisely what
         the schema particle knows and Repli deliberately doesn't. The clean composition:
          Repli stays vocabulary-ignorant and moves lines; the `%AppdataSchema` row tells
           the seam how to merge them. The law-book is not decoration — it is the missing
            half of the replication design.
2. *Absence is not deletion.* A key cleared at the source stays set on the mirror forever;
    `op:delete` removes whole particles, and nothing removes one key. The §0.2e audit found
     no current mutator un-sets a key over the wire — true today, but the account tables
      will break it (an `active:1` flag moving between Identities must un-set somewhere).
       Before the account stream carries Tier B/C, either the key-clear op gets designed
        (§0.2e question 4) or account mutations are shaped as whole-particle replaces.
3. *Reload amnesia.* The shadow lives in `.c`, which never persists: the first send after a
    reload patterns on all keys, and a particle that mutated across the reload splits into
     a visible twin. Fail-closed churn, never silent loss — and `%Record`, the shape it
      matters most for, already has a receiver-side census that locates by id regardless — 
       but a body-to-body stream that reconnects daily will see it, so the five mutating
        shapes keep a declared identity until the clear-op and persistence questions are
         settled.

Below Repli sits the transport floor: the relay authenticates a socket once at hello and
 never per-frame, and `Peeroleum`'s verify is still a mock. The signing-floor analysis
  (§12) says why this composes safely today — content lands only through vouch gates that
   fail closed — and what hardening remains.

## 6. The fidelity axis — Originals and the SoundPool

Two stations of being for one piece of music. The Original is the holding: `%Record` in a
 `%Library` on a real filesystem, the Cave's charge. A pool copy is a lofi pressing in some
  body's OPFS SoundPool, made for listening on a device that cannot and should not hold the
   library. The librarian's interest runs entirely to Originals; the pool is the people's
    music — portable, lossy, expendable.

**Identity across fidelities.** A pool row wears `%Record` on the pool's own shelf — the
 identity law is per-shelf, and a pool row genuinely holds its bytes. Its `id` is the hash
  of the lofi bytes themselves; `of:<original-id>` is the cross-fidelity join;
   `grade:'ogg128'` marks the pressing. Provenance rides scalars, which is how this codebase
    has always expressed it. The sharp line from the coupling trace, kept: the flaw is never
     that %Record means holding, but that forty-five seams each privately re-decide that it
      does — hence `Ra_holding_keys()`, the one place the question is answered.

**The pool is a mount.** A pool record's path is `pool/…`, resolved to the OPFS nav exactly
 as `music/…` resolves to the FSA nav — the nav contract (`read_file/write_file/dir`) is
  already the seam, and MountNav routes by prefix. Zero changes at the meander and serve
   seams; a received `path:"pool/…"` that doesn't resolve yet is a dead reference that
    starts resolving the day a pool mount stands, exactly as `music/…` behaves before a
     share opens.

**The pool is Mag-based, and both standing rules apply**: every collection holding lives in
 the shelf's paged Mag, whatever verb minted it — so pool tracks mint through the one owned
  door (`Ra_rec_home`) into a paged Mag, never a flat way-station; and a ledger is not a
   Mag — so the pool ledger (what was pooled, from what, when; the thing the smuggle backs
    up) stays a berth ledger beside the Mag.

**The OPFS reality.** OPFS works on phones and is invisible to the OS file manager, which
 is fine for a cache. It is evictable: storage pressure can clear it and "clear browsing
  data" kills it. Two consequences: the pool is designed expendable — a pool entry is
   re-pressable from its Original, and losing the pool loses convenience, never music,
    provided the smuggle has run so the ledger outlives the bytes; and the pool needs an
     economy — a size cap, an eviction order (least-recently-listened first), and honesty
      in the UI about what is pooled here versus held elsewhere.

**The pool-steward** (name to preen; "Quartermaster" fits the register — the officer who
 provisions the voyage). Replication ignores the pool, so something must decide what a good
  stash is, and it is scheduley, not reactive: once it has a good stash made, that's your
   mobile device set for a while. The shape:

- A goal-state, not a queue: the steward computes what the stash should be — cap-sized,
   policy-weighted (recently played, recently jammed, faves, a friend's fresh introductions
    from the exchange) — then diffs it against what is pooled. The diff is a want-list:
     press these, pull these, evict those.
- A scheduley cadence: it re-evaluates on real occasions — a session of plays ends, a jam
   happened, the Cave came reachable, idle-and-charging — and between occasions it rests. A
    good stash stays the stash. The daemon's digger (tour, rest, tour) is the precedent for
     the rhythm.
- It proposes; flows dispose: the steward never writes pool bytes — it mints wants, and the
   press, pull, and exchange machinery serve them under their own gates (grants,
    reachability, battery). Its whole surface is legible: a want-list the Door can show
     ("what your phone wants next and why"), and the stash-diff is Book-testable at the
      model layer without a byte moving.

**The press.** Hifi→lofi transcoding is Cave work and the machinery already runs — the
 daemon's native ffmpeg stocking and Radio's demand-driven transcode. The catalog landing
  for pool material is complete and correct (`Heist_catalog_land`'s pool branch minting
   through `Ra_rec_pool`) and currently inert: nothing lights its two triggers
    (`mardir='pool'` plus a pressed `lofi`/`body_hash`). The missing piece is the driver,
     `Ra_press(shelf, origId)`, which must reuse `Heist_catalog_land` rather than fork a
      parallel minter. It ships in two versions: v1 is a byte-for-byte copy of the Original
       into the pool nav — deterministic, so a normal byte-exact Book proves it, and already
        useful (portable at Original fidelity, expendable). v2 is the ogg128 transcode — 
         smaller, lossy, and not bit-reproducible, so its Book presses through a pinned stub
          and asserts shape, never bytes. A grade's bytes are local truth, never shared
           truth.

**The pool is a Heist destination, not only a press target.** The landing head
 parameterised over any nav lets a Captain heist straight into its own pool — no Cave in
  the loop — and lets the pool exchange be a heist whose destination is OPFS: one
   machinery, two destinations. What lands pool-side is pool-grade by posture (lofi,
    expendable, `of:`-joined); the Cave remains where Original-grade landing happens. The
     older "no heist setup on the phone" ruling scopes to the v1 UI while the machinery
      below it goes destination-agnostic.

## 7. The relay — how bodies coexist

The relay is a dumb address-routed forwarder; two verified facts govern the design.

Delivery fans out to a set, keyed by address: a `to:<addr>` frame reaches every station
 socket bound under that address. Two bodies under the same address is therefore
  duplication, not division — both receive everything, both answer, and a friend receives
   two interleaved streams one repli window can never reconcile. That is the observed
    two-daemon disease. And music routes to the asker's address while recognition rides the
     pub: a body receives what it asks for at whatever address it asked under, and proves
      itself by key, not by name.

So bodies coexist by holding distinct addresses. A Captain and its Cave can both be live,
 both talk to friends, both heist: each receives its own pages at its own door, both verify
  as the same soul, neither collides. `Swarm_next_suffix` computes the place,
   `Swarm_steal_back` concedes and jumps, `Swarm_reinstate` returns to the bare name with
    the disk-wins hold. The bare name goes to whoever claimed it first; no body has a
     birthright to it, and peers don't need it — a soul's bodies advertise their working
      address and SelfType in the hello, so a peer wanting music asks the body that
       advertised Cave duties, and a peer answering a QR gesture talks to the Captain in
        front of it. Peers address bodies, not souls; the soul is proven by pub either way.

Enforcement at the relay is deliberately thin. Honest bodies avoid collision by suffixing;
 the 👥 tripwire catches the case nobody chose. The security floor is not the relay — it is
  that peers sign with the key matching their prepub and receivers verify, which is
   enforced on every seal-minting path (§12 carries the residual). The relay does verify
    one thing: hello ed25519-binds a prepub to its socket at connect. It also already
     closes dead sockets (~30s heartbeat), so address squatting is bounded.

Two ruled tidyings: one websocket per body, binding several addresses over it (one socket,
 one liveness, one delivery door — shrinks the own-door dance to "deliver once per
  socket"); and the election half of address recovery — surviving bodies seeing a freed
   address and a new primary stepping up — is the cohort lock within a profile and the
    hello-v2 arbiter across machines.

## 8. The tandem — the four flows

The division of labour, stated once: the Captain holds the helm; the Cave keeps the hoard.
 The Captain is where the human is — it meets people, mints and redeems in person, listens.
  The Cave is where the disk is — it acquires, presses, keeps, and repairs, on standing
   orders.

**Flow 1 — the Heist.** The human marks something; the Cave carries it out with the gears
 that already exist, against the friend grants the soul already holds. The grant chain
  traces Captain-to-Captain — souls befriend souls, in person, by QR — while the bytes flow
   Cave-to-Cave, the bodies with the libraries and the uptime. Socially it is two people
    sharing music; mechanically it is their two stations doing the lifting overnight.

**Flow 2 — the pool press.** The Cave presses Originals to lofi and fills the Captain's
 SoundPool over the wire, so the phone actually listens. Contents are chosen by the human
  and by the steward's policy; the pool cap governs.

**Flow 3 — the pool exchange**, possibly the majority transport. Two phones in a room swap
 SoundPool material directly: live, phone-to-phone, lofi only, no Cave online. Mechanically
  it is a heist whose landing nav is OPFS. Each pooled track arrives as a record with its
   `of:` join intact, so it is simultaneously listenable now and an introduction — 
    something the receiving side's Cave can later fill out as an Original through Flow 1,
     under whatever grant the friendship carries. The exchange is the discovery surface;
      the Caves make it a collection.

**Flow 4 — the smuggle.** Two different rails under one word. The account rides the §10
 body-to-body replication stream; the SoundPool does not — the replication layer ignores
  it, and pool material crosses as an app flow, a heist-ride, steward-decided. Both reach
   the Cave for backup, not listening. The Cave regards every arriving pool copy as lofi
    that wants to be hifi-ified: each carries its `of:` join, so the Cave can fetch the
     Original whenever it becomes reachable. The backup is thereby also the upgrade queue,
      and the pool's expendability is underwritten — bytes may die with the browser; the
       ledger lives on the Cave's disk.

## 9. The ledger follows the helm

The Captain is the one invite processor, by definition of the helm — under cert-crew, simply
 the body whose `/Crew` row says `role:Captain` (Crew_todo §2: "Alone controls the crew
  ledger: minting a `Grant:Crew` takes the soul key"). A Cave reads everything, heists
   freely, and writes its own Tier-B replica — it is forbidden exactly one thing, writing the
    consumable ledger, and that is what makes it useful while safe. The crew ledger
     replicates to every mate continuously, soul-signed, last-writer-wins (Crew_todo §4: "any
      Crew online falls in line"), because a Cave must see ejections and revoked grants to
       refuse a cut-off peer at serve time. And standing down is a wire transition, not a
        permission bit: a body ceasing its duties must actually unbind its address — as long
         as it stays bound at a contested name it keeps receiving and answering the soul's
          fan-out, doubling streams regardless of what it may write.

## 10. Division — superseded by Crew (`Crew_todo.md` §3–§6)

**What this section proposed.** A device became a Cave by redeeming a role-Feature invite,
 `%Invite:MyCave` (you will be my Cave), on the same `%Idzeug` rails as a music invite.
  Redemption grafted the Captain's account Waft (`Identity,key` + `Peering`, issuer state
   read-only) onto the new device and wrote it into the Captain's `%Sibling` family register
    — the roster being how the 👥 theft-tripwire told family from a stranger. The serve
     layer's seven hardcoded `'Music'` `Swarm_pier_live` sites would need a Feature-generic
      retrofit to carry a role.

**Why it changed.** The design conflated becoming crew (which needs only a signed credential
 for a key the device already has) with the Captain's authority over that credential.
  `Crew_todo.md` (§1–§4a) separates them: a body mints its own key first
   (`Swarm_body_key_ensure`); the Captain signs it a `Grant:Crew` — "a credential I PRESENT,
    not an authority I confer on myself" (`Swarm.g`) — checked fresh at every door
     (`Swarm_voucher_ok`). No account Waft is grafted; no `%Sibling` roster is the membership
      record (the `%Body` roster that exists is a routing cache only). `%Invite:MyCave` as a
       standalone role-invite was never built past the audit below; LinkDevice now lands a
        `Grant:Crew` directly.

**What still holds, carried forward:**
- **The rails really were already Feature-generic** — the audit's finding is exactly why
   `Grant:Crew` could ride the same `mint_grant`/`verify_grant` primitive a friendship uses,
    with *no* serve-layer surgery, because crew membership never touches the music-serve
     sites at all — a different door (`Swarm_voucher_ok`) decides crew.
- **The ceremony mechanics are unchanged and now law** (Crew_todo §6: "the `?Iz` spine
   survives the model flip whole"): an invite whose redemption makes you, not befriends you
    — high-entropy, single-use, short-lived, never posted; both devices online so the
     exchange seals under a code-derived key (the secret rides the URL fragment, never the
      relay) with a matching-emoji confirm before anything moves; the carry is a QR beacon
       with a typed short-code fallback.
- **What the Cave concretely is** stands unchanged — a Chrome tab with FSA at first, the
   always-on daemon at its most cave-like. A body's Post says which duties it carries; what
    bestows it is now a `Grant:Crew` + the row's `role`, not an invite redemption event.
- **The `%Invite` particle** (a URL's token data autovivified into a lifecycle-bearing
   particle, arrived → redeeming → sealed|refused) is real and unaffected.

Distinct in kind from a music invite even now: that grants what I will serve you;
 `Grant:Crew` grants who you are to me — the most dangerous cert the system mints, handled
  accordingly (Crew_todo §12.3: "`Grant:Crew` is total impersonation").

## 11. The adoption handoff — superseded by Crew's "resume" (`Crew_todo.md` §4, §4a)

**What this section proposed.** The arc: the Captain runs with a laptop Cave for a while;
 later a daemon spins up to do everything, using the laptop's latest replica. The protocol
  scoped: the daemon boots still and adopts the freshest replica — a wholesale take of Tier A
   plus a union of Tier B; it announces and online bodies ack; the standing Cave stands down
    — stops fulfilment, unbinds its address; the daemon binds and takes up fulfilment.

**Why it changed.** There is no replica to adopt and no lease to hand over: every crewmate
 already carries the whole `/Crew` tree (Crew_todo §4). "Taking over" collapses to one signed
  act, `Swarm_crew_captain`: flip the `role` on two rows and gossip the ledger — "grant
   Captain" from a live Captain and "resume" from any surviving Cave are the same call
    (Crew_todo §4a). No key material moves; no account copy precedes it; the ledger itself is
     the mutex.

**What still holds, carried forward:** the operational caution underneath the old protocol is
 still real — two bodies briefly believing they hold the helm is the doubled-stream disease,
  so a deliberate flip-and-gossip beats a silent one, and `Swarm_reinstate`'s disk-wins hold
   still guards against a stale device clobbering a fresher ledger during the window. Live
    owed (Crew_todo §4): the station re-dial under a new Captain's name is not built, and the
     stash/account directory keyed by the old prepub is not migrated.

## 12. The trust floor, and what remains open on it

The signing floor, audited and then reframed by the deeper transport read: trust is
 enforced where it is minted and thinner where it is merely used. Every seal-minting path
  verifies — hello by presig regeneration and page binding, accept/confirm by grant
   signature, the reinvite chain end-to-end, live sealed piers by per-era voucher. Gossip
    frames and music-chunk sender identity are per-frame unsigned — a sealed friend can
     spoof another's prepub in advisory data — but the spoof cannot escalate: content lands
      only through `Heist_vouch_ok`/`Ra_verify`, which fail closed, and a live cast's
       `%Theirs` is structurally non-promotable to a holding (`Ra_holding_keys`
        exclusion). Universalising per-frame signing is hardening, not a ship-blocker; the
         one invariant worth a Book first is that `%Theirs` never promotes off-vouch.

Grant revocation holds: a signed `%NotGrant` atom, durable before return, consulted at
 every use, rehydrated on standup, resurrection-proof against stale snaps. `Grant:Crew` rides
  the same rails, so a defected Cave is cut off the way a defriended peer is. Two eyes-open
   caveats: revocation is lazy (the revoked party discovers it on next use) and, per
    `Crew_todo.md` §12.3, an ejection does not yet gossip to FRIENDS ("local only —
     revocation does not travel yet") — an offline friend keeps trusting a revoked Cave until
      it hears otherwise, owed. Also in-flight streams finish. For a revoked Cave this means:
       cutting it off stops its service, not its knowledge — what it already replicated, it
        keeps.

 **Fixed 2026-10-15, superseded premise:** this section used to say "only key rotation truly
  un-knows a body... rotation is undesigned, rare, accepted" as if that were universal. Under
   cert-crew (`Crew_todo.md` §12.2–§12.3) it is **case-split**: an ordinary Cave — own key
    plus a `Grant:Crew` cert, never the soul's secret — is NOT the soul, and the Captain
     ejects it cleanly with a soul-signed `%NotGrant:Crew`; no rotation needed. The blanket
      claim is still true only for a body additionally handed the soul's own secret via the
       ferry/resume path (§4's superseded note) — that device, stolen, is a "permanent full-
        soul compromise" (Crew_todo §12.2), because key rotation genuinely does not exist in
         the code today. Most Caves are now cheaply revocable; a body entrusted with resume
          capability is the remaining open risk, not a universal one.

At-rest encryption is ruled not-yet: any body can pop the admin console for its own
 cohort — that is democracy among your own bodies. A someday layer wraps the account under
  the vessel key at rest; today, bothering the user to unlock every session is the worse
   trade.

## 13. Open questions

- Multi-Cave is not guaranteed (one Cave, one Captain; more bodies at your own risk). The
   someday-sharpening: a booting body should tell within ~40s whether someone is already
    using an address, by reading marks on an agreed schematica — the account mirror's ~20s
     write cadence gives the signal; a tiny liveness beat is the honest-when-idle
      alternative. Both halves are small; design owed.
- Is a tab a whole identity, or an address plus a Post? The suffix machinery softens
   the old reason for per-tab identities; a tab could be a pointer to a part of the main
    identity's business. Undecided; the answer decides what `%Body` rows contain and what
     LinkDevice mints for a same-house second tab.
- The friend-side pier seam: ruled one %Pier per body; verify in code that repli window
   and era state key off the per-body row, and give a Pier its counterparty's Post.
- Body-key mortality: a re-linked device is a new body with a new key; the human may
   forget the old one. Remaining: the `%Body` cache's aging story for bodies that vanish
    without being forgotten — a ghost row should fade, not linger as a permanent 👥
     suspect.
- Instance memory: its exact home, what it holds beyond body-key + Post + souls-held,
   and how one-body-many-souls (a family's shared daemon) reads it. V1 stance: one soul
    per Cave.
- Pool quota numbers: a cap, an eviction order, the `navigator.storage.persist()` request.
   Small, but someone must own the numbers.
- The Repli rulings this doc leans on (§5): rule the shadow design in; rule the key-clear
   question; decide the %Union merge seam's reading of the law-book. All live in
    `Mag_todo` §0.2e's ruling list plus §4 here.
- A naming preen: `Swarm_steal_back` concedes the contested name and steps aside; the
   reclaim is `Swarm_reinstate`. The name reads backwards for what it does.
- The no-shared-anything bound: two bodies sharing neither filesystem nor relay have no
   common point to reconcile at. Either full sync or the house rule "one soul, one home at
    a time"; a newly-linked body born `role:Cave` keeps the default on the right side of
     this.

## 14. Primitive inventory (what the code already gives us)

Verified at the time of writing; re-check before relying. ⚠ `Swarm_sibling`/`Swarm_is_sibling`/
 `Swarm_note_theft`/`Swarm_stolen` below are the PRE-cert-crew layer — same-browser-profile
  cohort/theft detection, not account membership, which is now `Swarm_crew_grant` +
   `Swarm_voucher_ok` (`/Crew`, `Grant:Crew` — see `Crew_todo.md` §3–§5 and §2/§10 above).

- identity ≠ address — `Ghost/S/Swarm.g` places region: `Swarm_address`,
   `Swarm_next_suffix`, `Swarm_steal_back`, `Swarm_reinstate` (disk-wins hold),
    `Swarm_sibling`/`Swarm_is_sibling`, `Swarm_note_theft`/`Swarm_stolen`. Session-local,
     omitted from every export.
- the wire dial — `Ghost/N/Tribunal.g` `Socket_real`: `home()` reads
   `address ?? name` fresh per connect; `rehome()` re-dials; `Swarm_rehome(ident)` syncs
    the Peering and calls it on Steal Back / Reinstate.
- relay routing — `src/lib/server/relay.ts`: `locals` (addr → set), `deliverLocal`
   (fan-out), additive `bind`, hello's ed25519 socket binding, ~30s heartbeat sweep.
    The file carries a NUL byte — grep runs binary-silent; use the Read tool. Run
     `scripts/relay-test.ts` after touching it.
- replication — `Ghost/N/Repli.g` (§5): offer/want/park/serve, `Repli_merge`,
   `Repli_identity_keys` (the table), `Repli_loc_shadow` (the prototyped successor,
    behind `opts.shadow_loc`).
- Tier C — `Ghost/S/Swarm.g` iz region: `Swarm_iz_issuer`, `Swarm_claimed_has/add`,
   `Swarm_token`.
- the berth append-door — `Ghost/M/Heist.g`: `Berth_append`/`Berth_save` fold-supersede
   by key.
- OPFS nav — `src/lib/O/WormholeOpfs.svelte.ts`: `OpfsOverlayNav`, same
   read_file/write_file/dir contract as every nav.
- transcode — daemon-native ffmpeg stocking; `Ghost/M/Radio.g`
   `Ra_transcode_ensure|advance`. The pool press is the same gears, new destination.
- pool landing — `Heist_catalog_land`'s pool branch → `Ra_rec_pool`; inert until the
   press driver lights it (§6).
- revocation — `Swarm_revoke` → `mint_revoke` (signed `%NotGrant`), durable before
   return, checked by `Swarm_pier_live` at every use, rehydrated on standup,
    dedup-protected. Feature-generic throughout.
- the generic Feature flow — issuer/token/redeem/hello/accept never inspect the Feature;
   the serve layer's six `Swarm_pier_live(p,'Music')` sites are the only hardcoding.
- record path semantics — `Ra_record_from` (`sc.path` base-relative, `sc.id` sha256 of
   source bytes); `MountNav` routes per-method by mount prefix — the seam the pool mount
    rides.
- listening-only boot — `Housing.svelte.ts` boot_role branch (`H.c.listen_only`); not yet
   verified on a real phone.
- the disk write-lease — `Identity_persist` §7.4f; daemon and browser guards.
