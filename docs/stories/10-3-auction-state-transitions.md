# Story 10-3: Auction State Transitions

## Status
Ready for Dev

## Story
**As a** maker,
**I want** auction status to update correctly as timers expire and offers are accepted,
**so that** fulfillment, notifications, and payouts align with the true auction outcome

## Acceptance Criteria
1. **BUSINESS CRITICAL**: `auction_state_service.dart` enforces state machine transitions (`pending → active → ended|accepted → completed`), locking invalid transitions and recording audit entries with actor context (Implementation Guide §3).
2. **REAL-TIME CRITICAL**: WebSocket `AuctionStateChanged` messages broadcast within 1s of transition, and client `auction_state_bloc.dart` updates UI sections (bid controls, summary banners) accordingly (Implementation Guide §3).
3. **NOTIFICATIONS CRITICAL**: EventBridge event `auctions.state.changed` and SNS messages notify makers/buyers of new status, including end-of-auction payload with winner and settlement deadline (Implementation Guide §3).
4. **INTEGRATION CRITICAL**: State transitions trigger downstream flows—accepted auctions notify fulfillment (Epic 11 dependency) while ended auctions without bids mark items for relist—and all transitions reconcile with timer completion events (Implementation Guide §3 & §5).

## Prerequisites
1. Story 10.1 – Auction Timer & State Management (baseline timer + drift)
2. Story 10.2 – Soft-Close Extension Logic (ensures final end time is accurate)
3. Story 9.2 – Server Validation & Auction Trigger (initial activation + audit log basics)

## Tasks / Subtasks

### Phase 1 – State Machine Implementation
- [ ] Expand `auction_state_service.dart` transitions (AC: 1) [Source: docs/tech-spec-epic-10.md – Implementation Guide §3]
  - [ ] Define transition rules with guard clauses and rollback
  - [ ] Persist new status + `ended_at` or `accepted_at` timestamps
  - [ ] Append audit log entries with actor, reason, and trace ID
  - [ ] Handle concurrent requests via optimistic locking/version checks
- [ ] Ensure timer completion triggers state update (AC: 1,4)
  - [ ] When timer task marks auction finished, transition to `ended`
  - [ ] If maker accepts bid before expiry, cancel further timer ticks

### Phase 2 – Real-Time & Notifications
- [ ] Update `auction_updates_channel.dart` to emit `AuctionStateChanged` (AC: 2) [Source: Source Tree]
  - [ ] Include payload: status, winner info, settlement deadline, trace ID
  - [ ] Backfill latest bids and soft-close metadata for reconnecting clients
- [ ] Implement client `auction_state_bloc.dart` (AC: 2)
  - [ ] React to state events and adjust UI components (disable bids, show winner banner)
  - [ ] Trigger local notifications (snackbar/toast) summarizing outcome
- [ ] Configure EventBridge + SNS notifications (AC: 3) [Source: Implementation Guide §3]
  - [ ] Emit events for acceptance and completion with payload metadata
  - [ ] Update Terraform (`auctions_timer.tf`) with SNS topics + subscriptions

### Phase 3 – Downstream Integration & QA
- [ ] Integrate with fulfillment hooks (AC: 4)
  - [ ] For `accepted` state, enqueue job for Epic 11 fulfillment workflow
  - [ ] For `ended` without bids, notify maker success team to relist
- [ ] Expand analytics + monitoring
  - [ ] Segment event `auction_state_changed` with previous/new status
  - [ ] Datadog counter `auctions.state.transition_count`
  - [ ] Dashboard update per `docs/analytics/auction-timer-dashboard.md`
- [ ] Tests: `auction_state_service_test.dart`, `auctions_state_event_test.dart`, bloc/widget coverage (AC: 1-4) [Source: Test Traceability]

## Dev Notes
- Coordinate with Story 9.3 cancellation logic to ensure cancelled offers propagate correct state changes.
- Timer completion events (Story 10.4) must not double-fire transitions—use version checks.

## Data Models
- `Auction` table gains `ended_at`, `accepted_at`, `completed_at` timestamps. [Source: docs/tech-spec-epic-10.md – Implementation Guide §3]
- Audit log entries include `state_change_reason` and `actor_role`. [Source: docs/tech-spec-epic-10.md – Implementation Guide §3]

## API Specifications
- `POST /auctions/{id}/state` (internal) accepts `{transition, actorId, reason}` for maker/admin actions. [Source: docs/tech-spec-epic-10.md – Implementation Guide §3]
- WebSocket event `AuctionStateChanged` contains current state and metadata. [Source: docs/tech-spec-epic-10.md – Implementation Guide §3]

## Component Specifications
- Server: `auction_state_service.dart`, `auction_timer_scheduler.dart` (stop/resume), integrations in `infrastructure/terraform/`. [Source: docs/tech-spec-epic-10.md – Source Tree]
- Client: `auction_state_bloc.dart`, UI updates within `auction_timer_page.dart`. [Source: docs/tech-spec-epic-10.md – Source Tree]

## Testing Requirements
- ≥80% coverage for state service, WebSocket channel, and client bloc tests. [Source: docs/tech-spec-epic-10.md – Test Traceability]
- Integration tests verifying SNS/EventBridge payloads and fulfillment hooks triggered correctly. [Source: docs/tech-spec-epic-10.md – Implementation Guide §3]

## Change Log
| Date       | Version | Description | Author |
| ---------- | ------- | ----------- | ------ |
| 2025-10-29 | v1.0    | Definitive auction state transition scope aligned to Implementation Guide §3 | GitHub Copilot AI |

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
