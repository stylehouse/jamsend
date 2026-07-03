# flock — dockerised Chrome app-runners (Cluster_spec §4)

The real-isolation testbed. Each runner is a **container running a real Chrome running
 the app**, booted as an `?I=<cluster>-<n>` idle runner — a genuine WebRTC peer with real
  serialization, real connection setup, real loss. This is what the in-process Story
   (PereProof et al.) structurally *can't* be. A flock of these is the swarm a
    distributed Story musters its cast from.

Lineage: copied + adapted from `ty/droidlounge` (the abandoned prod pier-scraper). The
 Selenium `standalone-chromium` droid + `bot.js` pair stays; the bot no longer scrapes
  production — it babysits a runner tab.

## The two intents this serves

**1. Many clusters coming and going.** A *cluster* is a compose **project**; clusters
 coexist as separate projects with their own bridge network, container names, and
  per-cluster Chrome profiles. Nothing is published to the host by default, so any number
   run side by side with zero port arbitration.

```
./flock.sh up alpha        # cluster "alpha": 3 runners, ?I=alpha-1..3
./flock.sh up beta         # a second cluster alongside — no clash
./flock.sh ps alpha
./flock.sh down beta
```

**2. Restarting without dropping anyone's work.** `./flock.sh restart alpha` cycles
 **only** alpha's chromes; beta never notices. And alpha's own work is not lost, because
  work does not live in the tab:

- each runner's **Idento + `%HostedIdentity`** persist in its mounted per-cluster profile
   (`.env.chrome-profiles/<cluster>-<n>/`), so a bounced runner re-binds to the relay as
    the **same** runner — sticky `favourite_client` still points at it;
- in-flight runs live in durable **`Storyrun`** records pinned on other peers / the relay,
   addressable `@uid` — the orchestrator re-musters or resumes from there.

So a restart is a **re-announce, not a reset**. The bot reinforces this: on any crash it
 rebuilds the session against the same persisted profile (a graceful self-heal).

## Watching one

```
./flock.sh vnc alpha       # publishes noVNC → http://localhost:7901 :7902 :7903
```
Only one *watched* cluster at a time (those host ports are fixed). Unwatched clusters
 publish nothing. Otherwise just read the bot heartbeats: `./flock.sh logs alpha`.

## How a runner boots

`bot.js` opens `${TARGET_BASE}/?I=<cluster>-<n>` (default `TARGET_BASE=http://host.docker.internal:9091`).
 `?I=<tag>` **alone** (no `?B=`) puts the tab on the grid as an idle runner; the tag keys
  the forked Idento (§3.1). The app then auto-acquires the spine via Creduler
   (`CREDULER_GHOSTS`, gated by `%Creduler_pending`) and idles awaiting `%Rungo`. Confirm
    liveness out-of-band with `scripts/runner_ask.mjs` over the same `/relay`.

## Preconditions

- **Dev server reachable from containers.** They hit `host.docker.internal:9091`
   (mapped via `extra_hosts: host-gateway`). Point elsewhere with `TARGET_BASE=…`.
- **`ALLOWED_HOSTS`** on the dev server must admit the `Host` the containers send
   (`host.docker.internal`) — see the allowed-hosts env note; don't expose the dev
    server unauthed.
- **The gen `.go` must already exist on disk** (ghost-compiled) for Creduler to acquire —
   a headless container has no editor to compile.

## Bombs / TODO (the gaps before this is a true §4 swarm)

- **Addressing.** Fanning a run to a *specific* runner needs `to:<pub>` (§3.2): built
   relay-side + verified, but **no peer emits the signed hello yet** (`Tribunal.g`
    `Socket_real`). Until then runners are reachable but not individually addressable —
     the flock can stand up, but the conductor can't yet say "this part on alpha-2."
- **Repo IO is grant-gated — BUILT (2026-07-01), :9091-unverified.** A headless container has
   **no FSA handle** (DirectoryAccess is off the table — by design), so boot a runner that needs the
    *real* repo with **`&remoteWormhole=1`** (e.g. `?I=alpha-1&remoteWormhole=1`; was `&disk=proxy`): it acquires a
     **`method:remoteWormhole`** backend, **begging the editor through the channel** (`wormhole_beg`).
      The operator clicks **grant 🛰️** on that runner's row in the editor's **Rundar** rack; the editor
       mints a signed **`%Grant`** (`Funk/Grant.ts`), the runner holds it (local `.stashed`, survives a
        bot self-heal) and presents it back with every rw-op, which the editor verifies + serves from its
         own handle. Until granted, the runner's reads park (the intended gum-up). Range reads
          (`read_range`) keep a big asset from crossing whole. See Cluster_spec "beg through the Brink"
           for the deltas (base64 v1; single-runner addressing until the spine is re-pinned). Sim Books
            that carry their own fixtures (Peeroleum family) need none of this — boot them WITHOUT
             `&remoteWormhole=1`. To wire it into the flock, add `&remoteWormhole=1` to `bot.js`'s URL
              for runners that drive real-code Books.
- **Crash-quorum restart** (§3.6) + the **host-exec socket** successor (§3.7) — a relay
   `restart_request` past a DEAD-quorum bridged to a host socket line — is unbuilt; for
    now restart is manual (`flock.sh restart`).
- **`?I` idle-runner boot** relies on the "`?I` alone = idle runner" path (clustation
   identity layer). If that regresses, switch to the explicit `?Runner=<name>` successor
    once it lands (§3.0).
- **Watching N clusters at once** needs per-cluster noVNC port offsets — the vnc overlay
   is single-cluster.

## Files

- `docker-compose.yml` — the flock: 3 droid+bot runner pairs, cluster-parameterized.
- `docker-compose.vnc.yml` — overlay that publishes noVNC for one watched cluster.
- `bot.js` — the babysitter: boot a runner tab, heartbeat, self-heal.
- `flock.sh` — up/down/restart/ps/logs/vnc a named cluster.
- `.env.chrome-profiles/` — per-cluster persisted Chrome profiles (Idento lives here).
