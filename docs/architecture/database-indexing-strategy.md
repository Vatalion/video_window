# Database Indexing Strategy

**Effective Date:** 2025-10-14
**Version:** 1.0
**Database:** PostgreSQL 15+
**Objective:** Optimize query performance while maintaining write efficiency

## Overview

This document outlines a comprehensive indexing strategy for the Video Window platform's PostgreSQL database. The strategy focuses on optimizing read performance for critical user journeys while minimizing the impact on write operations.

## Indexing Principles

### 1. Query-Driven Indexing
- Indexes are created based on actual query patterns
- Each index serves specific query access patterns
- Regular review of index usage statistics

### 2. Selective Indexing
- Focus on high-impact indexes first
- Avoid over-indexing which can hurt write performance
- Consider read-to-write ratios for each table

### 3. Performance Monitoring
- Regular monitoring of index usage
- Identify and remove unused indexes
- Optimize based on actual query performance data

## Core Table Indexing Strategy

### 1. Users Table

```sql
-- Primary users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    bio TEXT,
    avatar_url TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    seller_rating DECIMAL(3,2) CHECK (seller_rating >= 0 AND seller_rating <= 5),
    role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('user', 'seller', 'moderator', 'admin')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at TIMESTAMP WITH TIME ZONE,
    email_verified_at TIMESTAMP WITH TIME ZONE
);

-- Indexes for users table
CREATE UNIQUE INDEX CONCURRENTLY idx_users_email ON users(email) WHERE is_active = TRUE;
CREATE UNIQUE INDEX CONCURRENTLY idx_users_username ON users(username) WHERE is_active = TRUE;
CREATE INDEX CONCURRENTLY idx_users_role_active ON users(role, is_active) WHERE is_active = TRUE;
CREATE INDEX CONCURRENTLY idx_users_created_at ON users(created_at DESC);
CREATE INDEX CONCURRENTLY idx_users_last_login ON users(last_login_at DESC NULLS LAST) WHERE is_active = TRUE;
CREATE INDEX CONCURRENTLY idx_users_seller_rating ON users(seller_rating DESC) WHERE seller_rating IS NOT NULL;
CREATE INDEX CONCURRENTLY idx_users_verified ON users(is_verified, created_at DESC) WHERE is_active = TRUE;

-- Full-text search for user profiles
CREATE INDEX CONCURRENTLY idx_users_fulltext ON users USING gin(
    to_tsvector('english', coalesce(full_name, '') || ' ' || coalesce(bio, ''))
) WHERE is_active = TRUE;
```

### 2. Auctions Table

```sql
-- Main auctions table
CREATE TABLE auctions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id UUID NOT NULL REFERENCES users(id),
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(50) NOT NULL,
    starting_price DECIMAL(12,2) NOT NULL CHECK (starting_price > 0),
    current_bid DECIMAL(12,2) DEFAULT 0 CHECK (current_bid >= 0),
    reserve_price DECIMAL(12,2) CHECK (reserve_price IS NULL OR reserve_price >= starting_price),
    bid_count INTEGER DEFAULT 0 CHECK (bid_count >= 0),
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'ended', 'cancelled', 'sold')),
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    shipping_info JSONB,
    tags TEXT[],
    view_count INTEGER DEFAULT 0 CHECK (view_count >= 0),
    featured BOOLEAN DEFAULT FALSE,
    featured_until TIMESTAMP WITH TIME ZONE
);

-- Core indexes for auctions
CREATE INDEX CONCURRENTLY idx_auctions_seller_status ON auctions(seller_id, status) WHERE status IN ('active', 'ended');
CREATE INDEX CONCURRENTLY idx_auctions_category_end_time ON auctions(category, end_time DESC) WHERE status = 'active';
CREATE INDEX CONCURRENTLY idx_auctions_status_end_time ON auctions(status, end_time DESC) WHERE status IN ('active', 'ended');
CREATE INDEX CONCURRENTLY idx_auctions_start_time ON auctions(start_time) WHERE status = 'draft';
CREATE INDEX CONCURRENTLY idx_auctions_created_at ON auctions(created_at DESC);
CREATE INDEX CONCURRENTLY idx_auctions_current_bid ON auctions(current_bid DESC NULLS LAST) WHERE status = 'active';
CREATE INDEX CONCURRENTLY idx_auctions_bid_count ON auctions(bid_count DESC NULLS LAST) WHERE status = 'active';

-- Pricing indexes
CREATE INDEX CONCURRENTLY idx_auctions_price_range ON auctions(starting_price, current_bid) WHERE status = 'active';
CREATE INDEX CONCURRENTLY idx_auctions_featured ON auctions(featured, featured_until DESC) WHERE featured = TRUE AND featured_until > NOW();

-- Search and filtering indexes
CREATE INDEX CONCURRENTLY idx_auctions_tags ON auctions USING gin(tags) WHERE status = 'active';
CREATE INDEX CONCURRENTLY idx_auctions_fulltext ON auctions USING gin(
    to_tsvector('english', title || ' ' || description)
) WHERE status = 'active';

-- Composite index for browsing (most common query pattern)
CREATE INDEX CONCURRENTLY idx_auctions_browse ON auctions(status, category, end_time DESC, current_bid DESC)
WHERE status = 'active';

-- Partial index for seller's auction management
CREATE INDEX CONCURRENTLY idx_auctions_seller_management ON auctions(created_at DESC, status)
WHERE seller_id IS NOT NULL;
```

