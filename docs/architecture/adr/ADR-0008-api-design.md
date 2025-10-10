# ADR-0008: API Design: Serverpod RPC + REST

**Date:** 2025-10-09
**Status:** Accepted
**Decider(s):** Technical Lead, API Architecture Team
**Reviewers:** Development Team, QA Team

## Context
The video marketplace platform requires a comprehensive API strategy that supports real-time auction functionality, secure payment processing, and efficient mobile client communication. We need to design an API architecture that provides optimal performance, developer experience, and maintainability while supporting our Flutter + Serverpod stack.

## Decision
Adopt a hybrid API approach combining Serverpod's native RPC for core application functionality with RESTful endpoints for external integrations and webhooks. This provides type safety for client-server communication while maintaining compatibility with external systems.

## Options Considered

1. **Option A** - Pure Serverpod RPC
   - Pros: Type safety, automatic client generation, real-time support
   - Cons: Limited external integration options, proprietary protocol
   - Risk: Vendor lock-in, third-party integration complexity

2. **Option B** - Pure REST API
   - Pros: Universal compatibility, extensive tooling, standardized
   - Cons: Manual client generation, less type safety, real-time limitations
   - Risk: Development overhead, performance limitations

3. **Option C** - GraphQL API
   - Pros: Flexible queries, single endpoint, strong typing
   - Cons: Complex setup, caching challenges, learning curve
   - Risk: Over-engineering for current requirements

4. **Option D** - Hybrid RPC + REST (Chosen)
   - Pros: Best of both worlds, optimal performance, flexibility
   - Cons: Two API styles to maintain, documentation complexity
   - Risk: Inconsistent patterns if not properly governed

## Decision Outcome
Chose Option D: Hybrid RPC + REST approach. This provides:
- Type-safe RPC for Flutter client communication
- RESTful APIs for external integrations (Stripe, webhooks, etc.)
- Real-time WebSocket support via Serverpod
- Standard HTTP tooling and monitoring

## Consequences

- **Positive:**
  - Type safety for mobile client communication
  - Real-time auction updates via WebSocket
  - External system compatibility via REST
  - Optimal performance for different use cases
  - Automatic client generation reduces bugs
  - Comprehensive tooling support

- **Negative:**
  - Two API patterns to maintain
  - Documentation complexity
  - Testing overhead for both styles
  - Potential for inconsistent patterns
  - Learning curve for team members

- **Neutral:**
  - API governance requirements
  - Documentation generation needs
  - Monitoring and observability setup
  - Version management complexity

## API Architecture Overview

### Serverpod RPC APIs
Used for core Flutter application functionality with type-safe communication.

```dart
// Serverpod Endpoint Definition
@Endpoint()
class AuctionEndpoint {
  Future<List<Auction>> getActiveAuctions(Session session) async {
    // Implementation
  }

  Future<AuctionBid> placeBid(Session session, AuctionBidRequest request) async {
    // Implementation
  }

  Stream<AuctionUpdate> getAuctionUpdates(Session session, String auctionId) async* {
    // Real-time updates
  }
}
```

### REST APIs
Used for external integrations, webhooks, and third-party access.

```yaml
# OpenAPI Specification
paths:
  /api/v1/auctions/{id}:
    get:
      summary: Get auction details
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: Auction details
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Auction'

  /api/v1/webhooks/stripe:
    post:
      summary: Stripe webhook handler
      security:
        - ApiKeyAuth: []
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/StripeEvent'
```

## API Design Principles

### 1. Consistent Naming Conventions
- **RPC**: PascalCase methods, descriptive parameter names
- **REST**: kebab-case endpoints, camelCase response fields
- **Models**: PascalCase class names, camelCase properties

### 2. Error Handling
```dart
// RPC Error Handling
class ApiException implements Exception {
  final String code;
  final String message;
  final int statusCode;

  const ApiException(this.code, this.message, this.statusCode);
}

// REST Error Response
{
  "error": {
    "code": "AUCTION_NOT_FOUND",
    "message": "Auction with ID 'xxx' not found",
    "timestamp": "2025-10-09T10:30:00Z",
    "requestId": "req_123456789"
  }
}
```

### 3. Pagination
```dart
// RPC Pagination
class PaginatedResponse<T> {
  final List<T> items;
  final int totalCount;
  final int pageSize;
  final int currentPage;
  final bool hasNextPage;
}

// REST Pagination
{
  "data": [...],
  "pagination": {
    "total": 100,
    "page": 1,
    "pageSize": 20,
    "hasNext": true,
    "hasPrev": false
  }
}
```

