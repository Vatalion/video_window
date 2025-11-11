# Story 4-5: External Integration Requirements

**Story:** 4-5 Content Recommendation Engine Integration  
**Date:** 2025-11-10  
**Status:** Implementation Complete - External Integrations Pending

## Overview

This document outlines the external integration requirements that need to be completed before production deployment. The core implementation is complete with proper structure, error handling, and fallback logic. However, several external dependencies require integration.

## Required Integrations

### 1. gRPC Client for LightFM Service (AC #1)

**Status:** ⚠️ **PLACEHOLDER** - Structure ready, proto files needed

**Current State:**
- gRPC client structure implemented in `recommendation_bridge_service.dart`
- Deadline (150ms) and retry logic (max 2) configured
- Circuit breaker pattern implemented
- Placeholder implementation returns mock data

**Required Actions:**
1. Obtain proto files from LightFM microservice (API v2025.9)
2. Generate Dart gRPC client stubs using `protoc`:
   ```bash
   protoc --dart_out=grpc:lib/src/generated \
     --plugin=protoc-gen-dart=~/.pub-cache/bin/protoc-gen-dart \
     lightfm_recommendation.proto
   ```
3. Replace placeholder gRPC call (lines 114-125) with actual client invocation
4. Configure gRPC endpoint via environment variable: `LIGHTFM_GRPC_ENDPOINT`

**Files to Modify:**
- `video_window_server/lib/src/services/recommendation_bridge_service.dart:114-125`

**Dependencies:**
- LightFM microservice must expose gRPC endpoint
- Proto files must match API version v2025.9
- Service account credentials: `feed-rec-svc@video-window`

**Testing:**
- Unit tests scaffolded in `recommendation_bridge_service_test.dart`
- Integration tests require actual gRPC service or mock server

---

### 2. Kafka Producer Integration (AC #3)

**Status:** ⚠️ **PLACEHOLDER** - Structure ready, plugin needed

**Current State:**
- Interaction endpoint implemented with correct schema
- Kafka message structure matches AC requirements
- Placeholder logging in place

**Required Actions:**
1. Add `serverpod_kafka` plugin 1.3.0 to `pubspec.yaml`:
   ```yaml
   dependencies:
     serverpod_kafka: 1.3.0
   ```
2. Configure Kafka broker endpoints in Serverpod config:
   ```yaml
   # config/production.yaml
   kafka:
     brokers: ['broker1:9092', 'broker2:9092']
     topic: 'feed.interactions.v1'
   ```
3. Initialize Kafka producer in server startup
4. Replace placeholder (lines 36-41) with actual producer.send():
   ```dart
   await kafkaProducer.send(
     topic: 'feed.interactions.v1',
     key: userId,
     value: jsonEncode(kafkaMessage),
   );
   ```

**Files to Modify:**
- `video_window_server/pubspec.yaml` - Add dependency
- `video_window_server/lib/src/endpoints/feed/interaction_endpoint.dart:36-41`
- `video_window_server/lib/server.dart` - Initialize producer

**Dependencies:**
- Kafka topic `feed.interactions.v1` provisioned (see `docs/infrastructure/kafka-feed-interactions-setup.md`)
- IAM role `feed-rec-producer` configured with write permissions
- AWS MSK cluster or self-hosted Kafka cluster

**Testing:**
- Integration tests require Kafka test container or mock producer
- Verify message schema matches AC requirements

---

### 3. Datadog SDK Integration (AC #2, AC #5)

**Status:** ⚠️ **PLACEHOLDER** - Logging structure ready

