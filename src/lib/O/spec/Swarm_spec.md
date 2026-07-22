# Swarm_spec — the p2p social side: identity, contacts, invites

The non-Radio, non-infra half of jamsend: the **people** and the fabric between them — who you are,
 who your friends are, and how two strangers become peers. Where `Radio_spec` is the *stream* and
  `Cluster_spec` is the *machine* (trust substrate, runner flock, relay), this is the *society*: a
   portable identity-particle, the contacts it accumulates, and an **Idzeug** invite that hands a
    friend the **%Grants** that open a Pier.

The triad: `Cluster_spec` is **how it runs**, `Radio_spec` is **what streams**, this is **who's on it**.
 And as a layer story (owner 2026-07-07): **Swarm is the first thing you'd show someone about the
  Pier**; Cluster is its **proto self** — an Identity that can use the relay without really being a
   Pier or anything about Radio; that intersects **Peeroleum**, which goes on to be the fullest
    networking gear underneath. Radio (`Radio_todo.md` — the main conceptual spring) is the
     experience the layers converge into.

> **Supersedes `Swarm_doc.md`** (the earlier starting doc, now deleted — its identity substrate is
>  folded in; the `Cluster_spec.md` / `Radio_spec.md` cross-refs point here).

Tags: **[now]** = current code, **[want]** = proposed here. Much of identity is a *want* today —
 it hides in a Dexie row and never touches disk. This doc is the design to make it robust and to
  reincarnate the old **Trusting / Idzeug** invite garden on the C-model — **without the Tyrant**
   (the third-party authority worked but ran ~90% red; each peer is now the authority for its own
    friendships).

---

## 1. The one idea

**A person is a portable identity-particle; the swarm is those identities finding each other, and a
 friendship is a pair of signed grants.** Every feature is a facet:

- an **identity** (`%Identity`) is a keypair you *own*, stored where you can back it up;
- a **page** (`%Peering`) is that identity's outward name — the pub it advertises to the world;
- a **contact** (`%Pier`) is a friend you've accepted — their cached page plus the **Music** grant that made them a Pier;
- an **invite** (`Idzeug`) is single-use proof your link reached them — both online, it seals a mutual **Music** grant;
- **presence / sharing** ride the same edges Radio uses (`Radio_spec §1`).

So "build the social side" is not N features; it is **identities + grants + snapped state**.

---

## 2. The particle model — `%Identity` / `%Peering` / `%Pier`

The shape the human named — self → outward name → friend, nested under one durable Waft:

```
Waft:Account                                    — the durable account (§4: Dexie ⇄ disk snap)
  %Identity,<tag>          .c.keys={pub,key}     — MyAccount: the secret keypair (.c, never encoded)
      sc.prepub  sc.friendly  sc.active          — 16-hex address · display name · the live one
    %Peering,name:<prepub>                       — MyPage: the pub this identity advertises
        sc.friendly  %cap,<ability> …            — outward name + declared capabilities (§7)
      %Pier,pub:<friend-prepub>                  — AFriend: one contact's DURABLE MEMORY
          sc.friendly  sc.at  sc.since           — their name (cached) · relay hint · when we met
          %Peering,name:<friend-prepub>          — their page, IMPORTED (the "stashed Peering", §6)
          %Grant,by:<friend>,for:<me>,time,sign  — the grant THEY gave me
            %Music,genre:Classical               —   FOR: the Music Feature, param-scoped (§6.1)
          %Grant,by:<me>,for:<friend>,…          — my copy of the grant I gave them
          %NotGrant,…                            — a revocation, kept HERE in the Pier's memory (§6.4)
```

**`%Identity`** owns the secret key on `.c.keys` (an object in `.sc` is a fatal encode, CLAUDE.md).
 `sc.prepub` (`prepubOf` = `pubHex.slice(0,16)`) is the routing address a `to:<pub>` envelope carries.
  One `%Identity` is `active:1` at a time (a boolean rides as `1`-or-absent). This is today's
   `Clustation_concrete` (`Auto.svelte`) — **[now]**. An `%Identity` is *general*: it is the identity
    for **any applet** we log into (editor, runner, listener); `?I=` switches which one is live (§5).

**`%Peering`** is MyPage — and it is **very nearly just the `%Identity` itself**: a page's whole job is
 to advertise its identity's pub (or another address) to the outside world. One identity *could* own
  **several** pub-prefixed Peerings — distinct outward names for distinct machinery (an editor face, a
   bot face) — but that is the address-hold mechanism (§3) again, and is **deferred**: **1:1 for now**,
    the 1:N door left open. A Peering's *own* fields (friendly, caps) are shareable; its `%Pier` children
     are **private** and pruned before sharing (§6.5).

**`%Pier`** is AFriend, and it lives at **two layers — keep them straight**:

- its **durable memory** — the particle above, stored under `%Identity` in the account tree (Dexie +
   disk, §4): who they are, their imported page, the grants both ways, any revocation. This survives
    offline, restart, device-move.
- its **living, breathing instance** — the live connection when the friend is online: the transport
   `Pier` (`%Pier,pub:…,req:handshake` in the networking spine), linked off `.c.live`, never snapped.

**The contact is the memory; the connection is the instance.** Don't conflate them — a friend you can't
 currently reach is still a friend.

---

## 3. Address & aliveness — who holds a Peering

A `to:<pub>` envelope resolves to whoever currently **holds** that Peering's address, and exactly one
 live place should. Local mutex, relay challenge, and the multi-place problem are **one mechanism** — a
  leased hold on a Peering address — not three:

- **local (one browser profile)** — a Peering can be open in several tabs. Dexie `liveQuery` is the
   local mutex: a tab can see a sibling already holds the address before it ever troubles the relay.
- **startup-fast alternative** — waiting on a possibly-sluggish sibling tab through `liveQuery` can
   stall boot, so a tab may instead just bind and let the **relay** answer "taken — jump to `${pub}_1`"
    (the next free suffix). *Leaning relay-suggested for boot speed; open.*
- **multi-place (deliberate, across tabs/devices)** — the same identity in N live places is **one key
   on N addresses**: `<prepub>`, `<prepub>_1`, `<prepub>_2` — and every place understands it is *the
    non-first them*. `to:<prepub>` (bare) is the primary; `to:<prepub>_1` a specific other place. This
     is the identity≠address split: one key, many session addresses.
