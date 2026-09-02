# CrewLink_todo — device-link as a CREW of distinct identities, certified not copied

**The single clean statement of the device-link pivot (owner decision, 2026-09-02), after a week lost to a
 device-link that never completed live.** A linked device is no longer a copy of your soul key colliding
  with your other bodies on the relay; it is its OWN Identity, blessed into your crew by a signed Charter
   cert. This doc replaces the model in `Ceremony_handover_todo.md`, `Ceremony_layering_todo.md`, and the
    soul-key-copy ruling in `Division_todo.md`. It EXTENDS working code (the Charter machinery already runs
     on disk) — it is not greenfield.

Companions: `Division_todo.md` (the organism/organs teleology + Post/roster substrate — still live),
 `Reach_todo.md` (the cross-body procedure layer the cert-offer rides), `Cluster_spec.md` (the blessed
  relay statement). Memory: `device-link-cert-crew-pivot.md`, `foreign-want-door-holder.md`,
   `want-middleware-plan.md`.

---

## 0. WHAT TO GET ON WITH NEXT

The addressing self-collision that cursed the week is FIXED + Book-green (SwarmBody 23/23; seat-dodge in
 `LiesLies.svelte`, in-family want-clamp + `on_hello` door-reclaim in `Ghost/S/Swarm.g` — memory
  `foreign-want-door-holder.md`). Land-of-prepub (Model B) is in: bodies hello with their OWN keys, roster
   gossips, `%Body` rows are contact-learned (`Division_todo.md` §0). So the substrate is ready. The moves,
    in order:

1. **Map the cert path before rebuilding LinkDevice** (owner's explicit next). Trace on the DISK account
    (`/app/.jamsend/account/<soul>/toc.snap`, verify there — the Door UI lies) how a new Identity gets
     crew-blessed today: `Charter,era:N` payload (`pub:Post:soulname` per member + soul sig), the matching
      `%Body` rows, the `Pier … link,post:Cave` un-revoked both-way grants. eed carries `Charter,era:137` =
       Captain + 3 Caves, signed — that IS the cert-crew model, already persisted.
2. **Rebuild LinkDevice as cert-MINT, not key-COPY.** Today `Swarm_ferry_link` ferries the whole account
    blob (incl. the soul key) to a blank device. New: the new device mints its OWN body/identity key; the
     inviter signs a Charter membership cert over the new pub; the ferry carries only the account DATA
      (library/settings — replication, which already exists), never the root key. The QR's `#Iz=<token>&
       fc=<secret>` physical channel + fc-seal stay the hard gate.
3. **Port the cert-offer onto `%Reach` (W2).** The knock that offers membership settles
    `landed | refused,<why> | dead,nobody-answered` — the Reach primitive is complete + Book-gated
     (`Reach_todo.md`, `want-middleware-plan.md`). This ships the missing "nobody answered the door" error
      the old ceremony lacked, and deletes LinkDevice's tick/ask_at/pulse-fallback pumps. LIVE two-tab
       proof is human-gated.
4. **Surface the Cave-side consent.** Today's live link fails cleanly because the "become part of this
    crew?" offer never surfaces on redeem (it lands on the Link INTRO, not the consent). Find why the ferry
     phase never reaches `'offered'` (parked ghost-side at Swarm standup off the `#Iz`; `Swarm_ferry_facts`
      reads phase `'offered'`→`f.offer`).
