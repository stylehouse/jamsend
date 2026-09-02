# Ceremony_layering_todo.md

**Is the device-link ceremony machinery mis-designed — and specifically, why did a ceremony
 (pier_hello) concern force patches into the reliable TRANSPORT layer (Peeroleum)?** An
  architecture reckoning (analysis only; no code changed), triggered by the live "stuck at
   receiving from eed" wedge and the chain of ever-deeper fixes it required.

---

## 0. WHAT TO GET ON WITH NEXT

The reckoning below argues **the owner's instinct is right in spirit but half-wrong on the
 remedy**, and that the fragilities are mostly ONE model error, not many. If you are picking
  this up, the ranked moves are:

1. **DON'T rip pier_hello out of the reliable stream wholesale.** (§1, §2, §4-A.) The knock
    is genuinely reliable app-data on FIRST contact — it already rides the **pier-less lane**
     (`!pier` branch), which IS the "stateless knock" the owner wants. The wedge was NOT that
      the knock is reliable; it was that a **STALE %Pier existed for a peer that never sealed**,
       so the knock stopped taking the pier-less lane and fell into the booked path. Fix the
        stale pier, not the reliability class.
2. **The clean invariant to adopt (§1):** *a pier_hello is ALWAYS handled pre-relationship —
    it must never consult per-pier seq/inbox/dedup state, whether or not a %Pier happens to
     exist for its `from`.* Today that's true only when `!pier`; the reborn-knock patch is the
      code paying for the times it's false. Make it true unconditionally (§4-A move 1) and the
       collision-branch special-case becomes deletable.
3. **The reborn-knock patch (§2) is a WORKAROUND at the right layer for the wrong reason.** It
    lives in Peeroleum's collision branch — correct file, because that's where the stale-pier
     mis-route lands — but it is a second copy of the first-contact lane bolted onto the dedup
      path. The replacement is move-2 above: route pier_hello to the pier-less handler BEFORE
       the pier lookup can capture it, deleting the collision-branch clause.
4. **The live silent stall (§3, the trigger's step 3) is almost certainly the SOUL-SHIP GATE,
    not the transport.** The giver's `pier_accept` in the mint-stop branch is sent
     unconditionally (Swarm.g ~2224), so "no pier_accept at all" points at either (a) the
      `!ident` / crew-claim self-drop in the `hear` funnel eating the giver's own knock, or (b)
       an exception between verify and seal now surfaced by the parent's `🦑 hello VERIFIED`
        breadcrumb + try/catch. Read the next reload's log for that breadcrumb FIRST; it
         disambiguates transport-vs-ceremony in one line. (§3 lists the four candidate bails.)
5. **The one-model fix (§3):** name it — *the ceremony treats a %Pier as BOTH the reliable
    transport channel AND the ceremony's own state store.* Split them: the chrysalis (link
     state) is a **ceremony req** (already is: `Swarm_ferry_role`), the %Pier is a **dial
      handle**. A knock should never depend on a %Pier existing; the ceremony should never
       depend on the %Pier's stream state. See §4 for the incremental vs clean split.

Open rulings the human owes are in §5. The safe-incremental set (§4, "SAFE") can land now; the
 clean redesign (§4, "CLEAN") wants the §5 rulings first.

---

## 1. VERDICT ON THE OWNER'S INSTINCT

**The owner's instinct — "pier_hello is a pre-relationship, application-layer knock carrying
 its own credential; the transport should be oblivious to it; Peeroleum needing a pier_hello
  special-case at all smells like wrong layering" — is CORRECT as a diagnosis of the SMELL, and
   the code already half-agrees with it. But the remedy "make ALL pier_hello bypass
    seq/inbox/dedup unconditionally, like pulse/swarm_hi" is right in aim and wrong in
     mechanism.** Here is the precise picture.

**What pier_hello already is, in the code.** Peeroleum has TWO dispatch lanes:
 - the **pier-less lane** (`Peeroleum_deliver_do`, the `if (!pier && h.type === 'pier_hello')`
    branch, Peeroleum.g ~626): dispatch handler-direct, NO inbox booking, NO seq check, ack via
     a re-routed frame. This is EXACTLY the owner's "handle it statelessly at the transport
      boundary." The comment even says so: *"The Pier/Ud booking discipline can't apply to a
       caller we haven't met, and doesn't need to: the Idzeug echoed inside is its own
        credential."*
 - the **booked lane** (the rest of `Peeroleum_deliver_do`): a %Pier exists, so the frame
    books a `%req:unemit` under the pier inbox, runs through the seq/dedup guard, and drains via
     `req_unemit` (with its pre-Ud gate).

