# ADR-0003: Database Architecture: PostgreSQL + Redis

**Date:** 2025-10-09
**Status:** Accepted
**Decider(s):** Technical Lead, Database Architect
**Reviewers:** Development Team, DevOps Team

## Context
The video auctions platform requires a robust database architecture that can handle:
- Complex auction data with relational integrity
- Real-time bidding with high concurrency
- User authentication and profile data
- Payment transactions and financial records
- Video metadata and content management
- Analytics and reporting requirements

## Decision
Adopt a hybrid database architecture using PostgreSQL 15 as the primary relational database and Redis 7 for caching, session management, and real-time data coordination.

## Options Considered

1. **Option A** - PostgreSQL Only
   - Pros: ACID compliance, complex queries, mature ecosystem
   - Cons: Limited real-time capabilities, performance bottleneck for high-frequency operations
   - Risk: Performance limitations for real-time bidding

2. **Option B** - MongoDB + Redis
   - Pros: Flexible schema, good for unstructured data
   - Cons: Limited transaction support, eventual consistency challenges
   - Risk: Data consistency issues for financial transactions

3. **Option C** - MySQL + Redis
   - Pros: Good performance, widely adopted
   - Cons: Limited JSON support, fewer advanced features
   - Risk: Limited scalability for complex queries

4. **Option D** - PostgreSQL + Redis (Chosen)
   - Pros: Relational integrity, real-time capabilities, excellent JSON support, mature ecosystem
   - Cons: Two systems to maintain, architectural complexity
   - Risk: Integration complexity between systems

## Decision Outcome
Chose Option D: PostgreSQL + Redis. This provides:
- Strong data consistency and integrity
- Real-time capabilities for auction operations
- Excellent performance for different access patterns
- Mature ecosystem and tooling
- Scalable architecture

## Consequences

- **Positive:**
  - Strong ACID compliance for financial data
  - Real-time auction updates via Redis pub/sub
  - Excellent caching capabilities
  - Complex query support for analytics
  - Mature tooling and monitoring
  - JSONB support for flexible data structures

- **Negative:**
  - Two database systems to maintain
  - Increased infrastructure complexity
  - Data synchronization requirements
  - Backup and recovery complexity

- **Neutral:**
  - Development team learning curve
  - Operational overhead
  - Monitoring and alerting requirements

## Architecture Overview

### PostgreSQL Schema Design
```sql
-- Core Tables
users (id, email, username, profile_data, created_at, updated_at)
auctions (id, title, description, seller_id, start_time, end_time, starting_bid, current_bid, status)
bids (id, auction_id, bidder_id, amount, timestamp, status)
payments (id, user_id, auction_id, amount, status, payment_method, created_at)
videos (id, auction_id, storage_path, metadata, processing_status)

-- JSONB Columns for Flexibility
users.profile_data (JSONB) - Preferences, settings, social links
auctions.metadata (JSONB) - Custom fields, auction rules
videos.metadata (JSONB) - Encoding settings, thumbnails

-- Indexes for Performance
CREATE INDEX idx_auctions_status ON auctions(status);
CREATE INDEX idx_bids_auction_amount ON bids(auction_id, amount DESC);
CREATE INDEX idx_users_email ON users(email);
```

### Redis Data Structures
```redis
# Real-time Auction Data
auction:{id}:current_bid -> current bid amount
auction:{id}:bidders -> Set of active bidders
auction:{id}:updates -> Stream of auction events

# User Sessions
session:{token} -> User session data
user:{id}:notifications -> Queue of user notifications

# Rate Limiting
rate_limit:{user_id}:{endpoint} -> Request counter
rate_limit:{ip}:{endpoint} -> IP-based rate limiting

# Caching
cache:auction:{id} -> Cached auction data
cache:user:{id} -> Cached user profile

# Leaderboards
leaderboard:top_bidders -> Sorted set of top bidders
leaderboard:active_auctions -> Sorted set of active auctions
```

### Data Flow Patterns

#### Real-time Bidding Flow
1. User places bid via WebSocket
2. Server validates bid in PostgreSQL
3. Update Redis with new current bid
4. Publish bid event to Redis pub/sub
5. Notify all connected clients
6. Persist bid details to PostgreSQL

