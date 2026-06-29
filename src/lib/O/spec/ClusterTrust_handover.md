# Cluster-trust handover

A handoff between two parallel jobs building the **authenticated cluster channel** — so
editor / runner / claude-via-cli sign the frames they message around (and verify what they
receive), closing the unauthenticated-relay RCE.

- **THIS job (transport/trust wiring):** the relay-side verification gate + the signing/
  verifying contract. Builds on the Peeroleum binary transport (spec §4.2 — `header.sign`
  already rides the wire).
- **OTHER job (clients-use-Idento):** make editor / runner / claude-cli actually sign their
  messages with their cluster Idento; the new `this-dock-updated` event the editor gets;
  claude editing + compiling `.g`→`.go` itself; the **PereEditrogression** test to show it off.

This doc is the contract between them. Read it before touching the other side's surface.

---

## The threat & the end state

`gen_write` (the editor shipping a compiled `.go` down its relay socket → Node writes it to
`src/lib/gen/**`) is **unauthenticated**: any ws client that reaches `/relay` can write
arbitrary code to disk, and Vite runs it — an RCE. End state: **every privileged frame is
signed by a cluster key and verified against the trusted flock; unsigned/foreign frames are
dropped.** "All clients have and use the trust."

## The pieces that already exist

- `src/lib/p2p/cluster_trust.ts` — the primitives (importable by node AND browser; only the
  PUBLIC half is browser-safe):
  - `signHeader(header, privHex)` → hex sig. **Node-only** (needs a private key).
  - `verifyHeader(header, trustedPubs)` → the matching full pubkey, or `null` (unsigned/
    malformed/foreign). **Fail-closed**: empty trusted set ⇒ `null`.
  - `canonicalHeader(header)` — the signed unit: header **minus** its `sign` field, key-sorted,
    `JSON.stringify`. Signer and verifier serialise identically regardless of key order.
  - `loadTrustedPubs(env)` (`CLUSTER_TRUSTED_PUBS`), `loadRoleKey(role, env)`
    (`CLUSTER_IDENTO_<ROLE>_KEY`), `prepubOf(pub)` (16-hex address).
- `scripts/gen-cluster-identos.ts` — mints the SECRET flock (random ed25519 per role), SPLIT per
  role: `.env.cluster-pubs` (PUBLIC — `CLUSTER_TRUSTED_PUBS`, every verifier) + `.env.cluster-<role>`
  (SECRET — that role's KEY/PUB). All gitignored (`.env.*`). Distribute each role file to its host
  ALONE; env_file it into only that service — so no container loads or can read a foreign role's key.
  `--force` rotates.
- `src/lib/p2p/Identos.ts` — the PUBLIC deterministic pool (peer NAMES for the flock tests).
  **Distinct from cluster_trust**: Identos = public addresses, no secrecy; cluster_trust =
  secret signing keys. Don't conflate them.
- `src/lib/server/relay.ts` — the `/relay` forwarder; `header.sign` already crosses the wire
  (the binary frame is `[header JSON]\n[raw buffer]`, header cleartext so the relay routes on
  `to`; signed ≠ encrypted).

## The signing contract (what both sides must agree on)

A privileged frame's signed unit is its **header** (the addressing + intent + a body
commitment), never the body bytes directly:

1. Compute `body_hash` over the payload, **then** put it in the header.
2. `sign = signHeader(header_without_sign, roleKey)` — covers `from`/`to`/`type`/`body_hash`/…
   So one signature authenticates the whole frame: the header commits to the body via
   `body_hash`, and the sign commits to the header.
3. Send the header **with** `sign` (+ the body/buffer). The verifier strips `sign`,
   re-serialises canonically, checks against `CLUSTER_TRUSTED_PUBS`, and **also** re-checks
   `body_hash` against the received body (so the signed hash actually covers what arrived).

### body_hash: now sha256 on both sides (was FNV on the spine) — IMPORTANT

