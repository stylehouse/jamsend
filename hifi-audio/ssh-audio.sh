#!/bin/sh
# ssh-audio.sh — play THIS desktop's audio out of another machine's speakers/headset.
#
#   sh ssh-audio.sh <host> [latency_ms]      e.g.  sh ssh-audio.sh laptop 400
#
# Use case: this desktop has no Bluetooth; the laptop does. Ship the sound there and
#  the laptop's default sink (= its BT headset, once paired) plays it.
#
# Every run does the whole thing, idempotently:
#   1. REMOTE: make its pipewire-pulse listen on localhost:4713 (writes the conf,
#      restarts pipewire-pulse only if the conf changed). Verifies it's listening.
#      ⚠ this is `pulse.properties server.address`, NOT a module — the PulseAudio
#        `module-native-protocol-tcp` name does not exist in PipeWire.
#   2. LOCAL: ssh -L tunnel (local 4713 → remote 4713), wait for it.
#   3. LOCAL: tunnel-sink SSH_Audio over it, matched to the graph rate, with a fat
#      buffer (WiFi's problem is jitter not bandwidth: even 24/96 is ~6 Mbit/s).
#   4. Make it the default output and move playing streams onto it.
# It then HOLDS. Ctrl-C tears everything down and restores your previous output.
# If the ssh drops (WiFi), it tears down too and tells you.
#
# The sink appears where you LOAD it (here), never as an output on the remote —
#  on the remote it's a playback stream. Don't go looking for it in its pavucontrol.
HOST="$1"; LAT="${2:-400}"; PORT=4713; SINK=SSH_Audio
[ -n "$HOST" ] || { echo "usage: sh ssh-audio.sh <host> [latency_ms]"; exit 1; }

# ── 1. remote listener ─────────────────────────────────────────────────────────
echo "== $HOST: ensuring pipewire-pulse listens on 127.0.0.1:$PORT"
R=$(ssh "$HOST" 'sh -s' <<REMOTE
set -e
D=\$HOME/.config/pipewire/pipewire-pulse.conf.d; mkdir -p "\$D"; F=\$D/ssh-audio.conf
cat > "\$F.new" <<'CONF'
# written by hifi-audio/ssh-audio.sh — accept pulse clients over the ssh tunnel
pulse.properties = {
    server.address = [
        "unix:native"
        "tcp:127.0.0.1:$PORT"
    ]
}
CONF
if cmp -s "\$F.new" "\$F"; then rm "\$F.new"; else mv "\$F.new" "\$F"; systemctl --user restart pipewire-pulse; sleep 1; fi
ss -tln | grep -q "127.0.0.1:$PORT" || { systemctl --user restart pipewire-pulse; sleep 1; }
ss -tln | grep -q "127.0.0.1:$PORT" && echo LISTENING || echo NOT_LISTENING
REMOTE
)
case "$R" in *LISTENING) echo "   ok";; *) echo "!! $HOST is not listening on $PORT ($R). Is its user session up?"; exit 1;; esac

# ── 2. tunnel ──────────────────────────────────────────────────────────────────
PREV=$(pactl get-default-sink 2>/dev/null)
SSHPID=""
cleanup() {
  echo; echo "== tearing down"
  for m in $(pactl list modules short 2>/dev/null | awk '/module-tunnel-sink/{print $1}'); do pactl unload-module "$m"; done
  [ -n "$PREV" ] && pactl set-default-sink "$PREV" 2>/dev/null && echo "   output back to $PREV"
  [ -n "$SSHPID" ] && kill "$SSHPID" 2>/dev/null
  exit 0
}
trap cleanup INT TERM

if ss -tln | grep -q "127.0.0.1:$PORT"; then
  echo "== local $PORT already listening — reusing that tunnel"
else
  echo "== opening ssh -L $PORT → $HOST"
  ssh -N -L "$PORT:127.0.0.1:$PORT" "$HOST" & SSHPID=$!
  i=0; until ss -tln | grep -q "127.0.0.1:$PORT"; do i=$((i+1)); [ $i -gt 20 ] && { echo "!! tunnel never came up"; kill $SSHPID; exit 1; }; sleep 0.25; done
fi

# ── 3. tunnel sink, matched to the live graph rate ─────────────────────────────
for m in $(pactl list modules short | awk '/module-tunnel-sink/{print $1}'); do pactl unload-module "$m"; done
RATE=$(pactl list sinks short | awk '/alsa_output/{for(i=1;i<=NF;i++) if($i ~ /Hz$/){sub(/Hz/,"",$i); print $i; exit}}')
RATE=${RATE:-48000}
echo "== loading $SINK  rate=$RATE  latency=${LAT}ms"
pactl load-module module-tunnel-sink "server=tcp:127.0.0.1:$PORT" "sink_name=$SINK" "rate=$RATE" "latency_msec=$LAT" >/dev/null
i=0; until pactl list sinks short | grep -q "$SINK"; do i=$((i+1)); [ $i -gt 20 ] && { echo "!! $SINK never appeared — tunnel connected but no pulse server answered on $HOST"; cleanup; }; sleep 0.25; done

# ── 4. route ───────────────────────────────────────────────────────────────────
pactl set-default-sink "$SINK"
for s in $(pactl list sink-inputs short | awk '{print $1}'); do pactl move-sink-input "$s" "$SINK" 2>/dev/null; done
echo "== playing through $HOST. Ctrl-C to stop and restore $PREV."
if [ -n "$SSHPID" ]; then
  wait "$SSHPID"; echo "!! ssh to $HOST dropped"; cleanup
else
  while :; do sleep 3600; done
fi
