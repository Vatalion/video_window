# Runbook: Log Analysis Procedures

## Overview

This runbook provides procedures for analyzing logs to investigate issues, debug problems, and understand system behavior.

## Log Structure

All logs follow JSON structure with these fields:

```json
{
  "timestamp": "2025-11-08T10:30:45.123Z",
  "level": "INFO|DEBUG|WARNING|ERROR|CRITICAL",
  "service": "video_window",
  "logger": "AuthEndpoint",
  "message": "User logged in successfully",
  "correlation_id": "550e8400-e29b-41d4-a716-446655440000",
  "context": {...},
  "error": "...",
  "stack_trace": "..."
}
```

## CloudWatch Logs Insights Queries

### Find Errors by Time Range

```
fields @timestamp, level, message, error
| filter level = "ERROR" or level = "CRITICAL"
| sort @timestamp desc
| limit 100
```

### Track Request by Correlation ID

```
fields @timestamp, logger, message, context
| filter correlation_id = "YOUR-CORRELATION-ID"
| sort @timestamp asc
```

### Identify Most Common Errors

```
fields message, error
| filter level = "ERROR"
| stats count() as error_count by error
| sort error_count desc
| limit 20
```

### Monitor Specific Endpoint Performance

```
fields @timestamp, message, context.duration_ms
| filter logger = "YourEndpoint"
| stats avg(context.duration_ms) as avg_duration, max(context.duration_ms) as max_duration, count() as request_count
| sort avg_duration desc
```

### Find Authentication Failures

```
fields @timestamp, message, context.user_id, context.reason
| filter logger = "AuthEndpoint" and level = "WARNING"
| sort @timestamp desc
| limit 50
```

### Detect Slow Queries

```
fields @timestamp, message, context.query_time_ms, context.query_type
| filter context.query_time_ms > 500
| sort context.query_time_ms desc
| limit 100
```

## Local Log Analysis

### Using grep and jq

```bash
# Get all ERROR logs from last hour
docker logs video_window_server --since 1h 2>&1 | grep '"level":"ERROR"'

# Parse JSON and extract specific fields
docker logs video_window_server --since 1h 2>&1 | \
  grep '"level":"ERROR"' | \
  jq -r '[.timestamp, .logger, .message] | @tsv'

# Count errors by logger
docker logs video_window_server --since 1h 2>&1 | \
  grep '"level":"ERROR"' | \
  jq -r '.logger' | \
  sort | uniq -c | sort -rn
```

### Follow Live Logs

```bash
# Tail all logs
docker logs -f video_window_server

# Filter for specific logger
docker logs -f video_window_server 2>&1 | jq -r 'select(.logger == "AuthEndpoint")'

# Filter for errors only
docker logs -f video_window_server 2>&1 | jq -r 'select(.level == "ERROR" or .level == "CRITICAL")'
```

## Analysis Workflows

### Investigating User-Reported Issue

1. **Get correlation ID from user report or frontend logs**
2. **Search CloudWatch for that correlation ID:**
   ```
   fields @timestamp, logger, level, message
   | filter correlation_id = "CORRELATION-ID"
   | sort @timestamp asc
   ```
3. **Review the sequence of log entries**
4. **Identify where the error occurred**
5. **Check related components using same timestamp range**

### Performance Investigation

1. **Identify slow period in Grafana**
2. **Query logs for that time range:**
   ```
   fields @timestamp, logger, context.duration_ms
   | filter @timestamp >= "2025-11-08T10:00:00" and @timestamp <= "2025-11-08T11:00:00"
   | filter context.duration_ms > 1000
   | sort context.duration_ms desc
   ```
3. **Group by endpoint to find bottlenecks:**
   ```
   fields logger
   | filter context.duration_ms > 1000
   | stats avg(context.duration_ms) as avg_time by logger
   | sort avg_time desc
   ```
4. **Review database query logs for same period**

### Security Audit

1. **Find all failed authentication attempts:**
   ```
   fields @timestamp, context.ip_address, context.user_email, message
   | filter logger = "AuthEndpoint" and message =~ /failed|denied/
   | sort @timestamp desc
   ```

2. **Detect suspicious patterns:**
   ```
   fields context.ip_address
   | filter level = "WARNING" or level = "ERROR"
   | stats count() as attempt_count by context.ip_address
   | filter attempt_count > 10
   | sort attempt_count desc
   ```

3. **Review critical actions:**
   ```
   fields @timestamp, logger, message, context.user_id
   | filter level = "CRITICAL"
   | sort @timestamp desc
   ```

## PII Sanitization Verification

Logs should **NEVER** contain:

- Credit card numbers (PAN)
- Full email addresses (redacted in production)
- Passwords or API keys
- Tokens or session IDs (except hashed)

### Verify Sanitization

```bash
# Check for potential PII leaks (should return no results)
docker logs video_window_server 2>&1 | \
  grep -E '\b\d{13,19}\b|password|api.?key|bearer'

# If anything is found, investigate immediately
```

## Log Retention

- **Debug logs:** 30 days
- **Info logs:** 60 days
- **Warning logs:** 90 days
- **Error/Critical logs:** 90 days

## Export Logs for Analysis

```bash
# Export logs to file for offline analysis
aws logs filter-log-events \
  --log-group-name /video-window/api \
  --start-time $(date -u -d '1 day ago' +%s)000 \
  --output json > logs-export.json

# Convert to CSV for spreadsheet analysis
cat logs-export.json | \
  jq -r '.events[] | [.timestamp, .message.level, .message.logger, .message.message] | @csv' \
  > logs-export.csv
```

## Troubleshooting

### No Logs Appearing

1. Check if service is running: `docker ps`
2. Verify log group exists in CloudWatch
3. Check IAM permissions for CloudWatch Logs
4. Review logger configuration in code

### Incomplete Context Data

- Ensure context is passed to logger methods
- Verify correlation ID is set in request middleware
- Check if context is being sanitized

### High Log Volume

- Review log levels (set to INFO in production, not DEBUG)
- Implement sampling for high-frequency logs
- Use structured logging to reduce verbosity

## Related Runbooks

- [High Error Rates](high-error-rates.md)
- [Performance Degradation](performance-degradation.md)
- [Metric Interpretation](metric-interpretation.md)
