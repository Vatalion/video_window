# Database Performance Audit Plan

**Effective Date:** 2025-10-14
**Version:** 1.0
**Target Databases:** PostgreSQL primary, read replicas, Redis cache
**Frequency:** Monthly comprehensive audit + weekly health checks

## Overview

This document outlines a comprehensive database performance audit plan for the Video Window platform. The audit covers query performance, indexing strategy, resource utilization, and scaling considerations to ensure optimal database performance as the platform grows.

## Audit Scope

### 1. Primary PostgreSQL Database
- Query performance analysis
- Index usage and optimization
- Table bloat and fragmentation
- Connection pooling efficiency
- Transaction throughput
- Lock contention analysis

### 2. Read Replicas
- Replication lag monitoring
- Read query distribution
- Replica performance metrics
- Failover readiness

### 3. Redis Cache
- Hit ratio analysis
- Memory usage patterns
- Key distribution and expiration
- Connection efficiency

### 4. Connection and Pool Management
- Pool utilization metrics
- Connection latency analysis
- Timeout and error rates
- Scaling thresholds

## Audit Checklist

### Phase 1: Performance Metrics Collection

#### 1.1 Query Performance Analysis
```sql
-- Top 20 slowest queries (last 7 days)
SELECT
    query,
    calls,
    total_time,
    mean_time,
    rows,
    100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0) AS hit_percent
FROM pg_stat_statements
WHERE mean_time > 100
ORDER BY mean_time DESC
LIMIT 20;

-- Queries with high execution count
SELECT
    query,
    calls,
    total_time,
    mean_time,
    stddev_time
FROM pg_stat_statements
WHERE calls > 1000
ORDER BY calls DESC
LIMIT 20;

-- Queries causing the most total wait time
SELECT
    query,
    calls,
    total_exec_time,
    total_plan_time,
    total_wait_time
FROM pg_stat_statements
WHERE total_wait_time > 0
ORDER BY total_wait_time DESC
LIMIT 20;
```

#### 1.2 Index Usage Analysis
```sql
-- Unused indexes
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY schemaname, tablename;

-- Heavily used indexes
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE idx_scan > 1000
ORDER BY idx_scan DESC;

-- Index size analysis
SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
    idx_scan
FROM pg_stat_user_indexes
ORDER BY pg_relation_size(indexrelid) DESC;
```

#### 1.3 Table Bloat and Fragmentation
```sql
-- Table bloat analysis
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) AS index_size,
    (SELECT COUNT(*) FROM pg_stats WHERE schemaname = s.schemaname AND tablename = s.tablename) AS column_count
FROM pg_tables s
WHERE schemaname NOT IN ('information_schema', 'pg_catalog')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Dead tuple analysis
SELECT
    schemaname,
    tablename,
    n_dead_tup,
    n_live_tup,
    ROUND(n_dead_tup::numeric / (n_dead_tup + n_live_tup) * 100, 2) AS dead_tuple_percent,
    last_vacuum,
    last_autovacuum
FROM pg_stat_user_tables
WHERE n_dead_tup > 0
ORDER BY dead_tuple_percent DESC;
```

#### 1.4 Lock Contention Analysis
```sql
-- Current lock waits
SELECT
    pid,
    now() - pg_stat_activity.query_start AS duration,
    query,
    state,
    wait_event_type,
    wait_event
FROM pg_stat_activity
WHERE wait_event IS NOT NULL;

-- Lock statistics
SELECT
    datname,
    mode,
    COUNT(*) AS lock_count,
    MAX(now() - xact_start) AS longest_wait
FROM pg_locks
JOIN pg_database ON pg_database.oid = pg_locks.database
GROUP BY datname, mode
ORDER BY lock_count DESC;
```

### Phase 2: Resource Utilization Analysis

#### 2.1 Memory Usage
```sql
-- Memory usage by database
SELECT
    datname,
    numbackends,
    xact_commit,
    xact_rollback,
    blks_read,
    blks_hit,
    tup_returned,
    tup_fetched,
    tup_inserted,
    tup_updated,
    tup_deleted
FROM pg_stat_database
WHERE datname NOT IN ('template0', 'template1', 'postgres')
ORDER BY blks_read DESC;

-- Work memory analysis
SELECT
    name,
    setting,
    unit,
    short_desc
FROM pg_settings
WHERE name LIKE '%work_mem%' OR name LIKE '%maintenance_work_mem%';
```

