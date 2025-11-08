# Runbook: High Error Rates

## Alert: HighErrorRate

**Severity:** Critical  
**Threshold:** Error rate > 5% for 2 minutes

## Symptoms

- API error rate exceeds 5%
- Multiple failed requests visible in logs
- User-facing errors or degraded service

## Investigation Steps

### 1. Check CloudWatch Logs

```bash
# Query recent errors
aws logs filter-log-events \
  --log-group-name /video-window/api \
  --filter-pattern '{ $.level = "ERROR" OR $.level = "CRITICAL" }' \
  --start-time $(date -u -d '10 minutes ago' +%s)000
```

### 2. Review Error Types in Grafana

- Open Grafana dashboard: "Video Window - Service Health"
- Check "Error Rate" panel for breakdown by error type
- Identify which endpoints are affected

### 3. Check Service Health

```bash
# Check if service is running
docker ps | grep video_window_server

# Check service logs
docker logs video_window_server --tail=100
```

### 4. Review Metrics

```bash
# Get current metrics from Prometheus
curl http://localhost:9090/api/v1/query?query=rate(api_errors_total[5m])
```

## Common Causes & Solutions

### Database Connection Issues

**Symptoms:**
- Errors related to database timeouts
- Connection pool exhaustion

**Solution:**
```bash
# Check database status
docker exec video_window_postgres pg_isready

# Check active connections
psql -h localhost -U postgres -d video_window -c \
  "SELECT count(*) FROM pg_stat_activity WHERE datname = 'video_window';"

# Restart database if necessary
docker restart video_window_postgres
```

### External Service Failures

**Symptoms:**
- Timeout errors when calling Stripe, S3, or other services
- Network connectivity issues

**Solution:**
- Check external service status pages
- Review network configuration
- Enable circuit breaker if repeated failures

### Deployment Issues

**Symptoms:**
- Errors started after recent deployment
- Configuration mismatch

**Solution:**
```bash
# Rollback to previous version
git checkout <previous-commit>
docker-compose up -d --build

# Restore from backup if needed
./scripts/restore-backup.sh
```

## Escalation

If error rate doesn't decrease after 15 minutes:

1. **Contact:** On-call engineer via PagerDuty
2. **Escalate to:** Engineering Lead
3. **Consider:** Enabling maintenance mode

## Post-Incident

1. Document root cause
2. Update monitoring thresholds if necessary
3. Create tickets for preventive measures
4. Schedule post-mortem if impact was significant

## Related Runbooks

- [Performance Degradation](performance-degradation.md)
- [Log Analysis Procedures](log-analysis.md)
