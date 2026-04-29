#!/bin/sh
set -e
echo "$TLS_CERT" | base64 -d > /etc/ssl/coturn.crt
echo "$TLS_KEY"  | base64 -d > /etc/ssl/coturn.key
chmod 600 /etc/ssl/coturn.key

PUBLIC_IP=$(curl -s -4 ifconfig.me)
# relay-ip must be a local interface address, not the public floating IP
LOCAL_IP=$(ip route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if ($i=="src") print $(i+1)}')

sed \
    -e "s|^external-ip=$|external-ip=${PUBLIC_IP}|" \
    -e "s|^relay-ip=.*|relay-ip=${LOCAL_IP}|" \
    /etc/coturn/turnserver.conf > /tmp/turnserver.conf

exec turnserver -c /tmp/turnserver.conf --log-file stdout --no-stdout-log