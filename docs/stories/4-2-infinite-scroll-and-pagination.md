# Story 4-2: Infinite Scroll & Pagination

## Status
Ready for Dev

## Story
**As a** returning viewer,
**I want** the feed to seamlessly load more videos as I swipe,
**so that** I never hit a dead end while browsing content.

## Acceptance Criteria
1. Cursor-based pagination retrieves 20-item pages by default and gracefully handles backfill when returning to previous videos. [Source: docs/tech-spec-epic-4.md#implementation-guide]
2. Serverpod feed endpoint enforces max page size 50 and returns `feedSessionId`, `nextCursor`, and `hasMore` fields that the client persists and reuses. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]
3. Infinite scroll footer displays loading, error, and end-of-feed states with retry capability and analytics event `feed_pagination_retry`. [Source: docs/tech-spec-epic-4.md#analytics--observability]
4. **PERFORMANCE CRITICAL**: Pagination must resolve within 350 ms P95 when data cached, 650 ms P95 when cache miss, measured via Datadog RUM spans. [Source: docs/tech-spec-epic-4.md#performance-metrics]
5. Feed state persists across app restarts (last cursor replay) and handles offline fallback by replaying cached videos when network unavailable. [Source: docs/tech-spec-epic-4.md#implementation-guide]

## Prerequisites
1. Story 4.1 – Home Feed Implementation (base feed shell)
2. Epic 2 – Maker content publishing to populate the feed

## Tasks / Subtasks

### Flutter
- [ ] Extend `fetch_feed_page_use_case.dart` to send cursor + personalization params, persisting last cursor in secure storage. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]
- [ ] Implement `infinite_scroll_footer.dart` widget with loading/error/end visuals and retry callback. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]
- [ ] Update `feed_page.dart` BLoC wiring to trigger pagination when 80% scroll threshold reached and to replay cached pages offline. [Source: docs/tech-spec-epic-4.md#implementation-guide]

### Serverpod
- [ ] Update `feed_endpoint.dart` to emit cursor tokens, enforce page limit <=50, and include `feedSessionId`. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]
- [ ] Add Redis-backed page cache (`feed:page:{userId}:{cursor}`) with 120-second TTL leveraging `feed_cache_manager.dart`. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]
- [ ] Emit Datadog trace spans capturing pagination latency and cache source (hit/miss). [Source: docs/tech-spec-epic-4.md#analytics--observability]

### Testing & Analytics
- [ ] Create `feed_pagination_integration_test.dart` covering cursor flow, offline replay, and error retries. [Source: docs/tech-spec-epic-4.md#test-traceability]
- [ ] Fire analytics event `feed_page_loaded` with cursor metadata and latency buckets. [Source: docs/tech-spec-epic-4.md#analytics--observability]

## Data Models
- `feed_cache` table stores cached page payloads keyed by cursor; ensure migration present. [Source: docs/tech-spec-epic-4.md#data-models]

## API Specifications
- `GET /feed/videos` and `/feed/videos/next-page` utilize cursor tokens; ensure OpenAPI spec updated accordingly. [Source: docs/tech-spec-epic-4.md#feed-endpoints]

## Component Specifications
- Pagination triggers handled in `VideoFeedBloc` with debounced `LoadNextPage` event and fail-safe to prevent duplicate requests. [Source: docs/tech-spec-epic-4.md#flutter-feed-module-structure]

## File Locations
- Client logic in `video_window_flutter/packages/features/timeline/lib/presentation/pages/feed_page.dart` and `.../widgets/infinite_scroll_footer.dart`. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]
- Server logic in `video_window_server/lib/src/endpoints/feed/feed_endpoint.dart`. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]

## Testing Requirements
- Unit: `fetch_feed_page_use_case_test.dart` covering cursor persistence and offline fallbacks.
- Integration: `feed_pagination_integration_test.dart` hitting mocked Serverpod endpoint.
- Performance: Datadog synthetic test verifying latency thresholds.

## Technical Constraints
- Prefetch threshold fixed at 0.8 scroll progress; adjustments follow change control. [Source: docs/tech-spec-epic-4.md#implementation-guide]
- Cursor tokens expire after 10 minutes; client must gracefully request a new feed session. [Source: docs/tech-spec-epic-4.md#implementation-guide]

## Change Log
| Date       | Version | Description                         | Author            |
| ---------- | ------- | ----------------------------------- | ----------------- |
| 2025-10-29 | v1.0    | Infinite scroll story authored      | GitHub Copilot AI |

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
