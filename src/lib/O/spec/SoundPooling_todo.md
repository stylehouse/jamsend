# SoundPooling_todo.md — the pool: press + reach into it, pool-first radio out, cells over it

*(Two mechanisms fill the pool — PRESS (passive, this doc's origin) and REACH (active/cross-body, §0.5 +
 `Reach_todo`) — and the cells (§0.5) surface both. Origin title kept below for continuity.)*
### (origin: the OPFS pocket cache — from ambient press to pool-first radio)

**What SoundPooling is.** When you stream a friend's track over Radio today, chunks land in
 memory and are immediately played — nothing persists past the session. SoundPooling is the
  act of pressing those played bytes (or deliberately siphoning chosen tracks) into your
   phone's OPFS so they are there OFFLINE: small LOFI copies, replayable without a peer,
    tradable phone-to-phone. The pool is a cache with a ledger — not a second library.

**THE HEIST/POOL BOUNDARY (owner, 2026-09-02) — two different acts, do not conflate:**
 - **Heist** = a CONCISE, usually-LOSSLESS acquisition between two different IDENTITIES (keeps a whole
    album together — a deliberate, structured grab). See [[ferry-cave-model]] for identity terms.
 - **SoundPooling** = a LIQUID approach to music piracy: lofi, casual, ambient, expendable — music
    kept MOVING and filling space, not a curated transaction.
 They share the Heist byte-DOER (§0.5: a pool Reach delegates carry-out to `Heist_materialise_one`),
  but they are opposite in DIGNITY — lossless-album-per-Identity vs liquid-lofi-circulation. The
   boundary law: bytes+doing belong to Heist/Repli; standing intent belongs to Reach; the POOL is the
    liquid destination, the LIBRARY is the lossless one.

**THE FORMULAS ARE THE CONTROL SURFACE (owner, 2026-09-02).** SoundPooling's character is DIALLED by
 the two formula sites in `Ghost/M/Ra.g`, and these are what we tune (not the plumbing): (1) the taste
  score `likes×3 + grabs×2 + spins×1` (`Ra_quarter_tally` ~1016), (2) the `%Pool` composition +
   take-policies + declaration-order priority (`Ra_pool_define`/`Ra_quarter_goal_pools` ~1046–1107).
    ⚠ **WATCH THE JAM SCHEMA (owner's explicit ask):** the taste score reads `%Spin`/`%Like`/`%Grab`
     events under `%Jam` sessions — that schema is LOAD-BEARING for the whole economy; a drift in the
      Jam ledger silently changes what gets pooled. Any Jam-schema change must be checked against
       `Ra_quarter_tally`'s reads.

**What already exists** (audited 2026-08-28 / Portability_todo §0 §3):
- `Ghost/M/Ra.g` — `Ra_press` (v1 byte-copy, v2 ogg128), `Ra_quarter` (steward goal/diff),
   `Ra_quarter_serve` (dispose loop: press + evict), `Ra_rec_pool` (catalog door), `Ra_upgrade_scan`
    (Cave upgrade queue). All DORMANT — Book-proven (MusuPress/MusuQuarter/MusuSteward/MusuSmuggle),
     no live caller anywhere.
- `Ghost/M/Siphon.g` — the DELIBERATE SoundPool act: `Siphon_pull`, `Siphon_tag_def/apply/unapply`,
   `Siphon_playlist`. Built 2026-08-28 (see Siphon_todo.md). Its proposed P2 connect-up seam (the
    RadioFace source-chip becoming local|pool|friend) names `Radio_source_next(n)` which does not exist.
- `src/lib/O/Housing.svelte.ts` `Wormhole_mount_pool` — the `pool/…` OPFS mount stands; a path like
   `pool/A/B/track.flac` resolves to OPFS exactly as `music/A/B/track.flac` resolves to FSA.
- `Ghost/M/Heist.g` `Heist_catalog_land` — ONE landing door for every arriving record: its pool branch
   (behind `Heist_is_pool`) fires when `mardir='pool'` + `lofi:1` + `body_hash`. Both triggers are unlit
    in live flow today. The branch is proven inert.

**The live wiring gap (the load-bearing open seam):** the press economy is model-complete. What is
 missing is the DRIVER — a live tick that hands `Ra_quarter_serve` the phone's pool nav, a lib (the
  streaming source), the pool shelf, and a cap. The `lib` mapping for a streaming phone (press what you
   stream vs press from a held library) is the delicate §3/§4 question Portability_todo holds open.
    Do NOT wire blind; the Siphon's explicit-lib choice was exactly what kept Siphon_todo out of that area.

---

## 0. Where to start, and the arc

