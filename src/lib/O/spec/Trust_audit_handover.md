# Trust_audit_handover.md — audit per-connect trust rebuild + add invite serial-claiming

A continuation brief for a fresh session. Destination + the one bomb + the next move.
Written 2026-07-21 against the live tree; correct anything that has drifted.

---

## 💣 THE BOMB — read this or waste the session

**The LIVE p2p crypto lives in `src/lib/p2p/Peerily.svelte.ts` — NOT in the `.g` ghosts.**
Peerily's `emit` (line 672) signs EVERY frame's content with the sender's identity key
 (`crypto.sign = enhex(await this.eer.Id.sign(json))`, `+buffer_sign`), and `unemit` /
  `process_single_unemit` (~745/766) VERIFIES it (`await this.Ud.verify(dehex(crypto.sign), data)`,
   throws on mismatch). Trust is **per-channel state** — `reset_protocol_state` (821) + the
    hello→trust→trusted handshake + `verify_trust` (1011) over signed trust tokens.

`Ghost/S/Swarm.g` + `Ghost/N/Peeroleum.g` + `Ghost/N/Tribunal.g` are the **Story-SIMULATION
 transport** (LiesLies.svelte:59 literally "carriers — mock / webrtc / websocket relay"; its real
  carrier is still a loopback, Radio_todo §10.1 "WebRTC/relay untested by any Book"; Tribunal's
   `wire` at :97 is a raw dumb pipe). A prior session (2026-07-21) audited THAT sim layer, mistook
    its detached `voucher` for the production security boundary, and filed bogus "voucher forgery /
     catalog clobber" findings — **all RETRACTED**. Do not repeat it. For anything crypto/trust,
      confirm which stack is live (grep the imports — the `src/lib/*` app imports `p2p/Peerily`) and
       read Peerily + Trust + Tyranny. (memory: `peerily-live-p2p-crypto`.)

---

## Where this sits — the way back to Radios (don't lose the road home)

This crypto/trust audit is **ONE LEG of the main spring, not a side quest.** The living doc for the
 whole thing is **`Radio_todo.md`** (read its §0 owed-ledger + §1.0 "the machine at a glance"); the
  mission is **Radiobuddies** — friends' libraries flowing to each other over a *trust-gated* p2p wire
   (memory: `radiobuddies-shebang-unnamed`, THE MAIN SPRING). Trust matters here precisely because that
    flow is trust-gated: a friend's music only crosses on a live, rebuilt-per-connect relationship, and
     an invite is how a stranger becomes a sealed friend — so "trust rebuilds after each connect" (job A)
      and "an invite is single-use" (job B) are **load-bearing for the actual product**, not abstract crypto.

**After A + B land, go back to `Radio_todo.md`.** The broader arc is there: the real carrier wiring (the
 `.g` wire is still a loopback, §10.1), the owed live-gates (the two-tab fingers-proof), and the fleet is
  green except the flagged **PereProof** dige-drift re-record (§0 "health-sweep reds", the human's call).
   Also parked, un-retracted, still real: the invite **ttl** question (how long an invite may wander before
    claiming). Don't let the crypto leg become the whole map — it's the trust floor the music stands on.

---

## 0. What to get on with next

Two jobs, both strictly on the LIVE stack (`p2p/Peerily.svelte.ts` + `Trust.svelte.ts` +
 `ghost/Trust.svelte` + `ghost/Tyranny.svelte`). **The human's steer:** *"check trust does get built
  up after each connect, and add the serial-number claiming."*

### A. Audit that per-channel trust genuinely (re)builds after EACH connect
Verify — don't assume — that every (re)connect rebuilds trust cleanly and no trust-affecting message
 crosses *as trusted* before trust is re-established.
- **The seam:** `con.on('open')` (Peerily:481) → `init_completo` (516) → `reset_protocol_state` (520 —
   clears `said_hello/said_trust/heard_trust/trust/trusted` + `retry_untrusted_messages_until_ts`) →
    `say_hello` (526) → hello→trust→trusted (handlers 837-864, each gated on `is_vaguely_trusted` 954)
     → `verify_trust` (1011, the signed trust-token check).
- **The untrusted-message window:** `retry_untrusted_messages_until_ts` (776-783) holds/retries
   messages for ~9.11s until trust re-establishes. Confirm nothing trust-affecting slips through it.
- **Questions to answer with the code:** (1) does a RECONNECT always reset+rebuild, never reuse stale
   `trust`/`trusted`? (2) are the `trust`/`trusted` handlers truly refused until `is_vaguely_trusted`
    (837-864 return early)? (3) does `verify_trust` reject a token signed by the wrong key or naming the
     wrong pub? (4) can a Pier get stuck half-trusted — said-not-heard — across a flaky reconnect?
- **Gate it with a Book** if you build/change anything (the live-runner discipline), but the AUDIT
   itself is a code read of the real stack — no Book needed to just check the logic.

### B. Add the invite serial-number "already claimed" single-use tracking
The human recalls a prior version where an invite carried a **serial** and we tracked claimed serials
 for a *"prize already claimed"* failure (single-use). Restore/add it on the current stack.
- **What exists:** `stashed.PierSerial` + `stashed.IdzeugSerial` monotonic counters
   (`ghost/Trust.svelte:63-64`); a Pier is assigned a serial on creation (`Trust.svelte:885-887`).
- **What to verify then add:** is there a SPENT-serial set that refuses a *second* claim of the same
   Idzeug serial? (A light scout suggests NOT — confirm.) If absent, add it at the claim/admission
    seam: `ghost/Tyranny.svelte` — `Idzeuging` (264) / the `Idzeugnation` officiation flow (see the
     bad-actor / hacked-Idzeugnation notes at :121-174). A claimed serial is recorded durably; a
      re-claim fails "already claimed". This is the companion to the still-open **invite ttl** question
       (the human: invites may need to "wander for months/years before claiming" — so the serial, not a
        short ttl, is what must enforce single-use).

---

## The files — next session starts here (scout pointers; VERIFY, don't trust blind)

- **`src/lib/p2p/Peerily.svelte.ts`** — the live transport. emit/unemit signing; the
   connect→hello→trust→trusted handshake; `reset_protocol_state`; `verify_trust`. (Note: there is also
    a near-twin `src/lib/O/Peerily.svelte.ts` — the app imports the **`p2p/`** one; confirm which is live.)
- **`src/lib/Trust.svelte.ts`** — the trust-token TYPES (`ToTrust`/`SaidTrusticle`/`StashedTrusticle`)
   + `Trusting`. The comment at :182-184 documents the sign/verify envelope (server strips `.sign`,
    adds `.pub`, verifies the rest as json).
- **`src/lib/ghost/Trust.svelte`** — the trust-token + Idzeug/Peering/Pier machinery (the serials live here).
- **`src/lib/ghost/Tyranny.svelte`** — the Idzeug ADMISSION / officiation (`Idzeugnation`). The natural
   home for serial-claiming; the design notes on bad actors are at :121-174.

## What NOT to do
- Don't audit `Ghost/S/Swarm.g` / `Peeroleum.g` / `Tribunal.g` as production crypto (**the bomb**).
- Don't grep-and-assume — every file:line above is from a LIGHT read; confirm against live code before
   building on it. The retracted findings this handover exists to prevent came from exactly that shortcut.
