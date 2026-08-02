---
name: identity-thing-jamsend-track
description: Identity + friendship persisted to owner-local .jamsend — BUILT+GREEN (SwarmDisk); keys ride the snap in clear; %Pier/%Grant durable via stash/rehydrate; migrator DROPPED; only owed seam = Auto boot-seed wiring (two-tab test)
metadata: 
  node_type: memory
  type: project
  originSessionId: 2f2e32df-77de-4509-9ea4-3454f9ecd5a7
---

**Identity-on-.jamsend is CUT + GREEN×2 (SwarmDisk, 2026-07-27).** The human's rulings (answered — do NOT re-ask):
- `.jamsend` is **owner-local** (NOT readable via Repli) → **keys ride the snap in clear**. (Enforced in code 2026-07-27: `Crate_nav_paths` skips dot-dirs/node_modules; Housing `rw_op` refuses any path touching a `.jamsend` segment.)
- **`Swarm_export`/`Swarm_import` dropped the `env.keys` sidecar** — an `account` export embeds the keypair as two hex sc scalars on the Identity root (`Swarm_snap_keyed`); import THAWS onto `.c.keys` + STRIPS off sc, so every LIVE node keeps "keys ride .c only" (only the on-disk snap bears them). SwarmStaple beat 8 green×2, byte-identical.
- **Everyone shares ONE FSA point** → `account/<prepub>/` disambiguates owners; no per-device root. "Which is main" is a Thang (Dexie) concern (`?I=` selects; multi-identity weakly supported). Roster is recognition-only, pub-only.
- **NO migrator** — the old-garden Things→%Idzeug lift is DROPPED (human copies the one account by hand). (Terminology: OLD garden = **Thing**, raw `indexedDB.open('Trust',2)`; **Thang** = Dexie `'thangs'`.)

**Built (Swarm.g `#region portability`):** `Swarm_account_dir/save/load`, `Swarm_account_list`, `Swarm_roster_open/save`, `Swarm_persist`, `Swarm_boot_seed` (PURE lift). Two homes under `.jamsend`: `account/<prepub>/toc.snap` (keyed export = agency, Waft-editable) + `identities/toc.snap` (pub-only roster). SwarmDisk uses an in-memory nav double (memnav — no FSA grant, survives reload); real FSA backend already proven by Heist/Musu over the same 7-method contract. SwarmDisk = 7 beats / 11 assertions green×2 (seal → persist keypair → fresh-browser reseed thawed-key-SIGNS → multi-owner `?I=` pick → write-through UPDATE + %NotGrant tombstone surviving the round-trip). Adding a beat shifts witness-req settling (`ok`↔`initialdo`) in earlier steps — DETERMINISTIC, re-record the shifted steps.

**Friendship durability (the SECOND organ of the same disease).** `Swarm_seal` built `%Pier` + both `%Grant` atoms + `%NotGrant` revocations as RUNTIME particles under the `%Peering` — reload lost them (r2r redial masked it, "gets lost very easily"). Fix:
- `Swarm_pier_stash(ident, page, grants, nots)` — on `top_House().stashed`, keyed my-prepub→their-prepub `{page:{prepub,pub,friendly}, grants:[raw atoms], nots:[raw atoms]}`. Merges by field (a partial revoke-caller never blanks a known page). **Gated on `Swarm_live_self()===ident`** — Book-minted idents never stash (prevents puppet pollution).
- `Swarm_piers_rehydrate(w, ident)` at station standup replays each entry THROUGH the idempotent `Swarm_seal` (rehydrate = re-seal; `pier.sc.since` only stamps when absent). `Swarm_restash_piers` converges disk-grafted accounts (2026-07-27 fix — grafted piers now hit the stash). Tombstone law upheld: the stash NEVER drops a `not` (a forgotten revoke would RE-GRANT on rehydrate). The transport `%Pier` re-mints per rehydrated friendship (`Swarm_station_routes`); a `suggests` lane rides the friendship `%Pier` (capped 24/friend). **How to apply:** anything minted at a handshake a USER would call "mine" needs a durable twin on `stashed` + a standup rehydrate through the idempotent constructor.

**The ONE owed seam: wire `Swarm_boot_seed` into Auto `ensure_identity`** — exact patch in `spec/Identity_persist_todo.md §5` (seam = `Clustation_ensure_identity` peek-MISS; `Clustation_concrete` oai's the grafted Identity so no dup; `?I=<prepub>` path only). OWED sub-piece: the second-reload trap → `Swarm_restash_all` OR make disk authoritative — DECIDE at the two-tab test (WITH the human, not blind). See [[invite]], [[swarm-invite-features]], [[revocation-tombstone-durable]], [[reconnect-epoch-seq-collision]], [[live-share-wired]].
