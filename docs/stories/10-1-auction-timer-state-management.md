# Story 10-1: Auction Timer & State Management

## Status
Ready for Dev

## Story
**As a** marketplace participant (viewer, maker, or admin),
**I want** the auction timer to start, tick, and stay accurate in real time as soon as an auction launches,
**so that** I can trust auction countdowns and react to bids without timing surprises

## Acceptance Criteria
1. **TIMER CRITICAL**: Auction timers register automatically when Epic 9 emits `offers.auction.started`, storing start/end metadata in Redis with version control and recovering after restarts (Implementation Guide §1).
2. **REAL-TIME CRITICAL**: `auction_timer_task` publishes WebSocket timer ticks every ≤15 seconds, and clients display countdowns with drift warning banner when deviation >250ms (Implementation Guide §1).
3. **BUSINESS CRITICAL**: Client timer bloc reconnects, rehydrates via `GET /auctions/{id}/timer`, and reconciles differences using monotonic clock + Datadog drift metrics (Implementation Guide §1).
4. **RELIABILITY CRITICAL**: Timer persistence survives Redis failover scenarios with background reconciliation job ensuring remaining duration accuracy ≤ ±5s across 100 concurrent auctions (Implementation Guide §1 & §5).
5. **OBSERVABILITY CRITICAL**: Datadog metrics `auctions.timer.drift_ms`, `auctions.timer.tick_delay_ms`, and Segment events `auction_timer_started`/`auction_timer_resynced` emit with trace IDs (Monitoring & Analytics).

## Prerequisites
1. Story 01.1 – Bootstrap Repository and Flutter App
2. Story 9.1 – Offer Submission Flow (auction activation event stream)
3. Redis + Serverpod cron infrastructure configured per `docs/architecture/message-queue-architecture.md`
4. Observability baseline (metrics/logging) established using `docs/runbooks/auction-timer.md`

## Tasks / Subtasks

### Phase 1 – Timer Registration & Scheduler

- [ ] **TIMER CRITICAL - TIMER-INIT**: Register auction timers in Redis with versioned payload (AC: 1) [Source: docs/tech-spec-epic-10.md – Implementation Guide §1]
  - [ ] Persist `startsAt`, `endsAt`, and policy metadata on `offers.auction.started`
  - [ ] Store timer hash + sorted set entry `auction:timer:{id}` with ms precision
  - [ ] Write audit log entry `auction_timer_registered` with trace ID
  - [ ] Implement idempotent registration to avoid duplicate timers
- [ ] Build `auction_timer_scheduler.dart` & `auction_timer_task.dart` (AC: 1,2) [Source: Implementation Guide §1]
  - [ ] Schedule tick worker every 15s via Serverpod task queue
  - [ ] Publish `TimerTick` payload to WebSocket channel + EventBridge
  - [ ] Handle expired timers by removing Redis entries and emitting completion events
  - [ ] Log tick latency to Datadog metric `auctions.timer.tick_delay_ms`

### Phase 2 – Client Countdown & Drift Handling

- [ ] Update `auction_timer_bloc.dart` to reconcile ticks with monotonic clock (AC: 2,3) [Source: Implementation Guide §1]
  - [ ] Apply smoothing window using `clock` package when drift <100ms
  - [ ] Emit `AuctionTimerDriftWarning` when >250ms and show banner
  - [ ] Trigger `sync_auction_timer_use_case` when difference >500ms
  - [ ] Persist `submission_trace_id` for observability
- [ ] Refresh `auction_timer_page.dart` & `auction_timer_banner.dart` UI (AC: 2,3) [Source: Source Tree & Implementation Guide §1]
  - [ ] Display countdown, drift badge, and websocket status pill
  - [ ] Provide fallback polling button when offline
  - [ ] Ensure accessibility labels include remaining time and drift warnings

### Phase 3 – Resilience & Observability

