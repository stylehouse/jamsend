#!/bin/bash

CURRENT_DIR=$(basename "$PWD")
if [[ ! "$CURRENT_DIR" =~ ^prod- ]]; then
  echo "Error: This script must be run from a directory named 'prod-*'."
  echo "Current directory: $CURRENT_DIR"
  exit 1
fi

# pretend not to be prod while pulling changes
git checkout HEAD -- docker-compose.yml svelte.config.js
if [ $? -ne 0 ]; then
  echo "Warning: Could not reset one or both configuration files. Continuing, but please verify."
fi

# dev news
git pull

# become prod
cp docker-compose.prod.yml docker-compose.yml
cp svelte.config.prod.js svelte.config.js

# Build new Docker images and start the services.
# The '--build' flag ensures your images are rebuilt with the latest code and configurations.
# You might want to add '-d' here to run in detached mode for production.
echo "Building and starting Docker services..."
docker compose up --build -d
if [ $? -ne 0 ]; then
  echo "Error: Docker Compose failed to build or start services. Check logs for details."
  exit 1
fi

echo "Deployment complete! Production services should now be running."
