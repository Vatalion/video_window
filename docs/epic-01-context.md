# Epic 01 Context: Environment & CI/CD Setup

**Generated:** 2025-11-04  
**Epic ID:** 01  
**Epic Title:** Environment & CI/CD Setup  
**Status:** contexted

## Technical Foundation

### Architecture Decisions
- **Monorepo Structure:** Serverpod standard layout with Melos-managed Flutter workspace
- **Local Development:** Docker Compose for PostgreSQL 15+ and Redis 7.2.4+
- **Code Generation:** Serverpod CLI for backend, build_runner for Flutter packages
- **CI/CD:** GitHub Actions with quality gates (format, analyze, test)

### Technology Stack
- Flutter 3.35.4+ (min 3.19.6), Dart 3.9.2+ (min 3.5.6)
- Serverpod 2.9.x, PostgreSQL 15+, Redis 7.2.4+
- Melos for workspace management
- GitHub Actions for CI/CD automation

### Key Integration Points
- `video_window_server/` - Serverpod backend
- `video_window_client/` - Auto-generated API client (DO NOT EDIT)
- `video_window_shared/` - Auto-generated shared code (DO NOT EDIT)
- `video_window_flutter/` - Flutter app with Melos workspace

### Implementation Patterns
- **Code Generation:** Run `serverpod generate` after protocol changes
- **Workspace Management:** Run `melos run setup` for first-time bootstrap
- **Quality Gates:** Automated format/analyze/test on every PR
- **Secrets:** Environment-based configuration, never commit secrets

### Story Dependencies
1. **01.1:** Bootstrap repository structure (foundation)
2. **01.2:** Local development environment (depends on 01.1)
3. **01.3:** Code generation workflows (depends on 01.1, 01.2)
4. **01.4:** CI/CD pipeline (depends on all previous)

### Success Criteria
- Developer can clone, run `melos run setup`, and start app <10 minutes
- CI pipeline enforces quality gates on every PR
- Code generation works reliably for both Serverpod and Flutter
- Documentation is complete and validated

**Reference:** See `docs/tech-spec-epic-01.md` for full technical specification
