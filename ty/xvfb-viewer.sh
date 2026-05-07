#!/bin/bash
# tunnel to the jamsend Xvfb VNC on the remote host, then open a viewer
HOST="${1:?Usage: xvfb-viewer.sh <ssh-host>}"
ssh -L 5910:localhost:5910 "$HOST" -N &
SSH_PID=$!
trap "kill $SSH_PID" EXIT
sleep 1
vncviewer localhost:5910