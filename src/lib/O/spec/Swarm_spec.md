# Swarm_spec — the p2p social side: identity, contacts, invites

The non-Radio, non-infra half of jamsend: the **people** and the fabric between them — who you are,
 who your friends are, and how two strangers become peers. Where `Radio_spec` is the *stream* and
  `Cluster_spec` is the *machine* (trust substrate, runner flock, relay), this is the *society*: a
   portable identity-particle, the contacts it accumulates, and an **Idzeug** invite that hands a
    friend the **%Grants** that open a Pier.

The triad: `Cluster_spec` is **how it runs**, `Radio_spec` is **what streams**, this is **who's on it**.
 Identity begins as the trust substrate in `Cluster_spec §2` (the cluster signing keys — the *code-push*
  flock) and becomes **portable + social** here (the end-user's own account — the *people* flock). Two
   uses of one crypto primitive; keep them distinct (§2 note).

> **Supersedes `Swarm_doc.md`** (the earlier starting doc — its §2–§4 substrate is folded in below).
>  Retire that file; repoint the `Swarm_doc.md` cross-refs in `Cluster_spec.md` and `Radio_spec.md`.

Tags: **[now]** = current code; **[want]** = proposed here. Much of identity is a *want* today —
 identity currently hides in a Dexie row and never touches disk. This doc is the design to fix that and
  to reincarnate the old **Trusting / Tyranny / Idzeug** invite garden on the C-model.

---

## 1. The one idea

**A person is a portable identity-particle; the swarm is those identities finding each other, and a
 friendship is a pair of signed grants.** Every feature is a facet:

- an **identity** (`%Identity`) is a particle you *own* — your keypair, your name, stored where you can
   back it up, not trapped in a browser;
- a **page** (`%Peering`) is your public face — the shareable subtree others hold as their copy of you;
- a **contact** (`%Pier`) is a friend you've accepted — their cached page plus the **grants** you and
   they exchanged;
- an **invite** (`Idzeug`) is a signed link that *embodies grants* — redeeming it opens the Pier;
- **presence / capability / sharing** ride the same edges Radio uses (`Radio_spec §1`).

So "build the social side" is not N features; it is **identities + grants + snapped state**, and each
 section is a lens on it — the move `Radio_spec` makes for audio and `Cluster_spec` for the flock.

---

## 2. The particle model — `%Identity` / `%Peering` / `%Pier`

The shape the human named: `%Identity$:MyAccount / %Peering$:MyPage / %Pier$:AFriend`. Self → public
 face → friend, nested, all under one durable Waft:

```
Waft:Account                                   — the durable account (§3: Dexie ⇄ disk snap)
  %Identity,<tag>          .c.keys={pub,key}    — MyAccount: the secret keypair (.c, never encoded)
      sc.prepub  sc.friendly  sc.active         — 16-hex address · display name · the live one
    %Peering,name:<prepub>                      — MyPage: my public, shareable face
        sc.friendly  %cap,<ability> …           — name + declared capabilities (§6)
      %Pier,pub:<friend-prepub>                 — AFriend: one durable contact
          sc.friendly  sc.at  sc.since          — their name (cached) · relay hint · when we met
          %Peering,name:<friend-prepub>         — their page, IMPORTED (the "stashed Peering", §5)
          %Grant,befriend,by:<friend>,for:<me>  — the grant THEY gave me (their signature)
          %Grant,befriend,by:<me>,for:<friend>  — my copy of the grant I gave them
          %NotGrant,…                           — a revocation, if any (§5.4)
```

**`%Identity`** owns the secret key on `.c.keys` (never `.sc` — an object in `.sc` is a fatal encode,
 CLAUDE.md). One `%Identity` is `active:1` at a time (a boolean rides as `1`-or-absent). `sc.prepub`
  (`pubHex.slice(0,16)`, `prepubOf`) is the routing address — the `to:<pub>` a frame carries. This is
   exactly today's `Clustation_concrete` (`Auto.svelte`) — **[now]**.

**`%Peering`** is MyPage — the public face I hand out. Its **own** scalar fields (friendly, caps) are
 shareable; its `%Pier` children are **private** and pruned before sharing (§5.5). Two altitudes of
  "Peering" exist and must not be conflated: this **social `%Peering` particle** (durable, on disk) vs
   the **transport `Peering`** runtime object (`Peerily.svelte.ts` / `MachPeerily`) that *listens* on
    the prepub and sprouts live connections. The particle is who-you-are; the transport is a live wire
     it lights up. Link them on `.c` when connected, never in the snap.

**`%Pier`** is AFriend — a **durable contact record**, not a live socket. It caches the friend's page
 (their imported `%Peering`) and holds the grants both directions. When the friend is online, its live
  connection is the transport Pier (`%Pier,pub:… ,req:handshake` in `Peeroleum.g`), linked via `.c.inst`
   / `.c.live`; when offline, the contact still stands. **The contact is the snap; the connection is
    ephemeral.** (This is the `%HostedIdentity` durable-directory vs `%Runner` live-presence split from
     `Cluster_spec §3`, one altitude down into the personal account.)

---

## 3. Robust storage — Dexie **and** disk, plus export

This is the load-bearing requirement: **an identity and its friends are precious to the person who owns
 them** — losing them is losing your account and your whole contact list. So three copies, each with a
  job:

1. **Dexie `identities` Thang** — the **working store**, always-available and pre-share. The identity
    exists here at *first boot, before any disk share is open*, dissolving the chicken-and-egg. **[now]**
     (`Thangs.svelte` `thang_add`/`thang_peek`, Dexie db `thangs`).
2. **Disk account tree** — `<music-collection>/.jamsend/account/<prepub>/toc.snap`, a **snapped C-tree**
    via the Wormhole: the durable, portable, inspectable, backup-able copy. The secret key sits in the
     user's own file on the user's own disk — the same trust posture as the FSA share they already
      opened (`Cluster_spec §2.4`: a browser may hold a key on a trusted origin). **[want]**
3. **Export / import blob** — the account (or one contact) as an encodable snap you can copy to the
    clipboard, paste into another browser, or mail to yourself. The reincarnation of the old
     `thawEnteredStashed` "paste JSON to import a Peering stashed object" (`Trust.svelte.ts`), now over
      the C-snap format. **[want]**

**The stream rule** (owner, 2026-07-01): **Dexie AND disk — write-through Dexie→disk continuously;
 unless Dexie is empty, in which case seed Dexie from disk.** Concretely:

- **Dexie → disk** — on any `Waft:Account` version bump, throttled, re-snap the account subtree and
   write its `toc.snap` (reuse the Wormhole write path; the old `save_stash` `throttle(…, 200)` is the
    precedent). Encodability is the axis that matters, not *where*: a snap is enLine-able, copyable to
     wire and disk; a raw Dexie blob dead-ends.
- **disk → Dexie** — on boot, if Dexie has no identity and a disk account tree exists, decode its
   `toc.snap` and seed Dexie. The disk copy is the seed a *fresh browser* imports.
- this mirrors the Wormhole's own **seed/scratch** split (`WormholeOpfs`) and the **Keep** precedent
   (a Waft that snaps to its own `wormhole/Keep/toc.snap` with per-Waft cursor-resume). `Waft:Account`
    is an `%equip` Waft exactly like `Waft:Cluster` (which already holds `%HostedIdentity` entries) —
     reuse that machinery, don't invent storage.

> The disk copy is a **snap**, not a Dexie export — that is what lets the *same* representation double
>  as a shareable contact (its public `%Peering` subtree over the relay), a backup, and a move to
>   another device. Dexie is the fast local copy that streams into it, not a parallel format.

Then an identity is **portable** (copy the tree → it moves), **inspectable**, **backed up** — and no
 longer a Dexie-only anomaly — while keeping Dexie's pre-share availability.

---

## 4. Auto — become who you are, mint one if there's none

`Auto.svelte`'s Clustation region is "becoming who it is." It stays, extended with the disk seed and
 the **auto-mint**. The resolution ladder on boot (`Clustation_ensure_identity`, extended):

```
1. ?I=<tag>          → resume that tag from Dexie   (?I=new mints, rewrites URL → ?I=<prepub>)   [now]
2. else Dexie        → an active %Identity present?  resume it                                    [now]
3. else disk share   → <music>/.jamsend/account/*/toc.snap present?  seed Dexie from it, resume   [want]
4. else MINT FRESH   → generateKeys → persist Dexie → (once a share opens) mirror to disk (§3)     [want]
   always: rewrite URL to ?I=<prepub> so a reload RESUMES, not re-mints (Cluster_spec §2.2a)
```

**Today** an absent `?I=` leaves the layer inert (the legacy path). **The change** is step 4: *no
 identity anywhere ⇒ automatically mint one* — the human's "Auto will automatically generate an Id if
  there's none in Dexie or their share." No ceremony, no paste for the common case: a first-time visitor
   silently *becomes somebody*, and that somebody is durable the instant a share opens (§3).

`IdHatch.svelte` (the 🪪 hatch) stays for the **advanced** paths — paste-adopt an external
 `.env.cluster-<role>` key (`Clustation_adopt`), "Set up cluster trust" (`Lies_cluster_setup`), copy
  my public id, clear/switch identity. The auto-mint is the *default*; the hatch is the *override* and
   the account face the coming UI grows from (§8).

Keep the two identity uses separate (`Cluster_spec §2` note): a **cluster** signing key (code-push
 flock, `CLUSTER_TRUSTED_PUBS`) is minted by the editor's setup and is a handful of keys the human
  controls; a **swarm** `%Identity` (an end-user account) is auto-minted per person and multiplies
   freely. Same `Idento`/ed25519 primitive, different populations and different authorization (flock
    membership = code-push; per-Pier grants = friendship, §5).

---

## 5. The Idzeug invite + the `%Grant` scheme

The reborn heart of the old **Tyranny** garden: two people become peers by one signing an **Idzeug**
 (an invite that *embodies grants*) and the other redeeming it. **No tyrant, no cert, no central
  authority** — each person is the authority for their *own* friendships (`Cluster_spec §2.8`: certs
   were prototyped and removed; finer per-action grants belong as app-level particles — a Pier's grants
    are exactly that).

### 5.1 `%Grant` — the atom (already built)

`Grant.ts` **[now]**: a self-contained, signed capability — `%Grant,<ability>,by,for,time,sign`, ed25519
 over sorted-key JSON (`claim_json`, mirroring `canonicalHeader`). It carries its own grantor (`by`) and
  grantee (`for`), so it **verifies off any connection**, not just the socket it arrived on. `mint_grant`
   / `verify_grant` (throws on forgery) / `grant_to_C` ⇄ `grant_of_C` (atom ⇄ a `%Grant` particle you
    leave in a Waft). **No `until`** — grants are infinite by design (click-to-renew trains rubber-
     stamping); revocation is a separate signed `%NotGrant` (§5.4). Today it gates Wormhole access
      (`Cluster_spec §3.8`); here it becomes the **currency of friendship**.

Abilities a social Pier trades: `befriend` (the base — "you're my contact"), `follow` (subscribe to my
 feed, `Swarm §6`), `audio`/`disk`/`compute` (consume a declared capability, §6). Each is one signed
  `%Grant`; a Pier accumulates a small set.

### 5.2 `Idzeug` — the invite that embodies grants  **[want]**

An **Idzeug** is a shareable invite artifact — the old signed URL-hash token, reborn. Propose an
 `Idzeug.ts` beside `Grant.ts`, same shape (a signed struct, ed25519 via `Idento`):

```
Idzeug = {
  v: 1,
  from:   { prepub, friendly, at },        — the inviter's public page + a relay hint (§5.5)
  grants: [ %Grant atom, … ],              — the EMBODIED grants, each signed by `from` (bearer, §5.3)
  nonce, [exp],                            — single-use marker / optional soft expiry
  sign                                     — `from` signs the whole invite (page + grants tamper-evident)
}
```

`mint_idzeug(myIdentity, abilities, opt)` → the struct; `idzeug_to_link` → `?idz=<base64>` (or a
 copy-paste string, or a QR). `verify_idzeug` rebuilds and checks `from`'s signature. **"Idzeug embodies
  %Grants"** = `grants[]` are real `Grant.ts` atoms — redeeming *installs* them.

### 5.3 The handshake — mint → share → redeem → reciprocate

Bearer invite, sealed by reciprocation (you don't know the redeemer's prepub when you make a link):

1. **Mint** — Alice `mint_idzeug`s a **bearer** invite (`grants[].for` empty — `Grant.ts` already
    handles the no-grantee degenerate case). She shares the `?idz=` link out-of-band.
2. **Redeem** — Bob opens it, `verify_idzeug`s Alice's signature, and creates `%Pier,pub:alice` under
    his Peering: caches Alice's page as the imported `%Peering` (§2), installs her bearer grants, then
     dials her `to:alice.pub` with a **`pier_hello`** carrying *his* page + *his* reciprocal grant(s).
      This is the old **`Idzeugnation`** (the invitee's redeem side), reborn.
3. **Reciprocate** — Alice receives `pier_hello`, verifies Bob's grant, creates `%Pier,pub:bob`, and —
    now that she knows Bob's prepub — mints a **bound** `%Grant,befriend,for:bob` (upgrading from
     bearer) and returns it in **`pier_accept`**. This is the old **`Idzeugnosis`** (the authority's
      verify-and-grant side) — except *Alice is her own authority*, no tyrant on the graph.
4. **Sealed** — both hold a mutual `%Pier` with the other's grant. The bearer Idzeug can be
    single-use (invalidated by its `nonce`) or left open as a standing invite link.

`pier_hello`/`pier_accept` are **additive Peeroleum frames** (no `.g` spine change) — the exact pattern
 the built Wormhole `wormhole_beg`→`grant_offer`→`wormhole_req`→`wormhole_reply` used (`LiesFunk`).
  Point-to-point rides `to:<pub>` (`Cluster_spec §3.2`, relay-side bind **[now]**).

### 5.4 Revocation & expiry

Grants are infinite; **unfriending** is a signed `%NotGrant` (`mint_revoke`/`verify_revoke`, seed-only
 today — the standing revocation corpus is the owed piece). A Pier is live iff a `befriend` grant stands
  and no matching `%NotGrant` overrides it. Check the corpus at *use*, not at mint. **[now-atom /
   want-corpus]**

### 5.5 Privacy — what actually crosses

Sharing "my page" shares **`%Peering`'s own face** (friendly, caps, relay hint) — **never its `%Pier`
 children** (your contact list is private). Prune with the encode protocol: a `SWARM_PROTOCOL` that sets
  `omit_sc`/skip-subtree for `%Pier` under a shared `%Peering` (the `WAFT_PROTOCOL`/`enWaft` mechanism
   in `Text.svelte`, `omit_sc` per mainkey). A contact you hand someone is a *pruned* page; the Idzeug
    carries only that pruned page plus the grants. The secret `.c.keys` never encodes at all (it's
     `.c`, off the snap by construction).

### 5.6 Later — transitive trust

The old garden had `Idvoyage` (a signed induction cert: "this peer is on the social graph") and
 friend-of-friend admission. Reachable here as **grant chains** (a `%Grant` whose `by` is itself
  grant-attested by someone you trust), but **defer** — the flat per-Pier grant is the MVP. `[want,
   later]`

---

## 6. Capability + presence — what an identity offers

An identity **offers** things (audio playback, disk to proxy, compute to run a Book) — the social
 currency of "who can do what, who's up now." **[now]** for the beacon plumbing, **[want]** for the
  `%cap` collapse:

- a **capability** is a `%cap,<ability>` child of `%Peering` (declared once, travels with the account,
   §3) — first cut, a flat `audio` facet beside `ready`/`book`/`engaged` on the existing beacon; the
    `caps` map is the collapse to make once the beacon's dige-sync lands (agreed with the Radio agent,
     2026-07-01).
