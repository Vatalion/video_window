# Serverpod Deployment Guide

**Version:** Serverpod 2.9.x  
**Project:** Video Window  
**Last Updated:** 2025-10-30

---

## Overview

This guide covers deploying Video Window's Serverpod backend to production environments.

---

## Deployment Architecture

```
┌─────────────────────────────────────────────────┐
│                 Load Balancer                    │
│                 (nginx/ALB)                      │
└───────────┬──────────────────────┬───────────────┘
            │                      │
    ┌───────▼────────┐     ┌───────▼────────┐
    │  Serverpod     │     │  Serverpod     │
    │  Instance 1    │     │  Instance 2    │
    └───────┬────────┘     └───────┬────────┘
            │                      │
            └──────────┬───────────┘
                       │
            ┌──────────▼──────────┐
            │   PostgreSQL        │
            │   (RDS/Managed)     │
            └──────────┬──────────┘
                       │
            ┌──────────▼──────────┐
            │   Redis             │
            │   (ElastiCache)     │
            └─────────────────────┘
```

---

## Pre-Deployment Checklist

### 1. Environment Configuration

**File:** `video_window_server/config/production.yaml`

```yaml
database:
  host: ${DB_HOST}
  port: ${DB_PORT}
  name: ${DB_NAME}
  user: ${DB_USER}
  password: ${DB_PASSWORD}
  ssl: true
  sslMode: require

redis:
  enabled: true
  host: ${REDIS_HOST}
  port: ${REDIS_PORT}
  password: ${REDIS_PASSWORD}

server:
  port: 8080
  publicHost: ${PUBLIC_HOST}
  publicScheme: https

auth:
  jwtSecret: ${JWT_SECRET}
  tokenExpiry: 900  # 15 minutes

stripe:
  apiKey: ${STRIPE_SECRET_KEY}
  webhookSecret: ${STRIPE_WEBHOOK_SECRET}

sendgrid:
  apiKey: ${SENDGRID_API_KEY}

s3:
  bucket: ${S3_BUCKET}
  region: ${AWS_REGION}
  accessKey: ${AWS_ACCESS_KEY}
  secretKey: ${AWS_SECRET_KEY}
```

### 2. Required Environment Variables

```bash
# Database
export DB_HOST=prod-db.xxxxx.us-east-1.rds.amazonaws.com
export DB_PORT=5432
export DB_NAME=video_window_prod
export DB_USER=vw_app
export DB_PASSWORD='<secure_password>'

# Redis
export REDIS_HOST=prod-redis.xxxxx.cache.amazonaws.com
export REDIS_PORT=6379
export REDIS_PASSWORD='<secure_password>'

# Server
export PUBLIC_HOST=api.videowindow.com
export JWT_SECRET='<cryptographically_secure_random_string>'

# External Services
export STRIPE_SECRET_KEY='sk_live_...'
export STRIPE_WEBHOOK_SECRET='whsec_...'
export SENDGRID_API_KEY='SG...'
export AWS_ACCESS_KEY='AKIA...'
export AWS_SECRET_KEY='<secret>'
export S3_BUCKET='videowindow-media-prod'
export AWS_REGION='us-east-1'
```

---

## Deployment Methods

### Option 1: Docker Deployment (Recommended)

#### 1. Build Docker Image

**Dockerfile:**
```dockerfile
FROM dart:3.5.6 AS build

WORKDIR /app
COPY video_window_server/pubspec.* ./
RUN dart pub get

COPY video_window_server/ ./
RUN dart compile exe bin/main.dart -o bin/server

FROM debian:bookworm-slim
COPY --from=build /app/bin/server /app/bin/server
COPY --from=build /app/config /app/config
COPY --from=build /app/migrations /app/migrations

WORKDIR /app
EXPOSE 8080

CMD ["./bin/server"]
```

#### 2. Build & Push

```bash
# Build image
docker build -t videowindow/serverpod:latest .

# Tag for registry
docker tag videowindow/serverpod:latest \
  gcr.io/video-window/serverpod:v1.0.0

# Push to registry
docker push gcr.io/video-window/serverpod:v1.0.0
```

#### 3. Deploy

**docker-compose.yml (Production):**
```yaml
version: '3.8'

services:
  serverpod:
    image: gcr.io/video-window/serverpod:v1.0.0
    ports:
      - "8080:8080"
    environment:
      - DB_HOST=${DB_HOST}
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
      # ... other env vars
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

---

### Option 2: Cloud Platforms

#### AWS Elastic Beanstalk

```bash
# Install EB CLI
pip install awsebcli

# Initialize
eb init -p docker video-window-api

# Create environment
eb create prod-env \
  --instance-type t3.medium \
  --database.engine postgres \
  --database.size 10

