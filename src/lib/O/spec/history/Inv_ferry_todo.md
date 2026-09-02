# ⚰ HISTORICITY NOTICE (2026-09-03)

The ferry exchange surveyed as a state machine, for Book coverage. Living content — the `?Iz`/`#fc`
 spine mechanics, the Book coverage map + missing-coverage list, the 11 assertion targets — absorbed
  into `spec/Crew_todo.md` §6/§7. The soul-key crossing it surveys is the superseded mechanism. Kept
   whole for the frame×state tables.

---

# Inv_ferry_todo.md — the ferry / invite / adopt / colonise exchange, as a state machine

> **ⓘ 2026-09-02:** the crossing this doc surveys — the soul key ferried to the Linkee, "both end up
>  bodies of ONE soul (key)" — is the SUPERSEDED mechanism. Cert-crew (`CrewLink_todo.md`): the Linkee
>   keeps its OWN key, the Captain mints a `Grant:Crew` at the seal, and the ferry carries account DATA
>    only (`{ferry:1}` omits the private key). The frame×state tables + the sealed-channel/secret
>     discipline below remain the map of the rungs the new ceremony still rides — read with that flip.

> **DRAFT 2026-08-30** — a SURVEY written to unit-test the ferry exchange with a Story Book
>  (task #35). Authored WITHOUT a live runner, so nothing here has been re-run: the frame×state
>   tables are read off `Ghost/S/Swarm.g`, `Ghost/N/Peeroleum.g`, the model Books in
>    `Ghost/Story/Swarmation.g` (SwarmSpread, SwarmFerry, SwarmSeal, SwarmInvite, SwarmDoor,
>     SwarmStaple), and the design's own worked writeup `Network_procedures_todo.md` (the ferry IS
>      that doc's reference example, Phases 1–11). Correct anything that has drifted.

## 0. What to do next / status

This doc is the high-value half of task #35: enumerate the exchange so the Book knows exactly which
 states are worth asserting. The Book half is `Ghost/Story/InvSeal.g` (refined) + a sibling
  `Ghost/Story/InvFerry.g` (new, this pass) — both DRAFTS, NOT yet compiled or run.

**Candidates for the next session (all need a live runner):**
- Compile `InvSeal.g` + `InvFerry.g` via LocalGen (GFILES must name them, or LocalGen silently
   skips — memory: runner-ask-player-ops-reload-dump), register both in `CREDULER_GHOSTS`
    (`src/lib/O/LiesLies.svelte:56`, add TWO lines beside `Ghost/Story/Swarmation.g`), author each
     Book's **Plan** in the editor (a missing Plan yields the hollow 1-step green — memory:
      hollow-book-1step-green; SwarmFerry's own fixture is exactly that hollow shape today, only
       `001.snap`, no `step=N` lines — do NOT copy it as a passing model).
- Run each `--watch` N≥5 (a race flip-flops `ok_pct`/dige); record the fixture from the LIVE runner
   only (headless `Story_cli_run.mjs` greens are a bubble — Phase 11).
- The NAME-GATE and the serial-REFUSAL are adjacent features landing separately (§4 below): the Book
   NOTES them as future beats but does not depend on them.

**The overall arc.** The ferry is the LinkDevice / "give my soul" ceremony: a **Linkor** (a soul
 device, full account) offers its whole account to a **Linkee** (a blank Cave-to-be, only a body
  key), the account crosses a SEALED channel (secret out-of-band on the URL `#fc=` fragment, never
   the relay), and both end up bodies of ONE soul. It composes two lower rungs already proven by
    Books: the **compact QR invite** (SwarmInvite/SwarmStaple — mint→carry→verify→claim→seal a
     mutual friendship) and the **Sealbox account crossing** (SwarmSeal/SwarmFerry — the AES-GCM
      seal/unseal that keeps the soul secret). The exchange is unit-tested at the MODEL layer; the
       live two-tab finger-proof (real socket, real QR camera) is un-Bookable and stays the human's job.

---

## 1. The parties and the shared fact (Network_procedures Phase 1)

