# Grafana Capability Monitoring Panels

**Epic:** 2 - Capability Enablement & Verification  
**Story:** 2-1 - Capability Enablement Request Flow  
**Task 13:** Add Grafana panel for request volume, approval rate, and blocker distribution

## Overview

This document defines the Grafana dashboard panels for monitoring the capability system performance and user funnel metrics.

## Dashboard: Capability Operations

### Panel 1: Capability Request Volume

**Type:** Time series graph  
**Query:** 
```sql
SELECT 
  time_bucket('1 hour', created_at) AS time,
  capability,
  COUNT(*) as request_count
FROM capability_requests
WHERE created_at >= NOW() - INTERVAL '7 days'
GROUP BY time, capability
ORDER BY time ASC
```

**Visualization:**
- Line chart with 3 series (publish, collect_payments, fulfill_orders)
- Y-axis: Request count
- X-axis: Time (hourly buckets)
- Legend: Capability type

**Thresholds:**
- Green: < 100 requests/hour
- Yellow: 100-500 requests/hour
- Red: > 500 requests/hour (potential bot activity)

---

### Panel 2: Approval Rate

**Type:** Stat panel with sparkline  
**Query:**
```sql
SELECT 
  capability,
  COUNT(CASE WHEN status = 'approved' THEN 1 END)::FLOAT / COUNT(*)::FLOAT * 100 as approval_rate
FROM capability_requests
WHERE created_at >= NOW() - INTERVAL '24 hours'
GROUP BY capability
```

**Visualization:**
- 3 stat cards (one per capability)
- Value: Percentage (%)
- Sparkline: 24-hour trend
- Color mapping:
  - Green: > 70%
  - Yellow: 50-70%
  - Red: < 50%

---

### Panel 3: Blocker Distribution

**Type:** Pie chart  
**Query:**
```sql
SELECT 
  jsonb_object_keys(blockers) as blocker_type,
  COUNT(*) as occurrence_count
FROM user_capabilities
WHERE blockers != '{}'::jsonb
GROUP BY blocker_type
ORDER BY occurrence_count DESC
```

**Visualization:**
- Pie chart showing top blockers preventing capability enablement
- Labels: Blocker type (e.g., "identity_verification_required", "payout_not_configured")
- Values: Count of users affected

---

### Panel 4: Time to Approval

**Type:** Histogram  
**Query:**
```sql
SELECT 
  capability,
  EXTRACT(EPOCH FROM (resolved_at - created_at)) / 3600 as hours_to_approval
FROM capability_requests
WHERE status = 'approved' 
  AND resolved_at IS NOT NULL
  AND created_at >= NOW() - INTERVAL '7 days'
```

**Visualization:**
- Histogram with 3 series (one per capability)
- X-axis: Hours to approval (buckets: 0-1, 1-6, 6-24, 24+)
- Y-axis: Count of requests
- Target SLA: < 24 hours for auto-approval paths

---

### Panel 5: Review State Distribution

**Type:** Bar gauge  
**Query:**
```sql
SELECT 
  review_state,
  COUNT(*) as user_count
FROM user_capabilities
GROUP BY review_state
```

**Visualization:**
- Horizontal bar gauge
- States: none, pending, manual_review
- Color coding:
  - Green: none (no issues)
  - Yellow: pending (awaiting auto-processing)
  - Red: manual_review (requires human intervention)

---

### Panel 6: Capability Funnel

**Type:** Funnel visualization  
**Metrics:**
1. Total users (baseline)
2. Users with >= 1 capability request
3. Users with >= 1 capability approved
4. Users with all 3 capabilities approved

**Query:**
```sql
SELECT 
  'Total Users' as stage, COUNT(DISTINCT id) as count FROM users
UNION ALL
SELECT 
  'Requested Capability', COUNT(DISTINCT user_id) FROM capability_requests
UNION ALL
SELECT 
  'Has Capability', COUNT(DISTINCT user_id) 
FROM user_capabilities 
WHERE can_publish OR can_collect_payments OR can_fulfill_orders
UNION ALL
SELECT 
  'Full Access', COUNT(DISTINCT user_id)
FROM user_capabilities
WHERE can_publish AND can_collect_payments AND can_fulfill_orders
```

**Conversion Targets:**
- Request rate: > 20% of total users
- Approval rate: > 80% of requesters
- Full access rate: > 10% of total users

---

## Alerts

### Critical Alerts

**Alert 1: High Rejection Rate**
- Condition: Approval rate < 50% for > 1 hour
- Severity: P2
- Action: Review manual review queue, check for systemic blocker

**Alert 2: Capability System Down**
- Condition: Zero requests in last 30 minutes during business hours
- Severity: P1
- Action: Check API availability, database connectivity

**Alert 3: Review Queue Buildup**
- Condition: > 100 requests in manual_review state
- Severity: P3
- Action: Scale review team, investigate common blockers

### Warning Alerts

**Alert 4: Elevated Request Volume**
- Condition: > 500 requests/hour sustained for 1 hour
- Severity: P3
- Action: Monitor for bot activity, check rate limiting

**Alert 5: Slow Approval Time**
- Condition: Median time to approval > 48 hours
- Severity: P3
- Action: Review auto-approval logic, check external service latency (Persona, Stripe)

---

## Implementation Notes

1. **Data Source:** PostgreSQL connection to video_window production database
2. **Refresh Rate:** 30 seconds for real-time panels, 5 minutes for historical panels
3. **Retention:** 90 days for detailed logs, 1 year for aggregated metrics
4. **Access Control:** Restrict to Ops team, Product team, and relevant stakeholders
5. **Dashboard Link:** [TBD - deploy to Grafana instance]

---

## Testing Dashboard Locally

For local development, use the test database:

```bash
# Start Grafana with docker-compose
docker-compose -f docker-compose.monitoring.yml up -d

# Access dashboard
open http://localhost:3000/d/capability-ops

# Default credentials
# Username: admin
# Password: admin
```

---

**Last Updated:** 2025-11-11  
**Owner:** DevOps Team  
**Reviewers:** Product, Engineering

