# Coding Standards & Conventions

## Flutter Client
- **State Management**: Use Riverpod for feature modules; avoid introducing new state libraries without architecture approval.
- **Folder Layout**: Group by feature (`lib/features/<feature>/`) with subfolders for `data`, `domain`, `presentation`, and `widgets`. Shared primitives remain under `lib/ui/`.
- **Theming**: Centralize colors, typography, and motion tokens in `lib/ui/theme/`; align with branding deliverables documented in the PRD.
- **Networking**: All API calls flow through generated Serverpod clients under `lib/api/`; keep manual `http` usage isolated to integration stubs.
- **Error Handling**: Surface domain failures using `AsyncValue` patterns, log errors via Sentry, and provide user-visible fallback messaging anchored in ACs.
- **Testing**: Every feature ships with widget tests covering primary flows and mocks for Serverpod clients. Golden tests ensure feed cards and detail pages respect accessibility contrast requirements.

## Backend Integration Contracts
- Track API schema changes in `docs/prd/assumptions.md` (future) and raise architecture review before breaking changes.
- Use JWT-based auth between Flutter client and Serverpod; refresh tokens stored securely via iOS Keychain.

## Security & Compliance
- Follow Stripe's PCI guidelines: sensitive data never logged, and tokens exchanged server-side.
- Mapbox keys stored via environment variables; never hard-code secrets in the repo.
- Enforce TLS 1.2+ end-to-end; monitor for man-in-the-middle vulnerabilities.

## Code Review Expectations
- All PRs include story references (e.g., `story/1.1`), pass `dart format`, `flutter analyze`, and `flutter test` before requesting review.
- Require at least one reviewer versed in feature area, plus QA sign-off for release branches.

## Documentation Links
- Requirements: [../prd.md](../prd.md)
- Story shards: [../prd/](../prd/)
- Story specs: [../stories/](../stories/)
- Workflow agreements: [development-workflow.md](development-workflow.md)
