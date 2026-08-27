# Division_todo.md

**The imperial realm: one soul, many role-bearing bodies — a paradigm-general substrate, music
 poured through first.** Division is how a single soul (one keypair) inhabits several bodies
  (phone, laptop, daemon) and *departmentalises* the work among them by ROLE. The Cave|Captain split
   is music's instance of it; the substrate itself is meant to be shared beyond music (the owner,
    2026-08-27: "the Cave|Captain Division may work across multiple paradigms — these are the elements
     I want the imperial realm of this software to share with beyond").

> Status: **working `_todo`, opened 2026-08-27** at the owner's push to stop deferring the
>  SelfType/Division modelling and CREATE it. **§3 SUBSTRATE BUILT the same day** — `%Body` +
>   `Swarm_body_take/note/roster/pick/for/primary` + `Swarm_pier_body` in Ghost/S/Swarm.g (compile-green,
>    17 gen markers), proven by the **SwarmDivide** Book (Swarmation.g, 4 beats, on the Credence board,
>     compile+seam+smoke green) AND a standalone routing verifier (`scratchpad/bodypick_verify.mjs`, 8/8:
>      role-match · bare-first tiebreak · address-asc · order-independence · miss→null). Awaits the Lane-A
>       editor recording (`?B=SwarmDivide`, Resume ×4, → `n:1..5`) like the other new Books. The roster
>        WIRE PAYLOAD also landed (`Swarm_roster_of` publish → `Swarm_roster_onto` absorb, scalar Tier-B,
>         proven in SwarmDivide beat 5). NEXT — the LIVE integration phase (touches running code, do with
>          care): (a) carry `Swarm_roster_of` in the pier handshake (pier_accept / the pier page /
>           Swarm_pier_stash) so a friend's pier absorbs the roster for real; (b) have a booting body
>            `Swarm_body_take` its role+address at station-up (the SelfType arrives on real bodies here);
>             (c) bind the serve DIAL to `Swarm_body_for` so a stream reaches the serving body's address.
>    Sibling docs: **`Portability_doc`/`Portability_todo`** own the music-side portability arc (the
>     Cave|Captain flows, the LinkDevice ceremony, the pool). This doc owns the GENERAL substrate those
>      lean on. Where they overlap, Portability is the music tenant; this is the landlord.

---

## 0. Where to start, and the arc

**The destination.** A soul is not a device. It is a keypair that lives in one-or-more BODIES, each a
 running instance somewhere (a phone browser tab, a laptop tab, a headless daemon). The bodies are not
  peers-of-convenience; they are DEPARTMENTS of one self, each doing the work its situation suits:

- **The substrate is paradigm-general.** Nothing about "a soul has bodies with roles, one of them
   primary, and peers find a body by the role they need" is about music. That is the imperial realm —
    the part meant to generalise. It provides: `%Body`, the `SelfType` role slot, the primary that
     holds the bare address and rosters the rest, and the queryable *find-body-by-role*.
- **A paradigm is a tenant.** It supplies the role VOCABULARY and what each role DOES. Music's tenancy:
   **Captain** (the social hand — online, in-person, mints/redeems invites, listens; the phone) and
    **Cave** (the hoard — disk, library, heists, serving, backup; the laptop/daemon). Another paradigm
     atop the same substrate would name its own departments and never touch these.
