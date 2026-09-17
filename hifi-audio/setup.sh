#!/bin/sh
# setup.sh — make the desktop audio fix PERMANENT (survives reboot).
#
# What this encodes, proven on w 2026-09-16/17:
#   · the stutter was the graph quantum sitting at 256-512 — this box can't make
#     that deadline with EasyEffects/Strawberry's own low-latency requests in the
#     graph. min/max-quantum ALONE did not hold that floor against those requests
#     (confirmed live: quantum stayed at 512 with min-quantum=1024 set) — only
#     `force-quantum` actually pins it, which is what the live pw-metadata test
#     that first proved the fix used. This conf now sets force, not just a floor.
#   · s32le IS 24-bit on the Envy24 (24 bits in a 32-bit slot). Left unforced, the
#     graph follows the source rate (44.1k files play at 44.1k, lossless) — fine,
#     but every rate-differing track then triggers a hardware reopen, a plausible
#     source of a click/gap at track boundaries. force-rate pins ONE rate always
#     (everything gets resampled to it — small constant CPU cost, zero rate-switch
#     hiccups). Owner chose forced 96000 over "follows source" 2026-09-17.
# `~/bin/destutter` did the quantum part with pw-metadata, which is RUNTIME-ONLY
#  and evaporated on every reboot — that is why it "kept coming back".
#
#   sh setup.sh        # deploy + restart + verify — force 2048 quantum, force 96000 rate
#   sh setup.sh 48     # same, but force 48000 instead of 96000
D="$HOME/.config/pipewire/pipewire.conf.d"
mkdir -p "$D"
RATE=96000; [ "$1" = "48" ] && RATE=48000
rm -f "$D/10-hifi-96k.conf"                      # the old name, superseded

cat > "$D/10-hifi-rate.conf" <<CONF
# hifi-audio/setup.sh — FORCE the clock to $RATE always (not just a ceiling): every
#  stream gets resampled to this one rate, so no track ever triggers a hardware
#  rate switch (and the click/gap that can come with one).
context.properties = {
    default.clock.rate          = $RATE
    default.clock.force-rate    = $RATE
    default.clock.allowed-rates = [ $RATE ]
}
CONF

cat > "$D/20-quantum.conf" <<'CONF'
# hifi-audio/setup.sh — THE fix. force-quantum PINS the buffer so no client
#  (pavucontrol meters, a low-latency stream request) can drag the graph down to
#  a size this box can't meet. min/max alone did not hold on this box — proven
#  2026-09-17: quantum sat at 512 with min-quantum=1024 configured and no force.
context.properties = {
    default.clock.quantum       = 2048
    default.clock.min-quantum   = 1024
    default.clock.max-quantum   = 2048
    default.clock.force-quantum = 2048
}
CONF

echo "deployed:"; ls -1 "$D"/10-hifi-rate.conf "$D"/20-quantum.conf
echo "restarting pipewire..."
systemctl --user restart wireplumber pipewire pipewire-pulse
sleep 2
exec sh "$(dirname "$0")/check.sh"
