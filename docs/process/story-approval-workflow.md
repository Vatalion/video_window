# Story Approval Workflow

**Document Version:** 1.0  
**Last Updated:** 2025-10-30  
**Status:** APPROVED

## Purpose

This document defines the complete workflow for story creation, approval, implementation, and completion. It establishes clear responsibilities, decision gates, and status transitions throughout the story lifecycle.

## Approval & Governance

**Approved By:**
- [x] John (Product Manager) - Business process and stakeholder responsibilities
- [x] Winston (Architect) - Technical review process and architecture gates
- [x] Amelia (Dev Lead) - Development workflow and handoff procedures
- [x] Murat (Test Lead) - Quality gates and testing workflow
- [x] Bob (Scrum Master) - Overall process orchestration and compliance

**Approval Date:** 2025-10-30

**Review Cycle:** Quarterly or when process inefficiencies are identified

---

## Story Lifecycle Overview

```
Draft → Ready for Review → Approved → InProgress → Ready for QA → Done
  ↓         ↓                ↓          ↓            ↓             ↓
Author   Validation      Sprint      Development   Testing      Complete
         & Approval      Planning    & Review      & Review
```

---

## Phase 1: Story Creation & Preparation

### **Status: Draft**

**Primary Responsibility:** Scrum Master (Bob)

**Activities:**
1. **Story Authoring**
   - Create story file using standard template
   - Define user story in "As a... I want... So that..." format
   - Document acceptance criteria with numbered, testable requirements
   - Identify prerequisites and dependencies
   - Break down implementation tasks and subtasks

2. **Initial Technical Review**
   - Research technical approach and feasibility
   - Identify integration points and affected components
   - Document file locations and architectural considerations
   - Reference relevant architecture guides and tech specs

3. **Testing Strategy Planning**
   - Define test requirements (unit, integration, e2e)
   - Identify security testing needs
   - Specify performance testing criteria
   - Document test data requirements

**Exit Criteria:**
- Story template fully completed
- All required sections populated
- Initial technical approach documented
- Author believes story meets Definition of Ready

**Next Status:** Ready for Review

---

## Phase 2: Stakeholder Review & Approval

### **Status: Ready for Review**

**Workflow Steps:**

#### **Step 1: Product Manager Review**
**Responsibility:** John (Product Manager)  
**Timeline:** 1-2 business days

**Review Criteria:**
- [ ] Business value clearly articulated and aligns with PRD
- [ ] User story format correct and meaningful
- [ ] Acceptance criteria complete and testable
- [ ] Priority assignment appropriate
- [ ] Scope appropriate for sprint-sized work

**Outcomes:**
- ✅ **Approve:** Sign off and proceed to technical review
- ❌ **Request Changes:** Return to Draft with specific feedback
- ⏸️ **Block:** Escalate to Product Owner if scope/priority unclear

#### **Step 2: Architecture Review**
**Responsibility:** Winston (Architect)  
**Timeline:** 1-2 business days  
**Prerequisite:** Product Manager approval

**Review Criteria:**
- [ ] Technical approach aligns with architecture decisions
- [ ] Dependencies correctly identified and manageable
- [ ] Integration points properly specified
- [ ] Performance and security considerations addressed
- [ ] Implementation guidance sufficient for development

**Outcomes:**
- ✅ **Approve:** Sign off and proceed to test review
- ❌ **Request Changes:** Return to Draft with technical guidance
- ⏸️ **Research Needed:** Schedule architecture spike or research task

#### **Step 3: Test Strategy Review**
**Responsibility:** Murat (Test Lead)  
**Timeline:** 1 business day  
**Prerequisite:** Architecture approval

**Review Criteria:**
- [ ] Testing approach aligns with master test strategy
- [ ] Test coverage appropriate for risk level
- [ ] Security testing requirements adequate
- [ ] Performance testing criteria realistic and measurable
- [ ] Test automation feasibility confirmed