#### 2.2 Disk I/O Analysis
```sql
-- Database I/O statistics
SELECT
    datname,
    blks_read,
    blks_hit,
    blks_read + blks_hit AS total_blocks,
    ROUND(blks_hit::numeric / (blks_hit + blks_read) * 100, 2) AS cache_hit_ratio
FROM pg_stat_database
WHERE datname NOT IN ('template0', 'template1', 'postgres')
ORDER BY total_blocks DESC;

-- Table I/O statistics
SELECT
    schemaname,
    tablename,
    seq_scan,
    seq_tup_read,
    idx_scan,
    idx_tup_fetch,
    n_tup_ins,
    n_tup_upd,
    n_tup_del,
    n_tup_hot_upd
FROM pg_stat_user_tables
ORDER BY (seq_tup_read + idx_tup_fetch) DESC;
```

### Phase 3: Connection Analysis

#### 3.1 Connection Pool Statistics
```sql
-- Active connections by database
SELECT
    datname,
    COUNT(*) AS connection_count,
    COUNT(CASE WHEN state = 'active' THEN 1 END) AS active_connections,
    COUNT(CASE WHEN state = 'idle' THEN 1 END) AS idle_connections,
    COUNT(CASE WHEN state = 'idle in transaction' THEN 1 END) AS idle_in_transaction
FROM pg_stat_activity
WHERE datname IS NOT NULL
GROUP BY datname;

-- Long-running queries
SELECT
    pid,
    now() - pg_stat_activity.query_start AS duration,
    query,
    state,
    application_name
FROM pg_stat_activity
WHERE now() - pg_stat_activity.query_start > interval '5 minutes'
ORDER BY duration DESC;
```

### Phase 4: Redis Performance Analysis

#### 4.1 Redis Metrics Collection
```bash
# Redis info command
redis-cli INFO memory
redis-cli INFO stats
redis-cli INFO replication
redis-cli INFO clients

# Slow log analysis
redis-cli SLOWLOG GET 20

# Memory usage by key patterns
redis-cli --scan --pattern "auction:*" | head -10 | xargs -I {} redis-cli MEMORY USAGE {}
```

#### 4.2 Cache Hit Ratio Analysis
```javascript
// Redis Lua script for cache analysis
local keys = redis.call('KEYS', ARGV[1])
local total_hits = 0
local total_requests = 0

for i=1,#keys do
    local hits = redis.call('HGET', keys[i], 'hits') or 0
    local requests = redis.call('HGET', keys[i], 'requests') or 0
    total_hits = total_hits + tonumber(hits)
    total_requests = total_requests + tonumber(requests)
end

if total_requests > 0 then
    return total_hits / total_requests
else
    return 0
end
```

## Performance Benchmarks and Thresholds

### Query Performance Targets
- **Simple SELECT queries**: < 10ms
- **Complex JOIN queries**: < 100ms
- **INSERT/UPDATE operations**: < 50ms
- **Bulk operations**: < 1000ms
- **Cache hits**: < 1ms

### Resource Utilization Targets
- **CPU usage**: < 70% average, < 90% peak
- **Memory usage**: < 80% of allocated memory
- **Disk I/O**: < 80% of available IOPS
- **Network bandwidth**: < 70% of available bandwidth
- **Connection pool utilization**: < 80%

### Database Health Indicators
- **Cache hit ratio**: > 95%
- **Dead tuple ratio**: < 5%
- **Autovacuum effectiveness**: > 90% dead tuples cleaned
- **Replication lag**: < 1 second
- **Lock wait time**: < 100ms average

## Automated Audit Scripts

