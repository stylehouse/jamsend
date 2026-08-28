# Voromay_todo.md — graphing the multi-device, multi-person reality

A capture doc (2026-08-28).  The owner, describing the new shape the app has grown into:
 *"this new multi-device multi-person reality needs graphing with… Vyto?  Vyto is in flux a bit.
  perhaps Voromay may do better.  good luck."*

## 0. The reality that now needs a picture

The app used to be one person, one library, one tab.  It is now a TOPOLOGY:
- **souls** (signing identities) — and one soul may span **devices**: a phone, a laptop, a **Cave**
   (a home daemon holding the soul's keys and serving its library *as it*, via Link Device).
- **people** — friends, each a soul, sealed to you with **grants** (Music &c.), each with a shelf.
- **flows** between them — streams (radio pulling a friend's track over Repli), ferries (an account
   colonising a new device), heists (whole albums coming across), the SoundPool swap (phone↔phone
    LOFI, no Cave), the smuggle (Cave backing up a soul).

None of this has a legible picture.  The Door lists friends as rows; the glass shows cells; but the
 SHAPE — who is whom's device, which soul a Cave belongs to, which grants are live, what is flowing
  right now — is unrepresented.  The owner wants it graphed.

## 1. Vyto vs Voromay — the open renderer question

Vyto is the cell/voronoi glass the music UI rides; it is IN FLUX (see Cellsizing_todo — the
 measure loop is unsettled) and it is tuned for a SMALL number of attention-competing cells, not a
  graph of dozens of souls/devices/edges.  The owner floats **Voromay** as possibly the better fit —
   read that as: this may want its OWN renderer, not a bolt-on to the music glass.  Before building,
    decide: is the multi-device topology (a) a new mode of Vyto, (b) a sibling glass (Voromay) that
     eats the same C model, or (c) a distinct view entirely?  The bet (CLAUDE.md) says everything is
      the same legible living matter — so whatever renders it should read the SAME particles (souls,
       %Pier, %Grant, %Cave/%Link, the flow ledgers), not a parallel model.

## 2. The inventory — the topology ALREADY exists as C particles

*(surveyed 2026-08-28, file:line grounded)*  The good news that decides everything below: **the
 multi-device/multi-person topology is already a graph in the matter.**  Souls, devices, friendships,
  and flows are all snapped C particles today — the graph is a pure VIEW, and we mint nothing new to
   draw it (the bet).  The three model docs behind these rows are `Swarm_spec` (souls/pages/piers/
    grants), `Portability_doc` (bodies/Captain/Cave/ferry — the device tandem), and the flow ledgers
     in `Ghost/M/*.g`.

### 2.1 Nodes — souls and their devices

| topology element | particle (mainkey) | file:line | what it carries |
|---|---|---|---|
| **soul** (signing identity, mine) | `%Identity` | `Ghost/S/Swarm.g:42` | `sc.prepub` (16-hex address, the node id), `sc.friendly`, `sc.active:1`; keypair on `.c.keys` (never sc) |
| **my page** (outward name) | `%Peering,name:<prepub>` | `Ghost/S/Swarm.g:47` | `sc.friendly`, `%cap,<ability>` caps — the container the device/roster rows hang under |
| **friend** (another soul) | `%Pier,pub:<prepub>` | `Ghost/S/Swarm.g:2027` | `sc.pub` (friend node id), `sc.friendly`, `sc.since`; **the durable memory of a friend, one PER friend-body** (Portability §3) |
| friend's imported page | `%Peering` under the `%Pier` | `Ghost/S/Swarm.g:2033` | their cached page — lets us draw a friend node even while they are offline |
| **device** (a body a soul spans) | `%Body,pub:<vessel-key>` | `Ghost/S/Swarm.g:3797` | `sc.role` (`Captain`/`Cave`/absent=undivided), `sc.address` (its `<prepub>_N` session addr); keyed by the **body key**, not the soul — many bodies share one soul (`Swarm_body_take`) |
| **the roster of my bodies** (cohort) | `%Charter` | `Ghost/S/Swarm.g:3912` | signed attestation over the `%Body` set — `payload = pub:role:address` per body (`Swarm_charter_payload:3919`); the soul-signed truth a friend absorbs to know my devices |
| Cave / Captain station | `%Body.sc.role` value | `Ghost/S/Swarm.g:3833` | `Swarm_body_repost` derives the Post from the grant `holder`; **Cave = the disk-bearing body, Captain = where the human is** (Portability §2) |
| same-store sibling tabs (session) | `%Sibling` | `Ghost/S/Swarm.g:3738` | session-only co-presence within one browser profile — the seed of the durable `%Body` roster; **omitted from export** |

### 2.2 Edges — seals (undirected) and referrals

| topology element | particle (mainkey) | file:line | what it carries |
|---|---|---|---|
| **grant** (the friendship seal) | `%Grant,by:<pub>,for:<pub>` | `Ghost/S/Swarm.g:2038` | `sc.Grant`=Feature (`Music`…), `by`/`for` FULL pubs, `time`, `sign` (ed25519).  A **whole seal is TWO grants** (mine-to-them + theirs-to-me); holding one is a **half-seal** (DoorFace already draws "sealing — 1 of 2", `ui/DoorFace.svelte:56`) |
| revocation (tombstone) | `%NotGrant` | `Ghost/S/Swarm.g:2117` | signed revoke kept in the Pier's memory — a dead edge that must still be *visible* |
| **the friendship graph itself** | `%SocialGraph` / `%Edge,a,b,at` | `Ghost/S/Swarm.g:2040` | an already-materialised **edge list** (`a`/`b` prepubs, `at` timestamp) — the owner-side who-befriended-whom, the closest thing to a ready-made graph model |
| referral lineage (join-via) | `%ChainRoot,pub,prepub` | `Ghost/S/Swarm.g:2011` | who vouched a soul into the web — a second, sparser edge kind |
| ferry / LinkDevice invite | `%Idzeug,to:MyCave` + `%Invite:MyCave` | `Ghost/S/Swarm.g:4260` / `4100` | the "makes you rather than befriends you" seal; a ferry frame (`kind:'ferry'`, `:4235`) carries the sealed account across to colonise a new body |

### 2.3 Flow edges — directed, live, animatable

Every flow is an append-only ledger event carrying an `of:<id>` (many-events-per-track) or `pub:<who>`
 pointer — so a flow edge is *directed* and already timestamped.

| flow | particle (mainkey) | file:line | direction / join |
|---|---|---|---|
| **radio spin** (DJ streamed a track at a listener) | `%Spin,of:<id>,at` | `Ghost/M/Jam.g:63` (`Jam_spin`) | child of `%Jam,with:<dj-prepub>` — the edge is listener←DJ, one row per play |
| **like** (taste fact) | `%Like,of:<id>,at` | `Ghost/M/Jam.g:67` | listener-local, on the same `%Jam` session |
| **grab / keep** (heisted a keeper copy) | `%Grab,of:<id>,at` | `Ghost/M/Jam.g:71` | listener kept a copy — the "flow became durable" event |
| **heist** (whole album / track pull op) | `%Heist,seed:<id>,pub:<source>,state` | `Ghost/M/Radio.g:297` | `pub`=source friend (empty=own); `state:primed→wanted→asking→pulling→landed` — a directed pull with a live phase |
| heist picks | `%Pick,ref:<id>` under `%Heist` | `Ghost/M/Heist.g:3555` | the tracks inside a heist |
| **friend's crate** (their shelf, live-mirrored over Repli) | `%MusuThem,pub:<friend>` | `Ghost/M/Ra.g:686` (usage `:2304`) | a per-friend mirror container — the node-adjacent "what they have" |
| **live transfer HUD** (bytes moving now) | `%Transfer` (`dontSnap:1`) | `Ghost/M/Heist.g:2202` | reads `Repli_xfer` live (`held/total`, goodput) — the pulsing-edge data, deliberately NOT snapped |
| single-track siphon (SoundPool phone-pull) | `%Siphon,of:<id>,phase` | `Ghost/M/Siphon.g:109` | `asked→pulling→landed` — the LOFI hand-to-hand pull |
| pool press/evict pressure | `%Want,of:<id>,do:press\|pull\|evict` | `Ghost/M/Ra.g:1076` | the SoundPool economy proposals |
| smuggle / backup queue | `%Upgrade,of:<origId>` | `Ghost/M/Ra.g:1145` | lofi-copy-held-but-Original-not-yet — the Cave-backup flow |
| stream chunks (the actual bytes) | `%Stream` / `%Preview` (seq-keyed) | `Ghost/M/Ra.g:2799` / `1745` | the wire segments; too fine to draw as edges — summarise via `%Transfer` |

### 2.4 Liveness — who is reachable, honestly (the three-valued source)

The graph must never paint a false-complete flock.  Two honesty primitives already exist and are the
 exact source to read — **do not re-derive them**:

| need | source | file:line | note |
|---|---|---|---|
| **presence rung** here / fading / away | `pier.c.heard_at` → `<15s` here, `<45s` fading, else away | `ui/DoorFace.svelte:56` | already the honest three-rung read off the friend's pulse; a null `heard_at` = **away/unknown**, never invented-present |
| **liveness verdict** live/sluggish/dead/**unknown** | `liveness()` | `src/lib/O/runner_liveness.mjs:36` | the ONE shared verdict (SLUGGISH 9s / DEAD 20s / LIVE 45s / PIER_CULL 5min); returns `'unknown'` when it cannot tell — the fourth value the graph needs for "haven't heard" |
| **census under-reports, never invents** | `liveCensus()` / broadcast rotation | `scripts/runner_ask.mjs:236` (`:223` note) | can miss a wedged tab; a body absent from the census is drawn **unknown**, not gone |
| durable directory vs live presence | `%HostedIdentity` (durable) vs `%Runner` (dontSnap) | `LiesLies.svelte:1682` / `1741` | the split the graph mirrors: a soul/body node persists; its *liveness* is a live overlay that can lapse to unknown |
| who-am-I / self node | `Swarm_body_mine` (computed, never stored) | `Ghost/S/Swarm.g:3756` header | "self" is derived per-viewer — the graph roots on `Lies_self(w).prepub`, never a stored flag |

**The upshot:** node existence comes from the DURABLE particles (`%Identity`/`%Pier`/`%Body`/`%Charter`)
 — so a friend or a Cave you can't reach still has a node; its *liveness* is a separate overlay read
  from `heard_at`/`liveness()` that renders as here/fading/away/**unknown**.  Absence of a beacon dims a
   node; it never deletes it.  This is the false-complete-flock bomb (§3) discharged by construction.

## 2b. The renderer question — recommendation: **(a′) a new CYTO mode, not a Vyto bolt-on, not a Voromay from scratch**

**Recommendation: render the topology as a new mode of the existing Cyto graph glass — call the mode
 "Voromay" but do NOT build a new renderer under it.**  Reasoning, weighed against the three options the
  owner named:

- **Cyto is already a directed+undirected graph over C particles, and it is STABLE.**  `cyto_scan`
   (`Cyto.svelte:351`) walks a particle tree into `cyto_node`s with a `.c.source_n` backlink to the live
    particle (no encode cost); `cytyle_classify` (`:704`) skips/groups; `make_wave` (`:1290`) emits
     `edge_upsert` for directed edges and animates state-changes via a **wave** (`grawave`, 0.3–0.4s,
      `:100`).  A soul/device/grant/flow graph is *exactly* what Cyto renders — nodes with backlinks,
       directed edges, live-animated diffs.  Matstyle (`Matstyle.svelte`) already auto-swatches any
        particle by mainkey, so `%Identity`/`%Body`/`%Pier`/`%Spin` each get a swatch for free.
- **NOT a new mode of Vyto (reject option a-as-Vyto).**  Vyto is the voronoi *cell* glass tuned for
   ~5–15 attention-competing cells, and its measure loop is unsettled (`Cellsizing_todo`: one-shot
    measure, nothing re-solves on change).  A flock of dozens of souls×devices×edges is the wrong scale
     and the wrong primitive (cells tessellate a plane; a topology wants nodes+edges).  Bolting it onto
      the in-flux music glass inherits an open bug for no gain.
- **NOT a from-scratch sibling renderer (reject option b — mostly).**  A brand-new "Voromay glass" is
   new bespoke machinery where a deletion/reuse was available — the anti-pattern Homethink §4 names.
    Cyto already solves node-backlink + directed-edge + wave-animation; re-solving them is pure cost.
- **What "Voromay" IS, then:** a **named Cyto scan target + a Matstyle palette + a liveness overlay**,
   not a renderer.  Concretely: a `w:Voromay` (or a scan mode flag on `w:Cyto`) whose scan root is the
    account tree (`%Identity`→`%Peering`→`%Pier`/`%Body`) plus the flow ledgers, with (i) device
     sub-nodes drawn as Cyto **compound** children of their soul (`cytyle_classify` already returns
      `compound`), (ii) grant edges undirected, (iii) flow ledger rows as directed edges, and (iv) a
       liveness overlay tinting each node from `heard_at`/`liveness()`.  If the voronoi *look* is wanted
        later, the **Voro fold organ** (`Ghost/V/Voro.g`, already built) crushes a Cyto graph into
         voronoi panes via `%Seem` — so "Voromay = Voro-over-the-topology-Cyto" is a free upgrade path,
          not a prerequisite.  **The name can survive; the from-scratch renderer should not.**

*(One honest caveat: Cyto is slated to "freeze" per the renderer survey.  If it is truly frozen to new
 modes, the fallback is option (b) but built as a THIN Cytoscape reuse — same library, same
  `source_n`/wave patterns lifted — never a green-field engine.  The owner should confirm Cyto's
   freeze status; see §4 open question.)*

## 2c. The smallest honest prototype — "me + my Cave + one friend + their track across"

The minimal picture the owner asked for, and exactly which particles feed each node/edge:

**Nodes (4):**
1. **me (soul)** — `%Identity` (`sc.prepub`), rendered as the root; `Swarm_body_mine` picks which
    `%Body` row is this viewer.  Liveness: always "here" (it's us).
2. **my Cave (device)** — my `%Body,role:Cave` (`Swarm.g:3797`), a **compound child of node 1**.
    Liveness overlay from its beacon `last_heard` via `liveness()`; drawn **unknown/away** if the daemon
     hasn't pinged (the honest case — a sleeping Cave is dimmed, not dropped).
3. **friend (soul)** — my `%Pier,pub:<friend>` (`Swarm.g:2027`) + its imported `%Peering`; node exists
    from the durable Pier even if they're offline.
4. **their Captain (device)** — the friend's `%Body,role:Captain` absorbed from their `%Charter`
    (`Swarm.g:3912`), a compound child of node 3.

**Edges (3):**
1. **the seal** (me ↔ friend) — the pair of `%Grant` rows under the `%Pier` (`Swarm.g:2038`).  Drawn
    **undirected**; **half-seal honesty**: if only one of the two grants is present, draw it dashed and
     label "sealing — 1 of 2" (reuse the DoorFace predicate, `DoorFace.svelte:56`).
2. **the live stream** (their Captain → me) — a `%Spin,of:<id>` on my `%Jam,with:<friend>`
    (`Jam.g:63`), drawn as a **directed** edge animated by the Cyto wave; its "moving now" thickness/
     pulse reads the live `%Transfer` HUD (`held/total`, `Heist.g:2202`).  When the track lands as a
      keeper, a `%Grab` (`Jam.g:71`) marks the edge durable.
3. **(implicit) their crate** — `%MusuThem,pub:<friend>` (`Ra.g:686`) as the friend node's "what they
    have" badge, the reservoir the stream pulls from.

**The truth test this prototype must pass:** turn the Cave daemon off and the Cave node goes
 **unknown/away** (dimmed) while remaining on the graph; drop one grant and the seal edge shows
  **half-sealed**, not connected; stop the stream and the directed edge stops pulsing but the `%Spin`
   history remains.  If all three degrade honestly — dim, half, still — the picture is truthful, and
    that IS the prototype's acceptance gate.  Build it as a Cyto scan over a hand-built two-soul
     `Waft:Account` fixture first (no wire), then point it at a live `runner_ask`/DoorFace pair.

## 3. Bombs / constraints carried in

- Live-tab behaviour rides the HUMDINGER gate; a runner records fixtures without it.  A new glass
   must keep the fixture set byte-identical by the same discipline.
- The census can miss a wedged tab, never invents one (Cluster_spec) — the graph must show
   "unknown/unreachable" honestly, not a false-complete flock.  **Discharged by construction in §2.4**:
    nodes come from durable particles; liveness is a separate overlay that dims to unknown, never deletes.
- `.c` refs for backlinks (no encode cost); never an object in `.sc`.  Cyto's `source_n` is exactly this
   pattern — reuse it, don't invent a parallel one.

## 4. The one open question the owner must answer first

**Is Cyto open to a new scan mode, or is it frozen?**  The whole recommendation (§2b) rides on reusing
 Cyto's `cyto_scan`/`make_wave`/`source_n`/`edge_upsert` machinery for a `w:Voromay` scan target.  The
  renderer survey flagged Cyto as "production, will freeze."  If Cyto will still accept a new scan root +
   Matstyle palette + liveness overlay, this is a **days-not-weeks** view over particles that already
    exist — build the §2c prototype directly.  If Cyto is truly sealed, the fallback is a thin Cytoscape
     reuse under the "Voromay" name (same library, lifted patterns) — still NOT a green-field renderer.
      Decide this before anyone writes a line; everything else in the design is settled by the inventory.

Secondary opens (lower stakes, decide during build): (a) do device sub-nodes render as Cyto **compound**
 children or as satellite nodes with a "same-soul" edge? (compound reads truer but Cyto compound layout
  can be fussy at scale); (b) which flow ledgers earn a persistent edge vs a transient wave-only pulse —
   leaning: `%Spin`/`%Heist`/`%Grab` persist, `%Transfer`/`%Stream` are live-only pulses; (c) does the
    graph read a live world (a runner tab, via `runner_ask`) or a snapped `Waft:Account` fixture — both,
     but the fixture path is the testable one and should come first.
