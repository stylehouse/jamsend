#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

install_unit "jamsend-droids.service"
install_unit "jamsend-droids-restart.service"
install_unit "jamsend-droids-restart.timer"

echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Enabling service for boot..."
sudo systemctl enable jamsend-droids.service

echo "Enabling and starting restart timer (fires at :00, :20, :40)..."
sudo systemctl enable --now jamsend-droids-restart.timer

echo "Starting service..."
sudo systemctl restart jamsend-droids.service

echo "Done!"
echo "Check service:  journalctl -u jamsend-droids.service -f"
echo "Check timer:    systemctl status jamsend-droids-restart.timer"
echo "Next fire:      systemd-analyze calendar '*:0/20'"