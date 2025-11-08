# Story 12-2: Payment Window Enforcement

## Status
Ready for Dev

## Story
**As a** commerce operations lead,
**I want** payment sessions to expire automatically after 24 hours,
**so that** auctions reopen quickly when buyers fail to pay.

## Acceptance Criteria
1. **WINDOW CRITICAL**: `payment_window_task.dart` closes sessions past `expiresAt`, expires Stripe checkout objects, and transitions status to `expired` with audit entry. (Implementation Guide §2)
2. **CLIENT UX**: `payment_window_bloc.dart` drives `payment_window_timer.dart` countdown with drift correction, offline recovery, and WCAG-compliant alerts when <60 minutes remain. (Implementation Guide §2)
3. **OPERATIONS**: `payment_window_endpoint.dart` allows authorized admins to extend or terminate windows with RBAC and SNS notifications to maker/buyer topics. (Implementation Guide §2)
4. **OBSERVABILITY**: Metrics `payments.window.expired_count` and `payments.window.extension_count` plus Segment event `payments.checkout.expired` publish with session + auction metadata. (Implementation Guide §2, Monitoring & Analytics)

## Prerequisites
1. Story 12.1 – Stripe Checkout Integration.
2. Redis cluster + EventBridge schedule configured via `infrastructure/terraform/payments.tf`.
3. Notification templates defined for payment expiration alerts (Epic 9 messaging assets).

## Tasks / Subtasks

### Phase 1 – Server Enforcement
- [ ] Implement `payment_window_service.dart` to persist expiry metadata in Redis (`payment:window:{sessionId}`) and compute remaining time. (AC: 1) [Source: docs/tech-spec-epic-12.md – Implementation Guide §2]
- [ ] Create `payment_window_task.dart` invoked by EventBridge to expire overdue sessions, cancel Stripe checkout, and emit audit log `payment_expired`. (AC: 1)
- [ ] Add `payment_window_endpoint.dart` for admin override (extend/terminate) with RBAC + SNS notifications. (AC: 3)

### Phase 2 – Client Countdown Experience
- [ ] Build `payment_window_bloc.dart` and `payment_window_timer.dart` to stream remaining time, pause/resume offline, and surface a11y announcements when thresholds hit. (AC: 2) [Source: Implementation Guide §2]
- [ ] Update `payment_checkout_page.dart` to embed timer widget, including maker/admin override entry points. (AC: 2)
- [ ] Ensure `observe_payment_status_use_case.dart` triggers resync on reconnect using `payment_window_service.dart`. (AC: 2)

### Phase 3 – Analytics & QA
- [ ] Emit Datadog metrics `payments.window.expired_count`, `payments.window.extension_count`, `payments.window.override_count` via `payments_metrics.dart`; wire to dashboard `docs/analytics/stripe-payments-dashboard.md`. (AC: 4)
- [ ] Publish Segment event `payments.checkout.expired` with root cause metadata (`reason`, `retryEligible`). (AC: 4)
- [ ] Tests: `payment_window_task_test.dart`, `payment_window_service_test.dart`, `payment_window_endpoint_test.dart`, `payment_window_bloc_test.dart`. (AC: 1-4) [Source: Test Traceability]

## Dev Notes
- Use Redis TTL and versioning to avoid double-expiration when multiple workers run.
- Coordinate with Auction state machine (Story 10.3) to relist auction or notify maker after expiration.
- Admin overrides must respect maximum extension policy defined in maker configuration.

## Data Models
- `payment_sessions` status transitions to `expired` with `expired_at` timestamp and audit log. [Source: docs/tech-spec-epic-12.md – Implementation Guide §2]
- Redis sorted set tracks pending expirations to support reconciliation. [Source: docs/tech-spec-epic-12.md – Implementation Guide §2]

## API Specifications
- `GET /payments/checkout/{sessionId}/status` returns `remainingTime` and `expiresAt`. [Source: docs/tech-spec-epic-12.md – API Endpoints]
- `POST /payments/window/{sessionId}/override` accepts `{action: extend|terminate, minutes?: int}` with RBAC guard. [Source: docs/tech-spec-epic-12.md – Implementation Guide §2]

## Component Specifications
- Server services: `payment_window_service.dart`, `payment_window_task.dart`, `payment_window_endpoint.dart`. [Source: docs/tech-spec-epic-12.md – Source Tree]
- Client presentation: `payment_window_bloc.dart`, `payment_window_timer.dart`. [Source: docs/tech-spec-epic-12.md – Source Tree]
- Telemetry: `payments_metrics.dart` + Segment instrumentation. [Source: docs/tech-spec-epic-12.md – Source Tree]

## Testing Requirements
- Ensure expiration task handles idempotency and Stripe API failures gracefully with retries. [Source: docs/tech-spec-epic-12.md – Implementation Guide §2]
- Widget tests must verify countdown formatting, accessibility announcements, and timezone adjustments. [Source: docs/tech-spec-epic-12.md – Implementation Guide §2]

## Change Log
| Date       | Version | Description | Author |
| ---------- | ------- | ----------- | ------ |
| 2025-10-29 | v1.0    | Definitive payment window enforcement scope | GitHub Copilot AI |

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
