# Unified Account Model Correction Plan

**Date:** 2025-11-02  
**Owner:** Documentation Task Force (PM, Architect, Dev Lead, QA, Scrum Master)  
**Branch:** `chore/unified-account-plan`

## 1. Context & Rationale
- Current documentation and backlog assume two account archetypes (viewer vs maker) with invitation-based onboarding and RBAC.  
- Product direction pivots to a single polymorphic account, unlocking maker capabilities contextually (e.g., publishing, selling, shipping) when prerequisites are satisfied.  
- Objectives: reduce user friction, align flows with simplified UX, and limit unnecessary infrastructure (invitation codes, complex role hierarchy) for MVP.

## 2. Impacted Artifacts
| Category | Artifact(s) | Impact Summary |
| --- | --- | --- |
| Product Narrative | `docs/brief.md`, `docs/prd.md` | Rewrite personas/flows to describe unified accounts, capability unlock checkpoints, and verification gating within feature flows. |
| Technical Specs | `docs/tech-spec-epic-1.md`, `docs/tech-spec-epic-2.md` | Collapse invitation/RBAC stack; describe progressive capability flags and verification services triggered from publish/offer/payment flows. |
| Stories & Backlog | `docs/stories/2.1.*`, `docs/stories/2.2.*`, downstream references (e.g., 3.x, 5.x, 9.x) | Replace invitation/RBAC stories with unified account enablement stories; update prerequisites/ACs referencing `is_maker` or role guards. |
| Architecture Docs | `docs/architecture/front-end-architecture.md`, `docs/architecture/story-component-mapping.md`, `docs/data-flow-mapping.md` | Update route guard descriptions, state model diagrams, and data transformation notes to use capability flags rather than separate account types. |
| Analytics & Dashboards | `docs/analytics/maker-access-dashboard.md`, `docs/analytics/authentication-dashboard.md` | Shift metrics to track capability enablement stages (e.g., "publish_ready", "checkout_ready") instead of viewer vs maker splits. |
| Testing & Process | `docs/testing/master-test-strategy.md`, `docs/process/definition-of-ready.md`, `docs/process/story-approval-workflow.md` | Adjust readiness criteria, testing matrices, and approval checklists to reference capability gating checkpoints. |
| Historical Logs | `docs/archive/course-correction-change-log.md` | Append entry documenting this course correction decision. |

## 3. Planned Documentation Updates
1. **Brief & PRD**  
   - Rewrite personas as "Creators" and "Shoppers" sharing one account.  
   - Update functional requirements (FR1–FR9) and Epic overviews to describe capability unlock flows (e.g., publishing requires verification, selling requires payout setup, shipping requires address verification).  
   - Remove references to invitation-based maker onboarding, redux RBAC, and `is_maker` flag; replace with capability matrix table.

2. **Tech Specs**  
   - **Epic 1**: Describe polymorphic user model with capability flags (`can_publish`, `can_collect_payments`, `can_ship`) managed through verification services.  
   - **Epic 2**: Retire invitation & RBAC focus. Re-scope epic to "Capability Enablement & Verification" including verification flows, payout onboarding, device trust, and risk checks triggered by feature use.  
   - Update API endpoints to reflect on-demand verification (e.g., `/capabilities/request`, `/capabilities/status`) instead of `/invitations/*` or `/roles/*`.

3. **Stories**  
   - Deprecate `docs/stories/2.1.maker-onboarding-invitation-flow.md` and `docs/stories/2.2.rbac-enforcement-and-permission-management.md`.  
   - Author replacement stories:
     - `Story 2.1 - Capability Enablement Request Flow`
     - `Story 2.2 - Verification Requirements within Publish Flow`
     - `Story 2.3 - Payout & Compliance Activation`
     - `Story 2.4 - Device Trust & Risk Monitoring`
   - Review all dependent stories (Epics 3–13) and update prerequisites/ACs referencing maker-only access guards or `is_maker` flags.

4. **Architecture & Data Flow**  
   - Update diagrams to reflect `UserCapability` model instead of role-based guards.  
   - Document capability evaluation points in route guards, BLoCs, and Serverpod endpoints.  
   - Clarify data flow transformations for capability checks (UI → BLoC → Use Case → Capability Service → Repository).

5. **Analytics & Testing**  
   - Define new KPIs: capability request conversions, verification completion rates, blocked action attempts.  
   - Modify test strategy to include capability gating scenarios (unit, integration, end-to-end).  
   - Ensure QA checklists validate verification prompts trigger only when necessary.

6. **Process & Governance**  
   - Update Definition of Ready/Done to require capability mapping and verification plan for each story touching restricted flows.  
   - Adjust story approval workflow to reference capability gating sign-offs instead of maker invitation reviews.

7. **Change Log**  
   - Add entry to `docs/archive/course-correction-change-log.md` capturing the business rationale, impacted artifacts, and expected delivery timeline.

## 4. Execution Timeline (Target)
| Milestone | Owner | Target Date |
| --- | --- | --- |
| Draft updated PRD + Brief revisions | PM + Architect | 2025-11-04 |
| Tech spec rewrites (Epics 1 & 2) | Architect + Dev Lead | 2025-11-05 |
| Story backlog replacement & dependency sweep | Scrum Master + Dev Lead | 2025-11-06 |
| Architecture/Analytics/Test doc updates | Architect + QA Lead + Data Lead | 2025-11-07 |
| Process/gov updates + change log entry | Scrum Master | 2025-11-07 |
| Stakeholder review & approval | Exec Sponsor + PM | 2025-11-08 |

## 5. Risks & Mitigations
- **Risk:** Hidden dependencies in downstream stories referencing deprecated `is_maker` flag.  
  **Mitigation:** Perform grep-based audit for `is_maker`, `maker-only`, `invitation`, `RBAC` and log follow-up tasks.
- **Risk:** Verification scope creep reintroducing friction.  
  **Mitigation:** Define clear capability trigger points in PRD; limit MVP requirements to necessary compliance gates. 
- **Risk:** Analytics dashboards tied to old role segmentation.  
  **Mitigation:** Coordinate with Data team to update schemas and avoid broken reporting.

## 6. Next Steps
1. Review and confirm this plan with PM, Architect, Dev Lead.  
2. Begin documentation updates following priority order in Section 3.  
3. Run `scripts/validate-docs.sh` before opening PR.  
4. Prepare rollout communication summarizing the unified account model shift for the broader team.

## 7. Related Documents
- `docs/unified-account-final-report.md` — Validation record confirming documentation remediation status post-migration.
