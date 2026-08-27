#!/usr/bin/env bash
set -u
RA="node scripts/runner_ask.mjs"
$RA release >/dev/null 2>&1
echo "reloading runner (clear cached plans)…"
$RA reload >/dev/null 2>&1
for i in $(seq 1 15); do sleep 8; c=$(timeout 20 $RA ping 2>&1 | grep -oE '"channel":"up"'); [ -n "$c" ] && { echo "runner up after ${i}x8s"; break; }; done
bash scratchpad/record_book.sh SwarmPost 5 scratchpad/sw_post.txt
bash scratchpad/record_book.sh SwarmGossip 4 scratchpad/sw_gossip.txt
bash scratchpad/record_book.sh SwarmServe 4 scratchpad/sw_serve.txt
echo "=== DONE ==="
