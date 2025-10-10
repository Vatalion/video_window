# Docker Configuration Guide

**Effective Date:** 2025-10-09
**Target Framework:** Flutter 3.19.6, Serverpod 2.9.x
**Platform:** Multi-stage Docker builds for production

## Overview

This guide covers Docker configuration for the Craft Video Marketplace, including multi-stage builds for optimization, security best practices, and container orchestration.

## Docker Architecture

### Container Strategy

| Service | Base Image | Purpose | Size |
|---------|------------|---------|------|
| **Serverpod Backend** | `dart:stable-slim` | API server | ~100MB |
| **Flutter Web** | `nginx:alpine` | Static web hosting | ~50MB |
| **PostgreSQL** | `postgres:15-alpine` | Database | ~150MB |
| **Redis** | `redis:7-alpine` | Cache/Queue | ~30MB |
| **Nginx** | `nginx:alpine` | Load balancer | ~20MB |

## Dockerfiles

### Serverpod Multi-stage Dockerfile

```dockerfile
# server/Dockerfile

# Build stage
FROM dart:stable AS builder
WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml ./
COPY pubspec_overrides.yaml ./

# Download dependencies
RUN dart pub get

# Copy source code
COPY . .

# Generate code
RUN dart run build_runner build --delete-conflicting-outputs

# Run tests
RUN dart test --reporter=expanded

# Production stage
FROM dart:stable-slim AS production

# Install system dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create app user
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Copy dependencies from builder
COPY --from=builder /app/.dart_tool .dart_tool
COPY --from=builder /app/pubspec.yaml ./
COPY --from=builder /app/pubspec.lock ./
COPY --from=builder /app/pubspec_overrides.yaml ./

# Copy compiled application
COPY --from=builder /app/bin bin/
COPY --from=builder /app/lib lib/
COPY --from=builder /app/config config/

# Create necessary directories
RUN mkdir -p logs temp && chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Expose port
EXPOSE 8080

# Run application
CMD ["dart", "run", "bin/server.dart"]
```

### Flutter Web Dockerfile

```dockerfile
# web/Dockerfile

# Build stage
FROM cirrusci/flutter:3.19.6 AS builder
WORKDIR /app

# Copy Flutter app
COPY . .

# Download dependencies
RUN flutter pub get

# Generate code
RUN dart run build_runner build --delete-conflicting-outputs

# Build web app
RUN flutter build web --release --no-tree-shake-icons

# Production stage
FROM nginx:alpine AS production

# Copy custom nginx config
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf

# Copy built web app
COPY --from=builder /app/build/web /usr/share/nginx/html

# Add health check
RUN apk add --no-cache curl

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/health || exit 1

# Expose port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
```

### Optimized Flutter Web Dockerfile

```dockerfile
# web/Dockerfile.optimized

# Build stage with caching
FROM cirrusci/flutter:3.19.6 AS builder
WORKDIR /app

# Copy dependency files first for layer caching
COPY pubspec.yaml ./
COPY pubspec.lock ./
COPY .flutter-plugins ./
COPY .flutter-plugins-dependencies ./

# Download dependencies (cached layer)
RUN flutter pub get

# Copy source code
COPY . .

# Generate code
RUN dart run build_runner build --delete-conflicting-outputs

# Build web app with optimizations
RUN flutter build web \
    --release \
    --no-tree-shake-icons \
    --web-renderer canvaskit \
    --no-web-resources-cdn

# Production stage
FROM nginx:alpine AS production

# Install additional tools
RUN apk add --no-cache \
    curl \
    tzdata \
    && rm -rf /var/cache/apk/*

# Copy optimized nginx config
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY nginx/mime.types /etc/nginx/mime.types

# Copy built web app with correct permissions
COPY --from=builder --chown=nginx:nginx /app/build/web /usr/share/nginx/html

# Add compression and caching
RUN find /usr/share/nginx/html -name "*.js" -exec gzip -k {} \; \
    && find /usr/share/nginx/html -name "*.css" -exec gzip -k {} \; \
    && find /usr/share/nginx/html -name "*.html" -exec gzip -k {} \;

# Health check endpoint
RUN echo 'OK' > /usr/share/nginx/html/health

# Security headers and optimization
COPY nginx/security.conf /etc/nginx/snippets/security.conf
COPY nginx/gzip.conf /etc/nginx/snippets/gzip.conf

# Non-root user for security
RUN addgroup -g 1001 -S nginx \
    && adduser -S -D -H -u 1001 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/health || exit 1

# Switch to non-root user
USER nginx

# Expose port
EXPOSE 80

# Start nginx with optimized configuration
CMD ["nginx", "-g", "daemon off;", "-c", "/etc/nginx/nginx.conf"]
```

## Docker Compose Development

### Development Docker Compose