- **Roles are looked-up, not just worn** (the owner, 2026-08-27: "people have to be looking for a
   certain role, within the Music paradigm"). A friend wanting a stream does not reach "the soul" — it
    reaches the soul's body that plays the SERVING role. So `SelfType` is a PEER-VISIBLE ROUTING
     property: a friend's `%Pier` records the counterparty's role(s), and "who serves music for soul X"
      resolves to a body + address. This is the reason SelfType cannot be a private tag.

**Two ways bodies relate — the distinction the whole model turns on:**

- **Siblings** — the SAME store. Because `%Identity` does not partition Dexie, every Chrome tab on one
   profile shares one IndexedDB and thus one identity: they are the same body multiplexed across tabs,
    differing only by an address SUFFIX so they don't collide on the relay. No role division — a sibling
     is not a department, it is a duplicate. Primacy (who holds the bare address) is decided live by a
      Web Lock, zero-staleness, auto-released on tab death. *(Open naming: "Sibling" may want a better
       word — it currently means "another tab of the very same store", which is nearer TWIN or FACET
        than sibling. Decide when the substrate particle is named.)*
- **Division** — DIFFERENT stores, DIFFERENT machines, joined by the LinkDevice ceremony and split BY
   ROLE. A phone and a laptop are one soul departmentalised. This is the paradigm-crossing part; a
    Division is a partition of labour, not a duplication of presence.

  The tell that separates them: siblings share a Dexie and race for one address; a Division shares only
   the keypair and each body keeps its OWN address + role. Same soul, opposite relationship.

**The primary — name TBD (`DivisionMaster` leads; `Steward` also floated).** One body per soul is the
 primary: it holds the unsuffixed `<prepub>` address and tracks the others (the roster). The owner's
  framing (2026-08-27): "the [primary] is the primary one of a Division, who holds the unsuffixed
   address and tracks the others." Open question below is whether primary is a SIBLING-primacy concept
    (Web-Lock, within one store) promoted to span a Division, or a distinct Division-level helm. Music's
     answer is nearly forced: the Captain is the helm (it alone processes invites — Portability §9), so
      in the music tenant primary ≈ Captain. Whether the general substrate must name a primary at all,
       or only paradigms that need a helm do, is the first real design fork (see §2).

**What already exists** (map confirmed against code before building — see §3):
- `Swarm_sibling`/`Swarm_is_sibling` + the BroadcastChannel cohort census (the Sibling machinery).
- `Swarm_address`/`Swarm_next_suffix`/`Swarm_steal_back`/`Swarm_reinstate`/`Swarm_rehome` (the
   bare-vs-suffixed address machinery, disk-wins hold).
- `Swarm_cohort_vessel`/`_primacy`/`_stand` + `Swarm_station_up` + a Web Lock (the primacy decision).
- A vestigial `selftype` string threaded through `Swarm_sibling` — set empty, read nowhere. The seam
   is already CUT for SelfType; nothing fills it. **This is the hook the whole model hangs on.**
- The LinkDevice crypto (SwarmSeal/SwarmFerry/EmojiConfirm — Portability): the secure body-join.

**What is missing (the work this doc scopes):**
1. **`SelfType` as a real, peer-visible role.** A body carries its role; the role is queryable.
2. **`%Body` / the roster.** The primary's list of the soul's bodies — each a (role, address, vessel).
3. **`find-body-by-role`** — the routing query a Pier/serve seam uses to reach the right department.
4. **The Pier carries counterparty role(s)** — so a friend routes to my serving body, not my phone.
5. **The music role vocabulary bound onto the substrate** — Captain, Cave, and what each serves.
6. **The Book** — proving the substrate at the model layer: two bodies of one soul take roles, the
    primary rosters them, a peer's find-by-role resolves to the serving body, a wrong-role query misses.

**The next move (once the map lands, §3):** name the substrate particles (§2 fork first), then build
 the smallest end-to-end slice — a soul with two bodies (Captain + Cave), the primary rostering both,
  and a `find-body-by-role` that a peer uses to reach the Cave for serving — model-layer, Book-proven,
   music role names bound but the substrate paradigm-blind. Details accrete below as the design firms.

## 1. The layering (substrate vs tenant), stated once

| Concern | Imperial realm (substrate) | Music tenant |
|---------|----------------------------|--------------|
| A soul has… | bodies, each with a `SelfType` | — |
| Roles are… | a queryable slot, peer-visible | Captain, Cave (the vocabulary) |
| Primary is… | the body holding the bare address + roster | the Captain (the helm) |
| Find-by-role… | `body_for(soul, role)` → address | "who serves music for X" → the serving body |
| Knows about music? | NO | yes — binds role meaning |

The substrate must compile and be Book-provable with the music names factored OUT — a paradigm supplies
 role strings and serve-meaning; the substrate never branches on `'Cave'`.

## 2. Forks — RULED 2026-08-27 (against the code map; the owner delegated "that's on you")
- **`%Body` vs reusing `%Sibling`/`%Pier` → NEW `%Body`.** The map settles it: `%Sibling` is a
   SESSION-ONLY same-store cohort row (BroadcastChannel, lost on reload, `Swarm_sibling(ident, place,
    address, role)` at Swarm.g:3669), and a self-Pier is explicitly SKIPPED everywhere (Radio.g:1705) —
     there is NO cross-machine body representation today. A Division body is different in KIND
      (different store/machine, PERSISTENT, replicated Tier-B, role-partitioned), so it gets its own
       mainkey **`%Body`**, under `%Peering` beside `%Pier` and `%Sibling`.
- **"Sibling" rename → NO, split instead.** Sibling stays the same-store cohort (accurate: tabs of one
   Dexie); `%Body` is the Division roster. The overload the owner sensed is dissolved by the split, not a
    rename. (`%Sibling.role` — the vestigial field — is the same-store analogue; `%Body.role` is the
     cross-machine one. Same SelfType idea, two scopes.)
- **Primary: substrate or tenant → substrate PREDICATE, tenant BINDING.** The substrate exposes
   `Swarm_body_primary(ident)` = the `%Body` at the bare `<prepub>` (address === prepub) — the map shows
    bare-address-holding is already the primacy spine (Web Lock same-profile at Swarm.g:3759 + hello-v2
     cross-machine). Paradigm-general. Music BINDS primary = Captain (the sole invite helm, Portability
      §9). A paradigm without a helm simply never asks.
- **Name the primary → `DivisionMaster`** (the general concept, in prose). Distinct from the POOL
   steward **Quartermaster** (Portability — decides phone stash). Code uses the plain predicate
    `Swarm_body_primary`; no separate particle (primary is a computed property of the roster).

## 3. The ruled model (build target)

**The particle.** `%Body,pub:<vesselpub>` under `%Peering`, carrying `role:<SelfType>` (the queryable
 department), `address:<addr>` (bare `<prepub>` or `<prepub>_N`), and `self:1` on the running body's own
  row. Keyed by `pub` (the vessel key identifies a body — many bodies per soul someday, so not keyed by
   role). Tier-B grow-only: bodies append, the roster unions across replicas.

**The substrate seams (paradigm-BLIND — never branch on a role string):**
- `Swarm_body_take(ident, role, address)` — the running body declares its own `%Body,self:1` (oai,
   idempotent); updates role/address if changed.
- `Swarm_body_note(ident, pub, role, address)` — record ANOTHER body (from roster replication / the
   LinkDevice roster hand-off). oai per `pub`.
- `Swarm_body_roster(ident)` — the `%Body` rows (the division).
- `Swarm_body_for(ident, role)` — **the routing query**: the body playing `role`, deterministic
   tiebreak (primary/bare first, then address asc). Returns the row (address on it) or null.
- `Swarm_body_primary(ident)` — the `%Body` whose address === the bare prepub (DivisionMaster).

**The peer side (why the role is peer-visible).** A friend's `%Pier` carries the counterparty's roster
 so "who serves music for soul X" resolves to a body+address, not to "the soul". `Swarm_pier_body(pier,
  role)` finds the counterparty body playing `role` over the imported roster on the Pier. (v1 stamps the
   roster onto the Pier directly and proves the lookup; the WIRE that publishes a soul's roster to its
    Piers is a later replication slice.)

**Music tenancy** (bound in the Book, never in the substrate): roles `'Captain'` (social hand, online,
 listens) and `'Cave'` (library, disk, heists, SERVING). "Looking for a role within the Music paradigm"
  = a peer's `Swarm_pier_body(pier, 'Cave')` → the serving body's address. The substrate fns take these
   as opaque strings; a green Book with the music names factored through the substrate proves the
    paradigm-blindness (the imperial-realm claim).

**The Book — `SwarmDivide`** (Swarm-family, Swarmation.g): beat 2 a soul stands two bodies (Captain at
 bare `<prepub>`, Cave at `<prepub>_1`), each takes its role; beat 3 the substrate queries resolve
  (find Cave → `_1`, find Captain → bare, primary → the Captain, a wrong role → null) with the fns never
   naming a role; beat 4 a friend's Pier carries Alice's roster and `Swarm_pier_body(pier,'Cave')`
    reaches the Cave address (the peer routing) while an unpublished role misses.

## 4. find-Body-by-role — RESOLVED (2026-08-27, after a second adversarial round scrapped `%Reach`)

A first pass reified "the other side" as a materialised verdict particle `%Reach` (a cached
 `state ∈ {live,stale,dark,ungranted}` kept fresh by a watcher off the presence pulse). **It was
  built (slice 1) then REVERTED.** Two adversarial reviews converged: `%Reach` re-introduced a presence
   cache with its own ~40s clock — the EXACT "cache liveness and keep it fresh" shape the live transfer
    protocol (`repli_want`, `Ghost/N/Repli.g`) already tore out for being "redundant and, live, pure
     liability" (it flooded the `%outbox` and killed the deliver pump mid-heist). The codebase already ran
      this experiment one layer down and wrote down why. Don't rebuild it one layer up.

**The sublation — find-Body-by-role is TWO questions that were being conflated:**
1. **RESOLUTION (directory):** *which body plays role R for soul S, and at what dialable address?* Pure,
    stateless, paradigm-blind, CANNOT lie (it makes no reachability claim). This is `Swarm_body_for` /
     `Swarm_pier_body` / `Swarm_body_pick` — **already built and proven (SwarmDivide). It stays.**
2. **REACHABILITY (liveness):** *is that address answering right now?* This is **NOT a directory property
    and must not be cached as one.** It is the transport's ground truth — `Swarm_deliver`'s boolean return
     (`false` = no ready carrier) and the per-Pier outbox ack/dead ledger (`Reliable.g` `retx_due`). You
      discover it by SENDING, not by asking. "Emit is what `%Reach` wanted to cache" — so cache nothing;
       emit and let it fail forward.

**The pattern (resolve-and-emit, fail-forward):** resolve role→address (cheap, from the roster), then
 EMIT. The reply lands, or the sink re-asks (the pull's 4s heartbeat already self-heals a dropped want).
  No verdict particle, no watcher, no freshness clock.

```
// music tenant — reach a soul's serving body. Grant gate is a real check (G5), not a cache.
Musu_serve_ask(w, ident, pier, frame):
    if (!this.Swarm_pier_live(pier, 'Music')) return false        // grant — checked at use, per its own law
    let body = this.Swarm_pier_body(pier, 'Cave')                 // RESOLUTION (pure directory)
    let to = (body && body.sc.address) || pier.sc.prepub          // dialable; else the soul (relay fans out)
    return this.Swarm_deliver(w, ident, to, frame)                // EMIT; false = fail-forward, re-ask heals
```

- **Self vs friend** unify inside `Swarm_deliver` (it already falls to an in-process mail drop for a local
   account) — no `.send()` local/wire fork needed at call sites.
- **Captain-offline / nobody-home (G7)** is handled by fail-forward, not a verdict: emit to the bare
   prepub and the relay fans out to whatever body is awake; nothing answers if none is up — same outcome as
    "dark," self-healing the instant a body wakes.
- **The one thing emit can't do** — show a human "your friend's Cave is offline" BEFORE they act — is a
   DERIVED, NON-PERSISTED read, not a particle: `Musu_serve_note(pier) → 'live'|'offline'|'unknown'` folds
    `Presence_here(pub)` + `Swarm_pier_live(pier,'Music')` at the moment of the read, exactly as
     `Radio_reason` already composes them. Zero new state.

**Kept from the reviews:** the RESOLUTION/REACHABILITY split (the spine above); the grant gate as an
 explicit at-use check; and a documented FALLBACK — if a hot loop ever proves it needs a cached reachability
  read, the lean form is a verdict grounded on the transport's OWN ack/dead ledger (`retx_due`), never a
   standalone presence clock. We are not there; the live protocols say we likely never will be.

## 5. The corrected layering (Captain/Cave are GENERAL; SelfType marks Division) — supersedes §1

The owner's ruling (2026-08-27): "Captain|Cave will be roles shared beyond the Music realm"; "SelfType|role
 is definitely BELOW the Music realm." So the earlier §0/§1 framing ("substrate paradigm-blind, MUSIC binds
  Captain/Cave") was INVERTED. The correct split:

- **The general realm (below music) owns:** that a soul may DIVIDE into bodies; that dividing confers a
   **SelfType** (a body's role) — *an undivided one-body soul has NO SelfType; it is simply the soul,
    everywhere; dividing is the act that confers roles*; the role NAMES themselves, including **Captain**
     (social hand / helm / authority) and **Cave** (deep hoard / disk / serving) — general stations that
      recur across paradigms; and the mechanism to RESOLVE a role to a body and route to it.
- **A paradigm (music, first tenant) owns:** what a role MEANS and DOES — a Cave serves streams and fulfils
   heists, a Captain mints invites and listens — and the GRANT that gates it (`%Invite:Music`). It binds
    behaviour to a role name; it never owns the name.

The code already honours this — `%Body`/`Swarm_body_for` take `role` as an opaque string and never branch
 on `'Cave'` — so NO code change; only the doc prose (and Portability §2's "SelfType = a station in life"
  and §1's table cell placing Captain/Cave in the music column) must be corrected to match.

## 6. Owed follow-ups the reviews surfaced (not yet resolved — need building or a ruling)

- **How a body FIRST gets its SelfType** (M1): the LinkDevice/Division ceremony should CONFER the role
   (Portability §10 "the Captain writes the new body into the family register at issue time"), not a body
    self-declaring locally. Wire `Swarm_body_take` to the ceremony payload, not to an arbitrary boot choice.
- **Role change/revoke** (M2, M8): the roster is grow-only Tier-B, wrong CRDT for a MUTABLE role; and a
   defected Cave (`%Invite:MyCave` revoked, Portability §12) must drop from routing — TWO revocation planes
    (music-grant vs role-grant) the resolve path must both honour. Needs the fade/tombstone story (§13).
- **The one-body base case** (M3): `Musu_serve_ask` on an undivided soul — does it degrade to "reach the
   soul" (bare prepub) when no roster/role exists? Almost certainly yes (fail-forward makes it free), but
    state it. This is the COMMON case today.
- **Roster refresh transport** (M7): does the peer-visible roster travel by pier HANDSHAKE (point-in-time,
   `Swarm_roster_of`/`onto` — built) or by the continuous body-to-body REPLICATION stream (Portability §10)?
    Unreconciled; a peer on a stale handshake roster routes to a decommissioned Cave until re-handshake.