## API Endpoint Categories

### 1. Authentication & Authorization
```dart
// RPC Endpoints
@Endpoint()
class AuthEndpoint {
  Future<AuthResponse> signIn(Session session, SignInRequest request);
  Future<AuthResponse> signUp(Session session, SignUpRequest request);
  Future<void> signOut(Session session);
  Future<User> getCurrentUser(Session session);
}

// REST Endpoints
POST   /api/v1/auth/refresh
POST   /api/v1/auth/logout
GET    /api/v1/auth/me
```

### 2. Auction Management
```dart
// RPC Endpoints
@Endpoint()
class AuctionEndpoint {
  Future<List<Auction>> getActiveAuctions(Session session, AuctionFilters filters);
  Future<Auction> getAuctionDetails(Session session, String auctionId);
  Future<AuctionBid> placeBid(Session session, PlaceBidRequest request);
  Stream<AuctionUpdate> getAuctionUpdates(Session session, String auctionId);
  Future<Auction> createAuction(Session session, CreateAuctionRequest request);
}

// REST Endpoints
GET    /api/v1/auctions
GET    /api/v1/auctions/{id}
POST   /api/v1/auctions/{id}/bids
GET    /api/v1/auctions/{id}/bids
```

### 3. Payment Processing
```dart
// RPC Endpoints
@Endpoint()
class PaymentEndpoint {
  Future<PaymentIntent> createPaymentIntent(Session session, CreatePaymentRequest request);
  Future<PaymentStatus> getPaymentStatus(Session session, String paymentId);
  Future<void> confirmPayment(Session session, ConfirmPaymentRequest request);
}

// REST Endpoints (Stripe Integration)
POST   /api/v1/payments/create
GET    /api/v1/payments/{id}/status
POST   /api/v1/webhooks/stripe
```

### 4. User Management
```dart
// RPC Endpoints
@Endpoint()
class UserEndpoint {
  Future<UserProfile> getProfile(Session session, String userId);
  Future<UserProfile> updateProfile(Session session, UpdateProfileRequest request);
  Future<List<Address>> getAddresses(Session session);
  Future<Address> addAddress(Session session, AddressRequest request);
}

// REST Endpoints
GET    /api/v1/users/{id}
PUT    /api/v1/users/{id}
GET    /api/v1/users/{id}/addresses
POST   /api/v1/users/{id}/addresses
```

## Real-time Communication

### WebSocket Implementation
```dart
@Endpoint()
class RealtimeEndpoint {
  Stream<AuctionUpdate> subscribeToAuction(Session session, String auctionId) async* {
    // Real-time auction updates
  }

  Stream<Notification> getNotifications(Session session) async* {
    // User notifications
  }

  Stream<BidUpdate> subscribeToBids(Session session, String auctionId) async* {
    // Real-time bid updates
  }
}
```

### Client-side Implementation
```dart
class AuctionBloc extends Bloc<AuctionEvent, AuctionState> {
  late StreamSubscription<AuctionUpdate> _auctionSubscription;

  void subscribeToAuction(String auctionId) {
    _auctionSubscription = client.realtime.subscribeToAuction(auctionId).listen(
      (update) => add(AuctionUpdateReceived(update)),
      onError: (error) => add(AuctionSubscriptionError(error)),
    );
  }
}
```

## API Documentation

### 1. Auto-generated Documentation
- Serverpod automatically generates client SDKs
- RPC endpoints documented via code annotations
- REST APIs documented via OpenAPI 3.0 specification

### 2. Interactive Documentation
- Swagger UI for REST API exploration
- Postman collections for external testing
- Code examples in multiple languages

### 3. Version Management
```yaml
# API Versioning Strategy
# RPC: Version at endpoint level
@Endpoint(version: 'v1')
class AuctionEndpointV1 { ... }

@Endpoint(version: 'v2')
class AuctionEndpointV2 { ... }

# REST: Version in URL path
/api/v1/auctions
/api/v2/auctions
```

## Security Implementation

### 1. Authentication
```dart
// RPC Authentication
@Endpoint()
class SecureEndpoint {
  Future<User> getProfile(Session session) async {
    final user = await session.authenticatedUser;
    if (user == null) {
      throw ApiException('UNAUTHORIZED', 'Authentication required', 401);
    }
    return user;
  }
}

// REST Authentication
headers: {
  'Authorization': 'Bearer ${jwtToken}',
  'Content-Type': 'application/json'
}
```

