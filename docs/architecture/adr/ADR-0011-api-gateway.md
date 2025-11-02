# ADR-0011: API Gateway Implementation

**Status:** Accepted
**Date:** 2025-10-14
**Decision Made By:** Architect Agent
**Impacts:** Backend architecture, service communication, routing, security

## Context

The Video Window platform currently exposes services directly through Serverpod endpoints. As the platform scales, we need a centralized API Gateway to:

1. Provide unified entry point for all client requests
2. Enable service decomposition without breaking clients
3. Implement cross-cutting concerns (authentication, rate limiting, logging)
4. Support protocol translation and request routing
5. Enable gradual service migration and versioning

Current challenges:
- Tight coupling between clients and service endpoints
- Duplicate authentication/authorization logic across services
- No centralized request transformation or validation
- Difficult to implement consistent rate limiting and monitoring
- Service boundaries are not well-defined

## Decision

Implement an API Gateway using a custom Serverpod-based solution that provides:

1. **Centralized Routing** - Route requests to appropriate microservices
2. **Authentication & Authorization** - Unified security layer
3. **Rate Limiting** - Per-client and per-endpoint throttling
4. **Request Transformation** - Protocol translation and payload normalization
5. **Monitoring & Logging** - Centralized observability
6. **Circuit Breaking** - Fault tolerance and service protection

## Architecture

### Components

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Mobile App    │    │   Web Client     │    │  External APIs  │
└─────────┬───────┘    └─────────┬────────┘    └─────────┬───────┘
          │                      │                       │
          └──────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │      API Gateway          │
                    │  (Serverpod Service)      │
                    └─────────────┬─────────────┘
                                 │
          ┌──────────────────────┼──────────────────────┐
          │                      │                      │
    ┌─────▼─────┐          ┌─────▼─────┐        ┌─────▼─────┐
    │ Auth Svc  │          │ Auction   │        │ Payment   │
    │           │          │ Service   │        │ Service   │
    └───────────┘          └───────────┘        └───────────┘
```

### Gateway Services

1. **Route Manager**
   - Path-based routing configuration
   - Service discovery integration
   - Load balancing across service instances

2. **Auth Middleware**
   - JWT token validation
   - User session management
   - Permission-based access control

3. **Rate Limiter**
   - Token bucket algorithm
   - Redis-based distributed counting
   - Configurable limits per route/client

4. **Request Transformer**
   - Protocol translation (REST ↔ gRPC)
   - Payload validation and normalization
   - Request/response enrichment

5. **Circuit Breaker**
   - Service health monitoring
   - Automatic failover
   - Degraded service responses

## Implementation Details

### 1. Gateway Configuration

```yaml
# config/gateway.yaml
routes:
  - path: "/api/v1/auth/**"
    service: "auth-service"
    methods: ["POST", "PUT", "DELETE"]
    auth_required: false
    rate_limit: 10/minute

  - path: "/api/v1/auctions/**"
    service: "auction-service"
    methods: ["GET", "POST", "PUT", "DELETE"]
    auth_required: true
    rate_limit: 100/minute

  - path: "/api/v1/payments/**"
    service: "payment-service"
    methods: ["POST", "PUT"]
    auth_required: true
    rate_limit: 20/minute
    circuit_breaker:
      threshold: 5
      timeout: 30s
```

### 2. Service Registration

```dart
// Gateway service endpoint
@Endpoint()
class GatewayService {

  @EndpointMethod('get', '/api/v1/{path*}')
  Future<Map<String, dynamic>> proxyRequest(
    Session session,
    String path,
    Map<String, dynamic> requestBody,
    Map<String, String> headers,
  ) async {
    // Route to appropriate service
  }
}
```

### 3. Authentication Middleware

```dart
class AuthMiddleware {
  Future<bool> authenticate(
    Session session,
    String path,
    Map<String, String> headers,
  ) async {
    final token = headers['authorization'];
    if (token == null) return false;

    // Validate JWT token
    final user = await _validateToken(token);
    if (user == null) return false;

    // Store user context for downstream services
    session.set('user', user);
    return true;
  }
}
```

### 4. Rate Limiting

```dart
class RateLimiter {
  Future<bool> allowRequest(
    String clientId,
    String route,
    int limit,
    Duration window,
  ) async {
    final key = 'rate_limit:$clientId:$route';
    final count = await redis.incr(key);

    if (count == 1) {
      await redis.expire(key, window.inSeconds);
    }

    return count <= limit;
  }
}
```

### 5. Circuit Breaker

```dart
class CircuitBreaker {
  final String serviceName;
  int failureCount = 0;
  DateTime? lastFailureTime;
  CircuitState state = CircuitState.closed;

