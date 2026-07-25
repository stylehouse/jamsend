# Trust_audit_handover.md — audit the `.g` production crypto against the Peerily reference

A continuation brief. Destination + the one correction + the next move.
Rewritten 2026-07-26 against the live tree, after a code read of both stacks. Correct anything that drifts.

---

## 🔁 The correction that rewrites this doc (this REPLACES the old "bomb")

**An earlier version of THIS file said the `.g` comms were a "Story-SIMULATION — don't audit them." That
 was WRONG, and the human corrected it twice.** Do not reinstate it.

- **`src/lib/p2p/Peerily.svelte.ts` is the PREVIOUS-GENERATION PROTOTYPE.** The human: *"src/lib/p2p/ is
   all the previous generation, a prototype, which does a lot correctly."* It has **solid fundamentals** and
    is still imported across `src/lib/` for identity primitives (`Idento` → `Id`/`Ud`). Treat it as the
     **REFERENCE for what good p2p crypto looks like** — not the thing to protect, not the destination.
- **The `.g` comms suite IS the real/production comms** — the human: *"the .g suite of comms is supposed
   to be real."* This matches `Peeroleum_spec.md` (the `.g` ghosts "are the law"; endgame **retires**
    `Peerily.svelte.ts` and renames Peeroleum → Peerily). It is a migration in flight: Peerily = the carrier
     that works today, the `.g` spine = the destination replacing it.
- **So: DO audit `Ghost/**`.** That is this doc's whole job now.

---

## 🎭 The one finding that matters: the `.g` crypto is SPLIT-PERSONALITY

A code read (verified file:line, 2026-07-26) says the `.g` family is **half real crypto, half deliberate
 mock** — and knowing which half is which is the entire game:

```
   Ghost/S/Swarm.g          ── SOCIETY layer ──      REAL ed25519.   ✅ meets/exceeds the reference
   (identity · contacts ·        invites, grants,     signHeader / verifyHeader / mint_grant /
    the Idzeug invite)           reinvites, vouchers   verify_grant — throws on forgery. Single-use
                                 all SIGNED+VERIFIED   spend + blotter + chain all BUILT & Book-green.

   Ghost/N/Peeroleum.g      ── TRANSPORT layer ──    MOCK (v1, on purpose).  ❌ not yet the reference
   Ghost/N/Tyrant.g              per-frame + the      hello "verify" = startsWith(pub); trust "verify"
   Ghost/N/Tribunal.g            hello/trust           = no-op; NO per-frame signature (body_hash is
                                 handshake             unkeyed sha256); the wire is a raw pipe.
```

**In one line:** the `.g` invite/grant crypto **is real and matches the Peerily reference** (and adds
 single-use, which Peerily never had); the `.g` **wire/handshake crypto is a placeholder** whose scaffolding
  is built but whose signatures are stubbed, awaiting the port from Peerily. Audit each half on its own terms
   — do **not** tar the real half with the mock half (or vice-versa).

---

## 📋 Peerily's minimal feature set → checked on the `.g` (the human's ask, discharged)

Peerily's appraisal, distilled to a checklist, each row checked against the `.g` code:

| # | Peerily reference property (verified in `p2p/Peerily.svelte.ts`) | `.g` production reality | verdict |
|---|---|---|---|
| 1 | **Per-frame content signing** — `emit` signs every frame's json: `crypto.sign = Id.sign(json)` (672), buffers too (676) | Peeroleum: **none**. `body_hash` is *unkeyed* sha256 (186-189); `header.sign` is an explicit landed-**later** TODO ("when header.sign lands…", 176-182) | ❌ **owed** |
| 2 | **Per-frame verify, throw on mismatch** — `process_single_unemit` throws before parse (745-746, 766-767) | Peeroleum: sha256 catches *corruption*, not forgery; `hear_hello` verify = `startsWith(pier%pub)` (150) | ❌ **mock** |
| 3 | **Trust rebuilt on EVERY (re)connect** — `reset_protocol_state()` on both `con.on('close')` (496) and `open`→`init_completo` (520), keeps nothing | Peeroleum: `Peeroleum_reset_handshake` drops protocol/hello/trust + in/outbox but **keeps `%Ud`** (649-675); `Tribunal_redial` calls it per-Pier on carrier change (296) | ✅ **real scaffolding** (rebuilds the *mock* handshake) |
| 4 | **Signed trust tokens** — `verify_trust` checks granter sig over `{to,time,pub}` (1011) | Peeroleum `hear_trust` = *"verify their grants (trivial under the mock)"*, a no-op (157-160); Tyrant trust = M1 over provisioned `%Ud` | ❌ **mock** |
| 5 | **Ability gated on a held grant** — feature route refused without `trust/trusted` (804-806); ~9.11s untrusted-hold (779-783) | Swarm: gossip is **grant-gated** (a revoked grant shuts the door); `Repli_allowed` re-checks consent at **every** leg (Repli:259-264); Peeroleum `peer_ready` startup-hold (234-242, enforced 603) | ✅ **real** (grant side) |
| 6 | *(Peerily has no invite single-use)* | Swarm: `deny('spent')` (698), durable iz-stash (721); ttl door (701); chain-holder tracking (707-718) | ✅ **exceeds** reference |
| 7 | **Forgery-resistant identity binding** | Swarm: `verify_grant`/`verifyHeader` throw (132, 204-206, 686, 712); `Swarm_page_bound` = prepub↔pub key-derivation check (60-69) | ✅ **real** |

