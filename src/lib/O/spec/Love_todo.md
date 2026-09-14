# Love_todo — ♥ is the one intent; Heist, FSA, Cave and SoundPool are its roads

The front door for the road a person meets most: press ♥ on a track, and the machine sees to it that the
 music is yours — as a pool copy here, a file here, or a file on another of your devices. The design is
  cooked in `Radio_circuit_todo.md §9` (LOVE AS THE CONTROL SURFACE, 2026-09-10/11) and the code's own
   statement is the header of Heard.g's `THE HANDOFF` region; this doc is the map, not a second design.
    (Owner 2026-09-14: *"it's very central to it all, and likely what will be reconfigured or rebuilt a
     lot when this takes on a crowd of student programmers."*)

## 0. What to get on with next

- **♥ on a SoundPool track heists nothing** (found 2026-09-13). A pool card is `%Record,id:<lofi>,of:<original>`
   with NO holder (the pool does not track where its try-outs came from — on purpose), and `Radio_open`'s
    source walk (`rec.c.play_by || rec.sc.from || Ra_pub_of(rec)`) climbs to the pool shelf and lands on
     ME, so `Radio_like` writes `Card,id:<lofi>,pub:me,take` — which `Heard_takes` and `Heard_landed_ids`
      both exclude as "a heart on your own music is a taste fact". Fix, keeping the pool anonymous: the
       take on a pooled track names `of` (the original) with NO holder, and `Heard_takes` resolves a
        holder-less card at haul time against the `%Theirs` mirrors (crew first) — whoever has it now.
         No `%whoclue`: the mirrors are local catalogs, so "who holds X" is a local lookup.
- eed has no `recent` compartment (consent predates the default; it only applies at a FIRST yes) — tick it
   in the SoundPool sentence to see `loved-and-landed → pool copy` run.
- The representation question is open: the Haul cell's row words (`waiting · handed to Laptop · held`) are
   the embryo of "watch your love travel"; the owner wonders about something richer ("like a videogame").

## 1. The one intent, three roads (all built, all ambient)

| road | needs | what lands | gate |
|---|---|---|---|
| **copy** | SoundPool consent | a lofi copy this device can play, in `%SoundPooling > stock` | `Ra_pool_consent` |
| **folder** | a folder open HERE (FSA — the Crate nav) | the real file, in Mine | `Crate_nav` |
| **hand** | no folder here, a crew body that has one | the real file, on THAT device's Mine | `Heard_hand_on` |

A body with several roads takes them all. `RadioFace`'s long-press sheet names the three in one sentence.

## 2. The ledger — one Card, every road a scalar on it

`Mag:heard,pub:me > Card,id:X,pub:H` — H is the holder you heard it from. ♥ stamps `take`; a second ♥
 removes it (`Heard_unwant`). The Mag lives on the identity (durable, travels with you: pillar 8).
  **Every road writes a scalar on the Card and nothing else:** `take · into:pool · handed:<name> · via:<body>
   · held · unvouched · landfail,why` — a face draws the whole love-heist-opfs-fsa-now-later story off the
    Mag with no state of its own (Heard.g, THE HANDOFF header).
 A heart on a track of MY OWN (`pub === me`) is a taste fact: nothing is owed, nothing hauls, and the
  pool's `recent` never draws it.

## 3. The roads, step by step

**Folder here (FSA):**
```
♥ ─ Radio_like ─▶ Card,id:X,pub:H,take
Swarm_share_beat ─▶ Heist_keep_beat ─▶ Heard_haul_beat(w, rw, me, nav, shop)   ← nav = the open folder; !nav ⇒ return 0
   ─▶ Heard_takes (owed, oldest first, one holder at a time) ─▶ %Heist,seed:X,pub:H (one live keep per holder)
   ─▶ Heist_keep_pool_go / the Repli chunk lane ─▶ lands under <genre>/ in Mine ─▶ Heard_landed answers the ask
```
**No folder here (the phone) — the hand:**
```
♥ ─▶ Card,id:X,pub:H,take            (phone; nothing can land here)
Heard_hand_beat ─▶ Heard_hand_targets  = rostered %Body ≠ me wearing %Organ,kind:trove   (the Cave)
   ─▶ one `take` frame over the crew mile (Swarm_sibling_send: body page + soul voucher)
Cave: Heard_hand_land ─▶ the SAME Card,id:X,pub:H,take,via:<phone> on ITS Mag ─▶ its Heard_haul_beat ─▶ Mine
Cave ─▶ take_got ─▶ phone: Heard_hand_got ─▶ Card%handed:<Cave name>   (the Haul row's word: waiting → handed to Laptop)
Heard_hand_wake re-offers anything unacked when a sibling reappears; sent once per session (card.c.hand_sent)
```
**Back to the phone (SoundPool):** the crew's libraries merge into one Mine, so the phone's
 `Heard_landed` sees the Cave's holding; `Heard_landed_ids` (loved AND landed, newest first) feeds the
  pool's `recent` compartment, and the fill pulls a lofi copy FROM THE CREW MIRROR (`🏊 pool-fill: landed 1
   pool copy from the crew mirror`). Heist it on the desktop, hear it on the bus.

Un-taking does not travel (a heart handed and taken back within 10s stays handed; ✕ on the laptop's Haul
 row is the way back) — `Radio_circuit_todo §9.4/9.8`.

## 4. Where the bodies come from
`/Crew` on the identity is membership (grant-gated); the `%Body` roster is a cache; a trove is
 `%Organ,kind:trove` on a body, replicated by the roster mile — `Crew_todo.md`. Captain wields, Caves
  carry; a phone with no folder is the usual Captain.

## 5. Read next
`Radio_circuit_todo.md §9` (the facets + rulings owed) · `SoundPooling_todo.md` (the pool's steward and
 fill) · `Heist_todo.md` (the keep machinery) · `Crew_todo.md` (bodies, grants, the mile).
