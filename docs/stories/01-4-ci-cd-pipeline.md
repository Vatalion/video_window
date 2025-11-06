# Story 01.4: CI/CD Pipeline

## Status
Ready for Development

## Story

**As a** development team,
**I want** automated CI/CD pipelines with quality gates,
**so that** code quality is enforced, tests run automatically, and deployments are streamlined.

---

## Acceptance Criteria

1. **AC1:** GitHub Actions workflow runs on every PR and push to main/develop branches
2. **AC2:** Quality gates (format, analyze, test) all pass before merge allowed
3. **AC3:** Test coverage reported and enforced (≥80% threshold)
4. **AC4:** Failed checks block PR merge via branch protection rules
5. **AC5:** Deployment pipeline documented with runbook

---

## Tasks / Subtasks

- [ ] **Task 1: Create GitHub Actions Quality Gates Workflow** (AC: 1, 2)
  - [ ] Subtask 1.1: Create `.github/workflows/quality-gates.yml` with triggers for PR and push events
  - [ ] Subtask 1.2: Add format-check job using `melos run format-check` with failure on changes needed
  - [ ] Subtask 1.3: Add analyze job using `melos run analyze` with fatal-infos enabled
  - [ ] Subtask 1.4: Configure job dependencies so analyze runs after format-check passes

- [ ] **Task 2: Implement Comprehensive Test Suite Jobs** (AC: 2, 3)
  - [ ] Subtask 2.1: Add unit test job running `melos run test:unit` with coverage collection
  - [ ] Subtask 2.2: Add widget test job running `melos run test:widget` 
  - [ ] Subtask 2.3: Add integration test job running `melos run test:integration`
  - [ ] Subtask 2.4: Upload coverage reports to Codecov with ≥80% threshold check
  - [ ] Subtask 2.5: Configure tests to run in parallel where possible for faster feedback

- [ ] **Task 3: Add Serverpod Backend Testing** (AC: 2)
  - [ ] Subtask 3.1: Create serverpod-tests job with PostgreSQL and Redis service containers
  - [ ] Subtask 3.2: Run `serverpod generate` to ensure generated code is current
  - [ ] Subtask 3.3: Execute Serverpod test suite with `dart test` in video_window_server
  - [ ] Subtask 3.4: Verify health endpoint and database migrations run successfully

- [ ] **Task 4: Configure Branch Protection Rules** (AC: 4)
  - [ ] Subtask 4.1: Document branch protection settings for main and develop branches
  - [ ] Subtask 4.2: Require all quality gate jobs to pass before merge
  - [ ] Subtask 4.3: Enable "Require branches to be up to date before merging"
  - [ ] Subtask 4.4: Test that PRs with failing checks cannot be merged

- [ ] **Task 5: Add Code Generation Validation** (AC: 2)
  - [ ] Subtask 5.1: Run `serverpod generate` and `melos run generate` in workflow
  - [ ] Subtask 5.2: Check git diff to ensure no generated code is stale
  - [ ] Subtask 5.3: Fail build if generated code needs to be committed
  - [ ] Subtask 5.4: Provide clear error message with instructions to regenerate locally

- [ ] **Task 6: Create Deployment Pipeline Documentation** (AC: 5)
  - [ ] Subtask 6.1: Document CI/CD workflow structure and job dependencies
  - [ ] Subtask 6.2: Create runbook for deployment process (staging and production)
  - [ ] Subtask 6.3: Document secrets and environment variables needed
  - [ ] Subtask 6.4: Add troubleshooting guide for common CI failures
  - [ ] Subtask 6.5: Update root README with links to CI/CD documentation

- [ ] **Task 7: Optimize Workflow Performance** (AC: 1)
  - [ ] Subtask 7.1: Enable caching for Flutter SDK and pub dependencies
  - [ ] Subtask 7.2: Configure appropriate timeouts for each job (15-30 minutes)
  - [ ] Subtask 7.3: Use matrix strategy for running tests across multiple package scopes if needed
  - [ ] Subtask 7.4: Verify total workflow time is under 20 minutes for fast feedback

---

## Dev Notes

### Epic Context [Source: docs/tech-spec-epic-01.md]
This story completes Epic 01 by establishing automated quality gates and deployment processes. The CI/CD pipeline builds on the repository structure (01.1), local environment (01.2), and code generation workflows (01.3) to provide continuous validation of code quality.

### Existing Implementation
- **Quality gates workflow already exists:** `.github/workflows/quality-gates.yml` with comprehensive jobs
- **Current coverage:** Format checks, static analysis, unit/widget/integration tests, golden tests, performance tests
- **Serverpod integration:** Backend tests with PostgreSQL and Redis service containers
- **Code generation validation:** Checks for stale generated code

### Technical Requirements [Source: docs/tech-spec-epic-01.md#CI/CD Pipeline]
- **Flutter Version:** 3.35.4+ (minimum 3.19.6)
- **Dart Version:** 3.9.2+ (minimum 3.5.6)
- **Test Coverage:** ≥80% overall, ≥95% for critical paths
- **Quality Tools:** Melos for workspace management, dart format, flutter analyze
- **Database Testing:** Use PostgreSQL 15 and Redis 7.2.4 service containers

### Melos Scripts Referenced
- `melos run deps` - Install all dependencies
- `melos run generate` - Run code generation across packages
- `melos run format-check` - Check code formatting without modifying files
- `melos run analyze` - Run static analysis with fatal-infos
- `melos run test:unit` - Execute unit tests with coverage
- `melos run test:widget` - Execute widget tests
- `melos run test:integration` - Execute integration tests
- `melos run test:coverage:check` - Validate coverage meets threshold

### Branch Protection Strategy
- **Protected Branches:** main, develop, release/*
- **Required Checks:** All quality gate jobs must pass
- **Review Requirements:** At least 1 approval for main branch
- **Status Checks:** Enforce branch is up-to-date before merge

### File Locations
- **Workflow Definition:** `.github/workflows/quality-gates.yml`
- **Melos Configuration:** `video_window_flutter/melos.yaml`
- **Documentation:** `docs/runbooks/ci-cd-pipeline.md` (to be created)
- **Scripts:** `scripts/validate-docs.sh` (referenced in workflow)

### Testing Standards [Source: docs/testing/master-test-strategy.md]
- **Unit Tests:** Required for all business logic, ≥80% coverage
- **Widget Tests:** Required for UI components
- **Integration Tests:** Required for API and feature interactions
- **Coverage Reporting:** Upload to Codecov, enforce minimum thresholds
- **Test Organization:** Follow AAA pattern, mirror source structure

---

## Definition of Done
- [ ] All acceptance criteria met
- [ ] GitHub Actions workflow operational and passing
- [ ] Test coverage ≥80% enforced via Codecov
- [ ] Branch protection rules configured and tested
- [ ] CI/CD documentation complete and reviewed
- [ ] All quality gates pass on clean PR
- [ ] Workflow performance optimized (< 20 minutes total)

## Dev Agent Record

### Context Reference

<!-- Path(s) to story context XML will be added here by context workflow -->

### Agent Model Used

<!-- Will be populated during dev-story execution -->

### Debug Log References

<!-- Will be populated during dev-story execution -->

### Completion Notes List

<!-- Will be populated during dev-story execution -->

### File List

<!-- Will be populated during dev-story execution -->

## Change Log

| Date | Version | Description | Author |
|------|---------|-------------|--------|
| 2025-11-06 | v0.1 | Initial story creation | Bob (SM) |
