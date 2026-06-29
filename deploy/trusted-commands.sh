#!/usr/bin/env bash
# trusted-commands.sh — the ENTIRE privileged surface of the trusted-command runner (Cluster_spec §3.7).
#
#  The webservice (scripts/trusted-command-runner.ts) has ALREADY verified a tyrant-rooted can:restart
#   cert, fail-closed, before invoking this. This script maps an ALLOWLISTED command NAME to its
#    action. The caller picks a name from the list — it never sends a command — so even a fully
#     compromised webservice can run only what is written here. Keep this file tiny and auditable.
#
#  Invoked as ARGV (never a shell string): bash trusted-commands.sh <cmd> [arg]. No eval, no
#   interpolation of caller input into a shell — `arg` is matched against a literal allowlist below.
#
#  Host-specific names (service units, KVM domain/snapshot) are PLACEHOLDERS, overridable by env and
#   marked TO-CONFIRM — set them per host before enabling the unit (deploy/README.md).
set -euo pipefail

cmd="${1:-}"
arg="${2:-}"

# TO-CONFIRM per host — the real unit/service names.
PROXY_UNIT="${TRUSTED_PROXY_UNIT:-ssh-reverse-proxy.service}"   # the ssh reverse proxy systemd unit
VIRT_DOMAIN="${TRUSTED_VIRT_DOMAIN:-staging}"                   # the KVM guest (ty/ heritage)
VIRT_SNAPSHOT="${TRUSTED_VIRT_SNAPSHOT:-snap3}"                 # the known-good snapshot to revert to

case "$cmd" in
  restart-docker)
    # arg = a docker compose service name, ITSELF allowlisted — no arbitrary service.
    case "$arg" in
      app|relay|claude) exec docker compose restart "$arg" ;;
      *) echo "trusted-commands: docker service '$arg' not allowlisted" >&2; exit 2 ;;
    esac
    ;;
  restart-proxy)
    # The bootstrap wrinkle (§3.7): this restarts the very ssh proxy the tyrant's relay rides — so the
    #  daemon must be reachable on a channel that does NOT depend on this proxy (a direct port).
    exec systemctl restart "$PROXY_UNIT"
    ;;
  snapshot-revert)
    # Generalises ty/'s virtreset.py — revert the KVM guest to a known-good snapshot.
    exec virsh snapshot-revert "$VIRT_DOMAIN" "$VIRT_SNAPSHOT"
    ;;
  *)
    echo "trusted-commands: unknown command '$cmd'" >&2
    exit 2
    ;;
esac