### 1. Database Health Check Script
```python
#!/usr/bin/env python3
"""
Database Health Check Script
Runs comprehensive performance analysis and generates report
"""

import psycopg2
import redis
import json
import datetime
from collections import defaultdict

class DatabaseAuditor:
    def __init__(self, db_config, redis_config):
        self.db_config = db_config
        self.redis_config = redis_config
        self.results = defaultdict(dict)

    def run_full_audit(self):
        """Run complete database performance audit"""
        print("Starting database performance audit...")

        # PostgreSQL audit
        self.audit_query_performance()
        self.audit_index_usage()
        self.audit_table_bloat()
        self.audit_lock_contention()
        self.audit_resource_utilization()
        self.audit_connections()

        # Redis audit
        self.audit_redis_performance()

        # Generate report
        self.generate_report()

    def audit_query_performance(self):
        """Analyze query performance"""
        print("Analyzing query performance...")

        queries = [
            # Slow queries
            """
            SELECT query, calls, total_time, mean_time, rows
            FROM pg_stat_statements
            WHERE mean_time > 100
            ORDER BY mean_time DESC
            LIMIT 20
            """,
            # High frequency queries
            """
            SELECT query, calls, total_time, mean_time
            FROM pg_stat_statements
            WHERE calls > 1000
            ORDER BY calls DESC
            LIMIT 20
            """
        ]

        for i, query in enumerate(queries):
            self.results['queries'][f'query_set_{i}'] = self.execute_query(query)

    def audit_redis_performance(self):
        """Analyze Redis performance"""
        print("Analyzing Redis performance...")

        r = redis.Redis(**self.redis_config)

        # Get Redis info
        info = r.info()

        self.results['redis'] = {
            'memory_used': info['used_memory'],
            'memory_peak': info['used_memory_peak'],
            'keyspace_hits': info['keyspace_hits'],
            'keyspace_misses': info['keyspace_misses'],
            'connected_clients': info['connected_clients'],
            'total_commands_processed': info['total_commands_processed'],
            'cache_hit_ratio': info['keyspace_hits'] / max(info['keyspace_hits'] + info['keyspace_misses'], 1)
        }

        # Get slow log
        slow_log = r.slowlog_get(20)
        self.results['redis']['slow_queries'] = slow_log

    def generate_report(self):
        """Generate comprehensive audit report"""
        report = {
            'timestamp': datetime.datetime.now().isoformat(),
            'results': dict(self.results),
            'recommendations': self.generate_recommendations()
        }

        # Save report
        filename = f"database_audit_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(filename, 'w') as f:
            json.dump(report, f, indent=2, default=str)

        print(f"Audit report saved to: {filename}")

        # Print summary
        self.print_summary(report)

    def generate_recommendations(self):
        """Generate performance optimization recommendations"""
        recommendations = []

        # Analyze query performance
        slow_queries = self.results.get('queries', {}).get('query_set_0', [])
        if slow_queries and len(slow_queries) > 10:
            recommendations.append({
                'priority': 'HIGH',
                'category': 'Queries',
                'issue': f'Found {len(slow_queries)} slow queries',
                'recommendation': 'Review and optimize slow queries, add missing indexes'
            })

        # Analyze cache hit ratio
        redis_stats = self.results.get('redis', {})
        cache_hit_ratio = redis_stats.get('cache_hit_ratio', 0)
        if cache_hit_ratio < 0.95:
            recommendations.append({
                'priority': 'MEDIUM',
                'category': 'Redis',
                'issue': f'Cache hit ratio is {cache_hit_ratio:.2%}',
                'recommendation': 'Review cache strategy and key expiration policies'
            })

        return recommendations

    def execute_query(self, query):
        """Execute PostgreSQL query"""
        conn = psycopg2.connect(**self.db_config)
        try:
            with conn.cursor() as cur:
                cur.execute(query)
                columns = [desc[0] for desc in cur.description]
                return [dict(zip(columns, row)) for row in cur.fetchall()]
        finally:
            conn.close()

if __name__ == "__main__":
    # Configuration
    db_config = {
        'host': 'localhost',
        'database': 'videowindow',
        'user': 'postgres',
        'password': 'password'
    }

    redis_config = {
        'host': 'localhost',
        'port': 6379,
        'db': 0
    }

    auditor = DatabaseAuditor(db_config, redis_config)
    auditor.run_full_audit()
```

### 2. Weekly Health Check Script
```bash
#!/bin/bash
# Weekly Database Health Check

echo "=== Database Health Check - $(date) ==="

# PostgreSQL health checks
echo "1. PostgreSQL Connection Count:"
psql -h localhost -U postgres -d videowindow -c "
SELECT COUNT(*) as total_connections,
       COUNT(CASE WHEN state = 'active' THEN 1 END) as active_connections
FROM pg_stat_activity;"

echo -e "\n2. Database Size:"
psql -h localhost -U postgres -d videowindow -c "
SELECT pg_size_pretty(pg_database_size('videowindow')) as database_size;"

echo -e "\n3. Cache Hit Ratio:"
psql -h localhost -U postgres -d videowindow -c "
SELECT
    blks_hit,
    blks_read,
    ROUND(blks_hit::numeric / (blks_hit + blks_read) * 100, 2) AS cache_hit_ratio
FROM pg_stat_database
WHERE datname = 'videowindow';"

echo -e "\n4. Long-running Queries:"
psql -h localhost -U postgres -d videowindow -c "
SELECT pid, now() - query_start AS duration, query
FROM pg_stat_activity
WHERE now() - query_start > interval '5 minutes'
AND state = 'active';"

# Redis health checks
echo -e "\n5. Redis Memory Usage:"
redis-cli INFO memory | grep used_memory

echo -e "\n6. Redis Cache Hit Ratio:"
redis-cli EVAL "
local hits = redis.call('INFO', 'stats'):match('keyspace_hits:(%d+)')
local misses = redis.call('INFO', 'stats'):match('keyspace_misses:(%d+)')
if hits and misses then
    local ratio = tonumber(hits) / (tonumber(hits) + tonumber(misses))
    return ratio * 100
else
    return 0
end
" 0

echo -e "\n=== Health Check Complete ==="
```

