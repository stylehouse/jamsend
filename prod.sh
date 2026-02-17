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



# Also update/create a 'prod' tag that always points to latest production
echo ""
echo "Step 8: Updating 'prod' tag to point to current deployment..."

# Delete old prod tag (local and remote)
if git show-ref --tags | grep -q "refs/tags/prod"; then
  git tag -d prod
fi
git push origin :refs/tags/prod 2>/dev/null || true
# Create and push the new prod tag
git tag -f prod "$COMMIT_AFTER"
git push -f origin prod

if [ $? -ne 0 ]; then
  echo "Warning: Failed to update 'prod' tag on origin."
else
  echo "✓ Updated 'prod' tag on origin"
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