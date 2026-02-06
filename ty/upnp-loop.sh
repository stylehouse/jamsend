#!/bin/sh
# upnp-loop.sh - Refresh UPnP port forwarding every hour

echo "UPnP port forwarder started"

# Run immediately on startup
echo "$(date): Starting UPnP port forward for port 9999 TCP"
upnpc -r 9999 TCP
echo "$(date): Initial UPnP command completed with exit code: $?"

# Then run every hour (no cron)
while true; do
    sleep 3600
    echo "$(date): Starting UPnP port forward for port 9999 TCP"
    upnpc -r 9999 TCP
    echo "$(date): UPnP command completed with exit code: $?"
done