#!/bin/bash

# Configuration
DEST_PATH="/usr/local/bin/chrome-limit.sh"
SERVICE_PATH="/etc/systemd/system/chrome-limit.service"
# for a 32G machine
MEM_THRESHOLD=21

# 1. INSTALLATION LOGIC
if [[ "$0" != "$DEST_PATH" ]]; then
    echo "--- Chrome Memory Limit Installer ---"
    read -p "Would you like to install this script as a systemd service? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        
        echo "Copying script to $DEST_PATH..."
        sudo cp "$0" "$DEST_PATH"
        sudo chmod +x "$DEST_PATH"

        echo "Creating systemd unit at $SERVICE_PATH..."
        sudo bash -c "cat <<EOF > $SERVICE_PATH
[Unit]
Description=Kill Chrome processes over $MEM_THRESHOLD%% memory
After=network.target

[Service]
Type=simple
ExecStart=$DEST_PATH
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF"

        echo "Reloading systemd and starting service..."
        sudo systemctl daemon-reload
        sudo systemctl enable --now chrome-limit.service

        echo "Done! Chrome is now capped at $MEM_THRESHOLD% memory per process."
        echo "Check status with: systemctl status chrome-limit.service"
        exit 0
    else
        echo "Installation cancelled. Running in one-off mode..."
    fi
fi

# 2. MONITORING LOOP
echo "Monitoring Chrome processes... (Threshold: $MEM_THRESHOLD%)"
while true; do
  # Find PIDs of 'chrome' processes where column 4 (%MEM) > threshold
  BAD_PIDS=$(ps aux | grep -i chrome | awk -v limit="$MEM_THRESHOLD" '$4 > limit {print $2}')
  
  for PID in $BAD_PIDS; do
    # Verify the PID still exists before killing
    if ps -p "$PID" > /dev/null; then
       echo "[$(date)] Killing rogue Chrome process $PID (exceeded $MEM_THRESHOLD% MEM)"
       kill -9 "$PID"
    fi
  done
  sleep 5
done
