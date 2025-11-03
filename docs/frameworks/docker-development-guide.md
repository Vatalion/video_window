# Docker Development Guide - Video Window

**Version:** Docker 27.4.0  
**Last Updated:** 2025-11-03  
**Status:** ✅ Active - Development Environment

---

## Overview

Docker provides containerized PostgreSQL and Redis for Video Window development. This guide covers local development setup, NOT production deployment.

---

## Current Setup

### Running Containers

```bash
# Check status
docker ps

# Expected output:
# - PostgreSQL 16.10 on port 8090
# - Redis 6.2.6 on port 8091
```

### docker-compose.yaml

```yaml
# video_window_server/docker-compose.yaml
version: '3.8'

services:
  postgres:
    image: postgres:16.10
    restart: unless-stopped
    ports:
      - '8090:5432'
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: video_window
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U postgres']
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:6.2.6
    restart: unless-stopped
    ports:
      - '8091:6379'
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes
    healthcheck:
      test: ['CMD', 'redis-cli', 'ping']
      interval: 10s
      timeout: 3s
      retries: 5

volumes:
  postgres_data:
  redis_data:
```

---

## Common Commands

```bash
# Start all services
cd video_window_server
docker-compose up -d

# View logs
docker-compose logs -f postgres
docker-compose logs -f redis

# Stop services
docker-compose down

# Stop and remove volumes (DELETE DATA!)
docker-compose down -v

# Restart a service
docker-compose restart postgres

# Execute commands in container
docker-compose exec postgres psql -U postgres -d video_window
docker-compose exec redis redis-cli
```

---

## Database Operations

### Connect to PostgreSQL

```bash
docker-compose exec postgres psql -U postgres -d video_window
```

### Run SQL queries

```sql
-- List tables
\dt

-- Describe table
\d users

-- Query data
SELECT * FROM users LIMIT 10;

-- Exit
\q
```

### Backup Database

```bash
docker-compose exec -T postgres pg_dump -U postgres video_window > backup.sql
```

### Restore Database

```bash
docker-compose exec -T postgres psql -U postgres video_window < backup.sql
```

---

## Redis Operations

### Connect to Redis

```bash
docker-compose exec redis redis-cli
```

### Common Redis Commands

```bash
# Get all keys
KEYS *

# Get value
GET key_name

# Set value
SET mykey "Hello"

# Check connection
PING

# Flush all data (DANGEROUS!)
FLUSHALL

# Exit
exit
```

---

## Troubleshooting

### Port Already in Use

```bash
# Find process using port 8090
lsof -i :8090

# Kill process
kill -9 <PID>

# Or change port in docker-compose.yaml
```

### Container Won't Start

```bash
# View detailed logs
docker-compose logs postgres

# Remove and recreate
docker-compose down
docker-compose up -d
```

### Data Persistence Issues

```bash
# Check volumes
docker volume ls

# Inspect volume
docker volume inspect video_window_server_postgres_data

# Remove volume (deletes data!)
docker volume rm video_window_server_postgres_data
```

---

## Video Window Conventions

- **Postgres Port:** 8090 (NOT default 5432, avoids conflicts)
- **Redis Port:** 8091 (NOT default 6379, avoids conflicts)
- **Passwords:** `postgres` (dev only, change in production)
- **Volumes:** Named volumes for persistence

---

## Reference

- **Docker Docs:** https://docs.docker.com/
- **Docker Compose:** https://docs.docker.com/compose/
- **PostgreSQL Image:** https://hub.docker.com/_/postgres
- **Redis Image:** https://hub.docker.com/_/redis

---

**Last Updated:** 2025-11-03 by Winston  
**For:** Development environment only (NOT production)