| party | what it is | holds at start | holds at end |
|---|---|---|---|
| **Linkor** (soul / Captain) | a full account: `%Identity` + `%Peering` + keys + content (a self-issued `%Idzeug`) | the soul key; mints the ferry link + the random `#fc` secret | the same soul, now with a Cave body under its Charter |
| **Linkee** (Cave-to-be / Ebox / box) | a BLANK device — only a **body key**, no soul, no role | its own body key; can prove it holds that key (the adopt offer) | the very same soul key as the Linkor, wearing role **Cave** |

The ONE shared fact they converge on: **the account now lives on both devices** (the soul crossed;
 both are bodies of it; a Charter routes them). For the plain-friendship rung (SwarmInvite) the
  shared fact is instead **a mutual sealed Pier** — two strangers become peers.

**One-shot vs standing (Phase 1 — the trap that cost days):**
- **one-shot:** `Swarm_ferry_send` (export → seal → deliver, fires once at the sealing instant via
   the SEAL-SEAM `Swarm_ferry_on_seal`); the seal exchange itself; a redeem's hello→accept→confirm.
- **standing (needs a durable twin, Phase 5):** `ferry_secret` (Linkor `.c`) ↔
   `stashed.ferry_pending_secret`; `ferry_awaiting` (Linkee `.c`) ↔ `stashed.ferry_awaiting`;
    `ferry_confirm` (the parked consent); the UnInvite decline set (ONLY on `stashed.uninvited`).

---

## 2. Frames and their LANE (Phase 3)

Every wire frame in the exchange, and its reliability lane (`Peeroleum.g` `Peeroleum_send`
 ephemeral table + `Peeroleum_deliver` receive-bypass):

| frame | direction | lane | role |
|---|---|---|---|
| `pier_hello` | redeemer → issuer | **booked** (door-opening) | the redeem knock; echoes the Idzeug/token; first-contact promotes a Pier |
| `pier_accept` | issuer → redeemer | **booked** | the door accepts; carries the issuer's page/pub |
| `pier_confirm` | redeemer → issuer | **booked** | carries the DEFERRED reciprocal grant (3-frame seal) |
| `pier_reject` | issuer → redeemer | **booked** | the door refuses (spent serial etc.); surfaces as `%rebuff` |
| `ferry` | Linkor → Linkee | **booked** (one-shot payload, MUST arrive once) | the SEALED account blob (`{sealed, salt, role:'Cave'}`) crossing the pier |
| `ferry_got` | Linkee → Linkor | **booked** | the receive-ack; Linkor deletes secret/confirm/twin, lights "✓ received" |
| `adopt_seal` / `adopt_confirm` | soul ↔ box | **booked** | the account seal + consent in the scan-ceremony variant |
| `ferry_want` | Linkee → Linkor | **ephemeral** (self-re-asking, ~2.8s, 1100ms floor) | the demand beacon that re-triggers the seal-seam after a reload |
| `ferry_cancel` | either | **ephemeral** (one-shot teardown) | tear the ceremony down |
| `reinvite` / `reinvite_honour` / `reinvite_seal` / `reinvite_ok` | chain (RULED OUT §10, kept as capability) | booked | the re-assignable chain (not a live door) |

**The lane trap (Phase 3):** `ferry_want` was originally BOOKED and wedged forever — a reloaded Cave
 pier is not a sealed friendship, so `Swarm_station_routes` never re-stamps its `%Ud`, and a booked
  frame sits behind the pre-Ud gate un-drained. Moving it to the ephemeral receive-bypass
   (`Peeroleum.g:709`) unwedged the whole Adopt. A Book emits NEITHER `ferry_want` NOR `ferry_cancel`
    (send is pulse-/humdinger-gated) — so a fixture never records them (Book-inertness, Phase 11).

---

## 3. The state machine (the exchange, end to end)

The compact-invite rung and the ferry rung share the mint→carry→verify→claim→seal spine; the ferry
 adds the seal-seam + secret twin + account crossing on top.

