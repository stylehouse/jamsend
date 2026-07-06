#!/bin/bash
# tunnel to an x11vnc serving the REAL desktop (display :0) on the remote host, then open a viewer.
# Sibling of xvfb-viewer.sh (which targets the headless Xvfb :10 on 5910). Use THIS one to grant
#  FSA: the native "open share" file picker actually behaves on a real desktop, which has the dbus
#   session + xdg-desktop-portal backend + window focus that the bare Xvfb :10 lacks (there the
#    picker just flickers and throws AbortError).
#
# PREREQ on the remote — an x11vnc bound to :0 on 5900. One-off:
#   x11vnc -display :0 -auth guess -localhost -nopw -forever -rfbport 5900 &
#  (confirm the real display is :0 with `ls /tmp/.X11-unix/`; adjust -display / port if not.)
HOST="${1:?Usage: desktop-viewer.sh <ssh-host>}"
ssh -L 5900:localhost:5900 "$HOST" -N &
SSH_PID=$!
trap "kill $SSH_PID" EXIT
sleep 1
# LAN tuning: bandwidth is plentiful, CPU/latency is the bottleneck — so spend bytes to save both.
#  Low compression, high JPEG quality, tight+copyrect encoding. These are TightVNC Viewer (1.3.x)
#   flags — what's installed here. (TigerVNC differs: -PreferredEncoding Tight -CompressLevel 1
#    -QualityLevel 9.) Run with NOVNCOPTS=1 to pass none (e.g. a viewer that rejects these).
if [ -n "$NOVNCOPTS" ]; then
    vncviewer localhost:5900
else
    vncviewer -encodings "tight copyrect" -compresslevel 1 -quality 9 localhost:5900
fi
