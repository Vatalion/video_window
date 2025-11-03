# Sprint 1 Plan: Foundation Infrastructure

**Sprint Duration:** 2 weeks (November 4-17, 2025)  
**Sprint Goal:** Establish technical foundation enabling all future epic development  
**Epic Focus:** Epic 01 (Environment & CI/CD)  
**Status:** ✅ APPROVED - Ready for Development

---

## Sprint Objective

Deliver a fully operational Serverpod + Flutter + Melos workspace with CI/CD infrastructure, enabling the team to begin Epic 1 (Authentication) development in Sprint 2.

### Success Criteria
1. ✅ All Epic 01 stories (01.1-01.4) meet Definition of Done
2. ✅ Developer can run `melos run setup` and have working environment in <10 minutes
3. ✅ CI/CD pipeline blocks merges on test/lint failures
4. ✅ Architecture documented and team onboarded
5. ✅ Epic 1 (Authentication) can start Sprint 2 with zero blockers

---

## Team Composition & Capacity

| Role | Agent | Availability | Capacity (Story Points) |
|------|-------|--------------|------------------------|
| Developer | Amelia | 100% | 13 SP |
| Architect | Winston | 50% (consulting) | Advisory |
| Scrum Master | Bob | 100% | Facilitation |
| Product Manager | John | 25% (review) | Acceptance |
| Business Analyst | Mary | 25% (validation) | Requirements support |

**Total Sprint Capacity:** 13 Story Points

---

## Sprint Backlog

### Epic 01: Environment & CI/CD (ALL 4 stories committed)

#### **Story 01.1: Bootstrap Repository and Flutter App** 
**Priority:** P0 - CRITICAL PATH  
**Estimate:** 5 SP  
**Status:** Committed  
**Assignee:** Amelia

**Description:** Scaffold Serverpod backend, Flutter client, and Melos workspace with initial testing infrastructure.

**Acceptance Criteria:**
1. Flutter project under `video_window_flutter/` with passing widget test and README
2. Serverpod backend scaffold with health endpoint documented for smoke tests
3. Root README with prerequisites, setup, and links to guardrail docs

**Key Dependencies:**
- NONE (foundational story)

**Implementation Sequence:**
- **Days 1-2:** Serverpod scaffold, Melos workspace config, package structure
- **Day 3:** BLoC architecture, routing setup, testing infrastructure
- **Day 4:** Documentation, CI/CD scripts, validation

**Technical Risks:**
- ⚠️ Serverpod 2.9.x configuration issues
- ⚠️ Melos package resolution across features
- ⚠️ Path dependencies between core/shared/features

**Mitigation:**
- Use `docs/frameworks/serverpod/` official guides (validated complete)
- Reference `project-structure-implementation.md` for canonical layout
- Winston available for architectural consultation

**Definition of Done Checklist:**
- [ ] All acceptance criteria met with evidence
- [ ] Unit tests pass (`melos run test:unit`)
- [ ] Widget tests pass (`melos run test:widget`)
- [ ] Code formatted (`melos run format`)
- [ ] Static analysis clean (`melos run analyze`)
- [ ] CI/CD pipeline passes
- [ ] Documentation updated (README, architecture docs)
- [ ] Code reviewed and approved
- [ ] Deployed to dev environment
- [ ] Product Owner acceptance obtained

---

#### **Story 01.2: CI/CD Pipeline Setup**
**Priority:** P0 - CRITICAL PATH  
**Estimate:** 3 SP  
**Status:** Committed  
**Assignee:** Amelia  
**Depends On:** 01.1 (workspace structure)

**Description:** Implement GitHub Actions workflows for automated testing, linting, and quality gates.

**Acceptance Criteria:**
1. PR checks run tests, linting, and formatting validation
2. Main branch deployment pipeline to dev environment
3. Quality gates documented and enforced

**Key Dependencies:**
- ✅ Story 01.1 complete (workspace structure exists)

**Implementation Sequence:**
- **Day 5:** GitHub Actions workflow files (.github/workflows/)
- **Day 6:** Quality gate configuration, branch protection, documentation

**Technical Risks:**
- ⚠️ GitHub Actions runner compatibility with Flutter/Serverpod
- ⚠️ Serverpod code generation in CI environment