**So pier_hello does not go through the transport machinery — UNLESS a %Pier already exists for
 its `from`.** That "unless" is the entire bug. The reliability POLICY (Peeroleum.g ~455)
  classifies pier_hello as RELIABLE ("door-opening handshake") — but that classification is a
   SEND-side property (does the sender book an outbox emit + retransmit?), and it is correct:
    the first knock must survive a lost beat or the ceremony never starts. The owner's "like
     pulse/swarm_hi (ephemeral)" conflates two different axes:
 - **send reliability** (retransmit-until-acked): pier_hello SHOULD stay reliable. It is not
    self-re-asking gossip; a dropped first knock has nothing behind it to heal it (the Cave
     re-hellos on reload, but that's a coarse human-timescale retry, not a 4s pull). Making it
      ephemeral would reintroduce "the knock silently lost" — the exact class the reliability
       policy comment warns about.
 - **receive-side statefulness** (does it consult per-pier seq/inbox/dedup?): pier_hello should
    be **STATELESS on receive, ALWAYS**. This is the owner's real point, and it is right.

**THE CLEAN INVARIANT.** *A pier_hello is dispatched pre-relationship: on receive it is routed
 to the first-contact handler WITHOUT consulting any per-pier seq, inbox, or dedup state,
  whether or not a %Pier exists for its `from`. Its own credential (the ?Iz presig + serial
   ledger, re-verified by `Swarm_hello` every time) is the only gate; a replayed/spent knock is
    refused by that verification (`deny('spent')`), not by transport dedup.* On SEND it stays
     reliable (outbox emit + retransmit), because a first knock has no application-layer re-ask
      behind it.

**WHERE THE "THIS IS A KNOCK, HANDLE IT STATELESSLY" DECISION BELONGS.** At the top of
 `Peeroleum_deliver_do`, BY FRAME TYPE, before the `Peeroleum_route` pier lookup — exactly
  where `runner_ask`/`ghost_confile` are already dispatched by type (Peeroleum.g ~617). Today
   the type-check for pier_hello is entangled with the pier lookup (`if (!pier && type ===
    'pier_hello')`), which is what lets a stale pier steal it. Hoisting the pier_hello (and, see
     §4/§5, arguably pier_accept/pier_confirm) type-dispatch ABOVE the pier lookup makes the
      invariant structural: the transport is oblivious to the knock by construction, and a
       lingering %Pier can no longer change the knock's fate.

**Is a lingering %Pier for an unsealed peer a legitimate concept?** Partly. A %Pier that has
 sealed (has a %Ud, has grants/stamp) is legitimate durable state. A %Pier that exists for a
  peer that NEVER completed a handshake — a "stale knock pier" rehydrated with inbox history but
   no %Ud — is an ILLEGITIMATE half-object: it has enough state to capture the booked lane but
    not enough (%Ud) to pass `req_unemit`'s pre-Ud gate, so anything it captures dies silently.
     That specific object is the disease. Under the clean invariant the knock never consults it,
      so its legitimacy stops mattering for the knock; but §5 asks the human whether such a pier
       should be GARBAGE-COLLECTED rather than merely bypassed.

---

## 2. THE REBORN-KNOCK PATCH: RIGHT FIX OR WORKAROUND?

**It is a WORKAROUND at the correct FILE for a structural gap — a second, hand-copied instance
 of the first-contact lane, grafted onto the dedup path to catch the case the first-contact
  branch structurally misses.** Not wrong, not a layering violation in the "put ceremony logic
   in transport" sense (the branch contains no ceremony knowledge — it re-dispatches to the
    registered handler, same as first-contact), but it is a symptom that the first-contact lane
     is guarded by the wrong predicate.

