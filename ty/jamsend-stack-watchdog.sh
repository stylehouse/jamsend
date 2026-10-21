#!/usr/bin/env bash
# jamsend-stack-watchdog.sh — the HOST's watchdog over the public stack: prod vite (relay + app), Caddy (https), the
#  jamserve daemon.  One probe ROUND per run; jamsend-stack-watchdog.service runs a round every minute, forever
#   (install-jamsend-stack-watchdog.sh puts it in place).  By hand: `DRY=1 ./jamsend-stack-watchdog.sh` for one round.
#   (Not to be confused with history/jamsend-watchdog.service — the retired Chrome/puppeteer heartbeat.)
#
#  Each service has a probe.  A probe failing FAILS_<SVC> minutes in a row restarts that container (`docker restart` by
#   NAME — works from any directory, no compose dir needed), then the service gets COOLDOWN seconds to come back before it
#    can be restarted again.  Everything it sees goes to $LOG; a restart also dumps the container's last log lines and a
#     `docker stats` snapshot first, so the evidence survives the cure.
#
#  Why (2026-10-21): the daemon blocked its event loop for 8.5 minutes, the relay cut it for a missed pong, and the
#   browser starved mid-preview — nothing noticed but the listener.  The daemon now logs its own stuck stack (the 🐕 loop
#    watchdog in scripts/daemon/main.ts); this is the outside half that acts.
#
#  Overrides via env or a sibling jamsend-stack-watchdog.env (sourced if present):
#   PROD_CONTAINER (jamsend-prod)   PROD_URL (http://172.17.0.1:19091)
#   DAEMON_CONTAINER (jamserve)     DAEMON_URL (http://172.17.0.1:9099)
#   CADDY_CONTAINER (leproxy-caddy-1; set it empty ⇒ Caddy is probed and logged but never restarted)
#   PUBLIC_URL (https://jamsend.duckdns.org:9999)
#   FAILS_PROD (3)  FAILS_CADDY (3)  FAILS_DAEMON (5)  COOLDOWN (900)
#   STATE (/var/tmp/jamsend-watchdog)  LOG ($STATE/watchdog.log)   DRY=1 ⇒ say what it would restart, don't
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
[ -f "$HERE/jamsend-stack-watchdog.env" ] && . "$HERE/jamsend-stack-watchdog.env"

PROD_CONTAINER="${PROD_CONTAINER:-jamsend-prod}"
PROD_URL="${PROD_URL:-http://172.17.0.1:19091}"
DAEMON_CONTAINER="${DAEMON_CONTAINER:-jamserve}"
DAEMON_URL="${DAEMON_URL:-http://172.17.0.1:9099}"
CADDY_CONTAINER="${CADDY_CONTAINER-leproxy-caddy-1}"   # no colon: an explicit empty value disables the restart
PUBLIC_URL="${PUBLIC_URL:-https://jamsend.duckdns.org:9999}"
FAILS_PROD="${FAILS_PROD:-3}"
FAILS_CADDY="${FAILS_CADDY:-3}"
FAILS_DAEMON="${FAILS_DAEMON:-5}"
COOLDOWN="${COOLDOWN:-900}"
STATE="${STATE:-/var/tmp/jamsend-watchdog}"
LOG="${LOG:-$STATE/watchdog.log}"
DRY="${DRY:-}"

mkdir -p "$STATE"
exec 9>"$STATE/lock"
flock -n 9 || exit 0          # a slow probe round must not stack up behind itself

# to the file AND stdout — under the service, stdout is the journal (journalctl -u jamsend-stack-watchdog)
say() { local line; line="$(date -u '+%F %T') $*"; echo "$line" >> "$LOG"; echo "$line"; }
# keep the log bounded: one prior generation, like the daemon's own
if [ -f "$LOG" ] && [ "$(stat -c %s "$LOG" 2>/dev/null || echo 0)" -gt 5242880 ]; then mv -f "$LOG" "$LOG.1"; fi

# http_code URL [max-seconds] — the status code, or 000 when nothing answered in time
http_code() { curl -sk -o /dev/null -m "${2:-20}" -w '%{http_code}' "$1" 2>/dev/null || true; }

# the relay is a websocket upgrade on the same origin: HTTP 200 with a hung upgrade is a known failure shape (the vite
#  restart race), so ask for the upgrade itself and want 101 Switching Protocols.
ws_code() {
    curl -sk -o /dev/null -m 5 -w '%{http_code}' --http1.1 \
        -H 'Connection: Upgrade' -H 'Upgrade: websocket' -H 'Sec-WebSocket-Version: 13' \
        -H 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' "$1/relay" 2>/dev/null || true
}

# verdict SVC ok|fail detail CONTAINER LIMIT — count consecutive failures, restart at LIMIT, respect the cooldown
verdict() {
    local svc="$1" result="$2" detail="$3" ctr="$4" limit="$5"
    local nf=0 f="$STATE/$svc.fails" r="$STATE/$svc.restarted"
    [ -f "$f" ] && nf="$(cat "$f")"
    if [ "$result" = ok ]; then
        [ "$nf" -gt 0 ] && say "✓ $svc healthy again after $nf failed probe(s) — $detail"
        echo 0 > "$f"
        return
    fi
    nf=$((nf + 1)); echo "$nf" > "$f"
    say "✗ $svc probe failed ($nf/$limit) — $detail"
    [ "$nf" -lt "$limit" ] && return
    if [ -z "$ctr" ]; then say "  $svc: no container configured — not restarting"; return; fi
    local now last=0; now="$(date +%s)"
    [ -f "$r" ] && last="$(cat "$r")"
    if [ $((now - last)) -lt "$COOLDOWN" ]; then say "  $svc: restarted $((now - last))s ago — inside the ${COOLDOWN}s cooldown, waiting"; return; fi
    say "↻ restarting $ctr ($svc) — evidence first:"
    { docker stats --no-stream "$ctr" 2>&1 | sed 's/^/    /'; docker logs --tail 80 "$ctr" 2>&1 | sed 's/^/    | /'; } >> "$LOG"
    if [ -n "$DRY" ]; then say "  DRY — would have run: docker restart $ctr"; else docker restart "$ctr" >> "$LOG" 2>&1 && say "  restarted $ctr"; fi
    echo "$now" > "$r"; echo 0 > "$f"
}

# ── prod vite: the page and the relay ───────────────────────────────────────────────────────
p_page="$(http_code "$PROD_URL/BigSoundland" 30)"
p_ws="$(ws_code "$PROD_URL")"
prod_ok=fail
[ "$p_page" = 200 ] && [ "$p_ws" = 101 ] && prod_ok=ok
verdict prod "$prod_ok" "page=$p_page relay=$p_ws" "$PROD_CONTAINER" "$FAILS_PROD"

# ── Caddy: only judged while prod itself is up, or a dead vite gets blamed on the proxy ──────
c_page="$(http_code "$PUBLIC_URL/BigSoundland" 30)"
if [ "$prod_ok" = ok ]; then
    caddy_ok=fail; [ "$c_page" = 200 ] && caddy_ok=ok
    verdict caddy "$caddy_ok" "public=$c_page" "$CADDY_CONTAINER" "$FAILS_CADDY"
fi

# ── the daemon: its own status endpoint answers only when its event loop is free ─────────────
d_code="$(http_code "$DAEMON_URL/status" 15)"
daemon_ok=fail; [ "$d_code" = 200 ] && daemon_ok=ok
verdict daemon "$daemon_ok" "status=$d_code" "$DAEMON_CONTAINER" "$FAILS_DAEMON"