**The destination.** Stream a friend's track; a small LOFI copy quietly lands on your phone.
 Next session, no friend online: the radio plays from the pool. Two phones meet: they swap
  pool material without a Cave. A Cave comes online: it fills pool copies out into Originals.
   The pool is the PEOPLE'S music — expendable, portable, honest about what it is.

**LANDED 2026-08-30 (this session — the ambient economy + its glass):**
- **Pools of defined size** (Ra.g → Ra.go): `Ra_pool_define(w,name,take,cap)` + `Ra_pool_defs` +
   `Ra_quarter_goal_pools` — the goal composes from `%Pool,name,take,cap` compartments (declaration
    order = priority, dedup across pools); take-policies `taste|liked|kept|latest`, all clockless.
     No %Pool declared = the old single anonymous goal (byte-identical, gate stayed green).
- **The source chip + pool rung** (Radio.g → Radio.go): `Radio_source_next(n)` cycles `'' ⇄ 'pool'`
   on `%Radio,source`; `Radio_dial_pool_local` is the SoundPool dial rung (own OPFS shelf via
    `Ra_home_pool`); `Radio_dial` obeys `source==='pool'` EXCLUSIVELY.  RadioFace's provenance badge
     is now the tappable source chip (P2 applied).
- **The ambient steward occasion**: `Radio_autopress(w,radio)` fires at a track advance, DEFAULT-OFF
   behind `top.c.pool_steward` (+`pool_steward_cap`, default 24), humdinger-gated, own-library-only
    (the §3/§4 lib-mapping tripwire respected — a shareless phone still uses the explicit Siphon).
- **The glass** (ShuffleFace.svelte): pool-mode shows YOUR pocket copies (probe-first `Ra_home_pool`),
   plus the steward want-list "what your phone wants next and why" grouped by pool compartment (§5.4).
- **Siphonation is a real gate** now (P1 registered + P3 recorded live, 6/6).
- **The pool economy Books are gates now** — MusuPress / MusuQuarter / MusuSteward / MusuSmuggle
  were authored-but-never-recorded (no wormhole dir); all four recorded live + verified green in
  check mode (each %see-asserted, single-beat).  The press/steward/upgrade model is now regression-
  fenced, not just smoke-green.
- **P1 registered**: Siphon.g + Siphonation.g in LiesLies CREDULER_GHOSTS.

**Owner-testable NOW (reload both tabs for the 388834c+ build):** tap the source chip under the
 player → it flips to "♪ SOUNDPOOL"; the ShuffleFace shows your pool (empty until pressed) + the
  steward's want-list.  Flip `H.top_House().c.pool_steward = 1` on a Cave/FSA tab and let a track
   advance → `🏊 steward: pressed N` presses `%Record,path:pool/…` rows you can snap.

**LANDED 2026-09-03 — the FIRST LIVE SOUNDPOOLING INCREMENT: the pool-fill reach, Book-gated.**
 The §0.5 realisation made real: a Captain's pool fills FROM its crew Cave by BOOKING, not calling.
- **The booking seam** — `Ra_pool_fill_book(w, ident, origId)` (Ghost/M/Ra.g, POOL-FILL REACH region):
   books `%Reach,to:Cave,of:<id>,for:serve` toward the rostered crew Cave (role-addressed so it
    survives re-keying; no Cave on the roster → no intent faked; idempotent; stands while away).
- **The live doer binding** (Reach_todo §0 "still owed" — now bound for `for:serve`): `Swarm_reach_pump`
   invokes `Ra_pool_fill_pump` (knob-gated `w.c.reach_on`, default-off) → `Ra_pool_fill_serve` presses
    the asked track from the Cave's OWN library into its own pool (`Siphon_pull` → `Ra_press` v1 →
     `Heist_catalog_land` — the one door; the §3/§4 lib tripwire honoured) and answers the sync
      tri-state verdict (`Ra_pool_fill_verdict`: arrived | not-yet | refused,'not_in_library'); then
       reports terminals once and graduates.  Foreign `for:` verbs return FALSY (left for their own
        doer — never refused by this layer).
- **The landing** — `Ra_pool_fill_land`: an outbound fill acked 'arrived' siphons the artifact out of
   the crew mirror into MY pool through the same one door (the pool branch lights, byte-faithful,
    body_hash); no mirror / no readable nav → the reach STANDS 'arrived' as visible awaiting-transport
     state, never a fake landing.
- **Book-gated** — MusuPoolFill (Ghost/Story/Heistation.g, 6 beats, recorded live, 2× green, 4 %see):
   book → road → live-doer serve → ack → byte-faithful pool %Record on the Captain → graduate — plus
    the honest refusal receipt standing on both sides.
