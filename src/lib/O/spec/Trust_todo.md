# Trust_todo — what's real on the wire, and the substrate beneath every ceremony

**What "trust" covers in jamsend.** Three questions, asked constantly, by code that has to answer them before it
 acts: *who are you to the relay* (a socket is nobody until a signed hello binds it to a key), *is this frame really
  from the peer it claims* (a signature or voucher, not just a header field), and *who may do what* (a `%Grant`,
   minted by a ceremony a human or a device actually consented to — Adopt, Ferry, a crew invite, a signed call to a
    box). The relay itself trusts nobody and sees everything in cleartext; every guarantee above that is built in the
     app layer, on top of an untrusted pipe. This doc holds both halves of that: **§1–§2** audit what's cryptographically
      real on the wire today (the audit was previously a separate handover, folded in here 2026-10-15), and **§3–§4**
       name the pattern every ceremony keeps reinventing — a grant, minted by a consent step, checked at use — and ask
        whether it should be one machine instead of several.

---

## 0. What to get on with next

**First, the wire (§1.3 — WT1→WT4), a session key per era:**
- **WT1** — an authenticated key exchange per era: each side puts an ephemeral X25519 public key into the era
   handshake it already does (`swarm_hi` / the voucher), signed by its identity key exactly as the voucher is. ECDH
    → HKDF with both prepubs and both eras as salt gives a pair session key. Nothing new to trust — the identity
     signatures are the ones already verified at the hear funnel.
- **WT2** — per-frame AEAD (AES-GCM, WebCrypto) over `{type, seq, era, body_hash}` + the body. The relay keeps
   cleartext `{from, to}` for routing only. One stroke: integrity, replay protection, privacy.
- **WT3** — retire the mock. `hear_hello` / `hear_trust` either carry WT1's keys or go.
- **WT4** — decide whether the sealed-account ferry rides the same session key or keeps its own seal.
- Owed before building: a design pass over `Peeroleum_spec.md` §4–§7 (frame format, inbox/ack), the era/reset
   machinery (`Swarm_note_era`, `Peeroleum_reset_handshake`), and the Books that pin frame bytes (SwarmShare,
    SwarmBody, Peeroleum Books) — encrypting changes bytes every wire-Book fixture holds.
- **Independent of `Signed_call_todo.md`** (Tend): a signed call is self-signed and safe on today's wire regardless.