**Outcomes:**
- ✅ **Approve:** Sign off and proceed to dev review
- ❌ **Request Changes:** Return to Draft with testing guidance

#### **Step 4: Development Review**
**Responsibility:** Amelia (Dev Lead)  
**Timeline:** 1 business day  
**Prerequisite:** Test strategy approval

**Review Criteria:**
- [ ] Task breakdown clear and implementable
- [ ] Effort estimate reasonable
- [ ] No unknown technical challenges
- [ ] Implementation guidance sufficient
- [ ] Code review requirements understood

**Outcomes:**
- ✅ **Approve:** Story ready for Approved status
- ❌ **Request Changes:** Return to Draft with implementation concerns

#### **Step 5: Final Validation**
**Responsibility:** Bob (Scrum Master)  
**Timeline:** Same day  
**Prerequisite:** All stakeholder approvals

**Validation Activities:**
- [ ] Verify all approval signatures collected
- [ ] Confirm Definition of Ready checklist complete
- [ ] Update story status to "Approved"
- [ ] Add story to sprint planning backlog
- [ ] Document approval date and approvers

**Exit Criteria:**
- All stakeholder approvals documented
- Definition of Ready checklist complete
- Story status updated to "Approved"

**Next Status:** Approved

---

## Phase 3: Sprint Planning & Development

### **Status: Approved**

**Primary Responsibility:** Scrum Master (Bob) + Development Team

**Activities:**
1. **Sprint Planning Eligibility**
   - Only "Approved" stories eligible for sprint commitment
   - Stories selected based on priority and team capacity
   - Dependencies verified before sprint commitment

2. **Sprint Commitment**
   - Team commits to delivering story within sprint
   - Story status updated to "InProgress"
   - Implementation begins

**Exit Criteria:**
- Story selected for active sprint
- Team commitment confirmed
- Implementation work begins

**Next Status:** InProgress

---

## Phase 4: Development & Implementation

### **Status: InProgress**

**Primary Responsibility:** Development Team (Led by Amelia)

**Activities:**
1. **Implementation**
   - Follow task breakdown and technical guidance
   - Implement code following architecture patterns
   - Write automated tests (unit, integration, widget)
   - Conduct peer code reviews

2. **Continuous Validation**
   - Regular check-ins on acceptance criteria progress
   - Early integration testing
   - Performance and security validation
   - Documentation updates

3. **Development Completion**
   - All tasks completed and checked off
   - Code review approved
   - Automated tests passing
   - Ready for independent QA validation

**Exit Criteria:**
- All implementation tasks completed
- Code review approved by peer
- Automated test suite passing
- Developer believes all acceptance criteria met

**Next Status:** Ready for QA

---

## Phase 5: Quality Assurance & Testing

### **Status: Ready for QA**

**Primary Responsibility:** Murat (Test Lead) + QA Team

**Activities:**
1. **Independent Testing**
   - Manual validation of all acceptance criteria
   - Cross-platform and cross-browser testing
   - Accessibility and performance validation
   - Security testing (if applicable)

2. **Quality Validation**
   - Verify Definition of Done criteria met
   - Confirm automated test coverage adequate
   - Validate user experience meets expectations
   - Check integration points and edge cases

3. **Issue Resolution**
   - Document any defects or gaps
   - Work with development team on fixes
   - Re-test after issue resolution

**Outcomes:**
- ✅ **Pass QA:** All acceptance criteria validated, proceed to final review
- ❌ **Fail QA:** Return to InProgress with specific issues documented
- ⏸️ **Clarification Needed:** Escalate acceptance criteria questions to PM

**Exit Criteria:**
- All acceptance criteria manually validated
- Definition of Done checklist complete
- QA team approval documented

**Next Status:** Done (after final PM acceptance)

---

## Phase 6: Final Acceptance & Completion

### **Status: Done**

**Primary Responsibility:** John (Product Manager)

**Activities:**
1. **Business Validation**
   - Confirm delivered functionality meets business expectations
   - Validate user experience acceptable
   - Verify business value realized

