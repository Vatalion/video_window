# Epic 01: Environment & CI/CD Enablement - Technical Specification

**Epic ID:** 01  
**Epic Title:** Environment & CI/CD Enablement  
**Version:** 1.0  
**Status:** ✅ APPROVED  
**Created:** 2025-10-30  
**Last Updated:** 2025-11-01

---

## Overview

### Purpose
Establish a Flutter + Serverpod workspace with enforced guardrails enabling every contributor to ship confidently from day one. This epic creates the foundation for all subsequent development.

### Success Criteria
- Repository bootstrapped with Flutter app, Serverpod backend, and Melos monorepo
- CI/CD pipeline enforcing format, analyze, and test gates on every PR
- Story-based branching workflow automated and documented
- Secrets management and release channels hardened

### Dependencies
- **Prerequisites:** None - foundational epic
- **Blocks:** All other epics depend on this foundation

---

## Architecture & Design

### Technology Stack
- **Flutter:** 3.19.6 (Dart 3.5.6)
- **Serverpod:** 2.9.x
- **Melos:** Latest stable (monorepo management)
- **CI/CD:** GitHub Actions
- **Secrets:** GitHub Secrets / 1Password
- **Version Control:** Git with story-based branching

### Repository Structure
```
video_window/
├── .github/
│   └── workflows/
│       ├── flutter-ci.yml           # CI pipeline
│       └── quality-gates.yml        # Additional gates
├── video_window_server/             # Serverpod backend
├── video_window_client/             # Generated client
├── video_window_flutter/            # Flutter app (Melos root)
│   ├── melos.yaml                   # Melos configuration
│   └── packages/
│       ├── core/                    # Core functionality
│       ├── shared/                  # Shared components
│       └── features/                # Feature modules
├── video_window_shared/             # Shared models
├── scripts/
│   └── story-flow.sh                # Story workflow automation
└── docs/                            # Documentation
```

### CI/CD Pipeline Design
```yaml
Trigger: Push to any branch
├── Job 1: Flutter Format Check
│   └── dart format --set-exit-if-changed
├── Job 2: Flutter Analyze
│   └── flutter analyze --fatal-infos --fatal-warnings
├── Job 3: Flutter Test
│   └── flutter test --no-pub --coverage
└── Job 4: Serverpod Test
    └── cd video_window_server && dart test
```

---

## Implementation Guide

### Story 01.1: Bootstrap Repository and Flutter App
**Objective:** Create initial project structure

**Steps:**
1. Initialize Git repository
2. Run `serverpod create video_window`
3. Run `flutter create video_window_flutter`
4. Configure Melos workspace in `video_window_flutter/melos.yaml`
5. Add initial widget test and health endpoint
6. Create comprehensive README with setup instructions

**Verification:**
- `flutter test` passes in Flutter app
- Serverpod health endpoint responds
- Melos bootstrap completes successfully

### Story 01.2: Enforce Story Branching and Scripts
**Objective:** Automate story-based workflow

**Steps:**
1. Create `scripts/story-flow.sh` for branch automation
2. Document Conventional Commit format in CONTRIBUTING.md
3. Configure branch naming rules in GitHub
4. Add pre-commit hooks for commit message validation
5. Update sample story file with workflow examples

**Verification:**
- Script creates properly named branches
- Pre-commit hooks reject non-conforming commits
- GitHub enforces branch naming rules

### Story 01.3: Configure CI Format/Analyze/Test Gates
**Objective:** Automated quality gates

**Steps:**
1. Create `.github/workflows/flutter-ci.yml`
2. Pin Flutter 3.19.6 / Dart 3.5.6
3. Configure dependency caching
4. Add format check job
5. Add analyze job with fatal warnings
6. Add test job with coverage
7. Configure required status checks in GitHub

**Verification:**
- Pipeline runs on every push
- Format violations block merge
- Analyze warnings block merge
- Test failures block merge

### Story 01.4: Harden Secrets Management and Release Channels
**Objective:** Secure secrets and define release process

**Steps:**
1. Create `.env.example` with required keys
2. Document `--dart-define` usage in README
3. Configure GitHub Secrets for CI
4. Set up git-secrets or pre-commit hooks
5. Document release channel strategy
6. Create tagging convention documentation

