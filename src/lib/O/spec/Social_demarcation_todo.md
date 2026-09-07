# Social_demarcation_todo.md — the substrate/app boundary, and the accessor it never had

A **working `_todo`** (not self-promoted — the owner reads + preens). Precipitated by a live walk on
 2026-09-06 in which SoundPooling was dead for two days for a reason that had nothing to do with
  SoundPooling.

## 0. WHAT TO GET ON WITH NEXT

1. **The accessor** (§2) — `Swarm_piers(ident, {live})`, and stop 126 call sites deciding for themselves.
2. **Reach terminality** (§4.1) — a reach addressed to a body that no longer exists must go `dead`
    with a named why, not sit `dispatched` forever.
3. **`since` and general timestamping** (§4.2) — every Pier on eed carries the SAME `since`, so the
    data has no age at all. The owner: *"%since and general timestamping could do with a do up."*
4. Then the sweep: §3's table is the list of things that read the boundary wrongly today.

**The arc:** the social substrate (identity · pier · grant · presence · transport) is a *platform*,
 and Radio/Heist/SoundPool/Story are *apps on it*. That layering is real and mostly good — SP owns no
  transport of its own, and that is the design. But the boundary was never given a **surface**, so
   apps reach straight past it into the substrate's raw storage, and the substrate's own truths
    (*this peer is retired*) are invisible to everyone who didn't personally remember to ask.

---

## 1. THE PRECIPITATING FACT (2026-09-06, eed831f1 measured live)

SoundPooling had not landed a track in ~36 hours. Every layer inside SP was fixed in turn — the
 preview carry, the disk resurrect, the pocket mirror, the byte-lane rebind, the eviction wipe, a
  `bin_rm` that called `bin_read`. All real; none of them the reason. The reason:

```
Body,pub:631300e8…,post:Cave        ← a closed Incognito window
Crew,soul:eed831f1…
  mate:631300e8…                     ← still crew
```

`Ra_pool_fill_homes` asks `Swarm_body_for(ident,'Cave')` for the crew Cave and draws circulation from
 it. eed's Cave was a browser window closed several sessions earlier. So every want, every reach and
  every `ws SEND` went to a ghost — six reaches still `dispatched` from 12:11 the previous night —
   while the daemon (alive, 40 records, Music granted both ways, a Pier on both sides) was never
    addressed once. It received nothing, so it never offered its catalog, so eed never mirrored it, so
     it could never even become a *candidate*.

**Nothing in the system said so.** A reach to a dead Cave is byte-identical to a reach to a slow one.

And the wider survey of the same account:

| finding | count |
|---|---|
| Piers total | 15 |
| …that are dead Incognito test windows | 13 (`Gur, Gruff, Green, Green, Gurf, Grink, Gurg, Gri, Garar, Grewp, Guatr, Grit, e4001fb6`) |
| …still live and real | 2 (`S` the daemon, `Grav` = eed itself) |
| Music grants revoked by eed | 13 — i.e. **the intent is already correctly recorded** |
| `owe:pier_accept` rows re-offered forever | 6 |
| Piers sharing one identical `since:` | 15 of 15 |
| retired-schema particles (`%Jam`, `%Like`, `%SoundPile`) | 0 — those migrations genuinely landed |

The rot is not old shapes. It is **live shapes holding dead references**.

---

## 2. THE DEFECT: the raw query is the API