- it reaches the swarm on the **existing** presence beacon: `Lies_advertise` emits off the active
   identity, `Lies_advertise_recv` folds it into `%HostedIdentity` (durable directory) + `%Runner` (live
    presence) — `Cluster_spec §3`.
- **split durable capability from live fact**: `%HostedIdentity.caps` = *can* (declared, part of the
   account) vs `%Runner` live state = *ready right now* (ephemeral, from the runtime AudioContext gate).
    Don't conflate "hasAudioContext" — each slots into an existing shelf.
- **the browser gesture is a boundary artifact, not part of the model**: a human tab satisfies the
   `AudioContext` gesture through normal use; a headless audio runner launches with
    `--autoplay-policy=no-user-gesture-required`. Never an every-load tap.

Whether a declared cap is *verified* or advisory-until-a-run-proves-it ties to `Cluster_spec §2.8`
 (membership *is* the permission) — for social caps, leaning advisory + grant-gated consume (§5).

---

## 7. The Book — prove it end to end

A Story, dispatched as usual. Name it **`SwarmStaple`** (liveness of the invite handshake) with a
 sibling **`SwarmProof`** if it grows (the PereStaple/PereProof split precedent). Fixtures under
  `wormhole/Story/SwarmStaple/`. The old test lineage name `Idzeuzia` (`Ghost/test/Story/Lake/Idzeuzia.g`,
   which still fingers `eer.stashed.Idvoyage`/`Idzeug`) is the ancestor to honour.

