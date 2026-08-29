# Network procedures — how to build a multi-party feature on jamsend

A **builder-facing recipe.** The platform's whole proposition is that distributed, multi-party
 apps are buildable to a *repeatable recipe* — but until now there was none. We just spent DAYS
  hand-building exactly ONE such feature (the **LinkDevice / "ferry" device-link ceremony**,
   `Ghost/S/Swarm.g` `Swarm_ferry_*`), and every day of that pain taught a rule that was NOT
    obvious up front. This doc extracts those rules so the NEXT network procedure — a group
     playlist vote, a co-listen session, a shared-queue handoff, a trust-delegation, whatever —
      is designed right the FIRST time instead of re-learned bug-by-bug.

It is a **working `_todo`**, deliberately NOT self-promoted to `_spec` — the owner reads + preens
 before that. If it earns it, it becomes `Network_procedures_spec.md`.

Its neighbours: `Swarm_spec.md` (the pier/seal/grant machinery), `Peeroleum_spec.md` (the reliable
 receive layer), `Focus_todo.md` (the ferry root-cause writeups this is distilled from),
  `Networky_directions_todo.md` (the data-plane/control-plane separation — the transport's own
   arc), `Presence_todo.md` (the five freshness windows), `Error_channel_todo.md` (observable
    failure). `Division_todo.md` and `Pier_todo.md` are where the *identity* rules bite.

---

## 0. What to get on with next

This doc is **complete as a recipe** — the immediate "next" is to USE it: the moment someone
 starts a new multi-party feature, walk Phases 1–9 below in order before writing a frame, and add
  the feature's own worked lessons back here as an appendix (like the ferry section). Vaguer
   candidates, for when there's slack:

- **Extract a `net_procedure` scaffold.** Every rule below is currently re-hand-written per
   feature. A helper module (mint-link, park, want-beacon throttle, warmth gate, durable twin,
    surface bump, observable-block log) would turn the recipe into an API. Ferry is the reference
     implementation to lift from — do NOT abstract before a SECOND procedure exists to abstract
      *across* (two points define the line; one is a guess).
- **A `pier_kind` classifier** (`Pier_todo.md`): friend vs your-own-body vs future Posts. Several
   rules below (warmth, grant-vs-presence) are really "what KIND of pier is this" questions.
- **Fold the epoch into a per-connection session nonce** (`Networky_directions_todo.md` Front D):
   the seq/rebirth scar tissue that half the reload-resilience rules below dance around.

**The arc — where this is going.** Today a network feature is a heroic one-off. The destination is
 that a builder reads this page, names their parties and frames, picks lanes and lifetimes off the
  tables here, writes the live-runner Book FIRST, and lands a correct multi-party ceremony without
   re-discovering the seal-seam or the stale-corpse bug. The ferry cost days precisely because none
    of this was written down; the win is that the SECOND feature costs hours.

---

## The shape of every multi-party procedure

Before the rules: the mental model they all serve. A multi-party procedure is **two (or more)
 devices converging on a shared fact through frames over piers, where either side may reload at
  any instant and the relay is untrusted.** That one sentence generates every rule:

- *"either side may reload at any instant"* → the seal-seam + durable twin + demand-driven focus
   (Phases 3, 5, 6).
- *"the relay is untrusted"* → warmth gates, vouchers, out-of-band secrets, SAS (Phases 4, 8).
- *"converging on a shared fact"* → holding-vs-referring identity, the surface bump, observable
   blocks (Phases 2, 7, 9).
- *"frames over piers"* → lane choice, req lifetimes (Phases 3, 6).

The ferry is the worked example throughout: a **Linkor** (the "soul" device offering its account)
 and a **Linkee** (the new device becoming a "Cave" body of that soul) converge on the fact
  "the account now lives on both devices."

---

## Phase 1 — Name the parties and the ONE-SHOT vs STANDING state

Before any code, write down: **who are the parties, what is the one shared fact they converge on,
 and for each piece of state, is it a one-shot moment or standing until torn down?**

- **One-shot** = a handshake instant that fires once and is done (the ferry's `Swarm_ferry_send`:
   export account, seal, deliver — happens exactly once when the pier seals).
