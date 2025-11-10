# Docker Database Setup - Local Development

**Author:** Amelia (Developer Agent)  
**Date:** 2025-11-10  
**Purpose:** Comprehensive guide to starting Docker containers for development and testing with correct passwords

## Overview

The Video Window project uses Docker Compose to run PostgreSQL and Redis containers for both development and testing. **CRITICAL:** Passwords must be loaded from `video_window_server/config/passwords.yaml` when starting containers.

## Quick Start (Development)

```bash
cd /Volumes/workspace/projects/flutter/video_window

# Start development containers with correct passwords from passwords.yaml
POSTGRES_PASSWORD=Q9i79T4dGkpypurtwOs8r_HAhww3E68Z \
REDIS_PASSWORD=JLLDNS1puOSFsmtR7AePtBQt9huXBltb \
docker-compose up -d

# Wait for containers to be healthy (about 8 seconds)
sleep 8

# Apply migrations
cd video_window_server
dart bin/main.dart --apply-migrations --role maintenance
```

## Quick Start (Testing)

```bash
cd /Volumes/workspace/projects/flutter/video_window

# Start test containers with correct passwords from passwords.yaml
POSTGRES_TEST_PASSWORD=UvY-cHGz8dlZ5GfHp_VwyTakurIQuH6y \
REDIS_TEST_PASSWORD=e7qtwVJcd9gkrfakVNaXVqnpJqE8BhlK \
docker-compose --profile testing up -d

# Wait for containers to be healthy
sleep 8

# Run tests
cd video_window_server
dart test
```

## Quick Start (Both Dev + Test)

```bash
cd /Volumes/workspace/projects/flutter/video_window

# Start ALL containers
POSTGRES_PASSWORD=Q9i79T4dGkpypurtwOs8r_HAhww3E68Z \
REDIS_PASSWORD=JLLDNS1puOSFsmtR7AePtBQt9huXBltb \
POSTGRES_TEST_PASSWORD=UvY-cHGz8dlZ5GfHp_VwyTakurIQuH6y \
REDIS_TEST_PASSWORD=e7qtwVJcd9gkrfakVNaXVqnpJqE8BhlK \
docker-compose --profile testing up -d
```

## Password Configuration

### Where Passwords Are Stored

**DO NOT** set random passwords or leave them empty. All passwords are defined in:

```
video_window_server/config/passwords.yaml
```

### Current Passwords (from passwords.yaml)

#### Development:
- **POSTGRES_PASSWORD**: `Q9i79T4dGkpypurtwOs8r_HAhww3E68Z`
- **REDIS_PASSWORD**: `JLLDNS1puOSFsmtR7AePtBQt9huXBltb`

#### Test:
- **POSTGRES_TEST_PASSWORD**: `UvY-cHGz8dlZ5GfHp_VwyTakurIQuH6y`
- **REDIS_TEST_PASSWORD**: `e7qtwVJcd9gkrfakVNaXVqnpJqE8BhlK`

### Why This Matters

1. **Serverpod reads passwords from passwords.yaml** when connecting to the database
2. **Docker containers must be initialized with the SAME passwords**
3. **Mismatch causes authentication failures**: `password authentication failed for user "postgres"`
4. **Once initialized, changing the password requires removing Docker volumes**

## Docker Compose Configuration

### Services

#### Development Services (Default)
- `postgres`: PostgreSQL 16 with pgvector extension
  - Port: `8090` → 5432
  - Database: `video_window`
  - Volume: `video_window_data`
  
- `redis`: Redis 7.2.4
  - Port: `8091` → 6379

#### Test Services (Profile: testing)
- `postgres_test`: PostgreSQL 16 with pgvector
  - Port: `9090` → 5432
  - Database: `video_window_test`
  - Volume: `video_window_test_data`

- `redis_test`: Redis 7.2.4
  - Port: `9091` → 6379

### Profiles

Docker Compose uses profiles to separate dev and test environments:

- **No profile**: Starts dev services only
- **`--profile testing`**: Starts test services in addition to dev services

## Common Operations

### Check Container Status

```bash
docker ps | grep video_window
```

**Expected output (dev only):**
```
<id>  pgvector/pgvector:pg16   ...  Up ... (healthy)  0.0.0.0:8090->5432/tcp  video_window_postgres
<id>  redis:7.2.4-alpine        ...  Up ... (healthy)  0.0.0.0:8091->6379/tcp  video_window_redis
```

**Expected output (dev + test):**
```
<id>  pgvector/pgvector:pg16   ...  Up ... (healthy)  0.0.0.0:8090->5432/tcp  video_window_postgres
<id>  redis:7.2.4-alpine        ...  Up ... (healthy)  0.0.0.0:8091->6379/tcp  video_window_redis
<id>  pgvector/pgvector:pg16   ...  Up ... (healthy)  0.0.0.0:9090->5432/tcp  video_window_postgres_test
<id>  redis:7.2.4-alpine        ...  Up ... (healthy)  0.0.0.0:9091->6379/tcp  video_window_redis_test
```

### Check Container Logs

```bash
# Development PostgreSQL
docker logs video_window_postgres

# Development Redis
docker logs video_window_redis

# Test PostgreSQL
docker logs video_window_postgres_test

# Test Redis
docker logs video_window_redis_test
```

### Stop Containers

```bash
# Stop dev containers
docker-compose down

# Stop all containers (including test)
docker-compose --profile testing down
```

### Reset Database (Remove Volumes)

⚠️ **WARNING**: This deletes ALL data in the databases!

```bash
# Stop and remove containers + volumes
docker-compose --profile testing down -v

# Then restart with correct passwords (see Quick Start sections above)
```

