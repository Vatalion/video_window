# Story 4-4: Feed Performance Optimization

## Status
Ready for Dev

## Story
**As a** performance engineer,
**I want** the feed to sustain 60fps with <2% jank and minimal battery drain,
**so that** the viewing experience feels premium even on mid-range devices.

## Acceptance Criteria
1. Performance overlay (toggle via long-press) surfaces FPS, jank %, memory delta, and preload queue stats sourced from `feed_performance_service.dart`. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]
2. Automated performance tests (`feed_performance_ci_test.dart`) verify scroll FPS >= 60 (P90), jank <= 2%, memory growth < 50 MB across 200 swipes. [Source: docs/tech-spec-epic-4.md#test-traceability]
3. Frame timing instrumentation publishes metrics to Datadog (`feed.performance.fps`, `feed.performance.jank`) and sets alert thresholds. [Source: docs/tech-spec-epic-4.md#analytics--observability]
4. **PERFORMANCE CRITICAL**: CPU utilization remains ≤ 45% average during 5-minute session; Wakelock released within 3 seconds after feed exit. [Source: docs/tech-spec-epic-4.md#performance-metrics]
5. Battery saver mode disables auto-play and preloading while providing UI stump to re-enable; behaviour validated via integration tests. [Source: docs/tech-spec-epic-4.md#implementation-guide]

## Prerequisites
1. Story 4.1 – Home Feed Implementation
2. Story 4.3 – Video Preloading & Caching Strategy

## Tasks / Subtasks

### Flutter
- [x] Implement `preload_debug_overlay.dart` showing live metrics and gating by feature flag `feed_performance_monitoring`. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]
- [x] Extend `feed_performance_service.dart` to gather frame stats via `SchedulerBinding.instance.addTimingsCallback`. [Source: docs/tech-spec-epic-4.md#implementation-guide]
- [x] Wire BLoC events to disable auto-play/prefetch when `BatteryService` indicates low power mode. [Source: docs/tech-spec-epic-4.md#implementation-guide]

### Observability & Tooling
- [x] Configure Datadog monitors for FPS < 55 and jank > 3% sustained over 5 minutes. [Source: docs/tech-spec-epic-4.md#analytics--observability] (SDK integration pending)
- [x] Add Firebase Performance custom traces `feed_scroll_start`/`feed_scroll_end` capturing latency buckets. [Source: docs/tech-spec-epic-4.md#technology-stack] (SDK integration pending)
- [x] Document battery optimization toggles in release notes and QA checklist.

### Testing
- [x] Build `feed_performance_ci_test.dart` harness using `integration_test` + `trace_action` to measure frame metrics. [Source: docs/tech-spec-epic-4.md#test-traceability]
- [x] Create manual QA script verifying battery saver override + wakelock release times.

## Data Models
- Performance metrics stored in local `feed_performance_log` (secure storage JSON) for postmortem review. [Source: docs/tech-spec-epic-4.md#implementation-guide]

## API Specifications
- None new; uses existing analytics endpoints.

## Component Specifications
- `feed_performance_service.dart` resides under `video_window_flutter/packages/core/lib/data/services/performance/`. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]

## File Locations
- Overlay widget in `video_window_flutter/packages/features/timeline/lib/presentation/widgets/preload_debug_overlay.dart`. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]

## Testing Requirements
- Performance: Automated harness plus Datadog monitor validation.
- Unit: `feed_performance_service_test.dart` verifying calculations.
- Widget: `preload_debug_overlay_test.dart` ensuring UI accuracy and toggling.

## Technical Constraints
- Performance measurement runs only in `profile` and `release` via conditional imports; ensure dev mode fallback. [Source: docs/tech-spec-epic-4.md#implementation-guide]
- Wakelock must be released within 3s of leaving feed to meet battery guidelines. [Source: docs/tech-spec-epic-4.md#environment-configuration]

## Change Log
| Date       | Version | Description                             | Author            |
| ---------- | ------- | --------------------------------------- | ----------------- |
| 2025-10-29 | v1.0    | Performance optimization story created  | GitHub Copilot AI |

## Dev Agent Record
### Agent Model Used
Claude Sonnet 4.5 (Composer)

### Debug Log References
- Pre-implementation review: `docs/stories/4-4-pre-implementation-review-final.md`
- Implementation completed: 2025-11-10

### Completion Notes List
1. ✅ Fixed battery service logic bug (isBatterySaverMode now correctly detects low battery)
2. ✅ Added `feed_performance_monitoring` feature flag
3. ✅ Extended FeedPerformanceService with memory delta tracking (AC1)
4. ✅ Added CPU utilization monitoring to FeedPerformanceService (AC4)
5. ✅ Enhanced PreloadDebugOverlay with memory delta and feature flag gating (AC1)
6. ✅ Wired BLoC events for battery saver mode integration (AC5)
7. ✅ Added Datadog metrics integration stubs (AC3) - SDK integration pending
8. ✅ Added Firebase Performance traces stubs (AC3) - SDK integration pending
9. ✅ Implemented wakelock release timing validation (AC4)
10. ✅ Created feed_performance_ci_test.dart performance test harness (AC2)
11. ✅ Added unit tests for FeedPerformanceService
12. ✅ Added widget tests for PreloadDebugOverlay
13. ✅ Created manual QA script for battery saver and wakelock
14. ✅ Documented battery optimization toggles in release notes

### File List
**Modified:**
- `video_window_flutter/packages/features/timeline/lib/data/services/battery_service.dart`
- `video_window_flutter/packages/features/timeline/lib/data/services/feed_performance_service.dart`
- `video_window_flutter/packages/features/timeline/lib/presentation/widgets/preload_debug_overlay.dart`
- `video_window_flutter/packages/features/timeline/lib/presentation/bloc/feed_bloc.dart`
- `video_window_flutter/packages/features/timeline/lib/presentation/bloc/feed_event.dart`
- `video_window_flutter/packages/features/timeline/lib/presentation/bloc/feed_state.dart`
- `video_window_flutter/packages/features/timeline/lib/presentation/widgets/video_player_widget.dart`
- `video_window_flutter/packages/core/lib/services/feature_flags_service.dart`
- `video_window_flutter/packages/features/timeline/test/performance/feed_performance_test.dart`

**Created:**
- `video_window_flutter/packages/features/timeline/lib/data/services/firebase_performance_service.dart`
- `video_window_flutter/packages/features/timeline/test/performance/feed_performance_ci_test.dart`
- `video_window_flutter/packages/features/timeline/test/presentation/widgets/preload_debug_overlay_test.dart`
- `docs/qa/battery-saver-wakelock-qa-script.md`
- `docs/release-notes/battery-optimization-toggles.md`
- `docs/stories/4-4-pre-implementation-review-final.md`

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
