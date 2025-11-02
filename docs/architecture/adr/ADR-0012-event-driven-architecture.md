# ADR-0012: Event-Driven Architecture Foundation

**Status:** Accepted
**Date:** 2025-10-14
**Decision Made By:** Architect Agent
**Impacts:** Backend architecture, service communication, data consistency, scalability

## Context

The Video Window platform currently uses direct service-to-service communication for most operations. As the platform scales and introduces more complex workflows (auctions, payments, notifications), this approach creates several challenges:

1. **Tight Coupling**: Services are directly dependent on each other's APIs
2. **Brittleness**: Service failures cascade through the system
3. **Scalability Issues**: Synchronous communication limits throughput
4. **Complex Workflows**: Multi-service transactions are difficult to coordinate
5. **Audit Trail**: Limited visibility into system state changes
6. **Performance**: Synchronous calls add latency to critical paths

Current pain points:
- Auction bidding requires coordination between auction, notification, and user services
- Payment processing involves multiple services with complex success/failure handling
- Real-time updates require polling or inefficient notification mechanisms
- No reliable way to track state changes across services

## Decision

Implement an event-driven architecture using Redis Streams as the backbone. This will provide:

1. **Asynchronous Communication**: Services communicate through events without direct coupling
2. **Event Sourcing**: Critical events are stored for audit and replay capabilities
3. **Reliable Delivery**: At-least-once delivery guarantees with consumer groups
4. **Real-time Processing**: Stream-based processing for low-latency workflows
5. **Scalability**: Horizontal scaling through consumer groups and partitioning
6. **Fault Tolerance**: Durable event storage with replay capabilities

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Event Bus Architecture                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌─────────────┐    ┌────────────────────┐ │
│  │   Auction    │    │   Payment   │    │    Notification    │ │
│  │   Service    │    │   Service   │    │     Service        │ │
│  └──────┬───────┘    └──────┬──────┘    └────────┬───────────┘ │
│         │                    │                     │           │
│         │                    │                     │           │
│  ┌──────▼────────────────────▼─────────────────────▼───────┐   │
│  │                Redis Streams (Event Bus)                │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │   │
│  │  │ Auctions    │  │ Payments    │  │ Notifications   │  │   │
│  │  │ Stream      │  │ Stream      │  │ Stream          │  │   │
│  │  └─────────────┘  └─────────────┘  └─────────────────┘  │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │   │
│  │  │ Users       │  │ Orders      │  │ System Events   │  │   │
│  │  │ Stream      │  │ Stream      │  │ Stream          │  │   │
│  │  └─────────────┘  └─────────────┘  └─────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────┘
│                                 │                               │
│                                 │                               │
│  ┌──────────────┐    ┌─────────────────────────────────────┐   │
│  │    User      │    │       Event Consumers               │   │
│  │   Service    │    │  ┌─────────────┐  ┌──────────────┐  │   │
│  └──────┬───────┘    │  │    Search   │  │   Analytics  │  │   │
│         │            │  │  Consumer   │  │   Consumer   │  │   │
│         │            │  └─────────────┘  └──────────────┘  │   │
│  ┌──────▼───────┐    │  ┌─────────────┐  ┌──────────────┐  │   │
│  │    Order     │    │  │   Caching   │  │   Reporting  │  │   │
│  │   Service    │    │  │  Consumer   │  │   Consumer   │  │   │
│  └──────────────┘    │  └─────────────┘  └──────────────┘  │   │
│                       └─────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Event Streams Design

### 1. Auction Events Stream
**Stream Key:** `events:auctions`

```yaml
Events:
  AuctionCreated:
    data:
      auctionId: UUID
      sellerId: UUID
      title: String
      category: String
      startingPrice: Decimal
      startTime: DateTime
      endTime: DateTime

  AuctionUpdated:
    data:
      auctionId: UUID
      changes: Map<String, Any>
      updatedBy: UUID

  BidPlaced:
    data:
      auctionId: UUID
      bidId: UUID
      bidderId: UUID
      amount: Decimal
      previousAmount: Decimal
      timestamp: DateTime

  AuctionEnded:
    data:
      auctionId: UUID
      winningBidId: UUID?
      finalPrice: Decimal?
      endTime: DateTime

  AuctionCancelled:
    data:
      auctionId: UUID
      reason: String
      cancelledBy: UUID
```

