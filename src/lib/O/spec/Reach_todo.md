# Reach_todo — the cross-body procedure layer (the foam between the foam)

Commissioned 2026-09-01 (owner): *"imagine what might be if we built some foam layer between the foam
 layers we have, to concentrate on the multi-body programming environment … it has seemed like we've been
  under-abstracting for a while because I don't bother reading your code anymore."*

This doc is the answer to that, and to Homethink §5's load-bearing question — *"how do we build a
 network-party procedure"* — and to §6's shape: Arrival / Ceremony / Focus are the situations a SINGLE
  body passes through, made legible matter. **Reach is the situation that happens BETWEEN bodies**, and it
   is currently NOT abstracted — it is hand-rolled five times over. This is the missing §6 entry.

## ⓘ UPDATED 2026-09-02 (night) — Reach is NOT superseded; it composes on top of the cert-crew pivot

**Reach stands.** The device-link MODEL flipped (owner, 2026-09-02): device-link is now a CREW of DISTINCT
 identities bound by a signed Charter cert, NOT one soul key copied across colliding bodies — see
  `CrewLink_todo.md`. That does not touch the Reach primitive; it CLARIFIES the destination the "still
   owed" migrations point at:
- The W1 Reach primitive is COMPLETE + Book-gated (SwarmBody 23 beats / 25 sworn): 3 exits + terminal
   latch + terminal guard + cap + receipt-aging + pier-less auth + doer tri-state + why-on-the-wire + one
    self-throttling pump. See memory `want-middleware-plan.md`.
- The **cert-offer of CrewLink IS a Reach** — the knock that offers a Charter membership cert to a new
   device settles `landed | refused,<why> | dead,nobody-answered` exactly like any Reach. So the "no one
    answered the door" gap (old `ferry_want`) ports onto Reach (W2), and CrewLink's ceremony rides this
     layer rather than re-hand-rolling the knock. Keep the doer-binding + migration seams below aimed there.
- The addressing self-collision that used to swallow reaches to `to:<soul>` is FIXED + Book-green (memory
   `foreign-want-door-holder.md`); the sibling-lane auth (§6 rule 6) already assumes distinct-body routing.

---

## 0. What to get on with next

**LANDED 2026-09-01 (the same day, on the owner's "fuck that hand-rolled pattern is exactly right — we
 need C** to join simplicity to complexity"):** the WHOLE PRIMITIVE + its wire lane, Book-gated
  (SwarmBody beats 10–12, 12/12 green + the full seven-Book gate):
 - the verbs — `Swarm_reach_book / _addr / _dispatch / _settle / _heard / _serve / _graduate / _refuse /
    _ack / _road / _report` (Swarm.g, right after the %Owed shelf — Reach is its generalization).
 - the lifecycle proven pure (beat 10): book stands + routes off the family charter (a role → the body
    that plays it) · an OFFLINE dispatch leaves the intent standing (the state IS the debt — no separate
     %Owed) · re-book is idempotent · heard → serving → a doer gates → arrived → graduates.
 - the round trip + receipts (beat 11): the settle loop OBSERVES until `w.c.reach_on` flips (the
    backpressure discipline) · the booker acks the outcome · arrived graduates away · **refused STANDS**
     as a visible terminal receipt.
 - the wire lane (beat 12 + production): `reach`/`reach_done` frames route in BOTH hear funnels; the road
    admits only a rostered body of MY OWN soul (`by` prefix-matches a %Body pub — a stranger lands
     nothing); the report resolves the booker's return seat off the roster; the retry rides the 60s
      family trickle (self-gated off `w.c.reach_on`).
 - the crew read (beat 13) + `%Organ` (beat 14) + organ replication (beat 15) + **backpressure** (beat 16:
    a new booking beyond `w.c.reach_cap` (default 32) is refused; a re-book of a standing reach is always
     honoured). **The primitive is production-complete** — durable, addressed, offline-tolerant, roster-
      gated, bounded, and legible (crew read). SwarmBody 16/16 + full seven-Book gate green.

**LANDED 2026-09-01 — organ replication** (SwarmBody beat 15, 15/15 green + full seven-Book gate):
 `Swarm_organ_wire` / `Swarm_organ_absorb` (Swarm.g) + `organs:` on the sibling charter mile — a body
  ships its OWN pocket/trove sizes, a sibling lands them onto the roster row they describe, so the phone
   sees the laptop's trove. (A near-miss caught here: a witness `let ow` collided with beat 6's — LocalGen
    ✓'d it but svelte's parser rejected the redeclaration and the whole app went white-screen until the
     rename; that IS why the runner appeared "down". Now guarded — see [[localgen-misses-redeclaration]].)

