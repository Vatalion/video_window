# Story 10-4: Timer Precision & Synchronization

## Status
Ready for Dev

## Story
**As an** operations engineer,
**I want** auction timers to self-correct when drift is detected across servers or clients,
**so that** countdowns remain accurate and compliant with auction policy SLAs

## Acceptance Criteria
1. **RELIABILITY CRITICAL**: `timer_reconciliation_service.dart` scans active timers every 60s, detects drift >250ms compared to canonical clock, and applies corrective writes with audit entries (Implementation Guide §4).
2. **CLIENT EXPERIENCE**: `sync_auction_timer_use_case.dart` requests `POST /timers/sync` when local drift >500ms, coordinating via `synchronized` mutex to avoid conflicting updates and updating UI once resynced (Implementation Guide §4).
3. **OBSERVABILITY CRITICAL**: Metrics `auctions.timer.drift_ms`, `auctions.timer.tick_delay_ms`, and Segment event `auction_timer_resynced` emit from both server and client flows, with alerts defined in `docs/analytics/auction-timer-dashboard.md` (Monitoring & Analytics).
4. **RESILIENCE**: Synthetic load test `auction_timer_drift_test.dart` simulates 100 concurrent timers and ensures recovery within ≤3 cycles, with results published to Datadog + runbook checklist (Implementation Guide §4 & §5).

## Prerequisites
1. Story 10.1 – Auction Timer & State Management (baseline ticks + registration)
2. Story 10.2 – Soft-Close Extension Logic (final end times)
3. Story 10.3 – Auction State Transitions (ensures timer corrections don’t break state)

## Tasks / Subtasks

### Phase 1 – Server Drift Detection
- [ ] Implement drift scan in `timer_reconciliation_service.dart` (AC: 1) [Source: docs/tech-spec-epic-10.md – Implementation Guide §4]
  - [ ] Compare Redis `endsAt` vs Serverpod `DateTime.now()` + residual duration
  - [ ] Apply corrective end times, update Redis hash/version
  - [ ] Push reconciliation event to Redis stream `auction:timer:reconciliations`
  - [ ] Log correction with trace ID in `auction_audit_log`
- [ ] Schedule reconciliation task via EventBridge/Serverpod (AC: 1)
  - [ ] Execute every 60s; skip if no active timers
  - [ ] Alert on failures using Datadog monitor `auctions.scheduler.failures`

### Phase 2 – Client Resync & UX
- [ ] Implement `sync_auction_timer_use_case.dart` (AC: 2) [Source: Source Tree & Implementation Guide §4]
  - [ ] Calculate client drift vs server timestamp; trigger sync when >500ms
  - [ ] Use `synchronized` guard to serialise updates
  - [ ] Update bloc state with corrected remaining time + success banner
- [ ] Update `auction_timer_banner.dart` to show “Resynced” badge and link to runbook entry for escalations (AC: 2)

### Phase 3 – Observability & Testing
- [ ] Emit metrics + events (AC: 3)
  - [ ] Datadog gauge `auctions.timer.drift_ms` from server + client
  - [ ] Segment `auction_timer_resynced`, `auction_timer_drift_warning`
  - [ ] Update `docs/analytics/auction-timer-dashboard.md` with drift widgets
- [ ] Build synthetic load + integration tests (AC: 4) [Source: Test Traceability]
  - [ ] `auction_timer_drift_test.dart` simulates network lag and verifies recovery within 3 cycles
  - [ ] Add monitoring pipeline to record results nightly
  - [ ] Document in `docs/runbooks/auction-timer.md` the escalation steps if test fails

## Dev Notes
- Coordinate with Observability team to ensure Datadog API keys align with environment YAML in tech spec.
- Synthetic test should run in CI nightly and staging hourly to catch drift early.

## Data Models
- Reconciliation events stored in Redis stream contain timer ID, detected drift, corrective delta, and trace ID. [Source: docs/tech-spec-epic-10.md – Implementation Guide §4]

## API Specifications
- `POST /timers/sync` accepts `{auctionId, clientTimestamp}` and returns corrected `endsAt`, `remainingMs`. [Source: docs/tech-spec-epic-10.md – Implementation Guide §4]

## Component Specifications
- Server services: `timer_reconciliation_service.dart`, scheduler tasks. [Source: docs/tech-spec-epic-10.md – Source Tree]
- Client: `sync_auction_timer_use_case.dart`, bloc + banner updates. [Source: docs/tech-spec-epic-10.md – Source Tree]

## Testing Requirements
- ≥80% coverage for reconciliation service, client use case, and drift monitor utilities. [Source: docs/tech-spec-epic-10.md – Test Traceability]
- Load test ensures drift correction remains within SLA for 100 concurrent timers; results logged and reviewed weekly. [Source: docs/tech-spec-epic-10.md – Monitoring & Analytics]

## Change Log
| Date       | Version | Description | Author |
| ---------- | ------- | ----------- | ------ |
| 2025-10-29 | v1.0    | Definitive timer precision & sync scope aligned to Implementation Guide §4 | GitHub Copilot AI |

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