### 3. Bids Table

```sql
-- Bids table
CREATE TABLE bids (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auction_id UUID NOT NULL REFERENCES auctions(id),
    bidder_id UUID NOT NULL REFERENCES users(id),
    amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    message TEXT,
    is_winning BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for bids table
CREATE INDEX CONCURRENTLY idx_bids_auction_amount ON bids(auction_id, amount DESC);
CREATE INDEX CONCURRENTLY idx_bids_bidder_created ON bids(bidder_id, created_at DESC);
CREATE INDEX CONCURRENTLY idx_bids_auction_created ON bids(auction_id, created_at DESC);
CREATE INDEX CONCURRENTLY idx_bids_winning ON bids(auction_id) WHERE is_winning = TRUE;

-- Index for bid history queries
CREATE INDEX CONCURRENTLY idx_bids_history ON bids(auction_id, created_at DESC, amount DESC);

-- Prevent duplicate bids from same user in short timeframe
CREATE UNIQUE INDEX CONCURRENTLY idx_bids_unique_recent ON bids(auction_id, bidder_id, created_at)
WHERE created_at > NOW() - INTERVAL '5 minutes';
```

### 4. Payments Table

```sql
-- Payments table
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES orders(id),
    user_id UUID NOT NULL REFERENCES users(id),
    stripe_payment_intent_id VARCHAR(255) UNIQUE,
    amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    currency VARCHAR(3) DEFAULT 'USD',
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'succeeded', 'failed', 'cancelled', 'refunded')),
    fees DECIMAL(12,2) DEFAULT 0 CHECK (fees >= 0),
    net_amount DECIMAL(12,2) GENERATED ALWAYS AS (amount - fees) STORED,
    payment_method_id VARCHAR(255),
    failure_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE
);

-- Indexes for payments table
CREATE INDEX CONCURRENTLY idx_payments_user_status ON payments(user_id, status);
CREATE INDEX CONCURRENTLY idx_payments_status_created ON payments(status, created_at DESC);
CREATE INDEX CONCURRENTLY idx_payments_order ON payments(order_id) WHERE order_id IS NOT NULL;
CREATE INDEX CONCURRENTLY idx_payments_stripe_intent ON payments(stripe_payment_intent_id) WHERE stripe_payment_intent_id IS NOT NULL;
CREATE INDEX CONCURRENTLY idx_payments_amount ON payments(amount DESC) WHERE status = 'succeeded';
CREATE INDEX CONCURRENTLY idx_payments_processed_at ON payments(processed_at DESC NULLS LAST) WHERE processed_at IS NOT NULL;
```

### 5. Orders Table

```sql
-- Orders table
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auction_id UUID NOT NULL REFERENCES auctions(id),
    buyer_id UUID NOT NULL REFERENCES users(id),
    seller_id UUID NOT NULL REFERENCES users(id),
    final_price DECIMAL(12,2) NOT NULL CHECK (final_price > 0),
    payment_id UUID REFERENCES payments(id),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled', 'refunded')),
    tracking_number VARCHAR(100),
    carrier VARCHAR(50),
    shipping_address JSONB NOT NULL,
    shipping_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    confirmed_at TIMESTAMP WITH TIME ZONE,
    shipped_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE
);

-- Indexes for orders table
CREATE INDEX CONCURRENTLY idx_orders_buyer_status ON orders(buyer_id, status);
CREATE INDEX CONCURRENTLY idx_orders_seller_status ON orders(seller_id, status);
CREATE INDEX CONCURRENTLY idx_orders_auction ON orders(auction_id);
CREATE INDEX CONCURRENTLY idx_orders_payment ON orders(payment_id) WHERE payment_id IS NOT NULL;
CREATE INDEX CONCURRENTLY idx_orders_status_created ON orders(status, created_at DESC);
CREATE INDEX CONCURRENTLY idx_orders_tracking ON orders(tracking_number) WHERE tracking_number IS NOT NULL;
CREATE INDEX CONCURRENTLY idx_orders_carrier ON orders(carrier, shipped_at DESC) WHERE shipped_at IS NOT NULL;

-- Composite index for order management
CREATE INDEX CONCURRENTLY idx_orders_management ON orders(seller_id, status, created_at DESC);
```

