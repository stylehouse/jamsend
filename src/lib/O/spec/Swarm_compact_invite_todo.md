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

**NEXT (2026-08-06): §9 — the Invite as a standing two-sided req.** The compact seal shipped and then
 half-landed on the human's live tabs; §7c predicted exactly that and the built healer is blind to the
  half it hit. §9 is the half-design for the general cure (the human: *"remember the Invite until both
   parties have agreed they have fully processed it"*). **Rung 1 is shippable today and needs no wire.**

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
  **HAPPENED, 2026-08-06 — and the built cure is blind to the half it landed on.** Observed live on the
   human's two tabs: Lefto `96d0cf88` (issuer) held a MUTUAL %Pier, `grants:[f5da6599b850→Music,
    96d0cf885265→Music]`; Righto `f5da6599` (redeemer) held `grants:[96d0cf885265→Music]` — missing its
     **OWN** grant. That is the REDEEMER-side half-seal, the mirror of the issuer-side one
      `Swarm_reaccept_incomplete` (Swarm.g:707) was built for, and that healer cannot see it: its first
       test is `if (pier.o({Grant:1, by: theirPub})[0]) continue // already complete` — it asks *"do I
        hold THEIRS?"*, not *"is this pier WHOLE?"* — and Righto does hold theirs, so it is judged
         finished and skipped. Its stated invariant (Swarm.g:706, *"a redeemer's %Pier is born with BOTH
          grants, so only an issuer half-seal ever matches"*) is empirically FALSE. Even if the predicate
           were fixed, line 719 reuses `mineC` to heal — which is the very grant that's missing here.
  **The cheap half of the cure needs NO WIRE.** A redeemer's own grant is signed by its own key: Righto
   can re-mint it unilaterally, offline, any time. So the redeemer-side gap is *locally* curable — see
    §9's rung 1. (Scope note: the missing grant is the one governing Righto **serving** Lefto, so it is
     not what stalls a Righto-pulls-from-Lefto heist. It is a real hole; it was not that day's blocker.)
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

---

## 9. TODO / HALF-DESIGN — the Invite OUTLIVES its handshake (a standing two-sided req)

**Status: rungs 1–2 LANDED as a repair; rungs 3–5 (the actual enhancement) NOT BUILT — low priority,
 the human 2026-08-06.** Their own framing, and it is the right one: *"so this is a hack not an Invite
  process enhancement that won't quit the original task whatever it was until fulfilled?"* — **yes.**
   What shipped is a self-heal that fires at station standup and patches a pier that came out wrong.
    What is OWED is the standing req: an invite that does not FINISH until both ends confirm, so no
     repair pass is needed because the task never quit. Do not let the green tabs retire this section.

**What landed (2026-08-06, `Swarm.g` `Swarm_reaccept_incomplete`, verified live on both tabs going
 `⇄ MUTUAL`):** rung 2's wholeness predicate (holds BOTH grants — replacing the "do I hold theirs?"
  test whose stated invariant the live tabs disproved) and rung 1's local re-mint (a side missing its
   OWN grant re-signs it with its own key — no wire, no security surface). The one-way pier that had
    been standing for over a week healed on the next standup.

**Why that is still a hack.** It runs on a REDIAL, not on the invite. Nothing remembers that a seal was
 in progress, so: a pair that never redials stays broken; a fresh invite that half-lands is broken until
  something unrelated bounces the socket; and the glass can only report the damage after the fact, never
   *"still sealing, 1 of 2"*. The repair also cannot know what the invite MEANT — rung 1 guesses the
    Feature from the other side's grant and falls back to `'Music'`, which is right today only because
     Music is the only Feature. A second Feature makes that guess wrong, silently.

The human 2026-08-06, on being shown the one-way pairing: *"we should remember the Invite until both
 parties have agreed they have fully processed it? so we can keep giving all the Grants until done"* —
  and, on scope: *"it's kind of leaving infrastructure for more complicated apps and possibilities to
   reuse, but not too much that we get confused."* So: build the **shape**, not a negotiation language.

### 9.0 The diagnosis in one line

Today an invite is a **moment** — three fire-once frames, then nothing remembers it happened. Every
 repair we've written since (`Swarm_reaccept_incomplete`, the swarm_hi epoch re-drive) is a bespoke
  patch bolted to a specific frame going missing, each with its own predicate, each blind to the half it
   wasn't written for (§7c). The general cure is to make the invite a **req** — a thing that is
    *unfinished* until it is done, and that the machine therefore keeps working on for free. Cf
     [[req-is-where-state-belongs]]: *prefer a req over a status string; it carries its own liveness.*

