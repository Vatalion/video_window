# Story 9-3: Offer Withdrawal & Cancellation

## Status
Ready for Dev

## Story
**As a** buyer,
**I want** to withdraw or cancel my offer within the allowed window,
**so that** I can manage commitments while preserving full audit accountability

## Acceptance Criteria
1. **BUSINESS CRITICAL**: `offer_cancel_endpoint` enforces `OFFER_MODIFICATION_WINDOW_MINUTES`, verifies actor authority (buyer or maker delegate), appends immutable audit records, and returns updated status payloads.
2. Offer cancellation UI (`offer_cancellation_page.dart`, `offer_cancellation_dialog.dart`) displays remaining window, captures canned + freeform reasons, and confirms outcome with updated story context.
3. Maker notifications publish to SNS topic `offers.cancelled`, Slack alert fires for high-value cancellations, and Datadog metric `offers.cancellation.success_rate` remains ≥95%.
4. Cancellation attempts after window expiry surface localized errors, log to Sentry with `submission_trace_id`, and provide escalation path to support.
5. Automated tests cover endpoint authz, window enforcement, audit logging, notification dispatch, and client UX flows (widget + bloc tests).

## Prerequisites
1. Story 9.1 – Offer Submission Flow (offer draft + submission states)
2. Story 9.2 – Server Validation & Auction Trigger (submission saga + audit log base)
3. Story 1.1 – Implement Email OTP Sign-In (session validation)
4. Story 2.2 – RBAC Enforcement (maker delegate permissions)

## Tasks / Subtasks

### Phase 1 – Server-Side Cancellation Enforcement

- [ ] **BUSINESS CRITICAL - BUS-003**: Implement `offer_cancel_endpoint.dart` with SLA + authority checks (AC: 1) [Source: docs/tech-spec-epic-9.md – Implementation Guide §4]
  - [ ] Validate actor identity (buyer, maker, commerce admin) using RBAC roles
  - [ ] Enforce modification window vs `created_at` timestamp and maker override policy
  - [ ] Append `OfferAuditLog` entry capturing reason, actor, device info
  - [ ] Emit EventBridge event `offers.cancellation.completed`
- [ ] Expand `offer_cancellation_service.dart` to encapsulate invariants (AC: 1, 4)
  - [ ] Reject cancellations for offers already accepted & auction closed
  - [ ] Provide structured error codes for UI mapping
  - [ ] Trigger compensating actions (release payment hold) on success

### Phase 2 – Client UX & Analytics

- [ ] Build `offer_cancellation_bloc.dart` + dialogs/pages (AC: 2) [Source: docs/tech-spec-epic-9.md – Implementation Guide §4]
  - [ ] Fetch SLA metadata from maker policy payload / cancellation endpoint preflight
  - [ ] Present canned reasons with optional note field and char limits
  - [ ] Update story context state post-cancellation success
  - [ ] Record local audit context for offline history (Story 9.4 dependency)
- [ ] Emit analytics + observability signals (AC: 3-4) [Source: docs/tech-spec-epic-9.md – Monitoring & Analytics]
  - [ ] Segment events `offer_cancelled`, `offer_cancellation_blocked`
  - [ ] Datadog metric `offers.client.cancellation_latency_ms`
  - [ ] Sentry breadcrumb with `submission_trace_id`
  - [ ] Slack notification via `slack_notifier` when amount > maker auto-reject threshold

### Phase 3 – Notifications, QA, and Runbooks

- [ ] Update SNS + EventBridge wiring in `offers.tf` (AC: 3) [Source: docs/tech-spec-epic-9.md – Implementation Guide §4]
  - [ ] Create topic `offers-cancelled` with maker + ops subscriptions
  - [ ] Add EventBridge rule to notify auction timer service of cancellations
  - [ ] Document runbook section `docs/runbooks/offers-submission.md` for cancellation handling
- [ ] Expand automated test coverage (AC: 5) [Source: docs/tech-spec-epic-9.md – Test Traceability]
  - [ ] Endpoint tests verifying SLA enforcement and authz
  - [ ] Service tests ensuring audit log entries + payment reversal
  - [ ] Widget + bloc tests for cancellation UI flows
  - [ ] Contract tests for SNS notification payload schema

## Dev Notes
### Previous Story Insights
- Coordinate with Story 9.2 audit logging format to guarantee consistent `OfferAuditLog` schema. [Source: docs/tech-spec-epic-9.md – Data Models]
- Story 10.1 depends on accurate cancellation events to manage auction timers.

### Data Models
- `OfferAuditLog` entries must include old/new status, reason, actor, and device metadata. [Source: docs/tech-spec-epic-9.md – Data Models]
- Maker policy defines cancellation window overrides; ensure exposure via validation endpoint. [Source: docs/tech-spec-epic-9.md – Implementation Guide §4]

### API Specifications
- `PUT /offers/{offerId}/cancel` enforces SLA, returns updated offer and audit entry metadata. [Source: docs/tech-spec-epic-9.md – Implementation Guide §4]
- EventBridge event `offers.cancellation.completed` informs downstream services. [Source: docs/tech-spec-epic-9.md – Implementation Guide §4]

### Component Specifications
- Client presentation layer in `video_window_flutter/packages/features/commerce/lib/presentation/` (cancellation page/dialog). [Source: docs/tech-spec-epic-9.md – Source Tree & File Directives]
- Server logic resides in `video_window_server/lib/src/services/offers/offer_cancellation_service.dart`. [Source: docs/tech-spec-epic-9.md – Source Tree & File Directives]
- Infrastructure updates in `infrastructure/terraform/offers.tf` + `offers_audit_glacier.tf`. [Source: docs/tech-spec-epic-9.md – Source Tree & File Directives]

### Testing Requirements
- Maintain ≥80% coverage for cancellation bloc, endpoint, and service modules. [Source: docs/tech-spec-epic-9.md – Test Traceability]
- Add integration test verifying SNS + EventBridge payloads using sandbox topic. [Source: docs/tech-spec-epic-9.md – Monitoring & Analytics]
- Include regression test for window expiry and duplicate cancellation attempts. [Source: docs/tech-spec-epic-9.md – Implementation Guide §4]

## Change Log
| Date       | Version | Description | Author |
| ---------- | ------- | ----------- | ------ |
| 2025-10-29 | v1.0    | Initial definitive scope for cancellation workflows mapped to Implementation Guide §4 | GitHub Copilot AI |

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