- [ ] Implement `timer_reconciliation_service` baseline functions (AC: 4) [Source: Implementation Guide §1 & §5]
  - [ ] Detect drift vs Serverpod clock >250ms and reschedule ticks
  - [ ] Write correction events to Redis stream `auction:timer:reconciliations`
  - [ ] Emit Datadog event + Kibana log for manual review
- [ ] Wire analytics and monitoring hooks (AC: 5) [Source: Monitoring & Analytics]
  - [ ] Ship Segment events `auction_timer_started`, `auction_timer_resynced`
  - [ ] Add Datadog counters via `drift_monitor.dart`
  - [ ] Update `docs/analytics/auction-timer-dashboard.md` with widget references
  - [ ] Document operational checks in `docs/runbooks/auction-timer.md`

### Standard Implementation Tasks

- [ ] Implement Flutter auction timer UI with BLoC state management using shared design tokens (AC: 1, 4) [Source: architecture/front-end-architecture.md#module-overview] [Source: architecture/front-end-architecture.md#state-management]
  - [ ] Create countdown timer widget with soft-close indication and formatting
  - [ ] Add timer synchronization logic with WebSocket integration
  - [ ] Implement loading states and error handling for timer disruptions
- [ ] Connect timer UI to Serverpod auction service via WebSocket and REST APIs (AC: 1, 2, 4) [Source: tech-spec-epic-10.md#api-endpoints] [Source: architecture/architecture.md#auction-service]
  - [ ] Implement GET /auctions/{id}/timer endpoint for timer status
  - [ ] Connect to WebSocket /auctions/{id}/updates for real-time updates
  - [ ] Handle connection failures and implement retry logic
- [ ] Implement timer accuracy monitoring and SLA compliance tracking (AC: 8) [Source: tech-spec-epic-10.md#monitoring-and-analytics]
  - [ ] Monitor timer drift and accuracy metrics
  - [ ] Track WebSocket latency and connection success rates
  - [ ] Implement alerting for timer failures or SLA breaches
  - [ ] Provide performance dashboards for timer service health

### Testing Requirements

- [ ] Comprehensive timer testing including precision, concurrency, and failure scenarios (AC: 1, 2, 3, 4, 5, 6, 7, 8) [Source: tech-spec-epic-10.md#testing-strategy]
  - [ ] Unit tests for timer logic, state machine, and extension mechanisms
  - [ ] Integration tests for WebSocket connectivity and event delivery
  - [ ] Performance tests for timer precision under load (100+ concurrent auctions)
  - [ ] Failure scenario tests for Redis persistence, network failures, and service restarts
  - [ ] End-to-end tests for complete auction lifecycle with timer events

## Dev Notes
### Previous Story Insights
- Epic 9 (Offer Submission) emits `offers.auction.started` events consumed by the scheduler. Align timer registration with Implementation Guide §1 to prevent duplicate entries.

- `Auction` schema provides `starts_at`, `ends_at`, `soft_close_until`, and status for timer orchestration. [Source: docs/tech-spec-epic-10.md – Data Models]
- Redis hash `auction:timer:{id}` stores end time, version, policy data for active timers. [Source: docs/tech-spec-epic-10.md – Implementation Guide §1]
- `auction_audit_log` records timer registration, tick corrections, and completion entries. [Source: docs/tech-spec-epic-10.md – Implementation Guide §1]

- `GET /auctions/{id}/timer` hydrates countdown and includes drift reference timestamp. [Source: docs/tech-spec-epic-10.md – Implementation Guide §1]
- `WebSocket /auctions/{id}/updates` streams `TimerTick` payload every 15s with trace context. [Source: docs/tech-spec-epic-10.md – Implementation Guide §1]
- `POST /timers/sync` invoked when drift exceed threshold to resynchronize server state. [Source: docs/tech-spec-epic-10.md – Implementation Guide §4]

- Flutter commerce package owns presentation/BLoC; align file paths with Source Tree directives. [Source: docs/tech-spec-epic-10.md – Source Tree]
- Serverpod services (`auction_timer_scheduler.dart`, `auction_timer_task.dart`) manage backend logic for this story. [Source: docs/tech-spec-epic-10.md – Source Tree]
- Redis cluster provides timer persistence and reconciliation stream. [Source: docs/tech-spec-epic-10.md – Implementation Guide §1]

### File Locations
- Client presentation + BLoCs: `video_window_flutter/packages/features/commerce/lib/presentation/auction_timer/` with tests mirroring under `.../test/presentation/auction_timer/`.
- Feature use cases: `video_window_flutter/packages/features/commerce/lib/use_cases/auction_timer/` coordinating with repositories.
- Core data + WebSocket services: `video_window_flutter/packages/core/lib/data/services/auctions/` and `.../repositories/auctions/` with unit tests in `packages/core/test/`.
- Server-side modules: `video_window_server/lib/src/endpoints/auctions/` and supporting business logic in `lib/src/business/auctions/`; tests in `video_window_server/test/endpoints/auctions/` and `.../business/`.

- Maintain ≥85% coverage for timer scheduler/task, bloc, and UI components referenced in Test Traceability row for Story 10.1. [Source: docs/tech-spec-epic-10.md – Test Traceability]
- Include integration tests simulating tick gaps and verifying drift correction within ±250ms. [Source: docs/tech-spec-epic-10.md – Implementation Guide §1]
- Run synthetic timer load tests (100 simultaneous timers) via `melos run test:integration -- --tags auctions-timer`. [Source: docs/tech-spec-epic-10.md – Monitoring & Analytics]

### Technical Constraints
- Timer precision must be maintained within ±5 seconds under normal load with server time synchronization and client drift correction. [Source: tech-spec-epic-10.md#timer-precision-considerations]
- Soft-close extensions must be limited to 15-minute increments with a maximum 24-hour total extension cap from original end time. [Source: brief.md#soft-close-auction-mechanics]
- WebSocket connections must support 1000+ concurrent participants with <100ms latency for timer updates and bid notifications. [Source: tech-spec-epic-10.md#real-time-updates]
- Redis timer state must persist across service restarts with automatic recovery and conflict resolution using version control. [Source: tech-spec-epic-10.md#redis-timer-state-management]
- All timer events and state transitions must be logged to the audit table with complete context for compliance and debugging. [Source: tech-spec-epic-10.md#auction-audit-log-table]
- Error handling must provide graceful degradation when Redis or WebSocket services are unavailable, with fallback polling mechanisms. [Source: tech-spec-epic-10.md#error-handling]

### Project Structure Notes
- Timer implementation aligns with the melos-managed commerce package while keeping networking and repositories in `packages/core/`. [Source: architecture/architecture.md#source-tree]
- WebSocket integration follows established patterns for real-time communication with connection pooling and recovery mechanisms. [Source: tech-spec-epic-10.md#websocket-infrastructure]

### Scope Notes
- Separate initial delivery (Timer Service + Client Countdown) from subsequent enhancements (Soft-Close Extensions, Analytics, SLA Monitoring) to manage complexity and release iteratively.

## Testing
- Follow the project testing pipeline by running `dart format`, `flutter analyze`, `flutter test --no-pub`, and `dart test` before submission. [Source: architecture/architecture.md#testing-strategy]
- Add comprehensive timer BLoC tests with fixtures covering timer precision, soft-close extensions, state transitions, and WebSocket communication scenarios. [Source: architecture/front-end-architecture.md#testing-strategy-client]
- Implement performance tests validating timer accuracy under load, WebSocket scalability, and Redis persistence reliability. [Source: tech-spec-epic-10.md#performance-tests]

## Change Log
| Date       | Version | Description | Author |
| ---------- | ------- | ----------- | ------ |
| 2025-10-09 | v0.1    | Initial draft created | Claude Code Assistant |
| 2025-10-29 | v1.0    | Scoped to baseline timer registration, scheduler, client drift handling per definitive spec | GitHub Copilot AI |

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