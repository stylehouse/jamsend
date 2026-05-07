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

# Required for -R tunnels to bind to specific addresses (not just 127.0.0.1)
if ! sudo grep -q "^GatewayPorts clientspecified" /etc/ssh/sshd_config; then
    echo "Configuring sshd: GatewayPorts clientspecified..."
    echo "GatewayPorts clientspecified" | sudo tee -a /etc/ssh/sshd_config
    sudo systemctl restart sshd
else
    echo "sshd GatewayPorts already configured."
fi

install_unit "jamsend-prod.service"

echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Enabling service for boot..."
sudo systemctl enable jamsend-prod.service

echo "Starting service..."
sudo systemctl restart jamsend-prod.service

echo "Done! Check progress with: journalctl -u jamsend-prod.service -f"
