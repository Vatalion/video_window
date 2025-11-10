# Story 3-5: Account Settings Management

## Status
Ready for Dev

## Story
**As a** viewer,
**I want** to manage sensitive account settings like DSAR requests, account deletion, and security preferences,
**so that** I maintain control over my personal data and compliance obligations.

## Acceptance Criteria
1. Account settings tab offers DSAR export, DSAR deletion, session revocation, and trusted device list management with confirmation dialogues. [Source: docs/tech-spec-epic-3.md#implementation-guide]
2. DSAR export generates downloadable package within 24 hours and surfaces status/progress in UI with polling. [Source: docs/tech-spec-epic-3.md#dsar-data-export]
3. Account deletion workflow anonymizes profile, revokes tokens, deletes media, and queues background cleanup while providing final confirmation screens. [Source: docs/tech-spec-epic-3.md#implementation-guide]
4. **SECURITY CRITICAL**: All DSAR and deletion actions require re-authentication (OTP) if last auth > 10 minutes. [Source: docs/tech-spec-epic-3.md#error-recovery]
5. Audit events recorded for DSAR export/deletion and account closure, notifying compliance team via `audit.profile` stream. [Source: docs/tech-spec-epic-3.md#security-monitoring]

## Prerequisites
1. Story 3.1 – Viewer Profile Management
2. Epic 2 – Device & session management infrastructure in place.

## Tasks / Subtasks

### Flutter
- [ ] Extend `profile_page.dart` with Account tab containing DSAR/closure actions and status banners. [Source: docs/tech-spec-epic-3.md#implementation-guide]
- [ ] Add OTP confirmation modal triggered before DSAR/deletion requests when session age criteria met. [Source: docs/tech-spec-epic-3.md#security--compliance-hardening]
- [ ] Implement polling for DSAR export status via `dsar_export_polling_cubit.dart`. [Source: docs/tech-spec-epic-3.md#implementation-guide]

### Serverpod
- [ ] Update `profile_endpoint.dart` with `/dsar/export`, `/dsar/delete`, and `/account/close` endpoints plus OTP validation hook. [Source: docs/tech-spec-epic-3.md#profile-management-endpoints]
- [ ] Implement `ProfileDSARService` orchestrating export packaging, storage, and retention policy. [Source: docs/tech-spec-epic-3.md#dsar-data-export]
- [ ] Ensure `deleteUserData` workflow cascades deletes across profile, privacy, notification, media, and sessions tables with audit logging. [Source: docs/tech-spec-epic-3.md#implementation-guide]

### Infrastructure & Compliance
- [ ] Configure retention job to purge DSAR export bundles after `DSAR_EXPORT_RETENTION_DAYS`. [Source: docs/tech-spec-epic-3.md#environment-variables]
- [ ] Wire audit stream to compliance Slack channel via AWS EventBridge rule `audit-profile-to-slack`. [Source: docs/tech-spec-epic-3.md#security-monitoring]

## Data Models
- `dsar_requests` table stores status, download URL, and audit metadata; update indexes for status + created_at. [Source: docs/tech-spec-epic-3.md#database-migrations]

## API Specifications
- `GET /users/me/dsar/export` initiates export; `DELETE /users/me/dsar/delete` handles closure. [Source: docs/tech-spec-epic-3.md#profile-management-endpoints]
- `DELETE /users/me/account` finalizes account deletion after OTP validation. [Source: docs/tech-spec-epic-3.md#implementation-guide]

## Component Specifications
- DSAR polling uses `ProfileDSARService` + background job to assemble ZIP stored in S3 signed URL. [Source: docs/tech-spec-epic-3.md#dsar-data-export]

## File Locations
- Flutter DSAR components in `packages/features/profile/lib/presentation/widgets/account/`. [Source: docs/tech-spec-epic-3.md#source-tree--file-directives]
- Serverpod services in `video_window_server/lib/src/services/profile_service.dart` and `.../profile/dsar_service.dart`. [Source: docs/tech-spec-epic-3.md#implementation-guide]

## Testing Requirements
- Unit: DSAR service packaging, OTP re-auth enforcement, deletion cascades.
- Widget: account tab flows, confirmation modals, status banners.
- Integration: full DSAR export + download, account deletion path including media cleanup.
- Security: ensure OTP requirement triggers correctly and failure logs audit event.

## Technical Constraints
- DSAR exports capped at 2 GB; split into multipart zip if larger. [Source: docs/tech-spec-epic-3.md#dsar-data-export]
- Account deletion finalizes within 15 minutes; progress updates surface to user. [Source: docs/tech-spec-epic-3.md#success-metrics]

## Change Log
| Date       | Version | Description                             | Author            |
| ---------- | ------- | --------------------------------------- | ----------------- |
| 2025-10-29 | v1.0    | Account settings & DSAR story completed | GitHub Copilot AI |

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
