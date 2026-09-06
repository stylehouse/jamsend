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
