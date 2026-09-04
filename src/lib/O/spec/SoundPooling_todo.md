# SoundPooling_todo.md — the pool: press + reach into it, pool-first radio out, cells over it

## 0. WHAT TO GET ON WITH NEXT — PUT THE FEATURE IN ONE PLACE (2026-09-04, the owner's)

*"lets move all those into unison? SoundPooling/Pool/* should have its scheme and content|state and
 everything it has?"* — yes, and it is worse than it looks. **SoundPooling lives in FOUR homes today:**

| part | where it lives now |
|---|---|
| the **declaration** | `%Identity > %Pools > %Pool,name,take,cap,salt,who,share` (`Ra_pool_home`) |
| **consent + budget** | `%Pools > %Consent,at` · `%Pools%budget_mb` |
| the **want-list** (its running state) | `w > %Provisions > %Want,of:<id>,do:press|pull|evict,why` — on the world floor |
| the **material** | `w > SoundPile,pub:<me> > stock,pub > Mag:shuffle > Cloud,page > Record,id,of,grade,path:pool/…` |

**The unison:**

```
SoundPool,pub:c0de,budget_mb=200          ← ONE home for the whole feature
  Consent,at:1788400000
  Pool,name:circulation,take:random,cap:12,salt:3,who:crew,share:50
  Pool,name:recent,take:recent,cap:50,share:50
  Provisions
    Want,of:9a3c…,do:press,why:took it — carried
  stock,pub:c0de
    Mag:shuffle > Cloud,page:N > Record,id,of,grade,path:pool/…
```

### Where it hangs is the whole decision — and the mechanics were checked, not assumed

**Hang it under `%Identity`.** Then the declaration keeps its account-snap home (the second durable home
 beside the Dexie stash) and `Swarm_restash_pools` walks it one level deeper, unchanged in shape.
The obvious fear — that pool churn now rewrites the whole account file on every press, inside the beliefs
 mutex — **does not happen**: Auto.svelte's account-write `mark` is built from `ident.version`, and
  `bump()` does NOT propagate upward (`TheX.bump_version` touches its own `serial_i` only), so a mint under
   `SoundPool > stock > Mag > Cloud` bumps that Cloud's X and nothing above it.

Two consequences, both to decide with open eyes:
1. **The pooled catalog would ride the account snap** — ~30KB at 200 tracks. Cheap, and arguably right: it
    is what is actually on this device. `dontSnap` on `stock` would prune it, at the cost of making the
     pool unreadable from a snap, which is the wrong trade for the one shelf a person might want to audit.
2. ⚠ **A latent bug this exposes, which is TRUE TODAY and not caused by the move**: a pool declaration
    change does not trigger an account write at all. Minting `%Pool` bumps `%Pools`' X, never the
     identity's, so the declaration only reaches disk when something ELSE bumps the identity. The stash
      pillar is doing all the real work; the account copy is incidental. Worth fixing (bump the identity on
       a declaration change) whether or not the unison happens.

### What it touches

`Ra_home_pool` · `Ra_pool_home` · every `Ra_pool_*` verb · `Ra_quarter`/`_diff`/`_serve` (the
 `%Provisions` home) · `Swarm_restash_pools`/`_pools_rehydrate` · SwarmReboot · PoolFace · and every pool
  fixture. **Bigger than the `Musu` rename sweep** ([[musu-prefix-rename-ruled]]: `MusuSelf`→`Mine`,
   `MusuThem`→`Theirs`, `MusuPool`→`SoundPile`) — all three landed 2026-09-04. Do them as ONE pass, since both rewrite the
    same fixtures — and note that once the feature IS one home, **`SoundPooling` becomes an honest name for
     it** (the objection to that name was only that a reader would look for the compartments underneath and
      not find them; here they are underneath).

**Ordering**: after `Radio_circuit_todo.md`'s heard circuit lands (in flight 2026-09-04), then the rename +
 unison as one sweep. See also that doc's §7.8: whether the pool should exist AT ALL on a device that has a
  folder — if the answer is no, this home only ever stands on a phone, which simplifies everything here.

---

