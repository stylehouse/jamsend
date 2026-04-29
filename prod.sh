#!/bin/bash

set -e  # Exit on any error

CURRENT_DIR=$(basename "$PWD")
if [[ ! "$CURRENT_DIR" =~ ^prod- ]]; then
  echo "Error: This script must be run from a directory named 'prod-*'."
  echo "Current directory: $CURRENT_DIR"
  exit 1
fi

echo "=== Production Deployment Script ==="
echo "Starting deployment in: $CURRENT_DIR"
echo ""

# ── Tunnel mode detection ─────────────────────────────────────────────────────
# leproxy/install.sh sets TUNNEL_MODE=true when a jump server is in use.
# We read it early so we know whether to strip services and build there/.
LEPROXY_DIR=~/src/leproxy
LEPROXY_ENV=${LEPROXY_DIR}/.env
TUNNEL_MODE=false
LEPROXY_PUBLIC_IP=""
LEPROXY_DUCKDNS_NAMES=""

if [[ -f "$LEPROXY_ENV" ]]; then
    TUNNEL_MODE=$(        grep '^TUNNEL_MODE='   "$LEPROXY_ENV" | cut -d= -f2 | tr -d '"' || echo "false")
    LEPROXY_PUBLIC_IP=$(  grep '^PUBLIC_IP='     "$LEPROXY_ENV" | cut -d= -f2 | tr -d '"' || echo "")
    LEPROXY_DUCKDNS_NAMES=$(grep '^DUCKDNS_NAMES=' "$LEPROXY_ENV" | cut -d= -f2 | tr -d '"' || echo "")
else
    echo "Warning: ${LEPROXY_ENV} not found. Assuming direct (non-tunnel) mode."
fi

# Pretend not to be prod while pulling changes
echo "Step 1: Resetting configuration files..."
git checkout HEAD -- docker-compose.yml svelte.config.js
if [ $? -ne 0 ]; then
  echo "Warning: Could not reset one or both configuration files. Continuing, but please verify."
fi

# Get current commit before pull for tagging later
COMMIT_BEFORE=$(git rev-parse HEAD)

# Pull dev news
echo ""
echo "Step 2: Pulling latest changes..."
git pull
if [ $? -ne 0 ]; then
  echo "Pull failed."
  exit 1
fi

# Get commit after pull
COMMIT_AFTER=$(git rev-parse HEAD)

# Become prod
echo ""
echo "Step 3: Applying production configuration..."
cp docker-compose.prod.yml docker-compose.yml
cp svelte.config.prod.js svelte.config.js
mkdir -p build

if [[ "${TUNNEL_MODE}" == "true" ]]; then
    echo "  Tunnel mode: stripping coturn and upnp-forwarder from docker-compose.yml"
    echo "  (those run on the jump server at ${LEPROXY_PUBLIC_IP})"

    # Remove service blocks for coturn and upnp-forwarder.
    # Each block: 2-space-indented service name, then all more-deeply-indented
    #   or blank lines, stopping before the next 2-space-indented key or top-level key.
    perl -0777 -i -pe '
      # Each block: service line, then any lines that are blank or start with whitespace
      s/\n  (?:upnp-forwarder|coturn):(?:\n(?:[ \t]+[^\n]*|))*//g;
      # Remove the external volume entry the same way
      s/\n  leproxy_caddy_data:(?:\n(?:[ \t]+[^\n]*|))*//g;
      # Remove volumes: if it ends up empty (nothing but optional whitespace after it)
      s/\nvolumes:\s*$//;
    ' docker-compose.yml
    # coturn was the only consumer of leproxy_caddy_data; remove that volume entry too
    perl -0777 -i -pe '
      s/\n  leproxy_caddy_data:\n    external: true\n//g
    ' docker-compose.yml
fi

# Build new Docker images and start the services
echo ""
echo "Step 4: Building and starting Docker services..."
docker compose up --build -d
if [ $? -ne 0 ]; then
  echo "Error: Docker Compose failed to build or start services. Check logs for details."
  exit 1
fi

# Wait a moment for services to stabilize
echo ""
echo "Step 5: Waiting for services to stabilize..."
sleep 5

# Check if services are actually running
echo ""
echo "Step 6: Verifying services..."
docker compose ps
if [ $? -ne 0 ]; then
  echo "Warning: Could not verify service status."
fi

