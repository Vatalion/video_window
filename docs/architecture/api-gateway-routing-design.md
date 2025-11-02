# API Gateway Routing Design

**Effective Date:** 2025-10-14
**Version:** 1.0
**Architecture:** Microservices with API Gateway

## Overview

This document defines the routing rules, service boundaries, and configuration for the Video Window API Gateway. The design provides a unified entry point for all client requests while maintaining clear service separation and enabling future scalability.

## Service Architecture

```
Client Applications
       │
       ▼
┌─────────────────┐
│   API Gateway   │ ← Entry Point
│  (Port 8080)    │
└─────────┬───────┘
          │
    ┌─────┴─────┐
    │ Service   │
    │ Registry  │
    └─────┬─────┘
          │
    ┌─────┴─────────────────────────────────────┐
    │                                           │
┌───▼────┐    ┌───────┐    ┌──────────┐    ┌───▼──────┐
│ Auth   │    │ User  │    │ Auction  │    │ Payment  │
│(8081)  │    │(8082) │    │ (8083)   │    │ (8084)   │
└────────┘    └───────┘    └──────────┘    └──────────┘
```

## Service Boundaries

### 1. Authentication Service (Port 8081)
**Responsibility**: User authentication, token management, security

**Endpoints:**
```
POST   /api/v1/auth/register
POST   /api/v1/auth/login
POST   /api/v1/auth/refresh
POST   /api/v1/auth/logout
POST   /api/v1/auth/forgot-password
POST   /api/v1/auth/reset-password
GET    /api/v1/auth/verify-email/{token}
```

**Data Ownership:**
- User credentials (passwords, tokens)
- Authentication sessions
- Security configurations
- Email verification tokens

### 2. User Service (Port 8082)
**Responsibility**: User profile management, preferences, social features

**Endpoints:**
```
GET    /api/v1/users/me
PUT    /api/v1/users/me
GET    /api/v1/users/{userId}
PUT    /api/v1/users/{userId}/follow
DELETE /api/v1/users/{userId}/follow
GET    /api/v1/users/{userId}/followers
GET    /api/v1/users/{userId}/following
PUT    /api/v1/users/me/preferences
POST   /api/v1/users/me/avatar
```

**Data Ownership:**
- User profiles and metadata
- User preferences and settings
- Social connections (followers/following)
- User-generated content (profiles, bios)

### 3. Auction Service (Port 8083)
**Responsibility**: Auction creation, management, bidding logic

**Endpoints:**
```
GET    /api/v1/auctions
POST   /api/v1/auctions
GET    /api/v1/auctions/{auctionId}
PUT    /api/v1/auctions/{auctionId}
DELETE /api/v1/auctions/{auctionId}
GET    /api/v1/auctions/{auctionId}/bids
POST   /api/v1/auctions/{auctionId}/bids
PUT    /api/v1/auctions/{auctionId}/watchlist
DELETE /api/v1/auctions/{auctionId}/watchlist
GET    /api/v1/auctions/categories
GET    /api/v1/auctions/search
```

**Data Ownership:**
- Auction configurations and rules
- Bidding history and current bids
- Auction categories and taxonomies
- Watchlist and user interactions

### 4. Payment Service (Port 8084)
**Responsibility**: Payment processing, transactions, financial operations

**Endpoints:**
```
POST   /api/v1/payments/create-intent
POST   /api/v1/payments/{paymentId}/confirm
POST   /api/v1/payments/{paymentId}/cancel
GET    /api/v1/payments/{paymentId}
GET    /api/v1/payments/methods
POST   /api/v1/payments/methods
PUT    /api/v1/payments/methods/{methodId}
DELETE /api/v1/payments/methods/{methodId}
GET    /api/v1/payments/transactions
```

**Data Ownership:**
- Payment transactions and records
- Payment methods and customer data
- Financial reconciliations
- Refund and dispute records

### 5. Media Service (Port 8085)
**Responsibility**: Video upload, processing, streaming, storage

**Endpoints:**
```
POST   /api/v1/media/upload
GET    /api/v1/media/{mediaId}
GET    /api/v1/media/{mediaId}/stream
GET    /api/v1/media/{mediaId}/thumbnail
PUT    /api/v1/media/{mediaId}/metadata
DELETE /api/v1/media/{mediaId}
POST   /api/v1/media/{mediaId}/transcode
GET    /api/v1/media/presigned-url
```