- **What stays live-only (the named owed seam):** the real cross-device BYTE transport.  Live, the
   Captain's crew mirror has no byte-readable nav yet (the Repli/Mag lane — Reach_todo's "the Mag is
    what travels"), so a live fill today walks the whole reach + presses the artifact CAVE-side and
     the Captain sees 'arrived'; the Captain-side OPFS landing runs the moment a mirror nav stands.
      The booking GESTURE (where in the glass a fill is born) also stays owner-gated (Reach_todo §0).

**What to get on with next (fresh session reads here):**
1. **Wire the ambient steward** — `Radio_source_next(n)` + `Radio_autopress` (the press driver that
    lights `Ra_quarter_serve` at a natural play-session seam). This is the ambient economy proper
     and the one thing Siphon_todo deliberately deferred. Start here only after the §3/§4 lib
      question is resolved (read Portability_todo §3 first; do not guess the lib mapping).
2. **Record the pending Books** — MusuPress/MusuSteward/MusuSmuggle/MusuQuarter are smoke-green but
    unrecorded. These are Lane-A recording passes (runner_ask.mjs), not code work.
3. **Apply Siphon_todo P1** — register Siphon.g + Siphonation.g with the Creduler (LiesLies.svelte),
    then P3 (the recording pass for Siphonation).
4. **Apply Siphon_todo P2** — the RadioFace source chip — only after `Radio_source_next` exists (§4 below).
5. **The pool-source Radio rung** — the dial consulting pool records when `sc.source === 'pool'`.
6. **Phone↔phone exchange (Flow 3)** — a heist whose mardir is `'pool'`, destination OPFS.

**The bet to hold.** Pool↔pool exchange between phones may be the MAJORITY way music actually
 moves (Portability_todo §0). Design pool paths as PRIMARY, not as a nicety on top of the library.

**THE ECONOMY'S CHARACTER (owner, 2026-09-02) — two fills, and a gift-shaped transaction.**
 *"Not just 'stream → copy lands' — you have to LIKE it, I think? but also another bunch of stuff
  comes across whether you like it or not, just because we want to fill up the space and keep
   things moving. That's a new concept for software — everything has been paywall and static and
    transaction-driven. We want to give the user transactions like 'enjoy what you can of all this
     music' that then affect how we SoundPool for them later. And it's likely how they keep random
      music on their phone from their computer as well."*
 Unpacked, this rules the press economy's shape:
 - **Two fills, distinct in dignity:** the CHOSEN fill (liked/taste — tracks you engaged with) and
    the **CIRCULATION fill** (unchosen — music that arrives to fill spare space and keep the music
     MOVING through the mesh; expendable by design, first-evicted, no ask). Circulation is not a
      cache-miss optimisation — it is the point: the pool is how music travels.
 - **The transaction is a GIFT with a feedback loop, not a purchase:** "enjoy what you can of all
    this" (the Music grant already has this shape) — and what you then PLAY/LIKE out of the
     circulation stream shapes what gets pooled for you next (circulation → engagement → the taste
      compartment). Anti-paywall, anti-static: the ledger records enjoyment, not entitlement.
 - **Same machinery, one mapping (sketch):** %Pool compartments already carry take-policies and
    declaration-order priority — a `liked`/`taste` compartment (high priority, kept) beside a
     `circulation` compartment (fills remaining cap, evict-first, generous take); engagement
      GRADUATES a track from circulation into taste. No new machinery smell — a policy expression
       over `Ra_pool_define`.
 - **The everyday corollary:** Cave→Captain fill (Flow 4) IS the circulation stream between your
    own bodies — "random music on their phone from their computer," unasked, space-permitting.

---

## 0.5 THE REACH CHAPTER (2026-09-01) — the cross-body procedure layer this doc was hand-rolling

*(Reconciliation note: a near-duplicate doc for the multi-body music environment was drafted this day
 before this one was found, then FOLDED IN HERE and removed — one topic, one todo. They COMPLEMENT (see
  below); the generic cross-body primitive lives in `Reach_todo.md`.)*

**They do not conflict — they are two mechanisms filling ONE pool, plus the surface over both:**
 - **PRESS** (this doc, §3–§4.2) — the pool fills PASSIVELY: bytes that stream through you are pressed to
    OPFS; the ambient steward + Siphon. "What flows through me sticks."
 - **REACH** (`Reach_todo`, LANDED — SwarmBody beats 10–14) — the pool fills ACTIVELY: a body BOOKS a
    durable, addressed intent ("get me this here") that stands as legible matter, routes off the family
     charter, survives the target being offline (settles on the presence edge), and drops when served.

