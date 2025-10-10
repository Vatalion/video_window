# Architecture Pattern Library

This document provides a comprehensive library of architectural patterns used in the Video Marketplace platform. Each pattern includes implementation guidance, decision criteria, and specific use cases for our Flutter + Serverpod stack.

## Table of Contents

1. [Architectural Patterns](#architectural-patterns)
   - [Modular Monolith with Microservices Path](#modular-monolith-with-microservices-path)
   - [Domain-Driven Design (DDD)](#domain-driven-design-ddd)
   - [CQRS with Event Sourcing](#cqrs-with-event-sourcing)
   - [API Gateway Pattern](#api-gateway-pattern)

2. [Design Patterns](#design-patterns)
   - [Repository Pattern](#repository-pattern)
   - [Unit of Work Pattern](#unit-of-work-pattern)
   - [Factory Pattern](#factory-pattern)
   - [Observer Pattern](#observer-pattern)
   - [Strategy Pattern](#strategy-pattern)
   - [Decorator Pattern](#decorator-pattern)

3. [Data Patterns](#data-patterns)
   - [Database per Service](#database-per-service)
   - [Eventual Consistency](#eventual-consistency)
   - [Cache-Aside Pattern](#cache-aside-pattern)
   - [CQRS Pattern](#cqrs-pattern)

4. [Integration Patterns](#integration-patterns)
   - [API Composition](#api-composition)
   - [Saga Pattern](#saga-pattern)
   - [Event-Driven Architecture](#event-driven-architecture)
   - [Circuit Breaker Pattern](#circuit-breaker-pattern)

5. [Frontend Patterns](#frontend-patterns)
   - [BLoC Pattern](#bloc-pattern)
   - [Provider Pattern](#provider-pattern)
   - [Repository Pattern (Frontend)](#repository-pattern-frontend)
   - [State Management Patterns](#state-management-patterns)

6. [Security Patterns](#security-patterns)
   - [Zero Trust Architecture](#zero-trust-architecture)
   - [Defense in Depth](#defense-in-depth)
   - [OAuth 2.0 with JWT](#oauth-20-with-jwt)
   - [API Gateway Security](#api-gateway-security)

---

## Architectural Patterns

### Modular Monolith with Microservices Path

**Description**: A monolithic application structured as well-defined modules that can be extracted into microservices as needed.

**When to Use**:
- Early-stage product with unclear domain boundaries
- Need for rapid development and deployment
- Plan to evolve to microservices when team grows
- Single database is acceptable initially

**Implementation**:

```dart
// Module structure
lib/
├── modules/
│   ├── auth/
│   │   ├── domain/
│   │   ├── application/
│   │   ├── infrastructure/
│   │   └── presentation/
│   ├── auctions/
│   │   ├── domain/
│   │   ├── application/
│   │   ├── infrastructure/
│   │   └── presentation/
│   └── payments/
│       ├── domain/
│       ├── application/
│       ├── infrastructure/
│       └── presentation/
```

**Module Interface**:
```dart
// Module abstraction
abstract class Module {
  String get name;
  List<Endpoint> get endpoints;
  List<DatabaseMigration> get migrations;
  List<EventHandler> get eventHandlers;
}

// Auth module implementation
class AuthModule extends Module {
  @override
  String get name => 'auth';

  @override
  List<Endpoint> get endpoints => [
    AuthEndpoint(),
    UserEndpoint(),
  ];

  @override
  List<DatabaseMigration> get migrations => [
    CreateUserTable(),
    CreateSessionsTable(),
  ];

  @override
  List<EventHandler> get eventHandlers => [
    UserRegisteredHandler(),
    UserLoggedInHandler(),
  ];
}
```

**Migration Path**:
1. **Phase 1**: Identify module boundaries
2. **Phase 2**: Implement module interfaces
3. **Phase 3**: Extract high-traffic modules first
4. **Phase 4**: Implement inter-module communication
5. **Phase 5**: Full microservices deployment

**Decision Criteria**:
- ✅ Team size < 20 developers
- ✅ Single database tolerance
- ✅ Rapid iteration requirements
- ❌ High isolation requirements
- ❌ Independent scaling needs

---

### Domain-Driven Design (DDD)

**Description**: An approach to software development that focuses on a core domain and domain logic, and bases complex designs on a model of the domain.

**When to Use**:
- Complex business logic domains
- Long-term projects requiring maintainability
- Domain experts available for collaboration
- Multiple development teams

**Core Concepts**:

```dart
// Entity
abstract class Entity {
  String get id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Entity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// Value Object
abstract class ValueObject {
  @override
  bool operator ==(Object other);

  @override
  int get hashCode;

  @override
  String toString();
}

// Domain Entity
class Auction extends Entity {
  final String id;
  final String title;
  final Money startingPrice;
  final Money currentBid;
  final AuctionStatus status;
  final DateTime startTime;
  final DateTime endTime;
  final String sellerId;

  Auction({
    required this.id,
    required this.title,
    required this.startingPrice,
    this.currentBid = Money.zero(),
    this.status = AuctionStatus.draft,
    required this.startTime,
    required this.endTime,
    required this.sellerId,
  });

  // Domain logic
  bool get isActive => status == AuctionStatus.active &&
                      DateTime.now().isAfter(startTime) &&
                      DateTime.now().isBefore(endTime);

  bool get canReceiveBids => isActive &&
                            currentBid.amount < startingPrice.amount * 10;

  AuctionBid placeBid(User bidder, Money amount) {
    if (!canReceiveBids) {
      throw DomainException('Auction cannot receive bids at this time');
    }

    if (amount.amount <= currentBid.amount) {
      throw DomainException('Bid amount must be higher than current bid');
    }

    return AuctionBid(
      id: Uuid().v4(),
      auctionId: id,
      bidderId: bidder.id,
      amount: amount,
      placedAt: DateTime.now(),
    );
  }
}

// Aggregate Root
abstract class AggregateRoot extends Entity {
  final List<DomainEvent> _domainEvents = [];

  void addDomainEvent(DomainEvent event) {
    _domainEvents.add(event);
  }

  List<DomainEvent> get domainEvents => List.unmodifiable(_domainEvents);

  void clearDomainEvents() {
    _domainEvents.clear();
  }
}

// Repository (Domain layer)
abstract class AuctionRepository {
  Future<Auction?> findById(String id);
  Future<List<Auction>> findBySellerId(String sellerId);
  Future<void> save(Auction auction);
  Future<void> delete(String id);
}

// Application Service
class AuctionService {
  final AuctionRepository _repository;
  final EventBus _eventBus;

  AuctionService(this._repository, this._eventBus);

  Future<Auction> createAuction(CreateAuctionCommand command) async {
    // Validate business rules
    final auction = Auction(
      id: Uuid().v4(),
      title: command.title,
      startingPrice: command.startingPrice,
      startTime: command.startTime,
      endTime: command.endTime,
      sellerId: command.sellerId,
    );

    // Save to repository
    await _repository.save(auction);

    // Publish domain events
    for (final event in auction.domainEvents) {
      await _eventBus.publish(event);
    }
    auction.clearDomainEvents();

    return auction;
  }
}
```

**Implementation Guidelines**:
1. **Bounded Contexts**: Define clear boundaries for each domain
2. **Ubiquitous Language**: Use consistent terminology across codebase
3. **Aggregates**: Design transactional boundaries
4. **Domain Events**: Implement event-driven communication
5. **Anti-Corruption Layer**: Protect domain from external influences

---

### CQRS with Event Sourcing

**Description**: Command Query Responsibility Segregation (CQRS) separates read and write operations, while Event Sourcing persists all state changes as a sequence of events.

**When to Use**:
- High-read, high-write systems
- Complex business transactions
- Audit trail requirements
- Multiple read model needs

**Implementation**:

```dart
// Command
abstract class Command {
  String get id;
  DateTime get timestamp;
}

class PlaceBidCommand extends Command {
  final String auctionId;
  final String userId;
  final double amount;

  PlaceBidCommand({
    required this.auctionId,
    required this.userId,
    required this.amount,
  }) : id = Uuid().v4(),
       timestamp = DateTime.now();
}

// Query
abstract class Query {
  String get id;
}

class GetAuctionDetailsQuery extends Query {
  final String auctionId;

  GetAuctionDetailsQuery(this.auctionId) : id = Uuid().v4();
}

// Event
abstract class DomainEvent {
  String get id;
  DateTime get timestamp;
}

class BidPlacedEvent extends DomainEvent {
  final String auctionId;
  final String userId;
  final double amount;

  BidPlacedEvent({
    required this.auctionId,
    required this.userId,
    required this.amount,
  }) : id = Uuid().v4(),
       timestamp = DateTime.now();
}

// Command Handler
abstract class CommandHandler<T extends Command> {
  Future<void> handle(T command);
}

class PlaceBidCommandHandler extends CommandHandler<PlaceBidCommand> {
  final AuctionAggregateRepository _repository;
  final EventBus _eventBus;

  PlaceBidCommandHandler(this._repository, this._eventBus);

  @override
  Future<void> handle(PlaceBidCommand command) async {
    // Load aggregate from event store
    final auction = await _repository.load(command.auctionId);

    // Execute domain logic
    auction.placeBid(command.userId, command.amount);

    // Save events to event store
    await _repository.save(auction);

    // Publish events
    for (final event in auction.domainEvents) {
      await _eventBus.publish(event);
    }
  }
}

// Query Handler
abstract class QueryHandler<T extends Query, R> {
  Future<R> handle(T query);
}

class GetAuctionDetailsQueryHandler extends QueryHandler<GetAuctionDetailsQuery, AuctionDetails> {
  final AuctionReadModelRepository _repository;

  GetAuctionDetailsQueryHandler(this._repository);

  @override
  Future<AuctionDetails> handle(GetAuctionDetailsQuery query) async {
    return await _repository.findById(query.auctionId);
  }
}

// Event Store
interface EventStore {
  Future<void> saveEvents(String aggregateId, List<DomainEvent> events);
  Future<List<DomainEvent>> getEvents(String aggregateId);
  Future<List<DomainEvent>> getEventsFromVersion(String aggregateId, int version);
}

// Read Model Projection
class AuctionProjection {
  final AuctionReadModelRepository _repository;

  AuctionProjection(this._repository);

  @EventHandler
  void on(AuctionCreatedEvent event) {
    final readModel = AuctionReadModel(
      id: event.auctionId,
      title: event.title,
      currentBid: event.startingPrice,
      bidCount: 0,
      status: AuctionStatus.active,
    );
    _repository.save(readModel);
  }

  @EventHandler
  void on(BidPlacedEvent event) {
    final readModel = _repository.findById(event.auctionId);
    readModel.currentBid = event.amount;
    readModel.bidCount += 1;
    _repository.save(readModel);
  }
}
```

**Benefits**:
- Scalable read and write operations
- Complete audit trail
- Performance optimization
- Business intelligence capabilities

**Trade-offs**:
- Increased complexity
- Eventual consistency challenges
- Learning curve
- Debugging complexity

---

### API Gateway Pattern

**Description**: A single entry point for all client requests, routing them to appropriate microservices while handling cross-cutting concerns.

**When to Use**:
- Multiple microservices
- Cross-cutting concerns (auth, logging, rate limiting)
- Client diversity (web, mobile, external)
- Security requirements

**Implementation**:

```dart
// Gateway configuration
class GatewayConfig {
  final List<RouteConfig> routes;
  final List<Middleware> globalMiddleware;
  final Map<String, ServiceConfig> services;

  GatewayConfig({
    required this.routes,
    required this.globalMiddleware,
    required this.services,
  });
}

class RouteConfig {
  final String path;
  final String method;
  final String service;
  final String endpoint;
  final List<Middleware> middleware;
  final Map<String, dynamic> parameters;

  RouteConfig({
    required this.path,
    required this.method,
    required this.service,
    required this.endpoint,
    this.middleware = const [],
    this.parameters = const {},
  });
}

// Gateway implementation
class ApiGateway {
  final GatewayConfig _config;
  final Map<String, ServiceClient> _clients;
  final List<Middleware> _middleware;

  ApiGateway(this._config, this._clients, this._middleware);

  Future<Response> handleRequest(Request request) async {
    // Build middleware chain
    var handler = _createHandler();

    // Apply global middleware
    for (final middleware in _config.globalMiddleware.reversed) {
      handler = () => middleware.process(request, handler);
    }

    // Apply route-specific middleware
    final route = _findRoute(request);
    for (final middleware in route.middleware.reversed) {
      handler = () => middleware.process(request, handler);
    }

    return await handler();
  }

  Future<Response> _createHandler() async {
    final route = _findRoute(request);
    final client = _clients[route.service];

    // Transform request and route to service
    final serviceRequest = _transformRequest(request, route);
    final serviceResponse = await client.call(serviceRequest);

    // Transform response back to client
    return _transformResponse(serviceResponse);
  }
}

// Authentication middleware
class AuthenticationMiddleware extends Middleware {
  final AuthService _authService;

  AuthenticationMiddleware(this._authService);

  @override
  Future<Response> process(Request request, NextHandler next) async {
    final token = _extractToken(request);
    if (token == null) {
      return Response.unauthorized('Missing authentication token');
    }

    final user = await _authService.validateToken(token);
    if (user == null) {
      return Response.unauthorized('Invalid authentication token');
    }

    // Add user context to request
    request.context['user'] = user;
    return await next();
  }

  String? _extractToken(Request request) {
    final authHeader = request.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return null;
    }
    return authHeader.substring(7);
  }
}

// Rate limiting middleware
class RateLimitMiddleware extends Middleware {
  final RateLimitStore _store;
  final int requestsPerMinute;

  RateLimitMiddleware(this._store, this.requestsPerMinute);

  @override
  Future<Response> process(Request request, NextHandler next) async {
    final clientId = _getClientId(request);
    final key = 'rate_limit:$clientId:${request.path}';

    final currentCount = await _store.increment(key, Duration(minutes: 1));

    if (currentCount > requestsPerMinute) {
      return Response.tooManyRequests('Rate limit exceeded');
    }

    return await next();
  }

  String _getClientId(Request request) {
    final user = request.context['user'] as User?;
    return user?.id ?? request.ipAddress;
  }
}

// Logging middleware
class LoggingMiddleware extends Middleware {
  final Logger _logger;

  LoggingMiddleware(this._logger);

  @override
  Future<Response> process(Request request, NextHandler next) async {
    final stopwatch = Stopwatch()..start();

    _logger.info('Request started', {
      'method': request.method,
      'path': request.path,
      'ip': request.ipAddress,
      'user_id': (request.context['user'] as User?)?.id,
    });

    try {
      final response = await next();

      _logger.info('Request completed', {
        'method': request.method,
        'path': request.path,
        'status_code': response.statusCode,
        'duration_ms': stopwatch.elapsedMilliseconds,
      });

      return response;
    } catch (error) {
      _logger.error('Request failed', error: error, {
        'method': request.method,
        'path': request.path,
        'duration_ms': stopwatch.elapsedMilliseconds,
      });
      rethrow;
    }
  }
}
```

**Gateway Configuration**:
```yaml
gateway:
  routes:
    - path: "/api/v1/auctions/*"
      method: "*"
      service: "auction-service"
      middleware: ["auth", "rate-limit"]

    - path: "/api/v1/auth/*"
      method: "*"
      service: "auth-service"
      middleware: ["rate-limit"]

    - path: "/api/v1/payments/*"
      method: "*"
      service: "payment-service"
      middleware: ["auth", "rate-limit", "encryption"]

  services:
    auction-service:
      url: "http://auction-service:8080"
      timeout: 30s
      retries: 3

    auth-service:
      url: "http://auth-service:8080"
      timeout: 10s
      retries: 2

    payment-service:
      url: "http://payment-service:8080"
      timeout: 45s
      retries: 3

  middleware:
    auth:
      class: "AuthenticationMiddleware"
      config:
        jwt_secret: "${JWT_SECRET}"

    rate-limit:
      class: "RateLimitMiddleware"
      config:
        requests_per_minute: 100

    encryption:
      class: "EncryptionMiddleware"
      config:
        algorithm: "AES-256-GCM"
```

---

## Design Patterns

### Repository Pattern

**Description**: Mediates between the domain and data mapping layers using a collection-like interface for accessing domain objects.

**When to Use**:
- Need to separate domain logic from data source logic
- Want to test domain logic independently
- Multiple data sources or complex queries
- Need for consistent data access interface

**Implementation**:

```dart
// Abstract repository
abstract class Repository<T, ID> {
  Future<T?> findById(ID id);
  Future<List<T>> findAll();
  Future<T> save(T entity);
  Future<void> delete(ID id);
  Future<List<T>> findBy(Map<String, dynamic> criteria);
}

// Domain entity
class Auction {
  final String id;
  final String title;
  final String description;
  final double startingPrice;
  final DateTime startTime;
  final DateTime endTime;
  final String sellerId;

  Auction({
    required this.id,
    required this.title,
    required this.description,
    required this.startingPrice,
    required this.startTime,
    required this.endTime,
    required this.sellerId,
  });
}

// Repository interface
abstract class AuctionRepository extends Repository<Auction, String> {
  Future<List<Auction>> findBySellerId(String sellerId);
  Future<List<Auction>> findActiveAuctions();
  Future<List<Auction>> findByCategory(String category);
  Future<Auction?> findWithBids(String auctionId);
}

// Repository implementation
class DatabaseAuctionRepository implements AuctionRepository {
  final Database _database;
  final BidRepository _bidRepository;

  DatabaseAuctionRepository(this._database, this._bidRepository);

  @override
  Future<Auction?> findById(String id) async {
    final row = await _database.query(
      'SELECT * FROM auctions WHERE id = ?',
      [id],
    );

    if (row.isEmpty) return null;

    return _mapRowToAuction(row.first);
  }

  @override
  Future<List<Auction>> findAll() async {
    final rows = await _database.query('SELECT * FROM auctions ORDER BY created_at DESC');
    return rows.map(_mapRowToAuction).toList();
  }

  @override
  Future<Auction> save(Auction auction) async {
    await _database.execute('''
      INSERT OR REPLACE INTO auctions (
        id, title, description, starting_price, start_time, end_time, seller_id
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
    ''', [
      auction.id,
      auction.title,
      auction.description,
      auction.startingPrice,
      auction.startTime.toIso8601String(),
      auction.endTime.toIso8601String(),
      auction.sellerId,
    ]);

    return auction;
  }

  @override
  Future<void> delete(String id) async {
    await _database.execute('DELETE FROM auctions WHERE id = ?', [id]);
  }

  @override
  Future<List<Auction>> findBy(Map<String, dynamic> criteria) async {
    final whereClause = criteria.keys.map((key) => '$key = ?').join(' AND ');
    final values = criteria.values.toList();

    final rows = await _database.query(
      'SELECT * FROM auctions WHERE $whereClause',
      values,
    );

    return rows.map(_mapRowToAuction).toList();
  }

  @override
  Future<List<Auction>> findBySellerId(String sellerId) async {
    final rows = await _database.query(
      'SELECT * FROM auctions WHERE seller_id = ? ORDER BY created_at DESC',
      [sellerId],
    );

    return rows.map(_mapRowToAuction).toList();
  }

  @override
  Future<List<Auction>> findActiveAuctions() async {
    final now = DateTime.now().toIso8601String();
    final rows = await _database.query('''
      SELECT * FROM auctions
      WHERE start_time <= ? AND end_time > ? AND status = 'active'
      ORDER BY end_time ASC
    ''', [now, now]);

    return rows.map(_mapRowToAuction).toList();
  }

  @override
  Future<List<Auction>> findByCategory(String category) async {
    final rows = await _database.query(
      'SELECT * FROM auctions WHERE category = ? ORDER BY created_at DESC',
      [category],
    );

    return rows.map(_mapRowToAuction).toList();
  }

  @override
  Future<Auction?> findWithBids(String auctionId) async {
    final auction = await findById(auctionId);
    if (auction == null) return null;

    // Load associated bids if needed
    return auction;
  }

  Auction _mapRowToAuction(Map<String, dynamic> row) {
    return Auction(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String,
      startingPrice: row['starting_price'] as double,
      startTime: DateTime.parse(row['start_time'] as String),
      endTime: DateTime.parse(row['end_time'] as String),
      sellerId: row['seller_id'] as String,
    );
  }
}

// Repository factory
class RepositoryFactory {
  final Database _database;
  final Map<Type, dynamic> _repositories = {};

  RepositoryFactory(this._database);

  T get<T extends Repository>() {
    return _repositories.putIfAbsent(T, () => _createRepository<T>());
  }

  Repository<T, ID> _createRepository<T extends Repository<T, ID>>() {
    switch (T) {
      case AuctionRepository:
        return DatabaseAuctionRepository(_database, get<BidRepository>()) as T;
      case BidRepository:
        return DatabaseBidRepository(_database) as T;
      case UserRepository:
        return DatabaseUserRepository(_database) as T;
      default:
        throw ArgumentError('Unknown repository type: $T');
    }
  }
}

// Usage example
class AuctionService {
  final AuctionRepository _repository;

  AuctionService(this._repository);

  Future<List<Auction>> getSellerActiveAuctions(String sellerId) async {
    return await _repository.findBySellerId(sellerId);
  }

  Future<Auction> createAuction(CreateAuctionRequest request) async {
    final auction = Auction(
      id: Uuid().v4(),
      title: request.title,
      description: request.description,
      startingPrice: request.startingPrice,
      startTime: request.startTime,
      endTime: request.endTime,
      sellerId: request.sellerId,
    );

    return await _repository.save(auction);
  }
}
```

**Benefits**:
- Separation of concerns
- Testability
- Centralized data access logic
- Consistent interface
- Easy to swap implementations

---

### Unit of Work Pattern

**Description**: Maintains a list of objects affected by a business transaction and coordinates the writing out of changes and the resolution of concurrency problems.

**When to Use**:
- Multiple repository operations in a single transaction
- Need for atomic operations across repositories
- Complex business transactions
- Performance optimization with batch operations

**Implementation**:

```dart
// Unit of Work interface
abstract class UnitOfWork {
  AuctionRepository get auctions;
  BidRepository get bids;
  UserRepository get users;
  PaymentRepository get payments;

  Future<void> commit();
  Future<void> rollback();
  void dispose();
}

// Unit of Work implementation
class DatabaseUnitOfWork implements UnitOfWork {
  final Database _database;
  final Transaction? _transaction;

  late final AuctionRepository _auctions;
  late final BidRepository _bids;
  late final UserRepository _users;
  late final PaymentRepository _payments;

  bool _isCommitted = false;

  DatabaseUnitOfWork(this._database) {
    _transaction = _database.beginTransaction();
    _auctions = DatabaseAuctionRepository(_database, _transaction);
    _bids = DatabaseBidRepository(_database, _transaction);
    _users = DatabaseUserRepository(_database, _transaction);
    _payments = DatabasePaymentRepository(_database, _transaction);
  }

  @override
  AuctionRepository get auctions => _auctions;

  @override
  BidRepository get bids => _bids;

  @override
  UserRepository get users => _users;

  @override
  PaymentRepository get payments => _payments;

  @override
  Future<void> commit() async {
    if (_isCommitted) {
      throw StateError('Transaction already committed');
    }

    try {
      await _transaction?.commit();
      _isCommitted = true;
    } catch (e) {
      await rollback();
      rethrow;
    }
  }

  @override
  Future<void> rollback() async {
    if (!_isCommitted) {
      await _transaction?.rollback();
      _isCommitted = true;
    }
  }

  @override
  void dispose() {
    if (!_isCommitted) {
      rollback();
    }
    _transaction?.dispose();
  }
}

// Unit of Work factory
class UnitOfWorkFactory {
  final Database _database;

  UnitOfWorkFactory(this._database);

  Future<UnitOfWork> create() async {
    return DatabaseUnitOfWork(_database);
  }
}

// Usage example
class AuctionService {
  final UnitOfWorkFactory _uowFactory;

  AuctionService(this._uowFactory);

  Future<void> placeBid(PlaceBidRequest request) async {
    final uow = await _uowFactory.create();

    try {
      // Load auction
      final auction = await uow.auctions.findById(request.auctionId);
      if (auction == null) {
        throw NotFoundException('Auction not found');
      }

      // Load user
      final user = await uow.users.findById(request.userId);
      if (user == null) {
        throw NotFoundException('User not found');
      }

      // Validate bid
      if (request.amount <= auction.currentBid) {
        throw ValidationException('Bid amount must be higher than current bid');
      }

      // Create bid
      final bid = Bid(
        id: Uuid().v4(),
        auctionId: request.auctionId,
        userId: request.userId,
        amount: request.amount,
        placedAt: DateTime.now(),
      );

      // Update auction current bid
      auction.currentBid = request.amount;

      // Save changes
      await uow.auctions.save(auction);
      await uow.bids.save(bid);

      // Create notification
      final notification = Notification(
        id: Uuid().v4(),
        userId: auction.sellerId,
        type: NotificationType.newBid,
        title: 'New bid received',
        message: 'Someone bid \$${request.amount} on your auction',
        relatedEntityId: auction.id,
        createdAt: DateTime.now(),
      );

      await uow.notifications.save(notification);

      // Commit transaction
      await uow.commit();

    } catch (e) {
      await uow.rollback();
      rethrow;
    } finally {
      uow.dispose();
    }
  }
}

// Complex transaction example
class OrderService {
  final UnitOfWorkFactory _uowFactory;
  final PaymentService _paymentService;

  OrderService(this._uowFactory, this._paymentService);

  Future<Order> createOrder(CreateOrderRequest request) async {
    final uow = await _uowFactory.create();

    try {
      // 1. Load and validate auction
      final auction = await uow.auctions.findById(request.auctionId);
      if (auction == null || auction.status != AuctionStatus.ended) {
        throw ValidationException('Invalid auction');
      }

      // 2. Load winning bid
      final winningBid = await uow.bids.findWinningBid(request.auctionId);
      if (winningBid == null) {
        throw ValidationException('No winning bid found');
      }

      // 3. Create order
      final order = Order(
        id: Uuid().v4(),
        auctionId: auction.id,
        buyerId: winningBid.userId,
        sellerId: auction.sellerId,
        finalPrice: winningBid.amount,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
      );

      await uow.orders.save(order);

      // 4. Create payment intent
      final paymentIntent = await _paymentService.createPaymentIntent(
        orderId: order.id,
        amount: order.finalPrice,
        currency: 'USD',
      );

      final payment = Payment(
        id: paymentIntent.id,
        orderId: order.id,
        userId: order.buyerId,
        stripePaymentIntentId: paymentIntent.stripeId,
        amount: order.finalPrice,
        status: PaymentStatus.pending,
        createdAt: DateTime.now(),
      );

      await uow.payments.save(payment);

      // 5. Update auction status
      auction.status = AuctionStatus.sold;
      await uow.auctions.save(auction);

      // 6. Create notifications
      final buyerNotification = Notification(
        id: Uuid().v4(),
        userId: order.buyerId,
        type: NotificationType.orderCreated,
        title: 'Order created',
        message: 'Your order has been created. Please complete payment.',
        relatedEntityId: order.id,
        createdAt: DateTime.now(),
      );

      final sellerNotification = Notification(
        id: Uuid().v4(),
        userId: order.sellerId,
        type: NotificationType.orderCreated,
        title: 'Order created',
        message: 'Your auction has been sold. Awaiting payment confirmation.',
        relatedEntityId: order.id,
        createdAt: DateTime.now(),
      );

      await uow.notifications.saveAll([buyerNotification, sellerNotification]);

      // Commit all changes
      await uow.commit();

      return order;

    } catch (e) {
      await uow.rollback();
      rethrow;
    } finally {
      uow.dispose();
    }
  }
}
```

**Benefits**:
- Transactional consistency
- Reduced database round trips
- Atomic operations
- Rollback capabilities
- Clear transaction boundaries

---

## Frontend Patterns

### BLoC Pattern

**Description**: Business Logic Component pattern separates presentation from business logic, using streams to manage state.

**When to Use**:
- Complex state management
- Real-time data updates
- Separation of UI and business logic
- Reactive programming needs

**Implementation**:

```dart
// Event
abstract class AuctionEvent extends Equatable {
  const AuctionEvent();

  @override
  List<Object> get props => [];
}

class LoadAuctions extends AuctionEvent {
  final AuctionFilters filters;

  const LoadAuctions(this.filters);

  @override
  List<Object> get props => [filters];
}

class RefreshAuctions extends AuctionEvent {
  const RefreshAuctions();
}

class PlaceBid extends AuctionEvent {
  final String auctionId;
  final double amount;

  const PlaceBid(this.auctionId, this.amount);

  @override
  List<Object> get props => [auctionId, amount];
}

class UpdateAuctionFilter extends AuctionEvent {
  final AuctionFilters filters;

  const UpdateAuctionFilter(this.filters);

  @override
  List<Object> get props => [filters];
}

// State
abstract class AuctionState extends Equatable {
  const AuctionState();

  @override
  List<Object> get props => [];
}

class AuctionInitial extends AuctionState {
  const AuctionInitial();
}

class AuctionLoading extends AuctionState {
  const AuctionLoading();
}

class AuctionLoaded extends AuctionState {
  final List<Auction> auctions;
  final AuctionFilters filters;
  final bool hasReachedMax;

  const AuctionLoaded({
    required this.auctions,
    required this.filters,
    this.hasReachedMax = false,
  });

  AuctionLoaded copyWith({
    List<Auction>? auctions,
    AuctionFilters? filters,
    bool? hasReachedMax,
  }) {
    return AuctionLoaded(
      auctions: auctions ?? this.auctions,
      filters: filters ?? this.filters,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object> get props => [auctions, filters, hasReachedMax];
}

class AuctionError extends AuctionState {
  final String message;

  const AuctionError(this.message);

  @override
  List<Object> get props => [message];
}

class BidPlacing extends AuctionState {
  final String auctionId;

  const BidPlacing(this.auctionId);

  @override
  List<Object> get props => [auctionId];
}

// BLoC
class AuctionBloc extends Bloc<AuctionEvent, AuctionState> {
  final GetAuctions _getAuctions;
  final PlaceBid _placeBid;

  AuctionBloc({
    required GetAuctions getAuctions,
    required PlaceBid placeBid,
  })  : _getAuctions = getAuctions,
        _placeBid = placeBid,
        super(const AuctionInitial()) {
    on<LoadAuctions>(_onLoadAuctions);
    on<RefreshAuctions>(_onRefreshAuctions);
    on<PlaceBid>(_onPlaceBid);
    on<UpdateAuctionFilter>(_onUpdateAuctionFilter);
  }

  Future<void> _onLoadAuctions(
    LoadAuctions event,
    Emitter<AuctionState> emit,
  ) async {
    if (state is AuctionLoading) return;

    final currentState = state;
    final auctions = (currentState is AuctionLoaded) ? currentState.auctions : <Auction>[];

    emit(AuctionLoading());

    try {
      final result = await _getAuctions(AuctionParams(
        filters: event.filters,
        offset: auctions.length,
        limit: 20,
      ));

      final newAuctions = result.auctions;

      if (currentState is AuctionLoaded) {
        emit(
          currentState.copyWith(
            auctions: [...currentState.auctions, ...newAuctions],
            hasReachedMax: newAuctions.length < 20,
          ),
        );
      } else {
        emit(
          AuctionLoaded(
            auctions: newAuctions,
            filters: event.filters,
            hasReachedMax: newAuctions.length < 20,
          ),
        );
      }
    } catch (e) {
      emit(AuctionError(e.toString()));
    }
  }

  Future<void> _onRefreshAuctions(
    RefreshAuctions event,
    Emitter<AuctionState> emit,
  ) async {
    final currentState = state;
    final filters = currentState is AuctionLoaded ? currentState.filters : AuctionFilters();

    emit(const AuctionLoading());

    try {
      final result = await _getAuctions(AuctionParams(
        filters: filters,
        offset: 0,
        limit: 20,
      ));

      emit(
        AuctionLoaded(
          auctions: result.auctions,
          filters: filters,
          hasReachedMax: result.auctions.length < 20,
        ),
      );
    } catch (e) {
      emit(AuctionError(e.toString()));
    }
  }

  Future<void> _onPlaceBid(
    PlaceBid event,
    Emitter<AuctionState> emit,
  ) async {
    try {
      emit(BidPlacing(event.auctionId));

      await _placeBid(PlaceBidParams(
        auctionId: event.auctionId,
        amount: event.amount,
      ));

      // Refresh auctions to get updated data
      add(RefreshAuctions());
    } catch (e) {
      emit(AuctionError(e.toString()));
    }
  }

  void _onUpdateAuctionFilter(
    UpdateAuctionFilter event,
    Emitter<AuctionState> emit,
  ) {
    add(LoadAuctions(event.filters));
  }
}

// Use case
class GetAuctions extends UseCase<List<Auction>, AuctionParams> {
  final AuctionRepository _repository;

  GetAuctions(this._repository);

  @override
  Future<Either<Failure, List<Auction>>> call(AuctionParams params) async {
    return await _repository.getAuctions(
      filters: params.filters,
      offset: params.offset,
      limit: params.limit,
    );
  }
}

// UI Widget
class AuctionListPage extends StatelessWidget {
  const AuctionListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AuctionBloc>()..add(LoadAuctions(AuctionFilters())),
      child: const AuctionListView(),
    );
  }
}

class AuctionListView extends StatefulWidget {
  const AuctionListView({Key? key}) : super(key: key);

  @override
  State<AuctionListView> createState() => _AuctionListViewState();
}

class _AuctionListViewState extends State<AuctionListView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuctionBloc, AuctionState>(
      builder: (context, state) {
        if (state is AuctionLoading && state is! AuctionLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AuctionError) {
          return Center(
            child: Text(
              'Error: ${state.message}',
              style: Theme.of(context).textTheme.headline6,
            ),
          );
        }

        if (state is AuctionLoaded) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<AuctionBloc>().add(RefreshAuctions());
            },
            child: ListView.builder(
              controller: _scrollController,
              itemCount: state.hasReachedMax
                  ? state.auctions.length
                  : state.auctions.length + 1,
              itemBuilder: (context, index) {
                if (index >= state.auctions.length) {
                  return const BottomLoader();
                }

                final auction = state.auctions[index];
                return AuctionCard(auction: auction);
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<AuctionBloc>().add(LoadAuctions(AuctionFilters()));
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}
```

**Benefits**:
- Clear separation of concerns
- Testable business logic
- Reactive state management
- Complex state handling
- Stream-based updates

---

## Decision Trees

### Pattern Selection Guide

```
┌─────────────────────────────────────────────────────────────┐
│                    Pattern Selection Tree                   │
└─────────────────────────────────────────────────────────────┘

1. Application Architecture
   ├── Team Size < 20?
   │   ├── Yes → Modular Monolith → Evolve to Microservices
   │   └── No → Microservices (if high scaling needs)
   │
   ├── Domain Complexity High?
   │   ├── Yes → Domain-Driven Design (DDD)
   │   └── No → Layered Architecture
   │
   ├── Read/Write Patterns Different?
   │   ├── Yes → CQRS (with Event Sourcing if audit needed)
   │   └── No → Traditional CRUD
   │
   └── Multiple External Services?
       ├── Yes → API Gateway Pattern
       └── No → Direct service communication

2. Data Management
   ├── Transactional Consistency Required?
   │   ├── Yes → Unit of Work Pattern
   │   └── No → Repository Pattern
   │
   ├── Complex Queries?
   │   ├── Yes → Repository Pattern + Specification Pattern
   │   └── No → Active Record Pattern
   │
   ├── Multiple Data Sources?
   │   ├── Yes → Repository Pattern with Data Mapper
   │   └── No → Active Record Pattern
   │
   └── Cache Requirements?
       ├── Yes → Cache-Aside Pattern
       └── No → Direct database access

3. Frontend State Management
   ├── Complex State Logic?
   │   ├── Yes → BLoC Pattern
   │   └── No → Provider/StatefulWidget
   │
   ├── Real-time Updates?
   │   ├── Yes → BLoC with Streams
   │   └── No → setState or Provider
   │
   ├── Shared State Across Widgets?
   │   ├── Yes → Provider or BLoC
   │   └── No → Local state
   │
   └── Form-heavy Application?
       ├── Yes → BLoC with Form Validation
       └── No → Provider or setState

4. Integration Patterns
   ├── External API Integration?
   │   ├── Yes → Adapter Pattern + Circuit Breaker
   │   └── No → Direct calls
   │
   ├── Async Processing Required?
   │   ├── Yes → Event-Driven Architecture
   │   └── No → Synchronous calls
   │
   ├── Distributed Transactions?
   │   ├── Yes → Saga Pattern
   │   └── No → Unit of Work
   │
   └── Data Aggregation from Multiple Services?
       ├── Yes → API Composition Pattern
       └── No → Single service calls
```

### Migration Path Decisions

```
Modular Monolith → Microservices Migration Path:

Phase 1: Identify Boundaries
├── Business capability analysis
├── Data ownership identification
├── Dependency mapping
└── Communication pattern analysis

Phase 2: Extract Services
├── High-traffic services first
├── Independent data ownership
├── API Gateway implementation
└── Service discovery setup

Phase 3: Refactor Communication
├── Implement event-driven communication
├── Add circuit breakers
├── Implement distributed tracing
└── Add monitoring and observability

Phase 4: Optimize Operations
├── Independent deployment pipelines
├── Auto-scaling configuration
├── Disaster recovery setup
└── Performance optimization
```

This Architecture Pattern Library provides comprehensive guidance for implementing various architectural patterns in the Video Marketplace platform. Each pattern includes specific implementation details, decision criteria, and examples tailored to our Flutter + Serverpod stack.

The library serves as a reference for developers to make informed architectural decisions and ensures consistency across the codebase while allowing flexibility for different use cases and requirements.