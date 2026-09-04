# Radio_circuit_todo — the datasplatter behind Radio, and the one circuit it wants to be

The owner, 2026-09-04, reading the Like|Jam|Grab schematics: *"none of this shit makes sense to me… it
 seems like a big cancer? can we please simplify… think long and hard about the datasplatter behind
  Radio, basically… mature!"* This is that thinking. It is a `_todo` for you to preen, not a build.

## 0. THE ONE SENTENCE, AND THE RULING IT RESTS ON

**There is one container, `%Mag`, and one referring particle, `%Card`. Every other "want" shape is
 vocabulary pretending to be structure.** That is not a new idea — it is your own ruling of 2026-08-05
  (`Mag_todo.md` §0.0): *"there is ONE Mag kind… `%Grasp` is DROPPED… a want is a `%Caper`… the disk
   becomes a Mag at the point it is read… favouriting is not in v1.0."*

What went wrong since is simple to say: **`Jam.g` (July) predates that ruling and contradicts it**, and
 tonight I built batch acquisition ON it rather than noticing. So the ♥ landed as `%Jam > %Like`, a
  fourth want-shape beside `%Heist`, `%Caper` and the pool's `%Want` — the splatter got one deeper.

## 1. THE SPLATTER, COUNTED

Six ways today to say "I want that", each with its own container, its own lifetime and its own reader:

| shape | container | minted by | read by | lifetime |
|---|---|---|---|---|
| `%Like,of` | `stock > %Jam,with:<dj>` | ♥ | `Heist_want_beat` | forever (never partitioned) |
| `%Heist,seed,pub` | `shop` | ⇊ / pool catch / the beat | `Heist_keep_step` | until landed |
| `%Caper,at,seed` | `shop` | `Heist_job` | `Heist_beat` | until flattened |
| `%Pick,ref` | under a `%Heist` | describe | the pull | with the keep |
| `%Want,of,do` | `w > %Provisions` | `Ra_quarter` | `Ra_quarter_serve` | until the next sit-down |
| `%Caperlet` / `%Rummage` | `shop > bay,pub` | the ask | the far side | until answered |