**The load-bearing realisation: Flow 3 (§4.3, phone↔phone) and Flow 4 (§4.4, Cave→Captain) ARE reaches.**
 Both are "move pool material from one body/peer to another, whenever they overlap." §4.4 even names the
  hand-rolled version — "steward occasions: Cave came online / library grew / Captain pool is thin … the
   daemon's digger tour→rest→tour." That per-flow occasion+resume logic is EXACTLY the Reach settle loop
    (`Swarm_reach_settle`, the 60s trickle, presence-edge re-dispatch). So:
     - a pool Heist to another body becomes `%Reach,of:<content-id>,to:<body|friend>,for:serve` — the
        booking STANDS, dispatches when reachable, and the carry-out DELEGATES to the existing Heist doer
         (`Heist_materialise_one`, `mardir='pool'`, the §4.3 landing shape — UNCHANGED). Reach adds the
          durability + addressing + offline-tolerance; the byte-transport + landing stay as they are.
     - the "Captain pool is thin → fill it" occasion becomes a reach the Captain BOOKS (or the Cave books
        on the Captain's behalf), instead of a bespoke daemon occasion per flow.
   The measure (Homethink §4): Reach REMOVES the per-flow occasion/resume machinery, replacing it with one
    primitive Flow 3/Flow 4 both ride. **Do NOT rip out the flows yet** — bind them to Reach after the
     live doer-binding proves (Reach_todo §0 "still owed"), same isolation-first discipline as everything.

**§5.4 "Door — pool legibility (future)" is now data-ready.** That deferred pool-legibility surface is the
 **cells** the owner named ("bunch of new cells to make up"), and their DATA landed this day:
  - **`%Organ`** (SwarmBody beat 14) — a body describing the organ it grows: `pocket` (ready set) vs
     `trove` (collection), as quantities on its own `%Body` row. `Swarm_organ_take` / `Swarm_organ_of`.
      This is the pocket/trove readout §5.4 + the Organ cell want. (Cross-body organ visibility — the
       phone seeing the laptop's trove — is the next data brick: organ rides the charter mile like the
        family grants do.)
  - **the crew read** (`Swarm_reach_crew`, beat 13) — the standing reaches in one legible glance, tallied
     by state. The Crew cell's data.
  - **the cells** (Crew · Pool · Organ) — belly cells alongside Door/Radio/Link, reading the above; the
     Pool cell's "pull here" gesture calls `Swarm_reach_book`. Svelte/humdinger → un-Book-provable, so
      built WITH the owner at a tab (the standing law); the data beneath is Book-gated and safe.

**So the arc, unified:** the pool is filled by PRESS (passive) and REACH (active, cross-body); the cells
 make it legible and drivable; pool-first radio (§0 LANDED) plays it back. Press and pool-first radio are
  the owner-testable NOW; Reach + cells are the new frontier this chapter opens.

## 1. What Radio does today and where SoundPooling plugs in

**The dial ladder** (Radio_dial, `Ghost/M/Radio.g`): friend-first by default (`Radio_dial_pool`
 walks `%MusuThem` mirrors), falls through to own stock only when friend pool dry OR listener
  flipped `radio.sc.own`. The dial reads `radio.c.heard` (heard-this-sitting) to avoid repeats.
   `Radio_pool_census` counts friends/known/playable/fresh honestly — the ShuffleFace reads these
    same pools visually (one pip per reachable %Record, fill = preview fraction landed).

**What the pool IS in Radio terms today:** the "pool" Radio uses is the IN-MEMORY mirror of friends'
 stocks (`%MusuThem` shelves). That is the radio-pool / shuffle-pool — a volatile runtime thing.
  The SoundPool is DIFFERENT: a durable OPFS store of pressed copies. These two uses of "pool" must
   be held clearly separate. Going forward:
- **Radio-pool / shuffle pool** = friend-mirror records in `%MusuThem`, volatile, play-over-wire.
- **SoundPool** = the OPFS `pool/…` shelf, durable, play-offline.

**Where SoundPooling plugs in:** a third source rung between "friends" and "own":

```
dial ladder:
  1. friends (MusuThem mirrors, live wire)        ← today: default
  2. SoundPool  (OPFS pool shelf, offline-ok)     ← NEW RUNG: sc.source === 'pool'
  3. own stock  (local library, sc.source === '' + sc.own)  ← today: explicit toggle
```

The source selector (`sc.source` on the %Radio particle) is already sketched in Siphon_todo P2.

---

## 2. The C-particles involved

### 2.1 The pool shelf — where pool records live

The pool is an existing concept with an existing mount, not a new container shape. Pool records
 wear **`%Record`** (the 2026-08-27 ruling, Portability_todo §3 "mainkey question BURNED") on the
  pool's own shelf — a `%MusuSelf`-shaped home standing in the radio world alongside the library
   home, but rooted at `pool/…` paths. The identity law (CLAUDE.md "identity is per-shelf") is
    satisfied because the pool SHELF is distinct: a pool %Record at `id:X,path:pool/A/B/t.wav` is
     a different holding from the library %Record at `id:X,path:music/A/B/t.wav`, even if X
      coincides (v1 byte-copy = same bytes). A v2 ogg128 press has a NEW id (different bytes →
       different enid), `of:<origId>` the cross-fidelity join, `grade:'ogg128'`.

**The catalog door** is `Ra_rec_pool(shelf, origId, lofiId, path, grade)` in `Ghost/M/Ra.g:895`.
 One door for every landing, whatever verb brought the bytes — never a parallel minter.

**The pool home particle** (to be stood):
```
%MusuSelf (or a new name — call it %MusuPool to avoid ambiguity with the library home)
  pub: <my-prepub>
  pool: 1           ← 1-or-absent; distinguishes from the library home
  stock: 1  (the shuffle Mag shelf — same paged-Mag structure Ra_rec_home uses)
```
Or: re-use the library home with the `pool` mount already standing; `Ra_home_self` returns the
 library home — the pool would want its own `Ra_home_pool(w, pub)` find-or-create. This is a
  naming call (a few lines of code); pick when the steward driver is wired.

### 2.2 Press ledger particles — transient scaffolding

`%press,of:<origId>` — the visible scaffolding Ra_press mints on `w` per press attempt (exists in
 `Ghost/M/Ra.g:980`). Transient; the pool-steward sweep is the natural drop seam. A failed
  press stays standing with the fail reason (the same discipline Siphon_pull uses for `%Siphon`).

### 2.3 Quartermaster (steward) particles

`%Provisions` — the steward's want-list container under `w`:
```
%Provisions
  %Want,of:<origId>,do:press|pull|evict,why:<tally sentence>
```
`Ra_quarter` mints/drops these idempotently. `Ra_quarter_serve` enacts them.

### 2.4 Siphon particles (deliberate act — already built)

See Siphon_todo.md §0 "the model":
```
%Tags (on the radio world)
  %Tag,name:<word>
    %Tagged,of:<origId>       ← a referring particle; many per tag
%Siphons (on the radio world)
  %Siphon,of:<origId>,phase:<asked|pulling|landed|fail:<why>>  ← transient, dropped on land
```

### 2.5 Upgrade queue (Cave-side, existing)

`%Upgrades → %Upgrade,of:<origId>` — `Ra_upgrade_scan` (`Ghost/M/Ra.g:1113`) mints these on the
 Cave's world when a smuggled LOFI copy has no Original in the Cave's library. The heist flow
  serves them (Flow 1, Portability_todo §5). No new particles needed.

### 2.6 Source control on the %Radio particle

`radio.sc.source` — a new scalar on the `%Radio` particle: `''` (default, friends first) |
 `'pool'` (SoundPool rung) | `<friend-pub>` (aimed at one friend). This is what Siphon_todo P2
  stamps via the proposed `Radio_source_next(n)` verb. The 1-or-absent rule does not apply here
   because an empty string is the valid default; the three-way enum is clean as a string.

**Identity rule check (CLAUDE.md):** `%Radio` is already a face particle (one per world, its
 mainkey = state), and `sc.source` is a scalar on it. No new mainkeys needed; no identity violation.

---

## 3. The req-machine wiring

### 3.1 The ambient steward (what to build)

The steward is SCHEDULEY (Portability_todo §3): it does not run on every play, only on OCCASIONS.
 The right occasions: a play-session ends, a jam session concludes, the Cave becomes reachable,
  the tab has been idle for a while.

**Proposed shape — a permanent req that re-arms on occasions:**

```
req:PoolSteward (permanent, one-per-ghost in the radio world)
  on_occasion():
    Ra_quarter_serve(w, nav, shelf, pool, lib, cap)
  finished when: the round completes (a single oai-idempotent sweep — fast)
  re-armed by: play-session-end, jam-end, Cave-reachable tick
```

The steward is NOT reactive (not a wake-per-event) and NOT a timer. The right trigger for the
 first version is a seam already fired by Radio: when `Radio_state(radio, 'off')` or when a
  track finishes (`tape-out` path). `Ra_quarter_serve` is already idempotent; calling it at a
   session boundary is safe and cheap (it computes the diff and presses only what changed).

**The lib mapping question (the delicate gap, Portability_todo §3 ⚠):** `Ra_quarter_serve`'s
 `lib` arg is "where to read Original bytes from." For a phone-with-no-library this is the
  friend's share (the streaming source). That mapping is the open §3/§4 question. Until it is
   resolved, wire the steward only for the case where `lib` is the OWN library (a Cave or a tab
    with FSA granted). A shareless phone gets the Siphon's EXPLICIT lib instead (Siphon_todo rung
     3). This is a deliberate non-wiring, not a TODO to ignore.