**Two sides up** (`Tyrant.g`'s `Tyrant_sides_up` is the pattern — lay each side's `%Identity`/`%Peering`
 and drive the handshake). The `.g` lays the tree with `$:` captures the way the human sketched it
  (capture an `oai` result into a `let`, per the g-capture rule — a bare `$:` binds create-legs only):

```
Alice i Identity$:MyAccount / Peering$:MyPage           — side A (mint keys in the arm, not the peel)
Bob   i Identity / Peering                              — side B
# step: Alice mints an Idzeug embodying a befriend %Grant, hands the link to Bob
# step: Bob redeems → %Pier,pub:alice under Bob/Peering (+ Alice's page imported, + her grant)
# step: Bob pier_hello → Alice; Alice pier_accept → Bob (bound grant back)
# witness: both sides hold a mutual %Pier$:AFriend with a verified %Grant each way
```

What it proves, step by step (each a differential witness with teeth, `Radio_spec §6` discipline —
 `%see:'sentence'` once-noticed claims, em-dashes not commas):

- **mint + verify** — a tampered Idzeug fails `verify_idzeug` (negative control: flip a byte → rejected).
- **redeem imports the page** — after redeem Bob holds `%Pier,pub:alice / %Peering` with Alice's
   friendly (the "import a Peering stashed object" reborn — §5.3 / the `thawEnteredStashed` ancestor).
