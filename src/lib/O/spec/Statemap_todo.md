# Statemap_todo — a map of the account | ceremony | surface state, and the push to predictable structure

Commissioned 2026-08-31 (owner, mid device-link testing): *"w.c.focused sounds exactly like what I don't
 want this built like… what is tested of our Link|Invite|Cell process? must be nothing if such state is
  hiding in .c.* … so C/C/C structures should be holding what's going on, aye … we need to create localities,
   objects of some sort … we'll need a map of state … I was thinking of making all the account data, or a type
    of Wormhole+Lines storage, have more predictable structure."*

This doc is that map. It exists because the device-link locus proved the thesis of the whole project the hard
 way: **state hidden in `.c` is invisible to the snap, the mesh, Cyto, `/c`, and every Book — so it drifts
  unchecked and cannot be tested.** The bet (CLAUDE.md) is the opposite: turn every kind of state into legible
   living matter a group can see, prove, and rewrite while it runs. Where we broke that, it broke.

## 0. What to get on with next

The arc, highest leverage first:
1. **Close the sibling-sync gap (§3).** The Captain now signs+gossips its division (landed), but the Cave still
    can't learn the Captain: a body is not a friend, so there is no `%Pier` to absorb the charter onto, and the
     Captain's pier for the Cave is keyed by the Cave's PRE-become prepub (stale after the handover). This is the
      real "they still don't know each other." It wants a **sibling channel** (charter delivered to body
       ADDRESSES `<soul>_N`, absorbed into one's OWN `%Peering` when `charter.soul === my soul`), which is
        plausibly a **Repli / replication** job (the owner's "use Repli to move stuff?"). Design in §3.
2. **Make the surface a C locality (§2).** Replace the `w.c.focused` / `link_surfaced` / `link_decided` /
    `link_unlive_at` pile with ONE snappable particle so the belly focus is legible + Book-assertable. The owner
     named this precisely. Medium risk (touches the hot belly-render path in Cellui) — do WITH the owner testing.
3. **Predictable-structure account storage (§4).** The bigger direction: account data / Wormhole+Lines with a
    declared, uniform shape so "what's up across the systems" reads at a glance and snaps identically everywhere.

## 1. THE MAP — device-link / account state, WHERE it lives, whether it SNAPS, whether it's TESTED

Legend: **particle** = a C in `.sc` (snaps, mesh-visible, Book-assertable). **`.c`** = runtime flag/ref (never
 snapped, invisible, untestable). ✓tested = a Book asserts it (via `%see`/snap-fixture diff).

### The GOOD — already legible C structures (keep, lean on these)
| state | home | snaps? | tested? |
|---|---|---|---|
| the account | `%Identity` / `%Peering` | ✓ | ✓ (Swarm* Books) |
| friend memory + trust | `%Pier` → `%Grant` / `%NotGrant` | ✓ | ✓ (SwarmStaple beat 7) |
| the invite issuer + spend | `%Idzeug,next,claimed` | ✓ | ✓ (SwarmInvite/Blotter) |
| the ceremony walk | `req:Ferry_soul` / `req:Ferry_cave` `sc.phase` | ✓ | ✓ (InvSeal/InvFerry/InvWalk phase walk) |
| **the family roster** | `%Body,pub,role,address,name` under `%Peering` | ✓ | ✗ **OUTCOME untested** (§3) |
| **the division attestation** | `%Charter,era,payload,sig,soul` | ✓ | ✗ **never signed at ceremony until 2026-08-31 (§3)** |
| the storage decision | `%Share,mode` (Arrival_todo) | ✓ | ✗ (new) |
| the arrival phase | `%Arrival,phase,reason` + `%want` (Arrival_todo) | ✓ | ✗ (new) |

### The BAD — state hiding in `.c` (the anti-pattern the owner caught; the localities to create)
| state | home (`.c`) | why it's wrong |
|---|---|---|
| which belly cell is focused | `client_w.c.focused` (a mainkey string) | the ceremony's whole visible OUTPUT, invisible + untestable — §2 |
| the auto-surface latch | `w.c.link_surfaced` | ditto; the "comes and goes" flicker lives here |
| the per-phase surface decision | `w.c.link_decided` (`phase@at@named` key) | ditto |
| the unlive janitor debounce | `w.c.link_unlive_at` | a timer masquerading as state |
| the offer seizure clock | `req:Ferry_cave.c.offer_at` | fine as a clock, but the OFFER itself deserves visibility |
| the glass machine-facts | `top.c.glass_wanted` / `glass_stood` | pragmatic .c mirror (added this session) — candidate to fold into `%Arrival` |
| butler up / boot flags | `top.c.butler_up` etc. | Arrival_todo §A already targets these |

The tell the owner named: **"what is tested of our Link|Invite|Cell process? must be nothing if such state is
 hiding in .c.*"** — and he was right about the SURFACE and the OUTCOME. The phase WALK is tested; the CELL it
  drives and the ROSTER it produces are not, because both live in `.c` or were never attested.

## 2. THE SURFACE LOCALITY (task: replace the `w.c.focused` pile with a particle)

Today the belly focus is a scatter of `.c` on the client world, written by `Sounditron_commission`
 (Ghost/Story/Sounditron.g) and read by `Cellui.svelte` (the belly ladder, `commissioner_focus()` at ~:494)
  and `SwarmStandup.svelte` (`link_surfaced`). Nothing snaps; nothing tests; the flicker is undebuggable
   because the transitions can't be SEEN.

**Proposed locality:** one `%Focus` particle on the client world —
```
/Focus,cell:<mainkey>/            ← the belly's focused cell (Door|Link|Radio|…), a legible scalar
   surfaced:1                      ← the auto-surface latch (presence, 1-or-absent)
   decided:<phase@at@named>        ← the per-phase decision key (so a re-decide is one field write)
```
`.c` keeps only genuine refs/clocks (`link_unlive_at` is a debounce timer — fine on `.c`). Writers set the
 particle; Cellui/SwarmStandup READ it; a Book can then assert "after the offer lands + glass stands,
  `%Focus.cell === 'Door'`, then after the name, `=== 'Link'`" — the surface becomes testable for the first
   time, and the "comes and goes" ordering becomes a visible, diffable transition.
Risk: Cellui's belly ladder is the hot render path; migrate the READ carefully, keep the mainkey semantics.
 Do with the owner at a tab (humdinger UX, un-headless-verifiable — the Arrival_todo landmine rule).

## 3. THE CEREMONY OUTCOME CHAIN — roster → charter → propagation (the "they don't know each other" bug)

The intended chain (Division_todo is the fuller design):
1. Redeem forms a **mutual `%Pier:MyCave`** (pier_hello→accept→confirm) — twins-not-friends, a device-link
    grant, not Music trust. ✓ works.
2. Soul ferries across; the Cave takes its own `%Body,role:Cave` (`Swarm_ferry_heard`, Swarm.g:4672). ✓.
3. On the `ferry_got` ack, the Captain finalises the roster: its own `%Body,role:Captain` + the Cave's
    `%Body,role:Cave` (Swarm.g:1138 block, humdinger/consenter-gated). ✓ the rows form (proven in the InvWalk
     fixture).
4. **THE MISSING WELD (fixed 2026-08-31):** the roster was NEVER signed into a `%Charter`. Empirically, the
    InvWalk fixture showed the Captain's `%Body` rows but NO `%Charter` — so `Swarm_charter_wire` was null,
     `Swarm_charter_gossip` sent nothing, and the division died LOCAL: no friend and no sibling could learn it.
      → LANDED: the Captain's finalise now `await Swarm_charter_sign(ident)` + `Swarm_charter_gossip(w2, ident)`.
       Book-inert (InvWalk 8/8 byte-identical — the puppet's hear-path `ident` is keyless so the sign no-ops on a
        Book; a real Captain has `c.keys`), so it needs the owner's LIVE confirm.

**THE STILL-OPEN GAP — the Cave never learns the Captain (the real "they don't know each other as Piers"):**
- After becoming, the Cave IS the soul. A body is NOT a friend, so there is no `%Pier` between the two bodies
   to absorb a charter onto — `Swarm_charter_heard` looks up `%Pier,pub:from` and finds none, so it drops the
    Captain's gossip.
- The Captain's `%Pier` for the Cave is keyed by the Cave's PRE-become (incognito) prepub; once the Cave
   reloads as `?I=<soul>` it answers at the body address `<soul>_1`, so the pier's routing target is stale.
- The Cave imported the soul's account BEFORE the Captain rostered itself (chicken-and-egg), so its import
   never carried the Captain's `%Body` row.

**THE SIBLING ABSORB — LANDED 2026-08-31 (`Swarm_charter_heard`, the `!pier` fallthrough):** a charter whose
 `soul` matches a KEYED identity I hold is my sibling's — verify against that soul pub (only a soul-key holder
  signs; forgery fails closed) and absorb onto that identity's OWN `%Peering` (structurally the same absorb —
   `%Charter` + `%Body` rows live under `%Peering` exactly as under a `%Pier`; highest-era-wins comes free).
    Three roads to the soul identity: beside the recipient husk in its account container (the live Cave right
     after consume — the load-bearing one), the world's `%Account` sweep (Books), the live self (the reloaded
      soul). TIMING that makes it work: the Captain signs+gossips at `ferry_got`, when the Cave is STILL
       listening at its pre-become address on the ceremony pier — the charter lands in the imported soul
        account BEFORE the reload, so the Cave wakes as the soul already knowing its family.
 GATE: SwarmGossip 4/4 + SwarmCharter 4/4 + SwarmServe 4/4 + SwarmSpread 5/5 + SwarmStaple 8/8 + InvSeal 5/5 +
  InvFerry 6/6 + InvWalk 8/8, all ok_pct 1 in check mode (byte-identical — every existing charter fixture is
   friend-directed, so the pier path returns before the sibling road). ⚠ Needs the owner's live 2-device
    confirm: after a fresh link, BOTH devices' Doors should list Captain + Cave.
 KNOWN LIMITS (follow-ups, in order):
 - the charter payload carries pub:role:address, NOT names — the Cave learns the Captain's row unnamed
    (names ride Swarm_body_note; fold `name` into the payload at the next era bump if wanted);
 - after the Cave reloads, its pre-become relay address dies — LATER charter eras from the Captain go into
    the outbox void (the observed pier_accept storm to the dead old body is this same disease). The durable
     channel is delivery to body ADDRESSES `<soul>_N` (Division_todo routing) — the Repli-shaped job;
 - the `ferry_got` ack is self-documented lossy, so the Captain's half can still miss; body-address
    re-convergence dissolves that too.
 Gate for the durable channel: a Book beat puppeting TWO keyed bodies of one soul, each ending with the
  other's `%Body` row + a shared-era `%Charter` (single-node collapses the bodies confusingly — the InvWalk
   `name:Cavey`-on-the-Captain tell — so live 2-device stays the real proof).