5. **Make the Charter an account-BACKUP vector** (owner's additive ask): replicate the account blob across
    the crew and keep it fresh, so the division IS the backup — MyCaptain "resume from backup" (Division
     §0a) regrows a lost organ from any surviving member. All FSA-able.
6. **Housekeeping owed:** prune eed's ~12 dead Caves (all NotGrant); stop reloading — let the ~30s relay
    reaper clear stale sockets rather than piling bindings.

Do NOT re-open the seat/`want`/soul-family arbiter (`ClusterAddressing_todo.md` ⚑ entries) — cert-crew
 deletes that problem; distinct identities never collide.

---

## 1. THE MODEL — certify a new key, do not copy the old one

**Each device is its OWN regular Identity** — own key, own address. The relay handles distinct addresses
 perfectly (proven headless in `scripts/ceremony-addr-test.ts` phase C); it is built NOT to let two live
  sockets hold one name, which is exactly what the old soul-key-copy fought. Device-link becomes four
   moves:

- **Mint.** The new device generates its own body/identity key locally (never handed one).
- **Certify.** The inviter (Captain, or any body holding the helm per Division §0a) signs a **Charter
   membership cert** — "this Identity is one of mine / part of my crew." The Charter is the era-versioned,
    soul-signed ledger of `pub:Post:soulname` members; adding a member bumps the era.
- **Gossip to Piers.** You tell your friends your whole crew set (the roster, already replicated
   body↔body via `roster_of`/`roster_onto` and published to friends on the pier page / `pier_accept`).
    Friends trust a member frame the way they trust every body-signed frame; the Charter cert proves
     membership.
- **Render member as you.** A friend's UI renders ANY crew member as "you" — one presence, many bodies.
   Grouping lives in the **Pier/Peering table** (app layer), NOT in relay-address collision. Owner: "can
    we group them in the Pier table better than we can make them work colliding on the relay? — yes, by a
     mile."

**Semantics preserved:** a linked device is still a TWIN — same account/library, blessed high in the app.
 Only the MECHANISM flips. It is also SAFER: per-device revocable keys mean one stolen device ≠ whole
  identity gone (revoke that member's cert; the soul key was never on it).

**Reuses existing machinery** (map before rebuilding): the Charter (signed crew ledger, era-versioned),
 Grants (cross-signed trust — friendships only), roster replication, the `%Body` roster. Land-of-prepub
  already has bodies hello with their own keys and contact-learn each other's `%Body` rows — cert-crew is
   the identity story that substrate was built for.

---

## 2. WHAT DIES

- **The soul-key COPY.** The ferry no longer transplants the soul key (or an account blob containing it)
   into a blank device. `Swarm_ferry_link`'s key-transplant path retires; only account DATA replicates.
- **The soul-door COLLISION and everything built to survive it:** the seat arbiter, `foreign want`, the
   door-yield/rehome "switcheroo", the `${prepub}_${rid}` extension-room addressing build, the
   seat/primary/recapture failover question. All of it existed to make two live sockets share one name —
    unnecessary when devices never share a name. (`ClusterAddressing_todo.md`'s ⚑ v3-hello work,
     `Ceremony_layering_todo.md`'s reborn-knock collision-branch surgery.)
- **The "Charter: deleted" sub-ruling** (`Division_todo.md` §0 ⚑⚑⚑). REVERSED: the Charter is the
   membership cert AND the backup ledger. It stays.

**What does NOT die:** the account/library DATA still has to sync between devices (data replication, which
 exists) — that was always true and is not identity. Friendships keep the full Grant handshake (Grants are
  for relationships between PEOPLE; Links are your account in multiple places). The `who` presence probe
   stands (`Presence_todo.md`); "is this soul online" becomes the union of the crew's presences.

---

## 3. THE ACCOUNT-BACKUP EXTENSION (additive)

Owner: "how else do you backup but with all your bodies? we want some stuff to be quite immortal, and
 share it amongst our bodies." The division IS the backup. The Charter, being the crew ledger every member
  carries, becomes the natural vector for it:

- **Replicate the account blob across the crew** and keep it fresh (not a one-shot ferry-at-link). Every
   member carries the account-matter, so it is "quite immortal": lose a device, any surviving member
    regrows the organ (Division §0a's MyCaptain = resume-from-backup).
- **All FSA-able** — a backup member is a body describing the account-organ it grows, legible matter, not
   a `.c` flag (the one bet).
- This is ADDITIVE on top of §1's cert-mint; it does not gate the turn-key link.

---

## 4. TURN-KEY DELIVERABLES

1. LinkDevice rebuilt: new device mints own key → inviter signs Charter cert → ferry carries account DATA
    only (no key transplant).
2. Cert-offer as a `%Reach` (settles landed | refused,why | dead) — the "nobody answered" error shipped;
    LinkDevice's pumps deleted.
3. Cave-side "join this crew?" consent surfaces on redeem (fix the ferry phase never reaching `'offered'`).
4. Friends learn the crew set (roster gossip already carries it) and render any member as "you".
5. Account-backup: replicate + keep-fresh the account across the crew, over the Charter.
6. Per-device revocation: a member's cert is revocable (`%NotGrant`-style) without touching the soul key.
7. Prune dead Caves + stop the reload-pile; trust the relay reaper.

---

## 5. THE DISEASE THIS RETIRES (record, so it is not re-caught)

The week's failure was an ADDRESSING self-collision, not a foreign relay holder and not stale ceremony
 code: a tab's own two sockets fought for its soul name — a no-`want` Lies/role-channel hello seated the
  bare prepub on the relay, so the station socket got suffixed OFF ITS OWN NAME by its sibling → door-yield
   → rehome → `foreign want` → `to:<soul>` dead-ended unprocessed in w:Lies. FIXED client-side (seat-dodge,
    in-family want-clamp, `on_hello` door-reclaim), proven in `scripts/ceremony-addr-test.ts` §D (10/10) +
     relay-test + SwarmBody 23/23, zero fixture churn. The forensic trail is
      `foreign-want-door-holder.md`, `Ceremony_handover_todo.md`, `Ceremony_layering_todo.md`. Keep the one
       durable architectural taste from the layering doc: **a knock must never depend on a %Pier existing;
        the ceremony must never depend on the %Pier's stream state.**
