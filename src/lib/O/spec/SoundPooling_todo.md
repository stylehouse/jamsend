# SoundPooling_todo.md — the OPFS pocket cache: from ambient press to pool-first radio

**What SoundPooling is.** When you stream a friend's track over Radio today, chunks land in
 memory and are immediately played — nothing persists past the session. SoundPooling is the
  act of pressing those played bytes (or deliberately siphoning chosen tracks) into your
   phone's OPFS so they are there OFFLINE: small LOFI copies, replayable without a peer,
    tradable phone-to-phone. The pool is a cache with a ledger — not a second library.

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
- **P1 registered**: Siphon.g + Siphonation.g in LiesLies CREDULER_GHOSTS.

**Owner-testable NOW (reload both tabs for the 388834c+ build):** tap the source chip under the
 player → it flips to "♪ SOUNDPOOL"; the ShuffleFace shows your pool (empty until pressed) + the
  steward's want-list.  Flip `H.top_House().c.pool_steward = 1` on a Cave/FSA tab and let a track
   advance → `🏊 steward: pressed N` presses `%Record,path:pool/…` rows you can snap.

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

---

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
