# Story 4-5: Content Recommendation Engine Integration

## Status
Ready for Dev

## Story
**As a** personalization engineer,
**I want** to plug the feed into the LightFM recommendation service,
**so that** viewers receive relevant videos that keep them engaged.

## Acceptance Criteria
1. Serverpod `recommendation_bridge_service.dart` proxies requests to LightFM API v2025.9 with gRPC deadline 150 ms and retries capped at 2. [Source: docs/tech-spec-epic-4.md#implementation-guide]
2. Recommendation fallback logic switches to trending feed when LightFM errors or exceeds deadline, logging Datadog event `feed.recommendation.fallback`. [Source: docs/tech-spec-epic-4.md#implementation-guide]
3. Interaction endpoint streams events to Kafka topic `feed.interactions.v1` with schema `{userId, videoId, interactionType, watchTime, timestamp}`. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]
4. **DATA QUALITY CRITICAL**: Segment analytics emits `feed_recommendation_served` event containing algorithm, feed session, and experiment variant IDs. [Source: docs/tech-spec-epic-4.md#analytics--observability]
5. Nightly retraining job triggers via Serverpod task, pulling parquet exports of interactions and logging completion status to Snowflake. [Source: docs/tech-spec-epic-4.md#recommendation-engine]

## Prerequisites
1. Story 4.2 – Infinite Scroll & Pagination
2. Story 4.3 – Video Preloading & Caching Strategy

## Tasks / Subtasks

### Serverpod
- [ ] Implement `recommendation_bridge_service.dart` with gRPC client, circuit breaker, and metrics. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]
- [ ] Update `feed_service.dart` to request recommendations with personalization filters, fallback to trending when necessary. [Source: docs/tech-spec-epic-4.md#implementation-guide]
- [ ] Modify `interaction_endpoint.dart` to enqueue Kafka messages and persist to `user_interactions`. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]

### Infrastructure
- [ ] Provision Kafka topic `feed.interactions.v1` and IAM role `feed-rec-producer`. [Source: docs/tech-spec-epic-4.md#recommendation-engine]
- [ ] Schedule Serverpod cron job `feed_lightfm_retrain` nightly at 02:00 UTC, publishing metrics to Datadog. [Source: docs/tech-spec-epic-4.md#recommendation-engine]

### Client & Analytics
- [ ] Add analytics instrumentation for recommendation served/consumed events with experiment IDs. [Source: docs/tech-spec-epic-4.md#analytics--observability]
- [ ] Update `record_interaction_use_case.dart` to include session + recommendation metadata in payload. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]

## Data Models
- `feed_cache` stores recommendation algorithm used per page for debugging. [Source: docs/tech-spec-epic-4.md#data-models]
- `user_interactions` table includes `recommendation_score` column to support model training. [Source: docs/tech-spec-epic-4.md#data-models]

## API Specifications
- `GET /feed/recommendations` returns LightFM-ordered IDs with scores; `POST /feed/interactions` records engagement. [Source: docs/tech-spec-epic-4.md#feed-endpoints]

## Component Specifications
- Kafka producer resides within `interaction_endpoint.dart` using `serverpod_kafka` plugin pinned to 1.3.0. [Source: docs/tech-spec-epic-4.md#technology-stack]

## File Locations
- Server files under `video_window_server/lib/src/services/recommendation_bridge_service.dart` and `.../endpoints/feed/interaction_endpoint.dart`. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]
- Client instrumentation in `video_window_flutter/packages/core/lib/data/repositories/feed/feed_repository.dart`. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]

## Testing Requirements
- Unit: `recommendation_bridge_service_test.dart` covering gRPC retries and circuit breaker.
- Integration: `feed_recommendation_integration_test.dart` verifying fallback + metadata propagation.
- Data quality: Backfill test ensuring interactions persisted correctly and exported for model training.

## Technical Constraints
- LightFM API contract version locked at v2025.9; breaking changes require coordinate release. [Source: docs/tech-spec-epic-4.md#recommendation-engine]
- Kafka publish latency must stay < 50 ms P95; configure batching accordingly. [Source: docs/tech-spec-epic-4.md#performance-metrics]

## Change Log
| Date       | Version | Description                                   | Author            |
| ---------- | ------- | --------------------------------------------- | ----------------- |
| 2025-10-29 | v1.0    | Recommendation integration story created      | GitHub Copilot AI |

## Dev Agent Record
### Agent Model Used
_(To be completed by Dev Agent)_

### Debug Log References
_(To be completed by Dev Agent)_

### Completion Notes List
_(To be completed by Dev Agent)_

### File List
_(To be completed by Dev Agent)_

## QA Results
_(To be completed by QA Agent)_

## Dev Notes

### Implementation Guidance
- Follow architecture patterns defined in tech spec
- Reference epic context for integration points
- Ensure test coverage meets acceptance criteria requirements

### Key Considerations
- Review security requirements if authentication/authorization involved
- Check performance requirements and optimize accordingly
- Validate against Definition of Ready before starting implementation
