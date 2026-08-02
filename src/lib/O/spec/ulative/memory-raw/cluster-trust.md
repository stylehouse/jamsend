---
name: cluster-trust
description: Authenticated cluster channel — signing relay frames to close the gen_write RCE; two-agent split
metadata: 
  node_type: memory
  type: project
  originSessionId: 1ba65664-b844-4697-a7a2-797e790ee535
---

Building the **authenticated cluster channel**: editor/runner/claude-cli sign privileged relay frames
with a cluster Idento; receivers verify against the trusted flock; unsigned/foreign dropped. Closes
the live RCE — `gen_write` writes any `gen/**.go` to disk from any socket and Vite runs it.

**2026-07-01 — trusted set SIMPLIFIED to {editor, claude}; runners OUT.** The set is ONLY the code-push
allowlist — the two gates that read it are the relay `gen_write` + editor `ghost_compile` verify. A runner
signs nothing it verifies (hello=self-auth; advertise/ping/run_* unsigned) and its disk access rides
**`%Grant`** (per-runner, editor-signed, `by==editor.pub` — NOT set membership). So `.env.cluster-editor`
+ `.env.cluster-runner` are DROPPED: the editor uses a `?I=` %Identity and SELF-PROVISIONS via IdHatch's
**“Set up cluster trust”** button → `Lies_cluster_setup` (LiesLies) FSA-writes `.env.cluster-pubs` (rebuilt
to {this editor, claude}, EDITOR_URL kept) + mints `.env.cluster-claude` if absent; `Lies_cluster_trust_status`
+ the IdHatch ✅/⚠️ line show it. `mintClusterKey` added to cluster_trust.ts; **`scripts/gen-cluster-identos.ts` DELETED 2026-07-01**
(editor is the sole key genesis — no no-browser cold-start path; rotate via `?I=new` / `rm .env.cluster-claude` + the button). Headless flock runners = real Chrome at `?I=<tag>` (bot.js) → self-gen identity, NEVER used the runner
key; composes never env_file'd editor/runner keys (only pubs+claude) → nothing to un-wire. Relay+Vite read the
set at start/build → **RESTART after any change.** **VERIFIED 2026-07-01: owner clicked the button, editor pub is now in the trusted set, servers restarted — gen_write authorised.** type-clean.

**Two parallel jobs, contract NOW in `src/lib/O/spec/Cluster_spec.md` §2 (renamed+expanded from the old
`ClusterTrust_handover.md` 2026-06-29 — same trust substrate, now under the wider cluster/runner-flock spec; read it first):**
- THIS/transport agent: relay-side `gen_write` verify gate (`relay.ts handleGenWrite`) — LANDED
  (enforces when `CLUSTER_TRUSTED_PUBS` set, warn-and-allows otherwise; sha256 body_hash + verifyHeader).
- OTHER/clients agent (me): clients sign their frames; `this-dock-updated` event; claude `.g→.go`;
  PereEditrogression test.

