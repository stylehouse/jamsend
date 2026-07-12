#!/usr/bin/env bash
# chrome.sh — relaunch your NORMAL Chrome with background-throttling disabled, restoring the exact tabs
#  you already had (all your ?I= identity + ?B= runner URLs).  RUN ON THE HOST.
#
# Uses your DEFAULT profile — no --user-data-dir — so every ?I= chooser, grant and cookie is intact.
#  It does NOT force any URLs: --restore-last-session reopens whatever you last had open.
#
# The catch, stated plainly: the anti-throttle flags only take effect on a FRESH browser process.  A
#  Chrome that's already running ignores flags handed to a second invocation (it just forwards URLs to
#   the existing process), and you can't run two Chromes on one profile at once.  So this QUITS your
#    running Chrome first (gracefully — SIGTERM), then relaunches it with the flags + --restore-last-
#     session, which brings every tab back.  Set NO_QUIT=1 to skip the quit (flags then WON'T apply if
#      a Chrome is already up — useful only when none is running).
#
# The flags stop hidden-tab timer throttling + tab discard — the "half-open relay" where the tab's JS
#  sleeps while the ws keeps ponging.  systemd-inhibit stops display-sleep/screensaver (which hides
#   every tab at once and trips the same throttle).
#
# Usage:
#   chrome.sh                 # quit + relaunch on your normal profile, restore last session
#   chrome.sh <url> [url...]  # ...and also open these alongside the restored tabs
#   NO_QUIT=1 chrome.sh       # don't quit a running Chrome
set -euo pipefail

BIN=""
for c in google-chrome google-chrome-stable chromium chromium-browser brave-browser; do
  command -v "$c" >/dev/null 2>&1 && { BIN="$c"; break; }
done
[ -n "$BIN" ] || { echo "chrome.sh: no chromium-family browser on PATH" >&2; exit 1; }

FLAGS=(
  --restore-last-session                         # reopen the exact tabs you had (your ?I=/?B= URLs)
  --disable-background-timer-throttling          # hidden-tab timers keep full speed
  --disable-backgrounding-occluded-windows       # covered windows aren't demoted
  --disable-renderer-backgrounding               # renderer priority stays high in background
  --disable-features=CalculateNativeWinOcclusion,IntensiveWakeUpThrottling,TabDiscarding
)

# The flags only bite on a fresh process — a running Chrome would just swallow the URLs and ignore them,
#  so quit it first (its session is restored on relaunch).  -x = exact comm match, so no collateral;
#   -u $USER = only OUR browser — a dockerised Chrome (the selenium/Xvfb flock) shows up in the host's
#    pgrep under the same comm but a foreign uid, isn't ours to quit, and can't be signalled anyway,
#     so without -u the wait loop watches it forever and bails.
if [ -z "${NO_QUIT:-}" ]; then
  running=""
  for comm in chrome chromium chromium-browser google-chrome brave; do
    pgrep -x -u "$USER" "$comm" >/dev/null 2>&1 && running="$comm"
  done
  if [ -n "$running" ]; then
    echo "chrome.sh: quitting the running browser ('$running') so the flags take — your session is restored on relaunch…"
    for comm in chrome chromium chromium-browser google-chrome brave; do pkill -x -u "$USER" "$comm" 2>/dev/null || true; done
    for i in $(seq 1 40); do pgrep -x -u "$USER" "$running" >/dev/null 2>&1 || break; sleep 0.25; done
    pgrep -x -u "$USER" "$running" >/dev/null 2>&1 && { echo "chrome.sh: '$running' still running after 10s — quit it by hand, then rerun" >&2; exit 1; }
  fi
fi

# Belt-and-braces for classic X screensavers (harmless if absent):
command -v xset >/dev/null 2>&1 && xset s off -dpms 2>/dev/null || true

# systemd-inhibit blocks idle→sleep→screen-blank for the browser's lifetime (GNOME/logind):
INHIBIT=()
command -v systemd-inhibit >/dev/null 2>&1 && \
  INHIBIT=(systemd-inhibit --what=idle:sleep:handle-lid-switch --why="jamsend relay tabs" --mode=block)

echo "chrome.sh: $BIN --restore-last-session (+throttle-off, sleep-inhibited: ${INHIBIT:+yes})${*:+  extra: $*}"
exec "${INHIBIT[@]}" "$BIN" "${FLAGS[@]}" "$@"