Read the two patches the parent made in sequence:
 - **Patch v1** (collision branch: reset the stream + re-book through the pier inbox) — DIED in
    `req_unemit`'s pre-Ud gate (Peeroleum.g ~1108: `ok = !(pre_ud && type !== 'hello' &&
     'noop')`). A booked pier_hello on a %Ud-less pier is refused `pre-Ud`, silently (the
      pre-Ud branch is one of the two reasons deliberately kept quiet, ~1186). So v1 moved the
       swallow from the dedup guard to the pre-Ud gate — same silence, one layer deeper.
 - **Patch v2** (collision branch: `Peeroleum_reset_handshake(pier)` + dispatch handler-direct
    `w.c.on['pier_hello'](w, null, frame)`, no inbox booking, re-ack via re-route) — this is
     LITERALLY the first-contact branch (~626), duplicated inside the collision branch (~814).
      It works because it stops treating the knock as booked traffic.

**The tell that this is a workaround:** the collision branch now has to re-derive everything the
 first-contact branch already knows (reset the dead stream, reset `hiseq`, dispatch pier-less,
  re-ack), plus a try/catch the first-contact branch lacks. Two copies of one idea, kept in
   sync by hand, is the classic "the abstraction boundary is in the wrong place" signature.

**THE REPLACEMENT (clean):** make first-contact dispatch fire on TYPE, not on `!pier`.

    // at the top of Peeroleum_deliver_do, beside the runner_ask/ghost_compile type-dispatch,
    // BEFORE Peeroleum_route:
    if (h.type === 'pier_hello') { <the current first-contact body> ; return }

Then a %Pier existing for the knocker's `from` is irrelevant — the knock never reaches the
 pier lookup, never books, never hits the dedup guard, never hits the collision branch. The
  collision-branch pier_hello clause (~814-829) **deletes entirely**, and so does the
   `Peeroleum_reset_handshake`-from-collision path for this type. `reset_handshake` stays for
    its OTHER job (the era-borne reset for sealed friends). The loud try/catch the parent added
     migrates onto the single first-contact call site (worth keeping — see §3).

Risk of the replacement: LOW-MEDIUM. The change is "route one type earlier," and the existing
 first-contact branch already proves the pier-less lane is sound for pier_hello. The one thing
  to preserve: a pier_hello that arrives for an ALREADY-SEALED pier (a genuine re-hello from a
   friend we already hold) must still be fine dispatched pier-less — it is, because `Swarm_hello`
    re-verifies and `Swarm_seal` is idempotent. Verify by re-running SwarmDoor/SwarmWire/
     SwarmChain/InvFerry (the parent's gate) plus a live reborn-knock over two tabs.

---

## 3. THE ONE-MODEL VIEW: are the fragilities independent, or one design error?

**They are mostly ONE error, wearing five faces. Name it:**

> **THE %PIER IS OVERLOADED: it is simultaneously (a) the reliable TRANSPORT channel to a peer,
>  (b) the CEREMONY's live state store, and (c) the MEMBERSHIP/relationship record. A device
>   link is a PRE-relationship event, so at knock time NONE of (a/b/c) legitimately exists yet —
>    but the machinery keeps reaching for a %Pier as if one did, and half-built or stale %Piers
>     then capture, gate, and silently drop the ceremony.**

The owner's own Pier/Peering law (Division §0 ⚑⚑⚑, "SIMILAR AUTISTICS") already isolates the
 sub-conflations — dial/listen, identity/address — but the ceremony fragility is a THIRD
  conflation on the same object: **channel vs ceremony-state vs relationship.** The Division doc
   even sketched the cure ("a live link rail" should become "an unfinished ceremony req whose
    serial matches" — §0 purge point 1). The ceremony-req half of that HAS landed
     (`Swarm_ferry_role` is the state store), but the %Pier is still load-bearing for the
      ceremony's transport AND liveness, so the split is incomplete.

Now the five faces, each traced to the one error:

**(i) The reborn-knock wedge (the trigger).** A stale %Pier (face-a/c leftover) captured a
 knock that should have taken the pre-relationship lane. Pure channel-vs-pre-relationship
  confusion. → §1/§2.

**(ii) Reload fragility (secret/offer lost, both tabs miss each other, linkee hangs forever).**
 The ceremony state lives in `Swarm_ferry_role` reqs + `top.stashed.ferry` (the twin) — that's
  the RIGHT home. But the ceremony's PROGRESS depends on the %Pier's transport state surviving
   reload identically: `Swarm_ferry_on_seal` returns immediately unless
    `Swarm_pier_linklive(pier)` (Swarm.g ~5927), and a reloaded Cave pier "is not a sealed
     friendship, so `Swarm_station_routes` never re-stamps its %Ud" (Peeroleum.g ~744) — the
      whole reason ferry_want had to be dragged out of the booked lane. So a reload can leave
       the ceremony-req ALIVE (rehealed from the twin) while the %Pier it needs is a cold husk.
        The linkee's "receiving… waiting to confirm" hang is the ceremony-req waiting on a %Pier
         seam that will never fire because the pier never re-warmed. Same error: ceremony
          progress bound to transport-object liveness.

**(iii) The address split (redeemer knocks at SOUL eed831f1…; giver runs as BODY 5ade3510…).**
 This one is actually COHERENT and is NOT a bug — but it's worth stating why, because it looks
  like one. The giver tab holds the soul DOOR (bound at the soul name on the relay), so a frame
   `to:<soul>` arrives; `Swarm_account_of` resolves `to:<soul>` to the live self because the
    body carries the soul key (Swarm.g ~892). The reply `pier_accept` goes `from:<soul>`
     (Swarm_deliver ~957 sends `from: ident.sc.prepub` = the soul prepub), which the redeemer
      routes correctly. The door-holder model is sound FOR THE KNOCK. The brittleness the owner
       senses is real but lives ELSEWHERE: it is that the DOOR (who is bound at the soul name)
        is live transport state with no ledger record, so "which tab answers for the soul" is a
         race under reload (Division §C/§E, the seat apparatus). For the ceremony specifically,
          the address split is fine; don't spend redesign budget here.

**(iv) Silent bails (fail-null-with-no-rebuff-no-trace).** ENDEMIC, and it is the SECOND
 independent problem — a legibility failure orthogonal to the %Pier overload, though the
  overload creates most of the sites. The catalogue, each a place a refusal vanishes:
 - `hear`'s `if (!ident) return false` (Swarm.g ~976) — a frame to a `to` we can't resolve
    dies mute. On the giver, if the knock's `to` fails to resolve (e.g. addressing skew), the
     ceremony dies here with nothing.
 - the crew-claim self-drop (Swarm.g ~1004/1008: `return false`) — a frame that looks like our
    own body/soul is dropped; correct policy, but silent, and a mis-classified knock could be
     eaten here.
 - `Swarm_seal` returning null on an unbound page (Swarm.g ~2526) — then the mint-stop branch
    does `pier.sc.link = 1` on a null (Swarm.g ~2210) → a **throw**, which (pre-parent-patch)
     was swallowed. This is a live candidate for the trigger's step-3 stall.
 - `Swarm_ferry_on_seal`'s `if (!secret) return` / `if (!pwarm) … return` (Swarm.g ~5932/5957)
    — the ferry seam no-ops when there's no live offer or the pier is cold. The cold-pier one
     now logs (parent added it); the no-secret one is quiet.
 - `Swarm_deliver` returning false on `!ready` / `!route` / voucher-window (Swarm.g ~927/961)
    — a pier_accept that can't be delivered returns false and the mint-stop branch IGNORES the
       return (Swarm.g ~2224 doesn't check it, unlike the friend path ~1842 which `owed_note`s
        on false). So a giver can "send" pier_accept into a dropped transport and never know.
 **The invariant that would make every refusal legible:** *every ceremony bail either seals, or
  records a `%rebuff` (local, traced) OR sends a `pier_reject`/`ferry_cancel` (remote, so the
   counterparty folds) — there is no third exit.* `Swarm_rebuff` already exists and is traced;
    the fix is to route the mute `return null/false` sites through it (or through a new
     `Swarm_ferry_bail(why)` that both rebuffs locally and, when a return address is known,
      tells the far side). The parent's `🦑 hello VERIFIED` breadcrumb + try/catch is the FIRST
       instance of this being done right; generalise it.

**(v) The soul-ship gate (giver always sends pier_accept but ships the soul only if
 `Swarm_ferry_secret()` is set).** This is a REAL design bug and the most dangerous one for the
  live symptom "linkee hangs forever." The mint-stop branch (Swarm.g ~2208-2225): it ALWAYS
   sends `pier_accept`, then re-fires `Swarm_ferry_on_seal` ONLY `if (… Swarm_ferry_secret() …)`.
    So a giver with no live offer (post-reload, secret lost from `.c` AND twin, or the offer was
     never minted on this tab) will ACCEPT the knock — the linkee seals its chrysalis and moves
      to "receiving…" — but NEVER ship the soul, because there's no secret. The linkee waits
       forever with no rebuff. **The soul-ship is gated correctly (you can't ship a soul you
        have no secret to seal it with), but the ACCEPT is gated WRONGLY: it should not accept a
         device link it cannot fulfil.** The clean rule: *pier_accept for a My<Post> link is
          only legitimate when a live offer (secret) backs it; absent the secret, send
           `pier_reject('no_offer')` (or a ferry_cancel) so the linkee folds to "the other
            device has no link in progress — mint a fresh one," instead of hanging.* This is
             face-(iv) again (a silent success that is really a failure) plus a genuine gating
              inversion.

**Summary:** (i), (ii), (v) are the SAME error (%Pier / ceremony-state / channel overload +
 accept-without-offer). (iii) is a non-bug (coherent). (iv) is a SEPARATE, endemic legibility
  failure that the overload amplifies. So: **two design errors, not five bugs** — the Pier
   overload, and the silent-bail culture.

---

## 4. PRIORITISED RECOMMENDATION

Distinguishing **SAFE incremental** (land now, small blast radius) from **CLEAN redesign**
 (wants the §5 rulings). Ordered by value/risk.

**SAFE-1 — Make the accept-without-offer bail loud AND correct (fixes face-v, the "hang
 forever").** In the mint-stop branch (Swarm.g ~2208), gate the `pier_accept` send on the same
  secret the soul-ship needs: no live offer → `pier_reject('no_offer')` + `Swarm_rebuff`,
   never a bare accept. Blast radius: SMALL (one branch, ceremony-only; friendships untouched).
    Biggest single win for the live symptom. Verify: InvFerry/InvWalk/InvSeal green + a live
     reload-then-knock where the giver has no offer must show the linkee FOLDING, not hanging.

**SAFE-2 — Route every ceremony `return null/false` through `Swarm_rebuff` (or a new
 `Swarm_ferry_bail`) (fixes face-iv).** The `!ident`, crew-claim, `Swarm_seal`-null, and
  ignored-`Swarm_deliver`-false sites each get a traced rebuff and, where a return address
   exists, a reject/cancel. Blast radius: SMALL-MEDIUM (touches several sites but each is
    additive — a log/rebuff where there was silence). This is the invariant from §3(iv). Keep
     the parent's `🦑 hello VERIFIED` breadcrumb; it is the template.

**SAFE-3 — Guard the `Swarm_seal` null → `pier.sc.link=1` throw (Swarm.g ~2209-2212).** Check
 `pier` before stamping; a null seal is a bail, not a crash. Blast radius: TINY. Likely the
  actual trigger step-3 stall (a swallowed throw between verify and seal) — the parent's
   try/catch will confirm on next reload.

**SAFE-4 — Confirm/keep the reload-durability of the ferry twin is doing its job, and make the
 cold-Cave-pier re-warm observable (fixes face-ii's diagnosis, not yet the cure).** The
  `Swarm_ferry_on_seal` cold-pier log exists; add the symmetric "ceremony req alive but its
   pier never re-warmed after reload" heartbeat so face-(ii) stops being invisible. Blast
    radius: TINY (logging). The real cure is CLEAN-2.

**CLEAN-1 — Hoist pier_hello (pre-relationship) dispatch above the pier lookup; delete the
 collision-branch clause (fixes faces i, and structurally retires §2's workaround).** §2's
  replacement. Blast radius: MEDIUM (reorders the deliver funnel's top). Wants §5 ruling on
   whether pier_accept/pier_confirm join it (they carry `to:<soul>` and CAN find a pier — but
    on the redeemer side the ceremony pier may be a cold husk too; see §5). Gate: the full
     Swarm*/Inv* suite + live two-tab reborn knock, re-run several times (the Coding_guide race
      rule — a layering change to the deliver funnel is exactly where a race hides).

**CLEAN-2 — Sever ceremony PROGRESS from %Pier transport liveness (fixes face-ii properly).**
 The ceremony seam (`Swarm_ferry_on_seal`) should fire off the CEREMONY REQ reaching its
  sealed phase, not off `Swarm_pier_linklive(pier)`. A reloaded ceremony that rehealed its req
   from the twin should be able to re-drive the soul-ship without waiting for the %Pier's %Ud to
    re-stamp — the pier is just the DIAL HANDLE; if it's cold, re-warm it (re-hello) as a
     transport concern, don't stall the ceremony on it. This is the Division doc's own "a live
      link rail becomes an unfinished ceremony req whose serial matches." Blast radius: LARGE
       (touches the seam, the retry pump, and the linklive gate). This is the real redesign;
        do it last, after SAFE-1..4 have stopped the bleeding, and only with §5 ruling 3.

**WHAT NOT TO CHANGE:**
 - **Don't make pier_hello ephemeral on SEND.** (§1.) It would reintroduce silent first-knock
    loss. Reliable-send + stateless-receive is the correct pair.
 - **Don't touch the address/door model for the ceremony's sake.** (§3-iii.) The soul-door knock
    is coherent; the door-race is a separate Division concern (§C/§E), not a ceremony bug.
 - **Don't touch the friendship (grant) handshake.** Every fix above is scoped to the My<Post>
    link branch; the full grant handshake is the tested, working path and must stay inert
     (SwarmStaple/SwarmSpread isolation swears).
 - **Don't delete `Peeroleum_reset_handshake`** — it keeps its era-borne-reset job for sealed
    friends after CLEAN-1 removes its pier_hello caller.

---

## 5. OPEN QUESTIONS FOR THE HUMAN (do not decide unilaterally)

1. **Do pier_accept and pier_confirm join pier_hello on the unconditional pre-relationship
    lane, or only pier_hello?** pier_hello is unambiguously pre-relationship. pier_accept/
     pier_confirm arrive when a chrysalis pier may already exist (the ceremony sealed one) — so
      they legitimately CAN want the pier. But on a RELOADED redeemer that pier can be a cold
       husk, which is face-(ii). Ruling needed: are accept/confirm "still pre-relationship until
        the ceremony completes" (→ pre-relationship lane, keyed by the ceremony req + serial,
         not the pier) or "post-seal reliable traffic" (→ booked, but then face-ii must be
          cured by CLEAN-2 first)? The recommendation leans **pre-relationship-until-complete**,
           consistent with "a Link is not a friendship," but it's the human's model call.

2. **Should a stale/half-built %Pier (inbox history, no %Ud, never sealed) be GARBAGE-COLLECTED
    at standup, not merely bypassed?** Bypassing (CLEAN-1) makes it harmless for the knock, but
     the husk still sits in the ledger confusing liveness reads. GC-ing it is cleaner but risks
      dropping a pier that's legitimately mid-handshake. Related to the Division "husk pier"
       rulings — may already be covered there; the human should say whether ceremony-husk GC is
        in-scope here or belongs to the Division purge.

3. **CLEAN-2 (sever ceremony progress from pier liveness): is the ferry seam allowed to
    RE-HELLO a cold Cave pier to re-warm it, or must it wait for the Cave to re-hello?** This is
     a "who drives recovery" question — the giver actively re-warming vs waiting — with a
      re-consent/security flavour (the giver re-initiating touch after a reload). The owner's
       "the ceremony should couldn't-not-work" instinct suggests active re-warm, but re-touching
        a device mid-ferry brushes the consent posture (ferry-cave-model: consent is
         per-ceremony). Human ruling needed before CLEAN-2.

4. **Is "the giver refuses a link it cannot fulfil" (SAFE-1) the right consent posture, or
    should a post-reload giver instead AUTO-REMINT the offer** (resume the ceremony from the
     twin) so the human doesn't have to re-press Link? The twin carries the serial; a reheal
      could in principle re-arm the secret too — but the secret is random per mint and is NOT in
       the twin by design after some phases (Swarm_ferry_stash keeps it only for minted/
        confirming/sent/held). So auto-remint may need a fresh secret = a fresh serial = a fresh
         QR, which the linkee can't know about. Likely SAFE-1 (refuse cleanly) is right and
          auto-resume is a bigger feature; confirm.