- **reciprocity** — after `pier_accept`, both sides carry a `%Grant,befriend` the *other* signed;
   `verify_grant` passes each way; a forged grant is rejected.
- **revocation** — a `%NotGrant` retires the Pier (§5.4).
- **persistence round-trip** — snap `Waft:Account` to disk, clear Dexie, re-seed from disk, and witness
   the identity + its Piers survive byte-identical (§3). This is the whole *robustness* claim, gated.
- **auto-mint** — boot with no `?I=`, empty Dexie, empty disk → an `%Identity,active:1` appears (§4).

Run it on the **live `:9091` runner** (`runner_ask.mjs run SwarmStaple --watch` → `snap <n>` → accept),
 **never headless** — the recorded fixtures must come from the live runner (CLAUDE.md; the headless boot
  quiesces at a different depth). The handshake is in-process/deterministic for now; the real-relay,
   two-real-browsers version is the same distributed-Story upgrade `Cluster_spec §5` describes.

**Wiring** — either add the arm code as a `.g` dock compiled to `gen/Story/*.go` and one line in
 `CREDULER_GHOSTS` (the PereStaple flavour), or as a `Run_A_SwarmStaple` recipe in a mounted `.svelte`
  ghost (the Lake* flavour). Keep the world named `w:SwarmStaple` or `do_fn_for` never runs the wrangle.

