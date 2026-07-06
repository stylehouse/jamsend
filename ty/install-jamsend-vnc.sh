#!/bin/sh
# install-jamsend-vnc.sh — the SIMPLE chrome-appserver path.
#  Serve the real logged-in desktop (:0) over x11vnc so a human can VNC in and grant FSA by hand
#   occasionally; no Xvfb, no watchdog, no KVM snapshot. Installs jamsend-vnc.service and RETIRES
#    the old headless three-part stack (jamsend-xvfb + jamsend-wm + jamsend-x11vnc on :10) on THIS
#     host. (The KVM path in install-jamsend-virt.sh ships its own copies of those units inside the
#      VM — this only clears them off the bare host.)  See README.md "## simply".

SERVICE_NAME="jamsend-vnc.service"
SOURCE_SERVICE="$SERVICE_NAME"
OLD="jamsend-xvfb.service jamsend-wm.service jamsend-x11vnc.service"

if [ ! -f "$SOURCE_SERVICE" ]; then
    echo "Error: $SOURCE_SERVICE not found — run this from the ty/ directory."
    exit 1
fi

echo "--- Retiring the old headless :10 stack on this host ---"
for s in $OLD; do
    if [ -e "/etc/systemd/system/$s" ]; then
        sudo systemctl disable --now "$s" 2>/dev/null || true
        sudo rm -f "/etc/systemd/system/$s"
        echo "retired $s"
    fi
done

echo "--- Installing $SERVICE_NAME ---"
sudo cp "$SOURCE_SERVICE" "/etc/systemd/system/$SERVICE_NAME"
sudo chmod 644 "/etc/systemd/system/$SERVICE_NAME"
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl start "$SERVICE_NAME"

echo "--- Done. x11vnc is serving :0 on 127.0.0.1:5900 (loopback only) ---"
echo "View it from your machine:   ty/desktop-viewer.sh <ssh-host>"
echo "If it didn't come up, -auth guess may have fired before the display manager settled —"
echo " check the status and swap in the explicit cookie path (see the .service comment):"
echo "   sudo systemctl status $SERVICE_NAME"
