# Cluster_spec.md — the cluster: trust substrate, runner flock, real-isolation testbed

The cluster is the layer **above** the Peeroleum spine where identity, trust, membership, and
 *running things on other machines* live. This doc is its spec. It supersedes the old
  `ClusterTrust_handover.md` (a two-job handover that is now mostly DONE — folded in below as the
   **trust substrate**), and absorbs the runner-fleet ops notes.

Pair it with **`spec/Peeroleum_handover.md`** (the spine: frames, inseq, retx, fault, multicast).
 The shorthand is **Peeroleum + Trusting**: Peeroleum is the transport, *Trusting* is everything
  cluster — the reborn lineage of the old `MTrusting`/`Trusting`/`Gardening` garden (heading 1).

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

---

## 2. The trust substrate (the signing layer — ALREADY BUILT)

> This is the former `ClusterTrust_handover.md`, kept intact because it is load-bearing and a
>  memory-less instance needs it verbatim. Most of it is DONE (heading 2.7). It exists so that the
>   privileged frames a flock sends — `gen_write`, `restart_request` — are **signed by a cluster key
>    and verified against the trusted flock**; unsigned/foreign frames are dropped. A sender in the
>     flock may do everything — there is no separate capability layer (2.8).

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
- `scripts/gen-cluster-identos.ts` — mints the SECRET flock (random ed25519 per role), SPLIT per
   role: `.env.cluster-pubs` (PUBLIC) + `.env.cluster-<role>` (SECRET). All gitignored. Distribute
    each role file to its host ALONE. `--force` rotates.
- `src/lib/p2p/Identos.ts` — the PUBLIC deterministic pool (peer NAMES for flock tests). **Distinct
   from cluster_trust**: Identos = public addresses, no secrecy; cluster_trust = secret signing keys.
- `src/lib/server/relay.ts` — the `/relay` forwarder; `header.sign` already crosses the wire (binary
   frame `[header JSON]\n[raw buffer]`, header cleartext so the relay routes on `to`; signed ≠ encrypted).

**The `.env*` inventory — where the keys actually live** (all gitignored, `.env.*`; `gen-cluster-identos`
 mints + SPLITS them so no host holds a key it doesn't own):
- **`.env.cluster-pubs`** — *PUBLIC*. `CLUSTER_TRUSTED_PUBS` = comma-list of the flock's full pubkeys.
   Distribute everywhere; `env_file` into every verifier; `vite.config.ts` bakes it to
    `VITE_CLUSTER_TRUSTED_PUBS` for the browser. **This list IS the authority** (2.8) — in it ⇒ trusted.
- **`.env.cluster-<role>`** — *SECRET, one per role*: `CLUSTER_IDENTO_<ROLE>_KEY` (+ `_PUB`). Three roles
   today — `editor` (addr `214f8a4e…`), `runner` (`9d2498e3…`), `claude` (`e63cdcca…`). Each file goes to
    that role's host ALONE and is `env_file`d into ONLY that service (docker-compose), so no container
     holds a foreign role's private key.
- **The browser** can't read node env files: it holds its role key out-of-band in the top House's Dexie
   `.stashed.cluster_idento` via the 🪪 Id hatch (`IdHatch.svelte` — paste a `.env.cluster-<role>`).
- **To add/rotate a role:** `vite-node -c scripts/compile.vite.config.ts scripts/gen-cluster-identos.ts
   [roles…] [--force]`, then hand each `.env.cluster-<role>` to its host alone, keep `.env.cluster-pubs`
    everywhere. `--force` rotates every key (breaks live peers holding the old set — do it deliberately).

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

### 3.3 The `Lies%runner` UI — the outer tab sorts itself out
The runner tab needs a face to declare and manage what it is: pick/fork its `?I=` Idento, show role
 (editor|runner) + lease/claim status + liveness (LIVE/SLUGGISH/DEAD), offer "become runner" / "fork
  a new Id" / "spawn N runner links". A **`Lens:Runner`/Brink** tenant (the Lens:Runner face exists,
   unverified — see the Lens handover); claim status reads the `%Claim` particle the spine mints.

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
   coordination) or stay **read-only** (output via the verdict wire + `Storyrun` pins)? Leaning
    read-only; decide before building the backend.