**Data Ownership:**
- Video files and metadata
- Transcoding jobs and statuses
- Storage locations and CDN configurations
- Media processing workflows

### 6. Notification Service (Port 8086)
**Responsibility**: Real-time notifications, email, push notifications

**Endpoints:**
```
GET    /api/v1/notifications
PUT    /api/v1/notifications/{notificationId}/read
POST   /api/v1/notifications/preferences
GET    /api/v1/notifications/preferences
POST   /api/v1/webhooks/stripe
POST   /api/v1/webhooks/custom
GET    /api/v1/webhooks/config
```

**Data Ownership:**
- Notification templates and content
- User notification preferences
- Webhook configurations and logs
- Delivery status and analytics

### 7. Order Service (Port 8087)
**Responsibility**: Order management, fulfillment, shipping

**Endpoints:**
```
GET    /api/v1/orders
POST   /api/v1/orders
GET    /api/v1/orders/{orderId}
PUT    /api/v1/orders/{orderId}/status
POST   /api/v1/orders/{orderId}/tracking
GET    /api/v1/orders/{orderId}/tracking
PUT    /api/v1/orders/{orderId}/shipping
```

**Data Ownership:**
- Order records and status
- Shipping information and tracking
- Order fulfillment workflows
- Customer order history

## Gateway Routing Configuration

### Primary Routing Rules

```yaml
# config/gateway/routes.yaml
routes:
  # Authentication routes (no auth required)
  - name: "auth-register"
    path: "/api/v1/auth/register"
    method: "POST"
    service: "auth-service"
    port: 8081
    auth_required: false
    rate_limit: 5/minute
    timeout: 10s

  - name: "auth-login"
    path: "/api/v1/auth/login"
    method: "POST"
    service: "auth-service"
    port: 8081
    auth_required: false
    rate_limit: 10/minute
    timeout: 10s

  - name: "auth-refresh"
    path: "/api/v1/auth/refresh"
    method: "POST"
    service: "auth-service"
    port: 8081
    auth_required: false
    rate_limit: 20/minute
    timeout: 5s

  - name: "auth-endpoints"
    path: "/api/v1/auth/**"
    method: "*"
    service: "auth-service"
    port: 8081
    auth_required: false
    rate_limit: 10/minute
    timeout: 10s

  # User management routes
  - name: "user-profile"
    path: "/api/v1/users/me"
    method: "GET"
    service: "user-service"
    port: 8082
    auth_required: true
    rate_limit: 100/minute
    timeout: 5s

  - name: "user-update"
    path: "/api/v1/users/me"
    method: "PUT"
    service: "user-service"
    port: 8082
    auth_required: true
    rate_limit: 50/minute
    timeout: 10s

  - name: "user-routes"
    path: "/api/v1/users/**"
    method: "*"
    service: "user-service"
    port: 8082
    auth_required: true
    rate_limit: 100/minute
    timeout: 10s

  # Auction routes
  - name: "auction-list"
    path: "/api/v1/auctions"
    method: "GET"
    service: "auction-service"
    port: 8083
    auth_required: false
    rate_limit: 200/minute
    timeout: 15s
    cache_ttl: 30s

  - name: "auction-create"
    path: "/api/v1/auctions"
    method: "POST"
    service: "auction-service"
    port: 8083
    auth_required: true
    rate_limit: 10/minute
    timeout: 30s

  - name: "auction-detail"
    path: "/api/v1/auctions/{auctionId}"
    method: "GET"
    service: "auction-service"
    port: 8083
    auth_required: false
    rate_limit: 300/minute
    timeout: 10s
    cache_ttl: 60s

  - name: "auction-manage"
    path: "/api/v1/auctions/{auctionId}"
    method: "PUT|DELETE"
    service: "auction-service"
    port: 8083
    auth_required: true
    rate_limit: 20/minute
    timeout: 15s

  - name: "auction-bids"
    path: "/api/v1/auctions/{auctionId}/bids"
    method: "*"
    service: "auction-service"
    port: 8083
    auth_required: true
    rate_limit: 100/minute
    timeout: 10s

  - name: "auction-routes"
    path: "/api/v1/auctions/**"
    method: "*"
    service: "auction-service"
    port: 8083
    auth_required: true
    rate_limit: 200/minute
    timeout: 15s

  # Payment routes
  - name: "payment-create"
    path: "/api/v1/payments/create-intent"
    method: "POST"
    service: "payment-service"
    port: 8084
    auth_required: true
    rate_limit: 20/minute
    timeout: 15s
    circuit_breaker:
      threshold: 3
      timeout: 30s

  - name: "payment-confirm"
    path: "/api/v1/payments/{paymentId}/confirm"
    method: "POST"
    service: "payment-service"
    port: 8084
    auth_required: true
    rate_limit: 30/minute
    timeout: 20s
    circuit_breaker:
      threshold: 3
      timeout: 30s

  - name: "payment-routes"
    path: "/api/v1/payments/**"
    method: "*"
    service: "payment-service"
    port: 8084
    auth_required: true
    rate_limit: 50/minute
    timeout: 15s
    circuit_breaker:
      threshold: 5
      timeout: 30s

  # Media routes
  - name: "media-upload"
    path: "/api/v1/media/upload"
    method: "POST"
    service: "media-service"
    port: 8085
    auth_required: true
    rate_limit: 10/minute
    timeout: 60s
    max_payload_size: 100MB

  - name: "media-stream"
    path: "/api/v1/media/{mediaId}/stream"
    method: "GET"
    service: "media-service"
    port: 8085
    auth_required: true
    rate_limit: 1000/minute
    timeout: 5s
    cache_ttl: 300s

  - name: "media-routes"
    path: "/api/v1/media/**"
    method: "*"
    service: "media-service"
    port: 8085
    auth_required: true
    rate_limit: 200/minute
    timeout: 30s

  # Order routes
  - name: "order-routes"
    path: "/api/v1/orders/**"
    method: "*"
    service: "order-service"
    port: 8087
    auth_required: true
    rate_limit: 100/minute
    timeout: 15s

  # Notification routes
  - name: "notification-routes"
    path: "/api/v1/notifications/**"
    method: "*"
    service: "notification-service"
    port: 8086
    auth_required: true
    rate_limit: 200/minute
    timeout: 10s

  # Webhook routes (external services)
  - name: "stripe-webhook"
    path: "/api/v1/webhooks/stripe"
    method: "POST"
    service: "notification-service"
    port: 8086
    auth_required: false
    rate_limit: 1000/minute
    timeout: 10s
    webhook_signature: true

  # Fallback route
  - name: "fallback"
    path: "/api/v1/**"
    method: "*"
    service: "fallback-service"
    port: 8088
    auth_required: false
    rate_limit: 100/minute
    timeout: 5s
```