```yaml
# docker-compose.dev.yml

version: '3.8'

services:
  # Serverpod Backend
  server:
    build:
      context: ./server
      dockerfile: Dockerfile
      target: builder
    ports:
      - "8080:8080"
    environment:
      - POSTGRES_HOST=postgres
      - POSTGRES_PORT=5432
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=testpass
      - POSTGRES_DB=craftmarketplace_dev
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - ENVIRONMENT=development
      - LOG_LEVEL=debug
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    volumes:
      - ./server:/app
      - server_logs:/app/logs
    networks:
      - craftmarketplace-network
    restart: unless-stopped

  # PostgreSQL Database
  postgres:
    image: postgres:15-alpine
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=testpass
      - POSTGRES_DB=craftmarketplace_dev
      - POSTGRES_INITDB_ARGS=--encoding=UTF-8 --lc-collate=C --lc-ctype=C
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./server/migrations:/docker-entrypoint-initdb.d
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - craftmarketplace-network
    restart: unless-stopped

  # Redis Cache
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - craftmarketplace-network
    restart: unless-stopped

  # Flutter Web
  web:
    build:
      context: .
      dockerfile: web/Dockerfile
      target: builder
    ports:
      - "3000:80"
    environment:
      - API_BASE_URL=http://localhost:8080
      - WEB_URL=http://localhost:3000
    depends_on:
      - server
    volumes:
      - ./lib:/app/lib
      - ./web:/app/web
    networks:
      - craftmarketplace-network
    restart: unless-stopped

  # Nginx Load Balancer
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/ssl:/etc/nginx/ssl
    depends_on:
      - server
      - web
    networks:
      - craftmarketplace-network
    restart: unless-stopped

  # Monitoring (Prometheus)
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    networks:
      - craftmarketplace-network
    restart: unless-stopped

  # Monitoring (Grafana)
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana
      - ./monitoring/grafana/dashboards:/etc/grafana/provisioning/dashboards
      - ./monitoring/grafana/datasources:/etc/grafana/provisioning/datasources
    depends_on:
      - prometheus
    networks:
      - craftmarketplace-network
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
  server_logs:
  prometheus_data:
  grafana_data:

networks:
  craftmarketplace-network:
    driver: bridge
```

### Production Docker Compose

```yaml
# docker-compose.prod.yml

version: '3.8'

services:
  # Serverpod Backend (Production)
  server:
    build:
      context: ./server
      dockerfile: Dockerfile
      target: production
    image: ghcr.io/craftmarketplace/video_window-server:${VERSION}
    restart: always
    environment:
      - POSTGRES_HOST=postgres
      - POSTGRES_PORT=5432
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=craftmarketplace_prod
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - ENVIRONMENT=production
      - LOG_LEVEL=info
      - JWT_SECRET=${JWT_SECRET}
      - STRIPE_SECRET_KEY=${STRIPE_SECRET_KEY}
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    volumes:
      - server_logs:/app/logs
      - server_uploads:/app/uploads
    networks:
      - craftmarketplace-network
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3

  # PostgreSQL Database (Production)
  postgres:
    image: postgres:15-alpine
    restart: always
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=craftmarketplace_prod
      - POSTGRES_INITDB_ARGS=--encoding=UTF-8 --lc-collate=C --lc-ctype=C
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./server/migrations:/docker-entrypoint-initdb.d
      - ./backups:/backups
    networks:
      - craftmarketplace-network
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '1.0'
          memory: 1G
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

  # Redis Cache (Production)
  redis:
    image: redis:7-alpine
    restart: always
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    networks:
      - craftmarketplace-network
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Flutter Web (Production)
  web:
    build:
      context: .
      dockerfile: web/Dockerfile.optimized
      target: production
    image: ghcr.io/craftmarketplace/video_window-web:${VERSION}
    restart: always
    environment:
      - API_BASE_URL=https://api.craftmarketplace.com
      - WEB_URL=https://craftmarketplace.com
    depends_on:
      - server
    networks:
      - craftmarketplace-network
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
        reservations:
          cpus: '0.25'
          memory: 128M

  # Nginx Load Balancer (Production)
  nginx:
    image: nginx:alpine
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.prod.conf:/etc/nginx/nginx.conf
      - ./nginx/ssl:/etc/nginx/ssl
      - ./logs/nginx:/var/log/nginx
    depends_on:
      - server
      - web
    networks:
      - craftmarketplace-network
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
        reservations:
          cpus: '0.25'
          memory: 128M

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local
  server_logs:
    driver: local
  server_uploads:
    driver: local

networks:
  craftmarketplace-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

## Nginx Configuration

### Production Nginx Configuration

```nginx
# nginx/nginx.prod.conf

user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

