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
- [ ] Implement `preload_debug_overlay.dart` showing live metrics and gating by feature flag `feed_performance_monitoring`. [Source: docs/tech-spec-epic-4.md#source-tree--file-directives]
- [ ] Extend `feed_performance_service.dart` to gather frame stats via `SchedulerBinding.instance.addTimingsCallback`. [Source: docs/tech-spec-epic-4.md#implementation-guide]
- [ ] Wire BLoC events to disable auto-play/prefetch when `PowerManager` indicates low power mode. [Source: docs/tech-spec-epic-4.md#implementation-guide]

### Observability & Tooling
- [ ] Configure Datadog monitors for FPS < 55 and jank > 3% sustained over 5 minutes. [Source: docs/tech-spec-epic-4.md#analytics--observability]
- [ ] Add Firebase Performance custom traces `feed_scroll_start`/`feed_scroll_end` capturing latency buckets. [Source: docs/tech-spec-epic-4.md#technology-stack]
- [ ] Document battery optimization toggles in release notes and QA checklist.

### Testing
- [ ] Build `feed_performance_ci_test.dart` harness using `integration_test` + `trace_action` to measure frame metrics. [Source: docs/tech-spec-epic-4.md#test-traceability]
- [ ] Create manual QA script verifying battery saver override + wakelock release times.

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
_(To be completed by Dev Agent)_

### Debug Log References
_(To be completed by Dev Agent)_

### Completion Notes List
_(To be completed by Dev Agent)_

### File List
_(To be completed by Dev Agent)_

## QA Results
_(To be completed by QA Agent)_
