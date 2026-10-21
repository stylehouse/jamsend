#!/bin/bash
# tunnel VNC from the jamsend VM through an SSH jump host, then open a viewer
# x11vnc binds localhost-only inside the VM; nothing needs to be open on the jump host
JUMP="${1:?Usage: xvfb-viewer.sh <jump-host>}"

ssh -J "$JUMP" jamsend@192.168.122.100 -L 5910:localhost:5910 -N &
SSH_PID=$!
trap "kill $SSH_PID" EXIT
sleep 1
vncviewer localhost:5910