## 0.1 THE DECISION (2026-09-03, the owner's — everything below is history or machinery)

**SoundPool is one sentence, and the sentence is the whole UI:**

> *SoundPool keeps rolling **[ 300 ] MB** of music in browser storage, sourced from **[ ] friends** (less
>  predictable) and **[x] crew** (your devices, see Door).*

Under it, the framing: *"just whether they want surprise music in their daily playlist."* And the reason the
 owner wants it at all: **the lofi transcode levels the volume** (verified: -14 LUFS, both serve paths).

**What the sentence means, in the machine (all built, all Book-green tonight):**
- **The number is the consent.** 0 = off and clean out (`Ra_pool_off`: the yes taken back, budget 0, every
   compartment dropped, every pooled card AND its file gone — `nav.bin_rm` → `Ra_pool_unfile`). A number =
    the yes (`Ra_pool_start(w, mb, now, who)`): a `%Consent` and `budget_mb` on the %Pools shelf, and ONE
     compartment, `rolling`, `take:'random'`, at 100% of the budget. Caps are derived (~4 MB a lofi track),
      never set by hand. Nothing that touches bytes — the catch, the steward's press/evict, the fills — runs
       without the yes; the yes rides the pools pillar so a phone is asked once and never wakes up pooling.
- **The two checkboxes are `who`**: friends (mirrors of non-crew sharers — new to me), crew (mirrors of
   my own crew — my collection spread across my devices), both, or neither. `Ra_pool_sources` marks each
    holder crew-or-not off /Crew; `Ra_quarter_goal_pools` filters on it.
- **"Keep what I hear" is negated** (you already heard it): random from everyone is the default draw, a
   clockless shuffle re-drawn per salt. The `take:'radio'` catch stays built and gated, not offered.
- **♥ is the heist button.** `Radio_like` stamps `take` on the track's Card in `Mag:heard` (`Heard_take`,
   `Ghost/M/Heard.g:216`) — durable the instant it lands, and mints nothing else; with a share mounted the
    share beat (`Heard_haul_beat`) turns the oldest take per holder into one live keep, pulling in the
     background (no form, no glass seize); without one the take stands for the crew or the pool to live
      out. (Before 2026-09-04 this minted a `%Like` under a `%Jam` ledger and a `%Heist` right here — both
       gone, see `Radio_circuit_todo.md`.) A pool keep starts itself, takes ONE track not the album,
        forced lofi (`Heist_keep_pool_go`).