# Load modules
load_module modules/ngx_http_brotli_filter_module.so;
load_module modules/ngx_http_brotli_static_module.so;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging format
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for" '
                    'rt=$request_time uct="$upstream_connect_time" '
                    'uht="$upstream_header_time" urt="$upstream_response_time"';

    access_log /var/log/nginx/access.log main;

    # Basic settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    # Security headers
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://www.googletagmanager.com https://www.google-analytics.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https:; connect-src 'self' https://api.craftmarketplace.com; media-src 'self' https:; object-src 'none'; base-uri 'self'; form-action 'self';" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;

    # Brotli compression
    brotli on;
    brotli_comp_level 6;
    brotli_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;

    # Upstream servers
    upstream api_backend {
        least_conn;
        server server1:8080 max_fails=3 fail_timeout=30s;
        server server2:8080 max_fails=3 fail_timeout=30s;
        server server3:8080 max_fails=3 fail_timeout=30s;
        keepalive 32;
    }

    # HTTP to HTTPS redirect
    server {
        listen 80;
        server_name craftmarketplace.com www.craftmarketplace.com api.craftmarketplace.com;
        return 301 https://$server_name$request_uri;
    }

    # Main site
    server {
        listen 443 ssl http2;
        server_name craftmarketplace.com www.craftmarketplace.com;

        # SSL configuration
        ssl_certificate /etc/nginx/ssl/craftmarketplace.com.crt;
        ssl_certificate_key /etc/nginx/ssl/craftmarketplace.com.key;
        ssl_session_timeout 1d;
        ssl_session_cache shared:SSL:50m;
        ssl_session_tickets off;

        # Modern SSL configuration
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;

        # HSTS
        add_header Strict-Transport-Security "max-age=63072000" always;

        # Static files
        location / {
            root /usr/share/nginx/html;
            index index.html;
            try_files $uri $uri/ /index.html;

            # Cache static files
            location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
                expires 1y;
                add_header Cache-Control "public, immutable";
                add_header Vary Accept-Encoding;
            }

            # HTML files
            location ~* \.html$ {
                expires 1h;
                add_header Cache-Control "public, no-cache";
            }
        }

        # Health check
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }

    # API server
    server {
        listen 443 ssl http2;
        server_name api.craftmarketplace.com;

        # SSL configuration
        ssl_certificate /etc/nginx/ssl/api.craftmarketplace.com.crt;
        ssl_certificate_key /etc/nginx/ssl/api.craftmarketplace.com.key;
        ssl_session_timeout 1d;
        ssl_session_cache shared:SSL:50m;
        ssl_session_tickets off;

        # Modern SSL configuration
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;

        # HSTS
        add_header Strict-Transport-Security "max-age=63072000" always;

        # API endpoints
        location / {
            limit_req zone=api burst=20 nodelay;

            proxy_pass http://api_backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;

            # Timeouts
            proxy_connect_timeout 30s;
            proxy_send_timeout 30s;
            proxy_read_timeout 30s;
        }

        # Auth endpoints with stricter rate limiting
        location /auth/ {
            limit_req zone=login burst=5 nodelay;

            proxy_pass http://api_backend;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Health check
        location /health {
            proxy_pass http://api_backend/health;
            access_log off;
        }
    }
}
```

## Build Scripts

### Docker Build Script

```bash
#!/bin/bash
# scripts/build-docker.sh

set -e

VERSION=${1:-latest}
ENVIRONMENT=${2:-production}

echo "🐳 Building Docker images for $ENVIRONMENT (version: $VERSION)"

# Build Serverpod image
echo "Building Serverpod image..."
docker build -t ghcr.io/craftmarketplace/video_window-server:$VERSION \
    -t ghcr.io/craftmarketplace/video_window-server:latest \
    ./server

# Build Flutter Web image
echo "Building Flutter Web image..."
docker build -t ghcr.io/craftmarketplace/video_window-web:$VERSION \
    -t ghcr.io/craftmarketplace/video_window-web:latest \
    -f web/Dockerfile.optimized .

# Build multi-architecture images
echo "Building multi-architecture images..."
docker buildx build --platform linux/amd64,linux/arm64 \
    -t ghcr.io/craftmarketplace/video_window-server:$VERSION \
    -t ghcr.io/craftmarketplace/video_window-server:latest \
    --push \
    ./server

docker buildx build --platform linux/amd64,linux/arm64 \
    -t ghcr.io/craftmarketplace/video_window-web:$VERSION \
    -t ghcr.io/craftmarketplace/video_window-web:latest \
    --push \
    -f web/Dockerfile.optimized .

echo "✅ Docker images built successfully!"

# Show image sizes
echo "📊 Image sizes:"
docker images | grep video_window
```

### Development Setup Script

```bash
#!/bin/bash
# scripts/dev-setup.sh

set -e

echo "🚀 Setting up development environment..."

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file..."
    cat > .env << EOF
