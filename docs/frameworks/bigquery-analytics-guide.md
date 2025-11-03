# BigQuery Analytics Guide - Video Window

**Version:** BigQuery Latest  
**Last Updated:** 2025-11-03  
**Status:** ⏳ Planned - Post-MVP (Epic 17)

---

## Overview

BigQuery will provide Video Window's analytics data warehouse for business intelligence and KPI tracking. **NOT USED IN SPRINT 1**.

---

## Planned Schema

### Events Table

```sql
CREATE TABLE `video_window.events` (
  event_id STRING NOT NULL,
  event_type STRING NOT NULL,
  user_id STRING,
  session_id STRING,
  timestamp TIMESTAMP NOT NULL,
  properties JSON,
  device_type STRING,
  platform STRING,
  app_version STRING
)
PARTITION BY DATE(timestamp)
CLUSTER BY event_type, user_id;
```

### Stories Table

```sql
CREATE TABLE `video_window.stories` (
  story_id STRING NOT NULL,
  maker_id STRING NOT NULL,
  created_at TIMESTAMP NOT NULL,
  view_count INT64 DEFAULT 0,
  offer_count INT64 DEFAULT 0,
  sale_count INT64 DEFAULT 0,
  total_revenue FLOAT64 DEFAULT 0.0,
  avg_watch_time_seconds FLOAT64,
  completion_rate FLOAT64
)
PARTITION BY DATE(created_at)
CLUSTER BY maker_id;
```

### Transactions Table

```sql
CREATE TABLE `video_window.transactions` (
  transaction_id STRING NOT NULL,
  story_id STRING NOT NULL,
  buyer_id STRING,
  maker_id STRING NOT NULL,
  amount FLOAT64 NOT NULL,
  platform_fee FLOAT64 NOT NULL,
  maker_payout FLOAT64 NOT NULL,
  status STRING NOT NULL,
  created_at TIMESTAMP NOT NULL,
  completed_at TIMESTAMP
)
PARTITION BY DATE(created_at)
CLUSTER BY maker_id, buyer_id;
```

---

## Event Tracking (Future)

```dart
// video_window_server/lib/src/services/analytics_service.dart
class AnalyticsService {
  final BigQuery _bigquery;
  
  Future<void> trackEvent({
    required String eventType,
    required String userId,
    required Map<String, dynamic> properties,
  }) async {
    await _bigquery.tabledata.insertAll(
      BigQueryTableDataInsertAllRequest(
        rows: [
          {
            'json': {
              'event_id': Uuid().v4(),
              'event_type': eventType,
              'user_id': userId,
              'timestamp': DateTime.now().toIso8601String(),
              'properties': jsonEncode(properties),
            },
          },
        ],
      ),
      'video_window',
      'events',
      'events',
    );
  }
}

// Usage
await analytics.trackEvent(
  eventType: 'story_viewed',
  userId: currentUser.id,
  properties: {
    'story_id': story.id,
    'watch_duration': 15.5,
  },
);
```

---

## Common KPI Queries

### Daily Active Users

```sql
SELECT
  DATE(timestamp) as date,
  COUNT(DISTINCT user_id) as dau
FROM `video_window.events`
WHERE event_type = 'session_start'
  AND timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
GROUP BY date
ORDER BY date DESC;
```

### Top Performing Stories

```sql
SELECT
  story_id,
  view_count,
  sale_count,
  total_revenue,
  (sale_count / view_count) * 100 as conversion_rate
FROM `video_window.stories`
WHERE created_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
ORDER BY total_revenue DESC
LIMIT 10;
```

### Maker Revenue Summary

```sql
SELECT
  maker_id,
  COUNT(DISTINCT story_id) as stories_count,
  SUM(sale_count) as total_sales,
  SUM(total_revenue) as total_revenue,
  AVG(completion_rate) as avg_completion_rate
FROM `video_window.stories`
WHERE created_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
GROUP BY maker_id
HAVING total_revenue > 0
ORDER BY total_revenue DESC;
```

---

## Batch Export (Nightly)

```dart
// Export Serverpod data to BigQuery
Future<void> exportDailyMetrics() async {
  final yesterday = DateTime.now().subtract(Duration(days: 1));
  
  // Export stories metrics
  final stories = await Story.find(
    session,
    where: (t) => t.createdAt.between(
      yesterday.subtract(Duration(days: 1)),
      yesterday,
    ),
  );
  
  for (final story in stories) {
    await _bigquery.tabledata.insertAll(
      BigQueryTableDataInsertAllRequest(
        rows: [
          {
            'json': {
              'story_id': story.id,
              'maker_id': story.makerId,
              'created_at': story.createdAt.toIso8601String(),
              'view_count': story.viewCount,
              'offer_count': story.offerCount,
              'sale_count': story.saleCount,
              'total_revenue': story.totalRevenue,
            },
          },
        ],
      ),
      'video_window',
      'stories',
      'stories',
    );
  }
}
```

---

## Video Window Conventions

- **Project:** `video-window-production`
- **Dataset:** `video_window`
- **Partition:** Date-based (daily)
- **Clustering:** User/story IDs for query performance
- **Retention:** 1 year for events, indefinite for aggregated metrics
- **Export Schedule:** Nightly batch (2 AM UTC)

---

## Reference

- **BigQuery Docs:** https://cloud.google.com/bigquery/docs
- **SQL Reference:** https://cloud.google.com/bigquery/docs/reference/standard-sql

---

**Last Updated:** 2025-11-03 by Winston  
**Status:** Planned for Epic 17 (Post-MVP)
