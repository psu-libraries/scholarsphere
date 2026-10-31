#!/bin/bash
# Fresh Docker Setup Script for Scholarsphere
# This script handles all the necessary steps to set up a clean Docker environment
# Usage: ./bin/setup-docker-fresh.sh

set -e

echo "🐳 Scholarsphere Docker Fresh Setup"
echo "===================================="
echo ""

# Step 1: Source environment variables
echo "Step 1: Setting up Docker environment..."
source ./docker-env.sh
echo ""

# Step 2: Stop and remove old containers
echo "Step 2: Stopping old containers..."
docker-compose down -v 2>/dev/null || true
echo "✓ Old containers removed"
echo ""

# Step 3: Fix Solr volume permissions (critical for Linux)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  echo "Step 3: Fixing Solr volume permissions (Linux)..."
  SOLR_VOLUME="/var/lib/docker/volumes/scholarsphere_solr-data/_data"
  
  # Check if volume exists and needs fixing
  if [ -d "$SOLR_VOLUME" ]; then
    echo "  Solr volume found at: $SOLR_VOLUME"
    if ! sudo test -w "$SOLR_VOLUME" 2>/dev/null; then
      echo "  Fixing permissions with: sudo chmod -R 777 $SOLR_VOLUME"
      sudo chmod -R 777 "$SOLR_VOLUME" || {
        echo "  ✗ Failed to fix permissions. Please run manually:"
        echo "    sudo chmod -R 777 $SOLR_VOLUME"
        exit 1
      }
      echo "  ✓ Permissions fixed"
    else
      echo "  ✓ Permissions already correct"
    fi
  else
    echo "  (Volume will be created on first startup)"
  fi
else
  echo "Step 3: Skipping Solr volume permissions fix (macOS/Windows)"
fi
echo ""

# Step 4: Start containers
echo "Step 4: Starting Docker containers (this may take 2-3 minutes)..."
docker-compose up -d --build
echo "✓ Containers started"
echo ""

# Step 5: Wait for Solr to become healthy
echo "Step 5: Waiting for Solr to initialize (up to 120 seconds)..."
for i in {1..24}; do
  if docker-compose ps | grep -q "scholarsphere-solr-1.*healthy"; then
    echo "✓ Solr is healthy"
    break
  fi
  echo "  Waiting... ($i/24)"
  sleep 5
done

if ! docker-compose ps | grep -q "scholarsphere-solr-1.*healthy"; then
  echo "✗ Solr did not become healthy within timeout"
  echo "  Run: docker-compose logs solr"
  exit 1
fi
echo ""

# Step 6: Initialize database
echo "Step 6: Initializing database..."
docker-compose exec -T web bash -lc "cd /app && bundle exec rails db:create db:migrate" || {
  echo "✗ Database initialization failed"
  exit 1
}
echo "✓ Database initialized"
echo ""

# Step 7: Initialize Solr
echo "Step 7: Initializing Solr collections..."
docker-compose exec -T web bash -lc "cd /app && bundle exec rake solr:init" || {
  echo "✗ Solr initialization failed"
  exit 1
}
echo "✓ Solr collections initialized"
echo ""

# Step 8: Verify setup
echo "Step 8: Verifying setup..."
echo "Container status:"
docker-compose ps
echo ""
echo "Testing Solr health check:"
curl -fsS -u scholarsphere:scholarsphere "http://localhost:8983/solr/admin/collections?action=LIST&wt=json" | head -c 200 && echo ""
echo ""

echo "✅ Setup complete!"
echo ""
echo "Ready to run tests:"
echo "  docker-compose exec -T web bash -lc 'cd /app && RAILS_ENV=test bundle exec rspec'"
echo ""
echo "Or run full test suite and save to log:"
echo "  docker-compose exec -T web bash -lc 'cd /app && RAILS_ENV=test bundle exec rspec > rspec-tests.log'"