  Future<T?> execute<T>(Future<T> Function() operation) async {
    if (state == CircuitState.open) {
      if (_shouldAttemptReset()) {
        state = CircuitState.halfOpen;
      } else {
        throw CircuitBreakerOpenException();
      }
    }

    try {
      final result = await operation();
      _onSuccess();
      return result;
    } catch (error) {
      _onFailure();
      rethrow;
    }
  }
}
```

## Service Boundaries

Based on the existing OpenAPI specification, we define the following service boundaries:

### 1. Authentication Service
- **Responsibility**: User registration, login, token management
- **Endpoints**: `/auth/*`
- **Data**: User profiles, credentials, sessions

### 2. User Service
- **Responsibility**: User profile management, preferences
- **Endpoints**: `/users/*`
- **Data**: User information, settings, avatars

### 3. Auction Service
- **Responsibility**: Auction creation, management, bidding
- **Endpoints**: `/auctions/*`, `/bids/*`
- **Data**: Auctions, bids, categories

### 4. Payment Service
- **Responsibility**: Payment processing, transactions
- **Endpoints**: `/payments/*`
- **Data**: Payments, orders, transactions

### 5. Media Service
- **Responsibility**: Video upload, processing, streaming
- **Endpoints**: `/videos/*`, `/media/*`
- **Data**: Video files, thumbnails, metadata

### 6. Notification Service
- **Responsibility**: Real-time notifications, webhooks
- **Endpoints**: `/notifications/*`, `/webhooks/*`
- **Data**: Events, notifications, webhooks

## Migration Strategy

### Phase 1: Gateway Implementation (Week 1-2)
1. Create gateway service structure
2. Implement basic routing and proxying
3. Add authentication middleware
4. Deploy alongside existing services

### Phase 2: Service Migration (Week 3-4)
1. Migrate authentication endpoints
2. Update client configurations
3. Implement rate limiting
4. Add monitoring and logging

### Phase 3: Advanced Features (Week 5-6)
1. Implement circuit breakers
2. Add request transformation
3. Enable service discovery
4. Performance optimization

### Phase 4: Full Migration (Week 7-8)
1. Migrate all services
2. Remove direct service access
3. Optimize performance
4. Document new architecture

## Benefits

1. **Single Entry Point**: Simplified client configuration
2. **Cross-cutting Concerns**: Centralized auth, rate limiting, logging
3. **Service Isolation**: Better fault tolerance and resilience
4. **Protocol Flexibility**: Support for multiple communication patterns
5. **Observability**: Centralized monitoring and tracing
6. **Security**: Enhanced security posture with unified controls

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Performance bottleneck | High | Implement caching, connection pooling, horizontal scaling |
| Single point of failure | High | Deploy multiple instances, health checks, auto-scaling |
| Configuration complexity | Medium | Use feature flags, gradual rollout, comprehensive testing |
| Service discovery latency | Medium | Cache service locations, implement health checks |

## Monitoring Requirements

1. **Request Metrics**
   - Request rate, latency, error rates per route
   - Service response times and availability
   - Circuit breaker state changes

2. **Business Metrics**
   - Authentication success/failure rates
   - API usage patterns by client
   - Rate limiting enforcement statistics

3. **Infrastructure Metrics**
   - Gateway instance health and resource usage
   - Redis connection health and performance
   - Network latency and throughput

## Alternatives Considered

1. **AWS API Gateway**
   - Pros: Managed service, auto-scaling
   - Cons: Vendor lock-in, limited customization, higher cost

2. **Kong/Nginx**
   - Pros: Battle-tested, high performance
   - Cons: Separate infrastructure, Dart integration complexity

3. **Envoy Proxy**
   - Pros: Advanced features, cloud-native
   - Cons: Complex configuration, learning curve

Chosen solution balances integration with existing Serverpod infrastructure while providing required features.

## Consequences

- All client requests will route through the gateway
- Services need to be registered with the gateway
- Authentication tokens become gateway-managed
- Rate limiting and monitoring become centralized
- Service boundaries become more explicit
- Development workflow includes gateway configuration

## Future Considerations

1. **GraphQL Support**: Add GraphQL gateway capabilities
2. **WebSocket Proxying**: Support real-time communication
3. **API Versioning**: Implement version-aware routing
4. **Edge Deployment**: Deploy gateway at CDN edge locations
5. **AI-powered Routing**: Intelligent request routing based on ML

---

**Related ADRs:**
- ADR-002: Event-Driven Architecture Foundation
- ADR-007: State Management: BLoC Pattern
- ADR-008: Database Architecture Strategy

**Related Documentation:**
- [API Gateway Implementation Guide](../api-gateway-routing-design.md)
- [Service Migration Guide](../project-structure-implementation.md)
- [Gateway Configuration Reference](../system-integration-maps.md)