```
 (Linkor)                                                    (Linkee)
   │
   │  mint                                                     blank device,
   │  Swarm_ferry_link(w, alice, base)                         only a body key
   │  → <base>?Iz=<token>#fc=<secret>                          Swarm_adopt_offer(bkeys, nonce)
   │  · %Idzeug,to minted (serial off the issuer)              (proves it holds its key)
   │  · ferry_secret on .c + twin in stash                     Swarm_adopt_verify(offer) → true
   │  · secret rides the #fc FRAGMENT (never the relay)
   ▼
 MINTED ───────────────── carry (the ?Iz token) ────────────►  the token is scanned/pasted
   │                                                            Swarm_iz_of_url(url) pulls ?Iz
   │                                                            Swarm_redeem(w, linkee, token)
   │                                                                    │
   │  ◄──────────────── pier_hello (booked) ───────────────────────────┘
   ▼
 VERIFY AT THE DOOR
   · Swarm_iz_find(serial) → the %Idzeug row (or unknown → refuse LOCALLY, §4)
   · presig REGENERATED by the ISSUER (truncate(issuer_sig(canonical(prepub,serial,$n)),16))
   · prefix-match: a flipped presig → refuse('forged') LOCALLY (only the issuer can check a presig)
   · Swarm_iz_spent(serial)? → refuse (double-spend / replay, §4)
   ▼
 CLAIM
   · Swarm_iz_claim(serial) ticks the serial `claimed` in the spend ledger (single-use)
   │  ────────────────── pier_accept (booked) ─────────────────────────►  Linkee lands issuer page/pub
   │  ◄───────────────── pier_confirm (booked, deferred reciprocal) ─────┘
   ▼
 SEAL (reciprocal grants)
   · both sides hold a mutual %Pier with cross-signed %Grants
   · FRIENDSHIP rung ends here (SwarmInvite/SwarmStaple): the seal is the goal
   │
   │  === FERRY rung continues (SwarmSpread beat 5 / InvSeal beat 4): a %Grant:MyCave pier ===
   │
   ▼  seal-seam: Swarm_ferry_on_seal(w, linkor, pier) fires at the sealing instant
 ON_SEAL (the CHOKEPOINT — gate on WARMTH not grant, Phase 4)
   · humdinger-gated: a bare runner sends straight through; a live tab PARKS for human consent
   · COLD pier (no heard_at within 45s) → parks NOTHING (grant is not presence — stale-corpse cure)
   · WARM pier (heard_at recent) → parks ferry_confirm keyed to the pier; holds the secret; sends NOTHING
   ▼  human gives their soul (the "give my soul" consent) →
 CROSS
   · Swarm_ferry_send(w, linkor, pier, code): export{secret} → SEAL → deliver `ferry` over the pier
   │  ────────────────── ferry (booked, the sealed blob) ──────────────►  lands in Linkee's inbox
   │                                                            Swarm_ferry_heard(w, linkee, frame, code)
   │                                                            · unseal with the #fc fragment code
   │                                                            · WRONG code → throws in unseal → fails closed, NO account
   │                                                            · import → now holds the SAME soul key
   ▼                                                            · derive Post = Cave from the grant
 CONSUMED
   · Swarm_ferry_consume clears the live secret + parked confirm + the durable twin
   · a reload NEVER rehydrates a resolved ceremony
   · both devices are now bodies of ONE soul; a Charter routes Captain(bare) + Cave(suffix)
```

**Cancel (the honest way out + the tidy-up):** `Swarm_ferry_cancel(w)` clears the live secret, the
 parked confirm, AND the durable twin. With no humdinger up it sends no frame and UnInvites nobody —
  the runner tab is handed back ferry-clean.

---

## 4. States worth asserting (what the Book proves)

The rows below are the assertion targets. Each maps to a `story_swear`/`%see` in the Book.

**Happy path (the exchange):**
1. **minted** — the Linkor mints the ferry link; the URL carries both the `?Iz=` token and the `#fc=`
    fragment; the live secret rides the FRAGMENT (never the relay); its durable twin lands in the stash.
