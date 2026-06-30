#!/usr/bin/env bash
# flock.sh — bring a CLUSTER of Chrome app-runners up/down/restart (Cluster_spec §4).
#   A cluster IS a compose project, so many run side by side. Restart is graceful:
#    it cycles only this cluster's chromes; identities + run records survive, so the
#     runners re-bind and re-announce rather than reset (see docker-compose.yml header).
#
#   usage:  ./flock.sh <cmd> [cluster=flock]
#     up        start (or rebuild) the cluster, detached
#     down      stop + remove the cluster's containers
#     restart   graceful bounce of this cluster only
#     ps        list the cluster's containers
#     logs      follow the cluster's logs (bot heartbeats + self-heals)
#     vnc       start the cluster WITH noVNC published (watch at :7901-:7903)
#   examples:
#     ./flock.sh up alpha          # cluster "alpha", 3 runners ?I=alpha-1..3
#     ./flock.sh up beta           # a second cluster alongside, no clash
#     ./flock.sh restart alpha     # bounce alpha; beta untouched
set -euo pipefail
cd "$(dirname "$0")"

cmd="${1:-help}"
cluster="${2:-flock}"
export CLUSTER="$cluster"
dc() { docker compose -p "$cluster" "$@"; }

case "$cmd" in
  up)      dc up -d --build ;;
  down)    dc down ;;
  restart) dc restart ;;
  ps)      dc ps ;;
  logs)    dc logs -f --tail=80 ;;
  vnc)     docker compose -p "$cluster" -f docker-compose.yml -f docker-compose.vnc.yml up -d --build
           echo "watch → http://localhost:7901  :7902  :7903" ;;
  *)       sed -n '2,20p' "$0"; exit 1 ;;
esac
