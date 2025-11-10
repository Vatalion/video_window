# Story 3-3: Privacy Settings & Controls

## Status
Ready for Dev

## Story
**As a** privacy-conscious viewer,
**I want** granular control over who can see my information and how my data is used,
**so that** I can manage compliance preferences and protect my personal data.

## Acceptance Criteria
1. Privacy settings page surfaces profile visibility, data sharing, tagging, search-by-phone, and marketing consent toggles with descriptive helper text. [Source: docs/tech-spec-epic-3.md#implementation-guide]
2. Saving privacy settings instantly updates server values and returns the effective configuration; UI confirms success and rolls back on failure. [Source: docs/tech-spec-epic-3.md#profile-management-flow]
3. `PrivacyManager` enforces visibility rules for public, friends-only, and private queries including blocked user lists. [Source: docs/tech-spec-epic-3.md#privacy-settings-entity]
4. **COMPLIANCE CRITICAL**: Consent changes generate audit log entries and emit analytics event `privacy_settings_changed`. [Source: docs/tech-spec-epic-3.md#analytics-events]
5. DSAR export/delete actions reference latest privacy settings and require explicit confirmation modal before proceeding. [Source: docs/tech-spec-epic-3.md#implementation-guide]

## Prerequisites
1. Story 3.1 – Viewer Profile Management
2. Epic 2 – RBAC enforcement in place for ownership validation.

## Tasks / Subtasks

### Flutter
- [ ] Create `privacy_settings_page.dart` with grouped toggles, inline learn-more links, and WCAG-compliant contrast. [Source: docs/tech-spec-epic-3.md#source-tree--file-directives]
- [ ] Build `privacy_toggle_tile.dart` widget for reusable switches + compliance copy. [Source: docs/tech-spec-epic-3.md#source-tree--file-directives]
- [ ] Extend `ProfileBloc` with `PrivacySettingsSubmitted` event and success/error states; connect to DSAR CTA. [Source: docs/tech-spec-epic-3.md#implementation-guide]

### Serverpod
- [ ] Implement `privacy_manager.dart` applying business rules for visibility, blocked users, and consent toggles. [Source: docs/tech-spec-epic-3.md#source-tree--file-directives]
- [ ] Update `profile_endpoint.dart` to persist privacy settings and emit audit log + segment event. [Source: docs/tech-spec-epic-3.md#implementation-guide]
- [ ] Add integration test `privacy_visiblity_enforcement_test.dart` ensuring correct data filtering. [Source: docs/tech-spec-epic-3.md#test-traceability]

### Analytics & Audit
- [ ] Emit `privacy_settings_changed` event with `setting_name`, `old_value`, `new_value`. [Source: docs/tech-spec-epic-3.md#analytics-events]
- [ ] Record audit entries in `privacy_audit_log` table (migration add) with actor, change summary, timestamp. [Source: docs/tech-spec-epic-3.md#security-monitoring]

## Data Models
- `user_privacy_settings` table fields align with toggles; add JSONB `audit_context` for metadata. [Source: docs/tech-spec-epic-3.md#database-migrations]

## API Specifications
- `GET/PUT /users/me/privacy-settings` exchange typed payloads defined in spec. [Source: docs/tech-spec-epic-3.md#profile-management-endpoints]

## Component Specifications
- Privacy filters executed in `privacy_manager.dart` with helper for `friendsOnly` access. [Source: docs/tech-spec-epic-3.md#privacy-settings-entity]

## File Locations
- Flutter UI components live under `packages/features/profile/lib/presentation/pages/` and `/widgets/`. [Source: docs/tech-spec-epic-3.md#source-tree--file-directives]
- Server logic resides in `video_window_server/lib/src/business/profile/privacy_manager.dart`. [Source: docs/tech-spec-epic-3.md#source-tree--file-directives]

## Testing Requirements
- Widget tests verifying toggle states, helper text, and rollback behavior.
- Repository tests confirming payload transformation to value objects.
- Integration tests covering privacy enforcement for `public`, `friendsOnly`, and `private` profiles.
- Audit log test ensuring every change writes correct metadata.

## Technical Constraints
- Toggle updates must respond within 400 ms (P95) to feel instantaneous. [Source: docs/tech-spec-epic-3.md#performance-considerations]
- Privacy defaults revert to most restrictive option when server unreachable. [Source: docs/tech-spec-epic-3.md#error-recovery]

## Change Log
| Date       | Version | Description                         | Author            |
| ---------- | ------- | ----------------------------------- | ----------------- |
| 2025-10-29 | v1.0    | Privacy controls story established  | GitHub Copilot AI |

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