**Then, the substrate itch (§3):** when WT1 lands, it IS a trust ceremony (a signed exchange that ends in a shared
 secret both sides checked). That's the first real data point for the §3 question — inventory every place a consent /
  grant / SAS / "do you trust this" decision is made (Adopt, Ferry, friend-invite redeem, Captain mint, Heist authz,
   WT1's handshake, a Tend call) and see how much is already the same shape, before proposing Trust as a real new
    register. See §4.

---

## 1. The wire: what's real and what isn't

Re-read 2026-10-13 against the live tree (the owner: *"I think there are per-frame signatures, and hello and trust
 checks should be real by now"*). Re-verified again 2026-10-15 against `src/lib/cluster_trust.ts`
  (`signHeader`/`verifyHeader`), `src/lib/server/relay.ts` (`fromGate`/`fromProven`/`RELAY_FROM_CHECK`), `Ghost/S/Swarm.g`
   (`Swarm_voucher_ok`/`Swarm_reach_vouched`), `Ghost/N/Peeroleum.g` (`hear_hello`/`hear_trust`). Everything below still
    held; one row improved (the voucher-cache-vs-revocation ⚠ is now a verified ✅ — see 1.2).

### 1.1 What is REAL now

| property | where | verdict |
|---|---|---|
| **Link auth to the relay** | a socket hellos with `{control:'hello', from, pub, ts, sign}`; `cluster_trust.ts`'s `verifyHeader` checks the self-signature before `relay.ts`'s `handleHello` binds the address. Role channels authenticate the same way but don't join the prepub's delivery fan-out | ✅ real |
| **Sender proof on every Swarm frame** | the per-era **station voucher** (`{control,from,pub,era,ts}` signed by the soul key, or by a crew body's own key + its `Grant:Crew`), attached to every swarm frame; verified by `Swarm_voucher_ok` against the pub imported AT SEAL. Crew road: `verify_grant` + by/for checks + `NotGrant:Crew` ejection | ✅ real, **per era** |
| **Pier-less frames** (reach, reach_done) | `Swarm_reach_vouched`: voucher signature + soul is mine or a sealed friend's | ✅ real, per era |
| **Society layer** (invites, grants, reinvites, crew charter/roster) | ed25519 throughout (`cluster_trust.ts`'s `signHeader`/`verifyHeader`), single-use spends | ✅ real |

### 1.2 What is still NOT real

| property | where | verdict |
|---|---|---|
| **Per-frame integrity** | the voucher is minted once per era and does **not** cover the frame's body, seq or type. Anyone who sees one of a friend's frames (the relay, which sees everything) can lift the voucher onto a forged body to that same peer until the era changes. `body_hash` is an unkeyed sha256 (`Peeroleum_body_digest`): it catches corruption, not forgery | ❌ owed — WT2 |
| **Replay of whole frames** | the inbox's seq guards ordering/dup within an epoch, but a seq isn't signed | ❌ owed (falls out of the row above) |
| **Peeroleum's own hello/trust** | `hear_hello` is `startsWith(pier%pub)`; `hear_trust` is a no-op ("trivial under the mock"). Now a sequencing handshake UNDER the Swarm voucher, so it matters less, but it's still a mock | ❌ mock, demoted |
| **Privacy** | every frame is cleartext to the relay. Only the device-link account ferry is sealed. That posture was accepted ([[ferry-security-posture]]) | ❌ none — WT2 |
| **The music plane's sender** | `repli_*` frames (catalog lines, audio pages, wants, parked/missed) carry no `swarm` bag, so no voucher. They were admitted on `header.from` alone, and the relay routed on `.to` without ever checking `.from` | ✅ **closed 2026-10-13 by the relay from-check** (1.25), for the transport; WT2 closes it cryptographically |
| **Voucher cache vs revocation** | `sealed.c.voucher_ok` short-circuits re-verification for the era | ✅ **fixed and verified**: `delete pier.c.voucher_ok` fires on every `NotGrant:Crew` ejection in `Swarm.g` ("the voucher cache must fall with the ejection… a membership change invalidates every cached verdict on that pier — clear it and re-decide") |

### 1.25 LANDED 2026-10-13 — the relay from-check (`src/lib/server/relay.ts`'s `fromGate`)

A frame whose `header.from` is identity-shaped (16 hex, optionally `_N`) is forwarded only if the SENDING SOCKET bound
 that address by a verified signed hello (`ws.bound`, set in `handleHello`). Frames that arrive while that socket's
  hello is still verifying queue behind it, in order, so a seq-ordered inbox never sees them overtake each other. Role
   names, `cli-*` and channels pass untouched. The relay-to-relay bridge isn't gated. `RELAY_FROM_CHECK=enforce`
    (default) | `log` | `off`.
- **A refusal** logs `⛔ FROM REFUSED … ×n` (first and every 100th) and sends the socket one `control:'from_refused'`.
- **Limits:** this trusts the relay. A malicious RELAY can still forge anything, and only WT2 fixes that. Within a pair
   that both hello on this relay, it closes header.from spoofing for every plane at once.

### 1.3 The plan: a session key per era turns all four ❌ into one mechanism

Signing every frame with ed25519 is the obvious port of Peerily's `crypto.sign = Id.sign(json)`, and it would close
 integrity. But it costs ~1 ms per op in JS at chunk rates of hundreds a second, and it still leaves the wire readable.
  The better rung is the one Signal-style systems use — see §0's WT1–WT4 for the four rungs.

---

## 2. Reasoning kept from the older audit

The audit (2026-07-26, corrected 2026-07-28, re-read 2026-10-13) made two findings worth keeping as standing
 reasoning, independent of §1's current numbers.

### 2.1 The `.g` suite is production, not a simulation

**An earlier version of this doc said the `.g` comms were a "Story-SIMULATION — don't audit them." That was WRONG,
 and the human corrected it twice. Do not reinstate it.**

- `src/lib/p2p/Peerily.svelte.ts` is the **previous-generation prototype**. The human: *"src/lib/p2p/ is all the
   previous generation, a prototype, which does a lot correctly."* It has solid fundamentals and is still imported
    across `src/lib/` for identity primitives (`Idento` → `Id`/`Ud`). Treat it as the **reference** for what good p2p
     crypto looks like — not the thing to protect, not the destination.
- **The `.g` comms suite is the real/production comms** — the human: *"the .g suite of comms is supposed to be
   real."* This matches `Peeroleum_spec.md` (the `.g` ghosts "are the law"; endgame retires `Peerily.svelte.ts` and
    renames Peeroleum → Peerily). It is a migration in flight: Peerily is the carrier that works today, the `.g` spine
     is the destination replacing it. So: audit `Ghost/**`. That is this section's whole job.

### 2.2 The split was society-real / transport-mock — now narrower, same shape

A 2026-07-26 code read found the `.g` family **half real crypto, half deliberate mock**, split cleanly by layer:
 `Ghost/S/Swarm.g` (society: identity, contacts, invites, grants, vouchers) was real ed25519 throughout; the
  transport layer below it was a deliberate mock. **That transport layer then included `Ghost/N/Tyrant.g`**, an
   admission ghost sketched as a minima ladder (M0 emit/ack, M1 trust-as-acked-exchange, M2 policy-gated admission,
    M3 cultivation) — **`Tyrant.g` was deleted 2026-09-16 with the old prototype**; its one idea worth keeping
     (`%req:join` as a conjunction of policy leaves) is parked in `Peeroleum_spec.md` §17.1, sourced from
      `history/Covenant_design.md`. Don't cite `Tyrant.g` as live anywhere; it's gone.

What shipped instead of Tyrant's ladder is exactly `Swarm.g`'s grant model — invites, `Grant:Crew`, per-era vouchers
 — which is §1's "society layer REAL" row. The split itself still holds, narrower: `Peeroleum.g`'s own hello/trust is
  still mock (§1.2), everything above it on the Swarm voucher is real (§1.1). **The one line that matters, still
   true:** audit each half on its own terms — don't tar the real half with the mock half, or vice-versa.

### 2.3 Peerily's minimal feature set, checked against the `.g` (historical audit trail)

Peerily's appraisal, distilled to a checklist and checked against the `.g` code on 2026-07-26. Kept here as the
 provenance for §1's verdicts — the live numbers are §1, not this table.

| # | Peerily reference property | `.g` production reality (2026-07-26 read) | verdict then | still true? |
|---|---|---|---|---|
| 1 | Per-frame content signing (`Id.sign(json)` on every frame + buffer) | Peeroleum: none. `body_hash` unkeyed sha256; `header.sign` a seam, not landed | ❌ owed | yes — §1.2, now WT2's job |
| 2 | Per-frame verify, throw on mismatch | sha256 catches corruption, not forgery; `hear_hello` = `startsWith` | ❌ mock | yes — §1.2 |
| 3 | Trust rebuilt on EVERY (re)connect, keeps nothing | `Peeroleum_reset_handshake` drops protocol/hello/trust but keeps `%Ud`; `Tribunal_redial` re-arms per Pier | ✅ real scaffolding | yes, machinery sound; what rides it is still the mock handshake (§1.2) |
| 4 | Signed trust tokens (`verify_trust` over `{to,time,pub}`) | Peeroleum `hear_trust` = no-op; **the then-current Tyrant trust layer was M1 over a provisioned `%Ud`** | ❌ mock | **Tyrant half is gone (2.2) — no replacement landed; still mock per §1.2** |
| 5 | Ability gated on a held grant | Swarm: gossip grant-gated; `Repli_allowed` re-checks consent at every leg; Peeroleum `peer_ready` startup-hold | ✅ real | yes |
| 6 | *(Peerily has no invite single-use)* | Swarm: `deny('spent')`, durable iz-stash, ttl door, chain-holder tracking | ✅ exceeds reference | yes |
| 7 | Forgery-resistant identity binding | Swarm: `verify_grant`/`verifyHeader` throw; `Swarm_page_bound` = prepub↔pub key-derivation check | ✅ real | yes |

Rows 1/2/4 are the owed port (now named WT1–WT4, §0/§1.3); rows 3/5/6/7 were already sound and still are.

### 2.4 Already-settled items — don't re-open

- **Invite "already claimed" tracking** is built: `Swarm_hello` refuses a replayed nonce (`if (record.sc.spent)
   return deny('spent')`), set + durably stashed on claim. Blotter serials spend independently through the same
    door; the chain trilogy (`SwarmBlotter ×2`, `SwarmChain ×2`) is Book-green. The only serial-adjacent thing still
     open is the invite **ttl** — "no ttl on the record = the invite waits forever" — a **policy** choice (the
      human's *"wander for months/years before claiming"* question), not missing code.
- **The chain / society-layer crypto** had two adversarial audits (2026-07-22). The one real HIGH finding —
   `Swarm_seal` bound the verified key but not the routing prepub, an identity-hijack hole — is fixed:
    `Swarm_page_bound` at every seal entry, proven RED→GREEN by the adversarial Book `SwarmSpoof`. Related findings
     (reinvite grant-oracle, forged-hello leaving a transport route, forgeable `header.from` fallback, rung-0
      `sha256===cid` on chunk arrival) are all fixed and green. Don't re-audit the society layer cold from here;
       start from `Swarm_spec.md` if it needs another pass.
- **The per-era voucher is link-auth by design, not a forgery bug.** It authenticates the sender's key for the era,
   not each message, and the code self-caveats that a real per-Pier handshake is the owed upgrade — that upgrade IS
    §1.3/§0's WT plan.

### 2.5 Where this sits — the way back to Radios

This trust audit is one leg of the main spring, not a side quest. The living doc is `Radio_todo.md` (its §0
 owed-ledger + §1.0 "the machine at a glance"); the mission is Radiobuddies — friends' libraries flowing over a
  trust-gated p2p wire. The wire is trust-gated precisely by the grants this section is about: a friend's music only
   crosses on a grant that a real, signed handshake established. "The wire signs every frame + trust is
    cryptographic" is load-bearing for the actual product, not abstract crypto. After the wire crypto lands, the
     broader arc continues in `Radio_todo.md`.

### 2.6 Scout pointers (verify before building — line numbers drift)

**Reference (prototype, read to learn the target shape):** `src/lib/p2p/Peerily.svelte.ts` — `emit`/`unemit`
 per-frame signing, `reset_protocol_state` on close+open, `verify_trust` signed tokens, the hello→trust→trusted
  ladder.

**Production (`.g`, the audit target):**
- `Ghost/S/Swarm.g` (spec: `Swarm_spec.md`) — real invite/grant/reinvite/voucher crypto (`Swarm_voucher_ok`,
   `Swarm_reach_vouched`, `Swarm_voucher_mint`); single-use spend; chain; the per-era voucher.
- `Ghost/N/Peeroleum.g` (spec: `Peeroleum_spec.md`) — the transport spine. Mock handshake (`hear_hello`,
   `hear_trust`); the `header.sign` seam (`Peeroleum_body_digest` already commits the buffer, ready for a signature
    to cover it); `Peeroleum_reset_handshake`; `peer_ready`.
- `Ghost/N/Tribunal.g` — carriers; `Tribunal_redial` re-arms trust per Pier on carrier change.
- `ghost/Trust.svelte` / `ghost/Tyranny.svelte` — the prototype trust/Idzeug machine, same logic as `Swarm.g`,
   older stack.
- ~~`Ghost/N/Tyrant.g`~~ — deleted 2026-09-16. Its design lives in `history/Covenant_design.md`; its one surviving
   idea is in `Peeroleum_spec.md` §17.1.

### What NOT to do

- Don't dismiss the `.g` suite as a simulation — that was the prior error; it's production.
- Don't assume the whole `.g` suite is crypto-real either — `Peeroleum.g`'s own hello/trust is still deliberate mock
   (§1.2), even though the Swarm voucher riding above it is real.
- Don't re-file the per-era voucher as a forgery bug — it's link-auth by design (2.4).
- Verify every claim above against the code before building on it — the retracted findings this section exists to
   prevent came from grep-and-assume, and from mistaking one stack for the other.

---

## 3. Trust as substrate — ceremonies as one reusable machine

A **capture doc, not yet a plan** (the Atheory pattern — an itch given an address). The owner reached for this while
 venting about the Adopt/Ferry ceremony, 2026-08-28:

- *"this powwow with the Adopt protocol needs to live under the Trust protocol… and all our protocols need to be
   secured by the Trust that enables them, somehow. are we within a `Grant:Adopt` role or something?"*
- *"I don't really care how elegant that is for right now actually, just venting, maybe put it somewhere."*

### 3.1 What this is about

One sentence: **every protocol we run (Music sharing, Adopt/Ferry, Heist, the invite ledger) is authorised by a
 grant, and the granting itself — the consent, the SAS match, the "yes, I trust this" — is a protocol in its own
  right that today is scattered and re-invented per feature.** The vent asks: name it. Make **Trust** the substrate
   every other protocol sits on, so a feature says *"I run under `Grant:Music`"* / *"I run under `Grant:Adopt`"* the
    way it already says which `%Feature` it carries — and the consent ceremony (popup + SAS emojis + the signed
     grant that results) is ONE reusable machine, not a thing each protocol grows its own crooked version of.

The tell that it wants naming: the **Ferry** path (the live device-link) superseded the **Adopt** path
 (`Crew_todo.md` §0, which absorbed `Division_todo`) and in doing so **lost the mutual consent + the EmojiConfirm
  SAS** that Adopt already had (`Swarm_adopt_sas_land`/`_consent`, "shows on BOTH screens to catch a relay MITM").
   Two ceremonies, one of them silently weaker — because the trust step was never a shared protocol, just code each
    side happened to carry. That's the disease this section names.

### 3.2 The `Grant:Adopt` musing

The owner's own half-question — *"are we within a `Grant:Adopt` role or something?"* — points at the shape.
 `Crew_todo.md` already models a body's Post as a cross-signed grant (`%Grant:MyCave`, `%Grant:MyCaptain`) rather
  than a self-chosen tag; Trust would generalise that: the RIGHT to run a protocol with someone is itself a grant,
   minted by a consent ceremony, revocable by `%NotGrant`, and gated at USE the way `Swarm_pier_live(pier, 'Music')`
    already gates the music dial. "Am I allowed to ferry my soul to you?" becomes the same question as "am I allowed
     to serve you music?" — a live grant check, not a bespoke handshake.

### 3.3 Not yet

No design here — this is the itch's address. When it starts: inventory every place a consent / grant / SAS / "do
 you trust this" decision is made (Adopt, Ferry, friend-invite redeem, Captain mint, the Heist authz — and now
  WT1's era handshake and a Tend signed call, §4), see how much is already the same shape (`mint_grant` +
   `Swarm_pier_live` + the SAS row), and only then propose whether **Trust** is a real new register or just the
    honest name for what `%Grant` + the ceremony already are.

### 3.4 First concrete step it implies (owed regardless of the big rename)

**Restore consent + SAS to the Ferry path.** Independent of whether "Trust" becomes a register, the ferry today
 auto-fires on seal with no grantor approval and no emoji match — strictly weaker than the Adopt ceremony it
  replaced. Re-attaching the grantor-consent popup (*"device X wants to become a Cave of your account — approve?"*)
   and the 3-glyph SAS is the first payment on this debt, and it doubles as the fix for *"eed has no idea / no trace
    on eed side"*. Tracked as the ceremony redesign in `Crew_todo.md`.

### 3.5 Its neighbours (so this doesn't grow in isolation)

- **`Crew_todo.md`** — the crew ceremony + grant model live here. Trust is the layer *beneath* it: Crew/Adopt is one
   protocol Trust would secure. The `#fc`→nonce decision there ("eed is the security control point") is already a
    Trust-shaped ruling: the human at the granting device IS the trust anchor, so the paranoid machine-secret is
     fluff.
- **`Focus_todo.md` / `Atheory_todo.md`** — the toplevel's attention and loading halves. Trust is a third
   cross-cutting substrate the rebuilt toplevel might own: who's allowed, who's shown, what's loaded.

---

## 4. Where the wire and the substrate meet

§1 and §3 read as two different projects, but they're the same question at two scales:

- **WT1 (§0/§1.3) is itself one trust ceremony.** An authenticated key exchange per era — each side signs an
   ephemeral key with its identity key, both derive a shared secret, and from then on frames ride that secret — is
    exactly the shape §3 is asking for: a consent step (the signed exchange), checked, that produces a durable
     authorization (the session key) consumed at use. It just runs between two machines instead of between a human
      and a popup, and the thing it grants is "decrypt/accept my frames this era" instead of "run as crew" or "ferry
       my soul."
- **`Signed_call_todo.md` (Tend) is another.** A Tend call envelope (`{tend, args, from, pub, to, ts, seq, sign}`,
   verified by the same `signHeader`/`verifyHeader` pair §1 audits) is a grant-gated ceremony in miniature: a human
    grants a key the right to ask a box to do things (§3.2's `Grant:Adopt` shape, concretely — call it
     `Grant:Tend`), and every call after that is "run under this grant," checked the way `Swarm_pier_live` checks
      music. Tend's own §3 note calls this out directly: *"the wire's sender proof today is a per-era voucher, which
       a relay could replay onto a forged body… a self-signed envelope is immune to both"* — the same reasoning §1.2
        gives for why the voucher alone isn't enough, applied to a third door.
- **The unification §3.3 asks for** is this: WT1's handshake, a Tend call's grant, Adopt's SAS, and Ferry's (missing)
   consent popup are four instances of one shape — *mint a grant via a checked consent step, gate a capability on
    holding it, revoke it by name*. Building WT1 and Tend as two independent efforts, each inventing its own
     envelope and verify function, is exactly the "scattered and re-invented per feature" disease §3.1 names. Once
      WT1 lands, it's worth a pass that asks whether `signHeader`/`verifyHeader` + a `%Grant` row is already the one
       machine, and every ceremony (human or machine) should be written as a caller of it rather than its own crypto.

---

## 5. Pointers

- `Signed_call_todo.md` — the signed-call grant (Tend): one envelope, any door (HTTP, relay, CLI), verified by the
   same primitives §1 audits. Independent build track; §4 above is where it rejoins this doc.
- `Crew_todo.md` — the crew/Adopt/Ferry ceremony this doc's §3 is about; the consent+SAS debt (§3.4) is tracked
   there as the ceremony redesign.
- `Peeroleum_spec.md` §17.1 — "the floor and what stands on it": the Linoleum/cabinetry/partying image, and
   Covenant's parked `%req:join`-as-policy-conjunction idea.
- `history/Covenant_design.md` — `Tyrant.g`'s design, retired; read only for the parked idea above, not as a live
   account of what exists.
- `Sharing_design.md` — the wire's privacy/sharing posture; catches up to §1's current numbers rather than
   duplicating them.