### 6. Notifications Table

```sql
-- Notifications table
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    type VARCHAR(50) NOT NULL,
    channel VARCHAR(20) DEFAULT 'in_app' CHECK (channel IN ('email', 'push', 'sms', 'in_app')),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    data JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE
);

-- Indexes for notifications table
CREATE INDEX CONCURRENTLY idx_notifications_user_unread ON notifications(user_id, is_read, created_at DESC) WHERE is_read = FALSE;
CREATE INDEX CONCURRENTLY idx_notifications_user_type ON notifications(user_id, type, created_at DESC);
CREATE INDEX CONCURRENTLY idx_notifications_channel_status ON notifications(channel, is_read) WHERE is_read = FALSE;
CREATE INDEX CONCURRENTLY idx_notifications_expires ON notifications(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX CONCURRENTLY idx_notifications_created_at ON notifications(created_at DESC);

-- Partial index for unread notifications cleanup
CREATE INDEX CONCURRENTLY idx_notifications_old_unread ON notifications(created_at)
WHERE is_read = FALSE AND created_at < NOW() - INTERVAL '30 days';
```

## Specialized Indexes

### 1. Full-Text Search Indexes

```sql
-- Auction full-text search
CREATE INDEX CONCURRENTLY idx_auctions_search_title ON auctions USING gin(
    to_tsvector('english', title)
) WHERE status = 'active';

CREATE INDEX CONCURRENTLY idx_auctions_search_description ON auctions USING gin(
    to_tsvector('english', description)
) WHERE status = 'active';

-- Combined title and description search
CREATE INDEX CONCURRENTLY idx_auctions_search_combined ON auctions USING gin(
    to_tsvector('english', coalesce(title, '') || ' ' || coalesce(description, ''))
) WHERE status = 'active';

-- User profile search
CREATE INDEX CONCURRENTLY idx_users_search_profile ON users USING gin(
    to_tsvector('english', coalesce(full_name, '') || ' ' || coalesce(bio, '') || ' ' || coalesce(username, ''))
) WHERE is_active = TRUE;
```

### 2. JSONB Indexes

```sql
-- Shipping info indexes
CREATE INDEX CONCURRENTLY idx_auctions_shipping_location ON auctions USING gin(
    (shipping_info->'location')
) WHERE shipping_info IS NOT NULL;

CREATE INDEX CONCURRENTLY idx_auctions_shipping_methods ON auctions USING gin(
    (shipping_info->'available_methods')
) WHERE shipping_info IS NOT NULL;

-- Notification data indexes
CREATE INDEX CONCURRENTLY idx_notifications_data_auction ON notifications USING gin(
    (data->'auctionId')
) WHERE data ? 'auctionId';

CREATE INDEX CONCURRENTLY idx_notifications_data_bid ON notifications USING gin(
    (data->'bidId')
) WHERE data ? 'bidId';
```

### 3. Time-Series Indexes

```sql
-- Time-based partitioning indexes (for large tables)
CREATE INDEX CONCURRENTLY idx_auctions_time_partition ON auctions(date_trunc('month', created_at), status);
CREATE INDEX CONCURRENTLY idx_bids_time_partition ON bids(date_trunc('day', created_at), auction_id);
CREATE INDEX CONCURRENTLY idx_payments_time_partition ON payments(date_trunc('day', created_at), status);
```

## Partitioning Strategy

### 1. Time-Based Partitioning

