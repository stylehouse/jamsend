#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Install system dependencies
echo "Installing system dependencies..."
sudo apt install -y python3-psutil

# 2. Build the watchdog container
echo "Building watchdog container..."
cd "$SCRIPT_DIR" && docker compose build

# 3. Deploy Systemd Units
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