2. **carried** — the token pulls back out of the URL (`Swarm_iz_of_url`) and parses to the offer.
3. **verified at the door** — the presig REGENERATES (not stored); only the issuer key can wear the MAC.
4. **claimed** — the serial ticks `claimed` in the spend ledger (single-use).
5. **reciprocal grants** — both sides hold a mutual `%Pier` with cross-signed `%Grant`s (`Grant,by`).
6. **seal-seam parks on WARMTH** — a WARM `%Grant:MyCave` pier sealing parks a `ferry_confirm` keyed
    to that pier; the secret is held; NOTHING crosses until the human gives their soul.
7. **the account crosses whole** — through seal→unseal→import the vessel re-exports byte-identical to
    the Linkor (a lossy transfer flips it).
8. **the secret never rides in clear** — the sealed `ferry` frame carries no private-key hex.
9. **the code gates arrival** — a WRONG code cannot unseal, so NO account lands (fails closed).
10. **the keys ride .c only across transit** — the landed account thaws its keypair onto `.c` and
     bears no `pub`/`key` scalar in `sc` (the ride-.c-only invariant survived transit).
11. **consume/reload safety** — cancel/consume clears the live secret, the parked confirm, AND the
     durable twin; a re-scan/reload does not un-spend and does not rehydrate a dead ceremony.

**Teeth (the failure edges worth a beat):**
- **cold-pier refusal** — the SAME seal on a COLD pier (no `heard_at`) parks NOTHING (grant is not
   presence — the stale-corpse cure). [InvSeal beat 4 asserts this today.]
- **double-spend refusal** — a second redeem finds the nonce spent → `pier_reject` / `%rebuff:rejected_spent`.
- **forged-serial / forged-presig refusal** — a flipped presig on a well-formed token → `refuse('forged')`
   LOCALLY (only the issuer regenerates the presig). [SwarmStaple beat 5 tooth; SwarmSpoof owns the crypto gate.]
- **tamper / wrong-nonce / withheld-consent → NO body** — the SwarmSpread beat-4 teeth family for the
   scan-ceremony variant.

**FUTURE beats (adjacent features landing separately — NOTE, do NOT depend on):**
- **the NAME-GATE** — the door refuses a redeemer whose claimed name collides.
- **the serial-REFUSAL semantics** — an UNKNOWN serial refuses LOCALLY with NO `pier_reject` reply
   (an unknown serial is indistinguishable from a probe, and serials are guessable, so replying would
    confirm the door to a serial-scanner — `Swarm_compact_invite_todo` §0). Assert this only once the
     feature lands; the Book leaves a commented placeholder.

---

## 5. Book-inertness + snap discipline (Phase 11, and the fixture law)