```sql
-- Partition bids table by month (for high-volume bidding data)
CREATE TABLE bids_partitioned (
    LIKE bids INCLUDING ALL
) PARTITION BY RANGE (created_at);

-- Create monthly partitions
CREATE TABLE bids_2024_01 PARTITION OF bids_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE bids_2024_02 PARTITION OF bids_partitioned
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

-- Continue for each month...

-- Create indexes on partitions
CREATE INDEX idx_bids_2024_01_auction_amount ON bids_2024_01(auction_id, amount DESC);
CREATE INDEX idx_bids_2024_01_bidder_created ON bids_2024_01(bidder_id, created_at DESC);
```

### 2. Category-Based Partitioning

```sql
-- Partition auctions by category for very large datasets
CREATE TABLE auctions_by_category (
    LIKE auctions INCLUDING ALL
) PARTITION BY LIST (category);

-- Create partitions for major categories
CREATE TABLE auctions_electronics PARTITION OF auctions_by_category
    FOR VALUES IN ('electronics', 'computers', 'phones');

CREATE TABLE auctions_fashion PARTITION OF auctions_by_category
    FOR VALUES IN ('clothing', 'shoes', 'accessories');

CREATE TABLE auctions_home PARTITION OF auctions_by_category
    FOR VALUES IN ('furniture', 'decor', 'appliances');
```

## Index Maintenance

### 1. Index Usage Monitoring

```sql
-- Check index usage statistics
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC;

-- Find unused indexes
SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;
```

### 2. Index Bloat Analysis

```sql
-- Check for index bloat
SELECT
    nspname AS schema_name,
    relname AS table_name,
    indexrelname AS index_name,
    ROUND(100 * (
        (bs.relpages - floor((relpages * (1 - (bs.bloat_percent / 100.0)))))
        / bs.relpages::float
    ), 2) AS bloat_percent,
    pg_size_pretty((bs.relpages - floor((relpages * (1 - (bs.bloat_percent / 100.0))))) * 8192) AS bloat_size
FROM pg_stat_all_indexes i
JOIN pg_class c ON c.oid = i.indexrelid
JOIN (
    SELECT
        indexrelid,
        relpages,
        (100 * (1 - (relpages / (
            SELECT CEIL(SUM(relpages) / COUNT(indexrelid))
            FROM pg_stat_all_indexes ii
            WHERE ii.indexrelid = i.indexrelid
            GROUP BY indexrelid
        )))) AS bloat_percent
    FROM pg_stat_all_indexes i
    WHERE i.schemaname NOT IN ('pg_catalog', 'information_schema')
) bs ON bs.indexrelid = i.indexrelid
WHERE bs.bloat_percent > 10
ORDER BY bloat_percent DESC;
```

### 3. Automated Index Maintenance

```sql
-- Function to create indexes concurrently
CREATE OR REPLACE FUNCTION create_index_concurrently(
    index_name TEXT,
    table_name TEXT,
    index_definition TEXT
) RETURNS VOID AS $$
BEGIN
    EXECUTE format('CREATE INDEX CONCURRENTLY IF NOT EXISTS %I ON %I %s',
                   index_name, table_name, index_definition);
END;
$$ LANGUAGE plpgsql;

-- Function to rebuild indexes with low bloat
CREATE OR REPLACE FUNCTION rebuild_index_if_needed(
    schema_name TEXT,
    table_name TEXT,
    index_name TEXT,
    bloat_threshold DECIMAL DEFAULT 10.0
) RETURNS BOOLEAN AS $$
DECLARE
    bloat_percent DECIMAL;
BEGIN
    -- Calculate bloat percentage (simplified)
    SELECT ROUND(100 * (
        (relpages - (SELECT AVG(relpages) FROM pg_stat_all_indexes
                    WHERE schemaname = schema_name AND tablename = table_name))
        / relpages::float
    ), 2) INTO bloat_percent
    FROM pg_stat_all_indexes
    WHERE schemaname = schema_name AND tablename = table_name AND indexname = index_name;

    IF bloat_percent > bloat_threshold THEN
        EXECUTE format('REINDEX INDEX CONCURRENTLY %I.%I', schema_name, index_name);
        RETURN TRUE;
    END IF;

    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;
```

## Performance Testing and Optimization

### 1. Query Performance Testing

