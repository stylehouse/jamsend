#!/bin/sh
set -e
echo "$TLS_CERT" | base64 -d > /etc/ssl/coturn.crt
echo "$TLS_KEY"  | base64 -d > /etc/ssl/coturn.key
chmod 600 /etc/ssl/coturn.key
sed "s|^external-ip=$|external-ip=$(curl -s -4 ifconfig.me)|" \
    /etc/coturn/turnserver.conf > /tmp/turnserver.conf
exec turnserver -c /tmp/turnserver.conf --log-file stdout --no-stdout-log