### 2. Rate Limiting
```dart
// Serverpod Rate Limiting
@Endpoint()
class RateLimitedEndpoint {
  @RateLimit(requests: 10, period: Duration(minutes: 1))
  Future<List<Auction>> getAuctions(Session session) async {
    // Implementation
  }
}
```

### 3. Input Validation
```dart
// Request Validation
class PlaceBidRequest {
  @Validate(Required(), Min(1.0))
  final double amount;

  @Validate(Required(), Length(min: 1, max: 1000))
  final String message;

  PlaceBidRequest({required this.amount, required this.message});
}
```

## Testing Strategy

### 1. Unit Testing
```dart
test('placeBid should create valid bid', () async {
  final request = PlaceBidRequest(amount: 100.0, message: 'Test bid');
  final result = await auctionEndpoint.placeBid(mockSession, request);

  expect(result.amount, equals(100.0));
  expect(result.auctionId, equals('test-auction-id'));
});
```

### 2. Integration Testing
```dart
test('full auction flow', () async {
  // Create auction
  final auction = await createTestAuction();

  // Place bid
  final bid = await auctionEndpoint.placeBid(session, PlaceBidRequest(
    amount: 150.0,
    auctionId: auction.id,
  ));

  // Verify bid received
  expect(bid.amount, equals(150.0));
});
```

### 3. Load Testing
```dart
// Simulate concurrent bidding
await Future.wait(List.generate(100, (index) async {
  await auctionEndpoint.placeBid(session, PlaceBidRequest(
    amount: 100.0 + index,
    auctionId: auctionId,
  ));
}));
```

## Monitoring & Observability

### 1. Metrics Collection
```dart
@Endpoint()
class MonitoredEndpoint {
  Future<Auction> getAuction(Session session, String id) async {
    final timer = Metrics.timer('api.auction.get.duration');
    try {
      final result = await auctionService.getAuction(id);
      Metrics.counter('api.auction.get.success').increment();
      return result;
    } catch (e) {
      Metrics.counter('api.auction.get.error').increment();
      rethrow;
    } finally {
      timer.stop();
    }
  }
}
```

### 2. Request Tracing
```dart
@Endpoint()
class TracedEndpoint {
  Future<Auction> processRequest(Session session, String id) async {
    final span = Trace.startSpan('api.auction.process');
    try {
      span.setAttribute('auction.id', id);
      span.setAttribute('user.id', session.authenticatedUserId);

      final result = await auctionService.process(id);

      span.setStatus(Status.ok());
      return result;
    } catch (e) {
      span.setStatus(Status.error(e.toString()));
      rethrow;
    } finally {
      span.end();
    }
  }
}
```

## Implementation Timeline

### Phase 1: Core RPC APIs (Week 1-2)
- [ ] Authentication endpoints
- [ ] User management endpoints
- [ ] Basic auction endpoints
- [ ] Real-time WebSocket setup

### Phase 2: REST APIs (Week 3-4)
- [ ] Stripe webhook handlers
- [ ] External integration endpoints
- [ ] OpenAPI documentation
- [ ] API versioning setup

### Phase 3: Advanced Features (Week 5-6)
- [ ] Rate limiting implementation
- [ ] Advanced filtering and search
- [ ] File upload/download endpoints
- [ ] Comprehensive testing

## Success Metrics
- **Performance**: <100ms median response time for RPC calls
- **Reliability**: 99.9% uptime for all endpoints
- **Developer Experience**: Zero client-server type mismatches
- **Integration**: Successful Stripe webhook processing
- **Real-time**: <50ms WebSocket message delivery
- **Documentation**: 100% API coverage in generated docs

## Related ADRs
- ADR-0002: Flutter + Serverpod Architecture
- ADR-0003: Database Architecture: PostgreSQL + Redis
- ADR-0004: Payment Processing: Stripe Connect Express
- ADR-0007: State Management: BLoC Pattern

## References
- [Serverpod API Documentation](https://serverpod.dev/docs/api)
- [OpenAPI 3.0 Specification](https://swagger.io/specification/)
- [REST API Design Guidelines](https://restfulapi.net/)
- [WebSocket Best Practices](https://websocket.org/)

## Status Updates
- **2025-10-09**: Accepted - API architecture approved
- **2025-10-09**: Implementation planning started
- **TBD**: Core RPC endpoints development
- **TBD**: REST API implementation
- **TBD**: Documentation generation

---

*This ADR establishes a comprehensive API strategy that provides optimal performance and developer experience while supporting both internal and external system integrations.*