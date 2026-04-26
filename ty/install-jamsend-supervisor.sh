#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Build the watchdog container
echo "Building watchdog container..."
cd "$SCRIPT_DIR" && docker compose build

# 2. Deploy Systemd Unit
install_unit() {
    local NAME="$1"
    local SOURCE="$SCRIPT_DIR/$NAME"
    local DEST="/etc/systemd/system/$NAME"

    echo "Deploying $NAME..."
    sudo cp "$SOURCE" "$DEST"
    sudo chown root:root "$DEST"
    sudo chmod 644 "$DEST"
}

install_unit "jamsend-droids.service"

echo "Reloading systemd..."
sudo systemctl daemon-reload
sudo systemctl enable jamsend-droids.service

echo "Starting service..."
sudo systemctl restart jamsend-droids.service

echo "Done! Monitor with: journalctl -u jamsend-droids.service -f"