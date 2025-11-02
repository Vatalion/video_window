# Story 01.1: Bootstrap Repository and Flutter App

## Status
Ready for Dev

## Story

**As a** developer,
**I want** the video marketplace repo scaffolded with the Flutter client, Serverpod backend, and shared tooling,
**so that** the team can run, test, and iterate against a consistent structure for the video content marketplace.

---

## Acceptance Criteria

1. Flutter project lives under `video_window` with a passing widget test and README quick-start commands
2. Serverpod backend scaffold (or placeholder stub) checked in with health endpoint documented for smoke tests
3. Root README captures prerequisites, local setup, and links to guardrail docs (`AGENTS.md`, story flow)

---

## Tasks / Subtasks

- [ ] **Restructure Project Directory** (AC: 1)
  - [ ] Lay out Serverpod's monorepo baseline with `video_window_flutter/`, `video_window_server/`, `video_window_client/`, and `video_window_shared/` folders under the root `video_window/` directory.
  - [ ] Inside `video_window_flutter/`, scaffold `packages/core`, `packages/shared`, and `packages/features/` so Melos can manage shared code and feature modules.
  - [ ] Configure `melos.yaml` to discover the new package paths and ensure path dependencies resolve across the workspace.
  - [ ] Refresh onboarding docs and the root README so the documented structure matches the Serverpod-first layout.

- [ ] **Scaffold Serverpod Backend Structure** (AC: 2)
  - [ ] Initialize `video_window_server/` via Serverpod CLI with baseline config, including `config/` and `lib/src/endpoints/` directories.
  - [ ] Add stub endpoint modules for identity, story, offers, payments, and orders under `video_window_server/lib/src/endpoints/`.
  - [ ] Implement the health endpoint and register it so smoke tests can call `/health` successfully.
  - [ ] Document PostgreSQL and Redis connection details alongside smoke-test instructions in the README or runbooks.

- [ ] **Implement Feature-First Architecture** (AC: 1)
  - [ ] Scaffold `video_window_flutter/lib/app_shell/` for bootstrap, routing, and theme configuration.
  - [ ] Stand up global BLoCs under `video_window_flutter/lib/presentation/bloc/` for app and auth state.
  - [ ] Create feature packages (`auth`, `timeline`, `commerce`, `publishing`) inside `video_window_flutter/packages/features/` with `use_cases/` and `presentation/` layers only.
  - [ ] Add shared design tokens and UI components in `video_window_flutter/packages/shared/` and wire them into the mobile app.

- [ ] **Add Testing Infrastructure** (AC: 1)
  - [ ] Add a smoke widget test for the Flutter app under `video_window_flutter/test/` to keep AC1 green.
  - [ ] Configure `melos run test` to execute package-level unit, widget, and integration tests consistently.
  - [ ] Create a Serverpod health integration test in `video_window_server/test/` that exercises the `/health` endpoint.
  - [ ] Provide coverage hooks or scripts (e.g., `melos run test:unit`, `melos run test:widget`) so future packages inherit the testing baseline.

- [ ] **Update Documentation and README** (AC: 3)
  - [ ] Refresh the root README with Melos-first setup steps and Serverpod prerequisites.
  - [ ] Add or update `docs/development.md` with workspace bootstrap (`melos run setup`) and codegen guidance (`serverpod generate`).
  - [ ] Ensure guardrail docs (e.g., `AGENTS.md`, story flow) link to the new structure and workflow.
  - [ ] Review ignore files so generated directories (`video_window_client/`, `video_window_shared/`) and local env files stay untracked.

- [ ] **Configure Development Environment** (AC: 1, 2)
  - [ ] Establish centralized lint rules via `analysis_options.yaml` shared across packages and Serverpod code.
  - [ ] Add Melos scripts for `format`, `analyze`, and `generate` that wrap Flutter and Serverpod tooling.
  - [ ] Verify Flutter 3.19.6 / Dart 3.5.6 compatibility across the workspace and document SDK pinning.
  - [ ] Provide helper scripts or tasks (e.g., VS Code tasks) for `melos run setup`, `melos run analyze`, and `melos run test` to streamline onboarding.

---

## Dev Notes

### Previous Story Insights
No previous stories - this is the foundational story for the project.

### Project Structure Requirements [Source: architecture/project-structure-implementation.md]
- Root workspace follows Serverpod's standard layout: `video_window_server/`, `video_window_client/`, `video_window_flutter/`, and `video_window_shared/` under `video_window/`.
- `video_window_flutter/` is the Melos workspace root with `packages/core/`, `packages/shared/`, and `packages/features/` (feature packages expose only `use_cases/` + `presentation/`).
- Generated artifacts (`video_window_client/`, `video_window_shared/`) are maintained by Serverpod codegen—never edit them manually.
- All data/repository code lives in `packages/core/`; feature packages depend on `core` + `shared` via path dependencies.