Rows 1/2/4 are the **owed port**; rows 3/5/6/7 are already sound. Row 3 is the subtle one: the *machinery*
 to rebuild trust per-connect exists and is correct (it even preserves `%Ud`, the proven identity, exactly
  as Peerily does) — but what rides that machinery today is the mock handshake, so rebuilding it proves little
   until rows 1/2/4 land on it.

---

## 0. What to get on with next

### A. The per-connect trust rebuild — scaffolding is real, land the crypto on it
Don't re-audit whether trust rebuilds per connect — it **does**, structurally (`reset_handshake` keeps `%Ud`,
 clears hello/trust; `Tribunal_redial` re-arms per Pier on carrier change; `peer_ready` gates app frames).
  The move is to make what it rebuilds **cryptographic**, porting Peerily's proven pieces onto the ready
   Peeroleum scaffolding:
- **Land `header.sign`** (Peeroleum:176-182 says the seam is prepared — `body_hash` already commits the buffer,
   so a header signature covers header+body in one) = Peerily's per-frame `emit`-sign / `unemit`-verify.
- **Make `hear_hello` / `hear_trust` real** (Peeroleum:150, 157-160) — replace `startsWith`/no-op with a
   signature check over the peer's identity + granted abilities = Peerily's `verify_trust` (1011).
- Then row 3's per-connect rebuild becomes a *cryptographic* rebuild, and the wire matches the reference.
- **Gate any change with a live-runner Book** (the discipline). Candidate: a Peeroleum-handshake Book that
   proves a forged/replayed frame is refused after a reconnect (mirror the SwarmWire gate).

### B. ~~Add invite serial "already claimed" tracking~~ — **DONE, delete this job**
It's **already built** on the production `.g` stack: `Swarm_hello` refuses a replayed nonce —
 `if (record.sc.spent) return deny('spent')` (Swarm:698), set + durably stashed on claim (720-721). Blotter
  serials spend independently through the same door; the chain trilogy is Book-green (`SwarmBlotter ×2`,
   `SwarmChain ×2`). The *prototype* path also has it — `claim_Idzeug_number` + the literal `"prize already
    claimed"` (`ghost/Tyranny.svelte`:722, 775). The only serial-adjacent thing still **open** is the invite
     **ttl** (Swarm:700-701 "no ttl on the record = the invite waits forever") — that's the human's
      *"wander for months/years before claiming"* question, a **policy** choice, not missing code.

### C. The chain / society-layer crypto — **already audited + hardened (2026-07-22), don't redo it**
The chain is **built** (`chain:1` invites don't spend, track the tip/holder Swarm:707-718; grow via a signed
 ReInvite that embeds the original invite; `%ChainRoot` lineage; no-escalation — the Feature is pinned by
  Alice's signature). And the society-layer crypto has **already had two adversarial audits** (per
   `Radio_todo.md` §0 "INVITE-CRYPTO HARDENED 2026-07-22" + memory `swarm-seal-prepub-binding-hole`):
- The one real **HIGH** — `Swarm_seal` bound the verified key but not the routing prepub (an identity hijack)
   — is **FIXED**: `Swarm_page_bound` at all 5 seal entries + a backstop, proven RED→GREEN by the adversarial
    Book **SwarmSpoof** (green ×2), family non-regressed.