## 4. PREDICTABLE-STRUCTURE ACCOUNT STORAGE (the owner's bigger aim)

*"making all the account data, or a type of Wormhole+Lines storage, have more predictable structure."*
The account already IS Wormhole+Lines (`toc.snap`), but its shape is emergent, not declared. The aim: a
 uniform, predictable schema for account/roster/ceremony state so a reader (human, Cyto, daemon `/c`, a Book
  fixture) sees the same shape every time and a malformed line is a visible fault, not silent drift. Candidates:
- a declared vocabulary/gate for the account subtree (the parked mainkey gate, CLAUDE.md, is the lever);
- the roster/charter as the template — it already has a canonical, sorted, signed payload; generalise that
   "serialise-at-a-version, re-emit on digest-move (the WELD)" discipline to the rest of the account;
- Repli as the mover for grow-only cross-body state (§3).
Not near-term; the direction. The concrete first steps are §1→§3: get every piece of ceremony/surface state
 into a named particle, THEN the "predictable structure" is mostly a matter of declaring the shape they already
  share.

## 5. What landed this session (2026-08-31)
- **Captain-side `%Charter` sign + gossip at ferry_got finalise** (Swarm.g) — the missing WELD; the division is
   now attested + propagatable. Live-confirm owed; Book-inert (all Swarm*/Inv* Books green + byte-identical).
- (Boot/arrival fixes + the ONE OPEN SHARE button + the ceremony auto-drag are in `Arrival_todo.md`.)
- **This map.** The state inventory (§1), the surface-locality design (§2), the sibling-sync gap + fix (§3),
   and the predictable-structure direction (§4) — so the locus is finally legible on paper.
