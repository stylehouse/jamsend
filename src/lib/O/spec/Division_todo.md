# Division_todo.md

**One soul, many role-bearing bodies — a paradigm-general substrate, music poured through first.**
 Division is how one soul (one keypair) inhabits several bodies across machines and *departmentalises*
  the work among them by role. The Cave|Captain split is music's instance; the substrate is meant to be
   shared beyond music.

---

## 0. WHERE THIS IS (2026-08-28) — the live device-link path is the FERRY model

The device-link ("spread myself out") ceremony runs on a **handshake + ferry**, which SUPERSEDES the old
 `Swarm_adopt_*` seal-first model (that inverted the roles and never crossed — `Swarm_deliver` has no `%Pier`
  to route the seal over until a handshake forms one). The order:
  1. **SOUL device** presses "🔗 link a device" (in the Door) → `Swarm_ferry_link` mints an `%Invite:MyCave`.
  2. **NEW device** opens the `?Iz=` link → the ordinary invite path (`Swarm_redeem`) forms the `%Pier` both
      ways + cross-signs `%Grant:MyCave` (SwarmRole-proven).
  3. The soul's `Swarm_ferry_on_seal` fires when that pier seals → `Swarm_ferry_send` exports+seals+delivers
      the whole account over the now-live pier. New device `Swarm_ferry_park`s it; `Swarm_ferry_consume`
       unseals + imports → it holds the soul key, keeps its old key as body key, derives Post=Cave.

**⚠ THE `#fc` DECISION (owner, 2026-08-28) — it's redundant, remove it.** The seal today rides a random secret
 in the URL FRAGMENT (`#fc=…`, "hidden from the relay"). But the **adopt** ceremony beside it already sealed
  correctly with `ikm = offer.nonce` (a nonce that rides the offer frame over the relay) — the codebase already
   *trusts the relay*, which is the owner's stance ("we've got nothing to hide from the relay… eed is the
    security control point"). The ferry reinvented a more paranoid, worse version and made the human carry a
     fragment. **The fix: seal with the invite/redeem nonce like `Swarm_adopt_redeem`; drop `#fc`, the URL
      fragment, and the durable-secret twin; link goes back to plain `?Iz=<invite>`.** The big attended
       refactor (crown-jewel seal + re-record SwarmSpread beat 5) — do it carefully, not blind.

