# Story 1-4: Account Recovery (Email Only)

## Status
In Progress

## Story
**As a** viewer or maker who has lost access,
**I want** to recover my account using a secure email workflow,
**so that** I can regain access without contacting support.

## Acceptance Criteria
1. Recovery flow issues a one-time recovery token that expires in 15 minutes and can only be used once.
2. Recovery emails include device + location metadata and a “Not You?” link that revokes the token immediately.
3. Submitting a recovery token allows the user to re-authenticate and forces a passwordless login plus full session rotation.
4. Attempting to reuse or brute force recovery tokens locks the account for 30 minutes and alerts security monitoring.
5. Successful recovery must invalidate all active sessions and refresh tokens associated with the account.

## Prerequisites
1. Story 1.1 – Implement Email OTP Sign-In
2. Story 1.2 – Add Social Sign-In Options
3. Story 1.3 – Session Management & Refresh

## Dev Notes

### Previous Story Insights
- Build on OTP issuance patterns to deliver secure recovery tokens and leverage session rotation from Story 1.3 to enforce logout-all on recovery. [Source: docs/tech-spec-epic-1.md#implementation-guide]

### Data Models
- Recovery tokens stored in `recovery_tokens` table with hashed value, expiry, IP, and user agent. [Source: docs/tech-spec-epic-1.md#database-migrations]
- Tokens relate to users by foreign key and track first-use timestamp for auditable completion. [Source: docs/tech-spec-epic-1.md#security-implementation]

### API Specifications
- `POST /auth/recovery/send` triggers secure email dispatch with contextual metadata. [Source: docs/tech-spec-epic-1.md#authentication-endpoints]
- `POST /auth/recovery/verify` validates token and rotates sessions. [Source: docs/tech-spec-epic-1.md#serverpod-identity-service]

### Component Specifications
- Recovery entry point exposed from auth landing page with rate-limited button. [Source: docs/tech-spec-epic-1.md#source-tree--file-directives]
- Verification screen accepts token input and handles success/failure states with shared `ResultBanner` widget. [Source: docs/tech-spec-epic-1.md#implementation-details]
- Email templates live in `video_window_server/lib/src/services/email/templates/recovery_email.html` and include device/location metadata.

### File Locations
- Flutter recovery flow: `video_window_flutter/packages/features/auth/lib/presentation/pages/account_recovery_page.dart` (create).
- Recovery use case: `video_window_flutter/packages/features/auth/lib/use_cases/account_recovery_use_case.dart` (create).
- Server recovery service + endpoints: `video_window_server/lib/src/services/recovery_service.dart`, `video_window_server/lib/src/endpoints/identity/recovery_endpoint.dart`.
- Email template + localization strings under `video_window_server/assets/email/`.

### Testing Requirements
- Unit tests for recovery use case, email template rendering, and token validation.
- Integration tests for full recovery flow, brute force lockout, and revoke-all-sessions behaviour. [Source: docs/tech-spec-epic-1.md#testing-strategy]

### Technical Constraints
- Recovery tokens hashed with bcrypt and stored with per-user salt. [Source: docs/tech-spec-epic-1.md#security-implementation]
- Rate limiting: 3 recovery attempts per 24 hours per user, 10 per IP. [Source: docs/tech-spec-epic-1.md#security-implementation]
- Security alert emitted to `security.alerts` topic when lockout occurs.

### Project Structure Notes
- Keep recovery UI alongside other auth presentation pages; repository/service logic remains in core package to respect architecture layering. [Source: docs/tech-spec-epic-1.md#source-tree--file-directives]

## Tasks / Subtasks

1. **Create recovery token service** (AC: 1,4)
   - Generate hashed token + metadata and persist to Postgres.
   - Implement rate limiting + lockout logic on repeated failures.

2. **Implement recovery email dispatch** (AC: 2)
   - Build transactional email template with device/IP metadata and revocation link.
   - Integrate with SendGrid API v3.

3. **Build client recovery flow** (AC: 3)
   - Add recovery entry point + token entry screen.
   - Wire to recovery use case and handle success/failure states.

4. **Invalidate sessions on success** (AC: 5)
   - Revoke all refresh tokens + sessions for the user in Serverpod.
   - Clear secure storage on client and force re-authentication.

5. **Testing & analytics instrumentation** (All ACs)
   - Unit, widget, and integration tests.
   - Emit `auth_recovery_started`, `auth_recovery_completed`, and `auth_recovery_revoked` events.

## Testing

### Unit Tests
- `account_recovery_use_case_test.dart` validates happy path and failure responses.
- `recovery_service_test.dart` covers token hashing, expiry, and lockout logic.

### Integration Tests
- `integration/security/account_recovery_flow_test.dart` covers end-to-end recovery.
- `integration/security/account_recovery_lockout_test.dart` verifies brute force protection.

### Widget Tests
- `account_recovery_page_test.dart` covers UI states and navigation.

## Change Log
| Date | Version | Description | Author |
|------|---------|-------------|--------|
| 2025-10-29 | 1.0 | Initial story draft | Bob (Scrum Master) |

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