### 2. Payment Events Stream
**Stream Key:** `events:payments`

```yaml
Events:
  PaymentIntentCreated:
    data:
      paymentId: UUID
      auctionId: UUID
      userId: UUID
      amount: Decimal
      currency: String
      stripeIntentId: String

  PaymentSucceeded:
    data:
      paymentId: UUID
      stripePaymentId: String
      amount: Decimal
      currency: String
      fees: Decimal

  PaymentFailed:
    data:
      paymentId: UUID
      reason: String
      errorCode: String
      retryable: Boolean

  PaymentRefunded:
    data:
      paymentId: UUID
      refundId: UUID
      amount: Decimal
      reason: String
```

### 3. User Events Stream
**Stream Key:** `events:users`

```yaml
Events:
  UserRegistered:
    data:
      userId: UUID
      email: String
      username: String
      registrationTime: DateTime

  UserUpdated:
    data:
      userId: UUID
      changes: Map<String, Any>
      updatedBy: UUID

  UserSuspended:
    data:
      userId: UUID
      reason: String
      suspendedBy: UUID
      suspendedUntil: DateTime?

  UserVerified:
    data:
      userId: UUID
      verificationMethod: String
      verifiedBy: UUID
```

### 4. Order Events Stream
**Stream Key:** `events:orders`

```yaml
Events:
  OrderCreated:
    data:
      orderId: UUID
      auctionId: UUID
      buyerId: UUID
      sellerId: UUID
      finalPrice: Decimal
      paymentId: UUID

  OrderConfirmed:
    data:
      orderId: UUID
      confirmedBy: UUID
      confirmationTime: DateTime

  OrderShipped:
    data:
      orderId: UUID
      trackingNumber: String
      carrier: String
      shippedBy: UUID

  OrderDelivered:
    data:
      orderId: UUID
      deliveryTime: DateTime
      confirmedBy: UUID
```

### 5. Notification Events Stream
**Stream Key:** `events:notifications`

```yaml
Events:
  NotificationRequested:
    data:
      notificationId: UUID
      userId: UUID
      type: String
      channel: String
      data: Map<String, Any>

  NotificationSent:
    data:
      notificationId: UUID
      channel: String
      sentAt: DateTime
      messageId: String

  NotificationFailed:
    data:
      notificationId: UUID
      channel: String
      error: String
      retryCount: Int
```

## Event Processing Patterns

### 1. Simple Event Processing
```dart
class AuctionEventHandler {
  final NotificationService _notificationService;
  final SearchService _searchService;

  void handleAuctionCreated(AuctionCreatedEvent event) async {
    // Update search index
    await _searchService.indexAuction(event.auctionId);

    // Notify followers
    await _notificationService.notifyFollowers(
      event.sellerId,
      'New auction created: ${event.title}',
    );
  }
}
```

### 2. Saga Pattern for Complex Workflows
```dart
class AuctionPurchaseSaga {
  Future<void> execute(AuctionEndedEvent event) async {
    if (event.winningBidId != null) {
      try {
        // Step 1: Create payment intent
        await _publishEvent(PaymentIntentRequestedEvent(
          auctionId: event.auctionId,
          bidderId: event.winningBidderId,
          amount: event.finalPrice,
        ));

        // Step 2: Wait for payment success
        await _waitForEvent<PaymentSucceededEvent>(
          predicate: (e) => e.auctionId == event.auctionId,
          timeout: Duration(minutes: 30),
        );

        // Step 3: Create order
        await _publishEvent(OrderCreatedEvent(
          auctionId: event.auctionId,
          buyerId: event.winningBidderId,
        ));

      } catch (error) {
        // Handle compensation
        await _publishEvent(PaymentRefundRequestedEvent(
          auctionId: event.auctionId,
        ));
      }
    }
  }
}
```

### 3. Event Sourcing for Critical Entities
```dart
class AuctionAggregate {
  final List<AuctionEvent> _events = [];

  void applyEvent(AuctionEvent event) {
    _events.add(event);

    switch (event.type) {
      case 'AuctionCreated':
        _handleAuctionCreated(event as AuctionCreatedEvent);
        break;
      case 'BidPlaced':
        _handleBidPlaced(event as BidPlacedEvent);
        break;
      // ... other event types
    }
  }

  AuctionState getCurrentState() {
    return _events.fold(
      AuctionState.initial(),
      (state, event) => state.apply(event),
    );
  }
}
```

