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
- `scripts/gen-cluster-identos.ts` — mints the SECRET flock (random ed25519 per role) →
  `.env.cluster-identos` (gitignored; distribute out-of-band; add to each machine's
  docker-compose `env_file`). `--force` rotates.
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

### body_hash: FNV (test) vs sha256 (security) — IMPORTANT

The Peeroleum spine's `Peeroleum_body_digest` is **FNV-1a** — a fast, *non-cryptographic*
digest, fine for the binary **test** exercise (detects accidental/meddle corruption) but
**trivially collidable**. A signature over an FNV `body_hash` is NOT real integrity — an
attacker can craft a different body with the same FNV. So **security-critical frames
(`gen_write`, anything that writes code/disk) MUST use a cryptographic `body_hash` (sha256)**,
not the spine FNV. Keep them separate; do not sign an FNV hash and call it secure.

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
  `localStorage['cluster_idento']` = `'{"pub":"<64hex>","key":"<64hex>"}'` (per-profile, set out-of-band,
  never bundled — resolves constraint #1 by the user's choice: the editor browser holds its own key);
  a **node** client falls back to `loadRoleKey(role)` / `CLUSTER_IDENTO_<ROLE>_KEY` from the env.
- `sha256hex(data)` added to `cluster_trust.ts` (browser+node, crypto.subtle) — the shared body-commitment
  digest both signer and the relay gate use.
- Verified: a frame built by `Lies_send_gen_write` is **accepted** by a replica of the relay's
  `handleGenWrite` gate (signer identified); tampered-body / foreign-key / unsigned all rejected under
  enforcement. Type-clean (no new svelte-check errors).

**STILL OPEN (OTHER job):**
- `this-dock-updated` routed envelope (editor learns a dock's `.g` changed → refresh `%Good`): sign on
  emit, **verify in the async carrier-recv window** (constraint #2 — not in sync `pump_inbox`).
- Expose `CLUSTER_TRUSTED_PUBS` to the browser (constraint #3, a `VITE_` env) for verifying inbound
  routed frames; node clients read `process.env`.
- claude-cli signed `gen_write` — only needed for **remote** runners (out of scope for now; local uses
  `ghost_update.ts` which writes `.go` to the shared disk directly, no `gen_write`).
- The PereEditrogression test.