## Service Discovery Configuration

```yaml
# config/gateway/services.yaml
services:
  auth-service:
    host: "auth-service"
    port: 8081
    health_check: "/health"
    protocol: "http"
    timeout: 5s
    retries: 3

  user-service:
    host: "user-service"
    port: 8082
    health_check: "/health"
    protocol: "http"
    timeout: 5s
    retries: 3

  auction-service:
    host: "auction-service"
    port: 8083
    health_check: "/health"
    protocol: "http"
    timeout: 10s
    retries: 2

  payment-service:
    host: "payment-service"
    port: 8084
    health_check: "/health"
    protocol: "http"
    timeout: 15s
    retries: 3

  media-service:
    host: "media-service"
    port: 8085
    health_check: "/health"
    protocol: "http"
    timeout: 30s
    retries: 2

  notification-service:
    host: "notification-service"
    port: 8086
    health_check: "/health"
    protocol: "http"
    timeout: 5s
    retries: 3

  order-service:
    host: "order-service"
    port: 8087
    health_check: "/health"
    protocol: "http"
    timeout: 10s
    retries: 3
```

## Request Flow Examples

### 1. User Registration Flow
```
Client → Gateway → Auth Service → Database
        │          │
        │          └─ Create user, generate tokens
        └─ Return auth response
```

### 2. Auction Bidding Flow
```
Client → Gateway → Auth Check → Auction Service → Event Bus
        │          │            │                  │
        │          │            └─ Process bid     │
        │          │                               └─ Notify bidders
        │          └─ Validate JWT token
        └─ Return bid confirmation
```

### 3. Payment Processing Flow
```
Client → Gateway → Auth Check → Payment Service → Stripe → Event Bus
        │          │            │                 │         │
        │          │            └─ Create intent │         │
        │          │                              └─ Process payment
        │          └─ Validate permissions                  └─ Update order status
        └─ Return payment confirmation
```

## Load Balancing Strategy