**Mitigation:**
- Reference existing `.github/workflows/quality-gates.yml` structure
- Use official Flutter/Dart GitHub Actions
- Document Serverpod generation step in CI

---

#### **Story 01.3: Melos Workspace Scripts**
**Priority:** P1 - HIGH  
**Estimate:** 2 SP  
**Status:** Committed  
**Assignee:** Amelia  
**Depends On:** 01.1 (workspace structure)

**Description:** Configure Melos scripts for setup, generation, testing, and analysis across all packages.

**Acceptance Criteria:**
1. `melos run setup` installs all dependencies and runs codegen
2. `melos run generate` executes build_runner for Flutter packages
3. `melos run test` runs full test suite with coverage
4. `melos run analyze` and `melos run format` work across workspace

**Key Dependencies:**
- ✅ Story 01.1 complete (Melos workspace exists)

**Implementation Sequence:**
- **Day 7:** Melos script configuration in `melos.yaml`
- **Day 7:** Script validation and documentation

**Technical Risks:**
- ⚠️ Script execution order dependencies
- ⚠️ Cross-platform compatibility (macOS, Linux, Windows CI)

---

#### **Story 01.4: Developer Onboarding Documentation**
**Priority:** P1 - HIGH  
**Estimate:** 3 SP  
**Status:** Committed  
**Assignee:** Amelia  
**Depends On:** 01.1, 01.2, 01.3 complete

**Description:** Create comprehensive developer documentation for workspace setup, workflows, and conventions.

**Acceptance Criteria:**
1. Quick start guide gets new developer running in <10 minutes
2. Architecture documentation explains package structure and patterns
3. Troubleshooting guide covers common setup issues

**Key Dependencies:**
- ✅ Stories 01.1-01.3 complete (all infrastructure operational)

**Implementation Sequence:**
- **Day 8:** Documentation writing and validation
- **Day 9:** Fresh environment testing, refinements

---

## Story Sequencing & Timeline

```
Week 1 (Nov 4-8):
┌─────────────────────────────────────────────────────────┐
│ Days 1-4: Story 01.1 (Bootstrap) - CRITICAL PATH       │
│ Days 5-6: Story 01.2 (CI/CD)                           │
│ Day 7:    Story 01.3 (Melos Scripts)                   │
└─────────────────────────────────────────────────────────┘

Week 2 (Nov 11-15):
┌─────────────────────────────────────────────────────────┐
│ Days 8-9: Story 01.4 (Documentation)                   │
│ Day 10:   Sprint review, retrospective, demo prep      │
└─────────────────────────────────────────────────────────┘
```

**Critical Path:** 01.1 → 01.2 & 01.3 (parallel) → 01.4

---

## Sprint Ceremonies

### Daily Standup
- **Time:** 9:00 AM daily
- **Format:** Async updates in project channel
- **Focus:** Blockers, progress, help needed

### Mid-Sprint Check-in
- **Date:** Thursday, November 7 (Day 4)
- **Purpose:** Validate 01.1 completion, unblock 01.2/01.3
- **Attendees:** Amelia, Winston, Bob

### Sprint Review
- **Date:** Friday, November 15
- **Purpose:** Demo working workspace, validate acceptance criteria
- **Attendees:** Full team + stakeholders

### Sprint Retrospective
- **Date:** Friday, November 15 (after review)
- **Purpose:** Process improvement, Sprint 2 planning prep
- **Attendees:** Core team

---

## Risk Register

| Risk | Probability | Impact | Mitigation | Owner |
|------|-------------|--------|------------|-------|
| Serverpod 2.9.x config issues | Medium | High | Use official docs in `docs/frameworks/serverpod/`, Winston consulting | Amelia |
| Melos package resolution failures | Medium | High | Reference `project-structure-implementation.md`, incremental validation | Amelia |
| CI/CD environment differences | Low | Medium | Test on clean VM, document environment requirements | Amelia |
| Scope creep into Epic 02 | Low | Low | Bob enforces Sprint 1 boundary, Epic 02 explicitly excluded | Bob |
| Story 01.1 delays blocking others | Medium | Critical | Daily progress checks, Winston available for unblocking | Bob |

---

## Definition of Done (Sprint-Level)

### Code Quality
- [ ] All tests passing (unit, widget, integration)
- [ ] Code coverage ≥ 80% for new code
- [ ] No linting errors or warnings
- [ ] Code formatted per Dart conventions
- [ ] No commented-out code or TODO markers

