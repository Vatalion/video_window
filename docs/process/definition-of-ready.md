# Definition of Ready (DoR)

**Document Version:** 1.0  
**Last Updated:** 2025-10-30  
**Status:** APPROVED

## Purpose

This document defines the criteria that must be met before a user story can be considered "ready" to enter a development sprint. The Definition of Ready ensures that stories have sufficient detail, clarity, and approval to enable efficient implementation without blocking issues.

## Approval & Governance

**Approved By:**
- [x] John (Product Manager) - Business value and scope validation
- [x] Winston (Architect) - Technical feasibility and architecture alignment
- [x] Amelia (Dev Lead) - Implementation clarity and effort estimation
- [x] Murat (Test Lead) - Testability and quality requirements

**Approval Date:** 2025-10-30

**Review Cycle:** Quarterly or as needed when process gaps are identified

---

## Story Readiness Criteria

A user story is considered **"Ready for Development"** when ALL of the following criteria are met:

### 1. Business Requirements ✓

- [ ] **Clear user story format:** "As a [role], I want [action], so that [benefit]"
- [ ] **Explicit business value:** Story articulates why this work matters and what outcome it delivers
- [ ] **Priority assigned:** Story has a defined priority (P0/Critical, P1/High, P2/Medium, P3/Low)
- [ ] **Product Manager approval:** PM has reviewed and approved the business requirements and scope

### 2. Acceptance Criteria ✓

- [ ] **Numbered and specific:** Each acceptance criterion is numbered and describes testable behavior
- [ ] **Measurable outcomes:** Success can be objectively verified (not subjective or ambiguous)
- [ ] **Security requirements:** Any security-critical requirements explicitly flagged and detailed
- [ ] **Performance targets:** Non-functional requirements specified with concrete metrics (if applicable)
- [ ] **Accessibility requirements:** WCAG 2.1 AA compliance confirmed or exceptions documented

### 3. Technical Clarity ✓

- [ ] **Architecture alignment:** Story aligns with documented architecture patterns and decisions
- [ ] **Component specifications:** Clear guidance on which modules/packages are affected
- [ ] **API contracts defined:** Backend endpoints, data models, and integration points specified
- [ ] **File locations identified:** Story references specific file paths or directory structure
- [ ] **Technical approach validated:** Architect has reviewed and approved the implementation approach

### 4. Dependencies & Prerequisites ✓

- [ ] **Prerequisites identified:** All dependent stories, infrastructure, or third-party services listed
- [ ] **Prerequisites satisfied:** All blocking dependencies are completed or have mitigation plans
- [ ] **External dependencies managed:** Third-party APIs, services, or vendor integrations confirmed available
- [ ] **Data requirements:** Any required seed data, migrations, or data transformations specified

### 5. Design & UX ✓

- [ ] **Design assets available:** UI mockups, wireframes, or design specs provided (if UI work required)
- [ ] **Design system alignment:** Story references shared design tokens, components, or patterns
- [ ] **User flows documented:** Navigation paths and interaction patterns clearly described
- [ ] **Edge cases considered:** Error states, loading states, empty states, and unhappy paths addressed

### 6. Testing Requirements ✓

- [ ] **Test strategy defined:** Unit, integration, and/or e2e test requirements specified
- [ ] **Coverage expectations:** Minimum coverage thresholds identified (default: ≥80%)
- [ ] **Security testing:** Security test requirements included for auth, payments, or sensitive data flows
- [ ] **Performance testing:** Performance test requirements specified (if applicable)
- [ ] **Test data requirements:** Test scenarios and data needs documented

### 7. Task Breakdown ✓

- [ ] **Tasks enumerated:** Story broken down into specific implementation tasks/subtasks
- [ ] **Tasks mapped to ACs:** Each task references which acceptance criteria it satisfies
- [ ] **Effort estimated:** Development team has reviewed and estimated effort (story points or hours)
- [ ] **No unknowns:** Team has sufficient information to implement without discovery work

### 8. Documentation & References ✓

- [ ] **PRD reference:** Story traces back to specific PRD requirements or epics
- [ ] **Tech spec reference:** Story references relevant sections of epic tech spec document
- [ ] **Architecture docs linked:** References to architecture guides, ADRs, or coding standards included
- [ ] **Related stories identified:** Links to related or dependent stories documented

### 9. Approvals & Sign-offs ✓

- [ ] **Product Manager sign-off:** PM approves business requirements and priority
- [ ] **Architect sign-off:** Technical approach approved by architect
- [ ] **Test Lead sign-off:** Testing strategy and requirements approved by QA lead
- [ ] **Status updated:** Story status field set to "Approved" with approval date and approvers documented

---

## Story Status Progression

Stories progress through the following states:

1. **Draft** - Story being authored, not yet complete
2. **Ready for Review** - Story author believes it meets DoR, pending validation
3. **Approved** - All DoR criteria met, story ready for sprint planning
4. **InProgress** - Story actively being implemented in current sprint
5. **Ready for QA** - Implementation complete, awaiting QA validation
6. **Done** - All acceptance criteria validated, story complete

**Important:** Only stories in **"Approved"** status may enter sprint planning.

---

## Responsibility Matrix

| Criteria Category | Primary Reviewer | Final Approver |
|------------------|------------------|----------------|
| Business Requirements | Product Manager | Product Manager |
| Acceptance Criteria | Product Manager + Test Lead | Product Manager |
| Technical Clarity | Architect | Architect |
| Dependencies | Scrum Master | Product Manager |
| Design & UX | UX Designer | Product Manager |
| Testing Requirements | Test Lead | Test Lead |
| Task Breakdown | Dev Lead | Dev Lead |
| Documentation | Scrum Master | Scrum Master |

---

## Exception Process

In rare cases, a story may need to proceed without meeting all DoR criteria:

1. **Emergency/Hotfix:** Critical production issues may bypass DoR with PM + Architect approval
2. **Technical Spike:** Discovery stories intentionally lack full acceptance criteria but must have time-box and success criteria
3. **Infrastructure Work:** Pure technical work may have reduced UX/design requirements

**All exceptions must be:**
- Documented in story with "DoR Exception" label
- Approved by Product Manager AND Architect
- Include mitigation plan for missing criteria

---

## Process Integration

### During Story Preparation (Scrum Master)
1. Author story using template
2. Complete DoR self-assessment checklist
3. Iterate with PM, Architect, Test Lead until all criteria met
4. Update status to "Ready for Review"
5. Request approval signatures

### During Story Review (Team Leads)
1. Product Manager reviews business requirements and acceptance criteria
2. Architect reviews technical clarity and dependencies
3. Test Lead reviews testing requirements
4. Dev Lead validates task breakdown and effort estimate
5. All approvers sign off in story document

### During Sprint Planning
1. Only "Approved" stories are eligible for sprint commitment
2. Team pulls stories based on priority and capacity
3. Story status updated to "InProgress" when work begins

---

## Related Documents

- [Definition of Done](./definition-of-done.md) - Criteria for story completion
- [Story Approval Workflow](./story-approval-workflow.md) - Detailed approval process
- [Master Test Strategy](../testing/master-test-strategy.md) - Testing requirements and standards
- [Story Template](../../bmad/bmm/workflows/create-story.mdc) - BMAD v6 story creation workflow

---

## Change Log

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-10-30 | 1.0 | Initial Definition of Ready created from gap analysis | Bob (Scrum Master) |

---

**Next Review Date:** 2026-01-30