### Round Robin Load Balancing
```dart
class LoadBalancer {
  final Map<String, List<ServiceInstance>> _serviceInstances = {};
  final Map<String, int> _currentIndexes = {};

  ServiceInstance getNextInstance(String serviceName) {
    final instances = _serviceInstances[serviceName];
    if (instances == null || instances.isEmpty) {
      throw ServiceUnavailableException(serviceName);
    }

    final currentIndex = _currentIndexes[serviceName] ?? 0;
    final instance = instances[currentIndex % instances.length];
    _currentIndexes[serviceName] = currentIndex + 1;

    // Check instance health
    if (!instance.isHealthy) {
      // Try next healthy instance
      return getNextHealthyInstance(serviceName, instances);
    }

    return instance;
  }
}
```

### Health Check Implementation
```dart
class HealthChecker {
  Future<bool> checkServiceHealth(ServiceInstance instance) async {
    try {
      final response = await http.get(
        Uri.parse('${instance.baseUrl}/health'),
      ).timeout(Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (error) {
      return false;
    }
  }

  void startHealthChecks() {
    Timer.periodic(Duration(seconds: 30), (timer) async {
      for (final serviceName in _serviceInstances.keys) {
        final instances = _serviceInstances[serviceName]!;
        for (final instance in instances) {
          instance.isHealthy = await checkServiceHealth(instance);
        }
      }
    });
  }
}
```

## Circuit Breaker Configuration

```yaml
# config/gateway/circuit-breakers.yaml
circuit_breakers:
  payment-service:
    failure_threshold: 3
    timeout: 30s
    half_open_max_calls: 5
    success_threshold: 2

  media-service:
    failure_threshold: 5
    timeout: 60s
    half_open_max_calls: 3
    success_threshold: 3

  auction-service:
    failure_threshold: 4
    timeout: 45s
    half_open_max_calls: 10
    success_threshold: 3
```

## Rate Limiting Configuration

```yaml
# config/gateway/rate-limiting.yaml
rate_limits:
  global:
    requests_per_minute: 10000
    burst_size: 100

  per_user:
    authenticated:
      requests_per_minute: 1000
      burst_size: 50
    anonymous:
      requests_per_minute: 100
      burst_size: 20

  per_endpoint:
    "/api/v1/auth/login":
      requests_per_minute: 10
      burst_size: 5
    "/api/v1/auctions":
      requests_per_minute: 200
      burst_size: 50
    "/api/v1/payments/create-intent":
      requests_per_minute: 20
      burst_size: 10
```

## Security Configuration

```yaml
# config/gateway/security.yaml
security:
  authentication:
    jwt_secret: "${JWT_SECRET}"
    token_expiry: 3600s
    refresh_token_expiry: 604800s

  cors:
    allowed_origins:
      - "https://app.videomarketplace.com"
      - "https://www.videomarketplace.com"
    allowed_methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allowed_headers: ["Content-Type", "Authorization"]
    max_age: 86400

  https:
    redirect_http: true
    hsts_enabled: true
    hsts_max_age: 31536000

  headers:
    security_headers:
      x_frame_options: "DENY"
      x_content_type_options: "nosniff"
      x_xss_protection: "1; mode=block"
      strict_transport_security: "max-age=31536000; includeSubDomains"
```

## Monitoring and Logging

```yaml
# config/gateway/monitoring.yaml
monitoring:
  metrics:
    enabled: true
    interval: 10s
    retention: 7d

  logging:
    level: "info"
    format: "json"
    include_request_body: false
    include_response_body: false

  tracing:
    enabled: true
    sampling_rate: 0.1
    jaeger_endpoint: "http://jaeger:14268/api/traces"

  alerts:
    high_error_rate:
      threshold: 5%
      window: 5m

    high_latency:
      threshold: 1000ms
      window: 5m

    service_down:
      threshold: 0
      window: 30s
```

## Migration Strategy

### Phase 1: Shadow Mode
- Deploy gateway alongside existing services
- Route traffic to both gateway and direct services
- Compare responses and performance
- Fix configuration issues

### Phase 2: Gradual Rollout
- Route 10% of traffic through gateway
- Monitor performance and errors
- Gradually increase to 50%, then 100%

### Phase 3: Full Migration
- Remove direct service access
- Update all client configurations
- Decommission direct service endpoints

This routing design provides a solid foundation for scaling the Video Window platform while maintaining security, performance, and reliability.

---

**Related Documents:**
- [ADR-0011: API Gateway Implementation](adr/ADR-0011-api-gateway.md)
- [API Gateway Implementation Guide](system-integration-maps.md)
- [Service Migration Guide](project-structure-implementation.md)