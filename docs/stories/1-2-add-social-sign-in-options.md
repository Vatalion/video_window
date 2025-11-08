# Story 1-2: Add Social Sign-In Options

## Status
ready-for-dev

## Story
**As a** user,
**I want** to sign in using Google or Apple accounts,
**so that** I can authenticate quickly without email OTP

## Acceptance Criteria
1. Configure Apple Sign-In (iOS) and Google Sign-In (iOS/Android) per platform guidelines.
2. Serverpod reconciles social identities, preventing duplicate viewer accounts.
3. Fallback to email OTP if social auth fails, with analytics capturing drop-off.
4. **UNIFIED AUTH**: Uses same authentication flow as Story 1.1 - social auth creates/links accounts using same user model, with role differentiation (viewer/maker) happening post-signin.

## Prerequisites
1. Story 01.1 – Bootstrap Repository and Flutter App
2. Story 1.1 – Implement Email OTP Sign-In (shared auth services, secure storage patterns)
3. Serverpod identity module scaffolding (`video_window_server/lib/src/endpoints/identity/`)

## Dev Notes

### Previous Story Insights
From Story 1.1: Security patterns established for OTP, JWT tokens, rate limiting, and secure storage should be extended to social authentication flows. [Source: docs/stories/1.1.implement-email-sms-sign-in.md#dev-notes]

### Data Models
- User model should accommodate social identity linking (Apple ID, Google ID) alongside email identities. [Source: docs/tech-spec-epic-1.md#user-entity]
- Social authentication tokens need temporary storage with same security patterns as JWT tokens. [Source: docs/tech-spec-epic-1.md#session-entity]
- Account reconciliation logic to prevent duplicate viewer accounts when same email used across social providers. [Source: docs/tech-spec-epic-1.md#implementation-details]

### API Specifications
- Social authentication endpoints in Serverpod for Apple Sign-In token validation. [Source: docs/tech-spec-epic-1.md#authentication-endpoints]
- Google Sign-In token validation endpoint. [Source: docs/tech-spec-epic-1.md#authentication-endpoints]
- Account reconciliation endpoint to merge/link social identities with existing accounts. [Source: docs/tech-spec-epic-1.md#serverpod-identity-service]
- Fallback authentication endpoint to switch to email OTP flow. [Source: docs/tech-spec-epic-1.md#implementation-guide]

### Component Specifications
- Social sign-in buttons follow design system tokens from `design_system/`. [Source: docs/tech-spec-epic-1.md#implementation-guide]
- Sign-in flow orchestration uses BLoC for complex flows and StatefulWidget for simple UI state. [Source: docs/tech-spec-epic-1.md#implementation-details]
- Error handling for social auth failures uses shared `ErrorView` components. [Source: docs/tech-spec-epic-1.md#error-handling]

### File Locations
- Social auth UI components live under `video_window_flutter/packages/features/auth/lib/presentation/widgets/social_sign_in/`
- Feature BLoCs and flow orchestration belong in `video_window_flutter/packages/features/auth/lib/presentation/bloc/`
- Feature use cases are defined under `video_window_flutter/packages/features/auth/lib/use_cases/`
- Data access and provider integrations must reside in `video_window_flutter/packages/core/lib/data/services/auth/`
- Serverpod identity endpoints live in `video_window_server/lib/src/endpoints/identity/`

### Testing Requirements
- Unit tests for social auth token validation and account reconciliation logic
- Integration tests for Apple Sign-In and Google Sign-In flows (mocked)
- Widget tests for social sign-in UI components
- Maintain ≥80% coverage following testing strategy [Source: architecture/coding-standards.md#api-calls]

### Technical Constraints
- Apple Sign-In requires iOS platform-specific implementation following Apple Human Interface Guidelines
- Google Sign-In requires Google Sign-In SDK integration for both iOS and Android
- Social auth tokens must follow same security patterns as JWT tokens (RS256, 15-minute expiry) [Source: docs/stories/1.1.implement-email-sms-sign-in.md#technical-constraints]
- Account reconciliation must handle edge cases: same email across providers, provider account changes, etc.
- Analytics tracking for social auth success/failure/drop-off rates
- Rate limiting should extend to social auth attempts to prevent abuse

### Project Structure Notes
- Social authentication components align with the melos-managed feature package at `video_window_flutter/packages/features/auth/`. [Source: architecture/coding-standards.md#flutter-client]
- No deviations identified from the current monorepo structure rooted in `video_window_flutter/`. [Source: architecture/architecture.md#source-tree]

## Tasks / Subtasks

1. **Set up social authentication dependencies** (AC: 1)
   - Add Apple Sign-In SDK to iOS project configuration
   - Add Google Sign-In SDK to both iOS and Android projects
   - Configure Firebase/Google Console for social auth

2. **Create social authentication UI components** (AC: 1)
   - Design social sign-in buttons following design system tokens
   - Implement social sign-in flow screens
   - Add loading states and error handling for social auth attempts

3. **Implement Apple Sign-In integration** (AC: 1)
   - Create Apple Sign-In BLoC for complex authentication flow
   - Handle Apple Sign-In token response
   - Implement Apple ID validation flow

4. **Implement Google Sign-In integration** (AC: 1)
   - Create Google Sign-In BLoC for complex authentication flow
   - Handle Google Sign-In token response
   - Implement Google ID validation flow

5. **Build Serverpod social auth endpoints** (AC: 2)
   - Create Apple Sign-In token validation endpoint
   - Create Google Sign-In token validation endpoint
   - Implement account reconciliation logic to prevent duplicates

6. **Implement fallback authentication flow** (AC: 3)
   - Create seamless transition from social auth failure to email OTP
   - Add analytics tracking for social auth drop-off points
   - Implement retry logic for social auth failures

7. **Add comprehensive testing** (All ACs)
   - Unit tests for social auth providers and services
   - Widget tests for social sign-in UI components
   - Integration tests for complete social auth flows
   - Mock social auth responses for consistent testing

8. **Update navigation and routing** (All ACs)
   - Add social auth routes to router configuration
   - Implement deep linking for social auth callbacks
   - Update auth flow state management

## Testing

### Unit Tests
- Test Apple Sign-In token validation and error handling
- Test Google Sign-In token validation and error handling
- Test account reconciliation logic for duplicate prevention
- Test fallback authentication flow triggering
- Test analytics tracking for social auth events

### Integration Tests
- Test complete Apple Sign-In flow (mocked)
- Test complete Google Sign-In flow (mocked)
- Test social auth to email OTP fallback flow
- Test account reconciliation scenarios

### Widget Tests
- Test social sign-in button interactions and states
- Test loading and error state UI components
- Test social sign-in screen navigation and flow

## QA Results

### Review Date: 2025-10-04

### Reviewed By: Quinn (Test Architect)

### Code Quality Assessment

**Excellent story preparation with comprehensive technical guidance.** The story demonstrates strong alignment with established patterns from Story 1.1, provides clear security requirements, and includes a thorough testing strategy. The account reconciliation complexity is well-addressed with proper technical constraints and edge case considerations.

### Refactoring Performed

No refactoring required - story is in draft phase and well-structured.

### Compliance Check

- Coding Standards: ✓ Aligns with feature-first structure and BLoC patterns
- Project Structure: ✓ Follows documented monorepo architecture
- Testing Strategy: ✓ Comprehensive unit, integration, and widget test coverage
- All ACs Met: ✓ Clear mapping from acceptance criteria to implementation tasks

### Improvements Checklist

All story preparation elements are comprehensive and well-defined:

- [x] Security patterns properly inherited from Story 1.1
- [x] Account reconciliation logic clearly specified
- [x] Social auth SDK integration requirements detailed
- [x] Fallback authentication flow designed
- [x] Analytics tracking for drop-off analysis included
- [x] Rate limiting extended to social auth attempts

### Security Review

**SECURITY PASS:** Story properly inherits critical security patterns from Story 1.1:
- JWT token handling with RS256 encryption and 15-minute expiry
- Rate limiting for social auth attempts to prevent abuse
- Secure storage patterns for social auth tokens
- Account reconciliation logic to prevent duplicate accounts
- Comprehensive error handling without information leakage

### Performance Considerations

**PERFORMANCE PASS:** Optimized approach with:
- Native social auth SDKs for optimal mobile performance
- Appropriate loading states and error handling
- Fallback flow designed for minimal user friction
- Analytics tracking designed to be non-blocking

### Files Modified During Review

None (story in draft phase)

### Gate Status

Gate: PASS → docs/qa/gates/1.2-add-social-sign-in-options.yml
Risk profile: Not applicable (pre-implementation)
NFR assessment: Integrated into this review

### Recommended Status

✓ Ready for Development (comprehensive story preparation)

## Change Log

| Date | Version | Description | Author |
|------|---------|-------------|--------|
| 2025-10-04 | 1.0 | Initial story draft | BMad Scrum Master |
| 2025-10-04 | 1.1 | QA review completed - PASS | Quinn (Test Architect) |

## Dev Agent Record

### Context Reference

- `docs/stories/1-2-add-social-sign-in-options.context.xml`

### Agent Model Used

<!-- Will be populated during dev-story execution -->

### Debug Log References

<!-- Will be populated during dev-story execution -->

### Completion Notes List

<!-- Will be populated during dev-story execution -->

### File List

<!-- Will be populated during dev-story execution -->
