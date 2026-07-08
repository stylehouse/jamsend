# Cluster_spec.md — the cluster: trust substrate, runner flock, real-isolation testbed

The cluster is the layer **above** the Peeroleum spine where identity, trust, membership, and
 *running things on other machines* live. This doc is its spec. It supersedes the old
  `ClusterTrust_handover.md` (a two-job handover that is now mostly DONE — folded in below as the
   **trust substrate**), and absorbs the runner-fleet ops notes.

Pair it with **`spec/Peeroleum_handover.md`** (the spine: frames, inseq, retx, fault, multicast).
 The shorthand is **Peeroleum + Trusting**: Peeroleum is the transport, *Trusting* is everything
  cluster — the reborn lineage of the old `MTrusting`/`Trusting`/`Gardening` garden (heading 1).

The triad: this is **how it runs**; `Swarm_spec.md` is **who's on it** (the p2p social side — identity,
 presence, sharing); `Radio_spec.md` is **what streams**. Identity begins here (the trust substrate, §2)
  and becomes portable + social in `Swarm_spec`.

> **This doc is now the single home** for the cluster/runner/robustness story. The old `Runner_network.md`,
> `Runner_quality_handover.md`, `Runner_talk_TODO.md`, and `Cluster_runner_handover.md` folded in here
> (§3.2b substrate · §3.3 badges/CLI/ladder · §3.9 quality+liveness · §5 drive→examine→accept) and were
> deleted 2026-07-06; the retired `Robustness_plan.md`'s five hardening organs distributed to their §homes
> (the assert-vs-derive **principle** → head of §2; Organ 1 latch → §3.2b; Organ 2 ack → §1; Organ 4
> identity 9→2 → §3.2a, **DONE + verified**; Organ 5 nav-contract → §3.8; Organ 3 authoritative-absence → §2.0a). `Robustness_plan.md` is now
> fully absorbed — retired to `spec/history/`. Remote-Wormhole `bin_write` + nav
> precedence: §3.8.

---

## 0. The north star — remote `%Rungo`, and why the whole edifice

Today a run (`%Rungo`, the run-authority token) lands on **one shared runner** in a Chrome on the
 human's desktop, that Claude *and* the human both haphazardly shoot runs at. The destination:

- **Remote `%Rungo`** — an editor hands a run to a runner **it owns**, that **focuses on it**, over
   the relay. Not a shared random one.
- **A daemonised `Lies%runner` flock** — *little dockers full of real Chrome instances*, each a
   self-booting peer. Real browsers ⇒ real WebRTC, real serialization, real NAT/timing.
- **Large swarm simulations** — M peers that must *keep in contact as best they can* under real
   loss. We pump a known corpus of "news" through them and **measure how much each actually got**:
    a delivery-coverage metric (heading 6) that becomes the **fitness function** for the reliability
     code we just spent steps 2–33 of PereProof proving in miniature.
- **The same harness for audio** — later, the audio-streaming code gets the same treatment: measure
   stream continuity/gap/jitter across a real swarm instead of message coverage.

**Why real dockers, why now.** The adversarial mutation pass (2026-06-29, on PereProof 30–33)
 confirmed the tests have real teeth — break the production retx/fault/inseq code and the Book goes
  red — *but* it pinned the ceiling: the Story transport is **in-process**. `make_lossy_partner`
   injects loss at `port.recv`, a direct JS function call — no wire, no serialization, no real
    concurrency. Step 33's "crossfire under load" is deterministic synchronous delivery, not a race.
     **Dockerised real-browser peers close exactly that gap.** The swarm simulation IS the Tier-3
      two-origin real-transport harness the Peeroleum handover says we owe — it just also happens to
       be the runner flock. One build, two payoffs.

This is "a real leap of complicatedness" (running several parts of a Story *in unison* across a
 fleet). It fits: the spine is proven, the trust substrate is built, the missing pieces are small
  and enumerated (heading 7).

---

## 1. Peeroleum + Trusting — and the old garden to reincarnate

The cluster reincarnates a **legacy garden** the human built before the particle rewrite. Use its
 *concepts*, not its code (the old `.svelte` is pre-C-model). The lineage to port, each reborn on the
  Peeroleum spine + the cluster_trust signing layer (heading 2):

| old concept (`Trust.svelte`, `Gardening.svelte`, `Peerily`, `OverPiering.svelte`) | reborn as |
|---|---|
| **`Trusting` / `TrustingModus`** — the "high-level clustery thinking" ghost | the Lies%runner orchestration + relay arbitration (this doc) |
| **`Idzeug` / `Idzeugnation`** — identity birth | mint a **tag-keyed cluster Idento** = the `?I=<tag>` fork (3.1) |
| **`OverPiering` / `%Hath`** — "all known peers, joined from every data source" (the who-exists directory) | the relay's **bind table** of verified Idento→socket (the modern roster) |
| **`Ringing` / `RingUp`** — a contact attempt | dial a peer over relay→WebRTC; `ring✗` = the failed-connect tag |
| **`Ping`** — onlinity | the LIVE/SLUGGISH/DEAD liveness the app already computes |
| **`give_them_trust`** (trust grants from Feature checkboxes) | membership of the **trusted flock** (`CLUSTER_TRUSTED_PUBS`, 2.2) — a trusted pub may do everything (2.8); finer per-action grants, if ever, are app-level Tyrant-ghost particles, not certs |
| **active-terminal migration / Id hop-over** | mint a fresh tag-Idento, re-grant, re-bind at relay, drain the old (3.1) |

So "Trusting" is not new invention — it is the garden's membership/contact/trust machine, rebuilt
 on a transport that now actually works. Keep the names where they still fit; they carry meaning.

