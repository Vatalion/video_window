# Story 2-4: Device Trust & Risk Monitoring

## Status
Ready for Dev

## Story
**As a** platform security stakeholder,
**I want** to ensure only trusted devices can perform high-risk actions,
**so that** we reduce fraud while keeping legitimate creators active.

## Acceptance Criteria
1. Device registration occurs on app launch, capturing device ID, platform, attestation result, and telemetry, then posts to `/devices/register`. [Source: docs/tech-spec-epic-2.md#story-24-device-trust--risk-monitoring]
2. Trust score is calculated server-side; capabilities requiring trusted devices (`fulfill_orders`) remain blocked until at least one device exceeds threshold. [Source: docs/tech-spec-epic-2.md#12-deployment-considerations]
3. Device management screen lists registered devices with trust score, last seen timestamp, and options to revoke; revocation lowers capability state appropriately. [Source: docs/tech-spec-epic-2.md#7-source-tree--file-directives]
4. Alerts trigger when multiple low-trust devices register for the same user within 24 hours. [Source: docs/tech-spec-epic-2.md#11-monitoring--analytics]
5. Capability downgrade event is emitted when trust score falls below threshold or all devices revoked, notifying user via push/email. [Source: docs/tech-spec-epic-2.md#8-implementation-guide]

## Prerequisites
1. Story 2.1 – Capability Enablement Request Flow
2. Risk SDK integration (Apple DeviceCheck / Google Play Integrity) finalized
3. Audit logging pipeline operational (Epic 1 stories)

## Tasks / Subtasks

### Client Telemetry Capture
- [ ] Implement `DeviceTrustService` on Flutter capturing telemetry and trust hints. [Source: docs/tech-spec-epic-2.md#7-source-tree--file-directives]
- [ ] Ensure background refresh updates last seen timestamp without exhaustive polling. [Source: docs/tech-spec-epic-2.md#4-implementation-details-story-mapping]
- [ ] Add UI in settings → security to list devices and provide revoke button.

### Server Device Trust Service
- [ ] Create `DeviceTrustService` evaluating telemetry and producing trust score (base 0.8 minus risk penalties). [Source: docs/tech-spec-epic-2.md#4-implementation-details-story-mapping]
- [ ] Persist entries in `trusted_devices` table and update capability blockers when none exceed threshold. [Source: docs/tech-spec-epic-2.md#6-database-schema]
- [ ] Emit `device.trust_scored` and `capability.downgraded` events to audit stream. [Source: docs/tech-spec-epic-2.md#5-security--compliance-considerations]

### Alerts & Analytics
- [ ] Add Grafana panel for trust score distribution and anomaly detection chart. [Source: docs/tech-spec-epic-2.md#11-monitoring--analytics]
- [ ] Configure alert rule for low trust spike (>3 low-trust devices/user in 24h).
- [ ] Instrument `device_trust_revoked` analytics event with reason code.

### Testing
- [ ] Unit tests for trust scoring logic covering jailbreak/rooted, outdated OS, emulator detection scenarios. [Source: docs/tech-spec-epic-2.md#9-acceptance-criteria-traceability]
- [ ] Integration test verifying capability downgrade when all devices revoked. [Source: docs/tech-spec-epic-2.md#9-acceptance-criteria-traceability]
- [ ] Penetration test attempt to spoof device telemetry; ensure rejection logged. [Source: docs/tech-spec-epic-2.md#5-security--compliance-considerations]

### Telemetry Foundation (Merged from Core Platform Services 02.4)
- [ ] Build shared analytics wrapper that normalizes event names, session context, and offline buffering before dispatching to Serverpod.
- [ ] Ensure Serverpod analytics endpoint emits structured events with user, request, and capability metadata aligned to analytics schema.
- [ ] Maintain event catalog (screen_view, button_click, capability flows) with versioning in `docs/analytics/mvp-analytics-events.md`.
- [ ] Validate end-to-end telemetry flow via integration tests, including replay handling and backpressure scenarios.

## Data Models
- `TrustedDevice` entries storing device metadata, trust score, telemetry, and revocation state. [Source: docs/tech-spec-epic-2.md#2-data-models]
- `UserCapabilities.blockers` map includes device trust blocker reason. [Source: docs/tech-spec-epic-2.md#2-data-models]

## API Specifications
- `POST /devices/register` accepts telemetry payload and returns current trust score. [Source: docs/tech-spec-epic-2.md#3-api-endpoints]
- `GET /devices` lists trusted devices for authenticated user; `POST /devices/{id}/revoke` revokes trust. [Source: docs/tech-spec-epic-2.md#3-api-endpoints]

## Component Specifications
- Flutter device management UI lives under `video_window_flutter/packages/features/profile/lib/presentation/security/`. [Source: docs/tech-spec-epic-2.md#7-source-tree--file-directives]
- Server endpoints/services located within `video_window_server/lib/src/endpoints/capabilities/` and `.../services/device_trust_service.dart`. [Source: docs/tech-spec-epic-2.md#7-source-tree--file-directives]
- Alerts configured in existing monitoring stack (Grafana + PagerDuty).

## Testing Requirements
- Automated tests cover revoke flow ensuring capability blockers update. [Source: docs/tech-spec-epic-2.md#10-testing-strategy]
- Load testing ensures device registration endpoint handles 100 req/s without degradation. [Source: docs/tech-spec-epic-2.md#10-testing-strategy]
- Security testing validates telemetry payload signature if provided by SDK. [Source: docs/tech-spec-epic-2.md#5-security--compliance-considerations]

## Technical Constraints
- Trust score threshold configurable via `capability.minDeviceTrust`; default 0.7 for MVP. [Source: docs/tech-spec-epic-2.md#4-implementation-details-story-mapping]
- Device telemetry stored redacted for privacy before logging. [Source: docs/tech-spec-epic-2.md#5-security--compliance-considerations]
- Revocation must trigger immediate capability reassessment to avoid stale access. [Source: docs/tech-spec-epic-2.md#8-implementation-guide]

## Change Log
| Date       | Version | Description | Author |
| ---------- | ------- | ----------- | ------ |
| 2025-11-02 | v1.0    | New device trust capability story | Documentation Task Force |

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