### Documentation
- [ ] README updated with setup instructions
- [ ] Architecture docs reflect current structure
- [ ] API documentation generated and accessible
- [ ] Troubleshooting guide covers common issues

### Testing
- [ ] Smoke tests validate end-to-end setup
- [ ] CI/CD pipeline demonstrates green builds
- [ ] Fresh environment setup validated (<10 min)

### Deployment
- [ ] Changes merged to `main` branch
- [ ] Dev environment operational
- [ ] Workspace accessible to all team members

### Acceptance
- [ ] Product Owner approval obtained
- [ ] Sprint review demo successful
- [ ] Epic 1 unblocked for Sprint 2

---

## Sprint Backlog Refinement

### Epic 02 Stories (Backlog - NOT Sprint 1)
These stories are **refined and ready** but explicitly **excluded from Sprint 1 commitment**:

- **Story 02.1:** Capability Enablement Request Flow (Ready, 5 SP)
- **Story 02.2:** Verification Within Publish Flow (Ready, 3 SP)
- **Story 02.3:** Payout & Compliance Activation (Ready, 5 SP)
- **Story 02.4:** Device Trust & Risk Monitoring (Ready, 3 SP)

**Note:** Epic 02 is validated and approved but deferred to Sprint 2+ per capacity constraints.

---

## Technical Reference Documents

### Architecture
- `docs/architecture/tech-stack.md` - Technology decisions
- `docs/architecture/coding-standards.md` - Code conventions
- `docs/architecture/bloc-implementation-guide.md` - State management patterns
- `docs/architecture/project-structure-implementation.md` - Package structure

### Frameworks
- `docs/frameworks/serverpod/01-setup-installation.md`
- `docs/frameworks/serverpod/02-project-structure.md`
- `docs/frameworks/serverpod/03-code-generation.md`

### Process
- `docs/process/definition-of-ready.md` - Story readiness criteria
- `docs/process/definition-of-done.md` - Completion criteria
- `docs/process/story-approval-workflow.md` - Approval process

### Testing
- `docs/testing/master-test-strategy.md` - Testing approach

---

## Sprint Metrics & Goals

### Velocity Target
- **Committed:** 13 SP (Epic 01: 4 stories)
- **Stretch Goal:** None (focus on quality foundation)

### Quality Metrics
- Code coverage: ≥80%
- CI/CD pipeline: <5 min build time
- Setup time: <10 min for new developer
- Zero P0/P1 bugs in workspace setup

### Success Indicators
- ✅ All Epic 01 stories complete
- ✅ Team can demonstrate working workspace
- ✅ Epic 1 (Authentication) ready to start Sprint 2
- ✅ No technical debt carried forward

---

## Notes & Decisions

### Sprint Planning Decisions (November 3, 2025)
1. **Epic 02 Excluded:** Despite being validated/approved, Epic 02 deferred to maintain Sprint 1 focus on infrastructure
2. **Single Developer Sprint:** Amelia as sole implementer; Winston/Bob/John/Mary in supporting roles
3. **Quality Over Speed:** No stretch goals; prioritizing rock-solid foundation
4. **Documentation Critical:** Story 01.4 non-negotiable for team velocity in future sprints

### Key Architectural Decisions
1. **Serverpod-First:** Backend-driven with auto-generated client (no manual HTTP clients)
2. **Melos Workspace:** All Flutter packages managed via Melos monorepo
3. **BLoC Pattern:** Global state in app, feature state in feature packages
4. **No GetIt:** Constructor injection only, no service locator pattern

---

## Change Log

| Date | Version | Change | Author |
|------|---------|--------|--------|
| 2025-11-03 | v1.0 | Initial Sprint 1 plan created from party mode discussion | BMad Master + Team |

---

## Approvals

- [ ] **Product Owner (John):** Sprint goal and scope approved
- [ ] **Scrum Master (Bob):** Sprint commitment validated against capacity
- [ ] **Tech Lead (Winston):** Technical approach and sequencing approved
- [ ] **Developer (Amelia):** Story estimates and implementation plan accepted

---

**Sprint 1 Status:** ✅ PLANNING COMPLETE - Ready to Start November 4, 2025