**The doer-binding shape (owner 2026-09-01, "a suggestion — don't force it if not ripe"):** a Reach's
 carry-out (`for:serve`) is *"generate a Mag and feed it across to where it needs to be."* The Reach is the
  durable "get it there"; the **Mag is what travels** (the Repli-able unit — heads husk-first, then bytes).
   So `Swarm_reach_serve`'s doer = mint/assemble the wanted Mag + hand it to Repli toward the booker. Not
    built; captured as the intended shape for when the music slice is ripe.

**Still owed (the owner's seams):**
 - **the DOER BINDING** (§5 step 3) — `Swarm_reach_serve`'s doer is a stub in the Book; the live binding
    (`for:serve` → `Radio_keep`/`Heist_materialise_one`) is the humdinger seam — land it with the owner at
     two tabs and flip `w.c.reach_on`. THAT is the "book on the phone, laptop serves it" moment.
 - **the booking GESTURE** — where in the UI a reach is born (a heard-but-absent track's press?).
 - the §7 forks (open `for` vocabulary · %Owed retirement schedule · the Seem-over-Reach dashboard).
 - the MIGRATIONS (§4): charter/grant/pier-heal debts becoming reaches — after the music slice proves live.

- **The fork the owner was confused by is dissolved in §3** — it was never "reuse %Heist vs new %Reach for
   one feature." It's "Reach is a LAYER; Heist is one thing that rides it."
- Do NOT boil the ocean. §4 lists everything that COULD collapse into Reach. The measure of this work is
   bespoke machinery REMOVED (Homethink §4), proven one slice at a time.

## 1. The diagnosis — one pattern, hand-rolled five times

Every time one body needs another body (a sibling of its soul, or a friend) to DO something, the code
 re-derives the same shape from scratch:

  **resolve an address → send → notice it didn't land → stand the intent somewhere → retry on a cadence →
   settle when the far side returns → drop when served.**

Where it lives today, each a private re-implementation of that one shape:

| instance | intent lives in | "didn't land" lives in | retry | settle | drop |
|---|---|---|---|---|---|
| **Repli want** (fetch a page) | *nowhere* — fire-and-forget frame | *nowhere* (lost) | 4s RTO re-ask | — | on land |
| **Heist pull** (nab an album) | `%Heist,state:pulling` | `%Heist.c.no_route_ts` | the share beat | peer returns → next beat | `state:done` → drop |
| **Swarm %Owed** (a missed frame) | the frame's caller | `%Owed,owe:<kind>` on the counterparty row | family/heal trickle | presence edge (`owed_settle`) | `owed_paid` |
| **charter gossip** (tell my division) | the charter | `%Owed,owe:charter` | the trickle | presence edge | paid on landed send |
| **founding-grant / family-grant replication** | the grant atoms | (none — best-effort) | the trickle | — | idempotent absorb |

Five columns of the SAME table, five different vocabularies. A reader (the owner) can't hold it in their
 head because there is no ONE thing to hold — there are five dialects of one idea. That is the
  under-abstraction. `%Owed` was the closest we came to naming it, but we named only the FAILURE half (the
   debt), not the intent — so the intent stayed scattered across Heist/Repli/charter and the debt sat
    beside it as a second particle. **The debt is not a separate thing; it is an intent that hasn't landed
     yet.**

## 2. The primitive — `%Reach`

A **Reach** is a durable, addressed, standing intent: *"this body wants THAT (party) to do THIS, and the
 want STANDS as legible matter until it's served."* One particle, one lifecycle, one settle loop — the
  five columns above become one.

```
%Reach, of:<subject>, to:<role|bodypub|friendpub>, for:<verb>, by:<my bodypub>
   state: booked → dispatched → serving → arrived          (receipts: dropped | refused)
   at:<ts>                                                  (last transition clock)
   <verb-specific fields ride as sc scalars>               (e.g. of:<content-id>, stream:opus)
```

The whole point: **the state IS the debt.** A Reach in `booked`/`dispatched` that hasn't been served is
 exactly what `%Owed` was trying to be — but now it's the same particle as the intent, so there's nothing
  to keep in sync. No separate ledger, no "note the debt beside the request."

The verb set (this is ALL of it — the five dialects collapse into these):

- `Reach_book(w, ident, {of, to, for, ...})` — mint the standing intent (`state:booked`). Snapped, so the
   mesh/Cyto/`/c`/a Book all SEE it the instant it's booked. It exists whether or not the far side is up.
- `Reach_dispatch(w, ident, reach)` — RESOLVE the address (§ROUTING: `to` is a role → `Swarm_body_for` /
   `Charter_addr`; a bodypub → `Swarm_sibling_send`; a friendpub → `Swarm_deliver`), then send. Landed →
    `state:dispatched`. Did not land → **it just stays `booked`** (the intent stands; there is no separate
     debt to write). Idempotent: re-dispatching a booked Reach is the retry.
- `Reach_settle(w, ident)` — the ONE loop: on the presence edge (a body/friend comes back), re-dispatch
   every standing Reach addressed to them. Replaces `owed_settle` AND the Heist stall-resume AND the
    charter-debt retry — one loop for all reaches, gated by the same backpressure knob (`w.c.reach_on`,
     default-off until proven, the discipline).
- `Reach_serve(w, ident)` — the TARGET side: pick up reaches addressed to me (heard over the wire, or
   replicated in), gate on the grant the verb needs, DO the work (bind to the existing doer —
    `Repli_serve_want` for audio, `Swarm_charter_absorb` for a charter, etc.), and mark `state:serving →
     arrived`.
- `Reach_graduate(w, ident, reach)` — the fulfilled Reach DROPS (the transient-req rule: scaffolding, not
   ledger — leave in the snap only reaches whose in-flight state is worth SEEING). The booker sees it go
    to `arrived` then vanish; the arc closes.

**Routing is already built** (this session): `to` resolves through the Charter — `Swarm_body_for(me,
 role)` / `Charter_addr(anchor, role)` for a body of my own soul, the `%Pier` for a friend. Reach doesn't
  invent addressing; it USES the division we just made legible. That's why this layer is cheap now and
   wasn't six months ago.

## 3. The fork, dissolved — Reach is a LAYER, Heist rides it

The owner's confusion ("I really don't understand the Reach problem … who the fuck knows … RemoteHeist
 subclass?") was MY fault: I posed it as a narrow either/or — *reuse `%Heist` vs mint a fresh `%Reach` for
  one booking feature* — which is the wrong question and reads as arbitrary. The real shape:

- **`%Heist` is a LOCAL pull-job**: "I am nabbing this album from a friend, right now, on THIS device —
   here's the folder form, the picks, the progress bar." It is a thing a body DOES, in front of you.
- **`%Reach` is the cross-body INTENT**: "some party should serve me this, and the want stands until it
   does." It is a thing a body BOOKS, that may be carried out elsewhere and later.

They are different KINDS (a job you're running ≠ an intent you've placed), so they are different particles
 — the one-mainkey-one-shape law holds. But the relationship is not "vs":

  **A Heist that reaches a friend who is offline should BECOME a Reach.** The cross-body/offline case of
   Heist is not a new state bolted onto Heist — it's Heist handing the "get me these bytes from that body,
    whenever it's up" part DOWN to the Reach layer, and staying focused on the local job (form, picks,
     landing, probation) it's good at. Heist's own `no_route_ts` stall is a proto-Reach; it graduates INTO
      a real Reach.

**"RemoteHeist" resolved**: the instinct is right, the mechanism is wrong. Subclassing doesn't exist here
 (one mainkey, one shape). A "remote heist" is simply **a Reach whose `to` is a body of my own soul**
  (`to:<my Cave bodypub>`, `for:serve`) instead of a friend. Not a subclass — an ADDRESS. The phone books
   `%Reach,of:<track>,to:<laptop>,for:serve`; the laptop's `Reach_serve` picks it up whenever it next
    wakes and serves via the Heist/Repli doer it already has. Same primitive, different address — which is
     the whole promise of making the division legible: "my laptop" is now an address you can reach.

## 4. What collapses into Reach (the payoff — do NOT build all at once)

Each of these is a candidate to become "a Reach with a specific `for` verb + doer binding." Listed to show
 the abstraction's reach (ha), NOT as a work list — §5 builds ONE and proves the shape first.

- **`for:serve`** (audio) — the music booking. Doer: `Repli_serve_want` / `Heist_materialise_one`. THE
   FIRST SLICE (§5).
- **`for:charter`** — tell a sibling/friend my division. Doer: `Swarm_charter_absorb`. Retires
   `%Owed,owe:charter` + the sibling charter mile's bespoke retry.
- **`for:grant`** — replicate a family grant atom. Doer: `Swarm_family_grants_absorb`. Retires the
   founding/family-grant best-effort push.
- **`for:reaccept` / `for:repli_ready`** — the pier-heal frames. Doer: the existing seal/arm. Retires the
   remaining `%Owed` kinds and the rung-2 throttle special-case.
- **`for:page`** (a Repli want) — the deepest cut: durable, resumable byte-pulls. Biggest payoff, most
   care (it's the hot path); LAST, if ever.

When (if) all land, `%Owed` DELETES (it was the debt-half of Reach), the sibling-send retry loops DELETE,
 and Heist's cross-body stall DELETES — the measure of the change is the machinery removed.

## 5. The first slice — `for:serve`, beside the green Heist, Book-proven

Build the thinnest real Reach and prove it end to end, isolation-first (never retrofit onto green code —
 the Seem discipline):

1. **Book** (phone): a Door/Radio gesture on a heard-but-absent track mints
   `%Reach,of:<content-id>,to:<my Cave>,for:serve,by:<phone>,state:booked`. Resolve `to` via
    `Swarm_body_for(me,'Cave')` (falls back to the Seat). Snapped → visible immediately.
2. **Dispatch**: `Reach_dispatch` sends it over `Swarm_sibling_send` to the Cave's address. Laptop
   offline → stays `booked` (no separate debt). `Reach_settle` on the presence edge re-dispatches.
3. **Serve** (laptop, when awake): `Reach_serve` finds reaches addressed to it, gates on the Music grant,
   and hands the actual fetch to the EXISTING Heist doer (`Radio_keep` / `Heist_materialise_one`) — Reach
    does NOT re-implement landing/probation, it DELEGATES. Marks `serving → arrived`.
4. **Graduate**: audio crossed (the Heist landed it), Reach drops. Phone sees `arrived` then gone.

**Gate**: a new Book (SwarmReach, or a beat in SwarmBody's world) proving pure C-matter: book → dispatch
 to an offline target stands as `booked` → target comes online → settle re-dispatches → serve marks
  arrived → graduate drops. All the wire is station-gated so the Book proves the DECISIONS, not the IO
   (the beat-5/6 stance). Do NOT flip `w.c.reach_on` live until the Book is green and the owner tests.

## 6. Why Seem is the other half — the multi-body environment becomes VISIBLE

The owner's real complaint ("I don't bother reading your code anymore") is a LEGIBILITY failure, and Reach
 alone fixes only half of it (the intents now stand as matter). The other half is PERCEIVING the web of
  them — and that is exactly what **Seem** is for: a second tree that mirrors a first and computes
   arrivals / departures / survivors across beats (goners/neus/survivors), "the model seeing itself
    reflected."

  **A Seem over `%Reach` is the multi-body dashboard, for free.** Mirror the reaches (mine outbound +
   theirs inbound); the resolve hands you `neus` (just booked / just arrived), `goners` (just fulfilled /
    refused), `survivors` (in flight, with age). That IS "what is my crew doing for me, and what do I owe
     them" — as a distilled `%Se:crew` row you can read in a snap and a Book can swear to, instead of
      spelunking `.c` across five ghosts. The Voro glass then styles it by kind (Matstyle) and you can
       WATCH the crew work — reaches lighting up and settling — which is the plaything-that-explains-itself
        north star pointed at the multi-body layer.

So the foam layer is two primitives, composed:
 - **Reach** — the cross-body VERB (a durable addressed intent), which the purpose layer (Heist/Repli)
    expresses its cross-body work IN and the diplomacy layer (Swarm/Peeroleum) carries.
 - **Seem** — the cross-body NOUN's awareness (the reflux over the reaches), which makes the whole web
    perceivable and provable.

Reach sits BETWEEN the diplomacy layer (identity/grants/transport — how bodies CAN talk) and the purpose
 layer (music — WHAT they say). It is the missing "network-party procedure" primitive: not an integration
  between two Houses, but two Houses agreeing to hold the same standing intent as matter (Homethink §5).
   That is the multi-body programming environment — you program the crew by writing reaches into the
    shared matter and watching the Seem reflect them back.

## 7. Open questions for the human (do not improvise)

- **`for` vocabulary**: is `for` a closed enum (serve/charter/grant/…) or open (any verb a doer binds)? Open
   is more powerful (a community extends the crew's abilities by registering a doer — Homethink §5 "you
    extend it by writing into it"); closed is safer to start. Recommend: open, but ship §5 with one verb.
- **Where a Reach lives**: on the booker's `%Peering` (beside `%Body`/`%Charter` — the Crew locality) vs a
   dedicated `%Crew` container. Recommend the `%Peering` (the division's home; a Reach is Crew activity).
- **Does `%Owed` retire NOW or after the byte-path slice?** It's the debt-half of Reach; keep it until the
   `for:charter`/`for:grant` slices land (they're what currently mint it), then delete. Not day one.
- **Seem-over-Reach**: build the dashboard Seem in the same slice, or after the verb layer is proven? Recommend
   after — prove the intent stands and settles first, then make it pretty/perceivable.
