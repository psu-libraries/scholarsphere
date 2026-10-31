#!/bin/bash
# Docker Environment Setup Script
# Source this file to set up Docker user permissions: source ./docker-env.sh

# Get current user's UID and GID
CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)
CURRENT_USER_ID="${CURRENT_UID}:${CURRENT_GID}"

# Export for docker-compose to use
export CURRENT_USER_ID

echo "✓ Docker user configured: $CURRENT_USER_ID"
echo "  Docker containers will run as your current user ($(id -un):$(id -gn))"

# Check if we need to fix Solr volume permissions on Linux
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  SOLR_VOLUME_PATH="/var/lib/docker/volumes/scholarsphere_solr-data/_data"
  if [ -d "$SOLR_VOLUME_PATH" ]; then
    if ! sudo test -w "$SOLR_VOLUME_PATH" 2>/dev/null; then
      echo ""
      echo "⚠️  WARNING: Solr volume is not writable by the solr container."
      echo "   To fix this, run:"
      echo "   sudo chmod -R 777 /var/lib/docker/volumes/scholarsphere_solr-data/_data"
      echo ""
    fi
  fi
fi
echo ""
echo "You can now run:"
echo "  docker-compose build web"
echo "  docker-compose up -d"
echo "  docker-compose exec -T web bash"
