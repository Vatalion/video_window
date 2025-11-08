# Story 4-3: Video Preloading & Caching Strategy

## Status
Ready for Dev

## Story
**As a** heavy feed user,
**I want** upcoming videos to preload and stay responsive,
**so that** playback never stutters even when I swipe quickly.

## Acceptance Criteria
1. Video preloader warms the previous and next two videos using controller pooling and releases resources when out of range. [Source: docs/tech-spec-epic-4.md#implementation-guide]
2. Local cache keeps up to 100 MB of feed data (Hive box `feed_cache`) with LRU eviction and redis hydration on launch. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]
3. Background worker `feed_prefetch_worker.ts` pre-warms CloudFront cache hourly for trending feed segments, configurable via `FEED_PREFETCH_CRON_EXPRESSION`. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]
4. **PERFORMANCE CRITICAL**: Video startup latency ≤ 800 ms P95 after preload; cold loads ≤ 2 s P95. [Source: docs/tech-spec-epic-4.md#performance-metrics]
5. Cache health metrics (hit rate, eviction count, preload queue depth) are emitted to Datadog and exposed via debug overlay. [Source: docs/tech-spec-epic-4.md#analytics--observability]

## Prerequisites
1. Story 4.1 – Home Feed Implementation
2. Story 4.2 – Infinite Scroll & Pagination

## Tasks / Subtasks

### Flutter
- [ ] Implement `preload_videos_use_case.dart` controlling warm-up and teardown of queued controllers. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]
- [ ] Update `video_feed_item.dart` to request preloaded controllers and expose preload debug overlay toggled via long-press. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]
- [ ] Add `feed_performance_service.dart` to capture preload metrics and surface to overlay. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]

### Server & Infrastructure
- [ ] Create `feed_prefetch_worker.ts` (serverless) to pull trending videos from Serverpod and issue CloudFront cache warm requests. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]
- [ ] Provision Terraform `feed_cdn.tf` + `feed_redis.tf` resources and ensure IAM roles permit signed cookie generation. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]
- [ ] Implement `feed_cache_manager.dart` for Redis hydration and TTL enforcement. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]

### Observability
- [ ] Emit Datadog gauge `feed.preload.queue_depth` and counter `feed.cache.evictions`. [Source: docs/tech-spec-epic-4.md#analytics--observability]
- [ ] Add Segment event `feed_preload_complete` with latency metadata. [Source: docs/tech-spec-epic-4.md#analytics--observability]

## Data Models
- Redis structures `feed:prefetch:{videoId}` store cached manifests with TTL 10 minutes. [Source: docs/tech-spec-epic-4.md#implementation-guide]

## API Specifications
- Prefetch worker calls `GET /feed/trending` and `GET /feed/videos` with service token to fetch next pages. [Source: docs/tech-spec-epic-4.md#feed-endpoints]

## Component Specifications
- `VideoPreloader` resides in `video_window_flutter/packages/features/timeline/lib/use_cases/`. Preload queue responds to network quality signals. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]

## File Locations
- Client caching utilities live in `video_window_flutter/packages/core/lib/data/repositories/feed/feed_cache_repository.dart`. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]
- Worker code under `infrastructure/serverless/feed_prefetch_worker.ts`. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]

## Testing Requirements
- Unit: `preload_videos_use_case_test.dart`, verifying queue size, release behaviour, and metric emission.
- Integration: `preload_pipeline_integration_test.dart` simulating warm/cold loads.
- Performance: Automated test harness verifying startup latency thresholds on mid-range Android device.

## Technical Constraints
- Cache cap fixed at 100 MB; adjustments require architecture approval. [Source: docs/tech-spec-epic-4.md#environment-configuration]
- Prefetch runs when battery level > 30% and device not on low power mode. [Source: docs/tech-spec-epic-4.md#implementation-guide]

## Change Log
| Date       | Version | Description                                | Author            |
| ---------- | ------- | ------------------------------------------ | ----------------- |
| 2025-10-29 | v1.0    | Video preloading and caching story created | GitHub Copilot AI |

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
