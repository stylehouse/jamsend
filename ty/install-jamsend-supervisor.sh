#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Install system dependencies
echo "Installing system dependencies..."
sudo apt install -y python3-psutil xvfb x11vnc

# 2. Build the watchdog container
echo "Building watchdog container..."
cd "$SCRIPT_DIR" && docker compose build

# 3. Deploy systemd units
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
install_unit "jamsend-xvfb.service"
install_unit "jamsend-x11vnc.service"

echo "Reloading systemd..."
sudo systemctl daemon-reload

# xvfb              provides a DISPLAY=:10 to:
#  → x11vnc                  remote viewing
#  → launcher → watchdog       restarting
sudo systemctl enable jamsend-xvfb.service
sudo systemctl enable jamsend-x11vnc.service
sudo systemctl enable jamsend-launcher.service
sudo systemctl enable jamsend-watchdog.service

echo "Starting services..."
sudo systemctl restart jamsend-xvfb.service
sudo systemctl restart jamsend-x11vnc.service
sudo systemctl restart jamsend-launcher.service
sudo systemctl restart jamsend-watchdog.service

echo "Done. Monitor with:"
echo "  journalctl -u jamsend-xvfb.service -f"
echo "  journalctl -u jamsend-x11vnc.service -f"
echo "  journalctl -u jamsend-launcher.service -f"
echo "  journalctl -u jamsend-watchdog.service -f"