**Req lifetimes:**
- `req:PoolSteward` — `permanent` (one owner per radio world, holds its occasion write)
- `req:PoolPress,of:<origId>` — `transient`, minted per `Ra_press` attempt, dropped on land
   or fail (the `%press` scaffolding is the visible form; this req is the hold)
- `req:PoolEvict,of:<id>` — `transient`, minted per eviction, dropped on completion

### 3.2 The source rung in Radio_dial

`Radio_source_next(n)` — the cycle verb (Siphon_todo P2 names it): stamps `radio.sc.source` on
 the %Radio particle, cycling `''` → `'pool'` → `<friend>` → `''`. The dial consults
  `sc.source` at the top of Radio_dial and dispatches:
```
if sc.source === 'pool':   Radio_dial_pool_local(w, radio)  ← new: reads the OPFS pool shelf
elif sc.source is a pub:   Radio_dial_aimed(w, radio, pub)   ← aim-locked to that friend
else:                      current ladder (friend-first, fallback own)
```
`Radio_dial_pool_local` is a thin read over `Ra_home_pool(w, pub)` — the same Ra_recs walk
 `Radio_dial_pool` does over MusuThem, but against the OPFS pool shelf. No new machinery; new
  two-liner.

### 3.3 ShuffleFace extension

ShuffleFace already shows the "radio-pool" (friend mirror records). When `sc.source === 'pool'`
 it should show the SoundPool instead — same pip idiom, same presence gate (does the pool
  record have bytes on the OPFS mount?). The source switch makes ShuffleFace polymorphic over
   the active source. This is a view-layer change, no new particles.

