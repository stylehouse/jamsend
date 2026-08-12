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

# NOTHING IS STRIPPED HERE ANY MORE (2026-08-12).  This block used to remove coturn,
#  upnp-forwarder and the leproxy_caddy_data volume in tunnel mode.  coturn is gone
#   (TURN abandoned), and the router forwarding moved to leproxy, which owns the public
#    ports and already branches on TUNNEL_MODE when it generates its own compose.  So
#     prod.sh no longer edits the compose it just copied, and no longer needs to know
#      what the front door looks like.

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
# We copy it beside the app and hand back the rsync line; the jump server holds nothing else.
# COTURN IS GONE (2026-08-12): TURN is abandoned, the transport is the websocket relay.
#  What used to live here — copying ty/turnserver.conf into there/, lifting the TLS cert
#   out of leproxy's RUNNING Caddy into there/.env, and appending a coturn service to
#    there/docker-compose.yml — is removed with it.  That is also why prod.sh no longer
#     needs Caddy to be up before it can finish, and why LEPROXY_DUCKDNS_NAMES (read at
#      the top only to build the cert path) is now unused.
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