- **relay keeps the bind honest** — a fast *are-you-alive* challenge to the holder; a holder too slow to
   answer **forfeits the name** and it can be rebound. `// <` surfacing that forfeit as an error the
    owner actually sees is unbuilt.

The relay-side authenticated bind of a signed `hello` → `prepubOf(pub)` → socket already exists
 (`Cluster_spec §3.2`, **[now]**). The **identity≠address split + the cooperative-vs-theft distinction +
  Steal Back** are now **[now]** at the MODEL layer — `Swarm.g`'s *places* region: `Swarm_address`
   (session address, defaults to the canonical `name`, becomes `<prepub>_N` after a steal-back),
    `Swarm_next_suffix` (relay's "taken — jump to the next free suffix" done locally), `Swarm_sibling`/
     `Swarm_is_sibling` (the Dexie-liveQuery "these are all our tabs" roster, modeled as `%Sibling`
      records), `Swarm_take_role` (the tabs split the work — one plays music, one encodes — so a 6-hour
       leak never takes it all down), `Swarm_note_theft` (a KNOWN sibling is cooperative co-presence, no
        alarm; anyone else raises `%Peering.sc.stolen` + a durable `%Stolen,by/at` husk the banner
         reads), `Swarm_stolen`, and `Swarm_steal_back`. Proved end to end by the **`SwarmSteal`** Book
          (§9). Session-local by construction: `stolen`/`address`/`role` and the `%Sibling`/`%Stolen`
           husks are omitted from every export (a backup is the canonical identity, never a moment's
            reachability). Still **[want]**: the actual browser wiring — Dexie `liveQuery` feeding the
             sibling roster, the relay's *are-you-alive* challenge and name-forfeit, and the relay
              surfacing a duplicate-`hello` collision (today the `to:<pub>` bind is silently additive —
               two sockets for one pub coexist; the `@channel` "taken" refusal is the template) — plus
                the `Identity Stolen` / `Steal Back` **UI** banner over these verbs.

---

## 4. Robust storage — Dexie **and** disk, plus export

The load-bearing requirement: **an identity and its friends are precious to their owner** — losing them
 is losing your account and your whole contact list. Three copies, each with a job:

1. **Dexie `identities` Thang** — the **working store**, always-available and pre-share; the identity
    exists here at first boot, *before any disk share is open*, dissolving the chicken-and-egg. **[now]**
     (`Thangs.svelte` `thang_add`/`thang_peek`).
2. **Disk account tree** — `<music-collection>/.jamsend/account/<prepub>/toc.snap`, a **snapped C-tree**
    via the Wormhole: durable, portable, inspectable, backup-able. The secret key sits in the user's own
     file on the user's own disk — the same trust posture as the FSA share they already opened. Fixed
      path, **no config**. **[want]**
3. **Export / import blob** — the account (or one contact) as an encodable snap you can copy in|out — the
    reincarnation of the old `thawEnteredStashed` "paste JSON to import a Peering stashed object", now
     over the C-snap. Surfaced in the 🪪 hatch (§10). **[now]** for the verbs — `Swarm_export` (a JSON
      envelope `{v, kind, snap, keys?}`; `keys` only on a deliberate secret export) / `Swarm_import` →
       `Swarm_graft` (identity-keyed find-or-merge, so a re-import never duplicates); export→import→
        re-export is byte-identical, gated by the Book (§9). The 🪪 surface is still owed.

**The stream rule** (owner, 2026-07-01): **Dexie AND disk — write-through Dexie→disk continuously;
 unless Dexie is empty, in which case seed Dexie from disk.**

- **Dexie → disk** — on any `Waft:Account` version bump, throttled, re-snap the account subtree and
   write its `toc.snap` (the old `save_stash` throttle is the precedent).
- **disk → Dexie** — on boot, if Dexie has no identity and a disk tree exists, decode and seed Dexie.
- **both empty** → Auto mints (§5).
- **divergence** (Dexie *and* disk both non-empty and disagree — two devices) → **last-write-wins** on
   `toc.snap`. Not a merge; keep it simple.

`Waft:Account` is an `%equip` Waft that snaps to its own `toc.snap` — exactly the **Keep** precedent
 (a Waft with per-Waft cursor-resume, `wormhole/Keep/toc.snap`) and `Waft:Cluster`'s pattern. Reuse
  that machinery; don't invent storage. Encodability is the axis that matters, not *where*: a snap is
   copyable to wire and disk and doubles as the shareable contact (§6.5), the backup, and the device-move;
    a raw Dexie blob dead-ends.

---

## 5. Auto — become who you are, mint one if there's none

`Auto.svelte`'s Clustation region is "becoming who it is." It stays, extended with the disk seed and the
 **auto-mint**. The boot ladder (`Clustation_ensure_identity`, extended):

```
1. ?I=<tag>          → resume that tag from Dexie   (?I=new mints, rewrites URL → ?I=<prepub>)   [now]
2. else Dexie        → an active %Identity present?  resume it                                    [now]
3. else disk share   → <music>/.jamsend/account/*/toc.snap present?  seed Dexie from it, resume   [want]
4. else MINT FRESH   → generateKeys → persist Dexie → (once a share opens) mirror to disk (§4)     [want]
   always: rewrite URL to ?I=<prepub> so a reload RESUMES, not re-mints (Cluster_spec §2.2a)
```

**Today** an absent `?I=` leaves the layer inert. **The change** is step 4 — *nothing anywhere ⇒
 automatically mint one*: a first-time visitor silently *becomes somebody*, durable the instant a share
  opens. `?I=` then switches between the identities on this machine — the editor's key, a runner's, a
   social account are all `%Identity`s, one live at a time.

---

## 6. The Idzeug invite + the `%Grant` scheme

Two people become peers by one signing an **Idzeug** (an invite offering the **Music** Feature) and the
 other redeeming it **while both are online**. Each peer is the authority for its own friendships —
  **no Tyrant, no cert**
  (`Cluster_spec §2.8`: certs were prototyped and removed; per-action grants belong as app-level
   particles — a Pier's grants are exactly that).

### 6.1 `%Grant` — the atom, always FOR a Feature

`Grant.ts` **[now]**: a self-contained signed capability — `by`, `for`, `time`, `sign` — ed25519 over
 sorted-key JSON, carrying its own grantor/grantee so it **verifies off any connection**. `mint_grant` /
  `verify_grant` (throws on forgery) / `grant_to_C` ⇄ `grant_of_C` / `mint_revoke`. **Kept as the shared
   atom** (Wormhole access rides it too, `Cluster_spec §3.8`).

A grant is always **FOR** a **Feature** — a mainkey with params, not a bare flag, so it can scope itself
 ("Classical only"). **`Music` is the Feature every Idzeug grants — receiving it *is* becoming a Pier.**
  In the C-form the Feature is a child particle:

```
%Grant,by,for,time,sign
  %Music,genre:Classical           — the Feature: mainkey `Music`, param `genre:Classical` (only my Classical)
```

The signed claim flattens it (Grant's `to:<mainkey>` + the param keys it already carries as `[k]:string`),
 so **no `Grant.ts` change** — just the convention that `to` names the Feature mainkey and its params ride
  alongside. Later Features are more `%Grant`s FOR other mainkeys (`follow`, `disk`, `compute`). **No
   `until`** — grants are infinite; unfriending is a `%NotGrant` (§6.4).

### 6.2 `Idzeug` — proof your link reached them  **[want]**

An **Idzeug** is a single-use, signed invite carrying the inviter's page, the **Music** grant it offers,
 and a nonce. Its job is narrow: **proof that your link reached the other Pier.** It is *not* an offline
  capability token — **both Piers must be online** to complete, and the live handshake (§6.3) turns the
   offer into mutual signed grants. Composed in `.g` from Grant atoms (§8) — no new `.ts`.

- **delivery** — a `?Iz=<base64>` **query param** (not a URL `#`-fragment; apps handling those links were
   stripping the fragment off). Copy-paste, a link, or a QR — all the same blob.
- **mode** — the invite carries a **policy**, chosen by the UI that mints it, and there are two:
   - the everyday **SHARE** QR popup mints a **re-assignable chain** (§6.3a): one evolving ticket
      tracked by its current holder, *no* serial — it is meant to propagate friendship along a social
       graph (A→B→C→D), so it re-assigns.
   - a **blotter sheet** mints a *batch* of **one-time serials**: each nonce is a numbered tab,
      **single-use**, and the maker **remembers the claimed serial** so a second claim of the same tab
       is refused (`spent` per serial — the old `taken_n`/`Upper_Number` ledger). A torn-off tab admits
        exactly one Pier and is done; it never re-assigns. The **legacy `######`** links are one-time
         serials too. **[built — Book: SwarmBlotter, green ×2]**: `Swarm_mint_blotter(w, ident, feature,
          count, tag)` (`Swarm.g #region blotter`) mints `count` plain serials `<tag>-1..<tag>-count`
           — each a normal `Swarm_mint_idzeug` (never `chain:1`), tagged `blotter:<tag>` and grouped
            under one `%Blotter,<tag>` record. Every serial spends through the *exact same* single-use
             door (`Swarm_hello` spends its nonce, `deny('spent')` refuses a replay), so the two invite
              kinds part at the mint, not in the door. The sheet holds only its **size** as durable data;
               the **claimed count is derived** — `Swarm_blotter_claimed` counts members whose own spend
                flag is set — never a snapped counter to drift (the ledger is each serial's own `spent`).
                 The Book proves: three serials under one blotter each admit a *different* claimant into
                  an independent friendship, a torn tab spends only itself (its siblings stay unclaimed),
                   a replay of a spent tab is refused with no friendship sealed, and the legacy `######`
                    link still parses at the door granting `ftp` not a Feature. Membership survives reload
                     (the iz-stash carries `blotter:<tag>`; the sheet re-derives its count from members).
- handling the **legacy** set of Idzeugs (the old garden's format) — **rung 1 BUILT 2026-07-07**.
   The concrete shape (surveyed 2026-07-07, `Tyranny.svelte` + `Trust.svelte.ts`): an old link is a
    URL **hash-fragment** `#<13-#-pad><prepub>-<advice>-<sign>` — prepub is the 16-hex address, advice
     a peel-encoded `{name, n}` (`.`-sep, `~`-hier, spaces as `+`), sign an ed25519 over the string
      (sometimes truncated to 16). Its spend ledger (`taken_n[]`, `nRepeating`, `Upper_Number`) and the
       identity KEY that signed it live in the old garden's **Dexie** (`Trusting.OurIdzeugs`,
        `OurPier.stashed`) — nothing on disk, nothing in particles. And an old claim granted the
         hardcoded `'ftp'` trust atom, NOT a Feature grant — do not transcode it as `Music`.
   So "support the old Idzeugs" = two rungs: (1) **dual-parse at the door [BUILT — Book SwarmPolicy]**:
    `Swarm_legacy_of_url` (`Swarm.g #region legacy`) reads the `#`-fragment shape pure — prepub|name|n
     lifted, `granted:'ftp'` surfaced so nobody transcodes it as Music, null (never a throw) on
      garbage and modern links. One deliberate mercy: the parser ADMITS `+` (the old ENCODER wrote
       spaces as `+` but its own matcher never accepted them — spaced names broke old links at their
        own door; we read what the encoder wrote). `InvitePanel` shows the honest relic face — names
         the inviter, says the key has not moved into this door yet, suggests a fresh QR. (2) a
     **one-time migrator** that lifts the old Dexie ledger + keys into `%Idzeug` records under the
      live `%Peering` — without which the door can only say `deny('unknown')`, honestly: the maker's
       ledger IS the validity (§10.1). Verification against the OLD signing key requires that key
        migrated too — an old link whose key never moved is dead, and should say so. `// <` rung 2 owed.

### 6.3 The handshake — live, both online

1. **Mint & share** — Alice (online) `mint_idzeug`s a one-shot invite offering `%Music` and shares the
    `?Iz=` link.
2. **Redeem live** (the old `Idzeugnation`) — Bob opens the link *while online*, verifies Alice's
    signature, and dials `to:alice.pub` with a **`pier_hello`** that echoes the Idzeug back as **proof he
     received the link** (+ his page).
3. **Seal** (the old `Idzeugnosis`, peer-as-own-authority) — Alice, seeing a valid Idzeug from a reachable
    Bob, mints the bound `%Grant,Music,for:bob` and returns it in **`pier_accept`**; Bob mints his
     reciprocal `%Music` for Alice. Both now hold a mutual `%Pier` with the other's signed Music grant —
      and, both being online, the living connection (§2) is up at once.

The nonce is spent; the Idzeug **proves receipt, it does not stand in for an absent party** — redeeming
 with the inviter offline simply fails. `pier_hello`/`pier_accept` are **additive Peeroleum frames** (no
  spine change) — the pattern the built Wormhole `wormhole_beg`→`grant_offer`→`wormhole_req`→
   `wormhole_reply` already uses. **[now]** — `Swarm_arm(w)` registers the three kinds on the spine's
    `w.c.on[type]` registry; `Swarm_deliver` routes transport-first when the sender holds a station
     (a `%Peering,name:<prepub>` flock), so the same verbs ride a real authenticated link (the pre-Ud
      gate) with ack/retransmit/dedup for free — gated by the **`SwarmWire`** Book (§9).

### 6.3a ReInvite — the re-assignable chain (Alice → Bob → Carol)  **[built — Book: SwarmChain, green ×2]**

> **As built (2026-07-22).** The mechanism below is live in `Ghost/S/Swarm.g` and proven end to end by
>  the `SwarmChain` Book (Dee→Eli→Fay→Gus, all four beats green on the live runner). One refinement from
>   the first sketch: there is **no separate `reinvite_ask`/`reinvite_bless` round-trip**. The tip's
>    consent *is* the act of honouring; Alice advances her tracker only on the tip's **signed**
>     `reinvite_ok` confirmation. And the "one bit still to shape" — what a future tip keeps to extend the
>      chain — is now a concrete **`%ChainRoot`** (a light lineage reference, not a friendship). Both are
>       folded into the sections below.

The base invite (§6.3) is single-use: the nonce spends on Bob's redeem and the Idzeug is done. A
 **ReInvite** turns that one nonce into a **movable admission ticket** that grows a **chain of
  friendships** — A—B, B—C, C—D — where each new member befriends *the one who brought them in*, not
   the original inviter. Alice stays the **authority and tracker-keeper** for the whole lineage — her
    `%Idzeug` record remembers *which Pier last claimed it* (the tip) — but past the first friendship
     she is only a **notary whose signature each newcomer verifies**, never a contact they keep. Crucially,
      it is the **tip who gives out the Grant**, not Alice: the ReInvite is an Alice-signed capability that
       *embeds the original Invite*, and the tip honours it peer-to-peer.

The move, concretely (Bob, the tip, bringing in Carol):

1. **Carol redeems; Alice issues a ReInvite.** Carol (holding Bob's link) redeems it while Alice is
    online. Alice's door sees a non-holder on a held chain link and signs a **ReInvite** that **embeds
     the original Invite** (so it carries the Grant/Feature Alice signed), names **Carol** the newcomer
      and **Bob** the current tip she joins at, and is timestamped. Alice signs it as she signed the
       Idzeug; she is the only authority the tracker answers to. (There is no separate "ask Bob first"
        leg — Bob's consent comes when he chooses to honour, step 3, and Alice only advances on his
         signed confirmation, step 5.)
2. **The ReInvite travels back to Carol, who carries it to Bob** — Bob her about-to-be contact.
3. **Bob honours it.** Bob verifies Alice's signature (he holds Alice's key — Alice is his *persistent*
    contact from A—B), checks it names him the tip, Carol the newcomer, and is recent, then **grants Carol
     the embedded Feature** — never more than Bob himself holds (no escalation). Carol reciprocates:
      **B—C is sealed** (`Swarm_seal` + the pier stash, §6.3).
4. **Carol validates too, then drops Alice.** Carol verifies the *same* Alice signature — she holds
    Alice's key only from the invite's embedded page ("the chain she joined with") — which is how she
     trusts Bob is a real member of the lineage, not an impostor. That Alice-reference is
      **non-persisted**: once the B—C Pier lands Carol drops it — no `%Grant` crosses A↔C, Carol never
       saves Alice as a contact.
5. **Alice advances the tip.** On Bob's confirmation that B—C sealed, Alice moves her tracker Bob →
    Carol — so the next ReInvite is *to Carol, for Dave*, and the chain grows C—D the same way.

Three properties fall out:

- **The chain is the graph.** A—B, B—C, C—D are the durable friendships; the touches A↔C, A↔D are
   transient notary meetings that leave no Grant and no saved contact. Alice seeds a lineage without
    collecting the whole chain as her own Piers.
- **No escalation.** The Feature is pinned by Alice's signed ReInvite and each ReInviter can only pass
   what they hold, so every Pier down the chain gets at most what Bob (the first claimer) got —
    *the first Invitor doesn't grant any more access than the first person who used it.*
- **The tracker is linear (the lineage never forks).** The tracker is one moving `holder` pointer at
   Alice, and it advances **at most once per tip**: once Bob's signed `reinvite_ok` moves it Bob → Carol,
    Bob is no longer the holder, so a *second* completed hop from Bob is refused at Alice
     (`frame.page.prepub !== record.sc.holder`). The *lineage* — who may be issued the next ReInvite —
      stays a single thread. (The friendship *graph* may still branch if a tip chooses to honour more than
       one newcomer before Alice advances: that is the tip spending its own link, each grant capped at the
        Feature and revocable — Bob's call, not an escalation. Only the one Alice's tracker lands on carries
         the lineage forward.) As built, the gate is the **tip's honour + the Feature cap + one advance per
          tip**, not a pre-registered `next`.

**The say/hear feedback (the prior art's shape).** Each leg is a say/hear pair, the way
 `pier_hello`/`pier_accept`/`pier_reject` already are: Carol *says* redeem (a `pier_hello` on the held
  chain link) → Alice *hears* a non-holder and *says* a signed ReInvite back → Carol *carries* it to
   Bob → Bob *hears*, validates Alice's signature, and — by choosing to **honour** — *says* the grant
    that seals B—C (his honouring **is** his consent, no separate "I believe" leg) → Carol *seals* and
     *says* her reciprocal → Bob *says* a signed `reinvite_ok` up to Alice → Alice *hears* and advances
      the tracker. A refusal at any leg answers back so the asker sees why (the `%rebuff` seam).

**The seams that make it airtight (open, resolved at build).**
- **Tip advance = confirmation, not issue.** Alice moves the tracker Bob → Carol only when Bob
   *confirms* B—C sealed (a small confirm frame she hears), so the tip always names a member actually
    in — a failed hop never strands the chain at a phantom Carol.
- **Each ReInvite spent once, bound to the live tip.** Bob honours a given ReInvite once, and Alice
   issues one only from her *current* tip — so a stale or replayed ReInvite (an old `Bob→Eve` that
    never completed) cannot re-fire, and the chain stays linear, no fork.
- **Carol drops Alice as a contact but keeps a light `%ChainRoot`.** The transient A↔C touch never
   becomes a friendship: no `%Pier`, no `%Grant`, nothing that puts Alice in Carol's contact book or dial
    pool. But Carol *does* keep one small thing — a **`%ChainRoot,pub:<Alice>`** referring particle
     (pub + prepub, no grant, never dialled), durable across reload via `Swarm_chainroot_stash`. It is the
      **lineage authority**, not a friendship: `Swarm_chain_root_ok` consults it (or a direct `%Pier`) to
       decide whether to honour a ReInvite — so when a *future* newcomer (Dave) arrives, Carol-the-tip can
        honour Alice's `Carol→Dave` ReInvite without ever having befriended Alice. This is the "one bit"
         the first sketch left open, now shaped: the chain outlives every A↔X touch except this feather.
- **`reinvite_ok` is signed by the tip, not trusted by its link.** Past the first hop the tip (Carol)
   is *not* a friend of the root (Alice), so the confirmation rides an untrusted channel. The tip signs
    `{nonce, rnonce, newcomer, pub}` with its identity key; Alice binds `prepubOf(pub)` to her *current*
     tracked holder and verifies the signature — so only the live tip can advance the tracker, and a wire
      observer who saw the ReInvite cannot forge the advance.

**The frames (choreography, as built).** Bob gives Carol his chain link out of band. Six frames grow
 the chain by one:
1. `pier_hello` **Carol → Alice** — Carol redeems the link; Alice's door (`Swarm_hello`) sees a *held*
    chain link claimed by a **non-holder** and, instead of `deny('held')`, opens the ReInvite flow
     (`Swarm_reinvite_begin`): mint a single-use ReInvite (tip = Bob, newcomer = Carol, fresh `rnonce`),
      remember it *pending*, hand it back.
2. `reinvite` **Alice → Carol** — the signed ReInvite (it embeds the original Invite). Carol is the
    newcomer it names, so `Swarm_reinvited` stashes it and forwards.
3. `reinvite` **Carol → Bob** — same frame kind, other role: Bob is the tip it names, so `Swarm_reinvited`
    routes to `Swarm_reinvite_honour`.
4. `reinvite_honour` **Bob → Carol** — Bob verified Alice's signature (via a direct `%Pier` **or** a
    `%ChainRoot`), granted Carol the embedded Feature (capped — no escalation), and sealed B—C his side.
5. `reinvite_seal` **Carol → Bob** — Carol verified Bob's grant traces to the named tip and Feature,
    reciprocated, sealed B—C her side, recorded her `%ChainRoot` to Alice, and dropped the transient.
6. `reinvite_ok` **Bob → Alice** — signed by Bob; only *now* does Alice advance her tracker Bob → Carol
    and spend the `rnonce`.

The pure sign/verify core is `Swarm_mint_reinvite` / `Swarm_verify_reinvite`; the wire verbs are
 `Swarm_reinvite_begin` / `Swarm_reinvited` / `Swarm_reinvite_honour` / `Swarm_reinvite_honoured` /
  `Swarm_reinvite_sealed` / `Swarm_reinvite_ok`, all registered additively on the Peeroleum on-registry.

**Which invites chain (non-breaking).** Only the everyday **SHARE** QR popup mints a chain; a **blotter
 sheet** and the **legacy `######`** links are *one-time serials* (§6.2) — each claimed once, its serial
  remembered, never re-assigning. The policy rides the `%Idzeug`: `chain:1` with a moving `holder`
   (the tip), versus a plain record that `spent`s on first claim. Existing single-use invites and their
    Books stay untouched (proven: `SwarmStaple` beat 6 still rejects the replayed spent nonce, green).
     The blotter *serial batch* is now **[built — Book: SwarmBlotter, green ×2]** (`Swarm_mint_blotter`
      + `%Blotter` + `Swarm_blotter_claimed`, §6.2): a sheet of plain serials, each single-use through
       the same door, the claimed count derived from members' spend flags. Only the rung-2 legacy
        **migrator** (lifting the old Dexie ledger + keys into `%Idzeug` records) remains `[want]`.

### 6.4 Revocation

Grants are infinite; **unfriending** is a signed `%NotGrant` (`mint_revoke`), kept **under the Pier it
 revokes** — in that Pier's durable memory (§2), never floating loose. A Pier is live iff a `befriend`
  grant stands and no matching `%NotGrant` overrides it, checked at *use*. `// <` the standing-revocation
   corpus is seed-only in `Grant.ts` today.

### 6.5 Privacy — what actually crosses

Sharing "my page" shares `%Peering`'s **own** face (friendly, caps) — **never its `%Pier` children**
 (your contact list is private). Prune with a `SWARM_PROTOCOL` `omit_sc`/skip-subtree over `%Pier`
  (the `enWaft` mechanism, `Text.svelte`). The Idzeug carries only that pruned page + the grants; the
   secret `.c.keys` never encodes at all. **[now]** — `Swarm_protocol(kind)`: session keys (`online`…)
    omitted, `mail`|`rebuff` husks skipped, and kind `page` additionally skips `%Pier` + `%Idzeug` +
     `%SocialGraph` (the spend ledger and the graph are as private as the contacts). NB skip rules
      match by `sc_has` presence, not `mk` — `lematch` reads an mk entry as match-all (footgun,
       noted in the `.g`).

### 6.6 Beyond the base handshake

- **Log the social graph** *(near-term, higher priority)* — every sealed friendship is an edge; each
   end's `%Pier` set is the local view, and the graph of who-befriended-whom is logged where the owner
    can watch it form (the old Tyranny logged `Idvoyage`s to `/log`; with no Tyrant the log lands
     owner-side | relay-side — open where, §12). It is the substrate for follows/feeds (§7).
- **Voice-call verification** *(eventually, lower priority)* — insist on a live voice call during the
   invite before sealing, so a human confirms a human. Deferred behind the graph log.
- **Transitive trust** — the old `Idvoyage` friend-of-friend admission, as grant chains; deferred, MVP is
   flat per-Pier grants.

---

## 7. Capability + presence — what an identity offers

An identity **offers** things (audio, disk, compute) — "who can do what, who's up now". **[now]** for
 the beacon plumbing, **[want]** for the `%cap` collapse:

- a **capability** is a `%cap,<ability>` child of `%Peering` — declared once, travels with the account.
   First cut: a flat `audio` facet beside `ready`/`book`/`engaged` on the beacon; the `caps` map is the
    collapse to make once the beacon's dige-sync lands (agreed with the Radio agent, 2026-07-01).
- it reaches the swarm on the **existing** beacon: `Lies_advertise` emits off the active identity,
   `Lies_advertise_recv` folds it into `%HostedIdentity` (durable directory) + `%Runner` (live presence)
    — `Cluster_spec §3`.
- **split declared from live** (the roster already does): `%HostedIdentity.caps` = *can* (durable) vs
   `%Runner` live state = *ready now* (ephemeral). Don't conflate "hasAudioContext".
- the **browser gesture** is a boundary artifact: a human tab satisfies it through normal use; a headless
   audio runner launches `--autoplay-policy=no-user-gesture-required`. Never an every-load tap.

---

## 8. Where it lives — the Swarm ghost family (`.g`)

**All the new code is `.g`, not scattered `.ts`** (the house doctrine: fold logic into the DSL — see
 `NOTATION.md`). There is a lot to it — the whole invite/accept UX flow *and* the crypto-using logic —
  so it earns its own family:

- a **Swarm ghost family** `Ghost/S/*.g` — the third beside networking (`Ghost/N/`) and music
   (`Ghost/M/`), surfaced as **`Waft:Ghost/Swarm/*`** beside `Waft:Ghost/Net/*` and `Waft:Ghost/Music/*`.
   **[now]** — `Ghost/S/Swarm.g`: keys / the account tree / the pruned page, the Idzeug (an unbound
    Grant + nonce), the wire seam (in-process today, Peeroleum-shaped), hello→accept→seal, `%NotGrant`.
- scenario verbs `Swarm_*`; the Story ghost `Ghost/Story/Swarmation.g` (mirroring `Peregrination.g` /
   `Musuation.g`); the Book `SwarmStaple` (§9). **[now]** — both built + enrolled in `CREDULER_GHOSTS`.
- **crypto reached via `IMPORT()`** — the `.g`→`.go` header pulls in `Grant.ts` / `Idento` / `cluster_trust`
   (a capability for real external deps, *not* an excuse to scatter logic — the invite/grant/UX logic
    itself stays in `.g`). The Idzeug is *composed* in `.g` from imported Grant atoms.
- **BOMB — registration order** (`NOTATION`/Radio_todo): a ghost is enrolled in `CREDULER_GHOSTS`
   (`LiesLies.svelte`), and **a gen `.go` that does not yet exist hangs the runner boot**. So enroll a
    Swarm `.g` only after it has been ghost-compiled; that one edit outside `Ghost/S/` is the deferred
     human touch.

---

## 9. The Book — prove it end to end

A Story, dispatched as usual: **`SwarmStaple`** (fixtures under `wormhole/Story/SwarmStaple/`), two
 sides up, driven per beat by an eternal `%req:wrangle` whose do_fn calls `SwarmStaple_drive` (the
  `PereStaple`/`MusuStaple` pattern; keep the world `w:SwarmStaple` or `do_fn_for` never runs it).
 **[now]** — built (beats 2–7, nine `%see` witnesses), headless-green and byte-deterministic (seeded
  keys + pinned `w.sc.now`, only the Story's own `round=` wobbles); the live-runner record is owed. Lay
   the tree with `$:` captures the way the human sketched it (capture an `oai` into a `let` — a bare `$:`
    binds create-legs only, per the g-capture rule):

```
Alice i Identity$:MyAccount / Peering$:MyPage        — side A (mint keys in the arm, not the peel)
Bob   i Identity / Peering                           — side B
# Alice (online) mints an Idzeug offering %Grant FOR %Music,genre:Classical → the ?Iz= link
# Bob (online) redeems → dials Alice, echoes the Idzeug back as proof → pier_hello
# Alice pier_accept → bound %Music grant → both hold a mutual %Pier$:AFriend, connection live
```

What it proves — each a differential witness with teeth (`%see:'sentence'` once-noticed claims,
 em-dashes not commas):

- **verify** — a tampered Idzeug fails `verify_idzeug` (flip a byte → rejected).
- **import** — after redeem Bob holds `%Pier,pub:alice / %Peering` with Alice's friendly — the
   "import a Peering stashed object" reborn (§6.3 / the `thawEnteredStashed` ancestor).
- **reciprocity** — both carry a `%Grant,Music` the *other* signed; a forged grant is rejected; it is FOR
   `%Music,genre:Classical` and nothing else.
- **both online** — redeeming with the inviter offline fails; the Idzeug is proof-of-receipt, not an
   offline token (§6.2).
- **graph logged** — the sealed friendship surfaces as an edge in the social-graph log (§6.6).
- **revocation** — a `%NotGrant` under the Pier retires it (§6.4).
- **persistence round-trip** — snap `Waft:Account` to disk, clear Dexie, re-seed from disk → identity +
   Piers survive byte-identical (§4). The whole *robustness* claim, gated.
- **auto-mint** — no `?I=`, empty Dexie, empty disk → an `%Identity,active:1` appears (§5).

Run on the **live `:9091` runner** (`runner_ask.mjs run SwarmStaple --watch` → `snap <n>` → accept),
 **never headless** (CLAUDE.md). SwarmStaple is **live-recorded green 8/8** (2026-07-04). A second Book,
  **`SwarmWire`** (beats 2–5), proves the SAME handshake as real Peeroleum frames — stations by prepub,
   authenticate-first, hello/accept/reject through the real outbox→inbox lifecycle — **live-recorded
    green 5/5** (2026-07-04; step 2 fuzz-tagged, its beat-2 handshake seed is mid-flight at the snap).
     A third Book, **`SwarmSteal`** (beats 2–6), proves the ADDRESS layer (§3): one key
     in many places — cooperative sibling tabs splitting roles music|encode, a foreign claimant raising
      *Identity Stolen*, and *Steal Back* re-presenting at `<prepub>_2` (past the thief and the siblings,
       same key). Each `%see` is a per-beat OBSERVATION gated to its step (`n === K`, live truth) so it
        appears once and DROPS as the story moves on — the drop is the signal (step 4's *stolen* gives
         way to step 5's cleared alarm); a persisting `%see` is the old `%witnessed` latch noise reborn.
          **live-recorded green 6/6** (2026-07-04, caveat:0).
          The two-real-browsers version is the distributed-Story upgrade `Cluster_spec §5`
           describes.

---

## 10. The coming UI — designed-for, not built-yet

A big new UI is coming — an account page, a friends list, an invite control, per-friend grant management.
 **This spec builds the model that UI needs; it does not build the UI**, and there is **no new toplevel
  page yet** (the human: "nah maybe not yet"). Surface through existing seams first:

- the **🪪 IdHatch** ("Cluster identity") grows to **list every `%Identity` on this machine** and
   **copy each one's snap in|out** for manual messing (the reborn `thawEnteredStashed` import/export,
    §4 pt 3) — plus the existing paste-adopt / set-up-trust / clear.
- `%Peering`/`%Pier` render through the existing Waft/GhostList/`MiniWaft`/Cyto machinery — the graph is
   literally the social graph; no bespoke widgets needed to see the model.
- the invite is just a `?Iz=` URL param the boot layer reads, like `?I=`/`?B=`/`?E=` — no page.

Keep the model clean — one snappable account Waft, one particle per contact with a pruned public face,
 one signed struct per invite, one atom per grant — and the toplevel page becomes a later, cheap view.

### 10.1 The Invite front door — building now (online-scan)  **[2026-07-07 decision]**

The owner wants the QR invite maker back ("monkey business vibe") as the front door to *get music
 onto a phone*: point a phone camera at an on-screen QR, and the phone gains a `%Pier` to pull from.
  Claim model = **online scan** (both present — the coffeeshop case), which is exactly what the
   built handshake already is (§6.3 both-online); no offline-bearer-token design (that needed the
    removed Tyrant).

**Naming.** User-facing this is an **Invite** (drop "Idzeug"). The signed crypto verbs stay
 `Swarm_*_idzeug` for now — renaming a green, signature-bearing handshake is a deliberate later pass,
  not a drive-by (the wire blob param stays `?Iz=`).

**The identity is already the right shape — no parallel self to mint.** Auto's `Clustation_concrete`
 stands up the active `%Identity` with `.c.keys` (ed25519 `{pub,key}`) *owning* a `%Peering` + a
  `prepub` — precisely what `Swarm_mint_idzeug(w, ident, …)` consumes (`ident.c.keys`,
   `Swarm_peering(ident)`, `Swarm_page(ident)`). Verified: `Lies_cluster_idento(w)` returns that same
    `{pub,key}` and *already* mints grants through the same `Grant.ts` `mint_grant` (`LiesFunk.svelte`
     ~:533). The "one signing key, one derived address" collapse (Cluster_spec §3.2a) means **the live
      cluster self IS the Swarm inviter** — the front door mints from `A:Clustation`'s active
       `%Identity`, it does not create a new one.

**Three pieces (the whole front door):**
1. **Mint from the live self** — resolve the active `%Identity` under `A:Clustation`, `Swarm_arm(w)`
    the cluster world once (register the swarm frame kinds on its Peeroleum on-registry), then
     `Swarm_mint_idzeug(w, self, {Music:1}, nonce)` → the `?Iz=` URL.
2. **Render the QR** — `src/lib/O/ui/micro/InviteQR.svelte`, mirroring the proven
    `p2p/ui/ShareButton.svelte` usage of `svelte-qrcode` (already a dependency). Self-contained:
     `value` = the `?Iz=` URL, shows the QR + the copyable link. Mounts through an existing seam (a
      Lens Panel or the 🪪 IdHatch), **no new toplevel page**.
3. **Redeem on open** — the boot layer reads `?Iz=<blob>` (beside `?I=`/`?B=`/`?E=`) and calls
    `Swarm_redeem(w, self, iz)` against the live self → `Swarm_seal` births the `%Pier`. Online-scan:
     the inviter is present, so the redeem's dial-home succeeds.

**Two invite kinds now** (both proven): a plain nonce spent at redeem, and — since 2026-07-22 — the
 **serial-numbered batch** (a blotter sheet, `Swarm_mint_blotter`, Book `SwarmBlotter` green ×2, §6.2),
  each serial single-use through the same door. The re-assignable **chain** is the third (§6.3a, Book
   `SwarmChain`). Still §6.2 **[want]**: *feature-selectable* invites, and the rung-2 legacy **migrator**
    (the old `nRepeating`/`Upper_Number` Dexie ledger + signing keys lifted into `%Idzeug` records).

**Proven.** Book `SwarmInvite` (Swarmation.g, green 2026-07-07): mints from Auto's real
 `Clustation_concrete` shape (active-of-two selection), URL round-trip + verify, scan→seal
  (cross-signed Music grants both Piers), photographed-QR-dead. The panel (`O/ui/InvitePanel.svelte`
   atop BigSoundland) is the live face over those verbs.

**The door asks the MAKER — validity lives with the inviter (owner 2026-07-07).** Structurally
 already true: a redeem DIALS HOME (`pier_hello`), and the inviter's own ledger answers — there is
  no offline oracle to fool. That makes invite POLICY a one-sided upgrade: the `%Idzeug` record
   under the inviter's `%Peering` grows policy fields the DOOR checks at hello-time, no wire or
    redeemer change at all —
 - `ttl:` — short-lived invites: `deny('expired')` when `now > time + ttl`. **[BUILT 2026-07-07,
    Book SwarmPolicy]** — ttl rides the mint's feature params onto the `%Idzeug` record (the maker's
     law), the CLAIM's signed `time` is the clock, and `Swarm_iz_params` STRIPS ttl before any grant
      mints (grants stay infinite — the expiry is invite policy, never grant policy). An expired
       redeem leaves the nonce UNSPENT (`%rebuff,hello_expired` maker-side, `rejected_expired`
        redeemer-side); inside the window the invite seals as ever.
 - `challenge: voice | name` — the door doesn't seal on the first hello; it answers with a
    challenge (a live voice call on the already-standing link, or "tell me your name and I check it
     against what I expect") and only `Swarm_seal`s on the prove. This is `Covenant_design.md`'s
      claim→challenge→prove→verdict ladder standing at the invite door — the design vocabulary
       exists; only the `%req:meet`-shaped door step is new.
 The single-use nonce stays the floor under all of it: policy can only make the door STRICTER.

**The frontier rung — the two BigSoundlands become for each other. [BUILT 2026-07-07]** The
 discovery that shaped it: a /BigSoundland tab never dialed the relay at ALL (`boot_qualand` sets
  `boot_role`, never `c.role`, so `Lies_channel_up` never fires) — and it must NOT dial as a role:
   a second `become runner` socket eats the fleet's role-addressed frames (the roles-divide wedge).
    So the station is role-LESS: `Swarm_station_up(w, ident)` (Swarm.g `#region station`) dials
     `?addr=<prepub>` (Socket_real reads the first Peering's name), sends NO `become`, and
      hello-binds the identity key on every (re)open — `to:<prepub>` then routes to the proven
       key-holder. The station lives on its own `w:Swarm` under `A:Clustation`
        (`Swarm_station_world`), clear of w:Lies's channel slots. Three companion moves:
 - **first-contact at the spine** — a `pier_hello` arrives BY DESIGN from a prepub with no `%Pier`
    yet, and `Peeroleum_deliver` dropped it at the no-pier gate. One additive branch (beside the
     `runner_ask` by-type precedent): no-pier + `pier_hello` + a registered handler ⇒ dispatch, then
      ack through the route the handler just promoted. Every other no-pier frame still drops.
 - **promotion at the door** — `Swarm_hello` now `Swarm_station_pier`s its caller (the
    `Lies_runner_pier` shape: oai-Pier + c.up + Ud) so the accept — and every deny's reject — has a
     route back. No-op in station-less worlds, so Book fixtures never see it.
 - **live readiness** — station piers never run the Book wire's per-Pier handshake (the Lies
    channel's v1 precedent), so `Swarm_deliver` counts a live carrier as ready when `station_up`;
     Books keep the strict `peer_ready` gate. The REAL per-Pier handshake at the door is the owed
      upgrade (first-contact for the spine's own `hello` would need the same no-pier thinking).
 The panel (`InvitePanel`) stands the station on page-presence (being on the page IS being at the
  door), and join = promote → wait-for-open → redeem → watch for the SEAL (the account `%Pier`),
   shown as a friends row on both faces (now with the ♪ IveGot chips + the reachable tally —
    Radio_todo §9.1c). **LIVE-PROVEN 2026-07-07**: two real BigSoundland tabs sealed over the relay
     (`✓ joined — <prepub> is a music Pier now`), and Book **SwarmDoor** gates the asymmetric
      first-contact seam (the no-pier branch, the door promotion, the station_up readiness — each
       one-line-revert red). Owed: the REAL per-Pier handshake at the door (above), and the phone
        scan (PWA/HTTPS origin — `PWA_install_handover`).

---

## 11. The lineage map — old garden → reborn

Concepts ported (not the pre-C-model `.svelte` code, and **not** the Tyrant, `Cluster_spec §1`):

| old (`Trust.svelte`, `Tyranny.svelte`, `Peerily`) | reborn here |
|---|---|
| `Trusting` / `MTrusting` — the feature + its onboarding UI | `Waft:Account` + Auto (§4/§5) + the 🪪 hatch (§10) |
| `OurPeerings` / `OurPiers` (Dexie Things) | `%Peering` / `%Pier` particles in `Waft:Account` (§2) |
| `thawEnteredStashed` — paste JSON to import a Peering | snap import/export of an account *or* a contact (§4/§6.3) |
| `Idzeug` / `Idzeugnate` — mint a signed invite | `mint_idzeug` → `?Iz=` link, composed in `.g` (§6.2) |
| `Idzeugnation` — the invitee redeems | Bob's redeem: verify → `%Pier` → `pier_hello` (§6.3) |
| `Idzeugnosis` — the authority verifies + grants | Alice's `pier_accept` — *peer is own authority, no tyrant* (§6.3) |
| `give_them_trust` — trust from checkboxes | the **`Music`** Feature grant — receiving it *is* becoming a Pier (§6.1) |
| `Idvoyage` / `log_Idvoyage` → `/log` | the **social-graph log** (near-term, §6.6); grant-chain transitive trust deferred |
| `OverPiering` / `%Hath` — the who-exists directory | `%HostedIdentity` roster over the relay bind table (§7) |

---

## 12. Open decisions

*Settled here* (folded into the body, no longer open): account path (fixed, no config — §4); Dexie↔disk
 divergence (last-write-wins — §4); Idzeug lifetime (single-use — §6.2); delivery (`?Iz=` query param —
  §6.2); Idzeug packaging (composed in `.g` from Grant atoms, `Grant.ts` kept — §6.2/§8); revocation home
   (under the Pier's durable memory — §6.4).

*Still open:*

- **Name-forfeit surfacing** (§3) — a Peering holder too slow on the relay's are-you-alive challenge
   loses the name; where does that error reach the owner? `// <` unbuilt.
- **Local mutex vs relay-suggested `${pub}_N`** (§3) — wait on Dexie `liveQuery` to know we're already
   online, or skip it for boot speed and take the relay's suffix suggestion? Leaning relay-suggested.
- **A second `%Peering` off one `%Identity`** (§2) — distinct outward names for distinct machinery; the
   same address-hold mechanism, deferred until a real need.
- **Multi-place session keys** (§3) — is `<prepub>_1` the same key on a suffixed address (simplest), or
   an ephemeral per-place key *vouched* by the identity? Sequence against `Cluster_spec §3`.
- **Grant ability schema** (§6.1) — is the ability mainkey drawn from a known set (`befriend`/`follow`/
   `play`/`disk`/`compute`) or fully open? Params too (`genre`, quality, quota)?
- **Legacy Idzeug handling** (§6.2) — ANSWERED 2026-07-07: decode it. Rung 1 (dual-parse +
   honest relic face) is built and Book-gated (SwarmPolicy); the rung-2 Dexie migrator is the
    remaining decision — without it every old link stays a named-but-dead relic.
- **Where the social-graph log lands** (§6.6) — owner-side (a local `%SocialGraph` record), relay-side
   (a central tally, the old `/log`), or both? Near-term, ahead of voice-verify.
- **Voice-call in the invite** (§6.6) — insist on a live call before sealing? Eventually, lower priority.
- **Capability verification** (§7) — is a declared cap advisory-until-proven, or grant-gated on consume?
   (Ties to `Cluster_spec §2.8`: membership *is* the permission.)
