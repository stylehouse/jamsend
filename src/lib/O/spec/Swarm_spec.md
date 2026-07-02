# Swarm_spec — the p2p social side: identity, contacts, invites

The non-Radio, non-infra half of jamsend: the **people** and the fabric between them — who you are,
 who your friends are, and how two strangers become peers. Where `Radio_spec` is the *stream* and
  `Cluster_spec` is the *machine* (trust substrate, runner flock, relay), this is the *society*: a
   portable identity-particle, the contacts it accumulates, and an **Idzeug** invite that hands a
    friend the **%Grants** that open a Pier.

The triad: `Cluster_spec` is **how it runs**, `Radio_spec` is **what streams**, this is **who's on it**.

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

All **[want]**. The relay-side authenticated bind of a signed `hello` → `prepubOf(pub)` → socket already
 exists (`Cluster_spec §3.2`, **[now]**); the suffixing, the challenge, and the local mutex are the new
  work.

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
     over the C-snap. Surfaced in the 🪪 hatch (§10). **[want]**

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
- **once** — single-use; the nonce is spent on the one live redeem.
- `// <` handling the **legacy** set of Idzeugs (the old garden's format) — owed, deferred.

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
   `wormhole_reply` already uses.

### 6.4 Revocation

Grants are infinite; **unfriending** is a signed `%NotGrant` (`mint_revoke`), kept **under the Pier it
 revokes** — in that Pier's durable memory (§2), never floating loose. A Pier is live iff a `befriend`
  grant stands and no matching `%NotGrant` overrides it, checked at *use*. `// <` the standing-revocation
   corpus is seed-only in `Grant.ts` today.

### 6.5 Privacy — what actually crosses

Sharing "my page" shares `%Peering`'s **own** face (friendly, caps) — **never its `%Pier` children**
 (your contact list is private). Prune with a `SWARM_PROTOCOL` `omit_sc`/skip-subtree over `%Pier`
  (the `enWaft` mechanism, `Text.svelte`). The Idzeug carries only that pruned page + the grants; the
   secret `.c.keys` never encodes at all.

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
- scenario verbs `Swarm_*`; the Story ghost `Ghost/Story/Swarmation.g` (mirroring `Peregrination.g` /
   `Musuation.g`); the Book `SwarmStaple` (§9).
- **crypto reached via `IMPORT()`** — the `.g`→`.go` header pulls in `Grant.ts` / `Idento` / `cluster_trust`
   (a capability for real external deps, *not* an excuse to scatter logic — the invite/grant/UX logic
    itself stays in `.g`). The Idzeug is *composed* in `.g` from imported Grant atoms.
- **BOMB — registration order** (`NOTATION`/Music_todo): a ghost is enrolled in `CREDULER_GHOSTS`
   (`LiesLies.svelte`), and **a gen `.go` that does not yet exist hangs the runner boot**. So enroll a
    Swarm `.g` only after it has been ghost-compiled; that one edit outside `Ghost/S/` is the deferred
     human touch.

---

## 9. The Book — prove it end to end

A Story, dispatched as usual: **`SwarmStaple`** (fixtures under `wormhole/Story/SwarmStaple/`), two
 sides up, driven per beat by an eternal `%req:wrangle` whose do_fn calls `Swarm_drive` (the
  `PereStaple`/`MusuStaple` pattern; keep the world `w:SwarmStaple` or `do_fn_for` never runs it). Lay
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
 **never headless** (CLAUDE.md). The handshake is in-process/deterministic for now; the two-real-browsers
  version is the distributed-Story upgrade `Cluster_spec §5` describes.

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
- **Legacy Idzeug handling** (§6.2) — decode the old garden's invite format, or drop it? Deferred.
- **Where the social-graph log lands** (§6.6) — owner-side (a local `%SocialGraph` record), relay-side
   (a central tally, the old `/log`), or both? Near-term, ahead of voice-verify.
- **Voice-call in the invite** (§6.6) — insist on a live call before sealing? Eventually, lower priority.
- **Capability verification** (§7) — is a declared cap advisory-until-proven, or grant-gated on consume?
   (Ties to `Cluster_spec §2.8`: membership *is* the permission.)