- **F1** (reinvite grant-oracle, Swarm:807-812) — **downgraded** by that same page-bound guard (810).
   **F3** (forged-hello leaving a transport route, Swarm:818) — closed by **verify-first** (refuse a spoofed
    hello locally before minting a route; SwarmSpoof beat-4b). **G1** (forgeable `header.from` fallback) and
     **R1** (rung-0 `sha256===cid` on chunk arrival, Book **RaBreach**) — both fixed + green.
- So don't re-open the society layer cold. The **one un-touched item** flagged there is **F5 — voucher-era
   freshness** (labelled "retracted / wrong-layer" in the heat of the earlier confusion). It is **not** a
    wrong-layer non-issue: it is exactly **job A** — the per-era voucher is link-auth by design, and "the real
     per-Pier handshake at the door" (Swarm:330-334) is the owed transport-crypto upgrade. Fold F5 into A.

---

## Where this sits — the way back to Radios (don't lose the road home)

This trust audit is **ONE LEG of the main spring, not a side quest.** The living doc is **`Radio_todo.md`**
 (read its §0 owed-ledger + §1.0 "the machine at a glance"); the mission is **Radiobuddies** — friends'
  libraries flowing over a *trust-gated* p2p wire (memory: `radiobuddies-shebang-unnamed`, THE MAIN SPRING).
   The wire is trust-gated precisely by the grants this audit is about: a friend's music only crosses on a
    grant that a real, signed handshake established. So "the wire signs every frame + trust is cryptographic"
     (job A) is **load-bearing for the actual product**, not abstract crypto.

**After the wire crypto lands, go back to `Radio_todo.md`.** The broader arc is there: the real carrier
 wiring (Tribunal's live `ws` pipe, §10.1), the owed live-gates (two-tab fingers-proof), and the fleet is
  green except the flagged **PereProof** dige-drift re-record (the human's call). Also still open, still real:
   the invite **ttl** policy (job B's leftover). Don't let the crypto leg become the whole map — it's the
    trust floor the music stands on.

---

## The files — where to stand (scout pointers; VERIFY, don't trust blind)

**Reference (prototype, read to learn the target shape):**
- `src/lib/p2p/Peerily.svelte.ts` — emit/unemit per-frame signing (672/745); `reset_protocol_state` on
   close+open (496/520); `verify_trust` signed tokens (1011); the hello→trust→trusted ladder (837-864).

**Production (`.g`, the audit target):**
- `Ghost/S/Swarm.g` (spec: `Swarm_spec.md`) — REAL invite/grant/reinvite/voucher crypto. Single-use spend
   (698/720), chain (707-718), reinvite F1/F3 (807-818), the per-era **voucher** (538-539, stapled 339).
- `Ghost/N/Peeroleum.g` (spec: `Peeroleum_spec.md`) — the transport spine. MOCK handshake (150/157-160),
   `header.sign` seam (176-182), `reset_handshake` (649-675), `peer_ready` (234-242).
- `Ghost/N/Tribunal.g` — carriers; the live `ws` wire is a raw pipe (97); `Tribunal_redial` re-arms trust (296).
- `Ghost/N/Tyrant.g` (design: `Covenant_design.md`) — admission over Peeroleum; M1 trust over provisioned `%Ud`.
- `ghost/Trust.svelte` / `ghost/Tyranny.svelte` — the **prototype** trust/Idzeug machine (serials 63-64/270-272;
   `claim_Idzeug_number` + "prize already claimed" 722/775). Same logic as Swarm.g, older stack.

## What NOT to do (the inverse of the old bomb)
- **Don't dismiss the `.g` as a simulation** — that was the prior error; it's production. **But don't assume
   the whole `.g` is crypto-real either** — the transport half (Peeroleum/Tyrant/Tribunal) is deliberate mock.
- **Don't re-file the detached per-era voucher** (Swarm:538-539, stapled to every frame 339) as a forgery bug.
   It's a per-era **link-auth** token by design — it authenticates the sender's key for the era, not each
    message — and the code self-caveats (330-334) that the "real per-Pier handshake at the door is the owed
     upgrade." That owed upgrade IS job A.
- **Verify every file:line above before building on it.** The retracted findings this doc exists to prevent
   came from grep-and-assume — and from mistaking one stack for the other.
