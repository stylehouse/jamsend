# Swarm_compact_invite_todo.md — the small QR invite (prepub · $n · presig), as the CANONICAL form

The front-door QR invite is 428 chars today (`sign` 128 hex + `by` 64 hex = the bulk). It wants to be
 tiny (a QR the phone scans easily). This doc is the verified design to shrink it to ~40-50 chars AND
  **standardise on that compact form as canonical** — the old full-atom Idzeug is REPLACED, not kept
   alongside (human ruling 2026-07-27: *"I'd like to standardise on this form, so it could take over the
    canonical Story of etc."*). No dual-regime.

---

## 0. What to do next / status

**IMPLEMENTED + FULLY RE-RECORDED (2026-07-27).** The seam is CUT in `Ghost/S/Swarm.g` (token codec
 + presig + 3-frame seal + `Swarm_confirmed` + dispatch + rehydrate-params), `InvitePanel.svelte`
  parses the compact token at the door, gen compiled (LocalGen), and **ALL 15 Books are GREEN×2 on
   runner 20e3476b**: SwarmStaple/Wire/Invite/Door/Got/Policy/Share/Chain/Blotter/Spoof +
    MusuRaStream/RaChase/Buddy/Mag/Heist, with SwarmSteal green as an untouched regression check.
     **SwarmSpoof — the security gate — PASSED**, its new beat 5 mounting the guessed-serial +
      forged-presig probes (Assertion:presig-mac-teeth latched). Entropy Books converged on the
       known accept-twice pattern (RaChase). REMAINING: the live two-tab fingers-proof of the new
        QR (mint on one Sounditron, scan on the other — needs the human's tabs).
 Notable semantics change vs the design: an UNKNOWN serial now refuses **locally** (no pier_reject
  reply) — without a third-party-verifiable signature an unknown serial is indistinguishable from a
   probe, and serials are guessable, so replying would confirm the door to a serial-scanner.

**The change is TWO coupled moves** (one enables the other):
1. **Defer the reciprocal grant** (2-frame → 3-frame seal). Because the compact token no longer carries
    the issuer's full pub, the invitee can't mint its reciprocal at redeem — it defers to after
     `pier_accept`. This is EXACTLY the existing ReInvite honour→seal split, so it's a proven shape.
2. **Shrink the token** to `prepub · serial · $n · presig` (§1), which the deferral unblocks.

Two **adjacent big-deal threads** the human raised — SCOPED SEPARATELY in §7, NOT part of this cut:
 (a) migrate the old garden's key/spend-ledger; (b) persist Identity per-Identity on `.jamsend` + resolve
  "which is main" on a fresh browser.

---

## 1. The compact token (canonical)

A compact **string** (not JSON/base64): `<prepub16>·<serial>·<$n>·<presig16>` (separator TBD — the old
 garden used `-`; `.`/`~` are the peel hierarchy chars, cf `Swarm_legacy_advice` Swarm.g:281).

| field | ~chars | role |
|---|---|---|
| `prepub` | 16 hex | issuer address — the invitee dials it (replaces `by` for routing) |
| `serial` | ~4-12 | the single-use %Idzeug ledger key (nonce). Infinite until first claim (no `time`) |
| `$n` | var | the Feature + params. **class-id default 1 OMITTED** to save space (human's model); `to`=Music etc. |
| `presig` | 16 hex | `truncate(issuer_sig(canonical(prepub, serial, $n)), 16)` — the issuer regenerates + prefix-matches |

**DROPPED vs today** (`{to, by, for, time, nonce, prepub, friendly, sign}`):
- `by` (64 hex) — revealed at `pier_accept` (`frame.page.pub`), so not needed in the token.
- **`for` — OMITTED entirely** for the open invites we make now (human 2026-07-27: *"`for` should be left
   out most of the time … rather than being '\*'"*). A `for`-bound (targeted-at-one-pub) invite is a later
    variant that adds it back. Absent `for` also drops from the signed domain.
- `time` (10) — no expiry; the human's expected model is "works infinitely for the first grant, then it
   moves to the reciprocal grant" (single-use by serial, no clock).
- `friendly` — optional; omit from the QR (the redeemer names themselves at the door anyway).
- full `sign` (128) → `presig` (16).

The **ReInvite/chain blob KEEPS its full embedded sign** — the tip third-party-verifies Alice
 (`Swarm_verify_reinvite` Swarm.g:205, they've never met), non-negotiable. It isn't the QR anyway.

---

## 2. Why the presig still stops spoofing (16 hex is enough — the anti-guess argument)

The §4-hazard: dropping the full signature loses the "genuinely-ours, non-forged" crypto basis of
 `Swarm_hello:685-686`. The presig restores it, **re-based from third-party-verify to issuer-regeneration**:

- On redeem the issuer looks the `serial` up in its OWN `%Idzeug` ledger (issuer-private, `Swarm_hello:696`)
   — an unknown serial is `deny('unknown')`. That already stops inventing a serial.
- But **serials are guessable** (blotter serials are literally `<tag>-1`, `<tag>-2`, … `Swarm_mint_blotter`
   Swarm.g:157). Without a presig, a guessed serial would seal. The **presig is a per-serial MAC only the
    issuer's key can produce**; the issuer regenerates it deterministically (ed25519 is deterministic) and
     prefix-matches. A forger can't compute it → `refuse('not_ours')`. 64 bits is ample for an ONLINE,
      single-use, deterministic check (offline third-party verify would need the full 512 — we don't do that).
- The issuer uses its LEDGER record's `$n` as authoritative (not the carried `$n`), so `$n`-tampering is
   moot; the presig also covers `$n` as belt-and-suspenders.

So the anti-spoof PROPERTY survives; only its mechanism changes. **SwarmSpoof is RE-EXPRESSED** to mount
 Mallory's same attack against the compact invite (see §4/§5) — that green IS the proof the tooth bites.

---

## 3. The reciprocal-grant deferral (2 → 3 frames) — templated on ReInvite

Verified today (2-frame): `pier_hello` carries the invitee's reciprocal grant (Swarm.g:658, minted for
 `claim.by` at :657); `Swarm_hello` seals BOTH grants (:724) and answers `pier_accept` (:725). The invitee
  knows `by` because the FULL SIGNED TOKEN carries it — which is exactly what we're removing.

New (3-frame), mirroring the chain's honour→seal split (Swarm.g:815 one-sided seal, :851 reciprocal-later):
1. **`pier_hello`** INVITEE→ISSUER — `{ prepub, serial, $n, presig, page }`. **No `grant`.** (Drop the mint
    at :657 + the `ident.c.offered` stash at :665-666.)
2. **`pier_accept`** ISSUER→INVITEE — unchanged shape `{ grant: mine, page }` (already carries the issuer's
    full pub via `page.pub`). `Swarm_hello` seals **one-sided**: `Swarm_seal(w, ident, frame.page, null, mine)`
     (like reinvite_honour :815). Move the reciprocal verify/gate (:711-714) OUT of hello.
3. **`pier_confirm`** INVITEE→ISSUER (NEW) — `{ grant: reciprocal, page }`. In `Swarm_accept` (:732) the
    invitee now has the issuer pub (`frame.page.pub`) + Feature (`frame.grant.to`) → mint the reciprocal
     HERE, seal locally, send it back (like reinvite_seal :851).
4. **`Swarm_confirmed`** (NEW issuer handler, mirror `Swarm_reinvite_sealed` :856) — `Swarm_page_bound`
    guard, `verify_grant`, gate `for === my pub`, `Swarm_seal(w, ident, frame.page, frame.grant, null)`
     (idempotent; seal dedups grants at :951). Wire into dispatch (:381-383, :394, :421-423).

Safe ordering (verified): the nonce SPEND (:720) depends only on the token being genuine+ours+bound+unspent
 (:685-698), NOT on the reciprocal — so moving :711-714 out is sound.

---

## 4. Invariants that MUST survive (RE-EXPRESSED on the compact form, not preserved in parallel)

- **`Swarm_page_bound`** (Swarm.g:68: `prepubOf(page.pub) === page.prepub`) — the SwarmSpoof tooth; gates
   hello :687, accept :743, and the `Swarm_seal` backstop :940. UNCHANGED (page semantics don't change).
- The **refuse/deny ladder** (:684-714): `forged` (now presig-regeneration fails), `not_ours` (presig
   mismatch), `spoofed` (page unbound), `unknown`/`spent` (ledger). No transport route / %Ud / reply before
    proof (the F3-flood defense) — PRESERVED.
- **SwarmSpoof re-expressed**: Mallory holds a real compact invite, crafts a `pier_hello` with
   `page={pub:Mallory, prepub:Victim}` → still `hello_spoofed`, invite stays UNSPENT, Victim hears nothing
    (Swarmation.g:1577,1581). Same asserts, new invite shape.

---

## 5. The Book re-record list (the regression surface — all to the compact form)

Seal Books (`Ghost/Story/Swarmation.g`): **SwarmStaple** (the model, :182 mutual-grant-both-ends moves to
 after frame 3), **SwarmWire** (:302), **SwarmSteal**, **SwarmInvite** (:440 the QR parse — the token shape
  changes most here), **SwarmDoor** (first-contact), **SwarmGot**, **SwarmPolicy** (ttl goes away — no
   `time`!), **SwarmShare**, **SwarmChain** (:1291 — chain keeps full sign, but shares the seal), **SwarmBlotter**
    (:1440), **SwarmSpoof** (RE-EXPRESS, :1577/1581). Plus `Radiation.g`: **MusuRaStream**/**MusuRaChase**/**MusuBuddy**;
     `Heistation.g`: **MusuHeist** (:551 mutual-grant-gates-heist). Each: reset toc dige→lie, rm snaps, run→red,
      re-declare asserts as needed, accept, rerun green×2. **SwarmPolicy needs rethinking** (its whole subject,
       the ttl door, is being removed).

---

## 6. Part A + legacy already exist (corrections to earlier claims)

- **`?Iz→?I=` rewrite EXISTS** — `InvitePanel.svelte:224-231`, fires on `Swarm_redeem` landing (PIN via
   `Clustation_pin` first). It deliberately swaps on REDEEM not SEAL (:218-223: gating on the 8s seal window
    "stranded ?Iz whenever the seal ran late"). A tab stuck on ?Iz means that `join()` path didn't complete
     the swap (pin falsy, or auto-join never fired + no click). NOTE: the human's "swap when the %Grant is
      sealed" is the behaviour they moved AWAY from — reconcile before changing it.
- **Legacy door mostly EXISTS** — `Swarm_legacy_of_url` (Swarm.g:262) parses old `#`-links; the `relic`
   preview (`InvitePanel.svelte:138-144`) shows the inviter + "can't verify here yet" (honest — the old
    key/ledger never migrated → §7a).

---

## 7. Adjacent BIG-DEAL threads (separate; the human flagged both 2026-07-27)

### 7a. Bring the old key/spend-ledger (the rung-2 migrator)
CORRECTION (survey 2026-07-27): the old garden's store is **Things over raw IndexedDB, NOT Dexie**
 (`ThingIsms`, `src/lib/data/Things.svelte.ts`; Swarm.g:251's "Dexie" is wrong). The ledger is DB
  **`Trust` v2**, all real state as JSON blobs in the **`gizmo`** store keyed
   `F=Trusting()/Thing:<Peering|Pier|Idzeug>=<name>` — identity keys raw-hex in `stashed.Id`,
    `stashed.main` the main marker, `taken_n[]` the spent serials, `Upper_Number` the issued
     high-water, `nRepeating` the infinite flag. "Bring it" = the migrator that lifts those into
      `%Idzeug` records + the identity roster, so an old `#`-link can actually redeem. **DROPPED
       (human 2026-07-27): no migration — the survey stays as reference only; the one old account
        gets copied by hand. See `Identity_persist_todo.md` §3 rung 5.**

### 7b. Identity per-Identity on `.jamsend` — RESOLVED + BUILT → `Identity_persist_todo.md`
This thread graduated to its own living doc (one-doc-per-topic). The open question ("is `.jamsend`
 peer-readable?") was ANSWERED — **owner-local, never Repli-readable** — so keys ride the account snap
  in the clear. Built + green×2 (`SwarmDisk`, 2026-07-27): `account/<prepub>/toc.snap` (keyed export)
   + pub-only `identities/toc.snap` roster; `Swarm_export`/`Swarm_import` dropped the `env.keys` sidecar.
    "Which is main" is a Thang concern (`?I=` selects). The one owed seam (Auto boot-seed wiring, proven
     by the two-tab test) has an exact recipe in `Identity_persist_todo.md` §5. See there for everything.

### 7c. Real-wire risks for the two-tab test (production audit, 2026-07-27)
The Books seal over the in-process mail-wire / `Lake_link` mock pair — the REAL relay path is unproven.
 Watch these during the two-tab fingers-test (none is a certain breaker; all are mock-invisible):
- **`pier_confirm` (frame 3) has no re-drive.** The inviter seals ONE-SIDED at `pier_hello`; the
   reciprocal only rides `pier_confirm`, a fire-once `Swarm_deliver`. A reconnect / era-change
    (`Peeroleum_reset_handshake`) mid-seal can drop it → the inviter's friend record permanently lacks
     the reciprocal grant (music still flows — each side serves off its own grant, presence self-heals
      via `swarm_hi`/pulse — but the SocialGraph/backup is asymmetric). FIX: on a vouched reconnect from
       a pier missing the reciprocal, re-drive the deferred confirm (or reconcile grants).
- **Two hard-coded timing guesses.** `join()` does `sleep(400)` "for the hello-bind to land" before
   redeeming; on a real relay the joiner's signed hello-bind may not be processed before the inviter
    routes `pier_accept` back → accept dropped → joiner sits at the 8s timeout. And `mint()` opens the
     QR unconditionally even when `Swarm_station_up` returned null (boot window) → a fast scan hits an
      unbound inviter. FIX: replace the fixed sleep with an explicit bind-ack round-trip; gate the QR on
       the station actually being bound (`stood`).
- **Unknown-serial is indistinguishable from inviter-slow.** By design `refuse('unknown')` sends NO
   reply (so a serial-scanner gets no confirmation the door exists). So a genuinely stale QR — or an
    inviter whose `Swarm_iz_rehydrate` didn't restore the ledger — shows the joiner the SAME "hello
     delivered but no accept yet" as a live seal-in-flight (the 2026-07-18 invisible-`hello_unknown`
      class). FIX: keep the no-reply for security, but add a positive "hello acknowledged" signal (or a
       definitive "invite not recognized" after the window) so a dead serial isn't reported as maybe-live.

---

## 8. Security coordination

This touches the SwarmSpoof-hardened seal. The plan keeps the anti-spoof property and PROVES it by a
 re-expressed SwarmSpoof (Mallory vs the compact invite) going green — that green is the gate. Leave a clean
  diff + the green SwarmSpoof for the security thread to sight. See [[swarm-seal-prepub-binding-hole]],
   [[protocol-back-signal-built]], [[reinvite-chain-built]], [[cluster-trust]].