- **Standing** = state that must survive and re-derive across reloads until the ceremony resolves
   (the ferry's `ferry_secret`, `ferry_pending`, `ferry_awaiting`).

**WHY:** the ferry's central design is the **seal-seam** — `Swarm_ferry_on_seal` fires the one-shot
 transfer at the exact instant a `%Pier` seals bearing the right grant. That is beautiful when both
  ends stay up. But a device reloads mid-ceremony and the one-shot moment is *gone* — its `.c` state
   is wiped (Rule 5), and the seam never re-fires because the pier already sealed. Every "the link
    wedged forever" bug was a piece of standing state that had only a one-shot representation.

**HOW:** for each party, tabulate `{fact, kind: one-shot|standing, where-it-lives}`. Standing state
 needs a durable twin (Phase 5) and usually a demand beacon to re-trigger the one-shot after a
  reload (Phase 6). Do this on paper first — it is the cheapest phase and prevents the dearest bugs.

## Phase 2 — Model the shared object: HOLDING vs REFERRING, presence NOT payload

Decide how the shared fact is represented as C particles, obeying the identity law
 (`CLAUDE.md`: *"there's only one of anything"*).

- The **holding** is the ONE particle that IS the thing, under its owning container, wearing its
   mainkey (the ferry's landed `%Identity` soul; a `%Record` in a `%Library`).
- A **referring particle** merely NAMES it elsewhere, wears its OWN mainkey, and carries the id.
   1:1 lets the mainkey carry identity beside a join key (`Card,id:X` ↔ `Record,id:X`). **Many:1
    wears an `of:` pointer** (`Spin,of:X`, `Like,of:X`, `Heist,of:X` — many events per track).

**WHY:** the old magazine minted `%Record` *cards* that looked exactly like holdings — two
 different shapes under one mainkey — and it broke because "there's only one of anything." A
  multi-party feature that mints, say, a `%Vote` per participant per track is a **many:1**: it MUST
   be `Vote,of:<track>` beside the track holding, never a second `%Track` impersonation.

**Also:** a network object's *presence* (is the peer here now?) is NOT part of its snapped payload —
 it rides `.c` (`heard_at`), never `sc`, and *nothing a Story snaps may read live presence*
  (`Presence_todo.md`). Grant/identity is durable and snaps; presence is live and must not.

## Phase 3 — Pick the frame kinds and their LANE (ephemeral vs booked)

List every wire frame the procedure sends and classify each into a lane
 (`Peeroleum.g` `Peeroleum_send` ephemeral table + `Peeroleum_deliver` receive-bypass):

| Lane | Use for | Cost | Reliability |
|------|---------|------|-------------|
| **Booked** (reliable) | the one-shot payload that MUST arrive exactly once (ferry `ferry`, `adopt_seal`, `reinvite_seal`) | an inbox `%req:unemit`, per-Pier monotone seq, ack, retransmit | ordered, exactly-once, acked |
| **Ephemeral** (bypass) | self-re-asking beacons + one-shot teardowns that gain nothing from booking (`ferry_want`, `ferry_cancel`, `repli_want`, `pulse`, `ping`, `advertise`) | none — dispatched straight to the handler, no booking, no ack | best-effort; the RE-ASK is the reliability |

**WHY — the trap that cost days:** `ferry_want` was originally *booked*. A **reloaded Cave pier is
 not a "sealed friendship," so `Swarm_station_routes` never re-stamps its `%Ud`** — and a booked
  frame sits behind the **pre-Ud gate** in the serial inbox, *un-drained forever*. The Linkor never
   re-parked its confirm and "eed is not at the party." Moving `ferry_want`/`ferry_cancel` onto the
    **ephemeral receive-bypass** (`Peeroleum.g:709`) is what unwedged the whole Adopt: a half-thawed
     pier still HEARS the demand (still voucher-verified there — see Phase 8 — just not inbox-gated).

**HOW — the decision rule:** *If the frame re-asks itself on a timer, book NOTHING — make it
 ephemeral.* Booking buys reliability the re-ask already provides, and a booked self-re-asking frame
  is a storm generator (each want ran a full `inbox.do()` + O(depth) rollup; a want-storm melted the
   CPU). Only the true one-shot payload rides the booked lane. And note the send/receive asymmetry:
    a frame can be ephemeral-on-SEND but booked-on-RECEIVE (`ive_got`), or bypass on both — decide
     each independently, and beware `SwarmGot` asserts on *booked* not *delivered*
      (`Networky_directions_todo.md` item 1).

## Phase 4 — Gate on WARMTH, never on grant-liveness alone

Any action that transacts with a peer (surfacing a consent screen, sending the payload, seizing the
 screen) must gate on the peer being **actually present**, defined as `heard_at`-recent:

```
let ha = pier.c.heard_at || 0
let warm = ha && (Date.now() - ha) < 45000   // a voucher-checked frame from THEM in the last 45s
```

**WHY — THE stale-corpse family of bugs (a whole day, 2026-08-29 "goddamn unusable"):**
 `Swarm_pier_live(p, 'MyCave')` is a **grant check with NO presence** — a `%Grant:MyCave` persists
  for *every device ever (half-)linked*. So on boot the tab went straight into *"giving your soul to
   ○ <peer>"* where the peer was the first pier in the list, **offline for ages, can't possibly be
    asking**. Grant-liveness said "live"; the device was a corpse. Symptoms: "giving your soul to
     Gag ● online" for a peer that isn't there; a phantom confirm parked against a cold cave; the
      ceremony hijacking the screen for a dead ceremony.

**HOW:**
- **`heard_at` is the ONLY positive presence signal.** A voucher-checked inbound frame stamps it
   (`Swarm.g` hear funnel, `.c` only). A spoofer stamps nothing (Phase 8). Grant is durable identity,
    not presence.
- **NOT `socket_fresh`** as per-pier evidence: it ignores its `p` arg and reads the GLOBAL relay-wire
   stamp, so a chatty relay made *every* pier read warm. Its own contract says "never as positive
    per-pier evidence."
- **Gate at the CHOKEPOINT.** The ferry had three callers reaching the park (seal-seam, want-hear,
   retry-pump); the retry-pump picked its pier by grant alone, so ONE warmth check at the shared park
    site (`Swarm_ferry_on_seal:4458`) covers all three. Find your procedure's chokepoint and gate
     there, not at each caller.
- **Two windows, one answer:** ~45s for "warm enough to transact/seize"; `Presence_todo.md` wants the
   several freshness windows to collapse onto one answer — pick your N and reuse it.

## Phase 5 — Give standing state a DURABLE TWIN (the `.c` vs `stashed` mirror)

Standing state (Phase 1) lives in `.c` for the live tree — and **`.c` is wiped on reload.** Mirror
 every piece of standing state that must survive a reload onto the auto-saved `top.stashed`:

- ferry_secret (`.c`) ↔ `stashed.ferry_pending_secret` (Linkor)
- ferry_awaiting (`.c`) ↔ `stashed.ferry_awaiting` (Linkee)
- the UnInvite decline set lives ONLY on `stashed.uninvited` (a "no" must outlive reload)

**WHY:** reloading the soul device mid-ceremony **orphaned the `#fc` the other device already held**
 and the account could never cross — the ceremony was alive on one end, dead on the other. The twin
  lets standup *rehydrate* `.c.ferry_secret` from the stash (`Swarm.g:1422`) so the seal-seam,
   `link_active`, and poke all see it again.

**HOW:**
- On mint/arm, write BOTH the `.c` and the `stashed` twin.
- At standup, rehydrate `.c` from the twin *before* anything reads it.
- Clear BOTH on success AND on cancel — a reload must never rehydrate a *resolved* ceremony (the
   `ferry_cancelled` / `ferry_consume` clear the twin too).
- **Snap discipline:** a durable boolean rides as `1`-or-absent, never `false`/`0`; prefer deleting
   the key (`CLAUDE.md`). The twin is snapped state — obey the snap law.
- **Sweep dead ceremonies:** a secret that survived a reload with NO live warm pier is a *dead
   ceremony* (the QR was for a session that's gone) — sweep it, but ONLY when there is no live warm
    counterparty (a live pier means a real ferry is mid-flight; leave that alone). `Swarm.g:1398`.

## Phase 6 — DEMAND-DRIVEN focus: a `*_want` beacon, the mirror of the seal-seam

The asking party repeats a `*_want` frame on a timer so the serving party stays focused on the
 ceremony **regardless of its own `.c` resets.** This is the far mirror of the seal-seam: the
  ceremony is held open by the asker's *standing demand*, not by either end durably remembering a
   one-shot seal (owner: *"a steady flow of 'I want linkage' sentiment from 495 to eed to keep it
    focused on serving the request"*).

**WHY:** the seal-seam fires once, at the sealing instant. If that moment is missed — the pier
 sealed a tick before the secret was stashed, or the server reloaded — nothing re-fires it. The
  Linkee's `ferry_want` (every ~3s while awaiting) re-drives the Linkor's `Swarm_ferry_on_seal` off
   the WIRE (`Swarm.g:1026`), which re-derives the live secret and re-parks the confirm. The demand
    is what makes the ceremony *"couldn't not work"* across reloads on the serving end.

**HOW:**
- The beacon rides the **ephemeral lane** (Phase 3) and re-triggers the one-shot handler on receipt.
- **Throttle it HARD, with an absolute floor `force` can't cross.** The Link cell re-grapples on
   every version-bump, so a mounted cell fired **~1000 `ferry_want`/second** on startup (each deliver
    bumps → re-commission → remount → pounce again). `Swarm_ferry_ask` uses an 1100ms absolute floor
     *before* the force check, plus a ~2.8s idle throttle; `force` buys eagerness (leap the moment
      both ends are present), never a machine-gun.
- **Units trap:** throttle in `Date.now()` **ms**, not `Swarm_now` (which is *seconds* on a live
   tab). The original `Swarm_now(w) - at < 2800` compared a ~3 gap to 2800 and suppressed every ask
    for ~47 minutes — "eed is never pulled in."
- The beacon carries a page/proof so the re-triggered handler can re-derive who's asking and
   re-verify (Phase 8).

## Phase 7 — Make `.c` writes the UI must SEE bump the version (the surface bump)

If a `.c` write must change what the human sees *now* (park a consent, surface a cell), call
 `bump_version()` explicitly right after it.

**WHY:** *a `.c` write NEVER bumps `H.version`* (codebase law — refs/backlinks change constantly).
 The ferry `on_seal` parked `top.c.ferry_confirm` correctly — but the auto-surface effect and the
  cell's derived `confirm` only notice on the next wall-tick, which a music page **isn't even
   mounting**. So the ask arrived (`cave_pier=yes my_secret=yes ferrying=no`), the confirm was
    parked, and *"eed has no idea it's happening."* Adding `top.bump_version()` (`Swarm.g:4477`)
     pulls the "giving your soul" cell up the instant the ask lands — the exact courtesy the
      `ferry_got` handler already paid (`Swarm.g:1056`).

**HOW:**
- Bump after a `.c` write that must surface *this tick*. Frame-driven writes are safe to bump
   (never called from reactivity → no bump loop). Do NOT bump inside a reactive read
    (`Swarm_link_fresh` reads on every bump — a log or bump there machine-guns).
- **Wake ≠ Hold** (`Coding_guide.md`): a bump is a WAKE ("run the loop again soon"), not a HOLD. If
   the pending async op must show up in a *snap*, you need an unfinished `req` or a ttlilt, not just
    a bump. For UI surfacing a bump is right; for snap-timing it is not.

## Phase 8 — The security seam: out-of-band secret, voucher on the wire, SAS for the human

Three layers, because the relay is untrusted:

1. **Out-of-band secret — never on the relay.** The ferry `#fc=<secret>` rides the URL **fragment**,
    which never leaves the browser, so it never transits the relay. The sealed account is delivered
     over the pier; the code that unseals it travelled by QR/paste. `Swarm_ferry_link` +
      `Swarm_ferry_heard`: a wrong/tampered code throws in `unseal` → **fails closed**, no account
       lands.
2. **Voucher on every frame from a sealed peer.** The relay routes on `header.to` and never checks
    `header.from`, so any socket could forge a sealed friend's prepub. A frame from a sealed pier
     therefore carries a **per-era voucher** signed by the key we imported at seal
      (`Swarm_voucher_ok`); a bad voucher is DEAD — no `heard_at`, no dispatch. **This is why warmth
       (Phase 4) is trustworthy:** only a voucher-checked frame stamps `heard_at`, so presence can't
        be spoofed. The ephemeral bypass (Phase 3) still runs this verification — a forged
         `ferry_want` can't re-park a confirm.
3. **SAS glyph row for the human — expose a swapped pub.** `Swarm_ferry_sas` computes a 3-glyph row
    IDENTICALLY on both ends from the two pubs the `salt` binds (`<soulpub>:<bodypub>`). Equal rows
     on both screens ⇒ no relay swapped a pub (owner: *"three icons to match, like jackpot
      machines"*). No nonce — the row's whole job is to expose a MITM'd pub, and the human compares
       live.

**WHY:** without (1) the secret leaks to the relay operator; without (2) a live station lets any
 socket forge a sealed friend and warm false presence; without (3) a relay could swap the pub mid-
  handshake and the humans would never know. All three are needed for a soul-crossing ceremony; a
   lower-stakes procedure may need only a subset — but decide *deliberately* which.

## Phase 9 — Make refusals OBSERVABLE; give the human an UnInvite

**Every gate that silently refuses looks identical to "responded."** Name the refusal reason in a
 log at the point of refusal.

**WHY:** when `on_seal` heard the ask but the warmth/UnInvite gate refused to park a confirm, the
 log said **NOTHING** — indistinguishable from a successful response (owner: *"eed has no idea it's
  happening"*). The two-device debug session had no way to tell "the frame never arrived" from "the
   frame arrived and was refused." Naming it (`Swarm.g:4465`: *"heard the ask… but NOT surfacing a
    confirm — pier is cold (no heard_at within 45s) / was UnInvited"*) turns a mystery into a fork:
     you instantly know whether it's the cold-pier gate or an UnInvite.

**HOW:**
- Log the *reason* at each silent early-return that a debugging human would otherwise read as
   success. But **NOT in a hot reactive read** — `link_fresh` runs on every bump and a log there
    machine-gunned dozens of lines/sec; the decision there is silent, and the *park-site* gate
     (called from frames, throttled) is where the observable log lives.
- **UnInvite** — a durable, per-pub "no". The ferry ceremony *"keeps hijacking us until we click no,
   then will refuse to get distracted by that same thing."* A decline stamps the counterparty pub
    into `stashed.uninvited` (survives reload); the seize-check consults it so that pub never
     re-seizes the screen until a deliberate re-engagement (a fresh mint / opening the surface)
      clears the set. A "no" is durable and per-pub, full stop — an earlier draft that cleared all
       UnInvites on every mint *resurrected the very corpse the human had just declined*, in a loop.
- Route the fullscreen decision through the ONE focus authority (`Screen_decide` /
   `MH.c.screen = {dominant, reason, wants, yields_to}`, `Focus_todo.md`), not a private `{#if}` per
    surface. Independent surfaces reading private signals *fight, strand, and hide each other*. A
     ceremony seizes the screen only while its counterparty is WARM and un-UnInvited (`link_fresh`);
      a fresh boot-tap is a *want*, hosted by whatever surface is dominant, not a rung that hijacks.

## Phase 10 — Choose req LIFETIMES; wake ≠ hold; drop finished transient reqs

If the procedure runs through the req machine (Hovercraft), pick each req's lifetime deliberately
 (`Coding_guide.md`, `CLAUDE.md`):

- **eternal** — persists across ticks (a standing watcher).
- **permanent** — one-per-ghost, owns a write.
- **transient** — scaffolding; **an owner DROPS its finished transient reqs.** `finish(req)` marks
   `%finished` but does NOT detach — a snap fills with dead `req:…,finished` rows (38 landed
    `awaitbuf`s per pulled track before the cull). Drop transient reqs (`host.drop(req)`) at a safe
     seam (the sweep iterates a fresh `o()` snapshot, so a detach can't corrupt live iteration).

**WHY:** a pending async op that must show up in the SNAP needs a **HOLD** (an unfinished req or a
 ttlilt), not a **WAKE** (a bump). Interactively a wake is enough — the work runs, you see it. Under
  a Story run (which snaps at quiescence) the work can lose the race and the snap catches the *stale*
   state. This reads as a "flaky test," not a "missing hold." Arm the hold **synchronously, at the
    cause** — never in a later gate reached via a wake.

**HOW:** for a network op whose *result* must be in the fixture, hold from the frame that causes it
 until the result lands. For an op whose result is only UI (Phase 7), a bump suffices. A ttlilt is a
  one-shot snap-timing advisor that must ride a req that *finishes* — prefer DRIVING a req unfinished
   over a timeout bridge when you can (deterministic beats "hope N seconds is enough").

## Phase 11 — Write the LIVE-RUNNER Book FIRST; prove it there, never headless

**Author the Story Book before (or alongside) the code, and verify only on a LIVE runner.**

**WHY:** `scripts/Story_cli_run.mjs` (headless node+jsdom) has real disk access, loads the GhostList
 off the wormhole, and quiesces at a DIFFERENT depth than a live runner — its fixtures match
  *itself* but go all-red on the real runner. **A green there is a bubble, not a gate.** The ferry's
   identity-activation seam (`Clustation_concrete`) is explicitly noted as verifiable ONLY by the
    live two-tab test. And a race is invisible in a single green run — run the Book **N≥5 times**; a
     race shows as flip-flopping `ok_pct` / different diges (the freeze-fix and the compile-chain both
      demanded this).

**HOW:**
- `node scripts/runner_ask.mjs run <Book> --watch` — become_book + poll to done|failed (exit 1 on
   red, so it scripts). `steps` for per-Step ok|caveat|dige; `snap <n>` for one Step's live snap.
- The **snap-fixture diff IS the gate** — it's where you *notice* un-asserted detail. New assertions
   are `%see:'sentence'` (once-noticed; no commas — the peel parser splits on them; use an em-dash).
- **Book-inertness is a design tool, not an afterthought.** The ferry keeps every live-only branch
   behind `humdinger`/`station_up` guards so Books carry no `screen`/`heard_at`/consent frames and
    fixtures stay byte-identical (Book piers carry no `heard_at`, so the SEND branch that Books
     exercise is never gated). Design your live-only surfacing so a Book never records it — then the
      fixture diff isolates exactly the machine behaviour, and your feature doesn't re-record the
       whole suite.
- **`heard_at` verification volatility:** never assert cross-run `dige` equality on presence-derived
   state (run-volatile); assert on ok/exit code (memory: runner-steps-dige-is-run-volatile).

---

## The ferry as the worked reference (map from rule → code)

Keep this table beside the recipe; it's the "show me it's real" for every phase.

| Phase / rule | Ferry code (`Ghost/S/Swarm.g` unless noted) | The bug it cured |
|---|---|---|
| 1 one-shot vs standing | `Swarm_ferry_send` (one-shot) vs `ferry_secret`/`ferry_awaiting` (standing) | seam missed on reload → wedged forever |
| 2 holding vs referring | landed `%Identity` soul + `Swarm_body_take`; `Grant,of`/`%Grant:MyCave` | "there's only one of anything" |
| 3 lane choice | `Peeroleum.g:709` ferry_want/cancel bypass; `Peeroleum.g:404` send-ephemeral | booked want behind pre-Ud gate → "eed not at the party" |
| 4 warmth gate | `on_seal:4458`, `poke:4540`, `link_fresh:4641` (`heard_at`<45s) | "giving your soul to ○ offline"; boot-hijack into a corpse |
| 5 durable twin | `stashed.ferry_pending_secret` / `stashed.ferry_awaiting`; rehydrate `:1422` | reload orphaned the `#fc`, account never crossed |
| 6 demand beacon | `Swarm_ferry_ask` (want, 1100ms floor, ms units) | seam missed → confirm never re-parked; ms/sec unit bug (47min silence); 1000/s storm |
| 7 surface bump | `on_seal:4477` `bump_version()` after `.c` park | confirm parked but never surfaced on a music page |
| 8 security seam | `#fc` fragment; `Swarm_voucher_ok`; `Swarm_ferry_sas` | relay leak / forged sealed friend / swapped pub |
| 9 observable + UnInvite | refusal log `:4465`; `Swarm_ferry_uninvite`/`_uninvited`; `Screen_decide` | silent refusal = "no idea"; ceremony hijack loop |
| 10 req lifetimes / hold | Coding_guide worked example; `ferrying` in-flight flag `:4502` | mid-send re-park strands a dead confirm |
| 11 live Book first | `SwarmSpread`/`SwarmStaple`; `runner_ask`; humdinger-gating | headless false-greens; single-run race blindness |

## The one-paragraph version (for the person who won't read the rest)

Name your parties and mark each state one-shot or standing. Fire the one-shot at a **seam**; keep it
 alive across reloads with a **durable twin** and a throttled **`*_want` demand beacon** on the
  **ephemeral lane**. Gate every transaction on **warmth (`heard_at` < N s), never grant**. Verify
   frames with a **voucher**, keep the secret **off the relay** (URL fragment), and show a **SAS
    row** the human matches. **`bump_version()`** any `.c` write the UI must see now; **log every
     silent refusal**; give the human a durable **UnInvite**. Model the shared thing as a **holding
      + `of:` referrers**, obey the snap law (`1`-or-absent), and drop finished transient reqs.
       **Write the live-runner Book first, run it N≥5, and never trust a headless green.**