**Verification:**
- Secrets never committed to repo
- CI can access required secrets
- Release process documented
- Pre-commit hooks catch secrets

---

## Data Models & API Contracts

### Environment Configuration
```dart
class EnvironmentConfig {
  final String apiBaseUrl;
  final String stripePublishableKey;
  final String analyticsKey;
  final bool enableDebugFeatures;
  
  // Loaded via --dart-define or .env
}
```

### Health Check Endpoint
```dart
// Serverpod endpoint
class HealthEndpoint extends Endpoint {
  Future<Map<String, dynamic>> check(Session session) async {
    return {
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'version': '0.1.0',
    };
  }
}
```

---

## Testing Strategy

### Story 01.1 Tests
- Widget test for Flutter app scaffold
- Health endpoint integration test
- Melos bootstrap validation

### Story 01.2 Tests
- Script execution tests
- Commit message validation tests
- Branch naming validation

### Story 01.3 Tests
- CI pipeline execution tests
- Format check validation
- Analyze rule validation
- Test coverage validation

### Story 01.4 Tests
- Secret detection tests
- Environment variable loading tests
- Release process validation

---

## Security Considerations

### Secrets Management
- Never commit secrets to repository
- Use GitHub Secrets for CI/CD
- Use 1Password or similar for team secrets
- Rotate secrets every 90 days (NFR1)
- Implement pre-commit hooks for secret detection

### Access Control
- Protect `main` and `develop` branches
- Require PR reviews before merge
- Enforce signed commits (optional)
- Limit repository access by role

---

## Deployment & Operations

### Local Development Setup
```bash
# 1. Clone repository
git clone <repo-url>
cd video_window

# 2. Install Melos
dart pub global activate melos

# 3. Bootstrap workspace
cd video_window_flutter
melos run setup

# 4. Run app
flutter run
```

### CI/CD Pipeline
- Runs on every push to any branch
- Required checks must pass before PR merge
- Caches dependencies for faster builds
- Generates test coverage reports

### Release Process
```
story/* → develop (via PR) → main (via PR) → tagged release
```

---

## Monitoring & Observability

### CI/CD Metrics
- Pipeline success/failure rates
- Average build time
- Test coverage trends
- Dependency vulnerability alerts

### Repository Health
- Branch count and staleness
- PR merge time metrics
- Commit frequency
- Contributor activity

---

## Source Tree & File Locations

### New Files Created
```
.github/workflows/flutter-ci.yml
scripts/story-flow.sh
.env.example
CONTRIBUTING.md
video_window_flutter/melos.yaml
video_window_flutter/test/widget_test.dart
video_window_server/lib/src/endpoints/health_endpoint.dart
```

### Modified Files
```
README.md (updated with setup instructions)
.gitignore (add .env, secrets)
```

---

## Migration & Rollout Strategy

### Phase 1: Initial Setup (Week 1)
- Story 01.1: Bootstrap repository
- Story 01.2: Setup branching workflow

### Phase 2: CI/CD (Week 1-2)
- Story 01.3: Configure quality gates
- Story 01.4: Harden secrets management

### Success Metrics
- All team members can run project locally
- CI pipeline green on develop branch
- Zero secrets in repository
- Documentation complete and accurate

---

## Future Enhancements

### Post-MVP Improvements
- Automated dependency updates (Dependabot)
- Performance benchmarking in CI
- Automated deployment to staging
- Code coverage badges
- Pre-release beta distribution

---

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Melos Documentation](https://melos.invertase.dev/)
- [Flutter CI/CD Best Practices](https://docs.flutter.dev/deployment/cd)
- [Serverpod Documentation](https://docs.serverpod.dev/)

---

## Change Log

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-10-30 | 1.0 | Initial tech spec created | Winston (Architect) |
| 2025-11-01 | 1.0 | Approved by all stakeholders, ready for Sprint 1 | BMad Team |

---

## Approval Signatures

**Technical Validation:**
- [x] Winston (Architect) - Approved 2025-11-01
- [x] Amelia (Dev Lead) - Approved 2025-11-01
- [x] Murat (Test Lead) - Approved 2025-11-01

**Business Approval:**
- [x] John (Product Manager) - Approved 2025-11-01

**Status:** ✅ APPROVED - READY FOR DEVELOPMENT  
**Approval Date:** 2025-11-01
