#!/bin/sh
# upnp-loop.sh - Refresh UPnP port forwarding every hour

echo "UPnP port forwarder started"

forward_ports() {
    echo "$(date): Starting UPnP port forwards"
    
    # PeerJS port
    upnpc -r 9999 TCP
    echo "Port 9999 TCP: exit code $?"
    
    # CoTURN STUN/TURN
    upnpc -r 3478 UDP
    echo "Port 3478 UDP: exit code $?"
    
    upnpc -r 3478 TCP
    echo "Port 3478 TCP: exit code $?"
    
    # CoTURN TLS (optional)
    upnpc -r 5349 TCP
    echo "Port 5349 TCP: exit code $?"
    
    echo "$(date): UPnP forwards completed"
}

# Run immediately on startup
forward_ports

# Then run every hour
while true; do
    sleep 3600
    forward_ports
done