---

## 4. How peers contribute and draw from the pool

### 4.1 The ambient press (local-library → OPFS)

Source: your own library (a Cave or FSA tab) copies a track into OPFS.
Verb: `Ra_press` (v1 byte-copy, deterministic, already built).
Driver: `Ra_quarter_serve` at the steward occasion (§3.1).
Wire: none — this is PURELY LOCAL. No peer exchange.

### 4.2 The Siphon (deliberate pull from a friend's share → OPFS)

Source: a friend's share you are browsing (explicit lib, not ambient).
Verb: `Siphon_pull(w, shelf, pool, lib, origId, nav)` in `Ghost/M/Siphon.g:152`.
Wire: uses the existing radio/Repli chunk machinery (the track is already streamable; the siphon
 reads the bytes that would have played and writes them to OPFS instead).
State: `%Siphon,of:<origId>,phase` — legible, transient.

### 4.3 Flow 3 — phone↔phone pool exchange (the majority transport)

Two phones in a room swap SoundPool material directly: LOFI only, no Cave required.

**Mechanism (the Portability_todo §5 ruling):** a Heist whose `mardir = 'pool'` and whose
 destination nav is the OPFS pool nav. The Heist machinery is already parameterised over any
  nav (the loosened landing head); what is missing is the UI gesture and the pool-destination
   wiring in the Heist setup path.

**The exchange is a Heist, not a new protocol frame.** The existing Repli machinery moves the
 chunks; consent rides the existing Swarm grant (`%Invite:Music` or a new pool-exchange feature
  flag if the policy needs separating). The landing catalogues through `Heist_catalog_land` with
   `mardir='pool'`, which lights the EXISTING pool branch.

**Particles involved:** the same Heist ledger (`%Caper,at:<pier>`, `%Pick,ref:<id>`) plus the
 pool branch's landing shape (`%Record,of:<origId>,grade:ogg128,lofi:1,path:pool/…`). The
  `of:` join is what makes a received pool copy simultaneously listenable (LOFI, now) and an
   INTRODUCTION: the receiving Cave can later fetch the Original (Flow 1, `Ra_upgrade_scan`).

**Network exchange:** rides existing Swarm gossip + Repli — no new frame kind. The pool exchange
 is a NEW OCCASION for a Heist, not a new wire protocol.

### 4.4 Flow 2 — Cave → Captain pool fill

A Cave that holds a library presses LOFI copies and sends them to the Captain's OPFS pool over
 the wire. Mechanically: `Ra_quarter_serve` on the Cave side, `mardir='pool'`, the Captain's
  address as destination. The Heist send path already exists; the pool destination needs the
   `pool/…` mount wired on the RECEIVING (Captain) side, which already stands (`poolmount`).

