# Sprint 1 Plan - Foundation Epic

**Sprint:** 1  
**Duration:** 2 weeks (Nov 4 - Nov 15, 2025)  
**Status:** READY TO START  
**Created:** 2025-11-01

---

## Sprint Goal

**Establish production-ready Flutter + Serverpod workspace with CI/CD pipeline and story-based workflow automation, enabling all team members to develop, test, and ship features confidently from day one.**

---

## Sprint Commitment

### Epic 01: Environment & CI/CD Enablement
**Total Story Points:** 13

| Story | Title | Points | Priority | Assignee |
|-------|-------|--------|----------|----------|
| 01.1 | Bootstrap Repository and Flutter App | 5 | P0 | TBD |
| 01.2 | Enforce Story Branching and Scripts | 2 | P0 | TBD |
| 01.3 | Configure CI Format/Analyze/Test Gates | 3 | P0 | TBD |
| 01.4 | Harden Secrets Management and Release Channels | 3 | P0 | TBD |

---

## Sprint Objectives

### Primary Objectives (Must Complete)
1. ✅ **Repository Structure:** Complete Serverpod + Flutter + Melos workspace setup
2. ✅ **CI/CD Pipeline:** Automated quality gates running on every PR
3. ✅ **Story Workflow:** Branching and commit conventions enforced
4. ✅ **Security:** Secrets management hardened with pre-commit hooks

### Secondary Objectives (Nice to Have)
- Developer onboarding documentation complete
- VS Code tasks configured for common operations
- Initial tech debt tracking established

---

## Team Capacity

**Sprint Capacity:** TBD (to be determined during Sprint Planning)

**Team Members:**
- **Dev Lead (Amelia):** Full-time (10 story points capacity)
- **Additional Developers:** TBD during Sprint Planning

**Availability Notes:**
- No planned PTO
- No major holidays (US: Veterans Day Nov 11 - federal holiday)

---

## Story Details

### Story 01.1: Bootstrap Repository and Flutter App (5 pts)

**Dependencies:** None - foundational

**Acceptance Criteria:**
1. Flutter project under `video_window` with passing widget test and README
2. Serverpod backend with health endpoint documented
3. Root README with prerequisites, setup, and guardrail docs

**Key Tasks:**
- Restructure project directory (Serverpod monorepo baseline)
- Scaffold Serverpod backend structure
- Implement feature-first architecture
- Add testing infrastructure
- Update documentation and README
- Configure development environment

**Definition of Done:**
- [ ] All acceptance criteria verified
- [ ] Unit tests passing (≥80% coverage)
- [ ] Code reviewed and approved
- [ ] Documentation updated
- [ ] CI pipeline green

---

### Story 01.2: Enforce Story Branching and Scripts (2 pts)

**Dependencies:** 01.1 complete

**Acceptance Criteria:**
1. `scripts/story-flow.sh` creates properly named branches
2. Pre-commit hooks reject non-conforming commits
3. GitHub enforces branch naming rules

**Key Tasks:**
- Create story-flow.sh script
- Document Conventional Commit format
- Configure GitHub branch rules
- Add pre-commit hooks
- Update sample story files

**Definition of Done:**
- [ ] Script tested and working
- [ ] Pre-commit hooks enforcing rules
- [ ] Documentation complete
- [ ] Team trained on workflow

---

### Story 01.3: Configure CI Format/Analyze/Test Gates (3 pts)

**Dependencies:** 01.1 complete

**Acceptance Criteria:**
1. Pipeline runs on every push
2. Format violations block merge
3. Analyze warnings block merge
4. Test failures block merge

**Key Tasks:**
- Create `.github/workflows/flutter-ci.yml`
- Pin Flutter 3.19.6 / Dart 3.5.6
- Configure dependency caching
- Add format/analyze/test jobs
- Configure required status checks

**Definition of Done:**
- [ ] CI pipeline running automatically
- [ ] All quality gates enforced
- [ ] Performance acceptable (<5 min builds)
- [ ] Documentation updated

---

### Story 01.4: Harden Secrets Management and Release Channels (3 pts)

**Dependencies:** 01.1 complete

**Acceptance Criteria:**
1. Secrets never committed to repo
2. CI can access required secrets
3. Release process documented
4. Pre-commit hooks catch secrets

**Key Tasks:**
- Create `.env.example`
- Document `--dart-define` usage
- Configure GitHub Secrets
- Set up git-secrets hooks
- Document release channel strategy

**Definition of Done:**
- [ ] No secrets in repository (verified)
- [ ] CI secrets configured and working
- [ ] Release process documented
- [ ] Team trained on secrets management

---

## Sprint Schedule

### Week 1 (Nov 4-8)
**Monday (Nov 4):**
- 9:00 AM - Sprint Planning Meeting
- 10:00 AM - Story 01.1 kickoff
- Development begins

