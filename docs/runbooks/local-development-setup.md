# Local Development Environment Setup

**Time to Complete:** < 10 minutes  
**Prerequisites:** Docker Desktop installed and running

## Quick Start

### 1. Configure Environment Variables (2 min)

```bash
# Navigate to project root
cd video_window

# Copy environment template
cp .env.example .env

# Generate secure passwords
openssl rand -base64 32  # Run this 5 times for each password

# Edit .env and replace placeholder passwords
# Required variables:
#   - POSTGRES_PASSWORD
#   - REDIS_PASSWORD
#   - POSTGRES_TEST_PASSWORD
#   - REDIS_TEST_PASSWORD
#   - SERVICE_SECRET
```

### 2. Start Local Services (2 min)

```bash
# Start PostgreSQL and Redis (development only)
docker compose up -d

# Verify services are healthy
docker compose ps

# Expected output:
# NAME                      STATUS
# video_window_postgres     Up (healthy)
# video_window_redis        Up (healthy)
```

### 3. Apply Database Migrations (1 min)

```bash
cd video_window_server
dart bin/main.dart --apply-migrations
```

### 4. Start Serverpod Backend (1 min)

```bash
# From video_window_server directory
dart bin/main.dart

# Expected output:
# ✓ Server started on http://localhost:8080
# ✓ Connected to PostgreSQL at localhost:8090
# ✓ Connected to Redis at localhost:8091
```

### 5. Run Flutter App (2 min)

In a new terminal:

```bash
cd video_window_flutter
flutter pub get
flutter run
```

## Service Ports

| Service | Port | URL/Connection |
|---------|------|----------------|
| PostgreSQL (dev) | 8090 | `localhost:8090` |
| Redis (dev) | 8091 | `localhost:8091` |
| Serverpod API | 8080 | `http://localhost:8080` |
| Serverpod Insights | 8081 | `http://localhost:8081` |
| Serverpod Web | 8082 | `http://localhost:8082` |
| PostgreSQL (test) | 9090 | `localhost:9090` (via `--profile testing`) |
| Redis (test) | 9091 | `localhost:9091` (via `--profile testing`) |

## Testing Services

### Start Test Services

```bash
# Start test databases alongside development services
docker compose --profile testing up -d
```

### Connect to PostgreSQL

```bash
# Development database
docker exec -it video_window_postgres psql -U postgres -d video_window

# Test database (if running)
docker exec -it video_window_postgres_test psql -U postgres -d video_window_test
```

### Connect to Redis

```bash
# Development Redis
docker exec -it video_window_redis redis-cli

# Authenticate (use password from .env)
AUTH your_redis_password
PING  # Should return PONG
```

## Troubleshooting

### Services Won't Start

```bash
# Check Docker is running
docker info

# Check for port conflicts
lsof -i :8090  # PostgreSQL
lsof -i :8091  # Redis

# View service logs
docker compose logs postgres
docker compose logs redis
```

### Database Connection Fails

```bash
# Verify PostgreSQL is healthy
docker compose ps postgres

# Check connection from host
psql -h localhost -p 8090 -U postgres -d video_window

# Restart services
docker compose restart postgres
```

### Redis Connection Fails

```bash
# Verify Redis is healthy
docker compose ps redis

# Test connection
redis-cli -h localhost -p 8091 -a your_redis_password ping

# Restart Redis
docker compose restart redis
```

### Clean Start (Nuclear Option)

```bash
# Stop all services
docker compose down

# Remove volumes (WARNING: Deletes all data)
docker volume rm video_window_data video_window_test_data

# Restart fresh
docker compose up -d

# Re-apply migrations
cd video_window_server
dart bin/main.dart --apply-migrations
```

## Daily Workflow

```bash
# Morning: Start services
docker compose up -d

# During development: Run app
cd video_window_flutter && flutter run

# Evening: Stop services (optional, saves resources)
docker compose stop

# When switching branches with migrations
cd video_window_server
dart bin/main.dart --apply-migrations
```

## Next Steps

After local setup:

1. **Epic 01-3**: Configure code generation workflows
2. **Epic 01-4**: Set up CI/CD pipeline
3. **Epic 02**: Begin app shell development

## Configuration Files

- **docker-compose.yml**: Service definitions (project root)
- **.env**: Local environment variables (git-ignored)
- **.env.example**: Template with defaults
- **video_window_server/config/development.yaml**: Serverpod dev config
- **video_window_server/config/passwords.yaml**: Serverpod passwords (git-ignored)

## Security Notes

- Never commit `.env` file to version control
- Generate unique passwords for each environment
- Rotate passwords periodically
- Use Docker secrets in production
- Keep `passwords.yaml` in `.gitignore`

## Support

- **Documentation**: `/docs/README.md`
- **Architecture**: `/docs/architecture/`
- **PRD**: `/docs/prd.md`
- **Serverpod Guide**: `/docs/frameworks/serverpod/`