2. **Final Approval**
   - Sign off on story completion
   - Document completion date and final notes
   - Release for potential deployment

3. **Post-Completion Activities**
   - Update project metrics and velocity tracking
   - Document lessons learned for retrospective
   - Close related issues or tickets

**Exit Criteria:**
- Product Manager final acceptance documented
- Story marked "Done" with completion date
- All Definition of Done criteria verified

**Final Status:** Done

---

## Exception Handling & Escalation

### **Common Exception Scenarios**

#### **Blocked Dependencies**
- **Process:** Flag dependency blocker, escalate to PM for prioritization
- **Responsible:** Scrum Master
- **Resolution:** Dependency resolved or story scope adjusted

#### **Technical Feasibility Issues**
- **Process:** Architect review, potential spike story creation
- **Responsible:** Architect + Dev Lead
- **Resolution:** Alternative approach or story scope adjustment

#### **Changing Requirements**
- **Process:** PM evaluation, potential story amendment or new story creation
- **Responsible:** Product Manager
- **Resolution:** Story updated with change documentation or new story created

#### **Quality Issues**
- **Process:** Failed QA results in return to InProgress status
- **Responsible:** Test Lead + Dev Lead
- **Resolution:** Issues addressed and story re-tested

### **Escalation Matrix**

| Issue Type | First Contact | Escalation Level 1 | Escalation Level 2 |
|------------|---------------|-------------------|-------------------|
| Scope/Priority Conflicts | Product Manager | Product Owner | Executive Sponsor |
| Technical Blockers | Architect | CTO/Tech Lead | External Consultation |
| Resource Constraints | Scrum Master | Engineering Manager | Resource Planning Team |
| Quality Issues | Test Lead | Dev Lead | Quality Assurance Manager |
| Timeline Conflicts | Scrum Master | Product Manager | Program Management |

---

## Status Change Authorization

| From Status | To Status | Authorized By | Required Approvals |
|-------------|-----------|---------------|-------------------|
| Draft | Ready for Review | Story Author | Self-assessment complete |
| Ready for Review | Draft | Any Reviewer | Feedback provided |
| Ready for Review | Approved | Scrum Master | All stakeholder approvals |
| Approved | InProgress | Dev Team | Sprint commitment |
| InProgress | Ready for QA | Developer | Code review + tests pass |
| Ready for QA | InProgress | QA Team | Issues documented |
| Ready for QA | Done | Product Manager | QA approval + final acceptance |
| Any Status | Blocked | Anyone | Blocker documented |

---

## Process Metrics & Monitoring

### **Workflow Efficiency Metrics**
- **Approval Cycle Time:** Time from "Ready for Review" to "Approved"
- **Review Rejection Rate:** Percentage of stories requiring rework during review
- **Block Resolution Time:** Average time to resolve blocked stories
- **Sprint Commitment Accuracy:** Percentage of committed stories completed

### **Quality Metrics**
- **First-Pass QA Rate:** Percentage of stories passing QA on first attempt
- **Post-Completion Defect Rate:** Issues found after "Done" status
- **Definition of Done Compliance:** Stories meeting all DoD criteria
- **Customer Acceptance Rate:** Stakeholder satisfaction with delivered stories

### **Process Improvement**
- **Monthly process review:** Identify bottlenecks and improvement opportunities
- **Quarterly workflow assessment:** Update process based on team feedback
- **Annual process audit:** Comprehensive review of workflow effectiveness

---

## Related Documents

- [Definition of Ready](./definition-of-ready.md) - Entry criteria for development
- [Definition of Done](./definition-of-done.md) - Exit criteria for completion
- [Master Test Strategy](../testing/master-test-strategy.md) - Testing approach and standards
- [Story Template](../../bmad/bmm/workflows/create-story.mdc) - BMAD v6 story creation workflow

---

## Change Log

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-10-30 | 1.0 | Initial Story Approval Workflow created from gap analysis | Bob (Scrum Master) |

---

**Next Review Date:** 2026-01-30