The steward occasions for this are Cave-side: "Cave came online", "library grew", "Captain pool is
 thin". These are daemon-level occasions; the daemon's `digger` pattern (tour→rest→tour) is the
  standing precedent.

---

## 5. How it surfaces in the glass

### 5.1 RadioFace source chip (Siphon_todo P2 — proposed, not applied)

The `{#if face.by}…{/if}` provenance block in `src/lib/O/ui/RadioFace.svelte` becomes the
 **source selector**: tap it to cycle `''` → `'pool'` → `<friend>` → `''` via
  `Radio_source_next(n)`. The chip names the live source and flips between what stands.

The exact patch is written in Siphon_todo §"proposed patches" P2 — apply by hand after
 `Radio_source_next` exists.

### 5.2 ShuffleFace — pool mode

When `radio.sc.source === 'pool'`, ShuffleFace shows the OPFS pool shelf pips instead of the
 friend-mirror pips. One toggle in the derived computation (same `Ra_recs` walk, different
  shelf). The presence gate stays the same (`Radio_playable` checks chunk 0 — which, for an
   OPFS pool record, means the bytes are locally present, never a latency question).

### 5.3 SiphonFace (rung 5 of Siphon_todo — not yet built)

A new face (`Ghost/M/SiphonFace.svelte` or inline in `Siphon.g`) listing pooled tracks with
 tag chips and a define-a-tag affordance. Hidden behind the RadioFace source chip. Props {n, H}
  per the glass convention. Reads `%Tags` and the pool shelf; calls `Siphon_tag_def/apply/unapply`.

This face does NOT exist yet. It is rung 5 of Siphon_todo. Design it there; point here for
 the SoundPooling arc context.

### 5.4 Door — pool legibility (future)

`%Provisions → %Want,of,do,why` is already the legible want-list. A Door section showing
 "what your phone wants next and why" is a pure read over these particles — no new model
  work. Defer until the steward is live and the list has something to show.

### 5.5 The cross-body cells (the Reach chapter's surface — data landed 2026-09-01)

Three belly cells alongside Door/Radio/Link (the Sounditron organ ladder + Cellui), each reading a
 Book-gated data verb; Svelte/humdinger so built WITH the owner at a tab (the standing law). Spec'd here
  so the build is a fill-in, not an invention:
- **Crew** (`CrewFace.svelte`) — the soul across its machines. READS `Swarm_reach_crew` +
   `Swarm_body_roster` (roles + presence off `sc.heard`) + `Swarm_organ_of` (sizes). SHOWS a row per body
    (mine dimmed): role badge · presence dot (here/fading/away) · organ size ("214 ready" / "38k trove");
     beneath, the reaches in flight with state glyphs (booked ⋯ / serving ↯ / arrived ✓ / refused ⚠).
      This is DoorFace's family box grown into the full crew view. DRIVES: away-body forget ✕ (built);
       refused-reach dismiss.
- **Pool** (`PoolFace.svelte`) — SoundPooling proper: the union trove across the roster, deduped by
   content-id, each track tagged with which body/bodies HOLD it. A track not on THIS body shows "pull
    here" → `Swarm_reach_book(w, self, {to:<this body>, of:<content-id>, for:'serve'})`; the fill
     progresses as the reach serves (its state shown inline, the crew read filtered to the track).
- **Organ** (`OrganFace.svelte`, or a strip in Crew) — pocket vs trove as quantities + top tags +
   offline/served, per body. "A body describing the organ it grows."

---

## 6. The smallest demonstrable first slice

**Do this first to prove it works:** apply Siphon_todo P1 (register Siphon.g + Siphonation.g),
 do the P3 recording pass, then wire `Radio_source_next(n)` as a three-state cycle and test it
  live: with a friend's share open, tap the source chip, confirm `radio.sc.source` flips in the
   snap (`runner_ask snap 1`), and confirm `Radio_dial_pool_local` returns records from the pool
    shelf (even if empty, it must not throw). That is the end-to-end cycle proved.

The FIRST LIVE PRESS to verify bytes actually land: run `Ra_quarter_serve` manually from a story
 step or a runner_ask one-shot, with a known lib, pool nav, and cap=1. Inspect `runner_ask snap`
  for the `%Record,path:pool/…,body_hash:…` row in the pool shelf. No face needed; the snap is
   the proof.

**Build order:**
1. Record pending Books (Lane A — editor passes, no code).
2. Apply Siphon P1 + P3 (register, record).
3. `Radio_source_next(n)` verb + `Radio_dial_pool_local(w, radio)` (new rung, ~20 lines).
4. Apply Siphon P2 (source chip).
5. `Radio_autopress` — the ambient press at play-session end (resolve §3/§4 lib first).
6. ShuffleFace pool-mode extension.
7. SiphonFace (Siphon_todo rung 5).
8. Flow 3 — phone↔phone exchange (the Heist-to-pool seam).