# Development Environment Variables
POSTGRES_USER=postgres
POSTGRES_PASSWORD=testpass
POSTGRES_DB=craftmarketplace_dev
REDIS_PASSWORD=testpass
JWT_SECRET=test-jwt-secret-dev
STRIPE_SECRET_KEY=sk_test_
VERSION=latest
ENVIRONMENT=development
EOF
fi

# Build and start services
echo "Building and starting services..."
docker-compose -f docker-compose.dev.yml up --build -d

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 30

# Run database migrations
echo "Running database migrations..."
docker-compose -f docker-compose.dev.yml exec server dart run serverpod_cli migrate

# Show service status
echo "📊 Service status:"
docker-compose -f docker-compose.dev.yml ps

echo "✅ Development environment is ready!"
echo "🌐 Web app: http://localhost:3000"
echo "🔧 API: http://localhost:8080"
echo "📊 Grafana: http://localhost:3001 (admin/admin)"
echo "📈 Prometheus: http://localhost:9090"
```

## Security Best Practices

### Docker Security Configuration

```dockerfile
# security/Dockerfile.security

# Use minimal base image
FROM alpine:latest

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -S -u 1001 -G appgroup appuser

# Install only necessary packages
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    && rm -rf /var/cache/apk/*

# Set proper permissions
COPY --chown=appuser:appgroup . /app
WORKDIR /app

# Remove setuid and setgid binaries
RUN find / -perm /6000 -type f -exec chmod a-s {} \; || true
RUN find / -perm /4000 -type f -exec chmod a-s {} \; || true

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Expose port
EXPOSE 8080

# Run application
CMD ["./app"]
```

### Security Scan Script

```bash
#!/bin/bash
# scripts/security-scan.sh

set -e

IMAGE=${1:-ghcr.io/craftmarketplace/video_window-server:latest}

echo "🔍 Running security scan on $IMAGE"

# Trivy vulnerability scan
echo "Running Trivy scan..."
trivy image --exit-code 0 --severity HIGH,CRITICAL $IMAGE

# Docker Bench Security
echo "Running Docker Bench Security..."
docker run -it --net host --pid host --userns host --cap-add audit_control \
    -e DOCKER_CONTENT_TRUST=$DOCKER_CONTENT_TRUST \
    -v /etc:/etc:ro \
    -v /usr/bin/containerd:/usr/bin/containerd:ro \
    -v /usr/bin/runc:/usr/bin/runc:ro \
    -v /usr/lib/systemd:/usr/lib/systemd:ro \
    -v /var/lib:/var/lib:ro \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    --label docker_bench_security \
    docker/docker-bench-security

# Custom security checks
echo "Running custom security checks..."
docker run --rm $IMAGE \
    sh -c "id && groups && ls -la /app"

echo "✅ Security scan completed!"
```

## Optimization

### Multi-stage Build Optimization

```dockerfile
# optimized/Dockerfile.server

# Dependencies stage
FROM dart:stable AS deps
WORKDIR /app
COPY pubspec.yaml ./
COPY pubspec_overrides.yaml ./
RUN dart pub get --no-dev

# Code generation stage
FROM deps AS codegen
COPY . .
RUN dart run build_runner build --delete-conflicting-outputs

# Builder stage
FROM codegen AS builder
RUN dart compile exe bin/server.dart -o bin/server.aot

# Final production image
FROM gcr.io/dart-lang/base:3.5.6 AS production

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Copy compiled binary
COPY --from=builder --chown=appuser:appuser /app/bin/server.aot /app/server
COPY --from=builder --chown=appuser:appuser /app/config /app/config

# Create directories
RUN mkdir -p logs temp && chown -R appuser:appuser /app

USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

EXPOSE 8080

CMD ["./server"]
```

### Image Size Optimization

```bash
#!/bin/bash
# scripts/optimize-images.sh

set -e

echo "📦 Optimizing Docker images..."

# Clean up unused images
echo "Cleaning up unused images..."
docker image prune -f

# Build optimized images
echo "Building optimized images..."
docker build -f optimized/Dockerfile.server -t craftmarketplace/server:optimized ./server
docker build -f web/Dockerfile.optimized -t craftmarketplace/web:optimized .

# Show size comparison
echo "📊 Image size comparison:"
echo "Original vs Optimized:"
docker images | grep craftmarketplace

# Export optimized images
echo "Exporting optimized images..."
docker save craftmarketplace/server:optimized | gzip -c > craftmarketplace-server.tar.gz
docker save craftmarketplace/web:optimized | gzip -c > craftmarketplace-web.tar.gz

echo "✅ Image optimization completed!"
echo "📦 Exported files:"
ls -lh *.tar.gz
```

---

**Last Updated:** 2025-10-09
**Related Documentation:** [CI/CD Pipeline](./ci-cd.md) | [Testing Strategy](../testing/testing-strategy.md) | [Environment Setup](../development.md)