### 9.1 The lesson from the old garden — slowness is FINE, muteness is not

The human: *"see the old `Tyranny.svelte` for how slow the Invite|Idzeug process can be."* Read it
 (`src/lib/ghost/Tyranny.svelte`, `Idzeuganise` :442). The old handshake was **world particles worked
  continuously**, not frames fired once:

- `%Idzeugnation` (we are the invitee) and `%Idzeugnosis` (we are the doorman) — one particle per
   in-flight invite, both living in `w`, both re-entered every pass of `Idzeuganise()` until `sc.finished`.
- Blocking is **named and narrated**, not silent: `I.i({waits:"Our"})` parks a reason, and the loop
   pushes each `waits:` to the UI (`UIsay`) — *"they're standing at the gate getting a stream of mediocre
    noises"* (:464). A handshake that takes thirty seconds is fine as long as it says what it's waiting on.
- Failure is **counted, not thrown**: `not_dead` gives three strikes then drops the particle;
   `dont_get_stuck_waiting_for_k` counts `stuckat_<k>` and at the threshold says *"you may need to reload"*.
- A finished one **lingers so it can be seen**: `if (I.i_wasLast("finished") > 22) I.sc.dead = 1` (:512).

The compact 3-frame seal is strictly faster and strictly **muter**. When it half-lands, nothing anywhere
 says so — which is exactly why §7c sat in a doc for ten days while the tabs were quietly one-way. Restore
  the narration; keep the speed when the wire is good.

### 9.2 The design (settled with the human 2026-08-06 — build this)

**One `req:Seal` on the redeemer's `%Pier`, driven only while the peer is online, holding the list of
 what is still missing, finished when the peer's `seal_confirm` says they are whole too.** That is the
  whole machine. Each clause was a decision; the reasoning is inline so nobody re-opens it by accident.

**Where — on the `%Pier`, redeemer-side only.**
> *"this should be obviously in… Pier, the persisted Pier… that's our relationship to one other peer.
>  so our pending Invites hang there, only on the redeemer side I guess… it keeps trying, can be part
>   of the way through and skip early steps (ie the first Grant)"*

The `%Pier` IS the relationship; a pending invite is a fact about that relationship, so it hangs there
 and persists with it — no new home to invent, nothing to garbage-collect separately. (Two earlier
  candidates are rejected: a particle under the `%Peering`, and folding into the issuer's `%Idzeug`
   ledger row.) The issuer keeps no req at all: once it has answered `pier_accept`, everything
    outstanding is the redeemer's to drive. That asymmetry is the point — only one side needs state.

**Born the moment the invite is KNOWN — at `?Iz=` parse, not at `pier_accept`** (the human, same day:
 *"it persists once the Invite is known about (got from a URL) once right?"*). This matters: if the req
  only appeared at frame 2, a `pier_hello` that never got answered would leave nothing behind at all —
   the exact silent hole §7c's third bullet describes, where a dead serial and a live seal-in-flight look
    identical. So the redeem path mints a **grantless `%Pier` shell** keyed by the token's `prepub` and
     hangs the req on it immediately.
 That key is available: the compact token carries `prepub` (§1), and `prepub` is precisely what
  `Swarm_seal` keys `%Pier` by — so the shell and the sealed Pier are the same particle, and
   `pier_accept` fills it in rather than replacing it.
 **Security is unchanged, and deliberately so.** A grantless `%Pier` is not a capability — `Swarm_pier_live`
  requires grants, so the shell authorises nothing. The peer's `page` is NOT stored at parse time (we hold
   only a 16-hex prepub, never their full pub), so `Swarm_page_bound` still runs for the first time at
    `pier_accept` exactly as today: the SwarmSpoof tooth bites in the same place. And minting the shell is
     user-initiated (you opened the link), never remote-triggered. The shell must be visibly distinct from
      a sealed friend wherever Piers are listed — it is a pending invite, not a contact.

**When — presence-gated, and that is the whole throttle.**
> *"they should only appear when that Pier is online right? so then they'd resolve quite promptly I
>  think? sheesh, how much more robust do we need to be..."*