---

## 8. The coming UI — designed-for, not built-yet

A big new UI is coming — an **account page** (your name, your keypair status, backup/export), a
 **friends list** (your `%Pier`s, online/offline, per-friend grants), an **invite** control (generate
  an `?idz=` link / QR, redeem a pasted one), and per-friend **grant management** (what you've given,
   what you hold, revoke). **This spec builds the model that UI needs; it does not build the UI.**

**No new toplevel page yet** (the human: "a new toplevel page? nah maybe not yet"). Surface through
 existing seams first:

- the **🪪 IdHatch** grows from a key-paste hatch into the account face (§4) — or a **`Lens:Identity`**
   Brink tenant beside `Lens:Runner`/`Upkeep` (the ambient bottom-accreting dock, `Lens` handout), which
    is where a friends-roster + invite control naturally live without a route change.
- `%Peering`/`%Pier` render through the existing Waft/GhostList/`MiniWaft` machinery (bounded `C**`
   Travel) and Cyto (the graph is literally the social graph) — no bespoke widgets to see the model.
- the invite link is just a URL param (`?idz=`) the boot layer reads, like `?I=`/`?B=`/`?E=` — no page.

What the model must **not foreclose** (so the UI, when it comes, is a view not a rewrite): the account
 is one snappable Waft (§3), a contact is one particle with a pruned public face (§5.5), an invite is
  one signed struct (§5.2), a grant is one atom (§5.1). Every UI affordance is a read/mint over those —
   keep them clean and the toplevel page is a later, cheap addition.

