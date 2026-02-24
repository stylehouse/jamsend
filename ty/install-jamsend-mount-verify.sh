#!/bin/sh
user=$(id -u)
group=$(id -g)
SERVICE_NAME="jamsend-mount-verify.service"
SOURCE_SERVICE="ty/$SERVICE_NAME"

sudo mkdir -p /mnt/jamsend-music
sudo mkdir -p /mnt/jamsend-appcache

sudo chown $user:$group /mnt/jamsend-music
sudo chown $user:$group /mnt/jamsend-appcache

echo "--- Installing Systemd Service ---"
if [ -f "$SOURCE_SERVICE" ]; then
    sudo cp "$SOURCE_SERVICE" "/etc/systemd/system/$SERVICE_NAME"
    sudo chmod 644 "/etc/systemd/system/$SERVICE_NAME"
    
    sudo systemctl daemon-reload
    sudo systemctl enable "$SERVICE_NAME"
    echo "Service $SERVICE_NAME installed and enabled."
    
    echo "Starting service (will loop if /mnt/music is empty)..."
    sudo systemctl start "$SERVICE_NAME"
else
    echo "Error: $SOURCE_SERVICE not found!"
    exit 1
fi

echo "--- Deployment Complete ---"
