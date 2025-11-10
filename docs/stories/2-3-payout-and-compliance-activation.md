# Story 2-3: Payout & Compliance Activation

## Status
Ready for Dev

## Story
**As a** creator preparing to accept payments,
**I want** a guided payout activation flow integrated with checkout,
**so that** buyers cannot proceed until I complete required compliance steps.

## Acceptance Criteria
1. Attempting to launch checkout when `!canCollectPayments` opens a modal summarizing payout prerequisites and provides Stripe Express onboarding CTA. [Source: docs/tech-spec-epic-2.md#story-23-payout--compliance-activation]
2. Successful Stripe Express onboarding updates `payoutConfiguredAt` and unlocks checkout within 5 seconds of webhook completion. [Source: docs/tech-spec-epic-2.md#3-api-endpoints]
3. Tax form collection is enforced in-line using Stripe tax document flow; results stored encrypted and appear in capability status blockers map. [Source: docs/tech-spec-epic-2.md#story-23-payout--compliance-activation]
4. Users can track payout status in Capability Center with links to complete outstanding tasks; blocked state includes reason codes (e.g., `stripe_requirements_due`). [Source: docs/tech-spec-epic-2.md#2-data-models]
5. Audit event `capability.unlocked` with capability `collect_payments` is emitted once activation succeeds, and checkout guard verifies flag on server before creating session. [Source: docs/tech-spec-epic-2.md#8-implementation-guide]

## Prerequisites
1. Story 2.1 – Capability Enablement Request Flow (base capability request pipeline)
2. Stripe Connect Express account configured with webhooks to Capabilities endpoint
3. Compliance policies defined for tax collection and payout eligibility

## Tasks / Subtasks

### Client Experience
- [ ] Implement `PayoutBlockerSheet` component explaining steps and linking to Stripe onboarding. [Source: docs/tech-spec-epic-2.md#7-source-tree--file-directives]
- [ ] Add status indicators in capability center, including Stripe account state, tax form submission, and review queue. [Source: docs/tech-spec-epic-2.md#2-data-models]
- [ ] Provide notifications and email reminders when payouts remain blocked for >24 hours.

### Serverpod Integration
- [ ] Implement Stripe webhook handler updating `verification_tasks` payload and resolving capability requests. [Source: docs/tech-spec-epic-2.md#31-request-payload-examples]
- [ ] Store Stripe account IDs encrypted and track requirement due statuses in blockers map. [Source: docs/tech-spec-epic-2.md#5-security--compliance-considerations]
- [ ] Guard `/checkout/session/create` to ensure `canCollectPayments` is true; return error with blocker summary when false. [Source: docs/tech-spec-epic-2.md#4-implementation-details-story-mapping]

### Analytics & Monitoring
- [ ] Emit events `payout_activation_started` and `payout_activation_completed` with duration metrics. [Source: docs/tech-spec-epic-2.md#11-monitoring--analytics]
- [ ] Dashboard card for payout activation funnel (requested → onboarded → enabled) and tax document completion rates. [Source: docs/tech-spec-epic-2.md#11-monitoring--analytics]
- [ ] Configure alert when Stripe webhooks fail or requirement due >48 hours.

### Testing
- [ ] Integration test simulating webhook payload to confirm capability unlock occurs and checkout guard passes. [Source: docs/tech-spec-epic-2.md#9-acceptance-criteria-traceability]
- [ ] Security test verifying encrypted storage of Stripe account IDs and tax documents. [Source: docs/tech-spec-epic-2.md#5-security--compliance-considerations]
- [ ] QA checklist ensures blocked state messaging is accurate across locales.

### Configuration & Feature Flag Foundation (Merged from Core Platform Services 02.3)
- [ ] Implement remote configuration service with local JSON fallback and environment-specific overrides.
- [ ] Expose strongly typed feature flags (e.g., `FeatureFlags.capabilityCenterEnabled`) with percentage rollout and segment targeting support.
- [ ] Document configuration change workflow, audit logging, and flag toggling playbook in `docs/architecture/coding-standards.md`.
- [ ] Provide test hooks to override flags/config values for unit, widget, and integration suites.

## Data Models
- `VerificationTask` with type `stripe_payout`, storing account ID and requirement status. [Source: docs/tech-spec-epic-2.md#2-data-models]
- `UserCapabilities.payoutConfiguredAt` timestamp gating checkout availability. [Source: docs/tech-spec-epic-2.md#2-data-models]

## API Specifications
- `POST /capabilities/request` invoked when checkout blocked to ensure request exists. [Source: docs/tech-spec-epic-2.md#3-api-endpoints]
- Stripe webhook → `POST /capabilities/tasks/{id}/complete` updates verification task and capability record. [Source: docs/tech-spec-epic-2.md#31-request-payload-examples]
- `POST /checkout/session` guards on capability flag and returns blocker details if inactive. [Source: docs/tech-spec-epic-2.md#4-implementation-details-story-mapping]

## Component Specifications
- Client UI components under `video_window_flutter/packages/features/checkout/lib/presentation/widgets/`. [Source: docs/tech-spec-epic-2.md#7-source-tree--file-directives]
- Stripe integration logic in `video_window_server/lib/src/services/verification_service.dart`. [Source: docs/tech-spec-epic-2.md#7-source-tree--file-directives]
- Checkout guard implemented within `video_window_server/lib/src/endpoints/commerce/checkout_endpoint.dart`.

## Testing Requirements
- End-to-end test ensuring buyer cannot start checkout until payouts active. [Source: docs/tech-spec-epic-2.md#9-acceptance-criteria-traceability]
- Automated test verifying blockers map surfaces Stripe requirement codes. [Source: docs/tech-spec-epic-2.md#6-database-schema]
- Performance test ensuring webhook processing <200 ms p95. [Source: docs/tech-spec-epic-2.md#10-testing-strategy]

## Technical Constraints
- Stripe webhooks must be idempotent; duplicate events should not flip state multiple times. [Source: docs/tech-spec-epic-2.md#5-security--compliance-considerations]
- Tax documents stored encrypted with CMK `alias/video-window-sensitive-docs`. [Source: docs/tech-spec-epic-2.md#5-security--compliance-considerations]
- Capability unlock only after all Stripe `requirements_due` resolved; partial unlock unsupported for MVP. [Source: docs/tech-spec-epic-2.md#1-architecture-overview]

## Change Log
| Date       | Version | Description | Author |
| ---------- | ------- | ----------- | ------ |
| 2025-11-02 | v1.0    | Replaces invitation-based payout story with capability activation flow | Documentation Task Force |

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
