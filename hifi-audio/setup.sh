#!/bin/sh
# setup.sh — make the desktop audio fix PERMANENT (survives reboot).
#
# Two facts this encodes, both proven on w 2026-09-16:
#   · the stutter was the graph quantum being pulled down to 256 (5.8 ms) — this
#     box can't make that deadline. 2048 with a floor of 1024 fixed it.
#   · s32le IS 24-bit on the Envy24 (24 bits in a 32-bit slot); the graph follows
#     the source rate (44.1k files play at 44.1k, lossless), 96k is the ceiling.
# `~/bin/destutter` did the quantum part with pw-metadata, which is RUNTIME-ONLY
#  and evaporated on every reboot — that is why it "kept coming back".
#
#   sh setup.sh        # deploy + restart + verify
#   sh setup.sh 48     # same, but a 48k ceiling instead of 96k
D="$HOME/.config/pipewire/pipewire.conf.d"
mkdir -p "$D"
RATE=96000; [ "$1" = "48" ] && RATE=48000
rm -f "$D/10-hifi-96k.conf"                      # the old name, superseded

cat > "$D/10-hifi-rate.conf" <<CONF
# hifi-audio/setup.sh — rate ceiling $RATE; graph follows the source rate within these
context.properties = {
    default.clock.rate          = $RATE
    default.clock.allowed-rates = [ 44100 48000 96000 ]
}
CONF

cat > "$D/20-quantum.conf" <<'CONF'
# hifi-audio/setup.sh — THE fix. min-quantum stops clients (pavucontrol meters,
#  low-latency apps) dragging the whole graph down to a buffer this box can't meet.
context.properties = {
    default.clock.quantum     = 2048
    default.clock.min-quantum = 1024
    default.clock.max-quantum = 2048
}
CONF

echo "deployed:"; ls -1 "$D"/10-hifi-rate.conf "$D"/20-quantum.conf
echo "restarting pipewire..."
systemctl --user restart wireplumber pipewire pipewire-pulse
sleep 2
exec sh "$(dirname "$0")/check.sh"
