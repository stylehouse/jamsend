# Ferry_todo — the device-link ceremony: one particle, one phase walk, aware to the end

## 0. What to get on with

**THE BIG REFACTOR (owner 2026-08-30: "you have my list of wants that we will achieve in a big
refactor? go ahead then!").** The ceremony works end-to-end (proven live: mint → open → understand →
auto-receive → persist → reload → resume as the soul, relay grants `_1`, mirror write-discipline
holds) but the state is a wart-field: ~11 `top.c.ferry_*` flags + 3 `stashed` twins + UI-local
latches, with FOUR separate "make it show up" patches (bump / poke / pop_glass / link_open) bolted on
because the surfacing authority reads state it is never notified about. Every stumble of 2026-08-30
traces to that shape. Replace it with **one %Ferry particle whose phase walk IS the ceremony**.

Arc: §1 the wants (the owner's list — the refactor's acceptance tests) → §2 the state model →
§3 the write seams → §4 what stays untouched → §5 the plateau beyond (bodies of one soul).

## 1. The wants (owner's list, gathered live 2026-08-30 — each one stays true after the refactor)

1. **Aware all the time.** eed gets pulled to the Link cell the moment the Cave asks — from Radio,
   from anywhere, no Door visit. Every phase move surfaces itself (the particle bumps; one policy
   decides pull vs stay).
2. **Responsive to the end.** Every ack flips the face NOW (`carrying…` → `✓ delivered` →
   `✓ done — devices linked`), eed resolves without human help, and the acks themselves never starve
   (Peeroleum control-plane carve-out — landed, keep).
3. **Simple comms that resolve.** One heading + one line per side, upgraded in place. Concise consent:
   "become X? [understand] [not now]" (weight on hover). No third ask — opening the link + understand
   IS the consent; the soul lands and is taken on automatically (auto-receive). The linkee's terminal
   step is the point: **"reload — wake up as your account"**.
4. **Done goes to the Door.** The terminal exit lands in the Door (`Sounditron_link_done`), where the
   new 🔗 cave pier in the our-box is the receipt. Cancel/no stays in the Link cell (existing ruling).