**LANDED 2026-08-28 — GRANTOR CONSENT LIVES ON THE PIER (owner: *"when the Pier turns up we should be pulled
 out of the QRcode openness over to where we're seeing that Pier having that Adopt with us, to confirm it"* +
  *"the one place that state goes"*).** The ferry no longer auto-fires on seal. Now:
  - `Swarm_ferry_on_seal` — on a **humdinger** (live end-user) tab, PARKS `top.c.ferry_confirm = {pub,name,at}`
     keyed to the just-sealed Cave pier and sends **nothing**. A runner tab (no humdinger, every Book) sends
      straight through as before — so `SwarmSpread` beat 5 dige is **unchanged (`ac0f77d14fc3ab55`)**, no churn.
  - `Swarm_ferry_confirm(w)` — the grantor's "✓ send my account", pressed ON the pier; does the one held send.
     `Swarm_ferry_cancel` also clears `ferry_confirm`.
  - **DoorFace** is the single home: the adopting pier (and only it) becomes a bordered `.df-adopt` block with
     ✓/no; other Cave piers get a quiet 🔗 + "your Cave" (they used to render as plain friends — the *"wtf it
      grants Music?"* confusion was a MyCave pier sitting unmarked in the friend list).
  - **LinkFace** pulls the grantor QR→Door the instant `ferry_confirm` parks (latched, re-arms on clear).
  - Verified live: Swarm.go **317901c**, `SwarmSpread` **5/5** + `SwarmStaple` **8/8** green on runner e747cbed.
  - **OWED on this:** (a) the **3-emoji SAS** on the ferry confirm (the adopt path has `Swarm_adopt_sas`; the
     ferry confirm currently has no MITM match — owner's *"three icons like jackpot machines"*); (b) a
      **`ferry_ok` ack** so the grantor's pier graduates "sent"→"adopted & confirmed" (today it can only know
       "sent" — secret cleared); (c) **live two-tab proof** that the pull + confirm actually crosses the account.
      See `Trust_todo.md` — this is the first payment on making Trust the protocol beneath the protocols.

**The Cell:** `%Link` (`LinkFace`, in `glass_kinds.ts`, minted in `Sounditron_commission`) is **REACHED, not
 resident** — pressing "🔗 link a device" in the Door calls `Sounditron_focus('Link')` (a new world-resolved
  nav verb for faces), the cell takes the belly, and Door|Radio abandon it. Grappled only while focused or a
   link is in flight (`Swarm_link_active`); auto-surfaces once on the RECEIVING side (`w.c.link_surfaced` latch).

**Landed this session (all compiled + parse-gated + Books green — RaBreach/PortPlant/SwarmSpread):**
  - **Live blocker fixed:** a device-link Cave pier no longer arms the "a friend came online" expectation
     (`Swarm_expect_friends` filters to `Grant:'Music'` friend piers). A Cave is your own device, not a friend
      — it was reporting `nobody has come online` forever ("eed sees Grauc, Grauc says FAILED").
  - **Unstick + escape:** `Swarm_ferry_cancel` (the Link cell's cancel button) + a **stale-ferry sweep** at
     `Swarm_station_up` (clears a secret with no live MyCave pier) — so a wedged "ferrying now…" self-heals on
      reload. NB the auto-surface means a wedged soul boots INTO the Link cell, so the sweep matters.
  - **Onboarding:** the fullscreen "music here is shared with friends" beg-screen is GONE for a new/peerless
     tab (`Butler.svelte` — `friendless` no longer opens the door stage; `landing`/`Adopt`/`relic` still do).
      Instead a **peerless invite button** sits under the ♪ LOCAL sayer in `RadioFace` (shows on counted-zero
       `door_friends`), pressing it → the Door cell where the QR lives.

**Proven:** `SwarmSpread` **5/5** (beat 5 = the ferry glue, `step=5,dige:ac0f77d14fc3ab55`, «the-account-
 ferries-over»). Debug tool: `scripts/runner_watch.mjs` (remote run + named "pointer" predicates, exit-coded).

**NEXT MOVES (owed):**
  - **THE `#fc`→nonce refactor** (above) — the headline. Attended, with a Book re-record.
  - **Adoptee identity transition — LANDED, needs live proof.** `Swarm_ferry_consume` funnels the landed soul
     through `Clustation_concrete` (Auto.svelte, the single mint|adopt chokepoint) so the soul becomes the sole
      ACTIVE `%Identity` and the blank husk deactivates. Only full proof is the **live two-tab test** — confirm
       after "accept" the device presents AS the soul (eed), not its blank incognito self. Then DROP the husk
        `%Identity` once nothing (census/vessel/address bind) references it.
  - **The live gate:** a real **two-device test on ONE shared origin** (mint on the soul, open on the blank
     device). Note: `djamsend.duckdns.org:9999` is a REMOTE node running OLD code (unreachable from the
      container) — test on LOCAL `:9091` where this session's code actually runs, or deploy first.

---

## THE FIELD IN ONE BREATH

A **soul** is a keypair. It runs in one-or-more **bodies**, each on a machine, each holding the soul key
 and its own durable **body key**. An undivided soul is one body at the bare `<prepub>`, with no role.
  The **Division ceremony** (`%Invite:MyCave`, LinkDevice) confers a **Post** (Captain, Cave, …) on each
   body — the Post *is* a cross-signed grant, not a self-chosen tag. One body holds the bare name and
    anchors everything: the **Seat** (whoever is most reliably online — usually the always-on daemon). The
     Seat derives a soul-signed, era-stamped **Charter** — `{body-pub, post, address}[]` — from its
      current grants; the Charter is how any body OR any friend learns and *trusts* which body plays which
       Post. Routing is **resolve-and-emit**: read the address for a Post off the Charter, emit, let the
        transport fail forward — no liveness cache. Authority to *issue invites* is a separate thing, the
         **Captain**, which never auto-inherits. That is the whole machine.

---

## THE ATOMS

- **Soul** — one ed25519 keypair (`%Identity.c.keys`, Tier A, never encoded). The unit of identity and of
   every friend-facing grant. Replicated whole to each body at LinkDevice; never changes.
- **Body** — one soul's presence on one machine: the pair `(store × soul)`, NOT the machine itself. Holds
   the soul key, its own durable **body key**, a current **address**, and — once divided — a **Post**. A
    store serving two souls holds two Bodies, one per soul.
- **Body key** — a body's own durable keypair, minted when a soul first stands up in a store and persisted
   body-locally (the machine's Dexie, NEVER replicated). It is (a) the stable per-body identity that keys
    the Charter roster and lets a body find its own row, and (b) what the LinkDevice ceremony encrypts the
     account TO. *(Built — `Swarm_body_key`/`_ensure`, persisted via `vessel_store.ts`.)*
- **Vessel** — one running instance on a machine (a tab, the daemon process). Vessels of one store share
   Dexie but may differ in anything else — which soul they serve, which FSA mount they hold. Every vessel
    registers in the shared **Vessel table** (a Dexie table beside Housing's `db.House`, per store):
     `{vessel, root_prepub, address, fsa, alive}`. Queried by a root prepub it yields that individual's
      local **subnet** — the vessels serving that soul here, now. No crypto among vessels: same-store trust
       is the Web-Lock and the table.
- **Address** — `<prepub>` (bare) or `<prepub>_N` (suffixed), won via hello-v2 / Web-Lock. Mutable,
   body-local, non-replicating (already stripped from export), mostly stable across sessions (a body
    re-requests its prior suffix on bind). The root prepub is the individual's subnet: every vessel serving
     that soul addresses inside it, and the bare address is the Seat.
- **Post** — a body's role in the division: Captain, Cave, … General role NAMES that recur across
   paradigms; a paradigm binds only what a Post *does*. A body's Post IS the `%Grant:MyCave` (or
    `:MyCaptain`, …) its Seat cross-signed for it — crypto, revocable via `%NotGrant`. An undivided soul
     has no Post; dividing is exactly the act that confers them.

## THE TWO AXES

- **Vesselling** — per machine, cross-soul. A store partitions into running Vessels via the Vessel table.
   Vessels on the SAME root prepub are that soul's local subnet: they share the soul's Body (its body key,
    Post, grants), differ only by address suffix, and elect a **tab-primary** per soul via Web-Lock.
     Vessels on DIFFERENT prepubs coexist in one store — each soul's group is its own subnet, its own Body.
- **Division** — per soul, cross-machine. One soul's Bodies on different machines, joined by the LinkDevice
   ceremony and split by Post. Shares only the soul key; each Body keeps its own body key, address, and
    Post. This is the subject of the doc.

The axes are orthogonal: the Vessel table slices a MACHINE by soul; the Division slices a SOUL by machine.
 A Body is the cell where they cross.

## THE TWO AUTHORITIES (orthogonal — this is the crux)

- **the Seat** — the body at the bare `<prepub>`: routing anchor + roster-writer + Charter-signer. It is
   whoever is MOST RELIABLY ONLINE (the bare name is won via hello-v2), so in the standard phone +
    always-on-daemon deployment the daemon-Cave is the Seat, not the phone. That the Seat is the always-on
     body is a feature: the Charter-refresh anchor is reliably up. Exactly one Seat at a time.
- **the Captain** — the INVITE HELM: the sole writer of the Tier-C invite ledger (Portability §9). A Post,
   usually the phone, usually suffixed, usually asleep — invites happen when the human is on the phone.

Seat = *coordination* (who anchors the bare name). Captain = *authority* (who issues invites). They
 coincide only on a phone-only soul with no daemon. This orthogonality gives the right failure mode: a
  dead phone loses the Captain (invite-issuance freezes; the human re-mints one via `%Invite:MyCaptain`)
   WITHOUT losing the Seat (the daemon keeps routing + serving alive).

## THE POST'S TRUTH CHAIN (one truth, everything else a cache)

1. **Truth = the grant.** A Post IS the `%Grant:MyCave` the Seat cross-signed at the ceremony. Per-body,
    internal (friends never see it), revocable via `%NotGrant`. Not a string a body picks.
2. **Attestation = the Charter.** The Seat derives, from its current un-revoked grants, a roster
    `{body-pub, post, address}[]`, **signs it with the soul key**, and **stamps its era**. A friend (or
     any body) verifies the Charter against the soul pub; a spoofed "I am Alice's Cave" fails the signature;
      a split-brain can't flap because peers keep the highest-era Charter.
3. **Cache = the `%Body` roster** under `%Peering`, keyed by **body-pub**. Replicates (all a soul's bodies
    must agree who is Captain and who is Cave — keyed by whose-body-it-is, it can't confuse).

**Everyone routes via the Charter** — self-bodies and friends alike — so there is ONE routing path, no
 self-vs-friend fork. Raw grants only BUILD the Charter; nobody routes off them.

## STORAGE & REPLICATION (what crosses the wire, what stays home)

- **Replicates (shared soul-truth, must agree):** the soul key (Tier A, once); the `%Body` roster + the
   Charter (Tier B / signed snapshot); friendships, grants, the pool ledger (Tier B, grow-only union); the
    invite ledger (Tier C, Captain-write-only, replicated read-only to Caves).
- **NEVER replicates (body-local, computed — the existing `Swarm_protocol` strip):** which row is ME
   (computed by body-key match, never a stored flag); my current address; presence; the Vessel table (it
    IS the machine's runtime census); the stolen flag; per-body wire state (seq/era/voucher).

## ROUTING — resolve-and-emit, no liveness cache

find-body-by-role is TWO questions, kept apart:
- **RESOLUTION** — Post → body-pub → address, off the Charter. Pure, stateless, cannot lie.
- **REACHABILITY** — is that address answering? The transport's ground truth (`Swarm_deliver`'s boolean;
   the outbox ack/dead ledger). You discover it by SENDING, never by caching a verdict.

```
Musu_serve_ask(w, ident, pier, frame):
    if (!this.Swarm_pier_live(pier, 'Music')) return false   // grant gate — per-soul, checked at use
    let to = this.Charter_addr(pier, 'Cave') || pier.sc.prepub   // Cave address from the Charter; else the Seat
    return this.Swarm_deliver(w, ident, to, frame)           // EMIT; false = fail-forward, re-ask heals
```

Two hard transport facts the routing must honour:
- **The relay does EXACT-address routing, no fan-out** (`relay.ts:120,229` — `locals:Map<addr,sockets>`).
   A bare frame reaches only the Seat; reaching a Cave REQUIRES its Charter address. This is why the Charter
    is load-bearing, and why the always-on Seat is both the fallback anchor and the Charter-refresh source.
- **A friend holds one `%Pier` PER BODY** (per address — seq/era/voucher are per-body and never converge,
   Portability §7). The Charter tells the friend the Post→address map so it annotates each per-body pier
    with its Post; `Swarm_pier_body(soul, 'Cave')` = "my pier to this soul whose Post is Cave."

The one thing emit can't give a synchronous UI ("is Alice's Cave up, right now, before I act") is a
 DERIVED, non-persisted read — `Musu_serve_note(soul) → 'live'|'offline'|'unknown'` folding `Presence_here`
  + `Swarm_pier_live` at the read — not a particle.

## THE WELD — the Charter in the core language

The resolution layer already speaks C: `%Body` is a true particle (mainkey `Body`, identity `{Body,pub}`,
 oai-idempotent, scalar sc, `.c.up` backlink, bump()-driven watchers), and pure queries (`Swarm_body_for`)
  are the right shape for pure resolution — the o()/oai() register. The owed process layer (sign, gossip,
   absorb) is async work, and async work in this application speaks Hovercraft:

- **The Charter is a signed dige of the division.** Era = the version idiom (a counter bumped on change);
   the payload = a canonical scalar serialisation; re-charter = a watcher noticing the grants' digest
    moved. This is Story's own snap shape — a serialisation of state at a version, re-emitted when the dige
     changes — signed. Not a new concept in this app; its oldest one, given a signature.
- **ONE stable `%Charter` row, merged in place.** `{Charter:1}` under `%Peering`, sc: `era`, `sig`,
   `payload` (one scalar). oai + merge like `reset_interval`'s `%mo:main,interval` — NEVER replace()-churned
    (replace empties the container across two awaits: the Vytui childless-window class) and never
     one-row-per-era (goner+new snap churn).
- **The async sign/verify rides `expecting()`.** Key ops are async; a bare async fn lets a Story snap tear
   mid-sign. `expecting(w, 'charter_sign', secs, fn)` holds the snap coherent via ttlilt — resolve is
    causal, timeout is the bounded escape. Same on the receiving side's verify-then-absorb.
- **Friend-side `%Body` rows are minted ONLY by Charter-absorb** (verify → project), never by raw roster
   gossip. Routing off `%Body` rows then IS routing off the Charter, one hop removed — the cache-discipline
    rule becomes structural, not conventional. `Swarm_roster_of/onto` survive as the Charter's payload
     codec + projection, not as a parallel unsigned channel.
- **Cross-ghost = elvisto / vaguely_ponder.** The serve binding asks Swarm via the deferred call, so a
   context without Swarm stood up gives up cleanly instead of throwing.

## LIFECYCLE

- **Birth** — one body, at the bare name, no Post, no Charter. Routing = dial the bare name (it's the one
   body). Division machinery is entirely OFF.
- **First division** — the CEREMONY (see below): a blank device offers itself, the soul-holder scans and
   seals its account across, both consent, Posts are conferred (original → Captain, new → Cave), the
    more-online body takes the Seat, and the Seat writes Charter #1.
- **Post change / revoke** — the Seat mints a `%NotGrant` (existing machinery) and re-charters at a higher
   era; the new Charter gossips out. Change = revoke + re-issue.
- **Seat succession** — automatic: the bare name frees on the old Seat's relay-heartbeat lapse (~30s), the
   next-most-online body wins it via hello-v2 and re-charters. No election beyond the relay arbiter.
- **Captain succession** — NEVER automatic: the human re-mints via `%Invite:MyCaptain` (the most dangerous
   token — grants who-you-are, not what-you-serve). Invite-issuance stays frozen until then; nothing else
    is affected.
- **Eviction — replacement, NOT a timer.** A Post-holder leaves the Charter only when it is REPLACED: a new
   holder of that Post is `%NotGrant` + re-issue (the mechanism above), and the re-charter simply omits the
    old one. Whether a new holder evicts the incumbent is the Seat's call, defaulting by whether the Post is
     SINGULAR — a new **Captain** evicts the old (one invite-ledger writer, always); a new **Cave** COEXISTS
      (multi-Cave is permitted), evicted only on the admin's say-so. A body that dies and is NEVER replaced
       just lingers and fails-forward dark on each ask — harmless, because the Charter never asserted liveness
        (that is the `%Reach` cache we reverted): **liveness lives at the bare name**, where the Seat is alive
         by construction and every miss falls back to it. So there is NO dark-threshold timer and none is owed.

## FAILURE MODES (the honest table)

| Situation | Outcome |
|---|---|
| Seat asleep | Rare (it's the always-on body). Routing still works off the durable Charter; only re-chartering waits. |
| Captain (phone) dead | Invite-issuance freezes (safe); routing + serving + existing grants all continue. |
| Stale Charter + Cave moved address | Wedge until the Seat re-charters; bounded by address stability. The one real gap. |
| Split-brain (two Seats, a partition) | Peers keep the highest-era Charter; the loser's stale Charter is ignored. |
| Nobody plays the asked Post | `Charter_addr` → null → dial the Seat (bare); the transport declares `%dead` on exhaustion. |
| Multi-Cave | Permitted; the pick is deterministic (bare-first, address-asc); try-one-then-next on a miss (no broadcast). |

## THE CEREMONY — spread out by scanning (LinkDevice, the act of dividing)

Dividing rides the friend-invite rails **inverted**: the blank device shows the QR, the soul-holder scans.
The Door already IS this shape (InvitePanel mints an offer → InviteQR renders it → the OTHER device's native
 camera reads the `?…=` URL → live relay handshake); there is no in-app scanner and none is needed.

- **Offer — the Cave-to-be, a blank proto-identity.** A fresh device boots as *just a body key* — adopted by
   nobody, wearing **NO role** (it does not know it is a Cave). It shows a QR: an **adoption offer** (its
    body-key pub + nonce + presig), reusing the Idzeug compact codec. Role-agnostic by construction.
- **Scan — the soul-holder (the Captain-to-be).** The device that HAS the soul scans with its native camera.
   It DECIDES a role to propose (Cave, for an always-on box), **warns the human this is BODILY** — "this
    device will hold your keys and can serve your library AS you" — and on confirm SEALS its account to the
     scanned body-key pub (SwarmSeal, Phase 1) + mints `%Grant:MyCave` for it, delivering both over the relay.
- **Decide — the Cave consents.** The offered device RECEIVES the sealed account + the proposed grant and
   **decides**: the Cave doesn't know it's a Cave until now, and it must accept. On yes: it unseals (now holds
    the soul), derives its Post from the grant (`Swarm_body_repost` → Cave), and stands up as a body.
- **Seat + Charter.** The more-online body (usually the box) claims the bare name = the Seat; the Seat
   reposts both ends (original → Captain, new → Cave) and writes Charter #1, gossiped out.

**Consent is mutual and neither side is silent:** the soul-holder confirms the bodily *share*; the device
 confirms the *role*. A blank offer + a proposed role + a granted consent — never a self-declared Post.

**In the Door:** friend-invite stays the main act; a SMALLER **link a device** button opens the offer/scan.
 The device side shows a blank-body QR (never pre-labels a role); the phone side lands in its OWN colour with
  the bodily warning (NOT the friend colours) — a mis-scan must never quietly hand over your soul.

## VOCABULARY (glossary — rename freely, this is the coinage)

**Soul** · **Body** (`store × soul`, one Post) · **Body key** (durable per-body keypair + id) · **Vessel**
 (one running instance) · **the Vessel table** (the store's shared runtime census, grouped by root prepub =
  an individual's local subnet) · **Address** (bare / `_N`) · **Post** (role: Captain, Cave) ·
   **Vesselling** (per-machine, cross-soul partition) · **Division** (per-soul, cross-machine role-split) ·
    **the Seat** (bare-name anchor + Charter-signer) · **the Captain** (invite helm) · **the Charter**
     (soul-signed, era-stamped roster).

*Renamed along the way (old → current, for anyone holding an earlier draft): SelfType → Post ·
 vessel key → body key · Sibling / Facet → Vessel · DivisionMaster → the Seat.*

## BUILT vs OWED

**Built (model layer, additive, dormant — each RECORDED green on the live runner: real snaps + declared
 `%see` assertions, verified by inspecting the snaps not just the ok_pct; crypto proven standalone too):**
- **RESOLUTION register** — `%Body` roster + `Swarm_body_take/note/roster/pick/for/mine` + `Swarm_pier_body`
   + `Swarm_roster_of/onto`. Book **SwarmDivide** (Swarmation.g). `%Reach` was built then reverted (appendix).
- **1 · body key + Vessel table** — `Swarm_body_key`/`_ensure` (durable per-body keypair on `.c.bodykey`,
   Dexie-persisted via `src/lib/O/vessel_store.ts`, never replicated); `Swarm_body_mine` COMPUTES which row
    is me by body-key match (the stored `self:1` is GONE — a flag would replicate and lie); `Swarm_vessel_pick`
     + `Swarm_vessel_subnet` + the Vessel table (`{vessel, root_prepub, address, fsa, alive}`, registered at
      `Swarm_cohort_stand`). Book **SwarmBody**.
- **2 · the Charter** — `Swarm_charter_sign` (derive from the live `%Body` rows, sign with the soul key,
   stamp era, ONE `%Charter` row merged in place) + `_wire`/`_verify`/`_parse`/`_payload` + `Charter_addr`
    (resolve a Post→address, bare-first) + `Swarm_charter_absorb` (verify → land → project, highest-era wins).
     Book **SwarmCharter** + `scratchpad/charter_verify.ts` **16/16** (good verifies; moved-address / bumped-era
      / swapped-soul / wrong-pub rejected; supersede / stale / forged; multi-Cave pick).
- **3 · Post-from-grant** — `Swarm_post_from_feature` (My<Post> → Post) + `Swarm_grant_post` (the LIVE
   grant's Post, honouring `%NotGrant` as `Swarm_pier_live` does) + `Swarm_body_repost` (SET from a live grant,
    DROP under a revoke, body row stands). Book **SwarmPost** over SwarmRole's real redeem/revoke rails.
- **4 · Charter gossip** — a signed `charter` frame (`Swarm_charter_gossip` / `Swarm_charter_heard`), armed
   beside the other kinds, dispatched in both the pump and the hear funnel, SEEDED at `pier_accept`/`pier_confirm`
    (no-op for an undivided soul), re-emitted on a division change. Book **SwarmGossip**. Regression-clean:
     SwarmStaple 8/8 + SwarmChain 5/5 green against the shared-plumbing change.
- **5 · the serve binding** — `Swarm_serve_to` (Cave address off the Charter, else the Seat) + `Swarm_serve_ask`
   (gate on the Music grant at USE, resolve, emit — fail-forward). Book **SwarmServe**. The last mile — wiring
    the Heist/Ra dial to `Swarm_serve_ask` — is the owed CALL-SITE seam below.

**Fixtures RECORDED (live runner, `?B=<Book>`, 2026-08-27):** SwarmBody 4 steps / 5 assertions ·
 SwarmCharter 4 / 5 · SwarmPost 5 / 3 · SwarmGossip 4 / 3 · SwarmServe 4 / 3 — 19 declared swears, all
  sworn, all green. Checking the snaps caught a hollow-green in SwarmPost (a pier keyed `{Pier:1,pub}` was
   looked up as `{Pier:<prepub>}` — the same latent bug still sits in the SwarmRole Book at Swarmation.g
    ~2160, un-recorded so never caught); fixed + re-recorded with every derive/revoke flag firing.

**BUILT — THE CEREMONY (the "spread out" act, 2026-08-27):** `Swarm_adopt_offer`/`_verify` (role-agnostic
 body-adoption offer, presig-proven) · `Swarm_adopt_redeem` (verify → Sealbox-seal the whole account to the
  offered body-key → mint `%Grant:MyCave` → deliver) · `Swarm_adopt_absorb` (consent → unseal → import → the
   body holds the soul key → repost → Post) · `Swarm_adopt_finalise` (Captain + Cave rows + Charter #1) ·
    `adopt_seal`/`adopt_confirm` frames armed + dispatched · the UI front doors `Swarm_adopt_offer_url` /
     `_land` / `_pending` / `_consent`. Book **SwarmSpread** RECORDED green (4 steps / 4 assertions): the
      account genuinely crosses devices (`account_crossed`), the box derives Cave, Charter #1 routes both, and
       it fails closed on a tampered seal / wrong nonce / withheld consent. Regression-clean (SwarmStaple 8/8).
- **UI (`LinkDevice.svelte` + Door wiring, compile-clean, UNVERIFIED live):** the offer/land/consent faces;
   the role rides the offer (`Swarm_adopt_offer_url(w, base, role)`, default Cave) so both confirms NAME it;
    the **EmojiConfirm SAS** (`Swarm_adopt_sas_land`/`_consent`) shows on BOTH screens to catch a relay MITM;
     the warning is an opaque **cell takeover**; Link Device **auto-surfaces** on a landing `?Adopt=` or a
      parked consent; Butler shows "🪞 linking a device" (not the friend welcome); the Door paste slot accepts
       `?Adopt=` links; **🦑 squid logs** trace the handshake. Label "🪞 Link Device"; "TOTAL TRUST" opens the
        key-copy warning. **The human's two-device test is the gate** (see the check-list).

**Owed (the ceremony's remaining edges):**
- **The adoptee's identity transition.** After `Swarm_adopt_absorb` the device holds BOTH its old auto-vivified
   proto-identity (the body-key donor) AND the imported soul — so it can itself read as "two of you". Retiring
    the old self is NOT a naive husk-drop: the live self is stood up + managed by Auto/Clustation, so the
     transition "I am my own identity → I am a body of the soul" has to hand off through that layer, not just
      `container.drop`. Owed + Book-worthy (SwarmSpread proves the account crosses; it does not yet prune the
       donor). *(This is the most likely cause of a real post-adoption "two of you".)*
- **A role picker at the offer** (Cave / Captain) instead of the Cave default — small, offer-side.
- **Deploy to the remote node.** All of this lives on the local `/app`; the remote (djamsend) needs it pulled/
   built. The `?Adopt=` token proves the ceremony `.go` reached it; the UI batch above did not, yet.

**Owed (the other last mile):**
- **Wire the music dial to `Swarm_serve_ask`** at the Heist/Ra serve call site (needs live music fixtures +
   a serving daemon to verify), and **re-ground SwarmDivide onto per-body piers** — SwarmServe already proves
    the per-body Charter routing that supersedes SwarmDivide's roster-under-one-pier resolution.

**Owed a HUMAN ruling (not inventable):** whether the MUSIC paradigm lets one daemon Cave serve several
 souls' pools at once (Portability v1: one soul per Cave — deferred). One-store-many-souls is otherwise
  structurally native (the Vessel table groups by root prepub, and Body = `store × soul`, so a family daemon
   simply holds several Bodies). *(The dark-threshold prune number is RESOLVED: eviction is replacement, not
    a timer — see LIFECYCLE › Eviction. No quota is owed.)*

---

## APPENDIX — how we got here (the reasoning trail, compact)

- **The layering flip.** Captain/Cave were first placed as MUSIC-tenant vocabulary; the owner ruled them
   GENERAL ("below the Music realm"). The substrate owns the role NAMES; a paradigm binds only their MEANING.
- **The `%Reach` reversal.** A first pass reified "the other side" as a materialised liveness verdict
   (`%Reach`, kept fresh by a watcher off the presence pulse). Two adversarial Opus reviews + the owner's
    DNS-lookup instinct killed it: it re-introduced the exact "cache liveness + keep it fresh" shape the live
     transfer protocol (`repli_want`, `Repli.g`) already tore out for being "pure liability" that flooded the
      outbox and killed the deliver pump. Reverted. RESOLUTION stays pure; REACHABILITY is the transport's.
- **The Vessel straightening (owner, 2026-08-27).** The doc had hijacked "vessel" — the code's per-instance
   word (`Swarm_cohort_vessel`) — for the per-Body durable key. Straightened: Vessel = running instance
    (subsuming the old Facet/Sibling, and free to differ in soul/FSA/anything); the durable keypair is the
     BODY key; Body = `store × soul`; and a shared Vessel table grouped by root prepub is an individual's
      local subnet. This also made multi-soul stores structurally native.
- **The six cracks that shaped the field:** (1) relay has NO fan-out → the Charter is necessary [validated];
   (2) a stale Charter can wedge with no fan-out net [bounded by address stability]; (3) no durable per-body
    identity in code → the body key must be built; (4) Charter split-brain [fixed by the era stamp]; (5)
     friend-side is per-body piers, not roster-under-one-pier [reconcile before live]; (6) the always-on
      daemon-Cave is usually the SEAT, not the Captain [the insight that made Seat/Captain orthogonal and
       dissolved crack 2].
- **Resolved on inspection (not cracks):** per-body vs per-soul grants (both key off the soul — authz via
   the per-soul Music grant, authn via the soul-key voucher).
- **Death is eviction, not a timer (owner, 2026-08-27).** The last-owed HUMAN ruling — a "dark-threshold
   prune number" — dissolved once the frame flipped from *timeout* to *replacement*: a Post-holder leaves only
    when a new one takes its Post (`%NotGrant` + re-charter), singular Posts (Captain) evicting by default and
     plural ones (Cave) coexisting. A body that dies unreplaced lingers harmlessly, because the Charter never
      gated liveness (the `%Reach` lesson) — liveness lives at the bare name, where the Seat is alive by
       construction and every routing miss falls back to it. No quota, no clock, nothing owed.

*(This doc was consolidated 2026-08-27 from a long design + adversarial-review + crack-hunting arc.)*
