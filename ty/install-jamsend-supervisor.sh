#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Build the watchdog container
echo "Building watchdog container..."
cd "$SCRIPT_DIR" && docker compose build

# 2. Deploy Systemd Units
install_unit() {
    local NAME="$1"
    local SOURCE="$SCRIPT_DIR/$NAME"
    local DEST="/etc/systemd/system/$NAME"

    echo "Deploying $NAME..."
    sudo cp "$SOURCE" "$DEST"
    sudo chown root:root "$DEST"
    sudo chmod 644 "$DEST"
}

install_unit "jamsend-launcher.service"
install_unit "jamsend-watchdog.service"

echo "Reloading systemd..."
sudo systemctl daemon-reload

# Launcher must be enabled first; watchdog depends on it
sudo systemctl enable jamsend-launcher.service
sudo systemctl enable jamsend-watchdog.service

echo "Starting services..."
sudo systemctl restart jamsend-launcher.service
sudo systemctl restart jamsend-watchdog.service

echo "Done! Monitor with:"
echo "  journalctl -u jamsend-launcher.service -f"
echo "  journalctl -u jamsend-watchdog.service -f"