---

## 7. The bombs (what detonates if the next fork doesn't know)

- **The lib mapping is the live tripwire.** `Ra_quarter_serve`'s `lib` for a streaming phone is
   NOT its library (it has none). Guessing it = undefined behaviour. Read Portability_todo §3 ⚠
    before touching `Radio_autopress`.
- **Pool records must route through `Heist_catalog_land` — never a parallel minter.**
   `Ra_holding_keys()` is the one authority; a bespoke press-minter re-opens the forty-five-seams
    flaw. One door, always.
- **v2 (ogg128) press is not bit-reproducible** — two presses of one Original yield different bytes.
   A Book asserting the real v2 press cannot be a byte-exact fixture. Use the pinned-stub shape-Book
    pattern (Portability_todo §3 "determinism trap"). v1 (byte-copy) IS reproducible — book it normally.
- **Snapped booleans: `pool:1` not `pool:false`.** Every presence flag on new particles rides as
   `1` or ABSENT. Never `false`, never `0` in sc.
- **Objects and functions only in `.c`, never `.sc`.** The pool nav is `.c.ra_nav` (the existing
   pattern, `Ghost/M/Ra.g:884`); never store it in `sc`.
- **A cold tab runs no beats.** Live pool behaviour is humdinger-gated (the same law Radio_autopress
   would follow). A Book that exercises the pool model must stub the nav and press synchronously.
- **OPFS is evictable.** The pool is designed expendable; a re-press from its Original is always the
   recovery path. `navigator.storage.persist()` is the cheap mitigation (Portability §0.9b).
- **ShuffleFace is read-only.** It must never write; a render that calls `Ra_home_pool` (an oai)
   would mint a home on a mere poll. Probe first (`oa`), then read.
- **The pool is NOT replicated** (Portability §2E ruling 6). Replication ignores it; pool material
   crosses as APP FLOWS (heist-rides, steward-decided). Never add the pool shelf to Repli targets.
   **→ This is exactly why REACH fits (§0.5):** a reach IS an app-flow (a booking riding a Heist doer),
    NOT replication — so Flow 3/Flow 4 riding Reach honours this ruling, they do not violate it.

**The cross-body forks (from the Reach chapter — decide when you can SEE them, not before):**
- **Auto-restock vs explicit.** Does the pocket auto-fill from the trove (the bloodstream — Division
   §PURPOSE), or only on an explicit pull? Auto is the magic but it's a policy with backpressure teeth
    (it's the Reach cousin of the §7 lib-mapping tripwire). Decide when the Pool cell is real and you can
     watch it fill.
- **Ear bodies** (a phone with NO library, all reach). A first-class role, or a Captain with an empty
   pocket? Affects the roster/organ shape.
- **Cross-SOUL pooling** (a friend's trove in your pool, by grant) vs only your own bodies. Reach
   `to:<friendpub>` already addresses it; the policy (whose music appears in MY pool) is the open question.

---

## 8. Reference — existing file locations

| thing | file | lines |
|---|---|---|
| `Ra_rec_pool` — catalog door | `Ghost/M/Ra.g` | ~895 |
| `Ra_press` — byte-copy + ogg128 driver | `Ghost/M/Ra.g` | ~925 |
| `Ra_quarter / Ra_quarter_serve` — steward | `Ghost/M/Ra.g` | ~1060 |
| `Ra_upgrade_scan` — Cave upgrade queue | `Ghost/M/Ra.g` | ~1113 |
| `Heist_catalog_land` — one landing door | `Ghost/M/Heist.g` | ~950 |
| `Siphon_pull` + tag model | `Ghost/M/Siphon.g` | ~109, ~1 |
| `Radio_dial_pool` — friend-mirror rung | `Ghost/M/Radio.g` | ~2061 |
| `Radio_pool_census` — honest count | `Ghost/M/Radio.g` | ~2109 |
| `Wormhole_mount_pool` — OPFS mount | `src/lib/O/Housing.svelte.ts` | ~2550 |
| ShuffleFace | `src/lib/O/ui/ShuffleFace.svelte` | 1 |
| RadioFace + source chip (proposed P2) | `src/lib/O/ui/RadioFace.svelte` | ~150 |
| Portability_todo §3 (lib mapping ⚠) | `src/lib/O/spec/Portability_todo.md` | ~869 |
| Siphon_todo (rungs, proposed patches) | `src/lib/O/spec/Siphon_todo.md` | 1 |
