#!/bin/sh
set -e
echo "$TLS_CERT" | base64 -d > /etc/ssl/coturn.crt
echo "$TLS_KEY"  | base64 -d > /etc/ssl/coturn.key
chmod 600 /etc/ssl/coturn.key

PUBLIC_IP=$(curl -s -4 ifconfig.me)

sed \
    -e "s|^external-ip=$|external-ip=${PUBLIC_IP}|" \
    -e "s|^relay-ip=.*|relay-ip=${PUBLIC_IP}|" \
    /etc/coturn/turnserver.conf > /tmp/turnserver.conf

exec turnserver -c /tmp/turnserver.conf --log-file stdout --no-stdout-log