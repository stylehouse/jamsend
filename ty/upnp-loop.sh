#!/bin/sh
# upnp-loop.sh - Refresh UPnP port forwarding every hour

echo "UPnP port forwarder started"

# Exit immediately if a forward fails
forward_port() {
    proto=$1
    port=$2
    upnpc -r $port $proto
    if [ $? -ne 0 ]; then
        echo "$(date): FAILED to forward $proto $port — bailing"
        exit 1
    fi
}

forward_ports() {
    echo "$(date): Starting UPnP port forwards"

    # PeerJS signaling
    forward_port TCP 9999

    # CoTURN main STUN/TURN ports
    forward_port UDP 3478
    forward_port TCP 3478

    # CoTURN TURNS (TLS)
    forward_port TCP 5349

    # CoTURN relay port range — one per concurrent TURN session
    for port in $(seq 49152 49182); do
        forward_port UDP $port
    done

    echo "$(date): UPnP forwards completed"
}

# Run immediately on startup
forward_ports

# Then run every hour
while true; do
    sleep 3600
    forward_ports
done