# ── Jump server staging (tunnel mode only) ────────────────────────────────────
# leproxy/install.sh generated there/ with ssh-tunnel-destiny.
# We add coturn, extract TLS certs from the running leproxy Caddy, and rsync.
if [[ "${TUNNEL_MODE}" == "true" ]]; then
    echo ""
    echo "Step 6b: Staging jump server deployment (there/)..."

    if [[ ! -d "${LEPROXY_DIR}/there" ]]; then
        echo "Error: ${LEPROXY_DIR}/there not found. Run leproxy/install.sh first."
        exit 1
    fi

    mkdir -p there
    cp -r "${LEPROXY_DIR}/there/." there/
    echo "  Copied leproxy/there/ → ./there/"
    rm there/ssh_config

    # turnserver.conf lives in this repo; copy it into there/ for the jump server
    if [[ -f ty/turnserver.conf ]]; then
        cp ty/coturn-entrypoint.sh there/coturn-entrypoint.sh
        cp ty/turnserver.conf there/turnserver.conf
        echo "  Copied ty/turnserver.conf & coturn-entrypoint.sh → there"
    else
        echo "  Warning: ty/turnserver.conf not found. coturn on the jump server won't start."
    fi

    # ── Extract TLS certs from running leproxy Caddy ─────────────────────────
    # coturn on the jump server needs the domain cert for TURNS.
    # Caddy stores certs in its data volume; we pull them out and store base64
    #   in there/.env so the coturn entrypoint can decode them to files.
    # This is why prod.sh (not install.sh) does this: Caddy must already be up
    #   and have issued a cert. Re-run prod.sh if cert isn't ready yet.
    FIRST_DOMAIN=$(echo "$LEPROXY_DUCKDNS_NAMES" | cut -d, -f1)
    CERT_DIR="/data/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${FIRST_DOMAIN}.duckdns.org"

    echo "  Extracting TLS cert from leproxy Caddy for ${FIRST_DOMAIN}.duckdns.org..."
    pushd "$LEPROXY_DIR" > /dev/null

    if docker compose ps caddy 2>/dev/null | grep -q " Up "; then
        CERT_FILE="${CERT_DIR}/${FIRST_DOMAIN}.duckdns.org.crt"
        KEY_FILE="${CERT_DIR}/${FIRST_DOMAIN}.duckdns.org.key"
        if docker compose exec -T caddy test -f "$CERT_FILE" 2>/dev/null; then
            TLS_CERT=$(docker compose exec -T caddy cat "$CERT_FILE")
            TLS_KEY=$( docker compose exec -T caddy cat "$KEY_FILE")
            # PEM files contain newlines; store as single base64 lines in .env
            {
                printf 'TLS_CERT="%s"\n' "$(echo "$TLS_CERT" | base64 -w0)"
                printf 'TLS_KEY="%s"\n'  "$(echo "$TLS_KEY"  | base64 -w0)"
            } >> "${OLDPWD}/there/.env"
            echo "  TLS cert/key exported to there/.env."
        else
            echo "  Warning: cert not yet issued at ${CERT_FILE}"
            echo "  coturn will start without TLS. Re-run prod.sh after Caddy issues the cert."
        fi
    else
        echo "  Warning: leproxy Caddy is not running. Start it with: cd ${LEPROXY_DIR} && docker compose up -d"
        echo "  coturn will start without TLS. Re-run prod.sh after Caddy is up."
    fi

    popd > /dev/null

    # Append coturn to there/docker-compose.yml.
    # TLS_CERT/TLS_KEY come from there/.env (written above).
    # network_mode: host lets coturn bind the full UDP relay range without NAT.
    # entrypoint decodes certs from env, patches external-ip, then starts turnserver.
    cat >> there/docker-compose.yml << 'COTURN_EOF'

  # TURN/STUN for WebRTC NAT traversal. Runs on the jump server with
  #   network_mode: host to bind the full UDP relay range without Docker NAT.
  # TLS_CERT / TLS_KEY: base64-encoded PEM blobs from there/.env,
  #   extracted from leproxy's running Caddy by prod.sh.
  coturn:
    image: coturn/coturn:latest
    build:
      context: .
      dockerfile_inline: |
        FROM coturn/coturn:latest
        USER root
        RUN apt-get update -qq && apt-get install -y -qq curl iproute2
        COPY coturn-entrypoint.sh /entrypoint.sh
        RUN chmod +x /entrypoint.sh
        ENTRYPOINT ["/entrypoint.sh"]
    container_name: jamsend-prod-coturn
    user: "0:0"
    network_mode: host
    volumes:
      - ./turnserver.conf:/etc/coturn/turnserver.conf:ro
    environment:
      - TLS_CERT=${TLS_CERT}
      - TLS_KEY=${TLS_KEY}
    restart: always
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 128M
COTURN_EOF

    echo "  Appended coturn to there/docker-compose.yml."
fi

# Tag the commit in the origin repo
echo ""
echo "Step 7: Tagging deployment in origin repository..."

# Generate timestamp for unique tag
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
TAG_NAME="prod-${TIMESTAMP}"

# Create and push the tag
git tag -a "$TAG_NAME" "$COMMIT_AFTER" -m "Production deployment on ${TIMESTAMP}"
if [ $? -ne 0 ]; then
  echo "Warning: Failed to create tag locally."
else
  echo "Created local tag: $TAG_NAME"
  
  # Push the tag to origin
  git push origin "$TAG_NAME"
  if [ $? -ne 0 ]; then
    echo "Warning: Failed to push tag to origin. Tag exists locally but not on remote."
  else
    echo "✓ Tag pushed to origin: $TAG_NAME"
  fi
fi



echo ""
echo "=== Deployment Complete ==="
echo "✓ Services are running"
echo "✓ Deployed commit: $COMMIT_AFTER"
echo "✓ Tagged as: $TAG_NAME"
echo "✓ 'prod' tag updated"
echo ""
echo "To view logs: docker compose logs -f"
echo "To stop services: docker compose down"

if [[ "${TUNNEL_MODE}" == "true" ]]; then
    echo ""
    echo "=== Jump Server (${LEPROXY_PUBLIC_IP}) ==="
    echo "Deploy there/ with:"
    echo "  rsync -av --delete there/ c:leproxy/"
    echo "  ssh c 'cd leproxy && docker compose up -d --build'"
fi