## Troubleshooting

### Problem: "password authentication failed"

**Symptom:**
```
ERROR: Severity.fatal 28P01: password authentication failed for user "postgres"
```

**Cause:** Database was initialized with a different password than what Serverpod is using.

**Solution:**
1. Stop containers and remove volumes:
   ```bash
   docker-compose down -v
   ```

2. Restart with correct passwords from `passwords.yaml`:
   ```bash
   POSTGRES_PASSWORD=Q9i79T4dGkpypurtwOs8r_HAhww3E68Z \
   REDIS_PASSWORD=JLLDNS1puOSFsmtR7AePtBQt9huXBltb \
   docker-compose up -d
   ```

### Problem: "Connection refused" 

**Symptom:**
```
ERROR: SocketException: Connection refused (OS Error: Connection refused, errno = 61), address = localhost, port = 8090
```

**Causes & Solutions:**

1. **Containers not started:**
   ```bash
   docker-compose up -d
   ```

2. **Containers starting but not healthy yet:**
   ```bash
   # Wait 8 seconds for health checks
   sleep 8
   docker ps | grep video_window
   ```

3. **Containers exiting immediately:**
   ```bash
   # Check logs
   docker logs video_window_postgres
   docker logs video_window_redis
   
   # Usually means password is empty/invalid - see "password authentication failed" solution
   ```

### Problem: Redis container exits with "wrong number of arguments"

**Symptom:**
```
*** FATAL CONFIG FILE ERROR (Redis 7.2.4) ***
Reading the configuration file, at line 2
>>> 'requirepass'
wrong number of arguments
```

**Cause:** Redis password environment variable is empty (`REDIS_PASSWORD=""`).

**Solution:** Redis 7.2.4 doesn't accept empty passwords. Use the actual password from `passwords.yaml`:

```bash
REDIS_PASSWORD=JLLDNS1puOSFsmtR7AePtBQt9huXBltb \
docker-compose up -d
```

### Problem: Test database not available

**Symptom:**
```
ERROR: Failed to connect to the database.
database port: 9090
database name: video_window_test
```

**Cause:** Test containers not started (require `--profile testing`).

**Solution:**
```bash
POSTGRES_TEST_PASSWORD=UvY-cHGz8dlZ5GfHp_VwyTakurIQuH6y \
REDIS_TEST_PASSWORD=e7qtwVJcd9gkrfakVNaXVqnpJqE8BhlK \
docker-compose --profile testing up -d
```

### Problem: "The POSTGRES_PASSWORD variable is not set"

**Symptom:**
```
level=warning msg="The \"POSTGRES_PASSWORD\" variable is not set. Defaulting to a blank string."
```

**Impact:** This is just a warning, but if you don't provide the password, the container will fail to initialize.

**Solution:** Always provide passwords explicitly as environment variables (see Quick Start sections).

## Port Reference

| Service | Container | Host Port | Container Port |
|---------|-----------|-----------|----------------|
| Dev PostgreSQL | `video_window_postgres` | 8090 | 5432 |
| Dev Redis | `video_window_redis` | 8091 | 6379 |
| Test PostgreSQL | `video_window_postgres_test` | 9090 | 5432 |
| Test Redis | `video_window_redis_test` | 9091 | 6379 |

## Serverpod Configuration

Serverpod reads database configuration from:

### Development
- File: `video_window_server/config/development.yaml`
- Database host: `localhost`
- Database port: `8090`
- Database name: `video_window`
- Password source: `video_window_server/config/passwords.yaml` → `development.database`

### Test
- File: Auto-configured by `serverpod_test`
- Database host: `localhost`
- Database port: `9090`
- Database name: `video_window_test`
- Password source: `video_window_server/config/passwords.yaml` → `test.database`

## Best Practices

1. **Always check passwords.yaml first** before starting Docker containers
2. **Use the exact passwords from passwords.yaml** when starting containers
3. **Wait 8 seconds after `docker-compose up`** before attempting to connect
4. **Verify containers are healthy** with `docker ps` before running migrations/tests
5. **Check logs immediately** if containers exit unexpectedly
6. **Don't commit passwords.yaml** to version control (already in .gitignore)
7. **Reset volumes if password mismatch occurs** - there's no way to change password after initialization

## Automation Scripts (Future Enhancement)

Consider creating helper scripts:

### `scripts/docker-dev.sh`
```bash
#!/bin/bash
set -e
cd "$(dirname "$0")/.."

# Load passwords from config
POSTGRES_PASSWORD=$(grep "^  database:" video_window_server/config/passwords.yaml | awk '{print $2}' | tr -d "'\"")
REDIS_PASSWORD=$(grep "^  redis:" video_window_server/config/passwords.yaml | awk '{print $2}' | tr -d "'\"")

# Start containers
POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
REDIS_PASSWORD="$REDIS_PASSWORD" \
docker-compose up -d

echo "Waiting for containers to be healthy..."
sleep 8

echo "Development containers ready!"
docker ps | grep video_window
```

### `scripts/docker-test.sh`
Similar pattern for test environment.

## Related Documentation

- [Local Development Environment](../stories/01-2-local-development-environment.md)
- [Serverpod Configuration](../frameworks/serverpod/01-setup-installation.md)
- [Database Migrations](../frameworks/serverpod/04-database-migrations.md)
- [Testing Strategy](../architecture/architecture.md#testing-strategy)

## Changelog

| Date | Change | Author |
|------|--------|--------|
| 2025-11-10 | Initial documentation created | Amelia (Developer Agent) |