---

## 9. The lineage map — old garden → reborn

The concepts to port (not the pre-C-model `.svelte` code — `Cluster_spec §1`):

| old (`Trust.svelte`, `Tyranny.svelte`, `Peerily`) | reborn here |
|---|---|
| `Trusting` / `MTrusting` — the feature + its Modus onboarding UI | `Waft:Account` + Auto (§3/§4) + the coming account face (§8) |
| `OurPeerings` / `OurPiers` (Dexie Things) | `%Peering` / `%Pier` particles in `Waft:Account` (§2) |
| `thawEnteredStashed` — paste JSON to import a Peering stashed object | snap import/export of an account *or* a contact (§3 pt 3, §5.3 redeem) |
| `Idzeug` / `Idzeugnate` — mint a signed invite URL-hash | `mint_idzeug` → `?idz=` link, signed by `%Identity` (§5.2) |
| `Idzeugnation` — the invitee redeems | Bob's redeem: verify → `%Pier` → `pier_hello` (§5.3) |
| `Idzeugnosis` — the authority verifies on-graph + grants | Alice's `pier_accept`: verify → bound `%Grant` — *peer is own authority*, no tyrant (§5.3) |
| `give_them_trust` — trust from Feature checkboxes | per-Pier `%Grant` abilities (befriend/follow/audio/disk) (§5.1) |
| `Idvoyage` — signed induction cert on the social graph | grant chains — friend-of-friend, **deferred** (§5.6) |
| `OverPiering` / `%Hath` — the who-exists directory | `%HostedIdentity` roster over the relay bind table (§6, `Cluster_spec §3`) |
| `Gardening` — which Piers to actually connect to | app-level engagement + presence beacon (§6) |

"Trusting" is the garden's membership/contact/invite machine, rebuilt on a transport that now works and
 a crypto atom (`Grant.ts`) that already exists. Keep the names that still carry meaning.

---

## 10. Open decisions

- **Account mount path** — always `<music>/.jamsend/account/<prepub>/`, or a configurable Wormhole
   path? (The pre-share chicken-and-egg is RESOLVED by §3's Dexie-first rule.)
- **Dexie ⇄ disk divergence** — when Dexie *and* disk are both non-empty and disagree (two devices,
   same account), last-write-wins on `toc.snap`, or a real `EntropyArrest`-style `C**` merge? Does the
    account tree get its own reconcile policy? (The same merge question the rest of the system has.)
- **Bearer vs bound Idzeug** — is the default invite a reusable standing link (bearer, multi-redeem) or
   single-use (`nonce`-invalidated)? Both fall out of §5.2; pick the default.
- **Idzeug delivery** — `?idz=` URL hash, copy-paste string, QR, or all three? (All are the same base64
   blob; a hash keeps the secret out of server logs — prefer the fragment.)
- **`Idzeug.ts` vs fold into `Grant.ts`** — a separate tiny module mirroring Grant's shape, or an outer
   `%Grant,invite,…` envelope carrying nested grants? (Grant claims are flat strings; a nested page +
    grant array wants its own encode — leaning a separate module.)
- **Revocation corpus** — where the standing `%NotGrant` set lives and how a serve/use checks it
   (`Grant.ts` seed-only today; the versioned corpus is owed — also a `Cluster_spec` TODO).
- **Identity ≠ address (multi-place)** — one identity open in N tabs binds the same prepub N times, so
   `to:<prepub>` fans out to all (the double-delivery bug one layer up). Do sessions get their own
    ephemeral per-tab key *vouched* by the identity (`to:<session>` = one place, `to:<identity>` = all
     my places)? Sequence against `Cluster_spec §3`'s runner role-bucket split. Deferred but real.
- **Two identity populations** — is a person's swarm `%Identity` ever also a cluster-trust key (a
   power-user who runs their own flock), or strictly separate populations? Keep separate until a real
    need (§4).
