#!/bin/sh
SERVICE_NAME="jamsend-dev-ssh-tunnel.service"
SOURCE_SERVICE="$SERVICE_NAME"

echo "--- Installing SSH Tunnel User Service ---"
if [ -f "$SOURCE_SERVICE" ]; then
    mkdir -p ~/.config/systemd/user/
    cp "$SOURCE_SERVICE" ~/.config/systemd/user/$SERVICE_NAME
    chmod 644 ~/.config/systemd/user/$SERVICE_NAME

    systemctl --user daemon-reload
    systemctl --user enable "$SERVICE_NAME"
    echo "Service $SERVICE_NAME installed and enabled."

    # Allow service to survive logout (start at boot without an active session)
    sudo loginctl enable-linger $(id -u)

    echo "Starting service..."
    systemctl --user start "$SERVICE_NAME"
else
    echo "Error: $SOURCE_SERVICE not found!"
    exit 1
fi

echo "--- Deployment Complete ---"
echo "Watch with: journalctl --user -fu $SERVICE_NAME"