5. **Persistence correct at every seam.** The consume `thang_put`s the keypair (the ARREST fix —
   landed) **and must also carry the ledger** (§3.9: the Dexie resume path restores the key and
   nothing else — the 2026-08-30 log shows the reborn body dropping ALL family traffic "no Pier for
   7950f300", which strands friends' acks and is very likely the #37 flood's root). Terminals clear
   the durable twin (no "you have a device link in progress" ghosts).
6. **Books gate it.** InvFerry (6 beats) + InvSeal stay the gate; the %Ferry particle makes the phase
   walk SNAP-VISIBLE so a Book can assert `Ferry,phase:sent` instead of poking `.c`. Fixtures
   re-record ONCE, deliberately, when the particle lands in the snap.
7. **Never a boot hijack.** The seize policy keeps the warmth gates + butler hold (the 20s→120s valve
   lesson: a grace valve must sit FAR above any honest boot, and the splash now holds until Radio).

## 2. The state model — one %Ferry particle

One ceremony per tab. `%Ferry` lives on the station world (`A:Clustation / w:Swarm`), found
`w.oai({ Ferry: 1 })`:

    Ferry:1, phase:<p>, role:soul|cave, pub:<counterparty prepub>, name:<friendly>, serial:<n>, at:<s>

Phase walk (soul side): `minted → sealed → confirming → ferrying → sent → held → got → done`
Phase walk (cave side): `offered → joining → awaiting → pending → receiving → received → done(reload)`
Terminals from anywhere: `declined | ended | cancelled` (each clears the twin; `done` too).

- `at` re-stamps on every phase move (Swarm_now — Book-pinnable seconds); ages in the UI read one place.
- The SECRET never rides the particle sc (it would snap) — it stays `.c` + the ONE durable twin:
  `top.stashed.ferry = { phase, secret?, serial?, pub?, at }` — replacing ferry_pending_secret /
  ferry_awaiting / ferry_await_got. Standup rehydrates the particle FROM the twin (one seam).
- Acks fold in as phase moves, not side-flags: `held`/`got` ARE phases.

**The one verb:** `Swarm_ferry_phase(w, phase, patch)` — updates the particle, mirrors the twin,
bumps version, and applies the surface policy (pull Link via `Sounditron_link_open` for the phases
that deserve the screen; `Sounditron_link_done` for done). Writers never touch sc/stash/surface
directly. This single chokepoint is what makes wants 1+2 structural instead of patched.

## 3. Write seams to rewire (inventory)

1. mint (`Swarm_ferry_link`) → phase minted (+serial, secret to .c+twin)
2. `Swarm_offer_land` (URL/hashchange, cave) → offered
3. offer_accept/redeem (`Swarm_redeem` arms) → joining → awaiting
4. `Swarm_ferry_on_seal` + poke confirm-park → confirming (replaces ferry_confirm)
5. `Swarm_ferry_send` → ferrying → sent
6. hear `ferry_held` → held;  hear `ferry_got` → got (both currently patched with pop_glass — the
   phase verb's surface policy absorbs them)
7. `Swarm_ferry_park` (cave) → pending (+ferry_held ack send stays)
8. `Swarm_ferry_consume` → receiving → received; declined branch → declined
9. **NEW: ledger travels with the key.** At consume, after `Clustation_concrete` + the thang_put,
   run the `Swarm_restash_all` seam (the disk path's own idiom, Auto.svelte ~261) so the soul's
   Piers/Idzeugs/ChainRoots rehydrate on every later boot — a body without its friends drops the
   family's traffic and strands their acks (the 2026-08-30 "no Pier for 7950f300" log).
10. `Swarm_ferry_cancel` / `ferry_cancel` hear / `Swarm_ferry_cancelled` → cancelled/ended
11. Readers: `Swarm_link_active` (any non-terminal phase) / `Swarm_link_fresh` (phase×warmth policy,
    butler hold + 120s valve preserved) / LinkDevice (ONE derived off the particle) / BootGate /
    Butler / DoorFace wire strip.

## 4. Untouched by this refactor

- The frames on the wire (kinds, voucher gate, reliable-outbox policy) — protocol unchanged.
- Peeroleum control-plane carve-out; Clustation_concrete/adopt; the identities Thang shape.
- The Book grammar; InvFerry/InvSeal beats (assertions may tighten to read `Ferry,phase:*`).

## 5. The plateau beyond (NOT this refactor — the next arc)

Bodies of one soul cooperating: the relay family already gives discovery (hello_ok names the family,
suffix grants); missing is (a) body↔body dial + a Repli self-lane (the Cave's library stays empty),
(b) family fan-out hygiene — a frame addressed to the bare name reaching a body that can't serve it
should NACK-with-redirect rather than silently drop (today that silence = friends' retry storms),
(c) role division across machines (%Sibling was built same-profile; the census needs the wire).
Twins-not-friends stands: bodies are one soul, never Piers of each other — "they don't list each
other in their Pier lists" is CORRECT and stays.

**The instance identity (owner 2026-08-30: "we need a way to refer to the unique instance of the
Identity, huh. Captain Hook, Cave Hook").** A body is soul × role: the **Captain** is the primary
body (holds the bare relay seat, owns the account write — both facts already enforced), a **Cave**
is each linked body (suffixed seat, mirror held). The model half-owns this already: `%Body` rows
keyed BY ROLE (Swarm.g §"by ROLE", distinct from same-profile %Sibling) + the relay's family
addresses ARE the instance handles. The build-out: at ferry-done each side files the other as a
%Body under the soul's own Peering ({Body: captain|cave, place, address}), the standup census
refreshes their liveness off the family hello, and the Door's our-box lists them by instance name —
"● Captain Hook" / "● Cave Hook" — self marked, each with its own presence dot. That row is ALSO
the dial target for the Repli self-lane (a).

### 5b. When the fun starts — the startability ladder (owner 2026-08-30: "SoundPooling… remote
### heists, etc. note when we can start them")

What each wants, in dependency order — the point being that E is startable NOW:

- **SoundPooling / the Repli self-lane (facet E)** — the Cave's library filling from the Captain.
  Startable **now**: B landed (the reborn body has its piers/grants back, so ordinary friend-Repli
  already flows to it); what's missing is only the body↔body lane itself (Repli is keyed by
  Pier/Grant; bodies are twins-not-friends, so they need a family-keyed lane — the %Body roster +
  relay family addresses are already the dial book). First slice: the Cave pulls the Captain's
  %Library listing over the family address, reusing the existing repli_want machinery with the
  family as the authz (same soul = full grant by definition, no %Grant needed).
  **STARTED 2026-08-30 — pools of defined size (Ra.go 273583c).** The Quartermaster (Ra.g, the
  goal→diff→%Want steward, Portability_doc §6) now composes the goal from **%Pool compartments**:
  `Ra_pool_define(w, name, take, cap)` declares `%Pool,name,take,cap` under a %Pools shelf;
  declaration order is priority (earlier pools claim first, dedup); take-policies v1 all
  deterministic — `taste` (Like3/Grab2/Spin1), `liked`, `kept`, `latest` (last %Jam session, ledger
  order as clockless recency). Caps count TRACKS v1; byte-budgets are v2. No %Pool declared = the
  old anonymous single goal, byte-identical (MusuRaStock/MusuLossy/MusuHeist stayed green, zero
  churn). Wants from a declared pool wear `pool:<name>` — the Door face's composition column.
  **NEXT (the "magic" that moves bytes): the live steward occasion** — a default-off knob (the
  backpressure precedent) that runs `Ra_quarter_serve` on real occasions (play-session end, idle,
  Cave reachable); then `pull` wants served over the wire (Siphon/heist ride); then the Door face
  showing pools + wants ("what your phone wants next and why").
- **Remote heists** — heisting a track off a body/friend on ANOTHER host. The machinery exists
  (Heist ledger + repli/heist knobs, default-off: repli_serve_parked_budget, heist_selfclock,
  heist_window); what gates confidence is **facet C** (family fan-out silently drops → retry
  storms — likely the #37 flood) since a heist across the family rides the same addressing.
  Startable **after C's NACK-with-redirect** (or relay-side exact-seat fan-out); before that,
  remote heists between FRIENDS (distinct souls) are already exercisable behind the knobs.
- **Role division across machines** (daemon Captain, browser Caves, %Sibling→%Body census) —
  needs D's roster+presence build-out first; not before.

## 6. The full facet ledger — everything open, one line + its tell (2026-08-30 handover)

The destination: **a person links their devices and the devices then ACT like one person** — same
account, same friends, the music flowing between them. The ceremony (the first half) is proven live;
everything below is either hardening it or building the second half.

- **A. The %Ferry refactor** (§§1–3) — **STAGE 1 LANDED 2026-08-30** (Swarm.go 387039c, gate green:
  InvFerry 6/6, InvSeal 5/5, SwarmSpread 5/5+1caveat, SwarmFerry 1/1, SwarmStaple 8/8, ZERO fixture
  churn): `Swarm_ferry_phase`/`Swarm_ferry_particle` exist, ALL writer seams advance the particle
  (mint/offered/awaiting/confirming×2/sent×2/held/got/pending/received/declined/ended×2/cancelled/
  done), and the SURFACE POLICY is centralized in the verb (the four bump/poke/pop/link_open patches
  are absorbed).  The particle resolves on the TAB's station world (top A:Clustation w:Swarm) — a
  Book's ceremony therefore writes the RUNNER's particle, not its own world's, which is why fixtures
  didn't move; want-#6 snap-visibility needs a follow-up decision (resolve on `w` when it is a
  station world?  or have Books read the tab particle directly).
  **Stage 2 (next): reader migration** — link_active/link_fresh/LinkDevice/BootGate read
  `Ferry%phase` instead of the flag pile; then retire the legacy top.c.ferry_* flags + unify the
  three stashed twins into `stashed.ferry`; then seam 9 (ledger travels with the key — facet B).
- **B. Ledger travels with the key** (§3.9) — **LANDED 2026-08-30** (Swarm.go 388834c): consume now
  runs `Swarm_restash_all(live, soul)` after the keypair thang_put (the disk-seed idiom — read from
  the grafted soul, stash under the concrete-activated live self; the same-prepub guard inside).
  Boot log tell when it works: `🪪 ledger restashed — N pier(s), …`. NEEDS ONE LIVE RELINK to prove:
  the previously-reborn Cave was stashed key-only, so it stays friendless until re-ferried (or the
  soul re-linked); after a fresh ferry + reload the "no Pier for … DROPPED" spam should be gone.
- **C. Family fan-out hygiene** — frames addressed to the bare soul-name reach every body; a body
  that can't serve them drops SILENTLY, stranding the sender's reliable-outbox emits → retry storm.
  **This is very likely the #37 Repli-flood root** (the editor 7950f300 resending forever).
  **SCOPED 2026-08-30, deliberately NOT landed blind.** The drop site is `Peeroleum.g:607` (`if
  (!pier) …` — counts `w.c.wire_drop[type]`, logs `🛰☠ no Pier for … DROPPED`, returns).  The fix
  is NACK-with-redirect: on a no-pier drop of a STALL type (repli_want/repli_data/ack — NOT
  pulse/pong/advertise), emit a lightweight `{type:'nack', to:h.from, from:h.to, ref:h.seq,
  why:'no-pier'}` back over the same wire (the relay routes by address, no %Pier needed — cf. the
  pier_hello ack at :603), and have the reliable outbox RETIRE the referenced emit on nack instead
  of retransmitting.  WHY DEFERRED: there is no `nack`/retire concept in Reliable.g/Peeroleum.g yet
  (grep confirms), so this introduces new wire semantics whose only real proof is a two-body live
  run — exactly the thing a single-node Book cannot gate.  Land it in a LIVE two-tab session:
  add the nack emit (additive, an unknown peer ignores it → no regression), add outbox retire-on-nack
  (the delicate half — retire ONLY the exact (to,seq) named, never a broader sweep), then watch the
  reborn Cave's `wire_drop`/#37 flood fall to zero across a relink.  Relay-side alternative (fan out
  only to the seat asked for) is cleaner but lives in the relay, not this repo's ghosts.
- **D. Captain/Cave instance identity** (§5) — %Body rows + our-box listing + presence per body.
  **THE NAME IS THE INSTANCE'S UNIQUE PART (owner 2026-08-30: "the Name stays with the instance!
  Captain Grav and Cave Guw").** The name written at each device's name-gate BELONGS TO THAT BODY —
  the ferry must stop letting the landed soul's `friendly` swallow the Cave's chosen name (today
  incogni took "Grav" from eed; it should have stayed Guw-the-Cave-of-Grav's-soul).  %Body rows
  carry {role, name}: the friends still see ONE soul; the instance names are the family's own
  address book (our-box, presence, dial targets).
  **FIRST SLICE LANDED 2026-08-30**: `Swarm_ferry_heard` stamps the pre-ferry husk's `friendly`
  onto the Cave's %Body row as `name:` — the instance name now survives the soul landing (fixtures
  re-recorded deliberately: InvFerry 5–6, SwarmSpread 5 — the diff is exactly the name row).
  STILL OPEN: the Cave's LIVE face still presents the soul's friendly (the name-gate name is only
  filed, not worn); our-box "● Captain Grav / ● Cave Guw" listing off the %Body roster; presence
  per body; and the Captain side stamping its own name on ITS %Body row.
- **E. The Repli self-lane** — the POINT of linking: the Cave's library fills from the Captain.
  Repli is keyed by Pier/Grant today; bodies have neither (twins-not-friends). Needs its own lane
  keyed on the family. Tell today: reborn Cave's radio has `total:70` but nothing it can pull.
- **F. The eed_2 squatter** — hello_ok said "family holds eed, eed_2": a third body from a dead run
  still holds a seat. Where does a family seat EXPIRE? (Relay-side binding lifetime audit.)
- **G. Runner-seat hygiene on music pages** — every Big*land tab sends `become role=runner` and binds
  `addr=runner` on the SHARED relay; Auto.svelte's own comment warns a second `runner` claimant
  "silently receives every frame meant for a human's tab". The humdinger suppresses grid visibility
  but NOT the channel bind. Audit whether a humdinger should bind `runner` at all.
- **H. Virgin-tab FSA beg** — believed fixed by the 120s valve (Butler no longer lifts mid-boot, so
  its "open share" tap survives); needs ONE virgin-incognito confirm run.
- **I. Owner-eyes / ceremony residue** — tasks #27/#47/#48; declare the sworn InvFerry/InvSeal
  assertions (e_story_declare); the parked anchor-mint mystery (`#Iz=` token extracts but
  Swarm_token_parse refuses — flip the mint line back when diagnosed; read side already shipped).
- **J. COMMIT POINT (large)** — today's diff: arrest fix, ack carve-out, valve fix, auto-receive,
  reload-terminal, done→Door, our-box, wire strip, fossil filter, InvFerry+InvSeal made real.
  Fixture rule applies: keep wormhole/Story/InvFerry/ (new) + deliberate toc rows; revert
  Credulate/Credulation/TimeSpool/gen churn.
- **K. Old-garden cleanup (someday)** — 12 husk identities in the pre-`.jamsend` layout, stale
  appcache trees, the live tab's Sounditron fixture drift (sweep-flagged, known churn).
