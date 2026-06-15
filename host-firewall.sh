#!/usr/bin/env bash
# Run this ON THE HOST (needs root + iptables/ip6tables + ipset).
# Egress allowlist for the jamsend dev container: Anthropic API (keeps Claude
# Code alive) + npm + github, DNS allowed, everything else outbound DROPped.
# Inbound published ports (e.g. 9091) are untouched. Re-run to refresh CDN IPs.
set -euo pipefail
CID="${1:-d78e37a499bc}"

IP4S=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{println .IPAddress}}{{end}}'         "$CID" | grep -v '^$' || true)
IP6S=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{println .GlobalIPv6Address}}{{end}}' "$CID" | grep -v '^$' || true)
echo "container v4: ${IP4S:-none}"
echo "container v6: ${IP6S:-none}"

HOSTS="api.anthropic.com statsig.anthropic.com sentry.io \
registry.npmjs.org \
github.com api.github.com codeload.github.com objects.githubusercontent.com raw.githubusercontent.com"

ipset create jam_allow4 hash:net family inet  -exist
ipset create jam_allow6 hash:net family inet6 -exist
ipset flush jam_allow4; ipset flush jam_allow6

for h in $HOSTS; do
  for ip in $(getent ahostsv4 "$h" 2>/dev/null | awk '{print $1}' | sort -u); do ipset add jam_allow4 "$ip" -exist; done
  for ip in $(getent ahostsv6 "$h" 2>/dev/null | awk '{print $1}' | sort -u); do ipset add jam_allow6 "$ip" -exist; done
done

# github publishes its ranges; covers codeload/objects CDN churn
if command -v jq >/dev/null && command -v curl >/dev/null; then
  meta=$(curl -fsSL https://api.github.com/meta || true)
  [ -n "$meta" ] && echo "$meta" | jq -r '(.git//[])[],(.api//[])[],(.web//[])[]' 2>/dev/null | \
    while read -r c; do case "$c" in *:*) ipset add jam_allow6 "$c" -exist;; *.*) ipset add jam_allow4 "$c" -exist;; esac; done
fi

build_chain() { # $1 = iptables|ip6tables ; $2 = set name ; $3.. = private nets to keep
  local cmd="$1" set="$2"; shift 2
  "$cmd" -N JAMNET 2>/dev/null || "$cmd" -F JAMNET
  "$cmd" -A JAMNET -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN
  "$cmd" -A JAMNET -p udp --dport 53 -j RETURN
  "$cmd" -A JAMNET -p tcp --dport 53 -j RETURN
  for net in "$@"; do "$cmd" -A JAMNET -d "$net" -j RETURN; done   # keep all private/local (compose net, app:9091, LAN)
  "$cmd" -A JAMNET -m set --match-set "$set" dst -j RETURN          # keep allowlisted public domains
  "$cmd" -A JAMNET -j DROP                                          # drop the rest of the public internet
}
build_chain iptables  jam_allow4 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 169.254.0.0/16
build_chain ip6tables jam_allow6 fc00::/7 fe80::/10

for ip in $IP4S; do iptables  -C DOCKER-USER -s "$ip" -j JAMNET 2>/dev/null || iptables  -I DOCKER-USER -s "$ip" -j JAMNET; done
for ip in $IP6S; do ip6tables -C DOCKER-USER -s "$ip" -j JAMNET 2>/dev/null || ip6tables -I DOCKER-USER -s "$ip" -j JAMNET; done

echo "allowlist active for $CID"