#### Auction Lifecycle
1. Create auction in PostgreSQL
2. Cache auction data in Redis
3. Schedule timer in Redis
4. Monitor real-time updates
5. On completion, finalize in PostgreSQL
6. Clean up Redis data

## Technical Specifications

### PostgreSQL Configuration
```yaml
postgresql:
  version: 15.x
  max_connections: 200
  shared_buffers: 256MB
  effective_cache_size: 1GB
  work_mem: 4MB
  maintenance_work_mem: 64MB
  checkpoint_completion_target: 0.9
  wal_buffers: 16MB
  default_statistics_target: 100
```

### Redis Configuration
```yaml
redis:
  version: 7.x
  maxmemory: 512MB
  maxmemory_policy: allkeys-lru
  save: "900 1 300 10 60 10000"
  timeout: 300
  tcp-keepalive: 300
```

### Connection Management
```dart
// PostgreSQL Connection (via Serverpod)
class Database {
  late final Session _session;

  Future<List<Auction>> getActiveAuctions() async {
    return await _session.db.find<Auction>(
      where: (auction) => auction.status.equals('active'),
      orderBy: (auction) => auction.endTime,
    );
  }
}

// Redis Connection (via Serverpod)
class RedisService {
  late final Redis _redis;

  Future<void> updateCurrentBid(int auctionId, double amount) async {
    await _redis.set('auction:$auctionId:current_bid', amount);
    await _redis.publish('auction:$auctionId:updates', {
      'type': 'bid_update',
      'amount': amount,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
```

## Implementation Strategy

### Phase 1: Database Setup (Week 1)
- Provision PostgreSQL and Redis instances
- Configure connection pooling and security
- Set up automated backups
- Implement monitoring and alerting

### Phase 2: Schema Development (Week 2)
- Design and implement PostgreSQL schema
- Create Redis data structure patterns
- Implement data access layers
- Set up database migrations

### Phase 3: Integration (Week 3)
- Integrate PostgreSQL with Serverpod
- Implement Redis operations
- Create real-time data flows
- Test data consistency

### Phase 4: Optimization (Week 4)
- Performance tuning
- Index optimization
- Caching strategies
- Load testing

## Data Consistency Strategy

### Eventual Consistency
- Redis updates are asynchronous but fast
- PostgreSQL provides source of truth
- Reconciliation processes handle discrepancies

### Transaction Management
- Financial transactions use PostgreSQL ACID
- Redis operations are idempotent
- Rollback mechanisms for failed operations

### Backup and Recovery
- PostgreSQL: Point-in-time recovery
- Redis: AOF + RDB backup strategy
- Regular backup testing

## Monitoring and Alerting

### Key Metrics
- PostgreSQL: Connection count, query performance, deadlock rate
- Redis: Memory usage, hit rate, pub/sub message rate
- Application: Response times, error rates, data consistency

### Alert Thresholds
- PostgreSQL connections > 80% of max
- Redis memory usage > 90%
- Query response time > 1 second
- Redis sync delay > 5 seconds

## Security Considerations

### Access Control
- Database-specific user accounts
- Principle of least privilege
- Encrypted connections (SSL/TLS)
- Regular credential rotation

### Data Protection
- Sensitive data encryption at rest
- PII protection in Redis
- Audit logging for database operations
- Network segmentation

## Related ADRs
- ADR-0002: Flutter + Serverpod Architecture
- ADR-0004: Payment Processing: Stripe Connect Express
- ADR-0005: AWS Infrastructure Strategy

## References
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Redis Documentation](https://redis.io/documentation)
- [Database Architecture Guide](../database-architecture.md)
- [Performance Optimization Guide](../performance-optimization-guide.md)

## Status Updates
- **2025-10-09**: Accepted - Database architecture confirmed
- **2025-10-09**: Schema design in progress
- **TBD**: Implementation phase begins

---

*This ADR establishes a robust hybrid database architecture that balances consistency, performance, and scalability for the video auctions platform.*