And beside them, **invisible**: `keep.c.blagged` (the folder listing), `rec.c.unity` (the folder's MB),
 `w.c.keep_beat_at`, `rw.c.want_n` — **139 distinct `.c` keys in `Heist.g`, 118 in `Ra.g`, 124 in
  `Radio.g`**. That is the `.dontsee` you named. `Repli_design.md` §0.3 calls the same thing "the `.c`
   smear" and records your own read of it: *"any mention of `.c.*` is likely meant to be another attached
    sphere."* Nothing here is a new diagnosis; it is the same one, arrived at from the Radio side.

## 2. YOUR QUESTIONS, ANSWERED STRAIGHT

- **When does a `%Jam` happen? whole session?** — On the first ♥ with that dj, and then **never again**:
   one `%Jam,with:<dj>` per relationship, forever, accreting. Not a session at all, despite the name.
- **`%pub` is a prepub?** — Yes, 16 hex, everywhere in the music homes (`Radio_pub` reads `ident.sc.prepub`).
   It names a Pier you hold.
- **Why is their catalogue mirrored to me — doesn't that happen in Mags?** — It IS Mags. `%MusuThem,pub`
   is merely *where their Mags land*: `stock > %Mag:shuffle > %Cloud,page > %Record` husks, offered
    head-first when a record appears in their library (Repli's Seem notices; nobody "pushes"), bytes pulled
     page by page on demand. **The remote never pushes; each end has a Mag to talk through** — exactly as you
      said. The `bay` is the talking-Mag in the other direction (a chunkless ask crosses, comes back
       annotated). The architecture you described is ~80% built; what is NOT on it is the *wants*.
- **The `Musu` prefix** — leaked from the Book convention (`Musu*` Books require a `Musu*` world) into
   the home names in July. It implies nothing. Names are cheap: `%Self,pub` / `%Them,pub`.
- **`shop`** — your 2026-07-17 ruling (*"the whole loading here-and-there zone"*), and the concept is the
   GC invariant: bytes settle in exactly one place, so anything *in motion* must live somewhere that is
    not the collection. The concept stays; the word can go (`inbound`?).
- **Why would anyone press ♥ twice?** — They wouldn't, and tonight's toggle was the wrong answer to a
   question nobody asked. The right reading of a second press is §3's `mire`: it *adds*.
- **`%title` won't locate anything later** — correct. The pointer was `of:<id>` into a mirror that is
   swept on a TTL. The fix is not a better pointer; it is a **self-sufficient Card** (§3).
- **`keep.c.blagged` / `Ra_unity_stamp`** — the *idea* under both is the one you want: a Record already
   knows enough to begin a heist, and the folder listing is derivable from the mirror's cards sharing a
    dirname, ad hoc. The sin is the home (`.c`, invisible) and the names. §3 makes the listing a Cloud
     of Cards you can see; the MB is then a sum over it, not a stamp.
- **Persistence** — you already have it right: a want is *account* matter (`.jamsend/account/<prepub>/
   toc.snap` — `Swarm_export` is a skip-list, so a Mag hung under the `%Identity` rides for free, which is
    how the pools already persist); a heist is *FSA* matter (`berth/<prepub>/`, already per-prepub, so
     "filter for our own" is the existing layout).

## 3. THE CIRCUIT

Five stations, one shape. Read it top to bottom as one track's life.

```
THEIR SHELF — their Mag, landed at me husk-first, scrolling (era-GC off the front)
  Them,pub:f00d
    stock
      Mag:shuffle
        Cloud,page:7
          Record,id:r1,title:Cosmic C,artist:DJ Oscillo,path:DJ Oscillo/Cosmic C.flac,bytes=51744301,body_hash:…

MY ATTENTION — my Mag, partitioned by era, scrolling the same way.  THIS REPLACES %Jam/%Like/%Grab/%Spin.
  Identity                                   ← account matter: rides the export for free
    Mag:mire
      Cloud,era:41                           ← the open era; a new era every N hours|tracks (§4)
        Card,id:r1,of:f00d,mire=6,title:Cosmic C,artist:DJ Oscillo,path:DJ Oscillo/Cosmic C.flac,bytes=51744301
        Card,id:r2,of:f00d,mire=1,title:Dorian D,…
      Cloud,era:40
        Card,id:q9,of:beef,mire=1,…          ← ages off the front unless promoted (§4)

MY WANT — the harvester's verdict, as your ruling says: a %Caper.  THIS ABSORBS %Heist, %Pick, %blagged.
  Identity
    Mag:caper                                ← FSA matter too: mirrored to berth/<prepub>/ for resume
      Caper,at:f00d,seed:r1,state:pulling
        Cloud,dir:DJ Oscillo                 ← THE FOLDER LISTING, visible — derived from their shelf's
          Card,id:r1,…,take                     cards sharing the dirname (what blag did, in .c)
          Card,id:r3,…                        ← untaken = the old un-ticked %Pick, as ABSENCE of `take`

THE BAY — the Mag we talk through, unchanged in kind (Caperlet | Rummage already work this way)

MY COLLECTION — the disk, which becomes a Mag when read (your ruling).  A landed Card's id now
  answers "do I have it" on the shelf; the Caper drops itself; the Card in Mag:mire stays as history.
```

**What `mire` is.** One number on the Card, accreting from behaviour: heard a whole track `+1`, heard it
 again `+1`, ♥ `+5`, ♥ again `+5` (mashing the heart IS human), skipped `−1`. There is no `%Like`, no
  `%Grab`, no toggle, no un-like: disinterest is *decay* — a Card that never rises ages off with its era.
   That is your *"squishy adjustable rule engine"*, and it is one table (§4), not five particle kinds.

**Why a Card and not a pointer.** The Card carries the listing (`title, artist, path, bytes, body_hash`)
 copied off their shelf at the moment of attention, so it is **self-sufficient**: it survives the mirror
  sweep, a reload, and the friend going offline for a week. `id + of` is still the join; the rest is what
   lets the Caper begin without asking. *A Mag can't hold binary in the Wormhole* — right, and it never
    does: Cards only. Bytes fill at runtime through Repli, as today.

**What "delete at the top" is.** The era-GC you already ruled for shuffle (`Mag_todo` §0.0: *drop Clouds
 off the FRONT, bounded by any position that sits on them*), applied to `Mag:mire` with one extra bound:
  **a Card above threshold is promoted** (re-minted into the open era) before its Cloud drops. The Mag is
   therefore a **queue you run harvesters over, then delete** — your words — and it cannot grow
    ridiculously-shaped, because an era is a bounded window and the only thing that outlives one is
     something you demonstrably cared about.

## 4. THE RULE TABLE — the whole society, tweakable in one place

```
Mire                                   Harvest (a Card ⇒ a Caper)         Era
  heard whole        +1                  track    mire ≥ 5                   new era: 24h or 60 cards
  heard again        +1                  album    Σ mire over dir ≥ 12       drop: era < open−3
  ♥                  +5                  pool     mire ≥ 1 ∧ consent         promote: mire ≥ 5
  skipped            −1                  radio-more   mire 2..4 → dial bias
```

Every number is a scalar on one `%Rules` particle (visible, snapped, Book-gated), not a constant in a
 verb. Whether a ♥ takes the track, the album, or just biases the dial to play more of that folder — your
  *"squishy zone we'd be tweaking UX and app function with"* — is a row here, not a code path. The
   harvester is one pure function `Mire_harvest(mag, rules) → [caper intents]`, which is what makes it
    testable without a wire.

## 5. WHAT THIS DELETES, AND WHAT SURVIVES

| goes | because |
|---|---|
| `Jam.g` entire (`%Jam/%Spin/%Like/%Grab`) | `Mag:mire` + `mire=` on a Card |
| `%Heist` (the keep) as a kind | it was always the soft half of a `%Caper` (`Heist_todo` says so) |
| `%Pick` | a Card in the Caper's Cloud; untaken = no `take` |
| `keep.c.blagged`, `rec.c.unity` | the Caper's Cloud, visible; MB = Σ bytes over it |
| `%Provisions > %Want` | the pool is one more harvester row over `Mag:mire` |
| `%Hauls/%Haul/%Newly/%Fresh` (dontSnap) | the collection-as-Mag answers "what landed" with `created_at` |
| tonight's `Heist_want_*`, `Heist_keep_like_go`, `Radio_unlike`, `Heist_newly_mirror` | built on `%Jam` |

| survives, re-homed |
|---|
| one live Caper per holder, oldest first (the serialisation) — now a harvester rule, not a beat |
| "the collection answers the ask" — `Heist_want_settle` becomes: a Card whose id is on my shelf is done |
| byte progress off `%Body` never `%Preview` (`Heist_keep_flight`) — reads the Caper's Card |
| the Haul grouped by holder (`Heist_haul_piers`) — reads `Mag:caper` grouped by `at` |
| the wire: `Caper`, `Caperlet`, `Rummage`, `Repli`, the bay — untouched |

The engine (`Heist_beat`/`Heist_land`/the quarantine/the vouch door) is not in this picture because it
 does not need to be: it takes a `%Caper` and lands bytes, and that is exactly what it takes today.

## 6. RULINGS OWED (yours)

1. **`mire` values** — the four numbers in §4, and whether ♥ is +5 or "jump to threshold".
2. **Era size** — by time, by count, or by session (a `Cloud,era` per sitting is the most legible).
3. **Names** — `mire` / `caper` / `Self|Them` / what replaces `shop`. Cheap, but they go in a snap.
4. **Does the harvester run a Cave for a Captain?** (the blocked §3 of `Acquisition_todo`) — under this
    shape it is *one line*: `Mag:mire` is account matter, so it can ride the crew ferry like the pools do.
     Still your call whether it should.
5. **`.c` → a visible sphere** — the `Repli_design` §5 thread. This doc assumes it; it does not build it.

Nothing in tonight's tree needs to be kept for this. It was a night's work on the wrong container and the
 verbs that were right are three, listed above; the fixtures re-record in an hour once the shape is ruled.