```sql
-- Test auction browsing query
EXPLAIN (ANALYZE, BUFFERS)
SELECT a.*, u.username as seller_name, u.seller_rating
FROM auctions a
JOIN users u ON a.seller_id = u.id
WHERE a.status = 'active'
  AND a.category = 'electronics'
  AND a.end_time > NOW()
ORDER BY a.end_time ASC, a.current_bid DESC
LIMIT 20;

-- Test user's bids query
EXPLAIN (ANALYZE, BUFFERS)
SELECT b.*, a.title, a.end_time, a.status as auction_status
FROM bids b
JOIN auctions a ON b.auction_id = a.id
WHERE b.bidder_id = $1
ORDER BY b.created_at DESC
LIMIT 50;

-- Test search query
EXPLAIN (ANALYZE, BUFFERS)
SELECT a.*, u.username as seller_name
FROM auctions a
JOIN users u ON a.seller_id = u.id
WHERE a.status = 'active'
  AND to_tsvector('english', a.title || ' ' || a.description) @@ to_tsquery('english', $1)
ORDER BY a.end_time ASC, a.current_bid DESC
LIMIT 20;
```

### 2. Index Performance Metrics

```sql
-- Create monitoring view for index performance
CREATE VIEW index_performance_monitor AS
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
    CASE
        WHEN idx_scan = 0 THEN 'UNUSED'
        WHEN idx_scan < 10 THEN 'LOW_USAGE'
        WHEN idx_scan < 100 THEN 'MEDIUM_USAGE'
        ELSE 'HIGH_USAGE'
    END AS usage_level
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC;

-- Index efficiency calculation
CREATE VIEW index_efficiency AS
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    CASE
        WHEN idx_scan > 0 THEN ROUND(idx_tup_read::DECIMAL / idx_scan, 2)
        ELSE 0
    END AS avg_tuples_per_scan,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE idx_scan > 0
ORDER BY avg_tuples_per_scan DESC;
```

## Indexing Best Practices

### 1. Design Principles
- **Index for queries, not tables**: Each index should serve specific query patterns
- **Keep indexes narrow**: Include only necessary columns
- **Consider column order**: Most selective columns first
- **Use partial indexes**: For filtering subsets of data
- **Monitor regularly**: Remove unused indexes

### 2. Performance Considerations
- **Write overhead**: Each index adds overhead to INSERT/UPDATE/DELETE operations
- **Storage costs**: Indexes consume additional disk space
- **Maintenance overhead**: Indexes need to be updated and potentially rebuilt
- **Query planning**: Too many indexes can confuse the query planner

### 3. Maintenance Schedule
- **Weekly**: Monitor index usage statistics
- **Monthly**: Check for index bloat and fragmentation
- **Quarterly**: Review and optimize index strategy based on query patterns
- **As needed**: Add/remove indexes based on application requirements

## Index Creation Scripts

### 1. Production Deployment Script

```bash
#!/bin/bash
# Production index deployment script

set -e

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-videowindow}"
DB_USER="${DB_USER:-postgres}"

echo "Starting index deployment for database: $DB_NAME"

# Function to execute SQL with error handling
execute_sql() {
    local sql_file=$1
    echo "Executing: $sql_file"
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$sql_file"
    if [ $? -eq 0 ]; then
        echo "✅ Successfully executed: $sql_file"
    else
        echo "❌ Failed to execute: $sql_file"
        exit 1
    fi
}

# Deploy indexes in order of priority
execute_sql "indexes/01_users_indexes.sql"
execute_sql "indexes/02_auctions_indexes.sql"
execute_sql "indexes/03_bids_indexes.sql"
execute_sql "indexes/04_payments_indexes.sql"
execute_sql "indexes/05_orders_indexes.sql"
execute_sql "indexes/06_notifications_indexes.sql"
execute_sql "indexes/07_search_indexes.sql"

echo "✅ All indexes deployed successfully"
```

### 2. Index Verification Script

```bash
#!/bin/bash
# Index verification script

DB_NAME="${DB_NAME:-videowindow}"

echo "Verifying indexes for database: $DB_NAME"

# Check if all expected indexes exist
psql -d "$DB_NAME" -c "
SELECT
    tablename,
    indexname,
    'EXISTS' as status
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
"

# Check index sizes
psql -d "$DB_NAME" -c "
SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS size,
    idx_scan as usage_count
FROM pg_stat_user_indexes
ORDER BY pg_relation_size(indexrelid) DESC;
"

echo "Index verification complete"
```

---

**Related Documents:**
- [Database Performance Audit Plan](database-performance-audit-plan.md)
- [Event-Driven Architecture](adr/ADR-0012-event-driven-architecture.md)
- [API Gateway Implementation](adr/ADR-0011-api-gateway.md)

**Next Steps:**
1. Implement automated index monitoring
2. Set up regular performance testing
3. Create index deployment automation
4. Establish index maintenance procedures
5. Monitor and optimize based on real usage patterns