`Swarm_pier_forget` (the Door's ✕) does the right thing: mints a signed `%NotGrant` per feature +
 UnInvites, and deliberately keeps the `%Pier` row *"as history — it is not deleted"*. Good.

But **"retired" was only ever implemented as a filter in one face**:

```svelte
// DoorFace.svelte
retired: !(Swarm_pier_live(p,'Music') || Swarm_pier_live(p,'MyCave')),
}).filter((f) => !f.retired)
```

Retirement is **computed on demand from grant state**, it is not **marked**, and only the Door ever
 computes it. Everything else walks the raw store:

- **126 direct `o({Pier:1})` call sites across 22 files** (`Ghost/{S,N,M,Story}`, `src/lib/O/**`).
- `Swarm_pier_live` exists but is an opt-in per-call grant check. Roughly **three** sites apply it.

So the substrate records "this relationship is over" in a signed, durable, correct way — and 123 of
 126 readers cannot see it.

> **The rule this violates.** A store is not an interface. If the only way to ask a question is to
>  walk the storage yourself, then every caller re-implements the domain logic, and the ones written
>   before the logic existed simply don't have it.

### 2.1 The accessor (the proposal)

One named door, with the default that is safe:

```
Swarm_piers(ident, opts)      // opts: { live: 'Music' | 'MyCave' | true (any) | 'all' }
```

- default (`live` unset) ⇒ **live only** — a retired Pier is not returned.
- `{ live: 'all' }` ⇒ history included, for the two or three readers that genuinely want the ledger
   (an audit view, the Door's own "show retired", a migration).
- Companion: `Swarm_pier_retired(p)` as the single definition of retired, so it is stated once.

Then the sweep is mechanical: every `o({Pier:1})` becomes `Swarm_piers(ident)` unless it can say why
 it wants history. **Yes, all the tests would roll** — the owner said so before I did. That is the
  cost, and it is worth paying once rather than continuing to pay it in dead-peer bugs.

⚠ **Naming caution.** `Swarm_piers` must not collide with the stash pillar verbs
 (`Swarm_restash_piers`, `Swarm_pier_stash`, `Swarm_pier_unstash`) — those are about durability, this
  is about membership. Check before minting the name.

### 2.2 Why an accessor and not a delete

The owner asked directly: *"we can't keep revokes|UnGrants around without keeping the central
 Peering/Pier for it as well?"* — correct, and keeping them is right: a `%NotGrant` is a signed
  statement *about a relationship*, and it needs the relationship's particle to hang on. The fix is
   not to delete history; it is to stop conflating **the ledger** with **the roster**.

---

## 3. WHAT FLOWS ACROSS THE BOUNDARY (and what each gets wrong today)

The substrate offers four things upward. Apps consume all four, mostly by reaching past the boundary.

| substrate offering | the app-facing seam | what crosses it | current defect |
|---|---|---|---|
| **Membership** — who my peers are | `Peering.o({Pier:1})` *(raw)* | Radio sources, Heist routing, Reach addressing, the Door | retired peers returned as live (§2) |
| **Authority** — what they may do | `%Grant` / `%NotGrant`, `Swarm_pier_live` | Music sharing, MyCave, Crew | correct, but only read at ~3 of 126 sites |
| **Presence** — who is here now | `p.c.heard_at`, `Swarm_socket_fresh` | the catalog offer gate, reach dispatch, the dial's live filter | conflated with membership: a peer that is *gone* and one that is *quiet* are the same shape |
| **Transport** — get a frame there | `Swarm_deliver` → `Peeroleum` → relay | every app frame | a deliver to an unroutable peer returns `false` **silently** |

### 3.1 Repli — the one we encourage, and how SP sits on it

SP owns **no transport**. It rides Repli twice, both times *through Heist*:

- **catalog** — `Ra_offer_stock` ships each Mag as a husk fragment → `Repli_merge` dedups far-side →
   mints the `%Theirs` mirror that `Ra_pool_sources` draws candidates from.
- **bytes** — `%Heist,into:pool` → `Heist_keep_step` → `Repli_register_caster`/`_rx` → chunk wants.

This is the intended shape ("no second lane") and it is why a Pier-level or presence-level fault
 *presents as* "SoundPool is broken". The layering is sound; the diagnosis is what is missing.

**The catalog offer is presence-gated** (`Swarm.g`, the share beat):

```
if (!p.c.heard_at || (now - p.c.heard_at >= 40000 && !Swarm_socket_fresh(p, 20000))) continue
```

*"husking at silence is litter"* — reasonable. But combined with §2 it produces a **silent circular
 starvation**: a peer you never hear from is never offered a catalog; with no catalog it is never a
  candidate; never a candidate, you never address it; never addressed, it never hears from you. Two
   live, mutually-granted bodies can sit forever, each waiting for the other to speak first. That is
    eed↔S today.

→ **Owed:** a presence *floor* for a sealed, granted, currently-connected peer — offer at least once
   per N minutes regardless of `heard_at`, the same way the re-offer floor already backstops the
    change-mark. (`swarm_offer_floor_ms` exists for the mark; this is the other half.)

### 3.2 The systems that walk membership, by name

Each of these currently treats a retired Pier as a peer:

- **`Swarm_station_routes`** — re-mints a transport route for every Pier at standup, retired included.
- **the pier heal / `%owe` ledger** — re-offers `pier_accept` to retired piers forever (eed: 6 rows).
- **`Swarm_boast_floor` / `ive_got`** — boasts a collection at peers who revoked.
- **the share beat's offer loop** — gated on `Swarm_pier_live(p,'Music')`, so this one is **correct**;
   it is the model for the rest.
- **`Ra_pool_sources`** — reads `%Theirs` mirrors, which are minted from offers; inherits whatever
   membership decided upstream.
- **`Ra_pool_fill_homes`** — `Swarm_body_for(ident,'Cave')`, the crew Cave. **No liveness check at
   all** — this is the one that cost two days.
- **Reach addressing** — `Swarm_reach_addr` resolves a role or an address with no liveness question.

### 3.3 THE TWO ARMIES — the interface as arrayed language (2026-09-07)

Two vocabularies face each other across one frontier. The LEFT army knows *who may act and how a
 frame reaches them*; it never names a song. The RIGHT army knows *what a track is and how its bytes
  move*; it never mints a key. The war is won or lost in the thin no-man's-land between them — which is
   also the only ground no test currently stands on (see §7).

```
              THE SOCIAL ARMY                        ║                 THE APP ARMY
   substrate — WHO may act, HOW a frame crosses      ║      music — WHAT a track IS, how its bytes move
 ──────────────────────────────────────────────────╫──────────────────────────────────────────────────
  Identity · prepub · soul                           ║  Record (the holding)  ·  Card (catalog listing)
  Crew · mate · role:Captain|Cave                    ║  Mag · Cloud   (the magazine, offered as a husk)
  Grant:Music|MyCave|Crew    ·    NotGrant           ║  Preview · Prehead · Stream   (opus — PARTIAL stream)
  Pier (a peer) · Peering                            ║  Original | Lossy   (%Body whole-file chunks — REAL)
  Body,post:Cave (a device) · humdinger              ║  keep-id = sha256(pub | base | path)  (deterministic)
  heard_at · socket_fresh    (presence)              ║  RummageLib · rummage id   (path-hash of a describe)
  era · voucher    (rebirth · revocation)            ║  seed (the Mine id) ──re:──▶ the lofi twin (ogg128)
  Reach: booked→dispatched→serving→arrived→landed    ║  Heist keep: wanted→choosing→pulling→done
             ·  refused | dead                       ║        Pick :  blag {re:seed}  |  wire {id}
  Peeroleum · Swarm_deliver · relay deliverLocal     ║  pool | Mine | Theirs   (the three homes)
             (the wire · the own-door rule)          ║  Repli :  want ─▶ page ─▶ land   (the transport)
 ══════════════════════════════════════════════════╩══════════════════════════════════════════════════
     ▽  THE FRONTIER  ▽   where the two touch — and where every SP bug has hidden

   Ra_pool_fill ................ books a ........▶ Reach                (app asks the substrate to carry)
   Heist_rummage_ask/answer .... rides .........▶ Repli_offer          (consent-gated by Grant:Music)
   Repli_serve_want ............ consults ......▶ Repli_allowed        (Grant + pier — SOCIAL, mid-serve)
   Heist_materialise_one ....... mints .........▶ keep-id record       ◄── THE TWIN BUG LIVED HERE
   Repli_find_record ........... resolves ......▶ keep-id (husk|full)  ◄── THE SILENT SERVE LIVED HERE
   w.c.rummage_libs (APP state)  lifetime ruled by ▶ reload / era      (a SOCIAL event wipes app memory)
   Ra_pool_fill_homes .......... picks .........▶ Body,post:Cave       (app booking reaches for a device)
```

**Five places the treaty leaks** — each one a spot where an app decision cannot be made without a
 social fact, which is exactly what makes the app untestable in isolation:

1. **`w.c.rummage_libs`** is app state, but its *lifetime* is a social event — a reload or an era wipes
    it, and the holder then cannot resolve a keep-id it minted. (The re-census heal exists only because
     of this leak.)
2. **`keep-id`** folds a social fact (`pub`) into an app identity (`sha256(pub|base|path)`). The id a
    track is pulled by is half-social by construction.
3. **`Repli_serve_want`** reaches into `Grant`/pier (social) *mid-serve*, on every chunk want.
4. **`Ra_pool_fill_homes`** picks the crew Cave — a social body — with no liveness question. This is the
    one that cost two days.
5. **A pick's binding** (`blag {re:seed}` vs `wire {id}`) depends on whether a *real describe* ran —
    a live/social precondition. Get it wrong and the pull chases the opus preview forever (the 52/54
     stall). No fixture can be wrong about it because a fixture collapses the two id-spaces into one.

---

## 4. TWO REPAIRS THAT STOP THIS HIDING AGAIN

### 4.1 A reach must be able to die

Today: `booked → dispatched → serving → arrived → landed`, plus `refused | dead` as terminals that
 **only a peer's answer** can produce. So a reach to a body that no longer exists has no path to a
  terminal state: it re-dispatches (with backoff) forever, holds a pool want-slot forever, and reads
   in a snap exactly like a reach to a peer that is merely slow.

→ **Owed:** on dispatch, if the target resolves to no live pier and no crew body, mark
   `state:dead, why:'no such body any more'`. It is already the shape `Ra_pool_fill_land` uses for its
    other misses (`why` stamped on the row, said once). eed has six rows that want this right now.

### 4.2 `since`, and timestamping generally

All 15 of eed's Piers carry `since:1788658356` — the last standup. The field is re-stamped on
 rehydrate rather than preserved, so **age information does not exist** anywhere in the roster. The
  owner: *"%since and general timestamping could do with a do up."*

This is not cosmetic. Age is the cheapest possible liveness heuristic and the natural sort for a Door
 roster, and its absence is exactly why thirteen dead windows and one dead Cave could sit unnoticed
  among two real peers.

→ **Owed:** `since` set once at seal and preserved across rehydrate (it rides the pier stash already);
   audit the same class of field elsewhere (`at`, `heard_at`, `offered_at`) for reset-on-reload.

---

## 5. WHAT THIS DOC IS NOT

- Not a proposal to delete retired Piers. History stays; §2.2.
- Not a claim the layering is wrong. SP-over-Heist-over-Repli is the right shape and should stay.
- Not a rewrite of the substrate. Every repair here is additive: one accessor, one terminal state,
   one preserved field, one presence floor.

## 6. MAP

- `Swarm_spec.md` — the canonical social spine (identity, contacts, invites). The *what*.
- `Sharing_design.md` — settled consolidation of the sharing spine; `[LIVE]/[BOOK]/[OWED]` honesty marks.
- `Network_procedures_todo.md` — builder-facing recipe for a multi-party feature. **This doc is its
   missing half**: that one says how to *build* on the substrate, this one says what the substrate
    *owes* a builder.
- `Pier_todo.md` — the KINDS of Pier (friend / own body / role). Retirement is a **state orthogonal
   to kind**; the accessor in §2 should be designed alongside that split, not after it.
- `Peeroleum_spec.md` — transport, routing, the no-Pier drop.
- `Repli_design.md` — replication, the offer/merge lane §3.1 leans on.
- `Crew_todo.md` — the crew ledger, `Swarm_crew_eject`, and who may write membership.
- `SoundPooling_todo.md` — the app that paid for this doc.

---

## 7. WHERE THE TESTS STAND ON THE FRONTIER (2026-09-07 — the twin-record bug's autopsy)

The reason the twin-record + silent-serve bug (SoundPooling_todo §0, 2026-09-07) survived a green
 sweep for days: **every Book draws its line of reality to include only ONE army, and the bug lived in
  the no-man's-land between them.** Measured, not guessed — reading the Book source:

| Book | social army | app army | Repli transport | can it reach the seam? |
|---|---|---|---|---|
| **MusuPoolFill** | real (reach lifecycle, grants, doer) | **mocked** — hand-mints the mirror `{Record, id:'o1'}`; inspects `cave_writes`/`cap_writes` | **stubbed** | no — the mirror id *is* the seed; no rummage space |
| **MusuPoolBytes** | thin | real record, real `Heist_land` to disk | **skipped** — lands an *already-full* local record; never pulls | no — no want, no materialise |
| **MusuReplica / Repli\*** | thin | **clean fixture records (id == record)** | **real** | no — never a describe-minted keep-id, never a husk twin |
| **MusuHeist / MusuVend** | real (piers, grants, offers) | real magazines | **real** (`Repli_offer`, wants) | no — offers whole records; no rummage→materialise→pull |

So: **SP's own Books do not exercise Repli** (they mock or skip the chunk transport). **Repli's own
 Books do not exercise the rummage/keep-id/materialise path** (they use clean records). Real SP needs
  *both at once*, and no Book stands there. That is the seam, drawn on the map in §3.3.

**Realisticising the repro Book** — moving one Book's reality line DOWN to cover the frontier. It must
 stand up *just enough* of both armies for the app path to run for real:

1. A holder with a real folder (a mock nav dir of ≥2 tagged files) and a **real describe** —
    `Heist_rummage_folder` / `Heist_census_heads` — so genuine **rummage keep-ids** get minted beside
     the seed, in a `RummageLib`. (This is the app-army reality the pool Books skip.)
2. A **real Repli crossing** — `Repli_arm` + `Repli_register_caster`/`_rx` over a mock Pier with a live
    `Grant:Music` — so `Repli_serve_want` → `Repli_find_record` → `Heist_materialise_one` actually run.
     (This is the transport the pool Books stub.)
3. A pool keep (`into:'pool'`, `lofi`) whose seed is the folder's heard track, wearing `re:seed`.
4. Pump beats, then **swear two claims at once**:
   - `%see:'a pool keep solos to one pick and reaches pulling'` — the asker binds by `re:seed`.
   - `%see:'the holder serves the lofi copy it materialised — never a chunkless husk and never the opus preview'`
      — the second half nobody asserted. Watch it via the mirror record gaining `%Original` chunks, and
       (the bug's exact signature) that `Repli_find_record` never returns a `total:0` twin.

The mock Pier is where the "line of reality" is drawn. Today it sits *above* the rummage id-space and
 *above* the transport; this Book pulls it *below* both. Everything left above the line (the relay's
  own-door rule, the era/voucher machinery, a live AudioContext) stays mocked — those are genuinely the
   substrate's own to test, and §3.3's frontier says exactly where the cut is clean.

**Then the interface repair (§2, §4) makes the cut permanent**: once `Swarm_piers({live})`, a terminal
 reach, and a keep-id that does not fold `pub` in are in place, the app army can be drilled against a
  fixture holder with *no* social world at all — and this whole class becomes a five-line unit test
   instead of a Book that has to raise two armies to catch one deserter.

---

## 8. FLAWS AND WOBBLY BITS — gathered for the foundational fix (2026-09-07, with the owner)

> **Read `Fallen_out_of_mind_todo.md` beside this.** A twelve-reader sweep of the whole corpus (same day)
>  found that most of these "open" items were already RULED — some in the owner's words — then archived and
>   re-derived here without citation. Its §1 table maps each entry below to where it was decided.

The owner's charge: *"gather flaws so we can fix them all foundationally, and present a more
 un-screw-uppable world to the next app."* Each entry: the wobble · why it bites · the foundational
  direction. Written to be read by a human, not just re-derived by a session. Add to it.

**8.1 "Pier" means two things, and "soul" names a key as if it were a place.**
 · *(Corrected 2026-09-07 after the owner's "are you confused?" — the first draft described the
    pre-land-of-prepub seat model; the `_N` suffix code still exists but only as a collision fallback.)*
 · A friend's `%Pier` is keyed by **`page.prepub` — the prepub of the Body that sealed with them**
    (`Swarm_seal`: `peering.oai({Pier:1, pub: page.prepub})`). Under land-of-prepub every Body is its own
     address. So a Pier is *a Body we know*, and "Pier" is also read as *a role* (`reach.to:'Cave'`).
 · The **soul** is the Crew's *key* — `Swarm_soul`: "the crew's SOUL key {pub,key,prepub}"; the Captain
    *wields* it (holds the mutex), a Cave *carries* it. It is **never bound as an address** (grep: nothing
     routes `to:<soulpub>`). The owner is right that "soul" is non-descriptive: it is not who you call, it
      is what signs. → Rename in prose: **the Crew key** (wielded by the Captain, carried by Caves).
 · Fix: name the three things. **Body** (a device, its own address — what a `%Pier` actually points at),
    **Crew key** (what signs; never a door), **Post** (a role a Body plays: Captain, Cave). Retire the bare
     word "Pier" from prose; keep it as the mainkey only.

**8.2 Who does a foreign Crew call? — the Body it sealed with. Only that one, until taught otherwise.**
 · Measured: they address the prepub they sealed with. `Swarm_reach_addr` resolves `to` against **my own**
    roster only (`Swarm_body_for` → the Body playing that post); a foreign `to` is sent **raw**. A stranger
     cannot address a *post* in our Crew; they can only call a Body they already know.
 · Bites: the friendship is keyed to one Body. If that Body dies (an Incognito Cave that closed), the
    friend's frames go to a dead door — the Grink ghost, from the outside — and our other Bodies are
     reachable only if the roster (8.3) taught them. The owner: *"I think the Cave-services want to detect
      whether there is a Cave"* — presence of a *post*, not of a *door*, is the thing that should be asked.
 · Fix — **this wants a real design, not a patch** (the owner: *"design the way it wants to be a lot more,
    probably with all of these"*). The shape to design: a friendship keyed to a **Crew** (its key), with a
     *set of doors* (Bodies, post-tagged) learned from the roster, and a **natural state machine** per door
      (unknown → known → live → quiet → gone) so "is there a Cave?" is a query on state, not a guess from
       silence. Whether a protocol (Music, MyCave, Crew) resolves a post itself or the Crew resolves it is
        the open design question — answer it once, for all protocols.

**8.3 The slim roster is the intended model — today only a contact-learned cache travels.**
 · The owner: *"the bodies know the whole crew and give them (ongoingly) a slim roster of the Crew (without
    private keys!) — this is just some type of data our Piers want to give us, that unlocks further levels
     of communication with them... it's what everything's doing really."* Agreed — and that thing already
      has a name: the **Charter**, the signed export of `/Crew` (display + recovery, per Crew_todo). The flaw
       is only that the Charter does not yet travel *as the roster*: what a friend holds under our Pier is the
        contact-learned `%Body` cache (`Swarm_pier_of_body` prefix-matching inbound `from:`), partial and
         stale. The `crew-answers-not-the-roster` incident: this cache made a Cave scream theft at its own
          Captain.
 · Fix: the Charter *is* the slim roster; publish it to friends as data, ongoingly, post-tagged, and make it
    the only thing a friend consults about our Bodies. Same pattern as every other offer: data crosses,
     unlocks a level. Then 8.2's door-set is *given*, not inferred.

**8.4 The `Swarm_piers` accessor does not exist — and its proposed name is already taken.**
 · §2.1 proposes `Swarm_piers(ident,{live})`. It is **unbuilt**. Worse, the name is *already* a stash
    key (`st.Swarm_piers`, `Swarm_piers_rehydrate`) — exactly the collision §2.1's own caution predicted.
 · Fix: build it under a name that says membership, e.g. `Swarm_crew_of(ident,{live})` or
    `Swarm_souls(ident,{live})` (pairs with 8.1). Then the 126-site sweep.

**8.5 A husk is a `%Record` playing `%Card`'s part.** (the twin-record bug's root — §3.3, and the
 SoundPooling §0 autopsy)
 · A describe mints chunkless `%Record`s (`total:0`, `husk:1`) as its *catalog*. A materialise mints a
    full `%Record` under the **same** keep-id. Two shapes, one mainkey, one id — the exact tell
     CLAUDE.md records for the old magazine, recurring on the rummage path.
 · Fix: **a describe mints `%Card`; only a materialise/pull mints `%Record`.** Invariant: *a `%Record`
    always has bytes or a `total` that promises them; identity-without-bytes is always a `%Card`.*
     `total:0` + `%Record` becomes a contradiction the encoder can refuse. Then `Repli_find_record`
      cannot find a catalog twin, because catalog entries are not Records.

**8.6 The ask IS C-in-the-stream — but wrapped in imperative scaffolding the metaphysics never paid for.**
 · `Heist_rummage_ask` mints a `%Rummage` particle in a bay; `Repli_offer` replicates it; the source's
    beat *polls* its mirrors for landed asks and answers with more particles. Shared state, not RPC —
     the bet working. But: a **poll** not an event; a `≤3 answers / ≥5s` retry budget; an episode
      counter `ask.sc.n` — all there only because the wire drops frames and a value-upsert cannot tell
       "resent" from "new".
 · Fix direction: make *arrival* a first-class fact (a landed particle bumps a per-mirror `arrived`
    that the beat reads — event, not sweep), and make *episode* part of the particle's identity so a
     re-ask is a new particle rather than an in-place overwrite that needs a counter bolted on.

**8.7 The pool Books do not speak `%see` — so their progression is not readable as language.**
 · MusuHeist/MusuVend swear sentences (`see:'the pair sealed over the wire — …'`). The four pool
    Books record terse flag keys (`doer_served`, `cave_pressed`, `byte_faithful`) that accumulate
     step-over-step. The progression *is* there — MusuPoolFill goes `booked` → `+served,doer_served,
      cave_pressed…` → `+landed,pool_landed,byte_faithful,graduated` → `+refused,receipt_stands` — but
       a human reading the snap sees keys, not claims.
 · Fix: re-author the pool beats in `%see` sentences. The "arrayed armies of language" are only half
    arrayed while the app-side tests speak in tokens.

**8.8 This doc is written for a session, not a person.**
 · The owner: *"that doc is very for you."* True. §0–§4 are dense, code-pointing, and assume the
    reader re-derives. §8 is the first section written the other way.
 · Fix: keep §0 as the plain-language arc (destination · the bomb · the next move) and let the dense
    sections hang beneath it. A spec is *preened* by the owner; this is the todo that earns it.

**8.10 An Invite is a rendezvous, not a direction — the invitee must be able to pivot and invite back.**
 · The owner, 2026-09-07: *"if a Cave LinkDevices a Captain (with a MyCave) it becomes that the Captain is
    inviting the device to its Crew. Often it's easier to take the QR-code scan with a phone, which opens
     the app with that invite — then we use it only to find the other's address and kick off the ceremony
      anew. On the 'you got Invited' page we should be able to suddenly pivot to inviting them!"*
 · Today the QR fixes the direction at mint: the minter is the inviter, the scanner is the invitee, and a
    MyCave invite scanned by the wrong hand makes the wrong device the Cave. But the owner already named
     what a QR *is* — Swarm.g:944, 2026-08-09: an invite *"is essentially just saying 'come here', in a QR
      code"* — a **rendezvous**. Two facts got welded: *find me* (the address, which the QR carries) and
       *join me as X* (the role and direction, which should be decided once both are present).
 · Fix: split them in the social layer, where every Invite is exported to. A scanned Invite yields an
    **address + a warm door** and nothing else; the ceremony that follows is a fresh, mutual one in which
     *either* side may propose the direction (I join your Crew / you join mine / we become friends). The
      "you got Invited" page carries the pivot as a first-class verb. This also restores what Trust_todo
       flags Ferry lost: **mutual consent + SAS** — a rendezvous-then-propose shape is where that naturally
        lives. It belongs beneath the app: an app never knows which way a QR was pointing.
 · Pairs with 8.2 (a friendship keyed to a Crew with a set of doors) — a rendezvous is how a door is first
    learned — and with Swarm.g:7345 (*"a Cave produces another MyCave invite? I thought it would produce
     a MyCaptain"*): the invite's *kind* is a role question, answered at the pivot, not at the mint.

**8.9 (from §3.2, restated as a flaw)** Presence and membership are the same shape. A peer that is
 *gone* and one that is *quiet* both read as "a Pier with no fresh socket". → a presence **floor** for a
  granted, connected peer, and a terminal `dead` for a reach (§4.1) — so "gone" is a state, not a guess.