## Consumer Groups and Scaling

### 1. Notification Consumer Group
```yaml
Group: notifications
Streams: [events:payments, events:orders, events:auctions]
Consumers:
  - name: email-notifier
    streams: [events:payments, events:orders]
  - name: push-notifier
    streams: [events:auctions, events:orders]
  - name: sms-notifier
    streams: [events:payments]
Scaling: Horizontal (multiple instances per consumer)
```

### 2. Search Indexing Consumer Group
```yaml
Group: search-indexing
Streams: [events:auctions, events:users]
Consumers:
  - name: auction-indexer
    streams: [events:auctions]
  - name: user-indexer
    streams: [events:users]
Scaling: Horizontal with partitioning by entity ID
```

### 3. Analytics Consumer Group
```yaml
Group: analytics
Streams: [events:auctions, events:payments, events:orders]
Consumers:
  - name: real-time-analytics
    streams: [events:payments, events:orders]
  - name: batch-analytics
    streams: [events:auctions, events:payments, events:orders]
Scaling: Single instance for real-time, batch for analytics
```

## Implementation Details

### 1. Event Publisher
```dart
class EventPublisher {
  final RedisConnection _redis;

  Future<void> publish(String streamName, DomainEvent event) async {
    final eventData = {
      'id': event.id,
      'type': event.type,
      'version': event.version,
      'data': event.data,
      'timestamp': event.timestamp.toIso8601String(),
      'correlationId': event.correlationId,
      'causationId': event.causationId,
    };

    await _redis.xAdd(
      streamName,
      eventData,
      id: '*', // Auto-generated ID
    );
  }
}
```

### 2. Event Consumer
```dart
class EventConsumer {
  final RedisConnection _redis;
  final Map<String, EventHandler> _handlers = {};
  String _consumerGroup;
  String _consumerName;

  Future<void> startConsuming() async {
    // Create consumer group if it doesn't exist
    await _createConsumerGroupIfNotExists();

    while (true) {
      final messages = await _redis.xReadGroup(
        _consumerGroup,
        _consumerName,
        {streamName: '>'}, // Read new messages
        count: 10,
        block: 1000, // 1 second timeout
      );

      for (final message in messages) {
        await _processMessage(message);
      }
    }
  }

  Future<void> _processMessage(StreamMessage message) async {
    try {
      final event = _deserializeEvent(message.data);
      final handler = _handlers[event.type];

      if (handler != null) {
        await handler(event);

        // Acknowledge successful processing
        await _redis.xAck(streamName, _consumerGroup, message.id);
      }
    } catch (error) {
      // Handle processing errors
      await _handleProcessingError(message, error);
    }
  }
}
```

### 3. Event Store Interface
```dart
abstract class EventStore {
  Future<void> saveEvent(String streamName, DomainEvent event);
  Future<List<DomainEvent>> getEvents(String streamName, {String? fromId, int? count});
  Future<List<DomainEvent>> getEventsByType(String eventType, {DateTime? from, DateTime? to});
  Future<void> createConsumerGroup(String streamName, String groupName);
  Future<List<DomainEvent>> readGroup(String groupName, String consumerName, List<String> streams);
  Future<void> acknowledge(String streamName, String groupName, String messageId);
}
```

## Schema Validation and Evolution

### 1. Event Schema Registry
```dart
class EventSchemaRegistry {
  final Map<String, EventSchema> _schemas = {};

  void registerSchema(String eventType, EventSchema schema) {
    _schemas[eventType] = schema;
  }

  ValidationResult validateEvent(DomainEvent event) {
    final schema = _schemas[event.type];
    if (schema == null) {
      return ValidationResult.error('Unknown event type: ${event.type}');
    }

    return schema.validate(event.data);
  }
}
```

### 2. Schema Evolution Strategy
- **Backward Compatibility**: New fields are optional
- **Forward Compatibility**: Missing fields have defaults
- **Versioning**: Events include version numbers
- **Migration**: Automatic transformation for older event versions

