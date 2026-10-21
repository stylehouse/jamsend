#!/bin/bash
set -e

# The stack watchdog: probes prod vite (page + relay upgrade), Caddy and the jamserve daemon each minute and
#  restarts whichever stops answering.  Policy + overrides live in jamsend-stack-watchdog.sh's header.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_NAME="jamsend-stack-watchdog.service"

install_unit() {
    local NAME="$1"
    local SOURCE="$SCRIPT_DIR/$NAME"
    local DEST="/etc/systemd/system/$NAME"

    if [ ! -f "$SOURCE" ]; then
        echo "Error: $SOURCE not found."
        exit 1
    fi

    echo "Deploying $NAME..."
    sudo cp "$SOURCE" "$DEST"
    sudo chown root:root "$DEST"
    sudo chmod 644 "$DEST"
}

for bin in curl flock docker; do
    command -v "$bin" >/dev/null || { echo "Error: $bin is needed on the host."; exit 1; }
done
chmod +x "$SCRIPT_DIR/jamsend-stack-watchdog.sh"

echo "Dry round first (nothing is restarted) — any ✗ line below is a probe failing right now:"
DRY=1 "$SCRIPT_DIR/jamsend-stack-watchdog.sh" || true

install_unit "$SERVICE_NAME"

echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Enabling service for boot..."
sudo systemctl enable "$SERVICE_NAME"

echo "Starting service..."
sudo systemctl restart "$SERVICE_NAME"

echo "Done! Watch it with: journalctl -u $SERVICE_NAME -f"