The Peeroleum spine's `Peeroleum_body_digest` is now **sha256** (`crypto.subtle`, async) over the
raw buffer bytes — it used to be a non-cryptographic FNV-1a hack that only existed to keep the inbox
synchronous, and that constraint is gone (the delivery path went async all the way). So the old
warning is **lifted**: `body_hash` is cryptographic and therefore **signable** — a `header.sign`
over it genuinely pins the body. The remaining nuance is the **input**, not the strength: the spine
hashes the **raw `Uint8Array` buffer**, while cluster_trust `sha256hex` hashes the **body string**.
For a privileged frame whose body is a string (`gen_write` ships `.go` text), keep using
`sha256hex(body)`; if/when a privileged frame carries a raw buffer, hash the bytes the same way the
spine does so signer and verifier agree byte-for-byte. Security-critical frames still MUST use the
cryptographic hash (now true of both paths) — just be explicit about string-body vs buffer-bytes.

## The three constraints that shape who-does-what

1. **The browser cannot sign.** `signHeader` needs a private key; `CLUSTER_IDENTO_*_KEY` must
   never enter a browser bundle. So a **browser** client (the editor) cannot itself sign a
   `gen_write`. Either the signer is a **node** client (claude-cli, the runner's node side), or
   the browser editor's gen_write is migrated behind a node signer. **Open decision for the
   other job:** who signs the editor's gen_write?
2. **ed verify is async; the Peeroleum inbox is sync.** `verifyHeader` is a Promise, but
   `Peeroleum_pump_inbox` is synchronous (the §7.3 serial lock + mock determinism need it —
   an `await` there escapes the beliefs mutex). So a routed privileged frame can't be verified
   *inside* `pump_inbox`. Verify it in the **async carrier-recv window** (where `Peeroleum_deliver`
   already runs inside `post_do(async …)`) before booking the unemit, stamping a
   verified/rejected flag the sync inbox reads — OR verify control frames in the **relay**
   (node, no Atime). `gen_write` is a control frame handled in the relay, so it's the easy case.
3. **The browser verifier needs the trusted pubs.** `loadTrustedPubs(process.env)` works
   node-side; the browser needs `CLUSTER_TRUSTED_PUBS` exposed (a `VITE_`-prefixed env or an
   injected config). Node clients read `process.env` directly.

## Privileged frames

| frame              | path                              | signer        | verifier             |
|--------------------|-----------------------------------|---------------|----------------------|
| `gen_write`        | control frame → relay writes disk | node (cli)    | **relay** (node)     |
| `dock_push`        | routed envelope (`Peeroleum_on`)  | editor/cli    | runner (recv window) |
| `this-dock-updated`| routed envelope (NEW, other job)  | editor        | recipients (recv win)|

`gen_write` is the RCE; verifying it in the relay is the highest-value, self-contained fix.

## Division of labor

**THIS job builds (option 1):**
- The **relay `gen_write` verify gate** (`relay.ts` `handleGenWrite`): when
  `CLUSTER_TRUSTED_PUBS` is configured, reject a `gen_write` whose `sign` doesn't verify (and
  whose sha256 `body_hash` doesn't match the body) — fail-closed, log the authorised signer.
  When NOT configured, **warn-and-allow** (loud one-liner) so the current dev loop keeps
  working until the cluster is deployed. *(Migration gotcha below.)*
- This contract doc.

**OTHER job builds:**
- editor / runner / **claude-cli** signing the frames they emit with their role Idento
  (`loadRoleKey` + `signHeader`), per the contract above. Browser editor: resolve constraint #1.
- The `this-dock-updated` event (a routed envelope; register via `Peeroleum_on`, sign on emit,
  verify in the recv window).
- claude editing + compiling `.g`→`.go` and emitting a signed `gen_write` (claude-cli = node,
  has a key — the natural signer).
- Browser-side verification of routed privileged frames (constraint #2's recv-window approach)
  + exposing `CLUSTER_TRUSTED_PUBS` to the client (constraint #3).
- The **PereEditrogression** test.

## Migration gotcha (coordinate on this)

Turning on enforcement = setting `CLUSTER_TRUSTED_PUBS`. The moment it's set, the relay
**drops the browser editor's unsigned `gen_write`** — breaking the editor's compile→disk loop
unless the editor's gen_write already goes through a node signer (constraint #1). So: **wire a
signed gen_write path BEFORE (or in the same change as) configuring the cluster env.** Until
then the relay logs `⚠ gen_write UNAUTHENTICATED` and allows it.

## Signed `gen_write` shape (the wire contract this job's gate verifies)

```
{ control: 'gen_write',
  path:      'gen/N/Foo.go',
  body:      '<.go source>',
  from:      '<signer prepub, 16-hex>',
  body_hash: '<sha256(body) hex>',
  sign:      '<ed25519 over canonicalHeader({control,path,from,body_hash})>' }
```
Relay: `body_hash === sha256(body)` AND `verifyHeader({control,path,from,body_hash,sign}, trusted)` ≠ null.

---

## Progress — OTHER job (clients-use-Idento)

**DONE — editor signs `gen_write` (the RCE client half).**
- `Lies_send_gen_write` (LiesLies.svelte) is now `async` and signs per the wire contract above:
  `body_hash = sha256(body)` (cluster_trust `sha256hex`, NOT FNV), header `{control,path,from,body_hash}`,
  `sign = signHeader(header, key)`, sends `{...header, body, sign}`. Caller `LiesCortex.svelte:161`
  now `await`s it. **Forward-compatible**: with no key it sends unsigned and the relay warn-and-allows,
  so this is safe to run before `CLUSTER_TRUSTED_PUBS` is deployed.
- `Lies_cluster_idento(w)` (LiesLies.svelte) resolves this client's `{pub,key}`: **browser editor** reads
  the top House's Dexie `.stashed.cluster_idento` = `{pub,key}` (set via the 🪪 Id hatch / IdHatch.svelte — paste a .env.cluster-<role>; read live, no reload),
  never bundled — resolves constraint #1 by the user's choice: the editor browser holds its own key);
  a **node** client falls back to `loadRoleKey(role)` / `CLUSTER_IDENTO_<ROLE>_KEY` from the env.
- `sha256hex(data)` added to `cluster_trust.ts` (browser+node, crypto.subtle) — the shared body-commitment
  digest both signer and the relay gate use.
- Verified: a frame built by `Lies_send_gen_write` is **accepted** by a replica of the relay's
  `handleGenWrite` gate (signer identified); tampered-body / foreign-key / unsigned all rejected under
  enforcement. Type-clean (no new svelte-check errors).

**DONE — `this-dock-updated` event + browser trust exposure.**
- Signed unit lives in the **consumer payload**, not the spine header: `{type:'this_dock_updated',
  from, path}` + `sign`. So the spine ferries it opaque and needs NO trust awareness — verification is
  done in the handler, not in sync `pump_inbox` (resolves constraint #2 without a spine edit).
- Editor handler: `Peeroleum_on(w,'this_dock_updated', …)` → `Lies_this_dock_updated_recv` (LiesLies.svelte):
  async `verifyHeader({...dock,sign}, browserTrustedPubs())`; on trust, `delete good.c.content` +
  `LiesStore_read_good` to re-read the dock's `%Good`. Untrusted/unsigned dropped+logged.
- Emitters: `Lies_send_dock_updated(w,path)` (browser, signs + `Peeroleum_send_consumer`) and
  `ghost-update --notify-editor <relay-ws>` (claude-cli signs with `CLUSTER_IDENTO_CLAUDE_KEY` + sends).
- Browser trust exposure (constraint #3): `vite.config.ts` bakes `import.meta.env.VITE_CLUSTER_TRUSTED_PUBS`
  + `VITE_CLUSTER_ROLE` from `process.env` (PUBLIC pubs + role label only — keys never referenced);
  `cluster_trust.ts` adds `browserTrustedPubs()` / `browserRole()`. Node still uses `loadTrustedPubs(process.env)`.
- Tested: the `this_dock_updated` signed payload round-trips (accept / tampered-path / foreign / unsigned /
  empty-trust all correct). Type-clean.

**THE ONE REMAINING HOP (needs the spine — coordinate):** the editor's Peeroleum inbox still drops
PRE-`%Ud` senders (`Peeroleum.g:308-310`). Editor↔runner `this_dock_updated` works today (both Ud-handshaken),
but **claude-cli→editor** is dropped pre-Ud until the spine accepts a cluster-trusted frame in the async
**recv window** (`Peeroleum_deliver` post_do): verify the payload sign, and if trusted, treat as Ud-ok so it
reaches the handler. That edit is on the host-live spine surface — left for coordination with the Peeroleum job.

**STILL OPEN:** the spine recv-window trust-accept (above); claude-cli signed `gen_write` (remote runners
only — out of scope); the PereEditrogression test.

---

## Role / env convention (answers "does compose tell each service its role?")

Secrets are SPLIT per role (gen-cluster-identos), and each service env_files ONLY what it needs — so a
container never loads or can read a foreign role's key. docker-compose.yml wires the local pair:
- **Relay / dev server (`app`): verify-only** — `env_file: .env.cluster-pubs` (PUBLIC pubs); the relay
  verifies gen_write and vite bakes `VITE_CLUSTER_TRUSTED_PUBS`. No private key. The co-located
  `.env.cluster-claude` is blank-masked from this container so it can't read claude's secret off `.:/app`.
- **Browser (editor/runner):** *role* from `?E=`/`?B=` (`Lies_role`) or `VITE_CLUSTER_ROLE`; *signing key*
  from the top House's `.stashed.cluster_idento` (via the 🪪 Id action — never bundled); trusted pubs via the
  baked `VITE_CLUSTER_TRUSTED_PUBS`.
- **CLI (`claude`): role `claude`** — `env_file: .env.cluster-claude` (its OWN key/pub only). It signs.
- Each `env_file` is `required:false` so an un-minted cluster doesn't break `up`. Distribute
  `.env.cluster-editor`/`-runner` to the staging editor / runner hosts; don't leave foreign role files here.
- So: compose declares role only where a process *signs autonomously* (none yet) or for a *dedicated* browser
  deployment's default; verifiers just need the trusted pubs. Secrets stay node-side + the editor's .stashed (Id hatch).

## The runner fleet — forking Ids (`?I=`), addressing, and the restart/resume service (the long-term goal)

The destination (the human): a grid of Chrome app-servers running the app, a `Cluster/**` of **forkable Ids**, a
 runner a given editor *owns* (so `%Rungo` is handed to a runner that **focuses on us**, not a random shared one a
  Claude + a human both shoot runs at), a coordinator that asks for a **docker/libvirt restart** when a crash-quorum
   of tabs dies, **two** such grids (they want restarting constantly), and an **Id hop-over** to a fresh identity.
    This is the operations layer that rides the signing substrate above. The SPINE primitives it needs (the one
     `claim`/`lease` frame, `?I=`, point-to-point `to:<pub>` addressing, the `restart_request` frame) are specced in
      **`spec/Peeroleum_handover.md` → "The runner fleet — the spine primitives to invent NOW"**; this section is the
       operations half.

### `?I=` — fork identity at the TAB, not the OS profile
Today: *role* from `?E=`/`?B=` (`Lies_role`); *signing key* = the top House's `.stashed.cluster_idento` (the 🪪 Id
 hatch, `loadRoleKey`). Add **`?I=<tag>`** to select WHICH forked Idento *this tab* uses — minted/loaded from
  `stashed` keyed by the tag. Then **one browser profile hosts many separable runner tabs**, and you **spawn a flock
   by clicking N links**, each carrying a different `?I=`. This is the lightweight successor to `ty/`, which forked
    identity at the OS level — a whole Chrome `--user-data-dir` per profile (`public,private,tyrant` in
     `chrome-starter.py`/`watchdog.js`). The Idento + trust grants travel with the tag; **Id hop-over** = mint a fresh
      tag-keyed Idento, re-grant, re-bind at the relay, drain the old (the garden's `Idzeugnation`, reborn).

### The `Lies%runner` UI — the outer tab sorts itself out
The runner tab needs a face to declare and manage what it is: pick/fork its `?I=` Idento, show its role
 (editor|runner) + lease/claim status + liveness (LIVE/SLUGGISH/DEAD), and offer "become runner" / "fork a new Id" /
  "spawn N runner links". This is a **`Lens:Runner`/Brink** tenant (the Lens:Runner face already exists, unverified —
   see the Lens handover); the claim status is read from the `%Claim` particle the spine mints.

### The restart/resume service the inner sockets to (lifted from `ty/`)
The hard problem (`ty/README.md`): Chrome app-servers hold **File System Access Directory Handles** granted by a human
 clicking "Allow"; they live in browser memory, so **any Chrome restart destroys them**. `ty/`'s answer was NOT to
  restart Chrome but to run the whole Xvfb+Chrome stack inside a **KVM VM** and **revert to a healthy snapshot**
   (`snap3`, taken once handles were granted): the handles survive in the VM's frozen memory and the dirs they point
    at are **virtiofs** mounts from the host, so they're still there on wake. Two host services:
- **`watchdog.js`** (puppeteer-core, in the VM): every 30s connects to each profile's CDP debug port (`PORT_BASE+i`),
   runs `page.evaluate(() => true)` — a **crashed *tab*** is closed + reopened (no full restart); **Chrome unreachable**
    writes `RESTART:<profile>` to a Unix socket. Per-profile cooldown 25s.
- **`virtreset.py`** (on the host): listens on `/tmp/jamsend-supervisor/chrome_launcher.sock` (the VM writes it over
   virtiofs), and on `RESTART:<profile>` does `virsh snapshot-revert … snap3`; ALSO polls VM **balloon memory** and
    reverts before the guest OOMs (>90%); 120s revert cooldown; auto-reverts on host reboot if the VM isn't running.
   A **docker** variant exists (`install-jamsend-supervisor.sh`) but "keeps losing handles" — the KVM-revert is the
    "maybe well" one. The inner→host channel is a plain socket message (`RESTART:<name>`), trivially portable to an
     http or ws endpoint for a non-VM (docker) deployment.

### The crash-quorum → who asks for the restart
`ty/` triggers per-profile (any one Chrome unreachable → a `RESTART`). The human wants a **quorum** ("restart when
 most of ~7 tabs have crashed"). In the new world the **relay is the natural counter** — it already sees every socket
  and the app already computes LIVE/SLUGGISH/DEAD; the relay tallies DEAD across the fleet and, past the quorum, emits
   a `restart_request` control frame bridged to the host reset socket. The "stable filehandle Pier" vision in
    `ty/README.md` (a tab that almost never crashes holds the handles and shunts work to a "progress-bar-of-failure"
     series of work tabs, possibly a separate profile/Pier, WebRTC between them) is exactly the **focused-runner +
      owned-handle** split this fleet wants — the handle-holder is one Idento, the disposable workers another.

### Privileged-frame additions (the wire this implies — extend the table above)
| frame            | path                              | signer          | verifier              |
|------------------|-----------------------------------|-----------------|-----------------------|
| `claim`/`release`| routed envelope (`Peeroleum_on`)  | editor/runner   | relay arbitrates + recipients (recv win) |
| `restart_request`| control frame → host reset socket | relay/supervisor| host `virtreset`      |

Point-to-point delivery uses `to:<Idento.pub>` (the relay binds each verified Idento as its addr on the signed hello),
 reusing `bind`/`deliverLocal`; the `claims` map (today `@channel → socket`) generalises to the leased `%Claim` token.