## Reliability and Error Handling

### 1. Dead Letter Queue
```dart
class DeadLetterQueue {
  final String _streamName = 'dlq:events';

  Future<void> addToDLQ(FailedMessage message) async {
    await _redis.xAdd(_streamName, {
      'originalStream': message.originalStream,
      'originalId': message.originalId,
      'error': message.error.toString(),
      'eventData': jsonEncode(message.eventData),
      'failedAt': message.failedAt.toIso8601String(),
      'retryCount': message.retryCount,
    });
  }
}
```

### 2. Retry Mechanism
```dart
class RetryableEventConsumer {
  static const int maxRetries = 3;
  static const Duration baseDelay = Duration(seconds: 1);

  Future<void> _processMessageWithRetry(StreamMessage message) async {
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        await _processMessage(message);
        return; // Success
      } catch (error) {
        retryCount++;

        if (retryCount >= maxRetries) {
          await _addToDLQ(message, error, retryCount);
          return;
        }

        // Exponential backoff
        final delay = baseDelay * math.pow(2, retryCount - 1);
        await Future.delayed(delay);
      }
    }
  }
}
```

## Monitoring and Observability

### 1. Event Metrics
```dart
class EventMetrics {
  void recordEventPublished(String eventType) {
    // Increment counter for event type
  }

  void recordEventProcessed(String eventType, Duration processingTime) {
    // Record processing time histogram
  }

  void recordEventFailed(String eventType, String error) {
    // Increment error counter
  }
}
```

### 2. Consumer Health Monitoring
```dart
class ConsumerHealthMonitor {
  Future<void> checkConsumerHealth() async {
    for (final group in consumerGroups) {
      final lag = await _getConsumerLag(group);
      if (lag > maxAllowedLag) {
        _alertHighLag(group, lag);
      }
    }
  }
}
```

## Migration Strategy

### Phase 1: Infrastructure Setup (Week 1)
1. Set up Redis cluster with streams support
2. Implement basic EventPublisher and EventConsumer
3. Create event schema registry
4. Set up monitoring and logging

### Phase 2: Critical Event Flows (Week 2-3)
1. Implement auction events stream
2. Add payment events stream
3. Create notification consumers
4. Integrate with existing services

### Phase 3: Advanced Features (Week 4-5)
1. Implement event sourcing for critical entities
2. Add saga orchestration for complex workflows
3. Implement dead letter queues
4. Add comprehensive monitoring

### Phase 4: Full Migration (Week 6-8)
1. Migrate all service communication to events
2. Implement event replay capabilities
3. Add advanced consumer scaling
4. Performance optimization and tuning

## Benefits

1. **Decoupling**: Services communicate without direct dependencies
2. **Scalability**: Consumers can scale independently
3. **Reliability**: Durable event storage with replay capabilities
4. **Audit Trail**: Complete history of system state changes
5. **Flexibility**: Easy to add new consumers and event types
6. **Performance**: Asynchronous processing reduces latency
7. **Resilience**: Service failures don't cascade through the system

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Event ordering issues | High | Use single streams per entity, include sequence numbers |
| Duplicate processing | Medium | Implement idempotency keys and deduplication |
| Consumer lag | High | Monitor consumer health, auto-scale consumer groups |
| Schema evolution | Medium | Versioned schemas, backward compatibility |
| Event loss | High | Redis persistence, replication, monitoring |

## Performance Considerations

1. **Throughput**: Redis Streams can handle millions of events per second
2. **Latency**: Sub-millisecond event processing for local consumers
3. **Storage**: Configurable retention policies based on event importance
4. **Network**: Optimize batch sizes and compression for large events

## Security Considerations

1. **Access Control**: ACLs for stream access
2. **Data Encryption**: TLS for Redis connections
3. **Event Authentication**: Signed events for critical operations
4. **Audit Logging**: Complete audit trail of all events

---

**Related ADRs:**
- ADR-001: API Gateway Implementation
- ADR-003: Database Architecture Strategy
- ADR-004: Background Job Processing

**Related Documentation:**
- [Event Bus Implementation Guide](../message-queue-architecture.md)
- [Event Schema Reference](../../stories/17.1-event-schema.md)
- [Consumer Group Configuration](../message-queue-architecture.md)