Drive the seal **only while the peer is online**, reusing the `heard_at` gate `Swarm_share_beat` already
 applies before re-offering stock. No clock, no backoff ladder, no three-strikes, no TTL, no dismissal
  UI — and nothing to retire, because an unfinished req against an offline peer simply *is not driven*.
   The moment they appear it resolves in a round trip. This is what keeps §1's no-expiry stance intact:
    no timer ever touches an invite. It is also why this design is smaller than the old garden's.

**What — a list of what is still MISSING, not a script.** `%Want,of:<kind>` children, each naming
 something this side must come to hold. Landed steps leave the list and are never re-driven; only the
  outstanding ones go again. That is the "can be part of the way through and skip early steps" clause,
   and it is what makes the req *resumable* rather than a restart. Today the only kind is `of:Grant`;
    the list is the extension point where a later app adds `of:profile` / `of:receipt` / `of:challenge`
     without touching the seal spine. **Do not invent the other kinds now** — one kind, and a list shaped
      to hold more.

**Whole — one predicate, `Swarm_pier_whole(pier, me, theirs)`:** holds `Grant by:me` AND `Grant by:theirs`.
 Both half-seals fall out of it, and it retires the bespoke predicate that was blind to one of them (§7c).
  Already built (rung 2).

**Done — an explicit `seal_confirm` frame**, carrying the grant set the sender holds:

    finished  ⟺  self_whole  ∧  their seal_confirm says they are whole

A side never stops on its own say-so — that is precisely today's failure mode, where each end believes
 itself finished and the pair is silently one-way. The explicit frame costs a kind and a round trip and
  buys a wire event that is legible in a Book and assertable as a `%see:` claim; a digest piggybacked on
   `pulse`/`swarm_hi` would have been free but untestable, and was rejected for that.

**Re-driving needs no new frame kinds beyond that one.** The existing three are already idempotent
 (`Swarm_seal` dedups grants; `Swarm_confirmed` is documented idempotent), so the req's ordinary tick
  re-sends them safely: missing THEIRS → re-send `pier_confirm`; missing MY OWN → **no frame at all**,
   re-mint locally (rung 1, already built).

### 9.3 What is still owed (rungs 1–2 shipped; these are the enhancement)

3. **`req:Seal` on the `%Pier`** — lift the healing out of the redial path into a standing, persisted req
    with `%Want` children, presence-gated, resumable. This is the rung that makes the invite *not quit
     until fulfilled*, and it retires `Swarm_reaccept_incomplete` as a special case.
4. **The `seal_confirm` frame** → mutual `finished`. New kind; wire into dispatch beside `pier_confirm`.
5. **Narration** — `waits:`-style reasons on the req, surfaced through `Diag_trouble`, which DiagFace
    already renders. *"sealing with Lefto — 1 of 2 grants"* is exactly its register: the thing the old
     garden had (§9.1) and the compact seal lost.
6. **Move the `?Iz=` drop from redeem to FINISH** — and only now, because rung 3 is what makes it safe.
    The human asked for this originally, and §6 records that we moved AWAY from it: `InvitePanel.svelte`
     :270-276 drops the token the moment the redeem lands, because gating on the 8s seal window
      *"stranded `?Iz` whenever the seal ran late, and a reload then re-presented a dead blob"*. That
       objection was sound while the **URL was the only record of the invite**. Once the req persists on
        the `%Pier` (rung 3), the URL stops being the record, a late seal strands nothing, and a reload
         resumes from the req instead of re-presenting a blob — so the swap can wait for `finished`,
          which is what the human wanted in the first place: *"remove it from the browser location if
           it's in there when it finishes"*. **Order matters: do NOT do this before rung 3** — on its own
            it reinstates the exact stranding §6 warns about. The `?I=<prepub>` pin-gating stays as-is.

**Still genuinely open** (small, decide in the code): whether the `%Want` list needs ORDER for a future
 second kind. Unordered is enough for grants — leave it unordered until something demands otherwise.

### 9.4 Non-goals (the "not so much that we get confused" line)

No Tyrant / third-party officiation (§6 already ruled that out — it ran ~90% red). No capability
 *negotiation* language — the `%Want` list is declarative, each side states what it must hold, and there
  is no bargaining. No expiry, and no backoff ladder either — presence is the throttle (§9.2). No new
   frame kinds except `seal_confirm`. And nothing here weakens §4's invariants: re-drives reuse
    already-signed atoms, `Swarm_page_bound` still gates every entry, and a re-expressed **SwarmSpoof
     staying green is the gate** on any of it (§8).
