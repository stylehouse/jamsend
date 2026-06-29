# deploy/ — host infrastructure for the runner fleet

Host-side pieces from `src/lib/O/spec/Cluster_spec.md`. App-independent: nothing here imports the
Svelte app, and the app does not depend on these — they stabilise the topology the flock rides on.

## Trusted-command runner (§3.7)

Signed host control: a tiny daemon that runs **one of a fixed allowlist** of host commands, only when
the caller presents a tyrant-rooted `can:restart` capability cert (§2.8) and signs the request with the
granted key. Fail-closed at every step. The host-side twin of the in-app `restart_request`.

Three parts:

| file | role |
|---|---|
| `../scripts/trusted-command-runner.ts` | the daemon — verifies the cert/sign, then invokes the script |
| `trusted-commands.sh` | the allowlist — **the entire privileged surface**; a name → an action |
| `trusted-command-runner.service` | systemd unit that keeps the daemon up |

### The trust chain

1. The tyrant mints a cert once: `vite-node -c scripts/compile.vite.config.ts scripts/mint-cluster-cert.ts grant --grantee <runner-pub> --can restart --days 90`.
2. The caller POSTs `/run` with `{cmd, arg?, cert, from, ts, sign}` where `sign` is ed25519 over
   `requestSignBytes({cmd, arg, from, ts, grantee})` by the **grantee's** key (the key the cert names).
3. The daemon checks, fail-closed: tyrant configured → cert tyrant-signed & unexpired → cert grants
   `can:restart` → request signed by the cert's grantee → command allowlisted → request fresh (±30s).
4. Only then it runs `trusted-commands.sh <cmd> [arg]`. The caller picks a **name**, never a command.

The tyrant is contacted **only to mint** (step 1). Checking (step 3) is offline against the baked
`CLUSTER_TYRANT_PUB` — the daemon never dials the tyrant.

### The bootstrap wrinkle (§3.7)

One allowlisted action is `restart-proxy` — restarting the ssh reverse proxy the tyrant's relay rides.
So **the daemon must be reachable on a channel that survives that proxy being down**: bind
`TRUSTED_CMD_PORT` to a *direct* port (or a second ssh path), never only behind the proxy it recovers.
Keep the recovery channel independent of the thing being recovered.

### Install

```sh
# 1. bundle the daemon to a single self-contained .mjs (no app toolchain on the host):
npx esbuild scripts/trusted-command-runner.ts --bundle --platform=node --format=esm \
  --outfile=/opt/jamsend/trusted-command-runner.mjs
# 2. place the allowlist script + unit:
sudo install -m 0755 deploy/trusted-commands.sh /opt/jamsend/trusted-commands.sh
sudo install -m 0644 deploy/trusted-command-runner.service /etc/systemd/system/
# 3. the env file (SECRET-ish — the public root pub + the direct port):
sudo tee /etc/jamsend/trusted-command-runner.env >/dev/null <<EOF
CLUSTER_TYRANT_PUB=<the tyrant's 64-hex pub>
TRUSTED_CMD_PORT=9099
TRUSTED_CMD_SCRIPT=/opt/jamsend/trusted-commands.sh
EOF
# 4. enable:
sudo systemctl daemon-reload && sudo systemctl enable --now trusted-command-runner
```

### TO-CONFIRM per host (placeholders in `trusted-commands.sh`)

These were not yet pinned when the script was written — set them before enabling:

- `TRUSTED_PROXY_UNIT` — the ssh reverse proxy's systemd unit name (default `ssh-reverse-proxy.service`).
- `restart-docker` allowlist — the real docker compose service names (default `app|relay|claude`).
- `TRUSTED_VIRT_DOMAIN` / `TRUSTED_VIRT_SNAPSHOT` — the KVM guest + known-good snapshot (ty/ heritage).

The daemon runs as a user with exactly the `sudo`/group rights those actions need (e.g. `docker`
group, a narrow sudoers entry for `systemctl restart <unit>` and `virsh snapshot-revert`), nothing
broader — the allowlist script is narrow by construction, but least-privilege the account too.

## Headless proof

`scripts/cluster-cert-test.ts` proves the cert layer and the daemon's authorization fail-closed
(every denial path; exec never called when denied), no host touched. Run:

```sh
vite-node -c scripts/compile.vite.config.ts scripts/cluster-cert-test.ts
```
