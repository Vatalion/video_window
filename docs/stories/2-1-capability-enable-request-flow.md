# Story 2-1: Capability Enablement Request Flow

## Status
Ready for Dev

## Story
**As a** creator who wants to publish or sell,
**I want** to see exactly what steps I must complete when a restricted action is blocked,
**so that** I can request the required capability without leaving the flow.

## Acceptance Criteria
1. Capability Center screen (settings → capabilities) surfaces current capability status, blockers, and CTAs for `publish`, `collect_payments`, and `fulfill_orders`. [Source: docs/tech-spec-epic-2.md#story-21-capability-enablement-request-flow]
2. Inline prompts in publish, checkout, and fulfillment flows detect missing capability and open the guided checklist modal with context (draft ID, entry point). [Source: docs/tech-spec-epic-2.md#story-21-capability-enablement-request-flow]
3. Submitting a request calls `POST /capabilities/request`, persists contextual metadata, and updates UI state to in-progress with polling backoff. Idempotent retries do not create duplicate requests. [Source: docs/tech-spec-epic-2.md#api-endpoints]
4. Audit event `capability.requested` is emitted with capability type, entry point, and device fingerprint, and is visible on the capability operations dashboard. [Source: docs/tech-spec-epic-2.md#8-implementation-guide]
5. Analytics event `capability_request_submitted` is recorded with capability type, entry point, and success/failure result. [Source: docs/tech-spec-epic-2.md#story-21-capability-enablement-request-flow]

## Prerequisites
1. Story 1.1 – Implement Email OTP Sign-In (user authentication baseline)
2. Story 1.3 – Session Management & Refresh (ensures capability polling uses fresh tokens)
3. Epic 1 tech spec updates delivered (capability flags available on `User` entity)

## Tasks / Subtasks

### Capability Center UI & Bloc
- [ ] Create `CapabilityCenterPage` listing capability cards with status badges and CTA buttons. [Source: docs/tech-spec-epic-2.md#story-21-capability-enablement-request-flow]
- [ ] Implement `CapabilityCenterBloc` fetching `GET /capabilities/status` on init, handling poll refreshes, and emitting analytics. [Source: docs/tech-spec-epic-2.md#2-data-models]
- [ ] Add localization strings for capability statuses (`Inactive`, `In Review`, `Ready`, `Blocked`).

### Inline Prompts & Entry Point Wiring
- [ ] Publish flow: insert `PublishCapabilityCard` gate when `!canPublish`. [Source: docs/tech-spec-epic-2.md#story-22-verification-within-publish-flow]
- [ ] Checkout CTA: add `PayoutBlockerSheet` when `!canCollectPayments`. [Source: docs/tech-spec-epic-2.md#story-23-payout--compliance-activation]
- [ ] Fulfillment workspace: surface `FulfillmentCapabilityCallout` when `!canFulfillOrders`. [Source: docs/tech-spec-epic-2.md#story-24-device-trust--risk-monitoring]

### Repository & Service Layer
- [ ] Implement `CapabilityRepository` in core package with `fetchStatus()`, `requestCapability()`, and `subscribeToUpdates()` methods. [Source: docs/tech-spec-epic-2.md#7-source-tree--file-directives]
- [ ] Add `CapabilityService` for API calls, ensuring exponential backoff polling and HTTP retry policies. [Source: docs/tech-spec-epic-2.md#3-api-endpoints]
- [ ] Emit domain event `CapabilityRequested` for analytics bus.

### Serverpod Endpoint
- [ ] Implement `CapabilityEndpoint.requestCapability` verifying prerequisites, creating/refreshing `capability_requests`, and publishing audit events. [Source: docs/tech-spec-epic-2.md#8-implementation-guide]
- [ ] Enforce unique `(user_id, capability)` constraint and idempotency tokens. [Source: docs/tech-spec-epic-2.md#6-database-schema]
- [ ] Update OpenAPI/Client generation and regenerate Serverpod client.

### Observability & QA
- [ ] Add Grafana panel for request volume, approval rate, and blocker distribution. [Source: docs/tech-spec-epic-2.md#11-monitoring--analytics]
- [ ] Write widget + bloc tests for capability center states and inline prompts. [Source: docs/tech-spec-epic-2.md#9-acceptance-criteria-traceability]
- [ ] Author integration test covering request submission → status polling → unlock event.

### Design System Foundation (Merged from Core Platform Services 02.1)
- [ ] Define semantic light and dark palettes with centralized theme extension (`packages/shared/theme/color_palette.dart`).
- [ ] Publish typography scales and spacing tokens with unit tests guarding accessors (`packages/shared/theme/typography.dart`, `spacing.dart`).
- [ ] Update `docs/architecture/coding-standards.md` with token usage guidance and migration examples for legacy widgets.
- [ ] Ensure splash and placeholder feed screens consume tokens only (no hard-coded colors/spacing) and validate light/dark switching.

## Data Models
- `UserCapabilities` snapshot retrieved via `GET /capabilities/status`, including blockers map and review state. [Source: docs/tech-spec-epic-2.md#2-data-models]
- `CapabilityRequest` records containing user, capability type, status, metadata, and audit timestamps. [Source: docs/tech-spec-epic-2.md#2-data-models]

## API Specifications
- `GET /capabilities/status` returns `UserCapabilities` plus blockers. Cached for ≤10 seconds per user. [Source: docs/tech-spec-epic-2.md#3-api-endpoints]
- `POST /capabilities/request` accepts `capability` and `context` payload, is idempotent, and responds with updated status snapshot. [Source: docs/tech-spec-epic-2.md#31-request-payload-examples]

## Component Specifications
- Flutter components live under `video_window_flutter/packages/features/profile/lib/presentation/capability_center/`. [Source: docs/tech-spec-epic-2.md#7-source-tree--file-directives]
- Capability repository/service live under `video_window_flutter/packages/core/lib/data/`. [Source: docs/tech-spec-epic-2.md#7-source-tree--file-directives]
- Server code located at `video_window_server/lib/src/endpoints/capabilities/` with corresponding services and repositories. [Source: docs/tech-spec-epic-2.md#7-source-tree--file-directives]

## Testing Requirements
- Bloc/widget coverage ≥85% across loading, success, error, and blocked states. [Source: docs/tech-spec-epic-2.md#10-testing-strategy]
- Integration test verifying idempotent requests and audit event emission. [Source: docs/tech-spec-epic-2.md#9-acceptance-criteria-traceability]
- Load test ensures `POST /capabilities/request` handles 50 req/s with p95 < 100 ms. [Source: docs/tech-spec-epic-2.md#10-testing-strategy]

## Technical Constraints
- Capability status cache invalidates immediately on unlock events. [Source: docs/tech-spec-epic-2.md#8-implementation-guide]
- Requests must enforce per-user rate limiting to prevent spam (5/min). [Source: docs/tech-spec-epic-2.md#5-security--compliance-considerations]
- Audit events are mandatory; failure to publish should roll back state change. [Source: docs/tech-spec-epic-2.md#5-security--compliance-considerations]

## Change Log
| Date       | Version | Description | Author |
| ---------- | ------- | ----------- | ------ |
| 2025-11-02 | v1.0    | Rewritten for unified capability flow | Documentation Task Force |

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