The reason a ferry Book records a byte-repeatable fixture despite crypto-random secrets:
- **Determinism is total:** fixed keys (seeded off the person's NAME so ed25519 signs repeatably), a
   pinned clock (`w.sc.now` stepped per beat), fixed nonces/serials.
- **The random `#fc` secret NEVER touches `sc`.** It rides `.c`/`stashed`. The note rows the witness
   reads are **booleans only** (`{minted:1, url_carries_both:1, ...}`), so the snap stays byte-stable.
- **`heard_at`, `humdinger`, the secret all ride `.c`/stashed** — never snapped. A snapped boolean is
   `1`-or-absent, never `false`/`0` (prefer deleting the key; use a C method so the snap tracks it).
- **Book-inertness:** the live-only park branch is `humdinger`-gated; a bare runner sends straight
   through. A Book raises `top.c.humdinger` for exactly the `on_seal` calls it wants to test the PARK
    of, then drops it — so no `screen`/consent frame leaks into the fixture. Book piers carry no
     `heard_at`, so the SEND branch is what a plain send-path Book exercises.
- **`heard_at`-derived state is run-VOLATILE.** Never assert cross-run `dige` equality on it; the gate
   is ok/exit-code (memory: runner-steps-dige-is-run-volatile). InvSeal pins `heard_at = Date.now()`
    to DRIVE the warm branch, but the note it stamps is the boolean OUTCOME (`confirm_parked:1`), not
     the timestamp — so the snap stays repeatable.

---

## 6. The verbs (the ferry API surface — `Ghost/S/Swarm.g`)

Signatures + line numbers verified against source 2026-08-30 (`Ghost/S/Swarm.g`, ~5155 lines). These
 are load-bearing for the Book — a wrong arg order or a param that isn't there won't compile.

**Mint / issue:**
- **`Swarm_ferry_link(w, soulIdent, base)`** (async, ~4422) → `base + '?Iz=' + token + '#fc=' + secret`.
   Mints a `{MyCave:1}` invite INTERNALLY (via `Swarm_mint_invite` — no `feature` arg), generates a
    16-byte random `secret` (32 hex chars), sets `top.c.ferry_secret = secret` AND the durable twin
     `top.stashed.ferry_pending_secret = {secret, at}`, arms arrival. Secret is client-side only.
- **`Swarm_invite_url(w, ident, feature, base)`** (async, ~499) → `base + '?Iz=' + token` (the QR front
   door, no `#fc`). Winds the issuer `next`; arms `Swarm_expect_arrival`.
- **`Swarm_mint_invite(w, ident, feature)`** (async, ~348) — the real shipping mint: draws a NUMBER off
   the issuer, creates NO particle, returns the token. presig over `(prepub, canon z.i, n)`.
- **`Swarm_mint_idzeug(w, ident, feature, nonce, chain)`** (async, ~371) — CHAIN + Books mint only: mints
   a `%Idzeug,Idzeug:<nonce>,to:<mainkey>` record with `.c.iz` = full signed atom, returns `.c.token`.
- **`Swarm_mint_blotter(w, ident, feature, count)`** (async, ~414) — loops `count`× `Swarm_mint_invite`,
   returns the ordered `?Iz=` sheet (no `%Blotter` particle).

**Carry / spend ledger:**
- **`Swarm_iz_of_url(url)`** — pull the `?Iz=` blob back out (the boot handler's core).
- **`Swarm_token_parse(token)`** (~146) → `{prepub, serial, n, presig, to, params}` or null.
- **`Swarm_iz_find(ident, serial)`** (~278) → `{kind:'legacy'|'serial', ...}` or null. Legacy tried FIRST
   (load-bearing order). This is who VERIFIES the serial exists.
- **`Swarm_iz_spent(f)`** (~336) / **`Swarm_iz_claim(ident, f)`** (~340) — the single-use ledger. Serial:
   run-list membership `Swarm_claimed_has`/`_add`, `claimed:"3-5~9~14"` (`~`-joined, NEVER commas).
    Legacy: `spent:1`. Both land through `Swarm_iz_mark` (sc + Dexie + disk mirror).
- **`Swarm_presig(keys, prepub, serial, n)`** (~135) — the issuer-side ed25519 MAC, sliced to 16 hex.
   ONLY the issuer's key regenerates it; regeneration IS the door's check (not third-party-verifiable BY
    DESIGN). The door `Swarm_hello` (~1811) re-signs its own ledger record and prefix-matches.

**Redeem / seal (three frames):**
- **`Swarm_redeem(w, ident, iz, advice)`** (async, ~1752) — the redeemer knocks: parse token, deliver
   `pier_hello` to the issuer. If `to==='MyCave'` sets `top.c.ferry_awaiting={soul,at}` + twin (the
    RECEIVER "connecting…" marker). Failure → `Swarm_rebuff('forged'|'offline')`.
- **`Swarm_hello(w, ident, frame)`** (async, ~1811) — THE DOOR (issuer verifies): guards `not_ours` /
   `spoofed` / `unknown`; regenerates presig → `forged` on mismatch; then `spent`/`held`; on pass
    `Swarm_iz_claim` + mints `%Grant` + `Swarm_seal` (one-sided) + delivers `pier_accept`.
- **`Swarm_accept(w, ident, frame)`** (async, ~1890) — the redeemer: `verify_grant`, mints the DEFERRED
   reciprocal grant, `Swarm_seal`, delivers `pier_confirm`.
- **`Swarm_confirmed(w, ident, frame)`** (async, ~1927) — issuer hears the reciprocal: must have an
   existing `%Pier` (`unexpected` else), adds their grant beside mine.
- **`Swarm_seal(w, ident, page, theirGrant, myGrant)`** (~2120) — BOTH ends land here: `oai` the `%Pier`,
   mints their imported `%Peering,name` page, adds the `%Grant`s (dedup by `to`+`by`), the `%Edge`, the
    durable twin. **The FERRY SEAM (~2157):** if `top.c` has a ferry secret AND `!ferrying`, calls
     `Swarm_ferry_on_seal`.

**Ferry (the account crosses the MyCave pier):**
- **`Swarm_ferry_on_seal(w, soulIdent, pier)`** (async, ~4444) — the SEAL-SEAM chokepoint. Guards
   `Swarm_pier_live(pier,'MyCave')` (else no-op — a plain friend seal). **HUMDINGER gate** (`top.c.humdinger`
    = live end-user): WARMTH check (`heard_at` within 45s) + UnInvite check; cold/uninvited → log +
     return (never park); else PARK `top.c.ferry_confirm={pub,name,at}` + `bump_version()`, send NOTHING.
      **Runner/Book (no humdinger): sends straight through** via `Swarm_ferry_send`.
- **`Swarm_ferry_confirm(w)`** (async, ~4499) — the grantor's "give my soul" button: reads
   `top.c.ferry_confirm.pub`, holds `ferrying` across the await, `Swarm_ferry_send`, clears on success.
- **`Swarm_ferry_send(w, soulIdent, pier, code)`** (async, ~4386) — one-shot: `salt = soulPub+':'+theirPub`,
   `blob = Swarm_export(soulIdent)`, `sealed = seal(code, salt, blob)`, delivers `{kind:'ferry', sealed, salt, role:'Cave'}`.
- **`Swarm_ferry_heard(w, ident, frame, code)`** (async, ~4403) — `unseal(code, frame.salt, frame.sealed)`
   (fails closed on wrong code/tamper), `Swarm_import`, keeps pre-ferry keys as `.c.bodykey`, takes `%Body`,
    Post from the MyCave grant. Returns the soul (null on wrong code).
- **`Swarm_ferry_consume(w, code, accept)`** (async, ~4786) — the Linkee's decide: on accept →
   `Swarm_ferry_heard` → `Clustation_concrete` (the soul becomes the ACTIVE identity) → `ferry_got` ack.
- **`Swarm_ferry_cancel(w)`** (~4702, used by InvSeal.g) — deletes ALL of `ferry_secret, ferry_pending,
   ferrying, ferry_confirm, ferry_awaiting` + both stash twins; UnInvites the counterparty; idempotent;
    sends `ferry_cancel` only if humdinger. Returns did-it-run.
- **wire handlers:** `ferry_want` (~1026, re-fires `on_seal`), `ferry_cancel` (~1044), `ferry_got` (~1049,
   the receive-ack: Linkor deletes secret/confirm/twin).
- **UnInvite (durable "no"):** `Swarm_ferry_uninvite/_uninvited/_reinvite` (~4685) — stamps a pub into
   `top.stashed.uninvited` (survives reload); `Swarm_link_fresh` consults it.

**Adopt / colonise (the sibling ceremonies):**
- **adopt** (blank device offers itself, `?Adopt=` URL, `adopt_seal`/`adopt_confirm` frames):
   `Swarm_adopt_offer(bodykeys, nonce)` (~4236, self-signs to prove it holds the body key),
    `Swarm_adopt_verify(offer)` (~4241), `Swarm_adopt_redeem(w, soulIdent, offer, role)` (~4252, the soul
     DIVIDES: `salt = soulPub+':'+offer.pub`, seals the account, mints `%Grant:My<role>`, delivers
      `adopt_seal`), `Swarm_adopt_absorb(w, container, bodykeys, nonce, frame, consent)` (~4269, returns
       null on tamper/wrong-nonce/no-consent), `Swarm_adopt_finalise(w, soul, ...)` (~4288, Captain at
        bare + Cave at suffix + Charter #1), `Swarm_adopt_sas(soulpub, bodypub, nonce)` (~4839).
- **colonise = the ReInvite CHAIN** (§6.3a, RULED OUT as a live door — kept as capability):
   `reinvite`/`reinvite_honour`/`reinvite_seal`/`reinvite_ok` frames; the TIP (not Alice) signs the
    newcomer's grant, capped at the embedded feature (no escalation); `%ChainRoot` hangs off `%Identity`.

**Particle shapes (mainkey + sc keys):**
- `%Idzeug,Idzeug:<serial>,to:<Feature>` — issuer's offer/scheme under `%Peering`. `next` present ⟺ issuer
   scheme row; `claimed:"3-5~9~14"` = the `~`-run-list spend ledger; `.c.iz` = full signed atom, `.c.token`.
- `%Pier,pub:<their prepub>` under `%Peering` — a sealed friendship; children = their imported
   `%Peering,name:<prepub>` page + the `%Grant`/`%NotGrant` rows; `.c.heard_at` = presence (never snapped).
- `%Grant:<ability>,by:<grantor pub>,for:<grantee pub>,time,sign` — the mainkey value IS the ability
   (`Music`, `MyCave`, `MyCaptain`); minted by `mint_grant`. `%NotGrant` is the revocation twin.
- `%Body,pub,role:<Cave|Captain>,address`; `%Charter` (soul-signed era-stamped roster); `%Invite,<serial>,
   state:<arrived|redeeming|sealed|refused>` (STATION-world only, never on an account snap); `%Edge` (social graph).

---

## 7. Model-Book map (how the Book is grounded)

| model Book | source lines (Swarmation.g) | fixture | what it lends the ferry Book |
|---|---|---|---|
| **SwarmSpread** | 3453–3658 (5 beats) | REAL: `001`–`005.snap` + `toc.snap` with `step=2..5` Assertion lines | THE ferry-glue path (beat 5: `Swarm_ferry_send`/`Swarm_ferry_heard`), the MyCave pier recipe, the teeth family. The closest PASSING multi-beat model. |
| **SwarmFerry** | 2295–2407 (2 beats) | HOLLOW: only `001.snap`, empty Credulate/Credulation, no `step=N` — a 1-step green | the seal-then-import CROSSING claims (whole/secret_hidden/code_gated/keys_thawed). Clean source but do NOT copy its fixture as a gate. |
| **SwarmSeal** | 2184–2294 (2 beats) | — | the Sealbox fails-closed pattern (roundtrip/fresh_iv/tamper/wrongkey) via `seal`/`unseal` IMPORT. |
| **SwarmInvite** | 448–567 (5 beats) | REAL | the QR front door: mint→carry→verify→claim→seal + the spent-QR photograph tooth. Uses `%see` (n-gated). |
| **SwarmStaple** | 33–216 (8 beats) | REAL | the full friendship handshake + the forged-presig / spent-nonce / offline teeth. Uses `story_swear`. |
| **InvSeal** (standalone) | `Ghost/Story/InvSeal.g` | none yet | the seal-seam warmth-gate beat itself (cold-refused vs warm-parks); the current draft. |

**Dialect rules the Book obeys** (CLAUDE.md + these Books):
- The `_drive`/`_T`/`_note`/`_witness`/`_order` skeleton, world named after the Book (`do_fn_for`
   dispatches by `w.sc.w` — the usual bomb), per-beat dispatch on `req.c.did_step` (req-local,
    immune to on_step's H-global).
- `.g` refuses braceless if/else and bare `let x` then if/else-assignment — always brace, always init.
- `%see:'sentence'` is once-noticed, self-describing, NO COMMAS (the peel splits on commas — use an
   em-dash —); `story_swear(w, 'sentence')` for durable sworn facts (idempotent per run, shelf-checked).
- A Book is authored so a LIVE runner runs it; the fixture (snap) is the gate.