# Deploy
eb deploy
```

#### Google Cloud Run

```bash
# Deploy to Cloud Run
gcloud run deploy video-window-api \
  --image gcr.io/video-window/serverpod:v1.0.0 \
  --platform managed \
  --region us-east1 \
  --allow-unauthenticated \
  --set-env-vars DB_HOST=$DB_HOST,DB_USER=$DB_USER
```

---

## Database Migration in Production

### Safe Migration Process

```bash
# 1. Backup database
pg_dump -h $DB_HOST -U $DB_USER $DB_NAME \
  > backup_$(date +%Y%m%d_%H%M%S).sql

# 2. Test migration in staging
serverpod migrate --env staging

# 3. Verify staging
curl https://staging-api.videowindow.com/health

# 4. Apply to production
serverpod migrate --env production

# 5. Verify production
curl https://api.videowindow.com/health
```

---

## Monitoring & Health Checks

### Health Endpoint

```dart
// endpoints/health_endpoint.dart
class HealthEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;
  
  Future<HealthResponse> check(Session session) async {
    final checks = {
      'database': await _checkDatabase(session),
      'redis': await _checkRedis(session),
      's3': await _checkS3(),
    };
    
    final healthy = checks.values.every((v) => v);
    
    return HealthResponse(
      status: healthy ? 'healthy' : 'degraded',
      timestamp: DateTime.now(),
      checks: checks,
    );
  }
  
  Future<bool> _checkDatabase(Session session) async {
    try {
      await session.db.query('SELECT 1');
      return true;
    } catch (_) {
      return false;
    }
  }
}
```

### Load Balancer Health Check

```nginx
# nginx.conf
upstream serverpod {
  server serverpod-1:8080;
  server serverpod-2:8080;
}

server {
  listen 443 ssl;
  server_name api.videowindow.com;
  
  ssl_certificate /etc/ssl/certs/videowindow.crt;
  ssl_certificate_key /etc/ssl/private/videowindow.key;
  
  location / {
    proxy_pass http://serverpod;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }
  
  location /health {
    proxy_pass http://serverpod/health;
    access_log off;
  }
}
```

---

## Logging & Monitoring

### CloudWatch Logs (AWS)

```dart
import 'package:logging/logging.dart';

final logger = Logger('VideoWindow');

logger.info('User signed in', {
  'userId': userId,
  'method': 'email_otp',
  'timestamp': DateTime.now().toIso8601String(),
});
```

### Application Metrics

```dart
// Emit custom metrics
await CloudWatch.putMetric(
  namespace: 'VideoWindow/API',
  metricName: 'SignInAttempts',
  value: 1,
  dimensions: {'Method': 'email_otp'},
);
```

---

## Scaling Strategy

### Horizontal Scaling

```bash
# AWS Auto Scaling Group
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name video-window-api-asg \
  --min-size 2 \
  --max-size 10 \
  --desired-capacity 2 \
  --target-group-arns $TARGET_GROUP_ARN
```

### Database Connection Pooling

```yaml
# config/production.yaml
database:
  maxConnections: 20
  idleTimeout: 600  # 10 minutes
```

---

## Rollback Procedure

### Quick Rollback

```bash
# Docker
docker service update \
  --image gcr.io/video-window/serverpod:v0.9.0 \
  video-window-api

# Elastic Beanstalk
eb deploy --version v0.9.0

# Cloud Run
gcloud run services update video-window-api \
  --image gcr.io/video-window/serverpod:v0.9.0
```

---

## Security Hardening

### 1. Firewall Rules

```bash
# Only allow load balancer access
ufw allow from $LOAD_BALANCER_IP to any port 8080
ufw deny 8080
```

### 2. Secret Rotation

```bash
# Rotate JWT secret
NEW_JWT_SECRET=$(openssl rand -hex 32)

# Update environment
kubectl set env deployment/serverpod JWT_SECRET=$NEW_JWT_SECRET

# Force restart
kubectl rollout restart deployment/serverpod
```

### 3. SSL/TLS

```yaml
server:
  publicScheme: https
  ssl:
    enabled: true
    certificate: /etc/ssl/certs/videowindow.crt
    key: /etc/ssl/private/videowindow.key
```

---

## Troubleshooting

### Issue: High Database Connection Count
**Solution:** Tune connection pool
```yaml
database:
  maxConnections: 10  # Reduce per instance
```

### Issue: Memory Leaks
**Solution:** Monitor and restart
```bash
# Kubernetes
kubectl top pods
kubectl delete pod serverpod-xyz  # Triggers recreation
```

---

## Related Documentation

- **Setup:** [01-setup-installation.md](./01-setup-installation.md)
- **Database:** [04-database-migrations.md](./04-database-migrations.md)
- **Architecture:** `../../architecture/serverpod-integration-guide.md`

---

**Key Takeaway:** Always test in staging, backup before migrations, and have a rollback plan ready.
