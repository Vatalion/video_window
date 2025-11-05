# video_window_server

This is the starting point for your Serverpod server.

## Getting Started

### Prerequisites
- Docker and Docker Compose
- Dart SDK 3.5.6 or higher
- PostgreSQL 15+ (via Docker)
- Redis 7.2.4+ (via Docker)

### Running the Server

1. Start Postgres and Redis with Docker:
   ```bash
   docker compose up --build --detach
   ```

2. Start the Serverpod server:
   ```bash
   dart bin/main.dart
   ```

3. When finished, shut down Serverpod with `Ctrl-C`, then stop Docker services:
   ```bash
   docker compose stop
   ```

## Health Check Endpoint

The server includes a health check endpoint for monitoring and smoke tests:

**Endpoint:** `/health/check`

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-11-03T12:00:00.000Z",
  "version": "1.0.0",
  "services": {
    "database": "ok",
    "redis": "ok"
  }
}
```

**Smoke Test:**
```bash
# Start server, then:
curl http://localhost:8080/health/check
```

## Running Tests

Integration tests require Docker services to be running:

```bash
# Start Docker services
docker compose up -d

# Run tests
dart test

# Stop Docker services
docker compose stop
```