## Performance Optimization Recommendations

### 1. Query Optimization
- **Index Optimization**: Add missing indexes based on query patterns
- **Query Rewriting**: Optimize complex JOINs and subqueries
- **Partitioning**: Implement table partitioning for large tables
- **Materialized Views**: Create materialized views for complex aggregations

### 2. Index Strategy
```sql
-- Recommended indexes for core tables

-- Auctions table
CREATE INDEX CONCURRENTLY idx_auctions_seller_status
ON auctions(seller_id, status)
WHERE status IN ('active', 'ended');

CREATE INDEX CONCURRENTLY idx_auctions_category_end_time
ON auctions(category, end_time)
WHERE status = 'active';

CREATE INDEX CONCURRENTLY idx_auctions_created_at
ON auctions(created_at DESC);

-- Bids table
CREATE INDEX CONCURRENTLY idx_bids_auction_amount
ON bids(auction_id, amount DESC);

CREATE INDEX CONCURRENTLY idx_bids_bidder_created
ON bids(bidder_id, created_at DESC);

-- Users table
CREATE INDEX CONCURRENTLY idx_users_email_active
ON users(email)
WHERE is_active = true;

CREATE INDEX CONCURRENTLY idx_users_created_at
ON users(created_at DESC);

-- Payments table
CREATE INDEX CONCURRENTLY idx_payments_user_status
ON payments(user_id, status);

CREATE INDEX CONCURRENTLY idx_payments_created_at
ON payments(created_at DESC);

-- Orders table
CREATE INDEX CONCURRENTLY idx_orders_buyer_status
ON orders(buyer_id, status);

CREATE INDEX CONCURRENTLY idx_orders_seller_status
ON orders(seller_id, status);
```

### 3. Database Configuration Tuning
```postgresql
# PostgreSQL configuration recommendations

# Memory settings
shared_buffers = 25% of RAM
effective_cache_size = 75% of RAM
work_mem = 4MB per connection
maintenance_work_mem = 64MB-256MB

# Connection settings
max_connections = 200
superuser_reserved_connections = 3

# Checkpoint settings
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100

# Autovacuum settings
autovacuum = on
autovacuum_max_workers = 3
autovacuum_naptime = 1min
```

### 4. Redis Optimization
```bash
# Redis configuration recommendations

# Memory optimization
maxmemory 2gb
maxmemory-policy allkeys-lru

# Persistence settings
save 900 1
save 300 10
save 60 10000

# Connection settings
tcp-keepalive 300
timeout 0

# Client optimization
tcp-backlog 511
```

## Monitoring and Alerting

### 1. Key Metrics to Monitor
- **Query latency**: P95, P99 response times
- **Error rates**: Failed queries, connection errors
- **Resource utilization**: CPU, memory, disk I/O
- **Cache performance**: Hit ratios, miss rates
- **Replication lag**: Primary to replica delay
- **Connection pool**: Active connections, wait times

### 2. Alert Thresholds
```yaml
alerts:
  database:
    slow_queries:
      threshold: 5
      window: 5m
      severity: warning

    high_cpu:
      threshold: 80
      window: 10m
      severity: critical

    low_cache_hit_ratio:
      threshold: 90
      window: 15m
      severity: warning

    replication_lag:
      threshold: 5s
      window: 1m
      severity: critical

    connection_pool_exhaustion:
      threshold: 90
      window: 5m
      severity: critical
```

## Reporting Schedule

### Weekly Reports
- Database health summary
- Top 10 slow queries
- Cache performance metrics
- Connection pool statistics
- Replication status

### Monthly Reports
- Comprehensive performance analysis
- Index usage and optimization recommendations
- Resource utilization trends
- Capacity planning recommendations
- Security audit results

### Quarterly Reviews
- Architecture optimization review
- Scaling strategy assessment
- Performance benchmarking
- Cost optimization analysis
- Disaster recovery testing

---

**Related Documents:**
- [Database Indexing Strategy](database-indexing-strategy.md)
- [API Gateway Implementation](../adr/ADR-001-api-gateway.md)
- [Event-Driven Architecture](../adr/ADR-002-event-driven-architecture.md)

**Next Steps:**
1. Implement automated audit scripts
2. Set up monitoring and alerting
3. Create performance baseline
4. Schedule regular audit cycles
5. Establish performance optimization workflow