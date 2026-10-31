# Linux Development Setup Guide for Scholarsphere

This guide covers setting up the Scholarsphere Rails application for development on Linux (including Fedora/RHEL with SELinux).

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Understanding docker-env.sh](#understanding-docker-envsh)
4. [Solr 9 Configuration](#solr-9-configuration)
5. [Troubleshooting](#troubleshooting)
6. [Testing](#testing)

---

## Prerequisites

### Required Tools

- **Docker**: 20.10 or later
- **Docker Compose**: 1.29 or later
- **Git**: Any recent version
- **Bash**: 4.0+ (for scripts)

### Verify Installation

```bash
docker --version
docker-compose --version
git --version
```

### Linux-Specific Requirements

#### For Fedora/RHEL with SELinux

If you have SELinux enabled (default on Fedora/RHEL):

```bash
# Check if SELinux is enabled
getenforce

# If output is "Enforcing" or "Permissive", you need the SELinux-aware bind mount configuration
# This is handled automatically by docker-compose.yml when CURRENT_USER_ID is set
```

#### Docker Daemon Requirements

Ensure your user can run Docker without `sudo`:

```bash
# Add your user to the docker group
sudo usermod -aG docker $USER

# Apply the new group membership (choose ONE):
newgrp docker                    # Start a new shell with the group
# OR
# Log out and log back in
```

Verify:
```bash
docker ps  # Should not require sudo
```

---

## Quick Start

### 1. Set Up Docker User Permissions

Source the provided setup script:

```bash
source ./docker-env.sh
```

This script:
- ✅ Exports `CURRENT_USER_ID` (your UID:GID) for Docker containers
- ✅ Prevents permission issues when running containers as your user
- ✅ Checks Solr volume permissions on Linux
- ✅ Warns about SELinux-related issues if needed

**What it does:**
```bash
CURRENT_UID=$(id -u)           # Get your user ID
CURRENT_GID=$(id -g)           # Get your group ID
export CURRENT_USER_ID         # Export for docker-compose
```

### 2. Verify the Configuration

After sourcing `docker-env.sh`, you should see:

```
✓ Docker user configured: 1000:1000
  Docker containers will run as your current user (username:groupname)
```

### 3. Build and Start Containers

```bash
# Stop any existing containers
docker-compose down

# Build the web container (includes Ruby dependencies)
docker-compose build web

# Start all services (PostgreSQL, Redis, Solr, SeaweedFS, Web)
docker-compose up -d

# Verify services are running
docker-compose ps
```

Expected output:
```
NAME                COMMAND                  SERVICE      STATUS
scholarsphere-db-1          postgres            db           Up
scholarsphere-redis-1       redis               redis        Up
scholarsphere-seaweedfs-1   seaweedfs           seaweedfs    Up
scholarsphere-solr-1        solr                solr         Up
scholarsphere-web-1         rails server        web          Up (health: starting)
```

### 4. Initialize the Database

```bash
# Create database and run migrations
docker-compose exec -T web bash -c "cd /app && bundle exec rails db:create db:migrate"

# Initialize Solr collections
docker-compose exec -T web bash -c "cd /app && bundle exec rake solr:init"
```

### 5. Start the Development Server

```bash
# Open a shell in the web container
docker-compose exec web bash

# Inside the container:
cd /app
bundle exec rails server -b 0.0.0.0
```

Access the application at: **http://localhost:3000**

---

## Understanding docker-env.sh

### Why It's Needed on Linux

By default, Docker containers run as a specific user (UID/GID 1000:1000). This can cause permission problems:

- ❌ Files created in containers appear as "nobody" on your host
- ❌ You can't edit files that the container created
- ❌ Firefox profile directories cause permission errors
- ❌ Bundler can't write to shared volumes

### What docker-env.sh Does

```bash
#!/bin/bash
CURRENT_UID=$(id -u)           # Your user ID (e.g., 1000)
CURRENT_GID=$(id -g)           # Your group ID (e.g., 1000)
CURRENT_USER_ID="${CURRENT_UID}:${CURRENT_GID}"
export CURRENT_USER_ID         # Make available to docker-compose
```

### How Docker Compose Uses It

In `docker-compose.yml`:

```yaml
services:
  web:
    user: ${CURRENT_USER_ID:-1000:1000}  # Run as your UID:GID if set, else default
    volumes:
      - ./:/app
```

**Result:** The container runs as YOU, not as a different user.

### Permanent Setup (Optional)

If you always want `CURRENT_USER_ID` set, add to your shell config:

**For Bash** (`~/.bashrc`):
```bash
export CURRENT_USER_ID=$(id -u):$(id -g)
```

**For Zsh** (`~/.zshrc`):
```bash
export CURRENT_USER_ID=$(id -u):$(id -g)
```

Then restart your terminal:
```bash
exec zsh  # or exec bash
```

---

## Solr 9 Configuration

Scholarsphere uses **Solr 9.11.0** with specific memory and security settings.

### Default Configuration

The `docker-compose.yml` includes:

```yaml
solr:
  image: solr:9.11.0
  environment:
    SOLR_HEAP: 4g              # Heap size for JVM
    SOLR_JAVA_MEM: "-Xms3g -Xmx4g"  # Min/Max memory
    SOLR_MODULES: analysis-extras
    SOLR_OPTS: "-Dsolr.config.lib.enabled=true"
    SOLR_USERNAME: scholarsphere
    SOLR_PASSWORD: scholarsphere
```

### Why 4GB Memory?

- Solr 9 requires significant memory for collection management
- Tests stress Solr with large indexing operations
- Less memory causes "Connection refused" errors
- Trade-off: Slightly slower Docker startup

### Accessing Solr Admin UI

Once running:

```
http://localhost:8983/solr
Username: scholarsphere
Password: scholarsphere
```

### Troubleshooting Solr

**Solr container keeps restarting:**

```bash
# Check Solr logs
docker-compose logs -f solr

# Common issues:
# - Not enough disk space
# - Permission issues on Solr volume (see Linux-Specific section below)
# - Port 8983 already in use
```

**Fix Solr volume permissions (Linux):**

```bash
sudo chown -R 8983:8983 /var/lib/docker/volumes/scholarsphere_solr-data/_data
```

---

## Troubleshooting

### Permission Issues

**Symptom:** "Permission denied" when running commands in container

**Solution:**

```bash
# Ensure docker-env.sh was sourced
echo $CURRENT_USER_ID

# Should output: 1000:1000 (or your actual UID:GID)

# If empty, source it again
source ./docker-env.sh

# Rebuild containers with correct permissions
docker-compose down
docker-compose build --no-cache web
docker-compose up -d
```

### SELinux Issues (Fedora/RHEL)

**Symptom:** Container exits with "Permission denied" despite having correct UID/GID

**Solution:**

The `docker-compose.yml` includes SELinux-aware bind mount configuration:

```yaml
volumes:
  - type: bind
    source: ./
    target: /app
    bind:
      selinux: z   # Allow container to write with SELinux enabled
```

If you get SELinux errors, run:

```bash
# Check SELinux status
getenforce

# Temporarily disable for testing (requires sudo)
sudo setenforce 0

# Re-enable after testing
sudo setenforce 1
```

### Network/Connectivity Issues

**Symptom:** Web container can't reach Solr/Redis/SeaweedFS

**Solution:**

The correct S3 endpoint for Linux:

```yaml
# In docker-compose.yml
S3_ENDPOINT: http://seaweedfs:8333  # Use container service name, not localhost
```

NOT:
```yaml
S3_ENDPOINT: http://localhost:8333  # ❌ Won't work from container on Linux
```

### Files Owned by Wrong User

**Symptom:** Files in current directory now owned by UID 1000 instead of your user

**Solution:**

```bash
# Fix ownership
sudo chown -R $(id -u):$(id -g) .

# Then ensure CURRENT_USER_ID is set for future operations
source ./docker-env.sh
```

### Docker Compose Says "Unknown service"

**Symptom:** `docker-compose exec web bash` fails with "service 'web' not found"

**Solution:**

```bash
# Check running services
docker-compose ps

# If web is not listed, start it
docker-compose up -d

# If it keeps exiting, check logs
docker-compose logs web
```

---

## Testing

### Run All Tests

```bash
# Inside or outside the container
RAILS_ENV=test docker-compose exec -T web bundle exec rspec
```

### Run Specific Test File

```bash
RAILS_ENV=test docker-compose exec -T web bundle exec rspec spec/models/work_spec.rb
```

### Run Tests with Output

```bash
docker-compose exec -T web bash -lc "cd /app && RAILS_ENV=test bundle exec rspec" 2>&1 | tee rspec.log
```

### Run JavaScript Tests

```bash
docker-compose exec -T web yarn test
```

### Run Linting

```bash
# Ruby linting
docker-compose exec -T web bundle exec niftany

# JavaScript linting
docker-compose exec -T web yarn lint
```

### Integration Tests (Feature Specs)

```bash
RAILS_ENV=test docker-compose exec -T web bundle exec rspec spec/features/
```

---

## Common Workflows

### Develop Locally

```bash
# 1. Start containers
docker-compose up -d

# 2. Start Rails server
docker-compose exec web bash
cd /app
bundle exec rails server -b 0.0.0.0

# 3. In another terminal, run tests as you code
RAILS_ENV=test docker-compose exec -T web bundle exec rspec --watch

# 4. View app at http://localhost:3000
```

### Debug a Test Failure

```bash
# Run the failing test with verbose output
RAILS_ENV=test docker-compose exec -T web bundle exec rspec spec/path/to/spec.rb:123 -v

# Add breakpoints in the test using `binding.pry`
# Test execution will pause at breakpoint for inspection
```

### Rebuild After Dependency Changes

```bash
# If Gemfile changed:
docker-compose down
docker-compose build web

# If package.json changed:
docker-compose down
docker-compose build web

# Start again
docker-compose up -d
```

### Clean Slate

```bash
# Remove all containers and volumes (WARNING: Deletes database!)
docker-compose down -v

# Rebuild and restart
docker-compose build web
docker-compose up -d

# Re-initialize database
docker-compose exec -T web bundle exec rails db:create db:migrate
```

---

## Environment Variables

Key environment variables used by the application:

| Variable | Default | Purpose |
|----------|---------|---------|
| `CURRENT_USER_ID` | `1000:1000` | Docker container user (set by docker-env.sh) |
| `RAILS_ENV` | `development` | Rails environment (test, development, production) |
| `REDIS_HOST` | `redis` | Redis service hostname |
| `SOLR_HOST` | `solr` | Solr service hostname |
| `SOLR_USERNAME` | `scholarsphere` | Solr authentication |
| `SOLR_PASSWORD` | `scholarsphere` | Solr authentication |
| `S3_ENDPOINT` | `http://seaweedfs:8333` | SeaweedFS/S3-compatible storage |
| `POSTGRES_USER` | `scholarsphere` | Database username |
| `HOME` | `/tmp` | Home directory for container processes |

---

## Next Steps

- Read [DOCKER_SETUP.md](DOCKER_SETUP.md) for more Docker configuration details
- Check [SOLR9_MAIN1029_SETUP_FIXES.md](SOLR9_MAIN1029_SETUP_FIXES.md) for Solr 9 migration details
- See [run-tests.md](run-tests.md) for test execution details

---

**Last Updated:** 2026-10-30  
**For Issues:** Check docker-compose logs with `docker-compose logs <service-name>`