**Current State:**
- Logging placeholders in place for all Datadog events
- Event names match requirements:
  - `feed.recommendation.fallback` (AC #2)
  - `feed.lightfm.retrain.success` (AC #5)
  - `feed.lightfm.retrain.failure` (AC #5)

**Required Actions:**
1. Add Datadog SDK to `pubspec.yaml`:
   ```yaml
   dependencies:
     datadog_common_flutter: ^2.0.0  # Or appropriate Dart/Serverpod SDK
   ```
2. Initialize Datadog client in server startup
3. Replace logging placeholders with actual metric emissions:
   - `recommendation_bridge_service.dart:183-187` - Fallback event
   - `feed_lightfm_retrain.dart:46-50` - Retrain success/failure metrics
   - `recommendation_bridge_service.dart:217-222` - Latency histogram

**Files to Modify:**
- `video_window_server/pubspec.yaml` - Add dependency
- `video_window_server/lib/src/services/recommendation_bridge_service.dart:183-187, 217-222`
- `video_window_server/lib/src/tasks/feed_lightfm_retrain.dart:46-50, 58-63`

**Dependencies:**
- Datadog API key configured via environment variable
- Datadog agent or direct API access configured

**Metrics to Emit:**
- `feed.recommendation.fallback` (count) - When fallback occurs
- `feed.recommendation.latency` (histogram) - gRPC call duration
- `feed.lightfm.retrain.success` (count) - Retraining success
- `feed.lightfm.retrain.failure` (count) - Retraining failure

---

### 4. Snowflake Logging (AC #5)

**Status:** ⚠️ **PLACEHOLDER** - Structure ready

**Current State:**
- Retraining job structure in place
- Logging placeholder for Snowflake

**Required Actions:**
1. Add Snowflake connector library:
   ```yaml
   dependencies:
     snowflake_connector: ^1.0.0  # Or appropriate Dart library
   ```
2. Configure Snowflake connection:
   ```yaml
   # config/production.yaml
   snowflake:
     account: 'your-account'
     warehouse: 'COMPUTE_WH'
     database: 'VIDEO_WINDOW'
     schema: 'FEED'
     user: 'feed_service'
     password: '${SNOWFLAKE_PASSWORD}'  # From secrets manager
   ```
3. Implement Snowflake logging in retraining job:
   ```dart
   await snowflakeClient.execute(
     'INSERT INTO feed.lightfm_retrain_log (job_name, status, timestamp, interactions_processed) VALUES (?, ?, ?, ?)',
     ['feed_lightfm_retrain', 'completed', DateTime.now().toUtc(), interactions.length],
   );
   ```

**Files to Modify:**
- `video_window_server/lib/src/tasks/feed_lightfm_retrain.dart:31-37`

**Dependencies:**
- Snowflake data warehouse configured
- Table schema: `feed.lightfm_retrain_log`
- Service account with INSERT permissions

**Schema:**
```sql
CREATE TABLE feed.lightfm_retrain_log (
  job_name VARCHAR(100),
  status VARCHAR(50),
  timestamp TIMESTAMP_NTZ,
  interactions_processed INTEGER,
  error_message VARCHAR(500)
);
```

---

### 5. S3 Parquet Export Retrieval (AC #5)

**Status:** ⚠️ **PLACEHOLDER** - Structure ready

**Current State:**
- Retraining job structure in place
- Placeholder for S3 export loading

**Required Actions:**
1. Use existing AWS S3 SDK (already in dependencies)
2. Implement S3 parquet file retrieval:
   ```dart
   final s3Client = S3Client(region: 'us-east-1');
   final objects = await s3Client.listObjects(
     bucket: 'video-window-interactions',
     prefix: 'exports/${DateTime.now().toUtc().toIso8601String().split('T')[0]}/',
   );
   
   // Download and parse parquet files
   final interactions = await _parseParquetFiles(objects);
   ```
3. Parse parquet files using parquet library:
   ```yaml
   dependencies:
     parquet: ^2.0.0  # Or appropriate Dart library
   ```

**Files to Modify:**
- `video_window_server/lib/src/tasks/feed_lightfm_retrain.dart:17-24`

**Dependencies:**
- S3 bucket: `video-window-interactions`
- Parquet export job running (separate process)
- IAM permissions for S3 read access

---

## Integration Checklist

### Pre-Production Checklist

- [ ] gRPC proto files obtained and client generated
- [ ] gRPC endpoint configured and tested
- [ ] Kafka plugin integrated and producer initialized
- [ ] Kafka topic provisioned and accessible
- [ ] Datadog SDK integrated and metrics emitting
- [ ] Datadog dashboard created for monitoring
- [ ] Snowflake connection configured
- [ ] Snowflake table schema created
- [ ] S3 parquet export process running
- [ ] S3 access permissions configured
- [ ] All integration tests passing
- [ ] End-to-end test with all services

### Production Readiness

- [ ] All external services have monitoring/alerts
- [ ] Fallback mechanisms tested under failure scenarios
- [ ] Performance benchmarks met (150ms deadline, <50ms Kafka latency)
- [ ] Security review completed (IAM roles, secrets management)
- [ ] Documentation updated with production endpoints
- [ ] Runbook created for troubleshooting external integrations

---

## Testing Strategy

### Unit Tests
- ✅ Test structure implemented
- ⚠️ Requires mocks for external services

### Integration Tests
- ✅ Test structure implemented
- ⚠️ Requires test containers or mock services:
  - gRPC mock server
  - Kafka test container
  - Datadog test client
  - Snowflake test database

### End-to-End Tests
- ⚠️ Requires staging environment with all services configured

---

## Rollout Plan

1. **Phase 1:** Complete gRPC integration (highest priority - blocks AC #1)
2. **Phase 2:** Complete Kafka integration (blocks AC #3)
3. **Phase 3:** Complete Datadog integration (monitoring - non-blocking)
4. **Phase 4:** Complete Snowflake/S3 integration (analytics - non-blocking)

---

## Support Contacts

- **LightFM Service:** [Contact LightFM team]
- **Kafka Infrastructure:** [Contact DevOps]
- **Datadog:** [Contact Observability team]
- **Snowflake:** [Contact Data Engineering]

---

## Related Documentation

- `docs/infrastructure/kafka-feed-interactions-setup.md` - Kafka setup
- `docs/tech-spec-epic-4.md` - Technical specification
- `docs/stories/4-5-content-recommendation-engine-integration.md` - Story details