**Foundation (built, tested):**
- `src/lib/p2p/cluster_trust.ts` — `signHeader`/`verifyHeader` (fail-closed), `canonicalHeader`
  (header minus `sign`, key-sorted), `loadTrustedPubs`/`loadRoleKey`/`prepubOf`, `sha256hex` (the
  body commitment — sha256 NOT the spine's collidable FNV `Peeroleum_body_digest`).
- `scripts/gen-cluster-identos.ts` → mints RANDOM (not seed-derived) keypair per role, SPLIT per role
  (no over-share): `.env.cluster-pubs` (PUBLIC CLUSTER_TRUSTED_PUBS) + `.env.cluster-<role>` (SECRET
  KEY/PUB). All gitignored (.env.*). Distribute each role file to its host alone; `--force` rotates.
  Distinct from the PUBLIC `src/lib/p2p/Identos.ts` pool.
- docker-compose.yml: `app` env_files `.env.cluster-pubs` (verify-only) + blank-masks `.env.cluster-claude`;
  `claude` env_files `.env.cluster-claude` (its key only). Both `required:false`. So no container holds a
  foreign role's secret. vite.config bakes VITE_CLUSTER_TRUSTED_PUBS from process.env.CLUSTER_TRUSTED_PUBS.

**DONE this session — editor signs `gen_write`:** `Lies_send_gen_write` (LiesLies.svelte) now async +
signs; `Lies_cluster_idento(w)` reads the BROWSER key from the top House's Dexie `.stashed.cluster_idento` (set via the 🪪 Id hatch, IdHatch.svelte; read live → no reload)
(`{pub,key}`, per-profile, out-of-band — user chose the editor-browser-holds-its-key path) or a node
client's `CLUSTER_IDENTO_<ROLE>_KEY` env. Caller `LiesCortex.svelte:161` awaits. Interop-verified
against the relay gate. Forward-compatible (unsigned still works until env deployed).

**Wire contract:** signed unit = header `{control,path,from,body_hash}`; `body_hash=sha256(body)`;
`sign=ed25519(canonicalHeader)`; send `{...header, body, sign}`.

**DONE — this-dock-updated + browser trust exposure:** signed unit in the CONSUMER PAYLOAD
(`{type,from,path}`+`sign`), so the spine ferries it opaque (no spine edit, resolves the sync-inbox
constraint). Editor handler `Lies_this_dock_updated_recv` (Peeroleum_on seam, async verify →
`delete good.c.content`+`LiesStore_read_good`); emitters `Lies_send_dock_updated` (browser) +
`ghost-update --notify-editor <relay>` (claude-cli). `vite.config` bakes `VITE_CLUSTER_TRUSTED_PUBS`/
`VITE_CLUSTER_ROLE` (public only); `cluster_trust` adds `browserTrustedPubs()`/`browserRole()`. Trust
contract tested 5/5.

**THE ONE REMAINING HOP:** editor↔runner this_dock_updated works (both Ud-handshaken); claude→editor is
dropped at the spine PRE-%Ud gate (`Peeroleum.g:308`) until the spine accepts a cluster-trusted frame in
the recv window (`Peeroleum_deliver` post_do: verify payload sign → treat as Ud-ok). Spine = host-live
surface → COORDINATE, don't unilaterally edit.

**Role/env convention:** relay = verify-only (just `CLUSTER_TRUSTED_PUBS` via env_file); browser role from
?E=/?B= or `VITE_CLUSTER_ROLE`, key from top-House `.stashed.cluster_idento` via the 🪪 Id action/IdHatch (NOT localStorage); CLI = role `claude`
(`CLUSTER_IDENTO_CLAUDE_KEY`). Compose declares role only for autonomous signers / dedicated browser builds.

**Constraints (handover §69):** browser can't safely hold a key if origin exposed (user accepted for the
editor); `verifyHeader` async vs sync `pump_inbox` → verify in handler/recv-window not pump_inbox.
See [[compile-request-api]] for the `.g→.go` tooling.

**Local vs remote:** local runners share `/app` → `ghost_update.ts` writes `.go` directly, NO gen_write.
gen_write/`--remote` only for remote runners (out of scope now).

**This signing layer is FRAME-AUTH (*who sent this frame*) — and 2026-06-29 the human ruled that IS the WHOLE
story.** *What an Id may DO* is NOT a separate layer: a sender in `CLUSTER_TRUSTED_PUBS` may do everything (run
code / allocate / honour a `%Rungo` / ask a host restart). NO capability certs, NO tyrant, NO trust tokens — a
tyrant-rooted cert chain was prototyped that day and **dropped** ("we don't need new cluster certs"; Cluster_spec
§2.8). Knowing the sender + verifying the sig IS the permission. Finer grants IF ever = app-level particles in
`Ghost/N/Tyrant.g`, not certs. See [[runner-fleet-goal]] for the full reversal (host-exec = `chrome_launcher.sock`
lineage / ty/launcher.py; runner = trusted-flock member; KEPT the relay `to:<pub>` signed-`hello` bind).
