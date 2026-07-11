#!/usr/bin/env bash
# editor_awake.sh — keep the jamsend editor (+ a runner) tab ALIVE so /relay stays connected.
#
# RUN THIS ON THE HOST, not in the dev container — it launches host browser windows.
#
# The problem: a backgrounded browser tab gets its timers throttled (~1/min after a few
#  minutes) and can be discarded under memory pressure.  Either one drops the tab's /relay
#   websocket, and the relay evicts the participant → "no editor connected" / half-open
#    runner.  OS display-sleep/screensaver hides every tab at once and triggers the same.
#
# The flags below disable that throttling + discard, so the tabs survive being hidden;
#  systemd-inhibit stops the machine from idle/sleep/screen-blank while it runs.  With the
#   flags on, you do NOT have to keep the window focused — a hidden tab keeps ticking.
#
#   URL_EDITOR / URL_RUNNER / PROFILE overridable via env.  Ctrl-C to release the inhibit.
set -euo pipefail

URL_EDITOR="${URL_EDITOR:-http://localhost:9091/}"
URL_RUNNER="${URL_RUNNER:-http://localhost:9091/?B=GhoghoDrone}"
PROFILE="${PROFILE:-$HOME/.jamsend-awake-profile}"   # dedicated profile — won't touch your normal browser

BIN=""
for c in google-chrome google-chrome-stable chromium chromium-browser brave-browser microsoft-edge; do
  command -v "$c" >/dev/null 2>&1 && { BIN="$c"; break; }
done
[ -n "$BIN" ] || { echo "editor_awake: no chromium-family browser on PATH" >&2; exit 1; }

FLAGS=(
  --user-data-dir="$PROFILE"
  --disable-background-timer-throttling          # hidden-tab timers keep full speed
  --disable-backgrounding-occluded-windows       # covered windows aren't demoted
  --disable-renderer-backgrounding               # renderer priority stays high in background
  --disable-features=CalculateNativeWinOcclusion,IntensiveWakeUpThrottling,TabDiscarding
  --new-window
)

# Belt-and-braces for classic X screensavers (harmless if absent):
command -v xset >/dev/null 2>&1 && xset s off -dpms 2>/dev/null || true

# systemd-inhibit blocks idle→sleep→screen-blank for the browser's lifetime (GNOME/logind).
INHIBIT=()
command -v systemd-inhibit >/dev/null 2>&1 && \
  INHIBIT=(systemd-inhibit --what=idle:sleep:handle-lid-switch --why="jamsend editor relay" --mode=block)

echo "editor_awake: $BIN — editor=$URL_EDITOR runner=$URL_RUNNER (sleep-inhibited: ${INHIBIT:+yes})"
exec "${INHIBIT[@]}" "$BIN" "${FLAGS[@]}" "$URL_EDITOR" "$URL_RUNNER"