- **The seam is one scalar**: `into:'pool'` on the keep → `Heist_keep_mardir` → the same Heist transport and
   the same landing tail (`Heist_catalog_land`'s pool branch). No second lane.

**Gates:** MusuPoolRadio (6 beats, 11 sworn — the catch, the guards, the goal, the one sentence, the who,
 off), MusuPoolBytes (4 beats — a keep's bytes land under pool/ and off takes them back), MusuPoolRandom,
  MusuPoolFill, SwarmReboot (the pools pillar). `Ra_pool_defs` now lists a 0-share pool (declared but inert).

**What is deliberately NOT in the sentence, and why:**
- Several compartments with fractions "in a gang" (shares, `Ra_pool_share_set`, `Ra_pool_caps_apply`) — built
   and Book-proven, then set aside: the fair-share question it raises (an unfillable pool must not hold the
    others back, yet should reclaim its space one day — water-filling) is real and unsolved, and one pool makes
     it moot. It comes back on the day of *"20% chill, for your entire music collection"* — composition by
      specifics of a remote collection.
- Knobs (steward/fills/sit-down), want lists, ids on the face — internals. The yes IS the fills switch.

**Comms on the Radio are minimal by ruling** (owner 2026-09-03: "SOUNDPOOL / setup / is empty — just the most minimal effective comms"): the chip is the word; under it one word of state — `setup` (a button to the cell) or `empty`; the dial's pool note is `empty`. A table of the app's wordier speeches is in `Speeches_todo.md` for the owner to chop.

⚠ **Not understood yet, do not "fix"**: a Sounditron mounts BOTH UI:Vyto and UI:Cello (Otro mounts every registered UI; "show guts" reveals the Vyto under the Cello). Whether that is a cost, a design, or an accident is an open question — investigate before touching.

**THE LIVE WALK (the one thing only the owner can do — once, after the overnight pass):**
1. On the Cave: open the SoundPool cell (the `setup` word under SOUNDPOOL on the Radio), type 300, tick crew. Expect one console line: `🏊 SoundPool keeps rolling 300 MB from crew`.
2. Listen to the Captain for a few tracks. Expect `🏊 steward: booked N circulation fill(s)` at a track advance, then `⇊` lines as keeps pull, then `🏊` cards landing. If nothing after ~2 min: paste the console.
3. Press ♥ on a track. Expect `♥ liked … — no share here; the crew or the pool lives it out` on a Cave, or `— heisting in the background` on a body with a share.
4. Flip the Radio source to SOUNDPOOL. Expect play from pool copies (levelled). If it says `empty`, step 2 did not land — paste the console.
5. Reload the Cave. The sentence must still read 300 / crew (the pillar). Type 0. Expect the off line with pools/cards/files counts and the pool/ folder gone.

See also **** — likes → heists → batch per holder, what berth is actually for, and the `take:'recent'` acquisitions input the owner asked for.

See also **`Acquisition_todo.md`** — likes → heists → batch per holder, what berth is actually for (three caches, one of them the music-tree Census), and the `take:'recent'` acquisitions input.

**Next (in order):** the live walk on the Cave (declare 300 MB from crew, listen, watch `🏊` lines, flip the
 source chip to pool, hear it play offline); the "later" half of the Like (a Cave with a disk reading the
  crew's Likes and hauling them); "how full is it" on the sentence; the aim on the source chip as the day-one
   "point it places"; the Radio busy-loop's cousin, Stoker_churn resetting on every dry pass.

## 0.1 THE RADIO CRUX (owner, 2026-09-03 night — kept verbatim-ish; the design in §0 came out of it)

- **The unit of consent is SPACE, not a track count.** "Aim for 3GB… or less than 1/3rd of what Chrome thinks
   it can use." The first visit sets a byte budget; the same control must go back to **0 = off, and clean it
    all out**. Explained in **20 words max** — "splash-with-simple-buttons", and the splash PERSISTS as the
     top of the Pooling UI proper, it is not a one-time modal. Reached by a **separate button**, never by
      pressing the source switcher again.
- **"Keep what I hear" is negated.** You already heard it; the pool exists to give you what you have NOT.
   So the default is **random**, on by default once consented — "take another random bunch of Records".
- **The one real decision to present**: should the pool be (a) **random friends' tracks, to hear for the first
   time**, (b) **sourced from your Crew** — your own collection, possibly spread across several devices —
    or (c) **both**. That is the whole setup UI: budget + this choice.
- **There is no LIKE button — it is download or nothing.** The shape it wants: a Like is a DURABLE INTENT on
   the ledger (`%Like` under `%Jam`, which the taste tally already reads). If the liker has FSA, the Heist
    happens on the spot into the library (lossless). If not — a Captain "with no FSA but an ear for the
     music" — it happens LATER, when a Cave of the crew looks for things to do with ITS FSA. The crew's
      disk fulfils the crew's ear. **Built the same night**: the ⇊ button IS the ♥ now — `Radio_like` mints the
       Like and, with a share mounted, flips the same keep straight to pulling (dose off, no form, no glass
        seize — the Haul cell is a folded row while it lands); without a share the Like stands on the ledger.
         Owed: the "later" half — a Cave with a disk reading the crew's Likes and hauling them. (`%Like`
          and the `%Jam` ledger were deleted entire 2026-09-04; `Radio_like` now stamps `take` on
           `Mag:heard`'s Card instead — see `Radio_circuit_todo.md`. The "later" half is still owed.)

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
  score, now `take×3 + keep×2 + mire×1` (`Ra_quarter_tally` ~1060, delegating to `Heard_tally`,
   `Ghost/M/Heard.g:290` — was `likes×3 + grabs×2 + spins×1` before 2026-09-04), (2) the `%Pool`
    composition + take-policies + declaration-order priority (`Ra_pool_define`/`Ra_quarter_goal_pools`
     ~1071–1309).
    ⚠ **WATCH THE HEARD SCHEMA (owner's explicit ask, formerly "the Jam schema"):** the taste score
     reads `take`/`keep`/`mire` off `%Card` rows under `Mag:heard` — that schema is LOAD-BEARING for
      the whole economy; a drift there silently changes what gets pooled. `Jam.g` and its `%Spin`/
       `%Like`/`%Grab` events under `%Jam` sessions were deleted entire 2026-09-04 — see
        `Radio_circuit_todo.md`. Any Heard-schema change must be checked against `Ra_quarter_tally`'s
         reads.

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

**THE START (owner 2026-09-03: "it needs a lot of Book testing it moving noise around, unit testing style…
 and a quick UI for resnapping and seeking to the SoundPooling datastructure") — the ladder, then the glass:**

*The seek UI is LANDED (Storui.svelte):* the 📸 resnap popup and the main diff header carry **🏊 pool** and
 **🏴 crew** seek buttons — each press jumps the diff body to the NEXT line naming that structure (pool
  `%Record,path:pool/`, `%Pool,name`, `%Reach`, steward/siphon/pocket/trove; or /Crew, Grant:Crew, %Body,
   %Pier), highlights it, and says `pool 2/7`. Pure DOM over the rendered rows; scoped to whichever diff body
    the button lives in. Resnap a step, press 🏊, watch the noise move.

*The noise ladder — one Book per move, single-beat where possible, ONE %see each, seeded (no Date.now /
 Math.random on the Book path), noise = generated PCM under the Book's marrauding root (the Siphonation /
  MusuPress idiom). Existing gates in [brackets]; NEW ones are the work:*
1. [MusuPress] press one own-library track → a pool `%Record` (lofi v1, body_hash).
2. [MusuQuarter / MusuSteward] the goal composes from `%Pool` compartments; the steward wants the right next.
3. [MusuPoolFill] Captain books `%Reach,for:serve` → Cave serves from its own library → 'arrived' + refusal receipt.
4. **MusuPoolBytes** — THE OWED LANE: the served artifact's BYTES cross to the Captain's OPFS (the "Mag travels"
   transport over the crew mirror / Repli lane). Today's fill ends Cave-side with 'arrived' standing; this Book
    is red until bytes land Captain-side (`%Record,path:pool/…` with the same body_hash on BOTH identities).
     Author it first — it is the Book that forces the transport to exist.
5. **MusuPoolSwap** — Flow 3, phone↔phone: two FRIENDS (no crew), A holds a pool copy, B books a reach for it,
   A serves it from its POOL (not its library — the pool is the people's music), B's pool gains it. The
    tripwire: a shareless phone still serves pool copies.
6. **MusuPoolEvict** — cap + take policy: fill past `%Pool cap` → the lowest-priority compartment's oldest
   copy evicts; declaration order = priority; `taste|liked|kept|latest` each proven by one arrangement.
7. **MusuPoolRadio** — `%Radio,source:pool` with no friend online dials from the pool; source '' ignores it.
8. **MusuPoolUpgrade** — a Cave online fills a lofi pool copy out into an Original (§2.5 queue): pool → Originals,
   the copy retired, the Original wearing the pool's provenance.
9. **MusuPoolDaemon** — the same ceremony with the daemon as the Cave (Crew_todo §0.3): a headless crew member
   serving reaches while the phone sleeps. Needs the %Ferry-only ceremony state (Crew_todo §0.0 "half-spined").
Each: Heistation.g (the Musu* home), recorded on the LIVE runner, wormhole dir committed with toc + snaps.
 Verify a fill by `runner_ask snap <n>` + the 🏊 seek, never by log lines.

**A BOOKING NOW SURVIVES A RELOAD (2026-09-03).** `%Reach` became the sixth stash pillar
 (`Swarm_restash_reaches` + `Swarm_reaches_rehydrate`, gated by the SwarmReboot Book). Until then a
  standing booking lived only in the account snap — which a PHONE never writes (no folder ⇒ no nav), so
   every booked fill died at the next boot and "book it and walk away" was false on exactly the device
    SoundPooling is for. Terminal reaches are deliberately NOT carried: a settled fill is history.

**LANDED 2026-09-03 NIGHT — THE RANDOM POOL, POOL CRUD, THE POOL CELL (owner: "take SoundPooling all the way
 through CRUD if you like, of Pools, start with one that just acquires random whole LOFI tracks from all
  Piers|Crewmates" · "perhaps just another cell when there's any Crew").**
- **`take:random`** (Ra.g `Ra_quarter_goal_pools(shelf, pools, sources)`): the CIRCULATION fill. Draws from
   `Ra_pool_sources(w)` — every %Theirs mirror's stock shelf (a crate stands only for a body that shared with
    me, so crew and friends alike) — in a CLOCKLESS shuffle: `Ra_pool_hash` (FNV-1a over `name:salt:id`) orders
     the draw, so it is the same every sit-down and in every fixture; `%Pool,salt` is the human's "shuffle again".
      Each want names its holder (`Want,from:<name>`; the goal row carries `from`).
- **The bridge** `Ra_pool_fill_wants(w, ident)`: every pull-want that names a holder books `%Reach,to:<holder>,
   of,for:serve` (`Ra_pool_fill_book(w, ident, id, to)` — a ROLE target must stand on my roster; a NAMED holder is
    the address itself). Declaring the pool IS the consent. Live: `Radio_pool_steward` passes the sources and,
     under `w.c.reach_on`, books the fills. The reach road/report/dispatch now admit a **Music-granted FRIEND** as
      they admit kin (the people's music — a shareless phone still serves pool copies); a stranger is refused.
- **CRUD**: `Ra_pool_define` (C+U, resize in place) · `Ra_pool_defs` (R, declaration order) · `Ra_pool_drop` (D; its
   wants fall out at the next sit-down, pooled copies become evict wants). `Ra_pool_home(w)`: on the LIVE radio
    world the %Pools shelf lives on the live self's IDENTITY (the account snap carries it; a phone: OWED a pools
     stash pillar — the seventh — until then a folderless device loses its pool definitions at reload); a Book /
      lone world keeps them on the world.
- **The Pool cell** (`%Pooling,face:'Pooling'` on the radio world, `PoolFace.svelte`, grappled on live tabs once
   anyone shares with me — humdinger-gated so every Sounditron fixture stays byte-identical): the compartments
    (name · take · cap · wanted · 🔀 reshuffle · ✕), the wants per pool with their holders, "＋ random from
     everyone" / "＋ what I liked" presets, a define form, and the two knobs (steward · fills) + "sit down".
- **Gate: MusuPoolRandom** (Heistation.g, 4 beats, 5 sworn): 8 reachable from 2 holders → 3 pull-wants naming
   holders, never my own shelf · the same draw twice, a new salt a new draw · the wants book toward their
    holders (crewmate at its body name, friend at its pier), idempotent · the friend road admits Cap, refuses a
     stranger, reports back over the pier · resize / list / drop / fall back to the anonymous pool.
- **A REVIEW PASS RAN OVER IT THE SAME NIGHT** (an opus agent, code-read). Fixed: the landing read only the
   crew Cave's mirror, so a FRIEND-served circulation fill could never land (`Ra_pool_fill_from` now resolves
    the holder off the reach's `to:`, probe-first — on a phone with friends and no Cave every fill used to
     stall at 'arrived'); a re-used `%Want` kept a stale `pool`/`from` (both are deleted when the fresh diff
      row has none); `Ra_pool_defs`/`_drop` now read and drop from BOTH homes, so a pool minted before the
       live self hydrated is not orphaned on the world; bookings are BUDGETED (4 per pass) so a cap-12 pool
        cannot crowd the shared %Reach cap; a holder name must look like a key-derived prepub, so a Repli
         placeholder ('Crowd') can no longer vivify a station %Pier; PoolFace probes the pool home instead of
          minting it in a render effect, and its "sit down" cannot latch the steward on.
   ⚠ STILL OPEN from that review: nothing binds a reach's `by` to the frame's actual sender — the friend arm
    now demands a full key-derived prepub before it will prefix-match, which closes the one-character match,
     but a real authentication of `by` is owed (it is the same shape as the voucher gate).
- **Gate RECORDED + check-green** (2026-09-03 night): MusuPoolRandom 4 beats, 5/5 sworn, caveat 0 on a second
   run against its own fixtures.
- ✅ **THE POOLS STASH PILLAR (the seventh) LANDED** the same night: `Swarm_restash_pools` +
   `Swarm_pools_rehydrate`, in `Swarm_restash_all` and the `Swarm_station_up` ladder. A %Pool is a
    DECLARATION and it homed on the identity, which rides the account snap — and a phone never writes one,
     so every compartment a phone declared died at its next boot and the circulation stream stopped
      silently on exactly the device this is for. Gated by SwarmReboot (declare two → wipe → rehydrate →
       swear them back IN DECLARATION ORDER, since order is priority, with policy, cap and salt intact).
- NEXT on this thread: **MusuPoolBytes** (the byte lane — still the Book that forces the transport to exist);
   the pools stash pillar; the location pool (`take:dir`, Crew_todo §0 A½.3); the Pool cell on a real phone.

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
 walks `%Theirs` mirrors), falls through to own stock only when friend pool dry OR listener
  flipped `radio.sc.own`. The dial reads `radio.c.heard` (heard-this-sitting) to avoid repeats.
   `Radio_pool_census` counts friends/known/playable/fresh honestly — the ShuffleFace reads these
    same pools visually (one pip per reachable %Record, fill = preview fraction landed).

**What the pool IS in Radio terms today:** the "pool" Radio uses is the IN-MEMORY mirror of friends'
 stocks (`%Theirs` shelves). That is the radio-pool / shuffle-pool — a volatile runtime thing.
  The SoundPool is DIFFERENT: a durable OPFS store of pressed copies. These two uses of "pool" must
   be held clearly separate. Going forward:
- **Radio-pool / shuffle pool** = friend-mirror records in `%Theirs`, volatile, play-over-wire.
- **SoundPool** = the OPFS `pool/…` shelf, durable, play-offline.

**Where SoundPooling plugs in:** a third source rung between "friends" and "own":

```
dial ladder:
  1. friends (Theirs mirrors, live wire)        ← today: default
  2. SoundPool  (OPFS pool shelf, offline-ok)     ← NEW RUNG: sc.source === 'pool'
  3. own stock  (local library, sc.source === '' + sc.own)  ← today: explicit toggle
```

The source selector (`sc.source` on the %Radio particle) is already sketched in Siphon_todo P2.

---

## 2. The C-particles involved

### 2.1 The pool shelf — where pool records live

The pool is an existing concept with an existing mount, not a new container shape. Pool records
 wear **`%Record`** (the 2026-08-27 ruling, Portability_todo §3 "mainkey question BURNED") on the
  pool's own shelf — a `%Mine`-shaped home standing in the radio world alongside the library
   home, but rooted at `pool/…` paths. The identity law (CLAUDE.md "identity is per-shelf") is
    satisfied because the pool SHELF is distinct: a pool %Record at `id:X,path:pool/A/B/t.wav` is
     a different holding from the library %Record at `id:X,path:music/A/B/t.wav`, even if X
      coincides (v1 byte-copy = same bytes). A v2 ogg128 press has a NEW id (different bytes →
       different enid), `of:<origId>` the cross-fidelity join, `grade:'ogg128'`.

**The catalog door** is `Ra_rec_pool(shelf, origId, lofiId, path, grade)` in `Ghost/M/Ra.g:895`.
 One door for every landing, whatever verb brought the bytes — never a parallel minter.

**The pool home particle** (to be stood):
```
%Mine (or a new name — call it %SoundPile to avoid ambiguity with the library home)
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
 `Radio_dial_pool` does over Theirs, but against the OPFS pool shelf. No new machinery; new
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
