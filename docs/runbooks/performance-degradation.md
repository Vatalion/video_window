# Runbook: Performance Degradation

## Alert: HighLatency / SlowDatabaseQueries

**Severity:** Warning  
**Threshold:** P95 latency > 1000ms for API, > 500ms for database queries

## Symptoms

- Slow API response times
- User complaints about laggy UI
- Increased p95/p99 latency metrics
- Database query timeouts

## Investigation Steps

### 1. Check Current Metrics

```bash
# View Grafana dashboard
# Navigate to: "Video Window - Service Health"
# Review panels: API Latency, Database Query Latency

# Query Prometheus for current latency
curl 'http://localhost:9090/api/v1/query?query=histogram_quantile(0.95,rate(api_request_duration_ms_bucket[5m]))'
```

### 2. Identify Slow Endpoints

```bash
# CloudWatch Logs Insights query
aws logs start-query \
  --log-group-name /video-window/api \
  --start-time $(date -u -d '15 minutes ago' +%s) \
  --end-time $(date -u +%s) \
  --query-string 'fields @timestamp, message, correlation_id
    | filter level = "INFO"
    | stats avg(duration_ms) as avg_duration by endpoint
    | sort avg_duration desc
    | limit 20'
```

### 3. Check Database Performance

```sql
-- Connect to database
psql -h localhost -U postgres -d video_window

-- Find slow queries
SELECT pid, now() - pg_stat_activity.query_start AS duration, query
FROM pg_stat_activity
WHERE state = 'active'
AND now() - pg_stat_activity.query_start > interval '1 second'
ORDER BY duration DESC;

-- Check for locks
SELECT * FROM pg_locks WHERE NOT granted;

-- Check table bloat
SELECT schemaname, tablename, 
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;
```

### 4. Review System Resources

```bash
# Check CPU and memory usage
docker stats video_window_server --no-stream

# Check disk I/O
iostat -x 1 10

# Check network latency to external services
ping -c 5 stripe.com
```

## Common Causes & Solutions

### Database Index Missing

**Symptoms:**
- Specific queries are slow
- Table scans visible in query plans

**Solution:**
```sql
-- Analyze query plan
EXPLAIN ANALYZE <slow-query>;

-- Add missing index
CREATE INDEX idx_<table>_<column> ON <table>(<column>);

-- Update statistics
ANALYZE <table>;
```

### Connection Pool Saturation

**Symptoms:**
- High number of waiting queries
- Connection pool metrics near maximum

**Solution:**
```bash
# Increase connection pool size (temporary)
# Edit docker-compose.yml or server config
# max_connections = 100 -> 150

# Restart service
docker restart video_window_server
```

### External Service Latency

**Symptoms:**
- Timeouts calling Stripe, S3, or other services
- Increased latency for specific endpoints

**Solution:**
- Check status pages of external services
- Implement caching for frequently accessed data
- Add timeouts and circuit breakers
- Consider retry logic with exponential backoff

### Memory Pressure

**Symptoms:**
- High memory usage
- Garbage collection pauses
- OOM errors in logs

**Solution:**
```bash
# Increase memory limit
docker update --memory 2g video_window_server

# Restart container
docker restart video_window_server

# Review memory leaks in application code
```

### N+1 Query Problem

**Symptoms:**
- Many small queries instead of one larger query
- High database query count

**Solution:**
- Use eager loading for related data
- Batch queries where possible
- Implement DataLoader pattern for GraphQL

## Optimization Steps

### 1. Enable Query Caching

```dart
// Add Redis caching layer
final cache = RedisCache();
final result = await cache.getOrSet(
  key: 'user:$userId',
  ttl: Duration(minutes: 5),
  fetch: () => db.getUser(userId),
);
```

### 2. Optimize Database Queries

- Review slow query log
- Add appropriate indexes
- Use EXPLAIN ANALYZE to understand query plans
- Consider denormalization for read-heavy tables

### 3. Implement Rate Limiting

```dart
// Protect against traffic spikes
final rateLimiter = RateLimiter(
  maxRequests: 100,
  window: Duration(minutes: 1),
);
```

## Escalation

If latency remains high after 30 minutes:

1. **Contact:** Database administrator
2. **Escalate to:** Engineering Lead if widespread
3. **Consider:** Scaling up resources

## Post-Incident

1. Review slow query log
2. Implement permanent fixes (indexes, caching)
3. Update capacity planning
4. Consider auto-scaling policies

## Related Runbooks

- [High Error Rates](high-error-rates.md)
- [Log Analysis Procedures](log-analysis.md)
- [Metric Interpretation](metric-interpretation.md)
