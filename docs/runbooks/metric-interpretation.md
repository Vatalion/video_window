# Runbook: Metric Interpretation

## Overview

This runbook explains how to interpret metrics from Prometheus/Grafana dashboards and understand what they indicate about system health.

## Key Metrics

### API Metrics

#### api_requests_total (Counter)

**What it measures:** Total number of API requests

**Labels:** method, endpoint, status_code

**How to interpret:**
- Sudden spike: Traffic increase or potential attack
- Sudden drop: Service outage or client-side issues
- Gradual increase: Normal growth

**Queries:**
```promql
# Request rate per second
rate(api_requests_total[5m])

# Request rate by endpoint
sum by (endpoint) (rate(api_requests_total[5m]))

# Success vs error rate
sum by (status_code) (rate(api_requests_total[5m]))
```

#### api_request_duration_ms (Histogram)

**What it measures:** API request latency in milliseconds

**Labels:** endpoint

**How to interpret:**
- P50 (median): Typical user experience
- P95: Experience for slower requests
- P99: Worst-case experience

**Normal values:**
- P50: < 100ms
- P95: < 500ms
- P99: < 1000ms

**Queries:**
```promql
# P95 latency
histogram_quantile(0.95, rate(api_request_duration_ms_bucket[5m]))

# Average latency
rate(api_request_duration_ms_sum[5m]) / rate(api_request_duration_ms_count[5m])

# Latency by endpoint
histogram_quantile(0.95, sum by (endpoint, le) (rate(api_request_duration_ms_bucket[5m])))
```

#### api_errors_total (Counter)

**What it measures:** Total number of API errors

**Labels:** error_type, endpoint

**How to interpret:**
- Error rate > 1%: Investigation needed
- Error rate > 5%: Critical issue
- Spike in specific error type: Targeted problem

**Queries:**
```promql
# Error rate
rate(api_errors_total[5m])

# Error percentage
rate(api_errors_total[5m]) / rate(api_requests_total[5m]) * 100

# Errors by type
sum by (error_type) (rate(api_errors_total[5m]))
```

### Database Metrics

#### db_query_duration_ms (Histogram)

**What it measures:** Database query execution time

**Labels:** query_type

**Normal values:**
- Simple queries: < 10ms
- Complex queries: < 100ms
- Reports/aggregations: < 500ms

**Queries:**
```promql
# P95 query latency
histogram_quantile(0.95, rate(db_query_duration_ms_bucket[5m]))

# Slow queries
histogram_quantile(0.99, rate(db_query_duration_ms_bucket[5m])) > 500
```

#### db_connection_pool_active (Gauge)

**What it measures:** Number of active database connections

**Labels:** None

**How to interpret:**
- Near maximum: Connection pool saturation
- Consistently low: Good performance or low load
- Spiky: Variable load or connection leaks

**Threshold:** > 90% of max = critical

**Queries:**
```promql
# Current active connections
db_connection_pool_active

# Connection pool utilization percentage
db_connection_pool_active / db_connection_pool_max * 100
```

### System Metrics

#### process_resident_memory_bytes (Gauge)

**What it measures:** Memory used by the process

**Normal values:** < 1GB for typical load

**How to interpret:**
- Steady increase: Potential memory leak
- Stable: Healthy
- Sudden drop: Process restart or crash

**Queries:**
```promql
# Current memory usage
process_resident_memory_bytes

# Memory growth rate
rate(process_resident_memory_bytes[1h])
```

#### active_sessions (Gauge)

**What it measures:** Number of active user sessions

**How to interpret:**
- Correlates with user activity
- Sudden drop: Service issue or mass logout
- Growth: User base expansion

**Queries:**
```promql
# Current active sessions
active_sessions

# Session growth
rate(active_sessions[1h])
```

## Dashboard Panels Interpretation

### API Request Rate Panel

**Green (healthy):** Steady or gradually increasing  
**Yellow (warning):** Unusual spikes or drops  
**Red (critical):** Service unavailable (flat line at zero)

**Actions:**
- Spike: Check for traffic source, potential DDoS
- Drop: Investigate service health, check errors

### API Latency Panel

**Green (healthy):** P95 < 500ms  
**Yellow (warning):** P95 500-1000ms  
**Red (critical):** P95 > 1000ms

**Actions:**
- Slow endpoint: Review database queries
- General slowdown: Check system resources
- Gradual increase: Investigate N+1 queries or missing indexes

### Error Rate Panel

**Green (healthy):** Error rate < 1%  
**Yellow (warning):** Error rate 1-5%  
**Red (critical):** Error rate > 5%

**Actions:**
- Check error type distribution
- Review recent deployments
- Inspect logs for specific errors

### Database Query Latency Panel

**Green (healthy):** P95 < 100ms  
**Yellow (warning):** P95 100-500ms  
**Red (critical):** P95 > 500ms

**Actions:**
- Identify slow query types
- Check for missing indexes
- Review query plans with EXPLAIN ANALYZE

## Alert Thresholds

| Metric | Warning | Critical |
|--------|---------|----------|
| API Error Rate | 1% | 5% |
| API P95 Latency | 500ms | 1000ms |
| DB P95 Latency | 100ms | 500ms |
| Memory Usage | 512MB | 1GB |
| Connection Pool | 70% | 90% |

## Common Patterns

### Traffic Spike

**Indicators:**
- Sudden increase in `api_requests_total`
- Possible increase in latency
- Connection pool usage increase

**Actions:**
- Verify legitimate traffic vs attack
- Scale resources if needed
- Enable rate limiting

### Memory Leak

**Indicators:**
- Steady increase in `process_resident_memory_bytes`
- Eventually OOM errors in logs
- Service restarts

**Actions:**
- Review recent code changes
- Profile memory usage
- Check for unclosed connections or cached data

### Database Performance Degradation

**Indicators:**
- Increasing `db_query_duration_ms`
- High `db_connection_pool_active`
- Slow API endpoints

**Actions:**
- Check slow query log
- Review recent schema changes
- Analyze query plans
- Consider adding indexes

### Deployment Impact

**Indicators:**
- Error spike after deployment
- Latency increase after deployment
- Different behavior by endpoint

**Actions:**
- Review deployment changes
- Check configuration differences
- Consider rollback if critical

## Correlation Analysis

Always check multiple metrics together:

1. **High latency + high DB latency** → Database bottleneck
2. **High latency + high memory** → Memory pressure / GC pauses
3. **High errors + specific endpoint** → Code bug in that endpoint
4. **High errors + recent deployment** → Deployment issue
5. **Low traffic + high latency** → Not a load issue, investigate code

## Setting Custom Alerts

When creating new alerts, use these principles:

1. **Actionable:** Alert should require action
2. **Specific:** Clear what's wrong and where
3. **Timely:** Alert before customer impact
4. **Non-flapping:** Stable threshold to avoid noise

Example:
```yaml
- alert: HighEndpointLatency
  expr: histogram_quantile(0.95, rate(api_request_duration_ms_bucket{endpoint="/auth/login"}[5m])) > 1000
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Login endpoint is slow"
    description: "P95 latency is {{ $value }}ms for /auth/login"
```

## Related Runbooks

- [High Error Rates](high-error-rates.md)
- [Performance Degradation](performance-degradation.md)
- [Log Analysis Procedures](log-analysis.md)