**The delivery-honesty contract (Robustness Organ 2 — confirm, don't ack-and-hope).** The spine must
 **never ack undelivered or unhandled work, never return a "sent" seq on a dead transport, and surface every
  drop** — a silent success over dropped work is how a lost frame masquerades as a delivered one. The
   specimens the audit named: an unregistered frame type ACKed as handled (`Peeroleum.g` req_unemit); a
    transport drop that still hands the caller a "sent" seq (`:393`); async handlers acked true synchronously
     (`LiesLies.svelte:291-312`); an unknown/late corr dropped so a slow-but-arrived reply looks lost
      (`RemoteWormholeNav`). *Landed:* an unregistered frame type now **warns loudly**; the drop-returns-seq
       case turned out already-safe (`Lies_send_rungo` gates on `channel_live`, the rungo is booked and
        `Reliable.g` retx's). *Still owed (deferred, needs live proof):* marking a faulty frame `%faulty` and
         **not** acking it — held back because it would retx-wedge conditionally-registered handlers
          (`test_*`/`repli_*`/`audiochunk`/`stream_offer`). A second open: `MusuReplica`'s `%Crush_Tree`
 husk hides `body_hash`/ack from the delivery layer — decide whether a crushed husk counts as
  "delivered" (and what its ack surface is) before re-recording `MusuReco` (`musureplica-crush`
   memory). The positive template already in the tree:
           `LiesStore.svelte`'s stuck-read watchdog escalates+nags, and `land_good` refuses an `{error}` body.

---

## 2. The trust substrate (the signing layer — ALREADY BUILT)

> This is the former `ClusterTrust_handover.md`, kept intact because it is load-bearing and a
>  memory-less instance needs it verbatim. Most of it is DONE (heading 2.7). It exists so that the
>   privileged frames a flock sends — `gen_write`, `restart_request` — are **signed by a cluster key
>    and verified against the trusted flock**; unsigned/foreign frames are dropped. A sender in the
>     flock may do everything — there is no separate capability layer (2.8).

**The principle this whole layer is built on (assert vs derive, trust vs confirm).** *State is asserted
 instead of derived, and boundaries are trusted instead of confirmed* — that one shape was the root of the
  2026-07 grant saga (the badge *asserted* "granted" instead of *deriving* it from a live crypto verdict;
   the runner *trusted* an unconfirmed `not_found` and wiped the registry; the editor *trusted* `claim.for`
    as a routable address instead of *deriving* it at send; a reconcile *re-asserted* an identity invariant
     on a hot path and dropped a good grant on a blip). The cure is always the same: **derive from the live
      source at point of use (or reconcile against it every tick), and make every boundary answer a
       three-valued question — yes / no / couldn't-tell — so "couldn't-tell" can never masquerade as "no".**
        The signing layer below is the trust-vs-confirm half; the identity collapse (§3.2a), the latch
         reconcile (§3.2b), and the authoritative-absence read (Organ 3, §2.0a) are the
          derive-not-assert half. *(Distilled from the retired `Robustness_plan.md` — all five organs now
           folded into their §homes here, Organ 3 included.)*

### 2.0a Authoritative absence — the three-valued read (Organ 3, app-wide)

*The one hardening organ that is **not** cluster-specific — it governs every read that can overwrite durable
 data — folded in here from the retired `Robustness_plan.md`. If this doc is ever gutted, lift this principle
  into `CLAUDE.md`; it is load-bearing app-wide.*

**Principle.** A read is **three-valued**: `present(content) | absent | unavailable(reason)` — never conflate
 "genuinely gone" with "couldn't fetch". **A transient or empty read must never overwrite durable data.**
  Enforce it at the ONE choke point (`LiesStore` `land_good`), which re-confirms once before trusting a
   `not_found`, so authoritative-absence is inherited by every consumer instead of scattered per-caller
    `notfound_once` band-aids. Gate any empty-read auto-save on *confirmed* absence only.

**Landed 2026-07-05.** `land_good` re-asks ONCE before landing a `not_found` (deduped per-req via
 `req.c.nf_counted` across the Phase-2 + read_good sites); a transient not_found for a registry Waft never
  lands as absence; `Auto.svelte`'s Library got the same re-confirm on its `rw` queue; `text/Doc` is EXEMPT
   (a not_found doc is a new blank file). This was the grant-registry-wipe thread that started the whole
    robustness saga.

**Still-open.** The three-valued state at `land_good` is a *re-ask*, not yet a **contract flag on the reply**
 — so `RemoteWormholeNav` still forwards a `not_found` verbatim (only local FSA re-lists before answering);
  this is the same seam tracked as **Mode 3** in §3.3. Positive templates already in the tree: `Story.svelte`'s
   re-confirm-before-accepting-absence, and `LiesKeep`'s one authoritative snapped home + a coalesced mirror
    that can't feed a write loop.

### 2.1 The threat & the end state
`gen_write` (the editor shipping a compiled `.go` down its relay socket → Node writes it to
 `src/lib/gen/**`) was **unauthenticated**: any ws client reaching `/relay` could write arbitrary
  code to disk, and Vite runs it — an RCE. End state: **every privileged frame is signed by a cluster
   key and verified against the trusted flock; unsigned/foreign frames are dropped.** "All clients
    have and use the trust."

### 2.2 The pieces that exist
- `src/lib/p2p/cluster_trust.ts` — the primitives (node AND browser; only the PUBLIC half is
   browser-safe):
  - `signHeader(header, privHex)` → hex sig. **Node-only** (needs a private key).
  - `verifyHeader(header, trustedPubs)` → the matching full pubkey, or `null`. **Fail-closed**:
     empty trusted set ⇒ `null`.
  - `canonicalHeader(header)` — the signed unit: header **minus** its `sign`, key-sorted,
     `JSON.stringify`. Signer and verifier serialise identically regardless of key order.
  - `loadTrustedPubs(env)` (`CLUSTER_TRUSTED_PUBS`), `loadRoleKey(role, env)`
     (`CLUSTER_IDENTO_<ROLE>_KEY`), `prepubOf(pub)` (16-hex address).
  - `sha256hex(data)` (browser+node, crypto.subtle) — the shared body-commitment digest.
  - `browserTrustedPubs()` / `browserRole()` — browser-side trust exposure.
- `scripts/gen-cluster-identos.ts` — **REMOVED 2026-07-01.** Key genesis is now the editor's 🪪 “Set up
   cluster trust” (`Lies_cluster_setup`): it writes `.env.cluster-pubs` (PUBLIC) + mints `.env.cluster-claude`
    (the only remaining SECRET role key). Runners self-mint via `?I=`; no per-role flock file is handed out.
- `src/lib/p2p/Identos.ts` — the PUBLIC deterministic pool (peer NAMES for flock tests). **Distinct
   from cluster_trust**: Identos = public addresses, no secrecy; cluster_trust = secret signing keys.
- `src/lib/server/relay.ts` — the `/relay` forwarder; `header.sign` already crosses the wire (binary
   frame `[header JSON]\n[raw buffer]`, header cleartext so the relay routes on `to`; signed ≠ encrypted).

**The `.env*` inventory — where the keys actually live** (all gitignored, `.env.*`; the editor's 🪪 setup
 writes `.env.cluster-pubs` + mints `.env.cluster-claude`, so no host holds a key it doesn't own):
> **2026-07-01 — the trusted set is now just {editor, claude}; runners are OUT.** The trusted set is the
>  **code-push allowlist** and nothing else — the only two gates that read it are the relay's `gen_write`
>   (compiled `.go` → disk = the RCE surface) and the editor's `ghost_compile` verify. Only the **editor**
>    (signs `gen_write`) and the **claude CLI** (signs `ghost_compile`) sign those, so only they need to be
>     trusted. A **runner signs nothing the set verifies** (its `hello` is self-auth; advertise/ping/run_*
>      are unsigned) and its disk access rides **`%Grant`** (per-runner, editor-signed, verified by `by ==
>       editor.pub`), NOT set membership. So: **drop `.env.cluster-editor` + `.env.cluster-runner`.** The
>        editor now uses a `?I=` %Identity and SELF-PROVISIONS via IdHatch's **“Set up cluster trust”**
>         (`Lies_cluster_setup`): it FSA-writes its own pub into `.env.cluster-pubs` and mints
>          `.env.cluster-claude` if absent. Runners self-generate (`?I=`). (`gen-cluster-identos` has since
>           been REMOVED — the editor is the sole genesis.) **Both the relay AND the Vite bake read the set at start/build → a
>            dev-server RESTART is required after any change.** (The bullets below describe the pre-2026-07-01
>             per-role-key model; kept for the docker/env_file mechanics, which still apply to `claude`.)
- **`.env.cluster-pubs`** — *PUBLIC*. `CLUSTER_TRUSTED_PUBS` = comma-list of the flock's full pubkeys.
   Distribute everywhere; `env_file` into every verifier; `vite.config.ts` bakes it to
    `VITE_CLUSTER_TRUSTED_PUBS` for the browser. **This list IS the authority** (2.8) — in it ⇒ trusted.
- **`.env.cluster-<role>`** — *SECRET, one per role*: `CLUSTER_IDENTO_<ROLE>_KEY` (+ `_PUB`). Post-2026-07-01
   only `claude` remains a pre-minted role key; `editor`/`runner` are retired (see the note above). Each file
    goes to that role's host ALONE and is `env_file`d into ONLY that service (docker-compose), so no container
     holds a foreign role's private key.
- **The browser** can't read node env files: it holds its role key out-of-band in the top House's Dexie
   `.stashed.cluster_idento` via the 🪪 Id hatch (`IdHatch.svelte` — paste a `.env.cluster-<role>`).
- **To rotate a key (editor-driven now):** a new EDITOR identity is `?I=new` (then re-run “Set up cluster
   trust” to rewrite `.env.cluster-pubs`); a fresh CLAUDE key is `rm .env.cluster-claude` then “Set up cluster
    trust” again. Restart the dev server after either (relay + Vite re-read the set). Rotation breaks live peers
     holding the old set — do it deliberately.

### 2.2a Cold-start — standing up a cluster from nothing
Every key in the cluster now traces to ONE act: opening the editor and clicking a button. No pre-seed
 step, no `gen-cluster-identos` run in the normal path.

1. **Open the editor cold:** `http://localhost:9092/Otro?E=Editron&I=new`. `?I=new` mints the editor's
    `%Identity` — its signing key — and rewrites the URL to `?I=<prepub>` (bookmark THAT; it RESUMES the
     same editor, whereas `?I=new` would mint another). `:9092` = the editor (the `EDITOR_URL` host);
      `:9091` = the dev server where runners live.
2. **🪪 Id page → “Set up cluster trust”** (`Lies_cluster_setup`) — the ONLY key-minting step: it FSA-writes
    `.env.cluster-pubs` = `{this editor's pub, a freshly-minted claude pub}` and writes `.env.cluster-claude`
     (the claude CLI's secret) if absent (an existing one is reused, never rotated out from under a live CLI).
3. **Restart the dev server.** The relay reloads `CLUSTER_TRUSTED_PUBS` and Vite re-bakes
    `VITE_CLUSTER_TRUSTED_PUBS` — both read the set only at start/build. The 🪪 trust line flips ⚠️→✅ and the
     editor's `gen_write` compiles are authorised.
4. **Runners join by URL** — `…:9091/Otro?I=<tag>` (grid-idle) or `?B=<Book>`. Each self-generates its own
    `%Identity` (no key handed to it); remote disk access is an editor-signed `%Grant`, not set membership.
     The **claude CLI** reads `.env.cluster-claude` to sign `ghost_compile`.

So the editor cold-start generates every key that matters — its own, the claude CLI's, and the trusted
 list — and runners mint their own. **`scripts/gen-cluster-identos.ts` was REMOVED 2026-07-01** — the editor
  is the sole key genesis, and there is intentionally NO no-browser cold-start path any more (a cluster is
   always born at an editor). Rotation is editor-driven too (see §2.2's rotate bullet); the previous
    `--force` script path is gone.

### 2.3 The signing contract
A privileged frame's signed unit is its **header** (addressing + intent + a body commitment), never
 the body bytes directly:
1. Compute `body_hash` over the payload, **then** put it in the header.
2. `sign = signHeader(header_without_sign, roleKey)` — covers `from`/`to`/`type`/`body_hash`/…. One
   signature authenticates the whole frame.
3. Send the header **with** `sign` (+ body/buffer). The verifier strips `sign`, re-serialises
   canonically, checks against `CLUSTER_TRUSTED_PUBS`, **and** re-checks `body_hash` against the
    received body.

**body_hash is sha256 on both sides now** (was a non-cryptographic FNV hack on the spine to keep the
 inbox sync; that constraint is gone — delivery is async all the way). So `header.sign` over it
  genuinely pins the body. Nuance is the **input**: the spine hashes the raw `Uint8Array` buffer;
   cluster_trust `sha256hex` hashes the body **string**. For a string body (`gen_write` ships `.go`
    text) use `sha256hex(body)`; for a raw buffer, hash the bytes the spine way so signer/verifier
     agree byte-for-byte.

### 2.4 The three constraints that shape who-does-what
1. **The browser cannot sign.** `CLUSTER_IDENTO_*_KEY` must never enter a bundle. So a browser
    editor either signs via a **node** signer, or — *as chosen* — holds its own key in the top
     House's Dexie `.stashed.cluster_idento` via the 🪪 Id hatch (`IdHatch.svelte`, paste a
      `.env.cluster-<role>`, read live, never bundled).
2. **ed verify is async; the Peeroleum inbox is sync.** `verifyHeader` is a Promise; `pump_inbox` is
    sync (the §7.3 serial lock + mock determinism). Verify a routed privileged frame in the **async
     carrier-recv window** (`Peeroleum_deliver` runs in `post_do(async …)`), stamping a verified flag
      the sync inbox reads — OR verify control frames in the **relay** (node, no Atime). `gen_write`
       is a relay control frame → the easy case.
3. **The browser verifier needs the trusted pubs.** `vite.config.ts` bakes
    `VITE_CLUSTER_TRUSTED_PUBS` + `VITE_CLUSTER_ROLE` (PUBLIC pubs + role label only). Node reads
     `process.env` directly.

### 2.5 Privileged frames
| frame              | path                              | signer          | verifier              |
|--------------------|-----------------------------------|-----------------|-----------------------|
| `gen_write`        | control frame → relay writes disk | node (cli)      | **relay** (node)      |
| `dock_push`        | routed envelope (`Peeroleum_on`)  | editor/cli      | runner (recv window)  |
| `this-dock-updated`| routed envelope                   | editor          | recipients (recv win) |
| `claim`/`release`  | routed envelope (`Peeroleum_on`)  | editor/runner   | relay arbitrates + recipients — *only if a contended mutex needs it; else app-level (3.5)* |
| `restart_request`  | control frame → host reset socket | relay/supervisor| host supervisor       |

`gen_write` is the RCE; verifying it in the relay is the highest-value, self-contained fix. These
 frames authenticate *who sent what* — and *who* is the whole story: a sender in the trusted flock may
  do everything (allocate, run code, honour a `%Rungo`); there is no separate capability layer (2.8).

**Signed `gen_write` shape (the wire contract the relay gate verifies):**
```
{ control: 'gen_write',
  path:      'gen/N/Foo.go',
  body:      '<.go source>',
  from:      '<signer prepub, 16-hex>',
  body_hash: '<sha256(body) hex>',
  sign:      '<ed25519 over canonicalHeader({control,path,from,body_hash})>' }
```
Relay: `body_hash === sha256(body)` AND `verifyHeader({control,path,from,body_hash,sign}, trusted) ≠ null`.

Point-to-point delivery uses `to:<Idento.pub>` (relay binds each verified Idento as its addr on the
 signed hello), reusing `bind`/`deliverLocal`; the `claims` map (today `@channel → socket`)
  generalises to the leased `%Claim` token.

### 2.6 Migration gotcha
Turning on enforcement = setting `CLUSTER_TRUSTED_PUBS`. The moment it's set, the relay **drops the
 browser editor's unsigned `gen_write`** unless that path already signs (constraint #1). So **wire a
  signed gen_write path BEFORE (or with) configuring the cluster env.** Until then the relay logs `⚠
   gen_write UNAUTHENTICATED` and warn-and-allows, so the dev loop keeps working un-minted.

### 2.7 What's already DONE (the substrate is real)
- **Editor signs `gen_write`** (the RCE client half): `Lies_send_gen_write` (LiesLies.svelte) is
   async, signs per the contract; `Lies_cluster_idento(w)` resolves `{pub,key}` (browser ← stashed;
    node ← `loadRoleKey`); forward-compatible (unsigned + warn-allow until pubs deployed). Verified
     against a relay-gate replica (accept / tampered / foreign / unsigned).
- **`this-dock-updated` event + browser trust exposure**: signed unit in the consumer payload (spine
   ferries opaque, no trust awareness); editor handler verifies in the async recv window; emitters
    `Lies_send_dock_updated` (browser) + `ghost-update --notify-editor` (cli signs with
     `CLUSTER_IDENTO_CLAUDE_KEY`); `vite.config.ts` bakes the PUBLIC pubs. Round-trip tested.
- **Role/env convention**: secrets SPLIT per role; each service `env_file`s only what it needs
   (`required:false` so an un-minted cluster still `up`s). Relay/dev-server = verify-only
    (`.env.cluster-pubs`); CLI `claude` = its own key (`.env.cluster-claude`, it signs); browser role
     from `?E=`/`?B=` or `VITE_CLUSTER_ROLE`, key from stashed.

**THE ONE REMAINING SUBSTRATE HOP (needs the spine):** the editor inbox still drops PRE-`%Ud`
 senders (`Peeroleum.g:308-310`). Editor↔runner works (both Ud-handshaken), but **cli→editor** is
  dropped pre-Ud until the spine accepts a cluster-trusted frame in the async recv window (verify the
   payload sign; if trusted, treat as Ud-ok). Also open: cli signed `gen_write` for remote runners;
    the **PereEditrogression** demonstration test.

### 2.8 Capability = membership of the trusted flock (no certs)
*Who sent this* is the **whole** authorization. There is **no capability-cert layer, no tyrant, no trust
 tokens.** (A third-party tyrant-rooted cert chain was prototyped on 2026-06-29 and **removed the same
  day** as needless ceremony — the human's call: *"we don't need new cluster certs."*) The model is dead
   simple: **a sender whose pub is in `CLUSTER_TRUSTED_PUBS` (2.2) may do everything** — run code,
    allocate a runner, honour a `%Rungo`, ask for a host restart. Anyone not in the flock is dropped.
     Knowing the sender (a verified frame signature, 2.3) **is** the permission check.

This is deliberately coarse, and right for now: the flock is a handful of keys the human controls
 (editor / runner / claude today). The near-term direction is **a real cluster soon, still with no
  tokens** — just knowing the sender and verifying their signed emissions. If a finer per-action grant is
   ever wanted, it belongs as **app-level particles** in the Tyrant ghost — `Ghost/N/Tyrant.g` already
    models trust the garden way (`%trust,grants` + maz-ordered `%req:policy` leaves), crypto deferred —
     **not** a new privileged frame and **not** certs. Until then: trusted = trusted.

---

## 3. The runner flock — Ids, addressing, the restart service

The operations layer that rides the trust substrate: a grid of Chrome app-servers running the app, a
 `Cluster/**` of **forkable Ids**, a runner an editor *owns*, a coordinator that asks for a restart
  when a crash-quorum of tabs dies, and an **Id hop-over** to a fresh identity.

### 3.0 The runner is **app-level** — a stowaway with enormous leverage
The runner is **not** a privileged separate process; it is an **app-level role**, a stowaway in an
 ordinary Chrome tab. It boots the same app everyone else does and then *starts most of it* — it hosts
  the **EntropyProfiles**, acquires the spine, drives Books. That it has huge leverage (it can run code,
   hand out `%Rungo`) — but its right to do so is just **membership of the trusted flock** (2.8), not a
    special binary and not a cert. Same network, same spine; **being a trusted pub, not privilege**,
     separates a runner from a tab.

**`?Runner` (optionally `?Runner=<name>`)** is the boot mode that *makes* a tab a runner — the dedicated
 successor to "a tab becomes a runner via `?B=`". A named runner **registers into a self-assembling
  pool** under that name; an unnamed one takes an auto-name. Registration = announce presence (signed by
   a flock key, 2.3) → land in the roster (the modern `OverPiering`), idle and available for allocation.
    No tyrant, no cert to fetch — a runner is trusted because its pub is in the flock (2.8). The pool then
     self-assembles: runners come online, check in, and a multi-runner Story musters its cast from
      whoever answered (5).

### 3.1 `?I=<tag>` — fork identity at the TAB, not the OS profile
Today: *role* from `?E=`/`?B=` (`Lies_role`); *signing key* = the top House's
 `.stashed.cluster_idento` (the 🪪 Id hatch, `loadRoleKey`). Add **`?I=<tag>`** to select WHICH
  forked Idento *this tab* uses — minted/loaded from `stashed` keyed by the tag. Then **one browser
   profile hosts many separable runner tabs**, and you **spawn a flock by clicking N links**, each
    carrying a different `?I=`. The lightweight successor to `ty/`, which forked at the OS level (a
     whole Chrome `--user-data-dir` per profile). The Idento + trust grants travel with the tag.
      **Id hop-over** = mint a fresh tag-keyed Idento, re-grant, re-bind at the relay, drain the old
       (the garden's `Idzeugnation`, reborn). `?Runner=<name>` and `?I=<tag>` **compose**: the simplest
        scheme lets the runner name key both the pool entry and the tag-Idento, with an explicit `?I=`
         overriding when one identity must serve several roles (open: 8).

### 3.2 `to:<pub>` — point-to-point addressing by identity
The relay binds each verified Idento pub → its socket on the signed hello, and `deliverLocal`s a
 frame whose `to` is a pub to that socket. This **generalises the `claims` map** (today `@channel →
  socket` for multicast) to the unicast identity case. This is the single primitive remote `%Rungo`
   needs: "send this run to runner X" = a frame `to:<runnerX.pub>`.

**BUILT (2026-06-29, headless-verified):** the relay's `hello` control (`relay.ts handleHello`) does the
 AUTHENTICATED bind — a peer signs `{control:hello,from,pub,ts}` with its key, the relay verifies the
  self-sig (`verifyHeader` against the *claimed* pub) and binds `prepubOf(pub)` → socket, freed on
   disconnect. `?addr=` (unauthenticated) still works for the un-migrated path. ts-freshness bounds
    replay; a relay-issued nonce challenge is the noted hardening. Proof: the `to:<pub>` block in
     `scripts/relay-test.ts` (verified bind, delivery, and a forged hello binds nothing — no hijack).
      **Still client-side:** the browser/runner sending the signed hello on connect (`Tribunal.g`
       Socket_real) — relay accepts it, no peer emits it yet.

### 3.2a The identity model — one key, one derived address (the 9→2 collapse)
**BUILT + VERIFIED live 2026-07-05/06** (was Robustness_plan Organ 4, the "9 divergable tiers" deep fix).
 Verified on the bridge runner `49dee91d`: `ping` gives `self === clustation_self` (routing intact), and
  MusuReco flipped `failed 0/11` (starved) → `done 11/11` once the addressed replies were live. A peer used to
   hold ~9 notions of "who am I" and re-sample a two-tier fork (`Clustation_self ??
  stashed`) at the moment each ran — so the prepub it *advertised* could drift from the prepub the relay
   *hello-bound* it under, and every `to:<us>` frame silently misrouted (the 20s stall, "both runners ran
    it", the grant for-check flap). The collapse:

- **One signing key, one derived address.** `Lies_cluster_idento` is the SOLE key resolver (Clustation-
   active `??` `.stashed` `??` node env, in that precedence). `Lies_self` is now a **pure derivation** of
    it: `prepub = prepubOf(idento.pub)` — and `prepubOf` is a pure prefix (`pub.slice(0,16)`). Because the
     relay hello-binds under `prepubOf(idento.pub)` too, **advertised prepub ≡ hello-bound prepub by
      construction** — they can't diverge. The old `Clustation_self` face survives only as the cosmetic
       **nick** (never routed on). At boot an un-migrated peer holding only a bare `.stashed.cluster_idento`
        is auto-`Clustation_adopt`ed into a first-class `%Identity` (routing was already correct; this just
         makes it visible to the roster/IdHatch/registry).
- **The fatal invariant (the loud gate the collapse earns).** At the hello send (`Lies_channel_up`), assert
   `Lies_self(w).prepub === prepubOf(idento.pub)`. It can't fire in healthy code — it's there to catch a
    *regression* (a re-introduced identity tier) at the exact seam, LOUDLY, not as a silent black hole. Not a
     hard throw (that would abort the hello and strand us worse): it screams, rings the Relay Brink, and sets
      `w.c.identity_diverged` — which `Lies_advertise` honours by **refusing to advertise an address we can't
       receive on**. Self-heals when an Id switch re-aligns.
- **A grant's `for` is the grantee's FULL pub, not a truncated prepub.** A 16-hex prepub can't verify a sig,
   so a prepub-`for` was a bare matching string, not an identity — the property that let it drift (Organ
    4/H2). The advertise beacon now carries the full `pub` beside `from` (the prepub); the editor stores it
     on the `%HostedIdentity`/`%Runner` row and mints `grant.for = full pub` (form-matches `by`, so a %Grant
      is verifiable end to end). **Routing derives `to = prepubOf(claim.for)` at SEND** — never a frozen atom
       — and since `prepubOf(prepub) === prepub`, one expression addresses both new full-pub grants and old
        prefix grants. Fully **feature-detected + back-compatible**: an old beacon (no `pub`) → the editor
         grants the prepub as before; the runner's for-check accepts either via `prepubOf(atom.for)`.

**Roles divide, addresses deliver — the mature address+role model.** A **role** (editor|runner) is a
 *kind*: it gates behavior, filters candidates, decides WHO should act. An **address** (the prepub) is an
  *identity*: it decides WHICH socket a frame lands on. The relay binds **one socket per addr** — `become
   runner` is a single slot, not a subscription — so a role is only a safe *delivery* target while it is
    structurally singular (the one editor on its relay). The moment a second runner binds the role locally,
     every role-addressed frame silently lands on it and the other runner starves. **Observed 2026-07-05**
      (the live specimen, socklog-proven): a bridge runner wedged at `begun` — its every `wormhole_req`
       served by the editor, all 286 `wormhole_reply`s eaten `(local)` by a role-thief tab; its pongs stolen
        too, so its watchdog read DEAD and flapped the socket every ~35s. The corr-*broadcast* design here
         assumed role frames fan out to all runner sockets — the relay never honoured that.
 The rule, post-fix: **every editor→runner frame is addressed to a prepub** (the `become_book` pattern —
  pick by role from the roster, deliver by address); the role slot survives only as the identity-less
   fallback. Concretely:
- **wormhole replies (JSON + binary)** — addressed to the **asker**, read off the corr it minted
   (`corr = ${Lies_self.prepub}-${ts}-${n}`, RemoteWormholeNav): the LIVE hello-bound identity of the tab
    asking now, bridge-routable, immune to an Id switch since grant-mint. Fallback `prepubOf(grant.for)`,
     then broadcast (an identity-less `r-…` corr on a lone-runner grid). JSON and binary now route
      identically — the old corr-broadcast-vs-corr-route split is retired.
- **pong** — echoed to the pinger's `from` prepub (editor-side). A stolen pong froze the victim's RTT slot
   and tripped its 20s DEAD watchdog: the flap was self-inflicted starvation, not a bad socket.
- **grant_offer** — addressed to the grantee (it's the roster key we granted by).
- **ghost_compile** — fanned out addressed to EVERY roster runner (a recompile is for all of them; the one
   role slot delivered it to one, leaving the rest on stale gen). Broadcast only with an empty roster.
 Runner→editor traffic (`advertise`/`ping`/`run_phase`/`wormhole_req`) stays role-addressed: one editor per
  relay, structurally singular — the case role delivery is FOR.

**Open — two tabs on the SAME `%Identity`.** Reusing one `?I=<tag>` in two tabs mints two peers on the same
 prepub → they collide on the relay bind (last hello wins; the other goes dark). Intended resolution: detect
  the sibling **via Dexie `liveQuery`** (both tabs share the IndexedDB) and have the loser take an address
   like `${prepub}_2` — a per-tab suffix on the shared identity, so both are reachable without forking a whole
    new key. `Swarm.g` already mints `${pub}_N` blocks for the swarm case; the same suffix scheme applies
     here. Unbuilt; the `_N` same-key-vs-ephemeral question is shared with the Radiobuddies discovery work.

Load-bearing: `LiesLies.svelte` (`Lies_self`, `Lies_channel_up` hello, `Lies_advertise`/`_recv`,
 `Lies_runner_roster`), `LiesFunk.svelte` (`Lies_grant_wormhole`, `Lies_grant_offer_recv`,
  `Lies_wormhole_req_recv`), `Auto.svelte` (boot adopt), `Funk/Grant.ts` (`mint_grant` already took the full
   pub — the bug was the caller), `p2p/cluster_trust.ts` (`prepubOf`).

### 3.2b The connection substrate — how the channel stands up and stays honest
*(Folded from the retired `Runner_network.md`; the diagnostic ladder that reads these layers lives in §3.3.)*

**The boot→channel layer map, bottom-up.** Four layers stack a live runner onto the relay:
1. **`/relay`** (`server/relay.ts`) — the node forwarder. Routes by `header.to`; `become <role>` sets a role
    slot once; a signed `hello` binds `prepubOf(pub)`→socket (§3.2); an r2r bridge cross-links two relays;
     executes verified `gen_write`. Frames are `[header JSON]\n[raw buffer]`, header cleartext so it can route.
2. **`Socket_real`** (`Tribunal.g`) — the client. Dials `ws?addr=role`, backoff-reconnects, buffers real
    frames and drops ephemerals (ping·pong·ack·run_phase); `on_open` re-fires every reconnect (so become+hello
     are re-sent each time).
3. **`Lies_channel_up`** (`LiesLies.svelte`) — the consumer. Installs the **per-role frame-handler table**
    (runner handlers / editor handlers / both) and stamps `channel_up`; an off-think keepalive rides here.
4. **top** — advertise → the `%Runner` roster; engage `to:<prepub>`; `wormhole_req`/`reply` carrying a signed
    `%Grant`. The per-role handler roster (which frame types each role answers) is the unique shape to preserve.

**Standup sits ABOVE the disk loop** (2026-07-03 invariant): `Lies_channel_up` runs from the TOP of
 `LiesPersist`, above the Waft `%Good` loop — *connection first; disk settles through it*. This ordering fixed
  a channel-after-disk deadlock; keep the invariant even though the reorder itself is long done.

**The four standup guards, in order** (the walk the ladder in §3.3 references): role ≠ editor|runner → skip;
 `channel_up` already stamped → skip (idempotent); `Socket_real` not a function → **ring the Relay Brink**
  (guard 3, the "never-deposited/cross-wired gen" tell); no `WebSocket` global → skip. Each open re-sends
   `control:become` then a signed `control:hello`, re-reading `Lies_cluster_idento` **live** so an Id switch
    rebinds without a reload.

**The LIVE-vs-FROZEN asymmetry — the cross-wired-gen tell.** A runner rides **live** `gen/N/*.go`; the editor
 rides the **frozen** `p2p/pinned_stable/*.go`. So a broken `gen/N/Tribunal.go` breaks EVERY runner while the
  editor stays green — *editor-green-while-all-runners-down IS the tell* (diagnosis ladder, §3.3). It also means
   the editor-receives direction (e.g. the reconnect-epoch cure) can't be isolate-tested from a runner.

**Announce cadence.** Ping ~5s (liveness only, never carries facets); advertise ~15s (`ready|book|engaged|ac`
 facets, re-beacons early on a facet change via a `sig` compare). On socket open, fire an immediate ping +
  advertise directly (NOT via the keepalive, whose DEAD-check would trip on a stale `last_heard`). `Lies_ac_nudge`
   (Sound Brink) makes an AudioContext unlock advertise instantly.

**Latched flags must reconcile, never assert-once (Robustness Organ 1).** A fact stored as a set-once boolean
 keeps asserting a dead truth after the thing it described tears down. The canonical specimen: `channel_up` /
  `transport_up` — set once, and an HMR strip of `Socket_real` left the latch saying "up" while standup never
   re-ran (*the "relay down" wedge*). *Cure & landed:* derive-or-reconcile against the live transport each
    heartbeat — `Lies_channel_up`/`_transport_up` now CLEAR the latch and re-stand-up when `Socket_real`
     **vanished** (a merely-disconnected ws does not flap it). The correct template to copy elsewhere:
      `Auto.svelte`'s `identity_up`, which latches **only on success** and retries until it works; and
       `wormhole_state`, derived downstream of the crypto verdict every heartbeat (§3.8). *Still-open backlog*
        (same set-once disease, lower stakes): `Runner.sc.granted_wormhole`, `H.c.creduler_up`,
         `run.c.toc_loaded`, the snapped `sub.sc.subscribed`, and the Cyto/Thangs/Keep `*_done` UI latches —
          each wants a clear-on-teardown or derive-every-tick.

**Reconnect-epoch seq collision (OWED).** A reloaded runner restarts its per-Pier inseq counter LOW;
 if the far side's window has already moved past those values, every message from the reloaded peer
  lands as dup-dropped for ~20s. *Interim fix (SHIPPED):* `Reliable.g`'s retry-climb eventually
   escapes the dup window. *Clean fix (OWED):* a reconnect epoch-reset — the peer announces a fresh
    epoch tag on connect so the far side resets its window immediately (no climb delay, no silent mute).
     See `reconnect-epoch-seq-collision` memory.

### 3.3 The `Lies%runner` UI + the `runner_ask` CLI — badges, the rack, the diagnostic ladder
*(Folded from `Runner_network.md` (badges + ladder + CLI proof) and `Cluster_runner_handover.md` (the rack).)*

The runner tab needs a face to declare and manage what it is: pick/fork its `?I=` Idento, show role
 (editor|runner) + lease/claim status + liveness (LIVE/SLUGGISH/DEAD), offer "become runner" / "fork
  a new Id" / "spawn N runner links". A **`Lens:Runner`/Brink** tenant (the Lens:Runner face exists,
   unverified — see the Lens handover); claim status reads the `%Claim` particle the spine mints. The prepub
    **is** the name — Rundar shows it CSS-truncated ~6ch (`.rp-pub`, full pub on hover); the old `%friendly`
     alias was **killed** (any `friendly` left in Dexie/`toc.snap` is dead data that ages out).

**The editor's RUNNER rack** is ONE server-rack lens over the whole `%Runner` roster — a row per pub with its
 job-state — not a single `→RUNNER (live)` pair line. Job-board face states: `sc.sent`/`sent_at` set on dispatch
  = ☎ **calling**; cleared to ▶ **playing** when the runner advertises a `book`; else **dialing** / **free** /
   **engaged** / **silent**. This rides the directory/presence split: **`%HostedIdentity,<prepub>`** = durable
    directory (persists role/`favourite_client`, keyed by real prepub) vs **`%Runner,<prepub>`** = live presence
     (dontSnap, rebuilt from beacons — `last_heard`/ready/book/engaged, never persisted). `self` is DERIVED and
      viewer-relative: the registry is ONE shared file, so a reader computes `entry === Lies_self(w).prepub`
       (a stale persisted `self` is scrubbed).

**Brink badges — two axes that must never merge.**
- **channel** (`Lies_channel_live` = `channel_up` ∧ transport-connected, OUR socket only): "→EDITOR (no
   channel)" = relay-down for us.
- **remote-Wormhole** carries TWO independent axes: the **crypto** axis `grant_status` (absent | invalid |
   valid, via `Lies_wormhole_verdict` — ed25519 `verify_grant` + `browserTrustedPubs` issuer + `for` == this
    runner; **invalid = loud red, discard + re-beg**; `'ready'` is *derived*, never latched) and the **liveness**
     axis `channel_live` ("grant valid · editor not answering"). A valid-but-unanswered grant and an
      invalid-grant are different failures and get different badges. Durable-home rule: the grant's sole
       authority is the top-House `.stashed` (survives reload); the old `Waft:Cluster` grant copy was REMOVED
        (an empty-registry read could wipe it) — a wiped grant self-heals re-beg→re-grant.

**The `runner_ask` CLI — how you prove and drive a runner over the relay.** `scripts/runner_ask.mjs`
 (interactive twin `scripts/story_repl.mjs`) rides the same `/relay` the editor uses: it registers on
  `on('runner_ask')`, and the relay corr-routes `runner_ask`→runner and the `{control:'runner_ack',corr}`
   reply→CLI **by corr** (no address needed — a lone-Pier short-circuit + reliable-carrier no-inseq path lets an
    address-less CLI reach the one runner). Read ops: `ping` (one green round-trip proves relay-up + ws-bound +
     consumer-dispatch-alive; reports `{role,channel,self,advertising,clustation_self}`), `state`, `steps`,
      `snap <n>`, `rungos`, `runners` (lists the registry off `toc.snap`), plus `retain`/`trace`/`diff`;
       `--runner=<pub|prefix>` addresses ONE and **insists** (retry, never failover — the deliberate inverse of
        the editor's allocator, for repeatable targeted testing). `run <Book>` mints a fresh `uid`.

**The diagnostic ladder** (when a runner won't behave). *The editor staying green while every runner is down is
 itself the tell — suspect cross-wired gen first.*
- **Mode 1 — cross-wired gen** (the top suspect). "Creduler ready — N ghost(s) live" proves only that each
   Ghostmeta answers a dige, NOT that the right methods were deposited. Ladder: Network tab shows zero `/relay`
    dial attempts → walk the four standup guards (§3.2b); `grep -c Socket_real …/gen/N/Tribunal.go` ≥3 = healthy,
     1 = cross-wired; run the duplicate-dige sweep; headless-recompile via the `LocalGen.spec.ts` vitest command
      (self-heals through HMR re-mix, no reload). Upstream cause still OPEN: the compile-source-as-param seam that
       can write one dock's output to another's `gen_path`.
- **Mode 3 — error-lands-as-empty** (OPEN; the Organ 3 shape at the wormhole seam — principle §2.0a). `land_good` mapping
   `{error}`→`content:''` makes a failed read indistinguishable from a genuinely empty one → "Waft:Cluster empty"
    silently resets a registry. Ought to park-and-retry (leave `c.content` undefined). `Wormhole_park` serialises
     one op in-flight per queue, so a degraded down-channel crawls at ~20s/op.
- **Mode 4 — begun-wedge.** `become_book` accepted but `phase:begun` forever for EVERY Book = a tab-level fault
   (stuck `%Creduler_pending` / a dead Auto elvis), not a per-Book one; differential-test with a known-green Book
    (MusuSkip). `runner_ask` has no reload op — a wedged tab needs a human reload.
- **Mode 5 — watchdog states.** `Lies_keepalive` reads LIVE / SLUGGISH / DEAD; **only DEAD re-dials**;
   SLUGGISH (heard-but-no-pong) must NOT tear the socket.

**Open CLI ops** (the drive/examine/accept surface — protocol in §5): `op:'hold',at:<n>` / `op:'release'` (pause
 at a step mid-drive, needs a `req:Step`); on-demand snap at any tick; `op:'accept'` (the one *write* op, signed
  under the cluster Idento, relay-opaque + runner-verifies — the live analog of `CredRunner ACCEPT=1`);
   `forget <uid>`; and re-registering `on('runner_ask')` outside the `channel_up` once-guard so HMR can hot-swap
    a new handler.

### 3.4 The restart/resume service (the docker successor to `ty/`)
The hard problem (`ty/README.md`): Chrome app-servers hold **File System Access Directory Handles**
 granted by a human clicking "Allow"; they live in browser memory, so **any Chrome restart destroys
  them**. `ty/`'s answer ran the whole Xvfb+Chrome stack in a **KVM VM** and **reverted to a healthy
   snapshot** (`snap3`, taken once handles were granted): handles survive in frozen VM memory, the
    dirs are **virtiofs** mounts from the host. Two services: `watchdog.js` (puppeteer-core CDP probe
     per profile; crashed *tab* → close+reopen; Chrome unreachable → `RESTART:<profile>` to a Unix
      socket) and `virtreset.py` (on `RESTART` does `virsh snapshot-revert … snap3`; also reverts on
       balloon-memory OOM). A **docker** variant existed but "keeps losing handles."

**The New Stuff (this doc's testbed, heading 4):** *little dockers full of Chrome*, for tests that
 don't need a human-granted handle (the swarm sim peers carry their own fixtures, not an OPFS mount),
  so the handle-survival problem mostly **dissolves** — a crashed container just gets a fresh one. The
   inner→host channel stays a plain message (`RESTART:<name>`) on `ty/`'s Unix socket
    (`chrome_launcher.sock`, `ty/launcher.py`) — the **host-exec socket** (3.7), extended with more
     allowlisted commands as needed. A runner that needs the *real* repository (not just sim fixtures)
      replaces the handle with the **network Wormhole backend** (3.8), not nothing.

### 3.5 Claim / lease — the one primitive in three hats
Runner-affinity ("the editor owns this runner"), the distributed mutex ("whoever does mutexes"), and
 the restart-token are the **same primitive**: a **signed, relay-arbitrated `claim`/`lease`** over an
  Idento addr — a leased `%Claim,name,by,until` token, verified in the recv window, first-come at the
   relay. Made trustworthy by the cluster signing layer (heading 2). Build it once.

**But weigh it against app-level.** With the runner pool self-assembling (3.0) and capability gated by
 certs (2.8), "the editor owns this runner" may just be an app-level lease the two peers agree over the
  spine — no relay arbitration, no new privileged frame. Reserve relay first-come for a *genuinely
   contended mutex*; let plain affinity and pool-membership live app-level (open: 8).

### 3.6 The crash-quorum → who asks for the restart
The human wants a **quorum** ("restart when most of ~7 tabs have crashed"), not per-tab. The **relay
 is the natural counter** — it sees every socket and the app computes LIVE/SLUGGISH/DEAD; the relay
  tallies DEAD across the fleet and, past the quorum, emits a `restart_request` control frame bridged
   to the supervisor. The `ty/` "stable filehandle Pier" vision (one near-immortal tab holds the
    handles and shunts work to disposable worker tabs over WebRTC) is exactly the **handle-holder +
     disposable-worker** split: the holder is one Idento, the workers another.

### 3.7 Host-exec — the `chrome_launcher.sock` lineage (no certs)
When the app needs to act on the **host** — restart a crashed Chrome profile, bounce the docker service
 or the ssh reverse proxy — it can't do that from a browser tab. The mechanism already exists in `ty/`:
  a tiny **host daemon** on a **Unix socket** (`/tmp/jamsend-supervisor/chrome_launcher.sock`,
   `ty/launcher.py`, kept up by `ty/jamsend-launcher.service`) that accepts a plain text command
    (`RESTART:<profile>`) and runs **one of a fixed set of actions** — nothing else. `ty/virtreset.py`
     is the sibling that does `virsh snapshot-revert`. The allowlist *is* the whole privileged surface:
      the caller picks a **name**, never sends a command.

**The trust boundary is the socket, not a cert.** The socket is host-local (chmod 666 so the docker
 bridge can write it); reaching it means you are already on the host or in a bridged container the human
  set up. The in-app path: the app emits a `restart_request` (3.6) down its relay, and a small host-side
   bridge writes the line to the socket. Because every privileged relay frame is **signed and verified
    against the trusted flock** (2.3), *who may ask for a restart* is already answered — a trusted pub
     may; no `can:restart` cert, no tyrant, no per-action capability (2.8).

**To build (a `chrome_launcher.sock` successor):** extend the socket's command vocabulary beyond
 `RESTART:<profile>` to the other host actions wanted (`restart-docker <svc>`, `restart-proxy`), each an
  allowlisted name; add the relay→socket bridge so a quorum `restart_request` (3.6) lands as a socket
   line. **The bootstrap wrinkle:** one action may restart the ssh reverse proxy the relay rides, so the
    bridge/socket must be reachable on a path that survives that proxy being down (a direct port or a
     second ssh) — keep the recovery channel independent of the thing it recovers.

### 3.8 `w:Wormhole` backing — FSA handle for editors, a file server for runners
`w:Wormhole` is the world whose `/` is the **repository filesystem** (the `wormhole/**` tree —
 `toc.snap`s, Keep data, gen `.go`, fixtures). Today its IO rides the browser **File System Access API
  directory handle** (the `open_dir` action behind `H.c.disk_gated` / the FaceSucker share gate). That
   handle is the **fragile** thing (3.4): it lives in browser memory, **dies on every Chrome restart**,
    and **needs a human to re-grant** — fine where a human sits (the editor), fatal for a daemonised runner.

**The split to build (robustly, and tested):** abstract Wormhole's filesystem IO behind two backends,
 chosen by role:
- **FSA backend** — the directory handle, **banished to user-facing Chromes only** (where `Lies%editor`
   runs and a human can click *Allow*). Interactive, fragile, human-present.
- **Network backend** — a **repository-IO service on the remote host** (an "ftp server" loosely — but a
   browser can't open a raw FTP socket, so in practice WebDAV / SFTP-behind-a-proxy / a bespoke ws|http
    file service: the `gen_write`/`ghost_update` disk-write precedent generalised to *full* repo IO). The
     daemonised runner uses this: **no in-browser handle, survives restart, no human**. This is the
      robust path the flock needs.

**All runners open the repo at Wormhole's `/`** — one shared root — so the filesystem no longer
 distinguishes one runner from another (in a local-disk world the *opened directory* was itself the
  signal). **Identity must come from `?I=`** (the tab-fork tag, 3.1) or some in-browser trace awareness,
   *not* from "which folder did I open." A runner is *who its `?I=` says*, reading a `/` it shares with
    its siblings.

**Open — the writer problem:** if many runners share one `/`, do they **write** to it (clobber risk →
 per-`?I=` namespacing + coordination) or are they mostly **readers** (load Book/ghosts/fixtures) whose
  run-output goes back over the verdict wire + `Storyrun` pins, never to the shared tree? Leaning
   reader-mostly; settle before building (8).

**The access grant — beg through the Brink.** The network backend is **not open**: a runner
 holding no FSA handle (headless; OPFS illegal under the `?I=` boot) must be **granted** Wormhole
  access, never just take it. The protocol: the runner emits a signed **`WormholeBeg`**
   `to:<editor.pub>` ("runner `<pub>`/`<tag>` requests Wormhole — read | read+write"); it surfaces
    at the editor's **Brink** as a pending grant (a Lens/Brink tenant beside Runner/Upkeep —
     *"alpha-2 begs Wormhole · [grant ro] [grant rw] [deny]"*), where a human decides, or an
      auto-policy waves through a known `favourite_client`. Approval mints a **leased, signed
       capability** — the §3.5 `claim`/`lease` primitive in a fourth hat (Wormhole-access, not
        ownership/mutex/restart): `%Grant,for:<runner.pub>,scope:Wormhole,mode,until`. This is the
         **`disk_gated`/FaceSucker share gate generalised**: today the human grants the *local* tab
          disk; now the human grants a *remote* runner repo IO, from the Brink. Enforcement lives at
           the Wormhole **service**, not advice: it serves repo-IO frames from `<runner.pub>` only
            while a live grant exists, and the grant is revocable + expiring.

**Who serves it — first cut: the editor proxies its own handle.** The editor is already the disk
 authority (it holds the FSA handle and does `gen_write`/`ghost_update` to disk on behalf of
  compiles). The cheap first backend reuses that: granted runners read the repo *through the editor*
   over the relay — the `gen_write` precedent generalised to full, grant-gated repo IO, no new host
    service, and it matches "beg **from the editor**." The standalone host file service (3.8 network
     backend) is the **editor-less robustness upgrade** — for a daemonised flock with no editor
      present to proxy or to click *grant*.

**The editor's backing can be OPFS — robust shared session storage.** The fragility (handles dying on
 restart, §3.4) only ever had to be solved *once*, at the **one editor where a human is**, not on N
  headless runners. And the editor needn't even use the fragile directory handle: **OPFS works *from the
   editor*** (origin-persistent, survives restart, `navigator.storage.persist()` pins it) as a durable
    store — `method:opfs` — while `method:fsa` is reserved for when a runner genuinely needs the *real
     repo files* on host disk. Every granted runner proxies the **one** editor store, so they share a
      single `/` for free — and because the editor is then the **sole mutator**, it serialises the
       runners' writes into its backing, so the multi-writer clobber problem (the §3.8 open decision)
        **dissolves**: shared read+write becomes viable, not just read-only.

**The proxy streams binary, all the way.** Repo and scratch data is binary and large (audio, images,
 gen `.go`, fixtures), so the `remoteWormhole` channel is a **chunked binary stream** — reusing the same
  stream machinery that carries audio (the Peeroleum `offer_stream` path), never a base64-in-JSON RPC. A
   read streams chunks editor→runner, a write streams runner→editor, backpressure-aware; nothing buffers
    a whole file as text. So the Wormhole IO API is **stream-shaped on both backends** (an FSA
     `FileSystemFileHandle` and an OPFS handle both yield streams), and `method:remoteWormhole` is just
      that stream piped over the relay — the editor's chosen backing invisible beneath it.

**BUILT (2026-07-01, :9091-UNVERIFIED).** The beg→grant→serve spine is in, type-clean, at the new end:
 - **`%Grant` crypto atom** — `src/lib/O/Funk/Grant.ts`. A self-contained, signed capability (`to,by,for,
    time,sign` + opt `mode`), modelled on Peerily's `grant_trust`/`verify_trust`/`say_trust` (Peerily is
     out of bounds — REPLICATED, not reached into) but carrying its own grantor/grantee so it verifies off
      any connection. **No `until`** — grants are infinite by design (click-to-renew trains rubber-stamping +
       adds operator noise); revocation is a signed `%NotGrant` (`mint_revoke`, seed only). The **swap-out**
        is `grant_to_C`/`grant_of_C` (atom ⇄ a `%Grant` particle you leave around in `Waft:Cluster`).
 - **`method:remoteWormhole` backend** — `src/lib/O/RemoteWormholeNav.svelte.ts`. The third nav behind the
    same `read_file/write_file/dir/bin_read/read_range` contract, round-tripping rw-ops to the editor.
 - **Partial/range reads** — `read_range(dir,file,offset,len)` on both local navs (OPFS + FSA, via
    `file.slice`) and the rw_op dispatch; only the requested WINDOW of a 1.4GB asset ever crosses.
 - **The four verbs** (additive Peeroleum frames, no `.g` spine change) in LiesFunk + registered in LiesLies:
    `wormhole_beg`→roster flag, `grant_offer` (editor mints from the **Rundar rack** per-runner *grant 🛰️*
     button), `wormhole_req`→editor verifies (`by===self`) + serves from its own nav, `wormhole_reply`. The
      runner's **Rundar** RUNNER indicator shows the acquire status. `&remoteWormhole=1` (Otro; was `&disk=proxy`) swaps the
       FaceSucker for `req`-less acquire (Lies_aim drives beg→install; DirectoryOpener only reflects A.c.nav;
        ungranted ⇒ "nav not ready" ⇒ Lies waits — the intended gum-up).
 - **Bootstrap** — the held grant's durable home is the runner's local `.stashed` (per Chrome profile,
    survives a docker restart, readable with NO nav); `Waft:Cluster` keeps the registry copy. This breaks
     the circular dep (Waft:Cluster itself loads *through* the Wormhole the grant unlocks).

**SPINE PROMOTED + BINARY (2026-07-01).** The editor's pinned spine was promoted (`cp gen/N/{Peeroleum,
 Tribunal}.go → p2p/pinned_stable/`, backup `/tmp/pin_*_jun23.go.bak`) — it now has `Peeroleum_send_to`
  (per-pub addressing), `offer_stream`, multicast, retx/liveness sweeps. So **base64 is GONE**: a `bin`/
   `read_range` reply now rides an **addressed binary frame** — `Lies_send_binary_to(w, claim.for, …)` puts
    bytes on `frame.buffer` (the `[header]\n[raw buffer]` wire, body_hash-integrity, near-zero-copy), corr +
     size in the header; `RemoteWormholeNav.frame_bytes` unpacks it (b64 only the no-grantee degenerate).
      `wormhole_reply` is **addressed** (not broadcast). **The routing is now derived, not frozen** (the
       2026-07-05/06 address+role fix, §3.2a): the reply goes to the corr's **asker** prepub
        (`corr = ${Lies_self.prepub}-${ts}-${n}`, the live hello-bound tab asking now), fallback
         `prepubOf(grant.for)`, then broadcast only for a lone-runner grid — so the old `claim.for`-diverged-
          from-hello-bind caveat is retired. JSON and binary replies route identically.

**The full nav contract is a hard invariant (Robustness Organ 5 — errors name the real cause, no partial
 interfaces).** A backend either implements the **whole 7-method contract** — `read_file · write_file ·
  bin_read · bin_write · read_range · dir · dir_at` — or is explicitly **capability-probed at the seam** (the
   seam says *which capability is missing*, never a misleading "no writable share — grant one" three layers
    away from the real cause). Landed: all four navs (FSA / remote / OPFS-overlay / node) now carry the full
     contract; `RemoteWormholeNav.bin_write` writes binary over the proxy (a headless `&remoteWormhole=1`
      runner with no local share can write to the editor's disk); nav-precedence prefers a granted **local**
       share (`A.c.DL`) over the editor proxy, and the badge shows an honest `local` state.

**Deltas / owed.** (a) `grant_offer` is now **addressed `to:<grantee.pub>`** (was role-broadcast); the
  `%HostedIdentity`/`%Runner` row stores the full `pub` and grants `for = full pub` (§3.2a). (b) Whole-file
   reads still frame their window; **`offer_stream`** (now available) is the upgrade for large sequential/
    seekable streaming + migrating the audio decoder to `read_range`. (c) The editor serve calls its nav
     **directly**, bypassing the rw_queue, so a remote **write** can race the editor's own (reads are safe) —
      funnel writes through the queue, or grant `ro`. (d) Revocation-corpus check at serve is a TODO. (f)
       **PereBinary** (a Book diging a binary round-trip over the relay carrier) is the owed positive-path
        proof — the harness exercises binary send + bad-hash reject but never diges received content. NB the
         **relay-level** binary round-trip (buffer-intact, same-origin + over the r2r bridge) is proven HEADLESS
          in `scripts/relay-test.ts`; PereBinary's remaining gap is the **app-level** path — `Lies_send_binary_to`
           → `RemoteWormholeNav.frame_bytes` unpack → dige the received content — which needs a live runner.
            Verify live on the docker flock + an editor on :9091.

### 3.9 The runner machine — dispatch quality and liveness
*(Folded from `Runner_quality_handover.md` and the liveness architecture in `Cluster_runner_handover.md`.)*

**Belief-queue coalescing — the perf lesson.** A 117-todo death-spiral traced to per-frame belief churn. The
 fix is three-way: the relay's `control:log` goes only to editor-bound sockets (not every tab); `Tribunal.g`
  `on_message` routes control-frames inline vs enveloping binary through `Lies_deliver_soon`; and
   `Lies_deliver_soon` **per-`w` batch-coalesces** N frames into a single `post_do` drain via
    `Peeroleum_deliver` (Atime preserved; the design choice is coalesce-in-post_do, not reqyoncile-per-frame).
     The first two ride the **pinned spine** (recompile + re-pin `pinned_stable/Tribunal.go`).

**Click-preempt dispatch.** A single interactive click **preempts** — `Lies_preempt_target` sends a fresh
 `become_book` to the sticky `aim_runner`/`rungo_runner` and `Story_reset` cancels the prior run — instead of
  queueing behind it. StoryTimes keeps the hold/parallel-acquire path for non-interactive fan-out.

**needAC (audio) dispatch-match.** A beacon carries `ac:1` when its AudioContext is gesture-unlocked (probing
 `top_House().c.musu_gat`); the roster folds an `%Runner,ac` facet (Rundar "AC live"); `Lies_dispatch_target(w,
  needAC)` **prefers** an ac-live runner above every favour tier — *prefer, never require*. `runner_ask run`
   reads Credence (`bookNeedsAC`) and passes `needAC`, failing fast (~60s, not a 120s hang) rather than smearing
    a no-AC runner red. The load-bearing rule for the verdict: a run that ends `!ok` with nothing tried and an
     error must read **"couldn't run here"** (⌛/grey), NEVER "audio delivery broken" — a no-AC runner must not
      paint a needAC Book red. `Lies_secure_audio` opens the run record only AFTER AC is granted, so *"the run
       record appeared"* IS the grant signal the CLI leans on.

**needsFSA dispatch-match (twin of needAC, OWED).** A Book requiring local disk access carries a
 `needsFSA` cap flag in Credence (the twin of `bookNeedsAC`); the dispatch-gate should route it
  **only to LOCAL-FSA runners** and **refuse** a `method:remoteWormhole` runner outright — not smear
   it red, just "needs local share, try another". `MusuGenerateTestsMusic` is the canonical case
    (generates large binary fixtures to disk, blocked on a headless proxy runner). The Credence cap
     and dispatch-routing mirror the needAC pattern; both the cap read in dispatch and the `runner_ask`
      fail-fast path are OWED. See `needsFSA-dispatch-gate` memory.

**The liveness architecture still owed** (the address+role work fixed routing but kept the beacon as the
 heartbeat): promote **per-runner ping/pong** to the liveness *source* (stamp `%Runner.last_heard`/rtt from
  pong) and **demote `advertise`** to a pure directory+job-state announce; attribute `from:<pub>` on
   `run_phase`/`run_result` so the editor can **demux** which tab needs AC (today `w.c.run_phase` is a single
    slot → the Brink says "*a* runner needs AC", not which); and carry a per-Pier inseq-reload baseline across
     all N Piers. Plus the **activation ladder** (talking <15s ▸ lagging <45s ▸ silent ▸ offline, replacing the
      flat 45s window) and a **Pier-culling reaper** that reaps a dead `%Runner` presence + its transport/Pier
       (silent > 5min, `promoted_at` guarding a mid-ring probe) while KEEPING the durable `%HostedIdentity`.
        These want ONE shared `Lies_liveness(w)` verdict feeding rack + reaper + `runner_ask` (SLUGGISH ~9s,
         DEAD ~20s, roster LIVE ~45s, Pier cull ~5min), resetting the death-clock on any `run_phase`/`Storyrun`
          progress — which also kills the `--watch` 8s false-RED bug (it bailed below SLUGGISH). Net fatal =
           20s of no-answer AND no progress. (Tab sleepiness is the twin problem: a muted keepalive
            AudioContext + Page-Lifecycle resume→re-ping / freeze→"going cold" advertise; installed-PWA for a
             real fleet — see the warmth memory.)

**The dispatch allocator** (§3.5 lease in its dispatch hat): `Lies_dispatch_target` picks the latest trusted
 not-busy runner by tier (mine ▸ unclaimed ▸ another's favourite; a freshly-`sent` ☎ counts as busy) and
  returns `{to}` | `{}` | `{exhausted}` — where **exhausted = HOLD, never steal** (no tailspin), backstopped by
   `Lies_queue_run`/`Lies_drain_runs`. `favourite_client` READ (`Lies_favoured_runner`) is built; the SET path
    (editor blesses / runner self-claims into `%HostedIdentity,favourite_client`) is open.

**Rendering gap** (§8): `ui/Waft.svelte` renders only `ITEM_TYPES`, so unknown mainkeys
 (`HostedIdentity`/`Cursor`/`WaftTimes`) render **nothing** (no `{:else}` in `waftitem`) — which is why
  Cluster/Keep show no `/*`. Needs a generic fallback row.

---

## 4. The real-isolation testbed — dockerised Chrome

The leap. Each peer is a **container running a real Chrome running the app**, booted with
 `?B=&?I=<tag>` → a genuine WebRTC peer with real serialization, real connection setup, real loss.
  This is what the in-process Story can't be (heading 0).

**The daemonised entrypoint** (per container):
1. Boot Xvfb + Chrome (or headless-shell) → the app at the dev/staging URL with `?B=&?I=<tag>`.
2. The app **auto-acquires the spine** via Creduler (`CREDULER_GHOSTS`, gated by `%Creduler_pending`)
   — no hand-loader; the gen `.go` must already exist on disk (ghost-compiled), read over the **network
    Wormhole backend** (3.8) — no FSA handle in a headless container.
3. **Bind** its tag-Idento to the relay (signed hello → relay records pub→socket, the modern
    `OverPiering`).
4. Announce presence, show liveness, and **idle awaiting `%Rungo`** — a daemonised `Lies%runner`.

A flock = N such containers (or N `?I=` tabs in one container's Chrome). They are the swarm.

---

## 5. Distributed Story — parts in unison

The orchestration layer: a Story whose **parts run on different runners simultaneously**, coordinating
 over the **real relay**. Where PereProof drives all peers inside one in-process `w`, a distributed
  Story assigns each peer's part to a real container, drives them in unison, and aggregates the
   per-runner snaps back to the conductor. The existing pieces it leans on:
- **`become_book`** — hand a runner a Book to run (already a remote-ish handoff).
- **`Storyrun:<ident>`** + `run_phase` — the durable run record + phase stream (begun→stepping→done).
- **the Editron verdict wire** — verdicts + snap pins thread back to the editor.
- **`Run_A_<Book>` dispatch** — the per-Book recipe each runner executes for its part.

The conductor addresses each part `to:<runner.pub>` (3.2), collects verdicts, and diffs the aggregate
 — the same accept/diff gate CredRunner uses headless, now spanning a real fleet.

**Provisioning is part of the base Book.** A multi-runner Story cannot assume its cast exists, so its
 base Book opens with a **provisioning phase**: request/await the remote runners from the pool (3.0) and
  **gate on the whole cast checking in online** — every part's runner reports ready, or the run **fails
   fast as a provisioning failure** (cloud host never came up, container crashed on boot, cert rejected).
    Only once the muster passes does the Story proper begin. Then each remote runs its assigned
     **sub-book** — its slice of the cast — while the conductor drives them in unison, and you can
      **interrogate any one remote via the CLI** (`scripts/Story_cli_runner.svelte` headless, or the
       live Lens:Runner face) to read its local snap. A distributed Story is thus: *provision
        (muster-or-fail) → run sub-books in unison → aggregate + interrogate.*

**Drive → examine → accept, over the relay** *(folded from `Runner_talk_TODO.md`)*. The point is to
 interrogate and steer a live runner from a CLI with **no human at :9091** — the same addressless round-trip
  `ghost_compile`/`gen_write` use. A run holds as a durable record: `Storyrun:<ident>,uid` (uid = 8-hex),
   whose per-Step pins ride `sr.c.pins` — a Record keyed by `n` of `{n,ok,caveat,dige,got_snap,exp_snap,
    trace}`, **off-snap and refs-not-copies** (bounded to the last ~3, GC'd, `active_rungo` names the live one).
     `Lies_runner_begin`/`_verdict` + `Lies_rungo_record`/`_steps` + `Lies_runner_this` are the readers;
      `exp_snap` fills from `Step.sc.exp_snap ?? w:Story.c.exp_snaps[n]`. The examine ops (`snaps`/`retain`/
       `trace`/temporal `diff <n> prev|<m>`) are built (see §3.3's `runner_ask` surface).

Still open on this surface: **breakpoint** (`op:'hold',at:<n>` / `op:'release'` — pause *at* a step mid-drive,
 §4.2 fuzz classifier as the condition; needs a `req:Step`); on-demand snap at any tick (read a wedge mid-step);
  **`op:'accept'`** — the one *write* op, `book,step?`, **signed under the cluster Idento** (`cluster_trust.ts
   signHeader`), relay-opaque and runner-verified — the live-socket analog of headless `CredRunner ACCEPT=1`/
    Resnapture, gated on the accept/diff review; `forget <uid>`/`forget all`; and a truly diskless *runner*
     needs its `exp` snaps seeded into the `become_book` payload (no local disk to read fixtures from).

---

## 6. The coverage metric — "how much of the news got through"

The fitness function. Pump a known corpus of "news" (messages) into a swarm of M peers under a chosen
 **topology** and **real loss**, then measure **what each peer actually received/dispatched**:
- per-peer coverage = `received_set ∩ intended_set / intended_set`; aggregate = mean/min/p5 across peers;
- by message-class (clean / large / multicast), by hop-distance, by time-to-arrival;
- a regression/optimization number tracked **across reliability-code changes** — did this retx/backoff
   tweak raise the floor under loss?

This is the **real-transport generalization of `make_lossy_partner`**: there the drop/blackhole was
 injected at a function call; here the loss is genuine (NAT, datachannel backpressure, container
  network, crash-quorum churn). The mechanisms PereProof proved in miniature (inseq heal, retx-to-stall,
   fault-reject, identity routing) get their **real-world coverage number** instead of a synchronous
    pass/fail. **Audio variant:** same harness, measure stream continuity/gap/jitter/underrun instead
     of message coverage — the bridge to the audio-streaming platform endgame.

---

## 7. The MVP and the build order (to remote `%Rungo`)

What **EXISTS**: signed frames + relay (`claims`/`bind`/`deliverLocal`, r2r reconnect, multicast
 fan-out); the Peeroleum spine (inseq/retx/fault, sha256 body_hash, `to:@channel`); Creduler acquire;
  `become_book` + `Storyrun` + `run_phase` + the verdict wire; the trust substrate (heading 2.7); the
   Lens:Runner face (unverified); `ty/`'s restart pattern.

**BUILT (2026-06-29, headless-verified — see 3.2):** the relay's signed-`hello` AUTHENTICATED `to:<pub>`
 binding (relay-side, `relay.ts handleHello`, proven in `relay-test.ts`). *(A capability-cert layer +
  minting CLI + a cert-gated host daemon were also prototyped this day and then **removed** — the trusted
   flock is the authority, no certs; see 2.8 / 3.7.)*

What's still **MISSING**: the CLIENT half of `to:<pub>` (a peer emitting the signed hello on connect);
 `?I=<tag>` tab-fork + the
  `?Runner` role & self-assembling pool; the daemonised docker boot; allocation (app-level lease,
   *maybe* a relay-arbitrated mutex — 3.5); the **network `w:Wormhole` backend** (repo IO without the
    FSA handle — 3.8); crash-quorum `restart_request`; the distributed-Story conductor + the
     provisioning preamble + the coverage meter.

**The minimal path — remote `%Rungo` lands at step 3; everything after is the flock at scale:**

0. **Substrate (mostly done)** — keep warn-and-allow until a signed `gen_write` path exists, then set
    `CLUSTER_TRUSTED_PUBS` (the migration gotcha, 2.6). Close the one substrate hop (recv-window
     trust-accept) when convenient.
1. **`to:<pub>` addressing in the relay** — bind verified Idento→socket on signed hello;
    `deliverLocal` by pub. **Relay side DONE** (`relay.ts handleHello`, proven in `relay-test.ts`).
     Remaining: the client emits the signed hello on connect (`Tribunal.g` Socket_real) keyed by its
      `?I=` Idento — folds into step 2.
2. **`?I=<tag>` tab-fork + the `?Runner` role** — resolve cluster Idento keyed by `?I=`; two tabs/two
    identities both bind and address each other; a `?Runner[=name]` tab registers into the
     self-assembling pool (3.0) and idles available. *(The editor half — `Peeroleum_send_to` +
      roster→Pier promotion + per-Pier inseq baseline, and the engagement lease it carries — is
       detailed for the Lies/editor owner in [Engage_integration.md](Engage_integration.md).)*
3. **One daemonised runner in a docker** — image boots Chrome→app `?Runner=runnerA&?I=runnerA`,
    auto-acquires, binds, registers. Open the editor, see runnerA in the roster, hand it a Book via
     `become_book` addressed `to:runnerA`, get the verdict back. ("May it run this?" is just "is the
      sender a trusted pub?" — 2.8; no cert.) Prereq: its `w:Wormhole` on the **network backend** (3.8) —
       a headless container holds no FSA handle. **← remote `%Rungo`, minimal.**
4. **The flock + claim/lease + Lies%runner UI** — spawn N containers / N `?I=` links; editor claims
    one (lease); liveness + "spawn N links" + "become runner" in the Lens:Runner face.
5. **Crash-quorum restart** — relay tallies DEAD, emits `restart_request` (3.6) to the host-exec
    **`chrome_launcher.sock`** (3.7) via a relay→socket bridge.
6. **Distributed Story + coverage meter** — a Story across the flock (heading 5) whose base Book
    **provisions first** (muster-or-fail check-in) then runs sub-books in unison, with the delivery-
     coverage metric (heading 6). This doubles as the Tier-3 real-transport harness.
7. **Audio simulations** — the coverage harness retargeted at the audio code; toward the streaming
    platform.

"Go around and build whatever first" = this dependency order: 1→2→3 is the critical path to a single
 focused remote runner; 4→5 makes it a managed flock; 6→7 turns the flock into the measurement rig.

**Orthogonal, buildable now:** the **host-exec socket** (3.7) — extend `ty/`'s `chrome_launcher.sock`
 with the docker/proxy restart actions + a relay→socket bridge. Host infra that needs no app change,
  **stabilising the fragile staging topology everything else rides on**. (A cert-gated http daemon was
   prototyped here and removed — the socket *is* the trust boundary; 3.7 / 2.8.)

---

## 8. Open decisions
- **Container shape:** N `?I=` tabs in one Chrome per container (cheap, shared crash domain) vs one
   Chrome per container (true isolation, heavier). Likely a mix — workers share, the handle-holder is alone.
- **Loss realism for sims:** rely on genuine network loss, or also inject `tc`/netem at the container
   edge for repeatable adverse topologies? (A controlled knob makes coverage numbers comparable.)
- **Conductor location:** is the distributed-Story conductor an editor, a privileged node CLI, or its
   own role? (Affects who signs the `become_book`/part-assignment frames.)
- **`%Rungo` ownership semantics:** is a claim exclusive (one editor owns a runner) or shared with
   priority? How does a lease expire/transfer on editor disconnect?
- **The substrate recv-window hop** (2.7): when the spine accepts cluster-trusted pre-Ud frames,
   cli→editor and conductor→fresh-runner both unlock — sequence it before step 3 if cli is the conductor.
- **Allocation: app-level lease or relay mutex?** (3.5) Does affinity/ownership stay an app-level
   agreement, with the relay arbitrating only a genuinely contended mutex — or is the relay-arbitrated
    `%Claim` worth building uniformly? Leaning app-level per the "no new privileged frames" stance.
- **Host-exec recovery channel** (3.7): the `chrome_launcher.sock` bridge may need to restart the ssh
   reverse proxy the relay rides — so it must be reachable on a path that survives that proxy (a direct
    port, a second ssh, or a self-healing tunnel), never only behind the proxy it exists to restart.
- **`?Runner=<name>` vs `?I=<tag>`** (3.0/3.1): is the runner name the Idento tag itself, or a separate
   human-friendly pool label over a distinct key? Affects hop-over and re-registration under the same name.
- **Wormhole network-backend protocol** (3.8): WebDAV, SFTP-behind-a-proxy, or a bespoke ws|http file
   service reusing the gen_write/`ghost_update` precedent? The browser can't speak raw FTP — pick one
    the runner Chrome can actually reach.
- **The Wormhole writer problem** (3.8): do shared-`/` runners **write** (→ per-`?I=` namespacing +
   coordination) or stay **read-only** (output via the verdict wire + `Storyrun` pins)? **Largely
    dissolved** if all IO funnels through one editor store (3.8): the editor is the sole mutator and
     serialises the runners' writes, so shared read+write is viable — only app-level logical clobber
      (two runners writing the same path) still needs coordination.
- **Wormhole server: editor-proxy vs host service** (3.8): first cut = the editor proxies its FSA
   handle to granted runners (reuse, but needs an editor present); the standalone host file service is
    the editor-less upgrade. Build the grant + editor-proxy first, host service when the flock must run
     with nobody home.
- **Wormhole-grant = a fourth lease hat or its own frame?** (3.5/3.8): is `%Grant,scope:Wormhole` the
   same relay-arbitrated `%Claim`/lease as affinity/mutex/restart, or an app-level grant the two peers
    agree over the spine (the "no new privileged frames" stance)? Leaning app-level, Brink-surfaced.