**Tuesday-Friday:**
- Daily standups at 9:30 AM
- Story 01.1 implementation
- Story 01.2 preparation

**Friday (Nov 8):**
- Story 01.1 completion target
- Sprint mid-point review

### Week 2 (Nov 11-15)
**Monday (Nov 11):**
- **Veterans Day (US Federal Holiday)**
- Reduced capacity expected

**Tuesday-Thursday:**
- Story 01.2, 01.3, 01.4 parallel work
- Integration testing
- Documentation finalization

**Friday (Nov 15):**
- 2:00 PM - Sprint Review (demo to stakeholders)
- 3:00 PM - Sprint Retrospective
- 4:00 PM - Sprint 2 Planning (optional preview)

---

## Definition of Done (Sprint Level)

### Code Quality
- [ ] All stories meet individual DoD criteria
- [ ] Code review completed for all changes
- [ ] No critical or high-severity bugs introduced
- [ ] Technical debt documented and tracked

### Testing
- [ ] All unit tests passing (≥80% coverage)
- [ ] Integration tests passing
- [ ] CI pipeline green on main branch
- [ ] Manual testing completed for key workflows

### Documentation
- [ ] README updated with setup instructions
- [ ] Architecture docs updated
- [ ] API documentation current
- [ ] Runbooks created for operational tasks

### Deployment Readiness
- [ ] All secrets properly configured
- [ ] CI/CD pipeline operational
- [ ] Development environment reproducible
- [ ] Team can run project locally

---

## Risks & Mitigation

### Risk 1: Serverpod Integration Complexity
**Probability:** Medium  
**Impact:** High  
**Mitigation:** 
- Serverpod integration guides already created (6 docs)
- Architecture team available for pairing
- Time buffer built into Story 01.1 estimate

### Risk 2: Veterans Day Holiday Impact
**Probability:** High  
**Impact:** Low  
**Mitigation:**
- Critical work scheduled before Nov 11
- Stories 01.2-01.4 can proceed with reduced capacity
- No hard dependencies on single developer

### Risk 3: CI/CD Pipeline Configuration Issues
**Probability:** Low  
**Impact:** Medium  
**Mitigation:**
- GitHub Actions well-documented
- Similar pipelines exist in team's experience
- Can leverage community templates

---

## Success Criteria

### Sprint Success (Must Achieve)
- ✅ All 4 stories completed and meet DoD
- ✅ CI pipeline enforcing quality gates
- ✅ Team can develop features in Sprint 2
- ✅ Zero secrets in repository

### Sprint Excellence (Stretch Goals)
- Developer onboarding time <2 hours
- CI build time <3 minutes
- 100% team confidence in workflow
- Positive retrospective feedback

---

## Stakeholder Communication

### Sprint Review Attendees
- John (Product Manager) - Required
- Winston (Architect) - Required
- Murat (Test Lead) - Required
- Bob (Scrum Master) - Required
- Development Team - Required

### Sprint Review Agenda (Nov 15, 2:00 PM)
1. Sprint goal review (5 min)
2. Story demonstrations (25 min):
   - 01.1: Repository structure walkthrough
   - 01.2: Story workflow demonstration
   - 01.3: CI pipeline live demo
   - 01.4: Secrets management overview
3. Metrics review (5 min)
4. Sprint 2 preview (10 min)
5. Q&A (15 min)

---

## Sprint Metrics to Track

### Velocity Metrics
- **Committed Points:** 13
- **Completed Points:** TBD
- **Velocity:** TBD (baseline sprint)

### Quality Metrics
- **Defects Found:** TBD
- **Defects Fixed:** TBD
- **Code Coverage:** Target ≥80%
- **CI Pass Rate:** Target 95%

### Process Metrics
- **Story Cycle Time:** Average days from start to done
- **Code Review Time:** Average hours to approval
- **Build Success Rate:** Percentage of green builds

---

## Next Sprint Preview (Sprint 2)

**Tentative Scope:**
- Epic 02: Core Platform Services (4 stories)
  - 02.1: Design Tokens & Theming
  - 02.2: Navigation Shell & Route Registry
  - 02.3: Feature Flags Infrastructure
  - 02.4: Telemetry & Analytics Setup

**Estimated Points:** 15

---

## Related Documents

- [Epic 01 Tech Spec](../tech-spec-epic-01.md)
- [Story 01.1](../stories/1-1-bootstrap-repository-and-flutter-app.md)
- [Definition of Done](./process/definition-of-done.md)
- [Epic Validation Backlog](./process/epic-validation-backlog.md)

---

## Change Log

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-01 | 1.0 | Initial Sprint 1 plan created from documentation audit | BMad Team |

---

**Status:** 🟢 READY FOR SPRINT PLANNING - Nov 4, 2025 @ 9:00 AM
