# Story 3-4: Notification Preferences Matrix

## Status
Ready for Dev

## Story
**As a** viewer,
**I want** to configure which channels and frequencies I receive platform notifications,
**so that** I stay informed without being overwhelmed.

## Acceptance Criteria
1. Notification preferences page renders matrix of notification types (offers, bids, orders, maker activity, security alerts) across email, push, and in-app channels with per-channel toggles. [Source: docs/tech-spec-epic-3.md#implementation-guide]
2. Quiet hours editor lets users define daily start/end times (local timezone) and disables push/email delivery during that window. [Source: docs/tech-spec-epic-3.md#notification-preferences-entity]
3. Preferences persist via `notification_manager.dart`, update Firebase topics, and sync to SendGrid suppression groups. [Source: docs/tech-spec-epic-3.md#source-tree--file-directives]
4. **SECURITY CRITICAL**: Critical security alerts ignore quiet hours and cannot be disabled; UI communicates constraint. [Source: docs/tech-spec-epic-3.md#security-monitoring]
5. Analytics event `notification_preferences_updated` fires with channel + frequency metadata, and audit trail stored. [Source: docs/tech-spec-epic-3.md#analytics-events]

## Prerequisites
1. Story 3.1 – Viewer Profile Management
2. Story 3.3 – Privacy Settings & Controls (to align consent toggles)

## Tasks / Subtasks

### Flutter
- [ ] Create `notification_preferences_page.dart` with tabular layout, quiet hours modal, and validation messaging. [Source: docs/tech-spec-epic-3.md#source-tree--file-directives]
- [ ] Build `notification_channel_row.dart` widget to render per-type channel toggles. [Source: docs/tech-spec-epic-3.md#source-tree--file-directives]
- [ ] Update `ProfileBloc` to handle `NotificationSettingsSubmitted` event and propagate success/failure states. [Source: docs/tech-spec-epic-3.md#implementation-guide]

### Serverpod
- [ ] Implement `notification_manager.dart` to persist preferences, manage quiet hours, and call Firebase/SendGrid integrations. [Source: docs/tech-spec-epic-3.md#source-tree--file-directives]
- [ ] Extend `profile_endpoint.dart` with `/notification-preferences` routes and enforce critical alert immutability. [Source: docs/tech-spec-epic-3.md#implementation-guide]
- [ ] Add integration test `notification_preferences_sync_test.dart` ensuring external services update correctly.

### Infrastructure
- [ ] Configure Firebase Cloud Messaging topics per notification type; ensure device tokens stored with opt-in flags. [Source: docs/tech-spec-epic-3.md#technology-stack]
- [ ] Map SendGrid categories to notification types and update suppression group IDs in configuration. [Source: docs/tech-spec-epic-3.md#email--notifications]

## Data Models
- `user_notification_preferences.settings` JSONB contains per-type channel toggles; update schema migration to document expected keys. [Source: docs/tech-spec-epic-3.md#notification-preferences-entity]

## API Specifications
- `GET/PUT /users/me/notification-preferences` manage matrix payloads; quiet hours persisted as `{ start: "22:00", end: "07:00" }`. [Source: docs/tech-spec-epic-3.md#profile-management-endpoints]

## Component Specifications
- Quiet hours enforcement resides in `notification_manager.dart` with timezone-aware schedule conversions. [Source: docs/tech-spec-epic-3.md#implementation-guide]

## File Locations
- Flutter widgets live under `packages/features/profile/lib/presentation/pages/notification_preferences_page.dart` and `/widgets/notification_channel_row.dart`. [Source: docs/tech-spec-epic-3.md#source-tree--file-directives]
- Server logic in `video_window_server/lib/src/business/profile/notification_manager.dart` plus tests in `/test/business/profile/`. [Source: docs/tech-spec-epic-3.md#source-tree--file-directives]

## Testing Requirements
- Widget: matrix renders toggles correctly, quiet hours validation, accessibility audit.
- Unit: notification manager merges updates without clobbering defaults; quiet hours conversions tested.
- Integration: ensure Firebase topic subscription and SendGrid suppression updates fire on preference changes.

## Technical Constraints
- Quiet hours must convert to UTC accurately and respect DST changes. [Source: docs/tech-spec-epic-3.md#implementation-guide]
- Save latency ≤ 500 ms P95; failure surfaces actionable toast.

## Change Log
| Date       | Version | Description                              | Author            |
| ---------- | ------- | ---------------------------------------- | ----------------- |
| 2025-10-29 | v1.0    | Notification preferences story authored  | GitHub Copilot AI |

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