### Technical Architecture [Source: architecture/front-end-architecture.md]
- **State Management**: Global BLoCs in `video_window_flutter/lib/presentation/bloc/`; feature BLoCs in `video_window_flutter/packages/features/<feature>/lib/presentation/bloc/`.
- **Navigation**: GoRouter configuration lives in `video_window_flutter/lib/app_shell/router.dart` with capability-based guards that evaluate `canPublish`, `canCollectPayments`, and `canFulfillOrders`.
- **Directory Structure**:
  - `video_window_flutter/lib/app_shell/`: App bootstrap, router, theme, provider wiring.
  - `video_window_flutter/packages/shared/`: Design system, tokens, reusable widgets shared across features.
  - `video_window_flutter/packages/core/`: Data sources, repositories, value objects, and cross-cutting utilities.
  - `video_window_flutter/packages/features/<feature>/`: Feature boundary with `use_cases/` + `presentation/`; relies on core for data access.

### Coding Standards [Source: architecture/coding-standards.md]
- **Project Structure**: Feature packages live in `video_window_flutter/packages/features/<feature>/lib/{use_cases,presentation}` with data access centralized in `packages/core/`.
- **State Management**: Use BLoC for complex flows and StatefulWidget for lightweight UI state; no GetIt globals.
- **Testing**: Unit and integration tests required for new logic, executed via Melos scripts (`melos run test`, targeted package scripts).
- **Tooling**: Use workspace commands (`melos run format`, `melos run analyze`) which wrap `dart format --set-exit-if-changed`, `flutter analyze --fatal-infos`, and `flutter test --no-pub`.
- **Branch Naming**: `story/01.1-bootstrap-repository-and-flutter-app` format with conventional commits.

### Serverpod Requirements [Source: docs/prd.md - Technical Assumptions]
- **Version**: Serverpod 2.9.x with Postgres 15
- **Architecture**: Modular monolith with bounded contexts
- **Scheduling**: Built-in schedulers for auction/payment timers
- **Data Storage**: Redis for task queues, outbox pattern for webhooks

### File Locations and Structure
- **Flutter Workspace**: `video_window_flutter/` (Melos root) with primary app entry point in `lib/` and feature packages under `packages/`.
- **Serverpod Backend**: `video_window_server/` with endpoint modules in `lib/src/endpoints/` and configuration under `config/`.
- **Generated Client Code**: `video_window_client/` and `video_window_shared/` regenerated via `serverpod generate`—treated as read-only.
- **Tests**: Flutter tests under `video_window_flutter/test/` (mirroring lib structure) and Serverpod tests under `video_window_server/test/`.
- **Documentation**: Project-level docs remain in `docs/`, supplemented by workspace-specific READMEs inside `video_window_flutter/` and `video_window_server/`.

### Testing Standards [Source: architecture/coding-standards.md#Testing]
- **Unit Tests**: Required for all new logic under matching `test/` paths
- **Integration Tests**: Use Testcontainers for Postgres/Redis when touching persistence
- **Flutter Tests**: Golden tests required for core screens (Feed, Story, Offer, Checkout)
- **Mutation Tests**: Run smoke tests using `flutter test --no-pub` before merges
- **Test Organization**: Follow AAA pattern, place tests under matching source folder structure

---

## Testing

### Testing Requirements from Architecture
- **Test File Location**: Flutter tests live under `video_window_flutter/test/` (mirroring `lib/`) and package-level tests under each `packages/<name>/test/`; Serverpod tests live in `video_window_server/test/`.
- **Test Standards**: Follow AAA pattern (Arrange, Act, Assert) with melos scripts orchestrating runs (`melos run test`, `melos run test:unit`, etc.).
- **Testing Frameworks**:
  - Flutter test framework for unit, widget, and golden tests
  - Testcontainers or Dockerized Postgres/Redis for Serverpod integration coverage
  - Golden testing for core UI surfaces once the design system stabilizes
- **Specific Testing Requirements for 01.1**:
  - Basic widget smoke test for app initialization executed via `melos run test`
  - Serverpod health endpoint integration test invoked as part of the backend test suite
  - Verification that formatting and analysis commands (`melos run format`, `melos run analyze`) pass in CI

---

## Change Log

| Date       | Version | Description                           | Author |
| ---------- | ------- | ------------------------------------- | ------ |
| 2025-10-02 | v0.1    | Initial story draft created           | Bob (SM) |

---

## Dev Agent Record

### Agent Model Used
_(To be completed by Dev Agent)_

### Debug Log References
_(To be completed by Dev Agent)_

### Completion Notes List
_(To be completed by Dev Agent)_

### File List
_(To be completed by Dev Agent)_

---

## QA Results

_(To be completed by QA Agent)_
